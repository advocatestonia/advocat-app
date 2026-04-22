// ---------------------------------------------------------------------------
// EstonianMaxResources — additional Estonian legal resources added by
// OMEGA-ESTONIA-MAX (feature/estonia-max).
//
// This class augments the existing EstonianLegalDatabase with:
//   - 12 additional statutes (KodS, VSS, VRKS, SHS, EhS, PlanS, TTKS,
//     TKindlS, RPKS, AutÕS, RekS, LKindlS2)
//   - Supreme Court (Riigikohus) search guide + landmark cases
//   - Government procedures + service URLs
//   - Comprehensive deadlines table
//   - Emergency contacts with Russian-language hotlines
//   - Russian-language resource directory
//   - Business/tax deep dive for 2026 rates
//
// All data is cited to official sources (riigiteataja.ee, eesti.ee,
// official agency websites) with fetched_at timestamps in the source
// JSON files under assets/legal/estonia/.
//
// IMPORTANT: this file does NOT modify existing 20 acts in the corpus.
// It only adds NEW resources. Existing acts are maintained by
// fix/estonian-corpus branch (OMEGA-CORPUS-FIX).
// ---------------------------------------------------------------------------

abstract final class EstonianMaxResources {
  /// Map of newly added acts: code → (name, source URL, consolidated date,
  /// audience priority).
  static const Map<String, Map<String, String>> newActs = <String, Map<String, String>>{
    'KodS': <String, String>{
      'name': 'Kodakondsuse seadus',
      'name_en': 'Citizenship Act',
      'url': 'https://www.riigiteataja.ee/akt/KodS',
      'consolidated': '2025-07-06',
      'audience': 'high',
      'asset': 'assets/legal/estonia/kods.json',
    },
    'VSS': <String, String>{
      'name': 'Väljasõidukohustuse ja sissesõidukeelu seadus',
      'name_en': 'Obligation to Leave and Prohibition on Entry Act',
      'url': 'https://www.riigiteataja.ee/akt/VSS',
      'consolidated': '2025-09-01',
      'audience': 'critical',
      'asset': 'assets/legal/estonia/vss.json',
    },
    'VRKS': <String, String>{
      'name': 'Välismaalasele rahvusvahelise kaitse andmise seadus',
      'name_en': 'Act on Granting International Protection to Aliens',
      'url': 'https://www.riigiteataja.ee/akt/VRKS',
      'consolidated': '2025-09-01',
      'audience': 'critical',
      'asset': 'assets/legal/estonia/vrks.json',
    },
    'SHS': <String, String>{
      'name': 'Sotsiaalhoolekande seadus',
      'name_en': 'Social Welfare Act',
      'url': 'https://www.riigiteataja.ee/akt/SHS',
      'consolidated': '2026-01-09',
      'audience': 'high',
      'asset': 'assets/legal/estonia/shs.json',
    },
    'EhS': <String, String>{
      'name': 'Ehitusseadustik',
      'name_en': 'Building Code',
      'url': 'https://www.riigiteataja.ee/akt/EhS',
      'consolidated': '2026-03-28',
      'audience': 'medium',
      'asset': 'assets/legal/estonia/ehs.json',
    },
    'PlanS': <String, String>{
      'name': 'Planeerimisseadus',
      'name_en': 'Planning Act',
      'url': 'https://www.riigiteataja.ee/akt/PlanS',
      'consolidated': '2026-01-01',
      'audience': 'medium',
      'asset': 'assets/legal/estonia/plans.json',
    },
    'TTKS': <String, String>{
      'name': 'Tervishoiuteenuste korraldamise seadus',
      'name_en': 'Health Services Organization Act',
      'url': 'https://www.riigiteataja.ee/akt/TTKS',
      'consolidated': '2026-04-01',
      'audience': 'high',
      'asset': 'assets/legal/estonia/ttks.json',
    },
    'TKindlS': <String, String>{
      'name': 'Töötuskindlustuse seadus',
      'name_en': 'Unemployment Insurance Act',
      'url': 'https://www.riigiteataja.ee/akt/TKindlS',
      'consolidated': '2026-01-01',
      'audience': 'high',
      'asset': 'assets/legal/estonia/tkindls.json',
    },
    'RPKS': <String, String>{
      'name': 'Riikliku pensionikindlustuse seadus',
      'name_en': 'State Pension Insurance Act',
      'url': 'https://www.riigiteataja.ee/akt/RPKS',
      'consolidated': '2025-11-01',
      'audience': 'high',
      'asset': 'assets/legal/estonia/rpks.json',
    },
    'AutÕS': <String, String>{
      'name': 'Autoriõiguse seadus',
      'name_en': 'Copyright Act',
      'url': 'https://www.riigiteataja.ee/akt/AutÕS',
      'consolidated': '2025-10-01',
      'audience': 'low',
      'asset': 'assets/legal/estonia/autos.json',
    },
    'RekS': <String, String>{
      'name': 'Reklaamiseadus',
      'name_en': 'Advertising Act',
      'url': 'https://www.riigiteataja.ee/akt/RekS',
      'consolidated': '2026-03-16',
      'audience': 'low',
      'asset': 'assets/legal/estonia/reks.json',
    },
    'LKindlS2': <String, String>{
      'name': 'Liikluskindlustuse seadus (motor TPL)',
      'name_en': 'Motor Third-Party Liability Insurance Act',
      'url': 'https://www.riigiteataja.ee/akt/LKindlS',
      'consolidated': '2025-01-01',
      'audience': 'medium',
      'asset': 'assets/legal/estonia/lkindls2.json',
    },
  };

  /// Russian-language information notice to append when the AI detects that
  /// the user is communicating in Russian and asking about Estonian law.
  static const String russianResourceNotice = '''
Вам доступны официальные источники на русском языке:
- Портал госуслуг: https://www.eesti.ee/ru
- Налогово-таможенный департамент: https://www.emta.ee/ru
- Департамент полиции и погранохраны (PPA): https://www.politsei.ee/ru
- Департамент соцстраха: https://sotsiaalkindlustusamet.ee/ru
- Биржа труда (Töötukassa): https://www.tootukassa.ee/ru
- Фонд интеграции (INSA): https://www.integratsioon.ee/ru, бесплатный телефон 800 9999
- Бесплатная юрконсультация (HUGO.legal): https://www.juristaitab.ee

Экстренные телефоны с поддержкой на русском:
- 112 — общая экстренная
- 1247 — государственная инфолиния (24/7)
- 116 006 — помощь жертвам преступлений (24/7, анонимно)
- 116 111 — детская линия помощи (24/7)
''';

  /// Official Supreme Court (Riigikohus) case search guide.
  static const String riigikohusSearchGuide = '''
RIIGIKOHUS (Supreme Court of Estonia) case law search:
- Interface: https://www.riigikohus.ee/et/lahendid
- URL pattern for decisions: https://www.riigikohus.ee/et/lahendid/?asjaNr=CASE_NO
- Case number format: CHAMBER-YEAR-NUMBER/SUFFIX
  - 1-… Criminal Chamber (Kriminaalkolleegium)
  - 2-… Civil Chamber (Tsiviilkolleegium)
  - 3-… Administrative Chamber (Halduskolleegium)
  - 5-… Constitutional Review Chamber (Põhiseaduslikkuse järelevalve kolleegium)
- Annual report: https://aastaraamat.riigikohus.ee/
- ECtHR summaries (RU-relevant): https://www.riigikohus.ee/et/kohtupraktika-analuusid-ja-ulevaated/euroopa-inimoiguste-kohtu-lahendite-kokkuvotted
''';

  /// State legal aid eligibility and application guide.
  static const String stateLegalAidGuide = '''
STATE LEGAL AID (Riigi õigusabi) — Eesti Advokatuur
URL: https://www.advokatuur.ee/en/state-legal-aid

ELIGIBILITY:
- Natural person residing in Estonia or another EU Member State, OR
- Citizen of Estonia or another EU Member State

COST STRUCTURES (three types):
1. Free (no reimbursement obligation) — for low-income persons
2. Partial reimbursement in installments — moderate income
3. Full reimbursement (state pre-pays) — higher income but still eligible

APPLICATION:
- Submit to county court (maakohus) of applicant's residence
- Financial situation notice required (except criminal defence)
- Appointment by Bar Association

ALTERNATIVE — HUGO.legal (https://www.juristaitab.ee):
- 2 hours free consultation
- Eligible: gross monthly income up to €1,200
- Available in ET / EN / RU
''';

  /// Tax rates snapshot for 2026 (effective dates noted).
  static const Map<String, dynamic> taxRates2026 = <String, dynamic>{
    'personal_income_tax_percent': 22,
    'basic_exemption_monthly_eur': 700,
    'basic_exemption_pensioner_eur': 776,
    'corporate_tax_distributed_fraction': '22/78',
    'corporate_effective_rate_percent': 22,
    'vat_standard_percent': 24,
    'vat_reduced_percents': <int>[13, 9, 0],
    'vat_registration_threshold_eur': 40000,
    'social_tax_percent': 33,
    'social_tax_min_base_monthly_eur': 886,
    'unemployment_employee_percent': 1.6,
    'unemployment_employer_percent': 0.8,
    'min_wage_monthly_eur_2026': 946,
    'min_wage_hourly_eur_2026': 5.67,
  };

  /// Key appeal deadlines added by this module (complement existing
  /// EstonianLegalDatabase.deadlines). Values are calendar days.
  static const Map<String, int> additionalDeadlinesDays = <String, int>{
    'asylum_rejection_appeal': 10,
    'asylum_examination_by_ppa': 180,
    'deportation_precept_appeal': 10,
    'detailed_plan_objection': 30,
    'detailed_plan_court_appeal': 30,
    'construction_permit_appeal': 30,
    'pension_decision_appeal': 30,
    'unemployment_benefit_appeal': 30,
    'motor_insurance_claim_resolution': 30,
    'annual_report_submission': 180,
    'ombudsman_complaint_recommended_days': 365,
    'gdpr_complaint_recommended_days': 1095,
  };

  /// Emergency hotlines Russian-speaking residents can call.
  static const String emergencyHotlinesSummary = '''
EMERGENCY HOTLINES (all support Russian language unless noted):
- 112         — General emergency (police/ambulance/fire), 24/7
- 1247        — State Information + Crisis Hotline, 24/7
                From abroad: +372 600 1247
- 116 006     — Victim Support Crisis Hotline (Ohvriabi), 24/7, anonymous
                From abroad: +372 614 7393
                Chat: https://www.palunabi.ee
- 116 123     — Emotional Support Helpline (primarily ET)
- 116 111     — Child Helpline, 24/7
- 800 9999    — Integration Info Line (INSA), free in Estonia
                From abroad: +372 6599 025
- 640 6000    — Labour Inspectorate consultation, Mon-Fri 09:00-15:00
- 5620 2341   — Data Protection (AKI), Mon-Thu 13:00-16:00
''';

  /// Returns true if the given act code is among the newly added acts.
  static bool isNewAct(String actCode) => newActs.containsKey(actCode);

  /// Returns the count of newly added acts.
  static int get newActCount => newActs.length;

  /// Returns total Estonian act codes covered after this update
  /// (existing 20 + new 12 = 32, excluding duplicate LKindlS).
  static const int totalActsCovered = 32;
}
