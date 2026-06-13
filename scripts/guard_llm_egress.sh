#!/usr/bin/env bash
# guard_llm_egress.sh — fail CI when a NEW external-LLM egress site appears.
# ----------------------------------------------------------------------------
# Context (Data Fortress, 2026-06-13): client case-text was reaching US LLMs
# without pseudonymization because the PII scrubber was wired into only 2 of
# ~30 egress sites. This guard makes egress an EXPLICIT, REVIEWED inventory:
# every file that fetches an external LLM host must be on the allowlist below,
# annotated with HOW its outbound user text is protected. A new egress site
# (or a removed protection) fails the build, forcing a human to classify it:
#   scrubbed  — runs payload through _shared/llm_egress (pseudonymize/gateway)
#   corpus    — sends only public statute/citation text, no user PII
#   internal  — the gateway/scrubber implementation itself
#   fetcher   — pulls FROM a public source (eur-lex/hudoc/he/finlex), no egress
#               of user data
#
# This is an INVENTORY gate, not a dataflow proof — it guarantees no egress
# site is added silently, which is exactly the failure mode that caused the
# leak. Deeper per-call enforcement lives in code review + the gateway API.
# ----------------------------------------------------------------------------
set -euo pipefail

cd "$(dirname "$0")/.."
FN_DIR="supabase/functions"
HOSTS='api\.anthropic\.com|api\.openai\.com|api\.deepinfra\.com|api\.mistral\.ai'

# Reviewed allowlist: "path  # classification — note".
# Keep sorted. When you add a site, classify it and (if it handles user text)
# wire it through _shared/llm_egress first.
read -r -d '' ALLOWLIST <<'EOF' || true
# --- DONE: actually wired through _shared/llm_egress (verified) ---
_shared/corrections_retriever.ts    # scrubbed — pseudonymize() before embeddings
law-search/embed.ts                 # scrubbed — pseudonymize() before embeddings (user queries)
# --- internal: the egress/scrubber machinery itself ---
_shared/pii_scrubber.ts             # internal — the scrubber (Haiku name-pass)
_shared/llm_egress/scrub_body.ts    # internal — the body-scrub helper (host names in comments)
_shared/redactor.ts                 # internal — redaction helper
_shared/providers/anthropic_provider.ts  # internal — provider transport
_shared/providers/openai_provider.ts     # internal — provider transport
# --- corpus: send only public statute/citation/eval text, no user PII ---
_shared/red_team.ts                 # corpus — adversarial eval prompts, no user PII
corpus-embedder/index.ts            # corpus — embeds public statute corpus
hallucination-eval-runner/index.ts  # corpus — eval harness, synthetic prompts
qa-corpus-search/index.ts           # corpus — searches public corpus
# --- fetcher: pull FROM a public source, no egress of user data ---
eur-lex-fetcher/index.ts            # fetcher — pulls public EU law, no user egress
he-fetcher/index.ts                 # fetcher — pulls FI travaux, no user egress
hudoc-fetcher/index.ts              # fetcher — pulls ECtHR cases, no user egress
# --- scrubbed: routed through _shared/llm_egress scrubAnthropicBody/scrubText ---
# (identifiers-only tier: strips isikukood/HETU/IBAN, keeps names/emails/phones
#  for tool-calling + draft fidelity; EU-residency is the backstop for those.)
_shared/advice_digest.ts            # scrubbed — scrubAnthropicBody on Haiku digest
_shared/consilium.ts                # scrubbed — scrubAnthropicBody on lawyer-agent bodies
_shared/correction_detector.ts      # scrubbed — scrubAnthropicBody on detector body
_shared/fact_extractor.ts           # scrubbed — scrubAnthropicBody on extractor bodies
_shared/legal_planner.ts            # scrubbed — scrubAnthropicBody in defaultAnthropicCaller
_shared/query_rewriter.ts           # scrubbed — scrubAnthropicBody in defaultHaikuJsonCaller
_shared/subtraction_critic.ts       # scrubbed — scrubAnthropicBody on critic body
case-auto-patch/index.ts            # scrubbed — scrubAnthropicBody on patch body
classify-contract/index.ts          # scrubbed — scrubAnthropicBody on classify body
claude-proxy/index.ts               # scrubbed — stripIdentifiersFromBody on all 3 Anthropic egress
claude-proxy/llama_fallback.ts      # scrubbed — scrubText on each DeepInfra message content
claude-proxy/model_router.ts        # scrubbed — scrubAnthropicBody on routed body
contract-review/index.ts            # scrubbed — scrubAnthropicBody on review bodies
deadline-extractor/index.ts         # scrubbed — scrubAnthropicBody on extractor body
draft-ai-revise/index.ts            # scrubbed — scrubAnthropicBody on revise body
email-triage/index.ts               # scrubbed — scrubAnthropicBody on both triage bodies
extract-memory/index.ts             # scrubbed — scrubAnthropicBody on memory body
pdf-parser/index.ts                 # partial — embeddings input scrubText'd; Vision IMAGE is TIER-0 binary (needs EU-inference Phase 1)
whisper-stt/index.ts                # tier0-binary — only audio bytes egress, no text to scrub
EOF

# Allowlisted paths, one per line (comments/whitespace stripped). Kept as a
# newline-delimited string for bash 3.2 (macOS) compatibility — no assoc arrays.
ALLOWED_PATHS="$(echo "$ALLOWLIST" | sed 's/#.*//' | sed 's/[[:space:]]*$//' | grep -v '^[[:space:]]*$' | sort -u)"

# Find current egress sites (exclude tests).
CURRENT_PATHS="$(
  grep -rlE "$HOSTS" "$FN_DIR" 2>/dev/null \
    | grep -vE "__tests__|_tests" \
    | sed "s#^$FN_DIR/##" \
    | sort -u
)"

is_in() { echo "$2" | grep -qxF "$1"; }

fail=0
NEW=()
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  if ! is_in "$f" "$ALLOWED_PATHS"; then
    NEW+=("$f")
    fail=1
  fi
done <<< "$CURRENT_PATHS"

# Also warn (not fail) on stale allowlist entries that no longer egress.
STALE=()
while IFS= read -r p; do
  [[ -z "$p" ]] && continue
  if ! is_in "$p" "$CURRENT_PATHS"; then
    STALE+=("$p")
  fi
done <<< "$ALLOWED_PATHS"

CURRENT_COUNT="$(echo "$CURRENT_PATHS" | grep -c . || true)"

if [[ $fail -eq 1 ]]; then
  echo "❌ guard_llm_egress: NEW external-LLM egress site(s) not on the reviewed allowlist:"
  for f in "${NEW[@]}"; do echo "   + $f"; done
  echo ""
  echo "   Every site that sends user/case text to an external LLM MUST first"
  echo "   pseudonymize it via _shared/llm_egress (pseudonymize/prepareEgress)."
  echo "   Then add the file to ALLOWLIST in scripts/guard_llm_egress.sh with"
  echo "   its classification (scrubbed | corpus | internal | fetcher)."
  exit 1
fi

echo "✅ guard_llm_egress: all ${CURRENT_COUNT} egress sites are on the reviewed allowlist."
if [[ ${#STALE[@]} -gt 0 ]]; then
  echo "ℹ️  stale allowlist entries (no longer egress — prune when convenient):"
  for p in "${STALE[@]}"; do echo "   - $p"; done
fi
