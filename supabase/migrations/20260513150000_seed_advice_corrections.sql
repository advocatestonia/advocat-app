-- ============================================================================
-- 20260513150000_seed_advice_corrections.sql
-- Seed advice_corrections with lessons mined from
-- /Users/ai.place/.claude/projects/-Users-ai-place-Advocat/memory/lesson_*.md.
-- ----------------------------------------------------------------------------
-- Selection rule (from spec): only lessons describing AI/legal reasoning
-- failures qualify. Pure code/infra/CI lessons (canary refspec, migration
-- version, GitHub PAT, subtitles, logos, etc.) are excluded — they teach
-- the human operator, not the legal assistant.
--
-- Each row is inserted with:
--   * correction_source = 'lawyer_review'  (seeded by maintainer, not user)
--   * user_id           = NULL             (corpus-wide, not user-attributed)
--   * embedding         = NULL             (a backfill job runs OpenAI
--                                           text-embedding-3-small over the
--                                           question column once we deploy;
--                                           in the meantime match_corrections
--                                           returns 0 rows because the RPC
--                                           filters on embedding IS NOT NULL)
--   * metadata          = {'seeded_from': '<lesson_file>'}
--
-- ON CONFLICT DO NOTHING via deterministic UUID guards re-running the
-- migration in development without duplicating rows.
-- ============================================================================

-- ─── 1. HAO vs KHO jurisdiction (lesson_HAO_KHO_restoration_jurisdiction.md)
-- The single most expensive AI confusion we've caught: assistant routed a
-- menetetyn määräajan palauttaminen filing to HAO. HOL §114-115 reserves
-- that to KHO; HAO is statutorily incompetent.
INSERT INTO public.advice_corrections (
  id, user_id, question, wrong_advice, correct_answer, why_wrong,
  correction_source, jurisdiction, case_type, severity, embedding, metadata
) VALUES (
  '00000000-0000-0000-0000-000000010001',
  NULL,
  'Can HAO (Helsinki Administrative Court) hear a menetetyn määräajan palauttaminen request — restoration of a missed administrative-court appeal deadline?',
  'Yes, HAO can hear the restoration request together with the underlying appeal.',
  'No. Restoration of a missed administrative-court deadline (menetetyn määräajan palauttaminen) is the exclusive jurisdiction of KHO (Korkein hallinto-oikeus) under HOL §114 (1)(1) and §115 (1). Filing it at HAO results in an automatic ei tutki outcome. The appeal itself may go to HAO, but the restoration filing must be addressed to KHO — two different courts, one envelope to KHO when both are needed.',
  'Confused HAO''s general administrative-appeal jurisdiction with the restoration jurisdiction reserved to the supreme administrative court. The 30-day clock for restoration runs from laillisen esteen lakkaaminen, not from the original deadline.',
  'lawyer_review',
  'FI',
  'administrative',
  'procedural',
  NULL,
  jsonb_build_object('seeded_from', 'lesson_HAO_KHO_restoration_jurisdiction.md')
) ON CONFLICT (id) DO NOTHING;

-- ─── 2. Sulga identity error #1 — citizenship "Neuvostoliitto" ─────────────
-- (lesson_sulga_three_identity_errors.md, item 1)
INSERT INTO public.advice_corrections (
  id, user_id, question, wrong_advice, correct_answer, why_wrong,
  correction_source, jurisdiction, case_type, severity, embedding, metadata
) VALUES (
  '00000000-0000-0000-0000-000000010002',
  NULL,
  'A Finnish police decision records the citizenship of an Estonian EU citizen as "Neuvostoliitto" (Soviet Union). Is this a typo with no procedural consequence?',
  'It''s a minor typo. The substance of the decision is unaffected; mention it once if you like but it''s not strategically useful.',
  'It is NOT a typo — it is a category error. The Soviet Union ceased to exist in 1991; an EU citizen cannot be recorded under a defunct state. This is strategically usable evidence of systemic identification failure under Ulkomaalaislaki 196 § (erityisen painava syy) and Direktiivi 2004/38/EY due-process standards. Combined with other identification errors in the same file it supports a KHO valituslupa application on oikeuskäytännön yhtenäisyys grounds.',
  'Treated a clearly wrong categorical fact ("Neuvostoliitto" for an Estonian) as a stylistic typo. The legal weight comes from accumulation and category-error analysis under EU citizenship law.',
  'lawyer_review',
  'FI',
  'deportation',
  'strategic',
  NULL,
  jsonb_build_object(
    'seeded_from', 'lesson_sulga_three_identity_errors.md',
    'error_id', 1
  )
) ON CONFLICT (id) DO NOTHING;

-- ─── 3. Sulga identity error #2 — signature error (allekirjoitusvirhe) ─────
-- (lesson_sulga_three_identity_errors.md, item 2)
INSERT INTO public.advice_corrections (
  id, user_id, question, wrong_advice, correct_answer, why_wrong,
  correction_source, jurisdiction, case_type, severity, embedding, metadata
) VALUES (
  '00000000-0000-0000-0000-000000010003',
  NULL,
  'A Finnish police käännytyspäätös contains an obvious signature defect (wrong signatory or missing authentication marks). Should this be raised in HAO appeal as a procedural ground?',
  'Signature defects are cosmetic and rarely fatal. Focus on the substantive proportionality argument; mention the signature in passing only.',
  'Raise it explicitly as a procedural ground. Allekirjoitusvirhe in a hallintopäätös attacks the formal validity of the decision itself. Combined with the other identification errors in the same file (citizenship category error, name error on saantitodistus), it forms a systemic-failure pattern strong enough to support KHO valituslupa under "lain soveltamisen kannalta muissa samanlaisissa tapauksissa".',
  'Underweighted formal validity defects. In immigration decisions affecting an EU citizen, every procedural defect compounds and supports the disproportionality + due-process line.',
  'lawyer_review',
  'FI',
  'deportation',
  'procedural',
  NULL,
  jsonb_build_object(
    'seeded_from', 'lesson_sulga_three_identity_errors.md',
    'error_id', 2
  )
) ON CONFLICT (id) DO NOTHING;

-- ─── 4. Sulga identity error #3 — Dimitri vs Dmitri (saantitodistus) ───────
-- (lesson_sulga_three_identity_errors.md, item 3)
INSERT INTO public.advice_corrections (
  id, user_id, question, wrong_advice, correct_answer, why_wrong,
  correction_source, jurisdiction, case_type, severity, embedding, metadata
) VALUES (
  '00000000-0000-0000-0000-000000010004',
  NULL,
  'HAO addressed the international saantitodistus envelope to "Dimitri" instead of "Dmitri". Posti staff confirmed no notification was sent because the name did not match. Does this affect the tiedoksisaanti / deadline analysis?',
  'No. Tiedoksisaanti is formally on the date the recipient signed for the envelope; the spelling discrepancy is the recipient''s problem to clarify with Posti.',
  'Yes — this is delay caused by the STATE itself, not laillinen este on the client side. The state cannot rely on technical compliance with its own deficient document to defeat the appeal. This bolsters the menetetyn määräajan palauttaminen application and forms a third data point in the systemic identification failure pattern (alongside the Neuvostoliitto and signature errors). It does not change the formal sign date, but it changes the equitable analysis on extension grounds.',
  'Confused formal tiedoksisaanti date (sign date) with the question of whether the state''s own error caused the delay. Two separate analyses, both relevant to KHO valituslupa.',
  'lawyer_review',
  'FI',
  'deportation',
  'procedural',
  NULL,
  jsonb_build_object(
    'seeded_from', 'lesson_sulga_three_identity_errors.md',
    'error_id', 3
  )
) ON CONFLICT (id) DO NOTHING;

-- ─── 5. Don't lead with deportation framing for Advocat product
-- (lesson_canon_outdated_deportation_framing.md). The product spans 17
-- languages and 16 features including vehicle/company checker, employment,
-- consumer, housing, fines, rights guide, legal aid. Deportation is ONE
-- use case among many.
INSERT INTO public.advice_corrections (
  id, user_id, question, wrong_advice, correct_answer, why_wrong,
  correction_source, jurisdiction, case_type, severity, embedding, metadata
) VALUES (
  '00000000-0000-0000-0000-000000010005',
  NULL,
  'When describing what Advocat covers or which Estonian/Finnish legal issue an Advocat user can ask about, what is the scope?',
  'Advocat is an AI legal defense product for EU immigrants, focused primarily on deportation and asylum cases in Finland/Estonia.',
  'Advocat covers 16+ feature areas across 17 languages (Estonian, Finnish, English, Russian, plus 13 more): vehicle checker, company checker, employment law, consumer protection, housing, fines, family, rights guide, legal aid calculator, contract review, deadline radar, email assistant, vault, document drafting, citation grounding, intake wizard. Deportation/asylum is ONE use case, not the spine. Always frame responses against the user''s actual question type — never default to immigration framing.',
  'Followed an outdated STRATEGY_CANON.md framing instead of inspecting shipped features. Real product capability lives in app/advocat_project/lib/features/ and app/advocat_project/lib/l10n/.',
  'lawyer_review',
  NULL,
  NULL,
  'strategic',
  NULL,
  jsonb_build_object('seeded_from', 'lesson_canon_outdated_deportation_framing.md')
) ON CONFLICT (id) DO NOTHING;

-- ─── 6. Verify live data before designing legal artefacts ──────────────────
-- (lesson_email_prompt_written_blind.md). Closely related to the
-- design_artefacts_must_check_live_data feedback rule. When advising
-- on a multi-thread / multi-track case, never reason from canon /
-- memory snapshots — verify the actual current state first.
INSERT INTO public.advice_corrections (
  id, user_id, question, wrong_advice, correct_answer, why_wrong,
  correction_source, jurisdiction, case_type, severity, embedding, metadata
) VALUES (
  '00000000-0000-0000-0000-000000010006',
  NULL,
  'A user asks for advice on a multi-track case where there are several open threads with authorities (police, court, ministry, prosecutor). What is the safe starting point?',
  'Read the case canon / memory entries and prior advice digest, then synthesize a response. The canon is the source of truth for current status.',
  'Always verify against the LATEST artefact before synthesising advice. Memory entries and canon documents have short half-life — Dnro / R-number assignments, käsittely status, and ministry decisions change daily. When the user has provided thread IDs, document numbers, or dates, treat THOSE as ground truth and use canon only for stable background (statutes, contacts, deadlines once verified). If a fact is going to drive a recommendation, re-verify it.',
  'Trusted stale memory over live data — the same error class as the email-prompt-written-blind incident. The remedy is inspect-first, narrative-second.',
  'lawyer_review',
  NULL,
  NULL,
  'strategic',
  NULL,
  jsonb_build_object('seeded_from', 'lesson_email_prompt_written_blind.md')
) ON CONFLICT (id) DO NOTHING;

-- ─── 7. create_draft creates DRAFTS, not sends ─────────────────────────────
-- (lesson_gmail_mcp_create_draft_is_actually_draft.md). Affects every
-- piece of legal advice that says "I''ve emailed the authority". This is
-- a behavioural correction for the assistant when it reports tool outcomes
-- to the user.
INSERT INTO public.advice_corrections (
  id, user_id, question, wrong_advice, correct_answer, why_wrong,
  correction_source, jurisdiction, case_type, severity, embedding, metadata
) VALUES (
  '00000000-0000-0000-0000-000000010007',
  NULL,
  'After invoking the Gmail create_draft tool on a legal email (e.g. a reply to an authority), can the assistant tell the user "I''ve sent the email"?',
  'Yes — create_draft sends the email. The tool name is misleading but it actually sends.',
  'No. create_draft creates an ACTUAL draft in the Gmail Drafts folder. The message does not go out automatically. After every create_draft call: tell the user "I created the draft, please open Gmail, review, and click Send" — never say "I sent the email" based on create_draft alone. Verify with list_drafts (message appears in list_drafts = it is a draft) before claiming a send. For legally-binding sends use the in-app send-email edge function which actually sends and supports attachments + audit log.',
  'Confused tool name with tool behaviour. The MCP semantics changed between 2026-04 and 2026-05; the assistant relied on stale rule that said create_draft = send.',
  'lawyer_review',
  NULL,
  NULL,
  'factual',
  NULL,
  jsonb_build_object('seeded_from', 'lesson_gmail_mcp_create_draft_is_actually_draft.md')
) ON CONFLICT (id) DO NOTHING;

-- ─── 8. HOL §114 restoration window + jurisdiction (eval harness Phase 1) ─
-- (eval_harness_phase1 caught a real production hallucination 2026-05-13.)
-- The assistant invented (a) a 30-day window from the missed deadline, (b) a
-- 1-year cap, and (c) routed jurisdiction to "the court where the matter is
-- pending". HOL §114-115 is exclusive KHO jurisdiction; the time window is
-- 5 years from the missed deadline; standard is erityisen painava syy.
INSERT INTO public.advice_corrections (
  id, user_id, question, wrong_advice, correct_answer, why_wrong,
  correction_source, jurisdiction, case_type, severity, embedding, metadata
) VALUES (
  '00000000-0000-0000-0000-000000010008',
  NULL,
  'Mitä Hallintolainkäyttölaki §114 sanoo menetetyn määräajan palauttamisesta?',
  'Hakemus on tehtävä 30 päivän kuluessa siitä, kun este on lakannut. Hakemusta ei voida tehdä vuoden kuluttua määräajan päättymisestä. Hakemuksen käsittelee se tuomioistuin, jossa asia on vireillä.',
  'HOL §114-115 reserves restoration of missed deadlines (menetetyn määräajan palauttaminen) exclusively for KHO (Korkein hallinto-oikeus). Time window: 5 years from the missed deadline, not 30 days. Standard required: erityisen painava syy (especially weighty reason). NOT handled by the court where the matter is pending — only KHO has jurisdiction.',
  'Three distinct factual errors: (1) confused 30-day general appeal window with restoration window which is 5 years, (2) invented "one-year cap" that does not exist in HOL §114, (3) routed jurisdiction to "court where matter is pending" but HOL §114-115 is exclusive KHO jurisdiction.',
  'eval_failure',
  'fi',
  'administrative',
  'factual',
  NULL,
  jsonb_build_object(
    'discovered_by', 'eval_harness_phase1',
    'discovered_at', '2026-05-13',
    'eval_item_id', 'statute-001'
  )
) ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- Seed total: 8 rows.
-- ============================================================================
