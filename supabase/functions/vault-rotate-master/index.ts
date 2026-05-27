// vault-rotate-master/index.ts — HTTP shim for admin-driven master rotation.
// -----------------------------------------------------------------------------
// POST /functions/v1/vault-rotate-master
//   Body: { new_version: 2, batch_size?: 100, max_batches?: 10 }
//   Returns: { version_targeted, batches_run, rotated, skipped, errors, done }
//
// Auth: JWT required + acting user_id must be in ADMIN_USER_IDS env.
// Rate-limit: 5/min (rotation is rare; rate-limiting is here to cap accidental
//             loop runaway, not to gate legitimate use).
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  corsHeaders,
  jsonError,
  jsonOk,
  requireUserWithRateLimit,
} from "../_shared/auth.ts";
import {
  isAdmin,
  parseAdminIds,
  runRotateMaster,
  type SupabaseLike,
} from "./handler.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const ADMIN_USER_IDS = Deno.env.get("ADMIN_USER_IDS") ?? "";

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  const gate = await requireUserWithRateLimit(req, {
    bucket: "vault-rotate-master",
    maxPerMinute: 5,
  });
  if (gate.kind === "deny") return gate.response;

  // Reject anon/synthetic principals — admin gating only makes sense for
  // real user JWTs.
  if (gate.user.id.startsWith("anon:")) {
    return jsonError("Vault rotation requires authenticated admin session", 401);
  }

  // Admin allowlist check.
  const adminIds = parseAdminIds(ADMIN_USER_IDS);
  if (!isAdmin(gate.user.id, adminIds)) {
    // Audit: an unprivileged user attempted master rotation. Log structured
    // so security review can grep for it.
    console.warn(
      `[vault-rotate-master] FORBIDDEN user=${gate.user.id} email=${gate.user.email ?? "—"}`,
    );
    return jsonError("Forbidden — admin only", 403);
  }

  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    return jsonError("Vault backend not configured", 503);
  }

  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return jsonError("Body must be valid JSON", 400);
  }

  const client = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  }) as unknown as SupabaseLike;

  const result = await runRotateMaster(body, { supabase: client, userId: gate.user.id });

  // Structured audit log — Art. 5(2) accountability.
  console.log(
    `[vault-rotate-master] admin=${gate.user.id} ` +
      `kind=${result.kind} status=${result.status} ` +
      (result.kind === "success"
        ? `target_v=${result.body.version_targeted} batches=${result.body.batches_run} ` +
          `rotated=${result.body.rotated} skipped=${result.body.skipped} ` +
          `errors=${result.body.errors} done=${result.body.done}`
        : `error="${result.body.error}"`),
  );

  return result.kind === "success"
    ? jsonOk(result.body, result.status)
    : jsonError(result.body.error, result.status);
});

export { runRotateMaster } from "./handler.ts";
