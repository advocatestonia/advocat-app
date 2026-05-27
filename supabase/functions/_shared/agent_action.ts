// _shared/agent_action.ts — HMAC-signed action_id for agent-loop approval
// -----------------------------------------------------------------------------
// Pattern mirrors email-triage/policy_gate.ts but scoped to the agent
// loop's write-tool interception (Day 4 of MVP 2026-05-27).
//
// When claude-proxy detects a WRITE tool in a tool_use response, it:
//   1. Hashes the tool_input (sha256, hex) — args_sha256
//   2. Builds a payload { agent_run_id, user_id, tool_name, args_sha256,
//      iat_ms, ttl_ms }
//   3. Signs it with HMAC-SHA-256 over EMAIL_AGENT_GATE_SECRET (reused —
//      same secret protects gate_token + agent action_id; rotation
//      cascades cleanly).
//   4. Returns the token to Flutter inside the awaiting_approval SSE
//      event.
//
// The agent-approve edge fn receives { action_id } from the user's tap,
// re-derives the HMAC over the persisted agent_runs.write_pending.tool_input,
// and dispatches the write only when verify_ok.
// -----------------------------------------------------------------------------

const DEFAULT_TTL_MS = 5 * 60 * 1000; // 5 minutes — approval sheet window

/**
 * Action-ID payload — what gets HMAC-signed. Stable JSON shape so the
 * canonical-form string can be reconstructed deterministically at verify
 * time. Order of keys matters — we build the prefix manually below.
 */
export interface AgentActionPayload {
  agent_run_id: string;
  user_id: string;
  tool_name: string;
  args_sha256: string; // hex
  iat_ms: number;
  ttl_ms: number;
}

export interface AgentActionToken {
  payload_b64: string; // base64url(JSON(payload))
  hmac_hex: string;
}

/** Stable JSON canonicalisation — keys in a fixed order. */
function canonicalisePayload(p: AgentActionPayload): string {
  return JSON.stringify({
    agent_run_id: p.agent_run_id,
    user_id: p.user_id,
    tool_name: p.tool_name,
    args_sha256: p.args_sha256,
    iat_ms: p.iat_ms,
    ttl_ms: p.ttl_ms,
  });
}

function base64urlEncode(bytes: Uint8Array): string {
  let bin = "";
  // String.fromCharCode is safe up to ~8K chunks.
  const STEP = 8192;
  for (let i = 0; i < bytes.length; i += STEP) {
    const slice = bytes.subarray(i, Math.min(i + STEP, bytes.length));
    bin += String.fromCharCode(...slice);
  }
  return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function base64urlDecode(s: string): Uint8Array {
  const pad = "=".repeat((4 - (s.length % 4)) % 4);
  const std = (s + pad).replace(/-/g, "+").replace(/_/g, "/");
  const bin = atob(std);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}

function hexEncode(bytes: Uint8Array): string {
  let out = "";
  for (let i = 0; i < bytes.length; i++) {
    out += bytes[i].toString(16).padStart(2, "0");
  }
  return out;
}

/** SHA-256 hex digest over a UTF-8 string. */
export async function sha256Hex(text: string): Promise<string> {
  const enc = new TextEncoder();
  const hash = await crypto.subtle.digest("SHA-256", enc.encode(text));
  return hexEncode(new Uint8Array(hash));
}

/** Constant-time equality on hex strings (mitigates HMAC timing attacks). */
function constantTimeEqHex(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) {
    diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return diff === 0;
}

async function hmacSha256Hex(secret: string, message: string): Promise<string> {
  const enc = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    enc.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign("HMAC", key, enc.encode(message));
  return hexEncode(new Uint8Array(sig));
}

/**
 * Issue an action_id binding (agent_run_id, user_id, tool_name,
 * args_sha256). 5-minute TTL by default. Returns the `action_id` string
 * — base64url(payload).hex(hmac).
 */
export async function issueActionId(input: {
  agent_run_id: string;
  user_id: string;
  tool_name: string;
  args_sha256: string;
  secret: string;
  now_ms?: number;
  ttl_ms?: number;
}): Promise<string> {
  const payload: AgentActionPayload = {
    agent_run_id: input.agent_run_id,
    user_id: input.user_id,
    tool_name: input.tool_name,
    args_sha256: input.args_sha256,
    iat_ms: input.now_ms ?? Date.now(),
    ttl_ms: input.ttl_ms ?? DEFAULT_TTL_MS,
  };
  const canonical = canonicalisePayload(payload);
  const payload_b64 = base64urlEncode(new TextEncoder().encode(canonical));
  const hmac = await hmacSha256Hex(input.secret, canonical);
  return `${payload_b64}.${hmac}`;
}

export interface VerifyActionIdResult {
  ok: boolean;
  payload?: AgentActionPayload;
  reason?: string;
}

/**
 * Verify a token. Re-derives the HMAC, then compares:
 *   - signature (constant-time)
 *   - expected_agent_run_id (token must match the persisted row's id)
 *   - expected_user_id (token must match the authenticated caller)
 *   - expected_tool_name + expected_args_sha256 (token must match what
 *     we're about to dispatch — prevents bait-and-switch)
 *   - iat_ms + ttl_ms (token must not be expired)
 */
export async function verifyActionId(input: {
  token: string;
  expected_agent_run_id: string;
  expected_user_id: string;
  expected_tool_name: string;
  expected_args_sha256: string;
  secret: string;
  now_ms?: number;
}): Promise<VerifyActionIdResult> {
  const t = input.token ?? "";
  const dot = t.indexOf(".");
  if (dot <= 0 || dot === t.length - 1) {
    return { ok: false, reason: "malformed_token" };
  }
  const payloadB64 = t.slice(0, dot);
  const hmacHex = t.slice(dot + 1);
  let payload: AgentActionPayload;
  try {
    const canonical = new TextDecoder().decode(base64urlDecode(payloadB64));
    payload = JSON.parse(canonical) as AgentActionPayload;
  } catch (_e) {
    return { ok: false, reason: "malformed_payload" };
  }
  if (
    typeof payload?.agent_run_id !== "string" ||
    typeof payload?.user_id !== "string" ||
    typeof payload?.tool_name !== "string" ||
    typeof payload?.args_sha256 !== "string" ||
    typeof payload?.iat_ms !== "number" ||
    typeof payload?.ttl_ms !== "number"
  ) {
    return { ok: false, reason: "malformed_payload" };
  }
  if (payload.agent_run_id !== input.expected_agent_run_id) {
    return { ok: false, reason: "agent_run_id_mismatch" };
  }
  if (payload.user_id !== input.expected_user_id) {
    return { ok: false, reason: "user_id_mismatch" };
  }
  if (payload.tool_name !== input.expected_tool_name) {
    return { ok: false, reason: "tool_name_mismatch" };
  }
  if (payload.args_sha256 !== input.expected_args_sha256) {
    return { ok: false, reason: "args_sha256_mismatch" };
  }
  const now = input.now_ms ?? Date.now();
  if (now > payload.iat_ms + payload.ttl_ms) {
    return { ok: false, reason: "expired" };
  }
  const canonical = canonicalisePayload(payload);
  const expectedHmac = await hmacSha256Hex(input.secret, canonical);
  if (!constantTimeEqHex(expectedHmac, hmacHex)) {
    return { ok: false, reason: "hmac_mismatch" };
  }
  return { ok: true, payload };
}

/**
 * Compute the canonical args_sha256 over a tool_input object. Stable
 * JSON.stringify of the input is sufficient because tool_use blocks
 * come back with model-generated JSON-shaped objects (no Date / Map /
 * undefined to worry about — Anthropic serialises them clean).
 */
export async function hashToolInput(
  toolInput: Record<string, unknown>,
): Promise<string> {
  return sha256Hex(JSON.stringify(toolInput));
}

/**
 * The set of tool names that require approval before execution. Sourced
 * from the existing assistant_tools.dart requiresApproval set, server-
 * authoritative copy here.
 */
export const WRITE_TOOLS: ReadonlySet<string> = new Set([
  "send_email",
  "generate_pdf",
  "approve_send_draft",
  "draft_email_with_attachments",
  // Future write tools land here. Adding a tool name to this set forces
  // the agent loop to STOP + emit awaiting_approval instead of executing.
]);

export function isWriteTool(name: string): boolean {
  return WRITE_TOOLS.has(name);
}
