// =====================================================================
// CasePhase — Phase 2 Pkg 5.
//
// Mirrors the CHECK constraint on `user_cases.phase`:
//   intake | strategy | draft | wait | closed
//
// Schema source of truth: supabase/migrations/20260507_15_case_phase.sql
// Edge-side source of truth: supabase/functions/_shared/case_phase.ts
// =====================================================================

enum CasePhase {
  intake,
  strategy,
  draft,
  wait,
  closed;

  String get dbValue => name;
  String get displayToken => name.toUpperCase();

  static CasePhase? fromDb(String? raw) {
    if (raw == null) return null;
    switch (raw.trim().toLowerCase()) {
      case 'intake':
        return CasePhase.intake;
      case 'strategy':
        return CasePhase.strategy;
      case 'draft':
        return CasePhase.draft;
      case 'wait':
        return CasePhase.wait;
      case 'closed':
        return CasePhase.closed;
      default:
        return null;
    }
  }

  static CasePhase fromDbOrDefault(String? raw) =>
      fromDb(raw) ?? CasePhase.intake;
}
