// Housing/Tenant Rights Database for all 27 EU Countries
// Real legal data for immigrant tenant protection
// Last updated: 2026-04
//
// Sources: EU Housing Rights Observatory, national tenant protection laws,
// FEANTSA (European Federation of National Organisations Working with the Homeless),
// national ombudsman offices, Eurofound housing reports.

class TenantRights {
  final String country;
  final String countryCode;
  final int maxRentIncreasePercent;
  final int evictionNoticeDays;
  final bool depositLimitExists;
  final int? maxDepositMonths;
  final String tenantProtectionAuthority;
  final String? tenantHotline;
  final List<String> tenantRights;
  final List<String> evictionProtections;
  final String legalBasis;
  final String emergencyContact;
  final bool courtOrderRequiredForEviction;
  final String rentControlRules;
  final String repairObligations;
  final String depositReturnRules;
  final String discriminationProtections;
  final String immigrantSpecificNotes;
  final String languageOfContracts;

  const TenantRights({
    required this.country,
    required this.countryCode,
    required this.maxRentIncreasePercent,
    required this.evictionNoticeDays,
    required this.depositLimitExists,
    this.maxDepositMonths,
    required this.tenantProtectionAuthority,
    this.tenantHotline,
    required this.tenantRights,
    required this.evictionProtections,
    required this.legalBasis,
    required this.emergencyContact,
    required this.courtOrderRequiredForEviction,
    required this.rentControlRules,
    required this.repairObligations,
    required this.depositReturnRules,
    required this.discriminationProtections,
    required this.immigrantSpecificNotes,
    required this.languageOfContracts,
  });

  Map<String, dynamic> toMap() {
    return {
      'country': country,
      'countryCode': countryCode,
      'maxRentIncreasePercent': maxRentIncreasePercent,
      'evictionNoticeDays': evictionNoticeDays,
      'depositLimitExists': depositLimitExists,
      'maxDepositMonths': maxDepositMonths,
      'tenantProtectionAuthority': tenantProtectionAuthority,
      'tenantHotline': tenantHotline,
      'tenantRights': tenantRights,
      'evictionProtections': evictionProtections,
      'legalBasis': legalBasis,
      'emergencyContact': emergencyContact,
      'courtOrderRequiredForEviction': courtOrderRequiredForEviction,
      'rentControlRules': rentControlRules,
      'repairObligations': repairObligations,
      'depositReturnRules': depositReturnRules,
      'discriminationProtections': discriminationProtections,
      'immigrantSpecificNotes': immigrantSpecificNotes,
      'languageOfContracts': languageOfContracts,
    };
  }
}

class HousingRightsDatabase {
  static final HousingRightsDatabase _instance =
      HousingRightsDatabase._internal();
  factory HousingRightsDatabase() => _instance;
  HousingRightsDatabase._internal();

  /// Get tenant rights for a specific country by country code (e.g. "FI", "DE")
  TenantRights? getByCountryCode(String code) {
    final upper = code.toUpperCase();
    try {
      return allCountries.firstWhere((c) => c.countryCode == upper);
    } catch (_) {
      return null;
    }
  }

  /// Get tenant rights by country name (case-insensitive, partial match)
  TenantRights? getByCountryName(String name) {
    final lower = name.toLowerCase();
    try {
      return allCountries
          .firstWhere((c) => c.country.toLowerCase().contains(lower));
    } catch (_) {
      return null;
    }
  }

  /// Search across all countries for a specific right or protection keyword
  List<TenantRights> searchByKeyword(String keyword) {
    final lower = keyword.toLowerCase();
    return allCountries.where((c) {
      return c.tenantRights.any((r) => r.toLowerCase().contains(lower)) ||
          c.evictionProtections.any((p) => p.toLowerCase().contains(lower)) ||
          c.rentControlRules.toLowerCase().contains(lower) ||
          c.repairObligations.toLowerCase().contains(lower) ||
          c.depositReturnRules.toLowerCase().contains(lower) ||
          c.discriminationProtections.toLowerCase().contains(lower);
    }).toList();
  }

  /// Get countries where court order is required for eviction
  List<TenantRights> countriesWithCourtOrderRequired() {
    return allCountries.where((c) => c.courtOrderRequiredForEviction).toList();
  }

  /// Get countries with rent control / regulation
  List<TenantRights> countriesWithRentControl() {
    return allCountries
        .where((c) =>
            !c.rentControlRules.toLowerCase().contains('no rent control') &&
            !c.rentControlRules.toLowerCase().contains('no formal rent control'))
        .toList();
  }

  /// Get countries with deposit limits
  List<TenantRights> countriesWithDepositLimits() {
    return allCountries.where((c) => c.depositLimitExists).toList();
  }

  /// Compare tenant protections between two countries
  Map<String, dynamic> compareCountries(String code1, String code2) {
    final c1 = getByCountryCode(code1);
    final c2 = getByCountryCode(code2);
    if (c1 == null || c2 == null) return {};
    return {
      'country1': c1.toMap(),
      'country2': c2.toMap(),
      'comparison': {
        'betterEvictionNotice':
            c1.evictionNoticeDays >= c2.evictionNoticeDays
                ? c1.country
                : c2.country,
        'lowerMaxDeposit': (c1.maxDepositMonths ?? 99) <=
                (c2.maxDepositMonths ?? 99)
            ? c1.country
            : c2.country,
        'courtOrderRequired': {
          c1.country: c1.courtOrderRequiredForEviction,
          c2.country: c2.courtOrderRequiredForEviction,
        },
      },
    };
  }

  /// Generate a plain-language summary of rights for a country (useful for chatbot)
  String generateSummary(String countryCode, {String language = 'en'}) {
    final c = getByCountryCode(countryCode);
    if (c == null) return 'Country not found.';

    final buffer = StringBuffer();
    buffer.writeln('TENANT RIGHTS IN ${c.country.toUpperCase()}');
    buffer.writeln('=' * 40);
    buffer.writeln();
    buffer.writeln(
        'Court order required for eviction: ${c.courtOrderRequiredForEviction ? "YES - landlord CANNOT evict you without a court order" : "NO - but legal process still applies"}');
    buffer.writeln(
        'Minimum eviction notice: ${c.evictionNoticeDays} days');
    buffer.writeln(
        'Maximum deposit: ${c.depositLimitExists ? "${c.maxDepositMonths} months rent" : "No legal limit (negotiate carefully!)"}');
    buffer.writeln(
        'Rent increase limit: ${c.maxRentIncreasePercent > 0 ? "${c.maxRentIncreasePercent}% per year (regulated)" : "Market-based (check contract)"}');
    buffer.writeln();
    buffer.writeln('KEY RIGHTS:');
    for (final right in c.tenantRights) {
      buffer.writeln('  - $right');
    }
    buffer.writeln();
    buffer.writeln('EVICTION PROTECTIONS:');
    for (final prot in c.evictionProtections) {
      buffer.writeln('  - $prot');
    }
    buffer.writeln();
    buffer.writeln('RENT CONTROL: ${c.rentControlRules}');
    buffer.writeln();
    buffer.writeln('REPAIR OBLIGATIONS: ${c.repairObligations}');
    buffer.writeln();
    buffer.writeln('DEPOSIT RETURN: ${c.depositReturnRules}');
    buffer.writeln();
    buffer.writeln(
        'DISCRIMINATION PROTECTIONS: ${c.discriminationProtections}');
    buffer.writeln();
    buffer.writeln('FOR IMMIGRANTS: ${c.immigrantSpecificNotes}');
    buffer.writeln();
    buffer.writeln('EMERGENCY CONTACT: ${c.emergencyContact}');
    buffer.writeln('AUTHORITY: ${c.tenantProtectionAuthority}');
    if (c.tenantHotline != null) {
      buffer.writeln('HOTLINE: ${c.tenantHotline}');
    }
    buffer.writeln('LEGAL BASIS: ${c.legalBasis}');

    return buffer.toString();
  }

  // ====================================================================
  // ALL 27 EU COUNTRIES - REAL DATA
  // ====================================================================

  static const List<TenantRights> allCountries = [
    // ----------------------------------------------------------------
    // 1. AUSTRIA (AT)
    // ----------------------------------------------------------------
    TenantRights(
      country: 'Austria',
      countryCode: 'AT',
      maxRentIncreasePercent: 5,
      evictionNoticeDays: 30,
      depositLimitExists: true,
      maxDepositMonths: 6,
      tenantProtectionAuthority:
          'Schlichtungsstelle (Arbitration Board) / Mieterschutzverband',
      tenantHotline: '+43 1 523 39 65',
      tenantRights: [
        'Right to written lease agreement',
        'Right to adequate heating and hot water',
        'Protection against excessive rent in regulated buildings (Richtwertmiete)',
        'Right to sublet with landlord consent',
        'Right to challenge rent at Schlichtungsstelle within 3 years',
        'Right to privacy - landlord must give 24h notice before entry',
        'Right to make minor improvements with landlord notification',
      ],
      evictionProtections: [
        'Eviction requires court order (Raeumungsklage)',
        'Judge must find legally valid reason (important grounds)',
        'Winter eviction ban: courts rarely enforce during Nov-Mar',
        'Families with children receive extended deadlines',
        'Tenant can cure rent arrears before judgment',
        'Fixed-term contracts auto-renew after 3 years if not terminated properly',
      ],
      legalBasis:
          'Mietrechtsgesetz (MRG) - Tenancy Law Act; ABGB sections 1090-1121',
      emergencyContact: '142 (Telefonseelsorge) / 01 4000-8040 (Vienna social services)',
      courtOrderRequiredForEviction: true,
      rentControlRules:
          'Regulated rent (Richtwertmiete) applies to pre-1945 buildings. Reference values set per m2 by federal state. Free-market rent for newer buildings but must be "reasonable" (ortsüblich). Rent increases tied to CPI index, capped review periods.',
      repairObligations:
          'Landlord must maintain structural elements, roof, facade, common areas, heating system, plumbing, and electrical. Tenant responsible for minor repairs inside apartment (light fixtures, faucet washers). Landlord must act within reasonable time or tenant can repair and deduct.',
      depositReturnRules:
          'Deposit max 6 months rent. Must be returned within 1-2 months after move-out. Landlord must provide itemized deductions. Deposit must be kept in separate interest-bearing account. If not returned, file at Bezirksgericht (district court).',
      discriminationProtections:
          'Gleichbehandlungsgesetz (Equal Treatment Act) prohibits discrimination in housing based on ethnicity, religion, nationality, gender, sexual orientation, age, disability. File complaints with Gleichbehandlungsanwaltschaft (Equality Ombudsman). EU nationals have equal access rights.',
      immigrantSpecificNotes:
          'EU/EEA citizens have equal housing rights. Third-country nationals need valid residence permit. Registration (Meldezettel) required within 3 days of moving. Social housing in Vienna open to residents with 2+ years of main residence. Free legal aid available for low-income tenants at Mietervereinigung.',
      languageOfContracts: 'German (translations not legally required but recommended)',
    ),

    // ----------------------------------------------------------------
    // 2. BELGIUM (BE)
    // ----------------------------------------------------------------
    TenantRights(
      country: 'Belgium',
      countryCode: 'BE',
      maxRentIncreasePercent: 0,
      evictionNoticeDays: 180,
      depositLimitExists: true,
      maxDepositMonths: 2,
      tenantProtectionAuthority:
          'Regional Housing Inspection Services / Justice de Paix (Peace Court)',
      tenantHotline: '+32 2 542 72 00 (Brussels Housing)',
      tenantRights: [
        'Right to written lease (mandatory registration with tax office)',
        'Right to habitable dwelling meeting regional quality standards',
        'Right to peaceful enjoyment without landlord interference',
        'Rent only adjustable annually by health index (indexation)',
        'Right to make tenant improvements with notification',
        'Right to terminate 9-year lease every 3 years with 6 months notice',
        'Right to request energy performance certificate (EPC)',
      ],
      evictionProtections: [
        'Court order required for all evictions',
        'Landlord must prove valid legal ground (non-payment, personal use, renovation)',
        'Minimum 6 months notice for no-fault eviction',
        'Compensation required: 9-18 months rent depending on timing',
        'Winter eviction moratorium in Brussels Region (Nov 1 - Mar 15)',
        'Judges can grant delays up to 1 year for vulnerable tenants',
      ],
      legalBasis:
          'Brussels: Code bruxellois du logement; Flanders: Vlaams Woninghuurdecreet (2019); Wallonia: Décret wallon bail d\'habitation (2018)',
      emergencyContact: '0800 120 33 (Brussels Housing Emergency)',
      courtOrderRequiredForEviction: true,
      rentControlRules:
          'Rent freely set at start of lease. Annual increases ONLY by health index (santé index). Regions can impose rent caps in certain zones. Brussels introduced indicative rent grid (grille indicative des loyers). No rent increase beyond index without major renovations.',
      repairObligations:
          'Landlord: structural repairs, roof, exterior walls, heating installation, plumbing, electrical system safety. Tenant: minor maintenance (door handles, light bulbs, seals). If landlord fails to repair, tenant can request court-ordered repairs or rent reduction. Emergency repairs: tenant can do immediately and deduct.',
      depositReturnRules:
          'Maximum 2 months rent (3 months if on bank guarantee). Must be placed on blocked bank account in both names. Return within 1 month of key handover if no disputes. Landlord must justify any deductions with evidence. If no response in 1 month, send registered letter, then file at Justice de Paix.',
      discriminationProtections:
          'Anti-discrimination laws (Loi Antidiscrimination 2007) prohibit housing discrimination based on nationality, ethnic origin, religion, disability, gender, sexual orientation. Interfederal Centre for Equal Opportunities (UNIA) handles complaints. Brussels and Flanders conduct discrimination testing (mystery calling). Fines up to EUR 1,375.',
      immigrantSpecificNotes:
          'All legal residents have equal housing rights regardless of nationality. Registration at commune required. Social housing waiting lists can be long (years). Free legal aid (bureau d\'aide juridique) available. Many NGOs provide housing assistance: Convivial, CIRÉ (Brussels), Vluchtelingenwerk (Flanders). Contracts in French, Dutch, or German depending on region.',
      languageOfContracts: 'French (Wallonia/Brussels), Dutch (Flanders), German (Eupen)',
    ),

    // ----------------------------------------------------------------
    // 3. BULGARIA (BG)
    // ----------------------------------------------------------------
    TenantRights(
      country: 'Bulgaria',
      countryCode: 'BG',
      maxRentIncreasePercent: 0,
      evictionNoticeDays: 30,
      depositLimitExists: false,
      maxDepositMonths: null,
      tenantProtectionAuthority:
          'Commission for Consumer Protection / Regional courts',
      tenantHotline: '+359 2 933 05 65 (Consumer Protection)',
      tenantRights: [
        'Right to written lease agreement (recommended, oral valid but hard to prove)',
        'Right to habitable dwelling',
        'Right to peaceful use of property',
        'Right to be informed of ownership changes',
        'Right to extend lease under same conditions if not terminated properly',
        'Right to deduct repair costs from rent if landlord fails to act',
      ],
      evictionProtections: [
        'Court order required for eviction of lawful tenant',
        'Self-help eviction (changing locks, cutting utilities) is illegal',
        'Tenant can contest eviction in court',
        'Eviction suspended during court proceedings',
        'Social services must be notified for families with minors',
      ],
      legalBasis:
          'Zakon za Zadalkheniyata i Dogovorite (Obligations and Contracts Act), Articles 228-239',
      emergencyContact: '112 (General emergency) / 02 981 76 86 (Social services Sofia)',
      courtOrderRequiredForEviction: true,
      rentControlRules:
          'No formal rent control. Rent freely negotiated between parties. No statutory limits on rent increases, but increases must follow contract terms. If contract silent, landlord must give reasonable notice. Market rents relatively low compared to Western EU.',
      repairObligations:
          'Landlord responsible for major repairs (roof, structure, heating system, plumbing). Tenant responsible for routine maintenance and minor repairs. If landlord neglects major repairs, tenant can repair and deduct from rent or seek court order.',
      depositReturnRules:
          'No statutory deposit limit (typically 1-2 months negotiated). Return timeline per contract (usually 1 month). Landlord must prove damages to retain deposit. If landlord refuses return, file civil claim at district court. Keep photographic evidence of apartment condition at move-in and move-out.',
      discriminationProtections:
          'Zakon za Zashtita ot Diskriminatsiya (Protection Against Discrimination Act) covers housing. Commission for Protection Against Discrimination (KZD) handles complaints. Protected grounds: race, ethnicity, nationality, gender, religion, disability, sexual orientation, age. EU citizens have equal treatment rights.',
      immigrantSpecificNotes:
          'EU citizens can rent freely with valid ID. Third-country nationals need residence permit. Register address at local municipality within 5 days. Rental market informal in some areas - insist on written contracts. Average rents low but conditions vary. Free legal aid for those below income threshold at National Legal Aid Bureau.',
      languageOfContracts: 'Bulgarian',
    ),

    // ----------------------------------------------------------------
    // 4. CROATIA (HR)
    // ----------------------------------------------------------------
    TenantRights(
      country: 'Croatia',
      countryCode: 'HR',
      maxRentIncreasePercent: 0,
      evictionNoticeDays: 90,
      depositLimitExists: false,
      maxDepositMonths: null,
      tenantProtectionAuthority:
          'Ministry of Physical Planning, Construction and State Assets / Municipal courts',
      tenantHotline: '+385 1 3782 444 (Ministry)',
      tenantRights: [
        'Right to written lease agreement (must be registered with tax authority)',
        'Right to habitable dwelling meeting minimum standards',
        'Right to peaceful enjoyment',
        'Right to maintain original lease terms if property sold',
        'Right to receive receipts for rent payments',
        'Right to essential services (water, heating, electricity)',
      ],
      evictionProtections: [
        'Court order required for eviction',
        'Landlord must provide minimum 90 days notice for lease termination',
        'Tenant can contest eviction before court',
        'Protected tenants (pre-1991 social tenants) have enhanced protection',
        'Families with children and elderly receive judicial consideration',
        'Illegal self-help eviction subject to criminal penalties',
      ],
      legalBasis:
          'Zakon o najmu stanova (Residential Lease Act, OG 91/96, amendments); Zakon o obveznim odnosima (Obligations Act)',
      emergencyContact: '112 (Emergency) / 01 4590 111 (Zagreb Social Welfare Center)',
      courtOrderRequiredForEviction: true,
      rentControlRules:
          'No formal rent control for private rentals. Rent freely negotiated. "Protected rent" regime exists for pre-1991 tenancies at below-market rates. Rent increases must be agreed in contract or with reasonable notice. No statutory cap on annual increases.',
      repairObligations:
          'Landlord must maintain structural integrity, roof, facade, installations (heating, plumbing, electricity). Tenant handles daily maintenance. If landlord fails to repair within reasonable time, tenant can repair and seek reimbursement.',
      depositReturnRules:
          'No statutory deposit limit (commonly 1-2 months). Return per contract terms. Landlord must document damages to justify withholding. If deposit not returned, file at municipal court. Small claims procedure available for amounts under HRK 10,000.',
      discriminationProtections:
          'Zakon o suzbijanju diskriminacije (Anti-Discrimination Act 2008) covers housing. Ombudsman for human rights handles complaints. Prohibited grounds: race, ethnicity, nationality, religion, gender, sexual orientation, disability, age, social status. EU citizens have equal access.',
      immigrantSpecificNotes:
          'EU citizens rent freely with valid ID. Third-country nationals need residence permit. Register temporary address at police within 2 days. Rental contracts must be in writing and registered for tax purposes. Croatian Red Cross and UNHCR provide housing assistance for refugees. Legal aid available for low-income residents.',
      languageOfContracts: 'Croatian',
    ),

    // ----------------------------------------------------------------
    // 5. CYPRUS (CY)
    // ----------------------------------------------------------------
    TenantRights(
      country: 'Cyprus',
      countryCode: 'CY',
      maxRentIncreasePercent: 0,
      evictionNoticeDays: 30,
      depositLimitExists: false,
      maxDepositMonths: null,
      tenantProtectionAuthority:
          'Rent Control Court (Dikastirio Eleghou Enoikiaseon) / District Courts',
      tenantHotline: '+357 22 867 100 (Ministry of Interior)',
      tenantRights: [
        'Statutory tenants in rent-controlled properties have strong protection',
        'Right to written lease agreement',
        'Right to habitable dwelling',
        'Right to peaceful enjoyment',
        'Right to renewal of lease in rent-controlled areas',
        'Right to receive rent receipts',
      ],
      evictionProtections: [
        'Rent Control Court handles disputes for controlled properties',
        'Court order required for eviction',
        'Statutory tenants cannot be evicted except for specific legal grounds',
        'Self-help eviction is criminal offense',
        'Grounds: non-payment, damage, nuisance, landlord personal use (with proof)',
      ],
      legalBasis:
          'Rent Control Law (Cap. 83) for controlled properties; Contract Law (Cap. 149) for uncontrolled',
      emergencyContact: '112 / 1455 (Social Welfare Services)',
      courtOrderRequiredForEviction: true,
      rentControlRules:
          'Two-tier system: Rent-controlled properties (built before 1980 in certain areas) have strict rent limits set by Rent Control Court. Uncontrolled properties have free-market rent. For controlled properties, rent increases only with court approval. Controlled areas: Nicosia, Limassol, Larnaca, Famagusta district.',
      repairObligations:
          'Landlord responsible for structural repairs and maintaining habitability. Tenant responsible for minor wear and tear. For controlled properties, landlord cannot claim inability to repair as grounds for eviction.',
      depositReturnRules:
          'No statutory limit on deposit amount (typically 1-2 months). No specific statutory deadline for return. Landlord must justify deductions. If not returned, pursue through district court civil procedure. Always document apartment condition with photos.',
      discriminationProtections:
          'Equal Treatment in Employment and Occupation Laws extend principles to housing. Equality Authority (Archi Isotitas) handles discrimination complaints. EU Race Equality Directive (2000/43/EC) transposed. Protection against discrimination by nationality for EU citizens.',
      immigrantSpecificNotes:
          'EU citizens have equal access to housing. Registration with Civil Registry required. Third-country nationals need valid residence permit. KISA (Action for Equality, Support, Antiracism) provides free advice. Cyprus Refugee Council assists asylum seekers with housing. English widely understood but contracts typically in Greek.',
      languageOfContracts: 'Greek (English contracts common in practice)',
    ),

    // ----------------------------------------------------------------
    // 6. CZECH REPUBLIC (CZ)
    // ----------------------------------------------------------------
    TenantRights(
      country: 'Czech Republic',
      countryCode: 'CZ',
      maxRentIncreasePercent: 20,
      evictionNoticeDays: 90,
      depositLimitExists: true,
      maxDepositMonths: 3,
      tenantProtectionAuthority:
          'Municipal courts / Czech Trade Inspection (ČOI)',
      tenantHotline: '+420 296 366 360 (Ombudsman)',
      tenantRights: [
        'Right to written lease (oral leases valid but harder to enforce)',
        'Right to habitable dwelling meeting health and safety standards',
        'Right to keep lease if property is sold (new owner inherits obligations)',
        'Right to sublet with landlord written consent',
        'Right to have up to 2 people join the household without landlord approval',
        'Right to contest unreasonable rent increases in court',
        'Right to pre-emption if landlord sells in some cases',
      ],
      evictionProtections: [
        'Court order required for eviction (since 2014 Civil Code)',
        'Minimum 3 months notice for lease termination by landlord',
        'Landlord must state valid legal reason for termination',
        'Valid reasons: non-payment (3+ months), serious damage, criminal activity, landlord personal need',
        'Tenant can contest termination in court within 2 months',
        'Court can grant up to 6 months postponement for vulnerable tenants',
      ],
      legalBasis:
          'Občanský zákoník (Civil Code No. 89/2012 Sb.), Sections 2235-2301',
      emergencyContact: '112 / 116 111 (Social Emergency Line)',
      courtOrderRequiredForEviction: true,
      rentControlRules:
          'Rent deregulated since 2012. Rent freely negotiated at lease start. Annual increases limited to 20% of difference between current rent and comparable local rent (cannot exceed comparable rent). Tenant can challenge excessive rent at court. Prague and Brno have higher market rents.',
      repairObligations:
          'Landlord: major repairs, structural maintenance, heating system, plumbing, electrical. Tenant: minor maintenance up to CZK amount specified by government decree (approx. CZK 1,000 per item). Tenant must report defects promptly. If landlord fails to repair, tenant can repair and deduct or seek rent reduction.',
      depositReturnRules:
          'Maximum deposit: 3 months rent (since 2014). Must be returned within 1 month after lease end and apartment handover. Landlord can deduct unpaid rent and documented damages. Deposit must earn statutory interest. If not returned, send demand letter then file at district court.',
      discriminationProtections:
          'Antidiskriminační zákon (Anti-Discrimination Act 198/2009) covers housing. Public Defender of Rights (Ombudsman) handles complaints. Protected grounds: race, ethnicity, nationality, gender, sexual orientation, disability, age, religion. Discrimination testing conducted by NGOs. Penalties include compensation and injunction.',
      immigrantSpecificNotes:
          'EU citizens register at Foreign Police within 30 days. Equal housing rights with Czech citizens. Third-country nationals need residence permit. Register address at Foreign Police. Poradna pro integraci (Counselling Centre for Integration) provides free legal advice. Some landlords discriminate against foreigners - report to Ombudsman. Contracts in Czech - get translation.',
      languageOfContracts: 'Czech',
    ),

    // ----------------------------------------------------------------
    // 7. DENMARK (DK)
    // ----------------------------------------------------------------
    TenantRights(
      country: 'Denmark',
      countryCode: 'DK',
      maxRentIncreasePercent: 4,
      evictionNoticeDays: 90,
      depositLimitExists: true,
      maxDepositMonths: 3,
      tenantProtectionAuthority:
          'Huslejenævnet (Rent Tribunal) / Beboerklagenævnet (Tenant Complaints Board)',
      tenantHotline: '+45 33 13 14 15 (LLO - Danish Tenants Association)',
      tenantRights: [
        'Right to written lease (standard Type A form recommended)',
        'Right to habitable dwelling meeting building regulations',
        'Right to challenge excessive rent at Huslejenævnet (Rent Tribunal)',
        'Right to 14-day inspection report at move-in',
        'Right to sublease for up to 2 years (own residence)',
        'Right to maintain lease if property sold',
        'Right to organize tenant association in buildings with 6+ units',
        'Right to compensation for improvements made during tenancy',
      ],
      evictionProtections: [
        'Court order required via Boligretten (Housing Court)',
        'Landlord must prove valid legal ground',
        'Minimum 3 months notice (1 month for non-payment)',
        'Non-payment: tenant has 14 days to cure after warning',
        'Landlord personal use: must genuinely need the apartment',
        'Major renovation: must offer alternative housing',
        'Tenant can contest at Huslejenævnet (free of charge)',
      ],
      legalBasis:
          'Lejeloven (Rent Act, consolidated 2022); Boligreguleringsloven (Housing Regulation Act)',
      emergencyContact: '112 / 70 23 00 49 (Danish Tenants Association LLO)',
      courtOrderRequiredForEviction: true,
      rentControlRules:
          'Two systems: Regulated municipalities (Copenhagen, major cities) - rent based on operating costs + capital return (omkostningsbestemt leje). Unregulated municipalities - "comparable rent" standard. Private properties built after 1991 exempt from regulation. Annual increases limited to operating cost increases. Tenant can challenge at Huslejenævnet within 1 year.',
      repairObligations:
          'Landlord must maintain property in condition agreed at lease start. Responsible for exterior, structure, common areas, installations. Tenant responsible for internal maintenance (painting, minor repairs) unless lease states otherwise. If landlord fails to repair, Huslejenævnet can order repairs and authorize rent reduction.',
      depositReturnRules:
          'Maximum deposit: 3 months rent. Separate prepaid rent allowed: up to 3 months. Landlord must conduct move-out inspection within 2 weeks. Written claim within 2 weeks of inspection. Deposit returned minus documented costs within reasonable time. If disputed, file at Huslejenævnet (DKK 357 fee).',
      discriminationProtections:
          'Lov om etnisk ligebehandling (Ethnic Equal Treatment Act) covers housing. Board of Equal Treatment (Ligebehandlingsnævnet) handles complaints. Protected: race, ethnicity, nationality, religion, gender, sexual orientation, disability, age. Free to file complaints. Compensation awarded in proven cases.',
      immigrantSpecificNotes:
          'EU citizens register at International House or Citizen Service Centre (Borgerservice). CPR number required for lease signing. Social housing (almene boliger) open to all legal residents - apply via boligselskab. Waiting lists can be years. LLO (Lejernes Landsorganisation) provides tenant advice in English. Integration contracts may include housing obligations.',
      languageOfContracts: 'Danish (English not standard but sometimes available)',
    ),

    // ----------------------------------------------------------------
    // 8. ESTONIA (EE)
    // ----------------------------------------------------------------
    TenantRights(
      country: 'Estonia',
      countryCode: 'EE',
      maxRentIncreasePercent: 0,
      evictionNoticeDays: 90,
      depositLimitExists: true,
      maxDepositMonths: 3,
      tenantProtectionAuthority:
          'Consumer Protection and Technical Regulatory Authority (TTJA) / County Courts',
      tenantHotline: '+372 667 2000 (TTJA)',
      tenantRights: [
        'Right to written lease agreement',
        'Right to dwelling meeting health and safety standards',
        'Right to peaceful enjoyment without landlord interference',
        'Right to maintain lease terms if property sold',
        'Right to make improvements with landlord consent and seek compensation',
        'Right to receive itemized utility bills',
        'Right to terminate lease with 3 months notice (indefinite lease)',
      ],
      evictionProtections: [
        'Court order required for eviction',
        'Landlord must give 3 months notice for indefinite lease termination',
        'Valid grounds required: non-payment (3+ months), damage, nuisance',
        'Extraordinary termination only for serious breach',
        'Court can extend deadline for vulnerable persons',
        'Self-help eviction is illegal',
      ],
      legalBasis:
          'Võlaõigusseadus (Law of Obligations Act), Chapters 15-16 (Sections 271-338)',
      emergencyContact: '112 / 1247 (Social Insurance Board helpline)',
      courtOrderRequiredForEviction: true,
      rentControlRules:
          'No rent control. Market rent fully liberalized. Rent increases per contract terms. If contract silent, landlord can propose increase with reasonable notice. Tenant can reject and negotiate. If no agreement, either party can terminate with notice. Tallinn and Tartu have highest rents.',
      repairObligations:
          'Landlord: structural repairs, roof, exterior, common areas, central heating. Dwelling must meet health requirements throughout tenancy. Tenant: minor interior maintenance. If landlord fails, tenant can demand repair, reduce rent, or repair and deduct costs. Must notify landlord first.',
      depositReturnRules:
          'Maximum deposit: 3 months rent. Must be returned after lease ends and apartment inspected. Landlord can deduct proven damages and unpaid rent. No specific statutory deadline but "without undue delay" (practice: 30 days). If withheld unjustly, file at county court or use e-File system.',
      discriminationProtections:
          'Võrdse kohtlemise seadus (Equal Treatment Act 2009) covers housing related to ethnicity and race. Gender Equality Commissioner expanded to Equality Commissioner. Prohibited: discrimination by nationality, race, ethnicity, religion, disability, age, sexual orientation. Complaints to Chancellor of Justice (Õiguskantsler).',
      immigrantSpecificNotes:
          'EU citizens register residence at Police and Border Guard Board (PPA). ID code required for contracts. Third-country nationals need residence permit. Estonian Integration Foundation (INSA) provides free advice. Russian-speaking community substantial - many landlords speak Russian. Contracts typically in Estonian. e-Residency does not grant housing rights.',
      languageOfContracts: 'Estonian (Russian sometimes available)',
    ),

    // ----------------------------------------------------------------
    // 9. FINLAND (FI)
    // ----------------------------------------------------------------
    TenantRights(
      country: 'Finland',
      countryCode: 'FI',
      maxRentIncreasePercent: 0,
      evictionNoticeDays: 180,
      depositLimitExists: true,
      maxDepositMonths: 3,
      tenantProtectionAuthority:
          'Kuluttajariitalautakunta (Consumer Disputes Board) / District Courts',
      tenantHotline: '+358 9 2286 5100 (Vuokralaiset ry - Finnish Tenants Association)',
      tenantRights: [
        'Right to written lease agreement (oral valid but not recommended)',
        'Right to habitable dwelling meeting health standards',
        'Right to quiet enjoyment - landlord must give notice before visits',
        'Right to maintain lease terms if property sold (new owner bound)',
        'Right to sublease with landlord consent (cannot unreasonably refuse)',
        'Right to receive housing allowance (asumistuki) regardless of nationality',
        'Right to contest lease terms as unfair at Consumer Disputes Board',
        'Lease cannot be terminated during fixed term except for serious breach',
      ],
      evictionProtections: [
        'Court order (käräjäoikeus) ALWAYS required for eviction',
        'Landlord must give 6 months notice (indefinite lease) or 3 months if tenancy < 1 year',
        'Valid reason required: non-payment, serious breach, landlord genuine personal need',
        'Court enforcement (ulosotto) handles physical eviction - never landlord',
        'Tenant can request extended deadline from court',
        'Winter eviction: courts consider vulnerability',
        'Self-help eviction (lock changes, utility shutoff) is criminal offense',
      ],
      legalBasis:
          'Laki asuinhuoneiston vuokrauksesta (Act on Residential Leases 481/1995)',
      emergencyContact: '112 / 0295 020 900 (Kela social assistance)',
      courtOrderRequiredForEviction: true,
      rentControlRules:
          'No rent control in private market. Rent freely agreed between parties. Rent increases must follow contract terms. If no increase clause, landlord must notify and tenant can terminate if increase unreasonable. ARA (social housing) has regulated rents based on costs. Market highly transparent - check vuokraovi.com for comparisons.',
      repairObligations:
          'Landlord responsible for maintaining dwelling in agreed condition. Structure, heating, plumbing, appliances included in lease. Tenant must report defects immediately. Tenant liable for damage caused by negligence. If landlord fails to repair, tenant can: demand repair, reduce rent, repair and deduct, or terminate lease. Housing health inspector (terveystarkastaja) can order repairs.',
      depositReturnRules:
          'Maximum deposit: 3 months rent. Must be returned "without delay" after lease ends and apartment inspected (practice: within 1 month). Landlord must itemize any deductions with evidence. Interest not legally required but common. If not returned: send written demand, then file at district court or Consumer Disputes Board (free).',
      discriminationProtections:
          'Yhdenvertaisuuslaki (Non-Discrimination Act 1325/2014) strongly covers housing. Discrimination Commissioner (Yhdenvertaisuusvaltuutettu) handles complaints. Protected grounds: nationality, ethnic origin, language, religion, disability, sexual orientation, gender identity, age. Discrimination in housing advertisements also prohibited. Penalties: compensation + fine.',
      immigrantSpecificNotes:
          'Register at DVV (Digital and Population Data Services Agency) to get personal identity code (henkilötunnus) - ESSENTIAL for renting. Housing allowance (asumistuki) from Kela available to all legal residents regardless of nationality. Municipal housing agencies (e.g., Heka in Helsinki) accept immigrants. Finnish Refugee Council and local immigrant advisory services provide housing help. Discrimination by nationality is common but illegal - report to Non-Discrimination Ombudsman.',
      languageOfContracts: 'Finnish or Swedish (English contracts exist but not standard)',
    ),

    // ----------------------------------------------------------------
    // 10. FRANCE (FR)
    // ----------------------------------------------------------------
    TenantRights(
      country: 'France',
      countryCode: 'FR',
      maxRentIncreasePercent: 3,
      evictionNoticeDays: 180,
      depositLimitExists: true,
      maxDepositMonths: 1,
      tenantProtectionAuthority:
          'ADIL (Agence Départementale d\'Information sur le Logement) / Tribunal Judiciaire',
      tenantHotline: '0 805 160 075 (SOS Loyers Impayés - free)',
      tenantRights: [
        'Right to written lease using standard contract (loi ALUR model)',
        'Right to habitable dwelling meeting décence standards',
        'Right to rent receipt (quittance de loyer) monthly',
        'Right to APL/ALS housing allowance from CAF',
        'Right to 1-month notice in tense housing zones (zone tendue)',
        'Right to oppose excessive charges (charges récupérables only)',
        'Right to keep the lease if property sold (buyer inherits lease)',
        'Landlord cannot demand photos, bank statements beyond legal list of documents',
      ],
      evictionProtections: [
        'Court order (Tribunal Judiciaire) ALWAYS required',
        'Winter truce (trêve hivernale): NO evictions November 1 - March 31',
        'Landlord must give 6 months notice before lease end (3-year lease)',
        'Préfet must authorize police enforcement of eviction',
        'CCAPEX commission reviews every eviction for social solutions',
        'Right to rehousing (DALO) if recognized as priority',
        'Expulsion without court order is criminal offense (violation de domicile)',
      ],
      legalBasis:
          'Loi n°89-462 du 6 juillet 1989 (Loi Mermaz); Loi ALUR 2014; Loi ELAN 2018',
      emergencyContact: '115 (SAMU Social - homeless emergency) / 0 805 160 075',
      courtOrderRequiredForEviction: true,
      rentControlRules:
          'Encadrement des loyers (rent cap) active in Paris, Lyon, Lille, Bordeaux, Montpellier, and other cities. Rent cannot exceed reference rent + 20% (complément de loyer for exceptional features only). Annual increase limited to IRL index (around 3-4%). New leases in tense zones: rent capped at previous tenant\'s rent. Violations: up to EUR 5,000 fine (individual) or EUR 15,000 (company).',
      repairObligations:
          'Landlord must deliver and maintain "decent housing" (logement décent - Décret 2002-120). Includes: minimum 9m2, heating, hot water, electrical safety, no lead paint risk, energy performance. Major repairs (roof, plumbing, heating system) on landlord. Tenant: minor maintenance per Décret 87-712. If landlord refuses repairs: mise en demeure, then tribunal, rent reduction possible, housing inspector (ARS) can declare insalubrité.',
      depositReturnRules:
          'Maximum deposit: 1 month rent (unfurnished) or 2 months (furnished). Return deadline: 1 month if état des lieux identical, 2 months if damage noted. After deadline: 10% penalty per month of delay. Landlord must provide itemized deductions with invoices. If not returned: formal mise en demeure, then Tribunal de proximité or conciliator (free).',
      discriminationProtections:
          'Loi n°2008-496 (transposing EU directives) strongly prohibits housing discrimination. 24 protected criteria including nationality, ethnic origin, family situation, pregnancy, disability, sexual orientation, physical appearance, surname, place of residence. Défenseur des droits handles complaints (free). Testing/discrimination evidence admissible. Criminal penalties: up to 3 years prison + EUR 45,000 fine.',
      immigrantSpecificNotes:
          'All legal residents can rent and receive housing aid (APL/ALS from CAF). No nationality requirement for private rental. Dossier requirements strict: ID, proof of income (3x rent), tax notice. Guarantor often required - Visale (Action Logement) provides FREE state guarantee for under-30s and all new employees. ADIL provides free housing legal advice in every department. 115 for emergency shelter. DALO application if unable to find housing after 6 months.',
      languageOfContracts: 'French',
    ),

    // ----------------------------------------------------------------
    // 11. GERMANY (DE)
    // ----------------------------------------------------------------
    TenantRights(
      country: 'Germany',
      countryCode: 'DE',
      maxRentIncreasePercent: 15,
      evictionNoticeDays: 90,
      depositLimitExists: true,
      maxDepositMonths: 3,
      tenantProtectionAuthority:
          'Mieterverein (Tenant Association) / Amtsgericht (Local Court)',
      tenantHotline: '+49 30 226260 (Berliner Mieterverein)',
      tenantRights: [
        'Right to written lease (indefinite lease is the norm)',
        'Right to habitable dwelling meeting DIN standards',
        'Right to Mietpreisbremse (rent brake) in designated areas',
        'Right to reduce rent if defects exist (Mietminderung)',
        'Right to at least 3 months notice before eviction',
        'Right to keep the lease if property sold (Kauf bricht nicht Miete)',
        'Right to install satellite dish (with conditions)',
        'Right to keep pets unless lease specifically prohibits large animals',
        'Right to Wohngeld (housing benefit) regardless of nationality',
      ],
      evictionProtections: [
        'Court order (Amtsgericht) ALWAYS required',
        'Minimum notice: 3 months (< 5 years), 6 months (5-8 years), 9 months (8+ years)',
        'Landlord must prove "legitimate interest" (Berechtigtes Interesse)',
        'Eigenbedarf (personal need): must be genuine and specific',
        'Sozialklausel: tenant can object if eviction causes undue hardship',
        'Court can extend deadline up to 1 year for hardship cases',
        'Illegal eviction: criminal offense (Hausfriedensbruch)',
        'Berlin special: 10-year ban on Eigenbedarf after condo conversion',
      ],
      legalBasis:
          'Bürgerliches Gesetzbuch (BGB) Sections 535-580a; Mietpreisbremse (2015, reformed 2020)',
      emergencyContact: '112 / 030 25 00 23 23 (Berlin housing emergency)',
      courtOrderRequiredForEviction: true,
      rentControlRules:
          'Mietpreisbremse (rent brake): in designated areas, new lease rent max 10% above local reference rent (Mietspiegel). Existing tenants: max 15% increase in 3 years (20% in non-designated areas), up to local reference rent. Berlin, Munich, Hamburg, Frankfurt, Cologne all designated. Kappungsgrenze limits increases. Modernization surcharge: max 8% of costs passed to tenant annually.',
      repairObligations:
          'Landlord responsible for maintaining habitable condition. Structure, roof, heating, plumbing, windows, exterior. Schönheitsreparaturen (cosmetic repairs) clauses in many leases but many declared invalid by courts. Tenant must report defects immediately. Right to Mietminderung (rent reduction) from day defect is reported until fixed. Amount depends on severity (court tables available).',
      depositReturnRules:
          'Maximum: 3 months net rent (Kaltmiete, excluding utilities). Tenant can pay in 3 installments. Must be kept in separate account earning standard savings interest. Return: within "reasonable time" after move-out (courts say 3-6 months). Landlord can retain reasonable amount for utility settlement (up to 12 months). Itemized deductions required. If not returned: formal demand, then Amtsgericht.',
      discriminationProtections:
          'Allgemeines Gleichbehandlungsgesetz (AGG) covers housing (with limitations for small landlords). Antidiskriminierungsstelle des Bundes (Federal Anti-Discrimination Agency) handles complaints. Protected: race, ethnicity, religion, disability, age, sexual orientation, gender. Housing discrimination widespread but illegal. Some cities (Berlin) have anti-discrimination offices specifically for housing.',
      immigrantSpecificNotes:
          'EU citizens register at Bürgeramt (registration office) - Anmeldung is legally required within 14 days. Schufa credit check commonly required - new arrivals can get Schufa-Auskunft or use alternatives. Wohngeld (housing benefit) available to all legal residents. Mieterverein membership (EUR 5-10/month) provides excellent legal protection and advice. WBS (Wohnberechtigungsschein) for social housing. Many cities have Wohnungsamt for housing assistance.',
      languageOfContracts: 'German',
    ),

    // ----------------------------------------------------------------
    // 12. GREECE (GR)
    // ----------------------------------------------------------------
    TenantRights(
      country: 'Greece',
      countryCode: 'GR',
      maxRentIncreasePercent: 0,
      evictionNoticeDays: 30,
      depositLimitExists: true,
      maxDepositMonths: 2,
      tenantProtectionAuthority:
          'Eirinikodikeio (Peace Court) / Consumer Ombudsman',
      tenantHotline: '+30 210 6460 862 (Consumer Ombudsman)',
      tenantRights: [
        'Minimum lease duration: 3 years (even if contract says less)',
        'Right to habitable dwelling',
        'Right to quiet enjoyment',
        'Right to automatic 3-year term regardless of signed duration',
        'Right to sublease with landlord consent (for part of dwelling)',
        'Right to early termination with notice',
      ],
      evictionProtections: [
        'Court order required (Eirinikodikeio - Peace Court)',
        'Minimum lease 3 years protects against early eviction',
        'Tenant can cure rent arrears before court judgment',
        'Self-help eviction illegal - criminal penalties apply',
        'Court can grant delays for vulnerable tenants',
        'Eviction moratorium during emergencies (applied during COVID)',
      ],
      legalBasis:
          'Civil Code Articles 574-618; Law 1703/1987 on residential leases; Law 4242/2014 reforms',
      emergencyContact: '112 / 197 (Social Solidarity)',
      courtOrderRequiredForEviction: true,
      rentControlRules:
          'No formal rent control since 2015 reforms. Rent freely negotiated. Minimum 3-year lease term provides stability. Rent increases per contract agreement. If contract silent, increases must be "reasonable." Athens and Thessaloniki rents rising rapidly but no caps.',
      repairObligations:
          'Landlord: structural repairs, roof, exterior, installations provided at lease start. Must maintain habitability throughout lease. Tenant: minor wear and tear, maintenance of interior. If landlord fails, tenant can repair and deduct from rent after formal written notice. Can also seek rent reduction from court.',
      depositReturnRules:
          'Typically 2 months rent (no strict statutory limit but 2 months is standard). Return after lease ends and apartment inspected. No strict statutory deadline (practice: within 1-2 months). Landlord must prove damages. If not returned: send formal extrajudicial notice (εξώδικο), then file at Eirinikodikeio. Small claims for amounts under EUR 5,000.',
      discriminationProtections:
          'Law 4443/2016 transposing EU anti-discrimination directives. Greek Ombudsman handles housing discrimination. Protected: race, ethnicity, nationality, religion, disability, sexual orientation, age, gender. Enforcement improving but discrimination against immigrants documented. ECRI (Council of Europe) monitors.',
      immigrantSpecificNotes:
          'EU citizens register at Aliens Bureau or police within 3 months. Tax number (AFM) needed for lease registration. Third-country nationals need residence permit. Greek Council for Refugees provides housing assistance. UNHCR programs for refugees. Many rentals informal - ALWAYS insist on written contract and registration with TAXIS (tax system). Housing market tight in Athens - start searching early.',
      languageOfContracts: 'Greek',
    ),

    // ----------------------------------------------------------------
    // 13. HUNGARY (HU)
    // ----------------------------------------------------------------
    TenantRights(
      country: 'Hungary',
      countryCode: 'HU',
      maxRentIncreasePercent: 0,
      evictionNoticeDays: 30,
      depositLimitExists: false,
      maxDepositMonths: null,
      tenantProtectionAuthority:
          'District Courts (Járásbíróság) / Government Office (Kormányhivatal)',
      tenantHotline: '+36 1 472 8900 (Government Customer Service - 1818)',
      tenantRights: [
        'Right to written lease agreement (notarized for stronger protection)',
        'Right to habitable dwelling',
        'Right to peaceful enjoyment',
        'Right to maintain lease upon property sale',
        'Right to receive utility bill breakdowns',
        'Right to terminate indefinite lease with 15 days notice before month end',
      ],
      evictionProtections: [
        'Court order required for eviction',
        'Notarized lease enables faster enforcement but still needs court',
        'Social housing tenants have enhanced protection',
        'Local government must offer shelter housing for families with children in winter',
        'Self-help eviction illegal',
        'Tenant can contest at court',
      ],
      legalBasis:
          'Polgári Törvénykönyv (Civil Code 2013:V), Sections 6:331-6:364; Lakástörvény (Housing Act 1993:LXXVIII)',
      emergencyContact: '112 / 1818 (Government info line)',
      courtOrderRequiredForEviction: true,
      rentControlRules:
          'No rent control for private rentals. Rent freely negotiated. No statutory limits on increases. Contract terms govern increases. Social housing (önkormányzati lakás) has regulated rents set by local government decrees. Budapest and major cities have rising market rents.',
      repairObligations:
          'Landlord: structural repairs, installations that are part of the property, maintaining habitability. Tenant: minor maintenance, interior upkeep. Government Decree 2/2017 specifies division of repair obligations. If landlord fails, tenant can repair essential items and deduct from rent after written notice.',
      depositReturnRules:
          'No statutory deposit limit (commonly 2-3 months in practice). Return per contract terms (typically 15-30 days after move-out). Landlord can deduct documented damages and unpaid utilities. If not returned: send formal demand (felszólító levél), then file at district court. Notarized contract helps enforcement.',
      discriminationProtections:
          'Egyenlő Bánásmód törvény (Equal Treatment Act 2003) covers housing. Equal Treatment Authority (Egyenlő Bánásmód Hatóság) handles complaints (merged into Commissioner for Fundamental Rights in 2021). Protected: race, ethnicity, nationality, religion, disability, sexual orientation, age, social status. Discrimination against Roma in housing documented and sanctioned.',
      immigrantSpecificNotes:
          'EU citizens register at immigration office (OIF) within 93 days. Address card (lakcímkártya) needed. Third-country nationals need residence permit. Tax number required for formal rental. Menedék (Hungarian Association for Migrants) provides assistance. Hungarian Helsinki Committee offers free legal aid. Rental market mostly in Hungarian - bring interpreter for contract signing.',
      languageOfContracts: 'Hungarian',
    ),

    // ----------------------------------------------------------------
    // 14. IRELAND (IE)
    // ----------------------------------------------------------------
    TenantRights(
      country: 'Ireland',
      countryCode: 'IE',
      maxRentIncreasePercent: 2,
      evictionNoticeDays: 90,
      depositLimitExists: false,
      maxDepositMonths: null,
      tenantProtectionAuthority:
          'Residential Tenancies Board (RTB)',
      tenantHotline: '0818 303 037 (RTB) / 0818 776 776 (Threshold)',
      tenantRights: [
        'Right to written lease (landlord must provide within 2 months)',
        'Right to register tenancy with RTB (landlord obligation)',
        'Right to minimum standards (S.I. No. 137/2019)',
        'Right to Part 4 tenancy security after 6 months (indefinite security)',
        'Right to 2% annual rent cap in Rent Pressure Zones',
        'Right to receive Rent Book',
        'Right to refer disputes to RTB (free of charge)',
        'Right to Housing Assistance Payment (HAP) without discrimination',
      ],
      evictionProtections: [
        'RTB dispute resolution (adjudication/mediation) available',
        'Notice periods: 90 days (< 6 months) to 180 days (5+ years)',
        'Part 4 rights: only 6 valid reasons for termination after 6 months',
        'Valid reasons: non-payment, breach, property sale, landlord need, major renovation, change of use',
        'Landlord must serve valid notice of termination with reason',
        'Invalid notice can be challenged at RTB within 28 days',
        'Illegal eviction: RTB can award damages up to EUR 20,000',
      ],
      legalBasis:
          'Residential Tenancies Act 2004 (as amended 2015, 2016, 2019, 2021, 2024)',
      emergencyContact: '0818 776 776 (Threshold - housing charity) / 1800 454 454 (Simon emergency)',
      courtOrderRequiredForEviction: false,
      rentControlRules:
          'Rent Pressure Zones (RPZ): annual rent increases capped at 2% (previously CPI-linked). Most urban areas designated as RPZ (Dublin, Cork, Galway, Limerick, Waterford). Landlord must justify rent with 3 comparable rentals. RTB Rent Index provides market data. Outside RPZ: market rent but must not exceed market rate. New tenancies: rent cannot exceed previous rent by more than allowed increase.',
      repairObligations:
          'Landlord must meet minimum standards (S.I. No. 137/2019): heating, hot water, fire safety, ventilation, structural soundness, sanitary facilities, food preparation, laundry, refuse, electricity/gas safety. Tenant must not cause damage and maintain cleanliness. If landlord breaches: report to local authority housing inspector or file at RTB.',
      depositReturnRules:
          'No statutory deposit limit (typically 1 month). Must be returned "promptly" after tenancy ends. RTB can adjudicate deposit disputes (free to file). Common deductions: damage beyond wear and tear, unpaid rent, cleaning. If landlord fails to return: file dispute with RTB within 28 days of demand. RTB determination legally binding.',
      discriminationProtections:
          'Equal Status Acts 2000-2018 strongly cover housing and accommodation. Protected grounds: gender, civil status, family status, sexual orientation, religion, age, disability, race/ethnicity, membership of Traveller community, housing assistance (HAP). Refusing HAP tenants now explicitly illegal. Irish Human Rights and Equality Commission (IHREC) enforces. Workplace Relations Commission adjudicates.',
      immigrantSpecificNotes:
          'All legal residents can rent. PPS Number needed for HAP and social housing. EU citizens have full housing rights. Threshold charity provides free housing advice including for immigrants. Citizens Information centres offer multilingual help. Immigrant Council of Ireland provides legal support. HAP: local authority pays landlord directly - landlord cannot legally refuse HAP. Deposits can be paid in installments if on social welfare.',
      languageOfContracts: 'English',
    ),

    // ----------------------------------------------------------------
    // 15. ITALY (IT)
    // ----------------------------------------------------------------
    TenantRights(
      country: 'Italy',
      countryCode: 'IT',
      maxRentIncreasePercent: 0,
      evictionNoticeDays: 180,
      depositLimitExists: true,
      maxDepositMonths: 3,
      tenantProtectionAuthority:
          'SUNIA/SICET/UNIAT (Tenant Unions) / Tribunale Civile',
      tenantHotline: '+39 06 441 83 01 (SUNIA national)',
      tenantRights: [
        'Right to minimum 4-year lease (plus 4-year automatic renewal = 4+4)',
        'Right to registered lease (landlord must register with Agenzia delle Entrate)',
        'Right to habitable dwelling meeting safety standards',
        'Right to "cedolare secca" (flat tax) which freezes rent increases',
        'Right to reduced rent via "canone concordato" (negotiated rent) in qualifying cities',
        'Right to succeed to lease (family members on death/separation)',
        'Right to buy if landlord sells (prelazione)',
      ],
      evictionProtections: [
        'Court order (Tribunale) ALWAYS required for eviction',
        'Landlord must give 6 months notice before 4+4 period ends',
        'First 4-year period: landlord can only terminate for specific reasons',
        'Non-payment: must be 20+ days late, judge must validate',
        'Court can grant "termine di grazia" (grace period) of 90 days for payment',
        'Eviction enforcement via Ufficiale Giudiziario - can take months/years',
        'Vulnerable categories (elderly, disabled, families with minors) get extensions',
      ],
      legalBasis:
          'Legge 431/1998 (Disciplina delle locazioni); Codice Civile Articles 1571-1614',
      emergencyContact: '112 / 800 840 840 (social services - varies by municipality)',
      courtOrderRequiredForEviction: true,
      rentControlRules:
          'Two contract types: Free market (4+4 years) - rent freely negotiated. Canone concordato (3+2 years) - rent per local agreements between unions and landlord associations, tax benefits for both. Cedolare secca: flat 21% tax (10% for concordato) and NO rent increases for entire contract period. Annual increases in free market limited to 75% of ISTAT index.',
      repairObligations:
          'Landlord: extraordinary maintenance (structural, roof, heating systems, facade, compliance). Tenant: ordinary maintenance (interior painting, minor repairs, garden upkeep). Codice Civile Art. 1576-1577. If landlord refuses essential repairs: formal raccomandata (registered letter), then reduction of rent, or court order. Municipal housing inspection for safety violations.',
      depositReturnRules:
          'Maximum deposit: 3 months rent (Codice Civile Art. 11 L.392/78). Must earn legal interest, paid annually to tenant. Return: at end of lease after utility bill settlement (can take up to 6 months for final utility bills). Landlord must document deductions. If not returned: formal diffida (demand), then Tribunale. Mediation (mediazione) now mandatory before court.',
      discriminationProtections:
          'D.Lgs. 215/2003 and 216/2003 transposing EU anti-discrimination directives. UNAR (Ufficio Nazionale Antidiscriminazioni Razziali) handles housing discrimination. Protected: race, ethnicity, nationality, religion, disability, sexual orientation, age. Discrimination documented especially against immigrants and Roma. Fines and compensation available.',
      immigrantSpecificNotes:
          'Valid permesso di soggiorno (residence permit) needed for legal rental. Codice fiscale (tax code) essential for all contracts. EU citizens register at Anagrafe (municipal registry). Unregistered leases ("in nero") provide NO legal protection - always insist on registered contract. SUNIA, SICET, UNIAT unions provide cheap membership with full legal support. Sportello Immigrazione at local comune provides free advice. Emergency housing via Caritas and municipal social services.',
      languageOfContracts: 'Italian',
    ),

    // ----------------------------------------------------------------
    // 16. LATVIA (LV)
    // ----------------------------------------------------------------
    TenantRights(
      country: 'Latvia',
      countryCode: 'LV',
      maxRentIncreasePercent: 0,
      evictionNoticeDays: 30,
      depositLimitExists: false,
      maxDepositMonths: null,
      tenantProtectionAuthority:
          'District Courts (Rajona tiesa) / Consumer Rights Protection Centre (PTAC)',
      tenantHotline: '+371 65 452 554 (PTAC)',
      tenantRights: [
        'Right to written lease agreement',
        'Right to habitable dwelling',
        'Right to peaceful enjoyment',
        'Right to maintain lease if property sold (registered lease)',
        'Right to register lease in Land Register for stronger protection',
        'Right to receive utility cost breakdowns',
      ],
      evictionProtections: [
        'Court order required for eviction',
        'Lease registered in Land Register survives property sale',
        'Self-help eviction is criminal offense',
        'Court can postpone eviction for vulnerable persons',
        'Municipality must provide shelter for families with minors facing eviction',
        'Denationalized property tenants have special protections (historical)',
      ],
      legalBasis:
          'Dzīvojamo telpu īres likums (Residential Tenancy Law 2021, effective 2022); Civillikums (Civil Law)',
      emergencyContact: '112 / 80006070 (Social service info)',
      courtOrderRequiredForEviction: true,
      rentControlRules:
          'No rent control. Market rent fully liberalized since 2022 law. Rent freely negotiated. Increases per contract terms. New law (2022) simplified termination but maintained court requirement. Riga rents highest in Baltics. Denationalized property had transitional rent caps (expired).',
      repairObligations:
          'Landlord: structural maintenance, common areas, installations, roof, facade. Must maintain dwelling in contractually agreed condition. Tenant: interior daily maintenance. New 2022 law clarifies obligations. If landlord neglects: written notice, then repair and deduct, or court order.',
      depositReturnRules:
          'No statutory deposit limit (typically 1-2 months). Return per contract (usually 30 days). Landlord must document damages. If not returned: demand letter, then district court. Lease registration in Land Register provides strongest protection.',
      discriminationProtections:
          'Latvian Human Rights Office / Ombudsman handles discrimination. EU directives transposed. Protected: race, ethnicity, nationality, religion, disability, age, sexual orientation, gender. Enforcement developing. NGO Latvian Centre for Human Rights monitors housing discrimination.',
      immigrantSpecificNotes:
          'EU citizens register at Office of Citizenship and Migration Affairs (PMLP). Personal code required for lease. Third-country nationals need residence permit. Latvian language often needed for contracts and dealings. Shelter "Safe House" provides emergency housing. Latvian Red Cross assists refugees. Market relatively affordable compared to Western EU.',
      languageOfContracts: 'Latvian',
    ),

    // ----------------------------------------------------------------
    // 17. LITHUANIA (LT)
    // ----------------------------------------------------------------
    TenantRights(
      country: 'Lithuania',
      countryCode: 'LT',
      maxRentIncreasePercent: 0,
      evictionNoticeDays: 90,
      depositLimitExists: false,
      maxDepositMonths: null,
      tenantProtectionAuthority:
          'District Courts (Apylinkės teismas) / State Consumer Rights Protection Authority',
      tenantHotline: '+370 5 262 6760 (Consumer Protection)',
      tenantRights: [
        'Right to written lease agreement (oral leases valid but risky)',
        'Right to habitable dwelling meeting hygiene standards',
        'Right to peaceful use of rented premises',
        'Right to maintain lease if property sold (if lease registered)',
        'Right to sublease part of dwelling with landlord consent',
        'Right to essential services maintenance',
      ],
      evictionProtections: [
        'Court order required for eviction',
        'Minimum 3 months notice for indefinite lease termination',
        'Valid grounds needed: non-payment, damage, misuse, landlord need',
        'Court can delay eviction considering tenant circumstances',
        'Municipality must assist families with minors',
        'Self-help eviction is illegal',
      ],
      legalBasis:
          'Civilinis kodeksas (Civil Code), Book 6, Sections 6.477-6.506',
      emergencyContact: '112 / 8 706 64 444 (Social services info)',
      courtOrderRequiredForEviction: true,
      rentControlRules:
          'No rent control. Fully liberalized market. Rent negotiated between parties. No statutory caps on increases. Contract terms govern rent adjustments. Municipal housing has regulated rents. Vilnius rents highest, followed by Kaunas and Klaipėda.',
      repairObligations:
          'Landlord: capital/major repairs, maintaining structural integrity, common areas, heating systems. Tenant: routine maintenance, minor interior repairs. Civil Code specifies division. If landlord fails: written demand, repair and deduct, or seek court remedy.',
      depositReturnRules:
          'No statutory deposit limit (typically 1-2 months). Return per contract terms. Landlord must justify withholding. If not returned: formal demand, then district court. Quick procedure available for undisputed claims.',
      discriminationProtections:
          'Lygių galimybių įstatymas (Equal Opportunities Act) covers housing. Office of the Equal Opportunities Ombudsperson investigates complaints. Protected: gender, race, nationality, language, origin, social status, religion, disability, age, sexual orientation. Housing discrimination complaints accepted and investigated.',
      immigrantSpecificNotes:
          'EU citizens register at Migration Department within 3 months. Personal code (asmens kodas) needed. Third-country nationals need residence permit. Lithuanian Red Cross and Caritas provide housing assistance to refugees. Market affordable but quality varies. Always insist on written contracts. Lithuanian language usually required for official dealings.',
      languageOfContracts: 'Lithuanian',
    ),

    // ----------------------------------------------------------------
    // 18. LUXEMBOURG (LU)
    // ----------------------------------------------------------------
    TenantRights(
      country: 'Luxembourg',
      countryCode: 'LU',
      maxRentIncreasePercent: 10,
      evictionNoticeDays: 90,
      depositLimitExists: true,
      maxDepositMonths: 3,
      tenantProtectionAuthority:
          'Commission des Loyers (Rent Commission) / Justice de Paix',
      tenantHotline: '+352 26 86 26 1 (Office Social)',
      tenantRights: [
        'Right to written lease agreement',
        'Right to habitable dwelling meeting safety standards',
        'Right to challenge excessive rent at Rent Commission (Commission des loyers)',
        'Right to maximum rent calculated on capital invested (5% rule)',
        'Right to peaceful enjoyment',
        'Automatic renewal of leases',
        'Right to sublease with landlord consent',
      ],
      evictionProtections: [
        'Court order required (Justice de Paix)',
        'Minimum 3 months notice for termination',
        'Valid reasons: non-payment, breach, personal use, major renovation',
        'Personal use: landlord must actually move in',
        'Court can grant extensions for vulnerable tenants',
        'Winter considerations apply',
      ],
      legalBasis:
          'Loi du 21 septembre 2006 sur le bail à usage d\'habitation (modified 2015, 2019)',
      emergencyContact: '112 / 116 123 (SOS Détresse)',
      courtOrderRequiredForEviction: true,
      rentControlRules:
          'Statutory rent cap: annual rent cannot exceed 5% of capital invested in the property (including land and construction costs). Rent Commission (Commission des loyers) can review and reduce excessive rents. Rent increases beyond 10% in 2 years can be challenged. System criticized as capital-invested calculation often unclear.',
      repairObligations:
          'Landlord: major repairs (structure, roof, heating, plumbing, electrical). Must maintain dwelling in rentable condition. Tenant: minor maintenance and interior upkeep per decree. If landlord fails: formal mise en demeure, then Justice de Paix can order repairs and authorize rent reduction.',
      depositReturnRules:
          'Maximum deposit: 3 months rent. Must be placed in blocked bank account. Return within 3 months after lease end. Landlord must provide itemized deductions with proof. If not returned: formal mise en demeure, then Justice de Paix (fast-track possible). Interest on deposit belongs to tenant.',
      discriminationProtections:
          'Loi du 28 novembre 2006 on equal treatment. Centre for Equal Treatment (CET) handles complaints. Protected: race, ethnicity, nationality, religion, disability, age, sexual orientation, gender. CET provides free advice and can take cases to court. Luxembourg very international - discrimination still occurs but actively fought.',
      immigrantSpecificNotes:
          'Highly international population (47% non-Luxembourgish). EU citizens register at commune within 3 months. Housing market extremely tight and expensive. Social housing via Fonds du Logement and SNHBM (waiting lists). ASTI (Association de Soutien aux Travailleurs Immigrés) provides free housing advice. Contracts in French, German, or Luxembourgish. Most landlords accept international tenants but competition fierce.',
      languageOfContracts: 'French (German and Luxembourgish also used)',
    ),

    // ----------------------------------------------------------------
    // 19. MALTA (MT)
    // ----------------------------------------------------------------
    TenantRights(
      country: 'Malta',
      countryCode: 'MT',
      maxRentIncreasePercent: 5,
      evictionNoticeDays: 90,
      depositLimitExists: true,
      maxDepositMonths: 1,
      tenantProtectionAuthority:
          'Housing Authority / Rent Regulation Board',
      tenantHotline: '+356 2299 2000 (Housing Authority)',
      tenantRights: [
        'Right to written lease (mandatory since 2020 Private Residential Leases Act)',
        'Right to minimum 1-year lease (mandatory)',
        'Right to register lease with Housing Authority',
        'Right to habitable dwelling meeting standards',
        'Right to inventory at move-in',
        'Right to peaceful enjoyment',
        'Right to contest excessive rent increases',
      ],
      evictionProtections: [
        'Rent Regulation Board handles disputes',
        'Minimum 1-year lease (3-year recommended in law)',
        'Landlord must give 3 months notice before lease end',
        'Non-renewal: valid reason required during first year',
        'Pre-2010 controlled tenancies have very strong protection',
        'Court order needed for eviction enforcement',
      ],
      legalBasis:
          'Private Residential Leases Act (Chapter 604, 2020); Reletting of Urban Property Ordinance (Cap. 69) for old leases',
      emergencyContact: '112 / 179 (Appogg - social welfare)',
      courtOrderRequiredForEviction: true,
      rentControlRules:
          'New system since 2020: rent freely set at lease start. During lease, increases capped at 5% per year. Old controlled leases (pre-1995): very low regulated rents, being phased out. Housing Authority registers leases and monitors compliance. Market rents high relative to salaries.',
      repairObligations:
          'Landlord: structural repairs, maintenance of installations provided, electrical and plumbing systems. Must maintain property in condition described in inventory. Tenant: minor interior maintenance, keeping property clean. If landlord fails: notify Housing Authority or file at Rent Regulation Board.',
      depositReturnRules:
          'Maximum deposit: 1 month rent (since 2020 Act). Return within 1 month of lease end. Deductions only for documented damages beyond fair wear and tear. Inventory comparison determines damages. If not returned: file at Rent Regulation Board or Housing Authority.',
      discriminationProtections:
          'Equal Treatment of Persons Order (2007) covers housing. National Commission for the Promotion of Equality (NCPE) handles complaints. Protected: race, ethnicity, religion, gender, sexual orientation, disability, age. EU nationals have equal rights. Malta Refugee Council advocates for asylum seeker housing rights.',
      immigrantSpecificNotes:
          'Large expat community. EU citizens register with Identity Malta. eResidence card needed for longer stays. Third-country nationals need residence permit. Housing market very tight and expensive (Valletta, Sliema, St. Julian\'s). ALWAYS register lease with Housing Authority - provides legal protection. Migrant Women Association Malta and various NGOs assist. English widely spoken and contracts often in English.',
      languageOfContracts: 'English or Maltese (English very common)',
    ),

    // ----------------------------------------------------------------
    // 20. NETHERLANDS (NL)
    // ----------------------------------------------------------------
    TenantRights(
      country: 'Netherlands',
      countryCode: 'NL',
      maxRentIncreasePercent: 5,
      evictionNoticeDays: 90,
      depositLimitExists: true,
      maxDepositMonths: 2,
      tenantProtectionAuthority:
          'Huurcommissie (Rent Tribunal) / Kantonrechter (Subdistrict Court)',
      tenantHotline: '0900-4688 399 (Huurcommissie) / 0900-235 3535 (Juridisch Loket)',
      tenantRights: [
        'Right to written lease agreement',
        'Right to "points system" (woningwaarderingsstelsel) rent assessment for regulated housing',
        'Right to challenge rent at Huurcommissie within 6 months of moving in',
        'Right to maintenance and repairs',
        'Right to privacy - landlord needs permission to enter',
        'Right to continue lease indefinitely (no fixed term for regulated)',
        'Right to huurtoeslag (rent allowance) for regulated housing',
        'Right to peaceful enjoyment',
      ],
      evictionProtections: [
        'Court order (Kantonrechter) ALWAYS required',
        'Landlord must prove "urgent personal use" (dringend eigen gebruik) or other legal ground',
        'Judge checks for alternative housing for tenant',
        'Tenant can request up to 1 year postponement',
        'Self-help eviction is criminal offense (huisvredebreuk)',
        'Regulated-sector tenants: virtually impossible to evict without cause',
        'Temporary contracts (max 2 years) end automatically but still need proper notice',
      ],
      legalBasis:
          'Burgerlijk Wetboek (Civil Code) Book 7, Title 4; Huurprijzenwet woonruimte; Wet op het overleg huurders en verhuurders',
      emergencyContact: '112 / 0800-1351 (Government info)',
      courtOrderRequiredForEviction: true,
      rentControlRules:
          'Two sectors: Regulated (below liberalization threshold, EUR ~879/month in 2024) - rent set by points system (WWS), annual increase capped by government (max 5.5% in 2024). Free sector (above threshold) - previously unregulated, now Wet Betaalbare Huur (2024) extends points system to mid-range rentals. Huurcommissie reviews rent for regulated housing. Points based on size, facilities, location, energy label.',
      repairObligations:
          'Landlord: all major maintenance and repairs. Must respond to repair requests. "Gebrekenregeling" at Huurcommissie allows rent reduction if landlord fails to repair. Categories: A (serious, 40% reduction), B (moderate, 20-30% reduction), C (minor). Tenant: small day-to-day maintenance per Besluit kleine herstellingen. If ignored: Huurcommissie or court can order repairs.',
      depositReturnRules:
          'Maximum deposit: 2 months rent (since July 2023 Wet Goed Verhuurderschap). Must be returned within 14 days after lease end if no deductions. If deductions, itemized list required. Old law had no limit. Landlord cannot charge key money or unreasonable fees. If not returned: file at Kantonrechter. Juridisch Loket provides free legal advice.',
      discriminationProtections:
          'Wet Goed Verhuurderschap (Good Landlord Act 2023) explicitly prohibits discrimination. Municipalities can fine discriminating landlords. College voor de Rechten van de Mens (Netherlands Institute for Human Rights) handles complaints. Protected: race, nationality, religion, gender, sexual orientation, disability, age. Active enforcement with mystery calling tests in Amsterdam, Rotterdam, Utrecht.',
      immigrantSpecificNotes:
          'Register at gemeente (municipality) for BSN (citizen service number) - ESSENTIAL for everything. EU citizens register at IND within 3 months. Huurtoeslag (rent allowance) for low-income regulated housing tenants. Social housing via Woningcorporaties (housing associations) - register at WoningNet, waiting lists can be 7-15 years in Amsterdam. Juridisch Loket offers free legal advice. !WOON Amsterdam specializes in tenant rights. Contracts in Dutch - get translation.',
      languageOfContracts: 'Dutch',
    ),

    // ----------------------------------------------------------------
    // 21. POLAND (PL)
    // ----------------------------------------------------------------
    TenantRights(
      country: 'Poland',
      countryCode: 'PL',
      maxRentIncreasePercent: 10,
      evictionNoticeDays: 90,
      depositLimitExists: true,
      maxDepositMonths: 12,
      tenantProtectionAuthority:
          'District Courts (Sąd Rejonowy) / Municipal authorities',
      tenantHotline: '+48 800 120 002 (Consumer helpline)',
      tenantRights: [
        'Right to written lease agreement (umowa najmu)',
        'Right to habitable dwelling',
        'Right to peaceful enjoyment',
        'Right to maintain lease if property changes hands',
        'Right to social housing (lokal socjalny) if facing eviction and vulnerable',
        'Right to receive advance notice of rent increases (3 months)',
        'Right to challenge excessive rent increase at court',
      ],
      evictionProtections: [
        'Court order ALWAYS required for eviction',
        'Court must verify if tenant qualifies for social housing (lokal socjalny)',
        'Municipality must provide social housing before eviction executed for vulnerable groups',
        'Pregnant women, minors, disabled, and elderly cannot be evicted to homeless',
        'Winter eviction restrictions (courts reluctant Nov-Mar)',
        'Eviction "to nowhere" (eksmisja na bruk) prohibited since 2005',
        'Self-help eviction is criminal offense',
      ],
      legalBasis:
          'Ustawa o ochronie praw lokatorów (Tenant Protection Act 2001, amended 2019); Kodeks Cywilny (Civil Code)',
      emergencyContact: '112 / 116 123 (Helpline)',
      courtOrderRequiredForEviction: true,
      rentControlRules:
          'Limited rent control: for municipal/social housing, rent per local council resolution. Private rental: rent freely negotiated. Rent increases limited to 10% per year in general (can be challenged if exceeds 3% of reconstruction value of premises). Landlord must give 3 months written notice for increase. Tenant can terminate if increase unacceptable.',
      repairObligations:
          'Landlord: structural repairs, installations (heating, plumbing, gas, electrical), common areas, exterior. Tenant: daily maintenance, minor repairs (floors, doors, windows interior, painting, kitchen/bathroom fixtures). Detailed list in Tenant Protection Act. If landlord fails: written demand, then court, or deduct from rent for urgent repairs.',
      depositReturnRules:
          'Maximum deposit: 12 months rent (high limit, typically 1-3 months in practice). Must be returned within 1 month of lease end and apartment return. Landlord can deduct unpaid rent and documented damages. If not returned: formal wezwanie do zapłaty (demand for payment), then district court. Quick payment procedure (nakaz zapłaty) available.',
      discriminationProtections:
          'Kodeks Karny (Criminal Code) Art. 256-257 and anti-discrimination provisions. Polish Commissioner for Human Rights (Rzecznik Praw Obywatelskich) handles complaints. EU anti-discrimination directives transposed. Protected: nationality, race, ethnicity, religion, disability, gender, sexual orientation. Discrimination against Ukrainians and Roma documented - actively reported.',
      immigrantSpecificNotes:
          'Massive Ukrainian community since 2022. EU citizens register at voivodeship office. PESEL number needed for legal rental. Third-country nationals need residence permit or temporary protection. Many Ukrainians have special protection status. Contracts often informal - ALWAYS insist on written umowa najmu. Stowarzyszenie Interwencji Prawnej (Association for Legal Intervention) provides free legal aid. Fundacja Ocalenie helps refugees with housing.',
      languageOfContracts: 'Polish',
    ),

    // ----------------------------------------------------------------
    // 22. PORTUGAL (PT)
    // ----------------------------------------------------------------
    TenantRights(
      country: 'Portugal',
      countryCode: 'PT',
      maxRentIncreasePercent: 2,
      evictionNoticeDays: 120,
      depositLimitExists: true,
      maxDepositMonths: 2,
      tenantProtectionAuthority:
          'Balcão Nacional do Arrendamento (BNA - National Rental Counter) / Tribunal Judicial',
      tenantHotline: '+351 217 906 200 (IHRU - Housing Institute)',
      tenantRights: [
        'Right to written lease agreement (registered with tax authority - Finanças)',
        'Right to minimum lease: 1 year (automatic renewal up to 3 years)',
        'Right to habitable dwelling meeting safety standards',
        'Right to rent receipt',
        'Right to pre-emption if landlord sells (direito de preferência)',
        'Right to maintain lease at controlled rent for elderly (65+) and disabled tenants',
        'Right to contest rent increase',
      ],
      evictionProtections: [
        'Court order or BNA procedure required for eviction',
        'Minimum 120 days notice for lease end (240 days for longer leases)',
        'Elderly tenants (65+) and disabled tenants in pre-2012 contracts: cannot be evicted for renovation',
        'Non-payment: landlord must use BNA fast-track procedure',
        'Tenant can cure arrears within 1 month of notification',
        'Moratorium on evictions for vulnerable tenants extended periodically',
        'Self-help eviction is criminal offense (coação)',
      ],
      legalBasis:
          'Novo Regime do Arrendamento Urbano (NRAU - Law 6/2006, amended by Law 31/2012 and Law 56/2023 "Mais Habitação")',
      emergencyContact: '112 / 808 200 204 (Social Security line)',
      courtOrderRequiredForEviction: true,
      rentControlRules:
          'Mais Habitação law (2023): extraordinary rent increase cap of 2% for 2024 (government compensates landlords). Transitional regime for old contracts (pre-1990): gradual rent updates. New contracts: rent freely set but annual increases limited to government coefficient (based on inflation). Lisbon and Porto have highest rents. Rent freeze for vulnerable elderly and disabled.',
      repairObligations:
          'Landlord: structural maintenance (8+ year works), exterior, roof, installations. Must maintain habitability. If building classified as degraded, municipality can order repairs. Tenant: minor maintenance (5-year works), interior. If landlord fails: formal notification, then repair and deduct from rent (up to 6 months rent), or court order, or report to municipal câmara.',
      depositReturnRules:
          'Maximum deposit: 2 months rent (since 2023 Mais Habitação). Previously no legal limit. Return within 1 month of lease end. Deductions for documented damages only. If not returned: formal demand (carta registada), then BNA or Tribunal. Julgados de Paz (small claims) for amounts under EUR 15,000.',
      discriminationProtections:
          'Lei n.º 93/2017 on anti-discrimination. CICDR (Commission for Equality and Against Racial Discrimination) handles complaints. Protected: race, nationality, ethnic origin, religion, disability, age, sexual orientation, gender. ACM (High Commission for Migration) promotes immigrant housing rights. Testing operations conducted.',
      immigrantSpecificNotes:
          'Large immigrant community (Brazilian, Angolan, Ukrainian, Indian, Nepalese). NIF (tax number) essential for everything. EU citizens register at câmara municipal. SEF/AIMA (immigration service) for third-country nationals. Mais Habitação law created "Porta 65 Jovem" (rent subsidy for under-35s) and affordable rent program. ACM provides multilingual housing advice. Many NGOs assist: JRS Portugal, PAR (Platform for Refugee Support). Rental market extremely tight in Lisbon/Porto.',
      languageOfContracts: 'Portuguese',
    ),

    // ----------------------------------------------------------------
    // 23. ROMANIA (RO)
    // ----------------------------------------------------------------
    TenantRights(
      country: 'Romania',
      countryCode: 'RO',
      maxRentIncreasePercent: 0,
      evictionNoticeDays: 30,
      depositLimitExists: false,
      maxDepositMonths: null,
      tenantProtectionAuthority:
          'Judecătoria (Court of First Instance) / National Authority for Consumer Protection (ANPC)',
      tenantHotline: '+40 21 9551 (ANPC)',
      tenantRights: [
        'Right to written lease agreement',
        'Right to habitable dwelling',
        'Right to peaceful enjoyment',
        'Right to register lease with tax authority (ANAF)',
        'Right to maintain lease terms per contract',
        'Right to essential services (heating, water, electricity)',
      ],
      evictionProtections: [
        'Court order required for eviction',
        'Self-help eviction illegal',
        'Tenant can contest eviction in court',
        'Court considers social circumstances',
        'Social housing available for vulnerable groups via local council',
      ],
      legalBasis:
          'Codul Civil (Civil Code 2011), Articles 1777-1835; Legea locuinței nr. 114/1996',
      emergencyContact: '112 / 0800 801 200 (Social emergency)',
      courtOrderRequiredForEviction: true,
      rentControlRules:
          'No rent control. Market rent fully liberalized. No statutory caps on increases. Contract terms govern. Social housing (locuință socială) has regulated rents set by local councils (very low). Private market rents increasing rapidly in Bucharest and Cluj-Napoca.',
      repairObligations:
          'Landlord: major/capital repairs, structural maintenance, installations. Must deliver dwelling in good condition. Tenant: minor repairs, interior maintenance, current upkeep (repairs from normal use). Civil Code specifies division. If landlord fails: written notification, repair and deduct, or court order.',
      depositReturnRules:
          'No statutory deposit limit (typically 1-3 months). Return per contract terms (usually 30 days). Landlord must prove damages to retain. If not returned: formal notificare (notification), then court. Process can be slow. Keep move-in photos and signed protocol (proces-verbal).',
      discriminationProtections:
          'OG 137/2000 on preventing discrimination. National Council for Combating Discrimination (CNCD) handles housing complaints. Protected: race, nationality, ethnicity, language, religion, disability, HIV status, social category, sexual orientation. Discrimination against Roma extensively documented. CNCD can impose fines.',
      immigrantSpecificNotes:
          'EU citizens register at IGI (General Inspectorate for Immigration). CNP (personal numeric code) needed for contracts. Third-country nationals need residence permit. Market relatively affordable but quality varies. Always insist on written contract registered with ANAF. ARCA (Romanian Forum for Refugees and Migrants) assists with housing. JRS Romania provides support for asylum seekers.',
      languageOfContracts: 'Romanian',
    ),

    // ----------------------------------------------------------------
    // 24. SLOVAKIA (SK)
    // ----------------------------------------------------------------
    TenantRights(
      country: 'Slovakia',
      countryCode: 'SK',
      maxRentIncreasePercent: 20,
      evictionNoticeDays: 90,
      depositLimitExists: true,
      maxDepositMonths: 3,
      tenantProtectionAuthority:
          'District Courts (Okresný súd) / Slovak Trade Inspection (SOI)',
      tenantHotline: '+421 2 5827 2172 (SOI)',
      tenantRights: [
        'Right to written lease agreement',
        'Right to habitable dwelling',
        'Right to peaceful enjoyment',
        'Right to maintain lease if property sold (registered lease)',
        'Right to alternative housing in certain eviction cases',
        'Right to extend lease under same terms if no termination notice given',
      ],
      evictionProtections: [
        'Court order required for eviction',
        'Minimum 3 months notice (can be 6 months if contract states)',
        'Replacement housing may be required before eviction for certain categories',
        'Court must assess tenant circumstances',
        'Families with minors receive special consideration',
        'Self-help eviction is criminal offense',
      ],
      legalBasis:
          'Občiansky zákonník (Civil Code No. 40/1964), Sections 685-716; Zákon o krátkodobom nájme bytu (Short-term Lease Act 98/2014)',
      emergencyContact: '112 / 0800 191 222 (Social helpline)',
      courtOrderRequiredForEviction: true,
      rentControlRules:
          'Limited rent regulation. Municipal housing has regulated rents. Private market: rent freely negotiated. Short-term Lease Act (2014) allows more flexibility for shorter leases. Rent increases per contract terms. If contract silent, reasonable notice required. No formal cap but excessive increases can be challenged.',
      repairObligations:
          'Landlord: major structural repairs, installations (heating, plumbing, electrical), facade, roof. Tenant: minor repairs up to EUR amount set by decree. If landlord fails to make repairs: written notice, then deduct from rent or court order.',
      depositReturnRules:
          'Maximum 3 months rent (Civil Code). Return within 1 month of lease end. Landlord can deduct unpaid rent and documented damages. Under Short-term Lease Act: similar rules, faster procedures. If not returned: formal demand, then district court.',
      discriminationProtections:
          'Antidiskriminačný zákon (Anti-Discrimination Act 365/2004). Slovak National Centre for Human Rights handles complaints. Protected: race, nationality, ethnicity, religion, disability, age, sexual orientation, gender. Roma housing discrimination extensively documented and sanctioned. EU citizens have equal rights.',
      immigrantSpecificNotes:
          'EU citizens register at Foreign Police within 10 days. Rodné číslo (birth number) or similar ID needed for contracts. Third-country nationals need residence permit. Slovenská humanitná rada (Slovak Humanitarian Council) assists migrants. League for Human Rights provides legal aid. Market affordable outside Bratislava. Contracts in Slovak.',
      languageOfContracts: 'Slovak',
    ),

    // ----------------------------------------------------------------
    // 25. SLOVENIA (SI)
    // ----------------------------------------------------------------
    TenantRights(
      country: 'Slovenia',
      countryCode: 'SI',
      maxRentIncreasePercent: 0,
      evictionNoticeDays: 90,
      depositLimitExists: true,
      maxDepositMonths: 3,
      tenantProtectionAuthority:
          'Housing Inspection (Stanovanjska inšpekcija) / District Courts',
      tenantHotline: '+386 1 478 97 56 (Housing Fund)',
      tenantRights: [
        'Right to written lease agreement',
        'Right to habitable dwelling meeting minimum standards',
        'Right to peaceful enjoyment',
        'Right to register with administrative unit (upravna enota)',
        'Right to maintain lease if property sold',
        'Right to essential maintenance by landlord',
        'Non-profit rent available in public housing',
      ],
      evictionProtections: [
        'Court order required for eviction',
        'Minimum 90 days notice for lease termination',
        'Valid reasons needed: non-payment (2+ months), damage, illegal use',
        'Court considers social circumstances (family, health, alternatives)',
        'Self-help eviction is illegal',
        'Social services notified for families with children',
      ],
      legalBasis:
          'Stanovanjski zakon (Housing Act, SZ-1, 2003); Obligacijski zakonik (Code of Obligations)',
      emergencyContact: '112 / 080 21 13 (CSD - Social Work Centre)',
      courtOrderRequiredForEviction: true,
      rentControlRules:
          'Two-tier system: Non-profit rent (neprofitna najemnina) for public/social housing - calculated per methodology (points system based on size, location, quality). Free-market rent for private housing - no caps. Annual increase for non-profit housing set by government. Private rent per contract terms.',
      repairObligations:
          'Landlord: structural maintenance, installations, maintaining habitability standards. Tenant: minor maintenance, interior upkeep. Housing inspection can order landlord to make repairs. If landlord fails: housing inspector, repair and deduct, or court order.',
      depositReturnRules:
          'Maximum deposit: 3 months rent. Return after lease ends and apartment inspected. Deductions for documented damages. No specific statutory deadline (practice: 30 days). If not returned: formal demand, then district court. Mediation available through court-annexed mediation.',
      discriminationProtections:
          'Zakon o varstvu pred diskriminacijo (Protection Against Discrimination Act 2016). Advocate of the Principle of Equality handles complaints. Protected: nationality, race, ethnicity, religion, disability, age, sexual orientation, gender identity, social status. Active monitoring and enforcement.',
      immigrantSpecificNotes:
          'EU citizens register at administrative unit (upravna enota) within 3 months. Tax number (davčna številka) needed. Third-country nationals need residence permit. Housing Fund of Republic of Slovenia (SSRS) manages social housing. PIC (Legal-Informational Centre for NGOs) provides free legal aid to immigrants. Slovenian Philanthropy assists refugees. Ljubljana has tightest market.',
      languageOfContracts: 'Slovenian',
    ),

    // ----------------------------------------------------------------
    // 26. SPAIN (ES)
    // ----------------------------------------------------------------
    TenantRights(
      country: 'Spain',
      countryCode: 'ES',
      maxRentIncreasePercent: 3,
      evictionNoticeDays: 120,
      depositLimitExists: true,
      maxDepositMonths: 2,
      tenantProtectionAuthority:
          'Servicio de Mediación y Arbitraje / Juzgado de Primera Instancia',
      tenantHotline: '+34 024 (Housing emergency line, operational since 2023)',
      tenantRights: [
        'Right to minimum 5-year lease (7 years if landlord is company)',
        'Right to habitable dwelling meeting CTE standards',
        'Right to automatic annual lease renewal up to 5/7 years',
        'Right to 3-year tacit renewal after initial period',
        'Right to preference if landlord sells (derecho de tanteo y retracto)',
        'Right to deposit with regional deposit agency (fianza)',
        'Right to Ley de Vivienda protections in stressed housing zones',
        'Right to maintain lease if property changes hands',
      ],
      evictionProtections: [
        'Court order (Juzgado de Primera Instancia) ALWAYS required',
        'Ley de Vivienda 2023: mandatory social services assessment before eviction',
        'Vulnerable households: eviction suspended until alternative housing found',
        'Minimum 4 months notice before lease end',
        'Non-payment: 10 business days to cure (enervación del desahucio - one time)',
        'Court can delay eviction up to 3 months (1 month if landlord is company)',
        'Large landlords (10+ properties): additional protections for tenants',
        'Illegal eviction (desahucio extrajudicial) is criminal offense',
      ],
      legalBasis:
          'Ley de Arrendamientos Urbanos (LAU 29/1994, reformed 2019); Ley por el Derecho a la Vivienda (12/2023)',
      emergencyContact: '024 (Housing emergency) / 112 (General emergency)',
      courtOrderRequiredForEviction: true,
      rentControlRules:
          'Ley de Vivienda 2023: in "zonas tensionadas" (stressed housing zones declared by regions), rent for new contracts capped at previous tenant rent. Large landlords: rent capped by reference index. Annual increases limited to 3% (2024) then new reference index. Catalonia implemented its own rent cap. Annual increase linked to INE reference index (replacing CPI).',
      repairObligations:
          'Landlord: all repairs needed to maintain habitability (structure, plumbing, electrical, heating, roof). Cannot pass cost to tenant. Urgent repairs: tenant can do and deduct. Tenant: minor maintenance from daily use (small repairs). If landlord refuses: formal burofax demand, then court can order repairs and rent reduction. Municipal housing inspection for code violations.',
      depositReturnRules:
          'Mandatory deposit: 1 month rent (unfurnished) or 2 months (furnished). Additional guarantee up to 2 months allowed. Deposit lodged with regional deposit agency (IVIMA Madrid, INCASOL Catalonia, etc.). Return within 1 month of lease end. After 1 month: legal interest accrues. Landlord must itemize deductions. If not returned: demand via burofax, then Juzgado. Fast verbal procedure (juicio verbal) for amounts under EUR 6,000.',
      discriminationProtections:
          'Ley Integral de Igualdad de Trato (2022) comprehensively covers housing. Council for the Elimination of Racial or Ethnic Discrimination handles complaints. Protected: race, ethnicity, nationality, religion, gender, sexual orientation, disability, age, social condition. Ley de Vivienda prohibits discrimination in housing access. Fines for discriminatory rental ads.',
      immigrantSpecificNotes:
          'NIE (Número de Identidad de Extranjero) ESSENTIAL for renting legally. EU citizens get NIE at police station. Empadronamiento (municipal registration) required regardless of immigration status and grants access to services. Social services must assist all residents regardless of status. Plataforma de Afectados por la Hipoteca (PAH) provides housing rights support. Free legal aid (justicia gratuita) for low-income residents. Many cities have Oficina de Vivienda (Housing Office) with multilingual staff.',
      languageOfContracts: 'Spanish (Catalan, Basque, Galician in respective regions)',
    ),

    // ----------------------------------------------------------------
    // 27. SWEDEN (SE)
    // ----------------------------------------------------------------
    TenantRights(
      country: 'Sweden',
      countryCode: 'SE',
      maxRentIncreasePercent: 0,
      evictionNoticeDays: 90,
      depositLimitExists: false,
      maxDepositMonths: null,
      tenantProtectionAuthority:
          'Hyresnämnden (Rent Tribunal) / Kronofogdemyndigheten (Enforcement Authority)',
      tenantHotline: '+46 771 72 72 00 (Hyresgästföreningen - Swedish Union of Tenants)',
      tenantRights: [
        'Right to "besittningsskydd" (security of tenure) - one of strongest in EU',
        'Right to negotiate rent through tenant union (bruksvärdessystem)',
        'Right to habitable dwelling meeting building standards',
        'Right to challenge rent at Hyresnämnden (Rent Tribunal)',
        'Right to exchange apartment (lägenhetsbyte) with landlord/tribunal approval',
        'Right to sublet with valid reason (landlord/tribunal approval)',
        'Right to maintain lease indefinitely - no fixed terms in standard rental',
        'Right to compensation if lease wrongfully terminated',
      ],
      evictionProtections: [
        'Besittningsskydd (security of tenure): landlord cannot terminate without legal ground',
        'Hyresnämnden (Rent Tribunal) mediates all disputes',
        'Valid grounds: non-payment (1 week cure period), disturbance, illegal use, personal need (rare)',
        'Non-payment must be 1+ week late, and tenant warned in writing',
        'Social services notified before eviction of families',
        'Kronofogden (Enforcement Authority) handles physical eviction - never landlord',
        'Wrongful termination: landlord liable for substantial damages',
        'Tenant can challenge at Hyresnämnden free of charge',
      ],
      legalBasis:
          'Jordabalken (Land Code) Chapter 12 "Hyreslagen" (Rent Act); Hyresförhandlingslagen (Rent Negotiation Act)',
      emergencyContact: '112 / 0771-72 72 00 (Hyresgästföreningen)',
      courtOrderRequiredForEviction: true,
      rentControlRules:
          'Bruksvärdessystemet (use-value system): rent negotiated collectively between landlord and Hyresgästföreningen (tenant union). Rent based on apartment "use value" (size, standard, location, amenities) compared to similar apartments. No individual rent negotiation in regulated sector. Annual increase agreed centrally. Private new-build (after 2006): can use "presumptionshyra" (presumption rent) for 15 years. Second-hand subletting: max 115% of own rent.',
      repairObligations:
          'Landlord fully responsible for maintaining apartment in usable condition. Structure, installations, appliances included in lease, common areas, exterior. Tenant must report defects without delay. If landlord fails to repair: Hyresnämnden can order repairs under penalty of fine. Rent reduction from date defect reported. Tenant responsible only for damage caused by negligence.',
      depositReturnRules:
          'Deposits uncommon in primary rental market (first-hand contracts via housing companies). For second-hand subletting: no statutory limit but typically 1-2 months. Return after lease end. If withheld: Hyresnämnden or Kronofogden for enforcement. Most disputes handled through Hyresnämnden (free). NOTE: "black market" deposits for queue-jumping are illegal.',
      discriminationProtections:
          'Diskrimineringslag (Discrimination Act 2008) strongly covers housing. Diskrimineringsombudsmannen (DO - Equality Ombudsman) investigates complaints and can take cases to court. Protected: sex, transgender identity, ethnicity, religion, disability, sexual orientation, age. Active testing operations. Substantial damages awarded. DO publishes annual housing discrimination report.',
      immigrantSpecificNotes:
          'Register at Skatteverket (Tax Agency) for personnummer - CRITICAL for housing queue. EU citizens register within 3 months. Housing queue system: register at Bostadsförmedlingen (Stockholm) or equivalent - average wait 9-12 years in Stockholm. Second-hand (andrahand) subletting more accessible but expensive. Hyresgästföreningen membership provides legal support. Kommunal bostadsförmedling in other cities. Many municipalities have housing for new arrivals (EBO system for refugees). Beware of rental scams - never pay before seeing apartment.',
      languageOfContracts: 'Swedish',
    ),
  ];

  // ====================================================================
  // UTILITY METHODS
  // ====================================================================

  /// Get all countries sorted by eviction notice period (most protective first)
  List<TenantRights> sortedByEvictionProtection() {
    final sorted = List<TenantRights>.from(allCountries);
    sorted.sort((a, b) => b.evictionNoticeDays.compareTo(a.evictionNoticeDays));
    return sorted;
  }

  /// Get all countries sorted by deposit limit (lowest first)
  List<TenantRights> sortedByDepositLimit() {
    final sorted =
        allCountries.where((c) => c.depositLimitExists).toList();
    sorted.sort((a, b) =>
        (a.maxDepositMonths ?? 99).compareTo(b.maxDepositMonths ?? 99));
    return sorted;
  }

  /// Get emergency contacts for a country
  Map<String, String> getEmergencyInfo(String countryCode) {
    final c = getByCountryCode(countryCode);
    if (c == null) return {};
    return {
      'country': c.country,
      'emergency': c.emergencyContact,
      'tenantHotline': c.tenantHotline ?? 'Not available',
      'authority': c.tenantProtectionAuthority,
    };
  }

  /// Quick answer: Can landlord evict without court order?
  String canLandlordEvictWithoutCourt(String countryCode) {
    final c = getByCountryCode(countryCode);
    if (c == null) return 'Country not found.';
    if (c.courtOrderRequiredForEviction) {
      return 'NO. In ${c.country}, a landlord CANNOT evict you without a court order. '
          'Self-help eviction (changing locks, cutting utilities, removing belongings) '
          'is ILLEGAL. If this happens to you, call the police (112) immediately. '
          'Contact: ${c.tenantProtectionAuthority}.';
    } else {
      return 'In ${c.country}, the eviction process varies. While legal procedures exist, '
          'always ensure your landlord follows proper legal channels. '
          'Contact: ${c.tenantProtectionAuthority} for specific advice.';
    }
  }

  /// Quick answer: What to do if landlord doesn't return deposit
  String depositNotReturnedAdvice(String countryCode) {
    final c = getByCountryCode(countryCode);
    if (c == null) return 'Country not found.';
    return 'DEPOSIT NOT RETURNED IN ${c.country.toUpperCase()}:\n\n'
        '1. Document everything: move-in/move-out photos, lease, correspondence\n'
        '2. Send formal written demand (registered letter/email with delivery confirmation)\n'
        '3. Allow reasonable response time (14-30 days)\n'
        '4. ${c.depositReturnRules}\n\n'
        'Maximum legal deposit: ${c.depositLimitExists ? "${c.maxDepositMonths} months rent" : "No statutory limit"}\n'
        'Contact: ${c.tenantProtectionAuthority}\n'
        'Hotline: ${c.tenantHotline ?? "See local authority"}';
  }

  /// Quick answer: Discrimination in housing - what to do
  String discriminationAdvice(String countryCode) {
    final c = getByCountryCode(countryCode);
    if (c == null) return 'Country not found.';
    return 'HOUSING DISCRIMINATION IN ${c.country.toUpperCase()}:\n\n'
        '${c.discriminationProtections}\n\n'
        'WHAT TO DO:\n'
        '1. Document the discrimination (save messages, record dates/times, get witnesses)\n'
        '2. File complaint with: ${c.tenantProtectionAuthority}\n'
        '3. Contact equality body mentioned above\n'
        '4. You have the right to compensation\n'
        '5. EU Directive 2000/43/EC protects against racial/ethnic discrimination in housing in ALL EU countries\n\n'
        'FOR IMMIGRANTS: ${c.immigrantSpecificNotes}';
  }

  /// Get a quick checklist for immigrants renting in a specific country
  List<String> immigrantRentingChecklist(String countryCode) {
    final c = getByCountryCode(countryCode);
    if (c == null) return ['Country not found.'];
    return [
      'GET REGISTERED: Register your address with local authorities immediately',
      'GET ID NUMBER: Obtain local tax/personal ID number (essential for contracts)',
      'WRITTEN CONTRACT: ALWAYS insist on a written lease agreement',
      'LANGUAGE: Contracts typically in ${c.languageOfContracts} - get translation if needed',
      'DEPOSIT: ${c.depositLimitExists ? "Maximum legal deposit: ${c.maxDepositMonths} months rent" : "No legal deposit limit - negotiate carefully"}',
      'DOCUMENT CONDITION: Take photos/video of apartment at move-in, get landlord to sign inventory',
      'KNOW YOUR RIGHTS: Court order required for eviction: ${c.courtOrderRequiredForEviction ? "YES" : "Check local rules"}',
      'NOTICE PERIOD: Landlord must give minimum ${c.evictionNoticeDays} days notice',
      'GET HELP: Contact ${c.tenantProtectionAuthority}',
      'EMERGENCY: ${c.emergencyContact}',
      'DISCRIMINATION IS ILLEGAL: If refused housing due to nationality/ethnicity, file complaint',
      'NEVER PAY CASH without receipt. Keep all payment records.',
    ];
  }
}
