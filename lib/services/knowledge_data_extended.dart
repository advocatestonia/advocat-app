// ---------------------------------------------------------------------------
// Extended Legal Knowledge Base — All 27 EU Countries
// ---------------------------------------------------------------------------
// This file extends the core KnowledgeBase with comprehensive country-specific
// legal knowledge covering immigration, healthcare, education, domestic
// violence protections, practical contacts, landmark court decisions,
// and processing times for ALL 27 EU member states.
// ---------------------------------------------------------------------------

/// Extended knowledge data organized by country and topic.
/// Each section is a const String that can be injected into system prompts.
abstract final class KnowledgeDataExtended {

  // =========================================================================
  // SECTION 1: COUNTRY-SPECIFIC IMMIGRATION PROCEDURES
  // =========================================================================

  // ── FINLAND (FI) ──────────────────────────────────────────────────────────

  static const String finlandImmigration = '''
## FINLAND — IMMIGRATION PROCEDURES (DETAILED)

**Immigration Authority:**
- Maahanmuuttovirasto (Migri / Finnish Immigration Service)
- Address: Opastinsilta 12 A, 00520 Helsinki
- Phone: +358 295 430 431 (advice line)
- Website: migri.fi / enterfinland.fi
- E-service: Enter Finland (enterfinland.fi) — online applications

**Residence Permit Types:**
1. **A-permit (Continuous):** Issued for work, study, family — renewable, leads to permanent
2. **B-permit (Temporary):** Issued when grounds are temporary — does NOT count toward permanent
3. **P-permit (Permanent):** After 4 years continuous residence on A-permit
4. **EU Blue Card:** For highly qualified workers (min salary EUR 5505.83/month in 2024)
5. **Intra-corporate Transfer (ICT):** For managers/specialists transferred within company
6. **Seasonal Worker Permit:** Max 9 months, agriculture/tourism
7. **Startup Permit:** For innovative business founders (requires Business Finland evaluation)
8. **Researcher Permit:** For scientific research at accredited institution
9. **EU Long-Term Resident Permit:** After 5 years legal residence

**How to Apply:**
1. Create account on enterfinland.fi
2. Fill in application form online
3. Visit Finnish embassy/consulate or police station/Migri service point to verify identity
4. Provide supporting documents (passport, photo, proof of income, insurance, etc.)
5. Pay application fee (EUR 350-520 depending on type)
6. Await decision — notification via Enter Finland or by post

**Appeal Procedures and Deadlines:**
- **30 days** from notification to appeal to Hallinto-oikeus (Administrative Court)
- Appeal must be in writing, can be in Finnish, Swedish, or English
- Court can grant interim measures (stay of execution / turvaamistoimenpide)
- Court decision within 3-12 months typically
- Further appeal to KHO (Supreme Administrative Court) requires leave to appeal
- **KHO leave application: 30 days** from Administrative Court decision
- If deadline missed, can request restoration of expired deadline (menetetyn maaraaajan palauttaminen) within 30 days, only for excusable reasons

**Family Reunification:**
- Sponsor must have valid residence permit (A or P)
- Family members: spouse/registered partner, minor children under 18
- Income requirement: sponsor must show sufficient income (varies by family size)
  - Single + spouse: approx EUR 1700/month net
  - Each additional child: approx EUR 500/month additional
- Application filed by family member at Finnish embassy abroad
- Processing time: 9-18 months (significant backlog)
- Refugee sponsors: exempted from income requirement if applied within 3 months of getting refugee status
- DNA testing may be requested to verify family relationship

**Work Permit Process:**
- Most work requires employer to first file a request with TE-Office (Employment Office)
- TE-Office assesses labor market need (partial labor market test)
- Some professions exempt from labor market test: specialists, researchers, top athletes
- Self-employed: separate residence permit, must show viable business plan
- Seasonal work: separate simplified process through EURES
- EU Blue Card: no labor market test, salary threshold applies
- Work permit holder can change employer within same field after first permit

**Student Visa Rules:**
- Must be accepted at Finnish higher education institution
- Proof of sufficient funds: EUR 6720/year (or EUR 560/month)
- Health insurance required (coverage min EUR 100,000 for non-EU, EUR 30,000 for EU)
- Can work 25 hours/week during term, unlimited during holidays
- After graduation: 2-year job-seeking residence permit (A-permit)
- Time spent on student permit counts toward permanent residence

**Path to Permanent Residence:**
- 4 years continuous residence on A-permit (B-permit time does NOT count)
- Must have valid grounds for residence at time of application
- No extended absences (max 1 year total absence in 4-year period)
- Sufficient income to support self
- No criminal record issues (serious crimes may block)

**Path to Citizenship:**
- Residency requirement: 5 years continuous OR 7 years total (with 2 years continuous)
- Language requirement: Finnish or Swedish at level 3 (YKI 3 / intermediate)
- Clean criminal record (minor offenses may be waived)
- No unpaid taxes or debts to state
- Identity established reliably
- Dual citizenship allowed since June 2003
- Application fee: EUR 420 (online) / EUR 520 (paper)
- Processing time: 12-24 months
''';

  // ── ESTONIA (EE) ──────────────────────────────────────────────────────────

  static const String estoniaImmigration = '''
## ESTONIA — IMMIGRATION PROCEDURES (DETAILED)

**Immigration Authority:**
- Politsei- ja Piirivalveamet (PPA / Police and Border Guard Board)
- Address: Parnu mnt 139, 15060 Tallinn
- Phone: +372 612 3000
- Website: politsei.ee
- E-service: politsei.ee/en/instructions/residence-permits

**Residence Permit Types:**
1. **Temporary Residence Permit (TRP):** For work, study, family, business — valid 1-5 years
2. **Long-Term Resident Permit:** After 5 years legal residence
3. **EU Blue Card:** For highly qualified workers
4. **Short-Term Employment Registration:** Up to 365 days, no permit needed (registration only)
5. **Digital Nomad Visa:** For remote workers — up to 1 year
6. **Startup Visa:** For founders of innovative startups — up to 18 months initially
7. **ICT Permit:** Intra-corporate transferees
8. **Top Specialist Permit:** For highly paid specialists (salary 2x Estonian average)

**How to Apply:**
1. Submit application at Estonian embassy abroad or PPA service point in Estonia
2. Online pre-registration at politsei.ee
3. Provide biometric data (fingerprints, photo)
4. Supporting documents: passport, proof of income, insurance, housing proof
5. Application fee: EUR 80-160 depending on type
6. Decision typically within 2 months (can extend to 4 months)

**Appeal Procedures and Deadlines:**
- **30 days** from notification to file challenge (vaie) to PPA itself (mandatory pre-court procedure)
- PPA must respond within 30 days
- If PPA denies challenge: **30 days** to appeal to Tallinna Halduskohus (Tallinn Administrative Court)
- Court can grant interim measures (provisional legal protection)
- Further appeal to Tallinna Ringkonnakohus (Tallinn Circuit Court) within **30 days**
- Cassation to Riigikohus (Supreme Court) within **30 days** — leave required

**Family Reunification:**
- Sponsor needs valid TRP or long-term resident permit
- Family members: spouse, minor children, adult children in special cases, parents of minors
- Income requirement: sponsor must earn at least Estonian average salary
- Housing requirement: adequate living space
- Immigration quota: Estonia has annual immigration quota (approx 0.1% of population, ~1300 people/year)
  - Family reunification of spouse and minor children exempt from quota
  - EU/EEA citizens exempt from quota

**Work Permit Process:**
- Short-term employment (up to 365 days): register with PPA, employer files, no permit needed
- Long-term: need TRP for employment — employer involvement required
- Labor market test not required for most categories since 2017
- Salary requirement: at least Estonian average salary (EUR 1820/month in 2024)
- Top specialist: 2x average salary — fast track processing
- Seasonal work: up to 270 days within 365 days

**Student Visa Rules:**
- Acceptance at Estonian educational institution required
- Proof of funds: EUR 4704/year (EUR 392/month)
- Health insurance required
- Can work without restriction if related to studies or during summer
- Otherwise: max 20 hours/week during term
- After graduation: 9-month job-seeking permit

**Path to Permanent Residence (Long-Term Resident):**
- 5 years continuous legal residence
- Stable legal income
- Valid health insurance
- Registered place of residence
- Estonian language requirement: B1 level (Eesti keele oskus B1 tasemel)

**Path to Citizenship:**
- 8 years legal residence (5 continuous before application + 3 years prior)
- Estonian language: B1 level (reading, writing, speaking)
- Knowledge of Estonian Constitution and Citizenship Act (exam)
- Stable legal income
- No dual citizenship allowed (must renounce previous citizenship)
  - Exception: children born with multiple citizenships may keep until age 18
- Application fee: EUR 13 (state fee)
- Processing time: 6-12 months
- Note: ~70,000 stateless "grey passport" holders — simplified naturalization paths available
''';

  // ── GERMANY (DE) ──────────────────────────────────────────────────────────

  static const String germanyImmigration = '''
## GERMANY — IMMIGRATION PROCEDURES (DETAILED)

**Immigration Authority:**
- Bundesamt fur Migration und Fluchtlinge (BAMF) — asylum decisions
- Local Auslanderbehorde (Foreigners Authority) — residence permits
- Phone BAMF: +49 911 943 0
- Website: bamf.de / make-it-in-germany.com
- Each city has its own Auslanderbehorde

**Residence Permit Types:**
1. **Aufenthaltserlaubnis (Temporary Residence Permit):** For specific purpose — work, study, family
2. **Blaue Karte EU (EU Blue Card):** Highly qualified workers — salary min EUR 45,300/year (2024, shortage occupations) or EUR 58,400/year (general)
3. **Niederlassungserlaubnis (Settlement Permit):** Permanent — after 5 years (or 21-33 months with Blue Card)
4. **Erlaubnis zum Daueraufenthalt-EU (EU Long-Term Residence):** After 5 years
5. **Chancenkarte (Opportunity Card):** Points-based job-seeking visa (since June 2024)
6. **ICT Card:** Intra-corporate transfers
7. **Aufenthaltsgestattung:** Permit to stay during asylum procedure
8. **Duldung (Tolerated Stay):** Temporary suspension of deportation — not a residence permit
9. **Visum (National Visa - D):** Long-stay visa for initial entry

**How to Apply:**
1. Apply for national visa (D-visa) at German embassy in home country
2. After arrival, register at local Burgeramt (Citizens Office)
3. Apply for residence permit at local Auslanderbehorde
4. Provide: passport, biometric photos, proof of purpose (work contract, enrollment, etc.)
5. Health insurance proof mandatory
6. Fee: EUR 56-140 depending on type
7. Blue Card holders and skilled workers: fast-track through employer

**Appeal Procedures and Deadlines:**
- **Widerspruch (Objection):** 1 month from notification to the authority that issued the decision
- Not all Lander require Widerspruch — some allow direct court action
- **Klage (Lawsuit):** 1 month from Widerspruch decision (or from original decision if no Widerspruch)
- File at Verwaltungsgericht (Administrative Court)
- **Asylum cases: 2 weeks** for negative decisions, **1 week** for manifestly unfounded
- **Eilantrag (Urgent application):** Can request interim measures under VwGO Section 80(5) or 123
- Appeal to Oberverwaltungsgericht (OVG): approval of appeal required
- Revision to Bundesverwaltungsgericht (BVerwG): on points of law only

**Family Reunification:**
- Sponsor needs settlement permit or residence permit with good prognosis
- Spouse: must be 18+, basic German language skills (A1) usually required before entry
  - Exceptions: Blue Card holders' spouses, hardship cases
- Children under 18: generally permitted
- Parents of adult foreigners: only in cases of extreme hardship
- Income requirement: sufficient living space (12 sqm per person) and income to support family
- Health insurance for all family members required

**Work Permit Process:**
- Skilled workers (Fachkrafteeinwanderungsgesetz 2020/2024):
  - Recognized qualification (German or equivalent) required
  - OR: relevant professional experience (min 2 years) + salary threshold
- EU Blue Card: recognized degree + job offer meeting salary threshold
- Chancenkarte (since June 2024): points system — degree, experience, language, age
- Self-employment: Section 21 AufenthG — must show economic interest or regional need
- No labor market test for recognized skilled workers since March 2024
- IT specialists: 3 years experience + EUR 45,300 salary — no formal degree needed

**Student Visa Rules:**
- Admission letter from German university/Studienkolleg
- Proof of funds: EUR 11,208/year in blocked account (Sperrkonto)
- Health insurance (public or private)
- Work: 120 full days or 240 half days per year
- After graduation: 18-month job-seeking residence permit
- Student visa fee: EUR 75

**Path to Permanent Residence:**
- Niederlassungserlaubnis: 5 years on residence permit
  - German language B1
  - Sufficient income (no social benefits)
  - 60 months pension contributions
  - Basic knowledge of German legal/social system (Integration Course)
- Blue Card fast-track: 21 months (with B1 German) or 27 months (with A1 German)

**Path to Citizenship:**
- 5 years legal residence (reduced from 8, effective June 2024)
  - 3 years possible with exceptional integration
- German language: B1 level
- Citizenship test (Einburgerungstest) — 33 questions, must get 17 correct
- Self-sufficient (no social benefits in last 2 years, exceptions for elderly/disabled)
- Clean criminal record
- Dual citizenship now allowed (since June 2024 reform!)
- Fee: EUR 255 (adults), EUR 51 (minors)
- Processing time: 6-24 months depending on state/city
''';

  // ── SWEDEN (SE) ──────────────────────────────────────────────────────────

  static const String swedenImmigration = '''
## SWEDEN — IMMIGRATION PROCEDURES (DETAILED)

**Immigration Authority:**
- Migrationsverket (Swedish Migration Agency)
- Address: Slottsgatan 82, 602 22 Norrkoping
- Phone: +46 771 235 235
- Website: migrationsverket.se
- E-service: Online application at migrationsverket.se

**Residence Permit Types:**
1. **Arbetstillstand (Work Permit):** Employer-sponsored, 2 years initially
2. **EU Blue Card:** Highly qualified workers
3. **Uppehallstillstand for studier (Student Permit):** Duration of studies
4. **Anknytning (Family Reunification Permit):** For family of residents/citizens
5. **Asyl (Asylum):** International protection
6. **Permanent uppehallstillstand (Permanent Residence Permit):** After qualifying period
7. **EU Long-Term Resident Status:** After 5 years
8. **Researcher Permit:** For scientific research
9. **ICT Permit:** Intra-corporate transfer
10. **Self-Employment Permit:** For business owners with viable plan

**How to Apply:**
1. Apply online at migrationsverket.se (most categories)
2. Book appointment at Swedish embassy for biometrics (if abroad)
3. Or visit Migrationsverket service center (if in Sweden)
4. Provide: passport, supporting documents, photos
5. Fee: SEK 1000-2000 depending on category
6. Decision notification: online, by email, or by post

**Appeal Procedures and Deadlines:**
- **3 weeks (21 days)** from notification to appeal to Migrationsdomstol (Migration Court)
- 4 Migration Courts in Sweden: Stockholm, Gothenburg, Malmo, Lulea
- Migration Court can grant inhibition (stay of execution)
- Further appeal to Migrationsoverdomstolen (Migration Court of Appeal) in Stockholm
  - Leave to appeal required (prövningstillstand)
  - **3 weeks** to apply for leave
- Migrationsoverdomstolen decisions are final and set precedent

**Family Reunification:**
- Sponsor must have permanent residence permit or be Swedish citizen
- Temporary permit holders: limited reunification, must show good prognosis for permanent
- Family: spouse/cohabitant, children under 18
- Maintenance requirement (forsorjningskrav): since 2010
  - Sufficient income to support family (approx SEK 8694/month + housing costs)
  - Adequate housing (1 room per 2 people + kitchen)
  - Exemptions: Swedish citizens, children, refugees (if applied within 3 months)
- Proxy interview may be conducted with sponsor in Sweden
- Processing time: 12-24 months (significant delays)

**Work Permit Process:**
- Employer must advertise position in EU/EEA for 10 days minimum
- Employment terms must meet Swedish collective agreement standards
  - Minimum salary: SEK 13,000/month (before tax) effective 2024
  - Insurance: health, life, occupational injury, pension
- Work permit tied to specific employer for first 2 years
- After 2 years: can change employer within same occupation
- After 4 years: eligible for permanent residence
- Specialist and high-salary exemptions available

**Student Visa Rules:**
- Acceptance at Swedish university/college
- Tuition fee payment proof (non-EU/EEA students pay tuition)
- Funds: SEK 9450/month for duration of studies
- Health insurance: provided by university for PhD students, others need private
- Work: unlimited hours (no restriction for students with valid permit)
- After graduation: 12-month job-seeking permit (since 2022)

**Path to Permanent Residence:**
- 4 years of work permit (hemvist) in last 7 years
- OR 3 years continuous residence with Swedish citizen/permanent resident family
- Must demonstrate ability to support self
- Swedish language and civic knowledge requirements being introduced (proposed)

**Path to Citizenship:**
- 5 years continuous residence (3 years for Nordic citizens, 4 years for refugees)
- Must be 18 or older (children can be included in parent's application)
- Good conduct (vandel) — no serious criminal record
- NO language test currently required (proposed bill may change this)
- Dual citizenship allowed since July 2001
- Fee: SEK 1500 (adults), SEK 175 (minors)
- Processing time: 12-36 months (severe backlogs)
''';

  // ── FRANCE (FR) ──────────────────────────────────────────────────────────

  static const String franceImmigration = '''
## FRANCE — IMMIGRATION PROCEDURES (DETAILED)

**Immigration Authority:**
- Office Francais de l'Immigration et de l'Integration (OFII)
- Prefecture de Police (Paris) / Prefecture (other departments)
- Phone OFII: +33 1 53 69 53 70
- Website: ofii.fr / service-public.fr / administration-etrangers-en-france.interieur.gouv.fr
- Online platform: ANEF (Administration Numerique pour les Etrangers en France)

**Residence Permit Types:**
1. **Visa Long Sejour valant Titre de Sejour (VLS-TS):** Long-stay visa acting as residence permit (1 year)
2. **Carte de Sejour Temporaire:** 1-year temporary residence card
   - "Salarie" (employee), "Etudiant" (student), "Vie privee et familiale" (family life)
3. **Carte de Sejour Pluriannuelle:** Multi-year card (2-4 years) after first year
4. **Carte de Resident:** 10-year residence card
5. **Passeport Talent:** For highly skilled workers, researchers, artists, startup founders — 4 years
6. **Carte de Sejour "Retraite":** For retirees
7. **EU Blue Card:** Highly qualified workers
8. **Carte de Resident Permanent:** Permanent residence

**How to Apply:**
1. Apply for long-stay visa at French consulate in home country
2. Upon arrival: validate VLS-TS online via OFII website within 3 months
3. For renewals: apply online via ANEF platform at prefecture
4. Provide: passport, photos, proof of address, income, insurance
5. Fee (taxe): EUR 200-400 depending on type
6. Biometric appointment at prefecture

**Appeal Procedures and Deadlines:**
- **Recours gracieux (Administrative appeal):** To the prefecture that made the decision — no strict deadline but best within 2 months
- **Recours hierarchique:** To the Ministry of Interior — within 2 months
- **Recours contentieux (Court appeal):** To Tribunal Administratif within **2 months** from notification
- Visa refusal: **2 months** to Commission de Recours contre les Refus de Visa (CRRV), then 2 months to Tribunal Administratif de Nantes
- Asylum refusal: **1 month** to Cour Nationale du Droit d'Asile (CNDA)
  - Accelerated procedure: **15 days** to CNDA
- **Refere (Urgent interim measures):** Refere-liberte (48 hours) or refere-suspension to Tribunal Administratif
- Dublin transfer: **15 days** to Tribunal Administratif + refere-liberte possible

**Family Reunification:**
- Sponsor must have residence permit valid 18+ months and at least 18 months of residence
- Family: spouse (18+), minor children
- Income requirement: at least SMIC (EUR 1766.92/month gross in 2024) without social benefits
- Housing requirement: adequate size (9 sqm for first person + 7 sqm per additional)
- Process: application to OFII, evaluation by mayor, decision by prefecture
- Timeline: OFII has 6 months to process, then prefecture decides
- Children's education: immediate right to school enrollment

**Work Permit Process:**
- Standard employee: employer files request at prefecture, DREETS evaluates labor market
- Passeport Talent: no labor market test — for qualified workers, salary > 2x SMIC
- Intra-company transfer: ICT card, no labor market test
- Change of status (student to worker): at prefecture, employer involvement required
- Auto-entrepreneur: possible with specific residence cards
- EU Blue Card: salary threshold EUR 53,836.50/year (2024)

**Student Visa Rules:**
- Acceptance at French education institution
- Campus France procedure required for most nationalities (Etudes en France portal)
- Proof of funds: EUR 615/month
- Housing proof or reservation
- Health insurance: CPAM (automatic for students in France)
- Work: 964 hours/year (approx 60% of full time)
- After studies: 1-year "recherche d'emploi" APS (Autorisation Provisoire de Sejour)
- Master's degree holders from French institutions: can apply for job-seeking permit

**Path to Permanent Residence (Carte de Resident):**
- 5 years continuous legal residence on temporary permit
- Sufficient and stable income
- Integration in French society (Republican Integration Contract — CIR — completed)
- Some categories get 10-year card directly: parents of French children, spouses of French citizens (after 3 years), refugees

**Path to Citizenship:**
- 5 years continuous residence (reduced to 2 years for higher education in France or exceptional service)
- French language: B1 oral level minimum
- Knowledge of French history, culture, civic values
- Sufficient income (no fixed amount, assessed case-by-case)
- Good character / casier judiciaire clean
- Integration into French community assessed by prefecture interview
- Dual citizenship allowed
- Fee: EUR 55 (timbre fiscal)
- Processing time: 12-18 months (decree by Minister of Interior)
''';

  // ── ITALY (IT) ──────────────────────────────────────────────────────────

  static const String italyImmigration = '''
## ITALY — IMMIGRATION PROCEDURES (DETAILED)

**Immigration Authority:**
- Questura (Provincial Police Headquarters) — permits issued here
- Sportello Unico per l'Immigrazione (One-Stop Immigration Office) — at Prefettura
- Ministry of Interior: interno.gov.it
- Phone: +39 06 46539 (Ministry)
- Patronati (trade union offices) assist with applications for free

**Residence Permit Types:**
1. **Permesso di Soggiorno per Lavoro Subordinato:** Employment — 1-2 years
2. **Permesso di Soggiorno per Lavoro Autonomo:** Self-employment
3. **Permesso di Soggiorno per Studio:** Student — 1 year renewable
4. **Permesso di Soggiorno per Motivi Familiari:** Family
5. **Carta di Soggiorno (Permesso UE Soggiornanti di Lungo Periodo):** Permanent — after 5 years
6. **Protezione Internazionale:** International protection (refugee status / subsidiary)
7. **Permesso per Attesa Occupazione:** Job-seeking after job loss — 1 year
8. **Permesso per Cure Mediche:** Medical treatment
9. **EU Blue Card:** Highly qualified workers
10. **Elective Residence Visa:** For retirees / independent means

**How to Apply:**
1. Apply for entry visa at Italian embassy/consulate
2. Within 8 working days of arrival: apply for residence permit (permesso di soggiorno)
3. Application submitted at Poste Italiane (Post Office) using special kit
4. Biometric appointment at Questura
5. Supporting documents vary by permit type
6. Fee: EUR 40-100 + EUR 30.46 postal fee + EUR 16 revenue stamp (marca da bollo)

**Appeal Procedures and Deadlines:**
- **Ricorso al TAR (Regional Administrative Court):** 60 days from notification
- **Ricorso Straordinario al Presidente della Repubblica:** 120 days (alternative to TAR)
- Cannot use both — must choose one
- Asylum refusal: **30 days** to Tribunale Civile (Civil Court, specialized section)
  - Accelerated procedure: **15 days**
  - Dublin: **15 days**
- TAR can grant sospensiva (suspension of execution)
- Appeal from TAR to Consiglio di Stato within **60 days**

**Family Reunification:**
- Sponsor must have residence permit valid 1+ year with prospect of renewal
- Family: spouse (not legally separated), minor children, dependent parents (over 65), dependent adult children
- Income requirement: annual income at least equal to annual social allowance (assegno sociale)
  - 2024: approx EUR 6947.33/year for one person + increases per family member
- Housing requirement: idoneita alloggiativa certificate from municipality
- Apply at Sportello Unico per l'Immigrazione
- Processing: 90 days for Nulla Osta, then visa at consulate

**Work Permit Process:**
- Annual quota system (Decreto Flussi) — limited number of work permits per year
- Employer must apply within quota opening period
- Outside quota: EU Blue Card, ICT, highly qualified, researchers
- Seasonal work: separate quota
- Conversion from study to work: possible within quotas
- Self-employment: must show adequate resources and meet qualification requirements

**Student Visa Rules:**
- Pre-enrollment at Italian university via Universitaly portal
- Proof of funds: EUR 6000+/year
- Health insurance or enrollment in SSN (National Health Service)
- Work: max 20 hours/week (1040 hours/year)
- After graduation: 12-month job-seeking permit (since 2023)
- Housing proof required

**Path to Permanent Residence:**
- 5 years continuous legal residence
- Sufficient income (at least annual social allowance level)
- Adequate housing
- Italian language: A2 level
- Health insurance

**Path to Citizenship:**
- 10 years legal residence (4 years for EU citizens, 5 years for refugees)
- OR marriage to Italian citizen: 2 years in Italy / 3 years abroad (halved if children)
- Italian language: B1 level (since 2018)
- Sufficient income (min EUR 8263.31/year or family income)
- Clean criminal record
- Dual citizenship allowed (Italy is very permissive on dual nationality)
- Fee: EUR 250
- Processing time: legally 24 months, practically 36-48 months (huge backlog)
  - Can file appeal (diffida) if exceeds 24 months
''';

  // ── SPAIN (ES) ──────────────────────────────────────────────────────────

  static const String spainImmigration = '''
## SPAIN — IMMIGRATION PROCEDURES (DETAILED)

**Immigration Authority:**
- Oficina de Extranjeria (Foreigners Office) — at each provincial delegation
- Policia Nacional (National Police) — TIE card issuance
- Phone: +34 902 022 222 (general immigration info)
- Website: inclusion.gob.es / extranjeros.inclusion.gob.es
- Online portal: sede.administracionespublicas.gob.es

**Residence Permit Types:**
1. **Autorizacion de Residencia Temporal:** 1-year, renewable to 2 years, then 5 years
2. **Autorizacion de Residencia Temporal y Trabajo:** Work + residence
3. **Autorizacion de Residencia de Larga Duracion:** Permanent — after 5 years
4. **Visado de Estudios:** Student visa
5. **Arraigo Social:** Residence through social ties — 3 years illegal stay + job offer or social report
6. **Arraigo Laboral:** Residence through work ties — 2 years stay + 6 months documented work
7. **Arraigo Familiar:** Family ties to Spanish citizen
8. **Tarjeta de Familiar de Ciudadano UE:** Family member of EU citizen
9. **Autorizacion de Residencia No Lucrativa:** Non-profit/retirement
10. **Golden Visa:** Investment visa (EUR 500K real estate or EUR 1M financial)
11. **Visa para Nomadas Digitales:** Digital nomad visa (since 2023)
12. **Tarjeta Azul UE (EU Blue Card)**

**How to Apply:**
1. Visa application at Spanish embassy/consulate
2. In-country: application at Oficina de Extranjeria
3. Online through sede electronica when available
4. Provide: passport, EX forms, proof of purpose, NIE number
5. TIE card (Tarjeta de Identidad de Extranjero): apply at police station within 30 days of permit
6. Fee: approximately EUR 10-20 (Tasa modelo 790 012)

**Appeal Procedures and Deadlines:**
- **Recurso de Reposicion (Administrative appeal):** 1 month to same body that issued decision
  - Response within 1 month; silence = rejection
- **Recurso de Alzada (Hierarchical appeal):** 1 month to superior body
  - Response within 3 months; silence = rejection
- **Recurso Contencioso-Administrativo (Court):** 2 months from notification to Juzgado Contencioso-Administrativo
  - OR 6 months if challenging administrative silence
- Asylum: **1 month** to appeal rejection at Audiencia Nacional
- Interim measures (medidas cautelares): can request suspension at court
- Deportation: appeal does not automatically suspend execution — must request suspension separately

**Family Reunification:**
- Sponsor must have residence permit for 1+ year AND permit renewed/renewable
- Family: spouse, children under 18, dependent parents (sponsor must be long-term resident for parents)
- Income: IPREM-based (EUR 600/month for 2 persons + EUR 150 per additional member)
- Housing: adequate housing report from municipality
- Apply at Oficina de Extranjeria with family reunion form (EX-02)
- Processing: 45 days for resolution, then visa at consulate

**Work Permit Process:**
- Employer-sponsored: Autorizacion de trabajo por cuenta ajena — employer files
- Labor market test (situacion nacional de empleo): check that no available Spanish/EU workers
- Self-employed: must show viability and investment (min EUR 5000-10,000 recommended)
- Arraigo social path: 3 years residence + job offer OR social report
- Highly qualified: no labor market test needed
- Seasonal: GECCO program

**Student Visa Rules:**
- Acceptance at Spanish educational institution
- Proof of funds: min EUR 600/month (100% IPREM monthly)
- Health insurance (full coverage)
- Work: max 20 hours/week (must get separate authorization)
- Can change to work permit if job offer after graduation (modificacion de estancia a residencia)

**Path to Permanent Residence:**
- 5 years continuous legal residence
- Larga Duracion permit: indefinite, renewable every 5 years
- No extended absences (max 10 months in 5 years, no single absence > 6 continuous months)
- Clean record

**Path to Citizenship:**
- 10 years legal residence (general rule)
- 5 years for refugees
- 2 years for nationals of Ibero-American countries, Andorra, Philippines, Equatorial Guinea, Portugal, Sephardic Jews
- 1 year for: born in Spain, married to Spanish citizen (1 year), born to Spanish parent
- Spanish language + civic knowledge test: CCSE exam (by Instituto Cervantes) + DELE A2
- Clean record in Spain and country of origin
- Dual citizenship: only allowed for nationals of Ibero-American countries, Andorra, Philippines, Equatorial Guinea, Portugal
  - Others must renounce previous citizenship
- Fee: EUR 104.05
- Processing time: 12-36 months
''';

  // ── NETHERLANDS (NL) ──────────────────────────────────────────────────────

  static const String netherlandsImmigration = '''
## NETHERLANDS — IMMIGRATION PROCEDURES (DETAILED)

**Immigration Authority:**
- Immigratie- en Naturalisatiedienst (IND / Immigration and Naturalization Service)
- Address: Rijnstraat 8, 2515 XP The Hague
- Phone: +31 88 043 0430
- Website: ind.nl
- Online: mijn.ind.nl (application tracking)

**Residence Permit Types:**
1. **Verblijfsvergunning Regulier Bepaalde Tijd:** Regular temporary — work, study, family
2. **Verblijfsvergunning Regulier Onbepaalde Tijd:** Regular permanent — after 5 years
3. **Kennismigrant (Highly Skilled Migrant):** For knowledge workers — fast track
4. **Zoekjaar (Orientation Year):** Job-seeking after Dutch education
5. **Zelfstandig Ondernemer (Self-Employed):** Business owner
6. **EU Blue Card**
7. **ICT Permit**
8. **Asiel (Asylum)**
9. **EU Long-Term Resident**
10. **Startup Visa:** 1 year for startup founders (with recognized facilitator)

**How to Apply:**
1. MVV (Machtiging tot Voorlopig Verblijf): entry visa — applied for by sponsor/employer in NL at IND
2. After arrival: collect residence permit at IND desk or have it delivered
3. Some categories: apply directly at Dutch embassy without MVV
4. MVV-exempt nationals: USA, Canada, Japan, South Korea, Australia, NZ, and others
5. Online application via IND website for some categories
6. Fee: EUR 192-1171 depending on category

**Appeal Procedures and Deadlines:**
- **Bezwaar (Objection):** 4 weeks from decision to IND
- IND must decide within 6 weeks (extendable to 12 weeks)
- **Beroep (Appeal):** 4 weeks from bezwaar decision to Rechtbank (District Court)
- **Hoger beroep (Higher appeal):** 4 weeks to Afdeling Bestuursrechtspraak van de Raad van State (Council of State Administrative Jurisdiction Division)
- Asylum: **1 week** for bezwaar (accelerated) or **4 weeks** (extended procedure)
- Voorlopige voorziening (Interim measures): can request urgently at court
- Dublin: **1 week** for bezwaar

**Family Reunification:**
- Sponsor must have non-temporary residence permit
- Family: partner (21+ for both), minor children
- Income requirement: at least 100% of minimum wage (EUR 1934.40/month gross in 2024)
  - 150% for self-employed
  - Refugees: exempt if applied within 3 months (nareizigers)
- MVV required for family member before travel
- Civic integration exam (basisexamen inburgering) at embassy before arrival: Dutch language A1 + Knowledge of Dutch Society
- Processing: 90 days (MVV procedure)

**Work Permit Process:**
- Kennismigrant (Highly Skilled): recognized sponsor registers at IND, salary threshold:
  - 30+ years: EUR 5331/month (2024)
  - Under 30: EUR 3909/month
  - No labor market test
- Regular work permit (TWV): UWV assesses labor market need, 5-week test
- Self-employed: points system based on personal experience, business plan, added value to NL
- 30% ruling: tax advantage for incoming foreign workers (30% of salary tax-free, max 5 years)
- Seasonal: max 24 weeks per year

**Student Visa Rules:**
- Acceptance at DUO-recognized institution
- Proof of funds: EUR 12,689/year (2024) in blocked account or scholarship
- Health insurance: basic Dutch health insurance mandatory (approx EUR 130/month)
- Work: max 16 hours/week during term OR full-time June-August
- Orientation year (Zoekjaar): 1 year after graduation for job seeking
- Can work freely during orientation year

**Path to Permanent Residence:**
- 5 years continuous legal residence
- Civic integration exam passed (inburgeringsexamen)
- Sufficient income
- No extended absence (max 6 months continuous, max 10 months total in 5 years)

**Path to Citizenship:**
- 5 years continuous legal residence (3 years if married to Dutch citizen)
- Civic integration exam passed OR Dutch education diploma
- Renounce previous nationality (with exceptions: born in NL, married to Dutch, nationality cannot be renounced)
- 18+ years old
- No criminal record concerns
- Fee: EUR 971 (adults), EUR 142 (minors)
- Processing time: 6-12 months
- Dual citizenship: generally NOT allowed — must renounce, with specific exceptions
''';

  // ── POLAND (PL) ──────────────────────────────────────────────────────────

  static const String polandImmigration = '''
## POLAND — IMMIGRATION PROCEDURES (DETAILED)

**Immigration Authority:**
- Urzad do Spraw Cudzoziemcow (Office for Foreigners)
- Address: ul. Koszykowa 16, 00-564 Warsaw
- Phone: +48 22 601 74 01
- Website: gov.pl/udsc
- Local: Wojewoda (Voivode/Provincial Governor) offices handle permits

**Residence Permit Types:**
1. **Zezwolenie na Pobyt Czasowy:** Temporary residence — up to 3 years
2. **Zezwolenie na Pobyt Staly:** Permanent residence
3. **Zezwolenie na Pobyt Rezydenta Dlugolterminowego UE:** EU long-term resident
4. **Karta Polaka:** Polish Card — for persons of Polish descent abroad
5. **Wiza Krajowa (D-visa):** National long-stay visa
6. **EU Blue Card**
7. **Zezwolenie na Prace (Work Permit):** Employer-sponsored
8. **Oswiadczenie o powierzeniu pracy:** Declaration of employment (simplified — 24 months)

**How to Apply:**
1. Visa application at Polish embassy/consulate
2. Temporary/permanent residence: apply in person at Wojewoda office
3. Provide: filled application, passport, photos, proof of purpose, health insurance, income proof
4. Biometric data collected at Wojewoda office
5. Fee: PLN 340 (temporary) / PLN 640 (permanent) + PLN 50 for card
6. Decision: 1-2 months (officially), often 3-6 months due to backlogs

**Appeal Procedures and Deadlines:**
- **Odwolanie (Appeal):** 14 days to Szef Urzadu do Spraw Cudzoziemcow (Head of Office for Foreigners) via the Wojewoda
- **Skarga do WSA (Court complaint):** 30 days from appeal decision to Wojewodzki Sad Administracyjny (Regional Administrative Court)
- **Kasacja do NSA:** 30 days to Naczelny Sad Administracyjny (Supreme Administrative Court) — cassation
- Asylum: appeal within **14 days** to Rada do Spraw Uchodzcow (Refugee Board)
- Court review of Refugee Board: 30 days to WSA Warsaw
- Interim measures: court can suspend deportation
- During appeal, person generally has right to stay

**Family Reunification:**
- Sponsor needs temporary residence permit for 2+ years OR permanent/long-term
- Family: spouse, minor children
- No income requirement but must show means of support
- Housing: adequate housing
- Processing: within 60 days (formally), often longer
- Application at Wojewoda office

**Work Permit Process:**
- Employer-sponsored: employer applies at Wojewoda office
- Labor market test (informacja starosty) required — 14-day advertisement
- Exceptions: EU Blue Card, Karta Polaka holders, graduates of Polish universities
- Simplified procedure (Oswiadczenie): for citizens of 5 countries (Ukraine, Belarus, Georgia, Armenia, Moldova) — up to 24 months
- Single permit (temporary residence + work): combined application since 2018
- Self-employed: must show benefit to Polish economy

**Student Visa Rules:**
- Acceptance at Polish educational institution
- Proof of funds: approx PLN 776/month (student minimum)
- Health insurance (NFZ enrollment or private)
- Work: no separate permit needed if studying full-time at recognized institution
- After graduation: 1-year residence permit for job seeking

**Path to Permanent Residence:**
- Continuous legal residence for 5 years (on temporary permits)
  - Absences: max 10 months total, no single absence > 6 months
- Stable income
- Health insurance
- Polish language: B1 level (certificated by State Commission)
- Karta Polaka holders: can apply for permanent residence immediately upon arrival

**Path to Citizenship:**
- 3 years continuous residence with permanent/long-term resident permit
- Polish language: B1 (certified)
- Stable income
- Clean record
- OR: 10 years total residence in Poland
- OR: recognition of Polish citizenship by President (no fixed requirements — discretionary)
- Dual citizenship: tolerated (not explicitly regulated — Poland does not require renunciation)
- Fee: PLN 219
- Processing time: 2 months (Presidential recognition) to 12 months
''';

  // ── ROMANIA (RO) ──────────────────────────────────────────────────────────

  static const String romaniaImmigration = '''
## ROMANIA — IMMIGRATION PROCEDURES (DETAILED)

**Immigration Authority:**
- Inspectoratul General pentru Imigrari (IGI / General Inspectorate for Immigration)
- Address: Str. Lt. Col. Marinescu C-tin nr. 15A, Sector 5, Bucharest
- Phone: +40 21 210 22 52
- Website: igi.mai.gov.ro
- Territorial offices in each county

**Residence Permit Types:**
1. **Permis de Sedere Temporara:** Temporary — for work, study, family, business
2. **Permis de Sedere pe Termen Lung:** Long-term — after 5 years
3. **Drept de Sedere Temporara (Registration):** For EU citizens — registration after 3 months
4. **Viza de Lunga Sedere:** Long-stay visa (D-type) — entry document
5. **EU Blue Card**
6. **ICT Permit**
7. **Permis de Sedere pentru Activitati Comerciale:** Business activities
8. **Digital Nomad Visa:** Since 2022

**How to Apply:**
1. Long-stay visa at Romanian embassy/consulate
2. Within 30 days of entry: apply for residence permit at territorial IGI office
3. Documents: passport, visa, proof of accommodation, insurance, income, purpose
4. Fee: RON 120-259 depending on type
5. Biometric data collected at IGI

**Appeal Procedures and Deadlines:**
- **Contestatie (Challenge):** 30 days from notification — administrative appeal to issuing authority
- **Actiune in contencios administrativ:** 6 months from communication to Tribunal Administrativ (Administrative Court section of Tribunal)
  - Must exhaust administrative appeal first (prealabila)
- Asylum: **15 days** to Tribunal court
- Asylum accelerated: **10 days**
- Appeal from Tribunal to Curtea de Apel (Court of Appeal): **15 days**
- Interim measures: can request suspension of act at court
- Deportation: can challenge within 10 days to Court of Appeal

**Family Reunification:**
- Sponsor needs temporary residence for 1+ year with renewal prospect
- Family: spouse, minor children, dependent parents
- Income: at least Romanian minimum wage per family member (RON 3700/month gross in 2024)
- Housing: adequate accommodation
- Processing: 30 days (extendable to 60 days)

**Work Permit Process:**
- Employer applies for work authorization (aviz de munca) at IGI
- Labor market test: position must be advertised 30 days
- Authorization valid for 1 year, renewable
- Highly skilled: no labor market test needed
- Seasonal: max 5 months in 12 months
- EU Blue Card: recognized degree + employment contract + salary 2x Romanian average gross

**Student Visa Rules:**
- Acceptance at Romanian educational institution
- Proof of funds: approx EUR 500/month
- Health insurance
- Work: max 4 hours/day during academic year
- Accommodation proof

**Path to Permanent Residence:**
- 5 years continuous legal residence
- Proof of means of support (at least Romanian average salary)
- Health insurance
- Romanian language: basic knowledge (A2-B1, assessed by interview)
- Adequate accommodation

**Path to Citizenship:**
- 8 years legal residence (5 years for EU citizens)
- 5 years for spouse of Romanian citizen
- 4 years for refugees
- Romanian language: B1 (interview at Citizenship Commission)
- Knowledge of Romanian Constitution and history
- Sufficient income
- Clean record
- Dual citizenship: allowed (very common — Romania has large diaspora)
- Fee: RON 300 (EUR 60)
- Processing time: 6-18 months (Citizenship Commission)
''';

  // ── LATVIA (LV) ──────────────────────────────────────────────────────────

  static const String latviaImmigration = '''
## LATVIA — IMMIGRATION PROCEDURES (DETAILED)

**Immigration Authority:**
- Pilsonibas un migrācijas lietu pārvalde (PMLP / Office of Citizenship and Migration Affairs)
- Address: Čiekurkalna 1. linija 1, k-3, Riga, LV-1026
- Phone: +371 67 209 400
- Website: pmlp.gov.lv

**Residence Permit Types:**
1. **Termiņuzturēšanās atļauja (Temporary Residence Permit - TRP):** 1-5 years
2. **Pastāvīgā uzturēšanās atļauja (Permanent Residence Permit):** After 5 years
3. **EU Blue Card**
4. **Startup Visa**
5. **EU Long-Term Resident**
6. **Investment-based TRP:** Real estate EUR 250,000+, or company capital EUR 50,000+

**How to Apply:**
1. Apply at Latvian embassy or PMLP office in Latvia
2. Documents: passport, photos, proof of purpose, insurance, address registration
3. Fee: EUR 70-300 depending on type and processing speed
4. Decision within 30 days (standard), 10 days (urgent), 5 days (express)

**Appeal Procedures and Deadlines:**
- **Administrative appeal:** 1 month to PMLP Director
- **Court appeal:** 1 month from administrative decision to Administratīvā rajona tiesa (Administrative District Court)
- Further: Administratīvā apgabaltiesa (Administrative Regional Court)
- Cassation: Augstākā tiesa (Supreme Court) Senāts — 1 month
- Asylum: 15 days to Administrative District Court
- Interim measures available

**Family Reunification:**
- Sponsor: TRP or permanent residence
- Family: spouse, minor children, dependent parents
- Income: sufficient means of subsistence
- Housing: adequate living space
- Processing: 30-90 days

**Work Permit Process:**
- Employer submits invitation letter to PMLP
- Work permit issued as part of TRP
- No separate labor market test for most categories
- EU Blue Card: salary 1.5x Latvian average
- Self-employed: registered business + EUR 28,600 invested

**Path to Permanent Residence:**
- 5 years continuous legal residence
- Latvian language: A2 level
- Stable income
- No criminal concerns

**Path to Citizenship:**
- 5 years permanent residence (10 years total from first TRP)
- Latvian language: B1 (Latvian language proficiency exam)
- Knowledge of Constitution, national anthem, history (exam)
- Legal income
- Renounce previous citizenship (dual citizenship ONLY allowed with EU/NATO/EEA/EFTA countries, Australia, Brazil, and countries Latvia has agreements with)
- Fee: EUR 28.46
- Processing time: 6-12 months
- Note: ~200,000 "non-citizens" (nepilsoņi) with special status — simplified naturalization available
''';

  // ── LITHUANIA (LT) ──────────────────────────────────────────────────────

  static const String lithuaniaImmigration = '''
## LITHUANIA — IMMIGRATION PROCEDURES (DETAILED)

**Immigration Authority:**
- Migracijos departamentas (Migration Department under Ministry of Interior)
- Address: Šventaragio g. 2, 01510 Vilnius
- Phone: +370 5 271 7112
- Website: migracija.lrv.lt

**Residence Permit Types:**
1. **Leidimas laikinai gyventi (Temporary Residence Permit):** 1-2 years
2. **Leidimas nuolat gyventi (Permanent Residence Permit):** After 5 years
3. **EU Blue Card**
4. **Startup Visa:** For innovative business founders
5. **National D-Visa:** Long-stay up to 1 year
6. **EU Long-Term Resident**

**How to Apply:**
1. National visa at Lithuanian embassy
2. TRP: apply at Migration Department territorial office
3. Documents: passport, photo, purpose proof, insurance, income proof, criminal record
4. Fee: EUR 86-120
5. Processing: 2-4 months

**Appeal Procedures and Deadlines:**
- **Administrative complaint:** 1 month to Migration Department Director
- **Court:** 1 month to Vilniaus apygardos administracinis teismas (Vilnius Regional Administrative Court)
- Further: Lietuvos vyriausiasis administracinis teismas (Supreme Administrative Court of Lithuania)
- Asylum: 14 days to court
- Interim measures: court can suspend deportation

**Family Reunification:**
- Sponsor: TRP for 2+ years (or 1 year for highly qualified workers)
- Family: spouse, minor children
- Income: at least 2x minimum monthly salary per family member (EUR 924/month in 2024)
- Housing: min 14 sqm per person

**Work Permit Process:**
- Employer applies at Employment Service (Užimtumo tarnyba)
- Labor market test: 14-day advertisement for most categories
- Highly qualified: no market test, salary threshold
- EU Blue Card: salary 1.5x Lithuanian average gross
- Self-employed: must create jobs and invest (varies)

**Student Visa Rules:**
- Acceptance at Lithuanian institution
- Proof of funds: EUR 450/month
- Health insurance
- Work: max 20 hours/week during term

**Path to Permanent Residence:**
- 5 years continuous legal residence
- Lithuanian language: basic (A2 assessed by exam)
- Stable income
- Clean record

**Path to Citizenship:**
- 10 years permanent residence
- Lithuanian language: B1 (Constitution exam)
- Pass citizenship exam (Constitution basics)
- Legal income, no other citizenship
- Dual citizenship: NOT allowed (very strict — only by birth or descent exceptions)
  - Referendum failed to change this in 2019
- Fee: EUR 41
- Processing time: 6 months
''';

  // ── AUSTRIA (AT) ──────────────────────────────────────────────────────────

  static const String austriaImmigration = '''
## AUSTRIA — IMMIGRATION PROCEDURES (DETAILED)

**Immigration Authority:**
- Bundesamt für Fremdenwesen und Asyl (BFA — Federal Office for Immigration and Asylum) — asylum
- MA 35 (Vienna) / Bezirkshauptmannschaft (District Authority) — residence permits
- Phone BFA: +43 1 602 55 09 0
- Website: bfa.gv.at / oesterreich.gv.at
- Each Bundesland has its own authority for residence permits

**Residence Permit Types:**
1. **Aufenthaltstitel "Rot-Weiss-Rot Karte":** Skilled workers, key workers, graduates — 2 years
2. **Rot-Weiss-Rot Karte Plus:** Unrestricted labor market access — after initial card or family
3. **Niederlassungsbewilligung:** Settlement permit (various subcategories)
4. **Daueraufenthalt EU (EU Permanent Residence):** After 5 years
5. **Blaue Karte EU (EU Blue Card):** Highly qualified
6. **Aufenthaltsbewilligung Studierender:** Student permit
7. **Aufenthaltsbewilligung Forscher:** Researcher permit
8. **ICT:** Intra-corporate transfer
9. **Familienangehöriger:** Family member

**How to Apply:**
1. Apply at Austrian embassy/consulate before entry (most categories)
2. After entry: apply at competent authority (MA 35 in Vienna, BH elsewhere)
3. Points-based system for Rot-Weiss-Rot Karte (min 70 points out of max ~100):
   - Qualifications, work experience, language skills, age, salary
4. Documents: passport, birth certificate, police clearance, qualifications, employment contract
5. Fee: EUR 120-250 depending on category

**Appeal Procedures and Deadlines:**
- **Beschwerde (Complaint):** 4 weeks to Bundesverwaltungsgericht (Federal Administrative Court — BVwG)
  - Against BFA decisions (asylum, return, entry ban)
- **Berufung (Appeal):** 2 weeks to Landesverwaltungsgericht (Provincial Administrative Court)
  - Against residence permit decisions from provincial authorities
- **Revision:** 6 weeks to Verwaltungsgerichtshof (VwGH — Administrative High Court) — points of law only
- **Beschwerde an VfGH:** 6 weeks to Verfassungsgerichtshof (Constitutional Court) — fundamental rights
- Asylum: 4 weeks to BVwG (2 weeks for accelerated procedures)
- Interim measures: BVwG can grant aufschiebende Wirkung (suspensive effect)

**Family Reunification:**
- Sponsor: settlement permit or permanent residence
- Family: spouse (21+), minor children
- Income: at least reference rate (Ausgleichszulagenrichtsatz) — approx EUR 1217/month for couple
- Adequate housing
- Health insurance for all family members
- German A1 before entry (Integrationsvereinbarung) — except children under 14
- Annual quota: family reunification subject to Niederlassungsverordnung quotas

**Work Permit Process:**
- Rot-Weiss-Rot Karte: points-based, employer involvement
  - Key workers: min EUR 3375/month gross (2024)
  - Skilled workers in shortage occupations: listed annually
  - Other skilled workers: min EUR 2835/month gross + relevant qualifications
- Graduates of Austrian universities: simplified access
- Seasonal: Saisonbewilligung, quota-based
- Self-employed: must demonstrate economic benefit to Austria

**Student Visa Rules:**
- Acceptance at Austrian university
- Proof of funds: EUR 1217/month (under 24) / EUR 1310/month (24+)
- Health insurance
- Work: max 20 hours/week (10 hours for first year of bachelor's)
- Renewal dependent on academic progress (min ECTS credits)

**Path to Permanent Residence:**
- 5 years continuous legal residence
- German B1 (module 2 of Integration Agreement)
- Regular income (no social welfare)
- Health insurance
- Adequate housing

**Path to Citizenship:**
- 10 years continuous residence (6 years with B2 German or 3 years voluntary work, etc.)
- 6 years if married to Austrian citizen + living together
- German B1 (or B2 for 6-year track)
- Citizenship test (knowledge of Austrian democratic system, history, Bundesland)
- Self-sufficient income for last 3 years (some welfare payments OK if involuntary)
- Clean criminal record
- Renounce previous citizenship (dual NOT allowed — very strict)
  - Very rare exceptions (famous athletes, etc.)
- Fee: EUR 1115-1815 depending on Bundesland
- Processing time: 12-24+ months
''';

  // ── BELGIUM (BE) ──────────────────────────────────────────────────────────

  static const String belgiumImmigration = '''
## BELGIUM — IMMIGRATION PROCEDURES (DETAILED)

**Immigration Authority:**
- Office des Etrangers / Dienst Vreemdelingenzaken (Immigration Office)
- Address: Chaussee d'Anvers 59B, 1000 Brussels
- Phone: +32 2 793 80 00
- Website: dofi.ibz.be (Immigration Office)
- CGRA/CGVS (Commissioner General for Refugees and Stateless Persons) — asylum

**Residence Permit Types:**
1. **Carte A (CECI):** Temporary residence — 1 year renewable
2. **Carte B (CECI):** Unlimited residence
3. **Carte C (CECI):** Unlimited + unrestricted work
4. **Carte D:** Diplomatic
5. **Carte E / E+:** EU citizens' registration / permanent
6. **Carte F / F+:** Non-EU family of EU citizen / permanent
7. **Carte H (EU Blue Card)**
8. **Single Permit (Permis Unique / Gecombineerde Vergunning):** Work + residence
9. **Carte de Sejour de Resident de Longue Duree:** EU long-term resident

**How to Apply:**
1. Visa application at Belgian embassy/consulate
2. After arrival: register at commune/gemeente (municipality) within 8 days
3. Municipality issues Annex documents pending investigation
4. Police verification of address
5. Immigration Office makes final decision
6. Fee: EUR 200-350 (retribution payment for immigration application)

**Appeal Procedures and Deadlines:**
- **Recours en annulation (Annulment):** 30 days to Conseil du Contentieux des Etrangers (CCE / Council for Alien Law Litigation)
- **Recours en pleine juridiction (Full jurisdiction):** 15 days for asylum decisions to CCE
- **Recours en Cassation Administrative:** 30 days to Conseil d'Etat (Council of State)
- Extreme urgency procedure (extreme dringendheid / extreme urgence): 24-48 hours
- CCE can suspend and/or annul decisions
- Asylum accelerated: 10 days to CCE
- Dublin: 10 days to CCE

**Family Reunification:**
- Sponsor: unlimited residence permit or Belgian citizen
- Family: spouse/partner (21+ for third-country national sponsors, 18+ for Belgian sponsors), minor children, dependent parents (Belgian sponsors only)
- Income: at least 120% of social integration income (leefloon) — approx EUR 1934/month
- Adequate housing
- Sickness insurance (mutualite / ziekenfonds)
- Integration requirement: newcomer integration program (inburgeringscursus in Flanders)

**Work Permit Process:**
- Single Permit (since 2019): combined work + residence — employer applies at regional authority
  - Brussels: Brussel Economie en Werkgelegenheid
  - Flanders: Departement Werk en Sociale Economie
  - Wallonia: Direction de l'Emploi et des Permis de Travail
- Highly qualified: no labor market test, salary threshold
- EU Blue Card: salary min EUR 58,428/year (2024)
- Self-employed: Professional Card (carte professionnelle) via regional authority
- Au pair: separate procedure

**Student Visa Rules:**
- Acceptance at recognized Belgian institution
- Proof of funds: EUR 679/month (2024)
- Health insurance
- Work: max 20 hours/week during term, unlimited during holidays
- After graduation: 12-month job-seeking permit

**Path to Permanent Residence:**
- 5 years uninterrupted legal residence
- Stable, regular, sufficient income
- Health insurance (mutualite)
- Integration efforts demonstrated

**Path to Citizenship:**
- 5 years legal residence (3 years for Belgian-born, spouses of Belgians after marriage)
- Integration: one of: work 468 days in last 5 years, OR diploma from Belgian institution, OR integration course completed
- No language test legally required (but integration programs include language)
- Clean criminal record
- Dual citizenship: allowed
- Fee: EUR 150
- Processing time: 4-12 months (commune + prosecutor + State Security + Immigration Office investigate)
''';

  // ── IRELAND (IE) ──────────────────────────────────────────────────────────

  static const String irelandImmigration = '''
## IRELAND — IMMIGRATION PROCEDURES (DETAILED)

**Immigration Authority:**
- Immigration Service Delivery (ISD) — Department of Justice
- Address: 13-14 Burgh Quay, Dublin 2
- Phone: +353 1 616 7700
- Website: irishimmigration.ie
- INIS registration: burghquayregistrationoffice.inis.gov.ie

**Residence Permit Types (Stamp System):**
1. **Stamp 1:** Work permit holder — specific employer
2. **Stamp 1A:** Accounting trainees
3. **Stamp 2:** Student — limited work rights
4. **Stamp 3:** Non-EEA family member / dependent — no work
5. **Stamp 4:** Unlimited work access — refugees, family of Irish/EU citizens, long-term
6. **Stamp 4S:** Spouse of Critical Skills permit holder
7. **Stamp 5:** Without condition as to time — equivalent to permanent residence
8. **Stamp 6:** Dual citizenship holders
9. **Critical Skills Employment Permit:** Highly skilled, 2 years, leads to Stamp 4
10. **General Employment Permit:** Standard work permit, renewable
11. **Intra-Company Transfer Permit**
12. **Start-up Entrepreneur Programme (STEP):** For innovative startups — EUR 50,000 funding

**How to Apply:**
1. Visa (if required) at Irish embassy
2. On arrival: register with immigration officer at border
3. Within 90 days: register at Burgh Quay Dublin or local Garda (police) station
4. Receive IRP (Irish Residence Permit) card — biometric
5. Employment permits: apply online at dbei.gov.ie
6. Registration fee: EUR 300 per registration

**Appeal Procedures and Deadlines:**
- **Work permit refusal:** 28 days to appeal to Labour Market Division
- **Visa refusal:** 2 months to appeal to Visa Appeals Officer
- **Deportation order:** 15 working days to make representations to Minister
  - Judicial review: apply to High Court — no strict deadline but promptly
  - Leave required from High Court
- **Asylum (International Protection):** 15 working days to appeal to International Protection Appeals Tribunal (IPAT)
  - Accelerated: 10 working days
- High Court judicial review for all immigration matters
- Supreme Court: on point of law of exceptional public importance

**Family Reunification:**
- No comprehensive legislation — largely discretionary (Policy Document on Non-EEA Family Reunification)
- Sponsor: Irish citizen, EU citizen, or person with Stamp 4/5
- Family: spouse, dependent children, dependent parents (very limited)
- Critical Skills permit holders: immediate family can join with Stamp 1G/4S
- Income: must show ability to support family without social welfare
  - Guidelines: approx EUR 30,000+/year + EUR 5,000 per child
- No formal housing requirement but considered
- Refugees: statutory right under International Protection Act 2015 — 12-month deadline to apply

**Work Permit Process:**
- Critical Skills Employment Permit: specific occupations, salary EUR 38,000+ (or EUR 64,000+ for all occupations)
  - No labor market test
  - Spouse gets open work access
- General Employment Permit: salary min EUR 34,000, labor market test (14 days advertising)
- Ineligible categories list: certain jobs not eligible for permits
- Dependant/Partner Employment Permit: Stamp 3 holders with family ties
- After 5 years on work permit: eligible for Stamp 4 (no employer restriction)

**Student Visa Rules:**
- Acceptance at Irish education institution (ILEP — Interim List of Eligible Programmes)
- Proof of funds: EUR 10,000 in bank account
- Health insurance (not covered by public system unless employed)
- Work: 20 hours/week during term, 40 hours/week during holidays (June-September, December 15-January 15)
- Third Level Graduate Programme: 12-24 months post-study (Stamp 1G)

**Path to Permanent Residence:**
- No formal permanent residence program — instead: Stamp 4 (without condition) after 5 years
- Stamp 5 (Without Condition as to Time): application to Minister, 8 years residence
- Long-term residence: administrative scheme, 5 years on work permit

**Path to Citizenship (Naturalisation):**
- 5 years reckonable residence in last 9 years, with 1 year continuous before application
- Must be 18+ (children through parents)
- Good character
- Intention to reside in Ireland
- NO language test
- NO civic knowledge test
- Dual citizenship: allowed
- Fee: EUR 175 (application) + EUR 950 (certificate)
- Processing time: 12-23 months
- Decision by Minister — largely discretionary
''';

  // ── DENMARK (DK) ──────────────────────────────────────────────────────────

  static const String denmarkImmigration = '''
## DENMARK — IMMIGRATION PROCEDURES (DETAILED)

**Immigration Authority:**
- Udlaendingestyrelsen (SIRI — Danish Agency for International Recruitment and Integration) — work/study
- Udlaendingestyrelsen (Immigration Service) — asylum
- Udlaendingenævnet (Immigration Appeals Board) — appeals
- Phone: +45 72 14 20 00
- Website: nyidanmark.dk / siri.dk

**Residence Permit Types:**
1. **Opholds- og arbejdstilladelse (Residence and Work Permit):** Employer-specific
2. **Fast Track Scheme:** For certified companies — salary DKK 465,000+/year
3. **Pay Limit Scheme:** Salary-based, DKK 465,000+/year
4. **Positive List:** Shortage occupations
5. **Supplementary Positive List:** Bachelor's level shortage occupations
6. **Establishment Card:** Post-study job seeking — 3 years
7. **Start-up Denmark:** For startup founders
8. **Green Card (discontinued):** Replaced by newer schemes
9. **Family Reunification (Familiesammenføring)**
10. **Permanent Residence (Tidsubegrænset opholdstilladelse)**

**How to Apply:**
1. Apply online at nyidanmark.dk
2. Biometrics at Danish embassy/consulate or application center (VFS Global)
3. Fast Track: employer applies through SIRI
4. Provide: passport, documentation of purpose, financial means
5. Fee: DKK 3320-7350 depending on type
6. Processing: 1-6 months depending on category

**Appeal Procedures and Deadlines:**
- **Klage (Complaint):** 8 weeks to Udlaendingenævnet (Immigration Appeals Board) or Flygtningenævnet (Refugee Appeals Board)
- No court appeal against Nævnet decisions directly — only judicial review
- **Judicial review:** No fixed deadline but should be filed promptly at Byretten (City Court)
- Asylum: automatic review by Flygtningenævnet for most cases
  - Manifestly unfounded: no appeal, only judicial review
- Interim measures: can request at court
- Immigration detention: automatic court review within 72 hours

**Family Reunification:**
- Among the strictest in EU
- Spouse: both must be 24+ years old
- Aggregate attachment (tilknytningskrav): combined ties to Denmark must exceed ties to other country
  - Exemption: Danish citizens who lived in Denmark 28+ years
- Sponsor must have had permanent residence for 3+ years (or Danish/Nordic citizen)
- Financial security bond: DKK 100,000 deposit
- Income: self-sufficient, no social benefits in last 3 years
- Adequate housing: separate room per child
- Integration: language and knowledge test by 6 months
- Children: only if under 15 (was raised to 18 in recent changes), best interest test for 8-15

**Work Permit Process:**
- Employer-driven system — employer must offer employment
- Pay Limit Scheme: DKK 465,000+/year, no specific qualification needed
- Positive List: specific occupations with shortage, salary at usual level
- Fast Track: certified companies, various salary/qualification tracks
- Self-employed: very limited options
- All permits include work authorization

**Student Visa Rules:**
- Acceptance at Danish educational institution
- Proof of funds: DKK 6397/month
- Health insurance: automatic access to Danish healthcare upon registration
- Work: max 20 hours/week during term, full-time June-August
- After graduation: 3-year Establishment Card for job seeking (generous!)

**Path to Permanent Residence:**
- 8 years legal residence (can be reduced to 4 years with exceptional integration)
- Full-time employment 3.5 of last 4 years
- Pass Danish language test: Prøve i Dansk 2 (B1 equivalent)
- Pass civic knowledge test (medborgerskabsprøven)
- Self-sufficient for 4 years (no social benefits)
- No criminal record
- Active citizenship requirement (community involvement)
- No outstanding debt to public authorities

**Path to Citizenship:**
- 9 years legal residence (can be reduced to 6 for refugees, 8 for stateless)
- Danish language: Prøve i Dansk 3 (B2 equivalent) — very demanding
- Civic knowledge test (Indfodsretsprøven)
- Self-sufficient for 2 years
- Clean criminal record (strict — even minor convictions extend waiting period)
- No overdue public debt
- Self-declaration of loyalty to Denmark
- Dual citizenship: allowed since September 2015
- Fee: DKK 3800
- Processing: citizenship granted by law (Lov om Indfodsret) — twice yearly
''';

  // ── CZECH REPUBLIC (CZ) ──────────────────────────────────────────────────

  static const String czechRepublicImmigration = '''
## CZECH REPUBLIC — IMMIGRATION PROCEDURES (DETAILED)

**Immigration Authority:**
- Ministerstvo vnitra (Ministry of Interior) — Department for Asylum and Migration Policy
- Odbor azylovéa migrační politiky (OAMP)
- Phone: +420 974 832 421
- Website: mvcr.cz
- CzechPOINT offices for some services

**Residence Permit Types:**
1. **Dlouhodobé vízum (Long-Term Visa - D):** Over 90 days, max 1 year
2. **Povolení k dlouhodobému pobytu (Long-Term Residence Permit):** 1-2 years
3. **Povolení k trvalému pobytu (Permanent Residence Permit):** After 5 years
4. **Zaměstnanecká karta (Employee Card):** Combined work + residence
5. **Modrá karta (EU Blue Card):** Highly qualified
6. **Karta vnitropodnikově převedeného zaměstnance (ICT Card)**
7. **Povolení k pobytu za účelem investování:** Investor permit

**How to Apply:**
1. Long-term visa at Czech embassy/consulate
2. Long-term residence: apply at OAMP regional office (in CZ) or embassy
3. Employee Card: employer registers job vacancy, applicant applies
4. Documents: passport, purpose proof, accommodation proof, insurance, clean record
5. Fee: CZK 2500 (long-term visa), CZK 2500 (long-term residence), CZK 2500 (permanent)

**Appeal Procedures and Deadlines:**
- **Odvolání (Appeal):** 15 days to Komise pro rozhodování ve věcech pobytu cizinců (Commission for Decisions on Foreigners' Residence)
- **Žaloba (Court action):** 30 days to Krajský soud (Regional Court)
- **Kasační stížnost:** 2 weeks to Nejvyšší správní soud (Supreme Administrative Court)
- Asylum: 15 days to Krajský soud
- Interim measures: court can suspend deportation
- Detention review: automatic judicial review within 72 hours

**Family Reunification:**
- Sponsor: long-term or permanent residence permit
- Family: spouse, minor children, dependent parents (over 65)
- Income: at least subsistence minimum per family member
- Housing: adequate (certificate from municipality)
- Processing: 60-120 days

**Work Permit Process:**
- Employee Card: combined permit, employer files vacancy at labor office for 30 days
- EU Blue Card: university degree + salary 1.5x Czech average gross
- Self-employed: Živnostenský list (trade license) + business purpose residence
- Seasonal: max 6 months

**Path to Permanent Residence:**
- 5 years continuous legal residence
- Czech language A1 (exam at certified testing center)
- Clean record, stable income
- Dependants: 5 years alongside primary holder

**Path to Citizenship:**
- 5 years permanent residence (10 years total residence)
- Czech language B1 (certified exam)
- Civic knowledge test (Reálie)
- Clean record
- No serious tax debts
- Dual citizenship: allowed since January 2014
- Fee: CZK 2000
- Processing time: 6-12 months
''';

  // ── HUNGARY (HU) ──────────────────────────────────────────────────────────

  static const String hungaryImmigration = '''
## HUNGARY — IMMIGRATION PROCEDURES (DETAILED)

**Immigration Authority:**
- Országos Idegenrendészeti Főigazgatóság (OIF / National Directorate-General for Aliens Policing)
- Address: Budafoki út 60, 1117 Budapest
- Phone: +36 1 463 9100
- Website: oif.gov.hu
- Regional Directorates in each county

**Residence Permit Types:**
1. **Tartózkodási engedély (Residence Permit):** Temporary — work, study, family, etc.
2. **Bevándorlási engedély (Immigration Permit):** Settlement — repealed for most, replaced by national
3. **Letelepedési engedély (Settlement Permit):** Permanent — after 3-5 years
4. **EU Kék Kártya (EU Blue Card):** Highly qualified
5. **Nemzeti letelepedési engedély (National Settlement Permit):** Investors, special categories
6. **Ideiglenes tartózkodási engedély (Temporary Residence Certificate):** Asylum seekers
7. **Guest Investor (Golden Visa):** Investment-based, min EUR 250,000 in fund (since 2024)

**How to Apply:**
1. Visa at Hungarian embassy/consulate
2. Residence permit: apply at regional OIF office within 30 days of entry
3. Documents: passport, purpose proof, accommodation, insurance, income proof
4. Fee: HUF 18,000 (residence permit), HUF 50,000 (settlement)
5. Biometric data at OIF office

**Appeal Procedures and Deadlines:**
- **Fellebbezés (Appeal):** 15 days to OIF central (for first instance regional decisions)
  - NOTE: Since 2018, many immigration decisions have NO administrative appeal — direct court
- **Bírósági felülvizsgálat (Judicial review):** 30 days to Közigazgatási és Munkaügyi Bíróság (Administrative and Labor Court, now integrated into Törvényszék)
- Asylum: **8 days** for court review of rejection
  - Border procedure (transit zone) decisions: immediate court review
- Interim measures: court can suspend deportation
- Kúria (Supreme Court): extraordinary review on points of law

**Family Reunification:**
- Sponsor: residence permit for 1+ year
- Family: spouse, minor children, dependent parents
- Income: at least Hungarian minimum wage per month (HUF 266,800 in 2024)
- Housing: adequate
- Health insurance
- Processing: 21-45 days (faster than many EU countries)
- Note: Hungary's transit zone asylum system was ruled illegal by CJEU in 2020

**Work Permit Process:**
- Combined residence + work permit since 2019
- Employer involvement required
- Labor market test: not required for most categories since 2024 reforms
- EU Blue Card: degree + salary 1.5x Hungarian average
- Self-employed: must register company, show adequate capital
- Seasonal: up to 150 days

**Path to Permanent Residence:**
- 3 years continuous legal residence (one of shortest in EU!)
- Hungarian language: not formally required for settlement permit
- Stable income
- Health insurance
- Clean record

**Path to Citizenship:**
- 8 years continuous residence (3 years for spouse of Hungarian citizen, 5 years for refugees)
- Hungarian language: basic conversational (assessed by interview — no formal exam)
- Knowledge of Hungarian Constitution (civics exam)
- Clean criminal record
- Self-sufficient
- Simplified naturalization: available for ethnic Hungarians abroad (many applications from Romania, Serbia, Ukraine)
- Dual citizenship: allowed (since 2011 for ethnic Hungarians)
- Fee: HUF 10,000
- Processing: 3-6 months (faster for simplified)
''';

  // ── BULGARIA (BG) ──────────────────────────────────────────────────────────

  static const String bulgariaImmigration = '''
## BULGARIA — IMMIGRATION PROCEDURES (DETAILED)

**Immigration Authority:**
- Дирекция "Миграция" (Migration Directorate under Ministry of Interior)
- Address: bul. Knyaginya Maria Luiza 114B, Sofia
- Phone: +359 2 982 34 90
- Website: mvr.bg/migration

**Residence Permit Types:**
1. **Разрешение за продължително пребиваване (Extended Stay Permit):** Up to 1 year
2. **Разрешение за дългосрочно пребиваване (Long-Term Residence):** After 5 years
3. **Разрешение за постоянно пребиваване (Permanent Residence):** Ethnic Bulgarians, investors, others
4. **Синя карта на ЕС (EU Blue Card)**
5. **Виза тип D:** Long-stay visa

**How to Apply:**
1. D-visa at Bulgarian embassy
2. Within 14 days of arrival: register at Migration Directorate office
3. Apply for residence permit at regional Migration office
4. Documents: passport, purpose proof, address registration, insurance, income, criminal record
5. Fee: BGN 200-1000 depending on type

**Appeal Procedures and Deadlines:**
- **Administrative appeal:** 14 days to Director of Migration Directorate
- **Court:** 14 days from admin decision to Административен съд (Administrative Court)
- **Касация (Cassation):** 14 days to Върховен административен съд (Supreme Administrative Court - VAS)
- Asylum: 14 days to Administrative Court Sofia-grad
- Expulsion: 14 days to Administrative Court
- Court can suspend execution of deportation

**Family Reunification:**
- Sponsor: extended stay permit for 1+ year
- Family: spouse, minor children, dependent parents
- Income: sufficient means (no fixed amount, assessed case-by-case)
- Housing: adequate

**Work Permit Process:**
- Employer applies at Agentsia po zaetostta (Employment Agency)
- Labor market test required
- EU Blue Card: degree + salary 1.5x average Bulgarian salary
- Seasonal: up to 90 days
- Self-employed: must register business, show investment

**Path to Permanent Residence:**
- 5 years legal residence
- Bulgarian language: not formally tested for residence
- Income and housing adequate
- Ethnic Bulgarians: can get permanent residence directly

**Path to Citizenship:**
- 5 years permanent residence
- Bulgarian language: assessed by interview (no formal test)
- Clean record, income
- Must release previous citizenship (then reacquire after getting Bulgarian)
  - In practice: dual citizenship is common due to reacquisition procedure
- Ethnic Bulgarians: 3 years residence or direct path
- Fee: BGN 100
- Processing: 6-18 months
''';

  // ── CROATIA (HR) ──────────────────────────────────────────────────────────

  static const String croatiaImmigration = '''
## CROATIA — IMMIGRATION PROCEDURES (DETAILED)

**Immigration Authority:**
- Ministarstvo unutarnjih poslova (Ministry of Interior) — Policijska uprava (Police Administration)
- Address: Ilica 335, 10000 Zagreb (Ministry)
- Phone: +385 1 612 2111
- Website: mup.gov.hr

**Residence Permit Types:**
1. **Dozvola za privremeni boravak (Temporary Residence Permit):** 1 year renewable
2. **Dozvola za stalni boravak (Permanent Residence Permit):** After 5 years
3. **EU Blue Card (Plava karta EU)**
4. **Digitalni nomad (Digital Nomad Permit):** 1 year, tax-exempt
5. **Dozvola za boravak i rad (Residence and Work Permit)**

**How to Apply:**
1. Visa at Croatian embassy
2. Apply at local Police Administration office
3. Documents: passport, purpose proof, health insurance, accommodation, income
4. Fee: HRK 350-700 (now EUR 46-93 after Euro adoption Jan 2023)
5. Processing: 30-60 days

**Appeal Procedures and Deadlines:**
- **Žalba (Appeal):** 15 days to Ministry of Interior (through Police Administration)
- **Tužba (Court):** 30 days to Upravni sud (Administrative Court)
- **Žalba Visokom Upravnom Sudu:** 15 days to High Administrative Court
- Asylum: 30 days to Administrative Court
- Interim measures available
- Deportation: appeal within 8 days to Administrative Court in urgent cases

**Family Reunification:**
- Sponsor: temporary residence for 1+ year (or Croatian citizen)
- Family: spouse, minor children, parents (if dependent)
- Income: at least Croatian minimum wage per family member
- Housing: adequate
- Health insurance

**Work Permit Process:**
- Annual quota system for work permits
- Employer applies at Police Administration
- Some categories quota-exempt: highly qualified, seasonal, ICT
- EU Blue Card: degree + salary 1.5x Croatian average
- Self-employed: register company, show business plan
- Digital nomad: no local clients allowed, min income EUR 2539.31/month

**Path to Permanent Residence:**
- 5 years continuous legal residence
- Croatian language: B1 (knowledge of Croatian culture and social system test)
- Income: stable
- Clean record

**Path to Citizenship:**
- 8 years legal residence (5 years for spouse of Croatian citizen)
- Croatian language: B1 proficiency
- Knowledge of Croatian culture and social order
- Clean record
- Must renounce previous citizenship (with bilateral agreement exceptions)
  - Ethnic Croats: simplified path, dual allowed
- Fee: EUR 105
- Processing: 6-24 months
''';

  // ── SLOVAKIA (SK) ──────────────────────────────────────────────────────────

  static const String slovakiaImmigration = '''
## SLOVAKIA — IMMIGRATION PROCEDURES (DETAILED)

**Immigration Authority:**
- Oddelenie cudzineckej polície (Foreign Police Department — under Bureau of Border and Foreign Police)
- Migračný úrad MV SR (Migration Office — for asylum)
- Phone: +421 2 4859 3312 (Foreign Police Bratislava)
- Website: minv.sk

**Residence Permit Types:**
1. **Prechodný pobyt (Temporary Residence):** Employment, business, study, family — 1-5 years
2. **Trvalý pobyt (Permanent Residence):** After 5 years continuous
3. **Tolerovaný pobyt (Tolerated Stay):** Similar to Duldung in Germany
4. **Modrá karta EÚ (EU Blue Card)**
5. **Dlhodobý pobyt (Long-Term Residence - EU):** After 5 years

**How to Apply:**
1. Apply at Slovak embassy or Foreign Police department
2. Documents: passport, purpose proof, accommodation, insurance, clean record, financial proof
3. Fee: EUR 33-232 depending on type
4. Decision within 30-90 days

**Appeal Procedures and Deadlines:**
- **Odvolanie (Appeal):** 15 days to Bureau of Border and Foreign Police (Riaditeľstvo hraničnej a cudzineckej polície)
- **Žaloba (Court):** 2 months to Krajský súd (Regional Court) — administrative section
- **Kasačná sťažnosť:** 1 month to Najvyšší správny súd SR (Supreme Administrative Court)
- Asylum: 30 days to Krajský súd Bratislava
- Deportation: appeal within 15 days
- Interim measures available

**Family Reunification:**
- Sponsor: temporary residence for 1+ year
- Family: spouse, minor children, dependent parents (65+)
- Income: at least Slovak minimum wage (EUR 750/month in 2024) + extra per family member
- Housing: adequate (12 sqm per person)
- Health insurance

**Work Permit Process:**
- Combined temporary residence + work permit since 2018
- Employer files vacancy at labor office for 20 working days (labor market test)
- Exemptions: EU Blue Card, shortage occupations, seasonal
- Self-employed: trade license + business purpose residence
- EU Blue Card: degree + salary 1.5x Slovak average

**Path to Permanent Residence:**
- 5 years continuous legal residence
- Slovak language: A1-A2 (exam at testing center)
- Clean record, income

**Path to Citizenship:**
- 8 years permanent residence (5 years for spouse of Slovak citizen, after 3 years of marriage)
- Slovak language: B1 (exam)
- Knowledge of Slovakia (history, geography, civic exam)
- Clean record
- Dual citizenship: allowed (since 2022 amendment — previously very restricted!)
- Fee: EUR 700
- Processing: 6-24 months
''';

  // ── SLOVENIA (SI) ──────────────────────────────────────────────────────────

  static const String sloveniaImmigration = '''
## SLOVENIA — IMMIGRATION PROCEDURES (DETAILED)

**Immigration Authority:**
- Upravna enota (Administrative Unit) — local offices issue permits
- Ministrstvo za notranje zadeve (Ministry of Interior)
- Phone: +386 1 306 3000
- Website: infotujci.si (portal for foreigners)

**Residence Permit Types:**
1. **Dovoljenje za začasno prebivanje (Temporary Residence Permit):** 1 year renewable
2. **Dovoljenje za stalno prebivanje (Permanent Residence Permit):** After 5 years
3. **Modra karta EU (EU Blue Card)**
4. **Enotno dovoljenje (Single Permit):** Work + residence
5. **Pisna odobritev (Written approval):** For seasonal work

**How to Apply:**
1. Apply at Slovenian embassy or local Administrative Unit
2. Documents: passport, purpose proof, health insurance, accommodation, income
3. Fee: EUR 50-102
4. Processing: 30-60 days

**Appeal Procedures and Deadlines:**
- **Pritožba (Appeal):** 15 days to Ministry of Interior (via Administrative Unit)
- **Tožba (Court):** 30 days to Upravno sodišče RS (Administrative Court of the Republic of Slovenia)
- **Revizija:** Vrhovno sodišče (Supreme Court) — on points of law, leave required
- Asylum: 15 days to Administrative Court
- Court can grant interim measures

**Family Reunification:**
- Sponsor: temporary residence for 1+ year
- Family: spouse, minor children, dependent adult children/parents in exceptional cases
- Income: at least Slovenian minimum wage (EUR 1253.90/month in 2024)
- Housing: adequate
- Health insurance

**Work Permit Process:**
- Single permit (enotno dovoljenje): employer involvement
- Labor market test: Employment Service checks availability for 5 days
- EU Blue Card: degree + salary min EUR 2257/month (2024)
- Self-employed: register company, business plan
- Seasonal: up to 90 days

**Path to Permanent Residence:**
- 5 years continuous legal residence
- Slovenian language: basic (A2, exam at testing center)
- Income, insurance

**Path to Citizenship:**
- 10 years legal residence (5 years permanent + 5 years prior) OR 7 years permanent
- Slovenian language: A2 (certified)
- Clean record
- Renounce previous citizenship (dual citizenship NOT generally allowed)
  - Exceptions: Slovenian ancestry, special merit
- Fee: EUR 191
- Processing: 6-12 months
''';

  // ── PORTUGAL (PT) ──────────────────────────────────────────────────────────

  static const String portugalImmigration = '''
## PORTUGAL — IMMIGRATION PROCEDURES (DETAILED)

**Immigration Authority:**
- AIMA (Agência para a Integração, Migrações e Asilo) — replaced SEF in October 2023
- Address: Rua do Conde Redondo 74, 1169-009 Lisbon
- Phone: +351 808 202 653
- Website: aima.gov.pt
- Online: AIMA portal for scheduling

**Residence Permit Types:**
1. **Autorização de Residência Temporária:** 1-2 years renewable
2. **Autorização de Residência Permanente:** After 5 years
3. **D7 Visa (Passive Income / Retiree):** For people with regular income
4. **D8 Visa (Digital Nomad):** For remote workers, since 2022
5. **Tech Visa:** For tech companies and workers
6. **Startup Visa:** For innovative entrepreneurs
7. **Golden Visa (ARI):** Investment-based — modified in 2023 (real estate excluded in certain areas)
8. **EU Blue Card**
9. **Manifestação de Interesse:** Expression of interest for undocumented workers (being phased out 2024)
10. **CPLP Visa:** For citizens of Portuguese-speaking countries — facilitated process

**How to Apply:**
1. Apply for appropriate visa at Portuguese embassy/consulate
2. After arrival: schedule appointment at AIMA office
3. Apply for residence permit with supporting documents
4. Biometric data collected at AIMA
5. Fee: EUR 83-170 depending on type (visa) + EUR 50-72 (residence card)
6. Processing: historically 3-12 months, currently experiencing major backlogs (12-24+ months)

**Appeal Procedures and Deadlines:**
- **Reclamação (Administrative complaint):** 15 days to AIMA
- **Recurso hierárquico:** 30 days to supervising entity
- **Recurso contencioso:** 3 months to Tribunal Administrativo (Administrative Court)
- Asylum: 8 days to Tribunal Administrativo
- Interim measures (providência cautelar): urgent application to court
- Appeal from Tribunal Administrativo to Tribunal Central Administrativo: 30 days
- Recurso to Supremo Tribunal Administrativo on points of law

**Family Reunification:**
- Sponsor: valid residence permit for 1+ year with renewal prospect
- Family: spouse/partner, minor children, dependent parents, dependent adult children
- Income: at least minimum wage (EUR 820/month in 2024) + 50% per additional adult + 30% per child
- Housing: adequate (certified by municipality or junta de freguesia)
- Portuguese law is relatively liberal on family reunification
- Processing: 3-6 months (but current backlogs affect timing)

**Work Permit Process:**
- No separate work permit — work authorization is part of residence permit
- Employer provides job contract or promissory contract
- IEFP (employment service) labor market test: reduced or eliminated for many categories
- Tech Visa: streamlined for tech sector, no labor market test
- Self-employed: must show adequate income or business viability
- CPLP citizens (Brazil, Angola, Mozambique, etc.): simplified process

**Student Visa Rules:**
- Acceptance at Portuguese educational institution
- Proof of funds: approx EUR 760/month
- Health insurance or SNS access
- Work: part-time allowed
- After graduation: 1-year job-seeking permit
- Student time counts toward permanent residence

**Path to Permanent Residence:**
- 5 years legal residence
- Portuguese language: A2 level
- Clean record
- Stable income

**Path to Citizenship:**
- 5 years legal residence (one of the shortest in EU!)
- Portuguese language: A2 level (very accessible — among easiest in EU)
- Clean record (no conviction for serious crime with 3+ years prison)
- Connection to Portuguese community (assessed broadly)
- Special paths: born in Portugal (1 year parent's residence), married to/partner of Portuguese citizen (3 years)
- CPLP nationals: various facilitations
- Sephardic Jewish descendants: special process (under review since 2022)
- Dual citizenship: fully allowed
- Fee: EUR 175-250
- Processing: 12-24 months (significant backlog since citizenship law liberalization)
''';

  // ── GREECE (GR) ──────────────────────────────────────────────────────────

  static const String greeceImmigration = '''
## GREECE — IMMIGRATION PROCEDURES (DETAILED)

**Immigration Authority:**
- Αποκεντρωμένη Διοίκηση (Decentralized Administration) — regional, issues permits
- Υπηρεσία Ασύλου (Asylum Service) — asylum applications
- Ministry of Migration and Asylum: migration.gov.gr
- Phone: +30 210 998 1000
- Online: applications.migration.gov.gr

**Residence Permit Types:**
1. **Άδεια Διαμονής (Residence Permit):** Employment, study, family — 1-2 years
2. **Άδεια Διαμονής Αόριστης Διάρκειας (Indefinite Residence):** Permanent
3. **EU Blue Card**
4. **Golden Visa:** Real estate investment EUR 250,000-500,000+ (varies by area since 2024)
5. **Digital Nomad Visa:** For remote workers
6. **Seasonal Work Permit**
7. **National D-Visa:** Long stay

**How to Apply:**
1. Visa at Greek embassy/consulate
2. Apply for residence permit at Decentralized Administration (KEP or online)
3. Documents: passport, photos, purpose proof, insurance, income, accommodation
4. Fee: EUR 100-2000 depending on type (Golden Visa: EUR 2000)
5. Biometric data
6. Processing: 2-6 months (backlogs in Athens)

**Appeal Procedures and Deadlines:**
- **Αίτηση θεραπείας (Petition for remedy):** No strict deadline, to issuing authority
- **Ένσταση (Objection):** To Appeals Committee within 30 days
- **Προσφυγή (Court appeal):** 60 days to Διοικητικό Πρωτοδικείο (Administrative Court of First Instance)
- **Έφεση:** 60 days to Διοικητικό Εφετείο (Administrative Court of Appeals)
- **Αναίρεση:** To Συμβούλιο της Επικρατείας (Council of State — Supreme Administrative Court) — points of law
- Asylum: 30 days to Appeals Authority (Epitropi Prosfigon), then 30 days to Administrative Court
- Interim measures: Αναστολή (suspension) can be requested at court

**Family Reunification:**
- Sponsor: 2 years legal residence
- Family: spouse, minor children, dependent parents/in-laws
- Income: at least annual minimum wage + 20% per spouse + 15% per child
- Housing: adequate (verified by police)
- Processing: 3-6 months

**Work Permit Process:**
- Employer-sponsored: invitation from employer + regional labor market assessment
- Annual quotas set by Joint Ministerial Decision (metaklisi system)
- Seasonal: 5-month permits
- EU Blue Card: degree + salary 1.5x Greek average
- Self-employed: investment of EUR 60,000+ and business plan
- Golden Visa holders: can work since 2023 reform

**Path to Permanent Residence:**
- 5 years continuous legal residence
- Income adequate
- Health insurance
- Greek language/culture: tested for 10-year permit but not strictly for initial permanent
- Golden Visa: does NOT count toward permanent residence (no actual residence requirement)

**Path to Citizenship:**
- 7 years legal residence (3 years for spouse of Greek citizen with child, 3 years for recognized refugees)
- Greek language: B1 (Level 3 national exam Pistopoiitiko Elliomathias)
- Civic knowledge test (geography, history, culture, politics)
- Clean record
- Tax compliance
- Dual citizenship: allowed
- Fee: EUR 700
- Processing: 12-24 months (can take up to 3 years in practice)
- Note: children born in Greece to parents with 5 years legal residence can get citizenship
''';

  // ── MALTA (MT) ──────────────────────────────────────────────────────────

  static const String maltaImmigration = '''
## MALTA — IMMIGRATION PROCEDURES (DETAILED)

**Immigration Authority:**
- Identity Malta Agency
- Address: Triq Hal-Luqa, Hal Luqa LQA 1401
- Phone: +356 2590 4800
- Website: identitymalta.com
- Jobsplus: for work licenses

**Residence Permit Types:**
1. **Single Permit (Work + Residence):** Most common for third-country nationals
2. **Long-Term Residence:** After 5 years
3. **Key Employee Initiative (KEI):** Fast track for highly paid workers
4. **Startup Residence Permit**
5. **Highly Qualified Persons (HQP) Scheme:** Tax benefit for financial services, gaming, etc.
6. **Malta Permanent Residence Programme (MPRP):** Investment-based
7. **Malta Citizenship by Naturalisation for Exceptional Services (MEIN):** EUR 600,000-750,000 contribution
8. **Nomad Residence Permit:** For remote workers
9. **EU Blue Card**

**How to Apply:**
1. Apply at Identity Malta or via VFS Global center
2. Single Permit: employer applies at Jobsplus, then Identity Malta
3. Documents: passport, police clearance, health insurance, accommodation, employment
4. Fee: EUR 100-280
5. Processing: 4-8 weeks (KEI: 5 days!)

**Appeal Procedures and Deadlines:**
- **Internal review:** 30 days to Identity Malta
- **Immigration Appeals Board:** 15 days from decision
- **Court appeal:** To First Hall Civil Court within 6 months (judicial review)
- Asylum: Refugee Appeals Board — 15 days
- Constitutional Court for fundamental rights breaches

**Family Reunification:**
- Sponsor: resident for 2+ years
- Family: spouse, minor children
- Income: sufficient (assessed case-by-case)
- Housing: adequate
- Health insurance

**Work Permit Process:**
- Single Permit: employer applies at Jobsplus
- Labor market test: vacancy advertised 14 days
- KEI: salary EUR 30,000+ for non-EU, fast 5-day processing
- Self-employed: separate application with business plan

**Path to Permanent Residence:**
- 5 years continuous legal residence
- Maltese or English language: basic knowledge
- Stable income
- MPRP: investment route — EUR 68,000-98,000 contribution + EUR 50,000 donation + property

**Path to Citizenship:**
- 5 years residence in last 12 years, with 12 months continuous before application
  - OR marriage to Maltese citizen (5 years)
  - OR MEIN scheme (investment)
- Maltese language: basic knowledge (assessed by interview)
  - OR English acceptable given Malta's bilingual status
- Good character
- Dual citizenship: allowed
- Fee: EUR 500 (naturalization) / EUR 600,000+ (MEIN)
- Processing: 12-18 months
''';

  // ── CYPRUS (CY) ──────────────────────────────────────────────────────────

  static const String cyprusImmigration = '''
## CYPRUS — IMMIGRATION PROCEDURES (DETAILED)

**Immigration Authority:**
- Civil Registry and Migration Department (Τμήμα Αρχείου Πληθυσμού και Μετανάστευσης)
- Address: Aristotelous 1-3, 1304 Nicosia
- Phone: +357 22 804 400
- Website: moi.gov.cy/crmd
- Asylum Service: asylumservice.gov.cy

**Residence Permit Types:**
1. **Temporary Residence Permit:** Employment, study, family — 1-4 years
2. **Permanent Residence (Category F):** For third-country nationals — requires investment/income
3. **Immigration Permit:** Long-term settlement
4. **EU Blue Card**
5. **Fast Track Business Permit:** For companies of foreign interest
6. **Pink Slip:** Temporary permit for asylum seekers
7. **EU Long-Term Resident**

**How to Apply:**
1. Visa at Cypriot embassy
2. Apply at District Immigration Office or Civil Registry
3. Documents: passport, police clearance, health certificate, insurance, income
4. Fee: EUR 40-500 depending on type
5. Processing: 1-6 months

**Appeal Procedures and Deadlines:**
- **Ιεραρχική Προσφυγή (Hierarchical appeal):** No strict deadline, to Minister of Interior
- **Αναθεωρητική Αρχή Προσφύγων (Reviewing Authority for Refugees):** For asylum — 25 days
- **Διοικητικό Δικαστήριο (Administrative Court):** 75 days from decision
- **Ανώτατο Δικαστήριο (Supreme Court):** Further appeal on points of law — 42 days
- Interim measures: provisional order from court
- Deportation: can challenge within 75 days at Administrative Court

**Family Reunification:**
- Sponsor: legal residence for 2 years
- Family: spouse, minor children (under 18)
- Income: stable, at least average Cypriot wage
- Housing: adequate
- Health insurance

**Work Permit Process:**
- Employer applies at Department of Labour
- Labor market test: 3-week advertisement for local/EU workers
- Fast Track scheme: for companies registered with Business Facilitation Unit
- EU Blue Card: degree + salary 1.5x Cypriot average gross
- Domestic workers: separate scheme, significant sector in Cyprus

**Path to Permanent Residence:**
- 5 years continuous legal residence
- Category F permanent residence: requires investment (EUR 300,000 property or EUR 30,000/year income from abroad)
- Adequate income, insurance

**Path to Citizenship:**
- 7 years legal residence (5 of which in last 8 years)
  - OR 5 years if married to Cypriot citizen
- Greek language: basic knowledge (interview)
- Knowledge of Cyprus (social, political awareness)
- Clean record
- NOTE: Cyprus Citizenship by Investment scheme suspended since November 2020 (due to scandals)
- Dual citizenship: allowed
- Fee: EUR 500
- Processing: 12-24 months
''';

  // ── LUXEMBOURG (LU) ──────────────────────────────────────────────────────

  static const String luxembourgImmigration = '''
## LUXEMBOURG — IMMIGRATION PROCEDURES (DETAILED)

**Immigration Authority:**
- Direction de l'Immigration (Immigration Directorate — Ministry of Foreign and European Affairs)
- Address: 26, route d'Arlon, L-1140 Luxembourg
- Phone: +352 247-84040
- Website: guichet.lu / maee.gouvernement.lu/fr/directions-du-ministere/immigration.html

**Residence Permit Types:**
1. **Autorisation de Séjour Temporaire:** Temporary — 1-3 years
2. **Titre de Séjour de Résident de Longue Durée:** After 5 years
3. **Carte Bleue Européenne (EU Blue Card):** Highly qualified
4. **Autorisation de Séjour - Salarié:** Employee residence
5. **Autorisation de Séjour - Travailleur indépendant:** Self-employed
6. **Autorisation de Séjour - Etudiant:** Student
7. **Autorisation de Séjour - Regroupement familial:** Family reunification
8. **Autorisation de Séjour - Chercheur:** Researcher
9. **Autorisation de Séjour - Investisseur:** Investor (EUR 500,000+)

**How to Apply:**
1. Apply at Luxembourg embassy with long-stay visa
2. After arrival: register at commune (municipality) within 3 days
3. Apply for residence permit at Direction de l'Immigration
4. Medical examination required
5. Documents: passport, accommodation proof, insurance, employment contract, etc.
6. Fee: EUR 80-100
7. Processing: 3-6 months

**Appeal Procedures and Deadlines:**
- **Recours gracieux:** No strict deadline, to Direction de l'Immigration
- **Recours contentieux:** 3 months to Tribunal Administratif (Administrative Court)
- **Appel:** 40 days to Cour Administrative (Administrative Court of Appeal)
- Asylum: 1 month to Tribunal Administratif
  - Accelerated: 15 days
- Interim measures: référé at Tribunal Administratif
- NOTE: Luxembourg's small size means all administrative courts are in Luxembourg City

**Family Reunification:**
- Sponsor: residence permit for 1+ year with renewal prospect
- Family: spouse, minor children, dependent adult children/parents in exceptional cases
- Income: at least social minimum wage (EUR 2570.93/month in 2024)
  - 120% of social minimum wage for non-EU sponsors
- Housing: adequate for family size
- Processing: 3-6 months

**Work Permit Process:**
- Employer submits declaration to ADEM (Employment Agency) — labor market test
- High shortage: simplified for certain professions
- EU Blue Card: salary EUR 87,843/year (2024 — very high due to Luxembourg wages!)
- Self-employed: business authorization from Ministry of Economy
- Cross-border workers (frontaliers): no permit needed if residing in neighboring country

**Student Visa Rules:**
- Acceptance at Luxembourg educational institution
- Proof of funds: EUR 1200/month
- Health insurance
- Work: max 15 hours/week during term, 40 hours/week during holidays
- After graduation: 9-month job-seeking permit

**Path to Permanent Residence:**
- 5 years continuous legal residence
- Luxembourgish language: A2 oral + B1 understanding (assessed by test)
  - OR: 20 years residence exempts language test
- Adequate income
- Clean record

**Path to Citizenship:**
- 5 years continuous residence (reduced from 7 in 2017)
  - Last year must be in Luxembourg
- Luxembourgish language: A2 speaking + B1 understanding (Sproochentest)
  - OR: lived in Luxembourg for 20 years
- "Living together" course (vivre ensemble) — 24 hours civic education
- Clean record
- Dual citizenship: allowed since 2009
- Fee: EUR 50
- Processing: 6-8 months
- Jus soli: children born in Luxembourg to parents who lived there 12+ months can opt at age 12-18
''';

  // =========================================================================
  // SECTION 2: HEALTHCARE RIGHTS FOR IMMIGRANTS
  // =========================================================================

  static const String healthcareRightsAllCountries = '''
## HEALTHCARE RIGHTS FOR IMMIGRANTS — ALL 27 EU COUNTRIES

### GENERAL EU RULES
- **Emergency healthcare:** All persons present on EU territory have the right to emergency medical treatment regardless of legal status (based on ECHR Art. 3 and national laws)
- **EHIC (European Health Insurance Card):** Covers EU/EEA citizens for medically necessary care in other EU states — NOT for immigrants from third countries
- **Regulation (EC) 883/2004:** Coordinates social security including healthcare between EU member states
- **Asylum seekers:** Reception Conditions Directive 2013/33/EU guarantees access to emergency care and essential treatment of illness/mental disorders

### FINLAND (FI)
- **Emergency care:** Available to ALL persons regardless of status (Terveydenhuoltolaki / Health Care Act)
- **Undocumented:** Emergency care guaranteed; Global Clinic Helsinki provides additional free care
- **Residents with permit:** Full access to public healthcare (terveyskeskus — health center)
- **Asylum seekers:** Basic healthcare through reception centers (vastaanottokeskus)
- **EHIC:** EU citizens covered for necessary care; Kela issues EHIC to Finnish residents
- **Insurance:** Private insurance required for non-EU students; EU citizens can use EHIC
- **Mental health:** Available through public system (mielenterveyspalvelut); long waiting times (4-12 weeks)
- **Cost:** Public healthcare fee EUR 20.90/visit, hospital EUR 49.50/day (capped at EUR 692/year)

### ESTONIA (EE)
- **Emergency care:** Guaranteed to all regardless of status
- **Health insurance:** Through Eesti Haigekassa (Estonian Health Insurance Fund) — tied to employment or residence
- **Uninsured:** Emergency care only; must pay for non-emergency
- **Asylum seekers:** Healthcare through Social Insurance Board
- **Mental health:** Available but limited capacity, especially in rural areas
- **Cost:** Family doctor visits free with insurance; specialist EUR 5 co-pay

### GERMANY (DE)
- **Emergency care:** Available to all — hospitals cannot refuse emergency treatment
- **Asylum seekers:** First 18 months: reduced care under AsylbLG (Asylbewerberleistungsgesetz) — acute illness/pain only; after 18 months: full GKV-equivalent care
- **Residents:** Must have health insurance (Krankenversicherung) — public (GKV) or private (PKV)
- **Undocumented:** Emergency care guaranteed; Clearingstellen (clearing offices) in major cities help access care
- **Mental health:** Covered by health insurance; psychotherapy available but 3-6 month wait
- **Anonymous health certificate (Anonymer Krankenschein):** Available in some cities (Berlin, Hamburg, etc.) for undocumented
- **Cost:** Co-pay EUR 10/quarter for specialist (abolished 2013 actually — most care free with insurance)

### SWEDEN (SE)
- **Emergency care:** Available to all (Lag om halso- och sjukvard at asylsokande m.fl.)
- **Undocumented (papperslosa):** Since 2013: right to subsidized care equivalent to asylum seekers — emergency + care that cannot be delayed + maternal care + care for children
- **Asylum seekers:** LMA card (kort for asylsokande) — subsidized healthcare, EUR 5 equivalent per visit
- **Residents:** Full access via regional healthcare (landsting/region) — personnummer required
- **Mental health:** Available through Vardcentral (health center); crisis lines available
- **Cost:** Max SEK 1300/year for doctor visits (hogkostnadsskydd); SEK 2600 for prescriptions

### FRANCE (FR)
- **Emergency care:** SAMU (15) provides emergency response to all
- **Undocumented:** AME (Aide Medicale de l'Etat) — full healthcare coverage after 3 months in France, free for low income
  - Since 2020 reforms: some limitations on non-urgent hospital care first 9 months
- **Residents with permit:** CPAM / Assurance Maladie — full social security coverage (Securite Sociale)
- **Asylum seekers:** PUMA (Protection Universelle Maladie) + CMU-C (Complementaire Sante Solidaire)
- **Mental health:** CMP (Centre Medico-Psychologique) — free mental health centers in each sector
- **Cost:** 70% covered by Securite Sociale, rest by mutuelle (supplementary insurance)

### ITALY (IT)
- **Emergency care:** Guaranteed to all by Constitution Art. 32 — Pronto Soccorso cannot refuse
- **Undocumented (STP — Straniero Temporaneamente Presente):** STP code grants access to: emergency care, essential treatment, preventive medicine, pregnancy/maternity care, children's care
- **Residents:** SSN (Servizio Sanitario Nazionale) enrollment — Tessera Sanitaria (health card)
- **Asylum seekers:** Full SSN enrollment
- **Mental health:** DSM (Dipartimento Salute Mentale) in each ASL — free
- **Cost:** Ticket (co-pay) for some services EUR 10-36; exempt if low income

### SPAIN (ES)
- **Emergency care:** Available to all (since 2023 reform: Real Decreto-ley 7/2018 restored universal access)
- **Undocumented:** Can register at empadronamiento (municipal register) and after 3 months get Tarjeta Sanitaria
  - Emergency care always available regardless
- **Residents:** Full public healthcare (Sistema Nacional de Salud) — Tarjeta Sanitaria
- **Asylum seekers:** Full healthcare access
- **Mental health:** Through public system; significant regional variation
- **Cost:** Free at point of service; prescription co-pays based on income

### NETHERLANDS (NL)
- **Emergency care:** Available to all
- **Insurance:** Mandatory basic health insurance (basisverzekering) for all residents — approx EUR 130/month
- **Undocumented:** "Stichting Koppeling" and CAK reimbursement scheme — healthcare providers can treat undocumented and claim costs from CAK
- **Asylum seekers:** RMA (Regeling Medische zorg Asielzoekers) — full healthcare via GezondheidsZorg Asielzoekers (GZA)
- **Mental health:** GGZ (Geestelijke GezondheidsZorg) — covered by basic insurance; waiting lists 4-12 weeks
- **Cost:** EUR 385 eigen risico (deductible/year); GP visits free; specialist after deductible

### POLAND (PL)
- **Emergency care:** Available to all (Constitution Art. 68)
- **Insured residents:** NFZ (Narodowy Fundusz Zdrowia) — public insurance through employment
- **Uninsured:** Emergency only through SOR (hospital emergency)
- **Asylum seekers:** Healthcare provided by Office for Foreigners
- **Mental health:** Poradnia Zdrowia Psychicznego — free with NFZ referral; very long waits
- **Cost:** Free with NFZ; private healthcare common due to long public wait times

### ROMANIA (RO)
- **Emergency care:** Guaranteed to all
- **Residents with insurance:** CNAS (Casa Nationala de Asigurari de Sanatate) — through employment
- **Asylum seekers:** Basic healthcare through DSP (Public Health Directorate)
- **Mental health:** Limited availability, especially in rural areas
- **Cost:** Free emergency; co-pays for some services with insurance

### LATVIA (LV)
- **Emergency care:** Available to all
- **Residents:** State-funded healthcare for insured persons (mandatory health insurance contributions)
- **Insurance:** Patient co-payments; quota system for many services
- **Mental health:** Available through state system; limited capacity

### LITHUANIA (LT)
- **Emergency care:** Guaranteed to all
- **PSD (Privalomasis sveikatos draudimas):** Mandatory health insurance for residents
- **Asylum seekers:** Healthcare through reception system
- **Mental health:** Through public system; WHO has noted underfunding

### AUSTRIA (AT)
- **Emergency care:** Available to all
- **Social insurance (Sozialversicherung):** Mandatory for employed persons — OGK, BVAEB, SVS
- **Asylum seekers:** Basic healthcare through Grundversorgung (basic care) system
- **Mindestsicherung recipients:** Full insurance coverage
- **Mental health:** Covered by insurance; psychotherapy partially covered
- **Cost:** E-card needed; small co-pays; EUR 12.70 prescription fee

### BELGIUM (BE)
- **Emergency care:** Available to all (CPAS/OCMW provides Aide Medicale Urgente for undocumented)
- **Insurance:** Mandatory mutualite/ziekenfonds enrollment for residents
- **Asylum seekers:** Fedasil provides healthcare through designated providers
- **Mental health:** Covered by insurance; Centers for Mental Health (CSM/CGG) available
- **Cost:** Partial reimbursement system; low-income: verhoogde tegemoetkoming (increased reimbursement)

### IRELAND (IE)
- **Emergency care:** Available to all at A&E (EUR 100 fee without GP referral, free with Medical Card)
- **Medical Card:** Free GP and hospital care for low-income residents — means-tested
- **GP Visit Card:** Free GP visits, no means test for under-8 and over-70
- **Asylum seekers:** Medical card provided
- **Mental health:** HSE Mental Health Services; crisis: 116 123 (Samaritans)
- **Insurance:** No mandatory insurance; public system + optional private (VHI, Laya, etc.)

### DENMARK (DK)
- **Emergency care:** Available to all
- **Residents (CPR number):** Full access to free public healthcare (sundhedskort / yellow card)
- **Asylum seekers:** Healthcare through Danish Red Cross or operator of asylum center
- **Undocumented:** Emergency only; NGOs provide some additional care
- **Mental health:** Referred through GP; psychiatry covered by regions
- **Cost:** Free for residents; dental partially covered

### CZECH REPUBLIC (CZ)
- **Emergency care:** Available to all
- **Insurance:** Mandatory public health insurance for residents (VZP is largest insurer)
- **Asylum seekers:** Ministry of Interior covers insurance
- **Mental health:** Covered by insurance; reform underway to community-based model

### HUNGARY (HU)
- **Emergency care:** Available to all (Constitution Art. XX)
- **Insurance:** TAJ (social security number) for employed/insured persons
- **Asylum seekers:** Basic healthcare through reception
- **Mental health:** Through public system; underfunded

### BULGARIA (BG)
- **Emergency care:** Available to all
- **NHIF (Natsionalna Zdravnoosiguritelna Kasa):** Health insurance for residents
- **Asylum seekers:** Basic care through State Agency for Refugees
- **Cost:** Low co-pays; many Bulgarians lack insurance due to non-payment

### CROATIA (HR)
- **Emergency care:** Available to all
- **HZZO (Hrvatski zavod za zdravstveno osiguranje):** Mandatory health insurance
- **Asylum seekers:** Healthcare through reception
- **Mental health:** Available but limited rural access

### SLOVAKIA (SK)
- **Emergency care:** Available to all
- **Insurance:** Mandatory (VsZP, Dovera, Union) — employer/employee contributions
- **Asylum seekers:** Healthcare through Migration Office
- **Mental health:** Covered by insurance; psychiatry available

### SLOVENIA (SI)
- **Emergency care:** Available to all
- **ZZZS (Zavod za zdravstveno zavarovanje Slovenije):** Mandatory health insurance
- **Additional voluntary insurance:** Common (covers co-pays) — ~95% of population has it
- **Asylum seekers:** Healthcare provided
- **Cost:** Without voluntary insurance, co-pays can be 10-90%

### PORTUGAL (PT)
- **Emergency care:** Available to all regardless of status
- **SNS (Servico Nacional de Saude):** Universal healthcare for all residents
- **Undocumented:** Since 2001, can access SNS if registered at local health center with atestado de residencia from junta de freguesia
- **Asylum seekers:** Full SNS access
- **Mental health:** Through SNS; INEM for psychiatric emergencies
- **Cost:** Mostly free; small taxas moderadoras (co-pays) EUR 4-18, exempt for many categories

### GREECE (GR)
- **Emergency care:** Available to all
- **AMKA (Social Security Number):** Required for healthcare access
- **PAAYPA (Provisional Number):** For asylum seekers and some third-country nationals — full public healthcare
- **Undocumented:** Emergency care; free care for uninsured and vulnerable
- **Mental health:** Community Mental Health Centers (KMPS); NGOs supplement

### MALTA (MT)
- **Emergency care:** Available to all at Mater Dei Hospital
- **Residents:** Free public healthcare (entitlement based on residence, not insurance)
- **Asylum seekers:** Access to public healthcare
- **Mental health:** Mount Carmel Hospital; community mental health services expanding
- **Cost:** Public healthcare free for residents; private healthcare widely used

### CYPRUS (CY)
- **Emergency care:** Available to all
- **GESY/GHS (General Healthcare System):** Universal since 2019 — for all legal residents
- **Asylum seekers:** Healthcare through reception; free medical card
- **Mental health:** Through GESY; Cyprus Mental Health Services
- **Cost:** Small co-pays with GESY; free for low income

### LUXEMBOURG (LU)
- **Emergency care:** Available to all
- **CNS (Caisse Nationale de Sante):** Social health insurance for residents/workers
- **Asylum seekers:** Full healthcare coverage during procedure
- **Cross-border workers:** Covered by Luxembourg social security
- **Mental health:** Through CNS system; Services de Sante Mentale
- **Cost:** 80-100% reimbursement depending on service; prescription co-pay exists
''';

  // =========================================================================
  // SECTION 3: CHILDREN'S EDUCATION RIGHTS
  // =========================================================================

  static const String childrensEducationRights = '''
## CHILDREN'S EDUCATION RIGHTS — ALL 27 EU COUNTRIES

### EU FRAMEWORK
- **EU Charter of Fundamental Rights Art. 14:** Right to education for everyone
- **UN Convention on the Rights of the Child Art. 28-29:** Right to free primary education; secondary accessible to all
- **Reception Conditions Directive 2013/33/EU Art. 14:** Asylum-seeking children must have access to education within 3 months
- **Anti-Trafficking Directive 2011/36/EU:** Trafficked children have right to education

### KEY PRINCIPLE: In ALL EU countries, children have the right to education REGARDLESS of immigration status of parents

### FINLAND (FI)
- **Compulsory education:** Ages 7-18 (extended to 18 since 2021)
- **Language support:** Finnish/Swedish as second language (S2-opetus); preparatory education (valmistava opetus) for 1 year
- **Enrollment:** Contact local school or municipal education office; no papers required for enrollment
- **Asylum seeker children:** Right to same education as residents
- **Free:** All education free including meals, materials, transport
- **Special support:** Three-tiered support system (yleinen, tehostettu, erityinen tuki)

### ESTONIA (EE)
- **Compulsory education:** Ages 7-17
- **Language support:** Estonian language immersion programs; additional Estonian classes
- **Enrollment:** Register at local school via municipality
- **Free:** Basic education free; school meals free in basic education
- **Language of instruction:** Estonian; Russian-language schools transitioning to Estonian

### GERMANY (DE)
- **Compulsory education (Schulpflicht):** Ages 6-18 (varies by Bundesland); 9-10 years of schooling
- **Language support:** Willkommensklassen (welcome classes) / Vorbereitungsklassen; intensive German (DaZ — Deutsch als Zweitsprache)
- **Enrollment:** At local Grundschule (primary) through Schulamt (school authority)
- **Asylum seeker children:** Schulpflicht applies in most Bundesländer within 3-6 months; some states from day one
- **Free:** Public education free; materials and meals vary by state
- **Note:** Enrollment does NOT trigger immigration enforcement

### SWEDEN (SE)
- **Compulsory education:** Ages 6-16 (förskoleklass mandatory from age 6)
- **Language support:** Svenska som andraspråk (Swedish as second language); studiehandledning pa modersmal (study guidance in mother tongue)
- **Asylum/undocumented children:** Since 2013: right to education same as residents
- **Enrollment:** Contact municipality; schools must accept all children
- **Free:** All education, meals, materials free
- **Mother tongue instruction (modersmalsundervisning):** Available if spoken at home

### FRANCE (FR)
- **Compulsory education (instruction obligatoire):** Ages 3-16 (extended from 6 to 3 in 2019)
- **Language support:** UPE2A (Unite Pedagogique pour Eleves Allophones Arrivants) — dedicated classes
- **Enrollment:** At mairie (town hall), then assigned school
- **Undocumented children:** Full right to education — schools cannot check immigration status
- **Free:** Public education free; canteen fees based on income
- **CASNAV:** Academic centers for newly arrived students

### ITALY (IT)
- **Compulsory education (obbligo di istruzione):** Ages 6-16
- **Language support:** Italian L2 courses; intercultural mediators in many schools
- **Enrollment:** Register at any school; no immigration status check
- **Undocumented children:** Protected by DPR 394/1999 Art. 45 — right to education regardless
- **Free:** Public education free; some material costs
- **Special provision:** Children can self-enroll if parents unable

### SPAIN (ES)
- **Compulsory education (educacion obligatoria):** Ages 6-16
- **Language support:** Aulas de acogida / ATAL (Aulas Temporales de Adaptación Linguistica)
- **Enrollment:** Empadronamiento (municipal registration) sufficient — no residence permit needed
- **Undocumented children:** Full right to education (Ley Organica 4/2000 Art. 9)
- **Free:** Public education free; textbook lending programs in most regions (CCAA)

### NETHERLANDS (NL)
- **Compulsory education (leerplicht):** Ages 5-18 (partial from 16-18)
- **Language support:** NT2 (Nederlands als Tweede Taal) classes; ISK (Internationale Schakelklassen) for ages 12-18
- **Enrollment:** Register at school via municipality; no status check for enrollment
- **Asylum seekers:** COA coordinates education for children in reception
- **Free:** Public education free; parents' contribution for extracurricular voluntary

### POLAND (PL)
- **Compulsory education (obowiazek szkolny):** Ages 7-18 (or completion of gymnasium/liceum)
- **Language support:** Additional Polish lessons (minimum 2 hours/week); preparatory departments
- **Enrollment:** At local school; foreign children have same right as Polish children
- **Free:** Public education free
- **Cultural assistant:** Available in some schools for immigrant children

### ROMANIA (RO)
- **Compulsory education:** Ages 6-16 (planned extension to 18)
- **Language support:** Romanian language courses for foreign children
- **Enrollment:** At local school with basic documentation
- **Free:** Public education free

### LATVIA (LV)
- **Compulsory education:** Ages 5-16
- **Language support:** Latvian language integration programs
- **Enrollment:** Municipal education department
- **Free:** Public education free

### LITHUANIA (LT)
- **Compulsory education:** Ages 6-16
- **Language support:** Lithuanian language classes; integration programs
- **Asylum seeker children:** Education within 3 months of claim
- **Free:** Public education free

### AUSTRIA (AT)
- **Compulsory education (Schulpflicht):** Ages 6-15 (9 years)
- **Language support:** Sprachforderklassen / Sprachstartgruppen (German language start groups)
- **Enrollment:** At local Volksschule; applies to all children living in Austria
- **Free:** Public education free
- **MIKA-D test:** German language assessment for placement

### BELGIUM (BE)
- **Compulsory education:** Ages 5-18
- **Language support:** OKAN (Onthaalklas voor Anderstalige Nieuwkomers) in Flanders; DASPA (Dispositif d'Accueil et de Scolarisation des Primo-Arrivants) in Wallonia
- **Enrollment:** All children must be enrolled regardless of status
- **Free:** Public education free (minimal costs for materials)

### IRELAND (IE)
- **Compulsory education:** Ages 6-16
- **Language support:** EAL (English as Additional Language) support in schools
- **Enrollment:** Apply directly to school; no immigration status check
- **Free:** Primary and secondary education free in public schools
- **Direct Provision children:** Same education rights as citizens

### DENMARK (DK)
- **Compulsory education (undervisningspligt):** Ages 6-16
- **Language support:** Modtagelsesklasser (reception classes); Danish as second language (DSA)
- **Asylum seeker children:** Red Cross/operator provides education in reception; integration into local schools
- **Free:** All education free including materials

### CZECH REPUBLIC (CZ)
- **Compulsory education (povinná školní docházka):** Ages 6-15
- **Language support:** Czech language courses for foreigners (min 200 hours free)
- **Enrollment:** At local school; foreign children have same rights
- **Free:** Public education free

### HUNGARY (HU)
- **Compulsory education (tankötelezettseg):** Ages 3-16 (kindergarten mandatory from 3)
- **Language support:** Hungarian language preparatory year
- **Enrollment:** At local school via KLIK/Tankerulet
- **Free:** Public education free

### BULGARIA (BG)
- **Compulsory education:** Ages 7-16
- **Language support:** Bulgarian language courses for refugee/migrant children
- **Free:** Public education free; challenges in practice for some refugee children

### CROATIA (HR)
- **Compulsory education:** Ages 6-15 (8 years)
- **Language support:** Croatian language preparatory program (min 70 hours)
- **Enrollment:** Through school with basic documents
- **Free:** Public education free

### SLOVAKIA (SK)
- **Compulsory education:** Ages 6-16 (10 years)
- **Language support:** Slovak language courses for foreign pupils
- **Free:** Public education free

### SLOVENIA (SI)
- **Compulsory education:** Ages 6-15 (9 years)
- **Language support:** Slovenian language intensive courses (up to 1 year)
- **Enrollment:** At local school; all children regardless of status
- **Free:** Public education free

### PORTUGAL (PT)
- **Compulsory education:** Ages 6-18
- **Language support:** PLNM (Portugues Lingua Nao Materna) — Portuguese as non-native language
- **Enrollment:** At local school; all children regardless of status (strong tradition of inclusion)
- **Free:** Public education free

### GREECE (GR)
- **Compulsory education:** Ages 5-15
- **Language support:** Reception classes (taxeis ypodochis); ZEP (Zones of Educational Priority)
- **Refugee children:** DYEP (Reception Facilities for Refugee Education) + integration into regular schools
- **Free:** Public education free; challenges with capacity in some areas

### MALTA (MT)
- **Compulsory education:** Ages 5-16
- **Language support:** Induction Hub for migrant students; English/Maltese language support
- **Free:** Public education free
- **Enrollment:** Through school enrollment centers

### CYPRUS (CY)
- **Compulsory education:** Ages 5-15 (planned to extend to 18)
- **Language support:** Greek language integration classes
- **Free:** Public education free

### LUXEMBOURG (LU)
- **Compulsory education:** Ages 4-16
- **Language support:** Extremely multilingual system (Luxembourgish, German, French)
- **CASNA (Cellule d'Accueil Scolaire pour Eleves Nouveaux Arrivants):** Placement assessment for newly arrived children
- **International schools:** Public international schools available (French/English track)
- **Free:** Public education free
''';

  // =========================================================================
  // SECTION 4: DOMESTIC VIOLENCE PROTECTIONS
  // =========================================================================

  static const String domesticViolenceProtections = '''
## DOMESTIC VIOLENCE PROTECTIONS — ALL 27 EU COUNTRIES

### EU & INTERNATIONAL FRAMEWORK
- **Istanbul Convention (Council of Europe):** Ratified by most EU countries — comprehensive framework against gender-based violence
- **EU Victims' Rights Directive 2012/29/EU:** Right to support, protection, and participation in proceedings
- **EU Protection Order Directive 2011/99/EU:** Mutual recognition of protection orders across EU
- **EU Regulation 606/2013:** Civil law protection measures across borders

### CRITICAL: In most EU countries, domestic violence victims (including immigrants) can get INDEPENDENT residence permits

### FINLAND (FI)
- **Emergency Hotline:** 112 (general emergency); Nollalinja 080 005 005 (DV helpline, free, 24/7, multilingual)
- **Protection Orders:** Lahestymiskielto (restraining order) — apply at police or court; immediate temporary order by police
- **Independent Residence Permit:** Section 52a Aliens Act — victim of DV can get residence permit based on personal situation even if relationship (basis for original permit) ended
- **Shelters:** Turvakoti (shelter) — run by Ensi- ja turvakotien liitto; 29 shelters nationwide
  - Contact: turvakoti.fi; 24/7 crisis phone for each location
- **Criminal law:** Assault (pahoinpitely) RL Ch. 21; stalking (vainoaminen) RL Ch. 25 Section 7a
- **Key contact:** Naisten Linja (Women's Line): 0800 02 400 (free, multilingual)

### ESTONIA (EE)
- **Hotline:** 116 006 (victim support, free, 24/7)
- **Protection Orders:** Court can issue restraining order (laheneremiskeeld); immediate protective order by police
- **Shelters:** Naiste Tugikeskused (Women's Support Centers) — in each county
- **Contact:** Ohvriabi (Victim Support): +372 612 4200
- **Independent permit:** Possible under humanitarian grounds

### GERMANY (DE)
- **Hotline:** 08000 116 016 (Hilfetelefon Gewalt gegen Frauen — free, 24/7, 18 languages!)
- **Protection Orders:** Gewaltschutzgesetz (Protection Against Violence Act) — court orders within days
  - Wegweisung (police eviction of perpetrator from shared home) — immediate, in all Bundeslander
- **Independent Residence Permit:** Section 31 AufenthG — after DV, independent right of residence after 1 year of marriage (can be shortened in hardship cases)
- **Shelters:** Frauenhauser — approx 350 nationwide; contact via Hilfetelefon
  - BIG Hotline Berlin: 030 611 03 00
- **Cost:** Shelter stays subsidized through social welfare

### SWEDEN (SE)
- **Hotline:** Kvinnofridslinjen 020-50 50 50 (free, 24/7, interpreters available)
- **Protection Orders:** Kontaktforbud (contact ban) — police/prosecutor; besoksförbud
- **Independent Residence Permit:** Chapter 5, Section 16 Aliens Act — DV victim can retain residence if particularly oppressive situation
- **Shelters:** Kvinnojourer (women's shelters) — approx 200 nationwide; Riksorganisationen för Kvinnojourer (ROKS) and Unizon networks
- **Contact:** Socialtjansten (Social Services) in each municipality
- **BRA (Brottsoffermyndigheten):** Crime Victim Compensation Authority

### FRANCE (FR)
- **Hotline:** 3919 (Violences Femmes Info — free, Mon-Sat, multilingual)
- **Emergency:** 17 (police); SMS 114 (for those who cannot speak)
- **Protection Orders:** Ordonnance de protection — judge must decide within 6 days of request!
  - Telephones Grave Danger (TGD): emergency phone for high-risk victims
- **Independent Residence Permit:** Art. L425-6 CESEDA — DV victim gets residence card "vie privee et familiale" automatically, regardless of complaint filing
- **Shelters:** Centres d'Hebergement — via 115 (SAMU Social) or associations
- **Contact:** CIDFF (Centre d'Information sur les Droits des Femmes et des Familles)

### ITALY (IT)
- **Hotline:** 1522 (Antiviolenza — free, 24/7, multilingual including English, French, Spanish, Arabic, Russian, etc.)
- **Protection Orders:** Ordine di protezione (civil) — judge within 48 hours; Ammonimento del Questore (police warning); allontanamento d'urgenza dalla casa familiare (emergency removal)
- **Independent Residence Permit:** Art. 18-bis TU Immigrazione — special residence permit for DV victims (permesso per violenza domestica), 1 year, work-authorized
- **Shelters:** Case Rifugio and Centri Antiviolenza — approx 350 nationwide
  - Contact via 1522 for nearest center
- **Codice Rosso (Red Code Law, 2019):** Fast-track criminal proceedings for DV cases

### SPAIN (ES)
- **Hotline:** 016 (free, 24/7, 53 languages!) — does NOT appear on phone bill
- **Emergency:** 112; ATENPRO (telematic protection for high-risk victims)
- **Protection Orders:** Orden de Proteccion — judge within 72 hours via Juzgados de Violencia sobre la Mujer (specialized DV courts)
- **Independent Residence Permit:** Ley Organica 1/2004 — DV victims get temporary residence + work authorization; regularization of undocumented victims possible
- **Shelters:** Casas de Acogida — via municipal social services or 016
- **RVD (Valoracion del Riesgo):** Standardized police risk assessment for DV victims
- **VioGen system:** Police monitoring of DV cases (integrated tracking)

### NETHERLANDS (NL)
- **Hotline:** Veilig Thuis 0800 2000 (free, 24/7)
- **Protection Orders:** Huisverbod (temporary domestic ban, 10-28 days) — mayor can order immediately; Straatverbod via court
- **Independent Residence Permit:** Art. 3.51 Vreemdelingenbesluit — independent residence if DV proven (e.g., police report, Veilig Thuis registration, medical evidence)
- **Shelters:** Vrouwenopvang — via Veilig Thuis or municipality
- **Contact:** Fier (national center for violence): +31 88 208 0 000

### POLAND (PL)
- **Hotline:** Niebieska Linia (Blue Line): 800 120 002 (free, 24/7)
- **Protection Orders:** Nakaz natychmiastowego opuszczenia mieszkania (immediate eviction order by police, since 2020); court restraining orders
- **Shelters:** Specjalistyczne Osrodki Wsparcia (Specialist Support Centers) — approx 35 nationwide
  - Domy Samotnej Matki (Single Mother Homes)
- **Independent permit:** Possible under humanitarian grounds; DV recognized as ground for continued stay

### AUSTRIA (AT)
- **Hotline:** Frauenhelpline 0800 222 555 (free, 24/7, multilingual)
- **Protection Orders:** Betretungs- und Annaherungsverbot (ban on entering and approaching) — police order, 14 days, extendable by court
  - Einstweilige Verfugung (interim injunction) by court
- **Independent Residence Permit:** Section 27 NAG — DV victims can get independent residence right
- **Shelters:** Frauenhauser — 30 nationwide; Frauenberatungsstellen (women's counseling)
- **Vienna Women's Emergency Hotline:** 01 71 71 9

### BELGIUM (BE)
- **Hotline:** Ecoute Violences Conjugales 0800 30 030 (French); 1712 (Flemish — violence/abuse line)
- **Protection Orders:** Tijdelijk huisverbod (temporary domestic ban, 14 days) by prosecutor; court orders
- **Independent Residence Permit:** Circular of 2006 + practice: DV victims can get independent residence — social report from CPAS/OCMW supports
- **Shelters:** Maisons d'accueil / Vluchtelingenhuizen — via CPAS or hotline

### IRELAND (IE)
- **Hotline:** Women's Aid Freephone 1800 341 900 (24/7)
- **Protection Orders:** Safety Order (prohibits violence/threats); Barring Order (exclusion from home); Interim Barring Order (emergency)
  - Apply at District Court; free Legal Aid available
- **Independent Residence:** Immigration guidelines allow victims to apply for independent permission — assessed case by case
- **Shelters:** 20+ refuges via Safe Ireland network; contact via Women's Aid

### DENMARK (DK)
- **Hotline:** LOKK (Landsorganisationen af Kvindekrisecentre): 1888 (crisis line)
- **Protection Orders:** Tilhold (restraining order) via police; Bortvisning (eviction from home, 4 weeks)
- **Independent Residence Permit:** Since 2019, improved rules: DV victims can get continued residence if violence is documented
- **Shelters:** Kvindekrisecentre — approx 47 nationwide; free under Serviceloven
- **Contact:** Dialog mod Vold (Dialog Against Violence): counseling for perpetrators and victims

### PORTUGAL (PT)
- **Hotline:** 800 202 148 (free, 24/7, multilingual) — Comissao para a Cidadania e Igualdade de Genero (CIG)
- **Protection Orders:** Medidas de coaccao (judicial); afastamento do agressor; teleassistencia (electronic monitoring)
- **Special DV Victim Status:** Estatuto de Vitima de Violencia Domestica — issued within 48 hours; provides: independent residence right, social benefits, labor protections
- **Independent Residence Permit:** DV victims can get residence regardless of original permit basis
- **Shelters:** Casas de Abrigo — via hotline; APAV (Associacao Portuguesa de Apoio a Vitima): 116 006

### GREECE (GR)
- **Hotline:** 15900 (SOS line, free, 24/7, Greek + English)
- **Protection Orders:** Asfalistika Metra (protective measures) — court order; immediate police measures
- **Shelters:** DIOTIMA; EKKA (National Centre for Social Solidarity): 197; municipal shelters
- **Independent residence:** Possible through humanitarian protection grounds

### OTHER EU COUNTRIES — KEY HOTLINES AND RESOURCES:
- **Czech Republic:** DONA linka: 251 511 313; BKB (Bily Kruh Bezpeci): 116 006
- **Hungary:** NANE Helpline: 06 80 505 101
- **Bulgaria:** Animus Association: +359 2 981 7686; National Hotline: 0800 18 676
- **Croatia:** Autonomna Zenska Kuca: 0800 655 222
- **Slovakia:** National Hotline: 0800 212 212
- **Slovenia:** SOS telefon: 080 11 55 (free)
- **Romania:** ANAIS: 0800 500 333 (free)
- **Malta:** Appogg Support Line: 179 (24/7)
- **Cyprus:** 1440 (Family Violence Line)
- **Luxembourg:** Femmes en detresse: 12 2000; Helpline 8002 11 06
- **Lithuania:** 8 700 55 516
- **Latvia:** Krizu centrs: 116 111 (children); Marta centre: +371 67 378 539
''';

  // =========================================================================
  // SECTION 5: PRACTICAL CONTACTS PER COUNTRY
  // =========================================================================

  static const String practicalContactsAllCountries = '''
## PRACTICAL CONTACTS — ALL 27 EU COUNTRIES

### FINLAND (FI)
- **Police non-emergency:** 0295 419 800
- **Legal Aid Office (Oikeusaputoimisto):** 0295 390 390 (appointment booking)
- **Victim Support (RIKU):** 116 006
- **Anti-discrimination (Yhdenvertaisuusvaltuutettu):** 0295 666 817
- **Immigration (Migri):** +358 295 430 431
- **Free Legal Hotline:** Lakimiesliitto legal advice: various bar associations offer free clinics
- **NGOs:**
  1. Pakolaisneuvonta (Refugee Advice Centre): +358 9 2313 9300
  2. Monikulttuuriyhdistys (Multicultural Associations) — varies by city
  3. Suomen Punainen Risti (Red Cross Finland): 020 701 2000

### ESTONIA (EE)
- **Police non-emergency:** 612 3000
- **Legal Aid:** Riigi oigusabi: via courts or oigusabi.ee
- **Victim Support (Ohvriabi):** 116 006 (24/7)
- **Anti-discrimination (Volinik):** Equality Commissioner: 626 9059
- **Immigration (PPA):** +372 612 3000
- **Free Legal Hotline:** SA Juridicum (legal clinic): +372 631 1551
- **NGOs:**
  1. Estonian Human Rights Centre: +372 644 5148
  2. Johannes Mihkelsoni Keskus (integration): +372 655 1010
  3. Estonian Refugee Council: info@pagulasabi.ee

### GERMANY (DE)
- **Police non-emergency:** 110 (or local Polizeiprasidium)
- **Legal Aid (Beratungshilfe / Prozesskostenhilfe):** Apply at local Amtsgericht
- **Victim Support (Weisser Ring):** 116 006
- **Anti-discrimination (Antidiskriminierungsstelle):** 030 18555 1855
- **Immigration (BAMF):** +49 911 943 0
- **Free Legal Hotline:** Refugee Law Clinics (20+ cities): various local numbers
- **NGOs:**
  1. Pro Asyl: +49 69 242 314 0
  2. AWO (Arbeiterwohlfahrt): various
  3. Caritas Migrationsdienste: various local offices

### SWEDEN (SE)
- **Police non-emergency:** 114 14
- **Legal Aid (Rattshjalpsmyndigheten):** 060-13 31 00
- **Victim Support (Brottsofferjouren):** 0200-21 20 19
- **Anti-discrimination (Diskrimineringsombudsmannen - DO):** 08-120 20 700
- **Immigration (Migrationsverket):** +46 771 235 235
- **Free Legal Hotline:** Various law clinics at universities; Asylrattscentrum: 08-665 57 56
- **NGOs:**
  1. Roda Korset (Red Cross): various
  2. Radsverket: 08-22 06 08
  3. FARR (Swedish Network of Refugee Support Groups): 073-914 40 41

### FRANCE (FR)
- **Police non-emergency:** 17 (police/gendarmerie)
- **Legal Aid (Aide Juridictionnelle):** Apply at Tribunal Judiciaire or Maison de Justice
- **Victim Support (France Victimes):** 116 006 (free, 7 days)
- **Anti-discrimination (Defenseur des droits):** 09 69 39 00 00
- **Immigration (OFII):** +33 1 53 69 53 70
- **Free Legal Hotline:** Points d'Acces au Droit (PAD): varies by city
- **NGOs:**
  1. CIMADE: +33 1 44 18 60 50
  2. France terre d'asile: +33 1 53 04 39 99
  3. Medecins du Monde: +33 1 44 92 15 15

### ITALY (IT)
- **Police non-emergency:** 113 (Polizia), 112 (Carabinieri)
- **Legal Aid (Patrocinio a spese dello Stato):** Apply at Consiglio dell'Ordine degli Avvocati
- **Victim Support:** Telefono Amico: 02 2327 2327; Telefono Azzurro (children): 19696
- **Anti-discrimination (UNAR):** 800 90 10 10 (Contact Center)
- **Immigration:** Local Questura; Patronati (CGIL, CISL, UIL) — free assistance
- **Free Legal Hotline:** ASGI (Associazione Studi Giuridici Immigrazione): info@asgi.it
- **NGOs:**
  1. UNHCR Italy: Rome office
  2. CIR (Consiglio Italiano per i Rifugiati): +39 06 692 00 114
  3. Caritas Italiana: various local offices

### SPAIN (ES)
- **Police non-emergency:** 091 (Policia Nacional), 062 (Guardia Civil)
- **Legal Aid (Justicia Gratuita):** Apply at Colegio de Abogados; Turno de Oficio for foreigners
- **Victim Support:** 116 006 (Atencion a victimas)
- **Anti-discrimination:** Consejo para la Eliminación de la Discriminación: various
- **Immigration (Oficina de Extranjeria):** +34 902 022 222
- **Free Legal Hotline:** CEAR (Comision Espanola de Ayuda al Refugiado): 91 540 10 44
- **NGOs:**
  1. CEAR: +34 91 540 10 44
  2. Red Acoge: +34 91 563 37 79
  3. SOS Racismo: +34 91 559 29 06

### NETHERLANDS (NL)
- **Police non-emergency:** 0900 8844
- **Legal Aid (Rechtsbijstand):** Juridisch Loket: 0900 8020 (EUR 0.25/min)
- **Victim Support (Slachtofferhulp Nederland):** 0900 0101 (free)
- **Anti-discrimination (College Rechten van de Mens):** 030 888 3888
- **Immigration (IND):** +31 88 043 0430
- **Free Legal Hotline:** Juridisch Loket (basic legal advice): 0900 8020
- **NGOs:**
  1. VluchtelingenWerk Nederland: +31 20 346 72 00
  2. ASKV/Refugee Support: +31 20 420 36 22
  3. Defence for Children: +31 71 516 09 80

### POLAND (PL)
- **Police non-emergency:** 997 (police) or 112
- **Legal Aid (Nieodplatna pomoc prawna):** 800 002 229; free legal points in each powiat
- **Victim Support:** 116 006 (Centrum Praw Kobiet)
- **Anti-discrimination (Rzecznik Praw Obywatelskich — RPO):** 800 676 676
- **Immigration (Office for Foreigners):** +48 22 601 74 01
- **Free Legal Hotline:** Halina Niec Legal Aid Centre: +48 12 633 72 23
- **NGOs:**
  1. Helsinki Foundation for Human Rights: +48 22 556 44 40
  2. Stowarzyszenie Interwencji Prawnej (SIP): +48 22 621 51 65
  3. Fundacja Refugee.pl: +48 22 828 42 43

### ROMANIA (RO)
- **Police non-emergency:** 112 (integrated)
- **Legal Aid:** Ajutorul Public Judiciar — apply at court
- **Victim Support:** 116 006
- **Anti-discrimination (CNCD):** +40 21 312 65 78
- **Immigration (IGI):** +40 21 210 22 52
- **NGOs:**
  1. ARCA (Romanian Forum for Refugees): +40 21 310 14 15
  2. Save the Children Romania: +40 21 316 61 76
  3. APADOR-CH: +40 21 312 45 28

### LATVIA (LV)
- **Police non-emergency:** 110
- **Legal Aid:** Juridiskas palidzibas administracija: +371 67 514 208
- **Victim Support:** 116 006
- **Anti-discrimination (Ombudsman):** +371 67 686 768
- **Immigration (PMLP):** +371 67 209 400
- **NGOs:**
  1. Latvian Centre for Human Rights: +371 67 039 290
  2. Shelter "Safe House": +371 67 222 352
  3. Gribu palīdzēt bēgļiem (I Want to Help Refugees)

### LITHUANIA (LT)
- **Police non-emergency:** 112
- **Legal Aid:** Valstybinė garantuojama teisinė pagalba: +370 700 00 211
- **Victim Support:** 116 006
- **Anti-discrimination (Lygiu galimybiu kontrolieriaus tarnyba):** +370 5 261 2728
- **Immigration (Migration Department):** +370 5 271 7112
- **NGOs:**
  1. Lithuanian Red Cross: +370 5 262 8037
  2. Caritas Lithuania: +370 5 212 5952
  3. Refugee Reception Centre: +370 310 67 201

### AUSTRIA (AT)
- **Police non-emergency:** +43 59 133 (or local Polizeiinspektion)
- **Legal Aid (Verfahrenshilfe):** Apply at competent court
- **Victim Support (Weisser Ring Osterreich):** 0800 112 112
- **Anti-discrimination (Gleichbehandlungsanwaltschaft):** 0800 206 119
- **Immigration (BFA):** +43 1 602 55 09 0
- **Free Legal Hotline:** Deserteurs- und Fluchtlingsberatung: +43 1 533 72 71
- **NGOs:**
  1. Diakonie Fluchtlingsdienst: +43 1 402 67 54
  2. Caritas Asyl & Integration: various regional
  3. asylkoordination osterreich: +43 1 532 12 91

### BELGIUM (BE)
- **Police non-emergency:** 101
- **Legal Aid (Aide Juridique):** Bureau d'Aide Juridique at each bar; Pro Deo lawyers
- **Victim Support:** 1712 (Flanders), 0800 30 030 (Wallonia)
- **Anti-discrimination (Unia):** 0800 12 800 (free)
- **Immigration (Office des Etrangers):** +32 2 793 80 00
- **Free Legal Hotline:** CAJ/JAC (juridische eerstelijnsbijstand) via gerechtshuis
- **NGOs:**
  1. CIRÉ (Coordination et Initiatives pour Refugies et Etrangers): +32 2 629 77 10
  2. Vluchtelingenwerk Vlaanderen: +32 2 225 44 00
  3. ADDE (Association pour le Droit des Etrangers): +32 2 227 42 42

### IRELAND (IE)
- **Police (Garda) non-emergency:** +353 1 666 9500 (Dublin); or local station
- **Legal Aid (Legal Aid Board):** 1890 615 200
- **Victim Support (Crime Victims Helpline):** 116 006
- **Anti-discrimination (IHREC):** +353 1 858 9601
- **Immigration (ISD):** +353 1 616 7700
- **Free Legal Hotline:** FLAC (Free Legal Advice Centres): 1890 350 250
- **NGOs:**
  1. Irish Refugee Council: +353 1 764 5854
  2. Migrant Rights Centre Ireland (MRCI): +353 1 889 7570
  3. Doras (Limerick): +353 61 310 328

### DENMARK (DK)
- **Police non-emergency:** 114
- **Legal Aid (Retshjælpen):** Various local retshjælp offices; Retshjælpen i København: +45 33 11 21 55
- **Victim Support (Offerrådet):** 33 92 33 34
- **Anti-discrimination (Institut for Menneskerettigheder):** +45 32 69 88 88
- **Immigration (Udlændingestyrelsen):** +45 72 14 20 00
- **Free Legal Hotline:** Dansk Flygtningehjælp (DRC) legal aid: +45 33 73 50 00
- **NGOs:**
  1. Dansk Flygtningehjælp (Danish Refugee Council): +45 33 73 50 00
  2. Røde Kors (Red Cross Denmark): +45 35 25 92 00
  3. Amnesty International Denmark: +45 33 45 65 65

### CZECH REPUBLIC (CZ)
- **Police non-emergency:** 158 (police), 112 (emergency)
- **Legal Aid:** Apply at court; Czech Bar Association designates lawyer
- **Victim Support:** Bily kruh bezpeci (White Circle of Safety): 116 006
- **Anti-discrimination (Verejny ochranceprav — Ombudsman):** +420 542 542 888
- **Immigration (OAMP):** +420 974 832 421
- **NGOs:**
  1. Organizace pro pomoc uprchlikum (OPU): +420 234 621 484
  2. InBaze: +420 739 037 353
  3. Centrum pro integraci cizincu (CIC): +420 222 713 075

### HUNGARY (HU)
- **Police non-emergency:** 107 or 112
- **Legal Aid (Jogi segitsegnyujtas):** +36 1 795 5673
- **Victim Support (Aldozatsegito Szolgalat):** 06 80 225 225
- **Anti-discrimination (EBH — Equal Treatment Authority, now absorbed into Commissioner for Fundamental Rights):** +36 1 475 7100
- **Immigration (OIF):** +36 1 463 9100
- **NGOs:**
  1. Hungarian Helsinki Committee: +36 1 321 4323 (leading immigration legal aid)
  2. Menedek (Hungarian Association for Migrants): +36 1 322 1502
  3. Cordelia Foundation: +36 1 302 1040

### BULGARIA (BG)
- **Police non-emergency:** 166 or 112
- **Legal Aid (NBPP — National Bureau for Legal Aid):** +359 2 981 03 32
- **Victim Support:** 116 006
- **Anti-discrimination (KZD — Commission for Protection Against Discrimination):** +359 2 807 30 30
- **Immigration (Migration Directorate):** +359 2 982 34 90
- **NGOs:**
  1. Bulgarian Helsinki Committee: +359 2 944 01 45
  2. Bulgarian Lawyers for Human Rights: +359 2 980 39 67
  3. Council of Refugee Women: +359 2 847 35 01

### CROATIA (HR)
- **Police non-emergency:** 192
- **Legal Aid:** Apply at county office
- **Victim Support:** 116 006
- **Anti-discrimination (Pucka pravobraniteljica — Ombudswoman):** +385 1 4851 855
- **Immigration (MUP):** +385 1 612 2111
- **NGOs:**
  1. Croatian Law Centre: +385 1 614 9522
  2. Are You Syrious: volunteer network
  3. Centar za mirovne studije (CMS): +385 1 482 0094

### SLOVAKIA (SK)
- **Police non-emergency:** 158 or 112
- **Legal Aid (Centrum pravnej pomoci):** 0650 105 100
- **Victim Support:** 116 006
- **Anti-discrimination (SNSLP — Slovak National Centre for Human Rights):** +421 2 2082 1711
- **Immigration (Foreign Police):** +421 2 4859 3312
- **NGOs:**
  1. Liga za ludske prava (Human Rights League): +421 2 544 352 37
  2. Slovenská humanitná rada: +421 2 5024 4511
  3. Mareena: +421 948 233 838

### SLOVENIA (SI)
- **Police non-emergency:** 113
- **Legal Aid:** Apply at District Court
- **Victim Support:** 116 006
- **Anti-discrimination (Zagovornik nacela enakosti — Advocate of the Principle of Equality):** +386 1 473 5570
- **Immigration (MNZ):** +386 1 306 3000
- **NGOs:**
  1. PIC — Legal-Informational Centre for NGOs: +386 1 521 18 88
  2. Amnesty International Slovenia: +386 1 426 09 33
  3. Slovenska filantropija: +386 1 430 12 88

### PORTUGAL (PT)
- **Police non-emergency:** PSP 21 765 4242; GNR 213 217 000
- **Legal Aid (Apoio Judiciario):** Apply at Social Security or Ordem dos Advogados
- **Victim Support (APAV):** 116 006 (free, 24/7)
- **Anti-discrimination (CICDR):** 808 80 20 20
- **Immigration (AIMA):** +351 808 202 653
- **Free Legal Hotline:** ACM (Alto Comissariado para as Migracoes): 808 257 257 / SOS Imigrante
- **NGOs:**
  1. Conselho Portugues para os Refugiados (CPR): +351 21 831 4072
  2. JRS Portugal (Jesuit Refugee Service): +351 21 881 4700
  3. Plataforma de Apoio aos Refugiados (PAR)

### GREECE (GR)
- **Police non-emergency:** 100
- **Legal Aid:** Nomiki Voitheia — apply at bar association or court
- **Victim Support:** 116 006; EKKA: 197
- **Anti-discrimination:** Greek Ombudsman (Synigoros tou Politi): +30 213 1306 600
- **Immigration (Asylum Service):** +30 210 998 1000
- **NGOs:**
  1. Greek Council for Refugees (GSR): +30 210 380 0990
  2. UNHCR Greece: +30 210 672 6462
  3. Metadrasi: +30 214 100 8700

### MALTA (MT)
- **Police non-emergency:** 21 224 001 or 119
- **Legal Aid:** Apply at Legal Aid Agency; +356 2590 3265
- **Victim Support (Appogg):** 179 (24/7)
- **Anti-discrimination (NCPE — National Commission for the Promotion of Equality):** +356 2590 3850
- **Immigration (Identity Malta):** +356 2590 4800
- **NGOs:**
  1. aditus foundation: +356 2010 6295
  2. JRS Malta: +356 2144 2751
  3. Integra Foundation: +356 2137 2570

### CYPRUS (CY)
- **Police non-emergency:** 1460
- **Legal Aid:** Apply at court
- **Victim Support:** 1440 (family violence); 116 006
- **Anti-discrimination (Commissioner for Administration and Protection of Human Rights):** +357 22 405 500
- **Immigration (CRMD):** +357 22 804 400
- **NGOs:**
  1. KISA (Equality, Support, Antiracism): +357 22 878 181
  2. Cyprus Refugee Council: +357 22 349 049
  3. UNHCR Cyprus

### LUXEMBOURG (LU)
- **Police non-emergency:** 113 (or +352 244 40 1000)
- **Legal Aid (Assistance Judiciaire):** Apply at Barreau de Luxembourg; +352 46 72 72 1
- **Victim Support (SCAS — Service d'aide aux victimes):** +352 47 58 21
- **Anti-discrimination (CET — Centre pour l'egalite de traitement):** +352 28 37 36 35
- **Immigration (Direction de l'Immigration):** +352 247 84040
- **Free Legal Hotline:** Service Refugees (Caritas/Red Cross): +352 40 21 31
- **NGOs:**
  1. ASTI (Association de Soutien aux Travailleurs Immigres): +352 43 83 33
  2. Caritas Luxembourg: +352 40 21 31
  3. CLAE (Comite de Liaison des Associations d'Etrangers): +352 26 18 58
''';

  // =========================================================================
  // SECTION 6: NATIONAL COURT DECISIONS
  // =========================================================================

  static const String nationalCourtDecisions = '''
## LANDMARK NATIONAL COURT DECISIONS ON IMMIGRATION

### FINLAND — Korkein hallinto-oikeus (KHO / Supreme Administrative Court)

1. **KHO 2022:108** — Family reunification income requirement
   - Rule: Income requirement for family reunification must be assessed proportionally considering Art. 8 ECHR (family life). Mechanical application of income thresholds without individual assessment violates fundamental rights.
   - Impact: Migri must consider individual circumstances, not just numbers.

2. **KHO 2021:153** — Deportation and best interests of child
   - Rule: When deportation affects a child living in Finland, the best interests of the child must be a primary consideration (UN CRC Art. 3). General reference to "public order" insufficient without concrete individual threat assessment.
   - Impact: Higher threshold for deporting parents of children in Finland.

3. **KHO 2019:132** — Sur place refugee claim
   - Rule: Religious conversion after arriving in Finland can constitute genuine basis for asylum if credible. Assessment must examine sincerity of conversion, not just formal acts.
   - Impact: Strengthened protection for converts facing persecution.

4. **KHO 2018:147** — EU citizen deportation
   - Rule: EU citizen cannot be deported solely based on criminal conviction. Must show genuine, present and sufficiently serious threat to public policy. Long residence (12+ years) creates heightened protection under Dir. 2004/38 Art. 28(3).
   - Impact: Very high bar for deporting long-term EU citizen residents.

5. **KHO 2017:99** — Right to be heard in deportation
   - Rule: Failure to properly hear the person in their own language before deportation decision is a fundamental procedural error that invalidates the decision. Written hearing alone insufficient if person has limited literacy.
   - Impact: Reinforced right to oral hearing in deportation cases.

### GERMANY — Bundesverwaltungsgericht (BVerwG / Federal Administrative Court)

1. **BVerwG 1 C 39.19 (2020)** — Subsidiary protection and serious harm
   - Rule: Assessment of serious harm under Section 4 AsylG must consider cumulative effect of multiple threats, even if individual threats do not reach threshold. Situation in country of origin must be assessed at time of court decision, not application.
   - Impact: More holistic assessment of protection needs.

2. **BVerwG 1 C 13.19 (2020)** — Family separation and deportation
   - Rule: Deportation that would separate parent from minor German citizen child violates Art. 6 GG (Basic Law — family protection) unless compelling public interest. Best interests of child require concrete individual assessment.
   - Impact: Strengthened position of parents of German children against deportation.

3. **BVerwG 1 C 2.17 (2018)** — Dublin return and systemic deficiencies
   - Rule: Germany cannot return asylum seekers to other EU states under Dublin III if there are systemic deficiencies in reception conditions amounting to inhuman treatment (Art. 3 ECHR). Applied to returns to Greece and Italy.
   - Impact: Limited Dublin transfers where conditions are inadequate.

4. **BVerwG 1 C 4.16 (2017)** — Duldung and right to work
   - Rule: Long-term Duldung holder (4+ years) with good integration may have claim to residence permit under Section 25a or 25b AufenthG. Administrative inertia in processing does not justify continued precarious status.
   - Impact: Path from toleration to regular status for well-integrated persons.

5. **BVerwG 1 C 45.16 (2018)** — Expulsion interest-balancing
   - Rule: Under reformed Section 53 AufenthG, expulsion requires comprehensive interest-balancing considering all circumstances. Integration achievements, family ties, health issues must be weighed against security concerns. No automatic expulsion for any offense.
   - Impact: Individualized assessment required for every expulsion case.

### FRANCE — Conseil d'Etat (Supreme Administrative Court)

1. **CE, 19 June 2020, No. 434132** — Conditions in country of origin and subsidiary protection
   - Rule: Applicant does not need to demonstrate individual targeting for subsidiary protection — generalized violence in country/region sufficient if intensity is high enough that any civilian faces real risk.
   - Impact: Broader subsidiary protection for persons from high-violence areas.

2. **CE, 31 July 2019, No. 428530** — Retention of undocumented families
   - Rule: Detention of families with children for purposes of removal must be absolute last resort and for shortest possible duration. Alternatives to detention must always be considered first.
   - Impact: Limited immigration detention of families.

3. **CE, 19 November 2020, No. 432752** — OQTF and procedural safeguards
   - Rule: Obligation to Leave French Territory (OQTF) issued without hearing violates right to be heard under EU law (Directive 2008/115). Person must be given genuine opportunity to present observations before return decision.
   - Impact: Procedural protection before removal decisions.

4. **CE, 27 March 2019, No. 424146** — Private and family life (Art. 8 ECHR)
   - Rule: 10 years of continuous residence in France with established social ties creates strong presumption of private life requiring protection under Art. 8 ECHR. Removal after such period requires exceptionally strong justification.
   - Impact: Regularization path for long-term residents.

5. **CE, Ass., 13 November 2020, No. 444940** — COVID and conditions of detention
   - Rule: Conditions in administrative detention centers must comply with health requirements. Systematic detention during pandemic without adequate sanitary measures violates fundamental rights.
   - Impact: Health conditions monitoring in detention.

### SWEDEN — Migrationsoverdomstolen (Migration Court of Appeal)

1. **MIG 2021:8** — Assessment of alternative internal protection
   - Rule: When assessing internal flight alternative, must consider not just safety but also whether person can live a relatively normal life. Access to livelihood, healthcare, and social network must be considered.
   - Impact: Higher standard for internal protection alternative.

2. **MIG 2020:24** — Maintenance requirement and family reunification
   - Rule: Maintenance requirement for family reunification must be applied proportionally. If sponsor narrowly misses income threshold but has stable employment trajectory, rejection may be disproportionate considering child's right to family life.
   - Impact: Flexible application of income requirements.

3. **MIG 2018:20** — Credential assessment and work permits
   - Rule: Requirement that employment conditions match collective agreement standards must consider actual conditions, not just paper terms. Technical non-compliance (e.g., slight variation in insurance coverage) should not automatically lead to permit refusal if overall conditions are adequate.
   - Impact: Reduced technical rejections of work permits.

4. **MIG 2017:6** — Child-specific persecution
   - Rule: Children can have independent grounds for asylum separate from parents. Child-specific forms of persecution (forced marriage, child soldiers, FGM, child labor) must be assessed from child's perspective.
   - Impact: Recognized child-specific asylum grounds.

5. **MIG 2018:5** — New circumstances after final decision
   - Rule: New circumstances that arose after a final negative decision can constitute grounds for new examination under Chapter 12 Section 19 Aliens Act. Burden of proof shifts somewhat if person presents credible new evidence.
   - Impact: Pathway to reopen decided cases.

### NETHERLANDS — Afdeling Bestuursrechtspraak van de Raad van State (ABRvS / Council of State Administrative Jurisdiction Division)

1. **ABRvS 201908382/1/V1 (2020)** — Armenia and group persecution
   - Rule: Membership in a particular social group (e.g., political opposition) can establish refugee status even without individual targeting, if evidence shows systematic persecution of group members.
   - Impact: Group-based persecution recognized more broadly.

2. **ABRvS 201905990/1/V2 (2020)** — Family life and proportionality
   - Rule: Refusal of residence permit for family member violates Art. 8 ECHR where person has children in Netherlands who would be severely impacted by parent's departure. Best interests of children must be specifically assessed with reference to empirical evidence.
   - Impact: Stronger children's rights in family reunification.

3. **ABRvS 201902664/1/V1 (2019)** — Country of origin information
   - Rule: IND cannot rely solely on Ministry of Foreign Affairs country reports (ambtsberichten) if applicant provides contradicting evidence from other credible sources (UNHCR, EASO, NGOs). Court must assess all evidence.
   - Impact: Diversified country of origin evidence.

4. **ABRvS 201808164/1/V2 (2019)** — Dublin and Italy reception
   - Rule: Netherlands cannot transfer asylum seekers to Italy under Dublin III without individual assurances regarding reception conditions, particularly for vulnerable persons (families with children, serious medical conditions).
   - Impact: Individual guarantees required for Dublin transfers.

5. **ABRvS 201903953/1/V3 (2020)** — 1F exclusion and proportionality
   - Rule: Application of Article 1F Refugee Convention (exclusion for serious crimes) must include proportionality assessment under Art. 3 ECHR. If excluded person faces real risk of torture/inhuman treatment upon return, removal is still prohibited.
   - Impact: Non-refoulement overrides exclusion clause.

### ADDITIONAL NOTABLE DECISIONS FROM OTHER COUNTRIES:

**Italy — Corte di Cassazione:**
- **Cass. SU 29459/2019:** Humanitarian protection must consider private life built in Italy and vulnerability upon return. Not limited to health conditions.

**Spain — Tribunal Supremo:**
- **STS 3651/2020:** Arraigo social (social ties) must be assessed holistically — community involvement, language acquisition, and children's schooling are relevant factors for regularization.

**Belgium — Conseil du Contentieux des Etrangers:**
- **CCE No. 247.901 (2021):** Best interests of child in deportation must be assessed concretely, not abstractly. School integration, language development, and social bonds are decisive factors.

**Austria — Verwaltungsgerichtshof:**
- **VwGH Ra 2019/20/0558 (2020):** Long-term residence (10+ years) in Austria creates constitutional protection of private life. Deportation after such period requires truly compelling public safety grounds.

**Poland — Naczelny Sad Administracyjny:**
- **NSA II OSK 1026/17 (2019):** Right to family life cannot be subordinated to procedural requirements when family separation would cause irreparable harm.
''';

  // =========================================================================
  // SECTION 7: PROCESSING TIMES PER COUNTRY
  // =========================================================================

  static const String processingTimesAllCountries = '''
## PROCESSING TIMES — ALL 27 EU COUNTRIES (Approximate, subject to change)

**IMPORTANT NOTE:** Processing times vary significantly based on case complexity, current backlogs, and time of year. These are approximate averages based on most recent available data. Always check the relevant immigration authority's website for current estimates.

### FINLAND (FI)
- **Work-based residence permit:** 2-4 months (specialist/expert: 1-2 months)
- **Student residence permit:** 1-2 months
- **Family reunification:** 9-18 months (significant backlog)
- **Asylum decision (first instance):** 6-12 months
- **Appeal decision (Hallinto-oikeus):** 6-12 months
- **Citizenship:** 12-24 months
- **EU registration:** 1-2 weeks

### ESTONIA (EE)
- **Temporary residence permit:** 2-4 months
- **Short-term work registration:** 10-30 days
- **Student permit:** 1-2 months
- **Family reunification:** 2-4 months
- **Asylum:** 6-12 months
- **Citizenship:** 6-12 months
- **Top specialist (fast track):** 10-30 days

### GERMANY (DE)
- **Work visa / Blue Card:** 1-3 months (consulate) + 4-8 weeks (Auslanderbehorde)
- **Student visa:** 4-8 weeks
- **Family reunification:** 3-12 months (varies enormously by consulate — e.g., 12+ months for some countries)
- **Asylum (BAMF):** 6-18 months (Bundesamt target: 6 months)
- **Appeal (Verwaltungsgericht):** 6-18 months
- **Niederlassungserlaubnis:** 4-8 weeks at Auslanderbehorde (if all conditions met)
- **Citizenship:** 6-24 months (varies hugely by city — Berlin: 2+ years backlog)
- **Blue Card fast-track citizenship:** 21-33 months residence + 3-6 months processing

### SWEDEN (SE)
- **Work permit:** 2-5 months
- **Student permit:** 2-3 months
- **Family reunification:** 12-24 months (severe backlog!)
- **Asylum:** 12-24 months (including potential interview backlog)
- **Appeal (Migrationsdomstol):** 6-12 months
- **Permanent residence:** 10-14 months
- **Citizenship:** 12-36 months (severe backlogs — some applicants wait 3+ years)

### FRANCE (FR)
- **VLS-TS validation:** Online — 1-2 weeks
- **Work-based carte de sejour:** 2-4 months (Passeport Talent: faster)
- **Student visa:** 2-4 weeks (Campus France procedure: 2-3 months total)
- **Family reunification:** 6-12 months (OFII + prefecture)
- **Asylum (OFPRA):** 6-12 months; CNDA appeal: 5-10 months
- **Citizenship:** 12-18 months (decree by Minister)
- **10-year carte de resident:** 2-4 months
- **Prefecture appointment:** 0-6 months wait to even get an appointment (major issue in Paris and large cities!)

### ITALY (IT)
- **Permesso di soggiorno (general):** 2-6 months (legally 60 days, practically longer)
- **Nulla Osta for family reunification:** 90-180 days
- **Asylum (Commissione):** 6-12 months; Court appeal: 6-18 months
- **Citizenship:** 24 months legally; practically 36-48 months
  - Right to diffida after 24 months, then court action after 30 days
- **EU Blue Card:** 2-3 months
- **Long-term resident permit:** 2-4 months (if documents complete)

### SPAIN (ES)
- **Initial residence permit:** 1-3 months (Oficina de Extranjeria, legally 3 months max)
- **Arraigo social:** 3-6 months
- **Family reunification:** 2-6 months
- **Asylum:** 6-18 months (significant backlog — 120,000+ pending)
- **Citizenship:** 12-36 months (historically 2+ years)
- **TIE card issuance:** 30-45 days after permit approval
- **Digital nomad visa:** 20 working days (legally)

### NETHERLANDS (NL)
- **MVV + residence permit (regular):** 3 months (IND target)
- **Highly Skilled Migrant:** 2-4 weeks (fast processing)
- **Student permit:** 2-4 weeks
- **Family reunification:** 3-6 months
- **Asylum (extended procedure):** 6-15 months; bezwaar: 6-12 weeks; beroep: 6-12 months
- **Citizenship:** 6-12 months
- **EU long-term resident:** 5-6 months
- **Startup visa:** 3 months

### POLAND (PL)
- **Temporary residence permit:** 1-2 months (legally); 3-6 months (practically, major backlogs in Warsaw/Krakow)
- **Work declaration (Oswiadczenie):** 7-14 days
- **Family reunification:** 1-3 months
- **Asylum:** 6 months (Office for Foreigners) + appeal 2-3 months
- **Citizenship:** 2-6 months (Presidential procedure)
- **Permanent residence:** 2-4 months
- **Karta Polaka:** 1-3 months

### ROMANIA (RO)
- **Temporary residence permit:** 30-60 days
- **Long-term residence:** 30-60 days
- **Asylum:** 3-6 months
- **Citizenship:** 6-18 months (Citizenship Commission)
- **Work authorization:** 30 days

### LATVIA (LV)
- **Residence permit (standard):** 30 days
- **Residence permit (express):** 5-10 days
- **Asylum:** 3-6 months
- **Citizenship:** 6-12 months

### LITHUANIA (LT)
- **Temporary residence permit:** 2-4 months
- **EU Blue Card:** 1-2 months
- **Asylum:** 6 months
- **Citizenship:** 6 months

### AUSTRIA (AT)
- **Rot-Weiss-Rot Karte:** 2-3 months (legally 8 weeks for key workers)
- **Family reunification:** 3-6 months (subject to annual quota)
- **Student permit:** 2-3 months
- **Asylum (BFA):** 6-18 months; BVwG appeal: 6-12 months
- **Citizenship:** 12-24+ months (varies by Bundesland)
- **Niederlassungsbewilligung:** 2-4 months

### BELGIUM (BE)
- **Single Permit (work + residence):** 4 months (legally); 5-8 months practically
- **Family reunification:** 6-12 months (9 months legal max, often exceeded)
- **Student permit:** 2-3 months
- **Asylum (CGRA):** 6-12 months; CCE appeal: 3-6 months
- **Citizenship:** 4-12 months (commune investigation + prosecutor + State Security)
- **EU Blue Card:** 3-4 months

### IRELAND (IE)
- **Employment permit:** 4-12 weeks (Critical Skills: 4-6 weeks)
- **IRP registration:** Walk-in or appointment — 1-4 weeks
- **Family reunification:** 6-12 months
- **Asylum (IPO):** 6-18 months; IPAT appeal: 3-6 months
- **Citizenship (naturalisation):** 12-23 months
- **Stamp 4 (Long-term):** 4-8 weeks processing

### DENMARK (DK)
- **Work permit (Fast Track):** 1-2 months
- **Work permit (Pay Limit/Positive List):** 1-3 months
- **Student permit:** 1-2 months
- **Family reunification:** 5-10 months
- **Asylum:** 6-18 months; Refugee Board appeal: 3-6 months
- **Permanent residence:** 3-8 months
- **Citizenship:** Granted by law twice/year — total process 6-12 months

### CZECH REPUBLIC (CZ)
- **Employee Card:** 60-90 days (legally 60 days)
- **EU Blue Card:** 30-90 days
- **Student visa:** 60 days
- **Family reunification:** 60-120 days
- **Asylum:** 6-12 months
- **Citizenship:** 6-12 months
- **Permanent residence:** 60-120 days

### HUNGARY (HU)
- **Residence permit:** 21-30 days (one of fastest in EU!)
- **Family reunification:** 21-45 days
- **Asylum:** 2-6 months (very restrictive since 2018)
- **Citizenship:** 3-6 months (simplified: 2-3 months)
- **Settlement permit:** 30-60 days

### BULGARIA (BG)
- **Residence permit:** 30-60 days
- **Long-term residence:** 30-60 days
- **Asylum:** 3-6 months
- **Citizenship:** 6-18 months
- **EU Blue Card:** 30-60 days

### CROATIA (HR)
- **Residence permit:** 30-60 days
- **Digital Nomad:** 30 days
- **Asylum:** 6-12 months
- **Citizenship:** 6-24 months

### SLOVAKIA (SK)
- **Temporary residence:** 30-90 days
- **EU Blue Card:** 30 days
- **Asylum:** 6 months
- **Citizenship:** 6-24 months

### SLOVENIA (SI)
- **Temporary residence:** 30-60 days
- **Single permit:** 30-60 days
- **Asylum:** 6 months
- **Citizenship:** 6-12 months

### PORTUGAL (PT)
- **Visa application:** 30-60 days (consulate)
- **Residence permit (AIMA):** 3-12 months (MASSIVE backlog — 350,000+ pending cases as of 2024!)
- **Golden Visa:** 6-12 months
- **Family reunification:** 3-6 months
- **Asylum:** 6-12 months
- **Citizenship:** 12-24 months (backlog since 2017 law)
- **NOTE:** Portugal's backlog is among the worst in EU — legal action (intimacao) common to force processing

### GREECE (GR)
- **Residence permit:** 2-6 months (backlogs in Athens/Thessaloniki)
- **Golden Visa:** 2-4 months
- **Family reunification:** 3-6 months
- **Asylum (first instance):** 6-12 months (islands faster since EU-Turkey deal)
- **Asylum appeal:** 3-6 months
- **Citizenship:** 12-36 months (significant delays)

### MALTA (MT)
- **Single Permit:** 4-8 weeks
- **KEI (fast track):** 5 days!
- **Family reunification:** 2-4 months
- **Asylum:** 6-12 months
- **Citizenship (naturalisation):** 12-18 months
- **MPRP (investment permanent):** 4-6 months

### CYPRUS (CY)
- **Residence permit:** 1-6 months (backlogs)
- **Fast Track (business):** 1-3 months
- **Family reunification:** 3-6 months
- **Asylum:** 6-18 months (major backlog)
- **Citizenship:** 12-24 months
- **Permanent residence (Category F):** 2-3 months

### LUXEMBOURG (LU)
- **Residence permit:** 3-6 months
- **EU Blue Card:** 3-4 months
- **Student:** 2-3 months
- **Family reunification:** 3-6 months
- **Asylum:** 6-12 months
- **Citizenship:** 6-8 months (relatively efficient)
''';

  // =========================================================================
  // HELPER METHOD: Get all extended knowledge for a country
  // =========================================================================

  /// Returns the immigration section for a given country name (lowercase).
  static String getImmigrationForCountry(String country) {
    final c = country.toLowerCase();
    if (c.contains('finland') || c.contains('suomi') || c == 'fi') return finlandImmigration;
    if (c.contains('estonia') || c.contains('eesti') || c == 'ee') return estoniaImmigration;
    if (c.contains('germany') || c.contains('deutschland') || c == 'de') return germanyImmigration;
    if (c.contains('sweden') || c.contains('sverige') || c == 'se') return swedenImmigration;
    if (c.contains('france') || c == 'fr') return franceImmigration;
    if (c.contains('italy') || c.contains('italia') || c == 'it') return italyImmigration;
    if (c.contains('spain') || c.contains('espana') || c == 'es') return spainImmigration;
    if (c.contains('netherlands') || c.contains('nederland') || c == 'nl') return netherlandsImmigration;
    if (c.contains('poland') || c.contains('polska') || c == 'pl') return polandImmigration;
    if (c.contains('romania') || c == 'ro') return romaniaImmigration;
    if (c.contains('latvia') || c.contains('latvija') || c == 'lv') return latviaImmigration;
    if (c.contains('lithuania') || c.contains('lietuva') || c == 'lt') return lithuaniaImmigration;
    if (c.contains('austria') || c.contains('osterreich') || c == 'at') return austriaImmigration;
    if (c.contains('belgium') || c.contains('belgi') || c == 'be') return belgiumImmigration;
    if (c.contains('ireland') || c == 'ie') return irelandImmigration;
    if (c.contains('denmark') || c.contains('danmark') || c == 'dk') return denmarkImmigration;
    if (c.contains('czech') || c.contains('cesko') || c == 'cz') return czechRepublicImmigration;
    if (c.contains('hungary') || c.contains('magyarorszag') || c == 'hu') return hungaryImmigration;
    if (c.contains('bulgaria') || c == 'bg') return bulgariaImmigration;
    if (c.contains('croatia') || c.contains('hrvatska') || c == 'hr') return croatiaImmigration;
    if (c.contains('slovakia') || c.contains('slovensko') || c == 'sk') return slovakiaImmigration;
    if (c.contains('slovenia') || c.contains('slovenija') || c == 'si') return sloveniaImmigration;
    if (c.contains('portugal') || c == 'pt') return portugalImmigration;
    if (c.contains('greece') || c.contains('ellada') || c == 'gr') return greeceImmigration;
    if (c.contains('malta') || c == 'mt') return maltaImmigration;
    if (c.contains('cyprus') || c.contains('kypros') || c == 'cy') return cyprusImmigration;
    if (c.contains('luxembourg') || c.contains('letzebuerg') || c == 'lu') return luxembourgImmigration;
    return ''; // Unknown country
  }

  /// Returns all extended knowledge sections for a given country.
  /// Useful for building comprehensive system prompts.
  static String getAllForCountry(String country) {
    final sections = <String>[
      getImmigrationForCountry(country),
      healthcareRightsAllCountries,
      childrensEducationRights,
      domesticViolenceProtections,
      practicalContactsAllCountries,
      nationalCourtDecisions,
      processingTimesAllCountries,
    ];
    return sections.where((s) => s.isNotEmpty).join('\n\n---\n\n');
  }

  /// Returns only the country-specific immigration section.
  /// Lighter weight for token-constrained prompts.
  static String getCompactForCountry(String country) {
    return getImmigrationForCountry(country);
  }

  /// List of all 27 EU country codes supported.
  static const List<String> supportedCountryCodes = [
    'FI', 'EE', 'DE', 'SE', 'FR', 'IT', 'ES', 'NL', 'PL', 'RO',
    'LV', 'LT', 'AT', 'BE', 'IE', 'DK', 'CZ', 'HU', 'BG', 'HR',
    'SK', 'SI', 'PT', 'GR', 'MT', 'CY', 'LU',
  ];
}
