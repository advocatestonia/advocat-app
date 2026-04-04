// Prisoner Rights Database for Foreign Detainees in EU Countries
// Comprehensive database covering all 27 EU member states
// Last updated: 2026-04
//
// Sources: Vienna Convention on Consular Relations (1963),
// EU Framework Decision 2008/909/JHA (Transfer of Prisoners),
// EU Framework Decision 2002/584/JHA (European Arrest Warrant),
// Directive 2010/64/EU (Right to Interpretation/Translation),
// Directive 2012/13/EU (Right to Information),
// Directive 2013/48/EU (Right to Access a Lawyer),
// Directive 2016/1919/EU (Legal Aid),
// European Prison Rules (Rec(2006)2, updated 2020),
// CPT Standards (Council of Europe),
// FRA (Fundamental Rights Agency) reports,
// National prison service publications per country.

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

/// Categories of prisoner rights tracked per country.
enum PrisonerRightCategory {
  consularAccess,
  interpreterRight,
  transferToHomeCountry,
  legalAidCriminal,
  prisonConditions,
  communicationRights,
  healthcareInPrison,
  religiousRights,
  immigrationConsequences,
  earlyReleaseParole,
  deportationAfterSentence,
  europeanArrestWarrant,
  ngosHelpingPrisoners,
}

/// A single right / rule for a specific country.
class PrisonerRight {
  final PrisonerRightCategory category;
  final String title;
  final String description;
  final List<String> legalBasis;
  final String? practicalNotes;

  const PrisonerRight({
    required this.category,
    required this.title,
    required this.description,
    required this.legalBasis,
    this.practicalNotes,
  });

  Map<String, dynamic> toMap() => {
        'category': category.name,
        'title': title,
        'description': description,
        'legalBasis': legalBasis,
        if (practicalNotes != null) 'practicalNotes': practicalNotes,
      };
}

/// NGO / organisation that helps foreign prisoners in a country.
class PrisonerSupportNGO {
  final String name;
  final String country;
  final String description;
  final String? website;
  final String? phone;
  final String? email;
  final List<String> languages;

  const PrisonerSupportNGO({
    required this.name,
    required this.country,
    required this.description,
    this.website,
    this.phone,
    this.email,
    this.languages = const ['English'],
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'country': country,
        'description': description,
        if (website != null) 'website': website,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        'languages': languages,
      };
}

/// Full rights profile for one EU country.
class CountryPrisonerRights {
  final String countryCode; // ISO 3166-1 alpha-2
  final String countryName;
  final String prisonAuthority;
  final String prisonAuthorityWebsite;
  final int approximatePrisonPopulation;
  final double foreignPrisonerPercentage;
  final List<PrisonerRight> rights;
  final List<PrisonerSupportNGO> ngos;

  const CountryPrisonerRights({
    required this.countryCode,
    required this.countryName,
    required this.prisonAuthority,
    required this.prisonAuthorityWebsite,
    required this.approximatePrisonPopulation,
    required this.foreignPrisonerPercentage,
    required this.rights,
    required this.ngos,
  });

  PrisonerRight? getRight(PrisonerRightCategory category) {
    try {
      return rights.firstWhere((r) => r.category == category);
    } catch (_) {
      return null;
    }
  }

  List<PrisonerRight> getRightsByCategories(
      List<PrisonerRightCategory> categories) {
    return rights.where((r) => categories.contains(r.category)).toList();
  }

  Map<String, dynamic> toMap() => {
        'countryCode': countryCode,
        'countryName': countryName,
        'prisonAuthority': prisonAuthority,
        'prisonAuthorityWebsite': prisonAuthorityWebsite,
        'approximatePrisonPopulation': approximatePrisonPopulation,
        'foreignPrisonerPercentage': foreignPrisonerPercentage,
        'rights': rights.map((r) => r.toMap()).toList(),
        'ngos': ngos.map((n) => n.toMap()).toList(),
      };
}

/// EU-wide legal framework applicable to all member states.
class EUPrisonerFramework {
  final String name;
  final String reference;
  final int year;
  final String summary;
  final List<String> keyProvisions;
  final String url;

  const EUPrisonerFramework({
    required this.name,
    required this.reference,
    required this.year,
    required this.summary,
    required this.keyProvisions,
    required this.url,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'reference': reference,
        'year': year,
        'summary': summary,
        'keyProvisions': keyProvisions,
        'url': url,
      };
}

// ---------------------------------------------------------------------------
// Main database class
// ---------------------------------------------------------------------------

class PrisonerRightsDatabase {
  static final PrisonerRightsDatabase _instance =
      PrisonerRightsDatabase._internal();
  factory PrisonerRightsDatabase() => _instance;
  PrisonerRightsDatabase._internal();

  /// Get rights profile for a specific country by ISO code.
  CountryPrisonerRights? getCountry(String countryCode) {
    try {
      return allCountries
          .firstWhere((c) => c.countryCode == countryCode.toUpperCase());
    } catch (_) {
      return null;
    }
  }

  /// Get a specific right category for a country.
  PrisonerRight? getRight(String countryCode, PrisonerRightCategory category) {
    return getCountry(countryCode)?.getRight(category);
  }

  /// Get all NGOs for a specific country.
  List<PrisonerSupportNGO> getNGOs(String countryCode) {
    return getCountry(countryCode)?.ngos ?? [];
  }

  /// Search across all countries for a keyword in rights descriptions.
  List<MapEntry<String, PrisonerRight>> searchRights(String keyword) {
    final kw = keyword.toLowerCase();
    final results = <MapEntry<String, PrisonerRight>>[];
    for (final country in allCountries) {
      for (final right in country.rights) {
        if (right.description.toLowerCase().contains(kw) ||
            right.title.toLowerCase().contains(kw)) {
          results.add(MapEntry(country.countryCode, right));
        }
      }
    }
    return results;
  }

  /// Get all countries where a specific right category has notable differences.
  Map<String, PrisonerRight> compareRight(PrisonerRightCategory category) {
    final map = <String, PrisonerRight>{};
    for (final country in allCountries) {
      final right = country.getRight(category);
      if (right != null) {
        map[country.countryCode] = right;
      }
    }
    return map;
  }

  // =========================================================================
  // EU-WIDE FRAMEWORKS
  // =========================================================================

  static const List<EUPrisonerFramework> euFrameworks = [
    // --- Transfer of Prisoners ---
    EUPrisonerFramework(
      name: 'EU Framework Decision on Transfer of Prisoners',
      reference: '2008/909/JHA',
      year: 2008,
      summary:
          'Mutual recognition of judgments imposing custodial sentences. '
          'Allows transfer of sentenced prisoners to their EU home country '
          'or country of habitual residence for rehabilitation purposes. '
          'Replaces the 1983 Council of Europe Convention between EU states.',
      keyProvisions: [
        'Art. 3 — Purpose: social rehabilitation of sentenced person',
        'Art. 4 — Forwarding of judgment to executing state',
        'Art. 6 — Consent of sentenced person (with exceptions)',
        'Art. 8 — Recognition and enforcement of judgment',
        'Art. 9 — Double criminality not required for 32 listed offences',
        'Art. 12 — Adaptation of sentence if incompatible with executing state law',
        'Art. 17 — Continued enforcement governed by executing state law',
        'Art. 25 — Enforcement of sentence following EAW proceedings',
      ],
      url:
          'https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=celex:32008F0909',
    ),

    // --- European Arrest Warrant ---
    EUPrisonerFramework(
      name: 'European Arrest Warrant',
      reference: '2002/584/JHA',
      year: 2002,
      summary:
          'Simplified cross-border judicial surrender procedure between EU states. '
          'Replaces lengthy extradition procedures. Mandatory for offences carrying '
          'a maximum penalty of at least 12 months or sentences of at least 4 months.',
      keyProvisions: [
        'Art. 1 — Definition and obligation to execute EAW',
        'Art. 2 — Scope: 12+ months maximum penalty or 4+ months sentence',
        'Art. 3 — Mandatory grounds for non-execution (amnesty, ne bis in idem, age)',
        'Art. 4 — Optional grounds for non-execution',
        'Art. 5 — Guarantees by issuing state (in absentia, life sentence, nationals)',
        'Art. 11 — Rights of requested person',
        'Art. 12 — Detention conditions pending surrender',
        'Art. 17 — Time limits: 60 days, extendable to 90',
        'Art. 23 — Time limits for surrender: 10 days after final decision',
      ],
      url:
          'https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=celex:32002F0584',
    ),

    // --- Right to Interpretation and Translation ---
    EUPrisonerFramework(
      name: 'Right to Interpretation and Translation in Criminal Proceedings',
      reference: '2010/64/EU',
      year: 2010,
      summary:
          'Guarantees free interpretation and translation of essential documents '
          'for suspects/accused who do not speak the language of proceedings. '
          'Covers police questioning, court hearings, and essential documents '
          '(detention orders, charges, judgments).',
      keyProvisions: [
        'Art. 2 — Right to interpretation (police, court, lawyer meetings)',
        'Art. 3 — Right to translation of essential documents',
        'Art. 4 — Costs borne by the state regardless of outcome',
        'Art. 5 — Quality of interpretation must be sufficient',
        'Art. 6 — Right to challenge inadequate interpretation',
      ],
      url:
          'https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=celex:32010L0064',
    ),

    // --- Right to Information ---
    EUPrisonerFramework(
      name: 'Right to Information in Criminal Proceedings',
      reference: '2012/13/EU',
      year: 2012,
      summary:
          'Right to be informed promptly of rights upon arrest. Includes '
          'written Letter of Rights covering access to lawyer, interpretation, '
          'silence, legal aid, consular notification, and time limits for detention.',
      keyProvisions: [
        'Art. 3 — Right to information about rights (oral or written)',
        'Art. 4 — Letter of Rights on arrest',
        'Art. 5 — Letter of Rights in EAW proceedings',
        'Art. 6 — Right to information about the accusation',
        'Art. 7 — Right to access case materials',
      ],
      url:
          'https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=celex:32012L0013',
    ),

    // --- Right to Access a Lawyer ---
    EUPrisonerFramework(
      name: 'Right of Access to a Lawyer in Criminal Proceedings',
      reference: '2013/48/EU',
      year: 2013,
      summary:
          'Guarantees access to a lawyer from the earliest stages of criminal '
          'proceedings, including before police questioning. Also covers the '
          'right to have a third party informed upon deprivation of liberty '
          'and to communicate with consular authorities.',
      keyProvisions: [
        'Art. 3 — Right of access to a lawyer (timing and scope)',
        'Art. 4 — Confidentiality of lawyer-client communications',
        'Art. 5 — Right to have third party informed on deprivation of liberty',
        'Art. 6 — Right to communicate with consular authorities',
        'Art. 7 — Right to communicate with consular authorities for EAW',
        'Art. 8 — Temporary derogations (exceptional circumstances only)',
        'Art. 9 — Waiver must be voluntary, informed, and documented',
      ],
      url:
          'https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=celex:32013L0048',
    ),

    // --- Legal Aid ---
    EUPrisonerFramework(
      name: 'Legal Aid for Suspects and Accused Persons',
      reference: '2016/1919/EU',
      year: 2016,
      summary:
          'Ensures provisional and full legal aid for suspects and accused persons '
          'in criminal proceedings and for requested persons in EAW proceedings. '
          'Applies where legal aid is necessary to ensure effective access to justice.',
      keyProvisions: [
        'Art. 4 — Legal aid in criminal proceedings',
        'Art. 5 — Legal aid in EAW proceedings',
        'Art. 7 — Decisions on legal aid (means and merits test)',
        'Art. 8 — Quality of legal aid services',
      ],
      url:
          'https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=celex:32016L1919',
    ),

    // --- European Prison Rules ---
    EUPrisonerFramework(
      name: 'European Prison Rules',
      reference: 'Rec(2006)2 (revised 2020)',
      year: 2006,
      summary:
          'Council of Europe Recommendation establishing minimum standards for '
          'prison conditions. Covers accommodation, hygiene, nutrition, healthcare, '
          'contact with outside world, regime activities, and specific provisions '
          'for foreign prisoners. Not legally binding but referenced by ECtHR.',
      keyProvisions: [
        'Rule 37 — Foreign nationals: inform of right to consular contact',
        'Rule 37.1 — Cooperation with consular/diplomatic representatives',
        'Rule 37.2 — Access to legal and interpreter assistance',
        'Rule 37.3 — Information in language prisoner understands',
        'Rule 37.4 — Equivalent treatment regardless of nationality',
        'Rule 38 — Special needs of minority groups',
        'Rule 24 — Right to healthcare equivalent to community standard',
        'Rule 29 — Religious practice in prison',
        'Rule 24.1 — Access to doctor without undue delay',
        'Rule 99-100 — Sentenced foreign prisoners: social rehabilitation',
      ],
      url:
          'https://rm.coe.int/european-prison-rules-978-92-871-5982-3/16806ab9ae',
    ),

    // --- CPT Standards ---
    EUPrisonerFramework(
      name: 'CPT Standards (Committee for Prevention of Torture)',
      reference: 'CPT/Inf/E (2002) 1 - Rev. 2015',
      year: 2002,
      summary:
          'Substantive standards developed by the CPT through country visits. '
          'Cover police custody, imprisonment, foreign nationals deprived of liberty, '
          'solitary confinement, healthcare, and vulnerable groups. CPT reports '
          'are authoritative source for ECtHR on prison conditions.',
      keyProvisions: [
        'Section on police custody: max 48h, access to lawyer, doctor, notify third party',
        'Section on imprisonment: minimum 4m² per prisoner in multi-occupancy cells',
        'Section on foreign nationals: interpretation, consular access, transfer information',
        'Section on healthcare: equivalence of care, mental health, drug dependence',
        'Section on solitary confinement: max 14 days, medical monitoring',
        'Section on deportation: no deportation to torture risk (non-refoulement)',
        'Section on women in prison: gender-specific healthcare, no male staff in intimate searches',
      ],
      url: 'https://www.coe.int/en/web/cpt/standards',
    ),

    // --- Victims Rights Directive (relevant when prisoner is also victim) ---
    EUPrisonerFramework(
      name: 'Victims\' Rights Directive',
      reference: '2012/29/EU',
      year: 2012,
      summary:
          'Minimum standards on rights, support, and protection of victims. '
          'Relevant for foreign prisoners who were also victims of crime '
          '(trafficking, domestic violence). Guarantees interpretation, '
          'information, and support regardless of residence status.',
      keyProvisions: [
        'Art. 5-6 — Right to information and interpretation',
        'Art. 7 — Right to access victim support services',
        'Art. 11 — Rights in restorative justice',
        'Art. 17 — Right to protection, including from secondary victimisation',
        'Art. 22 — Individual assessment to identify protection needs',
      ],
      url:
          'https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=celex:32012L0029',
    ),

    // --- Convention on Transfer of Sentenced Persons ---
    EUPrisonerFramework(
      name: 'Convention on Transfer of Sentenced Persons',
      reference: 'ETS No. 112 (Council of Europe)',
      year: 1983,
      summary:
          'Original CoE convention allowing transfer of foreign prisoners to home '
          'country. Still applies between EU and non-EU CoE states. Requires '
          'consent of both states and the prisoner. Supplemented by Additional '
          'Protocol ETS 167 (1997) allowing transfer without prisoner consent '
          'in deportation cases.',
      keyProvisions: [
        'Art. 3 — Conditions for transfer: dual nationality not required',
        'Art. 3.1.d — Generally 6 months of sentence remaining required',
        'Art. 7 — Consent of sentenced person required',
        'Art. 9-11 — Continued enforcement or conversion of sentence',
        'Additional Protocol Art. 2 — Transfer without consent if deportation order exists',
        'Additional Protocol Art. 3 — Transfer of mentally disordered persons',
      ],
      url: 'https://www.coe.int/en/web/conventions/full-list/-/conventions/treaty/112',
    ),
  ];

  // =========================================================================
  // ALL 27 EU COUNTRIES
  // =========================================================================

  static const List<CountryPrisonerRights> allCountries = [
    // -----------------------------------------------------------------------
    // 1. AUSTRIA (AT)
    // -----------------------------------------------------------------------
    CountryPrisonerRights(
      countryCode: 'AT',
      countryName: 'Austria',
      prisonAuthority: 'Federal Ministry of Justice — Generaldirektion für den Strafvollzug',
      prisonAuthorityWebsite: 'https://www.justiz.gv.at',
      approximatePrisonPopulation: 8900,
      foreignPrisonerPercentage: 55.0,
      rights: [
        PrisonerRight(
          category: PrisonerRightCategory.consularAccess,
          title: 'Consular Access',
          description:
              'Austria is party to the Vienna Convention on Consular Relations. '
              'Foreign prisoners must be informed of their right to contact their '
              'consulate without delay upon arrest. The prison administration '
              'must facilitate consular visits.',
          legalBasis: [
            'Vienna Convention on Consular Relations Art. 36',
            'Austrian Code of Criminal Procedure (StPO) §171',
            'EU Directive 2013/48/EU Art. 6',
          ],
          practicalNotes:
              'Request consular notification immediately upon arrest. '
              'Consulate can help find a lawyer, contact family, and monitor '
              'prison conditions. Austria has one of the highest foreign prisoner '
              'percentages in the EU.',
        ),
        PrisonerRight(
          category: PrisonerRightCategory.interpreterRight,
          title: 'Right to Interpreter',
          description:
              'Free interpretation in criminal proceedings from the first police '
              'questioning through trial and appeal. Written translation of essential '
              'documents (charge sheet, judgment, detention order). Interpreter must '
              'be certified.',
          legalBasis: [
            'EU Directive 2010/64/EU',
            'StPO §56',
            'Austrian Federal Constitution Art. 6 ECHR',
          ],
          practicalNotes:
              'If interpreter quality is inadequate, you can challenge this. '
              'The court must provide a new interpreter. Common languages '
              '(Turkish, Serbian, Arabic, Romanian) are generally well served. '
              'Rare languages may cause delays.',
        ),
        PrisonerRight(
          category: PrisonerRightCategory.transferToHomeCountry,
          title: 'Transfer to Home Country',
          description:
              'EU nationals can request transfer under Framework Decision 2008/909/JHA. '
              'Non-EU nationals may apply under the CoE Convention ETS 112. Austria actively '
              'uses transfers, especially for nationals of neighbouring states. Transfer can '
              'be initiated by Austria, the home state, or the prisoner.',
          legalBasis: [
            'EU Framework Decision 2008/909/JHA',
            'Austrian EU-JZG (EU Judicial Cooperation Act) §§39-52',
            'CoE Convention on Transfer of Sentenced Persons ETS 112',
          ],
          practicalNotes:
              'Processing typically takes 6-12 months. At least 6 months of sentence '
              'must remain. For EU nationals, consent may not be required if transferring '
              'to country of nationality where the person will be deported to.',
        ),
        PrisonerRight(
          category: PrisonerRightCategory.legalAidCriminal,
          title: 'Legal Aid in Criminal Cases',
          description:
              'Free legal representation (Verfahrenshilfe) available for accused persons '
              'who cannot afford a lawyer. Mandatory defence counsel for offences with '
              'maximum penalty exceeding 3 years, or when in pre-trial detention. '
              'Legal aid covers all stages including appeal.',
          legalBasis: [
            'StPO §61',
            'EU Directive 2016/1919/EU',
            'ECHR Art. 6(3)(c)',
          ],
          practicalNotes:
              'Apply through the court. The bar association assigns a lawyer. '
              'Quality varies — you can request a change if representation is '
              'inadequate. Foreign prisoners may need a lawyer who speaks their language.',
        ),
        PrisonerRight(
          category: PrisonerRightCategory.prisonConditions,
          title: 'Prison Conditions',
          description:
              'Austrian prisons generally meet European standards. Single cells are '
              'the norm in newer facilities. Minimum cell size standards apply. '
              'CPT has noted overcrowding in pre-trial detention (Josefstadt). '
              'Foreign prisoners have equal access to facilities.',
          legalBasis: [
            'Strafvollzugsgesetz (StVG) — Prison Act',
            'European Prison Rules Rec(2006)2',
            'CPT Standards',
          ],
          practicalNotes:
              'Pre-trial conditions at Justizanstalt Wien-Josefstadt can be '
              'overcrowded. Sentenced prisoners in provincial facilities generally '
              'have better conditions. You can file complaints with the prison director '
              'or the Ombudsman Board (Volksanwaltschaft).',
        ),
        PrisonerRight(
          category: PrisonerRightCategory.communicationRights,
          title: 'Communication Rights',
          description:
              'Right to send and receive letters (may be monitored in pre-trial). '
              'Phone calls permitted, typically 1-2 per week in pre-trial, more after '
              'sentencing. Visits at least once per week for 1 hour. Lawyer visits '
              'are unrestricted and confidential.',
          legalBasis: [
            'StVG §§86-96',
            'StPO §§187-188 (pre-trial)',
            'European Prison Rules 24.1-24.12',
          ],
          practicalNotes:
              'International calls are possible but may be more expensive. '
              'Video calls introduced during COVID and partially maintained. '
              'Correspondence with lawyers and consulate cannot be monitored.',
        ),
        PrisonerRight(
          category: PrisonerRightCategory.healthcareInPrison,
          title: 'Healthcare in Prison',
          description:
              'Healthcare must be equivalent to community standards. Each prison has '
              'medical staff. Specialist referrals available. Mental health care '
              'provided. Dental care included. Medication for pre-existing conditions '
              'continued. Drug substitution therapy (methadone) available.',
          legalBasis: [
            'StVG §§66-74',
            'European Prison Rules Rule 24',
            'CPT healthcare standards',
          ],
          practicalNotes:
              'Bring documentation of existing medical conditions and prescriptions. '
              'Waiting times for specialists can be long. Psychiatric care has been '
              'criticised by CPT in some facilities.',
        ),
        PrisonerRight(
          category: PrisonerRightCategory.religiousRights,
          title: 'Religious Rights',
          description:
              'Freedom of religion protected. Catholic, Protestant, Islamic, and '
              'Orthodox chaplains serve Austrian prisons. Halal and kosher meals '
              'available on request. Religious items (prayer mat, rosary, religious '
              'texts) allowed in cells. Religious holidays respected where practicable.',
          legalBasis: [
            'StVG §85',
            'Austrian Constitution — Staatsgrundgesetz Art. 14-16',
            'European Prison Rules Rule 29',
          ],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.immigrationConsequences,
          title: 'Immigration Consequences of Criminal Conviction',
          description:
              'Criminal conviction can lead to: revocation of residence permit, '
              'entry ban (up to 10 years or permanent), deportation order. '
              'Threshold: unconditional sentence of 6+ months for residence ban, '
              'or 1+ year for long-term residents. Proportionality assessment required '
              '(family ties, length of stay, integration).',
          legalBasis: [
            'Fremdenpolizeigesetz (FPG) §§53, 67',
            'Niederlassungs- und Aufenthaltsgesetz (NAG) §§11, 28',
            'EU Return Directive 2008/115/EC',
          ],
          practicalNotes:
              'EU/EEA citizens have higher protection threshold. Deportation for '
              'EU citizens only on grounds of public policy/security. Challenge '
              'deportation order at BVwG (Federal Administrative Court). '
              'Art. 8 ECHR (family life) is key defence.',
        ),
        PrisonerRight(
          category: PrisonerRightCategory.earlyReleaseParole,
          title: 'Early Release / Parole',
          description:
              'Conditional release possible after serving half the sentence '
              '(for sentences up to 3 years) or two-thirds (for longer sentences). '
              'Foreign prisoners are eligible on equal terms but practical barriers '
              'exist (no address, no employment). Electronic monitoring available.',
          legalBasis: [
            'StGB §46',
            'StVG §144',
          ],
          practicalNotes:
              'Foreign prisoners have significantly lower parole rates due to '
              'lack of social ties in Austria. A concrete release plan '
              '(accommodation, support) strengthens the application. If deportation '
              'is planned, early release may be combined with removal.',
        ),
        PrisonerRight(
          category: PrisonerRightCategory.deportationAfterSentence,
          title: 'Deportation After Sentence',
          description:
              'BFA (Federal Office for Immigration and Asylum) can issue a return '
              'decision during imprisonment. Deportation typically occurs directly '
              'from prison upon release. Detention pending deportation if release '
              'date and deportation cannot be coordinated. Non-refoulement protection '
              'applies — no deportation to countries with torture risk.',
          legalBasis: [
            'FPG §§46, 50-52',
            'BFA-VG',
            'EU Return Directive 2008/115/EC',
            'ECHR Art. 3 (non-refoulement)',
          ],
          practicalNotes:
              'File asylum claim if you fear persecution in home country — this '
              'suspends deportation. The BFA must assess non-refoulement before '
              'deportation. Legal aid for deportation proceedings available through '
              'BBU (Federal Agency for Care and Support).',
        ),
        PrisonerRight(
          category: PrisonerRightCategory.europeanArrestWarrant,
          title: 'European Arrest Warrant',
          description:
              'Austria executes EAWs through the Landesgericht (Regional Court). '
              'Time limit: 60 days from arrest, extendable to 90. Mandatory grounds '
              'for refusal include ne bis in idem and age of criminal responsibility. '
              'Austrian nationals may be surrendered but can request to serve sentence '
              'in Austria.',
          legalBasis: [
            'EU-JZG §§2-30',
            'EU Framework Decision 2002/584/JHA',
          ],
          practicalNotes:
              'You have the right to a lawyer and interpreter in EAW proceedings. '
              'You can consent to surrender (simplified procedure, usually 10 days) '
              'or contest it. Legal aid applies.',
        ),
      ],
      ngos: [
        PrisonerSupportNGO(
          name: 'NEUSTART',
          country: 'Austria',
          description:
              'Probation service and prisoner reintegration. Helps foreign prisoners '
              'with release planning, housing, and social support.',
          website: 'https://www.neustart.at',
          phone: '+43 1 545 95 60',
          languages: ['German', 'English', 'Turkish', 'Serbian'],
        ),
        PrisonerSupportNGO(
          name: 'Verein für Bewährungshilfe und soziale Arbeit',
          country: 'Austria',
          description: 'Probation and social work for prisoners and ex-prisoners.',
          website: 'https://www.neustart.at',
          languages: ['German', 'English'],
        ),
        PrisonerSupportNGO(
          name: 'Diakonie Flüchtlingsdienst',
          country: 'Austria',
          description:
              'Legal counselling for refugees and migrants in detention, '
              'including those with criminal proceedings.',
          website: 'https://fluechtlingsdienst.diakonie.at',
          languages: ['German', 'English', 'Arabic', 'Farsi'],
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 2. BELGIUM (BE)
    // -----------------------------------------------------------------------
    CountryPrisonerRights(
      countryCode: 'BE',
      countryName: 'Belgium',
      prisonAuthority: 'Service Public Fédéral Justice — Direction Générale des Établissements Pénitentiaires',
      prisonAuthorityWebsite: 'https://justice.belgium.be',
      approximatePrisonPopulation: 11200,
      foreignPrisonerPercentage: 44.0,
      rights: [
        PrisonerRight(
          category: PrisonerRightCategory.consularAccess,
          title: 'Consular Access',
          description:
              'Foreign detainees are informed of the right to contact their '
              'consulate upon admission. Belgian authorities notify the consulate '
              'if the prisoner requests it. Consular visits treated as privileged.',
          legalBasis: [
            'Vienna Convention Art. 36',
            'Belgian Code of Criminal Procedure Art. 2bis',
            'Loi de principes 2005 (Basic Principles Act)',
          ],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.interpreterRight,
          title: 'Right to Interpreter',
          description:
              'Free sworn interpreter from first police hearing. Belgium has three '
              'official languages (Dutch, French, German) — proceedings in language '
              'of the jurisdiction unless accused requests change. Translation of '
              'essential documents provided free of charge.',
          legalBasis: [
            'EU Directive 2010/64/EU (transposed 2014)',
            'Code of Criminal Procedure Art. 31',
            'Judicial Code Art. 30',
          ],
          practicalNotes:
              'Belgium has a National Register of Sworn Interpreters/Translators. '
              'Quality is generally good for common languages. Request interpreter '
              'in your specific dialect if needed (e.g., Moroccan Arabic vs Standard Arabic).',
        ),
        PrisonerRight(
          category: PrisonerRightCategory.transferToHomeCountry,
          title: 'Transfer to Home Country',
          description:
              'EU nationals: Framework Decision 2008/909/JHA implemented via Law of '
              '15 May 2012. Belgium actively transfers sentenced EU nationals. '
              'Non-EU: CoE Convention ETS 112 and bilateral treaties with Morocco, '
              'Turkey, and others. Belgium may initiate transfer without prisoner '
              'consent in deportation cases.',
          legalBasis: [
            'Loi du 15 mai 2012',
            'EU Framework Decision 2008/909/JHA',
            'CoE Convention ETS 112',
          ],
          practicalNotes:
              'High number of Moroccan nationals transferred annually under bilateral '
              'agreement. Process takes 6-18 months. Apply through prison social service.',
        ),
        PrisonerRight(
          category: PrisonerRightCategory.legalAidCriminal,
          title: 'Legal Aid',
          description:
              'Full free legal aid (aide juridique de deuxième ligne / juridische tweedelijnsbijstand) '
              'for persons without sufficient means. Income threshold: below €1,526/month gross. '
              'Automatic for detained persons. Bureau d\'aide juridique assigns lawyers.',
          legalBasis: [
            'Judicial Code Art. 508/1-508/25',
            'EU Directive 2016/1919/EU',
          ],
          practicalNotes:
              'Quality of assigned lawyers varies. You can request a specific lawyer. '
              'Salduz rights (lawyer present at first hearing) well implemented since 2011.',
        ),
        PrisonerRight(
          category: PrisonerRightCategory.prisonConditions,
          title: 'Prison Conditions',
          description:
              'Belgian prisons suffer from chronic overcrowding (CPT has repeatedly '
              'criticised conditions). Basic Principles Act 2005 establishes minimum '
              'standards. Single-cell principle in law but not always in practice. '
              'ECtHR has found violations (e.g., Vasilescu v. Belgium 2014).',
          legalBasis: [
            'Loi de principes 2005',
            'European Prison Rules',
            'CPT reports on Belgium',
          ],
          practicalNotes:
              'Overcrowding is worst in Brussels (Forest, Saint-Gilles) and Antwerp. '
              'Newer prisons (Haren, Leuze-en-Hainaut, Marche-en-Famenne) have better '
              'conditions. File complaints to Complaints Commission (Plaintes-Commission).',
        ),
        PrisonerRight(
          category: PrisonerRightCategory.communicationRights,
          title: 'Communication Rights',
          description:
              'Minimum 3 visits per month for sentenced prisoners, 3 per week for '
              'pre-trial. Phone calls available daily (pre-paid system). Letters '
              'unlimited, correspondence with lawyer is confidential. Video visits '
              'available in most prisons.',
          legalBasis: [
            'Loi de principes 2005 Art. 54-70',
            'Règlement général des établissements pénitentiaires',
          ],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.healthcareInPrison,
          title: 'Healthcare',
          description:
              'Medical care provided by prison medical service. Equivalence with '
              'community care required by law. Psychiatric care at specialised '
              'annexes (Merksplas, Paifve). Drug substitution available. CPT has '
              'criticised psychiatric care for internees (mentally ill offenders).',
          legalBasis: [
            'Loi de principes 2005 Art. 88-98',
            'European Prison Rules Rule 24',
          ],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.religiousRights,
          title: 'Religious Rights',
          description:
              'All recognised religions have chaplains in Belgian prisons: Catholic, '
              'Protestant, Islamic, Jewish, Orthodox, Anglican, and Buddhist counsellors. '
              'Islamic practice is well accommodated (halal meals, Ramadan schedules). '
              'Non-denominational moral counsellors also available.',
          legalBasis: [
            'Loi de principes 2005 Art. 71',
            'Belgian Constitution Art. 19-21',
          ],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.immigrationConsequences,
          title: 'Immigration Consequences',
          description:
              'Conviction may trigger: withdrawal of residence permit, entry ban '
              '(3-10+ years), removal order by Office des Étrangers. EU citizens: '
              'only on serious public policy/security grounds. Third-country nationals: '
              'any effective prison sentence can trigger proceedings.',
          legalBasis: [
            'Loi du 15 décembre 1980 (Immigration Act) Art. 20-26',
            'EU Directive 2004/38/EC (EU citizens)',
          ],
          practicalNotes:
              'Challenge removal orders at Conseil du Contentieux des Étrangers (CCE). '
              'Suspensive effect if risk of irreparable harm. Art. 8 ECHR defence important.',
        ),
        PrisonerRight(
          category: PrisonerRightCategory.earlyReleaseParole,
          title: 'Early Release / Parole',
          description:
              'Conditional release after one-third of sentence (first offenders) '
              'or two-thirds (recidivists). For sentences under 3 years: decision '
              'by prison director. Over 3 years: Tribunal de l\'application des peines. '
              'Foreign prisoners eligible but may face practical barriers.',
          legalBasis: [
            'Loi du 17 mai 2006 (Sentence Implementation Act)',
          ],
          practicalNotes:
              'Foreign prisoners without residence status are often released on '
              'condition of leaving Belgium. Electronic monitoring available as '
              'alternative for sentences under 3 years.',
        ),
        PrisonerRight(
          category: PrisonerRightCategory.deportationAfterSentence,
          title: 'Deportation After Sentence',
          description:
              'Office des Étrangers issues removal orders during imprisonment. '
              'Deportation can occur immediately upon release. Detention centres '
              '(centre fermé) used if deportation not immediately possible. '
              'Non-refoulement principle applies.',
          legalBasis: [
            'Loi du 15 décembre 1980 Art. 7, 25, 26',
            'EU Return Directive 2008/115/EC',
          ],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.europeanArrestWarrant,
          title: 'European Arrest Warrant',
          description:
              'Executed by Chambre du Conseil (Council Chamber). Belgium is an active '
              'issuer and executor of EAWs. Nationals can be surrendered but may request '
              'return to serve sentence. Proportionality concerns have been raised for '
              'minor offences.',
          legalBasis: [
            'Loi du 19 décembre 2003 (EAW Act)',
            'EU Framework Decision 2002/584/JHA',
          ],
        ),
      ],
      ngos: [
        PrisonerSupportNGO(
          name: 'Aide aux personnes déplacées (APD)',
          country: 'Belgium',
          description: 'Legal assistance to detained foreigners.',
          website: 'https://www.aideauxpersonnesdeplacees.be',
          languages: ['French', 'English', 'Arabic'],
        ),
        PrisonerSupportNGO(
          name: 'Ligue des Droits Humains',
          country: 'Belgium',
          description: 'Human rights organisation monitoring prison conditions.',
          website: 'https://www.liguedh.be',
          languages: ['French', 'English'],
        ),
        PrisonerSupportNGO(
          name: 'CIRÉ (Coordination et Initiatives pour Réfugiés et Étrangers)',
          country: 'Belgium',
          description: 'Support for refugees and foreigners including those in detention.',
          website: 'https://www.cire.be',
          languages: ['French', 'English'],
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 3. BULGARIA (BG)
    // -----------------------------------------------------------------------
    CountryPrisonerRights(
      countryCode: 'BG',
      countryName: 'Bulgaria',
      prisonAuthority: 'General Directorate for Execution of Punishments (GDIN)',
      prisonAuthorityWebsite: 'https://www.gdin.bg',
      approximatePrisonPopulation: 6100,
      foreignPrisonerPercentage: 3.5,
      rights: [
        PrisonerRight(
          category: PrisonerRightCategory.consularAccess,
          title: 'Consular Access',
          description:
              'Foreign prisoners informed of right to consular contact upon admission. '
              'Low foreign prisoner population means less established procedures. '
              'Consular visits facilitated on request.',
          legalBasis: [
            'Vienna Convention Art. 36',
            'Bulgarian Criminal Procedure Code Art. 15',
            'EU Directive 2013/48/EU',
          ],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.interpreterRight,
          title: 'Right to Interpreter',
          description:
              'Free interpreter at all stages of criminal proceedings. Translation of '
              'essential documents. Bulgaria transposed EU Directive 2010/64/EU in 2014.',
          legalBasis: [
            'Criminal Procedure Code Art. 21',
            'EU Directive 2010/64/EU',
          ],
          practicalNotes:
              'Limited availability of interpreters for rare languages. '
              'Quality concerns noted by European Commission in monitoring reports.',
        ),
        PrisonerRight(
          category: PrisonerRightCategory.transferToHomeCountry,
          title: 'Transfer to Home Country',
          description:
              'Transfer under FD 2008/909/JHA for EU nationals. CoE Convention ETS 112 '
              'for non-EU nationals. Ministry of Justice handles requests. Transfer rate '
              'is relatively low.',
          legalBasis: [
            'EU Framework Decision 2008/909/JHA',
            'Recognition of Foreign Judicial Acts Act (2012)',
            'CoE Convention ETS 112',
          ],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.legalAidCriminal,
          title: 'Legal Aid',
          description:
              'Free legal aid through National Legal Aid Bureau (NLAB). Mandatory defence '
              'for offences carrying 10+ years, for detained persons, and for vulnerable '
              'accused. Income test applies for other cases.',
          legalBasis: [
            'Legal Aid Act 2006',
            'Criminal Procedure Code Art. 94',
            'EU Directive 2016/1919/EU',
          ],
          practicalNotes:
              'Legal aid lawyer quality has been criticised. Low remuneration for '
              'assigned lawyers affects quality. European Commission has raised concerns.',
        ),
        PrisonerRight(
          category: PrisonerRightCategory.prisonConditions,
          title: 'Prison Conditions',
          description:
              'Conditions have historically been poor. CPT has reported severe overcrowding, '
              'inter-prisoner violence, poor sanitation, and lack of activities. '
              'ECtHR pilot judgment Neshkov v. Bulgaria (2015) led to reforms. '
              'New legislation requires minimum 4m² per prisoner.',
          legalBasis: [
            'Execution of Punishments and Detention Act',
            'ECtHR Neshkov and Others v. Bulgaria (2015)',
            'CPT reports on Bulgaria',
          ],
          practicalNotes:
              'Sofia Prison and Burgas Prison have the worst conditions. '
              'Newer sections of Plovdiv and Varna are better. Complaints possible '
              'to prison inspector and to Regional Court.',
        ),
        PrisonerRight(
          category: PrisonerRightCategory.communicationRights,
          title: 'Communication Rights',
          description:
              'Two visits per month (30 min each) for convicted prisoners. '
              'Phone access limited. Letters permitted but may be monitored. '
              'Lawyer visits unrestricted.',
          legalBasis: [
            'Execution of Punishments and Detention Act Art. 86-93',
          ],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.healthcareInPrison,
          title: 'Healthcare',
          description:
              'Each prison has a medical unit. Hospital ward at Sofia Prison. '
              'CPT has repeatedly criticised insufficient healthcare, inadequate '
              'psychiatric care, and lack of medication. Reforms ongoing.',
          legalBasis: [
            'Execution of Punishments Act Art. 128-137',
            'Health Act',
          ],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.religiousRights,
          title: 'Religious Rights',
          description:
              'Freedom of religion respected. Orthodox Christianity predominant — '
              'chaplains available. Muslim, Catholic, and Protestant religious services '
              'can be arranged. Religious items permitted.',
          legalBasis: [
            'Bulgarian Constitution Art. 37',
            'Execution of Punishments Act Art. 165',
          ],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.immigrationConsequences,
          title: 'Immigration Consequences',
          description:
              'Criminal conviction of foreigners may lead to expulsion order and entry ban. '
              'Foreigners Act provides for compulsory removal following criminal conviction. '
              'EU citizens: higher threshold (serious public policy/security).',
          legalBasis: [
            'Foreigners in the Republic of Bulgaria Act Art. 10, 42',
            'EU Directive 2004/38/EC',
          ],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.earlyReleaseParole,
          title: 'Early Release / Parole',
          description:
              'Conditional release after serving half the sentence (first offenders) '
              'or two-thirds (recidivists). Application to the Regional Court. '
              'Foreign prisoners eligible on equal terms.',
          legalBasis: [
            'Criminal Code Art. 70-74',
          ],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.deportationAfterSentence,
          title: 'Deportation After Sentence',
          description:
              'Expulsion orders enforced by Migration Directorate after sentence completion. '
              'Detention in Special Homes for Temporary Accommodation if removal not immediate. '
              'Non-refoulement obligations apply.',
          legalBasis: [
            'Foreigners Act Art. 44',
            'Asylum and Refugees Act',
          ],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.europeanArrestWarrant,
          title: 'European Arrest Warrant',
          description:
              'Implemented via Extradition and European Arrest Warrant Act (2005). '
              'Sofia City Court handles EAW execution. Bulgarian nationals can be '
              'surrendered with guarantee of return to serve sentence.',
          legalBasis: [
            'Extradition and EAW Act 2005',
            'EU Framework Decision 2002/584/JHA',
          ],
        ),
      ],
      ngos: [
        PrisonerSupportNGO(
          name: 'Bulgarian Helsinki Committee',
          country: 'Bulgaria',
          description:
              'Human rights monitoring including prison conditions. '
              'Provides legal assistance to detained foreigners.',
          website: 'https://www.bghelsinki.org',
          languages: ['Bulgarian', 'English'],
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 4. CROATIA (HR)
    // -----------------------------------------------------------------------
    CountryPrisonerRights(
      countryCode: 'HR',
      countryName: 'Croatia',
      prisonAuthority: 'Uprava za zatvorski sustav i probaciju (Directorate for Prison System and Probation)',
      prisonAuthorityWebsite: 'https://pravosudje.gov.hr',
      approximatePrisonPopulation: 3200,
      foreignPrisonerPercentage: 8.0,
      rights: [
        PrisonerRight(
          category: PrisonerRightCategory.consularAccess,
          title: 'Consular Access',
          description:
              'Foreign prisoners informed of consular access right at admission. '
              'Prison administration assists with consular communication.',
          legalBasis: [
            'Vienna Convention Art. 36',
            'Croatian Criminal Procedure Act Art. 8',
            'Execution of Prison Sentences Act Art. 13',
          ],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.interpreterRight,
          title: 'Right to Interpreter',
          description:
              'Free interpreter in criminal proceedings. Translation of key documents. '
              'Croatia transposed Directive 2010/64/EU upon EU accession in 2013.',
          legalBasis: [
            'Criminal Procedure Act Art. 8',
            'EU Directive 2010/64/EU',
          ],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.transferToHomeCountry,
          title: 'Transfer to Home Country',
          description:
              'EU transfers under FD 2008/909/JHA implemented through Judicial '
              'Cooperation in Criminal Matters with EU Member States Act. '
              'CoE Convention ETS 112 for non-EU states. Ministry of Justice processes.',
          legalBasis: [
            'EU Framework Decision 2008/909/JHA',
            'Judicial Cooperation Act (2010, amended 2013)',
            'CoE Convention ETS 112',
          ],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.legalAidCriminal,
          title: 'Legal Aid',
          description:
              'Free legal aid available for accused who cannot afford a lawyer. '
              'Mandatory defence for offences with 8+ year maximum penalty, '
              'for detained persons, and for mute/deaf/juvenile accused.',
          legalBasis: [
            'Criminal Procedure Act Art. 65-66',
            'Free Legal Aid Act (2013)',
            'EU Directive 2016/1919/EU',
          ],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.prisonConditions,
          title: 'Prison Conditions',
          description:
              'Generally acceptable standards. Some overcrowding in Zagreb (Remetinec). '
              'CPT found generally adequate conditions in recent visits. '
              'Minimum 4m² per prisoner in multi-occupancy cells.',
          legalBasis: [
            'Execution of Prison Sentences Act (2013)',
            'European Prison Rules',
          ],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.communicationRights,
          title: 'Communication Rights',
          description:
              'Visits at least twice monthly. Phone calls available. '
              'Letters permitted with monitoring in pre-trial. '
              'Lawyer-client correspondence confidential.',
          legalBasis: ['Execution of Prison Sentences Act Art. 117-128'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.healthcareInPrison,
          title: 'Healthcare',
          description:
              'Prison medical service in each facility. Hospital ward at Prison '
              'Hospital Zagreb. Specialist referrals available. Mental health '
              'care provided. Drug substitution therapy available.',
          legalBasis: ['Execution of Prison Sentences Act Art. 100-112'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.religiousRights,
          title: 'Religious Rights',
          description:
              'Catholic chaplaincy well established. Other denominations accommodated '
              'upon request. Religious items permitted in cells.',
          legalBasis: [
            'Croatian Constitution Art. 40',
            'Execution of Prison Sentences Act Art. 82',
          ],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.immigrationConsequences,
          title: 'Immigration Consequences',
          description:
              'Criminal conviction can lead to termination of residence and return '
              'decision. EU citizens: public policy/security threshold. Third-country '
              'nationals: proportionality assessment considering family ties.',
          legalBasis: [
            'Foreigners Act Art. 104-115',
            'EU Directive 2004/38/EC',
          ],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.earlyReleaseParole,
          title: 'Early Release / Parole',
          description:
              'Conditional release after half the sentence (two-thirds for recidivists). '
              'Application to sentencing court. Foreign prisoners eligible.',
          legalBasis: ['Criminal Code Art. 59'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.deportationAfterSentence,
          title: 'Deportation After Sentence',
          description:
              'Return decision issued by Ministry of Interior during imprisonment. '
              'Deportation after sentence completion. Non-refoulement applies.',
          legalBasis: [
            'Foreigners Act Art. 112-115',
            'EU Return Directive 2008/115/EC',
          ],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.europeanArrestWarrant,
          title: 'European Arrest Warrant',
          description:
              'County Court (Županijski sud) handles EAW execution. '
              'Implemented through Judicial Cooperation Act. Standard EU rules apply.',
          legalBasis: [
            'Judicial Cooperation Act',
            'EU Framework Decision 2002/584/JHA',
          ],
        ),
      ],
      ngos: [
        PrisonerSupportNGO(
          name: 'Croatian Helsinki Committee',
          country: 'Croatia',
          description: 'Monitors detention conditions, legal assistance for foreigners.',
          website: 'https://www.hho.hr',
          languages: ['Croatian', 'English'],
        ),
        PrisonerSupportNGO(
          name: 'Centre for Peace Studies (CMS)',
          country: 'Croatia',
          description: 'Legal aid and advocacy for refugees and migrants in detention.',
          website: 'https://www.cms.hr',
          languages: ['Croatian', 'English'],
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 5. CYPRUS (CY)
    // -----------------------------------------------------------------------
    CountryPrisonerRights(
      countryCode: 'CY',
      countryName: 'Cyprus',
      prisonAuthority: 'Department of Prisons — Ministry of Justice and Public Order',
      prisonAuthorityWebsite: 'https://www.mjpo.gov.cy',
      approximatePrisonPopulation: 800,
      foreignPrisonerPercentage: 40.0,
      rights: [
        PrisonerRight(
          category: PrisonerRightCategory.consularAccess,
          title: 'Consular Access',
          description:
              'Right to consular contact upon arrest and detention. Nicosia Central '
              'Prison accommodates consular visits. High foreign prisoner rate means '
              'established procedures.',
          legalBasis: ['Vienna Convention Art. 36', 'Criminal Procedure Law Cap. 155'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.interpreterRight,
          title: 'Right to Interpreter',
          description:
              'Free interpretation at all stages. Cyprus transposed EU Directive 2010/64/EU. '
              'Greek and Turkish are official languages. English widely spoken by legal '
              'professionals.',
          legalBasis: ['EU Directive 2010/64/EU', 'Criminal Procedure Law Cap. 155'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.transferToHomeCountry,
          title: 'Transfer to Home Country',
          description:
              'FD 2008/909/JHA implemented. CoE Convention ETS 112 for non-EU states. '
              'Applications through Ministry of Justice.',
          legalBasis: ['EU Framework Decision 2008/909/JHA', 'Transfer of Sentenced Persons Law'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.legalAidCriminal,
          title: 'Legal Aid',
          description:
              'Free legal aid available under Legal Aid Law for persons who cannot '
              'afford representation. Mandatory for serious offences. Application '
              'through the court.',
          legalBasis: ['Legal Aid Law 2002 (as amended)', 'EU Directive 2016/1919/EU'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.prisonConditions,
          title: 'Prison Conditions',
          description:
              'Only one prison: Nicosia Central Prison. Chronic overcrowding '
              'criticised by CPT. Conditions have improved following investment '
              'but capacity remains an issue. Separate wings for different categories.',
          legalBasis: ['Prisons Law Cap. 286', 'CPT reports on Cyprus'],
          practicalNotes:
              'New prison facility planned. Drug unit and psychiatric wing available. '
              'Complaints to Prison Board or Ombudsman.',
        ),
        PrisonerRight(
          category: PrisonerRightCategory.communicationRights,
          title: 'Communication Rights',
          description:
              'Weekly visits. Phone calls available. Letters unrestricted for '
              'sentenced prisoners. Lawyer visits confidential.',
          legalBasis: ['Prison Regulations'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.healthcareInPrison,
          title: 'Healthcare',
          description:
              'Medical unit at Nicosia Central Prison. Hospital referrals for '
              'specialist care. Mental health services available. '
              'Drug rehabilitation programme.',
          legalBasis: ['Prisons Law Cap. 286'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.religiousRights,
          title: 'Religious Rights',
          description:
              'Orthodox Christian chaplaincy. Muslim prayer accommodated. '
              'Other faiths served by visiting ministers. Religious items permitted.',
          legalBasis: ['Cyprus Constitution Art. 18', 'Prisons Law'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.immigrationConsequences,
          title: 'Immigration Consequences',
          description:
              'Criminal conviction can result in deportation order. High rate '
              'of deportation for foreign prisoners after sentence completion.',
          legalBasis: ['Aliens and Immigration Law Cap. 105', 'EU Directive 2004/38/EC'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.earlyReleaseParole,
          title: 'Early Release / Parole',
          description:
              'Conditional release by Release Board after serving portion of sentence. '
              'Foreign prisoners eligible but often released for deportation.',
          legalBasis: ['Prisons Law Cap. 286'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.deportationAfterSentence,
          title: 'Deportation After Sentence',
          description:
              'Immigration authorities issue deportation orders during imprisonment. '
              'Deportation directly from prison common. Detention at Menoyia '
              'Detention Centre if removal delayed.',
          legalBasis: ['Aliens and Immigration Law', 'EU Return Directive 2008/115/EC'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.europeanArrestWarrant,
          title: 'European Arrest Warrant',
          description:
              'EAW implemented in Cypriot law. District Courts handle execution. '
              'Standard EU procedures apply.',
          legalBasis: ['European Arrest Warrant Law 2004', 'EU FD 2002/584/JHA'],
        ),
      ],
      ngos: [
        PrisonerSupportNGO(
          name: 'KISA (Κίνηση για Ισότητα, Στήριξη, Αντιρατσισμό)',
          country: 'Cyprus',
          description: 'Equality, support, antiracism. Assists detained migrants and asylum seekers.',
          website: 'https://kisa.org.cy',
          languages: ['Greek', 'English', 'Turkish'],
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 6. CZECH REPUBLIC (CZ)
    // -----------------------------------------------------------------------
    CountryPrisonerRights(
      countryCode: 'CZ',
      countryName: 'Czech Republic',
      prisonAuthority: 'Vězeňská služba České republiky (Prison Service of the Czech Republic)',
      prisonAuthorityWebsite: 'https://www.vscr.cz',
      approximatePrisonPopulation: 19500,
      foreignPrisonerPercentage: 8.5,
      rights: [
        PrisonerRight(
          category: PrisonerRightCategory.consularAccess,
          title: 'Consular Access',
          description:
              'Foreign prisoners informed of right to consular notification. '
              'Prison Service facilitates consular visits. Established procedures '
              'particularly for Vietnamese, Ukrainian, and Slovak nationals.',
          legalBasis: ['Vienna Convention Art. 36', 'Criminal Procedure Code §36'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.interpreterRight,
          title: 'Right to Interpreter',
          description:
              'Free interpreter from first police questioning through trial. '
              'Certified translators for essential documents. Well-implemented '
              'for common languages (Slovak, Vietnamese, Ukrainian, Russian).',
          legalBasis: ['Criminal Procedure Code §28', 'EU Directive 2010/64/EU'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.transferToHomeCountry,
          title: 'Transfer to Home Country',
          description:
              'Active participant in FD 2008/909/JHA transfers. Bilateral agreements '
              'with Slovakia enhance transfers. Ministry of Justice processes applications. '
              'CoE Convention ETS 112 for non-EU states.',
          legalBasis: [
            'Act on International Judicial Cooperation in Criminal Matters (104/2013)',
            'EU Framework Decision 2008/909/JHA',
          ],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.legalAidCriminal,
          title: 'Legal Aid',
          description:
              'Free legal representation for detained persons and for offences '
              'with 5+ years maximum. Czech Bar Association assigns ex officio lawyers. '
              'Income test for other cases.',
          legalBasis: ['Criminal Procedure Code §33-40', 'EU Directive 2016/1919/EU'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.prisonConditions,
          title: 'Prison Conditions',
          description:
              'Four security categories. Standards generally acceptable. '
              'CPT noted improvements in recent years. Minimum living space '
              '4m² per person. Separation of pre-trial and sentenced prisoners.',
          legalBasis: ['Act on Imprisonment (169/1999)', 'European Prison Rules'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.communicationRights,
          title: 'Communication Rights',
          description:
              'Minimum one visit per month (3 hours) for sentenced prisoners. '
              'Phone calls available via pre-paid system. Letters unrestricted. '
              'Video calls introduced. Lawyer visits unrestricted and confidential.',
          legalBasis: ['Act on Imprisonment §§18-19, 26-27'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.healthcareInPrison,
          title: 'Healthcare',
          description:
              'Prison hospital in Brno. Medical units in all prisons. '
              'Drug substitution therapy available. Psychiatric care provided. '
              'Dental services included.',
          legalBasis: ['Act on Imprisonment §§24-25'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.religiousRights,
          title: 'Religious Rights',
          description:
              'Catholic and Protestant chaplains. Other denominations accommodated. '
              'Religious items permitted. Czech Republic is highly secular — '
              'non-religious counselling available.',
          legalBasis: ['Charter of Fundamental Rights Art. 15-16', 'Act on Imprisonment §20'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.immigrationConsequences,
          title: 'Immigration Consequences',
          description:
              'Conviction may lead to administrative expulsion or judicial expulsion '
              '(can be imposed as criminal punishment). Entry ban 1-10 years. '
              'EU citizens: serious public policy/security grounds only.',
          legalBasis: ['Foreigners Residence Act (326/1999) §118-120', 'Criminal Code §80'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.earlyReleaseParole,
          title: 'Early Release / Parole',
          description:
              'Conditional release after half (standard), one-third (good conduct), '
              'or two-thirds (serious offences). Foreign prisoners eligible on equal terms.',
          legalBasis: ['Criminal Code §§88-91'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.deportationAfterSentence,
          title: 'Deportation After Sentence',
          description:
              'Alien Police enforce expulsion after sentence. Detention facility at '
              'Bělá-Jezová if immediate removal not possible. Non-refoulement applies.',
          legalBasis: ['Foreigners Residence Act §§123-129', 'EU Return Directive 2008/115/EC'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.europeanArrestWarrant,
          title: 'European Arrest Warrant',
          description:
              'Regional Courts handle EAW execution. Czech nationals can be surrendered. '
              'Dual criminality not required for listed offences.',
          legalBasis: ['Act 104/2013', 'EU Framework Decision 2002/584/JHA'],
        ),
      ],
      ngos: [
        PrisonerSupportNGO(
          name: 'Organisation for Aid to Refugees (OPU)',
          country: 'Czech Republic',
          description: 'Legal counselling for detained foreigners and asylum seekers.',
          website: 'https://www.opu.cz',
          languages: ['Czech', 'English', 'Russian', 'Arabic'],
        ),
        PrisonerSupportNGO(
          name: 'Czech Helsinki Committee',
          country: 'Czech Republic',
          description: 'Human rights monitoring, prison conditions oversight.',
          website: 'https://www.helcom.cz',
          languages: ['Czech', 'English'],
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 7. DENMARK (DK)
    // -----------------------------------------------------------------------
    CountryPrisonerRights(
      countryCode: 'DK',
      countryName: 'Denmark',
      prisonAuthority: 'Kriminalforsorgen (Danish Prison and Probation Service)',
      prisonAuthorityWebsite: 'https://www.kriminalforsorgen.dk',
      approximatePrisonPopulation: 3800,
      foreignPrisonerPercentage: 30.0,
      rights: [
        PrisonerRight(
          category: PrisonerRightCategory.consularAccess,
          title: 'Consular Access',
          description:
              'Foreign prisoners informed of consular rights at intake. '
              'Denmark has strong procedural safeguards for consular access.',
          legalBasis: ['Vienna Convention Art. 36', 'Administration of Justice Act §758'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.interpreterRight,
          title: 'Right to Interpreter',
          description:
              'Free interpreter at all stages. Denmark has high standards for '
              'interpretation. National register of certified interpreters. '
              'Arabic, Turkish, Somali, and Polish interpreters widely available.',
          legalBasis: ['Administration of Justice Act §149', 'EU Directive 2010/64/EU'],
          practicalNotes: 'Denmark has opt-out from EU Justice area but voluntarily '
              'aligns with most procedural rights directives.',
        ),
        PrisonerRight(
          category: PrisonerRightCategory.transferToHomeCountry,
          title: 'Transfer to Home Country',
          description:
              'Denmark opted out of EU Justice cooperation but participates in '
              'FD 2008/909/JHA through a parallel agreement. CoE Convention ETS 112 '
              'for non-EU. Nordic Enforcement Agreement for Nordic countries.',
          legalBasis: [
            'International Enforcement of Sentences Act',
            'CoE Convention ETS 112',
            'Nordic Enforcement Agreement',
          ],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.legalAidCriminal,
          title: 'Legal Aid',
          description:
              'Right to court-appointed defence counsel (beskikket forsvarer) '
              'for all serious cases. Free for detained persons. Denmark has '
              'generous legal aid system.',
          legalBasis: ['Administration of Justice Act §§730-742'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.prisonConditions,
          title: 'Prison Conditions',
          description:
              'Generally high standards. Open and closed prisons. Single cells '
              'standard. Activities, education, and work programmes. CPT has '
              'praised Danish conditions overall, with some concerns about '
              'immigration detainees in Ellebæk.',
          legalBasis: ['Enforcement of Sentences Act', 'European Prison Rules'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.communicationRights,
          title: 'Communication Rights',
          description:
              'Visits at least once weekly (open prisons: more flexible). '
              'Phone access in cells (open prisons) or payphones. Letters unrestricted. '
              'Internet access for education in some prisons.',
          legalBasis: ['Enforcement of Sentences Act §§51-56'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.healthcareInPrison,
          title: 'Healthcare',
          description:
              'High standard. Prison health service with nurses. Doctor visits regular. '
              'Hospital referrals for specialist care. Psychiatric care available. '
              'Drug treatment programmes.',
          legalBasis: ['Enforcement of Sentences Act §§45-46'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.religiousRights,
          title: 'Religious Rights',
          description:
              'Lutheran chaplains in all prisons. Muslim, Catholic, and other '
              'religious counsellors available. Halal meals provided. '
              'Prayer rooms available.',
          legalBasis: ['Danish Constitution §67-68', 'Enforcement of Sentences Act'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.immigrationConsequences,
          title: 'Immigration Consequences',
          description:
              'Denmark has strict immigration consequences for criminal convictions. '
              'Unconditional sentence leads to assessment for expulsion. Courts can '
              'impose expulsion as part of criminal sentence. Low threshold. '
              'EU citizens: higher protection but Denmark applies strict standards.',
          legalBasis: [
            'Aliens Act §§22-26',
            'Criminal Code §§24a-24d (judicial expulsion)',
          ],
          practicalNotes:
              'Denmark is among the strictest EU countries for expulsion of foreign '
              'criminals. Even relatively minor offences can trigger expulsion. '
              'Recent legislation lowered thresholds further.',
        ),
        PrisonerRight(
          category: PrisonerRightCategory.earlyReleaseParole,
          title: 'Early Release / Parole',
          description:
              'Standard release after two-thirds of sentence. Early release after '
              'half possible for good conduct. Foreign prisoners with expulsion '
              'orders may be released early for deportation.',
          legalBasis: ['Criminal Code §§38-40'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.deportationAfterSentence,
          title: 'Deportation After Sentence',
          description:
              'Judicial expulsion enforced immediately after sentence. '
              'Immigration Service coordinates with Prison Service. '
              'Detention at Ellebæk if immediate removal not possible. '
              'Tolerated stay status if deportation impossible.',
          legalBasis: ['Aliens Act §§30-36', 'EU Return Directive (limited application)'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.europeanArrestWarrant,
          title: 'European Arrest Warrant',
          description:
              'Denmark participates via separate agreement with the EU (2019). '
              'City Court handles EAW execution. Additional human rights safeguards '
              'compared to standard EU framework.',
          legalBasis: [
            'Nordic Arrest Warrant Act',
            'Extradition Act',
            'EU-Denmark EAW Agreement',
          ],
        ),
      ],
      ngos: [
        PrisonerSupportNGO(
          name: 'Danish Institute for Human Rights',
          country: 'Denmark',
          description: 'Monitors prison conditions and immigration detention.',
          website: 'https://www.humanrights.dk',
          languages: ['Danish', 'English'],
        ),
        PrisonerSupportNGO(
          name: 'Refugees Welcome (Venligboerne)',
          country: 'Denmark',
          description: 'Support for refugees including those in detention.',
          website: 'https://refugees-welcome.dk',
          languages: ['Danish', 'English', 'Arabic'],
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 8. ESTONIA (EE)
    // -----------------------------------------------------------------------
    CountryPrisonerRights(
      countryCode: 'EE',
      countryName: 'Estonia',
      prisonAuthority: 'Justiitsministeerium — Vanglateenistus (Prison Service)',
      prisonAuthorityWebsite: 'https://www.vangla.ee',
      approximatePrisonPopulation: 2400,
      foreignPrisonerPercentage: 35.0,
      rights: [
        PrisonerRight(
          category: PrisonerRightCategory.consularAccess,
          title: 'Consular Access',
          description:
              'Right to consular contact upon arrest. High percentage of Russian-speaking '
              'prisoners (including stateless persons with Estonian grey passports).',
          legalBasis: ['Vienna Convention Art. 36', 'Code of Criminal Procedure §34'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.interpreterRight,
          title: 'Right to Interpreter',
          description:
              'Free interpreter. Estonian and Russian both widely used in practice. '
              'Proceedings in Estonian; interpretation into Russian well-established.',
          legalBasis: ['Code of Criminal Procedure §10', 'EU Directive 2010/64/EU'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.transferToHomeCountry,
          title: 'Transfer to Home Country',
          description:
              'FD 2008/909/JHA implemented. Transfers mostly to/from Russia and Latvia. '
              'CoE Convention ETS 112 for non-EU states.',
          legalBasis: ['EU Framework Decision 2008/909/JHA', 'International Judicial Cooperation Act'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.legalAidCriminal,
          title: 'Legal Aid',
          description:
              'State-funded legal aid through Estonian Bar Association. Mandatory defence '
              'for serious offences. Income test for other cases.',
          legalBasis: ['State Legal Aid Act', 'Code of Criminal Procedure §43', 'EU Directive 2016/1919/EU'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.prisonConditions,
          title: 'Prison Conditions',
          description:
              'Major prison reform: old Soviet-era prisons replaced with modern '
              'facilities (Tallinn Prison 2008, Tartu Prison 2002, new Tallinn Prison 2018). '
              'Conditions now among best in Eastern Europe. Single cells standard.',
          legalBasis: ['Imprisonment Act', 'European Prison Rules'],
          practicalNotes:
              'Estonia has dramatically improved prison conditions. '
              'CPT praised new facilities. Activities and education programmes available.',
        ),
        PrisonerRight(
          category: PrisonerRightCategory.communicationRights,
          title: 'Communication Rights',
          description:
              'Short visits and long visits (contact visits). Phone calls via pre-paid '
              'system. Letters permitted. Video calls available. Lawyer visits confidential.',
          legalBasis: ['Imprisonment Act §§23-28'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.healthcareInPrison,
          title: 'Healthcare',
          description:
              'Medical service in all prisons. Tallinn Prison has medical department. '
              'Hospital referrals available. Mental health care provided. HIV and TB '
              'treatment programmes (historically high rates in Estonian prisons).',
          legalBasis: ['Imprisonment Act §§49-52'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.religiousRights,
          title: 'Religious Rights',
          description:
              'Orthodox and Lutheran chaplains. Muslim and other religious services '
              'can be arranged. Estonia is largely secular. Religious items permitted.',
          legalBasis: ['Estonian Constitution §40', 'Imprisonment Act §23'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.immigrationConsequences,
          title: 'Immigration Consequences',
          description:
              'Conviction can lead to residence permit revocation and obligation to leave. '
              'Stateless persons with grey passports face particular issues. '
              'EU citizens: higher protection threshold.',
          legalBasis: ['Obligation to Leave and Prohibition on Entry Act', 'Aliens Act'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.earlyReleaseParole,
          title: 'Early Release / Parole',
          description:
              'Release on parole after half (first offenders, sentence up to 5 years), '
              'or two-thirds of sentence. Foreign prisoners eligible.',
          legalBasis: ['Penal Code §§76-78'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.deportationAfterSentence,
          title: 'Deportation After Sentence',
          description:
              'Police and Border Guard Board enforces removal. Detention pending '
              'removal possible. Non-refoulement applies. Particular complexity for '
              'stateless persons.',
          legalBasis: ['Obligation to Leave Act', 'EU Return Directive 2008/115/EC'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.europeanArrestWarrant,
          title: 'European Arrest Warrant',
          description:
              'Harju County Court handles EAW execution. Estonian nationals can be '
              'surrendered with return guarantee.',
          legalBasis: ['EU Framework Decision 2002/584/JHA', 'Code of Criminal Procedure §§489-510'],
        ),
      ],
      ngos: [
        PrisonerSupportNGO(
          name: 'Estonian Human Rights Centre',
          country: 'Estonia',
          description: 'Human rights monitoring including prison conditions.',
          website: 'https://humanrights.ee',
          languages: ['Estonian', 'English', 'Russian'],
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 9. FINLAND (FI)
    // -----------------------------------------------------------------------
    CountryPrisonerRights(
      countryCode: 'FI',
      countryName: 'Finland',
      prisonAuthority: 'Rikosseuraamuslaitos (Criminal Sanctions Agency)',
      prisonAuthorityWebsite: 'https://www.rikosseuraamuslaitos.fi',
      approximatePrisonPopulation: 2800,
      foreignPrisonerPercentage: 17.0,
      rights: [
        PrisonerRight(
          category: PrisonerRightCategory.consularAccess,
          title: 'Consular Access',
          description:
              'Foreign prisoners are informed of their right to contact their '
              'consulate at intake. Finland strictly respects Vienna Convention '
              'obligations. Prison staff assist with consular communication.',
          legalBasis: [
            'Vienna Convention Art. 36',
            'Criminal Investigation Act Ch. 4 §10',
            'Imprisonment Act 767/2005 §1:5',
          ],
          practicalNotes:
              'Estonian and Russian nationals are the largest foreign prisoner groups. '
              'Consular access is well facilitated. Request immediately upon detention.',
        ),
        PrisonerRight(
          category: PrisonerRightCategory.interpreterRight,
          title: 'Right to Interpreter',
          description:
              'Free interpreter at all stages of criminal proceedings. Finland has '
              'constitutional protection for language rights. Official languages: '
              'Finnish and Swedish. Translation of essential documents provided. '
              'High quality interpretation services.',
          legalBasis: [
            'Finnish Constitution §17 (language rights)',
            'Criminal Procedure Act §6:2-3',
            'EU Directive 2010/64/EU',
            'Language Act 423/2003',
          ],
          practicalNotes:
              'Russian, Estonian, Arabic, Somali, and English interpreters readily '
              'available. Rare languages may take longer to arrange. Video remote '
              'interpretation increasingly used.',
        ),
        PrisonerRight(
          category: PrisonerRightCategory.transferToHomeCountry,
          title: 'Transfer to Home Country',
          description:
              'FD 2008/909/JHA implemented via Act on Mutual Recognition of Criminal '
              'Sanctions (EU) 2011. Nordic Enforcement of Sentences Agreement provides '
              'simplified transfer between Nordic countries. CoE Convention ETS 112 '
              'for non-EU states.',
          legalBasis: [
            'Act on International Cooperation in the Enforcement of Criminal Sanctions (21/1987)',
            'Act on Mutual Recognition (EU) 2011',
            'Nordic Enforcement Agreement',
            'CoE Convention ETS 112',
          ],
          practicalNotes:
              'Transfers to Estonia are common. Nordic transfer is faster (1-3 months). '
              'Apply through prison director. Ministry of Justice makes final decision.',
        ),
        PrisonerRight(
          category: PrisonerRightCategory.legalAidCriminal,
          title: 'Legal Aid',
          description:
              'Comprehensive public legal aid system. Free legal counsel for '
              'detained persons. Income-based for others (income up to €1,500/month '
              '= fully free). Public Legal Aid Offices across the country. '
              'Private lawyers can provide legal aid with state funding.',
          legalBasis: [
            'Legal Aid Act 257/2002',
            'Criminal Procedure Act §2:1',
            'EU Directive 2016/1919/EU',
          ],
          practicalNotes:
              'Apply at any Legal Aid Office or through the court. Response within '
              'days. Finnish legal aid system is considered among the best in Europe. '
              'You can choose your lawyer within the system.',
        ),
        PrisonerRight(
          category: PrisonerRightCategory.prisonConditions,
          title: 'Prison Conditions',
          description:
              'High standard. Open and closed prisons. Single cells in closed prisons. '
              'Cell size meets European standards. Activities, education, and work '
              'available. Low prisoner-to-staff ratio. CPT has consistently praised '
              'Finnish conditions with minor recommendations.',
          legalBasis: [
            'Imprisonment Act 767/2005',
            'Remand Imprisonment Act 768/2005',
            'European Prison Rules',
          ],
          practicalNotes:
              'Open prisons (e.g., Kerava, Suomenlinna) offer significant freedoms. '
              'Closed prisons (Helsinki, Riihimäki) are more restrictive but conditions '
              'remain good. Nordic model focuses on rehabilitation.',
        ),
        PrisonerRight(
          category: PrisonerRightCategory.communicationRights,
          title: 'Communication Rights',
          description:
              'Regular visits (supervised and unsupervised). Phone calls available '
              'daily in most prisons. Letters unrestricted. Email-based messaging system '
              '(Priha) in some prisons. Video calls available. Lawyer visits '
              'confidential and unrestricted.',
          legalBasis: [
            'Imprisonment Act Ch. 12-13',
            'Remand Imprisonment Act Ch. 8-9',
          ],
          practicalNotes:
              'Open prison inmates may have mobile phones and more contact with outside '
              'world. International calls permitted. Family visits facilitated.',
        ),
        PrisonerRight(
          category: PrisonerRightCategory.healthcareInPrison,
          title: 'Healthcare',
          description:
              'Healthcare provided by Vankiterveydenhuollon yksikkö (Prison Health Unit) '
              'under Health Care Services for Prisoners Act. Equivalent to community care. '
              'Every prison has nursing staff. Psychiatric unit at Vantaa Prison. '
              'Hospital at Hämeenlinna. Drug rehabilitation programmes available.',
          legalBasis: [
            'Imprisonment Act Ch. 10',
            'Health Care Act',
            'Health Care Services for Prisoners Act 2015',
          ],
          practicalNotes:
              'Bring documentation of existing conditions and medications. '
              'Mental health services well-developed. Substance abuse treatment '
              'programmes available.',
        ),
        PrisonerRight(
          category: PrisonerRightCategory.religiousRights,
          title: 'Religious Rights',
          description:
              'Lutheran and Orthodox chaplains in all prisons. Muslim, Catholic, '
              'and other religious services arranged. Prayer rooms available. '
              'Religious diet accommodated. Religious literature and items permitted.',
          legalBasis: [
            'Finnish Constitution §11',
            'Imprisonment Act §11:3',
          ],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.immigrationConsequences,
          title: 'Immigration Consequences',
          description:
              'Criminal conviction may lead to deportation decision by Finnish '
              'Immigration Service (Migri). Threshold varies: serious crime for '
              'long-term residents, lower for recent arrivals. EU citizens: '
              'only on serious public policy/security grounds. Proportionality '
              'assessment required (family ties, length of stay, integration, '
              'best interests of children).',
          legalBasis: [
            'Aliens Act 301/2004 §§149-150 (deportation)',
            'Aliens Act §§168-170 (entry bans)',
            'EU Directive 2004/38/EC',
          ],
          practicalNotes:
              'Migri initiates proceedings during imprisonment. You can appeal to '
              'Administrative Court, then to Supreme Administrative Court. '
              'Legal aid available for immigration proceedings. Art. 8 ECHR '
              '(family life) is a key defence. Finnish courts give significant '
              'weight to best interests of children.',
        ),
        PrisonerRight(
          category: PrisonerRightCategory.earlyReleaseParole,
          title: 'Early Release / Parole',
          description:
              'Conditional release (ehdonalainen vapaus) after half the sentence '
              '(first offenders) or two-thirds (recidivists). Supervision period '
              'follows. Foreign prisoners eligible on equal terms. Supervised '
              'probationary freedom (valvottu koevapaus) up to 6 months before '
              'conditional release.',
          legalBasis: [
            'Criminal Code Ch. 2c §§5-15',
            'Imprisonment Act Ch. 20 (supervised probationary freedom)',
          ],
          practicalNotes:
              'Foreign prisoners may face barriers for koevapaus if they lack an '
              'address in Finland. Apply through prison staff well in advance. '
              'Good conduct record matters.',
        ),
        PrisonerRight(
          category: PrisonerRightCategory.deportationAfterSentence,
          title: 'Deportation After Sentence',
          description:
              'Migri issues deportation decision. Police enforce removal upon release. '
              'If deportation not immediately possible, detention at Metsälä Detention '
              'Unit (Helsinki) or Konnunsuo. Maximum immigration detention: 6 months '
              '(12 months in exceptional cases). Non-refoulement strictly observed.',
          legalBasis: [
            'Aliens Act §§148-150, 200-201',
            'Act on the Treatment of Detained Aliens 116/2002',
            'EU Return Directive 2008/115/EC',
          ],
          practicalNotes:
              'File asylum claim if you fear persecution — this suspends deportation. '
              'Parliamentary Ombudsman monitors detention conditions. Finnish Red Cross '
              'has access to detention facilities.',
        ),
        PrisonerRight(
          category: PrisonerRightCategory.europeanArrestWarrant,
          title: 'European Arrest Warrant',
          description:
              'District Court handles EAW execution. Finnish nationals can be '
              'surrendered but may request to serve sentence in Finland. '
              'Nordic Arrest Warrant provides simplified procedure with Nordic countries. '
              'Time limits strictly observed.',
          legalBasis: [
            'EU Surrender Act (1286/2003)',
            'Nordic Arrest Warrant Act (1383/2007)',
            'EU Framework Decision 2002/584/JHA',
          ],
        ),
      ],
      ngos: [
        PrisonerSupportNGO(
          name: 'KRIS Finland',
          country: 'Finland',
          description:
              'Peer support organisation for prisoners and ex-prisoners. '
              'Helps with reintegration, housing, and employment.',
          website: 'https://www.kfriseura.fi',
          languages: ['Finnish', 'Swedish', 'English'],
        ),
        PrisonerSupportNGO(
          name: 'Criminal Sanctions Agency (RISE) Social Services',
          country: 'Finland',
          description: 'Official reintegration and social services for prisoners.',
          website: 'https://www.rikosseuraamuslaitos.fi',
          languages: ['Finnish', 'Swedish', 'English'],
        ),
        PrisonerSupportNGO(
          name: 'Finnish Red Cross — Detention Monitoring',
          country: 'Finland',
          description:
              'Monitors conditions in immigration detention. Legal information '
              'for detained foreigners.',
          website: 'https://www.redcross.fi',
          languages: ['Finnish', 'Swedish', 'English', 'Arabic', 'Somali'],
        ),
        PrisonerSupportNGO(
          name: 'Pakolaisneuvonta (Finnish Refugee Advice Centre)',
          country: 'Finland',
          description:
              'Free legal aid for asylum seekers and refugees, including those '
              'facing deportation after criminal conviction.',
          website: 'https://www.pakolaisneuvonta.fi',
          languages: ['Finnish', 'English', 'Arabic', 'Somali', 'Russian'],
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 10. FRANCE (FR)
    // -----------------------------------------------------------------------
    CountryPrisonerRights(
      countryCode: 'FR',
      countryName: 'France',
      prisonAuthority: 'Direction de l\'Administration Pénitentiaire (DAP)',
      prisonAuthorityWebsite: 'https://www.justice.gouv.fr',
      approximatePrisonPopulation: 73500,
      foreignPrisonerPercentage: 24.0,
      rights: [
        PrisonerRight(
          category: PrisonerRightCategory.consularAccess,
          title: 'Consular Access',
          description:
              'Right to consular notification upon arrest (garde à vue). France '
              'has one of the largest prison populations in Western Europe with '
              'significant foreign prisoner numbers. Established consular procedures.',
          legalBasis: ['Vienna Convention Art. 36', 'Code de Procédure Pénale Art. 63-1'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.interpreterRight,
          title: 'Right to Interpreter',
          description:
              'Free interpreter from garde à vue through trial. Sworn interpreters '
              'required. Translation of essential documents. Arabic, English, and '
              'major European languages well served.',
          legalBasis: ['Code de Procédure Pénale Art. 63-1, 803-5', 'EU Directive 2010/64/EU'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.transferToHomeCountry,
          title: 'Transfer to Home Country',
          description:
              'FD 2008/909/JHA implemented. France actively transfers prisoners, '
              'particularly to North African states under bilateral agreements. '
              'CoE Convention ETS 112 for non-EU states. Bilateral treaties with '
              'Morocco, Tunisia, Algeria, Turkey, and others.',
          legalBasis: [
            'Loi n° 2013-711 du 5 août 2013',
            'EU Framework Decision 2008/909/JHA',
            'Numerous bilateral conventions',
          ],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.legalAidCriminal,
          title: 'Legal Aid',
          description:
              'Aide juridictionnelle available for persons below income threshold. '
              'Automatic for garde à vue. Mandatory defence for serious offences. '
              'Bureau d\'aide juridictionnelle at each court.',
          legalBasis: [
            'Loi du 10 juillet 1991 (Legal Aid Act)',
            'Code de Procédure Pénale Art. 63-3-1',
            'EU Directive 2016/1919/EU',
          ],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.prisonConditions,
          title: 'Prison Conditions',
          description:
              'Severe overcrowding (140%+ occupancy rate nationally, higher in maisons '
              'd\'arrêt). ECtHR has repeatedly found violations (J.M.B. v. France 2020 — '
              'pilot judgment on overcrowding). Newer centres de détention have better '
              'conditions. Contrôleur général des lieux de privation de liberté (CGLPL) '
              'monitors conditions.',
          legalBasis: [
            'Code de Procédure Pénale Art. 714-728',
            'Loi Pénitentiaire 2009',
            'ECtHR J.M.B. v. France (2020)',
          ],
          practicalNotes:
              'Conditions in maisons d\'arrêt (pre-trial/short sentences) are worst. '
              'Centres de détention and centres pénitentiaires are better. '
              'File complaints to Juge d\'application des peines or CGLPL.',
        ),
        PrisonerRight(
          category: PrisonerRightCategory.communicationRights,
          title: 'Communication Rights',
          description:
              'At least 3 visits per month (parloir). Phone access via pre-paid system. '
              'Letters unrestricted for sentenced prisoners. Unités de vie familiale '
              '(family apartments) for longer visits in some prisons.',
          legalBasis: ['Code de Procédure Pénale Art. 35, 39, 145-4', 'Loi Pénitentiaire 2009'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.healthcareInPrison,
          title: 'Healthcare',
          description:
              'Healthcare provided by public hospital service (UCSA/USMP units in each '
              'prison). Equivalent to community care in principle. SMPR psychiatric units. '
              'Drug substitution (methadone, Subutex) widely available.',
          legalBasis: ['Code de la Santé Publique Art. L6141-5', 'Loi du 18 janvier 1994'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.religiousRights,
          title: 'Religious Rights',
          description:
              'Catholic, Protestant, Muslim, Jewish, Orthodox, and Buddhist chaplains. '
              'France has one of the largest Muslim prison populations in Europe. '
              'Halal meals available. Prayer rooms (laïcité principle applies).',
          legalBasis: ['Loi Pénitentiaire 2009 Art. 26', 'Loi du 9 décembre 1905 (laïcité)'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.immigrationConsequences,
          title: 'Immigration Consequences',
          description:
              'Court can impose interdiction du territoire français (ITF) as criminal '
              'sentence (5-10 years or permanent). Préfecture can also issue obligation '
              'de quitter le territoire (OQTF). EU citizens: higher protection.',
          legalBasis: [
            'Code Pénal Art. 131-30 (ITF)',
            'CESEDA Art. L611-1 (OQTF)',
            'EU Directive 2004/38/EC',
          ],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.earlyReleaseParole,
          title: 'Early Release / Parole',
          description:
              'Libération conditionnelle after half the sentence (two-thirds for '
              'recidivists). Réductions de peine (sentence reductions) for good conduct. '
              'Foreign prisoners eligible but practical barriers exist (no address, '
              'no employment). Libération sous contrainte (compulsory release under '
              'restrictions) at two-thirds.',
          legalBasis: ['Code de Procédure Pénale Art. 729-733'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.deportationAfterSentence,
          title: 'Deportation After Sentence',
          description:
              'ITF or OQTF enforced by Préfecture upon release. Centres de rétention '
              'administrative (CRA) if removal not immediate (max 90 days). '
              'Non-refoulement applies. High number of CRA placements after prison.',
          legalBasis: ['CESEDA Art. L741-1', 'EU Return Directive 2008/115/EC'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.europeanArrestWarrant,
          title: 'European Arrest Warrant',
          description:
              'Chambre de l\'instruction at Court of Appeal handles EAW. French nationals '
              'can be surrendered (constitutional amendment 2003). Active user of EAW.',
          legalBasis: [
            'Code de Procédure Pénale Art. 695-11 to 695-51',
            'EU Framework Decision 2002/584/JHA',
          ],
        ),
      ],
      ngos: [
        PrisonerSupportNGO(
          name: 'CIMADE',
          country: 'France',
          description:
              'Major organisation helping migrants and refugees in detention. '
              'Legal assistance in centres de rétention.',
          website: 'https://www.lacimade.org',
          languages: ['French', 'English', 'Arabic'],
        ),
        PrisonerSupportNGO(
          name: 'Observatoire International des Prisons (OIP)',
          country: 'France',
          description: 'Prison monitoring and advocacy. Publishes reports on conditions.',
          website: 'https://oip.org',
          languages: ['French', 'English'],
        ),
        PrisonerSupportNGO(
          name: 'Genepi',
          country: 'France',
          description: 'Student-run organisation providing education and support to prisoners.',
          website: 'https://www.genepi.fr',
          languages: ['French'],
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 11. GERMANY (DE)
    // -----------------------------------------------------------------------
    CountryPrisonerRights(
      countryCode: 'DE',
      countryName: 'Germany',
      prisonAuthority: 'Landesjustizverwaltungen (State Justice Administrations — prisons are state competence)',
      prisonAuthorityWebsite: 'https://www.bmj.de',
      approximatePrisonPopulation: 55000,
      foreignPrisonerPercentage: 33.0,
      rights: [
        PrisonerRight(
          category: PrisonerRightCategory.consularAccess,
          title: 'Consular Access',
          description:
              'Consular notification required upon arrest. Germany has established '
              'procedures given high foreign prisoner numbers. All 16 federal states '
              'implement Vienna Convention consistently.',
          legalBasis: ['Vienna Convention Art. 36', 'StPO §114b(2)', 'EU Directive 2013/48/EU Art. 6'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.interpreterRight,
          title: 'Right to Interpreter',
          description:
              'Free interpreter from police questioning through trial. Germany has '
              'extensive interpreter infrastructure. Translation of essential documents '
              'including indictment and judgment.',
          legalBasis: ['GG Art. 103', 'StPO §187', 'EU Directive 2010/64/EU'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.transferToHomeCountry,
          title: 'Transfer to Home Country',
          description:
              'FD 2008/909/JHA implemented via IRG (International Legal Assistance in '
              'Criminal Matters Act). Germany is one of the most active states for '
              'prisoner transfers. Bilateral agreements with many non-EU countries.',
          legalBasis: [
            'IRG (Gesetz über internationale Rechtshilfe in Strafsachen)',
            'EU Framework Decision 2008/909/JHA',
            'CoE Convention ETS 112',
          ],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.legalAidCriminal,
          title: 'Legal Aid',
          description:
              'Pflichtverteidiger (mandatory defence counsel) appointed when: offence '
              'carries 1+ year minimum, pre-trial detention, complex case, or if accused '
              'cannot defend themselves. Prozesskostenhilfe for other cases. Free for '
              'detained persons.',
          legalBasis: ['StPO §§140-142', 'EU Directive 2016/1919/EU'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.prisonConditions,
          title: 'Prison Conditions',
          description:
              'Standards vary by federal state but generally good. Single cells the norm. '
              'Comprehensive activities, education, and work programmes. Each state has '
              'its own prison act (Strafvollzugsgesetz). CPT generally positive.',
          legalBasis: ['16 State Prison Acts (Landesstrafvollzugsgesetze)', 'European Prison Rules'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.communicationRights,
          title: 'Communication Rights',
          description:
              'At least one visit per month (1 hour). Phone calls available. Letters '
              'unrestricted for sentenced prisoners. Long-term visits in some states. '
              'Lawyer visits unrestricted and confidential.',
          legalBasis: ['State Prison Acts', 'StPO §148 (lawyer access)'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.healthcareInPrison,
          title: 'Healthcare',
          description:
              'Healthcare provided by prison medical service. Equivalent to community '
              'standard required. Justizvollzugskrankenhaus (prison hospitals) in larger '
              'states. Drug substitution therapy available. Mental health care provided.',
          legalBasis: ['State Prison Acts (healthcare chapters)'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.religiousRights,
          title: 'Religious Rights',
          description:
              'Catholic, Protestant, and Muslim chaplains in most prisons. '
              'Other faiths accommodated. Religious diet available (halal, kosher). '
              'Prayer rooms provided.',
          legalBasis: ['GG Art. 4', 'State Prison Acts'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.immigrationConsequences,
          title: 'Immigration Consequences',
          description:
              'Criminal conviction triggers mandatory review by Ausländerbehörde '
              '(foreigners authority). Sentence of 1+ year typically leads to loss '
              'of residence permit. Entry ban (Einreiseverbot) up to 10 years. '
              'EU citizens: only for serious public policy/security threats.',
          legalBasis: [
            'AufenthG §§53-56 (Aufenthaltsgesetz)',
            'FreizügG/EU §6 (EU citizens)',
          ],
          practicalNotes:
              'Challenge Ausweisung (expulsion) at Verwaltungsgericht (Administrative Court). '
              'Art. 8 ECHR and family ties are key defences. Long-term residents '
              'have stronger protection.',
        ),
        PrisonerRight(
          category: PrisonerRightCategory.earlyReleaseParole,
          title: 'Early Release / Parole',
          description:
              'Conditional release (Aussetzung der Reststrafe) after two-thirds '
              '(standard) or half (exceptional, for first sentences under 2 years). '
              'Foreign prisoners eligible. §456a StPO allows early release of foreigners '
              'for deportation (Absehen von Vollstreckung).',
          legalBasis: ['StGB §§57-57a', 'StPO §456a'],
          practicalNotes:
              '§456a StPO is frequently used: prosecution can suspend remaining '
              'sentence to enable deportation, typically after half the sentence. '
              'This can be advantageous (earlier release) or disadvantageous '
              '(no parole supervision, immediate deportation).',
        ),
        PrisonerRight(
          category: PrisonerRightCategory.deportationAfterSentence,
          title: 'Deportation After Sentence',
          description:
              'Ausländerbehörde issues Abschiebungsanordnung. §456a StPO allows '
              'suspension of sentence for deportation. Detention pending removal '
              '(Abschiebungshaft) if needed. Non-refoulement via §60 AufenthG. '
              'Duldung (toleration) if deportation not possible.',
          legalBasis: [
            'AufenthG §§58-62',
            'StPO §456a',
            'EU Return Directive 2008/115/EC',
          ],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.europeanArrestWarrant,
          title: 'European Arrest Warrant',
          description:
              'Oberlandesgericht (Higher Regional Court) handles EAW. German nationals '
              'can be surrendered (GG Art. 16(2) amended 2000). Germany is a major user '
              'of the EAW system.',
          legalBasis: [
            'IRG §§78-83',
            'GG Art. 16(2)',
            'EU Framework Decision 2002/584/JHA',
          ],
        ),
      ],
      ngos: [
        PrisonerSupportNGO(
          name: 'Flüchtlingsrat (Refugee Council — per state)',
          country: 'Germany',
          description: 'Legal counselling for refugees and migrants facing deportation.',
          website: 'https://www.fluechtlingsrat.de',
          languages: ['German', 'English', 'Arabic', 'Farsi'],
        ),
        PrisonerSupportNGO(
          name: 'Freie Hilfe Berlin e.V.',
          country: 'Germany',
          description: 'Prisoner reintegration support in Berlin.',
          website: 'https://www.freiehilfe.de',
          languages: ['German', 'English', 'Turkish', 'Arabic'],
        ),
        PrisonerSupportNGO(
          name: 'PRO ASYL',
          country: 'Germany',
          description: 'Advocacy for refugees and asylum seekers, including those in detention.',
          website: 'https://www.proasyl.de',
          languages: ['German', 'English'],
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 12. GREECE (GR)
    // -----------------------------------------------------------------------
    CountryPrisonerRights(
      countryCode: 'GR',
      countryName: 'Greece',
      prisonAuthority: 'General Directorate for Crime & Detention Policy — Ministry of Citizen Protection',
      prisonAuthorityWebsite: 'https://www.ministryofjustice.gr',
      approximatePrisonPopulation: 10500,
      foreignPrisonerPercentage: 52.0,
      rights: [
        PrisonerRight(
          category: PrisonerRightCategory.consularAccess,
          title: 'Consular Access',
          description:
              'Right to consular contact upon arrest. Greece has one of the highest '
              'foreign prisoner percentages in the EU. Large numbers of Albanian, '
              'Pakistani, and Nigerian nationals.',
          legalBasis: ['Vienna Convention Art. 36', 'Code of Criminal Procedure Art. 96'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.interpreterRight,
          title: 'Right to Interpreter',
          description:
              'Free interpreter at all stages. Greece transposed Directive 2010/64/EU '
              'in 2014. Availability varies by language and location. Albanian interpreters '
              'readily available; rare languages more difficult.',
          legalBasis: ['Code of Criminal Procedure Art. 233', 'EU Directive 2010/64/EU'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.transferToHomeCountry,
          title: 'Transfer to Home Country',
          description:
              'FD 2008/909/JHA implemented. Bilateral agreement with Albania '
              '(largest foreign prisoner group). CoE Convention ETS 112.',
          legalBasis: ['EU Framework Decision 2008/909/JHA', 'Law 4307/2014', 'CoE Convention ETS 112'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.legalAidCriminal,
          title: 'Legal Aid',
          description:
              'Free legal aid for accused who cannot afford a lawyer. Mandatory for '
              'felonies. Bar association assigns counsel. Quality concerns raised '
              'by European Commission.',
          legalBasis: ['Code of Criminal Procedure Art. 340', 'Law 3226/2004', 'EU Directive 2016/1919/EU'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.prisonConditions,
          title: 'Prison Conditions',
          description:
              'Severe overcrowding and poor conditions. ECtHR has repeatedly found '
              'violations (Art. 3 ECHR). CPT has been highly critical. Korydallos '
              'Prison in Athens particularly problematic. Conditions have slowly '
              'improved but remain below European standards.',
          legalBasis: [
            'Correctional Code (Law 2776/1999)',
            'CPT reports on Greece',
            'ECtHR judgments (multiple)',
          ],
          practicalNotes:
              'Greek prisons are among the most overcrowded in Europe. '
              'File complaints to the supervising judge (δικαστικός λειτουργός). '
              'Ombudsman also monitors conditions.',
        ),
        PrisonerRight(
          category: PrisonerRightCategory.communicationRights,
          title: 'Communication Rights',
          description:
              'Visits permitted. Phone access via card-operated phones. Letters '
              'unrestricted. Lawyer visits confidential.',
          legalBasis: ['Correctional Code Art. 51-57'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.healthcareInPrison,
          title: 'Healthcare',
          description:
              'Medical units in prisons. Hospital at Korydallos. Specialist referrals '
              'through public hospitals. Psychiatric care available but insufficient. '
              'CPT has criticised healthcare conditions.',
          legalBasis: ['Correctional Code Art. 27-35'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.religiousRights,
          title: 'Religious Rights',
          description:
              'Greek Orthodox chaplains. Muslim, Catholic services can be arranged. '
              'Religious items permitted. Halal meals available in prisons with '
              'significant Muslim populations.',
          legalBasis: ['Greek Constitution Art. 13', 'Correctional Code Art. 37'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.immigrationConsequences,
          title: 'Immigration Consequences',
          description:
              'Criminal conviction typically leads to deportation order. Administrative '
              'expulsion by police. EU citizens: higher threshold. Greece is a major '
              'entry point for irregular migration, affecting prison demographics.',
          legalBasis: ['Immigration Code (Law 4251/2014)', 'EU Directive 2004/38/EC'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.earlyReleaseParole,
          title: 'Early Release / Parole',
          description:
              'Conditional release after serving portion of sentence (varies by offence '
              'severity: two-fifths to four-fifths). Foreign prisoners eligible.',
          legalBasis: ['Criminal Code Art. 105-110'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.deportationAfterSentence,
          title: 'Deportation After Sentence',
          description:
              'Police issue administrative expulsion. Pre-removal detention centres '
              '(often criticised for conditions). Non-refoulement applies. '
              'Deportation to Albania streamlined via bilateral agreements.',
          legalBasis: ['Immigration Code', 'EU Return Directive 2008/115/EC'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.europeanArrestWarrant,
          title: 'European Arrest Warrant',
          description:
              'Council of Appeals Court (Symvoulio Efeton) handles EAW. '
              'Implemented by Law 3251/2004.',
          legalBasis: ['Law 3251/2004', 'EU Framework Decision 2002/584/JHA'],
        ),
      ],
      ngos: [
        PrisonerSupportNGO(
          name: 'Greek Council for Refugees (GCR)',
          country: 'Greece',
          description: 'Legal aid for refugees and asylum seekers, including in detention.',
          website: 'https://www.gcr.gr',
          languages: ['Greek', 'English', 'Arabic', 'French'],
        ),
        PrisonerSupportNGO(
          name: 'ARSIS — Association for the Social Support of Youth',
          country: 'Greece',
          description: 'Support for detained youth and migrants.',
          website: 'https://www.arsis.gr',
          languages: ['Greek', 'English'],
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 13. HUNGARY (HU)
    // -----------------------------------------------------------------------
    CountryPrisonerRights(
      countryCode: 'HU',
      countryName: 'Hungary',
      prisonAuthority: 'Büntetés-végrehajtás Országos Parancsnoksága (National Prison Administration)',
      prisonAuthorityWebsite: 'https://bv.gov.hu',
      approximatePrisonPopulation: 16000,
      foreignPrisonerPercentage: 5.0,
      rights: [
        PrisonerRight(
          category: PrisonerRightCategory.consularAccess,
          title: 'Consular Access',
          description: 'Foreign detainees informed of consular access rights upon admission.',
          legalBasis: ['Vienna Convention Art. 36', 'Criminal Procedure Act §42'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.interpreterRight,
          title: 'Right to Interpreter',
          description:
              'Free interpreter throughout criminal proceedings. Hungarian is among '
              'the rarest EU languages — interpretation essential for nearly all '
              'foreign detainees.',
          legalBasis: ['Criminal Procedure Act §8', 'EU Directive 2010/64/EU'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.transferToHomeCountry,
          title: 'Transfer to Home Country',
          description:
              'FD 2008/909/JHA implemented via Act CLXXX of 2012. Ministry of Justice '
              'processes applications.',
          legalBasis: ['EU Framework Decision 2008/909/JHA', 'Act CLXXX of 2012', 'CoE Convention ETS 112'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.legalAidCriminal,
          title: 'Legal Aid',
          description:
              'Free legal counsel for detained persons and for serious offences. '
              'Legal Aid Service assigns lawyers.',
          legalBasis: ['Criminal Procedure Act §44-48', 'Legal Aid Act (2003)', 'EU Directive 2016/1919/EU'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.prisonConditions,
          title: 'Prison Conditions',
          description:
              'Overcrowding has been a major issue. ECtHR pilot judgment Varga v. Hungary '
              '(2015) found systematic violation of Art. 3. Compensation scheme introduced. '
              'Prison building programme underway. CPT has noted violence and corruption issues.',
          legalBasis: [
            'Act CCXL of 2013 (Prison Code)',
            'ECtHR Varga v. Hungary (2015)',
          ],
          practicalNotes:
              'Apply for compensation under the Varga mechanism if subjected to '
              'overcrowded conditions (below 3m² personal space).',
        ),
        PrisonerRight(
          category: PrisonerRightCategory.communicationRights,
          title: 'Communication Rights',
          description:
              'Monthly visits. Phone access. Letters permitted with possible monitoring. '
              'Lawyer visits confidential.',
          legalBasis: ['Act CCXL of 2013'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.healthcareInPrison,
          title: 'Healthcare',
          description:
              'Prison medical units. Central prison hospital (BVKK) in Tököl. '
              'Specialist referrals available.',
          legalBasis: ['Act CCXL of 2013'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.religiousRights,
          title: 'Religious Rights',
          description:
              'Catholic, Protestant, Jewish, and other chaplains. Religious items '
              'permitted. Religious services regular.',
          legalBasis: ['Fundamental Law of Hungary Art. VII', 'Act CCXL of 2013'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.immigrationConsequences,
          title: 'Immigration Consequences',
          description:
              'Criminal conviction can lead to expulsion (judicial, part of criminal sentence) '
              'or administrative removal. Entry ban imposed.',
          legalBasis: ['Criminal Code §59-61 (judicial expulsion)', 'Act II of 2007 (Foreigners Act)'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.earlyReleaseParole,
          title: 'Early Release / Parole',
          description:
              'Conditional release after two-thirds (standard) or four-fifths (serious offences). '
              'Foreign prisoners eligible.',
          legalBasis: ['Criminal Code §§38-40'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.deportationAfterSentence,
          title: 'Deportation After Sentence',
          description:
              'Immigration authorities enforce removal. Detention at immigration '
              'facilities. Non-refoulement principle applies.',
          legalBasis: ['Act II of 2007', 'EU Return Directive 2008/115/EC'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.europeanArrestWarrant,
          title: 'European Arrest Warrant',
          description:
              'Budapest Regional Court of Appeal handles EAW. Implemented via '
              'Act CXXX of 2003.',
          legalBasis: ['Act CXXX of 2003', 'EU Framework Decision 2002/584/JHA'],
        ),
      ],
      ngos: [
        PrisonerSupportNGO(
          name: 'Hungarian Helsinki Committee',
          country: 'Hungary',
          description:
              'Leading human rights organisation monitoring prison conditions '
              'and providing legal aid to detained foreigners.',
          website: 'https://helsinki.hu',
          languages: ['Hungarian', 'English'],
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 14. IRELAND (IE)
    // -----------------------------------------------------------------------
    CountryPrisonerRights(
      countryCode: 'IE',
      countryName: 'Ireland',
      prisonAuthority: 'Irish Prison Service (An tSeirbhís Phríosún)',
      prisonAuthorityWebsite: 'https://www.irishprisons.ie',
      approximatePrisonPopulation: 4000,
      foreignPrisonerPercentage: 12.0,
      rights: [
        PrisonerRight(
          category: PrisonerRightCategory.consularAccess,
          title: 'Consular Access',
          description: 'Right to consular access upon arrest. Prison Service facilitates visits.',
          legalBasis: ['Vienna Convention Art. 36', 'Criminal Justice Act 1984 §5'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.interpreterRight,
          title: 'Right to Interpreter',
          description:
              'Free interpreter at Garda (police) station and court. '
              'Irish and English are official languages. Translation of essential documents.',
          legalBasis: ['EU Directive 2010/64/EU', 'Criminal Justice Act 1984'],
          practicalNotes: 'Ireland opted into the EU procedural rights directives.',
        ),
        PrisonerRight(
          category: PrisonerRightCategory.transferToHomeCountry,
          title: 'Transfer to Home Country',
          description:
              'Transfer of Sentenced Persons Acts 1995-1997 implement CoE Convention. '
              'FD 2008/909/JHA transposed via Criminal Justice (Mutual Recognition of '
              'Custodial Sentences) Act 2023.',
          legalBasis: [
            'Transfer of Sentenced Persons Acts 1995-1997',
            'Criminal Justice (Mutual Recognition) Act 2023',
            'CoE Convention ETS 112',
          ],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.legalAidCriminal,
          title: 'Legal Aid',
          description:
              'Criminal Legal Aid Scheme: free solicitor and barrister for accused '
              'who cannot afford representation. Means-tested. Administered by courts.',
          legalBasis: ['Criminal Justice (Legal Aid) Act 1962', 'EU Directive 2016/1919/EU'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.prisonConditions,
          title: 'Prison Conditions',
          description:
              'Conditions have improved significantly. Overcrowding in some prisons '
              '(Mountjoy, Cloverhill). In-cell sanitation rolled out. Inspector of '
              'Prisons provides independent oversight.',
          legalBasis: ['Prison Rules 2007-2020', 'Prisons Act 2007'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.communicationRights,
          title: 'Communication Rights',
          description:
              'Weekly visits minimum. Phone calls available. Letters unrestricted. '
              'In-cell phones being introduced. Video calls available.',
          legalBasis: ['Prison Rules 2007 Rules 35-48'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.healthcareInPrison,
          title: 'Healthcare',
          description:
              'Medical officers in all prisons. National Forensic Mental Health Service. '
              'Hospital referrals available. Drug treatment programmes.',
          legalBasis: ['Prison Rules 2007 Rules 98-109'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.religiousRights,
          title: 'Religious Rights',
          description:
              'Catholic chaplains in all prisons. Church of Ireland, Muslim, and other '
              'religious ministers. Religious items and services.',
          legalBasis: ['Prison Rules 2007 Rule 34', 'Irish Constitution Art. 44'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.immigrationConsequences,
          title: 'Immigration Consequences',
          description:
              'Deportation order by Minister for Justice under Immigration Act 1999. '
              'EU citizens: public policy/security grounds. Proportionality assessment.',
          legalBasis: ['Immigration Act 1999 §3', 'European Communities (Free Movement) Regulations 2015'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.earlyReleaseParole,
          title: 'Early Release / Parole',
          description:
              'Parole Board (established 2024 on statutory footing) considers release after '
              'minimum tariff served. Temporary release by Minister. Foreign prisoners eligible.',
          legalBasis: ['Parole Act 2019 (commenced 2024)', 'Criminal Justice Act 1960 §2'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.deportationAfterSentence,
          title: 'Deportation After Sentence',
          description:
              'Deportation orders enforced by Garda National Immigration Bureau (GNIB). '
              'Detention if removal delayed. Non-refoulement under International '
              'Protection Act 2015.',
          legalBasis: ['Immigration Act 1999 §3', 'International Protection Act 2015'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.europeanArrestWarrant,
          title: 'European Arrest Warrant',
          description:
              'High Court handles EAW. Irish Supreme Court has referred several '
              'EAW cases to CJEU. Extensive case law on proportionality.',
          legalBasis: ['European Arrest Warrant Act 2003 (as amended)', 'EU FD 2002/584/JHA'],
        ),
      ],
      ngos: [
        PrisonerSupportNGO(
          name: 'Irish Penal Reform Trust (IPRT)',
          country: 'Ireland',
          description: 'Prison reform advocacy and monitoring.',
          website: 'https://www.iprt.ie',
          languages: ['English'],
        ),
        PrisonerSupportNGO(
          name: 'Irish Refugee Council',
          country: 'Ireland',
          description: 'Legal aid for refugees including those in detention.',
          website: 'https://www.irishrefugeecouncil.ie',
          languages: ['English', 'Arabic', 'French'],
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 15. ITALY (IT)
    // -----------------------------------------------------------------------
    CountryPrisonerRights(
      countryCode: 'IT',
      countryName: 'Italy',
      prisonAuthority: 'Dipartimento dell\'Amministrazione Penitenziaria (DAP)',
      prisonAuthorityWebsite: 'https://www.giustizia.it',
      approximatePrisonPopulation: 56500,
      foreignPrisonerPercentage: 31.0,
      rights: [
        PrisonerRight(
          category: PrisonerRightCategory.consularAccess,
          title: 'Consular Access',
          description: 'Consular notification upon arrest. Italy has large foreign prisoner population.',
          legalBasis: ['Vienna Convention Art. 36', 'Code of Criminal Procedure Art. 386(3)'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.interpreterRight,
          title: 'Right to Interpreter',
          description:
              'Free interpreter at all proceedings. Translation of essential documents. '
              'Albania, Romania, Morocco, Tunisia are most common nationalities.',
          legalBasis: ['Code of Criminal Procedure Art. 143', 'EU Directive 2010/64/EU'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.transferToHomeCountry,
          title: 'Transfer to Home Country',
          description:
              'FD 2008/909/JHA implemented via Legislative Decree 161/2010. '
              'Active bilateral agreements especially with Albania, Romania.',
          legalBasis: ['D.Lgs. 161/2010', 'EU FD 2008/909/JHA', 'CoE Convention ETS 112'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.legalAidCriminal,
          title: 'Legal Aid',
          description:
              'Patrocinio a spese dello Stato (state-funded legal aid). Income threshold: '
              'below approximately €12,838/year. Automatic for detained persons on request.',
          legalBasis: ['DPR 115/2002 (Testo Unico spese di giustizia)', 'EU Directive 2016/1919/EU'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.prisonConditions,
          title: 'Prison Conditions',
          description:
              'Chronic overcrowding. ECtHR pilot judgment Torreggiani v. Italy (2013) '
              'found systematic violation. Italy introduced compensation mechanism '
              'and early release measures. Conditions improving but still problematic.',
          legalBasis: [
            'Ordinamento Penitenziario (Law 354/1975)',
            'ECtHR Torreggiani v. Italy (2013)',
          ],
          practicalNotes:
              'Apply for compensation under Art. 35-ter OP if subjected to less than '
              '3m² personal space. Garante dei diritti dei detenuti monitors conditions.',
        ),
        PrisonerRight(
          category: PrisonerRightCategory.communicationRights,
          title: 'Communication Rights',
          description:
              '6 visits per month (standard regime). Phone calls (10 min/week, increased). '
              'Letters unrestricted. Video calls maintained post-COVID.',
          legalBasis: ['Ordinamento Penitenziario Art. 18, 39'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.healthcareInPrison,
          title: 'Healthcare',
          description:
              'Healthcare transferred to National Health Service (SSN) in 2008. '
              'Each prison has medical unit. Hospital referrals through ASL.',
          legalBasis: ['D.Lgs. 230/1999', 'DPCM 1 April 2008'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.religiousRights,
          title: 'Religious Rights',
          description:
              'Catholic chaplains by Concordat. Muslim Imams increasingly present. '
              'Other faiths accommodated. Halal and other dietary requirements met.',
          legalBasis: ['Ordinamento Penitenziario Art. 26', 'Italian Constitution Art. 19'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.immigrationConsequences,
          title: 'Immigration Consequences',
          description:
              'Espulsione giudiziaria (judicial expulsion) can be imposed as criminal '
              'sentence or security measure. Espulsione amministrativa by Prefetto. '
              'EU citizens: serious public policy/security grounds only.',
          legalBasis: ['D.Lgs. 286/1998 (Testo Unico Immigrazione) Art. 13, 15, 16', 'Criminal Code Art. 235'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.earlyReleaseParole,
          title: 'Early Release / Parole',
          description:
              'Liberazione condizionale after half the sentence (30 months minimum served). '
              'Sconto di pena (sentence reduction) 45 days per 6 months for good conduct. '
              'Art. 16 TUI: early expulsion as alternative to remaining sentence '
              '(for sentences under 2 years remaining).',
          legalBasis: ['Criminal Code Art. 176', 'Ordinamento Penitenziario Art. 54', 'D.Lgs. 286/1998 Art. 16'],
          practicalNotes:
              'Art. 16 TUI expulsion (espulsione alternativa) is widely used for '
              'foreign prisoners with 2 years or less remaining. Results in 10-year '
              'entry ban but earlier release. Tribunale di Sorveglianza decides.',
        ),
        PrisonerRight(
          category: PrisonerRightCategory.deportationAfterSentence,
          title: 'Deportation After Sentence',
          description:
              'Questura enforces expulsion. CPR (Centri di Permanenza per i Rimpatri) '
              'detention if removal not immediate. Maximum 18 months. Non-refoulement.',
          legalBasis: ['D.Lgs. 286/1998 Art. 14', 'EU Return Directive 2008/115/EC'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.europeanArrestWarrant,
          title: 'European Arrest Warrant',
          description:
              'Court of Appeal handles EAW. Implemented by Law 69/2005. Italy has raised '
              'concerns about EAW proportionality in CJEU cases.',
          legalBasis: ['Law 69/2005', 'EU Framework Decision 2002/584/JHA'],
        ),
      ],
      ngos: [
        PrisonerSupportNGO(
          name: 'Antigone (Associazione Antigone)',
          country: 'Italy',
          description: 'Prison monitoring and conditions reporting. Publishes annual report.',
          website: 'https://www.antigone.it',
          languages: ['Italian', 'English'],
        ),
        PrisonerSupportNGO(
          name: 'ASGI (Associazione Studi Giuridici sull\'Immigrazione)',
          country: 'Italy',
          description: 'Legal studies on immigration. Helps detained foreigners.',
          website: 'https://www.asgi.it',
          languages: ['Italian', 'English'],
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 16. LATVIA (LV)
    // -----------------------------------------------------------------------
    CountryPrisonerRights(
      countryCode: 'LV',
      countryName: 'Latvia',
      prisonAuthority: 'Ieslodzījuma vietu pārvalde (Prison Administration)',
      prisonAuthorityWebsite: 'https://www.ievp.gov.lv',
      approximatePrisonPopulation: 3300,
      foreignPrisonerPercentage: 5.0,
      rights: [
        PrisonerRight(
          category: PrisonerRightCategory.consularAccess,
          title: 'Consular Access',
          description: 'Consular access right upon arrest. Mostly Russian and Lithuanian nationals.',
          legalBasis: ['Vienna Convention Art. 36', 'Criminal Procedure Law §60'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.interpreterRight,
          title: 'Right to Interpreter',
          description: 'Free interpreter. Latvian and Russian both in practice use in proceedings.',
          legalBasis: ['Criminal Procedure Law §11', 'EU Directive 2010/64/EU'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.transferToHomeCountry,
          title: 'Transfer to Home Country',
          description: 'FD 2008/909/JHA and CoE ETS 112. Ministry of Justice handles transfers.',
          legalBasis: ['EU FD 2008/909/JHA', 'Criminal Procedure Law §§794-813'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.legalAidCriminal,
          title: 'Legal Aid',
          description: 'State-funded legal aid through Legal Aid Administration. Mandatory for serious offences.',
          legalBasis: ['State Legal Aid Law', 'Criminal Procedure Law §§80-84', 'EU Directive 2016/1919/EU'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.prisonConditions,
          title: 'Prison Conditions',
          description:
              'Conditions have improved. Old Soviet-era prisons gradually replaced. '
              'Olaine Prison (2020) modern facility. Daugavgrīva and Jelgava older. '
              'CPT noted improvements but some concerns remain.',
          legalBasis: ['Sentence Execution Code', 'European Prison Rules'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.communicationRights,
          title: 'Communication Rights',
          description: 'Regular visits. Phone access. Letters. Lawyer visits unrestricted.',
          legalBasis: ['Sentence Execution Code'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.healthcareInPrison,
          title: 'Healthcare',
          description: 'Medical units in prisons. Hospital referrals. Mental health services.',
          legalBasis: ['Sentence Execution Code'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.religiousRights,
          title: 'Religious Rights',
          description: 'Lutheran, Catholic, Orthodox chaplains. Religious items and services.',
          legalBasis: ['Latvian Constitution Art. 99', 'Sentence Execution Code'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.immigrationConsequences,
          title: 'Immigration Consequences',
          description:
              'Conviction may lead to removal decision and entry ban. '
              'Non-citizens (former Soviet citizens with Latvian non-citizen passports) '
              'have particular status. EU citizens: higher threshold.',
          legalBasis: ['Immigration Law', 'EU Directive 2004/38/EC'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.earlyReleaseParole,
          title: 'Early Release / Parole',
          description: 'Conditional release after half or two-thirds of sentence depending on category.',
          legalBasis: ['Criminal Law §61'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.deportationAfterSentence,
          title: 'Deportation After Sentence',
          description: 'State Border Guard enforces removal. Detention facility at Daugavpils. Non-refoulement applies.',
          legalBasis: ['Immigration Law', 'EU Return Directive 2008/115/EC'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.europeanArrestWarrant,
          title: 'European Arrest Warrant',
          description: 'District Court handles EAW. Standard EU procedures.',
          legalBasis: ['Criminal Procedure Law Ch. 65', 'EU FD 2002/584/JHA'],
        ),
      ],
      ngos: [
        PrisonerSupportNGO(
          name: 'Latvian Centre for Human Rights',
          country: 'Latvia',
          description: 'Human rights monitoring including detention conditions.',
          website: 'https://cilvektiesibas.org.lv',
          languages: ['Latvian', 'English', 'Russian'],
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 17. LITHUANIA (LT)
    // -----------------------------------------------------------------------
    CountryPrisonerRights(
      countryCode: 'LT',
      countryName: 'Lithuania',
      prisonAuthority: 'Kalėjimų departamentas (Prison Department)',
      prisonAuthorityWebsite: 'https://www.kalejimudepartamentas.lt',
      approximatePrisonPopulation: 5400,
      foreignPrisonerPercentage: 3.0,
      rights: [
        PrisonerRight(
          category: PrisonerRightCategory.consularAccess,
          title: 'Consular Access',
          description: 'Right to consular notification and access upon arrest.',
          legalBasis: ['Vienna Convention Art. 36', 'Code of Criminal Procedure Art. 44'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.interpreterRight,
          title: 'Right to Interpreter',
          description: 'Free interpreter. Russian interpreters widely available.',
          legalBasis: ['Code of Criminal Procedure Art. 8', 'EU Directive 2010/64/EU'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.transferToHomeCountry,
          title: 'Transfer to Home Country',
          description: 'FD 2008/909/JHA implemented. CoE ETS 112 for non-EU states.',
          legalBasis: ['EU FD 2008/909/JHA', 'Law on International Cooperation in Criminal Proceedings'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.legalAidCriminal,
          title: 'Legal Aid',
          description: 'State-guaranteed legal aid. Mandatory defence for serious offences and detained persons.',
          legalBasis: ['State-Guaranteed Legal Aid Law', 'Code of Criminal Procedure', 'EU Directive 2016/1919/EU'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.prisonConditions,
          title: 'Prison Conditions',
          description:
              'Conditions have improved but concerns remain. Lukiškės Prison in Vilnius '
              'closed (2019) and inmates transferred to newer facilities. CPT noted improvements.',
          legalBasis: ['Penal Code', 'Law on Execution of Sentences', 'European Prison Rules'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.communicationRights,
          title: 'Communication Rights',
          description: 'Regular visits, phone access, letters. Lawyer visits unrestricted.',
          legalBasis: ['Law on Execution of Sentences'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.healthcareInPrison,
          title: 'Healthcare',
          description: 'Medical units in prisons. Hospital at Pravieniškės. Mental health services.',
          legalBasis: ['Law on Execution of Sentences'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.religiousRights,
          title: 'Religious Rights',
          description: 'Catholic chaplains. Other denominations can be accommodated.',
          legalBasis: ['Lithuanian Constitution Art. 26'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.immigrationConsequences,
          title: 'Immigration Consequences',
          description: 'Conviction may lead to expulsion decision and entry ban.',
          legalBasis: ['Law on Legal Status of Aliens Art. 126-131'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.earlyReleaseParole,
          title: 'Early Release / Parole',
          description: 'Conditional release after half or two-thirds of sentence.',
          legalBasis: ['Criminal Code Art. 77'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.deportationAfterSentence,
          title: 'Deportation After Sentence',
          description: 'Migration Department enforces removal. Foreigners Registration Centre for detention.',
          legalBasis: ['Law on Legal Status of Aliens', 'EU Return Directive 2008/115/EC'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.europeanArrestWarrant,
          title: 'European Arrest Warrant',
          description: 'Vilnius Regional Court handles EAW execution.',
          legalBasis: ['Law on EAW', 'EU FD 2002/584/JHA'],
        ),
      ],
      ngos: [
        PrisonerSupportNGO(
          name: 'Lithuanian Red Cross',
          country: 'Lithuania',
          description: 'Visits detention facilities, assists detained foreigners.',
          website: 'https://www.redcross.lt',
          languages: ['Lithuanian', 'English', 'Russian'],
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 18. LUXEMBOURG (LU)
    // -----------------------------------------------------------------------
    CountryPrisonerRights(
      countryCode: 'LU',
      countryName: 'Luxembourg',
      prisonAuthority: 'Administration Pénitentiaire — Centre Pénitentiaire de Luxembourg',
      prisonAuthorityWebsite: 'https://justice.public.lu',
      approximatePrisonPopulation: 700,
      foreignPrisonerPercentage: 74.0,
      rights: [
        PrisonerRight(
          category: PrisonerRightCategory.consularAccess,
          title: 'Consular Access',
          description:
              'Right to consular notification. Luxembourg has the highest foreign '
              'prisoner percentage in the EU (74%). Well-established consular procedures.',
          legalBasis: ['Vienna Convention Art. 36', 'Code de Procédure Pénale'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.interpreterRight,
          title: 'Right to Interpreter',
          description:
              'Free interpreter. Three official languages (French, German, Luxembourgish). '
              'Portuguese interpreters in high demand given large Portuguese community.',
          legalBasis: ['EU Directive 2010/64/EU', 'Code de Procédure Pénale'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.transferToHomeCountry,
          title: 'Transfer to Home Country',
          description: 'FD 2008/909/JHA implemented. Active transfers given high foreign prisoner numbers.',
          legalBasis: ['EU FD 2008/909/JHA', 'Law of 1 August 2018', 'CoE Convention ETS 112'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.legalAidCriminal,
          title: 'Legal Aid',
          description: 'Assistance judiciaire for those without means. Generous income thresholds.',
          legalBasis: ['Loi sur l\'assistance judiciaire', 'EU Directive 2016/1919/EU'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.prisonConditions,
          title: 'Prison Conditions',
          description:
              'Two prisons: Centre Pénitentiaire de Luxembourg (Schrassig) and Centre '
              'Pénitentiaire de Givenich. New facility Uerschterhaff opened 2022. '
              'Generally good conditions. CPT has noted overcrowding at Schrassig.',
          legalBasis: ['Loi du 20 juillet 2018 (Prison Act)', 'European Prison Rules'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.communicationRights,
          title: 'Communication Rights',
          description: 'Regular visits. Phone access. Letters. Video calls. Lawyer visits unrestricted.',
          legalBasis: ['Loi du 20 juillet 2018'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.healthcareInPrison,
          title: 'Healthcare',
          description: 'Medical service. Hospital referrals to Centre Hospitalier. Good standard.',
          legalBasis: ['Loi du 20 juillet 2018'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.religiousRights,
          title: 'Religious Rights',
          description: 'Multi-faith chaplaincy. Diverse prison population accommodated.',
          legalBasis: ['Luxembourg Constitution', 'Loi du 20 juillet 2018'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.immigrationConsequences,
          title: 'Immigration Consequences',
          description: 'Conviction may lead to removal. EU citizens: public policy/security threshold.',
          legalBasis: ['Loi du 29 août 2008 (Immigration Act)', 'EU Directive 2004/38/EC'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.earlyReleaseParole,
          title: 'Early Release / Parole',
          description: 'Conditional release after half the sentence. Active use.',
          legalBasis: ['Code Pénal Art. 100-105'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.deportationAfterSentence,
          title: 'Deportation After Sentence',
          description: 'Direction de l\'Immigration enforces removal. Retention centre at Findel.',
          legalBasis: ['Loi du 29 août 2008', 'EU Return Directive 2008/115/EC'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.europeanArrestWarrant,
          title: 'European Arrest Warrant',
          description: 'Chambre du Conseil handles EAW.',
          legalBasis: ['Loi du 17 mars 2004', 'EU FD 2002/584/JHA'],
        ),
      ],
      ngos: [
        PrisonerSupportNGO(
          name: 'ASTI (Association de Soutien aux Travailleurs Immigrés)',
          country: 'Luxembourg',
          description: 'Support for immigrants including those in detention.',
          website: 'https://www.asti.lu',
          languages: ['French', 'Portuguese', 'English'],
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 19. MALTA (MT)
    // -----------------------------------------------------------------------
    CountryPrisonerRights(
      countryCode: 'MT',
      countryName: 'Malta',
      prisonAuthority: 'Correctional Services Agency — Corradino Correctional Facility',
      prisonAuthorityWebsite: 'https://homeaffairs.gov.mt',
      approximatePrisonPopulation: 700,
      foreignPrisonerPercentage: 42.0,
      rights: [
        PrisonerRight(
          category: PrisonerRightCategory.consularAccess,
          title: 'Consular Access',
          description: 'Right to consular contact. High foreign prisoner percentage.',
          legalBasis: ['Vienna Convention Art. 36', 'Criminal Code'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.interpreterRight,
          title: 'Right to Interpreter',
          description: 'Free interpreter. Maltese and English both official.',
          legalBasis: ['EU Directive 2010/64/EU', 'Criminal Code'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.transferToHomeCountry,
          title: 'Transfer to Home Country',
          description: 'FD 2008/909/JHA implemented. CoE Convention ETS 112.',
          legalBasis: ['EU FD 2008/909/JHA', 'Mutual Legal Assistance Regulations'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.legalAidCriminal,
          title: 'Legal Aid',
          description: 'Legal Aid Agency provides free representation. Means-tested.',
          legalBasis: ['Legal Aid (Malta) Act', 'EU Directive 2016/1919/EU'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.prisonConditions,
          title: 'Prison Conditions',
          description:
              'Corradino Correctional Facility (CCF) is the only prison. Overcrowding '
              'and outdated infrastructure. CPT has raised concerns about conditions.',
          legalBasis: ['Prisons Act Cap. 260', 'European Prison Rules'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.communicationRights,
          title: 'Communication Rights',
          description: 'Visits, phone calls, letters. Lawyer visits unrestricted.',
          legalBasis: ['Prisons Act Cap. 260'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.healthcareInPrison,
          title: 'Healthcare',
          description: 'Medical unit at CCF. Hospital referrals to Mater Dei Hospital.',
          legalBasis: ['Prisons Act Cap. 260'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.religiousRights,
          title: 'Religious Rights',
          description: 'Catholic chaplain. Other faiths accommodated on request.',
          legalBasis: ['Maltese Constitution Art. 40'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.immigrationConsequences,
          title: 'Immigration Consequences',
          description: 'Conviction may lead to removal order and entry ban.',
          legalBasis: ['Immigration Act Cap. 217', 'EU Directive 2004/38/EC'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.earlyReleaseParole,
          title: 'Early Release / Parole',
          description: 'Conditional release by Board of Visitors. Foreign prisoners eligible.',
          legalBasis: ['Prisons Act Cap. 260'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.deportationAfterSentence,
          title: 'Deportation After Sentence',
          description: 'Immigration Police enforce removal. Safi detention centre if delayed.',
          legalBasis: ['Immigration Act Cap. 217', 'EU Return Directive 2008/115/EC'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.europeanArrestWarrant,
          title: 'European Arrest Warrant',
          description: 'Court of Magistrates handles EAW.',
          legalBasis: ['Extradition Act Cap. 276', 'EU FD 2002/584/JHA'],
        ),
      ],
      ngos: [
        PrisonerSupportNGO(
          name: 'aditus foundation',
          country: 'Malta',
          description: 'Human rights organisation. Assists detained migrants.',
          website: 'https://aditus.org.mt',
          languages: ['English', 'Maltese'],
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 20. NETHERLANDS (NL)
    // -----------------------------------------------------------------------
    CountryPrisonerRights(
      countryCode: 'NL',
      countryName: 'Netherlands',
      prisonAuthority: 'Dienst Justitiële Inrichtingen (DJI)',
      prisonAuthorityWebsite: 'https://www.dji.nl',
      approximatePrisonPopulation: 9500,
      foreignPrisonerPercentage: 20.0,
      rights: [
        PrisonerRight(
          category: PrisonerRightCategory.consularAccess,
          title: 'Consular Access',
          description: 'Consular notification upon arrest. Well-established procedures.',
          legalBasis: ['Vienna Convention Art. 36', 'Code of Criminal Procedure Art. 27c'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.interpreterRight,
          title: 'Right to Interpreter',
          description:
              'Free certified interpreter. Dutch system has Register of Sworn '
              'Interpreters and Translators (Rbtv). High quality standards.',
          legalBasis: ['Code of Criminal Procedure Art. 275', 'EU Directive 2010/64/EU', 'Wbtv'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.transferToHomeCountry,
          title: 'Transfer to Home Country',
          description:
              'Active user of FD 2008/909/JHA. WETS (Wet wederzijdse erkenning en '
              'tenuitvoerlegging strafrechtelijke sancties) implements transfer. '
              'Netherlands can transfer without consent in some cases.',
          legalBasis: ['WETS (2012)', 'EU FD 2008/909/JHA', 'WOTS (CoE Convention implementation)'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.legalAidCriminal,
          title: 'Legal Aid',
          description:
              'Rechtsbijstand (legal aid) through Raad voor Rechtsbijstand. '
              'Piketadvocaat (duty lawyer) at police station. Comprehensive system.',
          legalBasis: ['Wet op de Rechtsbijstand', 'EU Directive 2016/1919/EU'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.prisonConditions,
          title: 'Prison Conditions',
          description:
              'Among best in Europe. Single cells. Extensive programmes. Netherlands '
              'has actually closed prisons due to declining population. CPT very '
              'positive. However, VRIS regime (Vreemdelingen in de Strafrechtketen — '
              'foreigners in criminal justice) offers fewer privileges.',
          legalBasis: [
            'Penitentiaire beginselenwet (Prison Principles Act)',
            'Penitentiaire maatregel',
          ],
          practicalNotes:
              'Foreign prisoners without residence rights are placed in VRIS regime '
              'with fewer privileges (no community leave, limited work). This has been '
              'criticised as discriminatory by Ombudsman.',
        ),
        PrisonerRight(
          category: PrisonerRightCategory.communicationRights,
          title: 'Communication Rights',
          description:
              'Weekly visits (1 hour). Daily phone access (10 min). Letters unrestricted. '
              'Video calls. Lawyer visits unrestricted.',
          legalBasis: ['Penitentiaire beginselenwet Art. 36-39'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.healthcareInPrison,
          title: 'Healthcare',
          description:
              'High standard. Prison medical service. Penitentiair Psychiatrisch Centrum '
              'for mental health. Drug treatment. Equivalence of care enforced.',
          legalBasis: ['Penitentiaire beginselenwet Art. 41-46'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.religiousRights,
          title: 'Religious Rights',
          description:
              'Multi-faith chaplaincy (Protestant, Catholic, Muslim, Jewish, Hindu, '
              'Buddhist, humanist). Halal meals. Prayer rooms.',
          legalBasis: ['Penitentiaire beginselenwet Art. 41'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.immigrationConsequences,
          title: 'Immigration Consequences',
          description:
              'Conviction can trigger: ongewenstverklaring (declaration as undesirable '
              'alien) or inreisverbod (entry ban). IND revokes residence permit. '
              'Sliding scale: longer residence = higher conviction threshold for expulsion.',
          legalBasis: [
            'Vreemdelingenwet 2000 Art. 67',
            'Vreemdelingenbesluit Art. 3.86 (sliding scale)',
            'EU Directive 2004/38/EC',
          ],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.earlyReleaseParole,
          title: 'Early Release / Parole',
          description:
              'Conditional release (voorwaardelijke invrijheidstelling - v.i.) after '
              'two-thirds of sentence (for sentences over 2 years). Strafonderbreking '
              '(sentence interruption) for deportation possible.',
          legalBasis: ['Wetboek van Strafrecht Art. 6:2:10'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.deportationAfterSentence,
          title: 'Deportation After Sentence',
          description:
              'DT&V (Dienst Terugkeer en Vertrek) coordinates removal. Detention '
              'in vreemdelingendetentie (immigration detention, Rotterdam or Zeist). '
              'Non-refoulement via Art. 3 ECHR.',
          legalBasis: ['Vreemdelingenwet 2000 Art. 59', 'EU Return Directive 2008/115/EC'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.europeanArrestWarrant,
          title: 'European Arrest Warrant',
          description:
              'Internationale Rechtshulpkamer (International Assistance Chamber) of '
              'Amsterdam District Court exclusively handles all EAW cases.',
          legalBasis: ['Overleveringswet (Surrender Act)', 'EU FD 2002/584/JHA'],
        ),
      ],
      ngos: [
        PrisonerSupportNGO(
          name: 'Meldpunt Vreemdelingendetentie',
          country: 'Netherlands',
          description: 'Monitors immigration detention conditions.',
          website: 'https://www.meldpuntvreemdelingendetentie.nl',
          languages: ['Dutch', 'English'],
        ),
        PrisonerSupportNGO(
          name: 'Stichting LOS (Landelijk Ongedocumenteerden Steunpunt)',
          country: 'Netherlands',
          description: 'Support for undocumented migrants, including detention assistance.',
          website: 'https://www.stichtinglos.nl',
          languages: ['Dutch', 'English'],
        ),
        PrisonerSupportNGO(
          name: 'Bonjo',
          country: 'Netherlands',
          description: 'Prisoner support and reintegration.',
          website: 'https://www.bonjo.nl',
          languages: ['Dutch', 'English'],
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 21. POLAND (PL)
    // -----------------------------------------------------------------------
    CountryPrisonerRights(
      countryCode: 'PL',
      countryName: 'Poland',
      prisonAuthority: 'Służba Więzienna (Prison Service)',
      prisonAuthorityWebsite: 'https://sw.gov.pl',
      approximatePrisonPopulation: 72000,
      foreignPrisonerPercentage: 2.0,
      rights: [
        PrisonerRight(
          category: PrisonerRightCategory.consularAccess,
          title: 'Consular Access',
          description: 'Right to consular contact. Low foreign prisoner percentage.',
          legalBasis: ['Vienna Convention Art. 36', 'Code of Criminal Procedure Art. 72§1'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.interpreterRight,
          title: 'Right to Interpreter',
          description: 'Free interpreter at all stages. Ukrainian interpreters increasingly in demand.',
          legalBasis: ['Code of Criminal Procedure Art. 72', 'EU Directive 2010/64/EU'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.transferToHomeCountry,
          title: 'Transfer to Home Country',
          description: 'FD 2008/909/JHA implemented via Code of Criminal Procedure amendments. CoE ETS 112.',
          legalBasis: ['Code of Criminal Procedure Ch. 66g', 'EU FD 2008/909/JHA'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.legalAidCriminal,
          title: 'Legal Aid',
          description:
              'Obrońca z urzędu (court-appointed lawyer). Mandatory for serious offences. '
              'Free for persons who demonstrate inability to pay.',
          legalBasis: ['Code of Criminal Procedure Art. 78-81', 'EU Directive 2016/1919/EU'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.prisonConditions,
          title: 'Prison Conditions',
          description:
              'Poland has one of the largest prison populations in the EU. Overcrowding '
              'historically problematic (Orchowski v. Poland 2009 pilot judgment). '
              'Conditions improved since. Minimum 3m² per person.',
          legalBasis: [
            'Executive Penal Code (Kodeks karny wykonawczy)',
            'ECtHR Orchowski v. Poland (2009)',
          ],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.communicationRights,
          title: 'Communication Rights',
          description: 'Visits at least twice monthly. Phone access. Letters. Lawyer visits unrestricted.',
          legalBasis: ['Executive Penal Code Art. 102, 105'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.healthcareInPrison,
          title: 'Healthcare',
          description: 'Medical units. Prison hospitals. Specialist referrals.',
          legalBasis: ['Executive Penal Code Art. 115-118'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.religiousRights,
          title: 'Religious Rights',
          description: 'Catholic chaplains in all prisons. Other faiths accommodated. Strong religious tradition.',
          legalBasis: ['Polish Constitution Art. 53', 'Executive Penal Code Art. 106'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.immigrationConsequences,
          title: 'Immigration Consequences',
          description: 'Conviction can lead to obligation to return and entry ban.',
          legalBasis: ['Act on Foreigners Art. 302-306'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.earlyReleaseParole,
          title: 'Early Release / Parole',
          description: 'Conditional release after half (standard) or two-thirds (recidivist) of sentence.',
          legalBasis: ['Criminal Code Art. 77-82'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.deportationAfterSentence,
          title: 'Deportation After Sentence',
          description: 'Border Guard enforces removal. Guarded Centres for Foreigners for detention.',
          legalBasis: ['Act on Foreigners', 'EU Return Directive 2008/115/EC'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.europeanArrestWarrant,
          title: 'European Arrest Warrant',
          description: 'Regional Court handles EAW. Poland is one of the most active EAW issuers in the EU.',
          legalBasis: ['Code of Criminal Procedure Ch. 65a-b', 'EU FD 2002/584/JHA'],
          practicalNotes:
              'Poland issues a very high number of EAWs, including for minor offences. '
              'This has led to proportionality concerns in executing states. Some CJEU '
              'cases addressed rule of law concerns (C-216/18 PPU).',
        ),
      ],
      ngos: [
        PrisonerSupportNGO(
          name: 'Helsinki Foundation for Human Rights (HFHR)',
          country: 'Poland',
          description: 'Major human rights organisation. Monitors detention and assists foreigners.',
          website: 'https://www.hfhr.pl',
          languages: ['Polish', 'English'],
        ),
        PrisonerSupportNGO(
          name: 'Association for Legal Intervention (SIP)',
          country: 'Poland',
          description: 'Legal assistance for refugees and migrants in detention.',
          website: 'https://interwencjaprawna.pl',
          languages: ['Polish', 'English', 'Russian'],
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 22. PORTUGAL (PT)
    // -----------------------------------------------------------------------
    CountryPrisonerRights(
      countryCode: 'PT',
      countryName: 'Portugal',
      prisonAuthority: 'Direção-Geral de Reinserção e Serviços Prisionais (DGRSP)',
      prisonAuthorityWebsite: 'https://dgrsp.justica.gov.pt',
      approximatePrisonPopulation: 12000,
      foreignPrisonerPercentage: 18.0,
      rights: [
        PrisonerRight(
          category: PrisonerRightCategory.consularAccess,
          title: 'Consular Access',
          description: 'Right to consular notification. Brazilian, Cape Verdean, and African nationals common.',
          legalBasis: ['Vienna Convention Art. 36', 'Code of Criminal Procedure Art. 92'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.interpreterRight,
          title: 'Right to Interpreter',
          description: 'Free interpreter. Portuguese is accessible to Lusophone nationals (Brazil, Angola, Mozambique, Cape Verde).',
          legalBasis: ['Code of Criminal Procedure Art. 92', 'EU Directive 2010/64/EU'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.transferToHomeCountry,
          title: 'Transfer to Home Country',
          description:
              'FD 2008/909/JHA implemented. Bilateral agreements with CPLP '
              '(Portuguese-speaking countries). CoE ETS 112.',
          legalBasis: ['EU FD 2008/909/JHA', 'Law 158/2015', 'CoE Convention ETS 112'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.legalAidCriminal,
          title: 'Legal Aid',
          description: 'Apoio judiciário (legal aid). Free for low-income persons. Segurança Social assesses eligibility.',
          legalBasis: ['Law 34/2004 (Legal Aid Act)', 'EU Directive 2016/1919/EU'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.prisonConditions,
          title: 'Prison Conditions',
          description:
              'Variable conditions. Some overcrowding. Lisbon Central Prison (EPL) '
              'problematic. Newer facilities better. CPT noted some improvements.',
          legalBasis: ['Code on Execution of Sentences (Law 115/2009)', 'European Prison Rules'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.communicationRights,
          title: 'Communication Rights',
          description: 'Regular visits. Phone access. Letters. Intimate visits (visitas íntimas). Lawyer visits unrestricted.',
          legalBasis: ['Law 115/2009'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.healthcareInPrison,
          title: 'Healthcare',
          description: 'Medical units. Hospital São João de Deus (prison hospital). NHS referrals.',
          legalBasis: ['Law 115/2009'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.religiousRights,
          title: 'Religious Rights',
          description: 'Catholic chaplains. Other faiths accommodated.',
          legalBasis: ['Portuguese Constitution Art. 41', 'Law 115/2009'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.immigrationConsequences,
          title: 'Immigration Consequences',
          description:
              'Court can impose accessory penalty of expulsion for sentences over '
              '6 months. Administrative removal also possible. Entry ban 5-10 years.',
          legalBasis: ['Criminal Code Art. 151', 'Foreigners Act (Law 23/2007) Art. 134-142'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.earlyReleaseParole,
          title: 'Early Release / Parole',
          description:
              'Conditional release (liberdade condicional) after half the sentence '
              '(mandatory consideration at two-thirds). Foreign prisoners eligible.',
          legalBasis: ['Criminal Code Art. 61-64'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.deportationAfterSentence,
          title: 'Deportation After Sentence',
          description: 'SEF/AIMA enforces removal. Detention at Unidade Habitacional de Santo António. Non-refoulement.',
          legalBasis: ['Law 23/2007', 'EU Return Directive 2008/115/EC'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.europeanArrestWarrant,
          title: 'European Arrest Warrant',
          description: 'Court of Appeal handles EAW. Implemented by Law 65/2003.',
          legalBasis: ['Law 65/2003', 'EU FD 2002/584/JHA'],
        ),
      ],
      ngos: [
        PrisonerSupportNGO(
          name: 'Portuguese Refugee Council (CPR)',
          country: 'Portugal',
          description: 'Legal assistance for refugees and migrants.',
          website: 'https://cpr.pt',
          languages: ['Portuguese', 'English', 'French'],
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 23. ROMANIA (RO)
    // -----------------------------------------------------------------------
    CountryPrisonerRights(
      countryCode: 'RO',
      countryName: 'Romania',
      prisonAuthority: 'Administrația Națională a Penitenciarelor (ANP)',
      prisonAuthorityWebsite: 'https://anp.gov.ro',
      approximatePrisonPopulation: 22000,
      foreignPrisonerPercentage: 2.5,
      rights: [
        PrisonerRight(
          category: PrisonerRightCategory.consularAccess,
          title: 'Consular Access',
          description: 'Right to consular notification and access.',
          legalBasis: ['Vienna Convention Art. 36', 'Code of Criminal Procedure Art. 10'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.interpreterRight,
          title: 'Right to Interpreter',
          description: 'Free interpreter at all stages.',
          legalBasis: ['Code of Criminal Procedure Art. 12', 'EU Directive 2010/64/EU'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.transferToHomeCountry,
          title: 'Transfer to Home Country',
          description: 'FD 2008/909/JHA implemented via Law 302/2004 (amended). CoE ETS 112.',
          legalBasis: ['Law 302/2004', 'EU FD 2008/909/JHA'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.legalAidCriminal,
          title: 'Legal Aid',
          description: 'Mandatory defence for serious offences and detained persons. Bar assigns lawyers.',
          legalBasis: ['Code of Criminal Procedure Art. 90-92', 'EU Directive 2016/1919/EU'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.prisonConditions,
          title: 'Prison Conditions',
          description:
              'ECtHR pilot judgment Rezmiveș v. Romania (2017) found systematic overcrowding '
              'and poor conditions. Compensation mechanism introduced. CPT repeatedly critical. '
              'Conditions improving slowly with EU-funded renovation.',
          legalBasis: [
            'Law 254/2013 (Execution of Sentences Act)',
            'ECtHR Rezmiveș v. Romania (2017)',
          ],
          practicalNotes:
              'Apply for compensation if subjected to less than 4m² personal space. '
              'Days of detention in poor conditions can be credited against sentence.',
        ),
        PrisonerRight(
          category: PrisonerRightCategory.communicationRights,
          title: 'Communication Rights',
          description: 'Visits, phone calls, letters. Varies by prison regime category.',
          legalBasis: ['Law 254/2013'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.healthcareInPrison,
          title: 'Healthcare',
          description: 'Medical units. Jilava Prison Hospital. Specialist referrals. Concerns about quality.',
          legalBasis: ['Law 254/2013'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.religiousRights,
          title: 'Religious Rights',
          description: 'Orthodox chaplains. Other faiths can be accommodated.',
          legalBasis: ['Romanian Constitution Art. 29', 'Law 254/2013'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.immigrationConsequences,
          title: 'Immigration Consequences',
          description: 'Conviction can result in removal and entry ban. Court can impose expulsion as criminal measure.',
          legalBasis: ['Emergency Ordinance 194/2002 (Foreigners Act)', 'Criminal Code Art. 66(1)(b)'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.earlyReleaseParole,
          title: 'Early Release / Parole',
          description:
              'Conditional release after portion of sentence served (varies by severity). '
              'Good conduct credits. Foreign prisoners eligible.',
          legalBasis: ['Criminal Code Art. 99-106'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.deportationAfterSentence,
          title: 'Deportation After Sentence',
          description: 'General Inspectorate for Immigration enforces removal. Detention centres available.',
          legalBasis: ['Emergency Ordinance 194/2002', 'EU Return Directive 2008/115/EC'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.europeanArrestWarrant,
          title: 'European Arrest Warrant',
          description: 'Court of Appeal handles EAW. Implemented via Law 302/2004.',
          legalBasis: ['Law 302/2004', 'EU FD 2002/584/JHA'],
        ),
      ],
      ngos: [
        PrisonerSupportNGO(
          name: 'APADOR-CH (Romanian Helsinki Committee)',
          country: 'Romania',
          description: 'Prison monitoring and human rights.',
          website: 'https://apador.org',
          languages: ['Romanian', 'English'],
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 24. SLOVAKIA (SK)
    // -----------------------------------------------------------------------
    CountryPrisonerRights(
      countryCode: 'SK',
      countryName: 'Slovakia',
      prisonAuthority: 'Zbor väzenskej a justičnej stráže (Corps of Prison and Court Guard)',
      prisonAuthorityWebsite: 'https://www.zvjs.sk',
      approximatePrisonPopulation: 9500,
      foreignPrisonerPercentage: 3.0,
      rights: [
        PrisonerRight(
          category: PrisonerRightCategory.consularAccess,
          title: 'Consular Access',
          description: 'Right to consular access upon arrest.',
          legalBasis: ['Vienna Convention Art. 36', 'Code of Criminal Procedure §34'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.interpreterRight,
          title: 'Right to Interpreter',
          description: 'Free interpreter. Czech mutually intelligible, otherwise interpreter required.',
          legalBasis: ['Code of Criminal Procedure §2(20)', 'EU Directive 2010/64/EU'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.transferToHomeCountry,
          title: 'Transfer to Home Country',
          description: 'FD 2008/909/JHA implemented. Close cooperation with Czech Republic.',
          legalBasis: ['EU FD 2008/909/JHA', 'Act on International Cooperation in Criminal Matters'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.legalAidCriminal,
          title: 'Legal Aid',
          description: 'Mandatory defence for serious offences. Centre for Legal Aid provides services.',
          legalBasis: ['Code of Criminal Procedure §37-42', 'Legal Aid Act', 'EU Directive 2016/1919/EU'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.prisonConditions,
          title: 'Prison Conditions',
          description: 'Generally acceptable. Some overcrowding. CPT noted improvements.',
          legalBasis: ['Act on Execution of Prison Sentences (475/2005)', 'European Prison Rules'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.communicationRights,
          title: 'Communication Rights',
          description: 'Visits, phone, letters. Lawyer visits unrestricted.',
          legalBasis: ['Act 475/2005'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.healthcareInPrison,
          title: 'Healthcare',
          description: 'Medical units. Prison hospital in Trenčín.',
          legalBasis: ['Act 475/2005'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.religiousRights,
          title: 'Religious Rights',
          description: 'Catholic and Protestant chaplains. Other faiths accommodated.',
          legalBasis: ['Slovak Constitution Art. 24'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.immigrationConsequences,
          title: 'Immigration Consequences',
          description: 'Conviction can lead to administrative expulsion and entry ban.',
          legalBasis: ['Act on Residence of Aliens (404/2011)'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.earlyReleaseParole,
          title: 'Early Release / Parole',
          description: 'Conditional release after half or two-thirds of sentence.',
          legalBasis: ['Criminal Code §66-68'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.deportationAfterSentence,
          title: 'Deportation After Sentence',
          description: 'Alien Police enforce removal. Detention at Medveďov or Sečovce facilities.',
          legalBasis: ['Act 404/2011', 'EU Return Directive 2008/115/EC'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.europeanArrestWarrant,
          title: 'European Arrest Warrant',
          description: 'Regional Court handles EAW.',
          legalBasis: ['Act on EAW', 'EU FD 2002/584/JHA'],
        ),
      ],
      ngos: [
        PrisonerSupportNGO(
          name: 'Human Rights League (Liga za ľudské práva)',
          country: 'Slovakia',
          description: 'Legal aid for foreigners and asylum seekers in detention.',
          website: 'https://www.hrl.sk',
          languages: ['Slovak', 'English'],
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 25. SLOVENIA (SI)
    // -----------------------------------------------------------------------
    CountryPrisonerRights(
      countryCode: 'SI',
      countryName: 'Slovenia',
      prisonAuthority: 'Uprava za izvrševanje kazenskih sankcij (Prison Administration)',
      prisonAuthorityWebsite: 'https://www.gov.si/drzavni-organi/organi-v-sestavi/uprava-za-izvrsevanje-kazenskih-sankcij/',
      approximatePrisonPopulation: 1400,
      foreignPrisonerPercentage: 15.0,
      rights: [
        PrisonerRight(
          category: PrisonerRightCategory.consularAccess,
          title: 'Consular Access',
          description: 'Right to consular access. Western Balkan nationals form majority of foreign prisoners.',
          legalBasis: ['Vienna Convention Art. 36', 'Criminal Procedure Act Art. 4'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.interpreterRight,
          title: 'Right to Interpreter',
          description: 'Free interpreter. Serbo-Croatian widely understood but interpreter provided.',
          legalBasis: ['Criminal Procedure Act Art. 8', 'EU Directive 2010/64/EU'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.transferToHomeCountry,
          title: 'Transfer to Home Country',
          description: 'FD 2008/909/JHA implemented. Cooperation with Western Balkan states.',
          legalBasis: ['EU FD 2008/909/JHA', 'Cooperation in Criminal Matters with EU Act'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.legalAidCriminal,
          title: 'Legal Aid',
          description: 'Free legal aid for detained persons. Legal Aid Act covers criminal cases.',
          legalBasis: ['Legal Aid Act', 'Criminal Procedure Act', 'EU Directive 2016/1919/EU'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.prisonConditions,
          title: 'Prison Conditions',
          description:
              'Small prison system. Dob and Ljubljana prisons. Some overcrowding. '
              'Generally acceptable conditions. CPT noted improvements.',
          legalBasis: ['Enforcement of Criminal Sanctions Act', 'European Prison Rules'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.communicationRights,
          title: 'Communication Rights',
          description: 'Regular visits, phone, letters. Lawyer visits unrestricted.',
          legalBasis: ['Enforcement of Criminal Sanctions Act'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.healthcareInPrison,
          title: 'Healthcare',
          description: 'Medical units. Hospital referrals to public system.',
          legalBasis: ['Enforcement of Criminal Sanctions Act'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.religiousRights,
          title: 'Religious Rights',
          description: 'Catholic and other chaplains. Religious freedom respected.',
          legalBasis: ['Slovenian Constitution Art. 41'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.immigrationConsequences,
          title: 'Immigration Consequences',
          description: 'Conviction may lead to removal and entry ban.',
          legalBasis: ['Foreigners Act'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.earlyReleaseParole,
          title: 'Early Release / Parole',
          description: 'Conditional release after half the sentence. Foreign prisoners eligible.',
          legalBasis: ['Criminal Code Art. 88'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.deportationAfterSentence,
          title: 'Deportation After Sentence',
          description: 'Police enforce removal. Centre for Foreigners in Postojna. Non-refoulement.',
          legalBasis: ['Foreigners Act', 'EU Return Directive 2008/115/EC'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.europeanArrestWarrant,
          title: 'European Arrest Warrant',
          description: 'District Court handles EAW.',
          legalBasis: ['Cooperation in Criminal Matters with EU Act', 'EU FD 2002/584/JHA'],
        ),
      ],
      ngos: [
        PrisonerSupportNGO(
          name: 'Legal-Informational Centre for NGOs (PIC)',
          country: 'Slovenia',
          description: 'Legal assistance for refugees and migrants in detention.',
          website: 'https://pic.si',
          languages: ['Slovenian', 'English'],
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 26. SPAIN (ES)
    // -----------------------------------------------------------------------
    CountryPrisonerRights(
      countryCode: 'ES',
      countryName: 'Spain',
      prisonAuthority: 'Secretaría General de Instituciones Penitenciarias (SGIP)',
      prisonAuthorityWebsite: 'https://www.institucionpenitenciaria.es',
      approximatePrisonPopulation: 55000,
      foreignPrisonerPercentage: 28.0,
      rights: [
        PrisonerRight(
          category: PrisonerRightCategory.consularAccess,
          title: 'Consular Access',
          description:
              'Right to consular notification upon arrest. Spain has large foreign '
              'prisoner population (Moroccan, Romanian, Colombian nationals prominent).',
          legalBasis: ['Vienna Convention Art. 36', 'LECrim Art. 520(2)(e)'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.interpreterRight,
          title: 'Right to Interpreter',
          description:
              'Free interpreter from police detention (detención). Translation of essential '
              'documents. Spanish, Catalan, Basque, Galician are co-official languages.',
          legalBasis: ['LECrim Art. 520(2)(e)', 'LO 5/2015 (transposing EU Directive 2010/64/EU)'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.transferToHomeCountry,
          title: 'Transfer to Home Country',
          description:
              'FD 2008/909/JHA implemented via LO 7/2014. Bilateral agreements with '
              'Morocco, Colombia, and many Latin American states. Spain actively transfers.',
          legalBasis: ['LO 7/2014', 'EU FD 2008/909/JHA', 'CoE Convention ETS 112', 'Bilateral treaties'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.legalAidCriminal,
          title: 'Legal Aid',
          description:
              'Turno de oficio (duty lawyer system) through Colegios de Abogados. '
              'Automatic for detainees. Justicia gratuita for those below income threshold.',
          legalBasis: ['Ley 1/1996 (Asistencia Jurídica Gratuita)', 'LECrim', 'EU Directive 2016/1919/EU'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.prisonConditions,
          title: 'Prison Conditions',
          description:
              'Mixed conditions. Newer "centros tipo" (modular prisons) good standard. '
              'Older prisons can be overcrowded. Three grades (grados): first (closed), '
              'second (standard), third (semi-liberty). CPT generally positive with some concerns.',
          legalBasis: [
            'Ley Orgánica 1/1979 (Ley General Penitenciaria)',
            'Reglamento Penitenciario (RD 190/1996)',
            'European Prison Rules',
          ],
          practicalNotes:
              'Catalonia has its own prison system (Departament de Justícia). '
              'Standard in Catalonia slightly different from rest of Spain.',
        ),
        PrisonerRight(
          category: PrisonerRightCategory.communicationRights,
          title: 'Communication Rights',
          description:
              'Weekly visits (vis-a-vis). Phone calls (5/week, 5 min each). Letters '
              'unrestricted. Intimate visits (vis-a-vis íntima) monthly. '
              'Family visits (vis-a-vis familiar) periodically. Lawyer visits unrestricted.',
          legalBasis: ['Reglamento Penitenciario Art. 41-53'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.healthcareInPrison,
          title: 'Healthcare',
          description:
              'Medical units in all prisons. Hospital referrals to SNS. Mental health '
              'programmes. Drug treatment (methadone). HIV/TB programmes.',
          legalBasis: ['Ley General Penitenciaria Art. 36-40', 'Reglamento Penitenciario'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.religiousRights,
          title: 'Religious Rights',
          description:
              'Catholic chaplaincy well established. Muslim, Protestant, Jewish, and '
              'other religious services arranged. Halal meals available. '
              'Spain has large Muslim prisoner population.',
          legalBasis: ['Spanish Constitution Art. 16', 'Reglamento Penitenciario Art. 230'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.immigrationConsequences,
          title: 'Immigration Consequences',
          description:
              'Expulsión judicial: court can substitute prison sentences under 6 years '
              'with deportation + 5-10 year entry ban (Art. 89 CP). Administrative '
              'expulsion also possible. EU citizens: higher threshold.',
          legalBasis: [
            'Código Penal Art. 89 (judicial expulsion)',
            'LO 4/2000 (Ley de Extranjería) Art. 57',
          ],
          practicalNotes:
              'Art. 89 CP allows substitution of entire prison sentence with expulsion '
              'for foreigners sentenced to less than 6 years. This is frequently applied. '
              'Challenge at Juzgado de Vigilancia Penitenciaria.',
        ),
        PrisonerRight(
          category: PrisonerRightCategory.earlyReleaseParole,
          title: 'Early Release / Parole',
          description:
              'Libertad condicional after three-quarters of sentence (two-thirds with '
              'good classification). Third-grade (tercer grado) semi-liberty after '
              'half the sentence. Foreign prisoners eligible but access to third grade '
              'can be more difficult without social ties.',
          legalBasis: ['Código Penal Art. 90-93', 'Ley General Penitenciaria Art. 72'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.deportationAfterSentence,
          title: 'Deportation After Sentence',
          description:
              'Policía Nacional (Brigada de Extranjería) enforces expulsion. '
              'CIE (Centro de Internamiento de Extranjeros) detention, max 60 days. '
              'Non-refoulement applies.',
          legalBasis: [
            'LO 4/2000 Art. 61-64',
            'EU Return Directive 2008/115/EC',
          ],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.europeanArrestWarrant,
          title: 'European Arrest Warrant',
          description:
              'Juzgado Central de Instrucción (Audiencia Nacional) handles EAW. '
              'Spanish nationals can be surrendered with return guarantee.',
          legalBasis: ['Ley 23/2014 (mutual recognition)', 'EU FD 2002/584/JHA'],
        ),
      ],
      ngos: [
        PrisonerSupportNGO(
          name: 'SJM (Servicio Jesuita a Migrantes)',
          country: 'Spain',
          description: 'Legal assistance and visits to migrants in CIE detention centres.',
          website: 'https://sjme.org',
          languages: ['Spanish', 'English', 'French', 'Arabic'],
        ),
        PrisonerSupportNGO(
          name: 'CEAR (Comisión Española de Ayuda al Refugiado)',
          country: 'Spain',
          description: 'Refugee assistance including detained asylum seekers.',
          website: 'https://www.cear.es',
          languages: ['Spanish', 'English', 'French', 'Arabic'],
        ),
        PrisonerSupportNGO(
          name: 'APDHA (Asociación Pro Derechos Humanos de Andalucía)',
          country: 'Spain',
          description: 'Human rights monitoring of CIE detention centres.',
          website: 'https://www.apdha.org',
          languages: ['Spanish', 'English'],
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // 27. SWEDEN (SE)
    // -----------------------------------------------------------------------
    CountryPrisonerRights(
      countryCode: 'SE',
      countryName: 'Sweden',
      prisonAuthority: 'Kriminalvården (Swedish Prison and Probation Service)',
      prisonAuthorityWebsite: 'https://www.kriminalvarden.se',
      approximatePrisonPopulation: 6500,
      foreignPrisonerPercentage: 30.0,
      rights: [
        PrisonerRight(
          category: PrisonerRightCategory.consularAccess,
          title: 'Consular Access',
          description:
              'Right to consular notification. Sweden strictly respects Vienna Convention. '
              'Well-established procedures.',
          legalBasis: ['Vienna Convention Art. 36', 'Rättegångsbalken (Code of Judicial Procedure) Ch. 24'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.interpreterRight,
          title: 'Right to Interpreter',
          description:
              'Free interpreter at all stages. Kammarkollegiet authorises interpreters. '
              'High quality. Arabic, Somali, Tigrinya, Polish, and other interpreters '
              'widely available.',
          legalBasis: [
            'Rättegångsbalken Ch. 5 §6',
            'Förvaltningslagen §13',
            'EU Directive 2010/64/EU',
          ],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.transferToHomeCountry,
          title: 'Transfer to Home Country',
          description:
              'FD 2008/909/JHA implemented via Lag (2015:96). Nordic Enforcement '
              'Agreement simplifies transfers to/from Nordic states. CoE ETS 112.',
          legalBasis: [
            'Lag (2015:96) om erkännande och verkställighet av frihetsberövande påföljder',
            'Nordic Enforcement Agreement',
            'Internationell straffverkställighetslag (1972:260)',
          ],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.legalAidCriminal,
          title: 'Legal Aid',
          description:
              'Offentlig försvarare (public defence counsel) appointed by court when: '
              'penalty may exceed 6 months, complex case, or accused detained. '
              'Free for the accused if convicted and unable to pay.',
          legalBasis: ['Rättegångsbalken Ch. 21', 'EU Directive 2016/1919/EU'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.prisonConditions,
          title: 'Prison Conditions',
          description:
              'High standard. Three security classes. Single cells standard. '
              'Extensive rehabilitation programmes. CPT generally very positive. '
              'Concerns have been raised about restrictions during pre-trial '
              'detention (isolering).',
          legalBasis: [
            'Fängelselagen (2010:610)',
            'Häkteslagen (2010:611)',
            'European Prison Rules',
          ],
          practicalNotes:
              'Pre-trial detention restrictions (restriktioner) can be severe: '
              'solitary confinement, no media, monitored correspondence. CPT has '
              'criticised this. Challenge restrictions through court.',
        ),
        PrisonerRight(
          category: PrisonerRightCategory.communicationRights,
          title: 'Communication Rights',
          description:
              'Regular visits. Phone access. Letters. Video calls available. '
              'Pre-trial: restrictions may limit contact. Lawyer visits always allowed.',
          legalBasis: ['Fängelselagen Ch. 7-8', 'Häkteslagen Ch. 3'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.healthcareInPrison,
          title: 'Healthcare',
          description:
              'High standard. Kriminalvården health service. Hospital referrals '
              'through regions. Mental health care. Drug rehabilitation. '
              'Hinseberg prison has women\'s healthcare programme.',
          legalBasis: ['Fängelselagen Ch. 9', 'Hälso- och sjukvårdslagen'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.religiousRights,
          title: 'Religious Rights',
          description:
              'Multi-faith chaplaincy. Church of Sweden, Muslim, Catholic, Orthodox, '
              'and other counsellors. Religious items and services. Dietary requirements met.',
          legalBasis: ['Swedish Constitution (Regeringsformen) Ch. 2 §1', 'Fängelselagen'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.immigrationConsequences,
          title: 'Immigration Consequences',
          description:
              'Criminal conviction: court can impose utvisning (expulsion) as part of '
              'criminal sentence for foreigners convicted of offences carrying imprisonment. '
              'Entry ban 5-15 years or lifetime. Proportionality assessment (family, '
              'length of stay). EU citizens: serious public policy/security.',
          legalBasis: [
            'Utlänningslagen (2005:716) Ch. 8a',
            'Brottsbalken Ch. 34 §4 (repealed, now in UtlL)',
          ],
          practicalNotes:
              'Swedish courts take family ties seriously in proportionality assessment. '
              'Migrationsöverdomstolen case law important. Challenge expulsion in '
              'criminal appeal. Separate immigration proceedings may also occur.',
        ),
        PrisonerRight(
          category: PrisonerRightCategory.earlyReleaseParole,
          title: 'Early Release / Parole',
          description:
              'Conditional release (villkorlig frigivning) after two-thirds of sentence '
              '(mandatory unless exceptional reasons). Supervision by Kriminalvården. '
              'Foreign prisoners with expulsion orders may be released for deportation.',
          legalBasis: ['Brottsbalken Ch. 26 §6-10'],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.deportationAfterSentence,
          title: 'Deportation After Sentence',
          description:
              'Migrationsverket (Migration Agency) and Police enforce. Detention at '
              'Migrationsverket detention centres (Märsta, Kållered, Flen). '
              'Maximum 12 months (18 in criminal cases). Non-refoulement strictly observed.',
          legalBasis: [
            'Utlänningslagen Ch. 10-12',
            'EU Return Directive 2008/115/EC',
          ],
        ),
        PrisonerRight(
          category: PrisonerRightCategory.europeanArrestWarrant,
          title: 'European Arrest Warrant',
          description:
              'District Court (Tingsrätt) handles EAW. Swedish nationals can be '
              'surrendered with return guarantee. Nordic Arrest Warrant for Nordic states.',
          legalBasis: [
            'Lag (2003:1156) om överlämnande från Sverige enligt en europeisk arresteringsorder',
            'EU FD 2002/584/JHA',
          ],
        ),
      ],
      ngos: [
        PrisonerSupportNGO(
          name: 'KRIS (Kriminellas Revansch I Samhället)',
          country: 'Sweden',
          description:
              'Peer support for prisoners and ex-prisoners. Reintegration help.',
          website: 'https://www.kfriseura.fi',
          languages: ['Swedish', 'English'],
        ),
        PrisonerSupportNGO(
          name: 'Swedish Red Cross — Detention Monitoring',
          country: 'Sweden',
          description: 'Monitors migration detention. Legal information for detainees.',
          website: 'https://www.rodakorset.se',
          languages: ['Swedish', 'English', 'Arabic', 'Somali', 'Tigrinya'],
        ),
        PrisonerSupportNGO(
          name: 'Asylrättscentrum (Swedish Refugee Law Center)',
          country: 'Sweden',
          description: 'Legal advice for asylum seekers including those facing deportation after conviction.',
          website: 'https://www.swereflaw.se',
          languages: ['Swedish', 'English', 'Arabic'],
        ),
      ],
    ),
  ];
}
