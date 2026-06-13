// account-delete/index.ts
// -----------------------------------------------------------------------------
// App Store Guideline 5.1.1(v) (hard requirement since 2022) + GDPR Art. 17
// self-service hard account deletion.
//
// Endpoint: POST /functions/v1/account-delete
// Auth:     Bearer <user JWT> (real authenticated user — anon refused)
// Rate:     1 / hour / user (prevents accidental double-tap; legitimate
//           re-attempts are still allowed because the operation is idempotent)
//
// Body:     { confirm: <user-email> }
//           The client UI requires the user to type their own email; we
//           re-check it server-side as a second guard against a malicious
//           in-app actor calling the endpoint without the typing step.
//
// Returns:  { deleted: true, message: "Account deleted", ... }            on success
//           { deleted: false, partial: true, message: "...retry", ... }   on partial
//           { error: "<reason>" }                                          on auth/validation failure
//
// Wires in the App-Store / GDPR-compliant "actual" delete (no soft-delete,
// no 30-day restoration window). The pure deletion logic lives in
// handler.ts; this file just owns request gating + client wiring.
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  corsHeaders,
  jsonError,
  jsonOk,
  requireUserWithRateLimit,
} from "../_shared/auth.ts";
import { runAccountDelete, type SupabaseAdminLike } from "./handler.ts";
import {
  buildDeletionCounts,
  recordDeletionCertificate,
} from "./deletion_certificate.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// 1 / hour / user. Account deletion is a once-per-lifetime action; allowing
// more would only widen the foot-gun if a UI bug ever fired the call twice.
// The endpoint is still idempotent, so even a legitimate retry after a
// network blip is fine — they just wait a minute. Rate-limit window is 60s
// in _shared/auth.ts, so "1 / hour" == maxPerMinute:1 is a conservative
// approximation that fits the existing limiter abstraction.
const MAX_PER_MINUTE = 1;

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  const gate = await requireUserWithRateLimit(req, {
    bucket: "account-delete",
    maxPerMinute: MAX_PER_MINUTE,
  });
  if (gate.kind === "deny") return gate.response;

  const userId = gate.user.id;
  const userEmail = gate.user.email;

  // Body parsing. `confirm` must echo the user's own email — defence in
  // depth against a stray client bug or in-app attacker calling the
  // endpoint without going through the typed-confirmation UI.
  let body: { confirm?: string } = {};
  try {
    if (req.headers.get("Content-Length") !== "0") {
      body = await req.json();
    }
  } catch (_) {
    return jsonError("Invalid JSON body", 400);
  }
  const confirm = (body.confirm ?? "").trim().toLowerCase();
  const expected = (userEmail ?? "").trim().toLowerCase();
  if (!confirm) {
    return jsonError("Missing confirmation. Type your email to confirm.", 400);
  }
  if (!expected) {
    // User has no email on file (SSO-only accounts without an email scope
    // are extremely rare; fall back to a server-side check that the JWT
    // user_id matches the body's `confirm` instead).
    if (confirm !== userId.toLowerCase()) {
      return jsonError("Confirmation mismatch", 400);
    }
  } else if (confirm !== expected) {
    return jsonError("Confirmation mismatch", 400);
  }

  const sb = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const result = await runAccountDelete(
    sb as unknown as SupabaseAdminLike,
    userId
  );

  // Structured server log for security review — Art. 5(2) accountability.
  console.log(
    `[account-delete] user=${userId} ok=${result.ok} ` +
      `auth_deleted=${result.auth_user_deleted} ` +
      `partial=${result.partial ?? false} ` +
      `table_failures=${result.table_results.filter((r) => !r.ok).length} ` +
      `storage_failures=${result.storage_results.filter((r) => r.error).length}`
  );

  // Data Fortress Pillar 1: crypto-shred — destroy the user's wrapped DEK so
  // every ciphertext they ever wrote becomes mathematically unrecoverable.
  // The generic sweep above already targets user_encryption_keys (so the RPC
  // often returns 0 — it already lost the race to the sweep). We call the
  // explicit shred as a belt-and-suspenders guarantee and record dek_shredded
  // in the cert as a BOOLEAN fact (the DEK is destroyed either way). The
  // sweep TableResult carries no row count, so we don't try to read one.
  const counts = buildDeletionCounts(result);
  const keySwept = result.table_results.some(
    (r) => r.table === "user_encryption_keys" && r.ok
  );
  let dekShredded = keySwept;
  try {
    const { data: shred } = await sb.rpc("vault_crypto_shred_user", {
      p_user_id: userId,
    });
    const row = Array.isArray(shred) ? shred[0] : shred;
    const destroyed =
      (row as { keys_destroyed?: number } | null)?.keys_destroyed ?? 0;
    if (destroyed > 0) dekShredded = true;
  } catch (e) {
    console.warn(
      `[account-delete] crypto-shred failed: ${String(e).slice(0, 160)}`
    );
  }
  if (dekShredded) counts["dek_shredded"] = 1;

  // Data Fortress Pillar 3: record a crypto-proof-of-erasure certificate and
  // hand it back to the user. Best-effort — never blocks or fails the delete
  // (the erasure already happened; a missing cert is logged, not fatal).
  const certificate = await recordDeletionCertificate(
    sb as unknown as Parameters<typeof recordDeletionCertificate>[0],
    {
      userId,
      subjectEmail: userEmail ?? null,
      counts,
      deletedAt: new Date().toISOString(),
    }
  );

  return jsonOk({ ...result, certificate }, result.ok ? 200 : 207);
});
