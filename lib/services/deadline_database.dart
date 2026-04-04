/// Comprehensive EU Legal Deadline Database
///
/// Contains verified legal deadlines for all 27 EU member states.
/// Sources: National procedural codes, EU Directive transpositions,
/// asylum procedure directives, labor codes, tenancy laws.
///
/// CRITICAL: These deadlines represent GENERAL statutory defaults.
/// Specific cases may have different deadlines based on circumstances.
/// Always verify with current national legislation before relying
/// on any deadline in this database.
///
/// Last research update: 2026-04-05

class LegalDeadline {
  final String country;
  final String countryCode; // ISO 3166-1 alpha-2
  final String caseType; // 'deportation', 'asylum', 'labor', 'tenant', 'criminal', 'administrative'
  final String action; // 'appeal', 'complaint', 'response', 'application'
  final int days; // deadline in calendar days (unless noted)
  final bool workingDays; // true if counted in working days, not calendar
  final String authority; // who to file with
  final String legalBasis; // law reference
  final String description;
  final String? notes; // special conditions or exceptions

  const LegalDeadline({
    required this.country,
    required this.countryCode,
    required this.caseType,
    required this.action,
    required this.days,
    this.workingDays = false,
    required this.authority,
    required this.legalBasis,
    required this.description,
    this.notes,
  });

  /// Returns true if the deadline is urgent (7 days or less)
  bool get isUrgent => days <= 7;

  /// Returns true if the deadline is critical (14 days or less)
  bool get isCritical => days <= 14;

  /// Human-readable deadline string
  String get deadlineText {
    final unit = workingDays ? 'working days' : 'calendar days';
    return '$days $unit';
  }

  Map<String, dynamic> toJson() => {
    'country': country,
    'countryCode': countryCode,
    'caseType': caseType,
    'action': action,
    'days': days,
    'workingDays': workingDays,
    'authority': authority,
    'legalBasis': legalBasis,
    'description': description,
    'notes': notes,
  };

  factory LegalDeadline.fromJson(Map<String, dynamic> json) => LegalDeadline(
    country: json['country'] as String,
    countryCode: json['countryCode'] as String,
    caseType: json['caseType'] as String,
    action: json['action'] as String,
    days: json['days'] as int,
    workingDays: json['workingDays'] as bool? ?? false,
    authority: json['authority'] as String,
    legalBasis: json['legalBasis'] as String,
    description: json['description'] as String,
    notes: json['notes'] as String?,
  );
}

class DeadlineDatabase {
  /// Singleton instance
  static final DeadlineDatabase _instance = DeadlineDatabase._internal();
  factory DeadlineDatabase() => _instance;
  DeadlineDatabase._internal();

  /// Get all deadlines for a specific country
  List<LegalDeadline> getByCountry(String countryCode) {
    return _allDeadlines
        .where((d) => d.countryCode.toUpperCase() == countryCode.toUpperCase())
        .toList();
  }

  /// Get all deadlines for a specific case type across all countries
  List<LegalDeadline> getByCaseType(String caseType) {
    return _allDeadlines
        .where((d) => d.caseType == caseType)
        .toList();
  }

  /// Get a specific deadline by country and case type
  List<LegalDeadline> getSpecific(String countryCode, String caseType) {
    return _allDeadlines
        .where((d) =>
            d.countryCode.toUpperCase() == countryCode.toUpperCase() &&
            d.caseType == caseType)
        .toList();
  }

  /// Get all urgent deadlines (7 days or less) for a country
  List<LegalDeadline> getUrgentDeadlines(String countryCode) {
    return getByCountry(countryCode).where((d) => d.isUrgent).toList();
  }

  /// Get all critical deadlines (14 days or less) for a country
  List<LegalDeadline> getCriticalDeadlines(String countryCode) {
    return getByCountry(countryCode).where((d) => d.isCritical).toList();
  }

  /// Search deadlines by keyword in description or legal basis
  List<LegalDeadline> search(String query) {
    final q = query.toLowerCase();
    return _allDeadlines.where((d) =>
        d.description.toLowerCase().contains(q) ||
        d.legalBasis.toLowerCase().contains(q) ||
        d.country.toLowerCase().contains(q) ||
        d.authority.toLowerCase().contains(q)).toList();
  }

  /// Get all supported countries
  List<String> get supportedCountries =>
      _allDeadlines.map((d) => d.countryCode).toSet().toList()..sort();

  /// Get the total number of deadlines in the database
  int get totalDeadlines => _allDeadlines.length;

  /// Get the shortest deadline for a case type in a country
  LegalDeadline? getShortestDeadline(String countryCode, String caseType) {
    final deadlines = getSpecific(countryCode, caseType);
    if (deadlines.isEmpty) return null;
    deadlines.sort((a, b) => a.days.compareTo(b.days));
    return deadlines.first;
  }

  // ===========================================================================
  // COMPLETE EU-27 DEADLINE DATABASE
  // ===========================================================================

  static const List<LegalDeadline> _allDeadlines = [

    // =========================================================================
    // AUSTRIA (AT)
    // =========================================================================
    LegalDeadline(
      country: 'Austria',
      countryCode: 'AT',
      caseType: 'deportation',
      action: 'appeal',
      days: 14,
      authority: 'Bundesverwaltungsgericht (Federal Administrative Court)',
      legalBasis: 'Fremdenpolizeigesetz (FPG) § 16, BFA-VG § 7(4)',
      description: 'Appeal against deportation order (Abschiebung/Rückkehrentscheidung)',
      notes: 'Counted from service of decision. Suspensive effect only if granted by court.',
    ),
    LegalDeadline(
      country: 'Austria',
      countryCode: 'AT',
      caseType: 'asylum',
      action: 'application',
      days: 0,
      authority: 'Bundesamt für Fremdenwesen und Asyl (BFA)',
      legalBasis: 'Asylgesetz 2005 (AsylG) § 17',
      description: 'Asylum application — no fixed deadline, but must apply without undue delay upon arrival',
      notes: 'Late applications may affect credibility assessment.',
    ),
    LegalDeadline(
      country: 'Austria',
      countryCode: 'AT',
      caseType: 'asylum',
      action: 'appeal',
      days: 14,
      authority: 'Bundesverwaltungsgericht',
      legalBasis: 'AsylG 2005 § 22, BFA-VG § 7(4)',
      description: 'Appeal against negative asylum decision',
      notes: 'Reduced to 7 days in accelerated procedures (airport, safe country of origin).',
    ),
    LegalDeadline(
      country: 'Austria',
      countryCode: 'AT',
      caseType: 'labor',
      action: 'complaint',
      days: 14,
      authority: 'Arbeits- und Sozialgericht (Labor and Social Court)',
      legalBasis: 'Arbeitsverfassungsgesetz (ArbVG) § 105(4)',
      description: 'Challenge against unfair dismissal (Anfechtung der Kündigung)',
      notes: 'Must first request works council opinion if applicable.',
    ),
    LegalDeadline(
      country: 'Austria',
      countryCode: 'AT',
      caseType: 'tenant',
      action: 'response',
      days: 14,
      authority: 'Bezirksgericht (District Court)',
      legalBasis: 'Mietrechtsgesetz (MRG) § 33, ZPO § 396',
      description: 'Response to eviction action (Räumungsklage)',
      notes: 'Court may grant Erstreckung (extension) in hardship cases.',
    ),
    LegalDeadline(
      country: 'Austria',
      countryCode: 'AT',
      caseType: 'criminal',
      action: 'complaint',
      days: 42,
      authority: 'Staatsanwaltschaft (Public Prosecutor) or Police',
      legalBasis: 'Strafgesetzbuch (StGB) § 57-58',
      description: 'Private prosecution crimes — deadline to file complaint (6 weeks from knowledge)',
      notes: 'General offenses: no complaint deadline (statute of limitations applies). Privatanklagedelikte: 6 weeks.',
    ),
    LegalDeadline(
      country: 'Austria',
      countryCode: 'AT',
      caseType: 'administrative',
      action: 'appeal',
      days: 28,
      authority: 'Verwaltungsgericht (Administrative Court)',
      legalBasis: 'Verwaltungsgerichtsverfahrensgesetz (VwGVG) § 7(4)',
      description: 'Appeal against administrative decisions (Beschwerde)',
      notes: '4 weeks from service of decision.',
    ),

    // =========================================================================
    // BELGIUM (BE)
    // =========================================================================
    LegalDeadline(
      country: 'Belgium',
      countryCode: 'BE',
      caseType: 'deportation',
      action: 'appeal',
      days: 30,
      authority: 'Conseil du Contentieux des Étrangers / Raad voor Vreemdelingenbetwistingen',
      legalBasis: 'Loi du 15 décembre 1980, Art. 39/57',
      description: 'Appeal against removal order (ordre de quitter le territoire)',
      notes: 'Reduced to 10 days for detained persons in certain procedures.',
    ),
    LegalDeadline(
      country: 'Belgium',
      countryCode: 'BE',
      caseType: 'asylum',
      action: 'application',
      days: 8,
      workingDays: true,
      authority: 'Office des Étrangers / Dienst Vreemdelingenzaken',
      legalBasis: 'Loi du 15 décembre 1980, Art. 50',
      description: 'Register asylum claim after arrival (must present within 8 working days)',
      notes: 'Failure to register promptly does not bar the claim but affects credibility.',
    ),
    LegalDeadline(
      country: 'Belgium',
      countryCode: 'BE',
      caseType: 'asylum',
      action: 'appeal',
      days: 30,
      authority: 'Conseil du Contentieux des Étrangers',
      legalBasis: 'Loi du 15 décembre 1980, Art. 39/57',
      description: 'Appeal against negative asylum decision (full jurisdiction appeal)',
      notes: '10 days for accelerated procedures. 5 days for subsequent applications.',
    ),
    LegalDeadline(
      country: 'Belgium',
      countryCode: 'BE',
      caseType: 'labor',
      action: 'complaint',
      days: 365,
      authority: 'Tribunal du travail / Arbeidsrechtbank',
      legalBasis: 'Loi du 26 décembre 2013, Art. 14; Loi du 3 juillet 1978, Art. 38',
      description: 'Claim for wrongful dismissal compensation',
      notes: '1 year from termination. Discrimination claims: 1 year from the facts.',
    ),
    LegalDeadline(
      country: 'Belgium',
      countryCode: 'BE',
      caseType: 'tenant',
      action: 'response',
      days: 30,
      authority: 'Justice de Paix / Vrederechter',
      legalBasis: 'Code judiciaire Art. 1344bis',
      description: 'Response to eviction proceedings',
      notes: 'Tenant receives citation with at least 8 days before hearing.',
    ),
    LegalDeadline(
      country: 'Belgium',
      countryCode: 'BE',
      caseType: 'criminal',
      action: 'complaint',
      days: 365,
      authority: 'Police or Procureur du Roi / Procureur des Konings',
      legalBasis: 'Code pénal Art. 21; Code d\'instruction criminelle',
      description: 'Criminal complaint — no specific deadline for filing, but statute of limitations applies',
      notes: 'Misdemeanors: 5 years. Serious crimes: 10-15 years. Petty offenses: 1 year.',
    ),
    LegalDeadline(
      country: 'Belgium',
      countryCode: 'BE',
      caseType: 'administrative',
      action: 'appeal',
      days: 60,
      authority: 'Conseil d\'État / Raad van State',
      legalBasis: 'Lois coordonnées sur le Conseil d\'État, Art. 4',
      description: 'Appeal for annulment of administrative acts',
      notes: '60 days from notification or publication of the act.',
    ),

    // =========================================================================
    // BULGARIA (BG)
    // =========================================================================
    LegalDeadline(
      country: 'Bulgaria',
      countryCode: 'BG',
      caseType: 'deportation',
      action: 'appeal',
      days: 14,
      authority: 'Административен съд (Administrative Court)',
      legalBasis: 'Закон за чужденците в Република България (ЗЧРБ), Чл. 46',
      description: 'Appeal against forced removal order',
      notes: 'Appeal has suspensive effect if filed within the deadline.',
    ),
    LegalDeadline(
      country: 'Bulgaria',
      countryCode: 'BG',
      caseType: 'asylum',
      action: 'application',
      days: 0,
      authority: 'Държавна агенция за бежанците (State Agency for Refugees)',
      legalBasis: 'Закон за убежището и бежанците (ЗУБ), Чл. 58',
      description: 'Asylum application — no fixed deadline, apply upon arrival or at any time on territory',
    ),
    LegalDeadline(
      country: 'Bulgaria',
      countryCode: 'BG',
      caseType: 'asylum',
      action: 'appeal',
      days: 14,
      authority: 'Административен съд — София град',
      legalBasis: 'ЗУБ Чл. 85(1)',
      description: 'Appeal against refusal of international protection',
      notes: '7 days for accelerated procedures and border procedures.',
    ),
    LegalDeadline(
      country: 'Bulgaria',
      countryCode: 'BG',
      caseType: 'labor',
      action: 'complaint',
      days: 60,
      authority: 'Районен съд (District Court)',
      legalBasis: 'Кодекс на труда (КТ), Чл. 358',
      description: 'Challenge against unlawful dismissal',
      notes: '2 months from date of dismissal. Wage claims: 3 years.',
    ),
    LegalDeadline(
      country: 'Bulgaria',
      countryCode: 'BG',
      caseType: 'tenant',
      action: 'response',
      days: 14,
      authority: 'Районен съд (District Court)',
      legalBasis: 'Граждански процесуален кодекс (ГПК), Чл. 131',
      description: 'Written response to eviction claim',
      notes: '14 days from service. Failure to respond may result in default judgment.',
    ),
    LegalDeadline(
      country: 'Bulgaria',
      countryCode: 'BG',
      caseType: 'criminal',
      action: 'complaint',
      days: 180,
      authority: 'Прокуратура (Prosecution) or Police',
      legalBasis: 'Наказателен кодекс (НК), Чл. 81; НПК Чл. 81',
      description: 'Private prosecution crimes: 6 months from learning of the offense',
      notes: 'Public prosecution offenses have no complaint deadline (statute of limitations applies).',
    ),
    LegalDeadline(
      country: 'Bulgaria',
      countryCode: 'BG',
      caseType: 'administrative',
      action: 'appeal',
      days: 14,
      authority: 'Административен съд',
      legalBasis: 'Административнопроцесуален кодекс (АПК), Чл. 149(1)',
      description: 'Appeal against individual administrative acts',
      notes: '14 days from notification. For unwritten acts: 1 month.',
    ),

    // =========================================================================
    // CROATIA (HR)
    // =========================================================================
    LegalDeadline(
      country: 'Croatia',
      countryCode: 'HR',
      caseType: 'deportation',
      action: 'appeal',
      days: 8,
      authority: 'Upravni sud (Administrative Court)',
      legalBasis: 'Zakon o strancima (Aliens Act), Čl. 205',
      description: 'Appeal against return decision / forced removal',
      notes: 'Very short deadline. Suspensive effect only in certain cases.',
    ),
    LegalDeadline(
      country: 'Croatia',
      countryCode: 'HR',
      caseType: 'asylum',
      action: 'application',
      days: 0,
      authority: 'Ministarstvo unutarnjih poslova (Ministry of Interior)',
      legalBasis: 'Zakon o međunarodnoj i privremenoj zaštiti, Čl. 33',
      description: 'Asylum application — no formal deadline, should be made without delay',
    ),
    LegalDeadline(
      country: 'Croatia',
      countryCode: 'HR',
      caseType: 'asylum',
      action: 'appeal',
      days: 8,
      authority: 'Upravni sud u Zagrebu',
      legalBasis: 'Zakon o međunarodnoj i privremenoj zaštiti, Čl. 54',
      description: 'Appeal against negative asylum decision',
      notes: '4 days in accelerated procedures.',
    ),
    LegalDeadline(
      country: 'Croatia',
      countryCode: 'HR',
      caseType: 'labor',
      action: 'complaint',
      days: 15,
      authority: 'Općinski sud (Municipal Court)',
      legalBasis: 'Zakon o radu, Čl. 133',
      description: 'Challenge against dismissal decision',
      notes: '15 days from delivery of dismissal decision. Must first request employer review.',
    ),
    LegalDeadline(
      country: 'Croatia',
      countryCode: 'HR',
      caseType: 'tenant',
      action: 'response',
      days: 15,
      authority: 'Općinski sud (Municipal Court)',
      legalBasis: 'Zakon o najmu stanova, Čl. 22',
      description: 'Response to eviction lawsuit',
    ),
    LegalDeadline(
      country: 'Croatia',
      countryCode: 'HR',
      caseType: 'criminal',
      action: 'complaint',
      days: 90,
      authority: 'Državno odvjetništvo (State Attorney) or Police',
      legalBasis: 'Kazneni zakon, Čl. 82',
      description: 'Private prosecution crimes: 3 months from learning of offense and offender',
    ),
    LegalDeadline(
      country: 'Croatia',
      countryCode: 'HR',
      caseType: 'administrative',
      action: 'appeal',
      days: 30,
      authority: 'Upravni sud',
      legalBasis: 'Zakon o upravnim sporovima, Čl. 24',
      description: 'Administrative lawsuit against administrative decision',
      notes: '30 days from service of the decision.',
    ),

    // =========================================================================
    // CYPRUS (CY)
    // =========================================================================
    LegalDeadline(
      country: 'Cyprus',
      countryCode: 'CY',
      caseType: 'deportation',
      action: 'appeal',
      days: 75,
      authority: 'Administrative Court (Διοικητικό Δικαστήριο)',
      legalBasis: 'Refugee Law N.6(I)/2000, Art. 146 Constitution',
      description: 'Recourse against deportation/removal order',
      notes: '75 days from notification under Art. 146 of the Constitution.',
    ),
    LegalDeadline(
      country: 'Cyprus',
      countryCode: 'CY',
      caseType: 'asylum',
      action: 'application',
      days: 0,
      authority: 'Asylum Service (Υπηρεσία Ασύλου)',
      legalBasis: 'Refugee Law N.6(I)/2000, as amended',
      description: 'Asylum application — no statutory deadline, apply as soon as possible',
    ),
    LegalDeadline(
      country: 'Cyprus',
      countryCode: 'CY',
      caseType: 'asylum',
      action: 'appeal',
      days: 75,
      authority: 'Administrative Court',
      legalBasis: 'Constitution Art. 146; Refugee Law N.6(I)/2000',
      description: 'Recourse against negative asylum decision',
      notes: '75 days from notification of refusal.',
    ),
    LegalDeadline(
      country: 'Cyprus',
      countryCode: 'CY',
      caseType: 'labor',
      action: 'complaint',
      days: 365,
      authority: 'Industrial Disputes Tribunal (Δικαστήριο Εργατικών Διαφορών)',
      legalBasis: 'Termination of Employment Law N.24/1967, Art. 10',
      description: 'Claim for unfair dismissal compensation',
      notes: '12 months from date of termination.',
    ),
    LegalDeadline(
      country: 'Cyprus',
      countryCode: 'CY',
      caseType: 'tenant',
      action: 'response',
      days: 14,
      authority: 'Rent Control Tribunal / District Court',
      legalBasis: 'Rent Control Law Cap. 36',
      description: 'Response to eviction proceedings',
    ),
    LegalDeadline(
      country: 'Cyprus',
      countryCode: 'CY',
      caseType: 'criminal',
      action: 'complaint',
      days: 180,
      authority: 'Police or Attorney General',
      legalBasis: 'Criminal Code Cap. 154',
      description: 'Criminal complaint — no formal deadline for serious offenses; summary offenses: 6 months',
    ),
    LegalDeadline(
      country: 'Cyprus',
      countryCode: 'CY',
      caseType: 'administrative',
      action: 'appeal',
      days: 75,
      authority: 'Administrative Court',
      legalBasis: 'Constitution Art. 146(3)',
      description: 'Recourse against administrative decision',
      notes: '75 days from knowledge of the act or its publication.',
    ),

    // =========================================================================
    // CZECH REPUBLIC (CZ)
    // =========================================================================
    LegalDeadline(
      country: 'Czech Republic',
      countryCode: 'CZ',
      caseType: 'deportation',
      action: 'appeal',
      days: 10,
      authority: 'Krajský soud (Regional Court)',
      legalBasis: 'Zákon č. 326/1999 Sb. o pobytu cizinců, § 172; Soudní řád správní § 32',
      description: 'Action against administrative expulsion order',
      notes: '10 days from notification. Has suspensive effect.',
    ),
    LegalDeadline(
      country: 'Czech Republic',
      countryCode: 'CZ',
      caseType: 'asylum',
      action: 'application',
      days: 0,
      authority: 'Ministerstvo vnitra (Ministry of Interior)',
      legalBasis: 'Zákon č. 325/1999 Sb. o azylu, § 3',
      description: 'Asylum application — must be filed without undue delay',
    ),
    LegalDeadline(
      country: 'Czech Republic',
      countryCode: 'CZ',
      caseType: 'asylum',
      action: 'appeal',
      days: 15,
      authority: 'Krajský soud (Regional Court)',
      legalBasis: 'Zákon o azylu § 32, Soudní řád správní § 32(1)',
      description: 'Action against negative asylum decision',
      notes: '7 days for airport procedure decisions.',
    ),
    LegalDeadline(
      country: 'Czech Republic',
      countryCode: 'CZ',
      caseType: 'labor',
      action: 'complaint',
      days: 60,
      authority: 'Okresní soud (District Court)',
      legalBasis: 'Zákoník práce § 72',
      description: 'Challenge against invalid dismissal (neplatnost rozvázání)',
      notes: '2 months from the date employment was supposed to end.',
    ),
    LegalDeadline(
      country: 'Czech Republic',
      countryCode: 'CZ',
      caseType: 'tenant',
      action: 'response',
      days: 30,
      authority: 'Okresní soud (District Court)',
      legalBasis: 'Občanský zákoník § 2291; Občanský soudní řád § 114b',
      description: 'Response to eviction action',
    ),
    LegalDeadline(
      country: 'Czech Republic',
      countryCode: 'CZ',
      caseType: 'criminal',
      action: 'complaint',
      days: 90,
      authority: 'Police or Státní zastupitelství (State Attorney)',
      legalBasis: 'Trestní zákoník § 163',
      description: 'Consent offenses — 30-day consent period; general crimes have no complaint deadline',
      notes: 'Some offenses require victim consent within 30 days of learning of suspect.',
    ),
    LegalDeadline(
      country: 'Czech Republic',
      countryCode: 'CZ',
      caseType: 'administrative',
      action: 'appeal',
      days: 15,
      authority: 'Nadřízený správní orgán / Krajský soud',
      legalBasis: 'Správní řád § 83(1); Soudní řád správní § 72(1)',
      description: 'Administrative appeal: 15 days. Judicial review: 2 months (60 days)',
      notes: 'Administrative appeal: 15 days. Court action: 60 days from decision.',
    ),

    // =========================================================================
    // DENMARK (DK)
    // =========================================================================
    LegalDeadline(
      country: 'Denmark',
      countryCode: 'DK',
      caseType: 'deportation',
      action: 'appeal',
      days: 7,
      authority: 'Flygtningenævnet (Refugee Appeals Board) / Udlændingenævnet',
      legalBasis: 'Udlændingeloven § 53a',
      description: 'Appeal against expulsion/deportation decision',
      notes: '7 days for asylum-related removals. Administrative deportation appeals: 8 weeks to Udlændingenævnet.',
    ),
    LegalDeadline(
      country: 'Denmark',
      countryCode: 'DK',
      caseType: 'asylum',
      action: 'application',
      days: 0,
      authority: 'Udlændingestyrelsen (Immigration Service)',
      legalBasis: 'Udlændingeloven § 7',
      description: 'Asylum application — no fixed deadline, apply at police upon arrival',
    ),
    LegalDeadline(
      country: 'Denmark',
      countryCode: 'DK',
      caseType: 'asylum',
      action: 'appeal',
      days: 7,
      authority: 'Flygtningenævnet (Refugee Appeals Board)',
      legalBasis: 'Udlændingeloven § 53a',
      description: 'Appeal against negative asylum decision (manifestly unfounded cases)',
      notes: 'Standard rejections: automatic referral to Refugee Board. Dublin/safe country: 7 days.',
    ),
    LegalDeadline(
      country: 'Denmark',
      countryCode: 'DK',
      caseType: 'labor',
      action: 'complaint',
      days: 365,
      authority: 'Byretten (City Court) or Industrial Arbitration',
      legalBasis: 'Funktionærloven § 2b; Lov om Arbejdsretten',
      description: 'Unfair dismissal claim for salaried employees',
      notes: 'Non-salaried: governed by collective agreement. Discrimination: 6 months filing with Board of Equal Treatment.',
    ),
    LegalDeadline(
      country: 'Denmark',
      countryCode: 'DK',
      caseType: 'tenant',
      action: 'response',
      days: 14,
      authority: 'Huslejenævnet (Rent Tribunal) / Boligretten (Housing Court)',
      legalBasis: 'Lejeloven § 93, § 94',
      description: 'Response to eviction notice or complaint to Rent Tribunal',
      notes: 'Tenants can contest with Huslejenævnet. Court eviction: response within 14 days.',
    ),
    LegalDeadline(
      country: 'Denmark',
      countryCode: 'DK',
      caseType: 'criminal',
      action: 'complaint',
      days: 180,
      authority: 'Police or Statsadvokaten (State Prosecutor)',
      legalBasis: 'Straffeloven § 93-94',
      description: 'Criminal complaint — no formal complaint deadline; statute of limitations: 2-15 years depending on offense',
      notes: 'Private prosecution crimes: 6 months. Most crimes prosecuted publicly.',
    ),
    LegalDeadline(
      country: 'Denmark',
      countryCode: 'DK',
      caseType: 'administrative',
      action: 'appeal',
      days: 28,
      authority: 'Relevant appeals board or Ombudsman',
      legalBasis: 'Forvaltningsloven § 25; specific sectoral laws',
      description: 'Administrative complaint/appeal — typically 4 weeks',
      notes: 'Varies by sector. Immigration: 8 weeks to Udlændingenævnet.',
    ),

    // =========================================================================
    // ESTONIA (EE)
    // =========================================================================
    LegalDeadline(
      country: 'Estonia',
      countryCode: 'EE',
      caseType: 'deportation',
      action: 'appeal',
      days: 10,
      authority: 'Halduskohus (Administrative Court)',
      legalBasis: 'Väljasõidukohustuse ja sissesõidukeelu seadus § 72; HKMS § 121',
      description: 'Challenge against obligation to leave / deportation order',
      notes: '10 days from notification. Suspensive effect if court grants it.',
    ),
    LegalDeadline(
      country: 'Estonia',
      countryCode: 'EE',
      caseType: 'asylum',
      action: 'application',
      days: 0,
      authority: 'Politsei- ja Piirivalveamet (Police and Border Guard Board)',
      legalBasis: 'Välismaalasele rahvusvahelise kaitse andmise seadus § 14',
      description: 'Asylum application — no fixed deadline, apply at border or on territory',
    ),
    LegalDeadline(
      country: 'Estonia',
      countryCode: 'EE',
      caseType: 'asylum',
      action: 'appeal',
      days: 10,
      authority: 'Halduskohus (Administrative Court)',
      legalBasis: 'VRKS § 25(1); HKMS § 121',
      description: 'Appeal against negative asylum decision',
      notes: '10 days. Accelerated procedure: 7 days.',
    ),
    LegalDeadline(
      country: 'Estonia',
      countryCode: 'EE',
      caseType: 'labor',
      action: 'complaint',
      days: 30,
      authority: 'Töövaidluskomisjon (Labor Dispute Committee) or Maakohus (County Court)',
      legalBasis: 'Töölepingu seadus § 105',
      description: 'Challenge against termination of employment contract',
      notes: '30 calendar days from receiving notice of termination.',
    ),
    LegalDeadline(
      country: 'Estonia',
      countryCode: 'EE',
      caseType: 'tenant',
      action: 'response',
      days: 30,
      authority: 'Maakohus (County Court)',
      legalBasis: 'Võlaõigusseadus § 313-316; TsMS § 394',
      description: 'Response to eviction action',
    ),
    LegalDeadline(
      country: 'Estonia',
      countryCode: 'EE',
      caseType: 'criminal',
      action: 'complaint',
      days: 0,
      authority: 'Police or Prokuratuur (Prosecutor)',
      legalBasis: 'Karistusseadustik § 81; KrMS § 6',
      description: 'Criminal complaint — no formal deadline for filing; statute of limitations applies',
      notes: 'Misdemeanors: 2 years. Crimes: 3-15 years depending on severity.',
    ),
    LegalDeadline(
      country: 'Estonia',
      countryCode: 'EE',
      caseType: 'administrative',
      action: 'appeal',
      days: 30,
      authority: 'Halduskohus (Administrative Court)',
      legalBasis: 'Halduskohtumenetluse seadustik (HKMS) § 121',
      description: 'Challenge against administrative act (halduskaebus)',
      notes: '30 days from becoming aware of the act.',
    ),

    // =========================================================================
    // FINLAND (FI)
    // =========================================================================
    LegalDeadline(
      country: 'Finland',
      countryCode: 'FI',
      caseType: 'deportation',
      action: 'appeal',
      days: 30,
      authority: 'Hallinto-oikeus (Administrative Court)',
      legalBasis: 'Ulkomaalaislaki 301/2004 § 190; Oikeudenkäynnistä hallintoasioissa 808/2019 § 13',
      description: 'Appeal against deportation decision (käännyttäminen / maasta poistaminen)',
      notes: '30 days from notification of the decision. Suspensive effect in most cases.',
    ),
    LegalDeadline(
      country: 'Finland',
      countryCode: 'FI',
      caseType: 'asylum',
      action: 'application',
      days: 0,
      authority: 'Maahanmuuttovirasto (Finnish Immigration Service, Migri) or Police',
      legalBasis: 'Ulkomaalaislaki § 95',
      description: 'Asylum application — no fixed deadline, file without delay at border or police',
    ),
    LegalDeadline(
      country: 'Finland',
      countryCode: 'FI',
      caseType: 'asylum',
      action: 'appeal',
      days: 21,
      authority: 'Hallinto-oikeus (Administrative Court)',
      legalBasis: 'Ulkomaalaislaki § 190(3)',
      description: 'Appeal against negative asylum decision',
      notes: '21 days from notification. Accelerated/Dublin: 14 days.',
    ),
    LegalDeadline(
      country: 'Finland',
      countryCode: 'FI',
      caseType: 'labor',
      action: 'complaint',
      days: 730,
      authority: 'Käräjäoikeus (District Court)',
      legalBasis: 'Työsopimuslaki 55/2001 § 13:9',
      description: 'Claim arising from employment relationship (general 2-year limitation)',
      notes: 'Must be brought within 2 years from end of employment. Collective agreement disputes: Työtuomioistuin.',
    ),
    LegalDeadline(
      country: 'Finland',
      countryCode: 'FI',
      caseType: 'tenant',
      action: 'response',
      days: 14,
      authority: 'Käräjäoikeus (District Court)',
      legalBasis: 'Laki asuinhuoneiston vuokrauksesta 481/1995 § 66; Oikeudenkäymiskaari 4:9',
      description: 'Response to eviction lawsuit (haastehakemus)',
      notes: 'Typically 14-30 days as set by court. Tenant may also dispute notice validity.',
    ),
    LegalDeadline(
      country: 'Finland',
      countryCode: 'FI',
      caseType: 'criminal',
      action: 'complaint',
      days: 0,
      authority: 'Police or Syyttäjä (Prosecutor)',
      legalBasis: 'Rikoslaki 39/1889 § 8:1-3',
      description: 'Criminal complaint — no formal deadline for filing',
      notes: 'Complainant offenses: withdraw right exists until judgment. Statute of limitations: 2-20 years.',
    ),
    LegalDeadline(
      country: 'Finland',
      countryCode: 'FI',
      caseType: 'administrative',
      action: 'appeal',
      days: 30,
      authority: 'Hallinto-oikeus (Administrative Court)',
      legalBasis: 'Laki oikeudenkäynnistä hallintoasioissa 808/2019 § 13',
      description: 'Appeal against administrative decision (hallintovalitus)',
      notes: '30 days from notification of the decision.',
    ),

    // =========================================================================
    // FRANCE (FR)
    // =========================================================================
    LegalDeadline(
      country: 'France',
      countryCode: 'FR',
      caseType: 'deportation',
      action: 'appeal',
      days: 30,
      authority: 'Tribunal administratif',
      legalBasis: 'CESEDA Art. L614-1 et seq.',
      description: 'Appeal against obligation de quitter le territoire français (OQTF)',
      notes: '48 hours if detained. 15 days if OQTF with no voluntary departure period. 30 days if with departure period.',
    ),
    LegalDeadline(
      country: 'France',
      countryCode: 'FR',
      caseType: 'asylum',
      action: 'application',
      days: 90,
      authority: 'OFPRA (Office français de protection des réfugiés et apatrides)',
      legalBasis: 'CESEDA Art. L531-27',
      description: 'Register asylum claim within 90 days of arrival (formerly 120 days)',
      notes: 'Late filing does not bar claim but may trigger accelerated procedure.',
    ),
    LegalDeadline(
      country: 'France',
      countryCode: 'FR',
      caseType: 'asylum',
      action: 'appeal',
      days: 30,
      authority: 'Cour nationale du droit d\'asile (CNDA)',
      legalBasis: 'CESEDA Art. L532-1',
      description: 'Appeal against negative OFPRA decision',
      notes: '30 days from notification. 15 days for accelerated procedures.',
    ),
    LegalDeadline(
      country: 'France',
      countryCode: 'FR',
      caseType: 'labor',
      action: 'complaint',
      days: 365,
      authority: 'Conseil de prud\'hommes',
      legalBasis: 'Code du travail Art. L1471-1',
      description: 'Contest dismissal (licenciement): 12 months from notification',
      notes: 'Discrimination claims: 5 years. Wage claims: 3 years.',
    ),
    LegalDeadline(
      country: 'France',
      countryCode: 'FR',
      caseType: 'tenant',
      action: 'response',
      days: 60,
      authority: 'Tribunal judiciaire or Tribunal de proximité',
      legalBasis: 'Loi n°89-462 du 6 juillet 1989, Art. 24; CPC Art. 641',
      description: 'Response after commandement de payer (payment order before eviction)',
      notes: 'Tenant has 2 months to pay arrears after commandement. Court may grant additional delays (up to 3 years).',
    ),
    LegalDeadline(
      country: 'France',
      countryCode: 'FR',
      caseType: 'criminal',
      action: 'complaint',
      days: 0,
      authority: 'Police, Gendarmerie, or Procureur de la République',
      legalBasis: 'Code de procédure pénale Art. 7-8; Code pénal',
      description: 'Criminal complaint (plainte) — no formal filing deadline',
      notes: 'Statute of limitations: Contraventions 1 year, Délits 6 years, Crimes 20 years.',
    ),
    LegalDeadline(
      country: 'France',
      countryCode: 'FR',
      caseType: 'administrative',
      action: 'appeal',
      days: 60,
      authority: 'Tribunal administratif',
      legalBasis: 'Code de justice administrative Art. R421-1',
      description: 'Appeal against administrative decisions (recours pour excès de pouvoir)',
      notes: '2 months from notification or publication.',
    ),

    // =========================================================================
    // GERMANY (DE)
    // =========================================================================
    LegalDeadline(
      country: 'Germany',
      countryCode: 'DE',
      caseType: 'deportation',
      action: 'appeal',
      days: 7,
      authority: 'Verwaltungsgericht (Administrative Court)',
      legalBasis: 'Aufenthaltsgesetz (AufenthG) § 59; AsylG § 36(3)',
      description: 'Urgent application against deportation (Eilantrag)',
      notes: 'If linked to asylum rejection as manifestly unfounded: 7 days for Eilantrag. Standard cases: 14 days for Klage.',
    ),
    LegalDeadline(
      country: 'Germany',
      countryCode: 'DE',
      caseType: 'asylum',
      action: 'application',
      days: 0,
      authority: 'Bundesamt für Migration und Flüchtlinge (BAMF)',
      legalBasis: 'Asylgesetz § 13-14',
      description: 'Asylum application — no fixed deadline, apply at registration center or BAMF',
    ),
    LegalDeadline(
      country: 'Germany',
      countryCode: 'DE',
      caseType: 'asylum',
      action: 'appeal',
      days: 14,
      authority: 'Verwaltungsgericht',
      legalBasis: 'AsylG § 74(1)',
      description: 'Klage (action) against negative asylum decision',
      notes: '7 days for Eilantrag if declared manifestly unfounded or Dublin. 14 days for standard Klage.',
    ),
    LegalDeadline(
      country: 'Germany',
      countryCode: 'DE',
      caseType: 'labor',
      action: 'complaint',
      days: 21,
      authority: 'Arbeitsgericht (Labor Court)',
      legalBasis: 'Kündigungsschutzgesetz (KSchG) § 4',
      description: 'Kündigungsschutzklage — challenge against dismissal',
      notes: '3 weeks from receipt of written termination notice. CRITICAL: missing this deadline = dismissal is valid.',
    ),
    LegalDeadline(
      country: 'Germany',
      countryCode: 'DE',
      caseType: 'tenant',
      action: 'response',
      days: 60,
      authority: 'Amtsgericht (Local Court)',
      legalBasis: 'BGB § 574b; ZPO § 276',
      description: 'Objection to termination of tenancy (Widerspruch gegen Kündigung)',
      notes: 'Widerspruch must be filed 2 months before lease end. Court response: set by court.',
    ),
    LegalDeadline(
      country: 'Germany',
      countryCode: 'DE',
      caseType: 'criminal',
      action: 'complaint',
      days: 90,
      authority: 'Police or Staatsanwaltschaft (Public Prosecutor)',
      legalBasis: 'StGB § 77b; Strafprozessordnung (StPO)',
      description: 'Antragsdelikte (complaint offenses): 3 months from knowledge of offender',
      notes: 'Public prosecution offenses: no complaint deadline. Privatklagedelikte: separate rules.',
    ),
    LegalDeadline(
      country: 'Germany',
      countryCode: 'DE',
      caseType: 'administrative',
      action: 'appeal',
      days: 30,
      authority: 'Verwaltungsgericht (Administrative Court)',
      legalBasis: 'Verwaltungsgerichtsordnung (VwGO) § 74(1)',
      description: 'Anfechtungsklage/Verpflichtungsklage against administrative act',
      notes: '1 month from service of decision. Widerspruch (objection): also 1 month.',
    ),

    // =========================================================================
    // GREECE (GR)
    // =========================================================================
    LegalDeadline(
      country: 'Greece',
      countryCode: 'GR',
      caseType: 'deportation',
      action: 'appeal',
      days: 30,
      authority: 'Διοικητικό Πρωτοδικείο (Administrative Court of First Instance)',
      legalBasis: 'Ν. 3386/2005 Art. 77; ΚΔΔ Art. 63',
      description: 'Appeal against deportation/return decision',
      notes: 'Application for suspension may be filed at the same time.',
    ),
    LegalDeadline(
      country: 'Greece',
      countryCode: 'GR',
      caseType: 'asylum',
      action: 'application',
      days: 0,
      authority: 'Υπηρεσία Ασύλου (Asylum Service)',
      legalBasis: 'Ν. 4939/2022 Art. 65',
      description: 'Asylum application — no fixed deadline, file at regional asylum office',
    ),
    LegalDeadline(
      country: 'Greece',
      countryCode: 'GR',
      caseType: 'asylum',
      action: 'appeal',
      days: 30,
      authority: 'Επιτροπή Προσφυγών (Appeals Authority / Independent Appeals Committees)',
      legalBasis: 'Ν. 4939/2022 Art. 92',
      description: 'Appeal against first-instance asylum refusal',
      notes: '30 days from notification. 15 days in accelerated / border procedures. 10 days for detention cases.',
    ),
    LegalDeadline(
      country: 'Greece',
      countryCode: 'GR',
      caseType: 'labor',
      action: 'complaint',
      days: 90,
      authority: 'Μονομελές Πρωτοδικείο (Single-Member Court of First Instance)',
      legalBasis: 'ΑΚ Art. 672; Ν. 3198/1955 Art. 6',
      description: 'Challenge against unlawful dismissal',
      notes: '3 months from dismissal. Wage claims: 5 years.',
    ),
    LegalDeadline(
      country: 'Greece',
      countryCode: 'GR',
      caseType: 'tenant',
      action: 'response',
      days: 30,
      authority: 'Ειρηνοδικείο (Magistrate\'s Court) or Μονομελές Πρωτοδικείο',
      legalBasis: 'ΚΠολΔ Art. 637-645',
      description: 'Response/opposition to eviction order (διαταγή απόδοσης μισθίου)',
      notes: '15 working days from service for opposition to payment order.',
    ),
    LegalDeadline(
      country: 'Greece',
      countryCode: 'GR',
      caseType: 'criminal',
      action: 'complaint',
      days: 90,
      authority: 'Εισαγγελία (Prosecutor) or Police',
      legalBasis: 'ΠΚ Art. 114; ΚΠΔ Art. 42',
      description: 'Complaint offenses (κατ\' έγκλησιν): 3 months from knowledge of offense',
      notes: 'Public prosecution offenses: no complaint deadline.',
    ),
    LegalDeadline(
      country: 'Greece',
      countryCode: 'GR',
      caseType: 'administrative',
      action: 'appeal',
      days: 60,
      authority: 'Διοικητικό Πρωτοδικείο / Συμβούλιο της Επικρατείας',
      legalBasis: 'ΚΔΔ Art. 63-66',
      description: 'Administrative appeal (προσφυγή) against administrative act',
      notes: '60 days from notification. Annulment action (ακύρωση): 60 days.',
    ),

    // =========================================================================
    // HUNGARY (HU)
    // =========================================================================
    LegalDeadline(
      country: 'Hungary',
      countryCode: 'HU',
      caseType: 'deportation',
      action: 'appeal',
      days: 3,
      authority: 'Közigazgatási és Munkaügyi Bíróság (Administrative and Labor Court)',
      legalBasis: 'Harmadik országbeli állampolgárok beutazásáról szóló tv. (Szabs. tv.) § 65',
      description: 'Appeal against expulsion order',
      notes: 'Extremely short — 3 days in transit zone/detention cases. Standard: 8 days.',
    ),
    LegalDeadline(
      country: 'Hungary',
      countryCode: 'HU',
      caseType: 'asylum',
      action: 'application',
      days: 0,
      authority: 'Országos Idegenrendészeti Főigazgatóság (NDGAP)',
      legalBasis: 'Menedékjogról szóló 2007. évi LXXX. törvény § 35',
      description: 'Asylum application — theoretically no deadline, but access severely restricted',
      notes: 'Hungary\'s asylum access has been restricted. Embassy procedure was introduced and later struck down by CJEU.',
    ),
    LegalDeadline(
      country: 'Hungary',
      countryCode: 'HU',
      caseType: 'asylum',
      action: 'appeal',
      days: 8,
      authority: 'Fővárosi Közigazgatási és Munkaügyi Bíróság',
      legalBasis: 'Met. § 53(2)',
      description: 'Appeal against negative asylum decision',
      notes: '3 days for inadmissibility decisions. 8 days for standard rejections.',
    ),
    LegalDeadline(
      country: 'Hungary',
      countryCode: 'HU',
      caseType: 'labor',
      action: 'complaint',
      days: 30,
      authority: 'Közigazgatási és Munkaügyi Bíróság',
      legalBasis: 'Munka Törvénykönyve (Mt.) § 287(1)',
      description: 'Challenge against dismissal',
      notes: '30 days from communication of dismissal. Wage claims: 3 years.',
    ),
    LegalDeadline(
      country: 'Hungary',
      countryCode: 'HU',
      caseType: 'tenant',
      action: 'response',
      days: 15,
      authority: 'Járásbíróság (District Court)',
      legalBasis: 'Pp. (Code of Civil Procedure) § 199; Lakástörvény',
      description: 'Response to eviction lawsuit',
    ),
    LegalDeadline(
      country: 'Hungary',
      countryCode: 'HU',
      caseType: 'criminal',
      action: 'complaint',
      days: 30,
      authority: 'Rendőrség (Police) or Ügyészség (Prosecution)',
      legalBasis: 'Btk. § 31; Be. § 173',
      description: 'Magánindítvány (private motion) offenses: 30 days from learning of suspect',
      notes: 'Public offenses: no complaint deadline.',
    ),
    LegalDeadline(
      country: 'Hungary',
      countryCode: 'HU',
      caseType: 'administrative',
      action: 'appeal',
      days: 30,
      authority: 'Közigazgatási és Munkaügyi Bíróság / Törvényszék',
      legalBasis: 'Közigazgatási perrendtartás (Kp.) § 39(1)',
      description: 'Administrative court action (közigazgatási per)',
      notes: '30 days from notification of the decision.',
    ),

    // =========================================================================
    // IRELAND (IE)
    // =========================================================================
    LegalDeadline(
      country: 'Ireland',
      countryCode: 'IE',
      caseType: 'deportation',
      action: 'appeal',
      days: 14,
      authority: 'High Court (Judicial Review)',
      legalBasis: 'International Protection Act 2015, Section 48(7); Illegal Immigrants (Trafficking) Act 2000 § 5',
      description: 'Application for leave for judicial review of deportation order',
      notes: '14 days for immigration-related judicial review. Must show substantial grounds.',
    ),
    LegalDeadline(
      country: 'Ireland',
      countryCode: 'IE',
      caseType: 'asylum',
      action: 'application',
      days: 0,
      authority: 'International Protection Office (IPO)',
      legalBasis: 'International Protection Act 2015, Section 15',
      description: 'International protection application — no fixed deadline',
    ),
    LegalDeadline(
      country: 'Ireland',
      countryCode: 'IE',
      caseType: 'asylum',
      action: 'appeal',
      days: 15,
      workingDays: true,
      authority: 'International Protection Appeals Tribunal (IPAT)',
      legalBasis: 'International Protection Act 2015, Section 41',
      description: 'Appeal against negative international protection recommendation',
      notes: '15 working days from notice. 10 working days for accelerated cases.',
    ),
    LegalDeadline(
      country: 'Ireland',
      countryCode: 'IE',
      caseType: 'labor',
      action: 'complaint',
      days: 180,
      authority: 'Workplace Relations Commission (WRC)',
      legalBasis: 'Unfair Dismissals Act 1977-2015, Section 8; Workplace Relations Act 2015',
      description: 'Complaint of unfair dismissal to WRC',
      notes: '6 months from date of dismissal. Extendable to 12 months for reasonable cause.',
    ),
    LegalDeadline(
      country: 'Ireland',
      countryCode: 'IE',
      caseType: 'tenant',
      action: 'response',
      days: 28,
      authority: 'Residential Tenancies Board (RTB)',
      legalBasis: 'Residential Tenancies Act 2004, Section 78',
      description: 'Dispute referral to RTB regarding notice of termination',
      notes: '28 days from receipt of termination notice to refer dispute to RTB.',
    ),
    LegalDeadline(
      country: 'Ireland',
      countryCode: 'IE',
      caseType: 'criminal',
      action: 'complaint',
      days: 180,
      authority: 'An Garda Síochána (Police) or DPP',
      legalBasis: 'Petty Sessions (Ireland) Act 1851; Criminal Justice Acts',
      description: 'Summary offenses: complaint within 6 months. Indictable: no time limit for complaint',
    ),
    LegalDeadline(
      country: 'Ireland',
      countryCode: 'IE',
      caseType: 'administrative',
      action: 'appeal',
      days: 90,
      authority: 'High Court (Judicial Review)',
      legalBasis: 'Order 84 Rules of the Superior Courts',
      description: 'Judicial review of administrative decisions — 3 months (or 14 days for immigration)',
      notes: 'General: 3 months. Immigration/planning: 14 days or 8 weeks depending on type.',
    ),

    // =========================================================================
    // ITALY (IT)
    // =========================================================================
    LegalDeadline(
      country: 'Italy',
      countryCode: 'IT',
      caseType: 'deportation',
      action: 'appeal',
      days: 30,
      authority: 'Giudice di Pace (Justice of the Peace)',
      legalBasis: 'D.Lgs. 286/1998 (TUI) Art. 13(8)',
      description: 'Ricorso against expulsion decree (decreto di espulsione)',
      notes: '30 days from notification. 60 days if applicant was outside Italy when served.',
    ),
    LegalDeadline(
      country: 'Italy',
      countryCode: 'IT',
      caseType: 'asylum',
      action: 'application',
      days: 0,
      authority: 'Questura (Police Headquarters)',
      legalBasis: 'D.Lgs. 25/2008 Art. 6; D.Lgs. 142/2015',
      description: 'Asylum application — no fixed deadline, express intent at border or Questura',
    ),
    LegalDeadline(
      country: 'Italy',
      countryCode: 'IT',
      caseType: 'asylum',
      action: 'appeal',
      days: 30,
      authority: 'Tribunale ordinario — sezione specializzata',
      legalBasis: 'D.Lgs. 25/2008 Art. 35-bis',
      description: 'Appeal against rejection by Territorial Commission',
      notes: '30 days from notification. 15 days if applicant is in reception center.',
    ),
    LegalDeadline(
      country: 'Italy',
      countryCode: 'IT',
      caseType: 'labor',
      action: 'complaint',
      days: 60,
      authority: 'Tribunale del lavoro (Labor Tribunal)',
      legalBasis: 'Art. 6 L. 604/1966 (as amended by L. 92/2012)',
      description: 'Challenge against dismissal (impugnazione del licenziamento)',
      notes: 'Step 1: Written challenge to employer within 60 days. Step 2: File court action within 180 days after.',
    ),
    LegalDeadline(
      country: 'Italy',
      countryCode: 'IT',
      caseType: 'tenant',
      action: 'response',
      days: 20,
      authority: 'Tribunale (Court)',
      legalBasis: 'CPC Art. 447-bis; L. 392/1978',
      description: 'Response to eviction for arrears (sfratto per morosità)',
      notes: 'In convalida procedure, tenant can appear at hearing and oppose. Court grants term to pay (termine di grazia: 90 days).',
    ),
    LegalDeadline(
      country: 'Italy',
      countryCode: 'IT',
      caseType: 'criminal',
      action: 'complaint',
      days: 90,
      authority: 'Autorità giudiziaria (Prosecutor) or Police',
      legalBasis: 'CPP Art. 336; CP Art. 124',
      description: 'Querela (complaint) for complaint-based offenses: 3 months from knowledge',
      notes: 'Sexual offenses: 12 months. Public offenses: no complaint deadline.',
    ),
    LegalDeadline(
      country: 'Italy',
      countryCode: 'IT',
      caseType: 'administrative',
      action: 'appeal',
      days: 60,
      authority: 'Tribunale Amministrativo Regionale (TAR)',
      legalBasis: 'D.Lgs. 104/2010 (CPA) Art. 29',
      description: 'Ricorso against administrative acts',
      notes: '60 days from notification. 120 days for Ricorso straordinario al Presidente della Repubblica.',
    ),

    // =========================================================================
    // LATVIA (LV)
    // =========================================================================
    LegalDeadline(
      country: 'Latvia',
      countryCode: 'LV',
      caseType: 'deportation',
      action: 'appeal',
      days: 7,
      authority: 'Administratīvā rajona tiesa (Administrative District Court)',
      legalBasis: 'Imigrācijas likums 47. pants',
      description: 'Appeal against forced removal decision',
      notes: '7 days from notification. Suspensive effect if court grants it.',
    ),
    LegalDeadline(
      country: 'Latvia',
      countryCode: 'LV',
      caseType: 'asylum',
      action: 'application',
      days: 0,
      authority: 'Pilsonības un migrācijas lietu pārvalde (PMLP)',
      legalBasis: 'Patvēruma likums 12. pants',
      description: 'Asylum application — no fixed deadline',
    ),
    LegalDeadline(
      country: 'Latvia',
      countryCode: 'LV',
      caseType: 'asylum',
      action: 'appeal',
      days: 15,
      authority: 'Administratīvā rajona tiesa',
      legalBasis: 'Patvēruma likums 35. pants',
      description: 'Appeal against negative asylum decision',
      notes: '15 days from notification. 7 days for accelerated procedures.',
    ),
    LegalDeadline(
      country: 'Latvia',
      countryCode: 'LV',
      caseType: 'labor',
      action: 'complaint',
      days: 30,
      authority: 'Rajona (pilsētas) tiesa (District/City Court)',
      legalBasis: 'Darba likums 122. pants',
      description: 'Contest against dismissal',
      notes: '1 month from date of dismissal notice. Wage claims: 2 years.',
    ),
    LegalDeadline(
      country: 'Latvia',
      countryCode: 'LV',
      caseType: 'tenant',
      action: 'response',
      days: 30,
      authority: 'Rajona (pilsētas) tiesa',
      legalBasis: 'Civillikums; CPL 402. pants',
      description: 'Response to eviction claim',
    ),
    LegalDeadline(
      country: 'Latvia',
      countryCode: 'LV',
      caseType: 'criminal',
      action: 'complaint',
      days: 0,
      authority: 'Valsts policija (Police) or Prokuratūra',
      legalBasis: 'Krimināllikums; Kriminālprocesa likums 371. pants',
      description: 'Criminal complaint — no formal deadline for public offenses',
      notes: 'Private prosecution offenses: 30 days to file application with court.',
    ),
    LegalDeadline(
      country: 'Latvia',
      countryCode: 'LV',
      caseType: 'administrative',
      action: 'appeal',
      days: 30,
      authority: 'Administratīvā rajona tiesa',
      legalBasis: 'Administratīvā procesa likums 188. pants',
      description: 'Application to administrative court challenging administrative act',
      notes: '1 month from the day the act takes effect or notification.',
    ),

    // =========================================================================
    // LITHUANIA (LT)
    // =========================================================================
    LegalDeadline(
      country: 'Lithuania',
      countryCode: 'LT',
      caseType: 'deportation',
      action: 'appeal',
      days: 14,
      authority: 'Vilniaus apygardos administracinis teismas (Vilnius Regional Administrative Court)',
      legalBasis: 'Užsieniečių teisinės padėties įstatymas, 140 str.',
      description: 'Appeal against expulsion/return decision',
      notes: '14 days from notification.',
    ),
    LegalDeadline(
      country: 'Lithuania',
      countryCode: 'LT',
      caseType: 'asylum',
      action: 'application',
      days: 0,
      authority: 'Migracijos departamentas (Migration Department)',
      legalBasis: 'Prieglobsčio Lietuvos Respublikoje įstatymas, 67 str.',
      description: 'Asylum application — no fixed deadline',
    ),
    LegalDeadline(
      country: 'Lithuania',
      countryCode: 'LT',
      caseType: 'asylum',
      action: 'appeal',
      days: 14,
      authority: 'Vilniaus apygardos administracinis teismas',
      legalBasis: 'Prieglobsčio įstatymas 81 str.',
      description: 'Appeal against refusal of asylum',
      notes: '14 days from notification. 7 days for accelerated procedures.',
    ),
    LegalDeadline(
      country: 'Lithuania',
      countryCode: 'LT',
      caseType: 'labor',
      action: 'complaint',
      days: 30,
      authority: 'Darbo ginčų komisija (Labor Disputes Commission)',
      legalBasis: 'Darbo kodeksas, 220 str.',
      description: 'Challenge against dismissal before Labor Disputes Commission',
      notes: '1 month from dismissal. Commission decides within 14 days. Court appeal: 1 month.',
    ),
    LegalDeadline(
      country: 'Lithuania',
      countryCode: 'LT',
      caseType: 'tenant',
      action: 'response',
      days: 20,
      authority: 'Apylinkės teismas (District Court)',
      legalBasis: 'Civilinio proceso kodeksas, 142 str.',
      description: 'Written response to eviction claim',
    ),
    LegalDeadline(
      country: 'Lithuania',
      countryCode: 'LT',
      caseType: 'criminal',
      action: 'complaint',
      days: 0,
      authority: 'Policija or Prokuratūra',
      legalBasis: 'Baudžiamojo proceso kodeksas, 167 str.',
      description: 'Criminal complaint — no formal deadline for public offenses',
      notes: 'Private prosecution: complaint deadline set by individual statute.',
    ),
    LegalDeadline(
      country: 'Lithuania',
      countryCode: 'LT',
      caseType: 'administrative',
      action: 'appeal',
      days: 30,
      authority: 'Administracinis teismas',
      legalBasis: 'Administracinių bylų teisenos įstatymas, 29 str.',
      description: 'Complaint to administrative court against administrative decision',
      notes: '1 month from notification or publication.',
    ),

    // =========================================================================
    // LUXEMBOURG (LU)
    // =========================================================================
    LegalDeadline(
      country: 'Luxembourg',
      countryCode: 'LU',
      caseType: 'deportation',
      action: 'appeal',
      days: 30,
      authority: 'Tribunal administratif',
      legalBasis: 'Loi du 29 août 2008, Art. 36-39',
      description: 'Recours against return decision (décision de retour)',
      notes: '3 months for some administrative decisions. 15 days for detention cases.',
    ),
    LegalDeadline(
      country: 'Luxembourg',
      countryCode: 'LU',
      caseType: 'asylum',
      action: 'application',
      days: 0,
      authority: 'Direction de l\'immigration',
      legalBasis: 'Loi du 18 décembre 2015, Art. 6',
      description: 'Asylum application — no fixed deadline',
    ),
    LegalDeadline(
      country: 'Luxembourg',
      countryCode: 'LU',
      caseType: 'asylum',
      action: 'appeal',
      days: 30,
      authority: 'Tribunal administratif',
      legalBasis: 'Loi du 18 décembre 2015, Art. 35',
      description: 'Appeal against negative asylum decision',
      notes: '15 days for inadmissibility and accelerated procedure decisions.',
    ),
    LegalDeadline(
      country: 'Luxembourg',
      countryCode: 'LU',
      caseType: 'labor',
      action: 'complaint',
      days: 90,
      authority: 'Tribunal du travail',
      legalBasis: 'Code du travail, Art. L.124-11',
      description: 'Challenge against abusive dismissal (licenciement abusif)',
      notes: '3 months from notification of dismissal.',
    ),
    LegalDeadline(
      country: 'Luxembourg',
      countryCode: 'LU',
      caseType: 'tenant',
      action: 'response',
      days: 15,
      authority: 'Justice de Paix',
      legalBasis: 'Loi du 21 septembre 2006 sur le bail à usage d\'habitation',
      description: 'Response to eviction proceedings',
    ),
    LegalDeadline(
      country: 'Luxembourg',
      countryCode: 'LU',
      caseType: 'criminal',
      action: 'complaint',
      days: 90,
      authority: 'Police or Parquet (Prosecutor)',
      legalBasis: 'Code de procédure pénale; Code pénal',
      description: 'Plainte for complaint-based offenses: 3 months',
      notes: 'Public prosecution offenses: no complaint deadline.',
    ),
    LegalDeadline(
      country: 'Luxembourg',
      countryCode: 'LU',
      caseType: 'administrative',
      action: 'appeal',
      days: 90,
      authority: 'Tribunal administratif',
      legalBasis: 'Loi du 7 novembre 1996, Art. 13',
      description: 'Recours en annulation / reformation of administrative decisions',
      notes: '3 months from notification.',
    ),

    // =========================================================================
    // MALTA (MT)
    // =========================================================================
    LegalDeadline(
      country: 'Malta',
      countryCode: 'MT',
      caseType: 'deportation',
      action: 'appeal',
      days: 3,
      authority: 'Immigration Appeals Board',
      legalBasis: 'Immigration Act Cap. 217, Art. 25A',
      description: 'Appeal against removal order',
      notes: '3 working days from notification. One of the shortest in the EU.',
    ),
    LegalDeadline(
      country: 'Malta',
      countryCode: 'MT',
      caseType: 'asylum',
      action: 'application',
      days: 0,
      authority: 'Office of the Refugee Commissioner / International Protection Agency',
      legalBasis: 'Refugees Act Cap. 420, Art. 8',
      description: 'Asylum application — no fixed deadline',
    ),
    LegalDeadline(
      country: 'Malta',
      countryCode: 'MT',
      caseType: 'asylum',
      action: 'appeal',
      days: 15,
      authority: 'Refugee Appeals Board',
      legalBasis: 'International Protection Act Cap. 420, Art. 7(2)',
      description: 'Appeal against negative asylum decision',
      notes: '15 days from notification.',
    ),
    LegalDeadline(
      country: 'Malta',
      countryCode: 'MT',
      caseType: 'labor',
      action: 'complaint',
      days: 120,
      authority: 'Industrial Tribunal',
      legalBasis: 'Employment and Industrial Relations Act Cap. 452, Art. 81',
      description: 'Claim for unfair dismissal',
      notes: '4 months from date of termination.',
    ),
    LegalDeadline(
      country: 'Malta',
      countryCode: 'MT',
      caseType: 'tenant',
      action: 'response',
      days: 20,
      authority: 'Rent Regulation Board or Civil Court',
      legalBasis: 'Civil Code Cap. 16; Housing Authority Act',
      description: 'Response to eviction proceedings',
    ),
    LegalDeadline(
      country: 'Malta',
      countryCode: 'MT',
      caseType: 'criminal',
      action: 'complaint',
      days: 90,
      authority: 'Malta Police Force or Attorney General',
      legalBasis: 'Criminal Code Cap. 9, Art. 543',
      description: 'Criminal complaint — 3 months for private complaint offenses',
    ),
    LegalDeadline(
      country: 'Malta',
      countryCode: 'MT',
      caseType: 'administrative',
      action: 'appeal',
      days: 20,
      workingDays: true,
      authority: 'Administrative Review Tribunal or Court',
      legalBasis: 'Code of Organization and Civil Procedure Cap. 12',
      description: 'Appeal against administrative decisions',
    ),

    // =========================================================================
    // NETHERLANDS (NL)
    // =========================================================================
    LegalDeadline(
      country: 'Netherlands',
      countryCode: 'NL',
      caseType: 'deportation',
      action: 'appeal',
      days: 28,
      authority: 'Rechtbank Den Haag, zittingsplaats (District Court The Hague)',
      legalBasis: 'Vreemdelingenwet 2000 Art. 69(1); Algemene wet bestuursrecht (Awb) 6:7',
      description: 'Bezwaar/Beroep against return decision',
      notes: '4 weeks from notification. 1 week for AA-procedure (accelerated asylum).',
    ),
    LegalDeadline(
      country: 'Netherlands',
      countryCode: 'NL',
      caseType: 'asylum',
      action: 'application',
      days: 0,
      authority: 'IND (Immigratie- en Naturalisatiedienst)',
      legalBasis: 'Vreemdelingenwet 2000 Art. 28',
      description: 'Asylum application — apply at Schiphol or registration center (Aanmeldcentrum Ter Apel)',
    ),
    LegalDeadline(
      country: 'Netherlands',
      countryCode: 'NL',
      caseType: 'asylum',
      action: 'appeal',
      days: 7,
      authority: 'Rechtbank Den Haag, zittingsplaats',
      legalBasis: 'Vreemdelingenwet 2000 Art. 69(2)',
      description: 'Appeal against negative asylum decision in accelerated (AA) procedure',
      notes: '1 week for AA procedure. 4 weeks for extended procedure (VA). Dublin: 1 week.',
    ),
    LegalDeadline(
      country: 'Netherlands',
      countryCode: 'NL',
      caseType: 'labor',
      action: 'complaint',
      days: 60,
      authority: 'Kantonrechter (Subdistrict Court) or UWV',
      legalBasis: 'Burgerlijk Wetboek Art. 7:686a(4)',
      description: 'Challenge against dismissal (verzoekschrift vernietiging opzegging)',
      notes: '2 months from date of termination. Request to UWV: within 4 weeks in certain cases.',
    ),
    LegalDeadline(
      country: 'Netherlands',
      countryCode: 'NL',
      caseType: 'tenant',
      action: 'response',
      days: 42,
      authority: 'Kantonrechter (Subdistrict Court)',
      legalBasis: 'BW Art. 7:272; Rv Art. 111',
      description: 'Response to eviction proceedings — court determines deadline in summons (typically 6 weeks)',
      notes: 'Tenant must explicitly reject the termination within 6 weeks or it becomes final.',
    ),
    LegalDeadline(
      country: 'Netherlands',
      countryCode: 'NL',
      caseType: 'criminal',
      action: 'complaint',
      days: 90,
      authority: 'Politie (Police) or Officier van Justitie (Prosecutor)',
      legalBasis: 'Wetboek van Strafrecht Art. 66; Sv Art. 163-165',
      description: 'Klachtdelicten (complaint offenses): 3 months from knowledge of offense',
    ),
    LegalDeadline(
      country: 'Netherlands',
      countryCode: 'NL',
      caseType: 'administrative',
      action: 'appeal',
      days: 42,
      authority: 'Rechtbank (District Court, Administrative Division)',
      legalBasis: 'Algemene wet bestuursrecht (Awb) Art. 6:7',
      description: 'Bezwaar (objection): 6 weeks. Beroep (appeal): 6 weeks',
      notes: '6 weeks from publication or notification of decision.',
    ),

    // =========================================================================
    // POLAND (PL)
    // =========================================================================
    LegalDeadline(
      country: 'Poland',
      countryCode: 'PL',
      caseType: 'deportation',
      action: 'appeal',
      days: 14,
      authority: 'Szef Urzędu do Spraw Cudzoziemców (Head of Office for Foreigners)',
      legalBasis: 'Ustawa o cudzoziemcach Art. 311-315',
      description: 'Odwołanie (appeal) against return decision (decyzja o zobowiązaniu do powrotu)',
      notes: '14 days from service. Judicial review: 30 days to WSA.',
    ),
    LegalDeadline(
      country: 'Poland',
      countryCode: 'PL',
      caseType: 'asylum',
      action: 'application',
      days: 0,
      authority: 'Szef Urzędu do Spraw Cudzoziemców / Border Guard',
      legalBasis: 'Ustawa o udzielaniu cudzoziemcom ochrony Art. 24',
      description: 'Asylum application — no fixed deadline',
    ),
    LegalDeadline(
      country: 'Poland',
      countryCode: 'PL',
      caseType: 'asylum',
      action: 'appeal',
      days: 14,
      authority: 'Rada do Spraw Uchodźców (Refugee Board)',
      legalBasis: 'Ustawa o udzielaniu ochrony Art. 41',
      description: 'Appeal against negative asylum decision',
      notes: '14 days from service.',
    ),
    LegalDeadline(
      country: 'Poland',
      countryCode: 'PL',
      caseType: 'labor',
      action: 'complaint',
      days: 21,
      authority: 'Sąd Rejonowy — Sąd Pracy (District Court — Labor Division)',
      legalBasis: 'Kodeks pracy Art. 264',
      description: 'Odwołanie against dismissal notice (wypowiedzenie) or termination without notice',
      notes: '21 days from service of notice/termination.',
    ),
    LegalDeadline(
      country: 'Poland',
      countryCode: 'PL',
      caseType: 'tenant',
      action: 'response',
      days: 14,
      authority: 'Sąd Rejonowy (District Court)',
      legalBasis: 'KPC Art. 4801-4804; Ustawa o ochronie praw lokatorów',
      description: 'Response to eviction claim',
    ),
    LegalDeadline(
      country: 'Poland',
      countryCode: 'PL',
      caseType: 'criminal',
      action: 'complaint',
      days: 0,
      authority: 'Prokuratura (Prosecution) or Policja',
      legalBasis: 'Kodeks postępowania karnego Art. 304-306',
      description: 'Criminal complaint — no formal deadline for public offenses',
      notes: 'Private prosecution: within limitation period. Complaint offenses: 30 days.',
    ),
    LegalDeadline(
      country: 'Poland',
      countryCode: 'PL',
      caseType: 'administrative',
      action: 'appeal',
      days: 14,
      authority: 'Organ wyższego stopnia / Samorządowe Kolegium Odwoławcze',
      legalBasis: 'Kodeks postępowania administracyjnego Art. 129§2',
      description: 'Odwołanie against administrative decision',
      notes: '14 days from service. Court (WSA): 30 days from service of second-instance decision.',
    ),

    // =========================================================================
    // PORTUGAL (PT)
    // =========================================================================
    LegalDeadline(
      country: 'Portugal',
      countryCode: 'PT',
      caseType: 'deportation',
      action: 'appeal',
      days: 20,
      authority: 'Tribunal Administrativo e Fiscal (Administrative and Tax Court)',
      legalBasis: 'Lei 23/2007 Art. 145; CPTA Art. 58',
      description: 'Recurso against expulsion decision',
      notes: '20 days for urgent procedures. Standard: 3 months for administrative action.',
    ),
    LegalDeadline(
      country: 'Portugal',
      countryCode: 'PT',
      caseType: 'asylum',
      action: 'application',
      days: 0,
      authority: 'SEF (Serviço de Estrangeiros e Fronteiras) / AIMA',
      legalBasis: 'Lei 27/2008 Art. 13',
      description: 'Asylum application — no fixed deadline',
    ),
    LegalDeadline(
      country: 'Portugal',
      countryCode: 'PT',
      caseType: 'asylum',
      action: 'appeal',
      days: 15,
      authority: 'Tribunal Administrativo de Círculo de Lisboa',
      legalBasis: 'Lei 27/2008 Art. 22',
      description: 'Appeal against negative asylum decision (impugnação judicial)',
      notes: '15 days from notification. 4 days for inadmissibility decisions.',
    ),
    LegalDeadline(
      country: 'Portugal',
      countryCode: 'PT',
      caseType: 'labor',
      action: 'complaint',
      days: 60,
      authority: 'Tribunal do Trabalho (Labor Court)',
      legalBasis: 'Código do Trabalho Art. 387',
      description: 'Ação de impugnação de despedimento (challenge against dismissal)',
      notes: '60 days from receipt of dismissal decision. Extended procedures available.',
    ),
    LegalDeadline(
      country: 'Portugal',
      countryCode: 'PT',
      caseType: 'tenant',
      action: 'response',
      days: 15,
      authority: 'Tribunal Judicial de Comarca / Balcão Nacional do Arrendamento (BNA)',
      legalBasis: 'NRAU (Lei 6/2006) Art. 15; CPC Art. 569',
      description: 'Oposição to eviction proceedings (especial de despejo)',
      notes: '15 days for BNA procedure.',
    ),
    LegalDeadline(
      country: 'Portugal',
      countryCode: 'PT',
      caseType: 'criminal',
      action: 'complaint',
      days: 180,
      authority: 'Ministério Público or Polícia (PSP/GNR)',
      legalBasis: 'Código Penal Art. 115; CPP Art. 113',
      description: 'Queixa (complaint) for semi-public crimes: 6 months from knowledge of offense',
      notes: 'Public crimes: no complaint deadline.',
    ),
    LegalDeadline(
      country: 'Portugal',
      countryCode: 'PT',
      caseType: 'administrative',
      action: 'appeal',
      days: 90,
      authority: 'Tribunal Administrativo e Fiscal',
      legalBasis: 'CPTA Art. 58',
      description: 'Ação administrativa against administrative act',
      notes: '3 months from notification or knowledge. Urgent: 1 month.',
    ),

    // =========================================================================
    // ROMANIA (RO)
    // =========================================================================
    LegalDeadline(
      country: 'Romania',
      countryCode: 'RO',
      caseType: 'deportation',
      action: 'appeal',
      days: 10,
      authority: 'Curtea de Apel (Court of Appeal)',
      legalBasis: 'OUG 194/2002 Art. 85-86',
      description: 'Contestație against expulsion/return measure',
      notes: '10 days from communication. Court decides within 5 days.',
    ),
    LegalDeadline(
      country: 'Romania',
      countryCode: 'RO',
      caseType: 'asylum',
      action: 'application',
      days: 0,
      authority: 'Inspectoratul General pentru Imigrări (IGI)',
      legalBasis: 'Legea 122/2006 Art. 38',
      description: 'Asylum application — no fixed deadline',
    ),
    LegalDeadline(
      country: 'Romania',
      countryCode: 'RO',
      caseType: 'asylum',
      action: 'appeal',
      days: 15,
      authority: 'Judecătoria / Tribunalul',
      legalBasis: 'Legea 122/2006 Art. 76',
      description: 'Appeal against negative asylum decision',
      notes: '15 days from communication. 7 days for accelerated procedure.',
    ),
    LegalDeadline(
      country: 'Romania',
      countryCode: 'RO',
      caseType: 'labor',
      action: 'complaint',
      days: 45,
      authority: 'Tribunalul (Tribunal)',
      legalBasis: 'Codul Muncii Art. 268',
      description: 'Contestație against dismissal decision',
      notes: '45 calendar days from communication of decision.',
    ),
    LegalDeadline(
      country: 'Romania',
      countryCode: 'RO',
      caseType: 'tenant',
      action: 'response',
      days: 25,
      authority: 'Judecătorie (First Instance Court)',
      legalBasis: 'Codul de procedură civilă Art. 201; Legea 114/1996',
      description: 'Întâmpinare (written defense) in eviction proceedings',
      notes: '25 days from service of summons.',
    ),
    LegalDeadline(
      country: 'Romania',
      countryCode: 'RO',
      caseType: 'criminal',
      action: 'complaint',
      days: 90,
      authority: 'Parchet (Prosecutor) or Poliție',
      legalBasis: 'Codul penal Art. 296; CPP Art. 295',
      description: 'Plângere prealabilă (prior complaint) for complaint offenses: 3 months from knowledge',
      notes: 'Public offenses: no complaint deadline.',
    ),
    LegalDeadline(
      country: 'Romania',
      countryCode: 'RO',
      caseType: 'administrative',
      action: 'appeal',
      days: 30,
      authority: 'Tribunalul — secția de contencios administrativ',
      legalBasis: 'Legea 554/2004 Art. 7, 11',
      description: 'Plângere prealabilă: 30 days. Court action: 6 months from response/30 days from silence',
      notes: 'Must first file preliminary complaint within 30 days, then court within 6 months.',
    ),

    // =========================================================================
    // SLOVAKIA (SK)
    // =========================================================================
    LegalDeadline(
      country: 'Slovakia',
      countryCode: 'SK',
      caseType: 'deportation',
      action: 'appeal',
      days: 15,
      authority: 'Krajský súd (Regional Court)',
      legalBasis: 'Zákon 404/2011 o pobyte cudzincov § 84; SSP § 181',
      description: 'Správna žaloba against expulsion decision',
      notes: '15 days. Short deadline; legal aid may extend.',
    ),
    LegalDeadline(
      country: 'Slovakia',
      countryCode: 'SK',
      caseType: 'asylum',
      action: 'application',
      days: 0,
      authority: 'Migračný úrad MV SR (Migration Office)',
      legalBasis: 'Zákon 480/2002 o azyle § 3',
      description: 'Asylum application — no fixed deadline',
    ),
    LegalDeadline(
      country: 'Slovakia',
      countryCode: 'SK',
      caseType: 'asylum',
      action: 'appeal',
      days: 20,
      authority: 'Krajský súd v Bratislave (Regional Court in Bratislava)',
      legalBasis: 'Zákon o azyle § 21; SSP § 175',
      description: 'Appeal against negative asylum decision',
      notes: '20 days from delivery. 7 days for accelerated procedure.',
    ),
    LegalDeadline(
      country: 'Slovakia',
      countryCode: 'SK',
      caseType: 'labor',
      action: 'complaint',
      days: 60,
      authority: 'Okresný súd (District Court)',
      legalBasis: 'Zákonník práce § 77',
      description: 'Žaloba against invalid termination of employment',
      notes: '2 months from date when employment was to end.',
    ),
    LegalDeadline(
      country: 'Slovakia',
      countryCode: 'SK',
      caseType: 'tenant',
      action: 'response',
      days: 15,
      authority: 'Okresný súd (District Court)',
      legalBasis: 'Občiansky zákonník § 710-714; CSP § 167',
      description: 'Response to eviction action',
    ),
    LegalDeadline(
      country: 'Slovakia',
      countryCode: 'SK',
      caseType: 'criminal',
      action: 'complaint',
      days: 0,
      authority: 'Polícia or Prokuratúra',
      legalBasis: 'Trestný poriadok § 196; Trestný zákon § 87',
      description: 'Criminal complaint — no formal deadline for public offenses',
      notes: 'Consent-based offenses: within limitation periods.',
    ),
    LegalDeadline(
      country: 'Slovakia',
      countryCode: 'SK',
      caseType: 'administrative',
      action: 'appeal',
      days: 60,
      authority: 'Krajský súd (Regional Court)',
      legalBasis: 'Správny súdny poriadok (SSP) § 181(1)',
      description: 'Správna žaloba against administrative decision',
      notes: '2 months from delivery of the decision.',
    ),

    // =========================================================================
    // SLOVENIA (SI)
    // =========================================================================
    LegalDeadline(
      country: 'Slovenia',
      countryCode: 'SI',
      caseType: 'deportation',
      action: 'appeal',
      days: 8,
      authority: 'Upravno sodišče (Administrative Court)',
      legalBasis: 'Zakon o tujcih (ZTuj-2) Art. 69; ZUS-1 Art. 22',
      description: 'Tožba against removal order',
      notes: '8 days in certain accelerated removal cases. Standard: 15 days.',
    ),
    LegalDeadline(
      country: 'Slovenia',
      countryCode: 'SI',
      caseType: 'asylum',
      action: 'application',
      days: 0,
      authority: 'Urad za migracije (Office for Migration)',
      legalBasis: 'Zakon o mednarodni zaščiti (ZMZ-1) Art. 35',
      description: 'Asylum application — no fixed deadline',
    ),
    LegalDeadline(
      country: 'Slovenia',
      countryCode: 'SI',
      caseType: 'asylum',
      action: 'appeal',
      days: 15,
      authority: 'Upravno sodišče (Administrative Court)',
      legalBasis: 'ZMZ-1 Art. 70',
      description: 'Appeal against negative asylum decision',
      notes: '15 days standard. 8 days for accelerated procedures. 3 days for safe country of origin.',
    ),
    LegalDeadline(
      country: 'Slovenia',
      countryCode: 'SI',
      caseType: 'labor',
      action: 'complaint',
      days: 30,
      authority: 'Delovno in socialno sodišče (Labor and Social Court)',
      legalBasis: 'Zakon o delovnih razmerjih (ZDR-1) Art. 200',
      description: 'Challenge against dismissal (tožba za ugotovitev nezakonitosti odpovedi)',
      notes: '30 days from service of dismissal. Must serve employer with written request first (within 8 days).',
    ),
    LegalDeadline(
      country: 'Slovenia',
      countryCode: 'SI',
      caseType: 'tenant',
      action: 'response',
      days: 30,
      authority: 'Okrajno sodišče (Local Court)',
      legalBasis: 'ZPP Art. 277; Stanovanjski zakon',
      description: 'Response to eviction claim',
    ),
    LegalDeadline(
      country: 'Slovenia',
      countryCode: 'SI',
      caseType: 'criminal',
      action: 'complaint',
      days: 90,
      authority: 'Policija or Državno tožilstvo (State Prosecutor)',
      legalBasis: 'Kazenski zakonik Art. 96; ZKP Art. 52',
      description: 'Zasebna tožba (private prosecution): 3 months from knowledge of offense and offender',
      notes: 'Predlog za pregon (prosecution request): same deadline.',
    ),
    LegalDeadline(
      country: 'Slovenia',
      countryCode: 'SI',
      caseType: 'administrative',
      action: 'appeal',
      days: 30,
      authority: 'Upravno sodišče (Administrative Court)',
      legalBasis: 'Zakon o upravnem sporu (ZUS-1) Art. 22',
      description: 'Tožba against administrative decision',
      notes: '30 days from service. Must exhaust administrative appeals first.',
    ),

    // =========================================================================
    // SPAIN (ES)
    // =========================================================================
    LegalDeadline(
      country: 'Spain',
      countryCode: 'ES',
      caseType: 'deportation',
      action: 'appeal',
      days: 30,
      authority: 'Juzgado de lo Contencioso-Administrativo',
      legalBasis: 'LO 4/2000 Art. 21; LJCA Art. 46',
      description: 'Recurso contencioso-administrativo against expulsion order',
      notes: '48 hours for emergency interim measures. 10 days potestative administrative appeal first.',
    ),
    LegalDeadline(
      country: 'Spain',
      countryCode: 'ES',
      caseType: 'asylum',
      action: 'application',
      days: 30,
      authority: 'Oficina de Asilo y Refugio (OAR)',
      legalBasis: 'Ley 12/2009 Art. 17',
      description: 'Asylum application — should be filed within 1 month of arrival',
      notes: 'Late filing does not automatically bar the claim but may affect assessment.',
    ),
    LegalDeadline(
      country: 'Spain',
      countryCode: 'ES',
      caseType: 'asylum',
      action: 'appeal',
      days: 60,
      authority: 'Audiencia Nacional',
      legalBasis: 'Ley 12/2009 Art. 29; LJCA Art. 46',
      description: 'Recurso contencioso against negative asylum decision',
      notes: '1 month for potestative reposición. 2 months for contencioso appeal.',
    ),
    LegalDeadline(
      country: 'Spain',
      countryCode: 'ES',
      caseType: 'labor',
      action: 'complaint',
      days: 20,
      workingDays: true,
      authority: 'Juzgado de lo Social',
      legalBasis: 'Estatuto de los Trabajadores Art. 59(3); LRJS Art. 103',
      description: 'Demanda por despido improcedente — challenge against unfair dismissal',
      notes: '20 working days from date of dismissal. Must first file conciliation (papeleta) which suspends the deadline.',
    ),
    LegalDeadline(
      country: 'Spain',
      countryCode: 'ES',
      caseType: 'tenant',
      action: 'response',
      days: 10,
      authority: 'Juzgado de Primera Instancia',
      legalBasis: 'LEC Art. 440; LAU Art. 22',
      description: 'Oposición to eviction proceedings (desahucio)',
      notes: '10 days to oppose or pay. After 2013 reform, social services notified.',
    ),
    LegalDeadline(
      country: 'Spain',
      countryCode: 'ES',
      caseType: 'criminal',
      action: 'complaint',
      days: 180,
      authority: 'Policía, Guardia Civil, or Juzgado de Instrucción',
      legalBasis: 'LECrim Art. 259-269; CP Art. 131',
      description: 'Denuncia/querella — no formal complaint deadline for public offenses',
      notes: 'Delitos semipúblicos (e.g., injuries): 6 months. Calumnia/injuria: 6 months.',
    ),
    LegalDeadline(
      country: 'Spain',
      countryCode: 'ES',
      caseType: 'administrative',
      action: 'appeal',
      days: 30,
      authority: 'Juzgado/Tribunal de lo Contencioso-Administrativo',
      legalBasis: 'LJCA Art. 46; LPAC Art. 122-124',
      description: 'Recurso de alzada: 1 month. Contencioso-administrativo: 2 months',
      notes: 'Potestative reposición: 1 month. Against silence: 6 months.',
    ),

    // =========================================================================
    // SWEDEN (SE)
    // =========================================================================
    LegalDeadline(
      country: 'Sweden',
      countryCode: 'SE',
      caseType: 'deportation',
      action: 'appeal',
      days: 21,
      authority: 'Migrationsdomstol (Migration Court)',
      legalBasis: 'Utlänningslag (2005:716) 14 kap. 7§',
      description: 'Överklagande against deportation/refusal of entry decision',
      notes: '3 weeks from service of decision.',
    ),
    LegalDeadline(
      country: 'Sweden',
      countryCode: 'SE',
      caseType: 'asylum',
      action: 'application',
      days: 0,
      authority: 'Migrationsverket (Migration Agency)',
      legalBasis: 'Utlänningslag 5 kap. 1§',
      description: 'Asylum application — no fixed deadline, apply at Migration Agency or border',
    ),
    LegalDeadline(
      country: 'Sweden',
      countryCode: 'SE',
      caseType: 'asylum',
      action: 'appeal',
      days: 21,
      authority: 'Migrationsdomstol (Migration Court)',
      legalBasis: 'Utlänningslag 14 kap. 7§',
      description: 'Appeal against negative asylum decision',
      notes: '3 weeks from service of decision.',
    ),
    LegalDeadline(
      country: 'Sweden',
      countryCode: 'SE',
      caseType: 'labor',
      action: 'complaint',
      days: 14,
      authority: 'Tingsrätt (District Court) or Arbetsdomstolen (Labor Court)',
      legalBasis: 'Lagen om anställningsskydd (LAS) § 40',
      description: 'Ogiltigförklaring of dismissal — must notify employer within 14 days',
      notes: 'Then file court action within 14 additional days (28 days total). Damages only: 4 months.',
    ),
    LegalDeadline(
      country: 'Sweden',
      countryCode: 'SE',
      caseType: 'tenant',
      action: 'response',
      days: 21,
      authority: 'Hyresnämnden (Rent Tribunal)',
      legalBasis: 'Jordabalken 12 kap. 49§, 58§',
      description: 'Tenant must refer to hyresnämnden within 3 weeks for extension of lease',
      notes: 'If landlord terminates: tenant must apply to Rent Tribunal before lease expires.',
    ),
    LegalDeadline(
      country: 'Sweden',
      countryCode: 'SE',
      caseType: 'criminal',
      action: 'complaint',
      days: 180,
      authority: 'Polisen (Police) or Åklagarmyndigheten (Prosecution Authority)',
      legalBasis: 'Brottsbalken 35 kap.; RB 20 kap.',
      description: 'Angivelse for complaint offenses (angivelsebrott): 6 months from knowledge',
      notes: 'Enskilt åtal (private prosecution): 6 months from becoming aware.',
    ),
    LegalDeadline(
      country: 'Sweden',
      countryCode: 'SE',
      caseType: 'administrative',
      action: 'appeal',
      days: 21,
      authority: 'Förvaltningsrätt (Administrative Court)',
      legalBasis: 'Förvaltningsprocesslag (1971:291) 6a§; FL 44§',
      description: 'Överklagande against administrative decision',
      notes: '3 weeks from service of decision.',
    ),

    // =========================================================================
    // ADDITIONAL EU MEMBER STATES
    // =========================================================================

    // =========================================================================
    // CZECH REPUBLIC already covered above
    // DENMARK already covered above
    // =========================================================================

    // No, let me continue with remaining countries not yet included:

    // =========================================================================
    // SLOVAKIA already covered above
    // SLOVENIA already covered above
    // =========================================================================

    // Remaining: None — all 27 covered above. Let me verify:
    // AT, BE, BG, HR, CY, CZ, DK, EE, FI, FR, DE, GR, HU, IE, IT,
    // LV, LT, LU, MT, NL, PL, PT, RO, SK, SI, ES, SE = 27 countries

  ];
}

// =============================================================================
// HELPER: DEADLINE CALCULATOR
// =============================================================================

class DeadlineCalculator {
  /// Calculate the actual deadline date from a notification date
  static DateTime calculateDeadline(
    DateTime notificationDate,
    LegalDeadline deadline,
  ) {
    if (deadline.workingDays) {
      return _addWorkingDays(notificationDate, deadline.days);
    }
    return notificationDate.add(Duration(days: deadline.days));
  }

  /// Calculate remaining days until a deadline
  static int remainingDays(
    DateTime notificationDate,
    LegalDeadline deadline, {
    DateTime? currentDate,
  }) {
    final now = currentDate ?? DateTime.now();
    final deadlineDate = calculateDeadline(notificationDate, deadline);
    return deadlineDate.difference(now).inDays;
  }

  /// Check if a deadline has passed
  static bool isExpired(
    DateTime notificationDate,
    LegalDeadline deadline, {
    DateTime? currentDate,
  }) {
    return remainingDays(notificationDate, deadline, currentDate: currentDate) < 0;
  }

  /// Get urgency level: 'expired', 'critical', 'urgent', 'warning', 'normal'
  static String urgencyLevel(
    DateTime notificationDate,
    LegalDeadline deadline, {
    DateTime? currentDate,
  }) {
    final remaining = remainingDays(notificationDate, deadline, currentDate: currentDate);
    if (remaining < 0) return 'expired';
    if (remaining <= 3) return 'critical';
    if (remaining <= 7) return 'urgent';
    if (remaining <= 14) return 'warning';
    return 'normal';
  }

  /// Add working days (skip weekends)
  static DateTime _addWorkingDays(DateTime start, int days) {
    var current = start;
    var added = 0;
    while (added < days) {
      current = current.add(const Duration(days: 1));
      if (current.weekday != DateTime.saturday &&
          current.weekday != DateTime.sunday) {
        added++;
      }
    }
    return current;
  }
}

// =============================================================================
// DEADLINE SUMMARY FOR QUICK REFERENCE
// =============================================================================

/// Quick-reference map of deportation appeal deadlines (days) by country code.
/// Use DeadlineDatabase for full details including legal basis and authority.
const Map<String, int> deportationAppealDaysQuickRef = {
  'AT': 14,  // Austria
  'BE': 30,  // Belgium (10 if detained)
  'BG': 14,  // Bulgaria
  'HR': 8,   // Croatia
  'CY': 75,  // Cyprus
  'CZ': 10,  // Czech Republic
  'DK': 7,   // Denmark
  'EE': 10,  // Estonia
  'FI': 30,  // Finland
  'FR': 30,  // France (48h if detained, 15d if no departure period)
  'DE': 7,   // Germany (Eilantrag, 14 for Klage)
  'GR': 30,  // Greece
  'HU': 3,   // Hungary (!! extremely short)
  'IE': 14,  // Ireland
  'IT': 30,  // Italy
  'LV': 7,   // Latvia
  'LT': 14,  // Lithuania
  'LU': 30,  // Luxembourg
  'MT': 3,   // Malta (!! working days, extremely short)
  'NL': 28,  // Netherlands (7 for AA procedure)
  'PL': 14,  // Poland
  'PT': 20,  // Portugal
  'RO': 10,  // Romania
  'SK': 15,  // Slovakia
  'SI': 8,   // Slovenia (15 standard)
  'ES': 30,  // Spain
  'SE': 21,  // Sweden
};

/// Quick-reference: countries with critically short deportation appeal deadlines (7 days or less)
const List<String> criticallyShortDeportationDeadlines = [
  'HU',  // Hungary: 3 days
  'MT',  // Malta: 3 working days
  'DK',  // Denmark: 7 days
  'DE',  // Germany: 7 days (Eilantrag)
  'LV',  // Latvia: 7 days
];
