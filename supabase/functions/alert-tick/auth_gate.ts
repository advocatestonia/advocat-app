// alert-tick/auth_gate.ts — cron-secret gate.
// -----------------------------------------------------------------------------
// Mirrors deadline-radar-tick/auth_gate.ts. /functions/v1/alert-tick is public
// (Supabase edge fns are reachable on the open internet); without this gate
// anyone could trigger the alert pipeline and spam the Slack channel.
// -----------------------------------------------------------------------------

export type GateResult =
  | { kind: "allow" }
  | { kind: "deny"; status: number; body: { error: string } };

export function checkCronSecret(
  header: string | null,
  envSecret: string | undefined,
): GateResult {
  if (!envSecret) {
    return {
      kind: "deny",
      status: 500,
      body: { error: "Cron secret not configured" },
    };
  }
  if (!header) {
    return { kind: "deny", status: 401, body: { error: "Missing cron secret" } };
  }
  if (header !== envSecret) {
    return { kind: "deny", status: 401, body: { error: "Invalid cron secret" } };
  }
  return { kind: "allow" };
}
