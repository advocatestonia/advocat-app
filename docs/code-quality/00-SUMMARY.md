# 00 — Code Quality Audit · Executive Summary

**Project:** Advocat v24.2.3 (frozen 2026-04-20)
**Branch:** `code-quality/omega-v1`
**Run:** 2026-04-21, OMEGA-CODE-DEPT coordinator
**Baseline confirmed:** 1068 tests passing, 11 skipped; `flutter analyze` → 104 issues (0 errors).

---

## Overall grade: **B+**

| Category                        | Grade | Report                                      |
|---------------------------------|-------|----------------------------------------------|
| 01 · Dead code / unused items   |  B+   | [`01-dead-code-report.md`](01-dead-code-report.md) |
| 02 · Security                   | B+/A- | [`02-security-audit.md`](02-security-audit.md)     |
| 03 · Test coverage              |  C+   | [`03-test-coverage.md`](03-test-coverage.md)       |
| 04 · Architecture               |  B    | [`04-architecture-review.md`](04-architecture-review.md) |
| 05 · Style & consistency        |  A-   | [`05-style-report.md`](05-style-report.md)         |

The codebase is healthy, disciplined, and well-tested in the knowledge/search layer. The two systemic weaknesses are (a) UI-screen files that have outgrown the 500-line ceiling, and (b) low coverage on paid-feature code paths (payments, voice, AI).

---

## Top 10 critical findings

| # | Severity | Finding                                                                           | Where                                              | Action class         |
|---|----------|------------------------------------------------------------------------------------|----------------------------------------------------|----------------------|
| 1 | HIGH     | Missing prompt-injection input sanitiser (Unicode tags, RTL overrides)            | `claude-proxy/index.ts`                            | Owner decision       |
| 2 | MEDIUM   | `create-checkout` Edge Function has no user authentication                        | `supabase/functions/create-checkout/index.ts`      | Owner decision       |
| 3 | MEDIUM   | No `Content-Security-Policy` header in `web/index.html`                           | `web/index.html`                                   | Owner decision       |
| 4 | MEDIUM   | 2 large DB files (~130 KB) never imported                                         | `consumer_protection_database.dart`, `deadline_database.dart` | Owner decision |
| 5 | MEDIUM   | `client_knowledge_service.dart` (new) ships with **0%** test coverage             | `lib/services/client_knowledge_service.dart`       | Owner decision       |
| 6 | MEDIUM   | `stripe_checkout_service.dart` at 16% coverage (payment flow)                     | `lib/services/stripe_checkout_service.dart`        | Owner decision       |
| 7 | MEDIUM   | UI screens 1000–3300 LOC — maintainability risk                                   | `chat_screen.dart`, `rights_detail_screen.dart`, `home_screen.dart`, etc. | Owner decision |
| 8 | LOW      | Email-regex duplicated in 2 auth screens                                          | `login_screen.dart`, `register_screen.dart`        | Quick win            |
| 9 | LOW      | 5 unused imports, 1 dead-code line                                                | various                                            | **Auto-fix Stage 4** |
|10 | LOW      | 51 `prefer_const_constructors` + 18 `prefer_const_declarations`                   | various                                            | **Auto-fix Stage 4** |

---

## Quick wins (safe auto-fixes, Stage 4)

These will run now:
1. `dart fix --apply` → removes ~80 analyzer infos, 5 unused imports, 1 unnecessary cast, 1 unnecessary null comparison, 1 dead-code line.
2. `dart format lib/` → formatting-only diff.
3. Commit in small batches with `flutter test` after each.

**NOT in scope for Stage 4** (per owner rules):
- Any edit to `lib/services/voice_service.dart`
- Any edit to `lib/services/ai_service.dart`
- Any edit under `supabase/functions/claude-proxy/`, `tts-proxy/`, `google-tts/`
- File deletions
- Refactors (splitting large files)
- Config changes to `analysis_options.yaml` beyond what Stage 5 documents

---

## Needs owner decision

These items will be documented in `FINAL.md` with clear reasoning; owner decides whether and when to act.

### A. Security follow-ups (for v24.3)
- Add input sanitiser to `claude-proxy` (strip Unicode Tags, RTL overrides, NFKC normalise).
- Wrap `create-checkout` with `requireUserWithRateLimit`.
- Add CSP header to `web/index.html` — deploy to preview branch first.

### B. Dead / parked content
- **`lib/services/consumer_protection_database.dart`** (~1400 LOC, 0 imports)
- **`lib/services/deadline_database.dart`** (~2430 LOC, 0 imports)

Options: (A) keep with TODO banner linking to v25 ticket, (B) move to `docs/reference/`, (C) delete. Owner picks.

### C. Refactor backlog (UI screens > 1000 LOC, in order of change frequency)
1. `chat_screen.dart` — 3291 LOC → target ≤5 files of ≤500 LOC each.
2. `rights_detail_screen.dart` — 3134 LOC → split by section or move content to ARB.
3. `home_screen.dart` — 1686 LOC → extract hero + feature cards.
4. `case_detail_screen.dart` — 1131 LOC → extract tab widgets.
5. `subscription_screen.dart` — 1265 LOC → extract plan cards.

### D. Coverage backlog
1. `client_knowledge_service.dart` → ≥ 75%.
2. `stripe_checkout_service.dart` → ≥ 70%.
3. `supabase_service.dart` → ≥ 60%.
4. Edge Functions integration tests (currently only `_shared/auth.ts` has a test file).

### E. Small consistency fixes
- Extract email-regex to `lib/shared/utils/validators.dart`.
- Migrate `claude-proxy`, `check-ai-quota`, `send-email` onto `_shared/auth.ts`.
- Generate Supabase types to guard against schema drift (Dart↔TS).

---

## What ran in this audit

1. **Stage 1** — checkout `code-quality/omega-v1`, verify 1068/1068 baseline.
2. **Stage 2** — static data-gathering (`flutter analyze`, `dart format`, `flutter test --coverage`, grep/dep scans).
3. **Stage 3** — five category reports written (this summary + 5 files above).
4. **Stage 4** (next) — safe auto-fixes with test-after-each-batch gate.
5. **Stage 5** (next) — `CODE_STANDARDS.md` document + `analysis_options.yaml` proposal.
6. **Stage 6** (next) — `FINAL.md` roll-up + PR command (PR NOT created automatically).

---

## One-line takeaway for the owner

> **Codebase is in good shape. Five "keep an eye on these" items and two parked-code files are worth 30 minutes of your review; the analyzer noise will clean itself up in Stage 4.**
