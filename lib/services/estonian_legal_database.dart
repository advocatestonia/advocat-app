/// Comprehensive Estonian legal knowledge base.
/// Used by knowledge_base.dart to provide detailed legal context to AI.
abstract final class EstonianLegalDatabase {

  /// Key emergency and help contacts
  static const String contacts = '''
EMERGENCY: 112
State info: 1247
Victim support (24/7): 116 006
Child helpline (24/7): 116 111
Emotional support: 116 123
Courts info: 620 0100
Social Insurance: +372 612 1360
Unemployment Fund: 15501
Consumer protection: 667 2000
Chancellor of Justice: +372 693 8404
Notaries: +372 617 7900
''';

  /// Key self-service portals
  static const String portals = '''
e-Toimik (courts): https://etoimik.rik.ee/
PPA applications: https://etaotlus.politsei.ee
PPA appointments: https://broneering.politsei.ee
Social Insurance: https://iseteenindus.sotsiaalkindlustusamet.ee
Tax (e-MTA): https://maasikas.emta.ee
e-Notar: https://iseteenindus.notar.ee
Inheritance: https://parimine.notar.ee
Consumer disputes: https://komisjon.ttja.ee/
Free legal aid: https://www.juristaitab.ee
Alimony calculator: https://alimendid.ee
''';

  /// Critical legal deadlines (cross-law)
  static const String deadlines = '''
CRITICAL DEADLINES:
- Administrative challenge (vaie): 30 days (HMS § 75)
- Court action (annulment): 30 days (HKMS § 46)
- Challenge employment termination: 30 days
- Appeal court decision: 30 days
- Deportation order appeal: 10 days
- Voluntary departure after precept: 7-30 days
- Renounce inheritance: 3 months (PärS § 119)
- Landlord notice to terminate: 3 months (VÕS § 311)
- Retroactive alimony claim: 1 year (PKS § 77)
- Discrimination claim: 1 year (VõrdKS § 25)
- Wage claims: 3 years
- Product warranty: 2 years
- Online purchase withdrawal: 14 days
''';

  /// Family law (PKS) key info
  static const String familyLaw = '''
PEREKONNASEADUS (PKS) — Family Law Act
URL: https://www.riigiteataja.ee/akt/PKS

ALIMONY (§ 100-106):
- Both parents must support child (§ 100)
- Minimum alimony from 01.04.2026: €318.62/month per child
- Formula: base (€295.86) + 3% of previous year avg gross salary
- Updated annually April 1st. Calculator: alimendid.ee
- Can claim retroactively max 1 year (§ 77)
- State pays elatisabi if parent doesn't pay: up to €100/month per child via Sotsiaalkindlustusamet
- Court can enforce via bailiff (kohtutäitur)

DIVORCE (§ 63-67):
- Administrative (notary): if no disputes about children/property
- Court divorce: if disputes exist
- Ground: irretrievable breakdown (§ 67)
- Spousal support: if caring for child under 3 (§ 72)

CHILD CUSTODY (§ 116+):
- Joint custody by default
- Court can modify based on child's best interest
- Child 10+ years: court must consider child's wish
''';

  /// Employment law (TLS) key info
  static const String employmentLaw = '''
TÖÖLEPINGU SEADUS (TLS) — Employment Contracts Act
URL: https://www.riigiteataja.ee/akt/TLS

TERMINATION NOTICE (employer → employee):
- Under 1 year: 15 days
- 1-5 years: 30 days
- 5-10 years: 60 days
- 10+ years: 90 days
Employee notice: 30 days

REDUNDANCY: 1 month average salary compensation (§ 100)
UNLAWFUL TERMINATION: challenge within 30 DAYS to labor dispute committee (FREE!) or court
OVERTIME: 1.5x pay or time off (§ 44)
ANNUAL LEAVE: 28 calendar days (minors: 35)
MATERNITY: 100 days leave
PATERNITY: 30 days before child turns 3
WAGES: 3-year claim expiry
MINIMUM WAGE 2026: €886/month

PRACTICAL:
- If fired: go to Töötukassa within 30 days
- Labor dispute committee is FREE — alternative to court
- Pregnant/parental leave workers have extra protection
''';

  /// Criminal law (KarS) key info
  static const String criminalLaw = '''
KARISTUSSEADUSTIK (KarS) — Penal Code
URL: https://www.riigiteataja.ee/akt/KarS

KEY OFFENSES:
- § 120: Threats — fine or up to 1 year
- § 121: Physical abuse/assault — fine or up to 5 years (aggravated)
- § 121 lg 1: Simple assault — fine or up to 1 year
- § 157³: Stalking — fine or up to 1 year
- § 141: Rape — up to 5 years (aggravated: up to 15)
- § 199: Theft — fine or up to 3 years
- § 209: Fraud — fine or up to 3 years
- § 183: Drugs (small) — fine or up to 3 years
- § 184: Drugs (large) — 3-15 years
- § 424: Drunk driving — fine or up to 3 years

DOMESTIC VIOLENCE: file police report, request restraining order
VICTIM SUPPORT: call 116 006 (24/7)
POLICE DETENTION: max 48 hours without court order
''';

  /// Immigration law (VMS) key info
  static const String immigrationLaw = '''
VÄLISMAALASTE SEADUS (VMS) — Aliens Act
URL: https://www.riigiteataja.ee/akt/VMS

RESIDENCE PERMITS:
- Temporary: 1-5 years (work, study, family, business)
- Long-term: requires 5 years + A2 Estonian
- Processing: up to 6 months
- Apply: etaotlus.politsei.ee or PPA office

AFTER PERMIT EXPIRES:
- 90 days to regularize or leave (§ 44(4))
- 270 days for special categories

DEPORTATION:
- Appeal deportation order: 10 DAYS to administrative court
- Request interim protection (esialgne õiguskaitse) IMMEDIATELY
- PPA must give written reasoned decision

PRACTICAL:
- If received lahkumisettekirjutus: appeal within 10 days
- Request suspension of enforcement from court
- Contact free legal aid: juristaitab.ee
''';

  /// Rental law key info
  static const String rentalLaw = '''
ÜÜRIÕIGUS (VÕS § 271-332) — Rental Law
URL: https://www.riigiteataja.ee/akt/VÕS

TENANT RIGHTS:
- Landlord must give 3 months written notice (§ 311)
- Max deposit: 3 months rent (§ 308)
- Can terminate immediately if health hazard (§ 317)
- Can challenge unfair termination in court (§ 327)

LANDLORD CAN TERMINATE if:
- Tenant 2+ months behind on rent (§ 316) — must warn first
- Serious breach of contract (§ 313)

RENT INCREASE:
- Must follow regulated procedure (§ 299)
- Can challenge excessive increases (§ 301)

PRACTICAL:
- Always have WRITTEN contract
- Photograph apartment at move-in
- Report defects in writing immediately
- Keep all payment receipts
''';

  /// Inheritance law key info
  static const String inheritanceLaw = '''
PÄRIMISSEADUS (PärS) — Law of Succession
URL: https://www.riigiteataja.ee/akt/PärS

STATUTORY HEIRS (if no will):
- First order: children (equal shares) (§ 13)
- Second order: parents (§ 14)
- Spouse inherits: with children 1/4, with parents 1/2, alone all (§ 16)

WILLS:
- Notarized: before notary (§ 21) — safest
- Holographic: ENTIRELY handwritten, dated, signed (§ 24)

COMPULSORY PORTION:
- If disinherited: can claim 1/2 of statutory share (§ 104)
- Only denied for crimes against testator (§ 108)

CRITICAL DEADLINES:
- Renounce inheritance: 3 MONTHS from learning of death (§ 119)
- If debts exceed assets: RENOUNCE within 3 months!
- Cannot reverse acceptance (§ 116)
- Notary can extend deadline on justified request

NO INHERITANCE TAX IN ESTONIA

Inheritance portal: https://parimine.notar.ee
Notary directory: https://www.notar.ee/et/notarid/nimekiri
''';

  /// Consumer protection key info
  static const String consumerLaw = '''
TARBIJAKAITSE — Consumer Protection
TTJA phone: 667 2000 | Consumer disputes: komisjon.ttja.ee

WARRANTY:
- 2 years from purchase
- First year: seller must prove defect is not manufacturing fault
- Complaint within 2 months of discovering defect
- Seller responds in 15 days
- First: free repair or replacement
- If fails: price reduction or refund

ONLINE SHOPPING:
- 14-day withdrawal right (no reason needed)
- Seller refunds within 14 days of return

DISPUTES:
- Consumer Disputes Commission: FREE, online application
- Alternative to court

PRACTICAL:
- Keep receipts and warranty cards
- Complain in writing
- If seller ignores: file at komisjon.ttja.ee
''';

  /// Administrative procedure key info
  static const String administrativeLaw = '''
HALDUSMENETLUSE SEADUS (HMS) — Administrative Procedure Act
URL: https://www.riigiteataja.ee/akt/HMS

YOUR RIGHTS:
- Right to be heard before decision (§ 40)
- Right to access case files (§ 37)
- Right to written reasoned decision (§ 56)
- Right to challenge (vaie) within 30 days (§ 75)

IF DECISION IS WRONG:
1. File vaie (administrative challenge) within 30 days to the authority
2. Authority decides within 30 days
3. If still wrong: file court action within 30 days (HKMS § 46)
4. Request interim protection if urgent (HKMS § 249)
5. Court fee: only 15-30 EUR (much cheaper than civil court)

PRACTICAL:
- ALWAYS request written decision with reasons
- Decision without reasoning = potentially unlawful (§ 56)
- Not given chance to comment = procedural violation (§ 40)
''';

  /// Discrimination law key info
  static const String discriminationLaw = '''
VÕRDSE KOHTLEMISE SEADUS (VõrdKS) — Equal Treatment Act
URL: https://www.riigiteataja.ee/akt/VõrdKS

PROTECTED GROUNDS:
nationality, ethnicity, race, skin color, religion, age, disability, sexual orientation, DNA

BURDEN OF PROOF:
- You show facts suggesting discrimination (§ 8)
- Employer/service provider must prove it wasn't discrimination
- Refusing to explain = admission of discrimination

DEADLINE: 1 year from learning of damage (§ 25)
EMPLOYER: must respond within 15 working days (§ 7)
DISABILITY: employer must provide reasonable accommodation (§ 11)

WHERE TO COMPLAIN:
- Labor dispute committee (FREE)
- Gender Equality Commissioner
- Chancellor of Justice
- Court
''';
}
