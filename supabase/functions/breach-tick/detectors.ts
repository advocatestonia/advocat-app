// detectors.ts — pure breach-detection decision logic (Data Fortress).
// ----------------------------------------------------------------------------
// Each detector takes the rows returned by a detect_* DB function and turns
// them into BreachAlert records (kind, severity, affected user, evidence,
// dedup key). Kept pure + I/O-free so the thresholds and shaping are unit-
// testable; index.ts owns the DB calls + notification side effects.
// ----------------------------------------------------------------------------

export interface BreachAlert {
  kind:
    | "mass_read"
    | "staff_offsession"
    | "decrypt_spike"
    | "us_egress_when_eu";
  severity: "low" | "medium" | "high" | "critical";
  actor: string | null;
  affectedUser: string | null;
  evidence: Record<string, unknown>;
  dedupKey: string;
}

/** A YYYY-MM-DDTHH bucket so the same anomaly dedups within the hour. */
export function hourBucket(iso: string): string {
  // iso like 2026-06-14T13:22:05.000Z -> 2026-06-14T13
  return iso.slice(0, 13);
}

/** Rows from detect_mass_read(): {affected_user, event_count}. */
export function fromMassRead(
  rows: Array<{ affected_user: string; event_count: number }>,
  windowMinutes: number,
  threshold: number,
  nowIso: string
): BreachAlert[] {
  const bucket = hourBucket(nowIso);
  return rows.map((r) => {
    // Severity scales with how far over the threshold the count is.
    const ratio = r.event_count / Math.max(threshold, 1);
    const severity: BreachAlert["severity"] =
      ratio >= 3 ? "critical" : ratio >= 2 ? "high" : "medium";
    return {
      kind: "mass_read",
      severity,
      actor: r.affected_user, // self-read mass; actor == subject here
      affectedUser: r.affected_user,
      evidence: {
        event_count: r.event_count,
        window_minutes: windowMinutes,
        threshold,
      },
      dedupKey: `mass_read:${r.affected_user}:${bucket}`,
    };
  });
}

/** Rows from detect_staff_access(): {affected_user, action, event_count}. */
export function fromStaffAccess(
  rows: Array<{ affected_user: string; action: string; event_count: number }>,
  windowMinutes: number,
  nowIso: string
): BreachAlert[] {
  const bucket = hourBucket(nowIso);
  return rows.map((r) => ({
    kind: "staff_offsession" as const,
    // Staff access to a data subject's record is always worth a high-severity
    // reviewable record; admin_access is treated as critical.
    severity: (r.action === "admin_access"
      ? "critical"
      : "high") as BreachAlert["severity"],
    actor: "staff",
    affectedUser: r.affected_user,
    evidence: {
      action: r.action,
      event_count: r.event_count,
      window_minutes: windowMinutes,
    },
    dedupKey: `staff_offsession:${r.affected_user}:${r.action}:${bucket}`,
  }));
}

/**
 * Decide whether a residency breach occurred: an llm_egress recorded with a
 * non-EU region while the configured mode is 'strict'. Caller supplies the
 * count of such events in the window.
 */
export function fromUsEgress(
  nonEuEgressCount: number,
  mode: string,
  windowMinutes: number,
  nowIso: string
): BreachAlert[] {
  if (mode !== "strict" || nonEuEgressCount <= 0) return [];
  return [
    {
      kind: "us_egress_when_eu",
      severity: "critical",
      actor: "system",
      affectedUser: null,
      evidence: {
        non_eu_egress_count: nonEuEgressCount,
        mode,
        window_minutes: windowMinutes,
      },
      dedupKey: `us_egress_when_eu:${hourBucket(nowIso)}`,
    },
  ];
}
