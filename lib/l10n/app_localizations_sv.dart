// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get appTitle => 'Advocat — Juridiskt informationsverktyg';

  @override
  String get onboardingTitle1 => 'AI-driven juridisk information';

  @override
  String get onboardingDesc1 =>
      'Advocat hjälper dig att förstå din juridiska situation. AI-verktyg analyserar dokument, identifierar potentiella problem och förbereder dokumentutkast för din granskning. Inte en advokatbyrå — ett teknikverktyg som stöd för ditt ärende.';

  @override
  String get onboardingTitle2 => 'Skanna och analysera dokument';

  @override
  String get onboardingDesc2 =>
      'Fotografera valfritt juridiskt dokument. AI läser det på flera språk, extraherar viktiga detaljer och kontrollerar mot EU-direktiv och nationell lagstiftning för potentiella problem.';

  @override
  String get onboardingTitle3 => 'AI kontrollerar potentiella problem';

  @override
  String get onboardingDesc3 =>
      'Våra AI-verktyg kontrollerar över 40 typer av procedurkrav. AI-analysen kan identifiera frågor som kräver uppmärksamhet — såsom delgivningsspråk, procedursteg och juridiska tidsfrister. Verifiera alltid med en kvalificerad jurist.';

  @override
  String get onboardingTitle4 => 'Dokumentutkast för din granskning';

  @override
  String get onboardingDesc4 =>
      'AI förbereder utkast till överklaganden, klagomål och brev med juridiska hänvisningar för din granskning. Du bestämmer vad som ska lämnas in. Varje dokument bör granskas av en kvalificerad jurist innan det lämnas in.';

  @override
  String get onboardingNext => 'Nästa';

  @override
  String get onboardingSkip => 'Hoppa över';

  @override
  String get getStarted => 'Kom igång';

  @override
  String get welcomeBack => 'Välkommen tillbaka';

  @override
  String get signInSubtitle => 'Logga in för att komma åt dina ärenden';

  @override
  String get signIn => 'Logga in';

  @override
  String get logIn => 'Logga in';

  @override
  String get signUp => 'Skapa konto';

  @override
  String get createAccount => 'Skapa konto';

  @override
  String get email => 'E-post';

  @override
  String get password => 'Lösenord';

  @override
  String get confirmPassword => 'Bekräfta lösenord';

  @override
  String get fullName => 'Fullständigt namn';

  @override
  String get forgotPassword => 'Glömt lösenord?';

  @override
  String get orDivider => 'eller';

  @override
  String get continueWithGoogle => 'Fortsätt med Google';

  @override
  String get noAccount => 'Har du inget konto? ';

  @override
  String get signUpLink => 'Registrera dig';

  @override
  String get alreadyHaveAccount => 'Har du redan ett konto? ';

  @override
  String get signInLink => 'Logga in';

  @override
  String get emailRequired => 'E-postadress krävs';

  @override
  String get emailInvalid => 'Ange en giltig e-postadress';

  @override
  String get passwordRequired => 'Lösenord krävs';

  @override
  String get passwordTooShort => 'Lösenordet måste vara minst 8 tecken';

  @override
  String get passwordsDoNotMatch => 'Lösenorden stämmer inte överens';

  @override
  String get nameRequired => 'Fullständigt namn krävs';

  @override
  String get termsRequired => 'Du måste godkänna användarvillkoren';

  @override
  String get agreeToTerms => 'Jag godkänner ';

  @override
  String get termsOfService => 'Användarvillkor';

  @override
  String get andWord => ' och ';

  @override
  String get privacyPolicy => 'Integritetspolicy';

  @override
  String get preferredLanguage => 'Föredraget språk';

  @override
  String get langEnglish => 'Engelska';

  @override
  String get langRussian => 'Ryska';

  @override
  String get langFinnish => 'Finska';

  @override
  String get passwordStrengthWeak => 'Svagt';

  @override
  String get passwordStrengthMedium => 'Medel';

  @override
  String get passwordStrengthStrong => 'Starkt';

  @override
  String get loginFailed => 'Ogiltig e-postadress eller lösenord. Försök igen.';

  @override
  String get registerFailed => 'Registreringen misslyckades. Försök igen.';

  @override
  String get resetPasswordSent =>
      'Länk för återställning av lösenord har skickats till din e-post.';

  @override
  String get resetPasswordFailed =>
      'Det gick inte att skicka återställningslänken. Försök igen.';

  @override
  String get myCases => 'Mina ärenden';

  @override
  String get newCase => 'Nytt ärende';

  @override
  String get noCases => 'Inga ärenden ännu';

  @override
  String get documents => 'Dokument';

  @override
  String get timeline => 'Tidslinje';

  @override
  String get aiAssistant => 'AI Juridisk Assistent';

  @override
  String get settings => 'Inställningar';

  @override
  String get language => 'Språk';

  @override
  String get subscription => 'Prenumeration';

  @override
  String get signOut => 'Logga ut';

  @override
  String get disclaimer =>
      'Enbart AI-vägledning – inte juridisk rådgivning. Rådgör alltid med en jurist.';

  @override
  String get scanDocument => 'Skanna dokument';

  @override
  String get camera => 'Kamera';

  @override
  String get gallery => 'Galleri';

  @override
  String get saveAndAnalyze => 'Spara och analysera';

  @override
  String get retry => 'Försök igen';

  @override
  String get cancel => 'Avbryt';

  @override
  String get confirm => 'Bekräfta';

  @override
  String get error => 'Fel';

  @override
  String get loading => 'Laddar...';

  @override
  String get home => 'Hem';

  @override
  String get cases => 'Ärenden';

  @override
  String get deadlines => 'Tidsfrister';

  @override
  String get scan => 'Skanna';

  @override
  String goodMorning(String name) {
    return 'God morgon, $name';
  }

  @override
  String goodAfternoon(String name) {
    return 'God eftermiddag, $name';
  }

  @override
  String goodEvening(String name) {
    return 'God kväll, $name';
  }

  @override
  String get caseOverview => 'Ärendeöversikt';

  @override
  String get activeCases => 'Aktiva ärenden';

  @override
  String get recentActivity => 'Senaste aktivitet';

  @override
  String urgentDeadline(String title) {
    return 'Brådskande: $title';
  }

  @override
  String daysRemaining(int count) {
    return '$count dagar';
  }

  @override
  String get overdue => 'Försenad';

  @override
  String get upcoming => 'Kommande';

  @override
  String get completed => 'Avslutad';

  @override
  String get markComplete => 'Markera som avslutad';

  @override
  String get deportation => 'Utvisning';

  @override
  String get criminalCase => 'Brottmål';

  @override
  String get asylum => 'Asyl';

  @override
  String get residencePermit => 'Uppehållstillstånd';

  @override
  String get victimSupport => 'Brottsofferstöd';

  @override
  String get familyReunification => 'Familjeåterförening';

  @override
  String get laborDispute => 'Arbetsrättsliga tvister';

  @override
  String get tenantRights => 'Hyresgästens rättigheter';

  @override
  String get debtCollection => 'Inkasso';

  @override
  String get discrimination => 'Diskriminering';

  @override
  String get policeMisconduct => 'Polisens agerande';

  @override
  String get socialBenefits => 'Sociala förmåner';

  @override
  String get other => 'Övrigt';

  @override
  String get caseDetail => 'Ärendedetaljer';

  @override
  String get aiAnalysis => 'AI-analys';

  @override
  String get draftAppeal => 'Utkast till överklagande';

  @override
  String get aiChat => 'AI-chatt';

  @override
  String get correspondence => 'Korrespondens';

  @override
  String get analyzing => 'Analyserar';

  @override
  String get readingDocument => 'Läser dokument';

  @override
  String get checkingErrors => 'Kontrollerar fel';

  @override
  String get researchingLaw => 'Undersöker lagstiftning';

  @override
  String issuesFound(int count) {
    return '$count problem hittade';
  }

  @override
  String get critical => 'Kritiskt';

  @override
  String get important => 'Viktigt';

  @override
  String get informational => 'Information';

  @override
  String get useInAppeal => 'Använd i överklagande';

  @override
  String get addedToAppeal => 'Tillagd i överklagande';

  @override
  String get generateAppeal => 'Generera överklagande';

  @override
  String get exportPdf => 'Exportera PDF';

  @override
  String get sendViaEmail => 'Skicka via e-post';

  @override
  String get copyText => 'Kopiera text';

  @override
  String get editDraft => 'Redigera utkast';

  @override
  String get saveDraft => 'Spara utkast';

  @override
  String get reviewWarning => 'Granska varning';

  @override
  String get disclaimerFull =>
      'Detta är AI-genererad vägledning och utgör inte juridisk rådgivning. Allt material bör granskas av en behörig jurist innan det används i rättsliga sammanhang.';

  @override
  String get askAboutCase => 'Fråga om ärendet';

  @override
  String get whatAreMyOptions => 'Vilka är mina alternativ?';

  @override
  String get checkDeadlines => 'Kontrollera tidsfrister';

  @override
  String get typeMessage => 'Skriv ett meddelande';

  @override
  String get connectEmail => 'Anslut e-post';

  @override
  String get connectGmail => 'Anslut Gmail';

  @override
  String get connectOutlook => 'Anslut Outlook';

  @override
  String get emailConnected => 'E-post ansluten';

  @override
  String get syncNow => 'Synkronisera nu';

  @override
  String get disconnect => 'Koppla från';

  @override
  String get emailPrivacyNote =>
      'Din e-post används enbart för ärenderelaterad korrespondens och lagras säkert.';

  @override
  String get pushNotifications => 'Push-notiser';

  @override
  String get deadlineReminders => 'Påminnelser om tidsfrister';

  @override
  String get deadlineRemindersDesc =>
      'Få påminnelser innan viktiga tidsfrister löper ut';

  @override
  String get editProfile => 'Redigera profil';

  @override
  String get exportMyData => 'Exportera mina uppgifter';

  @override
  String get exportDataDesc => 'Ladda ner alla dina ärendedata och dokument';

  @override
  String get deleteAccount => 'Radera konto';

  @override
  String get deleteAccountDesc =>
      'Radera permanent ditt konto och alla uppgifter';

  @override
  String get deleteConfirm =>
      'Är du säker på att du vill radera ditt konto? Denna åtgärd kan inte ångras.';

  @override
  String get about => 'Om';

  @override
  String get version => 'Version';

  @override
  String get rateUs => 'Betygsätt oss';

  @override
  String get contactSupport => 'Kontakta support';

  @override
  String get tryDemoMode => 'Prova demoläge';

  @override
  String get demoModeDesc =>
      'Utforska appen med exempeldata utan att skapa ett konto';

  @override
  String get free => 'Gratis';

  @override
  String get basic => 'Bas';

  @override
  String get pro => 'Pro';

  @override
  String get emergencyShield => 'Akutskydd';

  @override
  String get legalFighter => 'Juridisk Kämpe';

  @override
  String get fullDefense => 'Fullständigt Försvar';

  @override
  String get popular => 'Populär';

  @override
  String get currentPlan => 'Nuvarande plan';

  @override
  String get choosePlan => 'Välj plan';

  @override
  String get saveWithAnnual => 'Spara med årsbetalning';

  @override
  String get restorePurchases => 'Återställ köp';

  @override
  String get country => 'Land';

  @override
  String get caseDescription => 'Ärendebeskrivning';

  @override
  String get caseTitle => 'Ärendetitel';

  @override
  String get referenceNumber => 'Referensnummer';

  @override
  String get uploadDocument => 'Ladda upp dokument';

  @override
  String get optional => 'Valfritt';

  @override
  String step(int current, int total) {
    return 'Steg $current av $total';
  }

  @override
  String get next => 'Nästa';

  @override
  String get back => 'Tillbaka';

  @override
  String get createCase => 'Skapa ärende';

  @override
  String get searchCases => 'Sök ärenden';

  @override
  String get all => 'Alla';

  @override
  String get active => 'Aktiva';

  @override
  String get closed => 'Avslutade';

  @override
  String lastActivity(String time) {
    return 'Senaste aktivitet: $time';
  }

  @override
  String documentsCount(int count) {
    return '$count dokument';
  }

  @override
  String get noCasesYet => 'Inga ärenden ännu';

  @override
  String get startFirstCase => 'Skapa ditt första ärende';

  @override
  String get noDeadlines => 'Inga tidsfrister';

  @override
  String get appealFiled => 'Överklagande inlämnat';

  @override
  String get pendingDecision => 'Inväntar beslut';

  @override
  String get inProgress => 'Pågående';

  @override
  String get won => 'Vunnet';

  @override
  String get lost => 'Förlorat';

  @override
  String get preferences => 'INSTÄLLNINGAR';

  @override
  String get notifications => 'AVISERINGAR';

  @override
  String get emailIntegration => 'E-POSTINTEGRATION';

  @override
  String get dataAndPrivacy => 'DATA OCH INTEGRITET';

  @override
  String get legalSection => 'JURIDISKT';

  @override
  String get aboutSection => 'OM';

  @override
  String get appVersion => 'Appversion';

  @override
  String get selectLanguage => 'Välj språk';

  @override
  String get signOutConfirm => 'Är du säker på att du vill logga ut?';

  @override
  String get emailDisconnected => 'E-post frånkopplad';

  @override
  String get syncLegalCorrespondence => 'Synkronisera juridisk korrespondens';

  @override
  String get requestExport => 'Begär export';

  @override
  String get exportDataDialogContent =>
      'Vi förbereder en nedladdning av alla dina uppgifter inklusive ärenden, dokument och korrespondens. Du får ett e-postmeddelande när det är klart.';

  @override
  String get deleteAccountDialogContent =>
      'Denna åtgärd är permanent och kan inte ångras. Alla dina uppgifter, ärenden och dokument raderas permanent.';

  @override
  String get areYouAbsolutelySure => 'Är du helt säker?';

  @override
  String get typeDeleteToConfirm =>
      'Skriv DELETE för att bekräfta permanent kontoradering.';

  @override
  String get permanentlyDelete => 'Radera permanent';

  @override
  String get dataExportRequested =>
      'Dataexport begärd. Kontrollera din e-post.';

  @override
  String get connected => 'Ansluten';

  @override
  String get caseUpdated => 'Ärende uppdaterat';

  @override
  String get noRecentActivity => 'Ingen senaste aktivitet';

  @override
  String get couldNotLoadCases => 'Kunde inte ladda dina ärenden';

  @override
  String get viewAll => 'Visa alla';

  @override
  String get checkCompany => 'Check Company';

  @override
  String get checkVehicle => 'Check Vehicle';

  @override
  String get companyName => 'Company name or reg. number';

  @override
  String get selectCountry => 'Select country';

  @override
  String get riskLow => 'Safe to work with';

  @override
  String get riskMedium => 'Proceed with caution';

  @override
  String get riskHigh => 'High risk — avoid';

  @override
  String get perCheck => 'per check';

  @override
  String get checkerTitle => 'Checker';

  @override
  String get beforeYouWork => 'Before you work with them';

  @override
  String get beforeYouBuy => 'Before you buy';

  @override
  String get vehicleChecker => 'Vehicle Checker';

  @override
  String get licensePlate => 'License plate';

  @override
  String get vinNumber => 'VIN number';

  @override
  String get vehicleMake => 'Make';

  @override
  String get vehicleModel => 'Model';

  @override
  String get vehicleYear => 'Year';

  @override
  String get vehicleColor => 'Color';

  @override
  String get vehicleChecks => 'Status Checks';

  @override
  String get mileage => 'Mileage';

  @override
  String get accidents => 'Accidents';

  @override
  String get owners => 'Previous owners';

  @override
  String get insurance => 'Insurance';

  @override
  String get inspection => 'Technical inspection';

  @override
  String get stolen => 'Stolen check';

  @override
  String get safeToBuy => 'Safe to buy';

  @override
  String get someConcerns => 'Some concerns';

  @override
  String get doNotBuy => 'Do not buy';

  @override
  String get pricePerCheck => '€4.99 per check';

  @override
  String get demoHint => 'Demo: try plate \"908FBT\"';

  @override
  String get reportFraud => 'Report Fraud';

  @override
  String get openACase => 'Open a Case';
}
