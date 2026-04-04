/// Comprehensive EU Citizenship Pathways Database
/// Contains real naturalization data for all 27 EU member states.
/// Sources: national citizenship laws, government portals, EUDO CITLAW.
/// Last verified: 2026-Q1
library;

class CitizenshipPathway {
  final String country;
  final String countryCode;
  final int residenceYears;
  final bool languageTestRequired;
  final String? languageLevel;
  final bool civicsTestRequired;
  final bool dualCitizenshipAllowed;
  final String applicationAuthority;
  final String? applicationFee;
  final int processingMonths;
  final List<String> requirements;
  final List<String> exceptions;
  final String legalBasis;
  final RenunciationRule renunciationRule;
  final MarriagePathway? marriagePathway;
  final List<String> additionalNotes;

  const CitizenshipPathway({
    required this.country,
    required this.countryCode,
    required this.residenceYears,
    required this.languageTestRequired,
    this.languageLevel,
    required this.civicsTestRequired,
    required this.dualCitizenshipAllowed,
    required this.applicationAuthority,
    this.applicationFee,
    required this.processingMonths,
    required this.requirements,
    required this.exceptions,
    required this.legalBasis,
    required this.renunciationRule,
    this.marriagePathway,
    this.additionalNotes = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'country': country,
      'countryCode': countryCode,
      'residenceYears': residenceYears,
      'languageTestRequired': languageTestRequired,
      'languageLevel': languageLevel,
      'civicsTestRequired': civicsTestRequired,
      'dualCitizenshipAllowed': dualCitizenshipAllowed,
      'applicationAuthority': applicationAuthority,
      'applicationFee': applicationFee,
      'processingMonths': processingMonths,
      'requirements': requirements,
      'exceptions': exceptions,
      'legalBasis': legalBasis,
      'renunciationRule': renunciationRule.name,
      'marriagePathway': marriagePathway?.toMap(),
      'additionalNotes': additionalNotes,
    };
  }
}

enum RenunciationRule {
  /// Must renounce previous citizenship
  required,

  /// No renunciation required, dual citizenship fully allowed
  notRequired,

  /// Renunciation required with exceptions (reciprocal treaties, refugees, etc.)
  requiredWithExceptions,

  /// Renunciation not enforced in practice
  notEnforced,
}

class MarriagePathway {
  final int residenceYears;
  final int marriageYears;
  final List<String> additionalRequirements;

  const MarriagePathway({
    required this.residenceYears,
    required this.marriageYears,
    this.additionalRequirements = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'residenceYears': residenceYears,
      'marriageYears': marriageYears,
      'additionalRequirements': additionalRequirements,
    };
  }
}

/// Central database providing citizenship pathway data for all 27 EU member states.
class CitizenshipDatabase {
  CitizenshipDatabase._();

  static final List<CitizenshipPathway> _pathways = [
    // =========================================================================
    // 1. AUSTRIA
    // =========================================================================
    const CitizenshipPathway(
      country: 'Austria',
      countryCode: 'AT',
      residenceYears: 10,
      languageTestRequired: true,
      languageLevel: 'B1',
      civicsTestRequired: true,
      dualCitizenshipAllowed: false,
      applicationAuthority: 'Provincial Government (Landesregierung)',
      applicationFee: '€1,115',
      processingMonths: 18,
      requirements: [
        'Minimum 10 years continuous legal residence (6 years if certain conditions met)',
        'At least 5 years of settlement permit (Niederlassungsbewilligung)',
        'German language proficiency at B1 level (ÖIF certificate)',
        'Civics test (Staatsbürgerschaftsprüfung) on democratic order and history',
        'Sufficient income over preceding 3 years',
        'No criminal convictions, no pending criminal proceedings',
        'No close ties to a foreign state that could be detrimental',
        'Positive attitude toward the Republic of Austria',
        'Renunciation of previous citizenship',
        'Health insurance coverage',
      ],
      exceptions: [
        '6 years residence if: born in Austria, married to Austrian citizen for 5+ years, EEA national, recognized refugee, or proven B2 German + 3 years voluntary service',
        '15 years residence: simplified proof of integration',
        '30 years continuous residence: right to citizenship regardless',
        'Special merit: exceptional achievements in science, arts, sports, economy',
        'Former Austrian citizens may re-acquire citizenship',
      ],
      legalBasis: 'Staatsbürgerschaftsgesetz 1985 (StbG), as amended',
      renunciationRule: RenunciationRule.required,
      marriagePathway: MarriagePathway(
        residenceYears: 6,
        marriageYears: 5,
        additionalRequirements: [
          'Must be living together in a joint household',
          'All standard requirements (language, income, clean record) still apply',
        ],
      ),
      additionalNotes: [
        'One of the strictest dual citizenship bans in the EU',
        'Undisclosed retention of prior citizenship can lead to loss of Austrian citizenship',
        'Children born in Austria to foreign parents do NOT automatically get citizenship',
      ],
    ),

    // =========================================================================
    // 2. BELGIUM
    // =========================================================================
    const CitizenshipPathway(
      country: 'Belgium',
      countryCode: 'BE',
      residenceYears: 5,
      languageTestRequired: true,
      languageLevel: 'A2',
      civicsTestRequired: true,
      dualCitizenshipAllowed: true,
      applicationAuthority:
          'Municipal Administration (Gemeentebestuur / Administration communale)',
      applicationFee: '€150',
      processingMonths: 12,
      requirements: [
        'Minimum 5 years of continuous legal residence in Belgium',
        'Hold a permanent residence permit (unlimited duration)',
        'Language proficiency at A2 level in Dutch, French, or German',
        'Social integration: completion of integration course or proof of participation in community life',
        'Economic participation: proof of employment for at least 468 working days over 5 years, OR Belgian diploma, OR completed vocational training',
        'No serious criminal convictions (sentence of 5+ years excludes permanently)',
        'Declaration of nationality before municipal civil registrar',
      ],
      exceptions: [
        '10 years residence: simplified procedure if economically active for 5 years',
        'Marriage to Belgian: 3 years residence + 3 years marriage + cohabitation',
        'Parents of Belgian child: 5 years residence',
        'Born in Belgium: 5 years residence if registered at birth',
        'Disabled persons and pensioners: economic participation waived',
        'Stateless persons: reduced requirements',
      ],
      legalBasis: 'Code de la nationalité belge / Wetboek van de Belgische nationaliteit (2012 reform)',
      renunciationRule: RenunciationRule.notRequired,
      marriagePathway: MarriagePathway(
        residenceYears: 3,
        marriageYears: 3,
        additionalRequirements: [
          'Must be cohabiting in Belgium at time of application',
          'Language and integration requirements still apply',
        ],
      ),
      additionalNotes: [
        'Belgium allows full dual/multiple citizenship since 2008',
        'Nationality declaration (déclaration) is the standard route, not discretionary naturalization',
        'Federal prosecutor can object within 4 months of declaration',
      ],
    ),

    // =========================================================================
    // 3. BULGARIA
    // =========================================================================
    const CitizenshipPathway(
      country: 'Bulgaria',
      countryCode: 'BG',
      residenceYears: 5,
      languageTestRequired: true,
      languageLevel: 'B1',
      civicsTestRequired: false,
      dualCitizenshipAllowed: true,
      applicationAuthority:
          'Ministry of Justice, Directorate of Bulgarian Citizenship',
      applicationFee: 'BGN 100 (~€50)',
      processingMonths: 18,
      requirements: [
        'Minimum 5 years of lawful permanent residence in Bulgaria',
        'No criminal convictions in Bulgaria or country of origin',
        'Sufficient income or lawful occupation to support oneself',
        'Bulgarian language proficiency (B1 equivalent, interview-based assessment)',
        'Release from previous citizenship (unless dual citizenship exception applies)',
        'Must be at least 18 years old',
      ],
      exceptions: [
        '3 years residence if married to a Bulgarian citizen',
        'Bulgarian origin (ethnic Bulgarians): no residence requirement, just proof of ancestry',
        'Persons who have invested over BGN 1 million: naturalization by investment',
        'Stateless persons: 3 years residence',
        'Children adopted by Bulgarian citizens: simplified procedure',
        'Persons of special merit to Bulgaria in science, technology, culture, sports',
      ],
      legalBasis: 'Law on Bulgarian Citizenship (Закон за българското гражданство), 1998, as amended',
      renunciationRule: RenunciationRule.notRequired,
      marriagePathway: MarriagePathway(
        residenceYears: 3,
        marriageYears: 3,
        additionalRequirements: [
          'Must maintain permanent residence',
          'Language test still required',
        ],
      ),
      additionalNotes: [
        'Bulgaria permits full dual citizenship',
        'Ethnic Bulgarian diaspora (e.g., from North Macedonia, Moldova, Ukraine) has fast-track access',
        'Citizenship by investment program under review since EU criticism',
      ],
    ),

    // =========================================================================
    // 4. CROATIA
    // =========================================================================
    const CitizenshipPathway(
      country: 'Croatia',
      countryCode: 'HR',
      residenceYears: 8,
      languageTestRequired: true,
      languageLevel: 'B1',
      civicsTestRequired: true,
      dualCitizenshipAllowed: true,
      applicationAuthority:
          'Ministry of the Interior (Ministarstvo unutarnjih poslova)',
      applicationFee: 'HRK 1,050 (~€140)',
      processingMonths: 12,
      requirements: [
        'Minimum 8 years of continuous legal residence',
        'Croatian language and Latin script proficiency (B1)',
        'Knowledge of Croatian culture and social system (civics test)',
        'No criminal record in Croatia',
        'No threat to public order or national security',
        'Proof of release from previous citizenship (with exceptions)',
        'Must be at least 18 years old',
      ],
      exceptions: [
        '5 years residence for EU Blue Card holders',
        'Marriage to Croatian citizen: 5 years residence + language test',
        'Croatian diaspora (ethnic Croats): no residence requirement, ancestry proof required',
        'Persons of special interest to Croatia (cultural, economic, scientific merit)',
        'Children born in Croatia or adopted by Croatian citizens',
        'Former Yugoslav citizens with Croatian ethnic origin',
      ],
      legalBasis: 'Croatian Citizenship Act (Zakon o hrvatskom državljanstvu), 1991, as amended 2019',
      renunciationRule: RenunciationRule.notRequired,
      marriagePathway: MarriagePathway(
        residenceYears: 5,
        marriageYears: 3,
        additionalRequirements: [
          'Croatian language proficiency still required',
          'Must be cohabiting',
        ],
      ),
      additionalNotes: [
        'Croatia allows dual citizenship without restrictions',
        'Large diaspora naturalization program (especially for Bosnian Croats)',
        'Emigrant Croats can acquire citizenship through declaration',
      ],
    ),

    // =========================================================================
    // 5. CYPRUS
    // =========================================================================
    const CitizenshipPathway(
      country: 'Cyprus',
      countryCode: 'CY',
      residenceYears: 7,
      languageTestRequired: true,
      languageLevel: 'A2',
      civicsTestRequired: false,
      dualCitizenshipAllowed: true,
      applicationAuthority:
          'Civil Registry and Migration Department (Ministry of Interior)',
      applicationFee: '€500',
      processingMonths: 24,
      requirements: [
        'Minimum 7 years legal residence (5 continuous years immediately before application)',
        'Greek language proficiency (basic conversational, approximately A2)',
        'Clean criminal record',
        'Good character and no deportation orders',
        'No threat to public order or security',
        'Intention to reside in Cyprus',
        'Must be at least 18 years old',
      ],
      exceptions: [
        'Marriage to Cypriot citizen: 3 years of marriage + 2 years residence',
        'Persons of Cypriot origin or descent: reduced requirements',
        'Persons who served in Cyprus National Guard',
        'Persons of exceptional service to Cyprus',
        'Cyprus citizenship by investment was abolished in November 2020',
      ],
      legalBasis: 'Civil Registry Law, Cap. 141, as amended (Population Data Archives Law)',
      renunciationRule: RenunciationRule.notRequired,
      marriagePathway: MarriagePathway(
        residenceYears: 2,
        marriageYears: 3,
        additionalRequirements: [
          'Greek language at basic level',
          'Clean criminal record',
          'Joint household',
        ],
      ),
      additionalNotes: [
        'Cyprus allows dual citizenship',
        'Golden passport program was terminated in 2020 after scandals',
        'Processing times are very long (often 2-3 years in practice)',
        'Naturalization is at the discretion of the Council of Ministers',
      ],
    ),

    // =========================================================================
    // 6. CZECHIA (CZECH REPUBLIC)
    // =========================================================================
    const CitizenshipPathway(
      country: 'Czechia',
      countryCode: 'CZ',
      residenceYears: 5,
      languageTestRequired: true,
      languageLevel: 'B1',
      civicsTestRequired: true,
      dualCitizenshipAllowed: true,
      applicationAuthority:
          'Ministry of Interior (Ministerstvo vnitra), via regional offices',
      applicationFee: 'CZK 2,000 (~€80)',
      processingMonths: 6,
      requirements: [
        'Minimum 5 years of permanent residence in Czechia',
        '3 years of permanent residence for EU/EEA/Swiss citizens',
        'Czech language proficiency at B1 level (certified exam)',
        'Basic knowledge of Czech constitutional system, culture, geography (civics exam)',
        'No criminal record (Czech and country of origin)',
        'Proof of income from legal sources over preceding 3 years',
        'No outstanding tax or social security debts',
        'No unduly burdening the social security system',
        'Actual connection to Czechia (employment, family, property)',
      ],
      exceptions: [
        'Former Czech/Czechoslovak citizens: simplified re-acquisition by declaration',
        'Stateless persons and refugees: residence requirement may be reduced',
        'Spouses of Czech citizens: reduced requirements at discretion',
        'Persons who significantly contributed to Czech Republic (culture, science, sports)',
        'Minor children of Czech citizens',
        'EU Blue Card holders: 5 years permanent residence pathway',
      ],
      legalBasis: 'Act No. 186/2013 Coll., on Czech Citizenship (Zákon o státním občanství České republiky)',
      renunciationRule: RenunciationRule.notRequired,
      marriagePathway: MarriagePathway(
        residenceYears: 3,
        marriageYears: 3,
        additionalRequirements: [
          'Permanent residence permit required',
          'Language and civics tests still required',
          'Decision remains discretionary',
        ],
      ),
      additionalNotes: [
        'Since 2014, Czechia fully allows dual citizenship',
        'Previously (before 2014), renunciation was required',
        'Naturalization is discretionary, not an entitlement',
        'Relatively fast processing compared to other EU states',
      ],
    ),

    // =========================================================================
    // 7. DENMARK
    // =========================================================================
    const CitizenshipPathway(
      country: 'Denmark',
      countryCode: 'DK',
      residenceYears: 9,
      languageTestRequired: true,
      languageLevel: 'B2',
      civicsTestRequired: true,
      dualCitizenshipAllowed: true,
      applicationAuthority:
          'Danish Parliament (Folketinget) via Ministry of Immigration and Integration',
      applicationFee: 'DKK 3,800 (~€510)',
      processingMonths: 24,
      requirements: [
        'Minimum 9 years of continuous legal residence',
        'Valid permanent residence permit',
        'Danish language proficiency at B2 level (Prøve i Dansk 3 or higher)',
        'Pass citizenship test (Indfødsretsprøven) on Danish society, culture, history',
        'Self-supporting for 4.5 of the last 5 years (no social assistance)',
        'No criminal record (detailed point system; any prison sentence may disqualify)',
        'No overdue public debt',
        'Participation in oath/declaration of allegiance ceremony',
        'Must not have been sanctioned under certain laws',
      ],
      exceptions: [
        'Nordic citizens: 2 years residence',
        'Former Danish citizens: reduced requirements by declaration',
        'Stateless persons born in Denmark: 18 years old + entire life in Denmark',
        'Marriage pathway was abolished as a separate fast-track in 2019',
        'Persons aged 65+: language requirement may be reduced to B1 with justification',
      ],
      legalBasis: 'Danish Nationality Act (Indfødsretsloven) + Circular on Naturalization (Cirkulæreskrivelse om naturalisation)',
      renunciationRule: RenunciationRule.notRequired,
      marriagePathway: null,
      additionalNotes: [
        'Denmark allowed dual citizenship since September 2015',
        'Citizenship is granted by Act of Parliament (law listing approved applicants)',
        'One of the strictest naturalization regimes in the EU',
        'The handshake requirement at ceremonies was abolished in 2021',
        'Criminal convictions create waiting periods proportional to sentence length',
      ],
    ),

    // =========================================================================
    // 8. ESTONIA
    // =========================================================================
    const CitizenshipPathway(
      country: 'Estonia',
      countryCode: 'EE',
      residenceYears: 8,
      languageTestRequired: true,
      languageLevel: 'B1',
      civicsTestRequired: true,
      dualCitizenshipAllowed: false,
      applicationAuthority:
          'Police and Border Guard Board (Politsei- ja Piirivalveamet)',
      applicationFee: '€13',
      processingMonths: 6,
      requirements: [
        'Minimum 8 years of legal residence (5 years permanent residence)',
        'Estonian language proficiency at B1 level (certified exam)',
        'Knowledge of Estonian Constitution and Citizenship Act (civics exam)',
        'Proof of legal stable income',
        'Loyalty to the Estonian state',
        'Release from previous citizenship (must renounce before or upon grant)',
        'Must be at least 15 years old',
        'No prior removal from Estonian citizenship',
      ],
      exceptions: [
        'Persons under 15: parents who are Estonian citizens or naturalizing',
        'Persons who completed Estonian-language secondary or higher education: language test waived',
        'Persons with disabilities: language requirements may be adapted',
        'Persons over 65: written part of language test may be waived',
        'Children born in Estonia to stateless parents after Feb 26, 1992: simplified route',
        'Special merit: cultural or scientific contribution to Estonia',
      ],
      legalBasis: 'Citizenship Act (Kodakondsuse seadus), 1995, as amended',
      renunciationRule: RenunciationRule.required,
      marriagePathway: null,
      additionalNotes: [
        'Estonia does not allow dual citizenship for naturalized citizens',
        'Citizens by birth who acquire another citizenship may retain Estonian citizenship',
        'Large stateless (grey passport) population from Soviet era',
        'No marriage-based fast track exists',
        'e-Residency does NOT grant citizenship or physical residency',
        'Very low application fee compared to other EU states',
      ],
    ),

    // =========================================================================
    // 9. FINLAND
    // =========================================================================
    const CitizenshipPathway(
      country: 'Finland',
      countryCode: 'FI',
      residenceYears: 5,
      languageTestRequired: true,
      languageLevel: 'B1',
      civicsTestRequired: false,
      dualCitizenshipAllowed: true,
      applicationAuthority:
          'Finnish Immigration Service (Maahanmuuttovirasto / Migri)',
      applicationFee: '€420 (online) / €550 (paper)',
      processingMonths: 12,
      requirements: [
        'Minimum 5 years of continuous residence (or 7 years total with 2 continuous)',
        'Finnish or Swedish language proficiency at B1 level (YKI 3 or similar)',
        'Established identity (valid passport or other proof)',
        'No significant criminal record',
        'No significant unpaid taxes or maintenance obligations',
        'Ability to provide for oneself (assessed but not strict threshold)',
        'Must be at least 18 years old for independent application',
      ],
      exceptions: [
        '4 years continuous residence if married/cohabiting with Finnish citizen',
        'Nordic citizens: 2 years continuous residence',
        'Former Finnish citizens: 2 years residence',
        'Refugees and stateless persons: 4 years continuous residence',
        'Born in Finland and stateless: simplified',
        'Finnish-born with no other citizenship: age 18-22 simplified declaration',
        'Persons aged 65+: language requirement is flexible',
      ],
      legalBasis: 'Kansalaisuuslaki (Nationality Act) 359/2003, as amended',
      renunciationRule: RenunciationRule.notRequired,
      marriagePathway: MarriagePathway(
        residenceYears: 4,
        marriageYears: 3,
        additionalRequirements: [
          'Cohabiting partners (registered or de facto) also qualify',
          'Language requirement still applies',
        ],
      ),
      additionalNotes: [
        'Finland has allowed dual citizenship since June 1, 2003',
        'Language test accepts either Finnish or Swedish (both official)',
        'Migri online application (Enter Finland) is standard',
        'Processing times vary: straightforward cases ~6-9 months, complex ~18+ months',
        'Children can be included in parent application',
        'Continuous residence allows temporary absences up to ~1 year within the 5-year period',
      ],
    ),

    // =========================================================================
    // 10. FRANCE
    // =========================================================================
    const CitizenshipPathway(
      country: 'France',
      countryCode: 'FR',
      residenceYears: 5,
      languageTestRequired: true,
      languageLevel: 'B1',
      civicsTestRequired: true,
      dualCitizenshipAllowed: true,
      applicationAuthority:
          'Prefecture of residence, final decision by Ministry of Interior (Ministère de l\'Intérieur)',
      applicationFee: '€55 (stamp duty)',
      processingMonths: 18,
      requirements: [
        'Minimum 5 years of habitual legal residence in France',
        'French language proficiency at B1 oral level (TCF, TEF, DELF B1, or equivalent)',
        'Knowledge of French values, history, and culture (interview-based assessment)',
        'Good character, morals, and loyalty to the French Republic',
        'No criminal convictions of 6+ months imprisonment in preceding 10 years',
        'Assimilation into French community (linguistic and social)',
        'Stable and sufficient financial resources',
        'Valid residence permit at time of application',
        'Signing the Charte des droits et devoirs du citoyen français',
      ],
      exceptions: [
        '2 years residence if completed 2 years of higher education in France',
        'No residence requirement if served in French military',
        'No residence requirement for persons of exceptional contribution to France',
        'Marriage to French citizen: 4 years of marriage + community of life (separate procedure by declaration)',
        'Francophone nationals from French-speaking countries: reduced requirements possible',
        'Born in France (jus soli): automatic at 18 if lived in France for 5 years since age 11',
        'Refugees: no need to produce documents from country of origin',
      ],
      legalBasis: 'Code civil, Articles 21-1 to 21-27 (naturalization), Articles 21-2 to 21-6 (marriage)',
      renunciationRule: RenunciationRule.notRequired,
      marriagePathway: MarriagePathway(
        residenceYears: 0,
        marriageYears: 4,
        additionalRequirements: [
          'Uninterrupted community of life (communauté de vie) since marriage',
          'French language B1 oral required',
          '5 years of marriage required if not residing in France continuously for 3+ years',
          'Procedure is by declaration, not discretionary naturalization',
        ],
      ),
      additionalNotes: [
        'France has no restrictions on dual citizenship',
        'Naturalization is a discretionary decision (not a right)',
        'Refusals can be challenged in administrative court',
        'Naturalization ceremony with Marseillaise is required since 2012',
        'Government can oppose naturalization for lack of assimilation',
      ],
    ),

    // =========================================================================
    // 11. GERMANY
    // =========================================================================
    const CitizenshipPathway(
      country: 'Germany',
      countryCode: 'DE',
      residenceYears: 5,
      languageTestRequired: true,
      languageLevel: 'B1',
      civicsTestRequired: true,
      dualCitizenshipAllowed: true,
      applicationAuthority:
          'Local Naturalization Authority (Einbürgerungsbehörde / Ausländerbehörde)',
      applicationFee: '€255 (adults), €51 (minors)',
      processingMonths: 12,
      requirements: [
        'Minimum 5 years of lawful habitual residence in Germany (reduced from 8 in 2024 reform)',
        'German language proficiency at B1 level (Zertifikat Deutsch or equivalent)',
        'Pass naturalization test (Einbürgerungstest) on German legal/social order, history',
        'Ability to support oneself and dependents without social assistance',
        'No criminal convictions (minor offenses may be disregarded)',
        'Commitment to the free democratic basic order (freiheitliche demokratische Grundordnung)',
        'Valid settlement permit (Niederlassungserlaubnis) or equivalent residence title',
        'Renunciation of previous citizenship (with broad exceptions since 2024)',
      ],
      exceptions: [
        '3 years residence with special integration achievements (C1 German, civic engagement)',
        'EU/EEA/Swiss citizens and nationals of countries not allowing renunciation: dual citizenship kept',
        'Since June 2024 reform: dual citizenship generally permitted for all nationalities',
        'Spouses/partners of German citizens: 3-4 years residence + 2 years marriage',
        'Former Germans: simplified re-naturalization',
        'Victims of Nazi persecution (Art. 116 GG): right to restoration of citizenship',
        'Recognized refugees: 6 years residence, simplified documentation',
      ],
      legalBasis: 'Staatsangehörigkeitsgesetz (StAG), as reformed June 27, 2024',
      renunciationRule: RenunciationRule.notRequired,
      marriagePathway: MarriagePathway(
        residenceYears: 3,
        marriageYears: 2,
        additionalRequirements: [
          'B1 German still required',
          'Naturalization test still required',
          'Must be living together',
        ],
      ),
      additionalNotes: [
        'Major reform in June 2024: residence reduced from 8 to 5 years, dual citizenship allowed for all',
        'The 2024 reform is the most significant change to German citizenship law in decades',
        'Jus soli since 2000: children born in Germany to qualifying foreign parents get citizenship',
        'Oath of allegiance ceremony is mandatory',
        'Special rules for former guest workers (Gastarbeiter generation)',
      ],
    ),

    // =========================================================================
    // 12. GREECE
    // =========================================================================
    const CitizenshipPathway(
      country: 'Greece',
      countryCode: 'GR',
      residenceYears: 7,
      languageTestRequired: true,
      languageLevel: 'B1',
      civicsTestRequired: true,
      dualCitizenshipAllowed: true,
      applicationAuthority:
          'Decentralized Administration (Αποκεντρωμένη Διοίκηση), General Secretary',
      applicationFee: '€700',
      processingMonths: 24,
      requirements: [
        'Minimum 7 years of continuous legal residence in Greece',
        'Greek language proficiency at B1 level (certified exam by official center)',
        'Pass interview/test on Greek history, geography, culture, political institutions',
        'No criminal convictions incompatible with Greek citizenship',
        'No deportation orders',
        'Participation in Greek economic and social life',
        'Must be at least 18 years old',
        'Valid residence permit',
      ],
      exceptions: [
        '3 years residence if married to a Greek citizen and have a child together',
        'Persons of Greek origin/descent (homogeneis): simplified procedure, minimal residence',
        'Recognized refugees and stateless persons: reduced to 3 years residence',
        'Born in Greece + 6 years of Greek schooling: declaration at age 18-21',
        'Persons who served in Greek armed forces',
        'EU citizens: 7 years still required (no reduction)',
        'Ethnic Greeks from former Soviet Union, Albania, Turkey: special repatriation program',
      ],
      legalBasis: 'Greek Citizenship Code (Κώδικας Ελληνικής Ιθαγένειας), Law 3284/2004 as amended by Laws 3838/2010, 4332/2015, 4735/2020',
      renunciationRule: RenunciationRule.notRequired,
      marriagePathway: MarriagePathway(
        residenceYears: 3,
        marriageYears: 3,
        additionalRequirements: [
          'Must have a child with the Greek spouse',
          'If no child: 7 years residence still applies',
          'Language and civics tests required',
        ],
      ),
      additionalNotes: [
        'Greece allows dual citizenship without restrictions',
        'Processing is notoriously slow (2-4 years in practice)',
        'Naturalization decisions are at the discretion of the Minister',
        'Large ethnic Greek diaspora has facilitated access',
        'Second generation (born in Greece) now has clearer pathways since 2015/2020 reforms',
      ],
    ),

    // =========================================================================
    // 13. HUNGARY
    // =========================================================================
    const CitizenshipPathway(
      country: 'Hungary',
      countryCode: 'HU',
      residenceYears: 8,
      languageTestRequired: true,
      languageLevel: 'B1',
      civicsTestRequired: true,
      dualCitizenshipAllowed: true,
      applicationAuthority:
          'Budapest and County Government Offices (Fővárosi és Megyei Kormányhivatalok)',
      applicationFee: 'Free (no fee for standard naturalization)',
      processingMonths: 6,
      requirements: [
        'Minimum 8 years of continuous lawful residence in Hungary',
        'Hungarian language proficiency at B1 (assessed via interview)',
        'Pass civics examination on Hungarian constitution and basic civic knowledge',
        'Clean criminal record (no pending criminal proceedings)',
        'Stable livelihood and housing in Hungary',
        'Naturalization must not be detrimental to Hungarian national security',
        'Must be at least 18 years old',
      ],
      exceptions: [
        '5 years residence if married to Hungarian citizen for 3+ years, or has minor Hungarian child',
        '5 years if adopted by Hungarian citizen',
        '5 years for recognized refugees',
        '3 years if born in Hungary',
        'Ethnic Hungarians (simplified naturalization since 2011): no residence requirement, Hungarian language + ancestry',
        'Former Hungarian citizens: 3 years residence',
        'Persons of outstanding merit: presidential decision, no minimum requirements',
      ],
      legalBasis: 'Act LV of 1993 on Hungarian Citizenship (1993. évi LV. törvény a magyar állampolgárságról), as amended 2011',
      renunciationRule: RenunciationRule.notRequired,
      marriagePathway: MarriagePathway(
        residenceYears: 5,
        marriageYears: 3,
        additionalRequirements: [
          'Language and civics requirements still apply',
          'Both spouses must be living together',
        ],
      ),
      additionalNotes: [
        'Hungary allows dual citizenship and actively promotes it for ethnic Hungarians',
        'Since 2011, over 1 million ethnic Hungarians (mainly from Romania, Serbia, Ukraine, Slovakia) received citizenship',
        'Simplified naturalization for ethnic Hungarians requires no residence, only language and ancestry',
        'Naturalization is free of charge',
        'Very fast processing (often 2-3 months for simplified naturalization)',
      ],
    ),

    // =========================================================================
    // 14. IRELAND
    // =========================================================================
    const CitizenshipPathway(
      country: 'Ireland',
      countryCode: 'IE',
      residenceYears: 5,
      languageTestRequired: false,
      languageLevel: null,
      civicsTestRequired: false,
      dualCitizenshipAllowed: true,
      applicationAuthority:
          'Minister for Justice, via Citizenship Division (Immigration Service Delivery)',
      applicationFee: '€175 (application) + €950 (certification fee)',
      processingMonths: 23,
      requirements: [
        'Minimum 5 years (60 months) of reckonable residence in Ireland within last 9 years',
        'Including 1 continuous year of residence immediately before application',
        'Good character (Garda vetting / police clearance)',
        'Intention to continue residing in Ireland after naturalization',
        'Declaration of fidelity to the nation and loyalty to the State (at citizenship ceremony)',
        'Must be at least 18 years old (minors through separate application by parent)',
        'No language or civics test required',
      ],
      exceptions: [
        '3 years residence if married to or civil partner of an Irish citizen',
        'Irish descent/associations: reduced requirements at discretion of Minister',
        'Refugees: pre-recognition residence may be partially counted',
        'Stateless persons: Minister has discretion to waive requirements',
        'Children born in Ireland before 2005: automatic citizenship at birth',
        'Children born in Ireland after 2005: parents must have 3 years legal residence',
        'Foreign Births Register: citizenship by descent (grandparent born in Ireland)',
      ],
      legalBasis: 'Irish Nationality and Citizenship Act 1956, as amended (2004 referendum, 2010, 2024 amendments)',
      renunciationRule: RenunciationRule.notRequired,
      marriagePathway: MarriagePathway(
        residenceYears: 3,
        marriageYears: 3,
        additionalRequirements: [
          'Must be living together as married couple',
          'No additional tests required beyond standard',
        ],
      ),
      additionalNotes: [
        'Ireland fully allows dual/multiple citizenship',
        'No language or civics test whatsoever - unique in the EU',
        'Naturalization is entirely at the discretion of the Minister for Justice',
        'Processing backlog is significant (often 2+ years)',
        'Citizenship ceremony is mandatory since 2011',
        'Strong jus sanguinis: Irish citizenship by descent through grandparents',
      ],
    ),

    // =========================================================================
    // 15. ITALY
    // =========================================================================
    const CitizenshipPathway(
      country: 'Italy',
      countryCode: 'IT',
      residenceYears: 10,
      languageTestRequired: true,
      languageLevel: 'B1',
      civicsTestRequired: false,
      dualCitizenshipAllowed: true,
      applicationAuthority:
          'Ministry of Interior (Ministero dell\'Interno), Prefettura',
      applicationFee: '€250',
      processingMonths: 24,
      requirements: [
        'Minimum 10 years of continuous legal residence in Italy (4 years for EU citizens)',
        'Italian language proficiency at B1 level (since December 2018, Law 132/2018)',
        'Sufficient income (minimum ~€8,263.31/year plus supplements for dependents)',
        'No criminal convictions for serious offenses',
        'No security threats',
        'Valid residence permit throughout the period',
        'Tax compliance (no outstanding tax debts)',
        'Must be at least 18 years old',
      ],
      exceptions: [
        '4 years residence for EU citizens',
        '5 years residence for stateless persons and recognized refugees',
        '7 years for adopted foreign children',
        '3 years residence for persons born in Italy',
        'Marriage to Italian citizen: 2 years residence in Italy (or 3 years abroad) + still married',
        'Citizenship jure sanguinis: unlimited generational descent through Italian ancestor (no residence needed)',
        'Special merit: by Presidential Decree for extraordinary service to Italy',
      ],
      legalBasis: 'Law 91/1992 (Legge 5 febbraio 1992, n. 91), as amended by Law 132/2018',
      renunciationRule: RenunciationRule.notRequired,
      marriagePathway: MarriagePathway(
        residenceYears: 2,
        marriageYears: 2,
        additionalRequirements: [
          'If residing abroad: 3 years of marriage (halved if children)',
          'If residing in Italy: 2 years of marriage (halved if children)',
          'B1 language requirement applies since 2018',
          'Marriage must still be valid at time of decision',
        ],
      ),
      additionalNotes: [
        'Italy fully allows dual/multiple citizenship',
        'Jure sanguinis citizenship (by descent) is extremely generous - no generational limit',
        'Many Americans, Argentinians, Brazilians claim Italian citizenship through ancestors',
        'Processing is very slow: legally should be 24 months but often 3-4 years',
        'Applicants can sue (ricorso) if decision exceeds the legal deadline',
        'B1 language requirement added only in 2018',
      ],
    ),

    // =========================================================================
    // 16. LATVIA
    // =========================================================================
    const CitizenshipPathway(
      country: 'Latvia',
      countryCode: 'LV',
      residenceYears: 5,
      languageTestRequired: true,
      languageLevel: 'B1',
      civicsTestRequired: true,
      dualCitizenshipAllowed: true,
      applicationAuthority:
          'Office of Citizenship and Migration Affairs (Pilsonības un migrācijas lietu pārvalde)',
      applicationFee: '€28.46',
      processingMonths: 12,
      requirements: [
        'Minimum 5 years of permanent residence in Latvia',
        'Latvian language proficiency at B1 level (centralized exam)',
        'Knowledge of Latvian Constitution (Satversme), national anthem, and basic history (civics exam)',
        'Legal source of income',
        'Oath of loyalty to the Republic of Latvia',
        'Renunciation of previous citizenship (with exceptions)',
        'No criminal record in Latvia',
        'Must be at least 15 years old',
      ],
      exceptions: [
        'Latvian non-citizens (nepilsoņi): 5 years residence, same process',
        'Marriage to Latvian citizen does NOT reduce residence requirement',
        'Former Latvian citizens and their descendants: registration (not naturalization)',
        'Children born in Latvia after August 21, 1991 to non-citizens: entitled to citizenship',
        'Persons who completed education in Latvian language: language exam waived',
        'Persons over 65: simplified language exam (oral only)',
        'EU/EEA/NATO country citizens, Swiss, Australian, Brazilian, selected others: dual citizenship allowed since 2013',
      ],
      legalBasis: 'Citizenship Law (Pilsonības likums), 1994, as amended 2013',
      renunciationRule: RenunciationRule.requiredWithExceptions,
      marriagePathway: null,
      additionalNotes: [
        'Latvia allows dual citizenship only with specific countries (EU, EEA, NATO, Australia, Brazil, and others listed in law)',
        'With other countries, renunciation is still required',
        'Large non-citizen (nepilsoņi) population from Soviet era: similar to Estonian grey passports',
        'No marriage-based fast track - marriage does not reduce residence years',
        'Relatively affordable fees',
      ],
    ),

    // =========================================================================
    // 17. LITHUANIA
    // =========================================================================
    const CitizenshipPathway(
      country: 'Lithuania',
      countryCode: 'LT',
      residenceYears: 10,
      languageTestRequired: true,
      languageLevel: 'B1',
      civicsTestRequired: true,
      dualCitizenshipAllowed: false,
      applicationAuthority:
          'Migration Department under the Ministry of Interior (Migracijos departamentas)',
      applicationFee: '€41',
      processingMonths: 6,
      requirements: [
        'Minimum 10 years of continuous lawful permanent residence',
        'Lithuanian language proficiency at B1 level (state exam)',
        'Pass test on Lithuanian Constitution fundamentals (civics exam)',
        'Legal source of income',
        'Renunciation of previous citizenship (limited exceptions)',
        'Must be stateless or willing to renounce',
        'No criminal convictions in Lithuania',
        'Must be at least 18 years old',
      ],
      exceptions: [
        '7 years residence if married to Lithuanian citizen for 3+ years',
        'Lithuanian origin (descent): simplified restoration procedure, no residence requirement',
        'Persons who had Lithuanian citizenship before June 15, 1940 and their descendants: restoration',
        'Exceptional merit to Lithuania: presidential grant, no minimum requirements',
        'Recognized refugees: residence may be reduced',
        'Children born in Lithuania to permanent residents',
        'Dual citizenship only for: citizens by birth, persons of Lithuanian descent, certain diaspora',
      ],
      legalBasis: 'Law on Citizenship of the Republic of Lithuania (Lietuvos Respublikos pilietybės įstatymas), 2010, as amended',
      renunciationRule: RenunciationRule.required,
      marriagePathway: MarriagePathway(
        residenceYears: 7,
        marriageYears: 3,
        additionalRequirements: [
          'Must have continuous permanent residence',
          'Language and civics tests still required',
        ],
      ),
      additionalNotes: [
        'Lithuania is very restrictive on dual citizenship',
        'Constitutional Court ruled dual citizenship cannot be the general rule',
        'Dual citizenship allowed only for citizens by birth/descent (not naturalized)',
        'Referendum on dual citizenship in 2019 failed to reach quorum',
        'Lithuanian diaspora (especially in USA, UK) actively seeking dual citizenship reform',
        '2024 constitutional amendment discussions ongoing',
      ],
    ),

    // =========================================================================
    // 18. LUXEMBOURG
    // =========================================================================
    const CitizenshipPathway(
      country: 'Luxembourg',
      countryCode: 'LU',
      residenceYears: 5,
      languageTestRequired: true,
      languageLevel: 'A2/B1',
      civicsTestRequired: true,
      dualCitizenshipAllowed: true,
      applicationAuthority:
          'Ministry of Justice (Ministère de la Justice)',
      applicationFee: 'Free',
      processingMonths: 8,
      requirements: [
        'Minimum 5 years of continuous legal residence (last year immediately before application)',
        'Luxembourgish language: A2 spoken (oral comprehension) + B1 spoken (oral production) evaluated by Institut National des Langues',
        'Participation in "Vivre ensemble au Grand-Duché de Luxembourg" civic course (24 hours) or equivalent',
        'No criminal convictions resulting in a prison sentence of 12+ months',
        'Must be at least 18 years old',
        'Valid residence permit',
      ],
      exceptions: [
        'Marriage to Luxembourgish citizen: 3 years residence + 3 years marriage',
        'Born in Luxembourg: 1 year residence at age 18 if born in Luxembourg and resided 5 years total',
        'Former Luxembourgish citizens: recovery by declaration',
        'Persons over 75: language requirement reduced',
        'Descendants of Luxembourgish ancestors (before 1900): citizenship by recovery',
        'Persons who completed education in Luxembourgish: language requirement waived',
        'Stateless persons: 5 years residence',
      ],
      legalBasis: 'Loi du 8 mars 2017 sur la nationalité luxembourgeoise (Law of March 8, 2017)',
      renunciationRule: RenunciationRule.notRequired,
      marriagePathway: MarriagePathway(
        residenceYears: 3,
        marriageYears: 3,
        additionalRequirements: [
          'Luxembourgish language requirements still apply',
          'Civic course still required',
        ],
      ),
      additionalNotes: [
        'Luxembourg allows dual citizenship since 2009',
        'The 2017 law significantly liberalized access to citizenship',
        'Luxembourgish language is the main barrier (minority language, ~400,000 speakers)',
        'No application fee - one of the few EU countries with free naturalization',
        'Nearly 50% of Luxembourg residents are foreign nationals',
        'Large recovery program for descendants of Luxembourgish emigrants',
      ],
    ),

    // =========================================================================
    // 19. MALTA
    // =========================================================================
    const CitizenshipPathway(
      country: 'Malta',
      countryCode: 'MT',
      residenceYears: 5,
      languageTestRequired: true,
      languageLevel: 'A2',
      civicsTestRequired: false,
      dualCitizenshipAllowed: true,
      applicationAuthority:
          'Director of Citizenship, Department of Citizenship and Expatriate Affairs (Identity Malta)',
      applicationFee: '€500',
      processingMonths: 12,
      requirements: [
        'Minimum 5 years residence in the 12 years preceding application, of which the last 12 months must be continuous',
        'Maltese or English language proficiency at A2 level (both are official languages)',
        'Good character and conduct',
        'Adequate knowledge of Maltese or English',
        'Must be a suitable citizen',
        'Must be at least 18 years old',
      ],
      exceptions: [
        'Marriage to Maltese citizen: 5 years of marriage (if abroad) or 5 years residence + marriage',
        'Maltese descent: registration if parent/grandparent was born in Malta',
        'Exceptional Service: citizenship by naturalization for outstanding merit (e.g., in sports, culture)',
        'Maltese Citizenship by Investment (MEIN Program): €750,000+ contribution, 12 months residence (or 36 months with reduced contribution)',
        'Commonwealth citizens with Maltese connections: special provisions',
        'Former Maltese citizens: simplified re-acquisition',
      ],
      legalBasis: 'Maltese Citizenship Act (Chapter 188 of the Laws of Malta), 1964, as amended',
      renunciationRule: RenunciationRule.notRequired,
      marriagePathway: MarriagePathway(
        residenceYears: 0,
        marriageYears: 5,
        additionalRequirements: [
          'Can be applied even if couple resides abroad',
          'Must still be married at time of decision',
          'Language proficiency required',
        ],
      ),
      additionalNotes: [
        'Malta allows dual citizenship fully',
        'The Maltese Exceptional Investor Naturalization (MEIN) replaces old IIP program',
        'MEIN has been scrutinized by EU Commission',
        'Both Maltese and English accepted for language requirement',
        'One of the smallest EU countries, hence strict scrutiny despite relatively liberal law',
      ],
    ),

    // =========================================================================
    // 20. NETHERLANDS
    // =========================================================================
    const CitizenshipPathway(
      country: 'Netherlands',
      countryCode: 'NL',
      residenceYears: 5,
      languageTestRequired: true,
      languageLevel: 'A2',
      civicsTestRequired: true,
      dualCitizenshipAllowed: false,
      applicationAuthority:
          'Immigration and Naturalisation Service (IND - Immigratie- en Naturalisatiedienst)',
      applicationFee: '€1,011',
      processingMonths: 12,
      requirements: [
        'Minimum 5 years of continuous legal residence with valid residence permit',
        'Pass civic integration exam (inburgeringsexamen) at A2 level (reading, listening, writing, speaking, KNM, Orientation Dutch Labour Market)',
        'Renunciation of previous citizenship (with significant exceptions)',
        'No criminal convictions in preceding 4 years (or 5 years for sentences)',
        'Must be at least 18 years old',
        'Valid residence permit (not provisional)',
        'No ongoing criminal investigation',
      ],
      exceptions: [
        'Marriage/partnership with Dutch citizen: 3 years continuous residence + 3 years of relationship',
        'Surinamese and former Dutch nationals: simplified',
        'Nationals who cannot renounce (recognized refugees, nationals of countries that forbid renunciation): dual citizenship allowed',
        'Spouses who would lose social benefits from renunciation: exemption possible',
        'Born in Netherlands and resident since birth: option procedure at age 18',
        'Second generation born in Netherlands: option procedure',
        'Persons aged 65+: civic integration partially waived',
      ],
      legalBasis: 'Rijkswet op het Nederlanderschap (Netherlands Nationality Act), 2003, as amended',
      renunciationRule: RenunciationRule.requiredWithExceptions,
      marriagePathway: MarriagePathway(
        residenceYears: 3,
        marriageYears: 3,
        additionalRequirements: [
          'Civic integration exam still required',
          'Must be cohabiting in Netherlands',
          'Renunciation requirements still apply (with exceptions)',
        ],
      ),
      additionalNotes: [
        'Netherlands generally requires renunciation but with many exceptions in practice',
        'The coalition agreement in 2023-2024 discussed allowing dual citizenship more broadly but no reform yet as of 2026',
        'Civic integration exam is the main hurdle (pass rate issues)',
        'Option procedure (optie) is faster and cheaper for eligible persons (€201)',
        'High fees compared to most EU countries',
        'Moroccan nationals in practice retain dual citizenship (Morocco does not allow renunciation)',
      ],
    ),

    // =========================================================================
    // 21. POLAND
    // =========================================================================
    const CitizenshipPathway(
      country: 'Poland',
      countryCode: 'PL',
      residenceYears: 3,
      languageTestRequired: true,
      languageLevel: 'B1',
      civicsTestRequired: false,
      dualCitizenshipAllowed: true,
      applicationAuthority:
          'Voivode (Wojewoda) for recognition; President for grant of citizenship',
      applicationFee: 'PLN 219 (~€50)',
      processingMonths: 6,
      requirements: [
        'Minimum 3 years of continuous residence on settlement permit (zezwolenie na pobyt stały)',
        'Stable and regular income in Poland',
        'Legal title to accommodation',
        'Polish language proficiency at B1 level (certified exam or Polish school diploma)',
        'No threat to state security or public order',
        'Must be at least 18 years old',
      ],
      exceptions: [
        '2 years residence if married to a Polish citizen for 3+ years',
        '10 years residence on any legal basis (no settlement permit required)',
        '2 years on settlement permit if recognized refugee',
        'Polish descent (Karta Polaka holders): 1 year residence on settlement permit',
        'Presidential grant: no requirements at all (the President can grant citizenship to anyone)',
        'Citizenship by descent: Polish citizenship passes to children automatically',
        'Restored citizenship for persons who lost it under communist-era laws',
      ],
      legalBasis: 'Act of April 2, 2009 on Polish Citizenship (Ustawa o obywatelstwie polskim)',
      renunciationRule: RenunciationRule.notRequired,
      marriagePathway: MarriagePathway(
        residenceYears: 2,
        marriageYears: 3,
        additionalRequirements: [
          'Must hold settlement permit',
          'B1 Polish required',
          'Must be cohabiting',
        ],
      ),
      additionalNotes: [
        'Poland fully tolerates dual citizenship (no prohibition, no requirement to renounce)',
        'Two parallel paths: recognition by Voivode (standard) and grant by the President (discretionary)',
        'Presidential grant has no conditions and cannot be appealed (purely political decision)',
        'Karta Polaka (Card of the Pole): gives ethnic Poles special access, mainly from ex-Soviet countries',
        'One of the shortest residence requirements in the EU (3 years)',
        'Citizenship by descent has no generational limit',
      ],
    ),

    // =========================================================================
    // 22. PORTUGAL
    // =========================================================================
    const CitizenshipPathway(
      country: 'Portugal',
      countryCode: 'PT',
      residenceYears: 5,
      languageTestRequired: true,
      languageLevel: 'A2',
      civicsTestRequired: false,
      dualCitizenshipAllowed: true,
      applicationAuthority:
          'Central Registry Office (Conservatória dos Registos Centrais) and IRN (Institute of Registries and Notaries)',
      applicationFee: '€175 (stamp duty) + €25 (certificate)',
      processingMonths: 12,
      requirements: [
        'Minimum 5 years of legal residence in Portugal',
        'Portuguese language proficiency at A2 level (CIPLE exam or equivalent)',
        'No criminal conviction with 3+ years prison sentence',
        'Effective connection to the Portuguese national community',
        'Must be at least 18 years old',
        'Valid residence permit',
      ],
      exceptions: [
        'Marriage/partnership with Portuguese citizen: 3 years of marriage (no residence required if married to Portuguese)',
        'Children born in Portugal: citizenship if parent has been legal resident for 1+ years at time of birth (since 2020 reform)',
        'Portuguese descent (Sephardic Jews, descendants of Portuguese nationals): nationality by origin',
        'Citizens of Portuguese-speaking countries (CPLP: Brazil, Angola, Mozambique, Cape Verde, etc.): A2 language assumed, community ties easier to prove',
        'Minor children of naturalized parents: included automatically',
        'Golden Visa holders: 5 years residence (program modified in 2023, real estate investment removed)',
      ],
      legalBasis: 'Lei da Nacionalidade (Law No. 37/81 of October 3, 1981), as amended by Organic Law No. 2/2020',
      renunciationRule: RenunciationRule.notRequired,
      marriagePathway: MarriagePathway(
        residenceYears: 0,
        marriageYears: 3,
        additionalRequirements: [
          'Can apply from abroad',
          'A2 Portuguese required',
          'Effective connection to Portuguese community',
          'De facto unions (união de facto) also qualify if recognized for 3+ years',
        ],
      ),
      additionalNotes: [
        'Portugal fully allows dual/multiple citizenship',
        'One of the most liberal citizenship regimes in the EU',
        'A2 language requirement is the lowest in the EU (very basic level)',
        'Sephardic Jewish descent pathway available since 2015 (tightened in 2022)',
        'Golden Visa program modified: no more real estate investment option since Oct 2023',
        'Portuguese-speaking country nationals have significant advantages',
        'Processing has improved but backlogs exist',
      ],
    ),

    // =========================================================================
    // 23. ROMANIA
    // =========================================================================
    const CitizenshipPathway(
      country: 'Romania',
      countryCode: 'RO',
      residenceYears: 8,
      languageTestRequired: true,
      languageLevel: 'B1',
      civicsTestRequired: true,
      dualCitizenshipAllowed: true,
      applicationAuthority:
          'National Authority for Citizenship (Autoritatea Națională pentru Cetățenie - ANC)',
      applicationFee: 'RON 103 (~€21)',
      processingMonths: 12,
      requirements: [
        'Minimum 8 years of continuous legal residence in Romania (5 years if married to Romanian)',
        'Romanian language proficiency at B1 (interview assessment)',
        'Basic knowledge of Romanian culture, history, and Constitution (civics test during interview)',
        'Good conduct and no threat to national security',
        'Adequate means of subsistence',
        'No prior conviction for acts incompatible with Romanian citizenship',
        'Must be at least 18 years old',
        'Loyalty to the Romanian state',
      ],
      exceptions: [
        '5 years residence if married to Romanian citizen',
        'Romanian descent/origin: no residence requirement (Article 11 redobândire/recovery)',
        'Former Romanian citizens (and descendants up to 3rd generation): citizenship recovery by application',
        'Internationally known persons or persons of interest to Romania: reduced requirements',
        'EU citizens: 4 years residence',
        'Refugees: 4 years residence',
        'Investors: 4 years residence',
        'Children adopted by Romanian citizens: automatic',
      ],
      legalBasis: 'Law No. 21/1991 on Romanian Citizenship (Legea cetățeniei române), as amended by Law 248/2024',
      renunciationRule: RenunciationRule.notRequired,
      marriagePathway: MarriagePathway(
        residenceYears: 5,
        marriageYears: 5,
        additionalRequirements: [
          'Must have continuous legal residence',
          'Language interview still required',
        ],
      ),
      additionalNotes: [
        'Romania fully allows dual citizenship',
        'Massive citizenship recovery program for Moldovans and diaspora from former Romanian territories',
        'Over 1 million Moldovan citizens have obtained Romanian citizenship',
        'Very low fees',
        'Interview-based language and civics assessment (no written exam)',
        'Processing improved in recent years but backlogs remain for recovery applications',
      ],
    ),

    // =========================================================================
    // 24. SLOVAKIA
    // =========================================================================
    const CitizenshipPathway(
      country: 'Slovakia',
      countryCode: 'SK',
      residenceYears: 8,
      languageTestRequired: true,
      languageLevel: 'B1',
      civicsTestRequired: true,
      dualCitizenshipAllowed: false,
      applicationAuthority:
          'District Office in the seat of the region (Okresný úrad v sídle kraja), Ministry of Interior',
      applicationFee: '€700',
      processingMonths: 24,
      requirements: [
        'Minimum 8 years of continuous permanent residence in Slovakia',
        'Slovak language proficiency at B1 level (evaluated in oral interview)',
        'General knowledge of Slovakia (history, geography, civics - tested in interview)',
        'Clean criminal record (no conviction in preceding 5 years)',
        'No deportation/expulsion proceedings',
        'Fulfillment of obligations to state (taxes, social security, military)',
        'Must be at least 18 years old',
        'No threat to public order or security',
      ],
      exceptions: [
        '5 years residence if married to Slovak citizen for 5+ years and living in Slovakia',
        'Slovak descent or former Slovak citizens: 3 years residence',
        'Persons born in Slovakia: 3 years residence (must have been continuously resident)',
        'Person who significantly contributed to Slovakia: no minimum residence (ministerial decision)',
        'Stateless persons: 3 years residence',
        'Former Czechoslovak citizens: 3 years residence',
        'Minor children of Slovak citizens',
      ],
      legalBasis: 'Act No. 40/1993 Coll. on Citizenship of the Slovak Republic (Zákon o štátnom občianstve), as amended 2010, 2022',
      renunciationRule: RenunciationRule.required,
      marriagePathway: MarriagePathway(
        residenceYears: 5,
        marriageYears: 5,
        additionalRequirements: [
          'Must be continuously living in Slovakia',
          'Slovak language interview required',
          'Must renounce previous citizenship',
        ],
      ),
      additionalNotes: [
        'Slovakia strictly prohibits dual citizenship since 2010 amendment',
        'The 2010 law was enacted in response to Hungary\'s simplified naturalization for ethnic Hungarians',
        'Slovak citizens who acquire another nationality automatically LOSE Slovak citizenship',
        'This has caused significant problems for Slovak diaspora',
        'Some relaxation for persons who acquired foreign citizenship by birth or marriage (2022 amendment)',
        'One of the strictest dual citizenship regimes in the EU alongside Austria and Estonia',
      ],
    ),

    // =========================================================================
    // 25. SLOVENIA
    // =========================================================================
    const CitizenshipPathway(
      country: 'Slovenia',
      countryCode: 'SI',
      residenceYears: 10,
      languageTestRequired: true,
      languageLevel: 'A2',
      civicsTestRequired: false,
      dualCitizenshipAllowed: true,
      applicationAuthority:
          'Administrative Unit (Upravna enota) of place of residence, decided by Ministry of Interior',
      applicationFee: '€180',
      processingMonths: 12,
      requirements: [
        'Minimum 10 years of legal residence (5 years continuous immediately before application)',
        'Slovenian language proficiency at A2 level (certified exam or Slovenian school completion)',
        'Renunciation of previous citizenship (release obtained or proven impossible)',
        'No pending criminal proceedings, no prison sentence in preceding years',
        'Guaranteed permanent residence in Slovenia',
        'Financial means to support self and family',
        'No threat to public order, security, or defense',
        'Must be at least 18 years old',
        'Actual permanent residence in Slovenia',
      ],
      exceptions: [
        'Marriage to Slovenian citizen: 3 years of marriage + 1 year continuous residence (with renunciation waived)',
        'Born in Slovenia: 10 years still required but continuous period shorter',
        'Slovenian descent: simplified (1 year residence after Slovenian origin confirmed)',
        'Former Yugoslav citizens who were erased from registry (izbrisani): special access',
        'Stateless persons: 5 years continuous residence',
        'Persons of benefit to Slovenia: no minimum residence (government decision)',
        'EU Blue Card holders: follows standard permanent residence path',
      ],
      legalBasis: 'Citizenship of the Republic of Slovenia Act (Zakon o državljanstvu Republike Slovenije - ZDRS), 1991, as amended',
      renunciationRule: RenunciationRule.requiredWithExceptions,
      marriagePathway: MarriagePathway(
        residenceYears: 1,
        marriageYears: 3,
        additionalRequirements: [
          'Renunciation of previous citizenship is WAIVED for marriage-based naturalization',
          'A2 Slovenian required',
          'Must be continuously residing in Slovenia for 1 year',
        ],
      ),
      additionalNotes: [
        'Slovenia generally requires renunciation but waives it for spouses of Slovenian citizens',
        'This creates a de facto dual citizenship regime for many applicants',
        'The "erased" (izbrisani) issue from 1992 remains politically sensitive',
        '10 years is one of the longest standard residence requirements in the EU',
        'Slovenian language has A2 requirement - lower than many EU states',
      ],
    ),

    // =========================================================================
    // 26. SPAIN
    // =========================================================================
    const CitizenshipPathway(
      country: 'Spain',
      countryCode: 'ES',
      residenceYears: 10,
      languageTestRequired: true,
      languageLevel: 'A2',
      civicsTestRequired: true,
      dualCitizenshipAllowed: false,
      applicationAuthority:
          'Ministry of Justice (Ministerio de Justicia), Civil Registry',
      applicationFee: '€104',
      processingMonths: 24,
      requirements: [
        'Minimum 10 years of continuous legal residence in Spain',
        'Spanish language proficiency at A2 level (DELE A2 or CCSE-accredited center)',
        'Pass CCSE exam (Conocimientos Constitucionales y Socioculturales de España)',
        'Good civic conduct (no criminal record)',
        'Sufficient integration into Spanish society',
        'Renunciation of previous nationality (with exceptions)',
        'Must be at least 18 years old',
        'Valid residence permit (legal and continuous)',
      ],
      exceptions: [
        '5 years for refugees and stateless persons',
        '2 years for citizens of Latin American countries, Andorra, Philippines, Equatorial Guinea, Portugal, and Sephardic descent',
        '1 year if born in Spain, married to Spanish national for 1 year, born to Spanish parent, subject to guardianship of Spanish institution, or widow(er) of Spanish national',
        'Persons of Sephardic Jewish descent: 2 years residence (law modified in 2019)',
        'Dual citizenship by treaty: Latin American countries, Andorra, Philippines, Equatorial Guinea, Portugal',
      ],
      legalBasis: 'Código Civil, Articles 17-26 (Civil Code provisions on nationality), revised by Laws 36/2002, 12/2015, 20/2022',
      renunciationRule: RenunciationRule.requiredWithExceptions,
      marriagePathway: MarriagePathway(
        residenceYears: 1,
        marriageYears: 1,
        additionalRequirements: [
          'Must be cohabiting in Spain',
          'DELE A2 and CCSE exam still required',
          'Among the fastest marriage-based pathways in Europe',
        ],
      ),
      additionalNotes: [
        'Spain requires renunciation EXCEPT for nationals of Latin American countries, Philippines, Equatorial Guinea, Andorra, and Portugal (bilateral treaties)',
        'In practice, Spain does not verify whether renunciation was actually completed for many nationalities',
        'The 2-year rule for Latin American nationals makes Spain very popular',
        'Marriage pathway (1 year) is one of the fastest in the EU',
        'Democratic Memory Law (2022): facilitated nationality for descendants of Spanish Civil War exiles',
        'Processing backlogs: can take 2-3 years despite the legal deadline of 1 year',
        'CCSE exam pass rate is relatively high (~95%)',
      ],
    ),

    // =========================================================================
    // 27. SWEDEN
    // =========================================================================
    const CitizenshipPathway(
      country: 'Sweden',
      countryCode: 'SE',
      residenceYears: 5,
      languageTestRequired: false,
      languageLevel: null,
      civicsTestRequired: false,
      dualCitizenshipAllowed: true,
      applicationAuthority:
          'Swedish Migration Agency (Migrationsverket)',
      applicationFee: 'SEK 1,500 (~€135)',
      processingMonths: 15,
      requirements: [
        'Minimum 5 years of continuous legal residence in Sweden (habitual domicile)',
        'Proof of identity (established identity)',
        'Good conduct (no serious criminal convictions; waiting periods apply)',
        'Permanent residence permit or right of residence (EU citizens)',
        'Must be at least 18 years old for independent application',
        'Continuous residence (hemvist) - brief absences allowed',
      ],
      exceptions: [
        '4 years residence for recognized refugees and stateless persons',
        '3 years if married to or cohabiting with Swedish citizen (+ 2 years together)',
        '2 years for Nordic citizens (Denmark, Finland, Iceland, Norway)',
        'Former Swedish citizens: 2 years residence',
        'Persons aged 18-21 with 5 years continuous residence since age 13: simplified',
        'Children: notification procedure for those under 18 with residence',
        'No maximum age limit',
      ],
      legalBasis: 'Swedish Citizenship Act (Lag om svenskt medborgarskap, SFS 2001:82), as amended',
      renunciationRule: RenunciationRule.notRequired,
      marriagePathway: MarriagePathway(
        residenceYears: 3,
        marriageYears: 2,
        additionalRequirements: [
          'Must be living together (sambo)',
          'Cohabiting partners (sambo) treated equally to married spouses',
          'No language or civics test required',
        ],
      ),
      additionalNotes: [
        'Sweden has allowed dual citizenship since July 1, 2001',
        'Sweden has NO language test and NO civics test for citizenship - unique in the EU',
        'The government proposed introducing language requirements (B1 Swedish) in 2024-2025, but not yet enacted as of 2026',
        'One of the most liberal citizenship regimes in the EU',
        'Identity establishment is the main practical difficulty for some applicants',
        'Good conduct assessment considers criminal convictions with proportional waiting periods',
        'Processing times have improved but vary by case complexity',
      ],
    ),
  ];

  // ===========================================================================
  // PUBLIC API
  // ===========================================================================

  /// Returns all 27 EU citizenship pathways.
  static List<CitizenshipPathway> getAllPathways() =>
      List.unmodifiable(_pathways);

  /// Returns the pathway for a specific country (case-insensitive).
  static CitizenshipPathway? getByCountry(String country) {
    final lower = country.toLowerCase().trim();
    return _pathways.cast<CitizenshipPathway?>().firstWhere(
          (p) =>
              p!.country.toLowerCase() == lower ||
              p.countryCode.toLowerCase() == lower,
          orElse: () => null,
        );
  }

  /// Returns all countries that allow dual citizenship.
  static List<CitizenshipPathway> getDualCitizenshipCountries() {
    return _pathways.where((p) => p.dualCitizenshipAllowed).toList();
  }

  /// Returns all countries that do NOT allow dual citizenship (or require renunciation).
  static List<CitizenshipPathway> getNoDualCitizenshipCountries() {
    return _pathways.where((p) => !p.dualCitizenshipAllowed).toList();
  }

  /// Returns pathways sorted by residence requirement (ascending).
  static List<CitizenshipPathway> getByShortestResidence() {
    final sorted = List<CitizenshipPathway>.from(_pathways);
    sorted.sort((a, b) => a.residenceYears.compareTo(b.residenceYears));
    return sorted;
  }

  /// Returns pathways where no language test is required.
  static List<CitizenshipPathway> getNoLanguageTestCountries() {
    return _pathways.where((p) => !p.languageTestRequired).toList();
  }

  /// Returns pathways where no civics test is required.
  static List<CitizenshipPathway> getNoCivicsTestCountries() {
    return _pathways.where((p) => !p.civicsTestRequired).toList();
  }

  /// Returns pathways filtered by maximum residence years.
  static List<CitizenshipPathway> getByMaxResidenceYears(int maxYears) {
    return _pathways.where((p) => p.residenceYears <= maxYears).toList();
  }

  /// Returns pathways that have a marriage-based fast track.
  static List<CitizenshipPathway> getMarriagePathwayCountries() {
    return _pathways.where((p) => p.marriagePathway != null).toList();
  }

  /// Returns pathways sorted by processing time (ascending).
  static List<CitizenshipPathway> getByFastestProcessing() {
    final sorted = List<CitizenshipPathway>.from(_pathways);
    sorted.sort(
        (a, b) => a.processingMonths.compareTo(b.processingMonths));
    return sorted;
  }

  /// Returns pathways where the language requirement is at or below a given level.
  /// Level hierarchy: A1 < A2 < B1 < B2 < C1 < C2
  static List<CitizenshipPathway> getByMaxLanguageLevel(String maxLevel) {
    final hierarchy = ['A1', 'A2', 'A2/B1', 'B1', 'B2', 'C1', 'C2'];
    final maxIndex = hierarchy.indexOf(maxLevel.toUpperCase());
    if (maxIndex == -1) return [];

    return _pathways.where((p) {
      if (!p.languageTestRequired || p.languageLevel == null) return true;
      final pIndex = hierarchy.indexOf(p.languageLevel!.toUpperCase());
      return pIndex != -1 && pIndex <= maxIndex;
    }).toList();
  }

  /// Search pathways by keyword in requirements, exceptions, or notes.
  static List<CitizenshipPathway> searchByKeyword(String keyword) {
    final lower = keyword.toLowerCase();
    return _pathways.where((p) {
      return p.requirements.any((r) => r.toLowerCase().contains(lower)) ||
          p.exceptions.any((e) => e.toLowerCase().contains(lower)) ||
          p.additionalNotes.any((n) => n.toLowerCase().contains(lower)) ||
          p.country.toLowerCase().contains(lower);
    }).toList();
  }

  /// Returns a summary comparison of all countries.
  static List<Map<String, dynamic>> getComparisonTable() {
    return _pathways.map((p) {
      return {
        'country': p.country,
        'code': p.countryCode,
        'residenceYears': p.residenceYears,
        'languageLevel': p.languageLevel ?? 'None',
        'civicsTest': p.civicsTestRequired,
        'dualCitizenship': p.dualCitizenshipAllowed,
        'processingMonths': p.processingMonths,
        'fee': p.applicationFee ?? 'N/A',
        'marriageFastTrack': p.marriagePathway != null,
      };
    }).toList();
  }

  /// Returns countries grouped by renunciation policy.
  static Map<RenunciationRule, List<String>> getByRenunciationPolicy() {
    final result = <RenunciationRule, List<String>>{};
    for (final rule in RenunciationRule.values) {
      result[rule] = _pathways
          .where((p) => p.renunciationRule == rule)
          .map((p) => p.country)
          .toList();
    }
    return result;
  }

  /// Finds the best pathway options for a given user profile.
  static List<CitizenshipPathway> findBestOptions({
    required int maxResidenceYears,
    bool requireDualCitizenship = false,
    bool preferNoLanguageTest = false,
    bool preferNoRenunciation = false,
    String? currentNationality,
  }) {
    var results = List<CitizenshipPathway>.from(_pathways);

    results =
        results.where((p) => p.residenceYears <= maxResidenceYears).toList();

    if (requireDualCitizenship) {
      results = results.where((p) => p.dualCitizenshipAllowed).toList();
    }

    if (preferNoLanguageTest) {
      final noTest = results.where((p) => !p.languageTestRequired).toList();
      if (noTest.isNotEmpty) results = noTest;
    }

    if (preferNoRenunciation) {
      results = results
          .where((p) => p.renunciationRule == RenunciationRule.notRequired)
          .toList();
    }

    results.sort((a, b) {
      final yearsDiff = a.residenceYears.compareTo(b.residenceYears);
      if (yearsDiff != 0) return yearsDiff;
      return a.processingMonths.compareTo(b.processingMonths);
    });

    return results;
  }
}
