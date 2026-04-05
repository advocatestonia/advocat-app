// lib/services/insurance_pension_database.dart
// Insurance & Pension Rights for EU Immigrants
// Coverage: 27 EU countries × mandatory insurance, pension rights, cross-border coordination, healthcare insurance

class InsurancePensionDatabase {
  static Map<String, Map<String, dynamic>> getAllCountries() {
    return {
      'FI': _finland(),
      'DE': _germany(),
      'FR': _france(),
      'ES': _spain(),
      'IT': _italy(),
      'NL': _netherlands(),
      'BE': _belgium(),
      'AT': _austria(),
      'SE': _sweden(),
      'DK': _denmark(),
      'NO': _norway(),
      'PL': _poland(),
      'CZ': _czechia(),
      'HU': _hungary(),
      'RO': _romania(),
      'BG': _bulgaria(),
      'HR': _croatia(),
      'SK': _slovakia(),
      'SI': _slovenia(),
      'LT': _lithuania(),
      'LV': _latvia(),
      'EE': _estonia(),
      'PT': _portugal(),
      'GR': _greece(),
      'IE': _ireland(),
      'LU': _luxembourg(),
      'MT': _malta(),
    };
  }

  static Map<String, dynamic> _finland() {
    return {
      'country': 'Finland',
      'healthcare_insurance': {
        'system': 'Universal Kela (Kansaneläkelaitos) coverage',
        'eligibility': 'Register at DVV (Digital and Population Data Services Agency), get hetu (personal ID)',
        'kela_card': 'Free European Health Insurance Card (EHIC) from Kela',
        'costs': 'GP visits: EUR 20-30 copay; hospital EUR 48.90/day',
        'private': 'Optional private insurance; major providers: LähiTapiola, If, Fennia',
        'immigrants': 'EU citizens: immediate access after registration. Non-EU: after residence permit',
      },
      'mandatory_insurance': {
        'car': {
          'name': 'Liikennevakuutus (traffic insurance)',
          'mandatory': true,
          'basis': 'Liikennevakuutuslaki',
          'fine': 'EUR 100/month if uninsured',
          'providers': ['If', 'LähiTapiola', 'Fennia', 'OP', 'Pohjola'],
          'foreign_vehicles': 'EU driving license valid; need Finnish insurance after 3 months',
        },
        'home': {
          'mandatory': false,
          'recommended': true,
          'note': 'Most landlords require tenant insurance (kotivakuutus)',
          'cost': 'EUR 100-300/year typical',
        },
      },
      'pension': {
        'system': 'Earnings-related (TyEL) + national pension (Kansaneläke)',
        'authority': 'Eläketurvakeskus (ETK)',
        'website': 'etk.fi',
        'contribution_rate': '7.15% employee (2024), 17-24% employer',
        'retirement_age': 65,
        'minimum_accrual': '17 years old minimum',
        'immigrant_rights': {
          'eu_coordination': 'EU Regulation 883/2004 — periods in other EU countries count',
          'portability': 'Pension rights portable across EU',
          'minimum_period': 'No minimum period to start accruing',
          'check_your_pension': 'tyoelake.fi — view your accrued pension',
        },
        'national_pension': {
          'name': 'Kansaneläke',
          'for_whom': 'Those with no or low earnings-related pension',
          'residence_requirement': '3 years in Finland',
          'amount': 'Up to EUR 703/month (2024) single person',
        },
        'early_retirement': {
          'partial': 'Osittainen varhennettu vanhuuseläke from age 61',
          'full': 'Vanhuuseläke at personal retirement age (63-68)',
        },
        'disability': {
          'name': 'Työkyvyttömyyseläke',
          'eligibility': 'Permanent incapacity to work',
          'based_on': 'Future pension rights projected',
        },
        'survivors': {
          'name': 'Perhe-eläke (family pension)',
          'eligible': 'Spouse + children under 18',
        },
      },
      'unemployment_insurance': {
        'basic': 'Peruspäiväraha via Kela — EUR 37.21/day (2024)',
        'earnings_related': 'Ansiopäiväraha via unemployment fund (a-kassa)',
        'eligibility': 'Must join unemployment fund; worked 26 weeks before unemployment',
        'duration': 'Max 400 days',
        'immigrants': 'EU citizens equal rights after working in Finland',
      },
      'cross_border': {
        'ehic': 'Free from Kela; covers emergency care in EU',
        'pension_aggregation': 'All EU work periods combined for eligibility',
        'posted_workers': 'A1 certificate from ETK/Kela',
        'applicable_law': 'Work in Finland → Finnish social security applies',
      },
      'complaints': {
        'insurance': 'Vakuutus- ja rahoitusneuvonta FINE (fine.fi)',
        'kela': 'Kela complaints → muutoksenhaku (appeal)',
        'pension': 'ETK complaints → Vakuutusoikeus',
      },
    };
  }

  static Map<String, dynamic> _germany() {
    return {
      'country': 'Germany',
      'healthcare_insurance': {
        'system': 'Statutory health insurance (GKV) mandatory for employees',
        'gesetzliche': 'Public: AOK, TK, Barmer, DAK, IKK etc.',
        'private': 'PKV for high earners (>EUR 69,300/year 2024)',
        'contribution': '14.6% + additional (~1.7%) split employer/employee',
        'family': 'Free co-insurance for spouse/children if not earning',
        'immigrants': 'Register with any Krankenkasse; EU citizens immediate right',
      },
      'mandatory_insurance': {
        'car': {
          'name': 'Kfz-Haftpflichtversicherung',
          'mandatory': true,
          'fine': 'Loss of registration; criminal offense',
          'providers': ['ADAC', 'Allianz', 'HUK-COBURG', 'Zurich', 'AXA'],
        },
        'liability': {
          'name': 'Privathaftpflicht',
          'mandatory': false,
          'recommended': true,
          'note': 'Extremely important in Germany; covers accidental damage to others',
          'cost': 'EUR 50-100/year',
        },
        'home': {
          'mandatory': false,
          'hausrat': 'Contents insurance — highly recommended',
          'wohngebäude': 'Building insurance — landlord responsibility',
        },
      },
      'pension': {
        'system': 'Deutsche Rentenversicherung (DRV)',
        'website': 'deutsche-rentenversicherung.de',
        'contribution_rate': '18.6% total (9.3% each)',
        'retirement_age': 67,
        'minimum_period': '5 years (Wartezeit)',
        'immigrant_rights': {
          'eu_coordination': 'EU 883/2004 applies; all EU periods count',
          'non_eu': 'Bilateral agreements with many countries',
          'portability': 'Can receive German pension abroad',
          'check': 'Rentenauskunft — pension projection from DRV',
        },
        'basic_income': 'Grundrente for those who worked 33+ years but low earner',
        'early_retirement': 'Possible from 63 with 45 contribution years',
      },
      'unemployment_insurance': {
        'body': 'Bundesagentur für Arbeit (BA)',
        'alg1': 'ALG I (contribution-based): 60% net wage, 12-24 months',
        'alg2': 'Bürgergeld (means-tested): EUR 563/month (2024)',
        'eligibility': '12 months employment in last 30 months',
        'immigrants': 'EU citizens fully entitled; register at Jobcenter',
      },
      'cross_border': {
        'ehic': 'German EHIC from your Krankenkasse',
        'posted_workers': 'A1 certificate from DRV',
        'eu_pension': 'German and EU periods aggregated',
      },
      'complaints': {
        'insurance': 'Versicherungsombudsmann (versicherungsombudsmann.de)',
        'health_insurance': 'Unabhängige Patientenberatung (UPD)',
        'pension': 'Widerspruch to DRV then Sozialgericht',
      },
    };
  }

  static Map<String, dynamic> _france() {
    return {
      'country': 'France',
      'healthcare_insurance': {
        'system': "Sécurité Sociale — CPAM (Caisse Primaire d'Assurance Maladie)",
        'coverage': '70-80% reimbursement; complementary insurance (mutuelle) covers rest',
        'carte_vitale': 'Green card with chip; get from CPAM',
        'contribution': 'Based on income; employer contributes majority',
        'immigrants': 'EU citizens: register at CPAM with proof of residence + income',
        'puma': 'Protection Universelle Maladie — universal access after 3 months residence',
      },
      'mandatory_insurance': {
        'car': {
          'name': 'Assurance responsabilité civile automobile',
          'mandatory': true,
          'providers': ['Axa', 'Allianz', 'Maif', 'Matmut', 'Groupama'],
        },
        'home': {
          'tenants': 'Assurance habitation mandatory for tenants',
          'required_for': 'Rental contracts',
          'cost': 'EUR 100-300/year',
        },
      },
      'pension': {
        'system': 'Régime général (CNAV) + complementary AGIRC-ARRCO',
        'website': 'lassuranceretraite.fr',
        'contribution': 'About 28% total (employee + employer)',
        'retirement_age': 64,
        'minimum_quarters': '172 quarters for full pension (43 years)',
        'immigrant_rights': {
          'eu_coordination': 'EU 883/2004; all EU work counted',
          'portability': 'Receive French pension anywhere in EU',
          'check': 'info-retraite.fr — pension simulator',
        },
      },
      'unemployment_insurance': {
        'body': 'France Travail (ex-Pôle emploi)',
        "are": "Allocation de retour à l'emploi — 57-75% gross salary",
        'duration': '6 months to 2 years depending on work history',
        'eligibility': '6 months work in last 24 months',
      },
      'cross_border': {
        'ehic': "Carte Européenne d'Assurance Maladie from CPAM",
        'posted_workers': 'A1 certificate from URSSAF',
      },
      'complaints': {
        'insurance': "Médiateur de l'Assurance (mediation-assurance.org)",
        'health': 'Défenseur des droits',
        'pension': 'Médiateur CNAV',
      },
    };
  }

  static Map<String, dynamic> _spain() {
    return {
      'country': 'Spain',
      'healthcare_insurance': {
        'system': 'Sistema Nacional de Salud (SNS) — universal coverage',
        'registration': 'Register with Centro de Salud with empadronamiento (census registration)',
        'tarjeta_sanitaria': 'Health card from local health authority',
        'immigrants': 'EU citizens: same rights as nationals after empadronamiento',
      },
      'mandatory_insurance': {
        'car': {
          'name': 'Seguro obligatorio de automóviles',
          'mandatory': true,
          'minimum': 'Responsabilidad civil',
        },
        'home': {
          'tenants': 'Not mandatory but widely required by landlords',
        },
      },
      'pension': {
        'system': 'Sistema de Seguridad Social',
        'website': 'seg-social.es',
        'contribution': '28.3% total (employer 23.6%, employee 4.7%)',
        'retirement_age': 67,
        'minimum_period': '15 years (2 in last 15)',
        'immigrant_rights': {
          'eu_coordination': 'EU 883/2004 applies',
          'non_eu': 'Bilateral agreements with many countries',
        },
        'types': {
          'contributiva': 'Pension based on contributions',
          'no_contributiva': 'Means-tested pension for those without contributions',
        },
      },
      'unemployment_insurance': {
        'body': 'SEPE (Servicio Público de Empleo Estatal)',
        'prestacion': '70% first 180 days, then 50% of base',
        'duration': '120-720 days',
        'eligibility': '360 days in last 6 years',
      },
      'cross_border': {
        'ehic': 'Tarjeta Sanitaria Europea from INSS',
        'posted_workers': 'A1 from Tesorería General de la Seguridad Social',
      },
    };
  }

  static Map<String, dynamic> _italy() {
    return {
      'country': 'Italy',
      'healthcare_insurance': {
        'system': 'Servizio Sanitario Nazionale (SSN)',
        'registration': 'Iscrizione SSN at local ASL with codice fiscale',
        'tessera_sanitaria': 'Health card = Italian EHIC',
        'immigrants': 'EU citizens: immediate registration right',
      },
      'mandatory_insurance': {
        'car': {
          'name': 'RC Auto (responsabilità civile)',
          'mandatory': true,
          'blackbox': 'Scatola nera reduces premium',
        },
      },
      'pension': {
        'system': 'INPS (Istituto Nazionale della Previdenza Sociale)',
        'website': 'inps.it',
        'contribution': '33% total (23.81% employer, 9.19% employee)',
        'retirement_age': 67,
        'minimum_period': '20 years',
        'immigrant_rights': {
          'eu_coordination': 'EU 883/2004',
          'totalization': 'Italian + EU periods combined',
        },
      },
      'unemployment_insurance': {
        'body': 'INPS',
        'naspi': 'NASpI — 75-25% of previous wage',
        'duration': 'Half the weeks worked in previous 4 years (max 24 months)',
        'eligibility': '13 weeks in last 4 years',
      },
      'cross_border': {
        'ehic': 'Tessera Europea di Assicurazione Malattia from ASL',
        'posted_workers': 'A1 from INPS',
      },
    };
  }

  static Map<String, dynamic> _netherlands() {
    return {
      'country': 'Netherlands',
      'healthcare_insurance': {
        'system': 'Mandatory private insurance with government oversight',
        'basisverzekering': 'Basic package ~EUR 135/month (2024)',
        'zorgtoeslag': 'Government subsidy for lower incomes',
        'eigen_risico': 'Own risk EUR 385/year (2024)',
        'providers': ['Zilveren Kruis', 'VGZ', 'Menzis', 'CZ', 'DSW'],
        'immigrants': 'Must register within 4 months of arrival; BSN number required',
      },
      'mandatory_insurance': {
        'car': {
          'name': 'WA verzekering (Wettelijke Aansprakelijkheid)',
          'mandatory': true,
        },
        'health': 'MANDATORY — fines if uninsured',
      },
      'pension': {
        'system': 'AOW (state) + occupational pension (second pillar)',
        'authority': 'Sociale Verzekeringsbank (SVB)',
        'website': 'svb.nl',
        'aow_age': 67,
        'aow_accrual': '2% per year of residence (50 years = full AOW)',
        'immigrant_rights': {
          'eu_coordination': 'EU 883/2004; residence years in other EU count via agreement',
          'non_resident': 'Can buy voluntary AOW insurance if living abroad',
          'portability': 'Receive AOW anywhere in world',
        },
        'occupational': {
          'mandatory': 'Most employers must offer pension plan',
          'portability': 'Value preserved when leaving employer',
          'check': 'mijnpensioenoverzicht.nl',
        },
      },
      'unemployment_insurance': {
        'body': 'UWV (Uitvoeringsinstituut Werknemersverzekeringen)',
        'ww': 'WW-uitkering: 75% first 2 months, then 70% of last wage',
        'duration': 'Based on work history, max 24 months',
        'eligibility': '26 weeks in last 36 weeks',
        'immigrants': 'Equal rights with BSN number',
      },
      'cross_border': {
        'ehic': 'Zorgpas (health card) from your insurer = EHIC',
        'posted_workers': 'A1 from SVB',
      },
      'complaints': {
        'insurance': 'Kifid (Klachteninstituut Financiële Dienstverlening)',
        'pension': 'Ombudsman Pensioenen',
      },
    };
  }

  static Map<String, dynamic> _belgium() {
    return {
      'country': 'Belgium',
      'healthcare_insurance': {
        'system': 'Mandatory via mutuality (mutualiteit/mutualité)',
        'funds': ['CM/MC (Christian)', 'Solidaris', 'OZ', 'FSMB', 'Onafhankelijke'],
        'must_join': 'Within 3 months of arrival',
        'contribution': 'Employee: 3.55% of wage',
        'immigrants': 'EU citizens equal rights after registration',
      },
      'mandatory_insurance': {
        'car': {
          'name': 'Verzekering burgerlijke aansprakelijkheid motorvoertuigen',
          'mandatory': true,
        },
        'fire': {
          'tenants': 'Mandatory fire insurance for tenants',
        },
      },
      'pension': {
        'system': 'MyPension — three pillars',
        'authority': 'Rijksdienst voor Pensioenen (RVP/ONP)',
        'website': 'mypension.be',
        'retirement_age': 65,
        'minimum_period': '1 year contribution',
        'immigrant_rights': {
          'eu_coordination': 'EU 883/2004',
          'frontier_workers': 'Special rules for cross-border workers',
        },
      },
      'unemployment_insurance': {
        'body': 'RVA (Rijksdienst voor Arbeidsvoorziening)',
        'amount': '65% first 3 months, then decreasing based on situation',
        'eligibility': '312-624 working days depending on age',
        'unique': 'Belgium pays unemployment for very long periods',
      },
    };
  }

  static Map<String, dynamic> _austria() {
    return {
      'country': 'Austria',
      'healthcare_insurance': {
        'system': 'Österreichische Gesundheitskasse (ÖGK) mandatory',
        'contribution': '7.65% employee',
        'registration': 'Employer registers employee automatically',
        'immigrants': 'EU citizens: register with ÖGK with passport + work contract',
      },
      'pension': {
        'system': 'Allgemeines Pensionsversicherungsgesetz (APG)',
        'authority': 'Pensionsversicherungsanstalt (PVA)',
        'website': 'pv.at',
        'retirement_age': 65,
        'contribution': '22.8% total',
        'minimum_period': '15 years (7 with special conditions)',
        'immigrant_rights': {
          'eu_coordination': 'EU 883/2004',
        },
      },
      'unemployment_insurance': {
        'body': 'AMS (Arbeitsmarktservice)',
        'alg': '55% net wage',
        'eligibility': '52 weeks in last 2 years (24 weeks for young workers)',
        'duration': '20-52 weeks based on age and work history',
      },
    };
  }

  static Map<String, dynamic> _sweden() {
    return {
      'country': 'Sweden',
      'healthcare_insurance': {
        'system': 'Landsting/Region — tax-funded universal care',
        'cost': 'Max SEK 1,350/year for visits; SEK 2,850/year for prescriptions',
        'registration': 'Register at Folkbokföring; get personnummer',
        'immigrants': 'EU citizens: equal rights after registration',
      },
      'pension': {
        'system': 'Inkomstpension (NDC) + premium pension (PPM)',
        'authority': 'Pensionsmyndigheten',
        'website': 'pensionsmyndigheten.se',
        'retirement_age': '63 earliest; 67 for full benefit',
        'contribution': '18.5% of income (16% inkomst + 2.5% premium)',
        'immigrant_rights': {
          'eu_coordination': 'EU 883/2004',
          'portability': 'Receive anywhere in world',
          'check': 'minpension.se',
        },
        'guarantee_pension': 'Garantipension for low earners: SEK 9,028/month (2024)',
      },
      'unemployment_insurance': {
        'body': 'Inspektionen för Arbetslöshetsförsäkringen (IAF)',
        'a_kassa': 'Voluntary unemployment fund membership strongly recommended',
        'amount': '80% first 200 days, then 70%',
        'basic': 'Alfa-kassan for those not in a-kassa',
        'eligibility': '12 months in a-kassa + 6 months work',
      },
      'cross_border': {
        'ehic': 'Europeiskt sjukförsäkringskort from Försäkringskassan',
        'posted_workers': 'A1 certificate from Försäkringskassan',
      },
      'complaints': {
        'insurance': 'Konsumenternas försäkringsbyrå',
        'pension': 'Pensionsmyndigheten complaint form',
      },
    };
  }

  static Map<String, dynamic> _denmark() {
    return {
      'country': 'Denmark',
      'healthcare_insurance': {
        'system': 'Sygesikring — free universal healthcare via taxes',
        'sundhedskort': 'Yellow health card; get from borger.dk after CPR registration',
        'immigrants': 'EU citizens: CPR number → immediate access',
      },
      'pension': {
        'system': 'Folkepension (state) + ATP + occupational',
        'folkepension': 'Paid to all residents with 40 years Denmark residence',
        'atp': 'Mandatory supplementary pension for employed',
        'retirement_age': 67,
        'immigrant_rights': {
          'reduced_folkepension': 'Partial pension if fewer than 40 years',
          'eu_coordination': 'EU 883/2004',
          'check': 'atp.dk',
        },
      },
      'unemployment_insurance': {
        'body': 'A-kasse (unemployment fund)',
        'amount': 'Max DKK 19,459/month (2024)',
        'dagpenge': '90% of previous wage up to maximum',
        'eligibility': '12 months a-kasse membership + work requirement',
        'duration': '2 years',
        'immigrants': 'Must join a-kasse; EU citizens equal rights',
      },
    };
  }

  static Map<String, dynamic> _norway() {
    return {
      'country': 'Norway',
      'note': 'EEA, not EU — most EU social security rules apply',
      'healthcare_insurance': {
        'system': 'Helseøkonomiforvaltningen (HELFO) — universal',
        'frikort': 'Free card after NOK 3,145/year copayments',
        'immigrants': 'EEA citizens: register with Folkeregisteret + fastlege',
      },
      'pension': {
        'system': 'Folketrygden (National Insurance Scheme)',
        'authority': 'NAV (Arbeids- og velferdsetaten)',
        'website': 'nav.no',
        'retirement_age': 62,
        'contribution': '7.9% employee',
        'immigrant_rights': {
          'eea_coordination': 'EEA rules apply (equivalent to EU 883/2004)',
          'minimum': '3 years to receive any pension',
          'check': 'dinepensjoner.no',
        },
      },
      'unemployment_insurance': {
        'body': 'NAV',
        'dagpenger': '62.4% of previous income',
        'duration': '52-104 weeks based on income',
        'immigrants': 'Equal rights for EEA citizens',
      },
    };
  }

  static Map<String, dynamic> _poland() {
    return {
      'country': 'Poland',
      'healthcare_insurance': {
        'system': 'Narodowy Fundusz Zdrowia (NFZ)',
        'registration': 'PESEL number + employment → automatic NFZ',
        'contribution': '9% of base (fully deductible from income tax)',
        'immigrants': 'EU citizens: register with NFZ using PESEL',
      },
      'pension': {
        'system': 'ZUS (Zakład Ubezpieczeń Społecznych)',
        'website': 'zus.pl',
        'retirement_age': '65 men, 60 women',
        'contribution': '19.52% total',
        'immigrant_rights': {
          'eu_coordination': 'EU 883/2004',
          'non_eu': 'Many bilateral agreements',
          'check': 'platformaUslugi.zus.pl',
        },
      },
      'unemployment_insurance': {
        'body': 'Urząd Pracy (Employment Office)',
        'zasilek': 'PLN 1,491-1,860/month (2024)',
        'duration': '6-12 months',
        'eligibility': '365 days in last 18 months',
      },
    };
  }

  static Map<String, dynamic> _czechia() {
    return {
      'country': 'Czechia',
      'healthcare_insurance': {
        'system': 'Veřejné zdravotní pojištění — mandatory',
        'funds': ['VZP', 'ČPZP', 'OZP', 'ZPŠ', 'ZPMV'],
        'contribution': '13.5% (4.5% employee, 9% employer)',
        'immigrants': 'EU citizens: join Czech health fund',
      },
      'pension': {
        'system': 'ČSSZ (Česká správa sociálního zabezpečení)',
        'website': 'cssz.cz',
        'retirement_age': 65,
        'contribution': '28% total (6.5% employee)',
        'immigrant_rights': {
          'eu_coordination': 'EU 883/2004',
        },
      },
      'unemployment_insurance': {
        'body': 'Úřad práce ČR',
        'amount': '65% first 2 months, 50% remainder',
        'duration': '5-11 months depending on age',
        'eligibility': '12 months in last 2 years',
      },
    };
  }

  static Map<String, dynamic> _hungary() {
    return {
      'country': 'Hungary',
      'healthcare_insurance': {
        'system': 'National Health Insurance Fund (NEAK)',
        'contribution': '8.5% social contribution',
        'taj_card': 'TAJ kártya — social insurance card',
        'immigrants': 'EU citizens: apply for TAJ card with residence registration',
      },
      'pension': {
        'system': 'ONYF (National Pension Insurance Directorate) → MNY',
        'retirement_age': 65,
        'minimum_period': '20 years',
        'immigrant_rights': {
          'eu_coordination': 'EU 883/2004',
        },
      },
      'unemployment_insurance': {
        'body': 'Állami Foglalkoztatási Szolgálat (ÁFSz)',
        'amount': 'HUF 57,000/month flat rate',
        'duration': '90 days',
        'note': 'Hungary has relatively short unemployment benefit period',
      },
    };
  }

  static Map<String, dynamic> _romania() {
    return {
      'country': 'Romania',
      'healthcare_insurance': {
        'system': 'CNAS (Casa Națională de Asigurări de Sănătate)',
        'contribution': '10% of base salary',
        'immigrants': 'EU citizens: register at local CJAS',
      },
      'pension': {
        'system': 'Casa Națională de Pensii Publice (CNPP)',
        'website': 'cnpp.ro',
        'retirement_age': '65 men, 63 women (rising)',
        'minimum_period': '15 years',
        'immigrant_rights': {
          'eu_coordination': 'EU 883/2004',
        },
      },
      'unemployment_insurance': {
        'body': 'ANOFM (National Employment Agency)',
        'amount': '75% of minimum wage or 75% of previous wage',
        'duration': '6-12 months',
        'eligibility': '12 months in last 24',
      },
    };
  }

  static Map<String, dynamic> _bulgaria() {
    return {
      'country': 'Bulgaria',
      'healthcare_insurance': {
        'system': 'NHIF (Национална здравноосигурителна каса)',
        'contribution': '8% total (3.2% employee)',
        'immigrants': 'EU citizens: equal rights with registration',
      },
      'pension': {
        'system': 'National Social Security Institute (НОИ)',
        'retirement_age': '64 men, 61.5 women (rising to 65/63)',
        'minimum_period': '15 years',
        'immigrant_rights': {
          'eu_coordination': 'EU 883/2004',
        },
      },
      'unemployment_insurance': {
        'body': 'Employment Agency (Агенция по заетостта)',
        'amount': '60% of previous insurance income',
        'duration': '4-12 months',
        'eligibility': '9 months in last 15 months',
      },
    };
  }

  static Map<String, dynamic> _croatia() {
    return {
      'country': 'Croatia',
      'healthcare_insurance': {
        'system': 'HZZO (Croatian Health Insurance Fund)',
        'contribution': '16.5% total (employee + employer)',
        'immigrants': 'EU citizens: OIB number + HZZO registration',
      },
      'pension': {
        'system': 'HZMO (Croatian Pension Insurance Institute)',
        'retirement_age': 65,
        'contribution': '20% total (all employee!)',
        'split': '15% first pillar (HZMO), 5% second pillar (private funds)',
        'minimum_period': '15 years',
      },
      'unemployment_insurance': {
        'body': 'Hrvatski zavod za zapošljavanje (HZZ)',
        'amount': '70% of previous salary (max HRK 4,062/month)',
        'duration': '90-450 days',
        'eligibility': '9 months in last 24',
      },
    };
  }

  static Map<String, dynamic> _slovakia() {
    return {
      'country': 'Slovakia',
      'healthcare_insurance': {
        'system': 'Mandatory — choose between VšZP, Dôvera, or Union',
        'contribution': '14% total (4% employee)',
        'immigrants': 'EU citizens: register within 8 days of employment',
      },
      'pension': {
        'system': 'Sociálna poisťovňa',
        'website': 'socpoist.sk',
        'retirement_age': 64,
        'contribution': '28.75% total (7% employee)',
        'immigrant_rights': {
          'eu_coordination': 'EU 883/2004',
        },
      },
      'unemployment_insurance': {
        'body': 'Úrad práce, sociálnych vecí a rodiny',
        'amount': '50% of previous wage',
        'duration': '6 months',
        'eligibility': '24 months in last 4 years',
      },
    };
  }

  static Map<String, dynamic> _slovenia() {
    return {
      'country': 'Slovenia',
      'healthcare_insurance': {
        'system': 'ZZZS (Zavod za zdravstveno zavarovanje)',
        'contribution': '13.45% total (6.36% employee)',
        'immigrants': 'EU citizens: register with ZZZS',
      },
      'pension': {
        'system': 'ZPIZ (Zavod za pokojninsko in invalidsko zavarovanje)',
        'retirement_age': 65,
        'contribution': '24.35% total (15.5% employer, 8.85% employee)',
        'minimum_period': '15 years',
      },
      'unemployment_insurance': {
        'body': 'Zavod RS za zaposlovanje (ZRSZ)',
        'amount': '80% first 3 months, then 60%',
        'duration': '2-25 months based on work history',
        'eligibility': '9 months in last 24',
      },
    };
  }

  static Map<String, dynamic> _lithuania() {
    return {
      'country': 'Lithuania',
      'healthcare_insurance': {
        'system': 'VLSIC (National Health Insurance Fund)',
        'contribution': '6.98% employee',
        'immigrants': 'EU citizens: register at local PSDF',
      },
      'pension': {
        'system': 'SODRA (State Social Insurance Fund Board)',
        'website': 'sodra.lt',
        'retirement_age': 65,
        'contribution': '19.5% total (8.72% employee)',
        'immigrant_rights': {
          'eu_coordination': 'EU 883/2004',
        },
      },
      'unemployment_insurance': {
        'body': 'SODRA',
        'amount': '41.7-63% of previous insurance wage',
        'duration': '9 months',
        'eligibility': '18 months in last 3 years',
      },
    };
  }

  static Map<String, dynamic> _latvia() {
    return {
      'country': 'Latvia',
      'healthcare_insurance': {
        'system': 'National Health Service (NVD)',
        'contribution': 'From employer social tax',
        'immigrants': 'EU citizens: equal rights with registration',
      },
      'pension': {
        'system': 'State Social Insurance Agency (VSAA)',
        'website': 'vsaa.gov.lv',
        'retirement_age': 65,
        'contribution': '34.09% total (10.5% employee)',
        'immigrant_rights': {
          'eu_coordination': 'EU 883/2004',
        },
      },
      'unemployment_insurance': {
        'body': 'State Employment Agency (NVA)',
        'amount': '50-65% of previous wage',
        'duration': '8 months',
        'eligibility': '12 months in last 16 months',
      },
    };
  }

  static Map<String, dynamic> _estonia() {
    return {
      'country': 'Estonia',
      'healthcare_insurance': {
        'system': 'Estonian Health Insurance Fund (EHIF/Tervisekassa)',
        'website': 'haigekassa.ee',
        'contribution': '13% social tax paid by employer (includes health)',
        'digiID': 'Digital ID-card works as health insurance card',
        'immigrants': 'EU citizens: register at local government, get isikukood',
        'waiting_period': 'None if employed (covered from day 1)',
        'ehic': 'Euroopa ravikindlustuskaart — apply at haigekassa.ee',
      },
      'mandatory_insurance': {
        'car': {
          'name': 'Liikluskindlustus (traffic insurance)',
          'mandatory': true,
          'basis': 'Liikluskindlustuse seadus',
          'check': "blis.ee — verify any car's insurance",
          'providers': ['If', 'Gjensidige', 'Ergo', 'Salva', 'Seesam'],
          'uninsured_fine': 'Up to EUR 300 fine',
        },
        'home': {
          'mandatory': false,
          'recommended': 'Kodukindlustus — highly recommended',
          'cost': 'EUR 100-250/year',
          'note': 'Not required by law but most landlords expect it',
        },
      },
      'pension': {
        'system': 'Three-pillar system',
        'authority': 'Pensionikeskus',
        'website': 'pensionikeskus.ee',
        'first_pillar': {
          'name': 'Riiklik pension',
          'type': 'Pay-as-you-go state pension',
          'contribution': 'Employer pays 33% social tax; 20% goes to state pension',
          'retirement_age': 65,
          'minimum_period': '15 years',
        },
        'second_pillar': {
          'name': 'Kohustuslik kogumispension',
          'type': 'Mandatory funded pension (for those born after 1983)',
          'employee_contribution': '2%',
          'state_adds': '4%',
          'opt_out': 'Possible since 2021 reform',
          'funds': ['Swedbank', 'SEB', 'LHV', 'Luminor', 'Tuleva'],
          'check': 'pensionikeskus.ee',
        },
        'third_pillar': {
          'name': 'Täiendav kogumispension',
          'type': 'Voluntary; tax-deductible contributions',
          'tax_benefit': 'Up to EUR 6,000/year tax-deductible',
          'providers': ['LHV', 'Swedbank', 'SEB', 'Luminor'],
        },
        'immigrant_rights': {
          'eu_coordination': 'EU 883/2004 applies',
          'second_pillar_immigrants': 'Must join if under 35 when arriving; optional if older',
          'portability': 'Second + third pillar fully portable; can transfer to another EU fund',
          'check_balance': 'eesti.ee — pension account via ID-card login',
          'non_eu': 'Estonian pension can be received abroad',
        },
        'early_retirement': 'Possible 3 years before retirement age with reduced amount',
        'survivors': 'Toitjakaotuspension for surviving spouse/children',
      },
      'unemployment_insurance': {
        'body': 'Töötukassa (Unemployment Insurance Fund)',
        'website': 'tootukassa.ee',
        'types': {
          'kindlustushüvitis': {
            'name': 'Unemployment insurance benefit (kindlustushüvitis)',
            'basis': 'Contribution-based',
            'amount': '60% first 100 days, then 40%',
            'max': 'Based on average wage',
            'duration': '270 days max',
            'eligibility': '12 months insurance in last 3 years',
          },
          'töötutoetus': {
            'name': 'Unemployment allowance (töötutoetus)',
            'basis': 'Flat rate for those without insurance',
            'amount': 'EUR 9.49/day (2024)',
            'duration': '270 days',
            'eligibility': '180 days employment in last 12 months',
          },
        },
        'immigrants': 'EU citizens: equal rights with isikukood + registration at Töötukassa',
        'job_search': 'Mandatory job search activities; Töötukassa supports',
        'retraining': 'Free retraining courses through Töötukassa',
      },
      'cross_border': {
        'ehic': 'Apply at haigekassa.ee — European Health Insurance Card',
        'posted_workers': 'A1 certificate from Sotsiaalkindlustusamet',
        'receiving_eu_pension': 'Apply via Sotsiaalkindlustusamet (SKA)',
        'pension_from_abroad': 'Inform Pensionikeskus of foreign pension',
      },
      'social_benefits': {
        'toimetulekutoetus': 'Minimum living allowance from local government',
        'child_benefit': '80€/month per child (universal)',
        'parental_benefit': '100% of salary for 435 days',
      },
      'complaints': {
        'insurance': 'Kindlustuse lepitusorgan (Insurance Ombudsman): fin.ee',
        'health_insurance': 'Haigekassa complaint → then Tervishoiuamet',
        'pension': 'Pensionikeskus complaint; then Finantsinspektsioon',
        'unemployment': 'Töötukassa complaint → Töövaidluskomisjon',
      },
      'digital_access': {
        'all_services': 'eesti.ee — access all government services digitally',
        'requires': 'ID-card or Mobiil-ID or Smart-ID',
        'non_citizens': 'E-residency card for non-Estonian citizens',
      },
    };
  }

  static Map<String, dynamic> _portugal() {
    return {
      'country': 'Portugal',
      'healthcare_insurance': {
        'system': 'SNS (Serviço Nacional de Saúde) — universal',
        'registration': 'Centro de Saúde with NIF + residency',
        'cartão_utente': 'Health user card',
        'immigrants': 'EU citizens: equal access after NIF and SNS registration',
      },
      'pension': {
        'system': 'Segurança Social',
        'website': 'seg-social.pt',
        'retirement_age': 66.5,
        'contribution': '34.75% total (11% employee)',
        'minimum_period': '15 years',
        'immigrant_rights': {
          'eu_coordination': 'EU 883/2004',
        },
      },
      'unemployment_insurance': {
        'body': 'IEFP (Instituto do Emprego e Formação Profissional)',
        'amount': '65% of gross wage',
        'duration': '360-900 days based on age + work history',
        'eligibility': '360 days in last 24 months',
      },
    };
  }

  static Map<String, dynamic> _greece() {
    return {
      'country': 'Greece',
      'healthcare_insurance': {
        'system': 'EOPYY (National Organization for Healthcare Services Provision)',
        'amka': 'AMKA (Social Insurance Number) required',
        'immigrants': 'EU citizens: AMKA registration → healthcare access',
      },
      'pension': {
        'system': 'EFKA (Unified Social Security Entity)',
        'website': 'efka.gov.gr',
        'retirement_age': 67,
        'minimum_period': '15 years',
        'contribution': '20% total (6.67% employee)',
        'immigrant_rights': {
          'eu_coordination': 'EU 883/2004',
        },
      },
      'unemployment_insurance': {
        'body': 'DYPA (Public Employment Service)',
        'amount': 'EUR 399/month',
        'duration': '3-12 months',
        'eligibility': '125 working days in last 14 months',
      },
    };
  }

  static Map<String, dynamic> _ireland() {
    return {
      'country': 'Ireland',
      'healthcare_insurance': {
        'system': 'HSE (Health Service Executive) — universal but copays',
        'medical_card': 'Free GP + prescriptions for low income',
        'gp_visit_card': 'Free GP for children under 8',
        'private': 'VHI, Irish Life Health, Laya — popular for private hospitals',
        'immigrants': 'EU citizens: equal access; PPS number required',
      },
      'mandatory_insurance': {
        'car': {
          'name': 'Motor Third Party Liability',
          'mandatory': true,
          'fine': 'EUR 60-2,500',
        },
      },
      'pension': {
        'system': 'State Pension (Contributory) via Dept. of Social Protection',
        'retirement_age': 66,
        'minimum_contributions': '520 weekly contributions',
        'amount': 'EUR 277.30/week (2024)',
        'immigrant_rights': {
          'eu_coordination': 'EU 883/2004',
          'portability': 'Can receive abroad',
          'non_eu': 'Bilateral agreements with US, UK, Canada, Australia',
          'check': 'mywelfare.ie',
        },
        'occupational': 'Employer occupational pension not mandatory but many offer',
      },
      'unemployment_insurance': {
        'body': 'Dept. of Social Protection',
        'jsa': "Jobseeker's Allowance — EUR 232/week (2024)",
        'jb': "Jobseeker's Benefit — contribution-based, higher amount",
        'eligibility': '104 PRSI contributions',
        'immigrants': 'Habitual residence condition applies',
      },
    };
  }

  static Map<String, dynamic> _luxembourg() {
    return {
      'country': 'Luxembourg',
      'healthcare_insurance': {
        'system': 'CNS (Caisse Nationale de Santé)',
        'contribution': '6.6% total (3.05% employee)',
        'immigrants': 'EU citizens: join CNS immediately upon employment',
      },
      'pension': {
        'system': "CNAP (Caisse Nationale d'Assurance Pension)",
        'retirement_age': 65,
        'minimum_period': '10 years',
        'contribution': '24% total (8% employee)',
        'note': 'Luxembourg pensions among highest in EU',
        'immigrant_rights': {
          'eu_coordination': 'EU 883/2004; many cross-border workers',
          'frontier_workers': 'Special regime for daily cross-border commuters',
        },
      },
      'unemployment_insurance': {
        'body': "ADEM (Agence pour le Développement de l'Emploi)",
        'amount': '80% of last wage (very generous)',
        'duration': '12 months',
        'eligibility': '26 weeks in last year',
      },
    };
  }

  static Map<String, dynamic> _malta() {
    return {
      'country': 'Malta',
      'healthcare_insurance': {
        'system': 'Public healthcare — free for residents',
        'private': 'Optional; recommended for faster access',
        'immigrants': 'EU citizens: equal access with residency registration',
      },
      'pension': {
        'system': 'Department of Social Security',
        'retirement_age': 65,
        'minimum_period': '30 years for full pension',
        'contribution': '10% total (5% employee)',
        'immigrant_rights': {
          'eu_coordination': 'EU 883/2004',
        },
      },
      'unemployment_insurance': {
        'body': 'Jobsplus (Employment and Training Corporation)',
        'amount': 'EUR 174.46/week',
        'duration': '156 days per unemployment episode',
        'eligibility': '50 weeks contributions in last 2 years',
      },
    };
  }

  // === UTILITY METHODS ===

  static Map<String, dynamic>? getCountry(String countryCode) {
    return getAllCountries()[countryCode.toUpperCase()];
  }

  static String getRetirementAge(String countryCode) {
    final country = getCountry(countryCode);
    if (country == null) return 'Unknown';
    final pension = country['pension'] as Map<String, dynamic>?;
    if (pension == null) return 'Unknown';
    final age = pension['retirement_age'] ?? pension['aow_age'];
    return age?.toString() ?? 'Unknown';
  }

  static List<String> getEUCoordinationCountries() {
    final countries = getAllCountries();
    return countries.entries
        .where((e) {
          final pension = e.value['pension'] as Map<String, dynamic>?;
          final immigrant = pension?['immigrant_rights'] as Map<String, dynamic>?;
          return immigrant?.containsKey('eu_coordination') == true;
        })
        .map((e) => e.key)
        .toList();
  }

  static Map<String, dynamic> getUnemploymentBenefit(String countryCode) {
    final country = getCountry(countryCode);
    if (country == null) return {'error': 'Country not found'};
    return Map<String, dynamic>.from(country['unemployment_insurance'] ?? {});
  }

  static Map<String, dynamic> getPensionInfo(String countryCode) {
    final country = getCountry(countryCode);
    if (country == null) return {'error': 'Country not found'};
    return Map<String, dynamic>.from(country['pension'] ?? {});
  }

  static List<Map<String, dynamic>> getCountriesWithLowPensionMinimum() {
    final countries = getAllCountries();
    return countries.entries
        .where((e) {
          final pension = e.value['pension'] as Map<String, dynamic>?;
          final minYears = pension?['minimum_period'];
          if (minYears is int) return minYears <= 10;
          return false;
        })
        .map((e) => {
              'country_code': e.key,
              'country': e.value['country'],
              'minimum_period': e.value['pension']?['minimum_period'],
            })
        .toList();
  }

  static String getHealthcareSystem(String countryCode) {
    final country = getCountry(countryCode);
    if (country == null) return 'Country not found';
    final healthcare = country['healthcare_insurance'] as Map<String, dynamic>?;
    return healthcare?['system'] ?? 'No data';
  }
}
