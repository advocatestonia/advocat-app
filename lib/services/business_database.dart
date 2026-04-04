/// Comprehensive EU27 Business Formation Database for Immigrants
/// Contains real registration data for all 27 EU member states.
/// Sources: National business registries, EU Commission SME portal,
/// national tax authorities, Invest Europe, OECD migration policy.
/// Last verified: 2026-Q1
///
/// DISCLAIMER: Business registration rules change frequently. Always verify
/// current requirements with the relevant national authority before proceeding.
library;

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

class CompanyType {
  final String localName;
  final String englishName;
  final String abbreviation;
  final String description;
  final double? minimumCapital;
  final bool capitalFullyPaidUpfront;
  final int minShareholders;
  final int minDirectors;
  final String liabilityType;
  final List<String> notes;

  const CompanyType({
    required this.localName,
    required this.englishName,
    required this.abbreviation,
    required this.description,
    this.minimumCapital,
    required this.capitalFullyPaidUpfront,
    required this.minShareholders,
    required this.minDirectors,
    required this.liabilityType,
    this.notes = const [],
  });

  Map<String, dynamic> toMap() => {
        'localName': localName,
        'englishName': englishName,
        'abbreviation': abbreviation,
        'description': description,
        'minimumCapital': minimumCapital,
        'capitalFullyPaidUpfront': capitalFullyPaidUpfront,
        'minShareholders': minShareholders,
        'minDirectors': minDirectors,
        'liabilityType': liabilityType,
        'notes': notes,
      };
}

class TaxInfo {
  final double corporateTaxRate;
  final String? corporateTaxNotes;
  final double vatStandardRate;
  final double? vatReducedRate;
  final double? vatRegistrationThreshold;
  final String incomeTaxRange;
  final String? socialContributions;
  final String taxAuthority;
  final String? taxAuthorityUrl;

  const TaxInfo({
    required this.corporateTaxRate,
    this.corporateTaxNotes,
    required this.vatStandardRate,
    this.vatReducedRate,
    this.vatRegistrationThreshold,
    required this.incomeTaxRange,
    this.socialContributions,
    required this.taxAuthority,
    this.taxAuthorityUrl,
  });

  Map<String, dynamic> toMap() => {
        'corporateTaxRate': corporateTaxRate,
        'corporateTaxNotes': corporateTaxNotes,
        'vatStandardRate': vatStandardRate,
        'vatReducedRate': vatReducedRate,
        'vatRegistrationThreshold': vatRegistrationThreshold,
        'incomeTaxRange': incomeTaxRange,
        'socialContributions': socialContributions,
        'taxAuthority': taxAuthority,
        'taxAuthorityUrl': taxAuthorityUrl,
      };
}

class StartupVisaProgram {
  final String name;
  final String description;
  final List<String> requirements;
  final String? investmentMinimum;
  final String validityPeriod;
  final bool pathToResidence;
  final String? officialUrl;

  const StartupVisaProgram({
    required this.name,
    required this.description,
    required this.requirements,
    this.investmentMinimum,
    required this.validityPeriod,
    required this.pathToResidence,
    this.officialUrl,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'requirements': requirements,
        'investmentMinimum': investmentMinimum,
        'validityPeriod': validityPeriod,
        'pathToResidence': pathToResidence,
        'officialUrl': officialUrl,
      };
}

class BusinessIncubator {
  final String name;
  final String city;
  final String focus;
  final bool immigrantFriendly;
  final String? website;

  const BusinessIncubator({
    required this.name,
    required this.city,
    required this.focus,
    required this.immigrantFriendly,
    this.website,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'city': city,
        'focus': focus,
        'immigrantFriendly': immigrantFriendly,
        'website': website,
      };
}

class CountryBusinessGuide {
  final String country;
  final String countryCode;
  final bool immigrantsCanStartBusiness;
  final String immigrantBusinessSummary;
  final List<String> permitRequirements;
  final List<CompanyType> companyTypes;
  final List<String> registrationSteps;
  final String registrationTimeline;
  final String registrationCost;
  final TaxInfo taxInfo;
  final List<String> bankAccountRequirements;
  final List<String> accountingObligations;
  final List<String> hiringRulesForForeignEmployers;
  final List<StartupVisaProgram> startupVisaPrograms;
  final List<BusinessIncubator> incubators;
  final List<String> governmentGrants;
  final String businessAuthority;
  final String? businessAuthorityUrl;
  final String? businessAuthorityPhone;
  final List<String> additionalNotes;

  const CountryBusinessGuide({
    required this.country,
    required this.countryCode,
    required this.immigrantsCanStartBusiness,
    required this.immigrantBusinessSummary,
    required this.permitRequirements,
    required this.companyTypes,
    required this.registrationSteps,
    required this.registrationTimeline,
    required this.registrationCost,
    required this.taxInfo,
    required this.bankAccountRequirements,
    required this.accountingObligations,
    required this.hiringRulesForForeignEmployers,
    this.startupVisaPrograms = const [],
    this.incubators = const [],
    this.governmentGrants = const [],
    required this.businessAuthority,
    this.businessAuthorityUrl,
    this.businessAuthorityPhone,
    this.additionalNotes = const [],
  });

  Map<String, dynamic> toMap() => {
        'country': country,
        'countryCode': countryCode,
        'immigrantsCanStartBusiness': immigrantsCanStartBusiness,
        'immigrantBusinessSummary': immigrantBusinessSummary,
        'permitRequirements': permitRequirements,
        'companyTypes': companyTypes.map((c) => c.toMap()).toList(),
        'registrationSteps': registrationSteps,
        'registrationTimeline': registrationTimeline,
        'registrationCost': registrationCost,
        'taxInfo': taxInfo.toMap(),
        'bankAccountRequirements': bankAccountRequirements,
        'accountingObligations': accountingObligations,
        'hiringRulesForForeignEmployers': hiringRulesForForeignEmployers,
        'startupVisaPrograms':
            startupVisaPrograms.map((s) => s.toMap()).toList(),
        'incubators': incubators.map((i) => i.toMap()).toList(),
        'governmentGrants': governmentGrants,
        'businessAuthority': businessAuthority,
        'businessAuthorityUrl': businessAuthorityUrl,
        'businessAuthorityPhone': businessAuthorityPhone,
        'additionalNotes': additionalNotes,
      };
}

// ---------------------------------------------------------------------------
// Main database class
// ---------------------------------------------------------------------------

class BusinessDatabase {
  static final BusinessDatabase _instance = BusinessDatabase._internal();
  factory BusinessDatabase() => _instance;
  BusinessDatabase._internal();

  /// Get guide for a specific country by ISO code
  CountryBusinessGuide? getByCountry(String countryCode) {
    final code = countryCode.toUpperCase();
    try {
      return _allGuides.firstWhere((g) => g.countryCode == code);
    } catch (_) {
      return null;
    }
  }

  /// Get all 27 country guides
  List<CountryBusinessGuide> getAll() => List.unmodifiable(_allGuides);

  /// Countries where immigrants can start a business without special permit
  List<CountryBusinessGuide> getEasiestForImmigrants() {
    return _allGuides
        .where((g) =>
            g.immigrantsCanStartBusiness &&
            g.startupVisaPrograms.isNotEmpty)
        .toList();
  }

  /// Countries with startup visa programs
  List<CountryBusinessGuide> getWithStartupVisa() {
    return _allGuides
        .where((g) => g.startupVisaPrograms.isNotEmpty)
        .toList();
  }

  /// Countries with lowest minimum capital requirements
  List<CountryBusinessGuide> getLowestCapitalRequirements() {
    final sorted = List<CountryBusinessGuide>.from(_allGuides);
    sorted.sort((a, b) {
      final aMin = a.companyTypes
          .where((c) => c.minimumCapital != null && c.minimumCapital! > 0)
          .fold<double>(double.infinity,
              (prev, c) => c.minimumCapital! < prev ? c.minimumCapital! : prev);
      final bMin = b.companyTypes
          .where((c) => c.minimumCapital != null && c.minimumCapital! > 0)
          .fold<double>(double.infinity,
              (prev, c) => c.minimumCapital! < prev ? c.minimumCapital! : prev);
      return aMin.compareTo(bMin);
    });
    return sorted;
  }

  /// Get all countries sorted by corporate tax rate
  List<CountryBusinessGuide> getSortedByCorporateTax() {
    final sorted = List<CountryBusinessGuide>.from(_allGuides);
    sorted.sort(
        (a, b) => a.taxInfo.corporateTaxRate.compareTo(b.taxInfo.corporateTaxRate));
    return sorted;
  }

  /// Search across all countries
  List<CountryBusinessGuide> search(String query) {
    final q = query.toLowerCase();
    return _allGuides.where((g) {
      return g.country.toLowerCase().contains(q) ||
          g.immigrantBusinessSummary.toLowerCase().contains(q) ||
          g.companyTypes.any((c) =>
              c.englishName.toLowerCase().contains(q) ||
              c.localName.toLowerCase().contains(q)) ||
          g.startupVisaPrograms.any((s) =>
              s.name.toLowerCase().contains(q));
    }).toList();
  }

  // =========================================================================
  // FULL DATABASE — 27 EU MEMBER STATES
  // =========================================================================

  static const List<CountryBusinessGuide> _allGuides = [

    // -----------------------------------------------------------------------
    // 1. AUSTRIA (AT)
    // -----------------------------------------------------------------------
    CountryBusinessGuide(
      country: 'Austria',
      countryCode: 'AT',
      immigrantsCanStartBusiness: true,
      immigrantBusinessSummary:
          'Non-EU nationals need a residence permit with self-employment rights '
          '(Aufenthaltsbewilligung Selbstständiger) or a Red-White-Red Card for '
          'self-employed key workers. EU/EEA citizens have free establishment rights.',
      permitRequirements: [
        'Red-White-Red Card for self-employed key workers (points-based)',
        'Proof of economic benefit to Austria (investment, job creation)',
        'Minimum investment typically EUR 100,000 or creation of new jobs',
        'Business plan reviewed by Austrian Economic Chamber (WKO)',
        'EU/EEA citizens: freedom of establishment, register Gewerbe only',
      ],
      companyTypes: [
        CompanyType(
          localName: 'Gesellschaft mit beschränkter Haftung',
          englishName: 'Limited Liability Company',
          abbreviation: 'GmbH',
          description: 'Most popular form for SMEs, limited liability',
          minimumCapital: 35000,
          capitalFullyPaidUpfront: false,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited to share capital',
          notes: [
            'Minimum EUR 17,500 paid up at formation (50%)',
            'Privileged formation: EUR 10,000 capital (EUR 5,000 paid) for first 10 years',
            'Notarial deed required for articles of association',
          ],
        ),
        CompanyType(
          localName: 'Aktiengesellschaft',
          englishName: 'Joint Stock Company',
          abbreviation: 'AG',
          description: 'For larger enterprises, shares tradeable',
          minimumCapital: 70000,
          capitalFullyPaidUpfront: false,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited to share capital',
          notes: ['Supervisory board mandatory if >300 employees or capital >70K'],
        ),
        CompanyType(
          localName: 'Einzelunternehmen',
          englishName: 'Sole Proprietorship',
          abbreviation: 'e.U.',
          description: 'Simplest form, personal unlimited liability',
          minimumCapital: 0,
          capitalFullyPaidUpfront: true,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Unlimited personal liability',
        ),
      ],
      registrationSteps: [
        '1. Obtain trade license (Gewerbeberechtigung) from local trade authority',
        '2. Draft articles of association (notarized for GmbH)',
        '3. Open bank account and deposit share capital',
        '4. Register with Commercial Register (Firmenbuch) at regional court',
        '5. Register with tax office (Finanzamt) for tax number',
        '6. Register for social insurance (SVS for self-employed)',
        '7. Register employees with health insurance fund if applicable',
        '8. Register with Austrian Economic Chamber (WKO) - automatic for Gewerbe',
      ],
      registrationTimeline: '1-4 weeks (GmbH); 1-2 days (sole proprietor)',
      registrationCost:
          'GmbH: ~EUR 1,500-3,000 (notary ~EUR 1,000, court ~EUR 400, misc fees). '
          'Sole proprietor: ~EUR 50-200.',
      taxInfo: TaxInfo(
        corporateTaxRate: 23.0,
        corporateTaxNotes: 'Reduced from 25% to 23% in 2024. Minimum tax EUR 1,750/year for GmbH.',
        vatStandardRate: 20.0,
        vatReducedRate: 10.0,
        vatRegistrationThreshold: 35000,
        incomeTaxRange: '0% (up to EUR 12,816) to 55% (over EUR 1,000,000)',
        socialContributions:
            'Self-employed: ~26.83% (pension, health, accident via SVS)',
        taxAuthority: 'Bundesministerium für Finanzen (BMF)',
        taxAuthorityUrl: 'https://www.bmf.gv.at',
      ),
      bankAccountRequirements: [
        'Passport/ID, proof of address in Austria',
        'Company registration extract (Firmenbuchauszug)',
        'Trade license (Gewerbeschein)',
        'Signed articles of association',
        'AML/KYC compliance documentation',
        'Non-residents may face additional scrutiny; some banks require Austrian address',
      ],
      accountingObligations: [
        'Double-entry bookkeeping mandatory if turnover > EUR 700,000/year',
        'Small businesses (< EUR 700,000): simple income/expense accounting',
        'Annual financial statements must be filed with Firmenbuch (GmbH/AG)',
        'Monthly/quarterly VAT returns',
        'Annual corporate tax return by June 30 of following year',
        'Payroll reporting monthly if employees hired',
      ],
      hiringRulesForForeignEmployers: [
        'Must register as employer with social insurance (ÖGK)',
        'Non-EU employees need work permits (Beschäftigungsbewilligung)',
        'Minimum wages set by collective agreements (Kollektivvertrag)',
        'Written employment contract required',
        '13th and 14th month salary payments mandatory',
        'Employer social contributions ~21% of gross salary',
      ],
      startupVisaPrograms: [
        StartupVisaProgram(
          name: 'Red-White-Red Card for Start-up Founders',
          description:
              'Residence permit for innovative start-up founders from third countries',
          requirements: [
            'Innovative business idea evaluated by approved incubator',
            'Sufficient financial means (approx. EUR 1,200/month)',
            'Health insurance coverage',
            'Accommodation in Austria',
            'English or German language skills (A2 minimum)',
          ],
          validityPeriod: '2 years, renewable',
          pathToResidence: true,
          officialUrl: 'https://www.migration.gv.at',
        ),
      ],
      incubators: [
        BusinessIncubator(
          name: 'AWS (Austria Wirtschaftsservice)',
          city: 'Vienna',
          focus: 'General startup support, grants',
          immigrantFriendly: true,
          website: 'https://www.aws.at',
        ),
        BusinessIncubator(
          name: 'Vienna Business Agency',
          city: 'Vienna',
          focus: 'Tech, creative industries',
          immigrantFriendly: true,
          website: 'https://viennabusinessagency.at',
        ),
      ],
      governmentGrants: [
        'AWS Gründungsfonds: up to EUR 50,000 for innovative startups',
        'FFG Basisprogramm: R&D funding up to EUR 1M',
        'Neugründungsförderung (NeuFöG): exemption from various fees for new founders',
        'AMS Unternehmensgründungsprogramm: support for unemployed becoming self-employed',
      ],
      businessAuthority: 'Austrian Business Service (AWS) / Federal Economic Chamber (WKO)',
      businessAuthorityUrl: 'https://www.wko.at',
      businessAuthorityPhone: '+43 590 900',
    ),

    // -----------------------------------------------------------------------
    // 2. BELGIUM (BE)
    // -----------------------------------------------------------------------
    CountryBusinessGuide(
      country: 'Belgium',
      countryCode: 'BE',
      immigrantsCanStartBusiness: true,
      immigrantBusinessSummary:
          'Non-EU nationals need a Professional Card (Carte Professionnelle) to start '
          'a business. Application via Belgian embassy or online. EU citizens have full '
          'freedom of establishment.',
      permitRequirements: [
        'Professional Card (Carte Professionnelle) for non-EU nationals',
        'Application submitted before arrival or within 3 months of residence',
        'Business plan showing economic value for Belgium',
        'Proof of qualifications/experience',
        'Clean criminal record',
        'EU citizens: register at commune, start immediately',
      ],
      companyTypes: [
        CompanyType(
          localName: 'Besloten Vennootschap / Société à responsabilité limitée',
          englishName: 'Private Limited Company',
          abbreviation: 'BV/SRL',
          description: 'Most common form since 2019 reform, flexible structure',
          minimumCapital: 1,
          capitalFullyPaidUpfront: false,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited to contribution',
          notes: [
            'No minimum capital since 2019 Companies Code reform',
            'Must have sufficient starting capital (tested by financial plan)',
            'Financial plan prepared by accountant is mandatory',
          ],
        ),
        CompanyType(
          localName: 'Naamloze Vennootschap / Société anonyme',
          englishName: 'Public Limited Company',
          abbreviation: 'NV/SA',
          description: 'For larger companies, shares freely transferable',
          minimumCapital: 61500,
          capitalFullyPaidUpfront: false,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited to share capital',
          notes: ['At least EUR 61,500, one-quarter paid up at formation'],
        ),
        CompanyType(
          localName: 'Eenmanszaak / Entreprise individuelle',
          englishName: 'Sole Proprietorship',
          abbreviation: '-',
          description: 'Simple registration at Crossroads Bank for Enterprises',
          minimumCapital: 0,
          capitalFullyPaidUpfront: true,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Unlimited personal liability',
        ),
      ],
      registrationSteps: [
        '1. Draft articles of association (notarial deed for BV/SRL)',
        '2. Deposit capital in blocked bank account',
        '3. Notary files with Commercial Court clerk',
        '4. Obtain enterprise number from Crossroads Bank for Enterprises (BCE/KBO)',
        '5. Activate VAT status at local VAT office',
        '6. Register with social insurance fund for self-employed (within 90 days)',
        '7. Join a health insurance fund (mutualité/mutualiteit)',
        '8. Obtain permits if regulated profession',
      ],
      registrationTimeline: '3-5 business days for BV/SRL; 1 day for sole proprietor',
      registrationCost:
          'BV/SRL: ~EUR 1,500-2,500 (notary ~EUR 1,000, publication ~EUR 250, misc). '
          'Sole proprietor: ~EUR 90 (enterprise counter fee).',
      taxInfo: TaxInfo(
        corporateTaxRate: 25.0,
        corporateTaxNotes: 'Reduced rate 20% on first EUR 100,000 for small companies',
        vatStandardRate: 21.0,
        vatReducedRate: 6.0,
        vatRegistrationThreshold: 25000,
        incomeTaxRange: '25% (up to EUR 15,820) to 50% (over EUR 46,440)',
        socialContributions:
            'Self-employed: ~20.5% of net income (quarterly contributions)',
        taxAuthority: 'Service Public Fédéral Finances / FOD Financiën',
        taxAuthorityUrl: 'https://finance.belgium.be',
      ),
      bankAccountRequirements: [
        'Valid ID/passport',
        'Belgian address (registered at commune)',
        'Enterprise number (BCE/KBO)',
        'Articles of association',
        'Beneficial ownership declaration',
        'Some banks require appointment; N26/Wise accepted for start',
      ],
      accountingObligations: [
        'All companies must keep double-entry books',
        'Annual accounts filed with National Bank of Belgium',
        'VAT returns: monthly (turnover >EUR 2.5M) or quarterly',
        'Corporate tax return due 7 months after financial year end',
        'Statutory auditor required if company exceeds 2 of 3 thresholds: '
            'EUR 9M turnover, EUR 4.5M assets, 50 employees',
      ],
      hiringRulesForForeignEmployers: [
        'Employment contract must be in language of company region (Dutch/French/German)',
        'Register with ONSS/RSZ (social security office)',
        'Non-EU workers need combined work-residence permit (Single Permit)',
        'Minimum wages vary by sector (Joint Committees/Paritaire Comités)',
        'Employer social contributions ~25% of gross salary',
        'Mandatory 13th month pay in most sectors',
      ],
      startupVisaPrograms: [],
      incubators: [
        BusinessIncubator(
          name: 'Start it @KBC',
          city: 'Multiple cities',
          focus: 'Tech startups, free program',
          immigrantFriendly: true,
          website: 'https://startit.be',
        ),
        BusinessIncubator(
          name: 'Imec.istart',
          city: 'Leuven',
          focus: 'Deep tech, hardware, IoT',
          immigrantFriendly: true,
          website: 'https://www.imec-int.com/en/istart',
        ),
      ],
      governmentGrants: [
        'SME e-wallet (Flanders): up to EUR 10,000 for training/advice',
        'Brusoc microloans (Brussels): up to EUR 25,000',
        'SOWALFIN guarantees (Wallonia): bank loan guarantees for startups',
        'Win-win loan: tax benefit for private investors in startups',
      ],
      businessAuthority: 'Crossroads Bank for Enterprises (BCE/KBO)',
      businessAuthorityUrl: 'https://economie.fgov.be',
      businessAuthorityPhone: '+32 2 277 51 11',
    ),

    // -----------------------------------------------------------------------
    // 3. BULGARIA (BG)
    // -----------------------------------------------------------------------
    CountryBusinessGuide(
      country: 'Bulgaria',
      countryCode: 'BG',
      immigrantsCanStartBusiness: true,
      immigrantBusinessSummary:
          'Non-EU nationals can register a company without a residence permit, but need '
          'a Type D visa and residence permit to manage it from Bulgaria. Owning a company '
          'can support a residence permit application.',
      permitRequirements: [
        'Company registration possible without residence permit',
        'Type D long-stay visa needed to reside and manage the business',
        'Residence permit for self-employed: proof of business activity',
        'Investment of at least BGN 500,000 (~EUR 256,000) for investor permit',
        'EU citizens: register freely with Bulgarian ID card',
      ],
      companyTypes: [
        CompanyType(
          localName: 'Дружество с ограничена отговорност',
          englishName: 'Limited Liability Company',
          abbreviation: 'OOD/EOOD',
          description: 'Most popular form. EOOD = single member.',
          minimumCapital: 1,
          capitalFullyPaidUpfront: true,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited to share capital',
          notes: [
            'Minimum capital BGN 2 (~EUR 1) since 2009',
            'EOOD is single-member LLC, OOD is multi-member',
          ],
        ),
        CompanyType(
          localName: 'Акционерно дружество',
          englishName: 'Joint Stock Company',
          abbreviation: 'AD/EAD',
          description: 'For larger companies',
          minimumCapital: 25000,
          capitalFullyPaidUpfront: false,
          minShareholders: 1,
          minDirectors: 3,
          liabilityType: 'Limited to share capital',
          notes: ['BGN 50,000 (~EUR 25,000) minimum'],
        ),
        CompanyType(
          localName: 'Едноличен търговец',
          englishName: 'Sole Trader',
          abbreviation: 'ET',
          description: 'Individual entrepreneur',
          minimumCapital: 0,
          capitalFullyPaidUpfront: true,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Unlimited personal liability',
          notes: ['Only available to Bulgarian residents or EU citizens'],
        ),
      ],
      registrationSteps: [
        '1. Choose unique company name (check at Commercial Register)',
        '2. Draft articles of association',
        '3. Open bank account, deposit capital',
        '4. File application with Commercial Register (Registry Agency)',
        '5. Obtain Bulstat/EIK unified identification code',
        '6. Register for VAT if threshold met (BGN 166,000)',
        '7. Register with NRA (National Revenue Agency) for tax',
        '8. Register employees with NRA and social security',
      ],
      registrationTimeline: '1-3 business days',
      registrationCost:
          'EOOD: ~EUR 150-300 (registration fee BGN 110, publication BGN 40, misc). '
          'With lawyer: ~EUR 300-500 total.',
      taxInfo: TaxInfo(
        corporateTaxRate: 10.0,
        corporateTaxNotes: 'Flat 10% — lowest in the EU',
        vatStandardRate: 20.0,
        vatReducedRate: 9.0,
        vatRegistrationThreshold: 25565,
        incomeTaxRange: '10% flat rate on personal income',
        socialContributions:
            'Self-employed: ~31% on declared income (min BGN 933/month base)',
        taxAuthority: 'National Revenue Agency (NRA / НАП)',
        taxAuthorityUrl: 'https://www.nra.bg',
      ),
      bankAccountRequirements: [
        'Passport, Bulgarian address',
        'Company registration certificate (EIK)',
        'Articles of association',
        'Decision of appointment of manager',
        'Some banks accept non-residents; others require Bulgarian ID',
      ],
      accountingObligations: [
        'All companies must maintain double-entry bookkeeping',
        'Annual financial statements filed with Commercial Register',
        'Corporate tax return due March 31',
        'Monthly VAT returns if registered',
        'Annual statistical reports to NSI',
      ],
      hiringRulesForForeignEmployers: [
        'Register employees with NRA within 3 days of hiring',
        'Non-EU workers need work permits from Employment Agency',
        'Minimum wage: BGN 933/month (~EUR 477) in 2026',
        'Employer social contributions ~18-19% of gross salary',
        'Written employment contract mandatory, in Bulgarian',
      ],
      startupVisaPrograms: [],
      incubators: [
        BusinessIncubator(
          name: 'Eleven Ventures',
          city: 'Sofia',
          focus: 'Tech startups, seed funding',
          immigrantFriendly: true,
          website: 'https://www.11.me',
        ),
        BusinessIncubator(
          name: 'Campus X',
          city: 'Sofia',
          focus: 'General startup support',
          immigrantFriendly: true,
          website: 'https://campusx.bg',
        ),
      ],
      governmentGrants: [
        'OP Innovation and Competitiveness: EU co-funded grants for SMEs',
        'National Innovation Fund: R&D project funding',
        'JEREMIE/equity instruments via Fund of Funds',
        'Municipal startup programs in Sofia',
      ],
      businessAuthority: 'Registry Agency (Агенция по вписванията)',
      businessAuthorityUrl: 'https://www.registryagency.bg',
      businessAuthorityPhone: '+359 2 948 89 02',
    ),

    // -----------------------------------------------------------------------
    // 4. CROATIA (HR)
    // -----------------------------------------------------------------------
    CountryBusinessGuide(
      country: 'Croatia',
      countryCode: 'HR',
      immigrantsCanStartBusiness: true,
      immigrantBusinessSummary:
          'Non-EU nationals can register a company (d.o.o.) and then apply for a '
          'temporary residence permit for self-employment. Company ownership alone does '
          'not grant residence; a separate permit is needed.',
      permitRequirements: [
        'Register company first, then apply for temporary stay for self-employment',
        'Proof of sufficient funds and accommodation',
        'Health insurance coverage',
        'No criminal record',
        'EU citizens: register and start business freely',
      ],
      companyTypes: [
        CompanyType(
          localName: 'Društvo s ograničenom odgovornošću',
          englishName: 'Limited Liability Company',
          abbreviation: 'd.o.o.',
          description: 'Standard LLC, most common',
          minimumCapital: 2500,
          capitalFullyPaidUpfront: false,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited to share capital',
          notes: ['EUR 2,500 minimum since Croatia adopted EUR in 2023'],
        ),
        CompanyType(
          localName: 'Jednostavno društvo s ograničenom odgovornošću',
          englishName: 'Simple Limited Liability Company',
          abbreviation: 'j.d.o.o.',
          description: 'Simplified LLC for small businesses',
          minimumCapital: 1,
          capitalFullyPaidUpfront: true,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited to share capital',
          notes: [
            'Min EUR 1, max 3 members, max 3 board members',
            'Must allocate 25% of profit to reserves until EUR 2,500 reached',
          ],
        ),
        CompanyType(
          localName: 'Obrt',
          englishName: 'Sole Proprietorship / Craft Business',
          abbreviation: 'Obrt',
          description: 'Simple business form, personal liability',
          minimumCapital: 0,
          capitalFullyPaidUpfront: true,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Unlimited personal liability',
          notes: ['Requires Croatian residence permit'],
        ),
      ],
      registrationSteps: [
        '1. Choose company name (check with Court Register)',
        '2. Draft articles of association (notarized)',
        '3. Open temporary bank account, deposit capital',
        '4. Register with Commercial Court (Trgovački sud)',
        '5. Receive OIB (personal identification number)',
        '6. Register with Tax Administration (Porezna uprava)',
        '7. Register for VAT if applicable',
        '8. Open permanent business bank account',
      ],
      registrationTimeline: '3-7 business days',
      registrationCost:
          'd.o.o.: ~EUR 400-800 (notary ~EUR 200, court fee EUR 40, publication EUR 10). '
          'j.d.o.o.: ~EUR 50-100 (simplified procedure via HITRO.HR).',
      taxInfo: TaxInfo(
        corporateTaxRate: 18.0,
        corporateTaxNotes: '10% for small taxpayers (revenue < EUR 1M)',
        vatStandardRate: 25.0,
        vatReducedRate: 13.0,
        vatRegistrationThreshold: 40000,
        incomeTaxRange: '20% (up to EUR 50,400) and 30% (above)',
        socialContributions:
            'Self-employed: ~37.2% on declared income base',
        taxAuthority: 'Tax Administration (Porezna uprava)',
        taxAuthorityUrl: 'https://www.porezna-uprava.hr',
      ),
      bankAccountRequirements: [
        'Passport, OIB number',
        'Company registration extract',
        'Articles of association',
        'Director appointment decision',
        'Croatian address for correspondence',
      ],
      accountingObligations: [
        'Double-entry bookkeeping for all d.o.o. companies',
        'Annual financial statements to FINA (Financial Agency)',
        'Monthly/quarterly VAT returns',
        'Annual corporate/income tax return',
        'Small businesses: simplified records allowed',
      ],
      hiringRulesForForeignEmployers: [
        'Register employees with HZMO (pension) and HZZO (health)',
        'Non-EU workers need work permits (annual quota system)',
        'Minimum gross wage: ~EUR 840/month (2026)',
        'Employer contributions ~16.5% of gross salary',
        'Written contract required in Croatian',
      ],
      startupVisaPrograms: [
        StartupVisaProgram(
          name: 'Digital Nomad Visa',
          description: 'For remote workers/freelancers working for foreign clients',
          requirements: [
            'Proof of remote work/freelance income',
            'Minimum income EUR 2,540/month',
            'Health insurance',
            'Clean criminal record',
          ],
          validityPeriod: '1 year, renewable',
          pathToResidence: false,
          officialUrl: 'https://mup.gov.hr',
        ),
      ],
      incubators: [
        BusinessIncubator(
          name: 'ZIP (Zagreb Innovation Park)',
          city: 'Zagreb',
          focus: 'Tech startups',
          immigrantFriendly: true,
          website: 'https://www.zipzg.com',
        ),
      ],
      governmentGrants: [
        'HAMAG-BICRO: loans and guarantees for SMEs up to EUR 100,000',
        'EU Structural Funds for competitiveness (OP Competitiveness)',
        'Croatian Bank for Reconstruction loans for startups',
      ],
      businessAuthority: 'HITRO.HR (one-stop-shop) / Commercial Court',
      businessAuthorityUrl: 'https://www.hitro.hr',
      businessAuthorityPhone: '+385 1 490 6444',
    ),

    // -----------------------------------------------------------------------
    // 5. CYPRUS (CY)
    // -----------------------------------------------------------------------
    CountryBusinessGuide(
      country: 'Cyprus',
      countryCode: 'CY',
      immigrantsCanStartBusiness: true,
      immigrantBusinessSummary:
          'Non-EU nationals can register a company in Cyprus. To reside and manage it, '
          'they need a Temporary Residence and Employment Permit as director. Cyprus is '
          'popular for international holding structures due to its tax treaty network.',
      permitRequirements: [
        'Company registration possible without residence permit',
        'Apply for Temporary Residence Permit as company director',
        'Must show company is operational and employs Cypriot/EU workers',
        'Minimum salary as director: EUR 2,000-4,000/month',
        'EU citizens: register freely',
      ],
      companyTypes: [
        CompanyType(
          localName: 'Εταιρεία Περιορισμένης Ευθύνης (Ιδιωτική)',
          englishName: 'Private Limited Company',
          abbreviation: 'Ltd',
          description: 'Most common form, English-law based system',
          minimumCapital: 1,
          capitalFullyPaidUpfront: false,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited to share capital',
          notes: [
            'No minimum capital requirement in practice',
            'Standard authorized capital EUR 1,000-5,000',
            'Based on UK Companies Act model',
          ],
        ),
        CompanyType(
          localName: 'Δημόσια Εταιρεία',
          englishName: 'Public Limited Company',
          abbreviation: 'PLC',
          description: 'For listed companies or large enterprises',
          minimumCapital: 25629,
          capitalFullyPaidUpfront: false,
          minShareholders: 7,
          minDirectors: 2,
          liabilityType: 'Limited to share capital',
        ),
        CompanyType(
          localName: 'Αυτοεργοδοτούμενος',
          englishName: 'Sole Proprietorship',
          abbreviation: '-',
          description: 'Individual business, requires residence',
          minimumCapital: 0,
          capitalFullyPaidUpfront: true,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Unlimited personal liability',
        ),
      ],
      registrationSteps: [
        '1. Name approval from Registrar of Companies',
        '2. Prepare Memorandum & Articles of Association',
        '3. File registration documents with Registrar',
        '4. Obtain Certificate of Incorporation',
        '5. Register with Tax Department for TIC (Tax Identification Code)',
        '6. Register for VAT if applicable',
        '7. Register with Social Insurance Services',
        '8. Open business bank account',
      ],
      registrationTimeline: '3-5 business days (standard); 1 day (express)',
      registrationCost:
          'Ltd: ~EUR 500-1,500 (registration fee EUR 105, name approval EUR 10, '
          'filing ~EUR 60, legal/accounting fees). Express: additional EUR 100.',
      taxInfo: TaxInfo(
        corporateTaxRate: 12.5,
        corporateTaxNotes: 'One of the lowest in EU. IP box regime: effective 2.5% on IP income.',
        vatStandardRate: 19.0,
        vatReducedRate: 5.0,
        vatRegistrationThreshold: 15600,
        incomeTaxRange: '0% (up to EUR 19,500) to 35% (over EUR 60,000)',
        socialContributions:
            'Self-employed: 15.6% of income. Employer: 8.3% + 2% social cohesion',
        taxAuthority: 'Tax Department (Τμήμα Φορολογίας)',
        taxAuthorityUrl: 'https://www.mof.gov.cy/tax',
      ),
      bankAccountRequirements: [
        'Passport, proof of address (utility bill)',
        'Certificate of Incorporation',
        'Memorandum & Articles of Association',
        'Director/shareholder details and due diligence',
        'Reference letter from existing bank',
        'Business plan or description of activities',
      ],
      accountingObligations: [
        'All companies must maintain proper books of account',
        'Annual financial statements prepared under IFRS',
        'Annual return filed with Registrar of Companies',
        'Corporate tax return due 15 months after year end',
        'Quarterly VAT returns',
        'Audit mandatory for all Ltd companies',
      ],
      hiringRulesForForeignEmployers: [
        'Register with Social Insurance Department',
        'Non-EU workers need work permit from Migration Department',
        'Minimum wage: EUR 1,000/month (after 6 months in role)',
        'Employer social insurance contributions ~8.3%',
        '13th salary mandatory in most sectors',
      ],
      startupVisaPrograms: [
        StartupVisaProgram(
          name: 'Cyprus Startup Visa',
          description: 'For innovative startup founders from third countries',
          requirements: [
            'Innovative product/service with growth potential',
            'Endorsed by approved Cypriot incubator/accelerator',
            'Sufficient funds: EUR 20,000-50,000',
            'Health insurance',
            'Clean criminal record',
          ],
          investmentMinimum: 'EUR 20,000',
          validityPeriod: '1 year, renewable up to 2 years',
          pathToResidence: true,
          officialUrl: 'https://www.startupvisa.cy',
        ),
      ],
      incubators: [
        BusinessIncubator(
          name: 'IDEA Innovation Center',
          city: 'Nicosia',
          focus: 'Tech, innovation',
          immigrantFriendly: true,
          website: 'https://ideacy.net',
        ),
      ],
      governmentGrants: [
        'Scheme for Technology and Innovation: grants up to EUR 200,000',
        'Youth Entrepreneurship Scheme: up to EUR 80,000 for ages 20-40',
        'Digital Upgrade of Enterprises: up to EUR 50,000',
      ],
      businessAuthority: 'Department of Registrar of Companies and Intellectual Property',
      businessAuthorityUrl: 'https://www.companies.gov.cy',
      businessAuthorityPhone: '+357 22 404 301',
    ),

    // -----------------------------------------------------------------------
    // 6. CZECH REPUBLIC (CZ)
    // -----------------------------------------------------------------------
    CountryBusinessGuide(
      country: 'Czech Republic',
      countryCode: 'CZ',
      immigrantsCanStartBusiness: true,
      immigrantBusinessSummary:
          'Non-EU nationals can form a company (s.r.o.) without a Czech residence permit. '
          'To manage the business locally, a long-term business visa or residence permit '
          'for business purposes is required.',
      permitRequirements: [
        'Company registration does not require residence permit',
        'Long-term visa for business purpose to reside in CZ',
        'Trade license (Živnostenský list) obtainable by non-residents',
        'Proof of business premises (registered office address)',
        'Criminal record extract (apostilled from home country)',
        'EU citizens: free establishment',
      ],
      companyTypes: [
        CompanyType(
          localName: 'Společnost s ručením omezeným',
          englishName: 'Limited Liability Company',
          abbreviation: 's.r.o.',
          description: 'Most popular company form in Czech Republic',
          minimumCapital: 1,
          capitalFullyPaidUpfront: true,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited to share capital',
          notes: [
            'Minimum CZK 1 (~EUR 0.04) since 2014 Civil Code reform',
            'In practice, CZK 1-200,000 typical',
          ],
        ),
        CompanyType(
          localName: 'Akciová společnost',
          englishName: 'Joint Stock Company',
          abbreviation: 'a.s.',
          description: 'For larger enterprises',
          minimumCapital: 80000,
          capitalFullyPaidUpfront: false,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited to share capital',
          notes: ['CZK 2,000,000 (~EUR 80,000) minimum, 30% paid up'],
        ),
        CompanyType(
          localName: 'OSVČ (Osoba samostatně výdělečně činná)',
          englishName: 'Sole Trader / Self-employed',
          abbreviation: 'OSVČ',
          description: 'Individual trade license holder',
          minimumCapital: 0,
          capitalFullyPaidUpfront: true,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Unlimited personal liability',
          notes: ['Very popular due to flat expense deduction options'],
        ),
      ],
      registrationSteps: [
        '1. Obtain trade license from Trade Licensing Office (Živnostenský úřad)',
        '2. Draft memorandum of association (notarial deed for s.r.o.)',
        '3. Open bank account, deposit share capital',
        '4. Apply for registration at Commercial Register (Obchodní rejstřík)',
        '5. Register with Tax Authority (Finanční úřad)',
        '6. Register for social security and health insurance',
        '7. Register for VAT if required',
        '8. Obtain data box (Datová schránka) — mandatory for all companies',
      ],
      registrationTimeline: '5-10 business days',
      registrationCost:
          's.r.o.: ~EUR 400-800 (notary ~EUR 200, court fee CZK 2,700 (~EUR 108), '
          'trade license CZK 1,000 (~EUR 40)). OSVČ: ~EUR 40-50.',
      taxInfo: TaxInfo(
        corporateTaxRate: 21.0,
        corporateTaxNotes: 'Increased from 19% to 21% in 2024 consolidation package',
        vatStandardRate: 21.0,
        vatReducedRate: 12.0,
        vatRegistrationThreshold: 80000,
        incomeTaxRange: '15% (up to CZK 1,935,552) and 23% (above)',
        socialContributions:
            'Self-employed: ~29.2% min on 50% of profit (social) + ~13.5% (health)',
        taxAuthority: 'Finanční správa (Financial Administration)',
        taxAuthorityUrl: 'https://www.financnisprava.cz',
      ),
      bankAccountRequirements: [
        'Passport, Czech address or registered office proof',
        'Company extract from Commercial Register',
        'Trade license',
        'Some banks require Czech residency; Fio Banka often works for non-residents',
      ],
      accountingObligations: [
        'All s.r.o. must keep double-entry books',
        'OSVČ can use simplified tax records or flat-rate expenses',
        'Annual financial statements filed with Commercial Register',
        'Corporate tax return due April 1 (July 1 with tax advisor)',
        'Monthly/quarterly VAT returns',
        'Electronic filing via data box mandatory',
      ],
      hiringRulesForForeignEmployers: [
        'Register employees with ČSSZ (social admin) and health insurer within 8 days',
        'Non-EU workers: Employee Card (combined work + residence permit)',
        'Minimum wage: CZK 20,800/month (~EUR 833) in 2026',
        'Employer contributions: ~33.8% of gross salary',
        'Written contract in Czech required',
      ],
      startupVisaPrograms: [
        StartupVisaProgram(
          name: 'Czech Startup Visa',
          description: 'For innovative entrepreneurs from non-EU countries',
          requirements: [
            'Innovative business idea with scalability',
            'Endorsement by approved Czech incubator/accelerator',
            'Proof of funds: min EUR 7,200 for 12 months',
            'Health insurance',
          ],
          validityPeriod: '1 year, extendable to 2 years',
          pathToResidence: true,
          officialUrl: 'https://www.czechstartups.org',
        ),
      ],
      incubators: [
        BusinessIncubator(
          name: 'CzechInvest Startup Program',
          city: 'Prague',
          focus: 'Tech, innovation ecosystem',
          immigrantFriendly: true,
          website: 'https://www.czechinvest.org',
        ),
      ],
      governmentGrants: [
        'CzechInvest technology incubation grants',
        'TAČR (Technology Agency): R&D grants',
        'OP TAK: EU Structural Fund for business competitiveness',
        'ČMZRB guarantee programs for SMEs',
      ],
      businessAuthority: 'Trade Licensing Office (Živnostenský úřad) / CzechInvest',
      businessAuthorityUrl: 'https://www.czechinvest.org',
      businessAuthorityPhone: '+420 296 342 500',
    ),

    // -----------------------------------------------------------------------
    // 7. DENMARK (DK)
    // -----------------------------------------------------------------------
    CountryBusinessGuide(
      country: 'Denmark',
      countryCode: 'DK',
      immigrantsCanStartBusiness: true,
      immigrantBusinessSummary:
          'Non-EU nationals need a residence and work permit for self-employment (rarely '
          'granted) or Startup Denmark visa. Company formation is possible online, '
          'but physical presence needed for bank account. Denmark has a dedicated startup '
          'program for innovative entrepreneurs.',
      permitRequirements: [
        'Startup Denmark program for innovative entrepreneurs',
        'Self-employment permit: very restrictive, requires Danish economic interest',
        'Corporate registration possible online via virk.dk',
        'CPR number (civil registration) needed for director if resident',
        'EU citizens: free establishment with registration certificate',
      ],
      companyTypes: [
        CompanyType(
          localName: 'Anpartsselskab',
          englishName: 'Private Limited Company',
          abbreviation: 'ApS',
          description: 'Most popular for SMEs, flexible structure',
          minimumCapital: 40000,
          capitalFullyPaidUpfront: false,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited to share capital',
          notes: [
            'DKK 40,000 (~EUR 5,370) minimum capital',
            'At least 25% (DKK 10,000) paid up at formation',
          ],
        ),
        CompanyType(
          localName: 'Aktieselskab',
          englishName: 'Public Limited Company',
          abbreviation: 'A/S',
          description: 'For larger enterprises',
          minimumCapital: 53600,
          capitalFullyPaidUpfront: false,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited to share capital',
          notes: ['DKK 400,000 (~EUR 53,600) minimum'],
        ),
        CompanyType(
          localName: 'Iværksætterselskab',
          englishName: 'Entrepreneurial Company',
          abbreviation: 'IVS',
          description: 'Discontinued in 2021, existing IVS must convert to ApS',
          minimumCapital: 1,
          capitalFullyPaidUpfront: true,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited',
          notes: ['No longer available for new registrations since April 2021'],
        ),
        CompanyType(
          localName: 'Enkeltmandsvirksomhed',
          englishName: 'Sole Proprietorship',
          abbreviation: '-',
          description: 'Personal business, requires CPR number',
          minimumCapital: 0,
          capitalFullyPaidUpfront: true,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Unlimited personal liability',
          notes: ['Requires Danish CPR number (residence registration)'],
        ),
      ],
      registrationSteps: [
        '1. Register digitally via virk.dk (requires NemID/MitID or foreign eID)',
        '2. Register company with Danish Business Authority (Erhvervsstyrelsen)',
        '3. Receive CVR number (business registration number)',
        '4. Register for tax with Skattestyrelsen',
        '5. Register for VAT via virk.dk',
        '6. Open business bank account (requires physical presence)',
        '7. Register as employer if hiring (via virk.dk)',
      ],
      registrationTimeline: '1-3 hours online (ApS without capital verification)',
      registrationCost:
          'ApS: FREE online registration via virk.dk. '
          'Legal/accounting setup fees: ~EUR 500-1,500 if using advisor.',
      taxInfo: TaxInfo(
        corporateTaxRate: 22.0,
        corporateTaxNotes: 'Flat 22%. R&D tax credit: 22% of R&D losses refunded (max DKK 25M)',
        vatStandardRate: 25.0,
        vatReducedRate: 0,
        vatRegistrationThreshold: 6700,
        incomeTaxRange: '~37% (lowest bracket incl. labor market contribution) to ~52%',
        socialContributions:
            'Low mandatory social contributions; ATP pension ~DKK 3,408/year per employee',
        taxAuthority: 'Skattestyrelsen (Danish Tax Agency)',
        taxAuthorityUrl: 'https://www.skat.dk',
      ),
      bankAccountRequirements: [
        'Physical presence in Denmark usually required',
        'CVR number',
        'Passport and Danish address',
        'Business plan / description of activities',
        'Source of capital documentation',
        'Difficult for non-residents; consider Lunar, Revolut Business',
      ],
      accountingObligations: [
        'All ApS/A/S must file annual report with Danish Business Authority',
        'Bookkeeping must comply with Danish Bookkeeping Act',
        'Digital bookkeeping mandatory from 2025',
        'Audit mandatory if exceeding 2 of 3: DKK 8M revenue, DKK 4M assets, 12 employees',
        'Monthly/quarterly VAT returns via TastSelv (SKAT)',
      ],
      hiringRulesForForeignEmployers: [
        'Register as employer via virk.dk',
        'Non-EU workers need work permit (Positive List or Pay Limit scheme)',
        'No statutory minimum wage; set by collective agreements',
        'Employer pays ATP, labor market insurance contributions',
        'Holiday pay: 12.5% of salary accrued',
      ],
      startupVisaPrograms: [
        StartupVisaProgram(
          name: 'Startup Denmark',
          description: 'Residence permit for innovative startup founders from non-EU countries',
          requirements: [
            'Innovative, scalable business concept',
            'Approved by external expert panel',
            'Sufficient funds for personal support (DKK 142,032/year)',
            'Business plan in English',
            'No requirement for Danish language',
          ],
          validityPeriod: '2 years, renewable up to 3 years',
          pathToResidence: true,
          officialUrl: 'https://startupdenmark.info',
        ),
      ],
      incubators: [
        BusinessIncubator(
          name: 'Copenhagen Fintech',
          city: 'Copenhagen',
          focus: 'Fintech startups',
          immigrantFriendly: true,
          website: 'https://copenhagenfintech.dk',
        ),
        BusinessIncubator(
          name: 'DTU Skylab',
          city: 'Lyngby',
          focus: 'Deep tech, university spinoffs',
          immigrantFriendly: true,
          website: 'https://skylab.dtu.dk',
        ),
      ],
      governmentGrants: [
        'Innovationsfonden: grants for innovative projects (up to DKK 15M)',
        'Vækstfonden: loans and guarantees for growth companies',
        'EKF (Export Credit Agency): support for international expansion',
        'Innobooster: grants up to DKK 1.5M for SME innovation',
      ],
      businessAuthority: 'Danish Business Authority (Erhvervsstyrelsen)',
      businessAuthorityUrl: 'https://erhvervsstyrelsen.dk',
      businessAuthorityPhone: '+45 72 20 00 30',
    ),

    // -----------------------------------------------------------------------
    // 8. ESTONIA (EE)
    // -----------------------------------------------------------------------
    CountryBusinessGuide(
      country: 'Estonia',
      countryCode: 'EE',
      immigrantsCanStartBusiness: true,
      immigrantBusinessSummary:
          'Estonia is the most digital-friendly country in the EU for immigrant entrepreneurs. '
          'E-Residency program allows anyone worldwide to register and manage an Estonian company '
          'online. Physical residence requires a separate permit (Startup Visa available).',
      permitRequirements: [
        'E-Residency: digital ID card for remote company management (no physical residency)',
        'Startup Visa: temporary residence for startup founders',
        'D-visa for business: short-term business activities',
        'TRP for enterprise: temporary residence for significant business activity',
        'EU citizens: register via e-Business Register freely',
      ],
      companyTypes: [
        CompanyType(
          localName: 'Osaühing',
          englishName: 'Private Limited Company',
          abbreviation: 'OÜ',
          description: 'Most popular form, can be formed 100% online',
          minimumCapital: 2500,
          capitalFullyPaidUpfront: false,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited to share capital',
          notes: [
            'EUR 2,500 minimum but can be deferred (not paid upfront)',
            'Can be registered in 15 minutes via e-Business Register',
            'E-Residency holders can register fully online',
          ],
        ),
        CompanyType(
          localName: 'Aktsiaselts',
          englishName: 'Public Limited Company',
          abbreviation: 'AS',
          description: 'For larger enterprises',
          minimumCapital: 25000,
          capitalFullyPaidUpfront: false,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited to share capital',
        ),
        CompanyType(
          localName: 'Füüsilisest isikust ettevõtja',
          englishName: 'Sole Proprietor',
          abbreviation: 'FIE',
          description: 'Individual entrepreneur',
          minimumCapital: 0,
          capitalFullyPaidUpfront: true,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Unlimited personal liability',
          notes: ['Requires Estonian residency'],
        ),
      ],
      registrationSteps: [
        '1. Apply for E-Residency card (optional, for remote management)',
        '2. Register company via e-Business Register (ettevõtjaportaal)',
        '3. Digital signing of articles of association',
        '4. Company registered and gets registry code immediately',
        '5. Apply for VAT number from Tax Board (EMTA) if needed',
        '6. Open business bank account (Estonian bank or fintech)',
        '7. Register at Tax Board for employment taxes if hiring',
      ],
      registrationTimeline: '15 minutes to 1 business day (online)',
      registrationCost:
          'OÜ: EUR 265 (state fee for electronic filing, EUR 145 if via notary). '
          'E-Residency card: EUR 100-130. Registered address service: EUR 30-50/month.',
      taxInfo: TaxInfo(
        corporateTaxRate: 20.0,
        corporateTaxNotes:
            'Unique system: 0% on retained/reinvested profits! 20% only on distributed profits. '
            'Reduced rate 14% on regular dividend distributions.',
        vatStandardRate: 22.0,
        vatReducedRate: 9.0,
        vatRegistrationThreshold: 40000,
        incomeTaxRange: '20% flat rate (basic exemption EUR 7,848/year)',
        socialContributions:
            'Employer: 33% social tax + 0.8% unemployment insurance. '
            'Employee: 1.6% unemployment + 2% mandatory pension',
        taxAuthority: 'Estonian Tax and Customs Board (EMTA)',
        taxAuthorityUrl: 'https://www.emta.ee',
      ),
      bankAccountRequirements: [
        'E-Residency card or Estonian ID/passport',
        'Company registration extract',
        'Business description and plan',
        'Proof of address (can be foreign)',
        'Traditional banks (LHV, SEB) may require visit or video call',
        'Fintech alternatives: Wise Business, Payoneer (easier for e-Residents)',
      ],
      accountingObligations: [
        'All OÜ must keep double-entry books',
        'Annual report filed electronically with Business Register',
        'VAT return monthly (by 20th of following month)',
        'TSD form monthly for employment taxes',
        'Audit required if 2 of 3: EUR 4M revenue, EUR 2M assets, 60 employees',
        'E-Residency companies often use Estonian accounting firms remotely',
      ],
      hiringRulesForForeignEmployers: [
        'Register employees with EMTA via e-filing',
        'Non-EU workers need residence permit for employment',
        'Minimum wage: EUR 820/month (2026)',
        'Employer social tax: 33% on top of gross salary',
        'Employment contracts must be in writing (can be in English)',
        'Remote/foreign employees possible with Estonian company',
      ],
      startupVisaPrograms: [
        StartupVisaProgram(
          name: 'Estonian Startup Visa',
          description: 'Temporary residence permit for startup founders and key employees',
          requirements: [
            'Startup must be registered in Estonian e-Business Register',
            'Innovative, technology-based, scalable business model',
            'Endorsed by Startup Estonia committee',
            'Sufficient funds for stay in Estonia',
          ],
          validityPeriod: 'Up to 18 months (visa), extendable as TRP',
          pathToResidence: true,
          officialUrl: 'https://startupestonia.ee/visa',
        ),
        StartupVisaProgram(
          name: 'E-Residency',
          description:
              'Digital identity for remote business management (not a visa/residence permit)',
          requirements: [
            'Apply online, biometric data at Estonian embassy/service point',
            'Background check',
            'EUR 100-130 application fee',
            'Pickup at embassy or service point',
          ],
          validityPeriod: 'E-Residency card valid 5 years',
          pathToResidence: false,
          officialUrl: 'https://www.e-resident.gov.ee',
        ),
      ],
      incubators: [
        BusinessIncubator(
          name: 'Startup Estonia / Startup Wise Guys',
          city: 'Tallinn',
          focus: 'B2B SaaS, fintech',
          immigrantFriendly: true,
          website: 'https://startupestonia.ee',
        ),
        BusinessIncubator(
          name: 'Tehnopol Startup Incubator',
          city: 'Tallinn',
          focus: 'Tech, health-tech',
          immigrantFriendly: true,
          website: 'https://www.tehnopol.ee',
        ),
      ],
      governmentGrants: [
        'EAS (Enterprise Estonia) startup grant: up to EUR 15,000',
        'EAS development voucher: up to EUR 4,000 for consultancy',
        'KredEx startup loan: up to EUR 100,000',
        'Smart specialization R&D grants via EAS',
        'EU Structural Funds for digitalization and innovation',
      ],
      businessAuthority: 'Centre of Registers and Information Systems (RIK)',
      businessAuthorityUrl: 'https://www.rik.ee',
      businessAuthorityPhone: '+372 663 6300',
    ),

    // -----------------------------------------------------------------------
    // 9. FINLAND (FI)
    // -----------------------------------------------------------------------
    CountryBusinessGuide(
      country: 'Finland',
      countryCode: 'FI',
      immigrantsCanStartBusiness: true,
      immigrantBusinessSummary:
          'Non-EU nationals need a residence permit for self-employed persons (entrepreneur '
          'permit) from Finnish Immigration Service (Migri). EU citizens can start a business '
          'freely. Finland has a Startup Permit for innovative entrepreneurs.',
      permitRequirements: [
        'Entrepreneur residence permit: assessed by ELY Centre for business viability',
        'Startup Permit: for innovative startups (fast-track, Business Finland evaluation)',
        'Must show the business can provide livelihood',
        'Finnish personal ID (henkilötunnus) needed for practical matters',
        'EU/EEA citizens: register with DVV, start business freely',
      ],
      companyTypes: [
        CompanyType(
          localName: 'Osakeyhtiö',
          englishName: 'Private Limited Company',
          abbreviation: 'Oy',
          description: 'Most common company form in Finland',
          minimumCapital: 2500,
          capitalFullyPaidUpfront: true,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited to share capital',
          notes: [
            'EUR 2,500 minimum share capital',
            'At least one board member must reside in EEA (or apply for exemption from PRH)',
            'Can be registered online via YTJ/PRH',
          ],
        ),
        CompanyType(
          localName: 'Julkinen osakeyhtiö',
          englishName: 'Public Limited Company',
          abbreviation: 'Oyj',
          description: 'For publicly traded companies',
          minimumCapital: 80000,
          capitalFullyPaidUpfront: true,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited to share capital',
        ),
        CompanyType(
          localName: 'Toiminimi',
          englishName: 'Sole Trader / Private Trader',
          abbreviation: 'Tmi',
          description: 'Simplest form, personal liability',
          minimumCapital: 0,
          capitalFullyPaidUpfront: true,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Unlimited personal liability',
          notes: ['Requires domicile in EEA or PRH exemption'],
        ),
        CompanyType(
          localName: 'Osuuskunta',
          englishName: 'Cooperative',
          abbreviation: 'Osk',
          description: 'Member-owned cooperative',
          minimumCapital: 0,
          capitalFullyPaidUpfront: true,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited to membership fee',
          notes: ['Popular for freelancer cooperatives'],
        ),
      ],
      registrationSteps: [
        '1. Apply for Finnish personal ID (henkilötunnus) from DVV if needed',
        '2. Draft articles of association and shareholder agreement',
        '3. Pay share capital to company bank account',
        '4. Register via YTJ (Business Information System) / PRH online',
        '5. Receive Business ID (Y-tunnus)',
        '6. Register for VAT, employer register, prepayment register at Tax Admin',
        '7. Open business bank account',
        '8. Arrange mandatory insurance (YEL self-employed pension, TyEL if employees)',
      ],
      registrationTimeline: '1-5 business days (online via PRH)',
      registrationCost:
          'Oy: EUR 240 (online) or EUR 380 (paper) to PRH. '
          'Tmi: EUR 60 (online). Notary not required in Finland.',
      taxInfo: TaxInfo(
        corporateTaxRate: 20.0,
        corporateTaxNotes: 'Flat 20%. Dividends: up to 8% of net assets taxed at 25% of amount at 30%',
        vatStandardRate: 25.5,
        vatReducedRate: 14.0,
        vatRegistrationThreshold: 15000,
        incomeTaxRange: '~6% (municipal) + 12.64%-44% (state) progressive',
        socialContributions:
            'Self-employed (YEL): ~24.1% on confirmed income (under 53) or 25.6% (53+). '
            'Employer contributions: ~18% total for TyEL, unemployment, accident, group life',
        taxAuthority: 'Finnish Tax Administration (Verohallinto)',
        taxAuthorityUrl: 'https://www.vero.fi',
      ),
      bankAccountRequirements: [
        'Finnish personal ID (henkilötunnus)',
        'Business ID (Y-tunnus)',
        'Trade register extract from PRH',
        'Passport or ID card',
        'Banks: OP, Nordea, Danske Bank. Holvi popular for entrepreneurs.',
        'Non-residents may face difficulty; Holvi (fintech) more accessible',
      ],
      accountingObligations: [
        'All companies must maintain double-entry bookkeeping',
        'Annual financial statements filed with PRH (trade register)',
        'Audit mandatory if 2 of 3: EUR 200K revenue, EUR 100K assets, 3 employees',
        'Monthly/quarterly VAT returns via MyTax (OmaVero)',
        'Corporate tax return due 4 months after fiscal year end',
        'Monthly payroll reporting to Incomes Register',
      ],
      hiringRulesForForeignEmployers: [
        'Register as employer with Tax Administration and pension insurer',
        'Non-EU workers need residence permit for employed persons',
        'No statutory minimum wage; wages set by collective agreements',
        'Employer pension contributions (TyEL): ~17.4%',
        'Mandatory accident insurance for all employees',
        'Written employment contract strongly recommended (law allows oral)',
      ],
      startupVisaPrograms: [
        StartupVisaProgram(
          name: 'Finnish Startup Permit',
          description:
              'Fast-track residence permit for innovative startup founders from non-EU countries',
          requirements: [
            'Business Finland positive eligibility statement (innovation, scalability, team)',
            'Sufficient personal funds or startup funding',
            'Health insurance',
            'Apply at Finnish embassy or in Finland (if lawfully present)',
          ],
          validityPeriod: '2 years, renewable',
          pathToResidence: true,
          officialUrl: 'https://www.businessfinland.fi/en/for-finnish-customers/services/startup-permit',
        ),
      ],
      incubators: [
        BusinessIncubator(
          name: 'Maria 01',
          city: 'Helsinki',
          focus: 'Largest startup campus in Nordics',
          immigrantFriendly: true,
          website: 'https://maria.io',
        ),
        BusinessIncubator(
          name: 'Startup Sauna / Aalto Entrepreneurship Society',
          city: 'Espoo',
          focus: 'University-linked startup accelerator',
          immigrantFriendly: true,
          website: 'https://startupsauna.com',
        ),
        BusinessIncubator(
          name: 'NewCo Helsinki',
          city: 'Helsinki',
          focus: 'Free advisory for all entrepreneurs including immigrants',
          immigrantFriendly: true,
          website: 'https://newcohelsinki.fi',
        ),
      ],
      governmentGrants: [
        'Business Finland startup grant: up to EUR 50,000',
        'Business Finland R&D funding: up to EUR 1M+',
        'ELY Centre startup grant (starttiraha): ~EUR 750-1,000/month for 6-12 months',
        'Finnvera loans and guarantees for SMEs',
        'TE-office startup money for unemployed becoming entrepreneurs',
      ],
      businessAuthority:
          'Finnish Patent and Registration Office (PRH) / Business Finland',
      businessAuthorityUrl: 'https://www.prh.fi/en',
      businessAuthorityPhone: '+358 29 509 5000',
      additionalNotes: [
        'Finland has an excellent International House Helsinki for immigrant entrepreneurs',
        'Free business advisors available in English at NewCo Helsinki and Enterprise Agencies',
        'YEL pension insurance mandatory from month one for self-employed earning >EUR 9,010/year',
      ],
    ),

    // -----------------------------------------------------------------------
    // 10. FRANCE (FR)
    // -----------------------------------------------------------------------
    CountryBusinessGuide(
      country: 'France',
      countryCode: 'FR',
      immigrantsCanStartBusiness: true,
      immigrantBusinessSummary:
          'Non-EU nationals need a residence permit authorizing commercial or self-employed '
          'activity. The French Tech Visa (Passeport Talent) offers a 4-year residence '
          'permit for startup founders. EU citizens have full freedom of establishment.',
      permitRequirements: [
        'Passeport Talent - Création d\'entreprise: for startup founders',
        'Passeport Talent - Projet économique innovant: for innovative projects',
        'Commerçant status: for general business activity',
        'Proof of investment, business plan, qualifications',
        'EU citizens: register and start immediately',
      ],
      companyTypes: [
        CompanyType(
          localName: 'Société à responsabilité limitée',
          englishName: 'Limited Liability Company',
          abbreviation: 'SARL',
          description: 'Classic LLC form, flexible for SMEs',
          minimumCapital: 1,
          capitalFullyPaidUpfront: false,
          minShareholders: 2,
          minDirectors: 1,
          liabilityType: 'Limited to share capital',
          notes: [
            'No legal minimum capital (EUR 1 sufficient)',
            'At least 20% paid at formation, rest within 5 years',
          ],
        ),
        CompanyType(
          localName: 'Société par actions simplifiée',
          englishName: 'Simplified Joint Stock Company',
          abbreviation: 'SAS',
          description: 'Most popular form for startups, very flexible',
          minimumCapital: 1,
          capitalFullyPaidUpfront: false,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited to share capital',
          notes: [
            'Preferred form for startups and VC funding',
            'President (Président) can be individual or legal entity',
            'SASU = single-member SAS',
          ],
        ),
        CompanyType(
          localName: 'Entreprise individuelle / Micro-entreprise',
          englishName: 'Sole Proprietorship / Micro-enterprise',
          abbreviation: 'EI/ME',
          description: 'Simplified regime for small businesses and freelancers',
          minimumCapital: 0,
          capitalFullyPaidUpfront: true,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited to business assets (since 2022 reform)',
          notes: [
            'Micro-entreprise: simplified tax if under EUR 77,700 (services) '
                'or EUR 188,700 (commerce)',
            'Registration via INPI Guichet unique since 2023',
          ],
        ),
      ],
      registrationSteps: [
        '1. Draft articles of association (statuts)',
        '2. Deposit share capital at bank (attestation de dépôt des fonds)',
        '3. Publish legal notice (annonce légale) in approved journal (~EUR 150-250)',
        '4. Register online via INPI Guichet unique (guichet-entreprises.fr)',
        '5. Receive SIRET/SIREN number from INSEE',
        '6. Receive K-bis extract from Tribunal de Commerce',
        '7. Register for VAT and corporate tax with SIE',
        '8. Register with URSSAF for social contributions',
      ],
      registrationTimeline: '3-7 business days',
      registrationCost:
          'SAS/SARL: ~EUR 500-1,500 (greffe EUR 37-67, legal notice ~EUR 200, '
          'legal fees if used). Micro-entreprise: FREE (online via INPI).',
      taxInfo: TaxInfo(
        corporateTaxRate: 25.0,
        corporateTaxNotes: 'Reduced rate 15% on first EUR 42,500 for small companies',
        vatStandardRate: 20.0,
        vatReducedRate: 5.5,
        vatRegistrationThreshold: 36800,
        incomeTaxRange: '0% (up to EUR 11,294) to 45% (over EUR 177,106)',
        socialContributions:
            'Self-employed (gérant SARL): ~45% of net income. '
            'Micro-entreprise: 12.3%-22% of turnover. '
            'SAS President: salaried regime ~60-80% of net on charges',
        taxAuthority: 'Direction Générale des Finances Publiques (DGFiP)',
        taxAuthorityUrl: 'https://www.impots.gouv.fr',
      ),
      bankAccountRequirements: [
        'K-bis extract (company registration)',
        'Statuts (articles of association)',
        'ID of directors/shareholders',
        'Proof of address',
        'Opening deposit',
        'Online banks: Qonto, Shine, Blank popular for startups',
      ],
      accountingObligations: [
        'All companies (SAS/SARL) must keep full double-entry books',
        'Annual accounts filed with Tribunal de Commerce (greffe)',
        'Micro-entreprise: simplified bookkeeping (income/expense log)',
        'Monthly/quarterly/annual VAT returns depending on regime',
        'Corporate tax return due 4 months after fiscal year end',
        'Statutory auditor (commissaire aux comptes) if 2 of 3: EUR 8M revenue, EUR 4M assets, 50 employees',
      ],
      hiringRulesForForeignEmployers: [
        'Register with URSSAF as employer',
        'Non-EU workers need work authorization (autorisation de travail)',
        'SMIC minimum wage: EUR 11.88/hour (2026) = ~EUR 1,802/month gross',
        'Employer social charges: ~42-45% of gross salary',
        'Written employment contract required (in French)',
        'Mandatory profit-sharing (participation) if 50+ employees',
      ],
      startupVisaPrograms: [
        StartupVisaProgram(
          name: 'French Tech Visa (Passeport Talent)',
          description:
              '4-year residence permit for startup founders, investors, and tech employees',
          requirements: [
            'Innovative project recognized by a designated public body or incubator',
            'At least EUR 30,000 investment or diploma/experience',
            'Business plan demonstrating innovation and viability',
            'Health insurance',
          ],
          investmentMinimum: 'EUR 30,000',
          validityPeriod: '4 years, renewable',
          pathToResidence: true,
          officialUrl: 'https://lafrenchtech.com/en/how-france-helps-startups/french-tech-visa',
        ),
      ],
      incubators: [
        BusinessIncubator(
          name: 'Station F',
          city: 'Paris',
          focus: 'World\'s largest startup campus',
          immigrantFriendly: true,
          website: 'https://stationf.co',
        ),
        BusinessIncubator(
          name: 'Bpifrance Le Hub',
          city: 'Paris',
          focus: 'Corporate-startup matching',
          immigrantFriendly: true,
          website: 'https://lehub.bpifrance.fr',
        ),
      ],
      governmentGrants: [
        'Bpifrance: startup loans (prêt d\'honneur) up to EUR 90,000 interest-free',
        'BPI Aide à la Création: grants up to EUR 10,000',
        'Crédit d\'Impôt Recherche (CIR): 30% R&D tax credit',
        'Jeune Entreprise Innovante (JEI): social charge exemptions for innovative startups',
        'French Tech Tremplin: program for underrepresented entrepreneurs',
      ],
      businessAuthority: 'INPI Guichet unique (one-stop shop)',
      businessAuthorityUrl: 'https://www.inpi.fr',
      businessAuthorityPhone: '+33 1 56 65 89 98',
    ),

    // -----------------------------------------------------------------------
    // 11. GERMANY (DE)
    // -----------------------------------------------------------------------
    CountryBusinessGuide(
      country: 'Germany',
      countryCode: 'DE',
      immigrantsCanStartBusiness: true,
      immigrantBusinessSummary:
          'Non-EU nationals can apply for a self-employment residence permit (§21 AufenthG) '
          'or a freelance visa (§21(5) Freiberufler). Business must serve German economic '
          'interest. Since 2024, the new Chancenkarte (Opportunity Card) adds flexibility.',
      permitRequirements: [
        'Self-employment residence permit (§21 AufenthG): business plan, financing proof',
        'Freelancer visa (§21(5)): for liberal professions (IT, consulting, arts)',
        'Proof of experience, qualifications, and market demand',
        'Local Ausländerbehörde (immigration office) decides, consults IHK/HWK',
        'EU citizens: free establishment, register Gewerbe immediately',
      ],
      companyTypes: [
        CompanyType(
          localName: 'Gesellschaft mit beschränkter Haftung',
          englishName: 'Limited Liability Company',
          abbreviation: 'GmbH',
          description: 'Standard LLC, most trusted company form',
          minimumCapital: 25000,
          capitalFullyPaidUpfront: false,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited to share capital',
          notes: [
            'EUR 25,000 minimum, at least EUR 12,500 paid up at formation',
            'Notarial deed required (Gesellschaftsvertrag)',
          ],
        ),
        CompanyType(
          localName: 'Unternehmergesellschaft (haftungsbeschränkt)',
          englishName: 'Entrepreneurial Company (limited liability)',
          abbreviation: 'UG (haftungsbeschränkt)',
          description: 'Mini-GmbH for startups, from EUR 1 capital',
          minimumCapital: 1,
          capitalFullyPaidUpfront: true,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited to share capital',
          notes: [
            'Must retain 25% of annual profit until EUR 25,000 reached',
            'Then can convert to GmbH',
            'Popular startup form',
          ],
        ),
        CompanyType(
          localName: 'Einzelunternehmen',
          englishName: 'Sole Proprietorship',
          abbreviation: '-',
          description: 'Simplest form, register as Gewerbe or Freiberufler',
          minimumCapital: 0,
          capitalFullyPaidUpfront: true,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Unlimited personal liability',
          notes: [
            'Gewerbe registration at local Gewerbeamt',
            'Freiberufler: no Gewerbe needed, register with Finanzamt only',
          ],
        ),
        CompanyType(
          localName: 'Aktiengesellschaft',
          englishName: 'Joint Stock Company',
          abbreviation: 'AG',
          description: 'For large enterprises, publicly listed',
          minimumCapital: 50000,
          capitalFullyPaidUpfront: false,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited to share capital',
        ),
      ],
      registrationSteps: [
        '1. Draft articles of association (notarial deed for GmbH/UG)',
        '2. Open business bank account, deposit capital',
        '3. Register with Handelsregister (Commercial Register) via local court',
        '4. Register trade with Gewerbeamt (unless Freiberufler)',
        '5. Register with Finanzamt (Tax Office) — receive Steuernummer',
        '6. IHK/HWK membership automatic upon Gewerbe registration',
        '7. Register with Berufsgenossenschaft (accident insurance) if employees',
        '8. Register employees with Krankenkasse (health insurance)',
      ],
      registrationTimeline:
          'GmbH/UG: 2-6 weeks (notary + court). Gewerbe: 1-2 days.',
      registrationCost:
          'GmbH: ~EUR 800-2,000 (notary ~EUR 500-1,000, Handelsregister ~EUR 150, '
          'publication ~EUR 50). UG: ~EUR 400-800. Gewerbe: EUR 20-60.',
      taxInfo: TaxInfo(
        corporateTaxRate: 15.0,
        corporateTaxNotes:
            '15% Körperschaftsteuer + 5.5% solidarity surcharge + Gewerbesteuer '
            '(trade tax, varies ~14-17%). Effective total: ~30-33%.',
        vatStandardRate: 19.0,
        vatReducedRate: 7.0,
        vatRegistrationThreshold: 22000,
        incomeTaxRange: '14% (from EUR 11,784) to 45% (over EUR 277,826)',
        socialContributions:
            'Employees: ~20% employer + ~20% employee. '
            'Self-employed: voluntary or mandatory depending on profession',
        taxAuthority: 'Bundeszentralamt für Steuern (BZSt)',
        taxAuthorityUrl: 'https://www.bzst.de',
      ),
      bankAccountRequirements: [
        'Notarized articles of association',
        'Handelsregister extract (or filing receipt)',
        'Passport/ID of directors',
        'German address',
        'Some banks: in-person appointment required',
        'N26, Qonto, Penta, Fyrst popular for startups',
      ],
      accountingObligations: [
        'GmbH/UG: double-entry bookkeeping mandatory',
        'Annual financial statements (Jahresabschluss) filed with Handelsregister',
        'Corporate tax return + trade tax return annually',
        'Monthly/quarterly advance VAT returns (Umsatzsteuervoranmeldung)',
        'Freiberufler: simple income-surplus calculation (EÜR)',
        'Audit mandatory if 2 of 3: EUR 7.3M revenue, EUR 3.65M assets, 50 employees',
      ],
      hiringRulesForForeignEmployers: [
        'Register with social insurance carriers (Krankenkasse, pension, unemployment)',
        'Non-EU workers need work permit or Blue Card',
        'Minimum wage: EUR 12.82/hour (2026)',
        'Employer social contributions: ~21% of gross salary',
        'Written terms of employment (Nachweisgesetz) mandatory within 1 month',
      ],
      startupVisaPrograms: [
        StartupVisaProgram(
          name: 'Self-Employment Visa (§21 AufenthG)',
          description: 'Residence permit for entrepreneurs with viable business plans',
          requirements: [
            'Viable business plan reviewed by IHK/trade association',
            'Economic interest or regional need for the business',
            'Sufficient financing (own capital or bank commitment)',
            'Experience and qualifications in the field',
            'Over 45: adequate pension provision (>EUR 46,860/year income)',
          ],
          validityPeriod: '3 years, renewable; permanent residence after 3 years if successful',
          pathToResidence: true,
        ),
      ],
      incubators: [
        BusinessIncubator(
          name: 'Factory Berlin',
          city: 'Berlin',
          focus: 'Tech community and coworking',
          immigrantFriendly: true,
          website: 'https://factoryberlin.com',
        ),
        BusinessIncubator(
          name: 'German Accelerator',
          city: 'Multiple cities',
          focus: 'International market entry',
          immigrantFriendly: true,
          website: 'https://www.germanaccelerator.com',
        ),
      ],
      governmentGrants: [
        'EXIST Gründerstipendium: EUR 1,000-3,000/month for university spinoffs',
        'KfW Gründerkredit: loans up to EUR 125,000',
        'Gründungszuschuss: for unemployed starting a business (EUR 300/month + ALG I)',
        'INVEST grant: 20% subsidy for angel investors in startups',
        'ZIM (Central Innovation Programme): R&D grants up to EUR 380,000',
      ],
      businessAuthority: 'IHK (Industrie- und Handelskammer) / local Gewerbeamt',
      businessAuthorityUrl: 'https://www.ihk.de',
      businessAuthorityPhone: '+49 30 20308 0',
    ),

    // -----------------------------------------------------------------------
    // 12. GREECE (GR)
    // -----------------------------------------------------------------------
    CountryBusinessGuide(
      country: 'Greece',
      countryCode: 'GR',
      immigrantsCanStartBusiness: true,
      immigrantBusinessSummary:
          'Non-EU nationals can establish a company (IKE is popular and easy). A residence '
          'permit for independent economic activity or investment is required to manage '
          'the business from Greece. Golden Visa available for property investors.',
      permitRequirements: [
        'Residence permit for independent economic activity',
        'Investment residence permit (>EUR 250,000 real estate = Golden Visa)',
        'Company registration possible via one-stop-shop (e-YMS)',
        'Tax registration number (AFM) obtainable by non-residents',
        'EU citizens: register freely',
      ],
      companyTypes: [
        CompanyType(
          localName: 'Ιδιωτική Κεφαλαιουχική Εταιρεία',
          englishName: 'Private Company',
          abbreviation: 'IKE',
          description: 'Most popular modern form, very flexible since 2012',
          minimumCapital: 0,
          capitalFullyPaidUpfront: true,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited to contributions',
          notes: [
            'No minimum capital (EUR 0 is allowed)',
            'Can be formed in 1 day via e-YMS',
            'Recommended form for immigrant entrepreneurs',
          ],
        ),
        CompanyType(
          localName: 'Εταιρεία Περιορισμένης Ευθύνης',
          englishName: 'Limited Liability Company',
          abbreviation: 'EPE',
          description: 'Traditional LLC, less popular since IKE introduction',
          minimumCapital: 4500,
          capitalFullyPaidUpfront: true,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited to share capital',
        ),
        CompanyType(
          localName: 'Ανώνυμη Εταιρεία',
          englishName: 'Société Anonyme / Public Ltd',
          abbreviation: 'AE/SA',
          description: 'For larger enterprises',
          minimumCapital: 25000,
          capitalFullyPaidUpfront: false,
          minShareholders: 1,
          minDirectors: 3,
          liabilityType: 'Limited to share capital',
        ),
        CompanyType(
          localName: 'Ατομική Επιχείρηση',
          englishName: 'Sole Proprietorship',
          abbreviation: '-',
          description: 'Individual business, requires AFM tax number',
          minimumCapital: 0,
          capitalFullyPaidUpfront: true,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Unlimited personal liability',
        ),
      ],
      registrationSteps: [
        '1. Obtain AFM (tax ID) from local tax office (DOY)',
        '2. Register online via GEMI (General Electronic Commercial Registry) / e-YMS',
        '3. Draft articles of association (private document for IKE)',
        '4. One-stop-shop issues company registration, AFM, and social insurance in one step',
        '5. Register for VAT if required',
        '6. Open business bank account',
        '7. Register with EFKA (social insurance) as self-employed',
      ],
      registrationTimeline: '1 day via e-YMS for IKE; 3-5 days for AE',
      registrationCost:
          'IKE: ~EUR 100-200 (GEMI fee EUR 10, publication ~EUR 70, misc). '
          'AE: ~EUR 500-1,000. Sole proprietor: ~EUR 50.',
      taxInfo: TaxInfo(
        corporateTaxRate: 22.0,
        corporateTaxNotes: 'Flat 22%. Dividends taxed additionally at 5%.',
        vatStandardRate: 24.0,
        vatReducedRate: 13.0,
        vatRegistrationThreshold: 10000,
        incomeTaxRange: '9% (up to EUR 10,000) to 44% (over EUR 40,000)',
        socialContributions:
            'Self-employed: ~27% of declared income (EFKA contributions)',
        taxAuthority: 'Independent Authority for Public Revenue (AADE)',
        taxAuthorityUrl: 'https://www.aade.gr',
      ),
      bankAccountRequirements: [
        'AFM (Greek tax number)',
        'Passport/ID and proof of address',
        'GEMI registration certificate',
        'Articles of association',
        'Banks: Alpha Bank, Eurobank, Piraeus, National Bank of Greece',
      ],
      accountingObligations: [
        'All companies must use Greek Accounting Standards or IFRS',
        'Electronic books (myDATA) mandatory — real-time digital reporting to AADE',
        'Annual financial statements published via GEMI',
        'Monthly/quarterly VAT returns',
        'Corporate tax return by June of following year',
      ],
      hiringRulesForForeignEmployers: [
        'Register with ERGANI system for all employee movements',
        'Non-EU workers need work permit',
        'Minimum wage: EUR 830/month gross (2026)',
        'Employer social contributions: ~22% of gross salary',
        'Mandatory 13th and 14th month salary (Christmas/Easter/holiday bonuses)',
      ],
      startupVisaPrograms: [
        StartupVisaProgram(
          name: 'Greece Golden Visa',
          description: 'Residence permit through real estate investment',
          requirements: [
            'Real estate investment minimum EUR 250,000 (EUR 500,000 in Athens/Thessaloniki)',
            'Health insurance',
            'No criminal record',
          ],
          investmentMinimum: 'EUR 250,000-500,000',
          validityPeriod: '5 years, renewable',
          pathToResidence: true,
        ),
      ],
      incubators: [
        BusinessIncubator(
          name: 'EGG - Enter Grow Go (by Eurobank)',
          city: 'Athens',
          focus: 'General business incubation',
          immigrantFriendly: true,
          website: 'https://www.theegg.gr',
        ),
        BusinessIncubator(
          name: 'Found.ation',
          city: 'Athens',
          focus: 'Tech startups',
          immigrantFriendly: true,
          website: 'https://thefoundation.gr',
        ),
      ],
      governmentGrants: [
        'ESPA (EU co-funded): grants for new businesses up to EUR 50,000',
        'Elevate Greece: official startup ecosystem platform',
        'EquiFund: venture capital co-investment fund',
        'OAED self-employment program: grants for unemployed entrepreneurs',
      ],
      businessAuthority: 'General Electronic Commercial Registry (GEMI)',
      businessAuthorityUrl: 'https://www.businessportal.gr',
      businessAuthorityPhone: '+30 210 338 2600',
    ),

    // -----------------------------------------------------------------------
    // 13. HUNGARY (HU)
    // -----------------------------------------------------------------------
    CountryBusinessGuide(
      country: 'Hungary',
      countryCode: 'HU',
      immigrantsCanStartBusiness: true,
      immigrantBusinessSummary:
          'Non-EU nationals can form a company (Kft.) and apply for a residence permit '
          'for business purposes. Company registration is fast and affordable. '
          'Hungary has one of the lowest corporate tax rates in the EU.',
      permitRequirements: [
        'Residence permit for business/self-employment purpose',
        'Proof of registered company and business activity',
        'Proof of accommodation and health insurance',
        'Financial means to support yourself',
        'EU citizens: register with immigration within 93 days',
      ],
      companyTypes: [
        CompanyType(
          localName: 'Korlátolt felelősségű társaság',
          englishName: 'Limited Liability Company',
          abbreviation: 'Kft.',
          description: 'Most common company form',
          minimumCapital: 3000000,
          capitalFullyPaidUpfront: false,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited to share capital',
          notes: [
            'HUF 3,000,000 (~EUR 7,500) minimum capital',
            'Can be contributed in cash or in-kind',
            'Simplified Kft. formation possible with template articles',
          ],
        ),
        CompanyType(
          localName: 'Részvénytársaság',
          englishName: 'Joint Stock Company',
          abbreviation: 'Zrt./Nyrt.',
          description: 'Private (Zrt.) or Public (Nyrt.) stock company',
          minimumCapital: 5000000,
          capitalFullyPaidUpfront: false,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited to share capital',
          notes: ['Zrt: HUF 5M (~EUR 12,500). Nyrt: HUF 20M (~EUR 50,000)'],
        ),
        CompanyType(
          localName: 'Egyéni vállalkozó',
          englishName: 'Sole Proprietor',
          abbreviation: 'EV',
          description: 'Individual entrepreneur',
          minimumCapital: 0,
          capitalFullyPaidUpfront: true,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Unlimited personal liability',
          notes: ['Requires Hungarian residence; online registration via e-govt'],
        ),
      ],
      registrationSteps: [
        '1. Draft articles of association (lawyer mandatory for Kft.)',
        '2. Open bank account, deposit capital',
        '3. Lawyer submits registration to Court of Registration electronically',
        '4. Receive company registration number (cégjegyzékszám)',
        '5. Register with tax authority (NAV) for tax number',
        '6. Register for VAT',
        '7. Register as employer if hiring',
      ],
      registrationTimeline:
          '1-3 business days (simplified); 15 business days (standard)',
      registrationCost:
          'Kft. simplified: ~EUR 250-500 (court fee HUF 50,000 + lawyer ~HUF 50,000-100,000). '
          'Standard Kft.: ~EUR 500-1,000.',
      taxInfo: TaxInfo(
        corporateTaxRate: 9.0,
        corporateTaxNotes: 'Flat 9% — LOWEST corporate tax in the EU! Plus local business tax ~2%.',
        vatStandardRate: 27.0,
        vatReducedRate: 5.0,
        vatRegistrationThreshold: 32000,
        incomeTaxRange: '15% flat rate on personal income',
        socialContributions:
            'Self-employed: 13% social contribution tax on income base. '
            'Employer: 13% social contribution on gross salary',
        taxAuthority: 'National Tax and Customs Administration (NAV)',
        taxAuthorityUrl: 'https://nav.gov.hu',
      ),
      bankAccountRequirements: [
        'Company registration documents',
        'Passport, Hungarian tax number',
        'Power of attorney if not personally present',
        'Major banks: OTP, K&H, Erste, Raiffeisen',
        'Non-residents may need Hungarian address',
      ],
      accountingObligations: [
        'All Kft. must keep double-entry books',
        'Annual report filed with Court of Registration',
        'Corporate tax return by May 31',
        'Monthly/quarterly VAT returns',
        'KATA simplified tax option for small entrepreneurs (conditions apply)',
        'Electronic invoicing via NAV Online Számla system mandatory',
      ],
      hiringRulesForForeignEmployers: [
        'Register with NAV as employer before first hire',
        'Non-EU workers need combined work-residence permit',
        'Minimum wage: HUF 266,800/month (~EUR 667) for unskilled',
        'Guaranteed wage minimum: HUF 326,000/month (~EUR 815) for skilled',
        'Employer social contribution: 13% of gross salary',
        'Written employment contract in Hungarian',
      ],
      startupVisaPrograms: [
        StartupVisaProgram(
          name: 'White Card (Business Immigration Program)',
          description: 'Residence permit for entrepreneurs and investors',
          requirements: [
            'Registered Hungarian company',
            'Proof of business activity and sufficient funds',
            'Accommodation in Hungary',
            'Health insurance',
          ],
          validityPeriod: '2 years, renewable',
          pathToResidence: true,
        ),
      ],
      incubators: [
        BusinessIncubator(
          name: 'Design Terminal',
          city: 'Budapest',
          focus: 'Innovation, creative economy',
          immigrantFriendly: true,
          website: 'https://www.designterminal.org',
        ),
      ],
      governmentGrants: [
        'Széchenyi Program Plus (EU funds): various SME grants',
        'GINOP grants for business development',
        'MFB Points: preferential loans via Hungarian Development Bank',
        'Hungarian Startup University Program',
      ],
      businessAuthority: 'Court of Registration / Hungarian Investment Promotion Agency (HIPA)',
      businessAuthorityUrl: 'https://hipa.hu',
      businessAuthorityPhone: '+36 1 872 6520',
    ),

    // -----------------------------------------------------------------------
    // 14. IRELAND (IE)
    // -----------------------------------------------------------------------
    CountryBusinessGuide(
      country: 'Ireland',
      countryCode: 'IE',
      immigrantsCanStartBusiness: true,
      immigrantBusinessSummary:
          'Non-EU nationals can apply for the Start-Up Entrepreneur Programme (STEP) with '
          'EUR 50,000 funding and an innovative business plan. Ireland has an '
          'English-speaking, business-friendly environment with a strong tech ecosystem.',
      permitRequirements: [
        'STEP: EUR 50,000 funding + innovative, high-potential business idea',
        'Immigrant Investor Programme (IIP): EUR 1M investment',
        'Stamp 4 permission via STEP allows full business operation',
        'Company can be registered by non-residents via CRO',
        'EU citizens: free establishment',
      ],
      companyTypes: [
        CompanyType(
          localName: 'Private Company Limited by Shares',
          englishName: 'Private Company Limited by Shares',
          abbreviation: 'LTD',
          description: 'Standard Irish limited company, most popular',
          minimumCapital: 1,
          capitalFullyPaidUpfront: false,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited to share capital',
          notes: [
            'No minimum capital in practice (EUR 1 typical)',
            'At least 1 director must be EEA-resident (or buy Section 137 bond ~EUR 2,000/year)',
            'Company secretary required (can be the same person as director since 2014)',
          ],
        ),
        CompanyType(
          localName: 'Designated Activity Company',
          englishName: 'Designated Activity Company',
          abbreviation: 'DAC',
          description: 'Limited to specified activities in constitution',
          minimumCapital: 1,
          capitalFullyPaidUpfront: false,
          minShareholders: 1,
          minDirectors: 2,
          liabilityType: 'Limited to share capital',
        ),
        CompanyType(
          localName: 'Sole Trader',
          englishName: 'Sole Trader',
          abbreviation: '-',
          description: 'Individual business, simplest form',
          minimumCapital: 0,
          capitalFullyPaidUpfront: true,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Unlimited personal liability',
          notes: ['Register business name with CRO if not using personal name'],
        ),
      ],
      registrationSteps: [
        '1. Choose company name (check availability on CRO website)',
        '2. Prepare constitution (replaces memorandum & articles since 2014)',
        '3. File Form A1 with Companies Registration Office (CRO)',
        '4. Receive Certificate of Incorporation and CRO number',
        '5. Register for tax with Revenue Commissioners (Form TR1/TR2)',
        '6. Register for VAT, PAYE/PRSI if applicable',
        '7. Open business bank account',
      ],
      registrationTimeline: '3-5 business days (online); 10-15 days (paper)',
      registrationCost:
          'LTD: EUR 50 (online filing Form A1). '
          'Section 137 bond if no EEA director: ~EUR 2,000/year. '
          'Legal fees: EUR 500-1,500 if using solicitor.',
      taxInfo: TaxInfo(
        corporateTaxRate: 12.5,
        corporateTaxNotes:
            '12.5% on trading income — one of Europe\'s lowest. '
            '25% on passive/non-trading income. '
            '15% minimum for large multinationals (Pillar Two from 2024).',
        vatStandardRate: 23.0,
        vatReducedRate: 13.5,
        vatRegistrationThreshold: 37500,
        incomeTaxRange: '20% (up to EUR 42,000) and 40% (above)',
        socialContributions:
            'Self-employed PRSI: 4% (Class S). Employer PRSI: 11.05% of gross salary',
        taxAuthority: 'Revenue Commissioners (Revenue)',
        taxAuthorityUrl: 'https://www.revenue.ie',
      ),
      bankAccountRequirements: [
        'Certificate of Incorporation',
        'Company constitution',
        'Proof of address for directors',
        'PPS number (Personal Public Service number) for Irish residents',
        'Banks: AIB, Bank of Ireland, Ulster Bank, Permanent TSB',
        'Fintechs: Revolut Business, N26 for faster opening',
      ],
      accountingObligations: [
        'All LTD companies must file annual return (Form B1) with CRO',
        'Financial statements attached to annual return',
        'Audit exemption if 2 of 3: EUR 12M turnover, EUR 6M assets, 50 employees',
        'Bi-monthly VAT returns (VAT3)',
        'Corporation Tax return (CT1) within 9 months of accounting period end',
        'iXBRL format required for financial statements filed with Revenue',
      ],
      hiringRulesForForeignEmployers: [
        'Register as employer with Revenue for PAYE/PRSI',
        'Non-EU workers need employment permit from DETE',
        'Minimum wage: EUR 12.70/hour (2026)',
        'Employer PRSI: 11.05% of gross salary',
        'Written terms of employment within 5 days (Employment (Miscellaneous Provisions) Act)',
      ],
      startupVisaPrograms: [
        StartupVisaProgram(
          name: 'Start-Up Entrepreneur Programme (STEP)',
          description: 'Residence permission for innovative startup founders',
          requirements: [
            'Innovative business idea in technology, services, or manufacturing',
            'Minimum EUR 50,000 in funding',
            'Business plan endorsed by Enterprise Ireland evaluation committee',
            'No criminal record',
            'Not eligible for businesses in retail, catering, personal services',
          ],
          investmentMinimum: 'EUR 50,000',
          validityPeriod: '2 years (Stamp 4), renewable for 3 more years',
          pathToResidence: true,
          officialUrl: 'https://www.irishimmigration.ie/coming-to-work-in-ireland/what-are-my-work-visa-options/coming-to-work-for-yourself/the-start-up-entrepreneur-programme-step/',
        ),
      ],
      incubators: [
        BusinessIncubator(
          name: 'Enterprise Ireland HPSU',
          city: 'Dublin',
          focus: 'High-Potential Start-Ups, government backed',
          immigrantFriendly: true,
          website: 'https://www.enterprise-ireland.com',
        ),
        BusinessIncubator(
          name: 'NDRC (National Digital Research Centre)',
          city: 'Dublin',
          focus: 'Digital ventures accelerator',
          immigrantFriendly: true,
          website: 'https://www.ndrc.ie',
        ),
      ],
      governmentGrants: [
        'Enterprise Ireland feasibility grant: up to EUR 25,000',
        'Enterprise Ireland HPSU equity investment: up to EUR 250,000',
        'Local Enterprise Office (LEO) grants: up to EUR 50,000',
        'R&D Tax Credit (Section 766): 30% tax credit on qualifying R&D expenditure',
        'Knowledge Development Box: 6.25% effective rate on IP income',
      ],
      businessAuthority: 'Companies Registration Office (CRO)',
      businessAuthorityUrl: 'https://www.cro.ie',
      businessAuthorityPhone: '+353 1 804 5200',
    ),

    // -----------------------------------------------------------------------
    // 15. ITALY (IT)
    // -----------------------------------------------------------------------
    CountryBusinessGuide(
      country: 'Italy',
      countryCode: 'IT',
      immigrantsCanStartBusiness: true,
      immigrantBusinessSummary:
          'Non-EU nationals need a self-employment visa (Visto per lavoro autonomo) and '
          'a permesso di soggiorno for self-employment. Italy has a dedicated Italia '
          'Startup Visa program for innovative startup founders.',
      permitRequirements: [
        'Self-employment visa (lavoro autonomo) from Italian consulate',
        'Permesso di soggiorno per lavoro autonomo',
        'Codice fiscale (Italian tax code) obtainable at consulate',
        'Proof of income/resources, accommodation, health insurance',
        'Italia Startup Visa: fast track for innovative startups',
        'EU citizens: register and start freely',
      ],
      companyTypes: [
        CompanyType(
          localName: 'Società a responsabilità limitata',
          englishName: 'Limited Liability Company',
          abbreviation: 'S.r.l.',
          description: 'Standard LLC, most common for SMEs',
          minimumCapital: 10000,
          capitalFullyPaidUpfront: false,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited to share capital',
          notes: ['At least 25% paid up at formation'],
        ),
        CompanyType(
          localName: 'Società a responsabilità limitata semplificata',
          englishName: 'Simplified Limited Liability Company',
          abbreviation: 'S.r.l.s.',
          description: 'Simplified form with EUR 1 minimum capital',
          minimumCapital: 1,
          capitalFullyPaidUpfront: true,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited to share capital',
          notes: [
            'Capital EUR 1-9,999',
            'Standardized articles — no notary fees for formation',
            'Popular for young entrepreneurs',
          ],
        ),
        CompanyType(
          localName: 'Società per azioni',
          englishName: 'Joint Stock Company',
          abbreviation: 'S.p.A.',
          description: 'For large enterprises',
          minimumCapital: 50000,
          capitalFullyPaidUpfront: false,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited to share capital',
        ),
        CompanyType(
          localName: 'Ditta individuale',
          englishName: 'Sole Proprietorship',
          abbreviation: '-',
          description: 'Individual business, personal liability',
          minimumCapital: 0,
          capitalFullyPaidUpfront: true,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Unlimited personal liability',
          notes: ['Regime forfettario: flat 15% (5% first 5 years) if turnover <EUR 85,000'],
        ),
      ],
      registrationSteps: [
        '1. Obtain codice fiscale from Agenzia delle Entrate',
        '2. Draft articles of association (atto costitutivo) — notarized for S.r.l.',
        '3. Deposit capital in bank account',
        '4. Notary registers with Camera di Commercio (Chamber of Commerce)',
        '5. Register with Registro delle Imprese (Business Register)',
        '6. Obtain partita IVA (VAT number) from Agenzia delle Entrate',
        '7. Register with INPS (social security) and INAIL (accident insurance)',
        '8. SCIA notification to municipality if physical premises needed',
      ],
      registrationTimeline: '5-10 business days for S.r.l.; 1-2 days for S.r.l.s.',
      registrationCost:
          'S.r.l.: ~EUR 2,000-4,000 (notary EUR 1,500-2,500, chamber fee ~EUR 200, '
          'govt stamp EUR 310). S.r.l.s.: ~EUR 300-500 (no notary costs). '
          'Ditta individuale: ~EUR 100-200.',
      taxInfo: TaxInfo(
        corporateTaxRate: 24.0,
        corporateTaxNotes: '24% IRES + 3.9% IRAP (regional tax) = ~27.9% effective',
        vatStandardRate: 22.0,
        vatReducedRate: 10.0,
        vatRegistrationThreshold: 0,
        incomeTaxRange: '23% (up to EUR 28,000) to 43% (over EUR 50,000)',
        socialContributions:
            'Self-employed (gestione separata INPS): ~26.07%. '
            'Artisans/traders INPS: ~24% on income',
        taxAuthority: 'Agenzia delle Entrate',
        taxAuthorityUrl: 'https://www.agenziaentrate.gov.it',
      ),
      bankAccountRequirements: [
        'Codice fiscale',
        'Company registration from Camera di Commercio (Visura camerale)',
        'Passport/ID of directors',
        'Proof of address in Italy',
        'Banks: Intesa Sanpaolo, UniCredit, Banca Mediolanum',
        'Fintechs: Tot, Qonto Italia',
      ],
      accountingObligations: [
        'All S.r.l. must maintain statutory books and double-entry bookkeeping',
        'Annual financial statements filed with Camera di Commercio',
        'Fatturazione elettronica (electronic invoicing) mandatory for all businesses',
        'Quarterly/monthly VAT returns (comunicazioni liquidazioni periodiche)',
        'Annual tax return (Modello Redditi SC) by November 30',
        'Statutory audit required if 2 of 3: EUR 4M revenue, EUR 4M assets, 20 employees',
      ],
      hiringRulesForForeignEmployers: [
        'Register with INPS and INAIL as employer',
        'Non-EU workers need nulla osta (work authorization) from immigration office',
        'National collective bargaining agreements (CCNL) set minimum pay per sector',
        'Employer social contributions: ~30-32% of gross salary',
        'Written employment contract required',
        '13th and 14th month salary (tredicesima/quattordicesima) mandatory',
      ],
      startupVisaPrograms: [
        StartupVisaProgram(
          name: 'Italia Startup Visa',
          description: 'Fast-track visa for innovative startup founders from non-EU countries',
          requirements: [
            'Innovative startup as defined by Italian law (start-up innovativa)',
            'Must be registered in special section of Business Register',
            'Sufficient financial resources (min EUR 50,000 if company, less if individual)',
            'Evaluation by Italia Startup Hub committee',
          ],
          investmentMinimum: 'EUR 50,000 (company) or lower for individuals',
          validityPeriod: '1 year self-employment visa, then 2-year permit',
          pathToResidence: true,
          officialUrl: 'https://italiastartupvisa.mise.gov.it',
        ),
      ],
      incubators: [
        BusinessIncubator(
          name: 'Luiss EnLabs / LVenture Group',
          city: 'Rome',
          focus: 'Digital startups',
          immigrantFriendly: true,
          website: 'https://lfrancesco.it',
        ),
        BusinessIncubator(
          name: 'Polihub',
          city: 'Milan',
          focus: 'Deep tech, Politecnico di Milano accelerator',
          immigrantFriendly: true,
          website: 'https://www.polihub.it',
        ),
      ],
      governmentGrants: [
        'Smart&Start Italia: zero-interest loans up to EUR 1.5M for innovative startups',
        'Startup innovativa tax incentives: 30% tax deduction for investors',
        'Resto al Sud: grants up to EUR 60,000 for entrepreneurs in Southern Italy',
        'SELFIEmployment: zero-interest microloans up to EUR 50,000',
        'Invitalia ON - Oltre Nuove Imprese: grants up to EUR 200,000',
      ],
      businessAuthority: 'Camera di Commercio / InfoCamere',
      businessAuthorityUrl: 'https://www.registroimprese.it',
      businessAuthorityPhone: '+39 06 4704 1',
    ),

    // -----------------------------------------------------------------------
    // 16. LATVIA (LV)
    // -----------------------------------------------------------------------
    CountryBusinessGuide(
      country: 'Latvia',
      countryCode: 'LV',
      immigrantsCanStartBusiness: true,
      immigrantBusinessSummary:
          'Non-EU nationals can register a company (SIA) and apply for a temporary '
          'residence permit for commercial activity. Startup visa available since 2017.',
      permitRequirements: [
        'Temporary residence permit for commercial activity',
        'Minimum investment EUR 50,000 in company + EUR 10 tax payment/year per employee',
        'Startup activity visa: innovation-based business',
        'EU citizens: register freely',
      ],
      companyTypes: [
        CompanyType(
          localName: 'Sabiedrība ar ierobežotu atbildību',
          englishName: 'Limited Liability Company',
          abbreviation: 'SIA',
          description: 'Most popular company form',
          minimumCapital: 2800,
          capitalFullyPaidUpfront: false,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited to share capital',
          notes: ['EUR 2,800 minimum; can be registered with EUR 1 initially if capital <EUR 2,800'],
        ),
        CompanyType(
          localName: 'Akciju sabiedrība',
          englishName: 'Joint Stock Company',
          abbreviation: 'AS',
          description: 'For larger enterprises',
          minimumCapital: 35000,
          capitalFullyPaidUpfront: false,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited to share capital',
        ),
        CompanyType(
          localName: 'Individuālais komersants',
          englishName: 'Sole Proprietor',
          abbreviation: 'IK',
          description: 'Individual merchant',
          minimumCapital: 0,
          capitalFullyPaidUpfront: true,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Unlimited personal liability',
        ),
      ],
      registrationSteps: [
        '1. Draft articles of association',
        '2. Open bank account and deposit share capital',
        '3. Submit application to Register of Enterprises (Lursoft)',
        '4. Receive registration certificate and unified registration number',
        '5. Register with State Revenue Service (VID) for taxes',
        '6. Register for VAT if threshold exceeded',
        '7. Register as employer if hiring',
      ],
      registrationTimeline: '1-3 business days',
      registrationCost:
          'SIA: ~EUR 150-300 (state fee EUR 150 standard, EUR 50 electronic, '
          'EUR 20 publication). With lawyer: EUR 300-600.',
      taxInfo: TaxInfo(
        corporateTaxRate: 20.0,
        corporateTaxNotes:
            '0% on reinvested profits (Estonian model since 2018). '
            '20% on distributed profits (effective 25% gross-up).',
        vatStandardRate: 21.0,
        vatReducedRate: 12.0,
        vatRegistrationThreshold: 40000,
        incomeTaxRange: '20% (up to EUR 20,004), 23% (to EUR 78,100), 31% (above)',
        socialContributions:
            'Self-employed: 31.07% on declared income. '
            'Employer: 23.59%, Employee: 10.50%',
        taxAuthority: 'State Revenue Service (VID)',
        taxAuthorityUrl: 'https://www.vid.gov.lv',
      ),
      bankAccountRequirements: [
        'Passport, Latvian personal code (if resident)',
        'Company registration documents',
        'Banks: SEB, Swedbank, Citadele',
        'Non-residents increasingly difficult; some fintechs available',
      ],
      accountingObligations: [
        'All SIA must maintain double-entry bookkeeping',
        'Annual financial statements filed with Register of Enterprises',
        'Monthly tax declarations to VID (if employees)',
        'VAT returns monthly or quarterly',
        'Micro-enterprise tax option: 25% on turnover (limited eligibility)',
      ],
      hiringRulesForForeignEmployers: [
        'Register with VID as employer',
        'Non-EU workers need work permits',
        'Minimum wage: EUR 700/month (2026)',
        'Employer social contributions: ~23.59%',
        'Written employment contract required in Latvian',
      ],
      startupVisaPrograms: [
        StartupVisaProgram(
          name: 'Latvian Startup Visa',
          description: 'Temporary residence for innovative startup founders',
          requirements: [
            'Innovative, scalable startup idea',
            'Approved by Latvian Startup Visa committee (LIAA)',
            'Sufficient funds',
            'Health insurance',
          ],
          validityPeriod: '3 years',
          pathToResidence: true,
          officialUrl: 'https://www.liaa.gov.lv',
        ),
      ],
      incubators: [
        BusinessIncubator(
          name: 'TechHub Riga',
          city: 'Riga',
          focus: 'Tech startups',
          immigrantFriendly: true,
          website: 'https://techhub.com/riga',
        ),
      ],
      governmentGrants: [
        'LIAA startup support programs',
        'Altum (development finance institution): loans, guarantees, grants',
        'EU Structural Funds for innovation',
      ],
      businessAuthority: 'Register of Enterprises (Uzņēmumu reģistrs)',
      businessAuthorityUrl: 'https://www.ur.gov.lv',
      businessAuthorityPhone: '+371 67 031 703',
    ),

    // -----------------------------------------------------------------------
    // 17. LITHUANIA (LT)
    // -----------------------------------------------------------------------
    CountryBusinessGuide(
      country: 'Lithuania',
      countryCode: 'LT',
      immigrantsCanStartBusiness: true,
      immigrantBusinessSummary:
          'Non-EU nationals can register a company (UAB) and apply for a temporary '
          'residence permit for business. Lithuania has a Startup Visa and is very '
          'fintech-friendly with competitive costs.',
      permitRequirements: [
        'Temporary residence permit for lawful activity (business)',
        'Company must be operational, pay taxes, create jobs',
        'Startup visa for innovative startups (fast-track)',
        'EU citizens: register freely',
      ],
      companyTypes: [
        CompanyType(
          localName: 'Uždaroji akcinė bendrovė',
          englishName: 'Private Limited Company',
          abbreviation: 'UAB',
          description: 'Most popular form, straightforward',
          minimumCapital: 2500,
          capitalFullyPaidUpfront: false,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited to share capital',
          notes: ['EUR 2,500 minimum, at least 25% paid at incorporation'],
        ),
        CompanyType(
          localName: 'Mažoji bendrija',
          englishName: 'Small Partnership',
          abbreviation: 'MB',
          description: 'Simplified form for small businesses, max 10 members',
          minimumCapital: 0,
          capitalFullyPaidUpfront: true,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Unlimited for general partner',
          notes: ['Max 10 members, no minimum capital'],
        ),
        CompanyType(
          localName: 'Individuali veikla',
          englishName: 'Individual Activity (Self-employment)',
          abbreviation: '-',
          description: 'Registered self-employment via business certificate',
          minimumCapital: 0,
          capitalFullyPaidUpfront: true,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Unlimited personal liability',
        ),
      ],
      registrationSteps: [
        '1. Reserve company name at Register of Legal Entities',
        '2. Open temporary bank account and deposit capital',
        '3. Draft and notarize articles of association',
        '4. Register with Register of Legal Entities (Registrų centras)',
        '5. Register with State Tax Inspectorate (VMI)',
        '6. Register for VAT if required',
        '7. Register with Sodra (social insurance)',
      ],
      registrationTimeline: '1-3 business days',
      registrationCost:
          'UAB: ~EUR 200-400 (state fee EUR 49.60, notary ~EUR 100-200). '
          'MB: ~EUR 100-150.',
      taxInfo: TaxInfo(
        corporateTaxRate: 15.0,
        corporateTaxNotes: '5% for small companies (turnover <EUR 300,000, <10 employees) in first year',
        vatStandardRate: 21.0,
        vatReducedRate: 9.0,
        vatRegistrationThreshold: 45000,
        incomeTaxRange: '20% (up to EUR 101,094) and 32% (above)',
        socialContributions:
            'Self-employed: ~19.5% (Sodra). Employer: ~1.77% (variable by risk)',
        taxAuthority: 'State Tax Inspectorate (VMI)',
        taxAuthorityUrl: 'https://www.vmi.lt',
      ),
      bankAccountRequirements: [
        'Passport, Lithuanian personal code (if resident)',
        'Company registration extract',
        'Banks: SEB, Swedbank, Luminor',
        'Fintechs: Revolut, Paysera (Lithuanian-founded)',
      ],
      accountingObligations: [
        'All UAB: double-entry bookkeeping',
        'Annual financial statements filed with Register of Legal Entities',
        'Monthly VAT returns if registered',
        'Annual corporate tax return by June 15',
        'Audit mandatory if 2 of 3: EUR 3.5M revenue, EUR 1.8M assets, 50 employees',
      ],
      hiringRulesForForeignEmployers: [
        'Register with Sodra as employer',
        'Non-EU workers: work permit from Employment Service',
        'Minimum wage: EUR 924/month (2026)',
        'Employer Sodra contributions: ~1.77%',
        'Employee Sodra: ~19.5%',
        'Written employment contract required in Lithuanian',
      ],
      startupVisaPrograms: [
        StartupVisaProgram(
          name: 'Lithuanian Startup Visa',
          description: 'Temporary residence for innovative startup founders',
          requirements: [
            'Innovative, scalable, tech-oriented business',
            'Approved by Startup Lithuania evaluation committee',
            'Sufficient personal funds',
            'Health insurance',
          ],
          validityPeriod: '1 year, extendable to 2 years',
          pathToResidence: true,
          officialUrl: 'https://startupvisalithuania.com',
        ),
      ],
      incubators: [
        BusinessIncubator(
          name: 'Startup Lithuania / Enterprise Lithuania',
          city: 'Vilnius',
          focus: 'Startup ecosystem development',
          immigrantFriendly: true,
          website: 'https://startuplithuania.com',
        ),
        BusinessIncubator(
          name: 'Vilnius Tech Park',
          city: 'Vilnius',
          focus: 'Tech, fintech',
          immigrantFriendly: true,
          website: 'https://vilniustechpark.com',
        ),
      ],
      governmentGrants: [
        'INVEGA: SME loans, guarantees, and grants',
        'EU Structural Funds for innovation and competitiveness',
        'Inovacijų skatinimas: innovation vouchers up to EUR 6,000',
        'Startup Lithuania acceleration programs',
      ],
      businessAuthority: 'State Enterprise Centre of Registers (Registrų centras)',
      businessAuthorityUrl: 'https://www.registrucentras.lt',
      businessAuthorityPhone: '+370 5 268 8262',
    ),

    // -----------------------------------------------------------------------
    // 18. LUXEMBOURG (LU)
    // -----------------------------------------------------------------------
    CountryBusinessGuide(
      country: 'Luxembourg',
      countryCode: 'LU',
      immigrantsCanStartBusiness: true,
      immigrantBusinessSummary:
          'Non-EU nationals need a business authorization (autorisation d\'établissement) '
          'from the Ministry of the Economy and a residence permit. Luxembourg is a major '
          'financial center with multilingual business environment.',
      permitRequirements: [
        'Autorisation d\'établissement (business permit) from Ministry of Economy',
        'Residence permit for self-employed activity',
        'Proof of professional qualifications/experience',
        'Clean criminal record',
        'EU citizens: business permit still needed but residence is free',
      ],
      companyTypes: [
        CompanyType(
          localName: 'Société à responsabilité limitée',
          englishName: 'Private Limited Company',
          abbreviation: 'S.à r.l.',
          description: 'Most common form for SMEs',
          minimumCapital: 12000,
          capitalFullyPaidUpfront: true,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited to share capital',
          notes: ['EUR 12,000 fully paid up at formation'],
        ),
        CompanyType(
          localName: 'Société anonyme',
          englishName: 'Public Limited Company',
          abbreviation: 'SA',
          description: 'For larger companies',
          minimumCapital: 30000,
          capitalFullyPaidUpfront: false,
          minShareholders: 1,
          minDirectors: 3,
          liabilityType: 'Limited to share capital',
          notes: ['EUR 30,000 minimum, 25% paid up'],
        ),
        CompanyType(
          localName: 'Société par actions simplifiée',
          englishName: 'Simplified Joint Stock Company',
          abbreviation: 'SAS',
          description: 'New flexible form since 2016',
          minimumCapital: 1,
          capitalFullyPaidUpfront: true,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited to share capital',
          notes: ['Min EUR 1, max EUR 12M. Max 100 shareholders.'],
        ),
      ],
      registrationSteps: [
        '1. Obtain business authorization from Ministry of Economy',
        '2. Draft articles of association (notarial deed for S.à r.l.)',
        '3. Deposit capital in bank',
        '4. Notary files with Trade and Companies Register (RCS)',
        '5. Publication in RESA (Recueil Electronique des Sociétés et Associations)',
        '6. Register with Administration des Contributions (tax)',
        '7. Register with CCSS (social security)',
        '8. Register for VAT',
      ],
      registrationTimeline: '1-2 weeks',
      registrationCost:
          'S.à r.l.: ~EUR 2,000-3,500 (notary ~EUR 1,500, RCS ~EUR 75, '
          'publication ~EUR 200). Business authorization: EUR 24.',
      taxInfo: TaxInfo(
        corporateTaxRate: 24.94,
        corporateTaxNotes:
            '17% CIT + 1.19% solidarity surcharge + ~6.75% municipal business tax (in Luxembourg City). '
            'Combined effective ~24.94%. 15% for income <EUR 175,000.',
        vatStandardRate: 17.0,
        vatReducedRate: 8.0,
        vatRegistrationThreshold: 35000,
        incomeTaxRange: '0% (up to EUR 12,438) to 42% (over EUR 200,004)',
        socialContributions:
            'Self-employed: ~25% of income. Employer: ~12-15% of gross salary',
        taxAuthority: 'Administration des Contributions Directes (ACD)',
        taxAuthorityUrl: 'https://impotsdirects.public.lu',
      ),
      bankAccountRequirements: [
        'Notarized articles of association',
        'RCS registration extract',
        'Business authorization',
        'Passport/ID of all directors and beneficial owners',
        'Proof of address',
        'Banks: BGL BNP Paribas, ING, Banque de Luxembourg',
      ],
      accountingObligations: [
        'All companies: double-entry bookkeeping per Luxembourg GAAP or IFRS',
        'Annual accounts filed with RCS',
        'Audit mandatory if 2 of 3: EUR 4.4M revenue, EUR 4.4M assets, 50 employees',
        'Monthly/quarterly VAT returns',
        'Corporate tax return by May 31 of following year',
      ],
      hiringRulesForForeignEmployers: [
        'Register with CCSS as employer',
        'Non-EU workers need work permit from ADEM',
        'Minimum social wage: EUR 2,570/month unskilled, EUR 3,085/month skilled (2026)',
        'Employer social contributions: ~12-15%',
        'Written contract required in language understood by employee',
      ],
      startupVisaPrograms: [],
      incubators: [
        BusinessIncubator(
          name: 'Technoport',
          city: 'Esch-sur-Alzette',
          focus: 'Technology incubator',
          immigrantFriendly: true,
          website: 'https://www.technoport.lu',
        ),
        BusinessIncubator(
          name: 'Luxembourg House of Financial Technology (LHoFT)',
          city: 'Luxembourg City',
          focus: 'Fintech',
          immigrantFriendly: true,
          website: 'https://www.lhoft.com',
        ),
      ],
      governmentGrants: [
        'Fit 4 Start: acceleration program with EUR 150,000 aid',
        'Luxinnovation SME packages: up to EUR 5,000 for consulting',
        'RDI aid schemes: up to 25-70% of R&D project costs',
        'SNCI loans for startups',
      ],
      businessAuthority: 'Trade and Companies Register (RCS) / House of Entrepreneurship',
      businessAuthorityUrl: 'https://www.houseofentrepreneurship.lu',
      businessAuthorityPhone: '+352 42 39 39 330',
    ),

    // -----------------------------------------------------------------------
    // 19. MALTA (MT)
    // -----------------------------------------------------------------------
    CountryBusinessGuide(
      country: 'Malta',
      countryCode: 'MT',
      immigrantsCanStartBusiness: true,
      immigrantBusinessSummary:
          'Non-EU nationals can register a company and apply for a self-employment license '
          'from Identity Malta. Malta has English as an official language and an attractive '
          'tax refund system for shareholders.',
      permitRequirements: [
        'Self-employment license from Identity Malta',
        'Company registration at Malta Business Registry',
        'Proof of qualifications and business viability',
        'Health insurance and accommodation',
        'EU citizens: register freely',
      ],
      companyTypes: [
        CompanyType(
          localName: 'Private Limited Liability Company',
          englishName: 'Private Limited Liability Company',
          abbreviation: 'Ltd',
          description: 'Most common form, English-law based',
          minimumCapital: 1165,
          capitalFullyPaidUpfront: false,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited to share capital',
          notes: [
            'EUR 1,165 minimum, 20% paid up at formation',
            'Company secretary required',
          ],
        ),
        CompanyType(
          localName: 'Public Limited Company',
          englishName: 'Public Limited Company',
          abbreviation: 'PLC',
          description: 'For larger enterprises',
          minimumCapital: 46588,
          capitalFullyPaidUpfront: false,
          minShareholders: 2,
          minDirectors: 2,
          liabilityType: 'Limited to share capital',
          notes: ['EUR 46,588 minimum, 25% paid up'],
        ),
      ],
      registrationSteps: [
        '1. Name verification with Malta Business Registry (MBR)',
        '2. Draft memorandum and articles of association',
        '3. Deposit minimum capital in bank',
        '4. File documents with MBR',
        '5. Receive Certificate of Registration',
        '6. Register with Inland Revenue for tax and VAT',
        '7. Register with Employment and Training Corporation if hiring',
      ],
      registrationTimeline: '1-3 business days',
      registrationCost:
          'Ltd: ~EUR 300-500 (registration fee EUR 245, misc). '
          'With legal setup: EUR 1,000-2,000.',
      taxInfo: TaxInfo(
        corporateTaxRate: 35.0,
        corporateTaxNotes:
            '35% headline rate BUT 6/7 tax refund to shareholders = effective 5% for non-resident shareholders. '
            'Complex refund system — consult tax advisor.',
        vatStandardRate: 18.0,
        vatReducedRate: 7.0,
        vatRegistrationThreshold: 20000,
        incomeTaxRange: '0% (up to EUR 9,100) to 35% (over EUR 60,000)',
        socialContributions:
            'Self-employed: 15% of net income (min EUR 34.36/week). '
            'Employer: 10% of gross salary',
        taxAuthority: 'Commissioner for Revenue',
        taxAuthorityUrl: 'https://cfr.gov.mt',
      ),
      bankAccountRequirements: [
        'Passport/ID, proof of address',
        'Certificate of Registration from MBR',
        'Memorandum & articles of association',
        'Banks: BOV, HSBC Malta, Lombard Bank',
        'Account opening can take 2-6 weeks due to due diligence',
      ],
      accountingObligations: [
        'All companies: proper books of account',
        'Annual financial statements filed with MBR',
        'Audit mandatory for all limited companies',
        'Quarterly VAT returns',
        'Annual tax return by March 31 (extended deadlines available)',
      ],
      hiringRulesForForeignEmployers: [
        'Register with ETC (Employment and Training Corporation)',
        'Non-EU workers need single work permit',
        'Minimum wage: EUR 213.54/week (~EUR 925/month) in 2026',
        'Employer social security: 10% of gross',
        'Written contract required',
      ],
      startupVisaPrograms: [
        StartupVisaProgram(
          name: 'Malta Startup Residence Programme',
          description: 'Residence permit for innovative startup founders',
          requirements: [
            'Innovative startup in technology/knowledge sector',
            'Endorsed by Malta Enterprise',
            'Sufficient financial resources',
            'Health insurance',
          ],
          validityPeriod: '3 years, renewable',
          pathToResidence: true,
          officialUrl: 'https://maltaenterprise.com',
        ),
      ],
      incubators: [
        BusinessIncubator(
          name: 'Malta Enterprise',
          city: 'Pieta',
          focus: 'General business support and incentives',
          immigrantFriendly: true,
          website: 'https://www.maltaenterprise.com',
        ),
      ],
      governmentGrants: [
        'Malta Enterprise startup incentives: tax credits, grants',
        'Business START: up to EUR 25,000 for new businesses',
        'Smart & Sustainable Investment Grant: up to EUR 500,000',
        'Micro Invest scheme: tax credits up to EUR 50,000',
      ],
      businessAuthority: 'Malta Business Registry (MBR)',
      businessAuthorityUrl: 'https://mbr.mt',
      businessAuthorityPhone: '+356 2258 2300',
    ),

    // -----------------------------------------------------------------------
    // 20. NETHERLANDS (NL)
    // -----------------------------------------------------------------------
    CountryBusinessGuide(
      country: 'Netherlands',
      countryCode: 'NL',
      immigrantsCanStartBusiness: true,
      immigrantBusinessSummary:
          'Non-EU nationals can apply for a self-employment residence permit or use the '
          'Dutch-American/Japanese/Turkish Friendship Treaty (DAFT) if applicable. The '
          'Netherlands has a strong startup ecosystem and dedicated startup visa.',
      permitRequirements: [
        'Self-employment residence permit (assessed on points: personal experience, '
            'business plan, added value to Netherlands)',
        'DAFT treaty: EUR 4,500 investment for US/Japanese/Turkish citizens',
        'Startup visa: facilitated by approved incubator/facilitator',
        'EU citizens: register at KVK immediately',
      ],
      companyTypes: [
        CompanyType(
          localName: 'Besloten Vennootschap',
          englishName: 'Private Limited Company',
          abbreviation: 'BV',
          description: 'Most popular form, very flexible since 2012 reform',
          minimumCapital: 0.01,
          capitalFullyPaidUpfront: true,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited to share capital',
          notes: [
            'No minimum capital since Flex-BV reform 2012 (EUR 0.01 sufficient)',
            'Notarial deed required',
            'Very popular for startups and holding structures',
          ],
        ),
        CompanyType(
          localName: 'Naamloze Vennootschap',
          englishName: 'Public Limited Company',
          abbreviation: 'NV',
          description: 'For large and listed companies',
          minimumCapital: 45000,
          capitalFullyPaidUpfront: false,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited to share capital',
        ),
        CompanyType(
          localName: 'Eenmanszaak',
          englishName: 'Sole Proprietorship',
          abbreviation: '-',
          description: 'Simple form for individuals',
          minimumCapital: 0,
          capitalFullyPaidUpfront: true,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Unlimited personal liability',
          notes: ['Self-employed deduction (zelfstandigenaftrek) available'],
        ),
      ],
      registrationSteps: [
        '1. Draft articles of association via notary (for BV)',
        '2. Notary checks and executes deed of incorporation',
        '3. Register with KVK (Chamber of Commerce) — often done by notary',
        '4. Receive KVK number and RSIN/BSN',
        '5. Tax registration with Belastingdienst (automatic after KVK)',
        '6. Apply for VAT number',
        '7. Open business bank account',
      ],
      registrationTimeline: '1-5 business days for BV; same day for eenmanszaak at KVK',
      registrationCost:
          'BV: ~EUR 1,000-2,500 (notary EUR 500-1,500, KVK EUR 75). '
          'Eenmanszaak: EUR 75 (KVK registration).',
      taxInfo: TaxInfo(
        corporateTaxRate: 25.8,
        corporateTaxNotes: '19% on first EUR 200,000; 25.8% above',
        vatStandardRate: 21.0,
        vatReducedRate: 9.0,
        vatRegistrationThreshold: 20000,
        incomeTaxRange: '9.32% (box 1 low) to 49.50% (over EUR 75,518)',
        socialContributions:
            'Self-employed: voluntary. Employer: ~18% social insurance premiums',
        taxAuthority: 'Belastingdienst (Tax and Customs Administration)',
        taxAuthorityUrl: 'https://www.belastingdienst.nl',
      ),
      bankAccountRequirements: [
        'KVK extract',
        'Passport/ID',
        'BSN number (if Dutch resident)',
        'Notarial deed of incorporation',
        'Banks: ING, ABN AMRO, Rabobank',
        'Bunq, Revolut Business for faster opening',
      ],
      accountingObligations: [
        'All BVs: double-entry bookkeeping',
        'Annual financial statements filed with KVK',
        'Corporate tax return annually',
        'VAT returns: monthly, quarterly, or annually',
        'Audit mandatory if 2 of 3: EUR 12M revenue, EUR 6M assets, 50 employees',
        'Digital accounting widely used (exact, Twinfield, Xero)',
      ],
      hiringRulesForForeignEmployers: [
        'Register with Belastingdienst as employer (loonheffingen)',
        'Non-EU workers: single permit (GVVA) via UWV/IND',
        'No statutory minimum wage per hour; monthly minimums by age',
        'Minimum wage (21+): EUR 2,070/month gross (2026)',
        'Employer contributions: ~18% social premiums',
        '8% holiday allowance (vakantiegeld) mandatory',
      ],
      startupVisaPrograms: [
        StartupVisaProgram(
          name: 'Dutch Startup Visa',
          description: 'Residence permit for innovative entrepreneurs mentored by Dutch facilitator',
          requirements: [
            'Innovative product or service',
            'Cooperation agreement with approved facilitator (sponsor)',
            'Sufficient financial means',
            'Registered with KVK',
            'Facilitator guides for 1 year',
          ],
          validityPeriod: '1 year, then switch to self-employment permit',
          pathToResidence: true,
          officialUrl: 'https://www.rvo.nl/subsidies-financiering/startup-visa',
        ),
      ],
      incubators: [
        BusinessIncubator(
          name: 'YES!Delft',
          city: 'Delft',
          focus: 'Deep tech, TU Delft linked',
          immigrantFriendly: true,
          website: 'https://www.yesdelft.com',
        ),
        BusinessIncubator(
          name: 'Rockstart',
          city: 'Amsterdam',
          focus: 'Energy, AgriFood, Emerging Tech',
          immigrantFriendly: true,
          website: 'https://www.rockstart.com',
        ),
        BusinessIncubator(
          name: 'HighTechXL',
          city: 'Eindhoven',
          focus: 'Deep tech, hardware ventures',
          immigrantFriendly: true,
          website: 'https://hightechxl.com',
        ),
      ],
      governmentGrants: [
        'WBSO: R&D tax credit (reduces wage costs for R&D employees)',
        'Innovation Box: 9% effective tax rate on qualifying IP profits',
        'Seed Business Angel scheme: co-investment fund',
        'DOEN Foundation: grants for social entrepreneurs',
        'RVO innovation credits: loans for R&D up to EUR 5M',
      ],
      businessAuthority: 'KVK (Kamer van Koophandel / Chamber of Commerce)',
      businessAuthorityUrl: 'https://www.kvk.nl',
      businessAuthorityPhone: '+31 88 585 15 85',
    ),

    // -----------------------------------------------------------------------
    // 21. POLAND (PL)
    // -----------------------------------------------------------------------
    CountryBusinessGuide(
      country: 'Poland',
      countryCode: 'PL',
      immigrantsCanStartBusiness: true,
      immigrantBusinessSummary:
          'Non-EU nationals can form a sp. z o.o. (LLC) regardless of residence status. '
          'However, sole proprietorship (JDG) requires a residence permit with work rights. '
          'Company formation is fast and affordable.',
      permitRequirements: [
        'Sp. z o.o.: no residence permit needed to register',
        'JDG (sole proprietorship): requires residence permit with work access',
        'Temporary residence permit for business purpose available',
        'Poland Business Harbour program (for selected countries)',
        'EU citizens: free establishment',
      ],
      companyTypes: [
        CompanyType(
          localName: 'Spółka z ograniczoną odpowiedzialnością',
          englishName: 'Limited Liability Company',
          abbreviation: 'sp. z o.o.',
          description: 'Most popular form, can be formed online via S24 portal',
          minimumCapital: 5000,
          capitalFullyPaidUpfront: true,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited to share capital',
          notes: [
            'PLN 5,000 (~EUR 1,150) minimum capital',
            'Can be registered online in 24h via S24 portal (gov.pl)',
            'One-person sp. z o.o. possible',
          ],
        ),
        CompanyType(
          localName: 'Prosta spółka akcyjna',
          englishName: 'Simple Joint Stock Company',
          abbreviation: 'PSA',
          description: 'New form since 2021, designed for startups',
          minimumCapital: 1,
          capitalFullyPaidUpfront: true,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited',
          notes: [
            'PLN 1 (~EUR 0.23) minimum capital!',
            'Shares can be issued for work/services (not just cash)',
            'Very startup-friendly',
          ],
        ),
        CompanyType(
          localName: 'Jednoosobowa działalność gospodarcza',
          englishName: 'Sole Proprietorship',
          abbreviation: 'JDG',
          description: 'Individual business activity, very popular in Poland',
          minimumCapital: 0,
          capitalFullyPaidUpfront: true,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Unlimited personal liability',
          notes: [
            'Requires PESEL number and residence permit with work rights',
            'Registration free via CEIDG',
            'Flat tax options available (19% or ryczałt)',
          ],
        ),
      ],
      registrationSteps: [
        '1. Obtain PESEL number (required for directors/shareholders)',
        '2. Draft articles of association or use S24 template (online)',
        '3. Register via S24 portal (gov.pl) or traditional KRS court filing',
        '4. Receive KRS number (National Court Register)',
        '5. Automatic NIP (tax) and REGON (statistics) assignment',
        '6. Register for VAT at local tax office',
        '7. Open business bank account',
        '8. Register with ZUS (social insurance) if applicable',
      ],
      registrationTimeline:
          'S24 online: 1-2 days. Traditional KRS: 7-14 days. JDG: same day via CEIDG.',
      registrationCost:
          'Sp. z o.o. via S24: PLN 350 (~EUR 80) total (250 court + 100 publication). '
          'Traditional: PLN 600 (~EUR 140). JDG: FREE. PSA: PLN 350.',
      taxInfo: TaxInfo(
        corporateTaxRate: 19.0,
        corporateTaxNotes: '9% for small taxpayers (revenue <EUR 2M) and startups in first year',
        vatStandardRate: 23.0,
        vatReducedRate: 8.0,
        vatRegistrationThreshold: 200000,
        incomeTaxRange: '12% (up to PLN 120,000) and 32% (above). Flat tax option: 19%.',
        socialContributions:
            'Self-employed ZUS: ~PLN 1,600/month (~EUR 370) full rate. '
            'Preferential first 24 months: ~PLN 400/month. '
            'Employer ZUS: ~20% of gross salary',
        taxAuthority: 'Krajowa Administracja Skarbowa (KAS)',
        taxAuthorityUrl: 'https://www.podatki.gov.pl',
      ),
      bankAccountRequirements: [
        'PESEL or NIP number',
        'KRS extract or CEIDG printout',
        'Passport/ID',
        'Banks: PKO BP, mBank, ING, Santander Poland',
        'Non-residents: some banks accept, others require Polish ID',
      ],
      accountingObligations: [
        'Sp. z o.o.: full double-entry bookkeeping mandatory',
        'JDG: simplified tax ledger (KPiR) or lump-sum (ryczałt) if eligible',
        'Annual financial statements filed with KRS (sp. z o.o.)',
        'Monthly VAT returns (JPK_VAT file)',
        'Corporate tax return by March 31',
        'KSeF (structured electronic invoicing) from 2026',
      ],
      hiringRulesForForeignEmployers: [
        'Register with ZUS as employer within 7 days of first hire',
        'Non-EU workers: work permit type A/B or oświadczenie (declaration) for 24 months',
        'Minimum wage: PLN 4,626/month (~EUR 1,068) in 2026',
        'Employer ZUS contributions: ~20% of gross salary',
        'Written employment contract (umowa o pracę) in Polish',
      ],
      startupVisaPrograms: [
        StartupVisaProgram(
          name: 'Poland Business Harbour',
          description: 'Facilitated visa for IT/tech specialists and entrepreneurs from selected countries',
          requirements: [
            'IT/tech sector activity',
            'Business or employment in tech',
            'Available for citizens of specific countries (Belarus, Ukraine, Georgia, etc.)',
          ],
          validityPeriod: 'D-type visa (1 year) then temporary residence',
          pathToResidence: true,
          officialUrl: 'https://www.gov.pl/web/poland-businessharbour',
        ),
      ],
      incubators: [
        BusinessIncubator(
          name: 'Google for Startups Campus Warsaw',
          city: 'Warsaw',
          focus: 'Tech, general startup support',
          immigrantFriendly: true,
          website: 'https://www.campus.co/warsaw',
        ),
        BusinessIncubator(
          name: 'Huge Thing',
          city: 'Warsaw',
          focus: 'Acceleration programs',
          immigrantFriendly: true,
          website: 'https://hugething.vc',
        ),
      ],
      governmentGrants: [
        'PARP (Polish Agency for Enterprise Development): grants for startups',
        'BGK guarantees for SME bank loans',
        'EU Funds: Smart Growth (POIR) and regional operational programs',
        'PFR Ventures: VC fund of funds',
        'Startup Platform (Platforma Startowa): acceleration + up to PLN 1M grant',
      ],
      businessAuthority: 'National Court Register (KRS) / PARP',
      businessAuthorityUrl: 'https://www.biznes.gov.pl',
      businessAuthorityPhone: '+48 22 432 89 91',
    ),

    // -----------------------------------------------------------------------
    // 22. PORTUGAL (PT)
    // -----------------------------------------------------------------------
    CountryBusinessGuide(
      country: 'Portugal',
      countryCode: 'PT',
      immigrantsCanStartBusiness: true,
      immigrantBusinessSummary:
          'Non-EU nationals can register a company and apply for a residence permit for '
          'independent work or entrepreneurship (D2 visa). Portugal has a startup visa '
          'program and the Tech Visa. Very welcoming ecosystem for digital nomads.',
      permitRequirements: [
        'D2 visa for independent work / entrepreneurship',
        'Startup Visa: for tech startup founders with incubator support',
        'Tech Visa: fast-track for tech companies and their employees',
        'NIF (tax number) obtainable without residence',
        'EU citizens: register and start freely',
      ],
      companyTypes: [
        CompanyType(
          localName: 'Sociedade por Quotas',
          englishName: 'Private Limited Company',
          abbreviation: 'Lda.',
          description: 'Most common form, flexible',
          minimumCapital: 1,
          capitalFullyPaidUpfront: false,
          minShareholders: 2,
          minDirectors: 1,
          liabilityType: 'Limited to share capital',
          notes: [
            'No minimum capital in practice (EUR 1 per partner)',
            'Unipessoal Lda. = single-member version',
          ],
        ),
        CompanyType(
          localName: 'Sociedade Unipessoal por Quotas',
          englishName: 'Single-Member Limited Company',
          abbreviation: 'Unipessoal Lda.',
          description: 'Single-member LLC, very popular',
          minimumCapital: 1,
          capitalFullyPaidUpfront: false,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited to share capital',
        ),
        CompanyType(
          localName: 'Sociedade Anónima',
          englishName: 'Public Limited Company',
          abbreviation: 'SA',
          description: 'For larger companies',
          minimumCapital: 50000,
          capitalFullyPaidUpfront: false,
          minShareholders: 5,
          minDirectors: 1,
          liabilityType: 'Limited to share capital',
        ),
        CompanyType(
          localName: 'Empresário em Nome Individual',
          englishName: 'Sole Proprietor',
          abbreviation: 'ENI',
          description: 'Individual entrepreneur',
          minimumCapital: 0,
          capitalFullyPaidUpfront: true,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Unlimited personal liability',
          notes: ['Trabalhador independente (green receipts) very common for freelancers'],
        ),
      ],
      registrationSteps: [
        '1. Obtain NIF (tax identification number) from Finanças',
        '2. Register via Empresa na Hora (one-stop-shop, same-day incorporation)',
        '3. Choose company name from pre-approved list or request custom name',
        '4. Sign articles of association at Empresa na Hora desk',
        '5. Receive NIPC (company tax number) and commercial registration',
        '6. Open business bank account',
        '7. Register for Social Security (Segurança Social)',
        '8. Register for VAT via Portal das Finanças',
      ],
      registrationTimeline:
          'Empresa na Hora: 1 hour! Traditional: 5-10 business days.',
      registrationCost:
          'Lda. via Empresa na Hora: EUR 360 (all inclusive). '
          'Online via Empresa Online: EUR 220. '
          'Sole proprietor: FREE via Portal do Cidadão.',
      taxInfo: TaxInfo(
        corporateTaxRate: 21.0,
        corporateTaxNotes:
            '21% standard. SMEs (first EUR 50,000 profit): 17%. '
            'Madeira/Azores: reduced rates available. '
            'Derrama municipal: up to 1.5% additional.',
        vatStandardRate: 23.0,
        vatReducedRate: 6.0,
        vatRegistrationThreshold: 14500,
        incomeTaxRange: '14.5% (up to EUR 7,703) to 48% (over EUR 78,834)',
        socialContributions:
            'Self-employed: 21.4% of declared income. '
            'Employer: 23.75% of gross salary',
        taxAuthority: 'Autoridade Tributária e Aduaneira (AT)',
        taxAuthorityUrl: 'https://www.portaldasfinancas.gov.pt',
      ),
      bankAccountRequirements: [
        'NIF number',
        'Company registration certificate (certidão comercial)',
        'Passport/ID of directors',
        'Portuguese address (can use fiscal representative)',
        'Banks: Millennium BCP, Caixa Geral, Novo Banco, ActivoBank',
      ],
      accountingObligations: [
        'All Lda./SA: organized accounting (contabilidade organizada)',
        'Simplified regime for sole proprietors under EUR 200,000 turnover',
        'Annual IES (corporate tax + accounts) filed electronically by July 15',
        'Monthly/quarterly VAT returns',
        'SAF-T accounting file submission monthly to tax authority',
        'Certified accountant (Contabilista Certificado) mandatory for organized accounting',
      ],
      hiringRulesForForeignEmployers: [
        'Register with Segurança Social as employer',
        'Non-EU workers need work visa (D1 or combined permit)',
        'Minimum wage: EUR 870/month (14 payments) in 2026',
        'Employer social security: 23.75% of gross salary',
        '13th and 14th month salary (subsidio de Natal/férias) mandatory',
        'Written employment contract required in Portuguese',
      ],
      startupVisaPrograms: [
        StartupVisaProgram(
          name: 'Portugal Startup Visa',
          description: 'Residence visa for innovative startup founders from non-EU countries',
          requirements: [
            'Innovative, technology-based, scalable startup idea',
            'Incubation agreement with IAPMEI-certified incubator',
            'Minimum EUR 5,176 in funds per year',
            'Health insurance',
          ],
          investmentMinimum: 'EUR 5,176 (personal sustenance)',
          validityPeriod: '1 year residence, then renewable for 2-year periods',
          pathToResidence: true,
          officialUrl: 'https://startupportugal.com/startup-visa',
        ),
        StartupVisaProgram(
          name: 'Portugal Tech Visa',
          description: 'Fast-track work visa for certified tech companies and their employees',
          requirements: [
            'Company certified by IAPMEI as tech/innovative',
            'Job offer for a tech/specialist position',
            'Faster processing (10-day target)',
          ],
          validityPeriod: 'Residence permit duration varies',
          pathToResidence: true,
          officialUrl: 'https://www.iapmei.pt/PRODUTOS-E-SERVICOS/Incentivos-Financiamento/Tech-Visa.aspx',
        ),
      ],
      incubators: [
        BusinessIncubator(
          name: 'Startup Lisboa',
          city: 'Lisbon',
          focus: 'General startup incubation',
          immigrantFriendly: true,
          website: 'https://www.startuplisboa.com',
        ),
        BusinessIncubator(
          name: 'Beta-i',
          city: 'Lisbon',
          focus: 'Innovation, corporate collaboration',
          immigrantFriendly: true,
          website: 'https://beta-i.com',
        ),
      ],
      governmentGrants: [
        'IAPMEI startup vouchers: EUR 2,500/month for 12 months',
        'Portugal 2030 (EU funds): various SME grants',
        'SIFIDE II: R&D tax credit up to 82.5% of incremental expenses',
        'SI Inovação: grants for innovative projects',
        'StartUP Voucher: for young entrepreneurs (up to 35 years)',
      ],
      businessAuthority: 'IAPMEI / IRN (Instituto dos Registos e do Notariado)',
      businessAuthorityUrl: 'https://eportugal.gov.pt',
      businessAuthorityPhone: '+351 213 584 500',
    ),

    // -----------------------------------------------------------------------
    // 23. ROMANIA (RO)
    // -----------------------------------------------------------------------
    CountryBusinessGuide(
      country: 'Romania',
      countryCode: 'RO',
      immigrantsCanStartBusiness: true,
      immigrantBusinessSummary:
          'Non-EU nationals can register a company (SRL) without a residence permit. '
          'To reside and manage the business, a long-stay visa and residence permit for '
          'business activities is required. Very affordable setup costs.',
      permitRequirements: [
        'Company registration possible without residence permit',
        'Long-stay visa type D for business activities',
        'Temporary residence permit for commercial activities',
        'Investment of at least EUR 100,000 (or EUR 50,000 + 3 jobs) for investor residence',
        'EU citizens: register freely',
      ],
      companyTypes: [
        CompanyType(
          localName: 'Societate cu Răspundere Limitată',
          englishName: 'Limited Liability Company',
          abbreviation: 'SRL',
          description: 'Most popular form, very affordable',
          minimumCapital: 1,
          capitalFullyPaidUpfront: true,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited to share capital',
          notes: [
            'RON 1 (~EUR 0.20) minimum capital since 2021',
            'SRL-D: special status for new entrepreneurs with tax benefits',
          ],
        ),
        CompanyType(
          localName: 'Societate pe Acțiuni',
          englishName: 'Joint Stock Company',
          abbreviation: 'SA',
          description: 'For larger companies',
          minimumCapital: 25000,
          capitalFullyPaidUpfront: false,
          minShareholders: 2,
          minDirectors: 1,
          liabilityType: 'Limited to share capital',
          notes: ['RON 25,000 (~EUR 5,000) minimum, 30% paid up'],
        ),
        CompanyType(
          localName: 'Persoană Fizică Autorizată',
          englishName: 'Authorized Natural Person',
          abbreviation: 'PFA',
          description: 'Individual business, like sole proprietor',
          minimumCapital: 0,
          capitalFullyPaidUpfront: true,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Unlimited personal liability',
          notes: ['Requires Romanian residence'],
        ),
      ],
      registrationSteps: [
        '1. Verify company name availability at Trade Register (ONRC)',
        '2. Draft articles of incorporation',
        '3. Obtain proof of company headquarters (lease agreement)',
        '4. Submit documents to ONRC (Trade Register Office)',
        '5. Receive registration certificate and CUI (tax number)',
        '6. Register for VAT if required',
        '7. Open business bank account',
        '8. Register with labor authority if hiring',
      ],
      registrationTimeline: '3-5 business days',
      registrationCost:
          'SRL: ~EUR 100-200 (ONRC fee RON 100, publication RON 20, misc). '
          'With lawyer: EUR 300-500. PFA: ~EUR 20-50.',
      taxInfo: TaxInfo(
        corporateTaxRate: 16.0,
        corporateTaxNotes:
            '16% standard. Micro-enterprise tax: 1% on revenue (if <EUR 500,000 turnover '
            'and ≥1 employee). Very popular!',
        vatStandardRate: 19.0,
        vatReducedRate: 9.0,
        vatRegistrationThreshold: 44622,
        incomeTaxRange: '10% flat rate on personal income',
        socialContributions:
            'Self-employed: 25% pension + 10% health = 35% on declared income (if >12x min wage). '
            'Employer: 2.25% work insurance',
        taxAuthority: 'Agenția Națională de Administrare Fiscală (ANAF)',
        taxAuthorityUrl: 'https://www.anaf.ro',
      ),
      bankAccountRequirements: [
        'Company registration certificate from ONRC',
        'Articles of incorporation',
        'Passport/ID of directors',
        'Proof of registered address',
        'Banks: Banca Transilvania, BRD, ING Romania, BCR',
      ],
      accountingObligations: [
        'All SRL: double-entry bookkeeping (even micro-enterprises)',
        'Annual financial statements filed with Ministry of Finance',
        'Monthly/quarterly tax declarations to ANAF',
        'VAT returns monthly or quarterly',
        'Micro-enterprise quarterly declarations',
        'Certified accountant recommended (CECCAR registered)',
      ],
      hiringRulesForForeignEmployers: [
        'Register with ITM (Territorial Labor Inspectorate)',
        'Non-EU workers: work permit from General Immigration Inspectorate',
        'Minimum gross wage: RON 3,700/month (~EUR 740) in 2026',
        'Employer contributions: ~2.25% (work insurance)',
        'Employee pays 25% pension + 10% health + 10% income tax',
        'Written employment contract registered with Revisal (electronic register)',
      ],
      startupVisaPrograms: [],
      incubators: [
        BusinessIncubator(
          name: 'Impact Hub Bucharest',
          city: 'Bucharest',
          focus: 'Social enterprise, tech',
          immigrantFriendly: true,
          website: 'https://bucharest.impacthub.ro',
        ),
        BusinessIncubator(
          name: 'TechAngels Romania',
          city: 'Bucharest',
          focus: 'Angel investment network',
          immigrantFriendly: true,
          website: 'https://www.techangels.ro',
        ),
      ],
      governmentGrants: [
        'Start-Up Nation: grants up to RON 200,000 (~EUR 40,000)',
        'Minimis scheme for micro-enterprises',
        'Romania Startup Plus (EU-funded)',
        'POC/POCIDIF EU structural fund grants for innovation',
      ],
      businessAuthority: 'National Trade Register Office (ONRC)',
      businessAuthorityUrl: 'https://www.onrc.ro',
      businessAuthorityPhone: '+40 21 316 08 04',
    ),

    // -----------------------------------------------------------------------
    // 24. SLOVAKIA (SK)
    // -----------------------------------------------------------------------
    CountryBusinessGuide(
      country: 'Slovakia',
      countryCode: 'SK',
      immigrantsCanStartBusiness: true,
      immigrantBusinessSummary:
          'Non-EU nationals can register a company (s.r.o.) and apply for a temporary '
          'residence permit for business. Registration is straightforward and affordable.',
      permitRequirements: [
        'Temporary residence for business purposes',
        'Trade license (Živnostenské oprávnenie) obtainable by non-residents',
        'Proof of business activity and accommodation',
        'Health insurance mandatory',
        'EU citizens: register freely, obtain residence registration',
      ],
      companyTypes: [
        CompanyType(
          localName: 'Spoločnosť s ručením obmedzeným',
          englishName: 'Limited Liability Company',
          abbreviation: 's.r.o.',
          description: 'Most common company form',
          minimumCapital: 5000,
          capitalFullyPaidUpfront: false,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited to share capital',
          notes: [
            'EUR 5,000 minimum, each partner at least EUR 750',
            'At least 30% of cash contributions paid at formation',
          ],
        ),
        CompanyType(
          localName: 'Akciová spoločnosť',
          englishName: 'Joint Stock Company',
          abbreviation: 'a.s.',
          description: 'For larger enterprises',
          minimumCapital: 25000,
          capitalFullyPaidUpfront: false,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited to share capital',
        ),
        CompanyType(
          localName: 'SZČO (Samostatne zárobkovo činná osoba)',
          englishName: 'Self-Employed Person / Sole Trader',
          abbreviation: 'SZČO',
          description: 'Individual trade license holder',
          minimumCapital: 0,
          capitalFullyPaidUpfront: true,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Unlimited personal liability',
        ),
      ],
      registrationSteps: [
        '1. Obtain trade license from District Office (Okresný úrad)',
        '2. Draft articles of association (can be notarized)',
        '3. Open bank account and deposit capital',
        '4. File for registration at Commercial Register (Obchodný register)',
        '5. Receive IČO (company ID number)',
        '6. Register with Tax Office for tax and VAT',
        '7. Register with Social Insurance Agency (Sociálna poisťovňa)',
        '8. Register with health insurance company',
      ],
      registrationTimeline: '2-5 business days (electronic filing)',
      registrationCost:
          's.r.o.: ~EUR 300-600 (court fee EUR 150 electronic, trade license EUR 5/each, '
          'misc). SZČO: ~EUR 5-15.',
      taxInfo: TaxInfo(
        corporateTaxRate: 21.0,
        corporateTaxNotes: '15% for companies with turnover <EUR 49,790',
        vatStandardRate: 23.0,
        vatReducedRate: 10.0,
        vatRegistrationThreshold: 49790,
        incomeTaxRange: '19% (up to EUR 47,537) and 25% (above)',
        socialContributions:
            'Self-employed: ~33.15% of assessment base after first year. '
            'Employer: ~35.2% of gross salary',
        taxAuthority: 'Finančná správa SR (Financial Administration)',
        taxAuthorityUrl: 'https://www.financnasprava.sk',
      ),
      bankAccountRequirements: [
        'Company registration extract',
        'Trade license',
        'Passport/ID',
        'Slovak tax number',
        'Banks: Slovenská sporiteľňa, VÚB, Tatra banka',
      ],
      accountingObligations: [
        'All s.r.o.: double-entry bookkeeping',
        'SZČO: single-entry bookkeeping (flat-rate expenses option available)',
        'Annual financial statements filed with tax office and Commercial Register',
        'Monthly/quarterly VAT returns',
        'Corporate tax return by March 31 (extendable to June 30)',
      ],
      hiringRulesForForeignEmployers: [
        'Register with Social Insurance Agency within 8 days of hire',
        'Non-EU workers: work permit from Office of Labor',
        'Minimum wage: EUR 750/month (2026)',
        'Employer social contributions: ~35.2% of gross salary',
        'Written employment contract in Slovak required',
      ],
      startupVisaPrograms: [],
      incubators: [
        BusinessIncubator(
          name: 'Startup Campus Bratislava',
          city: 'Bratislava',
          focus: 'General startup support',
          immigrantFriendly: true,
          website: 'https://www.startupcampus.sk',
        ),
      ],
      governmentGrants: [
        'SBA (Slovak Business Agency): microloans and mentoring',
        'EU Structural Funds: Operational Programme Integrated Infrastructure',
        'Innovation vouchers via MH SR (Ministry of Economy)',
      ],
      businessAuthority: 'Commercial Register / Slovak Business Agency (SBA)',
      businessAuthorityUrl: 'https://www.sbagency.sk',
      businessAuthorityPhone: '+421 2 203 63 100',
    ),

    // -----------------------------------------------------------------------
    // 25. SLOVENIA (SI)
    // -----------------------------------------------------------------------
    CountryBusinessGuide(
      country: 'Slovenia',
      countryCode: 'SI',
      immigrantsCanStartBusiness: true,
      immigrantBusinessSummary:
          'Non-EU nationals can register a company (d.o.o.) and apply for a residence '
          'permit for self-employment. Registration is efficient through the e-VEM portal. '
          'Slovenia is well-positioned between Western and Eastern EU markets.',
      permitRequirements: [
        'Single permit (enotno dovoljenje) for self-employment',
        'Company can be registered first via e-VEM',
        'Proof of business activity, qualifications, accommodation',
        'Health insurance',
        'EU citizens: register freely',
      ],
      companyTypes: [
        CompanyType(
          localName: 'Družba z omejeno odgovornostjo',
          englishName: 'Limited Liability Company',
          abbreviation: 'd.o.o.',
          description: 'Most common company form',
          minimumCapital: 7500,
          capitalFullyPaidUpfront: false,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited to share capital',
          notes: [
            'EUR 7,500 minimum, each share at least EUR 50',
            'Can be formed via e-VEM one-stop-shop',
          ],
        ),
        CompanyType(
          localName: 'Delniška družba',
          englishName: 'Joint Stock Company',
          abbreviation: 'd.d.',
          description: 'For larger companies',
          minimumCapital: 25000,
          capitalFullyPaidUpfront: false,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited to share capital',
        ),
        CompanyType(
          localName: 'Samostojni podjetnik',
          englishName: 'Sole Proprietor',
          abbreviation: 's.p.',
          description: 'Individual entrepreneur',
          minimumCapital: 0,
          capitalFullyPaidUpfront: true,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Unlimited personal liability',
          notes: ['Registration via e-VEM portal, free of charge'],
        ),
      ],
      registrationSteps: [
        '1. Obtain Slovenian tax number (davčna številka) from FURS',
        '2. Register online via e-VEM portal (one-stop-shop)',
        '3. Choose company name (check with AJPES business register)',
        '4. Enter registration data and articles via e-VEM',
        '5. Receive registration in Court Register (Sodni register)',
        '6. Automatic tax and social insurance registration',
        '7. Open business bank account',
      ],
      registrationTimeline: '1-3 business days via e-VEM',
      registrationCost:
          'd.o.o. via e-VEM: FREE (no court or registration fees). '
          'With notary (traditional): ~EUR 500-1,000. s.p.: FREE.',
      taxInfo: TaxInfo(
        corporateTaxRate: 22.0,
        corporateTaxNotes: 'Flat 22%. Tax incentives for R&D (100% deduction of R&D costs)',
        vatStandardRate: 22.0,
        vatReducedRate: 9.5,
        vatRegistrationThreshold: 50000,
        incomeTaxRange: '16% (up to EUR 8,755) to 50% (over EUR 80,914)',
        socialContributions:
            'Self-employed: ~38.2% of insurance base. '
            'Employer: ~16.1%, Employee: ~22.1%',
        taxAuthority: 'Financial Administration (FURS)',
        taxAuthorityUrl: 'https://www.fu.gov.si',
      ),
      bankAccountRequirements: [
        'Slovenian tax number',
        'Company registration extract',
        'Passport/ID',
        'Banks: NLB, SKB, Nova KBM, Intesa Sanpaolo',
      ],
      accountingObligations: [
        'All d.o.o.: double-entry bookkeeping per Slovenian Accounting Standards',
        's.p.: simplified records (normirani odhodki: 80% flat expenses if <EUR 50,000 turnover)',
        'Annual financial statements filed with AJPES',
        'Monthly VAT returns (quarterly if <EUR 210,000)',
        'Corporate tax return by March 31',
        'Audit mandatory if 2 of 3: EUR 8.8M revenue, EUR 4.4M assets, 50 employees',
      ],
      hiringRulesForForeignEmployers: [
        'Register with FURS and ZZZS (health insurance)',
        'Non-EU workers: work permit from Employment Service (ZRSZ)',
        'Minimum wage: EUR 1,253/month gross (2026)',
        'Employer contributions: ~16.1% of gross salary',
        'Written employment contract required in Slovenian',
      ],
      startupVisaPrograms: [
        StartupVisaProgram(
          name: 'Slovenian Startup Visa (proposed)',
          description: 'Under development — check SPIRIT Slovenia for current programs',
          requirements: [
            'Check with SPIRIT Slovenia for latest requirements',
          ],
          validityPeriod: 'TBD',
          pathToResidence: true,
          officialUrl: 'https://www.spiritslovenia.si',
        ),
      ],
      incubators: [
        BusinessIncubator(
          name: 'Technology Park Ljubljana',
          city: 'Ljubljana',
          focus: 'Tech, deep tech',
          immigrantFriendly: true,
          website: 'https://www.tp-lj.si',
        ),
        BusinessIncubator(
          name: 'ABC Accelerator',
          city: 'Ljubljana',
          focus: 'International acceleration program',
          immigrantFriendly: true,
          website: 'https://abc-accelerator.com',
        ),
      ],
      governmentGrants: [
        'SPIRIT Slovenia: startup incentives and support',
        'Slovenian Enterprise Fund (SEF): startup grants up to EUR 54,000',
        'P2 program: seed money for innovative startups',
        'EU Cohesion Funds through SPIRIT',
      ],
      businessAuthority: 'AJPES (Agency for Public Legal Records) / SPIRIT Slovenia',
      businessAuthorityUrl: 'https://spot.gov.si',
      businessAuthorityPhone: '+386 1 583 66 00',
    ),

    // -----------------------------------------------------------------------
    // 26. SPAIN (ES)
    // -----------------------------------------------------------------------
    CountryBusinessGuide(
      country: 'Spain',
      countryCode: 'ES',
      immigrantsCanStartBusiness: true,
      immigrantBusinessSummary:
          'Non-EU nationals can apply for an entrepreneur visa (visado de emprendedor) '
          'under the Ley de Emprendedores (Entrepreneurs Law). Spain also has the highly '
          'popular Digital Nomad Visa and Autónomo (freelancer) registration.',
      permitRequirements: [
        'Entrepreneur visa (visado de emprendedor) for innovative business',
        'Self-employment visa (cuenta propia) for general business',
        'NIE (foreigner identity number) required for all business activity',
        'Digital Nomad Visa for remote workers',
        'EU citizens: NIE + registration at Social Security',
      ],
      companyTypes: [
        CompanyType(
          localName: 'Sociedad Limitada',
          englishName: 'Private Limited Company',
          abbreviation: 'S.L.',
          description: 'Most common business form in Spain',
          minimumCapital: 3000,
          capitalFullyPaidUpfront: true,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited to share capital',
          notes: [
            'EUR 3,000 fully paid up',
            'SLU = single-member S.L. (Sociedad Limitada Unipersonal)',
            'SLNE variant (Nueva Empresa): simplified template articles',
          ],
        ),
        CompanyType(
          localName: 'Sociedad Anónima',
          englishName: 'Public Limited Company',
          abbreviation: 'S.A.',
          description: 'For larger companies, shares freely tradeable',
          minimumCapital: 60000,
          capitalFullyPaidUpfront: false,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited to share capital',
          notes: ['25% paid up at formation'],
        ),
        CompanyType(
          localName: 'Autónomo (Trabajador por cuenta propia)',
          englishName: 'Self-Employed / Freelancer',
          abbreviation: 'Autónomo',
          description: 'Individual freelancer, very common in Spain',
          minimumCapital: 0,
          capitalFullyPaidUpfront: true,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Unlimited personal liability',
          notes: [
            'Tarifa plana: EUR 80/month Social Security for first 12 months',
            'Must register with Hacienda (tax) and Social Security (RETA)',
          ],
        ),
      ],
      registrationSteps: [
        '1. Obtain NIE (Número de Identificación de Extranjero)',
        '2. Obtain negative name certificate from Registro Mercantil Central',
        '3. Open bank account and deposit capital',
        '4. Draft articles of incorporation (escritura pública) before notary',
        '5. Obtain CIF (company tax number) from Hacienda',
        '6. Register with Registro Mercantil (Commercial Registry)',
        '7. Register for IAE (economic activity tax) with Hacienda',
        '8. Register with Social Security (RETA for autónomos)',
        '9. File alta censal (Form 036/037) with AEAT',
      ],
      registrationTimeline:
          'S.L. traditional: 2-4 weeks. PAE (one-stop-shop): 5-10 days. '
          'Autónomo: 1-2 days.',
      registrationCost:
          'S.L.: ~EUR 600-1,500 (notary ~EUR 300-500, registry ~EUR 150, '
          'name certificate EUR 13, misc). Autónomo: ~EUR 50-100.',
      taxInfo: TaxInfo(
        corporateTaxRate: 25.0,
        corporateTaxNotes:
            '25% standard. 15% for new companies in first 2 profitable years. '
            'Reduced rates in Canary Islands (4% ZEC regime).',
        vatStandardRate: 21.0,
        vatReducedRate: 10.0,
        vatRegistrationThreshold: 0,
        incomeTaxRange: '19% (up to EUR 12,450) to 47% (over EUR 300,000)',
        socialContributions:
            'Autónomo: income-based since 2023, EUR 230-500+/month depending on income. '
            'Tarifa plana: EUR 80/month first 12 months. '
            'Employer: ~30% of gross salary',
        taxAuthority: 'Agencia Tributaria (AEAT)',
        taxAuthorityUrl: 'https://www.agenciatributaria.es',
      ),
      bankAccountRequirements: [
        'NIE number',
        'Company deed (escritura)',
        'CIF (company tax number)',
        'Passport/ID of directors',
        'Banks: CaixaBank, BBVA, Santander, Sabadell',
        'Some banks offer foreigner-specific accounts',
      ],
      accountingObligations: [
        'All S.L.: double-entry bookkeeping per Plan General Contable',
        'Annual accounts (cuentas anuales) filed with Registro Mercantil',
        'Autónomos: simplified records (libro de ingresos/gastos)',
        'Quarterly VAT returns (Form 303)',
        'Quarterly income tax prepayment (Form 130/202)',
        'Annual corporate tax (Form 200) by July 25',
        'SII (electronic invoicing) mandatory for large companies',
      ],
      hiringRulesForForeignEmployers: [
        'Register as employer with Social Security (CCC code)',
        'Non-EU workers: work authorization (autorización de trabajo)',
        'Minimum wage (SMI): EUR 1,134/month (14 payments) in 2026',
        'Employer social security: ~30% of gross salary',
        'Written employment contract, register with SEPE within 10 days',
      ],
      startupVisaPrograms: [
        StartupVisaProgram(
          name: 'Spain Entrepreneur Visa (Ley de Emprendedores)',
          description: 'Residence authorization for innovative startup entrepreneurs',
          requirements: [
            'Innovative business project with special economic interest for Spain',
            'Favorable report from ENISA (public enterprise)',
            'Sufficient financial means',
            'Health insurance',
            'No criminal record',
          ],
          validityPeriod: '1 year, renewable for 2-year periods',
          pathToResidence: true,
          officialUrl: 'https://www.exteriores.gob.es',
        ),
        StartupVisaProgram(
          name: 'Spain Digital Nomad Visa',
          description: 'Residence for remote workers employed by foreign companies',
          requirements: [
            'Work remotely for a company outside Spain (or max 20% Spanish clients)',
            'Minimum income of EUR 2,646/month (200% of SMI)',
            'Professional experience or degree in relevant field',
            'Health insurance',
          ],
          validityPeriod: '3 years (if applied from Spain), 1 year + renewable (from abroad)',
          pathToResidence: true,
          officialUrl: 'https://www.inclusion.gob.es',
        ),
      ],
      incubators: [
        BusinessIncubator(
          name: 'Barcelona Activa',
          city: 'Barcelona',
          focus: 'Business incubation, public initiative',
          immigrantFriendly: true,
          website: 'https://www.barcelonactiva.cat',
        ),
        BusinessIncubator(
          name: 'Lanzadera',
          city: 'Valencia',
          focus: 'General acceleration, Juan Roig initiative',
          immigrantFriendly: true,
          website: 'https://lanzadera.es',
        ),
        BusinessIncubator(
          name: 'Google for Startups Campus Madrid',
          city: 'Madrid',
          focus: 'Tech, community',
          immigrantFriendly: true,
          website: 'https://campus.co/madrid',
        ),
      ],
      governmentGrants: [
        'ENISA loans: participative loans EUR 25,000-300,000 for startups',
        'ICO lines of credit for entrepreneurs',
        'CDTI grants for R&D projects',
        'Kit Digital: up to EUR 12,000 for digitalization',
        'Capitalización del desempleo: lump-sum unemployment for starting a business',
        'Regional incentives in Canary Islands, Basque Country, etc.',
      ],
      businessAuthority: 'Registro Mercantil / Ventanilla Única Empresarial',
      businessAuthorityUrl: 'https://www.ipyme.org',
      businessAuthorityPhone: '+34 900 150 000',
    ),

    // -----------------------------------------------------------------------
    // 27. SWEDEN (SE)
    // -----------------------------------------------------------------------
    CountryBusinessGuide(
      country: 'Sweden',
      countryCode: 'SE',
      immigrantsCanStartBusiness: true,
      immigrantBusinessSummary:
          'Non-EU nationals need a residence permit for self-employment from the Swedish '
          'Migration Agency (Migrationsverket). Must prove the business can sustain them '
          'financially for at least 2 years. Sweden has a highly digitized system.',
      permitRequirements: [
        'Residence permit for self-employment (egenföretagare) from Migrationsverket',
        'Must show business will provide sufficient income (>SEK 200,000/year)',
        'Relevant experience and sufficient capital to run the business',
        'Company must be registered with Bolagsverket',
        'EU citizens: register freely, get a coordination number or personnummer',
      ],
      companyTypes: [
        CompanyType(
          localName: 'Aktiebolag',
          englishName: 'Limited Liability Company',
          abbreviation: 'AB',
          description: 'Most common form for limited liability',
          minimumCapital: 25000,
          capitalFullyPaidUpfront: true,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Limited to share capital',
          notes: [
            'SEK 25,000 (~EUR 2,200) minimum share capital',
            'Registration online via verksamt.se',
            'Board member must be Swedish/EEA resident (or apply for exemption)',
          ],
        ),
        CompanyType(
          localName: 'Enskild firma',
          englishName: 'Sole Proprietorship',
          abbreviation: '-',
          description: 'Individual business, simplest form',
          minimumCapital: 0,
          capitalFullyPaidUpfront: true,
          minShareholders: 1,
          minDirectors: 1,
          liabilityType: 'Unlimited personal liability',
          notes: [
            'Requires Swedish personal number (personnummer) or coordination number',
            'F-tax (F-skatt) approval needed to invoice',
          ],
        ),
        CompanyType(
          localName: 'Handelsbolag',
          englishName: 'Trading Partnership',
          abbreviation: 'HB',
          description: 'Partnership, personal liability for all partners',
          minimumCapital: 0,
          capitalFullyPaidUpfront: true,
          minShareholders: 2,
          minDirectors: 0,
          liabilityType: 'Unlimited joint personal liability',
        ),
      ],
      registrationSteps: [
        '1. Register online via verksamt.se (one-stop portal)',
        '2. For AB: draft articles of association and memorandum of incorporation',
        '3. Open bank account, deposit share capital (AB)',
        '4. Submit registration to Bolagsverket (Swedish Companies Registration Office)',
        '5. Receive organization number (organisationsnummer)',
        '6. Apply for F-tax (F-skatt) with Skatteverket',
        '7. Register for VAT (moms) with Skatteverket',
        '8. Register as employer with Skatteverket if hiring',
      ],
      registrationTimeline:
          'AB: 1-2 weeks. Enskild firma: 2-3 business days online.',
      registrationCost:
          'AB: SEK 2,200 (~EUR 195) online, SEK 2,700 paper. '
          'Enskild firma: SEK 1,100 (~EUR 97). '
          'No notary fees required in Sweden.',
      taxInfo: TaxInfo(
        corporateTaxRate: 20.6,
        corporateTaxNotes: 'Flat 20.6%. One of the lower rates in Western/Northern EU.',
        vatStandardRate: 25.0,
        vatReducedRate: 12.0,
        vatRegistrationThreshold: 8000,
        incomeTaxRange: '~32% municipal tax + 20% state tax on income over SEK 598,500',
        socialContributions:
            'Self-employed: ~28.97% egenavgifter on profit. '
            'Employer: 31.42% arbetsgivaravgifter on gross salary',
        taxAuthority: 'Skatteverket (Swedish Tax Agency)',
        taxAuthorityUrl: 'https://www.skatteverket.se',
      ),
      bankAccountRequirements: [
        'Swedish personal number (personnummer) or coordination number',
        'Company registration certificate from Bolagsverket',
        'Passport/ID',
        'F-tax certificate',
        'Banks: Swedbank, SEB, Handelsbanken, Nordea',
        'Very difficult without personnummer — persistence needed',
      ],
      accountingObligations: [
        'All AB: double-entry bookkeeping (bokföringslagen)',
        'Enskild firma: simplified bookkeeping if <EUR 250,000 turnover',
        'Annual report (årsredovisning) filed with Bolagsverket for AB',
        'Monthly employer declarations (arbetsgivardeklaration) if employees',
        'VAT returns: monthly, quarterly, or annually',
        'Audit mandatory if 2 of 3: SEK 3M net revenue, SEK 1.5M assets, 3 employees',
      ],
      hiringRulesForForeignEmployers: [
        'Register as employer with Skatteverket',
        'Non-EU workers: work permit from Migrationsverket',
        'No statutory minimum wage; set by collective agreements',
        'Employer social fees (arbetsgivaravgifter): 31.42%',
        'Written employment terms within 1 month',
        'Collective agreements very common and influential',
      ],
      startupVisaPrograms: [
        StartupVisaProgram(
          name: 'Self-Employment Residence Permit',
          description: 'Residence permit for self-employed entrepreneurs from non-EU countries',
          requirements: [
            'Relevant experience in the business field',
            'Sufficient funds to support yourself and family for 2 years',
            'Business plan showing profitability within 2 years',
            'Company must be registered with Bolagsverket',
            'No language requirement but Swedish helps',
          ],
          validityPeriod: '2 years, renewable',
          pathToResidence: true,
          officialUrl: 'https://www.migrationsverket.se',
        ),
      ],
      incubators: [
        BusinessIncubator(
          name: 'Sting (Stockholm Innovation & Growth)',
          city: 'Stockholm',
          focus: 'Tech, deep tech',
          immigrantFriendly: true,
          website: 'https://www.sting.co',
        ),
        BusinessIncubator(
          name: 'Minc (Malmö Incubator)',
          city: 'Malmö',
          focus: 'Tech, social impact',
          immigrantFriendly: true,
          website: 'https://www.minc.se',
        ),
        BusinessIncubator(
          name: 'IUC Sverige / Almi',
          city: 'Multiple cities',
          focus: 'General business support, government backed',
          immigrantFriendly: true,
          website: 'https://www.almi.se',
        ),
      ],
      governmentGrants: [
        'Almi: startup loans up to SEK 250,000 (~EUR 22,000)',
        'Vinnova: innovation grants for R&D projects',
        'Starta eget-bidrag: startup grant from Arbetsförmedlingen for unemployed',
        'EU Structural Funds via Tillväxtverket',
        'Regional development grants',
      ],
      businessAuthority:
          'Bolagsverket (Swedish Companies Registration Office)',
      businessAuthorityUrl: 'https://bolagsverket.se',
      businessAuthorityPhone: '+46 771 670 670',
      additionalNotes: [
        'IFS (International Entrepreneur Association in Sweden) provides support in multiple languages',
        'Nyföretagarcentrum offers free startup advice including for immigrants',
        'Opening a bank account is the biggest practical challenge for non-EU entrepreneurs in Sweden',
      ],
    ),
  ];
}
