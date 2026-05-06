// auth_gate.ts — cron-secret gate for deadline-radar-tick.
// -----------------------------------------------------------------------------
// Mirrors deadline-reminder/auth_gate.ts (FIX-5 pattern). The cron pusher
// is publicly reachable via /functions/v1/deadline-radar-tick — without
// this gate, anyone could trigger arbitrary push fan-out. With the gate,
// only pg_cron (which sets the x-cron-secret header from a Postgres GUC)
// can invoke the endpoint.
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
    return {
      kind: "deny",
      status: 401,
      body: { error: "Missing cron secret" },
    };
  }
  if (header !== envSecret) {
    return {
      kind: "deny",
      status: 401,
      body: { error: "Invalid cron secret" },
    };
  }
  return { kind: "allow" };
}
