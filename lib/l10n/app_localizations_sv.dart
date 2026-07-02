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
  String get appearance => 'Utseende';

  @override
  String get appearanceSystem => 'System (auto)';

  @override
  String get appearanceLight => 'Ljust';

  @override
  String get appearanceDark => 'Mörkt';

  @override
  String get appearanceDescription => 'Välj hur Advocat ser ut';

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
  String get aiAnalyzing => 'AI analyserar';

  @override
  String get speakIntoMicHint =>
      'Tala in i mikrofonen. Se till att mikrofonåtkomst är aktiverad.';

  @override
  String get aiErrorRateLimit =>
      'Tjänsten är tillfälligt överbelastad. Försök igen om 1–2 minuter.';

  @override
  String get aiErrorOverload =>
      'AI:n är upptagen just nu, försök igen om en minut.';

  @override
  String freeLimitReached(int count) {
    return 'Du har använt alla $count kostnadsfria AI-meddelanden. Uppgradera till Legal Counsel för obegränsad AI-hjälp!';
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
  String get rateAppComingSoon => 'Kommer snart till appbutikerna!';

  @override
  String get dataCopiedToClipboard => 'Data kopierad till urklipp';

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
  String get fiveAiMessagesTotal => '5 AI-meddelanden (livstid)';

  @override
  String get hundredAiMessagesDay => '100 AI-meddelanden/dag';

  @override
  String get unlimitedAiMessages => 'Obegränsade AI-meddelanden';

  @override
  String get voiceInput => 'Röstinmatning';

  @override
  String get strategyRecommendations => 'Strategirekommendationer';

  @override
  String get foundingMemberNote =>
      'Grundande medlem: 9,99 €/mån de första 3 månaderna';

  @override
  String get saveTwentyPercent => 'Spara 20 %';

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
      'Hej! Jag är Advocat — din juridiska AI-assistent. Jag ger juridisk information, inte juridisk rådgivning. Vilken juridisk fråga kan jag hjälpa till med?';

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
      'Advocat är AI-genererad juridisk information, inte juridisk rådgivning. Kontrollera med en legitimerad jurist innan du agerar.';

  @override
  String get aiDisclaimerFullTitle => 'Viktigt: så fungerar Advocat';

  @override
  String get aiDisclaimerFullBody =>
      'Advocat är ett verktyg baserat på artificiell intelligens som ger juridisk information, inte juridisk rådgivning. Enligt EU:s AI-förordning (art. 50) måste vi tydligt informera dig: du interagerar med AI, inte med en mänsklig jurist.\n\nAdvocat är ingen advokatbyrå. Vi är inte legitimerade advokater enligt den estniska Advokatuuriseadus eller den finska Asianajajalaki, och advokatsekretess gäller inte för dina samtal med detta verktyg. Innan du förlitar dig på något svar — för att överklaga, skriva under ett avtal eller agera inom en tidsfrist — kontrollera med en legitimerad jurist i din jurisdiktion.';

  @override
  String get aiDisclaimerExpand => 'Läs mer';

  @override
  String get aiDisclaimerDismiss => 'OK, jag förstår';

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
      'Jag samtycker till behandling av mina uppgifter för juridisk AI-hjälp (krävs)';

  @override
  String get gdprConsentAnalytics =>
      'Jag samtycker till analys för att förbättra tjänsten (valfritt)';

  @override
  String get gdprArt9Intro =>
      'Denna app behandlar särskilda kategorier av personuppgifter enligt GDPR artikel 9, inklusive:';

  @override
  String get gdprSpecialLegalCases =>
      'Dina juridiska ärendedetaljer och domstolshandlingar';

  @override
  String get gdprSpecialNationality => 'Nationalitet och uppehållsstatus';

  @override
  String get gdprConsentLegalData =>
      'Jag samtycker till att mina juridiska ärendeuppgifter, nationalitet och uppehållsstatus behandlas av AI (krävs)';

  @override
  String get gdprConsentVoice =>
      'Jag samtycker till behandling av röstinspelningar (valfritt)';

  @override
  String get gdprViewPrivacyPolicy => 'Visa integritetspolicy';

  @override
  String get legalInformation => 'Juridisk information';

  @override
  String get legalEntityName => 'Vorantis OÜ';

  @override
  String get legalRegistryCode => 'Registreringskod: 17098992';

  @override
  String get legalAddress =>
      'Harju maakond, Tallinn, Kesklinna linnaosa, Tornimäe tn 5, 10145';

  @override
  String get legalEmail => 'E-post: support@advocat.ee';

  @override
  String get legalRegistry =>
      'Registrerad i det estniska handelsregistret (Äriregister)';

  @override
  String get aiGeneratedDisclaimer => 'AI-genererat • Inte juridisk rådgivning';

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
      'Brottsoffers rättigheter, akuthjälp, besöksförbud';

  @override
  String get rightCallEmergency =>
      'Du har rätt att ringa 112 i alla nödsituationer — polis, ambulans, brandkår';

  @override
  String get rightVictimProtection =>
      'Som brottsoffer har du rätt till skydd, stöd och information om ditt ärende';

  @override
  String get rightRestrainingOrder =>
      'Du kan ansöka om besöksförbud (lähestymiskielto) för att hålla förövaren borta';

  @override
  String get rightVictimInterpreter =>
      'Du har rätt till tolk under alla rättsliga förfaranden';

  @override
  String get rightMedicalHelp =>
      'Du har rätt till omedelbar sjukvård och dokumentation av skador';

  @override
  String get rightShelter =>
      'Du har rätt till akut skyddat boende — kontakta ett skyddat boende eller socialtjänsten';

  @override
  String get mustReportDanger =>
      'Om någon är i omedelbar fara, ring 112 omedelbart';

  @override
  String get mustDocumentInjuries =>
      'Dokumentera alla skador — foton, journaler, skriftliga anteckningar';

  @override
  String get domesticActionCallEmergency =>
      'Ring 112 om du är i omedelbar fara';

  @override
  String get domesticActionGoToSafe =>
      'Bege dig till en trygg plats — skyddat boende, vän, offentlig plats';

  @override
  String get domesticActionDocumentEverything =>
      'Dokumentera skador: ta foton, skaffa journalanteckningar';

  @override
  String get domesticActionFilePoliceReport =>
      'Gör en polisanmälan — du kan göra detta senare också';

  @override
  String get domesticActionContactShelter =>
      'Kontakta ett skyddat boende eller en kristelefon';

  @override
  String get domesticActionApplyRestraining =>
      'Ansök om besöksförbud via polisen eller domstolen';

  @override
  String get domesticFactRestrainingOrder =>
      'I Finland kan ett besöksförbud (lähestymiskielto) utfärdas även utan ett brottmål. Det förbjuder personen att kontakta eller närma sig dig.';

  @override
  String get domesticFactVictimDirective =>
      'Enligt EU:s brottsofferdirektiv 2012/29/EU har du rätt att bli behandlad med respekt, att få information på ett språk du förstår och att få tillgång till stödtjänster för brottsoffer — oavsett din uppehållsstatus.';

  @override
  String get domesticDeadlinePoliceReport =>
      'Gör en polisanmälan — ingen strikt tidsfrist, men ju förr desto bättre för bevisningen';

  @override
  String get domesticDeadlineRestraining =>
      'Besöksförbud — kan ansökas om när som helst';

  @override
  String get contactEmergency => 'Nödnummer';

  @override
  String get contactShelter => 'Turvakoti (skyddat boende) hjälplinje';

  @override
  String get contactCrisisHelpline => 'Kristelefon (Kriisipuhelin)';

  @override
  String get contactNollaLinja =>
      'Nollalinja — hjälplinje mot våld mot kvinnor';

  @override
  String get inheritance => 'Arv';

  @override
  String get inheritanceDesc =>
      'Testamenten, dödsbo, arvingars rättigheter, laglott, bouppteckning';

  @override
  String get rightInheritanceForced =>
      'Bröstarvingar (barn, make/maka) har rätt till laglott oavsett testamentet';

  @override
  String get rightInheritanceWill =>
      'Du har rätt att upprätta ett testamente för din egendom — bevittnade/notariserade testamenten har starkast rättsverkan';

  @override
  String get rightInheritanceRenounce =>
      'Du kan avstå från ett arv inom 3 månader efter att du fått kännedom om det';

  @override
  String get rightInheritanceInfo =>
      'Du har rätt att få information om dödsboet från banker och register';

  @override
  String get rightInheritanceDispute =>
      'Du kan bestrida ett orättvist testamente i domstol inom den lagstadgade preskriptionstiden';

  @override
  String get mustFileInheritance =>
      'Ansök om bouppteckning hos en notarie inom skälig tid';

  @override
  String get mustNotifyHeirs =>
      'Alla kända arvingar måste underrättas om bouppteckningen';

  @override
  String get inheritanceActionGatherDocs =>
      'Samla alla dokument: dödsattest, testamente, fastighetshandlingar, kontoutdrag';

  @override
  String get inheritanceActionContactNotary =>
      'Kontakta en notarie för att inleda bouppteckningen';

  @override
  String get inheritanceActionCheckDebts =>
      'Kontrollera om dödsboet har skulder innan du accepterar arvet';

  @override
  String get inheritanceActionFileCourt =>
      'Om testamentet bestrids, väck talan i domstol';

  @override
  String get inheritanceDeadlineRenounce =>
      '3 månader för att avstå från arv efter att ha fått kännedom om det';

  @override
  String get inheritanceDeadlineDispute =>
      'Preskriptionstid för att bestrida ett testamente: varierar beroende på grund';

  @override
  String get inheritanceFactForced =>
      'I Estland har bröstarvingar och make/maka rätt till laglott (1/2 av den legala arvslotten) även om de utesluts från testamentet';

  @override
  String get inheritanceFactNotary =>
      'Alla bouppteckningar i Estland måste gå via en notarie — detta steg kan inte hoppas över';

  @override
  String get consumerProtection => 'Konsumentskydd';

  @override
  String get consumerProtectionDesc =>
      'Bedrägeri, defekta produkter, returer, vilseledande säljare';

  @override
  String get rightReturnOnline =>
      'Du har 14 dagar på dig att ångra ett onlineköp utan att ange skäl (EU:s ångerrätt)';

  @override
  String get rightDefectiveProduct =>
      'Om en produkt är defekt har du rätt till reparation, ersättning eller återbetalning';

  @override
  String get rightClearPricing =>
      'Säljare måste visa tydliga priser inklusive alla avgifter — dolda kostnader är olagliga';

  @override
  String get rightComplainBoard =>
      'Du kan lämna in ett kostnadsfritt klagomål till konsumenttvistenämnden';

  @override
  String get rightProtectionFraud =>
      'Du är skyddad mot otillbörliga affärsmetoder och bedrägeri';

  @override
  String get mustKeepReceipts =>
      'Spara alla kvitton, avtal och kommunikation med säljare';

  @override
  String get mustActTimely =>
      'Reklamera fel till säljaren inom skälig tid efter upptäckt';

  @override
  String get consumerActionKeepEvidence =>
      'Spara kvitton, skärmdumpar, e-post och alla köpbevis';

  @override
  String get consumerActionContactSeller =>
      'Kontakta säljaren först — förklara problemet skriftligt';

  @override
  String get consumerActionFileComplaint =>
      'Lämna in ett klagomål till konsumenttvistenämnden (kuluttajariitalautakunta)';

  @override
  String get consumerActionContactAuthority =>
      'Kontakta konsumentrådgivningen för kostnadsfri hjälp';

  @override
  String get consumerActionReportFraud =>
      'Anmäl bedrägeri till polisen och konsumentombudsmannen';

  @override
  String get consumerFactWithdrawal =>
      'Enligt EU:s konsumenträttighetsdirektiv 2011/83/EU har du 14 dagar på dig att frånträda ett köp på distans eller online — utan att ange skäl. Säljaren måste återbetala dig inom 14 dagar.';

  @override
  String get consumerFactWarranty =>
      'I Finland ansvarar säljaren för produktfel under en skälig tid (ofta 2+ år). Detta gäller utöver eventuell tillverkargaranti.';

  @override
  String get consumerDeadlineWithdrawal =>
      'Ångerrätt vid onlineköp — 14 dagar från leverans';

  @override
  String get consumerDeadlineDefect =>
      'Reklamera fel till säljaren — inom 2 månader från upptäckt (rekommenderas)';

  @override
  String get contactConsumerAdvisory => 'Konsumentrådgivningen';

  @override
  String get contactConsumerOmbudsman =>
      'Konsumentombudsmannen (Kuluttaja-asiamies)';

  @override
  String get contactConsumerDisputesBoardDirect => 'Konsumenttvistenämnden';

  @override
  String get caseTypeStepLabel => 'Ärendetyp';

  @override
  String get detailsStepLabel => 'Detaljer';

  @override
  String get documentsStepLabel => 'Dokument';

  @override
  String get whatTypeOfCase => 'Vilken typ av ärende gäller det?';

  @override
  String get selectCategoryDescription =>
      'Välj den kategori som bäst beskriver din situation.';

  @override
  String get tellUsAboutCase => 'Berätta om ditt ärende';

  @override
  String get aiHelpsUnderstand =>
      'Denna information hjälper vår AI att bättre förstå din situation.';

  @override
  String get caseTitleHint => 't.ex. Överklagande av uppehållstillstånd 2026';

  @override
  String get countryJurisdiction => 'Land / jurisdiktion';

  @override
  String get selectCountryHint => 'Välj ett land';

  @override
  String get referenceNumberHint => 't.ex. UMA/12345/2026';

  @override
  String get descriptionOptional => 'Beskrivning (valfritt)';

  @override
  String get descriptionHint =>
      'Beskriv kort din situation. Vad hände? Vilket beslut fattades?';

  @override
  String get uploadFirstDocument => 'Ladda upp ditt första dokument';

  @override
  String get uploadDocumentDescription =>
      'Ladda upp beslutsbrevet eller ett annat relevant dokument. Du kan hoppa över detta steg och lägga till dokument senare.';

  @override
  String get tapToUploadFile => 'Tryck för att ladda upp en fil';

  @override
  String get fileSizeLimit => 'PDF, JPG, PNG upp till 25 MB';

  @override
  String get addDocumentsLaterHint =>
      'Du kan alltid lägga till dokument senare från ärendets detaljvy.';

  @override
  String get callAI => 'Ring AI';

  @override
  String get comingSoon => 'Kommer snart';

  @override
  String get encrypted => 'Krypterat';

  @override
  String get typing => 'Skriver…';

  @override
  String get online => 'Online';

  @override
  String get chatWelcomeSubtitle =>
      'Jag analyserar situationen, granskar dokument, hittar fel och föreslår vad du bör göra.';

  @override
  String get tapMicrophoneToSpeak => 'Tryck på mikrofonen för att tala';

  @override
  String get categoryEssential => 'Grundläggande';

  @override
  String get categoryPolice => 'Polis';

  @override
  String get categoryWork => 'Arbete';

  @override
  String get categoryHousing => 'Boende';

  @override
  String get categoryConsumer => 'Konsument';

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
  String get freeAidThreshold => 'Gräns för kostnadsfri rättshjälp';

  @override
  String get partialAidThreshold => 'Gräns för delvis rättshjälp';

  @override
  String get assetLimit => 'Tillgångsgräns';

  @override
  String get whereToApplyLabel => 'Var du ska ansöka';

  @override
  String get phoneLabel => 'Telefon';

  @override
  String get websiteLabel => 'Webbplats';

  @override
  String get disclaimerCollapsed => 'Endast AI-vägledning';

  @override
  String get disclaimerExpanded =>
      'AI-assistent — inte juridisk rådgivning. Kontrollera alltid med en behörig jurist.';

  @override
  String get chatDisclaimerBanner =>
      'AI-assistenten ger juridisk information, inte juridisk rådgivning. Rådgör alltid med en kvalificerad jurist.';

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
  String get categoryChildren => 'Barn';

  @override
  String get categoryDigital => 'Digitalt';

  @override
  String get childrenRights => 'Barns rättigheter och underhåll';

  @override
  String get childrenRightsDesc =>
      'Underhållsbidrag, skydd, statliga garantier';

  @override
  String get cyberbullying => 'Nätmobbning och nättrakasserier';

  @override
  String get cyberbullyingDesc => 'Hot, integritetskränkningar, förtal online';

  @override
  String get rightChildSupport =>
      'Båda föräldrarna är juridiskt skyldiga att försörja sitt barn ekonomiskt (Perekonnaseadus § 100–102)';

  @override
  String get rightMinimumAlimony =>
      'Minsta underhållsbidrag i Estland: grundbelopp (295,86 €) + 3 % av föregående års genomsnittliga bruttolön (PKS § 101). Från 01.04.2026 — 318,62 €/månad per barn. Uppdateras årligen den 1 april. Kalkylator: alimendid.ee';

  @override
  String get rightCourtAlimony =>
      'Du kan ansöka om underhållsbidrag via distriktsdomstolen (maakohus) — ingen jurist krävs för anspråk upp till 6 400 €';

  @override
  String get rightBailiffEnforcement =>
      'Om föräldern vägrar betala kan en kronofogde (kohtutäitur) verkställa domstolsbeslutet, inklusive löneutmätning';

  @override
  String get rightStateAlimonyGuarantee =>
      'Om föräldern inte betalar tillhandahåller staten elatisabi (underhållsstöd) via Sotsiaalkindlustusamet — upp till 100 €/månad per barn';

  @override
  String get rightChildEducation =>
      'Varje barn har rätt till utbildning, hälsovård och skydd mot övergrepp (Lastekaitseseadus § 4–5)';

  @override
  String get rightChildContact =>
      'Ett barn har rätt att upprätthålla kontakt med båda föräldrarna om inte domstolen beslutar annat (PKS § 143)';

  @override
  String get mustFileCourtClaim =>
      'För att få underhållsbidrag måste du väcka talan i domstol eller komma överens om beloppet skriftligt';

  @override
  String get mustNotifyAddressChange =>
      'Meddela Sotsiaalkindlustusamet om adressändringar om du får elatisabi';

  @override
  String get childrenActionGatherDocs =>
      'Samla barnets födelseattest, din legitimation och kvitton på utgifter';

  @override
  String get childrenActionFileCourtClaim =>
      'Väck talan om underhållsbidrag vid distriktsdomstolen (maakohus) — kan göras online via e-toimik';

  @override
  String get childrenActionApplyElatisabi =>
      'Ansök om statligt underhållsstöd (elatisabi) hos Sotsiaalkindlustusamet om föräldern inte betalar';

  @override
  String get childrenActionContactBailiff =>
      'Kontakta en kronofogde (kohtutäitur) för att verkställa domstolsbeslutet';

  @override
  String get childrenActionCallLasteabi =>
      'Ring Lasteabi 116 111, barnens hjälplinje — kostnadsfritt, dygnet runt';

  @override
  String get childrenDeadlineElatisabi =>
      'Ansök om elatisabi — efter domstolsbeslutet, ingen strikt tidsfrist men processen tar tid';

  @override
  String get childrenDeadlineCourt =>
      'Underhållsbidrag kan krävas retroaktivt upp till 1 år före domstolsansökan';

  @override
  String get childrenFactMinimum =>
      'Från 01.04.2026 är minsta underhållsbidrag 318,62 €/månad per barn. Formel: grundbelopp (295,86 €) + 3 % av föregående års genomsnittliga bruttolön. Uppdateras årligen den 1 april. En förälder kan inte komma överens om att betala mindre. Kalkylator: alimendid.ee';

  @override
  String get childrenFactElatisabi =>
      'Estlands statliga underhållsstöd (elatisabi) infördes 2017 för att skydda barn när en förälder vägrar betala. Staten betalar ut och driver sedan in beloppet från den skyldiga föräldern.';

  @override
  String get rightReportCybercrime =>
      'Du har rätt att anmäla hot, trakasserier och identitetsstöld online till polisen (Karistusseadustik § 120, § 157¹)';

  @override
  String get rightContentRemoval =>
      'Du kan begära att förtalande eller privat innehåll tas bort från plattformar och kräva borttagning enligt GDPR';

  @override
  String get rightMoralDamageCompensation =>
      'Du kan kräva ersättning för ideell skada orsakad av nätmobbning (Võlaõigusseadus § 1043–1055)';

  @override
  String get rightPrivacyProtection =>
      'Ditt privatliv är skyddat — obehörig delning av dina foton, meddelanden eller personuppgifter är olagligt (KarS § 157)';

  @override
  String get rightDataProtection =>
      'Anmäl dataskyddsöverträdelser (obehörig användning av dina uppgifter) till Andmekaitse Inspektsioon';

  @override
  String get rightDefamationAction =>
      'Förtal (laimamine) är ett civilrättsligt brott — du kan stämma för skadestånd och kräva ett offentligt dementi (KarS § 247 (upphävd), VÕS § 1047)';

  @override
  String get mustCollectEvidence =>
      'Samla in och bevara all bevisning — skärmdumpar, länkar, datum och vittnesuppgifter';

  @override
  String get mustNotRetaliate =>
      'Hämnas inte och ägna dig inte åt mottrakasserier — det kan försvaga ditt ärende';

  @override
  String get cyberActionScreenshots =>
      'Ta skärmdumpar av alla trakasserier — spara webbadresser, datum, användarnamn och innehåll';

  @override
  String get cyberActionReportPolice =>
      'Gör en polisanmälan på närmaste station eller online på politsei.ee';

  @override
  String get cyberActionReportPlatform =>
      'Anmäl innehållet till plattformen för borttagning';

  @override
  String get cyberActionContactDPA =>
      'Kontakta Andmekaitse Inspektsioon om dina personuppgifter har missbrukats';

  @override
  String get cyberActionConsultLawyer =>
      'Rådfråga en jurist om civilrättsligt skadestånd — kostnadsfri rättshjälp finns via Riigi Õigusabi';

  @override
  String get cyberDeadlineCriminal =>
      'Brottsanmälan — ingen strikt tidsfrist, men anmäl snabbt för bästa resultat';

  @override
  String get cyberDeadlineCivil =>
      'Civilrättsligt skadeståndsanspråk — upp till 3 år från det att du fick kännedom om kränkningen (TsÜS § 150)';

  @override
  String get cyberFactPrivacy =>
      'I Estland kan obehörig delning av någons intima bilder leda till upp till 3 års fängelse enligt Karistusseadustik § 157¹ (kränkning av privatlivet).';

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
  String freeQuotaExhausted(int count) {
    return 'Du har använt alla $count gratismeddelanden den här månaden.';
  }

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
  String get deadlineRadarTitle => 'Kommande tidsfrister';

  @override
  String get deadlineRadarEmpty => 'Inga kommande tidsfrister';

  @override
  String get deadlineRadarViewAll => 'Visa alla';

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
  String get deadlineCardTomorrow => 'imorgon';

  @override
  String get deadlineCardToday => 'idag';

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
  String get deadlineCardMarkComplete => 'Markera som klar';

  @override
  String get deadlineCardSnooze => 'Skjut upp';

  @override
  String get deadlineCardSnooze3d => 'Skjut upp 3 dagar';

  @override
  String get deadlineCardSnooze7d => 'Skjut upp 7 dagar';

  @override
  String get deadlineCardSnoozeCustom => 'Välj ett datum';

  @override
  String get deadlineCardEdit => 'Redigera';

  @override
  String get deadlineCardDelete => 'Arkivera';

  @override
  String get deadlineCardSourceLabelPdf => 'från PDF';

  @override
  String get deadlineCardSourceLabelIntake => 'från registrering';

  @override
  String get deadlineCardSourceLabelManual => 'tillagd manuellt';

  @override
  String get deadlineCardSourceLabelEmail => 'från e-post';

  @override
  String get deadlineCardSourceLabelHaikuExtract => 'AI-extraherad';

  @override
  String get deadlineCardSourceLabelStatutoryTemplate => 'lagmall';

  @override
  String deadlineBannerCritical(String title, String when) {
    return 'Kritisk tidsfrist $title $when';
  }

  @override
  String get deadlineBannerDismiss => 'Avfärda';

  @override
  String get deadlineBannerOpen => 'Öppna tidsfrist';

  @override
  String deadlineHolidayShifted(String original, String reason) {
    return 'Flyttad från $original på grund av $reason';
  }

  @override
  String get deadlinePermissionAskTitle =>
      'Aktivera påminnelser om tidsfrister?';

  @override
  String get deadlinePermissionAskBody =>
      'Vi påminner dig 7, 3 och 1 dag före varje lagstadgad tidsfrist, samt på morgonen samma dag. Används aldrig för marknadsföring.';

  @override
  String get deadlinePermissionAllow => 'Tillåt';

  @override
  String get deadlinePermissionLater => 'Senare';

  @override
  String get deadlineSettingsSection => 'Påminnelser om tidsfrister';

  @override
  String get deadlineSettingsPushChannel => 'Push-notiser';

  @override
  String get deadlineSettingsEmailChannel => 'E-post (endast kritiska)';

  @override
  String get deadlineSettingsInAppChannel => 'Banderoller i appen';

  @override
  String get deadlineSettingsCriticalBypass =>
      'Kritiska påminnelser kringgår tystnadstimmar';

  @override
  String get deadlineSettingsQuietHours => 'Tystnadstimmar';

  @override
  String deadlineSettingsQuietHoursBadge(String start, String end) {
    return 'Tyst $start–$end';
  }

  @override
  String get deadlineCaseScreenTitle => 'Ärendets tidsfrister';

  @override
  String get deadlineAddManualCta => 'Lägg till tidsfrist';

  @override
  String get deadlineFormTitle => 'Titel';

  @override
  String get deadlineFormDescription => 'Beskrivning (valfritt)';

  @override
  String get deadlineFormStatuteTemplate => 'Lagmall';

  @override
  String get deadlineFormStatuteTemplateNone => 'Ingen (manuell)';

  @override
  String get deadlineFormDeadlineAt => 'Tidsfristens datum';

  @override
  String get deadlineFormPriority => 'Prioritet';

  @override
  String get deadlineFormSave => 'Spara';

  @override
  String get deadlineFormCancel => 'Avbryt';

  @override
  String get deadlineCompletedNotePrompt =>
      'Lägg till en anteckning (valfritt)';

  @override
  String get deadlineCompletedNoteSave => 'Spara';

  @override
  String get inboxTitle => 'Inkorg';

  @override
  String get inboxEmptyTitle => 'Inget väntar';

  @override
  String get inboxEmptyBody =>
      'Nya e-posttrådar visas här allt eftersom de sorteras.';

  @override
  String get inboxApproveSend => 'Godkänn och skicka';

  @override
  String get inboxEditDraft => 'Redigera';

  @override
  String get inboxSnooze => 'Skjut upp';

  @override
  String get inboxArchive => 'Arkivera';

  @override
  String get inboxFilterAll => 'Alla';

  @override
  String get inboxConfirmSendTitle => 'Skicka det förberedda svaret?';

  @override
  String get inboxConfirmSendBody =>
      'Advocat skickar det AI-förberedda svaret via din anslutna Gmail. Du kan fortfarande granska innehållet på nästa skärm.';

  @override
  String get inboxSendButton => 'Skicka';

  @override
  String get inboxSentToast => 'Skickat.';

  @override
  String get inboxAlreadySentToast => 'Redan skickat.';

  @override
  String get inboxSendErrorToast =>
      'Kunde inte skicka svaret. Tryck för att försöka igen.';

  @override
  String get inboxSnoozedToast => 'Uppskjutet i 24 timmar.';

  @override
  String get inboxArchivedToast => 'Arkiverat.';

  @override
  String get inboxDraftLoadError => 'Kunde inte läsa in utkastet.';

  @override
  String get inboxDeadlineToday => 'idag';

  @override
  String get inboxDeadlineTomorrow => 'imorgon';

  @override
  String inboxDeadlineInDays(int days) {
    return 'om $days dagar';
  }

  @override
  String inboxDeadlineOverdue(int days) {
    return '$days dagar försenad';
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
  String get workspaceTabOverview => 'Översikt';

  @override
  String get workspaceTabChat => 'Chatt';

  @override
  String get workspaceTabDrafts => 'Utkast';

  @override
  String get workspaceOverviewEmpty =>
      'Lägg till dokument för att bygga en sammanfattning.';

  @override
  String get workspaceTimelineEmpty => 'Inga händelser än.';

  @override
  String get workspaceDocumentsEmpty => 'Inga dokument. Ladda upp via Skanna.';

  @override
  String get workspaceDraftsEmpty => 'Inga utkast än.';

  @override
  String get workspaceInboxEmpty => 'Ingen relaterad e-post.';

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
      '1 avtalsgranskning (engångsprov, gratis)';

  @override
  String get contractReviewsCounselFeature => '5 avtalsgranskningar per månad';

  @override
  String get contractReviewsProFeature => '20 avtalsgranskningar per månad';

  @override
  String contractReviewsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count avtalsgranskningar kvar denna månad',
      one: '1 avtalsgranskning kvar denna månad',
      zero: 'Inga avtalsgranskningar kvar denna månad',
    );
    return '$_temp0';
  }

  @override
  String get contractReviewsExhausted =>
      'Inga avtalsgranskningar kvar denna månad';

  @override
  String get contractReviewsFreeTrialLeft => 'Gratis prov: 1 avtalsgranskning';

  @override
  String get contractReviewsFreeTrialUsed => 'Gratis prov använt — uppgradera';

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
  String get draftsTab => 'Utkast';

  @override
  String get draftingTitle => 'Skrivstudio';

  @override
  String get draftingEmpty => 'Tomt utkast';

  @override
  String get draftingPlaceholder => 'Börja skriva ditt utkast…';

  @override
  String get draftingDraftsList => 'Mina utkast';

  @override
  String get draftingSave => 'Spara';

  @override
  String get draftingSaved => 'Sparat';

  @override
  String get draftingSavedJustNow => 'Sparat nyss';

  @override
  String get draftingAiRevise => 'Bearbeta med AI';

  @override
  String get draftingExportPdf => 'Exportera PDF';

  @override
  String get draftingExportDocx => 'Exportera DOCX';

  @override
  String get draftingExportMd => 'Exportera Markdown';

  @override
  String get draftingDeleteDraft => 'Ta bort utkast';

  @override
  String get draftingConfirmDelete => 'Ta bort detta utkast?';

  @override
  String get draftingConfirmDeleteMessage => 'Denna åtgärd kan inte ångras.';

  @override
  String get draftingConfirm => 'Ta bort';

  @override
  String get draftingCancel => 'Avbryt';

  @override
  String draftingDraftReplyTo(String name) {
    return 'Svara till $name';
  }

  @override
  String get draftingUntitled => 'Namnlös';

  @override
  String get draftingTitleHint => 'Titel (valfritt)';

  @override
  String get draftingAiReviseTitle => 'Bearbeta med AI';

  @override
  String get draftingAiReviseSelectionLabel => 'Markerad text:';

  @override
  String get draftingAiReviseInstructionLabel => 'Instruktion (valfritt)';

  @override
  String get draftingAiReviseInstructionHint =>
      't.ex. \"gör den mer formell\" eller \"korta ner\"';

  @override
  String get draftingAiReviseRunButton => 'Generera bearbetning';

  @override
  String get draftingAiReviseSuggestionLabel => 'Föreslagen bearbetning:';

  @override
  String get draftingAiReviseChangesLabel => 'Ändringar:';

  @override
  String get draftingAiReviseAccept => 'Acceptera';

  @override
  String get draftingAiReviseReject => 'Avvisa';

  @override
  String get draftingFormatBold => 'Fet';

  @override
  String get draftingFormatItalic => 'Kursiv';

  @override
  String get draftingFormatHeading => 'Rubrik';

  @override
  String get draftingFormatBullet => 'Punktlista';

  @override
  String get draftingFormatNumbered => 'Numrerad lista';

  @override
  String get draftingEmptyListMessage => 'Du har inga utkast än.';

  @override
  String get draftingEmptyListAction => 'Nytt utkast';

  @override
  String get draftingExporting => 'Exporterar…';

  @override
  String get draftingExportFailed => 'Export misslyckades';

  @override
  String get draftingSaveFailed => 'Det gick inte att spara';

  @override
  String get draftingNewDraft => 'Nytt utkast';

  @override
  String get vaultNoteChip => 'Anteckning i valvet';

  @override
  String get saveToVault => 'Spara i valvet';

  @override
  String get savingToVault => 'Sparar i valvet…';

  @override
  String get savedToVault => 'Sparat i valvet';

  @override
  String get vaultNoteTitlePrefix => 'Anteckning: ';

  @override
  String get openInVault => 'Öppna i valvet';

  @override
  String get saveToVaultFailed => 'Det gick inte att spara i valvet';

  @override
  String get pdfWorkerUnavailable =>
      'PDF-export är tillfälligt otillgänglig. Prova DOCX eller Markdown istället.';

  @override
  String get draftingVersionHistory => 'Versionshistorik';

  @override
  String get emptyHomeTitle => 'Välkommen till Advocat';

  @override
  String get emptyHomeBody =>
      'Välj en utgångspunkt — vi sköter den juridiska tungrodda delen.';

  @override
  String get intentChip1 => 'Fick böter';

  @override
  String get intentChip2 => 'Ansökan avslagen';

  @override
  String get intentChip3 => 'Avtalsproblem';

  @override
  String get emptyCasesTitle => 'Inga ärenden än';

  @override
  String get emptyCasesCta => 'Starta ett ärende';

  @override
  String get emptyDraftsTitle => 'Inga utkast än';

  @override
  String get emptyDraftsCta => 'Skapa utkast';

  @override
  String get emptyChatTitle => 'Fråga Advocat vad som helst';

  @override
  String get chatExamplePrompt1 => 'Hjälp mig svara på böter';

  @override
  String get chatExamplePrompt2 => 'Granska mitt hyresavtal';

  @override
  String get chatExamplePrompt3 => 'Vilka rättigheter har jag på jobbet?';

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
  String get contractReviewTitle => 'Avtalsgranskning';

  @override
  String get contractReviewUploadCta => 'Ladda upp avtal';

  @override
  String get contractReviewQuotaRemaining =>
      'Ladda upp ett avtal i PDF, DOC, DOCX eller TXT för en AI-granskning med varningsflaggor och förhandlingstips.';

  @override
  String get contractReviewRedFlags => 'Varningsflaggor';

  @override
  String get contractReviewReviewPoints => 'Granskningspunkter';

  @override
  String get contractReviewNegotiationTips => 'Förhandlingstips';

  @override
  String get contractReviewSaveToVault => 'Spara i valvet';

  @override
  String get contractReviewContinueChat => 'Fortsätt i chatten';

  @override
  String get referralInviteFriends => 'Bjud in vänner';

  @override
  String get referralYourCode => 'Din kod';

  @override
  String get referralCopiedToast => 'Koden kopierad till urklipp';

  @override
  String get referralReward =>
      'Få 1 månad av Counsel gratis för varje vän som prenumererar.';

  @override
  String get referralInvited => 'Inbjudna vänner';

  @override
  String get referralRewardsEarned => 'Intjänade gratismånader';

  @override
  String get deadlineUrgencyToday => 'Idag och försenade';

  @override
  String get deadlineUrgencyWeek => 'Denna vecka';

  @override
  String get deadlineUrgencyMonth => 'Denna månad';

  @override
  String get deadlineUrgencyLater => 'Senare';

  @override
  String get deadlineAddManual => 'Lägg till tidsfrist';

  @override
  String get deadlineSnoozeBy => 'Skjut upp';

  @override
  String get deadlineSnooze1d => 'Skjut upp 1 dag';

  @override
  String get deadlineSnooze3d => 'Skjut upp 3 dagar';

  @override
  String get deadlineSnooze7d => 'Skjut upp 7 dagar';

  @override
  String get deadlineDismiss => 'Avfärda';

  @override
  String get deadlineExportIcs => 'Lägg till i kalender';

  @override
  String get deadlineSource => 'Källa';

  @override
  String get deadlineEmpty =>
      'Inga tidsfrister än. Tidsfrister skapas automatiskt från dina e-postmeddelanden och dokument — eller lägg till en manuellt med +-knappen.';

  @override
  String get deadlineNewTitle => 'Ny tidsfrist';

  @override
  String get deadlineFieldTitle => 'Titel';

  @override
  String get deadlineFieldDueDate => 'Förfallodatum';

  @override
  String get deadlineFieldNotes => 'Anteckningar (valfritt)';

  @override
  String get deadlineSaved => 'Tidsfrist sparad';

  @override
  String get deadlineSaveFailed => 'Det gick inte att spara tidsfristen';

  @override
  String get deadlineUrgentBannerSingle => '1 tidsfrist idag eller försenad';

  @override
  String deadlineUrgentBannerMany(int count) {
    return '$count tidsfrister idag eller försenade';
  }

  @override
  String deadlineDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dagar kvar',
      one: '1 dag kvar',
      zero: 'idag',
    );
    return '$_temp0';
  }

  @override
  String deadlineDaysOverdue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dagar försenad',
      one: '1 dag försenad',
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
  String get deadlineEuRadarTitle => 'EU:s tidsfristradar (förhandsvisning)';

  @override
  String get deadlineEuRadarSubtitle =>
      'Hypotetiska EU-processuella tidsfrister — testdata';

  @override
  String get changePassword => 'Byt lösenord';

  @override
  String get changePasswordSubtitle => 'Uppdatera ditt kontolösenord';

  @override
  String get newPasswordTitle => 'Ange ett nytt lösenord';

  @override
  String get newPasswordHint =>
      'Ange och bekräfta ett nytt lösenord för ditt konto.';

  @override
  String get newPasswordSave => 'Spara nytt lösenord';

  @override
  String get newPasswordSuccess =>
      'Lösenordet har uppdaterats. Du kan nu logga in med det.';

  @override
  String get newPasswordError =>
      'Det gick inte att uppdatera lösenordet. Försök igen.';

  @override
  String get accessLogTile => 'Åtkomstlogg';

  @override
  String get accessLogTileSubtitle =>
      'Se vem och vad som har använt dina uppgifter';

  @override
  String get accessLogTitle => 'Åtkomstlogg för mina uppgifter';

  @override
  String get accessLogIntro =>
      'En transparent och manipuleringssäker logg över varje gång dina uppgifter har använts eller behandlats – även av vår AI. Du kan verifiera att den inte har ändrats.';

  @override
  String get accessLogEmpty => 'Inga åtkomsthändelser ännu.';

  @override
  String get accessLogError =>
      'Det gick inte att läsa in din åtkomstlogg. Dra nedåt för att försöka igen.';

  @override
  String get accessLogIntegrityOk =>
      'Integritet verifierad – loggens länkar bildar en obruten kedja.';

  @override
  String get accessLogIntegrityBroken =>
      'Varning: loggkedjan är bruten. Vissa poster kan ha tagits bort eller ändrats i ordning. Kontakta supporten.';

  @override
  String get accessActionLlmEgress =>
      'Skickat till AI för behandling (pseudonymiserat)';

  @override
  String get accessActionAiAnalysis => 'Analyserat av AI';

  @override
  String get accessActionDocumentParse => 'Dokument tolkat';

  @override
  String get accessActionStaffRead => 'Granskat av en medarbetare';

  @override
  String get accessActionExport => 'Uppgifter exporterade';

  @override
  String get accessActionEmailTriage => 'E-post sorterad';

  @override
  String get accessActionDeadlineScan => 'Tidsfrister genomsökta';

  @override
  String get breachAlertTitle => 'Säkerhetsvarning om dina uppgifter';

  @override
  String get breachAlertBody =>
      'Vår automatiska övervakning upptäckte ovanlig åtkomst som rör dina uppgifter. Vi granskar händelsen och meddelar dig om någon bekräftad incident enligt lag (artikel 34 i GDPR).';

  @override
  String get caseDossierTitle => 'Exportera ärendedossier';

  @override
  String get caseDossierSubtitle =>
      'En PDF med allt – fakta, kronologi, tidsfrister och dokument – att lämna till en advokat, en domstol eller ett klagomålsorgan.';

  @override
  String get caseDossierTileTitle => 'Exportera dossier (PDF)';

  @override
  String get caseDossierTileSubtitle =>
      'Lämna hela ärendet till en advokat eller domstol i en enda fil';

  @override
  String get caseDossierSectionsHeading => 'Inkludera i dossiern';

  @override
  String get caseDossierSectionFacts => 'Ärendefakta';

  @override
  String get caseDossierSectionFactsHint => 'Alltid med';

  @override
  String get caseDossierSectionTimeline => 'Kronologi';

  @override
  String get caseDossierSectionDeadlines => 'Tidsfrister';

  @override
  String get caseDossierSectionDocuments => 'Dokument';

  @override
  String get caseDossierSectionAiSummary => 'AI-sammanfattning';

  @override
  String get caseDossierExportButton => 'Exportera PDF';

  @override
  String get caseDossierExporting => 'Skapar din dossier …';

  @override
  String get caseDossierSuccess => 'Dossiern är klar. Öppna eller dela filen.';

  @override
  String get caseDossierOpen => 'Öppna dossier';

  @override
  String get caseDossierError =>
      'Det gick inte att skapa dossiern. Försök igen.';

  @override
  String get caseDossierErrorNotOwned => 'Detta ärende kunde inte hittas.';

  @override
  String get caseDossierDisclaimer =>
      'Dossiern återger dina ärendeuppgifter så som de registrerats. Granska den innan du delar den.';

  @override
  String get followupsTitle => 'Nästa steg';

  @override
  String get followupsSubtitle =>
      'Praktiska uppgifter för att föra ditt ärende framåt';

  @override
  String get followupsEmpty => 'Inga uppföljningssteg ännu.';

  @override
  String get followupsEmptyDesc =>
      'Lägg till ett steg, eller låt AI:n föreslå vad du bör göra härnäst.';

  @override
  String get followupsAdd => 'Lägg till steg';

  @override
  String get followupsSuggest => 'Föreslå steg';

  @override
  String get followupsSuggestNone =>
      'Inga förslag just nu. Försök igen efter att ha chattat om ärendet.';

  @override
  String get followupsSuggestTitle => 'Föreslagna nästa steg';

  @override
  String get followupsAddPrompt => 'Lägg till de steg du vill behålla:';

  @override
  String get followupsNewTitleHint => 'Vad behöver göras?';

  @override
  String get followupsNewDetailHint =>
      'Valfri anteckning (varför / vad som ska bifogas)';

  @override
  String get followupsDueOptional => 'Påminn mig den (valfritt)';

  @override
  String get followupsOverdue => 'Försenat';

  @override
  String followupsDueOn(String date) {
    return 'Förfaller $date';
  }

  @override
  String get followupsDone => 'Klart';

  @override
  String get followupsSnooze => 'Skjut upp';

  @override
  String get followupsSnooze1Week => 'Påminn om en vecka';

  @override
  String get followupsDismiss => 'Avfärda';

  @override
  String get followupsLoadError => 'Det gick inte att läsa in nästa steg';

  @override
  String get followupsAiBadge => 'AI';

  @override
  String get contractCompareTitle => 'Jämför versioner';

  @override
  String get contractCompareIntro =>
      'Ladda upp två versioner av samma avtal. Vi markerar vad som har ändrats och om varje ändring gynnar eller missgynnar dig.';

  @override
  String get contractCompareOldVersion => 'Gammal version (v1)';

  @override
  String get contractCompareNewVersion => 'Ny version (v2)';

  @override
  String get contractCompareCta => 'Jämför versioner';

  @override
  String get contractCompareAdverse => 'Ofördelaktig';

  @override
  String get contractCompareFavorable => 'Fördelaktig';

  @override
  String get contractCompareNeutral => 'Neutral';

  @override
  String get contractCompareBefore => 'Före';

  @override
  String get contractCompareAfter => 'Efter';

  @override
  String get contractCompareTruncated =>
      'Långt avtal – endast den första delen av varje version har jämförts.';

  @override
  String get contractCompareNoChanges =>
      'Inga väsentliga ändringar upptäcktes mellan de två versionerna.';

  @override
  String get docSearchTitle => 'Sök i mina dokument';

  @override
  String get docSearchHint => 't.ex. var nämndes depositionen';

  @override
  String get docSearchSubtitle =>
      'Semantisk sökning i ditt valv och dina ärendehandlingar';

  @override
  String get docSearchIdle =>
      'Sök i innehållet i dina egna dokument – inte bara i titlarna.';

  @override
  String get docSearchNoResults => 'Inga träffar i dina dokument.';

  @override
  String get docSearchError => 'Sökningen misslyckades. Försök igen.';

  @override
  String get docSearchUntitled => 'Namnlöst dokument';

  @override
  String get docSearchKindCase => 'Ärendehandling';

  @override
  String get docSearchKindVault => 'Valvdokument';

  @override
  String get docSearchMenuTitle => 'Sök i mina dokument';

  @override
  String get docSearchMenuSubtitle =>
      'Hitta vad som helst i dina egna filer efter innebörd';

  @override
  String get legalTemplatesTitle => 'Mallbibliotek';

  @override
  String get legalTemplatesMenuLabel => 'Mallar';

  @override
  String get legalTemplatesSubtitle =>
      'Välj ett färdigt formulär, fyll i några uppgifter, så skapar vi ett utkast som du kan redigera och exportera.';

  @override
  String get legalTemplatesDisclaimer =>
      'Detta är allmänna exempelformulär, inte individuell juridisk rådgivning. Granska och anpassa innan du skickar.';

  @override
  String get legalTemplatesSampleBadge => 'Exempel';

  @override
  String get legalTemplatesEmpty => 'Inga mallar för detta filter ännu.';

  @override
  String get legalTemplatesError =>
      'Det gick inte att läsa in mallarna. Försök igen.';

  @override
  String get legalTemplatesFilterAll => 'Alla';

  @override
  String get legalTemplatesJurisdictionFi => 'Finland';

  @override
  String get legalTemplatesJurisdictionEe => 'Estland';

  @override
  String get legalTemplatesCategoryComplaint => 'Klagomål';

  @override
  String get legalTemplatesCategoryAppeal => 'Överklaganden';

  @override
  String get legalTemplatesCategoryApplication => 'Ansökningar';

  @override
  String get legalTemplatesCategoryClaim => 'Krav';

  @override
  String get legalTemplatesCategoryRequest => 'Begäranden';

  @override
  String get legalTemplatesFillTitle => 'Fyll i uppgifterna';

  @override
  String get legalTemplatesFillIntro =>
      'Vi fyller automatiskt i ditt namn och dina ärendeuppgifter. Fyll i fälten nedan.';

  @override
  String get legalTemplatesFieldRequired => 'Detta fält är obligatoriskt';

  @override
  String get legalTemplatesCreateDraft => 'Skapa utkast';

  @override
  String get legalTemplatesCreating => 'Skapar utkast …';

  @override
  String get legalTemplatesCreateFailed =>
      'Det gick inte att skapa utkastet. Försök igen.';

  @override
  String get legalTemplatesUnresolvedWarning =>
      'Vissa fält är fortfarande tomma och markeras med ____ i utkastet. Du kan fylla i dem i redigeraren.';

  @override
  String get legalTemplatesFieldRecipient =>
      'Mottagare (myndighet / hyresvärd)';

  @override
  String get legalTemplatesFieldAddress => 'Din postadress';

  @override
  String get legalTemplatesFieldSubject => 'Ämne';

  @override
  String get legalTemplatesFieldDescription => 'Beskrivning av ärendet';

  @override
  String get legalTemplatesFieldDemand => 'Vad du begär';

  @override
  String get checklistActionPlan => 'Handlingsplan';

  @override
  String get checklistActionPlanSubtitle => 'Steg för den här typen av ärende';

  @override
  String checklistProgress(int completed, int total) {
    return '$completed av $total steg klara';
  }

  @override
  String get checklistAllDone => 'Alla steg slutförda';

  @override
  String get checklistEmpty =>
      'Ingen handlingsplan finns ännu för den här ärendetypen.';

  @override
  String checklistDeadlineDays(int days) {
    return '$days dagar';
  }

  @override
  String get checklistDisclaimer =>
      'Detta är allmän information, inte juridisk rådgivning. Tidsfristerna är lagstadgade standardvärden – bekräfta det exakta datumet för ditt ärende.';

  @override
  String get checklistViewPlan => 'Visa plan';

  @override
  String get explainPlainTitle => 'Förklara med enkla ord';

  @override
  String get explainPlainIntro =>
      'Klistra in ett officiellt brev, beslut eller avtal, så förklarar vi vad det betyder och vad det kräver av dig – på ett enkelt språk.';

  @override
  String get explainPlainLevelFriend => 'Som till en vän';

  @override
  String get explainPlainLevelTerms => 'Behåll juridiska termer';

  @override
  String get explainPlainInputHint => 'Klistra in den juridiska texten här …';

  @override
  String get explainPlainSubmit => 'Förklara';

  @override
  String get explainPlainWorking => 'Förklarar …';

  @override
  String get explainPlainTldr => 'Sammanfattningsvis';

  @override
  String get explainPlainBreakdown => 'Vad det säger, del för del';

  @override
  String get explainPlainGlossary => 'Svåra termer förklarade';

  @override
  String get explainPlainNextSteps => 'Vad du kan göra härnäst';

  @override
  String get explainPlainOpenInCorpus => 'Slå upp i lagbiblioteket';

  @override
  String get explainPlainEmptyResult =>
      'Ingen förklaring kunde tas fram för denna text. Försök klistra in ett längre eller tydligare utdrag.';

  @override
  String get explainPlainQuotaTitle =>
      'Du har använt dina kostnadsfria förklaringar denna månad';

  @override
  String get explainPlainQuotaBody =>
      'Kostnadsfria konton får 3 förklaringar per månad. Uppgradera till Pro för obegränsade förklaringar.';

  @override
  String get explainPlainUpgradeCta => 'Uppgradera till Pro';

  @override
  String get explainPlainError =>
      'Något gick fel när texten skulle förklaras. Försök igen.';

  @override
  String get explainPlainRetry => 'Försök igen';

  @override
  String get demandLetterTitle => 'Kravbrev';

  @override
  String get demandLetterSubtitle =>
      'Skapa ett formellt kravbrev före rättegång (maksuvaatimus / nõudekiri).';

  @override
  String get demandLetterStepType => 'Typ av krav';

  @override
  String get demandLetterStepParties => 'Parter';

  @override
  String get demandLetterStepClaim => 'Belopp och grund';

  @override
  String get demandLetterStepDeadline => 'Tidsfrist';

  @override
  String get demandLetterStepReview => 'Granska och generera';

  @override
  String get demandLetterClaimDepositReturn =>
      'Återbetalning av hyresdeposition';

  @override
  String get demandLetterClaimUnpaidWage => 'Obetald lön';

  @override
  String get demandLetterClaimFineDispute => 'Bestrida böter / avgift';

  @override
  String get demandLetterClaimGeneric => 'Annat penningkrav';

  @override
  String get demandLetterJurisdiction => 'Jurisdiktion';

  @override
  String get demandLetterLanguage => 'Brevspråk';

  @override
  String get demandLetterRecipientName => 'Mottagarens namn';

  @override
  String get demandLetterRecipientAddress => 'Mottagarens adress (valfritt)';

  @override
  String get demandLetterSenderName => 'Ditt namn';

  @override
  String get demandLetterSenderAddress => 'Din adress / e-post (valfritt)';

  @override
  String get demandLetterAmount => 'Belopp';

  @override
  String get demandLetterCurrency => 'Valuta';

  @override
  String get demandLetterBasis => 'Vad som hände (grunden för kravet)';

  @override
  String get demandLetterBasisHint =>
      'Beskriv fakta: datum, belopp, vad som avtalades och vad som gick fel.';

  @override
  String get demandLetterDeadline => 'Betalningsfrist';

  @override
  String get demandLetterDeadlineHint => 't.ex. 14 dagar från i dag';

  @override
  String get demandLetterReference => 'Referens (valfritt)';

  @override
  String get demandLetterGenerate => 'Generera brev';

  @override
  String get demandLetterGenerating => 'Genererar …';

  @override
  String get demandLetterGenerateFailed =>
      'Det gick inte att generera brevet. Försök igen.';

  @override
  String get demandLetterFieldRequired => 'Detta fält är obligatoriskt';

  @override
  String get demandLetterNext => 'Nästa';

  @override
  String get demandLetterBack => 'Tillbaka';

  @override
  String get demandLetterPreviewTitle => 'Ditt brev';

  @override
  String get demandLetterCopy => 'Kopiera text';

  @override
  String get demandLetterCopied => 'Brevet kopierat till urklipp';

  @override
  String get demandLetterExportPdf => 'Exportera PDF';

  @override
  String get demandLetterExporting => 'Exporterar …';

  @override
  String get demandLetterExportFailed =>
      'Det gick inte att exportera dokumentet. Försök igen.';

  @override
  String get demandLetterSendEmail => 'Skicka via e-post';

  @override
  String get demandLetterNormsTitle => 'Rättsliga hänvisningar';

  @override
  String get demandLetterDisclaimer =>
      'Detta brev upprättas för din räkning som en allmän mall. Det är inte juridisk rådgivning eller en handling utförd av en behörig advokat. Granska det innan du skickar – inget brev skickas automatiskt.';

  @override
  String get demandLetterMenuTile => 'Kravbrev';

  @override
  String get calcHubTitle => 'Juridiska kalkylatorer';

  @override
  String get calcHubSubtitle => 'Snabba uppskattningar inför ditt nästa steg';

  @override
  String get calcHubJurisdiction => 'Jurisdiktion';

  @override
  String calcRatesAsOf(String date) {
    return 'Satser per $date';
  }

  @override
  String get calcRatesOffline => 'Visar cachelagrade satser (offline)';

  @override
  String get calcIndicativeBanner =>
      'Endast vägledande uppskattning – inte en officiell beräkning eller juridisk rådgivning.';

  @override
  String get calcCalculate => 'Beräkna';

  @override
  String get calcResult => 'Resultat';

  @override
  String get calcFormula => 'Så här beräknas det';

  @override
  String get calcSource => 'Källa';

  @override
  String get calcSeveranceTitle => 'Avgångsvederlag / uppsägningstid';

  @override
  String get calcSeveranceDesc =>
      'Uppskatta avgångsvederlag och uppsägningstid vid uppsägning på grund av arbetsbrist';

  @override
  String get calcSeveranceSalary => 'Bruttomånadslön';

  @override
  String get calcSeveranceTenure => 'Anställningsår';

  @override
  String get calcSeveranceTotal => 'Uppskattat avgångsvederlag';

  @override
  String get calcSeveranceNotice => 'Uppsägningstid';

  @override
  String get calcSeveranceGenerateDemand => 'Upprätta ett kravbrev';

  @override
  String get calcLimitationTitle => 'Preskription och överklagandefrister';

  @override
  String get calcLimitationDesc =>
      'Kontrollera om en preskriptions- eller överklagandefrist har löpt ut';

  @override
  String get calcLimitationType => 'Typ av frist';

  @override
  String get calcLimitationStart => 'Startdatum (händelse / beslut)';

  @override
  String get calcLimitationPickDate => 'Välj datum';

  @override
  String get calcLimitationDeadline => 'Tidsfrist';

  @override
  String get calcLimitationExpired => 'Fristen har löpt ut';

  @override
  String calcLimitationDaysLeft(int days) {
    return '$days dagar kvar';
  }

  @override
  String get calcLimitationShifted =>
      'Flyttad till nästa arbetsdag (helg/helgdag).';

  @override
  String get calcLimitationAddDeadline => 'Lägg till bland tidsfrister';

  @override
  String get calcStateFeeTitle => 'Domstols- / statliga avgifter';

  @override
  String get calcStateFeeDesc =>
      'Referensavgifter för ansökan per domstol och instans';

  @override
  String get calcChildSupportTitle => 'Underhållsbidrag (orientering)';

  @override
  String get calcChildSupportDesc =>
      'Ungefärlig orienteringssiffra – det verkliga beloppet fastställs från fall till fall';

  @override
  String get calcChildSupportNet => 'Betalarens nettomånadsinkomst';

  @override
  String get calcChildSupportChildren => 'Antal barn';

  @override
  String get calcChildSupportPerChild => 'Per barn';

  @override
  String get calcChildSupportTotal => 'Totalt per månad';

  @override
  String get calcChildSupportWarning =>
      'Mycket varierande. Domstolar beslutar utifrån barnets behov och båda föräldrarnas betalningsförmåga. Använd endast som utgångspunkt.';

  @override
  String get docCollectTitle => 'Dokument att samla in';

  @override
  String get docCollectSubtitle =>
      'Samla in dessa innan du ansöker eller går till domstol';

  @override
  String get docCollectPickPrompt => 'Vad är din situation?';

  @override
  String get docCollectProblemResidence => 'Uppehållstillstånd';

  @override
  String get docCollectProblemTenant => 'Hyra / avhysning';

  @override
  String get docCollectProblemDismissal => 'Uppsägning från arbetet';

  @override
  String get docCollectProblemInheritance => 'Arv';

  @override
  String get docCollectProblemDivorce => 'Skilsmässa';

  @override
  String docCollectProgress(int collected, int total) {
    return '$collected av $total insamlade';
  }

  @override
  String get docCollectAllDone => 'Allt insamlat';

  @override
  String get docCollectEmpty =>
      'Ingen dokumentlista finns ännu för den här situationen.';

  @override
  String get docCollectOptional => 'Valfritt';

  @override
  String get docCollectWhereLabel => 'Var du får tag på det';

  @override
  String get docCollectWhyLabel => 'Varför det behövs';

  @override
  String get docCollectAttach => 'Bifoga en fil';

  @override
  String get docCollectAttached => 'Fil bifogad';

  @override
  String get docCollectChangeFile => 'Byt fil';

  @override
  String get docCollectRemoveFile => 'Ta bort fil';

  @override
  String get docCollectNoFiles => 'Du har inte laddat upp några dokument ännu.';

  @override
  String get docCollectPickFileTitle => 'Välj ett uppladdat dokument';

  @override
  String get docCollectExport => 'Exportera lista';

  @override
  String get docCollectExportSubject => 'Min dokumentchecklista';

  @override
  String get docCollectAiTitle => 'Behöver du något särskilt?';

  @override
  String get docCollectAiHint =>
      'Beskriv din situation, så föreslår vi eventuella extra dokument.';

  @override
  String get docCollectAiField => 'Beskriv din situation';

  @override
  String get docCollectAiButton => 'Föreslå extra dokument';

  @override
  String get docCollectAiLoading => 'Tänker …';

  @override
  String get docCollectAiEmpty =>
      'Inga extra dokument föreslås – grundlistan ser fullständig ut för din beskrivning.';

  @override
  String get docCollectAiSuggestionsTitle => 'Föreslagna extra dokument';

  @override
  String get docCollectDisclaimer =>
      'Detta är en grundläggande lista över vanligt förekommande dokument – din situation kan kräva fler eller färre. Det är allmän information, inte juridisk rådgivning.';

  @override
  String get docCollectRetry => 'Försök igen';

  @override
  String get renewalTitle => 'Förnyelseradar';

  @override
  String get renewalSubtitle =>
      'Håll koll på när dina tillstånd, ditt pass, din försäkring och andra dokument går ut. Vi påminner dig 90, 30 och 7 dagar före varje förnyelse.';

  @override
  String get renewalAdd => 'Lägg till dokument';

  @override
  String get renewalEditTitle => 'Redigera dokument';

  @override
  String get renewalSave => 'Spara';

  @override
  String get renewalRequired => 'Obligatoriskt';

  @override
  String get renewalPickDate => 'Välj utgångsdatum';

  @override
  String get renewalLoadError =>
      'Det gick inte att läsa in dina dokument. Dra för att uppdatera.';

  @override
  String get renewalEmptyTitle => 'Inga dokument bevakas ännu';

  @override
  String get renewalEmptyBody =>
      'Lägg till ditt uppehållstillstånd, pass, försäkring eller körkort, så bevakar vi utgångsdatumen åt dig.';

  @override
  String get renewalGuideHint => 'Så förnyar du →';

  @override
  String get renewalFieldType => 'Dokumenttyp';

  @override
  String get renewalFieldLabel => 'Etikett';

  @override
  String get renewalFieldNumber => 'Dokumentnummer (valfritt)';

  @override
  String get renewalFieldJurisdiction => 'Utfärdande land';

  @override
  String get renewalFieldExpiry => 'Utgångsdatum';

  @override
  String get renewalWindow90 => '90 dagar';

  @override
  String get renewalWindow30 => '30 dagar';

  @override
  String get renewalWindow7 => '7 dagar';

  @override
  String get renewalExpiresToday => 'Går ut i dag';

  @override
  String renewalExpiresInDays(int days, String date) {
    return 'Går ut om $days dagar · $date';
  }

  @override
  String renewalExpiredOn(String date) {
    return 'Gick ut den $date';
  }

  @override
  String get renewalTypeResidencePermit => 'Uppehållstillstånd';

  @override
  String get renewalTypePassport => 'Pass';

  @override
  String get renewalTypeIdCard => 'ID-kort';

  @override
  String get renewalTypeVisa => 'Visum';

  @override
  String get renewalTypeDrivingLicence => 'Körkort';

  @override
  String get renewalTypeInsurance => 'Försäkring';

  @override
  String get renewalTypeWorkPermit => 'Arbetstillstånd';

  @override
  String get renewalTypeOther => 'Övrigt';

  @override
  String get costEstimateTitle => 'Kostnads- och riskberäknare';

  @override
  String get costEstimateSubtitle =>
      'Få en ungefärlig uppfattning om vad ett ärende kan kosta, hur lång tid det kan ta och om det är värt att driva.';

  @override
  String get costEstimateCaseTypeLabel => 'Typ av ärende';

  @override
  String get costEstimateCaseTypeHint =>
      't.ex. obetald faktura, ogiltig uppsägning, depositionstvist';

  @override
  String get costEstimateJurisdictionLabel => 'Jurisdiktion';

  @override
  String get costEstimateAmountLabel => 'Tvistebelopp (valfritt)';

  @override
  String get costEstimateAmountHint => 't.ex. 12500';

  @override
  String get costEstimateDescriptionLabel =>
      'Beskriv kort situationen (valfritt)';

  @override
  String get costEstimateB2bToggle => 'Kort för leadskvalificering (B2B)';

  @override
  String get costEstimateB2bSubtitle =>
      'Kompakt utdata för att snabbt sortera en inkommande klient.';

  @override
  String get costEstimateSubmit => 'Beräkna mitt ärende';

  @override
  String get costEstimateDisclaimer =>
      'Endast en grov uppskattning – inte en förutsägelse, garanti eller juridisk rådgivning. Faktiska kostnader och utfall varierar från fall till fall.';

  @override
  String get costEstimateCostsHeading => 'Uppskattade kostnader';

  @override
  String get costEstimateCourtFee => 'Domstols- / statlig avgift';

  @override
  String get costEstimateLawyerFee => 'Advokatarvode';

  @override
  String get costEstimateTotal => 'Totalt (ca)';

  @override
  String get costEstimateDuration => 'Tid till första avgörande';

  @override
  String get costEstimateMonthsSuffix => 'månader';

  @override
  String get costEstimateFactorsFor => 'Till din fördel';

  @override
  String get costEstimateFactorsAgainst => 'Mot dig';

  @override
  String get costEstimateStrengthWorth => 'Sannolikt värt att driva';

  @override
  String get costEstimateStrengthContested =>
      'Omtvistat – kan gå åt båda hållen';

  @override
  String get costEstimateStrengthWeak => 'Svagt – gå försiktigt fram';
}
