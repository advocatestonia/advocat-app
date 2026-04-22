# Legal review checklist — for a 1-hour review with an EU legal-tech lawyer

**Budget:** 1 hour @ €300-€450/h = **€300-€450 one-off**
**Owner:** Sulga (Vorantis OÜ)
**Goal:** get a qualified EU lawyer to either sign off or flag concrete edits on our v1.0 legal docs before closed-beta launch.

---

## Documents to send the lawyer in advance (reading material)

All already in the repo under `/Users/ai.place/Advocat/app/docs/`:

1. `PRIVACY_POLICY.md` v1.0
2. `TERMS_OF_SERVICE.md` v1.0
3. `EU_AI_ACT_COMPLIANCE.md` v1.0
4. `AI_TRANSPARENCY_NOTICE.md`
5. `IN_APP_DISCLAIMERS.md`

Plus context:
- Company: Vorantis OÜ, reg 17098992, Tallinn, Estonia.
- Product: Advocat, AI legal information assistant for EU consumers.
- Stack: Flutter Web, Supabase, Claude (Anthropic), Google Cloud TTS, ElevenLabs, Stripe.
- Jurisdictions we operate in: full = EE/FI/LV/LT/SE/PL; medium-risk = ES/RO; disclaimer-heavy = DE/IT/FR.
- Target user: consumer, not lawyer.
- Monetisation: Free / Basic €14.99 / Pro €29.99 monthly.

## What we KNOW is fine (for owner to confirm)

These do not need a lawyer to rewrite — only to glance at and sanity-check:

- [ ] Company identity: Vorantis OÜ, reg 17098992, Tornimäe tn 5 Tallinn, support@advocat.ee — correct and matches e-Business Register.
- [ ] Jurisdiction heatmap in `EU_AI_ACT_COMPLIANCE.md` (Full/Medium/Disclaimer-heavy) — confirm Germany RDG + France + Italy disclaimer language is current.
- [ ] AI Act risk classification: "limited risk" (our classification in `AI_TRANSPARENCY_NOTICE.md`). Consumer-facing AI chat with transparency banner = Article 52 obligations only. **Lawyer to confirm this is not a "high-risk" system** under Annex III (legal assistance to consumers is not explicitly listed, but ask anyway).

## What we SUSPECT needs the lawyer's pen

These are the concrete items we want the lawyer to green-light or hand back with tracked changes:

### 1. Privacy Policy — scope of "AI processing"
- [ ] §3 "Data we process": does our current list (email, name, case text, documents, chat history) match Art. 13 GDPR information requirements for the *AI-specific* processing? In particular:
  - Recipient Anthropic (Claude) — are we required to name them, or is "sub-processors list on request" enough?
  - Recipient ElevenLabs / Google TTS — voice data handling.
  - Retention after cancellation: currently "30 days then hard delete" — lawyer to confirm this meets Art. 5(1)(e) storage limitation for legal-information-service purpose.
- [ ] §7 Art. 22 automated-decision-making: we claim Advocat is not automated decision-making because output is informational. **Lawyer must sign off** — this is the highest-risk interpretation in our doc.
- [ ] §9 DPO: we state "no DPO required" based on Art. 37(1). Lawyer to confirm — our processing does not involve large-scale systematic monitoring or special-category data at launch scale (<1000 beta users).

### 2. Terms of Service — UPL carve-outs
- [ ] §2 "Not a law firm": is our current phrasing sufficient under **Estonian Advokatuuri seadus** (bar-association law) to prevent UPL claims?
- [ ] Same check for **Finnish Laki asianajajista** — Finland is our #2 market and strictest bar.
- [ ] Same check for **German RDG §3** — we show a special disclaimer for German users at the top of the chat; lawyer to confirm the wording is RDG-compliant.
- [ ] Liability cap: currently "€100 or fees paid in the last 12 months". Lawyer to confirm this is enforceable under Estonian VÕS + B2C consumer unfairness rules.
- [ ] Governing law: Estonia + exclusive jurisdiction of Harju County Court. Any consumer-directive issue (93/13/EEC) with forcing foreign consumers to litigate in Tallinn?

### 3. EU AI Act
- [ ] Art. 52 transparency: our "AI Transparency Notice" banner appears at first use and in settings. Lawyer to confirm wording.
- [ ] Art. 50(2) obligation (artificially generated content labels): do our AI-drafted documents need a "generated with AI assistance" footer? Currently they don't; we explain to the user at generation time.
- [ ] Code of Practice signatory: do we need to sign the EU AI Code of Practice before August 2026? Probably not for a limited-risk system but worth asking.

### 4. Cookie & consent
- [ ] Landing cookie banner (wave1-3) — minimal, strictly-necessary only, respects DNT. Lawyer to glance at whether we need a proper CMP (OneTrust/Cookiebot) before paid ads, or can keep this in-house.

### 5. Finland-specific (because the Sulga case lives there)
- [ ] Finnish Rikoslaki §38 "data protection offence" — any risk from caching sensitive case details (asylum/deportation) in Supabase?
- [ ] Advocat's own handling of the founders' real case (Sulga v Finland) — lawyer to advise whether the product should include a "do not use for your own case if you are the product owner" disclaimer (conflict-of-interest optics).

## Shortlist: EU lawyers with legal-tech / GDPR experience in EE/FI

*Rates and contact details are public at time of writing — verify before booking.*

### Estonia

1. **Walless (formerly Cobalt) — Tech & Data Practice**
   - Contact: `info@walless.ee`
   - Rate: €300-€400/h, solid Estonian-Finnish legal-tech portfolio.
   - Known for: GDPR work for Bolt, Pipedrive.

2. **Triniti — IP & Tech**
   - Contact: `tallinn@triniti.legal`
   - Rate: €250-€350/h.
   - Known for: Skype legacy work, e-resident start-ups.

3. **Hedman Partners**
   - Contact: `info@hedman.legal`
   - Rate: €200-€300/h, start-up-friendly.
   - Recommended by Startup Estonia.

### Finland (if the Finnish UPL question is the biggest concern)

4. **Castrén & Snellman — Technology & IP**
   - Contact: `info@castren.fi`
   - Rate: €350-€500/h (Magic Circle tier).
   - Overkill for a €450 review but great signal value later if needed.

5. **Dottir Attorneys** (start-up focused)
   - Contact: `info@dottir.co`
   - Rate: €250-€400/h.
   - Worked with several Nordic legal-tech startups.

### Alternative: fixed-fee reviews

6. **Law.co / LegalVision EU fixed-fee product-review packages**
   - €499 for a 3-document privacy/ToS review within 5 business days.
   - Good option if the owner does not want hourly uncertainty.

## Recommended flow

1. Send the 5 markdown files + this checklist to 2 shortlisted firms for a fixed-fee quote.
2. Pick the cheaper one if responses are comparable.
3. Book 1 hour (or the fixed-fee package), walk through the 12 checkbox items above.
4. Incorporate tracked changes into the .md files.
5. Bump docs to v1.1 and re-link from the in-app Settings → Legal section.
6. **Do NOT ship without this step** for paid users; closed-beta free-tier can ship without if the owner accepts the residual risk.

## What NOT to ask the lawyer

We already resolved these internally and do not want to pay hourly for:
- General product-market-fit advice.
- Cookie-banner design (wave1-3 ships a minimal, DNT-respecting banner).
- AI model choice (Claude vs others).
- Pricing strategy.
- Agency agreement / employment contracts (no employees yet).
