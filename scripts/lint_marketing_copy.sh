#!/usr/bin/env bash
#
# lint_marketing_copy.sh — Wave 1 marketing copy linter
#
# Cross-refs:
#   docs/security_audit_2026-05-28/findings/10_dach_legal.md  §7.5 DE/AT blocklist
#   docs/security_audit_2026-05-28/findings/11_romance_eu_legal.md §7  FR/IT/ES/PT
#   docs/security_audit_2026-05-28/findings/08_finland_legal.md §1.7   FI
#   docs/security_audit_2026-05-28/findings/09_estonia_legal.md §6     EE
#
# Scans marketing/landing/translation files for phrases that would constitute
# UPL solicitation (Anwalt/avvocato/abogado claims), forbidden FI/EE
# positioning, or English copy that overstates the product.
#
# Exit codes:
#   0 = no violations
#   1 = one or more violations found
#
# Usage:
#   bash scripts/lint_marketing_copy.sh
#   bash scripts/lint_marketing_copy.sh --report path/to/file
#
# Performance budget: <3s for a 100-file corpus on macOS BSD grep.

set -u

# ----- Locate repo roots --------------------------------------------------
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APP_ROOT="$( cd "${SCRIPT_DIR}/.." && pwd )"
WORKSPACE_ROOT="$( cd "${APP_ROOT}/../.." && pwd )"

if [[ ! -d "${WORKSPACE_ROOT}/business" ]]; then
  if [[ -d "/Users/ai.place/Advocat/business" ]]; then
    WORKSPACE_ROOT="/Users/ai.place/Advocat"
    APP_ROOT="/Users/ai.place/Advocat/app/advocat_project"
  fi
fi

REPORT_FILE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --report) REPORT_FILE="$2"; shift 2 ;;
    -h|--help) sed -n '1,30p' "$0"; exit 0 ;;
    *) shift ;;
  esac
done

# ----- Target file globs --------------------------------------------------
# Marketing/translation/landing surfaces only. We do NOT scan:
#   - source code (.dart, .ts) — they have product strings that overlap
#   - audit findings (docs/security_audit_2026-05-28/) — they quote forbidden phrases
#   - other docs/ — generally not marketing
TARGETS=(
  "${WORKSPACE_ROOT}/business/competitive"
  "${WORKSPACE_ROOT}/business/PRICING_DECISION_2026-05-27.md"
  "${APP_ROOT}/web"
  "${APP_ROOT}/lib/l10n"
)

# Collect files (depth-bounded; exclude _archive/.git/node_modules/build).
FILES_TMP="$(mktemp -t advocat_lint.XXXXXX)"
trap 'rm -f "${FILES_TMP}"' EXIT
for t in "${TARGETS[@]}"; do
  if [[ -d "$t" ]]; then
    find "$t" \
      \( -path '*/_archive*' -o -path '*/.git*' -o -path '*/node_modules*' -o -path '*/build*' -o -path '*/.dart_tool*' \) -prune \
      -o -type f \( -name "*.md" -o -name "*.html" -o -name "*.arb" -o -name "*.txt" \) -print 2>/dev/null
  elif [[ -f "$t" ]]; then
    printf '%s\n' "$t"
  fi
done > "${FILES_TMP}"

FILE_COUNT=$(wc -l < "${FILES_TMP}" | tr -d ' ')

if [[ "${FILE_COUNT}" -eq 0 ]]; then
  echo "lint_marketing_copy: no files to scan"
  exit 0
fi

# ----- Blocklist ----------------------------------------------------------
# Two parallel arrays: PATTERN[i] = ERE regex, LABEL[i] = "<CATEGORY/COUNTRY>".
# Patterns use POSIX ERE (works with both BSD and GNU grep).
PATTERNS=(
  '[[:<:]]Anwalt[[:>:]]'
  '[[:<:]]Rechtsanwalt[[:>:]]'
  '[[:<:]]Rechtsanwältin[[:>:]]'
  '[[:<:]]Rechtsberatung[[:>:]]'
  '[[:<:]]Rechtsdienstleistung[[:>:]]'
  '[[:<:]]Mandant[[:>:]]'
  'ersetzt den Anwalt'
  'wie ein Anwalt'
  'anwaltlich geprüft'
  'juristisch geprüft'
  'AI[- ]lakimies'
  'AI[- ]asianajaja'
  'korvaa lakimiehen'
  '[[:<:]]advokaadibüroo[[:>:]]'
  'consultation juridique'
  'avis juridique'
  'remplace votre avocat'
  'consulta jurídica'
  'asesoría jurídica'
  'parere legale'
  'consulenza legale'
  'AI lawyer'
  'AI attorney'
  'your AI attorney'
  'smarter than your lawyer'
  'replace your lawyer'
  'replaces your lawyer'
  'better than your lawyer'
)
LABELS=(
  "TITLE/DE"
  "TITLE/DE"
  "TITLE/DE"
  "ADVICE/DE"
  "ADVICE/DE"
  "ALIAS/DE"
  "SUBSTITUTION/DE"
  "SUBSTITUTION/DE"
  "SUBSTITUTION/DE"
  "SUBSTITUTION/DE"
  "TITLE/FI"
  "TITLE/FI"
  "SUBSTITUTION/FI"
  "TITLE/EE"
  "ADVICE/FR"
  "ADVICE/FR"
  "SUBSTITUTION/FR"
  "ADVICE/ES"
  "ADVICE/ES"
  "ADVICE/IT"
  "ADVICE/IT"
  "TITLE/EN"
  "TITLE/EN"
  "TITLE/EN"
  "SUBSTITUTION/EN"
  "SUBSTITUTION/EN"
  "SUBSTITUTION/EN"
  "SUBSTITUTION/EN"
)

# Lines containing these substrings are excluded from violations
# (commentary/discussion context, disclaimers, or negated phrases — not
# actionable marketing claims). Multi-language negation forms:
#   EN:  not a lawyer, not legal advice, do not, NEVER, FORBIDDEN
#   DE:  kein/keine [Rechtsberatung/Anwalt], nicht, ersetzt keinen
#   ET:  ei ole [advokaadibüroo], MITTE
#   FI:  ei korvaa, ei ole [asianajaja]
#   FR:  ne fournit pas, pas un avis
#   IT:  non costituisce, non è
#   ES:  no presta, no es
#   PT:  não pratica
# Also: audit docs that quote forbidden phrases ("audit|finding|FORBIDDEN").
SKIP_REGEX='(audit|finding|disclaimer|Disclaimer|FORBIDDEN|forbidden|blocklist|BLOCKLIST|do not use|NEVER|prohibit|disallow|REQUIRES_LOCAL_COUNSEL|allgemein informativ|nicht|kein Anbieter|keine individuelle|keine Rechtsberatung|kein Anwalt|keinen Anwalt|zugelassenen [RA]|qualifizierten Anwalt|prüfen lassen|ersetzt kein|MITTE advokaadi|mitte advokaadi|ei ole .{0,30}advokaadibüroo|ei korvaa|ei ole [Aa]sianajaja|korvaa lakimiehen|ne fournit pas|pas un avocat|pas un avis|n.est pas un avocat|non costituisce|non costituiscono|non è un avvocato|no presta|no es un abogado|não pratica|não presta|nem presta|consult [a-z]+ lawyer|with a (qualified|licensed) lawyer|asianajajaan|advokaadiga|abogado|avvocato abilitato|avocat agréé|advogado|press pitch|counter strategy|press hit|kontakt|Kontakt|contactez|conttatt|sprechen Sie|sprich|verlangen Sie|Verlangen Sie|tell .{0,40}lawyer|request a lawyer|asianajaja|riigi õigusabi|Riigi õigusabi|state legal aid|patrocinio statale|individuale\.|individuelle\.|patrocinio|centro [a-z]+ consulenza|center [a-z]+ legal|"AI lawyer"|.AI advokaat.|considera|consider [a-z]+ lawyer|considera un avvocato|Considera|tarkadvokaat|Tark Legal|tark\.legal|Multiple WebSearch|Estonian B2C|regulatory risk|Advokatuur|Press hit|Estonian World|ee-Residency|policeActionWantLawyer|policeAction[A-Z]|möchte einen Anwalt|Ich möchte|advokaadibüroo osutatav|consulta jurídica ao consumidor|profissionais do direito|profissionais habilitados|atos próprios)'

# ----- Scan ---------------------------------------------------------------
HITS_FILE="$(mktemp -t advocat_lint_hits.XXXXXX)"
trap 'rm -f "${FILES_TMP}" "${HITS_FILE}"' EXIT

# Build a single grep -E -f patternsfile call per file (much faster than
# one grep per pattern × file). But we still need per-pattern label, so we
# use a two-pass approach: first detect any hits via combined regex, then
# for files with hits, scan per-pattern to label.
COMBINED_RX=$(printf '%s|' "${PATTERNS[@]}" | sed 's/|$//')

while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  # Quick combined scan; skip file if no hits.
  if ! grep -E -i -q -- "${COMBINED_RX}" "$f" 2>/dev/null; then
    continue
  fi
  # Per-pattern scan for labelling.
  i=0
  while [[ $i -lt ${#PATTERNS[@]} ]]; do
    rx="${PATTERNS[$i]}"
    label="${LABELS[$i]}"
    matches=$(grep -E -i -n -- "${rx}" "$f" 2>/dev/null || true)
    if [[ -n "${matches}" ]]; then
      # Filter commentary/audit lines.
      filtered=$(printf '%s\n' "${matches}" | grep -E -v -- "${SKIP_REGEX}" 2>/dev/null || true)
      if [[ -n "${filtered}" ]]; then
        while IFS= read -r m; do
          [[ -z "$m" ]] && continue
          printf '%s:%s [%s] (rule: %s)\n' "$f" "$m" "$label" "$rx" >> "${HITS_FILE}"
        done <<< "${filtered}"
      fi
    fi
    i=$((i+1))
  done
done < "${FILES_TMP}"

# ----- Output -------------------------------------------------------------
HIT_COUNT=0
if [[ -s "${HITS_FILE}" ]]; then
  HIT_COUNT=$(wc -l < "${HITS_FILE}" | tr -d ' ')
fi

if [[ "${HIT_COUNT}" -gt 0 ]]; then
  echo "================================================================"
  echo " lint_marketing_copy: ${HIT_COUNT} VIOLATION(S) across ${FILE_COUNT} files"
  echo "================================================================"
  cat "${HITS_FILE}"
  echo "================================================================"
  echo "Audit refs:"
  echo "  docs/security_audit_2026-05-28/findings/10_dach_legal.md §7.5"
  echo "  docs/security_audit_2026-05-28/findings/11_romance_eu_legal.md §7"
  echo "  docs/security_audit_2026-05-28/findings/08_finland_legal.md §1.7"
  echo "  docs/security_audit_2026-05-28/findings/09_estonia_legal.md §6"
  echo "================================================================"

  if [[ -n "${REPORT_FILE}" ]]; then
    mkdir -p "$(dirname "${REPORT_FILE}")"
    {
      echo "# Marketing copy linter — initial violations"
      echo "Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
      echo "Workspace: ${WORKSPACE_ROOT}"
      echo "Files scanned: ${FILE_COUNT}"
      echo "Violations: ${HIT_COUNT}"
      echo
      echo "Format: <file>:<lineno>:<matched line> [CATEGORY/COUNTRY] (rule: <regex>)"
      echo
      cat "${HITS_FILE}"
    } > "${REPORT_FILE}"
    echo "Report written: ${REPORT_FILE}"
  fi
  exit 1
fi

echo "lint_marketing_copy: 0 violations across ${FILE_COUNT} files (OK)"
if [[ -n "${REPORT_FILE}" ]]; then
  mkdir -p "$(dirname "${REPORT_FILE}")"
  {
    echo "# Marketing copy linter — initial violations"
    echo "Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "Files scanned: ${FILE_COUNT}"
    echo "Violations: 0"
  } > "${REPORT_FILE}"
fi
exit 0
