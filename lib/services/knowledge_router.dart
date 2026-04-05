// ---------------------------------------------------------------------------
// KnowledgeRouter — routes user queries to relevant specialty databases
// and returns a focused context string for inclusion in AI system prompts.
// ---------------------------------------------------------------------------

import 'business_database.dart';
import 'case_law_database.dart';
import 'citizenship_database.dart';
import 'consumer_protection_database.dart';
import 'digital_rights_database.dart';
import 'education_database.dart';
import 'emergency_phrases_database.dart';
import 'eu_directives_database.dart';
import 'family_law_database.dart';
import 'financial_access_database.dart';
import 'healthcare_database.dart';
import 'housing_rights_database.dart';
import 'inheritance_database.dart';
import 'insurance_pension_database.dart';
import 'knowledge_data_extended.dart';
import 'legal_aid_directory.dart';
import 'lgbtq_rights_database.dart';
import 'practical_guides_database.dart';
import 'prisoner_rights_database.dart';
import 'religious_rights_database.dart';
import 'social_benefits_database.dart';
import 'transportation_database.dart';
import 'work_permit_database.dart';

/// Routes queries to relevant specialty databases and assembles context.
///
/// Call [getContextForQuery] before building the AI system prompt.
/// The returned string is ready to append to the LEGAL KNOWLEDGE BASE section.
abstract final class KnowledgeRouter {
  /// Maximum characters to include from all specialty databases combined.
  static const int _maxContextChars = 8000;

  // Singleton instances for databases that use factory constructors.
  static final _healthcareDb = HealthcareDatabase();
  static final _housingDb = HousingRightsDatabase();
  static final _workPermitDb = WorkPermitDatabase();
  static final _educationDb = EducationDatabase();
  static final _financialDb = FinancialAccessDatabase();
  static final _businessDb = BusinessDatabase();
  static final _emergencyDb = EmergencyPhrasesDatabase();
  static final _prisonerDb = PrisonerRightsDatabase();
  static final _digitalDb = DigitalRightsDatabase();

  /// Build extra knowledge context from specialty databases.
  ///
  /// [query]    — the user's message text.
  /// [country]  — ISO 2-letter code or full country name, e.g. 'FI', 'Finland'.
  /// [caseType] — case type string, e.g. 'deportation'.
  ///
  /// Returns a Markdown-formatted string to append to the system prompt,
  /// capped at [_maxContextChars] characters.
  static String getContextForQuery(
    String query, {
    String? country,
    String? caseType,
  }) {
    final combined =
        '${query.toLowerCase()} ${(caseType ?? '').toLowerCase()}';
    final countryCode = _resolveCountryCode(country);
    final sections = <String>[];

    // Healthcare
    if (_matches(combined, [
      'health', 'медицин', 'больниц', 'doctor', 'hospital', 'clinic',
      'ehic', 'maternity', 'pregnancy', 'mental health', 'vaccine',
    ])) {
      try {
        final s = _buildHealthcareContext(countryCode);
        if (s.isNotEmpty) sections.add(s);
      } catch (_) {}
    }

    // Housing / tenant rights
    if (_matches(combined, [
      'housing', 'жильё', 'аренд', 'rental', 'rent', 'eviction',
      'tenant', 'landlord', 'lease', 'deposit', 'квартир',
    ])) {
      try {
        final s = _buildHousingContext(countryCode);
        if (s.isNotEmpty) sections.add(s);
      } catch (_) {}
    }

    // Work permit / visa
    if (_matches(combined, [
      'work permit', 'visa', 'работ', 'виза', 'permit', 'blue card',
      'residence permit', 'seasonal worker', 'work authorization',
    ])) {
      try {
        final s = _buildWorkPermitContext(countryCode);
        if (s.isNotEmpty) sections.add(s);
      } catch (_) {}
    }

    // Citizenship
    if (_matches(combined, [
      'citizen', 'passport', 'гражданств', 'naturalization',
      'naturalisation', 'dual citizenship', 'renunciation',
    ])) {
      try {
        final s = _buildCitizenshipContext(countryCode);
        if (s.isNotEmpty) sections.add(s);
      } catch (_) {}
    }

    // Social benefits
    if (_matches(combined, [
      'benefit', 'social', 'пособи', 'социальн', 'allowance',
      'welfare', 'assistance', 'kela', 'unemployment',
    ])) {
      try {
        final s = _buildSocialBenefitsContext(countryCode);
        if (s.isNotEmpty) sections.add(s);
      } catch (_) {}
    }

    // Education
    if (_matches(combined, [
      'school', 'university', 'education', 'учёб', 'образован',
      'enroll', 'diploma', 'degree', 'recognition', 'language course',
      'integration course',
    ])) {
      try {
        final s = _buildEducationContext(countryCode);
        if (s.isNotEmpty) sections.add(s);
      } catch (_) {}
    }

    // Family law
    if (_matches(combined, [
      'family', 'divorce', 'custody', 'семь', 'развод', 'алимент',
      'marriage', 'child support', 'domestic violence', 'child abduction',
      'maintenance', 'hague',
    ])) {
      try {
        final s = _buildFamilyContext(countryCode);
        if (s.isNotEmpty) sections.add(s);
      } catch (_) {}
    }

    // Consumer protection
    if (_matches(combined, [
      'consumer', 'warranty', 'return', 'возврат', 'гарантия',
      'flight', 'авиа', 'refund', 'withdrawal', 'online purchase',
      'package travel', 'compensation',
    ])) {
      try {
        final s = _buildConsumerContext();
        if (s.isNotEmpty) sections.add(s);
      } catch (_) {}
    }

    // Insurance / pension
    if (_matches(combined, [
      'insurance', 'pension', 'пенси', 'страховк', 'retirement',
      'car insurance', 'social security',
    ])) {
      try {
        final s = _buildInsurancePensionContext(countryCode);
        if (s.isNotEmpty) sections.add(s);
      } catch (_) {}
    }

    // EU directives
    if (_matches(combined, [
      'directive', 'regulation', 'директив', 'eu law', 'eu regulation',
      'regulation 604',
    ])) {
      try {
        final s = _buildEUDirectivesContext(combined);
        if (s.isNotEmpty) sections.add(s);
      } catch (_) {}
    }

    // Legal aid
    if (_matches(combined, [
      'lawyer', 'legal aid', 'адвокат', 'юрист', 'ngo',
      'free legal', 'legal help', 'бесплатн', 'ombudsman',
    ])) {
      try {
        final s = _buildLegalAidContext(countryCode);
        if (s.isNotEmpty) sections.add(s);
      } catch (_) {}
    }

    // Case law / precedents
    if (_matches(combined, [
      'court case', 'precedent', 'суд', 'прецедент', 'case law',
      'echr', 'cjeu', 'ruling', 'judgment',
    ])) {
      try {
        final s = _buildCaseLawContext(combined);
        if (s.isNotEmpty) sections.add(s);
      } catch (_) {}
    }

    // Emergency
    if (_matches(combined, [
      'emergency', 'police', 'arrest', 'полиц', 'арест', 'срочн',
      'help now', 'urgent', 'threatened', 'detained',
    ])) {
      try {
        final s = _buildEmergencyContext();
        if (s.isNotEmpty) sections.add(s);
      } catch (_) {}
    }

    // Business / startup
    if (_matches(combined, [
      'business', 'startup', 'company', 'бизнес', 'компани',
      'register company', 'sole trader', 'self-employed', 'vat',
    ])) {
      try {
        final s = _buildBusinessContext(countryCode);
        if (s.isNotEmpty) sections.add(s);
      } catch (_) {}
    }

    // Financial / banking / tax
    if (_matches(combined, [
      'bank', 'finance', 'tax', 'банк', 'налог', 'финанс',
      'account', 'credit', 'money transfer', 'remittance', 'fraud',
    ])) {
      try {
        final s = _buildFinancialContext(countryCode);
        if (s.isNotEmpty) sections.add(s);
      } catch (_) {}
    }

    // LGBTQ+
    if (_matches(combined, [
      'lgbtq', 'gay', 'lesbian', 'queer', 'transgender', 'same-sex',
      'sexual orientation',
    ])) {
      try {
        final s = _buildLgbtqContext(countryCode);
        if (s.isNotEmpty) sections.add(s);
      } catch (_) {}
    }

    // Prisoner rights
    if (_matches(combined, [
      'prison', 'detention', 'тюрьм', 'задержан',
      'detained', 'jail', 'remand', 'consular access',
    ])) {
      try {
        final s = _buildPrisonerRightsContext(countryCode);
        if (s.isNotEmpty) sections.add(s);
      } catch (_) {}
    }

    // Digital rights / GDPR
    if (_matches(combined, [
      'digital', 'gdpr', 'data', 'данные', 'цифров', 'privacy',
      'personal data', 'data protection', 'cookies', 'surveillance',
    ])) {
      try {
        final s = _buildDigitalRightsContext(countryCode);
        if (s.isNotEmpty) sections.add(s);
      } catch (_) {}
    }

    // Transportation / driving
    if (_matches(combined, [
      'car', 'transport', 'driving', 'машин', 'водительск',
      'license', 'licence', 'driver', 'vehicle', 'public transport',
    ])) {
      try {
        final s = _buildTransportationContext(countryCode);
        if (s.isNotEmpty) sections.add(s);
      } catch (_) {}
    }

    // Religious rights
    if (_matches(combined, [
      'religion', 'church', 'mosque', 'религи', 'церков', 'мечет',
      'halal', 'kosher', 'prayer', 'hijab', 'religious holiday',
    ])) {
      try {
        final s = _buildReligiousContext(countryCode);
        if (s.isNotEmpty) sections.add(s);
      } catch (_) {}
    }

    // Inheritance
    if (_matches(combined, [
      'inheritance', 'will', 'testament', 'наследств', 'завещан',
      'estate', 'probate', 'deceased', 'succession',
    ])) {
      try {
        final s = _buildInheritanceContext(countryCode);
        if (s.isNotEmpty) sections.add(s);
      } catch (_) {}
    }

    // Practical guides
    if (_matches(combined, [
      'guide', 'step', 'how to', 'как', 'пошагов', 'what to do',
      'instructions', 'procedure', 'process',
    ])) {
      try {
        final s = _buildPracticalGuidesContext(combined);
        if (s.isNotEmpty) sections.add(s);
      } catch (_) {}
    }

    // If nothing matched, fall back to extended country knowledge.
    if (sections.isEmpty) {
      try {
        final s = KnowledgeDataExtended.getCompactForCountry(countryCode);
        if (s.isNotEmpty) sections.add(s);
      } catch (_) {}
    }

    if (sections.isEmpty) return '';

    // Assemble and truncate to budget.
    final joined = sections.join('\n\n---\n\n');
    if (joined.length <= _maxContextChars) return joined;

    // Trim gracefully: include as many full sections as fit.
    final buffer = StringBuffer();
    var remaining = _maxContextChars;
    for (final s in sections) {
      if (remaining <= 100) break;
      final piece = s.length <= remaining ? s : s.substring(0, remaining);
      buffer.write(piece);
      remaining -= piece.length;
      if (remaining > 8) {
        buffer.write('\n\n---\n\n');
        remaining -= 8;
      }
    }
    return buffer.toString();
  }

  // ── Private helpers ────────────────────────────────────────────────────

  /// Returns true if [text] contains any of the [keywords].
  static bool _matches(String text, List<String> keywords) {
    for (final kw in keywords) {
      if (text.contains(kw)) return true;
    }
    return false;
  }

  /// Resolve a country string to an uppercase 2-letter ISO code.
  /// Defaults to 'FI' (Finland) if unrecognised.
  static String _resolveCountryCode(String? country) {
    if (country == null || country.isEmpty) return 'FI';
    final upper = country.toUpperCase().trim();
    if (upper.length == 2) return upper;
    const nameToCode = {
      'FINLAND': 'FI', 'SUOMI': 'FI',
      'GERMANY': 'DE', 'DEUTSCHLAND': 'DE',
      'SWEDEN': 'SE', 'SVERIGE': 'SE',
      'ESTONIA': 'EE', 'EESTI': 'EE',
      'FRANCE': 'FR', 'ITALY': 'IT',
      'SPAIN': 'ES', 'NETHERLANDS': 'NL',
      'HOLLAND': 'NL', 'POLAND': 'PL',
      'AUSTRIA': 'AT', 'BELGIUM': 'BE',
      'IRELAND': 'IE', 'DENMARK': 'DK',
      'CZECH REPUBLIC': 'CZ', 'CZECHIA': 'CZ',
      'HUNGARY': 'HU', 'ROMANIA': 'RO',
      'BULGARIA': 'BG', 'CROATIA': 'HR',
      'SLOVAKIA': 'SK', 'SLOVENIA': 'SI',
      'PORTUGAL': 'PT', 'GREECE': 'GR',
      'MALTA': 'MT', 'CYPRUS': 'CY',
      'LUXEMBOURG': 'LU', 'LATVIA': 'LV',
      'LITHUANIA': 'LT',
    };
    for (final entry in nameToCode.entries) {
      if (upper.contains(entry.key)) return entry.value;
    }
    return 'FI';
  }

  // ── Context builders ───────────────────────────────────────────────────

  static String _buildHealthcareContext(String countryCode) {
    final country = _healthcareDb.getByCountry(countryCode);
    if (country == null) {
      return '## HEALTHCARE (EU GENERAL)\n\n'
          '${HealthcareDatabase.emergencyInfo}\n\n'
          '${HealthcareDatabase.ehcardGeneralInfo}';
    }
    final sb = StringBuffer();
    sb.writeln('## HEALTHCARE — ${country.country.toUpperCase()}');
    sb.writeln();
    sb.writeln('Emergency number: ${country.emergencyNumber}');
    sb.writeln('Emergency free: ${country.emergencyFree ? "Yes" : "No"}');
    sb.writeln('Health system: ${country.healthInsuranceSystem}');
    sb.writeln('EHIC accepted: ${country.ehcardAccepted ? "Yes" : "No"}');
    sb.writeln('How to get EHIC: ${country.ehcardHowToGet}');
    sb.writeln('Undocumented access: ${country.undocumentedAccess}');
    sb.writeln('Asylum seeker access: ${country.asylumSeekerAccess}');
    sb.writeln('Mental health: ${country.mentalHealthAccess}');
    sb.writeln('Crisis line: ${country.mentalHealthCrisisLine}');
    sb.writeln('Maternity: ${country.maternityAccess}');
    sb.writeln('Children: ${country.childrenAccess}');
    sb.writeln('Registration: ${country.registrationProcess}');
    sb.writeln('Cost estimate: ${country.costEstimate}');
    if (country.freeClinicInfo != null) {
      sb.writeln('Free clinics: ${country.freeClinicInfo}');
    }
    sb.writeln('Legal basis: ${country.legalBasis}');
    sb.writeln('Immigrant notes: ${country.immigrantSpecificNotes}');
    return sb.toString().trim();
  }

  static String _buildHousingContext(String countryCode) {
    final r = _housingDb.getByCountryCode(countryCode);
    if (r == null) return '';
    final sb = StringBuffer();
    sb.writeln('## HOUSING / TENANT RIGHTS — ${r.country.toUpperCase()}');
    sb.writeln();
    sb.writeln('Max rent increase: ${r.maxRentIncreasePercent}%');
    sb.writeln('Eviction notice: ${r.evictionNoticeDays} days');
    sb.writeln('Court order required for eviction: ${r.courtOrderRequiredForEviction ? "Yes" : "No"}');
    sb.writeln('Deposit limit: ${r.depositLimitExists ? "${r.maxDepositMonths ?? "?"} months" : "No limit"}');
    sb.writeln('Rent control: ${r.rentControlRules}');
    sb.writeln('Repair obligations: ${r.repairObligations}');
    sb.writeln('Deposit return: ${r.depositReturnRules}');
    sb.writeln('Discrimination protections: ${r.discriminationProtections}');
    sb.writeln('Protection authority: ${r.tenantProtectionAuthority}');
    if (r.tenantHotline != null) sb.writeln('Hotline: ${r.tenantHotline}');
    sb.writeln('Emergency contact: ${r.emergencyContact}');
    sb.writeln('Contract language: ${r.languageOfContracts}');
    sb.writeln('Tenant rights:');
    for (final t in r.tenantRights) { sb.writeln('- $t'); }
    sb.writeln('Eviction protections:');
    for (final p in r.evictionProtections) { sb.writeln('- $p'); }
    sb.writeln('Legal basis: ${r.legalBasis}');
    sb.writeln('Immigrant notes: ${r.immigrantSpecificNotes}');
    return sb.toString().trim();
  }

  static String _buildWorkPermitContext(String countryCode) {
    final permits = _workPermitDb.getByCountry(countryCode);
    if (permits.isEmpty) return '';
    final sb = StringBuffer('## WORK PERMITS — ${countryCode.toUpperCase()}\n\n');
    for (final p in permits.take(4)) {
      sb.writeln('**${p.nameEn}** (${p.name})');
      sb.writeln('Category: ${p.category} | Processing: ${p.processingWeeks} weeks');
      sb.writeln('Description: ${p.description}');
      sb.writeln('Authority: ${p.applicationAuthority}');
      if (p.salaryThreshold != null) sb.writeln('Salary threshold: ${p.salaryThreshold}');
      if (p.validityPeriod != null) sb.writeln('Validity: ${p.validityPeriod}');
      sb.writeln('Legal basis: ${p.legalBasis}');
      sb.writeln();
    }
    return sb.toString().trim();
  }

  static String _buildCitizenshipContext(String countryCode) {
    CitizenshipPathway? pathway;
    try {
      pathway = CitizenshipDatabase.getAllPathways()
          .firstWhere((p) => p.countryCode.toUpperCase() == countryCode);
    } catch (_) {
      return '';
    }
    final sb = StringBuffer();
    sb.writeln('## CITIZENSHIP / NATURALIZATION — ${pathway.country.toUpperCase()}');
    sb.writeln();
    sb.writeln('Residence years required: ${pathway.residenceYears}');
    sb.writeln('Language test: ${pathway.languageTestRequired ? "Yes (${pathway.languageLevel ?? "see authority"})" : "No"}');
    sb.writeln('Civics test: ${pathway.civicsTestRequired ? "Yes" : "No"}');
    sb.writeln('Dual citizenship: ${pathway.dualCitizenshipAllowed ? "Allowed" : "Not allowed"}');
    sb.writeln('Authority: ${pathway.applicationAuthority}');
    sb.writeln('Processing time: ${pathway.processingMonths} months');
    if (pathway.applicationFee != null) sb.writeln('Fee: ${pathway.applicationFee}');
    sb.writeln('Requirements:');
    for (final r in pathway.requirements) { sb.writeln('- $r'); }
    if (pathway.exceptions.isNotEmpty) {
      sb.writeln('Exceptions:');
      for (final e in pathway.exceptions) { sb.writeln('- $e'); }
    }
    if (pathway.additionalNotes.isNotEmpty) {
      sb.writeln('Notes:');
      for (final n in pathway.additionalNotes.take(3)) { sb.writeln('- $n'); }
    }
    sb.writeln('Legal basis: ${pathway.legalBasis}');
    return sb.toString().trim();
  }

  static String _buildSocialBenefitsContext(String countryCode) {
    final benefits = SocialBenefitsDatabase.getBenefitsByCountry(countryCode);
    if (benefits.isEmpty) return '';
    final sb = StringBuffer('## SOCIAL BENEFITS — ${countryCode.toUpperCase()}\n\n');
    for (final b in benefits.take(5)) {
      sb.writeln('**${b.benefitName}** (${b.nameLocal})');
      sb.writeln('Type: ${b.type} | Eligibility: ${b.eligibility}');
      sb.writeln('Amount: ${b.amount} ${b.currency}');
      sb.writeln('How to apply: ${b.howToApply}');
      sb.writeln('Authority: ${b.authority}');
      if (b.phone != null) sb.writeln('Phone: ${b.phone}');
      sb.writeln('Asylum seekers: ${b.availableToAsylumSeekers ? "Yes" : "No"}');
      sb.writeln('Legal basis: ${b.legalBasis}');
      sb.writeln();
    }
    return sb.toString().trim();
  }

  static String _buildEducationContext(String countryCode) {
    final enrollment = _educationDb.getSchoolEnrollment(countryCode);
    if (enrollment == null) return '';
    final sb = StringBuffer();
    sb.writeln('## EDUCATION — ${enrollment.country.toUpperCase()}');
    sb.writeln();
    sb.writeln('Right regardless of status: ${enrollment.rightRegardlessOfStatus ? "Yes" : "No"}');
    sb.writeln('Compulsory age: ${enrollment.compulsoryAgeStart}–${enrollment.compulsoryAgeEnd}');
    sb.writeln('Enrollment without documents: ${enrollment.enrollmentPossibleWithoutDocuments ? "Yes" : "No"}');
    sb.writeln('Language support: ${enrollment.languageSupportProgram}');
    sb.writeln('Details: ${enrollment.languageSupportDetails}');
    sb.writeln('Free school meals: ${enrollment.freeSchoolMeals ? "Yes — ${enrollment.freeMealsDetails}" : "No"}');
    sb.writeln('Special education: ${enrollment.specialEducationRights}');
    sb.writeln('Enrollment process: ${enrollment.enrollmentProcess}');
    sb.writeln('Contact: ${enrollment.contactAuthority}');
    sb.writeln('Immigrant notes: ${enrollment.immigrantSpecificNotes}');
    sb.writeln('Legal basis: ${enrollment.legalBasis}');
    return sb.toString().trim();
  }

  static String _buildFamilyContext(String countryCode) {
    CountryFamilyLaw? data;
    try {
      data = FamilyLawDatabase.allCountries.firstWhere(
          (c) => c.countryCode.toUpperCase() == countryCode);
    } catch (_) {
      return FamilyLawDatabase.brusselsIIterOverview;
    }

    final sb = StringBuffer('## FAMILY LAW — ${data.country.toUpperCase()}\n\n');

    final m = data.marriage;
    sb.writeln('**Marriage:**');
    sb.writeln('- Min age: ${m.minimumAge} | Waiting period: ${m.waitingPeriodDays} days');
    sb.writeln('- Authority: ${m.registrationAuthority}');
    sb.writeln('- Foreign divorce recognised: ${m.foreignDivorceRecognized ? "Yes" : "No"}');
    if (m.notes.isNotEmpty) sb.writeln('- Notes: ${m.notes}');
    sb.writeln();

    final d = data.divorce;
    sb.writeln('**Divorce:**');
    sb.writeln('- Min separation: ${d.minimumSeparationMonths} months');
    sb.writeln('- Mutual consent: ${d.mutualConsentAvailable ? "Yes" : "No"}');
    sb.writeln('- Court: ${d.courtType}');
    sb.writeln('- Immigrant notes: ${d.immigrantNotes}');
    sb.writeln();

    final c = data.custody;
    sb.writeln('**Child custody:**');
    sb.writeln('- Default type: ${c.defaultCustodyType}');
    sb.writeln('- Hague Convention: ${c.hagueConventionStatus}');
    sb.writeln('- Immigrant notes: ${c.immigrantNotes}');

    if (data.brusselsIIterNotes.isNotEmpty) {
      sb.writeln();
      sb.writeln('Brussels IIter: ${data.brusselsIIterNotes}');
    }
    if (data.emergencyContacts.isNotEmpty) {
      sb.writeln('Emergency contacts: ${data.emergencyContacts}');
    }

    return sb.toString().trim();
  }

  static String _buildConsumerContext() {
    return '## CONSUMER RIGHTS (EU-WIDE)\n\n'
        'EU 14-day withdrawal right for online purchases (Directive 2011/83/EU).\n'
        'EU minimum 2-year warranty on all goods (Directive 2019/771).\n'
        'EU flight compensation EUR 250-600 for delays/cancellations (Regulation 261/2004).\n'
        'EU package travel protection including insolvency cover (Directive 2015/2302).';
  }

  static String _buildInsurancePensionContext(String countryCode) {
    CountryInsurancePension? data;
    try {
      data = InsurancePensionDatabase.allCountries.firstWhere(
          (c) => c.countryCode.toUpperCase() == countryCode);
    } catch (_) {
      return InsurancePensionDatabase.euRegulation883Summary;
    }

    final p = data.pension;
    final sb = StringBuffer('## INSURANCE & PENSION — ${data.country.toUpperCase()}\n\n');
    sb.writeln('**Pension:**');
    sb.writeln('- Retirement age: ${p.retirementAge} (women: ${p.retirementAgeWomen})');
    sb.writeln('- Min contribution years: ${p.minimumContributionYears}');
    sb.writeln('- Average state pension: ${p.averageStatePensionMonthly}');
    sb.writeln('- Authority: ${p.pensionAuthorityName} — ${p.pensionAuthorityWebsite}');
    sb.writeln();
    sb.writeln('**Mandatory insurance:**');
    for (final ins in data.mandatoryInsurance.take(4)) {
      sb.writeln('- ${ins.type}: ~${ins.averageMonthlyCost}/month');
      sb.writeln('  How to get as immigrant: ${ins.howToGetAsImmigrant}');
    }
    sb.writeln();
    sb.writeln('Health insurance: ${data.healthInsuranceSystem}');
    sb.writeln('Employee cost: ${data.healthInsuranceCostEmployee}');
    sb.writeln('Self-employed cost: ${data.healthInsuranceCostSelfEmployed}');
    sb.writeln('Immigrant notes: ${data.immigrantSpecificNotes}');
    return sb.toString().trim();
  }

  static String _buildEUDirectivesContext(String query) {
    List<EUDirective> relevant;
    if (_matches(query, ['asylum', 'refugee', 'asylum seeker'])) {
      relevant = EUDirectivesDatabase.immigrationAsylum.take(4).toList();
    } else if (_matches(query, ['worker', 'work', 'employ', 'labor'])) {
      relevant = EUDirectivesDatabase.workersRights.take(4).toList();
    } else if (_matches(query, ['discriminat', 'equality'])) {
      relevant = EUDirectivesDatabase.antiDiscrimination.take(4).toList();
    } else if (_matches(query, ['data', 'gdpr', 'privacy'])) {
      relevant = EUDirectivesDatabase.dataProtection.take(4).toList();
    } else if (_matches(query, ['consumer'])) {
      relevant = EUDirectivesDatabase.consumerProtection.take(4).toList();
    } else {
      relevant = EUDirectivesDatabase.fundamentalRights.take(4).toList();
    }

    if (relevant.isEmpty) return '';
    final sb = StringBuffer('## RELEVANT EU DIRECTIVES & REGULATIONS\n\n');
    for (final d in relevant) {
      sb.writeln('**${d.number} — ${d.shortName}** (${d.year})');
      sb.writeln(d.summary);
      if (d.keyArticles.isNotEmpty) {
        sb.writeln('Key articles: ${d.keyArticles.take(3).join("; ")}');
      }
      sb.writeln();
    }
    return sb.toString().trim();
  }

  static String _buildLegalAidContext(String countryCode) {
    final contacts = LegalAidDirectory.getByCountry(countryCode);
    final free =
        contacts.where((c) => c.freeService).take(5).toList();
    final all = free.isNotEmpty
        ? free
        : LegalAidDirectory.euWideContacts.take(4).toList();

    if (all.isEmpty) return '';
    final sb = StringBuffer('## LEGAL AID — ${countryCode.toUpperCase()}\n\n');
    for (final c in all) {
      sb.writeln('**${c.name}** [${c.type}]');
      if (c.phone != null) sb.writeln('Phone: ${c.phone}');
      if (c.email != null) sb.writeln('Email: ${c.email}');
      if (c.website != null) sb.writeln('Website: ${c.website}');
      if (c.description != null) sb.writeln(c.description);
      if (c.languages.isNotEmpty) sb.writeln('Languages: ${c.languages.join(", ")}');
      sb.writeln();
    }
    return sb.toString().trim();
  }

  static String _buildCaseLawContext(String query) {
    List<CourtCase> cases;
    if (_matches(query, ['deportation', 'expulsion', 'removal'])) {
      cases = CaseLawDatabase.deportationCases.take(4).toList();
    } else if (_matches(query, ['asylum', 'refugee'])) {
      cases = CaseLawDatabase.asylumCases.take(4).toList();
    } else if (_matches(query, ['family', 'reunification'])) {
      cases = CaseLawDatabase.familyReunificationCases.take(4).toList();
    } else if (_matches(query, ['detention'])) {
      cases = CaseLawDatabase.detentionCases.take(4).toList();
    } else if (_matches(query, ['worker', 'work'])) {
      cases = CaseLawDatabase.workerRightsCases.take(4).toList();
    } else {
      cases = CaseLawDatabase.searchCases(query).take(4).toList();
    }

    if (cases.isEmpty) return '';
    final sb = StringBuffer('## RELEVANT CASE LAW\n\n');
    for (final c in cases) {
      sb.writeln('**${c.title}** (${c.caseNumber}, ${c.court}, ${c.year})');
      sb.writeln('Key ruling: ${c.keyRuling}');
      sb.writeln('Articles: ${c.relevantArticles}');
      sb.writeln();
    }
    return sb.toString().trim();
  }

  static String _buildEmergencyContext() {
    final phrases = _emergencyDb.getPhrasesForLanguage('en');
    if (phrases.isEmpty) return '';
    final sb = StringBuffer('## EMERGENCY PHRASES & RIGHTS\n\n');
    sb.writeln('Emergency number in EU: 112');
    sb.writeln('\nKey emergency phrases (English):');
    for (final p in phrases.take(10)) {
      sb.writeln('- ${p.english}');
    }
    return sb.toString().trim();
  }

  static String _buildBusinessContext(String countryCode) {
    final guide = _businessDb.getByCountry(countryCode);
    if (guide == null) return '';
    final sb = StringBuffer('## BUSINESS FORMATION — ${guide.country.toUpperCase()}\n\n');
    sb.writeln('Immigrants can start a business: ${guide.immigrantsCanStartBusiness ? "Yes" : "No"}');
    sb.writeln('Summary: ${guide.immigrantBusinessSummary}');
    sb.writeln();
    sb.writeln('**Company types:**');
    for (final ct in guide.companyTypes.take(3)) {
      sb.writeln('- **${ct.englishName}** (${ct.abbreviation}): ${ct.description}');
      if (ct.minimumCapital != null && ct.minimumCapital! > 0) {
        sb.writeln('  Min capital: €${ct.minimumCapital!.toStringAsFixed(0)}');
      }
    }
    if (guide.startupVisaPrograms.isNotEmpty) {
      sb.writeln();
      sb.writeln('**Startup visa programs:**');
      for (final sv in guide.startupVisaPrograms.take(2)) {
        sb.writeln('- **${sv.name}**: ${sv.description}');
      }
    }
    sb.writeln();
    sb.writeln('Corporate tax: ${guide.taxInfo.corporateTaxRate}% | VAT: ${guide.taxInfo.vatStandardRate}%');
    return sb.toString().trim();
  }

  static String _buildFinancialContext(String countryCode) {
    final info = _financialDb.getCountryInfo(countryCode);
    if (info == null) return '';
    final sb = StringBuffer();
    sb.writeln('## FINANCIAL ACCESS — ${info.country.toUpperCase()}');
    sb.writeln();
    sb.writeln('Basic account right: ${info.basicAccountRight ? "Yes" : "No"}');
    sb.writeln('Documents for bank account: ${info.documentsForBankAccount.join(", ")}');
    sb.writeln('Best banks for immigrants: ${info.bestBanksForImmigrants.take(3).join(", ")}');
    sb.writeln('Banks for asylum seekers: ${info.banksForAsylumSeekers.take(3).join(", ")}');
    sb.writeln('Tax ID: ${info.taxIdName} — ${info.taxIdHowToGet}');
    sb.writeln('Tax obligations: ${info.taxObligationsForImmigrants}');
    sb.writeln('Filing deadline: ${info.taxFilingDeadline}');
    sb.writeln('Tax authority: ${info.taxAuthorityWebsite}');
    sb.writeln('Consumer credit: ${info.consumerCreditRights}');
    sb.writeln('Fraud authority: ${info.fraudProtectionAuthority} | ${info.fraudReportingPhone}');
    sb.writeln('Ombudsman: ${info.financialOmbudsman}');
    sb.writeln('Immigrant notes: ${info.immigrantSpecificNotes}');
    return sb.toString().trim();
  }

  static String _buildLgbtqContext(String countryCode) {
    final rights = LgbtqRightsDatabase.getCountryRights(countryCode);
    if (rights != null) {
      final sb = StringBuffer('## LGBTQ+ RIGHTS — ${rights.country.toUpperCase()}\n\n');
      sb.writeln('Marriage status: ${rights.marriageStatus.name}');
      sb.writeln('Marriage details: ${rights.marriageDetails}');
      sb.writeln('Employment protection: ${rights.employmentProtection ? "Yes" : "No"}');
      sb.writeln('Housing protection: ${rights.housingProtection ? "Yes" : "No"}');
      sb.writeln('Hate crime law: ${rights.hateCrimeLawSogi ? "Yes" : "No"}');
      sb.writeln('Conversion therapy ban: ${rights.conversionTherapyBan.name}');
      sb.writeln('Safety rating: ${rights.safetyRating.name}');
      sb.writeln('Safety notes: ${rights.safetyNotes}');
      sb.writeln('Asylum SOGI procedure: ${rights.asylumSogiProcedure}');
      sb.writeln('SOGI support org: ${rights.asylumSogiOrgSupport}');
      sb.writeln('Immigrant notes: ${rights.immigrantSpecificNotes}');
      sb.writeln('Refugee notes: ${rights.refugeeSpecificNotes}');
      return sb.toString().trim();
    }
    // Fallback: list safest countries
    final safe = LgbtqRightsDatabase.getSafestCountriesForAsylum().take(5);
    return '## LGBTQ+ ASYLUM — SAFEST EU COUNTRIES\n\n'
        '${safe.map((c) => "- ${c.country} (${c.countryCode}): ${c.safetyNotes}").join("\n")}';
  }

  static String _buildPrisonerRightsContext(String countryCode) {
    final data = _prisonerDb.getCountry(countryCode);
    if (data == null) {
      // Return EU framework summary
      final fw = PrisonerRightsDatabase.euFrameworks.take(3);
      final sb = StringBuffer('## PRISONER / DETENTION RIGHTS (EU)\n\n');
      for (final f in fw) {
        sb.writeln('**${f.name}** (${f.reference}, ${f.year})');
        sb.writeln(f.summary);
        sb.writeln();
      }
      return sb.toString().trim();
    }

    final sb = StringBuffer('## PRISONER / DETENTION RIGHTS — ${data.countryName.toUpperCase()}\n\n');
    for (final r in data.rights.take(7)) {
      sb.writeln('**${r.title}**');
      sb.writeln(r.description);
      if (r.practicalNotes != null) sb.writeln('Note: ${r.practicalNotes}');
      sb.writeln();
    }
    if (data.ngos.isNotEmpty) {
      sb.writeln('**NGOs helping prisoners:**');
      for (final ngo in data.ngos.take(3)) {
        sb.writeln('- ${ngo.name}: ${ngo.website ?? ngo.phone ?? ""}');
      }
    }
    return sb.toString().trim();
  }

  static String _buildDigitalRightsContext(String countryCode) {
    final country = _digitalDb.getByCountryCode(countryCode);
    if (country == null) {
      // Return universal GDPR rights summary
      final rights = DigitalRightsDatabase.universalGdprRights.take(4);
      final sb = StringBuffer('## GDPR / DIGITAL RIGHTS (EU-WIDE)\n\n');
      for (final r in rights) {
        sb.writeln('**${r.rightName}** (${r.article})');
        sb.writeln(r.simpleExplanation);
        sb.writeln();
      }
      return sb.toString().trim();
    }

    final dpa = country.dpa;
    final sb = StringBuffer();
    sb.writeln('## DIGITAL RIGHTS — ${country.country.toUpperCase()}');
    sb.writeln();
    sb.writeln('Data Protection Authority: ${dpa.authorityName}');
    sb.writeln('Website: ${dpa.website}');
    sb.writeln('Email: ${dpa.email}');
    sb.writeln('Complaint URL: ${dpa.complaintUrl}');
    sb.writeln('SIM registration required: ${country.simCardRegistrationRequired ? "Yes" : "No"}');
    sb.writeln('Internet access rights: ${country.internetAccessRights}');
    sb.writeln('Social media rights: ${country.socialMediaRights}');
    sb.writeln('Immigrant notes: ${country.immigrantSpecificDigitalRights}');
    return sb.toString().trim();
  }

  static String _buildTransportationContext(String countryCode) {
    TransportationRights? data;
    try {
      data = TransportationDatabase.allCountries.firstWhere(
          (c) => c.countryCode.toUpperCase() == countryCode);
    } catch (_) {
      return '';
    }

    final sb = StringBuffer();
    sb.writeln('## DRIVING LICENSE / TRANSPORT — ${data.country.toUpperCase()}');
    sb.writeln();
    sb.writeln('Foreign license accepted: ${data.foreignLicenseAccepted ? "Yes (${data.foreignLicenseValidMonths} months)" : "No"}');
    sb.writeln('Conditions: ${data.foreignLicenseConditions}');
    sb.writeln('Conversion process: ${data.conversionProcess}');
    sb.writeln('Cost: ${data.conversionCostEuros}');
    sb.writeln('Theory test: ${data.theoryTestRequired ? "Yes" : "No"}');
    sb.writeln('Practical test: ${data.practicalTestRequired ? "Yes" : "No"}');
    if (data.theoryTestLanguages.isNotEmpty) {
      sb.writeln('Test languages: ${data.theoryTestLanguages.join(", ")}');
    }
    sb.writeln('Public transport discounts: ${data.publicTransportDiscounts}');
    sb.writeln('Asylum seeker transport: ${data.asylumSeekerTransportRights}');
    sb.writeln('Authority: ${data.drivingAuthority} — ${data.authorityWebsite}');
    sb.writeln('Immigrant notes: ${data.immigrantSpecificNotes}');
    sb.writeln('Legal basis: ${data.legalBasis}');
    return sb.toString().trim();
  }

  static String _buildReligiousContext(String countryCode) {
    ReligiousRightsInfo? info;
    try {
      info = ReligiousRightsDatabase.allCountries.firstWhere(
          (c) => c.countryCode.toUpperCase() == countryCode);
    } catch (_) {
      return '';
    }

    final sb = StringBuffer();
    sb.writeln('## RELIGIOUS RIGHTS — ${info.country.toUpperCase()}');
    sb.writeln();
    sb.writeln('Legal basis: ${info.legalBasis}');
    sb.writeln('Constitutional provision: ${info.constitutionalProvision}');
    sb.writeln('Halal/Kosher — general: ${info.foodAccess.generalAvailability}');
    sb.writeln('Halal/Kosher — schools: ${info.foodAccess.schools}');
    sb.writeln('Religious holiday rights: ${info.holidayRights.employeeRights}');
    sb.writeln('Religious clothing at work: ${info.clothingRights.workplace}');
    sb.writeln('Face covering law: ${info.clothingRights.faceCoveringLaw}');
    sb.writeln('Prayer room (employer): ${info.prayerRoomRights.employerObligations}');
    sb.writeln('Discrimination complaints: ${info.discriminationComplaints.equalityBody}');
    sb.writeln('Complaint contact: ${info.discriminationComplaints.contactInfo}');
    sb.writeln('Islamic burial: ${info.burialRights.islamicBurial}');
    sb.writeln('Immigrant notes: ${info.immigrantSpecificNotes}');
    return sb.toString().trim();
  }

  static String _buildInheritanceContext(String countryCode) {
    InheritanceCountryData? data;
    try {
      data = InheritanceDatabase.getAllCountries().firstWhere(
          (c) => c.countryCode.toUpperCase() == countryCode);
    } catch (_) {
      return '## INHERITANCE — EU SUCCESSION REGULATION\n\n'
          '${EUSuccessionRegulation.summary}\n\n'
          'Key articles:\n'
          '${EUSuccessionRegulation.keyArticles.entries.take(4).map((e) => "${e.key}: ${e.value}").join("\n")}';
    }

    final law = data.lawBasics;
    final tax = data.tax;
    final sb = StringBuffer();
    sb.writeln('## INHERITANCE LAW — ${data.country.toUpperCase()}');
    sb.writeln();
    sb.writeln('Legal system: ${law.legalSystem}');
    sb.writeln('Main legislation: ${law.mainLegislation}');
    sb.writeln('Forced heirship: ${law.hasForcedHeirship ? "Yes" : "No"}');
    if (law.forcedHeirship != null) {
      sb.writeln('- Spouse share: ${law.forcedHeirship!.spouseShare}');
      sb.writeln('- Children share: ${law.forcedHeirship!.childrenShare}');
    }
    sb.writeln('Intestate order: ${law.intestateSuccessionOrder}');
    sb.writeln();
    sb.writeln('Inheritance tax: ${tax.hasInheritanceTax ? "Yes" : "No"}');
    sb.writeln('Spouse exemption: ${tax.spouseExemption}');
    sb.writeln('Child exemption: ${tax.childExemption}');
    sb.writeln('Foreign assets: ${tax.foreignAssetsTaxation}');
    sb.writeln();
    sb.writeln('Cross-border: ${data.crossBorderRules.recognitionOfForeignWills}');
    sb.writeln('Will registration: ${data.willGuide.registrationAuthority}');
    if (data.practicalTips.isNotEmpty) {
      sb.writeln('Tips:');
      for (final t in data.practicalTips.take(3)) { sb.writeln('- $t'); }
    }
    return sb.toString().trim();
  }

  static String _buildPracticalGuidesContext(String query) {
    List<PracticalGuide> guides;
    if (_matches(query, ['emergency', 'арест', 'police', 'detained'])) {
      guides = PracticalGuidesDatabase.getEmergencyGuides().take(2).toList();
    } else if (_matches(query, ['urgent', 'срочн'])) {
      guides = PracticalGuidesDatabase.getUrgentGuides().take(2).toList();
    } else {
      guides = PracticalGuidesDatabase.searchGuides(query).take(2).toList();
      if (guides.isEmpty) {
        guides = PracticalGuidesDatabase.getGuidesSortedByUrgency().take(2).toList();
      }
    }

    if (guides.isEmpty) return '';
    final sb = StringBuffer('## PRACTICAL STEP-BY-STEP GUIDES\n\n');
    for (final g in guides) {
      sb.writeln('**${g.title}** [${g.urgencyLevel.toUpperCase()}]');
      sb.writeln('Timeline: ${g.typicalTimeline} | Cost: ${g.costEstimate}');
      sb.writeln('Steps:');
      for (var i = 0; i < g.steps.length && i < 5; i++) {
        sb.writeln('${i + 1}. ${g.steps[i]}');
      }
      if (g.doNots.isNotEmpty) {
        sb.writeln('Do NOT:');
        for (final dn in g.doNots.take(3)) { sb.writeln('- $dn'); }
      }
      sb.writeln();
    }
    return sb.toString().trim();
  }
}
