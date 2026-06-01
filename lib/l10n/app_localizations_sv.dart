// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get about => 'Om';

  @override
  String get aboutSection => 'OM';

  @override
  String get appearance => 'Appearance';

  @override
  String get appearanceSystem => 'System (auto)';

  @override
  String get appearanceLight => 'Light';

  @override
  String get appearanceDark => 'Dark';

  @override
  String get appearanceDescription => 'Choose how Advocat looks';

  @override
  String get accidents => 'Olyckor';

  @override
  String get active => 'Aktiva';

  @override
  String get activeCases => 'Aktiva ärenden';

  @override
  String get addedToAppeal => 'Tillagd i överklagande';

  @override
  String get agreeToTerms => 'Jag godkänner ';

  @override
  String get aiAnalysis => 'AI-analys';

  @override
  String get aiAssistant => 'AI Juridisk Assistent';

  @override
  String get aiChat => 'AI-chatt';

  @override
  String get all => 'Alla';

  @override
  String get alreadyHaveAccount => 'Har du redan ett konto? ';

  @override
  String get analyzing => 'Analyserar';

  @override
  String get aiAnalyzing => 'AI is analyzing';

  @override
  String get speakIntoMicHint =>
      'Speak into the microphone. Make sure microphone access is enabled.';

  @override
  String get aiErrorRateLimit =>
      'Tjänsten är tillfälligt överbelastad. Försök igen om 1–2 minuter.';

  @override
  String get aiErrorOverload =>
      'AI:n är upptagen just nu, försök igen om en minut.';

  @override
  String freeLimitReached(int count) {
    return 'You have used all $count free AI messages. Upgrade to Legal Counsel for unlimited AI assistance!';
  }

  @override
  String get andWord => ' och ';

  @override
  String get appTitle => 'Advocat — Juridiskt informationsverktyg';

  @override
  String get appVersion => 'Appversion';

  @override
  String get appealFiled => 'Överklagande inlämnat';

  @override
  String get areYouAbsolutelySure => 'Är du helt säker?';

  @override
  String get askAboutCase => 'Fråga om ärendet';

  @override
  String get asylum => 'Asyl';

  @override
  String get back => 'Tillbaka';

  @override
  String get basic => 'Bas';

  @override
  String get beforeYouBuy => 'Innan du köper';

  @override
  String get beforeYouWork => 'Innan du samarbetar med dem';

  @override
  String get camera => 'Kamera';

  @override
  String get cancel => 'Avbryt';

  @override
  String get caseDescription => 'Ärendebeskrivning';

  @override
  String get caseDetail => 'Ärendedetaljer';

  @override
  String get caseOverview => 'Ärendeöversikt';

  @override
  String get caseTitle => 'Ärendetitel';

  @override
  String get caseUpdated => 'Ärende uppdaterat';

  @override
  String get cases => 'Ärenden';

  @override
  String get checkCompany => 'Kontrollera företag';

  @override
  String get checkDeadlines => 'Kontrollera tidsfrister';

  @override
  String get checkVehicle => 'Kontrollera fordon';

  @override
  String get checkerTitle => 'Kontrollör';

  @override
  String get checkingErrors => 'Kontrollerar fel';

  @override
  String get choosePlan => 'Välj plan';

  @override
  String get closed => 'Avslutade';

  @override
  String get companyName => 'Företagsnamn eller org.nr.';

  @override
  String get completed => 'Avslutad';

  @override
  String get confirm => 'Bekräfta';

  @override
  String get confirmPassword => 'Bekräfta lösenord';

  @override
  String get connectEmail => 'Anslut e-post';

  @override
  String get connectGmail => 'Anslut Gmail';

  @override
  String get connectOutlook => 'Anslut Outlook';

  @override
  String get connected => 'Ansluten';

  @override
  String get contactSupport => 'Kontakta support';

  @override
  String get continueWithGoogle => 'Fortsätt med Google';

  @override
  String get appleComingSoon => 'Kommer snart';

  @override
  String get appleComingSoonMessage =>
      'Logga in med Apple blir tillgängligt snart. Använd Google eller e-post för att fortsätta.';

  @override
  String get copyText => 'Kopiera text';

  @override
  String get correspondence => 'Korrespondens';

  @override
  String get couldNotLoadCases => 'Kunde inte ladda dina ärenden';

  @override
  String get country => 'Land';

  @override
  String get createAccount => 'Skapa konto';

  @override
  String get createCase => 'Skapa ärende';

  @override
  String get criminalCase => 'Brottmål';

  @override
  String get critical => 'Kritiskt';

  @override
  String get currentPlan => 'Nuvarande plan';

  @override
  String get dataAndPrivacy => 'DATA OCH INTEGRITET';

  @override
  String get dataExportRequested =>
      'Dataexport begärd. Kontrollera din e-post.';

  @override
  String daysRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dagar',
      one: '1 dag',
      zero: 'inga dagar kvar',
    );
    return '$_temp0';
  }

  @override
  String get deadlineReminders => 'Påminnelser om tidsfrister';

  @override
  String get deadlineRemindersDesc =>
      'Få påminnelser innan viktiga tidsfrister löper ut';

  @override
  String get deadlines => 'Tidsfrister';

  @override
  String get debtCollection => 'Inkasso';

  @override
  String get deleteAccount => 'Radera konto';

  @override
  String get deleteAccountDesc =>
      'Radera permanent ditt konto och alla uppgifter';

  @override
  String get deleteAccountDialogContent =>
      'Denna åtgärd är permanent och kan inte ångras. Alla dina uppgifter, ärenden och dokument raderas permanent.';

  @override
  String get deleteConfirm =>
      'Är du säker på att du vill radera ditt konto? Denna åtgärd kan inte ångras.';

  @override
  String get demoHint => 'Demo: prova registreringsnummer ”908FBT”';

  @override
  String get demoModeDesc =>
      'Utforska appen med exempeldata utan att skapa ett konto';

  @override
  String get deportation => 'Utvisning';

  @override
  String get disclaimer =>
      'Enbart AI-vägledning – inte juridisk rådgivning. Rådgör alltid med en jurist.';

  @override
  String get disclaimerFull =>
      'Detta är AI-genererad vägledning och utgör inte juridisk rådgivning. Allt material bör granskas av en behörig jurist innan det används i rättsliga sammanhang.';

  @override
  String get disconnect => 'Koppla från';

  @override
  String get discrimination => 'Diskriminering';

  @override
  String get doNotBuy => 'Köp inte';

  @override
  String get documents => 'Dokument';

  @override
  String documentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dokument',
      one: '1 dokument',
      zero: 'inga dokument',
    );
    return '$_temp0';
  }

  @override
  String get draftAppeal => 'Utkast till överklagande';

  @override
  String get editDraft => 'Redigera utkast';

  @override
  String get editProfile => 'Redigera profil';

  @override
  String get email => 'E-post';

  @override
  String get emailConnected => 'E-post ansluten';

  @override
  String get emailDisconnected => 'E-post frånkopplad';

  @override
  String get emailIntegration => 'E-POSTINTEGRATION';

  @override
  String get emailInvalid => 'Ange en giltig e-postadress';

  @override
  String get emailPrivacyNote =>
      'Din e-post används enbart för ärenderelaterad korrespondens och lagras säkert.';

  @override
  String get emailRequired => 'E-postadress krävs';

  @override
  String get emergencyShield => 'Akutskydd';

  @override
  String get error => 'Fel';

  @override
  String get exportDataDesc => 'Ladda ner alla dina ärendedata och dokument';

  @override
  String get exportDataDialogContent =>
      'Vi förbereder en nedladdning av alla dina uppgifter inklusive ärenden, dokument och korrespondens. Du får ett e-postmeddelande när det är klart.';

  @override
  String get exportMyData => 'Exportera mina uppgifter';

  @override
  String get exportPdf => 'Exportera PDF';

  @override
  String get familyReunification => 'Familjeåterförening';

  @override
  String get forgotPassword => 'Glömt lösenord?';

  @override
  String get free => 'Gratis';

  @override
  String get fullDefense => 'Advocat Pro';

  @override
  String get fullName => 'Fullständigt namn';

  @override
  String get gallery => 'Galleri';

  @override
  String get generateAppeal => 'Generera överklagande';

  @override
  String get getStarted => 'Kom igång';

  @override
  String goodAfternoon(String name) {
    return 'God eftermiddag, $name';
  }

  @override
  String goodEvening(String name) {
    return 'God kväll, $name';
  }

  @override
  String goodMorning(String name) {
    return 'God morgon, $name';
  }

  @override
  String goodNight(String name) {
    return 'God natt, $name';
  }

  @override
  String get home => 'Hem';

  @override
  String get important => 'Viktigt';

  @override
  String get inProgress => 'Pågående';

  @override
  String get informational => 'Information';

  @override
  String get inspection => 'Teknisk besiktning';

  @override
  String get insurance => 'Försäkring';

  @override
  String issuesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count problem hittade',
      one: '1 problem hittat',
      zero: 'inga problem hittades',
    );
    return '$_temp0';
  }

  @override
  String get laborDispute => 'Arbetsrättsliga tvister';

  @override
  String get langEnglish => 'Engelska';

  @override
  String get langFinnish => 'Finska';

  @override
  String get langRussian => 'Ryska';

  @override
  String get language => 'Språk';

  @override
  String lastActivity(String time) {
    return 'Senaste aktivitet: $time';
  }

  @override
  String get legalFighter => 'Juridisk Kämpe';

  @override
  String get legalSection => 'JURIDISKT';

  @override
  String get licensePlate => 'Registreringsnummer';

  @override
  String get loading => 'Laddar…';

  @override
  String get logIn => 'Logga in';

  @override
  String get loginFailed => 'Ogiltig e-postadress eller lösenord. Försök igen.';

  @override
  String get lost => 'Förlorat';

  @override
  String get markComplete => 'Markera som avslutad';

  @override
  String get mileage => 'Mätarställning';

  @override
  String get myCases => 'Mina ärenden';

  @override
  String get nameRequired => 'Fullständigt namn krävs';

  @override
  String get newCase => 'Nytt ärende';

  @override
  String get next => 'Nästa';

  @override
  String get noAccount => 'Har du inget konto? ';

  @override
  String get noCases => 'Inga ärenden ännu';

  @override
  String get noCasesYet => 'Inga ärenden ännu';

  @override
  String get noDeadlines => 'Inga tidsfrister';

  @override
  String get noRecentActivity => 'Ingen senaste aktivitet';

  @override
  String get notifications => 'AVISERINGAR';

  @override
  String get onboardingDesc1 =>
      'Advocat hjälper dig att förstå din juridiska situation. AI-verktyg analyserar dokument, identifierar potentiella problem och förbereder dokumentutkast för din granskning. Inte en advokatbyrå — ett teknikverktyg som stöd för ditt ärende.';

  @override
  String get onboardingDesc2 =>
      'Fotografera valfritt juridiskt dokument. AI läser det på flera språk, extraherar viktiga detaljer och kontrollerar mot EU-direktiv och nationell lagstiftning för potentiella problem.';

  @override
  String get onboardingDesc3 =>
      'Våra AI-verktyg kontrollerar över 40 typer av procedurkrav. AI-analysen kan identifiera frågor som kräver uppmärksamhet — såsom delgivningsspråk, procedursteg och juridiska tidsfrister. Verifiera alltid med en kvalificerad jurist.';

  @override
  String get onboardingDesc4 =>
      'AI förbereder utkast till överklaganden, klagomål och brev med juridiska hänvisningar för din granskning. Du bestämmer vad som ska lämnas in. Varje dokument bör granskas av en kvalificerad jurist innan det lämnas in.';

  @override
  String get onboardingNext => 'Nästa';

  @override
  String get onboardingSkip => 'Hoppa över';

  @override
  String get onboardingTitle1 => 'AI-driven juridisk information';

  @override
  String get onboardingTitle2 => 'Skanna och analysera dokument';

  @override
  String get onboardingTitle3 => 'AI kontrollerar potentiella problem';

  @override
  String get onboardingTitle4 => 'Dokumentutkast för din granskning';

  @override
  String get openACase => 'Öppna ett ärende';

  @override
  String get optional => 'Valfritt';

  @override
  String get orDivider => 'eller';

  @override
  String get other => 'Övrigt';

  @override
  String get overdue => 'Försenad';

  @override
  String get owners => 'Tidigare ägare';

  @override
  String get password => 'Lösenord';

  @override
  String get passwordRequired => 'Lösenord krävs';

  @override
  String get passwordStrengthMedium => 'Medel';

  @override
  String get passwordStrengthStrong => 'Starkt';

  @override
  String get passwordStrengthWeak => 'Svagt';

  @override
  String get passwordTooShort => 'Lösenordet måste vara minst 8 tecken';

  @override
  String get passwordsDoNotMatch => 'Lösenorden stämmer inte överens';

  @override
  String get pendingDecision => 'Inväntar beslut';

  @override
  String get perCheck => 'per kontroll';

  @override
  String get permanentlyDelete => 'Radera permanent';

  @override
  String get policeMisconduct => 'Polisens agerande';

  @override
  String get popular => 'Populär';

  @override
  String get preferences => 'INSTÄLLNINGAR';

  @override
  String get preferredLanguage => 'Föredraget språk';

  @override
  String get pricePerCheck => '4,99 € per kontroll';

  @override
  String get privacyPolicy => 'Integritetspolicy';

  @override
  String get dpaTitle => 'Personuppgiftsbiträdesavtal';

  @override
  String get dpaCheckoutGateTitle => 'Innan du uppgraderar';

  @override
  String get dpaCheckoutGateBody =>
      'EU-rätten (GDPR art. 28) kräver att vi tecknar ett personuppgiftsbiträdesavtal med varje betalande kund. Läs igenom och godkänn.';

  @override
  String get dpaViewLink => 'Visa personuppgiftsbiträdesavtal';

  @override
  String get dpaCheckboxLabel =>
      'Jag har läst och godkänner personuppgiftsbiträdesavtalet (v1.0).';

  @override
  String get dpaCancel => 'Avbryt';

  @override
  String get dpaAcceptAndContinue => 'Godkänn och fortsätt';

  @override
  String get dpaOpenHint =>
      'Öppna personuppgiftsbiträdesavtalet minst en gång för att aktivera knappen Godkänn.';

  @override
  String get pro => 'Pro';

  @override
  String get pushNotifications => 'Push-notiser';

  @override
  String get rateUs => 'Betygsätt oss';

  @override
  String get rateAppComingSoon => 'Coming to app stores soon!';

  @override
  String get dataCopiedToClipboard => 'Data copied to clipboard';

  @override
  String get readingDocument => 'Läser dokument';

  @override
  String get recentActivity => 'Senaste aktivitet';

  @override
  String get referenceNumber => 'Referensnummer';

  @override
  String get registerFailed => 'Registreringen misslyckades. Försök igen.';

  @override
  String get reportFraud => 'Rapportera bedrägeri';

  @override
  String get requestExport => 'Begär export';

  @override
  String get researchingLaw => 'Undersöker lagstiftning';

  @override
  String get resetPasswordFailed =>
      'Det gick inte att skicka återställningslänken. Försök igen.';

  @override
  String get resetPasswordSent =>
      'Länk för återställning av lösenord har skickats till din e-post.';

  @override
  String get residencePermit => 'Uppehållstillstånd';

  @override
  String get manageSubscription => 'Hantera prenumeration';

  @override
  String get restorePurchases => 'Återställ köp';

  @override
  String get retry => 'Försök igen';

  @override
  String get reviewWarning => 'Granska varning';

  @override
  String get riskHigh => 'Hög risk — undvik';

  @override
  String get riskLow => 'Säkert att samarbeta med';

  @override
  String get riskMedium => 'Fortsätt med försiktighet';

  @override
  String get safeToBuy => 'Säkert att köpa';

  @override
  String get saveAndAnalyze => 'Spara och analysera';

  @override
  String get saveDraft => 'Spara utkast';

  @override
  String get saveWithAnnual => 'Spara med årsbetalning';

  @override
  String get scan => 'Skanna';

  @override
  String get scanDocument => 'Skanna dokument';

  @override
  String get searchCases => 'Sök ärenden';

  @override
  String get selectCountry => 'Välj land';

  @override
  String get selectLanguage => 'Välj språk';

  @override
  String get sendViaEmail => 'Skicka via e-post';

  @override
  String get settings => 'Inställningar';

  @override
  String get signIn => 'Logga in';

  @override
  String get signInLink => 'Logga in';

  @override
  String get signInSubtitle => 'Logga in för att komma åt dina ärenden';

  @override
  String get signOut => 'Logga ut';

  @override
  String get signOutConfirm => 'Är du säker på att du vill logga ut?';

  @override
  String get signUp => 'Skapa konto';

  @override
  String get signUpLink => 'Registrera dig';

  @override
  String get socialBenefits => 'Sociala förmåner';

  @override
  String get someConcerns => 'Vissa farhågor';

  @override
  String get startFirstCase => 'Skapa ditt första ärende';

  @override
  String step(int current, int total) {
    return 'Steg $current av $total';
  }

  @override
  String get stolen => 'Stöldkontroll';

  @override
  String get subscription => 'Prenumeration';

  @override
  String get syncLegalCorrespondence => 'Synkronisera juridisk korrespondens';

  @override
  String get syncNow => 'Synkronisera nu';

  @override
  String get tenantRights => 'Hyresgästens rättigheter';

  @override
  String get termsOfService => 'Användarvillkor';

  @override
  String get termsRequired => 'Du måste godkänna användarvillkoren';

  @override
  String get timeline => 'Tidslinje';

  @override
  String get tryDemoMode => 'Prova demoläge';

  @override
  String get typeDeleteToConfirm =>
      'Skriv DELETE för att bekräfta permanent kontoradering.';

  @override
  String get typeMessage => 'Skriv ett meddelande';

  @override
  String get upcoming => 'Kommande';

  @override
  String get uploadDocument => 'Ladda upp dokument';

  @override
  String urgentDeadline(String title) {
    return 'Brådskande: $title';
  }

  @override
  String get useInAppeal => 'Använd i överklagande';

  @override
  String get vehicleChecker => 'Fordonskontroll';

  @override
  String get vehicleChecks => 'Statuskontroller';

  @override
  String get vehicleColor => 'Färg';

  @override
  String get vehicleMake => 'Märke';

  @override
  String get vehicleModel => 'Modell';

  @override
  String get vehicleYear => 'Årsmodell';

  @override
  String get version => 'Version';

  @override
  String get victimSupport => 'Brottsofferstöd';

  @override
  String get viewAll => 'Visa alla';

  @override
  String get vinNumber => 'VIN-nummer';

  @override
  String get welcomeBack => 'Välkommen tillbaka';

  @override
  String get whatAreMyOptions => 'Vilka är mina alternativ?';

  @override
  String get won => 'Vunnet';

  @override
  String get documentVault => 'Dokumentvalv';

  @override
  String get secureDocumentStorage => 'Säker dokumentförvaring';

  @override
  String get secureDocumentStorageDesc =>
      'Förvara dina viktiga juridiska dokument på ett ställe.';

  @override
  String get addDocument => 'Lägg till dokument';

  @override
  String get chooseHowToAdd => 'Välj hur du vill lägga till ditt dokument';

  @override
  String get uploadFile => 'Ladda upp fil';

  @override
  String get uploadFileDesc => 'Välj en PDF eller bild från din enhet';

  @override
  String get scanDocumentDesc => 'Ta ett foto av ditt dokument';

  @override
  String get createNote => 'Skapa anteckning';

  @override
  String get createNoteDesc =>
      'Skriv en anteckning eller registrera viktiga detaljer';

  @override
  String get knowYourRights => 'Känn dina rättigheter';

  @override
  String get stoppedByPolice => 'Stoppad av polisen';

  @override
  String get stoppedByPoliceDesc => 'Dina rättigheter vid poliskontroll';

  @override
  String get deportationNotice => 'Utvisningsbeslut';

  @override
  String get deportationNoticeDesc =>
      'Steg för att överklaga ett utvisningsbeslut';

  @override
  String get workplaceRights => 'Arbetsplatsrättigheter';

  @override
  String get workplaceRightsDesc => 'Arbetsrättsligt skydd i Finland';

  @override
  String get tenantRightsDesc => 'Bostads- och hyresskydd';

  @override
  String get immigrationDetention => 'Migrationsförvar';

  @override
  String get immigrationDetentionDesc =>
      'Rättigheter vid frihetsberövande av myndigheter';

  @override
  String get discriminationDesc =>
      'Hur man rapporterar och bekämpar diskriminering';

  @override
  String get scenarioNotFound => 'Scenario hittades inte';

  @override
  String get youHaveRightTo => 'Du har rätt att:';

  @override
  String get youMust => 'Du måste:';

  @override
  String get immediateSteps => 'Omedelbara steg:';

  @override
  String get yourRights => 'Dina rättigheter:';

  @override
  String get basicRights => 'Grundläggande rättigheter:';

  @override
  String get yourRightsAsTenant => 'Dina rättigheter som hyresgäst:';

  @override
  String get yourRightsInDetention => 'Dina rättigheter i förvar:';

  @override
  String get howToAct => 'Hur du ska agera:';

  @override
  String get rightKnowWhyStopped => 'Veta varför du stoppas';

  @override
  String get rightRemainSilent => 'Tiga (du måste identifiera dig)';

  @override
  String get rightAskInterpreter => 'Be om tolk';

  @override
  String get rightContactLawyer => 'Kontakta advokat innan förhör';

  @override
  String get rightRecordEncounter => 'Spela in mötet (på offentliga platser)';

  @override
  String get mustProvideName => 'Ange ditt namn och födelsedatum';

  @override
  String get mustShowId => 'Visa legitimation om du har';

  @override
  String get mustNotResist => 'Inte göra fysiskt motstånd';

  @override
  String get doNotIgnoreNotice =>
      'Ignorera INTE beslutet - tidsfristerna är strikta';

  @override
  String get noteAppealDeadline =>
      'Notera överklagandefristen (vanligtvis 30 dagar)';

  @override
  String get contactLawyerImmediately => 'Kontakta omedelbart en advokat';

  @override
  String get applyLegalAid => 'Ansök om rättshjälp vid behov';

  @override
  String get rightAppealAdmin =>
      'Rätt att överklaga till förvaltningsdomstolen';

  @override
  String get rightLegalRep => 'Rätt till juridiskt ombud';

  @override
  String get rightInterpreter => 'Rätt till tolk';

  @override
  String get rightStayDuringAppeal =>
      'Rätt att stanna under överklagande (i de flesta fall)';

  @override
  String get minimumWage => 'Minimilön enligt kollektivavtal';

  @override
  String get workingTimeLimits => 'Arbetstidsgränser (max 8t/dag, 40t/vecka)';

  @override
  String get annualLeave => 'Semester (minst 2 dagar per arbetad månad)';

  @override
  String get sickLeave => 'Sjukersättning';

  @override
  String get safeWorkingConditions => 'Säkra arbetsförhållanden';

  @override
  String get writtenRentalAgreement => 'Skriftligt hyresavtal krävs';

  @override
  String get securityDeposit => 'Deposition max 3 månaders hyra';

  @override
  String get landlordNotice =>
      'Hyresvärden måste ge uppsägningstid (3–6 månader)';

  @override
  String get rightHabitableDwelling => 'Rätt till en beboelig bostad';

  @override
  String get protectionUnjustEviction => 'Skydd mot orättvis vräkning';

  @override
  String get rightKnowDetentionReason =>
      'Rätt att veta orsaken till frihetsberövande';

  @override
  String get rightContactLawyerDetention => 'Rätt att kontakta en advokat';

  @override
  String get rightContactEmbassy => 'Rätt att kontakta din ambassad';

  @override
  String get rightChallengeDetention =>
      'Rätt att överklaga frihetsberövande i domstol';

  @override
  String get rightHumaneTreatment => 'Rätt till human behandling och sjukvård';

  @override
  String get documentIncident => 'Dokumentera händelsen (datum, tid, vittnen)';

  @override
  String get fileComplaintOmbudsman =>
      'Lämna klagomål till Diskrimineringsombudsmannen';

  @override
  String get contactLegalAidOffice => 'Kontakta ett rättshjälpskontor';

  @override
  String get reportToPolice => 'Anmäl till polisen vid brott (hot, misshandel)';

  @override
  String get legalAidCalculator => 'Rättshjälpskalkylator';

  @override
  String checkEligibility(String country) {
    return 'Kontrollera din behörighet för rättshjälp: $country';
  }

  @override
  String get estimateDisclaimer =>
      'Detta är bara en uppskattning. Faktisk behörighet avgörs av Rättshjälpsbyrån.';

  @override
  String get monthlyIncome => 'Månadsinkomst (EUR)';

  @override
  String get totalAssets => 'Totala tillgångar (EUR)';

  @override
  String get numberOfDependents => 'Antal beroende';

  @override
  String get calculateEligibility => 'Beräkna berättigande';

  @override
  String get likelyEligible => 'Troligen berättigad';

  @override
  String get mayNotQualify => 'Kanske inte berättigad';

  @override
  String get fullFreeLegalAid =>
      'Du kvalificerar troligen för full gratis rättshjälp.';

  @override
  String legalAidWithCopay(String percent) {
    return 'Du kan kvalificera för rättshjälp med en egenavgift på $percent%.';
  }

  @override
  String get mayNotQualifyDesc =>
      'Baserat på uppskattningen kanske du inte kvalificerar för statlig rättshjälp.';

  @override
  String get couldNotLoadDeadlines => 'Kunde inte ladda tidsfrister';

  @override
  String get noUpcomingDeadlines => 'Inga kommande tidsfrister';

  @override
  String get allClearDeadlines =>
      'Allt klart! Nya tidsfrister visas här när de sätts.';

  @override
  String get nothingOverdue => 'Inget förfallet';

  @override
  String get greatJobDeadlines => 'Bra jobbat med att hålla tidsfristerna.';

  @override
  String get noCompletedDeadlines => 'Inga slutförda tidsfrister';

  @override
  String get completedDeadlinesDesc => 'Slutförda tidsfrister visas här.';

  @override
  String get daysLate => 'dagar försenad';

  @override
  String get days => 'dagar';

  @override
  String get fromDocument => 'Från dokument';

  @override
  String get couldNotLoadCase => 'Kunde inte ladda ärendedetaljer';

  @override
  String get typeLabel => 'Typ';

  @override
  String get nationality => 'Nationalitet';

  @override
  String get migriReference => 'Migri-referens';

  @override
  String get courtCaseNo => 'Domstolsärende nr';

  @override
  String get created => 'Skapad';

  @override
  String get citizenship => 'Medborgarskap';

  @override
  String get workPermit => 'Arbetstillstånd';

  @override
  String get noDocumentsYet => 'Inga dokument uppladdade ännu';

  @override
  String get noUpcomingDeadlinesShort => 'Inga kommande tidsfrister';

  @override
  String get caseCreated => 'Ärende skapat';

  @override
  String get decisionReceived => 'Beslut mottaget';

  @override
  String get appealDeadline => 'Överklagandefrist';

  @override
  String get hearingScheduled => 'Förhandling planerad';

  @override
  String get late => 'försenad';

  @override
  String get pending => 'Väntar';

  @override
  String get processing => 'Bearbetar';

  @override
  String get ready => 'Klar';

  @override
  String get failed => 'Misslyckades';

  @override
  String get analyzed => 'Analyserad';

  @override
  String get noDocumentsScanHint =>
      'Inga dokument ännu. Skanna eller ladda upp.';

  @override
  String get inCourt => 'I domstol';

  @override
  String get appeal => 'Överklagande';

  @override
  String get caseTimeline => 'Ärendetidslinje';

  @override
  String get couldNotLoadTimeline => 'Kunde inte ladda tidslinje';

  @override
  String get noEventsYet => 'Inga händelser ännu';

  @override
  String get activityWillAppear =>
      'Aktivitet visas här när ditt ärende fortskrider.';

  @override
  String caseCreatedDesc(String title) {
    return 'Ärende ”$title” har skapats.';
  }

  @override
  String get decisionReceivedDesc =>
      'Ett officiellt beslut har mottagits för detta ärende.';

  @override
  String get appealDeadlineSet => 'Överklagandefrist satt';

  @override
  String appealDeadlineDesc(String date) {
    return 'Överklagande måste lämnas in senast $date.';
  }

  @override
  String hearingScheduledDesc(String date) {
    return 'Förhandling planerad till $date.';
  }

  @override
  String get caseInfoUpdated => 'Ärendeinformation senast uppdaterad.';

  @override
  String get noEventsForFilter => 'Inga händelser matchar detta filter';

  @override
  String get timelineFilterAll => 'Alla';

  @override
  String get timelineFilterEmails => 'E-post';

  @override
  String get timelineFilterConsilium => 'AI-beslut';

  @override
  String get timelineFilterDeadlines => 'Tidsfrister';

  @override
  String get timelineFilterNotes => 'Anteckningar';

  @override
  String get timelineEventEmailIn => 'E-post mottagen';

  @override
  String get timelineEventEmailOut => 'E-post skickad';

  @override
  String get timelineEventConsiliumDecision => 'AI-beslut';

  @override
  String get timelineEventDeadlineSet => 'Tidsfrist';

  @override
  String get timelineEventDocUploaded => 'Dokument';

  @override
  String get timelineEventPhaseChange => 'Fasändring';

  @override
  String get timelineEventManualNote => 'Anteckning';

  @override
  String get timelineJustNow => 'Just nu';

  @override
  String timelineMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minuter sedan',
      one: '1 minut sedan',
    );
    return '$_temp0';
  }

  @override
  String timelineHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count timmar sedan',
      one: '1 timme sedan',
    );
    return '$_temp0';
  }

  @override
  String timelineDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dagar sedan',
      one: '1 dag sedan',
    );
    return '$_temp0';
  }

  @override
  String get documentAnalysis => 'Dokumentanalys';

  @override
  String get exportAsPdf => 'Exportera som PDF';

  @override
  String get pdfExportComingSoon => 'PDF-export kommer snart';

  @override
  String get analysisFailedRetry => 'Analysen misslyckades. Försök igen.';

  @override
  String get somethingWentWrong => 'Något gick fel';

  @override
  String get genericError => 'Något gick fel. Försök igen.';

  @override
  String get retryAnalysis => 'Försök igen';

  @override
  String issuesFoundInDocument(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count problem hittade i dokumentet',
      one: '1 problem hittat i dokumentet',
      zero: 'Inga problem hittades i dokumentet',
    );
    return '$_temp0';
  }

  @override
  String get severityOverview => 'Allvarlighetsöversikt';

  @override
  String get issuesFoundHeader => 'Problem hittade';

  @override
  String generateAppealWithIssues(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Skapa överklagande ($count problem)',
      one: 'Skapa överklagande (1 problem)',
    );
    return '$_temp0';
  }

  @override
  String get analyzingContent => 'Analyserar innehåll…';

  @override
  String get documentProcessedOk => 'Dokument bearbetat framgångsrikt';

  @override
  String get noSignificantIssues =>
      'Inga väsentliga problem hittades i detta dokument.';

  @override
  String get cameraPermissionRequired => 'Kamerabehörighet krävs';

  @override
  String get cameraPermissionDesc =>
      'Ge kameratillgång för att skanna dokument eller använd galleriet.';

  @override
  String get openSettings => 'Öppna inställningar';

  @override
  String get alignDocument => 'Justera dokumentet inom ramen';

  @override
  String pageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sidor',
      one: '1 sida',
      zero: 'inga sidor',
    );
    return '$_temp0';
  }

  @override
  String get preview => 'Förhandsvisa';

  @override
  String pageNumber(int number) {
    return 'Sida $number';
  }

  @override
  String get done => 'Klart';

  @override
  String get retake => 'Ta om';

  @override
  String get useThisPhoto => 'Använd detta foto';

  @override
  String get addPage => 'Lägg till sida';

  @override
  String uploadingPercent(int percent) {
    return 'Laddar upp… $percent%';
  }

  @override
  String get preparingUpload => 'Förbereder uppladdning…';

  @override
  String get documentUploadedSuccess => 'Dokument uppladdat framgångsrikt';

  @override
  String pagesUploadedSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sidor laddades upp',
      one: '1 sida laddades upp',
    );
    return '$_temp0';
  }

  @override
  String get uploadFailed =>
      'Uppladdning misslyckades. Kontrollera anslutningen.';

  @override
  String get capturePhotoFailed => 'Kunde inte ta foto. Försök igen.';

  @override
  String get readingText => 'Läser text…';

  @override
  String get draftDocument => 'Dokumentutkast';

  @override
  String get saveChanges => 'Spara ändringar';

  @override
  String get editDocument => 'Redigera dokument';

  @override
  String get generatingDraft => 'Skapar ditt utkast…';

  @override
  String get generatingDraftDesc =>
      'AI förbereder ett juridiskt dokument baserat på dina ärendedetaljer.';

  @override
  String get failedToGenerateDraft => 'Kunde inte skapa utkast. Försök igen.';

  @override
  String get changesSaved => 'Ändringar sparade';

  @override
  String get copiedToClipboard => 'Kopierat till urklipp';

  @override
  String get emailComingSoon => 'E-postutskick kommer snart';

  @override
  String get reviewBeforeSending =>
      'Granska noggrant innan du skickar. Du ansvarar för dokumentets innehåll.';

  @override
  String get noContentAvailable => 'Inget innehåll tillgängligt';

  @override
  String get save => 'Spara';

  @override
  String get edit => 'Redigera';

  @override
  String get pdf => 'PDF';

  @override
  String get copy => 'Kopiera';

  @override
  String get appealDraft => 'Utkast till överklagande';

  @override
  String selected(int count) {
    return '$count valda';
  }

  @override
  String get deleteSelected => 'Radera valda';

  @override
  String deleteDocumentsConfirm(int count) {
    return 'Radera $count dokument?';
  }

  @override
  String get delete => 'Radera';

  @override
  String get analyzeSelected => 'Analysera valda';

  @override
  String get batchAnalysisStarting => 'Batchanalys startar…';

  @override
  String get switchToList => 'Växla till lista';

  @override
  String get switchToGrid => 'Växla till rutnät';

  @override
  String get scanNew => 'Ny skanning';

  @override
  String get noDocumentsYetScan => 'Inga dokument ännu';

  @override
  String get scanFirstDocumentHint =>
      'Skanna ditt första dokument så att AI kan analysera det.';

  @override
  String get failedToLoadDocuments => 'Kunde inte ladda dokument';

  @override
  String get emailIntegrationTitle => 'E-postintegration';

  @override
  String get connectYourEmail => 'Anslut din e-post';

  @override
  String get connectYourEmailDesc =>
      'Anslut din e-post för att automatiskt upptäcka och organisera juridisk korrespondens.';

  @override
  String get legalEmails => 'Juridiska e-postmeddelanden';

  @override
  String get unlinkedEmails => 'Olänkade e-postmeddelanden';

  @override
  String get noLegalEmailsYet => 'Inga juridiska e-postmeddelanden ännu';

  @override
  String get legalEmailsWillAppear =>
      'E-post klassificerad som juridisk visas här.';

  @override
  String get assignToCase => 'Tilldela ärende';

  @override
  String get disconnectEmail => 'Koppla bort e-post';

  @override
  String get disconnectEmailConfirm =>
      'Automatisk e-postsynkronisering stoppas. Tidigare synkroniserade e-postmeddelanden finns kvar.';

  @override
  String get gmailReauthBannerBody =>
      'Advocat v2.1 läser din inkorg för att skriva utkast till svar; du kan återkalla åtkomsten när som helst. Återanslut Gmail för att aktivera proaktiv sortering.';

  @override
  String get gmailReauthBannerCta => 'Auktorisera på nytt';

  @override
  String connectedTo(String email) {
    return 'Ansluten till $email';
  }

  @override
  String lastSynced(String time) {
    return 'Senast synkroniserat: $time';
  }

  @override
  String get filterByType => 'Filtrera efter typ';

  @override
  String get noCasesMatchSearch => 'Inga ärenden matchar sökningen';

  @override
  String get failedToLoadCases => 'Kunde inte ladda ärenden';

  @override
  String get monthly => 'Månadsvis';

  @override
  String get annual => 'Årlig';

  @override
  String get saveTwentyFivePercent => 'Spara 25%';

  @override
  String get mostPopular => 'POPULÄRAST';

  @override
  String get oneCaseActive => '1 aktivt ärende';

  @override
  String get threeCasesActive => '3 aktiva ärenden';

  @override
  String get unlimitedCases => 'Obegränsade ärenden';

  @override
  String get threeDocScans => '3 dokumentskanningar';

  @override
  String get twentyDocScans => '20 dokumentskanningar';

  @override
  String get unlimitedDocScans => 'Obegränsad dokumentskanning';

  @override
  String get basicAiAnalysis => 'Grundläggande AI-analys';

  @override
  String get fullAiAnalysis => 'Fullständig AI-analys';

  @override
  String get draftGeneration => 'Utkastgenerering';

  @override
  String get priorityProcessing => 'Prioriterad bearbetning';

  @override
  String get fiveAiMessagesTotal => '5 AI messages (lifetime)';

  @override
  String get hundredAiMessagesDay => '100 AI messages/day';

  @override
  String get unlimitedAiMessages => 'Unlimited AI messages';

  @override
  String get voiceInput => 'Voice input';

  @override
  String get strategyRecommendations => 'Strategy recommendations';

  @override
  String get foundingMemberNote =>
      'Founding Member: 9.99€/mo for first 3 months';

  @override
  String get saveTwentyPercent => 'Save 20%';

  @override
  String get forever => 'för alltid';

  @override
  String get perMonth => '/månad';

  @override
  String get perYear => '/år';

  @override
  String get checkingPurchases => 'Kontrollerar tidigare köp…';

  @override
  String get noPreviousPurchases => 'Inga tidigare köp hittades.';

  @override
  String get chatWelcomeMessage =>
      'Hi! I\'m Advocat — your AI legal assistant. I provide legal information, not legal advice. What legal question can I help with?';

  @override
  String get copySummary => 'Kopiera sammanfattning';

  @override
  String get caseSummaryCopied => 'Ärendesammanfattning kopierad';

  @override
  String get openCase => 'Öppna ärende';

  @override
  String get viewFull => 'Visa fullständig';

  @override
  String get draftCopiedToClipboard => 'Utkast kopierat till urklipp';

  @override
  String get reportMileageFraud => 'Rapportera mätarbedrägeri';

  @override
  String get reportMileageFraudDesc =>
      'En bedrägerirapport skapas baserat på fordonskontrolldata.';

  @override
  String get reportAndOpenCase => 'Rapportera och öppna ärende';

  @override
  String get caseCreationComingSoon =>
      'Skapa ärende med förifyllda data kommer snart';

  @override
  String get failedToCreateCaseRetry => 'Kunde inte skapa ärende. Försök igen.';

  @override
  String get takePhotoInstead => 'Ta ett foto istället';

  @override
  String get deleteCase => 'Radera ärende';

  @override
  String deleteCaseConfirm(String title) {
    return 'Är du säker på att du vill radera ”$title”? Åtgärden kan inte ångras.';
  }

  @override
  String get haveQuestionsAi => 'Frågor? Fråga AI';

  @override
  String get cookiePolicy => 'Cookiepolicy';

  @override
  String get aiDisclaimer => 'AI-ansvarsfriskrivning';

  @override
  String get aiDisclaimerCompact =>
      'Advocat is AI legal information, not legal advice. Verify with a licensed lawyer before acting.';

  @override
  String get aiDisclaimerFullTitle => 'Important: how Advocat works';

  @override
  String get aiDisclaimerFullBody =>
      'Advocat is an artificial-intelligence tool that provides legal information, not legal advice. Under the EU AI Act (Art. 50), we must tell you clearly: you are interacting with AI, not a human lawyer.\n\nAdvocat is not a law firm. We are not licensed advocates under the Estonian Advokatuuriseadus or the Finnish Asianajajalaki, and attorney-client privilege does not attach to your conversations with this tool. Before relying on any output — to file an appeal, sign a contract, or act on a deadline — verify with a licensed lawyer in your jurisdiction.';

  @override
  String get aiDisclaimerExpand => 'Learn more';

  @override
  String get aiDisclaimerDismiss => 'OK, I understand';

  @override
  String get dataPrivacyConsent => 'Dataskyddssamtycke';

  @override
  String get gdprIntro =>
      'För att tillhandahålla AI-juridisk hjälp behandlar vi dina data i enlighet med GDPR (EU 2016/679). Genom att fortsätta godkänner du:';

  @override
  String get gdprChat => 'Bearbetning av chattmeddelanden av AI';

  @override
  String get gdprDocs => 'Analys av uppladdade dokument';

  @override
  String get gdprStorage => 'Krypterad lagring av ärendedata';

  @override
  String get gdprDelete => 'Rätt att radera dina data när som helst';

  @override
  String get gdprFooter =>
      'Dina data är krypterade och delas aldrig med tredje part. Du kan återkalla samtycke och radera all data i Inställningar.';

  @override
  String get gdprConsentAiProcessing =>
      'I agree to the processing of my data for AI legal assistance (required)';

  @override
  String get gdprConsentAnalytics =>
      'I agree to analytics to improve the service (optional)';

  @override
  String get gdprArt9Intro =>
      'This app processes special category personal data under GDPR Article 9, including:';

  @override
  String get gdprSpecialLegalCases =>
      'Your legal case details and court documents';

  @override
  String get gdprSpecialNationality => 'Nationality and immigration status';

  @override
  String get gdprConsentLegalData =>
      'I consent to the processing of my legal case data, nationality, and immigration status by AI (required)';

  @override
  String get gdprConsentVoice =>
      'I consent to voice recording processing (optional)';

  @override
  String get gdprViewPrivacyPolicy => 'View Privacy Policy';

  @override
  String get legalInformation => 'Legal Information';

  @override
  String get legalEntityName => 'Vorantis OÜ';

  @override
  String get legalRegistryCode => 'Registry code: 17098992';

  @override
  String get legalAddress =>
      'Harju maakond, Tallinn, Kesklinna linnaosa, Tornimäe tn 5, 10145';

  @override
  String get legalEmail => 'Email: support@advocat.ee';

  @override
  String get legalRegistry =>
      'Registered in Estonian Commercial Register (Äriregister)';

  @override
  String get aiGeneratedDisclaimer => 'AI-generated • Not legal advice';

  @override
  String get decline => 'Avböj';

  @override
  String get iAgree => 'Jag godkänner';

  @override
  String get iAgreeToThe => 'Jag godkänner ';

  @override
  String get orWord => 'eller';

  @override
  String get english => 'Engelska';

  @override
  String get russian => 'Ryska';

  @override
  String get finnish => 'Finska';

  @override
  String successSubscribed(String plan) {
    return 'Prenumeration på $plan lyckades!';
  }

  @override
  String paymentFailed(String error) {
    return 'Betalning misslyckades: $error';
  }

  @override
  String get whatToDo => 'Vad ska du göra';

  @override
  String get getHelp => 'Få hjälp';

  @override
  String get share => 'Dela';

  @override
  String get didYouKnow => 'Visste du?';

  @override
  String get mustKnow => 'Måste veta';

  @override
  String get goodToKnow => 'Bra att veta';

  @override
  String get sentFromAdvocat => 'Skickat från Advocat-appen';

  @override
  String get policeActionStayCalm => 'Håll dig lugn och håll händerna synliga';

  @override
  String get policeActionAskWhy => 'Fråga polisen varför du stoppas';

  @override
  String get policeActionProvideName => 'Uppge ditt namn och födelsedatum';

  @override
  String get policeActionWantLawyer =>
      'Säg tydligt: ”Jag vill ha en advokat innan några frågor”';

  @override
  String get policeActionAskInterpreter => 'Be om tolk vid behov';

  @override
  String get policeActionNoteBadge => 'Notera polisens namn och tjänstenummer';

  @override
  String get policeFactMustTellReason =>
      'I Finland måste polisen berätta varför du stoppas. Om de inte gör det kan du fråga — och de är skyldiga enligt lag att förklara.';

  @override
  String get policeFactCanRecord =>
      'Du kan spela in polisinteraktioner på offentliga platser i Finland. Detta skyddas av yttrandefriheten.';

  @override
  String get contactFinnishLegalAid => 'Finsk rättshjälp';

  @override
  String get contactNonDiscriminationOmbudsman => 'Diskrimineringsombudsmannen';

  @override
  String get deportationDeadlineAppeal =>
      'Överklagande till förvaltningsdomstolen — vanligtvis 30 dagar från delgivning';

  @override
  String get deportationDeadlineLegalAid =>
      'Ansök om rättshjälp — gör detta OMEDELBART';

  @override
  String get deportationFactStayDuringAppeal =>
      'I Finland har du vanligtvis rätt att stanna i landet medan ditt överklagande behandlas. Utvisning kan inte verkställas under ett pågående överklagande i de flesta fall.';

  @override
  String get contactRefugeeAdviceCentre => 'Finlands Flyktingrådgivning';

  @override
  String get contactAdminCourtHelsinki => 'Förvaltningsdomstolen i Helsingfors';

  @override
  String get workplaceActionKeepContract =>
      'Spara kopior av ditt anställningsavtal';

  @override
  String get workplaceActionTrackHours =>
      'Registrera dina arbetstimmar självständigt';

  @override
  String get workplaceActionReportUnsafe =>
      'Anmäl osäkra förhållanden till arbetarskyddsmyndigheten';

  @override
  String get workplaceActionJoinUnion => 'Gå med i ett fackförbund för skydd';

  @override
  String get workplaceActionContactAuthority =>
      'Kontakta Arbetarskyddsmyndigheten vid behov';

  @override
  String get workplaceFactCollectiveWage =>
      'I Finland fastställer kollektivavtal minimilöner per bransch — det finns ingen enskild nationell minimilön. Din arbetsgivare måste följa kollektivavtalet för ditt område.';

  @override
  String get workplaceFactOralContract =>
      'Även utan skriftligt avtal har du fulla anställningsrättigheter i Finland. Ett muntligt avtal är lika bindande enligt lag.';

  @override
  String get contactOccupationalSafety => 'Arbetarskyddsmyndigheten';

  @override
  String get contactTradeUnionSAK => 'Fackföreningsrådgivning (SAK)';

  @override
  String get tenantActionWrittenAgreement =>
      'Ha alltid ett skriftligt hyresavtal';

  @override
  String get tenantActionDocumentCondition =>
      'Dokumentera lägenhetens skick vid inflyttning (foton)';

  @override
  String get tenantActionReportMaintenance =>
      'Anmäl underhållsproblem skriftligt';

  @override
  String get tenantActionNoIllegalEviction =>
      'Gå aldrig med på olaglig vräkning — domstolen måste besluta';

  @override
  String get tenantActionContactAdvisory =>
      'Kontakta hyresgästföreningen vid tvister';

  @override
  String get tenantFactNoEvictionWithoutCourt =>
      'En hyresvärd i Finland kan inte vräka dig utan domstolsbeslut, även om ditt hyresavtal har löpt ut. Att byta lås eller stänga av el/vatten är olagligt.';

  @override
  String get contactTenantsAssociation => 'Finlands Hyresgästförbund';

  @override
  String get contactConsumerDisputesBoard => 'Konsumenttvistenämnden';

  @override
  String get detentionActionAskDecision =>
      'Be omedelbart om det skriftliga förvarsbeslutet';

  @override
  String get detentionActionRequestLawyer => 'Begär att få kontakta en advokat';

  @override
  String get detentionActionContactEmbassy =>
      'Kontakta din ambassad eller konsulat';

  @override
  String get detentionActionAskMedical => 'Be om sjukvård vid behov';

  @override
  String get detentionActionRequestInterpreter =>
      'Begär tolk vid alla förhandlingar';

  @override
  String get detentionDeadlineCourtReview =>
      'Tingsrätten måste pröva förvaret inom 4 dagar';

  @override
  String get detentionDeadlineContinuation =>
      'Domstolen prövar förlängning varannan vecka';

  @override
  String get detentionFactCourtReview =>
      'Migrationsförvar i Finland måste prövas av en tingsrätt inom 4 dagar. Om det inte görs blir förvaret olagligt.';

  @override
  String get contactParliamentaryOmbudsman => 'Riksdagens justitieombudsman';

  @override
  String get discriminationActionWriteDown =>
      'Skriv ner exakt vad som hände (datum, tid, plats)';

  @override
  String get discriminationActionSaveEvidence =>
      'Spara bevis: meddelanden, e-post, vittnen';

  @override
  String get discriminationActionFileComplaint =>
      'Lämna in ett klagomål till Diskrimineringsombudsmannen';

  @override
  String get discriminationActionContactLegalAid =>
      'Kontakta ett rättshjälpskontor för gratis rådgivning';

  @override
  String get discriminationActionReportPolice =>
      'Anmäl till polisen om hot eller våld förekom';

  @override
  String get discriminationFactNonDiscriminationAct =>
      'Finlands diskrimineringslag omfattar diskriminering på grund av ålder, ursprung, nationalitet, språk, religion, hälsa, funktionsnedsättning, sexuell läggning och andra personliga egenskaper.';

  @override
  String get contactVictimSupportRIKU => 'Brottsofferjouren Finland (RIKU)';

  @override
  String get domesticViolence => 'Våld i hemmet';

  @override
  String get domesticViolenceDesc =>
      'Victim rights, emergency help, restraining orders';

  @override
  String get rightCallEmergency =>
      'You have the right to call 112 in any emergency — police, ambulance, fire';

  @override
  String get rightVictimProtection =>
      'As a victim, you have the right to protection, support, and information about your case';

  @override
  String get rightRestrainingOrder =>
      'You can apply for a restraining order (lähestymiskielto) to keep the abuser away';

  @override
  String get rightVictimInterpreter =>
      'You have the right to an interpreter during all legal proceedings';

  @override
  String get rightMedicalHelp =>
      'You have the right to immediate medical treatment and documentation of injuries';

  @override
  String get rightShelter =>
      'You have the right to emergency shelter — contact a shelter or social services';

  @override
  String get mustReportDanger =>
      'If someone is in immediate danger, call 112 immediately';

  @override
  String get mustDocumentInjuries =>
      'Document all injuries — photos, medical records, written notes';

  @override
  String get domesticActionCallEmergency =>
      'Call 112 if you are in immediate danger';

  @override
  String get domesticActionGoToSafe =>
      'Go to a safe place — shelter, friend, public place';

  @override
  String get domesticActionDocumentEverything =>
      'Document injuries: take photos, get medical records';

  @override
  String get domesticActionFilePoliceReport =>
      'File a police report — you can do this later too';

  @override
  String get domesticActionContactShelter =>
      'Contact a shelter or crisis helpline';

  @override
  String get domesticActionApplyRestraining =>
      'Apply for a restraining order through police or court';

  @override
  String get domesticFactRestrainingOrder =>
      'In Finland, a restraining order (lähestymiskielto) can be issued even without a criminal case. It prohibits the person from contacting or approaching you.';

  @override
  String get domesticFactVictimDirective =>
      'Under EU Victims\' Directive 2012/29/EU, you have the right to be treated with respect, to receive information in a language you understand, and to access victim support services — regardless of your residence status.';

  @override
  String get domesticDeadlinePoliceReport =>
      'File police report — no strict deadline, but sooner is better for evidence';

  @override
  String get domesticDeadlineRestraining =>
      'Restraining order — can be applied for at any time';

  @override
  String get contactEmergency => 'Emergency Number';

  @override
  String get contactShelter => 'Turvakoti (Shelter) Helpline';

  @override
  String get contactCrisisHelpline => 'Crisis Helpline (Kriisipuhelin)';

  @override
  String get contactNollaLinja =>
      'Nollalinja — Violence Against Women Helpline';

  @override
  String get inheritance => 'Arv';

  @override
  String get inheritanceDesc =>
      'Wills, estate, heirs\' rights, forced heirship, probate';

  @override
  String get rightInheritanceForced =>
      'Forced heirs (children, spouse) are entitled to a compulsory share regardless of the will';

  @override
  String get rightInheritanceWill =>
      'You have the right to make a will disposing of your property — notarized wills have the strongest legal force';

  @override
  String get rightInheritanceRenounce =>
      'You can renounce an inheritance within 3 months of learning about it';

  @override
  String get rightInheritanceInfo =>
      'You have the right to obtain information about the estate from banks and registries';

  @override
  String get rightInheritanceDispute =>
      'You can challenge an unfair will in court within the statutory limitation period';

  @override
  String get mustFileInheritance =>
      'File for succession proceedings at a notary within a reasonable time';

  @override
  String get mustNotifyHeirs =>
      'All known heirs must be notified of the succession proceedings';

  @override
  String get inheritanceActionGatherDocs =>
      'Gather all documents: death certificate, will, property records, bank statements';

  @override
  String get inheritanceActionContactNotary =>
      'Contact a notary to open succession proceedings';

  @override
  String get inheritanceActionCheckDebts =>
      'Check whether the estate has debts before accepting inheritance';

  @override
  String get inheritanceActionFileCourt =>
      'If the will is disputed, file a claim in court';

  @override
  String get inheritanceDeadlineRenounce =>
      '3 months to renounce inheritance after learning of it';

  @override
  String get inheritanceDeadlineDispute =>
      'Statute of limitations for challenging a will: varies by grounds';

  @override
  String get inheritanceFactForced =>
      'In Estonia, descendants and spouse have a right to a compulsory share (1/2 of legal share) even if excluded from the will';

  @override
  String get inheritanceFactNotary =>
      'All succession proceedings in Estonia must go through a notary — you cannot skip this step';

  @override
  String get consumerProtection => 'Konsumentskydd';

  @override
  String get consumerProtectionDesc =>
      'Fraud, defective products, returns, deceptive sellers';

  @override
  String get rightReturnOnline =>
      'You have 14 days to cancel online purchases without reason (EU right of withdrawal)';

  @override
  String get rightDefectiveProduct =>
      'If a product is defective, you have the right to repair, replacement, or refund';

  @override
  String get rightClearPricing =>
      'Sellers must display clear prices including all fees — hidden costs are illegal';

  @override
  String get rightComplainBoard =>
      'You can file a free complaint with the Consumer Disputes Board';

  @override
  String get rightProtectionFraud =>
      'You are protected against unfair commercial practices and fraud';

  @override
  String get mustKeepReceipts =>
      'Keep all receipts, contracts, and communication with sellers';

  @override
  String get mustActTimely =>
      'Report defects to the seller within a reasonable time after discovery';

  @override
  String get consumerActionKeepEvidence =>
      'Keep receipts, screenshots, emails, and all proof of purchase';

  @override
  String get consumerActionContactSeller =>
      'Contact the seller first — explain the problem in writing';

  @override
  String get consumerActionFileComplaint =>
      'File a complaint with the Consumer Disputes Board (kuluttajariitalautakunta)';

  @override
  String get consumerActionContactAuthority =>
      'Contact the Consumer Advisory Services for free help';

  @override
  String get consumerActionReportFraud =>
      'Report fraud to the police and Consumer Ombudsman';

  @override
  String get consumerFactWithdrawal =>
      'Under the EU Consumer Rights Directive 2011/83/EU, you have 14 days to withdraw from any online or distance purchase — no questions asked. The seller must refund you within 14 days.';

  @override
  String get consumerFactWarranty =>
      'In Finland, the seller is responsible for product defects for a reasonable time (often 2+ years). This is separate from any manufacturer warranty.';

  @override
  String get consumerDeadlineWithdrawal =>
      'Online purchase withdrawal — 14 days from delivery';

  @override
  String get consumerDeadlineDefect =>
      'Report defect to seller — within 2 months of discovery (recommended)';

  @override
  String get contactConsumerAdvisory => 'Consumer Advisory Services';

  @override
  String get contactConsumerOmbudsman =>
      'Consumer Ombudsman (Kuluttaja-asiamies)';

  @override
  String get contactConsumerDisputesBoardDirect => 'Consumer Disputes Board';

  @override
  String get caseTypeStepLabel => 'Case Type';

  @override
  String get detailsStepLabel => 'Details';

  @override
  String get documentsStepLabel => 'Documents';

  @override
  String get whatTypeOfCase => 'What type of case is this?';

  @override
  String get selectCategoryDescription =>
      'Select the category that best describes your situation.';

  @override
  String get tellUsAboutCase => 'Tell us about your case';

  @override
  String get aiHelpsUnderstand =>
      'This information helps our AI understand your situation better.';

  @override
  String get caseTitleHint => 'e.g., Residence Permit Appeal 2026';

  @override
  String get countryJurisdiction => 'Country / Jurisdiction';

  @override
  String get selectCountryHint => 'Select a country';

  @override
  String get referenceNumberHint => 'e.g., UMA/12345/2026';

  @override
  String get descriptionOptional => 'Description (optional)';

  @override
  String get descriptionHint =>
      'Describe your situation briefly. What happened? What decision was made?';

  @override
  String get uploadFirstDocument => 'Upload your first document';

  @override
  String get uploadDocumentDescription =>
      'Upload the decision letter or any relevant document. You can skip this step and add documents later.';

  @override
  String get tapToUploadFile => 'Tap to upload a file';

  @override
  String get fileSizeLimit => 'PDF, JPG, PNG up to 25 MB';

  @override
  String get addDocumentsLaterHint =>
      'You can always add documents later from the case detail screen.';

  @override
  String get callAI => 'Call AI';

  @override
  String get comingSoon => 'Kommer snart';

  @override
  String get encrypted => 'Encrypted';

  @override
  String get typing => 'Typing…';

  @override
  String get online => 'Online';

  @override
  String get chatWelcomeSubtitle =>
      'I will analyze the situation, check documents, find errors, and suggest what to do.';

  @override
  String get tapMicrophoneToSpeak => 'Tap the microphone to speak';

  @override
  String get categoryEssential => 'Essential';

  @override
  String get categoryPolice => 'Police';

  @override
  String get categoryWork => 'Work';

  @override
  String get categoryHousing => 'Housing';

  @override
  String get categoryConsumer => 'Consumer';

  @override
  String rightsInsideCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rättigheter inkluderade',
      one: '1 rättighet inkluderad',
      zero: 'inga rättigheter',
    );
    return '$_temp0';
  }

  @override
  String get freeAidThreshold => 'Free aid threshold';

  @override
  String get partialAidThreshold => 'Partial aid threshold';

  @override
  String get assetLimit => 'Asset limit';

  @override
  String get whereToApplyLabel => 'Where to apply';

  @override
  String get phoneLabel => 'Phone';

  @override
  String get websiteLabel => 'Website';

  @override
  String get disclaimerCollapsed => 'AI guidance only';

  @override
  String get disclaimerExpanded =>
      'AI assistant — not legal advice. Always verify with a qualified lawyer.';

  @override
  String get chatDisclaimerBanner =>
      'AI assistant provides legal information, not legal advice. Always consult a qualified lawyer.';

  @override
  String get chatDisclaimerSubtitle => 'AI-assistent · ej juridisk rådgivning';

  @override
  String get chatDisclaimerBannerFull =>
      'Advocat är en AI-assistent för juridisk information, inte en advokat. Informationen här skapar inget advokat–klient-förhållande, är inte juridisk rådgivning och kan vara felaktig. För bindande juridisk rådgivning, kontakta en behörig advokat i din jurisdiktion. Vi företräder dig inte.';

  @override
  String get chatDisclaimerFooter =>
      'AI-genererat. Verifiera med en behörig advokat.';

  @override
  String get chatDisclaimerGotIt => 'Uppfattat';

  @override
  String get categoryChildren => 'Children';

  @override
  String get categoryDigital => 'Digital';

  @override
  String get childrenRights => 'Children\'s Rights & Alimony';

  @override
  String get childrenRightsDesc =>
      'Child support, alimony, protection, state guarantees';

  @override
  String get cyberbullying => 'Cyberbullying & Online Harassment';

  @override
  String get cyberbullyingDesc =>
      'Threats, privacy violations, defamation online';

  @override
  String get rightChildSupport =>
      'Both parents are legally obligated to support their child financially (Perekonnaseadus § 100–102)';

  @override
  String get rightMinimumAlimony =>
      'Minimum child support in Estonia: base amount (€295.86) + 3% of previous year\'s average gross salary (PKS § 101). From 01.04.2026 — €318.62/month per child. Updated annually on April 1st. Calculator: alimendid.ee';

  @override
  String get rightCourtAlimony =>
      'You can apply for alimony through county court (maakohus) — no lawyer required for claims up to €6,400';

  @override
  String get rightBailiffEnforcement =>
      'If the parent refuses to pay, a bailiff (kohtutäitur) can enforce the court order, including wage garnishment';

  @override
  String get rightStateAlimonyGuarantee =>
      'If the parent does not pay, the state provides elatisabi (maintenance allowance) through Sotsiaalkindlustusamet — up to €100/month per child';

  @override
  String get rightChildEducation =>
      'Every child has the right to education, healthcare, and protection from abuse (Lastekaitseseadus § 4–5)';

  @override
  String get rightChildContact =>
      'A child has the right to maintain contact with both parents unless a court decides otherwise (PKS § 143)';

  @override
  String get mustFileCourtClaim =>
      'To receive alimony, you must file a claim at court or agree on the amount in writing';

  @override
  String get mustNotifyAddressChange =>
      'Notify Sotsiaalkindlustusamet of address changes if receiving elatisabi';

  @override
  String get childrenActionGatherDocs =>
      'Gather child\'s birth certificate, your ID, and proof of expenses';

  @override
  String get childrenActionFileCourtClaim =>
      'File an alimony claim at the county court (maakohus) — can be done online via e-toimik';

  @override
  String get childrenActionApplyElatisabi =>
      'Apply for state alimony guarantee (elatisabi) at Sotsiaalkindlustusamet if parent won\'t pay';

  @override
  String get childrenActionContactBailiff =>
      'Contact a bailiff (kohtutäitur) to enforce the court order';

  @override
  String get childrenActionCallLasteabi =>
      'Call Lasteabi 116 111 for children\'s helpline — free, 24/7';

  @override
  String get childrenDeadlineElatisabi =>
      'Apply for elatisabi — after court order, no strict deadline but process takes time';

  @override
  String get childrenDeadlineCourt =>
      'Alimony can be claimed retroactively for up to 1 year before court filing';

  @override
  String get childrenFactMinimum =>
      'From 01.04.2026 minimum child support is €318.62/month per child. Formula: base amount (€295.86) + 3% of previous year\'s average gross salary. Updated annually on April 1st. A parent cannot agree to pay less. Calculator: alimendid.ee';

  @override
  String get childrenFactElatisabi =>
      'Estonia\'s state alimony guarantee (elatisabi) was introduced in 2017 to protect children when a parent refuses to pay. The state pays and then recovers the amount from the debtor parent.';

  @override
  String get rightReportCybercrime =>
      'You have the right to report online threats, harassment, and identity theft to the police (Karistusseadustik § 120, § 157¹)';

  @override
  String get rightContentRemoval =>
      'You can request removal of defamatory or private content from platforms and demand takedown under GDPR';

  @override
  String get rightMoralDamageCompensation =>
      'You may claim compensation for moral damage caused by cyberbullying (Võlaõigusseadus § 1043–1055)';

  @override
  String get rightPrivacyProtection =>
      'Your private life is protected — unauthorized sharing of your photos, messages, or personal data is illegal (KarS § 157)';

  @override
  String get rightDataProtection =>
      'Report data protection violations (unauthorized use of your data) to Andmekaitse Inspektsioon';

  @override
  String get rightDefamationAction =>
      'Defamation (laimamine) is a civil offense — you can sue for damages and demand a public retraction (KarS § 247 (repealed), VÕS § 1047)';

  @override
  String get mustCollectEvidence =>
      'Collect and preserve all evidence — screenshots, links, dates, and witness information';

  @override
  String get mustNotRetaliate =>
      'Do not retaliate or engage in counter-harassment — it may weaken your case';

  @override
  String get cyberActionScreenshots =>
      'Take screenshots of all harassment — save URLs, dates, usernames, and content';

  @override
  String get cyberActionReportPolice =>
      'File a police report at the nearest station or online at politsei.ee';

  @override
  String get cyberActionReportPlatform =>
      'Report the content to the social media platform for removal';

  @override
  String get cyberActionContactDPA =>
      'Contact Andmekaitse Inspektsioon if your personal data was misused';

  @override
  String get cyberActionConsultLawyer =>
      'Consult a lawyer about civil damages — free legal aid is available through Riigi Õigusabi';

  @override
  String get cyberDeadlineCriminal =>
      'Criminal complaint — no strict deadline, but report promptly for best results';

  @override
  String get cyberDeadlineCivil =>
      'Civil claim for damages — up to 3 years from when you learned of the violation (TsÜS § 150)';

  @override
  String get cyberFactPrivacy =>
      'In Estonia, unauthorized sharing of someone\'s intimate images can result in up to 3 years in prison under Karistusseadustik § 157¹ (violation of privacy).';

  @override
  String get cyberFactGDPR =>
      'Under GDPR, you have the \'right to be forgotten\' — platforms must delete your personal data upon request if there is no legal basis to keep it.';

  @override
  String get guestUser => 'Gäst';

  @override
  String get howToUse => 'Hur använda?';

  @override
  String get tutorialStep1Title => 'AI-juridisk assistent';

  @override
  String get tutorialStep1Desc =>
      'Ställ vilken rättslig fråga som helst och få omedelbara svar baserade på estnisk lag.';

  @override
  String get tutorialStep2Title => 'Känn till dina rättigheter';

  @override
  String get tutorialStep2Desc =>
      'Bläddra bland juridisk information efter ämne — arbete, boende, konsumenträttigheter och mer.';

  @override
  String get tutorialStep3Title => 'Skanna dokument';

  @override
  String get tutorialStep3Desc =>
      'Ta bilder av juridiska dokument för AI-analys och säker förvaring.';

  @override
  String get tutorialStep4Title => 'Kom igång!';

  @override
  String get tutorialStep4Desc =>
      'Utforska appen och skydda dina rättigheter. All data förblir privat på din enhet.';

  @override
  String get advocatProTitle => 'Advocat Pro';

  @override
  String get advocatProSubtitle => 'Lås upp premiumfunktioner';

  @override
  String get voiceDisclaimer =>
      'Röstassistenten fungerar för närvarande bara på dator (Chrome-webbläsare). Mobilstöd kommer snart.';

  @override
  String get recommended => 'Rekommenderas';

  @override
  String get pleaseLogIn => 'Vänligen logga in';

  @override
  String get subscriptionNotFound => 'Prenumeration hittades inte';

  @override
  String errorWithMessage(String message) {
    return 'Fel: $message';
  }

  @override
  String get redirectingToPayment => 'Omdirigerar till betalningssidan…';

  @override
  String cheaperAnnually(String amount) {
    return '€$amount/mån billigare med årsprenumeration';
  }

  @override
  String get navigatingTo => 'Öppnar';

  @override
  String get stayInChat => 'Stanna i chatten';

  @override
  String get backToChat => 'Tillbaka till chatten';

  @override
  String get upgradeBannerTitle => 'Uppgradera för obegränsade konsultationer';

  @override
  String get upgradeBannerCta => 'Uppgradera';

  @override
  String get paymentSuccessTitle => 'Betalningen lyckades';

  @override
  String get paymentSuccessBody => 'Din prenumeration är nu aktiv.';

  @override
  String get commonOk => 'OK';

  @override
  String get feedbackThumbsUpLabel => 'Hjälpsamt';

  @override
  String get feedbackThumbsDownLabel => 'Inte hjälpsamt';

  @override
  String get feedbackCommentPrompt => 'Vad var fel?';

  @override
  String get feedbackSend => 'Skicka';

  @override
  String get feedbackCancel => 'Avbryt';

  @override
  String get reasoningPillIdle => 'Tänker…';

  @override
  String get reasoningPillSearchingLaw => 'Söker i estnisk lag…';

  @override
  String get reasoningPillSearchingWeb => 'Söker på webben…';

  @override
  String get reasoningPillCheckingCompany => 'Kontrollerar företagsregistret…';

  @override
  String get reasoningPillCheckingVehicle => 'Kontrollerar fordonsregistret…';

  @override
  String get reasoningPillReadingDocument => 'Läser ditt dokument…';

  @override
  String get reasoningPillDrafting => 'Skriver dokumentet…';

  @override
  String get reasoningPillPreparingEmail => 'Förbereder e-post…';

  @override
  String get reasoningPillFindingLawyer => 'Söker efter jurister…';

  @override
  String get reasoningPillThinking => 'Resonerar kring ditt ärende…';

  @override
  String get reasoningPillFinalising => 'Sammanställer ditt svar…';

  @override
  String reasoningCollapsedFormat(int sec, int sources) {
    return 'Resonerade i $sec s · $sources källor';
  }

  @override
  String get reasoningExpandHint => 'tryck för att se steg';

  @override
  String get caseFileTitle => 'Ärendeakt';

  @override
  String get caseFileTimeline => 'Tidslinje';

  @override
  String get caseFileParties => 'Parter';

  @override
  String get caseFileDeadlines => 'Tidsfrister';

  @override
  String get caseFileExportPdf => 'Ladda ner akt (PDF)';

  @override
  String get caseFileEmpty =>
      'Chatta med AI:n om ditt ärende — din tidslinje byggs upp av sig själv.';

  @override
  String get caseFileDisclaimer =>
      'Denna akt extraheras automatiskt från din chatt. Det är inte juridisk rådgivning.';

  @override
  String get caseFileTabLabel => 'Ärende';

  @override
  String get refresh => 'Uppdatera';

  @override
  String get demoLimitReached =>
      'Demogräns nådd. Registrera dig gratis för att fortsätta.';

  @override
  String get demoLimitSignUpCta => 'Registrera dig';

  @override
  String get freeQuotaExhausted =>
      'Du har använt alla 10 gratismeddelanden den här månaden.';

  @override
  String get upgradeForUnlimited => 'Uppgradera till Pro för obegränsat';

  @override
  String get upgradeCta => 'Uppgradera';

  @override
  String get rateLimitTryAgain =>
      'Du skickar för snabbt. Försök igen om några sekunder.';

  @override
  String get quickProfilePrompt =>
      'För att jag ska kunna hjälpa dig mer precist, vad är din rättsliga status: är du estnisk medborgare, EU-medborgare från ett annat land, eller har du uppehållstillstånd?';

  @override
  String get quickProfileChipEstonianCitizen => 'Estnisk medborgare';

  @override
  String get quickProfileChipEuCitizen => 'EU-medborgare (annat land)';

  @override
  String get quickProfileChipResidencePermit => 'Uppehållstillstånd';

  @override
  String get quickProfileSkipBtn => 'Hoppa över';

  @override
  String get quickProfileSavedAck => 'Uppfattat. Vad är din fråga?';

  @override
  String get caseTitleLabel => 'Ärendetitel';

  @override
  String get jurisdictionLabel => 'Jurisdiktion';

  @override
  String get caseTypeLabel => 'Ärendetyp';

  @override
  String get caseLanguageLabel => 'Språk';

  @override
  String get caseNumbersSection => 'Ärendenummer';

  @override
  String get partiesSection => 'Parter';

  @override
  String get authoritiesSection => 'Myndigheter';

  @override
  String get timelineSection => 'Tidslinje';

  @override
  String get openQuestionsSection => 'Öppna frågor';

  @override
  String get nextActionsSection => 'Nästa åtgärder';

  @override
  String get summarySection => 'Sammanfattning';

  @override
  String get addRow => 'Lägg till rad';

  @override
  String get removeRow => 'Ta bort';

  @override
  String get archiveCase => 'Arkivera ärende';

  @override
  String get closeCase => 'Stäng ärende';

  @override
  String get continueChatAboutCase => 'Fortsätt chatten om detta ärende';

  @override
  String get linkChatToCase => 'Koppla till ärende';

  @override
  String get clearActiveCase => 'Rensa aktivt ärende';

  @override
  String get caseSavedAck => 'Ärendet sparat';

  @override
  String get caseArchivedAck => 'Ärendet arkiverat';

  @override
  String get intakeStep1Title => 'Var ligger ärendet?';

  @override
  String get intakeStep1Subtitle => 'Land och myndighet du har att göra med.';

  @override
  String get intakeJurisdictionLabel => 'Land / jurisdiktion';

  @override
  String get intakeAuthorityLabel => 'Typ av myndighet';

  @override
  String get intakeAuthorityNameLabel => 'Myndighetens namn (valfritt)';

  @override
  String get intakeAuthorityPolice => 'Polis';

  @override
  String get intakeAuthorityCourt => 'Domstol';

  @override
  String get intakeAuthoritySocial => 'Socialtjänst';

  @override
  String get intakeAuthorityEmployer => 'Arbetsgivare';

  @override
  String get intakeAuthorityLandlord => 'Hyresvärd';

  @override
  String get intakeAuthorityOpposingParty => 'Motpart';

  @override
  String get intakeAuthorityOther => 'Annat';

  @override
  String get intakeStep2Title => 'Vilken typ av ärende?';

  @override
  String get intakeStep2Subtitle =>
      'Välj den närmaste typen — du kan precisera senare.';

  @override
  String get intakeCaseTypeCriminal => 'Brottmål';

  @override
  String get intakeCaseTypeCivil => 'Tvistemål';

  @override
  String get intakeCaseTypeFamily => 'Familjerätt';

  @override
  String get intakeCaseTypeAdmin => 'Förvaltningsrätt';

  @override
  String get intakeCaseTypeImmigration => 'Migration';

  @override
  String get intakeCaseTypeLabor => 'Arbetsrätt';

  @override
  String get intakeCaseTypeConsumer => 'Konsumenträtt';

  @override
  String get intakeCaseTypeInheritance => 'Arvsrätt';

  @override
  String get intakeCaseTypeOther => 'Annat';

  @override
  String get intakeStep3Title => 'Vilka är inblandade?';

  @override
  String get intakeStep3Subtitle => 'Din roll och motparten.';

  @override
  String get intakeRoleLabel => 'Din roll';

  @override
  String get intakeRolePlaintiff => 'Kärande';

  @override
  String get intakeRoleDefendant => 'Svarande';

  @override
  String get intakeRoleVictim => 'Målsägande';

  @override
  String get intakeRoleAccused => 'Tilltalad';

  @override
  String get intakeRoleWitness => 'Vittne';

  @override
  String get intakeRoleFamily => 'Familjemedlem';

  @override
  String get intakeRoleOther => 'Annat';

  @override
  String get intakeOpposingSideLabel => 'Motpart (valfritt)';

  @override
  String get intakeWitnessesLabel => 'Vittnen (valfritt)';

  @override
  String get intakeAddWitness => 'Lägg till vittne';

  @override
  String get intakeWitnessHint => 'Namn eller kontakt';

  @override
  String get intakeStep4Title => 'Nummer och datum';

  @override
  String get intakeStep4Subtitle =>
      'Det du redan har. Hoppa över det du inte har.';

  @override
  String get intakeCaseNumberLabel => 'Ärendenummer (valfritt)';

  @override
  String get intakeIncidentDateLabel => 'Datum för händelsen (valfritt)';

  @override
  String get intakeIncidentDatePick => 'Välj datum';

  @override
  String get intakeDeadlinesLabel => 'Kända tidsfrister';

  @override
  String get intakeAddDeadline => 'Lägg till tidsfrist';

  @override
  String get intakeDeadlineWhatHint => 'Vad';

  @override
  String get intakeStep5Title => 'Dokument';

  @override
  String get intakeStep5Subtitle => 'Ladda upp allt relevant. Vi läser det.';

  @override
  String get intakeUploadDocsLabel => 'Ladda upp dokument';

  @override
  String get intakeSkipDocs => 'Hoppa över — jag laddar upp senare';

  @override
  String get intakeNextBtn => 'Nästa';

  @override
  String get intakeBackBtn => 'Tillbaka';

  @override
  String get intakeFinishBtn => 'Slutför och öppna chatt';

  @override
  String get intakeUrgentBtn => 'Brådskande — fråga nu';

  @override
  String get intakeUrgentDialogTitle => 'Öppna chatten nu?';

  @override
  String get intakeUrgentDialogBody =>
      'Vi sparar det du har angett som ett utkast till ärende. Du kan slutföra guiden från ärendesidan när som helst.';

  @override
  String get intakeUrgentConfirm => 'Öppna chatt';

  @override
  String get intakeUrgentCancel => 'Fortsätt fylla i';

  @override
  String get intakePreparingCase => 'Förbereder ditt ärende…';

  @override
  String get intakeFallbackGreeting =>
      'Jag ser ditt ärende. Berätta vad som är mest brådskande — så går vi igenom det tillsammans.';

  @override
  String get intakeUrgentGreeting =>
      'Jag ser att detta är brådskande. Ställ din fråga — jag fyller i resten allteftersom.';

  @override
  String intakeStepIndicator(int current, int total) {
    return 'Steg $current av $total';
  }

  @override
  String get intakeFieldRequired => 'Obligatoriskt';

  @override
  String intakeUploadProgress(int done, int total) {
    return 'Laddar upp $done / $total…';
  }

  @override
  String get uplDisclaimerFooter =>
      'Advocat är inte en advokatbyrå. Detta är information, inte juridisk rådgivning.';

  @override
  String get citationStatusVerifiedBadge => 'Verifierad';

  @override
  String get citationStatusUnverifiedBadge => 'Overifierad';

  @override
  String get citationStatusHistoricalBadge => 'Historisk version';

  @override
  String get citationStatusVerifiedTooltip =>
      'Citerad från en hämtad rättskälla.';

  @override
  String get citationStatusUnverifiedTooltip =>
      'AI:n citerade detta utan källhämtning — verifiera innan du förlitar dig på det.';

  @override
  String get citationStatusHistoricalTooltip =>
      'Den citerade bestämmelsen är inte längre i kraft.';

  @override
  String get citationOpenInRiigiTeataja => 'Öppna i Riigi Teataja';

  @override
  String get citationSnippetExpand => 'Visa fullständig text';

  @override
  String get citationSnippetCollapse => 'Visa mindre';

  @override
  String get citationUnverifiedSheetNote =>
      'AI:n citerade denna paragraf, men den hämtades inte från lagkorpus i denna förfrågan. Verifiera hänvisningen innan du förlitar dig på den.';

  @override
  String get citationFooterNoneWarning => 'Inga belagda citat';

  @override
  String citationFooterSummaryTotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count citat',
      one: '1 citat',
    );
    return '$_temp0';
  }

  @override
  String citationFooterSummaryVerified(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count verifierade',
      one: '1 verifierat',
    );
    return '$_temp0';
  }

  @override
  String citationFooterSummaryUnverified(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count overifierade',
      one: '1 overifierad',
    );
    return '$_temp0';
  }

  @override
  String citationFooterSummaryHistorical(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count historiska',
      one: '1 historisk',
    );
    return '$_temp0';
  }

  @override
  String get deadlineRadarTitle => 'Upcoming deadlines';

  @override
  String get deadlineRadarEmpty => 'No upcoming deadlines';

  @override
  String get deadlineRadarViewAll => 'View all';

  @override
  String deadlineCardDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'om $count dagar',
      one: 'om 1 dag',
      zero: 'idag',
    );
    return '$_temp0';
  }

  @override
  String get deadlineCardTomorrow => 'tomorrow';

  @override
  String get deadlineCardToday => 'today';

  @override
  String deadlineCardOverdue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dagar försenat',
      one: '1 dag försenat',
    );
    return '$_temp0';
  }

  @override
  String get deadlineCardMarkComplete => 'Mark complete';

  @override
  String get deadlineCardSnooze => 'Snooze';

  @override
  String get deadlineCardSnooze3d => 'Snooze 3 days';

  @override
  String get deadlineCardSnooze7d => 'Snooze 7 days';

  @override
  String get deadlineCardSnoozeCustom => 'Pick a date';

  @override
  String get deadlineCardEdit => 'Edit';

  @override
  String get deadlineCardDelete => 'Archive';

  @override
  String get deadlineCardSourceLabelPdf => 'from PDF';

  @override
  String get deadlineCardSourceLabelIntake => 'from intake';

  @override
  String get deadlineCardSourceLabelManual => 'added manually';

  @override
  String get deadlineCardSourceLabelEmail => 'from email';

  @override
  String get deadlineCardSourceLabelHaikuExtract => 'AI-extracted';

  @override
  String get deadlineCardSourceLabelStatutoryTemplate => 'statute template';

  @override
  String deadlineBannerCritical(String title, String when) {
    return 'Critical deadline $title $when';
  }

  @override
  String get deadlineBannerDismiss => 'Dismiss';

  @override
  String get deadlineBannerOpen => 'Open deadline';

  @override
  String deadlineHolidayShifted(String original, String reason) {
    return 'Shifted from $original due to $reason';
  }

  @override
  String get deadlinePermissionAskTitle => 'Enable deadline reminders?';

  @override
  String get deadlinePermissionAskBody =>
      'We\'ll ping you 7, 3, and 1 day before each statutory deadline, plus the morning of. Never used for marketing.';

  @override
  String get deadlinePermissionAllow => 'Allow';

  @override
  String get deadlinePermissionLater => 'Later';

  @override
  String get deadlineSettingsSection => 'Deadline reminders';

  @override
  String get deadlineSettingsPushChannel => 'Push notifications';

  @override
  String get deadlineSettingsEmailChannel => 'Email (critical only)';

  @override
  String get deadlineSettingsInAppChannel => 'In-app banners';

  @override
  String get deadlineSettingsCriticalBypass =>
      'Critical reminders bypass quiet hours';

  @override
  String get deadlineSettingsQuietHours => 'Quiet hours';

  @override
  String deadlineSettingsQuietHoursBadge(String start, String end) {
    return 'Quiet $start–$end';
  }

  @override
  String get deadlineCaseScreenTitle => 'Case deadlines';

  @override
  String get deadlineAddManualCta => 'Add deadline';

  @override
  String get deadlineFormTitle => 'Title';

  @override
  String get deadlineFormDescription => 'Description (optional)';

  @override
  String get deadlineFormStatuteTemplate => 'Statute template';

  @override
  String get deadlineFormStatuteTemplateNone => 'None (manual)';

  @override
  String get deadlineFormDeadlineAt => 'Deadline date';

  @override
  String get deadlineFormPriority => 'Priority';

  @override
  String get deadlineFormSave => 'Save';

  @override
  String get deadlineFormCancel => 'Cancel';

  @override
  String get deadlineCompletedNotePrompt => 'Add a note (optional)';

  @override
  String get deadlineCompletedNoteSave => 'Save';

  @override
  String get inboxTitle => 'Inbox';

  @override
  String get inboxEmptyTitle => 'Nothing pending';

  @override
  String get inboxEmptyBody =>
      'New email threads will appear here as they get triaged.';

  @override
  String get inboxApproveSend => 'Approve & send';

  @override
  String get inboxEditDraft => 'Edit';

  @override
  String get inboxSnooze => 'Snooze';

  @override
  String get inboxArchive => 'Archive';

  @override
  String get inboxFilterAll => 'All';

  @override
  String get inboxConfirmSendTitle => 'Send the prepared reply?';

  @override
  String get inboxConfirmSendBody =>
      'Advocat will dispatch the AI-prepared reply via your connected Gmail. You can still review the body in the next screen.';

  @override
  String get inboxSendButton => 'Send';

  @override
  String get inboxSentToast => 'Sent.';

  @override
  String get inboxAlreadySentToast => 'Already sent.';

  @override
  String get inboxSendErrorToast => 'Could not send the reply. Tap retry.';

  @override
  String get inboxSnoozedToast => 'Snoozed for 24h.';

  @override
  String get inboxArchivedToast => 'Archived.';

  @override
  String get inboxDraftLoadError => 'Could not load draft.';

  @override
  String get inboxDeadlineToday => 'today';

  @override
  String get inboxDeadlineTomorrow => 'tomorrow';

  @override
  String inboxDeadlineInDays(int days) {
    return 'in ${days}d';
  }

  @override
  String inboxDeadlineOverdue(int days) {
    return 'overdue ${days}d';
  }

  @override
  String parallelActionsHeadline(int count) {
    return 'Konsiliet rekommenderar $count parallella åtgärder';
  }

  @override
  String get parallelActionsApproveAll => 'Godkänn alla och skicka';

  @override
  String parallelActionsApproveSelected(int count, int total) {
    return 'Godkänn $count av $total';
  }

  @override
  String parallelActionsConfirmTitle(int count) {
    return 'Skicka $count e-postmeddelanden?';
  }

  @override
  String parallelActionsConfirmBody(int count) {
    return 'Advocat skickar $count förberedda svar via din anslutna Gmail. Varje meddelande skickas oberoende — om något misslyckas går de andra ändå iväg.';
  }

  @override
  String parallelActionsSentToast(int count) {
    return '$count skickade.';
  }

  @override
  String parallelActionsPartialFailureToast(int sent, int failed) {
    return '$sent skickade, $failed misslyckades.';
  }

  @override
  String get parallelActionsKindReply => 'svar';

  @override
  String get parallelActionsKindNew => 'nytt';

  @override
  String get parallelActionsCheckboxSelected => 'Åtgärd vald';

  @override
  String get parallelActionsCheckboxUnselected => 'Åtgärd inte vald';

  @override
  String parallelActionsCitationCount(int count) {
    return '$count hänv.';
  }

  @override
  String parallelActionsRetryFailed(int count) {
    return 'Försök misslyckade igen ($count)';
  }

  @override
  String get agentApprovalNeedsReviewTitle =>
      'Advocat behöver ditt godkännande';

  @override
  String get agentApprovalResolvedTitle => 'Åtgärden hanterad';

  @override
  String get agentApprovalStepsLabel => 'steg';

  @override
  String get agentApprovalApproveButton => 'Godkänn och skicka';

  @override
  String get agentApprovalDeclineButton => 'Avböj';

  @override
  String get agentApprovalAttachmentsLabel => 'Bilagor';

  @override
  String get agentApprovalSentSummary => 'Skickat för din räkning.';

  @override
  String get agentApprovalDeclinedSummary => 'Avböjt — inget skickades.';

  @override
  String get agentToolDraftEmailAtt => 'Skicka e-post med bilagor';

  @override
  String get agentToolSendEmail => 'Skicka e-post';

  @override
  String get agentToolGeneratePdf => 'Generera PDF';

  @override
  String get agentToolApproveSend => 'Skicka förberett svar';

  @override
  String get inboxErrorTitle => 'Kunde inte läsa in inkorgen';

  @override
  String get inboxEditDiscardTitle => 'Kassera osparade ändringar?';

  @override
  String get inboxEditDiscardBody =>
      'Du har osparade ändringar i detta utkast. Om du går tillbaka kasseras de.';

  @override
  String get inboxEditKeepEditing => 'Fortsätt redigera';

  @override
  String get inboxEditDiscard => 'Kassera';

  @override
  String get workspaceTabOverview => 'Overview';

  @override
  String get workspaceTabChat => 'Chat';

  @override
  String get workspaceTabDrafts => 'Drafts';

  @override
  String get workspaceOverviewEmpty => 'Add documents to build a summary.';

  @override
  String get workspaceTimelineEmpty => 'No events yet.';

  @override
  String get workspaceDocumentsEmpty => 'No documents. Upload from Scan.';

  @override
  String get workspaceDraftsEmpty => 'No drafts yet.';

  @override
  String get workspaceInboxEmpty => 'No related email.';

  @override
  String get plannerSettingsTitle => 'Juridiskt resonemang i tre steg';

  @override
  String get plannerSettingsSubtitle =>
      'Planera → svara → granska. Långsammare men mer grundligt.';

  @override
  String get plannerSettingsProBadge => 'Pro';

  @override
  String get plannerSettingsProDescription => 'Tillgängligt med Pro-abonnemang';

  @override
  String get plannerTrailHeaderPlan => 'Plan';

  @override
  String get plannerTrailHeaderCritique => 'Granskning';

  @override
  String get plannerTrailSubQuestions => 'Delfrågor';

  @override
  String get plannerTrailCounterArgs => 'Motargument';

  @override
  String get plannerTrailEvidenceGaps => 'Bevisluckor';

  @override
  String get plannerTrailMaterialGapTrue => 'Väsentlig lucka upptäckt';

  @override
  String get plannerTrailRegeneratedBadge => 'Omgenererat en gång';

  @override
  String get plannerTrailEmpty => 'inga poster';

  @override
  String get supportTitle => 'Hjälp';

  @override
  String get supportSubtitle => 'Vi svarar vanligtvis inom 1–2 timmar.';

  @override
  String get supportSearchPlaceholder => 'Sök i hjälpen…';

  @override
  String get supportStatusAllOk => 'Alla system fungerar normalt';

  @override
  String get supportFaqWhatIs => 'Vad är Advocat?';

  @override
  String get supportFaqHowSubscribe => 'Hur prenumererar jag på Pro?';

  @override
  String get supportFaqExportData => 'Kan jag exportera mina data?';

  @override
  String get supportFaqCancelAccount => 'Avsluta eller radera konto';

  @override
  String get supportFaqTalkHuman => 'Prata med en människa';

  @override
  String get supportContactEmail => 'E-post';

  @override
  String get supportContactTelegram => 'Telegram';

  @override
  String get supportContactWhatsapp => 'WhatsApp';

  @override
  String get supportFooterSla => 'Vi svarar inom 24 h';

  @override
  String get supportWhatsapp => 'WhatsApp';

  @override
  String get supportEmail => 'E-post';

  @override
  String get supportInApp => 'Skriv till oss här';

  @override
  String get supportCategoryLabel => 'Kategori';

  @override
  String get supportCategoryBug => 'Bugg';

  @override
  String get supportCategoryPayment => 'Betalningsproblem';

  @override
  String get supportCategoryQuestion => 'Fråga';

  @override
  String get supportCategoryFeature => 'Funktionsförslag';

  @override
  String get supportCategoryOther => 'Annat';

  @override
  String get supportMessagePlaceholder => 'Beskriv ditt problem...';

  @override
  String get supportEmailLabel => 'E-post (valfritt)';

  @override
  String get supportSend => 'Skicka';

  @override
  String get supportSentSuccess => 'Meddelandet skickat! Vi svarar snart.';

  @override
  String get supportError => 'Något gick fel. Försök igen.';

  @override
  String get supportErrorTooShort => 'Skriv minst 10 tecken.';

  @override
  String get supportErrorTooLong => 'Högst 2000 tecken.';

  @override
  String get supportPrivacyNotice => 'Ditt meddelande lagras säkert.';

  @override
  String get reviewThisContract => 'Granska kontraktet';

  @override
  String get contractReviews => 'Avtalsgranskningar';

  @override
  String get contractReviewsFreeFeature =>
      '1 avtalsgranskning (provning för livstid)';

  @override
  String get contractReviewsCounselFeature => '5 avtalsgranskningar per månad';

  @override
  String get contractReviewsProFeature => '20 avtalsgranskningar per månad';

  @override
  String contractReviewsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kontraktsgranskningar kvar denna månad',
      one: '1 kontraktsgranskning kvar denna månad',
      zero: 'Inga kontraktsgranskningar kvar denna månad',
    );
    return '$_temp0';
  }

  @override
  String get contractReviewsExhausted =>
      'Inga avtalsgranskningar kvar denna månad';

  @override
  String get contractReviewsFreeTrialLeft =>
      'Gratis provning: 1 avtalsgranskning';

  @override
  String get contractReviewsFreeTrialUsed =>
      'Gratis provning använd — uppgradera';

  @override
  String get contractReviewsUpgradeTitle => 'Avtalsgranskningar slut';

  @override
  String get contractReviewsUpgradeBodyFree =>
      'Du har använt din gratis avtalsgranskning. Uppgradera för månatliga granskningar.';

  @override
  String contractReviewsUpgradeBodyPaid(int used, int cap) {
    return 'Du har använt $used av $cap granskningar denna månad. Uppgradera för en högre månadsgräns.';
  }

  @override
  String get contractReviewsUpgradeCounselCta =>
      'Uppgradera till Counsel (€19,99/mån) — 5 granskningar';

  @override
  String get contractReviewsUpgradeProCta =>
      'Uppgradera till Pro (€29,99/mån) — 20 granskningar';

  @override
  String get contractReviewsUpgradeToProShort => 'Uppgradera till Pro — 20/mån';

  @override
  String get notNow => 'Inte nu';

  @override
  String get referralTitle => 'Bjud in vänner';

  @override
  String get referralSubtitle => 'Få en gratis månad. Ge en gratis månad.';

  @override
  String get referralYourLink => 'DIN LÄNK';

  @override
  String get referralCopyLink => 'Kopiera länk';

  @override
  String get referralShare => 'Dela';

  @override
  String get referralLinkCopied => 'Länk kopierad';

  @override
  String get referralStatsInvited => 'Inbjudna';

  @override
  String get referralStatsConverted => 'Konverterade';

  @override
  String get referralStatsEarned => 'Gratis månader';

  @override
  String get referralShareWhatsApp => 'Dela på WhatsApp';

  @override
  String get referralShareTelegram => 'Dela på Telegram';

  @override
  String get referralShareEmail => 'Dela via e-post';

  @override
  String get referralEmailSubject =>
      'Prova Advocat — din juridiska AI-assistent';

  @override
  String get referralLoadError =>
      'Kunde inte ladda data. Dra nedåt för att uppdatera.';

  @override
  String get referralRetry => 'Försök igen';

  @override
  String get referralSettingsTile => 'Bjud in vänner';

  @override
  String get referralAfterReviewCta =>
      'Gillade du det? Bjud in en vän — båda får en gratis månad.';

  @override
  String get referralAntiFraud => 'Högst 12 lyckade värvningar per år.';

  @override
  String get referralEmpty =>
      'Inga värvningar ännu. Skicka din länk för att börja tjäna.';

  @override
  String get referralRecentActivity => 'Senaste aktivitet';

  @override
  String referralActivityInvited(String when) {
    return 'Bjöd in $when';
  }

  @override
  String referralActivityActivated(String when) {
    return 'aktiverade $when';
  }

  @override
  String get referralActivityPending => 'inte aktiverad ännu';

  @override
  String referralStatsInvitedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vänner',
      one: '1 vän',
      zero: 'inga vänner ännu',
    );
    return 'Du har bjudit in $_temp0';
  }

  @override
  String referralStatsConvertedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count har aktiverat',
      one: '1 har aktiverat',
      zero: 'ingen har aktiverat ännu',
    );
    return '$_temp0';
  }

  @override
  String referralStatsEarnedCount(int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months gratis månader',
      one: '1 gratis månad',
      zero: 'inget ännu',
    );
    return 'Din bonus: $_temp0';
  }

  @override
  String get referralNudgeMessage =>
      'Gillar du Advocat? Bjud in en vän — båda får en gratis månad.';

  @override
  String get referralNudgeAction => 'Bjud in';

  @override
  String get referralLandingTitle => 'Du har blivit inbjuden till Advocat';

  @override
  String referralLandingSubtitle(String inviterName) {
    return '$inviterName bjöd in dig — hämta din gratis första månad.';
  }

  @override
  String get referralLandingSubtitleGeneric =>
      'Hämta din gratis första månad av Advocat Pro.';

  @override
  String get referralLandingCta => 'Aktivera gratis månad och registrera dig';

  @override
  String get referralLandingCtaSecondary => 'Eller läs mer om Advocat';

  @override
  String get referralLandingFallback =>
      'Den här länken har gått ut — men du kan ändå prova Advocat gratis.';

  @override
  String get referralLandingBenefits =>
      '17 språk • Verklig estnisk, finsk och EU-rätt • Dygnet runt — ingen väntan';

  @override
  String get checkerProTagline => 'Professionella verifieringsverktyg';

  @override
  String get checkerDataSource => 'Data från officiella register';

  @override
  String get companyCheckerHint => 'Företagsnamn eller organisationsnummer';

  @override
  String get companyCheckerPriceChip => '€2.99 per kontroll  •  Ingår i Pro';

  @override
  String get companyCheckerEmptyState =>
      'Ange företagsnamn eller organisationsnummer\nför att få en fullständig rapport';

  @override
  String get aiMemoryTitle => 'AI-minne';

  @override
  String get aiMemorySubtitle => 'Granska och radera vad AI minns om dig';

  @override
  String get bookLawyerCallTitle => 'Boka ett samtal med en jurist';

  @override
  String get bookLawyerCallComingSoonTitle =>
      'Samtal med en riktig jurist — öppnar snart';

  @override
  String get bookLawyerCallComingSoonBody =>
      'Pro och Premium inkluderar 15-minuters samtal med en partnerjurist (1/kvartal i Pro, 2/kvartal i Premium). Vi färdigställer det estniska nätverket av enskilda jurister och mejlar dig så snart bokning öppnar.';

  @override
  String bookLawyerCallQuotaAvailable(int remaining, int total) {
    return 'Du har $remaining av $total samtal kvar detta kvartal.';
  }

  @override
  String get bookLawyerCallQuotaExhausted => 'Kvartalskvoten är slut.';

  @override
  String get bookLawyerCallQuotaBodyAvailable =>
      'Pro innehåller 1 samtal/kvartal, Premium 2. Samtalen varar 15 minuter via Google Meet.';

  @override
  String get bookLawyerCallQuotaBodyExhausted =>
      'Din kvot nollställs den första dagen i nästa kvartal. Behöver du prata tidigare? Uppgradera till Premium för ett extra samtal.';

  @override
  String get severityCritical => 'KRITISK';

  @override
  String get severityHigh => 'HÖG';

  @override
  String get severityMedium => 'MEDEL';

  @override
  String get severityLow => 'LÅG';

  @override
  String get deadlineRequiredFields => 'Titel och slutdatum krävs';

  @override
  String get acceptTermsRequired => 'Godkänn användarvillkoren';

  @override
  String get chatLegalCouncilTooltip => 'Juridiskt råd (4 experter)';

  @override
  String get attachFileTooltip => 'Bifoga fil';

  @override
  String get sendMessage => 'Skicka meddelande';

  @override
  String get stopGenerating => 'Stoppa generering';

  @override
  String get showPassword => 'Visa lösenord';

  @override
  String get hidePassword => 'Dölj lösenord';

  @override
  String get decreaseDependents => 'Minska';

  @override
  String get increaseDependents => 'Öka';

  @override
  String get sensitiveConsentTitle => 'Samtycke till känsliga uppgifter';

  @override
  String get sensitiveConsentBody =>
      'Dokument du är på väg att ladda upp kan innehålla särskilda kategorier av personuppgifter enligt GDPR art. 9 — såsom hälsouppgifter, uppgifter om brott, biometriska uppgifter eller uppgifter om ditt etniska ursprung, din religion eller sexuella läggning.\n\nVi behandlar dessa uppgifter enbart för att ge dig juridisk AI-hjälp, lagrar dem krypterat på ditt privata konto och använder dem aldrig för att träna modeller. Du kan återkalla samtycket och radera uppgifterna när som helst i Inställningar.\n\nGenom att godkänna ger du ditt uttryckliga samtycke enligt art. 9.2 a GDPR till att behandla särskilda kategorier av uppgifter för detta ändamål.';

  @override
  String get sensitiveConsentExplicitCheckbox =>
      'Jag ger mitt uttryckliga samtycke till att behandla särskilda kategorier av uppgifter (art. 9.2 a GDPR).';

  @override
  String get sensitiveConsentRightToShareCheckbox =>
      'Jag bekräftar att jag har rätt att dela dessa uppgifter (uppgifterna är mina, eller jag har informerat/lagligt stöd för att dela tredje parts uppgifter).';

  @override
  String get sensitiveConsentViewCategories =>
      'Se vad som räknas som känsligt →';

  @override
  String get sensitiveConsentWithdrawAction =>
      'Återkalla samtycke till känsliga uppgifter';

  @override
  String get privacyAndData => 'INTEGRITET OCH DATA';

  @override
  String get exportMyDataSubtitle =>
      'Ladda ner en kopia av alla dina personuppgifter (GDPR art. 15).';

  @override
  String get withdrawSensitiveConsent => 'Samtycke till känsliga uppgifter';

  @override
  String get withdrawSensitiveConsentSubtitle =>
      'Hantera eller återkalla samtycke till att behandla särskilda kategorier av uppgifter (GDPR art. 9.2 a).';

  @override
  String get dataProcessingAgreement => 'Personuppgiftsbiträdesavtal';

  @override
  String get exportingData => 'Exporterar dina data…';

  @override
  String get exportComplete => 'Dataexporten är klar — sparad på din enhet.';

  @override
  String get exportFailed =>
      'Exporten misslyckades. Försök igen eller kontakta supporten.';

  @override
  String get quotaExhaustedTitle => 'Gräns för gratismeddelanden nådd';

  @override
  String quotaExhaustedBody(int count) {
    return 'Du har använt alla $count gratismeddelanden. Uppgradera till Advocat Counsel för 19,99 €/månad och få obegränsade juridiska AI-konsultationer.';
  }

  @override
  String get quotaExhaustedLater => 'Senare';

  @override
  String get quotaExhaustedUpgrade => 'Advocat Counsel — 19,99 €/mån';

  @override
  String quotaCtaMessage(int count) {
    return 'Du har använt alla $count gratismeddelanden. Uppgradera till Advocat Counsel för 19,99 €/månad.';
  }

  @override
  String get quotaCtaButton => 'Skaffa Advocat Counsel — 19,99 €/mån';

  @override
  String get aiErrorQuota =>
      'Gräns för gratismeddelanden nådd. Prenumerera för att fortsätta använda AI:n.';

  @override
  String get aiErrorAuth =>
      'Inloggning krävs för att använda AI:n. Registrera dig eller logga in.';

  @override
  String get aiErrorGeneric =>
      'Tillfälligt AI-fel. Försök igen om en minut. Kontakta supporten om det kvarstår.';

  @override
  String get tooltipShareCase => 'Dela ärendesammanfattning';

  @override
  String get tooltipMuteVoice => 'Stäng av röst';

  @override
  String get tooltipUnmuteVoice => 'Slå på röst';

  @override
  String get tooltipAttachDoc => 'Bifoga dokument';

  @override
  String get aiTypingHint => 'AI…';

  @override
  String get error404Title => 'Sidan hittades inte';

  @override
  String error404Body(String path) {
    return 'Vi kunde inte hitta: $path';
  }

  @override
  String get goToHome => 'Gå till startsidan';

  @override
  String get emailAlreadyRegistered =>
      'Den här e-postadressen är redan registrerad. Vill du logga in?';

  @override
  String get actionSignIn => 'Logga in';

  @override
  String get actionUndo => 'Ångra';

  @override
  String get intakeUrgentOpened => 'Chatten öppnad — ditt utkast är sparat.';

  @override
  String get panicCoachmark => 'Håll inne för akut hjälp.';

  @override
  String get panicTitle => 'Vad behöver du just nu?';

  @override
  String get panicCardReadAloud => 'Läs upp för polisen';

  @override
  String get panicCardRecord => 'Spela in det här samtalet';

  @override
  String get panicCardCall => 'Ring en jurist';

  @override
  String get panicCardAi => 'Prata med Advocat nu';

  @override
  String get panicClose => 'Stäng';

  @override
  String get panicBadgeV2 => 'V2';

  @override
  String get panicRecordV1Title => 'Kommer i V2';

  @override
  String get panicRecordV1Body =>
      'Inspelningsfunktionen genomgår en juridisk validering för Estland och lanseras i V2. Använd tills vidare din telefons inbyggda röstinspelare.';

  @override
  String get panicCallFallbackBody =>
      'Mejla kiire@advocat.ee med en kort beskrivning så ringer vi tillbaka.';

  @override
  String get consiliumHeader => 'Juridiskt konsilium';

  @override
  String consiliumProgress(int count, int total) {
    return '$count av $total klara';
  }

  @override
  String get consiliumStarting => 'Juristerna granskar ditt ärende…';

  @override
  String get consiliumDisagreement => 'Experterna är oeniga';

  @override
  String get consiliumSynthesizing => 'Sammanställer rekommendation…';

  @override
  String consiliumDone(int totalRoles) {
    return 'Konsilium klart · $totalRoles experter';
  }

  @override
  String get consiliumPositionPush => 'Bestrid';

  @override
  String get consiliumPositionSettle => 'Förlik';

  @override
  String get consiliumPositionInvestigate => 'Utred';

  @override
  String get consiliumPositionOutOfScope => 'Utanför behörigheten';

  @override
  String get consiliumConfidence => 'Säkerhet';

  @override
  String get consiliumKeyCitation => 'Central källa';

  @override
  String get consiliumAdversarialRound => 'Kontradiktorisk runda';

  @override
  String get consiliumViewFullOpinion => 'Visa fullständigt yttrande';

  @override
  String consiliumExpertsAgreed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count experter håller med',
      one: '1 expert håller med',
    );
    return '$_temp0';
  }

  @override
  String consiliumExpertsDisagree(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count experter oense',
      one: '1 expert oense',
    );
    return '$_temp0';
  }

  @override
  String get consiliumDisclaimer =>
      'AI-agenter, inte mänskliga jurister. Verifiera väsentliga beslut med en auktoriserad advokat.';

  @override
  String get softCaseShellBanner =>
      'Vi skapade \"Namnlöst ärende\" för att spåra detta. Tryck för att byta namn.';

  @override
  String get softCaseShellBannerCta => 'Byt namn';

  @override
  String get draftsTab => 'Drafts';

  @override
  String get draftingTitle => 'Drafting Studio';

  @override
  String get draftingEmpty => 'Empty draft';

  @override
  String get draftingPlaceholder => 'Start typing your draft…';

  @override
  String get draftingDraftsList => 'My drafts';

  @override
  String get draftingSave => 'Save';

  @override
  String get draftingSaved => 'Saved';

  @override
  String get draftingSavedJustNow => 'Saved just now';

  @override
  String get draftingAiRevise => 'Revise with AI';

  @override
  String get draftingExportPdf => 'Export PDF';

  @override
  String get draftingExportDocx => 'Export DOCX';

  @override
  String get draftingExportMd => 'Export Markdown';

  @override
  String get draftingDeleteDraft => 'Delete draft';

  @override
  String get draftingConfirmDelete => 'Delete this draft?';

  @override
  String get draftingConfirmDeleteMessage => 'This action cannot be undone.';

  @override
  String get draftingConfirm => 'Delete';

  @override
  String get draftingCancel => 'Cancel';

  @override
  String draftingDraftReplyTo(String name) {
    return 'Reply to $name';
  }

  @override
  String get draftingUntitled => 'Untitled';

  @override
  String get draftingTitleHint => 'Title (optional)';

  @override
  String get draftingAiReviseTitle => 'Revise with AI';

  @override
  String get draftingAiReviseSelectionLabel => 'Selected text:';

  @override
  String get draftingAiReviseInstructionLabel => 'Instruction (optional)';

  @override
  String get draftingAiReviseInstructionHint =>
      'e.g. \"make it more formal\" or \"shorten\"';

  @override
  String get draftingAiReviseRunButton => 'Generate revision';

  @override
  String get draftingAiReviseSuggestionLabel => 'Suggested revision:';

  @override
  String get draftingAiReviseChangesLabel => 'Changes:';

  @override
  String get draftingAiReviseAccept => 'Accept';

  @override
  String get draftingAiReviseReject => 'Reject';

  @override
  String get draftingFormatBold => 'Bold';

  @override
  String get draftingFormatItalic => 'Italic';

  @override
  String get draftingFormatHeading => 'Heading';

  @override
  String get draftingFormatBullet => 'Bullet list';

  @override
  String get draftingFormatNumbered => 'Numbered list';

  @override
  String get draftingEmptyListMessage => 'You have no drafts yet.';

  @override
  String get draftingEmptyListAction => 'New draft';

  @override
  String get draftingExporting => 'Exporting…';

  @override
  String get draftingExportFailed => 'Export failed';

  @override
  String get draftingSaveFailed => 'Save failed';

  @override
  String get draftingNewDraft => 'New draft';

  @override
  String get vaultNoteChip => 'Vault note';

  @override
  String get saveToVault => 'Save to Vault';

  @override
  String get savingToVault => 'Saving to Vault…';

  @override
  String get savedToVault => 'Saved to Vault';

  @override
  String get vaultNoteTitlePrefix => 'Note: ';

  @override
  String get openInVault => 'Open in Vault';

  @override
  String get saveToVaultFailed => 'Save to Vault failed';

  @override
  String get pdfWorkerUnavailable =>
      'PDF export is temporarily unavailable. Please try DOCX or Markdown.';

  @override
  String get draftingVersionHistory => 'Version history';

  @override
  String get emptyHomeTitle => 'Welcome to Advocat';

  @override
  String get emptyHomeBody =>
      'Pick a starting point — we’ll handle the legal heavy lifting.';

  @override
  String get intentChip1 => 'Got a fine';

  @override
  String get intentChip2 => 'Permit denied';

  @override
  String get intentChip3 => 'Contract problem';

  @override
  String get emptyCasesTitle => 'No cases yet';

  @override
  String get emptyCasesCta => 'Start a case';

  @override
  String get emptyDraftsTitle => 'No drafts yet';

  @override
  String get emptyDraftsCta => 'Create draft';

  @override
  String get emptyChatTitle => 'Ask Advocat anything';

  @override
  String get chatExamplePrompt1 => 'Help me reply to a fine';

  @override
  String get chatExamplePrompt2 => 'Review my rental contract';

  @override
  String get chatExamplePrompt3 => 'What are my rights at work?';

  @override
  String get dangerZone => '[en] Danger zone';

  @override
  String get deleteAccountConfirmButton => '[en] Delete forever';

  @override
  String deleteAccountConfirmHint(String email) {
    return '[en] Type $email to confirm';
  }

  @override
  String get deleteAccountSuccess =>
      '[en] Account deleted. We\'re sorry to see you go.';

  @override
  String get deleteAccountWarning =>
      '[en] This permanently deletes your account, all cases, drafts, vault documents, and chat history. This cannot be undone.';

  @override
  String get deletingAccount => '[en] Deleting account…';

  @override
  String get contractReviewTitle => 'Contract Review';

  @override
  String get contractReviewUploadCta => 'Upload contract';

  @override
  String get contractReviewQuotaRemaining =>
      'Upload a PDF, DOC, DOCX, or TXT contract for an AI review with red flags and negotiation tips.';

  @override
  String get contractReviewRedFlags => 'Red flags';

  @override
  String get contractReviewReviewPoints => 'Review points';

  @override
  String get contractReviewNegotiationTips => 'Negotiation tips';

  @override
  String get contractReviewSaveToVault => 'Save to Vault';

  @override
  String get contractReviewContinueChat => 'Continue in chat';

  @override
  String get referralInviteFriends => 'Invite Friends';

  @override
  String get referralYourCode => 'Your code';

  @override
  String get referralCopiedToast => 'Code copied to clipboard';

  @override
  String get referralReward =>
      'Get 1 month of Counsel free for every friend who subscribes.';

  @override
  String get referralInvited => 'Friends invited';

  @override
  String get referralRewardsEarned => 'Free months earned';

  @override
  String get deadlineUrgencyToday => 'Today & Overdue';

  @override
  String get deadlineUrgencyWeek => 'This week';

  @override
  String get deadlineUrgencyMonth => 'This month';

  @override
  String get deadlineUrgencyLater => 'Later';

  @override
  String get deadlineAddManual => 'Add deadline';

  @override
  String get deadlineSnoozeBy => 'Snooze';

  @override
  String get deadlineSnooze1d => 'Snooze 1 day';

  @override
  String get deadlineSnooze3d => 'Snooze 3 days';

  @override
  String get deadlineSnooze7d => 'Snooze 7 days';

  @override
  String get deadlineDismiss => 'Dismiss';

  @override
  String get deadlineExportIcs => 'Add to calendar';

  @override
  String get deadlineSource => 'Source';

  @override
  String get deadlineEmpty =>
      'No deadlines yet. Deadlines are auto-created from your emails and documents — or add one manually with the + button.';

  @override
  String get deadlineNewTitle => 'New deadline';

  @override
  String get deadlineFieldTitle => 'Title';

  @override
  String get deadlineFieldDueDate => 'Due date';

  @override
  String get deadlineFieldNotes => 'Notes (optional)';

  @override
  String get deadlineSaved => 'Deadline saved';

  @override
  String get deadlineSaveFailed => 'Could not save deadline';

  @override
  String get deadlineUrgentBannerSingle => '1 deadline today or overdue';

  @override
  String deadlineUrgentBannerMany(int count) {
    return '$count deadlines today or overdue';
  }

  @override
  String deadlineDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days left',
      one: '1 day left',
      zero: 'today',
    );
    return '$_temp0';
  }

  @override
  String deadlineDaysOverdue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days overdue',
      one: '1 day overdue',
    );
    return '$_temp0';
  }

  @override
  String get iapPayWithApple => 'Betala med Apple';

  @override
  String get iapRestorePurchases => 'Återställ köp';

  @override
  String get iapPurchaseFailed =>
      'Köpet misslyckades. Försök igen eller kontakta supporten.';

  @override
  String get iapRestoreSuccess => 'Din prenumeration har återställts.';

  @override
  String get iapRestoreNoActive => 'Inget aktivt abonnemang att återställa.';

  @override
  String get deadlineEuRadarTitle => 'EU deadline radar (preview)';

  @override
  String get deadlineEuRadarSubtitle =>
      'Hypothetical EU procedural deadlines — mock data';
}
