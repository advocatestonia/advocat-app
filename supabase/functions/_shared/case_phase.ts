// case_phase.ts — Phase 2 Pkg 5 shared module.
// -----------------------------------------------------------------------------
// Pure module — no Deno globals, no I/O. Imported by:
//   * `case-auto-patch/index.ts` (auto-transition logic)
//   * deno tests under `__tests__/`
//
// Spec: docs/architecture/phase2-pkg5-state-machine.md §2 (transition table),
//       §3 (schema), §4 (auto-transitions).
// -----------------------------------------------------------------------------

export type CasePhase = "intake" | "strategy" | "draft" | "wait" | "closed";

export const CASE_PHASES: readonly CasePhase[] = [
  "intake",
  "strategy",
  "draft",
  "wait",
  "closed",
] as const;

export function parseCasePhase(raw: unknown): CasePhase | null {
  if (typeof raw !== "string") return null;
  const v = raw.trim().toLowerCase();
  if (
    v === "intake" || v === "strategy" || v === "draft" ||
    v === "wait" || v === "closed"
  ) {
    return v;
  }
  return null;
}

export interface CasePhaseSnapshot {
  phase: CasePhase;
  case_numbers: unknown;
  parties: unknown;
  key_dates: unknown;
}

export interface CasePhaseSignals {
  userIntentToTransitionTo?: CasePhase;
  userAcceptedDraft?: boolean;
  userSentDocument?: boolean;
}

export function nextAutoPhase(
  snapshot: CasePhaseSnapshot,
  signals: CasePhaseSignals,
): CasePhase | null {
  const target = signals.userIntentToTransitionTo ?? null;

  if (snapshot.phase === "intake") {
    if (target === "strategy" && hasIntakeMinFacts(snapshot)) {
      return "strategy";
    }
    return null;
  }

  if (snapshot.phase === "strategy") {
    if (signals.userAcceptedDraft === true || target === "draft") {
      return "draft";
    }
    return null;
  }

  if (snapshot.phase === "draft") {
    if (signals.userSentDocument === true || target === "wait") {
      return "wait";
    }
    return null;
  }

  // wait, closed: no auto-transition from chat-turn rule.
  return null;
}

export function hasIntakeMinFacts(snapshot: CasePhaseSnapshot): boolean {
  return (
    isNonEmptyArray(snapshot.case_numbers) &&
    isNonEmptyArray(snapshot.parties) &&
    isNonEmptyArray(snapshot.key_dates)
  );
}

function isNonEmptyArray(v: unknown): boolean {
  return Array.isArray(v) && v.length > 0;
}

export interface PhaseTransitionPatch {
  to: CasePhase;
  reason: string;
}

export function parsePhaseTransition(raw: unknown): PhaseTransitionPatch | null {
  if (raw === null || raw === undefined) return null;
  if (typeof raw !== "object" || Array.isArray(raw)) return null;
  const obj = raw as Record<string, unknown>;
  const to = parseCasePhase(obj.to);
  if (to === null) return null;
  if (to === "closed") return null;
  if (to === "intake") return null;
  const reason = typeof obj.reason === "string"
    ? obj.reason.slice(0, 120).trim()
    : "";
  return { to, reason };
}
