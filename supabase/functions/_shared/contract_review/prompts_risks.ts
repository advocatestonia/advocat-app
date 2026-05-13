// prompts_risks.ts — Risk taxonomy + optional industry add-on modules.
// -----------------------------------------------------------------------------
// Base taxonomy lists the five severities and five categories the model must
// use. Industry tags activate one (and only one) add-on; unknown tags are a
// no-op (return base only — never throw).
// -----------------------------------------------------------------------------

const RISK_BASE = `For every issue you surface, classify it into ONE of the five categories
below AND assign a severity. Severities go to the JSON \`top_risks[].severity\`
field and drive UI colour-coding.

Severities:
- **CRITICAL** — could nullify the contract, expose unbounded liability, or
  breach mandatory law. User must not enter or must renegotiate.
- **HIGH** — clearly disadvantageous; commercially or legally one-sided.
- **MEDIUM** — worth negotiating; not deal-breaking.
- **INFO** — neutral observation the user should be aware of.
- **GOOD** — a clause that actually protects the user; highlight as wins.

Categories:
1. **Commercial** — price, payment terms, volume, exclusivity, term/renewal,
   termination fees, MOQ, rebates, MFN clauses.
2. **Legal** — governing law, jurisdiction, dispute resolution, mandatory-law
   conflicts, AGB / unfair-terms control, severability.
3. **Warranty & liability** — warranty scope & duration, indemnity, liability
   caps, consequential damages exclusion, force majeure, insurance.
4. **IP & data** — IP ownership, licence scope, background vs foreground IP,
   moral rights, GDPR / DPA obligations, security standard, audit rights.
5. **Operational** — delivery, acceptance, SLA, support, escrow, change
   control, key-person, subcontracting, audit, exit assistance.
`;

const RISK_DEALER = `## Industry add-on: dealer / distribution / commercial agency
- Territorial exclusivity vs sole vs non-exclusive — be precise.
- Sales targets / minimum purchase obligations and the consequences of
  missing them (clawback, loss of exclusivity, termination).
- Termination notice period vs. amortisation of dealer investments (stock,
  showroom, training).
- Post-termination: stock buy-back at what price (invoice / net / fair
  market)? Right to continue servicing existing customers?
- **DACH only**: Handelsvertreter Ausgleichsanspruch (HGB § 89b) — cannot
  be excluded in advance; flag clauses pretending to do so.
- **EU competition law**: Vertical Block Exemption Reg. (VBER) 2022/720 —
  hardcore restrictions (RPM, absolute territorial protection, online-sales
  bans) void the exemption.
`;

const RISK_SAAS = `## Industry add-on: SaaS / software-as-a-service
- Uptime SLA: definition of "available", measurement window, scheduled vs
  unscheduled downtime, service credit cap.
- Data ownership: customer data vs aggregated/derived data. Right to delete
  on termination, export format, retention period after termination.
- Sub-processors: list + change-notification mechanism + opt-out window.
- Security baseline: ISO 27001, SOC 2 Type II, encryption at rest & in
  transit, breach notification SLA (24h / 48h / 72h).
- IP: customer retains its data; provider retains the platform. Feedback /
  improvement licence — perpetual? royalty-free? Acceptable, but be aware.
- Source-code escrow: relevant if vendor lock-in is high.
- Acceptable use, suspension rights, fair-use definitions.
`;

const RISK_NDA = `## Industry add-on: NDA / mutual confidentiality
- Symmetry: is the obligation mutual or one-sided? Many "mutual" NDAs are
  drafted with one party as the de-facto discloser.
- Definition of Confidential Information: marked-only? Catch-all? Reasonable
  to know it is confidential?
- Carve-outs: public domain, independently developed, lawfully received from
  a third party, court-ordered disclosure (with prompt notice).
- Duration: perpetual for trade secrets, fixed (3–5 yr) for everything else.
- Residual-knowledge clause: protects the recipient but is poison for the
  discloser. Flag in both directions.
- Return / destruction of materials on termination; certified destruction.
- Injunctive-relief carve-out and choice-of-law for the IP.
`;

const RISK_EMPLOYMENT = `## Industry add-on: employment / work contract
- Probation period within local statutory cap (EE: 4 mo TLS § 6; FI: 6 mo
  TSL 1:4; DE: 6 mo § 622 IV BGB).
- Notice periods symmetry — flag asymmetric notice favouring the employer.
- Working time, overtime compensation, on-call obligations.
- Non-compete: enforceability requires (i) legitimate interest, (ii) limited
  scope/duration/geography, (iii) compensation for the restraint period in
  many jurisdictions (DE § 74 HGB, FI TSL 3:5, EE TLS § 23–27).
- IP assignment: scope of work-for-hire, inventions made off-duty,
  background IP.
- Confidentiality + post-employment confidentiality.
- Termination grounds, severance, gardening leave.
- Mandatory-law floor: cannot contract below local minimum standards.
`;

const RISK_MA = `## Industry add-on: M&A — SPA / APA
- Reps & warranties: scope, qualifications (knowledge, materiality),
  bring-down at closing.
- Disclosure schedule: omissions vs general disclosure.
- Indemnity: cap, basket / de minimis, survival period, exclusive remedy.
- W&I insurance: who pays, retention, knowledge scrape.
- MAC / MAE clauses: definition, carve-outs (industry-wide, pandemic, etc.).
- Conditions precedent: regulatory approvals, financing, third-party
  consents, key-employee retention.
- Earn-out: metrics, audit rights, anti-manipulation covenant.
- Restrictive covenants on the seller (non-compete, non-solicit).
- Tax indemnity & ordinary-course tax conduct.
`;

const RISK_REAL_ESTATE = `## Industry add-on: real estate — lease / sale
- Rent indexation: CPI vs fixed step-ups vs market review.
- Term + renewal mechanism; tacit prolongation default.
- Repair & maintenance split (structural vs interior, capex vs opex).
- Insurance: who insures the structure, contents, business interruption.
- Subletting & assignment rights; landlord consent standard.
- Termination for cause, force majeure, destruction of premises.
- Security deposit / bank guarantee; return conditions.
- Permitted use, change-of-use consent.
- Compliance with local zoning / building-permit obligations.
- For sale: representations on title, encumbrances, environmental, zoning;
  apportionments at closing.
`;

/** Returns the risk-categorisation framework the analysis must follow. */
export function buildRiskTaxonomy(options?: { industry?: string }): string {
  const parts: string[] = ["# RISK TAXONOMY", RISK_BASE];

  const raw = options?.industry;
  if (raw === undefined || raw === null) {
    return parts.join("\n") + "\n";
  }
  const ind = raw.trim().toLowerCase();
  if (ind.length === 0) {
    return parts.join("\n") + "\n";
  }

  switch (ind) {
    case "dealer":
    case "distribution":
    case "agency":
      parts.push(RISK_DEALER);
      break;
    case "saas":
    case "software":
      parts.push(RISK_SAAS);
      break;
    case "nda":
    case "confidentiality":
      parts.push(RISK_NDA);
      break;
    case "employment":
    case "employee":
    case "work":
      parts.push(RISK_EMPLOYMENT);
      break;
    case "m&a":
    case "ma":
    case "spa":
    case "apa":
      parts.push(RISK_MA);
      break;
    case "real_estate":
    case "realestate":
    case "lease":
    case "property":
      parts.push(RISK_REAL_ESTATE);
      break;
    default:
      // Unknown industry tag — keep base taxonomy only, do not error.
      break;
  }
  return parts.join("\n") + "\n";
}
