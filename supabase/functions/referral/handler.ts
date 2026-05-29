// supabase/functions/referral/handler.ts
// -----------------------------------------------------------------------------
// Pure-ish dispatcher for the three referral endpoints:
//
//   POST /referral/code        (auth)  → returns user's code, generates if missing
//   POST /referral/attribute   (auth)  → body: { referral_code } → claim it
//   POST /referral/stats       (auth)  → aggregate stats for the inviter screen
//
// The Supabase client is injected so the unit tests can swap in a fake.
//
// Design notes:
//   * /attribute is called by the Flutter signup flow AFTER auth, not during
//     the anon /r/<code> landing. The new user's JWT is the one identifying
//     "who is being attributed". This sidesteps the "anon attribution"
//     security hole (someone forging /attribute calls for arbitrary user_ids).
//   * /attribute is idempotent: a unique constraint on referred_user_id means
//     the second call returns 200 with status='already_attributed' rather
//     than 409.
//   * Self-referral is rejected with 400 ('self_referral'). The DB CHECK
//     would also catch it, but the readable error matters for the client.
//   * Unknown code → 404. We do not leak whether codes exist for OTHER
//     users (the row is publicly readable by RLS — see migration — so this
//     is a cosmetic 404, not a security boundary).
// -----------------------------------------------------------------------------

import { jsonError, jsonOk } from "../_shared/auth.ts";

// deno-lint-ignore no-explicit-any
type SupabaseLike = any;

/** Action argument for {@link routeReferral}. */
export interface ReferralRequest {
  /** "code" | "attribute" | "stats" */
  action: string;
  /** Authenticated user id (already vetted by the caller). */
  userId: string;
  /** JSON body. */
  body: Record<string, unknown>;
}

/** Response from a handler — converted to a Response in index.ts. */
export interface HandlerResult {
  status: number;
  body: Record<string, unknown>;
}

/** Top-level dispatcher. */
export async function routeReferral(
  sb: SupabaseLike,
  req: ReferralRequest,
): Promise<HandlerResult> {
  switch (req.action) {
    case "code":
      return await handleCode(sb, req.userId);
    case "attribute":
      return await handleAttribute(sb, req.userId, req.body);
    case "stats":
      return await handleStats(sb, req.userId);
    default:
      return {
        status: 404,
        body: { error: "Unknown action", action: req.action },
      };
  }
}

// ─── /code ────────────────────────────────────────────────────────────────

/**
 * Returns the user's referral code. Generates one on first call by invoking
 * the get_or_create_referral_code RPC. The RPC handles collision retry.
 */
export async function handleCode(
  sb: SupabaseLike,
  userId: string,
): Promise<HandlerResult> {
  const { data, error } = await sb.rpc("get_or_create_referral_code", {
    p_user_id: userId,
  });
  if (error) {
    // Log raw DB error server-side; return a stable generic code only.
    // Echoing error.message would disclose RPC/table/constraint internals.
    console.error(`referral: get_or_create_referral_code failed: ${error.message}`);
    return {
      status: 500,
      body: { error: "code_generation_failed" },
    };
  }
  if (typeof data !== "string" || data.length === 0) {
    return {
      status: 500,
      body: { error: "code_generation_empty" },
    };
  }
  return {
    status: 200,
    body: {
      code: data,
      share_url: `https://advocat.ee/r/${data}`,
    },
  };
}

// ─── /attribute ───────────────────────────────────────────────────────────

/**
 * Claim a referral code on behalf of the authenticated user (the *referred*
 * party). The inviter is resolved from the code; we never trust an inviter
 * id from the request body.
 */
export async function handleAttribute(
  sb: SupabaseLike,
  userId: string,
  body: Record<string, unknown>,
): Promise<HandlerResult> {
  const rawCode = body.referral_code;
  if (typeof rawCode !== "string" || rawCode.length === 0) {
    return { status: 400, body: { error: "missing_referral_code" } };
  }
  const code = rawCode.trim().toLowerCase().slice(0, 16);
  if (!/^[a-z0-9]{6,16}$/.test(code)) {
    return {
      status: 400,
      body: { error: "invalid_referral_code", reason: "format" },
    };
  }

  // Resolve inviter from the code.
  const { data: codeRow, error: codeErr } = await sb
    .from("referral_codes")
    .select("user_id, code")
    .eq("code", code)
    .maybeSingle();
  if (codeErr) {
    console.error("referral: code lookup failed:", String(codeErr.message));
    return {
      status: 500,
      body: { error: "code_lookup_failed" },
    };
  }
  if (!codeRow) {
    return { status: 404, body: { error: "unknown_referral_code" } };
  }

  const inviterId: string = codeRow.user_id;
  if (inviterId === userId) {
    return { status: 400, body: { error: "self_referral" } };
  }

  // Idempotency: if this user already has an attribution row, return it.
  const { data: existing } = await sb
    .from("referral_attributions")
    .select("id, status, inviter_user_id, referral_code")
    .eq("referred_user_id", userId)
    .maybeSingle();
  if (existing) {
    return {
      status: 200,
      body: {
        already_attributed: true,
        attribution_id: existing.id,
        status: existing.status,
        inviter_user_id: existing.inviter_user_id,
        referral_code: existing.referral_code,
      },
    };
  }

  // Create the attribution row. unique_referred enforces single-claim from
  // the DB side as a defence against the race window between the SELECT
  // above and this INSERT.
  const { data: inserted, error: insErr } = await sb
    .from("referral_attributions")
    .insert({
      inviter_user_id: inviterId,
      referred_user_id: userId,
      referral_code: code,
      status: "attributed",
    })
    .select("id, status")
    .single();
  if (insErr) {
    // Race lost — read what won and return that.
    if (
      typeof insErr.message === "string" &&
      insErr.message.toLowerCase().includes("unique")
    ) {
      const { data: again } = await sb
        .from("referral_attributions")
        .select("id, status")
        .eq("referred_user_id", userId)
        .maybeSingle();
      if (again) {
        return {
          status: 200,
          body: {
            already_attributed: true,
            attribution_id: again.id,
            status: again.status,
          },
        };
      }
    }
    console.error("referral: attribution insert failed:", String(insErr.message));
    return {
      status: 500,
      body: {
        error: "attribution_insert_failed",
      },
    };
  }

  // Best-effort: bump the inviter's invites_sent counter. A failure here is
  // analytics-only; the attribution is the source of truth.
  //
  // PostgREST does not support `column = column + 1` directly. We re-read
  // and write back. Race-safe enough for a counter — concurrent signups
  // via the same inviter are rare and lossy increments here only affect
  // the displayed stats, not credit eligibility.
  const priorInvites = await readInvitesSent(sb, inviterId);
  await sb
    .from("referral_codes")
    .update({ total_invites_sent: priorInvites + 1 })
    .eq("user_id", inviterId);

  return {
    status: 200,
    body: {
      attribution_id: inserted.id,
      status: inserted.status,
      inviter_user_id: inviterId,
    },
  };
}

async function readInvitesSent(
  sb: SupabaseLike,
  inviterId: string,
): Promise<number> {
  const { data } = await sb
    .from("referral_codes")
    .select("total_invites_sent")
    .eq("user_id", inviterId)
    .maybeSingle();
  return Number(data?.total_invites_sent ?? 0);
}

// ─── /stats ───────────────────────────────────────────────────────────────

/**
 * Aggregate stats for the inviter screen: invites sent, conversions, free
 * months earned, current rolling-year credit count.
 */
export async function handleStats(
  sb: SupabaseLike,
  userId: string,
): Promise<HandlerResult> {
  const { data: codeRow } = await sb
    .from("referral_codes")
    .select("code, total_invites_sent, total_conversions, total_free_months_earned")
    .eq("user_id", userId)
    .maybeSingle();

  const { data: attribs } = await sb
    .from("referral_attributions")
    .select("status, free_month_credited_at")
    .eq("inviter_user_id", userId);

  const rows = Array.isArray(attribs) ? attribs : [];
  const conversions = rows.filter((r: { status: string }) =>
    r.status === "converted" || r.status === "credited"
  ).length;
  const credited = rows.filter((r: { status: string }) =>
    r.status === "credited"
  ).length;

  return {
    status: 200,
    body: {
      code: codeRow?.code ?? null,
      share_url: codeRow?.code
        ? `https://advocat.ee/r/${codeRow.code}`
        : null,
      invites_sent: Number(codeRow?.total_invites_sent ?? rows.length),
      conversions: Number(codeRow?.total_conversions ?? conversions),
      free_months_earned: Number(
        codeRow?.total_free_months_earned ?? credited,
      ),
      // Raw computed counts (auth source — independent of denormalised
      // counters in case they drift).
      computed: {
        attributions: rows.length,
        conversions,
        credited,
      },
    },
  };
}

// Re-export the json helpers so index.ts can build Responses uniformly.
export { jsonError, jsonOk };
