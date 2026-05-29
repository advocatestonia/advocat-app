# Edge Function Import Map — Supply-Chain Lock

**Status:** Active since 2026-05-28
**Closes:** security audit INFRA-02 (`docs/security_audit_2026-05-28/findings/06_infra_security.md`)

## Why this exists

Before this change, ~68 of ~80 edge functions imported:

```ts
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
```

`@2` is a **floating major-version** specifier. esm.sh resolves it to the latest 2.x release at request time. Consequences:

1. **Supply-chain risk.** A malicious or buggy `@supabase/supabase-js@2.55.0` published upstream would silently become the live SDK on the next Supabase Edge cold start — no review window, no PR, no rollback path.
2. **Provider risk.** esm.sh is a third party. If esm.sh's edge nodes or the route to them is compromised, attacker code ships into prod.
3. **Reproducibility drift.** The version that runs in CI's `deno test` is whatever esm.sh served at test time; the version that runs in prod is whatever esm.sh serves at cold start. They are not guaranteed to be the same.

The `import_map.json` in this directory turns every external URL into a **bare specifier** pointing at a **fully-pinned version**. Coupled with `supabase/config.toml`'s `[functions] import_map = "./functions/import_map.json"`, every `supabase functions deploy` ships against the pinned tree.

## How to add a new dependency

1. **Always pin to a full semver.** Never use `@latest`, `@2`, or `@^2.39`. Example:
   ```json
   "uuid": "https://esm.sh/uuid@9.0.1"
   ```
2. Add an entry to `imports` in `import_map.json`.
3. Use the bare specifier in your edge function:
   ```ts
   import { v4 } from "uuid";
   ```
4. Run `deno check supabase/functions/<your-fn>/index.ts --import-map=supabase/functions/import_map.json` locally — must succeed.
5. Commit `import_map.json` together with the function that uses the new dep.

## How to bump an existing dependency

1. **Read the upstream changelog and CVE list first.** Especially for `@supabase/supabase-js`, `stripe`, and `pdf-lib`.
2. Update the version in `import_map.json` in a dedicated PR — never bundle a dep bump with feature work.
3. Run the full Deno test suite locally: `deno test supabase/functions/`.
4. Smoke-test the affected functions on a staging project ref before canary deploy.
5. Document the bump in the PR description: old version, new version, link to changelog, link to security notes.
6. Tag the commit with `dep-bump/<package>@<version>` for auditability.

## What is pinned today

| Specifier | Pinned URL | Notes |
|---|---|---|
| `@supabase/supabase-js` | `https://esm.sh/@supabase/supabase-js@2.39.8` | Matches the 5 fns that were already pinned (classify-contract, contract-review, share-result, whisper-stt, check-ai-quota). |
| `stripe` | `https://esm.sh/stripe@14.14.0?target=deno` | Stripe SDK for Deno runtime. |
| `pdf-lib` | `https://esm.sh/pdf-lib@1.17.1` | PDF generation (used by draft-export-pdf, dsar-export). |
| `fflate` | `https://esm.sh/fflate@0.8.2` | ZIP archive support (DSAR export). |
| `std/http/server` | `https://deno.land/std@0.224.0/http/server.ts` | Note: prefer `Deno.serve` going forward (deno_std is migrating away from this module). |
| `std/assert` | `https://deno.land/std@0.224.0/assert/mod.ts` | Test assertions. |
| `std/testing/asserts` | `https://deno.land/std@0.224.0/assert/mod.ts` | Legacy alias — same file. |

## What was migrated to bare specifiers

As part of the initial 2026-05-28 sweep, the top-5 most-imported URLs were rewritten to bare specifiers in production functions:

- `https://esm.sh/@supabase/supabase-js@2` → `@supabase/supabase-js` (68 call sites)
- `https://esm.sh/@supabase/supabase-js@2.39.8` → `@supabase/supabase-js` (5 call sites — already-pinned, now uniform)

URLs that remained inline (intentional — pinned & rare):

- `https://esm.sh/stripe@14.14.0?target=deno` — `create-checkout` only (kept inline; already pinned).
- `https://esm.sh/pdf-lib@1.17.1` — 3 call sites (kept inline; already pinned).
- `https://esm.sh/fflate@0.8.2` — 1 call site (kept inline; already pinned).
- `https://deno.land/std@0.177.0/http/server.ts` — 77 call sites (kept inline; pinned to a specific minor, low rewrite ROI today; revisit in Wave 3 when migrating to `Deno.serve`).

## Verifying the import map is in effect

```bash
# Check a single function:
deno check supabase/functions/send-email/index.ts \
  --import-map=supabase/functions/import_map.json

# Confirm Supabase CLI picks it up:
supabase functions deploy send-email --project-ref okgnkucgwsytsondrjye --debug 2>&1 | grep -i "import.map"
```

The Supabase CLI auto-detects `supabase/config.toml` and reads the `[functions] import_map` setting.

## Wave 3 — full reproducibility (out of scope today)

A future hardening step is `deno vendor`, which downloads every transitive dep into a committed `vendor/` directory and points the import map at local files. This eliminates the third-party hot path entirely (esm.sh + deno.land are no longer in the cold-start path). Trade-off: ~50 MB more in the repo and a manual refresh cadence.

Tracking issue: see audit INFRA-02 ("Optional Wave 3").

## Cross-reference

- Audit finding: `/Users/ai.place/Advocat/docs/security_audit_2026-05-28/findings/06_infra_security.md` § INFRA-02
- Memory key: `swarm/security_audit_2026-05-28/wave2/deno_pinning`
- Related controls: `supabase/migrations/20260528010000_rate_limits.sql` (INFRA-06), `_shared/auth.ts` (JWT gate)
