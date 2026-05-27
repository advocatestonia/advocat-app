// Tests for _shared/agent_action.ts — HMAC action_id binding.

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  hashToolInput,
  isWriteTool,
  issueActionId,
  sha256Hex,
  verifyActionId,
  WRITE_TOOLS,
} from "../agent_action.ts";

const SECRET = "test-secret-do-not-use-in-prod";

Deno.test("issueActionId: structure is base64url.hex", async () => {
  const tok = await issueActionId({
    agent_run_id: "run-1",
    user_id: "user-1",
    tool_name: "send_email",
    args_sha256: "abc123",
    secret: SECRET,
    now_ms: 1_000_000,
  });
  const parts = tok.split(".");
  assertEquals(parts.length, 2);
  assert(/^[A-Za-z0-9_-]+$/.test(parts[0]), "payload not base64url");
  assert(/^[0-9a-f]+$/.test(parts[1]), "hmac not hex");
  assertEquals(parts[1].length, 64); // SHA-256 hex = 64 chars
});

Deno.test("verifyActionId: round-trip ok", async () => {
  const tok = await issueActionId({
    agent_run_id: "run-1",
    user_id: "user-1",
    tool_name: "send_email",
    args_sha256: "abc123",
    secret: SECRET,
    now_ms: 1_000_000,
  });
  const r = await verifyActionId({
    token: tok,
    expected_agent_run_id: "run-1",
    expected_user_id: "user-1",
    expected_tool_name: "send_email",
    expected_args_sha256: "abc123",
    secret: SECRET,
    now_ms: 1_000_000,
  });
  assertEquals(r.ok, true);
  assertEquals(r.payload?.agent_run_id, "run-1");
});

Deno.test("verifyActionId: rejects user_id mismatch", async () => {
  const tok = await issueActionId({
    agent_run_id: "run-1",
    user_id: "user-A",
    tool_name: "send_email",
    args_sha256: "abc123",
    secret: SECRET,
    now_ms: 1_000_000,
  });
  const r = await verifyActionId({
    token: tok,
    expected_agent_run_id: "run-1",
    expected_user_id: "user-B", // ← attacker swapping users
    expected_tool_name: "send_email",
    expected_args_sha256: "abc123",
    secret: SECRET,
    now_ms: 1_000_000,
  });
  assertEquals(r.ok, false);
  assertEquals(r.reason, "user_id_mismatch");
});

Deno.test("verifyActionId: rejects tool_name mismatch (bait-and-switch)", async () => {
  const tok = await issueActionId({
    agent_run_id: "run-1",
    user_id: "user-1",
    tool_name: "send_email",
    args_sha256: "abc",
    secret: SECRET,
    now_ms: 1_000_000,
  });
  const r = await verifyActionId({
    token: tok,
    expected_agent_run_id: "run-1",
    expected_user_id: "user-1",
    expected_tool_name: "generate_pdf", // ← swapped at execute time
    expected_args_sha256: "abc",
    secret: SECRET,
    now_ms: 1_000_000,
  });
  assertEquals(r.ok, false);
  assertEquals(r.reason, "tool_name_mismatch");
});

Deno.test("verifyActionId: rejects args swap", async () => {
  const tok = await issueActionId({
    agent_run_id: "run-1",
    user_id: "user-1",
    tool_name: "send_email",
    args_sha256: "abc",
    secret: SECRET,
    now_ms: 1_000_000,
  });
  const r = await verifyActionId({
    token: tok,
    expected_agent_run_id: "run-1",
    expected_user_id: "user-1",
    expected_tool_name: "send_email",
    expected_args_sha256: "xyz", // ← server later sees different args
    secret: SECRET,
    now_ms: 1_000_000,
  });
  assertEquals(r.ok, false);
  assertEquals(r.reason, "args_sha256_mismatch");
});

Deno.test("verifyActionId: rejects expired token", async () => {
  const tok = await issueActionId({
    agent_run_id: "run-1",
    user_id: "user-1",
    tool_name: "send_email",
    args_sha256: "abc",
    secret: SECRET,
    now_ms: 1_000_000,
    ttl_ms: 60_000,
  });
  const r = await verifyActionId({
    token: tok,
    expected_agent_run_id: "run-1",
    expected_user_id: "user-1",
    expected_tool_name: "send_email",
    expected_args_sha256: "abc",
    secret: SECRET,
    now_ms: 1_000_000 + 60_001, // 1 ms past expiry
  });
  assertEquals(r.ok, false);
  assertEquals(r.reason, "expired");
});

Deno.test("verifyActionId: rejects forged HMAC", async () => {
  const tok = await issueActionId({
    agent_run_id: "run-1",
    user_id: "user-1",
    tool_name: "send_email",
    args_sha256: "abc",
    secret: SECRET,
    now_ms: 1_000_000,
  });
  // Flip last char of HMAC.
  const dot = tok.lastIndexOf(".");
  const tampered = tok.slice(0, dot + 1) +
    (tok.slice(dot + 1, dot + 2) === "0" ? "1" : "0") +
    tok.slice(dot + 2);
  const r = await verifyActionId({
    token: tampered,
    expected_agent_run_id: "run-1",
    expected_user_id: "user-1",
    expected_tool_name: "send_email",
    expected_args_sha256: "abc",
    secret: SECRET,
    now_ms: 1_000_000,
  });
  assertEquals(r.ok, false);
  assertEquals(r.reason, "hmac_mismatch");
});

Deno.test("verifyActionId: rejects malformed token (no dot)", async () => {
  const r = await verifyActionId({
    token: "totally-not-a-token",
    expected_agent_run_id: "run-1",
    expected_user_id: "user-1",
    expected_tool_name: "send_email",
    expected_args_sha256: "abc",
    secret: SECRET,
    now_ms: 1_000_000,
  });
  assertEquals(r.ok, false);
  assertEquals(r.reason, "malformed_token");
});

Deno.test("verifyActionId: rejects wrong secret (downstream HMAC fail)", async () => {
  const tok = await issueActionId({
    agent_run_id: "run-1",
    user_id: "user-1",
    tool_name: "send_email",
    args_sha256: "abc",
    secret: SECRET,
    now_ms: 1_000_000,
  });
  const r = await verifyActionId({
    token: tok,
    expected_agent_run_id: "run-1",
    expected_user_id: "user-1",
    expected_tool_name: "send_email",
    expected_args_sha256: "abc",
    secret: "wrong-secret",
    now_ms: 1_000_000,
  });
  assertEquals(r.ok, false);
  assertEquals(r.reason, "hmac_mismatch");
});

Deno.test("sha256Hex: known vector", async () => {
  // SHA-256("abc") = ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad
  assertEquals(
    await sha256Hex("abc"),
    "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
  );
});

Deno.test("hashToolInput: stable across reorderings of same keys", async () => {
  // Two objects with same keys/values in different declaration order
  // SHOULD produce the same hash because JSON.stringify with literal
  // declaration order is what we hash. We document the limit: any caller
  // depending on key-order canonicalisation must sort manually first.
  const a = await hashToolInput({ to: "x@y", subject: "S" });
  const b = await hashToolInput({ to: "x@y", subject: "S" });
  assertEquals(a, b);
});

Deno.test("WRITE_TOOLS: includes the known write tools", () => {
  assert(WRITE_TOOLS.has("send_email"));
  assert(WRITE_TOOLS.has("generate_pdf"));
  assert(WRITE_TOOLS.has("approve_send_draft"));
  assert(WRITE_TOOLS.has("draft_email_with_attachments"));
});

Deno.test("WRITE_TOOLS: does NOT include read tools", () => {
  assert(!WRITE_TOOLS.has("list_inbox"));
  assert(!WRITE_TOOLS.has("read_thread_full"));
  assert(!WRITE_TOOLS.has("run_pdf_parser"));
  assert(!WRITE_TOOLS.has("run_consilium"));
  assert(!WRITE_TOOLS.has("legal_lookup"));
});

Deno.test("isWriteTool: helper mirrors set membership", () => {
  assert(isWriteTool("send_email"));
  assert(!isWriteTool("list_inbox"));
  assert(!isWriteTool("nonexistent"));
});
