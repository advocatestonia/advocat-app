# Halt-Rail Runbook

**Owner-facing operations doc.** Last updated: 2026-05-15 (P5 of Bentley batch).

The halt-rail is a serious-case detector + mandatory "consult licensed advocate"
banner wired into `claude-proxy`. It eliminates "unauthorized practice of law"
risk from Eesti Advokatuur / Suomen Asianajajaliitto by ensuring every reply
to a high-stakes legal query ends with an explicit advisory to engage a
licensed `asianajaja` (Finland) / `vandeadvokaat` (Estonia).

## What triggers the rail

Five categories, detected from the most recent user message:

| Category      | Examples (any language)                                                                                                          |
| ------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| `deportation` | käännyttäminen, väljasaatmine, депортация, deportointi, removal order                                                            |
| `custody`     | huoltajuus, ainuhooldusõigus, опека на ребёнка, child custody, parental rights                                                   |
| `criminal`    | rikossyyte, kriminaalmenetlus, kuriteo tunnustega, уголовное дело, indictment                                                    |
| `big_claim`   | any monetary amount > €20,000 (€50 000, 50,000 EUR, 50000€, 50 000 евро)                                                         |
| `echr`        | ihmisoikeustuomioistuin, EIT, EIK, ЕСПЧ, ECHR, Strasbourg court                                                                  |

See `supabase/functions/_shared/halt_rail.ts` for the full keyword tables and
the language-detection heuristic (`detectLangFromMessage`).

## What happens when it fires

1. **PRE-LLM:** `appendHaltRailToSystem()` injects a directive into the system
   prompt so Claude weaves the advisory into the natural reply.
2. **POST-LLM:** `appendHaltRailToResponse()` appends a visible localised
   banner (RU / FI / ET / EN, picked by the user-message language signal)
   to the reply text. Idempotent — if the model already wove in the
   advisory, the appender no-ops.
3. **Metric write:** one row is inserted into `public.halt_rail_triggers`
   via service-role POST. Fire-and-forget — chat replies never block on
   telemetry.
4. **Log line:** `console.log` in claude-proxy:
   `claude-proxy: halt-rail fired: <category> (<reason>)`

## Verifying production

**Run the smoke script:**

```bash
SMOKE_AUTH_JWT="$(supabase_user_jwt)" ./scripts/halt_rail_smoke.sh
```

Expected output: `==> Result: 10/10 fired, 0 failed`.

The script sends 10 trigger queries across EN/RU/FI/ET and all five
categories. It is also wired into the canary deploy if you uncomment the
relevant section in `scripts/canary-deploy.sh`.

**Without a JWT** the script will exit 2; the rail itself runs for anon
callers too, but anon responses are capped at 200 tokens and the rate
limit is 1/min/IP — too tight for a 10-query smoke. Use an authenticated
JWT.

## Monitoring (Supabase SQL Editor)

**Last 24 h firing rate by category × language:**

```sql
SELECT * FROM v_halt_rail_24h;
```

**Recent triggers (full detail):**

```sql
SELECT occurred_at, category, language, reason, amount_eur
FROM halt_rail_triggers
ORDER BY occurred_at DESC
LIMIT 50;
```

**Categories with no triggers in 30 days (possible detection gap):**

```sql
WITH cats AS (
  SELECT unnest(ARRAY['deportation','custody','criminal','big_claim','echr']) AS category
)
SELECT cats.category
FROM cats
LEFT JOIN halt_rail_triggers t
  ON t.category = cats.category
 AND t.occurred_at >= now() - interval '30 days'
WHERE t.id IS NULL;
```

**Likely-missed serious queries (no rail, but message contains a high-stakes
keyword the table doesn't cover):** open the latest `chat_messages` and
grep for terms not yet in `KEYWORDS`. P5 closed three such gaps:
`deportointi` (FI), `опека на ребёнка` (RU prep variant), `kuriteo` (EE).

## Adjusting the keyword tables

If you spot a missed category in production:

1. Edit `supabase/functions/_shared/halt_rail.ts` — add the new stem.
2. Add a regression test in
   `supabase/functions/_shared/__tests__/halt_rail_test.ts` that asserts
   `detectSeriousCase("<missed-query>").isSerious === true`.
3. Run `deno test --no-check --allow-net supabase/functions/_shared/__tests__/halt_rail_test.ts`.
4. Deploy via the standard canary path
   (`./scripts/canary-deploy.sh`) — the smoke includes the existing 33 unit
   tests plus the 3 P5 regressions plus the 6 metric-write tests.

## Adjusting the €-threshold

The big-claim threshold (`BIG_CLAIM_THRESHOLD_EUR`, currently 20 000) lives
at the top of `halt_rail.ts`. Lower it to fire more often (more cautious),
raise it to fire less. The threshold test (`claim at threshold (20000)
does not fire (strictly greater)`) anchors the boundary semantic.

## Banner text edits

The four localised banners live in the `BANNER` map (`halt_rail.ts`,
~line 434). Each banner MUST keep one of these four sentinel substrings,
because the idempotency guard and the smoke script both grep for them:

- `Advocat помогает понять закон`
- `Advocat aitab seadust mõista`
- `Advocat auttaa ymmärtämään lakia`
- `Advocat helps you understand the law`

Changing those phrases breaks idempotency (double banners) and the smoke
script (`0/10 fired`). If you must change them, update all three places
in one commit:

1. `supabase/functions/_shared/halt_rail.ts` — `BANNER` map
2. `supabase/functions/_shared/halt_rail.ts` — `appendHaltRailToResponse`
   idempotency check
3. `scripts/halt_rail_smoke.sh` — `SENTINELS` array

## Production smoke history

| Date       | Result | Notes                                                                          |
| ---------- | ------ | ------------------------------------------------------------------------------ |
| 2026-05-15 | 7/10 → 10/10 | P5 first run found 3 keyword gaps (deportointi, опека на, kuriteo). Patched. |

## Related

- Code: `supabase/functions/_shared/halt_rail.ts`
- Wiring: `supabase/functions/claude-proxy/index.ts` (search for `haltDetection`)
- Tests: `supabase/functions/_shared/__tests__/halt_rail_test.ts` (42 cases)
- Metric: `supabase/migrations/20260515200000_halt_rail_metrics_and_error_log.sql`
- Smoke: `scripts/halt_rail_smoke.sh`
- Memory: `[A7 of вабанк]` in MEMORY.md
