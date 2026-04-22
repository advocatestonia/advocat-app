# DPA signing checklist — step-by-step for the owner

**Total time estimate:** 1-2 hours of clicking through dashboards.
**Cost:** €0 (all standard data-processing agreements are free with paid plans).
**Who signs:** Sulga on behalf of Vorantis OÜ.

Under GDPR Art. 28, we (controller) must have a written DPA with every sub-processor (processor) that handles personal data on our behalf. The ones below are the six we actually use in production.

---

## 1. Anthropic (Claude API)

**What they process for us:** User chat messages, case context, document text.

**Procedure:**
1. Log into https://console.anthropic.com.
2. Go to Settings → Organization → Legal.
3. If there is no DPA listed yet, email `privacy@anthropic.com`:
   > Subject: DPA request — Vorantis OÜ
   > 
   > Hi Anthropic team,
   > 
   > We are a controller based in Estonia using Claude API in production. Please provide the standard Data Processing Addendum for commercial API use. Our organisation: Vorantis OÜ, reg 17098992, support@advocat.ee.
4. They send back a PDF. Sign via DocuSign or similar. Store signed copy in Vorantis shared drive under `legal/dpa/anthropic_dpa_YYYYMMDD.pdf`.
5. Anthropic's standard terms also reference their sub-processor list at https://www.anthropic.com/legal/subprocessors — link to it in our Privacy Policy §3.

**Estimated time:** 10 minutes + 1-3 business days for their reply.

---

## 2. Google Cloud (Cloud TTS / Chirp3-HD / Gemini TTS)

**What they process for us:** Text sent to the TTS API for voice synthesis. No audio is stored.

**Procedure:**
1. Log into https://console.cloud.google.com.
2. Select the Advocat project.
3. Navigate to Admin → Compliance → Data Processing and Security Terms.
4. Click "Accept" — this is Google's standard data-processing terms. GCP auto-accepts on behalf of anyone with a Billing Admin role.
5. Download PDF ("View full terms") and save to `legal/dpa/google_cloud_dpa_YYYYMMDD.pdf`.
6. EU-specific Standard Contractual Clauses are incorporated automatically for EU customers.

**Estimated time:** 5 minutes.

**Note:** If the owner set up the GCP project under a personal Gmail (not a `@advocat.ee` workspace account), the DPA is technically signed by that individual. Best practice: transfer the GCP project to a Google Workspace admin account for `support@advocat.ee` or similar before launch.

---

## 3. ElevenLabs (voice generation fallback for RU/EN/UK)

**What they process for us:** Text-to-speech requests.

**Procedure:**
1. Log into https://elevenlabs.io.
2. Go to Account → Subscription.
3. Click "Data Processing Addendum" link in the footer or under Account → Legal.
4. Fill in the two fields (company name: Vorantis OÜ, address: Tornimäe tn 5 Tallinn).
5. Click "Accept DPA" — this counterparts their side automatically.
6. Download the executed PDF, save to `legal/dpa/elevenlabs_dpa_YYYYMMDD.pdf`.

**Estimated time:** 5 minutes.

---

## 4. Supabase (database, auth, storage, edge functions)

**What they process for us:** *Everything.* User profiles, cases, documents, chat history, deadlines. This is our biggest processor.

**Procedure:**
1. Log into https://supabase.com/dashboard.
2. Go to Organization → Legal → Data Processing Agreement.
3. Fill in the form (company details + signatory name).
4. Click "Sign DPA" — Supabase auto-countersigns.
5. Download executed PDF, save to `legal/dpa/supabase_dpa_YYYYMMDD.pdf`.
6. Supabase's sub-processor list (Fly.io, AWS, Cloudflare) is at https://supabase.com/security — link in our Privacy Policy.

**Estimated time:** 5 minutes.

**Important:** Supabase hosts our project in `eu-central-1` (Frankfurt). Verify this in Project Settings → Database → Region before closed-beta launch. If it shows `us-east-1`, that is a GDPR transfer issue that must be fixed first (project migration is destructive, so better caught early).

---

## 5. Stripe (payments)

**What they process for us:** Payment card data, billing email, subscription status.

**Procedure:**
1. Log into https://dashboard.stripe.com.
2. Go to Settings → Compliance and Regulatory → Data Processing Agreement.
3. Review the pre-filled DPA (Stripe auto-fills from your account details).
4. Click "Accept DPA".
5. A copy is saved to your Stripe documents and emailed. Save a copy locally too.

**Estimated time:** 5 minutes.

**Sub-processors:** Stripe uses AWS + other processors — full list at https://stripe.com/legal/subprocessors. Link in Privacy Policy.

---

## 6. Email (SendGrid / Postmark / similar — if/when connected)

**Current status at 2026-04-21:** Advocat sends emails via the `send-email` Supabase edge function. Audit the code to confirm which provider it actually uses before signing. If it uses Supabase's built-in SMTP (no external ESP), Supabase's DPA above already covers it.

**Procedure** (if using SendGrid):
1. Log into https://app.sendgrid.com.
2. Settings → Account Details → Data Processing Agreement → Download signed PDF.
3. Save to `legal/dpa/sendgrid_dpa_YYYYMMDD.pdf`.

---

## Optional but recommended

### 7. GitHub (if you store any code that can reach user data — it shouldn't)

GitHub is a *contractual partner* for source code hosting, not a processor of end-user data. We do NOT check in secrets or user data. A DPA is not strictly required but Settings → Organization → Data Processing Agreement is available if you want one for completeness.

### 8. Sentry-lite (Agent 1-6 internal telemetry)

We ship an **opt-in** internal telemetry sink to our own Supabase table (not to an external tracker). No third-party DPA needed as long as we don't enable an external error tracker. If we later switch to Sentry / Bugsnag / Datadog, each of those needs a new DPA.

---

## After all DPAs are signed

1. Update `PRIVACY_POLICY.md` §4 "Sub-processors we use" to list each of the above with its link.
2. Commit the Privacy Policy bump as v1.1 and redeploy.
3. File all signed PDFs in a single shared drive folder for auditor readiness.
4. Set a calendar reminder for 2027-04-21: re-review each DPA annually (they sometimes change; updates do not require re-signing but we should be aware).

---

## What we are NOT signing

- **Cloudflare** — we do not CDN user data through Cloudflare directly. If we add a CDN, add this step.
- **Mixpanel / Amplitude / PostHog** — no analytics ship at launch (see wave1-3 cookie banner commit). If we add any, each needs a DPA.
- **Meta / Google Ads** — no tracking pixels. If we run paid ads later, each ad platform needs a DPA.
