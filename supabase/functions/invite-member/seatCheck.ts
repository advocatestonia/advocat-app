// invite-member/seatCheck.ts
// -----------------------------------------------------------------------------
// Pure seat-capacity predicate for invite-time. Extracted so the bound can be
// unit-tested without spinning up Supabase / sending email.
//
// At invite time the new invitee does NOT yet hold a seat (seats increment at
// accept-time). To avoid sending invites that are doomed to 402 on accept, we
// count current seats PLUS outstanding pending invitations and reject when
// admitting one more would breach the limit.
//
// This is a UX guard only. The hard ceilings remain accept-invitation's
// re-check and the org_increment_seats RPC (FOR UPDATE + check constraint).
// -----------------------------------------------------------------------------

/**
 * Returns true when admitting one more member would exceed the seat limit,
 * accounting for seats already taken AND pending (unaccepted) invitations.
 *
 * @param seatCount     Seats currently occupied by active members.
 * @param pendingInvites Outstanding invites not yet accepted/revoked/expired.
 * @param seatLimit     Maximum seats the org's plan permits.
 */
export function wouldExceedSeats(
  seatCount: number,
  pendingInvites: number,
  seatLimit: number,
): boolean {
  const taken = (seatCount ?? 0) + (pendingInvites ?? 0);
  return taken + 1 > (seatLimit ?? 0);
}
