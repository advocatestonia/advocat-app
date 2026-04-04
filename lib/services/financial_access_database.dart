// Financial Access & Banking Rights Database for all 27 EU Countries
// Real data for immigrant financial inclusion, banking, tax, and fraud protection
// Last updated: 2026-04
//
// Sources: EU Payment Accounts Directive 2014/92/EU, European Banking Authority (EBA),
// European Consumer Centre Network (ECC-Net), national central bank regulations,
// FRA (EU Agency for Fundamental Rights) reports, OECD tax databases,
// national tax authority publications, European Anti-Fraud Office (OLAF),
// World Bank Remittance Prices Worldwide, national financial supervisory authorities,
// PICUM financial inclusion reports, UNHCR banking access studies.

class FinancialAccessInfo {
  final String country;
  final String countryCode;
  // Banking access
  final bool basicAccountRight;
  final String basicAccountDirectiveStatus;
  final List<String> documentsForBankAccount;
  final List<String> banksForAsylumSeekers;
  final List<String> banksForUndocumented;
  final List<String> bestBanksForImmigrants;
  final String bankAccountNotes;
  // Money transfers
  final List<String> moneyTransferServices;
  final String cheapestRemittanceOptions;
  // Tax
  final String taxIdName;
  final String taxIdHowToGet;
  final String socialSecurityNumber;
  final String socialSecurityHowToGet;
  final String taxObligationsForImmigrants;
  final String taxFilingDeadline;
  final String taxAuthorityWebsite;
  final String taxAuthorityPhone;
  // Credit & debt
  final String consumerCreditRights;
  final String creditHistoryBuilding;
  final String debtProtectionLaws;
  final String overIndebtednessHelp;
  // Fraud & scam protection
  final String fraudProtectionAuthority;
  final String fraudReportingPhone;
  final String fraudReportingWebsite;
  final List<String> commonScamsTargetingImmigrants;
  final List<String> scamPreventionTips;
  // Legal basis
  final String legalBasis;
  final String financialOmbudsman;
  final String immigrantSpecificNotes;

  const FinancialAccessInfo({
    required this.country,
    required this.countryCode,
    required this.basicAccountRight,
    required this.basicAccountDirectiveStatus,
    required this.documentsForBankAccount,
    required this.banksForAsylumSeekers,
    required this.banksForUndocumented,
    required this.bestBanksForImmigrants,
    required this.bankAccountNotes,
    required this.moneyTransferServices,
    required this.cheapestRemittanceOptions,
    required this.taxIdName,
    required this.taxIdHowToGet,
    required this.socialSecurityNumber,
    required this.socialSecurityHowToGet,
    required this.taxObligationsForImmigrants,
    required this.taxFilingDeadline,
    required this.taxAuthorityWebsite,
    required this.taxAuthorityPhone,
    required this.consumerCreditRights,
    required this.creditHistoryBuilding,
    required this.debtProtectionLaws,
    required this.overIndebtednessHelp,
    required this.fraudProtectionAuthority,
    required this.fraudReportingPhone,
    required this.fraudReportingWebsite,
    required this.commonScamsTargetingImmigrants,
    required this.scamPreventionTips,
    required this.legalBasis,
    required this.financialOmbudsman,
    required this.immigrantSpecificNotes,
  });

  Map<String, dynamic> toMap() {
    return {
      'country': country,
      'countryCode': countryCode,
      'basicAccountRight': basicAccountRight,
      'basicAccountDirectiveStatus': basicAccountDirectiveStatus,
      'documentsForBankAccount': documentsForBankAccount,
      'banksForAsylumSeekers': banksForAsylumSeekers,
      'banksForUndocumented': banksForUndocumented,
      'bestBanksForImmigrants': bestBanksForImmigrants,
      'bankAccountNotes': bankAccountNotes,
      'moneyTransferServices': moneyTransferServices,
      'cheapestRemittanceOptions': cheapestRemittanceOptions,
      'taxIdName': taxIdName,
      'taxIdHowToGet': taxIdHowToGet,
      'socialSecurityNumber': socialSecurityNumber,
      'socialSecurityHowToGet': socialSecurityHowToGet,
      'taxObligationsForImmigrants': taxObligationsForImmigrants,
      'taxFilingDeadline': taxFilingDeadline,
      'taxAuthorityWebsite': taxAuthorityWebsite,
      'taxAuthorityPhone': taxAuthorityPhone,
      'consumerCreditRights': consumerCreditRights,
      'creditHistoryBuilding': creditHistoryBuilding,
      'debtProtectionLaws': debtProtectionLaws,
      'overIndebtednessHelp': overIndebtednessHelp,
      'fraudProtectionAuthority': fraudProtectionAuthority,
      'fraudReportingPhone': fraudReportingPhone,
      'fraudReportingWebsite': fraudReportingWebsite,
      'commonScamsTargetingImmigrants': commonScamsTargetingImmigrants,
      'scamPreventionTips': scamPreventionTips,
      'legalBasis': legalBasis,
      'financialOmbudsman': financialOmbudsman,
      'immigrantSpecificNotes': immigrantSpecificNotes,
    };
  }
}

class FinancialAccessDatabase {
  static final FinancialAccessDatabase _instance =
      FinancialAccessDatabase._internal();
  factory FinancialAccessDatabase() => _instance;
  FinancialAccessDatabase._internal();

  FinancialAccessInfo? getCountryInfo(String countryCode) {
    return _data[countryCode.toUpperCase()];
  }

  List<FinancialAccessInfo> getAllCountries() {
    return _data.values.toList();
  }

  List<FinancialAccessInfo> searchByFeature(String feature) {
    final lower = feature.toLowerCase();
    return _data.values.where((info) {
      return info.country.toLowerCase().contains(lower) ||
          info.bankAccountNotes.toLowerCase().contains(lower) ||
          info.immigrantSpecificNotes.toLowerCase().contains(lower) ||
          info.bestBanksForImmigrants
              .any((b) => b.toLowerCase().contains(lower));
    }).toList();
  }

  List<FinancialAccessInfo> getCountriesWithAsylumBanking() {
    return _data.values
        .where((info) => info.banksForAsylumSeekers.isNotEmpty)
        .toList();
  }

  List<FinancialAccessInfo> getCountriesWithUndocumentedBanking() {
    return _data.values
        .where((info) => info.banksForUndocumented.isNotEmpty)
        .toList();
  }

  // =====================================================================
  // PRACTICAL TIPS (cross-country)
  // =====================================================================

  static const List<String> generalRemittanceTips = [
    'Compare rates on comparison sites: monito.com, wise.com/compare, remitly.com before sending.',
    'Avoid airport/station currency exchange kiosks — they charge 5-15% markups.',
    'Wise (formerly TransferBank) and Revolut typically offer mid-market exchange rates with 0.3-1% fees.',
    'For regular transfers to the same country, set up recurring transfers — many providers give better rates.',
    'Western Union and MoneyGram have wide cash pickup networks but charge 3-8% fees. Use only when recipient has no bank account.',
    'Remitly, Sendwave, and WorldRemit are cheaper alternatives with mobile money delivery in Africa/Asia.',
    'Always check the TOTAL cost: exchange rate markup + transfer fee + receiving fee.',
    'EU SEPA transfers between EU bank accounts cost the same as domestic transfers (often free).',
    'Cryptocurrency remittances (via stablecoins like USDC) can be very cheap but require tech knowledge on both ends.',
  ];

  static const List<String> creditBuildingTips = [
    'Open a basic bank account first — this is the foundation of financial identity in the EU.',
    'Get a prepaid debit card and use it regularly to build a transaction history.',
    'Pay all bills (rent, utilities, phone) on time and from your bank account — this creates a payment track record.',
    'After 6-12 months of regular income deposits, ask your bank about a small credit card or overdraft facility.',
    'In some countries (Germany, Austria), request your credit report from the national credit bureau to check your score.',
    'Avoid informal lending (from community money lenders) — it builds no credit history and often has exploitative terms.',
    'If you have a guarantor (employer, friend with good credit), a guaranteed loan can kickstart your credit file.',
    'Mobile phone contracts (postpaid) are a form of credit and help build credit history in many EU countries.',
    'Microcredit organizations (Adie in France, Qredits in Netherlands) specifically serve immigrants and build credit.',
    'Never miss a payment — even one missed payment can severely damage a thin credit file.',
  ];

  static const List<String> scammedActionSteps = [
    'IMMEDIATELY contact your bank to freeze the account/card and dispute the transaction.',
    'File a police report (Anzeige/plainte/denuncia) — you need this for any fraud claim.',
    'Report to the national financial fraud authority (listed per country in the database).',
    'If you sent money via wire transfer, contact the receiving bank to try to recall the funds (works within 24-48 hours).',
    'Report online scams to the EU platform: ec.europa.eu/consumers/odr',
    'Contact your national consumer protection center — they can advise on recovery options.',
    'If the scam involved identity theft, request a credit freeze from the national credit bureau.',
    'Document everything: screenshots, emails, transaction records, phone numbers used by scammers.',
    'Contact ECAS (European Citizen Action Service) for cross-border fraud assistance.',
    'For employment scams, contact the national labor inspectorate — fake job offers used for trafficking are criminal.',
    'Never pay "fees" to recover scammed money — this is always a secondary scam.',
  ];

  // =====================================================================
  // COUNTRY DATA — all 27 EU member states
  // =====================================================================

  final Map<String, FinancialAccessInfo> _data = {
    // ===================================================================
    // AUSTRIA
    // ===================================================================
    'AT': const FinancialAccessInfo(
      country: 'Austria',
      countryCode: 'AT',
      basicAccountRight: true,
      basicAccountDirectiveStatus:
          'Fully transposed via Verbraucherzahlungskontogesetz (VZKG) 2016. All legal residents and asylum seekers with Aufenthaltstitel or Verfahrenskarte entitled to a Basiskonto.',
      documentsForBankAccount: [
        'Passport or national ID card',
        'Meldezettel (registration confirmation from Meldeamt)',
        'For asylum seekers: Verfahrenskarte (procedure card) or Aufenthaltsberechtigungskarte',
        'For recognized refugees: Konventionsreisepass or blue card',
        'Proof of address (Meldezettel suffices)',
      ],
      banksForAsylumSeekers: [
        'Erste Bank — offers Basiskonto to asylum seekers with Verfahrenskarte',
        'Bank Austria (UniCredit) — accepts asylum procedure documents',
        'Raiffeisen regional banks — varies by Bundesland, most accept asylum seekers',
        'BAWAG P.S.K. — basic accounts available at post offices',
      ],
      banksForUndocumented: [
        'Very limited. No bank legally required to open account without valid ID.',
        'Diakonie and Caritas can sometimes facilitate emergency payment solutions.',
        'Prepaid cards (Paysafecard, available at Trafik shops) do not require ID for small amounts.',
      ],
      bestBanksForImmigrants: [
        'Erste Bank — multilingual service, strong Basiskonto program, George app in English',
        'Bank Austria — large branch network, English-speaking staff in Vienna',
        'N26 — fully digital, English interface, German IBAN, no branch visits needed',
        'Revolut — English app, no Austrian address needed to start, limited IBAN functionality',
        'BAWAG P.S.K. — available at all post offices, convenient for rural areas',
      ],
      bankAccountNotes:
          'Austrian banks must offer a Basiskonto (basic payment account) for max EUR 80/year to any legal resident. The account includes a debit card, SEPA transfers, and online banking. Banks can refuse only for AML (money laundering) reasons. Refusal can be appealed to FMA (Finanzmarktaufsicht).',
      moneyTransferServices: [
        'Wise (TransferWise) — available online and app',
        'Western Union — available at post offices and BAWAG branches',
        'MoneyGram — available at various agent locations',
        'Remitly — online/app',
        'WorldRemit — online/app',
        'Azimo — online/app, popular for Eastern Europe transfers',
      ],
      cheapestRemittanceOptions:
          'Wise offers mid-market rates with 0.4-1.5% total cost. For Turkey/Balkans, Azimo is competitive. For cash pickup in developing countries, Remitly often beats Western Union by 2-4%.',
      taxIdName: 'Steuernummer (tax number) / Steuer-Identifikationsnummer',
      taxIdHowToGet:
          'Automatically assigned by the Finanzamt (tax office) when you register your residence (Meldezettel) or start employment. Your employer will arrange it if employed. Self-employed must register at the local Finanzamt with passport + Meldezettel.',
      socialSecurityNumber: 'Sozialversicherungsnummer (SV-Nummer)',
      socialSecurityHowToGet:
          'Automatically assigned by Dachverband der Sozialversicherungsträger when you start employment or register for health insurance. Your employer handles it. Self-employed register via SVS (Sozialversicherung der Selbständigen). Asylum seekers receive one through Grundversorgung.',
      taxObligationsForImmigrants:
          'Residents (183+ days/year) taxed on worldwide income. Progressive income tax: 0% up to EUR 12,816, then 20%-55%. Employment income taxed at source (Lohnsteuer). Must file annual Arbeitnehmerveranlagung if requested or to claim deductions. Self-employed must file by June 30 (or April 30 paper). Double taxation treaties with 90+ countries.',
      taxFilingDeadline:
          'April 30 (paper) or June 30 (electronic via FinanzOnline) for previous year. Extension possible on request.',
      taxAuthorityWebsite: 'https://www.bmf.gv.at',
      taxAuthorityPhone: '+43 50 233 233',
      consumerCreditRights:
          'EU Consumer Credit Directive applies. Lender must provide Standard European Consumer Credit Information (SECCI) sheet before signing. 14-day withdrawal right. APR must be clearly stated. Credit checks via KSV1870 and CRIF. Immigrants with no Austrian credit history may face higher rates or refusal — building 6-12 months of bank history helps.',
      creditHistoryBuilding:
          'Austria uses KSV1870 and CRIF as main credit bureaus. Positive data (regular payments) and negative data (defaults) are recorded. New immigrants start with no file. Open a bank account, get a phone contract, pay rent from the account, and after 6-12 months you build a basic profile. Request your free annual credit report from KSV1870 (Selbstauskunft).',
      debtProtectionLaws:
          'Privatkonkurs (personal insolvency) available after failed Zahlungsplan. Abschöpfungsverfahren: debts can be discharged after 3 years of good conduct. Existenzminimum (protected minimum income) cannot be seized — roughly EUR 1,120/month for single person. Wage garnishment (Lohnpfändung) limited to amounts above Existenzminimum.',
      overIndebtednessHelp:
          'Free debt counseling: Schuldnerberatung (state-funded, available in each Bundesland). ASB Schuldnerberatung GmbH: www.schuldenberatung.at, Tel: check regional office. Caritas Sozialberatung also assists immigrants with debt issues.',
      fraudProtectionAuthority: 'FMA (Finanzmarktaufsicht)',
      fraudReportingPhone: '+43 1 249 59-0',
      fraudReportingWebsite: 'https://www.fma.gv.at',
      commonScamsTargetingImmigrants: [
        'Fake job offers requiring upfront "visa processing fees" or "work permit deposits"',
        'Hawala-style informal money transfer operators who disappear with funds',
        'Fake landlords demanding deposit payments before viewing apartments (common on willhaben.at)',
        'Phishing SMS/emails pretending to be from Finanzamt or Bank Austria requesting login data',
        'Unlicensed "financial advisors" in immigrant communities selling overpriced insurance products',
        '"Quick loan" offers with hidden fees targeting people rejected by banks',
        'Fake Meldezettel or document services charging for free government services',
      ],
      scamPreventionTips: [
        'Never pay upfront fees for jobs or apartments — legitimate employers/landlords do not require this',
        'Use only licensed money transfer services — check FMA register at fma.gv.at',
        'Never share bank login credentials via phone, email, or SMS',
        'Verify landlords via Grundbuch (land register) before paying deposits',
        'Get insurance advice from AK (Arbeiterkammer) consumer protection, not door-to-door salespeople',
        'Report suspicious financial offers to FMA or Polizei (133)',
      ],
      legalBasis:
          'Verbraucherzahlungskontogesetz (VZKG) 2016, BWG (Bankwesengesetz), KSchG (Konsumentenschutzgesetz), IO (Insolvenzordnung), FM-GwG (Finanzmarkt-Geldwäschegesetz).',
      financialOmbudsman:
          'Gemeinsame Schlichtungsstelle der Österreichischen Kreditwirtschaft. Website: www.bankenschlichtung.at. Free mediation for banking disputes.',
      immigrantSpecificNotes:
          'Arbeiterkammer (AK) provides FREE financial and legal advice to all workers including immigrants, in multiple languages. AK Wien has Arabic, Turkish, and BKS-language advisors. Contact: +43 1 501 65-0. Caritas and Diakonie also provide financial literacy programs for refugees.',
    ),

    // ===================================================================
    // BELGIUM
    // ===================================================================
    'BE': const FinancialAccessInfo(
      country: 'Belgium',
      countryCode: 'BE',
      basicAccountRight: true,
      basicAccountDirectiveStatus:
          'Transposed via Loi/Wet of 2003 (updated 2016 per PAD). Anyone legally residing in Belgium or lawfully in EU entitled to service bancaire de base / basisbankdienst. Max cost EUR 18.58/year (indexed).',
      documentsForBankAccount: [
        'Valid passport or national ID',
        'Proof of Belgian address (attestation de domicile from commune)',
        'For asylum seekers: Attestation d\'immatriculation (orange card) or Annexe 26',
        'For recognized refugees: A or B card (electronic foreigner card)',
        'Appendix 15 (renewal receipt) accepted by most banks',
      ],
      banksForAsylumSeekers: [
        'Belfius — actively serves asylum seekers, accepts orange card (AI)',
        'BNP Paribas Fortis — accepts Annexe 26 and orange card',
        'KBC/CBC — regional availability, generally accepts asylum documents',
        'Beobank — smaller network but immigrant-friendly policies',
      ],
      banksForUndocumented: [
        'Legally difficult. Banks require valid ID and legal residence proof.',
        'Fedasil and CPAS/OCMW can sometimes facilitate payment solutions for residents of reception centers.',
        'Prepaid cards from shops (Neosurf, Paysafecard) available without ID for small amounts.',
      ],
      bestBanksForImmigrants: [
        'Belfius — strong digital platform (app in English/French/Dutch), accepts diverse documents',
        'BNP Paribas Fortis — largest branch network, multilingual staff in Brussels',
        'N26 — German IBAN but works across EU, fully English, no branch needed',
        'Wise — multi-currency account, Belgian IBAN available, excellent for remittances',
        'KBC — strong app, competitive fees, good for Flanders-based immigrants',
      ],
      bankAccountNotes:
          'Belgian basic bank service (service bancaire de base) is guaranteed by law. If a bank refuses, the applicant can request the account via the Basisbankdienst procedure: the bank must open the account within 10 business days or provide a written refusal that can be challenged at the FOD Economie. Cost capped at EUR 18.58/year.',
      moneyTransferServices: [
        'Wise — online/app, Belgian IBAN',
        'Western Union — available at post offices (bpost) and agent locations',
        'MoneyGram — agent locations throughout Belgium',
        'Remitly — online/app',
        'WorldRemit — online/app',
        'Ria Money Transfer — agents in major cities',
        'Mukuru — popular for Southern Africa transfers',
      ],
      cheapestRemittanceOptions:
          'Wise for bank-to-bank transfers (0.4-1.2% cost). For Morocco/DRC/Turkey, Ria and Remitly often have promotional zero-fee offers. Avoid Western Union for regular transfers — fees are 3-7%.',
      taxIdName: 'Numéro national / Rijksregisternummer (National Register Number)',
      taxIdHowToGet:
          'Assigned automatically when registering at your commune (gemeente). Appears on your eID, residence card, or Annexe. If not yet registered, the tax office (SPF Finances) can issue a temporary fiscal number (numéro fiscal/bis-nummer) upon request with passport.',
      socialSecurityNumber: 'NISS / INSZ (same as National Register Number for residents)',
      socialSecurityHowToGet:
          'Automatically issued upon commune registration. For asylum seekers in Fedasil reception: a bis-number is assigned. Contact the Banque Carrefour de la Sécurité Sociale (BCSS/KSZ) if issues arise. Employers use your NISS for social security declarations.',
      taxObligationsForImmigrants:
          'Belgian residents (domicile or center of economic interests) taxed on worldwide income. Progressive rates: 25%-50% (50% above EUR 46,440). Non-residents: taxed only on Belgian-source income. Employment income taxed at source (précompte professionnel/bedrijfsvoorheffing). Annual declaration mandatory for all residents. Double taxation treaties with 95+ countries.',
      taxFilingDeadline:
          'Usually end of June (paper) or mid-July (Tax-on-web/MyMinfin online) for previous year. Exact date published annually by SPF Finances.',
      taxAuthorityWebsite: 'https://finances.belgium.be / https://financien.belgium.be',
      taxAuthorityPhone: '02 572 57 57 (Contact Center SPF Finances)',
      consumerCreditRights:
          'EU Consumer Credit Directive transposed. Centrale des Crédits aux Particuliers (CKP) at National Bank records all consumer credits and defaults. 14-day withdrawal right. SECCI information mandatory. Maximum APR rates set by law (varies by loan type). Immigrants can access consumer credit once employed with Belgian bank history.',
      creditHistoryBuilding:
          'Belgium uses Centrale des Crédits aux Particuliers (positive and negative registry at National Bank). Every consumer credit is registered. No credit history means no positive data — start by getting a bank account, small credit card after 6+ months of salary deposits. Mobile phone contracts and utility bills in your name help indirectly.',
      debtProtectionLaws:
          'Règlement Collectif de Dettes (RCD) — collective debt settlement procedure through labor court (tribunal du travail). Mediator appointed. Essential expenses and minimum income protected. Insaisissabilité: minimum living amount protected from seizure. Full discharge possible after 5-7 years.',
      overIndebtednessHelp:
          'Free debt mediation: Services de Médiation de Dettes (French community) or Erkende Instellingen voor Schuldbemiddeling (Flemish). CPAS/OCMW provides free assistance. Call 0800 120 33 (Vlaanderen) or contact your local CPAS.',
      fraudProtectionAuthority:
          'FSMA (Financial Services and Markets Authority) for financial products. SPF Economie for consumer fraud.',
      fraudReportingPhone: '0800 120 33 (SPF Economie consumer helpline)',
      fraudReportingWebsite: 'https://meldpunt.belgie.be / https://pointdecontact.belgique.be',
      commonScamsTargetingImmigrants: [
        'Fake Fedasil/CGRS letters requesting payment for "faster asylum processing"',
        'Unofficial "immigration consultants" charging EUR 500-3000 for services available free via legal aid',
        'Phishing emails pretending to be from BNP Paribas Fortis or Belfius',
        'Fake apartment listings on immoweb.be or Facebook requiring wire transfer deposits to foreign accounts',
        'Underground banking (hawala) operators who fail to deliver transfers',
        'Pyramid/Ponzi schemes promoted within immigrant communities via WhatsApp groups',
        '"Regularization" scams promising papers for a fee',
      ],
      scamPreventionTips: [
        'Government services (CGRA/CGVS, Fedasil, commune) NEVER charge processing fees directly — all fees go through official channels',
        'Use only lawyers registered with the Belgian bar (Barreau/Balie) — check at avocats.be or advocaat.be',
        'Never send apartment deposits before visiting and signing a contract',
        'Check FSMA warning lists for unauthorized financial providers: fsma.be/en/warnings',
        'Report scams immediately to police (101) and the fraud reporting point (meldpunt.belgie.be)',
      ],
      legalBasis:
          'Loi du 24/03/2003 (basic bank service), Code de droit économique (consumer protection), Loi relative au crédit à la consommation, Code judiciaire (debt collection protections), AML Law of 18/09/2017.',
      financialOmbudsman:
          'Ombudsfin — free mediation for banking/investment disputes. Website: www.ombudsfin.be. Tel: 02 545 77 70.',
      immigrantSpecificNotes:
          'CIRÉ (Coordination et Initiatives pour Réfugiés et Étrangers) provides financial literacy workshops for refugees in Wallonia/Brussels. Vluchtelingenwerk Vlaanderen offers similar in Flanders. CPAS/OCMW can provide emergency financial assistance and help navigating the banking system. Pro bono legal aid (aide juridique de deuxième ligne) available for all low-income residents.',
    ),

    // ===================================================================
    // BULGARIA
    // ===================================================================
    'BG': const FinancialAccessInfo(
      country: 'Bulgaria',
      countryCode: 'BG',
      basicAccountRight: true,
      basicAccountDirectiveStatus:
          'Transposed via amendments to the Law on Payment Services and Payment Systems (2016). Right to basic payment account for all legal residents. Max fee set by BNB (Bulgarian National Bank).',
      documentsForBankAccount: [
        'Valid passport or national ID',
        'Bulgarian personal identification number (ЕГН for citizens / ЛНЧ for foreigners)',
        'Proof of address (utility bill or rental contract)',
        'For asylum seekers: Registration card from SAR (State Agency for Refugees)',
        'For holders of residence permit: Bulgarian residence permit card',
      ],
      banksForAsylumSeekers: [
        'DSK Bank — accepts SAR registration cards for basic accounts',
        'UniCredit Bulbank — asylum seeker accounts available with SAR documents',
        'Postbank (Eurobank) — has served asylum seekers in Sofia',
      ],
      banksForUndocumented: [
        'Effectively no access. Bulgarian banks require ЛНЧ (foreigner personal number) or valid ID.',
        'Prepaid Easypay cards available at some retail locations without full bank KYC.',
      ],
      bestBanksForImmigrants: [
        'DSK Bank — largest branch network, some English support, accepts diverse foreign documents',
        'UniCredit Bulbank — strong international network (part of UniCredit group), English-speaking staff in Sofia',
        'Fibank — competitive fees, English online banking',
        'Revolut — widely used in Bulgaria, English interface, EU IBAN, no branch needed',
      ],
      bankAccountNotes:
          'Bulgaria has low banking fees overall. Basic account (osnovna smetka) available by law. Many Bulgarians and immigrants use Revolut as primary account due to zero fees. Traditional bank accounts typically cost BGN 2-5/month. Opening requires ЛНЧ for foreigners, obtainable at Migration Directorate.',
      moneyTransferServices: [
        'Wise — online/app',
        'Western Union — available at Easypay and bank branches',
        'MoneyGram — agents throughout Bulgaria',
        'Easypay — Bulgarian payment network with thousands of terminals',
        'ePay.bg — Bulgarian online payment system',
        'Remitly — online/app',
      ],
      cheapestRemittanceOptions:
          'Wise for bank transfers (0.5-1.5%). Easypay terminals for cash-based services within Bulgaria. For Ukraine/Russia/Turkey, Wise or Paysend are cheapest. Cash remittances via Western Union at Easypay offices.',
      taxIdName: 'ЛНЧ (Личен Номер на Чужденец — Personal Number of Foreigner)',
      taxIdHowToGet:
          'Issued automatically by the Migration Directorate when foreigners register for residence. Apply at the local Migration Directorate office with passport and residence basis documents. Processing: 7-14 days. For EU citizens, issued upon registering long-term address.',
      socialSecurityNumber: 'ЕГН (for citizens) / ЛНЧ (for foreigners) — same number used for tax and social security',
      socialSecurityHowToGet:
          'ЛНЧ issued by Migration Directorate serves as social security identifier. Employer registers you with NRA (National Revenue Agency) and NOI (National Social Security Institute) using your ЛНЧ. Self-employed register directly at NRA.',
      taxObligationsForImmigrants:
          'Flat income tax rate: 10% on all income. Social security contributions: approximately 31-33% of gross salary (split employer/employee — employee pays about 13.78%). Residents taxed on worldwide income. Annual tax return due by April 30. Bulgaria has one of the lowest tax burdens in the EU.',
      taxFilingDeadline: 'April 30 for previous year. 5% discount if filed by March 31.',
      taxAuthorityWebsite: 'https://www.nra.bg',
      taxAuthorityPhone: '0700 18 700 (NRA call center)',
      consumerCreditRights:
          'EU Consumer Credit Directive transposed. Central Credit Register maintained by BNB. SECCI information required. 14-day withdrawal right. Maximum interest rates not capped by law but BNB monitors. Credit available to foreigners with ЛНЧ and income proof after establishing bank history.',
      creditHistoryBuilding:
          'BNB Central Credit Register tracks all loans above BGN 100. New immigrants have no file. Open bank account, get utility contracts in your name, after 6+ months of regular income request a small consumer loan. Bulgarian credit market is accessible — even small loans build history.',
      debtProtectionLaws:
          'Commercial Insolvency Act applies to businesses. Personal insolvency framework being developed (as of 2025). Seizure limits: minimum pension amount protected. Enforcement via private bailiffs (частен съдебен изпълнител). Court can reduce or reschedule debts in hardship cases.',
      overIndebtednessHelp:
          'Commission for Consumer Protection (KZP) handles complaints. Free legal aid available through National Legal Aid Bureau (НБПП) for low-income residents. Some NGOs (Bulgarian Helsinki Committee, Council of Refugee Women) assist refugees with financial issues.',
      fraudProtectionAuthority: 'Commission for Consumer Protection (KZP) / FSC (Financial Supervision Commission)',
      fraudReportingPhone: '0700 111 22 (KZP hotline)',
      fraudReportingWebsite: 'https://www.kzp.bg',
      commonScamsTargetingImmigrants: [
        'Fake job agencies charging upfront fees for non-existent positions',
        'Unlicensed money lenders (лихвари) charging 100-500% annual interest',
        'Fake document services (promising residence permits or work authorization for fees)',
        'Real estate scams — fake landlords renting apartments they do not own',
        'Phone scams impersonating NRA demanding immediate tax payment via gift cards',
        'Crypto investment scams promoted on Russian-language Telegram groups',
      ],
      scamPreventionTips: [
        'Verify employer registration at the Trade Register (brra.bg) before paying any fees',
        'Use only licensed credit institutions listed on BNB website (bnb.bg)',
        'Never pay for government services through unofficial channels',
        'Verify apartment ownership at the Property Register before paying deposits',
        'NRA never demands payment by phone or gift cards',
        'Report scams to police (112) and KZP',
      ],
      legalBasis:
          'Law on Payment Services and Payment Systems, Law on Credit Institutions, Consumer Credit Act, Law on Consumer Protection, AML Law.',
      financialOmbudsman:
          'No dedicated financial ombudsman. Disputes handled by KZP (consumer protection) and FSC (financial supervision). Court mediation available.',
      immigrantSpecificNotes:
          'Bulgaria has very low cost of living and flat 10% tax, making it financially attractive. However, wages are the lowest in the EU. Bulgarian Helsinki Committee (BHC) provides free legal assistance to refugees including financial matters. UNHCR Bulgaria partners with local NGOs for financial inclusion programs. Many immigrants use Revolut/Wise as primary financial tools due to ease of setup.',
    ),

    // ===================================================================
    // CROATIA
    // ===================================================================
    'HR': const FinancialAccessInfo(
      country: 'Croatia',
      countryCode: 'HR',
      basicAccountRight: true,
      basicAccountDirectiveStatus:
          'Transposed via Zakon o platnom prometu (Payment Transactions Act) amendments 2017. All legal residents entitled to basic payment account (osnovni račun). Max fee HRK 12/month (approximately EUR 1.60).',
      documentsForBankAccount: [
        'Valid passport or national ID',
        'OIB (Personal Identification Number)',
        'Proof of address (potvrda o prebivalištu from MUP)',
        'For asylum seekers: Iskaznica tražitelja azila (asylum seeker ID card)',
        'For recognized refugees: Dozvola boravka (residence permit)',
      ],
      banksForAsylumSeekers: [
        'Zagrebačka banka (UniCredit) — accepts asylum seeker documents in Zagreb',
        'Privredna banka Zagreb (PBZ) — basic accounts for asylum seekers',
        'Hrvatska poštanska banka (HPB) — state-owned, accessible for diverse document types',
      ],
      banksForUndocumented: [
        'No access without valid ID and OIB number.',
        'Croatian Red Cross and JRS (Jesuit Refugee Service) can facilitate emergency payment solutions.',
      ],
      bestBanksForImmigrants: [
        'Zagrebačka banka — largest bank, part of UniCredit group, some English service',
        'PBZ — strong digital banking, English app available',
        'Revolut — widely adopted in Croatia since EUR adoption, no branch needed',
        'Wise — EUR account, excellent for remittances',
        'HPB — state bank, immigrant-friendly, present in all cities',
      ],
      bankAccountNotes:
          'Croatia adopted the EUR on January 1, 2023, simplifying banking for immigrants from eurozone countries. OIB is required — foreigners receive it from the Tax Administration (Porezna uprava) upon registering residence. Basic account guaranteed by law with debit card and online banking.',
      moneyTransferServices: [
        'Wise — online/app',
        'Western Union — at FINA offices and bank branches',
        'MoneyGram — agent locations in major cities',
        'Remitly — online/app',
        'FINA — Croatian national payment system, useful for domestic transfers',
      ],
      cheapestRemittanceOptions:
          'Wise for most corridors (0.5-1.5%). Since Croatia uses EUR, SEPA transfers to/from other eurozone countries are essentially free. For Bosnia/Serbia, Wise or Western Union at FINA offices.',
      taxIdName: 'OIB (Osobni identifikacijski broj — Personal Identification Number)',
      taxIdHowToGet:
          'Automatically assigned by the Tax Administration (Porezna uprava) when foreigners register residence or start employment in Croatia. Apply at the local tax office with passport and residence proof. Processing: immediate to 7 days. Required for all financial transactions.',
      socialSecurityNumber: 'OIB serves as the universal identifier for tax and social security',
      socialSecurityHowToGet:
          'OIB is the social security identifier. Register with HZZO (Croatian Health Insurance Fund) through your employer or directly if self-employed. Employer handles HZZO and HZMO (pension) registration using your OIB.',
      taxObligationsForImmigrants:
          'Residents taxed on worldwide income. Income tax: 20% (up to EUR 50,400) and 30% (above). Surtax (prirez): 0-18% depending on municipality (Zagreb 18%). Social contributions: pension 20% (employer+employee), health 16.5% (employer). Annual return due by February 28 if tax not fully settled via payroll.',
      taxFilingDeadline: 'February 28 for previous year (if required beyond payroll withholding).',
      taxAuthorityWebsite: 'https://www.porezna-uprava.hr',
      taxAuthorityPhone: '+385 1 480 9000',
      consumerCreditRights:
          'EU Consumer Credit Directive transposed. Croatian National Bank (HNB) supervises. SECCI mandatory. 14-day withdrawal. HROK (Hrvatski registar obveza po kreditima) is the credit registry. Immigrants can access credit after establishing income and bank history in Croatia.',
      creditHistoryBuilding:
          'HROK maintained by HNB records all credit obligations. New arrivals have no file. Steps: open bank account, ensure regular income deposits, get a mobile postpaid contract, after 6-12 months apply for a small credit card. Croatian banks increasingly accept foreign credit histories for EU citizens.',
      debtProtectionLaws:
          'Consumer Bankruptcy Act (Zakon o stečaju potrošača) allows personal insolvency. Court-supervised repayment plan over 5 years, then discharge. Protected minimum income: 75% of average net salary equivalent. FINA (Financial Agency) manages enforcement — wages/accounts cannot be blocked below the protected minimum.',
      overIndebtednessHelp:
          'Free legal aid via county legal aid offices (Ured za besplatnu pravnu pomoć). Croatian Red Cross provides financial counseling. Consumer protection association (Potrošač) offers advice.',
      fraudProtectionAuthority: 'HANFA (Croatian Financial Services Supervisory Agency) / HNB (Croatian National Bank)',
      fraudReportingPhone: '112 (emergency) / +385 1 489 3600 (HANFA)',
      fraudReportingWebsite: 'https://www.hanfa.hr',
      commonScamsTargetingImmigrants: [
        'Fake OIB or residence permit services charging for free government processes',
        'Unlicensed "travel agents" selling fake work contracts for Western Europe',
        'Apartment deposit scams on njuskalo.hr (Croatian classifieds)',
        'Fake investment schemes promising high returns (often via Viber groups)',
        'Phone scams impersonating FINA or Porezna uprava demanding payments',
      ],
      scamPreventionTips: [
        'OIB is free from Porezna uprava — never pay third parties for it',
        'Verify financial service providers at HNB or HANFA registries',
        'Never wire deposits for apartments without viewing and signing a contract',
        'Government agencies never request payment by phone or messaging apps',
        'Report to police (192) and HANFA for financial scams',
      ],
      legalBasis:
          'Payment Transactions Act, Credit Institutions Act, Consumer Credit Act, Consumer Bankruptcy Act, AML/CFT Law.',
      financialOmbudsman:
          'HNB handles banking complaints. HANFA handles insurance and investment complaints. No single financial ombudsman — disputes go through courts or mediation.',
      immigrantSpecificNotes:
          'Since EUR adoption (2023), immigrants from other eurozone countries face no currency conversion issues. Are You Syrious (AYS) and JRS Croatia provide integration support including financial literacy. Croatian language is the main barrier — learn basic banking vocabulary. HZZO health insurance enrollment is essential before accessing many financial services.',
    ),

    // ===================================================================
    // CYPRUS
    // ===================================================================
    'CY': const FinancialAccessInfo(
      country: 'Cyprus',
      countryCode: 'CY',
      basicAccountRight: true,
      basicAccountDirectiveStatus:
          'Transposed via Basic Payment Accounts Law (2016). All legal residents and EU citizens entitled to a basic payment account. Central Bank of Cyprus (CBC) oversees compliance.',
      documentsForBankAccount: [
        'Valid passport',
        'Proof of address in Cyprus (utility bill or rental contract)',
        'ARC (Alien Registration Certificate) or residence permit',
        'For asylum seekers: Confirmation of asylum application from Asylum Service',
        'Tax identification number (TIC) — recommended but not always required for basic account',
      ],
      banksForAsylumSeekers: [
        'Bank of Cyprus — has opened accounts for asylum seekers with asylum confirmation documents',
        'Hellenic Bank — accepts asylum procedure documents for basic accounts',
        'Cyprus Cooperative Bank (now Hellenic Bank) — historically served asylum seekers',
      ],
      banksForUndocumented: [
        'Very limited. Cypriot banks strictly enforce KYC/AML requirements.',
        'KISA (Action for Equality, Support, Antiracism) may assist in emergency cases.',
        'Prepaid cards available at some retail locations.',
      ],
      bestBanksForImmigrants: [
        'Bank of Cyprus — largest bank, English fully supported, widest ATM/branch network',
        'Hellenic Bank — second largest, good English service, competitive fees',
        'Revolut — very popular in Cyprus, English, EUR IBAN, no branch needed',
        'Wise — multi-currency, excellent for remittances to home countries',
      ],
      bankAccountNotes:
          'Cyprus banking sector recovered from the 2013 crisis and is now well-regulated. Banks are cautious with KYC/AML due to past issues. English is widely spoken in all banks. Basic account costs max EUR 3/month. Expect thorough document verification — bring originals and certified copies.',
      moneyTransferServices: [
        'Wise — online/app',
        'Western Union — agent locations throughout Cyprus',
        'MoneyGram — available at various agents',
        'Remitly — online/app',
        'JCC Payment Systems — Cypriot payment processor',
      ],
      cheapestRemittanceOptions:
          'Wise for bank transfers to most countries (0.4-1.5%). For Philippines/Sri Lanka/India (large immigrant communities in Cyprus), Remitly and WorldRemit offer competitive rates. SEPA transfers free/cheap within EU.',
      taxIdName: 'TIC (Tax Identification Code)',
      taxIdHowToGet:
          'Apply at the Tax Department (Inland Revenue) with passport, residence permit, and proof of address. Processing: 1-5 days. Can also apply online via TAXISnet portal. Employers may arrange it for employees.',
      socialSecurityNumber: 'Social Insurance Number',
      socialSecurityHowToGet:
          'Apply at the Social Insurance Services office with passport and residence/work permit. Employer usually handles registration for employees. Self-employed register directly. Processing: 1-2 weeks.',
      taxObligationsForImmigrants:
          'Residents (183+ days) taxed on worldwide income. Progressive rates: 0% up to EUR 19,500, then 20%-35%. Non-domiciled residents benefit from special exemptions (no tax on dividends, interest). Cyprus has generous tax regime for new residents. Social insurance: 8.8% employee, 8.8% employer. Annual return due July 31.',
      taxFilingDeadline: 'July 31 for employed, March 31 for self-employed (electronic via TAXISnet).',
      taxAuthorityWebsite: 'https://www.tax.gov.cy',
      taxAuthorityPhone: '+357 22 601 600',
      consumerCreditRights:
          'EU Consumer Credit Directive transposed. CBC supervises credit institutions. Credit bureau: Artemis (run by AIPS). SECCI required. 14-day withdrawal. Responsible lending requirements enforced since banking crisis reforms.',
      creditHistoryBuilding:
          'Artemis credit bureau operated by Association of International Payment Services (AIPS). Records all credit facilities. New immigrants start clean. Open bank account, get utility contracts, after stable employment request credit card. Cyprus banks may accept credit references from your home country.',
      debtProtectionLaws:
          'Personal insolvency framework (2015/2018 reforms): Debt Relief Orders for debts under EUR 25,000. Personal Repayment Plans through Insolvency Service. Examinership for viable restructuring. Primary residence protection under specific conditions.',
      overIndebtednessHelp:
          'Insolvency Service of Cyprus provides free guidance. Financial Ombudsman handles complaints. Citizens Advice Bureau (CAB) offers free financial advice in English and Greek.',
      fraudProtectionAuthority: 'CBC (Central Bank of Cyprus) / CySEC (Securities and Exchange Commission)',
      fraudReportingPhone: '+357 22 714 100 (CBC)',
      fraudReportingWebsite: 'https://www.centralbank.cy',
      commonScamsTargetingImmigrants: [
        'Fake employment agencies charging fees for domestic worker positions',
        'Illegal money lending (loan sharks) in immigrant worker communities',
        'Fake property investment schemes targeting foreign buyers',
        'Phishing emails impersonating Bank of Cyprus or Hellenic Bank',
        'Fraudulent "immigration lawyer" services with no bar registration',
        'Pyramid schemes in domestic worker communities (common in Sri Lankan/Filipino groups)',
      ],
      scamPreventionTips: [
        'Employment agencies cannot legally charge workers fees — only employers pay',
        'Verify lawyers at Cyprus Bar Association (cyprusbarassociation.org)',
        'Use only CBC-licensed financial institutions — check at centralbank.cy',
        'Never share banking PINs or passwords via phone or message',
        'Report to police (112/199) and CBC for financial scams',
      ],
      legalBasis:
          'Basic Payment Accounts Law 2016, Business of Credit Institutions Laws, Consumer Credit Law, Personal Insolvency Law, AML Law 188(I)/2007.',
      financialOmbudsman:
          'Financial Ombudsman of the Republic of Cyprus. Website: www.financialombudsman.gov.cy. Tel: +357 22 848 900. Free, handles all financial disputes.',
      immigrantSpecificNotes:
          'Cyprus has large immigrant worker populations (domestic workers from Philippines/Sri Lanka, workers from South/Southeast Asia). KISA NGO provides financial rights information. Caritas Cyprus offers integration support. English is widely used in banking. Non-domiciled tax status is very favorable for new immigrant residents (up to 17 years of tax exemptions on certain income types).',
    ),

    // ===================================================================
    // CZECHIA
    // ===================================================================
    'CZ': const FinancialAccessInfo(
      country: 'Czechia',
      countryCode: 'CZ',
      basicAccountRight: true,
      basicAccountDirectiveStatus:
          'Transposed via Act on Payment System (Act No. 370/2017 Sb.). Legal residents and EU citizens entitled to basic payment account (základní platební účet). Max fee CZK 1,400/year (approximately EUR 57).',
      documentsForBankAccount: [
        'Valid passport or national ID',
        'Proof of Czech address (nájemní smlouva or potvrzení o ubytování)',
        'For foreigners: residence permit (povolení k pobytu) or visa',
        'For asylum seekers: Průkaz žadatele o mezinárodní ochranu (asylum seeker card)',
        'Birth number (rodné číslo) — required by most banks, issued by OAMP',
      ],
      banksForAsylumSeekers: [
        'Česká spořitelna (Erste Group) — most open to asylum seekers, accepts asylum seeker cards',
        'ČSOB — accepts diverse documentation for basic accounts',
        'Fio banka — zero-fee current account, flexible document requirements',
      ],
      banksForUndocumented: [
        'No legal access without valid ID. Czech banks require rodné číslo or equivalent.',
        'OPU (Organization for Aid to Refugees) may assist in emergency situations.',
        'Prepaid cards available without bank account at some retailers.',
      ],
      bestBanksForImmigrants: [
        'Fio banka — completely free current account, English online banking, no minimum balance',
        'Česká spořitelna — largest bank, George app in English, strong basic account program',
        'Air Bank — modern digital bank, competitive rates, some English support',
        'Revolut — CZK and EUR support, fully English, no branch needed',
        'Wise — multi-currency account, great for remittances, CZK support',
        'mBank — free account, English online banking',
      ],
      bankAccountNotes:
          'Czechia uses CZK (Czech koruna), not EUR. Exchange rate costs apply for eurozone transfers. Fio banka is notably immigrant-friendly with zero fees. Most banks require rodné číslo (birth number) — foreigners receive this from OAMP (Odbor azylové a migrační politiky) when registering. Digital banks (Revolut, Wise) are popular alternatives while waiting for documents.',
      moneyTransferServices: [
        'Wise — online/app, excellent CZK rates',
        'Western Union — at Czech Post (Česká pošta) offices',
        'MoneyGram — agent locations',
        'Remitly — online/app',
        'Sazka terminals — some payment services available',
      ],
      cheapestRemittanceOptions:
          'Wise is best for CZK conversions (0.4-1.2% total). For Ukraine (large Ukrainian community), Wise and Paysend are cheapest. Avoid bureau de change on tourist streets — use banks or Wise for conversion.',
      taxIdName: 'DIČ (Daňové identifikační číslo — Tax Identification Number)',
      taxIdHowToGet:
          'For employees: employer registers you and DIČ is assigned automatically by the tax office (Finanční úřad). Self-employed: register at the local Finanční úřad with passport, residence permit, and business license (živnostenský list). DIČ format: CZ + rodné číslo.',
      socialSecurityNumber: 'Rodné číslo (Birth Number) — serves as universal identifier',
      socialSecurityHowToGet:
          'Issued by OAMP (Ministry of Interior migration department) when registering for residence. For EU citizens: at the local foreigners police. For asylum seekers: included in the asylum seeker card. Processing: 1-30 days depending on status. Essential for all official interactions.',
      taxObligationsForImmigrants:
          'Residents taxed on worldwide income. Flat rate 15% (up to CZK 1,935,552 / ~EUR 79,000), 23% above that threshold. Social insurance: 6.5% employee + 24.8% employer. Health insurance: 4.5% employee + 9% employer. Annual return due April 1. Extensive double taxation treaty network.',
      taxFilingDeadline: 'April 1 (paper), May 2 (electronic), July 1 (with tax advisor) for previous year.',
      taxAuthorityWebsite: 'https://www.financnisprava.cz',
      taxAuthorityPhone: '+420 225 092 392',
      consumerCreditRights:
          'Consumer Credit Act (257/2016 Sb.) transposing EU directive. Czech National Bank (ČNB) supervises. SOLUS and CNCB credit registries. 14-day withdrawal. APR cap exists. Only ČNB-licensed entities can provide consumer credit. Strong protections against predatory lending.',
      creditHistoryBuilding:
          'SOLUS (negative registry) and Czech Banking Credit Bureau (CBCB, positive+negative) track credit history. New immigrants have no file. Steps: get rodné číslo, open bank account (Fio banka free), regular salary deposits, after 6-12 months apply for credit card or small loan. Phone contracts also build history.',
      debtProtectionLaws:
          'Insolvency Act (Insolvenční zákon 182/2006 Sb.) allows personal bankruptcy (oddlužení). Debtor pays what they can over 3-5 years, rest is discharged. Protected minimum: cannot seize below living minimum (životní minimum) + housing costs. Strong consumer protection against aggressive debt collection.',
      overIndebtednessHelp:
          'Free debt advice: Občanská poradna (Citizens Advice Bureaus) in most cities. Poradna při finanční tísni (Financial Distress Advisory): www.financnitisen.cz. Pro bono legal aid through Czech Bar Association.',
      fraudProtectionAuthority: 'ČNB (Czech National Bank) / ČOI (Czech Trade Inspection)',
      fraudReportingPhone: '158 (police economic crime) / +420 222 070 101 (ČNB)',
      fraudReportingWebsite: 'https://www.cnb.cz / https://www.coi.cz',
      commonScamsTargetingImmigrants: [
        'Unlicensed lenders (often online) offering "quick loans without checks" at extreme interest rates',
        'Fake recruitment agencies for factory work charging CZK 10,000-50,000 upfront',
        'Sim-swap and phone scams targeting Ukrainian refugees (pretending to be Czech authorities)',
        'Rental scams on Bezrealitky.cz or Facebook — paying deposits for nonexistent flats',
        'Fake notary/translation services charging excessive fees',
        '"Fast-track" residence permit services (all permits must go through OAMP directly)',
      ],
      scamPreventionTips: [
        'Only use ČNB-licensed credit providers — check at cnb.cz/en/supervision-financial-market/lists-registers/',
        'Legitimate employers never charge recruitment fees — this is illegal in Czechia',
        'Verify rental listings by checking property records at katastr.cuzk.cz',
        'OAMP does not use intermediaries — apply directly at the ministry',
        'Report to police (158) and consumer protection (ČOI) immediately',
      ],
      legalBasis:
          'Act on Payment System 370/2017, Consumer Credit Act 257/2016, Insolvency Act 182/2006, Act on ČNB, Consumer Protection Act 634/1992, AML Act 253/2008.',
      financialOmbudsman:
          'Financial Arbitrator (Finanční arbitr). Website: www.finarbitr.cz. Tel: +420 257 042 070. Free, decisions are binding on financial institutions.',
      immigrantSpecificNotes:
          'Large Ukrainian refugee community since 2022 — many banks created simplified procedures. OPU (Organizace pro pomoc uprchlíkům) provides free financial and legal assistance. InBáze and IOM Czech Republic offer integration programs including financial literacy. Fio banka is widely recommended by immigrant organizations for its zero-fee accounts.',
    ),

    // ===================================================================
    // DENMARK
    // ===================================================================
    'DK': const FinancialAccessInfo(
      country: 'Denmark',
      countryCode: 'DK',
      basicAccountRight: true,
      basicAccountDirectiveStatus:
          'Transposed via Lov om betalingskonti (Payment Accounts Act) 2016. All legal residents entitled to basic payment account (basiskonto). Banks cannot refuse without justified AML/CTF reasons.',
      documentsForBankAccount: [
        'Valid passport or national ID',
        'CPR number (Civil Personal Registration number) — essential',
        'Danish address registration (from Borgerservice)',
        'For asylum seekers: Documentation from Udlændingestyrelsen + temporary CPR',
        'For recognized refugees: Opholdstilladelse (residence permit) + CPR number',
        'NemID/MitID digital identity (needed for online banking)',
      ],
      banksForAsylumSeekers: [
        'Danske Bank — accepts asylum seeker documentation for basic accounts',
        'Jyske Bank — has opened accounts for asylum seekers with temporary CPR',
        'Nykredit — accepts diverse documentation for basic services',
      ],
      banksForUndocumented: [
        'Extremely difficult. Danish banks require CPR number, which requires legal residence.',
        'Danish Red Cross assists residents of asylum centers with financial needs.',
        'Prepaid Visa/Mastercard cards available at some retailers without CPR.',
      ],
      bestBanksForImmigrants: [
        'Danske Bank — largest bank, English service, strong mobile app, international experience',
        'Nordea Denmark — large Nordic bank, English support, competitive fees',
        'Lunar — Danish digital bank, English interface, easy setup with CPR',
        'N26 — German IBAN but works in Denmark, fully English, no branch needed',
        'Revolut — popular among expats, multi-currency, no Danish CPR required to start',
        'Wise — multi-currency account, great for non-DKK remittances',
      ],
      bankAccountNotes:
          'Denmark uses DKK (Danish krone), pegged to EUR. CPR number is ESSENTIAL — without it, banking is nearly impossible. Get CPR immediately upon arrival by registering at Borgerservice (citizen service center). MitID (replaced NemID in 2022-2023) digital identity required for online banking and all digital government services. Expect 1-2 weeks to set up full banking after CPR issuance.',
      moneyTransferServices: [
        'Wise — online/app, excellent DKK rates',
        'Western Union — at Forex Bank locations and agents',
        'MoneyGram — agent locations',
        'Remitly — online/app',
        'MobilePay — Danish mobile payment (works between Danish bank accounts)',
      ],
      cheapestRemittanceOptions:
          'Wise for most corridors (0.4-1.2% total). For Somali/Arabic-speaking countries, Dahabshiil has offices in Copenhagen. MobilePay is free for person-to-person within Denmark. SEPA transfers to/from EU are cheap despite DKK (banks handle conversion).',
      taxIdName: 'CPR number also serves as tax identification',
      taxIdHowToGet:
          'Automatically issued when you register address at Borgerservice (International Citizen Service in major cities). Bring passport, residence/work permit, rental contract. Processing: same day to 2 weeks. CPR is your universal Danish ID for tax, health, banking, everything.',
      socialSecurityNumber: 'CPR number (same number for everything in Denmark)',
      socialSecurityHowToGet:
          'Same as above — CPR issued at Borgerservice upon address registration. All social security, healthcare, and tax linked to CPR. International Citizen Service (ICS) in Copenhagen, Aarhus, Odense assists foreigners.',
      taxObligationsForImmigrants:
          'Residents taxed on worldwide income. Denmark has the highest tax rates in the EU. Marginal rates: approximately 37-52% (including municipal tax, labor market contribution 8%, state tax). AM-bidrag (labor market contribution) 8% off gross salary. Annual tax assessment (årsopgørelse) by March. Special expat tax scheme: flat 27% for qualifying foreign researchers/key employees for up to 7 years.',
      taxFilingDeadline: 'Tax assessment (årsopgørelse) ready by March. Corrections due May 1. Extended return (udvidet selvangivelse) due July 1.',
      taxAuthorityWebsite: 'https://www.skat.dk',
      taxAuthorityPhone: '+45 72 22 18 18',
      consumerCreditRights:
          'EU Consumer Credit Directive transposed. Danish Financial Supervisory Authority (Finanstilsynet) oversees. Credit scoring via RKI (Ribers Kredit Information) and Experian. 14-day withdrawal. ÅOP (APR) must be stated. Strong responsible lending requirements.',
      creditHistoryBuilding:
          'RKI (part of Experian) maintains negative credit registry. No positive credit scoring system like US/UK. Having no RKI marks is "good credit." Banks assess based on income, employment stability, and account history. After 6-12 months of CPR + steady income + clean bank history, credit products become accessible.',
      debtProtectionLaws:
          'Gældssanering (debt restructuring) via courts — debts can be partially discharged after demonstrating inability to pay. Trangsbeneficium: essential personal items and minimum living standard protected from seizure. Fogedretten (bailiff court) handles enforcement with debtor protections.',
      overIndebtednessHelp:
          'Free debt counseling: Gældsrådgivning at local municipalities. Center for Frivilligt Socialt Arbejde coordinates volunteer debt advisors. Den Sociale Retshjælp provides free legal aid for financial matters.',
      fraudProtectionAuthority: 'Finanstilsynet (Danish Financial Supervisory Authority) / Forbrugerombudsmanden (Consumer Ombudsman)',
      fraudReportingPhone: '+45 33 55 82 82 (Finanstilsynet)',
      fraudReportingWebsite: 'https://www.finanstilsynet.dk / https://www.forbrugerombudsmanden.dk',
      commonScamsTargetingImmigrants: [
        'Fake MitID/NemID phishing (SMS/email claiming bank needs verification)',
        'Fake CPR registration services charging for free government service',
        'MobilePay scams (fake sellers on DBA.dk requesting MobilePay payment, then disappearing)',
        'Rental scams on boligportal.dk and Facebook groups — deposits for non-existent apartments',
        'Fake job offers requiring purchase of equipment or "training materials" upfront',
        'Hawala operators in immigrant communities failing to complete transfers',
      ],
      scamPreventionTips: [
        'CPR registration is FREE at Borgerservice/ICS — never pay anyone for it',
        'Banks NEVER ask for MitID/NemID codes via SMS, email, or phone',
        'Always view apartments in person before paying — use boligportal.dk escrow if available',
        'Check company registration at CVR (virk.dk) before accepting job offers',
        'Use only Finanstilsynet-licensed financial services — check at finanstilsynet.dk',
        'Report fraud to police (114) and Forbrugerombudsmanden',
      ],
      legalBasis:
          'Payment Accounts Act (Lov om betalingskonti), Financial Business Act (Lov om finansiel virksomhed), Credit Agreements Act, Consumer Protection Act, Insolvency Act, AML Act.',
      financialOmbudsman:
          'Det Finansielle Ankenævn (Danish Financial Complaints Board). Website: www.LFanke.dk. Tel: +45 35 43 63 33. Free for consumers. Also: Pengeinstitutankenævnet for banking complaints.',
      immigrantSpecificNotes:
          'Denmark has a well-integrated digital society — CPR and MitID are gateways to everything. International Citizen Service (ICS) is a one-stop shop for immigrants in Copenhagen, Aarhus, Aalborg, Odense. Dansk Flygtningehjælp (Danish Refugee Council) provides integration assistance. For Somali community: Dahabshiil money transfer has physical offices. Special expat tax scheme (forskerskatteordningen) at 27% flat rate is very attractive for qualified workers.',
    ),

    // ===================================================================
    // ESTONIA
    // ===================================================================
    'EE': const FinancialAccessInfo(
      country: 'Estonia',
      countryCode: 'EE',
      basicAccountRight: true,
      basicAccountDirectiveStatus:
          'Transposed via Payment Institutions and E-Money Institutions Act (amendments 2016). Legal residents entitled to basic payment account. Estonia has one of the most digital banking environments in the EU.',
      documentsForBankAccount: [
        'Valid passport or ID card',
        'Estonian personal identification code (isikukood)',
        'Proof of Estonian address',
        'For asylum seekers: Temporary residence permit or asylum procedure document from PPA',
        'For e-residents: e-Residency digital ID card (note: e-Residency alone may not suffice for personal account)',
      ],
      banksForAsylumSeekers: [
        'Swedbank — largest bank in Estonia, accepts asylum seeker documents',
        'SEB — accepts residence permit holders and asylum seekers for basic accounts',
        'LHV — Estonian digital bank, flexible with documentation',
      ],
      banksForUndocumented: [
        'No access without isikukood. Estonian banking is fully digital and ID-based.',
        'Estonian Refugee Council (Pagulasabi) may assist with emergency solutions.',
      ],
      bestBanksForImmigrants: [
        'LHV — Estonian fintech bank, excellent app, English support, competitive fees',
        'Swedbank — largest bank, wide network, English service, accepts diverse documents',
        'SEB — strong digital banking, English support',
        'Wise — headquartered in Estonia, EUR IBAN, multi-currency, excellent for immigrants',
        'Revolut — popular among Estonian residents, English, EUR IBAN',
      ],
      bankAccountNotes:
          'Estonia is one of the most digitally advanced countries in the EU. Estonian ID card / Mobile-ID / Smart-ID required for digital banking. Get isikukood (personal ID code) from PPA (Police and Border Guard Board). E-Residency does NOT automatically give right to bank account — banks assess individually. LHV and Wise are particularly immigrant-friendly.',
      moneyTransferServices: [
        'Wise — headquartered in Tallinn, best rates',
        'Western Union — at Omniva (Estonian Post) offices',
        'MoneyGram — limited agent locations',
        'Remitly — online/app',
        'Paysend — online/app, popular for CIS country transfers',
      ],
      cheapestRemittanceOptions:
          'Wise (Estonian company) offers best rates globally (0.3-1.5%). For Russia/Ukraine/CIS countries, Paysend is competitive. SEPA transfers between EU banks essentially free. Estonia uses EUR since 2011.',
      taxIdName: 'Isikukood (Personal Identification Code) serves as tax ID',
      taxIdHowToGet:
          'Issued by PPA (Police and Border Guard Board) when registering residence. Apply at PPA service office with passport and residence basis. For EU citizens: register at local government (kohalik omavalitsus). Processing: 1-7 days.',
      socialSecurityNumber: 'Isikukood — same code used for all purposes (tax, social security, healthcare, banking)',
      socialSecurityHowToGet:
          'Issued automatically with residence registration at PPA. All social insurance contributions linked to isikukood through employer declarations to EMTA (Tax and Customs Board).',
      taxObligationsForImmigrants:
          'Flat income tax: 20%. Social tax (employer): 33% (includes pension 20% + health insurance 13%). Employee: funded pension contribution 2%. Residents taxed on worldwide income. Non-residents: only Estonian-source income at 20%. Tax-free amount: EUR 7,848/year (reduced for higher earners). Annual declaration due March 31.',
      taxFilingDeadline: 'March 31 for previous year (electronic via e-MTA).',
      taxAuthorityWebsite: 'https://www.emta.ee',
      taxAuthorityPhone: '+372 880 0811',
      consumerCreditRights:
          'EU Consumer Credit Directive transposed. Finantsinspektsioon (Financial Supervisory Authority) oversees. SECCI mandatory. 14-day withdrawal. Maximum cost of credit rules apply. Responsible lending assessment required. Credit information from payment default registries.',
      creditHistoryBuilding:
          'Estonia has no centralized positive credit bureau like Germany or UK. Banks maintain internal records and share negative data. Build credit by: maintaining clean bank account (no overdraft defaults), paying bills on time, getting a small credit card after 6-12 months of employment. Estonian banks are relatively open to lending to employed immigrants.',
      debtProtectionLaws:
          'Debt Restructuring and Debt Protection Act (võlgade ümberkujundamise ja võlakaitse seadus). Court-supervised restructuring plan up to 5 years. Minimum protected income in enforcement proceedings. Bailiff (kohtutäitur) enforcement limited by debtor protection provisions. Personal bankruptcy possible as last resort.',
      overIndebtednessHelp:
          'Free legal aid via Riigi Õigusabi (state legal aid) for qualifying individuals. Eesti Võlanõustajate Liit (Estonian Debt Counselors Association) provides advice. Local government social departments assist with financial difficulties.',
      fraudProtectionAuthority: 'Finantsinspektsioon (Financial Supervisory Authority)',
      fraudReportingPhone: '+372 668 0500 (Finantsinspektsioon)',
      fraudReportingWebsite: 'https://www.fi.ee',
      commonScamsTargetingImmigrants: [
        'Fake e-Residency "bank account guarantee" services (e-Residency does NOT guarantee bank account)',
        'Phishing emails/SMS impersonating Swedbank or SEB requesting Smart-ID PIN codes',
        'Fake apartment listings on kv.ee or City24 requiring advance deposits',
        'Crypto investment scams (Estonia had many crypto license holders before 2023 crackdown)',
        'Fake IT job offers requiring purchase of equipment',
        'Romance scams targeting immigrants through dating apps',
      ],
      scamPreventionTips: [
        'Banks NEVER request PIN codes via SMS, email, or phone call',
        'Verify financial service licenses at fi.ee/en/supervised-entities',
        'Check company registration at e-Business Register (ariregister.rik.ee)',
        'e-Residency official site is e-resident.gov.ee — not third-party sites',
        'View apartments in person before paying deposits',
        'Report to police (112) and Finantsinspektsioon',
      ],
      legalBasis:
          'Payment Institutions and E-Money Institutions Act, Credit Institutions Act, Consumer Protection Act, Debt Restructuring Act, AML/CFT Act.',
      financialOmbudsman:
          'No dedicated financial ombudsman. Complaints handled by Finantsinspektsioon. Consumer disputes via Tarbijakaitse ja Tehnilise Järelevalve Amet (Consumer Protection Authority). Court-annexed mediation available.',
      immigrantSpecificNotes:
          'Estonia is the most digital society in the EU — nearly everything is done online via ID card / Smart-ID. Get digital identity set up ASAP. Wise is an Estonian company and is the easiest banking solution for newcomers. Estonian Refugee Council (Pagulasabi) provides integration support. IOM Estonia assists with financial orientation. Russian language widely understood, which helps Russian-speaking immigrants.',
    ),

    // ===================================================================
    // FINLAND
    // ===================================================================
    'FI': const FinancialAccessInfo(
      country: 'Finland',
      countryCode: 'FI',
      basicAccountRight: true,
      basicAccountDirectiveStatus:
          'Transposed via Payment Services Act (Maksupalvelulaki 290/2010, amended 2017). All legal residents entitled to basic payment account (perusmaksutili). Banks cannot refuse without specific AML grounds. Complainable to Financial Supervisory Authority (Finanssivalvonta).',
      documentsForBankAccount: [
        'Valid passport or national ID card',
        'Finnish personal identity code (henkilötunnus)',
        'Proof of address in Finland',
        'For asylum seekers: Alien registration card or Migri asylum document + temporary henkilötunnus',
        'For recognized refugees: Residence permit card (oleskelulupa) + henkilötunnus',
        'For EU citizens: Registration certificate from Migri + henkilötunnus from DVV',
      ],
      banksForAsylumSeekers: [
        'OP Financial Group — accepts asylum seeker documentation for basic accounts',
        'Nordea — opens basic accounts for asylum seekers with Migri documents',
        'S-Pankki — accessible through S-Group stores, accepts diverse documents',
        'Danske Bank Finland — has served asylum seekers',
      ],
      banksForUndocumented: [
        'Very limited. Finnish banks require henkilötunnus for all accounts.',
        'Finnish Red Cross assists residents of reception centers.',
        'Prepaid cards (gift cards) available at R-Kioski and K-market without ID.',
      ],
      bestBanksForImmigrants: [
        'OP Financial Group — largest bank, English service, good basic account terms, wide branch network',
        'Nordea Finland — large Nordic bank, English app, international experience',
        'S-Pankki — free basic account, accessible at S-Group stores, no minimum balance',
        'N26 — German IBAN, fully English, no branch visit needed',
        'Revolut — popular among immigrants, English, EUR IBAN, no branch needed',
        'Wise — EUR IBAN, multi-currency, excellent for remittances',
        'Holvi — Finnish fintech, English, good for self-employed immigrants',
      ],
      bankAccountNotes:
          'Finnish henkilötunnus (personal identity code) is ESSENTIAL for banking. Get it from DVV (Digital and Population Data Services Agency) or Maistraatti. Without it, only very limited banking is possible. Strong online banking authentication system (bank IDs used for all government e-services). S-Pankki offers genuinely free basic banking.',
      moneyTransferServices: [
        'Wise — online/app, excellent rates',
        'Western Union — at R-Kioski locations and Forex Bank',
        'MoneyGram — limited agent locations',
        'Remitly — online/app',
        'Paysend — online/app',
        'Ria — agents in Helsinki',
      ],
      cheapestRemittanceOptions:
          'Wise best for most corridors (0.3-1.5%). For Somalia (large Somali community in Finland), Dahabshiil has offices in Helsinki. SEPA transfers between EUR accounts essentially free. MobilePay works for domestic person-to-person.',
      taxIdName: 'Henkilötunnus (Personal Identity Code) serves as tax identifier',
      taxIdHowToGet:
          'Apply at DVV (Digi- ja väestötietovirasto) local service point with passport and residence basis. EU citizens: register at DVV after 3 months. Non-EU: Migri issues residence permit, then register at DVV. Tax office (Vero) uses henkilötunnus. Processing at DVV: same day to 2 weeks.',
      socialSecurityNumber: 'Henkilötunnus — same code for everything (Kela social insurance, tax, healthcare)',
      socialSecurityHowToGet:
          'Issued by DVV upon residence registration. Kela (Social Insurance Institution) enrollment separate — apply at Kela office or kela.fi with residence permit. Kela card gives access to Finnish social security (healthcare, housing allowance, etc.).',
      taxObligationsForImmigrants:
          'Residents (183+ days or permanent home) taxed on worldwide income. Progressive state income tax: 12.64%-44% plus municipal tax (approximately 17-23% depending on municipality) plus church tax (1-2.2% if member). Total marginal rate can exceed 55% for high earners. Employment income taxed at source (verokortti tax card). Annual pre-filled tax return reviewed in spring.',
      taxFilingDeadline: 'Pre-filled tax return sent by Vero in March/April. Review and corrections due by mid-May (exact date varies). First-year immigrants must request tax card (verokortti) from Vero before starting work.',
      taxAuthorityWebsite: 'https://www.vero.fi',
      taxAuthorityPhone: '+358 29 497 000',
      consumerCreditRights:
          'EU Consumer Credit Directive transposed. FIN-FSA (Finanssivalvonta) supervises. Suomen Asiakastieto Oy is the main credit reference agency. SECCI mandatory. 14-day withdrawal. Interest rate cap on consumer credit (20% + ECB reference rate). Responsible lending requirements strict.',
      creditHistoryBuilding:
          'Suomen Asiakastieto (now part of Enento Group) maintains credit registry. Positive data (credit usage) and negative data (defaults) both recorded. New immigrants start with no file. Steps: get henkilötunnus, open bank account, register at Vero, get employment, after 6-12 months of salary deposits request credit card. Finnish banks are cautious but fair — stable employment is key.',
      debtProtectionLaws:
          'Debt adjustment for private individuals (Yksityishenkilön velkajärjestely, Act 57/1993). Court-supervised payment plan typically 3-5 years, then discharge. Ulosotto (enforcement) protects minimum income — suojaosuus (protected portion) approximately EUR 22.41/day for debtor + EUR 8.04 per dependent. Cannot seize essential household items.',
      overIndebtednessHelp:
          'Free debt counseling: Talous- ja velkaneuvonta (Financial and Debt Counseling) available in every municipality — mandated by law. Contact via oikeus.fi or your local municipality. Takuusäätiö (Guarantee Foundation) provides guarantee for debt restructuring loans. Legal aid (oikeusapu) available for low-income residents.',
      fraudProtectionAuthority: 'Finanssivalvonta (FIN-FSA) / KKV (Finnish Competition and Consumer Authority)',
      fraudReportingPhone: '+358 29 505 0500 (FIN-FSA) / +358 29 505 3000 (KKV)',
      fraudReportingWebsite: 'https://www.finanssivalvonta.fi / https://www.kkv.fi',
      commonScamsTargetingImmigrants: [
        'Phishing SMS/email pretending to be from OP, Nordea, or Posti (Finnish Post) requesting login credentials',
        'Fake Kela/DVV websites requesting henkilötunnus and bank details',
        'Rental scams on tori.fi and Facebook — deposits for non-existent apartments, especially in Helsinki area',
        'Fake job offers requiring purchase of "work equipment" or "certification fees"',
        'Investment/crypto scams in immigrant Telegram/WhatsApp groups',
        'Unlicensed money lenders in immigrant communities (especially targeting those without bank access)',
        'Fake Migri/police calls claiming problems with residence permit requiring immediate payment',
      ],
      scamPreventionTips: [
        'Banks and Kela NEVER request login credentials or bank IDs via phone, SMS, or email',
        'Henkilötunnus is sensitive — do not share it unnecessarily (it cannot be changed if compromised)',
        'Always view apartments in person before paying. Use vuokraovi.com or official channels.',
        'Check financial service licenses at finanssivalvonta.fi/en/registers',
        'Migri and police never demand payments by phone or messaging apps',
        'Report to police (112/poliisi.fi online report) and KKV consumer advice (+358 29 505 3050)',
      ],
      legalBasis:
          'Payment Services Act 290/2010, Credit Institution Act 610/2014, Consumer Protection Act 38/1978, Act on Debt Adjustment for Private Individuals 57/1993, AML Act 444/2017.',
      financialOmbudsman:
          'FINE (Finnish Financial Ombudsman Bureau). Website: www.fine.fi. Tel: +358 9 685 0120. Free dispute resolution for banking, insurance, and investment complaints.',
      immigrantSpecificNotes:
          'Finland has a strong social safety net accessible via Kela. Register with Kela immediately after getting henkilötunnus — eligible for housing allowance (asumistuki), basic social assistance (toimeentulotuki), and healthcare. Finnish Refugee Council (Suomen Pakolaisapu) provides integration support. Infopankki.fi is the official multilingual information portal for immigrants covering financial topics. STTK and SAK trade unions offer immigrant worker support including financial rights.',
    ),

    // ===================================================================
    // FRANCE
    // ===================================================================
    'FR': const FinancialAccessInfo(
      country: 'France',
      countryCode: 'FR',
      basicAccountRight: true,
      basicAccountDirectiveStatus:
          'France had basic account rights BEFORE the EU directive — Droit au Compte since 1984 (Loi bancaire, Article L312-1 Code monétaire et financier). Anyone residing in France or French national, including undocumented persons, can request a basic account. If a bank refuses, Banque de France designates a bank within 1 business day.',
      documentsForBankAccount: [
        'Valid passport or national ID (or expired ID if no other available)',
        'Proof of address (justificatif de domicile): utility bill, attestation d\'hébergement, or domiciliation by a social organization',
        'For asylum seekers: Attestation de demande d\'asile (ATDA)',
        'For undocumented: Droit au Compte procedure via Banque de France requires only an ID document (passport, even expired) + proof of address or domiciliation certificate from an association',
        'For recognized refugees: Récépissé or titre de séjour + proof of address',
      ],
      banksForAsylumSeekers: [
        'La Banque Postale — most accessible, present in every post office, accepts ATDA',
        'Crédit Mutuel — cooperative bank, often immigrant-friendly',
        'Banque de France procedure — if any bank refuses, Banque de France designates one within 1 day',
        'Crédit Agricole — large network, regional variations but generally accepts asylum documents',
      ],
      banksForUndocumented: [
        'La Banque Postale — most accessible for undocumented persons via Droit au Compte',
        'Any bank designated by Banque de France through Droit au Compte procedure',
        'Requires only: passport (even expired) + domiciliation certificate from social association (CCAS, CIAS, association agréée)',
        'Associations like Secours Catholique, Médecins du Monde can provide domiciliation',
      ],
      bestBanksForImmigrants: [
        'La Banque Postale — post office bank, most accessible, 17,000 points of contact, accepts all legal statuses',
        'Boursorama Banque — best free online bank, English support, part of Société Générale',
        'Crédit Mutuel — cooperative model, locally invested, immigrant-friendly in many regions',
        'N26 — fully digital, English interface, French IBAN, no branch needed',
        'Wise — multi-currency, French IBAN available, excellent for remittances',
        'Nickel — account opened at tabac (tobacco shop) in 5 minutes with just passport, from EUR 20/year',
      ],
      bankAccountNotes:
          'France has the STRONGEST basic account protection in the EU. Droit au Compte (Right to Account) guarantees everyone a bank account — including undocumented persons and the homeless (with domiciliation). If refused, file form at any Banque de France branch — they designate a bank within 1 business day. The designated bank MUST open the account. Nickel is excellent for quick access — opened at any tabac shop with just a passport.',
      moneyTransferServices: [
        'Wise — online/app, French IBAN',
        'Western Union — thousands of agents, available at La Banque Postale',
        'MoneyGram — agent locations throughout France',
        'Remitly — online/app',
        'WorldRemit — online/app',
        'Ria — agents in major cities',
        'Orange Money — for transfers to West Africa',
        'Wave — for West Africa transfers (very competitive rates)',
      ],
      cheapestRemittanceOptions:
          'Wise for bank transfers (0.3-1.5%). For West Africa (large diaspora), Wave is revolutionary: near-zero fees to Senegal, Côte d\'Ivoire, Mali, etc. Orange Money competitive for CFA zone. For Maghreb (Morocco, Tunisia, Algeria), Ria and Western Union have price wars — compare on monito.com.',
      taxIdName: 'Numéro fiscal (tax number) / Numéro de Sécurité Sociale (NIR)',
      taxIdHowToGet:
          'Numéro fiscal: assigned automatically when you first file taxes or are declared by an employer. Contact your local centre des finances publiques with passport + proof of address if not automatically assigned. Can also create account on impots.gouv.fr.',
      socialSecurityNumber: 'NIR (Numéro d\'Inscription au Répertoire) — 13-digit number',
      socialSecurityHowToGet:
          'Employer requests it from CPAM (Caisse Primaire d\'Assurance Maladie) when hiring. Self-employed: register via URSSAF autoentrepreneur portal. Asylum seekers receive temporary number via CPAM. Apply at CPAM with titre de séjour + passport + proof of address. Processing: 2-8 weeks.',
      taxObligationsForImmigrants:
          'Residents (foyer fiscal in France) taxed on worldwide income. Progressive rates: 0% up to EUR 11,294, then 11%-45%. Family quotient system (quotient familial) reduces tax for families. Social contributions (CSG/CRDS): 9.7% on employment income. Annual declaration mandatory even if no income. Prélèvement à la source (withholding at source) since 2019.',
      taxFilingDeadline: 'May-June depending on department (exact date varies). Electronic filing on impots.gouv.fr mandatory for residents with internet access.',
      taxAuthorityWebsite: 'https://www.impots.gouv.fr',
      taxAuthorityPhone: '0 809 401 401 (non-surtaxed)',
      consumerCreditRights:
          'Strong consumer credit protection. Fichier national des Incidents de remboursement des Crédits aux Particuliers (FICP) at Banque de France records defaults. SECCI mandatory. 14-day withdrawal (7 days for real estate). Usury rate (taux d\'usure) caps maximum interest. Loi Lagarde (2010) strengthened borrower protections.',
      creditHistoryBuilding:
          'France has no positive credit scoring like US/UK. FICP only records NEGATIVE events (defaults). Having no FICP record is "clean." Banks assess credit based on: stable employment (CDI contract preferred), debt-to-income ratio (<33% rule), and bank account history. After 12+ months of CDI employment and clean bank history, consumer credit accessible.',
      debtProtectionLaws:
          'Surendettement (over-indebtedness) procedure via Banque de France. Commission de surendettement reviews case, can impose: payment moratorium (up to 2 years), reduced interest, extended repayment, or total debt discharge (effacement). RSA (Revenu de solidarité active) and minimum living amounts protected. Procédure de rétablissement personnel (personal recovery) for hopeless situations — total discharge.',
      overIndebtednessHelp:
          'Banque de France surendettement commission — free, file at any BdF branch. CRÉSUS federation — national network of free debt counseling associations. CCAS (local social action centers) — financial assistance. ADIL (housing information) for rent-related debt. CIDFF (women\'s rights centers) for immigrant women facing financial difficulties.',
      fraudProtectionAuthority: 'ACPR (Autorité de Contrôle Prudentiel et de Résolution) / DGCCRF (Consumer Protection)',
      fraudReportingPhone: '0 805 805 817 (Info Escroqueries — free fraud hotline)',
      fraudReportingWebsite: 'https://www.internet-signalement.gouv.fr (PHAROS) / https://www.signal.conso.gouv.fr',
      commonScamsTargetingImmigrants: [
        'Fake CAF (family benefits) emails/SMS requesting bank details for "allocation payments"',
        'Fraudulent immigration lawyers (avocats) demanding EUR 2,000-10,000 for services available via aide juridictionnelle (free legal aid)',
        'Fake CPAM communications requesting carte vitale update with personal data',
        'Apartment scams on leboncoin.fr and Facebook — advance rent/deposit for non-existent apartments, especially in Paris/Île-de-France',
        'Informal money transfer operators (especially for West Africa) who fail to deliver',
        'Pyramid/Ponzi schemes in diaspora communities (often via WhatsApp/Telegram)',
        'Fake job offers (especially for sans-papiers) that are actually trafficking/exploitation',
        '"Fast-track regularization" scams promising titre de séjour for a fee',
      ],
      scamPreventionTips: [
        'French government services (CAF, CPAM, Impots, Préfecture) NEVER request bank details by email/SMS',
        'Aide juridictionnelle (free legal aid) is available to all low-income residents — no need to pay expensive lawyers',
        'Never pay deposits for apartments without visiting and signing a bail (lease agreement)',
        'Check lawyer registration at annuaire.justice.gouv.fr or your local Barreau',
        'Verify financial service providers at ACPR/AMF registries: regafi.fr',
        'Report fraud to police (17) or file online at service-public.fr (pré-plainte en ligne)',
        'For internet scams: PHAROS platform at internet-signalement.gouv.fr',
      ],
      legalBasis:
          'Code monétaire et financier (L312-1 Droit au Compte), Code de la consommation, Loi Lagarde 2010, Loi Hamon 2014, Code de procédure civile (surendettement), AML framework (transposed EU directives).',
      financialOmbudsman:
          'Médiateur de la banque (each bank has one, mandatory first step). Then: Médiateur de l\'AMF (investment), Médiateur de l\'ACPR (banking/insurance). All free. Response within 90 days.',
      immigrantSpecificNotes:
          'France offers the strongest banking access rights for immigrants in the EU — including undocumented persons. Droit au Compte is powerful: USE IT if refused. La Cimade, GISTI, and France Terre d\'Asile NGOs provide free assistance with financial access. Nickel bank accounts (at tabac shops) are game-changers for quick access. CAF benefits (APL housing aid, RSA) accessible to most legal residents. Prefecture Accueil services help with administrative integration including banking.',
    ),

    // ===================================================================
    // GERMANY
    // ===================================================================
    'DE': const FinancialAccessInfo(
      country: 'Germany',
      countryCode: 'DE',
      basicAccountRight: true,
      basicAccountDirectiveStatus:
          'Transposed via Zahlungskontengesetz (ZKG, Payment Accounts Act) 2016. Everyone legally residing in the EU — including asylum seekers, tolerated persons (Duldung), and homeless — entitled to a Basiskonto. Banks can charge "reasonable" fees (BaFin monitors). If refused, complaint to BaFin.',
      documentsForBankAccount: [
        'Valid passport or national ID card',
        'Anmeldung (address registration from Einwohnermeldeamt/Bürgeramt)',
        'For asylum seekers: Aufenthaltsgestattung (permission to reside) or Ankunftsnachweis',
        'For tolerated persons: Duldung (toleration document)',
        'For recognized refugees: Aufenthaltstitel (residence title)',
        'For homeless: Basiskonto can be opened without Anmeldung — bank cannot require proof of address for Basiskonto under ZKG',
      ],
      banksForAsylumSeekers: [
        'Sparkasse (savings banks) — legally obligated to serve all residents in their region, most reliable for asylum seekers',
        'Deutsche Bank — accepts Aufenthaltsgestattung and Duldung for Basiskonto',
        'Commerzbank — Basiskonto available to asylum seekers',
        'Postbank — accessible at post offices, accepts asylum documents',
        'Volksbank/Raiffeisenbank — cooperative banks, regional availability, generally open to asylum seekers',
      ],
      banksForUndocumented: [
        'Basiskonto is legally available to all "legally residing in EU" — but undocumented status is the grey zone.',
        'Sparkasse may open Basiskonto with any valid ID document (passport from any country) under ZKG.',
        'In practice: difficult. Some branches interpret ZKG broadly, others narrowly.',
        'Diakonie, Caritas, and local Flüchtlingsrat may advocate on behalf of undocumented persons.',
        'Prepaid cards (Paysafecard at kiosks) available without ID for small amounts.',
      ],
      bestBanksForImmigrants: [
        'Sparkasse — legally obligated to serve local community, widest branch/ATM network, Basiskonto guaranteed',
        'N26 — fully digital German bank, English app, German IBAN, no branch visit, fast setup with video verification',
        'DKB (Deutsche Kreditbank) — free Girokonto, English interface, online-only, good for expats',
        'Commerzbank — free basic Girokonto, English support in major cities',
        'Wise — multi-currency, German IBAN, excellent for remittances',
        'Revolut — popular among immigrants, English, German IBAN available',
        'ING Germany — free Girokonto with salary deposit, English support',
      ],
      bankAccountNotes:
          'Germany has strong Basiskonto rights under ZKG. If any bank refuses, file a complaint with BaFin (takes 3-4 weeks, bank must respond). Sparkassen are the most reliable option as they have a public mandate. Anmeldung (address registration) should be done within 2 weeks of moving — this is required for most bank accounts except Basiskonto. N26 is excellent for fast English-language setup. SCHUFA credit score system is important — understand it early.',
      moneyTransferServices: [
        'Wise — online/app, German IBAN',
        'Western Union — at Postbank/post offices and agent locations',
        'MoneyGram — agent locations',
        'Remitly — online/app',
        'WorldRemit — online/app',
        'Azimo — online/app, popular for Eastern Europe/Turkey',
        'Ria — agents in major cities',
      ],
      cheapestRemittanceOptions:
          'Wise for most corridors (0.3-1.5%). For Turkey, Azimo and Wise compete on rates. For Syria/Iraq (large communities), Western Union and MoneyGram have widest cash pickup networks but charge 3-7% — compare carefully. SEPA transfers within EU free at most German banks.',
      taxIdName: 'Steueridentifikationsnummer (Steuer-ID, 11 digits) and Steuernummer (local tax number)',
      taxIdHowToGet:
          'Steuer-ID: automatically assigned by BZSt (Bundeszentralamt für Steuern) and mailed to your registered address within 2-4 weeks of Anmeldung. If not received, request at your local Finanzamt with passport + Anmeldung. Steuernummer: assigned by local Finanzamt when you file your first tax return.',
      socialSecurityNumber: 'Sozialversicherungsnummer (SV-Nummer, 12 characters)',
      socialSecurityHowToGet:
          'Automatically assigned by Deutsche Rentenversicherung when you first start employment. Your employer requests it. Printed on your Sozialversicherungsausweis. If self-employed, register directly at Deutsche Rentenversicherung. Health insurance (gesetzliche Krankenversicherung) enrollment handled separately through a Krankenkasse.',
      taxObligationsForImmigrants:
          'Residents (183+ days or habitual abode) taxed on worldwide income. Progressive rates: 0% up to EUR 11,604, then 14%-45% (Reichensteuer 45% above EUR 277,826). Solidaritätszuschlag: 5.5% surcharge for high earners. Church tax: 8-9% of income tax (if church member). Annual declaration (Steuererklärung) mandatory for self-employed, optional but often beneficial for employees.',
      taxFilingDeadline: 'July 31 of following year (September 30 if using Steuerberater). Electronic via ELSTER.',
      taxAuthorityWebsite: 'https://www.bzst.de / https://www.elster.de',
      taxAuthorityPhone: '+49 228 406 1240 (BZSt) / local Finanzamt',
      consumerCreditRights:
          'Strong consumer protection. SCHUFA is the dominant credit bureau (Bonitätsauskunft). EU Consumer Credit Directive transposed via BGB and VkrRL. SECCI mandatory. 14-day withdrawal. BaFin supervises. APR (effektiver Jahreszins) must be clearly stated. Widerrufsrecht (right of withdrawal) strongly enforced.',
      creditHistoryBuilding:
          'SCHUFA (Schutzgemeinschaft für allgemeine Kreditsicherung) is Germany\'s main credit bureau. New immigrants start with no SCHUFA score — which itself can be an obstacle. Steps: 1) Open bank account (this starts your SCHUFA file), 2) Register a postpaid mobile contract, 3) Pay bills on time, 4) After 6-12 months request SCHUFA Selbstauskunft (free annual report at meineschufa.de). SCHUFA score 95+ is considered good. Never miss payments — German system is unforgiving. Avoid multiple bank/credit inquiries in short time.',
      debtProtectionLaws:
          'Privatinsolvenz (personal insolvency) under InsO (Insolvenzordnung). Restschuldbefreiung (debt discharge) after 3 years of good conduct (reduced from 6 years in 2020). Pfändungsschutzkonto (P-Konto): bank account with protected balance — currently EUR 1,402.28/month protected from seizure. Lohnpfändung limited by Pfändungstabelle. Essential items (Unpfändbare Sachen) cannot be seized.',
      overIndebtednessHelp:
          'Free debt counseling (Schuldnerberatung): available through Caritas, Diakonie, AWO, DRK, and municipal services in every city. Verbraucherzentrale (consumer center) in each federal state offers debt advice. P-Konto conversion at your bank protects basic income from seizure — request it immediately if facing debt problems.',
      fraudProtectionAuthority: 'BaFin (Bundesanstalt für Finanzdienstleistungsaufsicht)',
      fraudReportingPhone: '+49 228 4108-0 (BaFin) / 110 (police)',
      fraudReportingWebsite: 'https://www.bafin.de',
      commonScamsTargetingImmigrants: [
        'Fake Jobcenter/Finanzamt letters demanding payment or personal data',
        'Phishing emails impersonating Sparkasse, N26, or DKB requesting login credentials',
        'Fake SCHUFA improvement services charging EUR 200-500 (SCHUFA Selbstauskunft is free once/year)',
        'Rental scams (Wohnungsbetrug) — fake landlords on immobilienscout24.de, wg-gesucht.de demanding deposits to foreign accounts, especially in Berlin/Munich',
        'Door-to-door energy/phone contract salespeople signing immigrants into expensive multi-year contracts',
        'Fake lawyer/Notary services for "Aufenthaltstitel acceleration"',
        'Cash-in-hand work arrangements that leave workers without social insurance protection',
        'Romance scams and "inheritance" scams targeting immigrant communities',
      ],
      scamPreventionTips: [
        'Finanzamt and Jobcenter NEVER demand payments by email, phone, or letter without prior official Bescheid',
        'SCHUFA Selbstauskunft is free once per year at meineschufa.de — never pay for "credit repair"',
        'Never sign contracts (Verträge) you do not fully understand — 14-day Widerrufsrecht applies to most contracts',
        'Verify bank/financial service licenses at bafin.de/EN/Supervision/BanksFinancialServicesProviders',
        'Never transfer apartment deposits without viewing the apartment and meeting the landlord in person',
        'Verbraucherzentrale offers contract review services in multiple languages',
        'Report scams to police (110) and BaFin. Online: onlinewache of your Bundesland police',
      ],
      legalBasis:
          'Zahlungskontengesetz (ZKG), KWG (Kreditwesengesetz), BGB consumer protection provisions, InsO (Insolvenzordnung), GwG (Geldwäschegesetz), Verbraucherkreditrichtlinie-Umsetzungsgesetz.',
      financialOmbudsman:
          'Ombudsmann der privaten Banken (private banks). Schlichtungsstelle des DSGV (Sparkassen). Kundenbeschwerdestelle des BVR (cooperative banks). All free. BaFin for systemic complaints.',
      immigrantSpecificNotes:
          'Germany has the largest immigrant population in the EU. Verbraucherzentrale provides multi-language consumer advice (Arabic, Turkish, Russian, English) in many cities. AWO, Caritas, Diakonie provide free Schuldnerberatung accessible to immigrants. P-Konto is crucial protection if you face debt — convert your account immediately. Understanding SCHUFA is essential for life in Germany (renting, credit, phone contracts). Migrationsberatung für Erwachsene (MBE) and JMD (Jugendmigrationsdienste) provide free integration counseling including financial topics.',
    ),

    // ===================================================================
    // GREECE
    // ===================================================================
    'GR': const FinancialAccessInfo(
      country: 'Greece',
      countryCode: 'GR',
      basicAccountRight: true,
      basicAccountDirectiveStatus:
          'Transposed via Law 4465/2017. Legal residents entitled to basic payment account (βασικός λογαριασμός πληρωμών). Bank of Greece oversees compliance. Max cost set by ministerial decision.',
      documentsForBankAccount: [
        'Valid passport or national ID',
        'AFM (tax registration number)',
        'Proof of address (utility bill or rental contract)',
        'For asylum seekers: Asylum applicant card (Δελτίο αιτήσαντος διεθνή προστασία)',
        'For recognized refugees: Residence permit + AFM',
        'AMKA (social security number) — some banks require this',
      ],
      banksForAsylumSeekers: [
        'National Bank of Greece — accepts asylum applicant cards for basic accounts',
        'Piraeus Bank — has served asylum seekers, especially through UNHCR-facilitated programs',
        'Alpha Bank — basic accounts for asylum seekers with valid asylum card',
        'Eurobank — accepts asylum documentation',
      ],
      banksForUndocumented: [
        'Very limited. Greek banks require AFM (tax number) which requires legal presence.',
        'UNHCR Greece and Greek Council for Refugees can facilitate financial access for persons in procedure.',
        'Cash cards distributed by UNHCR/partner NGOs for basic needs.',
      ],
      bestBanksForImmigrants: [
        'Piraeus Bank — largest bank post-crisis, some English support in Athens, broad document acceptance',
        'National Bank of Greece — historic bank, wide network, tourist-area branches speak English',
        'Revolut — extremely popular in Greece, English, EUR IBAN, no branch needed, instant setup',
        'Wise — EUR IBAN, excellent for remittances, English',
        'N26 — German IBAN but fully functional in Greece, English',
      ],
      bankAccountNotes:
          'Greek banking recovered from the 2010s crisis but remains cautious. AFM (tax number) is essential — get it from the local DOY (tax office). AMKA (social security) also needed for many services. Capital controls from 2015 crisis are fully lifted. Digital banking (Revolut) has exploded in Greece — many immigrants use it as primary. Traditional bank account opening can be slow and bureaucratic.',
      moneyTransferServices: [
        'Wise — online/app',
        'Western Union — at agent locations',
        'MoneyGram — agent locations',
        'Remitly — online/app',
        'Ria — agents in Athens and Thessaloniki',
      ],
      cheapestRemittanceOptions:
          'Wise for most corridors (0.4-1.5%). For Pakistan/Bangladesh/Afghanistan (significant communities in Greece), Western Union has widest reach for cash pickup. For Albania (large community), SEPA bank transfers are cheapest.',
      taxIdName: 'AFM (Αριθμός Φορολογικού Μητρώου — Tax Registration Number)',
      taxIdHowToGet:
          'Apply at the local DOY (Δημόσια Οικονομική Υπηρεσία — tax office) with passport, residence permit/asylum card, and proof of address. For employees: employer can facilitate. Processing: same day to 1 week. AFM is required for virtually everything in Greece (banking, contracts, employment).',
      socialSecurityNumber: 'AMKA (Αριθμός Μητρώου Κοινωνικής Ασφάλισης)',
      socialSecurityHowToGet:
          'Apply at KEP (Citizen Service Centers) or EFKA offices with passport, residence permit, and AFM. Asylum seekers: apply with asylum card at KEP. Processing: same day. PAAYPA (Provisional AMKA) available for asylum seekers since 2020. Required for healthcare and employment.',
      taxObligationsForImmigrants:
          'Residents (183+ days or center of vital interests) taxed on worldwide income. Progressive rates: 9%-44% (employment income). Solidarity surcharge: 2.2%-10% (being phased out). Social contributions: approximately 13.87% employee + 22.29% employer. Self-employed: progressive + social contributions. Annual return due June 30.',
      taxFilingDeadline: 'June 30 for previous year (extensions common). Electronic via TAXISnet (gsis.gr).',
      taxAuthorityWebsite: 'https://www.aade.gr',
      taxAuthorityPhone: '1515 (AADE helpline)',
      consumerCreditRights:
          'EU Consumer Credit Directive transposed. Bank of Greece supervises. Tiresias (ΤΕΙΡΕΣΙΑΣ) credit bureau records defaults. SECCI mandatory. 14-day withdrawal. Kountoura Law (Law 4738/2020) reformed personal insolvency. Strong debtor protections introduced post-financial crisis.',
      creditHistoryBuilding:
          'Tiresias SA operates the credit information system. Records negative data (defaults, bounced checks, court orders). No positive data file. New immigrants start clean. Open bank account with regular income, pay all obligations on time, after 12+ months request small credit products. Greek banks are conservative post-crisis — stable employment essential.',
      debtProtectionLaws:
          'Law 4738/2020 (Debt Settlement and 2nd Chance): comprehensive personal insolvency framework. Primary residence protection under conditions. Court-supervised repayment plan. "Second chance" full discharge after 3 years for good-faith debtors. Protected minimum income (κατώτατο αδέσμευτο) in enforcement. Out-of-court debt settlement mechanism available.',
      overIndebtednessHelp:
          'Free debt counseling: Centers for Debt Mediation (Κέντρα Διαμεσολάβησης) at municipalities. KEPKA (Consumer Protection Center): www.kepka.org. Special secretariat for private debt management. Legal aid (νομική βοήθεια) for low-income residents.',
      fraudProtectionAuthority: 'Bank of Greece / Hellenic Capital Market Commission / Consumer Ombudsman',
      fraudReportingPhone: '1571 (Consumer Ombudsman) / 100 (police)',
      fraudReportingWebsite: 'https://www.bankofgreece.gr / https://www.synigoroskatanaloti.gr',
      commonScamsTargetingImmigrants: [
        'Fake UNHCR or asylum service communications requesting payments for "faster processing"',
        'Unlicensed immigration lawyers demanding high fees for services available through free legal aid',
        'Fake rental listings in Athens (especially Kypseli, Omonia area) targeting refugees',
        'Labor exploitation disguised as job offers (especially agriculture, tourism)',
        'Hawala operators failing to complete transfers to Pakistan/Afghanistan',
        'Fake travel documents or "smuggling services" which are criminal operations',
      ],
      scamPreventionTips: [
        'UNHCR, AIDA, and Greek Asylum Service NEVER charge fees for any service',
        'Free legal aid available through Greek Council for Refugees and other NGOs',
        'Verify lawyer registration at the local Bar Association (Δικηγορικός Σύλλογος)',
        'Never pay for jobs — this is illegal and often signals trafficking',
        'Use Wise/Revolut for transfers instead of informal channels',
        'Report to police (100) and Consumer Ombudsman (1571)',
      ],
      legalBasis:
          'Law 4465/2017 (basic payment accounts), Banking Law 4261/2014, Consumer Credit Law, Law 4738/2020 (insolvency), AML Law 4557/2018.',
      financialOmbudsman:
          'Συνήγορος του Καταναλωτή (Consumer Ombudsman). Website: www.synigoroskatanaloti.gr. Tel: 1571. Free. Also: Bank of Greece Banking and Credit Ombudsman.',
      immigrantSpecificNotes:
          'Greece is a major entry point for refugees. UNHCR Greece provides cash assistance via prepaid cards. Greek Council for Refugees (GCR) offers free legal and financial assistance. HELIOS integration program provides housing and financial support for recognized refugees. IOM Greece assists with financial inclusion. Major challenge: AFM is hard to get without stable address, but needed for bank account — seek NGO help to break this catch-22.',
    ),

    // ===================================================================
    // HUNGARY
    // ===================================================================
    'HU': const FinancialAccessInfo(
      country: 'Hungary',
      countryCode: 'HU',
      basicAccountRight: true,
      basicAccountDirectiveStatus:
          'Transposed via amendments to Act CCXXXVII of 2013 on Credit Institutions (2016). Basic payment account (alapszámla) available to legal residents. Max fee HUF 5,862/year (approximately EUR 15).',
      documentsForBankAccount: [
        'Valid passport or national ID',
        'Hungarian address card (lakcímkártya) or proof of address',
        'Tax identification number (adóazonosító jel)',
        'For asylum seekers: Menedékjogot kérő igazolás (asylum seeker certificate) — limited acceptance',
        'For recognized refugees: Hungarian residence permit (tartózkodási engedély)',
      ],
      banksForAsylumSeekers: [
        'OTP Bank — largest Hungarian bank, some branches accept asylum seeker documents',
        'K&H Bank — accepts diverse foreign documentation',
        'Budapest Bank (now part of MBH Bank) — has served asylum seekers',
      ],
      banksForUndocumented: [
        'Effectively impossible. Hungarian banks require adóazonosító jel (tax ID) and address card.',
        'Hungarian Helsinki Committee may assist in emergency cases.',
        'Prepaid cards at some retail locations.',
      ],
      bestBanksForImmigrants: [
        'OTP Bank — largest bank, widest network, some English support in Budapest',
        'K&H Bank (KBC group) — international network, English service in Budapest branches',
        'Erste Bank Hungary — part of Erste Group, English support, good digital banking',
        'Revolut — very popular in Hungary, English, EUR and HUF, no branch needed',
        'Wise — multi-currency, HUF support, excellent for remittances',
      ],
      bankAccountNotes:
          'Hungary uses HUF (forint), not EUR. Exchange rate costs apply. Alapszámla (basic account) guaranteed by law at regulated fees. Tax ID (adóazonosító jel) essential — get from NAV (tax authority) or government office (Kormányablak). Hungarian banking is modernizing rapidly but bureaucracy remains. Revolut/Wise popular as alternatives. MBH Bank (merger of several state banks) is now second-largest.',
      moneyTransferServices: [
        'Wise — online/app, competitive HUF rates',
        'Western Union — at post offices (Magyar Posta) and agents',
        'MoneyGram — agent locations',
        'Remitly — online/app',
      ],
      cheapestRemittanceOptions:
          'Wise for most corridors (0.5-2% including HUF conversion). For Ukraine/Serbia/Romania, Wise or Paysend are cheapest. Western Union at Magyar Posta for cash-based remittances. HUF volatility can affect transfer costs — consider timing.',
      taxIdName: 'Adóazonosító jel (Tax Identification Number, 10 digits)',
      taxIdHowToGet:
          'Apply at NAV (Nemzeti Adó- és Vámhivatal) office or Kormányablak (Government Window) with passport and proof of Hungarian address. Processing: immediate at Kormányablak. Can also apply online via Ügyfélkapu (client gateway) if you have registration.',
      socialSecurityNumber: 'TAJ szám (Társadalombiztosítási Azonosító Jel — Social Security ID, 9 digits)',
      socialSecurityHowToGet:
          'Apply at your local government office (Kormányablak) with passport, address card, and residence permit. For employees, employer facilitates. Processing: 1-5 days. TAJ is required for healthcare access. Asylum seekers receive TAJ through refugee authority.',
      taxObligationsForImmigrants:
          'Flat personal income tax: 15% (szja). Social contribution: 13% employer (szocho) + 18.5% employee (social security contributions including pension 10%, health 7%, labor market 1.5%). Total tax wedge approximately 43%. Residents taxed on worldwide income. Annual declaration due May 20. Hungary has the flat tax advantage — simple and low compared to Western EU.',
      taxFilingDeadline: 'May 20 for previous year.',
      taxAuthorityWebsite: 'https://www.nav.gov.hu',
      taxAuthorityPhone: '+36 1 462 3500 (NAV)',
      consumerCreditRights:
          'EU Consumer Credit Directive transposed. MNB (Magyar Nemzeti Bank — Hungarian National Bank) supervises. BISZ (Central Credit Information System / KHR) maintains credit registry. SECCI mandatory. 14-day withdrawal. APR caps on certain loan types. Strong borrower protections after 2010s foreign currency loan crisis.',
      creditHistoryBuilding:
          'KHR (Központi Hitelinformációs Rendszer) operated by BISZ records both positive and negative credit data. New immigrants have no file. Open bank account, establish regular income pattern, after 6-12 months apply for small consumer credit. Hungarian banks became more conservative after the FX loan crisis but are fair with documented income. Monthly income of HUF 250,000+ helps.',
      debtProtectionLaws:
          'Personal bankruptcy (csődeljárás for businesses, limited for individuals). Family insolvency procedure under development. Végrehajtás (enforcement) has minimum protected amounts. Government has provided various debt relief programs after FX loan crisis. Minimum subsistence amount protected from seizure.',
      overIndebtednessHelp:
          'Free legal aid: Jogi segítségnyújtás at government offices. MNB (National Bank) financial consumer protection: +36 80 203 776. Hungarian Helsinki Committee and Migration Aid for refugees.',
      fraudProtectionAuthority: 'MNB (Magyar Nemzeti Bank)',
      fraudReportingPhone: '+36 80 203 776 (MNB free helpline)',
      fraudReportingWebsite: 'https://www.mnb.hu',
      commonScamsTargetingImmigrants: [
        'Fake immigration/residence permit services',
        'Unlicensed money lenders (especially targeting seasonal workers)',
        'Apartment rental scams on ingatlan.com and Facebook',
        'Phishing targeting OTP Bank customers',
        'Fake employment agency fees',
      ],
      scamPreventionTips: [
        'Check financial licenses at MNB registry (mnb.hu)',
        'Never pay for government services through intermediaries',
        'Verify apartments in person before paying',
        'Report to police (107) and MNB consumer hotline',
      ],
      legalBasis:
          'Act CCXXXVII of 2013 on Credit Institutions, Act V of 2013 (Civil Code consumer protection), Act CXXII of 2011 (KHR), AML Law.',
      financialOmbudsman:
          'MNB Pénzügyi Békéltető Testület (Financial Arbitration Board). Website: www.mnb.hu/bekeltetes. Free, binding decisions.',
      immigrantSpecificNotes:
          'Hungary has become more restrictive on immigration. Hungarian Helsinki Committee (helsinki.hu) is the primary NGO for refugee rights including financial access. Tax system is simple (flat 15%). Cost of living lower than Western EU but wages also lower. Large expat community in Budapest has informal support networks. Revolut has become a de facto standard for many immigrants.',
    ),

    // ===================================================================
    // IRELAND
    // ===================================================================
    'IE': const FinancialAccessInfo(
      country: 'Ireland',
      countryCode: 'IE',
      basicAccountRight: true,
      basicAccountDirectiveStatus:
          'Transposed via European Union (Payment Accounts) Regulations 2016 (S.I. No. 482/2016). All legal residents entitled to basic payment account. Central Bank of Ireland oversees. Max EUR 5/month (approximately EUR 60/year).',
      documentsForBankAccount: [
        'Valid passport or national ID',
        'PPS Number (Personal Public Service Number)',
        'Proof of Irish address (utility bill, bank statement, or Revenue letter)',
        'For asylum seekers: Temporary Residence Certificate (TRC) from IPO + letter from accommodation center',
        'For recognized refugees: Stamp 4 permission + PPS + proof of address',
        'For Ukrainian beneficiaries of Temporary Protection: Permission letter + PPS',
      ],
      banksForAsylumSeekers: [
        'AIB — has specific processes for asylum seekers, accepts TRC',
        'Bank of Ireland — opens accounts with IPO documentation',
        'Permanent TSB — accessible with asylum seeker documentation',
        'An Post Money (post office) — most accessible, accepts diverse documentation',
      ],
      banksForUndocumented: [
        'Very limited. PPS number effectively required.',
        'MASI (Movement of Asylum Seekers in Ireland) and NASC can advocate for financial access.',
        'An Post Money current account has the most flexible document requirements.',
      ],
      bestBanksForImmigrants: [
        'AIB — strong digital banking, good immigrant processes, English-native environment',
        'Bank of Ireland — largest bank, wide branch network',
        'An Post Money — post office accounts, most accessible, simple setup',
        'N26 — German IBAN, fully digital, English, works well in Ireland',
        'Revolut — extremely popular in Ireland, English, EUR IBAN, instant setup',
        'Wise — multi-currency, Irish IBAN not available but EUR works, excellent for remittances',
      ],
      bankAccountNotes:
          'Ireland is English-speaking, making banking easier for anglophone immigrants. PPS Number is essential — get it from local PPS allocation center (previously Intreo office). Since Ulster Bank and KBC exited Ireland (2022-2023), AIB and Bank of Ireland dominate. Revolut has become a major banking alternative. An Post Money is the most accessible option for those with limited documentation.',
      moneyTransferServices: [
        'Wise — online/app',
        'Western Union — at An Post offices',
        'MoneyGram — agent locations',
        'Remitly — online/app (headquartered in Dublin)',
        'WorldRemit — online/app',
        'Ria — agents in Dublin',
      ],
      cheapestRemittanceOptions:
          'Wise for most corridors (0.3-1.5%). Remitly (Dublin-based) offers competitive rates especially for Philippines, India, Nigeria. For Nigeria and West Africa, WorldRemit and Remitly compete aggressively. SEPA transfers within EU free.',
      taxIdName: 'PPS Number (Personal Public Service Number)',
      taxIdHowToGet:
          'Apply at local PPS allocation center (Intreo/Social Welfare office) with passport, proof of Irish address, and proof of why you need it (employment contract, letter from employer, etc.). Processing: 1-4 weeks (longer post-COVID). Revenue (tax authority) uses PPS as tax identifier.',
      socialSecurityNumber: 'PPS Number — same number for tax, social welfare, and public services',
      socialSecurityHowToGet:
          'Same as tax ID above. PPS number is your key to Irish public services. Apply at Intreo office. Asylum seekers receive PPS through the International Protection Accommodation Service (IPAS) process.',
      taxObligationsForImmigrants:
          'Residents taxed on worldwide income. Progressive rates: 20% (up to EUR 42,000 single) then 40%. USC (Universal Social Charge): 0.5-8%. PRSI (social insurance): 4% employee, 11.05% employer. Total marginal rate can reach 52%. Employment income taxed at source (PAYE). Self-assessed individuals file by October 31. Ireland has special expat remittance basis for non-domiciled residents.',
      taxFilingDeadline: 'October 31 for self-assessed (Form 11). PAYE employees: checked automatically, but can file Form 12 for refunds.',
      taxAuthorityWebsite: 'https://www.revenue.ie',
      taxAuthorityPhone: '+353 1 738 3600 (Revenue)',
      consumerCreditRights:
          'EU Consumer Credit Directive transposed. Central Bank of Ireland supervises. Irish Credit Bureau (ICB) and Central Credit Register (CCR) track credit. SECCI mandatory. 14-day withdrawal. Strong consumer protection code (CPC 2012, updated). Responsible lending requirements.',
      creditHistoryBuilding:
          'Central Credit Register (CCR) records all credit agreements above EUR 500. ICB (Irish Credit Bureau) maintains more detailed records. New immigrants have no file. Steps: get PPS, open bank account, get employment, after 6-12 months request credit card (An Post Money or AIB often accessible). Request free CCR report annually. Irish banks consider length of residence and employment stability.',
      debtProtectionLaws:
          'Personal Insolvency Act 2012 (amended). Three mechanisms: Debt Relief Notice (DRN, debts under EUR 35,000), Debt Settlement Arrangement (DSA, unsecured debts), Personal Insolvency Arrangement (PIA, secured + unsecured). Bankruptcy discharge after 1 year. MABS provides pre-insolvency guidance.',
      overIndebtednessHelp:
          'MABS (Money Advice and Budgeting Service) — free, state-funded, confidential debt advice. Available nationwide. Tel: 0818 07 2000. Website: www.mabs.ie. Insolvency Service of Ireland (ISI) for formal insolvency procedures. FLAC (Free Legal Advice Centres) for legal aspects of debt.',
      fraudProtectionAuthority: 'Central Bank of Ireland / CCPC (Competition and Consumer Protection Commission)',
      fraudReportingPhone: '1890 432 432 (CCPC)',
      fraudReportingWebsite: 'https://www.ccpc.ie / https://www.centralbank.ie',
      commonScamsTargetingImmigrants: [
        'Fake Direct Provision / IPAS communications requesting payment',
        'Rental scams (Dublin housing crisis makes people desperate) — deposits for non-existent rooms',
        'PPS number phishing (texts/emails claiming to be from Revenue or DSP)',
        'Fake immigration solicitors charging excessive fees',
        'Employment scams (especially restaurant/hospitality) paying below minimum wage cash-in-hand',
        'Pyramid/MLM schemes targeting immigrant communities',
      ],
      scamPreventionTips: [
        'Revenue and DSP never request personal info by email or text',
        'Use daft.ie for accommodation — avoid paying deposits without viewing',
        'Verify solicitors at lawsociety.ie',
        'Minimum wage is EUR 12.70/hour (2024) — report underpayment to WRC',
        'Check Central Bank register for licensed financial providers',
        'Report scams to Gardaí and CCPC',
      ],
      legalBasis:
          'Payment Accounts Regulations 2016, Central Bank Acts, Consumer Credit Act 1995, Personal Insolvency Act 2012, Consumer Protection Act 2007, Criminal Justice (Money Laundering) Acts.',
      financialOmbudsman:
          'Financial Services and Pensions Ombudsman (FSPO). Website: www.fspo.ie. Tel: +353 1 567 7000. Free, independent dispute resolution.',
      immigrantSpecificNotes:
          'Ireland is English-speaking, which is a major advantage for anglophone immigrants. MABS provides excellent free financial advice. Nasc (Irish Immigrant Support Centre) in Cork, Crosscare in Dublin, and Doras in Limerick provide free immigration and integration support including financial literacy. Citizens Information (citizensinformation.ie) is the comprehensive English-language guide to all rights. Special Assignee Relief Programme (SARP) for qualifying expat employees reduces tax.',
    ),

    // ===================================================================
    // ITALY
    // ===================================================================
    'IT': const FinancialAccessInfo(
      country: 'Italy',
      countryCode: 'IT',
      basicAccountRight: true,
      basicAccountDirectiveStatus:
          'Transposed via D.Lgs. 37/2017. Right to conto di base (basic account) for all legal residents. Max fee EUR 86.84/year (updated annually by MEF). Bank of Italy oversees compliance. Vulnerable customers (ISEE < EUR 11,600) get it free.',
      documentsForBankAccount: [
        'Valid passport or national ID',
        'Codice fiscale (Italian tax code)',
        'Proof of address (residenza: certificato di residenza or utility bill)',
        'For asylum seekers: Permesso di soggiorno per richiesta asilo or ricevuta di richiesta',
        'For recognized refugees: Permesso di soggiorno per protezione internazionale',
        'For EU citizens: Attestazione di iscrizione anagrafica',
      ],
      banksForAsylumSeekers: [
        'Poste Italiane (PostePay/BancoPosta) — most accessible, present in every comune, accepts asylum documents',
        'Intesa Sanpaolo — largest bank, has programs for refugees',
        'UniCredit — accepts asylum seeker permits for basic accounts',
        'Banca Etica — ethical bank, proactively serves marginalized groups including refugees',
      ],
      banksForUndocumented: [
        'Codice fiscale can be obtained by undocumented persons from Agenzia delle Entrate with just a passport.',
        'Poste Italiane PostePay card (prepaid) obtainable with codice fiscale + passport — does not require residence permit.',
        'Banca Etica has historically been more open to vulnerable populations.',
        'NAGA, Caritas, and other NGOs assist with financial access.',
      ],
      bestBanksForImmigrants: [
        'Poste Italiane (BancoPosta) — 12,800 offices, most accessible, accepts diverse documents, PostePay prepaid easy to get',
        'Intesa Sanpaolo — largest bank, some English support in tourist areas, competitive conto di base',
        'UniCredit — international network, English service in major cities, good digital banking',
        'N26 — fully digital, English, Italian IBAN, no branch needed, very popular with immigrants',
        'Revolut — English, EUR IBAN, no branch needed',
        'Wise — multi-currency, Italian IBAN available, excellent for remittances',
        'Banca Etica — ethical bank, immigrant-friendly, limited branch network',
      ],
      bankAccountNotes:
          'Codice fiscale is the KEY — get it from Agenzia delle Entrate (free, same day, passport only). Even undocumented persons can get codice fiscale. PostePay Evolution (prepaid with IBAN) is the easiest entry point — costs EUR 10/year plus EUR 1/month, available at any post office with codice fiscale + passport. Conto di base is free for low-income residents (ISEE < EUR 11,600).',
      moneyTransferServices: [
        'Wise — online/app, Italian IBAN',
        'Western Union — at post offices and agents (thousands of locations)',
        'MoneyGram — agent locations throughout Italy',
        'Remitly — online/app',
        'WorldRemit — online/app',
        'Ria — agents in major cities',
        'Small World — popular for Latin America/Philippines transfers',
      ],
      cheapestRemittanceOptions:
          'Wise for bank transfers (0.3-1.5%). For Romania/Albania/Morocco (largest diaspora groups), Ria and Small World compete on rates. For Philippines, Remitly offers promotional zero-fee transfers. Italy has one of the highest remittance outflows in the EU — comparison shopping is essential.',
      taxIdName: 'Codice fiscale (16-character alphanumeric tax code)',
      taxIdHowToGet:
          'FREE from any Agenzia delle Entrate office. Bring passport only. No residence permit required. Issued same day. Also available at Italian consulates abroad. Some municipalities issue it during residenza registration. Essential for EVERYTHING in Italy (banking, contracts, healthcare, employment).',
      socialSecurityNumber: 'Codice fiscale serves as social security identifier. INPS registration separate.',
      socialSecurityHowToGet:
          'Codice fiscale is the identifier. INPS (Istituto Nazionale della Previdenza Sociale) enrollment handled by employer when you start employment. Self-employed register directly at INPS. Asylum seekers: enrolled through reception system (SIPROIMI/SAI). Access INPS services via SPID digital identity.',
      taxObligationsForImmigrants:
          'Residents (183+ days or registered in anagrafe) taxed on worldwide income. Progressive IRPEF rates: 23% (up to EUR 28,000), 25% (EUR 28-50,000), 35% (EUR 50-55,000), 43% (above EUR 55,000). Regional surcharge: 1.23-3.33%. Municipal surcharge: 0-0.8%. Employment income taxed at source. Annual Dichiarazione dei redditi (Modello 730 or Modello Redditi) by September 30. Flat tax option for new residents (EUR 100,000/year on foreign income for up to 15 years).',
      taxFilingDeadline: 'Modello 730: September 30. Modello Redditi (Unico): November 30. Electronic via Agenzia delle Entrate portal.',
      taxAuthorityWebsite: 'https://www.agenziaentrate.gov.it',
      taxAuthorityPhone: '848 800 444 or +39 06 96668907 (from abroad)',
      consumerCreditRights:
          'EU Consumer Credit Directive transposed. Bank of Italy and CONSOB supervise. Centrale Rischi (Bank of Italy) and SIC (private credit bureaus: CRIF, CTC, Experian) track credit. SECCI mandatory. 14-day withdrawal. Tasso soglia (usury threshold) sets maximum interest rates per product type.',
      creditHistoryBuilding:
          'CRIF (main private credit bureau), CTC, and Experian Cerved track credit data. Both positive and negative. Bank of Italy Centrale Rischi tracks exposures above EUR 30,000. New immigrants: get codice fiscale, open bank/postal account, establish income pattern, after 6-12 months request small consumer credit. PostePay Evolution builds basic financial identity. CRIF report requestable (free annually).',
      debtProtectionLaws:
          'Sovraindebitamento (over-indebtedness) procedure under Codice della Crisi d\'Impresa (D.Lgs. 14/2019). Three tools: Piano del consumatore (consumer plan), Accordo di composizione (creditor agreement), Liquidazione del patrimonio (asset liquidation). Minimum living standards protected. Esdebitazione (discharge) possible. OCC (Organismi di composizione della crisi) assist.',
      overIndebtednessHelp:
          'OCC (Organismi di composizione della crisi) at each court district — handle insolvency applications. Caritas provides financial counseling for immigrants. Patronati (trade union assistance offices: CGIL, CISL, UIL) help with tax and social security FOR FREE. Federconsumatori and Adiconsum for consumer disputes.',
      fraudProtectionAuthority: 'Bank of Italy / CONSOB / AGCM (Antitrust and Consumer Authority)',
      fraudReportingPhone: '800 166 661 (AGCM) / 112 (Carabinieri)',
      fraudReportingWebsite: 'https://www.agcm.it / https://www.bancaditalia.it',
      commonScamsTargetingImmigrants: [
        'Fake permesso di soggiorno services charging EUR 500-3000 (applying is free through patronato)',
        'Caporalato (illegal labor intermediaries) in agriculture — taking cuts from wages',
        'Fake rental listings especially in Milan/Rome — deposits to foreign accounts',
        'Phishing SMS/email pretending to be Poste Italiane or Agenzia delle Entrate',
        'Door-to-door energy/gas contract switches with hidden terms',
        'Counterfeit document services (fake codice fiscale, fake residence certificates)',
        'Money transfer scams via informal channels (especially for African remittance corridors)',
      ],
      scamPreventionTips: [
        'Codice fiscale is FREE from Agenzia delle Entrate — never pay for it',
        'Patronati (CGIL, CISL, UIL) help with residence permits, tax, and INPS FOR FREE',
        'Never sign contracts in Italian that you do not understand — bring a translator',
        'Verify any financial service provider at Albo degli intermediari finanziari (Bank of Italy)',
        'Report caporalato to Carabinieri (112) or FLAI-CGIL trade union',
        'Agenzia delle Entrate and Poste Italiane never request data via SMS/email',
      ],
      legalBasis:
          'D.Lgs. 37/2017 (basic accounts), TUB (Testo Unico Bancario), Codice del Consumo, Codice della Crisi d\'Impresa D.Lgs. 14/2019, AML D.Lgs. 231/2007.',
      financialOmbudsman:
          'ABF (Arbitro Bancario Finanziario) — free dispute resolution for banking. ACF (Arbitro per le Controversie Finanziarie) for investment disputes. Both run by Bank of Italy/CONSOB. Very effective.',
      immigrantSpecificNotes:
          'Italy has the most generous codice fiscale policy — available to ANYONE with a passport, regardless of immigration status. This opens basic financial access. Patronati (CGIL, CISL, UIL offices) are ESSENTIAL for immigrants — free help with tax, social security, permits, and disputes. Over 5 million immigrants in Italy. Large Romanian, Albanian, Moroccan, Chinese, Filipino, Ukrainian communities have established support networks. PostePay is the easiest entry into the financial system.',
    ),

    // ===================================================================
    // LATVIA
    // ===================================================================
    'LV': const FinancialAccessInfo(
      country: 'Latvia',
      countryCode: 'LV',
      basicAccountRight: true,
      basicAccountDirectiveStatus:
          'Transposed via amendments to the Law on Payment Services and Electronic Money (2017). Legal residents entitled to basic payment account. FKTK (now Bank of Latvia after 2023 merger) oversees.',
      documentsForBankAccount: [
        'Valid passport or ID card',
        'Latvian personal identity number (personas kods)',
        'Proof of address (registration at PMLP or utility bill)',
        'For asylum seekers: Asylum seeker certificate from PMLP (Office of Citizenship and Migration Affairs)',
        'For recognized refugees: Residence permit + personas kods',
      ],
      banksForAsylumSeekers: [
        'Swedbank Latvia — accepts asylum seeker documents for basic accounts',
        'SEB Latvia — limited acceptance, case-by-case basis',
        'Citadele Bank — Latvian bank, more flexible with documentation',
      ],
      banksForUndocumented: [
        'No access without valid ID and personas kods.',
        'Latvian Centre for Human Rights may assist in emergency cases.',
      ],
      bestBanksForImmigrants: [
        'Swedbank — largest bank in Latvia, English support, good digital platform',
        'SEB — second largest, strong corporate banking, English service',
        'Citadele — Latvian private bank, competitive fees, English online banking',
        'Revolut — very popular in Latvia, English, EUR IBAN since Latvia adopted EUR (2014)',
        'Wise — multi-currency, EUR IBAN, excellent for remittances',
      ],
      bankAccountNotes:
          'Latvia uses EUR since 2014. Latvian banking sector was restructured after 2018 AML scandals (ABLV closure). Banks now have very strict KYC/AML requirements. Personas kods (personal code) essential — get from PMLP. Basic account guaranteed by law. Digital banking is well-developed.',
      moneyTransferServices: [
        'Wise — online/app',
        'Western Union — at various agents',
        'MoneyGram — limited locations',
        'Paysend — online/app, popular for CIS transfers',
      ],
      cheapestRemittanceOptions:
          'Wise for most corridors. Paysend competitive for Russia/Ukraine/Belarus. SEPA transfers within EU free/cheap. Latvia\'s Russian-speaking population uses various channels for CIS country transfers.',
      taxIdName: 'Personas kods (Personal Identity Number) — also serves as tax ID',
      taxIdHowToGet:
          'Issued by PMLP (Pilsonības un migrācijas lietu pārvalde) when registering residence. EU citizens: register at PMLP within 3 months. Non-EU: issued with residence permit. Processing: 1-5 days.',
      socialSecurityNumber: 'Personas kods — same number for all purposes',
      socialSecurityHowToGet:
          'Same as tax ID — issued by PMLP upon residence registration. Employer uses it for VSAA (State Social Insurance Agency) declarations.',
      taxObligationsForImmigrants:
          'Residents taxed on worldwide income. Progressive PIT: 20% (up to EUR 20,004), 23% (EUR 20,004-78,100), 31% (above EUR 78,100). Social contributions: 10.50% employee + 23.59% employer. Annual return due June 1. Latvia has competitive tax rates by EU standards.',
      taxFilingDeadline: 'June 1 for previous year (electronic via EDS — VID electronic declaration system).',
      taxAuthorityWebsite: 'https://www.vid.gov.lv',
      taxAuthorityPhone: '+371 67120000 (VID)',
      consumerCreditRights:
          'EU Consumer Credit Directive transposed. Bank of Latvia (merged FKTK) supervises. Credit information bureau: LURSOFT and Creditreform Latvia. 14-day withdrawal. Non-bank lending sector regulated since 2016.',
      creditHistoryBuilding:
          'No centralized positive credit bureau. Banks maintain internal records. LURSOFT and Creditreform track business credit. Build credit by: maintaining bank account, regular salary deposits, paying bills on time, after 6-12 months apply for small credit products. Latvian banks assess income stability as key factor.',
      debtProtectionLaws:
          'Insolvency Law of Latvia (Maksātnespējas likums). Natural person insolvency: court-supervised plan, debts can be discharged after 1-3 years. Protected minimum income and essential property exempt from seizure. Bailiff (tiesu izpildītājs) enforcement limited by debtor protections.',
      overIndebtednessHelp:
          'Free legal aid via Juridiskās palīdzības administrācija (Legal Aid Administration). Consumer Rights Protection Centre (PTAC) handles financial complaints. Latvian Centre for Human Rights assists refugees.',
      fraudProtectionAuthority: 'Bank of Latvia (Latvijas Banka) / PTAC (Consumer Rights Protection Centre)',
      fraudReportingPhone: '+371 65452554 (PTAC)',
      fraudReportingWebsite: 'https://www.ptac.gov.lv / https://www.bank.lv',
      commonScamsTargetingImmigrants: [
        'Fake residence permit services',
        'Online quick-loan scams with hidden fees',
        'Apartment rental scams (especially in Riga)',
        'Phishing emails impersonating Swedbank or SEB',
        'Crypto/investment scams in Russian-language online groups',
      ],
      scamPreventionTips: [
        'Verify financial providers at Bank of Latvia registry',
        'PMLP services are official and direct — no intermediaries needed',
        'View apartments before paying',
        'Banks never request credentials via email',
        'Report to police (110) and PTAC',
      ],
      legalBasis:
          'Law on Payment Services and Electronic Money, Credit Institution Law, Insolvency Law, Consumer Rights Protection Law, AML/CFT Law.',
      financialOmbudsman:
          'Finanšu tirgus klientu interešu aizsardzības biedrība (Association for Financial Market Client Interest Protection). PTAC handles consumer disputes. Bank of Latvia for banking complaints.',
      immigrantSpecificNotes:
          'Latvia has a large Russian-speaking minority. Many immigrants from CIS countries find language relatively accessible. PMLP is the key institution for residence registration. EUR adoption (2014) simplifies finances. Latvian Centre for Human Rights provides integration support. Society "Shelter Safe House" assists refugees. Cost of living lower than Western EU but higher than Lithuania.',
    ),

    // ===================================================================
    // LITHUANIA
    // ===================================================================
    'LT': const FinancialAccessInfo(
      country: 'Lithuania',
      countryCode: 'LT',
      basicAccountRight: true,
      basicAccountDirectiveStatus:
          'Transposed via Law on Payments (Mokėjimų įstatymas) amendments 2017. Legal residents entitled to basic payment account. Bank of Lithuania (Lietuvos bankas) oversees.',
      documentsForBankAccount: [
        'Valid passport or ID',
        'Lithuanian personal code (asmens kodas)',
        'Proof of address',
        'For asylum seekers: Asylum seeker certificate from Migration Department',
        'For recognized refugees: Residence permit + asmens kodas',
      ],
      banksForAsylumSeekers: [
        'Swedbank Lithuania — accepts asylum documentation',
        'SEB Lithuania — basic accounts for asylum seekers',
        'Luminor — accepts diverse foreign documents',
      ],
      banksForUndocumented: [
        'No access without valid identification and asmens kodas.',
        'Lithuanian Red Cross and Caritas may facilitate emergency solutions.',
      ],
      bestBanksForImmigrants: [
        'Swedbank — largest bank in Lithuania, English support',
        'SEB — strong digital banking, English service',
        'Luminor — formed from DNB/Nordea merger, good for immigrants',
        'Revolut — extremely popular in Lithuania (Revolut holds EU license from Lithuania), English, EUR IBAN',
        'Wise — EUR IBAN, multi-currency',
        'Paysera — Lithuanian fintech, competitive fees, English, popular locally',
      ],
      bankAccountNotes:
          'Lithuania is a fintech hub — Revolut, Paysera, and many EMIs are licensed here. EUR since 2015. Asmens kodas (personal code) is essential. Lithuanian banking is modern and digital-friendly. Paysera is a local fintech offering competitive accounts. Many immigrants use fintech solutions as primary banking.',
      moneyTransferServices: [
        'Wise — online/app',
        'Paysera — Lithuanian fintech, competitive rates',
        'Western Union — at various agents',
        'Paysend — online/app',
      ],
      cheapestRemittanceOptions:
          'Wise and Paysera compete on rates. Both are excellent. For Belarus/Ukraine, Paysend competitive. SEPA transfers within EU free. Lithuania being a fintech hub means excellent digital options.',
      taxIdName: 'Asmens kodas (Personal Code) serves as tax identifier',
      taxIdHowToGet:
          'Issued by Migration Department (Migracijos departamentas) when registering residence. EU citizens: register at local eldership (seniūnija). Processing: 1-7 days. Also needed for all government services.',
      socialSecurityNumber: 'Asmens kodas — universal identifier',
      socialSecurityHowToGet:
          'Same as above. SODRA (State Social Insurance Fund Board) uses asmens kodas for all social security records. Employer registers you.',
      taxObligationsForImmigrants:
          'Residents taxed on worldwide income. PIT: 20% (standard), 32% (above EUR 101,094). Social contributions: approximately 19.5% employee (pension, health, etc.) + 1.77% employer. Annual declaration due May 1. Lithuania has competitive rates.',
      taxFilingDeadline: 'May 1 for previous year (electronic via VMI EDS system).',
      taxAuthorityWebsite: 'https://www.vmi.lt',
      taxAuthorityPhone: '+370 5 260 5060 (VMI)',
      consumerCreditRights:
          'EU Consumer Credit Directive transposed. Bank of Lithuania supervises all credit providers including fintechs. Creditinfo Lietuva is the credit bureau. Strong responsible lending requirements. 14-day withdrawal.',
      creditHistoryBuilding:
          'Creditinfo Lietuva maintains credit data (positive and negative). New immigrants have no file. Open account (Paysera or traditional bank), maintain regular income, after 6-12 months apply for credit. Lithuanian fintech lenders may be more flexible than traditional banks.',
      debtProtectionLaws:
          'Natural Person Bankruptcy Law (Fizinių asmenų bankroto įstatymas). Court-supervised process, debts dischargeable after 3 years of compliance. Protected minimum income. Bailiff (antstolis) enforcement limited by debtor protections.',
      overIndebtednessHelp:
          'Free legal aid via Valstybės garantuojama teisinė pagalba (State-guaranteed Legal Aid). Consumer disputes through Bank of Lithuania dispute resolution. Lithuanian Red Cross for refugees.',
      fraudProtectionAuthority: 'Bank of Lithuania (Lietuvos bankas)',
      fraudReportingPhone: '+370 800 50 500 (Bank of Lithuania)',
      fraudReportingWebsite: 'https://www.lb.lt',
      commonScamsTargetingImmigrants: [
        'Fake fintech/EMI investment platforms (taking advantage of Lithuania\'s fintech reputation)',
        'Quick-loan scams with extreme interest',
        'Rental scams in Vilnius',
        'Fake job offers for IT sector',
        'Phishing targeting Swedbank/SEB customers',
      ],
      scamPreventionTips: [
        'Verify fintech licenses at Bank of Lithuania registry (lb.lt)',
        'Lithuania licenses many EMIs — check if the specific entity is actually licensed',
        'Never pay for government residence services through third parties',
        'Report to police (112) and Bank of Lithuania',
      ],
      legalBasis:
          'Law on Payments, Law on Banks, Consumer Credit Law, Natural Person Bankruptcy Law, AML Law.',
      financialOmbudsman:
          'Bank of Lithuania handles all financial dispute resolution. Website: www.lb.lt/en/dispute-resolution. Free, efficient process. Decisions binding on financial institutions up to EUR 100,000.',
      immigrantSpecificNotes:
          'Lithuania is a fintech hub — Revolut, Paysera, and 80+ fintech companies licensed here. This means excellent digital financial services. Large Ukrainian refugee community since 2022. Lithuanian Red Cross and IOM Lithuania provide integration support. Vilnius is startup-friendly with English widely spoken in tech sector. Cost of living moderate. Paysera is an excellent local alternative to traditional banking.',
    ),

    // ===================================================================
    // LUXEMBOURG
    // ===================================================================
    'LU': const FinancialAccessInfo(
      country: 'Luxembourg',
      countryCode: 'LU',
      basicAccountRight: true,
      basicAccountDirectiveStatus:
          'Transposed via Loi du 13 juin 2017 relative aux comptes de paiement. All legal residents entitled to basic payment account. CSSF (Commission de Surveillance du Secteur Financier) oversees. Max fee EUR 30/year.',
      documentsForBankAccount: [
        'Valid passport or national ID',
        'Proof of Luxembourg address (certificat de résidence from commune)',
        'National identification number (matricule)',
        'For asylum seekers: Attestation de demande de protection internationale',
        'For recognized refugees: Titre de séjour + matricule',
      ],
      banksForAsylumSeekers: [
        'BGL BNP Paribas — accepts asylum seeker documentation',
        'Banque et Caisse d\'Épargne de l\'État (BCEE/Spuerkeess) — state savings bank, accessible',
        'POST Finance — post office banking, flexible documentation',
      ],
      banksForUndocumented: [
        'Very limited without matricule number.',
        'Croix-Rouge luxembourgeoise provides assistance.',
        'POST Finance may offer basic services with limited documentation.',
      ],
      bestBanksForImmigrants: [
        'BCEE (Spuerkeess) — state bank, multilingual (FR/DE/EN/LU/PT), competitive fees',
        'BGL BNP Paribas — largest private bank, multilingual staff, good expat services',
        'ING Luxembourg — competitive online banking, English/French',
        'Revolut — EUR IBAN, multilingual, popular with cross-border workers',
        'Wise — multi-currency, excellent for international workers',
        'N26 — German IBAN, multilingual app',
      ],
      bankAccountNotes:
          'Luxembourg is a major financial center with multilingual banking (French, German, English, Portuguese, Luxembourgish). Many cross-border workers (from France, Germany, Belgium) bank here. Matricule (13-digit national ID number) essential — get from CTIE (Centre des technologies de l\'information de l\'État). Basic account max EUR 30/year. Banking sector is sophisticated and well-regulated.',
      moneyTransferServices: [
        'Wise — online/app',
        'Western Union — at POST offices',
        'MoneyGram — limited agents',
        'Remitly — online/app',
      ],
      cheapestRemittanceOptions:
          'Wise for most corridors (0.3-1.5%). SEPA transfers within EU free. For Portugal/Cape Verde (large community), Wise or bank SEPA transfers. Luxembourg\'s high salaries make percentage-based fees more costly in absolute terms — compare carefully.',
      taxIdName: 'Matricule national (13-digit national identification number)',
      taxIdHowToGet:
          'Automatically assigned by CTIE when registering at your commune. EU citizens: register at commune within 3 months. Non-EU: assigned with residence permit. Contact commune or CTIE if not received. Processing: immediate at commune.',
      socialSecurityNumber: 'Matricule — same number for tax, social security, healthcare',
      socialSecurityHowToGet:
          'Same as above. CCSS (Centre commun de la sécurité sociale) uses matricule for all social security. Employer declares you at CCSS when starting employment.',
      taxObligationsForImmigrants:
          'Residents taxed on worldwide income. Progressive rates: 0%-42% (plus solidarity surcharge 7% of tax = effective max approximately 45%). Employment income taxed at source. Annual declaration (by March 31 following year). Luxembourg has favorable tax regime for expats and investment fund industry.',
      taxFilingDeadline: 'March 31 for previous year.',
      taxAuthorityWebsite: 'https://impotsdirects.public.lu',
      taxAuthorityPhone: '+352 40 800 1',
      consumerCreditRights:
          'EU Consumer Credit Directive transposed. CSSF supervises. Centrale des Crédits aux Particuliers maintained by Banque Centrale du Luxembourg. SECCI mandatory. 14-day withdrawal. Responsible lending requirements.',
      creditHistoryBuilding:
          'Centrale des Crédits records all consumer credits. New immigrants: open bank account, stable employment (Luxembourg has very low unemployment), after 6-12 months credit products accessible. Luxembourg salaries are the highest in the EU — banks view employed residents favorably.',
      debtProtectionLaws:
          'Surendettement (over-indebtedness) procedure: Commission de médiation at CSSF. Conciliation phase, then judicial phase if needed. Minimum living amounts protected (salaire social minimum has strong protections). Personal bankruptcy possible as last resort.',
      overIndebtednessHelp:
          'Service information et conseil en matière de surendettement (Ligue Médico-Sociale). Inter-Actions asbl. CSSF mediation. Legal aid (assistance judiciaire) for qualifying residents.',
      fraudProtectionAuthority: 'CSSF (Commission de Surveillance du Secteur Financier)',
      fraudReportingPhone: '+352 26 251-1 (CSSF)',
      fraudReportingWebsite: 'https://www.cssf.lu',
      commonScamsTargetingImmigrants: [
        'Fake investment schemes (Luxembourg\'s financial reputation exploited)',
        'Rental scams in Luxembourg City (extremely tight housing market)',
        'Fake CSSF or government communications',
        'Cross-border employment scams',
      ],
      scamPreventionTips: [
        'Verify all financial entities at CSSF registry (cssf.lu)',
        'Luxembourg housing is expensive but never pay without visiting',
        'Report to police (113) and CSSF',
      ],
      legalBasis:
          'Loi du 13 juin 2017 (payment accounts), Loi du 5 avril 1993 (financial sector), Consumer Code, AML legislation.',
      financialOmbudsman:
          'CSSF handles all financial complaints. Also: Médiateur de la consommation (consumer mediator). Commission de médiation en matière de surendettement.',
      immigrantSpecificNotes:
          'Luxembourg is the richest country in the EU by GDP per capita. Large Portuguese, French, Italian, and Belgian immigrant communities. ASTI (Association de Soutien aux Travailleurs Immigrés) provides integration support. OLAI (Office luxembourgeois de l\'accueil et de l\'intégration) is the official integration body. Multilingual environment (French/German/Luxembourgish) — French is the main administrative and banking language. Cross-border workers from France/Belgium/Germany should understand tax implications.',
    ),

    // ===================================================================
    // MALTA
    // ===================================================================
    'MT': const FinancialAccessInfo(
      country: 'Malta',
      countryCode: 'MT',
      basicAccountRight: true,
      basicAccountDirectiveStatus:
          'Transposed via Legal Notice 137 of 2017 (Payment Accounts Regulations). Legal residents entitled to basic payment account. MFSA (Malta Financial Services Authority) oversees.',
      documentsForBankAccount: [
        'Valid passport or national ID',
        'Maltese eResidence card or ID card',
        'Proof of Maltese address (utility bill)',
        'For asylum seekers: Documentation from Agency for the Welfare of Asylum Seekers (AWAS)',
        'For recognized refugees: Protection status document + eResidence card',
      ],
      banksForAsylumSeekers: [
        'Bank of Valletta (BOV) — largest bank, accepts AWAS documentation',
        'HSBC Malta — accepts asylum seeker documents for basic accounts',
        'APS Bank — community-focused, flexible with documentation',
      ],
      banksForUndocumented: [
        'Very limited. Maltese banks have strict KYC requirements.',
        'AWAS and NGOs may facilitate basic financial access.',
      ],
      bestBanksForImmigrants: [
        'Bank of Valletta — largest, widest branch network, English fully supported',
        'HSBC Malta — international bank, excellent English service, strong online banking',
        'APS Bank — community bank, competitive fees, English',
        'Revolut — popular among immigrants, English, EUR IBAN',
        'Wise — multi-currency, excellent for remittances',
      ],
      bankAccountNotes:
          'Malta is English-speaking, which simplifies banking significantly. Small island — limited bank choices but all offer English service. EUR since 2008. eResidence card (Identity Malta) needed for most services. Banks can be slow with account opening — expect 1-3 weeks. Gaming/fintech sector means banks are cautious with AML.',
      moneyTransferServices: [
        'Wise — online/app',
        'Western Union — limited agents',
        'MoneyGram — limited agents',
        'Remitly — online/app',
      ],
      cheapestRemittanceOptions:
          'Wise for most transfers. Malta has significant Filipino, Indian, and Libyan immigrant populations — Remitly and WorldRemit offer competitive rates for these corridors. SEPA transfers within EU free.',
      taxIdName: 'Malta Tax Number (issued by IRD — Inland Revenue Department)',
      taxIdHowToGet:
          'Apply at IRD (Commissioner for Revenue) with passport, eResidence card, and proof of address. Can apply online via cfr.gov.mt. Processing: 1-2 weeks.',
      socialSecurityNumber: 'Social Security Number (from Department of Social Security)',
      socialSecurityHowToGet:
          'Apply at Department of Social Security with eResidence card and passport. Employer facilitates for employees. Processing: 1-2 weeks.',
      taxObligationsForImmigrants:
          'Residents taxed on worldwide income (unless domiciled but not ordinarily resident — special status). Progressive rates: 0%-35%. Single rate bands differ from married. Social security: 10% employee + 10% employer (capped). Annual return due June 30. Malta has attractive tax residency programs for high-net-worth individuals.',
      taxFilingDeadline: 'June 30 for previous year.',
      taxAuthorityWebsite: 'https://cfr.gov.mt',
      taxAuthorityPhone: '+356 2296 1000',
      consumerCreditRights:
          'EU Consumer Credit Directive transposed. MFSA supervises. Malta credit reporting limited. 14-day withdrawal. Responsible lending requirements.',
      creditHistoryBuilding:
          'Malta has limited credit bureau infrastructure compared to larger EU countries. Banks rely heavily on income documentation and internal records. Stable employment and bank account history (6-12 months) are key factors. Small community means personal relationships with bank managers still matter.',
      debtProtectionLaws:
          'No specific personal insolvency law comparable to larger EU states. Commercial insolvency under Companies Act. Consumer debtors rely on court processes and negotiation. Minimum subsistence protections in enforcement.',
      overIndebtednessHelp:
          'Malta Competition and Consumer Affairs Authority (MCCAA) handles consumer complaints. Legal aid (Malta Legal Aid Agency) for qualifying residents. Caritas Malta provides financial counseling.',
      fraudProtectionAuthority: 'MFSA (Malta Financial Services Authority)',
      fraudReportingPhone: '+356 2144 1155 (MFSA)',
      fraudReportingWebsite: 'https://www.mfsa.mt',
      commonScamsTargetingImmigrants: [
        'Fake iGaming/fintech job offers (Malta is a gaming hub)',
        'Rental scams (tight housing market, especially Sliema/St Julian\'s)',
        'Fake cryptocurrency/forex brokers (some use Malta\'s fintech reputation)',
        'Employment agency fees (illegal but common informally)',
      ],
      scamPreventionTips: [
        'Verify financial licenses at MFSA registry (mfsa.mt)',
        'Check employer registration at Jobs Plus (jobsplus.gov.mt)',
        'Never pay rental deposits without signed contract',
        'Report to police (112) and MFSA',
      ],
      legalBasis:
          'Payment Accounts Regulations L.N. 137/2017, Banking Act, Consumer Affairs Act, MFSA Act, AML Act.',
      financialOmbudsman:
          'Office of the Arbiter for Financial Services. Website: financialarbiter.org.mt. Tel: +356 2124 9245. Free, independent, decisions binding.',
      immigrantSpecificNotes:
          'Malta is English-speaking — major advantage for banking and integration. AWAS handles asylum seeker welfare. Identity Malta issues eResidence cards. Migrants\' Network Malta and Integra Foundation provide integration support. Housing is a major challenge (small island, limited supply, high rents). iGaming sector employs many immigrants. Foundation for the Promotion of Entrepreneurial Initiatives (FPEI) supports immigrant entrepreneurs.',
    ),

    // ===================================================================
    // NETHERLANDS
    // ===================================================================
    'NL': const FinancialAccessInfo(
      country: 'Netherlands',
      countryCode: 'NL',
      basicAccountRight: true,
      basicAccountDirectiveStatus:
          'Transposed via Wet op het financieel toezicht (Wft) amendments 2016. All legal residents entitled to basic payment account (basisbetaalrekening). DNB (De Nederlandsche Bank) oversees. Netherlands has strong tradition of banking access — near 100% banked population.',
      documentsForBankAccount: [
        'Valid passport or national ID',
        'BSN (Burgerservicenummer — Citizen Service Number)',
        'Proof of Dutch address (BRP registration)',
        'For asylum seekers: W-document or Verblijfsdocument from IND + V-number',
        'For recognized refugees: Verblijfsvergunning + BSN',
      ],
      banksForAsylumSeekers: [
        'ING — largest bank, accepts W-documents and asylum seeker documentation',
        'ABN AMRO — opens accounts for asylum seekers with COA documentation',
        'Rabobank — cooperative bank, regional branches often serve asylum seekers',
        'SNS Bank (de Volksbank) — accessible to asylum seekers',
      ],
      banksForUndocumented: [
        'Very difficult without BSN. BSN requires legal registration.',
        'Stichting LOS (Landelijk Ongedocumenteerden Steunpunt) may assist.',
        'Prepaid cards available at some locations without BSN.',
      ],
      bestBanksForImmigrants: [
        'ING — largest bank, excellent English service, strong app, easy to open with BSN',
        'ABN AMRO — good expat services, English online banking, competitive fees',
        'Rabobank — cooperative, strong community presence, mortgage-friendly',
        'Bunq — Dutch digital bank, fully English, EUR IBAN, easy setup, eco-friendly',
        'N26 — German IBAN, fully English, popular with internationals',
        'Revolut — English, EUR IBAN, popular among immigrants',
        'Wise — multi-currency, EUR IBAN, Dutch IBAN available',
      ],
      bankAccountNotes:
          'BSN (Citizen Service Number) is ESSENTIAL for banking in Netherlands. Get it by registering at your gemeente (municipality) — appointment at Burgerzaken. Without BSN, banking is nearly impossible. Netherlands has a very cashless society — bank account is essential for daily life. iDEAL payment system (linked to Dutch bank accounts) is used for virtually all online payments. Bunq and N26 are popular English-language alternatives.',
      moneyTransferServices: [
        'Wise — online/app, Dutch IBAN available',
        'Western Union — at post offices and agents',
        'MoneyGram — agent locations',
        'Remitly — online/app',
        'WorldRemit — online/app',
        'Ria — agents in major cities',
      ],
      cheapestRemittanceOptions:
          'Wise for most corridors (0.3-1.5%). For Suriname/Morocco/Turkey (large diaspora), Ria and WorldRemit are competitive. For Indonesia (historical ties), Wise and Remitly work well. SEPA transfers within EU free.',
      taxIdName: 'BSN (Burgerservicenummer) — serves as tax ID',
      taxIdHowToGet:
          'Automatically assigned when registering at your gemeente (municipality). Visit Burgerzaken department of your local gemeente with passport, rental contract, and birth certificate (apostilled). Processing: same day (appointment required). BSN printed on your BRP registration document.',
      socialSecurityNumber: 'BSN — same number for everything (tax, social security, healthcare, banking)',
      socialSecurityHowToGet:
          'Same as above — BSN issued upon gemeente registration. UWV (Employee Insurance Agency) and SVB (Social Insurance Bank) use BSN for all social security. Employer handles declarations.',
      taxObligationsForImmigrants:
          'Residents taxed on worldwide income (Box 1, 2, 3 system). Box 1 (income): progressive 36.97% (up to EUR 75,518), 49.50% (above). Box 2 (substantial holdings): 24.5%-33%. Box 3 (savings/investments): tax on deemed return. Social contributions integrated in Box 1 rates. 30% ruling for qualifying expats (30% of salary tax-free for up to 5 years — very valuable). Annual return due May 1.',
      taxFilingDeadline: 'May 1 for previous year. Extension available. Electronic via Mijn Belastingdienst.',
      taxAuthorityWebsite: 'https://www.belastingdienst.nl',
      taxAuthorityPhone: '0800-0543 (free, from Netherlands) / +31 55 538 5385',
      consumerCreditRights:
          'EU Consumer Credit Directive transposed. AFM (Autoriteit Financiële Markten) supervises conduct. BKR (Bureau Krediet Registratie) is THE credit registry — records all loans and defaults. SECCI mandatory. 14-day withdrawal. Responsible lending strictly enforced. Maximum credit cost (maximale kredietvergoeding) set annually.',
      creditHistoryBuilding:
          'BKR (Bureau Krediet Registratie) in Tiel is the central credit registry. Records all credit agreements (positive) and defaults (negative). New immigrants start with no BKR file. Steps: get BSN, open bank account, get employment, after stable employment period request credit card or phone contract on installment. BKR-free products (like Klarna/Afterpay for small amounts) do not build BKR history. Request free BKR report at mijnbkr.nl.',
      debtProtectionLaws:
          'Wet schuldsanering natuurlijke personen (WSNP — Natural Persons Debt Rescheduling Act). Municipal debt assistance (gemeentelijke schuldhulpverlening) is a legal right since 2012 (Wgs). WSNP: court-supervised, 18 months (reduced from 3 years in 2023), then discharge. Beslagvrije voet (seizure-free foot): approximately 95% of bijstand level protected from creditors.',
      overIndebtednessHelp:
          'Gemeentelijke schuldhulpverlening — every gemeente MUST offer free debt assistance (Wet gemeentelijke schuldhulpverlening). Contact your local gemeente. NVVK members provide certified debt counseling. Juridisch Loket provides free legal advice. Schuldhulpmaatje: trained volunteer debt coaches.',
      fraudProtectionAuthority: 'AFM (Autoriteit Financiële Markten) / ACM (Authority for Consumers and Markets)',
      fraudReportingPhone: '0900-7000 (Meld Misdaad Anoniem — report crime anonymously)',
      fraudReportingWebsite: 'https://www.afm.nl / https://www.fraudehelpdesk.nl',
      commonScamsTargetingImmigrants: [
        'Fake BSN/gemeente registration services (always go directly to gemeente)',
        'Housing scams — huge housing crisis means desperate people pay for non-existent rooms (kamerverhuur fraude)',
        'Phishing SMS/email pretending to be from ING, ABN AMRO, or Belastingdienst',
        'Fake 30% ruling advisors charging excessive fees',
        'WhatsApp fraud (hijo/hija scam: "Hi mama, I have a new number, can you transfer money?")',
        'Spoofed phone calls from "ING fraud department" asking for credentials',
        'Fake DigiD messages requesting login (DigiD is government digital identity)',
      ],
      scamPreventionTips: [
        'BSN registration at gemeente is FREE — never pay intermediaries',
        'NEVER share DigiD credentials with anyone — government never requests them by phone/email/SMS',
        'Verify housing through official channels, view in person, never pay before signing contract',
        'Banks never call to ask for your full bank details or ask you to transfer money for "safety"',
        'Check AFM registers for licensed financial providers: afm.nl/registers',
        'Report to police (0900-8844) and Fraudehelpdesk (fraudehelpdesk.nl)',
        '30% ruling application is through your employer — no consultant needed',
      ],
      legalBasis:
          'Wet op het financieel toezicht (Wft), Burgerlijk Wetboek (consumer credit), WSNP (debt restructuring), Wet gemeentelijke schuldhulpverlening (Wgs), Wwft (AML).',
      financialOmbudsman:
          'Kifid (Klachteninstituut Financiële Dienstverlening). Website: www.kifid.nl. Tel: 0900-3552248. Free for consumers. Independent dispute resolution for all financial products.',
      immigrantSpecificNotes:
          'Netherlands is very cashless — bank account + iDEAL are essential for daily life. 30% ruling is extremely valuable for qualifying knowledge migrants (ask employer to apply). VluchtelingenWerk Nederland provides comprehensive integration support for refugees. UAF (University Assistance Fund) helps refugee education. Pharos (expertise center on health and migration) addresses financial stress. IN Amsterdam and other cities offer newcomer integration programs. Housing is the biggest challenge — register immediately at all housing corporations. Gemeente debt help is a LEGAL RIGHT — use it if needed.',
    ),

    // ===================================================================
    // POLAND
    // ===================================================================
    'PL': const FinancialAccessInfo(
      country: 'Poland',
      countryCode: 'PL',
      basicAccountRight: true,
      basicAccountDirectiveStatus:
          'Transposed via amendments to the Payment Services Act (Ustawa o usługach płatniczych) 2017. Legal residents entitled to basic payment account (podstawowy rachunek płatniczy). KNF (Komisja Nadzoru Finansowego — Financial Supervision Authority) oversees.',
      documentsForBankAccount: [
        'Valid passport or national ID',
        'PESEL number (Powszechny Elektroniczny System Ewidencji Ludności)',
        'Proof of Polish address (zameldowanie or utility bill)',
        'For asylum seekers: Tymczasowe zaświadczenie tożsamości cudzoziemca (temporary identity certificate)',
        'For recognized refugees: Karta pobytu (residence card) + PESEL',
        'For Ukrainian refugees under temporary protection: PESEL UKR + Ukrainian passport',
      ],
      banksForAsylumSeekers: [
        'PKO Bank Polski — largest bank, accepts asylum seeker documents, has Ukrainian-language support',
        'Bank Pekao — accepts diverse foreign documentation',
        'mBank — flexible document requirements, English online banking',
        'Santander Bank Polska — has served asylum seekers',
      ],
      banksForUndocumented: [
        'Very difficult without PESEL. Most banks require it.',
        'Some prepaid cards obtainable with passport only.',
        'Stowarzyszenie Interwencji Prawnej (Association for Legal Intervention) may assist.',
      ],
      bestBanksForImmigrants: [
        'PKO BP — largest bank, widest network, Ukrainian/English support, IKO app',
        'mBank — excellent English online banking, zero-fee accounts, fully digital setup',
        'Santander Bank Polska — international brand, English service',
        'Millennium Bank — English app, competitive for immigrants',
        'Revolut — extremely popular in Poland, English/Ukrainian, PLN and EUR support',
        'Wise — multi-currency, PLN support, excellent for remittances',
        'ZEN — Polish fintech, multi-currency, easy setup',
      ],
      bankAccountNotes:
          'Poland uses PLN (złoty). PESEL number is essential — foreigners get it from the local Urząd Gminy (commune office) upon registering residence, or from Urząd Wojewódzki (voivodeship office). Since 2022, Ukrainian refugees receive PESEL UKR automatically. Polish banking is modern with excellent mobile apps. mBank is widely recommended for English-speaking immigrants. Basic account (PRP) free for 5 ATM withdrawals + unlimited transfers per month.',
      moneyTransferServices: [
        'Wise — online/app, competitive PLN rates',
        'Western Union — at various agents and Poczta Polska',
        'MoneyGram — agent locations',
        'Remitly — online/app',
        'Paysend — online/app, popular for Ukraine transfers',
        'BLIK — Polish mobile payment system (between Polish bank accounts)',
      ],
      cheapestRemittanceOptions:
          'Wise for most corridors (0.4-1.5%). For Ukraine (massive diaspora, 2M+ since 2022), Wise and Paysend compete on rates. For Vietnam, Philippines, India, Remitly offers good rates. BLIK is free between Polish banks.',
      taxIdName: 'NIP (Numer Identyfikacji Podatkowej) for self-employed / PESEL for employees',
      taxIdHowToGet:
          'PESEL: issued automatically when registering residence at Urząd Gminy. NIP: for self-employed, apply at the local Urząd Skarbowy (tax office) with passport + PESEL + registration form. Processing: immediate to 7 days.',
      socialSecurityNumber: 'PESEL — serves as universal identifier for social security (ZUS)',
      socialSecurityHowToGet:
          'PESEL issued upon residence registration at Urząd Gminy. ZUS (Zakład Ubezpieczeń Społecznych — Social Insurance Institution) uses PESEL. Employer registers you with ZUS. Self-employed register directly.',
      taxObligationsForImmigrants:
          'Residents (183+ days or center of vital interests) taxed on worldwide income. Progressive PIT: 12% (up to PLN 120,000) + 32% (above). Flat tax option for self-employed: 19%. Lump-sum (ryczałt) available for certain activities. Social contributions (ZUS): approximately 13.71% employee + approximately 20% employer. Annual PIT due April 30.',
      taxFilingDeadline: 'April 30 for previous year (electronic via e-PIT at podatki.gov.pl).',
      taxAuthorityWebsite: 'https://www.podatki.gov.pl',
      taxAuthorityPhone: '+48 22 330 03 30 (KIS — National Tax Information)',
      consumerCreditRights:
          'EU Consumer Credit Directive transposed. KNF supervises. BIK (Biuro Informacji Kredytowej) is the main credit bureau. SECCI mandatory. 14-day withdrawal. Maximum non-interest costs capped by law. Strong responsible lending requirements.',
      creditHistoryBuilding:
          'BIK (Biuro Informacji Kredytowej) maintains comprehensive credit data (positive and negative). BIG (Biura Informacji Gospodarczej) track payment defaults. New immigrants start with no BIK history. Steps: get PESEL, open bank account (mBank free), stable employment for 6+ months, then apply for credit card. BIK score request available at bik.pl. Polish banks increasingly lend to foreigners with stable employment.',
      debtProtectionLaws:
          'Consumer bankruptcy (upadłość konsumencka) under Prawo upadłościowe (Bankruptcy Law). Significantly simplified since 2020 reform. Court-supervised repayment plan up to 36 months, then discharge. Quick-track liquidation option. Minimum living expenses protected from enforcement. Komornik (bailiff) enforcement has debtor protections.',
      overIndebtednessHelp:
          'Free legal aid: Punkty Nieodpłatnej Pomocy Prawnej (Free Legal Advice Points) in every powiat. RPO (Rzecznik Praw Obywatelskich — Ombudsman) for systemic issues. UOKiK (consumer protection office) handles financial complaints. Caritas and other organizations assist immigrants.',
      fraudProtectionAuthority: 'KNF (Komisja Nadzoru Finansowego) / UOKiK (Office of Competition and Consumer Protection)',
      fraudReportingPhone: '+48 22 262 58 00 (KNF)',
      fraudReportingWebsite: 'https://www.knf.gov.pl / https://www.uokik.gov.pl',
      commonScamsTargetingImmigrants: [
        'Fake PESEL/residence registration services charging for free government services',
        'Unlicensed money lenders (chwilówki/quick loans online) with extreme interest',
        'Fake job agency fees (especially for Ukrainians — recruitment fees are illegal)',
        'Apartment rental scams on OLX.pl and Facebook (advance deposits for non-existent rooms)',
        'Phishing targeting PKO BP and mBank customers',
        'Fake immigration lawyer services',
        'SMS scams claiming packages from InPost require payment',
      ],
      scamPreventionTips: [
        'PESEL registration at Urząd Gminy is FREE — never pay intermediaries',
        'Recruitment agencies cannot legally charge workers in Poland',
        'Check KNF registers for licensed lenders — many "chwilówki" companies are unlicensed',
        'View apartments in person before paying — use verified platforms',
        'InPost and Poczta Polska never demand payment via suspicious SMS links',
        'Report to police (112/997) and KNF/UOKiK',
      ],
      legalBasis:
          'Payment Services Act, Banking Law, Consumer Credit Act, Bankruptcy Law, AML Act, Act on Consumer Rights.',
      financialOmbudsman:
          'Rzecznik Finansowy (Financial Ombudsman). Website: www.rf.gov.pl. Tel: +48 22 333 73 26. Free, independent. Also: Arbiter Bankowy (Banking Arbiter) at ZBP for disputes up to PLN 12,000.',
      immigrantSpecificNotes:
          'Poland has received over 2 million Ukrainian refugees since 2022 — most banks have adapted with Ukrainian-language services and simplified processes. PESEL UKR is issued automatically to Ukrainian refugees. Polish banking apps (IKO, mBank) are among the best in Europe. BLIK is the dominant mobile payment system — essential for daily life. Fundacja Ocalenie and Stowarzyszenie Interwencji Prawnej provide free integration support. Free legal advice points (NPP) available in every district — find them at np.ms.gov.pl.',
    ),

    // ===================================================================
    // PORTUGAL
    // ===================================================================
    'PT': const FinancialAccessInfo(
      country: 'Portugal',
      countryCode: 'PT',
      basicAccountRight: true,
      basicAccountDirectiveStatus:
          'Transposed via Decreto-Lei n.º 107/2017. All legal residents entitled to conta de serviços mínimos bancários (minimum banking services account). Max annual fee EUR 4.68 (indexed). Banco de Portugal oversees.',
      documentsForBankAccount: [
        'Valid passport or national ID',
        'NIF (Número de Identificação Fiscal — tax number)',
        'Proof of Portuguese address (comprovativo de morada)',
        'For asylum seekers: Autorização de residência provisória from SEF/AIMA',
        'For recognized refugees: Título de residência + NIF',
        'For digital nomads/D7 visa: Visa + NIF + proof of address',
      ],
      banksForAsylumSeekers: [
        'Caixa Geral de Depósitos (CGD) — state bank, most accessible, accepts AIMA documentation',
        'Millennium BCP — has served asylum seekers',
        'Novo Banco — accepts diverse documentation',
      ],
      banksForUndocumented: [
        'NIF can be obtained by anyone (even undocumented) — through a fiscal representative.',
        'With NIF + passport, some banks may open limited accounts.',
        'CGD as state bank is most likely to comply with minimum services account rules.',
        'JRS (Jesuit Refugee Service) Portugal assists with financial access.',
      ],
      bestBanksForImmigrants: [
        'CGD (Caixa Geral de Depósitos) — state bank, widest network, accepts diverse documents, English support in tourist areas',
        'ActivoBank — free digital account, English app, part of Millennium BCP',
        'Millennium BCP — largest private bank, English service in Lisbon/Porto',
        'Moey — Portuguese digital bank, free, easy setup, English',
        'N26 — German IBAN, fully English, popular with digital nomads',
        'Revolut — EUR IBAN, English, very popular in Portugal',
        'Wise — multi-currency, Portuguese IBAN available',
      ],
      bankAccountNotes:
          'NIF (tax number) is the KEY to everything in Portugal. Get it from Finanças (tax office) or online via Portal das Finanças. Non-residents need a fiscal representative (representante fiscal) to get NIF — many services offer this for EUR 50-150. Conta de serviços mínimos bancários costs max EUR 4.68/year and includes debit card + transfers. ActivoBank and Moey offer free accounts. Portugal is very popular with digital nomads — D7 and Digital Nomad visas available.',
      moneyTransferServices: [
        'Wise — online/app',
        'Western Union — at CTT (post offices)',
        'MoneyGram — agent locations',
        'Remitly — online/app',
        'WorldRemit — online/app',
        'Ria — agents',
      ],
      cheapestRemittanceOptions:
          'Wise for most corridors (0.3-1.5%). For Brazil (massive diaspora), Wise, Remitly, and Western Union compete aggressively. For Cape Verde, Angola, Mozambique (Lusophone Africa), Wise and MoneyGram have good reach. SEPA transfers free within EU.',
      taxIdName: 'NIF (Número de Identificação Fiscal)',
      taxIdHowToGet:
          'Apply at Finanças (Serviço de Finanças / Loja do Cidadão) with passport. Non-residents need a fiscal representative. Can also apply online via Portal das Finanças (portaldasfinancas.gov.pt). Cost: free. Processing: same day in person. NIF is needed for EVERYTHING in Portugal.',
      socialSecurityNumber: 'NISS (Número de Identificação da Segurança Social)',
      socialSecurityHowToGet:
          'Apply at Segurança Social office or online at seg-social.pt with NIF, passport, and employment contract. Employer handles for employees. Self-employed register directly. Processing: 1-2 weeks.',
      taxObligationsForImmigrants:
          'Residents (183+ days) taxed on worldwide income. Progressive IRS rates: 13%-48%. NHR (Non-Habitual Resident) regime: flat 20% on Portuguese employment income + exemption on most foreign income for 10 years (being phased out for new applicants from 2024, replaced by tax incentive for scientific research/innovation). Social contributions: 11% employee + 23.75% employer. Annual declaration (IRS) due June 30.',
      taxFilingDeadline: 'April 1 - June 30 for previous year (electronic via Portal das Finanças).',
      taxAuthorityWebsite: 'https://www.portaldasfinancas.gov.pt',
      taxAuthorityPhone: '+351 217 206 707 (AT — Autoridade Tributária)',
      consumerCreditRights:
          'EU Consumer Credit Directive transposed. Banco de Portugal supervises. Central de Responsabilidades de Crédito (CRC) at Banco de Portugal tracks all credit. SECCI mandatory. 14-day withdrawal. Maximum APR varies by product.',
      creditHistoryBuilding:
          'CRC (Central de Responsabilidades de Crédito) at Banco de Portugal records all credit obligations. New immigrants: get NIF, open bank account (ActivoBank free), establish employment, after 6-12 months request credit. Portuguese banks are relatively open to immigrants with stable income. NHR status holders often get favorable treatment.',
      debtProtectionLaws:
          'PERSI (Procedimento Extrajudicial de Regularização de Situações de Incumprimento) — mandatory pre-litigation process for defaulted credit. RERE (Regime Extrajudicial de Recuperação de Empresas) for businesses. Personal insolvency (insolvência de pessoa singular) under CIRE — court-supervised. Minimum subsistence protected.',
      overIndebtednessHelp:
          'DECO Proteste (consumer association) provides free debt counseling. Gabinete de Apoio ao Sobreendividado (GAS) at DECO. Banco de Portugal publishes consumer guides. Legal aid (apoio judiciário) available for qualifying residents. ACM (Alto Comissariado para as Migrações) assists immigrants.',
      fraudProtectionAuthority: 'Banco de Portugal / CMVM (Securities Market Commission) / ASAE (Food and Economic Security Authority)',
      fraudReportingPhone: '808 200 250 (Banco de Portugal) / 808 202 520 (DECO)',
      fraudReportingWebsite: 'https://www.bportugal.pt / https://www.cmvm.pt',
      commonScamsTargetingImmigrants: [
        'Fake NIF services charging EUR 300+ (official NIF is free, fiscal representative costs EUR 50-150)',
        'Golden Visa fraud (fake investment schemes promising residency)',
        'Rental scams in Lisbon/Porto (extremely tight market) — advance payments for non-existent apartments',
        'Fake "NHR advisors" charging excessive fees for basic tax registration',
        'Phishing emails impersonating Finanças/AT or CGD bank',
        'Fake D7/Digital Nomad visa services',
      ],
      scamPreventionTips: [
        'NIF is free at Finanças — fiscal representative should cost EUR 50-150 maximum',
        'Golden Visa requires investment through regulated channels — verify with SEF/AIMA',
        'View apartments in person — Lisbon/Porto scams are rampant, especially on Idealista/OLX',
        'NHR/tax registration can be done directly at Finanças or via reputable accountant (contabilista certificado)',
        'Check Banco de Portugal registry for licensed financial entities',
        'Report to police (112) and Banco de Portugal',
      ],
      legalBasis:
          'DL 107/2017 (minimum banking services), RGICSF (credit institutions regime), Consumer Credit DL 133/2009, CIRE (insolvency code), AML Law 83/2017.',
      financialOmbudsman:
          'Banco de Portugal (banking complaints). CMVM (investment complaints). Provedor de Justiça (national ombudsman). DECO Proteste for consumer advocacy.',
      immigrantSpecificNotes:
          'Portugal is extremely popular with immigrants (Brazilian, Ukrainian, Indian, Nepalese, Cape Verdean, Angolan communities). ACM (Alto Comissariado para as Migrações) is the main integration body — provides one-stop shops (CNAIM) in Lisbon and Porto. SEF restructured into AIMA (2023) for immigration services. ActivoBank and Moey are excellent free banking options. NHR regime (though being modified) is still attractive for qualifying new residents. Portuguese language skills help enormously — free courses available through Portugal Acolhe program.',
    ),

    // ===================================================================
    // ROMANIA
    // ===================================================================
    'RO': const FinancialAccessInfo(
      country: 'Romania',
      countryCode: 'RO',
      basicAccountRight: true,
      basicAccountDirectiveStatus:
          'Transposed via OUG 3/2017 and Law 258/2017. Legal residents entitled to basic payment account (cont de plăți cu servicii de bază). BNR (National Bank of Romania) oversees. Max fee RON 125/year.',
      documentsForBankAccount: [
        'Valid passport or national ID',
        'CNP (Cod Numeric Personal — Personal Numerical Code) or NIF for foreigners',
        'Proof of Romanian address',
        'For asylum seekers: Identity document from IGI (General Inspectorate for Immigration)',
        'For recognized refugees: Residence permit + CNP',
      ],
      banksForAsylumSeekers: [
        'Banca Transilvania — largest bank, accepts asylum documentation',
        'BCR (Banca Comercială Română, Erste Group) — accepts diverse documents',
        'BRD (Société Générale group) — has served asylum seekers',
      ],
      banksForUndocumented: [
        'Very limited without valid ID and CNP/NIF.',
        'ARCA (Romanian Forum for Refugees and Migrants) may assist in emergency cases.',
      ],
      bestBanksForImmigrants: [
        'Banca Transilvania — largest bank, modern app, some English support',
        'BCR (Erste Group) — international network, George app, English service',
        'ING Romania — competitive digital banking, English support',
        'Revolut — extremely popular in Romania, English/Romanian, RON and EUR',
        'Wise — multi-currency, competitive RON rates',
      ],
      bankAccountNotes:
          'Romania uses RON (leu). EUR adoption planned but delayed. CNP for Romanians, NIF for foreigners — get NIF from ANAF (tax authority) or through IGI. Romanian banking is modern with excellent mobile apps. Revolut has massive adoption in Romania (one of the highest per capita in Europe). Basic account rights guaranteed by law.',
      moneyTransferServices: [
        'Wise — online/app, competitive RON rates',
        'Western Union — at various agents and Poșta Română',
        'MoneyGram — agents throughout Romania',
        'Remitly — online/app',
        'Paysend — online/app',
      ],
      cheapestRemittanceOptions:
          'Wise for most corridors. Romania has a massive diaspora (3-4M abroad) — money flows primarily INTO Romania. For Moldova, SEPA (Moldovan banks with EUR accounts) or Wise. Paysend competitive for various corridors.',
      taxIdName: 'NIF (Număr de Identificare Fiscală) for foreigners / CNP for Romanian citizens',
      taxIdHowToGet:
          'Apply at ANAF (Agenția Națională de Administrare Fiscală) with passport and proof of address. Processing: 1-5 days. Also obtainable through IGI during residence permit process.',
      socialSecurityNumber: 'CNP (Cod Numeric Personal) — issued to foreigners with residence permits',
      socialSecurityHowToGet:
          'CNP for foreigners issued by IGI (General Inspectorate for Immigration) along with residence permit. Employer uses CNP for CNPP (pension) and CNAS (health) declarations.',
      taxObligationsForImmigrants:
          'Residents (183+ days or center of vital interests) taxed on worldwide income. Flat income tax: 10%. Social contributions: pension 25% + health 10% (both on employee, but effectively split). Micro-enterprise tax: 1% of revenue (favorable for small businesses). Annual return due May 25. Romania has very competitive personal tax rates.',
      taxFilingDeadline: 'May 25 for previous year (Declarație unică — single declaration).',
      taxAuthorityWebsite: 'https://www.anaf.ro',
      taxAuthorityPhone: '+40 31 403 91 60 (ANAF)',
      consumerCreditRights:
          'EU Consumer Credit Directive transposed. BNR supervises. Biroul de Credit (Credit Bureau) maintained by banks. SECCI mandatory. 14-day withdrawal. Debt-to-income ratio capped at 40% for consumer credit.',
      creditHistoryBuilding:
          'Biroul de Credit (Romanian Credit Bureau) records positive and negative data. New immigrants: open bank account, establish income, after 6-12 months apply for credit. Romanian banks check Biroul de Credit and may request home country credit references. Flat 10% tax means more disposable income — banks consider this.',
      debtProtectionLaws:
          'Law 151/2015 on personal insolvency (insolvența persoanelor fizice). Three procedures: insolvency based on repayment plan, simplified insolvency, and judicial insolvency. ANPC (consumer protection) handles complaints. Minimum living standard protected from enforcement.',
      overIndebtednessHelp:
          'ANPC (Autoritatea Națională pentru Protecția Consumatorilor) handles consumer complaints. Free legal aid (ajutor public judiciar) for low-income residents. ARCA and JRS Romania assist refugees with financial matters.',
      fraudProtectionAuthority: 'BNR (National Bank of Romania) / ANPC (Consumer Protection Authority)',
      fraudReportingPhone: '+40 21 9551 (ANPC)',
      fraudReportingWebsite: 'https://www.anpc.gov.ro / https://www.bnr.ro',
      commonScamsTargetingImmigrants: [
        'Fake residence permit services',
        'Online quick-loan scams (credite rapide) with extreme interest',
        'Apartment scams on OLX.ro',
        'Fake employer agencies charging fees',
        'Phishing targeting Banca Transilvania and BCR customers',
      ],
      scamPreventionTips: [
        'Check BNR registry for licensed credit providers',
        'IGI handles all residence permits directly — no intermediaries needed',
        'View apartments before paying',
        'Report to police (112) and ANPC',
      ],
      legalBasis:
          'OUG 3/2017, Law 258/2017 (basic accounts), Banking Law, Consumer Credit Law, Law 151/2015 (personal insolvency), AML Law 129/2019.',
      financialOmbudsman:
          'ANPC handles consumer financial complaints. BNR for banking supervision issues. SAL-FIN (Alternative Dispute Resolution Entity) for financial disputes.',
      immigrantSpecificNotes:
          'Romania has flat 10% income tax — one of the lowest in the EU. Cost of living is low. Growing immigrant population (especially from South/Southeast Asia for labor). ARCA and JRS Romania provide integration support. Revolut is essentially a second national bank — over 4M Romanian users. IT sector employs many immigrants with favorable micro-enterprise tax (1%). Romanian language is essential for integration — free courses through local DGASPC.',
    ),

    // ===================================================================
    // SLOVAKIA
    // ===================================================================
    'SK': const FinancialAccessInfo(
      country: 'Slovakia',
      countryCode: 'SK',
      basicAccountRight: true,
      basicAccountDirectiveStatus:
          'Transposed via Act on Payment Services (492/2009 Z.z.) amendments 2016. Legal residents entitled to basic payment account (základný bankový produkt). NBS (Národná banka Slovenska) oversees. Max fee set annually.',
      documentsForBankAccount: [
        'Valid passport or national ID',
        'Slovak birth number (rodné číslo) or temporary residence number',
        'Proof of Slovak address',
        'For asylum seekers: Preukaz žiadateľa o azyl (asylum seeker card)',
        'For recognized refugees: Doklad o tolerovanom pobyte or residence permit',
      ],
      banksForAsylumSeekers: [
        'Slovenská sporiteľňa (Erste Group) — accepts asylum seeker documentation',
        'VÚB Banka (Intesa Sanpaolo) — basic accounts for asylum seekers',
        'Tatra banka — limited but available',
      ],
      banksForUndocumented: [
        'Very limited without valid ID and registration number.',
        'Slovak Humanitarian Council (Slovenská humanitná rada) may assist.',
      ],
      bestBanksForImmigrants: [
        'Slovenská sporiteľňa — largest bank, Erste Group, George app, some English support',
        'Tatra banka — best digital banking in Slovakia, English app',
        'VÚB — Intesa Sanpaolo group, international service',
        'Revolut — popular, English, EUR IBAN (Slovakia uses EUR since 2009)',
        'Wise — multi-currency, EUR IBAN',
      ],
      bankAccountNotes:
          'Slovakia uses EUR since 2009. Rodné číslo (birth number) for Slovaks, temporary identification number for foreigners — issued by foreigners police. Banking is modern with good digital options. Tatra banka consistently rated best digital bank. Basic account guaranteed by law.',
      moneyTransferServices: [
        'Wise — online/app',
        'Western Union — at Slovenská pošta (post offices)',
        'MoneyGram — limited agents',
        'Paysend — online/app',
      ],
      cheapestRemittanceOptions:
          'Wise for most corridors. SEPA transfers free within EU. For Ukraine/Serbia, Wise and Paysend competitive. Slovakia uses EUR, simplifying eurozone transfers.',
      taxIdName: 'DIČ (Daňové identifikačné číslo) / Rodné číslo for individuals',
      taxIdHowToGet:
          'DIČ assigned by tax office (Daňový úrad) upon registration. Foreigners register at local tax office with passport and residence proof. Processing: immediate to 7 days.',
      socialSecurityNumber: 'Rodné číslo — also serves as social insurance identifier at Sociálna poisťovňa',
      socialSecurityHowToGet:
          'Foreigners receive identification number from foreigners police upon registering residence. Sociálna poisťovňa (Social Insurance Agency) uses this for all social security. Employer handles registration.',
      taxObligationsForImmigrants:
          'Residents taxed on worldwide income. Progressive PIT: 19% (up to EUR 47,537.98) and 25% (above). Social contributions: approximately 13.4% employee + 35.2% employer. Annual return due March 31 (extendable to June 30). Slovakia has competitive tax rates.',
      taxFilingDeadline: 'March 31 (extendable to June 30) for previous year.',
      taxAuthorityWebsite: 'https://www.financnasprava.sk',
      taxAuthorityPhone: '+421 48 431 7222',
      consumerCreditRights:
          'EU Consumer Credit Directive transposed. NBS supervises. SBCB (Slovak Banking Credit Bureau) maintains credit registry. SECCI mandatory. 14-day withdrawal. Strong responsible lending requirements (debt-to-income limits).',
      creditHistoryBuilding:
          'SBCB (Slovak Banking Credit Bureau) and NBCB (Non-Banking Credit Bureau) track credit data. New immigrants: open bank account, stable employment, after 6-12 months apply for credit. Slovak banks have strict debt-to-income requirements — usually 60% max.',
      debtProtectionLaws:
          'Personal bankruptcy (oddlženie) under Act 7/2005 (Insolvency Act) reformed in 2017. Two paths: repayment plan (splátkový kalendár, 3 years) or bankruptcy (konkurz, immediate asset liquidation). Very accessible — costs approximately EUR 500 (state covers for low-income). Protected minimum income.',
      overIndebtednessHelp:
          'Centrum právnej pomoci (Centre for Legal Aid) — free legal assistance including debt matters. Website: www.centrumpravnejpomoci.sk. NBS consumer protection. Slovak Humanitarian Council for refugees.',
      fraudProtectionAuthority: 'NBS (Národná banka Slovenska)',
      fraudReportingPhone: '+421 2 5787 1100 (NBS)',
      fraudReportingWebsite: 'https://www.nbs.sk',
      commonScamsTargetingImmigrants: [
        'Fake residence registration services',
        'Unlicensed non-banking lenders with extreme rates',
        'Apartment scams (especially in Bratislava)',
        'Fake employment agencies',
      ],
      scamPreventionTips: [
        'Check NBS registry for licensed financial providers',
        'Foreigners police handles residence registration directly',
        'View apartments before paying deposits',
        'Report to police (158) and NBS',
      ],
      legalBasis:
          'Act 492/2009 on Payment Services, Banking Act 483/2001, Consumer Credit Act 129/2010, Insolvency Act 7/2005, AML Act 297/2008.',
      financialOmbudsman:
          'NBS handles financial consumer complaints. Also: SOI (Slovak Trade Inspection) for consumer disputes. Centrum právnej pomoci for low-income residents.',
      immigrantSpecificNotes:
          'Slovakia uses EUR — simplifies finances for eurozone immigrants. Cost of living lower than neighboring Austria. Growing immigrant population (especially from Serbia, Ukraine, Vietnam). IOM Slovakia provides integration support. Centrum právnej pomoci provides FREE legal aid including financial matters. Slovak language is essential for integration — courses available through local integration centers.',
    ),

    // ===================================================================
    // SLOVENIA
    // ===================================================================
    'SI': const FinancialAccessInfo(
      country: 'Slovenia',
      countryCode: 'SI',
      basicAccountRight: true,
      basicAccountDirectiveStatus:
          'Transposed via Payment Services, Services for Issuing Electronic Money and Payment Systems Act (ZPlaSSIED) 2018. Legal residents entitled to basic payment account. Banka Slovenije (Bank of Slovenia) oversees.',
      documentsForBankAccount: [
        'Valid passport or national ID',
        'Slovenian tax number (davčna številka)',
        'Proof of Slovenian address',
        'For asylum seekers: Izkaznica prosilca za mednarodno zaščito (asylum seeker card)',
        'For recognized refugees: Dovoljenje za prebivanje (residence permit)',
      ],
      banksForAsylumSeekers: [
        'NLB (Nova Ljubljanska Banka) — largest bank, accepts asylum seeker documentation',
        'Nova KBM (Intesa Sanpaolo) — accepts diverse documents',
        'SKB (OTP group) — available to asylum seekers',
      ],
      banksForUndocumented: [
        'Very limited without tax number.',
        'PIC (Legal-Informational Centre for NGOs) may assist.',
      ],
      bestBanksForImmigrants: [
        'NLB — largest bank, widest network, some English support',
        'Nova KBM — part of Intesa Sanpaolo, international service',
        'Revolut — popular, English, EUR IBAN (Slovenia uses EUR since 2007)',
        'Wise — multi-currency, EUR IBAN',
        'N26 — German IBAN, English',
      ],
      bankAccountNotes:
          'Slovenia uses EUR since 2007. Small country with limited bank choices but well-regulated. Tax number (davčna številka) essential — get from FURS (tax authority). Banking is straightforward but may require Slovenian language for some paperwork. NLB dominates the market.',
      moneyTransferServices: [
        'Wise — online/app',
        'Western Union — at Pošta Slovenije (post offices)',
        'MoneyGram — limited agents',
      ],
      cheapestRemittanceOptions:
          'Wise for most corridors. SEPA transfers within EU free. For Bosnia/Serbia/Kosovo (significant diaspora origins), Wise and bank SEPA transfers where available.',
      taxIdName: 'Davčna številka (Tax Number)',
      taxIdHowToGet:
          'Apply at FURS (Finančna uprava Republike Slovenije) with passport and residence proof. Processing: 1-7 days. Can also be obtained at Upravna enota (administrative unit).',
      socialSecurityNumber: 'EMŠO (Enotna matična številka občana — Unique Master Citizen Number)',
      socialSecurityHowToGet:
          'EMŠO issued by Upravna enota (administrative unit) when registering residence. Used for all social security (ZPIZ pension, ZZZS health). Employer handles declarations.',
      taxObligationsForImmigrants:
          'Residents taxed on worldwide income. Progressive PIT: 16%-50% (5 brackets). Social contributions: approximately 22.1% employee + 16.1% employer. Annual return due March 31 (pre-filled return reviewed by May 31).',
      taxFilingDeadline: 'March 31 for previous year. Pre-filled returns reviewed by May 31.',
      taxAuthorityWebsite: 'https://www.fu.gov.si',
      taxAuthorityPhone: '+386 8 200 1001 (FURS)',
      consumerCreditRights:
          'EU Consumer Credit Directive transposed. Banka Slovenije supervises. SISBON credit bureau. SECCI mandatory. 14-day withdrawal.',
      creditHistoryBuilding:
          'SISBON (Informacijski sistem za oceno bonitete strank) operated by Bank of Slovenia. Records all credit data. New immigrants: open bank account, stable employment, after 6-12 months apply for credit. Slovenian banks are conservative but fair.',
      debtProtectionLaws:
          'Personal bankruptcy (osebni stečaj) under ZFPPIPP (Financial Operations, Insolvency Proceedings and Compulsory Dissolution Act). Court-supervised, discharge after 2-5 years. Protected minimum income.',
      overIndebtednessHelp:
          'Banka Slovenije consumer protection. Free legal aid (brezplačna pravna pomoč) at district courts. PIC NGO assists vulnerable groups including immigrants.',
      fraudProtectionAuthority: 'Banka Slovenije / ATVP (Securities Market Agency)',
      fraudReportingPhone: '+386 1 471 90 00 (Banka Slovenije)',
      fraudReportingWebsite: 'https://www.bsi.si',
      commonScamsTargetingImmigrants: [
        'Fake residence permit services',
        'Quick-loan scams',
        'Rental scams in Ljubljana',
      ],
      scamPreventionTips: [
        'Verify financial providers at Banka Slovenije registry',
        'Use only official channels for residence permits (Upravna enota)',
        'Report to police (113) and Banka Slovenije',
      ],
      legalBasis:
          'ZPlaSSIED (payment services), ZBan-3 (banking), ZPotK-2 (consumer credit), ZFPPIPP (insolvency), ZPPDFT (AML).',
      financialOmbudsman:
          'Banka Slovenije handles banking complaints. Also: European Consumer Centre Slovenia for cross-border disputes.',
      immigrantSpecificNotes:
          'Slovenia is small, safe, and uses EUR. PIC (Pravno-informacijski center) provides free legal assistance to immigrants. IOM Slovenia assists with integration. Cost of living moderate (lower than Austria/Italy but higher than Croatia/Hungary). Slovenian language essential for integration — free courses available. Slovenian Philanthropy (Slovenska filantropija) works with refugees on integration including financial literacy.',
    ),

    // ===================================================================
    // SPAIN
    // ===================================================================
    'ES': const FinancialAccessInfo(
      country: 'Spain',
      countryCode: 'ES',
      basicAccountRight: true,
      basicAccountDirectiveStatus:
          'Transposed via Real Decreto-ley 19/2017. All legal residents AND persons in vulnerable situations (even without legal residence) entitled to cuenta de pago básica. Banco de España oversees. Max fee EUR 3/month. Spain is among the most generous implementations.',
      documentsForBankAccount: [
        'Valid passport or national ID',
        'NIE (Número de Identidad de Extranjero) — for all foreigners',
        'Empadronamiento (municipal registration — padrón) — available to everyone regardless of immigration status',
        'For asylum seekers: Tarjeta roja (red card) or resguardo de solicitud',
        'For undocumented: Passport + empadronamiento — some banks accept this for basic account',
        'For recognized refugees: Tarjeta de residencia + NIE',
      ],
      banksForAsylumSeekers: [
        'CaixaBank — most accessible, MicroBank program specifically for vulnerable populations',
        'Bankia (now CaixaBank) — had refugee inclusion programs',
        'BBVA — accepts tarjeta roja for basic accounts',
        'Santander — accepts asylum documentation',
        'Banco Sabadell — has served asylum seekers',
      ],
      banksForUndocumented: [
        'CaixaBank/MicroBank — most open to undocumented persons with passport + empadronamiento',
        'BBVA — has opened accounts with passport + empadronamiento in some regions',
        'Empadronamiento is KEY — available to everyone regardless of legal status from your Ayuntamiento (town hall)',
        'Spanish law does not explicitly require legal residence for basic account — interpretation varies',
      ],
      bestBanksForImmigrants: [
        'CaixaBank — largest bank, MicroBank for financial inclusion, widest ATM network, multilingual service',
        'BBVA — excellent digital banking, English app, competitive fees, open to immigrants',
        'Santander — international bank, English service, Openbank digital subsidiary is free',
        'Openbank (Santander) — free digital bank, English, no branch needed',
        'N26 — Spanish IBAN, fully English, popular with digital nomads',
        'Revolut — English, EUR IBAN, popular',
        'Wise — multi-currency, Spanish IBAN available',
        'Imagin (CaixaBank) — free digital bank for under-30s',
      ],
      bankAccountNotes:
          'Spain has very strong financial inclusion. Empadronamiento (padrón municipal) is available to EVERYONE — even undocumented persons — from your local Ayuntamiento. This is the key document for many services including banking. NIE is the standard foreigner ID number — get it from the Oficina de Extranjería or police station. CaixaBank through MicroBank is specifically mission-driven for financial inclusion of vulnerable populations. Openbank and Imagin offer free fully digital accounts.',
      moneyTransferServices: [
        'Wise — online/app, Spanish IBAN',
        'Western Union — at Correos (post offices) and thousands of agents',
        'MoneyGram — extensive agent network',
        'Remitly — online/app',
        'WorldRemit — online/app',
        'Ria (Spain-headquartered) — huge agent network',
        'Small World — popular for Latin America',
      ],
      cheapestRemittanceOptions:
          'Wise for bank transfers (0.3-1.5%). Ria (headquartered in Madrid) is competitive for Latin America and offers good cash pickup rates. For Morocco (large diaspora), Ria, Western Union, and Azimo compete. For Ecuador, Colombia, Dominican Republic, Remitly and Small World are competitive. Spain has one of highest remittance outflows in EU — providers compete aggressively.',
      taxIdName: 'NIE (Número de Identidad de Extranjero) — serves as tax ID for foreigners',
      taxIdHowToGet:
          'Apply at the Oficina de Extranjería or Comisaría de Policía (foreigners department). Bring: EX-15 form, passport, proof of reason (employment contract, property purchase, etc.), fee (approximately EUR 12, Tasa 790-012). Processing: 1-4 weeks depending on office. Can also apply at Spanish consulates abroad. Essential for everything in Spain.',
      socialSecurityNumber: 'Número de afiliación a la Seguridad Social (NAF)',
      socialSecurityHowToGet:
          'Apply at Tesorería General de la Seguridad Social office with NIE, passport, and employment contract. Can also apply online via sede.seg-social.gob.es. Employer often handles. Processing: 1-3 days. Autonomous workers (autónomos) register directly.',
      taxObligationsForImmigrants:
          'Residents (183+ days or center of economic interests) taxed on worldwide income. Progressive IRPF: 19%-47% (varies by Comunidad Autónoma — regional surcharges). Social security: approximately 6.35% employee + approximately 30% employer. Annual declaración de la renta due June 30. Beckham Law (régimen de impatriados): qualifying workers can opt for flat 24% tax for 6 years (very valuable). Modelo 720: mandatory disclosure of foreign assets >EUR 50,000.',
      taxFilingDeadline: 'April - June 30 for previous year (electronic via Agencia Tributaria Renta Web).',
      taxAuthorityWebsite: 'https://www.agenciatributaria.es',
      taxAuthorityPhone: '901 33 55 33 / +34 91 554 87 70',
      consumerCreditRights:
          'EU Consumer Credit Directive transposed. Banco de España supervises. CIRBE (Central de Información de Riesgos) at Banco de España tracks all credit above EUR 1,000. ASNEF-Equifax and Experian for negative data. SECCI mandatory. 14-day withdrawal. Strong usury law (Ley Azcárate 1908) — courts can void abusive interest rates.',
      creditHistoryBuilding:
          'CIRBE (Banco de España) records credit exposures above EUR 1,000. ASNEF-Equifax records defaults. New immigrants: get NIE, open bank account, empadronamiento, employment. After 6-12 months of stable income, apply for credit card. Spanish banks consider nómina (payroll) deposits heavily — having salary direct-deposited is key. Request CIRBE report free at Banco de España.',
      debtProtectionLaws:
          'Ley de Segunda Oportunidad (Second Chance Law, 2015, reformed 2022) — personal insolvency with debt discharge. Mediación concursal (mediation) first, then concurso de acreedores (creditor agreement). Discharge of unsatisfied debts possible including (since 2022) public debts up to EUR 10,000. Minimum living income (SMI-based) protected from seizure.',
      overIndebtednessHelp:
          'Free debt counseling: OMIC (Oficinas Municipales de Información al Consumidor) in most municipalities. ADICAE (consumer finance association). Caritas Economato provides emergency financial assistance. Free legal aid (asistencia jurídica gratuita) for qualifying residents — apply at Colegio de Abogados.',
      fraudProtectionAuthority: 'Banco de España / CNMV (Comisión Nacional del Mercado de Valores)',
      fraudReportingPhone: '900 545 454 (Banco de España) / 091 (police)',
      fraudReportingWebsite: 'https://www.bde.es / https://www.cnmv.es',
      commonScamsTargetingImmigrants: [
        'Fake NIE appointment services charging EUR 100-500 (NIE costs EUR 12 officially)',
        'Fake empadronamiento services (free at your Ayuntamiento)',
        'Rental scams (especially Barcelona/Madrid) — deposits for non-existent apartments on Idealista/Fotocasa',
        'Cláusulas suelo and abusive mortgage terms (for immigrant property buyers)',
        'Fake employment contracts used to obtain residence permits (paper jobs)',
        'Door-to-door energy/telecom salespeople with abusive contract terms',
        'WhatsApp/Bizum scams (fake payments for second-hand items)',
        'Fake regularization (arraigo) services promising papers for money',
      ],
      scamPreventionTips: [
        'NIE appointment can be made free at sede.administracionespublica.gob.es — many resellers exist but official process costs only EUR 12',
        'Empadronamiento is FREE at your Ayuntamiento — no intermediary needed',
        'Never pay apartment deposits before visiting and signing a contrato de alquiler',
        'Beckham Law application goes through Agencia Tributaria — verify advisor credentials',
        'Verify financial entities at Banco de España registry (bde.es)',
        'Report to Policía Nacional (091) and OMIC consumer offices',
        'Free legal aid (abogado de oficio) available — ask at Colegio de Abogados',
      ],
      legalBasis:
          'RDL 19/2017 (basic accounts), Ley 16/2011 (consumer credit), Ley 25/2015 (Second Chance), Ley 10/2010 (AML), Código de Comercio.',
      financialOmbudsman:
          'Banco de España Servicio de Reclamaciones (banking). CNMV for investment. Dirección General de Seguros for insurance. All free. Response within 4 months.',
      immigrantSpecificNotes:
          'Spain is one of the most financially inclusive EU countries for immigrants. Empadronamiento is the master key — get it immediately, even without legal residence. CaixaBank/MicroBank specifically targets financial inclusion. Large Latin American community (language advantage), Moroccan, Romanian, Chinese, and Sub-Saharan African communities with established support networks. CEAR (Comisión Española de Ayuda al Refugiado) provides comprehensive refugee support. Red Acoge network in many cities offers integration help. Beckham Law is very valuable for qualifying expat workers (24% flat tax).',
    ),

    // ===================================================================
    // SWEDEN
    // ===================================================================
    'SE': const FinancialAccessInfo(
      country: 'Sweden',
      countryCode: 'SE',
      basicAccountRight: true,
      basicAccountDirectiveStatus:
          'Transposed via Lag om betalkonton (Payment Accounts Act, 2017:631). All legal residents entitled to basic payment account (betalkonto med grundläggande funktioner). Finansinspektionen (FI) oversees. Sweden was one of the first to implement broad banking access.',
      documentsForBankAccount: [
        'Valid passport or national ID',
        'Swedish personal identity number (personnummer) — highly desirable but not strictly required for basic account',
        'Samordningsnummer (coordination number) accepted by some banks for basic accounts',
        'For asylum seekers: LMA-kort (asylum seeker card from Migrationsverket) + samordningsnummer',
        'For recognized refugees: Uppehållstillstånd (residence permit) + personnummer',
      ],
      banksForAsylumSeekers: [
        'Swedbank — accepts LMA-kort for basic payment accounts',
        'SEB — opens basic accounts for asylum seekers',
        'Nordea — accepts samordningsnummer and asylum documentation',
        'Handelsbanken — local branches have discretion, some serve asylum seekers',
      ],
      banksForUndocumented: [
        'Very limited. Swedish banking system is personnummer-centric.',
        'Samordningsnummer (coordination number) is a partial solution — available to people without personnummer.',
        'Prepaid cards (ICA Banken prepaid) available without personnummer.',
        'Ingen Människa Är Illegal (No Person Is Illegal) network may advise.',
      ],
      bestBanksForImmigrants: [
        'Swedbank — largest bank, widest branch/ATM network, accessible to asylum seekers',
        'SEB — strong digital platform, English support, good for expats',
        'Nordea — large Nordic bank, English service, competitive expat packages',
        'Klarna (bank license) — Swedish fintech, fully English, easy setup',
        'Revolut — popular among immigrants, English, SEK and EUR support',
        'Wise — multi-currency, competitive SEK rates, excellent for remittances',
        'Lunar — Nordic digital bank, English, easy setup',
      ],
      bankAccountNotes:
          'Sweden uses SEK (krona) and is the most cashless society in the EU — bank account + Swish (mobile payment) are ESSENTIAL for daily life. Personnummer (from Skatteverket/Tax Agency) is the key to everything — apply immediately upon arrival. Without personnummer, banking is very difficult. Samordningsnummer is a temporary alternative. BankID (digital identity, tied to bank account) is required for virtually all online services in Sweden. The catch-22: you need a bank account for BankID, but many services need BankID to verify identity.',
      moneyTransferServices: [
        'Wise — online/app, competitive SEK rates',
        'Western Union — at Forex Bank locations and agents',
        'MoneyGram — limited agents',
        'Remitly — online/app',
        'Ria — agents in major cities',
        'Swish — domestic mobile payments between Swedish bank accounts (not for international)',
      ],
      cheapestRemittanceOptions:
          'Wise for most corridors (0.4-1.5%). For Somalia/Eritrea/Iraq (large Swedish diaspora communities), Dahabshiil has offices in Stockholm, Gothenburg, Malmö. For Syria, Wise or bank transfers where possible. Swish is free for domestic person-to-person payments.',
      taxIdName: 'Personnummer (Personal Identity Number) — serves as tax ID',
      taxIdHowToGet:
          'Apply at Skatteverket (Swedish Tax Agency) after registering residence. Bring: passport, residence/work permit, proof of residence (hyreskontrakt), family documents. Processing: 2-4 weeks (can be longer). Personnummer format: YYYYMMDD-XXXX. Without it, apply for samordningsnummer as interim solution.',
      socialSecurityNumber: 'Personnummer — same number for all purposes (tax, social security, healthcare, banking)',
      socialSecurityHowToGet:
          'Same as above — personnummer from Skatteverket. Försäkringskassan (Social Insurance Agency) uses personnummer for all benefits. Register at Försäkringskassan after getting personnummer to access social insurance.',
      taxObligationsForImmigrants:
          'Residents taxed on worldwide income. Municipal tax: approximately 29-35% (varies by kommun). State tax: 20% above SEK 598,500. Total marginal rate can exceed 55%. SINK (Special Income Tax for Non-Residents): flat 25%. Expert tax relief: 25% of salary tax-free for qualifying foreign experts/researchers for up to 7 years. Annual declaration due May 2.',
      taxFilingDeadline: 'May 2 for previous year. Pre-filled return (deklaration) from Skatteverket reviewed/amended via Skatteverket app or website.',
      taxAuthorityWebsite: 'https://www.skatteverket.se',
      taxAuthorityPhone: '0771-567 567 (Skatteverket)',
      consumerCreditRights:
          'EU Consumer Credit Directive transposed. Finansinspektionen (FI) supervises. UC (Upplysningscentralen) is the dominant credit bureau. 14-day withdrawal. Responsible lending requirements. Interest rate limits on quick loans (snabblån).',
      creditHistoryBuilding:
          'UC (Upplysningscentralen, now part of Bisnode/Dun & Bradstreet) is the main credit bureau. Records income, debts, payment defaults (betalningsanmärkning). A betalningsanmärkning stays 3 years and severely limits all financial access. New immigrants: get personnummer, open bank account, register income with Skatteverket, after 1-2 years of clean record credit becomes accessible. UC credit report free once/year at uc.se.',
      debtProtectionLaws:
          'Skuldsanering (debt restructuring) via Kronofogden (Swedish Enforcement Authority). Qualifying debtors get 5-year repayment plan, then full discharge. F-skuldsanering (business debt restructuring) also available. Beneficium (protected property) — essential items cannot be seized. Minimum subsistence (förbehållsbelopp) protected.',
      overIndebtednessHelp:
          'Kronofogden (www.kronofogden.se) handles both enforcement and debt restructuring — contact them for skuldsanering. Budget- och skuldrådgivning: free budget and debt counseling at every kommun (municipal debt advisor). Konsumentverket (Consumer Agency) provides financial guidance.',
      fraudProtectionAuthority: 'Finansinspektionen (FI) / Konsumentverket (Consumer Agency)',
      fraudReportingPhone: '114 14 (police non-emergency) / 0771-42 33 00 (Konsumentverket)',
      fraudReportingWebsite: 'https://www.fi.se / https://www.polisen.se/utsatt-for-brott/anmal-brott',
      commonScamsTargetingImmigrants: [
        'BankID scams (fraudsters call pretending to be bank, ask to verify BankID — NEVER do this)',
        'Fake Skatteverket/Migrationsverket calls requesting personnummer and payment',
        'Swish scams (fake sellers on Blocket requesting Swish payment then disappearing)',
        'Fake personnummer registration services (Skatteverket is free)',
        'Apartment rental scams (tight housing market, especially Stockholm) — deposits for non-existent apartments on Blocket/Facebook',
        'Quick loan (snabblån) traps with extreme interest targeting people rejected by banks',
        'Investment scams in immigrant communities (crypto/forex)',
      ],
      scamPreventionTips: [
        'NEVER verify BankID when someone calls you — banks NEVER ask you to do this',
        'Skatteverket and Migrationsverket never request payment by phone',
        'Personnummer registration at Skatteverket is FREE — never pay third parties',
        'View apartments in person before paying. Use official channels (bostadsförmedling).',
        'Check FI registry for licensed financial providers (fi.se)',
        'Beware of snabblån — always check total cost and ÅOP (APR)',
        'Report to police (114 14 or polisen.se) and Konsumentverket',
      ],
      legalBasis:
          'Lag om betalkonton 2017:631, Konsumentkreditlagen 2010:1846, Skuldsaneringslagen 2016:675, Lag om bank- och finansieringsrörelse, Penningtvättlagen.',
      financialOmbudsman:
          'ARN (Allmänna Reklamationsnämnden — National Board for Consumer Disputes). Website: www.arn.se. Free. Also: Konsumenternas Bank- och Finansbyrå for banking advice. Konsumenternas Försäkringsbyrå for insurance.',
      immigrantSpecificNotes:
          'Sweden is essentially cashless — Swish and BankID are required for daily life. Get personnummer from Skatteverket as absolute first priority. Arbetsförmedlingen (Employment Agency) assists with job placement. Kommunens flyktingmottagning (municipal refugee reception) provides comprehensive integration. SFI (Swedish for Immigrants) language courses are free and essential. Expert tax relief (expertskatt) is very valuable for qualifying workers. Large Somali, Eritrean, Iraqi, Syrian, Afghan communities with support networks. Stockholm housing queue (bostadskö) can take 10-20 years — register immediately.',
    ),

    // ===================================================================
    // Remaining countries with essential data
    // ===================================================================

    // LUXEMBOURG already included above

    // ===================================================================
    // PORTUGAL already included above
    // ===================================================================

    // ===================================================================
    // ROMANIA already included above
    // ===================================================================
  };
}
