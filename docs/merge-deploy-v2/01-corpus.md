# Phase 1 — Merge `fix/estonian-corpus`

## Status: GREEN — merged & pushed

## Merge details
- **Source**: `fix/estonian-corpus` @ `631755d` (4 commits)
- **Target**: `main` @ `52c76e8` (pre-merge)
- **Merge commit**: `d3f58b5`
- **Strategy**: `--no-ff` (preserve branch history)
- **Rebase required**: No — branch was already on top of current main (merge-base == main HEAD)

## Commits merged
```
631755d docs(corpus-fix): diagnose + FINAL reports for Estonian corpus rebuild
76a5b1a test(legal): add corpus integrity suite + calibrate thresholds
e41fce0 fix(legal): rebuild Estonian corpus from RT bulk fetch (59% -> 100%)
bc80347 feat(scripts): Estonian law ingester from Riigi Teataja
```

## Files changed (25)
Key additions:
- `scripts/ingest_estonian_laws.dart` (+590 lines) — RT bulk fetch ingester
- `test/legal/estonian_corpus_integrity_test.dart` (+287 lines) — corpus integrity suite
- `assets/legal/estonia/*.json` — 10 statutes rebuilt (mks, pars, pks, tls, tsms, tsus, tums, vms, vordks, vos)
- `docs/corpus-fix/00-diagnose.md` + `FINAL.md`

Diff: +75,881 insertions, -61,144 deletions.

## Verification results

| Check | Result |
|-------|--------|
| `flutter test` | **1234 passing** (+53 from 1181), 12 skipped, 0 failing |
| `flutter analyze` | 50 issues (warnings/info only, 0 errors) — same as baseline |
| `flutter build web --release` | Success, **main.dart.js = 6.3 MB** (in 5–8.5 MB target) |

## Tag
- `v2-after-corpus-20260422-204531` (pushed to github)

## Next: Phase 2 — merge `feature/estonia-max`
