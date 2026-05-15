#!/usr/bin/env python3
"""
expand_fi_genitives.py — Expand statute_aliases with Finnish case forms.

Citation extractor surfaces unresolved refs like "tuloverolain 54 §" because
only nominative ("tuloverolaki" → fi-tuloverolaki) was previously aliased.

For each FI act in the corpus (jurisdiction='fi'), this script generates
inflected name forms (genitive, inessive, partitive, translative, adessive,
elative, illative) crossed with each known section, and INSERTs them as
common_misspelling aliases. Idempotent via ON CONFLICT DO NOTHING on the
existing UNIQUE (alias, act_slug, COALESCE(section, '')) index.

Usage (no commits, no deploys; pure SQL via Management API):
    python3 scripts/expand_fi_genitives.py | tee /tmp/expand_fi_genitives.sql
    # then POST to /v1/projects/.../database/query

Or directly:
    SUPABASE_ACCESS_TOKEN=... python3 scripts/expand_fi_genitives.py --apply
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import urllib.request

PROJECT_REF = "okgnkucgwsytsondrjye"
API = f"https://api.supabase.com/v1/projects/{PROJECT_REF}/database/query"

# ---------------------------------------------------------------------------
# Stem → inflected form generator (Finnish singular cases).
# ---------------------------------------------------------------------------

# Inflection rule sets keyed by nominative suffix. Each tuple is
# (suffix_to_strip, [inflected_suffixes_to_append]).
LAKI_FORMS = ["lain", "laissa", "lakia", "laiksi", "lailla", "laista", "lakiin"]
KAARI_FORMS = ["kaaren", "kaaressa", "kaarta", "kaareksi", "kaarella",
               "kaaresta", "kaareen"]


def inflect(nominative: str) -> list[str]:
    """Return list of inflected forms for a Finnish act nominative.

    Handles two endings observed in our corpus:
      -laki  → -lain / -laissa / -lakia / -laiksi / -lailla / -laista / -lakiin
      -kaari → -kaaren / -kaaressa / -kaarta / -kaareksi / -kaarella /
               -kaaresta / -kaareen
    """
    low = nominative.lower()
    if low.endswith("laki"):
        stem = low[: -len("laki")]
        return [stem + suffix for suffix in LAKI_FORMS]
    if low.endswith("kaari"):
        stem = low[: -len("kaari")]
        return [stem + suffix for suffix in KAARI_FORMS]
    return []


# ---------------------------------------------------------------------------
# Slug → list of nominative variants (one slug may have several common
# nominatives, e.g., "Laki viranomaisten toiminnan julkisuudesta" but cited as
# "julkisuuslaki" colloquially).
# ---------------------------------------------------------------------------

SLUG_NOMINATIVES: dict[str, list[str]] = {
    "fi-avioliittol": ["avioliittolaki"],
    "fi-esitutkintal": ["esitutkintalaki"],
    "fi-hol": ["hallintolaki"],
    "fi-holhoustoimil": ["holhoustoimilaki"],
    "fi-julkisuusl": ["julkisuuslaki"],
    "fi-konkurssil": ["konkurssilaki"],
    "fi-kuluttajansuojal": ["kuluttajansuojalaki"],
    "fi-kuntal": ["kuntalaki"],
    "fi-lapsenhuoltol": ["lapsenhuoltolaki"],
    "fi-oho": ["oikeudenkäyntilaki", "hallintoasiainlaki"],
    "fi-ok": ["oikeudenkäymiskaari"],
    "fi-pakkokeinol": ["pakkokeinolaki"],
    "fi-perustuslaki": ["perustuslaki", "suomenperustuslaki"],
    "fi-poll": ["poliisilaki"],
    "fi-rikosvahinkol": ["rikosvahinkolaki"],
    "fi-rl": ["rikoslaki"],
    "fi-rol": ["rikosasiainlaki"],
    "fi-sahkoinen-asiointi": ["sähköisenasioinninlaki", "sähköasiointilaki"],
    "fi-tietosuojal": ["tietosuojalaki"],
    "fi-tyosopimusl": ["työsopimuslaki"],
    "fi-ulkl": ["ulkomaalaislaki"],
    "fi-ulkrekl": ["ulkomaalaisrekisterilaki"],
    "fi-vahingonkorvausl": ["vahingonkorvauslaki"],
    "fi-velkajarjestelyl": ["velkajärjestelylaki"],
    "fi-yhdenvertaisuusl": ["yhdenvertaisuuslaki"],
}


# ---------------------------------------------------------------------------
# SQL builder
# ---------------------------------------------------------------------------

def build_sql() -> str:
    """Build a single INSERT … SELECT that joins inflected forms with each
    act's distinct sections from law_chunks_v2.
    """
    parts: list[str] = []
    for slug, nominatives in SLUG_NOMINATIVES.items():
        inflected: set[str] = set()
        for nom in nominatives:
            for form in inflect(nom):
                inflected.add(form)
        if not inflected:
            continue
        # Quote SQL literals; values are pure ASCII-or-Unicode word chars.
        form_values = ", ".join(f"('{f}')" for f in sorted(inflected))
        parts.append(f"""
INSERT INTO statute_aliases (alias, act_slug, section, pattern_kind)
SELECT
  f.form || ' ' || s.section || ' §' AS alias,
  '{slug}' AS act_slug,
  s.section,
  'common_misspelling' AS pattern_kind
FROM (VALUES {form_values}) AS f(form)
CROSS JOIN (
  SELECT DISTINCT section FROM law_chunks_v2
  WHERE act_slug = '{slug}' AND section IS NOT NULL
) AS s
ON CONFLICT (alias, act_slug, COALESCE(section, '')) DO NOTHING;
""".strip())
    return "\n\n".join(parts)


# ---------------------------------------------------------------------------
# Apply via Supabase Management API
# ---------------------------------------------------------------------------

def apply_sql(sql: str) -> dict:
    token = os.environ.get("SUPABASE_ACCESS_TOKEN")
    if not token:
        raise SystemExit("SUPABASE_ACCESS_TOKEN env var required for --apply")
    req = urllib.request.Request(
        API,
        method="POST",
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
            "User-Agent": "advocat-expand-fi-genitives/1.0",
        },
        data=json.dumps({"query": sql}).encode("utf-8"),
    )
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="replace")
        raise SystemExit(f"HTTP {e.code}: {body}")


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--apply", action="store_true",
                   help="Execute against prod via Management API")
    args = p.parse_args()
    sql = build_sql()
    if args.apply:
        result = apply_sql(sql)
        print(json.dumps(result, indent=2, ensure_ascii=False))
    else:
        print(sql)
    return 0


if __name__ == "__main__":
    sys.exit(main())
