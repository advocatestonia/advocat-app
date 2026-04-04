// Transportation & Driving License Rights Database for all 27 EU Countries
// Real data for immigrant driving license recognition, conversion, and transport rights
// Last updated: 2026-04
//
// Sources: EU Driving License Directive 2006/126/EC (as amended by 2018/645/EU),
// European Commission DG MOVE transport data, national driving license authorities,
// Vienna Convention on Road Traffic (1968), Geneva Convention on Road Traffic (1949),
// UNHCR asylum seeker rights documentation, FRA reports on migrant mobility,
// national public transport authority fare policies, OECD International Transport Forum,
// bilateral license recognition agreements between EU and third countries.

class TransportationRights {
  final String country;
  final String countryCode;
  final bool foreignLicenseAccepted;
  final int foreignLicenseValidMonths;
  final String foreignLicenseConditions;
  final String conversionProcess;
  final String conversionCostEuros;
  final bool theoryTestRequired;
  final bool practicalTestRequired;
  final List<String> theoryTestLanguages;
  final List<String> mutualRecognitionCountries;
  final String idpRules;
  final String policeStopConsequences;
  final String insuranceRequirements;
  final String publicTransportDiscounts;
  final String asylumSeekerTransportRights;
  final String drivingAuthority;
  final String authorityWebsite;
  final String legalBasis;
  final String immigrantSpecificNotes;
  final String strictnessRating; // 'lenient', 'moderate', 'strict'

  const TransportationRights({
    required this.country,
    required this.countryCode,
    required this.foreignLicenseAccepted,
    required this.foreignLicenseValidMonths,
    required this.foreignLicenseConditions,
    required this.conversionProcess,
    required this.conversionCostEuros,
    required this.theoryTestRequired,
    required this.practicalTestRequired,
    required this.theoryTestLanguages,
    required this.mutualRecognitionCountries,
    required this.idpRules,
    required this.policeStopConsequences,
    required this.insuranceRequirements,
    required this.publicTransportDiscounts,
    required this.asylumSeekerTransportRights,
    required this.drivingAuthority,
    required this.authorityWebsite,
    required this.legalBasis,
    required this.immigrantSpecificNotes,
    required this.strictnessRating,
  });

  Map<String, dynamic> toMap() {
    return {
      'country': country,
      'countryCode': countryCode,
      'foreignLicenseAccepted': foreignLicenseAccepted,
      'foreignLicenseValidMonths': foreignLicenseValidMonths,
      'foreignLicenseConditions': foreignLicenseConditions,
      'conversionProcess': conversionProcess,
      'conversionCostEuros': conversionCostEuros,
      'theoryTestRequired': theoryTestRequired,
      'practicalTestRequired': practicalTestRequired,
      'theoryTestLanguages': theoryTestLanguages,
      'mutualRecognitionCountries': mutualRecognitionCountries,
      'idpRules': idpRules,
      'policeStopConsequences': policeStopConsequences,
      'insuranceRequirements': insuranceRequirements,
      'publicTransportDiscounts': publicTransportDiscounts,
      'asylumSeekerTransportRights': asylumSeekerTransportRights,
      'drivingAuthority': drivingAuthority,
      'authorityWebsite': authorityWebsite,
      'legalBasis': legalBasis,
      'immigrantSpecificNotes': immigrantSpecificNotes,
      'strictnessRating': strictnessRating,
    };
  }
}

class TransportationDatabase {
  static final TransportationDatabase _instance =
      TransportationDatabase._internal();
  factory TransportationDatabase() => _instance;
  TransportationDatabase._internal();

  // ============================================================
  // EU DRIVING LICENSE DIRECTIVE 2006/126/EC - COMMON RULES
  // ============================================================
  //
  // Key provisions affecting immigrants:
  //
  // 1. MUTUAL RECOGNITION (Art. 2): All EU/EEA driving licenses are mutually
  //    recognized. A license issued by any EU member state is valid in all others.
  //
  // 2. SINGLE LICENSE PRINCIPLE (Art. 7): A person may hold only one EU driving
  //    license. When establishing normal residence in another EU country, you may
  //    continue using your existing EU license (no conversion needed) until expiry.
  //
  // 3. NORMAL RESIDENCE RULE (Art. 12): Defined as residing in a place for at
  //    least 185 days per calendar year due to personal/occupational ties.
  //
  // 4. THIRD-COUNTRY LICENSES (Art. 11(6)): When a holder of a third-country
  //    license establishes normal residence in an EU state, that state's national
  //    rules apply. The Directive does NOT harmonize third-country recognition.
  //    Each member state sets its own rules for non-EU license holders.
  //
  // 5. EXCHANGE (Art. 11(1-5)): Member states may exchange a license issued by
  //    another EU state for an equivalent national license. For third countries,
  //    exchange conditions are set nationally.
  //
  // 6. CATEGORIES: Harmonized EU categories (AM, A1, A2, A, B, BE, B1, C1, C1E,
  //    C, CE, D1, D1E, D, DE). Third-country license holders converting must
  //    match categories to the EU system.
  //
  // 7. PROPOSED REVISION (2023 proposal): The European Commission proposed
  //    updates including digital licenses, stricter medical checks for older
  //    drivers, and probationary periods. Still under legislative process.
  //
  // THIRD-COUNTRY RECOGNITION OVERVIEW:
  // - No EU-wide rule: each member state decides individually
  // - Vienna Convention (1968) signatories: licenses generally recognized for
  //   short stays (tourism) but NOT for residents
  // - Geneva Convention (1949): older treaty, less widely applied
  // - Bilateral agreements: some countries have specific deals (e.g., Japan,
  //   South Korea, Switzerland, certain Gulf states)
  // - International Driving Permit (IDP): Recommended for short stays, NOT a
  //   substitute for license conversion when becoming resident
  //
  // STRICTNESS RANKING (general):
  // Strictest: Germany, Austria, Netherlands, Finland, Sweden, Denmark
  // Moderate: France, Belgium, Spain, Italy, Portugal, Ireland
  // Most lenient: Poland, Romania, Bulgaria, Hungary, Czech Republic, Croatia
  // ============================================================

  static const List<TransportationRights> allCountries = [
    // ============================================================
    // 1. AUSTRIA
    // ============================================================
    TransportationRights(
      country: 'Austria',
      countryCode: 'AT',
      foreignLicenseAccepted: true,
      foreignLicenseValidMonths: 6,
      foreignLicenseConditions:
          'Third-country licenses valid for 6 months from establishing residence. '
          'Must be accompanied by a certified German translation or IDP. License must '
          'be valid and not expired. After 6 months, driving without Austrian license '
          'is illegal. EEA/Swiss licenses valid indefinitely until expiry.',
      conversionProcess:
          'Apply at local Bezirkshauptmannschaft (district authority) or Magistrat. '
          'Required: valid foreign license, passport, residence registration (Meldezettel), '
          'medical certificate (Ärztliches Gutachten, ~EUR 35), passport photo, certified '
          'German translation of license. Countries with bilateral agreement (Switzerland, '
          'Japan, South Korea, Taiwan, some US states): direct exchange without test. '
          'All others: must pass theory test (computer-based, multiple choice) and '
          'practical driving test. Surrender of foreign license required.',
      conversionCostEuros: '120-400 (fees ~EUR 120 + medical ~EUR 35 + translation ~EUR 25 + '
          'driving school if needed ~EUR 200+)',
      theoryTestRequired: true,
      practicalTestRequired: true,
      theoryTestLanguages: [
        'German',
        'English',
        'Turkish',
        'Croatian',
        'Slovenian',
        'Hungarian',
      ],
      mutualRecognitionCountries: [
        'Switzerland',
        'Japan',
        'South Korea',
        'Taiwan',
        'Some US states (varies by Bundesland)',
        'All EEA countries',
      ],
      idpRules:
          'IDP accepted for tourists/short-stay visitors for up to 6 months or 12 months '
          'from entry (whichever comes first). Must accompany original license. Not valid '
          'as standalone document. IDP based on Vienna Convention 1968 preferred.',
      policeStopConsequences:
          'Driving without valid license after 6-month grace period: fine EUR 363-2,180. '
          'Vehicle may be impounded. Classified as administrative offense '
          '(Verwaltungsübertretung). Repeated offense: criminal charges possible. '
          'Insurance may refuse to pay claims.',
      insuranceRequirements:
          'Third-party liability insurance (Haftpflichtversicherung) mandatory for all '
          'vehicles. Minimum coverage: EUR 7.6 million for personal injury, EUR 1.3 million '
          'for property damage. Foreign license holders may face higher premiums. '
          'Green Card system accepted for foreign-registered vehicles.',
      publicTransportDiscounts:
          'KlimaTicket: EUR 1,095/year for all public transport nationwide (no specific '
          'immigrant discount). Social tariffs available in Vienna (Mobilpass for low-income '
          'residents: 50% discount on annual pass). Asylum seekers in federal care receive '
          'free local transport in some Bundesländer. Students with residence permit: '
          'semester ticket ~EUR 75-150.',
      asylumSeekerTransportRights:
          'Asylum seekers in federal care (Grundversorgung) receive basic mobility support '
          'varying by province. Vienna: free Wiener Linien pass for those in Grundversorgung. '
          'Upper Austria, Tyrol: transport vouchers for appointments. No right to drive '
          'without valid license. Cannot convert license without residence permit (only '
          'with Aufenthaltstitel, not Aufenthaltsberechtigung for asylum procedures).',
      drivingAuthority: 'Bundesministerium für Klimaschutz, Umwelt, Energie, Mobilität',
      authorityWebsite: 'https://www.bmk.gv.at',
      legalBasis: 'Führerscheingesetz (FSG) §23-§25, Führerscheingesetz-Durchführungsverordnung',
      immigrantSpecificNotes:
          'Austria is STRICT. Most third-country licenses require both theory and practical '
          'tests. Medical certificate mandatory. The 6-month window is firm. Language barrier '
          'is significant as theory test is primarily in German (English available but '
          'limited slots). Ukrainian refugees received temporary extensions during 2022-2024. '
          'Recognized refugee status (Asylberechtigte) holders can convert license same as '
          'other third-country nationals.',
      strictnessRating: 'strict',
    ),

    // ============================================================
    // 2. BELGIUM
    // ============================================================
    TransportationRights(
      country: 'Belgium',
      countryCode: 'BE',
      foreignLicenseAccepted: true,
      foreignLicenseValidMonths: 6,
      foreignLicenseConditions:
          'Non-EU licenses valid for 6 months after establishing residence (registration '
          'at commune). Must carry original license + IDP or sworn translation. After 6 months, '
          'license must be exchanged or new Belgian license obtained. Tourists: license valid '
          'for duration of stay (max 6 months). EEA licenses valid until expiry.',
      conversionProcess:
          'Apply at commune (gemeentehuis/maison communale) of residence. Documents: valid '
          'foreign license, identity document, residence permit, 2 photos, medical certificate '
          '(if over 50 or for categories C/D). Countries with bilateral agreement: direct '
          'exchange without test. Others: must complete Belgian driving education (theory + '
          'practical test). Belgium has complex regional driving school systems. Wallonia, '
          'Flanders, and Brussels each have slightly different rules.',
      conversionCostEuros: '25-1,500 (exchange fee EUR 25 + driving school if needed: '
          'theory EUR 50-100, practical lessons EUR 800-1,200)',
      theoryTestRequired: true,
      practicalTestRequired: true,
      theoryTestLanguages: [
        'French',
        'Dutch',
        'German',
        'English (Brussels only, with conditions)',
      ],
      mutualRecognitionCountries: [
        'Switzerland',
        'Japan',
        'South Korea',
        'Algeria',
        'Morocco',
        'Tunisia',
        'Turkey',
        'DR Congo',
        'Republic of Congo',
        'Monaco',
        'Quebec (Canada)',
        'All EEA countries',
      ],
      idpRules:
          'IDP recommended for non-EU license holders as accompaniment. Valid for tourist stays. '
          'Not accepted as standalone document. Both Vienna (1968) and Geneva (1949) convention '
          'IDPs recognized. After establishing residence, IDP does not extend the 6-month '
          'grace period.',
      policeStopConsequences:
          'Driving without valid license: fine EUR 200-2,000 (immediate perception possible). '
          'Vehicle may be seized. If combined with other offenses (no insurance, accident): '
          'criminal prosecution possible. Court can impose driving ban of 8 days to 5 years. '
          'Uninsured driving: separate offense with higher penalties.',
      insuranceRequirements:
          'Mandatory third-party liability (responsabilité civile/burgerlijke aansprakelijkheid). '
          'Minimum coverage per incident: EUR 100 million combined. No-claims bonus transfers '
          'possible from some countries with documentation. Foreign license holders typically '
          'quoted higher premiums. Green Card required for foreign-registered vehicles.',
      publicTransportDiscounts:
          'STIB/MIVB (Brussels): free for CPAS/OCMW beneficiaries, EUR 12/year for asylum '
          'seekers in reception network. De Lijn (Flanders): Buzzy Pazz/Omnipas at reduced rates '
          'for low-income. TEC (Wallonia): free for those receiving social integration income '
          '(revenu d\'intégration sociale). SNCB/NMBS rail: no specific immigrant discount but '
          'social tariffs for low income (50% reduction with CPAS attestation).',
      asylumSeekerTransportRights:
          'Asylum seekers in Fedasil reception network receive: monthly allowance of EUR 7.40/week '
          '(pocket money) which may partially cover transport. Many reception centers provide '
          'transport vouchers for legal appointments and medical visits. Brussels STIB pass available '
          'for EUR 12/year with Fedasil attestation. Cannot convert driving license until granted '
          'protection status (refugee or subsidiary protection). May drive on valid foreign license '
          'for 6 months from registration.',
      drivingAuthority: 'SPF Mobilité et Transports / FOD Mobiliteit en Vervoer',
      authorityWebsite: 'https://mobilit.belgium.be',
      legalBasis: 'Arrêté Royal du 23 mars 1998 relatif au permis de conduire (Art. 23-27)',
      immigrantSpecificNotes:
          'Belgium is MODERATE. Notably generous mutual recognition with North African countries '
          '(Algeria, Morocco, Tunisia) and DR Congo due to historical ties. This means many '
          'African immigrants can exchange licenses without tests. The regional complexity '
          '(Flanders/Wallonia/Brussels) means rules vary by where you live. French, Dutch, or '
          'German language skills needed for theory test.',
      strictnessRating: 'moderate',
    ),

    // ============================================================
    // 3. BULGARIA
    // ============================================================
    TransportationRights(
      country: 'Bulgaria',
      countryCode: 'BG',
      foreignLicenseAccepted: true,
      foreignLicenseValidMonths: 12,
      foreignLicenseConditions:
          'Third-country licenses valid for 12 months from establishing residence. Must be '
          'accompanied by certified Bulgarian translation or IDP. License must conform to '
          'Vienna Convention format or be accompanied by IDP. After 12 months, exchange or '
          'new license required. EEA licenses recognized until expiry.',
      conversionProcess:
          'Apply at regional KAT (Traffic Police) office. Required: application form, valid '
          'foreign license + certified translation, passport, residence permit (long-term or '
          'permanent), medical certificate (from authorized physician, ~EUR 20), passport photo. '
          'Countries with bilateral agreements: direct exchange. Others: theory and practical '
          'test required. Foreign license is NOT surrendered (returned with hole punch marking '
          'it as exchanged).',
      conversionCostEuros: '50-300 (administrative fee ~EUR 25 + medical ~EUR 20 + translation '
          '~EUR 15 + driving lessons if needed ~EUR 150-250)',
      theoryTestRequired: true,
      practicalTestRequired: true,
      theoryTestLanguages: [
        'Bulgarian',
        'English',
        'Turkish',
        'Russian (unofficial, some centers)',
      ],
      mutualRecognitionCountries: [
        'Serbia',
        'North Macedonia',
        'Ukraine',
        'Moldova',
        'Russia (suspended since 2022)',
        'Turkey',
        'All EEA countries',
      ],
      idpRules:
          'IDP valid for tourists up to 12 months. Must accompany original license. Both '
          'Vienna and Geneva convention IDPs accepted. IDP alone is not valid for residents '
          'after the grace period.',
      policeStopConsequences:
          'Driving without valid license: fine BGN 100-300 (~EUR 50-150). Vehicle may be '
          'temporarily seized. No criminal record for first offense. Repeated offense: fine '
          'BGN 500-1,000 + possible imprisonment up to 1 year. Points system does not apply '
          'to unlicensed driving (separate offense).',
      insuranceRequirements:
          'Mandatory third-party liability (Гражданска отговорност). Minimum coverage: '
          'EUR 10.42 million for personal injury, EUR 2.1 million for property. Insurance '
          'relatively affordable (~EUR 150-300/year for basic). Green Card system applies. '
          'No-claims history from abroad may be accepted with documentation.',
      publicTransportDiscounts:
          'Sofia Urban Mobility Center (Sofiyski Metropoliten): monthly pass BGN 50 (~EUR 25). '
          'Retirees, students, disabled: free or heavily reduced. No specific immigrant '
          'discounts but low-income social assistance recipients may qualify for reduced fares '
          'through municipal programs. Asylum seekers in SAR (State Agency for Refugees) centers '
          'receive basic transport for appointments.',
      asylumSeekerTransportRights:
          'Asylum seekers accommodated in SAR centers receive: housing, food, and small monthly '
          'allowance (~BGN 65/month). Transport to legal/medical appointments typically arranged '
          'by SAR or UNHCR partners. No dedicated public transport pass. Bulgarian language '
          'course participants may receive transport subsidies. Cannot convert license until '
          'granted refugee or humanitarian status.',
      drivingAuthority: 'Изпълнителна агенция "Автомобилна администрация" (IAAA)',
      authorityWebsite: 'https://www.rta.government.bg',
      legalBasis: 'Закон за движението по пътищата (Road Traffic Act), Art. 160-163',
      immigrantSpecificNotes:
          'Bulgaria is LENIENT. The 12-month grace period is one of the longest in the EU. '
          'Costs are among the lowest. Recognition of Balkan and ex-Soviet country licenses '
          'is common. The process is bureaucratic but not expensive. Language can be a barrier '
          'as Bulgarian theory test is the default. Many driving schools cater to Russian and '
          'Turkish speakers informally.',
      strictnessRating: 'lenient',
    ),

    // ============================================================
    // 4. CROATIA
    // ============================================================
    TransportationRights(
      country: 'Croatia',
      countryCode: 'HR',
      foreignLicenseAccepted: true,
      foreignLicenseValidMonths: 12,
      foreignLicenseConditions:
          'Third-country licenses valid for up to 12 months from establishing temporary '
          'residence. Must be valid and not expired. Certified Croatian translation or IDP '
          'required. After 12 months or upon obtaining permanent residence, conversion mandatory. '
          'EEA licenses valid without limit until expiry.',
      conversionProcess:
          'Apply at police station (Policijska postaja) in area of residence. Documents: '
          'application form, valid foreign license, certified translation, OIB (personal '
          'identification number), residence permit, medical certificate (~EUR 40), passport '
          'photo. Vienna Convention countries: exchange possible without test if license has '
          'photo. Non-Vienna Convention: theory and practical test required.',
      conversionCostEuros: '70-400 (administrative fee ~EUR 35 + medical ~EUR 40 + translation '
          '~EUR 20 + tests/lessons if needed ~EUR 200-300)',
      theoryTestRequired: true,
      practicalTestRequired: true,
      theoryTestLanguages: ['Croatian', 'English', 'Italian (in Istria region)'],
      mutualRecognitionCountries: [
        'Serbia',
        'Bosnia and Herzegovina',
        'Montenegro',
        'North Macedonia',
        'Kosovo',
        'Slovenia',
        'All EEA countries',
      ],
      idpRules:
          'IDP accepted for tourist stays (up to 12 months). Must accompany original license. '
          'Vienna Convention IDP preferred. IDP does not extend the 12-month residential grace '
          'period.',
      policeStopConsequences:
          'Driving without valid license: fine HRK 5,000-15,000 (~EUR 660-2,000). Vehicle '
          'impoundment possible. Police may issue temporary driving ban. Criminal offense if '
          'combined with accident or DUI. Insurance invalidation risk.',
      insuranceRequirements:
          'Mandatory third-party liability (obvezno osiguranje od auto odgovornosti). Minimum '
          'coverage: EUR 7.6 million personal injury, EUR 1.12 million property. Croatia joined '
          'EU in 2013, insurance standards fully aligned. Green Card system applies. Insurance '
          'costs ~EUR 200-400/year.',
      publicTransportDiscounts:
          'ZET (Zagreb): monthly pass ~EUR 40. Students: 50% discount. Senior citizens (65+): '
          'free in Zagreb. No specific immigrant/asylum seeker discounts in national scheme. '
          'Social welfare recipients may qualify for reduced fares through municipal social '
          'welfare centers (CZSS). Some NGOs provide transport vouchers.',
      asylumSeekerTransportRights:
          'Asylum seekers in reception centers (Porin, Kutina) receive: accommodation, meals, '
          'and small financial allowance (~HRK 100/month). Transport to legal proceedings and '
          'medical appointments arranged by reception center or NGOs (Croatian Red Cross, '
          'JRS). No automatic public transport pass. Work permit holders (after 9 months) '
          'have same transport access as residents. Cannot convert license during asylum procedure.',
      drivingAuthority: 'Ministarstvo unutarnjih poslova (Ministry of Interior)',
      authorityWebsite: 'https://mup.gov.hr',
      legalBasis: 'Zakon o sigurnosti prometa na cestama (Road Traffic Safety Act), Art. 218-227',
      immigrantSpecificNotes:
          'Croatia is LENIENT. Very generous recognition of Western Balkan licenses (Serbia, '
          'Bosnia, Montenegro) due to shared Yugoslav heritage and similar driving standards. '
          'The 12-month period is generous. Costs are moderate for EU standards. Language '
          'barrier exists as Croatian is primary test language. EU membership since 2013 '
          'means standards are still being aligned with older member states.',
      strictnessRating: 'lenient',
    ),

    // ============================================================
    // 5. CYPRUS
    // ============================================================
    TransportationRights(
      country: 'Cyprus',
      countryCode: 'CY',
      foreignLicenseAccepted: true,
      foreignLicenseValidMonths: 6,
      foreignLicenseConditions:
          'Third-country licenses valid for 6 months from establishing residence. IDP or '
          'certified English/Greek translation required. License must be valid and issued by '
          'the country of previous normal residence. After 6 months, must obtain Cyprus license. '
          'Note: Cyprus drives on the LEFT (UK legacy). EEA licenses valid until expiry.',
      conversionProcess:
          'Apply at District Administration Office (Road Transport Department). Documents: '
          'application form, foreign license + certified translation, passport, residence permit '
          '(MEU1/MEU3 or Yellow Slip), medical certificate, 2 passport photos. Countries with '
          'agreements (Japan, South Korea, Australia, South Africa, certain Gulf states): '
          'exchange without test. Others: theory and practical test on LEFT-HAND driving.',
      conversionCostEuros: '40-800 (exchange fee ~EUR 40 + medical ~EUR 30 + driving school for '
          'left-hand driving adjustment: EUR 300-700)',
      theoryTestRequired: true,
      practicalTestRequired: true,
      theoryTestLanguages: ['Greek', 'English', 'Turkish'],
      mutualRecognitionCountries: [
        'Japan',
        'South Korea',
        'Australia',
        'South Africa',
        'United Kingdom',
        'Switzerland',
        'All EEA countries',
      ],
      idpRules:
          'IDP valid for tourists (up to 6 months). Must accompany original license. Useful for '
          'translation purpose since Greek/English are official. Both Vienna and Geneva IDPs '
          'accepted. Note: IDP must specify validity for left-hand traffic countries.',
      policeStopConsequences:
          'Driving without valid license: fine EUR 100-500. Court appearance may be required. '
          'Vehicle may be impounded. Insurance automatically voided if driving unlicensed. '
          'Points system: 4 points for unlicensed driving (12 points = suspension).',
      insuranceRequirements:
          'Mandatory third-party liability. Minimum: EUR 1.12 million per victim (unlimited '
          'number of victims), EUR 1.12 million property. Insurance relatively expensive '
          '(~EUR 400-800/year). Left-hand driving experience may affect premiums. Green Card '
          'system applies for foreign vehicles.',
      publicTransportDiscounts:
          'OSEL (public buses): monthly pass ~EUR 40. Students: 50% discount. Senior citizens: '
          'free bus travel. Low-income families: subsidized through Social Welfare Services. '
          'No specific asylum seeker transport program at national level. Limited public '
          'transport network outside Nicosia and Limassol.',
      asylumSeekerTransportRights:
          'Asylum seekers in Kofinou reception center or Pournara emergency center: basic needs '
          'covered by Asylum Service. Monthly allowance: EUR 100 (single adult) from which '
          'transport must be self-funded. NGOs (UNHCR Cyprus, KISA, Cyprus Refugee Council) '
          'sometimes provide transport assistance. Work permit available after 1 month. '
          'Cannot convert license during procedure. Very limited public transport to/from '
          'reception centers.',
      drivingAuthority: 'Τμήμα Οδικών Μεταφορών (Road Transport Department)',
      authorityWebsite: 'http://www.mcw.gov.cy/rtd',
      legalBasis: 'Motor Vehicles and Road Traffic Law (Cap. 332), as amended',
      immigrantSpecificNotes:
          'Cyprus is MODERATE. Left-hand driving is a major adjustment for most immigrants. '
          'English availability for theory test is helpful. Good recognition of Commonwealth '
          'and Asian licenses (UK, Australia, Japan, South Korea). Small island with limited '
          'public transport outside cities. Turkish-speaking north operates under different '
          'rules (Republic of Cyprus law applies only in government-controlled areas). Many '
          'immigrants rely on employer-provided transport.',
      strictnessRating: 'moderate',
    ),

    // ============================================================
    // 6. CZECH REPUBLIC
    // ============================================================
    TransportationRights(
      country: 'Czech Republic',
      countryCode: 'CZ',
      foreignLicenseAccepted: true,
      foreignLicenseValidMonths: 3,
      foreignLicenseConditions:
          'Third-country licenses valid for 3 months after establishing permanent residence, '
          'or for the duration of temporary residence (up to 1 year, renewable). License must '
          'conform to Vienna Convention or be accompanied by IDP/certified Czech translation. '
          'After expiry of grace period, Czech license required. EEA licenses valid until expiry.',
      conversionProcess:
          'Apply at municipal authority (obecní úřad obce s rozšířenou působností) in area '
          'of residence. Documents: application form, foreign license, passport, long-term '
          'residence permit, medical certificate (~EUR 15), certified translation, 1 passport '
          'photo. Vienna Convention countries with photo on license: may exchange without test. '
          'Others: theory + practical test. Foreign license surrendered and returned to issuing '
          'country via diplomatic channels.',
      conversionCostEuros: '20-500 (exchange fee CZK 50 ~EUR 2 + medical ~EUR 15 + tests if '
          'needed: theory CZK 700 ~EUR 28, practical CZK 700 ~EUR 28 + lessons ~EUR 300-400)',
      theoryTestRequired: true,
      practicalTestRequired: true,
      theoryTestLanguages: ['Czech', 'English'],
      mutualRecognitionCountries: [
        'Japan',
        'South Korea',
        'Ukraine',
        'Vietnam',
        'All Vienna Convention signatories (with conditions)',
        'All EEA countries',
      ],
      idpRules:
          'IDP valid for tourists and short-stay visitors. Must accompany original license. '
          'Vienna Convention (1968) IDP preferred. Geneva Convention (1949) IDP also accepted. '
          'IDP not valid for residents after grace period expires.',
      policeStopConsequences:
          'Driving without valid license: fine CZK 25,000-50,000 (~EUR 1,000-2,000) in '
          'administrative proceedings. Criminal offense under Section 337 Criminal Code '
          '(obstruction of official decision) if driving despite license suspension. Vehicle '
          'may be towed. Points: 7 points (12 = 1-year ban).',
      insuranceRequirements:
          'Mandatory third-party liability (povinné ručení). Minimum: CZK 44 million '
          '(~EUR 1.76 million) personal injury, CZK 44 million property. Very affordable '
          'insurance market (~EUR 80-200/year). Green Card required for foreign vehicles. '
          'Online comparison tools widely available.',
      publicTransportDiscounts:
          'Prague DPP: monthly pass CZK 550 (~EUR 22), annual CZK 3,650 (~EUR 146). Students '
          'under 26: 75% discount on rail. Seniors 65+: free public transport nationwide. '
          'Social benefit recipients: reduced fares available through municipal social '
          'departments. No specific asylum seeker discount program but low overall costs.',
      asylumSeekerTransportRights:
          'Asylum seekers in SUZ (Administration of Refugee Facilities) centers receive: '
          'accommodation, meals, and pocket money CZK 6/day (~EUR 0.24). Transport to '
          'legal/medical appointments arranged by SUZ. No public transport pass provided. '
          'After receiving protection status: same transport rights as Czech residents. '
          'Integration program (SIP) may include transport assistance. Cannot convert license '
          'during asylum procedure.',
      drivingAuthority: 'Ministerstvo dopravy ČR (Ministry of Transport)',
      authorityWebsite: 'https://www.mdcr.cz',
      legalBasis: 'Zákon č. 361/2000 Sb. o silničním provozu (Road Traffic Act), §104-§116',
      immigrantSpecificNotes:
          'Czech Republic is MODERATE to LENIENT. The 3-month grace period for permanent '
          'residents is short, but temporary residence holders get longer. Very low costs by EU '
          'standards. Vietnamese community has established driving school networks (Vietnamese '
          'is one of the largest immigrant communities). Ukrainian license holders benefit from '
          'bilateral recognition. English theory test available but Czech is strongly preferred.',
      strictnessRating: 'moderate',
    ),

    // ============================================================
    // 7. DENMARK
    // ============================================================
    TransportationRights(
      country: 'Denmark',
      countryCode: 'DK',
      foreignLicenseAccepted: true,
      foreignLicenseValidMonths: 6,
      foreignLicenseConditions:
          'Third-country licenses valid for 6 months from CPR number registration (establishing '
          'residence). License must be valid and in Roman script or accompanied by certified '
          'translation/IDP. Some non-Vienna Convention licenses may not be recognized at all. '
          'After 6 months, Danish license mandatory. EEA licenses: valid but must be exchanged '
          'within 2 years when category expires.',
      conversionProcess:
          'Apply at Borgerservice (citizen service center) in municipality. Documents: original '
          'foreign license, passport, CPR number, residence permit, medical certificate (from '
          'approved physician, ~DKK 500/EUR 67), passport photo, declaration of any driving '
          'bans. MOST third-country licenses require FULL Danish driving education including '
          'mandatory first-aid course, theory test, practical test, and slippery road course. '
          'Very few bilateral agreements. Old license surrendered.',
      conversionCostEuros: '500-3,000 (administration ~EUR 130 + medical ~EUR 67 + driving '
          'education if needed: theory course ~EUR 400 + practical lessons ~EUR 1,500-2,000 + '
          'first aid course ~EUR 80 + tests ~EUR 200)',
      theoryTestRequired: true,
      practicalTestRequired: true,
      theoryTestLanguages: [
        'Danish',
        'English',
        'Arabic',
        'Farsi (available at some centers)',
      ],
      mutualRecognitionCountries: [
        'Faroe Islands',
        'Greenland',
        'Iceland (EEA)',
        'Switzerland',
        'Japan (partial)',
        'South Korea (partial)',
        'All EEA countries',
      ],
      idpRules:
          'IDP accepted for tourists (max 6 months). Must accompany original license. Only '
          'Vienna Convention (1968) IDP officially recognized. Geneva Convention IDP may be '
          'accepted at police discretion. IDP does not extend grace period for residents.',
      policeStopConsequences:
          'Driving without valid license: fine DKK 5,000 (~EUR 670) minimum. Can increase to '
          'DKK 10,000+ for repeat offenses. Vehicle confiscation possible under certain '
          'conditions (2021 law on vehicle seizure). May affect residence permit renewal. '
          'Criminal prosecution possible for repeated violations.',
      insuranceRequirements:
          'Mandatory third-party liability (ansvarsforsikring). Denmark has among the highest '
          'minimum coverage in EU: DKK 80 million (~EUR 10.7 million) personal injury, '
          'DKK 16 million (~EUR 2.1 million) property. Insurance expensive: ~EUR 500-1,500/year. '
          'Bonus-malus system. Foreign no-claims history rarely accepted.',
      publicTransportDiscounts:
          'Rejsekort (travel card): pay-as-you-go with automatic discounts for frequent travel. '
          'Copenhagen area: monthly pass ~EUR 70-100 (zones vary). DSB rail: Orange tickets for '
          'cheap advance booking. Students (SU recipients): discounted transport. Social pension '
          'recipients: reduced rates. No specific immigrant/asylum seeker transport program.',
      asylumSeekerTransportRights:
          'Asylum seekers in Udlændingestyrelsen (Immigration Service) centers receive: pocket '
          'money DKK 39.05/day (basic rate 2024). Must fund own transport from this. Transport '
          'to asylum interviews and mandatory activities arranged by center. Some centers are '
          'in remote locations with limited public transport (deliberate policy). Tolstrup, '
          'Sjælsmark, Kærshovedgård especially isolated. NGOs (Danish Refugee Council, Red '
          'Cross) provide some assistance. Cannot drive or convert license during procedure.',
      drivingAuthority: 'Færdselsstyrelsen (Danish Road Safety Agency)',
      authorityWebsite: 'https://fstyr.dk',
      legalBasis: 'Færdselsloven (Road Traffic Act) §56-§67, Kørekortbekendtgørelsen',
      immigrantSpecificNotes:
          'Denmark is STRICT. One of the hardest EU countries to convert a foreign license. '
          'Almost all third-country nationals must complete full Danish driving education from '
          'scratch, which is among the most expensive in Europe (EUR 1,500-3,000 total). The '
          'mandatory first-aid and slippery road courses add cost and time. Very few bilateral '
          'agreements. Arabic and Farsi theory tests reflect the largest immigrant groups. '
          'Danish language proficiency is practically needed despite English availability.',
      strictnessRating: 'strict',
    ),

    // ============================================================
    // 8. ESTONIA
    // ============================================================
    TransportationRights(
      country: 'Estonia',
      countryCode: 'EE',
      foreignLicenseAccepted: true,
      foreignLicenseValidMonths: 12,
      foreignLicenseConditions:
          'Third-country licenses valid for 12 months from date of residence registration. '
          'License must conform to Vienna/Geneva Convention or be accompanied by IDP or '
          'certified Estonian/English translation. After 12 months, Estonian license required. '
          'EEA licenses valid without restriction until expiry.',
      conversionProcess:
          'Apply at Maanteeamet (Road Administration) service center. Documents: application '
          'form, foreign license, passport/ID, residence permit, medical certificate (from '
          'family doctor, ~EUR 20-30), 1 photo, translation if needed. Vienna Convention '
          'countries: exchange without test if license has photo and categories match. Others: '
          'theory and practical test required. Digital application possible via eesti.ee portal.',
      conversionCostEuros: '28-500 (state fee EUR 28 + medical ~EUR 25 + driving school if '
          'needed ~EUR 300-450)',
      theoryTestRequired: true,
      practicalTestRequired: true,
      theoryTestLanguages: ['Estonian', 'Russian', 'English'],
      mutualRecognitionCountries: [
        'Ukraine',
        'Russia (suspended)',
        'Belarus (suspended)',
        'Georgia',
        'All Vienna Convention signatories (with photo license)',
        'All EEA countries',
      ],
      idpRules:
          'IDP accepted for tourist stays. Both Vienna and Geneva IDPs recognized. Must '
          'accompany original license. For residents, IDP serves as translation only during '
          'the 12-month grace period, not as an extension.',
      policeStopConsequences:
          'Driving without valid license: fine EUR 400-800. Criminal offense if license was '
          'revoked/suspended (up to 3 years imprisonment). Vehicle not impounded for first '
          'offense typically. Digital police checks are efficient (e-government system). '
          'Record affects future license applications.',
      insuranceRequirements:
          'Mandatory third-party liability (liikluskindlustus). Minimum: EUR 5.6 million per '
          'incident personal injury, EUR 1.12 million property. Managed through Eesti '
          'Liikluskindlustuse Fond (Estonian Motor Insurance Bureau). Costs: ~EUR 150-400/year. '
          'Online quotes easy to obtain. No-claims history from abroad accepted with documentation.',
      publicTransportDiscounts:
          'Tallinn: FREE public transport for registered residents (since 2013, world first '
          'for a capital city). Must have Tallinn registered address and Ühiskaart. County buses: '
          'FREE nationwide since 2018 (excluding Tallinn city and express routes). Trains: '
          'Elron subsidized fares. Students: additional discounts. Estonia has among the most '
          'generous public transport policies in the EU.',
      asylumSeekerTransportRights:
          'Asylum seekers accommodated in Vao or Vägeva reception centers receive: basic needs '
          'coverage + monthly allowance EUR 130. Tallinn residents (including those with '
          'protection status registered in Tallinn) get FREE public transport. Transport to '
          'PPA (Police and Border Guard) interviews arranged by accommodation center. Estonian '
          'Language Foundation may provide transport for language courses. After protection: '
          'same benefits as residents including free Tallinn/county bus transport.',
      drivingAuthority: 'Transpordiamet (Transport Administration)',
      authorityWebsite: 'https://transpordiamet.ee',
      legalBasis: 'Liiklusseadus (Traffic Act) §96-§117',
      immigrantSpecificNotes:
          'Estonia is MODERATE to LENIENT. The 12-month grace period is generous. Russian '
          'language theory test is available, benefiting the large Russian-speaking population. '
          'E-government infrastructure makes applications easier. FREE public transport in '
          'Tallinn and on county buses is exceptional in the EU. Low conversion costs. Ukrainian '
          'refugees received special provisions since 2022. Digital-first approach means less '
          'bureaucratic hassle than many EU countries.',
      strictnessRating: 'moderate',
    ),

    // ============================================================
    // 9. FINLAND
    // ============================================================
    TransportationRights(
      country: 'Finland',
      countryCode: 'FI',
      foreignLicenseAccepted: true,
      foreignLicenseValidMonths: 24,
      foreignLicenseConditions:
          'Third-country licenses valid for up to 2 YEARS from establishing residence '
          '(registering municipality). Must be valid and not expired. License must conform to '
          'Vienna Convention or be accompanied by IDP/certified translation. After 2 years or '
          'when license expires (whichever first), Finnish license required. EEA licenses '
          'recognized without time limit until expiry.',
      conversionProcess:
          'Apply at Ajovarma service point (Traficom authorized). Documents: application form, '
          'foreign license + certified translation (authorized translator), passport, residence '
          'permit, medical certificate (from occupational health doctor or private clinic, '
          '~EUR 50-80), passport photo. Countries with bilateral agreements: exchange without '
          'test. Others: FULL Finnish driving education required including theory test '
          '(computer-based), practical test, slippery conditions training (liukkaan kelin '
          'harjoittelu), and dark driving training (pimeän ajon harjoittelu). Two-phase system: '
          'after passing test, 2-year probationary period begins.',
      conversionCostEuros: '100-3,500 (exchange fee ~EUR 55 + medical ~EUR 60 + driving school if '
          'needed: theory EUR 200-300, practical EUR 1,500-2,500, slippery course EUR 150, '
          'dark driving EUR 100)',
      theoryTestRequired: true,
      practicalTestRequired: true,
      theoryTestLanguages: ['Finnish', 'Swedish', 'English'],
      mutualRecognitionCountries: [
        'Japan',
        'South Korea',
        'Taiwan',
        'Hong Kong',
        'Macau',
        'Switzerland',
        'United Kingdom',
        'All EEA countries',
      ],
      idpRules:
          'IDP accepted for tourists and during the 2-year grace period for residents. Both '
          'Vienna and Geneva IDPs accepted. Must accompany original license. IDP is strongly '
          'recommended as Finnish police may not recognize non-Latin script licenses without '
          'translation.',
      policeStopConsequences:
          'Driving without valid license: day-fine system (päiväsakko) based on income. Minimum '
          '~EUR 120, can be thousands for high earners. Criminal offense (liikennerikkomus). '
          'Vehicle may be impounded. Affects residence permit assessment (criminal record). '
          'Finland has among the highest traffic fines in EU due to income-based system.',
      insuranceRequirements:
          'Mandatory third-party liability (liikennevakuutus). Minimum coverage: unlimited for '
          'personal injury, EUR 3.3 million property. Among the highest coverage requirements '
          'in EU. Costs: EUR 400-1,200/year (depends on vehicle, age, region). Bonus-malus '
          'system. Foreign no-claims history: some insurers accept with proof from previous '
          'insurer. Liikennevakuutuskeskus (Finnish Motor Insurance Centre) oversees.',
      publicTransportDiscounts:
          'HSL (Helsinki region): monthly pass EUR 62.70 (AB zone). Student discount: ~50%. '
          'Senior (70+): free in many cities. Kela transport: reimbursement for medical travel. '
          'Low-income: some municipalities provide transport vouchers through social services '
          '(toimeentulotuki/social assistance can include transport costs). VR (rail): student '
          'and conscript discounts.',
      asylumSeekerTransportRights:
          'Asylum seekers in Migri (Finnish Immigration Service) reception centers receive: '
          'reception allowance EUR 92/month (single adult in center with meals) or EUR 323/month '
          '(in private accommodation). Transport to Migri interviews and legal aid meetings '
          'covered by reception center. Some centers provide bus cards for local transport. '
          'Helsinki reception center residents may receive HSL travel card. Kela medical '
          'transport applies for health appointments. Cannot convert license during asylum '
          'process. After protection status: immediate access to municipal services.',
      drivingAuthority: 'Liikenne- ja viestintävirasto Traficom',
      authorityWebsite: 'https://www.traficom.fi',
      legalBasis: 'Ajokorttilaki 386/2011 (Driving Licence Act), especially §58-§68',
      immigrantSpecificNotes:
          'Finland is STRICT but with a uniquely long 2-year grace period. The extended period '
          'reflects practical reality of Nordic conditions. However, conversion is expensive and '
          'demanding: slippery conditions and dark driving courses are mandatory and unique to '
          'Nordic countries. Income-based fines mean high earners pay enormous penalties. '
          'Japanese, Korean, Taiwanese licenses have good bilateral recognition. Russian and '
          'Ukrainian license holders have NO bilateral agreement and must take full tests. '
          'English theory test available. Public transport is excellent in Helsinki area but '
          'sparse in rural areas where driving is essential.',
      strictnessRating: 'strict',
    ),

    // ============================================================
    // 10. FRANCE
    // ============================================================
    TransportationRights(
      country: 'France',
      countryCode: 'FR',
      foreignLicenseAccepted: true,
      foreignLicenseValidMonths: 12,
      foreignLicenseConditions:
          'Third-country licenses valid for 1 year from establishing residence (date on '
          'carte de séjour or visa long séjour). License must be valid, issued by country of '
          'previous normal residence, and before obtaining the first French residence permit. '
          'Must be accompanied by official French translation (traduction assermentée) by sworn '
          'translator. After 12 months, exchange or new license required. EEA licenses valid '
          'until expiry.',
      conversionProcess:
          'Apply ONLINE via ANTS (Agence Nationale des Titres Sécurisés) at '
          'permisdeconduire.ants.gouv.fr. Documents: foreign license + sworn translation, '
          'titre de séjour, proof of address, ID photos, attestation of rights from issuing '
          'country (if available). Countries with bilateral agreement (reciprocal exchange): '
          'direct exchange without test. Others: must pass French driving test (Code de la route '
          'theory + practical). Process notoriously slow (6-18 months for exchange due to ANTS '
          'backlog). Foreign license must be surrendered.',
      conversionCostEuros: '25-1,800 (exchange fee EUR 25 + sworn translation ~EUR 30-50 + '
          'photos ~EUR 5 + driving school if needed: code ~EUR 300, practical ~EUR 1,000-1,500)',
      theoryTestRequired: true,
      practicalTestRequired: true,
      theoryTestLanguages: [
        'French',
        'English (new tablet-based test since 2016)',
        'Arabic (select centers)',
      ],
      mutualRecognitionCountries: [
        'Algeria',
        'Morocco',
        'Tunisia',
        'Senegal',
        'Côte d\'Ivoire',
        'Mali',
        'Cameroon',
        'Lebanon',
        'Turkey',
        'Japan',
        'South Korea',
        'Taiwan',
        'Quebec (Canada)',
        'Many Francophone African countries',
        'United Kingdom',
        'Monaco',
        'Andorra',
        'All EEA countries',
      ],
      idpRules:
          'IDP accepted for tourists (up to 1 year). Must accompany original license. Both '
          'Vienna and Geneva IDPs accepted. For French residents, IDP does not replace the '
          'obligation to exchange after 12 months.',
      policeStopConsequences:
          'Driving without valid license (conduite sans permis): criminal offense under Art. '
          'L221-2 Code de la route. Penalty: up to 1 year imprisonment + EUR 15,000 fine. '
          'Vehicle confiscation possible. In practice, first offense usually EUR 800 fine + '
          'suspended license ban. Record criminel (criminal record) entry. Insurance void.',
      insuranceRequirements:
          'Mandatory third-party liability (responsabilité civile automobile). France has '
          'UNLIMITED minimum coverage for personal injury (highest in EU). Property minimum: '
          'EUR 1.12 million. Insurance costs: EUR 400-900/year. Fonds de Garantie des Assurances '
          'Obligatoires (FGAO) covers uninsured accidents. Bureau Central de Tarification forces '
          'insurers to provide cover if refused.',
      publicTransportDiscounts:
          'Île-de-France Mobilités (Paris region): Navigo Solidarité for low-income (CMU-C/ACS '
          'beneficiaries): 50% or 75% discount on Navigo pass (normally EUR 86.40/month). '
          'Navigo Solidarité Gratuite: free for RSA recipients. Students under 26: Imagine R '
          'at ~EUR 38/month. SNCF: Tarif social for low-income travelers (various reductions). '
          'Major cities (Lyon, Marseille, etc.): similar social tariffs for CMU holders.',
      asylumSeekerTransportRights:
          'Asylum seekers receive ADA (Allocation pour Demandeur d\'Asile): EUR 6.80/day '
          '(single adult, 2024). Additional EUR 7.40/day for non-accommodated. CADA/HUDA '
          'centers may provide local transport passes. Paris: Navigo Solidarité available for '
          'those with OFII attestation and low income. Transport to OFPRA/CNDA interviews: '
          'reimbursed by OFII. SNCF occasionally provides reduced fare tickets for official '
          'travel. After refugee status: full access to all social tariffs. Cannot exchange '
          'license during asylum procedure (need titre de séjour).',
      drivingAuthority: 'Ministère de la Transition Écologique - Délégation à la Sécurité Routière',
      authorityWebsite: 'https://permisdeconduire.ants.gouv.fr',
      legalBasis: 'Code de la route Art. L223-1 to L224-18, Arrêté du 12 janvier 2012',
      immigrantSpecificNotes:
          'France is MODERATE. Extensive bilateral agreements with Francophone Africa and former '
          'colonies mean many immigrants can exchange directly. ANTS online system is modern but '
          'processing times are extremely long (6-18 months). Unlimited insurance liability '
          'makes coverage important. Criminal penalties for unlicensed driving are severe. '
          'Paris public transport social tariffs are excellent for low-income residents. French '
          'or English for theory test. The sworn translation requirement adds cost.',
      strictnessRating: 'moderate',
    ),

    // ============================================================
    // 11. GERMANY
    // ============================================================
    TransportationRights(
      country: 'Germany',
      countryCode: 'DE',
      foreignLicenseAccepted: true,
      foreignLicenseValidMonths: 6,
      foreignLicenseConditions:
          'Third-country licenses valid for 6 months from establishing residence (Anmeldung '
          'at Einwohnermeldeamt). Must be accompanied by certified German translation from ADAC '
          'or sworn translator, OR IDP. After 6 months: license loses validity COMPLETELY. No '
          'extension possible (except individual hardship cases via Straßenverkehrsamt). EEA '
          'licenses: valid without restriction or time limit. EU Directive 2006/126 fully '
          'implemented.',
      conversionProcess:
          'Apply at Führerscheinstelle (driving license office) of residence. Documents: '
          'application form, foreign license + certified translation, Meldebescheinigung '
          '(residence registration), Aufenthaltstitel (residence permit), Sehtest (eye test '
          '~EUR 7), Erste-Hilfe-Kurs certificate (first aid, ~EUR 30), biometric photos. '
          'Annex 11 countries (bilateral agreements): exchange without test. Annex 11 with '
          'theory only: theory test required. All others (most countries): BOTH theory and '
          'practical tests. Theory: computer-based, touch screen. Process takes 4-8 weeks.',
      conversionCostEuros: '35-2,500 (exchange fee ~EUR 35-45 + translation ~EUR 30-80 + '
          'eye test EUR 7 + first aid EUR 30 + driving school if needed: theory ~EUR 200-400, '
          'practical lessons ~EUR 1,000-2,000 + tests EUR 90-130)',
      theoryTestRequired: true,
      practicalTestRequired: true,
      theoryTestLanguages: [
        'German',
        'English',
        'French',
        'Greek',
        'Italian',
        'Polish',
        'Portuguese',
        'Romanian',
        'Russian',
        'Croatian',
        'Spanish',
        'Turkish',
        'Arabic',
        'Hocharabisch (Modern Standard Arabic)',
      ],
      mutualRecognitionCountries: [
        'Annex 11 (full exchange): Japan, South Korea, Taiwan, Singapore, '
            'Israel, South Africa, Andorra, Guernsey, Isle of Man, Jersey, '
            'Monaco, New Zealand, San Marino, Switzerland, Quebec (Canada), '
            'United Kingdom, certain US states and Canadian provinces',
        'Annex 11 (theory test only): varies by specific state agreement',
        'All EEA countries (full recognition)',
      ],
      idpRules:
          'IDP valid for tourists (up to 6 months). MUST accompany original license. Only '
          'Vienna Convention (1968) IDP officially accepted. Geneva Convention IDP tolerated '
          'but not legally required to be accepted. IDP alone is NOT a driving license. For '
          'residents: IDP does not extend the 6-month period.',
      policeStopConsequences:
          'Driving without valid license (Fahren ohne Fahrerlaubnis): CRIMINAL OFFENSE under '
          '§21 StVG. Penalty: fine or up to 1 year imprisonment. In practice: Geldstrafe '
          '(monetary penalty) of 20-40 Tagessätze (day-rates based on income). Vehicle may be '
          'impounded. Strafregistereintrag (criminal record). Can seriously affect '
          'Aufenthaltserlaubnis (residence permit) renewal. Insurance void for damage claims.',
      insuranceRequirements:
          'Mandatory third-party liability (Kfz-Haftpflichtversicherung). Minimum: EUR 7.5 '
          'million personal injury, EUR 1.12 million property, EUR 50,000 financial loss. '
          'Insurance costs: EUR 300-1,000/year. Schadenfreiheitsklasse (no-claims class) '
          'system. Foreign NCB rarely accepted (some insurers accept from Switzerland, '
          'Austria). GDV (Gesamtverband der Deutschen Versicherungswirtschaft) oversees. '
          'eVB number required for registration.',
      publicTransportDiscounts:
          'Deutschlandticket (D-Ticket): EUR 49/month for ALL local and regional public '
          'transport nationwide (since May 2023, revolutionary for Germany). Sozialticket: '
          'many cities offer EUR 39 or lower for social benefit recipients (ALG II/Bürgergeld). '
          'Berlin: Berlinpass holders EUR 9/month. Students: Semesterticket ~EUR 100-200/semester '
          'including Deutschlandticket. Schülerticket: free or reduced for school children.',
      asylumSeekerTransportRights:
          'Asylum seekers receive Asylbewerberleistungen (AsylbLG): EUR 460/month (single adult, '
          '2024) from which transport must be funded. In initial reception (Erstaufnahme): food '
          'and shelter provided, reduced cash. Many Landkreise provide Sozialticket or transport '
          'vouchers. Some Bundesländer provide free Deutschlandticket for asylum seekers '
          '(Berlin piloted this). Transport to BAMF interviews: travel costs reimbursed. After '
          'Anerkennung (recognition): Bürgergeld eligibility includes Deutschlandticket subsidy. '
          'Cannot convert license during asylum procedure. Recognized refugees with '
          'Aufenthaltserlaubnis can convert normally.',
      drivingAuthority: 'Kraftfahrt-Bundesamt (KBA) / Local Führerscheinstelle',
      authorityWebsite: 'https://www.kba.de',
      legalBasis: 'Fahrerlaubnis-Verordnung (FeV) §28-§31, Anlage 11',
      immigrantSpecificNotes:
          'Germany is STRICT. The 6-month window is absolute with almost no exceptions. Most '
          'third-country nationals must take both tests. Theory test available in 14 languages '
          '(most in EU). Driving school costs are among Europe\'s highest (EUR 1,500-3,000 for '
          'full course). CRIMINAL offense for driving without license (not just administrative). '
          'However, the Deutschlandticket (EUR 49/month) revolution has massively improved '
          'public transport accessibility. Annex 11 agreements cover many developed countries. '
          'The ADAC translation service is efficient (~EUR 30-60). Ukrainian refugees received '
          'temporary driving recognition until 2025.',
      strictnessRating: 'strict',
    ),

    // ============================================================
    // 12. GREECE
    // ============================================================
    TransportationRights(
      country: 'Greece',
      countryCode: 'GR',
      foreignLicenseAccepted: true,
      foreignLicenseValidMonths: 6,
      foreignLicenseConditions:
          'Third-country licenses valid for 6 months from establishing residence. Must conform '
          'to Vienna Convention or be accompanied by IDP or certified Greek translation. Some '
          'licenses from non-Convention countries may not be recognized. After 6 months, '
          'Greek license required. EEA licenses valid until expiry.',
      conversionProcess:
          'Apply at Directorate of Transport (Διεύθυνση Μεταφορών) of regional prefecture. '
          'Documents: application, foreign license, passport, residence permit (minimum 185 days '
          'residence), medical certificates (from pathologist and ophthalmologist, ~EUR 50 total), '
          '4 passport photos, AFM (tax number), sworn translation of license. Most third-country '
          'licenses: theory and practical test. Some bilateral agreements allow direct exchange.',
      conversionCostEuros: '100-700 (administrative fees ~EUR 90 + medical ~EUR 50 + translation '
          '~EUR 30 + driving school if needed ~EUR 300-500)',
      theoryTestRequired: true,
      practicalTestRequired: true,
      theoryTestLanguages: ['Greek', 'English', 'Albanian (in some regions)'],
      mutualRecognitionCountries: [
        'Albania',
        'Ukraine',
        'Egypt',
        'Morocco',
        'South Korea',
        'Japan',
        'All EEA countries',
      ],
      idpRules:
          'IDP accepted for tourists. Both Vienna and Geneva IDPs recognized. Must accompany '
          'original license. Very useful in Greece as many licenses are in non-Latin scripts. '
          'Police commonly check for IDP in tourist areas.',
      policeStopConsequences:
          'Driving without valid license: fine EUR 200-2,000. Court appearance may be required. '
          'Vehicle impoundment for 10-30 days. License plates confiscated (Greek system of '
          'plate removal as penalty). Insurance void. Second offense: higher fines + possible '
          'criminal charges.',
      insuranceRequirements:
          'Mandatory third-party liability (ασφάλεια αυτοκινήτου τρίτων). Minimum coverage: '
          'EUR 1.22 million per victim, EUR 1.22 million property per incident. Insurance '
          'relatively affordable: EUR 200-500/year. Motor Insurance Bureau of Greece (EPIK) '
          'oversees. Green Card system applies.',
      publicTransportDiscounts:
          'OASA (Athens): monthly pass EUR 30 (all modes including metro, bus, tram, suburban '
          'rail). Students: 50% discount. Unemployed: free 12-month pass with OAED registration. '
          'Large families: 50% reduction. Disabled persons: free transport. No specific asylum '
          'seeker transport scheme but unemployment card (if eligible) provides free transport.',
      asylumSeekerTransportRights:
          'Asylum seekers in ESTIA/HELIOS accommodation or RIC/CCAC camps receive: monthly '
          'cash assistance via prepaid card (EUR 150/month single adult in accommodation, '
          'EUR 280 if not accommodated). Must fund transport from this. UNHCR and NGOs '
          '(IRC, Metadrasi, ASB) provide transport to interviews and appointments on islands '
          'and mainland. Island camps (Lesbos, Samos, Chios, Kos, Leros) have very limited '
          'public transport. Mainland Athens reception: OASA pass purchasable. After recognition: '
          'HELIOS integration program includes transport support for 12 months.',
      drivingAuthority: 'Υπουργείο Υποδομών και Μεταφορών (Ministry of Infrastructure & Transport)',
      authorityWebsite: 'https://www.yme.gr',
      legalBasis: 'Κώδικας Οδικής Κυκλοφορίας (Road Traffic Code) N. 2696/1999, Art. 92-99',
      immigrantSpecificNotes:
          'Greece is MODERATE. Albanian license recognition is important given the large '
          'Albanian immigrant community. Theory test in Albanian available in some areas. '
          'Bureaucracy can be slow (months for appointments). Island refugees face particular '
          'transport challenges. Athens public transport is affordable. Greek bureaucratic '
          'culture means the process often takes longer than the legal timeline suggests. '
          'Driving culture is more relaxed than Northern Europe regarding enforcement.',
      strictnessRating: 'moderate',
    ),

    // ============================================================
    // 13. HUNGARY
    // ============================================================
    TransportationRights(
      country: 'Hungary',
      countryCode: 'HU',
      foreignLicenseAccepted: true,
      foreignLicenseValidMonths: 12,
      foreignLicenseConditions:
          'Third-country licenses valid for 12 months from establishing residence. License must '
          'conform to Vienna Convention or be accompanied by certified Hungarian translation/IDP. '
          'After 12 months, Hungarian license required. Extension possible in individual cases. '
          'EEA licenses recognized until expiry.',
      conversionProcess:
          'Apply at Kormányablak (government window/office). Documents: application, foreign '
          'license, passport, residence permit, medical certificate from occupational health '
          'physician (~EUR 15-25), 1 photo, certified translation. Vienna Convention countries: '
          'exchange without test if license has photo. Non-Vienna Convention: theory and '
          'practical test. Process relatively straightforward. Old license returned with '
          'invalidation mark.',
      conversionCostEuros: '20-400 (administrative fee ~EUR 10-20 + medical ~EUR 20 + '
          'translation ~EUR 15 + driving school if needed ~EUR 200-350)',
      theoryTestRequired: true,
      practicalTestRequired: true,
      theoryTestLanguages: ['Hungarian', 'English', 'German'],
      mutualRecognitionCountries: [
        'Serbia',
        'Ukraine',
        'Japan',
        'South Korea',
        'All Vienna Convention countries (with conditions)',
        'All EEA countries',
      ],
      idpRules:
          'IDP accepted for tourists (up to 1 year). Both Vienna and Geneva IDPs recognized. '
          'Must accompany original license. For residents, IDP serves as translation during '
          'grace period only.',
      policeStopConsequences:
          'Driving without valid license: fine HUF 30,000-300,000 (~EUR 75-750). Vehicle may '
          'be stopped from further use. Repeated offense: criminal misdemeanor possible. Points '
          'system: unlicensed driving carries high points (18 points = ban). Police may be '
          'pragmatic for first-time minor violations.',
      insuranceRequirements:
          'Mandatory third-party liability (kötelező gépjármű-felelősségbiztosítás, KGFB). '
          'Minimum: EUR 6.45 million personal injury, EUR 1.3 million property per incident. '
          'Very affordable by EU standards: EUR 50-200/year. MABISZ (Hungarian Insurance '
          'Association) oversees. Online comparison straightforward.',
      publicTransportDiscounts:
          'BKK (Budapest): monthly pass HUF 9,500 (~EUR 24). Students: 50% discount. '
          'Seniors (65+): free nationwide. Pensioners: reduced rates. Social assistance '
          'recipients: Budapest Szociális Bérlet (social pass) at reduced rates. No specific '
          'asylum seeker transport program but overall very affordable.',
      asylumSeekerTransportRights:
          'Hungary\'s asylum system has been severely restricted since 2020 (border procedure '
          'only, embassy procedure requirement). Those in the system receive minimal support. '
          'Transit zones were closed (CJEU ruling 2020). Recognized refugees: eligible for '
          'integration support for 2 months including housing, no specific transport. Very '
          'limited NGO presence for transport assistance. Ukrainian refugees (2022+): temporary '
          'protection with work rights. Cannot convert license during any asylum procedure.',
      drivingAuthority: 'Innovációs és Technológiai Minisztérium (Ministry of Innovation)',
      authorityWebsite: 'https://www.kormany.hu/en/ministry-of-innovation-and-technology',
      legalBasis: 'közúti közlekedésről szóló 1988. évi I. törvény (Road Traffic Act), §15-§18',
      immigrantSpecificNotes:
          'Hungary is LENIENT. The 12-month grace period is generous and costs are among the '
          'lowest in the EU. Budapest public transport is extremely affordable. However, '
          'Hungary\'s restrictive asylum policy means few asylum seekers access the system. '
          'For regular immigrants (work/family permits), the process is straightforward and '
          'cheap. Hungarian language is a major barrier for the theory test. Serbian and '
          'Ukrainian recognition reflects border relations.',
      strictnessRating: 'lenient',
    ),

    // ============================================================
    // 14. IRELAND
    // ============================================================
    TransportationRights(
      country: 'Ireland',
      countryCode: 'IE',
      foreignLicenseAccepted: true,
      foreignLicenseValidMonths: 12,
      foreignLicenseConditions:
          'Third-country licenses (recognized/exchangeable countries) valid for 12 months from '
          'establishing normal residence. Other third-country licenses: valid for 1 month only. '
          'Must be valid and in English or accompanied by IDP/certified translation. After '
          'grace period, Irish learner permit/full license required. NOTE: Ireland drives on '
          'the LEFT. EEA licenses valid until expiry.',
      conversionProcess:
          'Apply at NDLS (National Driver Licence Service) center. Documents: application form '
          '(D401), foreign license, proof of PPS number, proof of address, proof of identity, '
          'eyesight report (from optician, ~EUR 25). Recognized exchange countries: direct '
          'exchange (no test). Non-recognized countries: must start from scratch with learner '
          'permit (EUR 35), mandatory 12 Essential Driver Training (EDT) lessons (EUR 400-600), '
          'theory test (EUR 45), and practical test (EUR 85). This takes minimum 6 months.',
      conversionCostEuros: '55-1,200 (exchange fee EUR 55 + eye test ~EUR 25 + full training '
          'if needed: learner permit EUR 35 + EDT EUR 400-600 + theory EUR 45 + practical EUR 85)',
      theoryTestRequired: true,
      practicalTestRequired: true,
      theoryTestLanguages: [
        'English',
        'Irish (Gaeilge)',
        'Polish (via voiceover)',
        'Portuguese (via voiceover)',
        'Lithuanian (via voiceover)',
      ],
      mutualRecognitionCountries: [
        'Australia',
        'Canada (some provinces)',
        'Gibraltar',
        'Guernsey',
        'Isle of Man',
        'Japan',
        'Jersey',
        'New Zealand',
        'South Africa',
        'South Korea',
        'Switzerland',
        'Taiwan',
        'United Kingdom (recognized country)',
        'All EEA countries',
      ],
      idpRules:
          'IDP accepted for tourists and visitors. Must accompany original license. Useful for '
          'left-hand driving countries. Police will check original license validity. IDP does '
          'not extend residential grace periods.',
      policeStopConsequences:
          'Driving without valid license: fine up to EUR 2,000 and/or up to 6 months '
          'imprisonment on summary conviction. Fixed penalty notice: EUR 500 (if paid within '
          '28 days). Penalty points: 5 points on conviction (12 points = 6-month ban). Vehicle '
          'may be seized under Section 41 of Road Traffic Act. Insurance void.',
      insuranceRequirements:
          'Mandatory third-party liability. Ireland has among the HIGHEST insurance costs in '
          'the EU: EUR 800-2,500/year. MIBI (Motor Insurers\' Bureau of Ireland) handles claims '
          'against uninsured drivers. No mandatory minimum specified by law (unlimited for '
          'personal injury). Significant insurance inflation in recent years. Foreign no-claims '
          'rarely accepted. Named driver policy common.',
      publicTransportDiscounts:
          'Leap Card: discounted fares on Dublin Bus, Luas, DART (20-30% off cash fare). '
          'Student Leap Card: additional discount. Free Travel Pass: for social welfare '
          'recipients over 66, disabled, carers. TFI 90-minute fare cap: EUR 2 (adult), '
          'EUR 1 (student/child). Young Adult Card (19-25): 50% discount. No specific '
          'immigrant/asylum seeker fare but low-income social welfare recipients may qualify '
          'for various schemes.',
      asylumSeekerTransportRights:
          'Asylum seekers in IPAS (International Protection Accommodation Services, formerly '
          'Direct Provision) receive: weekly allowance EUR 38.80/adult + accommodation. '
          'Transport to IPO (International Protection Office) interviews: travel costs '
          'reimbursed. Some centers provide local transport vouchers. Centers often in rural '
          'locations with limited public transport (Mosney, Knockalisheen, etc.). Right to '
          'work after 6 months. NGOs (MASI, Irish Refugee Council, Nasc) provide some transport '
          'support. Cannot exchange license during protection process. After status: full access.',
      drivingAuthority: 'Road Safety Authority (RSA) / NDLS',
      authorityWebsite: 'https://www.ndls.ie',
      legalBasis: 'Road Traffic Act 1961 (as amended), Road Traffic (Licensing of Drivers) '
          'Regulations 2006 (S.I. 537/2006)',
      immigrantSpecificNotes:
          'Ireland is MODERATE but EXPENSIVE. Good bilateral recognition with Anglophone and '
          'Commonwealth countries. Non-recognized countries face starting from scratch (minimum '
          '6 months). Insurance costs are among Europe\'s highest and a major financial barrier. '
          'Left-hand driving is an adjustment. Polish and Portuguese theory test voiceovers '
          'reflect the two largest immigrant communities. Rural asylum seeker centers highlight '
          'the transport poverty issue. The Leap Card 90-minute fare cap (EUR 2) is among the '
          'cheapest urban transport in Western Europe.',
      strictnessRating: 'moderate',
    ),

    // ============================================================
    // 15. ITALY
    // ============================================================
    TransportationRights(
      country: 'Italy',
      countryCode: 'IT',
      foreignLicenseAccepted: true,
      foreignLicenseValidMonths: 12,
      foreignLicenseConditions:
          'Third-country licenses valid for 12 months from establishing residence '
          '(residenza anagrafica). Must be accompanied by IDP or certified Italian translation '
          '(traduzione giurata). After 12 months, conversion or new Italian license required. '
          'License must be valid and not already exchanged in another country. EEA licenses '
          'valid until expiry (but must be converted on renewal).',
      conversionProcess:
          'Apply at Motorizzazione Civile (MCTC) or through autoscuola (driving school as '
          'intermediary). Documents: application form (MOD. TT 2112), foreign license + '
          'certified translation by Italian consular authority or sworn translator, codice '
          'fiscale, permesso di soggiorno, medical certificate from ASL or authorized physician '
          '(~EUR 50), marca da bollo (revenue stamps ~EUR 32), 3 photos. Countries with '
          'bilateral agreement: direct exchange. Others: theory and practical test. Italian '
          'bureaucracy means process can take 3-12 months.',
      conversionCostEuros: '80-1,500 (stamps + fees ~EUR 80-100 + medical ~EUR 50 + translation '
          '~EUR 30-80 + driving school if needed ~EUR 500-1,200)',
      theoryTestRequired: true,
      practicalTestRequired: true,
      theoryTestLanguages: [
        'Italian',
        'French (Valle d\'Aosta)',
        'German (South Tyrol)',
        'Slovenian (Friuli Venezia Giulia border areas)',
      ],
      mutualRecognitionCountries: [
        'Algeria',
        'Argentina',
        'Brazil (partial)',
        'El Salvador',
        'South Korea',
        'Japan',
        'Lebanon',
        'Moldova',
        'Morocco',
        'Philippines',
        'Taiwan',
        'Tunisia',
        'Turkey',
        'Ukraine',
        'Uruguay',
        'All EEA countries',
      ],
      idpRules:
          'IDP accepted for tourists (up to 12 months). Both Vienna and Geneva IDPs recognized. '
          'Must accompany original license. Italy is a party to both conventions. IDP serves '
          'as official translation for police checks.',
      policeStopConsequences:
          'Driving without valid license: fine EUR 2,257-9,032 (Art. 116 Codice della Strada). '
          'Vehicle seized for 3 months (Fermo amministrativo). In aggravated cases (repeat '
          'offense, accident): criminal charges possible. Police may issue immediate prohibition '
          'from driving. Very high fines by EU standards.',
      insuranceRequirements:
          'Mandatory third-party liability (RCA - Responsabilità Civile Autoveicoli). Minimum: '
          'EUR 6.45 million personal injury, EUR 1.3 million property per incident. Insurance '
          'costs vary dramatically by region: EUR 200-300 in northern Italy, EUR 500-1,500+ in '
          'Naples/southern Italy. Attestato di rischio (risk certificate) determines bonus-malus '
          'class. Foreign history rarely accepted. CONSAP oversees guarantee fund.',
      publicTransportDiscounts:
          'ATAC (Rome): monthly pass EUR 35 (all zones). ATM (Milan): monthly EUR 39. Annual '
          'passes often cheaper per month. Students: discounts vary by city (typically 30-50%). '
          'Over 70: free in Rome. Carta Tutto Treno: rail discounts. ISEE-based social '
          'tariffs in many cities (ISEE < EUR 6,500 threshold for maximum discount). Bonus '
          'trasporti: EUR 60 voucher for annual passes (income < EUR 20,000, introduced 2023).',
      asylumSeekerTransportRights:
          'Asylum seekers in SAI (formerly SPRAR/SIPROIMI) or CAS (emergency reception centers) '
          'receive: daily pocket money EUR 2.50 (in center) or EUR 5.00 (if meals not provided). '
          'Transport to Commissione Territoriale hearings: arranged by center or reimbursed. '
          'Some municipalities provide local transport passes for SAI beneficiaries. CAS centers '
          'often in remote locations. NGOs (ARCI, Caritas, CIR) provide transport assistance. '
          'After recognition: eligible for ISEE-based social tariffs. Integration program '
          'may include transport support.',
      drivingAuthority: 'Ministero delle Infrastrutture e dei Trasporti - Motorizzazione Civile',
      authorityWebsite: 'https://www.mit.gov.it/come-fare-per/motorizzazione',
      legalBasis: 'Codice della Strada (D.Lgs. 285/1992), Art. 116-136; DPR 495/1992',
      immigrantSpecificNotes:
          'Italy is MODERATE. Extensive bilateral agreements, especially with South American '
          'and Mediterranean countries, reflecting Italy\'s diaspora and immigration patterns. '
          'Italian-only theory test is a barrier (minority language exceptions only for '
          'historical linguistic minorities). Very high fines for unlicensed driving. Insurance '
          'costs in southern Italy are problematic. Bureaucratic delays are significant. The '
          'marca da bollo (revenue stamp) system adds to costs. Public transport in major '
          'cities is affordable but service quality varies.',
      strictnessRating: 'moderate',
    ),

    // ============================================================
    // 16. LATVIA
    // ============================================================
    TransportationRights(
      country: 'Latvia',
      countryCode: 'LV',
      foreignLicenseAccepted: true,
      foreignLicenseValidMonths: 12,
      foreignLicenseConditions:
          'Third-country licenses valid for 12 months from establishing residence or for the '
          'duration of a temporary residence permit (whichever is shorter). Must be valid and '
          'conform to Vienna Convention or accompanied by certified translation/IDP. After '
          'grace period, Latvian license required. EEA licenses valid until expiry.',
      conversionProcess:
          'Apply at CSDD (Road Traffic Safety Directorate) office. Documents: application, '
          'foreign license + certified translation (if not in Latvian/English/Russian), '
          'passport, residence permit, medical certificate (~EUR 15-25), 1 photo. Vienna '
          'Convention compliant licenses with photo: exchange possible with theory test only. '
          'Others: theory + practical test. CSDD process is digital-friendly.',
      conversionCostEuros: '30-500 (exchange fee ~EUR 28 + medical ~EUR 20 + translation ~EUR 15 '
          '+ tests/lessons if needed ~EUR 200-400)',
      theoryTestRequired: true,
      practicalTestRequired: true,
      theoryTestLanguages: ['Latvian', 'Russian', 'English'],
      mutualRecognitionCountries: [
        'Ukraine',
        'Russia (suspended)',
        'Belarus (suspended)',
        'Georgia',
        'All Vienna Convention signatories (with conditions)',
        'All EEA countries',
      ],
      idpRules:
          'IDP accepted for tourists. Vienna Convention IDP preferred. Must accompany original '
          'license. Useful for residents during grace period as supplementary translation.',
      policeStopConsequences:
          'Driving without valid license: fine EUR 280-700. Vehicle use prohibition. Repeated '
          'offense: criminal liability under Criminal Law Section 262 (up to 2 years '
          'imprisonment). Points system: 1-4 points depending on circumstances.',
      insuranceRequirements:
          'Mandatory third-party liability (OCTA). Minimum: EUR 5.6 million personal injury, '
          'EUR 1.12 million property. Very affordable: EUR 50-200/year. LTAB (Latvian Motor '
          'Insurers\' Bureau) oversees. Online purchase available. e-policy system.',
      publicTransportDiscounts:
          'Rīgas Satiksme (Riga): monthly e-ticket EUR 30 (all routes). Students: 50% discount. '
          'Seniors (70+): free in Riga. Disabled: free. Pupils: free in Riga. Low-income: '
          'social assistance recipients eligible for reduced rates via municipal social service. '
          'Rail (Pasažieru vilciens): student and senior discounts. Intercity buses affordable.',
      asylumSeekerTransportRights:
          'Asylum seekers in Mucenieki reception center receive: accommodation + daily allowance '
          'EUR 3/day. Transport to OCMA (Office of Citizenship and Migration Affairs) '
          'interviews arranged by center. Limited public transport near Mucenieki. NGOs '
          '(Latvian Red Cross, Gribu palīdzēt bēgļiem) provide some transport. After '
          'recognition: integration program (1 year) may include transport costs. Cannot '
          'convert license during procedure.',
      drivingAuthority: 'CSDD (Ceļu satiksmes drošības direkcija)',
      authorityWebsite: 'https://www.csdd.lv',
      legalBasis: 'Ceļu satiksmes likums (Road Traffic Law), Section 20-29',
      immigrantSpecificNotes:
          'Latvia is MODERATE to LENIENT. The 12-month grace period is generous. Russian '
          'language availability for theory test is crucial given the large Russian-speaking '
          'population (~25% of residents). Low costs overall. CSDD is reasonably efficient. '
          'Suspension of Russian/Belarusian bilateral agreements since 2022 affects some '
          'immigrants. Small country with concentrated urban transport in Riga.',
      strictnessRating: 'moderate',
    ),

    // ============================================================
    // 17. LITHUANIA
    // ============================================================
    TransportationRights(
      country: 'Lithuania',
      countryCode: 'LT',
      foreignLicenseAccepted: true,
      foreignLicenseValidMonths: 6,
      foreignLicenseConditions:
          'Third-country licenses valid for 6 months from establishing residence. Must be '
          'valid, conform to Vienna Convention or accompanied by certified translation/IDP. '
          'License must include photograph. After 6 months, Lithuanian license required. '
          'EEA licenses valid until expiry.',
      conversionProcess:
          'Apply at Regitra (state enterprise for registration). Documents: application, '
          'foreign license, passport, residence permit, medical certificate from authorized '
          'physician (~EUR 15-20), 1 photo. Vienna Convention licenses with photo: theory test '
          'only. Others: theory + practical test. Regitra offers online booking for tests. '
          'Process takes 2-4 weeks typically.',
      conversionCostEuros: '25-500 (Regitra fee ~EUR 20-30 + medical ~EUR 18 + translation '
          '~EUR 15 + tests/lessons if needed ~EUR 200-400)',
      theoryTestRequired: true,
      practicalTestRequired: true,
      theoryTestLanguages: ['Lithuanian', 'English', 'Russian'],
      mutualRecognitionCountries: [
        'Ukraine',
        'Belarus (suspended)',
        'Russia (suspended)',
        'Georgia',
        'Japan',
        'South Korea',
        'All EEA countries',
      ],
      idpRules:
          'IDP accepted for tourists. Vienna Convention IDP recognized. Must accompany original. '
          'Geneva IDP accepted with discretion. Not valid for residents after grace period.',
      policeStopConsequences:
          'Driving without valid license: fine EUR 300-850. Vehicle prohibition. Repeated '
          'violation: criminal offense under Art. 2811 Criminal Code (community service, '
          'fine, restriction of liberty, or up to 1 year arrest). License plate removal possible.',
      insuranceRequirements:
          'Mandatory third-party liability (TPVCA). Minimum: EUR 5.6 million personal injury, '
          'EUR 1.12 million property. Affordable: EUR 80-250/year. LB (Lithuanian Insurance '
          'Bureau) oversees. Mandatory e-insurance since 2014.',
      publicTransportDiscounts:
          'Vilniaus viešasis transportas (Vilnius): monthly e-ticket EUR 29. Students: 50% '
          'discount. Seniors (70+): free in Vilnius. Disabled: free. Social assistance '
          'recipients: reduced fares via municipal social department. Kaunas, Klaipeda: similar '
          'systems. Lithuanian Railways: student discounts. Overall very affordable.',
      asylumSeekerTransportRights:
          'Asylum seekers in Rukla Refugee Reception Centre or Naujininkai (Vilnius) receive: '
          'accommodation + monthly allowance EUR 102/month (basic). Transport to Migration '
          'Department interviews arranged by center. 2021-2022 Belarus border crisis led to '
          'expanded reception. NGOs (Lithuanian Red Cross, Caritas) provide transport support. '
          'After recognition: integration support (12 months) includes housing assistance, '
          'language courses, transport not specifically provided. Cannot convert license during '
          'procedure.',
      drivingAuthority: 'Regitra (VĮ Regitra) / Susisiekimo ministerija',
      authorityWebsite: 'https://www.regitra.lt',
      legalBasis: 'Kelių eismo taisyklių įstatymas (Road Traffic Rules), Saugaus eismo '
          'automobilių keliais įstatymas',
      immigrantSpecificNotes:
          'Lithuania is MODERATE. The 6-month period is standard. Russian language test '
          'availability is important. Low costs by EU standards. The 2021-2022 Belarus border '
          'crisis significantly impacted the asylum system. Good digital infrastructure at '
          'Regitra. Small country where public transport is concentrated in three main cities '
          '(Vilnius, Kaunas, Klaipeda). Rural areas require driving.',
      strictnessRating: 'moderate',
    ),

    // ============================================================
    // 18. LUXEMBOURG
    // ============================================================
    TransportationRights(
      country: 'Luxembourg',
      countryCode: 'LU',
      foreignLicenseAccepted: true,
      foreignLicenseValidMonths: 12,
      foreignLicenseConditions:
          'Third-country licenses valid for 12 months from establishing residence. Must be '
          'valid, in Roman script or accompanied by certified translation/IDP. After 12 months, '
          'Luxembourg license required. First 12 months: must carry original license + passport '
          '+ residence proof at all times. EEA licenses valid until expiry.',
      conversionProcess:
          'Apply at SNCA (Société Nationale de Circulation Automobile). Documents: application, '
          'foreign license + certified translation, passport, residence certificate from commune, '
          'medical certificate (~EUR 50), 2 photos. Countries with bilateral agreement: direct '
          'exchange. Others: theory test (multimedia, scenario-based) + practical test. '
          'Luxembourg test is considered demanding. Old license surrendered.',
      conversionCostEuros: '50-2,000 (SNCA fee ~EUR 50 + medical ~EUR 50 + translation ~EUR 25 '
          '+ driving school if needed: theory ~EUR 300-500, practical ~EUR 1,000-1,500)',
      theoryTestRequired: true,
      practicalTestRequired: true,
      theoryTestLanguages: ['French', 'German', 'Luxembourgish', 'English', 'Portuguese'],
      mutualRecognitionCountries: [
        'Switzerland',
        'Japan',
        'South Korea',
        'Taiwan',
        'Cape Verde',
        'Brazil (partial)',
        'All EEA countries',
      ],
      idpRules:
          'IDP accepted for tourists. Vienna Convention (1968) IDP officially recognized. '
          'Must accompany original license. Luxembourg is geographically tiny - transit to '
          'neighboring countries (France, Belgium, Germany) common and IDP useful there too.',
      policeStopConsequences:
          'Driving without valid license: fine EUR 500-10,000 and/or imprisonment 8 days to '
          '3 years (Art. 12 of Code de la Route). Vehicle immobilization possible. Luxembourg '
          'has strict enforcement with frequent police checks near borders.',
      insuranceRequirements:
          'Mandatory third-party liability. Minimum: EUR 100 million combined (among highest '
          'in EU). Insurance costs: EUR 500-1,200/year. Luxembourg insurance market is '
          'concentrated. ACA (Association des Compagnies d\'Assurances) oversees. Some '
          'cross-border policies available (many residents commute to France/Belgium/Germany).',
      publicTransportDiscounts:
          'FREE PUBLIC TRANSPORT for everyone since March 2020. All buses, trams, and trains '
          '(2nd class) within Luxembourg are completely free. No ticket needed on domestic '
          'routes. First country in the world to make all public transport free. Cross-border '
          'trains: free within Luxembourg, ticket needed for the foreign portion. This benefits '
          'ALL residents including immigrants and asylum seekers equally.',
      asylumSeekerTransportRights:
          'Asylum seekers in ONA (Office National de l\'Accueil) structures receive: '
          'accommodation + monthly allowance EUR 25/month (adults in center). Public transport '
          'is FREE for everyone so transport is not a barrier in Luxembourg. Transport to OLAI '
          '(Office luxembourgeois de l\'accueil et de l\'intégration) interviews covered. '
          'Small country means most locations are accessible by free bus/train. After '
          'recognition: same rights, still free transport. Cannot convert license during '
          'procedure. Among the best situations in the EU for asylum seeker mobility.',
      drivingAuthority: 'SNCA (Société Nationale de Circulation Automobile)',
      authorityWebsite: 'https://snca.lu',
      legalBasis: 'Code de la Route, Règlement grand-ducal du 23 novembre 1955 (as amended)',
      immigrantSpecificNotes:
          'Luxembourg is MODERATE for license conversion but EXCEPTIONAL for public transport '
          '(free for all). Portuguese is available for theory test, reflecting Luxembourg\'s '
          'largest immigrant community (~16% of population). Multilingual administration '
          '(French, German, Luxembourgish, English, Portuguese) is very immigrant-friendly. '
          'Free public transport since 2020 eliminates transport poverty entirely. High '
          'insurance costs reflect high-income economy. Cross-border commuters (200,000+ daily) '
          'mean driving is important for work despite small country size.',
      strictnessRating: 'moderate',
    ),

    // ============================================================
    // 19. MALTA
    // ============================================================
    TransportationRights(
      country: 'Malta',
      countryCode: 'MT',
      foreignLicenseAccepted: true,
      foreignLicenseValidMonths: 12,
      foreignLicenseConditions:
          'Third-country licenses valid for 12 months from establishing residence. Must be '
          'valid and in English or accompanied by certified translation/IDP. After 12 months, '
          'Maltese license required. NOTE: Malta drives on the LEFT (former British colony). '
          'EEA licenses valid until expiry.',
      conversionProcess:
          'Apply at Transport Malta (Land Transport Directorate). Documents: application form '
          '(VEH 06), foreign license + certified translation if not in English, passport, '
          'residence permit, medical certificate (from family doctor, ~EUR 20), ID photo. '
          'Commonwealth and select countries: direct exchange. Others: theory and practical '
          'test (left-hand driving). Process relatively fast in Malta (2-4 weeks).',
      conversionCostEuros: '40-800 (exchange fee ~EUR 40 + medical ~EUR 20 + driving school if '
          'needed for left-hand driving ~EUR 300-700)',
      theoryTestRequired: true,
      practicalTestRequired: true,
      theoryTestLanguages: ['English', 'Maltese'],
      mutualRecognitionCountries: [
        'Australia',
        'Canada',
        'Japan',
        'New Zealand',
        'South Africa',
        'South Korea',
        'Singapore',
        'United Kingdom',
        'Switzerland',
        'All EEA countries',
      ],
      idpRules:
          'IDP accepted for tourists. Both Vienna and Geneva IDPs recognized. Must accompany '
          'original license. Very useful as English is co-official language.',
      policeStopConsequences:
          'Driving without valid license: fine EUR 250-1,500. Court proceedings for serious '
          'cases. Vehicle impoundment possible. Malta is small with active police enforcement '
          'in tourist areas. Insurance void.',
      insuranceRequirements:
          'Mandatory third-party liability. Minimum: EUR 1.12 million per victim, EUR 1.12 '
          'million property. Insurance costs: EUR 300-700/year. Malta Insurance Association '
          'oversees. Small market with limited competition. Left-hand driving experience '
          'may affect premium.',
      publicTransportDiscounts:
          'Malta Public Transport (Tallinja): single journey EUR 1.50 (winter) / EUR 2.00 '
          '(summer), 12-journey card EUR 15. Tallinja Card (monthly): EUR 26. Students: '
          'explore card EUR 21. Seniors (60+): free bus travel with Tallinja 60+ card. '
          'Social assistance beneficiaries: free Tallinja card available. Ferry to Gozo: '
          'residents have reduced fares.',
      asylumSeekerTransportRights:
          'Asylum seekers in Ħal Far or Marsa open centers receive: accommodation + daily '
          'allowance EUR 4.66/day (single adult). Transport on Malta\'s small island is '
          'primarily by bus. Some asylum seekers receive Tallinja cards from AWAS (Agency for '
          'the Welfare of Asylum Seekers). NGOs (JRS Malta, Aditus Foundation) provide '
          'transport assistance. Malta\'s small size means most locations reachable by bus '
          'within 1-1.5 hours. Cannot convert license during procedure.',
      drivingAuthority: 'Transport Malta - Land Transport Directorate',
      authorityWebsite: 'https://www.transport.gov.mt',
      legalBasis: 'Motor Vehicles (Driving Licences) Regulations (S.L. 65.18)',
      immigrantSpecificNotes:
          'Malta is MODERATE. Left-hand driving (British legacy) is the main challenge. English '
          'as official language eliminates language barriers for testing. Good Commonwealth '
          'country recognition. Very small island (316 km2) so driving distances are short but '
          'traffic congestion is severe. Bus network covers the island. Large immigrant worker '
          'population (many from North Africa, Philippines, Eastern Europe). Insurance is '
          'relatively expensive for the small market.',
      strictnessRating: 'moderate',
    ),

    // ============================================================
    // 20. NETHERLANDS
    // ============================================================
    TransportationRights(
      country: 'Netherlands',
      countryCode: 'NL',
      foreignLicenseAccepted: true,
      foreignLicenseValidMonths: 6,
      foreignLicenseConditions:
          'Third-country licenses valid for a maximum of 185 days (approximately 6 months) '
          'from BRP (Basisregistratie Personen) registration. After 185 days, license is '
          'COMPLETELY INVALID. No exceptions. Must carry original license + IDP or certified '
          'translation. Some countries\' licenses not recognized at all if not Vienna Convention '
          'compliant. EEA licenses valid without limit until expiry.',
      conversionProcess:
          'Apply at Gemeente (municipality). Documents: declaration of health (Eigen verklaring '
          'EUR 42.20), foreign license, BSN (Citizen Service Number), residence permit, '
          'passport photo, application form. Countries with exchange agreement: direct exchange '
          '(no test, fee ~EUR 43). Non-agreement countries: must take FULL Dutch driving '
          'exam from scratch including theory (CBR computer test) and practical test. NO '
          'credit given for foreign driving experience. This effectively means starting over.',
      conversionCostEuros: '85-3,500 (exchange: EUR 43 + health declaration EUR 42. Full course: '
          'theory EUR 39.50 + practical test EUR 119.50 + driving lessons EUR 1,500-3,000)',
      theoryTestRequired: true,
      practicalTestRequired: true,
      theoryTestLanguages: [
        'Dutch',
        'English',
        'German',
        'Turkish',
        'Arabic (Modern Standard)',
      ],
      mutualRecognitionCountries: [
        'Japan',
        'South Korea',
        'Taiwan',
        'Singapore',
        'Israel',
        'Andorra',
        'Monaco',
        'Switzerland',
        'Quebec (Canada)',
        'Aruba, Curaçao, Sint Maarten, BES islands (Kingdom)',
        'All EEA countries',
      ],
      idpRules:
          'IDP accepted for visitors only (max 185 days from entry/registration). Must '
          'accompany original license. Only Vienna Convention (1968) IDP officially recognized. '
          'Geneva Convention IDP NOT accepted. Strict interpretation by Dutch police.',
      policeStopConsequences:
          'Driving without valid license: fine EUR 400 (OM-beschikking). Repeated offense: '
          'criminal prosecution, fine up to EUR 22,500 and/or up to 2 months detention. '
          'Vehicle can be confiscated. RDW (vehicle authority) may impound. Points: 2 penalty '
          'points. Affects verblijfsvergunning (residence permit) renewal if criminal conviction.',
      insuranceRequirements:
          'Mandatory third-party liability (WA-verzekering). Minimum: EUR 6.45 million per '
          'event combined. Insurance costs: EUR 400-1,200/year. RDW tracks insurance status '
          'digitally (automatic detection of uninsured vehicles). Bonus-malus system. Foreign '
          'no-claims: some Dutch insurers accept with letter from previous insurer. Vergelijk.nl '
          'and Independer for comparison shopping.',
      publicTransportDiscounts:
          'OV-chipkaart: pay-as-you-go for all public transport. NS (rail): various discount '
          'subscriptions (Dal Voordeel EUR 5.20/month for 40% off-peak discount). Students: '
          'free OV-chipkaart (with DUO studielink). Seniors (65+): no automatic discount (must '
          'buy subscription). Municipal social minimum: some gemeenten provide reduced-fare OV. '
          'Amsterdam U-Pas: discounts for low-income residents. Rotterdam Pas similar.',
      asylumSeekerTransportRights:
          'Asylum seekers in COA (Centraal Orgaan opvang Asielzoekers) locations receive: '
          'weekly allowance EUR 14/week (food money if cooking, more if no kitchen) + EUR 12.95/'
          'week pocket money. Transport to IND (Immigration) interviews: travel costs reimbursed '
          'by COA (public transport tickets provided). AZC (asylum centers) often in smaller '
          'cities/towns with limited public transport. Some AZCs provide bicycles. VluchtelingenWerk '
          'Nederland provides escort services to appointments. After status (verblijfsvergunning): '
          'eligible for municipal social support including transport assistance. Cannot convert '
          'license during procedure.',
      drivingAuthority: 'CBR (Centraal Bureau Rijvaardigheidsbewijzen) / RDW',
      authorityWebsite: 'https://www.cbr.nl',
      legalBasis: 'Wegenverkeerswet 1994 (Road Traffic Act), Art. 107-113; Regeling '
          'erkende rijbewijzen',
      immigrantSpecificNotes:
          'Netherlands is STRICT. The 185-day deadline is absolute with no extensions. Most '
          'third-country license holders must start completely from scratch (full Dutch driving '
          'course, one of the most expensive in Europe at EUR 2,000-3,500). Theory test in '
          'Turkish and Arabic reflects large immigrant communities. Dutch cycling culture means '
          'many residents manage without a car, but driving is important for work outside '
          'Randstad. AZC bicycle provision is uniquely Dutch. The 30% ruling for expats does '
          'NOT extend driving license validity. CBR waiting times for tests can be 4-8 weeks.',
      strictnessRating: 'strict',
    ),

    // ============================================================
    // 21. POLAND
    // ============================================================
    TransportationRights(
      country: 'Poland',
      countryCode: 'PL',
      foreignLicenseAccepted: true,
      foreignLicenseValidMonths: 6,
      foreignLicenseConditions:
          'Third-country licenses valid for 6 months from establishing residence. Must be '
          'valid, not suspended, and conform to Vienna Convention or accompanied by certified '
          'Polish translation/IDP. After 6 months, Polish license required. License must not '
          'have been obtained in a country where the holder was not a resident. EEA licenses '
          'valid without restriction.',
      conversionProcess:
          'Apply at Starostwo Powiatowe (county office) or Urząd Miasta (city office). '
          'Documents: application (wniosek), foreign license + sworn translation (tłumacz '
          'przysięgły, ~PLN 50-100), passport, Karta pobytu (residence card), medical '
          'certificate from authorized physician (badania lekarskie, ~PLN 200/EUR 45), '
          'psychological test for category C/D (~PLN 150), passport photo. Vienna Convention '
          'licenses: exchange without test in most cases. Others: theory + practical test. '
          'Polish process is paper-heavy but affordable.',
      conversionCostEuros: '30-500 (exchange fee PLN 100 ~EUR 23 + medical ~EUR 45 + translation '
          '~EUR 12-23 + tests/lessons if needed ~EUR 200-350)',
      theoryTestRequired: true,
      practicalTestRequired: true,
      theoryTestLanguages: [
        'Polish',
        'English',
        'German',
        'Sign language (video questions)',
      ],
      mutualRecognitionCountries: [
        'Ukraine',
        'Japan',
        'South Korea',
        'All Vienna Convention signatories',
        'All EEA countries',
      ],
      idpRules:
          'IDP accepted for tourists and during grace period. Both Vienna and Geneva IDPs '
          'recognized. Must accompany original license. Widely accepted by police for '
          'translation purposes.',
      policeStopConsequences:
          'Driving without valid license: fine PLN 1,000-5,000 (~EUR 230-1,150). Vehicle can '
          'be immobilized. Court referral for serious cases. Since 2022: PLN 1,500 fine for '
          'driving without carrying license (previously PLN 50). Criminal liability for '
          'driving despite ban (Art. 244 Criminal Code: up to 5 years).',
      insuranceRequirements:
          'Mandatory third-party liability (OC). Minimum: EUR 5.6 million personal injury, '
          'EUR 1.12 million property per event. Very affordable: EUR 60-200/year (among '
          'cheapest in EU). UFG (Ubezpieczeniowy Fundusz Gwarancyjny) guarantees. Online '
          'comparison tools (rankomat.pl, mfind.pl). Foreign no-claims accepted by some '
          'insurers.',
      publicTransportDiscounts:
          'ZTM Warszawa (Warsaw): monthly pass PLN 110 (~EUR 25). Students: 50% discount '
          '(legitymacja studencka). Seniors (70+): free in Warsaw. Social assistance: 50% '
          'discount with MOPS certification. PKP Intercity rail: student discount 51%. '
          'Large family card (Karta Dużej Rodziny): various discounts. Extremely affordable '
          'public transport throughout Poland.',
      asylumSeekerTransportRights:
          'Asylum seekers in OdU (Ośrodek dla Uchodźców) reception centers receive: '
          'accommodation + daily allowance PLN 9/day (~EUR 2) or PLN 25/day if outside center. '
          'Transport to Urząd do Spraw Cudzoziemców (Office for Foreigners) interviews: '
          'arranged by center. Since 2022: massive Ukrainian refugee influx led to expanded '
          'programs. PESEL UKR allows Ukrainian refugees immediate work rights + local transport '
          'discounts. Regular asylum seekers: limited transport support. NGOs (Polish Humanitarian '
          'Action, Caritas Poland) provide assistance. Cannot convert license during procedure.',
      drivingAuthority: 'Ministerstwo Infrastruktury / WORD (testing centers)',
      authorityWebsite: 'https://www.gov.pl/web/infrastruktura',
      legalBasis: 'Ustawa o kierujących pojazdami (Act on Vehicle Drivers) z dnia 5 '
          'stycznia 2011 r., Art. 4-14',
      immigrantSpecificNotes:
          'Poland is LENIENT. Among the cheapest EU countries for license conversion and '
          'insurance. The massive Ukrainian refugee integration (2022+) created new pathways. '
          'Ukrainian licenses widely recognized. Theory test in English and German available. '
          'Public transport is extremely affordable. The Polish bureaucracy is improving '
          'digitally but still paper-based in many offices. Driving culture is practical '
          'rather than restrictive. The sign language option for theory tests shows accessibility '
          'awareness.',
      strictnessRating: 'lenient',
    ),

    // ============================================================
    // 22. PORTUGAL
    // ============================================================
    TransportationRights(
      country: 'Portugal',
      countryCode: 'PT',
      foreignLicenseAccepted: true,
      foreignLicenseValidMonths: 6,
      foreignLicenseConditions:
          'Third-country licenses valid for up to 6 months from establishing legal residence. '
          'Must be valid and in Portuguese, English, French, or Spanish, or accompanied by '
          'certified translation/IDP. Holders from CPLP (Community of Portuguese Language '
          'Countries) may have extended recognition. After grace period, Portuguese license '
          'required. EEA licenses valid until expiry.',
      conversionProcess:
          'Apply at IMT (Instituto da Mobilidade e dos Transportes). Documents: application '
          '(Modelo 1-IMT), foreign license + certified translation, passport, título de '
          'residência, NIF (tax number), medical certificate (~EUR 25), 2 photos. CPLP '
          'countries (Brazil, Angola, Mozambique, Cape Verde, etc.): direct exchange. Others: '
          'theory + practical test. Process handled through IMT counters or IMT online portal.',
      conversionCostEuros: '30-800 (IMT fee ~EUR 30 + medical ~EUR 25 + translation ~EUR 20 + '
          'tests/lessons if needed ~EUR 300-700)',
      theoryTestRequired: true,
      practicalTestRequired: true,
      theoryTestLanguages: ['Portuguese', 'English'],
      mutualRecognitionCountries: [
        'Brazil',
        'Angola',
        'Mozambique',
        'Cape Verde',
        'Guinea-Bissau',
        'São Tomé and Príncipe',
        'Timor-Leste',
        'Macau (China)',
        'Switzerland',
        'Japan',
        'South Korea',
        'All CPLP member states',
        'All EEA countries',
      ],
      idpRules:
          'IDP accepted for tourists. Both Vienna and Geneva IDPs recognized. Must accompany '
          'original license. Very useful since many languages are not natively read by '
          'Portuguese police.',
      policeStopConsequences:
          'Driving without valid license: fine EUR 500-2,500. Vehicle immobilization. Criminal '
          'offense for repeat violations or if license was revoked (up to 2 years imprisonment). '
          'GNR (Guarda Nacional Republicana) and PSP (Polícia de Segurança Pública) enforce. '
          'Insurance void for claims.',
      insuranceRequirements:
          'Mandatory third-party liability (seguro automóvel). Minimum: EUR 6.45 million '
          'personal injury, EUR 1.3 million property per event. Costs: EUR 150-500/year. '
          'ASF (Autoridade de Supervisão de Seguros e Fundos de Pensões) oversees. Online '
          'comparison available. Reasonably affordable.',
      publicTransportDiscounts:
          'Navegante pass (Lisbon metropolitan area): EUR 30/month for municipal, EUR 40/month '
          'for metropolitan (all modes). Porto Andante: monthly ~EUR 30-40. Among the cheapest '
          'in Western Europe. Students: further discounts. Seniors (65+): reduced fares. '
          'Social tariff (sub23@metropolitano): free for under 23 in Lisbon/Porto since 2024. '
          'RSI (Rendimento Social de Inserção) recipients: free Navegante pass.',
      asylumSeekerTransportRights:
          'Asylum seekers receive monthly allowance through IPSS/CPR: ~EUR 150/month '
          '(varies by accommodation type). PAR (Plataforma de Apoio aos Refugiados) and '
          'CPR (Conselho Português para os Refugiados) provide integration support. Transport '
          'to SEF/AIMA interviews: arranged by hosting organization. Lisbon and Porto have '
          'affordable public transport. RSI eligibility after protection status = free transport. '
          'Cannot convert license during procedure. After status: immediate CPLP advantage for '
          'Brazilian, Angolan, and other Lusophone refugees.',
      drivingAuthority: 'IMT - Instituto da Mobilidade e dos Transportes',
      authorityWebsite: 'https://www.imt-ip.pt',
      legalBasis: 'Regulamento da Habilitação Legal para Conduzir (Decreto-Lei n.º 138/2012)',
      immigrantSpecificNotes:
          'Portugal is MODERATE to LENIENT. Exceptional CPLP (Lusophone) bilateral recognition '
          'means the large Brazilian, Angolan, Cape Verdean communities can exchange directly. '
          'This is a major advantage. Navegante pass at EUR 30-40/month is among cheapest in '
          'Western Europe. Free transport for under-23 since 2024 is progressive. Portuguese '
          'bureaucracy (IMT) can be slow but the system works. Golden visa holders have same '
          'license rules. AIMA (replacing SEF) integration is ongoing.',
      strictnessRating: 'moderate',
    ),

    // ============================================================
    // 23. ROMANIA
    // ============================================================
    TransportationRights(
      country: 'Romania',
      countryCode: 'RO',
      foreignLicenseAccepted: true,
      foreignLicenseValidMonths: 12,
      foreignLicenseConditions:
          'Third-country licenses valid for 12 months from establishing residence. Must be '
          'valid, conform to Vienna Convention or accompanied by certified translation/IDP. '
          'After 12 months, Romanian license required. Process must begin before expiry of '
          'grace period. EEA licenses valid without restriction.',
      conversionProcess:
          'Apply at DRPCIV (Direcția Regim Permise de Conducere și Înmatriculare a Vehiculelor) '
          'or local Serviciul Public Comunitar. Documents: application, foreign license + '
          'certified translation, passport, residence permit (permis de ședere), medical '
          'certificate (fișa medicală, ~RON 100/EUR 20), psychological evaluation (~RON 80/'
          'EUR 16), 2 photos. Vienna Convention compliant licenses: exchange without test. '
          'Others: theory (computer-based) + practical test. Process typically 2-6 weeks.',
      conversionCostEuros: '20-400 (DRPCIV fee ~RON 62/EUR 12 + medical ~EUR 20 + psych ~EUR 16 '
          '+ translation ~EUR 10 + tests/lessons if needed ~EUR 200-300)',
      theoryTestRequired: true,
      practicalTestRequired: true,
      theoryTestLanguages: ['Romanian', 'English', 'Hungarian (in Transylvania)'],
      mutualRecognitionCountries: [
        'Moldova',
        'Ukraine',
        'Serbia',
        'Turkey',
        'All Vienna Convention signatories (with conditions)',
        'All EEA countries',
      ],
      idpRules:
          'IDP accepted for tourists. Vienna Convention IDP preferred. Must accompany original '
          'license. Romania is a Vienna Convention signatory. IDP serves as translation.',
      policeStopConsequences:
          'Driving without valid license: fine RON 2,500-6,000 (~EUR 500-1,200) under OUG '
          '195/2002. Vehicle immobilization and plate removal. Criminal offense if license '
          'was revoked (Art. 335 Criminal Code: 1-5 years imprisonment). Contraventional '
          'fine for first-time expired/unconverted license.',
      insuranceRequirements:
          'Mandatory third-party liability (RCA). Minimum: EUR 6.45 million personal injury, '
          'EUR 1.3 million property. Among cheapest in EU: EUR 30-150/year. ASF (Autoritatea '
          'de Supraveghere Financiară) oversees. Online purchase common. BAAR guarantee fund.',
      publicTransportDiscounts:
          'STB (Bucharest): monthly pass RON 50 (~EUR 10). Students: 50% discount nationally. '
          'Seniors (60+ women, 65+ men): free in Bucharest. Disabled: free. Social assistance '
          'recipients: free in many cities. CFR (rail): student discount 50%. Among cheapest '
          'public transport in the EU.',
      asylumSeekerTransportRights:
          'Asylum seekers in IGI (Inspectoratul General pentru Imigrări) regional centers '
          'receive: accommodation + daily allowance RON 15/day (~EUR 3). Transport to IGI '
          'interviews: arranged by center. Limited but affordable public transport. NGOs '
          '(ARCA Romanian Forum for Refugees, JRS Romania) provide transport support. After '
          'recognition: integration program (12 months) includes housing, language, and '
          'employment support. Cannot convert license during procedure.',
      drivingAuthority: 'DRPCIV (Direcția Regim Permise de Conducere)',
      authorityWebsite: 'https://www.drpciv.ro',
      legalBasis: 'OUG 195/2002 privind circulația pe drumurile publice (as amended)',
      immigrantSpecificNotes:
          'Romania is LENIENT. Among the cheapest EU countries for everything: license '
          'conversion, insurance, and public transport. The 12-month grace period is generous. '
          'Moldovan license recognition is important given the large Moldovan community. '
          'Hungarian theory test in Transylvania reflects the ethnic Hungarian minority. '
          'Bureaucracy can be slow but costs are minimal. Romanian driving standards have '
          'improved significantly since EU accession (2007). Road infrastructure varies greatly '
          'between cities and rural areas.',
      strictnessRating: 'lenient',
    ),

    // ============================================================
    // 24. SLOVAKIA
    // ============================================================
    TransportationRights(
      country: 'Slovakia',
      countryCode: 'SK',
      foreignLicenseAccepted: true,
      foreignLicenseValidMonths: 6,
      foreignLicenseConditions:
          'Third-country licenses valid for up to 6 months from establishing residence (or '
          'until the date the license expires, whichever comes first). Must be valid and '
          'accompanied by certified translation/IDP. After 6 months, Slovak license required. '
          'EEA licenses valid without restriction.',
      conversionProcess:
          'Apply at Dopravný inšpektorát (Traffic Inspectorate) of district police. Documents: '
          'application, foreign license + certified translation, passport, residence permit, '
          'medical certificate (~EUR 15), 1 photo. Vienna Convention compliant with photo: '
          'exchange without test. Others: theory (computer-based) + practical test. Process '
          'relatively efficient (2-4 weeks). Old license returned with marking.',
      conversionCostEuros: '15-400 (administrative fee ~EUR 7-15 + medical ~EUR 15 + '
          'translation ~EUR 10 + tests/lessons if needed ~EUR 200-350)',
      theoryTestRequired: true,
      practicalTestRequired: true,
      theoryTestLanguages: ['Slovak', 'English', 'Hungarian', 'Czech'],
      mutualRecognitionCountries: [
        'Ukraine',
        'Serbia',
        'Japan',
        'South Korea',
        'All Vienna Convention signatories',
        'All EEA countries',
      ],
      idpRules:
          'IDP accepted for tourists. Vienna Convention IDP recognized. Geneva Convention IDP '
          'accepted with conditions. Must accompany original license.',
      policeStopConsequences:
          'Driving without valid license: fine EUR 300-1,300 (on the spot or administrative). '
          'Vehicle impoundment possible. Criminal offense for driving with suspended/revoked '
          'license (up to 2 years). Slovak police increasingly strict on document checks.',
      insuranceRequirements:
          'Mandatory third-party liability (PZP). Minimum: EUR 5.6 million personal injury, '
          'EUR 1.12 million property. Very affordable: EUR 50-200/year. SBP (Slovenská '
          'kancelária poisťovateľov) oversees. Online purchase straightforward.',
      publicTransportDiscounts:
          'DPB (Bratislava): monthly pass EUR 29.90. Students: 50% discount. Seniors (62+): '
          'free train travel nationwide since 2014. Disabled: free. Social assistance (pomoc '
          'v hmotnej núdzi) recipients: reduced municipal transport. ZSSK rail: free for '
          'students in second class on select routes. Very affordable system.',
      asylumSeekerTransportRights:
          'Asylum seekers in MÚ (Migračný úrad) facilities (Opatovská Nová Ves, Rohovce) '
          'receive: accommodation + monthly allowance ~EUR 10-40 depending on facility type. '
          'Transport to MÚ interviews arranged by facility. Limited public transport near '
          'facilities. Slovak Humanitarian Council and UNHCR partners provide some support. '
          'Small number of asylum seekers overall. Cannot convert license during procedure.',
      drivingAuthority: 'Ministerstvo vnútra SR - Dopravný inšpektorát',
      authorityWebsite: 'https://www.minv.sk',
      legalBasis: 'Zákon č. 8/2009 Z. z. o cestnej premávke (Road Traffic Act), §88-§98',
      immigrantSpecificNotes:
          'Slovakia is MODERATE to LENIENT. Low costs throughout. Hungarian and Czech language '
          'options reflect neighboring country communities. Free senior rail travel is unique. '
          'The Ukrainian community (growing since 2022) benefits from recognition agreements. '
          'Czech theory test is practically useful as languages are mutually intelligible. '
          'Bratislava\'s proximity to Vienna means some immigrants commute cross-border.',
      strictnessRating: 'moderate',
    ),

    // ============================================================
    // 25. SLOVENIA
    // ============================================================
    TransportationRights(
      country: 'Slovenia',
      countryCode: 'SI',
      foreignLicenseAccepted: true,
      foreignLicenseValidMonths: 6,
      foreignLicenseConditions:
          'Third-country licenses valid for 6 months from establishing residence. Must be '
          'valid and conform to Vienna Convention or accompanied by certified Slovenian '
          'translation/IDP. After 6 months, Slovenian license required. Extension NOT possible. '
          'EEA licenses valid until expiry.',
      conversionProcess:
          'Apply at Upravna enota (Administrative Unit) of residence. Documents: application, '
          'foreign license + certified translation, passport, dovoljenje za prebivanje (residence '
          'permit), medical certificate (from chosen physician, ~EUR 30), 1 photo. Most '
          'third-country licenses: theory + practical test required. Limited bilateral agreements. '
          'Slovenian driving school mandatory hours for some conversions. Old license surrendered.',
      conversionCostEuros: '50-1,000 (administrative fee ~EUR 20-40 + medical ~EUR 30 + '
          'translation ~EUR 20 + tests/lessons if needed ~EUR 400-900)',
      theoryTestRequired: true,
      practicalTestRequired: true,
      theoryTestLanguages: ['Slovenian', 'English', 'Italian (coastal area)', 'Hungarian (Prekmurje)'],
      mutualRecognitionCountries: [
        'Serbia',
        'Bosnia and Herzegovina',
        'North Macedonia',
        'Croatia (EEA)',
        'Japan',
        'South Korea',
        'All EEA countries',
      ],
      idpRules:
          'IDP accepted for tourists. Vienna Convention IDP recognized. Must accompany original '
          'license. Useful in border areas with Italy, Austria, Hungary, Croatia.',
      policeStopConsequences:
          'Driving without valid license: fine EUR 500-1,500. Vehicle impoundment. Misdemeanor '
          'offense (prekršek). Repeated offense: higher fines + possible driving ban. Slovenian '
          'police well-equipped with electronic document verification.',
      insuranceRequirements:
          'Mandatory third-party liability (zavarovanje avtomobilske odgovornosti). Minimum: '
          'EUR 5.6 million personal injury, EUR 1.12 million property. Costs: EUR 200-500/year. '
          'AZN (Agencija za zavarovalni nadzor) oversees. Moderate market.',
      publicTransportDiscounts:
          'LPP (Ljubljana): Urbana card, monthly EUR 35. Students: 50% discount. Seniors (65+): '
          'reduced fares. Disabled: free. Social assistance recipients: some municipal programs. '
          'SŽ (rail): student discounts. Ljubljana has been car-free city center since 2008, '
          'promoting cycling and walking.',
      asylumSeekerTransportRights:
          'Asylum seekers in Azilni dom (Asylum Home) Ljubljana or Logatec receive: '
          'accommodation + financial assistance ~EUR 18/month. Transport to interviews at '
          'Asylum Home arranged. Ljubljana urban bus accessible. NGOs (PIC - Legal Information '
          'Centre, Slovenian Philanthropy) provide transport support for legal appointments. '
          'Small country with limited asylum seeker numbers. Cannot convert license during '
          'procedure. After status: integration program (3 years) includes various support.',
      drivingAuthority: 'Ministrstvo za infrastrukturo',
      authorityWebsite: 'https://www.gov.si/drzavni-organi/ministrstva/ministrstvo-za-infrastrukturo/',
      legalBasis: 'Zakon o voznikih (Drivers Act) ZVoz, Art. 20-30',
      immigrantSpecificNotes:
          'Slovenia is MODERATE to STRICT. Relatively expensive conversion for a small country. '
          'Balkan license recognition is important (large Bosnian, Serbian communities). '
          'Italian and Hungarian minority language options are constitutionally mandated. '
          'Ljubljana\'s car-free center promotes alternative transport. Small asylum seeker '
          'population means less developed support infrastructure. Good road infrastructure '
          'but vignette (road toll sticker) required for highways.',
      strictnessRating: 'moderate',
    ),

    // ============================================================
    // 26. SPAIN
    // ============================================================
    TransportationRights(
      country: 'Spain',
      countryCode: 'ES',
      foreignLicenseAccepted: true,
      foreignLicenseValidMonths: 6,
      foreignLicenseConditions:
          'Third-country licenses valid for 6 months from establishing residence (obtaining '
          'NIE/TIE). Must be valid and in Spanish or accompanied by certified translation from '
          'a Spanish consular office or official translator. After 6 months, Spanish license '
          'required. Note: grace period starts from obtaining residence authorization, NOT from '
          'entering Spain. EEA licenses valid until expiry.',
      conversionProcess:
          'Apply at Jefatura Provincial de Tráfico (DGT). Documents: application (Modelo '
          '01.06), foreign license + certified translation by DGT-approved translator, NIE/'
          'TIE, empadronamiento (municipal registration), medical certificate from Centro de '
          'Reconocimiento de Conductores (CRC, ~EUR 25-40), 1 photo, tasa (fee). Countries '
          'with bilateral agreement (canje): direct exchange. Others: full theory and practical '
          'exam. DGT appointments via cita previa (online booking) often have long wait times.',
      conversionCostEuros: '30-1,200 (DGT fee EUR 28.87 + CRC medical EUR 25-40 + translation '
          '~EUR 30-50 + driving school if needed ~EUR 400-1,000)',
      theoryTestRequired: true,
      practicalTestRequired: true,
      theoryTestLanguages: [
        'Spanish (Castellano)',
        'Catalan',
        'Basque (Euskara)',
        'Galician (Galego)',
        'Valencian',
        'English (at DGT discretion, not guaranteed)',
      ],
      mutualRecognitionCountries: [
        'Algeria',
        'Argentina',
        'Bolivia',
        'Brazil',
        'Chile',
        'Colombia',
        'Dominican Republic',
        'Ecuador',
        'El Salvador',
        'Guatemala',
        'Japan',
        'Morocco',
        'Nicaragua',
        'Panama',
        'Paraguay',
        'Peru',
        'Philippines',
        'South Korea',
        'Serbia',
        'Tunisia',
        'Turkey',
        'Ukraine',
        'Uruguay',
        'Venezuela',
        'All EEA countries',
      ],
      idpRules:
          'IDP accepted for tourists (up to 6 months). Both Vienna and Geneva IDPs recognized. '
          'Must accompany original license. Spain is a party to both conventions. IDP does not '
          'extend grace period for residents.',
      policeStopConsequences:
          'Driving without valid license: fine EUR 500 (infracción muy grave). Repeated offense: '
          'EUR 500 + criminal charges (up to 6 months imprisonment under Art. 384 Código Penal '
          'for driving without having ever obtained a license). Vehicle immobilization. Insurance '
          'void. Points: not applicable (different offense category).',
      insuranceRequirements:
          'Mandatory third-party liability (seguro obligatorio de automóviles). Minimum: EUR 70 '
          'million personal injury, EUR 15 million property. Insurance costs: EUR 200-600/year. '
          'DGSFP (Dirección General de Seguros) oversees. Consorcio de Compensación de Seguros '
          '(CCS) as insurer of last resort. Online comparison easy (rastreator.com, acierto.com).',
      publicTransportDiscounts:
          'TMB (Barcelona): T-Casual 10 trips EUR 11.35, monthly T-Usual EUR 40. EMT (Madrid): '
          'monthly Abono Transportes EUR 54.60 (Zone A). Government Abono Joven (under 31): '
          'EUR 20/month nationwide since 2023. Students: further reductions. Seniors (65+): '
          'free Abono in Madrid. Tarjeta social: free for income < EUR 6,000/year. RENFE: 50% '
          'discount for families, free commuter rail with subscription (2023 extension). '
          'Spain introduced massive public transport subsidies since 2022 energy crisis.',
      asylumSeekerTransportRights:
          'Asylum seekers in SAI (Sistema de Acogida e Integración, managed by MSSSI) receive: '
          'Phase 1 (reception, 6-9 months): full accommodation + monthly allowance EUR 51.60 + '
          'transport to appointments. Phase 2 (integration, 6-18 months): rental assistance + '
          'EUR 347/month. SAI centers provide bus/metro cards in many cities. CEAR (Comisión '
          'Española de Ayuda al Refugiado) and ACCEM provide transport support. After protection: '
          'eligible for tarjeta social and Abono Joven. Cannot exchange license during procedure '
          '(need TIE). Spain has one of the largest asylum systems in EU.',
      drivingAuthority: 'DGT - Dirección General de Tráfico',
      authorityWebsite: 'https://sede.dgt.gob.es',
      legalBasis: 'Real Decreto 818/2009 Reglamento General de Conductores, Art. 21-26',
      immigrantSpecificNotes:
          'Spain is MODERATE. THE most extensive bilateral agreement network in the EU, '
          'especially with Latin American countries. This means the massive Latin American '
          'immigrant community (Colombian, Venezuelan, Ecuadorian, etc.) can exchange licenses '
          'directly. Also good recognition for North African licenses. Co-official languages '
          '(Catalan, Basque, Galician) available for tests in respective regions. Public '
          'transport subsidies since 2022 are among the most generous in Europe (Abono Joven '
          'EUR 20/month). DGT appointment waits can be months in Madrid/Barcelona. Filipino '
          'community also benefits from bilateral agreement.',
      strictnessRating: 'moderate',
    ),

    // ============================================================
    // 27. SWEDEN
    // ============================================================
    TransportationRights(
      country: 'Sweden',
      countryCode: 'SE',
      foreignLicenseAccepted: true,
      foreignLicenseValidMonths: 12,
      foreignLicenseConditions:
          'Third-country licenses valid for 12 months from establishing residence '
          '(folkbokföring/population registration at Skatteverket). Must be valid, not '
          'suspended, and issued before moving to Sweden. After 12 months, Swedish license '
          'mandatory. No extension. Must carry original license (copy not accepted). IDP '
          'or translation recommended. EEA licenses valid until expiry.',
      conversionProcess:
          'Apply at Transportstyrelsen (Swedish Transport Agency). Documents: application '
          '(online or paper), foreign license + sworn translation (auktoriserad translator), '
          'syntest (eye test at Synoptik/Specsavers ~SEK 150/EUR 13), Körkortstillstånd '
          '(driving license permit, includes medical declaration and background check). '
          'Sweden does NOT have bilateral agreements for most countries. Almost all third-country '
          'nationals must take FULL Swedish driving education: Riskutbildning 1 (risk education '
          'theory), Riskutbildning 2 (skid course), theory test, and practical test. Among the '
          'most demanding in Europe.',
      conversionCostEuros: '300-4,000 (Transportstyrelsen fee ~SEK 300/EUR 26 + eye test '
          '~EUR 13 + körkortstillstånd ~SEK 250/EUR 22 + full driving education: theory '
          '~EUR 400, practical lessons ~EUR 2,000-3,000, risk courses ~EUR 300-500)',
      theoryTestRequired: true,
      practicalTestRequired: true,
      theoryTestLanguages: [
        'Swedish',
        'English',
        'Arabic',
        'Albanian',
        'Bosnian/Croatian/Serbian (BCS)',
        'Finnish',
        'French',
        'Kurdish (Sorani)',
        'Persian (Farsi)',
        'Russian',
        'Somali',
        'Spanish',
        'Thai',
        'Tigrinya',
        'Turkish',
      ],
      mutualRecognitionCountries: [
        'Japan (from 2024 agreement)',
        'South Korea',
        'Switzerland',
        'Taiwan',
        'Faroe Islands',
        'All EEA countries',
      ],
      idpRules:
          'IDP accepted for tourists/visitors (up to 12 months). Must accompany original license. '
          'Both Vienna and Geneva IDPs accepted. Sweden is party to the 1968 Vienna Convention. '
          'IDP does not extend or replace the 12-month grace period.',
      policeStopConsequences:
          'Driving without valid license (olovlig körning): fine (böter) according to '
          'day-fine system (dagsböter) based on income, typically 30-100 dagsböter. Aggravated '
          'unlicensed driving (grov olovlig körning): up to 6 months imprisonment. Day-fines '
          'can be very high for high earners (thousands of EUR). Vehicle impoundment '
          '(förverkande) possible. Criminal record affects migration status.',
      insuranceRequirements:
          'Mandatory third-party liability (trafikförsäkring). UNLIMITED minimum coverage '
          '(together with France, among highest in EU). Insurance costs: SEK 3,000-12,000/year '
          '(EUR 260-1,050). Trafikförsäkringsföreningen (TFF) covers uninsured vehicles and '
          'charges penalty fee. Bonus system (bonus-malus). Foreign no-claims: some insurers '
          'accept with documentation. Folksam, IF, Länsförsäkringar are major providers.',
      publicTransportDiscounts:
          'SL (Stockholm): 30-day pass SEK 970 (~EUR 85). Monthly passes vary by region '
          '(Skånetrafiken, Västtrafik, etc. SEK 700-900). Youth (under 20): significantly '
          'reduced. Seniors (65+): reduced. Students: SL Student card available. SJ rail: '
          'student and senior discounts. Low-income: some kommuner provide subsidized transit '
          '(försörjningsstöd/social assistance may include transport costs). No uniform national '
          'social transport scheme.',
      asylumSeekerTransportRights:
          'Asylum seekers under Migrationsverket receive: LMA-kort (registration card) + daily '
          'allowance SEK 71/day (~EUR 6.20) for single adult (2024). If accommodated by '
          'Migrationsverket: SEK 24/day. Transport to Migrationsverket interviews: travel '
          'costs reimbursed with LMA-kort reference. Some kommuner provide SL/regional cards '
          'for those in municipal accommodation. Röda Korset (Red Cross) and other NGOs provide '
          'transport support. After uppehållstillstånd (residence permit): immediate access to '
          'kommunal integration program including transport support. Cannot convert license '
          'during asylum process.',
      drivingAuthority: 'Transportstyrelsen (Swedish Transport Agency)',
      authorityWebsite: 'https://www.transportstyrelsen.se',
      legalBasis: 'Körkortslagen (1998:488) Driving Licence Act, Körkortsförordningen (1998:980)',
      immigrantSpecificNotes:
          'Sweden is STRICT. Among the most demanding and expensive countries in the EU for '
          'license conversion. Almost NO bilateral agreements (Japan added only in 2024). Most '
          'immigrants must complete full Swedish driving education from scratch at EUR 2,000-4,000. '
          'However, theory test is available in 15+ languages (most in EU after Germany), '
          'reflecting Sweden\'s diverse immigrant population. Day-fine system means penalties '
          'scale with income. Unlimited insurance coverage requirement. Public transport is '
          'expensive by European standards. The mandatory risk education courses (skid training, '
          'theory) are unique Nordic requirements. Despite strictness, Swedish roads are among '
          'the safest in the world (Vision Zero policy).',
      strictnessRating: 'strict',
    ),
  ];

  // ============================================================
  // HELPER METHODS
  // ============================================================

  /// Get transportation rights for a specific country by code
  TransportationRights? getByCountryCode(String code) {
    try {
      return allCountries.firstWhere(
        (c) => c.countryCode.toUpperCase() == code.toUpperCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get transportation rights for a specific country by name
  TransportationRights? getByCountryName(String name) {
    try {
      return allCountries.firstWhere(
        (c) => c.country.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get all countries with a specific strictness rating
  List<TransportationRights> getByStrictnessRating(String rating) {
    return allCountries
        .where((c) => c.strictnessRating == rating.toLowerCase())
        .toList();
  }

  /// Get the strictest countries for license conversion
  List<TransportationRights> getStrictestCountries() {
    return getByStrictnessRating('strict');
  }

  /// Get the most lenient countries for license conversion
  List<TransportationRights> getMostLenientCountries() {
    return getByStrictnessRating('lenient');
  }

  /// Get countries sorted by grace period (longest first)
  List<TransportationRights> getByGracePeriod({bool ascending = false}) {
    final sorted = List<TransportationRights>.from(allCountries)
      ..sort((a, b) => ascending
          ? a.foreignLicenseValidMonths.compareTo(b.foreignLicenseValidMonths)
          : b.foreignLicenseValidMonths.compareTo(a.foreignLicenseValidMonths));
    return sorted;
  }

  /// Get countries that have mutual recognition with a specific country
  List<TransportationRights> getCountriesRecognizing(String country) {
    return allCountries
        .where((c) => c.mutualRecognitionCountries.any(
              (r) => r.toLowerCase().contains(country.toLowerCase()),
            ))
        .toList();
  }

  /// Get countries where theory test is available in a specific language
  List<TransportationRights> getCountriesWithTestLanguage(String language) {
    return allCountries
        .where((c) => c.theoryTestLanguages.any(
              (l) => l.toLowerCase().contains(language.toLowerCase()),
            ))
        .toList();
  }

  /// Get countries with free or heavily subsidized public transport
  List<TransportationRights> getCountriesWithFreeTransport() {
    return allCountries
        .where((c) =>
            c.publicTransportDiscounts.toLowerCase().contains('free') &&
            (c.publicTransportDiscounts.toLowerCase().contains('all') ||
             c.publicTransportDiscounts.toLowerCase().contains('everyone') ||
             c.publicTransportDiscounts.toLowerCase().contains('nationwide')))
        .toList();
  }

  /// Get a summary comparison of all countries
  List<Map<String, dynamic>> getComparisonSummary() {
    return allCountries.map((c) => <String, dynamic>{
        'country': c.country,
        'code': c.countryCode,
        'gracePeriodMonths': c.foreignLicenseValidMonths,
        'strictness': c.strictnessRating,
        'estimatedCost': c.conversionCostEuros,
        'testLanguages': c.theoryTestLanguages.length,
        'bilateralAgreements': c.mutualRecognitionCountries.length,
      }).toList();
  }

  /// Get EU Directive 2006/126/EC summary
  String getEUDirectiveSummary() {
    return '''
EU Driving License Directive 2006/126/EC - Summary for Immigrants:

1. MUTUAL RECOGNITION: All EU/EEA driving licenses are mutually recognized
   across all member states. No conversion needed when moving within the EU.

2. THIRD-COUNTRY LICENSES: The Directive does NOT harmonize recognition of
   non-EU licenses. Each member state sets its own rules independently.

3. NORMAL RESIDENCE: Defined as 185+ days/year in a member state. This
   triggers the obligation to comply with that state's license rules.

4. SINGLE LICENSE: You may hold only ONE EU driving license at a time. When
   converting, the foreign license must be surrendered.

5. CATEGORIES: EU uses harmonized categories (AM, A1, A2, A, B, BE, B1, C1,
   C1E, C, CE, D1, D1E, D, DE). Foreign categories must be mapped.

6. VALIDITY: EU licenses have maximum validity periods (15 years for cars,
   5 years for trucks/buses with medical checks).

7. KEY DATES: Directive entered force 19 January 2007. All member states
   had to comply by 19 January 2013. New credit-card format mandatory.

8. PROPOSED REVISION (2023): European Commission proposed updates including
   digital driving licenses, graduated licensing, and stricter medical
   requirements. Legislative process ongoing.

Grace Period Comparison:
- 24 months: Finland
- 12 months: Bulgaria, Croatia, Estonia, France, Hungary, Ireland, Italy,
  Latvia, Luxembourg, Malta, Netherlands (185 days), Romania, Sweden
- 6 months: Austria, Belgium, Cyprus, Czech Republic (3-12), Denmark,
  Germany, Greece, Lithuania, Netherlands, Poland, Portugal, Slovakia,
  Slovenia, Spain

Strictest: Germany, Austria, Netherlands, Denmark, Finland, Sweden
Most lenient: Bulgaria, Croatia, Hungary, Poland, Romania
''';
  }

  /// Get practical advice for a specific nationality
  String getAdviceForNationality(String nationality, String destinationCountryCode) {
    final destination = getByCountryCode(destinationCountryCode);
    if (destination == null) return 'Country not found.';

    final buffer = StringBuffer();
    buffer.writeln('Transportation advice for ${destination.country}:');
    buffer.writeln('');
    buffer.writeln('1. Grace period: ${destination.foreignLicenseValidMonths} months');
    buffer.writeln('2. Strictness: ${destination.strictnessRating}');
    buffer.writeln('3. Estimated cost: EUR ${destination.conversionCostEuros}');
    buffer.writeln('');

    // Check if nationality has mutual recognition
    final hasRecognition = destination.mutualRecognitionCountries.any(
      (r) => r.toLowerCase().contains(nationality.toLowerCase()),
    );
    if (hasRecognition) {
      buffer.writeln('GOOD NEWS: ${destination.country} may have mutual recognition '
          'with your country. Direct exchange may be possible without tests.');
    } else {
      buffer.writeln('NOTE: You will likely need to pass both theory and practical '
          'tests to convert your license.');
    }

    buffer.writeln('');
    buffer.writeln('Theory test languages: ${destination.theoryTestLanguages.join(", ")}');
    buffer.writeln('');
    buffer.writeln('If stopped by police without valid license:');
    buffer.writeln(destination.policeStopConsequences);
    buffer.writeln('');
    buffer.writeln('Public transport alternatives:');
    buffer.writeln(destination.publicTransportDiscounts);

    return buffer.toString();
  }
}
