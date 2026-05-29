# account-delete

Self-service hard account deletion. Implements **App Store Guideline 5.1.1(v)**
(in-app deletion required since 2022) and **GDPR Art. 17** (right to erasure).

## Endpoint

```
POST /functions/v1/account-delete
Authorization: Bearer <user JWT>
Content-Type: application/json

{ "confirm": "<user-email>" }
```

The user must type their own email; the server re-checks the value against
the JWT `email` claim before doing anything destructive.

## Sweep semantics

The handler performs three steps, in order:

1. **App data:** `DELETE FROM <table> WHERE user_id = <uid>` for every entry
   in `USER_DATA_TABLES` (see `handler.ts`). Order is FK-safe (children
   before parents).
2. **Storage:** every object under `<bucket>/<userId>/` is listed and removed
   for each bucket in `STORAGE_BUCKETS`.
3. **Auth:** `supabase.auth.admin.deleteUser(uid)` — last, so a failure here
   leaves a recoverable state (the user retains the auth row and can retry).

Failure in any step does NOT abort subsequent steps — GDPR Art. 17 prefers
**partial erasure** over an aborted one. The response surfaces a
`partial: true` flag in that case and the client UI advises the user to
retry. Retries are idempotent.

## Adding a new user-data table — REQUIRED CHECKLIST

> **STOP.** Read this before you create a table with a `user_id` column.

Whenever you create or rename a `public.*` table that carries any of
`user_id`, `owner_id`, or `created_by`, you MUST:

1. Add `["<new_table>", "<col>"]` to `USER_DATA_TABLES` in `handler.ts`
   (preferred), **or**
2. Add `{ table: "<new_table>", reason: "<GDPR justification>" }` to
   `EXCLUDED_TABLES` in `handler.ts` with a concrete legal reason.

The reason must cite either:
- a specific Art. 17(3) carve-out (`(a)` freedom of expression, `(b)` legal
  obligation, `(c)` public-interest health, `(d)` archiving/research,
  `(e)` legal-claims defence), **or**
- an operational fact (e.g. "cascades from FK", "org-scoped, separate flow").

The CI test `coverage_test.ts` will FAIL the build until one of the above
is done. Do NOT add a table to `EXCLUDED_TABLES` "just to silence CI" —
ask privacy review first.

Mirror the same change in `dsar-export/index.ts` so the Art. 15 access right
discloses what the Art. 17 erasure removes.

## DELETE_STRICT env var

When `DELETE_STRICT=1`, the handler treats `undefined_table` (PostgreSQL
code `42P01`) and `undefined_column` (`42703`) as **errors**, not silent
skips. This is the safety belt against the audit P0-7 catastrophe (the
prior handler listed `cases_v2`, `ai_memory`, `drafts`, `share_results`,
`referrals`, `payments`, `case_correspondence`, `feedback_buttons` — none
of which existed, so they silently passed).

**Default:** `1` in prod (set via `supabase secrets set DELETE_STRICT=1`).
**Default in dev/CI:** `0` because not every env has every migration applied.

When `DELETE_STRICT=1` and a table is missing, the response's
`table_results[i]` entry carries `strictFailure: true` and `ok: false` —
the response status drops from 200 to 207, and `partial: true` is set.

## CI gating

```bash
# Run against prod schema (requires SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY):
deno test --allow-net --allow-env --allow-read \
  supabase/functions/account-delete/coverage_test.ts
```

In a fork-PR build without secrets the test falls back to parsing migration
SQL files. That's a weaker guarantee — the owner is expected to run the
full live-schema check before any account-delete deploy. The script
emits a clear warning to that effect when running in fallback mode.

The `coverage_test.ts` enforces three invariants:

1. Every `public.*` table with a PII column appears in `USER_DATA_TABLES`
   OR `EXCLUDED_TABLES`.
2. Every entry in `USER_DATA_TABLES` corresponds to a table that actually
   exists in the schema (catches typos like the original `cases_v2`).
3. Every `EXCLUDED_TABLES` entry carries a non-empty `reason`.

## E2E verification

```bash
SUPABASE_URL=… \
SUPABASE_SERVICE_ROLE_KEY=… \
SUPABASE_ANON_KEY=… \
bash docs/security_audit_2026-05-28/fixes/wave1_account_delete_verify.sh
```

The script provisions a throw-away test user, seeds sentinel rows in ~25
key tables + a storage object, invokes account-delete, and asserts every
seeded surface returns 0 rows / 0 objects post-delete. Exits 0 on PASS,
1 on FAIL, 2 on setup error. A per-table residual matrix is printed
and persisted to `wave1_account_delete_verify.log` alongside the script.

## DSAR mirror

`dsar-export/index.ts` is the Art. 15 read counterpart. It MUST include
every table that `account-delete` wipes (and additionally `audit_log` /
`attorney_privilege_acceptance`, which are retained post-deletion under
Art. 17(3)(b)/(e) but are still subject to the access right).

If you change `USER_DATA_TABLES`, change `dsar-export` in the same commit.
There is currently no automated mirror check between the two functions —
this is on the manual review checklist.

## Audit trail of this fix

- 2026-05-28 — Wave 1: rebuilt `USER_DATA_TABLES` from the audit canonical
  list (62 tables ⇒ ~46 wiped, ~24 explicitly excluded with reason);
  added `DELETE_STRICT` env gate; added `coverage_test.ts`; added E2E
  verify script; mirrored updates in `dsar-export`.
- Audit findings:
  - `docs/security_audit_2026-05-28/findings/02_database_rls.md` §5
    (canonical PII-column table matrix)
  - `docs/security_audit_2026-05-28/findings/01_edge_functions_security.md`
    P0-03 (10+ missing tables enumerated)

## Owner deployment checklist (do NOT skip)

- [ ] `supabase secrets set DELETE_STRICT=1` in prod project
- [ ] Run `coverage_test.ts` against live schema with service-role key —
      expect PASS
- [ ] Run `wave1_account_delete_verify.sh` against the **staging** project
      (NOT prod) — expect 0 FAIL, 0 ERROR. SKIP entries are acceptable
      for tables that don't exist in this env.
- [ ] Canary deploy `account-delete` and `dsar-export` together (they share
      the table list)
- [ ] Monitor edge fn logs for first hour for `strict_mode:true` partial
      failures; investigate each before treating as noise.
