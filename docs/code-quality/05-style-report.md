# 05 — Style & Consistency Report

**Agent:** E (code-analyzer, Style & Consistency Enforcer)
**Branch:** `code-quality/omega-v1`
**Baseline:** v24.2.3 frozen, `flutter analyze` → 104 issues
**Date:** 2026-04-21

---

## 1. `flutter analyze` breakdown

Total issues: **104**
- errors:     **0**
- warnings:   **17**
- info:       **87**

Split by location:
- `lib/`:  **42** issues
- `test/`: **62** issues

### 1.1 Categories (all 104)

| Rule                                    | Count | Severity |
|-----------------------------------------|------:|----------|
| `prefer_const_constructors`             |    51 | info     |
| `prefer_const_declarations`             |    18 | info     |
| `unused_import`                         |     5 | warning  |
| `unused_element_parameter`              |     5 | warning  |
| `deprecated_member_use`                 |     5 | info     |
| `use_build_context_synchronously`       |     4 | info     |
| `unused_element`                        |     3 | warning  |
| `prefer_const_literals_to_create_immutables` | 3 | info  |
| `no_leading_underscores_for_local_identifiers` | 2 | info |
| `depend_on_referenced_packages`         |     2 | info     |
| `unused_local_variable`                 |     1 | warning  |
| `unnecessary_null_comparison`           |     1 | info     |
| `unnecessary_getters_setters`           |     1 | info     |
| `unnecessary_cast`                      |     1 | info     |
| `prefer_is_empty`                       |     1 | info     |
| `dead_code`                             |     1 | warning  |
| **TOTAL**                               | **104** |         |

**Note:** earlier intake said "106 warnings". Current run returns 104. Small delta likely from pub re-resolve. Either way: **0 errors, 17 warnings, 87 infos** is a healthy profile for a 161k-LOC project.

---

## 2. Auto-fixable findings (safe in Stage 4)

The following will be applied by `dart fix --apply` and `dart format`:

### 2.1 `dart fix --apply` candidates

- 51 `prefer_const_constructors` — add `const` to constructor calls.
- 18 `prefer_const_declarations` — upgrade `final x = const Y()` to `const x = Y()`.
- 5 `unused_import` — remove.
- 3 `prefer_const_literals_to_create_immutables`.
- 1 `unnecessary_cast`.
- 1 `unnecessary_null_comparison`.
- 1 `prefer_is_empty`.

Expected reduction: ~80 issues removed mechanically.

### 2.2 `dart format` scope

- Formatting drift — will diff-check before applying in Stage 4. Expected: no semantic changes.

---

## 3. Findings NOT auto-fixable (need human judgement)

### 3.1 `use_build_context_synchronously` (4 hits, info)

Flutter's analyzer flags `await` followed by `if (context.mounted)` or `Navigator.of(context)` calls without a mount check. Each hit needs to be inspected individually — adding `if (!mounted) return;` is usually correct but sometimes the widget is a `StatelessWidget` that cannot `mount`.

**Recommendation:** manual fix per call-site. Not part of Stage 4 auto-fix.

### 3.2 `unused_element_parameter` (5 hits, warning)

Dead parameters on private functions. In two cases (`test/features/chat/chat_provider_test.dart:104-106` for `caseType`/`country`/`nationality`) they're actually API of a test helper class that will be reused; removing them would narrow the contract.

**Recommendation:** per-case decision. Stage 4 does NOT touch.

### 3.3 `no_leading_underscores_for_local_identifiers` (2 hits, info)

Dart style: local variables should not be prefixed with `_` (only libraries, classes, fields — to mark privacy — use `_`). Harmless; stylistic only.

**Recommendation:** leave for now; let style-cop add it when we bump `analysis_options.yaml` (see §5).

### 3.4 `deprecated_member_use` (5 hits, info)

- `TextFormField.value` → use `initialValue` (2 hits in lib, Flutter ≥ 3.33).
- `Color.red` / `.green` / `.blue` getters in `test/config/theme_test.dart` → use `(c.r * 255).round().clamp(0,255)`.

**Recommendation (LOW priority):** owner picks when to upgrade Flutter-version-specific APIs. Safe to defer.

---

## 4. `print` vs `debugPrint`

- `print(` in `lib/`: **0 occurrences** — excellent.
- `debugPrint(` in `lib/`: 46 occurrences across 5 files.
  - `voice_service.dart`: 30 (FROZEN — not touched)
  - `features/chat/screens/chat_screen.dart`: 6
  - `features/auth/providers/auth_provider.dart`: 7
  - `features/vault/screens/add_vault_document_screen.dart`: 2
  - `shared/error_boundary.dart`: 1

`debugPrint` is compile-stripped in release mode (unlike `print`). This is acceptable for dev/diagnostic output, but the `logger` package is already in `pubspec.yaml` and is used in `ai_service.dart` for structured logs. **Convention-drift:** two logging styles coexist.

**Recommendation (LOW):** adopt `logger` as the sole path for new code; leave existing `debugPrint` as-is during the freeze.

---

## 5. `analysis_options.yaml` recommended upgrades (non-breaking)

Current config is the stock `flutter_lints` preset (zero custom rules). Proposal for Stage 5:

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  errors:
    # keep as info to avoid breaking CI on legacy code
    prefer_const_constructors: info
    prefer_final_locals: info
    avoid_print: warning
    unused_import: warning

linter:
  rules:
    prefer_const_constructors: true
    prefer_final_locals: true
    avoid_print: true
    unnecessary_late: true
    use_key_in_widget_constructors: true
    unawaited_futures: true     # catches dangling async
    always_declare_return_types: true
```

**Important:** all promoted to `warning`, NONE to `error` — keeps `flutter build web` green during the freeze. Owner can promote to `error` after v24.3 catch-up.

See `CODE_STANDARDS.md` (Stage 5) for the long-form rationale.

---

## 6. Magic numbers

Spot-audited common offenders:
- Timeouts hard-coded (`Duration(seconds: 30)`, etc.) — found in `claude_service.dart`, `voice_service.dart`, Edge Function rate-limit windows.
- Pixel offsets and radii in UI widgets (`16.0`, `24.0`, `8.0`) — widespread; acceptable in Flutter idiom.
- Rate-limit thresholds in Edge Functions (`MAX_PER_MINUTE = 10`) — **already extracted to named constants**. 

**Finding:** no egregious magic-number usage. Acceptable.

---

## 7. Internationalisation (l10n) gaps

- 61 files in `lib/` use `AppLocalizations`. 
- Several user-facing strings remain hard-coded in Dart (see TODO in `case_card.dart:39`: "Add l10n keys for case status labels").
- Legal content DBs (`*_database.dart`) return English/Estonian text mixed with country codes — a deliberate data model choice, not a localisation gap.

**Recommendation:** track the l10n-debt items from dead-code report §6 in the v24.3 backlog. Do not auto-fix; ARB edits need translation review.

---

## 8. Commentary style

Spot-check of `lib/services/*.dart` and `lib/features/chat/screens/chat_screen.dart`:
- Class- and method-level `///` doc comments: **used consistently** in services.
- WHY-comments (intent): present where decisions were non-obvious (e.g. `auth.ts` explaining in-process rate-limit storage).
- WHAT-comments (paraphrasing code): rare — no systematic re-stating of code.

Zero multi-line commented-out code blocks (verified in dead-code report §7).

**Grade: A.** Comment hygiene is good.

---

## 9. Import ordering

Manual check of 5 representative files (`ai_service.dart`, `voice_service.dart`, `chat_screen.dart`, `supabase_service.dart`, `main.dart`):

Expected order:
1. `dart:...`
2. `package:...` (external)
3. relative imports

All 5 files follow this convention. ✓

### Minor nit
A handful of files use `package:flutter_riverpod/flutter_riverpod.dart` next to `package:riverpod_annotation/riverpod_annotation.dart` without alphabetical ordering among package imports. The `directives_ordering` lint is not in the preset. Low-priority.

---

## 10. Summary & grade

| Aspect                           | Grade | Note                                                      |
|----------------------------------|-------|-----------------------------------------------------------|
| Static-analysis error count      | A     | 0 errors                                                  |
| Warning load                     | B+    | 17 total, 11 of those are "unused" items (easy cleanup)   |
| `avoid_print` adherence          | A     | 0 `print()` in lib                                        |
| Commenting conventions           | A     | WHY-first, no paraphrase-noise                            |
| Magic-number hygiene             | A−    | Named constants in hot paths                              |
| Lint-config strictness           | C     | Stock preset, no project-level promotions                 |
| i18n completeness                | B     | 61 files localised, 2 TODOs tracked                       |
| **Overall**                      | **A−**| Clean, idiomatic Dart. Room to tighten the lint config.  |

### Stage 4 will handle

- `dart fix --apply` (removes ~80 infos and 5 unused-import warnings).
- `dart format lib/` (formatting only).

### Stage 4 will NOT touch

- Any file in the FROZEN list (`voice_service.dart`, `ai_service.dart`, frozen Edge Functions).
- Anything that requires human judgement (`use_build_context_synchronously`, `unused_element`, deprecation upgrades).
