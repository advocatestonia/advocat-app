// Insurance & Pension Rights Database for all 27 EU Countries
// Real data for immigrant insurance obligations and pension rights
// Last updated: 2026-04
//
// Sources: EU Regulation 883/2004 (social security coordination),
// EU Regulation 987/2009 (implementing regulation), OECD Pensions at a Glance 2024,
// European Commission MISSOC database (Mutual Information System on Social Protection),
// EIOPA (European Insurance and Occupational Pensions Authority),
// national social security institution publications, Insurance Europe statistics,
// EU Motor Insurance Directive 2009/103/EC, national pension authority data,
// TRESS network reports (Training and Reporting on European Social Security).

class InsuranceType {
  final String type;
  final bool mandatory;
  final String averageMonthlyCost;
  final String description;
  final String howToGetAsImmigrant;

  const InsuranceType({
    required this.type,
    required this.mandatory,
    required this.averageMonthlyCost,
    required this.description,
    required this.howToGetAsImmigrant,
  });

  Map<String, dynamic> toMap() => {
    'type': type,
    'mandatory': mandatory,
    'averageMonthlyCost': averageMonthlyCost,
    'description': description,
    'howToGetAsImmigrant': howToGetAsImmigrant,
  };
}

class PensionInfo {
  final String systemType;
  final String pillar1;
  final String pillar2;
  final String pillar3;
  final int retirementAge;
  final int retirementAgeWomen;
  final int minimumContributionYears;
  final String averageStatePensionMonthly;
  final String minimumPensionMonthly;
  final String maximumPensionMonthly;
  final String contributionRate;
  final String pensionAuthorityName;
  final String pensionAuthorityWebsite;
  final String pensionAuthorityPhone;

  const PensionInfo({
    required this.systemType,
    required this.pillar1,
    required this.pillar2,
    required this.pillar3,
    required this.retirementAge,
    required this.retirementAgeWomen,
    required this.minimumContributionYears,
    required this.averageStatePensionMonthly,
    required this.minimumPensionMonthly,
    required this.maximumPensionMonthly,
    required this.contributionRate,
    required this.pensionAuthorityName,
    required this.pensionAuthorityWebsite,
    required this.pensionAuthorityPhone,
  });

  Map<String, dynamic> toMap() => {
    'systemType': systemType,
    'pillar1': pillar1,
    'pillar2': pillar2,
    'pillar3': pillar3,
    'retirementAge': retirementAge,
    'retirementAgeWomen': retirementAgeWomen,
    'minimumContributionYears': minimumContributionYears,
    'averageStatePensionMonthly': averageStatePensionMonthly,
    'minimumPensionMonthly': minimumPensionMonthly,
    'maximumPensionMonthly': maximumPensionMonthly,
    'contributionRate': contributionRate,
    'pensionAuthorityName': pensionAuthorityName,
    'pensionAuthorityWebsite': pensionAuthorityWebsite,
    'pensionAuthorityPhone': pensionAuthorityPhone,
  };
}

class ImmigrantPensionRights {
  final String rightsForEuCitizens;
  final String rightsForThirdCountryNationals;
  final String minimumResidenceForStatePension;
  final String crossBorderCoordination;
  final String whatHappensIfYouLeave;
  final String howToClaimFromAbroad;
  final String pensionExportRules;
  final String voluntaryContributions;
  final String pensionTransferOptions;
  final String bilateralAgreements;

  const ImmigrantPensionRights({
    required this.rightsForEuCitizens,
    required this.rightsForThirdCountryNationals,
    required this.minimumResidenceForStatePension,
    required this.crossBorderCoordination,
    required this.whatHappensIfYouLeave,
    required this.howToClaimFromAbroad,
    required this.pensionExportRules,
    required this.voluntaryContributions,
    required this.pensionTransferOptions,
    required this.bilateralAgreements,
  });

  Map<String, dynamic> toMap() => {
    'rightsForEuCitizens': rightsForEuCitizens,
    'rightsForThirdCountryNationals': rightsForThirdCountryNationals,
    'minimumResidenceForStatePension': minimumResidenceForStatePension,
    'crossBorderCoordination': crossBorderCoordination,
    'whatHappensIfYouLeave': whatHappensIfYouLeave,
    'howToClaimFromAbroad': howToClaimFromAbroad,
    'pensionExportRules': pensionExportRules,
    'voluntaryContributions': voluntaryContributions,
    'pensionTransferOptions': pensionTransferOptions,
    'bilateralAgreements': bilateralAgreements,
  };
}

class CarInsuranceInfo {
  final bool mandatory;
  final String minimumCoverage;
  final String averageAnnualCostTPL;
  final String averageAnnualCostFullCoverage;
  final String greenCardRequired;
  final String foreignLicenseRules;
  final String noClaimsDiscountTransfer;
  final String howToGetAsImmigrant;
  final String majorProviders;

  const CarInsuranceInfo({
    required this.mandatory,
    required this.minimumCoverage,
    required this.averageAnnualCostTPL,
    required this.averageAnnualCostFullCoverage,
    required this.greenCardRequired,
    required this.foreignLicenseRules,
    required this.noClaimsDiscountTransfer,
    required this.howToGetAsImmigrant,
    required this.majorProviders,
  });

  Map<String, dynamic> toMap() => {
    'mandatory': mandatory,
    'minimumCoverage': minimumCoverage,
    'averageAnnualCostTPL': averageAnnualCostTPL,
    'averageAnnualCostFullCoverage': averageAnnualCostFullCoverage,
    'greenCardRequired': greenCardRequired,
    'foreignLicenseRules': foreignLicenseRules,
    'noClaimsDiscountTransfer': noClaimsDiscountTransfer,
    'howToGetAsImmigrant': howToGetAsImmigrant,
    'majorProviders': majorProviders,
  };
}

class CountryInsurancePension {
  final String country;
  final String countryCode;
  final List<InsuranceType> mandatoryInsurance;
  final List<InsuranceType> recommendedInsurance;
  final PensionInfo pension;
  final ImmigrantPensionRights immigrantPensionRights;
  final CarInsuranceInfo carInsurance;
  final String healthInsuranceSystem;
  final String healthInsuranceCostEmployee;
  final String healthInsuranceCostSelfEmployed;
  final String socialSecurityOverview;
  final String legalBasis;
  final String immigrantSpecificNotes;

  const CountryInsurancePension({
    required this.country,
    required this.countryCode,
    required this.mandatoryInsurance,
    required this.recommendedInsurance,
    required this.pension,
    required this.immigrantPensionRights,
    required this.carInsurance,
    required this.healthInsuranceSystem,
    required this.healthInsuranceCostEmployee,
    required this.healthInsuranceCostSelfEmployed,
    required this.socialSecurityOverview,
    required this.legalBasis,
    required this.immigrantSpecificNotes,
  });

  Map<String, dynamic> toMap() => {
    'country': country,
    'countryCode': countryCode,
    'mandatoryInsurance': mandatoryInsurance.map((i) => i.toMap()).toList(),
    'recommendedInsurance': recommendedInsurance.map((i) => i.toMap()).toList(),
    'pension': pension.toMap(),
    'immigrantPensionRights': immigrantPensionRights.toMap(),
    'carInsurance': carInsurance.toMap(),
    'healthInsuranceSystem': healthInsuranceSystem,
    'healthInsuranceCostEmployee': healthInsuranceCostEmployee,
    'healthInsuranceCostSelfEmployed': healthInsuranceCostSelfEmployed,
    'socialSecurityOverview': socialSecurityOverview,
    'legalBasis': legalBasis,
    'immigrantSpecificNotes': immigrantSpecificNotes,
  };
}

class InsurancePensionDatabase {

  // ============================================================
  // EU REGULATION 883/2004 - CROSS-BORDER COORDINATION RULES
  // ============================================================

  static const String euRegulation883Summary = '''
EU Regulation 883/2004 on the coordination of social security systems ensures that
people moving within the EU do not lose their social security rights. Key principles:

1. SINGLE LEGISLATION: You are subject to the legislation of one country at a time,
   generally where you work (lex loci laboris).

2. EQUAL TREATMENT: You have the same rights and obligations as nationals of the
   country where you are insured.

3. AGGREGATION: Periods of insurance, work, or residence in other EU countries count
   when determining your right to benefits. If you worked 10 years in Germany and
   5 years in France, both periods count toward your pension in each country.

4. EXPORT OF BENEFITS: Cash benefits (especially pensions) can be paid regardless of
   where you live in the EU. Your pension follows you.

5. GOOD ADMINISTRATION: Institutions must cooperate and assist each other. Claims
   submitted in one country are treated as if submitted in all relevant countries.

Applies to: EU/EEA citizens and, under Regulation 1231/2010, third-country nationals
who have legally resided in an EU country and moved between EU states.

Key forms:
- S1: Right to healthcare in country of residence (posted workers, pensioners)
- P1: Summary of pension decisions
- U1: Periods of insurance for unemployment benefits
- E205/P5000: Record of insurance periods for pension claims
''';

  // ============================================================
  // COUNTRY DATA - ALL 27 EU MEMBER STATES
  // ============================================================

  static const List<CountryInsurancePension> allCountries = [

    // ============================================================
    // 1. AUSTRIA (AT)
    // ============================================================
    CountryInsurancePension(
      country: 'Austria',
      countryCode: 'AT',
      mandatoryInsurance: [
        InsuranceType(
          type: 'Health Insurance',
          mandatory: true,
          averageMonthlyCost: 'Employee: ~7.65% of gross salary (shared with employer). Self-employed: ~7.65% via SVS',
          description: 'Mandatory social health insurance through regional health insurance funds (OGK). Covers GP visits, hospital, prescriptions, dental basics.',
          howToGetAsImmigrant: 'Automatic enrollment when you start employment. Self-employed register with SVS. Non-working immigrants must arrange private insurance or qualify via family co-insurance.',
        ),
        InsuranceType(
          type: 'Car Insurance (TPL)',
          mandatory: true,
          averageMonthlyCost: '50-120 EUR/month (third-party liability)',
          description: 'Kfz-Haftpflichtversicherung mandatory for all registered vehicles. Minimum coverage 7.6 million EUR for personal injury.',
          howToGetAsImmigrant: 'Need valid residence permit, Austrian vehicle registration. Foreign no-claims bonus sometimes accepted. Compare at durchblicker.at.',
        ),
        InsuranceType(
          type: 'Liability Insurance (Tenants)',
          mandatory: false,
          averageMonthlyCost: '5-15 EUR/month',
          description: 'Private liability (Privathaftpflicht) not legally mandatory but most landlords require it. Covers damage to rented property and third-party claims.',
          howToGetAsImmigrant: 'Available from any Austrian insurer. No residence duration requirement. Allianz, Uniqa, Wiener Stadtische are major providers.',
        ),
      ],
      recommendedInsurance: [
        InsuranceType(
          type: 'Household Insurance',
          mandatory: false,
          averageMonthlyCost: '15-35 EUR/month',
          description: 'Haushaltsversicherung covers contents against fire, theft, water damage. Often includes private liability.',
          howToGetAsImmigrant: 'Widely available. Most landlords strongly recommend or require it.',
        ),
        InsuranceType(
          type: 'Supplementary Health Insurance',
          mandatory: false,
          averageMonthlyCost: '50-200 EUR/month',
          description: 'Private top-up for single rooms, choice of doctor, shorter wait times.',
          howToGetAsImmigrant: 'Available after registration in social insurance. Pre-existing condition waiting periods apply.',
        ),
      ],
      pension: PensionInfo(
        systemType: 'Pay-as-you-go with notional accounts',
        pillar1: 'State pension (Gesetzliche Pensionsversicherung): earnings-related, based on best 40 years of contributions',
        pillar2: 'Occupational pensions (Betriebspensionen): voluntary, offered by some employers, defined benefit or defined contribution',
        pillar3: 'Private pension products (Zukunftsvorsorge): tax-incentivized voluntary savings',
        retirementAge: 65,
        retirementAgeWomen: 60,
        minimumContributionYears: 15,
        averageStatePensionMonthly: '1,750 EUR',
        minimumPensionMonthly: '1,110 EUR (Ausgleichszulage for 30+ years) / 1,004 EUR (single, minimum guarantee)',
        maximumPensionMonthly: '~3,500 EUR',
        contributionRate: '22.8% of gross salary (10.25% employee + 12.55% employer)',
        pensionAuthorityName: 'Pensionsversicherungsanstalt (PVA)',
        pensionAuthorityWebsite: 'www.pv.at',
        pensionAuthorityPhone: '+43 50303',
      ),
      immigrantPensionRights: ImmigrantPensionRights(
        rightsForEuCitizens: 'Full equal treatment under EU Regulation 883/2004. All contribution periods in other EU states count toward Austrian pension via aggregation.',
        rightsForThirdCountryNationals: 'Equal pension rights if legally employed and insured. Bilateral agreements with Turkey, Serbia, Bosnia, etc. for period aggregation.',
        minimumResidenceForStatePension: '15 years of contribution (insurance) periods. Can combine with periods from other EU/bilateral countries.',
        crossBorderCoordination: 'Austria applies EU Regulation 883/2004 strictly. PVA coordinates with foreign institutions automatically when you claim pension.',
        whatHappensIfYouLeave: 'Pension rights are preserved. Austrian pension is exported to any EU/EEA country and most bilateral agreement countries. Contributions are never lost.',
        howToClaimFromAbroad: 'File pension claim in your country of residence. That institution contacts PVA. Or file directly with PVA online or by post.',
        pensionExportRules: 'Full export to EU/EEA/Switzerland. Export to bilateral agreement countries. For other countries, may be subject to 50% reduction for non-Austrian nationals (check bilateral treaties).',
        voluntaryContributions: 'Possible for self-insured persons. 210 EUR/month (2024 rate). Useful to reach 15-year minimum.',
        pensionTransferOptions: 'No lump-sum transfer between countries. Each country pays its portion (pro-rata). You receive separate pensions from each country you worked in.',
        bilateralAgreements: 'Turkey, Serbia, Bosnia-Herzegovina, North Macedonia, Montenegro, Kosovo, India, South Korea, Philippines, Tunisia, Israel, USA, Canada, Australia, Chile, and others.',
      ),
      carInsurance: CarInsuranceInfo(
        mandatory: true,
        minimumCoverage: '7.6M EUR personal injury, 1.27M EUR property damage (among highest in EU)',
        averageAnnualCostTPL: '600-1,400 EUR',
        averageAnnualCostFullCoverage: '1,200-3,000 EUR',
        greenCardRequired: 'Not for EU vehicles. Required for non-EU registered vehicles.',
        foreignLicenseRules: 'EU licenses valid indefinitely. Non-EU licenses valid 6 months, then must convert. Must carry IDP or official translation.',
        noClaimsDiscountTransfer: 'Some insurers accept foreign NCB with proof letter. Not guaranteed.',
        howToGetAsImmigrant: 'Need Meldezettel (registration), valid license. Compare at durchblicker.at or checkfelix.com. Allianz, Generali, Uniqa, Wiener Stadtische are major providers.',
        majorProviders: 'Allianz, Generali, Uniqa, Wiener Stadtische, DONAU, Grazer Wechselseitige',
      ),
      healthInsuranceSystem: 'Mandatory social health insurance (Sozialversicherung). OGK for employees, SVS for self-employed, BVAEB for civil servants.',
      healthInsuranceCostEmployee: '7.65% of gross salary (3.87% employee, 3.78% employer)',
      healthInsuranceCostSelfEmployed: '7.65% of declared income via SVS',
      socialSecurityOverview: 'Total social security contribution ~39.5% (18.12% employee + 21.38% employer). Covers health, pension, unemployment, accident insurance.',
      legalBasis: 'ASVG (General Social Insurance Act), GSVG (Commercial Social Insurance Act), BSVG (Agricultural Social Insurance Act), EU Reg 883/2004',
      immigrantSpecificNotes: 'Immigrants working legally get same social security as Austrians from day one. E-card (health insurance card) issued automatically. Asylum seekers covered by GVS (basic care). Family members co-insured free of charge.',
    ),

    // ============================================================
    // 2. BELGIUM (BE)
    // ============================================================
    CountryInsurancePension(
      country: 'Belgium',
      countryCode: 'BE',
      mandatoryInsurance: [
        InsuranceType(
          type: 'Health Insurance (Mutuelle/Ziekenfonds)',
          mandatory: true,
          averageMonthlyCost: '~13% of gross salary (shared). Personal contribution varies by mutuelle: 5-20 EUR/month',
          description: 'Mandatory enrollment in a mutuelle (health insurance fund). Covers ~75% of medical costs. Patient pays remainder (ticket moderateur).',
          howToGetAsImmigrant: 'Must register with a mutuelle within 3 months of arriving. Choose from: CM/MC, Solidaris/Socialistische, Liberale, Neutraal, or CAAMI/HZIV (state fund). Need residence permit and NISS number.',
        ),
        InsuranceType(
          type: 'Car Insurance (TPL)',
          mandatory: true,
          averageMonthlyCost: '40-100 EUR/month',
          description: 'RC Auto (responsabilite civile) mandatory. Minimum coverage per EU directive.',
          howToGetAsImmigrant: 'Need Belgian registration plates (DIV), valid driving license. Compare at independer.be or topcompare.be.',
        ),
        InsuranceType(
          type: 'Fire Insurance (Renters)',
          mandatory: false,
          averageMonthlyCost: '15-30 EUR/month',
          description: 'Assurance incendie not legally mandatory but virtually all leases require it. Covers fire, water damage, storm, liability to landlord.',
          howToGetAsImmigrant: 'Available immediately. Required for most rental contracts. Ethias, AG Insurance, AXA are common providers.',
        ),
      ],
      recommendedInsurance: [
        InsuranceType(
          type: 'Hospitalization Insurance',
          mandatory: false,
          averageMonthlyCost: '30-80 EUR/month',
          description: 'Covers hospital room supplements and additional medical costs. Some employers provide this.',
          howToGetAsImmigrant: 'Often offered through employer. Can also be purchased individually from mutuelles or private insurers.',
        ),
        InsuranceType(
          type: 'Family Liability Insurance',
          mandatory: false,
          averageMonthlyCost: '5-15 EUR/month',
          description: 'RC Familiale covers personal liability for damage caused to third parties.',
          howToGetAsImmigrant: 'Widely available. Often bundled with fire insurance.',
        ),
      ],
      pension: PensionInfo(
        systemType: 'Pay-as-you-go earnings-related',
        pillar1: 'State pension (Pension legale): earnings-related calculated on career earnings. Full career = 45 years.',
        pillar2: 'Occupational pension (Pension complementaire): common, employer-sponsored group insurance or pension fund',
        pillar3: 'Individual pension savings (Epargne-pension): tax-advantaged up to 1,020 EUR/year (2024) or 1,310 EUR at lower deduction',
        retirementAge: 65,
        retirementAgeWomen: 65,
        minimumContributionYears: 0,
        averageStatePensionMonthly: '1,400 EUR (employee average)',
        minimumPensionMonthly: '1,637 EUR (minimum pension for full 45-year career, employee) / pro-rata if fewer years but minimum 30 years needed',
        maximumPensionMonthly: '~2,900 EUR (employee, 45-year career at ceiling)',
        contributionRate: '16.36% employer contribution for blue-collar / 8.86% for white-collar. Total social security ~38% of gross (13.07% employee + ~25% employer)',
        pensionAuthorityName: 'Service federal des Pensions (SFP) / Federale Pensioendienst',
        pensionAuthorityWebsite: 'www.sfpd.fgov.be',
        pensionAuthorityPhone: '1765 (free from Belgium)',
      ),
      immigrantPensionRights: ImmigrantPensionRights(
        rightsForEuCitizens: 'Full equal treatment. All EU insurance periods count for Belgian pension calculation via aggregation principle.',
        rightsForThirdCountryNationals: 'Equal rights if legally employed. Belgium has bilateral agreements with Morocco, Tunisia, Turkey, DR Congo, and others.',
        minimumResidenceForStatePension: 'No minimum residence for contribution-based pension. Each year of work generates pension rights proportionally. Guaranteed minimum income for elderly (GRAPA) requires 10 years of actual residence including 5 consecutive.',
        crossBorderCoordination: 'SFP handles all cross-border pension coordination. Belgium is frequently involved in cross-border cases (many frontier workers with France, Luxembourg, Netherlands, Germany).',
        whatHappensIfYouLeave: 'All earned pension rights preserved. Belgian pension exported to any country worldwide without reduction for Belgian nationals. For non-EU foreigners, check bilateral agreements.',
        howToClaimFromAbroad: 'Apply through pension institution in your country of residence, which contacts SFP. Can also apply via mypension.be if you have Belgian eID.',
        pensionExportRules: 'Full export to all EU/EEA countries. Export to bilateral agreement countries. For other countries, Belgian nationals always receive full pension; foreigners may face restrictions without bilateral agreement.',
        voluntaryContributions: 'Limited options for voluntary pension insurance in Pillar 1. Pillar 2 and 3 voluntary contributions are common.',
        pensionTransferOptions: 'No transfer of pension capital between countries for Pillar 1. Each country pays its share. Pillar 2 occupational pensions may be transferable within EU (IORP II Directive).',
        bilateralAgreements: 'Morocco, Tunisia, Turkey, DR Congo, Algeria, India, South Korea, USA, Canada, Australia, Japan, Philippines, and others.',
      ),
      carInsurance: CarInsuranceInfo(
        mandatory: true,
        minimumCoverage: '100M EUR combined (among highest globally)',
        averageAnnualCostTPL: '500-1,200 EUR',
        averageAnnualCostFullCoverage: '900-2,500 EUR',
        greenCardRequired: 'Not for EU/EEA vehicles.',
        foreignLicenseRules: 'EU licenses valid. Non-EU licenses valid 6 months (1 year for recognized countries), then must exchange. Belgian theory and practical exams required for conversion from most non-EU countries.',
        noClaimsDiscountTransfer: 'Bonus-malus system abolished in 2004 for individual policies, but insurers still consider claims history. Foreign letter of experience often accepted.',
        howToGetAsImmigrant: 'Need Belgian plates (DIV registration), valid license. Compare at independer.be, TopCompare.be, Assurances.be.',
        majorProviders: 'Ethias, AG Insurance, AXA, Belfius, KBC, P&V, Baloise',
      ),
      healthInsuranceSystem: 'Mandatory social health insurance via mutuelles/ziekenfondsen. INAMI/RIZIV oversees the system. Universal coverage for legal residents.',
      healthInsuranceCostEmployee: '3.55% employee + 3.80% employer (health portion of social security)',
      healthInsuranceCostSelfEmployed: '~20.5% of net professional income (covers all social security including health)',
      socialSecurityOverview: 'Total: ~38% (13.07% employee + ~25% employer). Covers health, pension, unemployment, family allowances, annual vacation, occupational diseases, work accidents.',
      legalBasis: 'Loi coordonnee du 14.07.1994 (health insurance), Royal Decree No. 50 of 1967 (pensions), EU Reg 883/2004',
      immigrantSpecificNotes: 'Belgium requires registration with a mutuelle within 3 months. CAAMI/HZIV is the state fund accepting everyone. Refugees and subsidiary protection holders have full access. Asylum seekers covered by Fedasil/CPAS. GRAPA (guaranteed income for elderly) available for long-term residents.',
    ),

    // ============================================================
    // 3. BULGARIA (BG)
    // ============================================================
    CountryInsurancePension(
      country: 'Bulgaria',
      countryCode: 'BG',
      mandatoryInsurance: [
        InsuranceType(
          type: 'Health Insurance',
          mandatory: true,
          averageMonthlyCost: '8% of gross income (employer: 4.8%, employee: 3.2%)',
          description: 'National Health Insurance Fund (NHIF/NZOK). Covers GP visits, specialist referrals, hospital care, basic dental, prescriptions (partially).',
          howToGetAsImmigrant: 'Automatic when employed. Self-employed and non-working must pay 8% of minimum insurable income (BGN 933 in 2024). Need personal identification number (EGN or LNC for foreigners).',
        ),
        InsuranceType(
          type: 'Car Insurance (TPL)',
          mandatory: true,
          averageMonthlyCost: 'BGN 200-600/year (~100-300 EUR)',
          description: 'Civil liability mandatory. Relatively low cost compared to Western EU.',
          howToGetAsImmigrant: 'Need Bulgarian vehicle registration, valid license. Available from all Bulgarian insurers.',
        ),
      ],
      recommendedInsurance: [
        InsuranceType(
          type: 'Private Health Insurance',
          mandatory: false,
          averageMonthlyCost: 'BGN 50-200/month (~25-100 EUR)',
          description: 'Supplements public system. Faster access, private clinics, better facilities.',
          howToGetAsImmigrant: 'Available from Bulstrad, DZI, Euroins, Allianz Bulgaria.',
        ),
        InsuranceType(
          type: 'Home Insurance',
          mandatory: false,
          averageMonthlyCost: 'BGN 100-400/year (~50-200 EUR)',
          description: 'Property and contents insurance. Covers fire, natural disasters, theft.',
          howToGetAsImmigrant: 'Available to anyone with a rental or ownership agreement.',
        ),
      ],
      pension: PensionInfo(
        systemType: 'Three-pillar system: PAYG + mandatory funded + voluntary',
        pillar1: 'State pension (NOI): earnings-related PAYG. Formula based on individual coefficient and insurance length.',
        pillar2: 'Universal Pension Fund (UPF): mandatory funded pillar for those born after 1959. 5% of insurable income.',
        pillar3: 'Voluntary pension funds: tax-deductible contributions up to BGN 7,920/year',
        retirementAge: 64,
        retirementAgeWomen: 62,
        minimumContributionYears: 15,
        averageStatePensionMonthly: 'BGN 750 (~380 EUR)',
        minimumPensionMonthly: 'BGN 523 (~267 EUR, as of 2024)',
        maximumPensionMonthly: 'BGN 3,400 (~1,740 EUR, 40% of max insurable income)',
        contributionRate: '19.8% for Pillar 1 (employer: 11.02%, employee: 8.78%) + 5% for Pillar 2',
        pensionAuthorityName: 'National Social Security Institute (NOI)',
        pensionAuthorityWebsite: 'www.noi.bg',
        pensionAuthorityPhone: '+359 2 926 1010',
      ),
      immigrantPensionRights: ImmigrantPensionRights(
        rightsForEuCitizens: 'Full equal treatment under EU Regulation 883/2004. EU insurance periods aggregated for Bulgarian pension.',
        rightsForThirdCountryNationals: 'Equal rights if legally employed. Bilateral agreements with several countries including Russia, Ukraine, Moldova, Serbia, North Macedonia.',
        minimumResidenceForStatePension: '15 years of insurance periods. Can combine with EU/bilateral periods.',
        crossBorderCoordination: 'NOI handles cross-border coordination. Aggregation of periods under EU rules.',
        whatHappensIfYouLeave: 'Pillar 1 pension rights preserved and exportable. Pillar 2 mandatory funded pension can be maintained or transferred to foreign pension fund if leaving EU (subject to conditions).',
        howToClaimFromAbroad: 'Apply through institution in country of residence. NOI processes Bulgarian portion.',
        pensionExportRules: 'Full export to EU/EEA. Export to bilateral agreement countries. Bank transfer to foreign accounts.',
        voluntaryContributions: 'Possible through voluntary Pillar 3 funds. Self-insurance for pension also available.',
        pensionTransferOptions: 'Pillar 2 funds can be transferred between Bulgarian pension funds. Cross-border transfer rules under IORP II for occupational pensions.',
        bilateralAgreements: 'Russia, Ukraine, Moldova, Serbia, North Macedonia, Turkey, Israel, South Korea, Canada, and others.',
      ),
      carInsurance: CarInsuranceInfo(
        mandatory: true,
        minimumCoverage: '10.42M EUR personal injury, 2.08M EUR property damage',
        averageAnnualCostTPL: 'BGN 200-600 (100-300 EUR)',
        averageAnnualCostFullCoverage: 'BGN 600-2,000 (300-1,020 EUR)',
        greenCardRequired: 'Not for EU vehicles.',
        foreignLicenseRules: 'EU licenses valid. Non-EU licenses valid 1 year, then must convert. Driving test required for most non-EU conversions.',
        noClaimsDiscountTransfer: 'Bonus-malus system used. Foreign NCB sometimes accepted with documentation.',
        howToGetAsImmigrant: 'Need Bulgarian registration, valid license. Compare at moitepari.bg.',
        majorProviders: 'Bulstrad, DZI, Euroins, Lev Ins, Armeec, Generali Bulgaria',
      ),
      healthInsuranceSystem: 'National Health Insurance Fund (NZOK). Universal coverage for insured persons. Tax-funded with social contributions.',
      healthInsuranceCostEmployee: '3.2% employee + 4.8% employer = 8% total',
      healthInsuranceCostSelfEmployed: '8% of declared monthly income (minimum BGN 933)',
      socialSecurityOverview: 'Total contributions ~32-33% (employer ~19%, employee ~14%). Covers pension, health, unemployment, sickness, maternity.',
      legalBasis: 'Social Security Code (KSO), Health Insurance Act (ZZO), EU Reg 883/2004',
      immigrantSpecificNotes: 'Bulgaria has relatively low insurance costs. Immigrants must register with NZOK. If not employed, must pay health contributions independently or lose coverage after 3 months of non-payment. Re-entry requires paying back 5 years of missed contributions.',
    ),

    // ============================================================
    // 4. CROATIA (HR)
    // ============================================================
    CountryInsurancePension(
      country: 'Croatia',
      countryCode: 'HR',
      mandatoryInsurance: [
        InsuranceType(
          type: 'Health Insurance',
          mandatory: true,
          averageMonthlyCost: '16.5% employer contribution covers health + other social. Employee portion: 0% for health specifically.',
          description: 'Croatian Health Insurance Fund (HZZO). Universal coverage for residents. Covers primary care, hospital, dental basics, prescriptions.',
          howToGetAsImmigrant: 'Automatic when employed. Must register with HZZO with OIB (personal identification number) and residence permit.',
        ),
        InsuranceType(
          type: 'Car Insurance (TPL)',
          mandatory: true,
          averageMonthlyCost: '150-500 EUR/year',
          description: 'Osiguranje od automobilske odgovornosti (AO). Mandatory for all registered vehicles.',
          howToGetAsImmigrant: 'Need Croatian vehicle registration and valid license. Available from Croatia Osiguranje, Euroherc, Allianz Croatia.',
        ),
      ],
      recommendedInsurance: [
        InsuranceType(
          type: 'Supplementary Health Insurance',
          mandatory: false,
          averageMonthlyCost: '10-30 EUR/month',
          description: 'Dopunsko zdravstveno osiguranje covers co-payments (participacija). HZZO offers this for ~10 EUR/month.',
          howToGetAsImmigrant: 'Available from HZZO or private insurers. Covers the 20% co-payment for many services.',
        ),
        InsuranceType(
          type: 'Home Insurance',
          mandatory: false,
          averageMonthlyCost: '10-25 EUR/month',
          description: 'Property and contents. Earthquake coverage recommended (seismic zone).',
          howToGetAsImmigrant: 'Available from all Croatian insurers.',
        ),
      ],
      pension: PensionInfo(
        systemType: 'Two-pillar mandatory + voluntary third pillar',
        pillar1: 'State pension (PAYG): 15% of gross salary. Earnings-related based on personal points.',
        pillar2: 'Mandatory individual accounts: 5% of gross salary (for those who entered labor market after 2002)',
        pillar3: 'Voluntary pension funds with tax incentives (state co-financing up to HRK 750/year)',
        retirementAge: 65,
        retirementAgeWomen: 63,
        minimumContributionYears: 15,
        averageStatePensionMonthly: '450 EUR',
        minimumPensionMonthly: '280 EUR (minimum pension for 15 years)',
        maximumPensionMonthly: '~1,500 EUR',
        contributionRate: '20% total (15% Pillar 1 + 5% Pillar 2). Entire cost on employer.',
        pensionAuthorityName: 'Croatian Pension Insurance Institute (HZMO)',
        pensionAuthorityWebsite: 'www.mirovinsko.hr',
        pensionAuthorityPhone: '+385 1 595 3000',
      ),
      immigrantPensionRights: ImmigrantPensionRights(
        rightsForEuCitizens: 'Full equal treatment under EU Regulation 883/2004 (Croatia joined EU 2013). All EU periods aggregated.',
        rightsForThirdCountryNationals: 'Equal rights if legally employed. Bilateral agreements with successor states of Yugoslavia, Turkey, and others.',
        minimumResidenceForStatePension: '15 years of insurance periods. Aggregation with EU and bilateral treaty countries.',
        crossBorderCoordination: 'HZMO handles cross-border pension claims. EU coordination fully operational since 2013 accession.',
        whatHappensIfYouLeave: 'Pension rights preserved and exportable to EU/EEA. Pillar 2 individual account maintained by chosen pension fund.',
        howToClaimFromAbroad: 'Apply via pension institution in country of residence. HZMO processes Croatian portion.',
        pensionExportRules: 'Full export to EU/EEA and bilateral agreement countries. Pillar 2 paid as annuity or programmed withdrawal at retirement.',
        voluntaryContributions: 'Possible for self-insured persons and through Pillar 3 voluntary funds.',
        pensionTransferOptions: 'Pillar 2 funds remain in Croatia until retirement. No cross-border transfer of Pillar 2.',
        bilateralAgreements: 'Serbia, Bosnia-Herzegovina, Montenegro, North Macedonia, Turkey, Canada, Australia, and others (many inherited from Yugoslavia agreements).',
      ),
      carInsurance: CarInsuranceInfo(
        mandatory: true,
        minimumCoverage: '7.6M EUR personal injury, 1.52M EUR property damage',
        averageAnnualCostTPL: '150-500 EUR',
        averageAnnualCostFullCoverage: '400-1,200 EUR',
        greenCardRequired: 'Not for EU vehicles.',
        foreignLicenseRules: 'EU licenses valid. Non-EU licenses valid 1 year, then must convert.',
        noClaimsDiscountTransfer: 'Bonus-malus system in use. Foreign NCB may be accepted.',
        howToGetAsImmigrant: 'Need Croatian registration. Compare at osiguranje.hr.',
        majorProviders: 'Croatia Osiguranje, Euroherc, Allianz Croatia, Grawe, Generali',
      ),
      healthInsuranceSystem: 'Croatian Health Insurance Fund (HZZO). Universal coverage. Single-payer with co-payments.',
      healthInsuranceCostEmployee: 'Health insurance included in 16.5% employer social contribution',
      healthInsuranceCostSelfEmployed: '16.5% of declared base + supplementary optional',
      socialSecurityOverview: 'Employer pays 16.5% for health + work injury. Employee pays 20% for pension (15% Pillar 1 + 5% Pillar 2). Total ~36.5%.',
      legalBasis: 'Pension Insurance Act, Mandatory Health Insurance Act, EU Reg 883/2004',
      immigrantSpecificNotes: 'Croatia has lower insurance costs than Western EU. Digital nomad visa holders must have private health insurance. EU citizens can use EHIC for temporary stays. OIB number required for all insurance.',
    ),

    // ============================================================
    // 5. CYPRUS (CY)
    // ============================================================
    CountryInsurancePension(
      country: 'Cyprus',
      countryCode: 'CY',
      mandatoryInsurance: [
        InsuranceType(
          type: 'Health Insurance (GESY/GHS)',
          mandatory: true,
          averageMonthlyCost: 'Employee: 2.65% of gross. Employer: 2.90%. Self-employed: 4.0%.',
          description: 'General Healthcare System (GESY/GHS) launched 2019. Universal coverage for all legal residents. Covers GP, specialists, hospital, prescriptions, dental, mental health.',
          howToGetAsImmigrant: 'Register at gesy.org.cy with residence permit and social insurance number. Choose a personal doctor (GP). Coverage begins immediately upon registration.',
        ),
        InsuranceType(
          type: 'Car Insurance (TPL)',
          mandatory: true,
          averageMonthlyCost: '300-800 EUR/year',
          description: 'Motor third-party liability insurance mandatory under Motor Vehicles Act.',
          howToGetAsImmigrant: 'Need Cyprus vehicle registration. Drive on left side. UK-style system.',
        ),
      ],
      recommendedInsurance: [
        InsuranceType(
          type: 'Home/Contents Insurance',
          mandatory: false,
          averageMonthlyCost: '15-40 EUR/month',
          description: 'Covers property damage, theft, fire. Earthquake coverage recommended.',
          howToGetAsImmigrant: 'Available from local insurers. Often required by mortgage lenders.',
        ),
      ],
      pension: PensionInfo(
        systemType: 'Pay-as-you-go earnings-related + social pension',
        pillar1: 'Social Insurance Pension: basic + supplementary components. Based on insurance points.',
        pillar2: 'Provident funds: employer-sponsored lump-sum savings schemes (being reformed)',
        pillar3: 'Private pension and savings plans',
        retirementAge: 65,
        retirementAgeWomen: 65,
        minimumContributionYears: 10,
        averageStatePensionMonthly: '900 EUR',
        minimumPensionMonthly: '380 EUR (basic pension with minimum contributions)',
        maximumPensionMonthly: '~2,100 EUR',
        contributionRate: '22.8% total (8.3% employee + 8.3% employer + 6.2% state). Rising to 25.8% by 2039.',
        pensionAuthorityName: 'Social Insurance Services',
        pensionAuthorityWebsite: 'www.mlsi.gov.cy/sid',
        pensionAuthorityPhone: '+357 22 401 639',
      ),
      immigrantPensionRights: ImmigrantPensionRights(
        rightsForEuCitizens: 'Full equal treatment under EU Regulation 883/2004.',
        rightsForThirdCountryNationals: 'Equal rights if legally employed. Limited bilateral agreements.',
        minimumResidenceForStatePension: '10 years of contributions for basic pension. Social pension (non-contributory) requires residence.',
        crossBorderCoordination: 'Social Insurance Services handle EU coordination.',
        whatHappensIfYouLeave: 'Pension rights preserved. Exportable to EU/EEA countries.',
        howToClaimFromAbroad: 'Apply through institution in country of residence.',
        pensionExportRules: 'Full export within EU/EEA. Limited export to non-EU countries without bilateral agreements.',
        voluntaryContributions: 'Voluntary insurance possible for Cypriots abroad and self-employed.',
        pensionTransferOptions: 'No Pillar 1 transfer. Provident fund lump sums may be payable on departure.',
        bilateralAgreements: 'Egypt, Syria, Canada, Australia, and a few others.',
      ),
      carInsurance: CarInsuranceInfo(
        mandatory: true,
        minimumCoverage: '35M EUR personal injury, 7M EUR property damage',
        averageAnnualCostTPL: '300-800 EUR',
        averageAnnualCostFullCoverage: '600-1,800 EUR',
        greenCardRequired: 'Not for EU vehicles.',
        foreignLicenseRules: 'EU licenses valid. Non-EU licenses valid 6 months. Drive on LEFT (former British colony).',
        noClaimsDiscountTransfer: 'May be accepted with documentation.',
        howToGetAsImmigrant: 'Need Cyprus registration and valid license. Compare at Insurance Association of Cyprus.',
        majorProviders: 'CNP Asfalistiki, General Insurance of Cyprus, Allianz Cyprus, Universal Life',
      ),
      healthInsuranceSystem: 'GESY/GHS (General Healthcare System). Single-payer universal. Co-payments: 1 EUR GP visit, 6 EUR specialist, low prescription fees.',
      healthInsuranceCostEmployee: '2.65% employee + 2.90% employer',
      healthInsuranceCostSelfEmployed: '4.0% of declared income + 2.90% as own employer',
      socialSecurityOverview: 'Total social insurance: 22.8% (8.3% employee + 8.3% employer + 6.2% state). GESY additional: 2.65% employee + 2.90% employer.',
      legalBasis: 'Social Insurance Law (Cap 59.15), GESY Law 2017, EU Reg 883/2004',
      immigrantSpecificNotes: 'GESY provides excellent coverage at low cost. All legal residents must register. Asylum seekers receive medical care through welfare services. North Cyprus has separate system (not EU).',
    ),

    // ============================================================
    // 6. CZECH REPUBLIC (CZ)
    // ============================================================
    CountryInsurancePension(
      country: 'Czech Republic',
      countryCode: 'CZ',
      mandatoryInsurance: [
        InsuranceType(
          type: 'Health Insurance',
          mandatory: true,
          averageMonthlyCost: 'Employee: 4.5% of gross. Employer: 9%. Self-employed: 13.5% of 50% profit base.',
          description: 'Mandatory public health insurance through health insurance companies (VZP is largest). Covers comprehensive care.',
          howToGetAsImmigrant: 'EU citizens: register with any Czech health insurer (VZP, CPZP, OZP, etc.). Non-EU: must have comprehensive private health insurance for residence permit, unless employed (then public insurance).',
        ),
        InsuranceType(
          type: 'Car Insurance (TPL)',
          mandatory: true,
          averageMonthlyCost: 'CZK 3,000-10,000/year (~120-400 EUR)',
          description: 'Povinne ruceni (mandatory liability). Required for all registered vehicles.',
          howToGetAsImmigrant: 'Need Czech registration. Compare at srovnejto.cz, epojisteni.cz.',
        ),
        InsuranceType(
          type: 'Employer Liability Insurance',
          mandatory: true,
          averageMonthlyCost: 'Paid by employer',
          description: 'Employers must insure against work-related injuries and occupational diseases (Kooperativa or Generali CP only).',
          howToGetAsImmigrant: 'N/A - employer obligation.',
        ),
      ],
      recommendedInsurance: [
        InsuranceType(
          type: 'Property Insurance',
          mandatory: false,
          averageMonthlyCost: 'CZK 200-600/month (~8-25 EUR)',
          description: 'Pojisteni domacnosti covers household contents. Often combined with liability.',
          howToGetAsImmigrant: 'Available from all Czech insurers. Many landlords require it.',
        ),
      ],
      pension: PensionInfo(
        systemType: 'Pay-as-you-go with reformed supplementary savings',
        pillar1: 'State pension (duchod): flat-rate basic amount + earnings-related percentage amount. Formula: 30 years minimum.',
        pillar2: 'Abolished in 2016 (mandatory funded pillar existed 2013-2015)',
        pillar3: 'Supplementary pension savings (doplnkove penzijni sporeni): voluntary with state contribution up to CZK 2,760/year + employer tax-free contributions up to CZK 50,000/year',
        retirementAge: 65,
        retirementAgeWomen: 63,
        minimumContributionYears: 35,
        averageStatePensionMonthly: 'CZK 20,000 (~800 EUR)',
        minimumPensionMonthly: 'CZK 5,490 (~220 EUR, basic amount alone)',
        maximumPensionMonthly: '~CZK 50,000 (~2,000 EUR)',
        contributionRate: '28% for pension insurance (6.5% employee + 21.5% employer)',
        pensionAuthorityName: 'Czech Social Security Administration (CSSZ)',
        pensionAuthorityWebsite: 'www.cssz.cz',
        pensionAuthorityPhone: '+420 257 062 860',
      ),
      immigrantPensionRights: ImmigrantPensionRights(
        rightsForEuCitizens: 'Full equal treatment under EU Regulation 883/2004. All EU periods count.',
        rightsForThirdCountryNationals: 'Equal rights when legally employed. Bilateral agreements with Ukraine, Russia, South Korea, Japan, Turkey, USA, Canada, and others.',
        minimumResidenceForStatePension: '35 years of insurance for standard pension (can aggregate with EU/bilateral periods). 30 years for reduced pension.',
        crossBorderCoordination: 'CSSZ handles EU pension coordination. Well-established procedures.',
        whatHappensIfYouLeave: 'Pension rights fully preserved. Exportable worldwide for Czech citizens, EU-wide for EU citizens, bilateral countries for others.',
        howToClaimFromAbroad: 'Apply via pension institution in country of residence.',
        pensionExportRules: 'Full export within EU/EEA. Bilateral agreement countries receive pension transfers. For other countries: Czech nationals always receive pension, foreigners depend on agreements.',
        voluntaryContributions: 'Voluntary pension insurance through CSSZ possible (CZK 2,994/month minimum in 2024).',
        pensionTransferOptions: 'No Pillar 1 capital transfer. Pillar 3 supplementary savings can be withdrawn (with tax implications).',
        bilateralAgreements: 'Ukraine, USA, Canada, South Korea, Japan, Turkey, Israel, India, Australia, Russia, Moldova, Belarus, and others.',
      ),
      carInsurance: CarInsuranceInfo(
        mandatory: true,
        minimumCoverage: 'CZK 50M personal injury (~2M EUR), CZK 50M property damage',
        averageAnnualCostTPL: 'CZK 3,000-10,000 (120-400 EUR)',
        averageAnnualCostFullCoverage: 'CZK 8,000-25,000 (320-1,000 EUR)',
        greenCardRequired: 'Not for EU vehicles.',
        foreignLicenseRules: 'EU licenses valid. Non-EU licenses valid 1 year with IDP. Must convert after permanent residence.',
        noClaimsDiscountTransfer: 'Bonus-malus system. Foreign NCB may be accepted by some insurers.',
        howToGetAsImmigrant: 'Need Czech registration. Mandatory highway vignette (e-vignette since 2021). Compare at srovnejto.cz.',
        majorProviders: 'Ceska pojistovna, Kooperativa, Allianz, Generali, CSOB Pojistovna, Direct',
      ),
      healthInsuranceSystem: 'Mandatory social health insurance via competing health insurance companies. VZP covers ~60% of population. Free choice of insurer.',
      healthInsuranceCostEmployee: '4.5% employee + 9% employer = 13.5% total',
      healthInsuranceCostSelfEmployed: '13.5% of 50% of profit (or minimum base)',
      socialSecurityOverview: 'Total: 44.8% (11% employee + 33.8% employer). Covers pension (28%), health (13.5%), sickness (3.3%).',
      legalBasis: 'Act No. 155/1995 Coll. (Pension Insurance), Act No. 48/1997 Coll. (Public Health Insurance), EU Reg 883/2004',
      immigrantSpecificNotes: 'Non-EU immigrants need comprehensive private health insurance (VZP offers PVZP product ~CZK 7,000-14,000/year) unless employed. Blue Card holders get public insurance. Employee Permit holders get public insurance from day 1.',
    ),

    // ============================================================
    // 7. DENMARK (DK)
    // ============================================================
    CountryInsurancePension(
      country: 'Denmark',
      countryCode: 'DK',
      mandatoryInsurance: [
        InsuranceType(
          type: 'Health Insurance',
          mandatory: true,
          averageMonthlyCost: 'Tax-funded. No separate premium. Sundhedsbidrag (8% income) was abolished; now part of general taxation.',
          description: 'Universal tax-funded healthcare. All residents registered with CPR get a yellow health card (sundhedskort). Free GP, hospital, mental health. Dental and physio have co-payments.',
          howToGetAsImmigrant: 'Automatic when you get CPR number and register in municipality. Takes 1-6 weeks to receive sundhedskort. Until then, can use temporary certificate.',
        ),
        InsuranceType(
          type: 'Car Insurance (TPL)',
          mandatory: true,
          averageMonthlyCost: 'DKK 3,000-10,000/year (~400-1,340 EUR)',
          description: 'Ansvarsforsikring mandatory. Denmark has among the highest car insurance costs in EU due to high vehicle taxes.',
          howToGetAsImmigrant: 'Need Danish registration (very expensive registration tax: 85-150% of car value). Compare at forsikringsguiden.dk.',
        ),
      ],
      recommendedInsurance: [
        InsuranceType(
          type: 'Home Contents Insurance',
          mandatory: false,
          averageMonthlyCost: 'DKK 100-300/month (~13-40 EUR)',
          description: 'Indboforsikring covers personal belongings. Often includes liability coverage.',
          howToGetAsImmigrant: 'Widely recommended. Most Danes have this. Available from Tryg, Topdanmark, Alm. Brand.',
        ),
        InsuranceType(
          type: 'Supplementary Health Insurance (Danmark)',
          mandatory: false,
          averageMonthlyCost: 'DKK 150-300/month (~20-40 EUR)',
          description: 'Sygeforsikring "danmark" covers dental, physio, glasses, alternative treatment co-payments.',
          howToGetAsImmigrant: 'Open to all with yellow health card. Very popular - 2 million members.',
        ),
      ],
      pension: PensionInfo(
        systemType: 'Multi-pillar: universal state + ATP + occupational + voluntary',
        pillar1: 'Folkepension (state pension): universal flat-rate + income-tested supplement. ATP: mandatory quasi-funded scheme.',
        pillar2: 'Occupational pensions: quasi-mandatory through collective agreements. Covers ~90% of workforce. Typically 12-18% of salary.',
        pillar3: 'Private pension savings with tax advantages. Ratepension, livsvarig pension, aldersopsparing.',
        retirementAge: 67,
        retirementAgeWomen: 67,
        minimumContributionYears: 0,
        averageStatePensionMonthly: 'DKK 13,000 total (~1,745 EUR) including supplements',
        minimumPensionMonthly: 'DKK 6,600 base (~885 EUR) for folkepension without supplements',
        maximumPensionMonthly: 'DKK 19,500 (~2,615 EUR) folkepension + supplements. Much higher with occupational pension.',
        contributionRate: 'ATP: DKK 3,408/year (2/3 employer, 1/3 employee). Occupational: 12-18% of salary (varies by agreement).',
        pensionAuthorityName: 'Udbetaling Danmark (pays folkepension) + ATP',
        pensionAuthorityWebsite: 'www.borger.dk/pension',
        pensionAuthorityPhone: '+45 70 12 80 61',
      ),
      immigrantPensionRights: ImmigrantPensionRights(
        rightsForEuCitizens: 'Full equal treatment. Folkepension requires 10 years residence (3 must be in Denmark between age 15-67). EU periods can be aggregated for qualifying but not for calculation (residence-based).',
        rightsForThirdCountryNationals: 'Same residence-based rules. Folkepension requires actual residence in Denmark. Bilateral agreements with some countries.',
        minimumResidenceForStatePension: '10 years of residence in Denmark (between age 15 and pension age), of which 3 years must be consecutive. Full folkepension after 40 years of residence.',
        crossBorderCoordination: 'Under EU Reg 883/2004: residence periods in other EU countries can help meet qualifying conditions. But calculation is based on Danish residence years only.',
        whatHappensIfYouLeave: 'Folkepension: reduced proportionally. 10/40ths if 10 years residence, etc. ATP: fully exportable. Occupational pensions: exportable under fund rules.',
        howToClaimFromAbroad: 'Apply through institution in country of residence. Udbetaling Danmark processes folkepension claims.',
        pensionExportRules: 'Folkepension exportable to EU/EEA and bilateral agreement countries (proportional to residence). ATP fully exportable worldwide. Occupational pensions exportable.',
        voluntaryContributions: 'Limited voluntary contributions to folkepension (not applicable). ATP: not voluntary. Pillar 2/3: voluntary additional contributions possible.',
        pensionTransferOptions: 'No transfer of folkepension/ATP capital. Occupational pension funds may allow transfer between Danish funds.',
        bilateralAgreements: 'USA, Canada, Turkey, India, Pakistan, South Korea, Australia, Chile, Morocco, Israel, and others.',
      ),
      carInsurance: CarInsuranceInfo(
        mandatory: true,
        minimumCoverage: 'DKK 84M personal injury (~11.3M EUR), DKK 18M property',
        averageAnnualCostTPL: 'DKK 3,000-10,000 (400-1,340 EUR)',
        averageAnnualCostFullCoverage: 'DKK 6,000-20,000 (800-2,680 EUR)',
        greenCardRequired: 'Not for EU vehicles.',
        foreignLicenseRules: 'EU licenses valid. Non-EU licenses valid 90 days as tourist, 6 months if resident. Must convert after establishing residence.',
        noClaimsDiscountTransfer: 'Some insurers accept foreign NCB. Ask specifically.',
        howToGetAsImmigrant: 'VERY expensive due to registration tax (85-150% of vehicle value). Many immigrants use car-sharing. Compare at forsikringsguiden.dk.',
        majorProviders: 'Tryg, Topdanmark, Alm. Brand, Codan, GF Forsikring',
      ),
      healthInsuranceSystem: 'Universal tax-funded healthcare (Sundhedsvaesenet). No insurance premiums. Financed through general taxation (~8% of tax goes to regions for healthcare).',
      healthInsuranceCostEmployee: 'No separate health insurance contribution. Funded through income tax (~37-52%)',
      healthInsuranceCostSelfEmployed: 'Same tax structure applies',
      socialSecurityOverview: 'Denmark has low payroll contributions but high income taxes. ATP ~DKK 3,408/year. Labor market contribution (AM-bidrag): 8% of gross income. Most social benefits tax-funded.',
      legalBasis: 'Social Pension Act (Lov om social pension), ATP-loven, Sundhedsloven, EU Reg 883/2004',
      immigrantSpecificNotes: 'Denmark folkepension is residence-based, not contribution-based. This means immigrants build rights by living in Denmark, not by working. However, need 10 years minimum. Asylum seekers do not build folkepension rights during asylum process. International protection holders start counting from residence permit date.',
    ),

    // ============================================================
    // 8. ESTONIA (EE)
    // ============================================================
    CountryInsurancePension(
      country: 'Estonia',
      countryCode: 'EE',
      mandatoryInsurance: [
        InsuranceType(
          type: 'Health Insurance',
          mandatory: true,
          averageMonthlyCost: '13% employer social tax covers health insurance (part of 33% social tax)',
          description: 'Estonian Health Insurance Fund (Haigekassa/Tervisekassa). Universal for insured persons. Covers GP, specialists, hospital, dental (partially), prescriptions.',
          howToGetAsImmigrant: 'Automatic when employer pays social tax. Self-employed must register and pay social tax. Uninsured can get emergency care only. Need Estonian personal ID code.',
        ),
        InsuranceType(
          type: 'Car Insurance (TPL)',
          mandatory: true,
          averageMonthlyCost: '150-400 EUR/year',
          description: 'Liikluskindlustus (traffic insurance) mandatory for all registered vehicles.',
          howToGetAsImmigrant: 'Need Estonian registration. Compare at kindlustus.ee. LHV, ERGO, If, Salva are providers.',
        ),
      ],
      recommendedInsurance: [
        InsuranceType(
          type: 'Home Insurance',
          mandatory: false,
          averageMonthlyCost: '10-30 EUR/month',
          description: 'Kodukindlustus covers property and contents against fire, theft, water damage.',
          howToGetAsImmigrant: 'Available from all Estonian insurers.',
        ),
      ],
      pension: PensionInfo(
        systemType: 'Three-pillar: state PAYG + mandatory funded + voluntary',
        pillar1: 'State pension: flat-rate base part + service-years part + insurance part (contribution-based since 1999)',
        pillar2: 'Mandatory funded pension: 2% from employee gross salary + 4% from employer social tax. Born after 1983 mandatory. Others opted in.',
        pillar3: 'Voluntary funded pension with tax incentives (up to 15% of gross income deductible)',
        retirementAge: 65,
        retirementAgeWomen: 65,
        minimumContributionYears: 15,
        averageStatePensionMonthly: '650 EUR',
        minimumPensionMonthly: '324 EUR (national pension/rahvapension for 15+ years residence without qualifying insurance)',
        maximumPensionMonthly: '~1,200 EUR (state pension alone, Pillar 1)',
        contributionRate: '33% social tax (employer only): 20% for pension + 13% for health. Pillar 2: additional 2% from employee.',
        pensionAuthorityName: 'Social Insurance Board (Sotsiaalkindlustusamet)',
        pensionAuthorityWebsite: 'www.sotsiaalkindlustusamet.ee',
        pensionAuthorityPhone: '+372 612 1360',
      ),
      immigrantPensionRights: ImmigrantPensionRights(
        rightsForEuCitizens: 'Full equal treatment under EU Regulation 883/2004.',
        rightsForThirdCountryNationals: 'Equal rights if legally employed. Bilateral agreements with Russia, Ukraine, Canada, and others.',
        minimumResidenceForStatePension: '15 years of qualifying insurance periods. National pension (rahvapension) requires 15 years of residence in Estonia.',
        crossBorderCoordination: 'Social Insurance Board handles EU coordination.',
        whatHappensIfYouLeave: 'Pillar 1 state pension preserved and exportable. Pillar 2 mandatory funded pension remains in your chosen fund. Since 2021 reform, Pillar 2 can be withdrawn (with tax).',
        howToClaimFromAbroad: 'Apply through institution in country of residence.',
        pensionExportRules: 'Full export within EU/EEA and bilateral countries. Pillar 2 can be withdrawn as lump sum (taxed at 20% or 10% depending on conditions).',
        voluntaryContributions: 'Pillar 3 voluntary contributions. No voluntary Pillar 1 contributions.',
        pensionTransferOptions: 'Pillar 2 can be cashed out since 2021 reform (controversial). Can switch between Pillar 2 fund managers.',
        bilateralAgreements: 'Russia, Ukraine, Canada, Moldova, and a few others. Many residents have service years from Soviet era recognized.',
      ),
      carInsurance: CarInsuranceInfo(
        mandatory: true,
        minimumCoverage: '5.6M EUR personal injury, 1.2M EUR property',
        averageAnnualCostTPL: '150-400 EUR',
        averageAnnualCostFullCoverage: '400-1,200 EUR',
        greenCardRequired: 'Not for EU vehicles.',
        foreignLicenseRules: 'EU licenses valid. Non-EU licenses valid 1 year. Must convert for permanent residence.',
        noClaimsDiscountTransfer: 'Bonus-malus system. Some acceptance of foreign history.',
        howToGetAsImmigrant: 'Need Estonian registration. Digital process available via e-residency portal for some services.',
        majorProviders: 'If P&C, ERGO, LHV, Salva, Seesam (Compensa)',
      ),
      healthInsuranceSystem: 'Estonian Health Insurance Fund (Tervisekassa). Tax-funded through employer social tax. Free for insured persons. GP gatekeeping system.',
      healthInsuranceCostEmployee: '0% direct. Employer pays 33% social tax (13% health + 20% pension)',
      healthInsuranceCostSelfEmployed: 'Minimum social tax ~192 EUR/month in 2024 (covers health + pension)',
      socialSecurityOverview: 'Employer social tax: 33% (20% pension + 13% health). Unemployment insurance: 1.6% employee + 0.8% employer. Funded pension: 2% employee.',
      legalBasis: 'State Pension Insurance Act, Funded Pensions Act, Health Insurance Act, EU Reg 883/2004',
      immigrantSpecificNotes: 'Estonia is highly digital - most insurance and pension services available online. E-residency does NOT grant health insurance. Must be physically resident and employed/self-employed. Russian-speaking immigrants: many services available in Russian. Soviet-era pension years recognized.',
    ),

    // ============================================================
    // 9. FINLAND (FI)
    // ============================================================
    CountryInsurancePension(
      country: 'Finland',
      countryCode: 'FI',
      mandatoryInsurance: [
        InsuranceType(
          type: 'Health Insurance (Kela + Municipal)',
          mandatory: true,
          averageMonthlyCost: 'Employee: 1.96% medical care + 0% daily allowance (employer: 1.53%). Funded through taxation.',
          description: 'Dual system: Municipal healthcare (terveyskeskus) for residents + Kela sickness insurance. Universal coverage for registered residents (kotikunta). Covers primary care, hospital, dental, mental health.',
          howToGetAsImmigrant: 'Must register municipality of residence (kotikunta) at DVV. Need to intend to stay 1+ year. Get Kela card. EU citizens with E/S forms get coverage earlier.',
        ),
        InsuranceType(
          type: 'Car Insurance (TPL)',
          mandatory: true,
          averageMonthlyCost: '300-1,200 EUR/year',
          description: 'Liikennevakuutus (traffic insurance) mandatory for all registered vehicles.',
          howToGetAsImmigrant: 'Need Finnish registration. Compare at vakuutusvertailu.fi. If, OP, LahiTapiola, Pohjola are major providers.',
        ),
        InsuranceType(
          type: 'Employee Pension Insurance (TyEL)',
          mandatory: true,
          averageMonthlyCost: 'Employee: 7.15% (under 53) or 8.65% (53-62). Employer: ~17.4% average.',
          description: 'Mandatory earnings-related pension insurance for all employees aged 17-67. Employers must arrange this with a pension company.',
          howToGetAsImmigrant: 'Automatic when employed. Employer handles registration. Self-employed: YEL insurance mandatory when income exceeds 9,010 EUR/year.',
        ),
      ],
      recommendedInsurance: [
        InsuranceType(
          type: 'Home Insurance',
          mandatory: false,
          averageMonthlyCost: '15-40 EUR/month',
          description: 'Kotivakuutus covers contents and liability. Most landlords require it for renters.',
          howToGetAsImmigrant: 'Available from all Finnish insurers. Very commonly held.',
        ),
        InsuranceType(
          type: 'Private Health Insurance',
          mandatory: false,
          averageMonthlyCost: '30-100 EUR/month',
          description: 'Supplements public system. Faster access to specialists, private clinics.',
          howToGetAsImmigrant: 'Many employers provide as benefit. Also available individually.',
        ),
      ],
      pension: PensionInfo(
        systemType: 'Earnings-related (TyEL/YEL) + national pension (Kela) + guarantee pension',
        pillar1: 'Earnings-related pension (tyoelake): TyEL for employees, YEL for self-employed. Accrues 1.5% per year of earnings. National pension (kansanelake) from Kela: supplements low earnings-related pension. Guarantee pension (takuuelake): minimum floor.',
        pillar2: 'No separate mandatory Pillar 2. TyEL is partially funded (buffer funds).',
        pillar3: 'Voluntary individual pension insurance and PS (pitkaaiaissaastaminen) accounts. Limited tax benefits.',
        retirementAge: 65,
        retirementAgeWomen: 65,
        minimumContributionYears: 0,
        averageStatePensionMonthly: '1,900 EUR (average total pension)',
        minimumPensionMonthly: '976 EUR (guarantee pension/takuuelake, 2024)',
        maximumPensionMonthly: 'No statutory maximum for earnings-related pension. Typically up to 60% of career earnings.',
        contributionRate: 'TyEL: ~24.8% total (7.15% employee under 53, ~17.4% employer average). YEL: 24.1% (under 53) of confirmed income.',
        pensionAuthorityName: 'Finnish Centre for Pensions (ETK) + Kela',
        pensionAuthorityWebsite: 'www.tyoelake.fi (earnings-related) / www.kela.fi (national pension)',
        pensionAuthorityPhone: '+358 29 411 2110 (ETK)',
      ),
      immigrantPensionRights: ImmigrantPensionRights(
        rightsForEuCitizens: 'Full equal treatment under EU Regulation 883/2004. All EU insurance periods count for qualifying conditions.',
        rightsForThirdCountryNationals: 'Equal earnings-related pension rights when legally employed. National pension requires residence. Bilateral agreements with several countries.',
        minimumResidenceForStatePension: 'Earnings-related: no residence requirement (based on work). National pension (Kela): 3 years of residence in Finland after age 16. Full after 40 years. Guarantee pension: immediate for residents.',
        crossBorderCoordination: 'ETK (Finnish Centre for Pensions) handles all cross-border pension coordination. Very well-organized system.',
        whatHappensIfYouLeave: 'Earnings-related pension fully preserved and exportable worldwide. National pension: reduced proportionally, exported to EU/EEA/bilateral countries only. Guarantee pension: NOT exportable (only paid to Finland residents).',
        howToClaimFromAbroad: 'Apply through pension institution in country of residence. ETK coordinates. Can also apply online at tyoelake.fi.',
        pensionExportRules: 'Earnings-related: exportable worldwide without reduction. National pension: exportable to EU/EEA and bilateral countries, proportional to Finnish residence years. Guarantee pension: Finland only.',
        voluntaryContributions: 'No voluntary TyEL contributions. YEL income can be voluntarily set higher. Pillar 3 voluntary savings.',
        pensionTransferOptions: 'No capital transfer between countries. Each country pays its share. Finnish pension companies manage earnings-related pension.',
        bilateralAgreements: 'USA, Canada, Israel, India, South Korea, China, Japan, Chile, Australia, and others. Nordic Convention covers all Nordic countries specifically.',
      ),
      carInsurance: CarInsuranceInfo(
        mandatory: true,
        minimumCoverage: '5.9M EUR personal injury, 1.18M EUR property',
        averageAnnualCostTPL: '300-1,200 EUR',
        averageAnnualCostFullCoverage: '600-2,500 EUR',
        greenCardRequired: 'Not for EU vehicles.',
        foreignLicenseRules: 'EU licenses valid. Non-EU licenses valid 1 year (or 2 years for some countries). Must exchange for Finnish license.',
        noClaimsDiscountTransfer: 'Bonus system used. Some insurers accept foreign NCB letter.',
        howToGetAsImmigrant: 'Need Finnish registration (Traficom). Compare at vakuutusvertailu.fi or fine.fi.',
        majorProviders: 'If, OP, LahiTapiola, Pohjola (OP), Fennia, Turva',
      ),
      healthInsuranceSystem: 'Dual system: Municipal healthcare (public health centers) + Kela sickness insurance (reimbursement for private care). Universal for municipal residents.',
      healthInsuranceCostEmployee: 'Medical care: 0.51% employee + 1.01% employer. Daily allowance: 0% employee + 1.16% employer. Funded mainly through taxes.',
      healthInsuranceCostSelfEmployed: 'YEL pension insurance mandatory. Health covered through municipality and Kela based on residence.',
      socialSecurityOverview: 'Total employer costs: ~20-25% on top of salary (TyEL pension + health + unemployment + accident + group life). Employee: ~10% (pension + unemployment + health).',
      legalBasis: 'Employees Pensions Act (TyEL), Self-Employed Persons Pensions Act (YEL), National Pensions Act, Health Insurance Act, EU Reg 883/2004',
      immigrantSpecificNotes: 'Finland has strong pension system. Earnings-related pension accrues from first day of work. Kela national pension provides safety net. Guarantee pension ensures minimum income for all residents. Immigrants should check kotikunta registration (municipality of residence) as it determines healthcare access. Asylum seekers: reception center healthcare, not full Kela coverage.',
    ),

    // ============================================================
    // 10. FRANCE (FR)
    // ============================================================
    CountryInsurancePension(
      country: 'France',
      countryCode: 'FR',
      mandatoryInsurance: [
        InsuranceType(
          type: 'Health Insurance (Securite sociale)',
          mandatory: true,
          averageMonthlyCost: 'Employee contribution integrated into CSG (9.2% of gross, of which health portion). Employer: ~13% for health.',
          description: 'Universal health coverage (PUMa - Protection Universelle Maladie). Reimburses ~70% of costs. Complementary insurance (mutuelle) covers remainder.',
          howToGetAsImmigrant: 'Register with CPAM (Caisse Primaire d Assurance Maladie) after 3 months of stable residence. Need titre de sejour and proof of residence. Get Carte Vitale (health card).',
        ),
        InsuranceType(
          type: 'Complementary Health Insurance (Mutuelle)',
          mandatory: true,
          averageMonthlyCost: '30-100 EUR/month (employers must provide for employees since 2016)',
          description: 'Since January 2016, all employers must offer complementaire sante. Covers co-payments (ticket moderateur). CSS (Complementaire Sante Solidaire) free for low-income.',
          howToGetAsImmigrant: 'Employer provides for employees. Self-employed arrange privately. Low-income: apply for CSS at CPAM (free or 1 EUR/person/day).',
        ),
        InsuranceType(
          type: 'Car Insurance (TPL)',
          mandatory: true,
          averageMonthlyCost: '40-100 EUR/month',
          description: 'Assurance responsabilite civile automobile mandatory. France has high minimum coverage requirements.',
          howToGetAsImmigrant: 'Need carte grise (vehicle registration), valid license. Compare at lesfurets.com, assurland.com.',
        ),
        InsuranceType(
          type: 'Home Insurance (Renters)',
          mandatory: true,
          averageMonthlyCost: '15-30 EUR/month (renters), 25-50 EUR/month (owners)',
          description: 'Assurance habitation MANDATORY for all tenants (Loi Quilliot/ALUR). Covers fire, water damage, liability to landlord.',
          howToGetAsImmigrant: 'Must provide attestation d assurance habitation to landlord. Available from all insurers. Required before receiving keys.',
        ),
      ],
      recommendedInsurance: [
        InsuranceType(
          type: 'Personal Liability Insurance',
          mandatory: false,
          averageMonthlyCost: 'Often included in home insurance',
          description: 'Responsabilite civile vie privee. Usually bundled with assurance habitation.',
          howToGetAsImmigrant: 'Check if included in your home insurance policy.',
        ),
      ],
      pension: PensionInfo(
        systemType: 'Pay-as-you-go multi-tier: base + complementary (AGIRC-ARRCO)',
        pillar1: 'Regime general (base): earnings-related. Best 25 years of earnings. Rate: 50% of reference salary at full rate. AGIRC-ARRCO: mandatory points-based complementary for private sector.',
        pillar2: 'AGIRC-ARRCO (mandatory complementary for private sector). Points system. Significant addition to base pension.',
        pillar3: 'PER (Plan d Epargne Retraite): voluntary tax-advantaged savings since 2019 Pacte law reform.',
        retirementAge: 64,
        retirementAgeWomen: 64,
        minimumContributionYears: 43,
        averageStatePensionMonthly: '1,530 EUR (base + complementary average)',
        minimumPensionMonthly: '750 EUR (minimum contributif for full career) / ASPA: 1,012 EUR (minimum old-age income for residents 65+)',
        maximumPensionMonthly: '1,932 EUR (base maximum 2024) + AGIRC-ARRCO (no cap, depends on points)',
        contributionRate: 'Base: ~17.75% (employer + employee). AGIRC-ARRCO: ~10% (employer + employee). Total pension: ~28%.',
        pensionAuthorityName: 'Assurance Retraite (CNAV) + AGIRC-ARRCO',
        pensionAuthorityWebsite: 'www.lassuranceretraite.fr / www.agirc-arrco.fr',
        pensionAuthorityPhone: '3960 (from France)',
      ),
      immigrantPensionRights: ImmigrantPensionRights(
        rightsForEuCitizens: 'Full equal treatment under EU Regulation 883/2004. All EU quarters/periods aggregated.',
        rightsForThirdCountryNationals: 'Equal rights when legally employed. France has extensive bilateral agreements (former colonies, Francophone countries).',
        minimumResidenceForStatePension: 'Contribution-based: minimum 1 quarter of contributions. ASPA (minimum old-age): 10 years of stable residence in France.',
        crossBorderCoordination: 'CNAV + CLEISS (Centre des Liaisons Europeennes et Internationales de Securite Sociale) handle coordination.',
        whatHappensIfYouLeave: 'Base pension rights preserved. Exportable to EU/EEA and bilateral countries. ASPA (minimum old-age income) NOT exportable - France residence only.',
        howToClaimFromAbroad: 'Apply through pension institution in residence country. Or directly at lassuranceretraite.fr. French pension claim triggers cascade across all EU countries where you worked.',
        pensionExportRules: 'Full export of contributory pensions to EU/EEA and 40+ bilateral agreement countries. ASPA not exportable.',
        voluntaryContributions: 'Voluntary affiliation possible for French nationals abroad (CFE - Caisse des Francais de l Etranger). Rachat de trimestres (buy-back) possible for study years or gaps.',
        pensionTransferOptions: 'No capital transfer. Each regime pays its share. AGIRC-ARRCO points maintained separately.',
        bilateralAgreements: 'Algeria, Morocco, Tunisia, Senegal, Mali, Cameroon, USA, Canada, Quebec, Japan, South Korea, India, Brazil, Argentina, Turkey, Israel, and 40+ others.',
      ),
      carInsurance: CarInsuranceInfo(
        mandatory: true,
        minimumCoverage: 'Unlimited for personal injury. Property: minimum per EU directive.',
        averageAnnualCostTPL: '500-1,200 EUR',
        averageAnnualCostFullCoverage: '800-2,500 EUR',
        greenCardRequired: 'Not for EU vehicles.',
        foreignLicenseRules: 'EU licenses valid indefinitely. Non-EU: valid 1 year from establishing residence, then must exchange (only ~130 countries have exchange agreements).',
        noClaimsDiscountTransfer: 'Bonus-malus coefficient system (CRM). Starts at 1.00, -5% per year no-claim. Foreign NCB not officially transferable but some insurers accept letters.',
        howToGetAsImmigrant: 'Need carte grise and valid license. Compare at lesfurets.com, assurland.com, lelynx.fr. Young/new drivers pay significantly more.',
        majorProviders: 'AXA, Allianz, MAIF, MACIF, Groupama, MAAF, Matmut, Generali, MMA',
      ),
      healthInsuranceSystem: 'PUMa (universal). Securite sociale reimburses ~70%. Mutuelle/complementaire covers rest. AME (Aide Medicale d Etat) for undocumented residents.',
      healthInsuranceCostEmployee: 'CSG 9.2% (health portion) + employer ~13% health contribution',
      healthInsuranceCostSelfEmployed: '~8% of declared income for health (varies by regime)',
      socialSecurityOverview: 'Total social charges: ~65% of net salary (employer ~45%, employee ~20%). Covers health, pension, family, unemployment, occupational accidents.',
      legalBasis: 'Code de la securite sociale, Code des assurances, Loi Touraine 2016 (PUMa), 2023 pension reform, EU Reg 883/2004',
      immigrantSpecificNotes: 'France has extensive social protection. Home insurance is MANDATORY for tenants (unique in EU). AME provides healthcare for undocumented residents (3+ months presence). CSS (free complementary insurance) for low-income. Very strong pension system but complex with multiple regimes. 2023 reform raised retirement age to 64.',
    ),

    // ============================================================
    // 11. GERMANY (DE)
    // ============================================================
    CountryInsurancePension(
      country: 'Germany',
      countryCode: 'DE',
      mandatoryInsurance: [
        InsuranceType(
          type: 'Health Insurance (Krankenversicherung)',
          mandatory: true,
          averageMonthlyCost: 'Employee: ~8.3% of gross (half of ~14.6% general + ~1.7% supplementary rate). Max: ~530 EUR/month.',
          description: 'Mandatory for all residents. Choice between statutory (GKV, ~90% population) and private (PKV, income >69,300 EUR/year). GKV covers comprehensive care.',
          howToGetAsImmigrant: 'Must choose insurer within 2 weeks of employment. Employees <69,300 EUR income: GKV mandatory. Self-employed and high earners can choose PKV. Need Anmeldung (registration).',
        ),
        InsuranceType(
          type: 'Car Insurance (TPL)',
          mandatory: true,
          averageMonthlyCost: '30-100 EUR/month',
          description: 'Kfz-Haftpflichtversicherung mandatory. Must have before registering vehicle. eVB number (electronic insurance confirmation) required.',
          howToGetAsImmigrant: 'Need Anmeldung, valid license, eVB number from insurer. Compare at check24.de, verivox.de.',
        ),
        InsuranceType(
          type: 'Private Liability Insurance',
          mandatory: false,
          averageMonthlyCost: '3-10 EUR/month',
          description: 'Privathaftpflicht not legally mandatory but considered essential by all financial advisors. Covers personal liability for damage to third parties up to millions.',
          howToGetAsImmigrant: 'Available immediately. Haftpflichtkasse, HUK-COBURG, CosmosDirekt are affordable options.',
        ),
      ],
      recommendedInsurance: [
        InsuranceType(
          type: 'Household Insurance',
          mandatory: false,
          averageMonthlyCost: '10-30 EUR/month',
          description: 'Hausratversicherung covers household contents. Many landlords require it.',
          howToGetAsImmigrant: 'Available from all German insurers. Highly recommended.',
        ),
        InsuranceType(
          type: 'Disability Insurance',
          mandatory: false,
          averageMonthlyCost: '30-100 EUR/month',
          description: 'Berufsunfahigkeitsversicherung (BU) protects income if unable to work. Most important insurance after health according to consumer organizations.',
          howToGetAsImmigrant: 'Available but expensive. Health questionnaire required. Apply early in career.',
        ),
      ],
      pension: PensionInfo(
        systemType: 'Pay-as-you-go points system (Rentenversicherung)',
        pillar1: 'Deutsche Rentenversicherung: mandatory for employees. Points system - 1 year at average salary = 1 Entgeltpunkt. Each point worth 39.32 EUR (West, 2024) per month.',
        pillar2: 'Occupational pensions (betriebliche Altersvorsorge/bAV): employer-facilitated. Since 2018, employers must offer. Tax-advantaged contributions.',
        pillar3: 'Riester-Rente (state-subsidized), Ruerup/Basis-Rente (tax-deductible), private pension insurance.',
        retirementAge: 67,
        retirementAgeWomen: 67,
        minimumContributionYears: 5,
        averageStatePensionMonthly: '1,550 EUR (West Germany average, 2024)',
        minimumPensionMonthly: '1,100 EUR (Grundrente/basic pension supplement for 33+ years of low-income contributions)',
        maximumPensionMonthly: '~3,500 EUR (45 years at maximum contribution ceiling)',
        contributionRate: '18.6% (9.3% employee + 9.3% employer)',
        pensionAuthorityName: 'Deutsche Rentenversicherung Bund',
        pensionAuthorityWebsite: 'www.deutsche-rentenversicherung.de',
        pensionAuthorityPhone: '+49 800 1000 4800 (free)',
      ),
      immigrantPensionRights: ImmigrantPensionRights(
        rightsForEuCitizens: 'Full equal treatment under EU Regulation 883/2004. All EU insurance periods count for German 5-year minimum.',
        rightsForThirdCountryNationals: 'Equal rights when legally employed. Extensive bilateral agreements. Grundrente supplement requires 33 years of contributions (can include foreign periods).',
        minimumResidenceForStatePension: '5 years of contribution periods minimum (can aggregate with EU/bilateral periods). Grundrente: 33 years.',
        crossBorderCoordination: 'Deutsche Rentenversicherung handles cross-border coordination. Excellent infrastructure for international pension claims.',
        whatHappensIfYouLeave: 'Pension rights fully preserved. Exportable to EU/EEA and bilateral countries. Non-EU nationals without bilateral agreement: can request refund of contributions after 2 years of leaving, BUT only employee portion (not recommended as you lose employer portion).',
        howToClaimFromAbroad: 'Apply through pension institution in country of residence. DRV has multilingual services.',
        pensionExportRules: 'Full export worldwide for German nationals. EU/EEA citizens: full export within EU/EEA. Third-country nationals: full export to bilateral countries. Others: may face restrictions (Rentenabfindung possible).',
        voluntaryContributions: 'Voluntary contributions possible (minimum ~100 EUR/month, maximum ~1,400 EUR/month in 2024). Very useful for reaching 5-year minimum or improving pension.',
        pensionTransferOptions: 'No capital transfer between countries. Refund of employee contributions possible for non-EU nationals who leave permanently (2-year waiting period). Not recommended as employer contributions lost.',
        bilateralAgreements: 'Turkey, USA, Canada, Japan, South Korea, India, China, Brazil, Australia, Israel, Morocco, Tunisia, and 20+ more countries.',
      ),
      carInsurance: CarInsuranceInfo(
        mandatory: true,
        minimumCoverage: '7.5M EUR personal injury, 1.22M EUR property, 50K EUR financial loss',
        averageAnnualCostTPL: '400-1,200 EUR',
        averageAnnualCostFullCoverage: '800-2,500 EUR',
        greenCardRequired: 'Not for EU vehicles.',
        foreignLicenseRules: 'EU/EEA licenses valid indefinitely. Non-EU licenses valid 6 months, then must convert. Some countries have conversion agreements (no test). Others require full German driving test.',
        noClaimsDiscountTransfer: 'SF-Klassen (Schadenfreiheitsklassen) system. Foreign NCB sometimes accepted with official letter from previous insurer. Not guaranteed.',
        howToGetAsImmigrant: 'Need Anmeldung, license, eVB number. Compare at check24.de, verivox.de, HUK24.de. Typklasse (vehicle type class) and Regionalklasse (regional class) affect price.',
        majorProviders: 'HUK-COBURG, Allianz, AXA, ERGO, R+V, Generali, CosmosDirekt, HDI',
      ),
      healthInsuranceSystem: 'Dual system: Statutory (GKV) for most, Private (PKV) for high earners/self-employed. GKV: ~14.6% + ~1.7% supplementary (shared). PKV: income-based premiums, risk-rated.',
      healthInsuranceCostEmployee: '~8.3% of gross salary (half of ~14.6% + ~1.7% Zusatzbeitrag). Capped at Beitragsbemessungsgrenze 62,100 EUR/year.',
      healthInsuranceCostSelfEmployed: '~14.6% + Zusatzbeitrag of declared income (minimum ~230 EUR/month for GKV)',
      socialSecurityOverview: 'Total ~40% (roughly 20% employee + 20% employer). Covers health (~16.3%), pension (18.6%), unemployment (2.6%), long-term care (~4.0%), accident (employer only, ~1.3%).',
      legalBasis: 'SGB VI (Pension), SGB V (Health), VVG (Insurance Contract Act), PflVG (Mandatory Insurance Act), EU Reg 883/2004',
      immigrantSpecificNotes: 'Germany requires health insurance for all residents - no exceptions. Private liability insurance (Haftpflicht) is considered essential though not legally required. Pension system is very well-organized for immigrants with DRV having multilingual services. Non-EU nationals can get contribution refund if leaving EU permanently, but generally not recommended. Riester-Rente subsidies available for anyone in mandatory pension insurance.',
    ),

    // ============================================================
    // 12. GREECE (GR)
    // ============================================================
    CountryInsurancePension(
      country: 'Greece',
      countryCode: 'GR',
      mandatoryInsurance: [
        InsuranceType(
          type: 'Health Insurance (EOPYY)',
          mandatory: true,
          averageMonthlyCost: 'Included in social security: ~7.1% (employee: 2.15%, employer: 4.30%, state: 0.65%)',
          description: 'EOPYY (National Organization for Healthcare Provision). Covers primary care, hospital, prescriptions, dental basics. Co-payments for some services.',
          howToGetAsImmigrant: 'Automatic when employed and insured with EFKA. Need AMKA (social security number) or PAAYPA (temporary for asylum seekers). Register at KEP or EFKA office.',
        ),
        InsuranceType(
          type: 'Car Insurance (TPL)',
          mandatory: true,
          averageMonthlyCost: '200-600 EUR/year',
          description: 'Motor insurance mandatory. Third-party liability required.',
          howToGetAsImmigrant: 'Need Greek registration plates and valid license. Compare at insurancemarket.gr.',
        ),
      ],
      recommendedInsurance: [
        InsuranceType(
          type: 'Private Health Insurance',
          mandatory: false,
          averageMonthlyCost: '50-150 EUR/month',
          description: 'Supplements EOPYY. Private hospitals, shorter waits, better facilities.',
          howToGetAsImmigrant: 'Available from Ethniki, Eurolife, Interamerican, NN Hellas.',
        ),
        InsuranceType(
          type: 'Earthquake Insurance',
          mandatory: false,
          averageMonthlyCost: '10-30 EUR/month',
          description: 'Greece is seismically active. Property insurance with earthquake coverage recommended.',
          howToGetAsImmigrant: 'Available from all Greek insurers. Required by some mortgage lenders.',
        ),
      ],
      pension: PensionInfo(
        systemType: 'Pay-as-you-go: national pension + contributory pension (EFKA)',
        pillar1: 'National pension (residence-based). Contributory pension: earnings-related. Both through EFKA.',
        pillar2: 'Occupational: auxiliary pensions (ETEAEP, now integrated into EFKA). Mandatory for employees.',
        pillar3: 'Voluntary private pension plans. Limited market.',
        retirementAge: 67,
        retirementAgeWomen: 67,
        minimumContributionYears: 15,
        averageStatePensionMonthly: '730 EUR (main pension average)',
        minimumPensionMonthly: '426 EUR (national pension for 20+ years, single)',
        maximumPensionMonthly: '~3,200 EUR (combined main + auxiliary after long career)',
        contributionRate: '20% for main pension (6.67% employee + 13.33% employer). Auxiliary: 6.5% total.',
        pensionAuthorityName: 'EFKA (e-EFKA) - Unified Social Insurance Fund',
        pensionAuthorityWebsite: 'www.efka.gov.gr',
        pensionAuthorityPhone: '+30 210 529 2000',
      ),
      immigrantPensionRights: ImmigrantPensionRights(
        rightsForEuCitizens: 'Full equal treatment under EU Regulation 883/2004.',
        rightsForThirdCountryNationals: 'Equal rights if legally employed. Limited bilateral agreements.',
        minimumResidenceForStatePension: '15 years of insurance periods for full national pension. National pension reduced proportionally for fewer years (minimum 15).',
        crossBorderCoordination: 'EFKA handles EU coordination. Greek pension system reformed significantly 2016-2020 (Katrougalos reform).',
        whatHappensIfYouLeave: 'Pension rights preserved. Exportable to EU/EEA and bilateral countries.',
        howToClaimFromAbroad: 'Apply through institution in country of residence. EFKA processes Greek portion.',
        pensionExportRules: 'Full export within EU/EEA. Bilateral agreement countries.',
        voluntaryContributions: 'Limited voluntary insurance options through EFKA.',
        pensionTransferOptions: 'No capital transfer. Each country pays proportional pension.',
        bilateralAgreements: 'USA, Canada, Australia, Egypt, Argentina, Brazil, Venezuela, and others (significant Greek diaspora).',
      ),
      carInsurance: CarInsuranceInfo(
        mandatory: true,
        minimumCoverage: '1.22M EUR personal injury, 1.22M EUR property',
        averageAnnualCostTPL: '200-600 EUR',
        averageAnnualCostFullCoverage: '500-1,500 EUR',
        greenCardRequired: 'Not for EU vehicles.',
        foreignLicenseRules: 'EU licenses valid. Non-EU licenses: IDP required. Must convert within 6 months of residence.',
        noClaimsDiscountTransfer: 'Bonus-malus system. Foreign NCB may be accepted.',
        howToGetAsImmigrant: 'Need Greek plates, valid license. Insurance market competitive.',
        majorProviders: 'Ethniki Asfalistiki, Eurolife, Interamerican, NN Hellas, Generali Greece',
      ),
      healthInsuranceSystem: 'EOPYY national health provider. Social insurance funded. Universal for insured persons. Public hospitals free for insured. Significant co-payments at private providers.',
      healthInsuranceCostEmployee: '2.15% employee + 4.30% employer + 0.65% state = 7.10%',
      healthInsuranceCostSelfEmployed: '~6.95% of declared income classes',
      socialSecurityOverview: 'Total contributions ~36-41% depending on profession. Covers pension (20% main + 6.5% auxiliary), health (7.1%), unemployment, other.',
      legalBasis: 'Law 4387/2016 (EFKA reform), Law 4670/2020 (pension reform), EU Reg 883/2004',
      immigrantSpecificNotes: 'Greece reformed pensions significantly. AMKA number essential for all social insurance. PAAYPA for asylum seekers. Pension levels relatively low in EU. Many Greeks supplement with Pillar 3. Greek islands may have limited healthcare - mainland hospitals better equipped.',
    ),

    // ============================================================
    // 13. HUNGARY (HU)
    // ============================================================
    CountryInsurancePension(
      country: 'Hungary',
      countryCode: 'HU',
      mandatoryInsurance: [
        InsuranceType(
          type: 'Health Insurance',
          mandatory: true,
          averageMonthlyCost: 'Employer: 13% social contribution tax (szocho). Employee: 18.5% (includes pension + health).',
          description: 'National Health Insurance Fund (NEAK). Universal for insured persons. Covers comprehensive care with some co-payments for certain services.',
          howToGetAsImmigrant: 'Automatic when employed. Self-employed pay szocho. Non-working residents can pay voluntary health contribution (~HUF 11,300/month). Need TAJ number (social security card).',
        ),
        InsuranceType(
          type: 'Car Insurance (TPL)',
          mandatory: true,
          averageMonthlyCost: 'HUF 30,000-120,000/year (~80-320 EUR)',
          description: 'KGFB mandatory for all registered vehicles.',
          howToGetAsImmigrant: 'Need Hungarian registration and valid license. Compare at netrisk.hu, biztositas.hu.',
        ),
      ],
      recommendedInsurance: [
        InsuranceType(
          type: 'Home Insurance',
          mandatory: false,
          averageMonthlyCost: 'HUF 3,000-10,000/month (~8-27 EUR)',
          description: 'Lakasbiztositas covers property and contents. Relatively affordable.',
          howToGetAsImmigrant: 'Available from all Hungarian insurers.',
        ),
      ],
      pension: PensionInfo(
        systemType: 'Pay-as-you-go single-pillar (mandatory funded pillar effectively nationalized in 2011)',
        pillar1: 'State pension: earnings-related. Formula based on average indexed earnings and service years. Accrual: 33%-80% depending on years.',
        pillar2: 'Effectively abolished. Private pension funds nationalized 2011. Some voluntary pension funds remain.',
        pillar3: 'Voluntary pension funds with tax credit (20% of contributions, max HUF 150,000/year)',
        retirementAge: 65,
        retirementAgeWomen: 65,
        minimumContributionYears: 20,
        averageStatePensionMonthly: 'HUF 220,000 (~580 EUR)',
        minimumPensionMonthly: 'HUF 28,500 (~75 EUR) statutory minimum. Old-age allowance: HUF ~60,000.',
        maximumPensionMonthly: 'No statutory maximum. Based on contributions.',
        contributionRate: '18.5% employee (10% pension + 7% health + 1.5% labor market). 13% employer szocho.',
        pensionAuthorityName: 'Hungarian Treasury (Magyar Allamkincstar) - Pension Directorate',
        pensionAuthorityWebsite: 'www.allamkincstar.gov.hu',
        pensionAuthorityPhone: '+36 1 452 2500',
      ),
      immigrantPensionRights: ImmigrantPensionRights(
        rightsForEuCitizens: 'Full equal treatment under EU Regulation 883/2004.',
        rightsForThirdCountryNationals: 'Equal rights if legally employed. Bilateral agreements with some countries.',
        minimumResidenceForStatePension: '20 years of service for full pension. 15 years minimum. EU/bilateral periods aggregated.',
        crossBorderCoordination: 'Hungarian Treasury handles EU pension coordination.',
        whatHappensIfYouLeave: 'Pension rights preserved and exportable to EU/EEA.',
        howToClaimFromAbroad: 'Apply through institution in country of residence.',
        pensionExportRules: 'Full export within EU/EEA. Bilateral agreement countries.',
        voluntaryContributions: 'Voluntary pension fund contributions possible. Also self-insurance agreements with pension directorate.',
        pensionTransferOptions: 'No capital transfer for Pillar 1. Voluntary fund balances portable.',
        bilateralAgreements: 'South Korea, Japan, Canada, Australia, India, Turkey, Ukraine, Russia, and others.',
      ),
      carInsurance: CarInsuranceInfo(
        mandatory: true,
        minimumCoverage: '6.07M EUR personal injury, 1.22M EUR property',
        averageAnnualCostTPL: 'HUF 30,000-120,000 (80-320 EUR)',
        averageAnnualCostFullCoverage: 'HUF 80,000-300,000 (215-800 EUR)',
        greenCardRequired: 'Not for EU vehicles.',
        foreignLicenseRules: 'EU licenses valid. Non-EU licenses valid 1 year, then must convert.',
        noClaimsDiscountTransfer: 'Bonus-malus system (A00-M04 classes). Foreign NCB rarely accepted directly.',
        howToGetAsImmigrant: 'Need Hungarian registration. Annual switching period November-December. Compare at netrisk.hu.',
        majorProviders: 'Allianz Hungaria, Generali, Groupama Biztosito, Magyar Posta Biztosito, Union',
      ),
      healthInsuranceSystem: 'NEAK (National Health Insurance Fund). Social insurance funded. TAJ card for access. Universal for insured persons.',
      healthInsuranceCostEmployee: '7% of gross salary (health + in-kind health components within 18.5% total)',
      healthInsuranceCostSelfEmployed: '13% szocho on declared income base',
      socialSecurityOverview: 'Employee: 18.5% consolidated social contribution. Employer: 13% szocho. Total ~31.5%. Covers pension, health, unemployment.',
      legalBasis: 'Act LXXX of 1997 (pension), Act LXXX of 1997 (health insurance), EU Reg 883/2004',
      immigrantSpecificNotes: 'Hungary nationalized private pension funds in 2011. Women with 40 years of eligibility (includes child-raising years) can retire at any age. Pension levels are relatively low. TAJ number essential. Asylum seekers receive basic healthcare through reception facilities.',
    ),

    // ============================================================
    // 14. IRELAND (IE)
    // ============================================================
    CountryInsurancePension(
      country: 'Ireland',
      countryCode: 'IE',
      mandatoryInsurance: [
        InsuranceType(
          type: 'Social Insurance (PRSI)',
          mandatory: true,
          averageMonthlyCost: 'Employee: 4% of gross income. Employer: 11.05%.',
          description: 'Pay Related Social Insurance covers pension, health, unemployment, maternity. Not health insurance per se - public healthcare through HSE. Medical cards for low income, GP visit cards.',
          howToGetAsImmigrant: 'Automatic when employed. Need PPS number (Personal Public Service number). Apply at Intreo center with ID and proof of address.',
        ),
        InsuranceType(
          type: 'Car Insurance (TPL)',
          mandatory: true,
          averageMonthlyCost: '80-200 EUR/month (Ireland has among highest car insurance in EU)',
          description: 'Third-party liability minimum. Ireland has notoriously expensive car insurance.',
          howToGetAsImmigrant: 'Need Irish registration (NCT for older cars). Very expensive for new drivers/immigrants without Irish driving history. Some insurers refuse non-Irish license holders.',
        ),
      ],
      recommendedInsurance: [
        InsuranceType(
          type: 'Private Health Insurance',
          mandatory: false,
          averageMonthlyCost: '80-200 EUR/month',
          description: 'Supplements public HSE system. Faster access to private hospitals. ~46% of population has private cover.',
          howToGetAsImmigrant: 'Available from VHI, Laya Healthcare, Irish Life Health. Waiting periods for pre-existing conditions (5-10 years). No loading if taken within 9 months of age 35.',
        ),
        InsuranceType(
          type: 'Home/Contents Insurance',
          mandatory: false,
          averageMonthlyCost: '30-60 EUR/month',
          description: 'Covers property contents, personal liability. Most landlords require tenants to have contents insurance.',
          howToGetAsImmigrant: 'Available from all Irish insurers.',
        ),
      ],
      pension: PensionInfo(
        systemType: 'Flat-rate state pension + voluntary occupational + auto-enrollment (coming 2025)',
        pillar1: 'State Pension (Contributory): flat-rate 277.30 EUR/week (2024) for full PRSI record. Non-Contributory: means-tested 266 EUR/week.',
        pillar2: 'Occupational pensions: voluntary. ~55% of workers covered. Auto-enrollment system launching 2025.',
        pillar3: 'Personal Retirement Savings Accounts (PRSAs), Retirement Annuity Contracts (RACs). Tax relief at marginal rate.',
        retirementAge: 66,
        retirementAgeWomen: 66,
        minimumContributionYears: 10,
        averageStatePensionMonthly: '1,200 EUR (full contributory pension)',
        minimumPensionMonthly: '1,153 EUR/month non-contributory (means-tested) / 1,204 EUR/month (minimum contributory rate)',
        maximumPensionMonthly: '1,204 EUR/month (277.30 EUR/week, full contributory rate, 2024)',
        contributionRate: 'PRSI: 4% employee + 11.05% employer = 15.05%. No earmarked pension %, covers all social insurance.',
        pensionAuthorityName: 'Department of Social Protection',
        pensionAuthorityWebsite: 'www.gov.ie/dsp',
        pensionAuthorityPhone: '+353 1 471 5898',
      ),
      immigrantPensionRights: ImmigrantPensionRights(
        rightsForEuCitizens: 'Full equal treatment under EU Regulation 883/2004. All EU PRSI/insurance periods count for Irish pension qualifying.',
        rightsForThirdCountryNationals: 'Equal PRSI rights when legally employed. Bilateral agreements with some countries.',
        minimumResidenceForStatePension: 'Contributory: 520 paid PRSI contributions (10 years). Yearly average test or Total Contributions Approach (TCA, being phased in). Non-contributory: habitual residence condition + means test.',
        crossBorderCoordination: 'Department of Social Protection handles EU coordination. Cross-border workers with Northern Ireland (UK) covered by UK-EU TCA.',
        whatHappensIfYouLeave: 'PRSI contributions preserved indefinitely. Contributory pension payable worldwide. Non-contributory pension: Ireland residence only.',
        howToClaimFromAbroad: 'Apply through institution in country of residence. Department of Social Protection processes.',
        pensionExportRules: 'Contributory pension exportable worldwide without reduction. Non-contributory pension NOT exportable (Ireland residence only).',
        voluntaryContributions: 'Voluntary PRSI contributions available if previously paid PRSI. 500 EUR/year flat rate. Useful for maintaining pension entitlement while abroad.',
        pensionTransferOptions: 'No Pillar 1 transfer. PRSAs and occupational pensions may be transferred within Ireland or to QROPS.',
        bilateralAgreements: 'USA, Canada, Australia, New Zealand, Japan, South Korea, and others.',
      ),
      carInsurance: CarInsuranceInfo(
        mandatory: true,
        minimumCoverage: '6.45M EUR personal injury, 1.3M EUR property',
        averageAnnualCostTPL: '1,000-2,500 EUR',
        averageAnnualCostFullCoverage: '1,500-4,000 EUR',
        greenCardRequired: 'Not for EU vehicles.',
        foreignLicenseRules: 'EU licenses valid. Non-EU licenses recognized for 1 year. Must exchange or take Irish test. Full Irish license requires theory test + 12 Essential Driver Training lessons + driving test.',
        noClaimsDiscountTransfer: 'Very difficult. Most Irish insurers do NOT accept foreign NCB. Major issue for immigrants. Some accept from UK/US/Australia with proof.',
        howToGetAsImmigrant: 'Extremely expensive for new/immigrant drivers. Expect 2,000-4,000+ EUR initially. Compare at bonkers.ie, insuremycar.ie. Start building Irish NCB immediately.',
        majorProviders: 'AXA Ireland, Aviva, Allianz, Zurich, FBD, Liberty Insurance, RSA',
      ),
      healthInsuranceSystem: 'Public healthcare through HSE (Health Service Executive). GP visits: 55-65 EUR unless GP Visit Card/Medical Card. Hospital: free in public hospitals with referral. A&E: 100 EUR charge without referral.',
      healthInsuranceCostEmployee: 'PRSI 4% covers social insurance broadly. No separate health premium. USC (Universal Social Charge) 0.5-8% also partially funds health.',
      healthInsuranceCostSelfEmployed: 'PRSI Class S: 4% of income. USC same rates.',
      socialSecurityOverview: 'PRSI: 4% employee + 11.05% employer. USC: 0.5-8%. Income tax: 20%/40%. Total tax wedge high but social security component relatively low.',
      legalBasis: 'Social Welfare Consolidation Act 2005, Pensions Act 1990, Health Act 1970, EU Reg 883/2004',
      immigrantSpecificNotes: 'Ireland has flat-rate state pension (not earnings-related for Pillar 1). Auto-enrollment starting 2025 will improve Pillar 2 coverage. Car insurance is extremely expensive for immigrants - this is a major financial challenge. Medical card provides free GP and hospital care for low-income residents. Habitual Residence Condition (HRC) must be satisfied for most social welfare payments.',
    ),

    // ============================================================
    // 15. ITALY (IT)
    // ============================================================
    CountryInsurancePension(
      country: 'Italy',
      countryCode: 'IT',
      mandatoryInsurance: [
        InsuranceType(
          type: 'Health Insurance (SSN)',
          mandatory: true,
          averageMonthlyCost: 'Tax-funded + regional surcharge (addizionale regionale IRPEF: 1.23-3.33%). No separate health premium.',
          description: 'Servizio Sanitario Nazionale (SSN). Universal coverage for all legal residents. Free GP (medico di base), hospital care, emergency. Co-payments (ticket) for specialists and prescriptions.',
          howToGetAsImmigrant: 'Register with local ASL (Azienda Sanitaria Locale) with codice fiscale, residence permit, and residence certificate. Choose a GP (medico di base). Get tessera sanitaria (health card).',
        ),
        InsuranceType(
          type: 'Car Insurance (TPL)',
          mandatory: true,
          averageMonthlyCost: '30-100 EUR/month (varies hugely by region: Naples highest, Aosta lowest)',
          description: 'RCA (Responsabilita Civile Auto) mandatory. Italy has significant regional price variation.',
          howToGetAsImmigrant: 'Need Italian registration (targhe), valid license. Compare at facile.it, segugio.it, preventivass.it.',
        ),
      ],
      recommendedInsurance: [
        InsuranceType(
          type: 'Home Insurance',
          mandatory: false,
          averageMonthlyCost: '15-40 EUR/month',
          description: 'Assicurazione casa covers property and contents. Earthquake coverage important in seismic zones.',
          howToGetAsImmigrant: 'Available from all Italian insurers. Mandatory for subsidized mortgages post-earthquake.',
        ),
        InsuranceType(
          type: 'Private Health Insurance',
          mandatory: false,
          averageMonthlyCost: '50-150 EUR/month',
          description: 'Polizza sanitaria supplements SSN. Faster access, private clinics.',
          howToGetAsImmigrant: 'Available from UniSalute, Previmedical, Generali, Allianz.',
        ),
      ],
      pension: PensionInfo(
        systemType: 'Pay-as-you-go notional defined contribution (NDC since 1995 Dini reform)',
        pillar1: 'INPS pension: NDC (contributivo) for new workers since 1996. Mixed (misto) for those with pre-1996 contributions. Retributivo for pre-1996 service.',
        pillar2: 'Supplementary pension funds (fondi pensione complementare): quasi-mandatory through TFR (severance pay) diversion option.',
        pillar3: 'Individual pension plans (PIP): tax-advantaged up to 5,164.57 EUR/year.',
        retirementAge: 67,
        retirementAgeWomen: 67,
        minimumContributionYears: 20,
        averageStatePensionMonthly: '1,170 EUR',
        minimumPensionMonthly: '598 EUR (integrazione al trattamento minimo, if income below threshold)',
        maximumPensionMonthly: 'No statutory cap under contributivo. Based on contributions.',
        contributionRate: '33% for employees (9.19% employee + 23.81% employer). Self-employed: 25.72% (artisans/traders) or 26.23% (professionals).',
        pensionAuthorityName: 'INPS (Istituto Nazionale della Previdenza Sociale)',
        pensionAuthorityWebsite: 'www.inps.it',
        pensionAuthorityPhone: '+39 06 164 164',
      ),
      immigrantPensionRights: ImmigrantPensionRights(
        rightsForEuCitizens: 'Full equal treatment under EU Regulation 883/2004.',
        rightsForThirdCountryNationals: 'Equal rights when legally employed. Extensive bilateral agreements. Special social allowance (assegno sociale) requires 10 years of legal residence.',
        minimumResidenceForStatePension: '20 years of contributions for old-age pension (or 5 years under pure contributivo at age 71). Assegno sociale: 10 years of continuous legal residence.',
        crossBorderCoordination: 'INPS handles EU coordination. Italy has millions of pensioners abroad (diaspora).',
        whatHappensIfYouLeave: 'Pension rights preserved and exportable. INPS pays pensions to 160+ countries.',
        howToClaimFromAbroad: 'Apply through institution in country of residence or directly to INPS. Patronati (trade union assistance offices) abroad help free of charge.',
        pensionExportRules: 'Contributory pension exportable worldwide. Assegno sociale: Italy residence only. Integrazione al minimo: only within EU/bilateral countries.',
        voluntaryContributions: 'Voluntary INPS contributions (prosecuzione volontaria) possible if previously insured. Also riscatto laurea (buy-back university years).',
        pensionTransferOptions: 'No capital transfer. Totalizzazione (totalization) allows combining periods across Italian pension funds.',
        bilateralAgreements: 'Argentina, Australia, Brazil, Canada, USA, Venezuela, Tunisia, Turkey, and many others (large Italian diaspora).',
      ),
      carInsurance: CarInsuranceInfo(
        mandatory: true,
        minimumCoverage: '6.45M EUR personal injury, 1.3M EUR property',
        averageAnnualCostTPL: '400-1,500 EUR (huge regional variation)',
        averageAnnualCostFullCoverage: '800-3,000 EUR',
        greenCardRequired: 'Not for EU vehicles.',
        foreignLicenseRules: 'EU licenses valid. Non-EU licenses valid 1 year. Must convert (some countries exempt from driving test).',
        noClaimsDiscountTransfer: 'CU (Classe Universale) merit class system. Start at CU 14 (new driver). Foreign NCB: attestato di rischio from previous insurer may be accepted.',
        howToGetAsImmigrant: 'Need Italian plates, valid license. Southern Italy significantly more expensive. Compare at facile.it, segugio.it. Bersani law allows family CU class transfer.',
        majorProviders: 'Generali, Unipol, Allianz, AXA, Cattolica, Zurich, Vittoria',
      ),
      healthInsuranceSystem: 'SSN (Servizio Sanitario Nazionale). Universal tax-funded. Regional management. Free GP, hospital, emergency. Ticket (co-payment) for specialists/prescriptions.',
      healthInsuranceCostEmployee: 'No separate health premium. Funded through general taxation and regional IRPEF surcharge.',
      healthInsuranceCostSelfEmployed: 'Same tax structure. INPS contributions cover pension/social security, not health separately.',
      socialSecurityOverview: 'Total: ~40% of gross for employees (9.19% employee + ~30% employer including pension, sickness, maternity, unemployment, TFR).',
      legalBasis: 'Law 335/1995 (Dini reform), Law 214/2011 (Fornero reform), D.Lgs. 209/2005 (insurance code), EU Reg 883/2004',
      immigrantSpecificNotes: 'Italy provides healthcare to undocumented immigrants through STP (Straniero Temporaneamente Presente) code - emergency and essential care. Legal residents get full SSN access. Pension contributions are high (33%) but pension levels reasonable. Patronati offices provide free help with pension claims worldwide for Italians abroad. Car insurance: extreme regional variation.',
    ),

    // ============================================================
    // 16. LATVIA (LV)
    // ============================================================
    CountryInsurancePension(
      country: 'Latvia',
      countryCode: 'LV',
      mandatoryInsurance: [
        InsuranceType(
          type: 'Health Insurance',
          mandatory: true,
          averageMonthlyCost: 'Funded through social contributions (part of 34.09% total). Mandatory patient co-payments.',
          description: 'National Health Service (NVD). Tax-funded universal system. Covers primary care, hospital, emergency. Co-payments required for many services.',
          howToGetAsImmigrant: 'Automatic for employed persons. Must register GP. Need personal code (personas kods). Non-employed: must pay mandatory health insurance fee (50 EUR/month).',
        ),
        InsuranceType(
          type: 'Car Insurance (TPL)',
          mandatory: true,
          averageMonthlyCost: '100-400 EUR/year',
          description: 'OCTA mandatory.',
          howToGetAsImmigrant: 'Need Latvian registration.',
        ),
      ],
      recommendedInsurance: [
        InsuranceType(
          type: 'Private Health Insurance',
          mandatory: false,
          averageMonthlyCost: '30-80 EUR/month',
          description: 'Supplements public system significantly. Many employers offer as benefit.',
          howToGetAsImmigrant: 'Available from Balta, BTA, Ergo, If. Very common as employer benefit.',
        ),
      ],
      pension: PensionInfo(
        systemType: 'Three-pillar: NDC PAYG + mandatory funded + voluntary',
        pillar1: 'State pension (NDC - notional defined contribution): 14% of social contributions. Pension capital = indexed lifetime contributions.',
        pillar2: 'Mandatory funded pension: 6% of gross salary to chosen fund (Luminor, SEB, Swedbank, etc.)',
        pillar3: 'Voluntary private pension funds with tax incentives',
        retirementAge: 65,
        retirementAgeWomen: 65,
        minimumContributionYears: 15,
        averageStatePensionMonthly: '520 EUR',
        minimumPensionMonthly: '171 EUR (minimum state pension for 15 years)',
        maximumPensionMonthly: '~1,500 EUR (Pillar 1 alone, for very high earners)',
        contributionRate: '34.09% total (10.50% employee + 23.59% employer). Of this: 20% pension (14% Pillar 1 + 6% Pillar 2).',
        pensionAuthorityName: 'State Social Insurance Agency (VSAA)',
        pensionAuthorityWebsite: 'www.vsaa.gov.lv',
        pensionAuthorityPhone: '+371 64 507 020',
      ),
      immigrantPensionRights: ImmigrantPensionRights(
        rightsForEuCitizens: 'Full equal treatment under EU Regulation 883/2004.',
        rightsForThirdCountryNationals: 'Equal rights if legally employed. Bilateral agreements with Ukraine, Russia, Canada, and others.',
        minimumResidenceForStatePension: '15 years of insurance periods. EU/bilateral periods count.',
        crossBorderCoordination: 'VSAA handles EU pension coordination.',
        whatHappensIfYouLeave: 'Pillar 1 pension preserved and exportable. Pillar 2 funded pension remains invested in chosen fund.',
        howToClaimFromAbroad: 'Apply through institution in country of residence.',
        pensionExportRules: 'Full export within EU/EEA. Bilateral agreement countries.',
        voluntaryContributions: 'Voluntary membership in state social insurance possible.',
        pensionTransferOptions: 'Pillar 2 funds remain in Latvia. Can switch fund managers.',
        bilateralAgreements: 'Russia, Ukraine, Canada, Belarus, and others.',
      ),
      carInsurance: CarInsuranceInfo(
        mandatory: true,
        minimumCoverage: '5.6M EUR personal injury, 1.2M EUR property',
        averageAnnualCostTPL: '100-400 EUR',
        averageAnnualCostFullCoverage: '300-1,000 EUR',
        greenCardRequired: 'Not for EU vehicles.',
        foreignLicenseRules: 'EU licenses valid. Non-EU licenses valid with IDP for 1 year. Must convert for residence.',
        noClaimsDiscountTransfer: 'Bonus-malus system. Some acceptance of foreign history.',
        howToGetAsImmigrant: 'Need Latvian registration. LTAB (Motor Insurers Bureau) oversees market.',
        majorProviders: 'Balta, BTA, If Latvia, Ergo, Compensa',
      ),
      healthInsuranceSystem: 'NVD (National Health Service). Tax-funded through social contributions. GP gatekeeping. Co-payments for specialists and hospital stays.',
      healthInsuranceCostEmployee: 'Included in 34.09% social contributions. Non-employed must pay 50 EUR/month mandatory health contribution.',
      healthInsuranceCostSelfEmployed: 'Social contributions on declared income. Minimum contribution base applies.',
      socialSecurityOverview: 'Total: 34.09% (10.50% employee + 23.59% employer). Covers pension, health, disability, maternity, unemployment.',
      legalBasis: 'Law on State Pensions, Law on State Funded Pensions, EU Reg 883/2004',
      immigrantSpecificNotes: 'Latvia has relatively low pension levels. Pillar 2 mandatory funded pension important for total retirement income. Non-employed must pay 50 EUR/month health contribution or lose access to state healthcare. Russian-speaking community significant - many services in Russian.',
    ),

    // ============================================================
    // 17. LITHUANIA (LT)
    // ============================================================
    CountryInsurancePension(
      country: 'Lithuania',
      countryCode: 'LT',
      mandatoryInsurance: [
        InsuranceType(
          type: 'Health Insurance (PSD)',
          mandatory: true,
          averageMonthlyCost: '6.98% of income (PSD - compulsory health insurance)',
          description: 'National Health Insurance Fund (VLK). Universal for insured persons. Covers GP, specialists, hospital, dental basics, prescriptions.',
          howToGetAsImmigrant: 'Automatic when employed (employer deducts PSD). Self-employed pay directly. Non-working: covered if receiving social benefits, or pay minimum PSD contribution.',
        ),
        InsuranceType(
          type: 'Car Insurance (TPL)',
          mandatory: true,
          averageMonthlyCost: '80-300 EUR/year',
          description: 'TPVCA mandatory.',
          howToGetAsImmigrant: 'Need Lithuanian registration. Compare at draudimas.lt.',
        ),
      ],
      recommendedInsurance: [
        InsuranceType(
          type: 'Private Health Insurance',
          mandatory: false,
          averageMonthlyCost: '20-60 EUR/month',
          description: 'Supplements public system. Many employers offer as benefit (very common).',
          howToGetAsImmigrant: 'Available from Compensa, ERGO, Lietuvos draudimas, If.',
        ),
      ],
      pension: PensionInfo(
        systemType: 'Three-pillar: PAYG social insurance + voluntary funded + voluntary private',
        pillar1: 'State social insurance pension (Sodra): basic part + individual part based on insurance points. Reformed 2019.',
        pillar2: 'Voluntary funded pension (II pillar): opt-in with state matching contributions (1.5% from state + 3% personal from 2024). ~80% of workers participate.',
        pillar3: 'Voluntary private pension: tax-incentivized (deductible up to 25% of income)',
        retirementAge: 65,
        retirementAgeWomen: 65,
        minimumContributionYears: 15,
        averageStatePensionMonthly: '590 EUR',
        minimumPensionMonthly: '256 EUR (basic pension amount)',
        maximumPensionMonthly: '~1,200 EUR',
        contributionRate: 'Employee: 19.5% (pension 8.72% + health 6.98% + unemployment 0.8% + other). Employer: 1.77% + 1.4-3.6% accident.',
        pensionAuthorityName: 'Sodra (State Social Insurance Fund Board)',
        pensionAuthorityWebsite: 'www.sodra.lt',
        pensionAuthorityPhone: '+370 5 250 0883',
      ),
      immigrantPensionRights: ImmigrantPensionRights(
        rightsForEuCitizens: 'Full equal treatment under EU Regulation 883/2004.',
        rightsForThirdCountryNationals: 'Equal rights if legally employed. Bilateral agreements with some countries.',
        minimumResidenceForStatePension: '15 years of insurance periods for minimum pension. 30 years for full basic portion.',
        crossBorderCoordination: 'Sodra handles EU coordination.',
        whatHappensIfYouLeave: 'Pillar 1 pension preserved. Pillar 2 funds remain invested.',
        howToClaimFromAbroad: 'Apply through institution in country of residence.',
        pensionExportRules: 'Full export within EU/EEA. Bilateral agreement countries.',
        voluntaryContributions: 'Voluntary social insurance possible.',
        pensionTransferOptions: 'Pillar 2 funds remain in Lithuanian fund managers.',
        bilateralAgreements: 'Russia, Ukraine, Belarus, Canada, USA, and others.',
      ),
      carInsurance: CarInsuranceInfo(
        mandatory: true,
        minimumCoverage: '5.6M EUR personal injury, 1.2M EUR property',
        averageAnnualCostTPL: '80-300 EUR',
        averageAnnualCostFullCoverage: '250-800 EUR',
        greenCardRequired: 'Not for EU vehicles.',
        foreignLicenseRules: 'EU licenses valid. Non-EU licenses valid 1 year. Conversion required.',
        noClaimsDiscountTransfer: 'Bonus-malus system used.',
        howToGetAsImmigrant: 'Need Lithuanian registration.',
        majorProviders: 'Lietuvos draudimas, If, ERGO, Compensa, BTA',
      ),
      healthInsuranceSystem: 'VLK (National Health Insurance Fund). Universal for insured. Funded through PSD contributions. GP gatekeeping.',
      healthInsuranceCostEmployee: '6.98% PSD from employee income',
      healthInsuranceCostSelfEmployed: '6.98% of declared income',
      socialSecurityOverview: 'Employee: 19.5% total. Employer: ~3-5%. Lithuania shifted most contributions to employee side in 2019 reform (with gross salary increase).',
      legalBasis: 'Law on Social Insurance Pensions, Health Insurance Law, EU Reg 883/2004',
      immigrantSpecificNotes: 'Lithuania reformed its system in 2019, shifting contributions to employee side. Pillar 2 very popular (~80% participation). Pension levels modest but growing. Russian-speaking minority: services available in Russian in some areas.',
    ),

    // ============================================================
    // 18. LUXEMBOURG (LU)
    // ============================================================
    CountryInsurancePension(
      country: 'Luxembourg',
      countryCode: 'LU',
      mandatoryInsurance: [
        InsuranceType(
          type: 'Health Insurance (CNS)',
          mandatory: true,
          averageMonthlyCost: 'Employee: 3.05% of gross. Employer: 3.05%. State: 40% of healthcare costs.',
          description: 'Caisse Nationale de Sante (CNS). Mandatory universal coverage. Very generous: reimburses 80-100% of most healthcare costs.',
          howToGetAsImmigrant: 'Automatic when employed. CNS affiliation via CCSS (Centre Commun de la Securite Sociale). Get CNS card. Dependents co-insured.',
        ),
        InsuranceType(
          type: 'Car Insurance (TPL)',
          mandatory: true,
          averageMonthlyCost: '40-120 EUR/month',
          description: 'RC automobile mandatory. Luxembourg has relatively high insurance costs.',
          howToGetAsImmigrant: 'Need Luxembourg registration. Compare at atoz.lu.',
        ),
      ],
      recommendedInsurance: [
        InsuranceType(
          type: 'Complementary Health Insurance',
          mandatory: false,
          averageMonthlyCost: '20-60 EUR/month',
          description: 'Covers remaining co-payments after CNS reimbursement. Hospital room upgrades.',
          howToGetAsImmigrant: 'Available from DKV, Foyer, La Luxembourgeoise.',
        ),
      ],
      pension: PensionInfo(
        systemType: 'Pay-as-you-go with significant reserves',
        pillar1: 'State pension (CNAP): very generous. Fixed part + proportional part + end-of-year allowance. Accrual: 1.85% of career earnings per year.',
        pillar2: 'Occupational pensions: common in financial sector. Tax-advantaged.',
        pillar3: 'Private pension products with tax deduction up to 3,200 EUR/year',
        retirementAge: 65,
        retirementAgeWomen: 65,
        minimumContributionYears: 10,
        averageStatePensionMonthly: '3,900 EUR (among highest in EU)',
        minimumPensionMonthly: '2,085 EUR (minimum pension for 40 years, 2024)',
        maximumPensionMonthly: '~9,400 EUR (5/6 of 5x minimum social wage)',
        contributionRate: '24% for pension (8% employee + 8% employer + 8% state)',
        pensionAuthorityName: 'CNAP (Caisse Nationale d Assurance Pension)',
        pensionAuthorityWebsite: 'www.cnap.lu',
        pensionAuthorityPhone: '+352 22 41 41 1',
      ),
      immigrantPensionRights: ImmigrantPensionRights(
        rightsForEuCitizens: 'Full equal treatment. Critical for many cross-border workers (200,000+ commuters from France, Belgium, Germany).',
        rightsForThirdCountryNationals: 'Equal rights if legally employed. Bilateral agreements with several countries.',
        minimumResidenceForStatePension: '10 years of mandatory insurance periods (120 months). EU/bilateral periods aggregated.',
        crossBorderCoordination: 'CNAP very experienced with cross-border cases. Luxembourg has more cross-border pension cases per capita than any EU country.',
        whatHappensIfYouLeave: 'Pension rights fully preserved and exportable. Luxembourg pension follows you worldwide.',
        howToClaimFromAbroad: 'Apply through institution in country of residence. CNAP processes Luxembourg portion. Online portal available.',
        pensionExportRules: 'Full export worldwide without reduction (very generous policy).',
        voluntaryContributions: 'Voluntary continued insurance possible if previously insured. Also voluntary insurance for certain categories.',
        pensionTransferOptions: 'No Pillar 1 capital transfer. Occupational pensions may be transferable under IORP II.',
        bilateralAgreements: 'Brazil, Cape Verde, India, Morocco, Tunisia, Turkey, USA, Canada, Chile, and others.',
      ),
      carInsurance: CarInsuranceInfo(
        mandatory: true,
        minimumCoverage: '100M EUR combined (among highest in world)',
        averageAnnualCostTPL: '500-1,500 EUR',
        averageAnnualCostFullCoverage: '1,000-3,500 EUR',
        greenCardRequired: 'Not for EU vehicles.',
        foreignLicenseRules: 'EU licenses valid. Non-EU licenses valid 1 year. Must exchange.',
        noClaimsDiscountTransfer: 'Bonus-malus system. Foreign NCB may be accepted.',
        howToGetAsImmigrant: 'Need Luxembourg registration (SNCT inspection). Compare at atoz.lu.',
        majorProviders: 'Foyer, La Luxembourgeoise, AXA Luxembourg, Baloise, DKV',
      ),
      healthInsuranceSystem: 'CNS (Caisse Nationale de Sante). Universal mandatory. Very generous reimbursement rates (80-100%). CCSS manages contributions.',
      healthInsuranceCostEmployee: '3.05% employee + 3.05% employer + state subsidy',
      healthInsuranceCostSelfEmployed: '6.10% of declared income',
      socialSecurityOverview: 'Total contributions ~25% employee + ~12-15% employer (not including pension state share). Very comprehensive coverage.',
      legalBasis: 'Code de la securite sociale, EU Reg 883/2004',
      immigrantSpecificNotes: 'Luxembourg has the highest pensions in the EU. Average pension ~3,900 EUR/month. 200,000+ cross-border workers from neighboring countries. CNS coverage is excellent. Most financial sector employees also have generous occupational pensions. Very international workforce - many languages spoken in administrative offices.',
    ),

    // ============================================================
    // 19. MALTA (MT)
    // ============================================================
    CountryInsurancePension(
      country: 'Malta',
      countryCode: 'MT',
      mandatoryInsurance: [
        InsuranceType(
          type: 'Health Insurance / Social Security',
          mandatory: true,
          averageMonthlyCost: '10% employee + 10% employer social security contributions cover health and pension',
          description: 'National health system tax-funded. Free public healthcare for residents. Social security contributions cover pension and sickness benefits.',
          howToGetAsImmigrant: 'Need social security number. Register at Department of Social Security. Employment triggers automatic coverage. Third-country nationals: private health insurance required for residence permit.',
        ),
        InsuranceType(
          type: 'Car Insurance (TPL)',
          mandatory: true,
          averageMonthlyCost: '300-800 EUR/year',
          description: 'Motor vehicle third-party liability insurance mandatory.',
          howToGetAsImmigrant: 'Need Maltese registration. Drive on LEFT. Compare at laferla.com.mt.',
        ),
      ],
      recommendedInsurance: [
        InsuranceType(
          type: 'Private Health Insurance',
          mandatory: false,
          averageMonthlyCost: '40-120 EUR/month',
          description: 'Supplements public system. Required for non-EU residence permits.',
          howToGetAsImmigrant: 'Required for third-country national residence permits. Available from Citadel, GasanMamo, Mapfre Middlesea.',
        ),
      ],
      pension: PensionInfo(
        systemType: 'Pay-as-you-go social security pension',
        pillar1: 'Two-Thirds pension: aims to provide 2/3 of average income over best 3 consecutive calendar years in last 10. Subject to minimum and maximum.',
        pillar2: 'Occupational pensions: limited market. Government encouraging expansion.',
        pillar3: 'Voluntary private pensions with some tax advantages',
        retirementAge: 65,
        retirementAgeWomen: 65,
        minimumContributionYears: 10,
        averageStatePensionMonthly: '800 EUR',
        minimumPensionMonthly: '700 EUR (minimum pension 2024)',
        maximumPensionMonthly: '1,375 EUR (maximum pension 2024)',
        contributionRate: '20% total (10% employee + 10% employer). Self-employed: 15%.',
        pensionAuthorityName: 'Department of Social Security',
        pensionAuthorityWebsite: 'www.socialsecurity.gov.mt',
        pensionAuthorityPhone: '+356 2590 3200',
      ),
      immigrantPensionRights: ImmigrantPensionRights(
        rightsForEuCitizens: 'Full equal treatment under EU Regulation 883/2004.',
        rightsForThirdCountryNationals: 'Equal rights if legally employed. Limited bilateral agreements.',
        minimumResidenceForStatePension: '10 years of contributions minimum. Aggregation with EU periods.',
        crossBorderCoordination: 'Department of Social Security handles EU coordination.',
        whatHappensIfYouLeave: 'Pension rights preserved and exportable.',
        howToClaimFromAbroad: 'Apply through institution in country of residence.',
        pensionExportRules: 'Full export within EU/EEA.',
        voluntaryContributions: 'Voluntary social security contributions possible.',
        pensionTransferOptions: 'No capital transfer.',
        bilateralAgreements: 'Australia, Canada, and a few others.',
      ),
      carInsurance: CarInsuranceInfo(
        mandatory: true,
        minimumCoverage: '1.2M EUR personal injury, 1.2M EUR property',
        averageAnnualCostTPL: '300-800 EUR',
        averageAnnualCostFullCoverage: '600-1,800 EUR',
        greenCardRequired: 'Not for EU vehicles.',
        foreignLicenseRules: 'EU licenses valid. Non-EU licenses valid 1 year. Drive on LEFT.',
        noClaimsDiscountTransfer: 'May be accepted with documentation.',
        howToGetAsImmigrant: 'Need Maltese plates. Small island = high accident density per km.',
        majorProviders: 'GasanMamo, Mapfre Middlesea, Citadel, Elmo Insurance, Atlas',
      ),
      healthInsuranceSystem: 'Tax-funded national health service. Free at point of use in public sector. Mater Dei Hospital is main public hospital.',
      healthInsuranceCostEmployee: 'Included in 10% social security contribution',
      healthInsuranceCostSelfEmployed: '15% of net income (covers all social security)',
      socialSecurityOverview: '20% total (10% + 10%). Covers pension, sickness, unemployment, maternity. Health system tax-funded separately.',
      legalBasis: 'Social Security Act (Cap 318), EU Reg 883/2004',
      immigrantSpecificNotes: 'Malta requires private health insurance for non-EU residence permits. Small island with limited healthcare capacity - serious cases may be sent abroad. Maximum pension is capped relatively low. Drive on left. English widely spoken in administration.',
    ),

    // ============================================================
    // 20. NETHERLANDS (NL)
    // ============================================================
    CountryInsurancePension(
      country: 'Netherlands',
      countryCode: 'NL',
      mandatoryInsurance: [
        InsuranceType(
          type: 'Health Insurance (Zorgverzekeringswet)',
          mandatory: true,
          averageMonthlyCost: '130-170 EUR/month basic premium + 385 EUR/year deductible (eigen risico). Employer: 6.68% income-dependent contribution.',
          description: 'Mandatory private health insurance (Zvw). Must choose insurer within 4 months of arrival. Basic package standardized. Mandatory deductible 385 EUR/year.',
          howToGetAsImmigrant: 'MUST arrange within 4 months of registering in BRP (population register). Choose from ~20 insurers. Zorgtoeslag (healthcare allowance) available for low incomes via Belastingdienst.',
        ),
        InsuranceType(
          type: 'Car Insurance (TPL)',
          mandatory: true,
          averageMonthlyCost: '30-80 EUR/month',
          description: 'WA-verzekering (Wettelijke Aansprakelijkheid) mandatory for all registered vehicles.',
          howToGetAsImmigrant: 'Need Dutch registration (RDW). Compare at independer.nl, pricewise.nl.',
        ),
      ],
      recommendedInsurance: [
        InsuranceType(
          type: 'Supplementary Health Insurance',
          mandatory: false,
          averageMonthlyCost: '10-60 EUR/month',
          description: 'Aanvullende verzekering covers dental, physiotherapy beyond basic, glasses, alternative medicine.',
          howToGetAsImmigrant: 'Available from all health insurers alongside basic package.',
        ),
        InsuranceType(
          type: 'Liability Insurance',
          mandatory: false,
          averageMonthlyCost: '3-8 EUR/month',
          description: 'Aansprakelijkheidsverzekering (AVP). Covers damage you cause to others. Universally recommended.',
          howToGetAsImmigrant: 'Available from all Dutch insurers. Very affordable and important.',
        ),
        InsuranceType(
          type: 'Home Contents Insurance',
          mandatory: false,
          averageMonthlyCost: '10-25 EUR/month',
          description: 'Inboedelverzekering. Many landlords require it.',
          howToGetAsImmigrant: 'Available from all insurers. Often bundled with liability.',
        ),
      ],
      pension: PensionInfo(
        systemType: 'Three-pillar: universal state (AOW) + quasi-mandatory occupational + voluntary',
        pillar1: 'AOW (Algemene Ouderdomswet): universal flat-rate state pension. Builds up 2% per year of residence/work between age 15 and pension age. Full after 50 years.',
        pillar2: 'Occupational pensions: quasi-mandatory through sectoral/company funds. ~90% of employees covered. Average accrual ~1.75%/year. Being reformed to defined contribution (Wet Toekomst Pensioenen 2023).',
        pillar3: 'Individual pension products (lijfrente): tax-deductible up to annual limit.',
        retirementAge: 67,
        retirementAgeWomen: 67,
        minimumContributionYears: 0,
        averageStatePensionMonthly: '1,380 EUR (full AOW single, gross, 2024) + occupational average ~800 EUR = ~2,180 EUR total',
        minimumPensionMonthly: '1,380 EUR gross (full AOW single) / 950 EUR (AOW for partnered person). Reduced by 2% per missing year.',
        maximumPensionMonthly: '1,380 EUR AOW + unlimited occupational pension',
        contributionRate: 'AOW: 17.9% (employee only, integrated into income tax). Occupational: varies by fund, typically 20-30% of pensionable salary (shared).',
        pensionAuthorityName: 'SVB (Sociale Verzekeringsbank) for AOW + individual pension funds',
        pensionAuthorityWebsite: 'www.svb.nl',
        pensionAuthorityPhone: '+31 20 65 65 656',
      ),
      immigrantPensionRights: ImmigrantPensionRights(
        rightsForEuCitizens: 'Full equal treatment. AOW builds up 2% per year of residence/work in NL. EU periods may count for qualifying conditions but NOT for AOW calculation.',
        rightsForThirdCountryNationals: 'Same rules. AOW based on residence/work in NL specifically. Bilateral agreements for qualifying conditions only.',
        minimumResidenceForStatePension: 'No minimum! Each year of residence between 15 and pension age = 2% of full AOW. Even 1 year = 2% pension.',
        crossBorderCoordination: 'SVB handles AOW coordination. Individual pension funds handle occupational pensions. Very common cross-border cases (many expats in NL).',
        whatHappensIfYouLeave: 'AOW: you STOP accruing. Can buy voluntary AOW insurance (vrijwillige verzekering) for up to 10 years after leaving. Occupational pension: preserved in fund.',
        howToClaimFromAbroad: 'SVB pays AOW worldwide. Apply through institution in residence country or directly at SVB.',
        pensionExportRules: 'AOW exportable worldwide (proportional to years built up). Occupational pensions exportable.',
        voluntaryContributions: 'Voluntary AOW insurance available for up to 10 years after leaving NL. Cost: 17.9% of worldwide income. Expensive but valuable.',
        pensionTransferOptions: 'No AOW transfer. Occupational pensions stay in Dutch fund until retirement. International value transfer of occupational pensions possible under certain conditions.',
        bilateralAgreements: 'Morocco, Turkey, Tunisia, USA, Canada, Australia, New Zealand, Japan, South Korea, India, and many others.',
      ),
      carInsurance: CarInsuranceInfo(
        mandatory: true,
        minimumCoverage: '6.45M EUR combined',
        averageAnnualCostTPL: '400-1,000 EUR',
        averageAnnualCostFullCoverage: '700-2,000 EUR',
        greenCardRequired: 'Not for EU vehicles.',
        foreignLicenseRules: 'EU licenses valid. Non-EU licenses: valid 185 days after registration. Must exchange (only ~35 countries have exchange agreement without test). Others need full Dutch driving exam.',
        noClaimsDiscountTransfer: 'Schadevrije jaren system. Up to 75% discount for 15+ claim-free years. Foreign NCB sometimes accepted with letter (not guaranteed).',
        howToGetAsImmigrant: 'Need Dutch registration (RDW kenteken). Compare at independer.nl, pricewise.nl, poliswijzer.nl.',
        majorProviders: 'Centraal Beheer, ANWB, Interpolis, Unive, OHRA, InShared',
      ),
      healthInsuranceSystem: 'Mandatory private insurance (Zvw) with standardized basic package. Competition between ~20 insurers. Zorgtoeslag (allowance) for low income. Long-term care: Wlz (separate).',
      healthInsuranceCostEmployee: '130-170 EUR/month premium + 6.68% income-dependent employer contribution (capped at ~71,628 EUR)',
      healthInsuranceCostSelfEmployed: '130-170 EUR/month premium + 5.43% income-dependent contribution (self-paid)',
      socialSecurityOverview: 'Employee: ~28% (AOW 17.9% + Wlz 9.65% + health premium). Employer: ~20% (health 6.68% + WW/WAO/ZW ~10% + other). Total tax wedge high.',
      legalBasis: 'Zorgverzekeringswet (Zvw), AOW, Wet Toekomst Pensioenen (WTP 2023), Pensioenwet, EU Reg 883/2004',
      immigrantSpecificNotes: 'Netherlands REQUIRES health insurance within 4 months - fines for non-compliance (486.66 EUR/month retroactive). AOW builds per year of residence (2%/year). If you leave NL, you STOP building AOW - consider voluntary insurance. Occupational pensions being reformed to DC system (WTP). Zorgtoeslag helps low-income with health insurance costs (~130 EUR/month max). CAK administers fines for uninsured.',
    ),

    // ============================================================
    // 21. POLAND (PL)
    // ============================================================
    CountryInsurancePension(
      country: 'Poland',
      countryCode: 'PL',
      mandatoryInsurance: [
        InsuranceType(
          type: 'Health Insurance (NFZ)',
          mandatory: true,
          averageMonthlyCost: '9% of gross income (assessment base). Employer deducts for employees.',
          description: 'National Health Fund (NFZ). Universal for insured. Covers comprehensive care including GP, specialists, hospital, prescriptions.',
          howToGetAsImmigrant: 'Automatic when employed. Need PESEL number and eWUS (electronic system confirms insurance status). Self-employed: register with ZUS.',
        ),
        InsuranceType(
          type: 'Car Insurance (TPL)',
          mandatory: true,
          averageMonthlyCost: 'PLN 400-1,500/year (~90-340 EUR)',
          description: 'OC mandatory for all registered vehicles.',
          howToGetAsImmigrant: 'Need Polish registration. Compare at rankomat.pl, mfind.pl, ubea.pl.',
        ),
      ],
      recommendedInsurance: [
        InsuranceType(
          type: 'Private Health Insurance (Abonament medyczny)',
          mandatory: false,
          averageMonthlyCost: 'PLN 100-300/month (~23-70 EUR)',
          description: 'Very popular as employer benefit. Medicover, LUX MED, ENEL-MED provide subscription-based healthcare.',
          howToGetAsImmigrant: 'Very commonly offered by employers. Also available individually.',
        ),
        InsuranceType(
          type: 'Home Insurance',
          mandatory: false,
          averageMonthlyCost: 'PLN 200-800/year (~45-180 EUR)',
          description: 'Ubezpieczenie mieszkania/domu covers property and contents.',
          howToGetAsImmigrant: 'Available from all Polish insurers. Often required by mortgage banks.',
        ),
      ],
      pension: PensionInfo(
        systemType: 'Pay-as-you-go NDC (notional defined contribution)',
        pillar1: 'ZUS state pension (NDC): individual account where contributions are indexed. Pension = accumulated capital / life expectancy at retirement. No minimum pension amount (abolished for new system). Old system: minimum guaranteed.',
        pillar2: 'OFE (Open Pension Funds): reformed. Remaining assets in OFE or transferred to IKE. Sub-account in ZUS.',
        pillar3: 'PPK (Employee Capital Plans): auto-enrollment since 2019 (2% employee + 1.5% employer + state). IKE, IKZE: individual tax-advantaged accounts.',
        retirementAge: 65,
        retirementAgeWomen: 60,
        minimumContributionYears: 20,
        averageStatePensionMonthly: 'PLN 3,500 (~800 EUR)',
        minimumPensionMonthly: 'PLN 1,780 (~410 EUR, minimum guaranteed, 2024)',
        maximumPensionMonthly: 'No statutory maximum under NDC. Based on accumulated capital.',
        contributionRate: '19.52% for pension (9.76% employee + 9.76% employer). PPK additional: 2% employee + 1.5% employer.',
        pensionAuthorityName: 'ZUS (Zaklad Ubezpieczen Spolecznych)',
        pensionAuthorityWebsite: 'www.zus.pl',
        pensionAuthorityPhone: '+48 22 560 16 00',
      ),
      immigrantPensionRights: ImmigrantPensionRights(
        rightsForEuCitizens: 'Full equal treatment under EU Regulation 883/2004.',
        rightsForThirdCountryNationals: 'Equal rights if legally employed. Bilateral agreements with Ukraine (very important due to large Ukrainian community), USA, Canada, and others.',
        minimumResidenceForStatePension: 'Women: 20 years, Men: 25 years of insurance for minimum guaranteed pension. Under pure NDC: any contribution generates pension (no minimum).',
        crossBorderCoordination: 'ZUS handles EU pension coordination.',
        whatHappensIfYouLeave: 'NDC pension rights preserved. Accumulated capital stays in ZUS account. Exportable.',
        howToClaimFromAbroad: 'Apply through institution in country of residence. ZUS has multilingual service (including Ukrainian).',
        pensionExportRules: 'Full export within EU/EEA and bilateral countries.',
        voluntaryContributions: 'Voluntary ZUS pension insurance possible. PPK and IKE/IKZE for additional savings.',
        pensionTransferOptions: 'No capital transfer for Pillar 1. PPK funds portable between employers.',
        bilateralAgreements: 'Ukraine, USA, Canada, South Korea, Australia, Turkey, and others.',
      ),
      carInsurance: CarInsuranceInfo(
        mandatory: true,
        minimumCoverage: '5.21M EUR personal injury, 1.05M EUR property',
        averageAnnualCostTPL: 'PLN 400-1,500 (90-340 EUR)',
        averageAnnualCostFullCoverage: 'PLN 1,000-4,000 (230-910 EUR)',
        greenCardRequired: 'Not for EU vehicles.',
        foreignLicenseRules: 'EU licenses valid. Non-EU licenses valid 6 months. Must exchange for Polish license.',
        noClaimsDiscountTransfer: 'Bonus-malus system. Some insurers accept foreign NCB documentation.',
        howToGetAsImmigrant: 'Need Polish registration. Compare at rankomat.pl, mfind.pl. OC must be continuous - gap penalties.',
        majorProviders: 'PZU, Warta, Ergo Hestia, Allianz, Generali, UNIQA, Link4',
      ),
      healthInsuranceSystem: 'NFZ (National Health Fund). Social insurance funded. Universal for insured. Long waiting times for specialists in public system - hence private sector popularity.',
      healthInsuranceCostEmployee: '9% of gross salary deducted from employee',
      healthInsuranceCostSelfEmployed: '9% of declared base (minimum ~PLN 700/month)',
      socialSecurityOverview: 'Employee: ~13.7% (pension 9.76% + disability 1.5% + sickness 2.45%). Employer: ~20% (pension 9.76% + disability 6.5% + accident 0.67-3.33% + labor fund 2.45% + FGSP 0.10%). Health: 9% additional from employee.',
      legalBasis: 'Social Insurance System Act 1998, PPK Act 2018, Health Insurance Act, EU Reg 883/2004',
      immigrantSpecificNotes: 'Poland has large Ukrainian immigrant community (1M+). ZUS offers services in Ukrainian. PPK auto-enrollment since 2019 provides additional pension savings. Private health subscription (abonament) very popular - LUX MED, Medicover, ENEL-MED. Women retire at 60, men at 65 (one of few EU countries with gender difference). OC car insurance penalties for gaps.',
    ),

    // ============================================================
    // 22. PORTUGAL (PT)
    // ============================================================
    CountryInsurancePension(
      country: 'Portugal',
      countryCode: 'PT',
      mandatoryInsurance: [
        InsuranceType(
          type: 'Health Insurance (SNS)',
          mandatory: true,
          averageMonthlyCost: 'Tax-funded. No separate health premium. Social security contributions fund pensions, not health directly.',
          description: 'Servico Nacional de Saude (SNS). Universal tax-funded. Free primary care since 2024 reform. Hospital care free. Small co-payments (taxas moderadoras) for some services.',
          howToGetAsImmigrant: 'Register at local health center (centro de saude) with NIF (tax number) and proof of residence. Get SNS user number (numero de utente). All legal residents covered.',
        ),
        InsuranceType(
          type: 'Car Insurance (TPL)',
          mandatory: true,
          averageMonthlyCost: '200-600 EUR/year',
          description: 'Seguro automovel de responsabilidade civil mandatory.',
          howToGetAsImmigrant: 'Need Portuguese registration (matricula). Compare at comparamais.pt, deco.pt.',
        ),
      ],
      recommendedInsurance: [
        InsuranceType(
          type: 'Private Health Insurance',
          mandatory: false,
          averageMonthlyCost: '30-80 EUR/month',
          description: 'Supplements SNS. Faster access, private hospitals (CUF, Luz Saude). Popular due to SNS waiting times.',
          howToGetAsImmigrant: 'Available from Medis, Multicare, Allianz, Fidelidade. NHR program holders often use private.',
        ),
        InsuranceType(
          type: 'Home Insurance',
          mandatory: false,
          averageMonthlyCost: '10-25 EUR/month',
          description: 'Seguro multirriscos habitacao. Mandatory only if mortgaged property.',
          howToGetAsImmigrant: 'Mandatory with mortgage. Recommended for renters.',
        ),
      ],
      pension: PensionInfo(
        systemType: 'Pay-as-you-go earnings-related',
        pillar1: 'State pension (Seguranca Social): earnings-related based on best 40 years (entire career if all after 2002). Progressive formula.',
        pillar2: 'Occupational pensions (fundos de pensoes): relatively uncommon. Some large companies and financial sector.',
        pillar3: 'PPR (Planos Poupanca Reforma): tax-incentivized retirement savings. Popular.',
        retirementAge: 66,
        retirementAgeWomen: 66,
        minimumContributionYears: 15,
        averageStatePensionMonthly: '580 EUR',
        minimumPensionMonthly: '308-421 EUR depending on contribution career length (2024)',
        maximumPensionMonthly: '~3,700 EUR (92% of reference salary for very long high-income careers)',
        contributionRate: '34.75% total (11% employee + 23.75% employer). Self-employed: 21.4% of relevant income.',
        pensionAuthorityName: 'Seguranca Social (ISS - Instituto da Seguranca Social)',
        pensionAuthorityWebsite: 'www.seg-social.pt',
        pensionAuthorityPhone: '+351 300 502 502',
      ),
      immigrantPensionRights: ImmigrantPensionRights(
        rightsForEuCitizens: 'Full equal treatment under EU Regulation 883/2004.',
        rightsForThirdCountryNationals: 'Equal rights if legally employed. Bilateral agreements with former colonies (Brazil, Cape Verde, Mozambique, etc.) and others.',
        minimumResidenceForStatePension: '15 years of contribution periods. Social pension (pensao social de velhice): means-tested, requires 6 years of legal residence.',
        crossBorderCoordination: 'ISS handles EU coordination. Important corridor with Brazil (large community).',
        whatHappensIfYouLeave: 'Pension rights preserved and exportable.',
        howToClaimFromAbroad: 'Apply through institution in country of residence. ISS processes.',
        pensionExportRules: 'Contributory pension exportable worldwide. Social pension: Portugal residence only.',
        voluntaryContributions: 'Voluntary social insurance (seguro social voluntario) available. ~65 EUR/month minimum.',
        pensionTransferOptions: 'No capital transfer. Each country pays its portion.',
        bilateralAgreements: 'Brazil, Cape Verde, Mozambique, Angola, Sao Tome, Guinea-Bissau, USA, Canada, Australia, Venezuela, Morocco, Tunisia, and others.',
      ),
      carInsurance: CarInsuranceInfo(
        mandatory: true,
        minimumCoverage: '6.07M EUR personal injury, 1.22M EUR property',
        averageAnnualCostTPL: '200-600 EUR',
        averageAnnualCostFullCoverage: '500-1,500 EUR',
        greenCardRequired: 'Not for EU vehicles.',
        foreignLicenseRules: 'EU licenses valid. Non-EU licenses valid 185 days. Must exchange (some countries exempt from test).',
        noClaimsDiscountTransfer: 'Bonus-malus system. Some acceptance of foreign NCB.',
        howToGetAsImmigrant: 'Need Portuguese plates (matricula). IUC annual vehicle tax also applies. Compare at comparamais.pt.',
        majorProviders: 'Fidelidade, Allianz, Ageas, Generali, Liberty, Tranquilidade',
      ),
      healthInsuranceSystem: 'SNS (Servico Nacional de Saude). Universal tax-funded. Free primary care since 2024. Co-payments for some specialist and emergency services. ADSE for civil servants.',
      healthInsuranceCostEmployee: 'No separate health premium. Funded through general taxation. Social security 11% covers pension/social benefits.',
      healthInsuranceCostSelfEmployed: '21.4% of 70% of relevant income (effectively ~15%)',
      socialSecurityOverview: 'Employee: 11%. Employer: 23.75%. Total: 34.75%. Covers pension, sickness, maternity, unemployment, family. Health funded separately through taxation.',
      legalBasis: 'Codigo dos Regimes Contributivos do Sistema Previdencial de Seguranca Social, Lei de Bases da Seguranca Social, EU Reg 883/2004',
      immigrantSpecificNotes: 'Portugal NHR (Non-Habitual Resident) tax regime attracts many EU retirees (flat 10% tax on foreign pensions until 2024 reform). SNS now free for primary care. Large Brazilian community - many bilateral protections. D7 visa (passive income) requires health insurance. Golden Visa program reformed 2023. PPR retirement savings plans are popular and tax-efficient.',
    ),

    // ============================================================
    // 23. ROMANIA (RO)
    // ============================================================
    CountryInsurancePension(
      country: 'Romania',
      countryCode: 'RO',
      mandatoryInsurance: [
        InsuranceType(
          type: 'Health Insurance (CNAS)',
          mandatory: true,
          averageMonthlyCost: '10% of gross income (CASS contribution)',
          description: 'National Health Insurance House (CNAS). Covers GP, specialists, hospital, prescriptions, dental basics. Quality varies significantly between urban and rural.',
          howToGetAsImmigrant: 'Automatic when employed (employer deducts CASS). Self-employed and others: must pay 10% CASS to be insured. Need CNP (personal numeric code).',
        ),
        InsuranceType(
          type: 'Car Insurance (TPL)',
          mandatory: true,
          averageMonthlyCost: 'RON 500-2,000/year (~100-400 EUR)',
          description: 'RCA mandatory for all registered vehicles.',
          howToGetAsImmigrant: 'Need Romanian registration. Compare at conso.ro, pfrm.ro.',
        ),
      ],
      recommendedInsurance: [
        InsuranceType(
          type: 'Private Health Insurance',
          mandatory: false,
          averageMonthlyCost: 'RON 100-500/month (~20-100 EUR)',
          description: 'Very popular supplement due to public system challenges. Employers often provide.',
          howToGetAsImmigrant: 'Available from Signal Iduna, Allianz, Generali, NN Romania.',
        ),
      ],
      pension: PensionInfo(
        systemType: 'Pay-as-you-go + mandatory funded Pillar 2',
        pillar1: 'Public pension (CAS): earnings-related, point-based system. Pension = number of points x pension point value.',
        pillar2: 'Mandatory funded pension (Pillar 2): 3.75% of gross salary (reduced from planned 6%, controversial). For workers born after 1972.',
        pillar3: 'Voluntary pension funds with tax incentives (400 EUR/year deductible)',
        retirementAge: 65,
        retirementAgeWomen: 63,
        minimumContributionYears: 15,
        averageStatePensionMonthly: 'RON 2,500 (~500 EUR)',
        minimumPensionMonthly: 'RON 1,281 (~260 EUR, social pension minimum)',
        maximumPensionMonthly: 'No statutory cap. Based on points.',
        contributionRate: '25% CAS (entirely employee contribution since 2018 reform). Pillar 2: 3.75% redirected from CAS.',
        pensionAuthorityName: 'Casa Nationala de Pensii Publice (CNPP)',
        pensionAuthorityWebsite: 'www.cnpp.ro',
        pensionAuthorityPhone: '+40 21 316 24 32',
      ),
      immigrantPensionRights: ImmigrantPensionRights(
        rightsForEuCitizens: 'Full equal treatment under EU Regulation 883/2004.',
        rightsForThirdCountryNationals: 'Equal rights if legally employed. Bilateral agreements with Moldova, Turkey, and others.',
        minimumResidenceForStatePension: '15 years of contribution periods. Aggregation with EU/bilateral periods.',
        crossBorderCoordination: 'CNPP handles EU pension coordination.',
        whatHappensIfYouLeave: 'Pension rights preserved. Exportable to EU/EEA.',
        howToClaimFromAbroad: 'Apply through institution in country of residence.',
        pensionExportRules: 'Full export within EU/EEA and bilateral countries.',
        voluntaryContributions: 'Voluntary social insurance agreement possible with CNPP.',
        pensionTransferOptions: 'No Pillar 1 capital transfer. Pillar 2 funds remain in Romanian fund.',
        bilateralAgreements: 'Moldova, Turkey, Israel, Canada, South Korea, and others.',
      ),
      carInsurance: CarInsuranceInfo(
        mandatory: true,
        minimumCoverage: '6.07M EUR personal injury, 1.22M EUR property',
        averageAnnualCostTPL: 'RON 500-2,000 (100-400 EUR)',
        averageAnnualCostFullCoverage: 'RON 1,500-5,000 (300-1,000 EUR)',
        greenCardRequired: 'Not for EU vehicles.',
        foreignLicenseRules: 'EU licenses valid. Non-EU licenses valid 90 days. Must exchange or take Romanian test.',
        noClaimsDiscountTransfer: 'Bonus-malus system being implemented.',
        howToGetAsImmigrant: 'Need Romanian registration. RCA market had recent regulatory reforms.',
        majorProviders: 'Euroins, Groupama, Allianz-Tiriac, NN Asigurari, Generali',
      ),
      healthInsuranceSystem: 'CNAS (National Health Insurance House). Social insurance funded through CASS 10%. Quality varies regionally. Many Romanians seek care abroad (EU cross-border healthcare directive).',
      healthInsuranceCostEmployee: '10% CASS from employee gross salary',
      healthInsuranceCostSelfEmployed: '10% CASS on declared income (minimum threshold applies)',
      socialSecurityOverview: 'Employee: 25% CAS (pension) + 10% CASS (health) = 35%. Employer: ~2.25% (work insurance contribution). Romania shifted most burden to employee side in 2018.',
      legalBasis: 'Law 263/2010 (pensions), Law 411/2004 (private pension funds), Health Insurance Law 95/2006, EU Reg 883/2004',
      immigrantSpecificNotes: 'Romania has lower pension and insurance costs than Western EU but also lower benefits. Significant brain drain means pension system under pressure. Pillar 2 controversial - government reduced contribution from 6% to 3.75%. Private health insurance very common as supplement. Large Moldovan immigrant community.',
    ),

    // ============================================================
    // 24. SLOVAKIA (SK)
    // ============================================================
    CountryInsurancePension(
      country: 'Slovakia',
      countryCode: 'SK',
      mandatoryInsurance: [
        InsuranceType(
          type: 'Health Insurance',
          mandatory: true,
          averageMonthlyCost: 'Employee: 4% of gross. Employer: 10%. Self-employed: 14% of 50% assessment base.',
          description: 'Mandatory health insurance through one of three insurers: VsZP (state), Dovera, Union. Comprehensive coverage.',
          howToGetAsImmigrant: 'Must register with health insurer within 8 days of employment/residence. Need birth number (rodne cislo). EU citizens: EHIC or register locally.',
        ),
        InsuranceType(
          type: 'Car Insurance (TPL)',
          mandatory: true,
          averageMonthlyCost: '100-400 EUR/year',
          description: 'PZP mandatory third-party liability.',
          howToGetAsImmigrant: 'Need Slovak registration. Compare at netfinancie.sk, superpoistenie.sk.',
        ),
      ],
      recommendedInsurance: [
        InsuranceType(
          type: 'Home Insurance',
          mandatory: false,
          averageMonthlyCost: '8-25 EUR/month',
          description: 'Poistenie domacnosti covers contents. Poistenie nehnutelnosti covers building.',
          howToGetAsImmigrant: 'Available from Allianz, Generali, Union, Kooperativa.',
        ),
      ],
      pension: PensionInfo(
        systemType: 'Three-pillar: PAYG + mandatory funded + voluntary',
        pillar1: 'State pension (Socialna poistovna): earnings-related. Formula based on average personal wage points and insurance period.',
        pillar2: 'Mandatory funded pension (DSS): voluntary opt-in for new workers (auto-enrolled with opt-out). 5.5% of gross salary.',
        pillar3: 'Voluntary supplementary pension (DDS): employer and employee contributions. Tax-advantaged up to 180 EUR/year tax credit.',
        retirementAge: 64,
        retirementAgeWomen: 64,
        minimumContributionYears: 15,
        averageStatePensionMonthly: '620 EUR',
        minimumPensionMonthly: '389 EUR (minimum pension for 30+ years, 2024)',
        maximumPensionMonthly: 'No statutory cap. Based on earnings and contributions.',
        contributionRate: '18% for Pillar 1 (or 12.5% if in Pillar 2: 4% employee + 14% employer, of which 5.5% goes to Pillar 2)',
        pensionAuthorityName: 'Socialna poistovna (Social Insurance Agency)',
        pensionAuthorityWebsite: 'www.socpoist.sk',
        pensionAuthorityPhone: '+421 2 3247 1120',
      ),
      immigrantPensionRights: ImmigrantPensionRights(
        rightsForEuCitizens: 'Full equal treatment under EU Regulation 883/2004.',
        rightsForThirdCountryNationals: 'Equal rights if legally employed. Bilateral agreements with Ukraine, South Korea, Canada, and others.',
        minimumResidenceForStatePension: '15 years of insurance periods. EU/bilateral periods aggregated.',
        crossBorderCoordination: 'Socialna poistovna handles EU coordination.',
        whatHappensIfYouLeave: 'Pillar 1 pension preserved. Pillar 2 funds remain invested in DSS.',
        howToClaimFromAbroad: 'Apply through institution in country of residence.',
        pensionExportRules: 'Full export within EU/EEA. Bilateral countries.',
        voluntaryContributions: 'Voluntary pension insurance through Socialna poistovna possible.',
        pensionTransferOptions: 'Pillar 2 can switch between DSS managers. No cross-border transfer.',
        bilateralAgreements: 'Ukraine, South Korea, Canada, Australia, Israel, and others.',
      ),
      carInsurance: CarInsuranceInfo(
        mandatory: true,
        minimumCoverage: '5.24M EUR personal injury, 1.05M EUR property',
        averageAnnualCostTPL: '100-400 EUR',
        averageAnnualCostFullCoverage: '300-1,200 EUR',
        greenCardRequired: 'Not for EU vehicles.',
        foreignLicenseRules: 'EU licenses valid. Non-EU licenses valid with IDP. Must convert for permanent residence.',
        noClaimsDiscountTransfer: 'Bonus-malus system.',
        howToGetAsImmigrant: 'Need Slovak registration. Highway vignette required.',
        majorProviders: 'Allianz, Kooperativa, Generali, Union, CSOB Poistovna',
      ),
      healthInsuranceSystem: 'Three competing health insurers: VsZP (state, ~63% market), Dovera (~27%), Union (~10%). Standardized benefit package. Free choice of insurer.',
      healthInsuranceCostEmployee: '4% employee + 10% employer = 14% total',
      healthInsuranceCostSelfEmployed: '14% of 50% assessment base',
      socialSecurityOverview: 'Employee: ~13.4% (health 4% + pension 4% + disability 3% + unemployment 1% + sickness 1.4%). Employer: ~35.2% (health 10% + pension 14% + disability + reserve + accident + guarantee + unemployment).',
      legalBasis: 'Act No. 461/2003 Coll. (Social Insurance), Act No. 580/2004 Coll. (Health Insurance), Act No. 43/2004 Coll. (Retirement Pension Saving), EU Reg 883/2004',
      immigrantSpecificNotes: 'Slovakia has three-insurer health system with free choice. Pillar 2 auto-enrollment for new workers. Pension levels modest but growing. Minimum pension requires 30 years (generous floor). Highway vignette required for motorways. Large Ukrainian worker community since 2022.',
    ),

    // ============================================================
    // 25. SLOVENIA (SI)
    // ============================================================
    CountryInsurancePension(
      country: 'Slovenia',
      countryCode: 'SI',
      mandatoryInsurance: [
        InsuranceType(
          type: 'Health Insurance (ZZZS)',
          mandatory: true,
          averageMonthlyCost: 'Employee: 6.36% of gross. Employer: 6.56%. + Mandatory supplementary: ~35 EUR/month.',
          description: 'ZZZS (Health Insurance Institute of Slovenia). Mandatory basic + mandatory supplementary (dopolnilno). Basic covers 50-100% of costs depending on service. Supplementary covers the difference.',
          howToGetAsImmigrant: 'Basic: automatic when employed. Supplementary: MUST purchase separately from Vzajemna, Triglav Zdravstvena, or Generali. Fine for not having supplementary. Need EMSO (personal ID number).',
        ),
        InsuranceType(
          type: 'Car Insurance (TPL)',
          mandatory: true,
          averageMonthlyCost: '200-600 EUR/year',
          description: 'AO (avtomobilska odgovornost) mandatory.',
          howToGetAsImmigrant: 'Need Slovenian registration. Compare at zavaruj.si.',
        ),
      ],
      recommendedInsurance: [
        InsuranceType(
          type: 'Home Insurance',
          mandatory: false,
          averageMonthlyCost: '10-30 EUR/month',
          description: 'Stanovanjsko zavarovanje covers property and contents.',
          howToGetAsImmigrant: 'Available from Triglav, Generali, Sava, Wiener Stadtische podruznica.',
        ),
      ],
      pension: PensionInfo(
        systemType: 'Pay-as-you-go earnings-related + voluntary supplementary',
        pillar1: 'State pension (ZPIZ): earnings-related based on best 24 consecutive years. Accrual rate: 1.25% per year (men) / 1.38% (women) for pension base years.',
        pillar2: 'Occupational pension (PDPZ): some sectors mandatory (hazardous work). Voluntary supplementary pension widely available.',
        pillar3: 'Individual voluntary pension insurance. Tax relief available.',
        retirementAge: 65,
        retirementAgeWomen: 65,
        minimumContributionYears: 15,
        averageStatePensionMonthly: '850 EUR',
        minimumPensionMonthly: '620 EUR (minimum pension for 15 years, 2024)',
        maximumPensionMonthly: '~2,500 EUR (80% of pension base for 40-year career)',
        contributionRate: '24.35% (15.50% employer + 8.85% employee for pension. Total with health: employer ~16.1%, employee ~22.1%).',
        pensionAuthorityName: 'ZPIZ (Zavod za pokojninsko in invalidsko zavarovanje)',
        pensionAuthorityWebsite: 'www.zpiz.si',
        pensionAuthorityPhone: '+386 1 474 51 00',
      ),
      immigrantPensionRights: ImmigrantPensionRights(
        rightsForEuCitizens: 'Full equal treatment under EU Regulation 883/2004.',
        rightsForThirdCountryNationals: 'Equal rights if legally employed. Bilateral agreements with successor states of Yugoslavia and others.',
        minimumResidenceForStatePension: '15 years of insurance periods. Aggregation with EU/bilateral periods.',
        crossBorderCoordination: 'ZPIZ handles EU coordination.',
        whatHappensIfYouLeave: 'Pension rights preserved and exportable.',
        howToClaimFromAbroad: 'Apply through institution in country of residence.',
        pensionExportRules: 'Full export within EU/EEA and bilateral countries.',
        voluntaryContributions: 'Voluntary pension insurance possible.',
        pensionTransferOptions: 'No capital transfer for Pillar 1.',
        bilateralAgreements: 'Serbia, Bosnia-Herzegovina, Montenegro, North Macedonia, Kosovo, Turkey, Canada, Australia, and others.',
      ),
      carInsurance: CarInsuranceInfo(
        mandatory: true,
        minimumCoverage: '5.6M EUR personal injury, 1.12M EUR property',
        averageAnnualCostTPL: '200-600 EUR',
        averageAnnualCostFullCoverage: '500-1,500 EUR',
        greenCardRequired: 'Not for EU vehicles.',
        foreignLicenseRules: 'EU licenses valid. Non-EU licenses valid 1 year. Must convert.',
        noClaimsDiscountTransfer: 'Bonus-malus system. Foreign NCB may be considered.',
        howToGetAsImmigrant: 'Need Slovenian registration. Highway vignette required (e-vignette since 2022).',
        majorProviders: 'Zavarovalnica Triglav, Generali, Sava, Adriatic Slovenica, Wiener Stadtische',
      ),
      healthInsuranceSystem: 'ZZZS mandatory basic + mandatory supplementary insurance. Unique in EU: supplementary is quasi-mandatory (covers co-payments). Three supplementary insurers.',
      healthInsuranceCostEmployee: '6.36% employee + 6.56% employer for basic. Supplementary ~35 EUR/month individual.',
      healthInsuranceCostSelfEmployed: '~12.92% for health + mandatory supplementary ~35 EUR/month',
      socialSecurityOverview: 'Total: ~38% (employee ~22.1% + employer ~16.1%). Covers pension, health, unemployment, maternity.',
      legalBasis: 'Pension and Disability Insurance Act (ZPIZ-2), Health Care and Health Insurance Act (ZZVZZ), EU Reg 883/2004',
      immigrantSpecificNotes: 'Slovenia unique requirement: MANDATORY supplementary health insurance (dopolnilno). Must purchase from Vzajemna, Triglav Zdravstvena, or Generali. Without it, you pay full co-payments (up to 90% of some services). Pension system links well with former Yugoslav states. Highway e-vignette required.',
    ),

    // ============================================================
    // 26. SPAIN (ES)
    // ============================================================
    CountryInsurancePension(
      country: 'Spain',
      countryCode: 'ES',
      mandatoryInsurance: [
        InsuranceType(
          type: 'Health Insurance (SNS)',
          mandatory: true,
          averageMonthlyCost: 'Tax-funded. No separate health premium. Social security covers pension/unemployment.',
          description: 'Sistema Nacional de Salud (SNS). Universal tax-funded. Free at point of use. Managed by autonomous communities (17 regional systems). Covers everything except most dental and optical.',
          howToGetAsImmigrant: 'Register at local health center (centro de salud) with empadronamiento (municipal registration). Get SIP/TSI health card. Need NIE (foreigner ID number). All registered residents covered.',
        ),
        InsuranceType(
          type: 'Car Insurance (TPL)',
          mandatory: true,
          averageMonthlyCost: '300-800 EUR/year',
          description: 'Seguro obligatorio de automovil (SOA/RC) mandatory for all vehicles.',
          howToGetAsImmigrant: 'Need Spanish registration (matricula). ITV (inspection) for imported vehicles. Compare at rastreator.com, acierto.com.',
        ),
      ],
      recommendedInsurance: [
        InsuranceType(
          type: 'Private Health Insurance',
          mandatory: false,
          averageMonthlyCost: '40-120 EUR/month',
          description: 'Very popular supplement (~25% of population). Required for non-lucrative visa applicants. Sanitas, Adeslas, Asisa, DKV.',
          howToGetAsImmigrant: 'Required for non-lucrative visa, student visa, digital nomad visa. Available without waiting periods from some providers.',
        ),
        InsuranceType(
          type: 'Home Insurance',
          mandatory: false,
          averageMonthlyCost: '15-35 EUR/month',
          description: 'Seguro del hogar. Mandatory for mortgaged properties (fire coverage minimum). Recommended for renters.',
          howToGetAsImmigrant: 'Mandatory with mortgage. Available from all Spanish insurers.',
        ),
      ],
      pension: PensionInfo(
        systemType: 'Pay-as-you-go earnings-related (reformed 2011 and 2013)',
        pillar1: 'State pension (Seguridad Social): earnings-related based on last 25 years of contributions. Replacement rate declining with reforms.',
        pillar2: 'Occupational pensions (planes de empleo): growing after 2022 reform incentives. Previously uncommon.',
        pillar3: 'Individual pension plans (planes de pensiones individuales): tax deduction limited to 1,500 EUR/year (reduced from 8,000 in 2021).',
        retirementAge: 67,
        retirementAgeWomen: 67,
        minimumContributionYears: 15,
        averageStatePensionMonthly: '1,370 EUR (2024)',
        minimumPensionMonthly: '783 EUR (with spouse) / 722 EUR (without spouse, 65+, 15 years contributions)',
        maximumPensionMonthly: '3,175 EUR (2024, 14 payments/year so annual max 44,450 EUR)',
        contributionRate: '28.30% for common contingencies (4.70% employee + 23.60% employer). Additional for unemployment, training, FOGASA.',
        pensionAuthorityName: 'Seguridad Social (INSS - Instituto Nacional de la Seguridad Social)',
        pensionAuthorityWebsite: 'www.seg-social.es',
        pensionAuthorityPhone: '+34 901 16 65 65',
      ),
      immigrantPensionRights: ImmigrantPensionRights(
        rightsForEuCitizens: 'Full equal treatment under EU Regulation 883/2004.',
        rightsForThirdCountryNationals: 'Equal rights if legally employed. Extensive bilateral agreements with Latin America and North Africa.',
        minimumResidenceForStatePension: '15 years of contributions (at least 2 in last 15 years). Non-contributory pension: 10 years of legal residence (2 immediately preceding claim).',
        crossBorderCoordination: 'INSS handles EU coordination. Extensive experience with Latin American agreements.',
        whatHappensIfYouLeave: 'Contributory pension rights preserved and exportable. Non-contributory pension: Spain residence only.',
        howToClaimFromAbroad: 'Apply through institution in country of residence. INSS processes. Also via Spanish embassy consular assistance.',
        pensionExportRules: 'Contributory pension exportable to EU/EEA and all bilateral agreement countries (extensive list). Non-contributory: Spain only.',
        voluntaryContributions: 'Convenio especial (special agreement) allows voluntary contributions to maintain/extend rights. ~280-1,260 EUR/month depending on base chosen.',
        pensionTransferOptions: 'No capital transfer. Pro-rata pensions from each country.',
        bilateralAgreements: 'Argentina, Brazil, Chile, Colombia, Dominican Republic, Ecuador, Mexico, Paraguay, Peru, Uruguay, Venezuela, Morocco, Tunisia, Philippines, USA, Canada, Japan, South Korea, China, Russia, Ukraine, Australia, and many more.',
      ),
      carInsurance: CarInsuranceInfo(
        mandatory: true,
        minimumCoverage: '70M EUR personal injury, 15M EUR property',
        averageAnnualCostTPL: '300-800 EUR',
        averageAnnualCostFullCoverage: '600-2,000 EUR',
        greenCardRequired: 'Not for EU vehicles.',
        foreignLicenseRules: 'EU licenses valid. Non-EU licenses valid 6 months. Must exchange (Spain has agreements with many Latin American countries for easy exchange).',
        noClaimsDiscountTransfer: 'No official bonus-malus system. Insurers use their own experience rating. Foreign NCB may help negotiate better rate.',
        howToGetAsImmigrant: 'Need Spanish plates (matricula). ITV inspection required. Compare at rastreator.com, acierto.com, kelisto.es.',
        majorProviders: 'Mapfre, Linea Directa, Mutua Madrilena, AXA, Allianz, Pelayo, Liberty',
      ),
      healthInsuranceSystem: 'SNS (Sistema Nacional de Salud). Universal tax-funded. 17 regional health services. Free at point of use. Prescription co-payment based on income (0-60%).',
      healthInsuranceCostEmployee: 'No separate health premium. Funded through general taxation and social security.',
      healthInsuranceCostSelfEmployed: 'Autonomos pay ~30% social security contribution (covers pension, health, sick leave). Minimum base ~300 EUR/month.',
      socialSecurityOverview: 'Employee: ~6.5% (common contingencies 4.7% + unemployment 1.55% + training 0.10% + MEI 0.12%). Employer: ~30% (common 23.6% + unemployment ~5.5% + FOGASA 0.2% + training 0.60% + MEI 0.58% + accident varies).',
      legalBasis: 'Ley General de la Seguridad Social (LGSS), Ley de Ordenacion y Supervision de los Seguros Privados, EU Reg 883/2004',
      immigrantSpecificNotes: 'Spain requires empadronamiento (municipal registration) for health card. Private health insurance mandatory for non-lucrative visa, digital nomad visa, student visa. Spain pays pensions in 14 installments (12 monthly + 2 extra pays). Extensive bilateral agreements with Latin America. Non-contributory pension available for 10+ years residence. Autonomos (self-employed) system being reformed with income-based contributions since 2023.',
    ),

    // ============================================================
    // 27. SWEDEN (SE)
    // ============================================================
    CountryInsurancePension(
      country: 'Sweden',
      countryCode: 'SE',
      mandatoryInsurance: [
        InsuranceType(
          type: 'Health Insurance (Forsakringskassan)',
          mandatory: true,
          averageMonthlyCost: 'Tax-funded. No separate premium. Employer social contribution (arbetsgivaravgift): 31.42% includes health.',
          description: 'Universal tax-funded healthcare through regions (regioner). Patient fee: 100-400 SEK per visit (max 1,300 SEK/year high-cost protection). Prescriptions: max 2,850 SEK/year.',
          howToGetAsImmigrant: 'Register with Skatteverket (tax authority) to get personnummer. Then register with local vardcentral (health center). EU citizens need right of residence. Non-EU: residence permit required.',
        ),
        InsuranceType(
          type: 'Car Insurance (TPL)',
          mandatory: true,
          averageMonthlyCost: 'SEK 3,000-12,000/year (~260-1,050 EUR)',
          description: 'Trafikforsakring mandatory for all registered vehicles.',
          howToGetAsImmigrant: 'Need Swedish registration (Transportstyrelsen). Compare at compricer.se, konsumenternas.se.',
        ),
      ],
      recommendedInsurance: [
        InsuranceType(
          type: 'Home Insurance (Hemforsakring)',
          mandatory: false,
          averageMonthlyCost: 'SEK 150-400/month (~13-35 EUR)',
          description: 'Hemforsakring covers contents, travel, liability, legal protection, assault. ~95% of Swedes have this. Considered essential.',
          howToGetAsImmigrant: 'Almost universally held. Available from Lansforsakringar, IF, Trygg-Hansa, Folksam.',
        ),
      ],
      pension: PensionInfo(
        systemType: 'Three-pillar: NDC (income pension) + mandatory funded (premium pension) + guarantee pension',
        pillar1: 'Income pension (inkomstpension): NDC, 16% of pensionable income. Notional accounts indexed to income growth. Premium pension (premiepension): 2.5% of pensionable income to chosen fund (AP7 default).',
        pillar2: 'Occupational pensions (tjenstepension): quasi-mandatory through collective agreements. ~90% of workers covered. ITP (white-collar), SAF-LO (blue-collar), PA16 (government), KAP-KL (municipalities). Typically 4.5-30% of salary depending on income level.',
        pillar3: 'Private pension savings (privat pensionssparande): limited tax deductibility since 2016. ISK accounts popular alternative.',
        retirementAge: 66,
        retirementAgeWomen: 66,
        minimumContributionYears: 0,
        averageStatePensionMonthly: 'SEK 16,000 total (~1,400 EUR) including all pillars',
        minimumPensionMonthly: 'SEK 10,631 (~930 EUR, guarantee pension for 40 years residence, single, 2024)',
        maximumPensionMonthly: 'No statutory maximum for income pension or occupational. Based on career earnings.',
        contributionRate: '18.5% for public pension (7% employee pensionsavgift + 10.21% from employer arbetsgivaravgift + remainder). Split: 16% inkomstpension + 2.5% premiepension.',
        pensionAuthorityName: 'Pensionsmyndigheten (Swedish Pensions Agency)',
        pensionAuthorityWebsite: 'www.pensionsmyndigheten.se',
        pensionAuthorityPhone: '+46 771 776 776',
      ),
      immigrantPensionRights: ImmigrantPensionRights(
        rightsForEuCitizens: 'Full equal treatment under EU Regulation 883/2004. Guarantee pension requires 3 years of residence in Sweden. EU periods can help qualify but NOT count for calculation.',
        rightsForThirdCountryNationals: 'Equal rights for income pension when legally employed. Guarantee pension: residence-based, requires actually living in Sweden.',
        minimumResidenceForStatePension: 'Income pension: no residence requirement (based on work). Guarantee pension: 3 years of residence in Sweden for minimum entitlement. Full after 40 years of residence.',
        crossBorderCoordination: 'Pensionsmyndigheten handles cross-border coordination. Very well-organized system with minpension.se portal.',
        whatHappensIfYouLeave: 'Income pension: fully preserved, exportable worldwide. Premium pension: remains in chosen fund, paid at retirement. Guarantee pension: NOT exportable outside EU/EEA. Reduced by 1/40 per missing year of residence.',
        howToClaimFromAbroad: 'Apply through institution in country of residence. Pensionsmyndigheten processes. Also via minpension.se.',
        pensionExportRules: 'Income pension + premium pension: exportable worldwide. Guarantee pension: EU/EEA only and proportional to Swedish residence years. Elderly support (aldreforsorjningsstod): Sweden only.',
        voluntaryContributions: 'No voluntary contributions to public pension. Occupational and private savings available.',
        pensionTransferOptions: 'No public pension capital transfer. Premium pension can switch funds. Occupational pensions managed by collective agreement funds.',
        bilateralAgreements: 'USA, Canada, South Korea, Japan, India, Chile, Turkey, Israel, and others. Nordic Convention for Nordic countries.',
      ),
      carInsurance: CarInsuranceInfo(
        mandatory: true,
        minimumCoverage: 'SEK 350M (~31M EUR) combined',
        averageAnnualCostTPL: 'SEK 3,000-12,000 (260-1,050 EUR)',
        averageAnnualCostFullCoverage: 'SEK 5,000-20,000 (440-1,750 EUR)',
        greenCardRequired: 'Not for EU vehicles.',
        foreignLicenseRules: 'EU/EEA licenses valid indefinitely. Non-EU licenses valid 1 year. Must exchange for Swedish license (theory + practical test, no exceptions for most countries).',
        noClaimsDiscountTransfer: 'Some insurers accept foreign NCB with documentation. Varies by company.',
        howToGetAsImmigrant: 'Need Swedish registration (Transportstyrelsen). Compare at compricer.se, insplanet.se. Very expensive for new drivers.',
        majorProviders: 'Lansforsakringar, IF, Trygg-Hansa, Folksam, Dina Forsakringar',
      ),
      healthInsuranceSystem: 'Universal tax-funded healthcare via 21 regions. Patient fees capped (hogkostnadsskydd): max SEK 1,300/year for visits, SEK 2,850/year for prescriptions.',
      healthInsuranceCostEmployee: 'No separate premium. Employer pays arbetsgivaravgift 31.42% which includes health insurance component.',
      healthInsuranceCostSelfEmployed: 'Egenavgifter ~28.97% of net income',
      socialSecurityOverview: 'Employer arbetsgivaravgift: 31.42% (pension 10.21%, health 3.55%, parental 2.60%, and more). Employee pensionsavgift: 7% (credited against tax). Income tax ~30-55%.',
      legalBasis: 'Social Insurance Code (Socialforsakringsbalken), Income Pension Act, Premium Pension Act, Guarantee Pension Act, EU Reg 883/2004',
      immigrantSpecificNotes: 'Sweden has excellent pension tracking at minpension.se (all pillars in one place). Personnummer essential for everything. Guarantee pension is residence-based (40 years for full). Income pension earnings-related from first day of work. Occupational pension (tjenstepension) adds significantly - ensure employer provides it. Hemforsakring (home insurance) almost universally held and includes valuable legal protection benefit.',
    ),
  ];

  // ============================================================
  // HELPER METHODS
  // ============================================================

  /// Get insurance/pension data for a specific country
  static CountryInsurancePension? getByCountryCode(String code) {
    try {
      return allCountries.firstWhere(
        (c) => c.countryCode.toUpperCase() == code.toUpperCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get insurance/pension data by country name
  static CountryInsurancePension? getByCountryName(String name) {
    try {
      return allCountries.firstWhere(
        (c) => c.country.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Search countries by keyword in any field
  static List<CountryInsurancePension> searchByKeyword(String keyword) {
    final kw = keyword.toLowerCase();
    return allCountries.where((c) {
      final map = c.toMap();
      return _searchInMap(map, kw);
    }).toList();
  }

  static bool _searchInMap(Map<String, dynamic> map, String keyword) {
    for (final value in map.values) {
      if (value is String && value.toLowerCase().contains(keyword)) return true;
      if (value is Map<String, dynamic> && _searchInMap(value, keyword)) return true;
      if (value is List) {
        for (final item in value) {
          if (item is String && item.toLowerCase().contains(keyword)) return true;
          if (item is Map<String, dynamic> && _searchInMap(item, keyword)) return true;
        }
      }
    }
    return false;
  }

  /// Get countries with lowest car insurance
  static List<CountryInsurancePension> getCheapestCarInsurance() {
    final sorted = List<CountryInsurancePension>.from(allCountries);
    sorted.sort((a, b) {
      final aVal = _extractLowerBound(a.carInsurance.averageAnnualCostTPL);
      final bVal = _extractLowerBound(b.carInsurance.averageAnnualCostTPL);
      return aVal.compareTo(bVal);
    });
    return sorted;
  }

  /// Get countries with highest state pensions
  static List<CountryInsurancePension> getHighestStatePensions() {
    final sorted = List<CountryInsurancePension>.from(allCountries);
    sorted.sort((a, b) {
      final aVal = _extractAveragePension(a.pension.averageStatePensionMonthly);
      final bVal = _extractAveragePension(b.pension.averageStatePensionMonthly);
      return bVal.compareTo(aVal);
    });
    return sorted;
  }

  /// Get countries where pension is easiest to qualify for immigrants
  static List<CountryInsurancePension> getEasiestPensionAccess() {
    final sorted = List<CountryInsurancePension>.from(allCountries);
    sorted.sort((a, b) => a.pension.minimumContributionYears
        .compareTo(b.pension.minimumContributionYears));
    return sorted;
  }

  /// Get countries sorted by retirement age
  static List<CountryInsurancePension> getByRetirementAge({bool ascending = true}) {
    final sorted = List<CountryInsurancePension>.from(allCountries);
    sorted.sort((a, b) => ascending
        ? a.pension.retirementAge.compareTo(b.pension.retirementAge)
        : b.pension.retirementAge.compareTo(a.pension.retirementAge));
    return sorted;
  }

  /// Get all countries with bilateral agreement with a specific country
  static List<CountryInsurancePension> getCountriesWithBilateralAgreement(String country) {
    final kw = country.toLowerCase();
    return allCountries.where((c) =>
      c.immigrantPensionRights.bilateralAgreements.toLowerCase().contains(kw)
    ).toList();
  }

  /// Get pension export information for a specific country pair
  static String getPensionExportInfo(String fromCountryCode, String toCountryCode) {
    final from = getByCountryCode(fromCountryCode);
    final to = getByCountryCode(toCountryCode);
    if (from == null || to == null) return 'Country not found.';

    return 'Pension from ${from.country} to ${to.country}:\n'
        'Export rules: ${from.immigrantPensionRights.pensionExportRules}\n'
        'Cross-border coordination: ${from.immigrantPensionRights.crossBorderCoordination}\n'
        'Both are EU members, so EU Regulation 883/2004 applies fully.\n'
        'What happens if you leave ${from.country}: ${from.immigrantPensionRights.whatHappensIfYouLeave}\n'
        'How to claim from ${to.country}: ${from.immigrantPensionRights.howToClaimFromAbroad}';
  }

  /// Get mandatory insurance list for a country
  static List<InsuranceType> getMandatoryInsurance(String countryCode) {
    final country = getByCountryCode(countryCode);
    return country?.mandatoryInsurance ?? [];
  }

  /// Get pension comparison between two countries
  static Map<String, dynamic> comparePensions(String countryCode1, String countryCode2) {
    final c1 = getByCountryCode(countryCode1);
    final c2 = getByCountryCode(countryCode2);
    if (c1 == null || c2 == null) return {'error': 'Country not found'};

    return {
      'country1': c1.country,
      'country2': c2.country,
      'retirementAge': {c1.country: c1.pension.retirementAge, c2.country: c2.pension.retirementAge},
      'minimumYears': {c1.country: c1.pension.minimumContributionYears, c2.country: c2.pension.minimumContributionYears},
      'averagePension': {c1.country: c1.pension.averageStatePensionMonthly, c2.country: c2.pension.averageStatePensionMonthly},
      'minimumPension': {c1.country: c1.pension.minimumPensionMonthly, c2.country: c2.pension.minimumPensionMonthly},
      'contributionRate': {c1.country: c1.pension.contributionRate, c2.country: c2.pension.contributionRate},
      'exportRules': {c1.country: c1.immigrantPensionRights.pensionExportRules, c2.country: c2.immigrantPensionRights.pensionExportRules},
    };
  }

  static double _extractLowerBound(String costString) {
    final regex = RegExp(r'[\d,]+');
    final match = regex.firstMatch(costString.replaceAll(',', ''));
    if (match != null) {
      return double.tryParse(match.group(0) ?? '0') ?? 0;
    }
    return 0;
  }

  static double _extractAveragePension(String pensionString) {
    final cleaned = pensionString.replaceAll(RegExp(r'[^0-9,.]'), '').replaceAll(',', '');
    return double.tryParse(cleaned) ?? 0;
  }
}
