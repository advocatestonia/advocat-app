# Advocat Code Standards

**Status:** proposal from OMEGA-CODE-DEPT audit, 2026-04-21.
**Scope:** `lib/`, `test/`, `supabase/functions/`.
**Source of truth:** this file + `analysis_options.yaml` linter rules.

This document captures the conventions the codebase already follows (with receipts from the audit) and adds a small number of explicit rules where inconsistencies exist today.

---

## 1. File size

- **Max Dart file size:** **500 lines.** Reflects the rule in project-level `CLAUDE.md`.
- Exception: auto-generated files (`lib/l10n/app_localizations*.dart`).
- Exception: pure static-data files (legal DBs, email templates) — but these must not mix logic and data. Logic goes in a sibling file.

UI screens > 500 lines should extract widget subtrees into `widgets/` within the same feature.

Current outliers (as of audit): `chat_screen.dart` (3291), `rights_detail_screen.dart` (3134), `home_screen.dart` (1686), 6 others. See [`04-architecture-review.md`](04-architecture-review.md) §3 for the full list and refactor priorities.

---

## 2. Comments

- `///` doc comments on public classes and methods explaining **why** the class exists and **what invariants** it holds. Not a paraphrase of the code.
- No multi-line commented-out code blocks. If code needs to be removed, remove it — Git preserves history.
- `// TODO(scope): …` markers are OK when they link to intended future work. They should have a scope tag: `TODO(production)`, `TODO(l10n)`, etc. Current inventory has 9 TODOs — see [`01-dead-code-report.md`](01-dead-code-report.md) §6.
- `// FIXME` is reserved for known-broken code that ships. Use sparingly.

---

## 3. Logging

- **No `print()`** in `lib/`. Current count: 0. Good.
- Prefer the `logger` package (`package:logger/logger.dart`) for structured logs. See `ai_service.dart` for the established pattern.
- `debugPrint(...)` is acceptable during development but should not remain in new code added after this rule is adopted. Existing usages (46 in 5 files, mostly `voice_service.dart`) are grandfathered during the v24.2.3 freeze.

---

## 4. Error handling

- Prefer `try/catch` with explicit failure paths that surface a localised user message. Avoid swallowing exceptions with empty `catch {}`.
- Async errors must either propagate or be handled — no "dangling future" patterns. The linter rule `unawaited_futures` (enabled via this doc's proposed `analysis_options.yaml` delta) will enforce.
- In Riverpod, prefer `AsyncValue<T>` for loading/error state in UI-bound providers.
- Edge Functions: return a typed JSON error via `jsonError(msg, status)` (see `supabase/functions/_shared/auth.ts`). Do not return raw `Error` objects or HTML error pages.

---

## 5. Test coverage

- Critical services (AI, payments, voice, auth, storage) should have **≥ 70% line coverage**.
- New services must not ship to `main` with 0% coverage.
- Coverage baselines captured in [`03-test-coverage.md`](03-test-coverage.md).
- Acceptable exceptions: static-data database files, auto-generated localisation files, simple DTO classes.
- `flutter test` must be green before every commit to `main` or any protected branch. Branch protection + CI enforce this; developers should also run locally.

---

## 6. Imports

Import order in Dart files:

```dart
// 1. dart: libraries
import 'dart:async';
import 'dart:convert';

// 2. package: libraries (alphabetical within the group)
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 3. relative imports (alphabetical)
import '../config/app_config.dart';
import '../models/case_model.dart';
import 'claude_service.dart';
```

No conditional imports unless required for platform-specific stubs (see `web_speech_impl.dart` / `web_speech_stub.dart` pattern).

---

## 7. Naming

- **Files:** `snake_case.dart`.
- **Classes, typedefs, enums:** `PascalCase`.
- **Methods, variables, fields:** `camelCase`.
- **Constants:** `camelCase` (Dart idiom; `const FOO = ...` is not Dart-style).
- **Private members:** `_leadingUnderscore`.
- Feature-folder convention: `features/<feature>/{providers,screens,widgets[,services]}/`.

---

## 8. Security

- **Never commit secrets.** No API keys, passwords, tokens, or PATs in the tree. Current state: clean (see [`02-security-audit.md`](02-security-audit.md) §1).
- All client-side API keys come from `--dart-define` (see `lib/config/app_config.dart`).
- All server-side API keys come from Supabase secrets (`Deno.env.get(...)`).
- Auth on Edge Functions: use `requireUserWithRateLimit(...)` from `supabase/functions/_shared/auth.ts`. See §2 of the security audit for the 3 functions still carrying inline copies.
- All user-bearing tables have RLS policies enforcing `auth.uid() = user_id`.

---

## 9. External services

- No dashboard-click automation (Supabase, Stripe, Google Cloud). Use CLIs or give the operator (owner) instructions.
- Production deploys go through `./scripts/build-and-deploy.sh` — never a hand-run `flutter build web`.
- Rollback: `./scripts/rollback.sh <tag>`.

---

## 10. Git

- Commit on `main` **before** switching to `gh-pages` for deploys (owner rule #9).
- Descriptive commit messages prefixed with `feat`/`fix`/`chore`/`docs`/`refactor`.
- Small, reviewable commits. Do not roll unrelated changes together.
- Never amend published commits. Never `--force` push to `main`.

---

## 11. Dart-specific lints (enforced by `analysis_options.yaml`)

Core rules now enforced (upgrade from stock `flutter_lints` preset — see the file for details):

- `prefer_const_constructors` — warning.
- `prefer_const_declarations` — warning.
- `prefer_final_locals` — warning.
- `avoid_print` — warning.
- `unused_import` — warning.
- `unused_element` — warning.
- `unnecessary_late` — warning.
- `unnecessary_cast` — info.
- `unawaited_futures` — warning.

None of these are promoted to `error` during the v24.2 freeze. They can be promoted once the backlog is empty.

---

## 12. Documentation

- **ADRs:** architecture decisions live in `docs/learning/ADR-NNN-*.md`.
- **Runbooks / deploy docs:** `docs/DEPLOY.md`.
- **Freeze logs:** `docs/FROZEN_*.md`.
- **Quality audits:** `docs/code-quality/`.

Markdown files are not auto-formatted; keep line width ≤ 100 chars for readability.

---

## 13. When in doubt

1. Read the linked Obsidian notes (`/Users/ai.place/Documents/Obsidian Vault/Advocat/`).
2. Read the memory (`.claude/projects/-Users-ai-place-Advocat/memory/`).
3. Ask the owner.

Do not refactor production code unprompted (Rule #0). Do not auto-change external services (Rule #5). Do not commit secrets (Rule #8).
