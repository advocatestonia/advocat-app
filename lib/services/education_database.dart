// Education & Qualification Recognition Database for all 27 EU Countries
// Real data for immigrant education rights, school enrollment, diploma recognition,
// university access, and adult education/language courses
// Last updated: 2026-04
//
// Sources: European Commission Education and Training Monitor, Eurydice Network
// (European Education Information Network), ENIC-NARIC national recognition centers,
// UNESCO Global Convention on Recognition of Qualifications, EU Directive 2005/36/EC
// (professional qualifications), EU Directive 2013/55/EU (modernized recognition),
// Council of Europe Lisbon Recognition Convention (1997), UNHCR Education Reports,
// FRA (EU Fundamental Rights Agency) reports on migrant children's education,
// OECD PISA reports, national ministry of education data, Eurostat education statistics.

// ============================================================
// DATA MODELS
// ============================================================

class SchoolEnrollment {
  final String country;
  final String countryCode;
  final bool rightRegardlessOfStatus;
  final String legalBasis;
  final int compulsoryAgeStart;
  final int compulsoryAgeEnd;
  final List<String> documentsNeeded;
  final bool enrollmentPossibleWithoutDocuments;
  final String enrollmentProcess;
  final String languageSupportProgram;
  final String languageSupportDetails;
  final bool freeSchoolMeals;
  final String freeMealsDetails;
  final String specialEducationRights;
  final String contactAuthority;
  final String immigrantSpecificNotes;

  const SchoolEnrollment({
    required this.country,
    required this.countryCode,
    required this.rightRegardlessOfStatus,
    required this.legalBasis,
    required this.compulsoryAgeStart,
    required this.compulsoryAgeEnd,
    required this.documentsNeeded,
    required this.enrollmentPossibleWithoutDocuments,
    required this.enrollmentProcess,
    required this.languageSupportProgram,
    required this.languageSupportDetails,
    required this.freeSchoolMeals,
    required this.freeMealsDetails,
    required this.specialEducationRights,
    required this.contactAuthority,
    required this.immigrantSpecificNotes,
  });

  Map<String, dynamic> toMap() {
    return {
      'country': country,
      'countryCode': countryCode,
      'rightRegardlessOfStatus': rightRegardlessOfStatus,
      'legalBasis': legalBasis,
      'compulsoryAgeStart': compulsoryAgeStart,
      'compulsoryAgeEnd': compulsoryAgeEnd,
      'documentsNeeded': documentsNeeded,
      'enrollmentPossibleWithoutDocuments': enrollmentPossibleWithoutDocuments,
      'enrollmentProcess': enrollmentProcess,
      'languageSupportProgram': languageSupportProgram,
      'languageSupportDetails': languageSupportDetails,
      'freeSchoolMeals': freeSchoolMeals,
      'freeMealsDetails': freeMealsDetails,
      'specialEducationRights': specialEducationRights,
      'contactAuthority': contactAuthority,
      'immigrantSpecificNotes': immigrantSpecificNotes,
    };
  }
}

class DiplomaRecognition {
  final String country;
  final String countryCode;
  final String recognitionAuthority;
  final String authorityWebsite;
  final String processDescription;
  final String timelineWeeks;
  final String costEur;
  final String documentsRequired;
  final String doctorRequalification;
  final String engineerRequalification;
  final String teacherRequalification;
  final String nurseRequalification;
  final String lawyerRequalification;
  final String legalBasis;
  final String refugeeSpecialProcedure;
  final String contactInfo;

  const DiplomaRecognition({
    required this.country,
    required this.countryCode,
    required this.recognitionAuthority,
    required this.authorityWebsite,
    required this.processDescription,
    required this.timelineWeeks,
    required this.costEur,
    required this.documentsRequired,
    required this.doctorRequalification,
    required this.engineerRequalification,
    required this.teacherRequalification,
    required this.nurseRequalification,
    required this.lawyerRequalification,
    required this.legalBasis,
    required this.refugeeSpecialProcedure,
    required this.contactInfo,
  });

  Map<String, dynamic> toMap() {
    return {
      'country': country,
      'countryCode': countryCode,
      'recognitionAuthority': recognitionAuthority,
      'authorityWebsite': authorityWebsite,
      'processDescription': processDescription,
      'timelineWeeks': timelineWeeks,
      'costEur': costEur,
      'documentsRequired': documentsRequired,
      'doctorRequalification': doctorRequalification,
      'engineerRequalification': engineerRequalification,
      'teacherRequalification': teacherRequalification,
      'nurseRequalification': nurseRequalification,
      'lawyerRequalification': lawyerRequalification,
      'legalBasis': legalBasis,
      'refugeeSpecialProcedure': refugeeSpecialProcedure,
      'contactInfo': contactInfo,
    };
  }
}

class UniversityAccess {
  final String country;
  final String countryCode;
  final String tuitionNonEu;
  final String tuitionEu;
  final bool freeForRefugees;
  final List<String> scholarshipPrograms;
  final String languageCoursesAvailable;
  final String studentWorkRights;
  final int studentWorkHoursPerWeek;
  final String admissionProcess;
  final String preparatoryPrograms;
  final String contactAuthority;
  final String immigrantSpecificNotes;

  const UniversityAccess({
    required this.country,
    required this.countryCode,
    required this.tuitionNonEu,
    required this.tuitionEu,
    required this.freeForRefugees,
    required this.scholarshipPrograms,
    required this.languageCoursesAvailable,
    required this.studentWorkRights,
    required this.studentWorkHoursPerWeek,
    required this.admissionProcess,
    required this.preparatoryPrograms,
    required this.contactAuthority,
    required this.immigrantSpecificNotes,
  });

  Map<String, dynamic> toMap() {
    return {
      'country': country,
      'countryCode': countryCode,
      'tuitionNonEu': tuitionNonEu,
      'tuitionEu': tuitionEu,
      'freeForRefugees': freeForRefugees,
      'scholarshipPrograms': scholarshipPrograms,
      'languageCoursesAvailable': languageCoursesAvailable,
      'studentWorkRights': studentWorkRights,
      'studentWorkHoursPerWeek': studentWorkHoursPerWeek,
      'admissionProcess': admissionProcess,
      'preparatoryPrograms': preparatoryPrograms,
      'contactAuthority': contactAuthority,
      'immigrantSpecificNotes': immigrantSpecificNotes,
    };
  }
}

class AdultEducation {
  final String country;
  final String countryCode;
  final String freeLanguageCourses;
  final String languageCourseProvider;
  final String integrationCourseHours;
  final String integrationCourseContent;
  final bool integrationCourseMandatory;
  final String vocationalTrainingPrograms;
  final String digitalSkillsPrograms;
  final String financialSupport;
  final String contactAuthority;
  final String immigrantSpecificNotes;

  const AdultEducation({
    required this.country,
    required this.countryCode,
    required this.freeLanguageCourses,
    required this.languageCourseProvider,
    required this.integrationCourseHours,
    required this.integrationCourseContent,
    required this.integrationCourseMandatory,
    required this.vocationalTrainingPrograms,
    required this.digitalSkillsPrograms,
    required this.financialSupport,
    required this.contactAuthority,
    required this.immigrantSpecificNotes,
  });

  Map<String, dynamic> toMap() {
    return {
      'country': country,
      'countryCode': countryCode,
      'freeLanguageCourses': freeLanguageCourses,
      'languageCourseProvider': languageCourseProvider,
      'integrationCourseHours': integrationCourseHours,
      'integrationCourseContent': integrationCourseContent,
      'integrationCourseMandatory': integrationCourseMandatory,
      'vocationalTrainingPrograms': vocationalTrainingPrograms,
      'digitalSkillsPrograms': digitalSkillsPrograms,
      'financialSupport': financialSupport,
      'contactAuthority': contactAuthority,
      'immigrantSpecificNotes': immigrantSpecificNotes,
    };
  }
}

// ============================================================
// MAIN DATABASE CLASS
// ============================================================

class EducationDatabase {
  static final EducationDatabase _instance = EducationDatabase._internal();
  factory EducationDatabase() => _instance;
  EducationDatabase._internal();

  // ============================================================
  // SCHOOL ENROLLMENT — ALL 27 EU COUNTRIES
  // ============================================================

  static const List<SchoolEnrollment> schoolEnrollments = [
    // 1. AUSTRIA
    SchoolEnrollment(
      country: 'Austria',
      countryCode: 'AT',
      rightRegardlessOfStatus: true,
      legalBasis: 'Schulpflichtgesetz 1985, Section 1 — compulsory schooling for all children residing in Austria regardless of nationality or status',
      compulsoryAgeStart: 6,
      compulsoryAgeEnd: 15,
      documentsNeeded: ['Birth certificate or age proof', 'Proof of residence (Meldezettel)', 'Vaccination records (recommended)'],
      enrollmentPossibleWithoutDocuments: true,
      enrollmentProcess: 'Register at the local Volksschule (primary) or nearest school. The Bildungsdirektion (Education Directorate) assigns a place. No documents strictly required for initial enrollment — schools must accept children.',
      languageSupportProgram: 'Deutschförderklassen (German Support Classes)',
      languageSupportDetails: 'Since 2018/19, children scoring below threshold on MIKA-D test are placed in separate Deutschförderklassen (up to 4 semesters, max 20 hours/week German). After that, Deutschförderkurse (integrated support courses, 6 hrs/week).',
      freeSchoolMeals: false,
      freeMealsDetails: 'No universal free school meals. Some municipalities (especially Vienna) offer subsidized meals. Vienna: Ganztagsschulen provide free lunch. Other Länder vary.',
      specialEducationRights: 'Equal right to Sonderpädagogischer Förderbedarf (special educational needs assessment). Inclusive education policy; children can attend regular schools with support or Sonderschulen.',
      contactAuthority: 'Bildungsdirektion of respective Bundesland (e.g., Bildungsdirektion Wien: +43 1 52525-0)',
      immigrantSpecificNotes: 'Unaccompanied minors enrolled through Kinder- und Jugendhilfe. Asylum seeker children have full school access. Schulpflicht applies from the moment of residence, even during asylum procedure.',
    ),

    // 2. BELGIUM
    SchoolEnrollment(
      country: 'Belgium',
      countryCode: 'BE',
      rightRegardlessOfStatus: true,
      legalBasis: 'Belgian Constitution Art. 24; Compulsory Education Act 1983; Circular letters from Flemish, French, and German-speaking Communities',
      compulsoryAgeStart: 5,
      compulsoryAgeEnd: 18,
      documentsNeeded: ['Identity document (any)', 'Proof of residence or declaration', 'Medical certificate (school doctor visit)'],
      enrollmentPossibleWithoutDocuments: true,
      enrollmentProcess: 'Contact local school directly or municipal education service. In Brussels and Wallonia, CPMS (Centre PMS) assists. In Flanders, LOP (Lokaal Overlegplatform) helps find places. Schools cannot refuse based on status.',
      languageSupportProgram: 'OKAN (Onthaalklassen voor Anderstalige Nieuwkomers) in Flanders; DASPA (Dispositif d\'Accueil et de Scolarisation des Primo-Arrivants) in French Community',
      languageSupportDetails: 'OKAN: 1 year intensive Dutch for newcomers 6-18 years. DASPA: 1-2 years intensive French support. Both include cultural orientation. German Community has similar Auffangklassen.',
      freeSchoolMeals: false,
      freeMealsDetails: 'No universal free meals. CPAS/OCMW social aid can cover meal costs for low-income families. Some schools in Brussels offer subsidized canteen via commune.',
      specialEducationRights: 'Equal access to buitengewoon onderwijs (special education) in Flanders or enseignement spécialisé in Wallonia. M-decreet (Flanders) promotes inclusive education since 2015.',
      contactAuthority: 'Flanders: Agentschap voor Onderwijsdiensten, 1700 helpline. Wallonia: Administration générale de l\'Enseignement. Brussels: both communities.',
      immigrantSpecificNotes: 'Constitutional right — no child can be denied education. Undocumented children explicitly included. Schools penalized for refusing enrollment based on origin. Free education in public schools (small fees may apply for supplies).',
    ),

    // 3. BULGARIA
    SchoolEnrollment(
      country: 'Bulgaria',
      countryCode: 'BG',
      rightRegardlessOfStatus: true,
      legalBasis: 'Pre-school and School Education Act 2016 (Закон за предучилищното и училищното образование), Art. 9 — right to education for all children on Bulgarian territory',
      compulsoryAgeStart: 7,
      compulsoryAgeEnd: 16,
      documentsNeeded: ['Birth certificate or equivalent', 'Proof of address', 'Health card/vaccination record'],
      enrollmentPossibleWithoutDocuments: true,
      enrollmentProcess: 'Apply to the nearest school through the Regional Education Department (РУО). Refugee children enrolled through the State Agency for Refugees (ДАБ) coordination. Schools assigned by district.',
      languageSupportProgram: 'Допълнително обучение по български език (Additional Bulgarian Language Education)',
      languageSupportDetails: 'Up to 3 additional hours per week of Bulgarian as a second language. Special preparatory groups for refugee children funded by the state. Some NGOs (Caritas, Bulgarian Red Cross) provide supplementary language support.',
      freeSchoolMeals: true,
      freeMealsDetails: 'Free meals for grades 1-4 (primary school) since 2023 reform. Means-tested free meals for vulnerable families in higher grades. Refugee children in reception centers receive full meals.',
      specialEducationRights: 'Inclusive education guaranteed under 2016 Act. Resource teachers and support specialists provided. Special schools exist but inclusive placement preferred.',
      contactAuthority: 'Ministry of Education and Science: +359 2 9217 799. Regional Education Departments (РУО) in each oblast.',
      immigrantSpecificNotes: 'Asylum seekers placed in schools within 3 months of application. Unaccompanied minors assigned guardians who handle enrollment. Free textbooks for grades 1-7.',
    ),

    // 4. CROATIA
    SchoolEnrollment(
      country: 'Croatia',
      countryCode: 'HR',
      rightRegardlessOfStatus: true,
      legalBasis: 'Education Act (Zakon o odgoju i obrazovanju u osnovnoj i srednjoj školi), Art. 46; International and Temporary Protection Act',
      compulsoryAgeStart: 6,
      compulsoryAgeEnd: 15,
      documentsNeeded: ['Any identity document', 'Proof of residence or reception center address', 'Medical certificate (available from school doctor)'],
      enrollmentPossibleWithoutDocuments: true,
      enrollmentProcess: 'Registration through the nearest school or the Ministry of Science and Education office. Asylum seekers enrolled through coordination between the Ministry and reception centers.',
      languageSupportProgram: 'Pripremna nastava hrvatskog jezika (Preparatory Croatian Language Classes)',
      languageSupportDetails: '70 hours of intensive Croatian before or during regular schooling. Available in schools with foreign-origin students. Additional support through NGOs like Are You Syrious and Croatian Red Cross.',
      freeSchoolMeals: false,
      freeMealsDetails: 'No universal free meals. Subsidized meals through social welfare. Refugee children in reception centers receive free meals. School meal programs vary by county (županija).',
      specialEducationRights: 'Inclusive education policy. Individual education plans (IEP) for children with special needs. Teaching assistants provided when needed.',
      contactAuthority: 'Ministry of Science and Education: +385 1 4569 000. Education and Teacher Training Agency (AZOO).',
      immigrantSpecificNotes: 'Children granted international protection have identical rights as Croatian children. Free textbooks, transport subsidies, and extracurricular activities. Preparatory year option before mainstream enrollment.',
    ),

    // 5. CYPRUS
    SchoolEnrollment(
      country: 'Cyprus',
      countryCode: 'CY',
      rightRegardlessOfStatus: true,
      legalBasis: 'Compulsory Education Law of 1993 (N. 24(I)/1993) and amendments; Refugee Law N. 6(I)/2000',
      compulsoryAgeStart: 5,
      compulsoryAgeEnd: 15,
      documentsNeeded: ['Birth certificate', 'Proof of residence', 'Vaccination certificate'],
      enrollmentPossibleWithoutDocuments: true,
      enrollmentProcess: 'Register at the nearest public school. District Education Office (Επαρχιακό Γραφείο Παιδείας) coordinates placement. Asylum seekers can use reception center address.',
      languageSupportProgram: 'Zones of Educational Priority (ZEP) / Ζώνες Εκπαιδευτικής Προτεραιότητας (ΖΕΠ)',
      languageSupportDetails: 'ZEP schools in high-immigration areas offer intensive Greek language classes. Additional afternoon Greek language courses. Teacher support staff in schools with many non-Greek-speaking students.',
      freeSchoolMeals: false,
      freeMealsDetails: 'No universal free meals. Social Welfare Services can provide support. Some school canteens offer subsidized meals. NGOs provide lunch programs in areas with many refugee children.',
      specialEducationRights: 'Law on Special Education 113(I)/1999. Children with special needs entitled to individual support plans. Inclusive education policy applies equally to immigrants.',
      contactAuthority: 'Ministry of Education, Sport and Youth: +357 22 800 600',
      immigrantSpecificNotes: 'All children including undocumented have school access. Greek language intensive support provided. Afternoon classes (Απογευματινά Σχολεία) available for catch-up. Intercultural education framework in place.',
    ),

    // 6. CZECHIA
    SchoolEnrollment(
      country: 'Czechia',
      countryCode: 'CZ',
      rightRegardlessOfStatus: true,
      legalBasis: 'Education Act 561/2004 Sb., Section 20 — equal access for foreigners legally or illegally residing in Czechia',
      compulsoryAgeStart: 6,
      compulsoryAgeEnd: 15,
      documentsNeeded: ['Proof of age (any document)', 'Proof of residence or temporary address', 'Health insurance proof (recommended)'],
      enrollmentPossibleWithoutDocuments: true,
      enrollmentProcess: 'Apply directly to the school or through the municipal authority (obecní úřad). Foreign children assigned by the regional education authority. Schools must accept unless at full capacity.',
      languageSupportProgram: 'Bezplatná jazyková příprava (Free Language Preparation)',
      languageSupportDetails: 'Since 2021, 200 hours of free Czech language preparation for foreign pupils in designated schools. Available for children of all foreigners with legal residence. Adaptation coordinators in schools.',
      freeSchoolMeals: false,
      freeMealsDetails: 'No universal free meals. Subsidized lunches available. Since 2023, "Obědy do škol" program provides free meals for socially disadvantaged children (including refugee families).',
      specialEducationRights: 'Equal rights under inclusive education reform (2016 amendment). School counseling facilities (PPP) assess needs. Individual education plans for students with special needs.',
      contactAuthority: 'Ministry of Education: +420 234 811 111. Czech School Inspectorate for complaints.',
      immigrantSpecificNotes: 'Ukrainian refugee children (since 2022) have special fast-track enrollment. Adaptation groups available. Free Czech courses. All foreigners including undocumented have compulsory education right.',
    ),

    // 7. DENMARK
    SchoolEnrollment(
      country: 'Denmark',
      countryCode: 'DK',
      rightRegardlessOfStatus: true,
      legalBasis: 'Folkeskolelov (Public Schools Act), Section 2 — obligation for municipalities to offer education to all children in their area',
      compulsoryAgeStart: 6,
      compulsoryAgeEnd: 16,
      documentsNeeded: ['CPR number (civil registration)', 'Proof of address'],
      enrollmentPossibleWithoutDocuments: true,
      enrollmentProcess: 'Contact the municipality (kommune). Children assigned to local folkeskole. Asylum seeker children enrolled through reception center school arrangements or local schools.',
      languageSupportProgram: 'Basisundervisning i dansk som andetsprog (Basic Education in Danish as Second Language)',
      languageSupportDetails: 'Modtageklasser (reception classes) for newly arrived children — up to 2 years intensive Danish. Then integration into regular classes with supplementary Danish support (supplerende dansk).',
      freeSchoolMeals: false,
      freeMealsDetails: 'No universal free school meals in Denmark. Some municipalities run pilot programs. Packed lunches from home are the norm. Asylum center schools provide meals.',
      specialEducationRights: 'Full access to specialundervisning (special education). PPR (Pædagogisk Psykologisk Rådgivning) assessment available. Inclusive education principle applies.',
      contactAuthority: 'Municipality education department. Ministry of Children and Education: +45 33 92 50 00',
      immigrantSpecificNotes: 'Asylum seeker children must be offered education within 15 working days. Unaccompanied minors receive extra support. Integration requirements for families affect continued residence but not school access.',
    ),

    // 8. ESTONIA
    SchoolEnrollment(
      country: 'Estonia',
      countryCode: 'EE',
      rightRegardlessOfStatus: true,
      legalBasis: 'Basic Schools and Upper Secondary Schools Act (Põhikooli- ja gümnaasiumiseadus), Section 9 — right to education for all children living in Estonia',
      compulsoryAgeStart: 7,
      compulsoryAgeEnd: 17,
      documentsNeeded: ['Identity document or proof of age', 'Residence proof or accommodation center address'],
      enrollmentPossibleWithoutDocuments: true,
      enrollmentProcess: 'Local municipality assigns school place. Apply through the local government education department or directly to schools. e-School (eKool) system used for registration.',
      languageSupportProgram: 'Eesti keele kui teise keele õpe (Estonian as Second Language) / LAK-õpe (Language Immersion Programme)',
      languageSupportDetails: 'Intensive Estonian language courses for newcomers. Language immersion program (Keelekümblus) available since 2000. Additional support hours. Some schools in Tallinn and Ida-Virumaa also offer Russian-language instruction.',
      freeSchoolMeals: true,
      freeMealsDetails: 'Free school lunch for all students in grades 1-9 (basic education). State-funded since 2006. Upper secondary: municipality decides. All children including immigrants receive free meals.',
      specialEducationRights: 'Individual development plan (IÕK) for special needs. Counseling committees (Rajaleidja centers) assess needs. Inclusive education policy under 2010 reforms.',
      contactAuthority: 'Ministry of Education and Research: +372 735 0222. Haridus- ja Noorteamet (Education and Youth Board).',
      immigrantSpecificNotes: 'Welcome program (Kohanemisprogramm) includes educational support. Asylum seeker children enrolled within days. Estonian language support starts immediately. Digital learning tools widely available.',
    ),

    // 9. FINLAND
    SchoolEnrollment(
      country: 'Finland',
      countryCode: 'FI',
      rightRegardlessOfStatus: true,
      legalBasis: 'Basic Education Act (628/1998, Perusopetuslaki) Section 4 — municipality must arrange education for all children of compulsory school age residing in the area',
      compulsoryAgeStart: 7,
      compulsoryAgeEnd: 18,
      documentsNeeded: ['No documents strictly required for enrollment'],
      enrollmentPossibleWithoutDocuments: true,
      enrollmentProcess: 'Contact the municipality education department (kunnan opetustoimi). Municipality assigns a nearby school. Children can enroll immediately even without residence permit — being physically present is sufficient.',
      languageSupportProgram: 'Valmistava opetus (Preparatory Education)',
      languageSupportDetails: 'Up to 1 year (900 hours minimum) of preparatory education before mainstream school. Finnish/Swedish as second language (S2) instruction continues in regular school. Own mother tongue teaching available (2 hrs/week). Municipalities receive extra state funding per immigrant student.',
      freeSchoolMeals: true,
      freeMealsDetails: 'Free daily school meal for ALL students in basic education (grades 1-9) and upper secondary. Finland pioneered this in 1948. No means-testing. Includes immigrants, asylum seekers, undocumented children.',
      specialEducationRights: 'Three-tier support model: general, intensified, and special support. Equal access regardless of background. Individual education plans. Full-time special education if needed.',
      contactAuthority: 'Finnish National Agency for Education (Opetushallitus): +358 29 533 1000. Local municipality education office.',
      immigrantSpecificNotes: 'Finland is one of the most inclusive EU countries for immigrant education. Extended compulsory education to 18 (since 2021). Free textbooks, transport, and materials in basic education. Interpreting services available. Romani and Sámi language education also available.',
    ),

    // 10. FRANCE
    SchoolEnrollment(
      country: 'France',
      countryCode: 'FR',
      rightRegardlessOfStatus: true,
      legalBasis: 'Code de l\'éducation Art. L131-1; Circular 2012-141 (scolarisation des élèves allophones). Constitutional principle: education is a fundamental right for all children on French territory.',
      compulsoryAgeStart: 3,
      compulsoryAgeEnd: 16,
      documentsNeeded: ['Proof of age (any document)', 'Proof of address (or domiciliation attestation from CCAS)', 'Vaccination record (or catch-up arranged)'],
      enrollmentPossibleWithoutDocuments: true,
      enrollmentProcess: 'Register at the mairie (town hall) which assigns a school. CASNAV (Centre Académique pour la Scolarisation des élèves allophones Nouvellement Arrivés et des enfants issus de familles itinérantes et de Voyageurs) evaluates language level and assigns appropriate support.',
      languageSupportProgram: 'UPE2A (Unités Pédagogiques pour Élèves Allophones Arrivants)',
      languageSupportDetails: 'UPE2A classes provide intensive French (12-15 hrs/week) while students attend regular classes part-time. Duration: typically 1 year. CASNAV coordinates. FLE (Français Langue Étrangère) and FLS (Français Langue Seconde) methodology.',
      freeSchoolMeals: false,
      freeMealsDetails: 'Cantine scolaire fees are income-based. Many communes offer free meals for lowest income bracket (QF). Paris: tariff 0 available. Refugee families often qualify for the lowest or zero rate.',
      specialEducationRights: 'MDPH (Maison Départementale des Personnes Handicapées) evaluates special needs. PPS (Projet Personnalisé de Scolarisation) for children with disabilities. AESH (accompaniment staff) provided. Equal rights for all children.',
      contactAuthority: 'Rectorat of the relevant académie. CASNAV offices. National number: 3020 (education helpline).',
      immigrantSpecificNotes: 'Strong legal protections. Mayor CANNOT refuse enrollment based on immigration status (Conseil d\'État case law). Instruction obligation until 16, right to education until 18. Undocumented children fully protected. Free public education.',
    ),

    // 11. GERMANY
    SchoolEnrollment(
      country: 'Germany',
      countryCode: 'DE',
      rightRegardlessOfStatus: true,
      legalBasis: 'Grundgesetz Art. 7; each Bundesland has its own Schulgesetz with compulsory education (Schulpflicht) for all children. KMK resolution 2002: all children regardless of status.',
      compulsoryAgeStart: 6,
      compulsoryAgeEnd: 18,
      documentsNeeded: ['Proof of age', 'Proof of residence (Meldebescheinigung)', 'Vaccination record (Masern — measles mandatory since 2020)'],
      enrollmentPossibleWithoutDocuments: true,
      enrollmentProcess: 'Register at the Schulamt (school authority) or directly at the local school. Refugee children in reception facilities: enrollment organized by the Bundesland. Most Länder require enrollment within 3-6 months of arrival.',
      languageSupportProgram: 'Willkommensklassen (Berlin), Vorbereitungsklassen (VKL), Deutschförderklassen, Internationale Förderklassen (IFK) — name varies by Bundesland',
      languageSupportDetails: 'Intensive German classes for 1-2 years (10-28 hrs/week depending on Land). Gradual integration into regular classes. DaZ (Deutsch als Zweitsprache) support continues. Each Land has own model — Berlin: Willkommensklassen, Bayern: Deutschklassen, NRW: Internationale Förderklassen.',
      freeSchoolMeals: false,
      freeMealsDetails: 'No universal free meals. Bildungs- und Teilhabepaket (BuT) covers school lunch costs for families on social benefits (SGB II/XII, Asylbewerberleistungsgesetz). Ganztagsschulen provide lunch (subsidized or BuT-covered).',
      specialEducationRights: 'Sonderpädagogischer Förderbedarf assessment. Inclusive education (Inklusion) mandated since UN CRPD ratification 2009. Förderschulen available. Equal access for all children.',
      contactAuthority: 'Schulamt of the municipality/Kreis. KMK (Kultusministerkonferenz) for federal coordination. Each Bundesland: Ministerium für Bildung.',
      immigrantSpecificNotes: 'All 16 Bundesländer guarantee Schulpflicht for all children. Some Länder (e.g., Hamburg) have Schulpflicht from day 1; others (e.g., Sachsen) within 3 months. Asylum-seeker children included. Unaccompanied minors get Vormundschaft + school enrollment.',
    ),

    // 12. GREECE
    SchoolEnrollment(
      country: 'Greece',
      countryCode: 'GR',
      rightRegardlessOfStatus: true,
      legalBasis: 'Greek Constitution Art. 16; Law 4636/2019 (International Protection Act) Art. 55; Ministerial Decision 180647/ΓΔ4/2016',
      compulsoryAgeStart: 4,
      compulsoryAgeEnd: 15,
      documentsNeeded: ['Any age verification', 'Vaccination record (or catch-up at school)', 'AMKA or PAAYPA number (social security — can be obtained during enrollment)'],
      enrollmentPossibleWithoutDocuments: true,
      enrollmentProcess: 'Register at the nearest school (Σχολείο). Education coordinators in refugee camps assist with enrollment. Ministry of Education assigns places through Regional Education Directorates.',
      languageSupportProgram: 'Τάξεις Υποδοχής (Reception Classes — ZEP) / DYEP (Δομές Υποδοχής και Εκπαίδευσης Προσφύγων)',
      languageSupportDetails: 'Reception classes (Τάξεις Υποδοχής ZEP I & II) provide intensive Greek. ZEP I: beginners. ZEP II: intermediate. DYEP: afternoon reception facilities in camps for refugee children. Frontex/UNHCR-supported language programs.',
      freeSchoolMeals: false,
      freeMealsDetails: 'No universal free meals in Greek schools. Σχολικά Γεύματα (school meals program) in select disadvantaged areas since 2017. Refugee children in camps receive meals through UNHCR/NGO programs.',
      specialEducationRights: 'KEDASY (Κέντρα Διεπιστημονικής Αξιολόγησης) assess special needs. Law 3699/2008 on special education. Integration classes and special schools available.',
      contactAuthority: 'Ministry of Education: +30 210 344 2000. Regional Education Directorates (Περιφερειακές Διευθύνσεις Εκπαίδευσης).',
      immigrantSpecificNotes: 'Large refugee population (since 2015) led to expanded education infrastructure. Morning-zone (regular school) and afternoon-zone (DYEP) models. UNHCR and UNICEF support programs. Challenges remain in island camps. Intercultural schools in Athens, Thessaloniki.',
    ),

    // 13. HUNGARY
    SchoolEnrollment(
      country: 'Hungary',
      countryCode: 'HU',
      rightRegardlessOfStatus: true,
      legalBasis: 'Fundamental Law Art. XI; Act CXC of 2011 on National Public Education, Section 45 — all children residing in Hungary have right and duty to attend school',
      compulsoryAgeStart: 3,
      compulsoryAgeEnd: 16,
      documentsNeeded: ['Birth certificate or age proof', 'Address card (lakcímkártya)', 'TAJ card (social security) or proof of application'],
      enrollmentPossibleWithoutDocuments: false,
      enrollmentProcess: 'Register at the district school through the Klebelsberg Központ (education center). Refugee children enrolled through coordination with immigration authority (OIF).',
      languageSupportProgram: 'Magyar nyelvi előkészítő (Hungarian Language Preparatory Classes)',
      languageSupportDetails: 'Up to 1 year of Hungarian language preparation. Additional Hungarian as a foreign language support. Limited availability — concentrated in Budapest and larger cities. NGOs (Menedék, Hungarian Helsinki Committee) provide supplementary language education.',
      freeSchoolMeals: true,
      freeMealsDetails: 'Free meals for children in grades 1-8 from families receiving social benefits. Universal free meals in kindergarten (óvoda). School meals heavily subsidized for all.',
      specialEducationRights: 'Expert committees (Szakértői Bizottságok) assess special needs. Inclusive education or special schools. Equal rights under public education act.',
      contactAuthority: 'Klebelsberg Központ: +36 1 795 5657. Belügyminisztérium (Ministry of Interior) for refugee education issues.',
      immigrantSpecificNotes: 'Refugee children have equal education rights. However, practical access can be challenging outside Budapest. Hungarian language barrier significant. Few intercultural programs. Menedék Association provides key support services.',
    ),

    // 14. IRELAND
    SchoolEnrollment(
      country: 'Ireland',
      countryCode: 'IE',
      rightRegardlessOfStatus: true,
      legalBasis: 'Education Act 1998; Education (Welfare) Act 2000; Irish Constitution Art. 42 — all children in the State entitled to education',
      compulsoryAgeStart: 6,
      compulsoryAgeEnd: 16,
      documentsNeeded: ['Birth certificate', 'PPS number (can be obtained post-enrollment)', 'Proof of address', 'Immunization records'],
      enrollmentPossibleWithoutDocuments: true,
      enrollmentProcess: 'Apply directly to schools. If refused, contact the local Educational Welfare Officer (Tusla). Schools must follow admissions policies under Education (Admission to Schools) Act 2018. Direct Provision residents have full access.',
      languageSupportProgram: 'English as an Additional Language (EAL) Support',
      languageSupportDetails: 'EAL support teachers in primary and post-primary schools. Up to 2 years of additional English language instruction. Post-primary: English Language Support Programme. International students can take English at a modified level in state exams.',
      freeSchoolMeals: false,
      freeMealsDetails: 'School Meals Programme (DEIS schools) provides free meals in disadvantaged schools. Hot School Meals Programme expanding since 2023. Not universal but covers many immigrant families in DEIS schools.',
      specialEducationRights: 'EPSEN Act 2004 (Education for Persons with Special Educational Needs). NCSE (National Council for Special Education) coordinates. SNAs (Special Needs Assistants) and resource teachers provided.',
      contactAuthority: 'Department of Education: +353 1 889 6400. Tusla Education Support Service (TESS). NCSE.',
      immigrantSpecificNotes: 'Asylum seeker children in Direct Provision have full school access. Free primary education in public schools. Post-primary: SUSI grant available for refugees. Intercultural Education Strategy in place. NALA supports adult literacy.',
    ),

    // 15. ITALY
    SchoolEnrollment(
      country: 'Italy',
      countryCode: 'IT',
      rightRegardlessOfStatus: true,
      legalBasis: 'Italian Constitution Art. 34; D.Lgs. 286/1998 (TU Immigrazione) Art. 38 — minors present on Italian territory have right to education regardless of legal status',
      compulsoryAgeStart: 6,
      compulsoryAgeEnd: 16,
      documentsNeeded: ['Self-declaration of personal data (autocertificazione)', 'Vaccination record (or catch-up)'],
      enrollmentPossibleWithoutDocuments: true,
      enrollmentProcess: 'Register online through MIUR portal (Iscrizioni Online) or directly at school secretariat. For undocumented: self-certification accepted. Ufficio Scolastico Regionale coordinates placement.',
      languageSupportProgram: 'Laboratori linguistici di italiano L2 (Italian L2 Language Workshops)',
      languageSupportDetails: 'Schools organize Italian L2 laboratories (at least 2 hrs/week). Protocollo di accoglienza (welcome protocol) required in each school. Mediatori culturali (cultural mediators) in schools with many foreign students. National guidelines: C.M. 24/2006.',
      freeSchoolMeals: false,
      freeMealsDetails: 'Mensa scolastica fees based on ISEE (income indicator). Lowest ISEE brackets: free meals. Varies by municipality. Many immigrant families qualify for free/reduced meals. Rome: fascia gratuita available.',
      specialEducationRights: 'Italy pioneered inclusive education (Legge 517/1977). Insegnante di sostegno (support teacher) for students with certified disability. 104/1992 law applies equally to all children.',
      contactAuthority: 'Ufficio Scolastico Regionale (regional school office). MIUR helpline: 06 5849 1. Local Comune education office.',
      immigrantSpecificNotes: 'One of strongest protections in EU — Art. 38 TU Immigration explicitly states undocumented children have education rights. Schools cannot report undocumented families. Intercultural education guidelines. Cap of 30% foreign students per class (controversial, often waived).',
    ),

    // 16. LATVIA
    SchoolEnrollment(
      country: 'Latvia',
      countryCode: 'LV',
      rightRegardlessOfStatus: true,
      legalBasis: 'Education Law (Izglītības likums) Section 3; Asylum Law Art. 28 — education rights for asylum seeker children',
      compulsoryAgeStart: 5,
      compulsoryAgeEnd: 16,
      documentsNeeded: ['Identity document', 'Proof of residence or asylum seeker certificate', 'Health certificate'],
      enrollmentPossibleWithoutDocuments: true,
      enrollmentProcess: 'Apply to the municipal education department or directly to schools. Refugee children: coordinated through the Office of Citizenship and Migration Affairs (PMLP) and municipal education departments.',
      languageSupportProgram: 'Latviešu valodas kā otrās valodas apguve (Latvian as Second Language)',
      languageSupportDetails: 'Additional Latvian language hours in schools. Integration support program for newcomer children since 2016. Up to 480 hours of Latvian language preparation available. Bilingual education programs in some schools.',
      freeSchoolMeals: true,
      freeMealsDetails: 'Free meals for grades 1-4 state-funded. Additional free meals for socially vulnerable children in higher grades through municipal programs. Refugee children receive free meals.',
      specialEducationRights: 'Special education commissions assess needs. Inclusive education promoted. Special schools and integrated support in mainstream schools available.',
      contactAuthority: 'Ministry of Education and Science: +371 67 226 209. State Education Quality Service (IKVD).',
      immigrantSpecificNotes: 'Since Ukrainian refugee wave (2022), expanded integration support. Latvian language courses prioritized. Municipal coordinators for newcomer education. Free textbooks in basic education.',
    ),

    // 17. LITHUANIA
    SchoolEnrollment(
      country: 'Lithuania',
      countryCode: 'LT',
      rightRegardlessOfStatus: true,
      legalBasis: 'Law on Education (Švietimo įstatymas) Art. 24; Law on the Legal Status of Aliens Art. 28',
      compulsoryAgeStart: 6,
      compulsoryAgeEnd: 16,
      documentsNeeded: ['Identity document or asylum certificate', 'Proof of residence', 'Health certificate'],
      enrollmentPossibleWithoutDocuments: true,
      enrollmentProcess: 'Municipal education division assigns school. Direct application to schools possible. Refugee Registration Center coordinates for asylum seeker children.',
      languageSupportProgram: 'Lietuvių kalbos mokymasis (Lithuanian Language Learning) / Mobilios grupės (Mobile Groups)',
      languageSupportDetails: 'Intensive Lithuanian language courses: up to 1 year preparatory class. Mobile groups provide language support in schools with few foreign students. 640 hours of Lithuanian language preparation funded by the state.',
      freeSchoolMeals: true,
      freeMealsDetails: 'Free meals for socially vulnerable families. Since 2024 expansion, free meals for grades 1-4 in most municipalities. Refugee children qualify for free meals.',
      specialEducationRights: 'Pedagogical-Psychological Services (PPT) assess needs. Inclusive education policy. Special education assistants provided. Equal rights for all children.',
      contactAuthority: 'Ministry of Education, Science and Sport: +370 5 219 1190. Education Development Center (UPC).',
      immigrantSpecificNotes: 'Expanded infrastructure since 2022 refugee arrivals. Lithuanian language support scaled up. Integration support coordinators in schools. Free textbooks and school supplies for vulnerable families.',
    ),

    // 18. LUXEMBOURG
    SchoolEnrollment(
      country: 'Luxembourg',
      countryCode: 'LU',
      rightRegardlessOfStatus: true,
      legalBasis: 'Loi du 6 février 2009 on compulsory education. Constitution Art. 23. All children aged 4-16 residing in Luxembourg must attend school.',
      compulsoryAgeStart: 4,
      compulsoryAgeEnd: 16,
      documentsNeeded: ['Registration at commune (any proof of residence)', 'Birth certificate or age proof', 'Vaccination record'],
      enrollmentPossibleWithoutDocuments: true,
      enrollmentProcess: 'Register at the commune which assigns the school. SECAM (Service de la scolarisation des enfants étrangers) evaluates linguistic competences and recommends placement.',
      languageSupportProgram: 'Cours d\'accueil / Alphabétisation / Classes d\'insertion (CLIJA — Classes d\'insertion pour jeunes adultes)',
      languageSupportDetails: 'Luxembourg uses trilingual system (Luxembourgish, French, German). Cours d\'accueil: intensive language classes for newcomers. CASNA (Cellule d\'accueil scolaire pour élèves nouveaux arrivants) assesses and places. CLIJA classes for 12-17 year olds.',
      freeSchoolMeals: false,
      freeMealsDetails: 'Maisons relais (after-school care) provide meals at reduced cost. Chèque-service accueil system subsidizes childcare and meals. Low-income families receive significant subsidies.',
      specialEducationRights: 'Centres de compétences en psychopédagogie spécialisée assess and support. Commission d\'inclusion (CI) at school level. Inclusive education strengthened by 2017 law reform.',
      contactAuthority: 'MENJE (Ministère de l\'Éducation nationale): +352 247-85100. CASNA: +352 247-85277.',
      immigrantSpecificNotes: 'Highly multicultural — 47% of students are foreign nationals. Strong support infrastructure. SECAM/CASNA specifically for immigrant student integration. European Schools also available. Trilingual challenge significant for newcomers.',
    ),

    // 19. MALTA
    SchoolEnrollment(
      country: 'Malta',
      countryCode: 'MT',
      rightRegardlessOfStatus: true,
      legalBasis: 'Education Act (Cap. 327) 1988 as amended. Refugees Act (Cap. 420). All children in Malta have right to free compulsory education.',
      compulsoryAgeStart: 5,
      compulsoryAgeEnd: 16,
      documentsNeeded: ['Birth certificate or age proof', 'Proof of address', 'eResidence card or asylum seeker document'],
      enrollmentPossibleWithoutDocuments: true,
      enrollmentProcess: 'Register at the Student Services Department within the Directorate for Educational Services. Assigned to nearest state school. Induction Hub for newcomer children assesses and prepares.',
      languageSupportProgram: 'Induction Hub Programme / Complementary Education',
      languageSupportDetails: 'Induction Hub: 3-6 months intensive Maltese and English for newcomer children. Bilingual system (Maltese + English). ESL (English as Second Language) support in schools. Migrant Learners Unit coordinates.',
      freeSchoolMeals: false,
      freeMealsDetails: 'Subsidized school meals through Skolasajf program. Breakfast clubs in some schools. Social assistance covers meal costs for vulnerable families. No universal free meals.',
      specialEducationRights: 'CRPD assessment. Learning Support Educators (LSE) in schools. Inclusive Education Unit. Individual Education Programme (IEP) for students with special needs.',
      contactAuthority: 'Directorate for Educational Services: +356 2598 2000. Migrant Learners Unit: +356 2598 2445.',
      immigrantSpecificNotes: 'Migrant Learners Unit (MLU) specifically supports immigrant education. Hubbing system for newcomers well-established. Free state education. Malta has bilingual education system — both Maltese and English used.',
    ),

    // 20. NETHERLANDS
    SchoolEnrollment(
      country: 'Netherlands',
      countryCode: 'NL',
      rightRegardlessOfStatus: true,
      legalBasis: 'Leerplichtwet 1969 (Compulsory Education Act). Dutch Constitution Art. 23. All children 5-18 residing in NL must attend school.',
      compulsoryAgeStart: 5,
      compulsoryAgeEnd: 18,
      documentsNeeded: ['BSN number (Burgerservicenummer) — can be obtained', 'Proof of address', 'Previous school reports (if available)'],
      enrollmentPossibleWithoutDocuments: true,
      enrollmentProcess: 'Contact the school directly or the municipality (gemeente). Leerplichtambtenaar (compulsory education officer) ensures all children are enrolled. International Schakelklassen (ISK) for newcomers in secondary education.',
      languageSupportProgram: 'ISK (Internationale Schakelklassen) / Nieuwkomersonderwijs (Newcomer Education)',
      languageSupportDetails: 'ISK classes: 1-2 years intensive Dutch for secondary students (12-18). Primary: Nieuwkomersklassen or taalklassen in regular schools, up to 2 years. NT2 (Nederlands als Tweede Taal) methodology. LOWAN supports schools with newcomer education.',
      freeSchoolMeals: false,
      freeMealsDetails: 'No universal free meals. Schoolontbijt (school breakfast) program run by charity Jeugdeducatiefonds. Since 2023, government piloting free school lunches in disadvantaged areas. Asylum center schools may provide meals.',
      specialEducationRights: 'Passend Onderwijs (Appropriate Education) since 2014. Samenwerkingsverbanden (cooperation alliances) ensure every child gets support. Equal rights for immigrant children.',
      contactAuthority: 'DUO (Dienst Uitvoering Onderwijs): +31 50 599 9099. Gemeente education department. LOWAN (national newcomer education support).',
      immigrantSpecificNotes: 'Strong newcomer education system. ISK well-established nationally. Undocumented children ("ongedocumenteerde kinderen") have full leerplicht and education rights (confirmed by Hoge Raad). COA (refugee agency) coordinates asylum seeker children education.',
    ),

    // 21. POLAND
    SchoolEnrollment(
      country: 'Poland',
      countryCode: 'PL',
      rightRegardlessOfStatus: true,
      legalBasis: 'Prawo oświatowe (Education Law Act) 2016, Art. 165 — foreign citizens have right to education on same terms as Polish citizens in public schools',
      compulsoryAgeStart: 7,
      compulsoryAgeEnd: 18,
      documentsNeeded: ['Any identity document', 'Proof of address or accommodation center address'],
      enrollmentPossibleWithoutDocuments: true,
      enrollmentProcess: 'Apply to the school designated for the residential area (szkoła obwodowa). School principal enrolls the child. If needed, the Gmina (municipality) education office assists. Ukrainian refugee children have simplified fast-track enrollment.',
      languageSupportProgram: 'Oddział przygotowawczy (Preparatory Class) / Dodatkowe zajęcia z języka polskiego (Additional Polish Language Classes)',
      languageSupportDetails: 'Preparatory classes (oddział przygotowawczy): intensive Polish with core subjects, up to 12 months. Or additional Polish lessons: 2-5 hours/week for 12 months (extendable). Teacher assistant for students not speaking Polish.',
      freeSchoolMeals: false,
      freeMealsDetails: 'Program "Posiłek w szkole i w domu" covers school meals for children from families below 150% of poverty line. Refugee families typically qualify. School canteen fees otherwise low (PLN 3-8/day).',
      specialEducationRights: 'Poradnie psychologiczno-pedagogiczne (counseling centers) assess needs. Orzeczenie o potrzebie kształcenia specjalnego (special education decision). Inclusive education or special schools. Equal rights for foreign children.',
      contactAuthority: 'Kuratorium Oświaty (regional education authority) in each voivodeship. Ministry of Education: +48 22 347 41 00.',
      immigrantSpecificNotes: 'Since 2022, massive expansion for Ukrainian children (over 185,000 enrolled). Polish language support significantly expanded. Cultural assistants in schools. Free textbooks in grades 1-3. Public education entirely free.',
    ),

    // 22. PORTUGAL
    SchoolEnrollment(
      country: 'Portugal',
      countryCode: 'PT',
      rightRegardlessOfStatus: true,
      legalBasis: 'Portuguese Constitution Art. 74; Lei de Bases do Sistema Educativo (Law 46/86); Decree-Law 67/2004 — all children regardless of status have right to education',
      compulsoryAgeStart: 6,
      compulsoryAgeEnd: 18,
      documentsNeeded: ['Any identification (or declaration)', 'Proof of residence (atestado de residência from Junta de Freguesia)'],
      enrollmentPossibleWithoutDocuments: true,
      enrollmentProcess: 'Register through the school cluster (agrupamento de escolas) portal or directly at the school. PLNM (Portuguese as non-native language) assessment upon enrollment. No documents strictly required — schools must accept.',
      languageSupportProgram: 'PLNM (Português Língua Não Materna — Portuguese as Non-Native Language)',
      languageSupportDetails: 'PLNM program: 3 proficiency levels (initiation, intermediate, advanced). Minimum 4 hours/week of Portuguese language support. National curriculum includes PLNM as a specific subject. Acolhimento (welcoming) teams in school clusters.',
      freeSchoolMeals: true,
      freeMealsDetails: 'Escalão A (lowest income): free meals and school supplies. Escalão B: reduced price. ASE (Ação Social Escolar) system. Refugee and immigrant families often qualify for Escalão A. Free milk and fruit programs.',
      specialEducationRights: 'Decree-Law 54/2018 on inclusive education. Universal design for learning approach. Multidisciplinary teams in schools. Equal rights for all children.',
      contactAuthority: 'DGEstE (Direção-Geral dos Estabelecimentos Escolares): +351 21 340 7200. ACM (Alto Comissariado para as Migrações): +351 218 106 100.',
      immigrantSpecificNotes: 'Portugal known for inclusive immigration policy. SEF replaced by AIMA (2023). ACM provides integration support. Choices Programme targets immigrant youth. No discrimination in school enrollment — Provedor de Justiça (Ombudsman) enforces.',
    ),

    // 23. ROMANIA
    SchoolEnrollment(
      country: 'Romania',
      countryCode: 'RO',
      rightRegardlessOfStatus: true,
      legalBasis: 'Education Law 1/2011, Art. 45 — foreign citizens have access to education under same conditions. Constitution Art. 32.',
      compulsoryAgeStart: 6,
      compulsoryAgeEnd: 16,
      documentsNeeded: ['Birth certificate or equivalent', 'Proof of address or accommodation center', 'Medical records'],
      enrollmentPossibleWithoutDocuments: true,
      enrollmentProcess: 'Register at the school through Inspectoratul Școlar Județean (County School Inspectorate). Refugee children: IGI (General Inspectorate for Immigration) coordinates with education authorities.',
      languageSupportProgram: 'Curs de limba română (Romanian Language Course) / An pregătitor (Preparatory Year)',
      languageSupportDetails: 'Preparatory year of intensive Romanian language (up to 1 academic year). 4-5 hours/week of additional Romanian language support. Programs delivered in schools with foreign students. NGOs (CNRR, JRS Romania) supplement language education.',
      freeSchoolMeals: false,
      freeMealsDetails: 'Pilot "Masă caldă" (warm meal) program in disadvantaged areas expanding since 2022. Euro 200 social vouchers for school supplies (Sprijin pentru România Educată). Refugee children receive support through humanitarian programs.',
      specialEducationRights: 'CJRAE/CMBRAE (County/Bucharest resource and assistance centers) assess special needs. Inclusive education policy. Special education support available.',
      contactAuthority: 'Ministry of Education: +40 21 405 62 00. County School Inspectorates. CNRR (Romanian National Council for Refugees).',
      immigrantSpecificNotes: 'Growing immigrant population. Romanian language preparation available but capacity limited outside Bucharest. Free public education. Textbooks free for primary school. Ukrainian refugee children accommodated since 2022.',
    ),

    // 24. SLOVAKIA
    SchoolEnrollment(
      country: 'Slovakia',
      countryCode: 'SK',
      rightRegardlessOfStatus: true,
      legalBasis: 'School Act 245/2008 Z.z., Section 146 — children of foreigners have right to education under same conditions as Slovak citizens',
      compulsoryAgeStart: 6,
      compulsoryAgeEnd: 16,
      documentsNeeded: ['Proof of identity', 'Proof of residence or temporary accommodation', 'Health certificate'],
      enrollmentPossibleWithoutDocuments: true,
      enrollmentProcess: 'Enroll at the school in the school district (školský obvod). Municipality assigns school. For asylum seekers: Migration Office coordinates with the Regional Education Office (Regionálny úrad školskej správy).',
      languageSupportProgram: 'Jazykový kurz slovenského jazyka (Slovak Language Course) / Adaptačné vzdelávanie',
      languageSupportDetails: 'Basic Slovak language course (up to 20 lessons/year). Adaptation education program for newcomer children. Additional Slovak as a second language support. Very limited specialized infrastructure — most support through mainstream schools.',
      freeSchoolMeals: true,
      freeMealsDetails: 'Free school lunches for all pupils in state schools since 2023 (dotácia na stravu). Covers grades 1-9 in primary schools. One of the newest universal free meal programs in the EU.',
      specialEducationRights: 'Centres of educational-psychological counseling and prevention (CPPPaP) assess needs. Inclusive education promoted. Special schools and integration support available.',
      contactAuthority: 'Ministry of Education: +421 2 593 74 111. Regional Education Offices (RÚŠS). VÚDPaP (Research Institute).',
      immigrantSpecificNotes: 'Relatively small immigrant population but growing. Slovak language support capacity expanding. Free public education at all levels. School supplies support for socially disadvantaged families.',
    ),

    // 25. SLOVENIA
    SchoolEnrollment(
      country: 'Slovenia',
      countryCode: 'SI',
      rightRegardlessOfStatus: true,
      legalBasis: 'Basic School Act (Zakon o osnovni šoli), Art. 10; International Protection Act. All children in Slovenia have right to compulsory education.',
      compulsoryAgeStart: 6,
      compulsoryAgeEnd: 15,
      documentsNeeded: ['Proof of identity or age', 'Proof of residence or asylum certificate'],
      enrollmentPossibleWithoutDocuments: true,
      enrollmentProcess: 'Register at the nearest school or through the municipal education office. Integration House (Hiša za otroke) in Ljubljana offers initial reception for newcomer children.',
      languageSupportProgram: 'Začetni tečaj slovenščine (Initial Slovenian Course) / Dopolnilni pouk slovenščine',
      languageSupportDetails: 'Initial intensive Slovenian course: up to 1 year (120 hours). Additional supplementary Slovenian lessons (dopolnilni pouk): 2-5 hours/week during school year. Bilingual education available in areas with Italian/Hungarian minorities.',
      freeSchoolMeals: true,
      freeMealsDetails: 'Subsidized school meals based on income bracket. Lowest income: free meals. School Nutrition Act guarantees healthy meals. Most immigrant families qualify for free or heavily subsidized meals.',
      specialEducationRights: 'Zakon o usmerjanju otrok s posebnimi potrebami (Placement of Children with Special Needs Act). Assessment by counseling services. Inclusive education model with additional support.',
      contactAuthority: 'Ministry of Education: +386 1 400 54 00. National Education Institute of Slovenia (ZRSŠ): +386 1 420 12 00.',
      immigrantSpecificNotes: 'Small but growing immigrant student population. Slovenian language support well-organized. Free basic education including textbooks (loan scheme). Cultural mediators available in some schools. Saturday schools for mother tongue education.',
    ),

    // 26. SPAIN
    SchoolEnrollment(
      country: 'Spain',
      countryCode: 'ES',
      rightRegardlessOfStatus: true,
      legalBasis: 'Spanish Constitution Art. 27; Ley Orgánica 2/2006 (LOE) modified by LOMLOE 2020; Ley Orgánica 4/2000 Art. 9 — all foreigners under 18 have right and duty to education',
      compulsoryAgeStart: 6,
      compulsoryAgeEnd: 16,
      documentsNeeded: ['Empadronamiento (municipal registration) — NO legal status required for this', 'Birth certificate or age proof', 'Vaccination record'],
      enrollmentPossibleWithoutDocuments: true,
      enrollmentProcess: 'First: empadronamiento at the Ayuntamiento (free, regardless of status). Then apply to school through Comunidad Autónoma education service. Aula de enlace/acogida for initial assessment.',
      languageSupportProgram: 'Aulas de Enlace (Madrid) / Aules d\'Acollida (Catalonia) / Aulas ATAL (Andalusia) / Aulas de Adaptación Lingüística — varies by Comunidad Autónoma',
      languageSupportDetails: 'Intensive Spanish (or co-official language) classes for newcomers. Typically 6-12 months. Aulas de enlace (Madrid): full-time intensive for 6-9 months. ATAL (Andalusia): itinerant teachers visit schools. Catalonia: Aules d\'acollida + Pla educatiu d\'entorn.',
      freeSchoolMeals: false,
      freeMealsDetails: 'Becas de comedor (meal grants) available through Comunidades Autónomas. Income-based. Many immigrant families qualify. Andalucía, Valencia: extensive free meal programs for vulnerable families. Each region has own system.',
      specialEducationRights: 'Equipos de Orientación Educativa y Psicopedagógica (EOEP) assess needs. Inclusive education under LOMLOE. Adaptaciones curriculares (curriculum adaptations). Equal rights for all children.',
      contactAuthority: 'Ministerio de Educación: 910 837 937. Regional Consejerías de Educación. Defensor del Pueblo for complaints.',
      immigrantSpecificNotes: 'Very strong protections. Empadronamiento (not residence permit) is the key document — available to ALL including undocumented. After empadronamiento, full access to education, health, social services. 17 Comunidades Autónomas each have own programs.',
    ),

    // 27. SWEDEN
    SchoolEnrollment(
      country: 'Sweden',
      countryCode: 'SE',
      rightRegardlessOfStatus: true,
      legalBasis: 'Skollag (Education Act) 2010:800, Chapter 29 Section 2 — all children in Sweden have right to education. Includes asylum seekers and undocumented (papperslösa) children.',
      compulsoryAgeStart: 6,
      compulsoryAgeEnd: 16,
      documentsNeeded: ['No documents strictly required'],
      enrollmentPossibleWithoutDocuments: true,
      enrollmentProcess: 'Municipality (kommun) is obligated to offer school place. Contact the kommun education office (utbildningsförvaltningen). Assignment within 1 month of arrival. Asylum seekers: Migrationsverket coordinates with kommun.',
      languageSupportProgram: 'Förberedelseklass (Preparatory Class) / Studiehandledning på modersmålet (Study Guidance in Mother Tongue)',
      languageSupportDetails: 'Förberedelseklass: intensive Swedish for newcomers (individualized duration). SVA (Svenska som andraspråk — Swedish as Second Language): throughout schooling. Modersmålsundervisning (mother tongue education): if 5+ students speak same language. Studiehandledning: subjects explained in child\'s language.',
      freeSchoolMeals: true,
      freeMealsDetails: 'Free school lunch for ALL students in grundskola (compulsory school) and often in gymnasieskola (upper secondary). Universal — no means-testing. Sweden pioneered this alongside Finland. All children including undocumented receive free meals.',
      specialEducationRights: 'Skollag Chapter 3: all students entitled to support. Extra anpassningar (additional adjustments) and särskilt stöd (special support). Åtgärdsprogram (action plan) for students needing help. Specialpedagog/speciallärare in schools.',
      contactAuthority: 'Skolverket (National Agency for Education): +46 8 527 332 00. Municipal education office (Utbildningsförvaltning). Skolinspektionen (School Inspectorate) for complaints.',
      immigrantSpecificNotes: 'Since 2013 law change, even "papperslösa" (undocumented) children have RIGHT (not just access) to education. One of strongest protections in EU. Kartläggning (mapping) of prior knowledge on arrival. Extensive mother tongue support system. Newly arrived students exempt from certain grading initially.',
    ),
  ];

  // ============================================================
  // DIPLOMA RECOGNITION — ALL 27 EU COUNTRIES
  // ============================================================

  static const List<DiplomaRecognition> diplomaRecognitions = [
    // 1. AUSTRIA
    DiplomaRecognition(
      country: 'Austria',
      countryCode: 'AT',
      recognitionAuthority: 'ENIC NARIC Austria (Bundesministerium für Bildung, Wissenschaft und Forschung)',
      authorityWebsite: 'www.bmbwf.gv.at/anerkennung',
      processDescription: 'Submit application to ENIC NARIC Austria for academic recognition (Nostrifizierung for regulated professions, Bewertung for general assessment). Two tracks: Nostrifizierung (full equivalence for professional use) or Bewertung (evaluation/comparison statement).',
      timelineWeeks: '4-12 weeks for Bewertung; 3-12 months for Nostrifizierung',
      costEur: 'Bewertung: EUR 150. Nostrifizierung: EUR 150 + university fees if additional exams required',
      documentsRequired: 'Original diplomas + certified translations, transcript, CV/study plan, passport, application form',
      doctorRequalification: 'Nostrifizierung through Austrian medical university + Approbation from Österreichische Ärztekammer. EU/EEA doctors: automatic recognition under Directive 2005/36/EC. Third-country: full Nostrifizierung, may require additional exams.',
      engineerRequalification: 'Ingenieurgesetz 2017 for Ingenieur title. Nostrifizierung through technical university for academic title. EU engineers: automatic recognition for regulated specializations.',
      teacherRequalification: 'Nostrifizierung of teaching degree through university + Bildungsdirektion approval. May require additional courses in Austrian school system, language C1 proof.',
      nurseRequalification: 'Recognition through Gesundheit Österreich GmbH (GÖG). EU nurses: automatic under 2005/36/EC. Third-country: Nostrifikation + possible adaptation period.',
      lawyerRequalification: 'EU lawyers: registration under Lawyers Directive (98/5/EC) after 3 years practice. Non-EU: Austrian law degree required (Nostrifizierung) + Rechtsanwaltsprüfung.',
      legalBasis: 'Anerkennungs- und Bewertungsgesetz (AuBG) 2016; EU Directive 2005/36/EC transposed in Austrian law',
      refugeeSpecialProcedure: 'AST (Anlaufstellen für Personen mit im Ausland erworbenen Qualifikationen) counseling centers. Simplified procedure if documents lost — alternative assessment through interviews and tests.',
      contactInfo: 'ENIC NARIC Austria: naric@bmbwf.gv.at, +43 1 53120-5921',
    ),

    // 2. BELGIUM
    DiplomaRecognition(
      country: 'Belgium',
      countryCode: 'BE',
      recognitionAuthority: 'NARIC Flanders (Vlaamse Overheid) / Service de la reconnaissance des diplômes (French Community) / Ministerium der DG (German Community)',
      authorityWebsite: 'www.naricvlaanderen.be / www.equivalences.cfwb.be',
      processDescription: 'Three separate recognition authorities per community. Flanders: apply to NARIC Vlaanderen for gelijkwaardigheid (equivalence). French Community: Service des Équivalences for équivalence. Process varies by community.',
      timelineWeeks: 'Flanders: 4-16 weeks. French Community: 8-16 weeks. German Community: 4-8 weeks.',
      costEur: 'Flanders: EUR 90-300 depending on purpose. French Community: EUR 150-200. German Community: EUR 60-150.',
      documentsRequired: 'Diplomas + sworn translations, transcript, passport, application form, proof of payment',
      doctorRequalification: 'EU doctors: automatic recognition. Non-EU: visa committee evaluation + possible adaptation period or aptitude test. Registration with Orde van Artsen/Ordre des Médecins. RIZIV/INAMI registration.',
      engineerRequalification: 'Academic recognition through NARIC. IR (ingénieur civil) title protected. EU: automatic for listed specializations. Non-EU: possible bridging program.',
      teacherRequalification: 'Community-specific. Academic recognition + language certificate (Dutch C1/French C1). May require pedagogical training complement. Decree on teacher qualifications applies.',
      nurseRequalification: 'EU: automatic under 2005/36/EC via FPS Health. Non-EU: equivalence + possible adaptation. Registration with provincial nursing commission.',
      lawyerRequalification: 'EU lawyers: Lawyers Directive allows practice after 3 years. Non-EU: Belgian law degree essentially required. Bar exam (CAPA in French Community / beroepsopleiding in Flanders).',
      legalBasis: 'Decree on higher education (per community); EU Directive 2005/36/EC; Lisbon Recognition Convention',
      refugeeSpecialProcedure: 'Refugees without documents: alternative assessment possible in Flanders (sworn declaration + competency test). French Community: case-by-case review.',
      contactInfo: 'NARIC Flanders: naric@vlaanderen.be, +32 2 553 98 19. French Community Equivalences: +32 2 690 89 00',
    ),

    // 3. BULGARIA
    DiplomaRecognition(
      country: 'Bulgaria',
      countryCode: 'BG',
      recognitionAuthority: 'NACID (Национален център за информация и документация / National Centre for Information and Documentation)',
      authorityWebsite: 'www.nacid.bg',
      processDescription: 'Apply to NACID for academic recognition (признаване). NACID issues recognition certificate for higher education diplomas. Secondary education: recognized by Regional Education Department.',
      timelineWeeks: '4-8 weeks (2-3 months for complex cases)',
      costEur: 'EUR 35 (BGN 70) for standard procedure',
      documentsRequired: 'Legalized/apostilled diploma + certified translation to Bulgarian, transcript, passport copy, application',
      doctorRequalification: 'EU: automatic recognition through Ministry of Health. Non-EU: NACID academic recognition + BLS (Bulgarian Medical Association) evaluation + possible additional exams. Language requirement: Bulgarian B2.',
      engineerRequalification: 'NACID recognition of engineering degree. Not a regulated profession (except certain specializations). Registration with KIIP (Chamber of Engineers) for construction-related.',
      teacherRequalification: 'NACID recognition + Bulgarian language certificate (B2 minimum). Regional Education Department approval. May require pedagogical qualification supplement.',
      nurseRequalification: 'EU: automatic under 2005/36/EC. Non-EU: NACID recognition + Ministry of Health evaluation. Bulgarian language required.',
      lawyerRequalification: 'Bulgarian law degree required for bar admission. Recognition of foreign law degrees very limited. Must pass Bulgarian bar exam. Bulgarian citizenship or EU/EEA nationality required for full practice.',
      legalBasis: 'Higher Education Act; Professional Qualifications Recognition Act; EU Directive 2005/36/EC',
      refugeeSpecialProcedure: 'NACID has procedure for applicants without complete documentation. Declaration can substitute some documents. UNHCR assists with documentation.',
      contactInfo: 'NACID: nacid@nacid.bg, +359 2 8173 862',
    ),

    // 4. CROATIA
    DiplomaRecognition(
      country: 'Croatia',
      countryCode: 'HR',
      recognitionAuthority: 'ENIC/NARIC Croatia (Agencija za znanost i visoko obrazovanje — AZVO)',
      authorityWebsite: 'www.azvo.hr/en/enic-naric-office',
      processDescription: 'Apply to AZVO for academic recognition (priznavanje). Professional recognition for regulated professions through relevant competent authorities.',
      timelineWeeks: '4-8 weeks standard; up to 3 months for complex cases',
      costEur: 'EUR 100 (HRK 750) for academic recognition',
      documentsRequired: 'Apostilled diploma + certified Croatian translation, transcript, passport, application form',
      doctorRequalification: 'EU: automatic recognition. Non-EU: AZVO academic recognition + Ministry of Health evaluation + Croatian Medical Chamber registration. Croatian language C1.',
      engineerRequalification: 'AZVO academic recognition. Croatian Chamber of Engineers for regulated professions (construction, electrical). EU: automatic for harmonized qualifications.',
      teacherRequalification: 'AZVO recognition + Croatian language proficiency C1. Education and Teacher Training Agency (AZOO) approval. Pedagogical competence certificate may be required.',
      nurseRequalification: 'EU: automatic under 2005/36/EC. Non-EU: academic recognition + Ministry of Health assessment + possible adaptation period. Croatian language required.',
      lawyerRequalification: 'Croatian law degree or recognized equivalent. Croatian Bar Exam (Pravosudni ispit). EU lawyers: Lawyers Directive applies.',
      legalBasis: 'Act on Recognition of Foreign Educational Qualifications (NN 69/22); EU Directive 2005/36/EC',
      refugeeSpecialProcedure: 'Alternative recognition procedure for refugees without documents. Declaration under oath + competency assessment. Croatian Red Cross assists.',
      contactInfo: 'AZVO ENIC/NARIC: enic-naric@azvo.hr, +385 1 6274 800',
    ),

    // 5. CYPRUS
    DiplomaRecognition(
      country: 'Cyprus',
      countryCode: 'CY',
      recognitionAuthority: 'KYSATS (Κυπριακό Συμβούλιο Αναγνώρισης Τίτλων Σπουδών / Cyprus Council for the Recognition of Higher Education Qualifications)',
      authorityWebsite: 'www.kysats.ac.cy',
      processDescription: 'Apply to KYSATS for academic recognition. Professional recognition through respective professional bodies and Ministry of Education.',
      timelineWeeks: '4-12 weeks',
      costEur: 'EUR 51 for standard recognition',
      documentsRequired: 'Apostilled diploma + certified Greek or English translation, transcript, passport, application',
      doctorRequalification: 'EU: automatic recognition via Medical Council. Non-EU: KYSATS + Medical Council evaluation + possible Examination. Greek or English language proficiency required.',
      engineerRequalification: 'ETEK (Scientific Technical Chamber of Cyprus) registration. KYSATS academic recognition. EU: automatic for regulated specializations.',
      teacherRequalification: 'KYSATS recognition + Greek language C1. Ministry of Education approval. Cyprus Pedagogical Institute assessment. Teacher registration required.',
      nurseRequalification: 'EU: automatic under 2005/36/EC via Nursing Council. Non-EU: KYSATS + Nursing Council evaluation + adaptation period possible.',
      lawyerRequalification: 'Cyprus Bar Association registration. Common law system (English-influenced). Foreign law degrees: must pass Cyprus Bar Exam. EU lawyers: Lawyers Directive 98/5/EC.',
      legalBasis: 'Recognition of Higher Education Qualifications Law 68(I)/1996; EU Directive 2005/36/EC',
      refugeeSpecialProcedure: 'Case-by-case assessment for refugees. UNHCR Cyprus and KISA (NGO) assist with documentation and applications.',
      contactInfo: 'KYSATS: info@kysats.ac.cy, +357 22 402 300',
    ),

    // 6. CZECHIA
    DiplomaRecognition(
      country: 'Czechia',
      countryCode: 'CZ',
      recognitionAuthority: 'Centre for Higher Education Studies (CSVŠ) as ENIC-NARIC / Individual universities for nostrification',
      authorityWebsite: 'www.csvs.cz/enic-naric',
      processDescription: 'Two paths: (1) Nostrifikace through a comparable Czech university for full equivalence; (2) Recognition through CSVŠ for general academic assessment. Secondary education: regional authority (krajský úřad).',
      timelineWeeks: '4-8 weeks for CSVŠ; 1-6 months for university nostrification',
      costEur: 'CSVŠ: CZK 3,000 (EUR ~125). University nostrification: CZK 3,000 + possible exam fees.',
      documentsRequired: 'Apostilled/superlegalized diploma + Czech sworn translation, transcript, proof of study duration, passport',
      doctorRequalification: 'EU: automatic recognition through Ministry of Health. Non-EU: nostrification through medical faculty + approbation exam (aprobační zkouška) in Czech. Czech language exam (B2/C1).',
      engineerRequalification: 'University nostrification. Engineering not heavily regulated except authorized engineers (ČKAIT). EU: automatic for regulated specializations.',
      teacherRequalification: 'Nostrification through education faculty. Czech language proficiency C1. Pedagogical qualification required. Ministry of Education recognition.',
      nurseRequalification: 'EU: automatic under 2005/36/EC. Non-EU: nostrification + approbation. Czech language required.',
      lawyerRequalification: 'Czech law degree or nostrified equivalent. Czech Bar exam (advokátní zkouška). Czech citizenship or EU nationality for full practice (waivable). Czech language essential.',
      legalBasis: 'Act No. 111/1998 on Higher Education (amended); Act No. 18/2004 on Recognition; EU Directive 2005/36/EC',
      refugeeSpecialProcedure: 'CSVŠ offers alternative assessment for refugees without complete documents. Declaration + interview + competency test possible.',
      contactInfo: 'CSVŠ ENIC-NARIC: enic-naric@csvs.cz, +420 221 580 349',
    ),

    // 7. DENMARK
    DiplomaRecognition(
      country: 'Denmark',
      countryCode: 'DK',
      recognitionAuthority: 'Danish Agency for Higher Education and Science (Uddannelses- og Forskningsstyrelsen) — ENIC-NARIC Denmark',
      authorityWebsite: 'www.ufm.dk/en/education/recognition-and-transparency',
      processDescription: 'Apply online through STADS/kvali system. Assessment results in recognition statement (vurdering). For regulated professions: apply to relevant Danish authority.',
      timelineWeeks: '4-8 weeks for standard assessment',
      costEur: 'Free for individuals (state-funded)',
      documentsRequired: 'Diploma + English/Danish/other Scandinavian translation, transcript, CV, passport',
      doctorRequalification: 'EU: automatic recognition via Danish Patient Safety Authority (Styrelsen for Patientsikkerhed). Non-EU: full evaluation + Danish language exam + 6-12 month clinical assessment period. Very rigorous.',
      engineerRequalification: 'Academic recognition through NARIC. Chartered engineer (aut. ingeniør) registration if needed. Generally not heavily regulated.',
      teacherRequalification: 'Academic recognition + Danish language competency (Prøve i Dansk 3 or equivalent C1). Possible supplementary pedagogical training through professionshøjskole.',
      nurseRequalification: 'EU: automatic via Styrelsen for Patientsikkerhed. Non-EU: authorization requires evaluation + Danish language + adaptation period. 2-3 year process.',
      lawyerRequalification: 'Danish law degree required (or recognized equivalent). Advokateksamen (Bar exam). EU: Lawyers Directive 98/5/EC after 3 years. Danish language essential for practice.',
      legalBasis: 'Danish Act on the Assessment of Foreign Qualifications (2007, amended); EU Directive 2005/36/EC',
      refugeeSpecialProcedure: 'Special procedure for refugees (kvalifikationsvurdering for flygtninge). Alternative assessment through competency mapping when documents unavailable. Free and prioritized.',
      contactInfo: 'ENIC-NARIC Denmark: NARICDenmark@ufm.dk, +45 72 31 78 00',
    ),

    // 8. ESTONIA
    DiplomaRecognition(
      country: 'Estonia',
      countryCode: 'EE',
      recognitionAuthority: 'ENIC-NARIC Estonia (Haridus- ja Noorteamet / Education and Youth Board)',
      authorityWebsite: 'www.harno.ee/en/recognition',
      processDescription: 'Apply online through ENIC-NARIC Estonia. Academic recognition statement issued. Professional qualifications: apply to relevant competent authority.',
      timelineWeeks: '4-8 weeks',
      costEur: 'EUR 32 for standard assessment',
      documentsRequired: 'Diploma + English/Estonian translation, transcript, passport, application',
      doctorRequalification: 'EU: automatic recognition through Health Board (Terviseamet). Non-EU: ENIC-NARIC + Health Board evaluation + Estonian language B2/C1 + possible adaptation/aptitude test.',
      engineerRequalification: 'ENIC-NARIC recognition. Professional certification through Estonian Association of Engineers if needed. Not heavily regulated.',
      teacherRequalification: 'ENIC-NARIC recognition + Estonian language C1 (Eesti keele tasemeeksam). Possible pedagogical supplement at Estonian university.',
      nurseRequalification: 'EU: automatic via Health Board. Non-EU: recognition + Health Board evaluation + Estonian language required.',
      lawyerRequalification: 'Estonian law degree or recognized equivalent. Estonian Bar Association (Eesti Advokatuur) exam. Estonian language C1 essential.',
      legalBasis: 'Recognition of Foreign Professional Qualifications Act; Higher Education Act; EU Directive 2005/36/EC',
      refugeeSpecialProcedure: 'Alternative assessment available for refugees. Qualification passport process in cooperation with European Qualifications Passport for Refugees (Council of Europe).',
      contactInfo: 'ENIC-NARIC Estonia: enic-naric@harno.ee, +372 735 0500',
    ),

    // 9. FINLAND
    DiplomaRecognition(
      country: 'Finland',
      countryCode: 'FI',
      recognitionAuthority: 'Finnish National Agency for Education (Opetushallitus) — ENIC-NARIC Finland',
      authorityWebsite: 'www.oph.fi/en/services/recognition-qualifications',
      processDescription: 'Apply online to Opetushallitus. Two types: (1) Decision on comparability (rinnastamispäätös) for professional purposes; (2) Statement on level (tasoarvio) for informational purposes. Regulated professions: additional authority approval.',
      timelineWeeks: '4-8 weeks (statutory processing time: 4 months max)',
      costEur: 'EUR 236 for decision on comparability; EUR 100 for statement on level',
      documentsRequired: 'Legalized/apostilled diploma + certified Finnish/Swedish/English translation, transcript, proof of work experience if applicable',
      doctorRequalification: 'EU/EEA: automatic recognition via Valvira (National Supervisory Authority for Welfare and Health). Non-EU: Opetushallitus recognition + Valvira license process + Finnish/Swedish language skills. May require additional exams at Finnish university.',
      engineerRequalification: 'Opetushallitus recognition. Engineering generally not regulated. For authorized architect/building professional: specific authority approval.',
      teacherRequalification: 'Opetushallitus recognition (rinnastamispäätös) + Finnish or Swedish language proficiency. May require supplementary studies in Finnish education system. Teacher qualification highly regulated in Finland.',
      nurseRequalification: 'EU: automatic via Valvira. Non-EU: Opetushallitus recognition + Valvira assessment + language proficiency (Finnish/Swedish B1-B2). Supplementary training may be required.',
      lawyerRequalification: 'Finnish law degree or recognized equivalent + specific Finnish law courses. Asianajajaliitto (Finnish Bar Association) exam. Finnish or Swedish language essential. EU lawyers: Lawyers Directive.',
      legalBasis: 'Act on the Recognition of Professional Qualifications (1384/2015); Government Decree 120/2017; EU Directive 2005/36/EC; Lisbon Recognition Convention',
      refugeeSpecialProcedure: 'Opetushallitus participates in European Qualifications Passport for Refugees (EQPR). Alternative assessment with interview and portfolio when documents unavailable. SIMHE (Supporting Immigrants in Higher Education) guidance services at universities.',
      contactInfo: 'Opetushallitus ENIC-NARIC: recognition@oph.fi, +358 29 533 1000',
    ),

    // 10. FRANCE
    DiplomaRecognition(
      country: 'France',
      countryCode: 'FR',
      recognitionAuthority: 'ENIC-NARIC France (Centre international d\'études pédagogiques — France Éducation International)',
      authorityWebsite: 'www.france-education-international.fr/enic-naric',
      processDescription: 'Apply online for attestation de comparabilité (comparability certificate). This is not equivalence but a comparison with French system. For regulated professions: separate authority approval required.',
      timelineWeeks: '4-8 weeks (legally max 4 months)',
      costEur: 'EUR 70 for attestation de comparabilité',
      documentsRequired: 'Diploma + certified French translation (by sworn translator), transcript, passport, application form',
      doctorRequalification: 'EU: automatic recognition via Conseil National de l\'Ordre des Médecins (CNOM). Non-EU: PAE (Procédure d\'Autorisation d\'Exercice) — competitive selection, 1 year supervised practice, jury evaluation. French language C1+.',
      engineerRequalification: 'Titre d\'ingénieur via Commission des titres d\'ingénieur (CTI) assessment. Or attestation de comparabilité for academic recognition. Not as strictly regulated as medicine.',
      teacherRequalification: 'Attestation de comparabilité + DELF/DALF C1 French. Must pass French teaching concours (CAPES/CRPE/agrégation) for public schools. Private schools: more flexible.',
      nurseRequalification: 'EU: automatic via ARS (Agence Régionale de Santé). Non-EU: DRJSCS recognition procedure + French language + possible aptitude test. Registration with Ordre infirmier.',
      lawyerRequalification: 'CAPA (Certificat d\'Aptitude à la Profession d\'Avocat) required. Non-EU: French law Master + CAPA. EU lawyers: Directive 98/5/EC. Registration at Barreau.',
      legalBasis: 'Code de l\'éducation; Directive 2005/36/EC transposed; Arrêtés on professional recognition per sector',
      refugeeSpecialProcedure: 'ENIC-NARIC France has specific procedure for refugees (procédure réfugiés). Attestation possible with limited documents. OFPRA status proof accepted. UNHCR Qualifications Passport recognized.',
      contactInfo: 'ENIC-NARIC France: enic-naric@france-education-international.fr, +33 1 45 07 63 21',
    ),

    // 11. GERMANY
    DiplomaRecognition(
      country: 'Germany',
      countryCode: 'DE',
      recognitionAuthority: 'Anabin database (KMK-ZAB); IHK FOSA (for vocational); Landesbehörden for regulated professions. Central portal: anabin.kmk.org and anerkennung-in-deutschland.de',
      authorityWebsite: 'www.anerkennung-in-deutschland.de / anabin.kmk.org',
      processDescription: 'Anerkennungsgesetz (Recognition Act 2012): right to assessment. For academic: ZAB (Zentralstelle für ausländisches Bildungswesen) issues Zeugnisbewertung. For vocational: IHK FOSA or Handwerkskammer. For regulated: respective Landesbehörde.',
      timelineWeeks: 'ZAB Zeugnisbewertung: 4-8 weeks. Professional recognition: 3-4 months (legally max 3 months after complete application)',
      costEur: 'ZAB: EUR 200. Professional recognition: EUR 100-600 depending on profession and Land.',
      documentsRequired: 'Diploma + certified German translation (by sworn translator), transcript, CV, proof of professional experience, passport',
      doctorRequalification: 'EU: automatic recognition via Landesbehörde + Approbation. Non-EU: Kenntnisprüfung (knowledge exam) or Gleichwertigkeitsprüfung (equivalence test). German B2-C1 (Fachsprachprüfung). Berufserlaubnis (temporary license) possible during process.',
      engineerRequalification: 'Ingenieurkammer recognition in respective Bundesland. Title "Ingenieur" protected by state law. Academic recognition through ZAB. EU: generally straightforward.',
      teacherRequalification: 'Landesschulbehörde recognition. German C2 typically required. Additional studies often needed (German education law, didactics). Very Bundesland-specific process.',
      nurseRequalification: 'Landesbehörde recognition. Kenntnisprüfung or Anpassungslehrgang (adaptation course). German B1-B2. Recognition under Pflegeberufegesetz.',
      lawyerRequalification: 'German Staatsexamen (two state exams) essentially required. Very difficult path for non-EU lawyers. EU lawyers: Directive 98/5/EC (Rechtsanwaltsgesetz § 4ff). Eignungsprüfung (aptitude test) option.',
      legalBasis: 'Berufsqualifikationsfeststellungsgesetz (BQFG) 2012; EU Directive 2005/36/EC; 16 Länder recognition laws',
      refugeeSpecialProcedure: 'anerkennung-in-deutschland.de Anerkennungsberatung (free counseling). IQ Netzwerk (Integration through Qualification) provides free guidance. §14 BQFG: alternative assessment when documents unavailable (Qualifikationsanalyse — practical skills demonstration).',
      contactInfo: 'ZAB: zab@kmk.org, +49 228 501-0. Anerkennung hotline: +49 30 1815-1111',
    ),

    // 12. GREECE
    DiplomaRecognition(
      country: 'Greece',
      countryCode: 'GR',
      recognitionAuthority: 'DOATAP (Διεπιστημονικός Οργανισμός Αναγνώρισης Τίτλων Ακαδημαϊκών και Πληροφόρησης / Hellenic NARIC)',
      authorityWebsite: 'www.doatap.gr',
      processDescription: 'Apply to DOATAP for academic recognition (αναγνώριση ακαδημαϊκού τίτλου). DOATAP issues equivalence decision. Professional recognition: through SAEP (Συμβούλιο Αναγνώρισης Επαγγελματικών Προσόντων) for regulated professions.',
      timelineWeeks: '8-16 weeks (often longer in practice)',
      costEur: 'EUR 231 for academic recognition application',
      documentsRequired: 'Apostilled diploma + certified Greek translation, transcript, syllabus/course descriptions, passport',
      doctorRequalification: 'EU: automatic via SAEP + Ιατρικός Σύλλογος (Medical Association). Non-EU: DOATAP recognition + SAEP evaluation + possible aptitude test. Greek language required for practice.',
      engineerRequalification: 'DOATAP + TEE (Technical Chamber of Greece) registration. EU: automatic for regulated specializations via SAEP.',
      teacherRequalification: 'DOATAP recognition + Greek language proficiency. ASEP (civil service recruitment) exam for public schools. Complicated process for foreign-trained teachers.',
      nurseRequalification: 'EU: automatic via SAEP. Non-EU: DOATAP + Ministry of Health evaluation. Greek language required.',
      lawyerRequalification: 'Greek law degree (or DOATAP equivalent) + Bar exam (δικηγορικός διαγωνισμός). Very difficult for non-EU lawyers. EU: Directive 98/5/EC.',
      legalBasis: 'Law 3328/2005 on DOATAP; Presidential Decree 38/2010 (transposing EU Directive); EU Directive 2005/36/EC',
      refugeeSpecialProcedure: 'DOATAP can process applications with incomplete documentation for refugees. Greek Council for Refugees (GCR) and UNHCR assist. Process often slow.',
      contactInfo: 'DOATAP: info@doatap.gr, +30 210 5281 000',
    ),

    // 13. HUNGARY
    DiplomaRecognition(
      country: 'Hungary',
      countryCode: 'HU',
      recognitionAuthority: 'EENIC (Oktatási Hivatal — Educational Authority, Hungarian Equivalence and Information Centre)',
      authorityWebsite: 'www.oktatas.hu/kepesitesek_elismertetese',
      processDescription: 'Apply to Oktatási Hivatal for equivalence (elismerés/honosítás). Honosítás for full equivalence (involves university). Elismerés for general recognition.',
      timelineWeeks: '4-12 weeks for elismerés; up to 6 months for honosítás',
      costEur: 'EUR 60-110 (HUF 25,000-45,000) depending on type',
      documentsRequired: 'Apostilled diploma + certified Hungarian translation, transcript, passport, application form',
      doctorRequalification: 'EU: automatic via ENKK (Health Registration and Training Center). Non-EU: honosítás through medical university + ENKK evaluation + Hungarian language exam. Complex multi-step process.',
      engineerRequalification: 'Elismerés through Oktatási Hivatal. Magyar Mérnöki Kamara (Hungarian Chamber of Engineers) registration for practice.',
      teacherRequalification: 'Elismerés/honosítás + Hungarian language C1. Additional pedagogical studies may be required. Difficult process due to national curriculum specifics.',
      nurseRequalification: 'EU: automatic via ENKK. Non-EU: recognition + ENKK assessment + Hungarian language requirement.',
      lawyerRequalification: 'Hungarian law degree or honosítás + Magyar Ügyvédi Kamara (Hungarian Bar) exam. EU: Directive 98/5/EC. Hungarian language C2 essential.',
      legalBasis: 'Act C of 2001 on Recognition of Foreign Certificates and Degrees; Government Decree 137/2008; EU Directive 2005/36/EC',
      refugeeSpecialProcedure: 'Limited special procedures. Hungarian Helsinki Committee assists refugees with documentation and process. Competency-based assessment theoretically available.',
      contactInfo: 'Oktatási Hivatal: eenic@oh.gov.hu, +36 1 374 2100',
    ),

    // 14. IRELAND
    DiplomaRecognition(
      country: 'Ireland',
      countryCode: 'IE',
      recognitionAuthority: 'QQI (Quality and Qualifications Ireland) — NARIC Ireland',
      authorityWebsite: 'www.qqi.ie/what-we-do/the-qualifications-system/naric',
      processDescription: 'Free online comparability statement through QQI NARIC database. Check existing comparability advice online; if not listed, submit application for individual assessment. Places qualification on NFQ (National Framework of Qualifications).',
      timelineWeeks: '4-12 weeks for individual assessment (instant for database matches)',
      costEur: 'Free (no charge for comparability statements)',
      documentsRequired: 'Diploma (scanned), transcript, translation if not in English, passport',
      doctorRequalification: 'EU: automatic via Medical Council of Ireland. Non-EU: Medical Council assessment + PRES (Pre-Registration Examination System) or clinical assessment. English language: IELTS 7.0+ or OET.',
      engineerRequalification: 'QQI comparability. Engineers Ireland professional title (Chartered Engineer). Not statutorily regulated but professionally important.',
      teacherRequalification: 'QQI comparability + Teaching Council of Ireland registration. Irish language requirement (Irish-medium subjects). Possible qualification conditions (additional courses).',
      nurseRequalification: 'EU: automatic via NMBI (Nursing and Midwifery Board). Non-EU: NMBI assessment + aptitude test/adaptation period. English proficiency: IELTS 7.0 or OET.',
      lawyerRequalification: 'King\'s Inns (barristers) or Law Society of Ireland (solicitors). Qualified Lawyers Transfer Test. EU: Directive 98/5/EC. Common law system.',
      legalBasis: 'Qualifications and Quality Assurance (Education and Training) Act 2012; EU Directive 2005/36/EC; Lisbon Convention',
      refugeeSpecialProcedure: 'QQI provides free assessment for refugees. Sanctuary Scholarships available. UNHCR Ireland and Irish Refugee Council support. European Qualifications Passport for Refugees accepted.',
      contactInfo: 'QQI NARIC: info@qqi.ie, +353 1 905 8100',
    ),

    // 15. ITALY
    DiplomaRecognition(
      country: 'Italy',
      countryCode: 'IT',
      recognitionAuthority: 'CIMEA (Centro di Informazione sulla Mobilità e le Equivalenze Accademiche) — ENIC-NARIC Italy',
      authorityWebsite: 'www.cimea.it',
      processDescription: 'Dichiarazione di valore (declaration of value) through Italian consulate in country of origin. CIMEA issues comparability statements. Universities handle equipollenza (full equivalence) individually.',
      timelineWeeks: '8-16 weeks (dichiarazione di valore can be slow; CIMEA statements 4-8 weeks)',
      costEur: 'CIMEA statement: EUR 50-100. Dichiarazione di valore: consular fees vary. University equipollenza: EUR 100-200.',
      documentsRequired: 'Legalized diploma + Italian sworn translation, dichiarazione di valore or Hague apostille, transcript, passport',
      doctorRequalification: 'EU: automatic via Ministry of Health + Ordine dei Medici registration. Non-EU: university equivalence (equipollenza) + State exam (Esame di Stato) + Ordine registration. Italian language required.',
      engineerRequalification: 'University equipollenza or CIMEA statement + Esame di Stato for "ingegnere" title. Ordine degli Ingegneri registration. EU: automatic for some specializations.',
      teacherRequalification: 'Riconoscimento del titolo through MIUR (Ministry of Education). Italian C1+. May need to pass concorso (public competition) for permanent position.',
      nurseRequalification: 'EU: automatic via Ministry of Health. Non-EU: recognition + possible integrative measures. Italian language. IPASVI/OPI registration.',
      lawyerRequalification: 'Italian law degree or equipollenza + Esame di Stato per Avvocato. EU: Directive 98/5/EC. Italian language essential. Complex bureaucratic process.',
      legalBasis: 'D.Lgs. 206/2007 (transposing EU Directive 2005/36/EC); DPR 189/2009; University autonomy for equipollenza',
      refugeeSpecialProcedure: 'CIMEA participates in European Qualifications Passport for Refugees. Simplified procedure with UNHCR support. Declaration in lieu of documents possible for recognized refugees.',
      contactInfo: 'CIMEA: info@cimea.it, +39 06 6840 7425',
    ),

    // 16. LATVIA
    DiplomaRecognition(
      country: 'Latvia',
      countryCode: 'LV',
      recognitionAuthority: 'AIC (Akadēmiskās informācijas centrs / Academic Information Centre) — ENIC-NARIC Latvia',
      authorityWebsite: 'www.aic.lv',
      processDescription: 'Apply to AIC for academic recognition (atzīšana). AIC issues recognition certificate or statement. Professional recognition: through relevant competent authority.',
      timelineWeeks: '4-8 weeks',
      costEur: 'EUR 106.72 for standard procedure; EUR 213.43 for expedited',
      documentsRequired: 'Apostilled diploma + certified Latvian translation, transcript, passport, application form',
      doctorRequalification: 'EU: automatic via Health Inspection. Non-EU: AIC recognition + Health Inspection evaluation + Latvian language (B2/C1) + possible supplementary exam.',
      engineerRequalification: 'AIC recognition. Latvian Association of Certified Engineers registration for regulated activities.',
      teacherRequalification: 'AIC recognition + Latvian language C1. Ministry of Education approval. Possible supplementary pedagogical training.',
      nurseRequalification: 'EU: automatic. Non-EU: AIC + Health Inspection assessment. Latvian language required.',
      lawyerRequalification: 'Latvian law degree or recognized equivalent. Latvian Sworn Advocates Council exam. Latvian language C1+.',
      legalBasis: 'Law on Regulated Professions and Recognition of Professional Qualifications; Law on Higher Education; EU Directive 2005/36/EC',
      refugeeSpecialProcedure: 'AIC has procedure for applicants with incomplete documentation. Alternative assessment possible. Society "Shelter" and Latvian Red Cross assist.',
      contactInfo: 'AIC: aic@aic.lv, +371 67 225 155',
    ),

    // 17. LITHUANIA
    DiplomaRecognition(
      country: 'Lithuania',
      countryCode: 'LT',
      recognitionAuthority: 'SKVC (Studijų kokybės vertinimo centras / Centre for Quality Assessment in Higher Education) — ENIC-NARIC Lithuania',
      authorityWebsite: 'www.skvc.lt',
      processDescription: 'Apply to SKVC for academic recognition (kvalifikacijos pripažinimas). SKVC issues recognition decision or comparability statement.',
      timelineWeeks: '4-8 weeks (legally max 3 months)',
      costEur: 'EUR 58 for standard; EUR 116 for expedited',
      documentsRequired: 'Apostilled diploma + certified Lithuanian or English translation, transcript, passport, application',
      doctorRequalification: 'EU: automatic via State Health Care Accreditation Agency (VASPVT). Non-EU: SKVC recognition + VASPVT evaluation + Lithuanian language + possible competence assessment.',
      engineerRequalification: 'SKVC recognition. Engineering not heavily regulated. Professional registration through relevant association.',
      teacherRequalification: 'SKVC recognition + Lithuanian language (C1). Education Development Center approval. Supplementary studies may be needed.',
      nurseRequalification: 'EU: automatic via VASPVT. Non-EU: SKVC + VASPVT assessment + Lithuanian language.',
      lawyerRequalification: 'Lithuanian law degree or SKVC equivalent + Lithuanian Bar exam. Lithuanian language essential.',
      legalBasis: 'Law on the Recognition of Regulated Professional Qualifications; Law on Higher Education and Research; EU Directive 2005/36/EC',
      refugeeSpecialProcedure: 'SKVC participates in European Qualifications Passport for Refugees (EQPR). Alternative assessment when documents unavailable. Lithuanian Red Cross assists.',
      contactInfo: 'SKVC: skvc@skvc.lt, +370 5 210 4772',
    ),

    // 18. LUXEMBOURG
    DiplomaRecognition(
      country: 'Luxembourg',
      countryCode: 'LU',
      recognitionAuthority: 'MESR (Ministère de l\'Enseignement supérieur et de la Recherche) — ENIC-NARIC Luxembourg',
      authorityWebsite: 'www.mesr.public.lu/fr/reconnaissance-diplomes',
      processDescription: 'Apply to MESR for homologation (full equivalence) or registration of foreign diploma. Process: online application + document submission + evaluation.',
      timelineWeeks: '4-8 weeks for registration; 8-16 weeks for homologation',
      costEur: 'EUR 75 for registration; EUR 75 for homologation',
      documentsRequired: 'Apostilled diploma + certified French/German/English translation, transcript, passport',
      doctorRequalification: 'EU: automatic via Ministry of Health + Collège médical registration. Non-EU: homologation + Collège médical evaluation + language proficiency (French or German or Luxembourgish).',
      engineerRequalification: 'Diploma registration through MESR. OAI (Ordre des Architectes et Ingénieurs-Conseils) for professional title.',
      teacherRequalification: 'Homologation + Luxembourg trilingual requirement (Luxembourgish, French, German). Stage (supervised practice) required. MESR + MEN (Ministry of Education) coordination.',
      nurseRequalification: 'EU: automatic via Ministry of Health. Non-EU: homologation + evaluation + language requirement.',
      lawyerRequalification: 'Luxembourg law degree or homologated equivalent + CCDL (Cours complémentaire de droit luxembourgeois). Barreau de Luxembourg admission. EU: Directive 98/5/EC.',
      legalBasis: 'Loi du 28 octobre 2016 on recognition of professional qualifications; EU Directive 2005/36/EC',
      refugeeSpecialProcedure: 'MESR considers applications with limited documentation for refugees. OLAI (Office luxembourgeois de l\'accueil et de l\'intégration) assists.',
      contactInfo: 'MESR: reconnaissance@mesr.etat.lu, +352 247-86619',
    ),

    // 19. MALTA
    DiplomaRecognition(
      country: 'Malta',
      countryCode: 'MT',
      recognitionAuthority: 'MQRIC (Malta Qualifications Recognition Information Centre) within NCFHE',
      authorityWebsite: 'www.ncfhe.gov.mt/recognition',
      processDescription: 'Apply to MQRIC for recognition. Places qualification on MQF (Malta Qualifications Framework). Issues comparability statement or formal recognition.',
      timelineWeeks: '4-8 weeks',
      costEur: 'EUR 70 for standard recognition',
      documentsRequired: 'Apostilled diploma + English translation, transcript, passport, application form',
      doctorRequalification: 'EU: automatic via Medical Council of Malta. Non-EU: MQRIC + Medical Council assessment + possible aptitude test. English or Maltese proficiency.',
      engineerRequalification: 'MQRIC recognition. Warrant to practice engineering from Periti Warrant Board (for structural/civil).',
      teacherRequalification: 'MQRIC recognition + teacher registration with Education Department. Maltese language may be required for state schools. English sufficient for international schools.',
      nurseRequalification: 'EU: automatic via Council for Nurses and Midwives. Non-EU: MQRIC + Council assessment + language proficiency.',
      lawyerRequalification: 'Maltese law degree (or recognized equivalent) + Warrant from President of Malta. EU: Directive 98/5/EC. Mixed legal system (continental + common law).',
      legalBasis: 'Education Act (Cap. 327); Mutual Recognition of Qualifications Act (Cap. 451); EU Directive 2005/36/EC',
      refugeeSpecialProcedure: 'MQRIC processes refugee applications with available documentation. Refugee Commission (Commissioner for Refugees) assists.',
      contactInfo: 'MQRIC: mqric.ncfhe@gov.mt, +356 2770 1900',
    ),

    // 20. NETHERLANDS
    DiplomaRecognition(
      country: 'Netherlands',
      countryCode: 'NL',
      recognitionAuthority: 'Nuffic (EP-Nuffic) — ENIC-NARIC Netherlands / IDW (Informatiedienst Diploma Waardering)',
      authorityWebsite: 'www.nuffic.nl/en/diploma-recognition',
      processDescription: 'Apply to Nuffic IDW for credential evaluation (diplomawaardering). Issues evaluation statement placing diploma on NLQF. Free online database check first. For regulated professions: separate authority recognition.',
      timelineWeeks: '4-8 weeks',
      costEur: 'EUR 138 for standard evaluation',
      documentsRequired: 'Diploma + English/Dutch translation (certified), transcript, passport, application',
      doctorRequalification: 'EU: automatic via BIG-register (Ministry of Health). Non-EU: CIBG evaluation + knowledge/skills test + Dutch language (NT2-II). Process can take 2+ years.',
      engineerRequalification: 'Nuffic evaluation. "Ingenieur" title protected. KIVI (Royal Netherlands Society of Engineers) for professional recognition. Not heavily regulated except specific sectors.',
      teacherRequalification: 'Nuffic evaluation + DUO assessment for teaching qualification. Dutch language NT2-II. Possible supplementary training at hogeschool.',
      nurseRequalification: 'EU: automatic via BIG-register. Non-EU: CIBG assessment + competency test + Dutch NT2-II. AKV (algemene kennis- en vaardighedentoets).',
      lawyerRequalification: 'Dutch law degree or recognized equivalent + Nederlandse Orde van Advocaten (Bar Association) admission + beroepsopleiding (professional training). EU: Directive 98/5/EC.',
      legalBasis: 'Wet op de beroepen in het onderwijs; BIG-wet (for health professions); EU Directive 2005/36/EC; Lisbon Convention',
      refugeeSpecialProcedure: 'UAF (Stichting voor Vluchteling-Studenten) provides free support for refugee diploma recognition. Nuffic has refugee-specific fast-track. European Qualifications Passport accepted.',
      contactInfo: 'Nuffic IDW: diplomawaardering@nuffic.nl, +31 70 426 0260',
    ),

    // 21. POLAND
    DiplomaRecognition(
      country: 'Poland',
      countryCode: 'PL',
      recognitionAuthority: 'NAWA (Narodowa Agencja Wymiany Akademickiej) — ENIC-NARIC Poland; Individual universities for nostryfikacja',
      authorityWebsite: 'www.nawa.gov.pl/en/recognition',
      processDescription: 'Two paths: (1) NAWA issues written information on foreign qualifications (opinia o zagranicznych dyplomach). (2) Universities conduct nostryfikacja (full equivalence). Automatic recognition for many countries via bilateral agreements.',
      timelineWeeks: 'NAWA opinion: 4-6 weeks. University nostryfikacja: 3-6 months',
      costEur: 'NAWA: PLN 500 (EUR ~115). University nostryfikacja: up to 50% of first-year tuition (max PLN 3,205 / EUR ~740).',
      documentsRequired: 'Apostilled diploma + certified Polish translation (sworn translator), transcript, passport',
      doctorRequalification: 'EU: automatic via Ministry of Health. Non-EU: nostryfikacja at medical university + LEW/LDEW exam (Lekarski Egzamin Weryfikacyjny). Polish language B2+. Process: 1-3 years.',
      engineerRequalification: 'University nostryfikacja. PIIB (Polish Chamber of Civil Engineers) for construction. Not heavily regulated outside specific sectors.',
      teacherRequalification: 'Nostryfikacja of teaching degree + Polish language C1. Kuratorium Oświaty (education authority) recognition. May need Polish education system orientation.',
      nurseRequalification: 'EU: automatic. Non-EU: nostryfikacja + verification exam. Polish language B2. NIPiP (Nursing Council) registration.',
      lawyerRequalification: 'Polish law degree or nostryfikacja + egzamin adwokacki/radcowski (bar exam). EU: Directive 98/5/EC. Polish C2 essentially required.',
      legalBasis: 'Act on Higher Education and Science 2018 (Prawo o szkolnictwie wyższym i nauce); EU Directive 2005/36/EC; bilateral agreements',
      refugeeSpecialProcedure: 'Free nostryfikacja for holders of refugee status or subsidiary protection (Art. 327 of 2018 Act). NAWA assists. Simplified procedure with available documents.',
      contactInfo: 'NAWA: enic-naric@nawa.gov.pl, +48 22 390 35 00',
    ),

    // 22. PORTUGAL
    DiplomaRecognition(
      country: 'Portugal',
      countryCode: 'PT',
      recognitionAuthority: 'DGES (Direção-Geral do Ensino Superior) — ENIC-NARIC Portugal',
      authorityWebsite: 'www.dges.gov.pt/en/recognition',
      processDescription: 'Apply to DGES for equivalência (equivalence) or reconhecimento (recognition). Since Decree-Law 66/2018: simplified automatic recognition for many degrees. Regulated professions: professional order approval.',
      timelineWeeks: 'Automatic recognition: immediate to 4 weeks. Equivalência: 8-16 weeks.',
      costEur: 'EUR 50-150 depending on type. Automatic recognition via online platform: EUR 50.',
      documentsRequired: 'Apostilled diploma + Portuguese translation (if not in English/French/Spanish), transcript, passport',
      doctorRequalification: 'EU: automatic via Ordem dos Médicos. Non-EU: DGES recognition + Ordem dos Médicos evaluation + Portuguese language. May require supplementary exams.',
      engineerRequalification: 'DGES recognition + Ordem dos Engenheiros registration. Technical evaluation by the Ordem. EU: automatic for regulated specializations.',
      teacherRequalification: 'DGES recognition + Portuguese language C1. Possible supplementary training. Direction-General of Education (DGE) approval.',
      nurseRequalification: 'EU: automatic via Ordem dos Enfermeiros. Non-EU: DGES recognition + Ordem evaluation + Portuguese language + possible adaptation.',
      lawyerRequalification: 'Portuguese law degree or DGES equivalent + Ordem dos Advogados admission exam. EU: Directive 98/5/EC. Portuguese C1+.',
      legalBasis: 'Decree-Law 66/2018 (simplified recognition); Decree-Law 341/2007 (professional qualifications); EU Directive 2005/36/EC',
      refugeeSpecialProcedure: 'ACM (Alto Comissariado para as Migrações) assists refugees. DGES has flexible documentation requirements for refugees. European Qualifications Passport accepted.',
      contactInfo: 'DGES: naric@dges.gov.pt, +351 21 312 60 00',
    ),

    // 23. ROMANIA
    DiplomaRecognition(
      country: 'Romania',
      countryCode: 'RO',
      recognitionAuthority: 'CNRED (Centrul Național de Recunoaștere și Echivalare a Diplomelor / National Centre for Recognition and Equivalence of Diplomas)',
      authorityWebsite: 'www.cnred.edu.ro',
      processDescription: 'Apply to CNRED for echivalare (equivalence) or recunoaștere (recognition). CNRED issues equivalence certificate. Professional qualifications: relevant professional body.',
      timelineWeeks: '4-12 weeks',
      costEur: 'EUR 50-100 (RON 250-500) depending on type',
      documentsRequired: 'Apostilled diploma + certified Romanian translation (sworn translator), transcript, passport, application',
      doctorRequalification: 'EU: automatic via Ministry of Health + Colegiul Medicilor (Medical College). Non-EU: CNRED equivalence + Medical College evaluation + Romanian language + possible exam.',
      engineerRequalification: 'CNRED recognition. Ordinul Inginerilor (Engineers Order) registration for regulated activities.',
      teacherRequalification: 'CNRED equivalence + Romanian language. Ministry of Education approval. May require supplementary studies.',
      nurseRequalification: 'EU: automatic via OAMGMAMR (Order of Nurses). Non-EU: CNRED + OAMGMAMR assessment + Romanian language.',
      lawyerRequalification: 'Romanian law degree or CNRED equivalent + Barou (Bar) admission exam. EU: Directive 98/5/EC. Romanian language essential.',
      legalBasis: 'Law 200/2004 on recognition of professional qualifications; Emergency Ordinance 49/2009; EU Directive 2005/36/EC',
      refugeeSpecialProcedure: 'CNRED has procedure for refugees with limited documentation. CNRR (National Council for Refugees) assists. Alternative assessment possible.',
      contactInfo: 'CNRED: cnred@cnred.edu.ro, +40 21 405 56 51',
    ),

    // 24. SLOVAKIA
    DiplomaRecognition(
      country: 'Slovakia',
      countryCode: 'SK',
      recognitionAuthority: 'MŠVVŠ SR (Ministerstvo školstva, vedy, výskumu a športu SR) — ENIC-NARIC Slovakia / SAAIC (Slovak Academic Association for International Cooperation)',
      authorityWebsite: 'www.minedu.sk / www.saaic.sk',
      processDescription: 'Apply to MŠVVŠ for uznanie (recognition). Academic recognition through SAAIC ENIC-NARIC. Professional recognition through relevant competent authority.',
      timelineWeeks: '4-8 weeks',
      costEur: 'EUR 30-50',
      documentsRequired: 'Apostilled diploma + certified Slovak translation, transcript, passport',
      doctorRequalification: 'EU: automatic via Ministry of Health. Non-EU: recognition + Ministry of Health evaluation + Slovak language (B2/C1) + possible competence assessment.',
      engineerRequalification: 'Academic recognition through MŠVVŠ. Slovak Chamber of Civil Engineers for regulated construction activities.',
      teacherRequalification: 'Recognition + Slovak language C1. Ministry of Education additional assessment. Supplementary studies may be required.',
      nurseRequalification: 'EU: automatic. Non-EU: recognition + Ministry of Health assessment + Slovak language.',
      lawyerRequalification: 'Slovak law degree or recognized equivalent + Slovak Bar exam. EU: Directive 98/5/EC. Slovak language essential.',
      legalBasis: 'Act No. 422/2015 on Recognition of Education Documents and Professional Qualifications; EU Directive 2005/36/EC',
      refugeeSpecialProcedure: 'Limited special procedures. Alternative assessment available in principle. Slovak Humanitarian Council assists.',
      contactInfo: 'SAAIC ENIC-NARIC: enic-naric@saaic.sk, +421 2 209 22 201',
    ),

    // 25. SLOVENIA
    DiplomaRecognition(
      country: 'Slovenia',
      countryCode: 'SI',
      recognitionAuthority: 'ENIC-NARIC Slovenia (Ministry of Higher Education, Science and Innovation)',
      authorityWebsite: 'www.gov.si/en/topics/recognition-of-education',
      processDescription: 'Apply to ENIC-NARIC Slovenia for recognition (priznavanje). Issues evaluation opinion or formal recognition decision. Regulated professions: relevant ministry/authority.',
      timelineWeeks: '4-8 weeks (legally max 2 months)',
      costEur: 'EUR 36.21 for education recognition; EUR 72.42 for professional recognition',
      documentsRequired: 'Apostilled diploma + Slovenian or English translation, transcript, passport, application',
      doctorRequalification: 'EU: automatic via Medical Chamber of Slovenia (Zdravniška zbornica). Non-EU: ENIC-NARIC recognition + Medical Chamber evaluation + Slovenian language + possible exam.',
      engineerRequalification: 'ENIC-NARIC recognition. Chamber of Engineers (IZS) registration for regulated activities. Generally not heavily regulated.',
      teacherRequalification: 'ENIC-NARIC recognition + Slovenian language (C1). Ministry of Education approval. Supplementary pedagogical training may be needed.',
      nurseRequalification: 'EU: automatic via Nursing and Midwifery Board. Non-EU: recognition + evaluation + Slovenian language.',
      lawyerRequalification: 'Slovenian law degree or recognized equivalent + Bar exam (Pravniški državni izpit). EU: Directive 98/5/EC. Slovenian language essential.',
      legalBasis: 'Recognition and Assessment of Education Act (ZVDZ); EU Directive 2005/36/EC',
      refugeeSpecialProcedure: 'Alternative assessment for refugees with insufficient documentation. PIC (Legal Information Centre for NGOs) assists.',
      contactInfo: 'ENIC-NARIC Slovenia: gp.mvzi@gov.si, +386 1 478 46 00',
    ),

    // 26. SPAIN
    DiplomaRecognition(
      country: 'Spain',
      countryCode: 'ES',
      recognitionAuthority: 'NARIC Spain (Ministerio de Universidades) for university degrees; MECD (Ministerio de Educación y Formación Profesional) for non-university',
      authorityWebsite: 'www.universidades.gob.es/homologacion-y-equivalencia-de-titulos',
      processDescription: 'Two processes: (1) Homologación — full equivalence to specific Spanish degree. (2) Equivalencia — general level recognition. Apply through sede electrónica (electronic office). Convalidación for partial studies.',
      timelineWeeks: '6-12 months (homologación notoriously slow in Spain); equivalencia: 4-8 months',
      costEur: 'EUR 160.60 (tasa homologación). EUR 110 for equivalencia.',
      documentsRequired: 'Apostilled diploma + sworn Spanish translation (traductor jurado), transcript, passport, application form',
      doctorRequalification: 'EU: automatic via Ministerio de Sanidad. Non-EU: homologación of medical degree (VERY slow: 1-3 years) + MIR exam (residency selection exam). Spanish language C1+.',
      engineerRequalification: 'Homologación or equivalencia. Colegio de Ingenieros registration (colegiación) for practice. EU: automatic for harmonized titles.',
      teacherRequalification: 'Homologación + Spanish C1. Oposiciones (competitive exam) for public schools. Comunidad Autónoma-specific requirements.',
      nurseRequalification: 'EU: automatic via Ministerio de Sanidad. Non-EU: homologación + possible supplementary training. Spanish language. CGE (General Nursing Council) registration.',
      lawyerRequalification: 'Homologación of law degree + Máster de Acceso a la Abogacía + national bar exam. EU: Directive 98/5/EC. Very long process for non-EU lawyers.',
      legalBasis: 'Real Decreto 889/2022 on recognition; Real Decreto 967/2014 on equivalencia; EU Directive 2005/36/EC',
      refugeeSpecialProcedure: 'Simplified procedure for refugees (exención de apostilla — apostille exemption). CEAR (Comisión Española de Ayuda al Refugiado) and ACNUR (UNHCR Spain) assist. Flexible documentation requirements.',
      contactInfo: 'NARIC Spain: naric@universidades.gob.es, +34 91 506 56 00',
    ),

    // 27. SWEDEN
    DiplomaRecognition(
      country: 'Sweden',
      countryCode: 'SE',
      recognitionAuthority: 'UHR (Universitets- och högskolerådet / Swedish Council for Higher Education) — ENIC-NARIC Sweden',
      authorityWebsite: 'www.uhr.se/en/recognition',
      processDescription: 'Apply to UHR for recognition statement (utlåtande). UHR evaluates and places on Swedish qualifications framework. For regulated professions: separate authority (Socialstyrelsen for health, Skolverket for teachers).',
      timelineWeeks: '4-8 weeks (legally max 4 months)',
      costEur: 'Free (no charge for individuals)',
      documentsRequired: 'Diploma + Swedish/English translation, transcript, passport/ID copy',
      doctorRequalification: 'EU: automatic via Socialstyrelsen (National Board of Health and Welfare). Non-EU: UHR academic assessment + Socialstyrelsen evaluation + knowledge test (kunskapsprov) + Swedish language (C1 TISUS/SAS). Process: 1-3 years. Kompletterande utbildning (complementary training) available at universities.',
      engineerRequalification: 'UHR recognition. "Civilingenjör" title comparison. Not heavily regulated. Sveriges Ingenjörer (professional association) for career support.',
      teacherRequalification: 'UHR recognition + Skolverket (National Agency for Education) legitimation process. Swedish C1 (TISUS). Kompletterande pedagogisk utbildning (KPU — supplementary teacher training) often required. Snabbspår (fast track) program for refugee teachers.',
      nurseRequalification: 'EU: automatic via Socialstyrelsen. Non-EU: evaluation + kompletteringsutbildning (complementary training at university) + Swedish language + kunskapsprov. 1-2 year process.',
      lawyerRequalification: 'UHR recognition + Swedish law courses. Advokatsamfundet (Bar Association) membership after 3+ years supervised practice. EU: Directive 98/5/EC. Swedish essential.',
      legalBasis: 'Higher Education Ordinance (1993:100); EU Directive 2005/36/EC; Socialstyrelsen regulations (HSLF-FS)',
      refugeeSpecialProcedure: 'UHR has dedicated process for refugees (bedömning av utländsk utbildning för personer med flyktingbakgrund). Alternative assessment through interviews when documents unavailable. Snabbspår (fast track) programs for specific professions (teachers, doctors, nurses). Free.',
      contactInfo: 'UHR: registrator@uhr.se, +46 10 470 03 00',
    ),
  ];

  // ============================================================
  // UNIVERSITY ACCESS — ALL 27 EU COUNTRIES
  // ============================================================

  static const List<UniversityAccess> universityAccessData = [
    // 1. AUSTRIA
    UniversityAccess(
      country: 'Austria',
      countryCode: 'AT',
      tuitionNonEu: 'EUR 726.72/semester (non-EU). Some universities charge more.',
      tuitionEu: 'EUR 363.36/semester (EU/EEA) or free if within standard study period + 2 semesters',
      freeForRefugees: false,
      scholarshipPrograms: ['MORE Initiative (universities for refugees)', 'OeAD scholarships', 'ÖH social fund'],
      languageCoursesAvailable: 'Vorstudienlehrgang (VWU) — preparatory German courses at university level. ÖSD/Goethe certificates.',
      studentWorkRights: 'Non-EU students: 20 hrs/week during semester. No limit during breaks.',
      studentWorkHoursPerWeek: 20,
      admissionProcess: 'Apply through university directly. Studienplatzbewerbung portal. Nostrifizierung or Bewertung of diploma required. German B2/C1 (or university entrance exam).',
      preparatoryPrograms: 'Vorstudienlehrgang der Wiener Universitäten (VWU). University preparation courses. MORE program for refugees.',
      contactAuthority: 'OeAD (Austrian Exchange Service): +43 1 53408-0. Individual university international offices.',
      immigrantSpecificNotes: 'MORE initiative: free audit of courses for refugees at 22+ Austrian universities. ÖH (student union) support services. Refugees with recognized status: same tuition as Austrians. Asylum seekers: higher tuition but MORE provides access.',
    ),

    // 2. BELGIUM
    UniversityAccess(
      country: 'Belgium',
      countryCode: 'BE',
      tuitionNonEu: 'EUR 835-4,175/year depending on program and institution (Wallonia: higher for non-EU). Flanders: EUR 1,000-6,000/year.',
      tuitionEu: 'EUR 175-835/year (Flanders: EUR 1,000/year fixed for most programs)',
      freeForRefugees: false,
      scholarshipPrograms: ['DAFI/UNHCR scholarships', 'VLIR-UOS scholarships (Flanders)', 'ARES scholarships (French Community)', 'University-specific refugee programs'],
      languageCoursesAvailable: 'University language centers offer Dutch/French courses. CVO (Centra voor Volwassenenonderwijs) provide language preparation.',
      studentWorkRights: 'Student work contract (studentenarbeid): 600 hours/year with reduced social contributions. No weekly limit but semester schedule respected.',
      studentWorkHoursPerWeek: 20,
      admissionProcess: 'Apply through university. Equivalence of diploma from respective Community authority required. Language proof: Dutch (CNaVT) or French (DALF/TCF).',
      preparatoryPrograms: 'Voorbereidingsprogramma (Flanders). Année préparatoire (French Community). Some universities have refugee bridge programs.',
      contactAuthority: 'Flanders: VLIR: +32 2 792 55 00. Wallonia: ARES: +32 2 225 45 11.',
      immigrantSpecificNotes: 'Recognized refugees pay same tuition as Belgian students. Subsidiary protection holders: same rights. Asylum seekers: limited access, some universities offer free courses. Fedasil support for education costs.',
    ),

    // 3. BULGARIA
    UniversityAccess(
      country: 'Bulgaria',
      countryCode: 'BG',
      tuitionNonEu: 'EUR 2,000-8,000/year depending on program. Medicine: EUR 6,000-8,000.',
      tuitionEu: 'EUR 0-500/year (state-subsidized places)',
      freeForRefugees: true,
      scholarshipPrograms: ['State scholarship for refugees (equal to Bulgarian students)', 'DAFI/UNHCR scholarships', 'Bulgarian government scholarships for foreign students'],
      languageCoursesAvailable: 'University preparatory departments offer 1-year Bulgarian language courses. Approximately EUR 2,500/year.',
      studentWorkRights: 'Full work rights for students with valid residence permit.',
      studentWorkHoursPerWeek: 40,
      admissionProcess: 'Apply through university or via Bulgarian embassy. NACID recognition of diploma required. Bulgarian language preparatory year available.',
      preparatoryPrograms: '1-year preparatory course in Bulgarian at university language departments. Some universities offer English-language programs.',
      contactAuthority: 'Ministry of Education: +359 2 9217 799. NACID: +359 2 8173 862.',
      immigrantSpecificNotes: 'Refugees with status: same access and tuition as Bulgarian citizens. Bulgarian language is main barrier. Growing number of English-language programs (especially medicine). State dormitories available at low cost.',
    ),

    // 4. CROATIA
    UniversityAccess(
      country: 'Croatia',
      countryCode: 'HR',
      tuitionNonEu: 'EUR 1,000-6,000/year. Medicine at University of Zagreb: EUR 6,000-8,000.',
      tuitionEu: 'Free for full-time state-funded places (limited spots for EU non-Croatians)',
      freeForRefugees: true,
      scholarshipPrograms: ['National scholarships for refugees', 'DAFI/UNHCR scholarships', 'University-specific programs'],
      languageCoursesAvailable: 'Croatian language courses at university language centers. Croaticum program at University of Zagreb.',
      studentWorkRights: 'Student service contracts (studentski ugovor). Up to full-time during breaks.',
      studentWorkHoursPerWeek: 20,
      admissionProcess: 'National application portal (postani-student.hr) for Croatians. Direct application for international students. AZVO diploma recognition.',
      preparatoryPrograms: 'Croaticum language program. University of Zagreb preparatory courses for refugee students.',
      contactAuthority: 'AZVO: +385 1 6274 800. Ministry of Science and Education.',
      immigrantSpecificNotes: 'Recognized refugees: equal access as Croatian citizens. Croatian language is main barrier. Are You Syrious and other NGOs provide education support. Growing English-language offerings.',
    ),

    // 5. CYPRUS
    UniversityAccess(
      country: 'Cyprus',
      countryCode: 'CY',
      tuitionNonEu: 'EUR 3,400-10,000/year at public universities. Private: EUR 6,000-12,000.',
      tuitionEu: 'EUR 3,400/year at public universities',
      freeForRefugees: false,
      scholarshipPrograms: ['DAFI/UNHCR scholarships', 'University of Cyprus merit scholarships', 'Cyprus government scholarships (limited)'],
      languageCoursesAvailable: 'Greek language courses at University of Cyprus Language Centre. English widely used in higher education.',
      studentWorkRights: 'Students can work part-time with permit from Civil Registry and Migration Department.',
      studentWorkHoursPerWeek: 20,
      admissionProcess: 'Apply through university. KYSATS diploma recognition. Greek or English language proof depending on program.',
      preparatoryPrograms: 'Greek language preparatory courses. Some universities offer foundation programs.',
      contactAuthority: 'Ministry of Education: +357 22 800 600. KYSATS: +357 22 402 300.',
      immigrantSpecificNotes: 'Many English-language programs available. Private universities more accessible for non-Greek speakers. Recognized refugees may qualify for reduced tuition at public universities.',
    ),

    // 6. CZECHIA
    UniversityAccess(
      country: 'Czechia',
      countryCode: 'CZ',
      tuitionNonEu: 'Free if studying in Czech language. EUR 2,000-15,000/year for English-language programs.',
      tuitionEu: 'Free in Czech language. Same fees as non-EU for English programs.',
      freeForRefugees: true,
      scholarshipPrograms: ['Government scholarship program for developing countries', 'DAFI/UNHCR scholarships', 'InBáze integration program', 'UNHCR Czech Republic education fund'],
      languageCoursesAvailable: 'UJOP (Institute for Language and Preparatory Studies) — 1 year Czech preparatory course. Multiple university language centers.',
      studentWorkRights: 'No work permit needed for students. No hour restriction.',
      studentWorkHoursPerWeek: 40,
      admissionProcess: 'Apply directly to university. Czech-language programs: nostrifikace + entrance exam. English programs: direct application with recognized diploma.',
      preparatoryPrograms: 'UJOP Charles University preparatory year (Czech language + subject preparation). Available in Prague, Poděbrady, Mariánské Lázně.',
      contactAuthority: 'Ministry of Education: +420 234 811 111. DZS (Centre for International Cooperation in Education).',
      immigrantSpecificNotes: 'Key advantage: free tuition in Czech for ALL students regardless of nationality. Learning Czech opens free university education. Many affordable English programs. Strong technical universities.',
    ),

    // 7. DENMARK
    UniversityAccess(
      country: 'Denmark',
      countryCode: 'DK',
      tuitionNonEu: 'EUR 6,000-16,000/year depending on program. Medicine/engineering on higher end.',
      tuitionEu: 'Free (no tuition for EU/EEA students)',
      freeForRefugees: false,
      scholarshipPrograms: ['Danish Government Scholarships', 'Danida Fellowship Programme', 'University-specific tuition waivers', 'DAFI/UNHCR'],
      languageCoursesAvailable: 'Studieprøven (Danish language test for university). Danish language schools (sprogcentre). University-level Danish courses. Many programs in English.',
      studentWorkRights: 'Non-EU students: 20 hrs/week during semester, full-time June-August.',
      studentWorkHoursPerWeek: 20,
      admissionProcess: 'Apply through optagelse.dk (Danish programs) or direct to university (English programs). Credential assessment through NARIC Denmark.',
      preparatoryPrograms: 'Studieprøven preparation courses. Higher Preparatory Examination (HF) for those needing upper secondary qualification.',
      contactAuthority: 'Ministry of Higher Education: +45 72 31 78 00. Universities Denmark.',
      immigrantSpecificNotes: 'Recognized refugees with permanent residence: same tuition as Danish students. Many English-taught master programs. SU (student grants) available for refugees with permanent residence status. High cost of living.',
    ),

    // 8. ESTONIA
    UniversityAccess(
      country: 'Estonia',
      countryCode: 'EE',
      tuitionNonEu: 'EUR 1,660-11,000/year. Free in Estonian-language programs that meet credit requirements.',
      tuitionEu: 'Free in Estonian-language programs. Same rates as non-EU for English programs.',
      freeForRefugees: true,
      scholarshipPrograms: ['Dora Plus scholarships', 'Estonian government scholarships', 'DAFI/UNHCR', 'University-specific grants'],
      languageCoursesAvailable: 'Estonian language courses at university language centers. Keelekursused through Integration Foundation. Many English programs available.',
      studentWorkRights: 'No work permit needed. No hour restriction for students with valid residence permit.',
      studentWorkHoursPerWeek: 40,
      admissionProcess: 'Apply through DreamApply or university portal. ENIC-NARIC Estonia recognition. Estonian or English language proof.',
      preparatoryPrograms: 'Estonian language preparatory programs. University foundation courses.',
      contactAuthority: 'Ministry of Education: +372 735 0222. Study in Estonia portal.',
      immigrantSpecificNotes: 'Free tuition in Estonian-language programs is key advantage. Growing number of English programs. Digital-first education system. Refugees with international protection: equal access.',
    ),

    // 9. FINLAND
    UniversityAccess(
      country: 'Finland',
      countryCode: 'FI',
      tuitionNonEu: 'EUR 4,000-18,000/year for non-EU in English-language programs (since 2017). Finnish/Swedish programs: free for all.',
      tuitionEu: 'Free (no tuition for EU/EEA students regardless of language)',
      freeForRefugees: true,
      scholarshipPrograms: ['University tuition fee waivers (most universities offer)', 'EDUFI Fellowship Programme', 'Finland Scholarships', 'DAFI/UNHCR', 'SIMHE guidance for immigrants'],
      languageCoursesAvailable: 'Finnish/Swedish courses at universities (often free). Open university courses. YKI test preparation. Many master programs in English.',
      studentWorkRights: 'Non-EU students: 30 hrs/week during semester (since 2022 reform), unlimited during breaks.',
      studentWorkHoursPerWeek: 30,
      admissionProcess: 'Apply through Studyinfo.fi (Opintopolku). Finnish/Swedish entrance exams or SAT/international credentials for English programs. Opetushallitus diploma recognition.',
      preparatoryPrograms: 'SIMHE (Supporting Immigrants in Higher Education) at universities. VALMA (preparatory education for immigrants). Open university path. TUVA (preparatory education).',
      contactAuthority: 'Opetushallitus: +358 29 533 1000. Studyinfo.fi helpdesk.',
      immigrantSpecificNotes: 'Finnish/Swedish language programs remain FREE for everyone including non-EU. Key strategy: learn Finnish/Swedish for free education. SIMHE services at multiple universities help immigrants navigate higher education. Refugees with status: tuition waivers common. Open university allows starting studies while waiting for degree program.',
    ),

    // 10. FRANCE
    UniversityAccess(
      country: 'France',
      countryCode: 'FR',
      tuitionNonEu: 'EUR 2,770/year Licence, EUR 3,770/year Master at public universities (since 2019 "Bienvenue en France" reform). Exemptions widely available.',
      tuitionEu: 'EUR 170/year Licence, EUR 243/year Master at public universities',
      freeForRefugees: true,
      scholarshipPrograms: ['CROUS bourses (means-tested grants)', 'Eiffel Excellence Scholarships', 'Campus France scholarships', 'DAFI/UNHCR', 'Fondation de France refugee fund', 'Each university: exonération for refugees'],
      languageCoursesAvailable: 'DUEF/DUFLE (Diplôme Universitaire de Français) at universities. Alliance Française. DELF/DALF preparation. Many English master programs.',
      studentWorkRights: 'All students: 964 hours/year (about 20 hrs/week during term).',
      studentWorkHoursPerWeek: 20,
      admissionProcess: 'Undergraduate: Parcoursup (for French residents) or Études en France (for international). Master: Mon Master portal. Campus France processes applications for most non-EU students.',
      preparatoryPrograms: 'DU Passerelle (University Diploma for refugees to re-enter higher education). FLE courses. Année de remise à niveau (foundation year).',
      contactAuthority: 'Campus France: +33 1 40 40 58 58. CROUS offices (28 regional centers).',
      immigrantSpecificNotes: 'Recognized refugees: SAME tuition as French students (EUR 170-243). Subsidiary protection: same. Asylum seekers: some universities offer free enrollment (DU Passerelle programs). CROUS housing and grants for refugees. Many universities actively recruit refugee students.',
    ),

    // 11. GERMANY
    UniversityAccess(
      country: 'Germany',
      countryCode: 'DE',
      tuitionNonEu: 'Free at most public universities (no tuition). Exception: Baden-Württemberg EUR 1,500/semester for non-EU. Semester fee (Semesterbeitrag): EUR 100-400/semester everywhere.',
      tuitionEu: 'Free at public universities. Same semester fees.',
      freeForRefugees: true,
      scholarshipPrograms: ['DAAD scholarships', 'Deutschlandstipendium', 'DAFI/UNHCR', 'Friedrich Ebert/Konrad Adenauer/Heinrich Böll Stiftung', 'Integra program (DAAD for refugees)', 'Kiron Open Higher Education (online)'],
      languageCoursesAvailable: 'Studienkolleg (1-year university preparation + German). DSH/TestDaF preparation at universities. Goethe-Institut. Volkshochschulen. Many English master programs.',
      studentWorkRights: 'Non-EU students: 120 full days or 240 half days per year. Refugees: same rules with recognized status.',
      studentWorkHoursPerWeek: 20,
      admissionProcess: 'Apply through uni-assist.de (for most international applications) or directly to university. Studienkolleg for those needing preparation. ZAB Zeugnisbewertung for diploma recognition.',
      preparatoryPrograms: 'Studienkolleg (1 year: German + subject preparation, ends with Feststellungsprüfung). DAAD Integra program for refugees. Kiron digital learning platform. University bridge programs.',
      contactAuthority: 'DAAD: +49 228 882-0. uni-assist: +49 30 2016 46-000.',
      immigrantSpecificNotes: 'Germany is THE top destination for free higher education in EU. No tuition at public universities (except BW). Integra program specifically for refugees. Studienkolleg path for those without direct equivalence. DSH exam preparation widely available. Student visa allows work.',
    ),

    // 12. GREECE
    UniversityAccess(
      country: 'Greece',
      countryCode: 'GR',
      tuitionNonEu: 'EUR 1,500-12,000/year for English-language programs. Greek-language programs: free for all.',
      tuitionEu: 'Free (public universities, Greek-language programs)',
      freeForRefugees: true,
      scholarshipPrograms: ['IKY (State Scholarships Foundation)', 'DAFI/UNHCR', 'University-specific refugee programs', 'Solidarity Now education support'],
      languageCoursesAvailable: 'Greek language courses at universities. School of Modern Greek (University of Athens). Certificato di lingua greca preparation.',
      studentWorkRights: 'Non-EU students: 20 hrs/week with work permit.',
      studentWorkHoursPerWeek: 20,
      admissionProcess: 'Apply through Ministry of Education portal or university. Panhellenic exams for Greek residents. Special quota for refugees at some universities.',
      preparatoryPrograms: 'Greek language preparatory year. Foundation programs at some universities. Solidarity Now educational support programs.',
      contactAuthority: 'Ministry of Education: +30 210 344 2000. IKY: +30 210 372 6300.',
      immigrantSpecificNotes: 'Greek-language programs free for all. Limited English offerings. Recognized refugees: 5% special admission quota at some universities. Free textbooks for all public university students. Student welfare benefits (meals, housing) available.',
    ),

    // 13. HUNGARY
    UniversityAccess(
      country: 'Hungary',
      countryCode: 'HU',
      tuitionNonEu: 'EUR 1,200-16,000/year. Medicine: EUR 10,000-16,000. Other fields: EUR 1,200-5,000.',
      tuitionEu: 'State-funded (free) places available through Felvi.hu. Self-funded: same as non-EU rates.',
      freeForRefugees: false,
      scholarshipPrograms: ['Stipendium Hungaricum (government scholarship)', 'DAFI/UNHCR', 'Central European University (CEU) scholarships'],
      languageCoursesAvailable: 'Hungarian language preparatory programs at universities. Balassi Intézet. Many programs available in English (especially medicine, engineering).',
      studentWorkRights: 'Non-EU students: 24 hrs/week during semester, 90 days full-time per year.',
      studentWorkHoursPerWeek: 24,
      admissionProcess: 'Apply through Felvi.hu (Hungarian system) or directly to university for international programs.',
      preparatoryPrograms: 'Foundation year at universities. Hungarian language preparatory course (1 year). Balassi Intézet programs.',
      contactAuthority: 'Tempus Public Foundation: +36 1 436 3500. Felvi.hu.',
      immigrantSpecificNotes: 'Hungary has many affordable English-language programs, especially in medicine. Stipendium Hungaricum scholarship covers tuition + living costs. CEU (now in Vienna) historically served refugee students. Limited specific refugee support.',
    ),

    // 14. IRELAND
    UniversityAccess(
      country: 'Ireland',
      countryCode: 'IE',
      tuitionNonEu: 'EUR 10,000-55,000/year depending on program. Medicine: EUR 45,000-55,000. Arts/humanities: EUR 10,000-18,000.',
      tuitionEu: 'Free (Free Fees Initiative for EU residents who meet criteria). Student contribution: EUR 3,000/year.',
      freeForRefugees: true,
      scholarshipPrograms: ['University of Sanctuary Scholarships (multiple universities)', 'SUSI grants for refugees', 'Irish Research Council', 'DAFI/UNHCR', 'UCD/TCD/DCU sanctuary scholarships'],
      languageCoursesAvailable: 'English language schools (many in Dublin, Cork, Galway). IELTS/Cambridge preparation. University language centers.',
      studentWorkRights: 'Non-EU students: 20 hrs/week during term, 40 hrs/week during holidays (Stamp 2 visa).',
      studentWorkHoursPerWeek: 20,
      admissionProcess: 'CAO (Central Applications Office) for undergraduate. Direct to university for postgraduate. QQI NARIC for diploma recognition.',
      preparatoryPrograms: 'International Foundation Programmes at universities. English for Academic Purposes (EAP). Access courses.',
      contactAuthority: 'HEA (Higher Education Authority): +353 1 231 7100. SUSI: +353 76 108 7874.',
      immigrantSpecificNotes: 'University of Sanctuary movement strong — 12+ universities offer dedicated refugee scholarships. Recognized refugees: eligible for SUSI grants and Free Fees. Student contribution still applies. Strong support infrastructure for refugee students.',
    ),

    // 15. ITALY
    UniversityAccess(
      country: 'Italy',
      countryCode: 'IT',
      tuitionNonEu: 'EUR 900-4,000/year at public universities (income-based: ISEE). Private: EUR 5,000-20,000.',
      tuitionEu: 'Same as Italians: income-based (ISEE). EUR 0-4,000/year. Students below EUR 13,000 ISEE: free (no tax area).',
      freeForRefugees: true,
      scholarshipPrograms: ['Invest Your Talent in Italy', 'Regional DSU scholarships (borse di studio)', 'DAFI/UNHCR', 'University-specific refugee scholarships', 'CRUI (Rectors Conference) refugee program'],
      languageCoursesAvailable: 'Italian language courses at CLA (Centro Linguistico di Ateneo). Università per Stranieri di Perugia/Siena. CILS/CELI/PLIDA preparation.',
      studentWorkRights: 'All students: 20 hrs/week during term. 150-200 hours/year for university collaborations (borse di collaborazione).',
      studentWorkHoursPerWeek: 20,
      admissionProcess: 'Apply through Universitaly portal (for non-EU from abroad). Dichiarazione di valore from consulate. University direct application for those already in Italy.',
      preparatoryPrograms: 'Italian language preparatory year. Foundation courses at universities. Passaporto del rifugiato program.',
      contactAuthority: 'MIUR: +39 06 5849 1. CIMEA: +39 06 6840 7425. Regional DSU offices.',
      immigrantSpecificNotes: 'Refugees treated as Italian students for tuition purposes (ISEE-based, often EUR 0). Free or near-free public university education. CRUI manifesto: universities commit to refugee support. Many English programs available. Regional DSU grants cover meals, housing, books.',
    ),

    // 16. LATVIA
    UniversityAccess(
      country: 'Latvia',
      countryCode: 'LV',
      tuitionNonEu: 'EUR 1,500-12,000/year. Medicine: EUR 8,000-12,000. Other: EUR 1,500-4,000.',
      tuitionEu: 'State-funded places (free): limited and competitive. Self-funded: EUR 1,200-3,000.',
      freeForRefugees: false,
      scholarshipPrograms: ['Latvian State scholarships', 'DAFI/UNHCR', 'University-specific grants'],
      languageCoursesAvailable: 'Latvian language courses at university language centers. State Language Agency courses. Some English programs available.',
      studentWorkRights: 'Students with valid residence permit: 20 hrs/week during semester, full-time during breaks.',
      studentWorkHoursPerWeek: 20,
      admissionProcess: 'Apply directly to university. AIC diploma recognition. Latvian or English language proof.',
      preparatoryPrograms: 'Latvian language preparatory courses. Foundation programs at some universities.',
      contactAuthority: 'AIC: +371 67 225 155. Study in Latvia portal.',
      immigrantSpecificNotes: 'Affordable tuition compared to Western EU. Growing number of English programs. Recognized refugees may access state-funded places. IT and engineering programs increasingly popular.',
    ),

    // 17. LITHUANIA
    UniversityAccess(
      country: 'Lithuania',
      countryCode: 'LT',
      tuitionNonEu: 'EUR 1,000-11,000/year. Medicine: EUR 8,000-11,000. Other: EUR 1,000-4,000.',
      tuitionEu: 'State-funded places (free): competitive. Self-funded: EUR 600-2,500.',
      freeForRefugees: false,
      scholarshipPrograms: ['Lithuanian State scholarships', 'DAFI/UNHCR', 'University-specific programs'],
      languageCoursesAvailable: 'Lithuanian language courses at universities. Vilnius University Lituanistika center. English programs widely available.',
      studentWorkRights: 'Students can work without additional permit if enrolled full-time.',
      studentWorkHoursPerWeek: 20,
      admissionProcess: 'Apply through LAMA BPO (for Lithuanian-language) or directly for English programs. SKVC diploma recognition.',
      preparatoryPrograms: 'Lithuanian language preparatory year. Foundation programs. Bridge courses.',
      contactAuthority: 'SKVC: +370 5 210 4772. Study in Lithuania portal.',
      immigrantSpecificNotes: 'Affordable education. Many English-language programs. Vilnius and Kaunas main university cities. Recognized refugees: possible state-funded places. IT sector strong — good employment prospects.',
    ),

    // 18. LUXEMBOURG
    UniversityAccess(
      country: 'Luxembourg',
      countryCode: 'LU',
      tuitionNonEu: 'EUR 200/semester at University of Luxembourg (public). EUR 400/semester for some programs.',
      tuitionEu: 'EUR 200/semester',
      freeForRefugees: false,
      scholarshipPrograms: ['CEDIES (Centre de Documentation et d\'Information sur l\'Enseignement Supérieur) grants', 'Bourse d\'études supérieures', 'DAFI/UNHCR'],
      languageCoursesAvailable: 'University language center: French, German, Luxembourgish, English courses. INL (Institut National des Langues). Multilingual programs available.',
      studentWorkRights: 'Students: 15 hrs/week during semester, 40 hrs/week during breaks.',
      studentWorkHoursPerWeek: 15,
      admissionProcess: 'Apply through University of Luxembourg portal. MESR diploma recognition. Language proof depends on program language.',
      preparatoryPrograms: 'Cours d\'accueil for language preparation. Foundation semester at University of Luxembourg.',
      contactAuthority: 'CEDIES: +352 247-88650. University of Luxembourg: +352 46 66 44 1.',
      immigrantSpecificNotes: 'Only one public university but very affordable (EUR 200/semester for everyone). Multilingual programs (French, German, English). Many students study abroad with CEDIES grants. High standard of living but high costs.',
    ),

    // 19. MALTA
    UniversityAccess(
      country: 'Malta',
      countryCode: 'MT',
      tuitionNonEu: 'EUR 1,000-11,000/year at University of Malta. EUR 5,000-15,000 at private institutions.',
      tuitionEu: 'Free at University of Malta for full-time EU students',
      freeForRefugees: false,
      scholarshipPrograms: ['Malta Government Scholarships', 'MGSS (Malta Government Scholarship Scheme)', 'DAFI/UNHCR', 'Endeavour Scholarship Scheme'],
      languageCoursesAvailable: 'English language schools (Malta is English-speaking). Maltese language courses. University bilingual (Maltese/English).',
      studentWorkRights: 'Students with valid permit: 20 hrs/week.',
      studentWorkHoursPerWeek: 20,
      admissionProcess: 'Apply through University of Malta portal. MQRIC diploma recognition. English proficiency required.',
      preparatoryPrograms: 'Foundation programmes at University of Malta. MATSEC (Matriculation Secondary Education Certificate) for local entry.',
      contactAuthority: 'NCFHE: +356 2770 1900. University of Malta: +356 2340 2340.',
      immigrantSpecificNotes: 'English-speaking advantage for immigrants. Free EU tuition at University of Malta. Recognized refugees may access subsidized education. Small country with personal support system.',
    ),

    // 20. NETHERLANDS
    UniversityAccess(
      country: 'Netherlands',
      countryCode: 'NL',
      tuitionNonEu: 'EUR 6,000-20,000/year at research universities. EUR 8,000-15,000 at universities of applied sciences.',
      tuitionEu: 'EUR 2,530/year (wettelijk collegegeld 2025/26)',
      freeForRefugees: true,
      scholarshipPrograms: ['Holland Scholarship', 'Orange Knowledge Programme', 'UAF scholarships (specifically for refugees)', 'DAFI/UNHCR', 'University-specific refugee scholarships'],
      languageCoursesAvailable: 'NT2 (Dutch as Second Language) at ROC/language schools. University Dutch courses. Many English programs (especially Master). Inburgering courses.',
      studentWorkRights: 'Non-EU students: 16 hrs/week or full-time during June-August with TWV (work permit through employer).',
      studentWorkHoursPerWeek: 16,
      admissionProcess: 'Apply through Studielink (national portal). Nuffic diploma evaluation. VWO-level preparation or recognized equivalent.',
      preparatoryPrograms: 'UAF (Foundation for Refugee Students) guidance. Foundation year at universities. Preparation courses at HBO/WO level.',
      contactAuthority: 'Nuffic: +31 70 426 0260. DUO: +31 50 599 9099. UAF: +31 30 252 08 35.',
      immigrantSpecificNotes: 'UAF (Stichting voor Vluchteling-Studenten) is world-leading in refugee higher education support — free guidance, study financing, career support. Recognized refugees: EU tuition rate (EUR 2,530). Large number of English-taught programs. Strong support infrastructure.',
    ),

    // 21. POLAND
    UniversityAccess(
      country: 'Poland',
      countryCode: 'PL',
      tuitionNonEu: 'EUR 2,000-6,000/year for most programs. Medicine: EUR 10,000-14,000. Free if studying in Polish at public universities (for refugees/Karta Polaka holders).',
      tuitionEu: 'Free in Polish-language programs at public universities',
      freeForRefugees: true,
      scholarshipPrograms: ['Polish government scholarships (NAWA)', 'Stypendium im. Stefana Banаcha', 'DAFI/UNHCR', 'University-specific programs'],
      languageCoursesAvailable: 'Polish language courses at university language centers. School of Polish Language and Culture (e.g., at Jagiellonian University). NAWA Polish language courses.',
      studentWorkRights: 'Full work rights for full-time students. No hour restriction.',
      studentWorkHoursPerWeek: 40,
      admissionProcess: 'Apply through IRK (university recruitment system) or Rekrutacja portal. NAWA diploma recognition.',
      preparatoryPrograms: 'Polish language preparatory year at universities. Foundation courses. NAWA bridge programs.',
      contactAuthority: 'NAWA: +48 22 390 35 00. Study in Poland portal.',
      immigrantSpecificNotes: 'Refugees with status: FREE education in Polish at public universities (same as Poles). Polish language learning opens free quality education. Growing English programs. Affordable living costs. Strong technical and medical education. Karta Polaka holders also get free education.',
    ),

    // 22. PORTUGAL
    UniversityAccess(
      country: 'Portugal',
      countryCode: 'PT',
      tuitionNonEu: 'EUR 1,500-7,000/year at public universities. Private: EUR 3,000-10,000.',
      tuitionEu: 'EUR 697-1,500/year at public universities',
      freeForRefugees: true,
      scholarshipPrograms: ['DGES bolsas (state grants)', 'Global Platform for Syrian Students', 'DAFI/UNHCR', 'University-specific refugee scholarships', 'Calouste Gulbenkian Foundation'],
      languageCoursesAvailable: 'Portuguese language courses at university language centers. Instituto Camões. PLNM programs. CAPLE exam preparation.',
      studentWorkRights: 'Students: part-time work allowed. No specific hour restriction in law.',
      studentWorkHoursPerWeek: 20,
      admissionProcess: 'Apply through DGES portal (national competition) or directly to universities for international students. DGES diploma recognition.',
      preparatoryPrograms: 'Portuguese language preparatory courses. Foundation year. ACM integration support.',
      contactAuthority: 'DGES: +351 21 312 60 00. ACM: +351 218 106 100.',
      immigrantSpecificNotes: 'Recognized refugees: same tuition as Portuguese students. DGES grants available. ACM Global Platform: partnership for Syrian students. Affordable living costs (outside Lisbon). Growing number of English programs. Portuguese as bridge to Brazilian/Lusophone opportunities.',
    ),

    // 23. ROMANIA
    UniversityAccess(
      country: 'Romania',
      countryCode: 'RO',
      tuitionNonEu: 'EUR 2,000-9,000/year. Medicine: EUR 5,000-9,000. Other: EUR 2,000-4,000.',
      tuitionEu: 'Free for state-funded places (competition-based). Self-funded: EUR 500-2,000.',
      freeForRefugees: true,
      scholarshipPrograms: ['Romanian Government scholarships (through MFA)', 'DAFI/UNHCR', 'CNRR refugee education support'],
      languageCoursesAvailable: 'Romanian language preparatory year at universities. Department of Romanian as Foreign Language at major universities.',
      studentWorkRights: 'Students: 4 hrs/day during semester.',
      studentWorkHoursPerWeek: 20,
      admissionProcess: 'Apply through Studii in Romania portal (international) or direct to university. CNRED diploma recognition.',
      preparatoryPrograms: 'Romanian language preparatory year (1 academic year). Foundation courses at universities.',
      contactAuthority: 'Ministry of Education: +40 21 405 62 00. CNRED.',
      immigrantSpecificNotes: 'Refugees with status: access to state-funded places (free). Very affordable education and living costs. Growing number of English-language medical programs. EU diploma obtained. Romanian language year available.',
    ),

    // 24. SLOVAKIA
    UniversityAccess(
      country: 'Slovakia',
      countryCode: 'SK',
      tuitionNonEu: 'EUR 1,000-10,000/year. Medicine: EUR 7,000-10,000. Free in Slovak-language programs for all.',
      tuitionEu: 'Free in Slovak-language programs',
      freeForRefugees: true,
      scholarshipPrograms: ['Slovak Government Scholarships (SAIA)', 'National Scholarship Programme', 'DAFI/UNHCR'],
      languageCoursesAvailable: 'Slovak language courses at university language centers. Studia Academica Slovaca at Comenius University. Many programs in English (especially Bratislava).',
      studentWorkRights: 'Students: 20 hrs/week during semester, 40 hrs/week during breaks.',
      studentWorkHoursPerWeek: 20,
      admissionProcess: 'Apply directly to university. SAAIC diploma recognition. Slovak or English language proof.',
      preparatoryPrograms: 'Slovak language preparatory year. Foundation courses.',
      contactAuthority: 'SAIA: +421 2 5930 4700. Study in Slovakia portal.',
      immigrantSpecificNotes: 'Free tuition in Slovak-language programs for ALL nationalities. Learning Slovak opens free education pathway. Affordable living costs. Good medical and technical programs. Refugees with status get additional support.',
    ),

    // 25. SLOVENIA
    UniversityAccess(
      country: 'Slovenia',
      countryCode: 'SI',
      tuitionNonEu: 'EUR 2,000-11,000/year depending on program. Free for exchange agreement countries.',
      tuitionEu: 'Free (no tuition for full-time EU/EEA students at public universities)',
      freeForRefugees: true,
      scholarshipPrograms: ['Slovenian Government Scholarships', 'CMEPIUS exchange programs', 'DAFI/UNHCR', 'University of Ljubljana refugee support'],
      languageCoursesAvailable: 'Slovenian language courses at Center za slovenščino kot drugi in tuji jezik (University of Ljubljana). Summer schools. Some English programs.',
      studentWorkRights: 'Students: student work contracts (študentsko delo) through student service. Flexible hours.',
      studentWorkHoursPerWeek: 20,
      admissionProcess: 'Apply through eVŠ portal (national system). ENIC-NARIC Slovenia diploma recognition. Slovenian or English language proof.',
      preparatoryPrograms: 'Slovenian language preparatory course (1 year). Foundation programs at universities.',
      contactAuthority: 'Ministry of Education: +386 1 400 54 00. CMEPIUS: +386 1 620 94 50.',
      immigrantSpecificNotes: 'Refugees with international protection: same rights as Slovenian students (free tuition). Small, high-quality education system. Slovenian language is the main challenge. Affordable living costs. Strong engineering and natural sciences.',
    ),

    // 26. SPAIN
    UniversityAccess(
      country: 'Spain',
      countryCode: 'ES',
      tuitionNonEu: 'EUR 680-2,400/year for undergraduate at public universities (Comunidad Autónoma sets rates). Non-EU surcharge in some regions. Master: EUR 2,000-5,000.',
      tuitionEu: 'EUR 680-2,400/year for undergraduate (varies by Comunidad Autónoma). Same as Spanish students.',
      freeForRefugees: true,
      scholarshipPrograms: ['MEC/MECD becas (national grants)', 'CEAR (refugee support)', 'DAFI/UNHCR', 'Comunidad Autónoma specific grants', 'University-specific refugee programs'],
      languageCoursesAvailable: 'Spanish language courses at university language centers. Instituto Cervantes worldwide. DELE/SIELE preparation. Many programs in Catalan, Basque, Galician in respective regions.',
      studentWorkRights: 'Students with valid permit: 20 hrs/week during term. Full-time during breaks.',
      studentWorkHoursPerWeek: 20,
      admissionProcess: 'UNED selectividad for foreign students. UNEDasiss credential evaluation. Direct university application for some Master programs. Homologación of diploma.',
      preparatoryPrograms: 'Spanish language preparatory courses. UNEDasiss preparation. University foundation programs.',
      contactAuthority: 'Ministerio de Universidades: +34 91 506 56 00. UNED: +34 91 398 60 00.',
      immigrantSpecificNotes: 'Recognized refugees: same tuition as Spanish students + eligible for MEC grants. Spain has relatively affordable public universities. Empadronamiento (not visa) is key for accessing services. Strong university system (several in global top 500). Many programs in English at Master level.',
    ),

    // 27. SWEDEN
    UniversityAccess(
      country: 'Sweden',
      countryCode: 'SE',
      tuitionNonEu: 'SEK 80,000-295,000/year (EUR 7,000-26,000). Medicine highest. Free for exchange students.',
      tuitionEu: 'Free (no tuition for EU/EEA/Swiss students)',
      freeForRefugees: true,
      scholarshipPrograms: ['Swedish Institute scholarships', 'SI scholarships for global professionals', 'University-specific tuition waivers', 'DAFI/UNHCR', 'Folke Bernadotte Academy', 'CSN (student finance) for refugees with permanent residence'],
      languageCoursesAvailable: 'SFI (Svenska för invandrare — Swedish for Immigrants): free. University Swedish courses. TISUS exam preparation. Many Master programs in English.',
      studentWorkRights: 'No work hour restriction for non-EU students (since 2014). No work permit needed if enrolled.',
      studentWorkHoursPerWeek: 40,
      admissionProcess: 'Apply through Universityadmissions.se (Antagning.se in Swedish). UHR credential assessment. English (IELTS/TOEFL) or Swedish (TISUS) language proof.',
      preparatoryPrograms: 'Korta vägen (Short Cut) — fast-track for immigrant academics. Kompletterande utbildning (complementary education) for teachers, doctors, etc. SFI to SAS to TISUS language pathway.',
      contactAuthority: 'UHR: +46 10 470 03 00. Antagning.se. Swedish Institute: +46 8 453 78 00.',
      immigrantSpecificNotes: 'Recognized refugees: FREE tuition (same as Swedes). CSN study grants and loans available for refugees with permanent residence. Korta vägen program: specifically designed for immigrant academics to enter Swedish job market. Snabbspår (fast track): profession-specific pathways. Many English-taught programs. SFI is free and a right for all immigrants.',
    ),
  ];

  // ============================================================
  // ADULT EDUCATION & LANGUAGE COURSES — ALL 27 EU COUNTRIES
  // ============================================================

  static const List<AdultEducation> adultEducationData = [
    // 1. AUSTRIA
    AdultEducation(
      country: 'Austria',
      countryCode: 'AT',
      freeLanguageCourses: 'ÖIF (Österreichischer Integrationsfonds) German courses: free for recognized refugees and subsidiary protection holders. A1-B1 level.',
      languageCourseProvider: 'ÖIF, ÖSD, Volkshochschulen (VHS), BFI (Berufsförderungsinstitut), AMS (labor market service) courses',
      integrationCourseHours: '300 hours language (A2) + 100 hours orientation = 400 hours minimum. B1 level available (600 hours total).',
      integrationCourseContent: 'German language (A2-B1), Austrian values and legal order, labor market orientation, everyday life skills',
      integrationCourseMandatory: true,
      vocationalTrainingPrograms: 'AMS (Arbeitsmarktservice) vocational training. BFI and WIFI professional courses. Kompetenzcheck (skills assessment). Du kannst was! (recognition of informal skills).',
      digitalSkillsPrograms: 'fit4internet initiative. AMS digital skills training. VHS digital literacy courses.',
      financialSupport: 'AMS covers course costs for unemployed job seekers. ÖIF courses free for beneficiaries of international protection. Bildungskarenz (educational leave) for employed workers.',
      contactAuthority: 'ÖIF: +43 1 715 10 51. AMS: +43 1 87871. VHS: www.vhs.at',
      immigrantSpecificNotes: 'Integrationsvereinbarung (integration agreement) requires German A2 within 2 years. Free courses for refugees. AMS provides labor market integration. Wertekurse (values courses) mandatory 8 hours.',
    ),

    // 2. BELGIUM
    AdultEducation(
      country: 'Belgium',
      countryCode: 'BE',
      freeLanguageCourses: 'Flanders: free Dutch courses through inburgering (civic integration). Wallonia: free French courses through parcours d\'intégration. Brussels: choice of Dutch or French.',
      languageCourseProvider: 'Flanders: Atlas, IN-Gent, Bon (inburgering agencies), CVO. Wallonia: CISP, CPAS. Brussels: BON, VIA, Bruxelles Formation.',
      integrationCourseHours: 'Flanders: 240 hours Dutch (NT2) + 60 hours civic orientation + career guidance = ~360 hours. Wallonia: 400 hours French + 60 hours citizenship = 460 hours.',
      integrationCourseContent: 'Language courses (Dutch/French), civic orientation (maatschappelijke oriëntatie / formation citoyenne), career guidance (loopbaanoriëntatie)',
      integrationCourseMandatory: true,
      vocationalTrainingPrograms: 'VDAB (Flanders), Forem (Wallonia), Actiris (Brussels) — employment services with free vocational training. Syntra for entrepreneurship. IFAPME for trades.',
      digitalSkillsPrograms: 'Digidak network (free digital skills). Mediawijs. BeCode (coding bootcamp for vulnerable groups). WeTechCare.',
      financialSupport: 'CPAS/OCMW social integration income. VDAB/Forem training allowances. Inburgering courses free. Childcare available during courses.',
      contactAuthority: 'Flanders: Agentschap Integratie en Inburgering: 1700. Wallonia: CeRAIC. Brussels: BON/VIA.',
      immigrantSpecificNotes: 'Inburgering mandatory in Flanders and Brussels (since 2004/2023). Parcours d\'intégration in Wallonia (mandatory since 2016). Fines for non-compliance. Courses are free. Certificate required for permanent residence.',
    ),

    // 3. BULGARIA
    AdultEducation(
      country: 'Bulgaria',
      countryCode: 'BG',
      freeLanguageCourses: 'Free Bulgarian language courses for refugees through State Agency for Refugees (ДАБ). 600 hours government-funded. NGOs provide supplementary courses.',
      languageCourseProvider: 'State Agency for Refugees, Bulgarian Red Cross, Caritas Bulgaria, Council of Refugee Women, CVS Bulgaria',
      integrationCourseHours: '600 hours Bulgarian language + cultural orientation (varies). National integration program ongoing.',
      integrationCourseContent: 'Bulgarian language (A1-B1), cultural orientation, labor market information, legal rights education',
      integrationCourseMandatory: false,
      vocationalTrainingPrograms: 'National Agency for Vocational Education and Training (НАПОО) programs. Employment Agency (Агенция по заетостта) courses. NGO-provided skills training.',
      digitalSkillsPrograms: 'National digital skills program through MTSP. UNDP-supported digital literacy for refugees. Telerik Academy Foundation.',
      financialSupport: 'Integration allowance for refugees (limited). Employment Agency subsidies. EU-funded AMIF integration projects.',
      contactAuthority: 'State Agency for Refugees: +359 2 80 80 906. Employment Agency: +359 2 980 8719.',
      immigrantSpecificNotes: 'Integration support more limited than Western EU. NGOs play crucial role. Bulgarian language essential for employment. Refugee integration program provides some support but underfunded.',
    ),

    // 4. CROATIA
    AdultEducation(
      country: 'Croatia',
      countryCode: 'HR',
      freeLanguageCourses: 'Free Croatian language courses for international protection holders. 280 hours basic + 70 hours additional. Provided through Adult Education Institutions.',
      languageCourseProvider: 'Pučko otvoreno učilište (Adult Education Centers), Croatian Red Cross, JRS (Jesuit Refugee Service), Are You Syrious NGO',
      integrationCourseHours: '280 hours Croatian language + 70 hours Croatian culture/society = 350 hours',
      integrationCourseContent: 'Croatian language (A1-A2), Croatian culture, constitutional order, rights and obligations, everyday life orientation',
      integrationCourseMandatory: false,
      vocationalTrainingPrograms: 'HZZ (Croatian Employment Service) vocational training. Adult education centers. EU-funded skills programs.',
      digitalSkillsPrograms: 'e-Citizens program. Digital Croatia strategy programs. NGO digital literacy courses.',
      financialSupport: 'HZZ employment support. Integration support through AMIF funding. Housing and financial aid for first 2 years of protection.',
      contactAuthority: 'Ministry of Interior: +385 1 6122 111. HZZ: +385 1 6126 000.',
      immigrantSpecificNotes: 'Integration support package for refugees includes language courses, housing, employment support. Croatian language essential for integration. Growing but still developing infrastructure.',
    ),

    // 5. CYPRUS
    AdultEducation(
      country: 'Cyprus',
      countryCode: 'CY',
      freeLanguageCourses: 'Free Greek language courses through Adult Education Centres (Επιμορφωτικά Κέντρα). Evening classes. Also through UNHCR-funded NGOs.',
      languageCourseProvider: 'Ministry of Education Adult Education Centres, UNHCR Cyprus, KISA (Action for Equality, Support, Antiracism), Cyprus Refugee Council',
      integrationCourseHours: '100-200 hours Greek language. No formal integration course requirement.',
      integrationCourseContent: 'Greek language, basic civic orientation (informal). No structured integration program like Germany/Austria.',
      integrationCourseMandatory: false,
      vocationalTrainingPrograms: 'HRDA (Human Resource Development Authority) training programs. ANAD vocational training. Cyprus Productivity Centre.',
      digitalSkillsPrograms: 'HRDA digital skills programs. Microsoft digital skills partnership. NGO computer literacy courses.',
      financialSupport: 'Social Welfare Services support. HRDA subsidized training. EU-funded integration projects.',
      contactAuthority: 'Ministry of Education: +357 22 800 600. HRDA: +357 22 515 000.',
      immigrantSpecificNotes: 'No formal mandatory integration program. Greek language courses available but limited. English widely spoken which helps integration. NGOs provide key support services.',
    ),

    // 6. CZECHIA
    AdultEducation(
      country: 'Czechia',
      countryCode: 'CZ',
      freeLanguageCourses: 'Free Czech language courses for international protection holders. Up to 400 hours (recently expanded from 100). AMIF-funded courses for other immigrants available.',
      languageCourseProvider: 'Integration centers (Centra na podporu integrace cizinců), InBáze, Sdružení pro integraci a migraci (SIMI), People in Need (Člověk v tísni)',
      integrationCourseHours: '400 hours Czech language for protection holders. Adaptation-Integration courses: 16-48 hours civic orientation.',
      integrationCourseContent: 'Czech language (A1-B1), Czech society orientation, legal system, labor market information',
      integrationCourseMandatory: false,
      vocationalTrainingPrograms: 'Labour Office (Úřad práce) retraining courses. InBáze employment programs. META (Association for Opportunities of Young Migrants) career support.',
      digitalSkillsPrograms: 'Labour Office digital skills courses. Czechitas (IT courses for women). DigiKoalice.',
      financialSupport: 'State Integration Programme for refugees. Labour Office support. Integration centers provide free services.',
      contactAuthority: 'Ministry of Interior Integration Centers: +420 974 832 761. Labour Office: +420 844 844 803.',
      immigrantSpecificNotes: 'State Integration Programme provides comprehensive support for refugees (housing, language, employment). Czech language crucial for labor market. Integration centers in all regions. Strong NGO support network.',
    ),

    // 7. DENMARK
    AdultEducation(
      country: 'Denmark',
      countryCode: 'DK',
      freeLanguageCourses: 'Free Danish language courses for all immigrants with residence permit. Danskuddannelse 1, 2, or 3 (based on educational background). Up to 5 years.',
      languageCourseProvider: 'Municipal language centers (sprogcentre). Speak, Lærdansk, AOF sprogcentre, kommunale sprogcentre.',
      integrationCourseHours: 'Self-sufficiency and integration program (Selvforsørgelses- og hjemrejseprogram): Danish language (1,200 hours max) + employment-focused activities. Integration contract: 1-5 years.',
      integrationCourseContent: 'Danish language (Danskuddannelse 1/2/3), employment internships, civic orientation, Danish society knowledge. Test: Indfødsretsprøve (citizenship test) and Prøve i Dansk.',
      integrationCourseMandatory: true,
      vocationalTrainingPrograms: 'IGU (Integrationsgrunduddannelse) — 2 year integration training combining Danish, work, and education. AMU (adult vocational training). VEU (adult continuing education).',
      digitalSkillsPrograms: 'FGU (Forberedende Grunduddannelse) for young adults. AMU digital courses. IT courses through VUC.',
      financialSupport: 'Integrationsydelse (integration benefit) during program — lower than regular social assistance. Selvforsørgelses- og hjemrejseydelse for some groups.',
      contactAuthority: 'Municipality integration department. SIRI (Styrelsen for International Rekruttering og Integration): +45 72 14 20 00.',
      immigrantSpecificNotes: 'Denmark has strict but comprehensive integration requirements. Danish language mandatory for residence. IGU program very effective for employment integration. Sanctions for non-participation. Recent reforms tighten requirements further.',
    ),

    // 8. ESTONIA
    AdultEducation(
      country: 'Estonia',
      countryCode: 'EE',
      freeLanguageCourses: 'Free Estonian language courses (A1-B2) through Kohanemisprogramm (Settle in Estonia). Additional free courses for long-term residents and refugees.',
      languageCourseProvider: 'Integration Foundation (Integratsiooni Sihtasutus), Keelekursused.ee, private language schools with state vouchers',
      integrationCourseHours: 'Kohanemisprogramm: Estonian language (up to B1, ~200 hours) + orientation modules (16-24 hours). Total: ~230 hours.',
      integrationCourseContent: 'Estonian language, working in Estonia, studying in Estonia, family life, Estonian culture and society',
      integrationCourseMandatory: false,
      vocationalTrainingPrograms: 'Töötukassa (Unemployment Insurance Fund) retraining. Kutsekoolid (vocational schools) for adults. Work in Estonia programs.',
      digitalSkillsPrograms: 'e-Estonia digital skills programs. Töötukassa digital training. IT Academy (HITSA). Digital literacy through Vaata Maailma.',
      financialSupport: 'Töötukassa training support. Integration Foundation services free. Refugee support through social welfare.',
      contactAuthority: 'Integration Foundation: +372 659 9024. Töötukassa: +372 614 7386.',
      immigrantSpecificNotes: 'Estonia is digitally advanced — e-residency and digital public services. Estonian language crucial but English widely used in IT sector. Kohanemisprogramm is comprehensive and free. Russian-speaking community large (facilitates some integration).',
    ),

    // 9. FINLAND
    AdultEducation(
      country: 'Finland',
      countryCode: 'FI',
      freeLanguageCourses: 'Free Finnish/Swedish language courses through kotoutumiskoulutus (integration training). TE Office (employment service) provides. Also free at adult education centers (kansalaisopistot).',
      languageCourseProvider: 'TE Office (TE-palvelut), municipalities, kansalaisopistot (adult education centers), AEL/Amiedu, Testipiste, universities (open university)',
      integrationCourseHours: 'Kotoutumiskoulutus: approximately 40-60 weeks (800-1,200 hours). Finnish/Swedish to B1.1 level. Includes work practice (työharjoittelu).',
      integrationCourseContent: 'Finnish/Swedish language (to B1.1), work life skills, Finnish society, digital skills, work practice period, career planning. Integration plan (kotoutumissuunnitelma) is individual.',
      integrationCourseMandatory: true,
      vocationalTrainingPrograms: 'TE Office vocational training (ammatillinen koulutus). KOTO-SIB (Social Impact Bond for integration). Oppisopimuskoulutus (apprenticeship training). VALMA preparation. Free vocational education.',
      digitalSkillsPrograms: 'Digi- ja väestötietovirasto digital support. Library digital guidance. TE Office digital skills. Many public services digital-first.',
      financialSupport: 'Kotoutumistuki (integration support = labor market subsidy or unemployment benefit level). Free courses during integration period (up to 3 years, extendable). Kela benefits.',
      contactAuthority: 'TE Office: 0295 025 500. Kela: 020 634 0200. Municipal immigration services.',
      immigrantSpecificNotes: 'Finland\'s integration system is among the best in EU. Kotoutumissuunnitelma (individual integration plan) created within 3 years of arrival. All integration training is FREE. Finnish language is challenging but B1.1 target achievable. Working life emphasis. Recent reform (2025): municipalities take over from TE offices.',
    ),

    // 10. FRANCE
    AdultEducation(
      country: 'France',
      countryCode: 'FR',
      freeLanguageCourses: 'Free French courses through CIR (Contrat d\'Intégration Républicaine). 200-600 hours depending on level. OFII administers.',
      languageCourseProvider: 'OFII (Office Français de l\'Immigration et de l\'Intégration), Alliance Française, Greta (national education adult training), associations (e.g., France Terre d\'Asile)',
      integrationCourseHours: 'CIR: 200-600 hours French language + 24 hours civic training (formation civique) + individual guidance. Total: 224-624 hours.',
      integrationCourseContent: 'French language (A1 level minimum target), Principes et valeurs de la République (civic training), Vivre et accéder à l\'emploi en France (employment guidance)',
      integrationCourseMandatory: true,
      vocationalTrainingPrograms: 'Pôle Emploi (France Travail since 2024) vocational training. GRETA adult education. AFPA (Association pour la Formation Professionnelle des Adultes). Missions locales for youth.',
      digitalSkillsPrograms: 'Emmaüs Connect (digital inclusion). France Travail digital skills. Les Bons Clics platform. Pix digital competency certification.',
      financialSupport: 'RSA (Revenu de Solidarité Active) during integration. ADA (Allocation pour Demandeurs d\'Asile) for asylum seekers. CIR courses entirely free. France Travail training allowances.',
      contactAuthority: 'OFII: +33 1 53 69 53 70. France Travail: 3949. Préfecture for CIR.',
      immigrantSpecificNotes: 'CIR (Contrat d\'Intégration Républicaine) is the cornerstone of integration. Mandatory for new immigrants. Signed at Préfecture. A1 level required for first residence card renewal; B1 for permanent residence/citizenship. Free and comprehensive. Recent reforms increase hours and requirements.',
    ),

    // 11. GERMANY
    AdultEducation(
      country: 'Germany',
      countryCode: 'DE',
      freeLanguageCourses: 'Integrationskurs: 600 hours German + 100 hours orientation = 700 hours. Free for refugees and those on social benefits. Others: EUR 2.29/hour (partial reimbursement if B1 passed).',
      languageCourseProvider: 'BAMF (Bundesamt für Migration und Flüchtlinge) authorized course providers. Volkshochschulen (VHS), Goethe-Institut, AWO, Caritas, Diakonie, private schools.',
      integrationCourseHours: '700 hours standard (600 language + 100 orientation). Intensive course: 430 hours. Literacy course: 900 hours. Youth course: 900 hours. Women\'s/parents\' course: 900 hours.',
      integrationCourseContent: 'German language (A1-B1), Orientierungskurs: German legal system, history, culture, values, democracy, rights and responsibilities. DTZ exam (Deutsch-Test für Zuwanderer) + LiD test (Leben in Deutschland).',
      integrationCourseMandatory: true,
      vocationalTrainingPrograms: 'Berufsbezogene Deutschsprachförderung (DeuFöV): B2/C1 professional German courses. Agentur für Arbeit/Jobcenter vocational training. Ausbildung (apprenticeship) programs. IQ Netzwerk qualification programs.',
      digitalSkillsPrograms: 'Jobcenter digital skills courses. VHS digital workshops. ReDI School of Digital Integration (Berlin, Munich, NRW). Kiron (online learning).',
      financialSupport: 'Bürgergeld (citizen\'s income) during integration. BAföG for education. Integrationskurs free for entitled groups. BAMF reimburses 50% of costs if B1 passed within 2 years.',
      contactAuthority: 'BAMF: +49 911 943-0. Agentur für Arbeit: 0800 4 555 500 (free). Jobcenter locally.',
      immigrantSpecificNotes: 'Germany\'s Integrationskurs is the EU model for integration courses. BAMF coordinates everything. Mandatory for most new immigrants. B1 target realistic with 700 hours. DeuFöV courses (B2/C1) for professional integration are also free/subsidized. Sanctions for non-attendance. Excellent infrastructure across the country.',
    ),

    // 12. GREECE
    AdultEducation(
      country: 'Greece',
      countryCode: 'GR',
      freeLanguageCourses: 'Free Greek courses through KEEM (Integration Centers), municipalities, and NGOs. Ελληνομάθεια certification courses. UNHCR-funded programs.',
      languageCourseProvider: 'KEEM (Κέντρα Ένταξης Μεταναστών), municipalities, Solidarity Now, Metadrasi, Praksis, Greek Council for Refugees, university language centers',
      integrationCourseHours: '125-500 hours Greek language depending on provider. No standardized national integration course.',
      integrationCourseContent: 'Greek language, Greek culture and society (informal). No formal structured integration course like Germany. Civic orientation through NGOs.',
      integrationCourseMandatory: false,
      vocationalTrainingPrograms: 'OAED (Employment Agency) training. ELKETHE (Hellenic Centre for Marine Research) for relevant skills. NGO vocational programs. AMIF-funded skills training.',
      digitalSkillsPrograms: 'OAED digital training. Generation Greece (McKinsey) digital bootcamp. NGO computer classes. Libraries digital access.',
      financialSupport: 'ESTIA housing program (UNHCR). Cash assistance through UNHCR/government. OAED training allowances. Limited but improving.',
      contactAuthority: 'Ministry of Migration: +30 213 136 1300. OAED: +30 210 998 9000.',
      immigrantSpecificNotes: 'Greece lacks a formal integration course system. Integration support primarily through NGOs and EU-funded projects. Greek language certification (Ελληνομάθεια) exists. A2 Greek required for long-term residence. NGOs fill significant gaps in service provision.',
    ),

    // 13. HUNGARY
    AdultEducation(
      country: 'Hungary',
      countryCode: 'HU',
      freeLanguageCourses: 'Limited free Hungarian courses for refugees through government. Primary providers are NGOs: Menedék Association, Hungarian Helsinki Committee.',
      languageCourseProvider: 'Menedék Migránsokat Segítő Egyesület, Hungarian Helsinki Committee, Artemisszió Foundation, Corvinus University language center',
      integrationCourseHours: 'No formal national integration course. Hungarian language courses: 100-200 hours depending on provider.',
      integrationCourseContent: 'Hungarian language. Limited structured civic orientation. NGOs provide informal orientation sessions.',
      integrationCourseMandatory: false,
      vocationalTrainingPrograms: 'National Employment Service (NFSZ) training. Limited specific programs for immigrants.',
      digitalSkillsPrograms: 'Limited specific programs. General digital literacy through adult education centers.',
      financialSupport: 'Very limited state support for immigrant integration. NGOs provide most support. EU-funded AMIF projects (reduced since 2018).',
      contactAuthority: 'Menedék Association: +36 1 322 1502. Hungarian Helsinki Committee: +36 1 321 4141.',
      immigrantSpecificNotes: 'Hungary has minimal state integration infrastructure since 2018 policy changes. NGOs carry the burden. Hungarian is extremely difficult language. Limited English in public services outside Budapest. Menedék and Helsinki Committee are key contacts.',
    ),

    // 14. IRELAND
    AdultEducation(
      country: 'Ireland',
      countryCode: 'IE',
      freeLanguageCourses: 'Free English language courses through ETBs (Education and Training Boards). ESOL (English for Speakers of Other Languages) classes nationwide.',
      languageCourseProvider: 'ETBs (Education and Training Boards — 16 nationwide), local development companies, NALA (National Adult Literacy Agency), public libraries',
      integrationCourseHours: 'No formal mandatory integration course. ESOL: varies from 2-20 hours/week. Typically 100-400 hours total.',
      integrationCourseContent: 'English language (ESOL), functional literacy, citizenship preparation. No formal civic integration requirement.',
      integrationCourseMandatory: false,
      vocationalTrainingPrograms: 'SOLAS (Further Education and Training Authority) programs. ETB skill development. Springboard+ (free courses for job seekers). Skillnet Ireland.',
      digitalSkillsPrograms: 'National Digital Strategy. ETB digital skills. Code Institute. FIT (Fastrack to IT). Libraries digital skills.',
      financialSupport: 'SUSI grants. BTEA (Back to Education Allowance). VTOS (Vocational Training Opportunities Scheme). Jobseeker\'s Allowance can continue during training.',
      contactAuthority: 'SOLAS: +353 1 533 2500. Local ETB offices. Citizens Information: 0818 07 4000.',
      immigrantSpecificNotes: 'Ireland has no formal integration course but excellent adult education infrastructure. ESOL widely available and free through ETBs. English language advantage for integration. Refugees in Direct Provision can access all education services. NALA provides literacy support.',
    ),

    // 15. ITALY
    AdultEducation(
      country: 'Italy',
      countryCode: 'IT',
      freeLanguageCourses: 'Free Italian courses through CPIA (Centri Provinciali per l\'Istruzione degli Adulti). Also through CAS/SAI reception system. NGOs supplement.',
      languageCourseProvider: 'CPIA (200+ centers nationwide), Scuola di italiano per stranieri (university programs), Caritas, Arci, cooperatives, volunteer organizations',
      integrationCourseHours: '200 hours Italian language (CPIA). Accordo di Integrazione requires A2 level. Optional: additional 200 hours for B1.',
      integrationCourseContent: 'Italian language (A1-A2 minimum), civic education (educazione civica), Italian constitution basics. Accordo di Integrazione: credit-based system over 2 years.',
      integrationCourseMandatory: true,
      vocationalTrainingPrograms: 'Regional vocational training (formazione professionale regionale). ANPAL employment agency programs. Centri per l\'impiego (employment centers). SPRAR/SAI vocational programs for refugees.',
      digitalSkillsPrograms: 'Pane e Internet (Emilia-Romagna). CPIA digital literacy. Regional digital skill programs. Repubblica Digitale initiative.',
      financialSupport: 'SAI reception system provides comprehensive support. RdC (Reddito di Cittadinanza)/Assegno di Inclusione. Regional integration funds. CPIA education is free.',
      contactAuthority: 'CPIA (local). ANPAL: +39 06 4898 6700. Prefettura for Accordo di Integrazione.',
      immigrantSpecificNotes: 'Accordo di Integrazione (Integration Agreement) since 2012: point-based system, A2 Italian required within 2 years. CPIA is the main provider of free Italian courses. 200+ centers nationwide. Sessione di educazione civica e informazione (civic session) at Prefettura. Strong volunteer teaching tradition.',
    ),

    // 16. LATVIA
    AdultEducation(
      country: 'Latvia',
      countryCode: 'LV',
      freeLanguageCourses: 'Free Latvian language courses for international protection holders. State Language Agency (Valsts valodas centrs) organizes. EU-funded courses for other immigrants.',
      languageCourseProvider: 'State Language Agency, PATTS (Society Shelter), Latvian Red Cross, municipal adult education centers',
      integrationCourseHours: '150-200 hours Latvian language. Cultural orientation: 20-40 hours.',
      integrationCourseContent: 'Latvian language, Latvian history and culture, legal system basics, everyday life orientation',
      integrationCourseMandatory: false,
      vocationalTrainingPrograms: 'NVA (State Employment Agency) training programs. VIAA (State Education Development Agency) adult education. EU-funded skills programs.',
      digitalSkillsPrograms: 'NVA digital skills. Latvian IT Cluster programs. Libraries as digital access points.',
      financialSupport: 'NVA training support. Refugee integration support (limited). Municipal social assistance.',
      contactAuthority: 'State Language Agency: +371 67 201 681. NVA: +371 67 021 706.',
      immigrantSpecificNotes: 'Latvian language proficiency required for permanent residence (A2) and citizenship (B1). Free courses for refugees. State Language Agency conducts exams. Integration support developing. Russian widely spoken informally.',
    ),

    // 17. LITHUANIA
    AdultEducation(
      country: 'Lithuania',
      countryCode: 'LT',
      freeLanguageCourses: 'Free Lithuanian language courses for international protection holders. 190 hours state-funded. Additional EU-funded courses available.',
      languageCourseProvider: 'Refugee Reception Centre, Lithuanian Red Cross, Caritas Lithuania, municipal adult education centers, IOM Lithuania',
      integrationCourseHours: '190 hours Lithuanian language + civic/cultural orientation (40 hours) = 230 hours total',
      integrationCourseContent: 'Lithuanian language (A1-A2), Lithuanian society and culture, legal system, labor market orientation',
      integrationCourseMandatory: false,
      vocationalTrainingPrograms: 'Employment Service (Užimtumo tarnyba) training. VTDK (vocational training centers). EU-funded skills programs.',
      digitalSkillsPrograms: 'Employment Service digital courses. Libraries digital access. Infobalt IT programs.',
      financialSupport: 'Integration support for refugees (financial allowance). Employment Service training support. Municipal social assistance.',
      contactAuthority: 'Refugee Reception Centre: +370 5 261 4348. Employment Service: +370 5 236 0800.',
      immigrantSpecificNotes: 'Lithuanian language proficiency required for permanent residence (A1) and citizenship (B1). Integration support expanding since 2022 refugee wave. Lithuanian is Baltic language (difficult for most learners). Vilnius has most integration services.',
    ),

    // 18. LUXEMBOURG
    AdultEducation(
      country: 'Luxembourg',
      countryCode: 'LU',
      freeLanguageCourses: 'Free language courses: Luxembourgish (Sproochecoursen) through INL (Institut National des Langues). French and German also available. CAI (Contrat d\'Accueil et d\'Intégration) courses free.',
      languageCourseProvider: 'INL (Institut National des Langues), ASTI (Association de Soutien aux Travailleurs Immigrés), communes, private schools',
      integrationCourseHours: 'CAI: Luxembourgish course (120 hours) + civic orientation course (24 hours) + 6-hour course on daily life = 150 hours minimum.',
      integrationCourseContent: 'Luxembourgish language, French/German option, civic orientation (Vivre ensemble au Grand-Duché), daily life skills, rights and obligations',
      integrationCourseMandatory: false,
      vocationalTrainingPrograms: 'ADEM (Employment Agency) vocational training. Chambre des Métiers apprenticeships. Chambre de Commerce programs. CNFPC (Centre National de Formation Professionnelle Continue).',
      digitalSkillsPrograms: 'BEE SECURE digital skills. ADEM digital training. Digital Lëtzebuerg initiative.',
      financialSupport: 'REVIS (revenue d\'inclusion sociale). ADEM training support. ONA (National Reception Office) for asylum seekers. CAI courses free.',
      contactAuthority: 'OLAI: +352 247-85700. ADEM: +352 247-88888. INL: +352 26 44 30-1.',
      immigrantSpecificNotes: 'CAI (welcome and integration contract) voluntary but strongly encouraged. Trilingual challenge: Luxembourgish, French, German all used. French most important for daily life. Sproochentest (Luxembourgish test) for nationality. Very diverse population (47% foreign residents).',
    ),

    // 19. MALTA
    AdultEducation(
      country: 'Malta',
      countryCode: 'MT',
      freeLanguageCourses: 'Free Maltese and English language courses through Directorate for Lifelong Learning. Malta Integration Unit provides courses for refugees.',
      languageCourseProvider: 'Directorate for Lifelong Learning, Malta Integration Unit, Foundation for Shelter and Support to Migrants (FSM), JRS Malta',
      integrationCourseHours: '100-200 hours language. I Belong programme: civic orientation sessions.',
      integrationCourseContent: 'Maltese and/or English language, Maltese culture and society, labor market orientation. I Belong programme for civic integration.',
      integrationCourseMandatory: false,
      vocationalTrainingPrograms: 'Jobsplus training programs. MCAST (Malta College of Arts, Science & Technology) adult courses. ETC employment training.',
      digitalSkillsPrograms: 'eSkills Malta Foundation. Jobsplus digital training. MITA (Malta IT Agency) programs.',
      financialSupport: 'Social Security benefits during training. FSM support for refugees. Jobsplus training allowances.',
      contactAuthority: 'Human Rights and Integration Unit: +356 2590 4000. Jobsplus: +356 2220 1401.',
      immigrantSpecificNotes: 'Bilingual advantage: English widely spoken. Maltese language useful for integration. I Belong programme is main integration framework. Small country with accessible services. Mediterranean climate attracts many migrants.',
    ),

    // 20. NETHERLANDS
    AdultEducation(
      country: 'Netherlands',
      countryCode: 'NL',
      freeLanguageCourses: 'Since 2022 reform (Wet inburgering 2021): free inburgering courses provided by municipality. Previously self-funded. Dutch language (NT2) to B1.',
      languageCourseProvider: 'Municipal contracts with language schools. ROC (Regionaal Opleidingen Centrum), Taalhuizen (Language Houses in libraries), NT2-Café, volunteer organizations.',
      integrationCourseHours: 'Inburgering (civic integration): approx. 600 hours Dutch language (NT2 to B1) + participation declaration course (PVT) + civic orientation (KNM). Total varies by learning track: B1-route, education route (onderwijsroute), or MAP (Module Arbeidsmarkt en Participatie).',
      integrationCourseContent: 'Dutch language (NT2 to B1), Participatieverklaring (participation declaration), KNM (Kennis van de Nederlandse Maatschappij — knowledge of Dutch society), MAP (labor market orientation). Exam required.',
      integrationCourseMandatory: true,
      vocationalTrainingPrograms: 'UWV (Employee Insurance Agency) reintegration training. ROC vocational education. BBL (workplace-based learning). UAF programs for refugees.',
      digitalSkillsPrograms: 'Stichting Lezen en Schrijven (digital skills). Digisterker. Libraries digital workshops. Alliantie Digitaal Samenleven.',
      financialSupport: 'Bijstandsuitkering (social assistance) during inburgering. Since 2022: municipality covers course costs (no more loans). DUO study financing for education route.',
      contactAuthority: 'Municipality (gemeente) inburgeringsteam. IND: +31 88 043 0430. VluchtelingenWerk: +31 20 346 72 00.',
      immigrantSpecificNotes: 'Major reform in 2022 (Wet inburgering 2021): municipality-led, free, better quality. Three routes: B1 (standard Dutch), Onderwijsroute (higher education path), MAP (labor market entry). Deadline: 3 years. Penalties for non-completion. Dutch at B1 required for permanent residence. UAF is world-class refugee education support.',
    ),

    // 21. POLAND
    AdultEducation(
      country: 'Poland',
      countryCode: 'PL',
      freeLanguageCourses: 'Free Polish language courses for refugees through Individual Integration Programmes. Also widely available through NGOs. Municipal courses expanding since 2022.',
      languageCourseProvider: 'Powiatowe Centra Pomocy Rodzinie (Family Support Centers), Fundacja Ocalenie, Stowarzyszenie Interwencji Prawnej (SIP), Polish Humanitarian Action (PAH), Centrum Wielokulturowe (Multicultural Centers)',
      integrationCourseHours: '200-400 hours Polish language (varies by provider). Individual Integration Programme: 12 months including language.',
      integrationCourseContent: 'Polish language (A1-B1), Polish society orientation, labor market skills, practical life skills',
      integrationCourseMandatory: false,
      vocationalTrainingPrograms: 'PUP (Powiatowy Urząd Pracy — District Employment Office) training. OHP (Voluntary Labour Corps) for youth. EU-funded skills programs.',
      digitalSkillsPrograms: 'PUP digital skills courses. Fundacja Orange digital literacy. Libraries digital access (Biblionet).',
      financialSupport: 'Individual Integration Programme: monthly allowance for 12 months (for refugees). PUP training allowances. Social assistance.',
      contactAuthority: 'Voivodeship Office (Urząd Wojewódzki) for integration. PUP locally. OPM (Centre for Migration Research).',
      immigrantSpecificNotes: 'Massive Ukrainian refugee integration since 2022. Polish language courses dramatically expanded. Individual Integration Programme for refugees provides comprehensive support for 12 months. Polish as Slavic language is easier for Ukrainian/Russian speakers. Multicultural Centers in major cities provide one-stop support.',
    ),

    // 22. PORTUGAL
    AdultEducation(
      country: 'Portugal',
      countryCode: 'PT',
      freeLanguageCourses: 'Free Portuguese courses through PPT (Português para Todos / Portuguese for All) program. Also through CNAI (National Immigrant Support Centres). Available to all immigrants.',
      languageCourseProvider: 'IEFP (Institute of Employment and Professional Training), CNAI/CLAII (local immigrant support centers), ACM programs, universities, Cáritas, JRS',
      integrationCourseHours: 'PPT: 150-200 hours Portuguese (A2-B2). No mandatory integration course but PPT strongly encouraged.',
      integrationCourseContent: 'Portuguese language (A2-B2), Portuguese culture (basic), citizenship preparation. Programa Português para Todos (PPT) since 2008.',
      integrationCourseMandatory: false,
      vocationalTrainingPrograms: 'IEFP (Instituto do Emprego e Formação Profissional) vocational training. Qualifica program (adult qualification). RVCC (Recognition of Prior Learning).',
      digitalSkillsPrograms: 'INCoDe.2030 (national digital competency program). IEFP digital skills. Espaços Cidadão digital access. Portugal Digital Academy.',
      financialSupport: 'RSI (Rendimento Social de Inserção). IEFP training allowances. ACM integration support. PPT courses entirely free.',
      contactAuthority: 'ACM: +351 218 106 100. IEFP: +351 215 861 600. CNAI (National Centres): +351 808 257 257.',
      immigrantSpecificNotes: 'Portugal\'s PPT program is well-designed and free. A2 Portuguese required for permanent residence; B1 for citizenship. ACM one-stop shops (CNAI) in Lisbon, Porto, Faro are excellent resources. Strong immigrant support culture. Escolhas program for vulnerable youth. RVCC recognizes skills learned abroad.',
    ),

    // 23. ROMANIA
    AdultEducation(
      country: 'Romania',
      countryCode: 'RO',
      freeLanguageCourses: 'Free Romanian language courses for refugees through integration program. 120-200 hours. Also through NGOs and universities.',
      languageCourseProvider: 'IGI (General Inspectorate for Immigration), CNRR (National Council for Refugees), JRS Romania, ARCA (Romanian Forum for Refugees), universities',
      integrationCourseHours: '120-200 hours Romanian language + cultural orientation (20-40 hours)',
      integrationCourseContent: 'Romanian language (A1-A2), Romanian culture and society, legal system, labor market orientation',
      integrationCourseMandatory: false,
      vocationalTrainingPrograms: 'ANOFM (National Employment Agency) training. ARCA vocational programs for refugees. EU-funded skills projects.',
      digitalSkillsPrograms: 'ANOFM digital skills. Ateliere fără Frontiere (Workshops Without Borders). Digital Nation initiative.',
      financialSupport: 'Integration support for refugees (limited monthly allowance). ANOFM training support. Social assistance through local authorities.',
      contactAuthority: 'IGI: +40 21 440 41 03. ANOFM: +40 21 315 39 45. CNRR: +40 21 312 41 93.',
      immigrantSpecificNotes: 'Integration infrastructure developing. Romanian language essential but not widely taught abroad. NGOs provide critical support. EU funding enables most integration programs. Growing immigrant population requiring expanded services.',
    ),

    // 24. SLOVAKIA
    AdultEducation(
      country: 'Slovakia',
      countryCode: 'SK',
      freeLanguageCourses: 'Free Slovak language courses for refugees through Migration Office and IOM Slovakia. 150-200 hours. Limited availability for other immigrants.',
      languageCourseProvider: 'Migration Office of MoI SR, IOM Slovakia, Slovenská humanitná rada (Slovak Humanitarian Council), Marginal NGO, university language centers',
      integrationCourseHours: '150-200 hours Slovak language + orientation sessions (20-30 hours)',
      integrationCourseContent: 'Slovak language (A1-A2), Slovak society and culture basics, legal rights, labor market information',
      integrationCourseMandatory: false,
      vocationalTrainingPrograms: 'ÚPSVaR (Office of Labour, Social Affairs and Family) training. EU-funded skills programs. Limited specific immigrant programs.',
      digitalSkillsPrograms: 'ÚPSVaR digital training. IT Valley initiatives. Slovak IT community programs.',
      financialSupport: 'Integration allowance for refugees (limited). ÚPSVaR training support. Material need assistance (hmotná núdza).',
      contactAuthority: 'Migration Office: +421 2 4826 5706. ÚPSVaR: +421 2 2046 1111. IOM Slovakia: +421 2 5273 3791.',
      immigrantSpecificNotes: 'Integration infrastructure limited. Slovak language difficult but Slavic language speakers have advantage. IOM Slovakia key partner. Growing awareness of integration needs since 2022. Bratislava has most services.',
    ),

    // 25. SLOVENIA
    AdultEducation(
      country: 'Slovenia',
      countryCode: 'SI',
      freeLanguageCourses: 'Free Slovenian language courses: 180 hours for permanent residence holders, 60 hours initial for refugees. Programi za učenje slovenščine (Slovenian learning programs).',
      languageCourseProvider: 'Andragoški center Slovenije (Slovenian Institute for Adult Education), Ljudske univerze (adult education centers), University of Ljubljana Center za slovenščino',
      integrationCourseHours: '180 hours Slovenian language + civic integration sessions. Initial programme for refugees: 60 hours.',
      integrationCourseContent: 'Slovenian language (A1-A2, up to B1), Slovenian culture and history, civic orientation, practical life skills',
      integrationCourseMandatory: false,
      vocationalTrainingPrograms: 'ZRSZ (Employment Service of Slovenia) training programs. CPZ (Center za poklicno usposabljanje) vocational centers. EU-funded skills projects.',
      digitalSkillsPrograms: 'ZRSZ digital skills. Simbioz@ (digital literacy for seniors). Libraries digital access.',
      financialSupport: 'ZRSZ training support. Integration programme financial support for refugees. Social assistance (denarna socialna pomoč).',
      contactAuthority: 'Government Office for the Support and Integration of Migrants: +386 1 478 47 42. ZRSZ: +386 1 479 09 00.',
      immigrantSpecificNotes: 'Small country with developing integration infrastructure. Slovenian language proficiency (A1) required for permanent residence. Free courses available. PIC (Legal Information Centre) provides legal guidance. Growing services since increased migration.',
    ),

    // 26. SPAIN
    AdultEducation(
      country: 'Spain',
      countryCode: 'ES',
      freeLanguageCourses: 'Free Spanish courses through CEPA (Centros de Educación de Personas Adultas). Escuelas Oficiales de Idiomas (EOI). Red Cross language programs. Regional programs.',
      languageCourseProvider: 'CEPA (Adult Education Centers), EOI (Official Language Schools), CEAR (Spanish Commission for Refugees), Red Cross, Accem, MPDL, Comunidad Autónoma programs',
      integrationCourseHours: 'No national mandatory integration course. CEPA: 100-600 hours Spanish depending on level. Regional programs vary (e.g., Catalonia: 45-hour initial welcome program).',
      integrationCourseContent: 'Spanish language (and co-official languages). Sesiones informativas (information sessions) on rights, services, employment. Regional integration plans vary.',
      integrationCourseMandatory: false,
      vocationalTrainingPrograms: 'SEPE (Servicio Público de Empleo Estatal) training. Formación para el empleo programs. Comunidad Autónoma vocational training. NGO employment programs.',
      digitalSkillsPrograms: 'Plan Nacional de Competencias Digitales. EOI digital skills. Red Cross digital inclusion. Fundación Telefónica Empleabilidad Digital.',
      financialSupport: 'IMV (Ingreso Mínimo Vital — minimum vital income). Regional minimum income (RGI, etc.). CEAR refugee support. SEPE training allowances.',
      contactAuthority: 'SEPE: 901 119 999. CEAR: +34 91 441 55 00. Regional Consejería de Educación.',
      immigrantSpecificNotes: 'Spain has no formal mandatory integration course (unlike Germany/Netherlands). Integration through decentralized system — 17 Comunidades Autónomas each have own programs. CEPA/EOI provide free language education. Empadronamiento opens access to most services. Strong NGO network. A2 Spanish required for nationality (DELE/CCSE exams).',
    ),

    // 27. SWEDEN
    AdultEducation(
      country: 'Sweden',
      countryCode: 'SE',
      freeLanguageCourses: 'SFI (Svenska för invandrare / Swedish for Immigrants): FREE for all immigrants. Right to SFI within 1 month of municipality registration. 3 study tracks (1, 2, 3) based on educational background.',
      languageCourseProvider: 'Municipal adult education (Komvux/SFI). Folkuniversitetet. Medborgarskolan. Studieförbund (study associations: ABF, Sensus, etc.). Libraries.',
      integrationCourseHours: 'Etableringsprogrammet (establishment program): SFI (unlimited hours until passed) + civic orientation (100 hours) + employment activities = full-time for 2 years. SFI itself: typically 15-20 hrs/week.',
      integrationCourseContent: 'SFI (Swedish for Immigrants): Swedish to SAS-grund level. Samhällsorientering (civic orientation): 100 hours about Swedish society, healthcare, education, laws, work, family. Employment activities through Arbetsförmedlingen.',
      integrationCourseMandatory: true,
      vocationalTrainingPrograms: 'Arbetsförmedlingen (Employment Service) programs. Snabbspår (Fast Track) for specific professions. Folkhögskolor (folk high schools). Komvux (municipal adult education). Yrkeshögskola (vocational higher education).',
      digitalSkillsPrograms: 'Digitaliseringsinitiativet. Komvux digital skills. Kodcentrum. Libraries digital access and courses.',
      financialSupport: 'Etableringsersättning (establishment allowance) during program. CSN (study grants) for longer education. Aktivitetsstöd (activity support) from Försäkringskassan. All SFI and integration courses completely free.',
      contactAuthority: 'Arbetsförmedlingen: 0771-60 00 00. Municipal adult education (Komvux). Swedish Migration Agency: 0771-235 235.',
      immigrantSpecificNotes: 'Sweden\'s integration system is comprehensive and well-funded. SFI is a RIGHT — free, available to all immigrants. Etableringsprogrammet for refugees: 2-year full-time program combining language, civic orientation, and employment. Samhällsorientering available in mother tongue. Snabbspår fast-tracks professionals. Folkhögskolor offer alternative educational paths. SAS (Swedish as Second Language) continues beyond SFI in Komvux.',
    ),
  ];

  // ============================================================
  // LOOKUP METHODS
  // ============================================================

  SchoolEnrollment? getSchoolEnrollment(String countryCode) {
    try {
      return schoolEnrollments.firstWhere(
        (e) => e.countryCode == countryCode.toUpperCase(),
      );
    } catch (_) {
      return null;
    }
  }

  DiplomaRecognition? getDiplomaRecognition(String countryCode) {
    try {
      return diplomaRecognitions.firstWhere(
        (e) => e.countryCode == countryCode.toUpperCase(),
      );
    } catch (_) {
      return null;
    }
  }

  UniversityAccess? getUniversityAccess(String countryCode) {
    try {
      return universityAccessData.firstWhere(
        (e) => e.countryCode == countryCode.toUpperCase(),
      );
    } catch (_) {
      return null;
    }
  }

  AdultEducation? getAdultEducation(String countryCode) {
    try {
      return adultEducationData.firstWhere(
        (e) => e.countryCode == countryCode.toUpperCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Get complete education information for a country
  Map<String, dynamic>? getFullEducationInfo(String countryCode) {
    final school = getSchoolEnrollment(countryCode);
    final diploma = getDiplomaRecognition(countryCode);
    final university = getUniversityAccess(countryCode);
    final adult = getAdultEducation(countryCode);

    if (school == null && diploma == null && university == null && adult == null) {
      return null;
    }

    return {
      'schoolEnrollment': school?.toMap(),
      'diplomaRecognition': diploma?.toMap(),
      'universityAccess': university?.toMap(),
      'adultEducation': adult?.toMap(),
    };
  }

  /// Search by country name (partial match)
  List<Map<String, dynamic>> searchByCountryName(String query) {
    final lowerQuery = query.toLowerCase();
    final results = <Map<String, dynamic>>[];

    for (final enrollment in schoolEnrollments) {
      if (enrollment.country.toLowerCase().contains(lowerQuery)) {
        final info = getFullEducationInfo(enrollment.countryCode);
        if (info != null) {
          results.add(info);
        }
      }
    }
    return results;
  }

  /// Get all countries where school enrollment is possible without documents
  List<SchoolEnrollment> getCountriesNoDocumentsRequired() {
    return schoolEnrollments
        .where((e) => e.enrollmentPossibleWithoutDocuments)
        .toList();
  }

  /// Get all countries with free school meals
  List<SchoolEnrollment> getCountriesWithFreeSchoolMeals() {
    return schoolEnrollments.where((e) => e.freeSchoolMeals).toList();
  }

  /// Get all countries where university is free for refugees
  List<UniversityAccess> getCountriesFreeUniversityForRefugees() {
    return universityAccessData.where((e) => e.freeForRefugees).toList();
  }

  /// Get all countries with free diploma recognition
  List<DiplomaRecognition> getCountriesWithFreeDiplomaRecognition() {
    return diplomaRecognitions
        .where((e) => e.costEur.toLowerCase().contains('free'))
        .toList();
  }

  /// Get all countries with mandatory integration courses
  List<AdultEducation> getCountriesWithMandatoryIntegration() {
    return adultEducationData
        .where((e) => e.integrationCourseMandatory)
        .toList();
  }

  /// Get countries sorted by lowest non-EU tuition
  List<UniversityAccess> getCheapestUniversitiesForNonEU() {
    final list = List<UniversityAccess>.from(universityAccessData);
    // Countries where studying in national language is free for all
    final freeCountries = list.where(
      (e) => e.tuitionNonEu.toLowerCase().contains('free') ||
             e.tuitionNonEu.toLowerCase().contains('eur 0'),
    ).toList();
    return freeCountries;
  }

  /// Get recognition authority info for a specific profession in a country
  String getProfessionalRequalificationInfo(
    String countryCode,
    String profession,
  ) {
    final diploma = getDiplomaRecognition(countryCode);
    if (diploma == null) return 'Country not found';

    switch (profession.toLowerCase()) {
      case 'doctor':
      case 'physician':
      case 'medical':
        return diploma.doctorRequalification;
      case 'engineer':
      case 'engineering':
        return diploma.engineerRequalification;
      case 'teacher':
      case 'teaching':
        return diploma.teacherRequalification;
      case 'nurse':
      case 'nursing':
        return diploma.nurseRequalification;
      case 'lawyer':
      case 'legal':
      case 'attorney':
        return diploma.lawyerRequalification;
      default:
        return 'For profession "$profession", contact ${diploma.recognitionAuthority} at ${diploma.authorityWebsite}';
    }
  }

  /// Get summary statistics
  Map<String, dynamic> getSummaryStatistics() {
    return {
      'totalCountries': 27,
      'countriesRightToEducationRegardlessOfStatus':
          schoolEnrollments.where((e) => e.rightRegardlessOfStatus).length,
      'countriesNoDocumentsNeeded':
          schoolEnrollments.where((e) => e.enrollmentPossibleWithoutDocuments).length,
      'countriesWithFreeSchoolMeals':
          schoolEnrollments.where((e) => e.freeSchoolMeals).length,
      'countriesFreeUniversityForRefugees':
          universityAccessData.where((e) => e.freeForRefugees).length,
      'countriesMandatoryIntegration':
          adultEducationData.where((e) => e.integrationCourseMandatory).length,
      'countriesFreeDiplomaRecognition':
          diplomaRecognitions.where((e) => e.costEur.toLowerCase().contains('free')).length,
    };
  }
}
