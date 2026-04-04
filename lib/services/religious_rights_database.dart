// Religious Rights Database for all 27 EU Countries
// Comprehensive data on freedom of religion for immigrants
// Last updated: 2026-04
//
// Sources: ECHR Article 9 (Freedom of thought, conscience and religion),
// EU Charter of Fundamental Rights Articles 10, 21, 22,
// EU Framework Directive 2000/78/EC (equal treatment in employment),
// EU Racial Equality Directive 2000/43/EC,
// FRA (EU Agency for Fundamental Rights) reports,
// OSCE/ODIHR freedom of religion reports,
// US State Department International Religious Freedom Reports,
// European Court of Human Rights case law database (HUDOC),
// National constitutions and religious freedom legislation,
// Pew Research Center restrictions on religion indices.

class ReligiousRightsInfo {
  final String country;
  final String countryCode;
  final String legalBasis;
  final String constitutionalProvision;
  final HalalKosherAccess foodAccess;
  final ReligiousHolidayRights holidayRights;
  final ReligiousClothingRights clothingRights;
  final PrayerRoomRights prayerRoomRights;
  final ReligiousEducationRights educationRights;
  final PlacesOfWorshipRights worshipRights;
  final DiscriminationComplaints discriminationComplaints;
  final BurialRights burialRights;
  final ChaplaincyRights chaplaincyRights;
  final String immigrantSpecificNotes;

  const ReligiousRightsInfo({
    required this.country,
    required this.countryCode,
    required this.legalBasis,
    required this.constitutionalProvision,
    required this.foodAccess,
    required this.holidayRights,
    required this.clothingRights,
    required this.prayerRoomRights,
    required this.educationRights,
    required this.worshipRights,
    required this.discriminationComplaints,
    required this.burialRights,
    required this.chaplaincyRights,
    required this.immigrantSpecificNotes,
  });

  Map<String, dynamic> toMap() {
    return {
      'country': country,
      'countryCode': countryCode,
      'legalBasis': legalBasis,
      'constitutionalProvision': constitutionalProvision,
      'foodAccess': foodAccess.toMap(),
      'holidayRights': holidayRights.toMap(),
      'clothingRights': clothingRights.toMap(),
      'prayerRoomRights': prayerRoomRights.toMap(),
      'educationRights': educationRights.toMap(),
      'worshipRights': worshipRights.toMap(),
      'discriminationComplaints': discriminationComplaints.toMap(),
      'burialRights': burialRights.toMap(),
      'chaplaincyRights': chaplaincyRights.toMap(),
      'immigrantSpecificNotes': immigrantSpecificNotes,
    };
  }
}

class HalalKosherAccess {
  final String schools;
  final String hospitals;
  final String prisons;
  final String military;
  final String generalAvailability;
  final String slaughterLaw;

  const HalalKosherAccess({
    required this.schools,
    required this.hospitals,
    required this.prisons,
    required this.military,
    required this.generalAvailability,
    required this.slaughterLaw,
  });

  Map<String, dynamic> toMap() => {
    'schools': schools,
    'hospitals': hospitals,
    'prisons': prisons,
    'military': military,
    'generalAvailability': generalAvailability,
    'slaughterLaw': slaughterLaw,
  };
}

class ReligiousHolidayRights {
  final String legalFramework;
  final String employeeRights;
  final String publicSectorPolicy;
  final String keyHolidays;

  const ReligiousHolidayRights({
    required this.legalFramework,
    required this.employeeRights,
    required this.publicSectorPolicy,
    required this.keyHolidays,
  });

  Map<String, dynamic> toMap() => {
    'legalFramework': legalFramework,
    'employeeRights': employeeRights,
    'publicSectorPolicy': publicSectorPolicy,
    'keyHolidays': keyHolidays,
  };
}

class ReligiousClothingRights {
  final String workplace;
  final String publicSchools;
  final String governmentBuildings;
  final String faceCoveringLaw;
  final String keyLegalCases;

  const ReligiousClothingRights({
    required this.workplace,
    required this.publicSchools,
    required this.governmentBuildings,
    required this.faceCoveringLaw,
    required this.keyLegalCases,
  });

  Map<String, dynamic> toMap() => {
    'workplace': workplace,
    'publicSchools': publicSchools,
    'governmentBuildings': governmentBuildings,
    'faceCoveringLaw': faceCoveringLaw,
    'keyLegalCases': keyLegalCases,
  };
}

class PrayerRoomRights {
  final String employerObligations;
  final String publicInstitutions;
  final String airports;
  final String universities;

  const PrayerRoomRights({
    required this.employerObligations,
    required this.publicInstitutions,
    required this.airports,
    required this.universities,
  });

  Map<String, dynamic> toMap() => {
    'employerObligations': employerObligations,
    'publicInstitutions': publicInstitutions,
    'airports': airports,
    'universities': universities,
  };
}

class ReligiousEducationRights {
  final String publicSchoolPolicy;
  final String optOutRight;
  final String alternativeEthicsClass;
  final String religiousSchools;

  const ReligiousEducationRights({
    required this.publicSchoolPolicy,
    required this.optOutRight,
    required this.alternativeEthicsClass,
    required this.religiousSchools,
  });

  Map<String, dynamic> toMap() => {
    'publicSchoolPolicy': publicSchoolPolicy,
    'optOutRight': optOutRight,
    'alternativeEthicsClass': alternativeEthicsClass,
    'religiousSchools': religiousSchools,
  };
}

class PlacesOfWorshipRights {
  final String permitProcess;
  final String zoningLaw;
  final String minaretRestrictions;
  final String recentIssues;

  const PlacesOfWorshipRights({
    required this.permitProcess,
    required this.zoningLaw,
    required this.minaretRestrictions,
    required this.recentIssues,
  });

  Map<String, dynamic> toMap() => {
    'permitProcess': permitProcess,
    'zoningLaw': zoningLaw,
    'minaretRestrictions': minaretRestrictions,
    'recentIssues': recentIssues,
  };
}

class DiscriminationComplaints {
  final String equalityBody;
  final String contactInfo;
  final String onlineFiling;
  final String legalAidAvailable;
  final String timeLimit;

  const DiscriminationComplaints({
    required this.equalityBody,
    required this.contactInfo,
    required this.onlineFiling,
    required this.legalAidAvailable,
    required this.timeLimit,
  });

  Map<String, dynamic> toMap() => {
    'equalityBody': equalityBody,
    'contactInfo': contactInfo,
    'onlineFiling': onlineFiling,
    'legalAidAvailable': legalAidAvailable,
    'timeLimit': timeLimit,
  };
}

class BurialRights {
  final String islamicBurial;
  final String jewishBurial;
  final String dedicatedSections;
  final String repatriationOfRemains;
  final String embalming;

  const BurialRights({
    required this.islamicBurial,
    required this.jewishBurial,
    required this.dedicatedSections,
    required this.repatriationOfRemains,
    required this.embalming,
  });

  Map<String, dynamic> toMap() => {
    'islamicBurial': islamicBurial,
    'jewishBurial': jewishBurial,
    'dedicatedSections': dedicatedSections,
    'repatriationOfRemains': repatriationOfRemains,
    'embalming': embalming,
  };
}

class ChaplaincyRights {
  final String prisons;
  final String hospitals;
  final String military;
  final String multiReligious;

  const ChaplaincyRights({
    required this.prisons,
    required this.hospitals,
    required this.military,
    required this.multiReligious,
  });

  Map<String, dynamic> toMap() => {
    'prisons': prisons,
    'hospitals': hospitals,
    'military': military,
    'multiReligious': multiReligious,
  };
}

// =============================================================================
// MAIN DATABASE CLASS
// =============================================================================

class ReligiousRightsDatabase {
  static ReligiousRightsInfo? getByCountryCode(String code) {
    final upperCode = code.toUpperCase();
    return _allCountries.where((c) => c.countryCode == upperCode).firstOrNull;
  }

  static ReligiousRightsInfo? getByCountryName(String name) {
    final lower = name.toLowerCase();
    return _allCountries.where((c) => c.country.toLowerCase() == lower).firstOrNull;
  }

  static List<ReligiousRightsInfo> get allCountries => _allCountries;

  static List<ReligiousRightsInfo> searchByTopic(String topic) {
    final lower = topic.toLowerCase();
    return _allCountries.where((c) {
      final map = c.toMap();
      return map.values.any((v) {
        if (v is String) return v.toLowerCase().contains(lower);
        if (v is Map) return v.values.any((sv) => sv.toString().toLowerCase().contains(lower));
        return false;
      });
    }).toList();
  }

  static List<String> get availableCountries =>
      _allCountries.map((c) => c.country).toList();

  // =========================================================================
  // ALL 27 EU COUNTRIES DATA
  // =========================================================================

  static const List<ReligiousRightsInfo> _allCountries = [

    // ========================================================================
    // 1. AUSTRIA (AT)
    // ========================================================================
    ReligiousRightsInfo(
      country: 'Austria',
      countryCode: 'AT',
      legalBasis: 'Basic Law on the General Rights of Nationals (1867) Art 14-16; '
          'Islamgesetz 2015 (Islam Act); Israelitengesetz 2012; '
          'Equal Treatment Act (Gleichbehandlungsgesetz) 2004.',
      constitutionalProvision: 'Art 14 StGG guarantees full freedom of conscience and religion. '
          'Art 15 grants recognized religious communities corporate status. '
          'Islam has been officially recognized since 1912 (oldest recognition in Western Europe).',
      foodAccess: HalalKosherAccess(
        schools: 'Public schools must accommodate dietary needs upon parental request. '
            'Many schools in Vienna, Graz offer halal meals as standard option.',
        hospitals: 'Hospitals offer alternative menus. AKH Vienna and major hospitals '
            'provide halal and kosher options on request.',
        prisons: 'Justizanstalt (prison authority) required to provide religiously '
            'compliant meals. Halal meals available in all federal prisons since 2009.',
        military: 'Bundesheer provides halal meals for Muslim soldiers. '
            'Kosher options available on request.',
        generalAvailability: 'Widely available in Vienna, Graz, Linz. '
            'Halal certification by IGGÖ (Islamic Religious Authority in Austria).',
        slaughterLaw: 'Ritual slaughter (Schächten) permitted with prior stunning exception '
            'for recognized religious communities under Tierschutzgesetz §32.',
      ),
      holidayRights: ReligiousHolidayRights(
        legalFramework: 'Arbeitsruhegesetz (Rest from Work Act). Employees of recognized '
            'religions may take days off for religious holidays.',
        employeeRights: 'Muslims entitled to leave on Eid al-Fitr and Eid al-Adha under '
            'Islamgesetz 2015. Jewish employees entitled to Yom Kippur, Rosh Hashanah. '
            'Must agree with employer; unpaid unless otherwise negotiated.',
        publicSectorPolicy: 'Public sector accommodates religious holidays for employees '
            'of recognized denominations. Flexible scheduling permitted.',
        keyHolidays: '13 public holidays are Christian-based. Non-Christian religious holidays '
            'are not public holidays but recognized denominations have opt-out.',
      ),
      clothingRights: ReligiousClothingRights(
        workplace: 'Generally permitted in private sector. Employers may restrict for '
            'safety/hygiene reasons only with proportional justification.',
        publicSchools: 'Hijab banned for children under 10 (Kopftuchverbot, 2019). '
            'Constitutional Court upheld in 2020. Permitted for older students.',
        governmentBuildings: 'No general ban. Judges and prosecutors prohibited from '
            'wearing religious symbols under judicial neutrality principle (2019 reforms).',
        faceCoveringLaw: 'Anti-Face-Covering Act (Anti-Gesichtsverhüllungsgesetz) 2017 '
            'bans full face coverings in public spaces. Fine: €150.',
        keyLegalCases: 'VfGH (Constitutional Court) G 4/2021 upheld headscarf ban for '
            'under-10s. ECHR Ebrahimian-type cases referenced in domestic rulings.',
      ),
      prayerRoomRights: PrayerRoomRights(
        employerObligations: 'No legal obligation. Many large employers (e.g., ÖBB, '
            'Siemens Austria) voluntarily provide multi-faith prayer rooms.',
        publicInstitutions: 'Universities in Vienna, Graz, Innsbruck have prayer rooms. '
            'Required in some institutions under IGGÖ agreements.',
        airports: 'Vienna Airport (VIE) has interfaith prayer room in Terminal 3.',
        universities: 'University of Vienna, TU Wien, University of Graz all maintain '
            'multi-faith prayer spaces.',
      ),
      educationRights: ReligiousEducationRights(
        publicSchoolPolicy: 'Religious education mandatory but opt-out available. '
            'Islamic religious instruction in public schools since 1982, taught by '
            'IGGÖ-certified teachers. ~80,000 students attend Islamic RE.',
        optOutRight: 'Parents may withdraw children at start of each school year. '
            'Students 14+ can self-withdraw. Written notification to school required.',
        alternativeEthicsClass: 'Ethics class (Ethikunterricht) mandatory since 2021/22 '
            'for students who opt out of religious education.',
        religiousSchools: 'Islamic schools exist (IGGÖ-run). Jewish schools in Vienna '
            '(ZPC Zwi Perez Chajes). State funding available for recognized religions.',
      ),
      worshipRights: PlacesOfWorshipRights(
        permitProcess: 'Standard building permit (Baugenehmigung) through municipal '
            'authority. No special restrictions for religious buildings.',
        zoningLaw: 'Religious buildings classified as community facilities (Gemeinbedarfsflächen). '
            'Must comply with local zoning plan (Flächenwidmungsplan).',
        minaretRestrictions: 'Carinthia and Vorarlberg passed minaret restrictions (2008-2009). '
            'Challenged but partially upheld. Other Länder have no specific restrictions.',
        recentIssues: 'Controversy over Turkish-government-linked ATIB mosques. '
            'Islamgesetz 2015 banned foreign funding of religious communities.',
      ),
      discriminationComplaints: DiscriminationComplaints(
        equalityBody: 'Gleichbehandlungsanwaltschaft (Ombud for Equal Treatment)',
        contactInfo: 'Taubstummengasse 11, 1040 Vienna. Tel: +43 1 53220',
        onlineFiling: 'https://www.gleichbehandlungsanwaltschaft.gv.at/ — online form available',
        legalAidAvailable: 'Yes. ZARA (Zivilcourage und Anti-Rassismus-Arbeit) provides '
            'free counseling. Legal aid (Verfahrenshilfe) available based on income.',
        timeLimit: '1 year for employment claims, 3 years for civil claims.',
      ),
      burialRights: BurialRights(
        islamicBurial: 'Islamic burial sections in Vienna (Zentralfriedhof Group 27A, '
            'Liesing Islamic Cemetery), Graz, Linz, Innsbruck. Burial without coffin '
            'permitted in dedicated sections. 24-hour burial not guaranteed but expedited.',
        jewishBurial: 'Jewish sections in Zentralfriedhof (Gate 1 and Gate 4). '
            'IKG Wien manages Jewish burial. Perpetual grave rights.',
        dedicatedSections: 'All major cities have Islamic and Jewish cemetery sections. '
            'Vienna has the largest with over 4,000 Islamic graves.',
        repatriationOfRemains: 'Permitted under international agreements. '
            'Consular assistance available. AMASE (Austrian Muslim Association) '
            'helps with repatriation logistics. Average cost: €3,000-€8,000.',
        embalming: 'Not required by Austrian law. Religious communities may arrange '
            'burial preparation according to their rites.',
      ),
      chaplaincyRights: ChaplaincyRights(
        prisons: 'IGGÖ provides Muslim chaplains (Seelsorger) in all federal prisons. '
            'Jewish chaplaincy through IKG. Right guaranteed under Strafvollzugsgesetz §85.',
        hospitals: 'Hospital chaplaincy available. IGGÖ and IKG coordinate spiritual '
            'care in major hospitals. Multi-faith rooms in AKH Vienna.',
        military: 'Muslim military chaplain (Militärimam) appointed in 2015. '
            'Jewish military chaplaincy available.',
        multiReligious: 'Austria pioneered multi-faith chaplaincy model. '
            'Interfaith dialogue center (Kamptal) supports chaplaincy training.',
      ),
      immigrantSpecificNotes: 'Austria officially recognizes Islam since 1912 — the oldest '
          'recognition in Western Europe. Islamgesetz 2015 updated the framework but also '
          'banned foreign funding of mosques. Immigrants from Muslim-majority countries benefit '
          'from well-established IGGÖ infrastructure. Anti-face-covering law and under-10 '
          'headscarf ban are points of contention. Integration Agreement (Integrationsvereinbarung) '
          'requires language/values courses but does not restrict religious practice.',
    ),

    // ========================================================================
    // 2. BELGIUM (BE)
    // ========================================================================
    ReligiousRightsInfo(
      country: 'Belgium',
      countryCode: 'BE',
      legalBasis: 'Constitution Art 19-21 (freedom of worship); '
          'Law of 4 March 1870 (temporal aspects of worship); '
          'Anti-Discrimination Law 2007 (Loi anti-discrimination); '
          'EU Directive 2000/78 transposed.',
      constitutionalProvision: 'Art 19: Freedom of worship guaranteed. Art 20: No one can be '
          'compelled to participate in religious acts. Art 21: State may not interfere in '
          'appointment of ministers of religion. Six recognized religions: Catholicism, '
          'Protestantism, Anglicanism, Judaism, Islam (since 1974), Orthodox Christianity.',
      foodAccess: HalalKosherAccess(
        schools: 'Varies by region. Flanders: many schools offer halal options. '
            'Wallonia/Brussels: halal meals increasingly standard in schools with '
            'significant Muslim populations.',
        hospitals: 'Hospitals accommodate dietary requests. Brussels University Hospital '
            '(UZ Brussel) and major hospitals provide halal/kosher options.',
        prisons: 'Federal Prison Service (SPF Justice) required to provide religiously '
            'compliant meals. Halal meals available in all Belgian prisons.',
        military: 'Belgian Defence provides halal meals for Muslim soldiers.',
        generalAvailability: 'Widely available, especially in Brussels, Antwerp, Liège. '
            'Strong halal food industry with Belgian certification bodies.',
        slaughterLaw: 'Ritual slaughter WITHOUT prior stunning banned in Flanders (2019) '
            'and Wallonia (2019). Brussels region still permits it. '
            'CJEU ruled bans do not violate EU law (C-336/19, Dec 2020).',
      ),
      holidayRights: ReligiousHolidayRights(
        legalFramework: 'Employment Contracts Act (Loi du 3 juillet 1978). '
            'No automatic right to non-Christian religious holidays.',
        employeeRights: 'Employees may request leave for religious holidays using annual '
            'leave or through collective agreement. No statutory right to specific '
            'non-Christian holidays. Some CBAs in Brussels include Eid provisions.',
        publicSectorPolicy: 'Federal public servants may request schedule adjustments. '
            'Brussels regional administration allows flexible arrangements.',
        keyHolidays: '10 public holidays, all secular or Christian. No Muslim or Jewish holidays.',
      ),
      clothingRights: ReligiousClothingRights(
        workplace: 'Private sector: employers may impose dress code if applied neutrally. '
            'Belgian Court of Cassation (2020) upheld employer neutrality policies.',
        publicSchools: 'Varies by region and network. Flemish Community Education (GO!) '
            'bans all religious symbols. French Community more permissive. '
            'Individual school autonomy in Catholic network (libre).',
        governmentBuildings: 'No federal ban. Some municipalities ban religious symbols '
            'for public servants. Brussels varies by commune. Ghent permits hijab for '
            'city employees since 2021.',
        faceCoveringLaw: 'Full face covering ban since 2011 (Law of 1 June 2011). '
            'Fine: €15-€25 and/or up to 7 days imprisonment. '
            'Upheld by ECHR in Belcacemi and Oussar v. Belgium (2017).',
        keyLegalCases: 'CJEU C-157/15 Achbita v. G4S (Belgian reference, 2017): '
            'employer neutrality policy may justify headscarf ban if applied consistently.',
      ),
      prayerRoomRights: PrayerRoomRights(
        employerObligations: 'No legal obligation. Larger employers (BNP Paribas Fortis, '
            'Proximus) sometimes provide quiet rooms.',
        publicInstitutions: 'Universities: VUB, ULB, KU Leuven have prayer/quiet rooms. '
            'Some hospitals have multi-faith spaces.',
        airports: 'Brussels Airport (BRU) has interfaith prayer room in departure area.',
        universities: 'ULB Brussels, VUB, UCLouvain, KU Leuven all have dedicated spaces.',
      ),
      educationRights: ReligiousEducationRights(
        publicSchoolPolicy: 'Constitution Art 24: choice between religious instruction '
            '(Catholic, Protestant, Islamic, Orthodox, Jewish) or non-confessional ethics '
            '(morale laïque). Islamic RE available in French and Flemish Community schools.',
        optOutRight: 'Parents choose at enrollment between religion class or ethics class. '
            'Change possible at start of each school year.',
        alternativeEthicsClass: 'Non-confessional ethics (morale non confessionnelle) '
            'available as full alternative in all public schools.',
        religiousSchools: 'Extensive Catholic school network (libre). Islamic schools '
            'emerging (Lucerna College in Genk, Al Ghazali Brussels). '
            'State subsidized if meeting curriculum standards.',
      ),
      worshipRights: PlacesOfWorshipRights(
        permitProcess: 'Standard building permit (permis d\'urbanisme / stedenbouwkundige '
            'vergunning) through commune. Environmental impact review may be required.',
        zoningLaw: 'Religious buildings allowed in zones designated for community facilities. '
            'Some communes have been accused of using zoning to block mosque construction.',
        minaretRestrictions: 'No explicit ban. Subject to standard building regulations '
            'including height limits.',
        recentIssues: 'Belgian government revoked recognition of the Great Mosque of Brussels '
            '(managed by Saudi Arabia) in 2023 over extremism concerns. '
            'EMB (Exécutif des Musulmans de Belgique) restructured.',
      ),
      discriminationComplaints: DiscriminationComplaints(
        equalityBody: 'Unia (Interfederal Centre for Equal Opportunities)',
        contactInfo: 'Rue Royale 138, 1000 Brussels. Tel: +32 2 212 30 00. '
            'Free helpline: 0800 12 800',
        onlineFiling: 'https://www.unia.be/ — online complaint form in FR/NL/DE/EN',
        legalAidAvailable: 'Yes. Bureau d\'aide juridique / Bureau voor Juridische Bijstand '
            'provides free legal assistance. Unia can intervene in court proceedings.',
        timeLimit: '1 year for employment discrimination, 5 years for civil claims.',
      ),
      burialRights: BurialRights(
        islamicBurial: 'Islamic burial sections exist in Brussels (Schaerbeek cemetery), '
            'Antwerp, Liège, Charleroi. Burial without coffin permitted in some communes. '
            'Mecca-facing orientation accommodated in dedicated sections.',
        jewishBurial: 'Jewish cemeteries in Brussels (Kraainem), Antwerp, Liège. '
            'Long-established community manages burial.',
        dedicatedSections: 'Increasingly available. Flemish decree 2004 requires communes '
            'to designate multicultural sections on request.',
        repatriationOfRemains: 'Permitted. Consular agreements with Morocco, Turkey facilitate '
            'repatriation. AMIF (Aide aux Musulmans en cas d\'Invalidité et de Funérailles) '
            'assists with logistics. Cost: €3,000-€7,000.',
        embalming: 'Not required by law. Religious preparation of body permitted.',
      ),
      chaplaincyRights: ChaplaincyRights(
        prisons: 'Muslim chaplains (conseillers islamiques) employed by federal government '
            'in all prisons since Islam is a recognized religion. ~30 Islamic counselors.',
        hospitals: 'Recognized religions entitled to provide hospital chaplaincy. '
            'Paid by federal government. Islamic spiritual care expanding.',
        military: 'Muslim military chaplain (aumônier militaire islamique) appointed. '
            'Part of official military chaplaincy corps.',
        multiReligious: 'Belgium funds chaplaincy for all six recognized religions plus '
            'non-confessional moral counselors (conseillers laïques).',
      ),
      immigrantSpecificNotes: 'Belgium recognized Islam in 1974 but the institutional framework '
          '(EMB) has been repeatedly restructured. Ritual slaughter bans in Flanders and Wallonia '
          'significantly affect Muslim and Jewish communities — Brussels remains the exception. '
          'Strong anti-discrimination framework through Unia. Significant Muslim population '
          '(~7% of total) means services are relatively well-developed in major cities. '
          'Achbita CJEU case originated in Belgium and shapes EU-wide headscarf jurisprudence.',
    ),

    // ========================================================================
    // 3. BULGARIA (BG)
    // ========================================================================
    ReligiousRightsInfo(
      country: 'Bulgaria',
      countryCode: 'BG',
      legalBasis: 'Constitution Art 13, 37 (freedom of conscience and religion); '
          'Religious Denominations Act 2002 (Закон за вероизповеданията); '
          'Protection Against Discrimination Act 2003.',
      constitutionalProvision: 'Art 13: Freedom of religion is inviolable. Eastern Orthodox '
          'Christianity is the "traditional religion." Art 37: Freedom of conscience, thought, '
          'and religion; right to perform rites.',
      foodAccess: HalalKosherAccess(
        schools: 'No systematic provision. Parents may send packed meals. '
            'Some schools in areas with Turkish/Muslim minorities (Kardzhali, Razgrad) '
            'provide pork-free options.',
        hospitals: 'No formal policy. Hospitals generally accommodate dietary requests '
            'on individual basis.',
        prisons: 'Prisons expected to accommodate religious dietary needs under European '
            'Prison Rules. Practice is inconsistent.',
        military: 'No formal halal provision. Vegetarian alternatives available.',
        generalAvailability: 'Halal food available in areas with Muslim population '
            '(northeastern Bulgaria, Rhodope region). Limited in Sofia.',
        slaughterLaw: 'Ritual slaughter permitted with exemption from stunning requirement '
            'under Regulation (EC) 1099/2009 implementation.',
      ),
      holidayRights: ReligiousHolidayRights(
        legalFramework: 'Labour Code (Кодекс на труда) Art 154. Religious holidays for '
            'non-Orthodox denominations: employees may take days off.',
        employeeRights: 'Art 173 Labour Code allows use of annual leave for religious holidays. '
            'No specific statutory right to non-Orthodox holidays.',
        publicSectorPolicy: 'Civil Servants Act does not provide specific non-Orthodox holiday rights.',
        keyHolidays: 'Public holidays are secular and Orthodox Christian (Easter, Christmas). '
            'Bayram (Eid) widely observed informally in Muslim-majority areas.',
      ),
      clothingRights: ReligiousClothingRights(
        workplace: 'No specific legislation. Generally permitted unless employer has '
            'justified safety requirements.',
        publicSchools: 'Headscarf debate ongoing. No national ban. Some schools have '
            'attempted local restrictions. Commission for Protection Against Discrimination '
            'has ruled against blanket bans.',
        governmentBuildings: 'No formal ban on religious clothing.',
        faceCoveringLaw: 'Full face covering ban enacted 2016 (Amendment to the law on '
            'limiting the wearing of clothing concealing the face). '
            'Fine: BGN 200 (first offense) to BGN 1,500 (repeat).',
        keyLegalCases: 'Commission for Protection Against Discrimination Decision 2006: '
            'school headscarf ban ruled discriminatory.',
      ),
      prayerRoomRights: PrayerRoomRights(
        employerObligations: 'No legal obligation.',
        publicInstitutions: 'No formal provision in most public buildings.',
        airports: 'Sofia Airport has no dedicated prayer room.',
        universities: 'No formal multi-faith prayer rooms in Bulgarian universities.',
      ),
      educationRights: ReligiousEducationRights(
        publicSchoolPolicy: 'Religious education is optional (elective subject). '
            'Islam taught in areas with Muslim populations, especially in Kardzhali, '
            'Razgrad, Shumen oblasts.',
        optOutRight: 'Fully optional — no opt-out needed as enrollment is by choice.',
        alternativeEthicsClass: 'No mandatory ethics alternative; RE is already elective.',
        religiousSchools: 'Muslim religious schools (медресета) operated by Chief Muftiate. '
            'Higher Islamic Institute in Sofia. State recognizes diplomas.',
      ),
      worshipRights: PlacesOfWorshipRights(
        permitProcess: 'Standard construction permit through municipality. Religious '
            'Denominations Act requires registration of religious community.',
        zoningLaw: 'Standard zoning applies. No specific restrictions on religious buildings.',
        minaretRestrictions: 'No explicit restrictions. Historic mosques protected as '
            'cultural heritage (Ottoman era).',
        recentIssues: 'Tensions around renovation of Ottoman-era mosques. Chief Muftiate '
            'disputes with alternative Muslim organizations. ECHR case: Supreme Holy Council '
            'of the Muslim Community v. Bulgaria (2004) — state interference in Muslim leadership.',
      ),
      discriminationComplaints: DiscriminationComplaints(
        equalityBody: 'Commission for Protection Against Discrimination '
            '(Комисия за защита от дискриминация)',
        contactInfo: 'Ul. Dragan Tsankov 35, 1797 Sofia. Tel: +359 2 807 3030',
        onlineFiling: 'https://www.kzd-nondiscrimination.com/ — complaints via email or post',
        legalAidAvailable: 'Yes. National Legal Aid Bureau provides free assistance. '
            'Bulgarian Helsinki Committee offers legal support for discrimination cases.',
        timeLimit: '3 years for discrimination claims under Protection Against Discrimination Act.',
      ),
      burialRights: BurialRights(
        islamicBurial: 'Muslim cemeteries exist in areas with Muslim populations. '
            'Chief Muftiate manages Islamic burial grounds. Shroud burial (without coffin) '
            'practiced in traditional Muslim areas.',
        jewishBurial: 'Jewish cemetery in Sofia (Central Sofia Jewish Cemetery). '
            'Small Jewish community. Organization of Jews in Bulgaria manages burial.',
        dedicatedSections: 'Available in cities with Muslim communities. Sofia has limited provision.',
        repatriationOfRemains: 'Permitted. Consular assistance available through Turkish, '
            'Middle Eastern embassies. Cost variable.',
        embalming: 'Not required by law for domestic burial.',
      ),
      chaplaincyRights: ChaplaincyRights(
        prisons: 'Religious access guaranteed under Execution of Penalties Act. '
            'Muslim imams can visit upon prisoner request. Not systematically organized.',
        hospitals: 'No formal chaplaincy program. Religious leaders may visit on request.',
        military: 'Orthodox chaplaincy reintroduced in 2003. No formal Muslim military chaplaincy.',
        multiReligious: 'Multi-faith chaplaincy is underdeveloped. Orthodox Church has privileged position.',
      ),
      immigrantSpecificNotes: 'Bulgaria has a historic Muslim minority (~12% of population, '
          'mainly ethnic Turks and Pomaks) with established infrastructure. Immigrants from '
          'other Muslim countries may find less developed services. The Chief Muftiate is the '
          'official Islamic representative body. Face covering ban enacted 2016. '
          'ECHR has ruled against Bulgaria for state interference in Muslim community leadership.',
    ),

    // ========================================================================
    // 4. CROATIA (HR)
    // ========================================================================
    ReligiousRightsInfo(
      country: 'Croatia',
      countryCode: 'HR',
      legalBasis: 'Constitution Art 40-41 (freedom of conscience and religion); '
          'Legal Status of Religious Communities Act 2002 (Zakon o pravnom položaju '
          'vjerskih zajednica); Anti-Discrimination Act 2008.',
      constitutionalProvision: 'Art 40: Freedom of conscience and religion. Art 41: '
          'Religious communities equal before law, separated from state. '
          'Concordat with Holy See (1996-1998). Agreements with 19 other religious '
          'communities including Islamic Community.',
      foodAccess: HalalKosherAccess(
        schools: 'No systematic halal/kosher provision. Schools generally offer '
            'meat-free alternatives.',
        hospitals: 'Hospitals accommodate dietary requests on individual basis.',
        prisons: 'Prison administration must respect religious dietary needs under '
            'Execution of Prison Sentences Act.',
        military: 'Croatian Armed Forces accommodate dietary needs on request.',
        generalAvailability: 'Limited halal options. Available in Zagreb through '
            'specialized shops. Islamic Community of Croatia provides guidance.',
        slaughterLaw: 'Ritual slaughter with exemption from stunning permitted under '
            'Animal Protection Act implementation of EU regulations.',
      ),
      holidayRights: ReligiousHolidayRights(
        legalFramework: 'Labour Act (Zakon o radu). Religious holidays for registered '
            'communities recognized through bilateral agreements.',
        employeeRights: 'Employees may use annual leave for religious holidays. '
            'Agreement with Islamic Community provides for Eid recognition.',
        publicSectorPolicy: 'Civil Servants Act allows flexible scheduling for religious holidays.',
        keyHolidays: '13 public holidays include Catholic holidays. Bajram (Eid) not a public holiday.',
      ),
      clothingRights: ReligiousClothingRights(
        workplace: 'No specific legislation. Generally permitted. '
            'Anti-Discrimination Act protects against religious discrimination in employment.',
        publicSchools: 'No ban on religious clothing. Hijab generally permitted.',
        governmentBuildings: 'No formal restrictions on religious clothing.',
        faceCoveringLaw: 'No face covering ban.',
        keyLegalCases: 'Limited case law on religious clothing. Ombudsman has addressed '
            'individual complaints.',
      ),
      prayerRoomRights: PrayerRoomRights(
        employerObligations: 'No legal obligation.',
        publicInstitutions: 'No formal provision.',
        airports: 'Zagreb Airport has no dedicated prayer room.',
        universities: 'University of Zagreb has no formal multi-faith prayer room.',
      ),
      educationRights: ReligiousEducationRights(
        publicSchoolPolicy: 'Religious education available as optional subject. '
            'Catholic RE dominant. Islamic RE available where demand exists.',
        optOutRight: 'Fully optional — parents choose at enrollment.',
        alternativeEthicsClass: 'No mandatory ethics alternative; RE is elective.',
        religiousSchools: 'Catholic schools widespread. No Islamic schools. '
            'Medresa possible through Islamic Community.',
      ),
      worshipRights: PlacesOfWorshipRights(
        permitProcess: 'Standard building permit through municipal authorities. '
            'Religious community must be registered.',
        zoningLaw: 'Standard urban planning regulations apply.',
        minaretRestrictions: 'No explicit restrictions. Zagreb mosque (opened 1987) '
            'is the main Islamic center.',
        recentIssues: 'Islamic Community of Croatia has relatively small membership (~60,000). '
            'Some local opposition to new mosque construction.',
      ),
      discriminationComplaints: DiscriminationComplaints(
        equalityBody: 'Ombudsman (Pučki pravobranitelj) and specialized offices',
        contactInfo: 'Savska cesta 41/3, 10000 Zagreb. Tel: +385 1 4851 855',
        onlineFiling: 'https://www.ombudsman.hr/ — complaint form available',
        legalAidAvailable: 'Yes. Free Legal Aid Act 2008. Centre for Peace Studies '
            'provides assistance for discrimination cases.',
        timeLimit: '3 years for discrimination claims under Anti-Discrimination Act.',
      ),
      burialRights: BurialRights(
        islamicBurial: 'Islamic cemetery section in Zagreb (Mirogoj). Islamic Community '
            'manages burial according to Islamic rites.',
        jewishBurial: 'Jewish section in Mirogoj cemetery, Zagreb. '
            'Jewish Community of Zagreb manages burial.',
        dedicatedSections: 'Available in Zagreb. Limited in other cities.',
        repatriationOfRemains: 'Permitted under standard regulations. Consular assistance available.',
        embalming: 'Not required by law.',
      ),
      chaplaincyRights: ChaplaincyRights(
        prisons: 'Religious access guaranteed. Islamic Community can provide spiritual '
            'care upon prisoner request.',
        hospitals: 'Catholic chaplaincy dominant. Other religions accommodated on request.',
        military: 'Catholic military chaplaincy established. No formal Islamic military chaplaincy.',
        multiReligious: 'Multi-faith approach developing but Catholic Church has dominant position.',
      ),
      immigrantSpecificNotes: 'Croatia has a small but established Muslim community (mainly Bosniaks). '
          'Islamic Community of Croatia (Islamska zajednica u Hrvatskoj) is the official body. '
          'Religious freedom generally respected but infrastructure for non-Christian religions '
          'is limited. No face-covering ban. Anti-Discrimination Act provides protection. '
          'Country is a newer EU member (2013) still developing immigrant integration services.',
    ),

    // ========================================================================
    // 5. CYPRUS (CY)
    // ========================================================================
    ReligiousRightsInfo(
      country: 'Cyprus',
      countryCode: 'CY',
      legalBasis: 'Constitution Art 18 (freedom of religion); '
          'Law on Religious Groups 1960; Equal Treatment in Employment Law 2004 '
          '(transposing Directive 2000/78/EC).',
      constitutionalProvision: 'Art 18: Every person has the right to freedom of thought, '
          'conscience and religion. Three religious groups constitutionally recognized: '
          'Maronites, Armenian-Apostolic, Latin (Roman Catholic). Islam recognized through '
          'Turkish Cypriot community provisions.',
      foodAccess: HalalKosherAccess(
        schools: 'Limited formal provision. Some schools accommodate upon request.',
        hospitals: 'Hospitals accommodate dietary requests individually.',
        prisons: 'Prison Service accommodates religious dietary needs.',
        military: 'National Guard accommodates dietary requests.',
        generalAvailability: 'Halal food available in Larnaca, Limassol (areas with larger '
            'Muslim populations from immigration). Growing availability.',
        slaughterLaw: 'Ritual slaughter permitted with exemptions under Animal Welfare Law.',
      ),
      holidayRights: ReligiousHolidayRights(
        legalFramework: 'Annual Leave Law. Public holidays are Orthodox Christian and secular.',
        employeeRights: 'Employees may use annual leave for non-Orthodox religious holidays.',
        publicSectorPolicy: 'Recognized religious groups have some holiday provisions.',
        keyHolidays: 'Public holidays follow Greek Orthodox calendar. No Muslim holidays.',
      ),
      clothingRights: ReligiousClothingRights(
        workplace: 'No specific restrictions. Anti-discrimination law applies.',
        publicSchools: 'No ban on religious clothing.',
        governmentBuildings: 'No formal restrictions.',
        faceCoveringLaw: 'No face covering ban.',
        keyLegalCases: 'Limited case law. Equality Authority has handled some complaints.',
      ),
      prayerRoomRights: PrayerRoomRights(
        employerObligations: 'No legal obligation.',
        publicInstitutions: 'Limited provision.',
        airports: 'Larnaca Airport has no dedicated prayer room.',
        universities: 'University of Cyprus has no formal multi-faith room.',
      ),
      educationRights: ReligiousEducationRights(
        publicSchoolPolicy: 'Orthodox Christian religious education in public schools. '
            'Optional for non-Orthodox students.',
        optOutRight: 'Non-Orthodox students may be exempted.',
        alternativeEthicsClass: 'No formal ethics alternative in most schools.',
        religiousSchools: 'Armenian and Maronite schools exist. No Islamic schools in Republic.',
      ),
      worshipRights: PlacesOfWorshipRights(
        permitProcess: 'Standard planning permit through district administration.',
        zoningLaw: 'Standard urban planning regulations.',
        minaretRestrictions: 'No restrictions in law. Historic mosques in Republic-controlled '
            'areas maintained as cultural heritage.',
        recentIssues: 'Access to mosques in the north for Turkish Cypriots and vice versa '
            'for churches. Hala Sultan Tekke mosque in Larnaca is an important site.',
      ),
      discriminationComplaints: DiscriminationComplaints(
        equalityBody: 'Commissioner for Administration and Human Rights (Ombudsman) / '
            'Equality Authority',
        contactInfo: 'Era House, Diagorou 4, 1097 Nicosia. Tel: +357 22 405500',
        onlineFiling: 'http://www.ombudsman.gov.cy/ — complaint form available',
        legalAidAvailable: 'Yes. Legal Aid Law provides assistance based on income.',
        timeLimit: '6 months for Ombudsman complaints, 3 years for civil claims.',
      ),
      burialRights: BurialRights(
        islamicBurial: 'Muslim cemeteries exist in Larnaca and Limassol. '
            'Turkish Cypriot communities maintain cemeteries.',
        jewishBurial: 'Very small Jewish community. Arrangements made individually.',
        dedicatedSections: 'Muslim cemeteries maintained separately from Christian ones.',
        repatriationOfRemains: 'Permitted. Consular assistance available.',
        embalming: 'Not required by law.',
      ),
      chaplaincyRights: ChaplaincyRights(
        prisons: 'Religious access permitted. Imams can visit on request.',
        hospitals: 'Orthodox chaplaincy primary. Other religions accommodated on request.',
        military: 'Orthodox chaplaincy in National Guard.',
        multiReligious: 'Multi-faith approach limited. Orthodox Church has privileged position.',
      ),
      immigrantSpecificNotes: 'Cyprus has a unique religious landscape due to the division. '
          'Republic of Cyprus (Greek Cypriot) is predominantly Orthodox. Growing immigrant '
          'Muslim population (from South/Southeast Asia, Middle East, Africa). Infrastructure '
          'for Muslim immigrants is limited. No burqa ban. Generally tolerant but services '
          'for non-Orthodox religions are underdeveloped.',
    ),

    // ========================================================================
    // 6. CZECH REPUBLIC (CZ)
    // ========================================================================
    ReligiousRightsInfo(
      country: 'Czech Republic',
      countryCode: 'CZ',
      legalBasis: 'Charter of Fundamental Rights and Freedoms Art 15-16 (constitutional law); '
          'Act on Churches and Religious Societies 2002 (3/2002 Sb.); '
          'Anti-Discrimination Act 2009 (198/2009 Sb.).',
      constitutionalProvision: 'Art 15: Freedom of thought, conscience, religion. Art 16: '
          'Right to profess faith publicly or privately. Czech Republic is one of the most '
          'secular countries in Europe. 42 registered churches/religious societies.',
      foodAccess: HalalKosherAccess(
        schools: 'No systematic provision. Very low demand. Some Prague schools accommodate '
            'individual requests.',
        hospitals: 'Hospitals accommodate dietary requests individually.',
        prisons: 'Prison Service should accommodate under European Prison Rules. '
            'Practice limited due to very small Muslim population.',
        military: 'No formal provision. Individual accommodation possible.',
        generalAvailability: 'Very limited. Prague has some halal restaurants and shops '
            '(around Karlín). Kosher options through Jewish Community of Prague.',
        slaughterLaw: 'Ritual slaughter without stunning prohibited under Act on the '
            'Protection of Animals Against Cruelty (246/1992 Sb.). Halal/kosher meat imported.',
      ),
      holidayRights: ReligiousHolidayRights(
        legalFramework: 'Labour Code (262/2006 Sb.). No specific provisions for '
            'non-Christian religious holidays.',
        employeeRights: 'Employees use annual leave or unpaid leave for religious holidays. '
            'Employer should consider reasonable accommodation.',
        publicSectorPolicy: 'Civil Service Act allows flexible scheduling.',
        keyHolidays: '13 public holidays including some Christian holidays (Easter Monday, '
            'Christmas). Mostly secular/national holidays.',
      ),
      clothingRights: ReligiousClothingRights(
        workplace: 'No specific legislation. Generally permitted.',
        publicSchools: 'No ban on religious clothing. Very rare issue due to small Muslim population.',
        governmentBuildings: 'No formal restrictions.',
        faceCoveringLaw: 'No face covering ban despite political proposals.',
        keyLegalCases: 'Very limited case law on religious clothing.',
      ),
      prayerRoomRights: PrayerRoomRights(
        employerObligations: 'No legal obligation.',
        publicInstitutions: 'Very limited provision.',
        airports: 'Prague Airport (PRG) has an interfaith chapel in Terminal 2.',
        universities: 'Charles University and CTU have no formal prayer rooms.',
      ),
      educationRights: ReligiousEducationRights(
        publicSchoolPolicy: 'Religious education is optional, provided by registered '
            'churches/religious societies. Very low enrollment due to secularism.',
        optOutRight: 'Fully optional — enrollment is by parental choice.',
        alternativeEthicsClass: 'Ethics taught as part of civic education curriculum.',
        religiousSchools: 'Catholic and Protestant schools exist. No Islamic schools. '
            'Islamic Foundation (registered 2004) provides community education.',
      ),
      worshipRights: PlacesOfWorshipRights(
        permitProcess: 'Standard building permit through municipal building authority.',
        zoningLaw: 'Standard urban planning. No specific restrictions on religious buildings.',
        minaretRestrictions: 'No mosques with minarets currently in Czech Republic. '
            'Prague Islamic Centre operates without minaret.',
        recentIssues: 'Political opposition to mosque construction. Islamic Foundation in '
            'Czech Republic (Ústředí muslimských obcí) represents Muslim community. '
            'Proposal for mosque in Brno met local opposition.',
      ),
      discriminationComplaints: DiscriminationComplaints(
        equalityBody: 'Public Defender of Rights (Veřejný ochránce práv / Ombudsman)',
        contactInfo: 'Údolní 39, 602 00 Brno. Tel: +420 542 542 888',
        onlineFiling: 'https://www.ochrance.cz/ — online complaint form in CZ/EN',
        legalAidAvailable: 'Yes. Free legal aid through bar association program. '
            'Organization for Aid to Refugees (OPU) assists with discrimination.',
        timeLimit: '3 years for discrimination claims.',
      ),
      burialRights: BurialRights(
        islamicBurial: 'Very limited. No dedicated Islamic cemeteries. '
            'Some cemeteries in Prague accommodate Muslim burial practices.',
        jewishBurial: 'Historic Jewish cemeteries in Prague (Old Jewish Cemetery, '
            'New Jewish Cemetery). Jewish Community of Prague manages burial.',
        dedicatedSections: 'Prague municipal cemeteries can accommodate upon request.',
        repatriationOfRemains: 'Permitted under standard regulations.',
        embalming: 'Not required by law for domestic burial.',
      ),
      chaplaincyRights: ChaplaincyRights(
        prisons: 'Prison chaplaincy available for registered religious communities. '
            'Muslim spiritual care very limited.',
        hospitals: 'Hospital chaplaincy developing. Primarily Christian.',
        military: 'Military chaplaincy (Catholic, Protestant, Hussite). No Muslim chaplaincy.',
        multiReligious: 'Multi-faith approach limited by very small non-Christian populations.',
      ),
      immigrantSpecificNotes: 'Czech Republic is one of the most secular and skeptical-of-Islam '
          'countries in the EU. Very small Muslim population (~20,000). Infrastructure for '
          'Islamic practice is minimal. No face covering ban despite political pressure. '
          'Ritual slaughter banned — halal/kosher meat must be imported. Islamic Foundation '
          'registered since 2004. Generally tolerant legal framework but public attitudes '
          'can be unwelcoming. Anti-Discrimination Act provides basic protection.',
    ),

    // ========================================================================
    // 7. DENMARK (DK)
    // ========================================================================
    ReligiousRightsInfo(
      country: 'Denmark',
      countryCode: 'DK',
      legalBasis: 'Constitution §67-70 (freedom of religion); '
          'Act on Equal Treatment 1996; Anti-Discrimination Act. '
          'Evangelical Lutheran Church is state church (§4 Constitution).',
      constitutionalProvision: '§67: Citizens have right to worship God according to conviction. '
          '§70: No deprivation of civic rights due to faith. Evangelical Lutheran Church '
          'supported by state (§4). Other religions are "approved" (godkendte) or "recognized."',
      foodAccess: HalalKosherAccess(
        schools: 'Municipalities decide. Many schools in Copenhagen, Aarhus offer '
            'halal or pork-free options.',
        hospitals: 'Hospitals accommodate dietary requests. Copenhagen University Hospital '
            '(Rigshospitalet) provides halal options.',
        prisons: 'Danish Prison and Probation Service (Kriminalforsorgen) provides '
            'religiously compliant meals. Required under institutional regulations.',
        military: 'Danish Defence accommodates dietary needs.',
        generalAvailability: 'Widely available in Copenhagen, Aarhus, Odense. '
            'Well-established halal food industry.',
        slaughterLaw: 'Ritual slaughter without prior stunning banned since 2014. '
            'Halal meat (stunned before slaughter) produced domestically. '
            'Imports of non-stunned meat permitted.',
      ),
      holidayRights: ReligiousHolidayRights(
        legalFramework: 'Holiday Act (Ferieloven). No statutory right to non-Christian holidays.',
        employeeRights: 'Employees may negotiate leave for religious holidays. '
            'Use annual leave or unpaid leave. Some collective agreements include provisions.',
        publicSectorPolicy: 'Public sector may allow flexible scheduling.',
        keyHolidays: 'Public holidays are Christian (Easter, Christmas, Ascension, etc.). '
            'No Muslim or Jewish public holidays.',
      ),
      clothingRights: ReligiousClothingRights(
        workplace: 'Permitted unless employer demonstrates objective justification for '
            'restrictions. Board of Equal Treatment has ruled on multiple headscarf cases.',
        publicSchools: 'No ban on hijab in schools.',
        governmentBuildings: 'No general ban. Court interpreters and judges expected to '
            'appear neutral — debated but no formal prohibition.',
        faceCoveringLaw: 'Face covering ban enacted 2018 ("Burka ban"). '
            'Fine: DKK 1,000 (first offense) to DKK 10,000 (fourth offense).',
        keyLegalCases: 'Føtex case (Supreme Court 2005): employer could restrict headscarf '
            'under general dress code policy. Widely cited in Danish employment law.',
      ),
      prayerRoomRights: PrayerRoomRights(
        employerObligations: 'No legal obligation. Some employers provide quiet rooms.',
        publicInstitutions: 'Limited. Some hospitals have multi-faith rooms.',
        airports: 'Copenhagen Airport (CPH) has interfaith prayer room in Terminal 3.',
        universities: 'University of Copenhagen, Aarhus University have multi-faith spaces.',
      ),
      educationRights: ReligiousEducationRights(
        publicSchoolPolicy: 'Non-confessional "Christianity Studies" (Kristendomskundskab) '
            'mandatory in Folkeskole. Focuses on knowledge, not practice.',
        optOutRight: 'Parents may withdraw children from Christianity Studies if they can '
            'document equivalent instruction. Rarely exercised.',
        alternativeEthicsClass: 'No separate ethics class; Christianity Studies is intended '
            'to be non-confessional and cover world religions.',
        religiousSchools: 'Free schools (friskoler) may be religious. Islamic free schools exist '
            '(e.g., Nord-Vest Privatskole). State funded at ~76% of public school cost. '
            'Recent scrutiny and closures of some Islamic schools.',
      ),
      worshipRights: PlacesOfWorshipRights(
        permitProcess: 'Standard building permit through municipality (kommune).',
        zoningLaw: 'Planning Act (Planloven). Religious buildings subject to local plan.',
        minaretRestrictions: 'No explicit ban. Subject to building regulations.',
        recentIssues: 'Controversy over foreign-funded mosques. Law on financial transparency '
            'for religious organizations enacted. Some political pressure against new mosques.',
      ),
      discriminationComplaints: DiscriminationComplaints(
        equalityBody: 'Board of Equal Treatment (Ligebehandlingsnævnet)',
        contactInfo: 'Nævnenes Hus, Toldboden 2, 8800 Viborg. Tel: +45 72 40 50 00',
        onlineFiling: 'https://ast.dk/naevn/ligebehandlingsnaevnet — online form',
        legalAidAvailable: 'Yes. Danish Institute for Human Rights provides guidance. '
            'Free legal aid (fri proces) based on income.',
        timeLimit: 'No statutory time limit for Board complaints. Civil claims: 5 years.',
      ),
      burialRights: BurialRights(
        islamicBurial: 'Islamic burial sections in Copenhagen (Brøndby Muslim Cemetery, '
            'opened 2006 — Denmark\'s first purpose-built). Sections in Aarhus, Odense.',
        jewishBurial: 'Jewish cemetery in Copenhagen (Mosaisk Vestre Begravelsesplads). '
            'Jewish Community manages burial.',
        dedicatedSections: 'Brøndby Muslim Cemetery is the primary Islamic burial facility. '
            'Municipalities increasingly allocating sections.',
        repatriationOfRemains: 'Permitted. Well-established process. '
            'Islamic Burial Fund Denmark assists. Cost: DKK 20,000-50,000.',
        embalming: 'Not required by law. Body may be prepared according to religious rites.',
      ),
      chaplaincyRights: ChaplaincyRights(
        prisons: 'Prison chaplaincy includes Muslim imams since 2006. '
            'Imams employed by Prison Service in major facilities.',
        hospitals: 'Hospital chaplains primarily Lutheran. Muslim spiritual care '
            'available on request in major hospitals.',
        military: 'Lutheran military chaplaincy. No formal Muslim military chaplaincy, '
            'but accommodation possible.',
        multiReligious: 'Developing multi-faith approach. Imam training program at '
            'University of Copenhagen supports integration.',
      ),
      immigrantSpecificNotes: 'Denmark has one of Europe\'s strictest immigration policies but '
          'protects religious freedom constitutionally. Face covering ban since 2018. Ritual '
          'slaughter without stunning banned since 2014. Islamic free schools under increased '
          'scrutiny — several closed for alleged anti-democratic values. Brøndby Muslim Cemetery '
          'was a landmark achievement. Political climate can be challenging for Muslim immigrants '
          'but legal protections through Board of Equal Treatment are solid.',
    ),

    // ========================================================================
    // 8. ESTONIA (EE)
    // ========================================================================
    ReligiousRightsInfo(
      country: 'Estonia',
      countryCode: 'EE',
      legalBasis: 'Constitution §40-41 (freedom of religion); '
          'Churches and Congregations Act 2002; Equal Treatment Act 2008.',
      constitutionalProvision: '§40: Everyone has freedom of conscience, religion, and thought. '
          '§41: Right to remain faithful to opinions and convictions. '
          'No state church. One of most secular countries in Europe.',
      foodAccess: HalalKosherAccess(
        schools: 'No formal provision. Very limited demand.',
        hospitals: 'Individual accommodation possible upon request.',
        prisons: 'Prisons should accommodate under European Prison Rules. Very limited practice.',
        military: 'No formal provision.',
        generalAvailability: 'Very limited. Some halal options in Tallinn. '
            'Small Muslim community (~2,000-5,000).',
        slaughterLaw: 'Ritual slaughter without stunning prohibited under Animal Protection Act.',
      ),
      holidayRights: ReligiousHolidayRights(
        legalFramework: 'Employment Contracts Act. No specific non-Christian holiday provisions.',
        employeeRights: 'Annual leave used for religious holidays.',
        publicSectorPolicy: 'No specific provisions.',
        keyHolidays: 'Public holidays include Christmas and some Christian days. '
            'Also secular holidays. No Muslim holidays.',
      ),
      clothingRights: ReligiousClothingRights(
        workplace: 'No specific restrictions. Equal Treatment Act covers religious discrimination.',
        publicSchools: 'No ban on religious clothing.',
        governmentBuildings: 'No formal restrictions.',
        faceCoveringLaw: 'No face covering ban.',
        keyLegalCases: 'Very limited case law due to small religious minority populations.',
      ),
      prayerRoomRights: PrayerRoomRights(
        employerObligations: 'No legal obligation.',
        publicInstitutions: 'No formal provision.',
        airports: 'Tallinn Airport has no dedicated prayer room.',
        universities: 'No formal multi-faith rooms in Estonian universities.',
      ),
      educationRights: ReligiousEducationRights(
        publicSchoolPolicy: 'Religious education is optional, non-confessional. '
            'Rarely offered due to low demand in this very secular country.',
        optOutRight: 'Fully optional.',
        alternativeEthicsClass: 'Ethics integrated into social studies curriculum.',
        religiousSchools: 'Some Lutheran and Orthodox schools. No Islamic schools.',
      ),
      worshipRights: PlacesOfWorshipRights(
        permitProcess: 'Standard building permit through local government.',
        zoningLaw: 'Planning Act applies. No specific restrictions on religious buildings.',
        minaretRestrictions: 'No restrictions. No purpose-built mosques currently in Estonia.',
        recentIssues: 'Estonian Islamic Centre in Tallinn operates from converted premises. '
            'Plans for purpose-built mosque discussed but not realized.',
      ),
      discriminationComplaints: DiscriminationComplaints(
        equalityBody: 'Gender Equality and Equal Treatment Commissioner '
            '(Soolise võrdõiguslikkuse ja võrdse kohtlemise volinik)',
        contactInfo: 'Roosikrantsi 8b, 10119 Tallinn. Tel: +372 626 9259',
        onlineFiling: 'https://volinik.ee/ — complaint form available',
        legalAidAvailable: 'Yes. State legal aid available. Estonian Human Rights Centre '
            'provides free counseling.',
        timeLimit: '1 year for discrimination complaints to Commissioner.',
      ),
      burialRights: BurialRights(
        islamicBurial: 'Very limited. Small section in Tallinn cemeteries. '
            'Muslim community arranges burial individually.',
        jewishBurial: 'Jewish section in Rahumäe cemetery, Tallinn.',
        dedicatedSections: 'Very limited availability.',
        repatriationOfRemains: 'Permitted under standard regulations.',
        embalming: 'Not required by law.',
      ),
      chaplaincyRights: ChaplaincyRights(
        prisons: 'Religious visitors permitted. Chaplaincy program primarily Christian.',
        hospitals: 'No formal chaplaincy program. Religious visitors allowed.',
        military: 'Lutheran chaplaincy in Estonian Defence Forces.',
        multiReligious: 'Very limited due to small non-Christian populations.',
      ),
      immigrantSpecificNotes: 'Estonia is one of Europe\'s most secular countries with a very '
          'small Muslim population. Infrastructure for Islamic practice is minimal. '
          'No face covering ban, no specific restrictions on religious clothing. '
          'Legal framework provides basic protection against discrimination. '
          'Estonian Islamic Centre in Tallinn is the primary institution. '
          'Ritual slaughter without stunning is banned.',
    ),

    // ========================================================================
    // 9. FINLAND (FI)
    // ========================================================================
    ReligiousRightsInfo(
      country: 'Finland',
      countryCode: 'FI',
      legalBasis: 'Constitution §11 (freedom of religion and conscience); '
          'Freedom of Religion Act 2003 (453/2003); '
          'Non-Discrimination Act 2014 (1325/2014); '
          'Act on the Evangelical Lutheran Church; Act on the Orthodox Church.',
      constitutionalProvision: '§11: Freedom of religion and conscience includes the right to '
          'profess and practice a religion, to express convictions, and to belong or not to '
          'a religious community. Two national churches: Evangelical Lutheran and Orthodox.',
      foodAccess: HalalKosherAccess(
        schools: 'Schools must accommodate special diets including religious diets under '
            'Basic Education Act. Helsinki, Espoo, Vantaa, Turku, Tampere regularly '
            'provide halal options in school meals.',
        hospitals: 'Public hospitals accommodate dietary needs. HUS (Helsinki University '
            'Hospital) and other major hospitals provide halal options on request.',
        prisons: 'Criminal Sanctions Agency (Rikosseuraamuslaitos) required to provide '
            'religiously compliant meals. Halal meals available in all prisons.',
        military: 'Finnish Defence Forces provide halal meals for Muslim conscripts/soldiers.',
        generalAvailability: 'Available in Helsinki, Espoo, Turku, Tampere. '
            'Growing halal food industry. Finnish Islamic Council provides guidance.',
        slaughterLaw: 'Ritual slaughter without prior stunning prohibited under Animal '
            'Welfare Act (247/1996). Halal meat (post-stunning) produced domestically. '
            'Imports of non-stunned meat permitted.',
      ),
      holidayRights: ReligiousHolidayRights(
        legalFramework: 'Employment Contracts Act (55/2001) and collective agreements. '
            'No statutory right to non-Christian religious holidays.',
        employeeRights: 'Employees may negotiate leave for religious holidays. Annual leave '
            'or unpaid leave used. Non-Discrimination Act requires reasonable accommodation. '
            'Non-Discrimination Ombudsman has emphasized employer flexibility.',
        publicSectorPolicy: 'State Employer\'s Office recommends flexible scheduling for '
            'employees of different faiths.',
        keyHolidays: 'Public holidays are Christian/secular (Easter, Christmas, Midsummer, etc.). '
            'No Muslim or Jewish public holidays.',
      ),
      clothingRights: ReligiousClothingRights(
        workplace: 'Generally permitted. Non-Discrimination Act 2014 protects against '
            'religious discrimination. Employer restrictions must be proportionate '
            'and based on genuine occupational requirements.',
        publicSchools: 'No ban on hijab or religious clothing in schools. '
            'Non-Discrimination Ombudsman has confirmed this.',
        governmentBuildings: 'No ban. Public servants may wear religious clothing. '
            'Police officers may wear hijab under uniform policy accommodations.',
        faceCoveringLaw: 'No face covering ban. Proposed in 2018 parliament but not enacted.',
        keyLegalCases: 'Non-Discrimination Ombudsman case 2017: employer could not dismiss '
            'employee for wearing hijab without objective justification.',
      ),
      prayerRoomRights: PrayerRoomRights(
        employerObligations: 'No legal obligation but Non-Discrimination Act encourages '
            'reasonable accommodation. Many larger employers provide quiet rooms.',
        publicInstitutions: 'Some hospitals and public buildings have multi-faith quiet rooms.',
        airports: 'Helsinki-Vantaa Airport (HEL) has interfaith prayer room.',
        universities: 'University of Helsinki, Aalto University, University of Turku '
            'have multi-faith prayer/quiet rooms.',
      ),
      educationRights: ReligiousEducationRights(
        publicSchoolPolicy: 'Religious education based on student\'s own religion when group '
            'size ≥3 in a municipality. Islamic RE taught in Helsinki, Espoo, Turku, Tampere. '
            'Taught by qualified teachers approved by FISU (Finnish Islamic Council).',
        optOutRight: 'Students belonging to no religious community take Ethics class. '
            'Parents of children in religious communities can request Ethics instead. '
            'Students 18+ choose independently.',
        alternativeEthicsClass: 'Ethics (Elämänkatsomustieto) as full alternative to religious '
            'education. Well-developed curriculum covering world philosophies.',
        religiousSchools: 'No Islamic schools currently. Al-Risala educational activities. '
            'Private religious schools possible under Private Education Providers Act.',
      ),
      worshipRights: PlacesOfWorshipRights(
        permitProcess: 'Standard building permit through municipal building authority '
            '(rakennusvalvonta). Must comply with Land Use and Building Act.',
        zoningLaw: 'Religious buildings classified as public service buildings. '
            'Must conform to local detailed plan (asemakaava).',
        minaretRestrictions: 'No specific restrictions. Tattariharju mosque in Helsinki '
            'planned to include minaret (under discussion).',
        recentIssues: 'Helsinki Islamic Center (Masjid al-Huda) in Sörnäinen. '
            'Discussion about purpose-built central mosque for Helsinki ongoing. '
            'Some local opposition in suburban areas.',
      ),
      discriminationComplaints: DiscriminationComplaints(
        equalityBody: 'Non-Discrimination Ombudsman (Yhdenvertaisuusvaltuutettu)',
        contactInfo: 'P.O. Box 24, 00023 Government, Helsinki. Tel: +358 295 666 817',
        onlineFiling: 'https://syrjinta.fi/en/ — online complaint form in FI/SV/EN',
        legalAidAvailable: 'Yes. Public legal aid (oikeusapu) based on income. '
            'Victim Support Finland (RIKU) provides free assistance. '
            'Finnish League for Human Rights offers guidance.',
        timeLimit: '2 years for discrimination complaints to National Non-Discrimination '
            'and Equality Tribunal. Civil claims: 3 years general limitation.',
      ),
      burialRights: BurialRights(
        islamicBurial: 'Islamic burial section in Helsinki (Honkanummi cemetery, opened 2012). '
            'Sections in Turku and Tampere. Burial in shroud (without coffin) permitted '
            'in designated sections. Mecca-facing orientation accommodated.',
        jewishBurial: 'Jewish cemetery section in Helsinki (Hietaniemi). '
            'Jewish Community of Helsinki manages burial.',
        dedicatedSections: 'Available in Helsinki, Turku, Tampere, Oulu. '
            'Municipalities expanding Islamic sections on demand.',
        repatriationOfRemains: 'Permitted. Finnish Islamic Council assists with logistics. '
            'Some Islamic burial funds available through mosques. Cost: €3,000-€8,000.',
        embalming: 'Not required by Finnish law. Religious preparation permitted.',
      ),
      chaplaincyRights: ChaplaincyRights(
        prisons: 'Muslim chaplaincy (vankilaimaamit) available in prisons with significant '
            'Muslim populations. Criminal Sanctions Agency coordinates with Islamic organizations.',
        hospitals: 'Hospital chaplaincy traditionally Lutheran/Orthodox. Multi-faith '
            'spiritual care developing. HUS has guidelines for non-Christian pastoral care.',
        military: 'Lutheran and Orthodox military chaplaincy established. '
            'No formal Muslim military chaplaincy but accommodation provided for Muslim conscripts.',
        multiReligious: 'Multi-faith chaplaincy training program at University of Helsinki. '
            'USKOT Forum promotes interfaith dialogue.',
      ),
      immigrantSpecificNotes: 'Finland has a growing Muslim population (~100,000-120,000, ~2% of '
          'population). Strong legal framework through Non-Discrimination Act 2014 and Freedom '
          'of Religion Act 2003. No face covering ban. Ritual slaughter without stunning banned '
          'but imported meat permitted. School meal accommodation is legally required. '
          'Islamic religious education available in major cities. Honkanummi Islamic cemetery '
          'section was a significant development. Finnish Islamic Council (FISU) is key '
          'representative body. Integration services support religious practice. '
          'Non-Discrimination Ombudsman actively handles religious discrimination cases.',
    ),

    // ========================================================================
    // 10. FRANCE (FR)
    // ========================================================================
    ReligiousRightsInfo(
      country: 'France',
      countryCode: 'FR',
      legalBasis: 'Constitution Art 1 (laïcité); Law of 9 December 1905 (Separation of '
          'Churches and State); Law of 24 August 2021 (Loi confortant le respect des principes '
          'de la République — "Separatism Law"); Penal Code Art 225-1 (discrimination).',
      constitutionalProvision: 'Art 1: France is an indivisible, secular (laïque) Republic. '
          'It ensures equality before the law regardless of religion. It respects all beliefs. '
          'Laïcité is a constitutional principle — strict separation of state and religion.',
      foodAccess: HalalKosherAccess(
        schools: 'Public schools generally offer alternative menus (without pork) but '
            'no obligation to provide certified halal or kosher meals. '
            'Varies by municipality. Some cities removed pork-free options (political controversy).',
        hospitals: 'Public hospitals (AP-HP) accommodate dietary requests. No obligation '
            'for halal/kosher certified meals but pork-free alternatives provided.',
        prisons: 'Administration pénitentiaire provides pork-free meals. Not always certified '
            'halal. Conseil d\'État ruled (2013) that prisons not obligated to provide '
            'strictly halal meals but must offer alternatives.',
        military: 'French Armed Forces provide alternative menus. Not certified halal.',
        generalAvailability: 'France has Europe\'s largest halal market. Widely available '
            'nationwide. Major certification bodies: AVS, ARGML, Mosquée de Paris.',
        slaughterLaw: 'Ritual slaughter without stunning permitted under dérogation in '
            'Code rural Art R214-70. Must be performed in approved slaughterhouses. '
            'Repeated political debates but exemption maintained.',
      ),
      holidayRights: ReligiousHolidayRights(
        legalFramework: 'Code du travail. 11 public holidays, mostly Catholic-origin. '
            'No statutory right to non-Christian religious holidays.',
        employeeRights: 'Employees may request absence for religious holidays. Employer '
            'should accommodate unless operational necessity prevents it. '
            'Cour de cassation: refusal must be objectively justified.',
        publicSectorPolicy: 'Circular of 10 February 2012: public servants may request '
            'absence for non-Christian religious holidays (Eid, Yom Kippur, Diwali, etc.) '
            'subject to operational needs. Published annually in Journal Officiel.',
        keyHolidays: '11 public holidays (Easter, Ascension, Assumption, All Saints, Christmas). '
            'Alsace-Moselle region has Good Friday and St. Stephen\'s Day additionally.',
      ),
      clothingRights: ReligiousClothingRights(
        workplace: 'Private sector: employer can restrict if justified by genuine occupational '
            'requirement or documented in internal regulations (règlement intérieur). '
            'Cour de cassation Baby Loup case (2014): employer neutrality upheld.',
        publicSchools: 'Law of 15 March 2004: conspicuous religious symbols banned in '
            'public primary and secondary schools. Includes hijab, large crosses, kippah. '
            'Discreet symbols permitted. Does not apply to universities.',
        governmentBuildings: 'Public servants must observe strict religious neutrality '
            '(obligation de neutralité). No visible religious symbols while on duty.',
        faceCoveringLaw: 'Law of 11 October 2010: full face covering banned in public spaces '
            '(niqab/burqa). Fine: €150. Upheld by ECHR in S.A.S. v. France (2014).',
        keyLegalCases: 'S.A.S. v. France (ECHR 2014): face covering ban upheld. '
            'Loi de 2004 on school symbols — Conseil d\'État and Conseil constitutionnel '
            'upheld. Baby Loup (Cass. 2014): private crèche neutrality policy valid.',
      ),
      prayerRoomRights: PrayerRoomRights(
        employerObligations: 'No obligation under laïcité. Employer may provide but not required. '
            'Some companies provide multi-faith rooms voluntarily.',
        publicInstitutions: 'Hospital chapels exist historically. Multi-faith rooms in some '
            'newer facilities.',
        airports: 'Paris CDG has interfaith prayer rooms in all terminals. '
            'Orly also has prayer facilities.',
        universities: 'No formal prayer rooms in public universities (laïcité principle). '
            'Some student organizations arrange informal spaces.',
      ),
      educationRights: ReligiousEducationRights(
        publicSchoolPolicy: 'No religious education in public schools (laïcité). '
            '"Fait religieux" (religious facts) taught within history/philosophy. '
            'Exception: Alsace-Moselle region has optional confessional RE under Concordat.',
        optOutRight: 'Not applicable — no RE in public schools. In Alsace-Moselle, '
            'parents can opt out of confessional RE.',
        alternativeEthicsClass: 'Moral and civic education (Enseignement moral et civique - EMC) '
            'is mandatory for all.',
        religiousSchools: 'Extensive private school network under contract (sous contrat) '
            'with state. Catholic, Jewish (ORT, Alliance), and Muslim schools '
            '(Lycée Averroès in Lille, MHS in Strasbourg). State funding if under contract.',
      ),
      worshipRights: PlacesOfWorshipRights(
        permitProcess: 'Standard permis de construire through commune/préfecture. '
            'Law of 1905: state cannot fund construction but can provide long-term lease of land.',
        zoningLaw: 'Plan local d\'urbanisme (PLU). Religious buildings classified as '
            'ERP (établissements recevant du public). Some mayors accused of using '
            'zoning to block mosque construction.',
        minaretRestrictions: 'No explicit ban. Subject to PLU height restrictions and '
            'architectural regulations. Political controversies but no legislation.',
        recentIssues: 'Loi séparatisme (2021) increased oversight of religious organizations. '
            'Requires "republican contract" for associations receiving public funds. '
            'Foreign funding transparency required. Several mosques closed for promoting '
            '"radical" views under prefectoral orders.',
      ),
      discriminationComplaints: DiscriminationComplaints(
        equalityBody: 'Défenseur des droits (Defender of Rights)',
        contactInfo: 'TSA 90716, 75334 Paris Cedex 07. Tel: +33 9 69 39 00 00',
        onlineFiling: 'https://www.defenseurdesdroits.fr/ — online complaint form',
        legalAidAvailable: 'Yes. Aide juridictionnelle based on income. '
            'SOS Racisme, LICRA, LDH provide free legal support for discrimination. '
            'CCIF (now Collectif contre l\'islamophobie en Europe) documents anti-Muslim cases.',
        timeLimit: '5 years for criminal discrimination (Art 225-1 Penal Code). '
            'Civil claims: 5 years.',
      ),
      burialRights: BurialRights(
        islamicBurial: 'Square musulman (Muslim sections) in municipal cemeteries. '
            'Circular of 19 February 2008 encourages mayors to create Muslim sections. '
            'Available in most major cities. Burial without coffin: varies by commune — '
            'some allow shroud burial in dedicated sections.',
        jewishBurial: 'Jewish sections (carrés juifs) well-established in major cemeteries. '
            'Consistoire central manages burial. Perpetual concessions available.',
        dedicatedSections: 'Over 600 Muslim sections nationwide. Paris (Bobigny, Thiais), '
            'Lyon, Marseille, Strasbourg all have significant sections.',
        repatriationOfRemains: 'Permitted. AMIF (Aide Musulmane d\'Intervention Funéraire) and '
            'mosque associations assist. Bilateral agreements with North African countries. '
            'Cost: €2,000-€5,000.',
        embalming: 'Soins de conservation (embalming) not mandatory for domestic burial. '
            'Required for some international repatriations depending on destination country.',
      ),
      chaplaincyRights: ChaplaincyRights(
        prisons: 'Muslim chaplains (aumôniers musulmans) appointed in all prisons. '
            '~200 Muslim prison chaplains nationwide. Paid by state (exception to laïcité '
            'principle for closed institutions).',
        hospitals: 'Hospital chaplaincy (aumônerie hospitalière) for all religions. '
            'Muslim aumôniers in major hospitals. AP-HP has multi-faith chaplaincy.',
        military: 'Muslim military chaplain (aumônier militaire musulman) since 2006. '
            'Part of Service des aumôneries militaires.',
        multiReligious: 'France funds chaplaincy in closed institutions (prisons, military, '
            'hospitals) as exception to strict laïcité. Covers Catholic, Protestant, '
            'Jewish, Muslim, Orthodox, Buddhist chaplaincy.',
      ),
      immigrantSpecificNotes: 'France has the largest Muslim population in Western Europe '
          '(~5-6 million, ~8-9%). Laïcité creates a unique framework — religion is strictly '
          'private matter. School headscarf ban since 2004 and face covering ban since 2010 '
          'are the most restrictive in the EU. However, halal slaughter exemption maintained, '
          'prison/military chaplaincy funded by state, and private religious schools including '
          'Islamic ones receive state funding. Loi séparatisme (2021) increased scrutiny of '
          'Islamic organizations. Défenseur des droits actively handles discrimination. '
          'Strong legal aid network. Immigrant religious practice is constitutionally protected '
          'but public expression is more restricted than in most EU countries.',
    ),

    // ========================================================================
    // 11. GERMANY (DE)
    // ========================================================================
    ReligiousRightsInfo(
      country: 'Germany',
      countryCode: 'DE',
      legalBasis: 'Basic Law (Grundgesetz) Art 4 (freedom of faith/conscience), '
          'Art 3 (non-discrimination), Art 140 (Weimar Constitution religion articles); '
          'General Equal Treatment Act 2006 (AGG — Allgemeines Gleichbehandlungsgesetz).',
      constitutionalProvision: 'Art 4 GG: Inviolability of freedom of faith, conscience, and '
          'religious/philosophical creed. Undisturbed practice of religion guaranteed. '
          'Art 140 incorporates Weimar Constitution articles on religion — cooperative model '
          'between state and religious communities (Körperschaft des öffentlichen Rechts status).',
      foodAccess: HalalKosherAccess(
        schools: 'Varies by Land (state). Many schools in Berlin, NRW, Hamburg, '
            'Hessen offer halal meals. No federal mandate.',
        hospitals: 'Hospitals accommodate dietary needs. Charité Berlin, University '
            'hospitals in Munich, Hamburg provide halal/kosher options.',
        prisons: 'Strafvollzugsgesetz requires accommodation of religious dietary needs. '
            'Halal meals available in all federal and state prisons.',
        military: 'Bundeswehr provides halal meals for Muslim soldiers.',
        generalAvailability: 'Widely available throughout Germany. Strong halal food industry. '
            'Large Turkish/Muslim population ensures broad availability.',
        slaughterLaw: 'Ritual slaughter (Schächten) requires special exemption under '
            'Tierschutzgesetz §4a. BVerfG (Federal Constitutional Court) 2002: Muslim '
            'butcher granted exemption under Art 4 GG. Exemptions granted but regulated.',
      ),
      holidayRights: ReligiousHolidayRights(
        legalFramework: 'Federal and state holiday laws (Feiertagsgesetze). '
            'Varies by Land. Some Länder provide explicit provisions for non-Christian holidays.',
        employeeRights: 'AGG requires equal treatment. Employees may take annual leave for '
            'religious holidays. Some collective agreements (Tarifverträge) include provisions. '
            'Employer should consider reasonable accommodation under Art 4 GG.',
        publicSectorPolicy: 'Beamtengesetze (civil servant laws) of some Länder allow '
            'schedule adjustments. Berlin, NRW more accommodating.',
        keyHolidays: 'Public holidays vary by Land (9-13 days). Mix of Christian and secular. '
            'No Muslim holidays. Reformation Day in Protestant Länder.',
      ),
      clothingRights: ReligiousClothingRights(
        workplace: 'Generally permitted under Art 4 GG. AGG protects against religious '
            'discrimination. BAG (Federal Labour Court) has addressed headscarf in '
            'employment repeatedly.',
        publicSchools: 'No federal law. Varies by Land: some banned teacher headscarves '
            '(Baden-Württemberg, Bavaria, NRW — but BVerfG 2015 struck down blanket bans). '
            'Student headscarves: no ban in any Land.',
        governmentBuildings: 'BVerfG 2015: blanket headscarf bans for teachers unconstitutional. '
            'Must prove concrete danger. Judges: some Länder restrict under judicial neutrality. '
            'Berlin Neutrality Law (Berliner Neutralitätsgesetz) most restrictive — challenged.',
        faceCoveringLaw: 'No general face covering ban. Partial restrictions: Hessen, Bavaria, '
            'Lower Saxony ban in some public sector contexts. No federal burqa ban.',
        keyLegalCases: 'BVerfG 2003 (Ludin): first headscarf case, allowed Länder to legislate. '
            'BVerfG 2015 (1 BvR 471/10): blanket teacher headscarf bans unconstitutional. '
            'BAG 2019: employer neutrality policy must be consistent.',
      ),
      prayerRoomRights: PrayerRoomRights(
        employerObligations: 'No statutory obligation. Art 4 GG may require reasonable '
            'accommodation in some circumstances. BAG has not mandated prayer rooms.',
        publicInstitutions: 'Universities: many have multi-faith prayer rooms. '
            'Hospitals increasingly have multi-faith spaces.',
        airports: 'Frankfurt Airport (FRA), Munich Airport (MUC), Berlin Brandenburg (BER) '
            'all have interfaith prayer rooms/chapels.',
        universities: 'TU Berlin, FU Berlin, University of Cologne, University of Hamburg, '
            'LMU Munich all have prayer rooms.',
      ),
      educationRights: ReligiousEducationRights(
        publicSchoolPolicy: 'Art 7(3) GG: Religious instruction is regular school subject '
            'in public schools (except Bremen, Berlin — "Bremen clause"). Islamic RE '
            'introduced in NRW (2012), Hessen, Niedersachsen, BaWü, Hamburg.',
        optOutRight: 'Art 7(2) GG: Parents/guardians have right to decide child\'s participation. '
            'Students 14+ (religionsmündig) decide themselves. Written opt-out.',
        alternativeEthicsClass: 'Ethik, Werte und Normen, or Philosophie (varies by Land) '
            'as alternative to religious instruction. Mandatory in most Länder if opting out.',
        religiousSchools: 'Right to establish private schools under Art 7(4) GG. '
            'Islamic schools exist but few. DITIB and other organizations run Quran schools. '
            'State-recognized Islamic theology programs at Frankfurt, Münster, Tübingen, '
            'Osnabrück, Erlangen-Nürnberg universities.',
      ),
      worshipRights: PlacesOfWorshipRights(
        permitProcess: 'Standard Baugenehmigung through Bauordnungsamt. Religious buildings '
            'treated as Gemeinbedarfseinrichtungen (community facilities).',
        zoningLaw: 'Baunutzungsverordnung (BauNVO). Mosques generally permissible in '
            'mixed-use and residential zones as community facilities.',
        minaretRestrictions: 'No ban. Subject to Bauordnung height and design regulations. '
            'Some local controversies but no legal restrictions.',
        recentIssues: 'DITIB (Turkish-Islamic Union) mosque network under scrutiny for '
            'ties to Turkish government. Cologne Central Mosque (2018) is Europe\'s largest. '
            'AfD political opposition to mosque construction.',
      ),
      discriminationComplaints: DiscriminationComplaints(
        equalityBody: 'Federal Anti-Discrimination Agency '
            '(Antidiskriminierungsstelle des Bundes — ADS)',
        contactInfo: 'Glinkastraße 24, 10117 Berlin. Tel: +49 30 18555 1855',
        onlineFiling: 'https://www.antidiskriminierungsstelle.de/ — online form in DE/EN/TR/AR',
        legalAidAvailable: 'Yes. Prozesskostenhilfe (legal aid) based on income. '
            'Antidiskriminierungsverband Deutschland network. '
            'CLAIM alliance against Islam- and Muslim-hostility provides support.',
        timeLimit: '2 months for AGG claims to employer. Court claims: 3 months after '
            'written complaint. General civil limitation: 3 years.',
      ),
      burialRights: BurialRights(
        islamicBurial: 'Islamic sections in most major city cemeteries. Sargpflicht (coffin '
            'requirement) varies by Land — NRW, Bremen abolished it. Berlin allows shroud '
            'burial in designated areas. Eternal rest (no grave reuse): some Länder accommodate.',
        jewishBurial: 'Jewish cemeteries well-established. Zentralrat der Juden manages '
            'burial. Perpetual grave rights guaranteed in most Länder.',
        dedicatedSections: 'Widely available. Berlin, Hamburg, Cologne, Munich, Frankfurt, '
            'Stuttgart all have significant Islamic cemetery sections.',
        repatriationOfRemains: 'Permitted. DITIB, Islamic associations assist. '
            'Well-established process through Turkish, Moroccan, other consulates. '
            'Cost: €2,000-€6,000.',
        embalming: 'Bestattungsgesetze vary by Land. Coffin requirement waived in some '
            'Länder for religious burial.',
      ),
      chaplaincyRights: ChaplaincyRights(
        prisons: 'Muslim prison chaplaincy (Gefängnisseelsorge) developing in all Länder. '
            'NRW, Hessen, Niedersachsen, Hamburg have formal programs. '
            'Funded by state governments.',
        hospitals: 'Hospital chaplaincy (Klinikseelsorge) includes Muslim chaplains in '
            'major hospitals. Training programs at Islamic theology faculties.',
        military: 'Jewish military chaplaincy reintroduced 2021. Muslim military chaplaincy '
            'in preparation — Bundeswehr committed to introducing it.',
        multiReligious: 'Germany developing comprehensive multi-faith chaplaincy. '
            'Islamic theology university programs training chaplains. '
            'Deutsche Islam Konferenz (DIK) coordinates framework.',
      ),
      immigrantSpecificNotes: 'Germany has ~5.5 million Muslims (~6.5% of population), mostly '
          'Turkish-origin. Strong constitutional protection under Art 4 GG. Federal Constitutional '
          'Court has been protective of religious freedom (headscarf rulings, slaughter exemptions). '
          'Islamic RE being rolled out across Länder. No federal face covering ban. AGG provides '
          'anti-discrimination framework. Deutsche Islam Konferenz established 2006 for structured '
          'dialogue. DITIB is largest Islamic organization but faces scrutiny over Turkish government '
          'ties. Islamic theology chairs at five universities training imams and chaplains. '
          'Coffin requirement being relaxed in multiple Länder for Islamic burial.',
    ),

    // ========================================================================
    // 12. GREECE (GR)
    // ========================================================================
    ReligiousRightsInfo(
      country: 'Greece',
      countryCode: 'GR',
      legalBasis: 'Constitution Art 13 (religious freedom), Art 3 (prevailing religion); '
          'Law 4301/2014 (organization of religious communities); '
          'Law 4356/2015 (anti-discrimination). Treaty of Lausanne 1923 (Muslim minority in Thrace).',
      constitutionalProvision: 'Art 3: Eastern Orthodox Church is the "prevailing religion." '
          'Art 13: Freedom of religious conscience inviolable. Proselytism prohibited. '
          'Known and recognized religions enjoy protection.',
      foodAccess: HalalKosherAccess(
        schools: 'Muslim schools in Western Thrace provide halal meals. '
            'No systematic provision elsewhere.',
        hospitals: 'Hospitals accommodate upon individual request.',
        prisons: 'Prisons should accommodate dietary needs under regulations.',
        military: 'Greek military provides alternatives for Muslim soldiers, '
            'especially from Thrace minority.',
        generalAvailability: 'Available in Athens (Metaxourgeio area, central market), '
            'Thessaloniki, and extensively in Western Thrace (Komotini, Xanthi).',
        slaughterLaw: 'Ritual slaughter permitted with exemption under EU regulation implementation.',
      ),
      holidayRights: ReligiousHolidayRights(
        legalFramework: 'Labour law. Public holidays are Orthodox Christian.',
        employeeRights: 'Employees may use annual leave. No statutory non-Orthodox holiday rights.',
        publicSectorPolicy: 'Western Thrace Muslim minority has some local holiday recognition.',
        keyHolidays: 'Public holidays follow Orthodox calendar (different Easter dates from Western). '
            'No Muslim holidays except locally in Western Thrace.',
      ),
      clothingRights: ReligiousClothingRights(
        workplace: 'No specific restrictions. Anti-discrimination law applies.',
        publicSchools: 'No ban on hijab. Muslim schools in Thrace allow traditional dress.',
        governmentBuildings: 'No formal restrictions.',
        faceCoveringLaw: 'No face covering ban.',
        keyLegalCases: 'Limited case law. ECHR cases regarding Jehovah\'s Witnesses and '
            'proselytism laws have shaped Greek religious freedom jurisprudence.',
      ),
      prayerRoomRights: PrayerRoomRights(
        employerObligations: 'No legal obligation.',
        publicInstitutions: 'Very limited outside Western Thrace.',
        airports: 'Athens International Airport has a small chapel; no dedicated Muslim prayer room.',
        universities: 'Democritus University of Thrace in Komotini more accommodating.',
      ),
      educationRights: ReligiousEducationRights(
        publicSchoolPolicy: 'Orthodox RE mandatory in public schools. Non-Orthodox may be exempted.',
        optOutRight: 'Exemption available for non-Orthodox students. '
            'Council of State has upheld opt-out rights.',
        alternativeEthicsClass: 'Limited alternative provision. Students exempted typically '
            'attend study hall.',
        religiousSchools: 'Muslim minority schools in Western Thrace (under Treaty of Lausanne). '
            'Two Islamic secondary schools (medrese) in Komotini and Ehinos.',
      ),
      worshipRights: PlacesOfWorshipRights(
        permitProcess: 'Law 4301/2014 reformed permit process. Previously required approval '
            'from Orthodox Church. Now standard urban planning permit.',
        zoningLaw: 'Standard urban planning. Historic difficulty getting mosque permits '
            'has been documented by ECHR.',
        minaretRestrictions: 'No explicit ban. Hundreds of mosques in Western Thrace. '
            'Athens Official Mosque opened in November 2020 — first purpose-built mosque '
            'in Athens since independence (no minaret by design compromise).',
        recentIssues: 'Athens Mosque (Votanikos) opening in 2020 was a major milestone after '
            'over 15 years of delays. Unofficial prayer rooms (makeshift mosques) operate '
            'across Athens. Western Thrace mosques are established.',
      ),
      discriminationComplaints: DiscriminationComplaints(
        equalityBody: 'Greek Ombudsman (Συνήγορος του Πολίτη)',
        contactInfo: 'Chalkokondyli 17, 10432 Athens. Tel: +30 213 1306 600',
        onlineFiling: 'https://www.synigoros.gr/ — online complaint in EL/EN',
        legalAidAvailable: 'Yes. Free legal aid based on income (Law 3226/2004). '
            'Greek Helsinki Monitor and Racist Violence Recording Network provide support.',
        timeLimit: '6 months for Ombudsman. Civil claims: 5 years.',
      ),
      burialRights: BurialRights(
        islamicBurial: 'Muslim cemeteries in Western Thrace (Komotini, Xanthi, Alexandroupoli). '
            'Athens: Muslim section in Schisto cemetery. Limited availability.',
        jewishBurial: 'Jewish cemeteries in Athens, Thessaloniki (rebuilt after WWII). '
            'Central Board of Jewish Communities in Greece manages.',
        dedicatedSections: 'Available in Western Thrace. Athens provision improved but limited.',
        repatriationOfRemains: 'Permitted. Consular assistance available.',
        embalming: 'Not required for domestic burial.',
      ),
      chaplaincyRights: ChaplaincyRights(
        prisons: 'Religious access available. Imams can visit Muslim prisoners.',
        hospitals: 'Orthodox chaplaincy dominant. Non-Orthodox accommodated on request.',
        military: 'Orthodox chaplaincy. Muslim soldiers from Thrace minority accommodated.',
        multiReligious: 'Primarily Orthodox-centric. Multi-faith approach developing slowly.',
      ),
      immigrantSpecificNotes: 'Greece has a constitutionally established Muslim minority in '
          'Western Thrace (~120,000, under Treaty of Lausanne 1923) with mosques, schools, '
          'muftis. Immigrant Muslims (~500,000+) outside Thrace have much less infrastructure. '
          'Athens Mosque opened 2020 after decades of delay — major milestone. No face covering '
          'ban. Orthodox Church constitutionally "prevailing" creates asymmetry. Proselytism '
          'prohibition technically still in law. ECHR has ruled against Greece on several '
          'religious freedom matters. Mufti appointment controversy in Thrace ongoing.',
    ),

    // ========================================================================
    // 13. HUNGARY (HU)
    // ========================================================================
    ReligiousRightsInfo(
      country: 'Hungary',
      countryCode: 'HU',
      legalBasis: 'Fundamental Law (2011) Art VII (freedom of religion); '
          'Act CCVI of 2011 on the Right to Freedom of Conscience and Religion '
          '(Church Act, amended 2019); Equal Treatment Act 2003 (CXXV).',
      constitutionalProvision: 'Art VII: Right to freedom of thought, conscience and religion. '
          'State and religious communities operate separately. State cooperates with churches '
          '"for community goals." Distinction between "established churches" (bevett egyház) '
          'and registered religious organizations. ~30 established churches.',
      foodAccess: HalalKosherAccess(
        schools: 'No systematic provision. Very limited demand.',
        hospitals: 'Individual accommodation on request.',
        prisons: 'Prisons accommodate dietary needs under Prison Code.',
        military: 'No formal provision.',
        generalAvailability: 'Limited. Budapest has some halal options. Very small Muslim '
            'population (~40,000-60,000).',
        slaughterLaw: 'Ritual slaughter without stunning banned under Animal Protection Act. '
            'Imports permitted.',
      ),
      holidayRights: ReligiousHolidayRights(
        legalFramework: 'Labour Code (2012 I). No specific non-Christian holiday provisions.',
        employeeRights: 'Annual leave used for religious holidays.',
        publicSectorPolicy: 'No specific provisions.',
        keyHolidays: 'Public holidays include Christian holidays (Easter, Whitsun, Christmas, '
            'All Saints). No Muslim or Jewish holidays.',
      ),
      clothingRights: ReligiousClothingRights(
        workplace: 'No specific restrictions. Equal Treatment Act applies.',
        publicSchools: 'No ban on religious clothing.',
        governmentBuildings: 'No formal restrictions.',
        faceCoveringLaw: 'No face covering ban.',
        keyLegalCases: 'Limited case law on religious clothing.',
      ),
      prayerRoomRights: PrayerRoomRights(
        employerObligations: 'No legal obligation.',
        publicInstitutions: 'Very limited.',
        airports: 'Budapest Airport (BUD) has an interfaith chapel.',
        universities: 'No formal multi-faith rooms.',
      ),
      educationRights: ReligiousEducationRights(
        publicSchoolPolicy: 'Religious education or ethics class mandatory since 2013 (choice). '
            'RE provided by established churches. Islamic RE not systematically available.',
        optOutRight: 'Choice between religious education and ethics class.',
        alternativeEthicsClass: 'Ethics (erkölcstan) mandatory alternative to RE.',
        religiousSchools: 'Church-run schools receive full state funding. '
            'No Islamic schools. Jewish schools in Budapest (BZSH operated).',
      ),
      worshipRights: PlacesOfWorshipRights(
        permitProcess: 'Standard building permit. Religious organization must be registered.',
        zoningLaw: 'Standard urban planning regulations.',
        minaretRestrictions: 'No restrictions. No purpose-built mosques with minarets in Hungary.',
        recentIssues: 'Government strongly anti-immigration stance. Very small Muslim community. '
            'Budapest mosque operates from converted buildings.',
      ),
      discriminationComplaints: DiscriminationComplaints(
        equalityBody: 'Commissioner for Fundamental Rights (Alapvető Jogok Biztosa)',
        contactInfo: 'Nádor u. 22, 1051 Budapest. Tel: +36 1 475 7100',
        onlineFiling: 'https://www.ajbh.hu/ — complaint form available',
        legalAidAvailable: 'Yes. Legal aid based on income. Hungarian Helsinki Committee '
            'provides free legal assistance for discrimination.',
        timeLimit: '1 year for Equal Treatment Authority complaints (authority merged into '
            'Commissioner\'s office in 2021).',
      ),
      burialRights: BurialRights(
        islamicBurial: 'Very limited. Budapest has a small Islamic section in Rákoskeresztúr cemetery.',
        jewishBurial: 'Jewish cemeteries in Budapest (Kozma utca, Farkasréti). '
            'MAZSIHISZ (Federation of Hungarian Jewish Communities) manages burial.',
        dedicatedSections: 'Very limited for Muslims. Jewish sections well-established.',
        repatriationOfRemains: 'Permitted under standard regulations.',
        embalming: 'Not required by law.',
      ),
      chaplaincyRights: ChaplaincyRights(
        prisons: 'Religious access available for established churches. '
            'Muslim spiritual care very limited.',
        hospitals: 'Chaplaincy for established churches. Multi-faith limited.',
        military: 'Catholic and Protestant military chaplaincy. No Muslim chaplaincy.',
        multiReligious: 'Very limited due to small non-Christian populations and political climate.',
      ),
      immigrantSpecificNotes: 'Hungary has a very small Muslim population and an anti-immigration '
          'political stance. The 2011 Church Act created a tiered system that privileges '
          '"established churches." Islamic community not among established churches but can '
          'register as religious organization. No face covering ban but very limited infrastructure '
          'for Islamic practice. Equal Treatment Act provides basic anti-discrimination protection. '
          'Constitutional Court has been protective of individual religious freedom even as '
          'political rhetoric has been hostile to Islam.',
    ),

    // ========================================================================
    // 14. IRELAND (IE)
    // ========================================================================
    ReligiousRightsInfo(
      country: 'Ireland',
      countryCode: 'IE',
      legalBasis: 'Constitution (Bunreacht na hÉireann) Art 44 (religion); '
          'Employment Equality Acts 1998-2015; Equal Status Acts 2000-2018; '
          'Irish Human Rights and Equality Commission Act 2014.',
      constitutionalProvision: 'Art 44: State acknowledges homage to Almighty God. '
          'Freedom of conscience and free profession and practice of religion guaranteed. '
          'State shall not endow any religion. All religions treated equally (post-1972 '
          'amendment removing "special position" of Catholic Church).',
      foodAccess: HalalKosherAccess(
        schools: 'Schools increasingly accommodate. Many schools in Dublin provide halal options. '
            'No national mandate but Tusla guidelines encourage accommodation.',
        hospitals: 'HSE (Health Service Executive) hospitals accommodate dietary requests. '
            'Major Dublin hospitals provide halal options.',
        prisons: 'Irish Prison Service required to accommodate religious dietary needs. '
            'Halal meals provided in all prisons.',
        military: 'Defence Forces accommodate dietary requirements.',
        generalAvailability: 'Widely available in Dublin, Cork, Galway, Limerick. '
            'Growing halal food sector. IHRC certification available.',
        slaughterLaw: 'Ritual slaughter without stunning permitted under exemption in '
            'Abattoirs Act. Supervised by Department of Agriculture.',
      ),
      holidayRights: ReligiousHolidayRights(
        legalFramework: 'Organisation of Working Time Act 1997. No specific non-Christian '
            'holiday provisions.',
        employeeRights: 'Employees may request leave using annual leave. WRC '
            '(Workplace Relations Commission) has addressed religious accommodation cases.',
        publicSectorPolicy: 'Public service allows flexible arrangements.',
        keyHolidays: '9 public holidays (mix of secular and Christian — St Patrick\'s, '
            'Easter Monday, Christmas, St Stephen\'s Day). No Muslim holidays.',
      ),
      clothingRights: ReligiousClothingRights(
        workplace: 'Generally permitted. Employment Equality Acts protect against '
            'discrimination on religious grounds.',
        publicSchools: 'No ban. Education Act allows schools to set uniform policy but '
            'must not discriminate. Muslim girls wear hijab in public schools without issue.',
        governmentBuildings: 'No formal restrictions. Garda Síochána (police) explored '
            'hijab-friendly uniform modifications.',
        faceCoveringLaw: 'No face covering ban.',
        keyLegalCases: 'WRC cases on religious clothing in employment. Generally protective '
            'of religious expression.',
      ),
      prayerRoomRights: PrayerRoomRights(
        employerObligations: 'No statutory obligation. WRC may find failure to accommodate '
            'unreasonable in specific circumstances.',
        publicInstitutions: 'Some hospitals and public buildings have multi-faith spaces.',
        airports: 'Dublin Airport has interfaith prayer room.',
        universities: 'Trinity College Dublin, UCD, DCU, UCC all have multi-faith prayer rooms.',
      ),
      educationRights: ReligiousEducationRights(
        publicSchoolPolicy: 'Most primary schools are denominational (90% Catholic patronage). '
            'Religious instruction integral to ethos. Multidenominational schools (Educate Together) '
            'growing.',
        optOutRight: 'Constitutional right to opt out of religious instruction. '
            'Education (Admission to Schools) Act 2018 reformed baptism barrier. '
            'ERB (Education about Religions and Beliefs) pilot programs.',
        alternativeEthicsClass: 'No formal national ethics alternative in denominational schools. '
            'Educate Together schools teach "Learn Together" ethical education.',
        religiousSchools: 'Overwhelmingly Catholic school system. Muslim national school '
            '(Scoil an tSeachtar Laoch) in Dublin — Ireland\'s first Muslim primary school. '
            'Islamic Foundation of Ireland operates education programs.',
      ),
      worshipRights: PlacesOfWorshipRights(
        permitProcess: 'Standard planning permission through local authority under '
            'Planning and Development Act 2000.',
        zoningLaw: 'Development plan zoning. Religious buildings classified as community use.',
        minaretRestrictions: 'No restrictions. Islamic Cultural Centre of Ireland (Clonskeagh, '
            'Dublin) has minaret — largest mosque in Ireland.',
        recentIssues: 'Growing Muslim community (~85,000) driving demand for mosques. '
            'Generally positive reception. Some local planning disputes.',
      ),
      discriminationComplaints: DiscriminationComplaints(
        equalityBody: 'Irish Human Rights and Equality Commission (IHREC) / '
            'Workplace Relations Commission (WRC)',
        contactInfo: 'IHREC: 16-22 Green Street, Dublin 7. Tel: +353 1 858 9601. '
            'WRC: O\'Brien Road, Carlow. Tel: +353 59 917 8990',
        onlineFiling: 'https://www.workplacerelations.ie/ — online complaint form. '
            'IHREC: https://www.ihrec.ie/',
        legalAidAvailable: 'Yes. Legal Aid Board provides free legal aid. '
            'IHREC can provide legal assistance in strategic cases. '
            'Immigrant Council of Ireland offers legal support.',
        timeLimit: '6 months for WRC complaints (extendable to 12 months). '
            'Civil claims: statute of limitations varies.',
      ),
      burialRights: BurialRights(
        islamicBurial: 'Islamic burial sections in Dublin (Newcastle Muslim Cemetery), '
            'Cork, Galway. Islamic Foundation of Ireland manages burial. '
            'Burial without coffin permitted in some sections.',
        jewishBurial: 'Jewish cemetery in Dublin (Dolphin\'s Barn). '
            'Jewish Representative Council manages.',
        dedicatedSections: 'Newcastle Muslim Cemetery (Dublin) is the primary facility. '
            'Sections being developed in other cities.',
        repatriationOfRemains: 'Permitted. Islamic Foundation of Ireland assists. '
            'Costs: €3,000-€8,000 depending on destination.',
        embalming: 'Not legally required. Religious preparation of body permitted.',
      ),
      chaplaincyRights: ChaplaincyRights(
        prisons: 'Prison chaplaincy includes Muslim imam provision in major prisons. '
            'Irish Prison Service employs Muslim chaplain.',
        hospitals: 'HSE hospital chaplaincy traditionally Catholic. Multi-faith '
            'chaplaincy developing. HSE guidelines on spiritual care include all faiths.',
        military: 'Catholic dominant but Defence Forces accommodate other faiths.',
        multiReligious: 'Multi-faith approach developing. Interfaith dialogue supported '
            'by Dublin City Interfaith Forum.',
      ),
      immigrantSpecificNotes: 'Ireland has a growing and increasingly diverse Muslim community '
          '(~85,000). Generally welcoming legal environment with no face covering ban, '
          'no headscarf restrictions, and ritual slaughter permitted. The denominational '
          'school system is the main challenge — 90% Catholic patronage means limited '
          'non-Catholic options, though Educate Together and Muslim schools are expanding. '
          'Education admission reform (2018) removed baptism barrier. Strong equality legislation. '
          'Islamic Cultural Centre of Ireland (Clonskeagh) is a major community resource.',
    ),

    // ========================================================================
    // 15. ITALY (IT)
    // ========================================================================
    ReligiousRightsInfo(
      country: 'Italy',
      countryCode: 'IT',
      legalBasis: 'Constitution Art 3 (equality), Art 7-8 (relations with religions), '
          'Art 19-20 (religious freedom); Lateran Pacts 1929/1984 (Catholic Church); '
          'Law 101/1989 (Jewish communities); Legislative Decree 215/2003 '
          '(anti-discrimination, transposing 2000/43/EC). No intesa (agreement) with Islam yet.',
      constitutionalProvision: 'Art 8: All religious denominations are equally free before the law. '
          'Non-Catholic denominations have right to organize according to own statutes. '
          'Relations regulated by intese (bilateral agreements) — Islam has none, which limits '
          'institutional recognition and state funding.',
      foodAccess: HalalKosherAccess(
        schools: 'Varies by municipality. Milan, Rome, Turin schools increasingly offer '
            'halal/kosher options. No national mandate.',
        hospitals: 'Hospitals accommodate individually. Major hospitals in Rome, Milan '
            'provide alternatives.',
        prisons: 'DAP (Department of Prison Administration) requires dietary accommodation. '
            'Halal meals available in Italian prisons.',
        military: 'Italian Armed Forces accommodate dietary needs on request.',
        generalAvailability: 'Widely available, especially in Rome, Milan, Turin, Bologna. '
            'Large Muslim population ensures market demand.',
        slaughterLaw: 'Ritual slaughter permitted for communities with intesa. Jewish '
            'community (with intesa) has full exemption. Muslim community lacks intesa but '
            'practice continues under general provisions.',
      ),
      holidayRights: ReligiousHolidayRights(
        legalFramework: 'Statuto dei Lavoratori. Public holidays are secular and Catholic.',
        employeeRights: 'Employees of religious communities with intesa have specific rights. '
            'Muslims without intesa rely on annual leave and employer goodwill.',
        publicSectorPolicy: 'Public sector follows national holiday calendar. '
            'Flexible arrangements negotiable.',
        keyHolidays: '12 public holidays including Catholic holidays (Immaculate Conception, '
            'Easter, Assumption, All Saints, Christmas). No Muslim holidays.',
      ),
      clothingRights: ReligiousClothingRights(
        workplace: 'No specific restrictions. Anti-discrimination decree applies.',
        publicSchools: 'No ban on hijab. Crucifix in classrooms — ECHR Lautsi v. Italy (2011) '
            'upheld (passive symbol).',
        governmentBuildings: 'No formal ban on religious clothing. TULPS Art 85 (1931 public '
            'security law) sometimes cited to require face identification.',
        faceCoveringLaw: 'No specific burqa/niqab ban but Law 152/1975 and TULPS Art 85 '
            'prohibit covering face in public places for identification purposes. '
            'Applied to niqab by some local ordinances and police. Fines vary.',
        keyLegalCases: 'Lautsi v. Italy (ECHR Grand Chamber 2011): crucifix in schools not '
            'a violation. Various municipal ordinances against niqab challenged in courts.',
      ),
      prayerRoomRights: PrayerRoomRights(
        employerObligations: 'No legal obligation.',
        publicInstitutions: 'Some hospitals have multi-faith spaces. Very limited.',
        airports: 'Rome Fiumicino has interfaith chapel. Milan Malpensa has prayer room.',
        universities: 'Some universities (Bologna, Milan) have multi-faith spaces.',
      ),
      educationRights: ReligiousEducationRights(
        publicSchoolPolicy: 'Catholic religious instruction (Insegnamento della Religione '
            'Cattolica - IRC) offered in public schools under Lateran Pacts.',
        optOutRight: 'Students/parents can opt out of Catholic RE. '
            'Constitutional Court confirmed opt-out right.',
        alternativeEthicsClass: 'Alternative activity (attività alternativa) offered but '
            'quality varies. Can be study hall, ethics, or cultural activity.',
        religiousSchools: 'Catholic schools extensive (scuole paritarie). Jewish schools '
            'in Rome, Milan. Islamic schools very limited — no formal recognition without intesa.',
      ),
      worshipRights: PlacesOfWorshipRights(
        permitProcess: 'Building permit from municipal authority. Some Regions have passed '
            'restrictive "anti-mosque" laws (Lombardy 2015, Veneto).',
        zoningLaw: 'Varies by Region. Lombardy Law 2/2015 imposed strict requirements on '
            'new places of worship — Constitutional Court struck down some provisions (2017).',
        minaretRestrictions: 'No national restriction. Local opposition and regional laws '
            'have created de facto barriers.',
        recentIssues: 'Lombardy "anti-mosque" law partially struck down by Constitutional Court. '
            'Many Islamic prayer halls (centri islamici) operate from converted garages/warehouses '
            'due to permit difficulties. No intesa with Islam remains central issue.',
      ),
      discriminationComplaints: DiscriminationComplaints(
        equalityBody: 'UNAR (Ufficio Nazionale Antidiscriminazioni Razziali) / '
            'Regional Equality Advisors',
        contactInfo: 'UNAR Contact Center: 800 90 10 10 (toll-free). '
            'Largo Chigi 19, 00187 Rome',
        onlineFiling: 'https://www.unar.it/ — contact center and online reporting',
        legalAidAvailable: 'Yes. Gratuito patrocinio based on income. '
            'ASGI (Association for Juridical Studies on Immigration) provides legal support.',
        timeLimit: '6 months for employment discrimination. Civil claims: 5 years.',
      ),
      burialRights: BurialRights(
        islamicBurial: 'Islamic sections in some municipal cemeteries (Rome, Milan, Bologna, '
            'Turin, Florence). Mecca-facing orientation accommodated. '
            'Coffin generally required under Italian law (DPR 285/1990).',
        jewishBurial: 'Jewish cemeteries in Rome (Verano), Milan, Florence, Venice. '
            'UCEI manages Jewish burial.',
        dedicatedSections: 'Expanding but insufficient. Some municipalities reluctant. '
            'No systematic national provision.',
        repatriationOfRemains: 'Permitted. Consular assistance through Moroccan, '
            'Tunisian, Egyptian, Bangladeshi embassies. Cost: €2,000-€6,000.',
        embalming: 'Coffin required by regulation. Creates tension with Islamic preference '
            'for shroud burial.',
      ),
      chaplaincyRights: ChaplaincyRights(
        prisons: 'Muslim chaplaincy (mediatori culturali/assistenti religiosi) present in '
            'Italian prisons. Not formally equivalent to Catholic chaplaincy. '
            'UCOII and other Islamic organizations provide volunteers.',
        hospitals: 'Catholic chaplaincy dominant (cappellani ospedalieri). '
            'Muslim spiritual care available on request but not systematized.',
        military: 'Catholic military chaplaincy (Ordinariato militare). '
            'No formal non-Catholic military chaplaincy.',
        multiReligious: 'Italy\'s lack of intesa with Islam means Muslim chaplaincy '
            'is not institutionally equal. Developing informally.',
      ),
      immigrantSpecificNotes: 'Italy has ~2.6 million Muslims (~4.4% of population) but Islam '
          'has NO intesa (bilateral agreement) with the state, unlike Catholicism, Judaism, '
          'Protestantism, Buddhism, Hinduism, and others. This creates significant institutional '
          'disadvantages: no 8x1000 tax funding, no formal chaplaincy, limited school RE rights. '
          'Multiple attempts at intesa have failed due to lack of unified Muslim representative '
          'body. Regional "anti-mosque" laws in Lombardy and Veneto create barriers. '
          'No national face covering ban but identification laws used against niqab. '
          'Coffinrequirement conflicts with Islamic burial practice. UNAR handles complaints.',
    ),

    // ========================================================================
    // 16. LATVIA (LV)
    // ========================================================================
    ReligiousRightsInfo(
      country: 'Latvia',
      countryCode: 'LV',
      legalBasis: 'Constitution (Satversme) Art 99 (freedom of religion); '
          'Law on Religious Organizations 1995; Labour Law Art 29 (discrimination prohibition).',
      constitutionalProvision: 'Art 99: Freedom of thought, conscience and religion. '
          'Church and state separated. Traditional religious denominations recognized: '
          'Lutheran, Catholic, Orthodox, Old Believers, Baptist, Methodist, Adventist, Jewish.',
      foodAccess: HalalKosherAccess(
        schools: 'No formal provision. Negligible demand.',
        hospitals: 'Individual accommodation on request.',
        prisons: 'Should accommodate under regulations. Limited practice.',
        military: 'No formal provision.',
        generalAvailability: 'Very limited. Riga has a few halal-friendly establishments. '
            'Tiny Muslim population.',
        slaughterLaw: 'Ritual slaughter without stunning prohibited under Animal '
            'Welfare Law.',
      ),
      holidayRights: ReligiousHolidayRights(
        legalFramework: 'Labour Law. No non-Christian holiday provisions.',
        employeeRights: 'Annual leave used for religious holidays.',
        publicSectorPolicy: 'No specific provisions.',
        keyHolidays: 'Public holidays include Christian holidays (Christmas, Easter). '
            'No Muslim holidays.',
      ),
      clothingRights: ReligiousClothingRights(
        workplace: 'No specific restrictions. Anti-discrimination provisions apply.',
        publicSchools: 'No ban on religious clothing.',
        governmentBuildings: 'No formal restrictions.',
        faceCoveringLaw: 'No face covering ban.',
        keyLegalCases: 'Very limited case law.',
      ),
      prayerRoomRights: PrayerRoomRights(
        employerObligations: 'No legal obligation.',
        publicInstitutions: 'No formal provision.',
        airports: 'Riga Airport has no dedicated prayer room.',
        universities: 'No formal prayer rooms.',
      ),
      educationRights: ReligiousEducationRights(
        publicSchoolPolicy: 'Christian ethics (Kristīgā mācība) optional in public schools.',
        optOutRight: 'Fully optional.',
        alternativeEthicsClass: 'Ethics class as alternative.',
        religiousSchools: 'Some Christian schools. No Islamic schools.',
      ),
      worshipRights: PlacesOfWorshipRights(
        permitProcess: 'Standard building permit through municipality.',
        zoningLaw: 'Standard planning regulations.',
        minaretRestrictions: 'No restrictions. No mosques currently in Latvia.',
        recentIssues: 'Very small Muslim community. No purpose-built mosques. '
            'Prayer space in Riga (Islamic Cultural Centre).',
      ),
      discriminationComplaints: DiscriminationComplaints(
        equalityBody: 'Ombudsman of the Republic of Latvia (Tiesībsargs)',
        contactInfo: 'Baznīcas iela 25, Riga LV-1010. Tel: +371 67686768',
        onlineFiling: 'https://www.tiesibsargs.lv/ — online complaint',
        legalAidAvailable: 'Yes. State legal aid available based on income.',
        timeLimit: '1 year for Ombudsman complaints.',
      ),
      burialRights: BurialRights(
        islamicBurial: 'Very limited. No dedicated Islamic cemetery sections.',
        jewishBurial: 'Jewish cemeteries in Riga (Šmerli cemetery).',
        dedicatedSections: 'Extremely limited for Muslims.',
        repatriationOfRemains: 'Permitted under standard regulations.',
        embalming: 'Not required by law.',
      ),
      chaplaincyRights: ChaplaincyRights(
        prisons: 'Religious access available for registered denominations.',
        hospitals: 'Chaplaincy primarily Christian.',
        military: 'National Armed Forces chaplaincy (Christian).',
        multiReligious: 'Very limited multi-faith provision.',
      ),
      immigrantSpecificNotes: 'Latvia has a very small Muslim population (~1,000-2,000). '
          'Minimal Islamic infrastructure. No mosques. Islamic Cultural Centre in Riga is '
          'primary institution. No face covering ban. Legal framework provides basic '
          'anti-discrimination protection. Religious freedom constitutionally guaranteed but '
          'practical accommodation for Muslim immigrants is minimal.',
    ),

    // ========================================================================
    // 17. LITHUANIA (LT)
    // ========================================================================
    ReligiousRightsInfo(
      country: 'Lithuania',
      countryCode: 'LT',
      legalBasis: 'Constitution Art 26 (freedom of religion); '
          'Law on Religious Communities and Associations 1995; '
          'Equal Treatment Act 2005.',
      constitutionalProvision: 'Art 26: Freedom of thought, conscience and religion. '
          'Nine "traditional" religious communities recognized (Catholic, Orthodox, Old Believers, '
          'Lutheran, Reformed, Jewish, Muslim Sunni, Muslim Shiite, Karaite). '
          'Islam is a traditional religion in Lithuania (Lipka Tatars since 14th century).',
      foodAccess: HalalKosherAccess(
        schools: 'Limited provision. Available in areas near Tatar communities.',
        hospitals: 'Individual accommodation on request.',
        prisons: 'Dietary accommodation required under prison regulations.',
        military: 'No formal provision.',
        generalAvailability: 'Limited. Vilnius has some halal options.',
        slaughterLaw: 'Ritual slaughter without stunning prohibited under Animal Welfare Act.',
      ),
      holidayRights: ReligiousHolidayRights(
        legalFramework: 'Labour Code. Traditional religious communities may have holiday provisions.',
        employeeRights: 'Annual leave used. Sunni and Shiite Muslim communities as traditional '
            'religions have some recognition for holidays.',
        publicSectorPolicy: 'Limited specific provisions.',
        keyHolidays: 'Public holidays include Catholic holidays. No Muslim public holidays.',
      ),
      clothingRights: ReligiousClothingRights(
        workplace: 'No specific restrictions. Equal Treatment Act applies.',
        publicSchools: 'No ban on religious clothing.',
        governmentBuildings: 'No formal restrictions.',
        faceCoveringLaw: 'No face covering ban.',
        keyLegalCases: 'Very limited case law.',
      ),
      prayerRoomRights: PrayerRoomRights(
        employerObligations: 'No legal obligation.',
        publicInstitutions: 'No formal provision.',
        airports: 'Vilnius Airport has no dedicated prayer room.',
        universities: 'No formal multi-faith rooms.',
      ),
      educationRights: ReligiousEducationRights(
        publicSchoolPolicy: 'Religious education optional. Traditional religions can provide RE.',
        optOutRight: 'Fully optional.',
        alternativeEthicsClass: 'Ethics class as alternative.',
        religiousSchools: 'Catholic schools. Jewish school in Vilnius (Sholem Aleichem). '
            'No Islamic schools but Tatar community maintains cultural education.',
      ),
      worshipRights: PlacesOfWorshipRights(
        permitProcess: 'Standard building permit through municipality.',
        zoningLaw: 'Standard planning regulations.',
        minaretRestrictions: 'No restrictions. Historic mosques in Lithuania — Kaunas mosque '
            '(one of few purpose-built mosques in the Baltics).',
        recentIssues: 'Lipka Tatar community has deep roots. Kaunas mosque and Vilnius mosque '
            'are historic. New immigrant Muslim communities developing.',
      ),
      discriminationComplaints: DiscriminationComplaints(
        equalityBody: 'Office of the Equal Opportunities Ombudsperson '
            '(Lygių galimybių kontrolieriaus tarnyba)',
        contactInfo: 'S. Konarskio g. 35, 03123 Vilnius. Tel: +370 5 261 2786',
        onlineFiling: 'https://www.lygybe.lt/ — online complaint form',
        legalAidAvailable: 'Yes. State-guaranteed legal aid. Lithuanian Human Rights Centre.',
        timeLimit: '3 months for Ombudsperson complaints.',
      ),
      burialRights: BurialRights(
        islamicBurial: 'Historic Muslim (Tatar) cemeteries in Lithuania. Vilnius, Kaunas areas.',
        jewishBurial: 'Jewish cemeteries in Vilnius. Jewish Community of Lithuania manages.',
        dedicatedSections: 'Available through historic Tatar community infrastructure.',
        repatriationOfRemains: 'Permitted under standard regulations.',
        embalming: 'Not required by law.',
      ),
      chaplaincyRights: ChaplaincyRights(
        prisons: 'Religious access for traditional religious communities guaranteed.',
        hospitals: 'Catholic chaplaincy dominant. Others on request.',
        military: 'Military chaplaincy primarily Catholic.',
        multiReligious: 'Limited. Islam as traditional religion gives some institutional access.',
      ),
      immigrantSpecificNotes: 'Lithuania uniquely recognizes Islam as a "traditional religion" '
          'due to the 600-year presence of Lipka Tatars. This gives institutional advantages '
          'not found in other Baltic states. However, practical infrastructure for immigrant '
          'Muslims is still limited. Historic mosques in Kaunas and Vilnius. No face covering ban. '
          'Equal Treatment Act provides discrimination protection. Small but growing immigrant '
          'Muslim community alongside the historic Tatar community.',
    ),

    // ========================================================================
    // 18. LUXEMBOURG (LU)
    // ========================================================================
    ReligiousRightsInfo(
      country: 'Luxembourg',
      countryCode: 'LU',
      legalBasis: 'Constitution Art 19-22 (freedom of religion); '
          'Law of 31 October 2008 on relations between state and religious communities; '
          'Law of 28 November 2006 (equal treatment). Conventions with recognized religions.',
      constitutionalProvision: 'Art 19: Freedom of religion guaranteed. Art 22: State intervention '
          'in appointment of religious leaders. 2015 reform: separation of church and state. '
          'Conventions with Catholic, Protestant, Orthodox, Jewish, Muslim, Anglican communities.',
      foodAccess: HalalKosherAccess(
        schools: 'Schools accommodate dietary needs. Luxembourg City schools offer alternatives.',
        hospitals: 'Hospitals provide dietary alternatives on request.',
        prisons: 'Centre Pénitentiaire de Luxembourg accommodates religious diets.',
        military: 'Luxembourg Army accommodates dietary needs.',
        generalAvailability: 'Available in Luxembourg City. Growing Muslim population '
            '(~3-4% of population).',
        slaughterLaw: 'Ritual slaughter without stunning prohibited since 2018 animal '
            'welfare law reform.',
      ),
      holidayRights: ReligiousHolidayRights(
        legalFramework: 'Labour Code. No specific non-Christian holiday provisions.',
        employeeRights: 'Annual leave used for religious holidays. Employer accommodation '
            'encouraged.',
        publicSectorPolicy: 'Civil service allows flexible arrangements.',
        keyHolidays: 'Public holidays include Catholic holidays. No Muslim holidays.',
      ),
      clothingRights: ReligiousClothingRights(
        workplace: 'Generally permitted. Anti-discrimination law applies.',
        publicSchools: 'No ban. Religious education reformed in 2017 — replaced with '
            '"Life and Society" (Vie et Société) course.',
        governmentBuildings: 'No formal ban on religious clothing.',
        faceCoveringLaw: 'Face covering ban enacted 2018 for public buildings and transport. '
            'Fine: €25-€250.',
        keyLegalCases: 'Limited case law. CET (Centre pour l\'Égalité de Traitement) '
            'handles some religious discrimination cases.',
      ),
      prayerRoomRights: PrayerRoomRights(
        employerObligations: 'No legal obligation.',
        publicInstitutions: 'Limited provision.',
        airports: 'Luxembourg Airport (LUX) has interfaith prayer room.',
        universities: 'University of Luxembourg has quiet rooms.',
      ),
      educationRights: ReligiousEducationRights(
        publicSchoolPolicy: '2017 reform replaced confessional RE with "Vie et Société" '
            '(Life and Society) — mandatory non-confessional course covering ethics, '
            'citizenship, and world religions for all students.',
        optOutRight: 'No opt-out needed — Vie et Société is non-confessional.',
        alternativeEthicsClass: 'Vie et Société replaced both religious and ethics classes.',
        religiousSchools: 'Some Catholic schools. Religious communities may organize '
            'supplementary education outside school hours.',
      ),
      worshipRights: PlacesOfWorshipRights(
        permitProcess: 'Standard planning permit through commune.',
        zoningLaw: 'Standard urban planning. Religious buildings subject to PAG '
            '(Plan d\'Aménagement Général).',
        minaretRestrictions: 'No restrictions. Mosques operate in Luxembourg City, Esch-sur-Alzette.',
        recentIssues: 'Small country with relatively tolerant approach. '
            'Muslim community (Shoura) has convention with state since 2015.',
      ),
      discriminationComplaints: DiscriminationComplaints(
        equalityBody: 'Centre pour l\'Égalité de Traitement (CET)',
        contactInfo: '31, rue du Fossé, L-1536 Luxembourg. Tel: +352 26 48 30 33',
        onlineFiling: 'https://cet.lu/ — complaint form available',
        legalAidAvailable: 'Yes. Assistance judiciaire based on income.',
        timeLimit: '5 years for discrimination claims.',
      ),
      burialRights: BurialRights(
        islamicBurial: 'Muslim sections in Luxembourg municipal cemeteries.',
        jewishBurial: 'Jewish cemeteries in Luxembourg City.',
        dedicatedSections: 'Available in major communes.',
        repatriationOfRemains: 'Permitted. Consular assistance available.',
        embalming: 'Not required by law.',
      ),
      chaplaincyRights: ChaplaincyRights(
        prisons: 'Religious access guaranteed. Muslim spiritual care available.',
        hospitals: 'Multi-faith chaplaincy available.',
        military: 'Limited. Luxembourg Army small.',
        multiReligious: 'Post-2015 reform treats all recognized communities more equally.',
      ),
      immigrantSpecificNotes: 'Luxembourg reformed its church-state relations in 2015, creating '
          'a more equal framework for all recognized religions including Islam. The Shoura '
          '(Muslim community council) has a convention with the state. Education reform in 2017 '
          'replaced confessional RE with non-confessional "Vie et Société." Very high immigrant '
          'population (~47% non-Luxembourgish) means diversity is mainstream. Ritual slaughter '
          'without stunning banned since 2018. Limited face covering ban. Generally progressive.',
    ),

    // ========================================================================
    // 19. MALTA (MT)
    // ========================================================================
    ReligiousRightsInfo(
      country: 'Malta',
      countryCode: 'MT',
      legalBasis: 'Constitution Art 40 (freedom of conscience and religion); '
          'Art 2 (Roman Catholicism is state religion); '
          'Equality for Men and Women Act; Employment and Industrial Relations Act.',
      constitutionalProvision: 'Art 2: Roman Apostolic Catholic religion is the religion of Malta. '
          'Catholic moral teaching as basis of education. Art 40: Freedom of conscience and '
          'religion guaranteed. All persons equal regardless of creed.',
      foodAccess: HalalKosherAccess(
        schools: 'Limited provision. Catholic ethos in state schools. '
            'Individual accommodation possible.',
        hospitals: 'Mater Dei Hospital accommodates dietary requests.',
        prisons: 'Corradino Correctional Facility accommodates religious diets.',
        military: 'Armed Forces of Malta accommodate on request.',
        generalAvailability: 'Limited but growing. Some halal options in areas with '
            'immigrant communities. Small Muslim population.',
        slaughterLaw: 'Ritual slaughter regulated under animal welfare legislation.',
      ),
      holidayRights: ReligiousHolidayRights(
        legalFramework: 'Employment and Industrial Relations Act. Public holidays are Catholic.',
        employeeRights: 'Annual leave used for non-Catholic religious holidays.',
        publicSectorPolicy: 'No specific non-Catholic provisions.',
        keyHolidays: '14 public holidays — many Catholic (Feast of St Paul\'s Shipwreck, '
            'Assumption, Immaculate Conception, etc.). No Muslim holidays.',
      ),
      clothingRights: ReligiousClothingRights(
        workplace: 'No specific restrictions.',
        publicSchools: 'No ban on religious clothing.',
        governmentBuildings: 'No formal restrictions.',
        faceCoveringLaw: 'No face covering ban.',
        keyLegalCases: 'Limited case law on religious clothing for non-Catholics.',
      ),
      prayerRoomRights: PrayerRoomRights(
        employerObligations: 'No legal obligation.',
        publicInstitutions: 'Catholic chapels widespread. Limited multi-faith provision.',
        airports: 'Malta International Airport has no dedicated multi-faith prayer room.',
        universities: 'University of Malta has Catholic chapel. No multi-faith room.',
      ),
      educationRights: ReligiousEducationRights(
        publicSchoolPolicy: 'Catholic RE in state schools (Art 2 of Constitution). '
            'Ethics option introduced.',
        optOutRight: 'Parents can request exemption from Catholic RE.',
        alternativeEthicsClass: 'Ethics class being developed as alternative.',
        religiousSchools: 'Catholic schools dominant. No Islamic or Jewish schools.',
      ),
      worshipRights: PlacesOfWorshipRights(
        permitProcess: 'Planning permission through Planning Authority (MEPA successor).',
        zoningLaw: 'Standard urban planning. Small island — space limited.',
        minaretRestrictions: 'No specific restrictions. Mariam Al-Batool Mosque in Paola '
            'is the main mosque.',
        recentIssues: 'Growing Muslim community due to immigration. '
            'Mariam Al-Batool Mosque serves main community.',
      ),
      discriminationComplaints: DiscriminationComplaints(
        equalityBody: 'National Commission for the Promotion of Equality (NCPE)',
        contactInfo: 'Gattard House, National Road, Blata l-Bajda. Tel: +356 2590 3850',
        onlineFiling: 'https://ncpe.gov.mt/ — complaint form available',
        legalAidAvailable: 'Yes. Legal aid based on income.',
        timeLimit: '4 months for NCPE complaints.',
      ),
      burialRights: BurialRights(
        islamicBurial: 'Muslim section in Addolorata Cemetery (Ta\' Braxia). Limited space.',
        jewishBurial: 'Jewish section in Kalkara naval cemetery.',
        dedicatedSections: 'Very limited due to small island size.',
        repatriationOfRemains: 'Permitted. Consular assistance available.',
        embalming: 'Regulations apply due to climate.',
      ),
      chaplaincyRights: ChaplaincyRights(
        prisons: 'Catholic chaplaincy. Other faiths accommodated on request.',
        hospitals: 'Catholic chaplaincy in Mater Dei Hospital.',
        military: 'Catholic military chaplaincy.',
        multiReligious: 'Heavily Catholic-oriented. Multi-faith developing slowly.',
      ),
      immigrantSpecificNotes: 'Malta is constitutionally Catholic — Roman Catholicism is the state '
          'religion. This creates a unique environment where Catholic institutions permeate public '
          'life. However, Art 40 guarantees freedom of religion. Growing Muslim immigrant community '
          'served by Mariam Al-Batool Mosque in Paola. No face covering ban or headscarf '
          'restrictions. Limited but developing infrastructure for non-Catholic religions. '
          'Very small country — services concentrated in main urban area.',
    ),

    // ========================================================================
    // 20. NETHERLANDS (NL)
    // ========================================================================
    ReligiousRightsInfo(
      country: 'Netherlands',
      countryCode: 'NL',
      legalBasis: 'Constitution Art 1 (equality), Art 6 (freedom of religion); '
          'General Equal Treatment Act 1994 (AWGB — Algemene wet gelijke behandeling); '
          'Penal Code Art 137c-g (hate speech/discrimination).',
      constitutionalProvision: 'Art 6: Everyone has right to profess religion or belief freely, '
          'individually or in community. Complete separation of church and state since 1983. '
          'No recognized/official religions — all treated equally.',
      foodAccess: HalalKosherAccess(
        schools: 'Schools accommodate dietary needs. Amsterdam, Rotterdam, The Hague, '
            'Utrecht schools commonly offer halal options.',
        hospitals: 'Hospitals accommodate. Amsterdam UMC, Erasmus MC provide halal/kosher.',
        prisons: 'Dienst Justitiële Inrichtingen (DJI) provides halal meals in all prisons. '
            'Long-established practice.',
        military: 'Royal Netherlands Armed Forces provide halal meals.',
        generalAvailability: 'Widely available. Netherlands has large Muslim population (~5%). '
            'Strong halal market. Halal certification by various Dutch bodies.',
        slaughterLaw: 'Ritual slaughter without stunning: controversial but still permitted. '
            'Senate rejected ban in 2012. Covenant agreed requiring animals to lose consciousness '
            'within 40 seconds or stunning must occur.',
      ),
      holidayRights: ReligiousHolidayRights(
        legalFramework: 'Working Hours Act (Arbeidstijdenwet). No statutory right to '
            'non-Christian religious holidays.',
        employeeRights: 'Employees can request leave. CGB/NIHR rulings indicate employers '
            'should accommodate where possible. Use annual leave or CBA provisions.',
        publicSectorPolicy: 'Government encourages flexible scheduling for diverse workforce.',
        keyHolidays: 'Public holidays: King\'s Day, Liberation Day, and Christian holidays '
            '(Easter, Ascension, Whitsun, Christmas). No Muslim holidays.',
      ),
      clothingRights: ReligiousClothingRights(
        workplace: 'Generally permitted. AWGB protects against religious discrimination. '
            'Netherlands Institute for Human Rights (NIHR) has ruled on numerous headscarf cases.',
        publicSchools: 'No ban in public schools. Bijzondere scholen (special/denominational schools) '
            'may have own dress codes including Islamic schools.',
        governmentBuildings: 'Partial face covering ban in specific settings (2019). '
            'No hijab ban for public servants. Police accommodate hijab.',
        faceCoveringLaw: 'Partial ban (2019): face coverings banned in education buildings, '
            'hospitals, public transport, and government buildings. Fine: €150. '
            'Not a general public space ban.',
        keyLegalCases: 'NIHR opinions on headscarf in workplace (numerous). Generally protective '
            'of headscarf right. CJEU Achbita/Bougnaoui cases influential.',
      ),
      prayerRoomRights: PrayerRoomRights(
        employerObligations: 'No statutory obligation. NIHR has indicated employers should consider '
            'reasonable accommodation for prayer needs.',
        publicInstitutions: 'Hospitals, some government buildings have multi-faith rooms.',
        airports: 'Schiphol Airport (AMS) has interfaith meditation centre (Schiphol Kerk/Moskee).',
        universities: 'VU Amsterdam, University of Amsterdam, Leiden University, Utrecht University '
            'have multi-faith prayer spaces.',
      ),
      educationRights: ReligiousEducationRights(
        publicSchoolPolicy: 'Dutch system is unique: Art 23 Constitution guarantees freedom of '
            'education. State funds both public and religious schools equally. '
            'No RE in public schools. Religious schools provide their own RE.',
        optOutRight: 'Public schools: no RE to opt out of. Religious schools: attendance at '
            'RE part of school program but parents choose the school.',
        alternativeEthicsClass: 'Public schools teach citizenship education (burgerschap) including '
            'religious literacy.',
        religiousSchools: '~50 Islamic primary schools and several Islamic secondary schools. '
            'State funded. Islamic University of Rotterdam (IUR) for higher education. '
            'Schools must meet quality standards. Some Islamic schools closed for quality issues.',
      ),
      worshipRights: PlacesOfWorshipRights(
        permitProcess: 'Standard omgevingsvergunning (environmental permit) through municipality.',
        zoningLaw: 'Bestemmingsplan (zoning plan). Religious buildings classified as '
            'community facilities (maatschappelijk). Generally allowed in mixed zones.',
        minaretRestrictions: 'No ban. Subject to building regulations. PVV has proposed '
            'restrictions but no legislation passed.',
        recentIssues: 'Well-established mosque network (~500 mosques/prayer houses). '
            'Turkish (Diyanet), Moroccan, Surinamese Islamic organizations. '
            'Some municipalities resist new mosque construction.',
      ),
      discriminationComplaints: DiscriminationComplaints(
        equalityBody: 'Netherlands Institute for Human Rights '
            '(College voor de Rechten van de Mens)',
        contactInfo: 'Kleinesingel 1-3, 3572 CE Utrecht. Tel: +30 888 070 070',
        onlineFiling: 'https://mensenrechten.nl/ — online complaint form in NL/EN',
        legalAidAvailable: 'Yes. Gesubsidieerde rechtsbijstand (legal aid) based on income. '
            'Anti-discrimination bureaus (ADVs) in every region provide free assistance. '
            'Art.1 (national network) coordinates.',
        timeLimit: 'No statutory time limit for NIHR complaints. Employment: 2 months for '
            'formal complaint, 6 months for NIHR.',
      ),
      burialRights: BurialRights(
        islamicBurial: 'Islamic sections in many municipal cemeteries. Almere has dedicated '
            'Islamic cemetery. Amsterdam (De Nieuwe Ooster), Rotterdam, The Hague, Utrecht '
            'all have Islamic sections. Grave tenure: 10-20 years (renewable). '
            'Burial without coffin: varies by municipality, some allow shroud in specific sections.',
        jewishBurial: 'Jewish cemeteries well-established. NIK manages. '
            'Perpetual grave rights (eeuwig graf) tradition.',
        dedicatedSections: 'Widely available in major cities. ~100 Islamic cemetery sections.',
        repatriationOfRemains: 'Permitted. Well-established process. '
            'Uitvaartverzorging (funeral insurance) available through mosque associations. '
            'Cost: €2,000-€5,000.',
        embalming: 'Not required by law. Wet op de lijkbezorging (Burial Act) allows '
            'religious preparation.',
      ),
      chaplaincyRights: ChaplaincyRights(
        prisons: 'Muslim prison chaplaincy (geestelijke verzorging) fully institutionalized. '
            'Muslim chaplains employed by DJI in all prisons. Dienst Geestelijke Verzorging '
            'provides framework. ~40 Muslim chaplains.',
        hospitals: 'Hospital spiritual care (geestelijke verzorging) includes Muslim chaplains. '
            'Major hospitals have multi-faith teams.',
        military: 'Muslim military chaplaincy (geestelijke verzorging bij defensie) since 2003. '
            'Muslim chaplains serve in Royal Netherlands Armed Forces.',
        multiReligious: 'Netherlands has one of the most developed multi-faith chaplaincy systems '
            'in Europe. Humanist, Muslim, Hindu, Buddhist chaplains alongside Christian ones. '
            'Training at VU Amsterdam Islamic Theology program.',
      ),
      immigrantSpecificNotes: 'Netherlands has ~1 million Muslims (~5.8% of population). '
          'Strong anti-discrimination framework through AWGB and NIHR. Art 23 Constitution means '
          '~50 state-funded Islamic schools. Well-developed Muslim chaplaincy in prisons, military, '
          'hospitals. Partial face covering ban (2019) is more limited than in France/Belgium. '
          'Ritual slaughter compromise (40-second rule). Network of ~500 mosques. '
          'Regional anti-discrimination bureaus provide accessible complaint mechanism. '
          'Political climate can be hostile (PVV) but institutional protections are strong.',
    ),

    // ========================================================================
    // 21. POLAND (PL)
    // ========================================================================
    ReligiousRightsInfo(
      country: 'Poland',
      countryCode: 'PL',
      legalBasis: 'Constitution Art 25, 53 (freedom of religion); '
          'Act on Guarantees of Freedom of Conscience and Religion 1989; '
          'Act on the Relation of the State to the Muslim Religious Union 1936; '
          'Equal Treatment Act 2010.',
      constitutionalProvision: 'Art 25: Churches and religious organizations have equal rights. '
          'State is impartial in matters of religion. Art 53: Freedom of religion. '
          'Concordat with Holy See 1993. 15 registered religious communities including '
          'Muslim Religious Union in Poland (MZR, established 1925).',
      foodAccess: HalalKosherAccess(
        schools: 'No systematic provision. Individual accommodation on request.',
        hospitals: 'Hospitals accommodate dietary requests individually.',
        prisons: 'Central Board of Prison Service regulations require accommodation. '
            'Practice varies.',
        military: 'Polish Armed Forces accommodate on request.',
        generalAvailability: 'Limited but growing in Warsaw, Gdańsk. '
            'Small but historic Muslim community (Lipka Tatars + recent immigrants).',
        slaughterLaw: 'Ritual slaughter without stunning banned 2012 (Constitutional Tribunal '
            'upheld ban 2014). Amendment 2014: ritual slaughter for export permitted. '
            'Domestic ritual slaughter remains banned.',
      ),
      holidayRights: ReligiousHolidayRights(
        legalFramework: 'Labour Code. Act of 1989 on Freedom of Religion provides some provisions.',
        employeeRights: 'Members of registered religious communities may request leave for '
            'religious holidays. Must work extra hours to compensate. MZR members can '
            'request Eid leave.',
        publicSectorPolicy: 'Civil service follows standard holiday calendar.',
        keyHolidays: 'Public holidays include Catholic holidays (Corpus Christi, Assumption, '
            'All Saints). No Muslim holidays.',
      ),
      clothingRights: ReligiousClothingRights(
        workplace: 'No specific restrictions. Equal Treatment Act applies.',
        publicSchools: 'No ban on religious clothing.',
        governmentBuildings: 'No formal restrictions.',
        faceCoveringLaw: 'No face covering ban.',
        keyLegalCases: 'Limited case law on religious clothing for non-Christians.',
      ),
      prayerRoomRights: PrayerRoomRights(
        employerObligations: 'No legal obligation.',
        publicInstitutions: 'Catholic chapels common. Multi-faith rooms rare.',
        airports: 'Warsaw Chopin Airport has interfaith chapel.',
        universities: 'No formal multi-faith rooms in most universities.',
      ),
      educationRights: ReligiousEducationRights(
        publicSchoolPolicy: 'Religious education optional in public schools. '
            'Catholic RE dominant. Islamic RE possible through MZR but rarely organized.',
        optOutRight: 'Fully optional — parental choice.',
        alternativeEthicsClass: 'Ethics class available as alternative. '
            'Availability varies — not always offered despite legal requirement.',
        religiousSchools: 'Catholic schools extensive. No Islamic schools. '
            'Jewish school in Warsaw (Lauder-Morasha).',
      ),
      worshipRights: PlacesOfWorshipRights(
        permitProcess: 'Standard building permit through local authority.',
        zoningLaw: 'Spatial planning and development act. Standard regulations.',
        minaretRestrictions: 'No restrictions. Mosque in Gdańsk (planned, delayed). '
            'Historic mosques in Bohoniki and Kruszyniany (Tatar villages).',
        recentIssues: 'Warsaw mosque debate ongoing. Muslim Religious Union operates mosques '
            'in Warsaw, Białystok, Gdańsk. Historic Tatar mosques are cultural monuments.',
      ),
      discriminationComplaints: DiscriminationComplaints(
        equalityBody: 'Commissioner for Human Rights (Rzecznik Praw Obywatelskich)',
        contactInfo: 'Al. Solidarności 77, 00-090 Warsaw. Tel: +48 22 55 17 700',
        onlineFiling: 'https://www.rpo.gov.pl/ — online complaint in PL/EN',
        legalAidAvailable: 'Yes. Free legal aid points (nieodpłatna pomoc prawna). '
            'Helsinki Foundation for Human Rights provides legal support.',
        timeLimit: '3 years for civil discrimination claims.',
      ),
      burialRights: BurialRights(
        islamicBurial: 'Muslim cemeteries in Warsaw (Muslim section in Powązki area), '
            'Bohoniki and Kruszyniany (historic Tatar cemeteries).',
        jewishBurial: 'Jewish cemeteries in Warsaw (Okopowa), Kraków, Łódź. '
            'Jewish Community manages.',
        dedicatedSections: 'Limited. Warsaw has Muslim section. Historic Tatar villages.',
        repatriationOfRemains: 'Permitted under standard regulations.',
        embalming: 'Not required by law.',
      ),
      chaplaincyRights: ChaplaincyRights(
        prisons: 'Religious access guaranteed under 1989 Act. Muslim spiritual care limited.',
        hospitals: 'Catholic chaplaincy dominant. Other faiths on request.',
        military: 'Catholic military chaplaincy (Ordynariat Polowy). '
            'Orthodox military chaplaincy. No Muslim military chaplaincy.',
        multiReligious: 'Catholic Church dominant in chaplaincy. Multi-faith developing slowly.',
      ),
      immigrantSpecificNotes: 'Poland has a historic Muslim community — Lipka Tatars since 14th '
          'century. Muslim Religious Union in Poland (MZR) established 1925, one of oldest '
          'Islamic organizations in Europe. However, infrastructure is minimal. Ritual slaughter '
          'for domestic consumption banned (2014 exception for export). No face covering ban. '
          'No headscarf restrictions. Political climate: government has been resistant to Muslim '
          'immigration. Commissioner for Human Rights is an active defender of religious rights. '
          'Equal Treatment Act provides basic protection.',
    ),

    // ========================================================================
    // 22. PORTUGAL (PT)
    // ========================================================================
    ReligiousRightsInfo(
      country: 'Portugal',
      countryCode: 'PT',
      legalBasis: 'Constitution Art 13 (equality), Art 41 (freedom of conscience and religion); '
          'Religious Freedom Act 2001 (Lei da Liberdade Religiosa 16/2001); '
          'Concordat with Holy See 2004; Labour Code Art 14 (non-discrimination).',
      constitutionalProvision: 'Art 41: Freedom of conscience, religion and worship inviolable. '
          'No state religion. Churches and religious communities separated from state. '
          'Religious Freedom Act 2001 provides framework for all religions.',
      foodAccess: HalalKosherAccess(
        schools: 'Schools accommodate dietary needs on request. '
            'Lisbon and Porto schools increasingly responsive.',
        hospitals: 'Hospitals accommodate dietary requests.',
        prisons: 'Prison Service (DGRSP) accommodates religious dietary needs.',
        military: 'Portuguese Armed Forces accommodate on request.',
        generalAvailability: 'Available in Lisbon, Porto. Growing with Bangladeshi, '
            'Indian, African Muslim immigrant communities.',
        slaughterLaw: 'Ritual slaughter regulated under animal welfare law. '
            'Exemptions available for religious communities.',
      ),
      holidayRights: ReligiousHolidayRights(
        legalFramework: 'Labour Code. Religious Freedom Act Art 14: members of registered '
            'communities entitled to observe their days of rest and holidays.',
        employeeRights: 'Art 14 Religious Freedom Act: employees of registered religious '
            'communities may take religious holidays — must compensate hours. '
            'Employer must be notified. One of most progressive laws in EU.',
        publicSectorPolicy: 'Public servants also covered under Religious Freedom Act.',
        keyHolidays: 'Public holidays include Catholic holidays (Corpus Christi, Assumption, '
            'All Saints, Immaculate Conception). Registered community members can take own holidays.',
      ),
      clothingRights: ReligiousClothingRights(
        workplace: 'No specific restrictions. Anti-discrimination applies.',
        publicSchools: 'No ban on religious clothing.',
        governmentBuildings: 'No formal restrictions.',
        faceCoveringLaw: 'No face covering ban.',
        keyLegalCases: 'Very limited case law on religious clothing.',
      ),
      prayerRoomRights: PrayerRoomRights(
        employerObligations: 'No legal obligation but Religious Freedom Act encourages accommodation.',
        publicInstitutions: 'Catholic chapels in hospitals. Multi-faith limited.',
        airports: 'Lisbon Airport (LIS) has interfaith prayer room.',
        universities: 'Limited provision. University of Lisbon has some accommodation.',
      ),
      educationRights: ReligiousEducationRights(
        publicSchoolPolicy: 'Religious education optional in public schools. '
            '"Moral and Religious Catholic Education" most common. '
            'Other religions may provide RE if demand exists.',
        optOutRight: 'Fully optional — parental enrollment.',
        alternativeEthicsClass: 'No mandatory ethics alternative (RE is already optional).',
        religiousSchools: 'Catholic schools. No Islamic schools. '
            'Islamic Community can organize community education.',
      ),
      worshipRights: PlacesOfWorshipRights(
        permitProcess: 'Standard building license (licença de construção). '
            'Registered communities may request facilities.',
        zoningLaw: 'Municipal development plans (PDM). '
            'Religious buildings classified as community facilities.',
        minaretRestrictions: 'No restrictions. Lisbon Central Mosque (Mesquita Central de Lisboa) '
            'has minaret — one of oldest in Western Europe (1985).',
        recentIssues: 'Generally positive climate. Lisbon Central Mosque well-established. '
            'Growing community in Odivelas, Amadora, Porto.',
      ),
      discriminationComplaints: DiscriminationComplaints(
        equalityBody: 'Commission for Equality and Against Racial Discrimination (CICDR) / '
            'Provedor de Justiça (Ombudsman)',
        contactInfo: 'CICDR: Rua Álvaro Coutinho 14, 1150-025 Lisbon. Tel: +351 218 106 100. '
            'Ombudsman: Rua do Pau de Bandeira 7-9, 1249-088 Lisbon. Tel: +351 213 926 600',
        onlineFiling: 'CICDR: https://www.cicdr.pt/ — online form. '
            'Ombudsman: https://www.provedor-jus.pt/',
        legalAidAvailable: 'Yes. Proteção jurídica (legal protection) based on income. '
            'SOS Racismo Portugal provides support.',
        timeLimit: '1 year for employment discrimination. Civil claims: 3 years.',
      ),
      burialRights: BurialRights(
        islamicBurial: 'Islamic section in Lisbon (Cemitério do Alto de São João). '
            'Islamic Community of Lisbon manages burial.',
        jewishBurial: 'Jewish cemeteries in Lisbon, Porto, Faro (historic).',
        dedicatedSections: 'Available in Lisbon. Limited elsewhere.',
        repatriationOfRemains: 'Permitted. Consular assistance available.',
        embalming: 'Not required by law for domestic burial.',
      ),
      chaplaincyRights: ChaplaincyRights(
        prisons: 'Religious Freedom Act guarantees access. Muslim spiritual care available on request.',
        hospitals: 'Catholic chaplaincy dominant. Religious Freedom Act requires accommodation.',
        military: 'Catholic military chaplaincy. Other faiths accommodated under Religious Freedom Act.',
        multiReligious: 'Religious Freedom Act 2001 provides progressive framework for multi-faith '
            'chaplaincy. Implementation developing.',
      ),
      immigrantSpecificNotes: 'Portugal has one of the EU\'s most progressive Religious Freedom Acts '
          '(2001). Art 14 explicitly grants religious holiday rights to members of registered '
          'communities — a model for other EU countries. No face covering ban, no headscarf '
          'restrictions. Lisbon Central Mosque established since 1985. Growing Muslim population '
          'from Bangladesh, Guinea-Bissau, Mozambique, India, Pakistan. Generally tolerant society. '
          'CICDR handles discrimination complaints. Islamic Community of Lisbon is the primary '
          'representative body.',
    ),

    // ========================================================================
    // 23. ROMANIA (RO)
    // ========================================================================
    ReligiousRightsInfo(
      country: 'Romania',
      countryCode: 'RO',
      legalBasis: 'Constitution Art 29 (freedom of conscience and religion); '
          'Law 489/2006 on Religious Freedom and the General Regime of Religious Denominations; '
          'Ordinance 137/2000 (anti-discrimination).',
      constitutionalProvision: 'Art 29: Freedom of thought, opinion, and religion. Autonomous '
          'religious denominations. Romanian Orthodox Church has special role as church of majority. '
          '18 recognized religious denominations including Muslim Denomination (Muftiatul Cultului '
          'Musulman din România).',
      foodAccess: HalalKosherAccess(
        schools: 'Available in Dobrudja region (historic Muslim area). '
            'Limited elsewhere.',
        hospitals: 'Individual accommodation on request.',
        prisons: 'Prison administration should accommodate under law.',
        military: 'Romanian Armed Forces accommodate on request.',
        generalAvailability: 'Available in Constanța, Bucharest. Dobrudja region has '
            'established halal infrastructure. Turkish/Tatar Muslim minority community.',
        slaughterLaw: 'Ritual slaughter permitted with exemptions under animal welfare regulations.',
      ),
      holidayRights: ReligiousHolidayRights(
        legalFramework: 'Labour Code. Law 489/2006 provides that recognized denominations '
            'have the right to religious holidays.',
        employeeRights: 'Members of recognized denominations can take up to 2 days off for '
            'religious holidays not coinciding with public holidays.',
        publicSectorPolicy: 'Civil servants also covered.',
        keyHolidays: 'Public holidays follow Orthodox calendar (Orthodox Easter, Christmas on '
            'Dec 25-26). Muslim denomination members can take Bayram (Eid) days.',
      ),
      clothingRights: ReligiousClothingRights(
        workplace: 'No specific restrictions. Anti-discrimination ordinance applies.',
        publicSchools: 'No ban on religious clothing.',
        governmentBuildings: 'No formal restrictions.',
        faceCoveringLaw: 'No face covering ban.',
        keyLegalCases: 'Limited case law. CNCD (National Council for Combating Discrimination) '
            'has addressed some cases.',
      ),
      prayerRoomRights: PrayerRoomRights(
        employerObligations: 'No legal obligation.',
        publicInstitutions: 'Orthodox chapels in hospitals. Limited multi-faith provision.',
        airports: 'Bucharest Henri Coandă Airport has interfaith chapel.',
        universities: 'Limited multi-faith provision.',
      ),
      educationRights: ReligiousEducationRights(
        publicSchoolPolicy: 'Religious education based on student\'s denomination. '
            'Islamic RE available in Dobrudja for Muslim students.',
        optOutRight: 'Constitutional Court 2015: opt-out requires only written request '
            '(not justification). Previously required public opt-out.',
        alternativeEthicsClass: 'No mandatory alternative; RE is optional.',
        religiousSchools: 'Muslim theological seminary (Seminarul Teologic Musulman) in '
            'Medgidia, Constanța county. Orthodox, Catholic schools common.',
      ),
      worshipRights: PlacesOfWorshipRights(
        permitProcess: 'Standard building authorization through local authority.',
        zoningLaw: 'Urban planning regulations. No specific restrictions.',
        minaretRestrictions: 'No restrictions. Historic mosques in Constanța (Carol I Mosque, '
            'Hunchiar Mosque), Mangalia, Babadag.',
        recentIssues: 'Dobrudja has well-established mosque infrastructure. '
            'Muftiatul manages Muslim community affairs. Some tensions over new developments.',
      ),
      discriminationComplaints: DiscriminationComplaints(
        equalityBody: 'National Council for Combating Discrimination (CNCD — '
            'Consiliul Național pentru Combaterea Discriminării)',
        contactInfo: 'Piața Valter Mărăcineanu 1-3, Sector 1, Bucharest. Tel: +40 21 312 65 78',
        onlineFiling: 'https://www.cncd.ro/ — online complaint form',
        legalAidAvailable: 'Yes. Free legal aid (asistență juridică gratuită) based on income. '
            'ActiveWatch and APADOR-CH provide human rights legal support.',
        timeLimit: '1 year for CNCD complaints.',
      ),
      burialRights: BurialRights(
        islamicBurial: 'Muslim cemeteries in Dobrudja (Constanța, Mangalia, Babadag, Medgidia). '
            'Muftiatul manages Islamic burial.',
        jewishBurial: 'Jewish cemeteries in Bucharest, Cluj, Iași. FCER manages.',
        dedicatedSections: 'Well-established in Dobrudja. Limited in Bucharest.',
        repatriationOfRemains: 'Permitted under standard regulations.',
        embalming: 'Not required by law.',
      ),
      chaplaincyRights: ChaplaincyRights(
        prisons: 'Religious access for recognized denominations. Muslim spiritual care '
            'available through Muftiatul.',
        hospitals: 'Orthodox chaplaincy dominant. Recognized denominations have access right.',
        military: 'Orthodox military chaplaincy. Other recognized denominations accommodated.',
        multiReligious: 'Recognized denomination system provides framework for multi-faith access.',
      ),
      immigrantSpecificNotes: 'Romania has a historic Muslim minority (~64,000, mainly Turkish and '
          'Tatar) in Dobrudja, recognized since Ottoman period. Muftiatul Cultului Musulman din '
          'România is one of 18 recognized denominations with state support. Muslim theological '
          'seminary exists in Medgidia. Established infrastructure in Dobrudja. Immigrant Muslims '
          'in Bucharest have less infrastructure. No face covering ban, no headscarf restrictions. '
          'Generally respectful of religious diversity in the recognized denomination framework.',
    ),

    // ========================================================================
    // 24. SLOVAKIA (SK)
    // ========================================================================
    ReligiousRightsInfo(
      country: 'Slovakia',
      countryCode: 'SK',
      legalBasis: 'Constitution Art 24 (freedom of religion); '
          'Act 308/1991 on Freedom of Religious Faith; '
          'Anti-Discrimination Act 365/2004.',
      constitutionalProvision: 'Art 24: Freedom of thought, conscience, religion and faith '
          'guaranteed. Right to change religion. Right to manifest religion publicly or privately. '
          'Registration requires 50,000 adult members (since 2017 amendment — highest threshold in EU).',
      foodAccess: HalalKosherAccess(
        schools: 'No formal provision. Negligible demand.',
        hospitals: 'Individual accommodation possible.',
        prisons: 'Should accommodate under European standards. Practice minimal.',
        military: 'No formal provision.',
        generalAvailability: 'Very limited. Bratislava has a few options. '
            'Tiny Muslim population (~5,000).',
        slaughterLaw: 'Ritual slaughter without stunning prohibited under animal welfare law.',
      ),
      holidayRights: ReligiousHolidayRights(
        legalFramework: 'Labour Code. No non-Christian provisions.',
        employeeRights: 'Annual leave used for religious holidays.',
        publicSectorPolicy: 'No specific provisions.',
        keyHolidays: 'Public holidays include Catholic holidays (Epiphany, Good Friday, '
            'Assumption, All Saints, Christmas). No Muslim holidays.',
      ),
      clothingRights: ReligiousClothingRights(
        workplace: 'No specific restrictions.',
        publicSchools: 'No ban but discussion occurred.',
        governmentBuildings: 'No formal restrictions.',
        faceCoveringLaw: 'Face covering ban proposed multiple times but not enacted.',
        keyLegalCases: 'Very limited case law.',
      ),
      prayerRoomRights: PrayerRoomRights(
        employerObligations: 'No legal obligation.',
        publicInstitutions: 'No formal provision.',
        airports: 'Bratislava Airport has no dedicated prayer room.',
        universities: 'No formal multi-faith rooms.',
      ),
      educationRights: ReligiousEducationRights(
        publicSchoolPolicy: 'Religious education or ethics class — mandatory choice.',
        optOutRight: 'Choice between RE (Catholic or other registered) and ethics.',
        alternativeEthicsClass: 'Ethics class (etická výchova) mandatory alternative to RE.',
        religiousSchools: 'Catholic schools. No Islamic schools. Islam not registered '
            '(does not meet 50,000-member threshold).',
      ),
      worshipRights: PlacesOfWorshipRights(
        permitProcess: 'Standard building permit.',
        zoningLaw: 'Standard urban planning.',
        minaretRestrictions: 'No restrictions in law. No mosques in Slovakia. '
            'Islamic Foundation operates from rented premises in Bratislava.',
        recentIssues: '50,000-member registration requirement (raised from 20,000 in 2017) '
            'effectively prevents Islamic community from registering. '
            'Only unregistered religious community status available.',
      ),
      discriminationComplaints: DiscriminationComplaints(
        equalityBody: 'Slovak National Centre for Human Rights '
            '(Slovenské národné stredisko pre ľudské práva)',
        contactInfo: 'Laurinská 18, 811 01 Bratislava. Tel: +421 2 2082 1030',
        onlineFiling: 'https://www.snslp.sk/ — complaint available',
        legalAidAvailable: 'Yes. Legal aid centre (Centrum právnej pomoci). '
            'Via Iuris provides legal support for discrimination cases.',
        timeLimit: '3 years for discrimination claims.',
      ),
      burialRights: BurialRights(
        islamicBurial: 'No dedicated Islamic cemetery or section in Slovakia.',
        jewishBurial: 'Jewish cemeteries in Bratislava, Košice.',
        dedicatedSections: 'None for Muslims.',
        repatriationOfRemains: 'Permitted under standard regulations.',
        embalming: 'Not required by law.',
      ),
      chaplaincyRights: ChaplaincyRights(
        prisons: 'Religious access for registered communities. Islam not registered.',
        hospitals: 'Catholic chaplaincy dominant.',
        military: 'Catholic and Protestant military chaplaincy.',
        multiReligious: 'Very limited. Islam\'s unregistered status creates barriers.',
      ),
      immigrantSpecificNotes: 'Slovakia has the highest registration threshold in the EU (50,000 members), '
          'which effectively prevents the Islamic community from registering. This means no state '
          'funding, limited institutional access, and reduced rights compared to registered religions. '
          'Very small Muslim population (~5,000). No mosques. Islamic Foundation in Bratislava '
          'operates from rented premises. No face covering ban. Anti-Discrimination Act provides '
          'basic protection. One of the most challenging EU countries for Muslim religious practice.',
    ),

    // ========================================================================
    // 25. SLOVENIA (SI)
    // ========================================================================
    ReligiousRightsInfo(
      country: 'Slovenia',
      countryCode: 'SI',
      legalBasis: 'Constitution Art 7, 41 (freedom of religion, separation of state and '
          'religion); Religious Freedom Act 2007 (Zakon o verski svobodi); '
          'Protection Against Discrimination Act 2016.',
      constitutionalProvision: 'Art 7: State and religious communities separated. '
          'Religious communities have equal rights. Art 41: Freedom of religion, right to '
          'freely express religious and other beliefs.',
      foodAccess: HalalKosherAccess(
        schools: 'Some accommodation in Ljubljana schools.',
        hospitals: 'Hospitals accommodate on request.',
        prisons: 'Prison Service accommodates religious dietary needs.',
        military: 'Slovenian Armed Forces accommodate on request.',
        generalAvailability: 'Limited. Ljubljana has some halal options. '
            'Muslim community (~50,000, mainly Bosniak).',
        slaughterLaw: 'Ritual slaughter without stunning prohibited under Animal Protection Act.',
      ),
      holidayRights: ReligiousHolidayRights(
        legalFramework: 'Employment Relationships Act. Religious Freedom Act Art 4 provides '
            'for religious holiday observance.',
        employeeRights: 'Religious Freedom Act: employees may request leave for religious holidays. '
            'Must agree with employer on compensation.',
        publicSectorPolicy: 'Accommodation possible through flexible arrangements.',
        keyHolidays: 'Public holidays are secular with two Catholic holidays (Easter Sunday, '
            'Assumption). No Muslim holidays.',
      ),
      clothingRights: ReligiousClothingRights(
        workplace: 'No specific restrictions. Anti-discrimination law applies.',
        publicSchools: 'No ban on religious clothing.',
        governmentBuildings: 'No formal restrictions.',
        faceCoveringLaw: 'No face covering ban.',
        keyLegalCases: 'Limited case law on religious clothing.',
      ),
      prayerRoomRights: PrayerRoomRights(
        employerObligations: 'No legal obligation.',
        publicInstitutions: 'Limited provision.',
        airports: 'Ljubljana Airport has no dedicated prayer room.',
        universities: 'University of Ljubljana has limited provision.',
      ),
      educationRights: ReligiousEducationRights(
        publicSchoolPolicy: 'No religious education in public schools (secular system). '
            'Religions and ethics taught within other subjects.',
        optOutRight: 'Not applicable — no RE in public schools.',
        alternativeEthicsClass: 'Civic and ethical education as part of curriculum.',
        religiousSchools: 'Catholic schools exist. No Islamic schools. '
            'Islamic Community provides community education.',
      ),
      worshipRights: PlacesOfWorshipRights(
        permitProcess: 'Standard building permit. Special spatial planning provisions '
            'for religious buildings under Religious Freedom Act.',
        zoningLaw: 'Municipal spatial planning. Religious buildings classified as public facilities.',
        minaretRestrictions: 'No specific restrictions. Ljubljana Islamic Cultural Centre and '
            'Mosque opened in 2020 after 50 years of efforts — includes minaret.',
        recentIssues: 'Ljubljana Mosque opening in 2020 was historic after decades of delays, '
            'referendums, and legal challenges. First purpose-built mosque in Slovenia.',
      ),
      discriminationComplaints: DiscriminationComplaints(
        equalityBody: 'Advocate of the Principle of Equality (Zagovornik načela enakosti)',
        contactInfo: 'Dunajska cesta 22, 1000 Ljubljana. Tel: +386 1 473 55 31',
        onlineFiling: 'https://www.zagovornik.si/ — online complaint form',
        legalAidAvailable: 'Yes. Free legal aid (brezplačna pravna pomoč). '
            'Peace Institute provides legal support for discrimination.',
        timeLimit: '1 year for Advocate complaints. Civil claims: 5 years.',
      ),
      burialRights: BurialRights(
        islamicBurial: 'Muslim sections in Ljubljana (Žale cemetery) and some other cities. '
            'Islamic Community manages burial.',
        jewishBurial: 'Very small Jewish community. Individual arrangements.',
        dedicatedSections: 'Available in Ljubljana. Limited elsewhere.',
        repatriationOfRemains: 'Permitted. Consular assistance available.',
        embalming: 'Not required by law.',
      ),
      chaplaincyRights: ChaplaincyRights(
        prisons: 'Religious Freedom Act guarantees access. Muslim spiritual care available.',
        hospitals: 'Chaplaincy available for registered communities.',
        military: 'Military chaplaincy developing. Catholic focused.',
        multiReligious: 'Religious Freedom Act 2007 provides progressive framework.',
      ),
      immigrantSpecificNotes: 'Slovenia has a significant Bosniak Muslim community (~50,000, ~2.5%). '
          'Ljubljana Mosque opened in 2020 after 50 years of effort — major milestone. '
          'Religious Freedom Act 2007 provides progressive framework. No face covering ban, '
          'no headscarf restrictions. Ritual slaughter without stunning banned. '
          'Islamic Community of Slovenia (Islamska skupnost v Republiki Sloveniji) is registered. '
          'Generally improving environment after mosque opening breakthrough.',
    ),

    // ========================================================================
    // 26. SPAIN (ES)
    // ========================================================================
    ReligiousRightsInfo(
      country: 'Spain',
      countryCode: 'ES',
      legalBasis: 'Constitution Art 14 (equality), Art 16 (freedom of religion); '
          'Organic Law 7/1980 on Religious Freedom; '
          'Cooperation Agreements 1992 (with Protestant, Jewish, Islamic communities); '
          'Equality Law 2007 (Ley de Igualdad).',
      constitutionalProvision: 'Art 16: Freedom of ideology, religion and worship guaranteed. '
          'No state religion. Public powers cooperate with Catholic Church and other denominations. '
          'Cooperation Agreements with CIE (Comisión Islámica de España) since 1992 — one of '
          'the most comprehensive Islamic agreements in Europe.',
      foodAccess: HalalKosherAccess(
        schools: 'Cooperation Agreement Art 14: halal food in public schools, hospitals, '
            'prisons, military. Implementation varies by Autonomous Community. '
            'Catalonia, Madrid, Andalucía more developed.',
        hospitals: 'Cooperation Agreement provides for halal food in hospitals. '
            'Major hospitals in Madrid, Barcelona accommodate.',
        prisons: 'Instituciones Penitenciarias provides halal meals. Well-established.',
        military: 'Spanish Armed Forces provide halal meals under Cooperation Agreement.',
        generalAvailability: 'Widely available. Spain has ~2 million Muslims. '
            'Large Moroccan community. Ceuta and Melilla have extensive halal infrastructure.',
        slaughterLaw: 'Ritual slaughter without stunning permitted under EU exemption. '
            'Cooperation Agreement Art 14 guarantees halal slaughter rights.',
      ),
      holidayRights: ReligiousHolidayRights(
        legalFramework: 'Workers\' Statute (Estatuto de los Trabajadores). '
            'Cooperation Agreements provide specific holiday rights.',
        employeeRights: 'Cooperation Agreement Art 12: Muslim employees have right to leave '
            'for Eid al-Fitr, Eid al-Adha, and Mawlid. May request Friday prayer time '
            '(1:30-4:30 PM) by agreement with employer. '
            'Ramadan working hours adjustable by agreement.',
        publicSectorPolicy: 'Public sector follows Cooperation Agreement provisions.',
        keyHolidays: 'National holidays include Catholic holidays (Assumption, All Saints, '
            'Immaculate Conception). Ceuta celebrates Eid as local holiday. '
            'Melilla celebrates Eid al-Fitr and Eid al-Adha as local holidays.',
      ),
      clothingRights: ReligiousClothingRights(
        workplace: 'Generally permitted. No specific restrictions. '
            'Anti-discrimination framework applies.',
        publicSchools: 'No ban on hijab. Some school-level controversies (Arteixo case 2010, '
            'Madrid case 2011) resolved in favor of student\'s right to wear hijab.',
        governmentBuildings: 'No formal ban. Debate ongoing but no legislation.',
        faceCoveringLaw: 'No national face covering ban. Some municipal ordinances (Lleida, '
            'Reus — struck down by Supreme Court 2013 as exceeding municipal competence).',
        keyLegalCases: 'Tribunal Supremo 2013: Lleida municipal niqab ban struck down. '
            'Arteixo school hijab case: Education Ministry ruled in favor of student.',
      ),
      prayerRoomRights: PrayerRoomRights(
        employerObligations: 'No statutory obligation. Cooperation Agreement encourages '
            'accommodation for Friday prayer.',
        publicInstitutions: 'Some hospitals and public buildings have multi-faith rooms.',
        airports: 'Madrid-Barajas has interfaith prayer room. Barcelona El Prat also.',
        universities: 'Some universities (Complutense Madrid, University of Granada) have spaces.',
      ),
      educationRights: ReligiousEducationRights(
        publicSchoolPolicy: 'Cooperation Agreement Art 10: Islamic RE in public schools '
            'where demand exists. CIE designates teachers. Offered in Ceuta, Melilla, '
            'Andalucía, Catalonia, Madrid. ~350,000 eligible students.',
        optOutRight: 'Religious education (Catholic, Islamic, Protestant, Jewish) is optional. '
            'Alternatives available.',
        alternativeEthicsClass: 'Social and Civic Values (Valores Sociales y Cívicos) in primary; '
            'Ethical Values (Valores Éticos) in secondary as alternatives.',
        religiousSchools: 'Catholic schools extensive. Very few Islamic schools. '
            'Islamic community education programs through CIE.',
      ),
      worshipRights: PlacesOfWorshipRights(
        permitProcess: 'Standard building license (licencia de obras) through ayuntamiento. '
            'Cooperation Agreement Art 2 recognizes right to places of worship.',
        zoningLaw: 'Plan General de Ordenación Urbana. Varies by municipality. '
            'Catalonia has specific Law on Places of Worship (2009).',
        minaretRestrictions: 'No national restrictions. Subject to local planning. '
            'Some local opposition but no systematic barriers.',
        recentIssues: 'Catalonia Law on Places of Worship (2009) required municipalities to '
            'designate land for worship. Some municipalities have resisted mosque construction. '
            'Spain has ~1,700 mosques/prayer halls.',
      ),
      discriminationComplaints: DiscriminationComplaints(
        equalityBody: 'Defensor del Pueblo (Ombudsman) / '
            'Council for the Elimination of Racial or Ethnic Discrimination',
        contactInfo: 'Defensor: Paseo Eduardo Dato 31, 28010 Madrid. Tel: +34 91 432 79 00. '
            'Discrimination Council: Tel: +34 900 20 30 41 (free)',
        onlineFiling: 'https://www.defensordelpueblo.es/ — online complaint. '
            'Discrimination Council: online reporting available',
        legalAidAvailable: 'Yes. Justicia gratuita based on income. '
            'Plataforma Ciudadana contra la Islamofobia tracks anti-Muslim incidents.',
        timeLimit: '1 year for employment discrimination. Civil claims: 4 years.',
      ),
      burialRights: BurialRights(
        islamicBurial: 'Cooperation Agreement Art 2: right to Islamic burial rites. '
            'Islamic sections in many municipal cemeteries (Granada, Seville, Madrid, Barcelona, '
            'Valencia). Ceuta and Melilla have Muslim cemeteries. '
            'Burial without coffin: varies by Autonomous Community.',
        jewishBurial: 'Jewish sections in major cemeteries. Federation of Jewish Communities manages.',
        dedicatedSections: 'Expanding. Over 50 municipalities have Islamic cemetery sections. '
            'Granada Islamic Cemetery historically significant.',
        repatriationOfRemains: 'Permitted. Well-established process, especially with Morocco. '
            'Bilateral agreements. Islamic community funds assist. Cost: €2,000-€5,000.',
        embalming: 'Not required by national law. Regional health regulations may apply.',
      ),
      chaplaincyRights: ChaplaincyRights(
        prisons: 'Cooperation Agreement Art 9: right to Islamic spiritual assistance in prison. '
            'Muslim chaplains (imams) in Instituciones Penitenciarias. ~40 prison imams.',
        hospitals: 'Right to spiritual care under Cooperation Agreement. '
            'Muslim chaplaincy developing in major hospitals.',
        military: 'Cooperation Agreement provides for Muslim military chaplaincy. '
            'Practice still developing.',
        multiReligious: 'Spain\'s Cooperation Agreement system is one of the most comprehensive '
            'in Europe. Provides framework for Catholic, Protestant, Jewish, Muslim chaplaincy.',
      ),
      immigrantSpecificNotes: 'Spain has one of Europe\'s most comprehensive legal frameworks for '
          'Islam through the 1992 Cooperation Agreement with CIE. This provides explicit rights '
          'for halal food, religious education, burial, chaplaincy, holidays, and Friday prayer. '
          'Implementation varies by Autonomous Community — Catalonia, Madrid, Andalucía most developed. '
          'No face covering ban (Supreme Court struck down municipal bans). No headscarf ban. '
          'Ritual slaughter permitted. ~2 million Muslims, mainly Moroccan origin. '
          'Ceuta and Melilla have Eid as local holidays. ~1,700 mosques/prayer halls. '
          'Plataforma Ciudadana contra la Islamofobia monitors anti-Muslim discrimination.',
    ),

    // ========================================================================
    // 27. SWEDEN (SE)
    // ========================================================================
    ReligiousRightsInfo(
      country: 'Sweden',
      countryCode: 'SE',
      legalBasis: 'Instrument of Government (Regeringsformen) Ch 2 §1 (freedom of religion); '
          'Discrimination Act 2008 (Diskrimineringslag 2008:567); '
          'Act on Religious Communities 1998 (Lag om trossamfund).',
      constitutionalProvision: 'Ch 2 §1 RF: Freedom of religion — freedom to practice religion '
          'alone or with others. Church of Sweden separated from state in 2000. '
          'No state religion. All religious communities equal before law.',
      foodAccess: HalalKosherAccess(
        schools: 'School Food Act requires schools to provide nutritious free meals. '
            'Many municipalities accommodate halal/special diets. '
            'Stockholm, Gothenburg, Malmö widely offer halal options.',
        hospitals: 'Hospitals accommodate dietary needs as standard practice.',
        prisons: 'Swedish Prison and Probation Service (Kriminalvården) provides '
            'religiously compliant meals in all facilities.',
        military: 'Swedish Armed Forces (Försvarsmakten) provide halal meals.',
        generalAvailability: 'Widely available nationwide. Large Muslim population (~800,000, ~8%). '
            'Strong halal market.',
        slaughterLaw: 'Ritual slaughter without prior stunning prohibited since 1937 '
            '(oldest ban in Europe). All slaughter must include stunning. '
            'Halal meat imports permitted.',
      ),
      holidayRights: ReligiousHolidayRights(
        legalFramework: 'Employment Protection Act (LAS) and collective agreements. '
            'No statutory non-Christian holiday rights.',
        employeeRights: 'Employees may use annual leave. Discrimination Act requires '
            'reasonable accommodation. DO (Equality Ombudsman) has addressed cases.',
        publicSectorPolicy: 'Public sector encourages flexible scheduling.',
        keyHolidays: 'Public holidays: mix of Christian (Easter, Ascension, Whitsun, Christmas) '
            'and secular (Midsummer, National Day). No Muslim holidays.',
      ),
      clothingRights: ReligiousClothingRights(
        workplace: 'Generally permitted. Discrimination Act protects against religious '
            'discrimination in employment. AD (Labour Court) has addressed headscarf cases.',
        publicSchools: 'No ban on hijab. Some schools have attempted restrictions — '
            'DO has ruled against such restrictions.',
        governmentBuildings: 'No ban. Police authority explored hijab-compatible uniform. '
            'No judicial restrictions.',
        faceCoveringLaw: 'Face covering ban in schools enacted 2020 (applies to niqab/burqa '
            'in education settings — preschool through upper secondary). '
            'No general public space ban.',
        keyLegalCases: 'AD 2017/65: Labour Court addressed religious headscarf in workplace. '
            'DO cases on school hijab restrictions ruled discriminatory.',
      ),
      prayerRoomRights: PrayerRoomRights(
        employerObligations: 'No statutory obligation. Reasonable accommodation under '
            'Discrimination Act may apply in specific cases.',
        publicInstitutions: 'Hospitals have multi-faith rooms. Public buildings increasingly accommodate.',
        airports: 'Stockholm Arlanda has interfaith prayer room. Gothenburg Landvetter also.',
        universities: 'Stockholm University, Uppsala University, Lund University, '
            'Gothenburg University all have multi-faith prayer rooms.',
      ),
      educationRights: ReligiousEducationRights(
        publicSchoolPolicy: 'Non-confessional "Religion" (Religionskunskap) mandatory. '
            'Covers world religions including Islam. Not faith-based instruction.',
        optOutRight: 'Very limited opt-out as the subject is non-confessional and '
            'part of core curriculum. Specific activities with confessional elements '
            '(e.g., church visits at Christmas) can be opted out of.',
        alternativeEthicsClass: 'Not needed — Religion class is already non-confessional.',
        religiousSchools: 'Free schools (friskolor) may have religious profile. '
            'Islamic free schools exist (about 10-15). State funded. '
            'Increased scrutiny and stricter regulations since 2022 reforms. '
            'Some Islamic schools closed or denied permits.',
      ),
      worshipRights: PlacesOfWorshipRights(
        permitProcess: 'Standard building permit (bygglov) through municipality '
            'under Planning and Building Act (Plan- och bygglagen).',
        zoningLaw: 'Detailed development plan (detaljplan). Religious buildings classified as '
            'community service. Generally accommodated in mixed-use areas.',
        minaretRestrictions: 'No ban. Subject to building regulations. Fittja Mosque (Stockholm), '
            'Malmö Mosque have minarets.',
        recentIssues: 'Well-established mosque network (~200+ mosques/prayer rooms). '
            'Some debate about foreign-funded mosques. Security Service (Säpo) monitoring '
            'extremist influences. Sweden Democrats push for restrictions.',
      ),
      discriminationComplaints: DiscriminationComplaints(
        equalityBody: 'Equality Ombudsman (Diskrimineringsombudsmannen — DO)',
        contactInfo: 'Box 4057, 169 04 Solna. Tel: +46 8 120 20 700',
        onlineFiling: 'https://www.do.se/ — online complaint form in SV/EN/AR',
        legalAidAvailable: 'Yes. Rättshjälp (legal aid) based on income. '
            'Swedish anti-discrimination bureaus (antidiskrimineringsbyråer) in most regions '
            'provide free legal advice. Ibn Rushd Study Association.',
        timeLimit: '2 years for Discrimination Act claims. DO complaints: no strict time limit '
            'but recommended within 2 years.',
      ),
      burialRights: BurialRights(
        islamicBurial: 'Islamic sections in many municipal cemeteries. Stockholm (Järva, '
            'Skogskyrkogården), Gothenburg, Malmö, Uppsala. Burial without coffin: permitted '
            'in some municipalities (Malmö allows shroud burial). '
            '25 years minimum grave tenure (renewable).',
        jewishBurial: 'Jewish cemeteries in Stockholm (Aronsberg), Gothenburg, Malmö.',
        dedicatedSections: 'Widely available. Over 100 municipalities have Islamic sections. '
            'Church of Sweden (which manages most cemeteries) accommodates Islamic burial.',
        repatriationOfRemains: 'Permitted. Islamic organizations assist. '
            'Well-established process. Cost: SEK 25,000-60,000.',
        embalming: 'Not required by Swedish law. Burial must occur within reasonable time. '
            'Begravningslagen (Burial Act) is flexible.',
      ),
      chaplaincyRights: ChaplaincyRights(
        prisons: 'Muslim prison chaplaincy in Kriminalvården. Imams serve in major facilities. '
            'Part of formal spiritual care (andlig vård) framework.',
        hospitals: 'Multi-faith hospital chaplaincy developing. Muslim spiritual caregivers '
            'in major hospitals. Sjukhuskyrkan expanding to multi-faith model.',
        military: 'Church of Sweden historically provided military chaplaincy. '
            'Multi-faith approach developing in Försvarsmakten.',
        multiReligious: 'Sweden developing multi-faith chaplaincy across institutions. '
            'SST (Commission for Government Support to Faith Communities) coordinates.',
      ),
      immigrantSpecificNotes: 'Sweden has one of Europe\'s largest Muslim populations per capita '
          '(~800,000, ~8%). Strong anti-discrimination framework through DO and Discrimination Act. '
          'No general face covering ban (school ban only since 2020). Ritual slaughter banned since '
          '1937 (oldest ban in Europe) but imports permitted. ~200+ mosques. Islamic free schools '
          'exist but face increasing scrutiny. SST provides government funding to faith communities. '
          'Church of Sweden manages cemeteries and accommodates Islamic burial. Generally progressive '
          'framework but political climate shifting with Sweden Democrats influence. '
          'DO actively handles religious discrimination complaints. Free anti-discrimination bureaus '
          'provide accessible support.',
    ),

  ];
}
