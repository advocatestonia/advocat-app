// Family Law Database for Immigrants in all 27 EU Countries
// Comprehensive legal data: marriage, divorce, custody, support, DV, Hague Convention
// Last updated: 2026-04
//
// Sources: Brussels IIter Regulation (2019/1111), EU Maintenance Regulation (4/2009),
// Hague Convention on Child Abduction 1980, Rome III Regulation (1259/2010),
// national family codes, HCCH country profiles, EU e-Justice Portal,
// European Judicial Network in civil and commercial matters.

class MarriageRequirements {
  final List<String> requiredDocuments;
  final int waitingPeriodDays;
  final int minimumAge;
  final bool foreignDivorceRecognized;
  final String registrationAuthority;
  final String legalBasis;
  final String notes;

  const MarriageRequirements({
    required this.requiredDocuments,
    required this.waitingPeriodDays,
    required this.minimumAge,
    required this.foreignDivorceRecognized,
    required this.registrationAuthority,
    required this.legalBasis,
    this.notes = '',
  });

  Map<String, dynamic> toMap() => {
    'requiredDocuments': requiredDocuments,
    'waitingPeriodDays': waitingPeriodDays,
    'minimumAge': minimumAge,
    'foreignDivorceRecognized': foreignDivorceRecognized,
    'registrationAuthority': registrationAuthority,
    'legalBasis': legalBasis,
    'notes': notes,
  };
}

class DivorceRules {
  final String jurisdiction;
  final String applicableLaw;
  final int minimumSeparationMonths;
  final bool mutualConsentAvailable;
  final String courtType;
  final String legalBasis;
  final String immigrantNotes;

  const DivorceRules({
    required this.jurisdiction,
    required this.applicableLaw,
    required this.minimumSeparationMonths,
    required this.mutualConsentAvailable,
    required this.courtType,
    required this.legalBasis,
    required this.immigrantNotes,
  });

  Map<String, dynamic> toMap() => {
    'jurisdiction': jurisdiction,
    'applicableLaw': applicableLaw,
    'minimumSeparationMonths': minimumSeparationMonths,
    'mutualConsentAvailable': mutualConsentAvailable,
    'courtType': courtType,
    'legalBasis': legalBasis,
    'immigrantNotes': immigrantNotes,
  };
}

class ChildCustodyRules {
  final String applicableLaw;
  final String defaultCustodyType;
  final String centralAuthority;
  final String hagueConventionStatus;
  final String relocationRules;
  final String legalBasis;
  final String immigrantNotes;

  const ChildCustodyRules({
    required this.applicableLaw,
    required this.defaultCustodyType,
    required this.centralAuthority,
    required this.hagueConventionStatus,
    required this.relocationRules,
    required this.legalBasis,
    required this.immigrantNotes,
  });

  Map<String, dynamic> toMap() => {
    'applicableLaw': applicableLaw,
    'defaultCustodyType': defaultCustodyType,
    'centralAuthority': centralAuthority,
    'hagueConventionStatus': hagueConventionStatus,
    'relocationRules': relocationRules,
    'legalBasis': legalBasis,
    'immigrantNotes': immigrantNotes,
  };
}

class ChildSupportRules {
  final String calculationMethod;
  final String enforcementMechanism;
  final String crossBorderEnforcement;
  final String centralAuthority;
  final String legalBasis;
  final String notes;

  const ChildSupportRules({
    required this.calculationMethod,
    required this.enforcementMechanism,
    required this.crossBorderEnforcement,
    required this.centralAuthority,
    required this.legalBasis,
    this.notes = '',
  });

  Map<String, dynamic> toMap() => {
    'calculationMethod': calculationMethod,
    'enforcementMechanism': enforcementMechanism,
    'crossBorderEnforcement': crossBorderEnforcement,
    'centralAuthority': centralAuthority,
    'legalBasis': legalBasis,
    'notes': notes,
  };
}

class DomesticViolenceProtection {
  final bool emergencyOrderAvailable;
  final int emergencyOrderMaxDays;
  final String protectionOrderCourt;
  final String shelterAccess;
  final String emergencyHotline;
  final bool availableToImmigrants;
  final String legalBasis;
  final String specialImmigrantProtections;

  const DomesticViolenceProtection({
    required this.emergencyOrderAvailable,
    required this.emergencyOrderMaxDays,
    required this.protectionOrderCourt,
    required this.shelterAccess,
    required this.emergencyHotline,
    required this.availableToImmigrants,
    required this.legalBasis,
    required this.specialImmigrantProtections,
  });

  Map<String, dynamic> toMap() => {
    'emergencyOrderAvailable': emergencyOrderAvailable,
    'emergencyOrderMaxDays': emergencyOrderMaxDays,
    'protectionOrderCourt': protectionOrderCourt,
    'shelterAccess': shelterAccess,
    'emergencyHotline': emergencyHotline,
    'availableToImmigrants': availableToImmigrants,
    'legalBasis': legalBasis,
    'specialImmigrantProtections': specialImmigrantProtections,
  };
}

class ParentalLeaveRights {
  final int maternityLeaveDays;
  final int paternityLeaveDays;
  final int parentalLeaveDays;
  final String payRate;
  final bool availableToImmigrants;
  final String residencyRequirement;
  final String legalBasis;

  const ParentalLeaveRights({
    required this.maternityLeaveDays,
    required this.paternityLeaveDays,
    required this.parentalLeaveDays,
    required this.payRate,
    required this.availableToImmigrants,
    required this.residencyRequirement,
    required this.legalBasis,
  });

  Map<String, dynamic> toMap() => {
    'maternityLeaveDays': maternityLeaveDays,
    'paternityLeaveDays': paternityLeaveDays,
    'parentalLeaveDays': parentalLeaveDays,
    'payRate': payRate,
    'availableToImmigrants': availableToImmigrants,
    'residencyRequirement': residencyRequirement,
    'legalBasis': legalBasis,
  };
}

class BirthRegistration {
  final int deadlineDays;
  final String registrationOffice;
  final List<String> requiredDocuments;
  final String citizenshipRule;
  final String legalBasis;
  final String immigrantNotes;

  const BirthRegistration({
    required this.deadlineDays,
    required this.registrationOffice,
    required this.requiredDocuments,
    required this.citizenshipRule,
    required this.legalBasis,
    required this.immigrantNotes,
  });

  Map<String, dynamic> toMap() => {
    'deadlineDays': deadlineDays,
    'registrationOffice': registrationOffice,
    'requiredDocuments': requiredDocuments,
    'citizenshipRule': citizenshipRule,
    'legalBasis': legalBasis,
    'immigrantNotes': immigrantNotes,
  };
}

class PaternityRecognition {
  final String method;
  final String legalBasis;
  final String contestationPeriod;
  final String immigrantNotes;

  const PaternityRecognition({
    required this.method,
    required this.legalBasis,
    required this.contestationPeriod,
    required this.immigrantNotes,
  });

  Map<String, dynamic> toMap() => {
    'method': method,
    'legalBasis': legalBasis,
    'contestationPeriod': contestationPeriod,
    'immigrantNotes': immigrantNotes,
  };
}

class GuardianshipMinors {
  final String authority;
  final String appointmentProcess;
  final String legalBasis;
  final String unaccompaniedMinorNotes;

  const GuardianshipMinors({
    required this.authority,
    required this.appointmentProcess,
    required this.legalBasis,
    required this.unaccompaniedMinorNotes,
  });

  Map<String, dynamic> toMap() => {
    'authority': authority,
    'appointmentProcess': appointmentProcess,
    'legalBasis': legalBasis,
    'unaccompaniedMinorNotes': unaccompaniedMinorNotes,
  };
}

class CountryFamilyLaw {
  final String country;
  final String countryCode;
  final MarriageRequirements marriage;
  final DivorceRules divorce;
  final ChildCustodyRules custody;
  final ChildSupportRules childSupport;
  final DomesticViolenceProtection domesticViolence;
  final ParentalLeaveRights parentalLeave;
  final BirthRegistration birthRegistration;
  final PaternityRecognition paternity;
  final GuardianshipMinors guardianship;
  final String brusselsIIterNotes;
  final String hagueAbductionNotes;
  final String emergencyContacts;

  const CountryFamilyLaw({
    required this.country,
    required this.countryCode,
    required this.marriage,
    required this.divorce,
    required this.custody,
    required this.childSupport,
    required this.domesticViolence,
    required this.parentalLeave,
    required this.birthRegistration,
    required this.paternity,
    required this.guardianship,
    this.brusselsIIterNotes = '',
    this.hagueAbductionNotes = '',
    this.emergencyContacts = '',
  });

  Map<String, dynamic> toMap() => {
    'country': country,
    'countryCode': countryCode,
    'marriage': marriage.toMap(),
    'divorce': divorce.toMap(),
    'custody': custody.toMap(),
    'childSupport': childSupport.toMap(),
    'domesticViolence': domesticViolence.toMap(),
    'parentalLeave': parentalLeave.toMap(),
    'birthRegistration': birthRegistration.toMap(),
    'paternity': paternity.toMap(),
    'guardianship': guardianship.toMap(),
    'brusselsIIterNotes': brusselsIIterNotes,
    'hagueAbductionNotes': hagueAbductionNotes,
    'emergencyContacts': emergencyContacts,
  };
}

class FamilyLawDatabase {
  static final FamilyLawDatabase _instance = FamilyLawDatabase._internal();
  factory FamilyLawDatabase() => _instance;
  FamilyLawDatabase._internal();

  CountryFamilyLaw? getCountry(String countryCode) {
    return allCountries.where((c) => c.countryCode == countryCode).firstOrNull;
  }

  CountryFamilyLaw? getCountryByName(String name) {
    return allCountries
        .where((c) => c.country.toLowerCase() == name.toLowerCase())
        .firstOrNull;
  }

  List<CountryFamilyLaw> searchByTopic(String topic) {
    final t = topic.toLowerCase();
    return allCountries.where((c) {
      final map = c.toMap();
      return map.values.any((v) =>
          v.toString().toLowerCase().contains(t));
    }).toList();
  }

  // ─── EU-WIDE LEGAL FRAMEWORK ───────────────────────────────────────

  static const String brusselsIIterOverview = '''
Brussels IIter Regulation (EU 2019/1111) — effective 1 August 2022:
- Replaces Brussels IIa (2201/2003)
- Covers jurisdiction, recognition and enforcement of decisions on
  divorce, legal separation, marriage annulment, parental responsibility
- Automatic recognition of judgments across EU (no exequatur needed)
- Enhanced child abduction return procedures (6-week deadline per instance)
- Mandatory hearing of the child if capable of forming own views
- Privileged enforcement of access/contact rights
- Central Authority cooperation obligations
- Applies in all EU Member States except Denmark
''';

  static const String hagueConventionOverview = '''
Hague Convention on the Civil Aspects of International Child Abduction (1980):
- All 27 EU Member States are contracting parties
- Wrongful removal or retention of child under 16
- Prompt return to habitual residence (within 6 weeks target)
- Central Authority in each state handles applications
- Exceptions: grave risk of harm, child objects (if mature), settled in new environment (>1 year)
- Brussels IIter overrides between EU states with stricter rules
''';

  static const String maintenanceRegulationOverview = '''
EU Maintenance Regulation (4/2009):
- Cross-border enforcement of maintenance obligations (child support, alimony)
- Direct enforcement in other EU states without declaration of enforceability
- Applicable law determined by Hague Protocol 2007
- Central Authorities assist with cross-border recovery
- Applies in all EU states except Denmark (separate agreement)
''';

  // ─── ALL 27 EU COUNTRIES ───────────────────────────────────────────

  static const List<CountryFamilyLaw> allCountries = [

    // ═══════════════════════════════════════════════════════════════════
    // 1. AUSTRIA (AT)
    // ═══════════════════════════════════════════════════════════════════
    CountryFamilyLaw(
      country: 'Austria',
      countryCode: 'AT',
      marriage: MarriageRequirements(
        requiredDocuments: [
          'Valid passport',
          'Birth certificate (apostilled)',
          'Certificate of no impediment (Ehefähigkeitszeugnis) from home country',
          'Proof of dissolution of prior marriage if applicable',
          'Residence registration (Meldezettel)',
        ],
        waitingPeriodDays: 14,
        minimumAge: 18,
        foreignDivorceRecognized: true,
        registrationAuthority: 'Standesamt (Registry Office)',
        legalBasis: 'Austrian Marriage Act (Ehegesetz, EheG)',
        notes: 'Documents must be translated by certified translator. Apostille or superlegalization required. No impediment certificate valid 6 months.',
      ),
      divorce: DivorceRules(
        jurisdiction: 'Habitual residence of respondent, or last common habitual residence if applicant still lives there',
        applicableLaw: 'Rome III: spouses may choose law; default is law of common habitual residence',
        minimumSeparationMonths: 6,
        mutualConsentAvailable: true,
        courtType: 'Bezirksgericht (District Court)',
        legalBasis: 'EheG §§49-55a; Rome III Regulation 1259/2010',
        immigrantNotes: 'Immigrants can file for divorce if habitually resident in Austria for at least 1 year. Mutual consent divorce possible after 6 months separation. Court can apply foreign law if Rome III directs.',
      ),
      custody: ChildCustodyRules(
        applicableLaw: 'Law of child habitual residence (Brussels IIter / Hague 1996)',
        defaultCustodyType: 'Joint custody (Obsorge) if parents were married; mother sole custody if unmarried unless father recognized',
        centralAuthority: 'Federal Ministry of Justice (Bundesministerium für Justiz)',
        hagueConventionStatus: 'Party since 1988',
        relocationRules: 'Both parents must consent to relocation abroad; court permission required if no agreement',
        legalBasis: 'ABGB §§137-186; KindNamRÄG 2013',
        immigrantNotes: 'Child welfare (Kindeswohl) paramount. Language interpreter provided in court. Custody not linked to immigration status.',
      ),
      childSupport: ChildSupportRules(
        calculationMethod: 'Percentage of net income based on child age: 0-5 yrs 16%, 6-9 yrs 18%, 10-14 yrs 20%, 15+ yrs 22%. Reduced for multiple children.',
        enforcementMechanism: 'Court orders, wage garnishment, Unterhaltsvorschuss (state advance payments)',
        crossBorderEnforcement: 'EU Maintenance Regulation 4/2009; Hague Maintenance Convention 2007',
        centralAuthority: 'Federal Ministry of Justice',
        legalBasis: 'ABGB §§231-234; UVG (Unterhaltsvorschussgesetz)',
        notes: 'State advances maintenance if debtor fails to pay. Applies regardless of immigration status of child.',
      ),
      domesticViolence: DomesticViolenceProtection(
        emergencyOrderAvailable: true,
        emergencyOrderMaxDays: 14,
        protectionOrderCourt: 'Bezirksgericht issues interim injunction (Einstweilige Verfügung) up to 6 months',
        shelterAccess: 'Frauenhäuser (women shelters) available regardless of immigration status',
        emergencyHotline: 'Frauenhelpline: 0800 222 555 (24/7, free, multilingual)',
        availableToImmigrants: true,
        legalBasis: 'Gewaltschutzgesetz (Protection Against Violence Act) 1997, amended 2019',
        specialImmigrantProtections: 'Police can issue Betretungs- und Annäherungsverbot (barring and approach ban) for 14 days. DV victims may obtain independent residence permit. Shelter access regardless of status.',
      ),
      parentalLeave: ParentalLeaveRights(
        maternityLeaveDays: 112,
        paternityLeaveDays: 31,
        parentalLeaveDays: 730,
        payRate: 'Kinderbetreuungsgeld: flat rate €14.53/day or income-dependent 80% up to €69.83/day',
        availableToImmigrants: true,
        residencyRequirement: 'Legal residence in Austria and living with child',
        legalBasis: 'MSchG (Maternity Protection Act); VKG (Paternal Leave Act); KBGG (Childcare Allowance Act)',
      ),
      birthRegistration: BirthRegistration(
        deadlineDays: 7,
        registrationOffice: 'Standesamt where birth occurred',
        requiredDocuments: [
          'Hospital birth notification',
          'Parents passports',
          'Marriage certificate (if married)',
          'Birth certificates of parents',
          'Meldezettel (registration)',
        ],
        citizenshipRule: 'Ius sanguinis: child gets Austrian citizenship only if at least one parent is Austrian citizen',
        legalBasis: 'Personenstandsgesetz (PStG)',
        immigrantNotes: 'Children of immigrants registered normally. Child receives parents nationality. Austrian citizenship possible after parents naturalize.',
      ),
      paternity: PaternityRecognition(
        method: 'Voluntary acknowledgment at Standesamt or court; or judicial determination',
        legalBasis: 'ABGB §§144-163',
        contestationPeriod: 'Father or child may contest within 2 years of learning of circumstances',
        immigrantNotes: 'Foreign paternity acknowledgment recognized if valid under law of child habitual residence or parents national law.',
      ),
      guardianship: GuardianshipMinors(
        authority: 'Bezirksgericht (District Court)',
        appointmentProcess: 'Court appoints guardian (Kinder- und Jugendhilfeträger or individual). Youth welfare office acts as interim guardian.',
        legalBasis: 'ABGB §§207-209; Kinder- und Jugendhilfegesetz',
        unaccompaniedMinorNotes: 'Youth welfare office (Kinder- und Jugendhilfe) automatically becomes legal guardian. Separate qualified person assigned. Best interest standard applies regardless of immigration status.',
      ),
      hagueAbductionNotes: 'Central Authority: Federal Ministry of Justice, Museumstrasse 7, 1070 Wien. Return applications processed through Bezirksgericht. 6-week target per instance.',
      emergencyContacts: 'Police: 133; Emergency: 112; Women helpline: 0800 222 555; Child helpline: 147 (Rat auf Draht)',
    ),

    // ═══════════════════════════════════════════════════════════════════
    // 2. BELGIUM (BE)
    // ═══════════════════════════════════════════════════════════════════
    CountryFamilyLaw(
      country: 'Belgium',
      countryCode: 'BE',
      marriage: MarriageRequirements(
        requiredDocuments: [
          'Valid passport or ID',
          'Birth certificate (max 6 months old)',
          'Certificate of no impediment or sworn declaration',
          'Proof of residence in Belgium',
          'Proof of legal stay',
          'Divorce/death certificate of prior spouse if applicable',
        ],
        waitingPeriodDays: 14,
        minimumAge: 18,
        foreignDivorceRecognized: true,
        registrationAuthority: 'Commune / Gemeente (Municipal Registry)',
        legalBasis: 'Belgian Civil Code Art. 63-76',
        notes: 'Municipality investigates sham marriages. 14-day publication period. All documents need sworn translation into French, Dutch, or German.',
      ),
      divorce: DivorceRules(
        jurisdiction: 'Brussels IIter rules; habitual residence of respondent or common residence',
        applicableLaw: 'Rome III: parties can choose; default law of last common habitual residence',
        minimumSeparationMonths: 6,
        mutualConsentAvailable: true,
        courtType: 'Tribunal de la famille / Familierechtbank (Family Court)',
        legalBasis: 'Belgian Civil Code Art. 229-231; Code of Private International Law 2004',
        immigrantNotes: 'Court applies Rome III to determine applicable law. Mutual consent: 6 months separation. Irretrievable breakdown: no minimum if fault-based, 1 year separation otherwise.',
      ),
      custody: ChildCustodyRules(
        applicableLaw: 'Law of child habitual residence per Brussels IIter',
        defaultCustodyType: 'Joint parental authority (autorité parentale conjointe / gezamenlijk ouderlijk gezag) presumed',
        centralAuthority: 'SPF Justice / FOD Justitie — Direction générale de la Législation',
        hagueConventionStatus: 'Party since 1999',
        relocationRules: 'Relocation abroad requires consent of both parents or court authorization; specific rules in Civil Code',
        legalBasis: 'Civil Code Art. 373-374; Loi du 18 juillet 2006 on equal custody',
        immigrantNotes: 'Belgian courts have jurisdiction if child habitually resident in Belgium. Equal/alternating residence (hébergement égalitaire) strongly favored since 2006.',
      ),
      childSupport: ChildSupportRules(
        calculationMethod: 'Based on needs of child and means of both parents; Objectified calculation method (méthode Renard) widely used by courts',
        enforcementMechanism: 'SECAL/DAVO (Service des créances alimentaires) collects and advances maintenance payments',
        crossBorderEnforcement: 'EU Maintenance Regulation 4/2009; SECAL/DAVO acts as Central Authority',
        centralAuthority: 'SECAL/DAVO, SPF Finances',
        legalBasis: 'Civil Code Art. 203, 203bis; Loi SECAL 2003',
        notes: 'SECAL advances up to €175/month per child if debtor defaults. Available to all residents regardless of nationality.',
      ),
      domesticViolence: DomesticViolenceProtection(
        emergencyOrderAvailable: true,
        emergencyOrderMaxDays: 14,
        protectionOrderCourt: 'Justice de paix / Vrederechter issues temporary residence ban; Family Court for longer orders',
        shelterAccess: 'Refuges/vluchhuizen available regardless of immigration status',
        emergencyHotline: 'Ecoute violences conjugales: 0800 30 030 (FR); 1712 (NL)',
        availableToImmigrants: true,
        legalBasis: 'Loi du 15 mai 2012 on temporary residence ban; Criminal Code Art. 398-410',
        specialImmigrantProtections: 'DV victims can obtain autonomous residence permit under Immigration Act Art. 11§2. Prosecutor can order eviction of abuser. Specific protection for undocumented victims.',
      ),
      parentalLeave: ParentalLeaveRights(
        maternityLeaveDays: 105,
        paternityLeaveDays: 20,
        parentalLeaveDays: 120,
        payRate: 'Maternity: 82% first 30 days, 75% thereafter (capped). Parental leave: flat rate ~€850/month full-time.',
        availableToImmigrants: true,
        residencyRequirement: 'Employed or self-employed in Belgium with social security coverage',
        legalBasis: 'Loi sur le travail 1971 Art. 39; AR 29 Oct 1997 on parental leave',
      ),
      birthRegistration: BirthRegistration(
        deadlineDays: 15,
        registrationOffice: 'Commune / Gemeente where birth occurred',
        requiredDocuments: [
          'Medical birth certificate',
          'Parents identity documents',
          'Marriage certificate if applicable',
          'Acknowledgment of paternity if unmarried',
        ],
        citizenshipRule: 'Ius sanguinis primarily; ius soli if child would be stateless, or born to parent born in Belgium',
        legalBasis: 'Civil Code Art. 55-62',
        immigrantNotes: 'All births on Belgian territory must be registered. Third-generation ius soli: child born in Belgium to parent born in Belgium automatically Belgian.',
      ),
      paternity: PaternityRecognition(
        method: 'Automatic if married (presumption); voluntary acknowledgment before civil registrar; judicial establishment',
        legalBasis: 'Civil Code Art. 315-331',
        contestationPeriod: '1 year from discovery for husband; 1 year for mother; no limit for child',
        immigrantNotes: 'Municipality may investigate acknowledgments to prevent fraud/immigration abuse. Sincere acknowledgment required.',
      ),
      guardianship: GuardianshipMinors(
        authority: 'Tribunal de la famille / Familierechtbank',
        appointmentProcess: 'Court appoints guardian; Tutelles/Voogdij service oversees. For unaccompanied minors: dedicated guardianship service.',
        legalBasis: 'Civil Code Art. 389-426; Loi-programme du 24 décembre 2002 (Title XIII guardianship UAM)',
        unaccompaniedMinorNotes: 'Dedicated guardianship service (Service des Tutelles/Dienst Voogdij) under SPF Justice. Guardian appointed within days. Guardian manages legal representation, welfare, education, asylum procedure.',
      ),
      hagueAbductionNotes: 'Central Authority: SPF Justice, Direction générale de la Législation. Applications through Family Court. Belgium has dedicated child abduction judges.',
      emergencyContacts: 'Police: 101; Emergency: 112; DV French: 0800 30 030; DV Dutch: 1712; Child abuse: 103 (NL) / 0800 95 580 (FR)',
    ),

    // ═══════════════════════════════════════════════════════════════════
    // 3. BULGARIA (BG)
    // ═══════════════════════════════════════════════════════════════════
    CountryFamilyLaw(
      country: 'Bulgaria',
      countryCode: 'BG',
      marriage: MarriageRequirements(
        requiredDocuments: [
          'Valid passport',
          'Birth certificate (apostilled, translated)',
          'Declaration of marital status from home country',
          'Medical certificate',
          'Proof of legal residence',
        ],
        waitingPeriodDays: 30,
        minimumAge: 18,
        foreignDivorceRecognized: true,
        registrationAuthority: 'Municipal civil status office (ГРАО)',
        legalBasis: 'Family Code (Семеен кодекс) 2009, Art. 4-12',
        notes: 'Civil marriage only has legal effect. Religious marriage has no legal standing. 16-year-olds may marry with court permission.',
      ),
      divorce: DivorceRules(
        jurisdiction: 'Habitual residence of respondent or last common habitual residence',
        applicableLaw: 'Rome III applicable; default: common nationality, then habitual residence',
        minimumSeparationMonths: 0,
        mutualConsentAvailable: true,
        courtType: 'Rayonen sad (District Court)',
        legalBasis: 'Family Code Art. 49-58; Rome III Regulation',
        immigrantNotes: 'Mutual consent divorce: no separation required, single hearing possible. Contested: court examines irretrievable breakdown. No fault requirement.',
      ),
      custody: ChildCustodyRules(
        applicableLaw: 'Law of child habitual residence per Brussels IIter',
        defaultCustodyType: 'Joint parental rights during marriage; court decides after divorce (one parent typically receives primary custody)',
        centralAuthority: 'Ministry of Justice, International Legal Cooperation Directorate',
        hagueConventionStatus: 'Party since 2003',
        relocationRules: 'Consent of both parents needed; court decides disputes',
        legalBasis: 'Family Code Art. 59, 68-79; Child Protection Act',
        immigrantNotes: 'Best interest of child paramount. Social services report required in custody disputes. Free legal aid available for low-income immigrants.',
      ),
      childSupport: ChildSupportRules(
        calculationMethod: 'Court discretion based on needs of child and means of parent; no fixed formula',
        enforcementMechanism: 'Court enforcement, wage garnishment, criminal liability for non-payment',
        crossBorderEnforcement: 'EU Maintenance Regulation 4/2009',
        centralAuthority: 'Ministry of Justice',
        legalBasis: 'Family Code Art. 142-152',
        notes: 'Support obligations extend to age 18, or 20 if in education. State does not advance maintenance payments.',
      ),
      domesticViolence: DomesticViolenceProtection(
        emergencyOrderAvailable: true,
        emergencyOrderMaxDays: 30,
        protectionOrderCourt: 'Rayonen sad issues protection order within 30 days; emergency order within 24 hours',
        shelterAccess: 'Crisis centers available; limited capacity; NGOs provide additional shelters',
        emergencyHotline: '02 981 76 86 (Animus Foundation); 116 111 (child helpline)',
        availableToImmigrants: true,
        legalBasis: 'Protection Against Domestic Violence Act 2005 (amended 2019, 2023)',
        specialImmigrantProtections: 'Protection orders available regardless of immigration status. No requirement for legal stay to receive protection order.',
      ),
      parentalLeave: ParentalLeaveRights(
        maternityLeaveDays: 410,
        paternityLeaveDays: 15,
        parentalLeaveDays: 180,
        payRate: 'Maternity: 90% of income for 410 days. Paternity: 90% for 15 days. Additional parental leave: minimum wage rate.',
        availableToImmigrants: true,
        residencyRequirement: 'Must be socially insured with at least 12 months of insurance',
        legalBasis: 'Labour Code Art. 163-167; Social Insurance Code',
      ),
      birthRegistration: BirthRegistration(
        deadlineDays: 7,
        registrationOffice: 'Municipal civil registration office where birth occurred',
        requiredDocuments: [
          'Hospital birth certificate',
          'Parents identity documents',
          'Marriage certificate if applicable',
        ],
        citizenshipRule: 'Ius sanguinis: child is Bulgarian if at least one parent is Bulgarian citizen',
        legalBasis: 'Civil Registration Act Art. 36-43',
        immigrantNotes: 'All births must be registered regardless of parents status. Child of non-Bulgarian parents receives parents nationality.',
      ),
      paternity: PaternityRecognition(
        method: 'Presumption if married; voluntary acknowledgment; judicial establishment',
        legalBasis: 'Family Code Art. 61-67',
        contestationPeriod: 'Husband: 1 year from birth. Mother: 1 year from birth. Child: unlimited until age 21.',
        immigrantNotes: 'Foreign paternity acknowledgment recognized if compliant with Bulgarian public order.',
      ),
      guardianship: GuardianshipMinors(
        authority: 'Rayonen sad (District Court); Municipal social services',
        appointmentProcess: 'Court appoints guardian upon proposal by social services. Guardianship council may be formed.',
        legalBasis: 'Family Code Art. 153-174; Child Protection Act',
        unaccompaniedMinorNotes: 'State Agency for Refugees provides interim care. Municipal social services department assumes guardian role. Dedicated accommodation in specialized centers.',
      ),
      hagueAbductionNotes: 'Central Authority: Ministry of Justice, International Legal Cooperation Directorate, 1 Slavyanska Str., 1040 Sofia.',
      emergencyContacts: 'Police: 166; Emergency: 112; DV hotline: 02 981 76 86; Child line: 116 111',
    ),

    // ═══════════════════════════════════════════════════════════════════
    // 4. CROATIA (HR)
    // ═══════════════════════════════════════════════════════════════════
    CountryFamilyLaw(
      country: 'Croatia',
      countryCode: 'HR',
      marriage: MarriageRequirements(
        requiredDocuments: [
          'Valid passport',
          'Birth certificate (apostilled)',
          'Certificate of no impediment (potvrda o slobodnom bračnom stanju)',
          'Proof of legal residence',
          'Divorce/death decree if previously married',
        ],
        waitingPeriodDays: 30,
        minimumAge: 18,
        foreignDivorceRecognized: true,
        registrationAuthority: 'Matičar (Civil Registrar) at local office',
        legalBasis: 'Family Act (Obiteljski zakon) 2015, Art. 22-37',
        notes: 'Extra-marital partnership (izvanbračna zajednica) of 3+ years has same property rights as marriage.',
      ),
      divorce: DivorceRules(
        jurisdiction: 'Brussels IIter rules; habitual residence of parties',
        applicableLaw: 'Rome III: party autonomy; default law of common habitual residence',
        minimumSeparationMonths: 0,
        mutualConsentAvailable: true,
        courtType: 'Općinski sud (Municipal Court)',
        legalBasis: 'Family Act 2015 Art. 50-56; Rome III',
        immigrantNotes: 'Mutual consent divorce through court or notarial if no children. Mandatory mediation before contested divorce. Counseling at Social Welfare Center required.',
      ),
      custody: ChildCustodyRules(
        applicableLaw: 'Law of child habitual residence',
        defaultCustodyType: 'Joint parental care; both parents equal. After divorce: joint or sole by agreement or court decision.',
        centralAuthority: 'Ministry of Labour, Pension System, Family and Social Policy',
        hagueConventionStatus: 'Party since 1991 (succession from Yugoslavia)',
        relocationRules: 'Consent of both parents required for international relocation; Social Welfare Center mediates',
        legalBasis: 'Family Act Art. 91-117',
        immigrantNotes: 'Social Welfare Center (Centar za socijalnu skrb) plays major role in custody decisions. Mandatory participation in family mediation.',
      ),
      childSupport: ChildSupportRules(
        calculationMethod: 'Court discretion; minimum 17% of average net salary for one child; table guidelines exist',
        enforcementMechanism: 'Court enforcement, wage garnishment; criminal offense for persistent non-payment',
        crossBorderEnforcement: 'EU Maintenance Regulation 4/2009',
        centralAuthority: 'Ministry of Labour, Pension System, Family and Social Policy',
        legalBasis: 'Family Act Art. 283-312',
        notes: 'Temporary maintenance from Social Welfare Center if parent fails to pay (up to average amount). Child support until 18, or 26 if in education.',
      ),
      domesticViolence: DomesticViolenceProtection(
        emergencyOrderAvailable: true,
        emergencyOrderMaxDays: 30,
        protectionOrderCourt: 'Municipal Court issues protection measures; police can issue emergency eviction',
        shelterAccess: 'Women shelters (skloništa) available; government funded',
        emergencyHotline: '0800 655 222 (SOS telefon za žene); 116 006 (victim support)',
        availableToImmigrants: true,
        legalBasis: 'Protection Against Domestic Violence Act (Zakon o zaštiti od nasilja u obitelji) 2017',
        specialImmigrantProtections: 'Protection measures apply regardless of residence status. DV victims may receive temporary residence permit. Free legal aid for victims.',
      ),
      parentalLeave: ParentalLeaveRights(
        maternityLeaveDays: 98,
        paternityLeaveDays: 10,
        parentalLeaveDays: 240,
        payRate: 'Maternity: 100% of base salary. Parental leave first 6 months: 100% capped; remaining: flat rate.',
        availableToImmigrants: true,
        residencyRequirement: 'Must be insured under Croatian health/social insurance',
        legalBasis: 'Maternity and Parental Benefits Act 2022',
      ),
      birthRegistration: BirthRegistration(
        deadlineDays: 15,
        registrationOffice: 'Matični ured (Civil Registry Office) where birth occurred',
        requiredDocuments: [
          'Hospital birth notification',
          'Parents identity documents',
          'Marriage certificate if applicable',
        ],
        citizenshipRule: 'Ius sanguinis: Croatian citizenship if at least one parent is Croatian',
        legalBasis: 'Civil Registry Act; Croatian Citizenship Act',
        immigrantNotes: 'All births registered regardless of parents status. Child of non-Croatian parents gets parents nationality.',
      ),
      paternity: PaternityRecognition(
        method: 'Married father: automatic presumption. Unmarried: voluntary acknowledgment at registry or court. Judicial paternity establishment.',
        legalBasis: 'Family Act Art. 58-73',
        contestationPeriod: 'Husband: 6 months from learning of birth. Mother: 6 months. Child: unlimited.',
        immigrantNotes: 'Foreign paternity recognition accepted if valid under applicable foreign law and not contrary to Croatian public order.',
      ),
      guardianship: GuardianshipMinors(
        authority: 'Social Welfare Center (Centar za socijalnu skrb); Municipal Court',
        appointmentProcess: 'Social Welfare Center proposes guardian; court confirms. Center may act as temporary guardian.',
        legalBasis: 'Family Act Art. 218-246',
        unaccompaniedMinorNotes: 'Social Welfare Center appoints special guardian immediately. Accommodation in specialized institutions or foster care. Guardian represents minor in asylum proceedings.',
      ),
      hagueAbductionNotes: 'Central Authority: Ministry of Labour, Pension System, Family and Social Policy, Ulica grada Vukovara 78, 10000 Zagreb.',
      emergencyContacts: 'Police: 192; Emergency: 112; SOS women: 0800 655 222; Child helpline: 116 111',
    ),

    // ═══════════════════════════════════════════════════════════════════
    // 5. CYPRUS (CY)
    // ═══════════════════════════════════════════════════════════════════
    CountryFamilyLaw(
      country: 'Cyprus',
      countryCode: 'CY',
      marriage: MarriageRequirements(
        requiredDocuments: [
          'Valid passport',
          'Birth certificate',
          'Certificate of no impediment or statutory declaration',
          'Divorce decree if applicable (apostilled)',
          'Proof of address in Cyprus',
        ],
        waitingPeriodDays: 15,
        minimumAge: 18,
        foreignDivorceRecognized: true,
        registrationAuthority: 'Municipal Marriage Officer or licensed religious authority',
        legalBasis: 'Marriage Law Cap. 279; Civil Marriage Law 2003 (Law 104(I)/2003)',
        notes: 'Both civil and religious marriages recognized. No residency requirement to marry. Popular destination for quick marriages.',
      ),
      divorce: DivorceRules(
        jurisdiction: 'Family Court; Brussels IIter rules for jurisdiction',
        applicableLaw: 'Cyprus does not participate in Rome III (enhanced cooperation). Cypriot law typically applied.',
        minimumSeparationMonths: 24,
        mutualConsentAvailable: true,
        courtType: 'Oikogeneiako Dikastirio (Family Court)',
        legalBasis: 'Divorce (General Provisions) Law 1990 (Law 21/90)',
        immigrantNotes: 'Two-year separation required for no-fault divorce. Shorter if fault grounds (adultery, cruelty, desertion). Cyprus applies its own law, not Rome III.',
      ),
      custody: ChildCustodyRules(
        applicableLaw: 'Law of child habitual residence; Cypriot family law if child resident in Cyprus',
        defaultCustodyType: 'Joint parental responsibility during marriage; court awards custody post-divorce, typically to mother for young children',
        centralAuthority: 'Ministry of Justice and Public Order',
        hagueConventionStatus: 'Party since 1994',
        relocationRules: 'Permission of both parents or court order required',
        legalBasis: 'Relations of Parents and Children Law (Law 216/90); Children Law Cap. 352',
        immigrantNotes: 'Best interest of child standard applied. Welfare officer report prepared for court. Court can hear child views.',
      ),
      childSupport: ChildSupportRules(
        calculationMethod: 'Court discretion based on means and needs; no formula',
        enforcementMechanism: 'Court order enforcement; contempt of court for non-compliance; wage attachment',
        crossBorderEnforcement: 'EU Maintenance Regulation 4/2009',
        centralAuthority: 'Ministry of Justice and Public Order',
        legalBasis: 'Relations of Parents and Children Law; Maintenance and Support Law',
        notes: 'Support until 18, or 23 if in full-time education. Social welfare may provide assistance if support not paid.',
      ),
      domesticViolence: DomesticViolenceProtection(
        emergencyOrderAvailable: true,
        emergencyOrderMaxDays: 8,
        protectionOrderCourt: 'Family Court or District Court issues restraining orders',
        shelterAccess: 'State and NGO shelters available; Association for Prevention and Handling of Violence in the Family',
        emergencyHotline: '1440 (DV hotline); 116 000 (missing children)',
        availableToImmigrants: true,
        legalBasis: 'Violence in the Family (Prevention and Protection of Victims) Laws 2000-2015',
        specialImmigrantProtections: 'Protection available regardless of immigration status. DV victims may obtain independent residence status. Police trained in DV response.',
      ),
      parentalLeave: ParentalLeaveRights(
        maternityLeaveDays: 126,
        paternityLeaveDays: 14,
        parentalLeaveDays: 126,
        payRate: 'Maternity: 72% of insurable earnings. Paternity: 72%. Parental leave: unpaid (but eligible for state parental allowance).',
        availableToImmigrants: true,
        residencyRequirement: 'Must be insured under Social Insurance Scheme with sufficient contributions',
        legalBasis: 'Maternity Protection Law 1997; Parental Leave Law 2012; Paternity Leave Law 2017',
      ),
      birthRegistration: BirthRegistration(
        deadlineDays: 15,
        registrationOffice: 'District Administration Office (Civil Registry)',
        requiredDocuments: [
          'Hospital birth notification',
          'Parents passports/IDs',
          'Marriage certificate',
          'Residence permits if applicable',
        ],
        citizenshipRule: 'Ius sanguinis: Cypriot citizenship if father (or mother since 1999) is Cypriot citizen',
        legalBasis: 'Civil Registry Laws; Citizenship Law',
        immigrantNotes: 'Registration mandatory. Non-citizen children registered with parents nationality noted.',
      ),
      paternity: PaternityRecognition(
        method: 'Presumption if married; voluntary declaration; court order',
        legalBasis: 'Relations of Parents and Children Law 216/90',
        contestationPeriod: '3 years from birth or discovery',
        immigrantNotes: 'DNA testing available through court order. Foreign paternity declarations recognized.',
      ),
      guardianship: GuardianshipMinors(
        authority: 'Family Court; Social Welfare Services',
        appointmentProcess: 'Court appoints guardian on application by Social Welfare Services or interested party',
        legalBasis: 'Children Law Cap. 352; Refugee Law 2000',
        unaccompaniedMinorNotes: 'Director of Social Welfare Services acts as temporary guardian. Placed in reception centers or foster care. Commissioner for Childrens Rights oversees welfare.',
      ),
      hagueAbductionNotes: 'Central Authority: Ministry of Justice and Public Order, Athalassas Avenue 125, 1461 Nicosia.',
      emergencyContacts: 'Police: 199; Emergency: 112; DV hotline: 1440; Child helpline: 116 111',
    ),

    // ═══════════════════════════════════════════════════════════════════
    // 6. CZECH REPUBLIC (CZ)
    // ═══════════════════════════════════════════════════════════════════
    CountryFamilyLaw(
      country: 'Czech Republic',
      countryCode: 'CZ',
      marriage: MarriageRequirements(
        requiredDocuments: [
          'Valid passport',
          'Birth certificate (apostilled, translated by sworn translator)',
          'Certificate of legal capacity to marry (from home country)',
          'Proof of legal residence',
          'Divorce decree or death certificate if previously married',
          'Certificate of customs/traditions if religious marriage',
        ],
        waitingPeriodDays: 0,
        minimumAge: 18,
        foreignDivorceRecognized: true,
        registrationAuthority: 'Matriční úřad (Registry Office)',
        legalBasis: 'Civil Code (Občanský zákoník) 89/2012, §655-686',
        notes: 'No waiting period once documents ready. Both civil and church marriages legal if registered. Sworn translation required.',
      ),
      divorce: DivorceRules(
        jurisdiction: 'Brussels IIter; habitual residence of respondent',
        applicableLaw: 'Rome III not applicable (Czech Republic does not participate). Czech PIL Act determines applicable law.',
        minimumSeparationMonths: 6,
        mutualConsentAvailable: true,
        courtType: 'Okresní soud (District Court)',
        legalBasis: 'Civil Code §755-770; Act on Private International Law 91/2012',
        immigrantNotes: 'Mutual consent: 6 months separation, no minor child dispute. Contested: court must find deep, permanent, irretrievable breakdown. Czech PIL may apply foreign law based on common nationality.',
      ),
      custody: ChildCustodyRules(
        applicableLaw: 'Law of child habitual residence',
        defaultCustodyType: 'Joint parental responsibility. After divorce: court must decide custody arrangement (joint, sole, or alternating).',
        centralAuthority: 'Office for International Legal Protection of Children (ÚMPOD), Brno',
        hagueConventionStatus: 'Party since 1998',
        relocationRules: 'Both parents must agree; court decides disputes. ÚMPOD assists in international cases.',
        legalBasis: 'Civil Code §858-923',
        immigrantNotes: 'Court must decide custody before granting divorce if minor children involved. OSPOD (child protection authority) provides reports. Alternating custody increasingly favored.',
      ),
      childSupport: ChildSupportRules(
        calculationMethod: 'Court discretion guided by Ministry of Justice tables. Typically 11-24% of income depending on age of child.',
        enforcementMechanism: 'Court enforcement, wage garnishment, seizure of assets, criminal prosecution for persistent non-payment',
        crossBorderEnforcement: 'EU Maintenance Regulation 4/2009; ÚMPOD assists',
        centralAuthority: 'ÚMPOD (Úřad pro mezinárodněprávní ochranu dětí), Brno',
        legalBasis: 'Civil Code §910-923',
        notes: 'Support until child self-sufficient (typically completion of education). State substitute maintenance (náhradní výživné) since 2021 if parent defaults.',
      ),
      domesticViolence: DomesticViolenceProtection(
        emergencyOrderAvailable: true,
        emergencyOrderMaxDays: 10,
        protectionOrderCourt: 'Police issue 10-day eviction order; court extends to 6 months (předběžné opatření)',
        shelterAccess: 'Intervenční centra (intervention centers) in every region; shelters available',
        emergencyHotline: 'DONA linka: 251 511 313; Bílý kruh bezpečí: 116 006',
        availableToImmigrants: true,
        legalBasis: 'Act on Protection Against Domestic Violence 135/2006; Criminal Code §199',
        specialImmigrantProtections: 'Protection applies regardless of immigration status. Intervention centers provide 24/7 support. DV victims can receive temporary residence permit.',
      ),
      parentalLeave: ParentalLeaveRights(
        maternityLeaveDays: 196,
        paternityLeaveDays: 14,
        parentalLeaveDays: 1095,
        payRate: 'Maternity: 70% of daily assessment base. Parental allowance: CZK 350,000 total, flexible distribution until child 4 years.',
        availableToImmigrants: true,
        residencyRequirement: 'Permanent or long-term residence; social insurance participation for maternity benefit',
        legalBasis: 'Labour Code §195-198; Social Security Act 187/2006',
      ),
      birthRegistration: BirthRegistration(
        deadlineDays: 3,
        registrationOffice: 'Matriční úřad (Registry Office) where birth occurred',
        requiredDocuments: [
          'Hospital birth record',
          'Parents ID documents',
          'Marriage certificate if applicable',
          'Paternity acknowledgment if unmarried',
        ],
        citizenshipRule: 'Ius sanguinis: Czech citizenship if at least one parent is Czech citizen',
        legalBasis: 'Act on Vital Records 301/2000; Citizenship Act 186/2013',
        immigrantNotes: 'Registration within working day of notification from hospital. Free birth certificate issued. Non-Czech children registered with parents nationality.',
      ),
      paternity: PaternityRecognition(
        method: 'First presumption: married husband. Second: joint declaration of parents. Third: court determination.',
        legalBasis: 'Civil Code §776-793',
        contestationPeriod: 'Husband: 6 months from learning of birth. Second presumption: challengeable by any of the three parties.',
        immigrantNotes: 'Three-tier presumption system unique to Czech law. Foreign paternity recognized if valid under applicable foreign law.',
      ),
      guardianship: GuardianshipMinors(
        authority: 'Okresní soud (District Court); OSPOD (Authority for Social and Legal Protection of Children)',
        appointmentProcess: 'Court appoints guardian (poručník). OSPOD provides interim protection. Institutional or individual guardianship.',
        legalBasis: 'Civil Code §928-942; Social-Legal Protection of Children Act 359/1999',
        unaccompaniedMinorNotes: 'OSPOD immediately assumes care. Court appoints guardian. Placed in Facility for Children of Foreigners (Zařízení pro děti-cizince) in Prague or foster care. Guardian assists in asylum/immigration procedures.',
      ),
      hagueAbductionNotes: 'Central Authority: ÚMPOD, Šilingrovo náměstí 3/4, 602 00 Brno. Recognized as one of the most efficient Central Authorities in the EU.',
      emergencyContacts: 'Police: 158; Emergency: 112; DONA DV line: 251 511 313; Child line: 116 111; ÚMPOD: +420 542 215 522',
    ),

    // ═══════════════════════════════════════════════════════════════════
    // 7. DENMARK (DK)
    // ═══════════════════════════════════════════════════════════════════
    CountryFamilyLaw(
      country: 'Denmark',
      countryCode: 'DK',
      marriage: MarriageRequirements(
        requiredDocuments: [
          'Valid passport',
          'Birth certificate',
          'Certificate of marital status (prøvelsesattest)',
          'Proof of legal residence in Denmark',
          'Documentation of prior marriage dissolution if applicable',
          'CPR number (civil registration number)',
        ],
        waitingPeriodDays: 0,
        minimumAge: 18,
        foreignDivorceRecognized: true,
        registrationAuthority: 'Familieretshuset (Family Law House) issues marriage certificate (prøvelsesattest)',
        legalBasis: 'Marriage Act (Lov om ægteskabs indgåelse og opløsning)',
        notes: 'Municipality performs ceremony after Familieretshuset issues certificate. Strict anti-sham marriage controls for immigrants.',
      ),
      divorce: DivorceRules(
        jurisdiction: 'Familieretshuset has primary jurisdiction; Nordic Marriage Convention for Nordic citizens',
        applicableLaw: 'Danish law applies (Denmark opted out of Rome III and most EU family law regulations)',
        minimumSeparationMonths: 6,
        mutualConsentAvailable: true,
        courtType: 'Familieretshuset (administrative); Familieretten (Family Court) for contested cases',
        legalBasis: 'Marriage Act; Familieretshuset Act 2019',
        immigrantNotes: 'Denmark opted out of Brussels IIter and Rome III. Danish law generally applies. Mutual consent: immediate. Unilateral: 6-month separation. Familieretshuset screens all cases first.',
      ),
      custody: ChildCustodyRules(
        applicableLaw: 'Danish law if child habitually resident in Denmark (not bound by Brussels IIter)',
        defaultCustodyType: 'Joint custody (fælles forældremyndighed) presumed; continues after separation unless changed',
        centralAuthority: 'Familieretshuset (Family Law House)',
        hagueConventionStatus: 'Party since 1991',
        relocationRules: 'Custodial parent must notify 6 weeks before domestic move; international relocation requires agreement or court order',
        legalBasis: 'Parental Responsibility Act (Forældreansvarsloven) 2007',
        immigrantNotes: 'Denmark NOT bound by Brussels IIter (EU opt-out). Applies own Parental Responsibility Act. Joint custody is strong default. Child involvement in decisions from age 10.',
      ),
      childSupport: ChildSupportRules(
        calculationMethod: 'Familieretshuset sets amount based on income tables (normalbidrag + tillæg). Normal contribution ~DKK 1,560/month (2024).',
        enforcementMechanism: 'Familieretshuset collects; Gældsstyrelsen (debt collection agency) enforces',
        crossBorderEnforcement: 'Not under EU Maintenance Regulation (opt-out). Hague Maintenance Convention 2007 applies; bilateral agreements.',
        centralAuthority: 'Familieretshuset',
        legalBasis: 'Child Support Act (Lov om børns forsørgelse)',
        notes: 'Denmark opted out of EU Maintenance Regulation. Cross-border enforcement through Hague Convention 2007. State advances maintenance (forskudsvis udbetaling) via Udbetaling Danmark.',
      ),
      domesticViolence: DomesticViolenceProtection(
        emergencyOrderAvailable: true,
        emergencyOrderMaxDays: 4,
        protectionOrderCourt: 'Police issue tilhold (restraining order); court confirms within 24 hours. Extended orders through court.',
        shelterAccess: 'Kvindekrisecentre (women crisis centers) ~45 nationwide; free; funded by municipalities',
        emergencyHotline: 'LOKK Hotline: 1888 (crisis centers); Danner: +45 3341 0011',
        availableToImmigrants: true,
        legalBasis: 'Criminal Code §265 (tilhold); Social Services Act §109-110',
        specialImmigrantProtections: 'DV victims can receive independent residence permit. Crisis center stay covered by municipality. Interpreter services provided. Special rules for family reunification cases.',
      ),
      parentalLeave: ParentalLeaveRights(
        maternityLeaveDays: 28,
        paternityLeaveDays: 14,
        parentalLeaveDays: 308,
        payRate: 'Barselsdagpenge: max DKK 4,695/week (2024). Many collective agreements top up to full salary.',
        availableToImmigrants: true,
        residencyRequirement: 'Must meet employment/insurance requirements; legal residence',
        legalBasis: 'Barselsloven (Parental Leave Act) 2022 reform implementing EU Work-Life Balance Directive',
      ),
      birthRegistration: BirthRegistration(
        deadlineDays: 14,
        registrationOffice: 'Digital registration via borger.dk; verified by Personregistrering (CPR office)',
        requiredDocuments: [
          'Digital birth notification from hospital',
          'Parents CPR numbers',
          'Marriage certificate or paternity declaration',
        ],
        citizenshipRule: 'Ius sanguinis: Danish citizenship if father or mother is Danish citizen',
        legalBasis: 'CPR Act; Danish Nationality Act',
        immigrantNotes: 'Hospital notifies digitally. Parents register details via borger.dk within 14 days. Child of immigrants gets parents nationality.',
      ),
      paternity: PaternityRecognition(
        method: 'Married father: automatic (pater est). Unmarried: joint declaration (omsorgs- og ansvarserklæring) or Familieretshuset determination.',
        legalBasis: 'Children Act (Børneloven)',
        contestationPeriod: '6 months from knowledge; child unlimited',
        immigrantNotes: 'Digital declaration possible. Familieretshuset can order DNA testing. Foreign paternity generally recognized.',
      ),
      guardianship: GuardianshipMinors(
        authority: 'Familieretshuset; Statsforvaltningen (municipal social services)',
        appointmentProcess: 'Familieretshuset appoints guardian. Municipality provides interim care through social services.',
        legalBasis: 'Guardianship Act (Værgemålsloven); Social Services Act',
        unaccompaniedMinorNotes: 'Red Cross operates asylum centers for unaccompanied minors. Municipality appoints personal representative (personlig repræsentant). Separate legal guardian for asylum process.',
      ),
      hagueAbductionNotes: 'Central Authority: Familieretshuset, Stormgade 10, 6200 Aabenraa. Despite EU opt-out, Hague Convention fully operational.',
      emergencyContacts: 'Police: 114; Emergency: 112; LOKK crisis: 1888; Child helpline: 116 111',
    ),

    // ═══════════════════════════════════════════════════════════════════
    // 8. ESTONIA (EE)
    // ═══════════════════════════════════════════════════════════════════
    CountryFamilyLaw(
      country: 'Estonia',
      countryCode: 'EE',
      marriage: MarriageRequirements(
        requiredDocuments: [
          'Valid passport',
          'Birth certificate (apostilled)',
          'Certificate of no impediment from home country',
          'Proof of legal residence or visa',
          'Divorce/death certificate if previously married',
        ],
        waitingPeriodDays: 30,
        minimumAge: 18,
        foreignDivorceRecognized: true,
        registrationAuthority: 'Perekonnaseisuamet (Vital Statistics Office) or notary',
        legalBasis: 'Family Law Act (Perekonnaseadus) 2010',
        notes: 'Marriage can be contracted at vital statistics office, through notary, or by minister of religion. 1-month waiting period after application.',
      ),
      divorce: DivorceRules(
        jurisdiction: 'Brussels IIter; habitual residence rules',
        applicableLaw: 'Rome III: party choice; default common habitual residence',
        minimumSeparationMonths: 0,
        mutualConsentAvailable: true,
        courtType: 'Maakohus (County Court); or vital statistics office/notary for mutual consent',
        legalBasis: 'Family Law Act §64-68; Rome III',
        immigrantNotes: 'Mutual consent divorce possible through vital statistics office or notary without court. Contested divorce through county court. No separation requirement.',
      ),
      custody: ChildCustodyRules(
        applicableLaw: 'Law of child habitual residence per Brussels IIter',
        defaultCustodyType: 'Joint parental custody (ühine hooldusõigus); continues after divorce unless court orders otherwise',
        centralAuthority: 'Ministry of Justice (Justiitsministeerium)',
        hagueConventionStatus: 'Party since 2001',
        relocationRules: 'Both parents must consent; court decides in case of dispute',
        legalBasis: 'Family Law Act §116-140',
        immigrantNotes: 'Joint custody strong default. Court appoints child representative in disputes. E-services available for many family law procedures. Estonian courts efficient in Hague return cases.',
      ),
      childSupport: ChildSupportRules(
        calculationMethod: 'Minimum support: half the minimum wage (2024: ~€410/month). Court may set higher based on means and needs.',
        enforcementMechanism: 'Court order enforcement through bailiff (kohtutäitur); wage garnishment',
        crossBorderEnforcement: 'EU Maintenance Regulation 4/2009',
        centralAuthority: 'Ministry of Justice',
        legalBasis: 'Family Law Act §100-115',
        notes: 'Minimum maintenance relatively high (half minimum wage). State maintenance aid (riiklik elatisabi) up to €200/month if parent defaults. Support until 21 if in education.',
      ),
      domesticViolence: DomesticViolenceProtection(
        emergencyOrderAvailable: true,
        emergencyOrderMaxDays: 14,
        protectionOrderCourt: 'County court issues restraining order (lähenemiskeeld). Police can apply for temporary restraining order.',
        shelterAccess: 'Women shelters (naiste varjupaigad) in every county; 24/7 service',
        emergencyHotline: '116 006 (victim helpline); 1492 (women helpline)',
        availableToImmigrants: true,
        legalBasis: 'Code of Criminal Procedure §1411; Penal Code §120-1211; Victim Support Act',
        specialImmigrantProtections: 'Protection orders available regardless of status. Victim support services free and available in Russian and English. DV victims may receive temporary residence permit.',
      ),
      parentalLeave: ParentalLeaveRights(
        maternityLeaveDays: 100,
        paternityLeaveDays: 30,
        parentalLeaveDays: 475,
        payRate: 'Maternity: 100% of average salary. Parental benefit: 100% of previous income (capped at 3x national average). Minimum: €654/month.',
        availableToImmigrants: true,
        residencyRequirement: 'Legal residence in Estonia; registered in Population Register',
        legalBasis: 'Family Benefits Act (Perehüvitiste seadus) 2022 reform',
      ),
      birthRegistration: BirthRegistration(
        deadlineDays: 30,
        registrationOffice: 'Perekonnaseisuamet (Vital Statistics Office) or digitally via eesti.ee',
        requiredDocuments: [
          'Hospital birth notification',
          'Parents ID documents',
          'Marriage certificate if applicable',
        ],
        citizenshipRule: 'Ius sanguinis: Estonian citizenship if at least one parent is Estonian citizen. Children of non-citizens may be stateless or get parents nationality.',
        legalBasis: 'Vital Statistics Registration Act',
        immigrantNotes: 'Digital registration possible. Significant stateless population (grey passport holders) — children can apply for Estonian citizenship by naturalization.',
      ),
      paternity: PaternityRecognition(
        method: 'Married: automatic presumption. Unmarried: joint application to vital statistics office. Court determination if disputed.',
        legalBasis: 'Family Law Act §82-95',
        contestationPeriod: '1 year from learning of circumstances; child unlimited',
        immigrantNotes: 'Can be done digitally in some cases. Foreign paternity recognized if valid under applicable law.',
      ),
      guardianship: GuardianshipMinors(
        authority: 'Maakohus (County Court); local government (kohalik omavalitsus)',
        appointmentProcess: 'Local government identifies need; court appoints guardian. Local government may act as guardian.',
        legalBasis: 'Family Law Act §171-191',
        unaccompaniedMinorNotes: 'Local government provides immediate care and representation. Court appoints guardian. Placed in substitute homes (asenduskodud) or foster care. Estonian Integration Foundation assists.',
      ),
      hagueAbductionNotes: 'Central Authority: Ministry of Justice, Suur-Ameerika 1, 10122 Tallinn.',
      emergencyContacts: 'Police: 110; Emergency: 112; Victim helpline: 116 006; Women line: 1492; Child line: 116 111',
    ),

    // ═══════════════════════════════════════════════════════════════════
    // 9. FINLAND (FI)
    // ═══════════════════════════════════════════════════════════════════
    CountryFamilyLaw(
      country: 'Finland',
      countryCode: 'FI',
      marriage: MarriageRequirements(
        requiredDocuments: [
          'Valid passport',
          'Certificate of no impediment (esteetön todistus) from home country or DVV',
          'Birth certificate',
          'Divorce decree or death certificate if previously married',
          'Population register extract if resident in Finland',
        ],
        waitingPeriodDays: 7,
        minimumAge: 18,
        foreignDivorceRecognized: true,
        registrationAuthority: 'Digi- ja väestötietovirasto (DVV — Digital and Population Data Services Agency)',
        legalBasis: 'Marriage Act (Avioliittolaki 234/1929, amended)',
        notes: 'DVV examines impediments. Marriage can be performed by church, registered community, or magistrate. Same-sex marriage since 2017.',
      ),
      divorce: DivorceRules(
        jurisdiction: 'Brussels IIter; habitual residence of respondent or applicant (if 1 year residence)',
        applicableLaw: 'Rome III: party choice; Finnish law typically applied for residents',
        minimumSeparationMonths: 6,
        mutualConsentAvailable: true,
        courtType: 'Käräjäoikeus (District Court)',
        legalBasis: 'Marriage Act Ch. 6 §25-32; Rome III',

        immigrantNotes: 'Mandatory 6-month reconsideration period for all divorces (except 2-year separation). No fault required. Court can waive period in exceptional cases. Legal aid available for low-income applicants.',
      ),
      custody: ChildCustodyRules(
        applicableLaw: 'Law of child habitual residence; Finnish law if child in Finland',
        defaultCustodyType: 'Joint custody (yhteishuoltajuus) if parents married. Unmarried: mother has sole custody unless agreement or court order.',
        centralAuthority: 'Ministry of Justice (Oikeusministeriö)',
        hagueConventionStatus: 'Party since 1994',
        relocationRules: 'Joint custodians must agree on relocation. Notification obligation for domestic moves since 2019.',
        legalBasis: 'Act on Child Custody and Right of Access (Laki lapsen huollosta ja tapaamisoikeudesta 361/1983, reformed 2019)',
        immigrantNotes: 'Strong emphasis on best interest of child. Social worker (lastenvalvoja) assists in making agreements. Agreements confirmed by social welfare board have same force as court orders. Alternating residence increasingly common.',
      ),
      childSupport: ChildSupportRules(
        calculationMethod: 'Ministry of Justice guidelines: based on costs of child and both parents income. Typical range €150-400/month per child.',
        enforcementMechanism: 'Kela (Social Insurance Institution) can collect on behalf of recipient; enforcement through ulosotto (enforcement authority)',
        crossBorderEnforcement: 'EU Maintenance Regulation 4/2009; Kela as Central Authority intermediary',
        centralAuthority: 'Ministry of Justice; Kela for recovery',
        legalBasis: 'Child Maintenance Act (Laki lapsen elatuksesta 704/1975)',
        notes: 'Kela pays elatustuki (maintenance allowance) €172.59/month per child (2024) if parent does not pay. Available regardless of parents nationality.',
      ),
      domesticViolence: DomesticViolenceProtection(
        emergencyOrderAvailable: true,
        emergencyOrderMaxDays: 30,
        protectionOrderCourt: 'Käräjäoikeus issues lähestymiskielto (restraining order). Temporary order effective immediately.',
        shelterAccess: 'Turvakoti (shelter) network: ~29 shelters nationwide, free, available 24/7 regardless of immigration status',
        emergencyHotline: 'Nollalinja: 080 005 005 (24/7, free, multilingual including Russian, Arabic, English)',
        availableToImmigrants: true,
        legalBasis: 'Act on Restraining Orders (Laki lähestymiskiellosta 898/1998); Shelters Act 2014',
        specialImmigrantProtections: 'Restraining orders available regardless of immigration status. Turvakoti shelters open to all, no questions about residence status. Nollalinja multilingual. DV victims may obtain continuous residence permit (A-permit) independently.',
      ),
      parentalLeave: ParentalLeaveRights(
        maternityLeaveDays: 40,
        paternityLeaveDays: 40,
        parentalLeaveDays: 320,
        payRate: 'Pregnancy allowance and parental allowance: ~70% of income (higher for lower incomes, reduced above ceiling). Minimum ~€30.71/day.',
        availableToImmigrants: true,
        residencyRequirement: 'Covered by Finnish social security (residence-based via Kela)',
        legalBasis: 'Health Insurance Act (Sairausvakuutuslaki); 2022 family leave reform',
      ),
      birthRegistration: BirthRegistration(
        deadlineDays: 30,
        registrationOffice: 'DVV (Digital and Population Data Services Agency); hospital notifies automatically',
        requiredDocuments: [
          'Hospital birth notification (automatic)',
          'Parents personal data (from Population Information System)',
          'Notification of childs name within 3 months',
        ],
        citizenshipRule: 'Ius sanguinis: Finnish citizenship if mother is Finnish, or father if married to mother (or paternity confirmed and father Finnish)',
        legalBasis: 'Act on Population Information System; Nationality Act (Kansalaisuuslaki 359/2003)',
        immigrantNotes: 'Hospital notifies DVV automatically. Parents register name within 3 months. Child of immigrants gets parents nationality. Finnish citizenship possible by declaration if born in Finland and no other nationality.',
      ),
      paternity: PaternityRecognition(
        method: 'Married father: automatic if married at birth or later marriage. Unmarried: acknowledgment at neuvola (maternity clinic) before birth or at lastenvalvoja after birth. Court determination.',
        legalBasis: 'Paternity Act (Isyyslaki 11/2015)',
        contestationPeriod: '2 years from acknowledgment; child unlimited',
        immigrantNotes: 'Pre-birth acknowledgment at neuvola is common and straightforward. Maternity automatically established by birth. Second mother in female couple: recognized by acknowledgment since 2023.',
      ),
      guardianship: GuardianshipMinors(
        authority: 'Käräjäoikeus (District Court); DVV registers guardians',
        appointmentProcess: 'Court appoints guardian (edunvalvoja) on petition by social services or interested party. DVV maintains register.',
        legalBasis: 'Guardianship Services Act (Laki holhoustoimesta 442/1999)',
        unaccompaniedMinorNotes: 'Municipality reception services appoint representative (edustaja) for asylum-seeking UAMs immediately upon arrival. Separate from legal guardian. Placed in group homes (ryhmäkoti) or family care. Municipality of placement assumes ongoing responsibility.',
      ),
      hagueAbductionNotes: 'Central Authority: Ministry of Justice, Eteläesplanadi 10, 00130 Helsinki. Helsinki District Court has exclusive jurisdiction for Hague return cases.',
      emergencyContacts: 'Police: 112; Emergency: 112; Nollalinja (DV): 080 005 005; Child & youth helpline: 116 111; Crisis line: 09 2525 0111',
    ),

    // ═══════════════════════════════════════════════════════════════════
    // 10. FRANCE (FR)
    // ═══════════════════════════════════════════════════════════════════
    CountryFamilyLaw(
      country: 'France',
      countryCode: 'FR',
      marriage: MarriageRequirements(
        requiredDocuments: [
          'Valid passport',
          'Birth certificate less than 3 months old (acte de naissance)',
          'Certificat de coutume (certificate of custom/law from consulate)',
          'Certificat de célibat (single status certificate)',
          'Proof of domicile (justificatif de domicile)',
          'Divorce judgment if previously married',
        ],
        waitingPeriodDays: 10,
        minimumAge: 18,
        foreignDivorceRecognized: true,
        registrationAuthority: 'Mairie (Town Hall)',
        legalBasis: 'Code civil Art. 63-76',
        notes: 'Publication of banns (publication des bans) 10 days before ceremony. Marriage celebrated at Mairie. PACS (civil partnership) also available.',
      ),
      divorce: DivorceRules(
        jurisdiction: 'Brussels IIter; habitual residence rules; French courts if both spouses French',
        applicableLaw: 'Rome III: party choice; default law of common habitual residence',
        minimumSeparationMonths: 0,
        mutualConsentAvailable: true,
        courtType: 'Juge aux affaires familiales (JAF) at Tribunal judiciaire; or notarial divorce by mutual consent since 2017',
        legalBasis: 'Code civil Art. 229-309; Rome III',
        immigrantNotes: 'Four types: mutual consent (by notarial act since 2017), accepted breakdown, definitive alteration of marital bond (1 year separation removed in 2021 reform), fault. Mutual consent without court since 2017 unless minor child requests hearing.',
      ),
      custody: ChildCustodyRules(
        applicableLaw: 'Law of child habitual residence per Brussels IIter',
        defaultCustodyType: 'Joint parental authority (autorité parentale conjointe) — automatic for both married and unmarried parents who both recognized child',
        centralAuthority: 'Ministère de la Justice, Direction des Affaires Civiles et du Sceau',
        hagueConventionStatus: 'Party since 1983',
        relocationRules: 'Parent must notify other parent of planned move. If move affects access rights, court must decide.',
        legalBasis: 'Code civil Art. 371-387; Law of 4 March 2002',
        immigrantNotes: 'Joint authority default for all parents. Résidence alternée (shared residence) increasingly common. JAF decides all custody matters. Mediation encouraged. Child hearing right from age of discernment.',
      ),
      childSupport: ChildSupportRules(
        calculationMethod: 'Ministry of Justice reference table based on income, number of children, and custody arrangement. Indicative, not binding.',
        enforcementMechanism: 'Agence de recouvrement et d\'intermédiation des pensions alimentaires (ARIPA/CAF) collects and advances',
        crossBorderEnforcement: 'EU Maintenance Regulation 4/2009; ARIPA as intermediary body',
        centralAuthority: 'Ministère de la Justice; ARIPA/CAF for recovery',
        legalBasis: 'Code civil Art. 371-2, 373-2-2; Loi du 24 décembre 2019 (ARIPA)',
        notes: 'ARIPA (under CAF) systematically intermediates since 2023. Advances up to €616/month. ASF (allocation de soutien familial) €187.24/month if parent absent. Available to all legal residents.',
      ),
      domesticViolence: DomesticViolenceProtection(
        emergencyOrderAvailable: true,
        emergencyOrderMaxDays: 6,
        protectionOrderCourt: 'JAF issues ordonnance de protection within 6 days of request (since 2020 reform). Valid 6-12 months.',
        shelterAccess: 'CHRS (centres d\'hébergement) and dedicated DV shelters; 115 for emergency housing',
        emergencyHotline: '3919 (Violences Femmes Info, 24/7); 114 (SMS for deaf)',
        availableToImmigrants: true,
        legalBasis: 'Code civil Art. 515-9 to 515-13; Loi Visant à Protéger les Victimes de Violences Conjugales 2020',
        specialImmigrantProtections: 'Ordonnance de protection gives victim right to stay independently (titre de séjour). Telephones grave danger (TGD) program. Bracelet anti-rapprochement (electronic bracelet). Undocumented victims can obtain residence permit.',
      ),
      parentalLeave: ParentalLeaveRights(
        maternityLeaveDays: 112,
        paternityLeaveDays: 28,
        parentalLeaveDays: 1095,
        payRate: 'Maternity: daily allowance from Sécurité sociale (up to ceiling ~€100.36/day). Parental leave: PreParE ~€422.21/month full-time or €273.01 part-time.',
        availableToImmigrants: true,
        residencyRequirement: 'Legal residence and affiliation to Sécurité sociale',
        legalBasis: 'Code du travail L1225; Code de la sécurité sociale',
      ),
      birthRegistration: BirthRegistration(
        deadlineDays: 5,
        registrationOffice: 'Mairie (Town Hall) of birth location; officier d\'état civil',
        requiredDocuments: [
          'Medical certificate of birth',
          'Parents ID documents',
          'Livret de famille or marriage certificate',
          'Déclaration de naissance from hospital',
          'Reconnaissance (acknowledgment) if unmarried father',
        ],
        citizenshipRule: 'Ius sanguinis + strong ius soli: child born in France to foreign parents becomes French at 18 if resided in France 5+ years since age 11. Can claim at 16 or parents at 13.',
        legalBasis: 'Code civil Art. 55-62; Nationality Code Art. 19-3, 21-7 to 21-11',
        immigrantNotes: 'France has strong ius soli elements. Child born to immigrants on French soil can acquire French nationality. Double ius soli: automatic at birth if one parent also born in France.',
      ),
      paternity: PaternityRecognition(
        method: 'Married: automatic presumption. Unmarried: reconnaissance (acknowledgment) at Mairie, before or after birth. Judicial: action en recherche de paternité.',
        legalBasis: 'Code civil Art. 310-320',
        contestationPeriod: '5 years from birth or discovery. Child: 10 years from age of majority.',
        immigrantNotes: 'Pre-birth reconnaissance very common and recommended. Mairie may refer to prosecutor if suspicion of fraudulent reconnaissance (since 2019 law).',
      ),
      guardianship: GuardianshipMinors(
        authority: 'Juge des tutelles (guardianship judge) at Tribunal judiciaire',
        appointmentProcess: 'Juge des tutelles convenes family council (conseil de famille) which nominates guardian (tuteur). Judge appoints.',
        legalBasis: 'Code civil Art. 390-413',
        unaccompaniedMinorNotes: 'ASE (Aide Sociale à l\'Enfance — child welfare) of département provides interim care. Judge appoints administrator. Evaluation of age and minority status. Once confirmed minor: full child protection applies. Education, health, legal representation guaranteed.',
      ),
      hagueAbductionNotes: 'Central Authority: Ministère de la Justice, DACS, Bureau de l\'entraide civile et commerciale internationale, 13 Place Vendôme, 75001 Paris.',
      emergencyContacts: 'Police: 17; Emergency: 112; DV: 3919 (24/7); Child abuse: 119; Emergency housing: 115',
    ),

    // ═══════════════════════════════════════════════════════════════════
    // 11. GERMANY (DE)
    // ═══════════════════════════════════════════════════════════════════
    CountryFamilyLaw(
      country: 'Germany',
      countryCode: 'DE',
      marriage: MarriageRequirements(
        requiredDocuments: [
          'Valid passport',
          'Birth certificate (beglaubigte Abschrift aus dem Geburtenregister)',
          'Ehefähigkeitszeugnis (certificate of capacity to marry) from home country or exemption from higher regional court',
          'Aufenthaltsbescheinigung (residence certificate)',
          'Divorce decree / death certificate if applicable',
        ],
        waitingPeriodDays: 0,
        minimumAge: 18,
        foreignDivorceRecognized: true,
        registrationAuthority: 'Standesamt (Registry Office)',
        legalBasis: 'Bürgerliches Gesetzbuch (BGB) §1303-1312; Personenstandsgesetz (PStG)',
        notes: 'Only civil marriage legally valid. Ehefähigkeitszeugnis can be difficult to obtain; OLG can grant exemption. All documents require certified translation and apostille/legalization.',
      ),
      divorce: DivorceRules(
        jurisdiction: 'Brussels IIter; habitual residence rules',
        applicableLaw: 'Rome III: party choice; default common habitual residence, then common nationality',
        minimumSeparationMonths: 12,
        mutualConsentAvailable: true,
        courtType: 'Familiengericht (Family Court) at Amtsgericht',
        legalBasis: 'BGB §1564-1568; Rome III',
        immigrantNotes: 'Mandatory 1-year separation (Trennungsjahr). 3 years if unilateral and contested. Mandatory Versorgungsausgleich (pension equalization). Anwaltszwang: each party must have a lawyer. Prozesskostenhilfe (legal aid) available.',
      ),
      custody: ChildCustodyRules(
        applicableLaw: 'Law of child habitual residence per Brussels IIter',
        defaultCustodyType: 'Joint parental care (gemeinsames Sorgerecht) if married. Unmarried: mother has sole Sorgerecht unless father applies for joint (since 2013 reform).',
        centralAuthority: 'Bundesamt für Justiz (Federal Office of Justice), Bonn',
        hagueConventionStatus: 'Party since 1990',
        relocationRules: 'Joint Sorgerecht: both must agree on relocation. Aufenthaltsbestimmungsrecht (right to determine residence) can be transferred to one parent.',
        legalBasis: 'BGB §1626-1698; FamFG',
        immigrantNotes: 'Jugendamt (Youth Welfare Office) plays key role in all custody proceedings — provides reports and recommendations. Can be appointed as Beistand (legal representative of child). Unmarried fathers: simplified procedure to obtain joint custody since 2013.',
      ),
      childSupport: ChildSupportRules(
        calculationMethod: 'Düsseldorfer Tabelle: standardized table based on net income and age of child. Minimum ~€480/month for 0-5 years (2024).',
        enforcementMechanism: 'Court order, Jugendamt Beistandschaft (support collection), wage garnishment, Unterhaltsvorschuss (state advance)',
        crossBorderEnforcement: 'EU Maintenance Regulation 4/2009; Bundesamt für Justiz as Central Authority',
        centralAuthority: 'Bundesamt für Justiz, Bonn',
        legalBasis: 'BGB §1601-1615; Unterhaltsvorschussgesetz (UVG)',
        notes: 'Unterhaltsvorschuss (state advance): up to €230/month (0-5), €301 (6-11), €395 (12-17) (2024). Until age 18. Available regardless of nationality if child resident in Germany.',
      ),
      domesticViolence: DomesticViolenceProtection(
        emergencyOrderAvailable: true,
        emergencyOrderMaxDays: 14,
        protectionOrderCourt: 'Familiengericht issues Schutzanordnung per GewSchG. Police Platzverweisung (removal order) 10-14 days depending on Land.',
        shelterAccess: 'Frauenhäuser (women shelters) ~350 nationwide; funding varies by Bundesland',
        emergencyHotline: 'Hilfetelefon: 116 016 (24/7, 18 languages); Polizei: 110',
        availableToImmigrants: true,
        legalBasis: 'Gewaltschutzgesetz (GewSchG) 2002; respective Land police laws',
        specialImmigrantProtections: 'Wer schlägt, der geht (who hits, leaves) principle. DV victims with dependent residence permit: independent residence right after 3 years (reduced to 1 year in hardship cases per §31 AufenthG). Shelter access regardless of status. Hilfetelefon in 18 languages.',
      ),
      parentalLeave: ParentalLeaveRights(
        maternityLeaveDays: 98,
        paternityLeaveDays: 0,
        parentalLeaveDays: 1095,
        payRate: 'Elterngeld: 65-67% of net income, min €300, max €1,800/month. ElterngeldPlus: half amount, double duration. Partnership bonus available.',
        availableToImmigrants: true,
        residencyRequirement: 'Residence permit allowing employment (Aufenthaltstitel mit Erwerbstätigkeit); or EU citizens; or permanent residents',
        legalBasis: 'MuSchG (Maternity Protection Act); BEEG (Federal Parental Allowance and Parental Leave Act)',
      ),
      birthRegistration: BirthRegistration(
        deadlineDays: 7,
        registrationOffice: 'Standesamt (Registry Office) where birth occurred',
        requiredDocuments: [
          'Geburtsanzeige from hospital',
          'Parents passports',
          'Marriage certificate (Eheurkunde) if married',
          'Vaterschaftsanerkennung (paternity acknowledgment) if unmarried',
          'Geburtsurkunden of parents',
        ],
        citizenshipRule: 'Ius sanguinis + limited ius soli: German citizenship if one parent German, OR if child born in Germany to parent with 8+ years legal residence and permanent residence permit',
        legalBasis: 'PStG; Staatsangehörigkeitsgesetz (StAG) §4',
        immigrantNotes: 'Since 2000: ius soli for children born in Germany to parents with 8+ years residence + permanent permit. Since 2014 reform: dual nationality possible (Optionspflicht abolished for most). Major benefit for immigrant families.',
      ),
      paternity: PaternityRecognition(
        method: 'Married: automatic presumption. Unmarried: Vaterschaftsanerkennung (acknowledgment) at Standesamt, Jugendamt, notary. Judicial establishment.',
        legalBasis: 'BGB §1592-1600e',
        contestationPeriod: '2 years from knowledge of circumstances casting doubt',
        immigrantNotes: 'Jugendamt offers free paternity acknowledgment and custody declarations. Since 2017: authorities can refuse Vaterschaftsanerkennung if sole purpose is immigration advantage (§1597a BGB).',
      ),
      guardianship: GuardianshipMinors(
        authority: 'Familiengericht; Jugendamt (Youth Welfare Office)',
        appointmentProcess: 'Familiengericht appoints Vormund (guardian). Jugendamt can serve as Amtsvormund (official guardian). Individual Vormundschaft preferred since 2023 reform.',
        legalBasis: 'BGB §1773-1895; SGB VIII §§55-58; Vormundschaftsrecht reform 2023',
        unaccompaniedMinorNotes: 'Jugendamt takes into care immediately (Inobhutnahme per §42 SGB VIII). Familiengericht appoints Vormund. Age assessment procedures. Placed in Erstaufnahmeeinrichtung then Jugendhilfe facility. Guardian assists in asylum procedure. 2023 reform: individual guardianship preferred over Amtsvormund.',
      ),
      hagueAbductionNotes: 'Central Authority: Bundesamt für Justiz, Adenauerallee 99-103, 53113 Bonn. Designated family courts handle return cases with concentration of jurisdiction.',
      emergencyContacts: 'Police: 110; Emergency: 112; Hilfetelefon DV: 116 016 (18 languages); Child helpline: 116 111; Jugendamt varies by municipality',
    ),

    // ═══════════════════════════════════════════════════════════════════
    // 12. GREECE (GR)
    // ═══════════════════════════════════════════════════════════════════
    CountryFamilyLaw(
      country: 'Greece',
      countryCode: 'GR',
      marriage: MarriageRequirements(
        requiredDocuments: [
          'Valid passport',
          'Birth certificate (apostilled, translated)',
          'Certificate of no impediment from home country or consulate',
          'Publication of banns at municipality',
          'Proof of legal residence',
          'Affidavit of single status',
        ],
        waitingPeriodDays: 8,
        minimumAge: 18,
        foreignDivorceRecognized: true,
        registrationAuthority: 'Dimarchio (Town Hall) for civil; religious authority for church marriage',
        legalBasis: 'Civil Code Art. 1350-1371',
        notes: 'Both civil and religious (Orthodox, Catholic, Muslim, Jewish) marriages have equal legal standing. Publication of banns required 8 days before ceremony.',
      ),
      divorce: DivorceRules(
        jurisdiction: 'Brussels IIter; habitual residence rules',
        applicableLaw: 'Rome III: party choice; default common habitual residence',
        minimumSeparationMonths: 6,
        mutualConsentAvailable: true,
        courtType: 'Monomeles Protodikeio (Single-Member Court of First Instance); notarial divorce since 2017',
        legalBasis: 'Civil Code Art. 1438-1441; Law 4509/2017 (notarial divorce); Rome III',
        immigrantNotes: 'Mutual consent: notarial divorce possible since 2017 (even with minor children, with agreement). Contested: 2-year separation creates irrebuttable presumption of breakdown. Fault grounds also available.',
      ),
      custody: ChildCustodyRules(
        applicableLaw: 'Law of child habitual residence per Brussels IIter',
        defaultCustodyType: 'Joint parental care (goneki merimna). After divorce: joint custody preferred since Law 4800/2021 reform. Alternating residence encouraged.',
        centralAuthority: 'Ministry of Justice — Directorate of International Judicial Cooperation',
        hagueConventionStatus: 'Party since 1993',
        relocationRules: 'Relocation restrictions under joint custody; court permission required for international move',
        legalBasis: 'Civil Code Art. 1510-1541; Law 4800/2021 (major custody reform)',
        immigrantNotes: 'Major 2021 reform: mandatory joint custody, alternating residence as default, minimum 1/3 time with each parent, mandatory mediation before court. Parental alienation addressed.',
      ),
      childSupport: ChildSupportRules(
        calculationMethod: 'Court discretion based on needs and means; no official formula. Typically 1/3 of non-custodial parent income.',
        enforcementMechanism: 'Court order enforcement, wage attachment, asset seizure; criminal prosecution possible',
        crossBorderEnforcement: 'EU Maintenance Regulation 4/2009',
        centralAuthority: 'Ministry of Justice',
        legalBasis: 'Civil Code Art. 1485-1504',
        notes: 'Support until child self-sufficient. No state advance payment system. Enforcement can be slow. Cross-border recovery through EU Maintenance Regulation.',
      ),
      domesticViolence: DomesticViolenceProtection(
        emergencyOrderAvailable: true,
        emergencyOrderMaxDays: 30,
        protectionOrderCourt: 'Court issues protective measures (asfalistika metra). Police can arrest for flagrant DV offenses.',
        shelterAccess: 'KSOD (Counseling Centers) and shelters operated by KETHI and municipalities; ~20 shelters',
        emergencyHotline: '15900 (24/7 DV helpline); SOS 1056 (child abuse)',
        availableToImmigrants: true,
        legalBasis: 'Law 3500/2006 (Domestic Violence); amended by Law 4531/2018 (Istanbul Convention ratification)',
        specialImmigrantProtections: 'Protection available regardless of immigration status. DV victims can receive independent residence permit under Law 4251/2014 Art. 19A. Shelters accept undocumented women.',
      ),
      parentalLeave: ParentalLeaveRights(
        maternityLeaveDays: 119,
        paternityLeaveDays: 14,
        parentalLeaveDays: 120,
        payRate: 'Maternity: IKA benefits ~2/3 of salary. Parental leave: 2 months paid (minimum wage level per Law 4808/2021).',
        availableToImmigrants: true,
        residencyRequirement: 'Insured under IKA/EFKA social insurance',
        legalBasis: 'Labour laws; Law 4808/2021 implementing EU Work-Life Balance Directive',
      ),
      birthRegistration: BirthRegistration(
        deadlineDays: 10,
        registrationOffice: 'Lixiarchio (Civil Registry) of municipality where birth occurred',
        requiredDocuments: [
          'Hospital birth certificate',
          'Parents IDs/passports',
          'Marriage certificate or paternity acknowledgment',
          'Aftofoto (personal declaration) if needed',
        ],
        citizenshipRule: 'Ius sanguinis primarily. Limited ius soli: child born in Greece can acquire citizenship if parent has 5 years legal residence, or child after 6 years of schooling in Greece.',
        legalBasis: 'Civil Registry Code; Greek Citizenship Code (Law 4332/2015)',
        immigrantNotes: 'Law 4332/2015 introduced ius soli elements: second-generation children born in Greece, or those completing 6 years of Greek schooling, can acquire Greek citizenship.',
      ),
      paternity: PaternityRecognition(
        method: 'Married: automatic presumption. Unmarried: voluntary acknowledgment (ekoussia anagnorisi) at notary. Judicial establishment.',
        legalBasis: 'Civil Code Art. 1465-1484',
        contestationPeriod: 'Husband: 1 year from birth or knowledge. Child: unlimited until 1 year after majority.',
        immigrantNotes: 'Notarial acknowledgment straightforward. Foreign acknowledgments recognized if not contrary to Greek public order.',
      ),
      guardianship: GuardianshipMinors(
        authority: 'Monomeles Protodikeio; Social welfare services (Pronoiakes Ypiresies)',
        appointmentProcess: 'Court appoints epitropos (guardian). Social welfare investigates and recommends.',
        legalBasis: 'Civil Code Art. 1589-1654',
        unaccompaniedMinorNotes: 'National Centre for Social Solidarity (EKKA) coordinates protection. Placed in shelters or supported independent living. Guardian appointed by prosecutor initially. Special Protection Secretariat established 2020 for UAM.',
      ),
      hagueAbductionNotes: 'Central Authority: Ministry of Justice, Mesogion 96, 11527 Athens. Greek courts have been criticized for slow processing; improvements ongoing.',
      emergencyContacts: 'Police: 100; Emergency: 112; DV hotline: 15900; Child abuse: 1056; EKKA: 197',
    ),

    // ═══════════════════════════════════════════════════════════════════
    // 13. HUNGARY (HU)
    // ═══════════════════════════════════════════════════════════════════
    CountryFamilyLaw(
      country: 'Hungary',
      countryCode: 'HU',
      marriage: MarriageRequirements(
        requiredDocuments: [
          'Valid passport',
          'Birth certificate (apostilled, translated)',
          'Certificate of no impediment (tanúsítvány házasságkötési akadály hiányáról)',
          'Proof of legal residence',
          'Prior marriage dissolution proof if applicable',
        ],
        waitingPeriodDays: 30,
        minimumAge: 18,
        foreignDivorceRecognized: true,
        registrationAuthority: 'Anyakönyvvezető (Civil Registrar) at local government office',
        legalBasis: 'Civil Code (Ptk.) Book 4, Family Law',
        notes: '30-day waiting period after application. Only civil marriage legally valid. 16-year-olds may marry with guardianship authority permission.',
      ),
      divorce: DivorceRules(
        jurisdiction: 'Brussels IIter; habitual residence rules',
        applicableLaw: 'Rome III: party choice; default common habitual residence',
        minimumSeparationMonths: 0,
        mutualConsentAvailable: true,
        courtType: 'Járásbíróság (District Court)',
        legalBasis: 'Civil Code (Ptk.) 4:21-4:23; Rome III',
        immigrantNotes: 'Mutual consent divorce if agreement on all ancillary matters. Contested: deep and irretrievable breakdown. No mandatory separation period. Mediation encouraged.',
      ),
      custody: ChildCustodyRules(
        applicableLaw: 'Law of child habitual residence per Brussels IIter',
        defaultCustodyType: 'Joint parental authority (közös szülői felügyelet) during marriage. After divorce: joint or sole by agreement or court order.',
        centralAuthority: 'Ministry of Justice, Department of Private International Law',
        hagueConventionStatus: 'Party since 1986',
        relocationRules: 'Consent of both parents required for international relocation',
        legalBasis: 'Civil Code (Ptk.) 4:146-4:183',
        immigrantNotes: 'Best interest standard (gyermek érdeke). Gyámhatóság (guardianship authority) provides expertise. Joint custody strong preference. Child hearing from age 14 mandatory, younger if mature enough.',
      ),
      childSupport: ChildSupportRules(
        calculationMethod: 'Generally 15-25% of net income per child. Court discretion based on needs and means.',
        enforcementMechanism: 'Court enforcement, wage garnishment, execution proceedings',
        crossBorderEnforcement: 'EU Maintenance Regulation 4/2009',
        centralAuthority: 'Ministry of Justice',
        legalBasis: 'Civil Code (Ptk.) 4:194-4:220',
        notes: 'No state advance maintenance system. Gyerektartásdíj (child support) enforced through general execution law. Support typically until 18, or 20 if in secondary education.',
      ),
      domesticViolence: DomesticViolenceProtection(
        emergencyOrderAvailable: true,
        emergencyOrderMaxDays: 3,
        protectionOrderCourt: 'Police issue megelőző távoltartás (preventive restraining order) for 72 hours. Court issues ideiglenes megelőző távoltartás up to 60 days.',
        shelterAccess: 'Családok Átmeneti Otthona (family temporary shelters); crisis houses',
        emergencyHotline: 'NANE: +36 80 505 101; Victim helpline: 06 80 225 225',
        availableToImmigrants: true,
        legalBasis: 'Act LXXII of 2009 on restraining orders; Criminal Code §212/A',
        specialImmigrantProtections: 'Restraining orders available to all. Shelter access not dependent on immigration status. NANE helpline provides multilingual information.',
      ),
      parentalLeave: ParentalLeaveRights(
        maternityLeaveDays: 168,
        paternityLeaveDays: 10,
        parentalLeaveDays: 1095,
        payRate: 'CSED (maternity): 70% of daily income for 168 days. GYED: 70% for up to 2 years. GYES: flat rate HUF 28,500/month until age 3.',
        availableToImmigrants: true,
        residencyRequirement: 'Social insurance coverage; legal residence',
        legalBasis: 'Labour Code; Social Insurance Acts; Family Support Act',
      ),
      birthRegistration: BirthRegistration(
        deadlineDays: 8,
        registrationOffice: 'Anyakönyvvezető at local government where birth occurred',
        requiredDocuments: [
          'Hospital birth notification',
          'Parents identity documents',
          'Marriage certificate if applicable',
          'Paternity acknowledgment if unmarried',
        ],
        citizenshipRule: 'Ius sanguinis: Hungarian citizenship if at least one parent Hungarian',
        legalBasis: 'Act I of 2010 on Civil Registration',
        immigrantNotes: 'Registration mandatory. Children of non-Hungarian parents receive parents nationality. Hungary has simplified naturalization for ethnic Hungarians abroad.',
      ),
      paternity: PaternityRecognition(
        method: 'Married husband: automatic. Unmarried: acknowledgment at registrar or court. Judicial paternity determination.',
        legalBasis: 'Civil Code (Ptk.) 4:98-4:115',
        contestationPeriod: '5 years from birth; child unlimited',
        immigrantNotes: 'Acknowledgment straightforward at anyakönyvvezető. Foreign acknowledgment recognized under PIL rules.',
      ),
      guardianship: GuardianshipMinors(
        authority: 'Gyámhatóság (Guardianship Authority); Court',
        appointmentProcess: 'Gyámhatóság appoints guardian (gyám). Court involvement for contested or complex cases. Institutional guardianship available.',
        legalBasis: 'Civil Code (Ptk.) 4:224-4:247; Child Protection Act (Gyvt.)',
        unaccompaniedMinorNotes: 'Immigration authority notifies Gyámhatóság. Temporary guardian appointed. Placed in children homes. Guardian represents minor in asylum and legal proceedings.',
      ),
      hagueAbductionNotes: 'Central Authority: Ministry of Justice, Department of Private International Law, Kossuth Lajos tér 2-4, 1055 Budapest.',
      emergencyContacts: 'Police: 107; Emergency: 112; NANE DV: +36 80 505 101; Victim line: 06 80 225 225; Child helpline: 116 111',
    ),

    // ═══════════════════════════════════════════════════════════════════
    // 14. IRELAND (IE)
    // ═══════════════════════════════════════════════════════════════════
    CountryFamilyLaw(
      country: 'Ireland',
      countryCode: 'IE',
      marriage: MarriageRequirements(
        requiredDocuments: [
          'Valid passport',
          'Birth certificate',
          'Letter of Freedom to Marry (from home country embassy/consulate)',
          'PPS number',
          'Proof of address',
          'Decree of divorce/nullity if previously married',
        ],
        waitingPeriodDays: 5,
        minimumAge: 18,
        foreignDivorceRecognized: true,
        registrationAuthority: 'Registrar of Civil Marriages (HSE)',
        legalBasis: 'Civil Registration Act 2004; Family Law Act 1995',
        notes: 'Must give 3 months advance notification to Registrar. Registrar interviews both parties separately (anti-sham investigation per Immigration Act 2014). 5-day notice after approval.',
      ),
      divorce: DivorceRules(
        jurisdiction: 'Brussels IIter (Ireland participates); domicile in Ireland',
        applicableLaw: 'Irish law applies (Ireland does NOT participate in Rome III)',
        minimumSeparationMonths: 24,
        mutualConsentAvailable: false,
        courtType: 'Circuit Court or High Court',
        legalBasis: 'Family Law (Divorce) Act 1996, amended 2019; Constitution Art. 41.3.2',
        immigrantNotes: 'Constitutional right: 2-year living apart in previous 3 years required (reduced from 4 years in 2019 referendum). No mutual consent divorce as such — court must be satisfied no reasonable prospect of reconciliation. Proper provision for spouse/children required.',
      ),
      custody: ChildCustodyRules(
        applicableLaw: 'Irish law if child habitually resident in Ireland; Brussels IIter for jurisdiction',
        defaultCustodyType: 'Married parents: joint guardianship. Unmarried mother: automatic guardianship. Unmarried father: must apply (automatic if cohabiting 12+ months since 2016).',
        centralAuthority: 'Department of Justice — Central Authority for Child Abduction',
        hagueConventionStatus: 'Party since 1991',
        relocationRules: 'Guardian consent or court order required for relocation abroad',
        legalBasis: 'Guardianship of Infants Act 1964 (amended 2015); Children and Family Relationships Act 2015',
        immigrantNotes: 'Unmarried fathers: automatic guardianship if cohabiting 12+ months with mother after 2016 Act. Otherwise must apply to court or sign statutory declaration. Welfare of child paramount consideration.',
      ),
      childSupport: ChildSupportRules(
        calculationMethod: 'Court discretion; no formula. Based on means and needs. Typical range €50-250/week per child.',
        enforcementMechanism: 'Attachment of earnings order; enforcement through District Court',
        crossBorderEnforcement: 'EU Maintenance Regulation 4/2009 (Ireland participates)',
        centralAuthority: 'Department of Justice',
        legalBasis: 'Family Law (Maintenance of Spouses and Children) Act 1976; Family Law Act 1995',
        notes: 'No state maintenance advance scheme. One-parent family payment from social welfare provides partial support. Enforcement historically weak but improving.',
      ),
      domesticViolence: DomesticViolenceProtection(
        emergencyOrderAvailable: true,
        emergencyOrderMaxDays: 8,
        protectionOrderCourt: 'District Court issues safety order (5 years), barring order (3 years), interim barring order, protection order, emergency barring order',
        shelterAccess: 'Safe Ireland network: ~20 refuges nationwide',
        emergencyHotline: 'Women\'s Aid: 1800 341 900 (24/7); Men\'s Aid: 01 554 3811',
        availableToImmigrants: true,
        legalBasis: 'Domestic Violence Act 2018',
        specialImmigrantProtections: 'DV Act 2018 extended protection to cohabitants and dating relationships. DV victims on dependent visa: can apply for independent immigration permission. Legal aid available. Tusla (Child and Family Agency) provides support.',
      ),
      parentalLeave: ParentalLeaveRights(
        maternityLeaveDays: 182,
        paternityLeaveDays: 14,
        parentalLeaveDays: 63,
        payRate: 'Maternity benefit: €274/week (2024). Paternity: €274/week. Parent\'s benefit: €274/week for 9 weeks each parent (transferable 5 weeks since 2024).',
        availableToImmigrants: true,
        residencyRequirement: 'PRSI contributions; legal employment in Ireland',
        legalBasis: 'Maternity Protection Act 1994; Paternity Leave and Benefit Act 2016; Parent\'s Leave and Benefit Act 2019',
      ),
      birthRegistration: BirthRegistration(
        deadlineDays: 90,
        registrationOffice: 'HSE Civil Registration Office',
        requiredDocuments: [
          'Birth notification form (from hospital)',
          'Parents PPS numbers',
          'Parents photo ID',
          'Marriage certificate if applicable',
        ],
        citizenshipRule: 'Irish citizen if born on island of Ireland to Irish/British parent, or to parent with 3 years legal residence. Since 2005: not automatic ius soli.',
        legalBasis: 'Civil Registration Act 2004; Irish Nationality and Citizenship Act 1956 (amended 2004)',
        immigrantNotes: 'Since 2005 referendum: child born in Ireland NOT automatically Irish citizen unless parent has 3 years reckonable legal residence. Asylum/student time generally does not count.',
      ),
      paternity: PaternityRecognition(
        method: 'Married father: automatic. Unmarried: joint re-registration of birth, or court declaration of parentage, or statutory declaration.',
        legalBasis: 'Status of Children Act 1987; Children and Family Relationships Act 2015',
        contestationPeriod: 'No statutory time limit for declaring parentage',
        immigrantNotes: 'DNA testing available through court order. Re-registration of birth to add father requires mother consent or court order.',
      ),
      guardianship: GuardianshipMinors(
        authority: 'District Court; Tusla (Child and Family Agency)',
        appointmentProcess: 'Court appoints guardian. Tusla may apply for care orders. Testamentary guardian by will.',
        legalBasis: 'Guardianship of Infants Act 1964; Child Care Act 1991',
        unaccompaniedMinorNotes: 'Tusla takes into care. Placed in dedicated residential units or foster care. Social worker assigned. Referral to International Protection Office with legal representative. Tusla equity of care principle.',
      ),
      hagueAbductionNotes: 'Central Authority: Department of Justice, International Child Abduction Unit, Bishop\'s Square, Redmond Hill, Dublin 2. High Court has exclusive jurisdiction for return applications.',
      emergencyContacts: 'Police (Gardaí): 999/112; Women\'s Aid: 1800 341 900; Men\'s Aid: 01 554 3811; Childline: 1800 666 666; Tusla: 0818 176 176',
    ),

    // ═══════════════════════════════════════════════════════════════════
    // 15. ITALY (IT)
    // ═══════════════════════════════════════════════════════════════════
    CountryFamilyLaw(
      country: 'Italy',
      countryCode: 'IT',
      marriage: MarriageRequirements(
        requiredDocuments: [
          'Valid passport',
          'Birth certificate (apostilled)',
          'Nulla osta (certificate of no impediment) from consulate',
          'Atto notorio (affidavit of single status)',
          'Residence permit if applicable',
          'Divorce decree if previously married',
        ],
        waitingPeriodDays: 11,
        minimumAge: 18,
        foreignDivorceRecognized: true,
        registrationAuthority: 'Ufficio di Stato Civile (Civil Status Office) at Comune',
        legalBasis: 'Civil Code Art. 79-142',
        notes: 'Pubblicazioni (banns) posted 11 days before marriage. Both civil and concordat (religious) marriages legal. Comune residence requirement for one party.',
      ),
      divorce: DivorceRules(
        jurisdiction: 'Brussels IIter; habitual residence rules',
        applicableLaw: 'Rome III: party choice; default common habitual residence',
        minimumSeparationMonths: 6,
        mutualConsentAvailable: true,
        courtType: 'Tribunale Ordinario; since 2014: also before sindaco (mayor) or negoziazione assistita (lawyer negotiation)',
        legalBasis: 'Law 898/1970 (Divorce); Law 162/2014 (simplified); Civil Code; Rome III',
        immigrantNotes: 'Two-step process: separation then divorce. Mutual consent separation: 6 months before divorce. Contested separation: 12 months before divorce. Since 2015: shortened from 3 years. Negoziazione assistita (assisted negotiation by lawyers) possible since 2014.',
      ),
      custody: ChildCustodyRules(
        applicableLaw: 'Law of child habitual residence per Brussels IIter',
        defaultCustodyType: 'Affidamento condiviso (shared custody) since Law 54/2006 — default rule. Both parents maintain responsibility.',
        centralAuthority: 'Ministero della Giustizia — Dipartimento per la Giustizia Minorile e di Comunità',
        hagueConventionStatus: 'Party since 1995',
        relocationRules: 'Relocation of child requires agreement of both parents or court authorization',
        legalBasis: 'Civil Code Art. 337-bis to 337-octies; Law 54/2006',
        immigrantNotes: 'Shared custody is strong default since 2006. Collocamento prevalente (primary residence) with one parent plus significant time with other. Tribunale per i Minorenni handles cases involving unmarried parents.',
      ),
      childSupport: ChildSupportRules(
        calculationMethod: 'Court discretion based on principle of maintaining child\'s standard of living. No official formula. Typically €200-500/month per child plus 50% of extraordinary expenses.',
        enforcementMechanism: 'Court enforcement, wage garnishment, property seizure; criminal offense for non-payment (Art. 570 Criminal Code)',
        crossBorderEnforcement: 'EU Maintenance Regulation 4/2009',
        centralAuthority: 'Ministero della Giustizia',
        legalBasis: 'Civil Code Art. 337-ter; Criminal Code Art. 570',
        notes: 'No state advance maintenance system. Criminal sanctions for persistent non-payment. Assegno divorzile (spousal maintenance) criteria reformed by Corte di Cassazione 2018.',
      ),
      domesticViolence: DomesticViolenceProtection(
        emergencyOrderAvailable: true,
        emergencyOrderMaxDays: 0,
        protectionOrderCourt: 'Judge issues ordine di protezione (Art. 342-bis CC): removal from home + no approach. Ammonimento del Questore (police warning) also available.',
        shelterAccess: 'Centri antiviolenza (anti-violence centers) and case rifugio (shelters): ~370 centers, ~260 shelters nationwide',
        emergencyHotline: '1522 (24/7, multilingual antiviolenza hotline)',
        availableToImmigrants: true,
        legalBasis: 'Civil Code Art. 342-bis, 342-ter; Law 119/2013 (Codice Rosso); Law 69/2019',
        specialImmigrantProtections: 'Codice Rosso (2019): fast-track processing of DV complaints. DV victims receive permesso di soggiorno per protezione (Art. 18-bis TU Immigration). 1522 hotline in multiple languages. Undocumented victims protected.',
      ),
      parentalLeave: ParentalLeaveRights(
        maternityLeaveDays: 150,
        paternityLeaveDays: 10,
        parentalLeaveDays: 330,
        payRate: 'Maternity: 80% of salary (INPS). Parental leave: 30% for up to 9 months total (6 months per parent). First month at 80% since 2023.',
        availableToImmigrants: true,
        residencyRequirement: 'INPS social insurance coverage; legal employment',
        legalBasis: 'D.Lgs. 151/2001 (Testo Unico maternità/paternità); Budget Law 2023 reforms',
      ),
      birthRegistration: BirthRegistration(
        deadlineDays: 10,
        registrationOffice: 'Ufficio di Stato Civile of Comune where birth occurred; or at hospital',
        requiredDocuments: [
          'Attestazione di nascita from hospital',
          'Parents identity documents',
          'Marriage certificate if applicable',
          'Riconoscimento (acknowledgment) if unmarried',
        ],
        citizenshipRule: 'Ius sanguinis: Italian citizenship if at least one parent Italian. Very limited ius soli (stateless children or children of unknown parents only).',
        legalBasis: 'D.P.R. 396/2000 (Civil Status Regulation); Citizenship Law 91/1992',
        immigrantNotes: 'Ius soli reform debated but not yet passed. Children of immigrants must wait until 18 to apply for citizenship (if continuously resident since birth). Registration mandatory regardless of parents status.',
      ),
      paternity: PaternityRecognition(
        method: 'Married: automatic presumption. Unmarried: riconoscimento (acknowledgment) at civil registrar, before or after birth. Judicial declaration.',
        legalBasis: 'Civil Code Art. 231-290',
        contestationPeriod: '5 years for disavowal by husband. Child: unlimited.',
        immigrantNotes: 'Riconoscimento can be done at Italian consulate abroad. Since 2012 reform: all children have equal status regardless of parents marital status.',
      ),
      guardianship: GuardianshipMinors(
        authority: 'Tribunale per i Minorenni (Juvenile Court); municipal social services',
        appointmentProcess: 'Juvenile Court appoints tutore (guardian). Social services (Servizi Sociali) monitor and support.',
        legalBasis: 'Civil Code Art. 343-389; Law 184/1983 on adoption and foster care',
        unaccompaniedMinorNotes: 'Law 47/2017 (Zampa Law): comprehensive protection for UAMs. Immediate first reception. Municipality appoints voluntary guardian. No pushback of UAMs. Right to education and healthcare. Dedicated guardianship system with trained volunteers.',
      ),
      hagueAbductionNotes: 'Central Authority: Ministero della Giustizia, Dipartimento per la Giustizia Minorile e di Comunità, Via Damiano Chiesa 24, 00136 Roma.',
      emergencyContacts: 'Police (Carabinieri): 112; Emergency: 112; Antiviolenza: 1522; Child line: 114 (Telefono Azzurro); 19696',
    ),

    // ═══════════════════════════════════════════════════════════════════
    // 16. LATVIA (LV)
    // ═══════════════════════════════════════════════════════════════════
    CountryFamilyLaw(
      country: 'Latvia',
      countryCode: 'LV',
      marriage: MarriageRequirements(
        requiredDocuments: [
          'Valid passport',
          'Birth certificate',
          'Certificate of no impediment or sworn statement',
          'Divorce/death certificate if applicable',
          'Proof of legal residence',
        ],
        waitingPeriodDays: 30,
        minimumAge: 18,
        foreignDivorceRecognized: true,
        registrationAuthority: 'Dzimtsarakstu nodaļa (Civil Registry) or notary or minister of religion',
        legalBasis: 'Civil Law Part 1, Family Law; Civil Registry Law',
        notes: 'Application 1 month before ceremony. Since 2013 also possible before notary. Religious marriages (registered denominations) have legal force.',
      ),
      divorce: DivorceRules(
        jurisdiction: 'Brussels IIter; habitual residence',
        applicableLaw: 'Rome III: party choice or habitual residence',
        minimumSeparationMonths: 0,
        mutualConsentAvailable: true,
        courtType: 'Rajona tiesa (District Court); or notary for mutual consent without children disputes',
        legalBasis: 'Civil Law Art. 71-79; Notary Act; Rome III',
        immigrantNotes: 'Mutual consent: notary can dissolve if no property/children disputes. Contested: court based on irretrievable breakdown. No mandatory separation.',
      ),
      custody: ChildCustodyRules(
        applicableLaw: 'Law of child habitual residence per Brussels IIter',
        defaultCustodyType: 'Joint parental power (kopīga aizgādība). After divorce: court determines; joint custody possible.',
        centralAuthority: 'Ministry of Justice — Division of International Cooperation',
        hagueConventionStatus: 'Party since 2002',
        relocationRules: 'Both parents must consent; Bāriņtiesa (orphan court) mediates disputes',
        legalBasis: 'Civil Law Art. 177-205; Protection of the Rights of the Child Law',
        immigrantNotes: 'Bāriņtiesa (orphan/custody court) plays important role — extrajudicial body at municipality level that handles custody, access, guardianship matters. Free of charge.',
      ),
      childSupport: ChildSupportRules(
        calculationMethod: 'Minimum: 25% of state minimum wage per child per month. Court can set higher based on means.',
        enforcementMechanism: 'Court enforcement, wage garnishment; Uzturlīdzekļu garantiju fonds (Maintenance Guarantee Fund)',
        crossBorderEnforcement: 'EU Maintenance Regulation 4/2009',
        centralAuthority: 'Ministry of Justice',
        legalBasis: 'Civil Law Art. 179-181; Maintenance Guarantee Fund Law',
        notes: 'State Maintenance Guarantee Fund pays minimum maintenance (€107.50/month per child, 2024) if parent defaults. Available to residents regardless of nationality.',
      ),
      domesticViolence: DomesticViolenceProtection(
        emergencyOrderAvailable: true,
        emergencyOrderMaxDays: 8,
        protectionOrderCourt: 'Police issue temporary protection order; court extends. Pagaidu aizsardzība pret vardarbību (temporary protection against violence).',
        shelterAccess: 'Municipal crisis centers and NGO shelters available',
        emergencyHotline: '116 006 (victim helpline); 8000 2012 (MARTA Centre DV)',
        availableToImmigrants: true,
        legalBasis: 'Civil Procedure Law Chapter 30.5 (since 2014); Criminal Law',
        specialImmigrantProtections: 'Protection available regardless of immigration status. Temporary residence permit possible for DV victims. Municipal social services assist.',
      ),
      parentalLeave: ParentalLeaveRights(
        maternityLeaveDays: 112,
        paternityLeaveDays: 10,
        parentalLeaveDays: 547,
        payRate: 'Maternity: 80% of average salary. Childcare benefit: 60% of salary until 1 year, then flat rate until 1.5 years.',
        availableToImmigrants: true,
        residencyRequirement: 'Socially insured in Latvia',
        legalBasis: 'Labour Law Art. 154-156; State Social Insurance Benefits Law',
      ),
      birthRegistration: BirthRegistration(
        deadlineDays: 30,
        registrationOffice: 'Dzimtsarakstu nodaļa (Civil Registry Office)',
        requiredDocuments: [
          'Hospital birth certificate',
          'Parents identity documents',
          'Marriage certificate if applicable',
        ],
        citizenshipRule: 'Ius sanguinis: Latvian citizen if at least one parent Latvian. Children of non-citizens of Latvia (nepilsoņi) also eligible.',
        legalBasis: 'Civil Registry Law; Citizenship Law',
        immigrantNotes: 'Significant non-citizen (nepilsoņi) population. Children born in Latvia to non-citizens can register as Latvian citizens. Since 2020 amendments: automatically Latvian if born to non-citizens.',
      ),
      paternity: PaternityRecognition(
        method: 'Married: automatic. Unmarried: joint statement to civil registry. Judicial establishment.',
        legalBasis: 'Civil Law Art. 146-155',
        contestationPeriod: '2 years from learning of circumstances; child unlimited until 2 years after majority',
        immigrantNotes: 'Joint declaration at civil registry. Foreign paternity recognized.',
      ),
      guardianship: GuardianshipMinors(
        authority: 'Bāriņtiesa (Orphan Court); District Court',
        appointmentProcess: 'Bāriņtiesa (municipal orphan court) appoints guardian. Court involvement for disputes.',
        legalBasis: 'Civil Law Art. 216-270; Bāriņtiesa Law',
        unaccompaniedMinorNotes: 'Bāriņtiesa appoints guardian. State Border Guard notifies upon entry. Placed in care institutions or foster families. Guardian assists in asylum process. OCMA (Office of Citizenship and Migration Affairs) coordinates.',
      ),
      hagueAbductionNotes: 'Central Authority: Ministry of Justice, Brīvības bulvāris 36, LV-1536 Riga.',
      emergencyContacts: 'Police: 110; Emergency: 112; Victim helpline: 116 006; Child helpline: 116 111',
    ),

    // ═══════════════════════════════════════════════════════════════════
    // 17. LITHUANIA (LT)
    // ═══════════════════════════════════════════════════════════════════
    CountryFamilyLaw(
      country: 'Lithuania',
      countryCode: 'LT',
      marriage: MarriageRequirements(
        requiredDocuments: [
          'Valid passport',
          'Birth certificate (apostilled)',
          'Certificate of no impediment from home state',
          'Proof of legal residence',
          'Dissolution proof if previously married',
        ],
        waitingPeriodDays: 30,
        minimumAge: 18,
        foreignDivorceRecognized: true,
        registrationAuthority: 'Civilinės metrikacijos skyrius (Civil Registry Office)',
        legalBasis: 'Civil Code Book 3 (Family Law)',
        notes: 'Application 1 month before ceremony. Both civil and religious marriages have legal force.',
      ),
      divorce: DivorceRules(
        jurisdiction: 'Brussels IIter; habitual residence',
        applicableLaw: 'Rome III: party choice; default habitual residence',
        minimumSeparationMonths: 0,
        mutualConsentAvailable: true,
        courtType: 'Apylinkės teismas (District Court)',
        legalBasis: 'Civil Code Art. 3.51-3.73; Rome III',
        immigrantNotes: 'Three types: mutual consent, fault of one spouse, living apart for 1+ year. Mutual consent: comprehensive agreement on property, children, support required. Court approves within 30 days.',
      ),
      custody: ChildCustodyRules(
        applicableLaw: 'Law of child habitual residence per Brussels IIter',
        defaultCustodyType: 'Joint parental authority. After divorce: court determines residence; joint authority continues unless restricted.',
        centralAuthority: 'Ministry of Justice — International Law Department',
        hagueConventionStatus: 'Party since 2003',
        relocationRules: 'Both parents must consent to international relocation; court decides disputes',
        legalBasis: 'Civil Code Art. 3.155-3.180; Law on Fundamentals of Protection of the Rights of the Child',
        immigrantNotes: 'Best interest standard. VTAS (State Child Rights Protection and Adoption Service) provides expertise. Child hearing from age 10.',
      ),
      childSupport: ChildSupportRules(
        calculationMethod: 'Court discretion; typically 25% of income for one child, up to 50% for three or more. Minimum tied to minimum subsistence level.',
        enforcementMechanism: 'Court enforcement, wage garnishment; Vaikų išlaikymo fondas (Children\'s Maintenance Fund)',
        crossBorderEnforcement: 'EU Maintenance Regulation 4/2009',
        centralAuthority: 'Ministry of Justice',
        legalBasis: 'Civil Code Art. 3.192-3.200; Children\'s Maintenance Fund Law',
        notes: 'Children\'s Maintenance Fund (since 2017) advances maintenance up to 1.2 basic social benefit amounts (~€60/month) if debtor defaults.',
      ),
      domesticViolence: DomesticViolenceProtection(
        emergencyOrderAvailable: true,
        emergencyOrderMaxDays: 15,
        protectionOrderCourt: 'Police issue protection order for 15 days. Court extends. DV prosecuted ex officio since 2011.',
        shelterAccess: 'Specialized assistance centers in every municipality',
        emergencyHotline: '8-800-11112 (women\'s helpline); 116 111 (child helpline)',
        availableToImmigrants: true,
        legalBasis: 'Law on Protection Against Domestic Violence 2011; Criminal Code Art. 140.1',
        specialImmigrantProtections: 'DV is public prosecution offense since 2011 (no victim complaint needed). Protection available to all residents. Specialized assistance centers provide shelter and support.',
      ),
      parentalLeave: ParentalLeaveRights(
        maternityLeaveDays: 126,
        paternityLeaveDays: 30,
        parentalLeaveDays: 730,
        payRate: 'Maternity: 77.58% of compensatory salary. Childcare: 77.58% until 1 year or 54.31% until 2 years (parent chooses).',
        availableToImmigrants: true,
        residencyRequirement: 'Social insurance contributions; legal employment',
        legalBasis: 'Labour Code Art. 130-133; Sickness and Maternity Social Insurance Act',
      ),
      birthRegistration: BirthRegistration(
        deadlineDays: 30,
        registrationOffice: 'Civilinės metrikacijos skyrius (Civil Registry Office) of municipality',
        requiredDocuments: [
          'Hospital birth certificate',
          'Parents identity documents',
          'Marriage certificate if applicable',
        ],
        citizenshipRule: 'Ius sanguinis: Lithuanian citizenship if at least one parent Lithuanian',
        legalBasis: 'Civil Code Book 2; Citizenship Law',
        immigrantNotes: 'Registration mandatory within 30 days. Child of non-Lithuanian parents registered with parents nationality.',
      ),
      paternity: PaternityRecognition(
        method: 'Married: automatic. Unmarried: joint statement to civil registry. Judicial paternity establishment.',
        legalBasis: 'Civil Code Art. 3.138-3.154',
        contestationPeriod: '1 year from learning of circumstances; child until 1 year after majority',
        immigrantNotes: 'Joint declaration at civil registry office. Foreign paternity recognized if not against public order.',
      ),
      guardianship: GuardianshipMinors(
        authority: 'District Court; VTAS (State Child Rights Protection and Adoption Service); municipal child rights protection',
        appointmentProcess: 'Municipal child rights division proposes; court appoints guardian (globėjas/rūpintojas).',
        legalBasis: 'Civil Code Art. 3.240-3.282',
        unaccompaniedMinorNotes: 'VTAS and municipal child rights divisions coordinate. Guardian appointed. Placed in care homes or foster families. Legal representation in asylum process provided.',
      ),
      hagueAbductionNotes: 'Central Authority: Ministry of Justice, Gedimino pr. 30/1, LT-01104 Vilnius.',
      emergencyContacts: 'Police: 112; Emergency: 112; Women helpline: 8-800-11112; Child line: 116 111',
    ),

    // ═══════════════════════════════════════════════════════════════════
    // 18. LUXEMBOURG (LU)
    // ═══════════════════════════════════════════════════════════════════
    CountryFamilyLaw(
      country: 'Luxembourg',
      countryCode: 'LU',
      marriage: MarriageRequirements(
        requiredDocuments: [
          'Valid passport',
          'Birth certificate (less than 6 months old)',
          'Certificate of no impediment (certificat de non-empêchement)',
          'Proof of domicile',
          'Divorce decree if applicable',
          'Certificat de coutume if required',
        ],
        waitingPeriodDays: 10,
        minimumAge: 18,
        foreignDivorceRecognized: true,
        registrationAuthority: 'Officier de l\'état civil at Commune',
        legalBasis: 'Civil Code Art. 63-76',
        notes: 'Publication of banns 10 days before. High proportion of cross-border marriages due to international population (~48% foreign residents).',
      ),
      divorce: DivorceRules(
        jurisdiction: 'Brussels IIter; habitual residence',
        applicableLaw: 'Rome III: party choice; default habitual residence',
        minimumSeparationMonths: 0,
        mutualConsentAvailable: true,
        courtType: 'Tribunal d\'arrondissement (District Court)',
        legalBasis: 'Civil Code Art. 229-310; Rome III; Law of 27 June 2018 (divorce reform)',
        immigrantNotes: 'Major 2018 reform: divorce for irretrievable breakdown (no separation period) or mutual consent. Fault-based divorce abolished. Process simplified significantly.',
      ),
      custody: ChildCustodyRules(
        applicableLaw: 'Law of child habitual residence per Brussels IIter',
        defaultCustodyType: 'Joint parental authority (autorité parentale conjointe). After divorce: joint unless court orders otherwise.',
        centralAuthority: 'Parquet Général — Ministère de la Justice',
        hagueConventionStatus: 'Party since 1987',
        relocationRules: 'Both parents must agree; court decides disputes',
        legalBasis: 'Civil Code Art. 371-387; Law of 27 June 2018',
        immigrantNotes: 'Joint authority strong default. Résidence alternée (alternating residence) possible. Juge aux affaires familiales decides. Highly international population means frequent cross-border issues.',
      ),
      childSupport: ChildSupportRules(
        calculationMethod: 'Court discretion based on means and needs. No official formula. Typically €300-600/month per child.',
        enforcementMechanism: 'Court enforcement, wage garnishment; Fonds national de solidarité (FNS) advances maintenance',
        crossBorderEnforcement: 'EU Maintenance Regulation 4/2009',
        centralAuthority: 'Parquet Général',
        legalBasis: 'Civil Code Art. 203-211',
        notes: 'FNS (Fonds national de solidarité) advances maintenance if debtor defaults and recovers from debtor. Available to all legal residents.',
      ),
      domesticViolence: DomesticViolenceProtection(
        emergencyOrderAvailable: true,
        emergencyOrderMaxDays: 14,
        protectionOrderCourt: 'Police issues expulsion order (14 days). Court extends protection.',
        shelterAccess: 'Foyers/shelters operated by Femmes en Détresse and other NGOs',
        emergencyHotline: 'Helpline 12 344 (Femmes en Détresse); Police: 113',
        availableToImmigrants: true,
        legalBasis: 'Law of 8 September 2003 on domestic violence (amended 2013)',
        specialImmigrantProtections: 'Police expulsion of abuser regardless of who owns/rents. DV victims can obtain independent residence permit. Shelters accept regardless of status. Multilingual support (French, German, Portuguese, English).',
      ),
      parentalLeave: ParentalLeaveRights(
        maternityLeaveDays: 112,
        paternityLeaveDays: 10,
        parentalLeaveDays: 180,
        payRate: 'Maternity: full salary (employer + CNS). Parental leave: flat rate replacement income based on working time (~€3,377/month full-time, 2024).',
        availableToImmigrants: true,
        residencyRequirement: 'Affiliated to Luxembourg social security; employed or self-employed',
        legalBasis: 'Labour Code Book III; Law of 3 November 2016 (parental leave reform)',
      ),
      birthRegistration: BirthRegistration(
        deadlineDays: 5,
        registrationOffice: 'Officier de l\'état civil of commune where birth occurred',
        requiredDocuments: [
          'Hospital birth certificate',
          'Parents IDs',
          'Marriage certificate if applicable',
          'Reconnaissance (acknowledgment) if unmarried',
        ],
        citizenshipRule: 'Ius sanguinis. Since 2009: double ius soli (child born in Luxembourg to parent also born in Luxembourg). Simplified naturalization after 5 years residence.',
        legalBasis: 'Civil Code; Nationality Law of 23 October 2008 (amended 2017)',
        immigrantNotes: 'Double ius soli since 2009. Liberal naturalization law (5 years residence, language requirement). ~48% of population is foreign — family law frequently involves cross-border elements.',
      ),
      paternity: PaternityRecognition(
        method: 'Married: automatic. Unmarried: reconnaissance at civil registry. Judicial establishment.',
        legalBasis: 'Civil Code Art. 311-342',
        contestationPeriod: 'Husband: 1 year from knowledge. Child: until 5 years after majority.',
        immigrantNotes: 'Reconnaissance can be done before birth. Commune may investigate for fraudulent reconnaissance.',
      ),
      guardianship: GuardianshipMinors(
        authority: 'Juge des tutelles at Tribunal d\'arrondissement',
        appointmentProcess: 'Family council (conseil de famille) convened. Juge des tutelles confirms guardian appointment.',
        legalBasis: 'Civil Code Art. 390-413',
        unaccompaniedMinorNotes: 'Office National de l\'Accueil (ONA) provides accommodation. Judge appoints administrator ad hoc. Red Cross and Caritas assist. Education and healthcare guaranteed.',
      ),
      hagueAbductionNotes: 'Central Authority: Parquet Général, Cité Judiciaire, L-2080 Luxembourg.',
      emergencyContacts: 'Police: 113; Emergency: 112; Femmes en Détresse: 12 344; Child helpline: 116 111',
    ),

    // ═══════════════════════════════════════════════════════════════════
    // 19. MALTA (MT)
    // ═══════════════════════════════════════════════════════════════════
    CountryFamilyLaw(
      country: 'Malta',
      countryCode: 'MT',
      marriage: MarriageRequirements(
        requiredDocuments: [
          'Valid passport',
          'Birth certificate',
          'Certificate of no impediment / single status',
          'Publication of banns',
          'Divorce decree if applicable',
        ],
        waitingPeriodDays: 0,
        minimumAge: 18,
        foreignDivorceRecognized: true,
        registrationAuthority: 'Marriage Registrar (Public Registry)',
        legalBasis: 'Marriage Act (Cap. 255); Civil Code',
        notes: 'Marriage banns published. Both civil and religious marriages legal. Malta legalized divorce only in 2011.',
      ),
      divorce: DivorceRules(
        jurisdiction: 'Brussels IIter; habitual residence',
        applicableLaw: 'Rome III: Malta participates since 2014',
        minimumSeparationMonths: 48,
        mutualConsentAvailable: true,
        courtType: 'Civil Court (Family Section)',
        legalBasis: 'Civil Code Art. 66A-66R (introduced 2011); Rome III',
        immigrantNotes: 'Divorce introduced only in 2011 by referendum. 4-year separation required (reduced from original 4 years effective immediately). Mediation mandatory before proceedings. Most restrictive in EU.',
      ),
      custody: ChildCustodyRules(
        applicableLaw: 'Law of child habitual residence per Brussels IIter',
        defaultCustodyType: 'Joint parental authority (potestà tal-ġenituri). Court decides custody arrangement upon separation.',
        centralAuthority: 'Ministry for Justice — Office of the Attorney General',
        hagueConventionStatus: 'Party since 2003',
        relocationRules: 'Consent of both parents or court order',
        legalBasis: 'Civil Code Art. 131-156',
        immigrantNotes: 'Best interest of child. Small jurisdiction — cases handled efficiently. Child advocate (avukat tat-tfal) appointed in proceedings.',
      ),
      childSupport: ChildSupportRules(
        calculationMethod: 'Court discretion based on needs and means. No formula.',
        enforcementMechanism: 'Court enforcement orders; wage garnishment',
        crossBorderEnforcement: 'EU Maintenance Regulation 4/2009',
        centralAuthority: 'Office of the Attorney General',
        legalBasis: 'Civil Code Art. 3-21',
        notes: 'No state advance maintenance system. Small jurisdiction facilitates enforcement.',
      ),
      domesticViolence: DomesticViolenceProtection(
        emergencyOrderAvailable: true,
        emergencyOrderMaxDays: 0,
        protectionOrderCourt: 'Court issues protection order. Police can act on emergency basis.',
        shelterAccess: 'Għabex (domestic violence agency) operates shelters; Appoġġ agency support',
        emergencyHotline: 'Victim support: 179; DV helpline: 179',
        availableToImmigrants: true,
        legalBasis: 'Domestic Violence Act (Cap. 481); Gender-Based Violence and Domestic Violence Act 2018',
        specialImmigrantProtections: 'Protection regardless of immigration status. Istanbul Convention ratified 2018. Appoġġ (social welfare agency) provides comprehensive support.',
      ),
      parentalLeave: ParentalLeaveRights(
        maternityLeaveDays: 126,
        paternityLeaveDays: 10,
        parentalLeaveDays: 120,
        payRate: 'Maternity: 14 weeks at full pay + 4 weeks unpaid. Parental leave: flat rate benefit.',
        availableToImmigrants: true,
        residencyRequirement: 'Social security contributions; legal employment',
        legalBasis: 'Employment and Industrial Relations Act (EIRA); Social Security Act',
      ),
      birthRegistration: BirthRegistration(
        deadlineDays: 15,
        registrationOffice: 'Public Registry (Director of Public Registry)',
        requiredDocuments: [
          'Hospital birth notification',
          'Parents IDs',
          'Marriage certificate if applicable',
        ],
        citizenshipRule: 'Ius sanguinis: Maltese if at least one parent Maltese. Born in Malta to parents lawfully resident for 5+ years also eligible.',
        legalBasis: 'Civil Code; Maltese Citizenship Act',
        immigrantNotes: 'Registration mandatory. Children born in Malta to non-Maltese parents: can apply for citizenship after continuous residence.',
      ),
      paternity: PaternityRecognition(
        method: 'Married: automatic. Unmarried: voluntary acknowledgment. Judicial declaration.',
        legalBasis: 'Civil Code Art. 67-86',
        contestationPeriod: '6 months from knowledge; child unlimited',
        immigrantNotes: 'Acknowledgment at Public Registry. Foreign recognition accepted.',
      ),
      guardianship: GuardianshipMinors(
        authority: 'Civil Court (Family Section); Appoġġ (social welfare)',
        appointmentProcess: 'Court appoints tutur (guardian). Appoġġ provides welfare reports and interim care.',
        legalBasis: 'Civil Code Art. 131-186',
        unaccompaniedMinorNotes: 'Agency for the Welfare of Asylum Seekers (AWAS) and Appoġġ coordinate. Guardian appointed. Placed in specialized accommodation. Legal representation for asylum.',
      ),
      hagueAbductionNotes: 'Central Authority: Office of the Attorney General, Palace, Republic Street, Valletta VLT 1110.',
      emergencyContacts: 'Police: 112; Emergency: 112; Support line: 179; Child helpline: 116 111',
    ),

    // ═══════════════════════════════════════════════════════════════════
    // 20. NETHERLANDS (NL)
    // ═══════════════════════════════════════════════════════════════════
    CountryFamilyLaw(
      country: 'Netherlands',
      countryCode: 'NL',
      marriage: MarriageRequirements(
        requiredDocuments: [
          'Valid passport',
          'Birth certificate (apostilled)',
          'Certificate of no impediment (verklaring van huwelijksbevoegdheid)',
          'BRP registration (Basisregistratie Personen)',
          'Divorce decree if applicable',
        ],
        waitingPeriodDays: 14,
        minimumAge: 18,
        foreignDivorceRecognized: true,
        registrationAuthority: 'Ambtenaar van de burgerlijke stand (Civil Registrar) at gemeente',
        legalBasis: 'Burgerlijk Wetboek (Civil Code) Book 1, Title 5',
        notes: 'Notice of intent 14 days before. Same-sex marriage since 2001 (first in world). Free choice of matrimonial property regime since 2018 (limited community default).',
      ),
      divorce: DivorceRules(
        jurisdiction: 'Brussels IIter; habitual residence',
        applicableLaw: 'Rome III: party choice; default common habitual residence, then nationality, then lex fori',
        minimumSeparationMonths: 0,
        mutualConsentAvailable: true,
        courtType: 'Rechtbank (District Court)',
        legalBasis: 'Civil Code Book 1, Art. 150-166; Rome III',
        immigrantNotes: 'Single ground: irretrievable breakdown (duurzame ontwrichting). No separation period. Mandatory lawyer for both/each party. Joint petition possible. Mediation encouraged. Legal aid (toevoeging) available.',
      ),
      custody: ChildCustodyRules(
        applicableLaw: 'Law of child habitual residence per Brussels IIter',
        defaultCustodyType: 'Joint parental authority (gezamenlijk gezag) continues after divorce. Mandatory parenting plan (ouderschapsplan) since 2009.',
        centralAuthority: 'Ministry of Justice — Centrum Internationale Kinderontvoering (Centre for International Child Abduction)',
        hagueConventionStatus: 'Party since 1990',
        relocationRules: 'Major: Court permission needed for international relocation. Verhuisperikelen case law well-developed.',
        legalBasis: 'Civil Code Book 1, Art. 245-277; Wet bevordering voortgezet ouderschap (2009)',
        immigrantNotes: 'Mandatory ouderschapsplan (parenting plan) for divorce with children — covers residence, access, information exchange, costs. Joint custody strong default. Centrum IKO specialized in abduction.',
      ),
      childSupport: ChildSupportRules(
        calculationMethod: 'Trema-normen (judicial guidelines): standardized calculation based on both parents income, needs of child, capacity to pay. Highly formalized.',
        enforcementMechanism: 'LBIO (Landelijk Bureau Inning Onderhoudsbijdragen) collects and enforces; wage garnishment',
        crossBorderEnforcement: 'EU Maintenance Regulation 4/2009; LBIO as intermediary body',
        centralAuthority: 'LBIO, Rotterdam',
        legalBasis: 'Civil Code Book 1, Art. 392-413; Trema rapport alimentatienormen',
        notes: 'LBIO provides efficient collection service. Child maintenance until 21 (one of the highest ages in EU). Formalized Trema calculation used by all courts.',
      ),
      domesticViolence: DomesticViolenceProtection(
        emergencyOrderAvailable: true,
        emergencyOrderMaxDays: 10,
        protectionOrderCourt: 'Burgemeester (mayor) issues huisverbod (temporary domestic ban) for 10 days, extendable to 28. Court issues longer restraining orders.',
        shelterAccess: 'Veilig Thuis (Safe at Home) regions; vrouwenopvang (women\'s shelters)',
        emergencyHotline: 'Veilig Thuis: 0800-2000 (24/7, free)',
        availableToImmigrants: true,
        legalBasis: 'Wet tijdelijk huisverbod (Temporary Domestic Ban Act) 2009; Wet maatschappelijke ondersteuning',
        specialImmigrantProtections: 'Huisverbod available regardless of immigration status. DV victims with dependent permit: can obtain independent permit after assessment. Veilig Thuis provides multilingual support. Raad voor de Kinderbescherming involved when children affected.',
      ),
      parentalLeave: ParentalLeaveRights(
        maternityLeaveDays: 112,
        paternityLeaveDays: 35,
        parentalLeaveDays: 630,
        payRate: 'Maternity: 100% (capped at max daily wage). Birth leave: 5 days 100% + 5 weeks 70%. Parental leave: 9 weeks at 70% (paid since 2022) + remainder unpaid.',
        availableToImmigrants: true,
        residencyRequirement: 'Employed in Netherlands; insured under Wet arbeid en zorg',
        legalBasis: 'Wet arbeid en zorg (Work and Care Act); 2022 reform implementing EU directive',
      ),
      birthRegistration: BirthRegistration(
        deadlineDays: 3,
        registrationOffice: 'Gemeente (municipality) where birth occurred',
        requiredDocuments: [
          'ID of declarant',
          'Hospital birth notification',
          'Trouwboekje (marriage booklet) or erkenning (acknowledgment)',
        ],
        citizenshipRule: 'Ius sanguinis. Dutch citizenship if Dutch parent. Since 2003: also automatic if Dutch father acknowledges before age 7. Optional procedure for later.',
        legalBasis: 'Civil Code Book 1; Rijkswet op het Nederlanderschap (Nationality Act)',
        immigrantNotes: 'Registration within 3 working days. Children of immigrants: can apply for Dutch citizenship after 5 years legal residence and reaching 18. Earlier naturalization possible with Dutch parent.',
      ),
      paternity: PaternityRecognition(
        method: 'Married: automatic (wettelijk vermoeden). Unmarried: erkenning (acknowledgment) at gemeente, notary, or court. Judicial establishment (gerechtelijke vaststelling).',
        legalBasis: 'Civil Code Book 1, Art. 198-207',
        contestationPeriod: '5 years from awareness. Child: 3 years from learning of circumstances.',
        immigrantNotes: 'Erkenning before birth recommended. Mother must consent if child under 16. Court can substitute consent. Anti-fraud provisions for immigration-motivated erkenning.',
      ),
      guardianship: GuardianshipMinors(
        authority: 'Rechtbank (District Court); Raad voor de Kinderbescherming (Child Protection Board)',
        appointmentProcess: 'Raad voor de Kinderbescherming investigates and recommends. Court appoints voogd (guardian). Certified guardian institution (gecertificeerde instelling) or individual.',
        legalBasis: 'Civil Code Book 1, Art. 295-336; Youth Act 2015',
        unaccompaniedMinorNotes: 'Nidos (specialized guardian organization for UAMs) provides guardian. COA provides housing. Nidos guardian assists in asylum process, education, integration. Unique Dutch system recognized internationally.',
      ),
      hagueAbductionNotes: 'Central Authority: Centrum Internationale Kinderontvoering (Centrum IKO), Postbus 90603, 2509 LP The Hague. The Hague District Court has exclusive jurisdiction.',
      emergencyContacts: 'Police: 0900-8844; Emergency: 112; Veilig Thuis: 0800-2000; Kindertelefoon: 0800-0432; Centrum IKO: +31 70 381 2321',
    ),

    // ═══════════════════════════════════════════════════════════════════
    // 21. POLAND (PL)
    // ═══════════════════════════════════════════════════════════════════
    CountryFamilyLaw(
      country: 'Poland',
      countryCode: 'PL',
      marriage: MarriageRequirements(
        requiredDocuments: [
          'Valid passport',
          'Birth certificate (apostilled, sworn translation)',
          'Certificate of legal capacity to marry (zdolność do zawarcia małżeństwa) from home country or court exemption',
          'Proof of legal stay',
          'Divorce decree / death certificate if applicable',
        ],
        waitingPeriodDays: 30,
        minimumAge: 18,
        foreignDivorceRecognized: true,
        registrationAuthority: 'Urząd Stanu Cywilnego (Civil Registry Office)',
        legalBasis: 'Family and Guardianship Code (Kodeks rodzinny i opiekuńczy, KRO) Art. 1-22',
        notes: '30-day wait after filing. Both civil and concordat (Catholic) marriages legal. Court can exempt from certificate of capacity requirement.',
      ),
      divorce: DivorceRules(
        jurisdiction: 'Brussels IIter; habitual residence. Polish court if last common residence was in Poland.',
        applicableLaw: 'Rome III: Poland does NOT participate. Polish PIL Act 2011 determines applicable law (common nationality, then habitual residence).',
        minimumSeparationMonths: 0,
        mutualConsentAvailable: true,
        courtType: 'Sąd Okręgowy (Regional Court)',
        legalBasis: 'KRO Art. 56-61; PIL Act 2011; Art. 54 KRO (separation alternative)',
        immigrantNotes: 'Ground: complete and permanent breakdown (zupełny i trwały rozkład). Court determines fault (may be mutual, one party, or no-fault). Fault affects alimony. No separation period required. Legal separation (separacja) also available as alternative.',
      ),
      custody: ChildCustodyRules(
        applicableLaw: 'Law of child habitual residence per Brussels IIter',
        defaultCustodyType: 'Joint parental authority (władza rodzicielska) during marriage. After divorce: court may maintain joint, limit one parent, or award sole custody.',
        centralAuthority: 'Ministry of Justice — Department of International Cooperation and Human Rights',
        hagueConventionStatus: 'Party since 1992',
        relocationRules: 'Matters of significance (istotne sprawy) require consent of both parents or court decision. Relocation abroad is significant matter.',
        legalBasis: 'KRO Art. 92-113',
        immigrantNotes: 'Court typically restricts one parent\'s authority to specific decisions. Porozumienie rodzicielskie (parental agreement) possible. Free legal aid for low-income through Nieodpłatna pomoc prawna system.',
      ),
      childSupport: ChildSupportRules(
        calculationMethod: 'Court discretion based on justified needs of child and earning capacity of parent. No formula. Typical PLN 500-1500/month per child.',
        enforcementMechanism: 'Komornik (bailiff) enforcement; Fundusz Alimentacyjny (Maintenance Fund)',
        crossBorderEnforcement: 'EU Maintenance Regulation 4/2009',
        centralAuthority: 'Ministry of Justice',
        legalBasis: 'KRO Art. 128-144; Maintenance Fund Act',
        notes: 'Fundusz Alimentacyjny advances up to PLN 500/month per child if debtor defaults (income threshold applies). Persistent non-payment: criminal offense under Art. 209 Criminal Code (niealimentacja).',
      ),
      domesticViolence: DomesticViolenceProtection(
        emergencyOrderAvailable: true,
        emergencyOrderMaxDays: 14,
        protectionOrderCourt: 'Police issue natychmiastowy zakaz zbliżania (immediate restraining order) since 2020. Court issues longer protection orders.',
        shelterAccess: 'Specjalistyczne Ośrodki Wsparcia (specialized support centers) in each powiat; shelters available',
        emergencyHotline: 'Niebieska Linia (Blue Line): 800 12 00 02 (24/7, free)',
        availableToImmigrants: true,
        legalBasis: 'Act on Counteracting Domestic Violence (Ustawa o przeciwdziałaniu przemocy domowej) 2005, amended 2023; Criminal Code Art. 207',
        specialImmigrantProtections: 'Since 2020: police can immediately evict abuser (nakaz opuszczenia mieszkania). Protection regardless of immigration status. Niebieska Karta (Blue Card) procedure documents DV. 2023 reform strengthened protections.',
      ),
      parentalLeave: ParentalLeaveRights(
        maternityLeaveDays: 140,
        paternityLeaveDays: 14,
        parentalLeaveDays: 294,
        payRate: 'Maternity: 100% for 20 weeks. Parental: 70% for 41 weeks (or 81.5% if declared upfront). 9 weeks non-transferable per parent since 2023.',
        availableToImmigrants: true,
        residencyRequirement: 'Social insurance (ZUS) coverage; legal employment',
        legalBasis: 'Labour Code Art. 180-183; 2023 amendment implementing EU Work-Life Balance Directive',
      ),
      birthRegistration: BirthRegistration(
        deadlineDays: 21,
        registrationOffice: 'Urząd Stanu Cywilnego where birth occurred',
        requiredDocuments: [
          'Hospital birth card (karta urodzenia)',
          'Parents identity documents',
          'Marriage certificate if applicable',
        ],
        citizenshipRule: 'Ius sanguinis: Polish citizenship if at least one parent is Polish citizen',
        legalBasis: 'Civil Registry Act (Prawo o aktach stanu cywilnego); Citizenship Act 2009',
        immigrantNotes: 'Hospital submits birth card electronically. Registration within 21 days. Children of non-Polish parents: parents nationality. Polish Karta Polaka holders have facilitated naturalization.',
      ),
      paternity: PaternityRecognition(
        method: 'Married: automatic presumption (domniemanie ojcostwa). Unmarried: acknowledgment (uznanie ojcostwa) before USC registrar, court, or consul. Judicial establishment.',
        legalBasis: 'KRO Art. 62-86',
        contestationPeriod: 'Husband: 1 year from learning of birth. Mother: 1 year from birth. Child: 3 years from age 18.',
        immigrantNotes: 'Acknowledgment at USC straightforward. Consular acknowledgment possible abroad. Anti-fraud scrutiny for immigration-motivated cases.',
      ),
      guardianship: GuardianshipMinors(
        authority: 'Sąd opiekuńczy (Guardianship Court — division of District Court)',
        appointmentProcess: 'Court appoints opiekun (guardian). Can be individual or institution. Kurator (supervisor) may be appointed additionally.',
        legalBasis: 'KRO Art. 145-174',
        unaccompaniedMinorNotes: 'Court appoints kurator (curator) for UAM upon notification by Border Guard or police. Placed in opieka zastępcza (foster care) or ośrodek opiekuńczo-wychowawczy (care center). Curator represents in asylum procedure.',
      ),
      hagueAbductionNotes: 'Central Authority: Ministry of Justice, Al. Ujazdowskie 11, 00-950 Warsaw. Designated family courts for return proceedings.',
      emergencyContacts: 'Police: 997; Emergency: 112; Niebieska Linia DV: 800 12 00 02; Child helpline: 116 111',
    ),

    // ═══════════════════════════════════════════════════════════════════
    // 22. PORTUGAL (PT)
    // ═══════════════════════════════════════════════════════════════════
    CountryFamilyLaw(
      country: 'Portugal',
      countryCode: 'PT',
      marriage: MarriageRequirements(
        requiredDocuments: [
          'Valid passport',
          'Birth certificate',
          'Certificate of legal capacity to marry (certidão de capacidade matrimonial)',
          'Proof of legal residence',
          'Divorce/death certificate if applicable',
        ],
        waitingPeriodDays: 0,
        minimumAge: 18,
        foreignDivorceRecognized: true,
        registrationAuthority: 'Conservatória do Registo Civil (Civil Registry Office)',
        legalBasis: 'Civil Code Art. 1577-1651; Civil Registry Code',
        notes: 'Same-sex marriage since 2010. De facto union (união de facto) recognized after 2 years of cohabitation. Processo preliminar (preliminary process) at conservatória.',
      ),
      divorce: DivorceRules(
        jurisdiction: 'Brussels IIter; habitual residence',
        applicableLaw: 'Rome III: Portugal participates',
        minimumSeparationMonths: 0,
        mutualConsentAvailable: true,
        courtType: 'Conservatória do Registo Civil (mutual consent) or Tribunal de Família e Menores (contested)',
        legalBasis: 'Civil Code Art. 1773-1793; Rome III',
        immigrantNotes: 'Mutual consent: at Conservatória without court, even with children (if agreement approved by Ministério Público). Contested: single ground of irretrievable breakdown. No separation required. Very accessible process.',
      ),
      custody: ChildCustodyRules(
        applicableLaw: 'Law of child habitual residence per Brussels IIter',
        defaultCustodyType: 'Joint exercise of parental responsibilities (exercício conjunto das responsabilidades parentais) — default since 2008',
        centralAuthority: 'Direcção-Geral da Reinserção e Serviços Prisionais (DGRSP) under Ministry of Justice',
        hagueConventionStatus: 'Party since 1983',
        relocationRules: 'Questions of particular importance require agreement of both parents; relocation abroad is particular importance matter',
        legalBasis: 'Civil Code Art. 1877-1920; Law 61/2008 (major reform)',
        immigrantNotes: 'Joint parental responsibilities strong default since 2008. Residência alternada (alternating residence) increasingly favored. Comissões de Proteção de Crianças e Jovens (CPCJ) provide community-level child protection.',
      ),
      childSupport: ChildSupportRules(
        calculationMethod: 'Court discretion based on needs and means. FGADM (Fundo de Garantia de Alimentos Devidos a Menores) as state guarantee.',
        enforcementMechanism: 'Court enforcement; FGADM advances maintenance; wage garnishment',
        crossBorderEnforcement: 'EU Maintenance Regulation 4/2009',
        centralAuthority: 'DGRSP',
        legalBasis: 'Civil Code Art. 2003-2023; Law 75/98 (FGADM)',
        notes: 'FGADM guarantees maintenance advance through Social Security when parent defaults. Amount set by court. Available to all resident children.',
      ),
      domesticViolence: DomesticViolenceProtection(
        emergencyOrderAvailable: true,
        emergencyOrderMaxDays: 3,
        protectionOrderCourt: 'Court issues coercion measures within 48 hours. Teleassistência (teleprotection) program. Electronic ankle bracelet monitoring.',
        shelterAccess: 'Casas de abrigo (shelters) across country; CIG coordinates',
        emergencyHotline: '800 202 148 (Serviço de Informação às Vítimas de Violência Doméstica, 24/7)',
        availableToImmigrants: true,
        legalBasis: 'Law 112/2009 (DV legal framework); Criminal Code Art. 152',
        specialImmigrantProtections: 'DV is public crime (crime público) — prosecution without victim complaint. Autonomous residence permit for DV victims (Art. 107 Immigration Law). Teleassistência (24/7 electronic protection). Shelters accept regardless of status.',
      ),
      parentalLeave: ParentalLeaveRights(
        maternityLeaveDays: 42,
        paternityLeaveDays: 28,
        parentalLeaveDays: 150,
        payRate: 'Initial parental leave: 120 days at 100% or 150 days at 80%. Father mandatory 28 days. Extended parental leave until child 6 at 25%.',
        availableToImmigrants: true,
        residencyRequirement: 'Social security contributions; legal employment',
        legalBasis: 'Labour Code Art. 33-65; Decree-Law 91/2009',
      ),
      birthRegistration: BirthRegistration(
        deadlineDays: 20,
        registrationOffice: 'Conservatória do Registo Civil; many hospitals have on-site registration (Nascer Cidadão program)',
        requiredDocuments: [
          'Hospital birth notification',
          'Parents identity documents',
          'Marriage certificate if applicable',
        ],
        citizenshipRule: 'Ius sanguinis + ius soli: Portuguese if one parent Portuguese. Also: born in Portugal to parent legally resident for 2+ years (since 2020 reform) OR to parent born in Portugal.',
        legalBasis: 'Civil Registry Code; Nationality Law (Lei da Nacionalidade), amended 2020',
        immigrantNotes: 'Progressive nationality law reforms (2006, 2015, 2018, 2020): child born in Portugal to parent with 2+ years legal residence at birth is Portuguese. One of most inclusive ius soli regimes in EU.',
      ),
      paternity: PaternityRecognition(
        method: 'Married: automatic. Unmarried: perfilhação (acknowledgment) at civil registry, notary, or court. Judicial establishment.',
        legalBasis: 'Civil Code Art. 1796-1873',
        contestationPeriod: 'Husband: 3 years from knowledge. Child: until 10 years after majority.',
        immigrantNotes: 'Perfilhação straightforward. Ministério Público can initiate paternity investigation on behalf of child. Foreign acknowledgment recognized.',
      ),
      guardianship: GuardianshipMinors(
        authority: 'Tribunal de Família e Menores; CPCJ (Comissões de Proteção)',
        appointmentProcess: 'CPCJ handles first level of protection. Court appoints tutor if needed. Institutional or individual guardianship.',
        legalBasis: 'Civil Code Art. 1921-1962; Law 147/99 (LPCJP — Child Protection Law)',
        unaccompaniedMinorNotes: 'SEF/AIMA refers to CPCJ. Court appoints legal representative. Placed in Casa de Acolhimento Residencial (residential care) or foster family. Refugee Council assists in asylum process.',
      ),
      hagueAbductionNotes: 'Central Authority: DGRSP, Travessa da Cruz do Torel, 1, 1150-122 Lisboa.',
      emergencyContacts: 'Police: 112; Emergency: 112; DV line: 800 202 148; Child helpline: 116 111; SOS Criança: 116 111',
    ),

    // ═══════════════════════════════════════════════════════════════════
    // 23. ROMANIA (RO)
    // ═══════════════════════════════════════════════════════════════════
    CountryFamilyLaw(
      country: 'Romania',
      countryCode: 'RO',
      marriage: MarriageRequirements(
        requiredDocuments: [
          'Valid passport',
          'Birth certificate (apostilled, translated)',
          'Medical certificate (certificat medical prenupțial)',
          'Declaration of no impediment (declarație pe proprie răspundere)',
          'Divorce/death decree if applicable',
          'Proof of legal stay',
        ],
        waitingPeriodDays: 10,
        minimumAge: 18,
        foreignDivorceRecognized: true,
        registrationAuthority: 'Ofițer de stare civilă (Civil Status Officer) at primărie (town hall)',
        legalBasis: 'Civil Code (Codul civil) Art. 258-313',
        notes: 'Declaration filed 10 days before. Medical certificate mandatory. Only civil marriage has legal effect. Prenuptial agreement (convenție matrimonială) possible since 2011 Civil Code.',
      ),
      divorce: DivorceRules(
        jurisdiction: 'Brussels IIter; habitual residence',
        applicableLaw: 'Rome III: Romania participates',
        minimumSeparationMonths: 0,
        mutualConsentAvailable: true,
        courtType: 'Judecătorie (First Instance Court); or civil status officer/notary for mutual consent without minor children',
        legalBasis: 'Civil Code Art. 373-404; Rome III',
        immigrantNotes: 'Mutual consent without minor children: administrative divorce at primărie or notary. With children: court required. Fault-based or irretrievable breakdown grounds available. No separation period required.',
      ),
      custody: ChildCustodyRules(
        applicableLaw: 'Law of child habitual residence per Brussels IIter',
        defaultCustodyType: 'Joint parental authority (autoritate părintească comună). After divorce: joint exercise is default since 2011 Civil Code.',
        centralAuthority: 'Ministry of Justice — Direction for International Law and Judicial Cooperation',
        hagueConventionStatus: 'Party since 1993',
        relocationRules: 'Both parents must agree on child domicile/residence; court decides disputes',
        legalBasis: 'Civil Code Art. 483-512; Law 272/2004 on protection of child rights',
        immigrantNotes: 'Joint authority default. DGASPC (Direcția Generală de Asistență Socială și Protecția Copilului) at county level provides child protection services. Court must consult child over age 10.',
      ),
      childSupport: ChildSupportRules(
        calculationMethod: 'Civil Code Art. 529: up to 25% of net income for 1 child, 33% for 2, 50% for 3+',
        enforcementMechanism: 'Court enforcement, wage garnishment; criminal offense for non-payment (Art. 378 Criminal Code)',
        crossBorderEnforcement: 'EU Maintenance Regulation 4/2009',
        centralAuthority: 'Ministry of Justice',
        legalBasis: 'Civil Code Art. 516-534; Criminal Code Art. 378',
        notes: 'Fixed percentages in Civil Code provide clear framework. Criminal sanctions for abandoning family/non-payment. No state advance system.',
      ),
      domesticViolence: DomesticViolenceProtection(
        emergencyOrderAvailable: true,
        emergencyOrderMaxDays: 5,
        protectionOrderCourt: 'Police issue ordin de protecție provizoriu (provisional protection order) for 5 days. Court issues protection order up to 6 months.',
        shelterAccess: 'Centres for DV victims in each county; NGO shelters',
        emergencyHotline: '0800 500 333 (free DV helpline); 116 006 (victim support)',
        availableToImmigrants: true,
        legalBasis: 'Law 217/2003 on preventing and combating DV (amended 2018, 2020); Law 174/2018',
        specialImmigrantProtections: 'Protection regardless of immigration status. Since 2018: police can issue provisional protection order on the spot. Electronic monitoring of offender possible. DV victims can receive temporary residence.',
      ),
      parentalLeave: ParentalLeaveRights(
        maternityLeaveDays: 126,
        paternityLeaveDays: 15,
        parentalLeaveDays: 730,
        payRate: 'Maternity (prenatal + postnatal): 85% of average income. Childcare leave: 85% of net income (min RON 2,500/month, max RON 8,500/month, 2024) until child 2 years.',
        availableToImmigrants: true,
        residencyRequirement: 'Legal residence; 12 months of income in last 2 years',
        legalBasis: 'OUG 111/2010 on parental leave; Labour Code',
      ),
      birthRegistration: BirthRegistration(
        deadlineDays: 30,
        registrationOffice: 'Serviciul de Stare Civilă at primărie where birth occurred',
        requiredDocuments: [
          'Hospital birth certificate (certificat medical constatator)',
          'Parents identity documents',
          'Marriage certificate if applicable',
        ],
        citizenshipRule: 'Ius sanguinis: Romanian citizenship if at least one parent Romanian',
        legalBasis: 'Law 119/1996 on civil status documents; Citizenship Law 21/1991',
        immigrantNotes: 'Registration within 30 days (extendable). Late registration possible through court. Child of non-Romanian parents gets parents nationality.',
      ),
      paternity: PaternityRecognition(
        method: 'Married: automatic presumption. Unmarried: recunoaștere (acknowledgment) at civil registry. Judicial establishment.',
        legalBasis: 'Civil Code Art. 408-434',
        contestationPeriod: 'Husband: 3 years from learning. Child: unlimited (since 2011 Civil Code reform).',
        immigrantNotes: 'Acknowledgment at SPCLEP/civil registry office. Foreign acknowledgment recognized if valid under applicable law.',
      ),
      guardianship: GuardianshipMinors(
        authority: 'Instanța de tutelă (Guardianship Court / Judecătorie); DGASPC',
        appointmentProcess: 'Guardianship court appoints tutore. DGASPC provides child protection services and supervision.',
        legalBasis: 'Civil Code Art. 110-163; Law 272/2004',
        unaccompaniedMinorNotes: 'DGASPC takes child into emergency placement. Court appoints guardian. Placed in placement centers or professional maternal assistants (foster carers). IGI (General Inspectorate for Immigration) coordinates with DGASPC for asylum-seeking UAMs.',
      ),
      hagueAbductionNotes: 'Central Authority: Ministry of Justice, Str. Apolodor 17, Sector 5, 050741 Bucharest.',
      emergencyContacts: 'Police: 112; Emergency: 112; DV line: 0800 500 333; Child helpline: 116 111; Victim support: 116 006',
    ),

    // ═══════════════════════════════════════════════════════════════════
    // 24. SLOVAKIA (SK)
    // ═══════════════════════════════════════════════════════════════════
    CountryFamilyLaw(
      country: 'Slovakia',
      countryCode: 'SK',
      marriage: MarriageRequirements(
        requiredDocuments: [
          'Valid passport',
          'Birth certificate (apostilled, translated by court translator)',
          'Certificate of legal capacity to marry from home country',
          'Proof of legal residence',
          'Divorce/death certificate if applicable',
        ],
        waitingPeriodDays: 7,
        minimumAge: 18,
        foreignDivorceRecognized: true,
        registrationAuthority: 'Matričný úrad (Registry Office)',
        legalBasis: 'Family Act (Zákon o rodine) 36/2005',
        notes: 'Both civil and church marriages legal. Minimum 7 days between application and ceremony. Court can exempt from certificate requirement.',
      ),
      divorce: DivorceRules(
        jurisdiction: 'Brussels IIter; habitual residence',
        applicableLaw: 'Rome III: Slovakia does NOT participate. Slovak PIL determines applicable law.',
        minimumSeparationMonths: 0,
        mutualConsentAvailable: true,
        courtType: 'Okresný súd (District Court)',
        legalBasis: 'Family Act §22-27; PIL Act 97/1963',
        immigrantNotes: 'Ground: serious disruption of relations with no prospect of restoration. No separation period. Court must always decide custody before granting divorce if minor children. Mandatory conciliation attempt.',
      ),
      custody: ChildCustodyRules(
        applicableLaw: 'Law of child habitual residence per Brussels IIter',
        defaultCustodyType: 'Joint parental rights and duties. After divorce: court must decide (entrust to one parent, alternating, or joint custody).',
        centralAuthority: 'Centrum pre medzinárodnoprávnu ochranu detí a mládeže (Centre for International Legal Protection of Children and Youth)',
        hagueConventionStatus: 'Party since 2001 (succession from Czechoslovakia, reaccession)',
        relocationRules: 'Both parents must agree on matters of significance; relocation is significant matter',
        legalBasis: 'Family Act §28-39',
        immigrantNotes: 'Slovak Centre for International Legal Protection of Children (CIPC) in Bratislava handles all cross-border child cases. Efficient cooperation. Alternating custody available since 2010 amendment.',
      ),
      childSupport: ChildSupportRules(
        calculationMethod: 'Minimum: 30% of life subsistence minimum per child (~€35/month). Court determines based on means and needs. Typically €100-300/month.',
        enforcementMechanism: 'Court enforcement, wage garnishment; náhradné výživné (substitute maintenance) from state',
        crossBorderEnforcement: 'EU Maintenance Regulation 4/2009; CIPC assists',
        centralAuthority: 'CIPC Bratislava',
        legalBasis: 'Family Act §62-81',
        notes: 'Substitute maintenance (náhradné výživné) from state since 2020 if parent defaults. Amount limited. CIPC assists with cross-border maintenance recovery.',
      ),
      domesticViolence: DomesticViolenceProtection(
        emergencyOrderAvailable: true,
        emergencyOrderMaxDays: 14,
        protectionOrderCourt: 'Police issue vykázanie (eviction from dwelling) for 14 days. Court issues neodkladné opatrenie (emergency measure).',
        shelterAccess: 'Krízové centrá (crisis centers) and bezpečné ženské domy (safe women\'s houses)',
        emergencyHotline: 'Národná linka pre ženy zažívajúce násilie: 0800 212 212',
        availableToImmigrants: true,
        legalBasis: 'Police Force Act §27a (vykázanie); Civil Procedure Code (neodkladné opatrenie)',
        specialImmigrantProtections: 'Police eviction regardless of property ownership. Protection available to all. Koordinačno-metodické centrum for DV provides training and coordination.',
      ),
      parentalLeave: ParentalLeaveRights(
        maternityLeaveDays: 238,
        paternityLeaveDays: 14,
        parentalLeaveDays: 1095,
        payRate: 'Materské (maternity benefit): 75% of daily assessment base for 34 weeks. Rodičovský príspevok (parental allowance): ~€345/month until child 3 years.',
        availableToImmigrants: true,
        residencyRequirement: 'Social insurance; permanent or temporary residence',
        legalBasis: 'Social Insurance Act 461/2003; Parental Allowance Act 571/2009',
      ),
      birthRegistration: BirthRegistration(
        deadlineDays: 3,
        registrationOffice: 'Matričný úrad where birth occurred',
        requiredDocuments: [
          'Hospital birth report',
          'Parents ID documents',
          'Marriage certificate if applicable',
        ],
        citizenshipRule: 'Ius sanguinis: Slovak citizenship if at least one parent Slovak',
        legalBasis: 'Registry Act 154/1994; Citizenship Act 40/1993',
        immigrantNotes: 'Hospital reports birth to registry. Registration within 3 working days. Non-Slovak children receive parents nationality.',
      ),
      paternity: PaternityRecognition(
        method: 'Married: automatic presumption (300-day rule). Unmarried: súhlasné vyhlásenie (concordant declaration) at registry. Judicial determination.',
        legalBasis: 'Family Act §84-96',
        contestationPeriod: 'Husband: 3 years from learning. Child: 3 years from age 18.',
        immigrantNotes: 'Concordant declaration at matričný úrad. Foreign paternity recognized under PIL rules.',
      ),
      guardianship: GuardianshipMinors(
        authority: 'Okresný súd (District Court); Úrad práce, sociálnych vecí a rodiny (Office of Labour, Social Affairs and Family)',
        appointmentProcess: 'Court appoints poručník (guardian). Social affairs office provides supervision. Kolízny opatrovník (collision guardian) for proceedings.',
        legalBasis: 'Family Act §56-61; Social Protection of Children Act',
        unaccompaniedMinorNotes: 'Social affairs office takes into care. Court appoints guardian. Placed in detský domov (children\'s home) or foster care. Guardian represents in asylum process. CIPC coordinates cross-border matters.',
      ),
      hagueAbductionNotes: 'Central Authority: Centrum pre medzinárodnoprávnu ochranu detí a mládeže (CIPC), Špitálska 8, 814 55 Bratislava.',
      emergencyContacts: 'Police: 158; Emergency: 112; DV line: 0800 212 212; Child helpline: 116 111',
    ),

    // ═══════════════════════════════════════════════════════════════════
    // 25. SLOVENIA (SI)
    // ═══════════════════════════════════════════════════════════════════
    CountryFamilyLaw(
      country: 'Slovenia',
      countryCode: 'SI',
      marriage: MarriageRequirements(
        requiredDocuments: [
          'Valid passport',
          'Birth certificate (apostilled)',
          'Certificate of no impediment from home country',
          'Proof of legal residence',
          'Divorce/death certificate if applicable',
        ],
        waitingPeriodDays: 30,
        minimumAge: 18,
        foreignDivorceRecognized: true,
        registrationAuthority: 'Upravna enota (Administrative Unit)',
        legalBasis: 'Family Code (Družinski zakonik) 2017, effective 2019',
        notes: 'New Family Code 2017 (effective April 2019) modernized family law. Same-sex marriage since 2023 (via Constitutional Court). 30 days between application and ceremony.',
      ),
      divorce: DivorceRules(
        jurisdiction: 'Brussels IIter; habitual residence',
        applicableLaw: 'Rome III: Slovenia participates',
        minimumSeparationMonths: 0,
        mutualConsentAvailable: true,
        courtType: 'Okrožno sodišče (District Court); or notary for mutual consent without minor children',
        legalBasis: 'Family Code Art. 96-103; Rome III',
        immigrantNotes: 'Mutual consent without children: notarial divorce possible since 2019 Family Code. With children or contested: court. Ground: unbearable conditions. No separation period. Mediation encouraged.',
      ),
      custody: ChildCustodyRules(
        applicableLaw: 'Law of child habitual residence per Brussels IIter',
        defaultCustodyType: 'Joint parental care (skupna starševska skrb). After divorce: joint or sole by agreement or court decision.',
        centralAuthority: 'Ministry of Labour, Family, Social Affairs and Equal Opportunities',
        hagueConventionStatus: 'Party since 1994 (succession from Yugoslavia)',
        relocationRules: 'Important matters require consent of both parents; international relocation requires agreement or court order',
        legalBasis: 'Family Code Art. 135-176',
        immigrantNotes: 'CSD (Center za socialno delo — Social Work Centre) plays central role in family disputes. Mandatory preliminary meeting at CSD before court proceedings. Child participation recognized.',
      ),
      childSupport: ChildSupportRules(
        calculationMethod: 'Court discretion guided by child needs and parent capacity. Guidelines exist but not binding.',
        enforcementMechanism: 'Court enforcement; Javni štipendijski, razvojni, invalidski in preživninski sklad (Public Fund) advances maintenance',
        crossBorderEnforcement: 'EU Maintenance Regulation 4/2009',
        centralAuthority: 'Ministry of Labour, Family, Social Affairs and Equal Opportunities',
        legalBasis: 'Family Code Art. 183-206; Public Fund for Maintenance Act',
        notes: 'Public Fund (Preživninski sklad) advances maintenance if debtor defaults. Available to residents regardless of nationality. Support until 18, or 26 if in education.',
      ),
      domesticViolence: DomesticViolenceProtection(
        emergencyOrderAvailable: true,
        emergencyOrderMaxDays: 2,
        protectionOrderCourt: 'Police issue ukrep prepovedi približevanja (restraining order) for 48 hours. Court extends. Court issues protection measures.',
        shelterAccess: 'Varne hiše (safe houses) and krizni centri (crisis centers) available',
        emergencyHotline: 'SOS telefon: 080 11 55 (DV helpline)',
        availableToImmigrants: true,
        legalBasis: 'Domestic Violence Prevention Act (ZPND) 2008; Police Tasks and Powers Act',
        specialImmigrantProtections: 'Protection regardless of status. DV victims may obtain independent residence permit. CSD (Social Work Centre) provides comprehensive support. Safe houses accessible to all.',
      ),
      parentalLeave: ParentalLeaveRights(
        maternityLeaveDays: 105,
        paternityLeaveDays: 30,
        parentalLeaveDays: 260,
        payRate: 'Maternity: 100% of average salary. Paternity: 100% for 15 days paid, 15 days at partial pay. Parental leave: 100% of average salary.',
        availableToImmigrants: true,
        residencyRequirement: 'Parental protection insurance; legal residence',
        legalBasis: 'Parental Protection and Family Benefits Act (ZSDP-1)',
      ),
      birthRegistration: BirthRegistration(
        deadlineDays: 15,
        registrationOffice: 'Upravna enota (Administrative Unit) where birth occurred',
        requiredDocuments: [
          'Hospital birth notification',
          'Parents identity documents',
          'Marriage certificate if applicable',
        ],
        citizenshipRule: 'Ius sanguinis: Slovenian citizenship if at least one parent Slovenian citizen',
        legalBasis: 'Registry Act; Citizenship Act',
        immigrantNotes: 'Hospital notifies Administrative Unit. Registration within 15 days. Children of non-Slovenian parents: parents nationality.',
      ),
      paternity: PaternityRecognition(
        method: 'Married: automatic. Unmarried: acknowledgment (priznanje očetovstva) at CSD or Administrative Unit. Judicial establishment.',
        legalBasis: 'Family Code Art. 112-134',
        contestationPeriod: '5 years from knowledge. Child: until 5 years after majority.',
        immigrantNotes: 'Acknowledgment at CSD or Administrative Unit straightforward. CSD explains rights and consequences.',
      ),
      guardianship: GuardianshipMinors(
        authority: 'CSD (Social Work Centre); Okrožno sodišče (District Court)',
        appointmentProcess: 'CSD appoints guardian (skrbnik) for minor. Court involvement for contested cases.',
        legalBasis: 'Family Code Art. 231-269',
        unaccompaniedMinorNotes: 'CSD appoints legal guardian. Placed in crisis center or foster family. Guardian represents in asylum procedure. Slovenian Philanthropy (Slovenska filantropija) provides integration support.',
      ),
      hagueAbductionNotes: 'Central Authority: Ministry of Labour, Family, Social Affairs and Equal Opportunities, Štukljeva cesta 44, 1000 Ljubljana.',
      emergencyContacts: 'Police: 113; Emergency: 112; SOS DV: 080 11 55; Child helpline: 116 111',
    ),

    // ═══════════════════════════════════════════════════════════════════
    // 26. SPAIN (ES)
    // ═══════════════════════════════════════════════════════════════════
    CountryFamilyLaw(
      country: 'Spain',
      countryCode: 'ES',
      marriage: MarriageRequirements(
        requiredDocuments: [
          'Valid passport',
          'Birth certificate (apostilled, translated by sworn translator)',
          'Certificado de capacidad matrimonial or equivalent from home country',
          'Certificado de empadronamiento (municipal registration)',
          'Divorce/death decree if applicable',
          'Fe de vida y estado (certificate of life and marital status)',
        ],
        waitingPeriodDays: 0,
        minimumAge: 18,
        foreignDivorceRecognized: true,
        registrationAuthority: 'Registro Civil (Civil Registry) — Juez de Paz, Alcalde, or Notario',
        legalBasis: 'Civil Code Art. 42-80; Voluntary Jurisdiction Law 2015',
        notes: 'Expediente matrimonial (pre-marriage investigation) required. Since 2015: marriage before notary possible. Same-sex marriage since 2005. Autonomous communities may have own civil law.',
      ),
      divorce: DivorceRules(
        jurisdiction: 'Brussels IIter; habitual residence. Also Spanish court if both nationals.',
        applicableLaw: 'Rome III: Spain participates',
        minimumSeparationMonths: 3,
        mutualConsentAvailable: true,
        courtType: 'Juzgado de Primera Instancia (Court of First Instance); or notary for mutual consent without minor children',
        legalBasis: 'Civil Code Art. 81-89; Ley 15/2005 (express divorce); Rome III',

        immigrantNotes: 'Very accessible: 3 months from marriage, no fault, no separation. Mutual consent via notary since 2015 if no minor children or disabled dependents. Convenio regulador (regulatory agreement) required with children. Legal aid (justicia gratuita) for those qualifying.',
      ),
      custody: ChildCustodyRules(
        applicableLaw: 'Law of child habitual residence per Brussels IIter',
        defaultCustodyType: 'Patria potestad (parental authority) shared by default. Custodia compartida (shared custody) increasingly default in many Autonomous Communities.',
        centralAuthority: 'Ministry of Justice — Subdirección General de Cooperación Jurídica Internacional',
        hagueConventionStatus: 'Party since 1987',
        relocationRules: 'Relocation abroad with child requires other parent consent or judicial authorization',
        legalBasis: 'Civil Code Art. 90-96, 154-171; various Autonomous Community laws',
        immigrantNotes: 'Custodia compartida (shared custody) is default in Aragón, Cataluña, Navarra, Comunitat Valenciana, País Vasco. National Civil Code: court can grant shared custody even without agreement. Regional variations important.',
      ),
      childSupport: ChildSupportRules(
        calculationMethod: 'Court discretion. Tables published by CGPJ (Consejo General del Poder Judicial) available online as guidance but not binding.',
        enforcementMechanism: 'Court enforcement, wage garnishment, asset seizure; Fondo de Garantía de Pensiones advances maintenance',
        crossBorderEnforcement: 'EU Maintenance Regulation 4/2009',
        centralAuthority: 'Ministry of Justice — Subdirección General de Cooperación Jurídica Internacional',
        legalBasis: 'Civil Code Art. 142-153; Real Decreto-ley 1/2011 (Fondo de Garantía)',
        notes: 'Fondo de Garantía del Pago de Alimentos advances up to €100/month per child for 18 months if debtor defaults (income threshold). CGPJ online tables widely referenced.',
      ),
      domesticViolence: DomesticViolenceProtection(
        emergencyOrderAvailable: true,
        emergencyOrderMaxDays: 3,
        protectionOrderCourt: 'Juzgado de Violencia sobre la Mujer (specialized DV court) issues orden de protección within 72 hours',
        shelterAccess: 'Red de Casas de Acogida (shelter network) in each Autonomous Community',
        emergencyHotline: '016 (24/7, free, multilingual gender violence helpline); 112',
        availableToImmigrants: true,
        legalBasis: 'Ley Orgánica 1/2004 de Medidas de Protección Integral contra la Violencia de Género; amended by LO 10/2022',
        specialImmigrantProtections: 'Comprehensive LO 1/2004: specialized courts, prosecutors, police units (UFAM/EMUME). DV victims receive independent residence and work permit regardless of immigration status (Art. 19 LO 4/2000). 016 in 52 languages. Renta Activa de Inserción for DV victims.',
      ),
      parentalLeave: ParentalLeaveRights(
        maternityLeaveDays: 112,
        paternityLeaveDays: 112,
        parentalLeaveDays: 1095,
        payRate: 'Birth/adoption leave: 100% of regulatory base for 16 weeks each parent (equal since 2021). Unpaid excedencia up to 3 years with job reservation.',
        availableToImmigrants: true,
        residencyRequirement: 'Social security affiliation; legal employment. Special provisions for domestic workers.',
        legalBasis: 'Workers Statute Art. 48; Real Decreto-ley 6/2019 (equal leave)',
      ),
      birthRegistration: BirthRegistration(
        deadlineDays: 10,
        registrationOffice: 'Registro Civil; since 2023: electronic notification from hospital to Registro Civil',
        requiredDocuments: [
          'Hospital notification (electronic since 2023)',
          'Parents ID/passports',
          'Libro de Familia or marriage certificate',
        ],
        citizenshipRule: 'Ius sanguinis + limited ius soli: Spanish if parent Spanish. Born in Spain to foreign parents: Spanish if parents stateless, or if neither parent\'s country grants citizenship. Child of parent born in Spain: Spanish.',
        legalBasis: 'Civil Code Art. 17-19; Civil Registry Law 2011 (LRC 20/2011)',
        immigrantNotes: 'Double ius soli: child born in Spain to parent also born in Spain is automatically Spanish. Born to residents: can claim Spanish nationality after 1 year of age if resident. Liberal provisions for naturalization (10 years, reduced to 2 for Latin American/other nationals).',
      ),
      paternity: PaternityRecognition(
        method: 'Married: automatic. Unmarried: reconocimiento (acknowledgment) at Registro Civil, notary, or testamentary. Judicial filiation.',
        legalBasis: 'Civil Code Art. 108-141',
        contestationPeriod: '1 year from registration. Child: unlimited during lifetime.',
        immigrantNotes: 'Reconocimiento at Registro Civil or before notary. Flexible system. Foreign recognition generally accepted.',
      ),
      guardianship: GuardianshipMinors(
        authority: 'Juzgado de Primera Instancia; Entidad Pública (regional child protection)',
        appointmentProcess: 'Entidad Pública assumes tutela (guardianship) by ministerio de la ley for abandoned children. Court appoints individual tutor.',
        legalBasis: 'Civil Code Art. 199-238; LO 1/1996 Protection of Minors (reformed 2015)',
        unaccompaniedMinorNotes: 'Autonomous Community child protection service (Entidad Pública) assumes automatic tutela. Age determination. Placed in centros de acogida. Since LO 8/2021: residence and work authorization at 18 facilitated. Specific protocol for UAMs. Defensor del Menor oversees.',
      ),
      hagueAbductionNotes: 'Central Authority: Ministry of Justice, Subdirección General de Cooperación Jurídica Internacional, San Bernardo 62, 28015 Madrid.',
      emergencyContacts: 'Police: 091/092; Emergency: 112; Gender violence: 016 (52 languages); Child helpline: 116 111; ANAR: 900 20 20 10',
    ),

    // ═══════════════════════════════════════════════════════════════════
    // 27. SWEDEN (SE)
    // ═══════════════════════════════════════════════════════════════════
    CountryFamilyLaw(
      country: 'Sweden',
      countryCode: 'SE',
      marriage: MarriageRequirements(
        requiredDocuments: [
          'Valid passport',
          'Hindersprövning (certificate of no impediment) from Skatteverket',
          'Birth certificate from home country',
          'Proof that prior marriage dissolved',
          'Folkbokföring (population registration) if resident',
        ],
        waitingPeriodDays: 0,
        minimumAge: 18,
        foreignDivorceRecognized: true,
        registrationAuthority: 'Skatteverket (Swedish Tax Agency) issues hindersprövning; ceremony by vigselförrättare',
        legalBasis: 'Äktenskapsbalken (Marriage Code) 1987:230',
        notes: 'Hindersprövning valid 4 months. Ceremony by civil or religious officiant. Same-sex marriage since 2009. No minimum residency to marry.',
      ),
      divorce: DivorceRules(
        jurisdiction: 'Brussels IIter; habitual residence; Nordic Marriage Convention for Nordic citizens',
        applicableLaw: 'Rome III: Sweden does NOT participate. Swedish law generally applied. Nordic Convention for Nordic couples.',
        minimumSeparationMonths: 6,
        mutualConsentAvailable: true,
        courtType: 'Tingsrätt (District Court)',
        legalBasis: 'Marriage Code Ch. 5; not bound by Rome III',
        immigrantNotes: 'Mutual consent without children under 16: immediate divorce. With children under 16 or if one party objects: 6-month betänketid (reconsideration period). Very simple process — no fault, no grounds investigation. Legal aid (rättshjälp) available.',
      ),
      custody: ChildCustodyRules(
        applicableLaw: 'Law of child habitual residence; Swedish law if child in Sweden (not strictly bound by Brussels IIter for jurisdiction but follows it in practice)',
        defaultCustodyType: 'Gemensam vårdnad (joint custody) default. Continues after separation unless changed. Strong preference for maintaining joint custody.',
        centralAuthority: 'Ministry for Foreign Affairs (Utrikesdepartementet, UD)',
        hagueConventionStatus: 'Party since 1989',
        relocationRules: 'Joint custody: both parents must agree on child residence. Moving away without consent may constitute wrongful retention. Notification obligation.',
        legalBasis: 'Föräldrabalken (Children and Parents Code) Ch. 6',
        immigrantNotes: 'Joint custody extremely strong default — courts reluctant to change to sole custody. Samarbetssamtal (cooperation talks through familjerätten/municipality) mandatory before court. Barnets bästa (best interest of child) overriding principle. Child right to be heard.',
      ),
      childSupport: ChildSupportRules(
        calculationMethod: 'Försäkringskassan guidelines: based on both parents income and standard cost of child (standardbelopp linked to prisbasbelopp). Typically SEK 1,573-3,094/month per child (2024).',
        enforcementMechanism: 'Försäkringskassan pays underhållsstöd (maintenance support) and recovers from liable parent; Kronofogden (Enforcement Authority) enforces',
        crossBorderEnforcement: 'EU Maintenance Regulation: Sweden participates with reservation (not bound by Hague Protocol for applicable law). Bilateral Nordic agreement.',
        centralAuthority: 'Ministry for Foreign Affairs; Försäkringskassan for maintenance',
        legalBasis: 'Children and Parents Code Ch. 7; Social Insurance Code (Socialförsäkringsbalken)',
        notes: 'Underhållsstöd: Försäkringskassan pays SEK 1,573/month per child (2024) if parent does not pay. Recovers from debtor based on income. Available to all resident children regardless of nationality.',
      ),
      domesticViolence: DomesticViolenceProtection(
        emergencyOrderAvailable: true,
        emergencyOrderMaxDays: 0,
        protectionOrderCourt: 'Kontaktförbud (restraining order) issued by åklagare (prosecutor). Extended kontaktförbud med villkor om elektronisk övervakning (with electronic monitoring) since 2018.',
        shelterAccess: 'Kvinnojourer (women\'s shelters) ~200+ nationwide; Roks and Unizon umbrella organizations',
        emergencyHotline: 'Kvinnofridslinjen: 020-50 50 50 (24/7, multilingual)',
        availableToImmigrants: true,
        legalBasis: 'Kontaktförbudslagen (Restraining Order Act) 1988:688; Brottsbalken (Criminal Code) Ch. 4a (grov kvinnofridskränkning)',
        specialImmigrantProtections: 'Unique grov kvinnofridskränkning (gross violation of integrity) offense since 1998. DV victims on anknytning (family reunification permit): can receive own permit after assessment (Utlänningslag Ch. 5 §16). Kvinnofridslinjen in 20+ languages. Shelters open regardless of status.',
      ),
      parentalLeave: ParentalLeaveRights(
        maternityLeaveDays: 0,
        paternityLeaveDays: 0,
        parentalLeaveDays: 480,
        payRate: 'Föräldrapenning: 480 days per child shared between parents. 390 days at ~80% of income (max SEK 1,116/day), 90 days at SEK 180/day. 90 days non-transferable per parent.',
        availableToImmigrants: true,
        residencyRequirement: 'Covered by Swedish social insurance (folkbokförd in Sweden)',
        legalBasis: 'Socialförsäkringsbalken (Social Insurance Code); Föräldraledighetslag (Parental Leave Act)',
      ),
      birthRegistration: BirthRegistration(
        deadlineDays: 14,
        registrationOffice: 'Skatteverket (Tax Agency) — hospital notifies automatically; parents register name',
        requiredDocuments: [
          'Hospital birth notification (automatic to Skatteverket)',
          'Parents personnummer (personal ID)',
          'Name registration within 3 months',
        ],
        citizenshipRule: 'Ius sanguinis: Swedish citizenship if mother Swedish, or father Swedish if married to mother, or father Swedish if child born in Sweden (since 2015 automatic even if unmarried).',
        legalBasis: 'Folkbokföringslag; Swedish Citizenship Act (Medborgarskapslag 2001:82, amended 2015)',
        immigrantNotes: 'Hospital notifies Skatteverket automatically. Child gets personnummer. Since 2015: child born in Sweden to Swedish father automatically Swedish (regardless of marriage). Children of immigrants: can apply for Swedish citizenship after meeting residence requirements.',
      ),
      paternity: PaternityRecognition(
        method: 'Married: automatic (faderskapspresumtion). Unmarried: bekräftelse (acknowledgment) approved by socialnämnden (social welfare board). Judicial establishment.',
        legalBasis: 'Children and Parents Code Ch. 1',
        contestationPeriod: 'No statutory time limit for child. Father/mother: court discretion.',
        immigrantNotes: 'Socialnämnden (social welfare board) must approve all paternity acknowledgments. Proactive: socialnämnden has duty to establish paternity for all children born in Sweden. Very child-protective system.',
      ),
      guardianship: GuardianshipMinors(
        authority: 'Tingsrätt (District Court); Socialnämnden (Social Welfare Board); Överförmyndare (Chief Guardian)',
        appointmentProcess: 'Court appoints god man (trustee) or särskild förordnad vårdnadshavare (specially appointed custodian). Överförmyndaren supervises.',
        legalBasis: 'Children and Parents Code Ch. 6; Föräldrabalken Ch. 11 (god man)',
        unaccompaniedMinorNotes: 'Municipality assigns god man (trustee) immediately. Överförmyndaren oversees. Migrationsverket handles asylum with god man support. After permanent status: kommun appoints särskild förordnad vårdnadshavare (special custodian) to replace god man. Comprehensive support system.',
      ),
      hagueAbductionNotes: 'Central Authority: Ministry for Foreign Affairs (UD), Utrikesdepartementet, 103 39 Stockholm. Swedish courts generally comply with 6-week target.',
      emergencyContacts: 'Police: 114 14; Emergency: 112; Kvinnofridslinjen: 020-50 50 50; Barnens rätt i samhället (BRIS): 116 111; Stödlinjen: 020-22 00 60',
    ),
  ];
}
