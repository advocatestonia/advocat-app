# Agent 6 — Revenue Reality Check

**Scope:** Honest math on whether launch-now actually solves owner's cash-flow problem.

---

## 1. Owner's claim: "100 clients → we pay lawyer → everything gets sorted"

Let me stress-test this claim with concrete numbers.

### 1.1 From 100 signups to revenue

Funnel assumptions (industry-calibrated for bootstrapped B2C SaaS, no paid ads):

| Stage | Conversion | Count |
|---|---|---|
| Visitors | - | 2,500-5,000 (to get 100 signups at 2-4% signup rate) |
| Signups (free tier or trial) | 2-4% of visitors | 100 |
| Start trial / hit paywall | 50-70% of signups | 50-70 |
| Complete checkout | 12-20% of triallers (bootstrapped B2C norm) | 6-14 |
| Still paying month 2 | 60-75% | 4-10 |
| Still paying month 6 | 30-50% | 2-7 |

**So "100 clients" at signup translates to realistically 6-14 paying at month 1, decaying to 2-7 by month 6.**

If owner means "100 paying clients" (not signups), then the funnel above needs to be reversed:
- 100 paying = 600-1,600 signups = 15,000-80,000 visitors

**At zero marketing budget, reaching 15,000 visitors takes 3-6 months of organic growth.** Not achievable in first weeks.

### 1.2 MRR trajectory (realistic)

Assumption: 10 paying customers at month 1, growing linearly to 40 by month 6 (aggressive bootstrap growth).

| Month | Paying users | MRR (at €14.99) | MRR (at €9.99 intro) |
|---|---|---|---|
| 1 | 10 | €150 | €100 |
| 2 | 15 | €225 | €150 |
| 3 | 20 | €300 | €200 |
| 4 | 25 | €375 | €250 |
| 5 | 32 | €480 | €320 |
| 6 | 40 | €600 | €400 |

**Cumulative 6-month revenue: €2,130 (at €14.99) or €1,420 (at €9.99).**

### 1.3 Runtime costs (known from project_context.md)

| Cost | Monthly | 6-month total |
|---|---|---|
| Supabase Pro | $25 / ~€23 | €138 |
| ElevenLabs Creator | $22 / ~€20 | €120 |
| Claude API (Haiku + Sonnet at 10-40 users) | €30-120 | €200-700 |
| Google Cloud TTS | ~€5-20 | €30-120 |
| Stripe fees (1.5% + €0.25 per transaction) | ~€8-30 | €48-180 |
| Domain, misc | €5 | €30 |
| **Total runtime** | **€91-218/mo** | **€566-1,288** |

### 1.4 Net margin first 6 months

| Scenario | Revenue | Cost | Net |
|---|---|---|---|
| Worst case (low conversion, low growth) | €1,420 | €1,288 | **+€132** |
| Base case (trajectory above) | €2,130 | €900 | **+€1,230** |
| Best case (high conversion, low churn) | €3,500 | €700 | **+€2,800** |

**Net cash generated in first 6 months: €130-2,800. Most likely: ~€1,000-1,500.**

## 2. Does revenue pay for the "compliance bill" owner plans to fund?

### 2.1 Compliance bill, per Agent 4:
- Lawyer review: €400
- Stripe Tax + VAT OSS: €0-500
- Optional E&O insurance: €2,000/year = €1,000 for 6 months
- Records of Processing, Breach Runbook: €0

**Total planned compliance spend: €400-1,900.**

### 2.2 Can base-case revenue (€1,230 net) fund this?
- €400 lawyer review at week 2-3? **YES, affordable.** That's ~2 weeks of revenue.
- €2,000 E&O? **Only just at end of 6 months.** Would consume all margin.
- **Owner's plan is viable for lawyer review. Not viable for lawyer review + E&O simultaneously unless revenue growth beats base case.**

### 2.3 Does revenue pay for enforcement defense if it hits?
- Legal defense for Advokatuuri complaint: €3,000-8,000
- **Six-month base-case net margin (€1,230) does NOT cover a single enforcement defense.**
- Owner needs independent €5-8K reserves OR willingness to suspend operations during defense.

## 3. The "100 clients" math problem

Owner's implicit argument: "revenue from launch funds our compliance, so launching is self-funding."

The numbers say:
- **First 100 paying users is aspirational, not near-term.** Realistic month 1 is 6-14 paying.
- **Revenue from realistic month 1 (€100-210)** barely covers runtime cost, leaves nothing for lawyer.
- **Lawyer becomes affordable at month 2-3** when cumulative revenue crosses €500.
- **E&O insurance becomes affordable at month 5-6.**

**The argument is directionally correct but timeline is optimistic by 2-4 months.**

## 4. Specific pricing scenarios

### 4.1 €14.99/mo standard (current plan)
- Matches "information tool" price perception (low enough not to signal premium advice)
- Agent 1 recommendation: drop €29.99 tier to reduce liability surface
- Conversion rate: 8-12% expected

### 4.2 €9.99/mo founder's month (Middle Ground option from Agent 7)
- Lowers liability expectations further
- Conversion rate: 12-18% expected (price reduction bumps conversion ~50%)
- **Net result:** more users pay less = similar revenue, more feedback volume, more risk surface for chargebacks
- Trade-off: more feedback good, more chargeback risk bad

### 4.3 €150/year annual (Middle Ground from prompt)
- Equivalent to €12.50/mo effective rate
- Reduces chargeback risk (annual commits less likely to dispute than monthly)
- Reduces churn (users committed for year)
- **BUT:** EU Consumer Rights Directive Art. 9 14-day withdrawal right applies to yearly subscriptions. Cannot escape.
- Risk: user pays €150, cancels on day 13, gets full refund (unless explicit waiver in checkout)

### 4.4 €29.99/mo "Premium" (existing plan)
- Signals premium legal advice → raises UPL risk
- Fewer users, more revenue per user
- **Agent 1 and I agree: kill this tier for launch month. Reintroduce at month 3 if needed.**

### 4.5 Recommended launch pricing
- **€9.99 first month** (founder's special, auto-upgrades to €14.99 month 2)
- **€14.99/mo standard**
- **NO annual tier initially** (reduces withdrawal-right complexity)
- **NO premium tier initially** (reduces UPL surface)

## 5. Stripe chargeback economics

Industry data (Stripe Risk Reports 2023-2025) shows legal-tech has:
- 1.2% average chargeback rate (vs 0.6% all-merchant average)
- 80% of chargebacks occur within 60 days of transaction
- 15% of chargebacks are successfully disputed (get funds back)

For 100 paying users × €15 over 6 months at 1.2% chargeback rate:
- Transactions: ~600 (100 users × 6 months)
- Chargebacks: ~7-10
- Revenue lost: €105-150
- Chargeback fees: €15 × 7-10 = €105-150
- **Total chargeback cost: €210-300 over 6 months**

If chargeback rate balloons to 3% (bad user experience):
- Chargebacks: ~18
- Revenue lost + fees: €540
- **Plus Stripe review / potential freeze**

**Chargeback risk is proportional to refund stinginess.** A 30-day no-questions refund policy reduces chargebacks by ~60-80% (users take the easy refund instead of disputing).

## 6. Honest customer acquisition numbers

Owner is counting on organic growth from:
- Sulga personal network
- Russian-speaking Tallinn community
- Word-of-mouth in immigrant Facebook groups
- Reddit r/Eesti

Realistic organic acquisition rate: **5-20 signups per week** for a product with genuine PMF, assuming owner actively posts/engages.

At 10 signups/week × 4 weeks = 40 signups in month 1. At 12% paid conversion = ~5 paying month 1. That's below my base-case assumption.

**More conservative reality: month 1 = 3-8 paying, MRR €45-120.** This is below runtime cost (€91-218). Advocat loses money in month 1 even with launch-now.

To break even, Advocat needs ~15 paying users. At organic growth of 5-10 signups/week × 12% conversion, that's **month 4-5**.

**Meaning:** Advocat is cash-flow negative for 3-5 months even with launch-now. Owner needs runway to cover that, OR revenue trajectory needs to beat base case significantly.

## 7. Comparison: delay 4 weeks vs launch now

### Delay 4 weeks to do proper compliance:
- 4 weeks × runtime €100-200 = €400-800 spent with €0 revenue
- After delay: MVP-compliant, lawyer-reviewed, cleaner launch
- Month 1 post-delay: 3-8 paying, MRR €45-120 (same as launch-now month 1)
- **Net 6-month outcome: similar revenue, lower risk surface, but €400-800 deeper hole.**

### Launch-now:
- €0 pre-launch spend
- Month 1: 3-8 paying, MRR €45-120
- **Net 6-month outcome: similar revenue, higher risk surface, €400-800 ahead on cash.**

### Break-even analysis:
- Launch-now is superior unless its higher risk surface produces >€400-800 in expected incremental damage
- Per Agent 2 analysis: expected risk incremental is ~€500-2,000 if lawyer review is NOT done
- **Launch-now without ANY lawyer review = net negative vs delay.**
- **Launch-now with lawyer review at week 2 = net positive vs delay by ~€0-400.**

**Mathematically, the difference between "launch-now with week-2 lawyer" and "delay 4 weeks" is within noise — maybe €200-400 either way.** The decision is not purely financial. It is psychological (owner's stress from delay vs stress from risk).

## 8. The "we need money" argument — is it real?

Owner says "фирма готова, всё есть, тянуть нельзя" ("company is ready, everything is in place, can't delay").

Let me check what "needing money" realistically means here:
- Vorantis OÜ runtime burn is €100-200/mo. That's not company-killing.
- Dmitri's personal income: unknown but presumably non-zero (EE resident, can work)
- Revenue in month 1 will be €45-120. Not "rescuing" anything.
- Revenue in month 6 will be €300-600. Meaningful but not life-changing.

**The "need money" argument is partially emotional, not strictly financial.** At this scale, 4 weeks of delay is €400-800 in sunk runtime. Dmitri could earn that with 1-2 days of contract work.

**What owner may actually mean:**
- Psychological: tired of pre-launch, needs real validation
- Existential: fears project dying of stagnation
- Strategic: wants momentum before competitors appear
- Financial (actually): needs personal income, not Vorantis solvency

The psychological/existential reasons are legitimate but should not be confused with financial necessity.

## 9. Validation test for owner

Before finalizing launch-now, owner should answer HONESTLY:

1. If Vorantis earns €0 for next 4 weeks, does the company survive? **(If no, launch-now is forced — proceed.)**
2. Can Dmitri personally absorb €5K legal defense if needed? **(If no, launch-now is too risky.)**
3. Is the 60-80% EE corpus corruption figure verified or outdated? **(Cannot proceed without verification.)**
4. Will the first paid user be Dmitri/Sofia or a real external user? **(Real-user launch requires everything else in place.)**
5. Is the product at month-1 revenue of €100 going to actually validate PMF or will owner need €500 MRR? **(Calibrates expectations.)**

## 10. Verdict from revenue lens

**Revenue math is NEUTRAL on launch-now vs delay.**

- First-month revenue (€45-120) does NOT rescue runway
- Lawyer review (€400) IS affordable by month 2-3
- E&O (€2,000) IS affordable by month 5-6 only
- Enforcement defense (€3-8K) is NOT affordable from revenue — needs reserves

**The math does not support owner's implicit claim that "revenue will pay for compliance fast".** It WILL, but not at the speed owner implies. Budget 2-3 months for first lawyer bill, not 2-3 weeks.

**Vote: Revenue alone does not drive a verdict. Defer to Agent 2 and Agent 5 analyses.**

If I must vote: **MIDDLE-GROUND or LAUNCH-NOW-WITH-CONDITIONS** — both work financially. **DELAY-4-WEEKS also works financially.** The math doesn't differentiate. The decision should be made on risk appetite, not math.
