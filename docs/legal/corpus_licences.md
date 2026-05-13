# Legal corpus licences — Advocat.ee

**Owner:** Advocat OÜ
**Last updated:** 2026-05-11

This document records the licence chain for every external source that
feeds the `public.law_chunks` table. The mix is non-trivial: most of our
sources are CC BY 4.0 (compatible with commercial use under attribution),
but some are CC BY-NC 4.0 (incompatible) and **must not be ingested**.

The reader's takeaway: when in doubt, prefer the original numbered act
plus amendments (CC BY 4.0) over the "current consolidated text" version
(CC BY-NC 4.0).

---

## 1. Estonia — Riigi Teataja (`assets/legal/estonia/`)

| Source | Licence | Commercial use | Status |
| --- | --- | --- | --- |
| Riigi Teataja statute corpus | Public-sector information, free reuse permitted under [§ 64 AvTS](https://www.riigiteataja.ee/akt/AvTS) | Yes | Ingested |
| Riigikohus precedents (selected landmark cases) | Public information | Yes | Curated landmark set ingested |

Attribution convention: every Estonian chunk carries `source_url` pointing
to its `riigiteataja.ee/akt/...` page. No additional UI badge required —
Estonian public-sector information is widely re-used without explicit CC
labelling.

---

## 2. Finland — Finlex (`assets/legal/finland/`)

Finnish source data comes from the [Finlex Open Data API](https://opendata.finlex.fi/finlex/avoindata/v1),
launched 27 February 2026 by the Ministry of Justice (Oikeusministeriö).
The catalogue is mixed-licence:

### 2.1 What we ingest — CC BY 4.0 (compatible)

| Dataset | Licence | Commercial use |
| --- | --- | --- |
| Säädökset alkuperäisinä — original statutes as published | **CC BY 4.0** | Yes |
| Statute amendments (each numbered act) | **CC BY 4.0** | Yes |
| KKO judgments (Supreme Court) — *Phase 2* | **CC BY 4.0** | Yes |
| KHO judgments (Supreme Administrative Court) — *Phase 2* | **CC BY 4.0** | Yes |
| Government proposals (HE), treaties — *not currently ingested* | **CC BY 4.0** | Yes |

### 2.2 What we DO NOT ingest — CC BY-NC 4.0 (incompatible)

> **DO NOT ingest the consolidated / "ajantasainen" Finnish texts.**

The current-text composite (each act with all amendments applied to date,
exposed under the `/ajantasa/` path on the Finlex web UI) is licensed
**CC BY-NC 4.0**. The `NonCommercial` clause forbids use in any product
that derives revenue, which includes our paid-tier subscriptions
(€19–€59/month) — and mixing free-tier + paid-tier serves the same
corpus, so the restriction extends to the whole app.

To stay compliant we ingest the **original act + each numbered
amendment** (all CC BY 4.0) and build our own consolidation when needed.
This is laborious but legally clean. Akoma Ntoso has `mod` / `textualMod`
elements that encode amendments machine-readably, so consolidation can
be added in a later phase without licence change.

The scraper (`scripts/scrape_finlex.ts`) hits the `/akn/fi/act/statute/{year}/{number}/fin@`
endpoint, which serves the ORIGINAL act in Akoma Ntoso XML — never the
ajantasainen path.

### 2.3 Attribution — required for CC BY 4.0

The CC BY licence requires attribution. We satisfy this with:

1. **`source_url` per chunk.** Every Finnish row in `law_chunks` carries
   the Akoma Ntoso URL it was scraped from (e.g.
   `https://opendata.finlex.fi/finlex/avoindata/v1/akn/fi/act/statute/2001/55/fin@`).
2. **UI footer in the citation chip.** When a Finnish chunk is shown in
   chat, the footer reads:
   `Lainsäädäntödata: Finlex / Oikeusministeriö, CC BY 4.0`
   (Estonian: "Õigusandmed:", Russian: "Правовые данные:").
3. **App-store description.** Privacy / attribution section names Finlex
   as a data source.

### 2.4 Bilingual statutes (Finnish + Swedish)

Approximately 25% of Finnish acts are published in both Finnish and
Swedish (`swe@` LangAndVersion). We ingest **Finnish only** for Phase 1;
the same scraper can be re-run with `swe@` for Phase 2 if Swedish-language
users join the addressable market. Estonian-speaking users in Finland do
not read Swedish, so the practical demand is low.

### 2.5 Finlex API ToS compliance

The Finlex API ToS requires:
- Identifying `User-Agent` header (set by the scraper to
  `advocat.ee/1.0 <support@advocat.ee>`, overridable via env var).
- Reasonable rate (the scraper throttles to 1 request/1.1 s).
- Caching of responses to minimise upstream load (we ingest once, then
  re-embed monthly from cached JSON; only changed chunks trigger a new
  Finlex hit).

---

## 3. EU — EUR-Lex (`assets/legal/eu/`)

| Dataset | Licence | Commercial use | Status |
| --- | --- | --- | --- |
| EU directives (Working Time, Equal Treatment, Posted Workers, Consumer Rights, GDPR) | Notice 2011/C 12/04 — re-use permitted with attribution | Yes | 5 directives ingested |

EUR-Lex content is governed by [Commission Decision 2011/833/EU on the reuse of Commission documents](https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:32011D0833),
which authorises commercial reuse with attribution. Each chunk carries
its CELEX id (`32019L1152`, etc.) and the `eur-lex.europa.eu` URL.

---

## 4. Russia — RU translations (`lang='ru'` rows of Estonian acts)

Russian-language rows in `law_chunks` are **translations of Estonian acts**,
NOT original Russian Federation legislation. Source: Riigi Teataja's
official Russian translations, same `§ 64 AvTS` provenance as the
Estonian originals. No Russian-Federation law is ingested — see also the
`reference_pitfalls_chat_infra.md` memory and the
`_jurisdictionAnchorRuUk` block in `services/system_prompts.dart`.

---

## 5. Adding a new source — checklist

Before merging a new corpus file:

1. **Identify the licence.** Read the source's terms of use, look for
   a `LICENSE.txt` / CC badge / robots-txt clause.
2. **Reject if `NC` or `ND` is in the licence.** Non-commercial and
   no-derivatives both block our use case.
3. **Record provenance** in this file (a new row in §1/§2/§3/§4 above).
4. **Set `source_url` per chunk** in the corpus JSON so attribution
   travels with the data.
5. **Add UI attribution** if the licence requires named attribution
   (CC BY does; public-domain doesn't).

Failure to follow this checklist is a legal-product bug that takes
precedence over feature work.

---

## 6. References

- [Finlex open data terms (English)](https://www.finlex.fi/en/open-data)
- [avoindata.suomi.fi — Finlex dataset listing with per-bucket licences](https://avoindata.suomi.fi/data/fi/dataset/finlex-laki-ja-oikeus-avoimena-linkitettyna-datana)
- [CC BY 4.0 deed](https://creativecommons.org/licenses/by/4.0/)
- [CC BY-NC 4.0 deed](https://creativecommons.org/licenses/by-nc/4.0/)
- [Commission Decision 2011/833/EU (EUR-Lex reuse)](https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:32011D0833)
- [AvTS § 64 (Estonian Public Information Act, re-use of public-sector information)](https://www.riigiteataja.ee/akt/AvTS)
