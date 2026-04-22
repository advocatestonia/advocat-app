# 01 — Dead Code Report

**Agent:** A (code-analyzer, Dead Code Hunter)
**Branch:** `code-quality/omega-v1`
**Baseline:** v24.2.3 frozen, 1068 tests passing
**Date:** 2026-04-21

> **Non-destructive:** This report only surfaces candidates. Nothing here has been deleted. Owner decides.

---

## 1. Summary

| Metric                         | Count |
|--------------------------------|------:|
| `dart analyze` issues          |   104 |
| Unused imports (warnings)      |     5 |
| Unused elements (declarations) |     5 |
| Dead-code line (warning)       |     1 |
| Unused local variables         |     1 |
| TODO/FIXME markers             |     9 |
| Possibly-dead top-level files  |     2 |
| Files not imported anywhere    |     2 (big) + 8 (models/utils — verify) |

---

## 2. HIGH-SIGNAL FINDING: Two huge DB files appear unused

Two large service files have **zero** `import` references from anywhere in `lib/`:

| File                                                      | Lines  | Bytes     | Imports into it |
|-----------------------------------------------------------|-------:|----------:|----------------:|
| `lib/services/consumer_protection_database.dart`          |  ≈1400 |    41 KB  |               0 |
| `lib/services/deadline_database.dart`                     |  ≈2430 |    92 KB  |               0 |

Both contain structured legal data across 27 EU countries and are well-written — they look like **content that was authored for a future feature and never wired up**.

Note: the *string* `consumer_protection` appears in `case_model.dart` and `cases_provider.dart`, but only as a `CaseType` enum label. The database class `ConsumerProtectionDatabase` is never instantiated or queried anywhere in code or tests.

**Recommendation (owner decision):**
- Option A — Keep in tree if planned for v24.3+/v25 (add a TODO banner at top: "Wiring deferred until feature X").
- Option B — Move to `/docs/reference/` or a separate branch `feature/consumer-protection-db` until used.
- Option C — Delete.

**Do NOT delete silently** — these files are ~3.3 MB of curated legal data.

---

## 3. Unused imports (safe to remove by `dart fix --apply`)

From `flutter analyze`:

| File                                                    | Line | Import                                                              |
|---------------------------------------------------------|-----:|----------------------------------------------------------------------|
| `lib/features/email/screens/email_screen.dart`          |   11 | `../../../shared/widgets/app_card.dart`                              |
| `lib/features/email/screens/email_screen.dart`          |   13 | `../../../shared/widgets/status_chip.dart`                           |
| `test/services/legal_loader_test.dart`                  |    7 | `package:flutter/services.dart`                                      |
| `test/services/notification_service_test.dart`          |    2 | `package:firebase_core_platform_interface/...`                       |
| `test/services/supabase_service_test.dart`              |    7 | `package:advocat/models/user.dart`                                   |

All five are `dart fix --apply`-safe.

---

## 4. Unused elements (declarations not referenced)

| File                                                                         | Line | Symbol                               |
|------------------------------------------------------------------------------|-----:|---------------------------------------|
| `lib/features/cases/screens/cases_list_screen.dart`                          |  182 | `_showFilterSheet` (private method)   |
| `lib/features/email/screens/email_screen.dart`                               |  938 | `_SectionLabel` (private widget)      |
| `lib/features/email/screens/email_screen.dart`                               |  939 | `count` parameter (of `_SectionLabel`)|
| `test/features/chat/chat_provider_test.dart`                                 |   98 | `_TestChatNotifier` (test helper)     |
| `test/services/ai_golden_prompts_test.dart`                                  |   47 | `mustNotContain` param                |

`_showFilterSheet` in cases_list_screen is correlated with this TODO:
> `// TODO: Re-enable filter when case type filtering is implemented` (cases_list_screen.dart:38)

The dead method is the scaffolding for that future filter. **Recommendation: keep in place but flag with a `// ignore: unused_element` comment + link to the TODO**, OR remove now and re-add when the feature ships. Owner call.

---

## 5. Dead code (warning)

| File                                              | Line | Note                   |
|---------------------------------------------------|-----:|------------------------|
| `test/features/chat/chat_provider_test.dart`      |  991 | single unreachable line|

Safe to delete, but it's in test code — low impact.

---

## 6. TODO / FIXME inventory (only 9 total — healthy)

```
lib/config/app_config.dart:52                              TODO(production): MOVE TO SERVER-SIDE PROXY before public launch.
lib/services/ai_service.dart:294                           TODO(production): Enforce server-side in Supabase Edge Function.
lib/services/notification_service.dart:57                  TODO: Send updated token to backend via Supabase
lib/features/auth/screens/register_screen.dart:116         TODO: Open Terms of Service
lib/features/auth/screens/register_screen.dart:120         TODO: Open Privacy Policy
lib/features/checker/widgets/company_report_card.dart:132  TODO: Navigate to case creation with pre-filled data
lib/features/cases/screens/cases_list_screen.dart:38       TODO: Re-enable filter when case type filtering is implemented
lib/features/cases/widgets/case_card.dart:39               TODO: Add l10n keys for case status labels
lib/features/cases/widgets/case_card.dart:51               TODO: Add l10n keys for case type labels
```

**Categorisation:**
- P0 (before public launch): 2 (app_config.dart:52 + ai_service.dart:294 — server-side enforcement)
- UX stubs: 3 (ToS/Privacy open, navigate-to-case, filter reenable)
- l10n debt: 2 (case_card)
- Infra (notifications): 1

All 9 TODOs are **actionable** — none are "ancient cruft". Good hygiene.

---

## 7. Commented-out code blocks > 3 lines

Scanned `lib/**.dart` for runs of `//`-prefixed lines; found **0 multi-line commented-out code blocks** that would require stripping. (Most `//` lines are actual doc comments, which is correct.)

---

## 8. Redundant `pubspec.yaml` dependencies

All 27 prod dependencies have active imports somewhere in `lib/`. No orphans detected.

The `test/services/notification_service_test.dart` uses `firebase_core_platform_interface` which is a *transitive* (not direct) dep — the test imports it accidentally. Unused-import fix (§3) removes that.

---

## 9. Overall size stats

- `lib/` total: **161 892 lines** across **151 files** (incl. 14 locale files = 34 560 LOC)
- l10n files are auto-generated — no action needed
- Content DBs dominate LOC (~80 000 LOC of static legal data)
- Pure business logic is well under 30 000 LOC

---

## 10. Severity scoreboard

| Severity | Item                                              | Recommended action                                 |
|----------|---------------------------------------------------|-----------------------------------------------------|
| MEDIUM   | 2 dead DB files (~130 KB)                         | Owner decision: keep / move / delete                |
| LOW      | 5 unused imports                                  | `dart fix --apply` in Stage 4                       |
| LOW      | 5 unused elements                                 | Keep 1 (tied to TODO), drop the rest case-by-case   |
| LOW      | 1 dead-code line in test                          | Delete in Stage 4                                   |
| INFO     | 9 TODOs                                           | Track in owner's backlog                            |

**Grade for this category: B+** — project is clean; only two large "parked" content files muddy the signal.
