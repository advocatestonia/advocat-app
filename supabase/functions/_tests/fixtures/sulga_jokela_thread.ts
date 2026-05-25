// supabase/functions/_tests/fixtures/sulga_jokela_thread.ts
// -----------------------------------------------------------------------------
// E2E fixture — sanitized version of the real Sulga ↔ asianajaja Jokela
// thread used by `email_agent_e2e_test.ts`.
//
// PROVENANCE
//   Source thread:  /Users/ai.place/Advocat/cases/sulga/_outbound/
//                   2026-05-25_Jokela_Migri_yes/body_FI.txt
//                   (Sulga's reply that confirmed the Migri UL §150
//                   peruuttaminen-hakemus instruction.)
//   Counterpart:    asianajaja Minna Jokela — replaced here with a synthetic
//                   address  attorney@example-law.test  so committed fixtures
//                   carry no live identity.
//   Date captured:  2026-05-25
//   Sanitized by:   testing-and-quality-assurance agent, 2026-05-25.
//                   All PII removed: real name, phone, asiakasnumero,
//                   personal email, real attorney email, real case number
//                   `5500/R/75170/25` → `9999/R/99999/99`. Statute citations
//                   (UL §150, EIS 6.3, Dir 2004/38, CJEU C-348/09 / C-331/16 /
//                   C-371/08) preserved verbatim — they are public law and
//                   load-bearing for the consilium response shape.
//
// WHY A REAL CASE?
//   The Jokela 2026-05-25 thread is the canonical multi-action triage case
//   the production system has seen: it produces TWO parallel actions in the
//   consilium output (reply-to-counsel + asiakirjapyyntö-to-court) which
//   neither of the legacy single-draft fixtures exercise.
// -----------------------------------------------------------------------------

import type { ThreadRecord } from "../../email-triage/triage_logic.ts";

// ─── Synthetic identities (NEVER use these for real mail) ───────────────────
export const FX_USER_EMAIL = "client@example.test";
export const FX_USER_NAME = "Test Client";
export const FX_USER_ID = "00000000-0000-4000-8000-000000000001";
export const FX_ATTORNEY_EMAIL = "attorney@example-law.test";
export const FX_ATTORNEY_NAME = "Test Attorney";
export const FX_COURT_REGISTRY_EMAIL = "registry@example-court.test";
export const FX_CASE_NUMBER = "9999/R/99999/99"; // sanitized
export const FX_THREAD_ID = "00000000-0000-4000-8000-0000000000a1";
export const FX_CASE_ID = "00000000-0000-4000-8000-0000000000b1";

// ─── Scenario A: simple inbound — court registry receipt confirmation ──────
//
// Routine acknowledgement. Expect: 1 draft, MEDIUM severity, posture=reply_now.
// Mirrors fixture B in the existing triage_logic_test.ts but uses the e2e
// thread shape (so we share helpers).
export const SIMPLE_RECEIPT_THREAD: ThreadRecord = {
  id: FX_THREAD_ID,
  user_id: FX_USER_ID,
  case_id: FX_CASE_ID,
  subject: "Vastaanotettu — dnro 12345/2026",
  participants: [FX_COURT_REGISTRY_EMAIL, FX_USER_EMAIL],
  messages: [
    {
      id: "msg-a-1",
      gmail_message_id: "gmail-a-1",
      sender_email: FX_COURT_REGISTRY_EMAIL,
      sender_name: "Court Registry",
      to_recipients: [FX_USER_EMAIL],
      cc_recipients: [],
      subject: "Vastaanotettu — dnro 12345/2026",
      body_plaintext:
        "Viestinne on vastaanotettu, kirjattu diaariin 12345/2026.",
      sent_at: "2026-05-25T08:30:00Z",
      has_attachments: false,
      attachments_meta: [],
      headers_meta: {},
    },
  ],
};

// ─── Scenario B: complex Sulga/Jokela inbound — counsel proposes hakemus ────
//
// In the real thread, asianajaja Jokela proposed filing a Migri UL §150
// maahantulokielto-peruuttaminen hakemus so the client could attend the
// käräjäoikeus main hearing as vastaaja.  Sulga's strategy reply (preserved
// verbatim structure, identifiers redacted) instructs:
//
//   * file hakemus (rajattu / ehdollinen)
//   * non-prejudice clause re KHO-asia
//   * cite UL §150, EIS 6.3, Dir 2004/38, CJEU jurisprudence
//   * IN PARALLEL — ask the käräjäoikeus registry for haastehakemus
//     päivämäärä + tiedoksiannon tapa + pääkäsittelyn aikataulu
//
// EXPECTED CONSILIUM OUTPUT:
//   proposed_actions: [
//     { idx: 0, target: attorney,        type: reply,         draft: ... },
//     { idx: 1, target: court_registry,  type: asiakirjapyyntö, draft: ... },
//   ]
// -----------------------------------------------------------------------------
export const COMPLEX_JOKELA_THREAD: ThreadRecord = {
  id: FX_THREAD_ID,
  user_id: FX_USER_ID,
  case_id: FX_CASE_ID,
  subject: "VS: Migri UL §150 — peruuttaminen-hakemus oikeudenkäyntiä varten",
  participants: [FX_ATTORNEY_EMAIL, FX_USER_EMAIL],
  messages: [
    {
      id: "msg-b-1",
      gmail_message_id: "gmail-b-1",
      sender_email: FX_USER_EMAIL,
      sender_name: FX_USER_NAME,
      to_recipients: [FX_ATTORNEY_EMAIL],
      cc_recipients: [],
      subject: "Migri UL §150 — voiko peruuttaa oikeudenkäyntiä varten?",
      body_plaintext:
        "Hei, voiko UL §150 mukaan hakea maahantulokiellon peruuttamista " +
        "vain käräjäoikeuden pääkäsittelyn ajaksi? Aluesyyttäjä vahvisti " +
        "vastaaja-aseman asiassa " + FX_CASE_NUMBER + ".",
      sent_at: "2026-05-25T09:00:00Z",
      has_attachments: false,
      attachments_meta: [],
      headers_meta: {},
    },
    {
      id: "msg-b-2",
      gmail_message_id: "gmail-b-2",
      sender_email: FX_ATTORNEY_EMAIL,
      sender_name: FX_ATTORNEY_NAME,
      to_recipients: [FX_USER_EMAIL],
      cc_recipients: [],
      subject: "VS: Migri UL §150 — peruuttaminen-hakemus oikeudenkäyntiä varten",
      body_plaintext:
        "Hei,\n\nkyllä voin tehdä UL §150 (3 mom) mukaisen rajatun " +
        "peruuttamishakemuksen, 100 € käsittelymaksu. Vahvistakaa, jos " +
        "haluatte että jätän hakemuksen — palaan luonnoksella ennen jättämistä.\n\n" +
        "Ystävällisin terveisin,\n" + FX_ATTORNEY_NAME,
      sent_at: "2026-05-25T10:15:00Z",
      has_attachments: false,
      attachments_meta: [],
      headers_meta: {},
    },
  ],
};

// ─── Canned consilium output — Scenario A (simple) ──────────────────────────
//
// 6-block v1.1-final shape. The orchestrator will Phase-1 hard-cap
// `auto_send_eligible` → `hold_for_user_review`, but the parser + reviewer
// must still pass.
export const CANNED_A_TRIAGE = `<privilege_check>passed</privilege_check>
<conflict_check>passed</conflict_check>
<triage>
TRACK: [registry_acknowledgement]
INBOUND: receipt confirmation from court registry
KEY FACTS:
  - Court registry confirms receipt
  - Dnro 12345/2026 assigned
DEADLINES: none
CONTRADICTIONS: none
EVIDENCE GAPS: none
POSTURE: reply_now
REASONING: Routine acknowledgement — short thank-you back.
</triage>
<draft language="fi" addressed_to="${FX_COURT_REGISTRY_EMAIL}">
Subject: Vastaus: Vastaanotettu — dnro 12345/2026

Arvoisa kirjaamo,

vahvistan vastaanottaneeni dnro 12345/2026.

Ystävällisin terveisin,
${FX_USER_NAME}
</draft>
<gdpr_basis>
recipient: ${FX_COURT_REGISTRY_EMAIL}
art_6_basis: (c)
art_9_basis: n/a
art_10_basis: n/a
</gdpr_basis>
<actions_required>
- type: other
  target: monitor
  deadline: 2026-11-25
  why: track decision window
</actions_required>
<user_brief language="ru">Подтверждение получения, дело 12345/2026.</user_brief>
<send_recommendation>auto_send_eligible</send_recommendation>`;

// ─── Canned consilium output — Scenario B (complex Sulga/Jokela) ────────────
//
// Important shape note: this fixture writes the v1.1-final 6-block schema
// because that is what the orchestrator's `parse_blocks.ts` consumes today.
// The 15-lawyer consilium synthesis is captured separately on the
// AnthropicResponse as `lawyer_opinions` + `consilium_synthesis` — see
// CANNED_B_LAWYER_OPINIONS below. The PARALLEL ACTION shape (idx=0 reply,
// idx=1 asiakirjapyyntö) is represented in <actions_required> with the
// `target` discriminating the two outputs.
//
// When email-send (built by the parallel agent) lands with `action_idx`
// support, the test that exercises Scenario B will route action_idx=0 to
// FX_ATTORNEY_EMAIL and action_idx=1 to FX_COURT_REGISTRY_EMAIL.
export const CANNED_B_TRIAGE = `<privilege_check>own_counsel_advisory</privilege_check>
<conflict_check>passed</conflict_check>
<triage>
TRACK: [migri_ul150_peruuttaminen, karajaoikeus_vastaaja]
INBOUND: counsel proposes UL §150 (3 mom) rajattu peruuttamishakemus
KEY FACTS:
  - Counsel will file rajattu hakemus on confirmation, fee 100 EUR
  - Aluesyyttäjä confirmed vastaaja-asema in case ${FX_CASE_NUMBER}
  - Hakemus must NOT prejudice pending KHO-asia
  - Legal anchors: UL §150 (3 mom), EIS 6.1 + 6.3 (c)(d), Dir 2004/38/EY 27-28
  - CJEU support: C-348/09 P.I., C-331/16 K., C-371/08 Ziebell
DEADLINES:
  - 2026-06-01 (Δ 7 days) — confirm hakemus instruction to counsel
CONTRADICTIONS: none
EVIDENCE GAPS:
  - käräjäoikeus haastehakemus päivämäärä not yet on record
POSTURE: reply_now
REASONING: Two parallel actions required — confirm hakemus to counsel AND fetch case schedule from court registry so counsel can scope the rajaus.
</triage>
<draft language="fi" addressed_to="${FX_ATTORNEY_EMAIL}">
Subject: Vahvistus: hakekaa Migri UL §150 peruuttaminen oikeudenkäyntiä varten

Hei,

kyllä, hakekaa maahantulokiellon peruuttamista oikeudenkäyntiin osallistumista varten. Maksan 100 euron käsittelymaksun.

Pyytäisin huomioimaan neljä seikkaa:

1. Rajattu/ehdollinen peruuttaminen — vain Helsingin käräjäoikeuden pääkäsittelyä koskevia päiviä varten.
2. Hakemus ei korvaa vireillä olevaa KHO-asiaa koskien käännyttämispäätöksen laillisuutta.
3. Perusteluiksi: UL §150 (3 mom), EIS 6.1 + 6.3 (c)(d), Direktiivi 2004/38/EY 27-28 art., CJEU C-348/09 P.I., C-331/16 K., C-371/08 Ziebell.
4. Toivoisin luonnoksen tarkistettavaksi ennen jättämistä.

Ystävällisin terveisin,
${FX_USER_NAME}
</draft>
<gdpr_basis>
recipient: ${FX_ATTORNEY_EMAIL}
art_6_basis: (b)
art_9_basis: n/a
art_10_basis: n/a
</gdpr_basis>
<actions_required>
- type: reply
  target: ${FX_ATTORNEY_EMAIL}
  deadline: 2026-06-01
  why: confirm UL §150 hakemus instruction
- type: asiakirjapyynto
  target: ${FX_COURT_REGISTRY_EMAIL}
  deadline: 2026-06-01
  why: request haastehakemus date + tiedoksiannon tapa + pääkäsittelyn aikataulu in case ${FX_CASE_NUMBER}
</actions_required>
<user_brief language="ru">Адвокат готов подать UL §150 hakemus (100 €). Подтверждение даёт ход; параллельно — запрос в käräjäoikeus о расписании дела ${FX_CASE_NUMBER}.</user_brief>
<send_recommendation>hold_for_user_review</send_recommendation>`;

/**
 * The 5+ lawyer-opinion payloads the consilium produced for Scenario B.
 * Wired by the orchestrator's `callConsilium` dep (when present) into the
 * AnthropicResponse it returns. The audit row writes these to
 * `email_triage_results.lawyer_opinions`.
 */
export const CANNED_B_LAWYER_OPINIONS = [
  {
    role_id: "immigration-fi",
    role_name: "Immigration FI",
    opinion:
      "UL §150 (3 mom) sallii rajatun peruuttamisen painavasta syystä. " +
      "Vastaajan oikeus osallistua pääkäsittelyyn täyttää kriteerin.",
    position: "push",
    confidence: 0.85,
    key_citation: "[[ref:ulkomaalaislaki:150]]",
  },
  {
    role_id: "criminal-fi",
    role_name: "Criminal FI",
    opinion:
      "EIS 6.1 ja 6.3 (c)(d) takaavat henkilökohtaisen osallistumisen ja " +
      "todistajien kuulustelun oikeuden. Etäosallistuminen ei korvaa läsnäoloa.",
    position: "push",
    confidence: 0.9,
    key_citation: "[[ref:eis:6.3]]",
  },
  {
    role_id: "procedural-posture",
    role_name: "Procedural Posture",
    opinion:
      "Rajattu hakemus välttää ennakkokannan ottamista käännytyspäätöksen " +
      "laillisuuteen — paralleeli KHO-asialle.",
    position: "push",
    confidence: 0.75,
    key_citation: null,
  },
  {
    role_id: "consumer-eu",
    role_name: "EU Free Movement",
    opinion:
      "Direktiivin 2004/38/EY 27-28 art. edellyttävät suhteellisuutta ja " +
      "yksilöllistä arviointia EU-kansalaisen tapauksessa.",
    position: "push",
    confidence: 0.8,
    key_citation: "[[ref:dir-2004-38:27]]",
  },
  {
    role_id: "deadline-strategist",
    role_name: "Deadline Strategist",
    opinion:
      "Käräjäoikeuden aikataulu on tunnettava ennen rajauksen päivämääriä; " +
      "asiakirjapyyntö rinnakkain hakemuksen kanssa.",
    position: "investigate",
    confidence: 0.7,
    key_citation: null,
  },
];

export const CANNED_B_SYNTHESIS =
  "Consilium synthesis: file the rajattu UL §150 hakemus with the four " +
  "anchors (UL §150, EIS 6.3, Dir 2004/38, CJEU) AND fire a parallel " +
  "asiakirjapyyntö to the käräjäoikeus registry for the schedule. The " +
  "two actions must travel together so counsel can scope the rajaus to " +
  "the actual hearing dates.";
