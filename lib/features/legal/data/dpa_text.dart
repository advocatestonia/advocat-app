// GDPR Article 28 — Data Processing Agreement (DPA) text, v1.0
// -----------------------------------------------------------------------------
// This file is intentionally kept as a single Dart constant rather than an
// asset so the legal text ships in the same code-signed binary as the
// clickwrap UI. Updating the text MUST be a coordinated change:
//
//   1. Bump `kCurrentDpaVersion` (date-suffixed semver).
//   2. Update the body in `kDpaTextEnV1`.
//   3. Update the `CURRENT_DPA_VERSION` constant in
//      `supabase/functions/create-checkout/index.ts`.
//   4. Ship the migration that records new acceptances — old acceptances
//      remain valid for users on the old version until they next upgrade.
//
// English is the binding legal version. UI chrome (dialog title, buttons)
// is localised; the contract body itself is not — see CLAUDE.md.
// -----------------------------------------------------------------------------

/// Current DPA version string. Update on every material change to the body.
/// Format: `vMAJOR.MINOR-YYYY-MM-DD`.
const String kCurrentDpaVersion = 'v1.0-2026-05-20';

/// The full DPA body in English. Rendered verbatim in the review screen and
/// archived in `dpa_acceptances.dpa_version` so we can prove exactly which
/// text a given customer signed.
const String kDpaTextEnV1 = r'''
DATA PROCESSING AGREEMENT

Version v1.0 — Effective 20 May 2026

This Data Processing Agreement ("DPA") forms part of, and is incorporated by reference into, the Advocat Terms of Service (the "Agreement") between the Customer (acting as Controller, the "Controller") and Vorantis OÜ, registry code 17098992, Tornimäe tn 5, 10145 Tallinn, Republic of Estonia (acting as Processor, the "Processor", "Advocat", "we", "us"). It reflects the parties' agreement with respect to the processing of Personal Data by the Processor on behalf of the Controller in connection with the Advocat platform (the "Service") and is intended to satisfy Article 28 of Regulation (EU) 2016/679 (the "GDPR").

In this DPA, "Personal Data", "Controller", "Processor", "Data Subject", "Processing" and "Sub-processor" have the meanings given to them in the GDPR.

1. SUBJECT MATTER AND DURATION

1.1 Subject matter. The Processor processes Personal Data to provide AI-assisted legal-research, document-analysis, email, scheduling and adjacent features made available through the Service.

1.2 Duration. This DPA applies for as long as the Processor processes Personal Data on behalf of the Controller under the Agreement, and survives termination for the limited period necessary to perform the return-or-deletion obligations in Section 10.

2. NATURE AND PURPOSE OF PROCESSING

2.1 The Processor processes Personal Data only for the following purposes:
  (a) providing AI legal-research assistance, drafting, summarisation and translation in response to prompts submitted by the Controller's authorised users;
  (b) ingesting, transcribing, OCRing, indexing and analysing documents the Controller (or its end-users) upload to the Service;
  (c) storing conversation history, case files, deadlines and reminders associated with the Controller's account;
  (d) sending and receiving emails on behalf of the Controller, either through the Controller's own OAuth-authorised mailbox (e.g. Gmail) or, where the Controller has not connected a mailbox, through a transactional email fallback;
  (e) billing administration and customer support;
  (f) ensuring the security, availability and integrity of the Service.

2.2 The Processor will not process Personal Data for any other purpose, and in particular will not use Personal Data for its own advertising, model training or product analytics, without the Controller's prior written instruction.

3. CATEGORIES OF PERSONAL DATA AND DATA SUBJECTS

3.1 Categories of Personal Data. Depending on how the Controller and its users configure and use the Service, the Processor may process:
  (a) account data: email address, full name, IP address, device and browser metadata, locale, subscription tier;
  (b) authentication data: hashed credentials and OAuth tokens (Google/Apple), encrypted at rest;
  (c) content data: the text of prompts, chat messages, case notes, uploaded documents (which may themselves contain third-party Personal Data such as names, addresses, identity numbers, case file references, contact information, medical information and financial information where relevant to a legal matter), generated drafts, transcriptions of voice input;
  (d) communications metadata: sender, recipient, subject, date and provider message ID of emails sent or received through the Service;
  (e) usage data: feature interaction events used for product analytics, abuse prevention and capacity planning.

3.2 Categories of Data Subjects:
  (a) the Controller's authorised users (typically the Controller themselves where the Controller is an individual professional);
  (b) the Controller's clients, counterparties, witnesses, family members and other natural persons whose Personal Data appears in documents or prompts the Controller submits to the Service.

3.3 Special categories. The Service is not designed for the systematic processing of Article 9 special categories of data. The Controller is responsible for assessing whether a given upload is appropriate and for obtaining any consents required by Articles 9 and 10 of the GDPR.

4. PROCESSOR OBLIGATIONS (ARTICLE 28(3))

The Processor undertakes to:

4.1 Documented instructions. Process Personal Data only on documented instructions from the Controller. The Agreement, this DPA and the Controller's use of the Service through its account constitute the Controller's complete and final documented instructions. Additional or different instructions must be agreed in writing. The Processor will immediately inform the Controller if, in its opinion, an instruction infringes the GDPR or other Union or Member State data-protection law.

4.2 Confidentiality. Ensure that persons authorised to process the Personal Data (employees, contractors and Sub-processors) have committed themselves to confidentiality or are under an appropriate statutory obligation of confidentiality.

4.3 Security (Art. 32). Implement the technical and organisational measures described in Section 7 to ensure a level of security appropriate to the risk.

4.4 Sub-processors. Engage Sub-processors only in accordance with Section 5.

4.5 Data Subject rights. Taking into account the nature of the processing, assist the Controller by appropriate technical and organisational measures, insofar as this is possible, in fulfilling its obligation to respond to requests by Data Subjects exercising their rights under Chapter III of the GDPR.

4.6 Security, breach, DPIA and prior consultation assistance. Assist the Controller in ensuring compliance with the obligations in Articles 32 to 36 of the GDPR, taking into account the nature of the processing and the information available to the Processor.

4.7 Return or deletion. At the choice of the Controller, return or delete all Personal Data after the end of the provision of services relating to processing, in accordance with Section 10.

4.8 Audit. Make available to the Controller all information necessary to demonstrate compliance with the obligations laid down in Article 28 of the GDPR, and allow for and contribute to audits in accordance with Section 8.

5. SUB-PROCESSORS

5.1 General authorisation. The Controller grants the Processor general written authorisation to engage Sub-processors for the provision of the Service, subject to this Section 5.

5.2 Current Sub-processors. As at the version date of this DPA, the Processor engages the following Sub-processors:

  (a) Anthropic, PBC (United States) — large-language-model inference. Receives prompts (which may include Controller-uploaded content) and returns generated text. Anthropic is certified under the EU-US Data Privacy Framework and contractually does not train its models on Customer Data submitted via its commercial API.
  (b) Supabase, Inc. (United States, with EU-region database hosting in West Europe / London) — database, authentication and serverless functions. EU-US Data Privacy Framework and Standard Contractual Clauses.
  (c) Google LLC (United States) — Gmail API access when the Controller's user voluntarily connects a Google account, so that the Service can send and receive emails from the user's own mailbox. EU-US Data Privacy Framework.
  (d) Resend, Inc. (United States) — transactional email dispatch as a fallback where no user mailbox is connected. Standard Contractual Clauses.
  (e) Stripe, Inc. (United States) — payment processing for paid subscriptions. EU-US Data Privacy Framework.
  (f) ElevenLabs Inc. (United States / United Kingdom) — voice synthesis, engaged only when the user actively uses voice features. Standard Contractual Clauses.
  (g) GitHub, Inc. (United States) — static asset and landing-page hosting (GitHub Pages). EU-US Data Privacy Framework.

5.3 Changes. The Processor will give the Controller at least thirty (30) days' advance notice of any addition or replacement of a Sub-processor by updating the in-product list and, where the Controller has provided a notification email, by email. The Controller may object to such change on reasonable data-protection grounds within that notice period. If the parties cannot agree on a resolution, the Controller may terminate the affected portion of the Service for convenience.

5.4 Flow-down. The Processor will impose on each Sub-processor, by contract, data-protection obligations no less protective than those in this DPA, and remains fully liable to the Controller for the performance of each Sub-processor's obligations.

6. INTERNATIONAL TRANSFERS

6.1 Where the Processor or a Sub-processor transfers Personal Data outside the European Economic Area, such transfer is made on the basis of one or more of the following safeguards:
  (a) an adequacy decision adopted by the European Commission (including the EU-US Data Privacy Framework, where the recipient is certified);
  (b) the Standard Contractual Clauses adopted by the European Commission in Decision (EU) 2021/914, Module 2 (Controller to Processor) or Module 3 (Processor to Processor) as applicable, which are deemed incorporated into this DPA by reference and prevail in the event of conflict with this DPA;
  (c) any successor mechanism adopted by the European Commission.

6.2 The Processor will, on the Controller's reasonable request, provide a copy of the relevant transfer mechanism and a description of supplementary measures applied.

7. SECURITY MEASURES (ARTICLE 32)

7.1 The Processor maintains the following technical and organisational measures, which the Controller acknowledges as appropriate to the risk:
  (a) encryption in transit using TLS 1.2 or higher;
  (b) encryption at rest of the underlying Supabase Postgres storage and of stored OAuth refresh tokens;
  (c) row-level security policies that restrict access to each Controller's data to that Controller's authenticated session;
  (d) least-privilege role separation between application code, the service role and human operators, with audit logging of administrative access;
  (e) hashed credentials, single sign-on options and rate-limited authentication endpoints;
  (f) regular dependency scanning, secret scanning and security review of new code;
  (g) backup of the production database with encryption and retention controls;
  (h) an internal incident-response procedure with on-call coverage and a documented breach-notification flow.

7.2 The Processor may update these measures from time to time, provided that the overall level of security is not materially decreased.

8. AUDIT

8.1 Annual audit. On no more than one occasion per twelve-month period (or more frequently following a confirmed Personal Data Breach affecting the Controller's data), the Controller may, on thirty (30) days' prior written notice and during normal business hours, audit the Processor's compliance with this DPA.

8.2 Modalities. The audit must be conducted at the Controller's expense, under a reasonable confidentiality agreement, in a manner that does not unreasonably disrupt the Processor's operations, and may not require disclosure of information about other customers. The Controller may use a qualified independent auditor that is not a competitor of the Processor.

8.3 Alternative evidence. The Processor may discharge its audit obligation by providing third-party audit reports, penetration-test summaries or compliance certifications that reasonably evidence the matters in scope.

9. PERSONAL DATA BREACH NOTIFICATION

9.1 The Processor will notify the Controller without undue delay, and in any event within seventy-two (72) hours, after becoming aware of a Personal Data Breach affecting the Controller's Personal Data. The notification will, to the extent then known, describe the nature of the breach, the categories and approximate number of Data Subjects and records concerned, the likely consequences, and the measures taken or proposed to address the breach and mitigate its possible adverse effects.

9.2 The Processor will cooperate with the Controller and provide reasonable assistance in respect of any required notifications to the competent supervisory authority and to affected Data Subjects under Articles 33 and 34 of the GDPR.

10. RETURN OR DELETION OF DATA

10.1 Export window. On termination or expiry of the Agreement, the Controller may export its Personal Data through the in-product export tooling for thirty (30) days.

10.2 Deletion. After the export window, the Processor will delete the Controller's Personal Data within ninety (90) days, save to the extent that Union or Member State law requires the Processor to retain it (for example, accounting records under Estonian and Union tax law, which are retained for the statutory period). Backup copies are overwritten in the ordinary backup-rotation cycle, which does not exceed ninety (90) days.

11. LIABILITY

11.1 Each party's liability for breach of this DPA is governed by the limitation-of-liability provisions of the Agreement. Nothing in this DPA limits the rights of Data Subjects under the GDPR.

11.2 Where one party is required to pay compensation under Article 82 of the GDPR for damage caused by Processing that is attributable in whole or in part to the other party's breach of this DPA, that other party will indemnify the paying party for the corresponding share of the compensation, in accordance with Article 82(5) of the GDPR.

12. GOVERNING LAW AND JURISDICTION

12.1 This DPA is governed by the laws of the Republic of Estonia. The competent courts of Tallinn, Estonia, have exclusive jurisdiction over any dispute arising out of or in connection with this DPA, without prejudice to the rights of Data Subjects to bring proceedings before the competent supervisory authority or court under the GDPR.

13. PRECEDENCE AND AMENDMENTS

13.1 In the event of any conflict between this DPA and the Agreement, this DPA prevails with respect to the processing of Personal Data. In the event of any conflict between this DPA and the Standard Contractual Clauses incorporated under Section 6, the Standard Contractual Clauses prevail.

13.2 The Processor may update this DPA from time to time to reflect changes in applicable law, new Sub-processors or evolution of the Service. Material changes will be communicated as described in Section 5.3 and will require a new acceptance from the Controller before the Controller upgrades or renews a paid subscription on the new version.

-- End of DPA v1.0 --
''';
