# ФАЗА 0 — Pre-flight Baseline

**Дата:** 2026-04-22 18:31 EEST
**Coordinator:** OMEGA-MERGE-DEPLOY
**Working dir:** `/Users/ai.place/Advocat/app/advocat_project`

## Состояние репозитория на старте

- **Current branch:** был `code-quality/omega-v1`, переключился на `main`
- **Uncommitted:** `docs/launch-now/` (untracked) — застэшено: `stash: omega-merge-deploy: launch-now docs before merge`
- **Remote:** `github` (не `origin`) → `https://advocatestonia:***@github.com/advocatestonia/advocat-app.git`
- **Main HEAD:** `5ada9f4 feat(v24.2.3): native Russian/English voices via ElevenLabs v3`
- **Toolchain:** Flutter 3.41.6 stable (matches v24.2 frozen)

## Backup tag (rollback point)

```
backup-before-merge-20260422-183143
```
Pushed to `github` remote. Restore: `git reset --hard backup-before-merge-20260422-183143`.

## Baseline метрики

| Метрика | Значение |
|---|---|
| `flutter test` | **1068 passed + 11 skipped — all green** (~25s) |
| `flutter analyze` (errors) | **0** |
| `flutter analyze` (warnings) | **17** |
| `flutter analyze` (info) | **87** |
| `flutter analyze` (total) | **104 issues** |

Prod is the source of truth for "no regression": v24.2.3 live at advocat.ee, 21/21 smoke green.

## Merge order (от LOW risk к MEDIUM)

1. `code-quality/omega-v1` — LOW (6 commits)
2. `qa/omega-v1` — LOW (5 commits, +34 tests → ~1102)
3. `fix/sprint0-blockers` — MEDIUM (8 commits, Edge Functions + migrations → owner action)
4. `launch/wave1` — MEDIUM (9 commits, legal + UX Tier-A)
5. `fix/ai-quality` — MEDIUM (3 commits, AI-visible changes)

Ожидаемое финальное состояние: **~1180 tests**, analyze <80 issues, 0 errors.

## Stashed work

```
stash@{0}: omega-merge-deploy: launch-now docs before merge (docs/launch-now/)
```
6 файлов (01-pro-launch-now, 02-contra, 03-liability-numbers, 04-min-viable-compliance, 05-precedents, 06-revenue-math). Вернуть после Phase 10.

## Ok to proceed

Clean tree, main synced, backup pushed, baseline recorded. → **Phase 1 start.**
