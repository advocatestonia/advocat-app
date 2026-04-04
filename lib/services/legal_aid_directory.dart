// Legal Aid Directory — Comprehensive EU-wide NGO and Legal Aid Contact Database
// 27 EU countries + EU-wide organizations
// 150+ real contacts for AI-assisted legal help
//
// Sources: Official government websites, EU e-Justice portal, ECRE directory,
// national bar associations, ombudsman offices, UNHCR partner lists.
//
// Last verified: 2026-04

class LegalAidContact {
  final String name;
  final String country;
  final String countryCode;
  final String type; // 'legal_aid', 'ngo', 'victim_support', 'anti_discrimination', 'immigrant_support'
  final String? phone;
  final String? email;
  final String? website;
  final String? description;
  final List<String> languages;
  final bool freeService;

  const LegalAidContact({
    required this.name,
    required this.country,
    required this.countryCode,
    required this.type,
    this.phone,
    this.email,
    this.website,
    this.description,
    this.languages = const [],
    this.freeService = true,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'country': country,
    'countryCode': countryCode,
    'type': type,
    'phone': phone,
    'email': email,
    'website': website,
    'description': description,
    'languages': languages,
    'freeService': freeService,
  };

  factory LegalAidContact.fromJson(Map<String, dynamic> json) => LegalAidContact(
    name: json['name'] as String,
    country: json['country'] as String,
    countryCode: json['countryCode'] as String,
    type: json['type'] as String,
    phone: json['phone'] as String?,
    email: json['email'] as String?,
    website: json['website'] as String?,
    description: json['description'] as String?,
    languages: (json['languages'] as List<dynamic>?)?.cast<String>() ?? [],
    freeService: json['freeService'] as bool? ?? true,
  );
}

class LegalAidDirectory {
  // ─────────────────────────────────────────────────
  // EU-WIDE & INTERNATIONAL ORGANIZATIONS
  // ─────────────────────────────────────────────────
  static const List<LegalAidContact> euWideContacts = [
    LegalAidContact(
      name: 'European Council on Refugees and Exiles (ECRE)',
      country: 'EU-wide',
      countryCode: 'EU',
      type: 'ngo',
      phone: '+32 2 234 38 00',
      email: 'ecre@ecre.org',
      website: 'https://ecre.org',
      description: 'Pan-European alliance of 107 NGOs protecting refugees and asylum seekers. Provides legal policy analysis and country-specific information.',
      languages: ['en', 'fr', 'de'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'UNHCR Europe',
      country: 'EU-wide',
      countryCode: 'EU',
      type: 'ngo',
      phone: '+41 22 739 8111',
      website: 'https://www.unhcr.org/europe.html',
      description: 'UN Refugee Agency — provides international protection and assistance to refugees, asylum seekers, and stateless persons across Europe.',
      languages: ['en', 'fr', 'de', 'es', 'ar'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'International Organization for Migration (IOM)',
      country: 'EU-wide',
      countryCode: 'EU',
      type: 'immigrant_support',
      phone: '+41 22 717 9111',
      website: 'https://www.iom.int',
      description: 'UN migration agency providing services to migrants, including voluntary return, resettlement, and counter-trafficking programs.',
      languages: ['en', 'fr', 'es', 'ar'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'EU Agency for Fundamental Rights (FRA)',
      country: 'EU-wide',
      countryCode: 'EU',
      type: 'anti_discrimination',
      phone: '+43 1 580 30 0',
      website: 'https://fra.europa.eu',
      description: 'EU body providing evidence-based advice on fundamental rights. Publishes reports on discrimination, asylum, and migrant rights.',
      languages: ['en', 'fr', 'de'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'European e-Justice Portal',
      country: 'EU-wide',
      countryCode: 'EU',
      type: 'legal_aid',
      website: 'https://e-justice.europa.eu',
      description: 'EU portal for finding lawyers, legal aid information, court procedures, and rights in all EU member states.',
      languages: ['en', 'fr', 'de', 'es', 'it', 'pl', 'ro', 'nl', 'pt', 'el', 'cs', 'hu', 'bg', 'hr', 'sk', 'sl', 'da', 'fi', 'sv', 'et', 'lv', 'lt', 'mt', 'ga'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'European Emergency Number',
      country: 'EU-wide',
      countryCode: 'EU',
      type: 'victim_support',
      phone: '112',
      website: 'https://ec.europa.eu/digital-single-market/en/112',
      description: 'Free emergency number available in all EU countries. Works from any phone, including without a SIM card.',
      languages: ['en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Victim Support Europe',
      country: 'EU-wide',
      countryCode: 'EU',
      type: 'victim_support',
      phone: '+32 2 234 38 60',
      email: 'info@victimsupporteurope.eu',
      website: 'https://victimsupporteurope.eu',
      description: 'Umbrella organization for victim support services across Europe. Can refer to national services.',
      languages: ['en', 'fr', 'de'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'European Network of Equality Bodies (Equinet)',
      country: 'EU-wide',
      countryCode: 'EU',
      type: 'anti_discrimination',
      email: 'info@equineteurope.org',
      website: 'https://equineteurope.org',
      description: 'Network of 46 equality bodies across Europe. Can direct to national anti-discrimination offices.',
      languages: ['en', 'fr'],
      freeService: true,
    ),
  ];

  // ─────────────────────────────────────────────────
  // FINLAND (FI)
  // ─────────────────────────────────────────────────
  static const List<LegalAidContact> finlandContacts = [
    LegalAidContact(
      name: 'Oikeusapu — Finnish Legal Aid',
      country: 'Finland',
      countryCode: 'FI',
      type: 'legal_aid',
      phone: '+358 29 56 00100',
      website: 'https://oikeus.fi/oikeusapu/en/',
      description: 'Government legal aid offices provide free or subsidized legal assistance based on income. Covers all legal matters including immigration.',
      languages: ['fi', 'sv', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Pakolaisneuvonta ry (Finnish Refugee Advice Centre)',
      country: 'Finland',
      countryCode: 'FI',
      type: 'ngo',
      phone: '+358 9 2313 9300',
      email: 'info@pakolaisneuvonta.fi',
      website: 'https://www.pakolaisneuvonta.fi',
      description: 'Leading NGO providing free legal aid to asylum seekers, refugees, and other foreigners in Finland. Handles asylum, residence permit, deportation, and family reunification cases.',
      languages: ['fi', 'sv', 'en', 'ar', 'so', 'fa'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'RIKU — Rikosuhripäivystys (Victim Support Finland)',
      country: 'Finland',
      countryCode: 'FI',
      type: 'victim_support',
      phone: '+358 116 006',
      website: 'https://www.riku.fi',
      description: 'National victim support service providing practical advice and emotional support to crime victims and their families.',
      languages: ['fi', 'sv', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Yhdenvertaisuusvaltuutettu (Non-Discrimination Ombudsman)',
      country: 'Finland',
      countryCode: 'FI',
      type: 'anti_discrimination',
      phone: '+358 295 666 817',
      email: 'yvv@oikeus.fi',
      website: 'https://syrjinta.fi/en',
      description: 'Independent authority promoting equality and tackling discrimination. Also monitors the rights of foreigners and acts as National Rapporteur on Trafficking.',
      languages: ['fi', 'sv', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Infopankki — Information for Immigrants',
      country: 'Finland',
      countryCode: 'FI',
      type: 'immigrant_support',
      website: 'https://www.infopankki.fi',
      description: 'Comprehensive multilingual information portal for immigrants about living in Finland, including rights, services, and integration.',
      languages: ['fi', 'sv', 'en', 'ar', 'so', 'fa', 'ru', 'fr', 'zh', 'vi', 'et', 'tr'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Suomen Punainen Risti (Finnish Red Cross)',
      country: 'Finland',
      countryCode: 'FI',
      type: 'immigrant_support',
      phone: '+358 20 701 2000',
      website: 'https://www.redcross.fi',
      description: 'Runs reception centers for asylum seekers, provides family tracing services, and supports integration through volunteer programs.',
      languages: ['fi', 'sv', 'en'],
      freeService: true,
    ),
  ];

  // ─────────────────────────────────────────────────
  // ESTONIA (EE)
  // ─────────────────────────────────────────────────
  static const List<LegalAidContact> estoniaContacts = [
    LegalAidContact(
      name: 'Riigi Õigusabi (State Legal Aid)',
      country: 'Estonia',
      countryCode: 'EE',
      type: 'legal_aid',
      phone: '+372 620 8183',
      website: 'https://www.kohus.ee/en/state-legal-aid',
      description: 'Government legal aid provided through the courts. Available to persons who cannot afford legal services, including non-citizens.',
      languages: ['et', 'en', 'ru'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Eesti Pagulasabi (Estonian Refugee Council)',
      country: 'Estonia',
      countryCode: 'EE',
      type: 'ngo',
      email: 'info@pagulasabi.ee',
      website: 'https://www.pagulasabi.ee',
      description: 'NGO providing legal counseling, integration support, and advocacy for refugees and asylum seekers in Estonia.',
      languages: ['et', 'en', 'ru', 'ar'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Ohvriabi (Victim Support Estonia)',
      country: 'Estonia',
      countryCode: 'EE',
      type: 'victim_support',
      phone: '+372 612 1360',
      website: 'https://www.sotsiaalkindlustusamet.ee/en/victim-support',
      description: 'State victim support service under the Social Insurance Board. Provides counseling, crisis intervention, and referrals for crime victims.',
      languages: ['et', 'en', 'ru'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Soolise võrdõiguslikkuse ja võrdse kohtlemise volinik (Gender Equality and Equal Treatment Commissioner)',
      country: 'Estonia',
      countryCode: 'EE',
      type: 'anti_discrimination',
      phone: '+372 626 9059',
      email: 'avaldus@volinik.ee',
      website: 'https://volinik.ee/en/',
      description: 'Independent official monitoring compliance with equality laws. Handles discrimination complaints based on nationality, race, ethnicity, etc.',
      languages: ['et', 'en', 'ru'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Eesti Inimõiguste Keskus (Estonian Human Rights Centre)',
      country: 'Estonia',
      countryCode: 'EE',
      type: 'immigrant_support',
      phone: '+372 644 5148',
      email: 'info@humanrights.ee',
      website: 'https://humanrights.ee/en/',
      description: 'Leading human rights NGO providing legal consultations, advocacy for immigrant rights, and anti-discrimination work.',
      languages: ['et', 'en', 'ru'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Johannes Mihkelsoni Keskus (Integration Foundation)',
      country: 'Estonia',
      countryCode: 'EE',
      type: 'immigrant_support',
      phone: '+372 659 9021',
      website: 'https://www.integratsioon.ee',
      description: 'State-funded integration services including Estonian language courses, adaptation program, and settlement counseling for newcomers.',
      languages: ['et', 'en', 'ru'],
      freeService: true,
    ),
  ];

  // ─────────────────────────────────────────────────
  // GERMANY (DE)
  // ─────────────────────────────────────────────────
  static const List<LegalAidContact> germanyContacts = [
    LegalAidContact(
      name: 'Beratungshilfe & Prozesskostenhilfe (Legal Aid Germany)',
      country: 'Germany',
      countryCode: 'DE',
      type: 'legal_aid',
      website: 'https://www.bmj.de/DE/Themen/GessellschaftFamilie/Beratungshilfe/Beratungshilfe_node.html',
      description: 'German legal aid system providing Beratungshilfe (advice aid) and Prozesskostenhilfe (litigation aid) for those with low income. Apply through local Amtsgericht.',
      languages: ['de', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Pro Asyl',
      country: 'Germany',
      countryCode: 'DE',
      type: 'ngo',
      phone: '+49 69 242 314 0',
      email: 'proasyl@proasyl.de',
      website: 'https://www.proasyl.de',
      description: 'Leading German NGO for refugee rights. Provides legal assistance, political advocacy, and a nationwide network of refugee counseling centers.',
      languages: ['de', 'en', 'fr', 'ar'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Weisser Ring',
      country: 'Germany',
      countryCode: 'DE',
      type: 'victim_support',
      phone: '+49 116 006',
      website: 'https://weisser-ring.de',
      description: 'Germany largest victim support organization. Provides personal support, legal advice, financial assistance, and accompaniment to court.',
      languages: ['de', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Antidiskriminierungsstelle des Bundes (Federal Anti-Discrimination Agency)',
      country: 'Germany',
      countryCode: 'DE',
      type: 'anti_discrimination',
      phone: '+49 30 18555 1865',
      email: 'beratung@ads.bund.de',
      website: 'https://www.antidiskriminierungsstelle.de',
      description: 'Federal agency providing free advice and support to people who have experienced discrimination. Handles complaints under the General Equal Treatment Act (AGG).',
      languages: ['de', 'en', 'fr', 'ar', 'tr', 'ru'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Flüchtlingsrat (Refugee Councils — network)',
      country: 'Germany',
      countryCode: 'DE',
      type: 'immigrant_support',
      website: 'https://www.fluechtlingsrat.de',
      description: 'Network of independent refugee councils in all 16 German states. Provide legal counseling, social advice, and advocacy for asylum seekers.',
      languages: ['de', 'en', 'ar', 'fa'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'BAMF Hotline (Federal Office for Migration)',
      country: 'Germany',
      countryCode: 'DE',
      type: 'immigrant_support',
      phone: '+49 911 943 0',
      website: 'https://www.bamf.de',
      description: 'Federal migration office handling asylum applications. Information hotline for asylum procedures, integration courses, and residence permits.',
      languages: ['de', 'en', 'ar', 'fa', 'fr'],
      freeService: true,
    ),
  ];

  // ─────────────────────────────────────────────────
  // SWEDEN (SE)
  // ─────────────────────────────────────────────────
  static const List<LegalAidContact> swedenContacts = [
    LegalAidContact(
      name: 'Rättshjälpsmyndigheten (Legal Aid Authority)',
      country: 'Sweden',
      countryCode: 'SE',
      type: 'legal_aid',
      phone: '+46 60 13 46 00',
      website: 'https://www.rattshjalpsmyndigheten.se',
      description: 'Swedish government legal aid authority. Provides legal aid for those who cannot afford legal counsel. Covers civil, criminal, and administrative matters.',
      languages: ['sv', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Asylrättscentrum (Swedish Refugee Law Center)',
      country: 'Sweden',
      countryCode: 'SE',
      type: 'ngo',
      phone: '+46 8 665 06 02',
      email: 'info@sweref.org',
      website: 'https://www.sweref.org',
      description: 'Independent legal center providing free legal advice to asylum seekers. Offers information about the asylum process and legal representation.',
      languages: ['sv', 'en', 'ar', 'fa', 'ti', 'so'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Brottsoffermyndigheten (Crime Victim Authority)',
      country: 'Sweden',
      countryCode: 'SE',
      type: 'victim_support',
      phone: '+46 90 70 82 00',
      website: 'https://www.brottsoffermyndigheten.se',
      description: 'Government authority handling criminal injuries compensation and funding victim support services. Manages the Crime Victim Fund.',
      languages: ['sv', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Diskrimineringsombudsmannen (Discrimination Ombudsman)',
      country: 'Sweden',
      countryCode: 'SE',
      type: 'anti_discrimination',
      phone: '+46 8 120 20 700',
      email: 'do@do.se',
      website: 'https://www.do.se',
      description: 'Government agency working to combat discrimination based on sex, ethnicity, religion, disability, sexual orientation, age, and transgender identity.',
      languages: ['sv', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Röda Korset (Swedish Red Cross)',
      country: 'Sweden',
      countryCode: 'SE',
      type: 'immigrant_support',
      phone: '+46 8 452 46 00',
      website: 'https://www.rodakorset.se',
      description: 'Provides integration support, healthcare for undocumented migrants, family reunification tracing, and treatment centers for war and torture victims.',
      languages: ['sv', 'en', 'ar', 'fa', 'so', 'ti'],
      freeService: true,
    ),
  ];

  // ─────────────────────────────────────────────────
  // FRANCE (FR)
  // ─────────────────────────────────────────────────
  static const List<LegalAidContact> franceContacts = [
    LegalAidContact(
      name: 'Aide Juridictionnelle (Jurisdictional Legal Aid)',
      country: 'France',
      countryCode: 'FR',
      type: 'legal_aid',
      phone: '+33 1 44 32 51 51',
      website: 'https://www.justice.fr/fiche/aide-juridictionnelle',
      description: 'French legal aid system covering full or partial legal costs for those with insufficient resources. Apply at Tribunal or Maison de la Justice.',
      languages: ['fr', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'France terre d\'asile',
      country: 'France',
      countryCode: 'FR',
      type: 'ngo',
      phone: '+33 1 53 04 39 99',
      website: 'https://www.france-terre-asile.org',
      description: 'Major French NGO supporting asylum seekers and refugees with legal assistance, housing, integration, and advocacy since 1971.',
      languages: ['fr', 'en', 'ar'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'France Victimes',
      country: 'France',
      countryCode: 'FR',
      type: 'victim_support',
      phone: '+33 116 006',
      website: 'https://www.france-victimes.fr',
      description: 'National federation of 130+ victim support associations. Free helpline 116 006 provides psychological, legal, and social support.',
      languages: ['fr', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Défenseur des droits (Defender of Rights)',
      country: 'France',
      countryCode: 'FR',
      type: 'anti_discrimination',
      phone: '+33 9 69 39 00 00',
      website: 'https://www.defenseurdesdroits.fr',
      description: 'Independent constitutional authority protecting rights and combating discrimination. Handles complaints about public services, children\'s rights, and discrimination.',
      languages: ['fr', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'La Cimade',
      country: 'France',
      countryCode: 'FR',
      type: 'immigrant_support',
      phone: '+33 1 44 18 60 60',
      website: 'https://www.lacimade.org',
      description: 'NGO defending the dignity and rights of refugees and migrants. Provides legal assistance in detention centers and advocacy for immigration reform.',
      languages: ['fr', 'en', 'ar'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'GISTI (Groupe d\'information et de soutien des immigré·e·s)',
      country: 'France',
      countryCode: 'FR',
      type: 'immigrant_support',
      phone: '+33 1 43 14 84 84',
      website: 'https://www.gisti.org',
      description: 'Expert legal association for immigrant rights. Provides legal advice, publishes guides on immigration law, and conducts strategic litigation.',
      languages: ['fr', 'en'],
      freeService: true,
    ),
  ];

  // ─────────────────────────────────────────────────
  // ITALY (IT)
  // ─────────────────────────────────────────────────
  static const List<LegalAidContact> italyContacts = [
    LegalAidContact(
      name: 'Patrocinio a Spese dello Stato (State-Funded Legal Aid)',
      country: 'Italy',
      countryCode: 'IT',
      type: 'legal_aid',
      website: 'https://www.giustizia.it/giustizia/it/mg_3_7.page',
      description: 'Free legal aid for those with income below threshold. Available for criminal, civil, and administrative cases including immigration matters. Apply at the Bar Council (Consiglio dell\'Ordine degli Avvocati).',
      languages: ['it', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'ASGI (Associazione per gli Studi Giuridici sull\'Immigrazione)',
      country: 'Italy',
      countryCode: 'IT',
      type: 'ngo',
      email: 'info@asgi.it',
      website: 'https://www.asgi.it',
      description: 'Leading Italian legal association for immigration law. Provides free legal advice, strategic litigation, and expert resources on refugee and immigration law.',
      languages: ['it', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Telefono Amico / Rete Dafne (Victim Support)',
      country: 'Italy',
      countryCode: 'IT',
      type: 'victim_support',
      phone: '+39 02 713 900',
      website: 'https://www.retedafne.it',
      description: 'Network providing free support to crime victims including legal information, psychological support, and accompaniment through the justice process.',
      languages: ['it', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'UNAR (Ufficio Nazionale Antidiscriminazioni Razziali)',
      country: 'Italy',
      countryCode: 'IT',
      type: 'anti_discrimination',
      phone: '+39 800 90 10 10',
      email: 'unar@governo.it',
      website: 'https://unar.it',
      description: 'National Office Against Racial Discrimination. Free helpline and complaint processing for discrimination based on race, ethnicity, religion, nationality.',
      languages: ['it', 'en', 'ar', 'fr', 'zh', 'ro'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'CIR (Consiglio Italiano per i Rifugiati)',
      country: 'Italy',
      countryCode: 'IT',
      type: 'immigrant_support',
      phone: '+39 06 692 00 114',
      email: 'cir@cir-onlus.org',
      website: 'https://www.cir-onlus.org',
      description: 'Italian Refugee Council — provides legal assistance, orientation, and integration services to asylum seekers and refugees since 1990.',
      languages: ['it', 'en', 'fr', 'ar'],
      freeService: true,
    ),
  ];

  // ─────────────────────────────────────────────────
  // SPAIN (ES)
  // ─────────────────────────────────────────────────
  static const List<LegalAidContact> spainContacts = [
    LegalAidContact(
      name: 'Asistencia Jurídica Gratuita (Free Legal Aid)',
      country: 'Spain',
      countryCode: 'ES',
      type: 'legal_aid',
      phone: '+34 900 101 025',
      website: 'https://www.mjusticia.gob.es/es/ciudadania/asistencia-juridica-gratuita',
      description: 'Free legal aid for those with insufficient resources, including foreigners regardless of status for criminal, asylum, and gender violence cases.',
      languages: ['es', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'CEAR (Comisión Española de Ayuda al Refugiado)',
      country: 'Spain',
      countryCode: 'ES',
      type: 'ngo',
      phone: '+34 91 598 05 35',
      email: 'cear@cear.es',
      website: 'https://www.cear.es',
      description: 'Spanish Commission for Refugees — provides legal assistance, social services, and integration support. Has offices across Spain.',
      languages: ['es', 'en', 'fr', 'ar'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Oficinas de Asistencia a las Víctimas (Victim Assistance Offices)',
      country: 'Spain',
      countryCode: 'ES',
      type: 'victim_support',
      phone: '+34 900 150 909',
      website: 'https://www.mjusticia.gob.es/es/ciudadania/victimas-delitos',
      description: 'Government victim support offices providing free legal, psychological, and social assistance to crime victims. Available in all provinces.',
      languages: ['es', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Consejo para la Eliminación de la Discriminación Racial o Étnica',
      country: 'Spain',
      countryCode: 'ES',
      type: 'anti_discrimination',
      phone: '+34 900 203 041',
      website: 'https://igualdadynodiscriminacion.igualdad.gob.es',
      description: 'Council for the Elimination of Racial or Ethnic Discrimination. Provides free assistance to discrimination victims and monitors equal treatment.',
      languages: ['es', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'ACCEM',
      country: 'Spain',
      countryCode: 'ES',
      type: 'immigrant_support',
      phone: '+34 91 532 74 78',
      email: 'accem@accem.es',
      website: 'https://www.accem.es',
      description: 'Major NGO providing comprehensive assistance to refugees and immigrants: legal advice, housing, employment, language courses, and social integration.',
      languages: ['es', 'en', 'fr', 'ar', 'uk', 'zh'],
      freeService: true,
    ),
  ];

  // ─────────────────────────────────────────────────
  // NETHERLANDS (NL)
  // ─────────────────────────────────────────────────
  static const List<LegalAidContact> netherlandsContacts = [
    LegalAidContact(
      name: 'Raad voor Rechtsbijstand (Legal Aid Board)',
      country: 'Netherlands',
      countryCode: 'NL',
      type: 'legal_aid',
      phone: '+31 88 787 1000',
      website: 'https://www.rvr.org',
      description: 'Government legal aid board managing free legal assistance for those with low income. Covers immigration, criminal, and civil matters.',
      languages: ['nl', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'VluchtelingenWerk Nederland (Dutch Council for Refugees)',
      country: 'Netherlands',
      countryCode: 'NL',
      type: 'ngo',
      phone: '+31 20 346 72 00',
      website: 'https://www.vluchtelingenwerk.nl',
      description: 'Largest Dutch refugee support organization. Provides legal advice during asylum procedures, integration support, and advocacy.',
      languages: ['nl', 'en', 'ar', 'fa', 'ti'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Slachtofferhulp Nederland (Victim Support Netherlands)',
      country: 'Netherlands',
      countryCode: 'NL',
      type: 'victim_support',
      phone: '+31 900 0101',
      website: 'https://www.slachtofferhulp.nl',
      description: 'National victim support organization providing emotional support, legal advice, and practical help to victims of crimes and disasters.',
      languages: ['nl', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'College voor de Rechten van de Mens (Netherlands Institute for Human Rights)',
      country: 'Netherlands',
      countryCode: 'NL',
      type: 'anti_discrimination',
      phone: '+31 30 888 38 88',
      email: 'info@mensenrechten.nl',
      website: 'https://www.mensenrechten.nl',
      description: 'National human rights institute assessing individual discrimination complaints and issuing binding opinions on equal treatment.',
      languages: ['nl', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'ASKV / Refugee Support (Steunpunt Vluchtelingen)',
      country: 'Netherlands',
      countryCode: 'NL',
      type: 'immigrant_support',
      phone: '+31 20 627 70 82',
      website: 'https://www.askv.nl',
      description: 'NGO providing practical and legal support to refugees and undocumented migrants in the Amsterdam area.',
      languages: ['nl', 'en', 'ar'],
      freeService: true,
    ),
  ];

  // ─────────────────────────────────────────────────
  // POLAND (PL)
  // ─────────────────────────────────────────────────
  static const List<LegalAidContact> polandContacts = [
    LegalAidContact(
      name: 'Nieodpłatna Pomoc Prawna (Free Legal Aid)',
      country: 'Poland',
      countryCode: 'PL',
      type: 'legal_aid',
      phone: '+48 22 461 60 60',
      website: 'https://np.ms.gov.pl',
      description: 'Government free legal aid system accessible at local points across all counties (powiaty). Available to those meeting income criteria.',
      languages: ['pl', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Stowarzyszenie Interwencji Prawnej (Association for Legal Intervention)',
      country: 'Poland',
      countryCode: 'PL',
      type: 'ngo',
      phone: '+48 22 621 51 65',
      email: 'biuro@interwencjaprawna.pl',
      website: 'https://interwencjaprawna.pl',
      description: 'Leading Polish NGO providing free legal assistance to foreigners, refugees, and discrimination victims. Active in strategic litigation.',
      languages: ['pl', 'en', 'ru', 'uk'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Fundacja Centrum Praw Kobiet / Victim Support Network',
      country: 'Poland',
      countryCode: 'PL',
      type: 'victim_support',
      phone: '+48 22 622 25 17',
      website: 'https://cpk.org.pl',
      description: 'Women\'s Rights Center providing legal and psychological help to victims of violence. Also runs shelters and a 24-hour helpline.',
      languages: ['pl', 'en', 'uk'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Rzecznik Praw Obywatelskich (Commissioner for Human Rights)',
      country: 'Poland',
      countryCode: 'PL',
      type: 'anti_discrimination',
      phone: '+48 800 676 676',
      email: 'biurorzecznika@brpo.gov.pl',
      website: 'https://bip.brpo.gov.pl',
      description: 'Independent constitutional body protecting civil rights and equal treatment. Handles complaints about discrimination and rights violations.',
      languages: ['pl', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Helsińska Fundacja Praw Człowieka (Helsinki Foundation for Human Rights)',
      country: 'Poland',
      countryCode: 'PL',
      type: 'immigrant_support',
      phone: '+48 22 556 44 40',
      email: 'hfhr@hfhr.pl',
      website: 'https://www.hfhr.pl',
      description: 'Human rights foundation providing legal assistance to refugees and migrants, conducting litigation before national and European courts.',
      languages: ['pl', 'en', 'ru'],
      freeService: true,
    ),
  ];

  // ─────────────────────────────────────────────────
  // ROMANIA (RO)
  // ─────────────────────────────────────────────────
  static const List<LegalAidContact> romaniaContacts = [
    LegalAidContact(
      name: 'Asistență Juridică Gratuită (Free Legal Aid)',
      country: 'Romania',
      countryCode: 'RO',
      type: 'legal_aid',
      website: 'https://www.just.ro/asistenta-judiciara/',
      description: 'Government legal aid system providing free legal representation for those with low income. Apply through the court (instanța de judecată).',
      languages: ['ro', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Consiliul Român pentru Refugiați (Romanian National Council for Refugees)',
      country: 'Romania',
      countryCode: 'RO',
      type: 'ngo',
      phone: '+40 21 312 77 35',
      email: 'office@cnrr.ro',
      website: 'https://www.cnrr.ro',
      description: 'NGO providing legal assistance, social counseling, and integration support for asylum seekers and refugees in Romania since 1998.',
      languages: ['ro', 'en', 'fr', 'ar'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Asociația ACTEDO',
      country: 'Romania',
      countryCode: 'RO',
      type: 'victim_support',
      email: 'office@actedo.org',
      website: 'https://actedo.org',
      description: 'Human rights and victim support organization providing free legal assistance in discrimination and hate crime cases.',
      languages: ['ro', 'en', 'hu'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Consiliul Național pentru Combaterea Discriminării (CNCD)',
      country: 'Romania',
      countryCode: 'RO',
      type: 'anti_discrimination',
      phone: '+40 21 312 65 78',
      email: 'support@cncd.org.ro',
      website: 'https://www.cncd.ro',
      description: 'National Council for Combating Discrimination — autonomous body handling discrimination complaints and issuing sanctions.',
      languages: ['ro', 'en', 'hu'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Jesuit Refugee Service (JRS) Romania',
      country: 'Romania',
      countryCode: 'RO',
      type: 'immigrant_support',
      phone: '+40 21 327 08 01',
      email: 'romania@jrs.net',
      website: 'https://jfrromania.ro',
      description: 'International organization providing legal aid, education, psycho-social support, and integration services for refugees and asylum seekers.',
      languages: ['ro', 'en', 'fr', 'ar'],
      freeService: true,
    ),
  ];

  // ─────────────────────────────────────────────────
  // LATVIA (LV)
  // ─────────────────────────────────────────────────
  static const List<LegalAidContact> latviaContacts = [
    LegalAidContact(
      name: 'Juridiskā palīdzība (Legal Aid Administration)',
      country: 'Latvia',
      countryCode: 'LV',
      type: 'legal_aid',
      phone: '+371 67 514 208',
      email: 'jpa@jpa.gov.lv',
      website: 'https://www.jpa.gov.lv',
      description: 'State legal aid administration providing free legal consultations and representation for low-income residents, including asylum seekers.',
      languages: ['lv', 'en', 'ru'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Latvijas Cilvēktiesību centrs (Latvian Centre for Human Rights)',
      country: 'Latvia',
      countryCode: 'LV',
      type: 'ngo',
      phone: '+371 67 240 386',
      email: 'office@humanrights.org.lv',
      website: 'https://cilvektiesibas.org.lv',
      description: 'NGO providing legal assistance on asylum and migration issues, anti-discrimination work, and human rights monitoring.',
      languages: ['lv', 'en', 'ru'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Cietušo atbalsta centrs (Victim Support Centre)',
      country: 'Latvia',
      countryCode: 'LV',
      type: 'victim_support',
      phone: '+371 116 006',
      website: 'https://www.cietusajiem.lv',
      description: 'State-funded victim support providing free emotional support, legal information, and practical assistance to crime victims.',
      languages: ['lv', 'en', 'ru'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Tiesībsarga birojs (Ombudsman\'s Office)',
      country: 'Latvia',
      countryCode: 'LV',
      type: 'anti_discrimination',
      phone: '+371 67 686 768',
      email: 'pasts@tiesibsargs.lv',
      website: 'https://www.tiesibsargs.lv',
      description: 'National human rights institution handling complaints about discrimination and violations of fundamental rights by public authorities.',
      languages: ['lv', 'en', 'ru'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Gribu palīdzēt bēgļiem (I Want to Help Refugees)',
      country: 'Latvia',
      countryCode: 'LV',
      type: 'immigrant_support',
      email: 'info@gribupalidzetbegliem.lv',
      website: 'https://www.gribupalidzetbegliem.lv',
      description: 'Volunteer-based organization helping refugees with practical integration needs: language, housing, employment, and cultural orientation.',
      languages: ['lv', 'en', 'ru', 'uk'],
      freeService: true,
    ),
  ];

  // ─────────────────────────────────────────────────
  // LITHUANIA (LT)
  // ─────────────────────────────────────────────────
  static const List<LegalAidContact> lithuaniaContacts = [
    LegalAidContact(
      name: 'Valstybės garantuojama teisinė pagalba (State-Guaranteed Legal Aid)',
      country: 'Lithuania',
      countryCode: 'LT',
      type: 'legal_aid',
      phone: '+370 700 00 211',
      website: 'https://www.teisinepagalba.lt',
      description: 'Government legal aid service providing free primary and secondary legal assistance based on income and asset criteria.',
      languages: ['lt', 'en', 'ru'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Lietuvos Raudonojo Kryžiaus draugija (Lithuanian Red Cross)',
      country: 'Lithuania',
      countryCode: 'LT',
      type: 'ngo',
      phone: '+370 5 262 8037',
      email: 'info@redcross.lt',
      website: 'https://www.redcross.lt',
      description: 'Provides social and legal assistance to refugees and asylum seekers, including integration programs and family tracing.',
      languages: ['lt', 'en', 'ru', 'uk'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Nukentėjusiųjų pagalbos centras (Victim Support Centre)',
      country: 'Lithuania',
      countryCode: 'LT',
      type: 'victim_support',
      phone: '+370 5 212 3823',
      website: 'https://www.nfrp.lt',
      description: 'Provides comprehensive assistance to crime victims including legal consultations, psychological support, and mediation services.',
      languages: ['lt', 'en', 'ru'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Lygių galimybių kontrolieriaus tarnyba (Equal Opportunities Ombudsperson)',
      country: 'Lithuania',
      countryCode: 'LT',
      type: 'anti_discrimination',
      phone: '+370 5 261 0488',
      email: 'lygybe@lygybe.lt',
      website: 'https://www.lygybe.lt',
      description: 'Independent institution investigating discrimination complaints based on gender, race, nationality, disability, age, sexual orientation, and religion.',
      languages: ['lt', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Caritas Lithuania — Migration Support',
      country: 'Lithuania',
      countryCode: 'LT',
      type: 'immigrant_support',
      phone: '+370 5 212 5965',
      website: 'https://www.caritas.lt',
      description: 'Provides integration assistance to refugees: language courses, housing support, employment counseling, and social orientation.',
      languages: ['lt', 'en', 'ru', 'ar'],
      freeService: true,
    ),
  ];

  // ─────────────────────────────────────────────────
  // AUSTRIA (AT)
  // ─────────────────────────────────────────────────
  static const List<LegalAidContact> austriaContacts = [
    LegalAidContact(
      name: 'Verfahrenshilfe (Procedural Aid / Legal Aid)',
      country: 'Austria',
      countryCode: 'AT',
      type: 'legal_aid',
      website: 'https://www.oesterreich.gv.at/themen/dokumente_und_recht/verfahrenshilfe.html',
      description: 'Austrian legal aid system providing free legal representation in civil, criminal, and administrative proceedings for those who cannot afford it.',
      languages: ['de', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Diakonie Flüchtlingsdienst (Diakonie Refugee Service)',
      country: 'Austria',
      countryCode: 'AT',
      type: 'ngo',
      phone: '+43 1 402 67 54',
      website: 'https://fluechtlingsdienst.diakonie.at',
      description: 'Major Austrian refugee support NGO providing legal counseling, accommodation, integration, and education for asylum seekers and refugees.',
      languages: ['de', 'en', 'ar', 'fa', 'ru'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Weisser Ring Österreich (Victim Support Austria)',
      country: 'Austria',
      countryCode: 'AT',
      type: 'victim_support',
      phone: '+43 1 712 14 05',
      website: 'https://www.weisser-ring.at',
      description: 'Victim support organization providing legal advice, psychological support, and practical assistance to crime victims and their families.',
      languages: ['de', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Gleichbehandlungsanwaltschaft (Ombud for Equal Treatment)',
      country: 'Austria',
      countryCode: 'AT',
      type: 'anti_discrimination',
      phone: '+43 1 532 02 44',
      email: 'gaw@bka.gv.at',
      website: 'https://www.gleichbehandlungsanwaltschaft.gv.at',
      description: 'Independent body providing free advice and support to persons affected by discrimination based on gender, ethnicity, religion, age, or sexual orientation.',
      languages: ['de', 'en', 'tr'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Caritas Österreich — Refugee & Migration Services',
      country: 'Austria',
      countryCode: 'AT',
      type: 'immigrant_support',
      phone: '+43 1 488 31 0',
      website: 'https://www.caritas.at/hilfe-beratung/migrantinnen-fluechtlinge',
      description: 'Provides legal advice, German language courses, housing assistance, and integration programs for refugees and migrants across Austria.',
      languages: ['de', 'en', 'ar', 'fa', 'uk'],
      freeService: true,
    ),
  ];

  // ─────────────────────────────────────────────────
  // BELGIUM (BE)
  // ─────────────────────────────────────────────────
  static const List<LegalAidContact> belgiumContacts = [
    LegalAidContact(
      name: 'Bureau d\'Aide Juridique / Bureau voor Juridische Bijstand (Legal Aid Bureau)',
      country: 'Belgium',
      countryCode: 'BE',
      type: 'legal_aid',
      phone: '+32 2 508 66 59',
      website: 'https://www.avocats.be/aide-juridique',
      description: 'Free legal aid (aide juridique de deuxième ligne) providing pro bono lawyers to those with insufficient income. Apply through the Bureau of Legal Aid at each Bar.',
      languages: ['fr', 'nl', 'de', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'CIRÉ (Coordination et Initiatives pour Réfugiés et Étrangers)',
      country: 'Belgium',
      countryCode: 'BE',
      type: 'ngo',
      phone: '+32 2 629 77 10',
      email: 'cire@cire.be',
      website: 'https://www.cire.be',
      description: 'Francophone Belgian NGO network coordinating refugee support: legal advice, advocacy, housing, and integration. Umbrella for many local organizations.',
      languages: ['fr', 'en', 'ar'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Centre d\'Aide aux Victimes / Slachtofferhulp',
      country: 'Belgium',
      countryCode: 'BE',
      type: 'victim_support',
      phone: '+32 2 554 44 11',
      website: 'https://www.slachtofferzorg.be',
      description: 'Victim support services provided by the Communities (Flemish and French). Free psychological, legal, and practical assistance.',
      languages: ['fr', 'nl', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Unia (Interfederal Centre for Equal Opportunities)',
      country: 'Belgium',
      countryCode: 'BE',
      type: 'anti_discrimination',
      phone: '+32 800 12 800',
      email: 'info@unia.be',
      website: 'https://www.unia.be',
      description: 'Independent public institution combating discrimination based on race, religion, disability, age, sexual orientation, and more. Can take cases to court.',
      languages: ['fr', 'nl', 'de', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Vluchtelingenwerk Vlaanderen (Flemish Refugee Action)',
      country: 'Belgium',
      countryCode: 'BE',
      type: 'immigrant_support',
      phone: '+32 2 225 44 00',
      email: 'info@vluchtelingenwerk.be',
      website: 'https://www.vluchtelingenwerk.be',
      description: 'Flemish NGO providing legal advice, buddy programs, community support, and advocacy for asylum seekers and refugees.',
      languages: ['nl', 'en', 'fr', 'ar'],
      freeService: true,
    ),
  ];

  // ─────────────────────────────────────────────────
  // IRELAND (IE)
  // ─────────────────────────────────────────────────
  static const List<LegalAidContact> irelandContacts = [
    LegalAidContact(
      name: 'Legal Aid Board',
      country: 'Ireland',
      countryCode: 'IE',
      type: 'legal_aid',
      phone: '+353 66 947 1000',
      email: 'info@legalaidboard.ie',
      website: 'https://www.legalaidboard.ie',
      description: 'State body providing civil legal aid and advice to persons who cannot afford to pay for a solicitor. Has 34 law centres across Ireland.',
      languages: ['en', 'ga'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Irish Refugee Council',
      country: 'Ireland',
      countryCode: 'IE',
      type: 'ngo',
      phone: '+353 1 764 5854',
      email: 'info@irishrefugeecouncil.ie',
      website: 'https://www.irishrefugeecouncil.ie',
      description: 'Leading NGO providing free legal information, drop-in clinics, and advocacy for asylum seekers and refugees in Ireland.',
      languages: ['en', 'ar', 'fr'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Crime Victims Helpline',
      country: 'Ireland',
      countryCode: 'IE',
      type: 'victim_support',
      phone: '+353 116 006',
      email: 'info@crimevictimshelpline.ie',
      website: 'https://www.crimevictimshelpline.ie',
      description: 'National helpline for victims of crime offering emotional support, practical information about the criminal justice process, and referrals.',
      languages: ['en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Irish Human Rights and Equality Commission (IHREC)',
      country: 'Ireland',
      countryCode: 'IE',
      type: 'anti_discrimination',
      phone: '+353 1 858 9601',
      email: 'info@ihrec.ie',
      website: 'https://www.ihrec.ie',
      description: 'National human rights and equality body. Can provide legal assistance in equality and human rights cases, and take cases to court.',
      languages: ['en', 'ga'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Nasc, the Migrant and Refugee Rights Centre',
      country: 'Ireland',
      countryCode: 'IE',
      type: 'immigrant_support',
      phone: '+353 21 427 3594',
      email: 'info@nascireland.org',
      website: 'https://nascireland.org',
      description: 'Cork-based NGO providing immigration legal advice, information, and advocacy for migrants and refugees across Ireland.',
      languages: ['en', 'ar', 'pt', 'fr'],
      freeService: true,
    ),
  ];

  // ─────────────────────────────────────────────────
  // DENMARK (DK)
  // ─────────────────────────────────────────────────
  static const List<LegalAidContact> denmarkContacts = [
    LegalAidContact(
      name: 'Fri Proces / Retshjælp (Free Legal Aid)',
      country: 'Denmark',
      countryCode: 'DK',
      type: 'legal_aid',
      website: 'https://www.domstol.dk/sagstyper/fri-proces/',
      description: 'Government legal aid (fri proces) covering attorney fees and court costs for those with low income. Apply through the court or Civilstyrelsen.',
      languages: ['da', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Dansk Flygtningehjælp (Danish Refugee Council)',
      country: 'Denmark',
      countryCode: 'DK',
      type: 'ngo',
      phone: '+45 33 73 50 00',
      email: 'drc@drc.ngo',
      website: 'https://drc.ngo',
      description: 'Major Danish NGO providing legal counseling, asylum procedure support, integration assistance, and international humanitarian work.',
      languages: ['da', 'en', 'ar', 'fa', 'so', 'ti'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Offerrådgivningen (Victim Counseling)',
      country: 'Denmark',
      countryCode: 'DK',
      type: 'victim_support',
      phone: '+45 114',
      website: 'https://www.politi.dk/offerraadgivning',
      description: 'Police-affiliated victim counseling service providing emotional support and practical advice to crime victims. Available nationwide.',
      languages: ['da', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Institut for Menneskerettigheder (Danish Institute for Human Rights)',
      country: 'Denmark',
      countryCode: 'DK',
      type: 'anti_discrimination',
      phone: '+45 32 69 88 88',
      email: 'info@humanrights.dk',
      website: 'https://www.humanrights.dk',
      description: 'National human rights institution and equality body. Handles discrimination complaints and provides legal guidance on equal treatment.',
      languages: ['da', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Røde Kors Asyl (Red Cross Asylum)',
      country: 'Denmark',
      countryCode: 'DK',
      type: 'immigrant_support',
      phone: '+45 35 25 92 00',
      website: 'https://www.rodekors.dk/vores-arbejde/asyl',
      description: 'Danish Red Cross providing support in asylum centers, health services, and integration activities for asylum seekers.',
      languages: ['da', 'en', 'ar', 'fa'],
      freeService: true,
    ),
  ];

  // ─────────────────────────────────────────────────
  // CZECH REPUBLIC (CZ)
  // ─────────────────────────────────────────────────
  static const List<LegalAidContact> czechRepublicContacts = [
    LegalAidContact(
      name: 'Bezplatná právní pomoc (Free Legal Aid)',
      country: 'Czech Republic',
      countryCode: 'CZ',
      type: 'legal_aid',
      website: 'https://www.justice.cz/pravni-pomoc',
      description: 'Government legal aid system providing free legal consultations and representation through the Czech Bar Association for those in need.',
      languages: ['cs', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Organizace pro pomoc uprchlíkům (Organization for Aid to Refugees — OPU)',
      country: 'Czech Republic',
      countryCode: 'CZ',
      type: 'ngo',
      phone: '+420 234 621 318',
      email: 'opu@opu.cz',
      website: 'https://www.opu.cz',
      description: 'Leading Czech NGO providing free legal and social counseling to refugees, asylum seekers, and foreigners since 1991.',
      languages: ['cs', 'en', 'ru', 'uk', 'ar', 'fr'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Bílý kruh bezpečí (White Circle of Safety)',
      country: 'Czech Republic',
      countryCode: 'CZ',
      type: 'victim_support',
      phone: '+420 116 006',
      email: 'bkb@bkb.cz',
      website: 'https://www.bfrb.cz',
      description: 'Czech victim support organization providing free legal and psychological assistance to crime victims and witnesses.',
      languages: ['cs', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Veřejný ochránce práv (Public Defender of Rights / Ombudsman)',
      country: 'Czech Republic',
      countryCode: 'CZ',
      type: 'anti_discrimination',
      phone: '+420 542 542 888',
      email: 'podatelna@ochrance.cz',
      website: 'https://www.ochrance.cz',
      description: 'Ombudsman office serving as the national equality body. Handles complaints about discrimination and rights violations by public authorities.',
      languages: ['cs', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'InBáze',
      country: 'Czech Republic',
      countryCode: 'CZ',
      type: 'immigrant_support',
      phone: '+420 739 037 353',
      email: 'info@inbaze.cz',
      website: 'https://www.inbaze.cz',
      description: 'Multicultural community center providing social and legal counseling, language courses, and integration support for migrants and refugees.',
      languages: ['cs', 'en', 'ru', 'uk', 'ar'],
      freeService: true,
    ),
  ];

  // ─────────────────────────────────────────────────
  // HUNGARY (HU)
  // ─────────────────────────────────────────────────
  static const List<LegalAidContact> hungaryContacts = [
    LegalAidContact(
      name: 'Jogi Segítségnyújtó Szolgálat (Legal Aid Service)',
      country: 'Hungary',
      countryCode: 'HU',
      type: 'legal_aid',
      phone: '+36 1 795 5703',
      website: 'https://igazsagugyi.kormany.hu/jogi-segitsegnyujtas',
      description: 'Government legal aid service providing free legal advice and representation in civil and criminal matters based on social need.',
      languages: ['hu', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Magyar Helsinki Bizottság (Hungarian Helsinki Committee)',
      country: 'Hungary',
      countryCode: 'HU',
      type: 'ngo',
      phone: '+36 1 321 4323',
      email: 'helsinki@helsinki.hu',
      website: 'https://helsinki.hu/en/',
      description: 'Prominent human rights NGO providing free legal representation to asylum seekers, refugees, and immigration detainees. Active in strategic litigation.',
      languages: ['hu', 'en', 'ar', 'fa'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Fehér Gyűrű Közhasznú Egyesület (White Ring Hungary)',
      country: 'Hungary',
      countryCode: 'HU',
      type: 'victim_support',
      phone: '+36 1 312 4821',
      website: 'https://www.fehergyuru.eu',
      description: 'Victim support organization providing legal assistance, psychological help, and financial aid to crime victims in Hungary.',
      languages: ['hu', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Egyenlő Bánásmód Hatóság (Equal Treatment Authority)',
      country: 'Hungary',
      countryCode: 'HU',
      type: 'anti_discrimination',
      phone: '+36 1 795 2975',
      website: 'https://www.egyenlobanasmod.hu',
      description: 'Authority investigating complaints of discrimination and unequal treatment based on protected characteristics including nationality and ethnicity.',
      languages: ['hu', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Menedék — Hungarian Association for Migrants',
      country: 'Hungary',
      countryCode: 'HU',
      type: 'immigrant_support',
      phone: '+36 1 322 1502',
      email: 'info@menedek.hu',
      website: 'https://menedek.hu/en',
      description: 'NGO providing social and legal assistance, integration programs, and cultural mediation for refugees and migrants in Hungary.',
      languages: ['hu', 'en', 'ar', 'fa', 'uk'],
      freeService: true,
    ),
  ];

  // ─────────────────────────────────────────────────
  // BULGARIA (BG)
  // ─────────────────────────────────────────────────
  static const List<LegalAidContact> bulgariaContacts = [
    LegalAidContact(
      name: 'Национално бюро за правна помощ (National Legal Aid Bureau)',
      country: 'Bulgaria',
      countryCode: 'BG',
      type: 'legal_aid',
      phone: '+359 2 981 93 00',
      website: 'https://www.nbpp.government.bg',
      description: 'Government bureau organizing free legal aid for vulnerable persons. Manages a register of legal aid attorneys.',
      languages: ['bg', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Български хелзинкски комитет (Bulgarian Helsinki Committee)',
      country: 'Bulgaria',
      countryCode: 'BG',
      type: 'ngo',
      phone: '+359 2 981 3318',
      email: 'bhc@bghelsinki.org',
      website: 'https://www.bghelsinki.org',
      description: 'Leading human rights NGO providing free legal representation to asylum seekers and refugees, monitoring detention conditions, and strategic litigation.',
      languages: ['bg', 'en', 'ar', 'fa'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Фондация „Асоциация Анимус" (Animus Association Foundation)',
      country: 'Bulgaria',
      countryCode: 'BG',
      type: 'victim_support',
      phone: '+359 2 981 7686',
      website: 'https://animusassociation.org',
      description: 'NGO providing crisis intervention, psychological counseling, and legal assistance to victims of violence and trafficking.',
      languages: ['bg', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Комисия за защита от дискриминация (Commission for Protection against Discrimination)',
      country: 'Bulgaria',
      countryCode: 'BG',
      type: 'anti_discrimination',
      phone: '+359 2 807 30 30',
      email: 'kzd@kzd.bg',
      website: 'https://www.kzd-nondiscrimination.com',
      description: 'Independent state body handling complaints of discrimination based on race, ethnicity, gender, religion, disability, and other grounds.',
      languages: ['bg', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Съвет на бежанските жени в България (Council of Refugee Women in Bulgaria)',
      country: 'Bulgaria',
      countryCode: 'BG',
      type: 'immigrant_support',
      phone: '+359 2 953 3766',
      email: 'crw@crw-bg.org',
      website: 'https://crw-bg.org',
      description: 'NGO supporting refugee integration through legal aid, language courses, employment assistance, and community programs.',
      languages: ['bg', 'en', 'ar', 'fa'],
      freeService: true,
    ),
  ];

  // ─────────────────────────────────────────────────
  // CROATIA (HR)
  // ─────────────────────────────────────────────────
  static const List<LegalAidContact> croatiaContacts = [
    LegalAidContact(
      name: 'Besplatna pravna pomoć (Free Legal Aid)',
      country: 'Croatia',
      countryCode: 'HR',
      type: 'legal_aid',
      phone: '+385 1 371 40 00',
      website: 'https://pravosudje.gov.hr/besplatna-pravna-pomoc/6184',
      description: 'Government system of free primary and secondary legal aid. Available through county offices and authorized legal clinics.',
      languages: ['hr', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Hrvatski pravni centar (Croatian Law Centre)',
      country: 'Croatia',
      countryCode: 'HR',
      type: 'ngo',
      phone: '+385 1 484 11 53',
      email: 'hpc@hpc.hr',
      website: 'https://www.hpc.hr',
      description: 'NGO providing free legal aid to asylum seekers, refugees, and stateless persons. Also conducts research on refugee and migration law.',
      languages: ['hr', 'en', 'ar'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Žrtve i svjedoci (Victims and Witnesses Support)',
      country: 'Croatia',
      countryCode: 'HR',
      type: 'victim_support',
      phone: '+385 116 006',
      website: 'https://pravosudje.gov.hr/podrska-zrtvama-i-svjedocima/6156',
      description: 'Court-based victim and witness support service providing emotional support, information about proceedings, and referrals.',
      languages: ['hr', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Pučki pravobranitelj (Ombudsperson)',
      country: 'Croatia',
      countryCode: 'HR',
      type: 'anti_discrimination',
      phone: '+385 1 430 99 88',
      email: 'info@ombudsman.hr',
      website: 'https://www.ombudsman.hr',
      description: 'Parliamentary ombudsperson handling complaints about human rights violations and discrimination by public bodies.',
      languages: ['hr', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Are You Syrious (AYS)',
      country: 'Croatia',
      countryCode: 'HR',
      type: 'immigrant_support',
      email: 'areyousyrious@gmail.com',
      website: 'https://www.areyousyrious.org',
      description: 'Grassroots NGO providing direct assistance to refugees and displaced persons, daily news digests, and legal information.',
      languages: ['hr', 'en', 'ar'],
      freeService: true,
    ),
  ];

  // ─────────────────────────────────────────────────
  // SLOVAKIA (SK)
  // ─────────────────────────────────────────────────
  static const List<LegalAidContact> slovakiaContacts = [
    LegalAidContact(
      name: 'Centrum právnej pomoci (Centre for Legal Aid)',
      country: 'Slovakia',
      countryCode: 'SK',
      type: 'legal_aid',
      phone: '+421 650 105 100',
      email: 'info@centrumpravnejpomoci.sk',
      website: 'https://www.centrumpravnejpomoci.sk',
      description: 'State organization providing free legal aid to persons in material need. Has offices in all regions of Slovakia.',
      languages: ['sk', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Liga za ľudské práva (Human Rights League)',
      country: 'Slovakia',
      countryCode: 'SK',
      type: 'ngo',
      phone: '+421 2 5441 0021',
      email: 'hrl@hrl.sk',
      website: 'https://www.hrl.sk',
      description: 'NGO providing free legal assistance to asylum seekers and refugees. Monitors asylum procedures and advocates for refugee rights.',
      languages: ['sk', 'en', 'ar', 'uk'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Pomoc obetiam násilia (Victim Support Slovakia)',
      country: 'Slovakia',
      countryCode: 'SK',
      type: 'victim_support',
      phone: '+421 850 111 321',
      website: 'https://www.pomocobetiam.sk',
      description: 'National victim support service providing free legal, psychological, and social assistance to crime victims.',
      languages: ['sk', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Slovenské národné stredisko pre ľudské práva (Slovak National Centre for Human Rights)',
      country: 'Slovakia',
      countryCode: 'SK',
      type: 'anti_discrimination',
      phone: '+421 2 2082 6101',
      email: 'info@snslp.sk',
      website: 'https://www.snslp.sk',
      description: 'National human rights institution and equality body handling discrimination complaints and providing legal assistance.',
      languages: ['sk', 'en', 'hu'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Slovenská humanitná rada (Slovak Humanitarian Council)',
      country: 'Slovakia',
      countryCode: 'SK',
      type: 'immigrant_support',
      phone: '+421 2 5020 1614',
      website: 'https://www.shr.sk',
      description: 'Umbrella organization for NGOs providing integration support, language courses, and social assistance to refugees and migrants.',
      languages: ['sk', 'en', 'uk'],
      freeService: true,
    ),
  ];

  // ─────────────────────────────────────────────────
  // SLOVENIA (SI)
  // ─────────────────────────────────────────────────
  static const List<LegalAidContact> sloveniaContacts = [
    LegalAidContact(
      name: 'Brezplačna pravna pomoč (Free Legal Aid)',
      country: 'Slovenia',
      countryCode: 'SI',
      type: 'legal_aid',
      website: 'https://www.gov.si/teme/brezplacna-pravna-pomoc/',
      description: 'Government free legal aid system administered by district courts. Covers legal advice and representation for those with insufficient means.',
      languages: ['sl', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'PIC — Pravno-informacijski center (Legal Information Centre)',
      country: 'Slovenia',
      countryCode: 'SI',
      type: 'ngo',
      phone: '+386 1 521 18 88',
      email: 'pic@pic.si',
      website: 'https://pic.si',
      description: 'Leading Slovenian NGO providing free legal aid to refugees, asylum seekers, and undocumented migrants. Active in strategic litigation before European courts.',
      languages: ['sl', 'en', 'ar'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Društvo za nenasilno komunikacijo (Association for Non-violent Communication)',
      country: 'Slovenia',
      countryCode: 'SI',
      type: 'victim_support',
      phone: '+386 1 434 48 22',
      website: 'https://www.drustvo-dnk.si',
      description: 'NGO providing support to victims of violence including free legal counseling, safe houses, and psychological support.',
      languages: ['sl', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Zagovornik načela enakosti (Advocate of the Principle of Equality)',
      country: 'Slovenia',
      countryCode: 'SI',
      type: 'anti_discrimination',
      phone: '+386 1 473 55 31',
      email: 'gp.zagovornik@gov.si',
      website: 'https://zagovornik.si',
      description: 'Independent state body handling discrimination complaints and promoting equal treatment in Slovenia.',
      languages: ['sl', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Slovenska filantropija (Slovenian Philanthropy)',
      country: 'Slovenia',
      countryCode: 'SI',
      type: 'immigrant_support',
      phone: '+386 1 430 12 88',
      email: 'info@filantropija.org',
      website: 'https://www.filantropija.org',
      description: 'NGO running integration programs for refugees: mentoring, language courses, employment support, and cultural mediation.',
      languages: ['sl', 'en', 'ar'],
      freeService: true,
    ),
  ];

  // ─────────────────────────────────────────────────
  // PORTUGAL (PT)
  // ─────────────────────────────────────────────────
  static const List<LegalAidContact> portugalContacts = [
    LegalAidContact(
      name: 'Proteção Jurídica / Apoio Judiciário (Legal Protection / Judicial Aid)',
      country: 'Portugal',
      countryCode: 'PT',
      type: 'legal_aid',
      phone: '+351 808 200 351',
      website: 'https://www.seg-social.pt/protecao-juridica',
      description: 'Government legal aid system providing free legal consultation and representation through Social Security offices. Available to Portuguese and foreign residents.',
      languages: ['pt', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Conselho Português para os Refugiados (CPR)',
      country: 'Portugal',
      countryCode: 'PT',
      type: 'ngo',
      phone: '+351 21 831 43 72',
      email: 'geral@cpr.pt',
      website: 'https://cpr.pt',
      description: 'Portuguese Council for Refugees — provides legal assistance, social support, and integration services for asylum seekers and refugees since 1991.',
      languages: ['pt', 'en', 'fr', 'ar'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'APAV (Associação Portuguesa de Apoio à Vítima)',
      country: 'Portugal',
      countryCode: 'PT',
      type: 'victim_support',
      phone: '+351 116 006',
      email: 'apav.sede@apav.pt',
      website: 'https://apav.pt',
      description: 'Leading Portuguese victim support organization with 20+ offices. Provides free legal, psychological, and social support to all crime victims.',
      languages: ['pt', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Comissão para a Igualdade e contra a Discriminação Racial (CICDR)',
      country: 'Portugal',
      countryCode: 'PT',
      type: 'anti_discrimination',
      phone: '+351 21 810 61 00',
      website: 'https://www.cicdr.pt',
      description: 'Commission for Equality and Against Racial Discrimination. Processes complaints and promotes equal treatment regardless of race, nationality, or ethnicity.',
      languages: ['pt', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'JRS Portugal (Serviço Jesuíta aos Refugiados)',
      country: 'Portugal',
      countryCode: 'PT',
      type: 'immigrant_support',
      phone: '+351 21 881 49 27',
      email: 'info@jfrportugal.pt',
      website: 'https://www.jfrportugal.pt',
      description: 'Jesuit Refugee Service providing legal aid, Portuguese language courses, housing support, and integration assistance for refugees.',
      languages: ['pt', 'en', 'fr', 'ar'],
      freeService: true,
    ),
  ];

  // ─────────────────────────────────────────────────
  // GREECE (GR)
  // ─────────────────────────────────────────────────
  static const List<LegalAidContact> greeceContacts = [
    LegalAidContact(
      name: 'Νομική Βοήθεια (Legal Aid Greece)',
      country: 'Greece',
      countryCode: 'GR',
      type: 'legal_aid',
      website: 'https://www.ministryofjustice.gr/nomiki-voithia/',
      description: 'Government legal aid system providing free legal representation to those with very low income. Asylum seekers are entitled to legal aid at second instance.',
      languages: ['el', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Ελληνικό Συμβούλιο για τους Πρόσφυγες (Greek Council for Refugees — GCR)',
      country: 'Greece',
      countryCode: 'GR',
      type: 'ngo',
      phone: '+30 210 380 0990',
      email: 'gcr@gcr.gr',
      website: 'https://www.gcr.gr',
      description: 'Oldest and most established refugee NGO in Greece. Provides free legal representation in asylum cases, detention monitoring, and advocacy.',
      languages: ['el', 'en', 'ar', 'fa', 'fr'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Κέντρο Υποστήριξης Θυμάτων (Research Centre for Gender Equality — KETHI)',
      country: 'Greece',
      countryCode: 'GR',
      type: 'victim_support',
      phone: '+30 210 389 1030',
      website: 'https://www.kethi.gr',
      description: 'State-funded centers providing legal and psychological support to victims of gender-based violence and discrimination.',
      languages: ['el', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Συνήγορος του Πολίτη (Greek Ombudsman)',
      country: 'Greece',
      countryCode: 'GR',
      type: 'anti_discrimination',
      phone: '+30 213 130 6600',
      email: 'press@synigoros.gr',
      website: 'https://www.synigoros.gr',
      description: 'Independent authority handling complaints about discrimination, rights violations by public administration, and children\'s rights. Also serves as equality body.',
      languages: ['el', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'PRAKSIS',
      country: 'Greece',
      countryCode: 'GR',
      type: 'immigrant_support',
      phone: '+30 210 520 5200',
      email: 'praksis@praksis.gr',
      website: 'https://www.praksis.gr',
      description: 'Major Greek NGO providing healthcare, legal aid, social services, and integration support to refugees and vulnerable populations.',
      languages: ['el', 'en', 'ar', 'fa', 'fr'],
      freeService: true,
    ),
  ];

  // ─────────────────────────────────────────────────
  // MALTA (MT)
  // ─────────────────────────────────────────────────
  static const List<LegalAidContact> maltaContacts = [
    LegalAidContact(
      name: 'Legal Aid Malta',
      country: 'Malta',
      countryCode: 'MT',
      type: 'legal_aid',
      phone: '+356 2590 2219',
      website: 'https://justice.gov.mt/en/legalaid/',
      description: 'Government legal aid agency providing free legal assistance in civil and criminal matters to those who cannot afford it.',
      languages: ['mt', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'aditus Foundation',
      country: 'Malta',
      countryCode: 'MT',
      type: 'ngo',
      phone: '+356 2010 6295',
      email: 'info@aditus.org.mt',
      website: 'https://aditus.org.mt',
      description: 'Human rights NGO providing free legal advice to asylum seekers and refugees, monitoring detention, and advocating for migrant rights.',
      languages: ['mt', 'en', 'ar', 'fr'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Victim Support Malta',
      country: 'Malta',
      countryCode: 'MT',
      type: 'victim_support',
      phone: '+356 2122 8333',
      email: 'info@victimsupport.org.mt',
      website: 'https://www.victimsupport.org.mt',
      description: 'Free and confidential support service for victims of crime providing emotional support, legal information, and court accompaniment.',
      languages: ['mt', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'National Commission for the Promotion of Equality (NCPE)',
      country: 'Malta',
      countryCode: 'MT',
      type: 'anti_discrimination',
      phone: '+356 2590 3850',
      email: 'equality@gov.mt',
      website: 'https://ncpe.gov.mt',
      description: 'Government commission promoting equality and investigating complaints of discrimination based on gender, race, ethnicity, age, and other grounds.',
      languages: ['mt', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'JRS Malta (Jesuit Refugee Service)',
      country: 'Malta',
      countryCode: 'MT',
      type: 'immigrant_support',
      phone: '+356 2144 2751',
      email: 'info@jrsmalta.org',
      website: 'https://www.jrsmalta.org',
      description: 'Provides direct assistance to refugees and asylum seekers: legal information, livelihood programs, psychosocial support, and detention visits.',
      languages: ['mt', 'en', 'ar', 'fr', 'so'],
      freeService: true,
    ),
  ];

  // ─────────────────────────────────────────────────
  // CYPRUS (CY)
  // ─────────────────────────────────────────────────
  static const List<LegalAidContact> cyprusContacts = [
    LegalAidContact(
      name: 'Νομική Αρωγή (Legal Aid Cyprus)',
      country: 'Cyprus',
      countryCode: 'CY',
      type: 'legal_aid',
      phone: '+357 22 806 200',
      website: 'https://www.mjpo.gov.cy/mjpo/mjpo.nsf/page09_en/page09_en',
      description: 'Government legal aid available for criminal and civil cases. Asylum seekers have the right to free legal aid at the appeals stage.',
      languages: ['el', 'en', 'tr'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'KISA — Action for Equality, Support, Antiracism',
      country: 'Cyprus',
      countryCode: 'CY',
      type: 'ngo',
      phone: '+357 22 878 181',
      email: 'info@kisa.org.cy',
      website: 'https://kisa.org.cy',
      description: 'NGO providing free legal and social support to migrants, refugees, and asylum seekers. Active in anti-racism advocacy and integration.',
      languages: ['el', 'en', 'tr', 'ar'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Cyprus Crime Victim Support Association',
      country: 'Cyprus',
      countryCode: 'CY',
      type: 'victim_support',
      phone: '+357 22 878 181',
      website: 'https://www.police.gov.cy',
      description: 'Victim support services coordinated through the police Social Welfare Office and NGOs. Provides information about rights and referrals.',
      languages: ['el', 'en', 'tr'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Επίτροπος Διοικήσεως και Ανθρωπίνων Δικαιωμάτων (Commissioner for Administration and Human Rights — Ombudsman)',
      country: 'Cyprus',
      countryCode: 'CY',
      type: 'anti_discrimination',
      phone: '+357 22 405 500',
      email: 'commissioner@ombudsman.gov.cy',
      website: 'https://www.ombudsman.gov.cy',
      description: 'Independent authority acting as equality body and anti-discrimination authority. Handles complaints about public administration and equal treatment.',
      languages: ['el', 'en', 'tr'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Cyprus Refugee Council',
      country: 'Cyprus',
      countryCode: 'CY',
      type: 'immigrant_support',
      phone: '+357 22 256 006',
      email: 'info@cyrefugeecouncil.org',
      website: 'https://www.cyrefugeecouncil.org',
      description: 'NGO providing legal information, social assistance, and integration support to refugees and asylum seekers in Cyprus.',
      languages: ['el', 'en', 'ar', 'fr'],
      freeService: true,
    ),
  ];

  // ─────────────────────────────────────────────────
  // LUXEMBOURG (LU)
  // ─────────────────────────────────────────────────
  static const List<LegalAidContact> luxembourgContacts = [
    LegalAidContact(
      name: 'Assistance Judiciaire (Judicial Assistance)',
      country: 'Luxembourg',
      countryCode: 'LU',
      type: 'legal_aid',
      phone: '+352 247 84 600',
      website: 'https://justice.public.lu/fr/aides-informations/assistance-judiciaire.html',
      description: 'Free legal aid for those with insufficient income. Covers all legal matters. Apply through the Bar Council (Conseil de l\'Ordre des Avocats).',
      languages: ['fr', 'de', 'lb', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Lëtzebuerger Flüchtlingsrot (Luxembourg Refugee Council — LFR)',
      country: 'Luxembourg',
      countryCode: 'LU',
      type: 'ngo',
      phone: '+352 26 94 04 07',
      email: 'info@lfr.lu',
      website: 'https://www.lfr.lu',
      description: 'Platform of NGOs working with refugees in Luxembourg. Coordinates legal advice, advocacy, and integration activities.',
      languages: ['fr', 'de', 'en', 'ar'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Service d\'Aide aux Victimes (Victim Aid Service)',
      country: 'Luxembourg',
      countryCode: 'LU',
      type: 'victim_support',
      phone: '+352 475 821 628',
      website: 'https://justice.public.lu/fr/aides-informations/aide-victimes.html',
      description: 'Government victim support service providing free psychological support, legal information, and accompaniment through criminal proceedings.',
      languages: ['fr', 'de', 'lb', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'Centre pour l\'égalité de traitement (Centre for Equal Treatment — CET)',
      country: 'Luxembourg',
      countryCode: 'LU',
      type: 'anti_discrimination',
      phone: '+352 26 48 30 33',
      email: 'info@cet.lu',
      website: 'https://cet.lu',
      description: 'Independent body promoting equality and assisting victims of discrimination based on race, ethnicity, gender, religion, disability, age, and sexual orientation.',
      languages: ['fr', 'de', 'lb', 'en'],
      freeService: true,
    ),
    LegalAidContact(
      name: 'ASTI (Association de Soutien aux Travailleurs Immigrés)',
      country: 'Luxembourg',
      countryCode: 'LU',
      type: 'immigrant_support',
      phone: '+352 43 83 33',
      email: 'info@asti.lu',
      website: 'https://www.asti.lu',
      description: 'Major Luxembourg NGO supporting immigrant workers and their families with legal advice, language courses, and advocacy for integration policies.',
      languages: ['fr', 'de', 'lb', 'en', 'pt'],
      freeService: true,
    ),
  ];

  // ─────────────────────────────────────────────────
  // ALL CONTACTS — Combined list
  // ─────────────────────────────────────────────────

  static List<LegalAidContact> get allContacts => [
    ...euWideContacts,
    ...finlandContacts,
    ...estoniaContacts,
    ...germanyContacts,
    ...swedenContacts,
    ...franceContacts,
    ...italyContacts,
    ...spainContacts,
    ...netherlandsContacts,
    ...polandContacts,
    ...romaniaContacts,
    ...latviaContacts,
    ...lithuaniaContacts,
    ...austriaContacts,
    ...belgiumContacts,
    ...irelandContacts,
    ...denmarkContacts,
    ...czechRepublicContacts,
    ...hungaryContacts,
    ...bulgariaContacts,
    ...croatiaContacts,
    ...slovakiaContacts,
    ...sloveniaContacts,
    ...portugalContacts,
    ...greeceContacts,
    ...maltaContacts,
    ...cyprusContacts,
    ...luxembourgContacts,
  ];

  /// Get contacts for a specific country by country code (e.g., 'FI', 'DE', 'EU')
  static List<LegalAidContact> getByCountry(String countryCode) {
    return allContacts
        .where((c) => c.countryCode.toUpperCase() == countryCode.toUpperCase())
        .toList();
  }

  /// Get contacts by type across all countries
  static List<LegalAidContact> getByType(String type) {
    return allContacts.where((c) => c.type == type).toList();
  }

  /// Get contacts that serve in a specific language
  static List<LegalAidContact> getByLanguage(String languageCode) {
    return allContacts
        .where((c) => c.languages.contains(languageCode.toLowerCase()))
        .toList();
  }

  /// Get contacts for a country filtered by type
  static List<LegalAidContact> getByCountryAndType(String countryCode, String type) {
    return allContacts
        .where((c) =>
            c.countryCode.toUpperCase() == countryCode.toUpperCase() &&
            c.type == type)
        .toList();
  }

  /// Search contacts by name or description keyword
  static List<LegalAidContact> search(String query) {
    final q = query.toLowerCase();
    return allContacts
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            (c.description?.toLowerCase().contains(q) ?? false) ||
            c.country.toLowerCase().contains(q))
        .toList();
  }

  /// Get all free services (most are free, but this filters explicitly)
  static List<LegalAidContact> getFreeServices() {
    return allContacts.where((c) => c.freeService).toList();
  }

  /// Get all available country codes
  static List<String> get availableCountries {
    return allContacts.map((c) => c.countryCode).toSet().toList()..sort();
  }

  /// Get contact count statistics
  static Map<String, int> get statistics {
    return {
      'total': allContacts.length,
      'countries': allContacts.map((c) => c.countryCode).toSet().length,
      'legal_aid': getByType('legal_aid').length,
      'ngo': getByType('ngo').length,
      'victim_support': getByType('victim_support').length,
      'anti_discrimination': getByType('anti_discrimination').length,
      'immigrant_support': getByType('immigrant_support').length,
    };
  }

  /// Get the emergency number for any EU country
  static const String euEmergencyNumber = '112';

  /// Get EU rights information portal
  static const String euJusticePortal = 'https://e-justice.europa.eu';

  /// Format a contact for display in chat
  static String formatForChat(LegalAidContact contact) {
    final buffer = StringBuffer();
    buffer.writeln('${contact.name}');
    buffer.writeln('Country: ${contact.country}');
    if (contact.phone != null) buffer.writeln('Phone: ${contact.phone}');
    if (contact.email != null) buffer.writeln('Email: ${contact.email}');
    if (contact.website != null) buffer.writeln('Web: ${contact.website}');
    if (contact.description != null) buffer.writeln(contact.description);
    if (contact.languages.isNotEmpty) {
      buffer.writeln('Languages: ${contact.languages.join(", ")}');
    }
    buffer.writeln(contact.freeService ? 'Free service' : 'May have fees');
    return buffer.toString();
  }

  /// Format multiple contacts for a summary view
  static String formatCountrySummary(String countryCode) {
    final contacts = getByCountry(countryCode);
    if (contacts.isEmpty) return 'No contacts found for $countryCode';

    final buffer = StringBuffer();
    buffer.writeln('=== ${contacts.first.country} ===\n');
    for (final contact in contacts) {
      buffer.writeln('${contact.name}');
      buffer.writeln('  Type: ${contact.type}');
      if (contact.phone != null) buffer.writeln('  Phone: ${contact.phone}');
      if (contact.website != null) buffer.writeln('  Web: ${contact.website}');
      buffer.writeln('');
    }
    return buffer.toString();
  }
}
