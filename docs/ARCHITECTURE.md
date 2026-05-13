# Advocat — system architecture

Last refreshed: 2026-05-13. Build: `45dd3b5` (legal_lookup tool / AI v4.1).

This document gives a fresh engineer enough context to start working on any
single module without first reading every other one. For deploy specifics
see [`DEPLOY.md`](DEPLOY.md). For package-specific designs see
[`architecture/phase2-pkg*.md`](architecture/).

## High level

```
                ┌──────────────────────────────────────────┐
                │  Flutter web (lib/)                       │
                │  17 langs · /app.html shell · isPro gate │
                └────────────────┬──────────────────────────┘
                                 │ HTTPS + Supabase JWT
                                 ▼
┌────────────────────────────────────────────────────────────────────────────┐
│  Supabase project: okgnkucgwsytsondrjye                                    │
│  ┌──────────────────────────┐  ┌──────────────────────────────────────┐   │
│  │ Postgres + RLS + pgvector│  │ Edge Functions (Deno) — ~35           │   │
│  │  • auth.users            │  │  • claude-proxy  (chat orchestrator)  │   │
│  │  • user_quotas           │  │  • contract-review, classify-contract │   │
│  │  • user_cases            │  │  • email-triage, email-inbox-sync     │   │
│  │  • conversations         │  │  • law-search, law-lookup             │   │
│  │  • messages              │  │  • deadline-extractor, *-radar-tick   │   │
│  │  • contract_reviews      │  │  • pdf-parser, pdf-generator          │   │
│  │  • contract_analysis_jobs│  │  • stripe-webhook, create-checkout    │   │
│  │  • advice_corrections    │  │  • admin-add-correction (svc-role)    │   │
│  │  • advice_digest         │  │  • google-tts, tts-proxy, whisper-stt │   │
│  │  • law_chunks (vector)   │  │  • support-ticket, gold-review        │   │
│  │  • planner_traces        │  └──────────────────────────────────────┘   │
│  │  • case_deadlines        │                                              │
│  │  • email_inbox_threads   │                                              │
│  │  • message_citations     │                                              │
│  └──────────────────────────┘                                              │
└────────────────────────────────────────────────────────────────────────────┘
                │              │              │             │
                ▼              ▼              ▼             ▼
        Anthropic API    OpenAI emb.    Stripe API    Gmail API
        (Sonnet 4.6,     (text-emb-3    (checkout +   (OAuth +
         Haiku 4.5,       small)        webhooks)     IMAP)
         Opus 4.7)
                                          │
                                          ▼
                                  ┌─────────────────────┐
                                  │ Typst PDF worker    │
                                  │ (Railway, Deno+typst│
                                  │  contract-review.typ│
                                  └─────────────────────┘
```

## Key modules

### Edge functions

| Function | Purpose |
|---|---|
| `claude-proxy` | The hot path for chat. Routes user turns to passthrough / `legal_planner` / `consilium` based on complexity. Owns prompt caching, case-memory injection, citation persistence, error mapping, llama fallback. Source: `supabase/functions/claude-proxy/`. |
| `contract-review` | Contract Review mode. Loads owned `case_documents`, enforces 3-tier quota, calls planner, persists `contract_reviews` row, hands JSON to typst-worker for PDF, returns signed Storage URL + email draft + quality warnings. Async fallback via `contract_analysis_jobs` for >3 docs. |
| `classify-contract` | Cheap Haiku yes/no after a PDF upload — "is this a contract?". Drives the "Review this contract" chip in the UI. Confidence cutoff 0.7. |
| `admin-add-correction` | Service-role-only insert into `advice_corrections`. Used by lawyer-review tools and the eval failure pipeline. Embeds the question via OpenAI text-embedding-3-small. |
| `email-triage`, `email-inbox-sync`, `gmail-label` | Email Agent track. Gmail OAuth, IMAP poll, Sonnet triage with `<triage>` / `<draft>` / `<memory_update>` blocks. |
| `deadline-extractor`, `deadline-radar-tick`, `deadline-reminder` | Phase 2 Pkg 9 — Sonnet pulls deadlines out of message text + holiday-shifts (FI/EE/ECHR), nightly tick raises FCM push. |
| `pdf-parser`, `pdf-generator` | pdfjs + Vision OCR fallback (25-page cap) + Sonnet structured-JSON extractor; pdf-generator uses a separate Typst template for case dossiers. |
| `law-search`, `law-lookup` | RAG over `law_chunks` (pgvector). `law-search` is the chat tool; `law-lookup` is a tighter direct paragraph fetch wired into the `legal_lookup` Claude tool (AI v4.1). |
| `support-ticket`, `gold-review`, `gold-scrubber` | Lawyer review queue — flagged turns become gold-corpus candidates after PII scrubbing. |

### Shared library (`_shared/`)

| Module | Role in the AI pipeline |
|---|---|
| `legal_planner.ts` | Three-pass orchestrator + adversarial extensions. The single entry point for `mode='legal_planner'` in claude-proxy. |
| `consilium.ts` + `consilium_roles/` | Parallel multi-role synthesis. 11 domain experts (immigration-fi, criminal-fi, contract-ee, gdpr-eu, ...) + 6 strategic positions (decision-maker-risk, procedural-posture, silent-concession, long-game, 23-test, deadline-strategist). Router picks 4-6 per turn. |
| `red_team.ts` | Adversarial pass. Opus reads the executor draft AS THE OPPOSING PARTY and finds the strongest reason it fails in court. Severity (`minor`/`serious`/`fatal`) drives a re-plan loop, capped at 2. |
| `subtraction_critic.ts` | "Senior lawyer who knows when to shut up". Sonnet trims the post-red-team draft 40-60% by strategic value. Never cuts CRITICAL warnings or `[[ref:...]]` markers. |
| `corrections_retriever.ts` | "Memory of WRONG". Embeds the user question, retrieves top-N from `advice_corrections`, injects as `<learned_corrections>` system-prompt block. |
| `correction_detector.ts` | Haiku watcher on every user turn — "did the user just say we were wrong?". Inserts `correction_source='user_explicit'` rows. |
| `citation_grounder.ts` + `citation_enforcement.ts` | Map `[[ref:slug:para]]` markers to verified statute hits, emit one of `verified` / `unverified` / `outdated` status badges. |
| `legal_lookup.ts` | Mid-reasoning tool the executor can call (v4.1). pgvector top-5 from `law_chunks` with cosine ≥0.75, 4KB cap. v2 stubs: live Finlex / Riigi Teataja / EUR-Lex fallback when corpus >60d stale. |
| `fact_extractor.ts`, `case_patch_prompt.ts`, `case_phase.ts` | Haiku auto-patch of `user_cases.case_facts` between turns. State machine: intake → fact-gathering → strategy → execution → wait. |
| `pii_scrubber.ts`, `gold_enqueue.ts` | PII redaction before any gold-corpus write or external eval. |

### Frontend (`lib/`)

| Path | Feature |
|---|---|
| `lib/features/chat/` | Main consultant screen. Streaming SSE, citation widgets, mode badges, voice input/output. |
| `lib/features/case_workspace/` | 7-tab per-case workspace: chat, facts, deadlines, documents, drafts, timeline, settings. |
| `lib/features/checker/` | Contract Review UI. Multi-file upload, output-language picker, score + risks list, PDF download. |
| `lib/features/deadlines/`, `lib/features/inbox/`, `lib/features/email/` | Phase 2 packages. |
| `lib/services/claude_proxy_client.dart`, `auth_service.dart`, `subscription_service.dart` | Backend clients. |

## Data model (key tables)

| Table | Notes |
|---|---|
| `auth.users` | Supabase-managed. |
| `user_quotas` | Per-user counters. New: `contract_reviews_used`, `contract_reviews_period_start`. 30-day rolling window. |
| `user_cases` | One row per legal case. `case_facts` JSONB auto-patched between turns. |
| `conversations`, `messages` | Chat history. `messages.metadata` carries planner trace + citations. |
| `contract_reviews` | One per completed review. PDF stored in `contract-reviews` bucket. |
| `contract_analysis_jobs` | Async queue for multi-doc reviews. |
| `advice_corrections` | Memory of WRONG. 1536-dim vector embeddings, ivfflat cosine. RLS: read = any auth user, write = owner or service_role. |
| `advice_digest` | Memory of CORRECT (recent advice fingerprints — used for "have we already answered this?" deduplication). |
| `law_chunks` | RAG corpus. 8345 chunks across 30 ET acts + 5 EU directives + Finnish core. `jurisdiction` + `lang` filters. |
| `planner_traces` | One row per planner-routed turn. `plan` + `critique` + `red_team_passes[]` + `subtraction` + cost_cents. |
| `message_citations` | Verified statute hits per message, with `[[ref:slug:para]]` position + status. |
| `case_deadlines` | Extracted deadlines with holiday-shifted dates. |
| `email_inbox_threads`, `email_inbox_messages` | Gmail mirror for the Email Agent. |
| `support_tickets`, `gold_corpus` | Lawyer review pipeline. |

## AI pipeline (legal_planner mode)

```
                 user turn
                     │
                     ▼
              ┌──────────────┐
              │   Planner    │   Sonnet, T=0.0, ≤500 tok
              │  <plan>...   │   emits sub_questions / counter_args /
              └──────┬───────┘   evidence_gaps / probability_signal /
                     │           blocking_gaps[]
                     ▼
        ┌──────────────────────────┐
        │ blocking_gaps non-empty? │── yes ──▶ return "blocked" question
        └─────────────┬────────────┘
                     no
                     ▼
              ┌──────────────┐
              │  Executor    │   Sonnet, T=0.2, ≤16k tok
              │  drafts reply│   may call legal_lookup tool
              │  + markers   │   ──────────────────────┐
              └──────┬───────┘                          │
                     │                                  ▼
                     ▼                          ┌──────────────────┐
              ┌──────────────┐                  │  legal_lookup    │
              │   Critique   │                  │ (pgvector top-5  │
              │   Haiku      │                  │  from law_chunks)│
              │  material    │                  └──────────────────┘
              │   _gap?      │
              └──────┬───────┘
              yes (max 1 regen)
                     │  ──── inject critique, re-run Executor
                     ▼
              ┌──────────────┐
              │   Red-Team   │   Opus, T=0.0, ≤600 tok
              │   (v4)       │   "as opposing counsel — strongest attack"
              │  severity    │   minor/serious/fatal
              └──────┬───────┘
        serious|fatal│  (max 2 adversarial loops)
                     │  ──── append attack_summary to blocking_gaps,
                     │       loop back to Planner
                     ▼
              ┌──────────────┐
              │  Subtraction │   Sonnet, T=0.0, ≤12k tok
              │   (v4)       │   cuts 50-60%, keeps [[ref:...]] +
              │              │   CRITICAL warnings
              └──────┬───────┘
                     ▼
            citation_grounder → UPL footer → persist message + trace + citations
```

For consilium mode the structure is parallel — N specialised roles run in
`Promise.all` then a Sonnet synthesiser streams the final answer via SSE
(`consilium_start` → `role_done` × N → `synthesis_start` → `delta` × N → `done`).

## Cost model (per turn)

Approximate, cents. From `legal_planner.costCents` + `red_team.redTeamCostCents`
+ `subtraction.subtractionCostCents`. Used by the ops dashboard, not billing.

| Stage | Model | Typical in / out | Cost |
|---|---|---|---|
| Planner | Sonnet 4.6 | 2k / 0.4k | $0.012 |
| Executor (1st) | Sonnet 4.6 | 6k / 3k | $0.063 |
| Critique | Haiku 4.5 | 4k / 0.2k | $0.0005 |
| Executor (regen) | Sonnet 4.6 | 6.5k / 3k | $0.065 (only if material_gap) |
| Red-Team | Opus 4.7 | 4k / 0.3k | $0.083 |
| Re-plan loop | (Planner+Exec×2+Critique+RT) | ~24k / 7k | $0.18 (only if severity ≥ serious) |
| Subtraction | Sonnet 4.6 | 5k / 2.5k | $0.053 |
| **Typical clean turn** | | | **$0.13** |
| **Worst case (2 adversarial loops, 1 regen)** | | | **~$0.41** |

Cheap-path turns (chat passthrough, no planner) cost $0.01-0.02 — most
day-to-day "what does §X say" questions stay on this path.

Contract Review adds one Sonnet ≤16k call per doc batch + the typst-worker
HTTP roundtrip ($0 — Railway is included in flat plan). Typical review of a
12-page contract: $0.15 backend + Stripe fee.

## Eval

Two suites cover different surfaces — see `eval/README.md` and `../data/eval/README.md`:

| Suite | Target | Style | Trigger |
|---|---|---|---|
| `Advocat/data/eval/` (outer) | `claude-proxy` chat outputs | rubric+judge (Sonnet judge, swap A/B) | pre-deploy / nightly |
| `app/advocat_project/eval/` | `email-triage` edge fn | regex contract on `<triage>`/`<draft>`/`<memory_update>` blocks | manual post-staging |

Eval Phase 1 (Apr 2026) caught the HOL §114 hallucination ("30-day window" vs
the actual 5-year KHO-only rule) and motivated the legal_lookup tool (AI v4.1).
Eval Phase 2 wires the contract-review and consilium paths through the same
rubric harness — in progress.

## Deploy & rollback

See [`DEPLOY.md`](DEPLOY.md). Single path is `scripts/canary-deploy.sh`. Direct
`gh-pages` pushes blocked by `scripts/prod-lock.sh` githook. Override:
`FORCE_DEPLOY_REASON="..."`.

Typst worker deploys independently to Railway (`services/typst-worker/`); the
edge function discovers it via `CONTRACT_PDF_WORKER_URL` + `CONTRACT_PDF_WORKER_SECRET`
Supabase secrets.
