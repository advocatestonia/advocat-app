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
//
// WAVE 2 FIX W2-09 (2026-05-28, F-005 + F-008 + F-009):
//   - hashToolInput now uses canonical-JSON serialisation (deep-sorted
//     keys) so the hash survives a JSONB round-trip through Postgres.
//   - For write tools that have user-visible fields (send_email,
//     draft_email_with_attachments), the hash binds to a PROJECTION of
//     just those fields (sorted to/cc, subject, body_length,
//     has_attachments_count). This means the approval card display CAN
//     match the HMAC: a homograph attack would have to forge BOTH the
//     display AND the canonical fields.
//   - The signed payload now carries `aud: "agent_approve"` and
//     `purpose: <tool_name>` (F-009 prep — domain separation against the
//     shared EMAIL_AGENT_GATE_SECRET used for 4 unrelated signing
//     schemes).
// -----------------------------------------------------------------------------

const DEFAULT_TTL_MS = 5 * 60 * 1000; // 5 minutes — approval sheet window

/** Audience tag for the action_id signing scheme (F-009 domain separation). */
export const AGENT_ACTION_AUDIENCE = "agent_approve" as const;

/**
 * Action-ID payload — what gets HMAC-signed. Stable JSON shape so the
 * canonical-form string can be reconstructed deterministically at verify
 * time. Order of keys matters — we build the prefix manually below.
 */
export interface AgentActionPayload {
  aud: typeof AGENT_ACTION_AUDIENCE; // audience tag — domain separation
  purpose: string;                   // tool_name — explicit re-bind
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
  // Hand-written so the order is explicit even if the struct shape
  // changes underneath; never use JSON.stringify with arbitrary input
  // shape for HMAC payloads.
  return JSON.stringify({
    aud: p.aud,
    purpose: p.purpose,
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
    aud: AGENT_ACTION_AUDIENCE,
    purpose: input.tool_name,
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
 *   - audience (must be AGENT_ACTION_AUDIENCE — defends against
 *     cross-scheme token reuse if EMAIL_AGENT_GATE_SECRET is shared)
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
    typeof payload?.aud !== "string" ||
    typeof payload?.purpose !== "string" ||
    typeof payload?.agent_run_id !== "string" ||
    typeof payload?.user_id !== "string" ||
    typeof payload?.tool_name !== "string" ||
    typeof payload?.args_sha256 !== "string" ||
    typeof payload?.iat_ms !== "number" ||
    typeof payload?.ttl_ms !== "number"
  ) {
    return { ok: false, reason: "malformed_payload" };
  }
  if (payload.aud !== AGENT_ACTION_AUDIENCE) {
    return { ok: false, reason: "audience_mismatch" };
  }
  if (payload.purpose !== input.expected_tool_name) {
    return { ok: false, reason: "purpose_mismatch" };
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

// -----------------------------------------------------------------------------
// Canonical JSON — deep-sorted keys, preserves array order, deterministic
// number/string encoding. The CRITICAL invariant: passing the same
// logical value (regardless of key insertion order) MUST produce the
// same byte sequence. This survives a JSONB round-trip through Postgres,
// which is the F-005 root cause (Postgres normalises JSONB key order;
// the previous JSON.stringify(input) implementation hashed an
// insertion-order string that was different from the post-roundtrip
// shape, leading to 409 args_sha256_mismatch on legitimate Approve taps).
// -----------------------------------------------------------------------------

/**
 * Canonical JSON serialisation.
 *
 * Rules:
 *   - `undefined` is omitted from objects entirely (NOT serialised as
 *     the literal "undefined" or as null) — matches JSON.stringify
 *     semantics for `undefined` property values.
 *   - Object keys are deep-sorted lexicographically by codepoint
 *     (Array.prototype.sort default).
 *   - Arrays preserve order; each element is recursively canonicalised.
 *   - Numbers: NaN/Infinity normalised to null (same as JSON.stringify).
 *   - Strings, booleans, null delegate to JSON.stringify for proper
 *     escape sequences (\u00XX for control chars, \" \\ etc.).
 *
 * The implementation deliberately does NOT use JSON.stringify's
 * replacer-with-sorted-keys trick because that fails on deep nested
 * objects (replacer only sees one level at a time) — we recurse
 * explicitly.
 */
export function canonicalJsonStringify(value: unknown): string {
  if (value === null) return "null";
  if (value === undefined) return "null"; // top-level undefined → null
  const t = typeof value;
  if (t === "string") return JSON.stringify(value);
  if (t === "boolean") return value ? "true" : "false";
  if (t === "number") {
    if (!Number.isFinite(value as number)) return "null";
    return JSON.stringify(value);
  }
  if (t === "bigint") {
    // BigInt has no native JSON form; we serialise as string to keep
    // the hash stable. Caller should avoid BigInt in tool_input.
    return JSON.stringify((value as bigint).toString());
  }
  if (Array.isArray(value)) {
    const parts = value.map((v) => canonicalJsonStringify(v));
    return "[" + parts.join(",") + "]";
  }
  if (t === "object") {
    const obj = value as Record<string, unknown>;
    const keys = Object.keys(obj)
      .filter((k) => obj[k] !== undefined) // drop undefined props
      .sort();
    const parts = keys.map(
      (k) => JSON.stringify(k) + ":" + canonicalJsonStringify(obj[k]),
    );
    return "{" + parts.join(",") + "}";
  }
  // Functions, symbols → null (JSON.stringify-compatible).
  return "null";
}

// -----------------------------------------------------------------------------
// Visible-field projection for write tools (F-008 prep).
//
// For tools that the user actually approves in the UI (send_email,
// draft_email_with_attachments), we want the HMAC to bind to the
// SUBSET of args that the approval card displays. This way:
//   1. A homograph attack on `to` (Cyrillic 'о' in jоkela@...) is
//      caught: the canonical projection of `to` differs byte-for-byte
//      from the legitimate Latin form, so the hash differs.
//   2. A long-body deception attack still binds the body_length —
//      the user is shown the length and can refuse to approve a
//      surprisingly long body.
//   3. The model can swap unrelated fields (e.g. reply-to-thread
//      threading IDs) without invalidating the approval — keeps the
//      flow tolerant of harmless model jitter.
//
// For unknown write tools, fall back to canonical-JSON of the full
// input — safer default than hashing a partial projection of fields
// we don't know about.
// -----------------------------------------------------------------------------

/** Normalise an array of strings: trim, lowercase, sort. */
function normaliseStringArray(v: unknown): string[] {
  if (typeof v === "string") {
    return v
      .split(/[,;\s]+/)
      .map((s) => s.trim().toLowerCase())
      .filter((s) => s.length > 0)
      .sort();
  }
  if (Array.isArray(v)) {
    return v
      .map((x) => (typeof x === "string" ? x.trim().toLowerCase() : ""))
      .filter((s) => s.length > 0)
      .sort();
  }
  return [];
}

/** UTF-8 byte length — matches what Postgres stores and what the user
 *  sees as the "body size" in the approval card. */
function utf8ByteLength(s: string): number {
  return new TextEncoder().encode(s).length;
}

/**
 * Compute the user-visible projection for a write tool. Returns the
 * EXACT object that gets canonical-JSON-serialised before hashing.
 *
 * The returned object includes `_tool` so two different tools with the
 * same projection shape cannot collide.
 */
export function visibleProjectionForTool(
  toolName: string,
  input: Record<string, unknown>,
): Record<string, unknown> {
  switch (toolName) {
    case "send_email":
    case "draft_email_with_attachments":
    case "approve_send_draft": {
      const to = normaliseStringArray(input.to);
      const cc = normaliseStringArray(input.cc);
      const bcc = normaliseStringArray(input.bcc);
      const subject = typeof input.subject === "string"
        ? input.subject.trim()
        : "";
      const body = typeof input.body === "string" ? input.body : "";
      const attachments = Array.isArray(input.attachments)
        ? input.attachments.length
        : (Array.isArray(input.attachment_ids)
          ? input.attachment_ids.length
          : 0);
      return {
        _tool: toolName,
        to,
        cc,
        bcc,
        subject,
        body_length: utf8ByteLength(body),
        body_sha256_prefix: "", // populated below
        has_attachments_count: attachments,
      };
    }
    case "generate_pdf": {
      // PDF generation: user-visible fields are template + title.
      const template = typeof input.template === "string" ? input.template : "";
      const title = typeof input.title === "string" ? input.title : "";
      const contentLen = typeof input.content === "string"
        ? utf8ByteLength(input.content)
        : 0;
      return {
        _tool: toolName,
        template,
        title,
        content_length: contentLen,
      };
    }
    default: {
      // Unknown write tool — fall back to full canonical input, tagged.
      // This is safer than projecting fields we don't understand: an
      // attacker can't bypass the binding by hiding malicious args in
      // an unprojected field.
      return { _tool: toolName, _full: input };
    }
  }
}

/**
 * Compute the canonical args_sha256 over a tool_input object.
 *
 * The hash is taken over `canonicalJsonStringify(projection)` where
 * `projection = visibleProjectionForTool(toolName, toolInput)`. This
 * survives a JSONB round-trip through Postgres AND binds to the
 * user-visible card content (F-005 + F-008).
 *
 * For body-bearing tools (send_email, draft_email_with_attachments),
 * we also hash a sha256-prefix of the body so subtle body changes
 * (with same length) are still detected.
 */
export async function hashToolInput(
  toolInput: Record<string, unknown>,
  toolName?: string,
): Promise<string> {
  // toolName is optional only for backwards compatibility with callers
  // that haven't been updated yet. When absent we use the safe fallback
  // (canonical-JSON of the entire input).
  const projection = toolName != null
    ? visibleProjectionForTool(toolName, toolInput)
    : { _tool: "_unknown", _full: toolInput };

  // For body-bearing tools, populate body_sha256_prefix (first 16 hex
  // chars of sha256(body)) so length-preserving body tampering is
  // still detected.
  if (
    typeof projection.body_length === "number" &&
    typeof toolInput.body === "string"
  ) {
    const bodyHash = await sha256Hex(toolInput.body);
    projection.body_sha256_prefix = bodyHash.slice(0, 16);
  }

  return sha256Hex(canonicalJsonStringify(projection));
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
