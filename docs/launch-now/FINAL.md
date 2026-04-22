# OMEGA-LAUNCH-NOW — Final Verdict

**Session:** 2026-04-21
**Question owner asked:** *"Can I launch TO PAYING USERS this week, without closed beta, without prior lawyer review? I need money."*
**Consilium:** 7 agents, 3 rounds debate
**Consensus:** MIDDLE-GROUND M1 (6/7 agents), minority LAUNCH-NOW-CONDITIONS (1/7)

---

# TL;DR — Direct answer to owner

## YES, you can launch this week. With conditions.

But **not pure launch-now at €14.99 with no branding adjustments.** The consilium unanimously recommends **"Founder's Beta" soft launch (Option M1)**:

- Accept payments within **72 hours** of today
- Price **€9.99 first month, €14.99 after** (auto-escalation in Stripe)
- **"Founder's Beta v1.0"** badge visible in UI + Dmitri's personal sign-off on landing
- **Hard cap 25 paying users** first 30 days (hardcoded counter; close signup when hit)
- **Unconditional 30-day refund** explicit on checkout
- **Kill the €29.99 premium tier** for launch month (raises UPL risk vs benefit)
- **First-session modal** "I understand Advocat is not legal advice" with timestamped consent in Supabase

**If you accept this: first paid user by 2026-04-24.**

---

## The "no" part you need to hear

**There are 3 hard gates. If any fails, you cannot launch even M1 safely.**

### Gate 1 — Corpus integrity check (CRITICAL)

Prompt mentions: *"AI hallucination (LEGAL audit нашёл 60-80% EE corpus broken bodies)"*.

**If this figure is real and current:** selling Advocat to Estonian immigrants is not "risky launch". It is negligent — knowingly deploying a product that gives wrong § citations most of the time. Criminal UPL exposure rises sharply because "gross negligence" becomes arguable. Every agent flips to DELAY on this fact alone.

**Action required before any launch step:** 
- Owner must verify the 60-80% figure
- If it reflects a prior audit that has since been fixed → green light, proceed
- If still accurate → **DO NOT LAUNCH.** Fix corpus first. This is non-negotiable.
- If unverifiable → precautionary delay, run a sampling test (20 EE § citations from Advocat outputs vs Riigi Teataja source — if >10% wrong, delay)

### Gate 2 — Sofia's written consent

You have a co-founder. She is on the line for Vorantis OÜ liability. Agent 2 raised this in round 2 and the consilium agreed: **this is not a solo call**.

**Action required:** Before first paying user, Sofia must explicitly acknowledge in writing (email to herself + Dmitri, or signed document):
- "I consent to Vorantis OÜ launching paid subscriptions at v1.0 level of compliance"
- "I understand expected tail risk is €5-10K and worst-case tail risk is €20-35K"
- "I understand Dmitri has personal exposure to Advokatuuri §18 UPL criminal proceeding (low probability)"

Without this, launch-now is not authorized under Estonian commercial code director-duty-of-care standards. You are both liable if she later disputes the decision.

### Gate 3 — €5K reserves

Agent 5 precedent analysis: the single determining factor in "survived enforcement" vs "died from enforcement" for EU legal-tech startups is **cash reserves for defense**. AvoChat died because founders had €0 defense budget. Lexi, JurGPT, DoNotPay all survived because they could absorb €10-20K defense costs.

**Action required:** Identify €5,000 of liquid reserves (Vorantis OÜ bank balance OR Dmitri's personal available cash) that is labeled "defense fund — do not spend". This is insurance, not budget.

**If you cannot produce €5K of reserves:** you have the AvoChat profile. Launch-now is not survivable in a bad outcome. In that specific case, **delay 4 weeks**, earn €400-800 of contract work, build the reserve, then launch.

---

# Why the consilium did not say "pure launch-now"

Your instinct to launch to paying customers immediately was empirically supported (14 of 18 reviewed EU/US legal-tech startups launched without perfect compliance and survived). But 4 of 18 had enforcement actions within 8 months on average. The cost of first enforcement for the 4 was €15-35K direct + indirect.

The Middle-Ground M1 reduces the risk surface by ~40% at the cost of 4-6 hours of additional implementation work and ~10-15% lower short-term revenue. That trade-off is clearly positive.

**Pure launch-now is NOT wrong. M1 is just strictly better.**

# Why the consilium did not say "delay 4 weeks"

Your financial constraint is legitimate. Agent 6 confirms: 4-week delay costs €400-800 in runtime with zero revenue offset. Precedent says €5K defense reserves + fast cooperative response = survive enforcement. Perfect compliance pre-launch is not necessary; adequate compliance is.

Agent 4 confirms Advocat is at ~85% of MUST-HAVE compliance. That threshold is safe to launch at small scale (<100 users).

**A 4-week delay would be overkill. Owner was right to resist it.**

---

# Your Anthropic analogy — verdict

Owner said: *"Юрист проверять AI — это бред. AI решает мои проблемы по Финляндии. Если что-то пойдёт не так, я же не иду писать претензии в Anthropic."*

**Verdict: 70% right, 30% wrong. You need to understand the 30% to operate safely.**

### You ARE right that:
- When you use Advocat for your own Sulga case, Anthropic-ish disclaimers are the correct legal posture
- A standard "this is AI, not legal advice" disclaimer is enforceable under EU law for informational services
- Courts and regulators do NOT generally hold AI wrappers to the same standard as licensed attorneys

### You are WRONG that this transfers to selling:
- When you SELL Advocat for €14.99/mo to someone, you are a reseller, not a user
- EU Product Liability Directive 85/374/EEC (amended 2024 for AI/software) explicitly places liability on the person who **places the product on the market**, not the component supplier
- Consumer Rights Directive 2011/83/EU imposes duties of accuracy and fitness for purpose on the seller, even for "informational services"
- This is the farmer/salmonella analogy from your own prompt: the farmer who sells chicken cannot escape foodborne-illness liability by pointing to the hatchery

**The practical distinction:** when you use Advocat yourself, disclaimer protects you (the user). When someone else uses Advocat because you sold it to them, disclaimer protects you (the seller) only if the disclaimer is **conspicuous, specific, and accepted with informed consent** — which is exactly what Condition #2 in Middle-Ground M1 requires (full-screen modal + logged consent).

**Your instinct about what's "bullshit" is directionally correct. The specific safeguards are what transform instinct into legally defensible posture.**

---

# Your "100 clients pay for lawyer" math — verdict

**Verdict: directionally correct, timeline optimistic by 2-3 months.**

Agent 6 ran the real numbers:
- 100 signups ≠ 100 paying. Realistic month 1 paying: 6-14 users = €45-210 MRR
- Realistic cumulative revenue, first 6 months: €1,400-3,500
- Realistic net after runtime costs: €130-2,800

**You CAN fund a €400 lawyer review from revenue by month 2-3. That is true.**

**You CANNOT fund €2,000 E&O insurance from revenue until month 5-6.**

**You CANNOT fund a €5K enforcement defense from revenue at all — you need separate reserves.**

So your argument "launch → revenue → pay lawyer" works for the €400 review on 2-3 month timeline. Not immediately. And it does NOT replace the need for €5K reserves.

---

# Concrete action plan — 30 days

## Day 0 (today, 2026-04-21) — Gates

- [ ] **GATE 1**: Verify corpus. Pull 20 random EE § citations from recent Advocat outputs, compare to Riigi Teataja. Document error rate. **Halt everything if >10% wrong.**
- [ ] **GATE 2**: Send email to Sofia describing consent requirement. Wait for her written acknowledgment.
- [ ] **GATE 3**: Confirm €5K liquid reserves identified (Vorantis bank + personal as backstop).

**If any gate red → stop here. Fix first. Re-evaluate.**

## Day 1-2 (2026-04-22 to 04-23) — Deploy

- [ ] Execute launch/FINAL.md Phase A-D (Flutter deploy, Supabase migration, edge function deploy, smoke test).
- [ ] Verify Agent 4 Section 2 compliance items:
  - [ ] Art. 22 automated-decision-making disclosure in Privacy Policy
  - [ ] Age ≥18 in ToS
  - [ ] Withdrawal-right waiver in Stripe checkout
- [ ] Implement first-session "I understand" modal with consent logging.
- [ ] Add Founder's Beta badge to UI.
- [ ] Configure Stripe: €9.99 first-month intro pricing, €14.99 standard after.
- [ ] Hardcode 25-user cap on signup (close when reached).
- [ ] Kill €29.99 premium tier in Stripe for launch month.
- [ ] Write and publish Dmitri's personal sign-off on landing page.
- [ ] Enable telemetry sink (wave1-6 commit `b8af413`).

## Day 3-4 (2026-04-24 to 04-25) — First Paid User

- [ ] Open signup to first external user (ideally Sulga network — community member who trusts Dmitri personally)
- [ ] Monitor telemetry for errors
- [ ] Run `./test/e2e/prod_smoke.sh` at launch + 6h + 24h
- [ ] Monitor support@advocat.ee inbox every 2 hours
- [ ] Watch Claude API costs (if burn rate >€150/mo, investigate)

## Day 5-7 — DPAs

- [ ] Sign all 5 DPAs per launch/FINAL.md Phase E (60-90 min)
- [ ] File in `legal/dpa/` folder
- [ ] Draft Records of Processing Activities one-pager (Art. 30 GDPR)

## Week 2 — Lawyer and Partner Outreach

- [ ] Book €400 1-hour lawyer review (Walless, Triniti, or Hedman per launch/FINAL.md)
- [ ] Email 3 small Estonian attorneys about partnership (M4 aspirational)
- [ ] Apply lawyer's tracked changes when received

## Week 3 — Scale-up decision

- [ ] Review first 2 weeks of telemetry
- [ ] Review user feedback / complaints
- [ ] Decide: lift 25-user cap? Switch badge from "Founder's Beta" to "v1.0"?
- [ ] If all green: open signup to 50 users, keep Founder's Beta branding
- [ ] If issues: freeze signup, fix issues first

## Week 4 — Full public launch posture

- [ ] If still all green: 100-user cap lifted, standard €14.99 pricing, drop "Founder's Beta" badge
- [ ] Introduce €29.99 premium tier IF demand exists
- [ ] VAT OSS registration if approaching €10K annualized revenue

---

# Kill-switch criteria (halt new signups within 24h if triggered)

- Claude API costs exceed revenue for 2 consecutive weeks
- Chargeback rate >1.5% of transactions
- First AKI inquiry letter received
- First Advokatuuri UPL complaint notice received
- Any paying user reports actual legal harm (missed deadline, adverse ruling) — even if Advocat's output was not the proximate cause, pause and investigate
- Stripe risk review flag triggered
- Telemetry shows >3% of AI outputs producing user-visible errors

---

# Risk acknowledgment

Owner, you are taking the following risks by launching M1 this week:

1. **Expected 6-month financial exposure: €3,340-9,700.** (Agent 3 composite)
2. **Worst-case 6-month financial exposure: €20-35K.** (Agent 3 stacked scenarios)
3. **Non-zero Advokatuuri §18 criminal exposure on you personally.** Not monetizable. Low probability (~1-2% in year 1) but real.
4. **Sofia is exposed alongside you.** Ensure her consent is on the record.
5. **Your Sulga case data should NOT be in production Advocat.** Use a separate local instance. This avoids evidence-chain contamination and protects you if production is ever breached or subpoenaed.

**You must agree to these risks knowingly, not stumble into them.**

---

# Timeline — realistic, not optimistic

| Date | Milestone |
|---|---|
| 2026-04-21 (today) | Gates check |
| 2026-04-22/23 | Deploy M1 |
| 2026-04-24 | First paid user |
| 2026-04-25 | DPAs signed |
| 2026-05-05 | Lawyer review applied |
| 2026-05-15 | 25-user cap re-evaluated |
| 2026-06-01 | ~10-15 paying users, MRR €150-225 |
| 2026-07-21 | ~25-35 paying users, MRR €375-525 |
| 2026-10-21 | ~60-80 paying users, MRR €900-1200 (IF no enforcement event) |
| 2026-08-02 | **EU AI Act enforcement begins — CE marking / conformity assessment plan MUST be in place** |

Honest forecast: **break-even on runtime cost at month 4-5.** Cash reserves can drop until then. If owner can absorb 3-5 months of €100-200 monthly burn, this works.

---

# What happens if you ignore the consilium and launch pure LAUNCH-NOW anyway

Your risk surface increases from M1's ~€3-10K expected to ~€5-15K expected. Probability of enforcement action in year 1 rises from ~20% to ~30%. Cash runway requirement goes from €5K reserves to €8-10K reserves.

**It is still survivable. You are a competent founder. But it is strictly worse than M1, at zero savings.**

Do not do pure launch-now unless you have a specific reason to reject the Founder's Beta framing. I do not see such a reason in your stated constraints.

---

# What to remember from this session

1. **Your instinct to launch was correct.** Agencies and lawyers who say "first, spend €5K on compliance" are wrong at your scale. They're selling services, not giving advice.

2. **Your Anthropic analogy was 70% correct.** You're not crazy. The remaining 30% is what the 4-6 hours of M1 work addresses.

3. **The enemy of "your startup dies from compliance paralysis" is "your startup dies from enforcement because you had no defense budget."** Both are real. The balance point is M1 + €5K reserves.

4. **€400 lawyer review at week 2-3 is not "agency bullshit". It is the single highest-ROI action available to you. Do not skip it.**

5. **The corpus integrity question is the one thing that can unilaterally stop this plan.** Verify it today. If broken, fix before anything else.

6. **Sofia is a co-founder, not a spouse who'll nod along.** Her consent is a legal requirement, not a formality.

---

# Files in this consilium

1. `/Users/ai.place/Advocat/app/advocat_project/docs/launch-now/01-pro-launch-now.md`
2. `/Users/ai.place/Advocat/app/advocat_project/docs/launch-now/02-contra-launch-now.md`
3. `/Users/ai.place/Advocat/app/advocat_project/docs/launch-now/03-liability-numbers.md`
4. `/Users/ai.place/Advocat/app/advocat_project/docs/launch-now/04-minimum-viable-compliance.md`
5. `/Users/ai.place/Advocat/app/advocat_project/docs/launch-now/05-precedents.md`
6. `/Users/ai.place/Advocat/app/advocat_project/docs/launch-now/06-revenue-math.md`
7. `/Users/ai.place/Advocat/app/advocat_project/docs/launch-now/07-middle-ground.md`
8. `/Users/ai.place/Advocat/app/advocat_project/docs/launch-now/08-debate.md`
9. `/Users/ai.place/Advocat/app/advocat_project/docs/launch-now/FINAL.md` (this file)

Related:
- `docs/launch/FINAL.md` (technical readiness, 80/100 score)
- `docs/launch/dpa-signing-steps.md` (Phase E clicks)
- `docs/launch/legal-review-checklist.md` (what to send the €400 lawyer)
- `docs/launch/incident-playbook.md` (first-24h monitoring runbook)

---

## One-line answer

**YES — launch this week with "Founder's Beta" branding (Option M1), €9.99 intro price, 25-user cap, after verifying corpus integrity, securing Sofia's written consent, and confirming €5K defense reserves. First paid user within 72 hours. Full public launch posture in 4 weeks.**

**Pure launch-now without M1 branding is not forbidden but strictly inferior at zero savings.**
