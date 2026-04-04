// EU Directives & Regulations Database for Immigrant Rights
// Comprehensive database of ALL EU legal instruments affecting immigrants
// Last updated: 2026-04
//
// Sources: EUR-Lex, European Commission DG HOME, Council of the EU,
// European Parliament Legislative Observatory, ECRE, EUAA,
// FRA (Fundamental Rights Agency), Refworld (UNHCR).
//
// Covers: Immigration & Asylum, Workers' Rights, Anti-Discrimination,
// Victims' Rights, Data Protection, Consumer Protection,
// EU Pact on Migration 2024 (new instruments).

class EUDirective {
  final String number;
  final String name;
  final String shortName;
  final int year;
  final String summary;
  final List<String> keyArticles;
  final String eurLexUrl;
  final List<String> tags;
  final bool isRecast; // true if replaced by newer instrument
  final String? replacedBy; // number of replacing instrument
  final String? appliesFrom; // date when instrument starts applying

  const EUDirective({
    required this.number,
    required this.name,
    required this.shortName,
    required this.year,
    required this.summary,
    required this.keyArticles,
    required this.eurLexUrl,
    required this.tags,
    this.isRecast = false,
    this.replacedBy,
    this.appliesFrom,
  });

  Map<String, dynamic> toMap() {
    return {
      'number': number,
      'name': name,
      'shortName': shortName,
      'year': year,
      'summary': summary,
      'keyArticles': keyArticles,
      'eurLexUrl': eurLexUrl,
      'tags': tags,
      'isRecast': isRecast,
      'replacedBy': replacedBy,
      'appliesFrom': appliesFrom,
    };
  }
}

class EUDirectivesDatabase {
  static final EUDirectivesDatabase _instance =
      EUDirectivesDatabase._internal();
  factory EUDirectivesDatabase() => _instance;
  EUDirectivesDatabase._internal();

  // ============================================================
  // SECTION 1: IMMIGRATION & ASYLUM (Core Directives)
  // ============================================================

  static const List<EUDirective> immigrationAsylum = [
    // --- Qualification ---
    EUDirective(
      number: '2011/95/EU',
      name:
          'Directive on standards for the qualification of third-country nationals or stateless persons as beneficiaries of international protection',
      shortName: 'Qualification Directive (recast)',
      year: 2011,
      summary:
          'Sets common criteria for granting refugee status or subsidiary protection across the EU. '
          'Establishes uniform rights for beneficiaries including residence permits, travel documents, '
          'access to employment, education, social welfare, and healthcare.',
      keyArticles: [
        'Art. 2 — Definitions: refugee, subsidiary protection, family members, unaccompanied minor',
        'Art. 4 — Assessment of facts and circumstances; shared burden of proof between applicant and state',
        'Art. 9 — Acts of persecution: physical/mental violence, legal/administrative/police measures, prosecution for refusal of military service',
        'Art. 10 — Reasons for persecution: race, religion, nationality, political opinion, particular social group',
        'Art. 11 — Cessation of refugee status: voluntary re-availing of country of origin protection',
        'Art. 15 — Serious harm for subsidiary protection: death penalty, torture, serious individual threat from armed conflict',
        'Art. 20-35 — Content of international protection: residence permits (Art. 24), travel documents (Art. 25), access to employment (Art. 26), education (Art. 27), social welfare (Art. 29), healthcare (Art. 30)',
        'Art. 24 — Residence permit: at least 3 years (refugee) or 1 year renewable (subsidiary protection)',
      ],
      eurLexUrl: 'https://eur-lex.europa.eu/eli/dir/2011/95/oj',
      tags: [
        'asylum',
        'refugee',
        'subsidiary_protection',
        'qualification',
        'international_protection',
      ],
      isRecast: true,
      replacedBy: '2024/1347',
      appliesFrom: 'Directive 2011/95/EU repealed from 12 June 2026',
    ),

    // --- NEW: Qualification Regulation 2024 ---
    EUDirective(
      number: '2024/1347',
      name:
          'Regulation on standards for the qualification of third-country nationals or stateless persons as beneficiaries of international protection',
      shortName: 'Qualification Regulation (2024 Pact)',
      year: 2024,
      summary:
          'Replaces Directive 2011/95/EU with a directly applicable regulation. Harmonises qualification '
          'standards across all Member States, eliminating divergent transposition. Establishes uniform '
          'status for refugees and subsidiary protection beneficiaries with strengthened rights.',
      keyArticles: [
        'Art. 4 — Assessment of applications: individual assessment, cooperation duty, credibility assessment',
        'Art. 10 — Acts of persecution: updated to cover digital surveillance and gender-based persecution explicitly',
        'Art. 15 — Serious harm: death penalty/execution, torture, serious individual threat in armed conflict',
        'Art. 19 — Internal protection alternative: strict conditions, meaningful protection must be available',
        'Art. 24 — Residence permits: 3 years for refugees, 1 year (renewable) for subsidiary protection',
        'Art. 26 — Access to employment: equal treatment with nationals, recognition of qualifications facilitated',
        'Art. 29 — Social welfare: equal treatment with nationals for recognised beneficiaries',
        'Art. 30 — Healthcare: same eligibility conditions as nationals',
        'Art. 35 — Status review: regular review of whether conditions for protection still exist',
      ],
      eurLexUrl: 'https://eur-lex.europa.eu/eli/reg/2024/1347/oj',
      tags: [
        'asylum',
        'refugee',
        'subsidiary_protection',
        'qualification',
        'pact_2024',
      ],
      appliesFrom: '1 July 2026',
    ),

    // --- Asylum Procedures ---
    EUDirective(
      number: '2013/32/EU',
      name:
          'Directive on common procedures for granting and withdrawing international protection',
      shortName: 'Asylum Procedures Directive (recast)',
      year: 2013,
      summary:
          'Establishes common procedures for examining applications for international protection. '
          'Sets rules for personal interviews, legal assistance, appeals, and time limits. '
          'Defines safe country concepts and accelerated/border procedures.',
      keyArticles: [
        'Art. 6 — Access to the procedure: right to make an application, registration within 3-6 working days',
        'Art. 12 — Guarantees for applicants: right to interpreter, legal counsel, communication with UNHCR',
        'Art. 14-17 — Personal interview: right to be heard, conditions, absence of interview, report and recording',
        'Art. 20 — Free legal assistance and representation in appeal procedures',
        'Art. 22 — Role of UNHCR: right to access applicants, present views to authorities',
        'Art. 31 — Examination procedure: decision within 6 months (extendable to 21 months)',
        'Art. 33 — Inadmissible applications: first country of asylum, safe third country, subsequent application',
        'Art. 36-38 — Safe country concepts: safe country of origin, safe third country, European safe third country',
        'Art. 46 — Right to an effective remedy: full and ex nunc examination of both facts and points of law',
      ],
      eurLexUrl: 'https://eur-lex.europa.eu/eli/dir/2013/32/oj',
      tags: [
        'asylum',
        'procedures',
        'safe_country',
        'appeal',
        'legal_assistance',
      ],
      isRecast: true,
      replacedBy: '2024/1348',
      appliesFrom: 'Directive 2013/32/EU repealed from 12 June 2026',
    ),

    // --- NEW: Asylum Procedure Regulation 2024 ---
    EUDirective(
      number: '2024/1348',
      name:
          'Regulation establishing a common procedure for international protection in the Union',
      shortName: 'Asylum Procedure Regulation (2024 Pact)',
      year: 2024,
      summary:
          'Replaces Directive 2013/32/EU. Creates directly applicable common asylum procedure. '
          'Introduces mandatory border procedures for applicants from countries with low recognition rates. '
          'Shortens examination timelines and establishes harmonised safe country concepts.',
      keyArticles: [
        'Art. 8 — Registration: within 5 days of making an application (3 days at border)',
        'Art. 9 — Lodging: obligation to lodge within 21 days of registration',
        'Art. 19-22 — Personal interview guarantees: right to interpreter, private hearing, recording',
        'Art. 28 — Examination time limit: 6 months, extendable up to 15 months maximum',
        'Art. 36 — Inadmissible applications: first country of asylum, safe third country',
        'Art. 42 — Accelerated examination procedure: decision within 3 months',
        'Art. 44 — Border procedure: mandatory for nationals of countries with <20% recognition rate, max 12 weeks',
        'Art. 53 — Right to an effective remedy: suspensive effect, time limits for judicial decision',
        'Art. 61-64 — Safe country concepts: EU-wide list of safe countries of origin, safe third country concept',
      ],
      eurLexUrl: 'https://eur-lex.europa.eu/eli/reg/2024/1348/oj',
      tags: [
        'asylum',
        'procedures',
        'border_procedure',
        'safe_country',
        'pact_2024',
      ],
      appliesFrom: '12 June 2026',
    ),

    // --- Reception Conditions ---
    EUDirective(
      number: '2013/33/EU',
      name:
          'Directive laying down standards for the reception of applicants for international protection',
      shortName: 'Reception Conditions Directive (recast)',
      year: 2013,
      summary:
          'Sets minimum standards for reception of asylum seekers including housing, food, clothing, '
          'healthcare, and access to employment. Establishes rules on detention, special needs, '
          'and vulnerable persons including unaccompanied minors.',
      keyArticles: [
        'Art. 2 — Definitions: material reception conditions, detention, applicant with special reception needs',
        'Art. 7 — Residence and freedom of movement: assigned area, reporting obligations',
        'Art. 8-11 — Detention: grounds, guarantees, conditions; detention of vulnerable persons and minors as last resort',
        'Art. 15 — Employment access: within 9 months of lodging application if no first-instance decision',
        'Art. 17-18 — Material reception conditions: housing, food, clothing; adequate standard of living',
        'Art. 19 — Healthcare: emergency care and essential treatment of illness as minimum',
        'Art. 21 — Vulnerable persons: minors, unaccompanied minors, disabled, elderly, pregnant, victims of torture/trafficking',
        'Art. 22-23 — Assessment of special reception needs within reasonable time; best interest of the child',
        'Art. 24 — Unaccompanied minors: representative, family tracing, suitable accommodation',
      ],
      eurLexUrl: 'https://eur-lex.europa.eu/eli/dir/2013/33/oj',
      tags: [
        'asylum',
        'reception',
        'housing',
        'healthcare',
        'detention',
        'vulnerable',
      ],
      isRecast: true,
      replacedBy: '2024/1346',
      appliesFrom: 'Directive 2013/33/EU repealed from 12 June 2026',
    ),

    // --- NEW: Reception Conditions Directive 2024 ---
    EUDirective(
      number: '2024/1346',
      name:
          'Directive laying down standards for the reception of applicants for international protection (recast)',
      shortName: 'Reception Conditions Directive (2024 Pact)',
      year: 2024,
      summary:
          'Replaces Directive 2013/33/EU. Improves reception standards with earlier access to employment '
          '(6 months instead of 9). Strengthens safeguards on detention and introduces clearer rules on '
          'reducing/withdrawing material reception conditions for non-compliance.',
      keyArticles: [
        'Art. 9-13 — Detention: strict grounds, judicial review within 15 days, vulnerable persons protection',
        'Art. 15 — Employment access: within 6 months of lodging (reduced from 9 months)',
        'Art. 17 — Material reception conditions: housing, food, clothing, daily expenses allowance',
        'Art. 19 — Healthcare: at least emergency care and essential treatment; mental health care',
        'Art. 20 — Reduction or withdrawal: for absconding, non-compliance, serious violence, but basic needs always ensured',
        'Art. 22 — Vulnerable persons: enhanced identification mechanism',
        'Art. 25 — Unaccompanied minors: guardian within 15 working days, best interest assessment',
        'Art. 26 — Victims of torture: access to rehabilitation services',
      ],
      eurLexUrl: 'https://eur-lex.europa.eu/eli/dir/2024/1346/oj',
      tags: [
        'asylum',
        'reception',
        'housing',
        'healthcare',
        'detention',
        'pact_2024',
      ],
      appliesFrom: '12 June 2026',
    ),

    // --- Dublin III ---
    EUDirective(
      number: '604/2013',
      name:
          'Regulation establishing the criteria and mechanisms for determining the Member State responsible for examining an application for international protection',
      shortName: 'Dublin III Regulation',
      year: 2013,
      summary:
          'Establishes criteria for determining which EU Member State is responsible for examining '
          'an asylum application. Uses hierarchy: family unity, residence permits/visas, irregular entry, '
          'visa-free entry. Prevents multiple applications across Member States.',
      keyArticles: [
        'Art. 3 — Access to procedure: every application must be examined by a single Member State',
        'Art. 7 — Hierarchy of criteria: applied in the order set out in Chapter III',
        'Art. 8 — Unaccompanied minors: Member State where family member legally present, or where application lodged',
        'Art. 9-11 — Family members: family with beneficiary of international protection, with applicant, dependency',
        'Art. 12 — Residence documents or visas: State that issued valid document is responsible',
        'Art. 13 — Irregular entry: first Member State entered irregularly (responsibility ceases after 12 months)',
        'Art. 17 — Discretionary/sovereignty clause: any State may examine application even if not responsible',
        'Art. 18 — Obligations of the responsible State: take charge / take back the applicant',
        'Art. 27 — Remedies: right to appeal or review transfer decision, suspensive effect',
        'Art. 29 — Transfer time limit: within 6 months (18 months if absconding)',
      ],
      eurLexUrl: 'https://eur-lex.europa.eu/eli/reg/2013/604/oj',
      tags: [
        'asylum',
        'dublin',
        'responsibility',
        'transfer',
        'family_unity',
      ],
      isRecast: true,
      replacedBy: '2024/1351',
      appliesFrom: 'Regulation 604/2013 replaced from 12 June 2026',
    ),

    // --- NEW: Asylum and Migration Management Regulation ---
    EUDirective(
      number: '2024/1351',
      name:
          'Regulation on asylum and migration management',
      shortName: 'Asylum & Migration Management Regulation (AMMR, replaces Dublin III)',
      year: 2024,
      summary:
          'Replaces Dublin III Regulation. Introduces mandatory solidarity mechanism requiring all Member '
          'States to contribute through relocations, financial contributions (EUR 20,000 per person), or '
          'alternative measures. Retains responsibility criteria with modifications.',
      keyArticles: [
        'Art. 7 — Hierarchy of criteria: family unity prioritised, then permits/visas, then irregular entry',
        'Art. 8-16 — Responsibility criteria: minors, family members, diplomas, dependency, documents, entry',
        'Art. 17 — First country of entry: responsible for 20 months (was 12 months in Dublin III)',
        'Art. 33 — Cessation of responsibility: after return, or 15 months outside EU territory',
        'Art. 43-56 — Solidarity mechanism: mandatory annual solidarity pool, relocations, financial contributions',
        'Art. 44 — Solidarity forum: annual assessment of solidarity needs across the Union',
        'Art. 53 — Financial solidarity: EUR 20,000 per person not relocated',
        'Art. 57 — Responsibility offsets: 1:1 offset from relocations performed',
        'Art. 68 — Remedies: right to appeal or review transfer decision within 14 days',
      ],
      eurLexUrl: 'https://eur-lex.europa.eu/eli/reg/2024/1351/oj',
      tags: [
        'asylum',
        'dublin',
        'solidarity',
        'responsibility',
        'relocation',
        'pact_2024',
      ],
      appliesFrom: '12 June 2026',
    ),

    // --- Return Directive ---
    EUDirective(
      number: '2008/115/EC',
      name:
          'Directive on common standards and procedures in Member States for returning illegally staying third-country nationals',
      shortName: 'Return Directive',
      year: 2008,
      summary:
          'Establishes common standards for returning illegally staying third-country nationals. '
          'Requires voluntary departure periods (7-30 days), limits detention to 6 months (max 18), '
          'and provides procedural safeguards including right to appeal and legal aid.',
      keyArticles: [
        'Art. 3 — Definitions: return decision, removal, voluntary departure, entry ban, risk of absconding',
        'Art. 5 — Non-refoulement: best interests of child, family life, state of health',
        'Art. 6 — Return decision: issued to any illegally staying third-country national',
        'Art. 7 — Voluntary departure: 7-30 days, extendable; obligations may be imposed (reporting, deposit)',
        'Art. 9 — Postponement of removal: non-refoulement, suspensive effect of appeal, health, family',
        'Art. 10 — Unaccompanied minors: best interests, return only to family, guardian, or adequate facilities',
        'Art. 11 — Entry ban: maximum 5 years, may exceed for serious threat to public policy/security',
        'Art. 13 — Remedies: right to effective remedy before competent judicial or administrative authority',
        'Art. 14 — Safeguards pending return: family unity, emergency healthcare, education for minors',
        'Art. 15-18 — Detention: last resort, maximum 6 months (extendable to 18), judicial review, conditions',
      ],
      eurLexUrl: 'https://eur-lex.europa.eu/eli/dir/2008/115/oj',
      tags: [
        'return',
        'removal',
        'detention',
        'entry_ban',
        'voluntary_departure',
      ],
    ),

    // --- NEW: Return Border Procedure Regulation ---
    EUDirective(
      number: '2024/1349',
      name:
          'Regulation establishing a return border procedure',
      shortName: 'Return Border Procedure Regulation (2024 Pact)',
      year: 2024,
      summary:
          'Complements the Asylum Procedure Regulation with a return border procedure for applicants '
          'whose applications are rejected in the border procedure. Links asylum and return to ensure '
          'swift return of those not qualifying for international protection.',
      keyArticles: [
        'Art. 1 — Scope: return of third-country nationals whose application was rejected in border procedure',
        'Art. 4 — Return decision: issued immediately after rejection of asylum application in border procedure',
        'Art. 5 — Voluntary departure: period of up to 15 days may be granted',
        'Art. 7 — Removal: carried out as soon as possible, maximum 12 weeks from border procedure',
        'Art. 9 — Detention: permitted to prevent absconding, for a period not exceeding 12 weeks',
        'Art. 10 — Safeguards: emergency healthcare, basic needs, legal assistance, non-refoulement',
      ],
      eurLexUrl: 'https://eur-lex.europa.eu/eli/reg/2024/1349/oj',
      tags: [
        'return',
        'border_procedure',
        'removal',
        'pact_2024',
      ],
      appliesFrom: '12 June 2026',
    ),

    // --- Family Reunification ---
    EUDirective(
      number: '2003/86/EC',
      name: 'Council Directive on the right to family reunification',
      shortName: 'Family Reunification Directive',
      year: 2003,
      summary:
          'Establishes conditions under which third-country nationals residing lawfully in an EU Member '
          'State may exercise the right to family reunification. Covers spouse, minor children, and '
          'sometimes dependent parents. Refugees get more favourable conditions.',
      keyArticles: [
        'Art. 2 — Definitions: sponsor, family reunification, refugee, unaccompanied minor',
        'Art. 3 — Scope: applies to sponsors holding residence permit valid for 1+ year with prospect of permanent residence',
        'Art. 4 — Family members entitled: spouse, minor children (including adopted); may include first-degree relatives in direct ascending line, adult unmarried children',
        'Art. 5 — Submission and evidence: application by sponsor or family member, documents proving family relationship',
        'Art. 7 — Requirements: accommodation, sickness insurance, stable/regular resources (NOT for refugees)',
        'Art. 8 — Waiting period: maximum 2 years (3 years if quota system existed before directive)',
        'Art. 9-12 — Special provisions for refugees: no waiting period, relaxed evidence requirements, unaccompanied minor sponsors may bring parents',
        'Art. 13 — Autonomous residence permit: after maximum 5 years, independent of sponsor (earlier for domestic violence/hardship)',
        'Art. 14 — Rights: access to education, employment, vocational training on same terms as sponsor',
        'Art. 16 — Refusal, withdrawal: fraud, public order/security, actual family relationship ceased',
      ],
      eurLexUrl: 'https://eur-lex.europa.eu/eli/dir/2003/86/oj',
      tags: [
        'family',
        'reunification',
        'spouse',
        'children',
        'refugee',
      ],
    ),

    // --- Long-Term Residents ---
    EUDirective(
      number: '2003/109/EC',
      name:
          'Council Directive concerning the status of third-country nationals who are long-term residents',
      shortName: 'Long-Term Residents Directive',
      year: 2003,
      summary:
          'Grants long-term resident status to third-country nationals who have legally resided in a '
          'Member State for 5 continuous years. Provides near-equal treatment with nationals and the '
          'right to reside in other Member States. Amended by Directive 2011/51/EU to include refugees.',
      keyArticles: [
        'Art. 4 — Duration of residence: 5 years of legal and continuous residence immediately prior to application',
        'Art. 5 — Conditions: stable/regular/sufficient resources, sickness insurance; States may require integration conditions',
        'Art. 7 — Acquisition: long-term resident EC residence permit, valid for at least 5 years, automatically renewable',
        'Art. 8 — Long-term resident EC permit: indicates long-term resident status, issued within 6 months',
        'Art. 9 — Withdrawal/loss: absence from EU for 12+ consecutive months, fraudulent acquisition, expulsion',
        'Art. 11 — Equal treatment: employment, education, social protection, tax benefits, freedom of association, access to goods/services',
        'Art. 12 — Protection against expulsion: only on grounds of serious threat to public policy/security, proportionality, duration of residence, family ties',
        'Art. 14-23 — Right to reside in second Member State: employment, studies, other; may impose integration measures',
      ],
      eurLexUrl: 'https://eur-lex.europa.eu/eli/dir/2003/109/oj',
      tags: [
        'long_term_resident',
        'permanent_residence',
        'equal_treatment',
        'mobility',
      ],
    ),

    // --- Free Movement ---
    EUDirective(
      number: '2004/38/EC',
      name:
          'Directive on the right of citizens of the Union and their family members to move and reside freely within the territory of the Member States',
      shortName: 'Free Movement Directive (Citizens\' Rights)',
      year: 2004,
      summary:
          'Consolidates the right of EU citizens and their family members (including third-country national '
          'family members) to move and reside freely within the EU. Establishes graduated rights based on '
          'duration of stay: up to 3 months, 3 months to 5 years, and permanent residence after 5 years.',
      keyArticles: [
        'Art. 2 — Definitions: family member includes spouse, registered partner, direct descendants under 21 or dependants, dependent direct relatives in ascending line',
        'Art. 5-6 — Right of entry and short stay: up to 3 months with valid passport/ID, no conditions',
        'Art. 7 — Right of residence >3 months: workers, self-employed, students (with insurance + resources), family members',
        'Art. 10 — Residence card for TCN family members: issued within 6 months, valid for 5 years',
        'Art. 12-13 — Retention of right after death/departure of EU citizen or divorce: conditions',
        'Art. 16-18 — Permanent residence: after 5 continuous years of legal residence',
        'Art. 24 — Equal treatment: with nationals of host State in scope of Treaty',
        'Art. 27-33 — Restrictions on grounds of public policy, public security, public health: proportionality, procedural safeguards, expulsion protections (10 years residence = higher threshold)',
        'Art. 35 — Abuse of rights: Member States may refuse, terminate or withdraw rights in case of fraud/abuse',
      ],
      eurLexUrl: 'https://eur-lex.europa.eu/eli/dir/2004/38/oj',
      tags: [
        'free_movement',
        'eu_citizens',
        'family_members',
        'residence',
        'permanent_residence',
      ],
    ),

    // --- Blue Card ---
    EUDirective(
      number: '2021/1883',
      name:
          'Directive on the conditions of entry and residence of third-country nationals for the purpose of highly qualified employment',
      shortName: 'EU Blue Card Directive (revised)',
      year: 2021,
      summary:
          'Revised EU Blue Card for highly qualified workers. Lowers salary threshold (1-1.6x average gross), '
          'reduces minimum contract duration to 6 months, enables intra-EU mobility after 12 months, and '
          'strengthens family rights. Replaces Directive 2009/50/EC.',
      keyArticles: [
        'Art. 2 — Definitions: highly qualified employment, higher professional qualifications, salary threshold',
        'Art. 5 — Admission criteria: valid work contract or binding offer for 6+ months, salary above threshold (1-1.6x average gross)',
        'Art. 7 — Grounds for rejection: public policy/security, fraud, employer sanctions',
        'Art. 9 — EU Blue Card: valid for at least 24 months (or contract duration + 3 months)',
        'Art. 12 — Equal treatment: working conditions, social security, pensions, recognition of qualifications, freedom of association',
        'Art. 13 — Family members: right to accompany/join, access to employment immediately',
        'Art. 15 — Unemployment: 3 months to seek new employment without losing status (6 months after 2 years)',
        'Art. 17 — Long-term resident status: cumulate periods of residence in different Member States',
        'Art. 19-22 — Intra-EU mobility: after 12 months (was 18), short-term mobility (up to 90 days/180) and long-term mobility',
        'Art. 24 — Right to return: re-entry after up to 12 months absence',
      ],
      eurLexUrl: 'https://eur-lex.europa.eu/eli/dir/2021/1883/oj',
      tags: [
        'blue_card',
        'highly_qualified',
        'work',
        'mobility',
        'salary_threshold',
      ],
    ),

    // --- Single Permit ---
    EUDirective(
      number: '2011/98/EU',
      name:
          'Directive on a single application procedure for a single permit for third-country nationals to reside and work',
      shortName: 'Single Permit Directive',
      year: 2011,
      summary:
          'Establishes a single application procedure resulting in one combined work/residence permit. '
          'Ensures equal treatment with nationals in working conditions, social security, tax benefits, '
          'and access to goods and services for third-country workers.',
      keyArticles: [
        'Art. 4 — Single application procedure: one application for both residence and work authorisation',
        'Art. 5 — Competent authority: single authority designated by each Member State',
        'Art. 6 — Single permit: authorises residence and work, format per Regulation 1030/2002',
        'Art. 7 — Procedural time limit: decision within 4 months of complete application',
        'Art. 8 — Procedural guarantees: written notification, reasons for rejection, right to appeal',
        'Art. 12 — Equal treatment: working conditions (pay, dismissal, health & safety), social security branches, tax benefits, access to goods/services, education/vocational training, recognition of qualifications, freedom of association',
      ],
      eurLexUrl: 'https://eur-lex.europa.eu/eli/dir/2011/98/oj',
      tags: [
        'work_permit',
        'single_permit',
        'equal_treatment',
        'workers',
      ],
    ),

    // --- Seasonal Workers ---
    EUDirective(
      number: '2014/36/EU',
      name:
          'Directive on the conditions of entry and stay of third-country nationals for the purpose of employment as seasonal workers',
      shortName: 'Seasonal Workers Directive',
      year: 2014,
      summary:
          'Regulates conditions for entry and stay of third-country nationals for seasonal work (5-9 months '
          'max per 12-month period). Ensures equal treatment in working conditions, accommodation, and '
          'provides protection against exploitation.',
      keyArticles: [
        'Art. 2 — Definitions: seasonal worker, seasonal activity based on recurring events or patterns',
        'Art. 5 — Admission criteria: valid work contract or binding offer, accommodation, health insurance, sufficient resources for return',
        'Art. 12 — Authorisation duration: maximum 5-9 months within any 12-month period (Member State sets limit)',
        'Art. 14 — Facilitated re-entry: procedural facilitation for returning seasonal workers',
        'Art. 16 — Equal treatment: working conditions, pay, minimum working age, health and safety, social security, access to goods/services',
        'Art. 20 — Accommodation: adequate standards, rent proportionate and not deducted from wages automatically',
        'Art. 23 — Sanctions against employers: effective, proportionate, dissuasive penalties for exploitation',
        'Art. 25 — Complaint mechanisms: accessible to seasonal workers, protection against retaliation',
      ],
      eurLexUrl: 'https://eur-lex.europa.eu/eli/dir/2014/36/oj',
      tags: [
        'seasonal_work',
        'agriculture',
        'tourism',
        'exploitation',
        'accommodation',
      ],
    ),

    // --- Students and Researchers ---
    EUDirective(
      number: '2016/801',
      name:
          'Directive on the conditions of entry and residence of third-country nationals for the purposes of research, studies, training, voluntary service, pupil exchange schemes or educational projects and au pairing',
      shortName: 'Students & Researchers Directive',
      year: 2016,
      summary:
          'Consolidates and replaces previous directives on students and researchers. Provides '
          'right to work during studies (minimum 15 hours/week), intra-EU mobility for researchers, '
          'and post-study job-seeking period of at least 9 months.',
      keyArticles: [
        'Art. 7 — General conditions: valid travel document, health insurance, sufficient resources, no threat to public policy/security',
        'Art. 8 — Researchers: hosting agreement with approved research organisation',
        'Art. 11 — Students: admission to higher education institution, proof of fees paid, sufficient resources',
        'Art. 22 — Researchers rights: equal treatment in working conditions, social security, tax benefits, recognition of qualifications',
        'Art. 23 — Student employment: authorised to work at least 15 hours per week',
        'Art. 24-25 — Researcher intra-EU mobility: short-term (up to 180 days) and long-term, with notification',
        'Art. 28 — Job-seeking after completion: at least 9 months to seek employment or set up business',
        'Art. 29-30 — Researcher family members: right to accompany, access to employment',
        'Art. 31 — Procedural guarantee: decision within 90 days, reasons for rejection, right to appeal',
      ],
      eurLexUrl: 'https://eur-lex.europa.eu/eli/dir/2016/801/oj',
      tags: [
        'students',
        'researchers',
        'education',
        'work_during_studies',
        'job_seeking',
        'mobility',
      ],
    ),

    // --- Temporary Protection ---
    EUDirective(
      number: '2001/55/EC',
      name:
          'Council Directive on minimum standards for giving temporary protection in the event of a mass influx of displaced persons',
      shortName: 'Temporary Protection Directive',
      year: 2001,
      summary:
          'Provides immediate temporary protection for displaced persons during mass influx situations. '
          'Activated for Ukrainian refugees in March 2022 (first-ever activation). Grants residence permits, '
          'employment access, housing, social welfare, and education without individual asylum assessment.',
      keyArticles: [
        'Art. 2 — Definitions: temporary protection, mass influx, displaced persons',
        'Art. 4 — Duration: 1 year, automatically renewable by 6-month periods up to max 1 additional year (total max 3 years)',
        'Art. 5 — Activation: Council qualified majority decision on Commission proposal',
        'Art. 6 — Scope: displaced persons described in Council decision',
        'Art. 8 — Residence permits: for entire duration of protection',
        'Art. 12 — Employment: authorised to engage in employed or self-employed activities',
        'Art. 13 — Accommodation/housing: suitable accommodation or means to obtain housing',
        'Art. 14 — Social welfare and means of subsistence',
        'Art. 17 — Right to lodge asylum application: independent of temporary protection',
        'Art. 20-22 — Family reunification: spouse, minor children, close relatives who lived together',
        'Art. 23 — Unaccompanied minors: placed with adult relatives, foster family, or reception centres',
        'Art. 25-26 — Solidarity: balanced effort between Member States (voluntary relocation)',
      ],
      eurLexUrl: 'https://eur-lex.europa.eu/eli/dir/2001/55/oj',
      tags: [
        'temporary_protection',
        'mass_influx',
        'ukraine',
        'emergency',
        'solidarity',
      ],
    ),

    // --- Employers Sanctions ---
    EUDirective(
      number: '2009/52/EC',
      name:
          'Directive providing for minimum standards on sanctions and measures against employers of illegally staying third-country nationals',
      shortName: 'Employers Sanctions Directive',
      year: 2009,
      summary:
          'Prohibits employment of illegally staying third-country nationals and imposes sanctions on '
          'employers. Provides protections for exploited workers including back-pay claims and the '
          'right to complain without risk of deportation in certain cases.',
      keyArticles: [
        'Art. 3 — Prohibition of employment: of illegally staying third-country nationals',
        'Art. 4 — Obligations of employers: verify residence permit before employment, notify authorities',
        'Art. 5 — Financial sanctions: payment of outstanding wages, taxes, social contributions',
        'Art. 6 — Back pay: presumption of at least 3 months employment if duration cannot be established',
        'Art. 9 — Criminal offences: repeated infringements, particularly exploitative conditions, knowingly employing victims of trafficking',
        'Art. 13 — Complaint mechanisms: third-country nationals may lodge complaints directly or through designated third parties',
        'Art. 13(4) — Residence permits: Member States shall define conditions under which they may grant temporary residence permits (linked to Directive 2004/81/EC for trafficking victims)',
        'Art. 14 — Facilitated complaints: obligation to inform workers of their rights',
      ],
      eurLexUrl: 'https://eur-lex.europa.eu/eli/dir/2009/52/oj',
      tags: [
        'employers',
        'sanctions',
        'illegal_employment',
        'exploitation',
        'back_pay',
      ],
    ),

    // --- Intra-Corporate Transferees ---
    EUDirective(
      number: '2014/66/EU',
      name:
          'Directive on the conditions of entry and residence of third-country nationals in the framework of an intra-corporate transfer',
      shortName: 'Intra-Corporate Transferees (ICT) Directive',
      year: 2014,
      summary:
          'Regulates entry and residence for managers, specialists, and trainee employees transferred '
          'from a non-EU branch to an EU branch of the same company. Provides intra-EU mobility rights '
          'and equal treatment in working conditions.',
      keyArticles: [
        'Art. 2 — Definitions: intra-corporate transfer, host entity, manager, specialist, trainee employee',
        'Art. 5 — Admission criteria: employment by same company for 3-12 months prior, professional qualifications',
        'Art. 12 — Duration: max 3 years for managers/specialists, 1 year for trainee employees',
        'Art. 14 — Equal treatment: remuneration, working conditions, health and safety',
        'Art. 16 — Intra-EU mobility: short-term (up to 90 days/180) in any Member State without separate permit',
        'Art. 20-23 — Long-term mobility: notification procedure for stays >90 days in second Member State',
        'Art. 18 — Family rights: family reunification provisions apply, access to employment for family members',
      ],
      eurLexUrl: 'https://eur-lex.europa.eu/eli/dir/2014/66/oj',
      tags: [
        'intra_corporate',
        'transfer',
        'managers',
        'specialists',
        'mobility',
      ],
    ),

    // --- NEW: Screening Regulation ---
    EUDirective(
      number: '2024/1356',
      name:
          'Regulation introducing the screening of third-country nationals at the external borders',
      shortName: 'Screening Regulation (2024 Pact)',
      year: 2024,
      summary:
          'Introduces mandatory screening at external borders for all third-country nationals who do not '
          'meet entry requirements. Includes identity, health, security, and vulnerability checks before '
          'channelling to appropriate procedure (asylum, return, or entry refusal).',
      keyArticles: [
        'Art. 1 — Scope: third-country nationals apprehended at external borders or after disembarkation (SAR)',
        'Art. 5 — Screening: identity verification, health check, security check, vulnerability assessment',
        'Art. 6 — Duration: maximum 5 days at external borders, 3 days for apprehensions within territory',
        'Art. 7 — Health checks: identify immediate health needs and public health risks',
        'Art. 8 — Vulnerability assessment: unaccompanied minors, disabled, pregnant, torture victims, trafficking victims',
        'Art. 9 — Security checks: consultation of relevant databases (SIS, VIS, EES, ECRIS-TCN, Europol)',
        'Art. 10 — De-briefing form: result of screening channelling to asylum or return procedure',
        'Art. 11 — Fundamental rights monitoring: independent mechanism in each Member State',
      ],
      eurLexUrl: 'https://eur-lex.europa.eu/eli/reg/2024/1356/oj',
      tags: [
        'screening',
        'border',
        'identity',
        'health_check',
        'vulnerability',
        'pact_2024',
      ],
      appliesFrom: '12 June 2026',
    ),

    // --- NEW: Eurodac Regulation ---
    EUDirective(
      number: '2024/1358',
      name:
          'Regulation on the establishment of Eurodac for the comparison of biometric data',
      shortName: 'Eurodac Regulation (2024 Pact)',
      year: 2024,
      summary:
          'Recast Eurodac database regulation. Expands from fingerprints to include facial images, '
          'lowers age of collection to 6 years (from 14). Extends to cover all categories of migrants. '
          'Allows law enforcement access. Data retention periods: 10 years (asylum), 5 years (irregular entry).',
      keyArticles: [
        'Art. 1 — Purpose: comparison of biometric data for applying AMMR, resettlement, and identifying illegally staying TCNs',
        'Art. 10-13 — Categories: asylum applicants, irregular border crossers, SAR disembarkations, illegal stayers, resettled persons, temporary protection',
        'Art. 14 — Data collected: fingerprints, facial image, name, date of birth, nationality, document details',
        'Art. 15 — Age: biometric data from persons aged 6 and over (was 14)',
        'Art. 17 — Data retention: 10 years (asylum applicants), 5 years (irregular entry, SAR, illegal stay), 3 years (refused resettlement)',
        'Art. 20 — Law enforcement access: Member States and Europol may compare data for prevention/detection of terrorist and serious criminal offences',
        'Art. 26 — Data protection: supervised by national data protection authorities and European Data Protection Supervisor',
        'Art. 37 — Right of information: data subjects informed of identity of controller, purpose, retention period, right to access/rectify',
      ],
      eurLexUrl: 'https://eur-lex.europa.eu/eli/reg/2024/1358/oj',
      tags: [
        'eurodac',
        'biometric',
        'fingerprint',
        'database',
        'law_enforcement',
        'pact_2024',
      ],
      appliesFrom: '12 June 2026',
    ),

    // --- NEW: Crisis and Force Majeure Regulation ---
    EUDirective(
      number: '2024/1359',
      name:
          'Regulation addressing situations of crisis and force majeure in the field of migration and asylum',
      shortName: 'Crisis & Force Majeure Regulation (2024 Pact)',
      year: 2024,
      summary:
          'Provides temporary derogation measures during migration crises, instrumentalisation, or force '
          'majeure. Allows extended registration and border procedure timelines, triggers enhanced '
          'solidarity obligations, and includes anti-instrumentalisation provisions.',
      keyArticles: [
        'Art. 1 — Scope: crisis, instrumentalisation, and force majeure situations affecting migration/asylum',
        'Art. 2 — Definitions: crisis (mass influx or risk thereof), instrumentalisation (by third countries using migrants as tools)',
        'Art. 4 — Crisis measures: extended registration (up to 4 weeks), extended examination (additional 6 months)',
        'Art. 7 — Instrumentalisation: derogation from asylum procedures, including extended border procedure',
        'Art. 8 — Extended border procedure: up to 18 weeks total (vs 12 weeks normal), broader nationality scope',
        'Art. 9 — Temporary protection option: Council may activate temporary protection under 2001/55/EC',
        'Art. 10 — Force majeure: suspension of obligations when Member State cannot comply (natural disaster, etc.)',
        'Art. 13 — Enhanced solidarity: mandatory relocations and financial contributions increased during crisis',
      ],
      eurLexUrl: 'https://eur-lex.europa.eu/eli/reg/2024/1359/oj',
      tags: [
        'crisis',
        'force_majeure',
        'instrumentalisation',
        'solidarity',
        'emergency',
        'pact_2024',
      ],
      appliesFrom: '12 June 2026',
    ),

    // --- NEW: Resettlement Framework ---
    EUDirective(
      number: '2024/1350',
      name:
          'Regulation establishing a Union Resettlement and Humanitarian Admission Framework',
      shortName: 'EU Resettlement Framework Regulation (2024 Pact)',
      year: 2024,
      summary:
          'Establishes a permanent EU framework for resettlement and humanitarian admission. Creates '
          'legal pathways for persons in need of international protection to be transferred to EU '
          'Member States directly from third countries. Replaces ad hoc resettlement schemes.',
      keyArticles: [
        'Art. 2 — Definitions: resettlement, humanitarian admission, third country of asylum/transit',
        'Art. 4 — Union Resettlement and Humanitarian Admission Plan: adopted every 2 years by Council',
        'Art. 5 — Target number: Council sets total EU number and Member State contributions (voluntary)',
        'Art. 6 — Eligibility: persons referred by UNHCR or identified in third countries, vulnerable categories prioritised',
        'Art. 7 — Exclusion grounds: security threats, serious non-political crimes, acts contrary to UN principles',
        'Art. 8 — Procedure: assessment in third country, security screening, health assessment',
        'Art. 10 — Status granted: refugee status or subsidiary protection upon arrival',
        'Art. 12 — Financial support: from EU Asylum, Migration and Integration Fund',
      ],
      eurLexUrl: 'https://eur-lex.europa.eu/eli/reg/2024/1350/oj',
      tags: [
        'resettlement',
        'humanitarian_admission',
        'legal_pathways',
        'UNHCR',
        'pact_2024',
      ],
      appliesFrom: '12 June 2026',
    ),

    // --- Residence Permit for Trafficking/Smuggling Victims ---
    EUDirective(
      number: '2004/81/EC',
      name:
          'Council Directive on the residence permit issued to third-country nationals who are victims of trafficking in human beings or who have been the subject of an action to facilitate illegal immigration, who cooperate with the competent authorities',
      shortName: 'Residence Permit for Victims Directive',
      year: 2004,
      summary:
          'Grants residence permits to third-country national victims of trafficking or smuggling who '
          'cooperate with authorities. Provides reflection period of at least 30 days, during which '
          'removal is suspended and basic needs are met.',
      keyArticles: [
        'Art. 5 — Information: victims informed of possibilities offered under this Directive',
        'Art. 6 — Reflection period: at least 30 days to recover and decide on cooperation with authorities',
        'Art. 7 — Treatment during reflection: subsistence, emergency medical treatment, psychological assistance, translation/interpretation, free legal aid',
        'Art. 8 — Residence permit: issued if presence is necessary for investigation/judicial proceedings, and victim cooperates; or if necessary on humanitarian grounds',
        'Art. 9 — Non-renewal/withdrawal: if victim ceases cooperation, or public order/security threat',
        'Art. 10 — Treatment with permit: access to labour market, vocational training, education (minors), integration programmes',
        'Art. 11 — Duration: at least 6 months, renewable',
      ],
      eurLexUrl: 'https://eur-lex.europa.eu/eli/dir/2004/81/oj',
      tags: [
        'trafficking',
        'victims',
        'residence_permit',
        'cooperation',
        'reflection_period',
      ],
    ),
  ];

  // ============================================================
  // SECTION 2: WORKERS' RIGHTS
  // ============================================================

  static const List<EUDirective> workersRights = [
    EUDirective(
      number: '2003/88/EC',
      name:
          'Directive concerning certain aspects of the organisation of working time',
      shortName: 'Working Time Directive',
      year: 2003,
      summary:
          'Sets minimum safety and health requirements for working time including maximum 48-hour '
          'working week, minimum rest periods, minimum 4 weeks paid annual leave, and limits on '
          'night work. Applies equally to all workers regardless of nationality.',
      keyArticles: [
        'Art. 3 — Daily rest: minimum 11 consecutive hours rest in every 24-hour period',
        'Art. 4 — Breaks: rest break where working day exceeds 6 hours',
        'Art. 5 — Weekly rest: minimum 24 hours uninterrupted rest per 7-day period (+ 11 hours daily rest)',
        'Art. 6 — Maximum weekly working time: average 48 hours per 7-day period including overtime',
        'Art. 7 — Annual leave: minimum 4 weeks paid annual leave, cannot be replaced by payment except on termination',
        'Art. 8 — Night work: maximum 8 hours per 24-hour period on average; free health assessment',
        'Art. 17 — Derogations: for managing executives, family workers, church workers; by collective agreement for shift work, offshore, etc.',
        'Art. 22 — Opt-out: Member States may allow individual opt-out from 48-hour limit (with worker consent)',
      ],
      eurLexUrl: 'https://eur-lex.europa.eu/eli/dir/2003/88/oj',
      tags: [
        'working_time',
        'rest',
        'annual_leave',
        'night_work',
        'health_safety',
      ],
    ),

    EUDirective(
      number: '2019/1152',
      name:
          'Directive on transparent and predictable working conditions in the European Union',
      shortName: 'Transparent & Predictable Working Conditions Directive',
      year: 2019,
      summary:
          'Requires employers to provide workers with written information about essential aspects of '
          'their employment within 7 days. Establishes minimum rights on probation periods (max 6 months), '
          'parallel employment, training, and predictability of work schedules.',
      keyArticles: [
        'Art. 3-4 — Information obligation: identity of parties, place of work, job title/description, start date, duration, pay, working time, within 7 days (or 1 month for some elements)',
        'Art. 5 — Timing: essential information within first 7 calendar days of employment',
        'Art. 6 — Changes: informed in writing at earliest opportunity and no later than day of effect',
        'Art. 8 — Probationary period: maximum 6 months; proportionate if fixed-term; not repeated for same function',
        'Art. 9 — Parallel employment: employer may not prohibit work for other employers outside schedule',
        'Art. 10 — Minimum predictability: reference hours/days, reasonable notice of work assignments',
        'Art. 13 — Mandatory training: provided free and counted as working time',
        'Art. 14-15 — Collective agreements may adjust certain provisions',
        'Art. 16 — Presumption: in case of missing information, presumption favourable to worker',
        'Art. 17-18 — Remedies: right to redress, protection against adverse treatment and dismissal',
      ],
      eurLexUrl: 'https://eur-lex.europa.eu/eli/dir/2019/1152/oj',
      tags: [
        'working_conditions',
        'transparency',
        'contract',
        'probation',
        'information',
      ],
    ),

    EUDirective(
      number: '2018/957',
      name:
          'Directive amending Directive 96/71/EC concerning the posting of workers in the framework of the provision of services',
      shortName: 'Posted Workers Directive (revised)',
      year: 2018,
      summary:
          'Ensures equal pay for equal work at the same place. Posted workers must receive the same '
          'remuneration (not just minimum rates) as local workers. Posting limited to 12 months '
          '(extendable to 18). Strengthens protection against exploitation of mobile workers.',
      keyArticles: [
        'Art. 1(1) — Core principle: same remuneration as local workers for same work at same place',
        'Art. 1(2)(a) — Remuneration: all elements of pay made mandatory by law or universally applicable collective agreements',
        'Art. 1(2)(b) — Duration limit: after 12 months (extendable to 18 with notification), nearly all host State labour law applies',
        'Art. 1(2)(c) — Accommodation: where employer provides, must meet national standards',
        'Art. 1(2)(d) — Allowances: posting allowances are part of remuneration unless clearly reimbursement of costs',
        'Art. 1(2)(e) — Temporary agency workers: equal treatment conditions apply',
        'Art. 1(3) — Subcontracting chains: Member States may apply same conditions through entire chain',
        'Art. 1(4) — Transport sector: specific provisions (separate directive)',
      ],
      eurLexUrl: 'https://eur-lex.europa.eu/eli/dir/2018/957/oj',
      tags: [
        'posted_workers',
        'equal_pay',
        'cross_border',
        'remuneration',
        'labour_mobility',
      ],
    ),

    EUDirective(
      number: '2006/54/EC',
      name:
          'Directive on the implementation of the principle of equal opportunities and equal treatment of men and women in matters of employment and occupation',
      shortName: 'Gender Equal Treatment Directive (recast)',
      year: 2006,
      summary:
          'Consolidates gender equality directives in employment. Prohibits direct and indirect '
          'discrimination based on sex in access to employment, working conditions, pay, occupational '
          'social security, and provides for reversal of burden of proof.',
      keyArticles: [
        'Art. 2 — Definitions: direct/indirect discrimination, harassment, sexual harassment, instruction to discriminate',
        'Art. 4 — Equal pay: for equal work or work of equal value; all elements of pay',
        'Art. 14 — Non-discrimination: access to employment, promotion, working conditions, dismissal, membership of organisations',
        'Art. 15 — Return from maternity leave: right to return to same or equivalent post, benefit from improvements during absence',
        'Art. 16 — Paternity and adoption leave: protection analogous to maternity leave where Member States recognise such rights',
        'Art. 17 — Defence of rights: judicial and/or administrative procedures',
        'Art. 19 — Burden of proof: shifts to respondent once prima facie case established',
        'Art. 24 — Victimisation: protection against dismissal/adverse treatment for complaining',
        'Art. 25 — Penalties: effective, proportionate, dissuasive; may include compensation',
      ],
      eurLexUrl: 'https://eur-lex.europa.eu/eli/dir/2006/54/oj',
      tags: [
        'gender_equality',
        'equal_pay',
        'discrimination',
        'employment',
        'burden_of_proof',
      ],
    ),

    EUDirective(
      number: '2019/1158',
      name:
          'Directive on work-life balance for parents and carers',
      shortName: 'Work-Life Balance Directive',
      year: 2019,
      summary:
          'Establishes minimum requirements for paternity leave (10 days), parental leave (4 months, '
          '2 non-transferable), and carers\' leave (5 days/year). Provides right to request flexible '
          'working arrangements. Applies to all workers regardless of nationality.',
      keyArticles: [
        'Art. 4 — Paternity leave: minimum 10 working days around the time of birth, compensated at sick pay level minimum',
        'Art. 5 — Parental leave: 4 months per parent per child; 2 months non-transferable; until child is 8; compensated at adequate level',
        'Art. 6 — Carers\' leave: 5 working days per year for personal care of relative/household member with serious medical reason',
        'Art. 7 — Time off for force majeure: urgent family reasons',
        'Art. 8 — Adequate compensation: payment at least at sick pay level for paternity and non-transferable parental leave',
        'Art. 9 — Flexible working: right to request for caring purposes; employer must respond within reasonable time, justify any refusal',
        'Art. 10 — Employment rights: return to same/equivalent post, acquired rights maintained',
        'Art. 11 — Non-discrimination: no less favourable treatment for exercising rights under this Directive',
        'Art. 12 — Protection from dismissal: prohibited on grounds of exercising leave or flexible working rights',
      ],
      eurLexUrl: 'https://eur-lex.europa.eu/eli/dir/2019/1158/oj',
      tags: [
        'work_life_balance',
        'paternity_leave',
        'parental_leave',
        'carers_leave',
        'flexible_working',
      ],
    ),
  ];

  // ============================================================
  // SECTION 3: ANTI-DISCRIMINATION
  // ============================================================

  static const List<EUDirective> antiDiscrimination = [
    EUDirective(
      number: '2000/43/EC',
      name:
          'Council Directive implementing the principle of equal treatment between persons irrespective of racial or ethnic origin',
      shortName: 'Racial Equality Directive',
      year: 2000,
      summary:
          'Prohibits discrimination based on racial or ethnic origin in employment, education, social '
          'protection, healthcare, and access to goods and services including housing. Broadest scope '
          'of all EU anti-discrimination directives. Critical for immigrant protection.',
      keyArticles: [
        'Art. 2 — Concept of discrimination: direct, indirect discrimination, harassment, instruction to discriminate',
        'Art. 3 — Scope: employment, self-employment, education, social protection (incl. social security & healthcare), social advantages, access to goods/services including housing',
        'Art. 4 — Genuine occupational requirement: narrow exception where characteristic is genuine and determining',
        'Art. 5 — Positive action: measures to prevent/compensate for disadvantages linked to racial/ethnic origin',
        'Art. 7 — Defence of rights: judicial/administrative procedures, including after employment ends',
        'Art. 8 — Burden of proof: shifts to respondent once prima facie case established',
        'Art. 9 — Victimisation: protection against adverse treatment for complainants and witnesses',
        'Art. 11 — Social dialogue: encouragement of agreements laying down anti-discrimination rules',
        'Art. 13 — Equality bodies: designation of independent bodies to assist victims, conduct surveys, publish reports',
      ],
      eurLexUrl: 'https://eur-lex.europa.eu/eli/dir/2000/43/oj',
      tags: [
        'racial_equality',
        'ethnic_origin',
        'discrimination',
        'housing',
        'services',
        'education',
      ],
    ),

    EUDirective(
      number: '2000/78/EC',
      name:
          'Council Directive establishing a general framework for equal treatment in employment and occupation',
      shortName: 'Employment Equality Directive',
      year: 2000,
      summary:
          'Prohibits discrimination in employment based on religion or belief, disability, age, or '
          'sexual orientation. Covers access to employment, vocational training, working conditions, '
          'and membership of organisations. Important for immigrant workers facing multiple discrimination.',
      keyArticles: [
        'Art. 1 — Purpose: framework for combating discrimination on grounds of religion/belief, disability, age, sexual orientation',
        'Art. 2 — Concept of discrimination: direct, indirect, harassment, instruction to discriminate; reasonable accommodation for disabled',
        'Art. 3 — Scope: employment, self-employment, vocational training, working conditions, membership of organisations',
        'Art. 4 — Genuine occupational requirement: exception where characteristic is genuine, legitimate, proportionate',
        'Art. 5 — Reasonable accommodation for disabled persons: unless disproportionate burden',
        'Art. 6 — Age discrimination: justification possible for legitimate employment/labour market objectives',
        'Art. 7 — Positive action: permitted to prevent/compensate for disadvantages',
        'Art. 9 — Defence of rights: access to judicial/administrative procedures',
        'Art. 10 — Burden of proof: shifts to respondent',
        'Art. 11 — Victimisation: protection against retaliation',
      ],
      eurLexUrl: 'https://eur-lex.europa.eu/eli/dir/2000/78/oj',
      tags: [
        'employment_equality',
        'religion',
        'disability',
        'age',
        'sexual_orientation',
        'discrimination',
      ],
    ),
  ];

  // ============================================================
  // SECTION 4: VICTIMS' RIGHTS
  // ============================================================

  static const List<EUDirective> victimsRights = [
    EUDirective(
      number: '2012/29/EU',
      name:
          'Directive establishing minimum standards on the rights, support and protection of victims of crime',
      shortName: 'Victims\' Rights Directive',
      year: 2012,
      summary:
          'Establishes minimum rights for ALL crime victims in the EU regardless of nationality or '
          'residence status. Includes right to understand and be understood, right to information, '
          'interpretation, emotional support, and participation in criminal proceedings.',
      keyArticles: [
        'Art. 2 — Definitions: victim (natural person suffering harm from criminal offence), family members (spouse, partner, relatives in direct line)',
        'Art. 3 — Right to understand and be understood: simple, accessible language; interpretation where needed',
        'Art. 4 — Right to receive information: from first contact with authorities; rights, case progress, protection measures',
        'Art. 5 — Rights when making a complaint: written acknowledgment, interpretation free of charge',
        'Art. 6 — Right to information about case: notification of decision not to prosecute, release of suspect',
        'Art. 7 — Right to interpretation and translation: in accordance with role in proceedings, free of charge',
        'Art. 8-9 — Right to access victim support services: free, confidential, before/during/after proceedings',
        'Art. 10-17 — Rights in proceedings: to be heard, review non-prosecution decision, legal aid, reimbursement',
        'Art. 18 — Right to protection: assess protection needs, prevent secondary victimisation',
        'Art. 22-24 — Specific protection needs: individual assessment, special measures during investigation and court; specific provisions for child victims',
      ],
      eurLexUrl: 'https://eur-lex.europa.eu/eli/dir/2012/29/oj',
      tags: [
        'victims',
        'crime',
        'support',
        'protection',
        'interpretation',
        'legal_aid',
      ],
    ),

    EUDirective(
      number: '2004/80/EC',
      name:
          'Council Directive relating to compensation to crime victims',
      shortName: 'Crime Victims Compensation Directive',
      year: 2004,
      summary:
          'Ensures crime victims can claim compensation in the Member State where the crime occurred, '
          'even if they reside in another Member State. Establishes cross-border system of cooperation '
          'between national authorities for transmission and processing of compensation claims.',
      keyArticles: [
        'Art. 1 — Right of access to compensation: scheme in Member State where crime committed',
        'Art. 2 — Cross-border situations: compensation accessible when crime in different State than residence',
        'Art. 3 — Assisting authority: designated in State of habitual residence to assist applicant',
        'Art. 4 — Deciding authority: designated in State where crime was committed to decide and pay',
        'Art. 5-6 — Transmission: assisting authority transmits application within prescribed time, provides information on how to apply',
        'Art. 7 — Forms and information: standardised forms, general information in all EU languages',
        'Art. 11 — Language: deciding authority may request translation; assisting authority provides information',
        'Art. 12 — Cooperation: national authorities shall cooperate and exchange information',
        'Art. 12(2) — Commission facilitates: meetings of authorities, publishing list of designated authorities',
      ],
      eurLexUrl: 'https://eur-lex.europa.eu/eli/dir/2004/80/oj',
      tags: [
        'victims',
        'compensation',
        'cross_border',
        'crime',
      ],
    ),

    EUDirective(
      number: '2011/36/EU',
      name:
          'Directive on preventing and combating trafficking in human beings and protecting its victims',
      shortName: 'Anti-Trafficking Directive',
      year: 2011,
      summary:
          'Establishes minimum rules on trafficking offences and sanctions. Provides comprehensive '
          'victim protection including non-prosecution of victims for crimes they were compelled to '
          'commit, unconditional assistance, and special protection for child victims.',
      keyArticles: [
        'Art. 2 — Trafficking offences: recruitment, transport, transfer, harbouring by means of coercion, deception, abuse of power; for exploitation (sexual, forced labour, organ removal, etc.)',
        'Art. 4 — Penalties: maximum penalty of at least 5 years (10 years for aggravating circumstances)',
        'Art. 8 — Non-prosecution: authorities entitled not to prosecute or impose penalties on victims for criminal acts they were compelled to commit',
        'Art. 11 — Assistance and support: provided regardless of willingness to cooperate; before, during, and after criminal proceedings; at least during reflection period',
        'Art. 11(5) — Assistance includes: appropriate and safe accommodation, material assistance, medical treatment, psychological assistance, translation, counselling, legal representation',
        'Art. 12 — Protection during investigation: no unnecessary repetition of interviews, visual contact with defendant avoided, interview by trained professionals',
        'Art. 13 — General protection provisions: access to existing witness protection schemes',
        'Art. 14-16 — Child victims: presumption of minority if age uncertain, best interests paramount, guardian appointed, no unnecessary interviews',
        'Art. 17 — Compensation: right to access compensation schemes',
        'Art. 18-19 — Prevention: discouraging demand, training officials, national rapporteurs',
      ],
      eurLexUrl: 'https://eur-lex.europa.eu/eli/dir/2011/36/oj',
      tags: [
        'trafficking',
        'exploitation',
        'victims',
        'non_prosecution',
        'child_protection',
        'forced_labour',
      ],
    ),

    EUDirective(
      number: '2011/99/EU',
      name:
          'Directive on the European Protection Order',
      shortName: 'European Protection Order Directive',
      year: 2011,
      summary:
          'Enables a protection order issued in one Member State to be recognised and enforced in another. '
          'Protects victims (including immigrant victims of domestic violence or stalking) when they '
          'move or travel within the EU. Ensures continuity of protection across borders.',
      keyArticles: [
        'Art. 1 — Purpose: rules for recognition of protection measures adopted in criminal matters in another Member State',
        'Art. 3 — Definitions: protection measure, European protection order, issuing/executing State',
        'Art. 5 — EPO: issued when protected person moves to another Member State and requests continued protection',
        'Art. 6 — Conditions: protection measure already in force; prohibition to enter places, contact, or approach within distance',
        'Art. 9 — Recognition: executing State shall recognise and take measures to ensure protection',
        'Art. 11 — National law: executing State applies its own national law to ensure protection',
        'Art. 12 — Notification: of any breach to the issuing State',
        'Art. 14 — Cessation: when protection measure withdrawn in issuing State, or duration expires',
      ],
      eurLexUrl: 'https://eur-lex.europa.eu/eli/dir/2011/99/oj',
      tags: [
        'protection_order',
        'domestic_violence',
        'cross_border',
        'victims',
        'mutual_recognition',
      ],
    ),
  ];

  // ============================================================
  // SECTION 5: DATA PROTECTION & PRIVACY
  // ============================================================

  static const List<EUDirective> dataProtection = [
    EUDirective(
      number: '2016/679',
      name:
          'Regulation on the protection of natural persons with regard to the processing of personal data and on the free movement of such data',
      shortName: 'General Data Protection Regulation (GDPR)',
      year: 2016,
      summary:
          'Comprehensive data protection regulation applying to all individuals in the EU regardless of '
          'nationality. Critical for immigrants: protects personal data in asylum proceedings, immigration '
          'databases (Eurodac, SIS, VIS), employer records, and healthcare systems.',
      keyArticles: [
        'Art. 5 — Principles: lawfulness, fairness, transparency, purpose limitation, data minimisation, accuracy, storage limitation, integrity, accountability',
        'Art. 6 — Lawfulness of processing: consent, contract, legal obligation, vital interests, public interest, legitimate interests',
        'Art. 9 — Special categories: racial/ethnic origin, religion, health data, biometric data — prohibited unless specific exception (explicit consent, vital interests, etc.)',
        'Art. 12-14 — Right to information: transparent, intelligible, easily accessible; what data collected, purpose, retention, rights; provided in writing, free of charge',
        'Art. 15 — Right of access: confirmation of processing, access to data, copy of data',
        'Art. 16-17 — Right to rectification and erasure ("right to be forgotten")',
        'Art. 18 — Right to restriction of processing: when accuracy contested, processing unlawful, controller no longer needs data',
        'Art. 20 — Right to data portability: receive data in structured, machine-readable format',
        'Art. 21 — Right to object: to processing based on public interest or legitimate interests',
        'Art. 22 — Automated individual decision-making: right not to be subject to decision based solely on automated processing including profiling',
        'Art. 77-79 — Remedies: right to lodge complaint with supervisory authority, right to judicial remedy',
        'Art. 82 — Compensation: right to compensation for material or non-material damage from GDPR infringement',
      ],
      eurLexUrl: 'https://eur-lex.europa.eu/eli/reg/2016/679/oj',
      tags: [
        'data_protection',
        'privacy',
        'gdpr',
        'consent',
        'rights',
        'processing',
      ],
    ),
  ];

  // ============================================================
  // SECTION 6: CONSUMER PROTECTION
  // ============================================================

  static const List<EUDirective> consumerProtection = [
    EUDirective(
      number: '2011/83/EU',
      name:
          'Directive on consumer rights',
      shortName: 'Consumer Rights Directive',
      year: 2011,
      summary:
          'Harmonises consumer protection rules across the EU. Establishes 14-day right of withdrawal '
          'for distance/off-premises contracts, pre-contractual information requirements, and delivery '
          'rules. Important for immigrants targeted by predatory service providers.',
      keyArticles: [
        'Art. 5 — Information for on-premises contracts: main characteristics, identity of trader, total price, right of withdrawal, guarantee, duration',
        'Art. 6 — Information for distance/off-premises: comprehensive list of 20 mandatory information items before contract',
        'Art. 7-8 — Formal requirements: durable medium, confirmation, information in clear language',
        'Art. 9 — Right of withdrawal: 14 calendar days without giving any reason',
        'Art. 10 — Omission of information: withdrawal period extended to 12 months if information not provided',
        'Art. 13-14 — Effects of withdrawal: reimbursement within 14 days, return of goods',
        'Art. 18 — Delivery: within 30 days unless agreed otherwise; right to terminate if not delivered',
        'Art. 20 — Risk: passes to consumer only upon physical possession',
        'Art. 21 — Communication costs: no premium rate phone lines for existing contracts',
        'Art. 22 — Additional payments: explicit consent required; no pre-ticked boxes',
      ],
      eurLexUrl: 'https://eur-lex.europa.eu/eli/dir/2011/83/oj',
      tags: [
        'consumer',
        'withdrawal',
        'distance_contract',
        'information',
        'delivery',
      ],
    ),

    EUDirective(
      number: '2005/29/EC',
      name:
          'Directive concerning unfair business-to-consumer commercial practices',
      shortName: 'Unfair Commercial Practices Directive',
      year: 2005,
      summary:
          'Prohibits unfair, misleading, and aggressive commercial practices. Protects vulnerable '
          'consumers including immigrants with limited language skills or knowledge of local markets '
          'from exploitation by unscrupulous businesses.',
      keyArticles: [
        'Art. 5 — Prohibition: of unfair commercial practices; practice is unfair if contrary to professional diligence and materially distorts consumer behaviour',
        'Art. 6 — Misleading actions: false information or deceptive presentation regarding product characteristics, price, nature',
        'Art. 7 — Misleading omissions: omitting material information needed for informed decision',
        'Art. 8 — Aggressive practices: harassment, coercion, undue influence significantly impairing freedom of choice',
        'Art. 9 — Factors for aggressive practices: timing, location, nature, persistence, exploitation of misfortune, threats, onerous barriers',
        'Annex I — Black list: 31 practices always considered unfair (bait advertising, fake free offers, false urgency, pyramid schemes, etc.)',
      ],
      eurLexUrl: 'https://eur-lex.europa.eu/eli/dir/2005/29/oj',
      tags: [
        'consumer',
        'unfair_practices',
        'misleading',
        'aggressive',
        'vulnerable_consumers',
      ],
    ),
  ];

  // ============================================================
  // SECTION 7: SOCIAL SECURITY COORDINATION
  // ============================================================

  static const List<EUDirective> socialSecurity = [
    EUDirective(
      number: '883/2004',
      name:
          'Regulation on the coordination of social security systems',
      shortName: 'Social Security Coordination Regulation',
      year: 2004,
      summary:
          'Coordinates social security systems between EU Member States. Extended to third-country nationals '
          'by Regulation 1231/2010. Ensures aggregation of insurance periods, export of benefits, and '
          'prevention of double contributions. Critical for immigrant workers.',
      keyArticles: [
        'Art. 3 — Material scope: sickness, maternity/paternity, invalidity, old-age, survivors, accidents at work, unemployment, family benefits, pre-retirement',
        'Art. 4 — Equal treatment: persons to whom regulation applies receive same benefits and are subject to same obligations as nationals',
        'Art. 5 — Equal treatment of benefits, events: assimilated across Member States',
        'Art. 6 — Aggregation: all periods of insurance/residence taken into account in any Member State',
        'Art. 7 — Export of benefits: cash benefits not reduced/suspended for residing in different Member State',
        'Art. 11 — Single legislation: subject to legislation of a single Member State only',
        'Art. 12 — Posted workers: remain insured in sending State for up to 24 months',
        'Art. 64 — Unemployment: transfer to another Member State for 3-6 months while retaining benefits',
        'Art. 67-68 — Family benefits: aggregation rules, priority rules for overlapping entitlements',
      ],
      eurLexUrl: 'https://eur-lex.europa.eu/eli/reg/2004/883/oj',
      tags: [
        'social_security',
        'coordination',
        'pensions',
        'healthcare',
        'unemployment',
        'aggregation',
      ],
    ),

    EUDirective(
      number: '1231/2010',
      name:
          'Regulation extending Regulation (EC) No 883/2004 and Regulation (EC) No 987/2009 to nationals of third countries who are not already covered by these Regulations solely on the ground of their nationality',
      shortName: 'Extension of Social Security Coordination to Third-Country Nationals',
      year: 2010,
      summary:
          'Extends EU social security coordination rules (Regulation 883/2004) to legally residing '
          'third-country nationals who have cross-border situations between Member States. Ensures '
          'aggregation of insurance periods and equal treatment for non-EU workers.',
      keyArticles: [
        'Art. 1 — Extension: Regulation 883/2004 and implementing Regulation 987/2009 apply to third-country nationals legally residing in EU with cross-border situation',
        'Recital 7 — Cross-border element: applies only where TCN has been in situation involving at least 2 Member States',
        'Recital 10 — Denmark, UK, Ireland: may opt in separately (Denmark does not participate)',
        'Recital 12 — Single-State situations: TCNs in purely domestic situation are not covered (national law applies)',
      ],
      eurLexUrl: 'https://eur-lex.europa.eu/eli/reg/2010/1231/oj',
      tags: [
        'social_security',
        'third_country_nationals',
        'extension',
        'cross_border',
      ],
    ),
  ];

  // ============================================================
  // SECTION 8: FUNDAMENTAL RIGHTS (EU Charter)
  // ============================================================

  static const List<EUDirective> fundamentalRights = [
    EUDirective(
      number: '2012/C 326/02',
      name:
          'Charter of Fundamental Rights of the European Union',
      shortName: 'EU Charter of Fundamental Rights',
      year: 2000,
      summary:
          'Legally binding catalogue of fundamental rights applying when EU law is implemented. '
          'Includes dignity, freedoms, equality, solidarity, citizens\' rights, and justice. '
          'Core reference for all immigration and asylum decisions by Member States.',
      keyArticles: [
        'Art. 1 — Human dignity: inviolable, respected and protected',
        'Art. 3 — Right to integrity: physical and mental; prohibition of eugenics, organ sale, reproductive cloning',
        'Art. 4 — Prohibition of torture: no one subjected to torture, inhuman or degrading treatment or punishment',
        'Art. 5 — Prohibition of slavery and forced labour: including trafficking',
        'Art. 7 — Private and family life: respected',
        'Art. 18 — Right to asylum: guaranteed with due respect to Geneva Convention and EU Treaties',
        'Art. 19 — Protection from removal/expulsion/extradition: non-refoulement, no collective expulsion',
        'Art. 21 — Non-discrimination: any ground including sex, race, colour, ethnic/social origin, language, religion, political opinion, disability, age, sexual orientation',
        'Art. 24 — Rights of the child: best interests primary consideration, right to maintain contact with parents',
        'Art. 47 — Right to an effective remedy and fair trial: including legal aid where necessary',
      ],
      eurLexUrl: 'https://eur-lex.europa.eu/eli/treaty/char_2012/oj',
      tags: [
        'fundamental_rights',
        'charter',
        'dignity',
        'asylum',
        'non_refoulement',
        'non_discrimination',
      ],
    ),
  ];

  // ============================================================
  // COMPLETE DATABASE ACCESS
  // ============================================================

  /// Returns all directives/regulations in the database.
  List<EUDirective> get allDirectives => [
        ...immigrationAsylum,
        ...workersRights,
        ...antiDiscrimination,
        ...victimsRights,
        ...dataProtection,
        ...consumerProtection,
        ...socialSecurity,
        ...fundamentalRights,
      ];

  /// Total count of directives in database.
  int get totalCount => allDirectives.length;

  /// Search by tag.
  List<EUDirective> searchByTag(String tag) {
    return allDirectives
        .where((d) => d.tags.any((t) => t.toLowerCase().contains(tag.toLowerCase())))
        .toList();
  }

  /// Search by keyword in name, shortName, summary, or keyArticles.
  List<EUDirective> searchByKeyword(String keyword) {
    final kw = keyword.toLowerCase();
    return allDirectives.where((d) {
      return d.name.toLowerCase().contains(kw) ||
          d.shortName.toLowerCase().contains(kw) ||
          d.summary.toLowerCase().contains(kw) ||
          d.number.toLowerCase().contains(kw) ||
          d.keyArticles.any((a) => a.toLowerCase().contains(kw));
    }).toList();
  }

  /// Get directive by exact number (e.g., "2011/95/EU").
  EUDirective? getByNumber(String number) {
    try {
      return allDirectives.firstWhere(
        (d) => d.number.toLowerCase() == number.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Get directives from the 2024 Pact on Migration and Asylum.
  List<EUDirective> get pact2024Directives {
    return allDirectives.where((d) => d.tags.contains('pact_2024')).toList();
  }

  /// Get directives that have been recast/replaced by newer instruments.
  List<EUDirective> get recastDirectives {
    return allDirectives.where((d) => d.isRecast).toList();
  }

  /// Get the currently active version of a directive (latest replacement).
  EUDirective? getCurrentVersion(String number) {
    final directive = getByNumber(number);
    if (directive == null) return null;
    if (directive.replacedBy != null) {
      return getByNumber(directive.replacedBy!) ?? directive;
    }
    return directive;
  }

  /// Get directives by year.
  List<EUDirective> getByYear(int year) {
    return allDirectives.where((d) => d.year == year).toList();
  }

  /// Get directives by category.
  List<EUDirective> getByCategory(EUDirectiveCategory category) {
    switch (category) {
      case EUDirectiveCategory.immigrationAsylum:
        return immigrationAsylum;
      case EUDirectiveCategory.workersRights:
        return workersRights;
      case EUDirectiveCategory.antiDiscrimination:
        return antiDiscrimination;
      case EUDirectiveCategory.victimsRights:
        return victimsRights;
      case EUDirectiveCategory.dataProtection:
        return dataProtection;
      case EUDirectiveCategory.consumerProtection:
        return consumerProtection;
      case EUDirectiveCategory.socialSecurity:
        return socialSecurity;
      case EUDirectiveCategory.fundamentalRights:
        return fundamentalRights;
    }
  }

  /// Get all relevant directives for a specific immigration situation.
  List<EUDirective> getForSituation(ImmigrantSituation situation) {
    final Set<String> relevantTags = {};

    switch (situation) {
      case ImmigrantSituation.asylumSeeker:
        relevantTags.addAll([
          'asylum', 'reception', 'dublin', 'qualification',
          'procedures', 'fundamental_rights', 'data_protection',
        ]);
        break;
      case ImmigrantSituation.refugee:
        relevantTags.addAll([
          'refugee', 'qualification', 'family', 'reunification',
          'long_term_resident', 'social_security', 'employment_equality',
        ]);
        break;
      case ImmigrantSituation.worker:
        relevantTags.addAll([
          'work_permit', 'single_permit', 'blue_card', 'posted_workers',
          'working_time', 'working_conditions', 'equal_pay',
          'social_security', 'employment_equality',
        ]);
        break;
      case ImmigrantSituation.student:
        relevantTags.addAll([
          'students', 'researchers', 'education', 'work_during_studies',
        ]);
        break;
      case ImmigrantSituation.familyMember:
        relevantTags.addAll([
          'family', 'reunification', 'free_movement', 'family_members',
        ]);
        break;
      case ImmigrantSituation.undocumented:
        relevantTags.addAll([
          'return', 'removal', 'detention', 'victims', 'trafficking',
          'fundamental_rights', 'employers', 'sanctions',
        ]);
        break;
      case ImmigrantSituation.traffickingVictim:
        relevantTags.addAll([
          'trafficking', 'victims', 'exploitation', 'non_prosecution',
          'residence_permit', 'reflection_period', 'compensation',
        ]);
        break;
      case ImmigrantSituation.temporaryProtection:
        relevantTags.addAll([
          'temporary_protection', 'mass_influx', 'emergency', 'solidarity',
        ]);
        break;
      case ImmigrantSituation.deportation:
        relevantTags.addAll([
          'return', 'removal', 'detention', 'entry_ban',
          'non_refoulement', 'fundamental_rights', 'charter',
        ]);
        break;
      case ImmigrantSituation.discrimination:
        relevantTags.addAll([
          'racial_equality', 'ethnic_origin', 'discrimination',
          'employment_equality', 'non_discrimination',
        ]);
        break;
    }

    return allDirectives
        .where((d) => d.tags.any((t) => relevantTags.contains(t)))
        .toList();
  }

  /// Get summary statistics of the database.
  Map<String, dynamic> get statistics => {
        'totalDirectives': totalCount,
        'categories': {
          'immigrationAsylum': immigrationAsylum.length,
          'workersRights': workersRights.length,
          'antiDiscrimination': antiDiscrimination.length,
          'victimsRights': victimsRights.length,
          'dataProtection': dataProtection.length,
          'consumerProtection': consumerProtection.length,
          'socialSecurity': socialSecurity.length,
          'fundamentalRights': fundamentalRights.length,
        },
        'pact2024Instruments': pact2024Directives.length,
        'recastInstruments': recastDirectives.length,
        'yearRange': '2000-2024',
        'totalKeyArticles': allDirectives.fold<int>(
          0,
          (sum, d) => sum + d.keyArticles.length,
        ),
      };
}

// ============================================================
// ENUMS
// ============================================================

enum EUDirectiveCategory {
  immigrationAsylum,
  workersRights,
  antiDiscrimination,
  victimsRights,
  dataProtection,
  consumerProtection,
  socialSecurity,
  fundamentalRights,
}

enum ImmigrantSituation {
  asylumSeeker,
  refugee,
  worker,
  student,
  familyMember,
  undocumented,
  traffickingVictim,
  temporaryProtection,
  deportation,
  discrimination,
}
