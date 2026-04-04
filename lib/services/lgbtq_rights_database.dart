// LGBTQ+ Rights Database for all 27 EU Countries
// Comprehensive data for immigrants and asylum seekers
// Last updated: 2026-04
//
// Sources: ILGA-Europe Annual Review (2025), Rainbow Europe Map & Index,
// FRA (EU Agency for Fundamental Rights) LGBTI Survey II (2024),
// UNHCR Guidelines on International Protection No. 9 (Claims to Refugee
// Status based on Sexual Orientation and/or Gender Identity),
// EU Directive 2013/32/EU (Asylum Procedures Directive),
// EU Directive 2011/95/EU (Qualification Directive - recast),
// Yogyakarta Principles (2006) and Yogyakarta Principles Plus 10 (2017),
// ECHR case law (especially Dudgeon v. UK, Goodwin v. UK, Taddeucci v. Italy),
// Transgender Europe (TGEU) Trans Rights Map, ORAM (Organization for Refuge,
// Asylum & Migration), national ministry data and legislation.

// ============================================================
// DATA MODEL
// ============================================================

enum MarriageStatus {
  marriageEquality, // Full same-sex marriage
  registeredPartnership, // Civil union / registered partnership
  cohabitation, // Unregistered cohabitation recognized
  none, // No legal recognition
}

enum AdoptionRights {
  jointAdoption, // Joint adoption by same-sex couples
  stepchildOnly, // Second-parent / stepchild adoption only
  singleOnly, // Only individual (single-person) adoption
  none, // No adoption rights for same-sex couples
}

enum ConversionTherapyBan {
  fullBan, // Banned on all persons
  minorsBan, // Banned on minors only
  partialBan, // Partial restrictions
  noBan, // No ban
}

enum GenderRecognitionModel {
  selfDetermination, // Self-ID without medical requirements
  medicalRequired, // Requires diagnosis / medical report
  surgeryRequired, // Requires surgery or sterilization
  noProcess, // No legal gender recognition
}

enum SafetyRating {
  verySafe, // Very safe, strong protections
  safe, // Generally safe
  moderate, // Moderate, some concerns
  caution, // Exercise caution
  unsafe, // Significant risks
}

class LgbtqCountryRights {
  final String country;
  final String countryCode;

  // Partnership & Family
  final MarriageStatus marriageStatus;
  final String marriageDetails;
  final int marriageLegalSince; // Year, 0 if not applicable
  final AdoptionRights adoptionRights;
  final String adoptionDetails;
  final bool ivfAccessForLesbians;
  final bool surrogacyLegal;

  // Anti-Discrimination
  final bool employmentProtection;
  final bool housingProtection;
  final bool goodsAndServicesProtection;
  final bool constitutionalProtection;
  final String antiDiscriminationLegalBasis;

  // Gender Recognition
  final GenderRecognitionModel genderRecognitionModel;
  final String genderRecognitionProcess;
  final int genderRecognitionMinAge;
  final bool nonBinaryRecognized;

  // Asylum based on SOGI (Sexual Orientation & Gender Identity)
  final String asylumSogiProcedure;
  final String asylumSogiLegalBasis;
  final String asylumSogiSpecificRights;
  final String asylumSogiOrgSupport;

  // Hate Crimes
  final bool hateCrimeLawSogi;
  final bool hateSpeechLawSogi;
  final String hateCrimeReportingProcess;

  // Health & Medical
  final String bloodDonationPolicy;
  final String transHealthcareAccess;
  final bool transHealthcareStateFunded;
  final bool prepAvailable;

  // Military
  final String militaryService;

  // Conversion Therapy
  final ConversionTherapyBan conversionTherapyBan;
  final String conversionTherapyDetails;

  // Safety
  final SafetyRating safetyRating;
  final String safetyNotes;
  final double ilgaEuropeRanking; // Percentage score 0-100

  // Organizations & Support
  final List<LgbtqOrganization> organizations;

  // Immigrant-Specific
  final String immigrantSpecificNotes;
  final String refugeeSpecificNotes;

  const LgbtqCountryRights({
    required this.country,
    required this.countryCode,
    required this.marriageStatus,
    required this.marriageDetails,
    required this.marriageLegalSince,
    required this.adoptionRights,
    required this.adoptionDetails,
    required this.ivfAccessForLesbians,
    required this.surrogacyLegal,
    required this.employmentProtection,
    required this.housingProtection,
    required this.goodsAndServicesProtection,
    required this.constitutionalProtection,
    required this.antiDiscriminationLegalBasis,
    required this.genderRecognitionModel,
    required this.genderRecognitionProcess,
    required this.genderRecognitionMinAge,
    required this.nonBinaryRecognized,
    required this.asylumSogiProcedure,
    required this.asylumSogiLegalBasis,
    required this.asylumSogiSpecificRights,
    required this.asylumSogiOrgSupport,
    required this.hateCrimeLawSogi,
    required this.hateSpeechLawSogi,
    required this.hateCrimeReportingProcess,
    required this.bloodDonationPolicy,
    required this.transHealthcareAccess,
    required this.transHealthcareStateFunded,
    required this.prepAvailable,
    required this.militaryService,
    required this.conversionTherapyBan,
    required this.conversionTherapyDetails,
    required this.safetyRating,
    required this.safetyNotes,
    required this.ilgaEuropeRanking,
    required this.organizations,
    required this.immigrantSpecificNotes,
    required this.refugeeSpecificNotes,
  });

  Map<String, dynamic> toMap() {
    return {
      'country': country,
      'countryCode': countryCode,
      'marriageStatus': marriageStatus.name,
      'marriageDetails': marriageDetails,
      'marriageLegalSince': marriageLegalSince,
      'adoptionRights': adoptionRights.name,
      'adoptionDetails': adoptionDetails,
      'ivfAccessForLesbians': ivfAccessForLesbians,
      'surrogacyLegal': surrogacyLegal,
      'employmentProtection': employmentProtection,
      'housingProtection': housingProtection,
      'goodsAndServicesProtection': goodsAndServicesProtection,
      'constitutionalProtection': constitutionalProtection,
      'antiDiscriminationLegalBasis': antiDiscriminationLegalBasis,
      'genderRecognitionModel': genderRecognitionModel.name,
      'genderRecognitionProcess': genderRecognitionProcess,
      'genderRecognitionMinAge': genderRecognitionMinAge,
      'nonBinaryRecognized': nonBinaryRecognized,
      'asylumSogiProcedure': asylumSogiProcedure,
      'asylumSogiLegalBasis': asylumSogiLegalBasis,
      'asylumSogiSpecificRights': asylumSogiSpecificRights,
      'asylumSogiOrgSupport': asylumSogiOrgSupport,
      'hateCrimeLawSogi': hateCrimeLawSogi,
      'hateSpeechLawSogi': hateSpeechLawSogi,
      'hateCrimeReportingProcess': hateCrimeReportingProcess,
      'bloodDonationPolicy': bloodDonationPolicy,
      'transHealthcareAccess': transHealthcareAccess,
      'transHealthcareStateFunded': transHealthcareStateFunded,
      'prepAvailable': prepAvailable,
      'militaryService': militaryService,
      'conversionTherapyBan': conversionTherapyBan.name,
      'conversionTherapyDetails': conversionTherapyDetails,
      'safetyRating': safetyRating.name,
      'safetyNotes': safetyNotes,
      'ilgaEuropeRanking': ilgaEuropeRanking,
      'organizations': organizations.map((o) => o.toMap()).toList(),
      'immigrantSpecificNotes': immigrantSpecificNotes,
      'refugeeSpecificNotes': refugeeSpecificNotes,
    };
  }
}

class LgbtqOrganization {
  final String name;
  final String type; // e.g. "legal aid", "shelter", "health", "community", "asylum support"
  final String phone;
  final String email;
  final String website;
  final String address;
  final String languages;
  final String notes;

  const LgbtqOrganization({
    required this.name,
    required this.type,
    required this.phone,
    required this.email,
    required this.website,
    this.address = '',
    this.languages = 'English',
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'phone': phone,
      'email': email,
      'website': website,
      'address': address,
      'languages': languages,
      'notes': notes,
    };
  }
}

// ============================================================
// DATABASE SERVICE
// ============================================================

class LgbtqRightsDatabase {
  static LgbtqCountryRights? getCountryRights(String countryCode) {
    return _allCountries[countryCode.toUpperCase()];
  }

  static List<LgbtqCountryRights> getAllCountries() {
    return _allCountries.values.toList();
  }

  static List<LgbtqCountryRights> getCountriesWithMarriageEquality() {
    return _allCountries.values
        .where((c) => c.marriageStatus == MarriageStatus.marriageEquality)
        .toList();
  }

  static List<LgbtqCountryRights> getCountriesByMinimumSafety(SafetyRating minRating) {
    final ratingOrder = [
      SafetyRating.verySafe,
      SafetyRating.safe,
      SafetyRating.moderate,
      SafetyRating.caution,
      SafetyRating.unsafe,
    ];
    final minIndex = ratingOrder.indexOf(minRating);
    return _allCountries.values
        .where((c) => ratingOrder.indexOf(c.safetyRating) <= minIndex)
        .toList();
  }

  static List<LgbtqCountryRights> getSafestCountriesForAsylum() {
    return _allCountries.values
        .where((c) =>
            c.safetyRating == SafetyRating.verySafe ||
            c.safetyRating == SafetyRating.safe)
        .toList()
      ..sort((a, b) => b.ilgaEuropeRanking.compareTo(a.ilgaEuropeRanking));
  }

  static List<LgbtqCountryRights> getCountriesWithSelfIdGenderRecognition() {
    return _allCountries.values
        .where((c) => c.genderRecognitionModel == GenderRecognitionModel.selfDetermination)
        .toList();
  }

  static List<LgbtqCountryRights> getCountriesWithConversionTherapyBan() {
    return _allCountries.values
        .where((c) =>
            c.conversionTherapyBan == ConversionTherapyBan.fullBan ||
            c.conversionTherapyBan == ConversionTherapyBan.minorsBan)
        .toList();
  }

  static List<LgbtqCountryRights> getCountriesWithJointAdoption() {
    return _allCountries.values
        .where((c) => c.adoptionRights == AdoptionRights.jointAdoption)
        .toList();
  }

  /// Search organizations across all EU countries by type
  static List<MapEntry<String, LgbtqOrganization>> findOrganizationsByType(String type) {
    final results = <MapEntry<String, LgbtqOrganization>>[];
    for (final country in _allCountries.values) {
      for (final org in country.organizations) {
        if (org.type.toLowerCase().contains(type.toLowerCase())) {
          results.add(MapEntry(country.country, org));
        }
      }
    }
    return results;
  }

  /// Find asylum support organizations in a specific country
  static List<LgbtqOrganization> findAsylumSupport(String countryCode) {
    final country = _allCountries[countryCode.toUpperCase()];
    if (country == null) return [];
    return country.organizations
        .where((o) =>
            o.type.toLowerCase().contains('asylum') ||
            o.type.toLowerCase().contains('refugee') ||
            o.type.toLowerCase().contains('legal aid'))
        .toList();
  }

  /// Comprehensive summary for an asylum seeker arriving in a country
  static Map<String, dynamic>? getAsylumSeekerBrief(String countryCode) {
    final c = _allCountries[countryCode.toUpperCase()];
    if (c == null) return null;
    return {
      'country': c.country,
      'safetyRating': c.safetyRating.name,
      'ilgaScore': c.ilgaEuropeRanking,
      'marriageOrPartnership': c.marriageStatus.name,
      'hasAntiDiscrimination': c.employmentProtection && c.housingProtection,
      'hateCrimeProtection': c.hateCrimeLawSogi,
      'asylumProcedure': c.asylumSogiProcedure,
      'asylumLegalBasis': c.asylumSogiLegalBasis,
      'asylumRights': c.asylumSogiSpecificRights,
      'supportOrganizations': c.organizations
          .where((o) =>
              o.type.contains('asylum') ||
              o.type.contains('refugee') ||
              o.type.contains('legal'))
          .map((o) => {'name': o.name, 'phone': o.phone, 'email': o.email})
          .toList(),
      'transHealthcare': c.transHealthcareAccess,
      'refugeeNotes': c.refugeeSpecificNotes,
    };
  }

  // ============================================================
  // COUNTRY DATA - ALL 27 EU MEMBER STATES
  // ============================================================

  static const Map<String, LgbtqCountryRights> _allCountries = {

    // -------------------------------------------------------
    // AUSTRIA (AT)
    // -------------------------------------------------------
    'AT': LgbtqCountryRights(
      country: 'Austria',
      countryCode: 'AT',
      marriageStatus: MarriageStatus.marriageEquality,
      marriageDetails: 'Same-sex marriage legal since January 1, 2019, following Constitutional Court ruling (VfGH G 258-259/2017). Previously registered partnerships were available from 2010.',
      marriageLegalSince: 2019,
      adoptionRights: AdoptionRights.jointAdoption,
      adoptionDetails: 'Joint adoption legal since 2016 (Eingetragene Partnerschaft-Gesetz amendment). Stepchild adoption since 2013 following ECHR ruling in X & Others v. Austria.',
      ivfAccessForLesbians: true,
      surrogacyLegal: false,
      employmentProtection: true,
      housingProtection: true,
      goodsAndServicesProtection: true,
      constitutionalProtection: false,
      antiDiscriminationLegalBasis: 'Equal Treatment Act (Gleichbehandlungsgesetz, BGBl I 66/2004) covers employment. Individual federal states (Bundesländer) have additional protections for housing and services.',
      genderRecognitionModel: GenderRecognitionModel.selfDetermination,
      genderRecognitionProcess: 'Since 2024, Austria allows self-determination for legal gender change without medical requirements. Application at civil registry office (Standesamt). Non-binary option "divers" available since Constitutional Court ruling VfGH G 77/2018.',
      genderRecognitionMinAge: 14,
      nonBinaryRecognized: true,
      asylumSogiProcedure: 'Apply at BFA (Federal Office for Immigration and Asylum). SOGI claims are recognized grounds under the Asylum Act (AsylG 2005). Personal interview conducted by trained officers. Credibility assessment must follow UNHCR guidelines - cannot demand proof of sexual acts.',
      asylumSogiLegalBasis: 'AsylG 2005 transposing EU Qualification Directive 2011/95/EU. SOGI explicitly listed as particular social group ground (Article 10(1)(d)).',
      asylumSogiSpecificRights: 'Right to request same-sex interviewer. Separate accommodation in reception centers if safety concerns. Free legal counsel through Bundesagentur für Betreuungs- und Unterstützungsleistungen (BBU). Right to an interpreter who is SOGI-sensitive.',
      asylumSogiOrgSupport: 'Queer Base (queerbase.at) - specialized asylum support. UNHCR Austria. Asyl in Not.',
      hateCrimeLawSogi: true,
      hateSpeechLawSogi: true,
      hateCrimeReportingProcess: 'Report to police (Polizei) or online at BMI.gv.at. Section 283 Criminal Code (Verhetzung) covers incitement to hatred based on sexual orientation. Aggravating circumstances under Section 33(1)(5) StGB for bias-motivated crimes.',
      bloodDonationPolicy: 'Individual risk assessment since 2022. Previous 12-month deferral for MSM removed. Now based on individual sexual behavior risk regardless of gender of partners.',
      transHealthcareAccess: 'Hormone therapy and gender-affirming surgery covered by public health insurance (Sozialversicherung) with psychiatric/psychological assessment. Wait times 3-12 months for hormones, 6-18 months for surgery.',
      transHealthcareStateFunded: true,
      prepAvailable: true,
      militaryService: 'Open to all regardless of sexual orientation or gender identity. No restrictions since 2001.',
      conversionTherapyBan: ConversionTherapyBan.fullBan,
      conversionTherapyDetails: 'Banned on all persons since 2019 amendment to the Psychotherapy Act. Professional code of Austrian psychotherapy and psychology associations prohibits it.',
      safetyRating: SafetyRating.safe,
      safetyNotes: 'Generally safe, especially in Vienna. Vienna Pride is one of Europe\'s largest. Rural areas may be less accepting. Police are generally responsive to hate crimes.',
      ilgaEuropeRanking: 61.0,
      organizations: [
        LgbtqOrganization(
          name: 'Queer Base - Welcome and Support for LGBTIQ Refugees',
          type: 'asylum support, community',
          phone: '+43 1 585 69 66',
          email: 'office@queerbase.at',
          website: 'https://queerbase.at',
          address: 'Linke Wienzeile 102, 1060 Wien',
          languages: 'German, English, Arabic, Farsi, Russian',
          notes: 'Main LGBTQ+ refugee support organization. Legal aid, community, housing support.',
        ),
        LgbtqOrganization(
          name: 'HOSI Wien (Homosexuellen Initiative Wien)',
          type: 'community, legal aid',
          phone: '+43 1 216 66 04',
          email: 'office@hosiwien.at',
          website: 'https://www.hosiwien.at',
          address: 'Heumühlgasse 14/1, 1040 Wien',
          languages: 'German, English',
          notes: 'Austria\'s oldest LGBTQ+ organization. Counseling, community events, advocacy.',
        ),
        LgbtqOrganization(
          name: 'Transgender Team Austria (TransX)',
          type: 'trans support, health',
          phone: '+43 1 216 66 04',
          email: 'info@transx.at',
          website: 'https://www.transx.at',
          languages: 'German, English',
          notes: 'Trans-specific support, healthcare navigation, legal name change assistance.',
        ),
        LgbtqOrganization(
          name: 'Rechtskomitee Lambda',
          type: 'legal aid',
          phone: '+43 1 876 30 61',
          email: 'office@rklambda.at',
          website: 'https://www.rklambda.at',
          languages: 'German, English',
          notes: 'Legal aid for LGBTQ+ discrimination cases and asylum claims.',
        ),
      ],
      immigrantSpecificNotes: 'EU/EEA citizens can register partnerships/marriages performed abroad. Third-country nationals with valid residence permits have equal access to partnership registration. Family reunification includes same-sex spouses since 2019.',
      refugeeSpecificNotes: 'Austria has specific SOGI asylum guidelines. Queer Base provides specialized support from first interview through integration. Reception centers in Vienna have LGBTQ+ safe spaces. Risk of harm in shared accommodation should be raised with BFA immediately.',
    ),

    // -------------------------------------------------------
    // BELGIUM (BE)
    // -------------------------------------------------------
    'BE': LgbtqCountryRights(
      country: 'Belgium',
      countryCode: 'BE',
      marriageStatus: MarriageStatus.marriageEquality,
      marriageDetails: 'Same-sex marriage legal since June 1, 2003 - second country in the world after the Netherlands. Law of February 13, 2003.',
      marriageLegalSince: 2003,
      adoptionRights: AdoptionRights.jointAdoption,
      adoptionDetails: 'Joint adoption legal since 2006. Full parental rights equal to heterosexual couples. Automatic co-parentage for married female couples since 2014 (Law of May 5, 2014).',
      ivfAccessForLesbians: true,
      surrogacyLegal: false, // Not regulated, but practiced in some clinics (altruistic)
      employmentProtection: true,
      housingProtection: true,
      goodsAndServicesProtection: true,
      constitutionalProtection: true,
      antiDiscriminationLegalBasis: 'Federal Anti-Discrimination Act (Loi tendant à lutter contre certaines formes de discrimination, May 10, 2007). Article 11bis of Belgian Constitution prohibits discrimination. Regional equality bodies: Unia (interfederal).',
      genderRecognitionModel: GenderRecognitionModel.selfDetermination,
      genderRecognitionProcess: 'Self-determination model since 2018 (Law of June 25, 2017). Apply at civil registry office (commune). Requires statutory declaration, no medical requirements. Waiting period of 3-6 months. Available from age 16 (with parental consent from 12).',
      genderRecognitionMinAge: 16,
      nonBinaryRecognized: false, // Under discussion but not yet legally implemented
      asylumSogiProcedure: 'Apply at Immigration Office (Dienst Vreemdelingenzaken/Office des étrangers). CGRS (Commissariat général aux réfugiés et apatrides) handles asylum claims. SOGI-specialized protection officers. Personal interview in safe environment. Cannot be returned to countries criminalizing homosexuality.',
      asylumSogiLegalBasis: 'Law of September 21, 1980 on entry, stay, settlement and removal of foreign nationals. Transposition of EU Qualification Directive. Belgium follows UNHCR SOGI guidelines.',
      asylumSogiSpecificRights: 'Right to SOGI-sensitive interviewer. Separate housing in reception (managed by Fedasil). Free legal aid through Bureau d\'aide juridique. Right not to disclose SOGI to other asylum seekers. Protection officers receive SOGI training.',
      asylumSogiOrgSupport: 'Merhaba (LGBTQ+ people with migrant background), Rainbowhouse Brussels, Vluchtelingenwerk Vlaanderen, CIRÉ.',
      hateCrimeLawSogi: true,
      hateSpeechLawSogi: true,
      hateCrimeReportingProcess: 'Report to local police or online. Anti-Discrimination Law of May 10, 2007. Report also to Unia (equality body, unia.be) for investigation. Criminal penalties of 1 month to 1 year imprisonment and fines for discrimination.',
      bloodDonationPolicy: 'Individual risk assessment since 2023. No blanket deferral for MSM. Based on sexual risk behavior for all donors.',
      transHealthcareAccess: 'Gender-affirming care available through university gender teams (UZ Gent is the main center). Hormones and surgeries covered by mandatory health insurance (mutuelle/ziekenfonds). Wait times 6-18 months.',
      transHealthcareStateFunded: true,
      prepAvailable: true,
      militaryService: 'Open to all. No restrictions based on SOGI. Belgian Armed Forces have LGBTQ+ inclusion policies.',
      conversionTherapyBan: ConversionTherapyBan.fullBan,
      conversionTherapyDetails: 'Banned since 2023 at federal level. Wallonia and Flanders also have regional bans. Penalties include imprisonment and fines.',
      safetyRating: SafetyRating.verySafe,
      safetyNotes: 'One of the most LGBTQ+ friendly countries in Europe. Brussels hosts major Pride and has a vibrant LGBTQ+ scene. Police generally very responsive. Some caution needed in certain neighborhoods at night.',
      ilgaEuropeRanking: 74.0,
      organizations: [
        LgbtqOrganization(
          name: 'Merhaba',
          type: 'asylum support, community, legal aid',
          phone: '+32 2 503 59 90',
          email: 'info@merhaba.be',
          website: 'https://www.merhaba.be',
          address: 'Rainbowhouse, Rue du Marché au Charbon 42, 1000 Brussels',
          languages: 'French, Dutch, English, Arabic, Turkish',
          notes: 'LGBTQ+ organization focused on migrants and refugees. Key contact for SOGI asylum seekers.',
        ),
        LgbtqOrganization(
          name: 'Rainbowhouse Brussels',
          type: 'community, referral',
          phone: '+32 2 503 59 90',
          email: 'info@rainbowhouse.be',
          website: 'https://www.rainbowhouse.be',
          address: 'Rue du Marché au Charbon 42, 1000 Brussels',
          languages: 'French, Dutch, English',
          notes: 'Umbrella LGBTQ+ center hosting multiple organizations.',
        ),
        LgbtqOrganization(
          name: 'çavaria',
          type: 'community, advocacy',
          phone: '+32 9 223 69 29',
          email: 'info@cavaria.be',
          website: 'https://www.cavaria.be',
          address: 'Kammerstraat 22, 9000 Gent',
          languages: 'Dutch, English',
          notes: 'Flemish LGBTQ+ umbrella organization. Advocacy, education, support.',
        ),
        LgbtqOrganization(
          name: 'Genres Pluriels',
          type: 'trans support',
          phone: '+32 2 880 47 13',
          email: 'info@genrespluriels.be',
          website: 'https://www.genrespluriels.be',
          languages: 'French, English',
          notes: 'Trans and intersex support, healthcare navigation, peer groups.',
        ),
      ],
      immigrantSpecificNotes: 'Belgium recognizes foreign same-sex marriages. Family reunification for same-sex spouses fully available. Municipal registration straightforward for EU citizens. Third-country nationals must legalize relationship documents at Belgian embassy.',
      refugeeSpecificNotes: 'Belgium has a good track record for SOGI asylum claims, especially from countries with criminalization. Merhaba is the primary SOGI-specific refugee support. Fedasil reception centers have protocols for LGBTQ+ safety. Brussels has the most resources.',
    ),

    // -------------------------------------------------------
    // BULGARIA (BG)
    // -------------------------------------------------------
    'BG': LgbtqCountryRights(
      country: 'Bulgaria',
      countryCode: 'BG',
      marriageStatus: MarriageStatus.none,
      marriageDetails: 'No legal recognition of same-sex relationships. Constitution (Article 46) defines marriage as union between man and woman (2024 constitutional referendum reinforced this). No registered partnership or cohabitation law.',
      marriageLegalSince: 0,
      adoptionRights: AdoptionRights.none,
      adoptionDetails: 'No adoption rights for same-sex couples. Single individuals can adopt but joint adoption and stepchild adoption for same-sex partners not available.',
      ivfAccessForLesbians: false,
      surrogacyLegal: false,
      employmentProtection: true,
      housingProtection: false,
      goodsAndServicesProtection: false,
      constitutionalProtection: false,
      antiDiscriminationLegalBasis: 'Protection Against Discrimination Act (2004) covers employment discrimination on grounds of sexual orientation. Does not cover housing or services explicitly. Commission for Protection against Discrimination handles complaints.',
      genderRecognitionModel: GenderRecognitionModel.noProcess,
      genderRecognitionProcess: 'No specific legal framework for gender recognition. Some courts have granted gender change petitions on case-by-case basis under Civil Registration Act, but no standardized process. Supreme Court of Cassation rulings have been contradictory.',
      genderRecognitionMinAge: 0,
      nonBinaryRecognized: false,
      asylumSogiProcedure: 'Apply at State Agency for Refugees (SAR). SOGI can be claimed as grounds. Interviews conducted by SAR officers - no guarantee of SOGI-trained interviewer. Process often lacks sensitivity. Appeal possible to Administrative Court.',
      asylumSogiLegalBasis: 'Law on Asylum and Refugees (transposing EU Qualification Directive). SOGI recognized under particular social group category.',
      asylumSogiSpecificRights: 'Right to confidentiality of SOGI claim. Right to interpreter. Legal aid available but often underfunded. No systematic SOGI training for asylum officers. Accommodations in reception centers do not have SOGI-safe spaces.',
      asylumSogiOrgSupport: 'Bilitis Resource Center Foundation, Bulgarian Helsinki Committee, UNHCR Bulgaria.',
      hateCrimeLawSogi: false,
      hateSpeechLawSogi: false,
      hateCrimeReportingProcess: 'Report to police. No specific SOGI hate crime legislation. General criminal law may apply. Bulgarian Helsinki Committee can assist with documentation. Underreporting is a significant issue.',
      bloodDonationPolicy: 'Permanent deferral for MSM. Questionnaire asks about male-male sexual contact, leading to indefinite exclusion.',
      transHealthcareAccess: 'Very limited. No standardized protocol. Endocrinologists may prescribe hormones but not within a gender-affirming care framework. No gender-affirming surgery centers in Bulgaria. Most trans persons seek care abroad (Thailand, Serbia, or Western Europe).',
      transHealthcareStateFunded: false,
      prepAvailable: false,
      militaryService: 'Homosexuality no longer disqualifying (since 2003). Open service technically permitted but stigma remains significant in military culture.',
      conversionTherapyBan: ConversionTherapyBan.noBan,
      conversionTherapyDetails: 'No ban on conversion therapy. Some religious organizations and private practitioners offer it. No government regulation.',
      safetyRating: SafetyRating.caution,
      safetyNotes: 'Significant societal homophobia. Sofia Pride occurs annually but under heavy police protection. Violence against LGBTQ+ people reported. Rural areas particularly unsafe. Political rhetoric often anti-LGBTQ+.',
      ilgaEuropeRanking: 22.0,
      organizations: [
        LgbtqOrganization(
          name: 'Bilitis Resource Center Foundation',
          type: 'community, advocacy, legal aid',
          phone: '+359 2 981 00 24',
          email: 'bilitis@bilitis.org',
          website: 'https://bilitis.org',
          address: 'Sofia, Bulgaria',
          languages: 'Bulgarian, English',
          notes: 'Main LGBTQ+ organization in Bulgaria. Advocacy, community support, legal consultations.',
        ),
        LgbtqOrganization(
          name: 'Bulgarian Helsinki Committee',
          type: 'legal aid, asylum support',
          phone: '+359 2 943 48 76',
          email: 'bhc@bghelsinki.org',
          website: 'https://www.bghelsinki.org',
          languages: 'Bulgarian, English',
          notes: 'Human rights organization providing legal aid including for LGBTQ+ asylum seekers.',
        ),
        LgbtqOrganization(
          name: 'GLAS Foundation',
          type: 'community, health',
          phone: '',
          email: 'info@glasfoundation.bg',
          website: 'https://glasfoundation.bg',
          languages: 'Bulgarian, English',
          notes: 'LGBTQ+ health, community events, Sofia Pride organizer.',
        ),
      ],
      immigrantSpecificNotes: 'Bulgaria does not recognize same-sex marriages or partnerships performed abroad. Family reunification for same-sex partners not available. LGBTQ+ immigrants may face social hostility. Sofia is the only city with visible LGBTQ+ community infrastructure.',
      refugeeSpecificNotes: 'SOGI asylum claims are possible but the system is poorly prepared. Lack of SOGI training among officials, potential for insensitive questioning. Reception center conditions may be unsafe for openly LGBTQ+ persons. Bulgarian Helsinki Committee is the best resource for legal support.',
    ),

    // -------------------------------------------------------
    // CROATIA (HR)
    // -------------------------------------------------------
    'HR': LgbtqCountryRights(
      country: 'Croatia',
      countryCode: 'HR',
      marriageStatus: MarriageStatus.registeredPartnership,
      marriageDetails: 'Life Partnership Act (Zakon o životnom partnerstvu, 2014) provides registered partnerships with rights nearly equal to marriage except adoption. Constitutional amendment in 2013 defined marriage as man-woman union.',
      marriageLegalSince: 0,
      adoptionRights: AdoptionRights.none,
      adoptionDetails: 'No joint adoption rights. Life partners cannot adopt jointly. Individual adoption theoretically possible but courts rarely grant to openly LGBTQ+ persons. Constitutional Court has not yet ruled definitively.',
      ivfAccessForLesbians: false,
      surrogacyLegal: false,
      employmentProtection: true,
      housingProtection: true,
      goodsAndServicesProtection: true,
      constitutionalProtection: false,
      antiDiscriminationLegalBasis: 'Anti-Discrimination Act (Zakon o suzbijanju diskriminacije, 2008, amended 2012) covers sexual orientation and gender identity in employment, housing, education, and services. Ombudsperson for Gender Equality handles complaints.',
      genderRecognitionModel: GenderRecognitionModel.medicalRequired,
      genderRecognitionProcess: 'Legal gender recognition available under Gender Equality Act. Requires opinion from National Health Council committee (including psychiatrist and endocrinologist). No surgery requirement since 2014 Administrative Court ruling, but medical assessment still needed.',
      genderRecognitionMinAge: 18,
      nonBinaryRecognized: false,
      asylumSogiProcedure: 'Apply at Ministry of Interior or police station. Processed by Asylum Department. SOGI claims recognized. Personal interview with asylum officer. Croatian Law Centre provides free legal aid. Appeal to Administrative Court.',
      asylumSogiLegalBasis: 'International and Temporary Protection Act (2015, amended 2024) transposing EU Qualification Directive. SOGI as particular social group.',
      asylumSogiSpecificRights: 'Right to confidentiality. Access to free legal aid (Croatian Law Centre). SOGI-sensitive interpreter can be requested. Reception centers in Zagreb have some experience with LGBTQ+ residents.',
      asylumSogiOrgSupport: 'Zagreb Pride, Croatian Law Centre (Hrvatski pravni centar), Are You Syrious, UNHCR Croatia.',
      hateCrimeLawSogi: true,
      hateSpeechLawSogi: true,
      hateCrimeReportingProcess: 'Report to police. Criminal Code Articles 87(21) and 325 cover hate crimes and hate speech. Bias motive is an aggravating circumstance. Report to Ombudsperson for additional documentation.',
      bloodDonationPolicy: '12-month deferral for MSM (since 2023, reduced from permanent ban).',
      transHealthcareAccess: 'Hormones available through endocrinologists with psychiatric referral. Gender-affirming surgery performed at KBC Zagreb (limited capacity). Covered by national health insurance (HZZO) but wait times long (1-3 years for surgery).',
      transHealthcareStateFunded: true,
      prepAvailable: false,
      militaryService: 'Open service since 2001. No restrictions based on sexual orientation.',
      conversionTherapyBan: ConversionTherapyBan.noBan,
      conversionTherapyDetails: 'No explicit ban. However, professional psychological and psychiatric associations have issued statements against it.',
      safetyRating: SafetyRating.moderate,
      safetyNotes: 'Zagreb is generally safe with active LGBTQ+ community. Zagreb Pride well-established since 2002. Some violence incidents reported. Split and coastal cities improving. Rural areas and politically conservative regions less accepting.',
      ilgaEuropeRanking: 42.0,
      organizations: [
        LgbtqOrganization(
          name: 'Zagreb Pride',
          type: 'community, advocacy, asylum support',
          phone: '+385 1 6470 046',
          email: 'info@zagreb-pride.net',
          website: 'https://www.zagreb-pride.net',
          address: 'Zagreb, Croatia',
          languages: 'Croatian, English',
          notes: 'Main LGBTQ+ organization. Advocacy, legal support, community.',
        ),
        LgbtqOrganization(
          name: 'Croatian Law Centre (Hrvatski pravni centar)',
          type: 'legal aid, asylum support',
          phone: '+385 1 4811 158',
          email: 'hlc@hpc.hr',
          website: 'https://www.hpc.hr',
          languages: 'Croatian, English',
          notes: 'Free legal aid for asylum seekers including SOGI claims.',
        ),
        LgbtqOrganization(
          name: 'Trans Aid (TransAid)',
          type: 'trans support',
          phone: '',
          email: 'info@transaid.hr',
          website: 'https://www.transaid.hr',
          languages: 'Croatian, English',
          notes: 'Trans support, healthcare navigation, peer support groups.',
        ),
      ],
      immigrantSpecificNotes: 'Life partnerships available to foreign nationals with valid residence. Foreign same-sex marriages recognized as life partnerships. Family reunification for life partners covered under Foreigners Act. EU citizens can register partnership directly.',
      refugeeSpecificNotes: 'Croatia processes moderate numbers of asylum claims. SOGI claims are recognized but system experience is limited. Croatian Law Centre provides essential legal support. Zagreb is the only city with meaningful LGBTQ+ support infrastructure for refugees.',
    ),

    // -------------------------------------------------------
    // CYPRUS (CY)
    // -------------------------------------------------------
    'CY': LgbtqCountryRights(
      country: 'Cyprus',
      countryCode: 'CY',
      marriageStatus: MarriageStatus.registeredPartnership,
      marriageDetails: 'Civil Partnership Law (2015) provides registered partnerships open to same-sex couples. Not equivalent to marriage - excludes some inheritance and adoption rights. Government-controlled areas only (not Northern Cyprus).',
      marriageLegalSince: 0,
      adoptionRights: AdoptionRights.none,
      adoptionDetails: 'No adoption rights for same-sex couples. Civil partners cannot adopt jointly or as stepparents.',
      ivfAccessForLesbians: false,
      surrogacyLegal: false,
      employmentProtection: true,
      housingProtection: true,
      goodsAndServicesProtection: true,
      constitutionalProtection: false,
      antiDiscriminationLegalBasis: 'Law on Combating Racial and Other Forms of Discrimination (L.42(I)/2004) and Equal Treatment in Employment and Occupation Law (L.58(I)/2004). Cover sexual orientation in employment and services.',
      genderRecognitionModel: GenderRecognitionModel.medicalRequired,
      genderRecognitionProcess: 'Legal gender change possible through court application. Requires medical documentation. Process not fully codified in legislation. Case-by-case judicial assessment.',
      genderRecognitionMinAge: 18,
      nonBinaryRecognized: false,
      asylumSogiProcedure: 'Apply at Civil Registry and Migration Department or asylum service. SOGI claims accepted under Refugee Law (L.6(I)/2000, amended). Interview by asylum officer. Appeal to Refugee Reviewing Authority.',
      asylumSogiLegalBasis: 'Refugee Law transposing EU directives. SOGI recognized as particular social group. Cyprus Refugee Council provides support.',
      asylumSogiSpecificRights: 'Right to confidential interview. Legal aid available through Cyprus Refugee Council. Accommodation in Kofinou reception center.',
      asylumSogiOrgSupport: 'Accept-LGBTI Cyprus, Cyprus Refugee Council, KISA (Action for Equality, Support, Antiracism).',
      hateCrimeLawSogi: true,
      hateSpeechLawSogi: true,
      hateCrimeReportingProcess: 'Report to police. Criminal Code amended in 2015 to include sexual orientation and gender identity as protected grounds in hate crime provisions.',
      bloodDonationPolicy: '12-month deferral for MSM.',
      transHealthcareAccess: 'Limited. Some endocrinological care available in Nicosia. No gender-affirming surgery capacity - most trans persons travel to Greece, UK or other EU countries.',
      transHealthcareStateFunded: false,
      prepAvailable: false,
      militaryService: 'Open service. National Guard does not discriminate on sexual orientation (conscription applies to all male citizens).',
      conversionTherapyBan: ConversionTherapyBan.noBan,
      conversionTherapyDetails: 'No ban. Religious organizations, particularly within the Orthodox Church, have promoted "therapy" programs.',
      safetyRating: SafetyRating.moderate,
      safetyNotes: 'Nicosia and Limassol have small but growing LGBTQ+ communities. First Pride in 2014. Orthodox Church influence creates social conservatism. Generally safe but low visibility.',
      ilgaEuropeRanking: 37.0,
      organizations: [
        LgbtqOrganization(
          name: 'Accept-LGBTI Cyprus',
          type: 'community, advocacy',
          phone: '+357 22 100 587',
          email: 'info@acceptcy.org',
          website: 'https://www.acceptcy.org',
          languages: 'Greek, English',
          notes: 'Main LGBTQ+ organization. Advocacy, community, Pride organizer.',
        ),
        LgbtqOrganization(
          name: 'Cyprus Refugee Council',
          type: 'asylum support, legal aid',
          phone: '+357 22 455 577',
          email: 'info@cyrefugeecouncil.org',
          website: 'https://www.cyrefugeecouncil.org',
          languages: 'Greek, English, Arabic, French',
          notes: 'Legal aid and support for asylum seekers including SOGI claims.',
        ),
        LgbtqOrganization(
          name: 'KISA',
          type: 'legal aid, community',
          phone: '+357 22 878 181',
          email: 'info@kisa.org.cy',
          website: 'https://kisa.org.cy',
          languages: 'Greek, English, Turkish',
          notes: 'Anti-racism and equality organization. Supports LGBTQ+ migrants.',
        ),
      ],
      immigrantSpecificNotes: 'Civil partnerships available to foreign nationals. Foreign same-sex marriages recognized as civil partnerships. Note: Northern Cyprus (TRNC) has completely different laws and does not protect LGBTQ+ rights.',
      refugeeSpecificNotes: 'Cyprus receives significant asylum numbers. SOGI claims processed but system capacity limited. Cyprus Refugee Council is essential for legal support. Reception center conditions may be challenging for LGBTQ+ persons. Nicosia has the most resources.',
    ),

    // -------------------------------------------------------
    // CZECH REPUBLIC (CZ)
    // -------------------------------------------------------
    'CZ': LgbtqCountryRights(
      country: 'Czech Republic',
      countryCode: 'CZ',
      marriageStatus: MarriageStatus.registeredPartnership,
      marriageDetails: 'Registered partnership since 2006 (Act No. 115/2006 Coll.). Marriage equality bill passed first reading in Parliament in 2024 but not yet enacted. Partnerships lack some rights of marriage (adoption, automatic presumption of parentage).',
      marriageLegalSince: 0,
      adoptionRights: AdoptionRights.singleOnly,
      adoptionDetails: 'Individual adoption allowed. No joint adoption for registered partners. Stepchild adoption not legally available for same-sex partners. Constitutional Court has been asked to rule.',
      ivfAccessForLesbians: true,
      surrogacyLegal: false,
      employmentProtection: true,
      housingProtection: true,
      goodsAndServicesProtection: true,
      constitutionalProtection: false,
      antiDiscriminationLegalBasis: 'Anti-Discrimination Act (Act No. 198/2009 Coll.) covers sexual orientation in employment, education, healthcare, housing, goods and services. Public Defender of Rights (Ombudsman) handles complaints.',
      genderRecognitionModel: GenderRecognitionModel.surgeryRequired,
      genderRecognitionProcess: 'Requires sterilization/surgery under Health Services Act (Act No. 372/2011 Coll.). Must dissolve registered partnership. Diagnosis by sexological committee. Czech Constitutional Court upheld surgery requirement in 2023 but ECHR challenge pending.',
      genderRecognitionMinAge: 18,
      nonBinaryRecognized: false,
      asylumSogiProcedure: 'Apply at Ministry of Interior, Department for Asylum and Migration Policy. SOGI claims recognized. Interview by trained officer. Organization for Aid to Refugees (OPU) provides free legal aid.',
      asylumSogiLegalBasis: 'Asylum Act (Act No. 325/1999 Coll.) transposing EU Qualification Directive. SOGI as particular social group explicitly recognized.',
      asylumSogiSpecificRights: 'Right to confidential interview. Free legal aid through OPU and UNHCR. Accommodation in reception centers. Czech system is generally experienced with SOGI claims.',
      asylumSogiOrgSupport: 'Prague Pride, Sbarvouven.cz, Organization for Aid to Refugees (OPU), UNHCR Czech Republic.',
      hateCrimeLawSogi: true,
      hateSpeechLawSogi: false,
      hateCrimeReportingProcess: 'Report to police (Policie ČR). Criminal Code Section 352 (violence against group of persons) and Section 355 (defamation of group) cover some bias crimes. Sexual orientation not explicitly listed in hate speech provisions.',
      bloodDonationPolicy: '12-month deferral for MSM since 2022 (previously permanent).',
      transHealthcareAccess: 'Available through sexology departments at university hospitals (Prague, Brno). Hormones and surgery covered by public health insurance (VZP) but surgery requirement for legal recognition is controversial. Wait times 1-2 years.',
      transHealthcareStateFunded: true,
      prepAvailable: true,
      militaryService: 'Open service. No restrictions based on sexual orientation since 1999.',
      conversionTherapyBan: ConversionTherapyBan.noBan,
      conversionTherapyDetails: 'No explicit ban. Czech Medical Chamber and psychological associations discourage it but no legal prohibition.',
      safetyRating: SafetyRating.safe,
      safetyNotes: 'Czech Republic is one of the most secular and tolerant countries in Central Europe. Prague has a vibrant LGBTQ+ scene. Prague Pride is large and well-attended. Public opinion strongly favors LGBTQ+ rights.',
      ilgaEuropeRanking: 42.0,
      organizations: [
        LgbtqOrganization(
          name: 'Prague Pride',
          type: 'community, advocacy',
          phone: '+420 608 557 546',
          email: 'info@praguepride.cz',
          website: 'https://www.praguepride.cz',
          address: 'Prague, Czech Republic',
          languages: 'Czech, English',
          notes: 'Main LGBTQ+ organization. Annual Pride, advocacy, community support.',
        ),
        LgbtqOrganization(
          name: 'Organization for Aid to Refugees (OPU)',
          type: 'asylum support, legal aid',
          phone: '+420 284 683 714',
          email: 'opu@opu.cz',
          website: 'https://www.opu.cz',
          languages: 'Czech, English, Russian, Arabic, French',
          notes: 'Free legal aid for asylum seekers including SOGI claims.',
        ),
        LgbtqOrganization(
          name: 'Transparent (Trans*parent)',
          type: 'trans support',
          phone: '',
          email: 'info@transparentcz.cz',
          website: 'https://www.transparentcz.cz',
          languages: 'Czech, English',
          notes: 'Trans support, healthcare navigation, advocacy for ending surgery requirement.',
        ),
      ],
      immigrantSpecificNotes: 'Registered partnerships available to foreign nationals. Foreign same-sex marriages recognized as registered partnerships. Czech Republic is generally welcoming - Prague especially popular with LGBTQ+ expats.',
      refugeeSpecificNotes: 'Low asylum numbers but system is experienced. SOGI claims generally well-handled. OPU provides excellent legal support. Prague has the most LGBTQ+ resources. Note: surgery requirement for legal gender recognition affects trans asylum seekers.',
    ),

    // -------------------------------------------------------
    // DENMARK (DK)
    // -------------------------------------------------------
    'DK': LgbtqCountryRights(
      country: 'Denmark',
      countryCode: 'DK',
      marriageStatus: MarriageStatus.marriageEquality,
      marriageDetails: 'Same-sex marriage legal since June 15, 2012. Denmark was first country to allow registered partnerships (1989). Church of Denmark performs same-sex marriages since 2012.',
      marriageLegalSince: 2012,
      adoptionRights: AdoptionRights.jointAdoption,
      adoptionDetails: 'Joint adoption since 2010. Stepchild adoption since 1999. Full equal parental rights. Automatic co-parentage for married female couples.',
      ivfAccessForLesbians: true,
      surrogacyLegal: false,
      employmentProtection: true,
      housingProtection: true,
      goodsAndServicesProtection: true,
      constitutionalProtection: false,
      antiDiscriminationLegalBasis: 'Act on Prohibition of Discrimination in the Labour Market (Forskelsbehandlingsloven). Act on Ethnic Equal Treatment extended to cover sexual orientation and gender identity. Danish Institute for Human Rights monitors compliance.',
      genderRecognitionModel: GenderRecognitionModel.selfDetermination,
      genderRecognitionProcess: 'Self-determination since 2014 - first country in Europe. Application to CPR Office (Civil Registration). 6-month reflection period then confirmation. No medical requirements. Available from age 18. Minors (under 18) can apply with parental consent and additional requirements.',
      genderRecognitionMinAge: 18,
      nonBinaryRecognized: false,
      asylumSogiProcedure: 'Apply at Immigration Service (Udlændingestyrelsen). SOGI claims well-recognized. Interviews by trained officers at Refugee Appeals Board. Danish Refugee Council (Dansk Flygtningehjælp) provides legal aid. Good track record for SOGI claims from countries with criminalization.',
      asylumSogiLegalBasis: 'Aliens Act (Udlændingeloven) Section 7. SOGI recognized under particular social group. Denmark follows UNHCR SOGI guidelines closely.',
      asylumSogiSpecificRights: 'Right to SOGI-sensitive interviewer. Free legal aid at Refugee Appeals Board stage. Accommodation with safety considerations. Danish Refugee Council provides specialized support.',
      asylumSogiOrgSupport: 'LGBT+ Denmark, Danish Refugee Council, Sabaah (LGBTQ+ ethnic minorities), LGBT Asylum.',
      hateCrimeLawSogi: true,
      hateSpeechLawSogi: true,
      hateCrimeReportingProcess: 'Report to police (Politi). Criminal Code Section 81(6) lists bias motive as aggravating circumstance. Section 266b covers hate speech. National Police have hate crime coordinators.',
      bloodDonationPolicy: 'Individual risk assessment since 2021. 4-month deferral after new sexual partner (all genders). No MSM-specific ban.',
      transHealthcareAccess: 'Available through Center for Gender Identity (Sexologisk Klinik, Rigshospitalet Copenhagen). Hormones and surgery covered by public healthcare. Wait times 6-18 months for initial assessment. Recent improvements expanding capacity.',
      transHealthcareStateFunded: true,
      prepAvailable: true,
      militaryService: 'Open service. No restrictions. Danish military actively promotes diversity.',
      conversionTherapyBan: ConversionTherapyBan.fullBan,
      conversionTherapyDetails: 'Banned since 2022 for minors and non-consenting adults. Full ban extended in 2024. Criminal penalties apply.',
      safetyRating: SafetyRating.verySafe,
      safetyNotes: 'One of the safest countries in the world for LGBTQ+ persons. Copenhagen is a global LGBTQ+ hub. Strong legal protections. Copenhagen Pride is a major event. Very high public acceptance.',
      ilgaEuropeRanking: 73.0,
      organizations: [
        LgbtqOrganization(
          name: 'LGBT+ Denmark (LGBT+ Danmark)',
          type: 'community, advocacy, legal aid',
          phone: '+45 33 13 19 48',
          email: 'info@lgbt.dk',
          website: 'https://www.lgbt.dk',
          address: 'Nygade 7, 1164 Copenhagen K',
          languages: 'Danish, English',
          notes: 'National LGBTQ+ organization since 1948. Oldest in the world. Legal aid, community, advocacy.',
        ),
        LgbtqOrganization(
          name: 'Sabaah',
          type: 'community, asylum support',
          phone: '+45 26 24 99 24',
          email: 'info@sabaah.dk',
          website: 'https://www.sabaah.dk',
          languages: 'Danish, English, Arabic, Farsi, Turkish, Somali',
          notes: 'LGBTQ+ ethnic minorities and refugees. Peer support, community events, counseling.',
        ),
        LgbtqOrganization(
          name: 'Danish Refugee Council (Dansk Flygtningehjælp)',
          type: 'asylum support, legal aid',
          phone: '+45 33 73 50 00',
          email: 'drc@drc.ngo',
          website: 'https://drc.ngo',
          languages: 'Danish, English, Arabic, Farsi, Somali',
          notes: 'Legal aid and support for all asylum seekers. SOGI-trained counselors.',
        ),
        LgbtqOrganization(
          name: 'LGBT Asylum',
          type: 'asylum support',
          phone: '+45 60 88 89 88',
          email: 'info@lgbtasylum.dk',
          website: 'https://lgbtasylum.dk',
          languages: 'Danish, English, Arabic, Farsi',
          notes: 'Specialized support for LGBTQ+ asylum seekers. Housing, legal aid, social activities.',
        ),
      ],
      immigrantSpecificNotes: 'Foreign same-sex marriages fully recognized. Family reunification for same-sex spouses available under same conditions as different-sex couples. EU citizens register at International House Copenhagen.',
      refugeeSpecificNotes: 'Denmark has strong SOGI asylum recognition. LGBT Asylum and Sabaah provide specialized support. Note: Denmark\'s strict asylum policies in general may affect SOGI claimants. Accommodation options for LGBTQ+ persons in Copenhagen area. Good integration support available.',
    ),

    // -------------------------------------------------------
    // ESTONIA (EE)
    // -------------------------------------------------------
    'EE': LgbtqCountryRights(
      country: 'Estonia',
      countryCode: 'EE',
      marriageStatus: MarriageStatus.marriageEquality,
      marriageDetails: 'Same-sex marriage legal since January 1, 2024. Family Law Act amended June 2023. Previously, Cohabitation Act (2014/2016) provided registered cohabitation with limited rights.',
      marriageLegalSince: 2024,
      adoptionRights: AdoptionRights.jointAdoption,
      adoptionDetails: 'Joint adoption legal since marriage equality in 2024. Stepchild adoption available. Full equal parental rights for married same-sex couples.',
      ivfAccessForLesbians: true,
      surrogacyLegal: false,
      employmentProtection: true,
      housingProtection: true,
      goodsAndServicesProtection: true,
      constitutionalProtection: false,
      antiDiscriminationLegalBasis: 'Equal Treatment Act (Võrdse kohtlemise seadus, 2009) covers sexual orientation in employment. Gender Equality Act covers gender identity. Chancellor of Justice acts as equality body.',
      genderRecognitionModel: GenderRecognitionModel.medicalRequired,
      genderRecognitionProcess: 'Under Health Services Organisation Act. Requires psychiatric diagnosis and medical committee assessment. No surgery requirement since 2022. Application to Social Insurance Board after medical documentation.',
      genderRecognitionMinAge: 18,
      nonBinaryRecognized: false,
      asylumSogiProcedure: 'Apply at Police and Border Guard Board (PPA). SOGI claims accepted. Interview with migration official. Estonian Human Rights Centre provides legal support. Appeal to Administrative Court.',
      asylumSogiLegalBasis: 'International Protection Act (2006, amended) transposing EU Qualification Directive. SOGI recognized under particular social group.',
      asylumSogiSpecificRights: 'Right to confidential interview. Free legal aid through Estonian Human Rights Centre. Accommodation at Vao/Vägeva reception center.',
      asylumSogiOrgSupport: 'Estonian Human Rights Centre, Estonian LGBT Association (Eesti LGBT Ühing).',
      hateCrimeLawSogi: false,
      hateSpeechLawSogi: false,
      hateCrimeReportingProcess: 'Report to police. No specific SOGI hate crime legislation. General criminal provisions may apply. Estonian Human Rights Centre can assist with documentation.',
      bloodDonationPolicy: '12-month deferral for MSM.',
      transHealthcareAccess: 'Limited capacity. East Tallinn Central Hospital provides some services. Hormones available with psychiatric referral. Surgery often requires travel abroad. Covered partially by Estonian Health Insurance Fund.',
      transHealthcareStateFunded: true,
      prepAvailable: true,
      militaryService: 'Open service. No restrictions based on sexual orientation. Conscription applies to male citizens.',
      conversionTherapyBan: ConversionTherapyBan.noBan,
      conversionTherapyDetails: 'No specific ban. Estonian Psychological Association has discouraged it.',
      safetyRating: SafetyRating.safe,
      safetyNotes: 'Significant improvement in recent years. Marriage equality landmark. Tallinn has visible LGBTQ+ community. Baltic Pride held regularly. Public opinion shifting positively, especially among younger generation.',
      ilgaEuropeRanking: 44.0,
      organizations: [
        LgbtqOrganization(
          name: 'Estonian LGBT Association (Eesti LGBT Ühing)',
          type: 'community, advocacy, legal aid',
          phone: '+372 6 501 214',
          email: 'info@lgbt.ee',
          website: 'https://www.lgbt.ee',
          address: 'Tallinn, Estonia',
          languages: 'Estonian, English, Russian',
          notes: 'Main LGBTQ+ organization. Advocacy, legal support, community events.',
        ),
        LgbtqOrganization(
          name: 'Estonian Human Rights Centre',
          type: 'legal aid, asylum support',
          phone: '+372 644 5148',
          email: 'info@humanrights.ee',
          website: 'https://humanrights.ee',
          languages: 'Estonian, English, Russian',
          notes: 'Human rights legal aid including for LGBTQ+ asylum seekers.',
        ),
      ],
      immigrantSpecificNotes: 'Same-sex marriages recognized since 2024. Family reunification for same-sex spouses available. E-residency does not confer marriage rights but facilitates business. Tallinn is the main hub for LGBTQ+ immigrants.',
      refugeeSpecificNotes: 'Low asylum numbers. System functional but limited experience with SOGI claims. Estonian Human Rights Centre is key resource. Russian-speaking LGBTQ+ asylum seekers may find community support through Russian-speaking networks in Tallinn.',
    ),

    // -------------------------------------------------------
    // FINLAND (FI)
    // -------------------------------------------------------
    'FI': LgbtqCountryRights(
      country: 'Finland',
      countryCode: 'FI',
      marriageStatus: MarriageStatus.marriageEquality,
      marriageDetails: 'Same-sex marriage legal since March 1, 2017. Marriage Act amended by citizen initiative (first in Finnish history). Registered partnerships available since 2002 (no new registrations since 2017).',
      marriageLegalSince: 2017,
      adoptionRights: AdoptionRights.jointAdoption,
      adoptionDetails: 'Joint adoption since 2017 (with marriage equality). Internal stepchild adoption since 2009. International adoption may be limited by country-of-origin policies.',
      ivfAccessForLesbians: true,
      surrogacyLegal: false,
      employmentProtection: true,
      housingProtection: true,
      goodsAndServicesProtection: true,
      constitutionalProtection: true,
      antiDiscriminationLegalBasis: 'Non-Discrimination Act (Yhdenvertaisuuslaki, 1325/2014) covers sexual orientation, gender identity, and gender expression. Constitution Section 6 guarantees equality. Equality Ombudsman (Yhdenvertaisuusvaltuutettu) handles complaints.',
      genderRecognitionModel: GenderRecognitionModel.selfDetermination,
      genderRecognitionProcess: 'Self-determination since April 2023 (Trans Act, Translaki). Application to Digital and Population Data Services Agency (DVV). Written application, 30-day reflection period, then confirmation. No medical requirements. Available from age 18. For minors discussion ongoing.',
      genderRecognitionMinAge: 18,
      nonBinaryRecognized: false,
      asylumSogiProcedure: 'Apply at Finnish Immigration Service (Migri, migri.fi). SOGI claims well-recognized. Interview by trained Migri officer. Finnish Refugee Advice Centre provides free legal aid. Appeal to Administrative Court, further to Supreme Administrative Court.',
      asylumSogiLegalBasis: 'Aliens Act (Ulkomaalaislaki, 301/2004) Section 87. SOGI as particular social group. Finland follows UNHCR SOGI guidelines. Country of origin information service (Maatietopalvelu) provides SOGI-specific reports.',
      asylumSogiSpecificRights: 'Right to SOGI-sensitive interviewer. Free legal aid through Finnish Refugee Advice Centre. Accommodation in reception centers with safety considerations. Right to request same-sex interviewer and interpreter. Migri has SOGI training for officers.',
      asylumSogiOrgSupport: 'Seta ry, Finnish Refugee Advice Centre, Helsinki Pride Community, Finnish Red Cross.',
      hateCrimeLawSogi: true,
      hateSpeechLawSogi: true,
      hateCrimeReportingProcess: 'Report to police (Poliisi, 112 emergency, online at poliisi.fi). Criminal Code Chapter 6 Section 5 lists bias motive as aggravating. Chapter 11 Section 10 covers ethnic agitation (extended to sexual orientation). Report also to Equality Ombudsman.',
      bloodDonationPolicy: 'Individual risk assessment since 2024. No blanket MSM deferral. Finnish Red Cross Blood Service assesses each donor individually.',
      transHealthcareAccess: 'Available through university hospital gender identity clinics (TAYS Tampere, HUS Helsinki). Hormones and surgery covered by Kela (national health insurance). Wait times 6-12 months for first appointment. Trans Act (2023) separated legal recognition from medical transition.',
      transHealthcareStateFunded: true,
      prepAvailable: true,
      militaryService: 'Open service. No restrictions. Conscription (or civil service) applies to male citizens. Trans persons may be assigned based on legal gender.',
      conversionTherapyBan: ConversionTherapyBan.fullBan,
      conversionTherapyDetails: 'Banned since 2023. Criminal penalties for performing conversion therapy on any person.',
      safetyRating: SafetyRating.verySafe,
      safetyNotes: 'Very safe and progressive. Helsinki has vibrant LGBTQ+ community. Helsinki Pride is one of Finland\'s largest public events. Strong legal protections. High public acceptance, especially among younger population. Rural areas less visible but generally safe.',
      ilgaEuropeRanking: 71.0,
      organizations: [
        LgbtqOrganization(
          name: 'Seta ry (LGBTI Rights in Finland)',
          type: 'community, advocacy, legal aid, asylum support',
          phone: '+358 9 681 2580',
          email: 'info@seta.fi',
          website: 'https://seta.fi',
          address: 'Pasilanraitio 5, 00240 Helsinki',
          languages: 'Finnish, Swedish, English',
          notes: 'National LGBTQ+ organization since 1974. Comprehensive services: legal aid, asylum support, youth groups, counseling, advocacy.',
        ),
        LgbtqOrganization(
          name: 'Finnish Refugee Advice Centre (Pakolaisneuvonta)',
          type: 'asylum support, legal aid',
          phone: '+358 9 2312 0400',
          email: 'info@pakolaisneuvonta.fi',
          website: 'https://www.pakolaisneuvonta.fi',
          languages: 'Finnish, English, Arabic, Somali, Farsi, Russian',
          notes: 'Free legal aid for asylum seekers. SOGI-experienced lawyers on staff.',
        ),
        LgbtqOrganization(
          name: 'Trasek ry',
          type: 'trans support',
          phone: '',
          email: 'info@trasek.fi',
          website: 'https://trasek.fi',
          languages: 'Finnish, English',
          notes: 'Trans rights organization. Healthcare navigation, peer support, advocacy.',
        ),
        LgbtqOrganization(
          name: 'HeSeta (Helsinki Seta)',
          type: 'community, counseling',
          phone: '+358 9 681 2580',
          email: 'heseta@seta.fi',
          website: 'https://heseta.fi',
          languages: 'Finnish, English',
          notes: 'Helsinki-based community center. Drop-in events, counseling, social groups including for immigrants.',
        ),
        LgbtqOrganization(
          name: 'Finnish Red Cross - Asylum Support',
          type: 'asylum support, health',
          phone: '+358 20 701 2000',
          email: 'info@redcross.fi',
          website: 'https://www.redcross.fi',
          languages: 'Finnish, Swedish, English, multiple',
          notes: 'Runs reception centers. Health services. Can coordinate LGBTQ+ safe accommodation.',
        ),
      ],
      immigrantSpecificNotes: 'Foreign same-sex marriages fully recognized. Family reunification for same-sex spouses under same conditions (income requirements apply). Kela services available to residents. Municipal integration program includes all family members.',
      refugeeSpecificNotes: 'Finland has strong SOGI asylum recognition. Seta provides specialized support from initial registration. Finnish Refugee Advice Centre provides essential legal representation. Reception centers generally safe but request LGBTQ+ safe accommodation if needed. Helsinki, Tampere, and Turku have the most LGBTQ+ support resources. Integration services (kotoutuminen) available in Finnish, Swedish, and sometimes other languages.',
    ),

    // -------------------------------------------------------
    // FRANCE (FR)
    // -------------------------------------------------------
    'FR': LgbtqCountryRights(
      country: 'France',
      countryCode: 'FR',
      marriageStatus: MarriageStatus.marriageEquality,
      marriageDetails: 'Same-sex marriage legal since May 18, 2013 (Loi n° 2013-404, "Marriage pour tous"). PACS (Pacte civil de solidarité) available since 1999. Concubinage (cohabitation) also recognized.',
      marriageLegalSince: 2013,
      adoptionRights: AdoptionRights.jointAdoption,
      adoptionDetails: 'Joint adoption since 2013 with marriage equality. Stepchild adoption since 2013. Full equal parental rights for married couples. PMA (medically assisted reproduction) opened to all women and single persons since 2021.',
      ivfAccessForLesbians: true,
      surrogacyLegal: false,
      employmentProtection: true,
      housingProtection: true,
      goodsAndServicesProtection: true,
      constitutionalProtection: false,
      antiDiscriminationLegalBasis: 'Law of November 16, 2001 and Law of December 30, 2004 prohibit discrimination based on sexual orientation and gender identity in employment, housing, goods, services, and education. Défenseur des droits (Rights Ombudsman) handles complaints.',
      genderRecognitionModel: GenderRecognitionModel.selfDetermination,
      genderRecognitionProcess: 'Since 2016 (Law of November 18, 2016, Justice reform). Application to Tribunal judiciaire. Requires evidence of being known in desired gender (social presentation). No medical or surgical requirements. Process takes 3-12 months.',
      genderRecognitionMinAge: 18,
      nonBinaryRecognized: false,
      asylumSogiProcedure: 'Apply at SPADA (structure de premier accueil des demandeurs d\'asile) then GUDA (guichet unique). OFPRA (Office français de protection des réfugiés et apatrides) processes claims. SOGI-trained officers. Appeal to CNDA (Cour nationale du droit d\'asile).',
      asylumSogiLegalBasis: 'CESEDA (Code de l\'entrée et du séjour des étrangers et du droit d\'asile) Article L711-1. SOGI explicitly recognized. France has extensive SOGI asylum case law.',
      asylumSogiSpecificRights: 'Right to SOGI-trained interviewer at OFPRA. Free legal aid. Right to confidentiality. Accommodation through CADA (centres d\'accueil de demandeurs d\'asile). OFPRA has specific SOGI unit.',
      asylumSogiOrgSupport: 'ARDHIS (Association pour la Reconnaissance des Droits des Personnes Homosexuelles et Transsexuelles à l\'Immigration et au Séjour), ORAM France, Cimade, France Terre d\'Asile.',
      hateCrimeLawSogi: true,
      hateSpeechLawSogi: true,
      hateCrimeReportingProcess: 'Report to police/gendarmerie or online (pre-plainte-en-ligne.gouv.fr). Criminal Code Articles 132-77 (aggravating circumstance for SOGI bias), 225-1 (discrimination), 24 of the Law of July 29, 1881 (hate speech/incitement). SOS Homophobie operates a reporting line.',
      bloodDonationPolicy: 'Individual risk assessment since March 2022. No MSM-specific deferral. All donors assessed on individual risk behavior.',
      transHealthcareAccess: 'Available through public hospitals. Main teams in Paris (Pitié-Salpêtrière), Lyon, Bordeaux, Marseille. Hormones and surgery covered by Sécurité sociale (100% for ALD - Affection de Longue Durée). Wait times 6-24 months for surgery.',
      transHealthcareStateFunded: true,
      prepAvailable: true,
      militaryService: 'Open service. No restrictions since 2000. French Armed Forces have non-discrimination policies.',
      conversionTherapyBan: ConversionTherapyBan.fullBan,
      conversionTherapyDetails: 'Banned since January 2022 (Loi n° 2022-92). Criminal offense with penalties up to 2 years imprisonment and €30,000 fine. Aggravated penalties for minors.',
      safetyRating: SafetyRating.safe,
      safetyNotes: 'Generally safe, especially in Paris, Lyon, and other major cities. Le Marais (Paris) is a historic LGBTQ+ district. French Riviera also very accepting. Some violence incidents reported, particularly in certain suburbs. SOS Homophobie monitors incidents.',
      ilgaEuropeRanking: 67.0,
      organizations: [
        LgbtqOrganization(
          name: 'ARDHIS',
          type: 'asylum support, legal aid',
          phone: '+33 7 62 45 73 68',
          email: 'contact@ardhis.org',
          website: 'https://www.ardhis.org',
          address: 'Paris, France',
          languages: 'French, English, Arabic, Russian',
          notes: 'Primary LGBTQ+ asylum/immigration support. Legal aid for OFPRA interviews, accommodation, integration.',
        ),
        LgbtqOrganization(
          name: 'SOS Homophobie',
          type: 'legal aid, reporting, counseling',
          phone: '+33 1 48 06 42 41',
          email: 'sos@sos-homophobie.org',
          website: 'https://www.sos-homophobie.org',
          address: '34 rue Poissonnière, 75002 Paris',
          languages: 'French, English',
          notes: 'Hate crime reporting, legal support, counseling. National listening line. Annual report on homophobia.',
        ),
        LgbtqOrganization(
          name: 'Centre LGBT Paris-ÎdF',
          type: 'community, health, legal aid',
          phone: '+33 1 43 57 21 47',
          email: 'contact@centrelgbtparis.org',
          website: 'https://www.centrelgbtparis.org',
          address: '63 Rue Beaubourg, 75003 Paris',
          languages: 'French, English',
          notes: 'Community center. Health services, legal consultations, social activities, library.',
        ),
        LgbtqOrganization(
          name: 'Acceptess-T',
          type: 'trans support, asylum support',
          phone: '+33 1 42 61 24 89',
          email: 'contact@acceptess-t.com',
          website: 'https://www.acceptess-t.com',
          languages: 'French, English, Spanish, Portuguese',
          notes: 'Trans-specific support, especially for migrants and sex workers. Health, legal, housing.',
        ),
      ],
      immigrantSpecificNotes: 'Foreign same-sex marriages fully recognized. PACS available to foreign nationals. Family reunification for same-sex spouses. Titre de séjour vie privée et familiale for partners. AME (Aide Médicale de l\'État) covers undocumented persons\' healthcare.',
      refugeeSpecificNotes: 'France has extensive SOGI asylum experience. ARDHIS is the key specialized organization. OFPRA has SOGI-trained units. Accommodation system (CADA, HUDA) sometimes problematic for LGBTQ+ persons - request specific placement. Paris has the most resources but Lyon, Marseille, Lille also have support.',
    ),

    // -------------------------------------------------------
    // GERMANY (DE)
    // -------------------------------------------------------
    'DE': LgbtqCountryRights(
      country: 'Germany',
      countryCode: 'DE',
      marriageStatus: MarriageStatus.marriageEquality,
      marriageDetails: 'Same-sex marriage (Ehe für alle) legal since October 1, 2017. Previously registered life partnerships (Lebenspartnerschaft) from 2001.',
      marriageLegalSince: 2017,
      adoptionRights: AdoptionRights.jointAdoption,
      adoptionDetails: 'Joint adoption since 2017 (with marriage). Stepchild adoption since 2005. Constitutional Court (BVerfG) confirmed equal rights in adoption.',
      ivfAccessForLesbians: true,
      surrogacyLegal: false,
      employmentProtection: true,
      housingProtection: true,
      goodsAndServicesProtection: true,
      constitutionalProtection: false,
      antiDiscriminationLegalBasis: 'General Equal Treatment Act (Allgemeines Gleichbehandlungsgesetz, AGG, 2006) covers sexual orientation and gender identity in employment, housing, goods, services, education. Federal Anti-Discrimination Agency (Antidiskriminierungsstelle) handles complaints.',
      genderRecognitionModel: GenderRecognitionModel.selfDetermination,
      genderRecognitionProcess: 'Self-Determination Act (Selbstbestimmungsgesetz, SBGG) since November 1, 2024, replacing 1980 Transsexuellengesetz. Application at Standesamt (civil registry). Declaration 3 months in advance, no medical requirements. Non-binary option "divers" since 2018 (Constitutional Court ruling).',
      genderRecognitionMinAge: 14,
      nonBinaryRecognized: true,
      asylumSogiProcedure: 'Apply at BAMF (Bundesamt für Migration und Flüchtlinge). SOGI claims well-established. BAMF has SOGI-specialized decision-makers. Interview with trained officer. Appeal to Administrative Court (Verwaltungsgericht). Extensive case law.',
      asylumSogiLegalBasis: 'Asylum Act (Asylgesetz) and Residence Act (Aufenthaltsgesetz) transposing EU Qualification Directive. SOGI explicitly recognized. BAMF has internal SOGI guidelines.',
      asylumSogiSpecificRights: 'Right to SOGI-trained interviewer. Right to request same-sex interviewer. Free legal aid (Beratungshilfe). Accommodation considerations. BAMF has dedicated SOGI competence centers.',
      asylumSogiOrgSupport: 'Schwulenberatung Berlin, LesMigraS (Lesbenberatung Berlin), LSVD (Lesben- und Schwulenverband), Queer Refugees Deutschland.',
      hateCrimeLawSogi: true,
      hateSpeechLawSogi: true,
      hateCrimeReportingProcess: 'Report to police (Polizei, 110). Criminal Code Section 46(2) recognizes bias motive as aggravating. Section 130 (Volksverhetzung) covers incitement to hatred. Report also to Antidiskriminierungsstelle. MANEO (Berlin) operates a hate crime reporting system.',
      bloodDonationPolicy: 'Individual risk assessment since 2023. No MSM-specific deferral. Based on individual sexual risk behavior.',
      transHealthcareAccess: 'Hormones and surgery covered by statutory health insurance (Gesetzliche Krankenversicherung). Available at university hospitals and specialized clinics. Wait times 3-18 months. Self-Determination Act separated legal recognition from medical requirements.',
      transHealthcareStateFunded: true,
      prepAvailable: true,
      militaryService: 'Open service. No restrictions. Bundeswehr has LGBTQ+ network (QueerBw). Official apology issued in 2021 for past discrimination.',
      conversionTherapyBan: ConversionTherapyBan.minorsBan,
      conversionTherapyDetails: 'Banned on minors since 2020 (Gesetz zum Schutz vor Konversionsbehandlungen). Also banned on adults who cannot consent or are coerced. Penalties include imprisonment up to 1 year and fines.',
      safetyRating: SafetyRating.verySafe,
      safetyNotes: 'Very safe overall. Berlin is one of Europe\'s most LGBTQ+ friendly cities. Cologne, Hamburg, Munich also excellent. Christopher Street Day (CSD) celebrations nationwide. Some concerns about hate crimes rising in frequency though. Rural eastern Germany less accepting.',
      ilgaEuropeRanking: 63.0,
      organizations: [
        LgbtqOrganization(
          name: 'Schwulenberatung Berlin',
          type: 'community, asylum support, health, counseling',
          phone: '+49 30 233 69 070',
          email: 'info@schwulenberatungberlin.de',
          website: 'https://www.schwulenberatungberlin.de',
          address: 'Niebuhrstr. 59/60, 10629 Berlin',
          languages: 'German, English, Arabic, Farsi, Russian, Turkish, French',
          notes: 'Comprehensive LGBTQ+ center. Refugee program, housing, health, counseling. Operates refugee shelter.',
        ),
        LgbtqOrganization(
          name: 'LSVD (Lesben- und Schwulenverband)',
          type: 'advocacy, legal aid',
          phone: '+49 30 789 954 30',
          email: 'lsvd@lsvd.de',
          website: 'https://www.lsvd.de',
          languages: 'German, English',
          notes: 'National LGBTQ+ advocacy organization. Legal aid, Queer Refugees project.',
        ),
        LgbtqOrganization(
          name: 'Queer Refugees Deutschland',
          type: 'asylum support, community',
          phone: '+49 30 789 954 30',
          email: 'queerrefugees@lsvd.de',
          website: 'https://www.queer-refugees.de',
          languages: 'German, English, Arabic, Farsi, Russian, Turkish, French',
          notes: 'LSVD project specifically for LGBTQ+ refugees. Information, referral, networking.',
        ),
        LgbtqOrganization(
          name: 'LesMigraS (Lesbenberatung Berlin)',
          type: 'community, counseling, asylum support',
          phone: '+49 30 219 15 090',
          email: 'info@lesmigras.de',
          website: 'https://www.lesmigras.de',
          languages: 'German, English, Turkish, Arabic, Spanish',
          notes: 'Lesbian and bisexual women, trans persons, especially with migration background. Anti-violence work.',
        ),
        LgbtqOrganization(
          name: 'dgti (Deutsche Gesellschaft für Transidentität und Intersexualität)',
          type: 'trans support',
          phone: '+49 211 910 5357',
          email: 'info@dgti.org',
          website: 'https://dgti.org',
          languages: 'German, English',
          notes: 'Trans and intersex support. Issues supplementary ID card. Healthcare navigation.',
        ),
      ],
      immigrantSpecificNotes: 'Foreign same-sex marriages fully recognized. Family reunification for same-sex spouses. Residence permit for family reunion (Aufenthaltserlaubnis zum Familiennachzug). Registration at Bürgeramt straightforward. Berlin, Cologne, Hamburg have largest LGBTQ+ immigrant communities.',
      refugeeSpecificNotes: 'Germany has the most extensive SOGI asylum infrastructure in the EU. Schwulenberatung Berlin operates dedicated shelter. BAMF SOGI competence centers in Nuremberg and branch offices. Queer Refugees Deutschland provides nationwide network. Major cities have specialized programs. Note: Dublin procedure may still apply.',
    ),

    // -------------------------------------------------------
    // GREECE (GR)
    // -------------------------------------------------------
    'GR': LgbtqCountryRights(
      country: 'Greece',
      countryCode: 'GR',
      marriageStatus: MarriageStatus.marriageEquality,
      marriageDetails: 'Same-sex marriage legal since February 2024 (Law 5089/2024). Greece became the first Orthodox-majority country to legalize same-sex marriage. Previously, cohabitation agreements available since 2015.',
      marriageLegalSince: 2024,
      adoptionRights: AdoptionRights.stepchildOnly,
      adoptionDetails: 'Stepchild adoption for married same-sex couples since 2024. Joint adoption not available - only for married different-sex couples. Foster care available to individuals.',
      ivfAccessForLesbians: false,
      surrogacyLegal: false,
      employmentProtection: true,
      housingProtection: true,
      goodsAndServicesProtection: true,
      constitutionalProtection: false,
      antiDiscriminationLegalBasis: 'Law 4443/2016 implements EU Employment Equality Directive. Law 4356/2015 (Cohabitation Pact) and Law 4491/2017 cover gender identity. Greek Ombudsman handles discrimination complaints.',
      genderRecognitionModel: GenderRecognitionModel.selfDetermination,
      genderRecognitionProcess: 'Self-determination since 2017 (Law 4491/2017). Application to court (Eiriniodikio). Hearing without medical requirements. Available from age 17 (15 with parental consent and court approval). No surgery, diagnosis, or sterilization required.',
      genderRecognitionMinAge: 15,
      nonBinaryRecognized: false,
      asylumSogiProcedure: 'Apply at Regional Asylum Office or Reception and Identification Center. SOGI claims recognized by Greek Asylum Service. Personal interview. Appeal to Appeals Authority. Greek Council for Refugees provides legal aid.',
      asylumSogiLegalBasis: 'Law 4636/2019 (International Protection Act) transposing EU Qualification Directive. SOGI recognized under particular social group.',
      asylumSogiSpecificRights: 'Right to confidential interview. Free legal aid through UNHCR partners. Accommodation through ESTIA program. Greece handles large numbers of asylum seekers on islands and mainland.',
      asylumSogiOrgSupport: 'Greek Council for Refugees, UNHCR Greece, Colour Youth Athens, OLKE (Homosexual and Lesbian Community of Greece).',
      hateCrimeLawSogi: true,
      hateSpeechLawSogi: true,
      hateCrimeReportingProcess: 'Report to police or Racist Violence Recording Network (coordinated by UNHCR and Greek National Commission for Human Rights). Law 4285/2014 (anti-racism law) covers sexual orientation and gender identity.',
      bloodDonationPolicy: '12-month deferral for MSM.',
      transHealthcareAccess: 'Hormones available through endocrinologists. Surgery available at some Athens hospitals. Partially covered by EOPYY (national health insurance) but bureaucratic process. Wait times variable.',
      transHealthcareStateFunded: true,
      prepAvailable: true,
      militaryService: 'Open service. No restrictions. Conscription for male citizens.',
      conversionTherapyBan: ConversionTherapyBan.fullBan,
      conversionTherapyDetails: 'Banned since 2022 (Law 4958/2022). Criminal penalties for conversion practices on any person. Part of broader LGBTQ+ rights reform.',
      safetyRating: SafetyRating.safe,
      safetyNotes: 'Rapidly improving. Athens has vibrant LGBTQ+ scene, especially in Gazi area. Athens Pride well-attended. Thessaloniki also active. Islands (especially Mykonos, Lesbos) LGBTQ+ friendly. Some concerns about far-right groups. Orthodox Church opposition but not translating to public violence.',
      ilgaEuropeRanking: 57.0,
      organizations: [
        LgbtqOrganization(
          name: 'Greek Council for Refugees',
          type: 'asylum support, legal aid',
          phone: '+30 210 380 0990',
          email: 'gcr@gcr.gr',
          website: 'https://www.gcr.gr',
          languages: 'Greek, English, Arabic, French, Farsi',
          notes: 'Legal aid for asylum seekers including SOGI claims.',
        ),
        LgbtqOrganization(
          name: 'Colour Youth Athens - LGBTQ Youth Community',
          type: 'community, youth',
          phone: '+30 210 822 7205',
          email: 'info@colouryouth.gr',
          website: 'https://www.colouryouth.gr',
          languages: 'Greek, English',
          notes: 'LGBTQ+ youth organization. Support groups, events, advocacy.',
        ),
        LgbtqOrganization(
          name: 'OLKE (Homosexual and Lesbian Community of Greece)',
          type: 'community, advocacy',
          phone: '+30 210 924 6022',
          email: 'info@olke.org',
          website: 'https://www.olke.org',
          languages: 'Greek, English',
          notes: 'Main LGBTQ+ advocacy organization. Athens Pride organizer.',
        ),
        LgbtqOrganization(
          name: 'Transgender Support Association (SYD)',
          type: 'trans support',
          phone: '',
          email: 'info@tgender.gr',
          website: 'https://tgender.gr',
          languages: 'Greek, English',
          notes: 'Trans support, legal gender recognition assistance, healthcare navigation.',
        ),
      ],
      immigrantSpecificNotes: 'Same-sex marriages recognized since 2024. Cohabitation agreements available to foreigners. Family reunification for same-sex spouses. Athens is the main hub for LGBTQ+ immigrants. Island reception centers may lack LGBTQ+ support.',
      refugeeSpecificNotes: 'Greece processes large numbers of asylum seekers. SOGI claims recognized but system overwhelmed. Island hotspots (Lesbos, Samos, etc.) may be unsafe for openly LGBTQ+ asylum seekers. Request transfer to mainland if possible. Greek Council for Refugees and UNHCR are key resources. Athens has the most LGBTQ+ support infrastructure.',
    ),

    // -------------------------------------------------------
    // HUNGARY (HU)
    // -------------------------------------------------------
    'HU': LgbtqCountryRights(
      country: 'Hungary',
      countryCode: 'HU',
      marriageStatus: MarriageStatus.registeredPartnership,
      marriageDetails: 'Registered partnership (bejegyzett élettársi kapcsolat) since 2009 for same-sex couples. Constitution (Fundamental Law, 2012) defines marriage as man-woman. Anti-LGBTQ+ legislation passed in 2021 restricts "promotion" of LGBTQ+ content to minors.',
      marriageLegalSince: 0,
      adoptionRights: AdoptionRights.none,
      adoptionDetails: 'No joint adoption. No stepchild adoption. Single-person adoption restricted since 2020 amendment requiring special ministerial permission for unmarried applicants.',
      ivfAccessForLesbians: false,
      surrogacyLegal: false,
      employmentProtection: true,
      housingProtection: true,
      goodsAndServicesProtection: true,
      constitutionalProtection: false,
      antiDiscriminationLegalBasis: 'Act CXXV of 2003 on Equal Treatment covers sexual orientation in employment, housing, education, services. Equal Treatment Authority (merged into Commissioner for Fundamental Rights). Note: 2021 "child protection" law limits LGBTQ+ visibility.',
      genderRecognitionModel: GenderRecognitionModel.noProcess,
      genderRecognitionProcess: 'Legal gender recognition effectively suspended since May 2020 when Parliament passed law defining sex as "sex at birth" in official documents (Amendment to Civil Registry Act). No legal pathway currently available. Previous system required medical diagnosis.',
      genderRecognitionMinAge: 0,
      nonBinaryRecognized: false,
      asylumSogiProcedure: 'Hungary\'s asylum system severely restricted since 2020. Transit zones closed (CJEU ruling). Must apply from embassies or at border. National Directorate-General for Aliens Policing processes claims. SOGI claims theoretically accepted but system hostile. Hungarian Helsinki Committee provides legal aid.',
      asylumSogiLegalBasis: 'Act LXXX of 2007 on Asylum (heavily amended). EU Qualification Directive theoretically applies but implementation problematic after 2015-2020 restrictions.',
      asylumSogiSpecificRights: 'Very limited in practice. Hungarian Helsinki Committee provides critical legal aid. EU Commission has initiated infringement proceedings over asylum restrictions. LGBTQ+ asylum seekers face dual stigmatization.',
      asylumSogiOrgSupport: 'Hungarian Helsinki Committee, Háttér Society, UNHCR Hungary.',
      hateCrimeLawSogi: false,
      hateSpeechLawSogi: false,
      hateCrimeReportingProcess: 'Report to police. No specific SOGI hate crime legislation. General criminal provisions may apply. Háttér Society can assist with documentation and legal referrals.',
      bloodDonationPolicy: 'Permanent deferral for MSM.',
      transHealthcareAccess: 'Severely restricted since 2020. Legal gender recognition suspended. Hormones available from some endocrinologists privately but no structured gender-affirming care pathway. Most trans persons seek care abroad. No state funding.',
      transHealthcareStateFunded: false,
      prepAvailable: false,
      militaryService: 'Open service. No formal restrictions based on sexual orientation.',
      conversionTherapyBan: ConversionTherapyBan.noBan,
      conversionTherapyDetails: 'No ban. Government rhetoric has been hostile to LGBTQ+ rights. Some church-affiliated programs reportedly operate.',
      safetyRating: SafetyRating.caution,
      safetyNotes: 'Deteriorating environment since 2018. Budapest Pride still occurs but under police protection and political opposition. 2021 "child protection" law equating LGBTQ+ content with pedophilia created hostile atmosphere. Budapest relatively safer than rural areas. Government rhetoric encourages social hostility.',
      ilgaEuropeRanking: 27.0,
      organizations: [
        LgbtqOrganization(
          name: 'Háttér Society (Háttér Társaság)',
          type: 'community, legal aid, advocacy',
          phone: '+36 1 329 3380',
          email: 'info@hatter.hu',
          website: 'https://hfratter.hu',
          address: 'Budapest, Hungary',
          languages: 'Hungarian, English',
          notes: 'Main LGBTQ+ organization. Legal aid, hate crime documentation, counseling, advocacy.',
        ),
        LgbtqOrganization(
          name: 'Hungarian Helsinki Committee',
          type: 'asylum support, legal aid',
          phone: '+36 1 321 4323',
          email: 'helsinki@helsinki.hu',
          website: 'https://helsinki.hu',
          languages: 'Hungarian, English',
          notes: 'Critical legal aid for asylum seekers. Human rights monitoring.',
        ),
        LgbtqOrganization(
          name: 'Transvanilla Transgender Association',
          type: 'trans support',
          phone: '',
          email: 'info@transvanilla.hu',
          website: 'https://transvanilla.hu',
          languages: 'Hungarian, English',
          notes: 'Trans rights advocacy and support. Monitoring legal gender recognition suspension.',
        ),
      ],
      immigrantSpecificNotes: 'Registered partnerships available but with fewer rights than marriage. Foreign same-sex marriages recognized as registered partnerships. Family reunification for partners technically available but process may be obstructive. Consider other EU countries if possible.',
      refugeeSpecificNotes: 'Hungary is NOT recommended for LGBTQ+ asylum seekers. Asylum system severely restricted. Government hostility to both LGBTQ+ rights and refugees. Hungarian Helsinki Committee can provide emergency legal aid. If in Hungary, consider applying for transfer to another EU country under Dublin procedure. Budapest is the only city with any LGBTQ+ support infrastructure.',
    ),

    // -------------------------------------------------------
    // IRELAND (IE)
    // -------------------------------------------------------
    'IE': LgbtqCountryRights(
      country: 'Ireland',
      countryCode: 'IE',
      marriageStatus: MarriageStatus.marriageEquality,
      marriageDetails: 'Same-sex marriage legal since November 16, 2015. First country to legalize by popular referendum (62% yes, May 22, 2015). Civil partnerships available since 2011.',
      marriageLegalSince: 2015,
      adoptionRights: AdoptionRights.jointAdoption,
      adoptionDetails: 'Joint adoption since 2015 (Adoption (Amendment) Act 2017 and Children and Family Relationships Act 2015). Full equal adoption rights for married same-sex couples.',
      ivfAccessForLesbians: true,
      surrogacyLegal: false,
      employmentProtection: true,
      housingProtection: true,
      goodsAndServicesProtection: true,
      constitutionalProtection: true,
      antiDiscriminationLegalBasis: 'Employment Equality Acts 1998-2015 and Equal Status Acts 2000-2018 cover sexual orientation and gender identity. Article 40.1 of Constitution (equality). Irish Human Rights and Equality Commission (IHREC) is equality body.',
      genderRecognitionModel: GenderRecognitionModel.selfDetermination,
      genderRecognitionProcess: 'Self-determination since 2015 (Gender Recognition Act 2015). Apply to Department of Social Protection. Statutory declaration, no medical requirements for adults over 18. For 16-17: requires court order and parental consent with medical evidence. Under 16: not available.',
      genderRecognitionMinAge: 16,
      nonBinaryRecognized: false,
      asylumSogiProcedure: 'Apply to International Protection Office (IPO). SOGI claims well-recognized under International Protection Act 2015. Personal interview with IPO officer. Appeal to International Protection Appeals Tribunal (IPAT). Legal aid through Legal Aid Board.',
      asylumSogiLegalBasis: 'International Protection Act 2015 transposing EU Qualification Directive. SOGI recognized under particular social group. Ireland has positive SOGI asylum case law.',
      asylumSogiSpecificRights: 'Right to confidential interview. Free legal aid through Legal Aid Board. Accommodation through IPAS (International Protection Accommodation Services). Irish Refugee Council provides support.',
      asylumSogiOrgSupport: 'BeLonG To Youth Services, LGBT Ireland, Irish Refugee Council, TENI (Transgender Equality Network Ireland), MASI (Movement of Asylum Seekers in Ireland).',
      hateCrimeLawSogi: true,
      hateSpeechLawSogi: true,
      hateCrimeReportingProcess: 'Report to An Garda Síochána (police). Criminal Justice (Incitement to Violence or Hatred and Hate Offences) Act 2023 covers sexual orientation, gender identity, and sex characteristics. Comprehensive hate crime legislation.',
      bloodDonationPolicy: 'Individual risk assessment since 2022. No MSM-specific deferral. Irish Blood Transfusion Service assesses all donors equally.',
      transHealthcareAccess: 'National Gender Service at St. Columcille\'s Hospital, Dublin. Hormones covered by HSE. Surgery referrals mainly to UK (NHS). Wait times significant (2-4 years for first appointment). Efforts to expand capacity.',
      transHealthcareStateFunded: true,
      prepAvailable: true,
      militaryService: 'Open service. No restrictions. Defence Forces have equality policies.',
      conversionTherapyBan: ConversionTherapyBan.noBan,
      conversionTherapyDetails: 'No specific ban as of 2025. Bill proposed but not yet enacted. Professional bodies (PSI, IACP) have position statements against conversion therapy.',
      safetyRating: SafetyRating.verySafe,
      safetyNotes: 'Very safe. Remarkable social transformation - from criminalizing homosexuality (until 1993) to marriage equality by referendum. Dublin has vibrant LGBTQ+ scene. Strong public support. Minor concerns about transphobic rhetoric in some media. Overall very accepting society.',
      ilgaEuropeRanking: 63.0,
      organizations: [
        LgbtqOrganization(
          name: 'LGBT Ireland',
          type: 'community, counseling, referral',
          phone: '+353 1 907 3707',
          email: 'info@lgbt.ie',
          website: 'https://www.lgbt.ie',
          languages: 'English, Irish',
          notes: 'National support and referral service. Peer counseling, information, community.',
        ),
        LgbtqOrganization(
          name: 'Irish Refugee Council',
          type: 'asylum support, legal aid',
          phone: '+353 1 764 5854',
          email: 'info@irishrefugeecouncil.ie',
          website: 'https://www.irishrefugeecouncil.ie',
          languages: 'English, Arabic, French',
          notes: 'Legal aid and support for asylum seekers including SOGI claims.',
        ),
        LgbtqOrganization(
          name: 'TENI (Transgender Equality Network Ireland)',
          type: 'trans support, advocacy',
          phone: '+353 1 873 3575',
          email: 'info@teni.ie',
          website: 'https://www.teni.ie',
          languages: 'English',
          notes: 'Trans support, healthcare navigation, legal gender recognition assistance, advocacy.',
        ),
        LgbtqOrganization(
          name: 'BeLonG To Youth Services',
          type: 'youth, community',
          phone: '+353 1 670 6223',
          email: 'info@belongto.org',
          website: 'https://www.belongto.org',
          languages: 'English',
          notes: 'LGBTQ+ youth services. Support, education, crisis intervention.',
        ),
      ],
      immigrantSpecificNotes: 'Foreign same-sex marriages fully recognized. Family reunification for same-sex spouses under Immigration Act. Registration straightforward. Dublin has strong LGBTQ+ immigrant community. STAMP 4 holders have full rights.',
      refugeeSpecificNotes: 'Ireland has a welcoming reputation for LGBTQ+ asylum seekers. International Protection Act provides clear framework. Irish Refugee Council and LGBT Ireland both provide support. Direct Provision accommodation system has been reformed. Request consideration for LGBTQ+ safe housing if needed.',
    ),

    // -------------------------------------------------------
    // ITALY (IT)
    // -------------------------------------------------------
    'IT': LgbtqCountryRights(
      country: 'Italy',
      countryCode: 'IT',
      marriageStatus: MarriageStatus.registeredPartnership,
      marriageDetails: 'Civil unions (Unione civile) since June 2016 (Legge Cirinnà, Law 76/2016). Not full marriage - lacks automatic parental recognition and adoption provision (stepchild adoption removed during passage). Some municipalities register foreign same-sex marriages.',
      marriageLegalSince: 0,
      adoptionRights: AdoptionRights.stepchildOnly,
      adoptionDetails: 'Stepchild adoption granted by courts on case-by-case basis (adopzione in casi particolari, Art. 44 Law 184/1983). Not guaranteed in statute. No joint adoption. Court practice varies by region.',
      ivfAccessForLesbians: false,
      surrogacyLegal: false,
      employmentProtection: true,
      housingProtection: false,
      goodsAndServicesProtection: false,
      constitutionalProtection: false,
      antiDiscriminationLegalBasis: 'Legislative Decree 216/2003 covers employment discrimination on sexual orientation (implementing EU Employment Directive). No comprehensive anti-discrimination law covering housing/services. DDL Zan (comprehensive bill) failed in 2021.',
      genderRecognitionModel: GenderRecognitionModel.medicalRequired,
      genderRecognitionProcess: 'Under Law 164/1982 (gender reassignment). Application to Tribunale. Requires medical documentation. Constitutional Court ruled in 2015 (Ruling 221/2015) that surgery is not mandatory but medical pathway still required. Process takes 1-3 years.',
      genderRecognitionMinAge: 18,
      nonBinaryRecognized: false,
      asylumSogiProcedure: 'Apply at Questura (police headquarters) or at border. Territorial Commission processes claims. SOGI recognized. Interview with commission member. Appeal to specialized judicial sections (sezioni specializzate). UNHCR Italy provides support.',
      asylumSogiLegalBasis: 'Legislative Decree 251/2007 (transposing EU Qualification Directive). SOGI as particular social group. Italy has significant SOGI asylum case law due to high numbers.',
      asylumSogiSpecificRights: 'Right to confidential interview. Free legal aid. Accommodation through SAI (Sistema di Accoglienza e Integrazione) system. SOGI-sensitive placement can be requested.',
      asylumSogiOrgSupport: 'Arcigay, MIT (Movimento Identità Trans), ASGI (Associazione Studi Giuridici sull\'Immigrazione), UNHCR Italy, CIR (Consiglio Italiano per i Rifugiati).',
      hateCrimeLawSogi: false,
      hateSpeechLawSogi: false,
      hateCrimeReportingProcess: 'Report to Carabinieri or Polizia. No specific SOGI hate crime legislation (DDL Zan failed in 2021). General aggravating circumstances may be applied. Arcigay and other organizations document incidents. OSCAD (Observatory for Security Against Acts of Discrimination) within police monitors hate crimes.',
      bloodDonationPolicy: 'Individual risk assessment. No permanent MSM deferral. Assessment based on recent sexual behaviors.',
      transHealthcareAccess: 'Available through public healthcare (SSN) at specialized centers. Main centers in Milan (Niguarda), Rome, Bologna, Naples. Hormones and surgery covered by SSN with referral. Wait times 1-3 years. Quality varies by region (north generally better).',
      transHealthcareStateFunded: true,
      prepAvailable: true,
      militaryService: 'Open service. No restrictions based on sexual orientation.',
      conversionTherapyBan: ConversionTherapyBan.noBan,
      conversionTherapyDetails: 'No national ban. Some regional resolutions against conversion therapy (e.g., Lazio, Campania). Professional codes discourage it but no legal prohibition.',
      safetyRating: SafetyRating.moderate,
      safetyNotes: 'Variable by region. Milan, Rome, Bologna, Turin are generally LGBTQ+ friendly. Southern Italy and rural areas less accepting. Pride events in major cities. Political landscape mixed - right-wing government may affect policies. Violence incidents occur. LGBTQ+ visibility increasing especially in north.',
      ilgaEuropeRanking: 26.0,
      organizations: [
        LgbtqOrganization(
          name: 'Arcigay',
          type: 'community, advocacy, legal aid',
          phone: '+39 051 095 7241',
          email: 'info@arcigay.it',
          website: 'https://www.arcigay.it',
          languages: 'Italian, English',
          notes: 'Largest LGBTQ+ organization in Italy. 60+ local branches. Legal aid, community, advocacy.',
        ),
        LgbtqOrganization(
          name: 'MIT (Movimento Identità Trans)',
          type: 'trans support, asylum support',
          phone: '+39 051 232 722',
          email: 'mit.aps@gmail.com',
          website: 'https://mit-italia.it',
          address: 'Via Polese 22, 40122 Bologna',
          languages: 'Italian, English, Spanish, Portuguese',
          notes: 'Trans support organization. Shelter for trans asylum seekers, healthcare, legal aid.',
        ),
        LgbtqOrganization(
          name: 'ASGI (Associazione Studi Giuridici sull\'Immigrazione)',
          type: 'legal aid, asylum support',
          phone: '+39 011 436 2460',
          email: 'segreteria@asgi.it',
          website: 'https://www.asgi.it',
          languages: 'Italian, English, French',
          notes: 'Immigration law experts. Legal aid for asylum seekers including SOGI claims.',
        ),
        LgbtqOrganization(
          name: 'CIR (Consiglio Italiano per i Rifugiati)',
          type: 'asylum support, legal aid',
          phone: '+39 06 692 00 114',
          email: 'cir@cir-onlus.org',
          website: 'https://www.cir-onlus.org',
          languages: 'Italian, English, French, Arabic',
          notes: 'Italian Refugee Council. Legal aid and support for asylum seekers.',
        ),
      ],
      immigrantSpecificNotes: 'Civil unions available to foreign nationals. Foreign same-sex marriages may be recognized as civil unions (varies by municipality). Family reunification for civil union partners possible. North of Italy generally more welcoming. Milan has the largest LGBTQ+ immigrant community.',
      refugeeSpecificNotes: 'Italy processes large numbers of SOGI asylum claims, especially from sub-Saharan Africa. System experienced but quality varies. MIT in Bologna operates a trans refugee shelter (rare in Europe). SAI accommodation system can provide LGBTQ+ safe placement if requested. Major cities have the most resources. Legal aid essential for navigation.',
    ),

    // -------------------------------------------------------
    // LATVIA (LV)
    // -------------------------------------------------------
    'LV': LgbtqCountryRights(
      country: 'Latvia',
      countryCode: 'LV',
      marriageStatus: MarriageStatus.cohabitation,
      marriageDetails: 'No same-sex marriage (Constitution Article 110 defines marriage as man-woman since 2006). No registered partnership. Constitutional Court ruled in 2020 that same-sex cohabiting couples must be recognized for certain legal purposes (social benefits). Notarized cohabitation agreements provide limited protection.',
      marriageLegalSince: 0,
      adoptionRights: AdoptionRights.none,
      adoptionDetails: 'No adoption rights for same-sex couples. Individual adoption possible but joint adoption and stepchild adoption not available.',
      ivfAccessForLesbians: false,
      surrogacyLegal: false,
      employmentProtection: true,
      housingProtection: false,
      goodsAndServicesProtection: false,
      constitutionalProtection: false,
      antiDiscriminationLegalBasis: 'Labour Law Article 29 prohibits discrimination on sexual orientation in employment. No comprehensive anti-discrimination law covering housing or services on SOGI grounds. Ombudsman handles complaints.',
      genderRecognitionModel: GenderRecognitionModel.medicalRequired,
      genderRecognitionProcess: 'Legal gender change possible under Civil Status Documents Law. Requires medical documentation from healthcare provider. No specific procedure codified. Case-by-case through ZZDATS (Office of Citizenship and Migration Affairs).',
      genderRecognitionMinAge: 18,
      nonBinaryRecognized: false,
      asylumSogiProcedure: 'Apply at Office of Citizenship and Migration Affairs (PMLP). SOGI claims accepted. Interview with asylum officer. Latvian Centre for Human Rights provides legal assistance.',
      asylumSogiLegalBasis: 'Asylum Law transposing EU Qualification Directive. SOGI recognized under particular social group.',
      asylumSogiSpecificRights: 'Right to confidential interview. Free legal aid through state-funded legal assistance. Accommodation in Mucenieki reception center.',
      asylumSogiOrgSupport: 'Mozaīka (LGBTQ+ organization), Latvian Centre for Human Rights, UNHCR representative.',
      hateCrimeLawSogi: false,
      hateSpeechLawSogi: false,
      hateCrimeReportingProcess: 'Report to State Police (Valsts policija). No SOGI-specific hate crime legislation. General criminal provisions may apply. Mozaīka can assist with documentation.',
      bloodDonationPolicy: 'Permanent deferral for MSM.',
      transHealthcareAccess: 'Very limited. Some endocrinological care available in Riga. No structured gender-affirming care pathway. Most trans persons seek care abroad (often in neighboring countries). Not covered by state health insurance.',
      transHealthcareStateFunded: false,
      prepAvailable: false,
      militaryService: 'Open service. No formal restrictions on sexual orientation.',
      conversionTherapyBan: ConversionTherapyBan.noBan,
      conversionTherapyDetails: 'No ban. Some religious organizations promote conversion therapy.',
      safetyRating: SafetyRating.caution,
      safetyNotes: 'Challenging environment. Baltic Pride in Riga occurs under police protection. Social attitudes slowly improving but significant hostility remains. Political resistance to LGBTQ+ rights. Riga relatively more tolerant than rural areas.',
      ilgaEuropeRanking: 21.0,
      organizations: [
        LgbtqOrganization(
          name: 'Mozaīka',
          type: 'community, advocacy',
          phone: '+371 27 57 47 76',
          email: 'info@mozaika.lv',
          website: 'https://www.mozaika.lv',
          address: 'Riga, Latvia',
          languages: 'Latvian, English, Russian',
          notes: 'Main LGBTQ+ organization. Advocacy, community, Baltic Pride organizer.',
        ),
        LgbtqOrganization(
          name: 'Latvian Centre for Human Rights',
          type: 'legal aid',
          phone: '+371 67 039 290',
          email: 'office@humanrights.org.lv',
          website: 'https://www.humanrights.org.lv',
          languages: 'Latvian, English, Russian',
          notes: 'Human rights legal aid including for LGBTQ+ discrimination cases.',
        ),
      ],
      immigrantSpecificNotes: 'No recognition of foreign same-sex marriages or partnerships. Family reunification for same-sex partners not available. LGBTQ+ immigrants may face social isolation. Riga has the only LGBTQ+ community infrastructure.',
      refugeeSpecificNotes: 'Low asylum numbers. Limited SOGI expertise in asylum system. Latvian Centre for Human Rights provides legal support. Consider whether Latvia is the best destination for LGBTQ+ asylum seekers within the EU.',
    ),

    // -------------------------------------------------------
    // LITHUANIA (LT)
    // -------------------------------------------------------
    'LT': LgbtqCountryRights(
      country: 'Lithuania',
      countryCode: 'LT',
      marriageStatus: MarriageStatus.none,
      marriageDetails: 'No legal recognition. Constitution (Article 38) defines marriage as man-woman. No registered partnership or cohabitation law. Partnership bill debated in Seimas but not passed as of 2025.',
      marriageLegalSince: 0,
      adoptionRights: AdoptionRights.none,
      adoptionDetails: 'No adoption rights for same-sex couples. Individual adoption theoretically possible but practically very difficult for openly LGBTQ+ persons.',
      ivfAccessForLesbians: false,
      surrogacyLegal: false,
      employmentProtection: true,
      housingProtection: false,
      goodsAndServicesProtection: false,
      constitutionalProtection: false,
      antiDiscriminationLegalBasis: 'Law on Equal Treatment (2005) covers sexual orientation in employment. Does not cover housing or services. Equal Opportunities Ombudsperson handles complaints. Note: Law on the Protection of Minors from Detrimental Public Information (2009, amended 2014) restricted LGBTQ+ content to minors.',
      genderRecognitionModel: GenderRecognitionModel.noProcess,
      genderRecognitionProcess: 'No legal gender recognition process. ECHR ruled in L. v. Lithuania (2007) that Lithuania must provide legal gender recognition, but government has not implemented the ruling despite 17+ years. Draft legislation periodically proposed but not enacted.',
      genderRecognitionMinAge: 0,
      nonBinaryRecognized: false,
      asylumSogiProcedure: 'Apply at Migration Department. SOGI claims accepted in principle. Interview with migration officer. Lithuanian Red Cross provides some support. Appeal to Vilnius Regional Administrative Court.',
      asylumSogiLegalBasis: 'Law on the Legal Status of Aliens transposing EU Qualification Directive. SOGI as particular social group.',
      asylumSogiSpecificRights: 'Right to confidential interview. Free legal aid through state system. Accommodation in Rukla Refugee Reception Centre. Limited SOGI-specific protocols.',
      asylumSogiOrgSupport: 'Lithuanian Gay League (LGL), Lithuanian Red Cross, Caritas Lithuania.',
      hateCrimeLawSogi: false,
      hateSpeechLawSogi: false,
      hateCrimeReportingProcess: 'Report to police. No SOGI-specific hate crime legislation. Criminal Code Article 170 covers incitement against groups but sexual orientation not explicitly listed. LGL documents incidents.',
      bloodDonationPolicy: 'Permanent deferral for MSM.',
      transHealthcareAccess: 'No structured care pathway. Some psychiatrists and endocrinologists may provide care individually. No gender-affirming surgery capacity. Not covered by state insurance. Trans persons typically seek care in other EU countries.',
      transHealthcareStateFunded: false,
      prepAvailable: false,
      militaryService: 'Open service. No formal restrictions. Conscription reintroduced in 2015 for all eligible males.',
      conversionTherapyBan: ConversionTherapyBan.noBan,
      conversionTherapyDetails: 'No ban. Religious organizations have promoted conversion practices.',
      safetyRating: SafetyRating.caution,
      safetyNotes: 'Challenging. Vilnius and Kaunas have small LGBTQ+ communities. Baltic Pride held in Vilnius under police protection. Political hostility significant. Social attitudes slowly changing among younger generation but overall conservative. Violence incidents documented.',
      ilgaEuropeRanking: 19.0,
      organizations: [
        LgbtqOrganization(
          name: 'Lithuanian Gay League (LGL)',
          type: 'community, advocacy, legal aid',
          phone: '+370 5 261 0466',
          email: 'lgl@lgl.lt',
          website: 'https://www.lgl.lt',
          address: 'Vilnius, Lithuania',
          languages: 'Lithuanian, English, Russian',
          notes: 'Main LGBTQ+ organization. Advocacy, legal support, community events, Baltic Pride.',
        ),
      ],
      immigrantSpecificNotes: 'No recognition of foreign same-sex marriages or partnerships. No family reunification for same-sex partners. LGBTQ+ immigrants should be aware of restrictive legal environment. Vilnius has the only meaningful LGBTQ+ community.',
      refugeeSpecificNotes: 'Not recommended as primary destination for LGBTQ+ asylum seekers. Very limited SOGI expertise. LGL provides some support. Consider other EU countries with better LGBTQ+ asylum infrastructure. If in Lithuania, legal aid through Lithuanian Red Cross.',
    ),

    // -------------------------------------------------------
    // LUXEMBOURG (LU)
    // -------------------------------------------------------
    'LU': LgbtqCountryRights(
      country: 'Luxembourg',
      countryCode: 'LU',
      marriageStatus: MarriageStatus.marriageEquality,
      marriageDetails: 'Same-sex marriage legal since January 1, 2015. First sitting EU prime minister (Xavier Bettel) married same-sex partner. Registered partnerships (partenariat) available since 2004.',
      marriageLegalSince: 2015,
      adoptionRights: AdoptionRights.jointAdoption,
      adoptionDetails: 'Joint adoption since 2015 with marriage equality. Stepchild adoption available. Full equal parental rights.',
      ivfAccessForLesbians: true,
      surrogacyLegal: false,
      employmentProtection: true,
      housingProtection: true,
      goodsAndServicesProtection: true,
      constitutionalProtection: false,
      antiDiscriminationLegalBasis: 'Law of November 28, 2006 on Equal Treatment covers sexual orientation and gender identity in employment, housing, goods, services. Centre for Equal Treatment (CET) handles complaints.',
      genderRecognitionModel: GenderRecognitionModel.selfDetermination,
      genderRecognitionProcess: 'Self-determination since 2018 (Law of July 10, 2018). Application to civil registry (état civil). Statutory declaration. No medical requirements. Available from age 16.',
      genderRecognitionMinAge: 16,
      nonBinaryRecognized: false,
      asylumSogiProcedure: 'Apply at Direction de l\'immigration. SOGI claims recognized. Interview with protection officer. Appeal to Administrative Tribunal. Lëtzebuerger Flüchtlingsrot (LFR) provides support.',
      asylumSogiLegalBasis: 'Law of December 18, 2015 on International Protection transposing EU Qualification Directive. SOGI recognized.',
      asylumSogiSpecificRights: 'Right to confidential interview. Free legal aid. Accommodation through OLAI (Office luxembourgeois de l\'accueil et de l\'intégration). Small country with good coordination.',
      asylumSogiOrgSupport: 'Fondation Lëtzebuerger Flüchtlingsrot, Rosa Lëtzebuerg, CIGALE, CLAE.',
      hateCrimeLawSogi: true,
      hateSpeechLawSogi: true,
      hateCrimeReportingProcess: 'Report to Police Grand-Ducale. Criminal Code covers hate crimes and hate speech on SOGI grounds. Report also to CET.',
      bloodDonationPolicy: 'Individual risk assessment since 2023. No MSM-specific deferral.',
      transHealthcareAccess: 'Limited local capacity due to small country size. Some endocrinological care at Centre Hospitalier de Luxembourg. Surgery referrals to Belgium, France, or Germany. Covered by CNS (health insurance) with referral.',
      transHealthcareStateFunded: true,
      prepAvailable: true,
      militaryService: 'Open service. No restrictions. Luxembourg army is voluntary.',
      conversionTherapyBan: ConversionTherapyBan.fullBan,
      conversionTherapyDetails: 'Banned since 2023. Criminal penalties apply.',
      safetyRating: SafetyRating.verySafe,
      safetyNotes: 'Very safe and progressive. Small, multicultural country with strong LGBTQ+ rights. Luxembourg Pride well-attended. High public acceptance. Government actively supports LGBTQ+ equality.',
      ilgaEuropeRanking: 72.0,
      organizations: [
        LgbtqOrganization(
          name: 'Rosa Lëtzebuerg',
          type: 'community, advocacy',
          phone: '+352 26 19 00 18',
          email: 'info@rosa.lu',
          website: 'https://rosa.lu',
          languages: 'Luxembourgish, French, German, English',
          notes: 'Main LGBTQ+ organization. Advocacy, community, Pride organizer.',
        ),
        LgbtqOrganization(
          name: 'CIGALE (Centre d\'Information GAy et LEsbien)',
          type: 'community, referral',
          phone: '+352 26 19 00 18',
          email: 'cigale@cigale.lu',
          website: 'https://www.cigale.lu',
          languages: 'French, German, English',
          notes: 'LGBTQ+ information center. Referrals, social events.',
        ),
        LgbtqOrganization(
          name: 'Lëtzebuerger Flüchtlingsrot',
          type: 'asylum support, legal aid',
          phone: '+352 49 10 60',
          email: 'info@lfr.lu',
          website: 'https://www.lfr.lu',
          languages: 'French, German, English, Portuguese',
          notes: 'Refugee council. Legal aid and support for asylum seekers.',
        ),
      ],
      immigrantSpecificNotes: 'Foreign same-sex marriages fully recognized. Family reunification for same-sex spouses. Multicultural country with large immigrant population (47%+ foreign-born). Registration straightforward at commune.',
      refugeeSpecificNotes: 'Small number of asylum seekers. SOGI claims well-handled in an intimate system. Rosa Lëtzebuerg and LFR provide support. Good coordination between organizations due to small country size.',
    ),

    // -------------------------------------------------------
    // MALTA (MT)
    // -------------------------------------------------------
    'MT': LgbtqCountryRights(
      country: 'Malta',
      countryCode: 'MT',
      marriageStatus: MarriageStatus.marriageEquality,
      marriageDetails: 'Same-sex marriage legal since September 1, 2017 (Marriage Act amendment). Civil unions available since 2014. Malta has consistently ranked #1 on ILGA-Europe Rainbow Index.',
      marriageLegalSince: 2017,
      adoptionRights: AdoptionRights.jointAdoption,
      adoptionDetails: 'Joint adoption since 2014 (Civil Unions Act). Full equal parental rights. Foster care also available to same-sex couples.',
      ivfAccessForLesbians: true,
      surrogacyLegal: false,
      employmentProtection: true,
      housingProtection: true,
      goodsAndServicesProtection: true,
      constitutionalProtection: true,
      antiDiscriminationLegalBasis: 'Constitution Article 45 (amended 2014) explicitly prohibits discrimination on sexual orientation and gender identity. Equality for Men and Women Act. Employment and Industrial Relations Act. National Commission for the Promotion of Equality (NCPE).',
      genderRecognitionModel: GenderRecognitionModel.selfDetermination,
      genderRecognitionProcess: 'Self-determination since 2015 (Gender Identity, Gender Expression and Sex Characteristics Act - GIGESC Act). Application to Director of Public Registry. Notarial declaration, no medical requirements. World-leading legislation protecting sex characteristics (including intersex protections). Available from age 16 (under 16 with parental authority and court).',
      genderRecognitionMinAge: 16,
      nonBinaryRecognized: true,
      asylumSogiProcedure: 'Apply to Office of the Refugee Commissioner. SOGI claims well-recognized. Interview with protection officer. Malta has specific SOGI asylum guidelines. Appeal to Refugee Appeals Board.',
      asylumSogiLegalBasis: 'Refugees Act (Chapter 420) transposing EU Qualification Directive. SOGI explicitly recognized. Malta\'s LGBTQ+ legal framework supports strong protection.',
      asylumSogiSpecificRights: 'SOGI-trained interviewers. Confidentiality guaranteed. Accommodation with safety considerations. Free legal aid. Small system allows personalized attention.',
      asylumSogiOrgSupport: 'MGRM (Malta LGBTIQ Rights Movement), aditus foundation, JRS Malta (Jesuit Refugee Service).',
      hateCrimeLawSogi: true,
      hateSpeechLawSogi: true,
      hateCrimeReportingProcess: 'Report to Malta Police Force. Criminal Code Articles 82A-82D cover hate crimes with SOGI aggravating circumstance. Hate speech provisions explicitly include sexual orientation, gender identity, gender expression, and sex characteristics.',
      bloodDonationPolicy: 'Individual risk assessment. No MSM-specific deferral since 2021.',
      transHealthcareAccess: 'Available through public health system (Mater Dei Hospital). Hormones and some surgeries. Due to small country size, complex surgeries may require referral abroad (UK, Belgium). Covered by national health service.',
      transHealthcareStateFunded: true,
      prepAvailable: true,
      militaryService: 'Open service. No restrictions. Armed Forces of Malta have equality policies.',
      conversionTherapyBan: ConversionTherapyBan.fullBan,
      conversionTherapyDetails: 'Banned since 2016 - first European country to ban conversion therapy. Affirmation of Sexual Orientation, Gender Identity and Gender Expression Act. Criminal penalties including fines of EUR 1,000-5,000 or imprisonment.',
      safetyRating: SafetyRating.verySafe,
      safetyNotes: 'Top-ranked EU country for LGBTQ+ rights consistently. Remarkable transformation from strongly Catholic conservative to progressive leader. Valletta Pride well-attended. Very high public acceptance. Government actively champions LGBTQ+ rights internationally.',
      ilgaEuropeRanking: 89.0,
      organizations: [
        LgbtqOrganization(
          name: 'MGRM (Malta LGBTIQ Rights Movement)',
          type: 'community, advocacy, legal aid',
          phone: '+356 2143 6898',
          email: 'info@maltagayrights.org',
          website: 'https://www.maltagayrights.org',
          languages: 'Maltese, English',
          notes: 'Main LGBTQ+ organization. Advocacy, community, legal support, Pride organizer.',
        ),
        LgbtqOrganization(
          name: 'aditus foundation',
          type: 'asylum support, legal aid',
          phone: '+356 2010 6295',
          email: 'info@aditus.org.mt',
          website: 'https://aditus.org.mt',
          languages: 'Maltese, English, Arabic',
          notes: 'Human rights organization. Legal aid for asylum seekers including SOGI claims.',
        ),
        LgbtqOrganization(
          name: 'JRS Malta (Jesuit Refugee Service)',
          type: 'asylum support',
          phone: '+356 2144 2751',
          email: 'info@jrsmalta.org',
          website: 'https://jrsmalta.org',
          languages: 'Maltese, English, Arabic, Somali',
          notes: 'Refugee support. Housing, integration, legal referrals.',
        ),
      ],
      immigrantSpecificNotes: 'Foreign same-sex marriages fully recognized. Family reunification for spouses. Malta has world-leading LGBTQ+ legislation. Registration at Identity Malta straightforward. Small, welcoming community.',
      refugeeSpecificNotes: 'Malta processes asylum claims from Mediterranean arrivals. Strong LGBTQ+ legal framework benefits SOGI claimants. aditus foundation is key legal support. Small system means personalized attention. Accommodation may be crowded due to island geography.',
    ),

    // -------------------------------------------------------
    // NETHERLANDS (NL)
    // -------------------------------------------------------
    'NL': LgbtqCountryRights(
      country: 'Netherlands',
      countryCode: 'NL',
      marriageStatus: MarriageStatus.marriageEquality,
      marriageDetails: 'Same-sex marriage legal since April 1, 2001 - FIRST COUNTRY IN THE WORLD. Opening of Marriage Act (Wet openstelling huwelijk). Registered partnerships available since 1998.',
      marriageLegalSince: 2001,
      adoptionRights: AdoptionRights.jointAdoption,
      adoptionDetails: 'Joint adoption since 2001. Automatic co-parentage for married female couples. Full equal parental rights. International adoption may be limited by sending country.',
      ivfAccessForLesbians: true,
      surrogacyLegal: false, // Altruistic allowed, commercial banned
      employmentProtection: true,
      housingProtection: true,
      goodsAndServicesProtection: true,
      constitutionalProtection: true,
      antiDiscriminationLegalBasis: 'General Equal Treatment Act (Algemene wet gelijke behandeling, AWGB, 1994) covers sexual orientation. Article 1 of Dutch Constitution guarantees equality. Netherlands Institute for Human Rights (College voor de Rechten van de Mens) handles complaints.',
      genderRecognitionModel: GenderRecognitionModel.selfDetermination,
      genderRecognitionProcess: 'Self-determination since 2014 (amendment to Civil Code Book 1). Application at gemeente (municipality). Expert statement from designated psychologist or physician (simple confirmation, not diagnosis). Proposed reform to remove expert statement requirement. Available from age 16.',
      genderRecognitionMinAge: 16,
      nonBinaryRecognized: true,
      asylumSogiProcedure: 'Apply at Aanmeldcentrum (application center) in Ter Apel or Schiphol. IND (Immigratie- en Naturalisatiedienst) processes claims. IND has specific SOGI assessment framework (since 2018 reform following CJEU rulings). Personal interview with trained officer.',
      asylumSogiLegalBasis: 'Aliens Act (Vreemdelingenwet 2000) and Aliens Decree (Vreemdelingenbesluit). IND Work Instruction 2019/17 on SOGI claims. Strong SOGI case law from Council of State (Raad van State).',
      asylumSogiSpecificRights: 'SOGI-specialized IND decision-makers. Right to same-sex interviewer. Confidentiality. Free legal aid (funded by Legal Aid Board - Raad voor Rechtsbijstand). COA accommodation with LGBTQ+ safety measures. Appeal to district court then Council of State.',
      asylumSogiOrgSupport: 'COC Nederland, LGBT Asylum Support, VluchtelingenWerk Nederland, Secret Garden (LGBTQ+ asylum seekers).',
      hateCrimeLawSogi: true,
      hateSpeechLawSogi: true,
      hateCrimeReportingProcess: 'Report to police (112 emergency, 0900-8844 non-emergency). Criminal Code Articles 137c-137e cover discrimination and incitement. Pink in Blue (Roze in Blauw) - LGBTQ+ police liaison in major cities.',
      bloodDonationPolicy: 'Individual risk assessment since 2021. No MSM-specific deferral. Sanquin blood bank assesses all donors equally.',
      transHealthcareAccess: 'Available through VUmc Amsterdam (main gender clinic), UMCG Groningen, and expanding to regional centers. Hormones and surgery covered by basic health insurance (basisverzekering). Wait times significant (1-3 years for first appointment at VUmc). Efforts to expand capacity.',
      transHealthcareStateFunded: true,
      prepAvailable: true,
      militaryService: 'Open service since 1974. No restrictions. Dutch military actively promotes diversity and inclusion.',
      conversionTherapyBan: ConversionTherapyBan.fullBan,
      conversionTherapyDetails: 'Banned since 2024. Criminal penalties. Previous professional codes already prohibited it.',
      safetyRating: SafetyRating.verySafe,
      safetyNotes: 'Pioneer of LGBTQ+ rights globally. Amsterdam is iconic LGBTQ+ destination. Canal Pride among world\'s largest Pride events. Very high public acceptance. Some concerns about street harassment, particularly in large city centers. Pink in Blue police program provides specialized reporting.',
      ilgaEuropeRanking: 68.0,
      organizations: [
        LgbtqOrganization(
          name: 'COC Nederland',
          type: 'community, advocacy, asylum support',
          phone: '+31 20 623 45 96',
          email: 'info@coc.nl',
          website: 'https://www.coc.nl',
          address: 'Nieuwezijds Voorburgwal 68-70, 1012 SE Amsterdam',
          languages: 'Dutch, English',
          notes: 'Oldest existing LGBTQ+ organization in the world (founded 1946). National network with 20+ local chapters.',
        ),
        LgbtqOrganization(
          name: 'LGBT Asylum Support',
          type: 'asylum support, community',
          phone: '+31 6 2145 8792',
          email: 'info@lgbtasylumsupport.nl',
          website: 'https://lgbtasylumsupport.nl',
          languages: 'Dutch, English, Arabic, Farsi',
          notes: 'Specialized support for LGBTQ+ asylum seekers. Legal aid navigation, housing, community.',
        ),
        LgbtqOrganization(
          name: 'VluchtelingenWerk Nederland',
          type: 'asylum support, legal aid',
          phone: '+31 20 346 25 00',
          email: 'info@vluchtelingenwerk.nl',
          website: 'https://www.vluchtelingenwerk.nl',
          languages: 'Dutch, English, Arabic, Tigrinya, Farsi',
          notes: 'Dutch Council for Refugees. Legal aid and support. SOGI-trained staff.',
        ),
        LgbtqOrganization(
          name: 'Transgender Netwerk Nederland (TNN)',
          type: 'trans support, advocacy',
          phone: '+31 20 570 75 70',
          email: 'info@transgendernetwerk.nl',
          website: 'https://www.transgendernetwerk.nl',
          languages: 'Dutch, English',
          notes: 'Trans advocacy and support. Healthcare navigation, legal rights, peer groups.',
        ),
        LgbtqOrganization(
          name: 'Secret Garden',
          type: 'asylum support, community',
          phone: '',
          email: 'info@secretgarden.nl',
          website: 'https://www.secretgarden.nl',
          languages: 'Dutch, English, Arabic, Farsi',
          notes: 'Social and support network for LGBTQ+ asylum seekers and refugees.',
        ),
      ],
      immigrantSpecificNotes: 'Foreign same-sex marriages fully recognized. Family reunification for same-sex spouses. Registration at gemeente straightforward for EU citizens. Netherlands has the longest history of LGBTQ+ rights in the world.',
      refugeeSpecificNotes: 'Netherlands has extensive SOGI asylum experience and infrastructure. IND has specialized SOGI framework since 2018. COA accommodation centers have LGBTQ+ protocols. COC Nederland, LGBT Asylum Support, and VluchtelingenWerk provide comprehensive support. Amsterdam, The Hague, Rotterdam have most resources. Note: wait times for asylum processing can be long.',
    ),

    // -------------------------------------------------------
    // POLAND (PL)
    // -------------------------------------------------------
    'PL': LgbtqCountryRights(
      country: 'Poland',
      countryCode: 'PL',
      marriageStatus: MarriageStatus.none,
      marriageDetails: 'No legal recognition. Constitution (Article 18) protects marriage as union of man and woman. No registered partnership or cohabitation law. "LGBT-free zone" declarations by some municipalities (largely symbolic but hostile) - most rescinded under EU pressure by 2023.',
      marriageLegalSince: 0,
      adoptionRights: AdoptionRights.none,
      adoptionDetails: 'No adoption rights for same-sex couples. Individual adoption theoretically possible but practically very difficult for openly LGBTQ+ persons.',
      ivfAccessForLesbians: false,
      surrogacyLegal: false,
      employmentProtection: true,
      housingProtection: false,
      goodsAndServicesProtection: false,
      constitutionalProtection: false,
      antiDiscriminationLegalBasis: 'Labour Code Article 113 prohibits employment discrimination on sexual orientation. Act on Equal Treatment (2010) covers limited grounds. No comprehensive SOGI anti-discrimination law covering housing or services. Commissioner for Human Rights (RPO) may handle complaints.',
      genderRecognitionModel: GenderRecognitionModel.medicalRequired,
      genderRecognitionProcess: 'No specific legislation. Based on Supreme Court precedent (1989). Requires filing civil lawsuit against one\'s own parents to change registered sex. Medical documentation (psychiatric diagnosis) required. Process can take 1-3 years. No surgery requirement per case law but inconsistent practice.',
      genderRecognitionMinAge: 18,
      nonBinaryRecognized: false,
      asylumSogiProcedure: 'Apply at Office for Foreigners (Urząd do Spraw Cudzoziemców). SOGI claims accepted in principle. Interview with protection officer. Appeal to Refugee Board (Rada do Spraw Uchodźców). Helsinki Foundation for Human Rights provides legal aid.',
      asylumSogiLegalBasis: 'Act on Granting Protection to Aliens (2003, amended) transposing EU Qualification Directive. SOGI as particular social group.',
      asylumSogiSpecificRights: 'Right to confidential interview. Free legal aid through Helsinki Foundation. Accommodation in reception centers. Limited SOGI expertise among officers. Lambda Warszawa may provide community support.',
      asylumSogiOrgSupport: 'Lambda Warszawa, Campaign Against Homophobia (KPH), Helsinki Foundation for Human Rights.',
      hateCrimeLawSogi: false,
      hateSpeechLawSogi: false,
      hateCrimeReportingProcess: 'Report to police (Policja). No SOGI-specific hate crime legislation. General criminal provisions may apply. KPH documents incidents through monitoring projects.',
      bloodDonationPolicy: 'Permanent deferral for MSM.',
      transHealthcareAccess: 'Available through some sexology clinics and endocrinologists (mainly in Warsaw, Kraków, Łódź). Hormones available with psychiatric diagnosis. Surgery at some hospitals. Covered partially by NFZ (national health fund) but long wait times and bureaucratic barriers.',
      transHealthcareStateFunded: true,
      prepAvailable: false,
      militaryService: 'Open service. No formal restrictions.',
      conversionTherapyBan: ConversionTherapyBan.noBan,
      conversionTherapyDetails: 'No ban. Some Catholic organizations offer "healing" programs. Polish Sexological Society opposes conversion therapy but no legal prohibition.',
      safetyRating: SafetyRating.caution,
      safetyNotes: 'Challenging environment, especially outside Warsaw. "LGBT-free zones" (largely rescinded) created hostile climate. Warsaw and Kraków relatively more tolerant. Equality March (Pride) in Warsaw occurs annually but faces counter-protests. Government rhetoric has been hostile. Violence and harassment reported.',
      ilgaEuropeRanking: 16.0,
      organizations: [
        LgbtqOrganization(
          name: 'Campaign Against Homophobia (KPH)',
          type: 'advocacy, legal aid, community',
          phone: '+48 22 423 64 38',
          email: 'info@kph.org.pl',
          website: 'https://kph.org.pl',
          address: 'Warsaw, Poland',
          languages: 'Polish, English',
          notes: 'Major LGBTQ+ organization. Legal aid, hate crime monitoring, advocacy, community.',
        ),
        LgbtqOrganization(
          name: 'Lambda Warszawa',
          type: 'community, counseling',
          phone: '+48 22 628 52 22',
          email: 'info@lambdawarszawa.org',
          website: 'https://lambdawarszawa.org',
          languages: 'Polish, English, Russian, Ukrainian',
          notes: 'Community center. Counseling, support groups, social events. Helpline.',
        ),
        LgbtqOrganization(
          name: 'Helsinki Foundation for Human Rights',
          type: 'legal aid, asylum support',
          phone: '+48 22 556 44 40',
          email: 'hfhr@hfhr.pl',
          website: 'https://www.hfhr.pl',
          languages: 'Polish, English',
          notes: 'Human rights legal aid including for asylum seekers and LGBTQ+ discrimination cases.',
        ),
        LgbtqOrganization(
          name: 'Trans-Fuzja Foundation',
          type: 'trans support',
          phone: '',
          email: 'kontakt@transfuzja.org',
          website: 'https://www.transfuzja.org',
          languages: 'Polish, English',
          notes: 'Trans support, legal gender recognition assistance, healthcare navigation.',
        ),
      ],
      immigrantSpecificNotes: 'No recognition of foreign same-sex marriages or partnerships. Family reunification for same-sex partners not available. LGBTQ+ immigrants should exercise caution. Warsaw has the most resources and most tolerant atmosphere.',
      refugeeSpecificNotes: 'Poland receives significant numbers of asylum seekers (especially Ukrainian since 2022). SOGI claims processed but system has limited SOGI expertise. Helsinki Foundation is critical for legal support. Lambda Warszawa provides community support. Warsaw is the best location for LGBTQ+ asylum seekers. Consider whether Poland is the best destination within the EU for SOGI claims.',
    ),

    // -------------------------------------------------------
    // PORTUGAL (PT)
    // -------------------------------------------------------
    'PT': LgbtqCountryRights(
      country: 'Portugal',
      countryCode: 'PT',
      marriageStatus: MarriageStatus.marriageEquality,
      marriageDetails: 'Same-sex marriage legal since June 5, 2010 (Law 9/2010). De facto unions (uniões de facto) recognized since 2001. First Iberian country.',
      marriageLegalSince: 2010,
      adoptionRights: AdoptionRights.jointAdoption,
      adoptionDetails: 'Joint adoption since 2016 (Law 2/2016). Stepchild adoption since 2016. Full equal parental rights. Medically assisted reproduction for all women since 2016.',
      ivfAccessForLesbians: true,
      surrogacyLegal: true, // Altruistic surrogacy legalized 2016, suspended by Constitutional Court, partially restored
      employmentProtection: true,
      housingProtection: true,
      goodsAndServicesProtection: true,
      constitutionalProtection: true,
      antiDiscriminationLegalBasis: 'Constitution Article 13(2) explicitly prohibits discrimination on sexual orientation (since 2004 revision). Labour Code, Law 134/99 (anti-discrimination). Commission for Citizenship and Gender Equality (CIG) and Commission for Equality in Labour and Employment (CITE).',
      genderRecognitionModel: GenderRecognitionModel.selfDetermination,
      genderRecognitionProcess: 'Self-determination since 2018 (Law 38/2018). Application to Civil Registry (Conservatória do Registo Civil). No medical requirements. Simple declaration. Available from age 16 (parental consent). Non-binary option under discussion.',
      genderRecognitionMinAge: 16,
      nonBinaryRecognized: false,
      asylumSogiProcedure: 'Apply at SEF (Serviço de Estrangeiros e Fronteiras, now reorganized as AIMA - Agência para a Integração, Migrações e Asilo). SOGI claims well-recognized. Personal interview. Portuguese Council for Refugees (CPR) provides legal aid.',
      asylumSogiLegalBasis: 'Law 27/2008 (Asylum Act) transposing EU Qualification Directive. SOGI explicitly recognized. Portugal has positive SOGI asylum case law.',
      asylumSogiSpecificRights: 'SOGI-sensitive interviews. Free legal aid through CPR. Accommodation through AIMA reception system. Portugal generally welcoming.',
      asylumSogiOrgSupport: 'ILGA Portugal, Portuguese Council for Refugees (CPR), Rede ex aequo, JRS Portugal.',
      hateCrimeLawSogi: true,
      hateSpeechLawSogi: true,
      hateCrimeReportingProcess: 'Report to PSP (Polícia de Segurança Pública) or GNR (Guarda Nacional Republicana). Criminal Code Article 240 covers discrimination and incitement. SOGI covered as aggravating circumstance. Report to CIG for additional documentation.',
      bloodDonationPolicy: 'Individual risk assessment since 2022. No MSM-specific deferral.',
      transHealthcareAccess: 'Available through public SNS (Serviço Nacional de Saúde). Specialized services in Lisbon (Hospital de Santa Maria), Porto. Hormones and surgery covered by SNS. Wait times variable.',
      transHealthcareStateFunded: true,
      prepAvailable: true,
      militaryService: 'Open service. No restrictions.',
      conversionTherapyBan: ConversionTherapyBan.fullBan,
      conversionTherapyDetails: 'Banned since 2018 as part of Law 38/2018 (Gender Identity Law). Protects against practices aimed at changing sexual orientation or gender identity.',
      safetyRating: SafetyRating.verySafe,
      safetyNotes: 'Very safe and welcoming. Lisbon has vibrant LGBTQ+ scene (Príncipe Real neighborhood). Pride in Lisbon and Porto well-attended. Very high public acceptance. Portugal has transformed dramatically since decriminalization of homosexuality (1982). One of Europe\'s most LGBTQ+ friendly countries.',
      ilgaEuropeRanking: 73.0,
      organizations: [
        LgbtqOrganization(
          name: 'ILGA Portugal',
          type: 'community, advocacy, legal aid',
          phone: '+351 21 887 3918',
          email: 'ilga@ilga-portugal.pt',
          website: 'https://ilga-portugal.pt',
          address: 'Rua de São Lázaro, 88, 1150-333 Lisboa',
          languages: 'Portuguese, English',
          notes: 'Main LGBTQ+ organization. Legal aid, community center, advocacy, health services.',
        ),
        LgbtqOrganization(
          name: 'Portuguese Council for Refugees (CPR)',
          type: 'asylum support, legal aid',
          phone: '+351 21 831 4372',
          email: 'cpr@cpr.pt',
          website: 'https://cpr.pt',
          languages: 'Portuguese, English, French, Arabic',
          notes: 'Legal aid and support for asylum seekers including SOGI claims.',
        ),
        LgbtqOrganization(
          name: 'Rede ex aequo',
          type: 'youth, community',
          phone: '',
          email: 'geral@rea.pt',
          website: 'https://www.rea.pt',
          languages: 'Portuguese, English',
          notes: 'LGBTQ+ youth network. Support groups, education, community.',
        ),
        LgbtqOrganization(
          name: 'Associação ILGA Portugal - Centro Comunitário',
          type: 'community, health',
          phone: '+351 21 887 3918',
          email: 'centro@ilga-portugal.pt',
          website: 'https://ilga-portugal.pt',
          languages: 'Portuguese, English',
          notes: 'Community center with health services, HIV/STI testing, counseling.',
        ),
      ],
      immigrantSpecificNotes: 'Foreign same-sex marriages fully recognized. De facto unions available to foreign nationals. Family reunification for same-sex spouses. Portugal actively attracts immigrants with favorable policies. Lisbon and Porto are main LGBTQ+ hubs.',
      refugeeSpecificNotes: 'Portugal is welcoming for LGBTQ+ asylum seekers. CPR provides excellent legal support. ILGA Portugal offers community integration. System experienced though small. Accommodation through AIMA. Lisbon has the most resources.',
    ),

    // -------------------------------------------------------
    // ROMANIA (RO)
    // -------------------------------------------------------
    'RO': LgbtqCountryRights(
      country: 'Romania',
      countryCode: 'RO',
      marriageStatus: MarriageStatus.none,
      marriageDetails: 'No legal recognition. Constitution defines marriage as between spouses (gender-neutral after 2018 referendum failed to reach quorum). Civil Code Article 277 explicitly prohibits same-sex marriage. However, CJEU ruling Coman v Romania (2018) requires recognition of same-sex marriages performed abroad for residence purposes.',
      marriageLegalSince: 0,
      adoptionRights: AdoptionRights.none,
      adoptionDetails: 'No adoption rights for same-sex couples. Individual adoption possible but hostile environment for openly LGBTQ+ applicants.',
      ivfAccessForLesbians: false,
      surrogacyLegal: false,
      employmentProtection: true,
      housingProtection: false,
      goodsAndServicesProtection: false,
      constitutionalProtection: false,
      antiDiscriminationLegalBasis: 'Government Ordinance 137/2000 on preventing and sanctioning all forms of discrimination covers sexual orientation in employment. National Council for Combating Discrimination (CNCD) handles complaints. Limited scope beyond employment.',
      genderRecognitionModel: GenderRecognitionModel.medicalRequired,
      genderRecognitionProcess: 'No specific legislation. Based on court orders. Requires medical documentation and sometimes surgery. Process through civil court petition. Inconsistent across regions. Can take 1-3 years.',
      genderRecognitionMinAge: 18,
      nonBinaryRecognized: false,
      asylumSogiProcedure: 'Apply at General Inspectorate for Immigration (IGI). SOGI claims accepted. Interview with protection officer. UNHCR Romania and JRS Romania provide support. Appeal to court.',
      asylumSogiLegalBasis: 'Asylum Law (Law 122/2006) transposing EU Qualification Directive. SOGI recognized under particular social group.',
      asylumSogiSpecificRights: 'Right to confidential interview. Free legal aid. Accommodation in reception centers (Bucharest, Timișoara, Galați, etc.). Limited SOGI-specific protocols.',
      asylumSogiOrgSupport: 'Accept Romania (LGBTQ+ organization), JRS Romania, UNHCR Romania, ARCA Romanian Forum for Refugees.',
      hateCrimeLawSogi: false,
      hateSpeechLawSogi: false,
      hateCrimeReportingProcess: 'Report to police. No SOGI-specific hate crime legislation. Ordinance 137/2000 covers some discrimination. Accept Romania documents incidents.',
      bloodDonationPolicy: 'Permanent deferral for MSM.',
      transHealthcareAccess: 'Very limited. Some endocrinological care available in Bucharest. No structured gender-affirming care. Surgery not available domestically in most cases. Not covered by state insurance. Most trans persons seek care abroad.',
      transHealthcareStateFunded: false,
      prepAvailable: false,
      militaryService: 'Open service. No formal restrictions.',
      conversionTherapyBan: ConversionTherapyBan.noBan,
      conversionTherapyDetails: 'No ban. Orthodox Church influence. Some religious conversion programs operate.',
      safetyRating: SafetyRating.caution,
      safetyNotes: 'Challenging but slowly improving. Bucharest Pride has grown significantly. Bucharest and Cluj-Napoca have small LGBTQ+ communities. Rural areas and smaller cities much less accepting. Orthodox Church is influential. Violence and discrimination reported.',
      ilgaEuropeRanking: 18.0,
      organizations: [
        LgbtqOrganization(
          name: 'Accept Romania (Asociația Accept)',
          type: 'community, advocacy, legal aid',
          phone: '+40 21 252 5620',
          email: 'office@acceptromania.ro',
          website: 'https://www.acceptromania.ro',
          address: 'Bucharest, Romania',
          languages: 'Romanian, English',
          notes: 'Main LGBTQ+ organization. Advocacy, legal aid, community, Bucharest Pride organizer.',
        ),
        LgbtqOrganization(
          name: 'ARCA Romanian Forum for Refugees',
          type: 'asylum support, legal aid',
          phone: '+40 21 212 0414',
          email: 'arca@arca.org.ro',
          website: 'https://www.arca.org.ro',
          languages: 'Romanian, English, French, Arabic',
          notes: 'Refugee support and legal aid including for SOGI asylum claims.',
        ),
        LgbtqOrganization(
          name: 'MozaiQ',
          type: 'community',
          phone: '',
          email: 'contact@mozaiqlgbt.ro',
          website: 'https://mozaiqlgbt.ro',
          languages: 'Romanian, English',
          notes: 'LGBTQ+ community organization. Events, support, visibility campaigns.',
        ),
      ],
      immigrantSpecificNotes: 'CJEU Coman ruling requires Romania to recognize foreign same-sex marriages for residence purposes. Implementation inconsistent. No family reunification for same-sex partners under domestic law. Bucharest is the only city with meaningful LGBTQ+ community.',
      refugeeSpecificNotes: 'Romania processes asylum claims but SOGI expertise limited. Accept Romania provides essential community support. ARCA handles legal aid. Consider whether Romania is the best destination for LGBTQ+ asylum seekers in the EU. Bucharest has the most resources.',
    ),

    // -------------------------------------------------------
    // SLOVAKIA (SK)
    // -------------------------------------------------------
    'SK': LgbtqCountryRights(
      country: 'Slovakia',
      countryCode: 'SK',
      marriageStatus: MarriageStatus.none,
      marriageDetails: 'No legal recognition. Constitution (Article 41, amended 2014) defines marriage as unique bond between man and woman. No registered partnership or cohabitation law.',
      marriageLegalSince: 0,
      adoptionRights: AdoptionRights.none,
      adoptionDetails: 'No adoption rights for same-sex couples. Individual adoption possible but hostile environment.',
      ivfAccessForLesbians: false,
      surrogacyLegal: false,
      employmentProtection: true,
      housingProtection: true,
      goodsAndServicesProtection: true,
      constitutionalProtection: false,
      antiDiscriminationLegalBasis: 'Anti-Discrimination Act (Act No. 365/2004 Z.z.) covers sexual orientation in employment, education, healthcare, housing, goods and services. Slovak National Centre for Human Rights handles complaints.',
      genderRecognitionModel: GenderRecognitionModel.surgeryRequired,
      genderRecognitionProcess: 'Requires "complete sex reassignment" including sterilization under expert guidelines. Medical board assessment. Application through healthcare system then civil registry. No specific legislation - based on health ministry guidelines and expert commission opinions.',
      genderRecognitionMinAge: 18,
      nonBinaryRecognized: false,
      asylumSogiProcedure: 'Apply at Migration Office of the Ministry of Interior. SOGI claims accepted. Interview with protection officer. Slovak Humanitarian Council and UNHCR provide support. Appeal to court.',
      asylumSogiLegalBasis: 'Asylum Act (Act No. 480/2002 Z.z.) transposing EU Qualification Directive. SOGI as particular social group.',
      asylumSogiSpecificRights: 'Right to confidential interview. Free legal aid. Accommodation in reception centers. Very limited SOGI expertise in the system.',
      asylumSogiOrgSupport: 'Inakosť (LGBTQ+ organization), Human Rights League (Liga za ľudské práva), Slovak Humanitarian Council.',
      hateCrimeLawSogi: false,
      hateSpeechLawSogi: false,
      hateCrimeReportingProcess: 'Report to police. No SOGI-specific hate crime legislation. General criminal provisions may apply. Inakosť documents incidents.',
      bloodDonationPolicy: 'Permanent deferral for MSM.',
      transHealthcareAccess: 'Limited. Some psychiatric and endocrinological care in Bratislava. Sterilization still required for legal recognition. Most trans persons seek care abroad (Czech Republic, Austria).',
      transHealthcareStateFunded: true,
      prepAvailable: false,
      militaryService: 'Open service. No formal restrictions.',
      conversionTherapyBan: ConversionTherapyBan.noBan,
      conversionTherapyDetails: 'No ban. Catholic Church influence significant. Some conversion programs operate through religious organizations.',
      safetyRating: SafetyRating.caution,
      safetyNotes: 'Challenging. Bratislava has small LGBTQ+ community and hosts Pride. Political environment hostile (referendum attempts to restrict LGBTQ+ rights). Rural areas very conservative. Catholic Church influence significant. Violence incidents documented.',
      ilgaEuropeRanking: 24.0,
      organizations: [
        LgbtqOrganization(
          name: 'Inakosť',
          type: 'community, advocacy',
          phone: '+421 948 128 128',
          email: 'info@inakost.sk',
          website: 'https://inakost.sk',
          languages: 'Slovak, English',
          notes: 'Main LGBTQ+ organization. Advocacy, community, Pride organizer.',
        ),
        LgbtqOrganization(
          name: 'Human Rights League (Liga za ľudské práva)',
          type: 'legal aid, asylum support',
          phone: '+421 2 5441 0686',
          email: 'hrl@hrl.sk',
          website: 'https://www.hrl.sk',
          languages: 'Slovak, English',
          notes: 'Human rights legal aid including for asylum seekers.',
        ),
        LgbtqOrganization(
          name: 'TransFúzia',
          type: 'trans support',
          phone: '',
          email: 'info@transfuzia.sk',
          website: 'https://www.transfuzia.sk',
          languages: 'Slovak, English',
          notes: 'Trans rights and support organization.',
        ),
      ],
      immigrantSpecificNotes: 'No recognition of foreign same-sex marriages or partnerships. Family reunification for same-sex partners not available. Bratislava is the only city with LGBTQ+ community infrastructure. Consider neighboring Austria or Czech Republic.',
      refugeeSpecificNotes: 'Very low asylum numbers. Minimal SOGI expertise in the system. Human Rights League provides legal aid. Not recommended as primary destination for LGBTQ+ asylum seekers. If in Slovakia, Bratislava is the only viable location.',
    ),

    // -------------------------------------------------------
    // SLOVENIA (SI)
    // -------------------------------------------------------
    'SI': LgbtqCountryRights(
      country: 'Slovenia',
      countryCode: 'SI',
      marriageStatus: MarriageStatus.marriageEquality,
      marriageDetails: 'Same-sex marriage legal since July 8, 2022, following Constitutional Court ruling (U-I-486/20). First post-communist and first Slavic-language country with marriage equality. Previously, registered partnerships since 2006.',
      marriageLegalSince: 2022,
      adoptionRights: AdoptionRights.jointAdoption,
      adoptionDetails: 'Joint adoption legal since 2022 Constitutional Court ruling (same ruling as marriage). Full equal parental rights for married same-sex couples.',
      ivfAccessForLesbians: true,
      surrogacyLegal: false,
      employmentProtection: true,
      housingProtection: true,
      goodsAndServicesProtection: true,
      constitutionalProtection: false,
      antiDiscriminationLegalBasis: 'Protection Against Discrimination Act (2016) covers sexual orientation, gender identity, gender expression, and sex characteristics in all areas. Advocate of the Principle of Equality handles complaints.',
      genderRecognitionModel: GenderRecognitionModel.selfDetermination,
      genderRecognitionProcess: 'Self-determination since 2023 (amendment to Civil Registry Act). Application at administrative unit. Statutory declaration, no medical requirements. Simplified process.',
      genderRecognitionMinAge: 18,
      nonBinaryRecognized: false,
      asylumSogiProcedure: 'Apply at police or Office for Migrants (Ministry of Interior). SOGI claims recognized. Interview with trained officer. PIC (Legal-Informational Centre for NGOs) provides legal aid.',
      asylumSogiLegalBasis: 'International Protection Act (2017) transposing EU Qualification Directive. SOGI recognized.',
      asylumSogiSpecificRights: 'Right to confidential interview. Free legal aid through PIC. Accommodation at Ljubljana Asylum Home.',
      asylumSogiOrgSupport: 'Legebitra (LGBTQ+ organization), PIC, UNHCR Slovenia, Slovenian Philanthropy.',
      hateCrimeLawSogi: true,
      hateSpeechLawSogi: true,
      hateCrimeReportingProcess: 'Report to police. Criminal Code Article 297 covers incitement to hatred. SOGI covered as protected ground. Report also to Advocate of the Principle of Equality.',
      bloodDonationPolicy: 'Individual risk assessment. No permanent MSM deferral since 2023.',
      transHealthcareAccess: 'Available through University Medical Centre Ljubljana. Hormones and surgery covered by ZZZS (health insurance). Limited capacity - wait times significant.',
      transHealthcareStateFunded: true,
      prepAvailable: true,
      militaryService: 'Open service. No restrictions. Slovenian Armed Forces have equality policies.',
      conversionTherapyBan: ConversionTherapyBan.noBan,
      conversionTherapyDetails: 'No explicit ban. Professional associations discourage it.',
      safetyRating: SafetyRating.safe,
      safetyNotes: 'Safe and improving rapidly. Ljubljana has active LGBTQ+ scene. Ljubljana Pride well-attended. Constitutional Court has been driver of progress. Public opinion positive in urban areas. Some rural conservatism.',
      ilgaEuropeRanking: 63.0,
      organizations: [
        LgbtqOrganization(
          name: 'Legebitra',
          type: 'community, advocacy, legal aid',
          phone: '+386 1 430 51 44',
          email: 'info@legebitra.si',
          website: 'https://legebitra.si',
          address: 'Ljubljana, Slovenia',
          languages: 'Slovenian, English',
          notes: 'Main LGBTQ+ organization. Legal aid, community, advocacy, counseling.',
        ),
        LgbtqOrganization(
          name: 'PIC (Legal-Informational Centre for NGOs)',
          type: 'legal aid, asylum support',
          phone: '+386 1 521 18 88',
          email: 'pic@pic.si',
          website: 'https://pic.si',
          languages: 'Slovenian, English',
          notes: 'Legal aid for asylum seekers and vulnerable groups.',
        ),
        LgbtqOrganization(
          name: 'TransAkcija Institute',
          type: 'trans support',
          phone: '',
          email: 'info@transakcija.si',
          website: 'https://transakcija.si',
          languages: 'Slovenian, English',
          notes: 'Trans rights and support. Healthcare navigation, legal assistance.',
        ),
      ],
      immigrantSpecificNotes: 'Foreign same-sex marriages fully recognized. Family reunification for same-sex spouses. Registration at administrative unit. Ljubljana is the main LGBTQ+ hub.',
      refugeeSpecificNotes: 'Low asylum numbers but system functional. PIC provides legal aid. Legebitra offers community support. Ljubljana has the most resources. Recent marriage equality and anti-discrimination framework provide good protection.',
    ),

    // -------------------------------------------------------
    // SPAIN (ES)
    // -------------------------------------------------------
    'ES': LgbtqCountryRights(
      country: 'Spain',
      countryCode: 'ES',
      marriageStatus: MarriageStatus.marriageEquality,
      marriageDetails: 'Same-sex marriage legal since July 3, 2005 (Law 13/2005). Third country in the world. Constitutional Court upheld constitutionality in 2012. Long-standing LGBTQ+ acceptance culture.',
      marriageLegalSince: 2005,
      adoptionRights: AdoptionRights.jointAdoption,
      adoptionDetails: 'Joint adoption since 2005 with marriage equality. Full equal parental rights. Autonomous communities may have additional provisions. Automatic co-parentage for married female couples.',
      ivfAccessForLesbians: true,
      surrogacyLegal: false,
      employmentProtection: true,
      housingProtection: true,
      goodsAndServicesProtection: true,
      constitutionalProtection: false,
      antiDiscriminationLegalBasis: 'Law 4/2023 (Trans Law / Ley Trans) comprehensive LGBTI rights legislation. Constitution Article 14 (equality). Workers\' Statute. Multiple autonomous community laws. Various regional LGBTQ+ specific laws (Andalusia, Catalonia, Madrid, Valencia, etc.).',
      genderRecognitionModel: GenderRecognitionModel.selfDetermination,
      genderRecognitionProcess: 'Self-determination since 2023 (Law 4/2023, Ley Trans). Application at Civil Registry. No medical requirements. 3-month reflection period + confirmation. Available from age 16 without parental consent; 14-16 with parental consent; 12-14 with judicial authorization.',
      genderRecognitionMinAge: 12,
      nonBinaryRecognized: false,
      asylumSogiProcedure: 'Apply at OAR (Oficina de Asilo y Refugio) or police station. SOGI claims well-recognized. Spain has extensive SOGI asylum experience. Interview with trained officer. CEAR (Comisión Española de Ayuda al Refugiado) provides legal aid.',
      asylumSogiLegalBasis: 'Law 12/2009 on the right to asylum and subsidiary protection. SOGI explicitly recognized. Spain has generous SOGI asylum recognition rates.',
      asylumSogiSpecificRights: 'SOGI-trained interviewers. Free legal aid through CEAR and ACCEM. Accommodation through national reception system. SOGI-sensitive placement available. Spain offers humanitarian protection as alternative.',
      asylumSogiOrgSupport: 'FELGTBI+ (Federation), CEAR, ACCEM, Kifkif (LGBTQ+ migrants), COGAM (Madrid), Casal Lambda (Barcelona).',
      hateCrimeLawSogi: true,
      hateSpeechLawSogi: true,
      hateCrimeReportingProcess: 'Report to Policía Nacional, Guardia Civil, or Mossos d\'Esquadra (Catalonia), Ertzaintza (Basque). Criminal Code Articles 510-512 cover hate crimes and hate speech. SOGI explicitly covered. Fiscal de Delitos de Odio (Hate Crime Prosecutor) in each province.',
      bloodDonationPolicy: 'Individual risk assessment since 2022. No MSM-specific deferral.',
      transHealthcareAccess: 'Available through public healthcare (SNS) in autonomous community gender units. Main centers in Madrid, Barcelona, Málaga, Valencia, Bilbao. Hormones and surgery covered by public insurance. Wait times vary by autonomous community (6 months to 3 years). Trans Law (2023) improved access.',
      transHealthcareStateFunded: true,
      prepAvailable: true,
      militaryService: 'Open service. No restrictions. Spanish Armed Forces have non-discrimination policies.',
      conversionTherapyBan: ConversionTherapyBan.fullBan,
      conversionTherapyDetails: 'Banned nationally since 2023 (Law 4/2023). Previously banned in multiple autonomous communities (Madrid, Valencia, Andalusia, etc.). Criminal penalties.',
      safetyRating: SafetyRating.verySafe,
      safetyNotes: 'One of the safest and most LGBTQ+ friendly countries globally. Madrid (Chueca district), Barcelona (Eixample), and Sitges are iconic LGBTQ+ destinations. Massive Pride events. Very high public acceptance. Law 4/2023 is among the most progressive LGBTQ+ legislation in the world.',
      ilgaEuropeRanking: 74.0,
      organizations: [
        LgbtqOrganization(
          name: 'FELGTBI+ (Federación Estatal LGTBI+)',
          type: 'advocacy, community',
          phone: '+34 91 360 46 05',
          email: 'info@felgtbi.org',
          website: 'https://felgtbi.org',
          languages: 'Spanish, English',
          notes: 'National LGBTQ+ federation. Umbrella for 50+ member organizations. Advocacy, community.',
        ),
        LgbtqOrganization(
          name: 'Kifkif - LGBTQI+ Migration',
          type: 'asylum support, community',
          phone: '+34 91 523 94 60',
          email: 'info@kifkif.info',
          website: 'https://kifkif.info',
          address: 'Madrid, Spain',
          languages: 'Spanish, English, Arabic, French',
          notes: 'LGBTQ+ migrants and asylum seekers. Legal aid, community, housing support, integration.',
        ),
        LgbtqOrganization(
          name: 'CEAR (Comisión Española de Ayuda al Refugiado)',
          type: 'asylum support, legal aid',
          phone: '+34 91 598 05 35',
          email: 'cear@cear.es',
          website: 'https://www.cear.es',
          languages: 'Spanish, English, French, Arabic',
          notes: 'Spanish refugee agency. Legal aid, reception, integration. SOGI-trained staff.',
        ),
        LgbtqOrganization(
          name: 'COGAM (Colectivo LGTB+ de Madrid)',
          type: 'community, legal aid, health',
          phone: '+34 91 522 45 17',
          email: 'info@cogam.es',
          website: 'https://www.cogam.es',
          address: 'Calle de la Puebla 9, 28004 Madrid',
          languages: 'Spanish, English',
          notes: 'Madrid LGBTQ+ community center. Legal aid, health services, social groups.',
        ),
        LgbtqOrganization(
          name: 'Casal Lambda',
          type: 'community, legal aid',
          phone: '+34 93 319 55 50',
          email: 'info@lambda.cat',
          website: 'https://lambda.cat',
          address: 'Carrer del Comte Borrell 22, 08015 Barcelona',
          languages: 'Catalan, Spanish, English',
          notes: 'Barcelona LGBTQ+ community center. Legal aid, social activities, library.',
        ),
      ],
      immigrantSpecificNotes: 'Foreign same-sex marriages fully recognized. Family reunification for same-sex spouses. Spain has large immigrant communities with LGBTQ+ support. Empadronamiento (municipal registration) available to all regardless of status. Public healthcare (tarjeta sanitaria) accessible to registered residents.',
      refugeeSpecificNotes: 'Spain is one of the best EU countries for LGBTQ+ asylum seekers. High recognition rates for SOGI claims. Kifkif provides specialized LGBTQ+ migrant support in Madrid. CEAR and ACCEM operate nationwide. National reception system (sistema de acogida) can provide LGBTQ+ safe placement. Madrid and Barcelona have the most resources.',
    ),

    // -------------------------------------------------------
    // SWEDEN (SE)
    // -------------------------------------------------------
    'SE': LgbtqCountryRights(
      country: 'Sweden',
      countryCode: 'SE',
      marriageStatus: MarriageStatus.marriageEquality,
      marriageDetails: 'Same-sex marriage legal since May 1, 2009. Registered partnerships since 1995 (first country with nearly equal partnership law). Church of Sweden performs same-sex marriages. Gender-neutral marriage law.',
      marriageLegalSince: 2009,
      adoptionRights: AdoptionRights.jointAdoption,
      adoptionDetails: 'Joint adoption since 2003. Stepchild adoption since 2003. Full equal parental rights. Automatic co-parentage for married female couples. International adoption since 2003 (subject to sending country).',
      ivfAccessForLesbians: true,
      surrogacyLegal: false,
      employmentProtection: true,
      housingProtection: true,
      goodsAndServicesProtection: true,
      constitutionalProtection: true,
      antiDiscriminationLegalBasis: 'Discrimination Act (Diskrimineringslag, 2008:567) covers sexual orientation, transgender identity and expression in all areas of society. Instrument of Government (Regeringsformen) Chapter 1, Section 2. Equality Ombudsman (Diskrimineringsombudsmannen, DO) handles complaints.',
      genderRecognitionModel: GenderRecognitionModel.medicalRequired,
      genderRecognitionProcess: 'Application to National Board of Health and Welfare (Socialstyrelsen) Legal Council. Currently requires medical assessment (gender dysphoria diagnosis). No surgery or sterilization requirement (sterilization requirement removed in 2013 and compensation offered to those affected). New self-determination bill proposed but not yet enacted as of 2025.',
      genderRecognitionMinAge: 18,
      nonBinaryRecognized: false,
      asylumSogiProcedure: 'Apply at Migrationsverket (Swedish Migration Agency). SOGI claims well-established in Swedish practice. Trained officers conduct interviews. Swedish Red Cross and RFSL provide support. Appeal to Migration Court (Migrationsdomstolen) then Migration Court of Appeal.',
      asylumSogiLegalBasis: 'Aliens Act (Utlänningslag, 2005:716) Chapter 4. Sweden follows UNHCR SOGI guidelines. Extensive case law from Migration Court of Appeal.',
      asylumSogiSpecificRights: 'SOGI-trained officers at Migrationsverket. Right to same-sex interviewer. Free public counsel (offentligt biträde). Accommodation through Migrationsverket with LGBTQ+ safety considerations. RFSL Newcomers program.',
      asylumSogiOrgSupport: 'RFSL (Riksförbundet för homosexuellas, bisexuellas, transpersoners, queeras och intersexuellas rättigheter), RFSL Newcomers, Swedish Red Cross, Swedish Refugee Law Center.',
      hateCrimeLawSogi: true,
      hateSpeechLawSogi: true,
      hateCrimeReportingProcess: 'Report to police (Polisen, 114 14 non-emergency, 112 emergency). Criminal Code Chapter 29, Section 2(7) lists bias motive as aggravating. Chapter 16, Section 8 (Hets mot folkgrupp) covers hate speech including on sexual orientation. Police have hate crime coordinators.',
      bloodDonationPolicy: 'Individual risk assessment since 2021. No MSM-specific deferral. All donors assessed individually.',
      transHealthcareAccess: 'Available through specialized gender identity investigation teams (utredningsteam) at university hospitals (Stockholm - Karolinska, Gothenburg - Sahlgrenska, etc.). Hormones and surgery covered by public healthcare (landsting/region). Wait times 1-3 years for initial assessment. Capacity being expanded.',
      transHealthcareStateFunded: true,
      prepAvailable: true,
      militaryService: 'Open service. No restrictions. Swedish Armed Forces (Försvarsmakten) actively promote LGBTQ+ inclusion.',
      conversionTherapyBan: ConversionTherapyBan.fullBan,
      conversionTherapyDetails: 'Banned since 2024. Criminal penalties for performing conversion therapy on any person.',
      safetyRating: SafetyRating.verySafe,
      safetyNotes: 'One of the safest and most progressive countries globally. Stockholm has vibrant LGBTQ+ scene (Södermalm). EuroPride and Stockholm Pride major events. Gothenburg, Malmö also very welcoming. Very high public acceptance. Sweden has been a pioneer of LGBTQ+ rights globally.',
      ilgaEuropeRanking: 76.0,
      organizations: [
        LgbtqOrganization(
          name: 'RFSL (Swedish Federation for LGBTQI+ Rights)',
          type: 'community, advocacy, legal aid, asylum support',
          phone: '+46 8 501 629 00',
          email: 'forbundet@rfsl.se',
          website: 'https://www.rfsl.se',
          address: 'Sveavägen 59, 113 59 Stockholm',
          languages: 'Swedish, English',
          notes: 'National LGBTQ+ organization since 1950. 30+ local branches. Comprehensive services including asylum support.',
        ),
        LgbtqOrganization(
          name: 'RFSL Newcomers',
          type: 'asylum support, community',
          phone: '+46 8 501 629 00',
          email: 'newcomers@rfsl.se',
          website: 'https://www.rfsl.se/verksamhet/newcomers/',
          languages: 'Swedish, English, Arabic, Farsi, Somali, Tigrinya',
          notes: 'RFSL program specifically for LGBTQ+ asylum seekers and new arrivals. Social activities, support, information.',
        ),
        LgbtqOrganization(
          name: 'Swedish Refugee Law Center (Asylrättscentrum)',
          type: 'legal aid, asylum support',
          phone: '+46 8 665 09 30',
          email: 'info@sweref.org',
          website: 'https://sweref.org',
          languages: 'Swedish, English, Arabic',
          notes: 'Free legal advice for asylum seekers. SOGI-experienced lawyers.',
        ),
        LgbtqOrganization(
          name: 'RFSL Rådgivningen Skåne',
          type: 'counseling, health',
          phone: '+46 40 611 99 55',
          email: 'skane@rfsl.se',
          website: 'https://www.rfslmalmo.se',
          languages: 'Swedish, English, Arabic',
          notes: 'LGBTQ+ counseling, health services, HIV/STI testing in southern Sweden.',
        ),
      ],
      immigrantSpecificNotes: 'Foreign same-sex marriages fully recognized. Family reunification for same-sex spouses (maintenance requirement applies). Personnummer (personal number) facilitates all registration. Migrationsverket processes residence permits. RFSL branches in most major cities.',
      refugeeSpecificNotes: 'Sweden has extensive SOGI asylum experience. RFSL Newcomers is a unique specialized program. Migrationsverket has SOGI guidelines. Accommodation system (ABO/EBO) allows some choice. Stockholm, Gothenburg, Malmö have the most resources. Note: Sweden\'s asylum policies have tightened generally since 2015 but SOGI claims remain well-handled.',
    ),

  };
}
