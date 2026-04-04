// Healthcare Access Database for all 27 EU Countries
// Real data for immigrant healthcare rights and access
// Last updated: 2026-04
//
// Sources: WHO European Health Observatory, European Commission social security
// coordination (Regulations EC 883/2004 and 987/2009), ECHR Article 3 case law,
// EU Directive 2011/24/EU (cross-border healthcare), PICUM (Platform for
// International Cooperation on Undocumented Migrants), Médecins du Monde
// European Observatory on Access to Healthcare, national health ministry data,
// FRA (EU Agency for Fundamental Rights) reports on migrant healthcare access.

class HealthcareAccess {
  final String country;
  final String countryCode;
  final bool emergencyFree;
  final String emergencyNumber;
  final String healthInsuranceSystem;
  final bool ehcardAccepted;
  final String undocumentedAccess;
  final String asylumSeekerAccess;
  final String mentalHealthAccess;
  final String maternityAccess;
  final String childrenAccess;
  final String registrationProcess;
  final String? freeClinicInfo;
  final String costEstimate;
  final String legalBasis;
  final String mentalHealthCrisisLine;
  final String ehcardHowToGet;
  final String vaccinationProgram;
  final List<String> mustTreatHospitals;
  final String immigrantSpecificNotes;

  const HealthcareAccess({
    required this.country,
    required this.countryCode,
    required this.emergencyFree,
    required this.emergencyNumber,
    required this.healthInsuranceSystem,
    required this.ehcardAccepted,
    required this.undocumentedAccess,
    required this.asylumSeekerAccess,
    required this.mentalHealthAccess,
    required this.maternityAccess,
    required this.childrenAccess,
    required this.registrationProcess,
    this.freeClinicInfo,
    required this.costEstimate,
    required this.legalBasis,
    required this.mentalHealthCrisisLine,
    required this.ehcardHowToGet,
    required this.vaccinationProgram,
    required this.mustTreatHospitals,
    required this.immigrantSpecificNotes,
  });

  Map<String, dynamic> toMap() {
    return {
      'country': country,
      'countryCode': countryCode,
      'emergencyFree': emergencyFree,
      'emergencyNumber': emergencyNumber,
      'healthInsuranceSystem': healthInsuranceSystem,
      'ehcardAccepted': ehcardAccepted,
      'undocumentedAccess': undocumentedAccess,
      'asylumSeekerAccess': asylumSeekerAccess,
      'mentalHealthAccess': mentalHealthAccess,
      'maternityAccess': maternityAccess,
      'childrenAccess': childrenAccess,
      'registrationProcess': registrationProcess,
      'freeClinicInfo': freeClinicInfo,
      'costEstimate': costEstimate,
      'legalBasis': legalBasis,
      'mentalHealthCrisisLine': mentalHealthCrisisLine,
      'ehcardHowToGet': ehcardHowToGet,
      'vaccinationProgram': vaccinationProgram,
      'mustTreatHospitals': mustTreatHospitals,
      'immigrantSpecificNotes': immigrantSpecificNotes,
    };
  }
}

class HealthcareDatabase {
  static final HealthcareDatabase _instance = HealthcareDatabase._internal();
  factory HealthcareDatabase() => _instance;
  HealthcareDatabase._internal();

  HealthcareAccess? getByCountry(String country) {
    final lower = country.toLowerCase().trim();
    return allCountries.cast<HealthcareAccess?>().firstWhere(
      (c) =>
          c!.country.toLowerCase() == lower ||
          c.countryCode.toLowerCase() == lower,
      orElse: () => null,
    );
  }

  List<HealthcareAccess> getByEmergencyFree(bool free) {
    return allCountries.where((c) => c.emergencyFree == free).toList();
  }

  List<HealthcareAccess> getBySystemType(String systemType) {
    final lower = systemType.toLowerCase();
    return allCountries
        .where((c) => c.healthInsuranceSystem.toLowerCase().contains(lower))
        .toList();
  }

  List<HealthcareAccess> searchByKeyword(String keyword) {
    final lower = keyword.toLowerCase();
    return allCountries.where((c) {
      return c.country.toLowerCase().contains(lower) ||
          c.undocumentedAccess.toLowerCase().contains(lower) ||
          c.asylumSeekerAccess.toLowerCase().contains(lower) ||
          c.freeClinicInfo?.toLowerCase().contains(lower) == true ||
          c.immigrantSpecificNotes.toLowerCase().contains(lower);
    }).toList();
  }

  // ============================================================
  // ALL 27 EU COUNTRIES
  // ============================================================

  static const List<HealthcareAccess> allCountries = [
    // -------------------------------------------------------
    // 1. AUSTRIA
    // -------------------------------------------------------
    HealthcareAccess(
      country: 'Austria',
      countryCode: 'AT',
      emergencyFree: true,
      emergencyNumber: '112 / 144 (ambulance)',
      healthInsuranceSystem: 'Social insurance (Bismarck model). Mandatory '
          'insurance tied to employment via OGK (Osterreichische '
          'Gesundheitskasse). Self-employed use SVS.',
      ehcardAccepted: true,
      undocumentedAccess: 'Emergency care must be provided regardless of status '
          'under the Austrian Hospital Act (KAKuG). Beyond emergencies, '
          'undocumented persons have no legal entitlement to public healthcare. '
          'NGOs such as AmberMed (Vienna) and Marienambulanz (Graz) provide '
          'free primary care.',
      asylumSeekerAccess: 'Asylum seekers in federal care (Grundversorgung) '
          'receive an e-card equivalent giving access to the same services as '
          'insured residents, including GP visits, specialist referrals, '
          'hospital care, prescriptions, and dental emergencies.',
      mentalHealthAccess: 'Covered under social insurance. Psychotherapy is '
          'partially reimbursed (EUR 33 per session by OGK; full cost ~EUR 80-150). '
          'Asylum seekers can access mental health via Grundversorgung. '
          'Crisis line: 142 (Telefonseelsorge, 24/7, free, multilingual).',
      maternityAccess: 'Full maternity care covered by social insurance including '
          'prenatal visits, hospital birth, and postnatal care. Uninsured women '
          'can access emergency obstetric care. Asylum seekers receive full '
          'maternity coverage under Grundversorgung. Mother-child pass '
          '(Mutter-Kind-Pass) program provides free check-ups.',
      childrenAccess: 'All children in Austria are entitled to free vaccinations '
          'under the national immunization program regardless of residence '
          'status. Children of asylum seekers are fully covered. Uninsured '
          'children can access emergency care and NGO clinics.',
      registrationProcess: 'Register with OGK automatically upon starting '
          'employment. Self-register at local OGK office with residence '
          'registration (Meldezettel) and employment contract. Family members '
          'can be co-insured (Mitversicherung) at no extra cost.',
      freeClinicInfo: 'AmberMed (Vienna, Oberlaaer Str. 300-306) - free '
          'medical and dental care for uninsured persons. Marienambulanz '
          '(Graz, Mariengasse 12) - free primary care. Neunerhaus '
          '(Vienna) - healthcare for homeless. Louise Bus (Vienna, mobile '
          'medical unit by Caritas).',
      costEstimate: 'GP visit without insurance: EUR 50-80. Specialist: '
          'EUR 80-200. Emergency room: EUR 150-300. Hospital day: '
          'EUR 300-600. Prescription: EUR 6.85 (co-pay with insurance).',
      legalBasis: 'Allgemeines Sozialversicherungsgesetz (ASVG), '
          'Krankenanstalten- und Kuranstaltengesetz (KAKuG), '
          'Grundversorgungsvereinbarung Art. 15a B-VG.',
      mentalHealthCrisisLine: '142 (Telefonseelsorge, 24/7, free). '
          '01/31330 (Psychiatrische Soforthilfe Wien). '
          '0800 400 120 (Krisentelefon for children/youth).',
      ehcardHowToGet: 'The EHIC (e-card) is issued automatically by OGK '
          'to all insured persons. Request replacement at any OGK office '
          'or online at gesundheitskasse.at. Processing: 1-2 weeks.',
      vaccinationProgram: 'Free national immunization program for all children '
          '0-15 years regardless of status. Includes MMR, DTaP, Hep B, '
          'polio, HPV. Available at public health offices (Gesundheitsamt) '
          'and participating pediatricians.',
      mustTreatHospitals: [
        'All public hospitals (Landeskrankenhäuser) must provide emergency care',
        'AKH Wien (Allgemeines Krankenhaus der Stadt Wien)',
        'LKH Graz (Landeskrankenhaus-Universitätsklinikum Graz)',
        'Kepler Universitätsklinikum Linz',
      ],
      immigrantSpecificNotes: 'EU/EEA citizens can use EHIC for temporary stays. '
          'Registered residents with employment are automatically insured. '
          'Asylum seekers receive Grundversorgung e-card. Undocumented persons '
          'should contact AmberMed or Caritas for free healthcare. No data '
          'sharing between hospitals and immigration authorities for emergency '
          'care.',
    ),

    // -------------------------------------------------------
    // 2. BELGIUM
    // -------------------------------------------------------
    HealthcareAccess(
      country: 'Belgium',
      countryCode: 'BE',
      emergencyFree: true,
      emergencyNumber: '112 / 100 (ambulance) / 1733 (non-emergency GP)',
      healthInsuranceSystem: 'Mandatory social health insurance (Bismarck model). '
          'All residents must join a mutualité/ziekenfonds (mutual insurance '
          'fund). System covers ~99% of population.',
      ehcardAccepted: true,
      undocumentedAccess: 'Undocumented persons can apply for Aide Médicale '
          'Urgente (AMU / Dringende Medische Hulp) through their local CPAS/'
          'OCMW social welfare office. AMU covers all necessary medical care '
          '(not just emergencies) - GP visits, specialist care, hospital, '
          'prescriptions, mental health. One of the most comprehensive systems '
          'in the EU for undocumented migrants.',
      asylumSeekerAccess: 'Asylum seekers registered with Fedasil receive full '
          'healthcare access. Those in reception centers get care through the '
          'center medical service. Those in individual housing get a medical '
          'card from CPAS/OCMW covering full healthcare equivalent to Belgian '
          'social insurance.',
      mentalHealthAccess: 'Covered by social insurance. Psychologist visits '
          'partially reimbursed (EUR 11 co-pay for 8 sessions via '
          'conventional psychologists). Psychiatric care fully covered in '
          'hospitals. Asylum seekers and AMU holders can access mental health '
          'services. Several specialized refugee mental health centers exist.',
      maternityAccess: 'Full maternity care for all insured women including '
          'prenatal monitoring, hospital birth, postnatal care. AMU covers '
          'maternity for undocumented women. ONE (Office de la Naissance et '
          'de l\'Enfance) / Kind en Gezin provides free prenatal/postnatal '
          'consultations for all women regardless of status.',
      childrenAccess: 'All children have access to free preventive care through '
          'ONE (Wallonia/Brussels) and Kind en Gezin (Flanders) regardless of '
          'residence status. Free vaccinations, developmental check-ups. '
          'School health services available to all enrolled children.',
      registrationProcess: 'Register with a mutualité/ziekenfonds within 3 '
          'months of arrival. Need domicile registration, ID, and employment '
          'or proof of residence. Choose from: Mutualités Chrétiennes, '
          'Socialistische Mutualiteit, Liberale Mutualiteit, Neutraal '
          'Ziekenfonds, or CAAMI/HZIV (auxiliary fund).',
      freeClinicInfo: 'Médecins du Monde clinics in Brussels (Rue Botanique 75) '
          'and Antwerp - free care for uninsured. Maisons Médicales (Brussels, '
          'Wallonia) - community health centers, many offer flat-rate care. '
          'Wijkgezondheidscentra (Flanders) - neighborhood health centers with '
          'flat-rate system (no co-pay). Huis voor Gezondheid (Antwerp).',
      costEstimate: 'GP visit: EUR 30-40 (reimbursed ~75% with insurance). '
          'Specialist: EUR 40-60. Emergency room: EUR 60-150. '
          'Hospital day: EUR 300-500 (co-pay EUR 15-45/day with insurance). '
          'Prescriptions: EUR 1-15 co-pay with insurance.',
      legalBasis: 'Loi relative à l\'assurance obligatoire soins de santé '
          '(14.07.1994), Royal Decree 12.12.1996 on AMU (Aide Médicale '
          'Urgente), Loi accueil 12.01.2007 (asylum seekers).',
      mentalHealthCrisisLine: '0800 32 123 (Centre de Prévention du Suicide, '
          'French, 24/7, free). 1813 (Zelfmoordlijn, Dutch, 24/7, free). '
          '02/649 95 55 (SOS Psychiatrie Bruxelles).',
      ehcardHowToGet: 'Request EHIC from your mutualité/ziekenfonds. Available '
          'online via MyMutualité portal or at local office. Free of charge. '
          'Processing: immediate to 2 weeks. Valid 2 years.',
      vaccinationProgram: 'Free vaccination program for all children through ONE '
          '(French community) and Kind en Gezin (Flemish community). Covers '
          'all WHO-recommended childhood vaccines. Available at consultation '
          'centers regardless of residence status.',
      mustTreatHospitals: [
        'All hospital emergency departments must treat regardless of status',
        'CHU Saint-Pierre (Brussels) - specialized in migrant healthcare',
        'UZ Brussel (Brussels)',
        'CHU de Liège',
        'UZ Gent',
        'UZ Antwerpen',
      ],
      immigrantSpecificNotes: 'Belgium has one of the best healthcare access '
          'systems for undocumented migrants in the EU through AMU. The key '
          'step is visiting the local CPAS/OCMW to apply. Hospital social '
          'workers can help initiate AMU applications. Medical staff cannot '
          'report undocumented patients to immigration authorities. EU citizens '
          'can use EHIC; if staying longer than 3 months, must register with '
          'a mutualité.',
    ),

    // -------------------------------------------------------
    // 3. BULGARIA
    // -------------------------------------------------------
    HealthcareAccess(
      country: 'Bulgaria',
      countryCode: 'BG',
      emergencyFree: true,
      emergencyNumber: '112 / 150 (ambulance)',
      healthInsuranceSystem: 'National Health Insurance Fund (NHIF/NZOK). '
          'Mandatory insurance contributions (8% of income, split '
          'employer/employee). Covers ~87% of population; significant '
          'number of uninsured Bulgarians.',
      ehcardAccepted: true,
      undocumentedAccess: 'Emergency care must be provided at public hospitals. '
          'Beyond emergencies, undocumented persons have no legal entitlement '
          'to public healthcare. Some NGO assistance available through '
          'Bulgarian Red Cross and Médecins du Monde (limited operations).',
      asylumSeekerAccess: 'Asylum seekers with registration cards are entitled '
          'to healthcare equivalent to uninsured Bulgarian citizens - meaning '
          'emergency care, maternal care, communicable disease treatment, and '
          'care for children under 16. After 3 months of waiting for decision, '
          'entitled to full NHIF coverage.',
      mentalHealthAccess: 'Psychiatric care covered by NHIF for insured persons. '
          'Limited community mental health infrastructure. Asylum seekers can '
          'access mental health at reception centers (limited). '
          'Crisis line: 0035 (National Helpline for Children). Several NGOs '
          'provide psychological support to refugees.',
      maternityAccess: 'Maternity care covered for insured women. Uninsured '
          'women receive emergency obstetric care. Asylum-seeking women '
          'receive maternity care. Hospital births typically covered even '
          'for uninsured in practice, though billing disputes occur.',
      childrenAccess: 'Children under 16 receive free healthcare regardless of '
          'insurance status under Bulgarian law. National immunization program '
          'covers all children. School health services available.',
      registrationProcess: 'Register with NHIF via employer (automatic with '
          'employment contract) or self-register at NHIF regional office. '
          'Need personal identification number (EGN) or foreigner number '
          '(LNCh). Choose a GP from NHIF-contracted doctors.',
      freeClinicInfo: 'Bulgarian Red Cross health programs in Sofia. '
          'Health mediators program in Roma communities provides some '
          'access facilitation. Caritas Bulgaria offers limited medical '
          'assistance. Open-access vaccination sites in major cities.',
      costEstimate: 'GP visit without insurance: BGN 30-50 (EUR 15-25). '
          'Specialist: BGN 40-80 (EUR 20-40). Emergency room: BGN 50-200 '
          '(EUR 25-100). Hospital day: BGN 100-300 (EUR 50-150). '
          'Bulgaria has among the lowest healthcare costs in the EU.',
      legalBasis: 'Health Insurance Act (Закон за здравното осигуряване), '
          'Health Act (Закон за здравето), Asylum and Refugees Act '
          '(Закон за убежището и бежанците) Art. 29.',
      mentalHealthCrisisLine: '116 111 (National Helpline for Children, free). '
          '0800 20 058 (Anti-violence hotline). 02/981 76 86 (Crisis center '
          'Animus, Sofia).',
      ehcardHowToGet: 'Request EHIC at NHIF regional office or online at '
          'nhif.bg. Need valid health insurance status. Free of charge. '
          'Processing: up to 30 days.',
      vaccinationProgram: 'Mandatory vaccination program for all children '
          'regardless of status covering BCG, DTaP, polio, MMR, Hep B. '
          'Available free at GP offices and regional health inspectorates.',
      mustTreatHospitals: [
        'All public hospital emergency departments (Спешен прием)',
        'Pirogov Emergency Hospital (Sofia)',
        'Alexandrovska University Hospital (Sofia)',
        'St. Marina University Hospital (Varna)',
        'UMBAL Plovdiv',
      ],
      immigrantSpecificNotes: 'Bulgaria is primarily a transit country for '
          'migrants. Healthcare access for undocumented persons is very '
          'limited beyond emergencies. Asylum seekers should register '
          'promptly to access healthcare through the State Agency for '
          'Refugees (SAR). Language barriers are significant - bring a '
          'translator if possible. EU citizens use EHIC.',
    ),

    // -------------------------------------------------------
    // 4. CROATIA
    // -------------------------------------------------------
    HealthcareAccess(
      country: 'Croatia',
      countryCode: 'HR',
      emergencyFree: true,
      emergencyNumber: '112 / 194 (ambulance)',
      healthInsuranceSystem: 'Mandatory health insurance through HZZO '
          '(Croatian Health Insurance Fund). Bismarck model with '
          'universal coverage goal. Supplementary insurance available '
          'from HZZO or private insurers.',
      ehcardAccepted: true,
      undocumentedAccess: 'Emergency care must be provided at all public '
          'hospitals. Undocumented persons can access emergency and '
          'essential care; costs may be billed. Communicable disease '
          'treatment is provided regardless of status.',
      asylumSeekerAccess: 'Asylum seekers receive healthcare equivalent to '
          'insured Croatian citizens under the International and Temporary '
          'Protection Act. Includes GP, specialist, hospital, dental '
          'emergencies, prescriptions, and mental health support. Care '
          'coordinated through reception center medical staff.',
      mentalHealthAccess: 'Covered by mandatory insurance. Community mental '
          'health centers expanding. Asylum seekers have access to '
          'psychological support at reception centers and through NGO '
          'partners (Croatian Red Cross, JRS). Psychotherapy partially '
          'covered with referral.',
      maternityAccess: 'Full maternity care covered for insured women. Asylum '
          'seekers receive full maternity coverage. Prenatal care, hospital '
          'birth, and postnatal care included. Uninsured women receive '
          'emergency obstetric care at minimum.',
      childrenAccess: 'All children under 18 are entitled to healthcare '
          'under mandatory insurance. Children of asylum seekers receive '
          'full coverage. National immunization program mandatory and free '
          'for all children.',
      registrationProcess: 'Register with HZZO via employer or at local HZZO '
          'office. Need OIB (personal identification number), residence '
          'permit, and employment contract or other basis. Choose a GP '
          'from contracted providers.',
      freeClinicInfo: 'Croatian Red Cross provides health assistance to '
          'migrants. JRS (Jesuit Refugee Service) Croatia - psychosocial '
          'support. Centre for Peace Studies (CMS) Zagreb - legal and '
          'social assistance. IOM Croatia - health assessments for '
          'refugees.',
      costEstimate: 'GP visit without insurance: HRK 200-400 (EUR 27-53). '
          'Specialist: HRK 300-600 (EUR 40-80). Emergency room: HRK 300-800 '
          '(EUR 40-106). Hospital day: HRK 500-1500 (EUR 66-200).',
      legalBasis: 'Mandatory Health Insurance Act (NN 80/13, 137/13), '
          'International and Temporary Protection Act (NN 70/15, 127/17), '
          'Healthcare Act (NN 100/18).',
      mentalHealthCrisisLine: '116 006 (Hrabri Telefon - children/youth, free). '
          '01/4833 888 (Plavi Telefon - emotional support). '
          '0800 0800 (SOS phone for violence victims).',
      ehcardHowToGet: 'Request EHIC at HZZO regional office or online at '
          'hzzo.hr. Need valid mandatory health insurance. Free. '
          'Processing: 7-15 days.',
      vaccinationProgram: 'Mandatory and free vaccination program for all '
          'children. Includes DTaP, polio, MMR, Hep B, Hib, pneumococcal. '
          'Administered at patronage nurse visits and pediatric offices.',
      mustTreatHospitals: [
        'All public hospital emergency departments',
        'KBC Zagreb (Klinički bolnički centar Zagreb)',
        'KBC Split',
        'KBC Rijeka',
        'KBC Osijek',
      ],
      immigrantSpecificNotes: 'Croatia\'s healthcare system for asylum seekers '
          'improved significantly after EU accession. Registration at '
          'reception centers (Kutina, Zagreb) is key to accessing healthcare. '
          'Push-back concerns at borders mean some migrants arrive without '
          'proper registration - seek UNHCR or Croatian Red Cross assistance '
          'immediately.',
    ),

    // -------------------------------------------------------
    // 5. CYPRUS
    // -------------------------------------------------------
    HealthcareAccess(
      country: 'Cyprus',
      countryCode: 'CY',
      emergencyFree: true,
      emergencyNumber: '112 / 199 (ambulance)',
      healthInsuranceSystem: 'General Healthcare System (GeSY/GESY) launched '
          '2019. Universal coverage for all legal residents. Funded by '
          'contributions from employees, employers, state, and self-employed.',
      ehcardAccepted: true,
      undocumentedAccess: 'Emergency care provided at public hospitals. '
          'Undocumented persons not covered by GESY. Can access A&E for '
          'emergencies. Some NGO medical support available. Communicable '
          'disease treatment provided.',
      asylumSeekerAccess: 'Asylum seekers are entitled to GESY coverage '
          'after registration. Receive a GESY card allowing access to GP, '
          'specialist, hospital, prescriptions, dental, and mental health '
          'services on same basis as Cypriot citizens.',
      mentalHealthAccess: 'Covered under GESY including psychiatry and '
          'clinical psychology (limited sessions). Community mental health '
          'centers in major towns. NGOs like Cyprus Refugee Council provide '
          'psychosocial support to refugees.',
      maternityAccess: 'Full maternity coverage under GESY - prenatal care, '
          'hospital delivery, postnatal care. Asylum seekers covered. '
          'Undocumented women can access emergency obstetric care.',
      childrenAccess: 'All children registered in GESY receive full pediatric '
          'care. Vaccination program free for all children. School health '
          'services available.',
      registrationProcess: 'Register with GESY at gesy.org.cy using ARC '
          '(Alien Registration Certificate) or ID. Registration is free. '
          'Choose a personal doctor (GP) from GESY-registered physicians.',
      freeClinicInfo: 'Cyprus Refugee Council (Nicosia) - health navigation '
          'assistance. KISA (Nicosia, Limassol) - social support and health '
          'referrals. Caritas Cyprus - humanitarian assistance including '
          'health. Red Cross Cyprus - first aid and health programs.',
      costEstimate: 'GP visit (GESY co-pay): EUR 1. Specialist (GESY): '
          'EUR 6. Without GESY: GP EUR 30-50, Specialist EUR 50-100. '
          'Emergency room without GESY: EUR 100-200. Private hospital '
          'day: EUR 300-800.',
      legalBasis: 'General Healthcare System Law 89(I)/2001 as amended, '
          'Refugee Law N.6(I)/2000, Law on Public Health (Cap. 260).',
      mentalHealthCrisisLine: '1466 (Mental Health Helpline, free). '
          '116 111 (Children\'s helpline). '
          '1440 (Citizens\' helpline).',
      ehcardHowToGet: 'Request EHIC at GESY offices or online at gesy.org.cy. '
          'Must be registered in GESY. Free. Processing: 1-2 weeks.',
      vaccinationProgram: 'National immunization program free for all children. '
          'Includes DTaP, MMR, polio, Hep B, meningococcal, HPV. '
          'Administered at public health centers.',
      mustTreatHospitals: [
        'All public hospital A&E departments',
        'Nicosia General Hospital',
        'Limassol General Hospital',
        'Larnaca General Hospital',
        'Paphos General Hospital',
      ],
      immigrantSpecificNotes: 'GESY provides good coverage for legally resident '
          'immigrants and asylum seekers. Key is getting registered promptly '
          'at the Asylum Service (Nicosia). Long processing times for asylum '
          'applications. Turkish-occupied north has separate health system. '
          'English widely spoken in medical settings.',
    ),

    // -------------------------------------------------------
    // 6. CZECH REPUBLIC
    // -------------------------------------------------------
    HealthcareAccess(
      country: 'Czech Republic',
      countryCode: 'CZ',
      emergencyFree: true,
      emergencyNumber: '112 / 155 (ambulance)',
      healthInsuranceSystem: 'Mandatory public health insurance (Bismarck model). '
          'Multiple insurance funds: VZP (largest, ~60% market), VOZP, OZP, '
          'ZPMV, etc. All provide same basic coverage. Employer/employee '
          'contributions (13.5% of gross salary).',
      ehcardAccepted: true,
      undocumentedAccess: 'Emergency and urgent care must be provided. '
          'Undocumented persons have no access to public insurance. '
          'Must pay out-of-pocket or rely on charity. Some NGO medical '
          'support through Organization for Aid to Refugees (OPU) and '
          'Doctors Without Borders (limited).',
      asylumSeekerAccess: 'Asylum seekers receive health insurance equivalent '
          'to Czech citizens, paid by the state. Covers GP, specialist, '
          'hospital, dental, prescriptions, and preventive care. Must '
          'register with VZP (state assigns to this fund).',
      mentalHealthAccess: 'Covered by public insurance (psychiatry fully, '
          'clinical psychology with referral). Mental health reform ongoing '
          'with new community mental health centers. Asylum seekers have '
          'access. InBáze and other NGOs provide intercultural psychotherapy.',
      maternityAccess: 'Full maternity care for insured women - prenatal '
          'monitoring, hospital delivery, postnatal care, maternity benefits. '
          'Asylum seekers fully covered. Uninsured women receive emergency '
          'obstetric care.',
      childrenAccess: 'All insured children receive full pediatric care. '
          'Children of asylum seekers fully covered. National vaccination '
          'program mandatory. Uninsured children can access emergency care.',
      registrationProcess: 'Automatic enrollment via employer. Self-employed '
          'register at chosen insurance fund. Need residence permit, birth '
          'number (rodné číslo), and employment/business documentation. '
          'Choose a GP and register with them.',
      freeClinicInfo: 'InBáze (Prague, Legerova 50) - intercultural health '
          'and psychosocial support. OPU (Organization for Aid to Refugees) - '
          'health assistance navigation. Poradna pro integraci (Integration '
          'Center) - social and health support. Český červený kříž (Czech '
          'Red Cross) - humanitarian health programs.',
      costEstimate: 'GP visit without insurance: CZK 500-1000 (EUR 20-40). '
          'Specialist: CZK 800-2000 (EUR 32-80). Emergency room: CZK 1000-3000 '
          '(EUR 40-120). Hospital day: CZK 2000-5000 (EUR 80-200).',
      legalBasis: 'Act No. 48/1997 Coll. on Public Health Insurance, '
          'Act No. 325/1999 Coll. on Asylum, Act No. 326/1999 Coll. '
          'on Foreigners\' Residence.',
      mentalHealthCrisisLine: '116 123 (Linka důvěry, 24/7, free). '
          '116 111 (Linka bezpečí - children, 24/7). '
          '284 016 666 (Centrum krizové intervence, Prague).',
      ehcardHowToGet: 'Request EHIC from your health insurance fund (VZP, '
          'VOZP, etc.) at branch office or online. Free. Processing: '
          '7-14 days. Valid up to 1 year.',
      vaccinationProgram: 'Mandatory vaccination program for all children. '
          'Covers DTaP, polio, MMR, Hep B, Hib, pneumococcal. Administered '
          'by registered pediatricians. Non-compliance can result in fines.',
      mustTreatHospitals: [
        'All hospital emergency departments (Urgentní příjem)',
        'Všeobecná fakultní nemocnice (General University Hospital, Prague)',
        'Fakultní nemocnice Motol (Prague)',
        'Fakultní nemocnice Brno',
        'Fakultní nemocnice Olomouc',
      ],
      immigrantSpecificNotes: 'Third-country nationals without employment '
          'must purchase commercial health insurance (comprehensive, ~EUR 400/'
          'year) which has worse coverage than public insurance. This is a '
          'known structural problem. Asylum seekers get public insurance. '
          'EU citizens use EHIC or register with a Czech fund after '
          'establishing residence.',
    ),

    // -------------------------------------------------------
    // 7. DENMARK
    // -------------------------------------------------------
    HealthcareAccess(
      country: 'Denmark',
      countryCode: 'DK',
      emergencyFree: true,
      emergencyNumber: '112 / 1813 (non-emergency medical, Region Hovedstaden)',
      healthInsuranceSystem: 'Tax-funded universal healthcare (Beveridge model). '
          'All residents with CPR number (civil registration) receive free '
          'healthcare. No insurance premiums. Funded through national and '
          'municipal taxes.',
      ehcardAccepted: true,
      undocumentedAccess: 'Emergency care provided but may be billed. '
          'Undocumented persons have no access to regular healthcare. '
          'Since 2023, undocumented migrants can access limited healthcare '
          'through Røde Kors (Red Cross) clinic in Copenhagen. Restrictive '
          'approach compared to Scandinavian neighbors.',
      asylumSeekerAccess: 'Asylum seekers in the reception system receive '
          'healthcare through the Danish Immigration Service (Udlændingestyrelsen). '
          'Initially: emergency and essential care. After referral to a '
          'municipality: broader access. Dental only for acute/pain. '
          'Healthcare provided at asylum centers or contracted providers.',
      mentalHealthAccess: 'Psychiatric care free under public system with '
          'referral. Psychologist partially covered (60% for ages 18-24 '
          'with referral). Private psychologist: DKK 900-1200/session. '
          'Asylum seekers: mental health screening at arrival, trauma '
          'treatment through specialized centers like DIGNITY.',
      maternityAccess: 'Full free maternity care for all registered residents: '
          'prenatal visits, hospital birth, midwife care, postnatal. Asylum '
          'seekers receive maternity care. Undocumented women can access '
          'emergency obstetric care.',
      childrenAccess: 'All registered children receive free healthcare. '
          'Children of asylum seekers receive healthcare through the asylum '
          'system. Free vaccination program. School health services. '
          'Dental care free for under 18.',
      registrationProcess: 'Automatic upon receiving CPR number (granted with '
          'residence permit). Register at International Citizen Service or '
          'local municipality. Receive yellow health card (sundhedskort) with '
          'assigned GP. Can change GP online at sundhed.dk.',
      freeClinicInfo: 'Røde Kors Sundhedsklinik (Copenhagen, Griffenfeldsgade 44) '
          '- free care for undocumented migrants. DIGNITY (Copenhagen) - '
          'torture/trauma rehabilitation. Læger uden Grænser (MSF Denmark) - '
          'advocacy. Kirkens Korshær - health support for homeless.',
      costEstimate: 'GP visit: free with yellow card. Without CPR: '
          'DKK 400-800 (EUR 54-107). Specialist without referral: '
          'DKK 800-2000 (EUR 107-268). Emergency room: free for residents, '
          'DKK 2000-5000 (EUR 268-670) for uninsured.',
      legalBasis: 'Health Act (Sundhedsloven LBK nr 210 af 27/01/2022), '
          'Aliens Act (Udlændingeloven), Executive Order on Healthcare '
          'for Asylum Seekers (BEK nr 1077).',
      mentalHealthCrisisLine: '70 201 201 (Livslinien, 24/7 suicide prevention). '
          '116 123 (Sind helpline). 70 266 766 (Psykiatrisk skadestue/info). '
          'BørneTeIefonen: 116 111 (children, 24/7).',
      ehcardHowToGet: 'EHIC issued by Udbetaling Danmark. Apply online at '
          'borger.dk or contact Udbetaling Danmark. Need CPR number and '
          'valid Danish health coverage. Free. Processing: 1-3 weeks.',
      vaccinationProgram: 'Free childhood vaccination program for all '
          'registered children. Includes DTaP, polio, MMR, Hib, pneumococcal, '
          'HPV. Given at GP office as part of free child health checks.',
      mustTreatHospitals: [
        'All public hospital emergency departments (Akutmodtagelser)',
        'Rigshospitalet (Copenhagen)',
        'Herlev Hospital (Copenhagen region)',
        'Aarhus Universitetshospital',
        'Odense Universitetshospital',
        'Aalborg Universitetshospital',
      ],
      immigrantSpecificNotes: 'Denmark has a relatively restrictive approach to '
          'undocumented migrant healthcare compared to other Nordic countries. '
          'The key is obtaining a CPR number through legal residence. EU '
          'citizens can use EHIC; if working in Denmark, apply for CPR. '
          'Some municipalities are more accommodating than others. Interpreting '
          'services available in the public healthcare system.',
    ),

    // -------------------------------------------------------
    // 8. ESTONIA
    // -------------------------------------------------------
    HealthcareAccess(
      country: 'Estonia',
      countryCode: 'EE',
      emergencyFree: true,
      emergencyNumber: '112',
      healthInsuranceSystem: 'Estonian Health Insurance Fund (Eesti Haigekassa, '
          'EHIF). Mandatory social insurance funded by employer social tax '
          '(13% of payroll). Covers employees, children, pensioners, '
          'pregnant women, registered unemployed.',
      ehcardAccepted: true,
      undocumentedAccess: 'Emergency care must be provided. Undocumented '
          'persons pay full costs for non-emergency care. Very limited '
          'NGO medical support. Estonian Human Rights Centre provides '
          'some navigation assistance.',
      asylumSeekerAccess: 'Asylum seekers receive emergency care and essential '
          'healthcare paid by the state through the Social Insurance Board '
          '(Sotsiaalkindlustusamet). Includes GP visits, necessary specialist '
          'care, prescriptions, and mental health support. Care organized '
          'through designated providers.',
      mentalHealthAccess: 'Psychiatric care covered by EHIF with referral. '
          'Psychologist visits not covered by public insurance (private: '
          'EUR 50-80/session). Crisis services available. Asylum seekers '
          'can access mental health through the Social Insurance Board.',
      maternityAccess: 'Comprehensive maternity care for insured women: '
          'prenatal visits, hospital birth, postnatal care. Pregnant women '
          'automatically qualify for insurance regardless of employment. '
          'Asylum-seeking women receive maternity care.',
      childrenAccess: 'All children under 19 are covered by EHIF regardless '
          'of parents\' insurance status. Free vaccinations, pediatric care, '
          'dental care (under 19). Children of asylum seekers covered.',
      registrationProcess: 'Insurance activated automatically via employment '
          '(employer registers social tax). Non-working residents register '
          'at EHIF with ID code and residence permit. Choose a family doctor '
          '(perearst) from list at haigekassa.ee.',
      freeClinicInfo: 'Estonian Human Rights Centre (Tallinn) - legal and '
          'social navigation. Estonian Refugee Council - integration support '
          'including health. Johannes Mihkelsoni Keskus - refugee assistance. '
          'No dedicated free medical clinics for uninsured; primary route '
          'is through emergency departments.',
      costEstimate: 'GP visit (insured): EUR 5 co-pay. Without insurance: '
          'EUR 30-60. Specialist: EUR 50-120. Emergency room: EUR 5 co-pay '
          '(insured), EUR 100-300 (uninsured). Hospital day: EUR 2.50/day '
          'co-pay (insured), EUR 150-400 (uninsured).',
      legalBasis: 'Health Insurance Act (Ravikindlustuse seadus), Health '
          'Services Organisation Act (Tervishoiuteenuste korraldamise seadus), '
          'Act on Granting International Protection to Aliens '
          '(Välismaalasele rahvusvahelise kaitse andmise seadus).',
      mentalHealthCrisisLine: '116 123 (Emotional Support Line, 24/7, free). '
          '116 111 (Lasteabi - children\'s helpline, 24/7). '
          '655 8088 (Ohvriabi - victim support).',
      ehcardHowToGet: 'Request EHIC at EHIF (Haigekassa) office or online '
          'at haigekassa.ee. Need valid health insurance status and Estonian '
          'ID code. Free. Processing: up to 14 days.',
      vaccinationProgram: 'Free national immunization program for all children. '
          'Covers DTaP, polio, MMR, Hep B, Hib, pneumococcal. Administered '
          'by family doctors and school nurses.',
      mustTreatHospitals: [
        'All hospital emergency departments (Erakorraline meditsiini osakond)',
        'Põhja-Eesti Regionaalhaigla (North Estonia Medical Centre, Tallinn)',
        'Tartu Ülikooli Kliinikum (Tartu University Hospital)',
        'Ida-Tallinna Keskhaigla',
        'Pärnu Haigla',
      ],
      immigrantSpecificNotes: 'Estonia has a digital-first healthcare system. '
          'e-Residency does NOT grant health insurance - only actual residence '
          'and employment does. Russian-speaking medical staff available in '
          'many facilities. EU citizens use EHIC; if working, register for '
          'EHIF. Small refugee population means fewer specialized services.',
    ),

    // -------------------------------------------------------
    // 9. FINLAND
    // -------------------------------------------------------
    HealthcareAccess(
      country: 'Finland',
      countryCode: 'FI',
      emergencyFree: true,
      emergencyNumber: '112',
      healthInsuranceSystem: 'Tax-funded public healthcare (Beveridge model) '
          'via municipalities/wellbeing services counties (hyvinvointialueet '
          'since 2023). Additionally, Kela (Social Insurance Institution) '
          'provides sickness insurance reimbursements for private care.',
      ehcardAccepted: true,
      undocumentedAccess: 'Since 2023, undocumented persons can access '
          'essential healthcare (not just emergency) including maternity '
          'care, child healthcare, and communicable disease treatment. '
          'Emergency care always provided. Municipalities/regions may '
          'provide broader access. Global Clinic (Helsinki) provides '
          'free care for undocumented.',
      asylumSeekerAccess: 'Asylum seekers receive healthcare organized by '
          'the Finnish Immigration Service (Migri) through reception centers. '
          'Includes: health screening at arrival, urgent and essential care, '
          'maternity care, child healthcare, mental health assessment. '
          'After municipality placement: broader access similar to residents.',
      mentalHealthAccess: 'Public mental health services through health centers '
          '(terveyskeskus) and psychiatric polyclinics. Long waiting times '
          'common (months). Private psychotherapy partially reimbursed by '
          'Kela. Asylum seekers: mental health screening and crisis '
          'intervention through reception centers. PALOMA project provides '
          'specialized refugee mental health training.',
      maternityAccess: 'Renowned maternity care system. Neuvola (maternity and '
          'child health clinics) provide free prenatal and postnatal care for '
          'all residents. Famous maternity package (äitiyspakkaus). Asylum '
          'seekers receive maternity care. Undocumented pregnant women '
          'entitled to essential maternity care.',
      childrenAccess: 'Comprehensive free child healthcare through neuvola '
          'system from birth to school age, then school health services. '
          'All children receive free vaccinations. Children of asylum seekers '
          'receive full child healthcare. Undocumented children entitled to '
          'essential care.',
      registrationProcess: 'Register at local wellbeing services county '
          '(hyvinvointialue) health center with municipality of residence, '
          'Kela card (apply at kela.fi with residence permit and Finnish '
          'personal ID, henkilötunnus). Choose a health center or get '
          'assigned one.',
      freeClinicInfo: 'Global Clinic (Helsinki, Sörnäisten rantatie 27, Tuesdays) '
          '- free care for undocumented migrants, no questions asked. '
          'Global Clinic Turku and Oulu operate similarly. Diakonissalaitos '
          'health services for vulnerable groups. Finnish Red Cross refugee '
          'health support.',
      costEstimate: 'Public health center visit: EUR 20.90 (annual cap EUR 41.80). '
          'Hospital outpatient: EUR 41.80/visit. Hospital inpatient: EUR 49.60/'
          'day. Annual ceiling: EUR 692 (2024). Without Kela/registration: '
          'private GP EUR 80-150, specialist EUR 100-300.',
      legalBasis: 'Health Care Act (Terveydenhuoltolaki 1326/2010), Act on the '
          'Reception of Applicants for International Protection '
          '(Laki kansainvälistä suojelua hakevan vastaanotosta 746/2011), '
          'Act on Public Health (66/1972).',
      mentalHealthCrisisLine: '09 2525 0111 (Kriisipuhelin, MIELI Mental Health '
          'Finland, 24/7, free). 116 111 (Lasten ja nuorten puhelin - '
          'children/youth). 0800 98 800 (Rikosuhripäivystys - crime victim '
          'support).',
      ehcardHowToGet: 'Request EHIC from Kela online at kela.fi/asiointi, by '
          'phone (020 634 0200), or at Kela office. Need Kela health insurance '
          'coverage (based on residence). Free. Processing: 1-2 weeks.',
      vaccinationProgram: 'Free national vaccination program for all children '
          'regardless of status. Covers DTaP, polio, MMR, Hep B, rotavirus, '
          'HPV, influenza. Administered at neuvola and school health services. '
          'Catch-up vaccination available for immigrant children.',
      mustTreatHospitals: [
        'All public hospital emergency departments (Päivystys)',
        'HUS Meilahti (Helsinki University Hospital)',
        'TYKS (Turku University Hospital)',
        'TAYS (Tampere University Hospital)',
        'OYS (Oulu University Hospital)',
        'KYS (Kuopio University Hospital)',
      ],
      immigrantSpecificNotes: 'Finland has strong protections for children and '
          'pregnant women regardless of status. The neuvola system is uniquely '
          'comprehensive. Global Clinic is the key resource for undocumented '
          'persons. Getting a henkilötunnus (personal ID number) and Kela card '
          'are the critical first steps for legal residents. Interpreting '
          'services available in public healthcare (guaranteed by law). '
          'OmaKanta (kanta.fi) is the digital health portal.',
    ),

    // -------------------------------------------------------
    // 10. FRANCE
    // -------------------------------------------------------
    HealthcareAccess(
      country: 'France',
      countryCode: 'FR',
      emergencyFree: true,
      emergencyNumber: '112 / 15 (SAMU) / 114 (SMS for deaf)',
      healthInsuranceSystem: 'Universal health insurance (Sécurité sociale). '
          'Assurance Maladie covers all legal residents. Funded by employer/'
          'employee contributions and taxes (CSG). Complémentaire santé '
          'solidaire (CSS) for low-income. France has one of the best '
          'healthcare access systems for immigrants globally.',
      ehcardAccepted: true,
      undocumentedAccess: 'AME (Aide Médicale de l\'État) covers undocumented '
          'persons who have been in France >3 months and have income below '
          'threshold (~EUR 810/month for single person). AME covers: GP, '
          'specialist, hospital, prescriptions, dental, maternity - nearly '
          'the same as Assurance Maladie. Apply at CPAM. For those <3 months: '
          'emergency care (soins urgents) provided free.',
      asylumSeekerAccess: 'Asylum seekers receive full Assurance Maladie '
          'coverage from the date of asylum application (attestation de '
          'demande d\'asile). Entitled to Protection Universelle Maladie '
          '(PUMa) + CSS. Same coverage as French residents including GP, '
          'specialist, hospital, prescriptions, dental, optical.',
      mentalHealthAccess: 'Covered by Assurance Maladie. MonPsy program: 8 '
          'free psychologist sessions/year with GP referral. CMPs (Centres '
          'Médico-Psychologiques) provide free psychiatric care. EMPPs '
          '(Équipes Mobiles Psychiatrie Précarité) for vulnerable populations. '
          'Asylum seekers: Centre Primo Levi (Paris), COMEDE national network.',
      maternityAccess: 'Full maternity care for all insured women with 100% '
          'coverage from 6th month pregnancy to 12 days postpartum. PMI '
          '(Protection Maternelle et Infantile) provides free prenatal/'
          'postnatal care for ALL women regardless of status. AME covers '
          'maternity for undocumented women.',
      childrenAccess: 'All children have access to PMI (Protection Maternelle '
          'et Infantile) regardless of parents\' status - free medical '
          'check-ups, vaccinations, developmental monitoring up to age 6. '
          'School health services (médecine scolaire) for all enrolled '
          'children. ASE (Aide Sociale à l\'Enfance) for unaccompanied '
          'minors.',
      registrationProcess: 'Register with CPAM (Caisse Primaire d\'Assurance '
          'Maladie) at ameli.fr or local office. Need: ID, proof of '
          'residence, proof of stable residence >3 months, bank details (RIB). '
          'PUMa (Protection Universelle Maladie) covers all legal residents. '
          'Choose a médecin traitant (treating doctor) for pathway of care.',
      freeClinicInfo: 'Médecins du Monde (Paris: 8 Rue Orfila, and 25+ cities). '
          'PASS (Permanences d\'Accès aux Soins de Santé) - free care units '
          'inside public hospitals in every department. PMI clinics in every '
          'commune (free maternal/child care). Centres de Santé municipaux. '
          'COMEDE (Hôpital Bicêtre) - specialized migrant health.',
      costEstimate: 'GP visit: EUR 26.50 (tarif conventionné, reimbursed 70% '
          'by Assurance Maladie). Specialist: EUR 30-55. Emergency room: '
          'free at public hospitals for insured. Hospital day: EUR 20 forfait '
          'journalier. With CSS (low-income): zero co-pay. AME: zero co-pay.',
      legalBasis: 'Code de la Sécurité sociale Art. L160-1 (PUMa), Art. L251-1 '
          '(AME), Code de l\'action sociale Art. L254-1, CESEDA Art. L744-6 '
          '(asylum seeker healthcare), Code de la santé publique.',
      mentalHealthCrisisLine: '3114 (National Suicide Prevention, 24/7, free). '
          'SOS Amitié: 09 72 39 40 50. Fil Santé Jeunes: 0 800 235 236 '
          '(youth, free). SOS Psychiatrie: 01 45 39 40 00 (Île-de-France).',
      ehcardHowToGet: 'Request EHIC (CEAM - Carte Européenne d\'Assurance '
          'Maladie) at ameli.fr account, Ameli app, or by calling CPAM. '
          'Free. Processing: instant digital certificate, physical card '
          '2 weeks. Valid 2 years.',
      vaccinationProgram: 'Free mandatory vaccinations for all children '
          '(11 vaccines mandatory since 2018): DTaP, Hep B, Hib, pneumococcal, '
          'meningococcal C, MMR. Available at PMI (free), GP, pharmacies. '
          'Catch-up schedules available for immigrant children at PASS/PMI.',
      mustTreatHospitals: [
        'ALL public hospitals must treat emergencies (obligation de soins)',
        'Every public hospital has a PASS (free care unit)',
        'AP-HP hospitals (Paris: Bichat, Lariboisière, Saint-Louis, etc.)',
        'Hospices Civils de Lyon',
        'AP-HM (Marseille)',
        'CHU Toulouse, Bordeaux, Lille, Strasbourg, Nantes',
      ],
      immigrantSpecificNotes: 'France has one of the most comprehensive '
          'healthcare systems for immigrants in the world. Key resources: '
          '1) PASS units in every public hospital (free care). '
          '2) PMI for all mothers/children (free, no status check). '
          '3) AME for undocumented (apply at CPAM). '
          '4) Médecins du Monde clinics. '
          'IMPORTANT: Medical professionals have professional secrecy '
          '(secret médical) and CANNOT share patient info with police or '
          'immigration. Interpreting available at public hospitals.',
    ),

    // -------------------------------------------------------
    // 11. GERMANY
    // -------------------------------------------------------
    HealthcareAccess(
      country: 'Germany',
      countryCode: 'DE',
      emergencyFree: true,
      emergencyNumber: '112 / 116 117 (non-emergency medical on-call)',
      healthInsuranceSystem: 'Dual system: Gesetzliche Krankenversicherung (GKV, '
          'statutory, ~87% of population) and Private Krankenversicherung (PKV, '
          'private, ~11%). GKV mandatory for employees earning under EUR 69,300/'
          'year. ~110 statutory funds (Krankenkassen): TK, Barmer, AOK, DAK, etc.',
      ehcardAccepted: true,
      undocumentedAccess: 'Undocumented persons entitled to emergency care and '
          'treatment of acute illness and pain under AsylbLG §1a/§4. In '
          'practice, access is difficult due to Übermittlungspflicht '
          '(reporting obligation) when applying for social welfare payment. '
          'Exception: cities with anonymous health certificates (Clearingstellen) '
          '- Berlin, Hamburg, Munich, Frankfurt. Malteser Migranten Medizin '
          'and Medibüros provide free anonymous care.',
      asylumSeekerAccess: 'First 18 months: restricted care under AsylbLG §4 '
          '(acute illness, pain, pregnancy, vaccinations, preventive care). '
          'After 18 months: equivalent to GKV under AsylbLG §2 (full statutory '
          'coverage). Some federal states issue electronic health cards from '
          'day one (Bremen, Hamburg, Berlin, NRW cities) - equivalent to GKV.',
      mentalHealthAccess: 'GKV covers psychotherapy (behavioral, psychoanalytic, '
          'systemic) with approval - but waiting times 3-9 months. Emergency '
          'psychiatric care immediate. Asylum seekers: psychotherapy covered '
          'under AsylbLG §6 with application. BAfF (Bundesweite '
          'Arbeitsgemeinschaft der psychosozialen Zentren für Flüchtlinge) '
          'coordinates 46+ psychosocial centers for refugees.',
      maternityAccess: 'Full maternity care for insured women: prenatal, birth, '
          'postnatal, midwife care. Asylum seekers: maternity care from day one '
          'under AsylbLG §4. Undocumented pregnant women: entitled to care '
          '6 weeks before to 8 weeks after birth (apply through Sozialamt '
          'without immigration consequences). Schwangerschaftsberatung '
          '(pregnancy counseling) available anonymously.',
      childrenAccess: 'All insured children receive comprehensive care. Asylum '
          'seeker children: essential care from day one. STIKO (vaccination '
          'commission) recommendations apply to all children. School health '
          'services (Schuleingangsuntersuchung) for all enrolled children. '
          'Unaccompanied minors receive full GKV-equivalent coverage.',
      registrationProcess: 'GKV: automatic enrollment via employer. Choose from '
          '~110 Krankenkassen (all provide same basic coverage). Need: '
          'Anmeldung (address registration), employment contract or '
          'self-employment proof. Freelancers/students: self-register at '
          'chosen Krankenkasse. Minimum contribution ~EUR 200/month.',
      freeClinicInfo: 'Malteser Migranten Medizin (15+ cities: Berlin, Munich, '
          'Frankfurt, Cologne, Hamburg, etc.) - free anonymous care. '
          'Medibüros/Medinetze (Berlin Kreuzberg, Hamburg, many cities) - '
          'anonymous medical referral. Clearingstellen (Berlin, Munich) - '
          'anonymous health certificates. Ärzte der Welt (Munich). Open.Med '
          '(Munich, Dachauer Str. 161). Praxis ohne Grenzen (Hamburg).',
      costEstimate: 'GP visit: EUR 30-70 (free with GKV). Specialist: '
          'EUR 60-150. Emergency room: EUR 100-500. Hospital day: EUR 10/day '
          'co-pay with GKV (max 28 days/year), full cost EUR 300-800/day. '
          'Prescriptions: EUR 5-10 co-pay with GKV.',
      legalBasis: 'Sozialgesetzbuch V (SGB V - statutory health insurance), '
          'Asylbewerberleistungsgesetz (AsylbLG §4, §6, §2), '
          'Aufenthaltsgesetz (AufenthG), Infektionsschutzgesetz (IfSG).',
      mentalHealthCrisisLine: '0800 111 0 111 (Telefonseelsorge, 24/7, free). '
          '0800 111 0 222 (Telefonseelsorge, 24/7, free). '
          '0800 655 3000 (Hilfetelefon Gewalt gegen Frauen). '
          '116 111 (Kinder- und Jugendtelefon).',
      ehcardHowToGet: 'Request EHIC from your Krankenkasse (TK, AOK, Barmer, '
          'etc.) online, via app, or at service center. Free. Processing: '
          '1-2 weeks. Valid for duration of insurance membership.',
      vaccinationProgram: 'STIKO-recommended vaccinations free for all children '
          'through GKV. Covers DTaP, polio, MMR, Hep B, HPV, varicella, '
          'rotavirus, meningococcal. Asylum seekers: catch-up vaccination '
          'at initial health screening (Erstuntersuchung). '
          'Available at pediatricians, GPs, and public health offices.',
      mustTreatHospitals: [
        'All hospital emergency departments (Notaufnahme)',
        'Charité (Berlin) - largest university hospital in Europe',
        'Universitätsklinikum Hamburg-Eppendorf (UKE)',
        'LMU Klinikum München',
        'Universitätsklinikum Frankfurt',
        'Universitätsklinikum Köln',
        'Universitätsklinikum Heidelberg',
      ],
      immigrantSpecificNotes: 'Germany\'s dual-track system for asylum seekers '
          '(restricted first 18 months) is widely criticized. KEY TIP: In '
          'cities with electronic health cards (eGK) for asylum seekers '
          '(Bremen, Hamburg, Berlin, Thüringen), access is much easier - '
          'go directly to any doctor. In other areas, must get '
          'Behandlungsschein (treatment voucher) from Sozialamt first. '
          'Malteser Migranten Medizin and Medibüros are critical for '
          'undocumented persons. Interpreting NOT routinely provided - '
          'bring your own or ask for Gemeindedolmetscherdienst.',
    ),

    // -------------------------------------------------------
    // 12. GREECE
    // -------------------------------------------------------
    HealthcareAccess(
      country: 'Greece',
      countryCode: 'GR',
      emergencyFree: true,
      emergencyNumber: '112 / 166 (ambulance, EKAB)',
      healthInsuranceSystem: 'National public healthcare system (ESY) plus '
          'social insurance (EOPYY). Since 2016, universal coverage for all '
          'legal residents including uninsured Greeks. Funded by taxes and '
          'social contributions.',
      ehcardAccepted: true,
      undocumentedAccess: 'Emergency care provided at public hospitals. Since '
          'Law 4368/2016, uninsured and undocumented persons can access '
          'free healthcare at public facilities (hospitals, health centers) '
          'including: emergencies, maternity, children under 18, '
          'communicable diseases, vaccinations, chronic conditions requiring '
          'immediate treatment. Broader access than most EU countries.',
      asylumSeekerAccess: 'Asylum seekers receive PAAYPA (Provisional Number '
          'of Insurance and Healthcare for Foreigners) giving access to '
          'public healthcare equivalent to insured Greeks. Covers GP, '
          'specialist, hospital, prescriptions, mental health. Healthcare '
          'also provided at reception centers and through UNHCR/NGO partners.',
      mentalHealthAccess: 'Public psychiatric services through ESY. Community '
          'Mental Health Centers (KMPS) in major cities. Asylum seekers and '
          'refugees: MSF (Médecins Sans Frontières), MDM (Médecins du Monde), '
          'Babel Day Centre (Athens), METAdrasi, Praksis - all provide free '
          'mental health support including interpreting.',
      maternityAccess: 'Full maternity care at public hospitals free for all '
          'women regardless of status (Law 4368/2016). Includes prenatal, '
          'delivery, postnatal. Maternity protection for asylum seekers '
          'from registration. NGOs support prenatal care for refugee women.',
      childrenAccess: 'All children under 18 entitled to free healthcare at '
          'public facilities regardless of parents\' status. Free vaccinations '
          'at public health centers. School health programs. Pediatric care '
          'at public hospitals. NGOs provide extensive children\'s health '
          'programs in refugee settings.',
      registrationProcess: 'Register with EOPYY via employer or at local EOPYY '
          'office. Need AMKA (social security number) or PAAYPA (for '
          'third-country nationals). Apply at KEP (Citizens Service Centers) '
          'or EOPYY offices. Asylum seekers get PAAYPA at registration.',
      freeClinicInfo: 'Médecins du Monde (Athens: Sapfous 12, Thessaloniki, '
          'islands). Praksis (Athens: Stournari 57, Thessaloniki). '
          'KYADA Municipality Social Clinics (Athens). Metropolitan '
          'Community Clinic at Elliniko. MSF clinics on islands and '
          'mainland. Babel Day Centre (Athens - psychosocial). '
          'Social pharmacies in several municipalities.',
      costEstimate: 'Public hospital: free for insured/AMKA holders. '
          'EUR 5 outpatient co-pay. Without AMKA: emergency free, other '
          'services may require PAAYPA. Private GP: EUR 30-80. '
          'Private specialist: EUR 50-150. Private hospital: EUR 200-800/day.',
      legalBasis: 'Law 4368/2016 (universal healthcare access), Law 4636/2019 '
          '(International Protection), Presidential Decree 141/2013 '
          '(Reception Conditions Directive transposition), ESY Law 1397/1983.',
      mentalHealthCrisisLine: '1018 (Suicide Prevention Line, EPY). '
          '10306 (EKKA Immediate Social Assistance). '
          '116 111 (Children\'s helpline). '
          '15900 (Domestic violence helpline).',
      ehcardHowToGet: 'Request EHIC at EOPYY office or online at eopyy.gov.gr. '
          'Need AMKA and valid insurance status. Free. Processing: 1-3 weeks.',
      vaccinationProgram: 'National vaccination program free for all children '
          'at public health centers regardless of status. Special catch-up '
          'programs for refugee/migrant children. Covers DTaP, MMR, polio, '
          'Hep B, pneumococcal, meningococcal. Available at KEFI health '
          'centers and NGO vaccination points.',
      mustTreatHospitals: [
        'All public hospitals (Δημόσια Νοσοκομεία) must treat emergencies',
        'Evangelismos Hospital (Athens)',
        'Attikon University Hospital (Athens)',
        'AHEPA University Hospital (Thessaloniki)',
        'General Hospital of Thessaloniki Papageorgiou',
        'University Hospital of Heraklion (Crete)',
      ],
      immigrantSpecificNotes: 'Greece, as a frontline EU state, has extensive '
          'NGO healthcare infrastructure for migrants. Law 4368/2016 '
          'significantly expanded access. In practice, public hospitals on '
          'islands and Athens may be overwhelmed. Key: get PAAYPA number as '
          'soon as possible after registration. MSF, MDM, and Praksis are '
          'the main healthcare NGOs. Interpreting available through '
          'METAdrasi at many healthcare facilities.',
    ),

    // -------------------------------------------------------
    // 13. HUNGARY
    // -------------------------------------------------------
    HealthcareAccess(
      country: 'Hungary',
      countryCode: 'HU',
      emergencyFree: true,
      emergencyNumber: '112 / 104 (ambulance)',
      healthInsuranceSystem: 'National Health Insurance Fund (NEAK, formerly '
          'OEP). Mandatory social insurance funded by employer/employee '
          'contributions. Covers ~95% of population. Significant informal '
          'payments (hálapénz/gratitude money) historically common.',
      ehcardAccepted: true,
      undocumentedAccess: 'Emergency care must be provided. Undocumented persons '
          'have access to emergency and life-saving care only. No public '
          'insurance access. Limited NGO support. Since 2015 border crisis, '
          'increasingly restrictive approach to migrant healthcare.',
      asylumSeekerAccess: 'Very restricted since 2020 border procedure changes. '
          'Asylum seekers who manage to register receive limited healthcare '
          'through the Immigration and Asylum Office. In practice, few asylum '
          'seekers are in Hungary due to border closure policies. Those in '
          'reception receive basic medical care at facility.',
      mentalHealthAccess: 'Psychiatric care covered by NEAK with referral. '
          'Community mental health services underdeveloped. Psychotherapy '
          'partially covered (limited sessions). For refugees/asylum seekers: '
          'Cordelia Foundation provides free psychotherapy. Menedék '
          '(Hungarian Association for Migrants) offers psychosocial support.',
      maternityAccess: 'Full maternity care for insured women: prenatal '
          'monitoring, hospital birth, postnatal care. Uninsured women '
          'receive emergency obstetric care. Asylum-seeking women: '
          'maternity care provided. Védőnő (district nurse) system provides '
          'home visits for pregnant women and new mothers.',
      childrenAccess: 'All children in Hungary are entitled to healthcare '
          'regardless of insurance status (under 18). Free vaccinations '
          'mandatory for all children. Védőnő system monitors all '
          'children. School health services available.',
      registrationProcess: 'Registration through employer (automatic with '
          'employment). Self-registration at NEAK with TAJ number (social '
          'security number). Need: residence permit, address card, TAJ '
          'application at Government Window (Kormányablak). Choose a '
          'GP (háziorvos) in your district.',
      freeClinicInfo: 'Cordelia Foundation (Budapest) - free psychotherapy for '
          'torture survivors and refugees. Menedék Association (Budapest) - '
          'integration support. Hungarian Helsinki Committee - legal and '
          'health access support. Maltese Charity Service - social '
          'assistance. Red Cross Hungary - limited health programs.',
      costEstimate: 'GP visit (insured): free. Without insurance: '
          'HUF 5,000-15,000 (EUR 13-38). Specialist: HUF 10,000-30,000 '
          '(EUR 25-76). Emergency room: free for emergencies. Hospital '
          'day: HUF 2,000/day co-pay (insured), HUF 30,000-80,000/day '
          '(EUR 76-203, uninsured).',
      legalBasis: 'Act LXXX of 1997 on Social Insurance Healthcare, '
          'Act LXXX of 2007 on Asylum, Government Decree 301/2007 on '
          'reception conditions, Health Act CLIV of 1997.',
      mentalHealthCrisisLine: '116 123 (Lelki Elsősegély, emotional support). '
          '116 111 (Kék Vonal - children\'s helpline). '
          '06 80 505 678 (OORI Crisis helpline, free).',
      ehcardHowToGet: 'Request EHIC at NEAK office or online at neak.gov.hu. '
          'Need valid TAJ number and insurance status. Free. Processing: '
          'up to 15 working days.',
      vaccinationProgram: 'Mandatory vaccination program for all children '
          'in Hungary (one of the strictest in EU). Covers BCG, DTaP, '
          'polio, MMR, Hep B. Administered by védőnő and district GPs. '
          'Non-compliance can result in administrative fines.',
      mustTreatHospitals: [
        'All hospital emergency departments (Sürgősségi Betegellátó Osztály)',
        'Szent János Kórház (Budapest)',
        'Semmelweis University Hospitals (Budapest)',
        'Honvédkórház (Budapest)',
        'University of Pécs Clinical Centre',
        'University of Debrecen Clinical Centre',
      ],
      immigrantSpecificNotes: 'Hungary has become one of the most restrictive '
          'EU countries for asylum seekers since 2015. The border procedure '
          'and "transit zone" system (struck down by CJEU in 2020) has been '
          'replaced by embassy-based asylum application, making it nearly '
          'impossible to apply from within Hungary. For those already present: '
          'Hungarian Helsinki Committee is the key legal/healthcare access '
          'organization. EU citizens use EHIC; if working, register for TAJ.',
    ),

    // -------------------------------------------------------
    // 14. IRELAND
    // -------------------------------------------------------
    HealthcareAccess(
      country: 'Ireland',
      countryCode: 'IE',
      emergencyFree: true,
      emergencyNumber: '112 / 999',
      healthInsuranceSystem: 'Mixed public/private system. HSE (Health Service '
          'Executive) provides public healthcare. Medical Card holders (income '
          '<~EUR 184/week single) receive free care. GP Visit Card for '
          'ages <8 and >70. ~46% have private health insurance (VHI, Laya, '
          'Irish Life).',
      ehcardAccepted: true,
      undocumentedAccess: 'Emergency care provided at public hospitals. '
          'Undocumented persons can access emergency departments (A&E) '
          'at any public hospital without being refused. Beyond emergencies: '
          'limited to HSE emergency services. Safetynet Primary Care '
          '(Dublin) provides free GP care to homeless and undocumented. '
          'No comprehensive AME-type system.',
      asylumSeekerAccess: 'Asylum seekers (International Protection Applicants) '
          'receive a Medical Card from HSE providing full access to public '
          'healthcare: GP visits, hospital care, prescriptions, dental, '
          'optical, mental health. Same entitlements as Medical Card holders. '
          'Healthcare at Direct Provision centers coordinated by HSE.',
      mentalHealthAccess: 'Public mental health services through HSE Community '
          'Mental Health Teams. Free for Medical Card holders. Counselling '
          'in Primary Care (CIPC) - free sessions. Asylum seekers: SPIRASI '
          '(Dublin) provides specialized refugee mental health. HSE National '
          'Counselling Service available.',
      maternityAccess: 'Maternity care free for ALL women in Ireland regardless '
          'of status through the Maternity and Infant Care Scheme. Covers: '
          'GP antenatal visits, hospital care, public consultant care, '
          'postnatal check-up. No Medical Card needed. Asylum seekers: '
          'full maternity care.',
      childrenAccess: 'Free GP care for all children under 8 (GP Visit Card). '
          'All children of asylum seekers covered by Medical Card. National '
          'immunization program free for all children. School health '
          'services. Tusla (Child and Family Agency) supports vulnerable '
          'children regardless of status.',
      registrationProcess: 'Apply for Medical Card at HSE (medicalcard.ie) '
          'if income below threshold. Apply for GP Visit Card if over/under '
          'age thresholds. Register with a GP (some require Medical Card). '
          'Need PPS number (apply at MyWelfare.ie with ID and proof of '
          'address). EU citizens: EHIC for visits; register for PPS if '
          'working.',
      freeClinicInfo: 'Safetynet Primary Care (Dublin, various locations) - '
          'free GP for homeless/undocumented. Capuchin Day Centre (Dublin, '
          'Bow St) - meals and health referrals. Depaul medical services '
          '(Dublin). SPIRASI (Dublin, 213 North Circular Road) - refugee '
          'rehabilitation. Doctors of the World/Médecins du Monde Ireland '
          '(limited operations).',
      costEstimate: 'GP visit: EUR 50-70 (free with Medical Card). '
          'A&E without GP referral: EUR 100. Hospital stay: EUR 80/night '
          '(max 10 nights/year, free with Medical Card). Specialist (private): '
          'EUR 150-300. Prescriptions: EUR 1.50/item with Medical Card.',
      legalBasis: 'Health Act 1970 (Medical Card), Health (Amendment) Act 2013, '
          'International Protection Act 2015, Maternity and Infant Care '
          'Scheme (Dept. of Health circular).',
      mentalHealthCrisisLine: '116 123 (Samaritans Ireland, 24/7, free). '
          '1800 111 888 (Aware - depression support). '
          '116 111 (Childline, 24/7). '
          '1800 742 842 (Console suicide bereavement).',
      ehcardHowToGet: 'Request EHIC from HSE online at ehic.ie or by calling '
          '1890 252 919. Need PPS number and habitual residency. Free. '
          'Processing: 10 working days.',
      vaccinationProgram: 'Free Primary Childhood Immunisation Programme for '
          'all children at 2, 4, 6, 12, 13 months and 4-5 years. Covers '
          'DTaP, polio, MMR, Hep B, Hib, meningococcal, pneumococcal, '
          'rotavirus. Given at GP surgery. School-based HPV and Tdap '
          'boosters. Available regardless of status.',
      mustTreatHospitals: [
        'All public hospital Emergency Departments',
        'Mater Misericordiae (Dublin)',
        'St James\'s Hospital (Dublin)',
        'Beaumont Hospital (Dublin)',
        'Cork University Hospital',
        'University Hospital Galway',
        'University Hospital Limerick',
      ],
      immigrantSpecificNotes: 'Ireland\'s Maternity and Infant Care Scheme is '
          'uniquely accessible - ALL women regardless of status get free '
          'maternity care. The Medical Card is the key to healthcare access. '
          'Asylum seekers in Direct Provision receive Medical Cards '
          'automatically. PPS number is essential for all interactions. '
          'Habitual Residency Condition (HRC) is the main barrier for EU '
          'citizens - must prove intention to stay. Free interpreting in '
          'public hospitals is improving but inconsistent.',
    ),

    // -------------------------------------------------------
    // 15. ITALY
    // -------------------------------------------------------
    HealthcareAccess(
      country: 'Italy',
      countryCode: 'IT',
      emergencyFree: true,
      emergencyNumber: '112 / 118 (ambulance)',
      healthInsuranceSystem: 'Servizio Sanitario Nazionale (SSN) - universal '
          'tax-funded national health service (Beveridge model). Managed '
          'regionally (20 regions + autonomous provinces). All legal residents '
          'enrolled via tessera sanitaria. Co-payments (ticket) for some '
          'services.',
      ehcardAccepted: true,
      undocumentedAccess: 'Italy has one of the best systems for undocumented '
          'migrants. STP code (Straniero Temporaneamente Presente) provides '
          'access to: emergency care, essential care, pregnancy/maternity, '
          'child health, vaccinations, communicable disease treatment, '
          'addiction treatment, mental health emergencies. Available at any '
          'ASL (Local Health Authority). NO reporting to police.',
      asylumSeekerAccess: 'Asylum seekers receive SSN enrollment (tessera '
          'sanitaria) from the moment of asylum application. Full access '
          'identical to Italian citizens: GP (medico di base), specialist, '
          'hospital, prescriptions, dental, mental health, preventive care.',
      mentalHealthAccess: 'Public mental health through CSM (Centri di Salute '
          'Mentale) and DSM (Dipartimenti di Salute Mentale) - free with SSN. '
          'Italy closed psychiatric hospitals in 1978 (Basaglia Law) and has '
          'community-based system. Asylum seekers: full access to CSM. '
          'Numerous NGOs provide ethno-psychiatry. STP holders can access '
          'emergency mental health.',
      maternityAccess: 'Full maternity care for ALL women regardless of status '
          'under Italian law. STP code covers entire pregnancy, delivery, '
          'and postnatal period. Consultori familiari (family planning clinics) '
          'provide free prenatal care to all women. ASL services accessible. '
          'Hospital delivery free for everyone.',
      childrenAccess: 'All children under 18 entitled to SSN enrollment '
          'regardless of parents\' status (Law 286/1998 Art. 35). Free '
          'vaccinations for all children. Pediatra di libera scelta (family '
          'pediatrician) for all enrolled children. STP covers child health '
          'comprehensively.',
      registrationProcess: 'Register at local ASL (Azienda Sanitaria Locale) '
          'with codice fiscale, residence permit, and proof of address. '
          'Choose a medico di base (GP) or pediatra for children. Receive '
          'tessera sanitaria (health card). EU citizens: register at ASL '
          'with codice fiscale and EHIC or A1 form.',
      freeClinicInfo: 'Emergency (SIMM) network coordinates migrant health '
          'across Italy. Caritas medical clinics in major cities (Rome: '
          'Poliambulatorio Caritas, Via Marsala 97). Médecins Sans '
          'Frontières (southern Italy). NAGA (Milan, Via Zamenhof 7A) - '
          'free care for undocumented. Doctors for Human Rights (MEDU). '
          'EMERGENCY ONG (various cities). Consultori familiari (free, '
          'in every ASL).',
      costEstimate: 'GP visit (SSN): free. Specialist with SSN referral: '
          'EUR 36.15 ticket (exemptions for income, age, condition). '
          'Emergency room: EUR 25 white code (non-urgent). Hospital stay '
          '(SSN): free. Without SSN: GP EUR 50-100, Specialist EUR 80-200, '
          'Private hospital EUR 300-1000/day.',
      legalBasis: 'Testo Unico Immigrazione (D.Lgs. 286/1998 Art. 34-36), '
          'D.Lgs. 142/2015 (reception conditions), Legge 833/1978 (SSN), '
          'Circolare Min. Sanità 5/2000 (STP procedures).',
      mentalHealthCrisisLine: '800 274 274 (Telefono Amico, free). '
          '06 77208977 (Telefono Azzurro - children). '
          '1696 (Telefono Azzurro emergency). '
          '800 86 00 22 (Anti-violence number).',
      ehcardHowToGet: 'Request EHIC (TEAM - Tessera Europea di Assicurazione '
          'Malattia) at ASL or online at fascicolosanitario.gov.it. Need '
          'tessera sanitaria and codice fiscale. Free. Processing: instant '
          'provisional certificate, physical card 2-4 weeks.',
      vaccinationProgram: 'National Plan of Vaccine Prevention (PNPV). 10 '
          'mandatory vaccines for all children (Law 119/2017): polio, '
          'diphtheria, tetanus, pertussis, Hep B, Hib, measles, mumps, '
          'rubella, varicella. Free for all children regardless of status. '
          'Available at ASL vaccination centers.',
      mustTreatHospitals: [
        'ALL public hospitals MUST treat with STP code (no status check)',
        'Policlinico Umberto I (Rome)',
        'Ospedale Niguarda (Milan)',
        'Policlinico di Milano',
        'Ospedale Maggiore (Bologna)',
        'Policlinico di Napoli',
        'Ospedale Civile (Palermo)',
      ],
      immigrantSpecificNotes: 'Italy\'s STP system is a model for undocumented '
          'migrant healthcare in the EU. KEY: Go to any ASL and request an '
          'STP code - this is free, anonymous, and valid for 6 months '
          '(renewable). Medical facilities CANNOT report undocumented '
          'patients to police (Art. 35 comma 5 TU). Regional variation '
          'is significant - northern regions generally better organized. '
          'Cultural mediators (mediatori culturali) available at many '
          'hospitals. NAGA (Milan) and Caritas are the key NGOs for '
          'undocumented healthcare.',
    ),

    // -------------------------------------------------------
    // 16. LATVIA
    // -------------------------------------------------------
    HealthcareAccess(
      country: 'Latvia',
      countryCode: 'LV',
      emergencyFree: true,
      emergencyNumber: '112 / 113 (ambulance)',
      healthInsuranceSystem: 'Tax-funded public healthcare through National '
          'Health Service (NVD). All residents with personal code registered '
          'with a GP are entitled. Two-tier system: state-guaranteed basket '
          'of services and patient co-payments. Significant out-of-pocket '
          'costs.',
      ehcardAccepted: true,
      undocumentedAccess: 'Emergency care must be provided. Undocumented persons '
          'must pay for non-emergency care. Very limited NGO healthcare '
          'support. Red Cross Latvia provides some assistance.',
      asylumSeekerAccess: 'Asylum seekers receive state-funded healthcare '
          'including emergency care, maternity, children\'s health, and '
          'necessary medical treatment. Organized through the Office of '
          'Citizenship and Migration Affairs (PMLP) and designated medical '
          'providers. Mental health support included.',
      mentalHealthAccess: 'Public psychiatric services available with referral. '
          'Community mental health developing. Psychologist visits not '
          'covered by public system (private: EUR 40-70/session). '
          'Asylum seekers: psychological support through reception system. '
          'Crisis helplines available.',
      maternityAccess: 'Maternity care covered for registered residents: '
          'prenatal visits, hospital delivery, postnatal care. Asylum seekers '
          'receive maternity care. Uninsured women receive emergency obstetric '
          'care at minimum.',
      childrenAccess: 'Children registered with a GP receive free healthcare. '
          'National immunization program free and partially mandatory. '
          'Children of asylum seekers receive healthcare. School health '
          'services available.',
      registrationProcess: 'Register with a family doctor (ģimenes ārsts) at '
          'a primary care practice. Need personal code (personas kods) and '
          'residence registration. Can register online at latvija.lv or at '
          'GP practice. NVD assigns coverage.',
      freeClinicInfo: 'Red Cross Latvia - limited health assistance. '
          'Shelter "Safe House" (Riga) - support for trafficking victims '
          'including health. IOM Latvia - health assessments for refugees. '
          'Limited free clinic infrastructure compared to Western EU.',
      costEstimate: 'GP visit: EUR 1.42 co-pay (registered). Without '
          'registration: EUR 15-40. Specialist: EUR 4.27 co-pay (state). '
          'Emergency room: EUR 14.23 co-pay. Hospital day: EUR 10/day '
          'co-pay. Full cost uninsured: GP EUR 20-50, specialist EUR 40-100.',
      legalBasis: 'Medical Treatment Law (Ārstniecības likums), Law on '
          'Asylum (Patvēruma likums), Cabinet Regulation No. 555 on '
          'healthcare financing, Immigration Law.',
      mentalHealthCrisisLine: '116 123 (Uzticības tālrunis, emotional support). '
          '116 111 (Bērnu uzticības tālrunis - children). '
          '8006 2838 (Crisis helpline).',
      ehcardHowToGet: 'Request EHIC at NVD (National Health Service) office '
          'or online at latvija.lv. Need personal code and registered GP. '
          'Free. Processing: up to 30 days.',
      vaccinationProgram: 'National immunization calendar with mandatory and '
          'recommended vaccines for all children. Covers DTaP, polio, MMR, '
          'Hep B, Hib. Administered by GPs. Available for registered children.',
      mustTreatHospitals: [
        'All hospital emergency departments',
        'Pauls Stradiņš Clinical University Hospital (Riga)',
        'Riga East Clinical University Hospital',
        'Children\'s Clinical University Hospital (Riga)',
        'Liepāja Regional Hospital',
        'Daugavpils Regional Hospital',
      ],
      immigrantSpecificNotes: 'Latvia has relatively high out-of-pocket costs '
          'even for registered residents. Waiting times for specialists can '
          'be long (months). Russian-speaking medical staff widely available. '
          'EU citizens use EHIC; if working, register for personal code and '
          'GP. Small refugee population means fewer specialized services.',
    ),

    // -------------------------------------------------------
    // 17. LITHUANIA
    // -------------------------------------------------------
    HealthcareAccess(
      country: 'Lithuania',
      countryCode: 'LT',
      emergencyFree: true,
      emergencyNumber: '112',
      healthInsuranceSystem: 'Mandatory Health Insurance Fund (PSDF). Social '
          'insurance contributions from employers and employees. State covers '
          'children, students, pensioners, registered unemployed, pregnant '
          'women. Universal coverage goal with co-payments.',
      ehcardAccepted: true,
      undocumentedAccess: 'Emergency care must be provided. Undocumented persons '
          'have no access to public health insurance. Must pay full costs for '
          'non-emergency care. Limited NGO health support through Red Cross '
          'and Caritas Lithuania.',
      asylumSeekerAccess: 'Asylum seekers receive healthcare funded by the state '
          'including emergency care, primary care, maternity, children\'s '
          'health, mental health support, and necessary specialist care. '
          'Organized through the Migration Department and Refugee Reception '
          'Centre (Rukla). Since 2021 Belarus border crisis, expanded '
          'services through UNHCR and NGO partners.',
      mentalHealthAccess: 'Psychiatric care covered by PSDF. Community mental '
          'health centers established in recent reform. Psychotherapy partially '
          'covered. Asylum seekers: psychological support at reception centers '
          'and through NGO partners. Vilnius University Psychotrauma Centre.',
      maternityAccess: 'Full maternity care for insured women. Pregnant women '
          'automatically qualify for state insurance. Asylum seekers receive '
          'maternity care. Prenatal, delivery, and postnatal care covered.',
      childrenAccess: 'All children under 18 covered by state health insurance. '
          'Children of asylum seekers receive full healthcare. Mandatory '
          'vaccination program for all children. School health services.',
      registrationProcess: 'Register at Territorial Health Insurance Fund (TLK) '
          'with personal code (asmens kodas), residence permit, and employment '
          'documentation. Choose a family doctor (šeimos gydytojas) at a '
          'primary health center (poliklinika).',
      freeClinicInfo: 'Lithuanian Red Cross - health assistance for refugees. '
          'Caritas Lithuania (Vilnius, Kaunas) - social and health support. '
          'Vilnius University Psychotrauma Centre - free psychological help '
          'for refugees. Refugee Reception Centre Rukla - on-site medical.',
      costEstimate: 'GP visit (insured): free. Without insurance: EUR 15-40. '
          'Specialist: EUR 5 co-pay (insured), EUR 30-80 (uninsured). '
          'Emergency room: free for emergencies. Hospital day: EUR 50-200 '
          '(uninsured). Lithuania has low healthcare costs by EU standards.',
      legalBasis: 'Health Insurance Law (Sveikatos draudimo įstatymas), '
          'Law on the Legal Status of Aliens (Įstatymas dėl užsieniečių '
          'teisinės padėties), Law on Refugee Status and Asylum.',
      mentalHealthCrisisLine: '116 123 (Jaunimo linija - youth emotional support). '
          '116 111 (Vaikų linija - children\'s helpline). '
          '8 800 28888 (Vilties linija - hope line, 24/7). '
          '8 800 60700 (Pagalbos moterims linija - women).',
      ehcardHowToGet: 'Request EHIC at TLK office or online at vlk.lt. '
          'Need personal code and valid insurance status. Free. '
          'Processing: up to 20 working days.',
      vaccinationProgram: 'National immunization program for all children. '
          'Covers BCG, DTaP, polio, MMR, Hep B, Hib, pneumococcal. '
          'Mandatory for enrollment in educational institutions. '
          'Administered at primary health centers.',
      mustTreatHospitals: [
        'All hospital emergency departments',
        'Vilnius University Hospital Santaros Klinikos',
        'Republican Vilnius University Hospital',
        'Lithuanian University of Health Sciences Hospital (Kaunas)',
        'Klaipėda University Hospital',
      ],
      immigrantSpecificNotes: 'Lithuania saw significant increase in asylum '
          'seekers since 2021 Belarus border crisis. Healthcare infrastructure '
          'for migrants expanded with EU and UNHCR support. Key: register '
          'at Migration Department promptly. Russian and English widely '
          'understood in medical settings. EU citizens use EHIC; workers '
          'register at TLK.',
    ),

    // -------------------------------------------------------
    // 18. LUXEMBOURG
    // -------------------------------------------------------
    HealthcareAccess(
      country: 'Luxembourg',
      countryCode: 'LU',
      emergencyFree: true,
      emergencyNumber: '112',
      healthInsuranceSystem: 'CNS (Caisse Nationale de Santé) - mandatory social '
          'health insurance. Bismarck model with employer/employee '
          'contributions. Very comprehensive coverage (~99% population). '
          'One of the highest healthcare spending per capita in EU.',
      ehcardAccepted: true,
      undocumentedAccess: 'Emergency care provided at hospitals. Undocumented '
          'persons can apply for medical assistance through the social welfare '
          'office (Office social). Covers urgent and necessary care. '
          'Médecins du Monde Luxembourg provides free healthcare to '
          'undocumented persons.',
      asylumSeekerAccess: 'Asylum seekers (DPI - demandeurs de protection '
          'internationale) receive full CNS affiliation from the moment '
          'of application. Same coverage as Luxembourg residents: GP, '
          'specialist, hospital, prescriptions, dental, mental health. '
          'Organized through ONA (Office National de l\'Accueil).',
      mentalHealthAccess: 'Psychiatric care covered by CNS. Psychotherapy '
          'partially reimbursed. Luxembourg has excellent mental health '
          'infrastructure for its size. Asylum seekers: Centre Ulysse '
          '(psychotherapy for refugees), Service de santé mentale '
          'communautaire. Crisis services available 24/7.',
      maternityAccess: 'Full maternity care covered by CNS: prenatal '
          'monitoring, hospital delivery (choice of maternity ward), '
          'postnatal care. Asylum seekers fully covered. Sage-femme '
          '(midwife) home visits covered.',
      childrenAccess: 'All children enrolled in CNS receive comprehensive '
          'pediatric care. Free vaccinations for all children. Children of '
          'asylum seekers fully covered. School health services '
          '(médecine scolaire). Maison de l\'enfant services.',
      registrationProcess: 'Registration with CNS automatic upon starting '
          'employment. Non-employed residents register at CNS office '
          'with residence permit, registration certificate, and CCSS '
          '(Centre Commun de la Sécurité Sociale) number. All family '
          'members can be co-insured.',
      freeClinicInfo: 'Médecins du Monde Luxembourg (free clinic in Luxembourg '
          'City) - free care for uninsured. Croix-Rouge luxembourgeoise '
          '(Red Cross) - refugee health support. Centre Ulysse - free '
          'psychotherapy for refugees. Wanteraktioun (winter action) - '
          'health services for homeless.',
      costEstimate: 'GP visit: EUR 45-55 (reimbursed ~88% by CNS). '
          'Specialist: EUR 50-100 (reimbursed ~88%). Emergency room: '
          'covered by CNS. Hospital day: EUR 25 co-pay/day. Without CNS: '
          'GP EUR 45-55, specialist EUR 50-100, hospital EUR 500-1500/day. '
          'One of the highest reimbursement rates in EU.',
      legalBasis: 'Code de la Sécurité sociale (Book I - Health Insurance), '
          'Loi du 18 décembre 2015 (international protection), '
          'Loi du 29 août 2008 (free movement/immigration).',
      mentalHealthCrisisLine: '454545 (SOS Détresse, 24/7, free). '
          '116 111 (Kanner-Jugendtelefon - children/youth). '
          '12 12 (Femmes en détresse - women in distress).',
      ehcardHowToGet: 'Request EHIC at CNS office or online at cns.lu. '
          'Need valid CNS affiliation. Free. Processing: 1-2 weeks.',
      vaccinationProgram: 'Free recommended vaccination program for all '
          'children. Covers DTaP, polio, MMR, Hep B, Hib, pneumococcal, '
          'HPV, meningococcal. Administered by pediatricians and GPs. '
          'Not mandatory but strongly recommended.',
      mustTreatHospitals: [
        'All hospital emergency departments',
        'Centre Hospitalier de Luxembourg (CHL)',
        'Hôpitaux Robert Schuman',
        'Centre Hospitalier Emile Mayrisch (CHEM, Esch-sur-Alzette)',
        'Centre Hospitalier du Nord (Ettelbruck)',
      ],
      immigrantSpecificNotes: 'Luxembourg is very multicultural (~48% foreign '
          'population). Healthcare system accustomed to serving diverse '
          'populations. Most doctors speak French, German, and English. '
          'CNS affiliation for asylum seekers is fast and comprehensive. '
          'Médecins du Monde is the key resource for undocumented. '
          'EU citizens: use EHIC for visits; register with CNS via CCSS '
          'if working.',
    ),

    // -------------------------------------------------------
    // 19. MALTA
    // -------------------------------------------------------
    HealthcareAccess(
      country: 'Malta',
      countryCode: 'MT',
      emergencyFree: true,
      emergencyNumber: '112',
      healthInsuranceSystem: 'National Health Service (Beveridge model). Tax-funded '
          'public healthcare free at point of use for Maltese and EU citizens '
          'with EHIC. Social security contributions fund additional benefits. '
          'Significant private sector usage.',
      ehcardAccepted: true,
      undocumentedAccess: 'Emergency care provided at Mater Dei Hospital. '
          'Undocumented persons can access emergency departments. Limited '
          'access to non-emergency public healthcare without entitlement '
          'certificate. JRS Malta and aditus foundation provide health '
          'access navigation.',
      asylumSeekerAccess: 'Asylum seekers receive free public healthcare '
          'through an entitlement certificate (pink slip) from the Agency '
          'for the Welfare of Asylum Seekers (AWAS). Covers GP, specialist, '
          'hospital, prescriptions, dental emergencies, and mental health. '
          'Primary healthcare at initial reception centers.',
      mentalHealthAccess: 'Public psychiatric services at Mount Carmel Hospital '
          'and community mental health services. Free for entitled persons. '
          'Asylum seekers: psychological support through AWAS and NGO '
          'partners. Richmond Foundation provides community mental health. '
          'Migrant Health Liaison Office coordinates.',
      maternityAccess: 'Full maternity care at Mater Dei Hospital for all '
          'entitled women. Asylum seekers receive maternity care. Prenatal '
          'clinics, hospital delivery, postnatal care covered. Midwifery '
          'services available.',
      childrenAccess: 'All children in Malta receive free public healthcare. '
          'Free vaccination program. School health services. Children of '
          'asylum seekers covered. Child protection services available '
          'through APPOGG/Foundation for Social Welfare Services.',
      registrationProcess: 'EU citizens: register for free public healthcare '
          'at Primary Health Care Department with EHIC or E-card equivalent. '
          'Residents: register at Health Entitlements Unit with ID card. '
          'Choose a government GP at health centers.',
      freeClinicInfo: 'JRS Malta (Jesuit Refugee Service, Valletta) - health '
          'navigation and social support. aditus foundation - legal and '
          'health access support. UNHCR Malta - referral services. '
          'Migrant Health Unit (Floriana) - specialized migrant health.',
      costEstimate: 'Public healthcare: free for entitled. Private GP: '
          'EUR 20-35. Private specialist: EUR 50-100. Private hospital: '
          'EUR 200-500/day. Prescriptions (public): free or EUR 0.58 '
          'co-pay.',
      legalBasis: 'Social Security Act (Cap. 318), Health Act (Cap. 528), '
          'Refugees Act (Cap. 420), Reception of Asylum Seekers Regulations '
          '(SL 420.06).',
      mentalHealthCrisisLine: '179 (Supportline, 24/7, free). '
          '116 111 (Kellimni - children/youth helpline). '
          '116 123 (Emotional support). '
          '1770 (Sedqa - substance abuse helpline).',
      ehcardHowToGet: 'Request EHIC at Health Entitlements Unit (Primary Health '
          'Care, Floriana). Need valid Maltese social security. Free. '
          'Processing: 1-2 weeks.',
      vaccinationProgram: 'Free national immunization program for all children. '
          'Covers DTaP, polio, MMR, Hep B, Hib, meningococcal, HPV. '
          'Administered at health centers. Mandatory for school enrollment.',
      mustTreatHospitals: [
        'Mater Dei Hospital (Msida) - main acute hospital, must treat all emergencies',
        'Gozo General Hospital',
        'Sir Anthony Mamo Oncology Centre',
      ],
      immigrantSpecificNotes: 'Malta is small with one main hospital (Mater Dei). '
          'As a Mediterranean frontline state, has significant migrant '
          'population. The "pink slip" (entitlement certificate) is '
          'critical for asylum seekers to access healthcare. Processing '
          'can be slow. JRS Malta and aditus are the key support NGOs. '
          'English widely spoken in medical settings alongside Maltese.',
    ),

    // -------------------------------------------------------
    // 20. NETHERLANDS
    // -------------------------------------------------------
    HealthcareAccess(
      country: 'Netherlands',
      countryCode: 'NL',
      emergencyFree: true,
      emergencyNumber: '112 / 0900 8844 (non-emergency police) / 0800 0113 (suicide)',
      healthInsuranceSystem: 'Mandatory private health insurance '
          '(Zorgverzekeringswet/Zvw). All residents must purchase basic '
          'insurance (basisverzekering, ~EUR 130-170/month) from private '
          'insurers (VGZ, CZ, Zilveren Kruis, Menzis, etc.). Government '
          'provides zorgtoeslag (healthcare allowance) for low income. '
          'Annual deductible (eigen risico): EUR 385.',
      ehcardAccepted: true,
      undocumentedAccess: 'Unique system: healthcare providers can treat '
          'undocumented persons and claim reimbursement from CAK (Central '
          'Administration Office) under Article 122a Zvw. Covers medically '
          'necessary care: GP, hospital, maternity, mental health, '
          'prescriptions. Provider decides what is necessary. Lampion '
          'helpdesk (for providers) coordinates. Undocumented persons '
          'pay symbolic EUR 5/visit to GP if possible.',
      asylumSeekerAccess: 'Asylum seekers in COA (Central Agency for Reception) '
          'receive healthcare through GezondheidsZorg Asielzoekers (GZA) '
          'system. Covers: GP at reception center, specialist with referral, '
          'hospital, dental (emergency + some preventive), prescriptions, '
          'mental health, midwifery. Menzis administers the coverage (RMA '
          'insurance card).',
      mentalHealthAccess: 'Covered by basic insurance (psychiatry and psychology '
          'with referral from GP). Waiting times significant (8-26 weeks for '
          'specialized care). Asylum seekers: mental health screening, '
          'access to GGZ (mental healthcare) through GZA. iPOG '
          '(intercultural psychiatry) centers. ARQ National Psychotrauma '
          'Centre for refugees.',
      maternityAccess: 'Full maternity care covered by basic insurance: '
          'midwife (verloskundige), GP obstetrics, hospital birth if '
          'needed, kraamzorg (postnatal home care, 8 days). Asylum seekers '
          'fully covered. Undocumented women: maternity care covered '
          'through CAK system. Home birth tradition (though hospital births '
          'now majority).',
      childrenAccess: 'All children under 18 are insured free of charge '
          '(no premium, no deductible) under parent\'s policy. Children '
          'of asylum seekers covered through GZA. Free vaccination program '
          '(Rijksvaccinatieprogramma) for all children. JGZ '
          '(Jeugdgezondheidszorg/youth health) consultations free for all '
          'regardless of status.',
      registrationProcess: 'Must purchase basic insurance within 4 months of '
          'registration in BRP (population register). Need BSN (Burger '
          'Service Nummer). Choose insurer and basic package. Apply for '
          'zorgtoeslag at toeslagen.nl if income qualifies. Register with '
          'a huisarts (GP) - this can be challenging in cities.',
      freeClinicInfo: 'Kruispost (Amsterdam, Oudezijds Voorburgwal 129) - '
          'free medical post for uninsured. Dokters van de Wereld/Médecins '
          'du Monde (Amsterdam, Den Haag, Eindhoven). De Wereldpoli (Utrecht). '
          'Lampion helpdesk for providers treating undocumented (0800 808 5588). '
          'Rode Kruis (Red Cross) refugee health. GGD (Municipal Health '
          'Service) - public health services accessible to all.',
      costEstimate: 'Basic insurance premium: EUR 130-170/month. Eigen risico '
          '(deductible): EUR 385/year. GP visit: free (no deductible). '
          'Specialist/hospital: applies to deductible. Without insurance: '
          'GP EUR 30-50, specialist EUR 80-200, hospital EUR 500-2000/day.',
      legalBasis: 'Zorgverzekeringswet (Zvw) Art. 122a, Wet langdurige zorg '
          '(Wlz), Regeling Medische zorg Asielzoekers (RMA), Wet op de '
          'jeugdzorg, Vreemdelingenwet 2000.',
      mentalHealthCrisisLine: '0800 0113 (113 Zelfmoordpreventie, 24/7, free). '
          '0900 0767 (Sensoor, emotional support). '
          '116 111 (Kindertelefoon). '
          '0800 2000 (Slachtofferhulp/victim support).',
      ehcardHowToGet: 'Request EHIC from your health insurer (via their app, '
          'website, or phone). Need valid Dutch health insurance. Free. '
          'Processing: immediate digital card via app, physical 5-10 days.',
      vaccinationProgram: 'Rijksvaccinatieprogramma (RVP) - free for all '
          'children registered in Netherlands. Covers DTaP, polio, MMR, '
          'Hep B, Hib, pneumococcal, meningococcal, HPV. Administered at '
          'JGZ/consultatiebureau. Catch-up program for immigrant children.',
      mustTreatHospitals: [
        'All hospitals can treat undocumented and claim from CAK',
        'Amsterdam UMC (AMC and VUmc)',
        'Erasmus MC (Rotterdam)',
        'LUMC (Leiden)',
        'UMC Utrecht',
        'Radboudumc (Nijmegen)',
        'UMCG (Groningen)',
      ],
      immigrantSpecificNotes: 'The Netherlands has a pragmatic system for '
          'undocumented healthcare (CAK reimbursement). KEY: Any GP, hospital, '
          'or pharmacy can treat undocumented persons and get reimbursed - '
          'they just need to know the procedure. Lampion helpdesk assists '
          'providers. Finding a huisarts (GP) is difficult in major cities '
          'for everyone. GGD provides TB screening and vaccinations for all. '
          'Children under 18 are always insured free. EU workers: get BSN '
          'and buy insurance within 4 months.',
    ),

    // -------------------------------------------------------
    // 21. POLAND
    // -------------------------------------------------------
    HealthcareAccess(
      country: 'Poland',
      countryCode: 'PL',
      emergencyFree: true,
      emergencyNumber: '112 / 999 (ambulance) / 998 (fire)',
      healthInsuranceSystem: 'National Health Fund (NFZ - Narodowy Fundusz '
          'Zdrowia). Mandatory social health insurance funded by employee/'
          'employer contributions (9% of income). Covers ~91% of population. '
          'Public healthcare strained with long waiting times.',
      ehcardAccepted: true,
      undocumentedAccess: 'Emergency care must be provided but will be billed. '
          'Undocumented persons have no access to public health insurance. '
          'Since 2022 Ukrainian refugee crisis, expanded access for '
          'Ukrainians specifically. Other undocumented: NGO support through '
          'Red Cross and limited charitable medical care.',
      asylumSeekerAccess: 'Asylum seekers receive healthcare funded by the '
          'state through the Office for Foreigners (Urząd do Spraw '
          'Cudzoziemców). Covers: medical examinations, GP visits, '
          'specialist care with referral, hospital, maternity, dental '
          'emergencies, prescriptions, mental health. Healthcare at '
          'reception centers and designated facilities.',
      mentalHealthAccess: 'Psychiatric care covered by NFZ with long waiting '
          'times (months). Psychotherapy partially covered. Asylum seekers: '
          'psychological support at reception centers. Centrum Pomocy '
          'Prawnej im. H. Nieć provides support. Since 2022, expanded '
          'mental health services for Ukrainian refugees.',
      maternityAccess: 'Full maternity care for insured women through NFZ: '
          'prenatal, hospital delivery, postnatal, midwife home visits. '
          'Asylum seekers receive full maternity care. Uninsured women: '
          'emergency obstetric care. Since 2022, Ukrainian women receive '
          'maternity coverage.',
      childrenAccess: 'All children under 18 entitled to healthcare regardless '
          'of parents\' insurance (confirmed by Constitutional Tribunal). '
          'Free vaccinations mandatory for all children (strictest system in '
          'EU). School health services (nurse, dentist). Children of asylum '
          'seekers fully covered.',
      registrationProcess: 'Insurance through employer (automatic) or register '
          'at NFZ branch office with PESEL number, employment documentation, '
          'and ID. Choose a primary care doctor (lekarz podstawowej opieki '
          'zdrowotnej) by filing a declaration at a clinic.',
      freeClinicInfo: 'Centrum Pomocy Prawnej im. Haliny Nieć (Krakow) - legal '
          'and healthcare access for refugees. Polish Red Cross - health '
          'programs. Polskie Centrum Pomocy Międzynarodowej (PCPM) - '
          'humanitarian health. Fundacja Ocalenie (Warsaw) - refugee '
          'support. Since 2022, many medical points for Ukrainian refugees '
          'in major cities.',
      costEstimate: 'GP visit (NFZ): free. Without insurance: PLN 100-200 '
          '(EUR 22-44). Specialist: PLN 150-400 (EUR 33-88). '
          'Emergency room: free for emergencies. Hospital day: PLN 200-600 '
          '(EUR 44-132, uninsured). Private GP: PLN 150-250 (EUR 33-55).',
      legalBasis: 'Act on Health Care Services Financed from Public Funds '
          '(Ustawa o świadczeniach opieki zdrowotnej finansowanych ze '
          'środków publicznych), Act on Granting Protection to Foreigners '
          '(Ustawa o udzielaniu cudzoziemcom ochrony na terytorium RP), '
          'Special Act on Ukraine (Ustawa o pomocy obywatelom Ukrainy).',
      mentalHealthCrisisLine: '116 123 (Telefon Zaufania, emotional support). '
          '116 111 (Telefon Zaufania dla Dzieci i Młodzieży). '
          '800 70 2222 (Centrum Wsparcia - crisis support, 24/7, free). '
          '800 12 00 02 (Niebieska Linia - violence helpline).',
      ehcardHowToGet: 'Request EHIC at NFZ branch office or online at '
          'zip.nfz.gov.pl. Need PESEL and valid insurance. Free. '
          'Processing: up to 30 days (express 3 days at office).',
      vaccinationProgram: 'Mandatory vaccination program (Obowiązkowe szczepienia '
          'ochronne) for all children. Covers BCG, DTaP, polio, MMR, Hep B. '
          'Non-compliance can result in administrative fines. Administered '
          'at primary care clinics. Catch-up available for immigrant children.',
      mustTreatHospitals: [
        'All hospital emergency departments (SOR - Szpitalny Oddział Ratunkowy)',
        'Szpital Bielański (Warsaw)',
        'Centralny Szpital Kliniczny MSWiA (Warsaw)',
        'Szpital Uniwersytecki w Krakowie',
        'Szpital Kliniczny im. WAM (Łódź)',
        'Szpital Kliniczny (Gdańsk)',
        'Szpital Kliniczny (Wrocław)',
      ],
      immigrantSpecificNotes: 'Poland\'s healthcare landscape changed dramatically '
          'since 2022 with Ukrainian refugees. Ukrainians with PESEL UKR get '
          'full NFZ coverage. Other migrants: standard rules apply. Long '
          'waiting times in public system are a major issue. Private healthcare '
          'is affordable by Western standards. Key: get PESEL number and '
          'register with NFZ. Many doctors speak English in major cities. '
          'Mandatory vaccination enforcement is strict.',
    ),

    // -------------------------------------------------------
    // 22. PORTUGAL
    // -------------------------------------------------------
    HealthcareAccess(
      country: 'Portugal',
      countryCode: 'PT',
      emergencyFree: true,
      emergencyNumber: '112',
      healthInsuranceSystem: 'SNS (Serviço Nacional de Saúde) - universal '
          'tax-funded national health service (Beveridge model). All residents '
          'entitled regardless of nationality or legal status since Law '
          '95/2019. Taxas moderadoras (user fees) abolished for most services '
          'in 2024.',
      ehcardAccepted: true,
      undocumentedAccess: 'Portugal is one of the most accessible EU countries '
          'for undocumented migrants. Since 2001, undocumented persons with '
          'an atestado de residência (residence attestation from local '
          'junta de freguesia, EUR 0) can access the full SNS on the same '
          'basis as Portuguese citizens. Since Law 95/2019 and changes in '
          '2023, access further simplified - NIF or proof of address sufficient.',
      asylumSeekerAccess: 'Full SNS access from the moment of asylum application. '
          'Same entitlements as Portuguese citizens. Healthcare coordinated '
          'through CPR (Conselho Português para os Refugiados) and ACM '
          '(Alto Comissariado para as Migrações). User fees exempted.',
      mentalHealthAccess: 'Mental health covered by SNS. Community mental health '
          'teams expanding. Psychiatry and psychology available with referral. '
          'Asylum seekers: specialized support through CPR and ISCTE '
          'Multicultural Mental Health project. Long waiting times for '
          'public psychology.',
      maternityAccess: 'Full maternity care through SNS for ALL women regardless '
          'of status: prenatal visits, hospital delivery, postnatal care. '
          'Linha de Saúde Materno-Infantil (maternal/child health line) '
          'available. User fees exempted for pregnancy.',
      childrenAccess: 'All children entitled to full SNS care regardless of '
          'parents\' status. Free vaccinations through PNV (Programa Nacional '
          'de Vacinação). Pediatric care, school health services. User fees '
          'exempted for children under 18.',
      registrationProcess: 'Register at local Centro de Saúde (health center) '
          'with NIF (tax number), proof of address, and ID. Get a Número de '
          'Utente do SNS (SNS user number). Undocumented: get atestado from '
          'junta de freguesia. EU citizens: register with NIF and address.',
      freeClinicInfo: 'All SNS health centers (centros de saúde) are free or '
          'near-free since 2024 reforms. AMI Foundation (Lisbon, Porto) - '
          'medical and social support. JRS Portugal (Lisbon) - refugee '
          'health navigation. Santa Casa da Misericórdia (Lisbon) - '
          'charitable health services. Médicos do Mundo (Lisbon, Porto).',
      costEstimate: 'SNS health center visit: free (since 2024 reform). '
          'SNS hospital emergency: EUR 15-18 (many exemptions). '
          'Hospital specialist: EUR 7.75 (many exemptions). '
          'Without SNS number: hospital emergency always treated. '
          'Private GP: EUR 40-80. Private specialist: EUR 60-150.',
      legalBasis: 'Lei de Bases da Saúde (Law 95/2019), Decree-Law 113/2011 '
          '(SNS access for immigrants), Dispatch 25360/2001 (undocumented '
          'access), Law 27/2008 (asylum), Constitution Art. 64 '
          '(right to health protection).',
      mentalHealthCrisisLine: '808 200 204 (SOS Voz Amiga, free). '
          '116 111 (SOS Criança - children). '
          '808 257 257 (Linha de Saúde Mental - mental health line). '
          '800 202 651 (APAV - victim support).',
      ehcardHowToGet: 'Request EHIC at Social Security office or online at '
          'seg-social.pt. Need SNS user number and social security '
          'registration. Free. Processing: 7-15 days.',
      vaccinationProgram: 'PNV (Programa Nacional de Vacinação) - free '
          'comprehensive vaccination for all children and adults regardless '
          'of status. Covers DTaP, polio, MMR, Hep B, HPV, meningococcal, '
          'pneumococcal. Available at all centros de saúde. Catch-up '
          'vaccination program for immigrants.',
      mustTreatHospitals: [
        'All SNS hospitals treat regardless of status',
        'Hospital de Santa Maria (Lisbon)',
        'Hospital de São João (Porto)',
        'Centro Hospitalar de Coimbra',
        'Hospital de Faro',
        'Hospital de Braga',
      ],
      immigrantSpecificNotes: 'Portugal is widely recognized as having one of '
          'the most inclusive healthcare systems in the EU for immigrants. '
          'KEY STEPS: 1) Get NIF at Finanças. 2) Get atestado from junta '
          'de freguesia if undocumented. 3) Register at Centro de Saúde. '
          'Most healthcare workers speak some English. Intercultural '
          'mediators at major hospitals. ACM (acm.gov.pt) provides one-stop '
          'integration services. No data sharing between SNS and immigration '
          'authorities.',
    ),

    // -------------------------------------------------------
    // 23. ROMANIA
    // -------------------------------------------------------
    HealthcareAccess(
      country: 'Romania',
      countryCode: 'RO',
      emergencyFree: true,
      emergencyNumber: '112',
      healthInsuranceSystem: 'CNAS (Casa Națională de Asigurări de Sănătate) - '
          'mandatory social health insurance. Funded by employee/employer '
          'contributions (10% of gross income). Covers ~86% of population. '
          'Significant informal payment culture in practice.',
      ehcardAccepted: true,
      undocumentedAccess: 'Emergency care must be provided at public hospitals. '
          'Undocumented persons have access to emergency care and '
          'communicable disease treatment. No public insurance access. '
          'Limited NGO healthcare support through ICAR Foundation and '
          'Romanian Red Cross.',
      asylumSeekerAccess: 'Asylum seekers receive healthcare through the General '
          'Inspectorate for Immigration (IGI). First 3 months: emergency '
          'care, maternity, communicable diseases, children. After 3 months: '
          'primary care through designated family doctor. Medical assistance '
          'at reception centers (Bucharest, Timișoara, Galați, Giurgiu, '
          'Șomcuta Mare).',
      mentalHealthAccess: 'Psychiatric care covered by CNAS. Community mental '
          'health underdeveloped. Psychotherapy not covered by public '
          'insurance. Asylum seekers: psychological support through ICAR '
          'Foundation and UNHCR Romania partners. AIDRom - psychosocial '
          'support for refugees.',
      maternityAccess: 'Maternity care covered for insured women. Emergency '
          'obstetric care for all women. Asylum seekers receive maternity '
          'care. Prenatal, delivery, and postnatal care through designated '
          'family doctors and maternities.',
      childrenAccess: 'All children under 18 receive free healthcare regardless '
          'of parents\' insurance status. Mandatory vaccination program. '
          'School health services. Children of asylum seekers covered.',
      registrationProcess: 'Register at CNAS (Casa de Asigurări) with CNP '
          '(Cod Numeric Personal), employment contract, and ID. Choose a '
          'family doctor (medic de familie). Registration at local CAS '
          '(Casa Județeană de Asigurări de Sănătate).',
      freeClinicInfo: 'ICAR Foundation (Bucharest) - free healthcare for '
          'torture survivors and refugees. AIDRom (Bucharest, Timișoara) - '
          'refugee integration and health. Romanian Red Cross - health '
          'programs. Medici pentru Tine (volunteer doctors network). '
          'MedLife Foundation - occasional free programs.',
      costEstimate: 'GP visit (insured): free. Without insurance: '
          'RON 50-150 (EUR 10-30). Specialist: RON 100-300 (EUR 20-60). '
          'Emergency room: free for emergencies. Hospital day: RON 200-500 '
          '(EUR 40-100, uninsured). Romania has among the lowest healthcare '
          'costs in the EU. Informal payments common.',
      legalBasis: 'Law 95/2006 on Healthcare Reform, Law 122/2006 on Asylum, '
          'Government Decision 1251/2006 on reception conditions, '
          'Constitution Art. 34 (right to health protection).',
      mentalHealthCrisisLine: '116 123 (Telefonul Sufletului, emotional support). '
          '116 111 (Telefonul Copilului - children). '
          '0800 801 200 (Telverde for domestic violence, free).',
      ehcardHowToGet: 'Request EHIC at local CAS office or online at cnas.ro. '
          'Need CNP and valid insurance status. Free. Processing: up to '
          '7 working days.',
      vaccinationProgram: 'National immunization program with some mandatory '
          'and recommended vaccines. Covers BCG, DTaP, polio, MMR, Hep B. '
          'Coverage rates have declined in recent years. Administered by '
          'family doctors. Free for all children.',
      mustTreatHospitals: [
        'All hospital emergency departments (UPU - Unitate de Primiri Urgențe)',
        'Spitalul Universitar de Urgență București',
        'Spitalul Clinic de Urgență Floreasca (Bucharest)',
        'Spitalul Clinic Județean de Urgență Cluj',
        'Spitalul Clinic Județean Timișoara',
        'Spitalul Județean de Urgență Iași',
      ],
      immigrantSpecificNotes: 'Romania has a smaller immigrant population but '
          'growing. Healthcare system faces challenges with staffing and '
          'infrastructure. Informal payments (spaga) are culturally embedded '
          'though illegal. ICAR Foundation is the key organization for '
          'refugee healthcare. EU citizens use EHIC; if working, register '
          'for CNP and CAS. Romanian medical staff increasingly speak '
          'English, especially younger generation.',
    ),

    // -------------------------------------------------------
    // 24. SLOVAKIA
    // -------------------------------------------------------
    HealthcareAccess(
      country: 'Slovakia',
      countryCode: 'SK',
      emergencyFree: true,
      emergencyNumber: '112 / 155 (ambulance)',
      healthInsuranceSystem: 'Mandatory health insurance through three insurance '
          'companies: Všeobecná zdravotná poisťovňa (VšZP, state-owned, ~63%), '
          'Dôvera (~28%), Union (~9%). Bismarck model. Employer/employee '
          'contributions (14% of gross salary, split 10/4).',
      ehcardAccepted: true,
      undocumentedAccess: 'Emergency care must be provided. Undocumented persons '
          'have no access to public health insurance. Must pay for non-emergency '
          'care. Very limited NGO healthcare. Human Rights League (Liga za '
          'ľudské práva) provides some navigation support.',
      asylumSeekerAccess: 'Asylum seekers receive healthcare through the '
          'Migration Office of the Ministry of Interior. Covers: emergency '
          'care, essential medical treatment, preventive care, maternity, '
          'children. Healthcare at reception centers (Humenné, Opatovská '
          'Nová Ves) and designated facilities. After 1 year in procedure: '
          'broader access.',
      mentalHealthAccess: 'Psychiatric care covered by health insurance. '
          'Psychotherapy partially covered (limited). Community mental '
          'health developing. Asylum seekers: psychological support at '
          'reception facilities. Liga za ľudské práva provides '
          'psychosocial support.',
      maternityAccess: 'Full maternity care for insured women. Emergency '
          'obstetric care for all. Asylum seekers receive maternity care. '
          'Prenatal monitoring, hospital delivery, postnatal care covered.',
      childrenAccess: 'All children under 18 can be insured regardless of '
          'parents\' status. Free vaccinations mandatory. School health '
          'services. Children of asylum seekers receive healthcare through '
          'Migration Office.',
      registrationProcess: 'Choose one of three insurance companies and register '
          'with personal birth number (rodné číslo) or foreigner ID number. '
          'Registration through employer or at insurance company branch. '
          'Choose a GP (všeobecný lekár) at a nearby clinic.',
      freeClinicInfo: 'Liga za ľudské práva (Bratislava) - legal and social '
          'support for refugees. Slovak Humanitarian Council - social '
          'assistance. IOM Slovakia - migration health programs. '
          'Slovak Red Cross - limited health assistance. Very limited free '
          'clinic infrastructure.',
      costEstimate: 'GP visit (insured): free. Without insurance: EUR 20-50. '
          'Specialist: EUR 30-80. Emergency room: free for emergencies. '
          'Hospital day: EUR 3.32/day co-pay (insured), EUR 100-300 '
          '(uninsured). Prescriptions: co-payment varies.',
      legalBasis: 'Act No. 580/2004 on Health Insurance, Act No. 480/2002 '
          'on Asylum, Act No. 404/2011 on Stay of Foreigners, '
          'Act No. 576/2004 on Healthcare.',
      mentalHealthCrisisLine: '0800 500 333 (Linka dôvery Nezábudka, free). '
          '116 111 (Linka detskej istoty - children). '
          '0800 212 212 (Národná linka na pomoc obetiam - victims).',
      ehcardHowToGet: 'Request EHIC from your insurance company (VšZP, Dôvera, '
          'or Union) at branch or online. Need valid health insurance. Free. '
          'Processing: up to 30 days.',
      vaccinationProgram: 'Mandatory vaccination program for all children. '
          'Covers DTaP, polio, MMR, Hep B, Hib, pneumococcal. '
          'Non-compliance subject to administrative proceedings. '
          'Administered by pediatricians.',
      mustTreatHospitals: [
        'All hospital emergency departments (Urgentný príjem)',
        'Univerzitná nemocnica Bratislava',
        'Fakultná nemocnica s poliklinikou F.D. Roosevelta (Banská Bystrica)',
        'Univerzitná nemocnica Martin',
        'Univerzitná nemocnica L. Pasteura (Košice)',
      ],
      immigrantSpecificNotes: 'Slovakia has a small but growing immigrant '
          'population. Healthcare system works well for insured persons but '
          'limited for undocumented. Since 2022, temporary protection for '
          'Ukrainians provided healthcare access. Liga za ľudské práva is '
          'the key NGO for refugee support. Registration with health '
          'insurance is essential first step. Slovak and Czech languages '
          'mutually intelligible.',
    ),

    // -------------------------------------------------------
    // 25. SLOVENIA
    // -------------------------------------------------------
    HealthcareAccess(
      country: 'Slovenia',
      countryCode: 'SI',
      emergencyFree: true,
      emergencyNumber: '112',
      healthInsuranceSystem: 'ZZZS (Zavod za zdravstveno zavarovanje Slovenije) - '
          'mandatory health insurance. Bismarck model. Employer/employee '
          'contributions (13.45% of gross salary). Covers ~100% of population. '
          'Complementary insurance (Vzajemna, Triglav, Generali) needed for '
          'full coverage of co-payments.',
      ehcardAccepted: true,
      undocumentedAccess: 'Emergency care must be provided. Undocumented '
          'persons can access emergency care at hospitals. Beyond '
          'emergencies: limited access. Pro Bono clinic (Ljubljana) '
          'provides free medical care. Communicable disease treatment '
          'available.',
      asylumSeekerAccess: 'Asylum seekers receive healthcare equivalent to '
          'insured Slovenian citizens including GP, specialist, hospital, '
          'prescriptions, dental emergencies, and mental health. Funded by '
          'the state through the Government Office for the Support and '
          'Integration of Migrants. Healthcare at asylum home (Ljubljana) '
          'and designated providers.',
      mentalHealthAccess: 'Psychiatric care covered by ZZZS. Community mental '
          'health centers (CZOD) established in reform. Psychotherapy '
          'partially covered. Asylum seekers: psychological support at asylum '
          'home and through NGO partners (Slovene Philanthropy, PIC). '
          'UNHCR-funded mental health programs.',
      maternityAccess: 'Full maternity care for insured women. Asylum seekers '
          'receive full maternity care. Prenatal, hospital delivery, '
          'postnatal care, patronage nurse home visits. Uninsured women '
          'receive emergency obstetric care.',
      childrenAccess: 'All children under 18 with insurance receive full '
          'care with no co-payments. Children of asylum seekers fully '
          'covered. Free vaccination program. School health services '
          '(zdravstveni domovi). Patronage nurses visit newborns.',
      registrationProcess: 'Register at ZZZS with employer notification '
          '(M-1 form) or at ZZZS office. Need EMŠO (unique identification '
          'number), residence registration, and employment documentation. '
          'Choose a personal GP (izbrani osebni zdravnik) at a health center.',
      freeClinicInfo: 'Pro Bono Clinic (Ljubljana, Pražakova 7) - free medical '
          'care for uninsured persons. Slovene Philanthropy (Slovenska '
          'filantropija) - refugee integration and health support. PIC '
          '(Legal-Informational Centre for NGOs) - legal and health access. '
          'Red Cross Slovenia - health programs.',
      costEstimate: 'GP visit (insured): free. Without insurance: '
          'EUR 25-50. Specialist: EUR 40-100. Emergency room: free. '
          'Hospital day: EUR 12.44/day co-pay (with complementary '
          'insurance it is covered). Full cost uninsured: EUR 150-400/day.',
      legalBasis: 'Health Care and Health Insurance Act (ZZVZZ), International '
          'Protection Act (Zakon o mednarodni zaščiti), Foreigners Act '
          '(Zakon o tujcih), Health Services Act (ZZDej).',
      mentalHealthCrisisLine: '116 123 (Zaupni telefon Samarijan, 24/7). '
          '116 111 (TOM telefon - children/youth). '
          '080 11 55 (Krizni center za ženske - women\'s crisis).',
      ehcardHowToGet: 'Request EHIC at ZZZS office or online at ezzzs.zzzs.si. '
          'Need valid mandatory health insurance. Free. Processing: '
          '7-15 days.',
      vaccinationProgram: 'Mandatory vaccination program for all children. '
          'Covers DTaP, polio, MMR, Hep B, Hib. Administered at health '
          'centers (zdravstveni domovi). Non-compliance has legal '
          'consequences (fines). Additional recommended vaccines available.',
      mustTreatHospitals: [
        'All hospital emergency departments (Urgentni center)',
        'UKC Ljubljana (Univerzitetni klinični center)',
        'UKC Maribor',
        'Splošna bolnišnica Celje',
        'Splošna bolnišnica Novo mesto',
      ],
      immigrantSpecificNotes: 'Slovenia is a small country with good healthcare '
          'quality. Pro Bono clinic in Ljubljana is the main resource for '
          'undocumented persons. Asylum home is in Ljubljana. Registration '
          'with ZZZS is straightforward with legal residence. Complementary '
          'insurance (~EUR 35/month) important to avoid co-payments. '
          'Many medical staff speak English or German.',
    ),

    // -------------------------------------------------------
    // 26. SPAIN
    // -------------------------------------------------------
    HealthcareAccess(
      country: 'Spain',
      countryCode: 'ES',
      emergencyFree: true,
      emergencyNumber: '112 / 061 (health emergency)',
      healthInsuranceSystem: 'SNS (Sistema Nacional de Salud) - universal '
          'tax-funded national health service (Beveridge model). Managed by '
          '17 Autonomous Communities (Comunidades Autónomas). Since Royal '
          'Decree-Law 7/2018, universal coverage restored for all residents '
          'including undocumented persons.',
      ehcardAccepted: true,
      undocumentedAccess: 'Since 2018 (Royal Decree-Law 7/2018), undocumented '
          'persons can access the full SNS by registering at local Centro '
          'de Salud with padrón (municipal registration - no immigration '
          'check). Covers: GP, specialist, hospital, prescriptions, '
          'mental health. In practice, implementation varies by Autonomous '
          'Community. Emergency care always free.',
      asylumSeekerAccess: 'Full SNS access from the moment of asylum application. '
          'Receive SIP (tarjeta sanitaria individual) from Autonomous '
          'Community health service. Same entitlements as Spanish citizens '
          'including GP, specialist, hospital, prescriptions, dental '
          'emergencies, mental health.',
      mentalHealthAccess: 'Covered by SNS with GP referral. Psychiatry and '
          'clinical psychology available. Long waiting times (3-6 months). '
          'Each Autonomous Community has CSM (Centro de Salud Mental). '
          'Asylum seekers: CEAR (Comisión Española de Ayuda al Refugiado) '
          'provides psychosocial support. SOS Racismo, Accem, Cruz Roja '
          'offer mental health for migrants.',
      maternityAccess: 'Full maternity care through SNS for ALL women including '
          'undocumented: prenatal monitoring, hospital delivery, postnatal '
          'care, midwife (matrona) visits. Programa de atención al embarazo '
          'available at all centros de salud. No status check for maternity.',
      childrenAccess: 'All children in Spain entitled to full SNS healthcare '
          'regardless of parents\' status. Free vaccinations through '
          'Autonomous Community programs. Pediatric care at centros de salud. '
          'School health services.',
      registrationProcess: 'Register at padrón municipal (ayuntamiento) with '
          'proof of address (rental contract or empadronamiento). Then '
          'register at Centro de Salud with padrón certificate and ID. '
          'Receive tarjeta sanitaria (health card). Choose a médico de '
          'familia (family doctor) and pediatra for children.',
      freeClinicInfo: 'Médicos del Mundo (25+ cities across Spain) - free care '
          'for uninsured. Cruz Roja (Red Cross) health programs in all '
          'provinces. CEAR (Madrid, Barcelona, Valencia, etc.) - refugee '
          'healthcare. Accem (30+ offices). REDER network coordinates '
          'healthcare access for excluded populations. Open Arms health '
          'programs.',
      costEstimate: 'SNS: completely free at point of use (no co-payments for '
          'GP or hospital). Prescription co-pay: 0-60% depending on income '
          '(pensioners max EUR 8-18/month). Without SNS card: emergency '
          'free, private GP EUR 40-80, specialist EUR 60-150.',
      legalBasis: 'Ley 16/2003 de Cohesión y Calidad del SNS, Real Decreto-Ley '
          '7/2018 (universal coverage restoration), Ley 12/2009 (asylum), '
          'Constitution Art. 43 (right to health protection). Regional health '
          'laws of each Autonomous Community.',
      mentalHealthCrisisLine: '024 (Línea de Atención a la Conducta Suicida, '
          '24/7, free, since 2022). 116 111 (ANAR - children). '
          '900 22 22 92 (Teléfono de la Esperanza). '
          '016 (Violencia de género, 24/7, free).',
      ehcardHowToGet: 'Request TSE (Tarjeta Sanitaria Europea) at INSS office '
          'or online at sede.seg-social.gob.es. Need Social Security '
          'affiliation number. Free. Processing: instant provisional '
          'certificate, physical card 10 days.',
      vaccinationProgram: 'Free vaccination program managed by each Autonomous '
          'Community (slightly different schedules). Covers DTaP, polio, '
          'MMR, Hep B, meningococcal, HPV, varicella, pneumococcal. '
          'Available at centros de salud for all children regardless of '
          'status. Catch-up programs for immigrant children.',
      mustTreatHospitals: [
        'ALL public hospitals must treat regardless of status',
        'Hospital La Paz (Madrid)',
        'Hospital Clínic (Barcelona)',
        'Hospital Vall d\'Hebron (Barcelona)',
        'Hospital Virgen del Rocío (Sevilla)',
        'Hospital La Fe (Valencia)',
        'Hospital de Cruces (Bilbao)',
      ],
      immigrantSpecificNotes: 'Spain restored universal healthcare in 2018 after '
          'a controversial 2012 exclusion. KEY: empadronamiento (municipal '
          'registration) is the crucial first step - it does NOT require '
          'legal residence status and municipalities CANNOT refuse it. With '
          'padrón certificate, register at Centro de Salud. Some Autonomous '
          'Communities (Basque Country, Navarra, Valencia) are more '
          'progressive than others. Médicos del Mundo and REDER network '
          'can help if access is denied. Interpreting via intercultural '
          'mediators at many hospitals.',
    ),

    // -------------------------------------------------------
    // 27. SWEDEN
    // -------------------------------------------------------
    HealthcareAccess(
      country: 'Sweden',
      countryCode: 'SE',
      emergencyFree: true,
      emergencyNumber: '112 / 1177 (Vårdguiden - non-emergency health advice)',
      healthInsuranceSystem: 'Tax-funded universal healthcare (Beveridge model). '
          'Managed by 21 regions (regioner). All residents with personnummer '
          'entitled. Funded through regional income tax (~11%). Patient fees '
          'with annual ceiling (högkostnadsskydd): SEK 1,300/year for care, '
          'SEK 2,850/year for prescriptions.',
      ehcardAccepted: true,
      undocumentedAccess: 'Since 2013 (Lag 2013:407), undocumented persons '
          '(papperslösa) have the RIGHT to subsidized care: emergency care, '
          'care that cannot wait, maternity care, abortion, contraception, '
          'and healthcare for children. Same patient fees as residents. '
          'Providers cannot report patients to police. One of the best '
          'systems in EU for undocumented healthcare.',
      asylumSeekerAccess: 'Asylum seekers receive an LMA card from '
          'Migrationsverket (Migration Agency) giving access to: care that '
          'cannot wait (vård som inte kan anstå), dental emergency care, '
          'maternity care, contraception, abortion. Healthcare provided '
          'through regional health services. Children of asylum seekers '
          'receive full healthcare equal to residents.',
      mentalHealthAccess: 'Covered by regional healthcare. Psychiatric care '
          'with referral. BUP (Barn- och ungdomspsykiatrin) for children. '
          'Asylum seekers: entitled to mental health care "that cannot wait." '
          'Röda Korsets Behandlingscenter (Red Cross Treatment Centers) in '
          'several cities provide specialized torture/trauma rehabilitation. '
          'Transkulturellt Centrum (Stockholm) - intercultural psychiatry.',
      maternityAccess: 'Full free maternity care for ALL women including '
          'undocumented: mödravårdscentral (MVC - prenatal clinic), hospital '
          'delivery, BB (postnatal ward), barnmorska (midwife) postpartum '
          'home visits. BVC (child health center) from birth. Interpreting '
          'services provided.',
      childrenAccess: 'Children of asylum seekers and undocumented persons '
          'receive FULL healthcare equal to Swedish children (not restricted '
          'to "care that cannot wait"). Free vaccinations. BVC (Barnavårds-'
          'centralen) for all children 0-6. School health services. Dental '
          'care free for all children under 24.',
      registrationProcess: 'Automatic upon receiving personnummer (requires '
          'residence permit). Register at Skatteverket (Tax Agency) to get '
          'personnummer. Then register at local vårdcentral (health center) '
          'through 1177.se. Choose a fast läkare/vårdcentral. Samordnings-'
          'nummer for those without personnummer allows some access.',
      freeClinicInfo: 'Rosengrenska stiftelsen (Gothenburg) - free healthcare '
          'for undocumented since 1998 (pioneer in Sweden). Läkare i Världen '
          '(Doctors of the World, Stockholm: Luntmakargatan 22). Röda Korsets '
          'Behandlingscenter (Stockholm, Gothenburg, Malmö, Uppsala, Skövde) - '
          'trauma rehabilitation. Stadsmissionen health services (Stockholm, '
          'Gothenburg). Ny Gemenskap (Stockholm - mobile health services).',
      costEstimate: 'Vårdcentral (GP): SEK 100-300 (EUR 9-27). Emergency: '
          'SEK 400 (EUR 36). Specialist with referral: SEK 400 (EUR 36). '
          'Hospital stay: SEK 120/day (EUR 11). Annual ceiling: SEK 1,300 '
          '(EUR 117). For undocumented: SEK 50 for care (EUR 4.50). '
          'Children under 18 and dental under 24: free.',
      legalBasis: 'Hälso- och sjukvårdslag (2017:30), Lag (2013:407) om '
          'hälso- och sjukvård till vissa utlänningar som vistas i Sverige '
          'utan nödvändiga tillstånd, Lag (2008:344) om hälso- och sjukvård '
          'åt asylsökande m.fl., Utlänningslag (2005:716).',
      mentalHealthCrisisLine: '90101 (Mind Självmordslinjen, 24/7, free). '
          '116 123 (Jourhavande medmänniska, evenings/nights). '
          '116 111 (BRIS - children, 24/7). '
          '020-505 050 (Kvinnofridslinjen - women\'s helpline).',
      ehcardHowToGet: 'Request EHIC from Försäkringskassan at '
          'forsakringskassan.se, by phone (0771-524 524), or at service '
          'center. Need personnummer and Swedish residence. Free. '
          'Processing: 1-2 weeks.',
      vaccinationProgram: 'Free national vaccination program for all children '
          'regardless of status. Covers DTaP, polio, MMR, Hep B, Hib, '
          'pneumococcal, HPV, rotavirus. Administered at BVC (0-6 years) '
          'and school health services (6-18). Catch-up program for '
          'immigrant children (kompletteringsvaccination).',
      mustTreatHospitals: [
        'All hospitals must treat undocumented (Lag 2013:407)',
        'Karolinska Universitetssjukhuset (Stockholm)',
        'Sahlgrenska Universitetssjukhuset (Gothenburg)',
        'Skånes universitetssjukhus SUS (Malmö/Lund)',
        'Akademiska sjukhuset (Uppsala)',
        'Universitetssjukhuset Linköping',
      ],
      immigrantSpecificNotes: 'Sweden has strong legal protections for '
          'undocumented healthcare since 2013. KEY: Healthcare providers '
          'CANNOT report undocumented patients to police or Migrationsverket. '
          'Children always receive FULL care regardless of parents\' status. '
          '1177 Vårdguiden (1177.se) is the central portal for all healthcare '
          'information and appointment booking (available in multiple '
          'languages). Interpreting services (tolktjänst) are a legal RIGHT '
          'in healthcare - always request if needed. Rosengrenska (Gothenburg) '
          'and Läkare i Världen (Stockholm) are key NGOs for undocumented.',
    ),
  ];

  // ============================================================
  // CROSS-COUNTRY REFERENCE TABLES
  // ============================================================

  /// Countries where undocumented persons have comprehensive healthcare access
  /// (beyond just emergency care)
  static const List<String> bestAccessForUndocumented = [
    'France (AME - nearly full coverage after 3 months)',
    'Italy (STP code - emergency, essential, maternity, children)',
    'Spain (full SNS via empadronamiento since 2018)',
    'Portugal (full SNS via atestado since 2001)',
    'Belgium (AMU - comprehensive medical care via CPAS)',
    'Netherlands (CAK system - providers reimbursed for necessary care)',
    'Sweden (subsidized care since 2013, full for children)',
    'Greece (Law 4368/2016 - public healthcare access)',
  ];

  /// EU-wide emergency number and tips
  static const String emergencyInfo =
      '112 is the EU-wide emergency number, free from any phone (including '
      'without SIM card). Available in all 27 EU countries. Many countries '
      'have additional specific numbers for ambulance. Operators in most '
      'countries can handle calls in English. The European Emergency Number '
      'Association (EENA) coordinates 112 across the EU.';

  /// EHIC general information
  static const String ehcardGeneralInfo =
      'The European Health Insurance Card (EHIC) entitles EU/EEA citizens to '
      'state-provided healthcare during temporary stays in another EU country '
      'under the same conditions as local residents. It does NOT cover: '
      'planned treatment abroad (need S2 form), private healthcare, '
      'repatriation costs, or pre-existing conditions you travel specifically '
      'to treat. Since 2023, the EHIC is being supplemented by the European '
      'Digital Health Certificate. Apply for EHIC in your HOME country '
      'before travelling. If lost abroad, contact your home insurance for '
      'a Provisional Replacement Certificate (PRC).';

  /// Maternity care universal rights
  static const String maternityUniversalRights =
      'Under EU law and ECHR Article 3 case law, emergency obstetric care '
      'must be provided regardless of status in ALL EU countries. Many '
      'countries go further: France (PMI for all), Italy (STP covers full '
      'maternity), Spain (full SNS maternity), Portugal (full SNS maternity), '
      'Sweden (full maternity for undocumented), Ireland (Maternity and Infant '
      'Care Scheme for all), Finland (neuvola for all). Even in restrictive '
      'countries, hospitals cannot refuse a woman in labor.';

  /// Children's healthcare universal rights
  static const String childrenUniversalRights =
      'The UN Convention on the Rights of the Child (ratified by all EU states) '
      'and EU Reception Conditions Directive guarantee healthcare access for '
      'children regardless of status. In practice: Sweden provides FULL equal '
      'care to all children. Italy enrolls all under-18s in SSN. Most countries '
      'provide free vaccinations to all children. Children of asylum seekers '
      'are covered in ALL 27 EU countries.';
}
