# 04 — Architecture Review

**Agent:** D (architecture, Architecture Reviewer)
**Branch:** `code-quality/omega-v1`
**Baseline:** v24.2.3 frozen
**Date:** 2026-04-21

---

## 1. At a glance

| Metric                            | Value                 |
|-----------------------------------|-----------------------|
| Total Dart LOC (`lib/`)           | 161 892               |
| Total Dart files (`lib/`)         | 151                   |
| Non-l10n LOC                      | ~127 000              |
| Files > 500 lines                 | 78                    |
| Files > 500 lines (excl. l10n/DB) | 32                    |
| Files > 1000 lines (excl. l10n/DB)|  9                    |
| Layering                          | `features/` → `services/` only (one-way, clean) |

---

## 2. Layering and dependency direction

The codebase is organised as:

```
lib/
├── main.dart
├── config/              # app-wide config, router
├── models/              # plain data classes
├── services/            # backend + domain services (singletons / Riverpod providers)
├── shared/              # cross-feature widgets, utils, error boundary
├── features/            # UI features, each with providers/screens/widgets
│   ├── auth/
│   ├── cases/
│   ├── chat/
│   ├── checker/
│   ├── deadlines/
│   ├── documents/
│   ├── drafts/
│   ├── email/
│   ├── home/
│   ├── legal/
│   ├── legal_aid/
│   ├── onboarding/
│   ├── rights/
│   ├── settings/
│   └── vault/
└── l10n/                # auto-generated
```

**Finding (GOOD):** no `lib/services/*.dart` imports anything from `lib/features/*`. The dependency direction is strictly `features → services → models / config`. That's the correct inversion.

**Finding (MINOR, LOW):** `lib/services/tool_executor.dart` takes a `BuildContext` as a constructor arg (line 74) and imports `package:flutter/material.dart` transitively (via widgets). Services taking a `BuildContext` is a mild smell — it couples the domain layer to the Flutter widget tree. But:
- It's constructed in a `ChangeNotifierProvider` *scoped to a screen*, so the lifetime is managed.
- The alternative (global navigator key + pop-back stack) is arguably worse.

**Recommendation:** accept as-is. Document the intent in a class-level doc comment.

No circular dependencies detected. No other cross-layer violations.

---

## 3. Oversized files (> 500 lines)

Per CLAUDE.md: **Max file size 500 lines.** Below is the hit list (excluding auto-generated localisations & static legal-data DBs).

### 3.1 Top offenders

| File                                                                   |  LOC | Kind                  | Recommendation                                                               |
|------------------------------------------------------------------------|-----:|-----------------------|------------------------------------------------------------------------------|
| `lib/services/knowledge_data_extended.dart`                            | 3408 | Static data           | Acceptable — pure data file                                                  |
| `lib/features/chat/screens/chat_screen.dart`                           | 3291 | UI screen             | **Split** — message list, composer, tool-result rendering, voice wiring     |
| `lib/features/rights/screens/rights_detail_screen.dart`                | 3134 | UI screen             | **Split per country/topic section** or move content to ARB files             |
| `lib/services/email_templates.dart`                                    | 3072 | Static data           | Acceptable — template strings                                                |
| `lib/services/legal_aid_directory.dart`                                | 2042 | Data + lookup         | Split: contact data → JSON asset, lookup logic → code                       |
| `lib/features/home/screens/home_screen.dart`                           | 1686 | UI screen             | **Split** — hero, feature cards, CTA, nav sections                          |
| `lib/services/assistant_tools.dart`                                    | 1586 | Tool definitions      | Split by tool category (case, deadline, doc, search)                        |
| `lib/features/documents/screens/document_scan_screen.dart`             | 1371 | UI screen             | **Split** — camera, ML-kit pipeline, review UI                              |
| `lib/features/chat/widgets/tool_result_card.dart`                      | 1343 | UI widget             | **Split** per result-kind (CaseCreate, VehicleReport, etc.)                 |
| `lib/services/ai_service.dart` (FROZEN)                                | 1297 | Service               | Not touched per owner rule                                                   |
| `lib/features/settings/screens/subscription_screen.dart`               | 1265 | UI screen             | **Split** — plan cards, pricing matrix, checkout CTA                        |
| `lib/features/cases/screens/case_detail_screen.dart`                   | 1131 | UI screen             | **Split** — tabs into own widgets                                           |
| `lib/features/settings/screens/settings_screen.dart`                   | 1018 | UI screen             | **Split** — section widgets                                                 |
| `lib/features/cases/screens/case_create_screen.dart`                   | 1012 | UI screen             | **Split** — stepper steps                                                   |

### 3.2 Severity

- Data files (`knowledge_data_extended`, `email_templates`) — not a problem.
- UI screens > 1000 lines — **MEDIUM priority refactor**. These are the hottest hotspots for merge conflicts, slowest to test, most likely to hide duplicated UI patterns.
- `assistant_tools.dart` and `legal_aid_directory.dart` — **MEDIUM**. Mixing data + logic; each tool/directory entry is isolatable.

None of these are security or correctness risks. They're **readability and change-rate** risks.

---

## 4. Feature-folder consistency

Every feature follows a similar pattern (`providers/`, `screens/`, `widgets/`, sometimes `services/`). Two minor inconsistencies:

1. Only `chat/` has a `features/*/services/` sub-folder (`chat_tool_bridge.dart`). Other features call into `lib/services/` directly.
   - **Recommendation:** either promote feature-local services across all features, or fold `chat_tool_bridge.dart` into `lib/services/` to be consistent. The latter is less churn.

2. Several features are missing a `providers/` folder (`legal/`, `legal_aid/`, `onboarding/`, `vault/`). That's because they're primarily UI-only. No action needed — just document the convention: providers live in `providers/` when the feature needs state; otherwise, none.

---

## 5. Code duplication

### 5.1 HIGH-SIGNAL — Email validation regex duplicated

```
lib/features/auth/screens/register_screen.dart:346  RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
lib/features/auth/screens/login_screen.dart:266     RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
```

Two literal copies of the same (slightly loose) email regex. Should extract to `lib/shared/utils/validators.dart`.

There is likely a third copy in the Edge Functions (`send-email` validates recipients) — cross-file duplication between Dart and TS that cannot be deduped at code level, but should be tracked at **contract level**.

### 5.2 MEDIUM — Auth scaffolding duplicated in Edge Functions

From the security audit (§2.2): `claude-proxy/index.ts`, `check-ai-quota/index.ts`, `send-email/index.ts` each carry their own inline JWT + CORS + rate-limit blocks. The shared `_shared/auth.ts` module already exists; the migration just hasn't covered all endpoints yet. ~50–80 lines of duplicated logic across the three files.

### 5.3 LOW — Legal-DB class shape

Every `*_database.dart` file defines `static Map<String, Map<String, dynamic>> getAllCountries()` returning the same schema. Could be unified under a `LegalCategoryDatabase` interface — but the payoff is questionable since no polymorphic caller loops over them.

---

## 6. Riverpod providers

- ~37 provider files across `features/`. Pattern is consistent: `StateNotifierProvider` / `AsyncNotifierProvider`.
- No observed "god providers" — each notifier has a coherent scope.
- `ToolExecutor` provider takes a `BuildContext` — see §2.
- Generated providers (`@riverpod` annotation) and hand-written providers coexist — mildly inconsistent but both are valid Riverpod patterns.

**No leaks detected** in the code path (providers are correctly `autoDispose` where appropriate for short-lived screens). Runtime leak detection would need Dart DevTools; out of scope for a static audit.

---

## 7. Naming and conventions

- File names: consistent **snake_case** (`client_knowledge_service.dart`, `chat_screen.dart`). ✓
- Class names: **PascalCase** (`ClientKnowledgeService`, `ChatNotifier`). ✓
- Methods / variables: **camelCase**. ✓
- No instances of `snake_case` in Dart identifiers (the 2 hits are in database-mapping comments, intentional: the Postgres column is snake_case). ✓

Convention adherence: **strong**. Nothing to fix.

---

## 8. Cross-language consistency (Dart ↔ TS)

Dart and TS layers share a contract (Supabase table shapes, JSON request/response shapes). There is no code-gen for this — schemas are hand-copied. Areas where drift can cause bugs:

| Contract                     | Dart site                                   | TS site                                                      | Risk |
|------------------------------|---------------------------------------------|--------------------------------------------------------------|------|
| Chat message JSON            | `ai_service.dart` / `claude_service.dart`   | `claude-proxy/index.ts`                                      | M    |
| Email send payload           | `email_service.dart`                        | `send-email/index.ts`                                        | M    |
| Checkout payload             | `stripe_checkout_service.dart`              | `create-checkout/index.ts`                                   | H    |
| Deadline record              | `models/deadline.dart` (if exists)          | `deadline-reminder/index.ts`                                 | M    |
| AI-quota payload             | `ai_service.dart` quota flow                | `check-ai-quota/index.ts`                                    | L    |

The existing P1 bug "`deadlines.due_date` column missing on prod DB" is exactly a symptom of this: Dart code writes a column that wasn't deployed to prod DB.

**Recommendation (LOW for audit, but worth noting):** add a `supabase.types.ts` / `supabase_types.dart` generator step (Supabase CLI has one) to catch drift at compile time. Non-blocking.

---

## 9. `main.dart` and bootstrap

- 34 lines covered, 0/34 in pre-boot code paths (probably because widget tests don't execute `main()`). No concern.
- Deferred loading / chunk splitting not observed — all of `lib/` loads at startup. For a 5–8 MB `main.dart.js` this is fine today; *might* become a concern when content DBs get wired up (see dead-code report §2).

---

## 10. Summary & grade

| Category                       | Grade | Note                                                                |
|--------------------------------|-------|----------------------------------------------------------------------|
| Layering                       | A     | Clean one-way dependency                                             |
| File-size discipline           | C     | 9 files > 1000 LOC in UI; refactor backlog                           |
| Naming consistency             | A     | Strong across the tree                                               |
| Feature-folder uniformity      | B+    | One inconsistency (`chat/services/`)                                 |
| Code duplication               | B     | 1 auth-regex dup; 3 Edge Functions not on shared auth                |
| Provider hygiene               | A−    | Clean scopes; one `BuildContext`-in-service smell                    |
| Dart↔TS contract stability     | C+    | Ad-hoc sync; already produced one P1 bug (deadline.due_date)         |
| **Overall**                    | **B** | Solid architecture that has accrued some UI-layer debt.             |

### Top 3 architecture improvements if owner picks them up

1. Extract shared validators (`validators.dart`) — kill email-regex dup.
2. Finish `_shared/auth.ts` migration across the remaining 3 Edge Functions.
3. Split `chat_screen.dart` (3291 LOC) into ≤5 focused widgets — immediate maintainability win.
