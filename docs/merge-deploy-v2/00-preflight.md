# Phase 0 — Pre-flight (2026-04-22)

## Status: COMPLETE — green baseline captured

## Working state
- Working directory: `/Users/ai.place/Advocat/app/advocat_project`
- Branch at start: `feature/estonia-max` (clean, no uncommitted changes)
- Switched to `main` and pulled from `github` remote (already up to date)
- Git remote: `github` → `https://github.com/advocatestonia/advocat-app.git`

## Baseline (on main @ 52c76e8)

| Metric | Value |
|--------|-------|
| Tests passing | **1181** |
| Tests skipped | 12 |
| Tests failing | 0 |
| Analyzer issues | 50 (warnings/info only, 0 errors) |
| Flutter version | 3.41.6 (stable) |

## Branch SHAs (snapshotted)

| Branch | SHA | Commits ahead of main |
|--------|-----|----------------------|
| `main` | `52c76e8` | — |
| `fix/estonian-corpus` | `631755d` | 4 |
| `feature/estonia-max` | `ca74d34` | 1 |
| `safety/bulletproof` | `3d2a7a2` | 1 |
| `feature/founder-beta-pricing` | `bed3a6f` | 5 |

## Backup tag (rollback point)
- **Tag**: `v2-backup-before-merge-20260422-203954`
- Pushed to `github` remote
- Points to `52c76e8` (main HEAD)

## Rollback command
If any phase goes red: `git reset --hard v2-backup-before-merge-20260422-203954`

## Next: Phase 1 — merge `fix/estonian-corpus`
Expected delta: +some tests (new corpus integrity suite). No existing test regression.
