# ФАЗА 4 — merge launch/wave1

**Дата:** 2026-04-22 18:47 EEST
**Risk:** MEDIUM (legal + UX, conflict resolved)
**Status:** ✅ MERGED

## Merge details

- Source: `launch/wave1` (9 commits ahead of main before rebase)
- After rebase: **9 commits** (no cherry-pick overlap detected this time)
- Target: `main` (post-Phase 3)
- Strategy: `--no-ff` merge commit
- Merge commit: `6030774`
- Pushed to: `github/main`

## Conflict resolution

**File:** `lib/features/chat/screens/chat_screen.dart:1779`

Conflict between `code-quality/omega-v1` (const Expanded with hardcoded EN
text) and `launch/wave1-2` (localised via `AppLocalizations.of(context)`).

**Resolution:** took wave1-2's localisation pattern, removed `const` from
`Expanded` wrapper (required because `AppLocalizations.of(context)` is not a
compile-time constant). This matches existing patterns elsewhere in the file
(lines 225, 699, 808).

Before:
```dart
const Expanded(
  child: Text(
    'Upgrade for unlimited consultations',
```

After:
```dart
Expanded(
  child: Text(
    AppLocalizations.of(context)?.upgradeBannerTitle ??
        'Upgrade for unlimited consultations',
```

No other conflicts during rebase.

## Commits merged (9)

| # | Commit | Content |
|---|---|---|
| 1 | wave1-1 | Legal CRITICAL fixes: deadline reminder enum, create_deadline error surfacing, timezone-safe date parsing, disclaimer policy |
| 2 | wave1-2 | UX Tier-A: focus ring, 44x44 targets, iOS no-zoom, **localised paywall banner** (conflict resolved), deadline tap, autofillHints |
| 3 | wave1-3 | **GDPR cookie banner** on landing.html (accept/reject/learn) — 24 `cookie` mentions in web/landing.html |
| 4 | wave1-4 | **UPL-safe onboarding** titles for ru+uk (rename 'ИИ-юрист'/'ШІ-юрист' → legal-safe copy) |
| 5 | wave1-5 | GDPR Art. 15 + Art. 17 regression tests |
| 6 | wave1-6 | Opt-in Sentry-lite telemetry sink (Supabase app_errors table) |
| 7 | wave-3 | Validation + docs/launch/ rollup |
| 8 | wave3-fix | ARB keys restoration after hook overwrite + Finnish |
| 9 | docs | Correct final test count to 1086 |

## Regression gates

| Gate | Before | After | Δ |
|---|---|---|---|
| Flutter tests pass | 1126 | 1144 | **+18** |
| Skipped | 11 | 11 | 0 |
| Analyze errors | 0 | 0 | 0 |
| Analyze warnings | 1 | 1 | 0 |
| Analyze info | 47 | 47 | 0 |
| Analyze total | 48 | 48 | 0 |
| main.dart.js | 6.49 MB | **6.50 MB** | +10 KB (new features) |
| `flutter build web` | ✅ | ✅ | 24.2s |
| Cookie banner in landing.html | absent | **present** | 24 `cookie` mentions |

## Localization check

All 17 locale dart files regenerated in the merge:
app_en/et/ar/de/es/fa/fi/fr/it/lt/lv/pl/ro/ru/sv/tr/uk (+ app_localizations.dart dispatcher).

## Owner actions (documented, NOT executed)

- Migration `20260421_app_errors_telemetry.sql` — included in `supabase db push` batch (Phase 3 + this = 3 migrations to apply).
- No new secrets or Edge Function deploys beyond those in Phase 3.

## Rollback point

Tag: `after-launch-wave1-20260422-184730` (pushed).

## Ok to proceed → Phase 5 (fix/ai-quality)
