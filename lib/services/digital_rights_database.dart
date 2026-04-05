// Digital Rights & Privacy Database for all 27 EU Countries
// Comprehensive GDPR, digital identity, surveillance, and privacy data for immigrants
// Last updated: 2026-04
//
// Sources: EU GDPR (Regulation 2016/679), European Data Protection Board (EDPB),
// national Data Protection Authorities, eIDAS Regulation, EU Digital Identity framework,
// national telecommunications laws, EU Fundamental Rights Agency (FRA),
// European Digital Rights (EDRi), national surveillance oversight bodies.

class GdprRightsInfo {
  final String rightName;
  final String article;
  final String simpleExplanation;
  final String howToExercise;
  final int responseDeadlineDays;

  const GdprRightsInfo({
    required this.rightName,
    required this.article,
    required this.simpleExplanation,
    required this.howToExercise,
    required this.responseDeadlineDays,
  });

  Map<String, dynamic> toMap() => {
    'rightName': rightName,
    'article': article,
    'simpleExplanation': simpleExplanation,
    'howToExercise': howToExercise,
    'responseDeadlineDays': responseDeadlineDays,
  };
}

class DataProtectionAuthority {
  final String country;
  final String countryCode;
  final String authorityName;
  final String authorityNameLocal;
  final String website;
  final String email;
  final String phone;
  final String address;
  final String complaintUrl;
  final List<String> languagesSupported;

  const DataProtectionAuthority({
    required this.country,
    required this.countryCode,
    required this.authorityName,
    required this.authorityNameLocal,
    required this.website,
    required this.email,
    required this.phone,
    required this.address,
    required this.complaintUrl,
    required this.languagesSupported,
  });

  Map<String, dynamic> toMap() => {
    'country': country,
    'countryCode': countryCode,
    'authorityName': authorityName,
    'authorityNameLocal': authorityNameLocal,
    'website': website,
    'email': email,
    'phone': phone,
    'address': address,
    'complaintUrl': complaintUrl,
    'languagesSupported': languagesSupported,
  };
}

class DigitalIdSystem {
  final String systemName;
  final String description;
  final bool availableToNonCitizens;
  final bool availableToResidents;
  final String howToObtain;
  final List<String> requiredDocuments;
  final String website;

  const DigitalIdSystem({
    required this.systemName,
    required this.description,
    required this.availableToNonCitizens,
    required this.availableToResidents,
    required this.howToObtain,
    required this.requiredDocuments,
    required this.website,
  });

  Map<String, dynamic> toMap() => {
    'systemName': systemName,
    'description': description,
    'availableToNonCitizens': availableToNonCitizens,
    'availableToResidents': availableToResidents,
    'howToObtain': howToObtain,
    'requiredDocuments': requiredDocuments,
    'website': website,
  };
}

class SurveillanceInfo {
  final bool publicCameraSurveillanceRegulated;
  final String publicCameraRules;
  final bool workplaceSurveillanceRegulated;
  final String workplaceCameraRules;
  final String wiretappingRules;
  final String biometricDataRules;
  final String facialRecognitionStatus;
  final String oversightBody;
  final String legalBasis;

  const SurveillanceInfo({
    required this.publicCameraSurveillanceRegulated,
    required this.publicCameraRules,
    required this.workplaceSurveillanceRegulated,
    required this.workplaceCameraRules,
    required this.wiretappingRules,
    required this.biometricDataRules,
    required this.facialRecognitionStatus,
    required this.oversightBody,
    required this.legalBasis,
  });

  Map<String, dynamic> toMap() => {
    'publicCameraSurveillanceRegulated': publicCameraSurveillanceRegulated,
    'publicCameraRules': publicCameraRules,
    'workplaceSurveillanceRegulated': workplaceSurveillanceRegulated,
    'workplaceCameraRules': workplaceCameraRules,
    'wiretappingRules': wiretappingRules,
    'biometricDataRules': biometricDataRules,
    'facialRecognitionStatus': facialRecognitionStatus,
    'oversightBody': oversightBody,
    'legalBasis': legalBasis,
  };
}

class CountryDigitalRights {
  final String country;
  final String countryCode;
  final DataProtectionAuthority dpa;
  final List<DigitalIdSystem> digitalIdSystems;
  final bool simCardRegistrationRequired;
  final String simCardRequirements;
  final String internetAccessRights;
  final List<String> governmentDigitalServices;
  final String govServicesAccessUrl;
  final String socialMediaRights;
  final String freedomOfExpressionLimits;
  final SurveillanceInfo surveillance;
  final String cookieConsentRules;
  final String immigrantSpecificDigitalRights;
  final String dataPortabilityNotes;
  final String rightToBeForgottenNotes;

  const CountryDigitalRights({
    required this.country,
    required this.countryCode,
    required this.dpa,
    required this.digitalIdSystems,
    required this.simCardRegistrationRequired,
    required this.simCardRequirements,
    required this.internetAccessRights,
    required this.governmentDigitalServices,
    required this.govServicesAccessUrl,
    required this.socialMediaRights,
    required this.freedomOfExpressionLimits,
    required this.surveillance,
    required this.cookieConsentRules,
    required this.immigrantSpecificDigitalRights,
    required this.dataPortabilityNotes,
    required this.rightToBeForgottenNotes,
  });

  Map<String, dynamic> toMap() => {
    'country': country,
    'countryCode': countryCode,
    'dpa': dpa.toMap(),
    'digitalIdSystems': digitalIdSystems.map((s) => s.toMap()).toList(),
    'simCardRegistrationRequired': simCardRegistrationRequired,
    'simCardRequirements': simCardRequirements,
    'internetAccessRights': internetAccessRights,
    'governmentDigitalServices': governmentDigitalServices,
    'govServicesAccessUrl': govServicesAccessUrl,
    'socialMediaRights': socialMediaRights,
    'freedomOfExpressionLimits': freedomOfExpressionLimits,
    'surveillance': surveillance.toMap(),
    'cookieConsentRules': cookieConsentRules,
    'immigrantSpecificDigitalRights': immigrantSpecificDigitalRights,
    'dataPortabilityNotes': dataPortabilityNotes,
    'rightToBeForgottenNotes': rightToBeForgottenNotes,
  };
}

class DigitalRightsDatabase {
  static final DigitalRightsDatabase _instance =
      DigitalRightsDatabase._internal();
  factory DigitalRightsDatabase() => _instance;
  DigitalRightsDatabase._internal();

  // ============================================================
  // UNIVERSAL GDPR RIGHTS (apply to ALL 27 EU countries)
  // ============================================================

  static const List<GdprRightsInfo> universalGdprRights = [
    GdprRightsInfo(
      rightName: 'Right of Access',
      article: 'Article 15 GDPR',
      simpleExplanation:
          'You can ask any company or organization what personal data they have about you. '
          'They must give you a copy of all your data for free. This includes your name, '
          'address, phone records, purchase history, location data, and anything else linked to you.',
      howToExercise:
          'Send an email or letter to the company\'s Data Protection Officer (DPO) or privacy contact. '
          'Write: "Under Article 15 GDPR, I request access to all personal data you hold about me." '
          'Include your full name and any account identifiers. They must respond within 30 days.',
      responseDeadlineDays: 30,
    ),
    GdprRightsInfo(
      rightName: 'Right to Rectification',
      article: 'Article 16 GDPR',
      simpleExplanation:
          'If a company has wrong information about you (wrong name spelling, old address, '
          'incorrect nationality), you have the right to get it corrected immediately.',
      howToExercise:
          'Contact the company and specify exactly what data is incorrect and what the correct '
          'data should be. Provide proof if possible (e.g., passport copy for name correction). '
          'They must fix it without undue delay.',
      responseDeadlineDays: 30,
    ),
    GdprRightsInfo(
      rightName: 'Right to Erasure (Right to be Forgotten)',
      article: 'Article 17 GDPR',
      simpleExplanation:
          'You can ask any company to delete all your personal data. This is very powerful - '
          'they must delete everything unless they have a legal obligation to keep it '
          '(like tax records). Social media posts, old accounts, marketing databases - '
          'all can be deleted on your request.',
      howToExercise:
          'Send a written request: "Under Article 17 GDPR, I request the erasure of all my '
          'personal data." Be specific about what you want deleted. The company can only refuse '
          'if they have a legal obligation to keep the data, need it for legal claims, or '
          'it serves the public interest. If they shared your data with others, they must '
          'tell those parties to delete it too.',
      responseDeadlineDays: 30,
    ),
    GdprRightsInfo(
      rightName: 'Right to Data Portability',
      article: 'Article 20 GDPR',
      simpleExplanation:
          'You can ask a company to give you all your data in a common digital format '
          '(like CSV or JSON) so you can take it to another service. For example, you can '
          'move your data from one bank to another, or from one email provider to another.',
      howToExercise:
          'Request your data in a "structured, commonly used, machine-readable format." '
          'The company must provide it. You can also ask them to transfer it directly '
          'to another company if technically feasible.',
      responseDeadlineDays: 30,
    ),
    GdprRightsInfo(
      rightName: 'Right to Restrict Processing',
      article: 'Article 18 GDPR',
      simpleExplanation:
          'You can tell a company to stop using your data while you dispute something. '
          'For example, if you think data is wrong, or you object to how they use it, '
          'they must freeze your data until the dispute is resolved.',
      howToExercise:
          'Write to the company requesting restriction of processing under Article 18. '
          'State the reason: data inaccuracy, unlawful processing, or you need the data '
          'for legal claims. They can still store the data but cannot use it.',
      responseDeadlineDays: 30,
    ),
    GdprRightsInfo(
      rightName: 'Right to Object',
      article: 'Article 21 GDPR',
      simpleExplanation:
          'You can object to a company using your data for direct marketing at any time '
          'and they must stop immediately. You can also object to profiling and automated '
          'decision-making that affects you.',
      howToExercise:
          'For marketing: simply say "I object to processing of my data for marketing '
          'purposes" - they must stop immediately, no questions asked. For other processing: '
          'explain your specific situation and why the processing affects you.',
      responseDeadlineDays: 30,
    ),
    GdprRightsInfo(
      rightName: 'Right Not to be Subject to Automated Decisions',
      article: 'Article 22 GDPR',
      simpleExplanation:
          'If a computer algorithm makes a decision about you (loan approval, job screening, '
          'visa scoring), you have the right to know about it and to request a human review. '
          'This is especially important for immigrants facing automated immigration decisions.',
      howToExercise:
          'Ask the organization: "Was any automated decision-making or profiling used in my case?" '
          'If yes, you can demand: (1) human intervention, (2) to express your point of view, '
          'and (3) to contest the decision. They must provide meaningful information about '
          'the logic involved.',
      responseDeadlineDays: 30,
    ),
    GdprRightsInfo(
      rightName: 'Right to be Informed',
      article: 'Articles 13-14 GDPR',
      simpleExplanation:
          'Before collecting your data, any organization must tell you: who they are, why they '
          'need your data, who they will share it with, how long they will keep it, and what '
          'rights you have. This must be in clear, plain language.',
      howToExercise:
          'If an organization collects your data without informing you properly, you can '
          'complain to the national Data Protection Authority. Check their privacy policy - '
          'if it is unclear or missing, they are violating GDPR.',
      responseDeadlineDays: 0,
    ),
    GdprRightsInfo(
      rightName: 'Right to Lodge a Complaint',
      article: 'Article 77 GDPR',
      simpleExplanation:
          'If any company or government body violates your data rights, you can file a '
          'complaint with your country\'s Data Protection Authority for free. You do NOT '
          'need a lawyer. You do NOT need to be a citizen - GDPR protects everyone in the EU.',
      howToExercise:
          'Go to your country\'s Data Protection Authority website. Most have online complaint '
          'forms. Describe what happened, which organization violated your rights, and what '
          'you want. The authority must investigate and inform you of the outcome.',
      responseDeadlineDays: 90,
    ),
    GdprRightsInfo(
      rightName: 'Right to Compensation',
      article: 'Article 82 GDPR',
      simpleExplanation:
          'If you suffered damage (financial loss, emotional distress) because of a GDPR '
          'violation, you can sue for compensation in court. This applies to both material '
          'and non-material damage.',
      howToExercise:
          'You can bring a claim before the courts of the EU member state where the company '
          'is established or where you live. Consider contacting a consumer rights organization '
          'that may support collective claims.',
      responseDeadlineDays: 0,
    ),
  ];

  // ============================================================
  // HOW TO FILE A GDPR COMPLAINT (step-by-step)
  // ============================================================

  static const List<String> gdprComplaintSteps = [
    'Step 1: Contact the company first. Write to their Data Protection Officer (DPO) or privacy email. '
        'Give them 30 days to respond.',
    'Step 2: If they do not respond or you are not satisfied, go to your country\'s '
        'Data Protection Authority (DPA) website.',
    'Step 3: Find the online complaint form. Most DPAs have forms in the national language and English.',
    'Step 4: Fill in: your name, the company name, what happened, when it happened, '
        'what GDPR right was violated, and what you want.',
    'Step 5: Attach evidence: copies of your emails to the company, their response (if any), '
        'screenshots, etc.',
    'Step 6: Submit the complaint. You will receive a reference number.',
    'Step 7: The DPA will investigate. This can take 3-12 months depending on complexity.',
    'Step 8: The DPA will inform you of the outcome. They can fine the company up to '
        '4% of global revenue or EUR 20 million.',
    'Important: You do NOT need to be a citizen or permanent resident. GDPR protects '
        'EVERYONE physically present in the EU.',
    'Important: The complaint is FREE. You do NOT need a lawyer.',
    'Important: You can file in ANY EU country where the violation occurred or where '
        'the company is based.',
  ];

  // ============================================================
  // COOKIE CONSENT RIGHTS (universal EU rules)
  // ============================================================

  static const List<String> cookieConsentRights = [
    'Every website must ask your consent BEFORE placing non-essential cookies.',
    'You must be able to REFUSE cookies as easily as you accept them (no dark patterns).',
    'Pre-ticked boxes are illegal - consent must be an active choice.',
    'The website must work even if you refuse all optional cookies.',
    'You can withdraw consent at any time.',
    'Essential cookies (login, shopping cart) do not need consent.',
    'Analytics and advertising cookies ALWAYS need consent.',
    'Cookie walls (blocking content until you accept) are illegal in most EU countries.',
    'The ePrivacy Directive (2002/58/EC) and GDPR together govern cookie rules.',
    'If a website ignores your cookie preferences, report it to the national DPA.',
  ];

  // ============================================================
  // DATA REQUEST TEMPLATE
  // ============================================================

  static const String dataAccessRequestTemplate = '''
Subject: Data Access Request under Article 15 GDPR

Dear Data Protection Officer,

Under Article 15 of the General Data Protection Regulation (EU) 2016/679, I am requesting access to all personal data you hold about me.

My details:
- Full name: [YOUR NAME]
- Email address: [YOUR EMAIL]
- Account number/ID (if applicable): [YOUR ID]
- Date of birth: [YOUR DOB]

Please provide:
1. A copy of all personal data you process about me
2. The purposes of processing
3. The categories of personal data concerned
4. The recipients or categories of recipients to whom data has been disclosed
5. The envisaged storage period
6. Information about the source of data (if not collected from me directly)
7. Whether automated decision-making/profiling is used

Under GDPR, you must respond within 30 calendar days. This request is free of charge.

If you do not comply, I will file a complaint with the national Data Protection Authority.

Yours sincerely,
[YOUR NAME]
[YOUR ADDRESS]
[DATE]
''';

  static const String dataErasureRequestTemplate = '''
Subject: Right to Erasure Request under Article 17 GDPR

Dear Data Protection Officer,

Under Article 17 of the General Data Protection Regulation (EU) 2016/679, I request the erasure of all personal data you hold about me.

My details:
- Full name: [YOUR NAME]
- Email address: [YOUR EMAIL]
- Account number/ID (if applicable): [YOUR ID]

I request that you:
1. Delete all my personal data from your systems
2. Inform any third parties with whom you have shared my data to also erase it (Article 17(2))
3. Confirm the deletion in writing within 30 days

Under GDPR, you must comply unless you have a specific legal obligation to retain the data. If you refuse, please provide the specific legal basis.

If you do not comply, I will file a complaint with the national Data Protection Authority.

Yours sincerely,
[YOUR NAME]
[YOUR ADDRESS]
[DATE]
''';

  // ============================================================
  // 27 EU COUNTRIES - DIGITAL RIGHTS DATA
  // ============================================================

  static const List<CountryDigitalRights> allCountries = [

    // ==================== AUSTRIA ====================
    CountryDigitalRights(
      country: 'Austria',
      countryCode: 'AT',
      dpa: DataProtectionAuthority(
        country: 'Austria',
        countryCode: 'AT',
        authorityName: 'Austrian Data Protection Authority',
        authorityNameLocal: 'Datenschutzbehörde (DSB)',
        website: 'https://www.dsb.gv.at',
        email: 'dsb@dsb.gv.at',
        phone: '+43 1 52152-0',
        address: 'Barichgasse 40-42, 1030 Wien',
        complaintUrl: 'https://www.dsb.gv.at/download-links/formulare.html',
        languagesSupported: ['German', 'English'],
      ),
      digitalIdSystems: [
        DigitalIdSystem(
          systemName: 'Handy-Signatur / ID Austria',
          description: 'Mobile phone-based digital signature and identity system. '
              'Replaced the old Bürgerkarte. Used for government services, tax filing, '
              'and legal document signing.',
          availableToNonCitizens: true,
          availableToResidents: true,
          howToObtain: 'Register at a registration authority (Registrierungsstelle) with '
              'your passport/ID and residence permit. Can be activated at post offices, '
              'tax offices, or online with video identification.',
          requiredDocuments: ['Valid passport or national ID', 'Residence registration (Meldezettel)', 'Austrian phone number'],
          website: 'https://www.oesterreich.gv.at/id-austria.html',
        ),
      ],
      simCardRegistrationRequired: true,
      simCardRequirements: 'Since 2019, prepaid SIM cards require identity verification. '
          'You must provide a valid ID (passport, residence permit) at purchase. '
          'Telecom providers must verify identity before activation.',
      internetAccessRights: 'Universal service obligation includes broadband internet access. '
          'Net neutrality protected under EU regulation. No government internet censorship. '
          'ISPs must not discriminate based on nationality.',
      governmentDigitalServices: [
        'oesterreich.gv.at - Central government portal for all services',
        'FinanzOnline - Tax filing and financial administration',
        'ELGA - Electronic health records',
        'eAMS - Online employment service (AMS)',
        'Sozialversicherung.at - Social insurance portal',
      ],
      govServicesAccessUrl: 'https://www.oesterreich.gv.at',
      socialMediaRights: 'Freedom of expression protected under Article 13 Austrian Constitution. '
          'Hate speech (Verhetzung, §283 StGB) carries up to 2 years imprisonment. '
          'Social media companies must remove illegal content within 24 hours under '
          'the Communications Platforms Act (KoPl-G).',
      freedomOfExpressionLimits: 'Prohibited: Nazi symbols/glorification, hate speech against '
          'protected groups, Holocaust denial, defamation, incitement to violence.',
      surveillance: SurveillanceInfo(
        publicCameraSurveillanceRegulated: true,
        publicCameraRules: 'Public CCTV requires legitimate interest and must be proportionate. '
            'Signs must inform about surveillance. Data retention limited to 72 hours '
            'unless incident occurs. Regulated by DSG (Datenschutzgesetz).',
        workplaceSurveillanceRegulated: true,
        workplaceCameraRules: 'Workplace cameras require works council agreement. '
            'Continuous monitoring of employees is prohibited. Cameras in break rooms, '
            'toilets, and changing rooms are strictly forbidden.',
        wiretappingRules: 'Phone tapping requires court order. Only permitted for serious '
            'crimes (sentences > 1 year). Oversight by Legal Protection Commissioner '
            '(Rechtsschutzbeauftragter). Data retention was struck down by Constitutional Court.',
        biometricDataRules: 'Biometric data classified as special category under GDPR Art. 9. '
            'Fingerprints collected for residence permits under EU regulation. '
            'Workplace biometric access requires employee consent and works council approval.',
        facialRecognitionStatus: 'No general facial recognition in public spaces. '
            'Police use limited to specific investigations with court authorization.',
        oversightBody: 'Rechtsschutzbeauftragter (Legal Protection Commissioner)',
        legalBasis: 'Datenschutzgesetz (DSG), Sicherheitspolizeigesetz (SPG), '
            'Telekommunikationsgesetz (TKG 2021)',
      ),
      cookieConsentRules: 'Strict consent required under TKG 2021 §165. Austrian DSB actively '
          'enforces cookie consent. Fines issued for non-compliant cookie banners.',
      immigrantSpecificDigitalRights: 'Immigrants with valid residence permits have equal digital rights. '
          'ID Austria available to all registered residents. GDPR applies regardless of '
          'nationality or immigration status. Translation services available at DSB.',
      dataPortabilityNotes: 'Telecom providers must allow number portability within 1 business day. '
          'Bank account portability supported under Payment Accounts Directive.',
      rightToBeForgottenNotes: 'Austrian courts have actively upheld the right to be forgotten. '
          'Notable case law on search engine delisting. DSB handles erasure complaints efficiently.',
    ),

    // ==================== BELGIUM ====================
    CountryDigitalRights(
      country: 'Belgium',
      countryCode: 'BE',
      dpa: DataProtectionAuthority(
        country: 'Belgium',
        countryCode: 'BE',
        authorityName: 'Belgian Data Protection Authority',
        authorityNameLocal: 'Autorité de protection des données (APD) / Gegevensbeschermingsautoriteit (GBA)',
        website: 'https://www.dataprotectionauthority.be',
        email: 'contact@apd-gba.be',
        phone: '+32 2 274 48 00',
        address: 'Rue de la Presse 35, 1000 Brussels',
        complaintUrl: 'https://www.dataprotectionauthority.be/citizen/actions/lodge-a-complaint',
        languagesSupported: ['French', 'Dutch', 'German', 'English'],
      ),
      digitalIdSystems: [
        DigitalIdSystem(
          systemName: 'eID (Electronic Identity Card)',
          description: 'Belgian electronic ID card with embedded chip for digital authentication. '
              'Used for government services, banking, tax filing, and legally binding signatures.',
          availableToNonCitizens: false,
          availableToResidents: true,
          howToObtain: 'Non-EU residents receive an electronic foreigner card (A, B, C, D, E, F, H cards) '
              'from their commune. These have similar digital functionality to the Belgian eID.',
          requiredDocuments: ['Valid passport', 'Residence permit', 'Registration at commune'],
          website: 'https://eid.belgium.be',
        ),
        DigitalIdSystem(
          systemName: 'itsme',
          description: 'Mobile digital identity app widely used in Belgium for banking, '
              'government services, and signing documents. Linked to eID or bank card.',
          availableToNonCitizens: true,
          availableToResidents: true,
          howToObtain: 'Download the itsme app and register using your Belgian eID card or '
              'electronic foreigner card, or through participating banks.',
          requiredDocuments: ['Belgian eID or electronic foreigner card', 'Belgian phone number'],
          website: 'https://www.itsme-id.com',
        ),
      ],
      simCardRegistrationRequired: true,
      simCardRequirements: 'Since 2016, prepaid SIM cards require identification. Buyers must '
          'present valid ID (passport, residence card). Operators must verify and store identity '
          'data. Anonymous prepaid cards are not available.',
      internetAccessRights: 'Universal service includes functional internet access. '
          'Net neutrality enforced by BIPT (telecom regulator). Belgium has one of the '
          'highest broadband penetration rates in EU.',
      governmentDigitalServices: [
        'MyGovernment.be (Mijn Burgerprofiel) - Central citizen portal',
        'Tax-on-web - Online tax declarations',
        'eHealth platform - Health services and vaccination records',
        'My Career (Mijn Loopbaan) - Employment services',
        'CSAM - Federal Authentication Service',
      ],
      govServicesAccessUrl: 'https://www.belgium.be/en',
      socialMediaRights: 'Freedom of expression protected by Constitution Article 25. '
          'Belgium has strict anti-discrimination laws (Anti-Racism Act 1981, Anti-Discrimination Act 2007). '
          'Online hate speech prosecuted. Negationism of genocide is a criminal offense.',
      freedomOfExpressionLimits: 'Prohibited: hate speech, negationism (Holocaust/genocide denial), '
          'racism, sexism in public spaces (including online), cyberbullying, revenge pornography.',
      surveillance: SurveillanceInfo(
        publicCameraSurveillanceRegulated: true,
        publicCameraRules: 'Camera Surveillance Act (2007) requires prior authorization from '
            'municipal council for public cameras. Must display pictograms. Data retained '
            'max 30 days for public spaces.',
        workplaceSurveillanceRegulated: true,
        workplaceCameraRules: 'CBA No. 68 (1998) strictly regulates workplace surveillance. '
            'Employees must be informed. Hidden cameras only in case of criminal investigation. '
            'Works council must be consulted.',
        wiretappingRules: 'Court order required (investigating judge). Only for offenses '
            'punishable by 1+ years. Maximum duration 1 month, renewable. Oversight by '
            'Standing Intelligence Agencies Review Committee (Comité R/I).',
        biometricDataRules: 'Fingerprints on eID cards since 2019. Constitutional Court upheld '
            'this but with strict safeguards. Workplace biometrics require DPIA and consent.',
        facialRecognitionStatus: 'Brussels police pilot with facial recognition was controversial. '
            'No widespread deployment. DPA has issued warnings about proportionality.',
        oversightBody: 'Comité R (intelligence oversight), Comité P (police oversight)',
        legalBasis: 'Camera Surveillance Act 2007, Telecommunications Act, '
            'Intelligence Services Act 1998',
      ),
      cookieConsentRules: 'Belgian DPA has been active on cookie enforcement. Issued major fine '
          'to IAB Europe for TCF cookie consent framework (2022). Strict opt-in required.',
      immigrantSpecificDigitalRights: 'Electronic foreigner cards provide similar digital access as '
          'Belgian eID. GDPR rights apply equally. DPA accepts complaints in French, Dutch, '
          'German, and English. Asylum seekers can access basic digital services through FEDASIL.',
      dataPortabilityNotes: 'Strong telecom portability (number transfer within 1 day). '
          'Banking portability supported. Easy Switch mechanism for energy and telecom.',
      rightToBeForgottenNotes: 'Belgian DPA has handled multiple right to erasure cases. '
          'Belgian courts follow CJEU Google Spain ruling for search engine delisting.',
    ),

    // ==================== BULGARIA ====================
    CountryDigitalRights(
      country: 'Bulgaria',
      countryCode: 'BG',
      dpa: DataProtectionAuthority(
        country: 'Bulgaria',
        countryCode: 'BG',
        authorityName: 'Commission for Personal Data Protection',
        authorityNameLocal: 'Комисия за защита на личните данни (КЗЛД)',
        website: 'https://www.cpdp.bg',
        email: 'kzld@cpdp.bg',
        phone: '+359 2 915 3518',
        address: 'Prof. Tsvetan Lazarov Blvd. 2, 1592 Sofia',
        complaintUrl: 'https://www.cpdp.bg/en/index.php?p=rubric&aid=6',
        languagesSupported: ['Bulgarian', 'English'],
      ),
      digitalIdSystems: [
        DigitalIdSystem(
          systemName: 'Bulgarian eID',
          description: 'Electronic identity card with digital signature capability. '
              'Used for e-government services and electronic signatures.',
          availableToNonCitizens: false,
          availableToResidents: true,
          howToObtain: 'Non-citizens receive a residence permit card with electronic features. '
              'Apply at the Migration Directorate.',
          requiredDocuments: ['Valid passport', 'Residence permit', 'Address registration'],
          website: 'https://www.mvr.bg/en',
        ),
      ],
      simCardRegistrationRequired: true,
      simCardRequirements: 'Prepaid SIM registration required since 2010. Must present valid ID '
          '(passport, residence card) and provide personal details. Anonymous SIMs not available.',
      internetAccessRights: 'Universal service includes internet access. Net neutrality enforced '
          'under EU framework. Bulgaria has affordable mobile data prices in EU.',
      governmentDigitalServices: [
        'egov.bg - E-Government portal',
        'NRA portal - National Revenue Agency tax services',
        'NSSI - Social security electronic services',
        'NZOK - Health insurance fund portal',
        'eJustice - Court system electronic services',
      ],
      govServicesAccessUrl: 'https://egov.bg',
      socialMediaRights: 'Freedom of expression protected by Constitution Article 39-40. '
          'Media freedom generally respected. Hate speech criminalized under Penal Code.',
      freedomOfExpressionLimits: 'Prohibited: incitement to discrimination, hate speech based on '
          'race/ethnicity/religion, defamation (still criminal offense), state secrets disclosure.',
      surveillance: SurveillanceInfo(
        publicCameraSurveillanceRegulated: true,
        publicCameraRules: 'CCTV in public spaces regulated by Personal Data Protection Act. '
            'Must notify with signs. Police CCTV in major cities for traffic and security.',
        workplaceSurveillanceRegulated: true,
        workplaceCameraRules: 'Employer must inform employees about surveillance. Cannot monitor '
            'private spaces. CPDP guidelines require proportionality assessment.',
        wiretappingRules: 'Court order required from Sofia City Court (special panel). '
            'Only for serious crimes. Maximum 180 days. Annual reports published on '
            'number of wiretaps authorized.',
        biometricDataRules: 'Biometric data in ID documents under EU regulation. '
            'Fingerprints stored for residence permits. Workplace biometrics need consent.',
        facialRecognitionStatus: 'Limited use. Border control uses biometric verification. '
            'No widespread public facial recognition systems.',
        oversightBody: 'Parliamentary Committee on Surveillance',
        legalBasis: 'Personal Data Protection Act 2019, Electronic Communications Act, '
            'Special Surveillance Means Act',
      ),
      cookieConsentRules: 'Electronic Communications Act requires consent for cookies. '
          'Enforcement has been less active compared to Western EU members.',
      immigrantSpecificDigitalRights: 'GDPR applies equally to all residents regardless of status. '
          'Digital services accessible with residence permit. CPDP accepts complaints '
          'in Bulgarian; English assistance may be limited.',
      dataPortabilityNotes: 'Number portability available. Banking portability developing. '
          'CRC (Communications Regulation Commission) oversees telecom portability.',
      rightToBeForgottenNotes: 'CPDP handles erasure requests. Implementation follows GDPR '
          'standards. Court system may be slow for complex cases.',
    ),

    // ==================== CROATIA ====================
    CountryDigitalRights(
      country: 'Croatia',
      countryCode: 'HR',
      dpa: DataProtectionAuthority(
        country: 'Croatia',
        countryCode: 'HR',
        authorityName: 'Croatian Personal Data Protection Agency',
        authorityNameLocal: 'Agencija za zaštitu osobnih podataka (AZOP)',
        website: 'https://azop.hr',
        email: 'azop@azop.hr',
        phone: '+385 1 4609 000',
        address: 'Fra Grge Martića 14, 10000 Zagreb',
        complaintUrl: 'https://azop.hr/prava-ispitanika/',
        languagesSupported: ['Croatian', 'English'],
      ),
      digitalIdSystems: [
        DigitalIdSystem(
          systemName: 'e-Građani (e-Citizens)',
          description: 'Central government e-services system providing access to over 100 '
              'digital public services through a single authentication.',
          availableToNonCitizens: true,
          availableToResidents: true,
          howToObtain: 'Register at FINA offices (Financial Agency) or Police administration. '
              'Foreign residents can register with valid residence permit.',
          requiredDocuments: ['Valid passport or ID', 'Residence permit (for non-citizens)', 'OIB (personal identification number)'],
          website: 'https://gov.hr',
        ),
      ],
      simCardRegistrationRequired: true,
      simCardRequirements: 'Prepaid SIM cards require identification since 2009. Must present '
          'valid ID document. Operators must verify identity before activation.',
      internetAccessRights: 'Universal service includes broadband. HAKOM (telecom regulator) '
          'enforces net neutrality. Good mobile coverage across the country.',
      governmentDigitalServices: [
        'e-Građani (gov.hr) - Central citizen portal',
        'e-Porezna - Tax administration portal',
        'e-HZZO - Health insurance services',
        'e-Matice - Civil registry electronic services',
        'e-Pravosudje - Electronic justice services',
      ],
      govServicesAccessUrl: 'https://gov.hr',
      socialMediaRights: 'Freedom of expression protected by Constitution Article 38. '
          'Hate speech criminalized under Criminal Code Article 325.',
      freedomOfExpressionLimits: 'Prohibited: hate speech, incitement to violence/discrimination, '
          'insult based on race/religion/ethnicity/sexual orientation, Holocaust denial.',
      surveillance: SurveillanceInfo(
        publicCameraSurveillanceRegulated: true,
        publicCameraRules: 'GDPR implementation act regulates video surveillance. '
            'Mandatory notification signs. Data retention limited.',
        workplaceSurveillanceRegulated: true,
        workplaceCameraRules: 'Labour Act requires employee notification. Cannot monitor '
            'private spaces. Works council must be consulted.',
        wiretappingRules: 'Court order required (investigating judge). Only for crimes '
            'with 5+ years sentence. Oversight by Data Protection Agency.',
        biometricDataRules: 'Biometric data in travel documents under EU regulation. '
            'AZOP oversees biometric data processing compliance.',
        facialRecognitionStatus: 'No widespread public facial recognition. '
            'Border control uses EU standard biometric checks.',
        oversightBody: 'AZOP and Parliamentary Committee',
        legalBasis: 'GDPR Implementation Act 2018, Electronic Communications Act, '
            'Criminal Procedure Act',
      ),
      cookieConsentRules: 'Electronic Communications Act requires prior consent for cookies. '
          'AZOP enforces cookie compliance.',
      immigrantSpecificDigitalRights: 'EU/EEA citizens and residents with OIB have equal digital access. '
          'e-Građani system available to all registered residents. '
          'AZOP provides guidance in Croatian and English.',
      dataPortabilityNotes: 'Number portability available within 3 days. HAKOM oversees process.',
      rightToBeForgottenNotes: 'AZOP processes erasure complaints under GDPR Article 17. '
          'Croatian courts recognize the right following CJEU jurisprudence.',
    ),

    // ==================== CYPRUS ====================
    CountryDigitalRights(
      country: 'Cyprus',
      countryCode: 'CY',
      dpa: DataProtectionAuthority(
        country: 'Cyprus',
        countryCode: 'CY',
        authorityName: 'Commissioner for Personal Data Protection',
        authorityNameLocal: 'Γραφείο Επιτρόπου Προστασίας Δεδομένων Προσωπικού Χαρακτήρα',
        website: 'http://www.dataprotection.gov.cy',
        email: 'commissioner@dataprotection.gov.cy',
        phone: '+357 22 818 456',
        address: 'Iasonos 1, 1082 Nicosia',
        complaintUrl: 'http://www.dataprotection.gov.cy/dataprotection/dataprotection.nsf/page1e_en/page1e_en?opendocument',
        languagesSupported: ['Greek', 'English'],
      ),
      digitalIdSystems: [
        DigitalIdSystem(
          systemName: 'CY Login / Ariadni',
          description: 'Government digital service portal providing single sign-on access '
              'to Cypriot government e-services.',
          availableToNonCitizens: true,
          availableToResidents: true,
          howToObtain: 'Register online with Alien Registration Certificate (ARC) or '
              'Cypriot ID details through the Ariadni portal.',
          requiredDocuments: ['Valid ID or ARC', 'Cyprus address', 'Email and phone number'],
          website: 'https://cge.cyprus.gov.cy',
        ),
      ],
      simCardRegistrationRequired: false,
      simCardRequirements: 'Cyprus does not currently require mandatory prepaid SIM registration. '
          'Prepaid SIM cards can be purchased with minimal identification. However, '
          'postpaid contracts require standard identity verification.',
      internetAccessRights: 'Universal service includes internet access under EU framework. '
          'OCECPR (Office of the Commissioner of Electronic Communications) regulates. '
          'Net neutrality enforced.',
      governmentDigitalServices: [
        'Ariadni portal - Central government e-services',
        'TAXISnet - Tax services portal',
        'Social Insurance Services online portal',
        'eCourt - Electronic court services',
        'JCC Smart - Various government payment services',
      ],
      govServicesAccessUrl: 'https://cge.cyprus.gov.cy',
      socialMediaRights: 'Freedom of expression protected by Constitution Article 19. '
          'Criminal defamation still exists. Anti-discrimination legislation covers online speech.',
      freedomOfExpressionLimits: 'Prohibited: defamation (criminal), incitement to ethnic hatred, '
          'publishing false news likely to disturb public order.',
      surveillance: SurveillanceInfo(
        publicCameraSurveillanceRegulated: true,
        publicCameraRules: 'Commissioner guidelines regulate CCTV. Must display notices. '
            'Proportionality principle applies. Data retention limited.',
        workplaceSurveillanceRegulated: true,
        workplaceCameraRules: 'Employee notification required. Proportionality test applies. '
            'Commissioner has issued guidelines on workplace monitoring.',
        wiretappingRules: 'Court order required under Interception of Communications Act. '
            'Only for serious offenses. Attorney General oversight.',
        biometricDataRules: 'Biometric data in travel documents per EU regulation. '
            'Special category data under GDPR Article 9 protections apply.',
        facialRecognitionStatus: 'No widespread facial recognition deployment. '
            'Standard border control biometric checks.',
        oversightBody: 'Commissioner for Personal Data Protection',
        legalBasis: 'Processing of Personal Data (Protection of the Individual) Law 2018, '
            'Interception of Communications Act',
      ),
      cookieConsentRules: 'Regulation of Electronic Communications Act requires cookie consent. '
          'Commissioner provides guidance on compliance.',
      immigrantSpecificDigitalRights: 'All residents including third-country nationals with ARC '
          'can access digital government services. GDPR protects everyone in Cyprus '
          'regardless of status. Commissioner accepts complaints in Greek and English.',
      dataPortabilityNotes: 'Number portability available. OCECPR ensures compliance.',
      rightToBeForgottenNotes: 'Commissioner handles erasure requests under GDPR. '
          'English-language complaint process available.',
    ),

    // ==================== CZECH REPUBLIC ====================
    CountryDigitalRights(
      country: 'Czech Republic',
      countryCode: 'CZ',
      dpa: DataProtectionAuthority(
        country: 'Czech Republic',
        countryCode: 'CZ',
        authorityName: 'Office for Personal Data Protection',
        authorityNameLocal: 'Úřad pro ochranu osobních údajů (ÚOOÚ)',
        website: 'https://www.uoou.cz',
        email: 'posta@uoou.cz',
        phone: '+420 234 665 111',
        address: 'Pplk. Sochora 27, 170 00 Prague 7',
        complaintUrl: 'https://www.uoou.cz/en/vismo/zobraz_dok.asp?id_org=200156&id_ktg=1420',
        languagesSupported: ['Czech', 'English'],
      ),
      digitalIdSystems: [
        DigitalIdSystem(
          systemName: 'eIdentita / NIA',
          description: 'National Identity Authority system for electronic identification. '
              'Uses eID card, NIA ID, or bank identity for government service access.',
          availableToNonCitizens: true,
          availableToResidents: true,
          howToObtain: 'Register through Czech POINT offices using residence permit, or '
              'use Bank Identity (bankovní identita) from participating Czech banks.',
          requiredDocuments: ['Valid passport', 'Residence permit', 'Czech address registration'],
          website: 'https://www.eidentita.cz',
        ),
        DigitalIdSystem(
          systemName: 'Bank Identity (Bankovní identita)',
          description: 'Identity verification through Czech banks. Widely used alternative '
              'to eID card for accessing government services.',
          availableToNonCitizens: true,
          availableToResidents: true,
          howToObtain: 'Activate through your Czech bank account. Most major banks support it. '
              'Requires existing bank account with verified identity.',
          requiredDocuments: ['Czech bank account', 'Previously verified identity at bank'],
          website: 'https://www.bankovni-identita.cz',
        ),
      ],
      simCardRegistrationRequired: true,
      simCardRequirements: 'Since 2024, prepaid SIM cards require identity verification. '
          'Must provide valid ID (passport, residence permit). Transitional period for existing cards.',
      internetAccessRights: 'Universal service defined by Electronic Communications Act. '
          'CTU (Czech Telecommunication Office) regulates. Net neutrality enforced. '
          'Very competitive mobile data market with affordable prices.',
      governmentDigitalServices: [
        'Portál občana (Citizen Portal) - Central e-government portal',
        'Daňový portál - Tax portal (EPO)',
        'ePortál ČSSZ - Social security services',
        'Registr vozidel - Vehicle registry',
        'Czech POINT - Assisted contact points for digital services',
      ],
      govServicesAccessUrl: 'https://obcan.portal.gov.cz',
      socialMediaRights: 'Freedom of expression protected by Constitution (Charter of Fundamental Rights). '
          'Czech Republic has relatively liberal free speech protections.',
      freedomOfExpressionLimits: 'Prohibited: defamation (civil + criminal), incitement to hatred, '
          'denial/approval/justification of genocide, support for movements suppressing rights.',
      surveillance: SurveillanceInfo(
        publicCameraSurveillanceRegulated: true,
        publicCameraRules: 'ÚOOÚ regulates CCTV use. Municipal police cameras widespread in cities. '
            'Notification required. Data retention varies by purpose.',
        workplaceSurveillanceRegulated: true,
        workplaceCameraRules: 'Labour Code §316 regulates. Must not infringe privacy. '
            'Employee notification required. Monitoring of personal communications limited.',
        wiretappingRules: 'Court order from judge required. Only for crimes with 8+ years sentence '
            'or specific organized crime offenses. Max 4 months, renewable. '
            'Parliamentary oversight committee reviews annually.',
        biometricDataRules: 'Biometric data in travel documents per EU regulation. '
            'ÚOOÚ strictly oversees biometric data processing.',
        facialRecognitionStatus: 'Police have limited facial recognition capabilities. '
            'No mass surveillance deployment. ÚOOÚ has raised concerns about expansion.',
        oversightBody: 'Parliamentary Committee on Intelligence Services Oversight',
        legalBasis: 'Act on Personal Data Processing 2019, Electronic Communications Act, '
            'Police Act, Intelligence Services Act',
      ),
      cookieConsentRules: 'Electronic Communications Act requires consent. ÚOOÚ has issued '
          'guidance on cookie walls and consent mechanisms. Active enforcement increasing.',
      immigrantSpecificDigitalRights: 'Residents with biometric residence permits can access most '
          'digital services. Bank Identity accessible to all bank account holders. '
          'GDPR protections apply equally. ÚOOÚ provides English guidance.',
      dataPortabilityNotes: 'Number portability within 2 working days. Very competitive telecom market.',
      rightToBeForgottenNotes: 'ÚOOÚ processes erasure requests. Czech courts follow CJEU case law. '
          'Generally efficient handling of complaints.',
    ),

    // ==================== DENMARK ====================
    CountryDigitalRights(
      country: 'Denmark',
      countryCode: 'DK',
      dpa: DataProtectionAuthority(
        country: 'Denmark',
        countryCode: 'DK',
        authorityName: 'Danish Data Protection Agency',
        authorityNameLocal: 'Datatilsynet',
        website: 'https://www.datatilsynet.dk',
        email: 'dt@datatilsynet.dk',
        phone: '+45 33 19 32 00',
        address: 'Carl Jacobsens Vej 35, 2500 Valby',
        complaintUrl: 'https://www.datatilsynet.dk/english/citizens-rights/lodge-a-complaint',
        languagesSupported: ['Danish', 'English'],
      ),
      digitalIdSystems: [
        DigitalIdSystem(
          systemName: 'MitID',
          description: 'Denmark\'s national digital identity solution (replaced NemID in 2023). '
              'Essential for banking, government services, tax, healthcare, and digital signing.',
          availableToNonCitizens: true,
          availableToResidents: true,
          howToObtain: 'Apply at any MitID registration point (citizen service center, library, bank). '
              'Requires CPR number (civil registration number) and valid ID.',
          requiredDocuments: ['CPR number', 'Valid passport or residence card', 'Danish address registration'],
          website: 'https://www.mitid.dk',
        ),
      ],
      simCardRegistrationRequired: true,
      simCardRequirements: 'Prepaid SIM cards require registration since 2007. Must provide '
          'valid ID and CPR number. Operators verify identity before activation.',
      internetAccessRights: 'Universal service includes broadband. Denmark has among the highest '
          'internet penetration rates globally. Net neutrality strictly enforced. '
          'Danish Energy Agency oversees telecom.',
      governmentDigitalServices: [
        'borger.dk - Central citizen portal (mandatory digital post)',
        'SKAT (skat.dk) - Tax administration',
        'sundhed.dk - Health portal with medical records',
        'Min Sundhed (MinSundhed app) - Personal health app',
        'Digital Post (e-Boks / Mit.dk) - Mandatory digital mailbox',
      ],
      govServicesAccessUrl: 'https://www.borger.dk',
      socialMediaRights: 'Strong freedom of expression tradition. Protected by Constitution §77. '
          'Denmark has no specific social media regulation beyond general law.',
      freedomOfExpressionLimits: 'Prohibited: hate speech (§266b Penal Code), blasphemy law repealed 2017, '
          'defamation, threats, sharing intimate images without consent.',
      surveillance: SurveillanceInfo(
        publicCameraSurveillanceRegulated: true,
        publicCameraRules: 'TV Surveillance Act (TV-overvågningsloven) regulates. Private entities '
            'can only surveil their own property. Signs required. Police cameras in public '
            'spaces under separate authorization.',
        workplaceSurveillanceRegulated: true,
        workplaceCameraRules: 'Employers must inform employees in advance. Cannot monitor '
            'private areas. Datatilsynet provides detailed guidelines.',
        wiretappingRules: 'Court order required. Only for offenses with 6+ years sentence. '
            'PET (security intelligence) has broader powers under special oversight. '
            'Tilsynet med Efterretningstjenesterne (intelligence oversight) reviews.',
        biometricDataRules: 'Danish Data Protection Act supplements GDPR on biometric data. '
            'Strict rules on biometric employee access systems.',
        facialRecognitionStatus: 'Police tested facial recognition but Datatilsynet raised concerns. '
            'No widespread deployment. Active public debate on limits.',
        oversightBody: 'Tilsynet med Efterretningstjenesterne (Intelligence Oversight Board)',
        legalBasis: 'Danish Data Protection Act 2018, TV Surveillance Act, '
            'Administration of Justice Act',
      ),
      cookieConsentRules: 'Cookie Order (Cookiebekendtgørelsen) requires explicit consent. '
          'Datatilsynet actively enforces. Denmark has strict interpretation.',
      immigrantSpecificDigitalRights: 'All residents with CPR number can get MitID. Digital Post is '
          'MANDATORY - government sends all official letters digitally. Immigrants must '
          'set up digital post or apply for exemption. Failure to read Digital Post can '
          'result in missed legal deadlines. This is critically important for immigrants.',
      dataPortabilityNotes: 'Number portability within 1 business day. Strong telecom competition.',
      rightToBeForgottenNotes: 'Datatilsynet actively handles erasure cases. Danish courts '
          'follow CJEU jurisprudence. Efficient complaint handling.',
    ),

    // ==================== ESTONIA ====================
    CountryDigitalRights(
      country: 'Estonia',
      countryCode: 'EE',
      dpa: DataProtectionAuthority(
        country: 'Estonia',
        countryCode: 'EE',
        authorityName: 'Estonian Data Protection Inspectorate',
        authorityNameLocal: 'Andmekaitse Inspektsioon (AKI)',
        website: 'https://www.aki.ee',
        email: 'info@aki.ee',
        phone: '+372 627 4135',
        address: 'Tatari 39, 10134 Tallinn',
        complaintUrl: 'https://www.aki.ee/en/data-protection-reform/how-submit-complaint',
        languagesSupported: ['Estonian', 'English', 'Russian'],
      ),
      digitalIdSystems: [
        DigitalIdSystem(
          systemName: 'Estonian ID-kaart (eID)',
          description: 'World-leading digital identity card. Used for authentication, '
              'digital signatures, voting, healthcare, banking, and all government services. '
              'Estonia is the most digitally advanced government in the EU.',
          availableToNonCitizens: true,
          availableToResidents: true,
          howToObtain: 'All residents automatically receive an ID card with digital functionality '
              'from PPA (Police and Border Guard Board). Card reader or Smart-ID app needed.',
          requiredDocuments: ['Valid passport', 'Residence permit', 'Estonian personal code (isikukood)'],
          website: 'https://www.id.ee',
        ),
        DigitalIdSystem(
          systemName: 'e-Residency',
          description: 'Unique digital identity for non-residents enabling access to Estonian '
              'digital services, company registration, banking, and digital signatures '
              'from anywhere in the world. Does NOT grant physical residency.',
          availableToNonCitizens: true,
          availableToResidents: false,
          howToObtain: 'Apply online at e-resident.gov.ee. Background check takes 3-8 weeks. '
              'Pick up card at Estonian embassy or PPA service point.',
          requiredDocuments: ['Valid passport', 'Digital photo', 'Motivation statement', 'EUR 100-120 fee'],
          website: 'https://www.e-resident.gov.ee',
        ),
        DigitalIdSystem(
          systemName: 'Smart-ID',
          description: 'Mobile app for digital authentication and signing. Equivalent to '
              'physical ID card. Very widely used in Estonia and Baltics.',
          availableToNonCitizens: true,
          availableToResidents: true,
          howToObtain: 'Download Smart-ID app and register using Estonian ID card or '
              'Mobile-ID. Verification through bank also possible.',
          requiredDocuments: ['Estonian ID card or Mobile-ID', 'Smartphone'],
          website: 'https://www.smart-id.com',
        ),
      ],
      simCardRegistrationRequired: true,
      simCardRequirements: 'Prepaid SIM cards require identification. Must provide valid ID '
          '(passport, residence card). Estonian personal code needed for full services. '
          'Online registration available for some operators.',
      internetAccessRights: 'Estonia declared internet access a social right in 2000. '
          'Free public WiFi widely available (including forests!). '
          'Net neutrality enforced. Among the fastest broadband in EU.',
      governmentDigitalServices: [
        'eesti.ee - Central state portal (99% of services online)',
        'e-Tax (emta.ee) - Tax and customs board',
        'Digilugu - Digital health records (patient portal)',
        'eKool - Digital school system',
        'e-Business Register - Company registration and management',
        'i-Voting - Internet voting in elections (for citizens)',
        'e-Prescription - Digital prescriptions',
        'e-Police - Online police services',
      ],
      govServicesAccessUrl: 'https://www.eesti.ee',
      socialMediaRights: 'Freedom of expression protected by Constitution §45. '
          'Very liberal free speech tradition. Estonia ranks high on press freedom indices.',
      freedomOfExpressionLimits: 'Prohibited: incitement to hatred (Penal Code §151), '
          'defamation (civil liability), glorification of communist/Nazi regimes in certain contexts.',
      surveillance: SurveillanceInfo(
        publicCameraSurveillanceRegulated: true,
        publicCameraRules: 'Regulated by Personal Data Protection Act and AKI guidelines. '
            'Notification required. X-Road system logs all government data access '
            'transparently - citizens can see who accessed their data.',
        workplaceSurveillanceRegulated: true,
        workplaceCameraRules: 'Employment Contracts Act requires employee notification. '
            'Proportionality required. AKI has issued detailed workplace monitoring guidelines.',
        wiretappingRules: 'Court authorization required. Surveillance Activities Act regulates. '
            'Only for serious crimes. Parliamentary oversight through '
            'Security Authorities Surveillance Select Committee.',
        biometricDataRules: 'Biometric data in ID cards (fingerprints since 2021). '
            'X-Road ensures transparent data access logging. '
            'Citizens can verify who accessed their biometric data.',
        facialRecognitionStatus: 'No widespread public facial recognition. Estonia focuses more on '
            'digital identity rather than surveillance. Government approach is privacy-friendly.',
        oversightBody: 'Riigikogu Security Authorities Surveillance Select Committee',
        legalBasis: 'Personal Data Protection Act 2018, Surveillance Activities Act, '
            'Electronic Communications Act',
      ),
      cookieConsentRules: 'Electronic Communications Act requires consent for non-essential cookies. '
          'AKI enforces compliance. Estonia generally follows EU standard approach.',
      immigrantSpecificDigitalRights: 'Estonia is exceptionally immigrant-friendly digitally. '
          'All residents get digital ID. e-Residency available to anyone worldwide. '
          'X-Road transparency means you can see every government access to your data. '
          'AKI provides service in Estonian, English, and Russian. '
          'Asylum seekers receive basic digital access through reception centers.',
      dataPortabilityNotes: 'Seamless data portability through X-Road infrastructure. '
          'Number portability within 5 working days. Government data interoperability is exemplary.',
      rightToBeForgottenNotes: 'AKI handles erasure requests. Estonian approach balances '
          'transparency (X-Road) with privacy rights effectively.',
    ),

    // ==================== FINLAND ====================
    CountryDigitalRights(
      country: 'Finland',
      countryCode: 'FI',
      dpa: DataProtectionAuthority(
        country: 'Finland',
        countryCode: 'FI',
        authorityName: 'Office of the Data Protection Ombudsman',
        authorityNameLocal: 'Tietosuojavaltuutetun toimisto',
        website: 'https://tietosuoja.fi/en/home',
        email: 'tietosuoja@om.fi',
        phone: '+358 29 566 6700',
        address: 'Lintulahdenkuja 4, 00530 Helsinki',
        complaintUrl: 'https://tietosuoja.fi/en/notification-to-the-data-protection-ombudsman',
        languagesSupported: ['Finnish', 'Swedish', 'English'],
      ),
      digitalIdSystems: [
        DigitalIdSystem(
          systemName: 'Finnish Trust Network (Suomi.fi)',
          description: 'Strong electronic identification through banks, mobile certificates, '
              'or Finnish ID card. Gateway to all government e-services.',
          availableToNonCitizens: true,
          availableToResidents: true,
          howToObtain: 'Obtain through Finnish bank (bank credentials), mobile operator '
              '(mobile certificate), or DVV (Digital and Population Data Services Agency) '
              'for Finnish ID card.',
          requiredDocuments: ['Finnish personal identity code (henkilötunnus)', 'Valid ID document', 'Finnish bank account or mobile subscription'],
          website: 'https://www.suomi.fi/e-authorizations',
        ),
      ],
      simCardRegistrationRequired: true,
      simCardRequirements: 'Prepaid SIM cards require identification since 2009. '
          'Must provide valid ID (passport, residence permit) and Finnish personal '
          'identity code. Tourist SIMs may have simplified requirements.',
      internetAccessRights: 'Finland was first country to make broadband a legal right (2010). '
          'Minimum 2 Mbps guaranteed as universal service (being upgraded). '
          'Net neutrality strictly enforced by Traficom. Excellent mobile coverage.',
      governmentDigitalServices: [
        'Suomi.fi - Central government services portal',
        'OmaVero (vero.fi) - Tax administration',
        'Kanta (kanta.fi) - Health records and prescriptions',
        'OmaKela (kela.fi) - Social benefits (Kela)',
        'TE-palvelut - Employment services',
        'Enterfinland.fi - Immigration services (residence permits)',
        'DVV - Population register services',
      ],
      govServicesAccessUrl: 'https://www.suomi.fi',
      socialMediaRights: 'Strong freedom of expression tradition. Protected by Constitution §12. '
          'Finland consistently ranks among top countries for press freedom.',
      freedomOfExpressionLimits: 'Prohibited: ethnic agitation (Penal Code Ch. 11 §10), '
          'defamation, invasion of privacy, distribution of intimate images without consent, '
          'threats. Blasphemy law still exists but rarely enforced.',
      surveillance: SurveillanceInfo(
        publicCameraSurveillanceRegulated: true,
        publicCameraRules: 'Regulated by Personal Data Act and Data Protection Ombudsman guidance. '
            'Public authorities must notify about CCTV. Private cameras must not cover '
            'public spaces unnecessarily.',
        workplaceSurveillanceRegulated: true,
        workplaceCameraRules: 'Act on the Protection of Privacy in Working Life (759/2004) '
            'strictly regulates. Employer must negotiate with employees. Email monitoring '
            'heavily restricted. Camera placement rules detailed.',
        wiretappingRules: 'Court order required. Coercive Measures Act regulates. '
            'Intelligence legislation passed 2019 allowing foreign intelligence surveillance '
            'with court authorization. Parliamentary Intelligence Oversight Committee.',
        biometricDataRules: 'Strict regulation. Fingerprints in passports and residence permits. '
            'Workplace biometrics require strong justification. '
            'Data Protection Ombudsman actively oversees.',
        facialRecognitionStatus: 'Police use Clearview AI was found illegal by Data Protection Ombudsman '
            'in 2021. No authorized mass facial recognition. Very privacy-protective approach.',
        oversightBody: 'Intelligence Ombudsman + Parliamentary Intelligence Oversight Committee',
        legalBasis: 'Data Protection Act 2018, Act on Protection of Privacy in Working Life, '
            'Information Society Code, Intelligence Surveillance Act 2019',
      ),
      cookieConsentRules: 'Information Society Code §205 requires cookie consent. '
          'Data Protection Ombudsman has issued guidance. Finland follows strict EU approach.',
      immigrantSpecificDigitalRights: 'Immigrants with Finnish personal identity code (henkilötunnus) '
          'can access all digital services. EnterFinland.fi is the dedicated immigration portal. '
          'Kela digital services available in Finnish, Swedish, and English. '
          'Data Protection Ombudsman provides service in Finnish, Swedish, and English. '
          'IMPORTANT: Many services require Finnish bank credentials for strong authentication - '
          'getting a bank account is a critical first step for digital access.',
      dataPortabilityNotes: 'Number portability within 5 working days. Traficom enforces. '
          'Kanta health records portable across healthcare providers.',
      rightToBeForgottenNotes: 'Data Protection Ombudsman actively enforces. Finnish courts '
          'have applied CJEU case law. Search engine delisting orders have been issued.',
    ),

    // ==================== FRANCE ====================
    CountryDigitalRights(
      country: 'France',
      countryCode: 'FR',
      dpa: DataProtectionAuthority(
        country: 'France',
        countryCode: 'FR',
        authorityName: 'French Data Protection Authority',
        authorityNameLocal: 'Commission nationale de l\'informatique et des libertés (CNIL)',
        website: 'https://www.cnil.fr',
        email: 'via online form',
        phone: '+33 1 53 73 22 22',
        address: '3 place de Fontenoy, TSA 80715, 75334 Paris Cedex 07',
        complaintUrl: 'https://www.cnil.fr/en/complaints',
        languagesSupported: ['French', 'English'],
      ),
      digitalIdSystems: [
        DigitalIdSystem(
          systemName: 'FranceConnect',
          description: 'Federated identity system connecting to 1400+ government services. '
              'Uses existing credentials (tax portal, health insurance, La Poste, etc.).',
          availableToNonCitizens: true,
          availableToResidents: true,
          howToObtain: 'Create an account on impots.gouv.fr (tax) or ameli.fr (health insurance) '
              'or La Poste digital identity, then use FranceConnect to access other services.',
          requiredDocuments: ['French tax number or social security number', 'Valid ID', 'French address'],
          website: 'https://franceconnect.gouv.fr',
        ),
        DigitalIdSystem(
          systemName: 'France Identité (CNIe)',
          description: 'New electronic national ID card with digital identity features. '
              'Being rolled out with smartphone app for identity verification.',
          availableToNonCitizens: false,
          availableToResidents: false,
          howToObtain: 'French citizens only. Issued at mairie (town hall) with biometric data.',
          requiredDocuments: ['French citizenship', 'Birth certificate', 'Proof of address'],
          website: 'https://france-identite.gouv.fr',
        ),
      ],
      simCardRegistrationRequired: true,
      simCardRequirements: 'Prepaid SIM cards require identity verification since 2016 (anti-terrorism law). '
          'Must provide valid ID (passport, titre de séjour). Operators must verify before activation.',
      internetAccessRights: 'Universal service includes internet access. ARCEP regulates telecoms. '
          'Net neutrality enforced. Very competitive mobile market (Free Mobile revolution). '
          'France has a "right to connectivity" initiative for rural areas.',
      governmentDigitalServices: [
        'service-public.fr - Central government information portal',
        'impots.gouv.fr - Tax services',
        'ameli.fr - Health insurance (Assurance Maladie)',
        'caf.fr - Family allowances (CAF)',
        'pole-emploi.fr (France Travail) - Employment services',
        'ANEF - Online foreign nationals administration (residence permits)',
        'Démarches simplifiées - Government procedures platform',
      ],
      govServicesAccessUrl: 'https://www.service-public.fr',
      socialMediaRights: 'Freedom of expression protected by 1789 Declaration of Rights of Man. '
          'France has comprehensive hate speech laws (loi Pleven 1972, loi Gayssot 1990).',
      freedomOfExpressionLimits: 'Prohibited: hate speech, Holocaust denial (loi Gayssot), '
          'incitement to discrimination/violence, defamation, apology of terrorism, '
          'contestation of crimes against humanity. France has one of the strictest '
          'content regulation frameworks in the EU.',
      surveillance: SurveillanceInfo(
        publicCameraSurveillanceRegulated: true,
        publicCameraRules: 'Loi d\'orientation et de programmation de sécurité intérieure regulates. '
            'Préfecture authorization required. CNIL oversees compliance. '
            'Over 1 million cameras nationwide. Signs required.',
        workplaceSurveillanceRegulated: true,
        workplaceCameraRules: 'Labour Code and CNIL guidelines regulate. Employee notification '
            'required (works council + individual). DPIA often required. '
            'CNIL actively audits and fines non-compliant employers.',
        wiretappingRules: 'Judicial interceptions require judge authorization. '
            'Administrative interceptions (intelligence) authorized by Prime Minister '
            'with CNCTR (Commission nationale de contrôle des techniques de renseignement) '
            'oversight. Post-2015 terrorism laws expanded surveillance powers.',
        biometricDataRules: 'CNIL strictly regulates biometric data. Major decisions on '
            'school cafeteria fingerprint scanning (banned). Workplace biometrics require '
            'CNIL authorization and DPIA. Biometric time clocks common but regulated.',
        facialRecognitionStatus: 'AI Act for 2024 Olympics temporarily allowed experimental '
            'algorithmic video surveillance. CNIL has strict position against mass '
            'facial recognition. Ongoing national debate.',
        oversightBody: 'CNCTR (intelligence), CNIL (data protection)',
        legalBasis: 'Loi Informatique et Libertés 1978 (amended), Intelligence Act 2015, '
            'Internal Security Code, Labour Code',
      ),
      cookieConsentRules: 'CNIL has been the most active DPA on cookie enforcement in Europe. '
          'Issued landmark fines to Google (EUR 150M) and Facebook (EUR 60M) in 2022 for '
          'cookie consent violations. Strict opt-in required. Cookie walls generally prohibited.',
      immigrantSpecificDigitalRights: 'ANEF platform for residence permits (mandatory online applications). '
          'FranceConnect accessible with tax number or social security number. '
          'CNIL provides guidance in French and English. Asylum seekers can access '
          'digital services through OFII (immigration office). '
          'IMPORTANT: Many administrative procedures are now digital-only - '
          'préfecture appointments often only available online.',
      dataPortabilityNotes: 'Number portability via RIO code system (quick and free). '
          'Banque de France facilitates account portability. Digital Republic Law (2016) '
          'enhanced data portability rights beyond GDPR.',
      rightToBeForgottenNotes: 'CNIL has been a pioneer in right to be forgotten enforcement. '
          'France first referred Google Spain case to CJEU. Strong tradition of '
          'privacy protection. CNIL handles high volume of erasure complaints.',
    ),

    // ==================== GERMANY ====================
    CountryDigitalRights(
      country: 'Germany',
      countryCode: 'DE',
      dpa: DataProtectionAuthority(
        country: 'Germany',
        countryCode: 'DE',
        authorityName: 'Federal Commissioner for Data Protection and Freedom of Information',
        authorityNameLocal: 'Der Bundesbeauftragte für den Datenschutz und die Informationsfreiheit (BfDI)',
        website: 'https://www.bfdi.bund.de',
        email: 'poststelle@bfdi.bund.de',
        phone: '+49 228 997799-0',
        address: 'Graurheindorfer Str. 153, 53117 Bonn',
        complaintUrl: 'https://www.bfdi.bund.de/EN/Service/Complaint/complaint_node.html',
        languagesSupported: ['German', 'English'],
      ),
      digitalIdSystems: [
        DigitalIdSystem(
          systemName: 'eID (Online-Ausweis / nPA)',
          description: 'Electronic identity function on German ID card (Personalausweis) and '
              'electronic residence permit. Used for online government services and age verification.',
          availableToNonCitizens: true,
          availableToResidents: true,
          howToObtain: 'Electronic residence permit (eAT) has built-in eID function. '
              'Activate the online function at the local foreigners office (Ausländerbehörde). '
              'Need NFC-capable smartphone or card reader.',
          requiredDocuments: ['Electronic residence permit (eAT)', 'PIN (set at issuance)', 'NFC-capable smartphone or card reader'],
          website: 'https://www.personalausweisportal.de',
        ),
        DigitalIdSystem(
          systemName: 'BundID',
          description: 'Federal user account for accessing German government digital services. '
              'Linked to eID or ELSTER certificate.',
          availableToNonCitizens: true,
          availableToResidents: true,
          howToObtain: 'Register online using eID card/electronic residence permit or '
              'ELSTER certificate (tax). Username/password also possible for basic access.',
          requiredDocuments: ['eID or eAT', 'German address registration (Anmeldung)'],
          website: 'https://id.bund.de',
        ),
      ],
      simCardRegistrationRequired: true,
      simCardRequirements: 'Strict registration since 2017 (Telekommunikationsgesetz). '
          'Must show valid ID (passport, residence permit) in person or via video identification. '
          'Identity must be verified before SIM activation. Very strictly enforced.',
      internetAccessRights: 'Telecommunications Act ensures universal service including internet. '
          'BNetzA (Federal Network Agency) regulates. Net neutrality enforced. '
          'Germany has had challenges with rural broadband but major investment underway.',
      governmentDigitalServices: [
        'verwaltung.bund.de - Federal administration portal',
        'ELSTER (elster.de) - Tax filing',
        'eAU - Electronic sick leave certificates',
        'Gesundheitsakte - Electronic health records (ePA)',
        'Ausländerbehörde online portals - Immigration services (varies by city)',
        'Jobcenter/Arbeitsagentur - Employment services online',
      ],
      govServicesAccessUrl: 'https://verwaltung.bund.de',
      socialMediaRights: 'Freedom of expression protected by Grundgesetz Article 5. '
          'NetzDG (Network Enforcement Act 2017) requires social media platforms to '
          'remove illegal content within 24 hours. Germany has strict hate speech laws.',
      freedomOfExpressionLimits: 'Prohibited: Nazi symbols/propaganda (§86a StGB), Holocaust denial '
          '(§130 StGB), hate speech (Volksverhetzung), defamation (§185-187 StGB), '
          'insult (Beleidigung is criminal in Germany), sedition.',
      surveillance: SurveillanceInfo(
        publicCameraSurveillanceRegulated: true,
        publicCameraRules: 'BDSG §4 strictly regulates. Each German state (Land) has additional rules. '
            'Data protection authorities actively audit. Germany is generally restrictive '
            'on public surveillance compared to other EU countries.',
        workplaceSurveillanceRegulated: true,
        workplaceCameraRules: 'BDSG §26 regulates employee data processing. Works council (Betriebsrat) '
            'has strong co-determination rights. Hidden surveillance only in exceptional cases '
            'with documented suspicion of crime. BAG (Federal Labour Court) case law is strict.',
        wiretappingRules: 'Court order required (§100a StPO). Only for serious catalog crimes. '
            'BND (foreign intelligence) oversight by G10 Commission and Parliamentary Control Panel. '
            'Constitutional Court has issued landmark decisions limiting surveillance.',
        biometricDataRules: 'Extremely strict. Federal Constitutional Court has ruled biometric databases '
            'require strong justification. Fingerprints on ID cards upheld by CJEU but '
            'German implementation has additional safeguards.',
        facialRecognitionStatus: 'Very restrictive. Pilot at Berlin Südkreuz station was controversial. '
            'No mass public facial recognition. BfDI and state authorities critical of expansion. '
            'Strong civil society opposition.',
        oversightBody: 'G10 Commission, Parliamentary Control Panel (PKGr), BfDI, 16 state DPAs',
        legalBasis: 'BDSG (Federal Data Protection Act), Telecommunications-Telemedia Data '
            'Protection Act (TTDSG), G10 Act, BKA Act, BND Act',
      ),
      cookieConsentRules: 'TTDSG §25 requires consent for non-essential cookies (since Dec 2021). '
          'German courts and DPAs strictly enforce. Planet49 CJEU case originated from German referral.',
      immigrantSpecificDigitalRights: 'Electronic residence permit (eAT) provides digital identity. '
          'GDPR applies equally. Germany has 17 DPAs (1 federal + 16 states) - '
          'file complaints with the relevant state authority. Strong privacy culture. '
          'IMPORTANT: Each state has different digital government systems. '
          'Berlin, Munich, Hamburg have advanced online foreigner office portals.',
      dataPortabilityNotes: 'Number portability regulated by BNetzA. Must be completed within 1 day. '
          'Bank account switching service (Kontowechselservice) legally mandated.',
      rightToBeForgottenNotes: 'German courts have been very active on right to be forgotten. '
          'BGH (Federal Court of Justice) has multiple landmark decisions. '
          'German DPAs handle high volume of erasure requests.',
    ),

    // ==================== GREECE ====================
    CountryDigitalRights(
      country: 'Greece',
      countryCode: 'GR',
      dpa: DataProtectionAuthority(
        country: 'Greece',
        countryCode: 'GR',
        authorityName: 'Hellenic Data Protection Authority',
        authorityNameLocal: 'Αρχή Προστασίας Δεδομένων Προσωπικού Χαρακτήρα (ΑΠΔΠΧ)',
        website: 'https://www.dpa.gr',
        email: 'contact@dpa.gr',
        phone: '+30 210 647 5600',
        address: 'Kifissias 1-3, 115 23 Athens',
        complaintUrl: 'https://www.dpa.gr/en/individuals/complaint-hdpa',
        languagesSupported: ['Greek', 'English'],
      ),
      digitalIdSystems: [
        DigitalIdSystem(
          systemName: 'gov.gr wallet / myAADE',
          description: 'Digital government portal providing access to public services. '
              'Gov.gr wallet stores digital copies of official documents on smartphone.',
          availableToNonCitizens: true,
          availableToResidents: true,
          howToObtain: 'Register on gov.gr using TaxisNet credentials (tax office account) '
              'or bank credentials through the Greek Trust Network.',
          requiredDocuments: ['AFM (Greek tax number)', 'Valid ID or residence permit', 'Greek phone number'],
          website: 'https://www.gov.gr',
        ),
      ],
      simCardRegistrationRequired: true,
      simCardRequirements: 'Prepaid SIM registration required. Must provide valid ID '
          '(passport, residence permit) and tax number (AFM). Operators verify identity.',
      internetAccessRights: 'Universal service includes internet access. EETT (telecoms regulator) '
          'enforces. Net neutrality under EU framework. Rural connectivity improving '
          'through EU-funded projects.',
      governmentDigitalServices: [
        'gov.gr - Unified digital government portal',
        'TaxisNet (myAADE) - Tax services',
        'EFKA - Social security digital services',
        'e-DAPY - Digital health services',
        'ERGANI - Employment registration system',
        'myKEPlive - Remote access to citizen service centers',
      ],
      govServicesAccessUrl: 'https://www.gov.gr',
      socialMediaRights: 'Freedom of expression protected by Constitution Article 14. '
          'Greece has decriminalized defamation for media but retains criminal defamation for individuals.',
      freedomOfExpressionLimits: 'Prohibited: hate speech (Anti-Racism Law 4285/2014), defamation, '
          'blasphemy (rarely enforced), spreading false news in some contexts.',
      surveillance: SurveillanceInfo(
        publicCameraSurveillanceRegulated: true,
        publicCameraRules: 'HDPA Directive 1/2011 regulates CCTV. Authorization required for '
            'surveillance in public spaces. Notification mandatory.',
        workplaceSurveillanceRegulated: true,
        workplaceCameraRules: 'HDPA guidelines require employer notification to employees and DPA. '
            'Proportionality required. Private spaces (restrooms) absolutely prohibited.',
        wiretappingRules: 'Court order required. Greek wiretapping scandal (2022 Predator spyware) '
            'led to major political crisis and reform demands. ADAE (Authority for Communication '
            'Security and Privacy) provides oversight. Significant concerns remain.',
        biometricDataRules: 'HDPA strictly oversees biometric data. Fingerprints in travel documents '
            'per EU regulation. Workplace biometrics require strong justification.',
        facialRecognitionStatus: 'Limited deployment. HDPA has raised concerns about proportionality. '
            'No mass public facial recognition system.',
        oversightBody: 'ADAE (Authority for Communication Security and Privacy)',
        legalBasis: 'Law 4624/2019 (GDPR implementation), Law 3471/2006 (e-privacy), '
            'Constitution Articles 9 and 19',
      ),
      cookieConsentRules: 'Law 3471/2006 requires consent for cookies. HDPA provides guidance. '
          'Enforcement has been moderate.',
      immigrantSpecificDigitalRights: 'Immigrants with AFM (tax number) can access gov.gr services. '
          'GDPR applies to all. Major issue: asylum seekers on islands have had limited '
          'internet access. HDPA accepts complaints in Greek and English. '
          'Wiretapping scandal affected journalists and politicians including those '
          'covering immigration issues.',
      dataPortabilityNotes: 'Number portability available through EETT regulation. '
          'Banking portability developing.',
      rightToBeForgottenNotes: 'HDPA handles erasure requests. Greek courts follow CJEU precedent. '
          'Processing times can be longer than Western EU average.',
    ),

    // ==================== HUNGARY ====================
    CountryDigitalRights(
      country: 'Hungary',
      countryCode: 'HU',
      dpa: DataProtectionAuthority(
        country: 'Hungary',
        countryCode: 'HU',
        authorityName: 'Hungarian National Authority for Data Protection and Freedom of Information',
        authorityNameLocal: 'Nemzeti Adatvédelmi és Információszabadság Hatóság (NAIH)',
        website: 'https://www.naih.hu',
        email: 'ugyfelszolgalat@naih.hu',
        phone: '+36 1 391 1400',
        address: 'Falk Miksa utca 9-11, 1055 Budapest',
        complaintUrl: 'https://www.naih.hu/investigation-request',
        languagesSupported: ['Hungarian', 'English'],
      ),
      digitalIdSystems: [
        DigitalIdSystem(
          systemName: 'Ügyfélkapu / DÁP (Digital Citizen Program)',
          description: 'Government gateway for electronic administration. Being replaced by '
              'DÁP (Digitális Állampolgárság Program) with mobile app.',
          availableToNonCitizens: true,
          availableToResidents: true,
          howToObtain: 'Register at Government Windows (Kormányablak) with valid ID and '
              'residence permit. Online registration also possible with specific credentials.',
          requiredDocuments: ['Valid passport or ID', 'Residence permit', 'Hungarian address card (lakcímkártya)'],
          website: 'https://ugyfelkapu.gov.hu',
        ),
      ],
      simCardRegistrationRequired: true,
      simCardRequirements: 'Prepaid SIM registration required since 2016. Must provide valid ID '
          'and Hungarian tax number (adóazonosító jel). Operators verify identity at purchase.',
      internetAccessRights: 'Universal service includes internet. NMHH (media/telecom authority) regulates. '
          'Net neutrality under EU framework. Affordable mobile data.',
      governmentDigitalServices: [
        'magyarorszag.hu - Central government portal',
        'NAV Online - Tax administration',
        'eSZTÁR - Social services portal',
        'EESZT - Electronic health service space',
        'Ügyfélkapu - Government gateway services',
      ],
      govServicesAccessUrl: 'https://magyarorszag.hu',
      socialMediaRights: 'Freedom of expression in Constitution (Fundamental Law Article IX). '
          'However, concerns raised by EU about media freedom and government influence. '
          'Defamation is criminal.',
      freedomOfExpressionLimits: 'Prohibited: hate speech (Penal Code), defamation (criminal), '
          'incitement against groups, Holocaust denial. EU has expressed concerns about '
          'media concentration and government pressure on independent media.',
      surveillance: SurveillanceInfo(
        publicCameraSurveillanceRegulated: true,
        publicCameraRules: 'Regulated by data protection law and police act. Growing CCTV network '
            'in Budapest and major cities. Notification required.',
        workplaceSurveillanceRegulated: true,
        workplaceCameraRules: 'Labour Code regulates. Employee notification required. '
            'Proportionality principle applies. NAIH has issued guidelines.',
        wiretappingRules: 'Court or justice minister authorization. Concerns about lack of '
            'independent oversight. EU rule of law reports have flagged surveillance oversight issues. '
            'Pegasus spyware scandal (2021) revealed surveillance of journalists and opponents.',
        biometricDataRules: 'Biometric data in travel documents per EU regulation. '
            'NAIH oversees biometric data processing.',
        facialRecognitionStatus: 'Budapest police have facial recognition capabilities. '
            'Limited public information about scope and safeguards.',
        oversightBody: 'Parliamentary Committee on National Security (limited oversight effectiveness noted by EU)',
        legalBasis: 'Act CXII of 2011 on Informational Self-determination, '
            'Act C of 2003 on Electronic Communications, Police Act',
      ),
      cookieConsentRules: 'Electronic Communications Act requires consent. NAIH provides guidance. '
          'Enforcement has been relatively moderate.',
      immigrantSpecificDigitalRights: 'Residents with address card can access digital government services. '
          'GDPR applies equally. NAIH handles complaints in Hungarian and English. '
          'Concerns about surveillance of civil society organizations working with immigrants.',
      dataPortabilityNotes: 'Number portability available. NMHH oversees process.',
      rightToBeForgottenNotes: 'NAIH processes erasure requests under GDPR. '
          'Hungarian courts follow EU law. Processing times can vary.',
    ),

    // ==================== IRELAND ====================
    CountryDigitalRights(
      country: 'Ireland',
      countryCode: 'IE',
      dpa: DataProtectionAuthority(
        country: 'Ireland',
        countryCode: 'IE',
        authorityName: 'Data Protection Commission',
        authorityNameLocal: 'An Coimisiún um Chosaint Sonraí (DPC)',
        website: 'https://www.dataprotection.ie',
        email: 'info@dataprotection.ie',
        phone: '+353 57 868 4800',
        address: '21 Fitzwilliam Square South, Dublin 2, D02 RD28',
        complaintUrl: 'https://forms.dataprotection.ie/contact',
        languagesSupported: ['English', 'Irish'],
      ),
      digitalIdSystems: [
        DigitalIdSystem(
          systemName: 'MyGovID',
          description: 'Ireland\'s digital identity for government services. Uses verified identity '
              'linked to PPSN (Personal Public Service Number). Access to welfare, tax, '
              'health services, and driving licence services.',
          availableToNonCitizens: true,
          availableToResidents: true,
          howToObtain: 'Register at mygovid.ie with PPSN. Verify identity online with '
              'Irish passport or via SAFE registration at a government office.',
          requiredDocuments: ['PPSN (Personal Public Service Number)', 'Valid photo ID', 'Proof of address'],
          website: 'https://www.mygovid.ie',
        ),
      ],
      simCardRegistrationRequired: false,
      simCardRequirements: 'Ireland does not currently mandate prepaid SIM registration. '
          'Prepaid SIM cards can be purchased without identification. '
          'Postpaid contracts require standard credit/identity checks.',
      internetAccessRights: 'Universal service obligation includes broadband. ComReg regulates. '
          'National Broadband Plan investing EUR 5B in rural connectivity. Net neutrality enforced.',
      governmentDigitalServices: [
        'gov.ie - Central government portal',
        'Revenue Online Service (ROS) - Tax filing',
        'MyWelfare.ie - Social welfare services',
        'HSE online services - Health services',
        'INIS online - Immigration services',
        'MyGovID services - Integrated government services',
      ],
      govServicesAccessUrl: 'https://www.gov.ie',
      socialMediaRights: 'Freedom of expression protected by Constitution Article 40.6.1. '
          'Ireland hosts European HQs of major tech companies (Meta, Google, Apple, etc.) '
          'making DPC the lead GDPR authority for Big Tech.',
      freedomOfExpressionLimits: 'Prohibited: incitement to hatred (Criminal Justice Act 2024 updated), '
          'defamation (Defamation Act 2009), blasphemy removed from constitution 2018.',
      surveillance: SurveillanceInfo(
        publicCameraSurveillanceRegulated: true,
        publicCameraRules: 'Garda CCTV schemes require authorization. DPC guidelines on CCTV. '
            'Community CCTV schemes with Garda oversight.',
        workplaceSurveillanceRegulated: true,
        workplaceCameraRules: 'DPC guidance requires transparency and proportionality. '
            'Employee monitoring must comply with GDPR. WRC (Workplace Relations Commission) '
            'adjudicates disputes.',
        wiretappingRules: 'Interception of Postal Packets and Telecommunications Messages Act 1993. '
            'Ministerial warrant required. Designated Judge reviews compliance. '
            'Concerns raised about adequacy of oversight.',
        biometricDataRules: 'GDPR Article 9 protections apply. DPC guidelines on biometric data. '
            'Strict requirements for biometric processing in workplace.',
        facialRecognitionStatus: 'No mass facial recognition deployed. DPC has raised concerns. '
            'Garda use of certain technologies under scrutiny.',
        oversightBody: 'Designated Judge under Interception Act, DPC',
        legalBasis: 'Data Protection Act 2018, Communications (Retention of Data) Act 2011 '
            '(partly invalidated), ePrivacy Regulations 2011',
      ),
      cookieConsentRules: 'ePrivacy Regulations SI 336/2011 require cookie consent. '
          'DPC has issued detailed cookie guidance. Active enforcement against major companies.',
      immigrantSpecificDigitalRights: 'All residents with PPSN can access MyGovID and digital services. '
          'PPSN is essential - apply at DSP/Intreo office upon arrival. '
          'DPC is the lead authority for complaints against Big Tech companies '
          '(Facebook, Google, Apple, TikTok etc.) due to Irish HQs. '
          'Complaints can be filed from any EU country through DPC for these companies.',
      dataPortabilityNotes: 'Number portability within 2 working days. ComReg enforces. '
          'DPC has issued major data portability decisions against tech companies.',
      rightToBeForgottenNotes: 'DPC handles erasure requests including against major tech companies. '
          'As lead authority for Big Tech, DPC decisions on right to erasure have EU-wide impact.',
    ),

    // ==================== ITALY ====================
    CountryDigitalRights(
      country: 'Italy',
      countryCode: 'IT',
      dpa: DataProtectionAuthority(
        country: 'Italy',
        countryCode: 'IT',
        authorityName: 'Italian Data Protection Authority',
        authorityNameLocal: 'Garante per la protezione dei dati personali',
        website: 'https://www.garanteprivacy.it',
        email: 'garante@gpdp.it',
        phone: '+39 06 69677 1',
        address: 'Piazza Venezia 11, 00187 Roma',
        complaintUrl: 'https://www.garanteprivacy.it/home/diritti/come-agire-per-tutelare-i-propri-dati-personali',
        languagesSupported: ['Italian', 'English'],
      ),
      digitalIdSystems: [
        DigitalIdSystem(
          systemName: 'SPID (Sistema Pubblico di Identità Digitale)',
          description: 'Public digital identity system for accessing all government services. '
              'Multiple identity providers (Poste Italiane, Aruba, InfoCert, etc.). '
              'Used for tax, health, education, justice services.',
          availableToNonCitizens: true,
          availableToResidents: true,
          howToObtain: 'Register with any SPID identity provider. Need codice fiscale (tax code), '
              'valid ID, and permesso di soggiorno. Poste Italiane is most common provider.',
          requiredDocuments: ['Codice fiscale (tax code)', 'Valid passport or ID', 'Permesso di soggiorno (residence permit)', 'Italian phone number', 'Email address'],
          website: 'https://www.spid.gov.it',
        ),
        DigitalIdSystem(
          systemName: 'CIE (Carta d\'Identità Elettronica)',
          description: 'Electronic identity card with NFC chip. Being promoted as the primary '
              'digital identity alongside/replacing SPID. CIE ID app on smartphone.',
          availableToNonCitizens: false,
          availableToResidents: true,
          howToObtain: 'Issued at the commune (Anagrafe) upon registration. '
              'Foreign residents registered in Anagrafe can obtain CIE.',
          requiredDocuments: ['Residence registration at Anagrafe', 'Valid passport', 'Permesso di soggiorno'],
          website: 'https://www.cartaidentita.interno.gov.it',
        ),
      ],
      simCardRegistrationRequired: true,
      simCardRequirements: 'Strict SIM registration required. Must provide valid ID and '
          'codice fiscale (tax code). Both prepaid and postpaid require identity verification. '
          'Italy was one of the first EU countries to mandate SIM registration.',
      internetAccessRights: 'Universal service includes broadband. AGCOM regulates. '
          'Net neutrality enforced. Italy has invested heavily in fiber broadband rollout.',
      governmentDigitalServices: [
        'Portale della PA - Public administration portal',
        'Agenzia delle Entrate - Tax services (Fisconline/Entratel)',
        'INPS online - Social security and pensions',
        'Fascicolo Sanitario Elettronico - Electronic health records',
        'App IO - Government services mobile app',
        'PagoPA - Government payments platform',
        'ANPR - National population registry',
      ],
      govServicesAccessUrl: 'https://www.italia.it/en',
      socialMediaRights: 'Freedom of expression protected by Constitution Article 21. '
          'Italy has comprehensive defamation laws (including criminal defamation for press).',
      freedomOfExpressionLimits: 'Prohibited: defamation (civil + criminal), incitement to racial '
          'discrimination (Mancino Law 1993), apology of fascism (Scelba Law 1952), '
          'insult to state institutions, Holocaust denial (since 2016).',
      surveillance: SurveillanceInfo(
        publicCameraSurveillanceRegulated: true,
        publicCameraRules: 'Garante has issued detailed CCTV guidelines. Municipal cameras require '
            'assessment. Signs mandatory. Italian cities have extensive camera networks.',
        workplaceSurveillanceRegulated: true,
        workplaceCameraRules: 'Workers\' Statute (Statuto dei Lavoratori) Article 4 strictly regulates. '
            'Surveillance equipment requires union agreement or labour inspectorate authorization. '
            'Italy has among the strongest worker surveillance protections in EU.',
        wiretappingRules: 'Judge authorization required (GIP). Italian law allows extensive wiretapping '
            'for organized crime investigations. Trojan horse (captatore informatico) authorized '
            'for mafia and terrorism cases. Reform ongoing to limit scope.',
        biometricDataRules: 'Garante has strict position on biometric data. Banned Clearview AI '
            'and fined EUR 20M (2022). Workplace biometrics require strong justification.',
        facialRecognitionStatus: 'Garante imposed moratorium on facial recognition in public spaces '
            'until at least end of 2025. Fined Clearview AI EUR 20M. '
            'Only exception: law enforcement with judicial authorization.',
        oversightBody: 'COPASIR (Parliamentary Committee for Security), Garante',
        legalBasis: 'Privacy Code (D.Lgs. 196/2003, amended by D.Lgs. 101/2018), '
            'Workers\' Statute, Anti-terrorism legislation',
      ),
      cookieConsentRules: 'Garante issued comprehensive cookie guidelines (2021). '
          'Strict opt-in consent required. Cookie walls prohibited. '
          'Active enforcement including fines for non-compliance.',
      immigrantSpecificDigitalRights: 'SPID available to all residents with codice fiscale and permesso di soggiorno. '
          'App IO provides mobile access to many services. GDPR protections apply equally. '
          'Garante provides guidance in Italian and English. '
          'IMPORTANT: Codice fiscale is essential for ALL digital services - obtain it first '
          'at the Agenzia delle Entrate.',
      dataPortabilityNotes: 'Number portability within 2 working days. AGCOM enforces. '
          'Bank account portability under EU Payment Accounts Directive.',
      rightToBeForgottenNotes: 'Garante actively enforces right to erasure. Italian courts have '
          'extensive case law on right to be forgotten, especially regarding press archives.',
    ),

    // ==================== LATVIA ====================
    CountryDigitalRights(
      country: 'Latvia',
      countryCode: 'LV',
      dpa: DataProtectionAuthority(
        country: 'Latvia',
        countryCode: 'LV',
        authorityName: 'Data State Inspectorate',
        authorityNameLocal: 'Datu valsts inspekcija (DVI)',
        website: 'https://www.dvi.gov.lv',
        email: 'info@dvi.gov.lv',
        phone: '+371 67 22 31 31',
        address: 'Elijas iela 17, Riga, LV-1050',
        complaintUrl: 'https://www.dvi.gov.lv/en/individuals/lodge-complaint',
        languagesSupported: ['Latvian', 'English'],
      ),
      digitalIdSystems: [
        DigitalIdSystem(
          systemName: 'eID / eParaksts (eSignature)',
          description: 'Latvian electronic identity card and mobile eSignature for '
              'government services and digital signing.',
          availableToNonCitizens: true,
          availableToResidents: true,
          howToObtain: 'eID card issued at PMLP (migration office). eParaksts mobile app '
              'activated through banks or LVRTC.',
          requiredDocuments: ['Valid passport', 'Residence permit', 'Personal code (personas kods)'],
          website: 'https://www.eparaksts.lv',
        ),
        DigitalIdSystem(
          systemName: 'Smart-ID',
          description: 'Mobile identity app used across the Baltics. Accepted for banking '
              'and many government services in Latvia.',
          availableToNonCitizens: true,
          availableToResidents: true,
          howToObtain: 'Register using Latvian eID card or through participating banks.',
          requiredDocuments: ['Latvian eID or bank account', 'Smartphone'],
          website: 'https://www.smart-id.com',
        ),
      ],
      simCardRegistrationRequired: true,
      simCardRequirements: 'Prepaid SIM registration required since 2019. Must provide valid ID '
          'and personal code. Identity verified at purchase.',
      internetAccessRights: 'Universal service includes broadband. SPRK (regulator) oversees. '
          'Good internet infrastructure. Net neutrality enforced.',
      governmentDigitalServices: [
        'latvija.lv - Central e-government portal',
        'EDS (VID) - Electronic tax declaration system',
        'E-veseliba - Electronic health system',
        'VSAA - Social insurance portal',
        'PMLP e-services - Immigration and citizenship services',
      ],
      govServicesAccessUrl: 'https://www.latvija.lv',
      socialMediaRights: 'Freedom of expression protected by Constitution (Satversme) Article 100. '
          'Latvia has laws against incitement to ethnic hatred.',
      freedomOfExpressionLimits: 'Prohibited: incitement to national/ethnic/racial hatred, '
          'glorification of Soviet or Nazi regimes, defamation.',
      surveillance: SurveillanceInfo(
        publicCameraSurveillanceRegulated: true,
        publicCameraRules: 'DVI guidelines on video surveillance. Notification required. '
            'Municipal cameras in major cities.',
        workplaceSurveillanceRegulated: true,
        workplaceCameraRules: 'Labour Law and DVI guidelines require employee notification. '
            'Proportionality test applies.',
        wiretappingRules: 'Court order required. Special Investigation Bureau oversees. '
            'Only for serious crimes.',
        biometricDataRules: 'GDPR Article 9 protections. Fingerprints in travel documents. '
            'DVI oversees compliance.',
        facialRecognitionStatus: 'No widespread public facial recognition. '
            'Standard border control biometric checks.',
        oversightBody: 'Saeima (Parliament) National Security Committee',
        legalBasis: 'Personal Data Processing Law, Electronic Communications Law, '
            'Operational Activities Law',
      ),
      cookieConsentRules: 'Electronic Communications Law requires consent for cookies. '
          'DVI provides guidance and enforcement.',
      immigrantSpecificDigitalRights: 'Residents with personal code can access digital services. '
          'GDPR applies equally. DVI provides service in Latvian and English. '
          'Smart-ID and eParaksts accessible to all registered residents.',
      dataPortabilityNotes: 'Number portability available. SPRK oversees process.',
      rightToBeForgottenNotes: 'DVI handles erasure requests. Follows GDPR standard procedures.',
    ),

    // ==================== LITHUANIA ====================
    CountryDigitalRights(
      country: 'Lithuania',
      countryCode: 'LT',
      dpa: DataProtectionAuthority(
        country: 'Lithuania',
        countryCode: 'LT',
        authorityName: 'State Data Protection Inspectorate',
        authorityNameLocal: 'Valstybinė duomenų apsaugos inspekcija (VDAI)',
        website: 'https://vdai.lrv.lt',
        email: 'ada@ada.lt',
        phone: '+370 5 271 2804',
        address: 'L. Sapiegos g. 17, 10312 Vilnius',
        complaintUrl: 'https://vdai.lrv.lt/en/for-data-subjects/lodge-a-complaint',
        languagesSupported: ['Lithuanian', 'English'],
      ),
      digitalIdSystems: [
        DigitalIdSystem(
          systemName: 'Electronic Identity (eID / Mobile Signature)',
          description: 'Lithuanian eID card and mobile electronic signature for government '
              'services, banking, and digital signing.',
          availableToNonCitizens: true,
          availableToResidents: true,
          howToObtain: 'eID from Migration Department. Mobile signature through telecom operators. '
              'Smart-ID app as alternative.',
          requiredDocuments: ['Valid passport', 'Residence permit', 'Personal code (asmens kodas)'],
          website: 'https://www.eid.lt',
        ),
        DigitalIdSystem(
          systemName: 'Smart-ID',
          description: 'Mobile identity and signing app widely used in Lithuania. '
              'Accepted for banking, government services.',
          availableToNonCitizens: true,
          availableToResidents: true,
          howToObtain: 'Register using Lithuanian eID or through banks.',
          requiredDocuments: ['Lithuanian eID or bank account', 'Smartphone'],
          website: 'https://www.smart-id.com',
        ),
      ],
      simCardRegistrationRequired: true,
      simCardRequirements: 'Prepaid SIM registration required. Must provide valid ID. '
          'Operators verify identity before activation.',
      internetAccessRights: 'Universal service includes internet. RRT regulates. '
          'Lithuania has excellent internet infrastructure, especially fiber. '
          'Net neutrality enforced.',
      governmentDigitalServices: [
        'epaslaugos.lt - Electronic government services portal',
        'VMI (tax.lt) - Tax administration services',
        'Sodra - Social insurance online services',
        'E-sveikata - Electronic health services',
        'Migration Department e-services',
      ],
      govServicesAccessUrl: 'https://www.epaslaugos.lt',
      socialMediaRights: 'Freedom of expression protected by Constitution Article 25. '
          'Lithuania has laws against incitement to hatred.',
      freedomOfExpressionLimits: 'Prohibited: incitement to hatred, glorification of Soviet/Nazi regimes, '
          'defamation, spreading disinformation threatening national security.',
      surveillance: SurveillanceInfo(
        publicCameraSurveillanceRegulated: true,
        publicCameraRules: 'VDAI guidelines on CCTV. Notification required. '
            'Growing camera network in cities for public safety.',
        workplaceSurveillanceRegulated: true,
        workplaceCameraRules: 'Labour Code and VDAI guidelines. Employee notification required. '
            'Proportionality principle applies.',
        wiretappingRules: 'Court order required. Prosecutor application. '
            'Only for serious crimes. Parliamentary oversight.',
        biometricDataRules: 'GDPR Article 9 protections. Biometrics in travel documents. '
            'VDAI oversees compliance.',
        facialRecognitionStatus: 'No widespread public facial recognition. '
            'Standard border control checks.',
        oversightBody: 'Seimas (Parliament) Committee on National Security',
        legalBasis: 'Personal Data Protection Law, Electronic Communications Law, '
            'Intelligence Law',
      ),
      cookieConsentRules: 'Electronic Communications Law requires consent for cookies. '
          'VDAI provides guidance.',
      immigrantSpecificDigitalRights: 'Residents with personal code can access e-services. '
          'GDPR applies equally. VDAI provides English-language guidance. '
          'Smart-ID widely used and accessible to residents.',
      dataPortabilityNotes: 'Number portability available. RRT oversees.',
      rightToBeForgottenNotes: 'VDAI handles erasure requests under GDPR standard procedures.',
    ),

    // ==================== LUXEMBOURG ====================
    CountryDigitalRights(
      country: 'Luxembourg',
      countryCode: 'LU',
      dpa: DataProtectionAuthority(
        country: 'Luxembourg',
        countryCode: 'LU',
        authorityName: 'National Commission for Data Protection',
        authorityNameLocal: 'Commission nationale pour la protection des données (CNPD)',
        website: 'https://cnpd.public.lu',
        email: 'info@cnpd.lu',
        phone: '+352 26 10 60-1',
        address: '15, Boulevard du Jazz, L-4370 Belvaux',
        complaintUrl: 'https://cnpd.public.lu/en/particuliers/faire-valoir.html',
        languagesSupported: ['French', 'German', 'Luxembourgish', 'English'],
      ),
      digitalIdSystems: [
        DigitalIdSystem(
          systemName: 'LuxTrust',
          description: 'Digital identity and electronic signature solution for Luxembourg. '
              'Used for banking, government services, and legal document signing.',
          availableToNonCitizens: true,
          availableToResidents: true,
          howToObtain: 'Register through a LuxTrust Registration Authority (banks, commune, '
              'Guichet.lu). Need CNS number and valid ID.',
          requiredDocuments: ['Valid passport or ID', 'Residence permit', 'CNS number (social security)', 'Luxembourg address'],
          website: 'https://www.luxtrust.com',
        ),
        DigitalIdSystem(
          systemName: 'GouvID',
          description: 'Government digital identity app for accessing MyGuichet.lu services. '
              'Alternative to LuxTrust for government e-services.',
          availableToNonCitizens: true,
          availableToResidents: true,
          howToObtain: 'Download GouvID app. Register using ID card with eID chip or via '
              'LuxTrust credentials.',
          requiredDocuments: ['Valid ID with eID chip or LuxTrust product', 'Smartphone'],
          website: 'https://guichet.public.lu',
        ),
      ],
      simCardRegistrationRequired: false,
      simCardRequirements: 'Luxembourg does not currently mandate prepaid SIM registration. '
          'Prepaid SIMs can be purchased with minimal ID. Postpaid requires standard '
          'identity verification.',
      internetAccessRights: 'Universal service includes broadband. ILR (regulator) oversees. '
          'Excellent digital infrastructure. Net neutrality enforced. '
          'Luxembourg has among the highest broadband speeds in EU.',
      governmentDigitalServices: [
        'MyGuichet.lu - Central government e-services portal',
        'ACD (impotsdirects.public.lu) - Tax services',
        'CNS (cns.public.lu) - Health insurance',
        'ADEM - Employment services',
        'Guichet.lu - Administrative information',
      ],
      govServicesAccessUrl: 'https://guichet.public.lu',
      socialMediaRights: 'Freedom of expression protected by Constitution Article 24. '
          'Luxembourg hosts many EU institutions and has international approach.',
      freedomOfExpressionLimits: 'Prohibited: hate speech, incitement to discrimination, '
          'defamation, Holocaust denial (Law of August 19, 1997).',
      surveillance: SurveillanceInfo(
        publicCameraSurveillanceRegulated: true,
        publicCameraRules: 'CNPD guidelines on CCTV. Authorization may be required. '
            'Notification mandatory. Small country with moderate CCTV deployment.',
        workplaceSurveillanceRegulated: true,
        workplaceCameraRules: 'Labour Code and CNPD guidelines. Employee notification required. '
            'Staff delegation must be consulted. Proportionality required.',
        wiretappingRules: 'Court order required from investigating judge. '
            'Strict proportionality. Limited to serious offenses.',
        biometricDataRules: 'CNPD strictly regulates biometric data processing. '
            'GDPR Article 9 protections fully implemented.',
        facialRecognitionStatus: 'No public facial recognition deployment. '
            'Very privacy-conscious approach.',
        oversightBody: 'CNPD, Parliamentary oversight committee',
        legalBasis: 'Law of August 1, 2018 (GDPR implementation), '
            'Law of May 30, 2005 (electronic communications)',
      ),
      cookieConsentRules: 'E-Privacy rules require consent. CNPD provides detailed cookie guidance. '
          'Active enforcement.',
      immigrantSpecificDigitalRights: 'Highly international country (47% foreign-born population). '
          'Digital services designed for multilingual, international population. '
          'LuxTrust available to all residents. CNPD provides service in French, German, '
          'Luxembourgish, and English. Very immigrant-friendly digital environment.',
      dataPortabilityNotes: 'Number portability within 1 day. ILR enforces. '
          'Strong banking portability (major financial center).',
      rightToBeForgottenNotes: 'CNPD handles erasure requests. Luxembourg is home to Amazon EU HQ, '
          'so CNPD handles Amazon GDPR cases (EUR 746M fine in 2021).',
    ),

    // ==================== MALTA ====================
    CountryDigitalRights(
      country: 'Malta',
      countryCode: 'MT',
      dpa: DataProtectionAuthority(
        country: 'Malta',
        countryCode: 'MT',
        authorityName: 'Office of the Information and Data Protection Commissioner',
        authorityNameLocal: 'Uffiċċju tal-Kummissarju għall-Informazzjoni u l-Protezzjoni tad-Data (IDPC)',
        website: 'https://idpc.org.mt',
        email: 'idpc.info@idpc.org.mt',
        phone: '+356 2328 7100',
        address: 'Floor 2, Airways House, High Street, Sliema SLM 1549',
        complaintUrl: 'https://idpc.org.mt/complaints/',
        languagesSupported: ['Maltese', 'English'],
      ),
      digitalIdSystems: [
        DigitalIdSystem(
          systemName: 'e-ID Malta',
          description: 'Electronic identity card for Maltese citizens and residents. '
              'Used for government e-services and digital authentication.',
          availableToNonCitizens: true,
          availableToResidents: true,
          howToObtain: 'Apply at Identity Malta. Third-country nationals receive '
              'electronic residence documents with digital features.',
          requiredDocuments: ['Valid passport', 'Residence permit', 'Maltese address'],
          website: 'https://identitymalta.com',
        ),
      ],
      simCardRegistrationRequired: true,
      simCardRequirements: 'Prepaid SIM registration required. Must provide valid ID. '
          'MCA (Malta Communications Authority) oversees.',
      internetAccessRights: 'Universal service includes broadband. MCA regulates. '
          'Very high broadband penetration for island nation. Net neutrality enforced.',
      governmentDigitalServices: [
        'servizz.gov.mt - Government services portal',
        'CFR (tax services) - Inland Revenue online',
        'myHealth portal - Electronic health services',
        'Jobsplus - Employment services',
        'Identity Malta online services',
      ],
      govServicesAccessUrl: 'https://www.servizz.gov.mt',
      socialMediaRights: 'Freedom of expression protected by Constitution Article 41. '
          'Malta has strong media pluralism for its size.',
      freedomOfExpressionLimits: 'Prohibited: hate speech, incitement to racial hatred '
          '(Criminal Code), defamation (decriminalized for media in 2018), '
          'vilification of religion.',
      surveillance: SurveillanceInfo(
        publicCameraSurveillanceRegulated: true,
        publicCameraRules: 'IDPC guidelines on CCTV. Notification required. '
            'Safe City Malta project expanded CCTV in public areas.',
        workplaceSurveillanceRegulated: true,
        workplaceCameraRules: 'IDPC guidelines. Employee notification required. '
            'Proportionality applies.',
        wiretappingRules: 'Court warrant required. Security Service Act regulates. '
            'Oversight by Security Commission.',
        biometricDataRules: 'GDPR Article 9 protections apply. IDPC oversees compliance.',
        facialRecognitionStatus: 'Safe City project includes facial recognition capabilities '
            'in some CCTV cameras. Controversy over scope and safeguards.',
        oversightBody: 'Security Commission, IDPC',
        legalBasis: 'Data Protection Act 2018 (Cap. 586), Security Service Act',
      ),
      cookieConsentRules: 'Electronic Communications Act requires cookie consent. '
          'IDPC provides guidance. Enforcement developing.',
      immigrantSpecificDigitalRights: 'All residents can access digital government services. '
          'GDPR applies equally. IDPC works in both Maltese and English. '
          'Malta has large expatriate community so services are generally English-accessible.',
      dataPortabilityNotes: 'Number portability available. MCA oversees.',
      rightToBeForgottenNotes: 'IDPC handles erasure requests under GDPR.',
    ),

    // ==================== NETHERLANDS ====================
    CountryDigitalRights(
      country: 'Netherlands',
      countryCode: 'NL',
      dpa: DataProtectionAuthority(
        country: 'Netherlands',
        countryCode: 'NL',
        authorityName: 'Dutch Data Protection Authority',
        authorityNameLocal: 'Autoriteit Persoonsgegevens (AP)',
        website: 'https://www.autoriteitpersoonsgegevens.nl',
        email: 'via online form',
        phone: '+31 88 1805 250',
        address: 'Bezuidenhoutseweg 30, 2594 AV The Hague',
        complaintUrl: 'https://www.autoriteitpersoonsgegevens.nl/en/contact-dutch-dpa/tip-us-off',
        languagesSupported: ['Dutch', 'English'],
      ),
      digitalIdSystems: [
        DigitalIdSystem(
          systemName: 'DigiD',
          description: 'Digital identity for Dutch government services. Essential for tax, '
              'health insurance, social benefits, and municipality services.',
          availableToNonCitizens: true,
          availableToResidents: true,
          howToObtain: 'Register at digid.nl with BSN (Citizen Service Number). '
              'Activation letter sent to registered address. DigiD app for mobile use.',
          requiredDocuments: ['BSN (Burgerservicenummer)', 'Dutch registered address', 'Valid ID', 'Dutch phone number'],
          website: 'https://www.digid.nl',
        ),
      ],
      simCardRegistrationRequired: false,
      simCardRequirements: 'Netherlands does not mandate prepaid SIM registration. '
          'Prepaid SIMs available without identification. Postpaid requires standard '
          'identity and credit checks.',
      internetAccessRights: 'Netherlands was first EU country to legislate net neutrality (2012). '
          'Universal service includes internet. ACM (Authority for Consumers and Markets) '
          'and Agentschap Telecom regulate. Excellent broadband infrastructure.',
      governmentDigitalServices: [
        'mijn.overheid.nl - Personal government portal (MijnOverheid)',
        'Belastingdienst (tax.nl) - Tax services',
        'Mijn DUO - Education funding',
        'UWV - Employment insurance services',
        'MijnCBR - Driving licence services',
        'IND online - Immigration and Naturalisation Service',
        'Mijn toeslagen - Benefits and allowances',
      ],
      govServicesAccessUrl: 'https://www.overheid.nl',
      socialMediaRights: 'Strong freedom of expression tradition. Protected by Constitution Article 7. '
          'Netherlands has liberal approach but with hate speech limits.',
      freedomOfExpressionLimits: 'Prohibited: hate speech/group insult (Article 137c-e Criminal Code), '
          'defamation, discrimination, threats. Wilders trial established precedent for '
          'political hate speech prosecution.',
      surveillance: SurveillanceInfo(
        publicCameraSurveillanceRegulated: true,
        publicCameraRules: 'Municipal CCTV regulated by Municipalities Act and AP guidelines. '
            'Council approval required. Signs mandatory. Data retained max 4 weeks.',
        workplaceSurveillanceRegulated: true,
        workplaceCameraRules: 'Works council must be informed. AP provides detailed guidelines. '
            'Covert surveillance only with serious suspicion of criminal activity. '
            'Dutch courts have strong employee privacy protection tradition.',
        wiretappingRules: 'Court authorization required. Intelligence and Security Services Act 2017 '
            '(Wet op de inlichtingen- en veiligheidsdiensten, "Sleepwet") allows bulk '
            'interception with TIB (Toetsingscommissie Inzet Bevoegdheden) oversight. '
            'Controversial - narrowly approved in referendum.',
        biometricDataRules: 'AP very strict on biometric data. Landmark decision banning '
            'fingerprint-based access systems at companies without adequate justification. '
            'Tax authority discriminatory use of nationality data (childcare benefits scandal) '
            'led to fall of government in 2021.',
        facialRecognitionStatus: 'AP critical of facial recognition. No mass deployment. '
            'Police use of Clearview AI investigated. Strong civil liberties debate.',
        oversightBody: 'TIB (Interception assessment committee), CTIVD (oversight committee '
            'for intelligence services)',
        legalBasis: 'GDPR Implementation Act (UAVG), Intelligence and Security Services '
            'Act 2017, Telecommunications Act',
      ),
      cookieConsentRules: 'Telecommunications Act Article 11.7a requires consent. '
          'AP actively enforces. Netherlands follows strict EU approach. '
          'AP has issued guidance on cookie walls (generally prohibited).',
      immigrantSpecificDigitalRights: 'DigiD available to all residents with BSN. BSN obtained at '
          'gemeente (municipality) registration. MijnOverheid is mandatory digital mailbox. '
          'CRITICAL LESSON: The Dutch childcare benefits scandal (toeslagenaffaire) showed '
          'how automated systems discriminated against immigrants based on nationality data. '
          'AP and courts now very vigilant about algorithmic discrimination. '
          'If you suspect automated discrimination, file a complaint immediately.',
      dataPortabilityNotes: 'Number portability within 1 working day. ACM enforces. '
          'Banking portability well-developed (ING, ABN AMRO switching services).',
      rightToBeForgottenNotes: 'AP actively handles erasure requests. Dutch courts have strong '
          'tradition of privacy rights. Extensive case law on right to be forgotten.',
    ),

    // ==================== POLAND ====================
    CountryDigitalRights(
      country: 'Poland',
      countryCode: 'PL',
      dpa: DataProtectionAuthority(
        country: 'Poland',
        countryCode: 'PL',
        authorityName: 'Personal Data Protection Office',
        authorityNameLocal: 'Urząd Ochrony Danych Osobowych (UODO)',
        website: 'https://uodo.gov.pl',
        email: 'kancelaria@uodo.gov.pl',
        phone: '+48 22 531 03 00',
        address: 'ul. Stawki 2, 00-193 Warszawa',
        complaintUrl: 'https://uodo.gov.pl/en/557',
        languagesSupported: ['Polish', 'English'],
      ),
      digitalIdSystems: [
        DigitalIdSystem(
          systemName: 'Profil Zaufany (Trusted Profile)',
          description: 'Free digital identity for Polish government e-services. '
              'Can be confirmed through banks, in person, or via ePUAP.',
          availableToNonCitizens: true,
          availableToResidents: true,
          howToObtain: 'Register at pz.gov.pl. Confirm via Polish bank, at a government office, '
              'or using Polish eID. PESEL number required.',
          requiredDocuments: ['PESEL number', 'Valid passport or ID', 'Residence permit (for non-EU)', 'Polish bank account (for bank confirmation)'],
          website: 'https://pz.gov.pl',
        ),
        DigitalIdSystem(
          systemName: 'mObywatel (mCitizen)',
          description: 'Government mobile app carrying digital versions of ID, driving licence, '
              'vehicle registration, and other documents.',
          availableToNonCitizens: true,
          availableToResidents: true,
          howToObtain: 'Download mObywatel app and log in with Profil Zaufany credentials.',
          requiredDocuments: ['Profil Zaufany account', 'Smartphone'],
          website: 'https://www.gov.pl/web/mobywatel',
        ),
      ],
      simCardRegistrationRequired: true,
      simCardRequirements: 'Prepaid SIM registration mandatory since 2016. Must provide valid ID '
          '(passport, residence card) and PESEL number. Operators must verify identity. '
          'Non-registered SIMs are deactivated.',
      internetAccessRights: 'Universal service includes internet access. UKE (telecom regulator) oversees. '
          'Net neutrality enforced. Poland has competitive mobile market with affordable data.',
      governmentDigitalServices: [
        'gov.pl - Central government portal',
        'ePUAP - Electronic Platform of Public Administration Services',
        'e-Urząd Skarbowy - Tax office portal',
        'PUE ZUS - Social insurance platform',
        'IKP (Internetowe Konto Pacjenta) - Patient internet account',
        'mObywatel - Mobile government services app',
      ],
      govServicesAccessUrl: 'https://www.gov.pl',
      socialMediaRights: 'Freedom of expression protected by Constitution Article 54. '
          'Poland has debated social media regulation. Press freedom concerns raised by EU.',
      freedomOfExpressionLimits: 'Prohibited: incitement to hatred (Article 256 Penal Code), '
          'public insult of religion (Article 196), defamation (civil + criminal), '
          'insult of President or constitutional organs.',
      surveillance: SurveillanceInfo(
        publicCameraSurveillanceRegulated: true,
        publicCameraRules: 'CCTV in public spaces regulated by municipal law and UODO guidelines. '
            'Growing camera networks in cities. Notification required.',
        workplaceSurveillanceRegulated: true,
        workplaceCameraRules: 'Labour Code Article 222-223 regulate workplace monitoring. '
            'Employee notification required 2 weeks before implementation. '
            'Cannot monitor trade union activities or private areas.',
        wiretappingRules: 'Court order required for criminal cases. Internal Security Agency (ABW) '
            'and police have broad surveillance powers. 2016 Surveillance Act expanded powers. '
            'Concerns about oversight effectiveness raised by EU and civil society.',
        biometricDataRules: 'UODO oversees biometric data processing. GDPR Article 9 applies. '
            'Fingerprints in residence permits per EU regulation.',
        facialRecognitionStatus: 'Police have acquired facial recognition technology. '
            'Limited public information about deployment scope. Civil society monitoring.',
        oversightBody: 'Court oversight for wiretaps, Sejm committees',
        legalBasis: 'Personal Data Protection Act 2018, Telecommunications Law, '
            'Police Act, Internal Security Agency Act',
      ),
      cookieConsentRules: 'Telecommunications Law requires consent for cookies. '
          'UODO provides guidance. Enforcement increasing.',
      immigrantSpecificDigitalRights: 'Residents with PESEL can access all digital services. '
          'Profil Zaufany and mObywatel available to residents. '
          'GDPR applies equally. UODO provides English-language guidance. '
          'IMPORTANT: PESEL number is critical for all digital access - obtain it at the city hall.',
      dataPortabilityNotes: 'Number portability available. UKE oversees process.',
      rightToBeForgottenNotes: 'UODO handles erasure requests. Polish courts follow CJEU case law.',
    ),

    // ==================== PORTUGAL ====================
    CountryDigitalRights(
      country: 'Portugal',
      countryCode: 'PT',
      dpa: DataProtectionAuthority(
        country: 'Portugal',
        countryCode: 'PT',
        authorityName: 'Portuguese Data Protection Authority',
        authorityNameLocal: 'Comissão Nacional de Proteção de Dados (CNPD)',
        website: 'https://www.cnpd.pt',
        email: 'geral@cnpd.pt',
        phone: '+351 21 392 84 00',
        address: 'Rua de São Bento 148, 3°, 1200-821 Lisboa',
        complaintUrl: 'https://www.cnpd.pt/cidadaos/exercicio-de-direitos/',
        languagesSupported: ['Portuguese', 'English'],
      ),
      digitalIdSystems: [
        DigitalIdSystem(
          systemName: 'Chave Móvel Digital (Digital Mobile Key)',
          description: 'Mobile digital authentication key for Portuguese government services '
              'and digital signing. Linked to citizen card or tax number.',
          availableToNonCitizens: true,
          availableToResidents: true,
          howToObtain: 'Register at autenticacao.gov.pt with NIF (tax number) or citizen card. '
              'In-person registration at citizen shops or online with Cartão de Cidadão.',
          requiredDocuments: ['NIF (tax number)', 'Valid ID or residence permit', 'Portuguese phone number'],
          website: 'https://www.autenticacao.gov.pt',
        ),
        DigitalIdSystem(
          systemName: 'Cartão de Cidadão (Citizen Card)',
          description: 'Electronic ID card with digital certificate for authentication and signing.',
          availableToNonCitizens: false,
          availableToResidents: false,
          howToObtain: 'Portuguese citizens only. Issued at IRN (registry office).',
          requiredDocuments: ['Portuguese citizenship'],
          website: 'https://www.cartaodecidadao.pt',
        ),
      ],
      simCardRegistrationRequired: true,
      simCardRequirements: 'Prepaid SIM registration required since 2018 (Lei 32/2008). '
          'Must provide valid ID (passport, residence permit) and NIF. '
          'Operators verify identity at point of sale.',
      internetAccessRights: 'Universal service includes broadband. ANACOM regulates. '
          'Good broadband infrastructure. Net neutrality enforced. '
          'Portugal has competitive mobile market.',
      governmentDigitalServices: [
        'ePortugal.gov.pt - Central government portal',
        'Portal das Finanças - Tax services',
        'SNS (Serviço Nacional de Saúde) - Health services portal',
        'Segurança Social Direta - Social security online',
        'SEF/AIMA online - Immigration services',
        'Loja de Cidadão - Citizen shop services',
      ],
      govServicesAccessUrl: 'https://eportugal.gov.pt',
      socialMediaRights: 'Freedom of expression protected by Constitution Article 37. '
          'Portugal has strong press freedom traditions.',
      freedomOfExpressionLimits: 'Prohibited: incitement to discrimination/hatred (Article 240 Penal Code), '
          'defamation (criminal), injury to honor.',
      surveillance: SurveillanceInfo(
        publicCameraSurveillanceRegulated: true,
        publicCameraRules: 'Law 1/2005 regulates video surveillance in public spaces. '
            'CNPD authorization required. Notification mandatory. '
            'Data retention limited to 30 days.',
        workplaceSurveillanceRegulated: true,
        workplaceCameraRules: 'Labour Code (Article 20-22) strictly prohibits surveillance of employees '
            'in performance of work. Cameras only for property protection, not monitoring workers. '
            'Portugal has among the strongest worker privacy protections in EU.',
        wiretappingRules: 'Court order required from investigating judge. Only for crimes punishable '
            'by 3+ years. Criminal Procedure Code regulates. Strict proportionality.',
        biometricDataRules: 'CNPD strict on biometric data. GDPR Article 9 fully implemented. '
            'Workplace biometric systems require strong justification.',
        facialRecognitionStatus: 'No mass public facial recognition. CNPD has expressed concerns. '
            'Privacy-protective approach.',
        oversightBody: 'CNPD, Parliamentary oversight',
        legalBasis: 'Law 58/2019 (GDPR implementation), Law 41/2004 (e-privacy), '
            'Law 1/2005 (video surveillance)',
      ),
      cookieConsentRules: 'Law 41/2004 requires cookie consent. CNPD provides guidance. '
          'Enforcement developing.',
      immigrantSpecificDigitalRights: 'Chave Móvel Digital available to all residents with NIF. '
          'NIF obtainable at tax office (Finanças) even without residence permit. '
          'Portugal is known for welcoming digital nomads and immigrants. '
          'AIMA (immigration agency) has online portals. GDPR protects everyone equally. '
          'CNPD provides service in Portuguese and English.',
      dataPortabilityNotes: 'Number portability within 1 working day. ANACOM enforces.',
      rightToBeForgottenNotes: 'CNPD handles erasure requests. Portuguese courts follow CJEU case law. '
          'Constitutional Court has addressed right to privacy in digital context.',
    ),

    // ==================== ROMANIA ====================
    CountryDigitalRights(
      country: 'Romania',
      countryCode: 'RO',
      dpa: DataProtectionAuthority(
        country: 'Romania',
        countryCode: 'RO',
        authorityName: 'National Supervisory Authority for Personal Data Processing',
        authorityNameLocal: 'Autoritatea Națională de Supraveghere a Prelucrării Datelor cu Caracter Personal (ANSPDCP)',
        website: 'https://www.dataprotection.ro',
        email: 'anspdcp@dataprotection.ro',
        phone: '+40 318 059 211',
        address: 'Bd. G-ral. Gheorghe Magheru nr. 28-30, Sector 1, București',
        complaintUrl: 'https://www.dataprotection.ro/?page=Plangeri_online&lang=en',
        languagesSupported: ['Romanian', 'English'],
      ),
      digitalIdSystems: [
        DigitalIdSystem(
          systemName: 'Electronic Identity Card',
          description: 'New electronic ID card being rolled out with digital identity features.',
          availableToNonCitizens: false,
          availableToResidents: true,
          howToObtain: 'Romanian citizens at DEPABD offices. Foreign residents receive '
              'electronic residence permits from IGI (Immigration Inspectorate).',
          requiredDocuments: ['Valid passport', 'Residence permit', 'Romanian address registration'],
          website: 'https://www.cnp.gov.ro',
        ),
      ],
      simCardRegistrationRequired: true,
      simCardRequirements: 'Prepaid SIM registration required since 2008. Must provide valid ID. '
          'CNP (personal numerical code) required. Operators verify identity.',
      internetAccessRights: 'Universal service includes internet. ANCOM regulates. '
          'Romania has excellent and very affordable broadband (among cheapest in EU). '
          'Very high fiber penetration in urban areas.',
      governmentDigitalServices: [
        'e-guvernare.ro - E-government portal',
        'ANAF online - Tax services',
        'ghiseul.ro - Online payment of taxes and fees',
        'CNAS - Health insurance online services',
        'CNPP - Pension fund online services',
      ],
      govServicesAccessUrl: 'https://www.e-guvernare.ro',
      socialMediaRights: 'Freedom of expression protected by Constitution Article 30. '
          'Romania has relatively liberal free speech environment.',
      freedomOfExpressionLimits: 'Prohibited: incitement to hatred (Penal Code Article 369), '
          'defamation (decriminalized but civil liability), fascist/racist propaganda.',
      surveillance: SurveillanceInfo(
        publicCameraSurveillanceRegulated: true,
        publicCameraRules: 'ANSPDCP guidelines on CCTV. Notification required. '
            'Growing camera networks in major cities.',
        workplaceSurveillanceRegulated: true,
        workplaceCameraRules: 'Labour Code and ANSPDCP guidance. Employee notification required. '
            'Proportionality applies.',
        wiretappingRules: 'Court order required from judge. Criminal Procedure Code regulates. '
            'SRI (intelligence service) capabilities subject to oversight. '
            'Constitutional Court has struck down retention laws.',
        biometricDataRules: 'ANSPDCP oversees biometric data processing. '
            'GDPR Article 9 protections apply.',
        facialRecognitionStatus: 'Limited deployment. No mass public facial recognition. '
            'Standard border control biometric checks.',
        oversightBody: 'Parliamentary committees, ANSPDCP',
        legalBasis: 'Law 190/2018 (GDPR implementation), Law 506/2004 (e-privacy), '
            'Criminal Procedure Code',
      ),
      cookieConsentRules: 'Law 506/2004 requires cookie consent. ANSPDCP provides guidance.',
      immigrantSpecificDigitalRights: 'Residents with CNP can access digital services. '
          'GDPR applies equally. ANSPDCP provides English guidance. '
          'Romania has very affordable internet - beneficial for immigrants.',
      dataPortabilityNotes: 'Number portability within 1 day. ANCOM enforces.',
      rightToBeForgottenNotes: 'ANSPDCP handles erasure requests under GDPR.',
    ),

    // ==================== SLOVAKIA ====================
    CountryDigitalRights(
      country: 'Slovakia',
      countryCode: 'SK',
      dpa: DataProtectionAuthority(
        country: 'Slovakia',
        countryCode: 'SK',
        authorityName: 'Office for Personal Data Protection',
        authorityNameLocal: 'Úrad na ochranu osobných údajov Slovenskej republiky (ÚOOSÚ)',
        website: 'https://dataprotection.gov.sk',
        email: 'statny.dozor@pdp.gov.sk',
        phone: '+421 2 3231 3214',
        address: 'Hraničná 12, 820 07 Bratislava',
        complaintUrl: 'https://dataprotection.gov.sk/uoou/en/content/your-rights',
        languagesSupported: ['Slovak', 'English'],
      ),
      digitalIdSystems: [
        DigitalIdSystem(
          systemName: 'eID (Slovak electronic identity card)',
          description: 'Electronic identity card with chip for digital authentication and signing.',
          availableToNonCitizens: false,
          availableToResidents: true,
          howToObtain: 'Foreign residents receive electronic residence permits from '
              'Border and Aliens Police with digital functionality.',
          requiredDocuments: ['Valid passport', 'Residence permit', 'Slovak address registration'],
          website: 'https://www.slovensko.sk',
        ),
      ],
      simCardRegistrationRequired: true,
      simCardRequirements: 'Prepaid SIM registration required. Must provide valid ID. '
          'Operators verify identity before activation.',
      internetAccessRights: 'Universal service includes internet access. '
          'Regulatory Authority for Electronic Communications and Postal Services (RÚ) oversees. '
          'Net neutrality enforced.',
      governmentDigitalServices: [
        'slovensko.sk - Central government portal',
        'Finančná správa online - Tax services',
        'Sociálna poisťovňa - Social insurance online',
        'NCZI - National health information center',
        'Slovensko.sk Schránky - Electronic mailboxes',
      ],
      govServicesAccessUrl: 'https://www.slovensko.sk',
      socialMediaRights: 'Freedom of expression protected by Constitution Article 26.',
      freedomOfExpressionLimits: 'Prohibited: incitement to hatred (Penal Code §424), defamation, '
          'denial/glorification of Nazi/communist crimes (Penal Code §422d).',
      surveillance: SurveillanceInfo(
        publicCameraSurveillanceRegulated: true,
        publicCameraRules: 'ÚOOSÚ guidelines on CCTV. Notification required.',
        workplaceSurveillanceRegulated: true,
        workplaceCameraRules: 'Labour Code and ÚOOSÚ guidance. Employee notification required.',
        wiretappingRules: 'Court order required. Only for serious crimes. '
            'Parliamentary oversight committee.',
        biometricDataRules: 'GDPR Article 9 protections. Biometrics in travel documents.',
        facialRecognitionStatus: 'No mass public facial recognition deployment.',
        oversightBody: 'Parliamentary committees, ÚOOSÚ',
        legalBasis: 'Act 18/2018 on Personal Data Protection, Electronic Communications Act',
      ),
      cookieConsentRules: 'Electronic Communications Act requires consent. ÚOOSÚ provides guidance.',
      immigrantSpecificDigitalRights: 'Residents with birth number (rodné číslo) can access services. '
          'GDPR applies equally. ÚOOSÚ provides English guidance.',
      dataPortabilityNotes: 'Number portability available. RÚ oversees.',
      rightToBeForgottenNotes: 'ÚOOSÚ handles erasure requests under GDPR.',
    ),

    // ==================== SLOVENIA ====================
    CountryDigitalRights(
      country: 'Slovenia',
      countryCode: 'SI',
      dpa: DataProtectionAuthority(
        country: 'Slovenia',
        countryCode: 'SI',
        authorityName: 'Information Commissioner',
        authorityNameLocal: 'Informacijski pooblaščenec',
        website: 'https://www.ip-rs.si',
        email: 'gp.ip@ip-rs.si',
        phone: '+386 1 230 97 30',
        address: 'Dunajska cesta 22, 1000 Ljubljana',
        complaintUrl: 'https://www.ip-rs.si/en/data-protection/individual-rights',
        languagesSupported: ['Slovenian', 'English'],
      ),
      digitalIdSystems: [
        DigitalIdSystem(
          systemName: 'SI-PASS / smsPASS',
          description: 'Slovenian digital identity system for government e-services. '
              'SI-PASS is the central authentication system.',
          availableToNonCitizens: true,
          availableToResidents: true,
          howToObtain: 'Register at administrative units with valid ID. smsPASS for mobile '
              'authentication. Digital certificates available through SIGEN-CA.',
          requiredDocuments: ['Valid passport or ID', 'Residence permit', 'Slovenian tax number (davčna številka)'],
          website: 'https://www.si-trust.gov.si',
        ),
      ],
      simCardRegistrationRequired: true,
      simCardRequirements: 'Prepaid SIM registration required since 2014. Must provide valid ID. '
          'AKOS (telecom regulator) oversees compliance.',
      internetAccessRights: 'Universal service includes broadband. AKOS regulates. '
          'Good internet infrastructure. Net neutrality enforced.',
      governmentDigitalServices: [
        'e-uprava.gov.si - E-government portal',
        'eDavki - Tax portal',
        'eZdravje - Health services portal',
        'ZPIZ online - Pension and disability insurance',
        'eSociala - Social services portal',
      ],
      govServicesAccessUrl: 'https://e-uprava.gov.si',
      socialMediaRights: 'Freedom of expression protected by Constitution Article 39.',
      freedomOfExpressionLimits: 'Prohibited: incitement to hatred (Penal Code), defamation, '
          'violation of dignity.',
      surveillance: SurveillanceInfo(
        publicCameraSurveillanceRegulated: true,
        publicCameraRules: 'Information Commissioner guidelines on CCTV. Notification required.',
        workplaceSurveillanceRegulated: true,
        workplaceCameraRules: 'Employment Relationships Act and IC guidelines. '
            'Employee notification required. Proportionality applies.',
        wiretappingRules: 'Court order required. Criminal Procedure Act regulates. '
            'Parliamentary oversight.',
        biometricDataRules: 'GDPR Article 9 protections. IC oversees compliance.',
        facialRecognitionStatus: 'No mass public facial recognition. '
            'Privacy-conscious approach.',
        oversightBody: 'Information Commissioner',
        legalBasis: 'Personal Data Protection Act (ZVOP-2), Electronic Communications Act',
      ),
      cookieConsentRules: 'Electronic Communications Act requires consent. IC provides guidance.',
      immigrantSpecificDigitalRights: 'Residents with tax number can access digital services. '
          'GDPR applies equally. IC provides English guidance. '
          'Slovenia is generally accessible for digital immigrants.',
      dataPortabilityNotes: 'Number portability available. AKOS oversees.',
      rightToBeForgottenNotes: 'Information Commissioner handles erasure requests.',
    ),

    // ==================== SPAIN ====================
    CountryDigitalRights(
      country: 'Spain',
      countryCode: 'ES',
      dpa: DataProtectionAuthority(
        country: 'Spain',
        countryCode: 'ES',
        authorityName: 'Spanish Data Protection Agency',
        authorityNameLocal: 'Agencia Española de Protección de Datos (AEPD)',
        website: 'https://www.aepd.es',
        email: 'ciudadano@aepd.es',
        phone: '+34 91 266 35 17',
        address: 'C/ Jorge Juan 6, 28001 Madrid',
        complaintUrl: 'https://www.aepd.es/en/areas-of-action/know-your-rights/right-to-claim',
        languagesSupported: ['Spanish', 'English'],
      ),
      digitalIdSystems: [
        DigitalIdSystem(
          systemName: 'Cl@ve (Clave)',
          description: 'Government digital identity platform providing access to all Spanish '
              'government e-services. Three levels: Cl@ve PIN, Cl@ve Permanente, and certificate.',
          availableToNonCitizens: true,
          availableToResidents: true,
          howToObtain: 'Register at any government office (Oficina de Registro), tax office (AEAT), '
              'or Social Security office. Online registration possible with digital certificate.',
          requiredDocuments: ['NIE (Número de Identidad de Extranjero) for foreigners', 'Valid passport', 'Spanish phone number', 'Email'],
          website: 'https://clave.gob.es',
        ),
        DigitalIdSystem(
          systemName: 'DNIe / Certificate Digital',
          description: 'Electronic national ID (for citizens) and digital certificates '
              '(FNMT - Fábrica Nacional de Moneda y Timbre) for legal digital signing.',
          availableToNonCitizens: true,
          availableToResidents: true,
          howToObtain: 'Digital certificate from FNMT: request online, then verify identity '
              'at a government office with NIE and passport.',
          requiredDocuments: ['NIE', 'Valid passport or ID', 'In-person verification'],
          website: 'https://www.sede.fnmt.gob.es',
        ),
      ],
      simCardRegistrationRequired: true,
      simCardRequirements: 'Prepaid SIM registration required. Must provide valid ID (passport, NIE). '
          'Operators verify identity. Spain has been strict on SIM registration.',
      internetAccessRights: 'Universal service includes broadband (Royal Decree 1517/2019). '
          'CNMC (competition/telecom regulator) oversees. Net neutrality enforced. '
          'Spain has good broadband infrastructure including fiber.',
      governmentDigitalServices: [
        'administracion.gob.es - Central government portal',
        'Agencia Tributaria (AEAT) - Tax services',
        'Sede Electrónica Seguridad Social - Social security',
        'SIP / Carpeta ciudadana de Salud - Health services',
        'SEPE - Employment services',
        'Extranjería (immigration portal)',
        'Carpeta Ciudadana - Personal government folder',
      ],
      govServicesAccessUrl: 'https://administracion.gob.es',
      socialMediaRights: 'Freedom of expression protected by Constitution Article 20. '
          'Spain has specific organic laws protecting honor, privacy, and image rights.',
      freedomOfExpressionLimits: 'Prohibited: hate speech (Penal Code Article 510), '
          'glorification of terrorism (Article 578), insult to the Crown (Article 490-491), '
          'offenses against religious feelings (Article 525). '
          'Ley Mordaza (Citizen Security Law 2015) restricts protests and has been criticized.',
      surveillance: SurveillanceInfo(
        publicCameraSurveillanceRegulated: true,
        publicCameraRules: 'Organic Law 4/1997 on video surveillance by police. '
            'Authorization required from government delegate. AEPD guidelines for private CCTV.',
        workplaceSurveillanceRegulated: true,
        workplaceCameraRules: 'Workers\' Statute and AEPD/LOPDGDD guidelines. Employee notification '
            'required. Constitutional Court has addressed employee monitoring (STC 39/2016).',
        wiretappingRules: 'Court order required from investigating judge. Organic Law regulates. '
            'CNI (intelligence) has broader powers with judicial authorization. '
            'Pegasus spyware scandal (2022) revealed surveillance of Catalan politicians.',
        biometricDataRules: 'AEPD strict on biometric data. Has issued guidelines on biometric '
            'time and attendance systems. DPIA required. Consent or legal obligation needed.',
        facialRecognitionStatus: 'AEPD fined La Liga EUR 250K for stadium facial recognition use. '
            'No mass public deployment. AEPD takes strong position against '
            'disproportionate facial recognition.',
        oversightBody: 'Parliamentary oversight commissions, AEPD',
        legalBasis: 'LOPDGDD (Organic Law 3/2018), Citizen Security Law, '
            'Electronic Communications Law',
      ),
      cookieConsentRules: 'LSSI (Information Society Services Act) requires cookie consent. '
          'AEPD provides detailed cookie guidelines and actively enforces.',
      immigrantSpecificDigitalRights: 'All residents with NIE can access Cl@ve and digital services. '
          'NIE is essential - obtain at police foreigner office (Oficina de Extranjería). '
          'AEPD is very active and provides English guidance. '
          'Spain has specific right to digital education and right to disconnection from work (LOPDGDD). '
          'Autonomous communities may have additional digital services.',
      dataPortabilityNotes: 'Number portability within 1 working day. CNMC enforces. '
          'Very competitive telecom market.',
      rightToBeForgottenNotes: 'Spain originated the landmark Google Spain CJEU case (C-131/12) '
          'that established the right to be forgotten in EU law. AEPD processes '
          'high volume of erasure requests. Very strong tradition.',
    ),

    // ==================== SWEDEN ====================
    CountryDigitalRights(
      country: 'Sweden',
      countryCode: 'SE',
      dpa: DataProtectionAuthority(
        country: 'Sweden',
        countryCode: 'SE',
        authorityName: 'Swedish Authority for Privacy Protection',
        authorityNameLocal: 'Integritetsskyddsmyndigheten (IMY)',
        website: 'https://www.imy.se',
        email: 'imy@imy.se',
        phone: '+46 8 657 61 00',
        address: 'Box 8114, 104 20 Stockholm',
        complaintUrl: 'https://www.imy.se/en/individuals/complaints-and-tips/',
        languagesSupported: ['Swedish', 'English'],
      ),
      digitalIdSystems: [
        DigitalIdSystem(
          systemName: 'BankID',
          description: 'Sweden\'s de facto digital identity. Used for virtually everything: '
              'banking, government services, healthcare, signing contracts, age verification. '
              'Almost mandatory for living in Sweden.',
          availableToNonCitizens: true,
          availableToResidents: true,
          howToObtain: 'Must have Swedish bank account. The bank issues BankID after identity '
              'verification. Download BankID app on smartphone. Requires personnummer.',
          requiredDocuments: ['Swedish personnummer (personal identity number)', 'Swedish bank account', 'Valid ID verified by bank', 'Smartphone'],
          website: 'https://www.bankid.com',
        ),
        DigitalIdSystem(
          systemName: 'Freja eID',
          description: 'Alternative digital identity to BankID. Accepted by many government services. '
              'Can be obtained without Swedish bank account.',
          availableToNonCitizens: true,
          availableToResidents: true,
          howToObtain: 'Download Freja eID app. Verify identity at a Freja eID agent point '
              '(ATG stores, post offices) with valid ID.',
          requiredDocuments: ['Valid passport or Swedish ID', 'Swedish personnummer or samordningsnummer', 'Smartphone'],
          website: 'https://frejaeid.com',
        ),
      ],
      simCardRegistrationRequired: true,
      simCardRequirements: 'Since July 2022, prepaid SIM cards require identification. '
          'Must provide valid ID. Operators must verify identity. '
          'Existing users had transition period until 2024.',
      internetAccessRights: 'Universal service includes broadband. PTS (Post and Telecom Authority) '
          'regulates. Excellent internet infrastructure. Net neutrality enforced. '
          'Sweden has among the highest internet usage rates globally.',
      governmentDigitalServices: [
        'myndighetspost (Kivra/Min Myndighetspost) - Digital government mailbox',
        'Skatteverket (skatteverket.se) - Tax agency (Mina sidor)',
        'Försäkringskassan (FK) - Social insurance online',
        '1177.se - Healthcare information and services',
        'Arbetsförmedlingen - Employment services',
        'Migrationsverket (migrationsverket.se) - Migration Agency online',
      ],
      govServicesAccessUrl: 'https://www.sweden.se/life/society/digital-id',
      socialMediaRights: 'Very strong freedom of expression tradition. Protected by Grundlagen '
          '(constitutional laws). Sweden has unique Freedom of the Press Act (1766, world\'s oldest).',
      freedomOfExpressionLimits: 'Prohibited: hate speech (hets mot folkgrupp), defamation, '
          'unlawful threats. Sweden\'s free speech protections are among the strongest in EU.',
      surveillance: SurveillanceInfo(
        publicCameraSurveillanceRegulated: true,
        publicCameraRules: 'Camera Surveillance Act (Kameraövervakningslag) requires permit from '
            'IMY for most public surveillance. Conditions and time limits set. '
            'Annual permit review.',
        workplaceSurveillanceRegulated: true,
        workplaceCameraRules: 'IMY guidelines. Must have legitimate interest. '
            'Employees must be informed. Union negotiation may be required (MBL).',
        wiretappingRules: 'Court order required. Signals intelligence (FRA) can intercept '
            'cross-border communications under FRA Law (2008, controversial). '
            'SIN (Statens inspektion för försvarsunderrättelseverksamheten) oversight.',
        biometricDataRules: 'IMY strict on biometric data. Fined Swedish school EUR 20K for '
            'facial recognition attendance tracking (2019, first GDPR biometric fine in EU). '
            'Workplace biometric systems require careful assessment.',
        facialRecognitionStatus: 'IMY fined police for unauthorized use of Clearview AI. '
            'Very restrictive approach. National facial recognition deployment requires '
            'careful legal basis. Active civil society monitoring.',
        oversightBody: 'SIN (Signals Intelligence oversight), IMY',
        legalBasis: 'Data Protection Act (2018:218), Camera Surveillance Act, '
            'FRA Law (signals intelligence), Code of Judicial Procedure',
      ),
      cookieConsentRules: 'Electronic Communications Act (LEK) requires consent. '
          'IMY provides guidance and actively enforces.',
      immigrantSpecificDigitalRights: 'CRITICAL: BankID is nearly essential for daily life in Sweden, but '
          'getting it requires a personnummer AND a Swedish bank account, which can be '
          'very difficult for new immigrants. This creates a significant digital exclusion problem. '
          'Freja eID is an important alternative. Samordningsnummer (coordination number) '
          'may work for some services. Migrationsverket has online services for checking '
          'case status. IMY provides English-language complaint process.',
      dataPortabilityNotes: 'Number portability within 1 day. PTS enforces. '
          'Sweden has very competitive mobile market.',
      rightToBeForgottenNotes: 'IMY handles erasure requests. Swedish courts follow CJEU case law. '
          'Sweden\'s strong transparency tradition (offentlighetsprincipen) can sometimes '
          'conflict with right to erasure for public records.',
    ),

  ];

  // ============================================================
  // LOOKUP METHODS
  // ============================================================

  /// Get digital rights info for a specific country by code
  CountryDigitalRights? getByCountryCode(String code) {
    final upperCode = code.toUpperCase();
    try {
      return allCountries.firstWhere((c) => c.countryCode == upperCode);
    } catch (_) {
      return null;
    }
  }

  /// Get digital rights info for a specific country by name
  CountryDigitalRights? getByCountryName(String name) {
    final lowerName = name.toLowerCase();
    try {
      return allCountries.firstWhere(
        (c) => c.country.toLowerCase() == lowerName,
      );
    } catch (_) {
      return null;
    }
  }

  /// Get all Data Protection Authorities
  List<DataProtectionAuthority> getAllDPAs() {
    return allCountries.map((c) => c.dpa).toList();
  }

  /// Get DPA for a specific country
  DataProtectionAuthority? getDPA(String countryCode) {
    return getByCountryCode(countryCode)?.dpa;
  }

  /// Get countries with SIM registration requirements
  List<CountryDigitalRights> getCountriesWithSimRegistration() {
    return allCountries.where((c) => c.simCardRegistrationRequired).toList();
  }

  /// Get countries without SIM registration requirements
  List<CountryDigitalRights> getCountriesWithoutSimRegistration() {
    return allCountries.where((c) => !c.simCardRegistrationRequired).toList();
  }

  /// Get all universal GDPR rights
  List<GdprRightsInfo> getGdprRights() {
    return universalGdprRights;
  }

  /// Get GDPR complaint filing steps
  List<String> getComplaintSteps() {
    return gdprComplaintSteps;
  }

  /// Get cookie consent rights
  List<String> getCookieRights() {
    return cookieConsentRights;
  }

  /// Get data access request template
  String getDataAccessTemplate() {
    return dataAccessRequestTemplate;
  }

  /// Get data erasure request template
  String getDataErasureTemplate() {
    return dataErasureRequestTemplate;
  }

  /// Get digital ID systems for a country
  List<DigitalIdSystem> getDigitalIdSystems(String countryCode) {
    return getByCountryCode(countryCode)?.digitalIdSystems ?? [];
  }

  /// Get surveillance info for a country
  SurveillanceInfo? getSurveillanceInfo(String countryCode) {
    return getByCountryCode(countryCode)?.surveillance;
  }

  /// Get countries where digital ID is available to non-citizens
  List<Map<String, dynamic>> getDigitalIdAccessForNonCitizens() {
    final results = <Map<String, dynamic>>[];
    for (final country in allCountries) {
      for (final system in country.digitalIdSystems) {
        if (system.availableToNonCitizens) {
          results.add({
            'country': country.country,
            'countryCode': country.countryCode,
            'system': system.systemName,
            'description': system.description,
            'howToObtain': system.howToObtain,
          });
        }
      }
    }
    return results;
  }

  /// Search digital rights database by keyword
  List<Map<String, dynamic>> searchByKeyword(String keyword) {
    final lowerKeyword = keyword.toLowerCase();
    final results = <Map<String, dynamic>>[];

    for (final country in allCountries) {
      final matches = <String>[];

      if (country.simCardRequirements.toLowerCase().contains(lowerKeyword)) {
        matches.add('SIM card: ${country.simCardRequirements}');
      }
      if (country.internetAccessRights.toLowerCase().contains(lowerKeyword)) {
        matches.add('Internet: ${country.internetAccessRights}');
      }
      if (country.socialMediaRights.toLowerCase().contains(lowerKeyword)) {
        matches.add('Social media: ${country.socialMediaRights}');
      }
      if (country.freedomOfExpressionLimits.toLowerCase().contains(lowerKeyword)) {
        matches.add('Expression limits: ${country.freedomOfExpressionLimits}');
      }
      if (country.surveillance.wiretappingRules.toLowerCase().contains(lowerKeyword)) {
        matches.add('Wiretapping: ${country.surveillance.wiretappingRules}');
      }
      if (country.surveillance.biometricDataRules.toLowerCase().contains(lowerKeyword)) {
        matches.add('Biometrics: ${country.surveillance.biometricDataRules}');
      }
      if (country.surveillance.facialRecognitionStatus.toLowerCase().contains(lowerKeyword)) {
        matches.add('Facial recognition: ${country.surveillance.facialRecognitionStatus}');
      }
      if (country.immigrantSpecificDigitalRights.toLowerCase().contains(lowerKeyword)) {
        matches.add('Immigrant rights: ${country.immigrantSpecificDigitalRights}');
      }
      if (country.cookieConsentRules.toLowerCase().contains(lowerKeyword)) {
        matches.add('Cookies: ${country.cookieConsentRules}');
      }

      if (matches.isNotEmpty) {
        results.add({
          'country': country.country,
          'countryCode': country.countryCode,
          'matches': matches,
        });
      }
    }
    return results;
  }

  /// Get immigrant-specific digital rights summary for a country
  String getImmigrantDigitalRights(String countryCode) {
    final country = getByCountryCode(countryCode);
    if (country == null) return 'Country not found.';

    return '''
Digital Rights for Immigrants in ${country.country}:

DATA PROTECTION:
- DPA: ${country.dpa.authorityName} (${country.dpa.authorityNameLocal})
- Website: ${country.dpa.website}
- Complaint: ${country.dpa.complaintUrl}
- Languages: ${country.dpa.languagesSupported.join(', ')}

DIGITAL IDENTITY:
${country.digitalIdSystems.map((s) => '- ${s.systemName}: ${s.availableToNonCitizens ? "Available to immigrants" : "Citizens only"}\n  ${s.howToObtain}').join('\n')}

SIM CARD:
- Registration required: ${country.simCardRegistrationRequired ? 'YES' : 'NO'}
- ${country.simCardRequirements}

INTERNET:
- ${country.internetAccessRights}

GOVERNMENT SERVICES:
${country.governmentDigitalServices.map((s) => '- $s').join('\n')}
- Access: ${country.govServicesAccessUrl}

SURVEILLANCE:
- Public cameras: ${country.surveillance.publicCameraRules}
- Workplace cameras: ${country.surveillance.workplaceCameraRules}
- Wiretapping: ${country.surveillance.wiretappingRules}
- Biometrics: ${country.surveillance.biometricDataRules}
- Facial recognition: ${country.surveillance.facialRecognitionStatus}

SOCIAL MEDIA:
- ${country.socialMediaRights}
- Limits: ${country.freedomOfExpressionLimits}

COOKIES: ${country.cookieConsentRules}

IMMIGRANT-SPECIFIC NOTES:
${country.immigrantSpecificDigitalRights}

RIGHT TO BE FORGOTTEN:
${country.rightToBeForgottenNotes}

DATA PORTABILITY:
${country.dataPortabilityNotes}
''';
  }

  /// Get all country codes in the database
  List<String> getAllCountryCodes() {
    return allCountries.map((c) => c.countryCode).toList();
  }

  /// Get count of countries in database
  int get countryCount => allCountries.length;

  /// Compare digital rights between two countries
  Map<String, dynamic> compareCountries(String code1, String code2) {
    final c1 = getByCountryCode(code1);
    final c2 = getByCountryCode(code2);
    if (c1 == null || c2 == null) return {'error': 'Country not found'};

    return {
      'country1': c1.country,
      'country2': c2.country,
      'simRegistration': {
        c1.country: c1.simCardRegistrationRequired,
        c2.country: c2.simCardRegistrationRequired,
      },
      'digitalIdForImmigrants': {
        c1.country: c1.digitalIdSystems.any((s) => s.availableToNonCitizens),
        c2.country: c2.digitalIdSystems.any((s) => s.availableToNonCitizens),
      },
      'dpaLanguages': {
        c1.country: c1.dpa.languagesSupported,
        c2.country: c2.dpa.languagesSupported,
      },
      'facialRecognition': {
        c1.country: c1.surveillance.facialRecognitionStatus,
        c2.country: c2.surveillance.facialRecognitionStatus,
      },
      'immigrantNotes': {
        c1.country: c1.immigrantSpecificDigitalRights,
        c2.country: c2.immigrantSpecificDigitalRights,
      },
    };
  }
}
