// deadline_pipeline_test.ts — Phase 2 Pkg 9 deadline radar end-to-end.
// -----------------------------------------------------------------------------
// Run with:
//   deno test --allow-read --allow-env \
//     supabase/functions/_tests/deadline_pipeline_test.ts
//
// What this exercises (architect §10 #4 + #6 + #7):
//   - PDF parser shape → handlePdfPayload → upsert-row dedupe key matches
//   - Intake wizard shape → handleIntakePayload → identical natural-key
//   - Notifier idempotency: thresholdsForDelta + deduped log = exactly-once
//     fire per (deadline_id, threshold, channel) even when cron drifts
//   - Critical bypasses quiet hours; non-critical defers; both write logs
//   - Completed status survives a re-extraction (architect Risk #5)
//
// We deliberately do NOT spin up a real Postgres in Deno tests (the repo
// pattern is contract+pure-function, with CI integration handled by
// migration apply against a staging DB). Instead this file builds a minimal
// in-memory `case_deadlines` + `deadline_notification_log` shape and runs
// the real router functions through it. Any DB-shape change requires
// updating both this stub and the migration; the migration contract test
// (test/contract/deadline_radar_migration_contract_test.dart) catches the
// SQL-side; this file catches the routing logic.
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertFalse,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  handleIntakePayload,
  handlePdfPayload,
} from "../deadline-extractor/index.ts";
import {
  deliveryDecision,
  isCritical,
  thresholdsForDelta,
  type Threshold,
} from "../deadline-radar-tick/thresholds.ts";

// =============================================================================
// In-memory DB stubs — mirror the case_deadlines + notification_log shape.
// =============================================================================

interface CaseDeadlineRow {
  id: string;
  case_id: string;
  user_id: string;
  title: string;
  anchor_key: string | null;
  deadline_at: string;
  status: "active" | "completed" | "missed" | "archived";
  priority: "critical" | "high" | "medium" | "low";
  source: string;
}

interface NotificationLogRow {
  deadline_id: string;
  threshold: Threshold;
  channel: "push" | "email" | "in_app";
}

class FakeCaseDeadlinesTable {
  rows: CaseDeadlineRow[] = [];
  /** Mirrors the partial unique index on (case_id, anchor_key, date)
   * declared in 20260507_10_case_deadlines.sql. Returns id of upserted
   * row + a flag indicating if completed-status preserved. */
  upsert(
    caseId: string,
    userId: string,
    candidate: Record<string, unknown>,
  ): { id: string; reopened: boolean; skippedCompleted: boolean } {
    const anchorKey = candidate.anchor_key as string | null;
    const dateOnly = String(candidate.deadline_at).slice(0, 10);
    let existing: CaseDeadlineRow | undefined;
    if (anchorKey) {
      // Natural-key dedupe (anchor_key not null path).
      existing = this.rows.find((r) =>
        r.case_id === caseId &&
        r.anchor_key === anchorKey &&
        r.deadline_at.slice(0, 10) === dateOnly
      );
    }
    if (existing) {
      // Architect Risk #5: never reopen a completed deadline.
      if (existing.status === "completed") {
        return {
          id: existing.id,
          reopened: false,
          skippedCompleted: true,
        };
      }
      // Update mutable fields, keep status.
      existing.title = (candidate.title as string) ?? existing.title;
      existing.deadline_at = (candidate.deadline_at as string) ??
        existing.deadline_at;
      existing.priority = (candidate.priority as
        | "critical"
        | "high"
        | "medium"
        | "low") ?? existing.priority;
      return { id: existing.id, reopened: false, skippedCompleted: false };
    }
    const id = `d-${this.rows.length + 1}`;
    this.rows.push({
      id,
      case_id: caseId,
      user_id: userId,
      title: (candidate.title as string) ?? "Deadline",
      anchor_key: anchorKey,
      deadline_at: candidate.deadline_at as string,
      status: "active",
      priority: (candidate.priority as
        | "critical"
        | "high"
        | "medium"
        | "low") ?? "high",
      source: (candidate.source as string) ?? "manual",
    });
    return { id, reopened: false, skippedCompleted: false };
  }
  byId(id: string): CaseDeadlineRow | undefined {
    return this.rows.find((r) => r.id === id);
  }
  markCompleted(id: string): void {
    const r = this.byId(id);
    if (r) r.status = "completed";
  }
}

class FakeNotificationLog {
  rows: NotificationLogRow[] = [];
  /** Mirrors the unique(deadline_id, threshold, channel) constraint
   * from migration 20260507_11. Returns true if the row was actually
   * inserted (first time); false on the unique-violation no-op. */
  tryInsert(deadlineId: string, threshold: Threshold, channel: NotificationLogRow["channel"]): boolean {
    const dup = this.rows.find((r) =>
      r.deadline_id === deadlineId &&
      r.threshold === threshold &&
      r.channel === channel
    );
    if (dup) return false;
    this.rows.push({ deadline_id: deadlineId, threshold, channel });
    return true;
  }
}

/** A single tick of the deadline-radar-tick logic, but operating against
 * the in-memory fake. Mirrors the per-row loop in
 * supabase/functions/deadline-radar-tick/index.ts so behavior changes
 * ripple to this test if the router shape moves. */
function runRadarTick(
  deadlines: FakeCaseDeadlinesTable,
  log: FakeNotificationLog,
  now: Date,
  tz: string,
): { pushed: number; deferred: number; emailed: number; inApp: number } {
  let pushed = 0;
  let deferred = 0;
  let emailed = 0;
  let inApp = 0;
  for (const row of deadlines.rows) {
    if (row.status !== "active") continue;
    const deadlineAt = new Date(row.deadline_at);
    const deltaSec = Math.floor(
      (deadlineAt.getTime() - now.getTime()) / 1000,
    );
    const matches = thresholdsForDelta(deltaSec);
    for (const threshold of matches) {
      const decision = deliveryDecision(threshold, now, tz);
      if (decision === "defer") {
        deferred += 1;
        continue;
      }
      // push channel — every threshold.
      if (log.tryInsert(row.id, threshold, "push")) pushed += 1;
      // in-app channel — every threshold.
      if (log.tryInsert(row.id, threshold, "in_app")) inApp += 1;
      // email channel — only critical priority + critical threshold.
      if (row.priority === "critical" && isCritical(threshold)) {
        if (log.tryInsert(row.id, threshold, "email")) emailed += 1;
      }
    }
  }
  return { pushed, deferred, emailed, inApp };
}

// =============================================================================
// 1. PDF parser → extractor → DB row written
// =============================================================================

Deno.test("PIPE-T01 — FI Migri päätös PDF flows end-to-end into one DB row", () => {
  const deadlines = new FakeCaseDeadlinesTable();

  // pdf-parser emits {date, what, statute} after extracting from a Migri
  // päätös. The parser already pre-computes the absolute deadline.
  const pdfPayload = {
    doc_type: "court_decision",
    deadlines: [{
      date: "2026-06-12",
      what: "Valitus KHO:hon 30 päivän kuluessa",
      statute: "HOL §164",
    }],
    source_doc_id: "00000000-0000-0000-0000-000000000001",
  };

  const candidates = handlePdfPayload(pdfPayload, "FI");
  // The PDF router emits one row per matching anchor; FI court_decision
  // matches fi_hol_2019_808_khoa.
  const matched = candidates.find((c) =>
    c.anchor_key === "fi_hol_2019_808_khoa"
  );
  assert(matched, "PDF payload must produce a matched anchor row");

  // Stamp the source the way deadline-extractor's HTTP handler does.
  matched.source = "pdf";
  const result = deadlines.upsert("case-1", "user-1", matched);
  assertFalse(result.skippedCompleted);
  assertEquals(deadlines.rows.length, 1);
  assertEquals(deadlines.rows[0].anchor_key, "fi_hol_2019_808_khoa");
});

Deno.test("PIPE-T02 — same kaebus deadline from PDF AND intake → exactly one row (dedupe)", () => {
  // Architect §5: the natural key is (case_id, anchor_key, deadline_at::date).
  // Two extractions of the same deadline must NOT create two rows.
  const deadlines = new FakeCaseDeadlinesTable();

  // Path 1: PDF extracts the deadline.
  const pdf = handlePdfPayload({
    doc_type: "court_decision",
    deadlines: [{ date: "2026-06-10", what: "Kaebus", statute: "HKMS §46" }],
  }, "EE").find((r) => r.anchor_key === "ee_hkms_46_kaebus");
  assert(pdf);
  pdf!.source = "pdf";
  deadlines.upsert("case-1", "user-1", pdf!);

  // Path 2: intake wizard runs with the same service date a moment later
  // and computes the SAME absolute deadline.
  // 2026-05-06 (Wed) + 5d HMS §27 = 2026-05-11 (Mon) + 30d = 2026-06-10 (Wed).
  const intake = handleIntakePayload({
    doc_type: "court_decision",
    service_date: "2026-05-06",
  }, "EE").find((r) => r.anchor_key === "ee_hkms_46_kaebus");
  assert(intake);
  intake!.source = "intake";
  deadlines.upsert("case-1", "user-1", intake!);

  // Dedupe MUST keep us at one row.
  assertEquals(
    deadlines.rows.length,
    1,
    "natural key (case_id, anchor_key, deadline_at::date) must dedupe",
  );
  // The natural-key match is the date portion. Both paths must produce
  // the same yyyy-mm-dd; that's what enables dedupe.
  assertEquals(
    String(pdf!.deadline_at).slice(0, 10),
    String(intake!.deadline_at).slice(0, 10),
  );
});

// =============================================================================
// 2. Notifier scheduler picks up the deadline → log entry per threshold
// =============================================================================

Deno.test(
  "PIPE-T10 — radar tick fires push+in_app exactly once per threshold per cron pass",
  () => {
    const deadlines = new FakeCaseDeadlinesTable();
    const log = new FakeNotificationLog();
    const now = new Date("2026-06-09T12:00:00Z"); // deadline 3 days out

    // Insert a critical deadline 3 days from `now`.
    deadlines.rows.push({
      id: "d-critical-3d",
      case_id: "case-1",
      user_id: "user-1",
      title: "Kaebus",
      anchor_key: "ee_hkms_46_kaebus",
      deadline_at: new Date(
        now.getTime() + 3 * 24 * 3600 * 1000 - 60_000,
      ).toISOString(),
      status: "active",
      priority: "critical",
      source: "pdf",
    });

    // First tick — fires push + in_app (3d threshold) + email (critical).
    const r1 = runRadarTick(deadlines, log, now, "Europe/Helsinki");
    assertEquals(r1.pushed, 1);
    assertEquals(r1.inApp, 1);
    assertEquals(r1.emailed, 1);

    // Second tick a minute later (cron drift simulation) — must NOT
    // double-fire. Architect §6 + Risk #3.
    const tick2Now = new Date(now.getTime() + 60_000);
    const r2 = runRadarTick(deadlines, log, tick2Now, "Europe/Helsinki");
    assertEquals(r2.pushed, 0, "duplicate push blocked by unique constraint");
    assertEquals(r2.inApp, 0);
    assertEquals(r2.emailed, 0);

    // Log carries exactly one row per channel for the 3d threshold.
    assertEquals(log.rows.length, 3);
    const channels = log.rows.map((r) => r.channel).sort();
    assertEquals(channels, ["email", "in_app", "push"]);
  },
);

Deno.test(
  "PIPE-T11 — critical threshold (3d) bypasses quiet hours; non-critical (7d) defers",
  () => {
    const deadlines = new FakeCaseDeadlinesTable();
    const log = new FakeNotificationLog();
    // 22:00 Helsinki time = 19:00 UTC in DST. Quiet hours window.
    const quietNow = new Date("2026-06-09T19:00:00Z");

    // 3d-critical row.
    deadlines.rows.push({
      id: "d-3d",
      case_id: "case-1",
      user_id: "user-1",
      title: "Kaebus",
      anchor_key: "ee_hkms_46_kaebus",
      // 3d in the future from quietNow.
      deadline_at: new Date(
        quietNow.getTime() + 3 * 24 * 3600 * 1000 - 60_000,
      ).toISOString(),
      status: "active",
      priority: "critical",
      source: "pdf",
    });
    // 7d-medium row.
    deadlines.rows.push({
      id: "d-7d",
      case_id: "case-1",
      user_id: "user-1",
      title: "Vaie",
      anchor_key: "ee_hms_75_vaie",
      deadline_at: new Date(
        quietNow.getTime() + 6 * 24 * 3600 * 1000,
      ).toISOString(),
      status: "active",
      priority: "high",
      source: "pdf",
    });

    const r = runRadarTick(deadlines, log, quietNow, "Europe/Helsinki");
    // Critical 3d row fires (push + in_app + email = three log inserts).
    // Non-critical 7d row defers — the entire threshold pass is skipped,
    // so `deferred` increments once per matching threshold.
    assertEquals(
      r.deferred >= 1,
      true,
      "non-critical 7d threshold must defer at least once during quiet hours",
    );
    // The critical row fired all three channels.
    const fired = log.rows.filter((r) => r.deadline_id === "d-3d");
    assertEquals(fired.length, 3);
    // The 7d row fired NOTHING this tick.
    const fired7d = log.rows.filter((r) => r.deadline_id === "d-7d");
    assertEquals(fired7d.length, 0);
  },
);

// =============================================================================
// 3. Completed deadline never re-fires even if Haiku re-extracts same date
// =============================================================================

Deno.test(
  "PIPE-T20 — completed deadline survives Haiku re-extraction (architect Risk #5)",
  () => {
    const deadlines = new FakeCaseDeadlinesTable();
    // Seed: one already-completed row for this anchor + date.
    deadlines.rows.push({
      id: "d-done",
      case_id: "case-1",
      user_id: "user-1",
      title: "Kaebus",
      anchor_key: "ee_hkms_46_kaebus",
      deadline_at: "2026-06-10T00:00:00.000Z",
      status: "completed",
      priority: "critical",
      source: "pdf",
    });

    // Haiku re-extracts the same date 5 minutes later (chat turn flow).
    const reExtract = handleIntakePayload({
      doc_type: "court_decision",
      service_date: "2026-05-06",
    }, "EE").find((r) => r.anchor_key === "ee_hkms_46_kaebus");
    assert(reExtract);
    const result = deadlines.upsert("case-1", "user-1", reExtract!);
    assert(result.skippedCompleted, "completed row must NOT reopen");

    // Single row, status still completed.
    assertEquals(deadlines.rows.length, 1);
    assertEquals(deadlines.rows[0].status, "completed");
  },
);

Deno.test(
  "PIPE-T21 — completed deadlines never re-fire on subsequent ticks",
  () => {
    const deadlines = new FakeCaseDeadlinesTable();
    const log = new FakeNotificationLog();
    const now = new Date("2026-06-09T12:00:00Z");

    // Insert a completed row 1 day out — should NOT trigger any push.
    deadlines.rows.push({
      id: "d-done-1d",
      case_id: "case-1",
      user_id: "user-1",
      title: "Kaebus",
      anchor_key: "ee_hkms_46_kaebus",
      deadline_at: new Date(
        now.getTime() + 24 * 3600 * 1000,
      ).toISOString(),
      status: "completed",
      priority: "critical",
      source: "pdf",
    });

    const r = runRadarTick(deadlines, log, now, "Europe/Helsinki");
    assertEquals(r.pushed, 0);
    assertEquals(r.inApp, 0);
    assertEquals(r.emailed, 0);
    assertEquals(log.rows.length, 0);
  },
);

// =============================================================================
// 4. Service-date null → empty extraction (architect §10 #6)
// =============================================================================

Deno.test(
  "PIPE-T30 — intake without service_date yields zero rows (no half-baked deadlines)",
  () => {
    const deadlines = new FakeCaseDeadlinesTable();
    // Wizard finishes early with service_date still null (user didn't know).
    const candidates = handleIntakePayload({
      doc_type: "court_decision",
      service_date: null,
    }, "FI");
    assertEquals(candidates.length, 0);
    // Nothing flows into the DB.
    for (const c of candidates) {
      deadlines.upsert("case-1", "user-1", c);
    }
    assertEquals(deadlines.rows.length, 0);
  },
);

// =============================================================================
// 5. Multi-row + multi-tick stability
// =============================================================================

Deno.test(
  "PIPE-T40 — three deadlines at distinct windows fan out without cross-talk",
  () => {
    const deadlines = new FakeCaseDeadlinesTable();
    const log = new FakeNotificationLog();
    const now = new Date("2026-06-01T12:00:00Z");

    // 30d row + 7d row + 3d row.
    deadlines.rows.push(
      {
        id: "d-30",
        case_id: "case-1",
        user_id: "user-1",
        title: "Vaie 30d",
        anchor_key: "ee_hms_75_vaie",
        deadline_at: new Date(now.getTime() + 28 * 86400 * 1000).toISOString(),
        status: "active",
        priority: "high",
        source: "pdf",
      },
      {
        id: "d-7",
        case_id: "case-1",
        user_id: "user-1",
        title: "Kaebus 7d",
        anchor_key: "ee_hkms_46_kaebus",
        deadline_at: new Date(now.getTime() + 6 * 86400 * 1000).toISOString(),
        status: "active",
        priority: "critical",
        source: "pdf",
      },
      {
        id: "d-3",
        case_id: "case-1",
        user_id: "user-1",
        title: "ECHR 3d",
        anchor_key: "eu_echr_protocol_15",
        deadline_at: new Date(
          now.getTime() + (2 * 86400 + 12 * 3600) * 1000,
        ).toISOString(),
        status: "active",
        priority: "critical",
        source: "pdf",
      },
    );

    const r = runRadarTick(deadlines, log, now, "Europe/Helsinki");
    // 30d row: push + in_app (non-critical, daytime → no defer).
    // 7d  row: push + in_app + email NOT (7d is non-critical threshold).
    // 3d  row: push + in_app + email.
    // Total: push=3, in_app=3, email=1.
    assertEquals(r.pushed, 3);
    assertEquals(r.inApp, 3);
    assertEquals(r.emailed, 1);
    // No deferrals during daytime.
    assertEquals(r.deferred, 0);

    // Re-tick — every threshold already logged, nothing new fires.
    const r2 = runRadarTick(deadlines, log, now, "Europe/Helsinki");
    assertEquals(r2.pushed, 0);
    assertEquals(r2.inApp, 0);
    assertEquals(r2.emailed, 0);
  },
);

Deno.test(
  "PIPE-T41 — escalation across ticks: same row, threshold moves 7d → 3d → 1d, each fires once",
  () => {
    const deadlines = new FakeCaseDeadlinesTable();
    const log = new FakeNotificationLog();
    // Pin a deadline at a fixed timestamp; advance `now` to walk windows.
    const deadlineAt = new Date("2026-06-12T12:00:00Z");
    deadlines.rows.push({
      id: "d-walk",
      case_id: "case-1",
      user_id: "user-1",
      title: "Kaebus",
      anchor_key: "ee_hkms_46_kaebus",
      deadline_at: deadlineAt.toISOString(),
      status: "active",
      priority: "critical",
      source: "pdf",
    });

    // Tick 1: 6 days out → 7d window.
    runRadarTick(
      deadlines,
      log,
      new Date(deadlineAt.getTime() - 6 * 86400 * 1000),
      "Europe/Helsinki",
    );
    // Tick 2: 2.5 days out → 3d window.
    runRadarTick(
      deadlines,
      log,
      new Date(deadlineAt.getTime() - (2 * 86400 + 12 * 3600) * 1000),
      "Europe/Helsinki",
    );
    // Tick 3: 24h out → 1d window.
    runRadarTick(
      deadlines,
      log,
      new Date(deadlineAt.getTime() - 24 * 3600 * 1000),
      "Europe/Helsinki",
    );

    // Each unique threshold should have fired once per channel for this
    // critical row: 7d (push, in_app), 3d (push, in_app, email),
    // 1d (push, in_app, email). 7d is non-critical → no email.
    const thresholds = new Set(log.rows.map((r) => r.threshold));
    assertEquals(
      thresholds.size,
      3,
      "three distinct thresholds fired across ticks",
    );
    assert(thresholds.has("7d"));
    assert(thresholds.has("3d"));
    assert(thresholds.has("1d"));

    // 7d → 2 channels; 3d → 3 channels; 1d → 3 channels = 8 rows total.
    assertEquals(log.rows.length, 8);
  },
);
