// winback-send/winback_logic.ts
// -----------------------------------------------------------------------------
// Pure helpers for the winback worker. Picks the target step, generates the
// promo code, and constructs the unsubscribe URL.
// -----------------------------------------------------------------------------

export type WinbackStep = "d3" | "d7" | "d14";

export interface CandidateRow {
  user_id: string;
  email: string;
  full_name: string;
  preferred_language: string;
  last_active_at: string;
  target_step: string;
  winback_sent_count: number;
}

export interface ProcessedCandidate {
  userId: string;
  email: string;
  fullName: string;
  preferredLang: string;
  step: WinbackStep;
  daysInactive: number;
  promoCode?: string;
}

/** Classify the candidate's days-since-active. */
export function daysInactive(lastActiveAt: string, now: Date): number {
  const last = new Date(lastActiveAt);
  return Math.floor((now.getTime() - last.getTime()) / (24 * 60 * 60 * 1000));
}

/** Normalise the RPC's `target_step` to our enum, defensively. */
export function classifyStep(rawStep: string | null | undefined): WinbackStep | null {
  if (rawStep === "d3" || rawStep === "d7" || rawStep === "d14") return rawStep;
  return null;
}

/**
 * Deterministic promo code generator. Same user always gets the same code
 * (idempotent re-issue if mail provider eats one send). 8 chars, A-Z 0-9
 * with no easily confused glyphs (no 0/O/1/I/L).
 *
 * NB: this is a *display* code. The actual Stripe promotion is created
 * separately by the owner — this function is intentionally NOT a coupon
 * factory; it just produces a stable label per user.
 */
export function promoCodeFor(userId: string): string {
  const alphabet = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";
  let hash = 5381;
  for (let i = 0; i < userId.length; i++) {
    hash = ((hash << 5) + hash + userId.charCodeAt(i)) | 0;
  }
  let n = Math.abs(hash);
  let out = "ADV-";
  for (let i = 0; i < 6; i++) {
    out += alphabet[n % alphabet.length];
    n = Math.floor(n / alphabet.length) + i * 7;
  }
  return out;
}

/** Take raw candidate rows from the RPC, validate, build a typed list. */
export function processCandidates(
  rows: CandidateRow[],
  now: Date,
): ProcessedCandidate[] {
  const out: ProcessedCandidate[] = [];
  for (const r of rows) {
    const step = classifyStep(r.target_step);
    if (!step) continue;
    if ((r.winback_sent_count ?? 0) >= 3) continue;
    const days = daysInactive(r.last_active_at, now);
    out.push({
      userId: r.user_id,
      email: r.email,
      fullName: r.full_name ?? "",
      preferredLang: r.preferred_language ?? "en",
      step,
      daysInactive: days,
      promoCode: step === "d14" ? promoCodeFor(r.user_id) : undefined,
    });
  }
  return out;
}

/** Unsub URL builder — used by both digest and winback. */
export function unsubUrl(appBaseUrl: string, token: string, kind: "winback"): string {
  return `${appBaseUrl}/u/${token}?k=${kind}`;
}
