// supabase/functions/referral/anti_abuse.ts
// -----------------------------------------------------------------------------
// Pure anti-abuse decision used by both the referral edge function and the
// Stripe webhook conversion path.
//
// Rule (product spec): "max 12 free months/year per inviter".
//
// We interpret this as a rolling 365-day window over the inviter's
// referral_attributions rows where status='credited' AND free_month_credited_at
// is within now ± 365 days. The 12-count is INCLUSIVE — the 13th attempt is
// blocked.
//
// Why pure? So we can unit-test the decision against fixture data without
// a Supabase instance. The caller does the query and passes the timestamps
// in.
// -----------------------------------------------------------------------------

/** Decision returned by {@link shouldBlockForAbuse}. */
export type AbuseDecision =
  | { kind: "allow"; recentCreditCount: number }
  | {
      kind: "block";
      recentCreditCount: number;
      windowStart: string;
      windowEnd: string;
    };

/** Cap from the product spec: max 12 free months earned per rolling year. */
export const MAX_FREE_MONTHS_PER_YEAR = 12;

/** Window length in milliseconds (365 days, ignores leap seconds). */
export const ABUSE_WINDOW_MS = 365 * 24 * 60 * 60 * 1000;

/**
 * Decide whether a new credit should be blocked.
 *
 * @param creditedAt ISO timestamps for the inviter's prior credited rows.
 *                   Pass every row regardless of date; this function filters
 *                   by the window itself. Order does not matter.
 * @param now        Optional "current" ISO timestamp. Defaults to Date.now().
 *                   Injected so tests can pin the window.
 */
export function shouldBlockForAbuse(
  creditedAt: ReadonlyArray<string>,
  now: Date | string = new Date(),
): AbuseDecision {
  const nowMs = (typeof now === "string" ? new Date(now) : now).getTime();
  const windowStartMs = nowMs - ABUSE_WINDOW_MS;

  let recent = 0;
  for (const t of creditedAt) {
    const ms = new Date(t).getTime();
    if (!Number.isFinite(ms)) continue; // tolerate bad rows
    if (ms >= windowStartMs && ms <= nowMs) recent++;
  }

  if (recent >= MAX_FREE_MONTHS_PER_YEAR) {
    return {
      kind: "block",
      recentCreditCount: recent,
      windowStart: new Date(windowStartMs).toISOString(),
      windowEnd: new Date(nowMs).toISOString(),
    };
  }
  return { kind: "allow", recentCreditCount: recent };
}
