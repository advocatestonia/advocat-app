// lib/services/consumer_protection_database.dart
// Consumer Protection Rights for EU Immigrants
// Coverage: 27 EU countries × product returns, warranties, scams, EU261 flight rights, online shopping

class ConsumerProtectionDatabase {
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
      'authority': 'Kilpailu- ja kuluttajavirasto (KKV)',
      'authority_website': 'kkv.fi',
      'authority_phone': '029 505 3000',
      'returns_policy': {
        'standard_return_days': 14,
        'legal_basis': 'EU Consumer Rights Directive 2011/83/EU',
        'online_shopping': '14 days right of withdrawal, no reason needed',
        'in_store': 'No legal right, but many shops offer voluntary policy',
        'exceptions': ['Perishable goods', 'Customized items', 'Digital content downloaded'],
        'process': 'Contact seller, fill return form, get refund within 14 days of receiving returned item',
      },
      'warranty': {
        'minimum_years': 2,
        'legal_basis': 'EU Sale of Goods Directive 2019/771',
        'reverse_burden_of_proof': '1 year (product presumed defective if fault appears within 1 year)',
        'what_covered': 'Manufacturing defects, non-conformity with description',
        'your_rights': ['Repair', 'Replacement', 'Price reduction', 'Refund if repair/replacement fails'],
        'commercial_warranty': 'Extra, must be honored as stated',
      },
      'digital_goods': {
        'warranty_years': 2,
        'streaming_services': 'Must work as described, EU Digital Content Directive applies',
        'subscriptions': 'Cancel anytime for monthly, renewal notice required for annual',
      },
      'flight_rights': {
        'regulation': 'EU Regulation 261/2004',
        'applies_to': 'All flights from EU airports, flights TO EU on EU airlines',
        'delays': {
          '2h_short': 'Meals, refreshments, 2 calls/emails',
          '3h_long': 'Compensation EUR 250-600 depending on distance',
          'overnight': 'Hotel accommodation + transport',
        },
        'cancellation': 'Full refund OR rerouting + compensation EUR 250-600',
        'denied_boarding': 'Compensation + choice of refund or rerouting',
        'compensation_amounts': {
          'under_1500km': 250,
          '1500_3500km': 400,
          'over_3500km': 600,
        },
        'how_to_claim': 'Write to airline first, then Traficom (traficom.fi) if refused',
        'time_limit_years': 3,
      },
      'package_holidays': {
        'directive': 'EU Package Travel Directive 2015/2302',
        'cancellation_right': 'Full refund if significant change or unavoidable circumstances',
        'insolvency_protection': 'All package holidays must be insured against organizer bankruptcy',
      },
      'unfair_practices': {
        'banned': ['False urgency', 'Hidden fees', 'Pre-ticked boxes', 'Misleading pricing'],
        'report_to': 'KKV - kuluttajaneuvonta@kkv.fi',
        'consumer_ombudsman': 'kuluttaja-asiamies, KKV',
      },
      'online_shopping': {
        'secure_payment': 'Use credit card for chargeback rights',
        'fake_shops': 'Check Finnish Business ID (Y-tunnus) at ytj.fi',
        'cross_border_disputes': 'ODR platform: ec.europa.eu/consumers/odr',
        'parcel_delivery': 'Risk transfers to buyer upon delivery confirmation',
      },
      'financial_services': {
        'bank_charges': 'Transparent, regulated by Finanssivalvonta (FSA)',
        'loan_default': 'Right to information before contract signing',
        'insurance': 'Financial Ombudsman: FINE (fine.fi)',
      },
      'alternative_dispute': {
        'body': 'Kuluttajariitalautakunta (Consumer Disputes Board)',
        'website': 'kuluttajariitalautakunta.fi',
        'cost': 'Free',
        'time': '6-12 months',
        'binding': 'Not legally binding but usually followed',
      },
      'emergency_contacts': {
        'consumer_advice': 'kuluttajaneuvonta@kkv.fi / 029 505 3050',
        'ecc_finland': 'ecc.fi (European Consumer Centre)',
        'legal_aid': 'oikeusaputoimisto.fi',
      },
      'language_rights': 'You can communicate in Finnish or Swedish. English accepted by most companies.',
      'immigrant_specific': {
        'language_barrier': 'Consumer rights apply equally regardless of language',
        'online_purchases': 'Cross-border EU purchases have same protections',
        'marketplace_sellers': 'Amazon/eBay marketplace: seller responsible, platform secondary',
        'subscription_traps': 'Must be clearly stated; cancellation easy as signup',
      },
    };
  }

  static Map<String, dynamic> _germany() {
    return {
      'country': 'Germany',
      'authority': 'Verbraucherzentrale Bundesverband (vzbv)',
      'authority_website': 'verbraucherzentrale.de',
      'authority_phone': '030 258 00 0',
      'returns_policy': {
        'standard_return_days': 14,
        'legal_basis': 'BGB §312g, EU Consumer Rights Directive',
        'online_shopping': '14-day Widerrufsrecht, written notice required',
        'in_store': 'Voluntary only; many shops offer 30 days',
        'exceptions': ['Customized goods', 'Sealed hygiene products opened', 'Digital downloads'],
        'process': 'Widerrufserklärung (withdrawal declaration) to seller within 14 days',
      },
      'warranty': {
        'minimum_years': 2,
        'legal_name': 'Gewährleistung (Mängelhaftung)',
        'reverse_burden_of_proof': '1 year (extended from 6 months in 2022)',
        'what_covered': 'Material defects (Sachmangel), legal defects',
        'your_rights': ['Nacherfüllung (repair/replacement)', 'Minderung (price reduction)', 'Rücktritt (withdrawal)', 'Schadensersatz (damages)'],
        'commercial_warranty': 'Garantie - additional, voluntarily given by manufacturer',
      },
      'digital_goods': {
        'warranty_years': 2,
        'app_stores': 'Google Play / App Store refund: 48h after purchase',
        'streaming': 'Netflix etc. must function as described',
      },
      'flight_rights': {
        'regulation': 'EU 261/2004',
        'enforcement_body': 'Luftfahrt-Bundesamt (LBA)',
        'website': 'lba.de',
        'delays': {
          '2h_short': 'Care (meals, calls)',
          '3h_arrival': 'Compensation EUR 250-600',
          'overnight': 'Hotel + transport',
        },
        'cancellation': 'Refund + compensation (unless extraordinary circumstances)',
        'compensation_amounts': {
          'under_1500km': 250,
          '1500_3500km': 400,
          'over_3500km': 600,
        },
        'how_to_claim': 'Airline → LBA complaint → Schlichtungsstelle Luft- und Seereisen',
        'time_limit': '3 years (§195 BGB)',
      },
      'unfair_practices': {
        'banned': ['Aggressive selling', 'Misleading information', 'Hidden subscriptions'],
        'report_to': 'Verbraucherzentrale your Bundesland',
        'doorstep_selling': '14-day cooling-off period',
      },
      'online_shopping': {
        'trusted_seal': 'Trusted Shops, TÜV-certified shops',
        'fake_shops': 'Check Impressum (legal notice) required by law',
        'marketplace': 'Marketplace sellers: platform informs if professional seller',
        'price_guarantee': 'Lowest price must be shown (Omnibus Directive 2021)',
      },
      'financial_services': {
        'banking_ombudsman': 'Bankenombudsmann',
        'insurance_ombudsman': 'Versicherungsombudsmann',
        'debt_collection': 'Must show original creditor, amounts itemized',
      },
      'alternative_dispute': {
        'body': 'Schlichtungsstellen (sector-specific arbitration)',
        'general': 'Verbraucherschlichtungsstelle',
        'cost': 'Free for consumers',
        'binding': 'Depends on sector',
      },
      'immigrant_specific': {
        'language': 'German required in contracts, but courts accept translators',
        'warranty_cards': 'EU warranty valid without registration',
        'auto_renewals': 'Abo-Fallen (subscription traps) illegal if not clearly stated',
        'housing_deposits': 'Kaution max 3 months rent, returned within reasonable time',
      },
    };
  }

  static Map<String, dynamic> _france() {
    return {
      'country': 'France',
      'authority': 'Direction Générale de la Concurrence, de la Consommation et de la Répression des Fraudes (DGCCRF)',
      'authority_website': 'economie.gouv.fr/dgccrf',
      'authority_phone': '3939',
      'returns_policy': {
        'standard_return_days': 14,
        'online_shopping': '14 days droit de rétractation',
        'in_store': 'No legal right; shop policy only',
        'sales': 'Soldes: retailers set own return policies',
        'process': 'Declaration to seller, return item, refund within 14 days',
      },
      'warranty': {
        'minimum_years': 2,
        'legal_name': 'Garantie légale de conformité',
        'reverse_burden_of_proof': '2 years (France extended beyond EU minimum)',
        'hidden_defects': 'Vices cachés - additional 2 years from discovery',
        'your_rights': ['Repair', 'Replacement', 'Refund'],
        'presumption': 'Defects appearing within 2 years presumed pre-existing',
      },
      'digital_goods': {
        'warranty_years': 2,
        'streaming': 'Same conformity guarantee applies',
      },
      'flight_rights': {
        'regulation': 'EU 261/2004',
        'enforcement_body': 'Direction générale de l\'Aviation civile (DGAC)',
        'mediation': 'Médiateur du Tourisme et du Voyage (MTV)',
        'compensation_amounts': {
          'under_1500km': 250,
          '1500_3500km': 400,
          'over_3500km': 600,
        },
        'time_limit': '5 years',
      },
      'unfair_practices': {
        'banned': ['Vente forcée (forced selling)', 'Clauses abusives (unfair clauses)'],
        'report_to': 'SignalConso (signal.conso.gouv.fr)',
        'door_to_door': '14 days cooling-off',
      },
      'online_shopping': {
        'trusted': 'Look for "Certifié FEVAD" label',
        'amiable_resolution': 'Médiation required before court for most disputes',
      },
      'alternative_dispute': {
        'body': 'Médiateur de la consommation (sector-specific)',
        'platform': 'RLL (Règlement en Ligne des Litiges)',
        'cost': 'Free',
      },
      'immigrant_specific': {
        'language': 'French required for contracts; right to translation',
        'solidarity_contract': 'CAF benefits separate from consumer rights',
        'rental': 'Dépôt de garantie: 1 month (unfurnished), 2 months (furnished)',
      },
    };
  }

  static Map<String, dynamic> _spain() {
    return {
      'country': 'Spain',
      'authority': 'Agencia Española de Consumo, Seguridad Alimentaria y Nutrición (AECOSAN)',
      'authority_website': 'consumo.gob.es',
      'returns_policy': {
        'standard_return_days': 14,
        'legal_basis': 'Ley General para la Defensa de los Consumidores y Usuarios',
        'online_shopping': '14 days desistimiento',
        'in_store': 'Voluntary only',
        'january_sales': 'Rebajas: store policy applies',
      },
      'warranty': {
        'minimum_years': 3,
        'note': 'Spain extended warranty to 3 years (above EU minimum of 2)',
        'second_hand': '1 year minimum',
        'reverse_burden': '2 years',
        'your_rights': ['Reparación', 'Sustitución', 'Reducción del precio', 'Resolución'],
      },
      'flight_rights': {
        'regulation': 'EU 261/2004',
        'enforcement_body': 'Agencia Estatal de Seguridad Aérea (AESA)',
        'website': 'seguridadaerea.gob.es',
        'time_limit': '5 years',
        'compensation_amounts': {
          'under_1500km': 250,
          '1500_3500km': 400,
          'over_3500km': 600,
        },
      },
      'unfair_practices': {
        'banned': ['Ventas piramidales', 'Publicidad engañosa'],
        'report_to': 'OMIC (Oficina Municipal de Información al Consumidor)',
      },
      'alternative_dispute': {
        'body': 'Sistema Arbitral de Consumo',
        'cost': 'Free',
        'binding': 'Yes, if company participates',
      },
      'immigrant_specific': {
        'language': 'Spanish; regional languages in autonomous communities',
        'NIE_required': 'NIE (foreigner ID) needed for major purchases',
        'rental_deposit': '1 month deposit; fianza deposited with regional authority',
      },
    };
  }

  static Map<String, dynamic> _italy() {
    return {
      'country': 'Italy',
      'authority': 'Autorità Garante della Concorrenza e del Mercato (AGCM)',
      'authority_website': 'agcm.it',
      'returns_policy': {
        'standard_return_days': 14,
        'online_shopping': '14 days diritto di recesso',
        'in_store': 'Voluntary only',
        'exceptions': ['Tailor-made', 'Perishables', 'Newspapers'],
      },
      'warranty': {
        'minimum_years': 2,
        'reverse_burden': '1 year',
        'used_goods': '1 year minimum',
        'your_rights': ['Riparazione', 'Sostituzione', 'Riduzione del prezzo', 'Risoluzione del contratto'],
      },
      'flight_rights': {
        'regulation': 'EU 261/2004',
        'enforcement_body': 'Autorità di Regolazione dei Trasporti (ART)',
        'time_limit': '2 years',
        'compensation_amounts': {
          'under_1500km': 250,
          '1500_3500km': 400,
          'over_3500km': 600,
        },
      },
      'alternative_dispute': {
        'body': 'Conciliazione paritetica (sector-specific)',
        'telecoms': 'AGCOM - Conciliazione',
        'banking': 'ABF (Arbitro Bancario Finanziario)',
      },
      'immigrant_specific': {
        'codice_fiscale': 'Required for any contract',
        'rental': 'Caparra: negotiable, typically 1-3 months',
        'postal_delays': 'Poste Italiane delays common; track packages',
      },
    };
  }

  static Map<String, dynamic> _netherlands() {
    return {
      'country': 'Netherlands',
      'authority': 'Autoriteit Consument en Markt (ACM)',
      'authority_website': 'acm.nl',
      'returns_policy': {
        'standard_return_days': 14,
        'online_shopping': '14 days bedenktijd',
        'in_store': 'Voluntary; most major stores offer 30 days',
      },
      'warranty': {
        'minimum_years': 2,
        'note': 'Dutch law: product must work reasonably long (may exceed 2 years for expensive goods)',
        'reverse_burden': '1 year',
        'your_rights': ['Herstel (repair)', 'Vervanging (replacement)', 'Ontbinding (cancellation)', 'Schadevergoeding (damages)'],
      },
      'flight_rights': {
        'regulation': 'EU 261/2004',
        'enforcement_body': 'Inspectie Leefomgeving en Transport (ILT)',
        'mediation': 'Geschillencommissie Luchtvaart',
        'time_limit': '5 years',
        'compensation_amounts': {
          'under_1500km': 250,
          '1500_3500km': 400,
          'over_3500km': 600,
        },
      },
      'alternative_dispute': {
        'body': 'Geschillencommissie (sector-specific)',
        'website': 'degeschillencommissie.nl',
        'cost': 'Small fee for consumer',
        'binding': 'Yes',
      },
      'immigrant_specific': {
        'DigiD': 'Digital identity; get BSN number first',
        'rental': 'Borg max 2 months rent; returned within 30 days',
        'utilities': 'Compare at energievergelijker.nl',
      },
    };
  }

  static Map<String, dynamic> _belgium() {
    return {
      'country': 'Belgium',
      'authority': 'SPF Économie / FOD Economie',
      'authority_website': 'economie.fgov.be',
      'returns_policy': {
        'standard_return_days': 14,
        'online_shopping': '14 days herroepingsrecht / droit de rétractation',
        'in_store': 'Voluntary',
      },
      'warranty': {
        'minimum_years': 2,
        'reverse_burden': '1 year',
      },
      'flight_rights': {
        'regulation': 'EU 261/2004',
        'enforcement_body': 'SPF Mobilité et Transports',
        'time_limit': '1 year (be careful!)',
        'compensation_amounts': {
          'under_1500km': 250,
          '1500_3500km': 400,
          'over_3500km': 600,
        },
      },
      'alternative_dispute': {
        'body': 'Consumer Mediation Service (CMS)',
        'website': 'consumermediation.be',
        'cost': 'Free',
      },
      'immigrant_specific': {
        'languages': 'FR/NL/DE - use your preferred language',
        'rental': '2 months deposit typical',
      },
    };
  }

  static Map<String, dynamic> _austria() {
    return {
      'country': 'Austria',
      'authority': 'Bundesarbeiterkammer (AK)',
      'authority_website': 'arbeiterkammer.at',
      'returns_policy': {
        'standard_return_days': 14,
        'online_shopping': '14 days Rücktrittsrecht',
        'in_store': 'Voluntary',
      },
      'warranty': {
        'minimum_years': 2,
        'reverse_burden': '1 year',
        'your_rights': ['Verbesserung (repair)', 'Austausch (replacement)', 'Preisminderung', 'Wandlung (cancellation)'],
      },
      'flight_rights': {
        'regulation': 'EU 261/2004',
        'enforcement_body': 'Austro Control',
        'time_limit': '3 years',
        'compensation_amounts': {
          'under_1500km': 250,
          '1500_3500km': 400,
          'over_3500km': 600,
        },
      },
      'alternative_dispute': {
        'body': 'Internet Ombudsmann, sector-specific Schlichtungsstellen',
        'website': 'ombudsmann.at',
        'cost': 'Free',
      },
    };
  }

  static Map<String, dynamic> _sweden() {
    return {
      'country': 'Sweden',
      'authority': 'Konsumentverket',
      'authority_website': 'konsumentverket.se',
      'consumer_hotline': 'Hallå konsument: 0771-42 33 00',
      'returns_policy': {
        'standard_return_days': 14,
        'online_shopping': '14 days ångervård',
        'in_store': 'Voluntary; many stores offer 30+ days',
      },
      'warranty': {
        'minimum_years': 3,
        'note': 'Sweden: 3 years for new goods (above EU minimum)',
        'reverse_burden': '2 years',
        'your_rights': ['Avhjälpande (repair)', 'Omleverans (replacement)', 'Prisavdrag (price reduction)', 'Hävning (cancellation)'],
      },
      'flight_rights': {
        'regulation': 'EU 261/2004',
        'enforcement_body': 'Transportstyrelsen',
        'mediation': 'ARN (Allmänna reklamationsnämnden)',
        'time_limit': '3 years',
        'compensation_amounts': {
          'under_1500km': 250,
          '1500_3500km': 400,
          'over_3500km': 600,
        },
      },
      'alternative_dispute': {
        'body': 'Allmänna reklamationsnämnden (ARN)',
        'website': 'arn.se',
        'cost': 'Free',
        'binding': 'Recommended (not legally binding but most companies comply)',
      },
      'immigrant_specific': {
        'language': 'Swedish; Konsumentverket has info in multiple languages',
        'personnummer': 'Required for contracts; alternatives for new arrivals',
        'rental': 'Hyresdeposition max 3 months',
      },
    };
  }

  static Map<String, dynamic> _denmark() {
    return {
      'country': 'Denmark',
      'authority': 'Forbrugerrådet Tænk',
      'authority_website': 'taenk.dk',
      'returns_policy': {
        'standard_return_days': 14,
        'online_shopping': '14 days fortrydelsesret',
        'in_store': 'Voluntary; some stores offer 30 days',
      },
      'warranty': {
        'minimum_years': 2,
        'reverse_burden': '2 years (Denmark extended)',
        'your_rights': ['Afhjælpning', 'Omlevering', 'Forholdsmæssigt afslag', 'Hæve købet'],
      },
      'flight_rights': {
        'regulation': 'EU 261/2004',
        'enforcement_body': 'Trafikstyrelsen',
        'time_limit': '3 years',
        'compensation_amounts': {
          'under_1500km': 250,
          '1500_3500km': 400,
          'over_3500km': 600,
        },
      },
      'alternative_dispute': {
        'body': 'Forbrugerklagenævnet',
        'website': 'forbrug.dk',
        'fee': 'DKK 100-400',
        'binding': 'Yes',
      },
    };
  }

  static Map<String, dynamic> _norway() {
    return {
      'country': 'Norway',
      'authority': 'Forbrukertilsynet',
      'authority_website': 'forbrukertilsynet.no',
      'note': 'Norway is EEA (not EU) but applies most EU consumer law',
      'returns_policy': {
        'standard_return_days': 14,
        'online_shopping': '14 days angrerett',
        'in_store': 'Voluntary',
      },
      'warranty': {
        'minimum_years': 5,
        'note': 'Norway: 5 years for goods meant to last (extraordinary!)',
        'reverse_burden': '6 months',
      },
      'flight_rights': {
        'regulation': 'EU 261/2004 (via EEA)',
        'enforcement_body': 'Luftfartstilsynet',
        'compensation_amounts': {
          'under_1500km': 250,
          '1500_3500km': 400,
          'over_3500km': 600,
        },
      },
      'alternative_dispute': {
        'body': 'Forbrukerrådet',
        'website': 'forbrukerradet.no',
        'cost': 'Free',
      },
    };
  }

  static Map<String, dynamic> _poland() {
    return {
      'country': 'Poland',
      'authority': 'Urząd Ochrony Konkurencji i Konsumentów (UOKiK)',
      'authority_website': 'uokik.gov.pl',
      'returns_policy': {
        'standard_return_days': 14,
        'online_shopping': '14 days prawo odstąpienia od umowy',
        'in_store': 'Voluntary',
      },
      'warranty': {
        'minimum_years': 2,
        'reverse_burden': '1 year',
        'your_rights': ['Naprawa', 'Wymiana', 'Obniżenie ceny', 'Odstąpienie od umowy'],
      },
      'flight_rights': {
        'regulation': 'EU 261/2004',
        'enforcement_body': 'Urząd Lotnictwa Cywilnego (ULC)',
        'time_limit': '1 year',
        'compensation_amounts': {
          'under_1500km': 250,
          '1500_3500km': 400,
          'over_3500km': 600,
        },
      },
      'alternative_dispute': {
        'body': 'Rzecznik Praw Konsumentów (Consumer Rights Advocate)',
        'inspekcja': 'Inspekcja Handlowa (Trade Inspection)',
        'cost': 'Free',
      },
      'immigrant_specific': {
        'PESEL': 'Required for major transactions',
        'language': 'Polish required; interpreter rights in disputes',
        'scam_warning': 'Check KNF register for financial services',
      },
    };
  }

  static Map<String, dynamic> _czechia() {
    return {
      'country': 'Czechia',
      'authority': 'Česká obchodní inspekce (ČOI)',
      'authority_website': 'coi.cz',
      'returns_policy': {
        'standard_return_days': 14,
        'online_shopping': '14 days odstoupení od smlouvy',
        'in_store': 'Voluntary',
      },
      'warranty': {
        'minimum_years': 2,
        'reverse_burden': '1 year',
      },
      'flight_rights': {
        'regulation': 'EU 261/2004',
        'enforcement_body': 'Úřad pro civilní letectví (ÚCL)',
        'time_limit': '3 years',
        'compensation_amounts': {
          'under_1500km': 250,
          '1500_3500km': 400,
          'over_3500km': 600,
        },
      },
      'alternative_dispute': {
        'body': 'ČOI ADR',
        'website': 'coi.cz/adr',
        'cost': 'Free',
      },
    };
  }

  static Map<String, dynamic> _hungary() {
    return {
      'country': 'Hungary',
      'authority': 'Gazdasági Versenyhivatal (GVH)',
      'authority_website': 'gvh.hu',
      'returns_policy': {
        'standard_return_days': 14,
        'online_shopping': '14 days elállási jog',
        'in_store': 'Voluntary',
      },
      'warranty': {
        'minimum_years': 2,
        'kellékszavatosság': '2 years statutory warranty',
        'termékszavatosság': 'Product liability',
        'reverse_burden': '1 year',
      },
      'flight_rights': {
        'regulation': 'EU 261/2004',
        'enforcement_body': 'Budapest Főváros Kormányhivatala',
        'time_limit': '5 years',
        'compensation_amounts': {
          'under_1500km': 250,
          '1500_3500km': 400,
          'over_3500km': 600,
        },
      },
      'alternative_dispute': {
        'body': 'Békéltető testület (Conciliation Body)',
        'website': 'bekeltetes.hu',
        'cost': 'Free',
        'binding': 'Yes if company registered',
      },
    };
  }

  static Map<String, dynamic> _romania() {
    return {
      'country': 'Romania',
      'authority': 'Autoritatea Națională pentru Protecția Consumatorilor (ANPC)',
      'authority_website': 'anpc.ro',
      'returns_policy': {
        'standard_return_days': 14,
        'online_shopping': '14 days dreptul de retragere',
        'in_store': 'Voluntary',
      },
      'warranty': {
        'minimum_years': 2,
        'reverse_burden': '1 year',
      },
      'flight_rights': {
        'regulation': 'EU 261/2004',
        'enforcement_body': 'Autoritatea Aeronautică Civilă Română (AACR)',
        'time_limit': '3 years',
        'compensation_amounts': {
          'under_1500km': 250,
          '1500_3500km': 400,
          'over_3500km': 600,
        },
      },
      'alternative_dispute': {
        'body': 'SAL-Fin (financial services) or ANPC mediation',
        'cost': 'Free',
      },
    };
  }

  static Map<String, dynamic> _bulgaria() {
    return {
      'country': 'Bulgaria',
      'authority': 'Komisiya za zashtita na potrebitelite (KZP)',
      'authority_website': 'kzp.bg',
      'returns_policy': {
        'standard_return_days': 14,
        'online_shopping': '14 days pravo na otkazване',
        'in_store': 'Voluntary',
      },
      'warranty': {
        'minimum_years': 2,
        'reverse_burden': '1 year',
      },
      'flight_rights': {
        'regulation': 'EU 261/2004',
        'enforcement_body': 'Glaven Direktor na GD GA',
        'time_limit': '5 years',
        'compensation_amounts': {
          'under_1500km': 250,
          '1500_3500km': 400,
          'over_3500km': 600,
        },
      },
      'alternative_dispute': {
        'body': 'KZP mediation',
        'cost': 'Free',
      },
    };
  }

  static Map<String, dynamic> _croatia() {
    return {
      'country': 'Croatia',
      'authority': 'Državni inspektorat',
      'authority_website': 'inspektorat.gov.hr',
      'returns_policy': {
        'standard_return_days': 14,
        'online_shopping': '14 days pravo na jednostrani raskid ugovora',
        'in_store': 'Voluntary',
      },
      'warranty': {
        'minimum_years': 2,
        'reverse_burden': '1 year',
      },
      'flight_rights': {
        'regulation': 'EU 261/2004',
        'enforcement_body': 'Hrvatska agencija za civilno zrakoplovstvo (CCAA)',
        'time_limit': '3 years',
        'compensation_amounts': {
          'under_1500km': 250,
          '1500_3500km': 400,
          'over_3500km': 600,
        },
      },
      'alternative_dispute': {
        'body': 'Centar za mirenje',
        'cost': 'Small fee',
      },
    };
  }

  static Map<String, dynamic> _slovakia() {
    return {
      'country': 'Slovakia',
      'authority': 'Slovenská obchodná inšpekcia (SOI)',
      'authority_website': 'soi.sk',
      'returns_policy': {
        'standard_return_days': 14,
        'online_shopping': '14 days odstúpenie od zmluvy',
        'in_store': 'Voluntary',
      },
      'warranty': {
        'minimum_years': 2,
        'reverse_burden': '1 year',
      },
      'flight_rights': {
        'regulation': 'EU 261/2004',
        'enforcement_body': 'Letový prevádzkový útvar Slovenska',
        'time_limit': '3 years',
        'compensation_amounts': {
          'under_1500km': 250,
          '1500_3500km': 400,
          'over_3500km': 600,
        },
      },
      'alternative_dispute': {
        'body': 'SOI ADR',
        'cost': 'Free',
      },
    };
  }

  static Map<String, dynamic> _slovenia() {
    return {
      'country': 'Slovenia',
      'authority': 'Tržni inšpektorat RS (TIRS)',
      'authority_website': 'ti.gov.si',
      'returns_policy': {
        'standard_return_days': 14,
        'online_shopping': '14 days odstop od pogodbe',
        'in_store': 'Voluntary',
      },
      'warranty': {
        'minimum_years': 2,
        'reverse_burden': '1 year',
      },
      'flight_rights': {
        'regulation': 'EU 261/2004',
        'enforcement_body': 'Javna agencija za civilno letalstvo (CAA Slovenia)',
        'time_limit': '5 years',
        'compensation_amounts': {
          'under_1500km': 250,
          '1500_3500km': 400,
          'over_3500km': 600,
        },
      },
      'alternative_dispute': {
        'body': 'Arbitraža pri Trgovinski zbornici',
        'cost': 'Fee-based',
      },
    };
  }

  static Map<String, dynamic> _lithuania() {
    return {
      'country': 'Lithuania',
      'authority': 'Valstybinė vartotojų teisių apsaugos tarnyba (VVTAT)',
      'authority_website': 'vvtat.lt',
      'returns_policy': {
        'standard_return_days': 14,
        'online_shopping': '14 days atsisakymo teisė',
        'in_store': 'Voluntary',
      },
      'warranty': {
        'minimum_years': 2,
        'reverse_burden': '6 months',
      },
      'flight_rights': {
        'regulation': 'EU 261/2004',
        'enforcement_body': 'Civilinės aviacijos administracija (CAA Lithuania)',
        'time_limit': '3 years',
        'compensation_amounts': {
          'under_1500km': 250,
          '1500_3500km': 400,
          'over_3500km': 600,
        },
      },
      'alternative_dispute': {
        'body': 'VVTAT mediation',
        'cost': 'Free',
        'binding': 'Recommended',
      },
    };
  }

  static Map<String, dynamic> _latvia() {
    return {
      'country': 'Latvia',
      'authority': 'Patērētāju tiesību aizsardzības centrs (PTAC)',
      'authority_website': 'ptac.gov.lv',
      'returns_policy': {
        'standard_return_days': 14,
        'online_shopping': '14 days atteikuma tiesības',
        'in_store': 'Voluntary',
      },
      'warranty': {
        'minimum_years': 2,
        'reverse_burden': '6 months',
      },
      'flight_rights': {
        'regulation': 'EU 261/2004',
        'enforcement_body': 'Civilās aviācijas aģentūra (CAA Latvia)',
        'time_limit': '3 years',
        'compensation_amounts': {
          'under_1500km': 250,
          '1500_3500km': 400,
          'over_3500km': 600,
        },
      },
      'alternative_dispute': {
        'body': 'PTAC dispute resolution',
        'cost': 'Free',
      },
    };
  }

  static Map<String, dynamic> _estonia() {
    return {
      'country': 'Estonia',
      'authority': 'Tarbijakaitse ja Tehnilise Järelevalve Amet (TTJA)',
      'authority_website': 'ttja.ee',
      'consumer_hotline': '620 1707',
      'returns_policy': {
        'standard_return_days': 14,
        'online_shopping': '14 days taganemisõigus',
        'in_store': 'Voluntary',
        'exceptions': ['Customized goods', 'Perishables', 'Sealed hygiene products opened'],
        'process': 'Written notice to seller; refund within 14 days',
      },
      'warranty': {
        'minimum_years': 2,
        'reverse_burden': '2 years (Estonia extended)',
        'used_goods': '1 year',
        'your_rights': ['Tasuta parandamine', 'Asendamine', 'Hinnaalandus', 'Lepingust taganemine'],
        'hidden_defects': 'Seller liable for hidden defects for 2 years',
      },
      'digital_goods': {
        'warranty_years': 2,
        'e_services': 'X-Road based services; standard warranty applies',
      },
      'flight_rights': {
        'regulation': 'EU 261/2004',
        'enforcement_body': 'TTJA (Transport Division)',
        'time_limit': '3 years',
        'compensation_amounts': {
          'under_1500km': 250,
          '1500_3500km': 400,
          'over_3500km': 600,
        },
        'how_to_claim': 'Write to airline → TTJA complaint if refused',
      },
      'online_shopping': {
        'trusted': 'Look for e-kaubandus.ee member badge',
        'digital_signature': 'Many Estonian shops accept ID-card purchase',
        'cross_border': 'ECC Estonia: eec.ee',
      },
      'unfair_practices': {
        'banned': ['Ebaaus kauplemisvõte', 'Eksitav reklaam'],
        'report_to': 'TTJA: info@ttja.ee',
        'scam_registry': 'Check tarbijakaitse.ee for warnings',
      },
      'alternative_dispute': {
        'body': 'Tarbijakaitse komisjon (Consumer Disputes Committee)',
        'website': 'tarbijakaitse.ee',
        'cost': 'Free',
        'time': '90 days',
        'binding': 'Yes (for companies that accept jurisdiction)',
      },
      'immigrant_specific': {
        'isikukood': 'Estonian ID number required for many services',
        'e_residency': 'Available for non-residents; helps with digital services',
        'language': 'Estonian required in contracts; Russian widely understood',
        'scam_warning': 'Verify companies at rik.ee/en/e-business-register',
        'rental': 'Tagatisraha typically 1-2 months',
      },
    };
  }

  static Map<String, dynamic> _portugal() {
    return {
      'country': 'Portugal',
      'authority': 'Direção-Geral do Consumidor (DGC)',
      'authority_website': 'consumidor.pt',
      'returns_policy': {
        'standard_return_days': 14,
        'online_shopping': '14 days direito de livre resolução',
        'in_store': 'Voluntary',
      },
      'warranty': {
        'minimum_years': 3,
        'note': 'Portugal extended to 3 years',
        'reverse_burden': '2 years',
      },
      'flight_rights': {
        'regulation': 'EU 261/2004',
        'enforcement_body': 'Autoridade Nacional de Aviação Civil (ANAC)',
        'time_limit': '3 years',
        'compensation_amounts': {
          'under_1500km': 250,
          '1500_3500km': 400,
          'over_3500km': 600,
        },
      },
      'alternative_dispute': {
        'body': 'CIMAAL and sector-specific centers',
        'website': 'consumidor.pt',
        'cost': 'Free',
      },
    };
  }

  static Map<String, dynamic> _greece() {
    return {
      'country': 'Greece',
      'authority': 'Γενική Γραμματεία Εμπορίου (General Secretariat of Commerce)',
      'authority_website': 'efpolis.gr',
      'returns_policy': {
        'standard_return_days': 14,
        'online_shopping': '14 days δικαίωμα υπαναχώρησης',
        'in_store': 'Voluntary',
      },
      'warranty': {
        'minimum_years': 2,
        'reverse_burden': '6 months',
      },
      'flight_rights': {
        'regulation': 'EU 261/2004',
        'enforcement_body': 'Υπηρεσία Πολιτικής Αεροπορίας (YPA)',
        'time_limit': '2 years',
        'compensation_amounts': {
          'under_1500km': 250,
          '1500_3500km': 400,
          'over_3500km': 600,
        },
      },
      'alternative_dispute': {
        'body': 'Συνήγορος του Καταναλωτή (Consumer Advocate)',
        'website': 'synigoroskatanaloti.gr',
        'cost': 'Free',
      },
    };
  }

  static Map<String, dynamic> _ireland() {
    return {
      'country': 'Ireland',
      'authority': 'Competition and Consumer Protection Commission (CCPC)',
      'authority_website': 'ccpc.ie',
      'returns_policy': {
        'standard_return_days': 14,
        'online_shopping': '14 days cooling-off period',
        'in_store': 'Faulty goods only (unless shop offers returns)',
        'note': 'Rights for faulty goods apply even after return period',
      },
      'warranty': {
        'minimum_years': 6,
        'note': 'Ireland: up to 6 years under Statute of Limitations (significantly above EU minimum)',
        'reverse_burden': '6 months',
        'your_rights': ['Repair', 'Replacement', 'Refund'],
      },
      'flight_rights': {
        'regulation': 'EU 261/2004',
        'enforcement_body': 'Commission for Aviation Regulation (CAR)',
        'time_limit': '6 years',
        'compensation_amounts': {
          'under_1500km': 250,
          '1500_3500km': 400,
          'over_3500km': 600,
        },
      },
      'alternative_dispute': {
        'body': 'Small Claims Court (up to EUR 2,000)',
        'website': 'courts.ie',
        'fee': 'EUR 25',
        'binding': 'Yes',
      },
      'immigrant_specific': {
        'PPS_number': 'Required for financial services',
        'language': 'English/Irish; interpreter rights',
        'rental': '1 month deposit; protected by Residential Tenancies Board (RTB)',
      },
    };
  }

  static Map<String, dynamic> _luxembourg() {
    return {
      'country': 'Luxembourg',
      'authority': 'Union Luxembourgeoise des Consommateurs (ULC)',
      'authority_website': 'ulc.lu',
      'returns_policy': {
        'standard_return_days': 14,
        'online_shopping': '14 days droit de rétractation',
        'in_store': 'Voluntary',
      },
      'warranty': {
        'minimum_years': 2,
        'reverse_burden': '1 year',
      },
      'flight_rights': {
        'regulation': 'EU 261/2004',
        'enforcement_body': 'Direction de l\'Aviation Civile (DAC)',
        'time_limit': '3 years',
        'compensation_amounts': {
          'under_1500km': 250,
          '1500_3500km': 400,
          'over_3500km': 600,
        },
      },
      'alternative_dispute': {
        'body': 'Centre de Médiation de la Consommation',
        'cost': 'Free',
      },
    };
  }

  static Map<String, dynamic> _malta() {
    return {
      'country': 'Malta',
      'authority': 'Malta Competition and Consumer Affairs Authority (MCCAA)',
      'authority_website': 'mccaa.org.mt',
      'returns_policy': {
        'standard_return_days': 14,
        'online_shopping': '14 days cooling-off',
        'in_store': 'Faulty goods only',
      },
      'warranty': {
        'minimum_years': 2,
        'reverse_burden': '6 months',
      },
      'flight_rights': {
        'regulation': 'EU 261/2004',
        'enforcement_body': 'Civil Aviation Directorate (Transport Malta)',
        'time_limit': '2 years',
        'compensation_amounts': {
          'under_1500km': 250,
          '1500_3500km': 400,
          'over_3500km': 600,
        },
      },
      'alternative_dispute': {
        'body': 'Consumer Claims Tribunal',
        'cost': 'Small fee',
        'binding': 'Yes',
      },
    };
  }

  // === UTILITY METHODS ===

  static Map<String, dynamic>? getCountry(String countryCode) {
    return getAllCountries()[countryCode.toUpperCase()];
  }

  static List<String> getCountriesWithExtendedWarranty() {
    final countries = getAllCountries();
    return countries.entries
        .where((e) {
          final years = e.value['warranty']?['minimum_years'];
          return years != null && years > 2;
        })
        .map((e) => e.key)
        .toList();
  }

  static Map<String, int> getFlightCompensation(String countryCode, int distanceKm) {
    final country = getCountry(countryCode);
    if (country == null) return {};
    final amounts = country['flight_rights']?['compensation_amounts'] as Map<String, dynamic>?;
    if (amounts == null) return {};

    int compensation = 0;
    if (distanceKm < 1500) {
      compensation = amounts['under_1500km'] ?? 250;
    } else if (distanceKm <= 3500) {
      compensation = amounts['1500_3500km'] ?? 400;
    } else {
      compensation = amounts['over_3500km'] ?? 600;
    }

    return {
      'amount_eur': compensation,
      'distance_km': distanceKm,
    };
  }

  static List<Map<String, dynamic>> searchAllCountries(String topic) {
    final results = <Map<String, dynamic>>[];
    final allCountries = getAllCountries();

    for (final entry in allCountries.entries) {
      final country = entry.value;
      final countryStr = country.toString().toLowerCase();
      if (countryStr.contains(topic.toLowerCase())) {
        results.add({
          'country_code': entry.key,
          'country_name': country['country'],
          'data': country,
        });
      }
    }

    return results;
  }

  static String getReturnPolicy(String countryCode) {
    final country = getCountry(countryCode);
    if (country == null) return 'Country not found';
    final returns = country['returns_policy'] as Map<String, dynamic>?;
    if (returns == null) return 'No data available';

    final days = returns['standard_return_days'] ?? 14;
    final online = returns['online_shopping'] ?? '';
    return '$days days online return right. $online';
  }

  static Map<String, dynamic> getWarrantyInfo(String countryCode) {
    final country = getCountry(countryCode);
    if (country == null) return {'error': 'Country not found'};
    return Map<String, dynamic>.from(country['warranty'] ?? {});
  }

  static Map<String, dynamic> getDisputeResolution(String countryCode) {
    final country = getCountry(countryCode);
    if (country == null) return {'error': 'Country not found'};
    return Map<String, dynamic>.from(country['alternative_dispute'] ?? {});
  }
}
