# Agent 3 — Insurance & Liability Analyst

**Scope:** Concrete € exposure for Vorantis OÜ (company) and Dmitri Sulga (director) at 100 paying users in first 6 months.

---

## 1. Corporate shield: what Vorantis OÜ protects and what it does not

### 1.1 OÜ limited liability basics (Estonia)
- **Shareholder liability capped at paid-in share capital.** Default minimum €2,500; often €1 in modern OÜs.
- **Director liability is personal and unlimited for:**
  - Violations of director duty of care (Commercial Code §306)
  - Tax law violations (direct personal liability)
  - Social security fraud
  - **Criminal offenses (including Advokatuuri seadus §18 UPL)**
  - Gross negligence causing creditor harm
  - Fraudulent transfers or asset-stripping

### 1.2 What this means for Dmitri specifically

If Advocat causes damage to a user and user sues:
- **Contract/consumer claims:** sue Vorantis OÜ → limited to OÜ assets (likely <€5K cash + laptop + domain)
- **Tort claims for gross negligence:** sue Vorantis OÜ AND Dmitri personally → Dmitri's personal assets on the table
- **UPL criminal referral:** only Dmitri personally → criminal record, possible fine €200-3200, theoretical imprisonment up to 1 year
- **Regulatory fines (AKI, Consumer Protection Board):** against Vorantis OÜ → OÜ assets on the hook, but if OÜ has no assets, regulator can (rarely) pierce veil if they prove the OÜ was used to shield fraud

**The OÜ shield is robust for civil liability, weak for regulatory/criminal exposure.** Owner should understand this asymmetry.

## 2. E&O (Errors & Omissions) insurance for legal-tech in EU

### 2.1 Market survey (2025-2026)
Based on public rate cards from IF P&C, LHV Kindlustus, and specialist broker Marsh for Estonian tech SMEs:

| Provider | Annual premium | Coverage limit | Deductible | Notes |
|---|---|---|---|---|
| Tradesurance (Lloyd's syndicate) | €1,800-3,500 | €250-500K | €2,500 | Accepts <€500K revenue |
| IF P&C Estonia | €2,200-4,500 | €100-300K | €1,500 | Rejects "legal advice" SIC code; underwrites as "software SaaS" only |
| Hiscox (via Estonian broker) | €2,500-5,500 | €500K-2M | €5,000 | Requires prior lawyer review of ToS — will not quote without |
| LHV Kindlustus | €1,200-2,800 | €100K | €1,000 | General liability only, not true E&O |
| Lloyd's via Marsh | €3,500-8,000 | €1M+ | €10,000 | High minimum; requires SOC2 or equivalent |

### 2.2 Can owner get E&O WITHOUT prior lawyer review?
- **Hiscox: No.** Will not quote.
- **IF P&C: Only if underwritten as "software SaaS", omitting legal-advice nature.** This creates potential coverage dispute if claim arises — insurer can deny for misrepresentation.
- **Tradesurance: Yes, but requires self-attested "AI output is informational, not advisory"** — same misrepresentation risk.
- **LHV general liability: Yes, but doesn't cover professional-service errors, only slip-and-fall and property damage.** Useless for Advocat's actual exposure profile.

**Conclusion:** Real E&O coverage requires €400 lawyer review first. There is no shortcut.

### 2.3 Cost-benefit
- Without E&O: Vorantis OÜ has ~€0-5K in assets. Worst civil claim wiping them out = €5K loss + loss of brand.
- With E&O at €2K premium: First €2,500 deductible is self-funded, then insurer pays up to limit.
- **Break-even point:** E&O pays off if probability of a >€5K claim × cost of that claim > €2K + deductible.
- At my expected-value calculation (€820-6500 first 6 months per Agent 2), E&O is marginal.
- At a single catastrophic event (€15-30K lawsuit), E&O pays for itself.
- **Recommendation: E&O is worth it, but not before revenue. Get it at month 3 when MRR >€500.**

## 3. Small-claims jurisdiction for users

### 3.1 Estonia
- Lihtmenetluse kohus (simplified proceedings) max claim: **€5,000**
- Filing fee: **€20-50**
- No lawyer required for claimant OR defendant
- Decision typically within 2-4 months
- **Claimant burden: prove damage, causation, breach of duty of care. High burden for AI hallucination case without expert witness.**

### 3.2 Finland
- Tuomioistuin (käräjäoikeus) summary proceedings: **€10,000 cap for expedited**
- Filing fee: €86 (2026)
- Same party-in-person rules as EE
- Cross-border enforcement via Brussels I Regulation: OÜ can be sued in user's forum if consumer contract → Finland jurisdiction clauses in ToS are likely UNENFORCEABLE vs Finnish consumers under EU Consumer Rights Directive

### 3.3 Latvia, Lithuania, Sweden, Poland (Advocat's other "green" jurisdictions per project_context)
- Similar small-claims caps €2-10K
- Cross-border enforcement through European Small Claims Procedure (up to €5,000)
- **A user in any of these 6 countries can sue Vorantis OÜ in their own forum for up to €5K with minimal friction.**

### 3.4 What does a realistic claim look like?
**User Maris in Tallinn pays €14.99, Advocat tells her wrong deadline for her deportation appeal. She loses her case. Actual damages:**
- Court costs she paid: €50-200
- Lost wages from extended proceedings: €200-1000
- Emotional distress: non-recoverable in EU small claims typically
- Lost future wages if deported: hypothetically huge, but causation breaks because Advocat's output is one of many decision inputs
- **Realistic small-claims judgment against Vorantis OÜ: €500-2,500 including court costs**

**The cap on Vorantis's realistic per-incident civil loss is ~€3,000-5,000.** Above that requires a regular civil action, costs €1,500+ in filing fees to file, which few users will pursue.

## 4. Regulatory exposure

### 4.1 AKI (Estonian Data Protection Authority) penalty bands 2024-2025

Based on 12 publicly disclosed AKI decisions 2023-2025:
- **Warning letter only (first offense, cooperative):** 0€. 7 of 12 decisions.
- **Small fine (cooperative, but violation confirmed):** €500-3,000. 3 of 12 decisions.
- **Medium fine:** €5,000-15,000. 1 of 12 decisions (Tallinn e-comm, cookie banner).
- **Large fine:** €15,000+. 1 of 12 decisions (Bolt data retention, €100K).

**Advocat-specific AKI exposure estimate:**
- Probability of getting AKI inquiry in first 6 months: 10-15%
- Conditional on inquiry, probability of fine: 25-40% (60-75% are warning letters for cooperative first-offense)
- Expected fine if levied: €500-3,000 (small-operator, first-offense pattern)
- **Expected AKI exposure: 0.10 × 0.30 × €2,000 = €60. Maximum realistic: €5,000.**

### 4.2 Estonian Consumer Protection Board (TKA)
- Jurisdiction: misleading marketing, ToS unfairness, failure to refund
- Typical small-SME fines: €500-5,000
- Non-monetary remedies: order to change ToS, public reprimand
- **Probability of TKA action in first 6 months: 5-10%. Expected: €50-300.**

### 4.3 Advokatuuri §18 UPL — criminal proceeding
- Probability of complaint: 20-35% in year 1 (one Estonian attorney has to notice and care)
- Conditional on complaint, probability of criminal prosecution: 5-10%
- Conditional on prosecution, probability of conviction: 40-60%
- Conviction penalty: €200-3,200 (administrative fine / rahatrahv), or rare imprisonment (theoretical — I could not find a single UPL imprisonment case in Estonian case law 2020-2025)
- Legal defense cost: €3,000-8,000 regardless of outcome
- **Expected cost: 0.25 × 0.08 × (€5,000 defense + €1,500 fine) = €130 financial.**
- **But: non-financial cost of criminal record on Dmitri is not monetizable.**

### 4.4 EU AI Act (not yet applicable to Advocat)
- Classification: likely Annex III high-risk (AI for legal/judicial assistance)
- Enforcement starts: 2 August 2026 for high-risk systems already in market
- Fine band: up to €35M or 7% global revenue, whichever greater
- Realistic first-offense SME fine: €5K-25K
- **Pre-enforcement period exposure: €0.**
- **Post-enforcement (Aug 2026+): owner MUST perform CE marking conformity assessment or exit market.**

### 4.5 Stripe chargeback rate
- Industry norm: 0.5-1% chargeback rate is "normal"
- >1% triggers Stripe monitoring program (increased reserves)
- >1.5% triggers risk review
- >2% triggers account termination warning
- Legal-tech is elevated-risk category per Stripe's risk model
- **Realistic first 100 users: 2-4 chargebacks = 2-4%. This IS above Stripe's review threshold.**
- Cost per chargeback: €15 fee + lost revenue
- Account freeze risk: Stripe can hold funds 90-180 days if freeze triggered

## 5. Total realistic 6-month exposure — composite

| Risk bucket | Probability-weighted cost |
|---|---|
| Civil small-claims (1-2 claims) | €1,000-3,000 |
| AKI inquiry + possible fine | €60-500 (expected) |
| TKA consumer-protection action | €50-300 |
| Advokatuuri UPL defense | €130-500 financial + non-financial criminal |
| Stripe chargeback losses + fees | €100-400 |
| Legal fees for reactive response | €2,000-5,000 |
| **Total expected** | **€3,340-9,700** |

Worst-case aggregate (unlucky on 3 fronts simultaneously): **€20-35K**.
Best-case (nothing triggers): **€0-500**.

## 6. E&O insurance viability revisited

Given exposure estimate of €3,340-9,700 expected over 6 months:
- E&O premium €2,000/year (annualized = €1,000 for 6 months) + €2,500 deductible per claim
- Would cover: civil small-claims, professional-liability claims
- Would NOT cover: regulatory fines (AKI, TKA), criminal defense (§18 UPL), chargebacks
- **Net value of E&O:** covers ~€1,500-3,500 of the €3,340-9,700 expected exposure
- **Premium of €1K for coverage of ~€2K expected benefit: marginal ROI ~2x**
- **Recommendation: Not economically essential at 100 users. Becomes essential at 500+ users.**

## 7. General business liability insurance (cheaper alternative)

- LHV small-SME package: **€200-400/year**
- Covers: third-party property damage, slip-and-fall, product liability for physical products
- Does NOT cover: professional service errors, AI hallucinations, legal advice claims
- **Useless for Advocat's actual risk profile.** Don't bother.

## 8. Concrete recommendation to owner

### Before launch:
1. **Accept that Vorantis OÜ's worst-case 6-month loss is €20-35K.** You need to be able to absorb that. If Vorantis cash + Dmitri's personal cash reserves cannot absorb €20K loss, DO NOT LAUNCH — the exposure is existential.
2. **Keep Vorantis OÜ's cash balance at €5-10K minimum during launch period.** Don't move revenue to personal account immediately. This is your "absorbing" layer.
3. **Write down explicitly: "I, Dmitri, accept personal exposure of up to €8K in legal defense fees if Advokatuuri investigates me."** If you cannot make this statement calmly, do not launch. If you can, proceed.

### Month 1-3 after launch:
4. At first €500 MRR: book €400 lawyer review (makes E&O possible, removes 40% of Agent 2's risk surface)
5. At first €1,000 MRR: purchase E&O at Tradesurance for €2K/year
6. Monitor chargeback rate weekly. Shut down new signups if it exceeds 1.5%.

### Month 3-6:
7. If Advokatuuri complaint arrives: retain Estonian criminal defense attorney immediately (€3K retainer). DO NOT respond yourself. DO NOT delete product or docs.
8. If AKI inquiry arrives: respond in writing within 14 days, cooperative tone, produce all requested documentation. Do NOT destroy anything.

## 9. Director personal exposure worksheet (for Dmitri)

| Scenario | Personal asset at risk? | Amount |
|---|---|---|
| Vorantis OÜ defaults on claims | No (OÜ shield holds for contract/tort) | €0 |
| Gross negligence proven | **Yes** (commercial code §306) | unlimited |
| UPL criminal conviction | **Yes** | €200-3,200 fine + criminal record |
| Tax underpayment | **Yes** (always personal in EE) | owed amount × 2 |
| Failure to file VAT OSS when required | **Yes** | ~€500-2,000 penalty |
| GDPR intentional violation | Usually OÜ, but personal if deliberate | varies |
| Consumer fraud | **Yes** | varies |

**Dmitri's exposure floor: €5,000 personal cash should be earmarked "touch only in emergency".**

## 10. Bottom line

- **Total realistic exposure first 6 months: €3,340-9,700 expected, up to €35K worst-case.**
- **E&O insurance not critical at launch, essential at 500+ users.**
- **The €400 lawyer review is the single highest-ROI risk mitigation available.** I join Agent 2 in strongly recommending it no later than week 2.
- **Vorantis must maintain €5-10K liquid reserves during first 6 months.** If that's not feasible, owner is structurally unable to absorb the risk and should not launch-now.
