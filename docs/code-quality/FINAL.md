# FINAL — Code Quality Audit, v24.2.3

**Coordinator:** OMEGA-CODE-DEPT
**Branch:** `code-quality/omega-v1`
**Run window:** 2026-04-21 evening → 2026-04-22 morning (EEST)
**Production impact:** **zero** — no prod deploy, no `gh-pages` push, no Supabase migration.

---

## Headline numbers

| Metric                           | Before  | After   | Delta                          |
|----------------------------------|--------:|--------:|--------------------------------|
| Tests passing                    |    1068 |    1068 | **±0** (baseline preserved)    |
| Tests skipped                    |      11 |      11 | ±0                             |
| `flutter analyze` issues         |     104 |      46 | **−58** (lint config added ~21 unawaited_futures — see §4) |
| … of those: **errors**           |       0 |       0 | ±0                             |
| … of those: **warnings**         |      17 |      35 | +18 (new lint config surfaced async issues) |
| … of those: **info**             |      87 |      11 | **−76**                        |
| Files modified                   |       — |      21 | —                              |
| Commits on this branch           |       — |       5 | —                              |
| FROZEN files touched             |       — |       0 | **0**                          |

**Bottom line:** 76 lint-info issues cleaned up, baseline tests held at 1068/1068, no frozen files touched, audit reports + standards doc + updated analyzer config delivered.

---

## What was found

Five category reports in `docs/code-quality/`. One-paragraph summaries:

1. **Dead code** — `01-dead-code-report.md`. Grade **B+**. 104 analyzer issues, 9 TODOs (all actionable), 5 unused imports (fixed). Standout: two sizable legal-content DB files (`consumer_protection_database.dart` ~1400 LOC, `deadline_database.dart` ~2430 LOC) are **never imported** — curated content that was never wired up. Owner decides keep/move/delete.

2. **Security** — `02-security-audit.md`. Grade **B+/A−**. No hardcoded secrets. 11 of 13 Edge Functions use proper JWT + rate-limit + CORS. Three concrete mediums: (a) `create-checkout` has no user auth (email-spoof risk, limited), (b) no CSP header in `web/index.html`, (c) Claude proxy lacks Unicode-tag sanitiser for prompt injection. All three are owner-decision; no ship-blocker.

3. **Test coverage** — `03-test-coverage.md`. Grade **C+**. Knowledge/search layer at 85–96% (A grade). Paid-feature services underserved: `client_knowledge_service` 0%, `stripe_checkout_service` 16%, `voice_service` 15%, `ai_service` 40%. Top priority: `client_knowledge_service.dart` — it's the new three-tier memory layer (ADR-001) and ships with zero tests.

4. **Architecture** — `04-architecture-review.md`. Grade **B**. Clean layering (`features → services → models`). Nine UI files exceed 1000 LOC (`chat_screen.dart` is 3291). Email-regex duplicated in `login_screen.dart` + `register_screen.dart`. Three Edge Functions still carry their own auth blocks instead of migrating to `_shared/auth.ts`.

5. **Style** — `05-style-report.md`. Grade **A−**. Zero `print()` in `lib/`, good comment hygiene, consistent naming, clean import order. 104 analyzer issues before Stage 4; now 46. New `analysis_options.yaml` surfaces 21 `unawaited_futures` that are candidates for v24.3 hardening.

Full rollup: [`00-SUMMARY.md`](00-SUMMARY.md).

---

## What auto-fix applied (Stage 4)

Four sequential commits, each followed by `flutter test`:

| # | Commit | Scope | Result |
|---|--------|-------|--------|
| 1 | `de0ab9a chore(quality): remove unused imports` | 4 files (1 lib, 3 test) | 1068 green |
| 2 | `1a11dcc chore(quality): remove unnecessary cast + declare transitive test dep` | 3 files | 1068 green |
| 3 | `509a0de chore(quality): apply const optimizations` | 15 files (5 lib, 10 test) | 1068 green |
| 4 | `6843e91 chore(quality): add CODE_STANDARDS.md + tighten analysis_options` | 2 files | 1068 green |

Plus the Stage 2–3 documentation commit:

- `b56a129 docs(quality): add 5 audit reports + summary (OMEGA Stage 2-3)` — 6 new files under `docs/code-quality/`.

**Total commits on branch:** 5.

### Not applied (rejected during Stage 4)

- **`unnecessary_null_comparison` in `document_scan_screen.dart:398`.** `dart fix` stripped a defensive `else { context.pop(true); }` branch that was technically dead (flow analysis said `caseId` was already null-checked) but rewrote the surrounding block with broken indentation. Reverted. Logged for owner review.
- **`dart format lib/`** — 100 of 151 files would be reformatted. Too broad for a freeze window. Only the files auto-fix touched got formatted (which had zero format drift, so no net changes).
- **`deprecated_member_use`** fixes — Flutter-version-sensitive. Deferred to owner.
- **`unused_element` / `unused_element_parameter`** — would remove test-helper API or private scaffolding linked to `// TODO: re-enable filter` markers. Kept.

---

## What requires owner decision

### Security follow-ups (v24.3 backlog)
1. **Add Unicode-tag / RTL-override / NFKC input sanitiser** to `supabase/functions/claude-proxy/index.ts`. ~30 lines. HIGH per the security audit.
2. **Wrap `create-checkout` with `requireUserWithRateLimit`** and pull `customer_email` from the verified session, not the request body. MEDIUM.
3. **Add `Content-Security-Policy`** header to `web/index.html`. MEDIUM. **Do not auto-apply** — preview deploy first, confirm Supabase WebSocket + Stripe frames not blocked.

### Dead or parked code (MEDIUM — your call)
4. `lib/services/consumer_protection_database.dart` — 0 imports. Keep with TODO banner / move to `docs/reference/` / delete?
5. `lib/services/deadline_database.dart` — 0 imports. Same question.

### Refactor backlog (UI files > 1000 LOC, sorted by churn)
6. `lib/features/chat/screens/chat_screen.dart` (3291 LOC) — split into ≤5 focused widgets.
7. `lib/features/rights/screens/rights_detail_screen.dart` (3134 LOC).
8. `lib/features/home/screens/home_screen.dart` (1686 LOC).
9. `lib/features/settings/screens/subscription_screen.dart` (1265 LOC).
10. `lib/features/cases/screens/case_detail_screen.dart` (1131 LOC).

### Coverage backlog
11. `lib/services/client_knowledge_service.dart` → **≥ 75%** (new service, 0% today).
12. `lib/services/stripe_checkout_service.dart` → **≥ 70%** (payment flow, 16% today).
13. `lib/services/supabase_service.dart` → **≥ 60%** (most-imported, 35% today).
14. Edge Function integration tests — only `_shared/auth.ts` has a test today.

### Small consistency wins
15. Extract shared email regex to `lib/shared/utils/validators.dart` (duplicated in 2 auth screens).
16. Migrate `claude-proxy`, `check-ai-quota`, `send-email` onto `_shared/auth.ts` helper.
17. Generate Supabase types (Dart + TS) to catch schema drift — already cost one P1 bug (`deadlines.due_date`).

### Analyzer items left for human judgement
18. `unused_element`: `_showFilterSheet` in `cases_list_screen.dart:182` — tied to `// TODO: re-enable filter`.
19. `unused_element_parameter` × 4 in `test/features/chat/chat_provider_test.dart` — test helper API kept for future use.
20. `unused_local_variable` `glowSize` in `login_screen.dart:186`.
21. `dead_code` in `test/features/chat/chat_provider_test.dart:991` — single unreachable line.
22. `use_build_context_synchronously` × 4 — needs per-site review.
23. 5 × `deprecated_member_use` (Flutter ≥ 3.33 API rename).

None of these are blockers; none are security-sensitive.

---

## Branch state

```
branch: code-quality/omega-v1
commits ahead of main: 5
target for PR: main (submodule-level) OR preserved as reference branch
```

A stray branch `qa/omega-v1` was created automatically mid-run and contains the same HEAD; it can be deleted with `git branch -d qa/omega-v1` (safe — fast-forward identical).

---

## What to do next

The audit does **not** create a PR — per owner rule, PRs are owner-initiated. When ready:

```bash
cd /Users/ai.place/Advocat/app/advocat_project
git push -u origin code-quality/omega-v1
gh pr create \
  --base main \
  --head code-quality/omega-v1 \
  --title "Code quality audit v1 — Stage 2-5 results (no-touch freeze-safe)" \
  --body "See docs/code-quality/FINAL.md for the rollup. All changes are freeze-safe: 1068/1068 tests, 0 frozen files touched, 0 production deploys."
```

Before merging, recommended sanity checks for owner:
- `flutter test` locally (should be 1068 / 11).
- `flutter analyze` (should be 46 issues, 0 errors).
- Review `docs/code-quality/00-SUMMARY.md` — pick which owner-decision items get v24.3 tickets.
- Review `docs/code-quality/CODE_STANDARDS.md` — approve as project standards document.
- Delete stray branch `qa/omega-v1` when done.

**Status: ready for PR review. No autonomous deploy or merge performed.**

---

## Files produced

```
docs/code-quality/00-SUMMARY.md
docs/code-quality/01-dead-code-report.md
docs/code-quality/02-security-audit.md
docs/code-quality/03-test-coverage.md
docs/code-quality/04-architecture-review.md
docs/code-quality/05-style-report.md
docs/code-quality/CODE_STANDARDS.md
docs/code-quality/FINAL.md               (this file)
```

Configuration change:
```
analysis_options.yaml                    (tightened lint config, no errors promoted)
```

Code changes (all freeze-safe, all green):
```
lib/features/chat/screens/chat_screen.dart              (const)
lib/features/email/screens/email_screen.dart            (const + unused imports)
lib/features/home/screens/home_screen.dart              (const)
lib/features/settings/screens/subscription_screen.dart  (const + unnecessary cast)
lib/services/claude_service.dart                        (const)
pubspec.yaml, pubspec.lock                              (declare transitive dev dep)
[+ 10 test files — const optimizations and unused imports]
```
