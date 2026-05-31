// lawyer-booking/outcome.ts
// -----------------------------------------------------------------------------
// Pure handler for op:outcome — the partner lawyer's post-call form. Extracted
// from index.ts so the test suite can inject a fake supabase-like client and
// assert this MONEY path (it snapshots the partner payout into the booking row)
// without standing up a real Supabase stack.
//
// Behaviour is byte-identical to the previous inline handler EXCEPT the
// terminal UPDATE is now a compare-and-swap on the read status (see the
// TOCTOU comment below).
// -----------------------------------------------------------------------------

import { jsonError, jsonOk } from "../_shared/auth.ts";
import type { ValidatedOutcome } from "./validate.ts";

/** Default payout when neither the partner row nor the booking carry a rate. */
const DEFAULT_PAYOUT_CENTS = 2500;

export async function handleOutcome(
  // deno-lint-ignore no-explicit-any
  supabase: any,
  userId: string,
  body: ValidatedOutcome,
): Promise<Response> {
  // The lawyer fills this. Confirm the booking is theirs.
  const { data: booking, error: readErr } = await supabase
    .from("lawyer_bookings")
    .select("id, lawyer_id, status, payout_cents")
    .eq("id", body.bookingId)
    .maybeSingle();
  if (readErr) {
    return jsonError("Booking read failed", 500, { reason: "read_failed" });
  }
  if (!booking) {
    return jsonError("Booking not found", 404, { reason: "not_found" });
  }
  if (booking.lawyer_id !== userId) {
    return jsonError("Not the assigned lawyer", 403, {
      reason: "not_assigned",
    });
  }
  // Completion is terminal. An already-'completed' booking must NOT accept a
  // second outcome submission: re-submitting would silently overwrite the
  // outcome_summary, reset outcome_at, and re-snapshot payout_cents (a changed
  // partner rate would alter the recorded payout) after the fact. Reject as a
  // conflict so the form is idempotent — the first submission wins.
  if (booking.status === "completed") {
    return jsonError("Outcome already recorded for this booking", 409, {
      reason: "already_completed",
      state: booking.status,
    });
  }
  if (
    booking.status !== "confirmed" && booking.status !== "assigned"
  ) {
    return jsonError("Booking cannot be completed in current state", 409, {
      reason: "bad_state",
      state: booking.status,
    });
  }

  // Snapshot payout rate from partner row.
  let payoutCents: number = booking.payout_cents ?? DEFAULT_PAYOUT_CENTS;
  const { data: partner } = await supabase
    .from("partner_lawyers")
    .select("payout_rate_cents")
    .eq("lawyer_id", userId)
    .maybeSingle();
  if (partner?.payout_rate_cents) payoutCents = partner.payout_rate_cents;

  // TOCTOU / double-submit guard (2026-05-31): the status checks above are a
  // READ; the terminal UPDATE used to run with `.eq("id", bookingId)` ONLY,
  // i.e. no status precondition. Two concurrent outcome submissions for the
  // same booking (double-click, retry, replayed request) would BOTH read
  // status='confirmed', BOTH pass the already_completed / bad_state gates, and
  // BOTH write — double-snapshotting payout_cents and double-firing the stats
  // refresh (a money path). The rate limiter does not serialise
  // near-simultaneous requests. We close the window with a compare-and-swap:
  // gate the UPDATE on `.eq("status", booking.status)` so it only mutates the
  // row while it is still in the state we read. `.select("id")` returns the
  // affected rows; an empty result means another request already flipped the
  // row to 'completed' (we lost the race), so we return the same 409
  // already_completed and do NOT double-write the payout. Mirrors the
  // agent-approve (round-4) and referral/conversion.ts CAS pattern.
  const { data: updated, error: updErr } = await supabase
    .from("lawyer_bookings")
    .update({
      outcome_summary: body.outcomeSummary,
      outcome_at: new Date().toISOString(),
      status: "completed",
      payout_cents: payoutCents,
      // paid_out_at left NULL — admin batch-marks payouts monthly.
    })
    .eq("id", body.bookingId)
    .eq("status", booking.status)
    .select("id");
  if (updErr) {
    return jsonError("Outcome update failed", 500, {
      reason: "update_failed",
      detail: updErr.message,
    });
  }
  if (!updated || updated.length === 0) {
    // Lost the race — a concurrent submit already completed this booking.
    // Same response as the up-front idempotency check: first submission wins.
    return jsonError("Outcome already recorded for this booking", 409, {
      reason: "already_completed",
      state: "completed",
    });
  }

  // Refresh denormalised stats (best-effort).
  await supabase.rpc("refresh_partner_lawyer_stats", { p_lawyer: userId })
    .then(() => {})
    .catch((e: unknown) =>
      console.warn("[lawyer-booking] stats refresh failed:", e)
    );

  return jsonOk({ ok: true, status: "completed" });
}
