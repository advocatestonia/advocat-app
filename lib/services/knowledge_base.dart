import '../models/case_model.dart';
import 'knowledge_router.dart';

// ---------------------------------------------------------------------------
// Legal knowledge base — structured context for Claude system prompts
// ---------------------------------------------------------------------------

/// Provides country- and case-type-specific legal knowledge to include
/// in the Claude system prompt. Keeps context focused and within token
/// limits by selecting only relevant knowledge sections.
abstract final class KnowledgeBase {
  /// Maximum approximate token budget for the knowledge base context.
  static const int maxTokenBudget = 50000;

  /// Build the knowledge context string for a given case type and country.
  ///
  /// [query] is the user's current message text. When provided it is forwarded
  /// to [KnowledgeRouter] to pull relevant data from the 22 specialty databases.
  ///
  /// Returns a formatted text block suitable for inclusion in a system prompt.
  static String buildContext({
    CaseType? caseType,
    String? country,
    String? nationality,
    String? query,
  }) {
    final sections = <String>[];

    // Always include general EU rights
    sections.add(_euFundamentalRights);

    // Country-specific procedural law
    final countryLower = (country ?? 'finland').toLowerCase();
    if (countryLower.contains('finland') || countryLower.contains('suomi')) {
      sections.add(_finlandProcedural);
    } else if (countryLower.contains('germany') ||
        countryLower.contains('deutschland')) {
      sections.add(_germanyProcedural);
    } else if (countryLower.contains('sweden') ||
        countryLower.contains('sverige')) {
      sections.add(_swedenProcedural);
    }
    // Default: include Finland as primary market
    if (sections.length == 1) {
      sections.add(_finlandProcedural);
    }

    // Case-type-specific knowledge
    switch (caseType) {
      case CaseType.deportation:
      case CaseType.asylum:
      case CaseType.residencePermit:
      case CaseType.familyReunification:
      case CaseType.citizenship:
      case CaseType.workPermit:
        sections.add(_immigrationLaw(countryLower));
        break;
      case CaseType.laborDispute:
        sections.add(_laborLaw(countryLower));
        break;
      case CaseType.tenantRights:
        sections.add(_tenantLaw(countryLower));
        break;
      case CaseType.debtCollection:
        sections.add(_consumerLaw(countryLower));
        break;
      case CaseType.discrimination:
        sections.add(_discriminationLaw(countryLower));
        break;
      case CaseType.policeMisconduct:
        sections.add(_policeMisconductLaw(countryLower));
        break;
      case CaseType.socialBenefits:
        sections.add(_socialBenefitsLaw(countryLower));
        break;
      case CaseType.other:
      case null:
        // Include a broad overview
        sections.add(_immigrationLaw(countryLower));
        sections.add(_laborLaw(countryLower));
        sections.add(_tenantLaw(countryLower));
        break;
    }

    // If EU citizen, add free movement rights
    if (nationality != null && _euCountries.contains(nationality.toLowerCase())) {
      sections.add(_euFreeMovement);
    }

    // Specialty database context — pulled from 22 domain databases based on
    // the user's query keywords and case type.
    if (query != null && query.isNotEmpty) {
      try {
        final routerContext = KnowledgeRouter.getContextForQuery(
          query,
          country: country,
          caseType: caseType?.name,
        );
        if (routerContext.isNotEmpty) {
          sections.add(routerContext);
        }
      } catch (_) {
        // Router failure must never break the base prompt.
      }
    }

    return sections.join('\n\n---\n\n');
  }

  // ── EU Fundamental Rights ───────────────────────────────────────────────

  static const String _euFundamentalRights = '''
## EU FUNDAMENTAL RIGHTS (Always Applicable)

**Charter of Fundamental Rights of the European Union:**
- Art. 1: Human dignity is inviolable
- Art. 7: Respect for private and family life
- Art. 18: Right to asylum
- Art. 19: Protection in the event of removal, expulsion or extradition
  - No one may be removed to a state where there is a serious risk of death penalty, torture, or inhuman treatment
  - No collective expulsions
- Art. 21: Non-discrimination
- Art. 41: Right to good administration
  - Right to be heard before any adverse individual measure
  - Right of access to file
  - Obligation to give reasons for decisions
- Art. 47: Right to an effective remedy and a fair trial

**European Convention on Human Rights (ECHR):**
- Art. 3: Prohibition of torture and inhuman treatment (absolute, non-derogable)
- Art. 6: Right to a fair trial
- Art. 8: Right to respect for private and family life
- Art. 13: Right to an effective remedy
- Art. 14: Prohibition of discrimination
- Protocol 7, Art. 1: Procedural safeguards relating to expulsion of aliens

**EU Directive 2008/115/EC (Return Directive):**
- Art. 5: Non-refoulement, best interests of child, family life, health
- Art. 6-9: Return decision procedures
- Art. 12: Decisions must be in writing, give reasons, include info on remedies
- Art. 13: Right to effective remedy (appeal or review before competent authority)
- Art. 14: Safeguards pending return''';

  // ── EU Free Movement ────────────────────────────────────────────────────

  static const String _euFreeMovement = '''
## EU FREE MOVEMENT RIGHTS (EU/EEA Citizens)

**Directive 2004/38/EC (Free Movement Directive):**
- Art. 5: Right of entry (valid passport/ID sufficient)
- Art. 6: Right of residence up to 3 months without conditions
- Art. 7: Right of residence >3 months if worker, self-employed, student, or self-sufficient
- Art. 16: Permanent residence after 5 years continuous legal residence
- Art. 27: Restrictions on grounds of public policy, public security, public health
  - Must be proportionate and based on personal conduct
  - Previous criminal convictions alone not sufficient
  - Must represent genuine, present, and sufficiently serious threat
- Art. 28: Protection against expulsion
  - Greater protection after 5 years (serious grounds of public policy/security)
  - Greatest protection after 10 years (imperative grounds of public security)
- Art. 30: Notification of decisions (writing, reasons, remedies, time limit)
- Art. 31: Procedural safeguards (judicial/administrative redress, interim measures)

**Key ECJ Cases:**
- C-184/99 Grzelczyk: EU citizenship is the fundamental status
- C-413/99 Baumbast: Right of residence has direct effect
- C-145/09 Tsakouridis: High threshold for expulsion of long-term residents''';

  // ── Finland Procedural ──────────────────────────────────────────────────

  static const String _finlandProcedural = '''
## FINLAND — PROCEDURAL LAW

**Hallintolaki (Administrative Procedure Act, 434/2003):**
- Section 6: Principles of good administration (proportionality, impartiality, legitimate expectations)
- Section 17: Official language is Finnish and Swedish
- Section 26: Language of communication — authority must ensure person understands
- Section 31: Duty to investigate facts (authority bears burden)
- Section 34: Right to be heard before decision
- Section 36: Oral hearing if requested and necessary
- Section 44: Decision must be in writing with reasons
- Section 45: Obligation to state reasons for the decision
- Section 46: Decision must include appeal instructions
- Section 47: Appeal instructions must state: authority, time limit, manner of appeal
- Section 50: Correction of error in decision (procedural or clerical errors)
- Section 51: Annulment of erroneous decision

**Hallintolainkäyttölaki / Oikeudenkäynnistä hallintoasioissa (Act on Judicial Proceedings in Administrative Matters, 808/2019):**
- Section 7: Right to appeal administrative decisions
- Section 13-14: Time limit for appeal (30 days from notification)
- Section 36: Administrative court may grant interim measures (stay of execution)
- Section 73: Court can return matter to authority for new consideration

**Ulkomaalaislaki (Aliens Act, 301/2004):**
- Section 4: Application of law must respect human rights
- Section 5: Non-refoulement
- Section 146: Grounds for deportation (limited, exhaustive list)
- Section 147-148: Consideration of ties to Finland, proportionality
- Section 150: Right to be heard before deportation decision
- Section 152: Authority to issue decisions (only designated officials)
- Section 190-191: Right of appeal to administrative court
- Section 198: Execution of decisions (not before appeal period expires)
- Section 201: Prohibition of removal during appeal if court orders stay
- Section 203: Language and translation requirements

**Key Finnish Courts:**
- First instance: Hallinto-oikeus (Administrative Court) — Helsinki, Turku, etc.
- Second instance: Korkein hallinto-oikeus (KHO, Supreme Administrative Court)
- Ombudsman: Eduskunnan oikeusasiamies (Parliamentary Ombudsman)''';

  // ── Germany Procedural ──────────────────────────────────────────────────

  static const String _germanyProcedural = '''
## GERMANY — PROCEDURAL LAW

**Verwaltungsverfahrensgesetz (VwVfG, Administrative Procedure Act):**
- Section 28: Right to be heard
- Section 37: Formal requirements of administrative acts
- Section 39: Duty to state reasons
- Section 44: Void administrative acts (serious procedural errors)
- Section 45: Healing of procedural defects
- Section 48-49: Withdrawal and revocation of administrative acts

**Verwaltungsgerichtsordnung (VwGO, Administrative Court Code):**
- Section 42: Right to file suit (Anfechtungsklage, Verpflichtungsklage)
- Section 80: Suspensive effect of appeals (Aufschiebende Wirkung)
- Section 123: Interim measures (Einstweilige Anordnung)

**Aufenthaltsgesetz (AufenthG, Residence Act):**
- Section 50-58: Obligation to leave, deportation
- Section 60: Prohibition of deportation (non-refoulement, ECHR)
- Section 60a: Temporary suspension of deportation (Duldung)

**Key German Courts:**
- Verwaltungsgericht (Administrative Court, first instance)
- Oberverwaltungsgericht / Verwaltungsgerichtshof (Higher Administrative Court)
- Bundesverwaltungsgericht (Federal Administrative Court)''';

  // ── Sweden Procedural ───────────────────────────────────────────────────

  static const String _swedenProcedural = '''
## SWEDEN — PROCEDURAL LAW

**Förvaltningslagen (Administrative Procedure Act, 2017:900):**
- Section 5: Good administration (legality, objectivity, proportionality)
- Section 25: Right to be heard (kommunicering)
- Section 32: Decisions must be in writing with reasons

**Utlänningslagen (Aliens Act, 2005:716):**
- Chapter 8: Expulsion provisions
- Chapter 12: Prohibition of enforcement (non-refoulement)
- Chapter 14: Appeals to migration court (Migrationsdomstol)

**Key Swedish Courts:**
- Migrationsdomstol (Migration Court, first instance — 4 courts)
- Migrationsöverdomstolen (Migration Court of Appeal — Stockholm)''';

  // ── Case-type-specific knowledge ────────────────────────────────────────

  static String _immigrationLaw(String country) {
    if (country.contains('finland') || country.contains('suomi')) {
      return '''
## FINLAND — IMMIGRATION & DEPORTATION LAW

**Deportation (Ulkomaalaislaki Section 143-149):**
- Section 143: Grounds for deportation (conviction, threat to public order, residence permit expired)
- Section 146: Deportation decision must consider:
  - Duration of residence in Finland
  - Family and social ties
  - Best interests of the child
  - Conditions in the country of return
- Section 147: Prohibition of deportation (non-refoulement applies)
- Section 148: Voluntary departure period (7-30 days normally)
- Section 149: Entry ban (1-5 years, or permanent for serious cases)

**Appeal Process:**
1. Receive decision with appeal instructions
2. File appeal to Hallinto-oikeus (Administrative Court) within 30 days
3. Request stay of execution (turvaamistoimenpide) if deportation imminent
4. Oral hearing at court (request within appeal)
5. Court decision — can annul, modify, or return for new consideration
6. If unsuccessful: appeal to KHO (Supreme Administrative Court) — leave required
7. Alternative: Complaint to Parliamentary Ombudsman (procedural issues)

**Procedural Errors That Can Invalidate a Decision:**
- Wrong language (must provide in language person understands)
- Failure to hear the person before decision
- Decision by unauthorized official
- Factual errors in the decision
- Failure to consider relevant circumstances
- Missing or inadequate reasoning
- Missing appeal instructions

**Free Legal Aid:**
- Oikeusapu (Legal Aid) — means-tested, covers lawyer fees
- Apply at Oikeusaputoimisto (Legal Aid Office)
- Pakolaisneuvonta (Refugee Advice Centre) — for asylum seekers
- RIKU (Victim Support Finland) — if crime involved

**Key Migri (Finnish Immigration Service) Procedures:**
- Application for residence permit: enterfinland.fi
- Interview at Migri or police station
- Decision notification by letter (must include reasons and appeal instructions)
- Processing times vary: 1-18 months depending on permit type''';
    }
    if (country.contains('germany') || country.contains('deutschland')) {
      return '''
## GERMANY — IMMIGRATION LAW

**Aufenthaltsgesetz (Residence Act):**
- Section 50: Obligation to leave federal territory
- Section 51: Grounds for expiry of residence permit
- Section 53-56: Expulsion (Ausweisung) — interest-balancing test
- Section 58: Deportation (Abschiebung) — enforcement of obligation to leave
- Section 59: Deportation warning (Abschiebungsandrohung)
- Section 60: Prohibition of deportation (non-refoulement)
- Section 60a: Duldung (temporary suspension of deportation)

**Kündigungsschutzgesetz (KSchG, Dismissal Protection Act):**
- Applies to establishments with more than 10 employees
- Section 1: Dismissal must be socially justified
- Section 4: 3-week deadline to file unfair dismissal claim (Kündigungsschutzklage)

**Key Deadlines:**
- Appeal against asylum decision: 2 weeks (negative) or 1 week (manifestly unfounded)
- Appeal against deportation order: varies by state, typically 1 month
- Duldung renewal: before expiry date''';
    }
    return '''
## GENERAL EU IMMIGRATION LAW

**Key EU Instruments:**
- Regulation (EU) 604/2013 (Dublin III): Determines responsible Member State for asylum
- Directive 2011/95/EU (Qualification Directive): Standards for refugee status
- Directive 2013/32/EU (Asylum Procedures Directive): Common procedures
- Directive 2013/33/EU (Reception Conditions Directive): Material reception conditions
- Directive 2008/115/EC (Return Directive): Common standards for return

**Universal Protections:**
- Non-refoulement (cannot return person to danger)
- Right to be heard before adverse decision
- Right to legal assistance and interpretation
- Right to appeal to a judicial authority''';
  }

  static String _laborLaw(String country) {
    if (country.contains('finland') || country.contains('suomi')) {
      return '''
## FINLAND — LABOR LAW

**Työsopimuslaki (Employment Contracts Act, 55/2001):**
- Chapter 1, Section 3: Employment contract can be oral, written, or electronic
- Chapter 7: Grounds for termination (individual grounds — serious breach of obligations)
- Chapter 8: Grounds for immediate cancellation (extremely serious breach)
- Chapter 9: Notice periods (14 days to 6 months depending on duration)
- Chapter 12, Section 2: Compensation for unlawful termination (3-24 months salary)

**Yhdenvertaisuuslaki (Non-Discrimination Act, 1325/2014):**
- Prohibits discrimination in employment on grounds of age, origin, nationality, language, religion, etc.

**Key Bodies:**
- Aluehallintovirasto (Regional State Administrative Agency) — workplace inspections
- Tasa-arvovaltuutettu (Equality Ombudsman)
- Työtuomioistuin (Labour Court) — collective agreement disputes''';
    }
    if (country.contains('germany') || country.contains('deutschland')) {
      return '''
## GERMANY — LABOR LAW

**Kündigungsschutzgesetz (KSchG, Employment Protection Act):**
- Section 1: Dismissal must be socially justified (personal, behavioral, or operational reasons)
- Section 2: Modified dismissal (Änderungskündigung)
- Section 4: 3-WEEK DEADLINE to file unfair dismissal claim at Arbeitsgericht
- Section 9-10: Dissolution and severance pay

**Betriebsverfassungsgesetz (BetrVG, Works Constitution Act):**
- Section 102: Works council (Betriebsrat) must be consulted before any dismissal
- Failure to consult makes the dismissal void

**BGB (Civil Code) Employment Provisions:**
- Section 611a: Employment contract definition
- Section 622: Notice periods (4 weeks to 7 months)
- Section 626: Dismissal for cause (Wichtiger Grund) — 2-week notification period

**Key Points:**
- CRITICAL: 3-week deadline to challenge dismissal at Arbeitsgericht!
- Works council consultation is mandatory if one exists
- Written form required for termination notice
- Probationary period: 6 months maximum, 2-week notice period''';
    }
    return '''
## EU LABOR LAW BASICS

- Directive 98/59/EC: Collective redundancies
- Directive 2001/23/EC: Transfer of undertakings (employee rights protected)
- Directive 2003/88/EC: Working time (max 48 hours/week, rest periods)
- Directive 2019/1152: Transparent and predictable working conditions''';
  }

  static String _tenantLaw(String country) {
    if (country.contains('finland') || country.contains('suomi')) {
      return '''
## FINLAND — TENANT RIGHTS

**Laki asuinhuoneiston vuokrauksesta (AHVL, Act on Residential Leases, 481/1995):**
- Section 3-4: Lease agreement types (fixed-term vs. open-ended)
- Section 7: Written form not required but recommended
- Section 51-54: Termination by landlord:
  - Open-ended lease: notice required (3 months if <1 year tenancy, 6 months if >1 year)
  - Fixed-term lease: cannot be terminated early unless contract allows
  - Must have a justified reason (e.g., own use, renovation, sale)
  - Notice must be in writing
- Section 55-56: Termination by tenant:
  - Open-ended: 1 month notice
  - Fixed-term: only as per contract
- Section 61: Right to dispute termination in court within 30 days
- Section 20-26: Maintenance obligations (landlord: structure, tenant: general care)
- Section 30: Rent increase must follow contract terms or be reasonable

**Eviction Process:**
- Landlord cannot self-help evict (change locks, remove belongings)
- Must get court order (haaste oikeuteen)
- Tenant has right to legal aid
- Court can grant extra time for moving (max 1 year in hardship cases)

**Key Bodies:**
- Vuokralautakunta (Rent Tribunal) — Helsinki has one, free mediation
- Kuluttajariitalautakunta (Consumer Disputes Board)
- Käräjäoikeus (District Court) — for formal disputes''';
    }
    return '''
## EU TENANT RIGHTS BASICS

Tenant rights are primarily national law, but EU law provides:
- Non-discrimination in housing (Directive 2000/43/EC — racial equality)
- Consumer protection in unfair contract terms (Directive 93/13/EEC)
- Energy performance requirements (Directive 2010/31/EU)
- Right to adequate housing recognized in EU Charter Art. 34''';
  }

  static String _consumerLaw(String country) {
    return '''
## CONSUMER & DEBT COLLECTION LAW

**EU Consumer Rights Directive 2011/83/EU:**
- 14-day withdrawal right for distance/online contracts
- Information requirements before contract
- Prohibition of hidden charges

**EU Unfair Commercial Practices Directive 2005/29/EC:**
- Prohibition of aggressive debt collection practices
- Misleading actions and omissions prohibited

${country.contains('finland') || country.contains('suomi') ? '''
**Finland — Debt Collection:**
- Laki saatavien perinnästä (Debt Collection Act, 513/1999)
- Debt collector must identify themselves and the creditor
- Consumer has right to dispute the debt
- Aggressive or harassing collection is prohibited
- Kuluttaja-asiamies (Consumer Ombudsman) can intervene
- Ulosotto (enforcement) only through official bailiff (ulosottomies)
''' : ''}''';
  }

  static String _discriminationLaw(String country) {
    return '''
## DISCRIMINATION LAW

**EU Anti-Discrimination Framework:**
- Directive 2000/43/EC: Racial Equality (employment, education, social protection, housing)
- Directive 2000/78/EC: Equal Treatment in Employment (religion, disability, age, sexual orientation)
- Directive 2006/54/EC: Equal Treatment of Men and Women in Employment

**Key Principles:**
- Direct and indirect discrimination prohibited
- Harassment constitutes discrimination
- Victimization (retaliation for complaint) prohibited
- Burden of proof shifts to respondent once prima facie case established

${country.contains('finland') || country.contains('suomi') ? '''
**Finland — Yhdenvertaisuuslaki (Non-Discrimination Act, 1325/2014):**
- Applies to: employment, education, services, housing
- Protected grounds: age, origin, nationality, language, religion, belief, opinion, political activity, trade union activity, family relationships, health, disability, sexual orientation, or other personal characteristic
- Yhdenvertaisuusvaltuutettu (Non-Discrimination Ombudsman) — free, handles complaints
- Yhdenvertaisuus- ja tasa-arvolautakunta (Non-Discrimination and Equality Tribunal)
''' : ''}''';
  }

  static String _policeMisconductLaw(String country) {
    return '''
## POLICE MISCONDUCT / COMPLAINTS

**ECHR Protections:**
- Art. 3: Prohibition of torture/inhuman treatment (includes police brutality)
- Art. 5: Right to liberty (unlawful arrest/detention)
- Art. 13: Right to effective remedy against state actors

${country.contains('finland') || country.contains('suomi') ? '''
**Finland — Complaints Against Police:**
- Poliisin laillisuusvalvonta (Police Legality Control)
- Eduskunnan oikeusasiamies (Parliamentary Ombudsman) — handles police complaints
- Valtioneuvoston oikeuskansleri (Chancellor of Justice)
- Criminal complaint: file with another police district or directly to prosecutor
- Syyttäjä (Prosecutor) investigates police criminal matters
- Poliisilaki (Police Act, 872/2011) — Section 2: Proportionality requirement
''' : ''}''';
  }

  static String _socialBenefitsLaw(String country) {
    return '''
## SOCIAL BENEFITS LAW

${country.contains('finland') || country.contains('suomi') ? '''
**Finland — Key Social Benefits:**
- Kela (Social Insurance Institution) — manages most benefits
- Toimeentulotuki (Social Assistance) — last resort, municipality/Kela
- Asumistuki (Housing Allowance) — Kela
- Työttömyysturva (Unemployment Benefits) — Kela or unemployment fund
- Sairauspäiväraha (Sickness Allowance) — Kela

**Appeal Process for Kela Decisions:**
1. Request for review (oikaisuvaatimus) to Kela within 30 days
2. Appeal to Sosiaaliturva-asioiden muutoksenhakulautakunta (Social Security Appeal Board)
3. Further appeal to Vakuutusoikeus (Insurance Court)

**Right to Social Assistance:**
- Available to all residents regardless of nationality (if legally resident)
- Cannot be denied if person has no other means of support
- Covers: food, clothing, hygiene, local transport, small personal expenses, housing costs
''' : ''}''';
  }

  // ── Helper: EU member state check ───────────────────────────────────────

  static const Set<String> _euCountries = {
    'austrian', 'austria', 'belgian', 'belgium', 'bulgarian', 'bulgaria',
    'croatian', 'croatia', 'cypriot', 'cyprus', 'czech', 'czechia',
    'danish', 'denmark', 'estonian', 'estonia', 'finnish', 'finland',
    'french', 'france', 'german', 'germany', 'greek', 'greece',
    'hungarian', 'hungary', 'irish', 'ireland', 'italian', 'italy',
    'latvian', 'latvia', 'lithuanian', 'lithuania', 'luxembourgish',
    'luxembourg', 'maltese', 'malta', 'dutch', 'netherlands',
    'polish', 'poland', 'portuguese', 'portugal', 'romanian', 'romania',
    'slovak', 'slovakia', 'slovenian', 'slovenia', 'spanish', 'spain',
    'swedish', 'sweden',
    // EEA
    'norwegian', 'norway', 'icelandic', 'iceland', 'liechtenstein',
  };
}
