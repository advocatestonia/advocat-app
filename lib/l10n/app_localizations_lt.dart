// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Lithuanian (`lt`).
class AppLocalizationsLt extends AppLocalizations {
  AppLocalizationsLt([String locale = 'lt']) : super(locale);

  @override
  String get about => 'Apie';

  @override
  String get aboutSection => 'APIE';

  @override
  String get accidents => 'Avarijos';

  @override
  String get active => 'Aktyvios';

  @override
  String get activeCases => 'Aktyvios bylos';

  @override
  String get addedToAppeal => 'Pridėta prie apeliacijos';

  @override
  String get agreeToTerms => 'Sutinku su ';

  @override
  String get aiAnalysis => 'AI analizė';

  @override
  String get aiAssistant => 'AI teisinis padėjėjas';

  @override
  String get aiChat => 'AI pokalbis';

  @override
  String get all => 'Visos';

  @override
  String get alreadyHaveAccount => 'Jau turite paskyrą? ';

  @override
  String get analyzing => 'Analizuojama…';

  @override
  String get aiAnalyzing => 'AI is analyzing';

  @override
  String get speakIntoMicHint =>
      'Speak into the microphone. Make sure microphone access is enabled.';

  @override
  String get aiErrorRateLimit =>
      'The service is temporarily overloaded. Please try again in 1-2 minutes.';

  @override
  String get aiErrorOverload =>
      'The AI is busy right now, please try again in a minute.';

  @override
  String freeLimitReached(int count) {
    return 'You have used all $count free AI messages. Upgrade to Legal Counsel for unlimited AI assistance!';
  }

  @override
  String get andWord => ' ir ';

  @override
  String get appTitle => 'Advocat — Teisinės informacijos įrankis';

  @override
  String get appVersion => 'Programėlės versija';

  @override
  String get appealFiled => 'Apeliacija pateikta';

  @override
  String get areYouAbsolutelySure => 'Ar tikrai esate tikras?';

  @override
  String get askAboutCase => 'Analizuoti mano bylą';

  @override
  String get asylum => 'Prieglobstis';

  @override
  String get back => 'Atgal';

  @override
  String get basic => 'Bazinis';

  @override
  String get beforeYouBuy => 'Prieš perkant';

  @override
  String get beforeYouWork => 'Prieš dirbdami su jais';

  @override
  String get camera => 'Kamera';

  @override
  String get cancel => 'Atšaukti';

  @override
  String get caseDescription => 'Aprašykite savo situaciją';

  @override
  String get caseDetail => 'Bylos detalios';

  @override
  String get caseOverview => 'Štai jūsų bylų apžvalga';

  @override
  String get caseTitle => 'Bylos pavadinimas';

  @override
  String get caseUpdated => 'Byla atnaujinta';

  @override
  String get cases => 'Bylos';

  @override
  String get checkCompany => 'Patikrinti įmonę';

  @override
  String get checkDeadlines => 'Patikrinti terminus';

  @override
  String get checkVehicle => 'Patikrinti transporto priemonę';

  @override
  String get checkerTitle => 'Tikrintojas';

  @override
  String get checkingErrors => 'Tikrinamos klaidos…';

  @override
  String get choosePlan => 'Pasirinkti planą';

  @override
  String get closed => 'Uždarytos';

  @override
  String get companyName => 'Įmonės pavadinimas arba reg. numeris';

  @override
  String get completed => 'Užbaigta';

  @override
  String get confirm => 'Patvirtinti';

  @override
  String get confirmPassword => 'Patvirtinti slaptažodį';

  @override
  String get connectEmail => 'Prijungti el. paštą';

  @override
  String get connectGmail => 'Prijungti Gmail';

  @override
  String get connectOutlook => 'Prijungti Outlook';

  @override
  String get connected => 'Prijungtas';

  @override
  String get contactSupport => 'Susisiekite su palaikymu';

  @override
  String get continueWithGoogle => 'Tęsti su Google';

  @override
  String get appleComingSoon => 'Coming soon';

  @override
  String get appleComingSoonMessage =>
      'Apple Sign-In becomes available soon. Use Google or email to continue.';

  @override
  String get copyText => 'Kopijuoti tekstą';

  @override
  String get correspondence => 'Korespondencija';

  @override
  String get couldNotLoadCases => 'Nepavyko įkelti jūsų bylų';

  @override
  String get country => 'Šalis';

  @override
  String get createAccount => 'Sukurti paskyrą';

  @override
  String get createCase => 'Sukurti bylą';

  @override
  String get criminalCase => 'Baudžiamoji byla';

  @override
  String get critical => 'Kritinis';

  @override
  String get currentPlan => 'Dabartinis planas';

  @override
  String get dataAndPrivacy => 'DUOMENYS IR PRIVATUMAS';

  @override
  String get dataExportRequested =>
      'Duomenų eksportas užsakytas. Patikrinkite savo el. paštą.';

  @override
  String daysRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dienų',
      many: '$count dienos',
      few: '$count dienos',
      one: '$count diena',
      zero: 'dienų nebeliko',
    );
    return '$_temp0';
  }

  @override
  String get deadlineReminders => 'Terminų priminimai';

  @override
  String get deadlineRemindersDesc => 'Gaukite pranešimus prieš terminus';

  @override
  String get deadlines => 'Terminai';

  @override
  String get debtCollection => 'Skolų išieškojimas';

  @override
  String get deleteAccount => 'Ištrinti paskyrą';

  @override
  String get deleteAccountDesc => 'Visam laikui pašalinti jūsų paskyrą';

  @override
  String get deleteAccountDialogContent =>
      'Šis veiksmas yra neatstatomai ir negali būti atšauktas. Visi jūsų duomenys, bylos ir dokumentai bus visam laikui ištrinti.';

  @override
  String get deleteConfirm =>
      'Ar tikrai? Tai neatstatomai ištrins visus jūsų duomenis.';

  @override
  String get demoHint => 'Demo: išbandykite numerį „908FBT“';

  @override
  String get demoModeDesc =>
      'Ištyrinkite programėlę su pavyzdiniais duomenimis iš realios bylos';

  @override
  String get deportation => 'Deportacija';

  @override
  String get disclaimer =>
      'Tik AI rekomendacijos — ne teisinė konsultacija. Visada kreipkitės į advokatą.';

  @override
  String get disclaimerFull =>
      'Tai AI padėjėjas, ne advokatas. AI analizė gali turėti klaidų. Visada patikrinkite su kvalifikuotu teisininku.';

  @override
  String get disconnect => 'Atjungti';

  @override
  String get discrimination => 'Diskriminacija';

  @override
  String get doNotBuy => 'Nepirkite';

  @override
  String get documents => 'Dokumentai';

  @override
  String documentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dokumentų',
      many: '$count dokumento',
      few: '$count dokumentai',
      one: '$count dokumentas',
      zero: 'dokumentų nėra',
    );
    return '$_temp0';
  }

  @override
  String get draftAppeal => 'Apeliacijos projektas';

  @override
  String get editDraft => 'Redaguoti';

  @override
  String get editProfile => 'Redaguoti profilį';

  @override
  String get email => 'El. paštas';

  @override
  String get emailConnected => 'El. paštas prijungtas';

  @override
  String get emailDisconnected => 'El. paštas atjungtas';

  @override
  String get emailIntegration => 'EL. PAŠTO INTEGRACIJA';

  @override
  String get emailInvalid => 'Prašome įvesti galiojantį el. pašto';

  @override
  String get emailPrivacyNote =>
      'Mes skaitome tik su teisiniais klausimais susijusius el. laiškus. Jūsų asmeniniai laiškai lieka privatios.';

  @override
  String get emailRequired => 'El. paštas yra būtinas';

  @override
  String get emergencyShield => 'Skubios apsaugos skydas';

  @override
  String get error => 'Klaida';

  @override
  String get exportDataDesc => 'Atsisiųsti visus bylos duomenis';

  @override
  String get exportDataDialogContent =>
      'Mes parengsime visų jūsų duomenų atsisiuntimą, įskaitant bylas, dokumentus ir korespondenciją. Gausite el. laišką, kai bus parengta.';

  @override
  String get exportMyData => 'Eksportuoti mano duomenis';

  @override
  String get exportPdf => 'Eksportuoti PDF';

  @override
  String get familyReunification => 'Šeimos susivienijimas';

  @override
  String get forgotPassword => 'Pamiršote slaptažodį?';

  @override
  String get free => 'Nemokama';

  @override
  String get fullDefense => 'Advocat Pro';

  @override
  String get fullName => 'Pilnas vardas';

  @override
  String get gallery => 'Galerija';

  @override
  String get generateAppeal => 'Generuoti apeliaciją';

  @override
  String get getStarted => 'Pradėti';

  @override
  String goodAfternoon(String name) {
    return 'Laba diena, $name';
  }

  @override
  String goodEvening(String name) {
    return 'Labas vakaras, $name';
  }

  @override
  String goodMorning(String name) {
    return 'Labas rytas, $name';
  }

  @override
  String goodNight(String name) {
    return 'Labos nakties, $name';
  }

  @override
  String get home => 'Pradinis';

  @override
  String get important => 'Svarbus';

  @override
  String get inProgress => 'Vykdoma';

  @override
  String get informational => 'Informacinis';

  @override
  String get inspection => 'Techninė apžiūra';

  @override
  String get insurance => 'Draudimas';

  @override
  String issuesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Rasta $count problemų',
      many: 'Rasta $count problemos',
      few: 'Rasta $count problemos',
      one: 'Rasta $count problema',
      zero: 'problemų nerasta',
    );
    return '$_temp0';
  }

  @override
  String get laborDispute => 'Darbo ginčas';

  @override
  String get langEnglish => 'Anglų';

  @override
  String get langFinnish => 'Suomių';

  @override
  String get langRussian => 'Rusų';

  @override
  String get language => 'Kalba';

  @override
  String lastActivity(String time) {
    return 'Paskutinė veikla: $time';
  }

  @override
  String get legalFighter => 'Teisinis kovotojas';

  @override
  String get legalSection => 'TEISINIS';

  @override
  String get licensePlate => 'Valstybinis numeris';

  @override
  String get loading => 'Kraunama…';

  @override
  String get logIn => 'Prisijungti';

  @override
  String get loginFailed =>
      'Neteisingas el. paštas arba slaptažodis. Bandykite dar kartą.';

  @override
  String get lost => 'Prarasta';

  @override
  String get markComplete => 'Pažymėti kaip užbaigtą';

  @override
  String get mileage => 'Rida';

  @override
  String get myCases => 'Mano bylos';

  @override
  String get nameRequired => 'Pilnas vardas yra būtinas';

  @override
  String get newCase => 'Nauja byla';

  @override
  String get next => 'Toliau';

  @override
  String get noAccount => 'Neturite paskyros? ';

  @override
  String get noCases => 'Kol kas bylų nėra';

  @override
  String get noCasesYet => 'Kol kas bylų nėra';

  @override
  String get noDeadlines => 'Nėra terminų — viskas gerai!';

  @override
  String get noRecentActivity => 'Nėra naujausios veiklos';

  @override
  String get notifications => 'PRANEŠIMAI';

  @override
  String get onboardingDesc1 =>
      'Advocat padeda suprasti jūsų teisinę situaciją. AI įrankiai analizuoja dokumentus, nustato galimas problemas ir rengia dokumentų projektus jūsų peržiūrai. Tai ne advokatų kontora — tai technologijų įrankis jūsų bylai paremti.';

  @override
  String get onboardingDesc2 =>
      'Nufotografuokite bet kurį teisinį dokumentą. AI jį nuskaito keliomis kalbomis, ištraukia pagrindinius duomenis ir tikrina atitiktį ES direktyvoms bei nacionaliniams įstatymams.';

  @override
  String get onboardingDesc3 =>
      'Mūsų AI įrankiai tikrina daugiau nei 40 procesinės tvarkos reikalavimų tipų. AI analizė gali atskleisti problemas, kurioms reikia dėmesio — pavyzdžiui, įteikimo kalba, procesinis žingsniai ir teisiniai terminai. Visada patikrinkite su kvalifikuotu advokatu.';

  @override
  String get onboardingDesc4 =>
      'AI rengia apeliacijų, skundų ir laiškų projektus su teisinėmis nuorodomis jūsų peržiūrai. Jūs nusprendiate, ką pateikti. Kiekvienas dokumentas turėtų būti peržiūrėtas kvalifikuoto teisininko prieš pateikiant.';

  @override
  String get onboardingNext => 'Toliau';

  @override
  String get onboardingSkip => 'Praleisti';

  @override
  String get onboardingTitle1 => 'AI pagrindu veikianti teisinė informacija';

  @override
  String get onboardingTitle2 => 'Nuskaitykite ir analizuokite dokumentus';

  @override
  String get onboardingTitle3 => 'AI tikrina galimas problemas';

  @override
  String get onboardingTitle4 => 'Dokumentų projektai jūsų peržiūrai';

  @override
  String get openACase => 'Atidaryti bylą';

  @override
  String get optional => '(neprivaloma)';

  @override
  String get orDivider => 'arba';

  @override
  String get other => 'Kita';

  @override
  String get overdue => 'Vėluojama';

  @override
  String get owners => 'Ankstesni savininkai';

  @override
  String get password => 'Slaptažodis';

  @override
  String get passwordRequired => 'Slaptažodis yra būtinas';

  @override
  String get passwordStrengthMedium => 'Vidutinis';

  @override
  String get passwordStrengthStrong => 'Stiprus';

  @override
  String get passwordStrengthWeak => 'Silpnas';

  @override
  String get passwordTooShort => 'Slaptažodis turi būti bent 8 simbolių';

  @override
  String get passwordsDoNotMatch => 'Slaptažodžiai nesutampa';

  @override
  String get pendingDecision => 'Laukiama sprendimo';

  @override
  String get perCheck => 'už patikrinimą';

  @override
  String get permanentlyDelete => 'Ištrinti visam laikui';

  @override
  String get policeMisconduct => 'Policijos netinkamas elgesys';

  @override
  String get popular => 'POPULIARU';

  @override
  String get preferences => 'NUSTATYMAI';

  @override
  String get preferredLanguage => 'Pageidaujama kalba';

  @override
  String get pricePerCheck => '€4,99 už patikrinimą';

  @override
  String get privacyPolicy => 'Privatumo politika';

  @override
  String get dpaTitle => 'Data Processing Agreement';

  @override
  String get dpaCheckoutGateTitle => 'Before you upgrade';

  @override
  String get dpaCheckoutGateBody =>
      'EU law (GDPR Art. 28) requires us to sign a Data Processing Agreement with every paying customer. Please review and accept.';

  @override
  String get dpaViewLink => 'View Data Processing Agreement';

  @override
  String get dpaCheckboxLabel =>
      'I have read and accept the Data Processing Agreement (v1.0).';

  @override
  String get dpaCancel => 'Cancel';

  @override
  String get dpaAcceptAndContinue => 'Accept and continue';

  @override
  String get dpaOpenHint =>
      'Open the DPA at least once to enable the Accept button.';

  @override
  String get pro => 'Pro';

  @override
  String get pushNotifications => 'Push pranešimai';

  @override
  String get rateUs => 'Įvertinkite mus';

  @override
  String get rateAppComingSoon => 'Coming to app stores soon!';

  @override
  String get dataCopiedToClipboard => 'Data copied to clipboard';

  @override
  String get readingDocument => 'Skaitomas dokumentas…';

  @override
  String get recentActivity => 'Naujausia veikla';

  @override
  String get referenceNumber => 'Nuorodos numeris';

  @override
  String get registerFailed => 'Registracija nepavyko. Bandykite dar kartą.';

  @override
  String get reportFraud => 'Pranešti apie sukčiavimą';

  @override
  String get requestExport => 'Prašyti eksporto';

  @override
  String get researchingLaw => 'Tiriami taikytini įstatymai…';

  @override
  String get resetPasswordFailed =>
      'Nepavyko išsiųsti atstatymo nuorodos. Bandykite dar kartą.';

  @override
  String get resetPasswordSent =>
      'Slaptažodžio atstatymo nuoroda išsiųsta į jūsų el. paštą.';

  @override
  String get residencePermit => 'Leidimas gyventi';

  @override
  String get manageSubscription => 'Tvarkyti prenumeratą';

  @override
  String get restorePurchases => 'Atkurti pirkinius';

  @override
  String get retry => 'Bandyti dar kartą';

  @override
  String get reviewWarning =>
      'Atidžiai peržiūrėkite prieš siųsdami. Jūs esate atsakingas už turinį.';

  @override
  String get riskHigh => 'Didelė rizika — venkite';

  @override
  String get riskLow => 'Saugu dirbti';

  @override
  String get riskMedium => 'Elkitės atsargiai';

  @override
  String get safeToBuy => 'Saugu pirkti';

  @override
  String get saveAndAnalyze => 'Išsaugoti ir analizuoti';

  @override
  String get saveDraft => 'Išsaugoti';

  @override
  String get saveWithAnnual => 'Sutaupykite 25% su metiniu mokėjimu';

  @override
  String get scan => 'Nuskaityti';

  @override
  String get scanDocument => 'Nuskaityti dokumentą';

  @override
  String get searchCases => 'Ieškoti bylų…';

  @override
  String get selectCountry => 'Pasirinkite šalį';

  @override
  String get selectLanguage => 'Pasirinkti kalbą';

  @override
  String get sendViaEmail => 'Siųsti el. paštu';

  @override
  String get settings => 'Nustatymai';

  @override
  String get signIn => 'Prisijungti';

  @override
  String get signInLink => 'Prisijungti';

  @override
  String get signInSubtitle => 'Prisijunkite, kad pasiektumėte savo bylas';

  @override
  String get signOut => 'Atsijungti';

  @override
  String get signOutConfirm => 'Ar tikrai norite atsijungti?';

  @override
  String get signUp => 'Sukurti paskyrą';

  @override
  String get signUpLink => 'Registruotis';

  @override
  String get socialBenefits => 'Socialinės išmokos';

  @override
  String get someConcerns => 'Kai kurie nuogąstavimai';

  @override
  String get startFirstCase => 'Pradėkite savo pirmą bylą';

  @override
  String step(int current, int total) {
    return '$current žingsnis iš $total';
  }

  @override
  String get stolen => 'Vagystės patikrinimas';

  @override
  String get subscription => 'Prenumerata';

  @override
  String get syncLegalCorrespondence =>
      'Sinchronizuoti teisinę korespondenciją';

  @override
  String get syncNow => 'Sinchronizuoti dabar';

  @override
  String get tenantRights => 'Nuomininko teisės';

  @override
  String get termsOfService => 'Paslaugos sąlygomis';

  @override
  String get termsRequired => 'Turite sutikti su Paslaugos sąlygomis';

  @override
  String get timeline => 'Laiko juosta';

  @override
  String get tryDemoMode => 'Išbandyti demo režimą';

  @override
  String get typeDeleteToConfirm =>
      'Įveskite DELETE, kad patvirtintumėte nuolatinį paskyros pašalinimą.';

  @override
  String get typeMessage => 'Įveskite žinutę…';

  @override
  String get upcoming => 'Artėjanti';

  @override
  String get uploadDocument => 'Įkelti dokumentą';

  @override
  String urgentDeadline(String title) {
    return 'Skubu: $title';
  }

  @override
  String get useInAppeal => 'Naudoti apeliacijoje';

  @override
  String get vehicleChecker => 'Transporto priemonės tikrintojas';

  @override
  String get vehicleChecks => 'Būklės patikrinimai';

  @override
  String get vehicleColor => 'Spalva';

  @override
  String get vehicleMake => 'Markė';

  @override
  String get vehicleModel => 'Modelis';

  @override
  String get vehicleYear => 'Metai';

  @override
  String get version => 'Versija';

  @override
  String get victimSupport => 'Aukų pagalba';

  @override
  String get viewAll => 'Peržiūrėti visas';

  @override
  String get vinNumber => 'VIN numeris';

  @override
  String get welcomeBack => 'Sveiki sugrįžę';

  @override
  String get whatAreMyOptions => 'Kokios mano galimybės?';

  @override
  String get won => 'Laimėta';

  @override
  String get documentVault => 'Dokumentų saugykla';

  @override
  String get secureDocumentStorage => 'Saugi dokumentų saugykla';

  @override
  String get secureDocumentStorageDesc =>
      'Saugiai laikykite svarbius teisinius dokumentus. Visi failai yra pilnai užšifruoti.';

  @override
  String get addDocument => 'Pridėti dokumentą';

  @override
  String get chooseHowToAdd => 'Pasirinkite, kaip pridėti dokumentą';

  @override
  String get uploadFile => 'Įkelti failą';

  @override
  String get uploadFileDesc =>
      'Pasirinkite PDF arba nuotrauką iš savo įrenginio';

  @override
  String get scanDocumentDesc => 'Nufotografuokite savo dokumentą';

  @override
  String get createNote => 'Sukurti pastabą';

  @override
  String get createNoteDesc =>
      'Parašykite pastabą arba užfiksuokite svarbias detales';

  @override
  String get knowYourRights => 'Žinok savo teises';

  @override
  String get stoppedByPolice => 'Sustabdė policija';

  @override
  String get stoppedByPoliceDesc => 'Jūsų teisės policijos patikrinimo metu';

  @override
  String get deportationNotice => 'Deportacijos pranešimas';

  @override
  String get deportationNoticeDesc =>
      'Žingsniai ginčijant išsiuntimo sprendimą';

  @override
  String get workplaceRights => 'Darbo teisės';

  @override
  String get workplaceRightsDesc => 'Darbo teisės apsauga Suomijoje';

  @override
  String get tenantRightsDesc => 'Būsto ir nuomos apsauga';

  @override
  String get immigrationDetention => 'Imigracijos sulaikymas';

  @override
  String get immigrationDetentionDesc =>
      'Jūsų teisės, jei esate sulaikytas valdžios institucijų';

  @override
  String get discriminationDesc =>
      'Kaip pranešti apie diskriminaciją ir kovoti su ja';

  @override
  String get scenarioNotFound => 'Scenarijus nerastas';

  @override
  String get youHaveRightTo => 'Jūs turite teisę:';

  @override
  String get youMust => 'Jūs privalote:';

  @override
  String get immediateSteps => 'Neatidėliotini žingsniai:';

  @override
  String get yourRights => 'Jūsų teisės:';

  @override
  String get basicRights => 'Pagrindinės teisės:';

  @override
  String get yourRightsAsTenant => 'Jūsų teisės kaip nuomininko:';

  @override
  String get yourRightsInDetention => 'Jūsų teisės sulaikymo metu:';

  @override
  String get howToAct => 'Kaip elgtis:';

  @override
  String get rightKnowWhyStopped => 'Žinoti, kodėl esate sustabdytas';

  @override
  String get rightRemainSilent => 'Tylėti (privalote pasakyti savo tapatybę)';

  @override
  String get rightAskInterpreter => 'Prašyti vertėjo';

  @override
  String get rightContactLawyer => 'Susisiekti su advokatu prieš apklausą';

  @override
  String get rightRecordEncounter => 'Įrašyti susitikimą (viešose vietose)';

  @override
  String get mustProvideName => 'Nurodyti savo vardą ir gimimo datą';

  @override
  String get mustShowId => 'Parodyti asmens dokumentą, jei turite';

  @override
  String get mustNotResist => 'Fiziškai nesipriešinti';

  @override
  String get doNotIgnoreNotice =>
      'NEIGNORUOKITE pranešimo — terminai yra griežti';

  @override
  String get noteAppealDeadline =>
      'Pasižymėkite apeliacijos terminą (paprastai 30 dienų)';

  @override
  String get contactLawyerImmediately => 'Nedelsdami susisiekite su advokatu';

  @override
  String get applyLegalAid => 'Kreipkitės dėl teisinės pagalbos, jei reikia';

  @override
  String get rightAppealAdmin => 'Teisė apskųsti Administraciniam teismui';

  @override
  String get rightLegalRep => 'Teisė į teisinį atstovavimą';

  @override
  String get rightInterpreter => 'Teisė į vertėją';

  @override
  String get rightStayDuringAppeal =>
      'Teisė likti apeliacijos metu (daugeliu atvejų)';

  @override
  String get minimumWage =>
      'Minimalus darbo užmokestis pagal kolektyvinę sutartį';

  @override
  String get workingTimeLimits =>
      'Darbo laiko ribos (maks. 8 val./dieną, 40 val./savaitę)';

  @override
  String get annualLeave =>
      'Kasmetinės atostogos (mažiausiai 2 dienos už kiekvieną dirbtą mėnesį)';

  @override
  String get sickLeave => 'Ligos pašalpa';

  @override
  String get safeWorkingConditions => 'Saugios darbo sąlygos';

  @override
  String get writtenRentalAgreement => 'Būtina rašytinė nuomos sutartis';

  @override
  String get securityDeposit => 'Užstatas — ne daugiau nei 3 mėnesių nuoma';

  @override
  String get landlordNotice => 'Nuomotojas turi įspėti (3–6 mėnesiai)';

  @override
  String get rightHabitableDwelling => 'Teisė į tinkamą gyventi būstą';

  @override
  String get protectionUnjustEviction => 'Apsauga nuo nepagrįsto iškeldinimo';

  @override
  String get rightKnowDetentionReason => 'Teisė žinoti sulaikymo priežastį';

  @override
  String get rightContactLawyerDetention => 'Teisė susisiekti su advokatu';

  @override
  String get rightContactEmbassy => 'Teisė susisiekti su savo ambasada';

  @override
  String get rightChallengeDetention => 'Teisė ginčyti sulaikymą teisme';

  @override
  String get rightHumaneTreatment =>
      'Teisė į humanišką elgesį ir medicininę priežiūrą';

  @override
  String get documentIncident =>
      'Užfiksuokite incidentą (data, laikas, liudytojai)';

  @override
  String get fileComplaintOmbudsman =>
      'Pateikite skundą Nediskriminavimo ombudsmenui';

  @override
  String get contactLegalAidOffice =>
      'Susisiekite su teisinės pagalbos tarnyba';

  @override
  String get reportToPolice =>
      'Praneškite policijai, jei tai nusikaltimas (grasinimas, užpuolimas)';

  @override
  String get legalAidCalculator => 'Teisinės pagalbos skaičiuoklė';

  @override
  String checkEligibility(String country) {
    return 'Patikrinkite savo teisę į teisinę pagalbą: $country';
  }

  @override
  String get estimateDisclaimer =>
      'Tai tik preliminarus įvertinimas. Tikrąją teisę nustato Teisinės pagalbos tarnyba.';

  @override
  String get monthlyIncome => 'Mėnesinės pajamos (EUR)';

  @override
  String get totalAssets => 'Bendras turtas (EUR)';

  @override
  String get numberOfDependents => 'Išlaikytinių skaičius';

  @override
  String get calculateEligibility => 'Apskaičiuoti teisę';

  @override
  String get likelyEligible => 'Tikriausiai atitinkate';

  @override
  String get mayNotQualify => 'Gali neatitikti';

  @override
  String get fullFreeLegalAid =>
      'Tikriausiai atitinkate visiškai nemokamos teisinės pagalbos reikalavimus (be dalinio mokėjimo).';

  @override
  String legalAidWithCopay(String percent) {
    return 'Galite atitikti teisinės pagalbos reikalavimus su daliniu mokėjimu $percent%.';
  }

  @override
  String get mayNotQualifyDesc =>
      'Pagal šį įvertinimą galite neatitikti valstybinės teisinės pagalbos reikalavimų. Apsvarstykite konsultaciją su privačiu advokatu arba teisine klinika.';

  @override
  String get couldNotLoadDeadlines => 'Nepavyko įkelti terminų';

  @override
  String get noUpcomingDeadlines => 'Nėra artėjančių terminų';

  @override
  String get allClearDeadlines =>
      'Viskas gerai! Nauji terminai bus rodomi čia, kai bus nustatyti.';

  @override
  String get nothingOverdue => 'Nieko nepavėluota';

  @override
  String get greatJobDeadlines => 'Puikus darbas laikantis terminų.';

  @override
  String get noCompletedDeadlines => 'Nėra užbaigtų terminų';

  @override
  String get completedDeadlinesDesc => 'Užbaigti terminai bus rodomi čia.';

  @override
  String get daysLate => 'dienų vėlavimas';

  @override
  String get days => 'dienų';

  @override
  String get fromDocument => 'Iš dokumento';

  @override
  String get couldNotLoadCase => 'Nepavyko įkelti bylos detalių';

  @override
  String get typeLabel => 'Tipas';

  @override
  String get nationality => 'Tautybė';

  @override
  String get migriReference => 'Migri nuoroda';

  @override
  String get courtCaseNo => 'Teismo bylos Nr.';

  @override
  String get created => 'Sukurta';

  @override
  String get citizenship => 'Pilietybė';

  @override
  String get workPermit => 'Darbo leidimas';

  @override
  String get noDocumentsYet => 'Dar nėra įkeltų dokumentų';

  @override
  String get noUpcomingDeadlinesShort => 'Nėra artėjančių terminų';

  @override
  String get caseCreated => 'Byla sukurta';

  @override
  String get decisionReceived => 'Sprendimas gautas';

  @override
  String get appealDeadline => 'Apeliacijos terminas';

  @override
  String get hearingScheduled => 'Teismo posėdis suplanuotas';

  @override
  String get late => 'vėluojama';

  @override
  String get pending => 'Laukiama';

  @override
  String get processing => 'Apdorojama';

  @override
  String get ready => 'Paruošta';

  @override
  String get failed => 'Nepavyko';

  @override
  String get analyzed => 'Išanalizuota';

  @override
  String get noDocumentsScanHint =>
      'Dar nėra dokumentų. Nuskaitykite arba įkelkite.';

  @override
  String get inCourt => 'Teisme';

  @override
  String get appeal => 'Apeliacija';

  @override
  String get caseTimeline => 'Bylos laiko juosta';

  @override
  String get couldNotLoadTimeline => 'Nepavyko įkelti laiko juostos';

  @override
  String get noEventsYet => 'Dar nėra įvykių';

  @override
  String get activityWillAppear =>
      'Veikla bus rodoma čia, bylai progresuojant.';

  @override
  String caseCreatedDesc(String title) {
    return 'Byla „$title“ buvo sukurta.';
  }

  @override
  String get decisionReceivedDesc => 'Gautas oficialus sprendimas šiai bylai.';

  @override
  String get appealDeadlineSet => 'Apeliacijos terminas nustatytas';

  @override
  String appealDeadlineDesc(String date) {
    return 'Apeliacija turi būti pateikta iki $date.';
  }

  @override
  String hearingScheduledDesc(String date) {
    return 'Teismo posėdis suplanuotas $date.';
  }

  @override
  String get caseInfoUpdated => 'Bylos informacija paskutinį kartą atnaujinta.';

  @override
  String get noEventsForFilter => 'No events match this filter';

  @override
  String get timelineFilterAll => 'All';

  @override
  String get timelineFilterEmails => 'Emails';

  @override
  String get timelineFilterConsilium => 'AI decisions';

  @override
  String get timelineFilterDeadlines => 'Deadlines';

  @override
  String get timelineFilterNotes => 'Notes';

  @override
  String get timelineEventEmailIn => 'Email received';

  @override
  String get timelineEventEmailOut => 'Email sent';

  @override
  String get timelineEventConsiliumDecision => 'AI decision';

  @override
  String get timelineEventDeadlineSet => 'Deadline';

  @override
  String get timelineEventDocUploaded => 'Document';

  @override
  String get timelineEventPhaseChange => 'Phase change';

  @override
  String get timelineEventManualNote => 'Note';

  @override
  String get timelineJustNow => 'Just now';

  @override
  String timelineMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String timelineHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String timelineDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get documentAnalysis => 'Dokumento analizė';

  @override
  String get exportAsPdf => 'Eksportuoti kaip PDF';

  @override
  String get pdfExportComingSoon => 'PDF eksportas netrukus';

  @override
  String get analysisFailedRetry => 'Analizė nepavyko. Bandykite dar kartą.';

  @override
  String get somethingWentWrong => 'Kažkas nutiko ne taip';

  @override
  String get genericError => 'Kažkas nepavyko. Bandykite dar kartą.';

  @override
  String get retryAnalysis => 'Pakartoti analizę';

  @override
  String issuesFoundInDocument(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dokumente rasta $count problemų',
      many: 'Dokumente rasta $count problemos',
      few: 'Dokumente rasta $count problemos',
      one: 'Dokumente rasta $count problema',
      zero: 'Dokumente problemų nerasta',
    );
    return '$_temp0';
  }

  @override
  String get severityOverview => 'Rimtumo apžvalga';

  @override
  String get issuesFoundHeader => 'Rastos problemos';

  @override
  String generateAppealWithIssues(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Generuoti apeliaciją ($count problemų)',
      many: 'Generuoti apeliaciją ($count problemos)',
      few: 'Generuoti apeliaciją ($count problemos)',
      one: 'Generuoti apeliaciją ($count problema)',
    );
    return '$_temp0';
  }

  @override
  String get analyzingContent => 'Analizuojamas turinys…';

  @override
  String get documentProcessedOk => 'Dokumentas sėkmingai apdorotas';

  @override
  String get noSignificantIssues =>
      'Šiame dokumente reikšmingų problemų nerasta.';

  @override
  String get cameraPermissionRequired => 'Reikalingas kameros leidimas';

  @override
  String get cameraPermissionDesc =>
      'Suteikite prieigą prie kameros, kad galėtumėte nuskaityti dokumentus, arba naudokite galeriją.';

  @override
  String get openSettings => 'Atidaryti nustatymus';

  @override
  String get alignDocument => 'Sulygiuokite dokumentą rėmelyje';

  @override
  String pageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count puslapių',
      many: '$count puslapio',
      few: '$count puslapiai',
      one: '$count puslapis',
      zero: 'puslapių nėra',
    );
    return '$_temp0';
  }

  @override
  String get preview => 'Peržiūra';

  @override
  String pageNumber(int number) {
    return '$number puslapis';
  }

  @override
  String get done => 'Atlikta';

  @override
  String get retake => 'Fotografuoti iš naujo';

  @override
  String get useThisPhoto => 'Naudoti šią nuotrauką';

  @override
  String get addPage => 'Pridėti puslapį';

  @override
  String uploadingPercent(int percent) {
    return 'Įkeliama… $percent%';
  }

  @override
  String get preparingUpload => 'Ruošiamas įkėlimas…';

  @override
  String get documentUploadedSuccess => 'Dokumentas sėkmingai įkeltas';

  @override
  String pagesUploadedSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sėkmingai įkelta $count puslapių',
      many: 'Sėkmingai įkelti $count puslapio',
      few: 'Sėkmingai įkelti $count puslapiai',
      one: 'Sėkmingai įkeltas $count puslapis',
    );
    return '$_temp0';
  }

  @override
  String get uploadFailed =>
      'Įkėlimas nepavyko. Patikrinkite ryšį ir bandykite dar kartą.';

  @override
  String get capturePhotoFailed =>
      'Nepavyko nufotografuoti. Bandykite dar kartą.';

  @override
  String get readingText => 'Skaitomas tekstas…';

  @override
  String get draftDocument => 'Dokumento projektas';

  @override
  String get saveChanges => 'Išsaugoti pakeitimus';

  @override
  String get editDocument => 'Redaguoti dokumentą';

  @override
  String get generatingDraft => 'Generuojamas jūsų projektas…';

  @override
  String get generatingDraftDesc =>
      'AI rengia teisinį dokumentą pagal jūsų bylos duomenis ir pasirinktas problemas.';

  @override
  String get failedToGenerateDraft =>
      'Nepavyko sugeneruoti projekto. Bandykite dar kartą.';

  @override
  String get changesSaved => 'Pakeitimai išsaugoti';

  @override
  String get copiedToClipboard => 'Nukopijuota į iškarpinę';

  @override
  String get emailComingSoon => 'El. laiškų siuntimas netrukus';

  @override
  String get reviewBeforeSending =>
      'Atidžiai peržiūrėkite prieš siųsdami. Jūs esate atsakingas už šio dokumento turinį.';

  @override
  String get noContentAvailable => 'Turinio nėra';

  @override
  String get save => 'Išsaugoti';

  @override
  String get edit => 'Redaguoti';

  @override
  String get pdf => 'PDF';

  @override
  String get copy => 'Kopijuoti';

  @override
  String get appealDraft => 'Apeliacijos projektas';

  @override
  String selected(int count) {
    return '$count pasirinkta';
  }

  @override
  String get deleteSelected => 'Ištrinti pasirinktus';

  @override
  String deleteDocumentsConfirm(int count) {
    return 'Ištrinti $count dokumentą(-us)?';
  }

  @override
  String get delete => 'Ištrinti';

  @override
  String get analyzeSelected => 'Analizuoti pasirinktus';

  @override
  String get batchAnalysisStarting => 'Pradedama paketinė analizė…';

  @override
  String get switchToList => 'Perjungti į sąrašą';

  @override
  String get switchToGrid => 'Perjungti į tinklelį';

  @override
  String get scanNew => 'Nuskaityti naują';

  @override
  String get noDocumentsYetScan => 'Dar nėra dokumentų';

  @override
  String get scanFirstDocumentHint =>
      'Nuskaitykite pirmą dokumentą, kad AI jį išanalizuotų klaidų paieškai ir apeliacijų generavimui.';

  @override
  String get failedToLoadDocuments => 'Nepavyko įkelti dokumentų';

  @override
  String get emailIntegrationTitle => 'El. pašto integracija';

  @override
  String get connectYourEmail => 'Prijunkite el. paštą';

  @override
  String get connectYourEmailDesc =>
      'Prijunkite el. paštą, kad automatiškai aptiktumėte ir tvarkytumėte su bylomis susijusią teisinę korespondenciją.';

  @override
  String get legalEmails => 'Teisiniai laiškai';

  @override
  String get unlinkedEmails => 'Nesusieti laiškai';

  @override
  String get noLegalEmailsYet => 'Teisinių laiškų dar nėra';

  @override
  String get legalEmailsWillAppear =>
      'Čia bus rodomi kaip teisiniai klasifikuoti laiškai.';

  @override
  String get assignToCase => 'Priskirti bylai';

  @override
  String get disconnectEmail => 'Atjungti el. paštą';

  @override
  String get disconnectEmailConfirm =>
      'Automatinis el. pašto sinchronizavimas bus sustabdytas. Anksčiau sinchronizuoti laiškai liks bylose.';

  @override
  String get gmailReauthBannerBody =>
      'Advocat v2.1 reads your inbox to draft replies; you can revoke any time. Reconnect Gmail to enable proactive triage.';

  @override
  String get gmailReauthBannerCta => 'Reauthorize';

  @override
  String connectedTo(String email) {
    return 'Prijungta prie $email';
  }

  @override
  String lastSynced(String time) {
    return 'Sinchronizuota: $time';
  }

  @override
  String get filterByType => 'Filtruoti pagal tipą';

  @override
  String get noCasesMatchSearch => 'Nerasta bylų pagal paiešką';

  @override
  String get failedToLoadCases => 'Nepavyko įkelti bylų';

  @override
  String get monthly => 'Mėnesinis';

  @override
  String get annual => 'Metinis';

  @override
  String get saveTwentyFivePercent => 'Sutaupykite 25%';

  @override
  String get mostPopular => 'POPULIARIAUSIAS';

  @override
  String get oneCaseActive => '1 aktyvi byla';

  @override
  String get threeCasesActive => '3 aktyvios bylos';

  @override
  String get unlimitedCases => 'Neribotos bylos';

  @override
  String get threeDocScans => '3 dokumentų nuskaitymai';

  @override
  String get twentyDocScans => '20 dokumentų nuskaitymų';

  @override
  String get unlimitedDocScans => 'Neribotas dokumentų nuskaitymas';

  @override
  String get basicAiAnalysis => 'Pagrindinė DI analizė';

  @override
  String get fullAiAnalysis => 'Pilna DI analizė';

  @override
  String get draftGeneration => 'Juodraščių kūrimas';

  @override
  String get priorityProcessing => 'Prioritetinis apdorojimas';

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
  String get forever => 'amžinai';

  @override
  String get perMonth => '/mėn.';

  @override
  String get perYear => '/m.';

  @override
  String get checkingPurchases => 'Tikrinami ankstesni pirkimai…';

  @override
  String get noPreviousPurchases => 'Ankstesnių pirkimų nerasta.';

  @override
  String get chatWelcomeMessage =>
      'Hi! I\'m Advocat — your AI legal assistant. I provide legal information, not legal advice. What legal question can I help with?';

  @override
  String get copySummary => 'Kopijuoti santrauką';

  @override
  String get caseSummaryCopied => 'Bylos santrauka nukopijuota';

  @override
  String get openCase => 'Atidaryti bylą';

  @override
  String get viewFull => 'Peržiūrėti visą';

  @override
  String get draftCopiedToClipboard => 'Juodraštis nukopijuotas';

  @override
  String get reportMileageFraud => 'Pranešti apie ridos klastojimą';

  @override
  String get reportMileageFraudDesc =>
      'Bus sukurtas sukčiavimo ataskaita pagal transporto priemonės patikrinimo duomenis. Taip pat galite atidaryti teisinę bylą.';

  @override
  String get reportAndOpenCase => 'Pranešti ir atidaryti bylą';

  @override
  String get caseCreationComingSoon =>
      'Bylos kūrimas su iš anksto užpildytais duomenimis netrukus';

  @override
  String get failedToCreateCaseRetry =>
      'Nepavyko sukurti bylos. Bandykite dar kartą.';

  @override
  String get takePhotoInstead => 'Nufotografuoti';

  @override
  String get deleteCase => 'Ištrinti bylą';

  @override
  String deleteCaseConfirm(String title) {
    return 'Ar tikrai norite ištrinti „$title“? Šio veiksmo negalima atšaukti.';
  }

  @override
  String get haveQuestionsAi => 'Turite klausimų? Klauskite DI';

  @override
  String get cookiePolicy => 'Slapukų politika';

  @override
  String get aiDisclaimer => 'DI atsakomybės apribojimas';

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
  String get dataPrivacyConsent => 'Duomenų privatumo sutikimas';

  @override
  String get gdprIntro =>
      'Teikdami teisinę pagalbą su DI, tvarkome jūsų duomenis pagal BDAR (ES 2016/679). Tęsdami sutinkate su:';

  @override
  String get gdprChat => 'Pokalbių pranešimų apdorojimas DI';

  @override
  String get gdprDocs => 'Įkeltų dokumentų analizė';

  @override
  String get gdprStorage => 'Šifruotas bylų duomenų saugojimas';

  @override
  String get gdprDelete => 'Teisė bet kada ištrinti savo duomenis';

  @override
  String get gdprFooter =>
      'Jūsų duomenys yra užšifruoti ir niekada nesidalijami su trečiosiomis šalimis. Galite atšaukti sutikimą ir ištrinti visus duomenis Nustatymuose.';

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
  String get decline => 'Atmesti';

  @override
  String get iAgree => 'Sutinku';

  @override
  String get iAgreeToThe => 'Sutinku su ';

  @override
  String get orWord => 'arba';

  @override
  String get english => 'Anglų';

  @override
  String get russian => 'Rusų';

  @override
  String get finnish => 'Suomių';

  @override
  String successSubscribed(String plan) {
    return 'Prenumerata $plan sėkmingai aktyvuota!';
  }

  @override
  String paymentFailed(String error) {
    return 'Mokėjimas nepavyko: $error';
  }

  @override
  String get whatToDo => 'Ką daryti';

  @override
  String get getHelp => 'Gauti pagalbą';

  @override
  String get share => 'Dalintis';

  @override
  String get didYouKnow => 'Ar žinojote?';

  @override
  String get mustKnow => 'Būtina žinoti';

  @override
  String get goodToKnow => 'Naudinga žinoti';

  @override
  String get sentFromAdvocat => 'Išsiųsta iš Advocat programėlės';

  @override
  String get policeActionStayCalm =>
      'Likite ramūs ir laikykite rankas matomoje vietoje';

  @override
  String get policeActionAskWhy =>
      'Paklauskite pareigūno, kodėl buvote sustabdytas';

  @override
  String get policeActionProvideName => 'Nurodykite savo vardą ir gimimo datą';

  @override
  String get policeActionWantLawyer =>
      'Aiškiai pasakykite: „Noriu advokato prieš bet kokius klausimus“';

  @override
  String get policeActionAskInterpreter => 'Jei reikia, paprašykite vertėjo';

  @override
  String get policeActionNoteBadge =>
      'Užsirašykite pareigūno vardą ir tarnybinį numerį';

  @override
  String get policeFactMustTellReason =>
      'Suomijoje policija privalo pasakyti sustabdymo priežastį. Jei to nepadaro, galite paklausti — ir jie teisiškai įpareigoti paaiškinti.';

  @override
  String get policeFactCanRecord =>
      'Suomijoje galite įrašyti sąveiką su policija viešose vietose. Tai apsaugota žodžio laisvės.';

  @override
  String get contactFinnishLegalAid => 'Suomijos teisinė pagalba';

  @override
  String get contactNonDiscriminationOmbudsman =>
      'Nediskriminavimo ombudsmenas';

  @override
  String get deportationDeadlineAppeal =>
      'Apeliacija Administraciniam teismui — paprastai 30 dienų nuo pranešimo';

  @override
  String get deportationDeadlineLegalAid =>
      'Kreipkitės dėl teisinės pagalbos — darykite tai NEDELSIANT';

  @override
  String get deportationFactStayDuringAppeal =>
      'Suomijoje paprastai turite teisę likti šalyje, kol jūsų apeliacija nagrinėjama. Deportacija negali būti vykdoma aktyvios apeliacijos metu daugeliu atvejų.';

  @override
  String get contactRefugeeAdviceCentre =>
      'Suomijos pabėgėlių konsultavimo centras';

  @override
  String get contactAdminCourtHelsinki => 'Helsinkio administracinis teismas';

  @override
  String get workplaceActionKeepContract => 'Saugokite darbo sutarties kopijas';

  @override
  String get workplaceActionTrackHours => 'Savarankiškai sekite darbo valandas';

  @override
  String get workplaceActionReportUnsafe =>
      'Praneškite apie nesaugias sąlygas darbo saugos institucijai';

  @override
  String get workplaceActionJoinUnion =>
      'Įstokite į profesinę sąjungą apsaugai';

  @override
  String get workplaceActionContactAuthority =>
      'Jei reikia, kreipkitės į Darbo saugos tarnybą';

  @override
  String get workplaceFactCollectiveWage =>
      'Suomijoje kolektyvinės sutartys nustato minimalų atlyginimą pagal pramonės šaką — vieno nacionalinio minimalaus atlyginimo nėra. Jūsų darbdavys privalo laikytis jūsų srities kolektyvinės sutarties.';

  @override
  String get workplaceFactOralContract =>
      'Net ir be rašytinės sutarties Suomijoje turite visas darbuotojo teises. Žodinis susitarimas yra teisiškai vienodai privalomas.';

  @override
  String get contactOccupationalSafety => 'Darbo saugos tarnyba';

  @override
  String get contactTradeUnionSAK => 'Profesinės sąjungos konsultacija (SAK)';

  @override
  String get tenantActionWrittenAgreement =>
      'Visada turėkite rašytinę nuomos sutartį';

  @override
  String get tenantActionDocumentCondition =>
      'Dokumentuokite buto būklę įsikeliant (nuotraukos)';

  @override
  String get tenantActionReportMaintenance =>
      'Praneškite apie priežiūros problemas raštu';

  @override
  String get tenantActionNoIllegalEviction =>
      'Niekada nesutikite su neteisėtu iškeldinimu — sprendžia teismas';

  @override
  String get tenantActionContactAdvisory =>
      'Kilus ginčams, kreipkitės į nuomininkų konsultavimo tarnybą';

  @override
  String get tenantFactNoEvictionWithoutCourt =>
      'Nuomotojas Suomijoje negali jūsų iškeldinti be teismo sprendimo, net jei nuomos sutartis pasibaigė. Spynų keitimas ar komunalinių paslaugų atjungimas yra neteisėtas.';

  @override
  String get contactTenantsAssociation => 'Suomijos nuomininkų asociacija';

  @override
  String get contactConsumerDisputesBoard => 'Vartotojų ginčų komisija';

  @override
  String get detentionActionAskDecision =>
      'Nedelsdami pareikalaukite rašytinio sulaikymo sprendimo';

  @override
  String get detentionActionRequestLawyer =>
      'Pareikalaukite susisiekti su advokatu';

  @override
  String get detentionActionContactEmbassy =>
      'Susisiekite su savo ambasada ar konsulatu';

  @override
  String get detentionActionAskMedical =>
      'Jei reikia, pareikalaukite medicininės pagalbos';

  @override
  String get detentionActionRequestInterpreter =>
      'Pareikalaukite vertėjo visoms teismo posėdžiams';

  @override
  String get detentionDeadlineCourtReview =>
      'Apylinkės teismas turi peržiūrėti sulaikymą per 4 dienas';

  @override
  String get detentionDeadlineContinuation =>
      'Teismas peržiūri pratęsimą kas 2 savaites';

  @override
  String get detentionFactCourtReview =>
      'Imigracinis sulaikymas Suomijoje turi būti peržiūrėtas apylinkės teismo per 4 dienas. Jei to nepadaroma, sulaikymas tampa neteisėtu.';

  @override
  String get contactParliamentaryOmbudsman => 'Parlamentinis ombudsmenas';

  @override
  String get discriminationActionWriteDown =>
      'Užrašykite tiksliai, kas atsitiko (data, laikas, vieta)';

  @override
  String get discriminationActionSaveEvidence =>
      'Išsaugokite įrodymus: žinutes, el. laiškus, liudytojus';

  @override
  String get discriminationActionFileComplaint =>
      'Pateikite skundą Nediskriminavimo ombudsmenui';

  @override
  String get discriminationActionContactLegalAid =>
      'Kreipkitės į teisinės pagalbos biurą dėl nemokamos konsultacijos';

  @override
  String get discriminationActionReportPolice =>
      'Praneškite policijai, jei buvo grasinimų ar užpuolimo';

  @override
  String get discriminationFactNonDiscriminationAct =>
      'Suomijos nediskriminavimo įstatymas apima diskriminaciją dėl amžiaus, kilmės, pilietybės, kalbos, religijos, sveikatos, negalios, seksualinės orientacijos ir kitų asmeninių savybių.';

  @override
  String get contactVictimSupportRIKU => 'Aukų parama Suomija (RIKU)';

  @override
  String get domesticViolence => 'Smurtas šeimoje';

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
  String get inheritance => 'Paveldėjimas';

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
  String get consumerProtection => 'Vartotojų apsauga';

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
  String get comingSoon => 'Netrukus';

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
      other: '$count teisių viduje',
      many: '$count teisės viduje',
      few: '$count teisės viduje',
      one: '$count teisė viduje',
      zero: 'teisių nėra',
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
  String get chatDisclaimerSubtitle =>
      'DI asistentas · ne teisinė konsultacija';

  @override
  String get chatDisclaimerBannerFull =>
      'Advocat – tai DI teisinės informacijos asistentas, o ne advokatas. Čia pateikta informacija nesukuria advokato ir kliento santykių, nėra teisinė konsultacija ir gali būti netiksli. Dėl privalomos teisinės konsultacijos kreipkitės į licencijuotą advokatą savo jurisdikcijoje. Mes jums neatstovaujame.';

  @override
  String get chatDisclaimerFooter =>
      'Sukurta DI. Patikrinkite pas licencijuotą advokatą.';

  @override
  String get chatDisclaimerGotIt => 'Supratau';

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
  String get guestUser => 'Svečias';

  @override
  String get howToUse => 'Kaip naudoti?';

  @override
  String get tutorialStep1Title => 'DI teisinis asistentas';

  @override
  String get tutorialStep1Desc =>
      'Uzduokite bet koki teisini klausima ir gaukite greitus atsakymus pagal Estijos istatymus.';

  @override
  String get tutorialStep2Title => 'Zinokite savo teises';

  @override
  String get tutorialStep2Desc =>
      'Narsykite teisine informacija pagal temas — darbas, bustas, vartotoju teises ir daugiau.';

  @override
  String get tutorialStep3Title => 'Skenuoti dokumentus';

  @override
  String get tutorialStep3Desc =>
      'Fotografuokite teisinius dokumentus DI analizei ir saugiam saugojimui.';

  @override
  String get tutorialStep4Title => 'Pradekime!';

  @override
  String get tutorialStep4Desc =>
      'Isstyrinkite programele ir apsaugokite savo teises. Visi duomenys lieka privatūs jusu irengynyje.';

  @override
  String get advocatProTitle => 'Advocat Pro';

  @override
  String get advocatProSubtitle => 'Atrakinkite premium funkcijas';

  @override
  String get voiceDisclaimer =>
      'Balso asistentas šiuo metu veikia tik kompiuteryje (Chrome naršyklė). Mobilusis palaikymas netrukus.';

  @override
  String get recommended => 'Rekomenduojama';

  @override
  String get pleaseLogIn => 'Prašome prisijungti';

  @override
  String get subscriptionNotFound => 'Prenumerata nerasta';

  @override
  String errorWithMessage(String message) {
    return 'Klaida: $message';
  }

  @override
  String get redirectingToPayment => 'Nukreipiama į mokėjimo puslapį…';

  @override
  String cheaperAnnually(String amount) {
    return '€$amount/mėn. pigiau su metine prenumerata';
  }

  @override
  String get navigatingTo => 'Atidaroma';

  @override
  String get stayInChat => 'Likti pokalbyje';

  @override
  String get backToChat => 'Grįžti į pokalbį';

  @override
  String get upgradeBannerTitle => 'Upgrade for unlimited consultations';

  @override
  String get upgradeBannerCta => 'Upgrade';

  @override
  String get paymentSuccessTitle => 'Payment successful';

  @override
  String get paymentSuccessBody => 'Your subscription is now active.';

  @override
  String get commonOk => 'OK';

  @override
  String get feedbackThumbsUpLabel => 'Helpful';

  @override
  String get feedbackThumbsDownLabel => 'Not helpful';

  @override
  String get feedbackCommentPrompt => 'What was wrong?';

  @override
  String get feedbackSend => 'Send';

  @override
  String get feedbackCancel => 'Cancel';

  @override
  String get reasoningPillIdle => 'Thinking…';

  @override
  String get reasoningPillSearchingLaw => 'Searching Estonian law…';

  @override
  String get reasoningPillSearchingWeb => 'Searching the web…';

  @override
  String get reasoningPillCheckingCompany => 'Checking company registry…';

  @override
  String get reasoningPillCheckingVehicle => 'Checking vehicle registry…';

  @override
  String get reasoningPillReadingDocument => 'Reading your document…';

  @override
  String get reasoningPillDrafting => 'Drafting the document…';

  @override
  String get reasoningPillPreparingEmail => 'Preparing email…';

  @override
  String get reasoningPillFindingLawyer => 'Looking up lawyers…';

  @override
  String get reasoningPillThinking => 'Reasoning through your case…';

  @override
  String get reasoningPillFinalising => 'Composing your answer…';

  @override
  String reasoningCollapsedFormat(int sec, int sources) {
    return 'Reasoned for ${sec}s · $sources sources';
  }

  @override
  String get reasoningExpandHint => 'tap to see steps';

  @override
  String get caseFileTitle => 'Case File';

  @override
  String get caseFileTimeline => 'Timeline';

  @override
  String get caseFileParties => 'Parties';

  @override
  String get caseFileDeadlines => 'Deadlines';

  @override
  String get caseFileExportPdf => 'Download dossier (PDF)';

  @override
  String get caseFileEmpty =>
      'Chat with the AI about your case — your timeline will build itself.';

  @override
  String get caseFileDisclaimer =>
      'This dossier is auto-extracted from your chat. It is not legal advice.';

  @override
  String get caseFileTabLabel => 'Case';

  @override
  String get refresh => 'Refresh';

  @override
  String get demoLimitReached =>
      'Demo limit reached. Sign up for free to continue.';

  @override
  String get demoLimitSignUpCta => 'Sign up';

  @override
  String get freeQuotaExhausted =>
      'You\'ve used all 10 free messages this month.';

  @override
  String get upgradeForUnlimited => 'Upgrade to Pro for unlimited';

  @override
  String get upgradeCta => 'Upgrade';

  @override
  String get rateLimitTryAgain =>
      'Sending too fast. Try again in a few seconds.';

  @override
  String get quickProfilePrompt =>
      'So I can help more precisely, what is your legal status: are you an Estonian citizen, an EU citizen from another country, or do you have a residence permit?';

  @override
  String get quickProfileChipEstonianCitizen => 'Estonian citizen';

  @override
  String get quickProfileChipEuCitizen => 'EU citizen (other)';

  @override
  String get quickProfileChipResidencePermit => 'Residence permit';

  @override
  String get quickProfileSkipBtn => 'Skip';

  @override
  String get quickProfileSavedAck => 'Got it. Now, what\'s your question?';

  @override
  String get caseTitleLabel => 'Case title';

  @override
  String get jurisdictionLabel => 'Jurisdiction';

  @override
  String get caseTypeLabel => 'Case type';

  @override
  String get caseLanguageLabel => 'Language';

  @override
  String get caseNumbersSection => 'Case numbers';

  @override
  String get partiesSection => 'Parties';

  @override
  String get authoritiesSection => 'Authorities';

  @override
  String get timelineSection => 'Timeline';

  @override
  String get openQuestionsSection => 'Open questions';

  @override
  String get nextActionsSection => 'Next actions';

  @override
  String get summarySection => 'Summary';

  @override
  String get addRow => 'Add row';

  @override
  String get removeRow => 'Remove';

  @override
  String get archiveCase => 'Archive case';

  @override
  String get closeCase => 'Close case';

  @override
  String get continueChatAboutCase => 'Continue chat about this case';

  @override
  String get linkChatToCase => 'Link to case';

  @override
  String get clearActiveCase => 'Clear active case';

  @override
  String get caseSavedAck => 'Case saved';

  @override
  String get caseArchivedAck => 'Case archived';

  @override
  String get intakeStep1Title => 'Where is the case?';

  @override
  String get intakeStep1Subtitle =>
      'Country and authority you are dealing with.';

  @override
  String get intakeJurisdictionLabel => 'Country / jurisdiction';

  @override
  String get intakeAuthorityLabel => 'Authority type';

  @override
  String get intakeAuthorityNameLabel => 'Authority name (optional)';

  @override
  String get intakeAuthorityPolice => 'Police';

  @override
  String get intakeAuthorityCourt => 'Court';

  @override
  String get intakeAuthoritySocial => 'Social services';

  @override
  String get intakeAuthorityEmployer => 'Employer';

  @override
  String get intakeAuthorityLandlord => 'Landlord';

  @override
  String get intakeAuthorityOpposingParty => 'Opposing party';

  @override
  String get intakeAuthorityOther => 'Other';

  @override
  String get intakeStep2Title => 'What kind of case?';

  @override
  String get intakeStep2Subtitle =>
      'Pick the closest type — you can refine later.';

  @override
  String get intakeCaseTypeCriminal => 'Criminal';

  @override
  String get intakeCaseTypeCivil => 'Civil';

  @override
  String get intakeCaseTypeFamily => 'Family';

  @override
  String get intakeCaseTypeAdmin => 'Administrative';

  @override
  String get intakeCaseTypeImmigration => 'Immigration';

  @override
  String get intakeCaseTypeLabor => 'Labor';

  @override
  String get intakeCaseTypeConsumer => 'Consumer';

  @override
  String get intakeCaseTypeInheritance => 'Inheritance';

  @override
  String get intakeCaseTypeOther => 'Other';

  @override
  String get intakeStep3Title => 'Who is involved?';

  @override
  String get intakeStep3Subtitle => 'Your role and the other side.';

  @override
  String get intakeRoleLabel => 'Your role';

  @override
  String get intakeRolePlaintiff => 'Plaintiff';

  @override
  String get intakeRoleDefendant => 'Defendant';

  @override
  String get intakeRoleVictim => 'Victim';

  @override
  String get intakeRoleAccused => 'Accused';

  @override
  String get intakeRoleWitness => 'Witness';

  @override
  String get intakeRoleFamily => 'Family member';

  @override
  String get intakeRoleOther => 'Other';

  @override
  String get intakeOpposingSideLabel => 'Opposing side (optional)';

  @override
  String get intakeWitnessesLabel => 'Witnesses (optional)';

  @override
  String get intakeAddWitness => 'Add witness';

  @override
  String get intakeWitnessHint => 'Name or contact';

  @override
  String get intakeStep4Title => 'Numbers & dates';

  @override
  String get intakeStep4Subtitle =>
      'Whatever you already have. Skip what you don\'t.';

  @override
  String get intakeCaseNumberLabel => 'Case number (optional)';

  @override
  String get intakeIncidentDateLabel => 'Incident date (optional)';

  @override
  String get intakeIncidentDatePick => 'Pick date';

  @override
  String get intakeDeadlinesLabel => 'Known deadlines';

  @override
  String get intakeAddDeadline => 'Add deadline';

  @override
  String get intakeDeadlineWhatHint => 'What';

  @override
  String get intakeStep5Title => 'Documents';

  @override
  String get intakeStep5Subtitle =>
      'Upload anything relevant. We will read it.';

  @override
  String get intakeUploadDocsLabel => 'Upload documents';

  @override
  String get intakeSkipDocs => 'Skip — I\'ll upload later';

  @override
  String get intakeNextBtn => 'Next';

  @override
  String get intakeBackBtn => 'Back';

  @override
  String get intakeFinishBtn => 'Finish & open chat';

  @override
  String get intakeUrgentBtn => 'Urgent — ask now';

  @override
  String get intakeUrgentDialogTitle => 'Open chat now?';

  @override
  String get intakeUrgentDialogBody =>
      'We\'ll save what you\'ve entered as a draft case. You can finish the wizard from the case page anytime.';

  @override
  String get intakeUrgentConfirm => 'Open chat';

  @override
  String get intakeUrgentCancel => 'Keep filling';

  @override
  String get intakePreparingCase => 'Preparing your case…';

  @override
  String get intakeFallbackGreeting =>
      'I see your case. Tell me what\'s most pressing — I\'ll work through it with you.';

  @override
  String get intakeUrgentGreeting =>
      'I see this is urgent. Ask your question — I\'ll fill in the rest as we go.';

  @override
  String intakeStepIndicator(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get intakeFieldRequired => 'Required';

  @override
  String intakeUploadProgress(int done, int total) {
    return 'Uploading $done / $total…';
  }

  @override
  String get uplDisclaimerFooter =>
      'Advocat is not a law firm. This is information, not legal advice.';

  @override
  String get citationStatusVerifiedBadge => 'Patvirtinta';

  @override
  String get citationStatusUnverifiedBadge => 'Nepatvirtinta';

  @override
  String get citationStatusHistoricalBadge => 'Senoji redakcija';

  @override
  String get citationStatusVerifiedTooltip =>
      'Cituojama iš atgauto teisės šaltinio.';

  @override
  String get citationStatusUnverifiedTooltip =>
      'DI pacitavo šį pasažą be šaltinio atgavimo — patikrinkite prieš juo remdamiesi.';

  @override
  String get citationStatusHistoricalTooltip =>
      'Cituojama nuostata nebegalioja.';

  @override
  String get citationOpenInRiigiTeataja => 'Atidaryti Riigi Teataja';

  @override
  String get citationSnippetExpand => 'Rodyti visą tekstą';

  @override
  String get citationSnippetCollapse => 'Rodyti mažiau';

  @override
  String get citationUnverifiedSheetNote =>
      'DI pacitavo šį paragrafą, tačiau šioje sesijoje jis nebuvo atgautas iš teisės akto korpuso. Patikrinkite nuorodą prieš ja remdamiesi.';

  @override
  String get citationFooterNoneWarning => 'Nėra pagrįstų citatų';

  @override
  String citationFooterSummaryTotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count citatų',
      many: '$count citatos',
      few: '$count citatos',
      one: '$count citata',
    );
    return '$_temp0';
  }

  @override
  String citationFooterSummaryVerified(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count patvirtintų',
      many: '$count patvirtintos',
      few: '$count patvirtintos',
      one: '$count patvirtinta',
    );
    return '$_temp0';
  }

  @override
  String citationFooterSummaryUnverified(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nepatvirtintų',
      many: '$count nepatvirtintos',
      few: '$count nepatvirtintos',
      one: '$count nepatvirtinta',
    );
    return '$_temp0';
  }

  @override
  String citationFooterSummaryHistorical(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count senųjų redakcijų',
      many: '$count senosios redakcijos',
      few: '$count senosios redakcijos',
      one: '$count senoji redakcija',
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
      other: 'po $count dienų',
      many: 'po $count dienos',
      few: 'po $count dienų',
      one: 'po $count dienos',
      zero: 'šiandien',
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
      other: 'vėluoja $count dienų',
      many: 'vėluoja $count dienos',
      few: 'vėluoja $count dienas',
      one: 'vėluoja $count dieną',
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
    return 'Consilium recommends $count parallel actions';
  }

  @override
  String get parallelActionsApproveAll => 'Approve All & Send';

  @override
  String parallelActionsApproveSelected(int count, int total) {
    return 'Approve $count of $total';
  }

  @override
  String parallelActionsConfirmTitle(int count) {
    return 'Send $count emails?';
  }

  @override
  String parallelActionsConfirmBody(int count) {
    return 'Advocat will dispatch $count prepared replies via your connected Gmail. Each one is sent independently — if any one fails, the others still go.';
  }

  @override
  String parallelActionsSentToast(int count) {
    return '$count sent.';
  }

  @override
  String parallelActionsPartialFailureToast(int sent, int failed) {
    return '$sent sent, $failed failed.';
  }

  @override
  String get parallelActionsKindReply => 'reply';

  @override
  String get parallelActionsKindNew => 'new';

  @override
  String get parallelActionsCheckboxSelected => 'Action selected';

  @override
  String get parallelActionsCheckboxUnselected => 'Action not selected';

  @override
  String parallelActionsCitationCount(int count) {
    return '$count cit';
  }

  @override
  String parallelActionsRetryFailed(int count) {
    return 'Retry failed ($count)';
  }

  @override
  String get agentApprovalNeedsReviewTitle => 'Advocat needs your approval';

  @override
  String get agentApprovalResolvedTitle => 'Action resolved';

  @override
  String get agentApprovalStepsLabel => 'steps';

  @override
  String get agentApprovalApproveButton => 'Approve & Send';

  @override
  String get agentApprovalDeclineButton => 'Decline';

  @override
  String get agentApprovalAttachmentsLabel => 'Attachments';

  @override
  String get agentApprovalSentSummary => 'Sent on your behalf.';

  @override
  String get agentApprovalDeclinedSummary => 'Declined — nothing was sent.';

  @override
  String get agentToolDraftEmailAtt => 'Send email with attachments';

  @override
  String get agentToolSendEmail => 'Send email';

  @override
  String get agentToolGeneratePdf => 'Generate PDF';

  @override
  String get agentToolApproveSend => 'Send prepared reply';

  @override
  String get inboxErrorTitle => 'Could not load inbox';

  @override
  String get inboxEditDiscardTitle => 'Discard unsaved edits?';

  @override
  String get inboxEditDiscardBody =>
      'You have unsaved changes to this draft. Going back will discard them.';

  @override
  String get inboxEditKeepEditing => 'Keep editing';

  @override
  String get inboxEditDiscard => 'Discard';

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
  String get plannerSettingsTitle => 'Three-pass legal reasoning';

  @override
  String get plannerSettingsSubtitle =>
      'Plan → answer → critique. Slower but more thorough.';

  @override
  String get plannerSettingsProBadge => 'Pro';

  @override
  String get plannerSettingsProDescription => 'Available on Pro plan';

  @override
  String get plannerTrailHeaderPlan => 'Plan';

  @override
  String get plannerTrailHeaderCritique => 'Critique';

  @override
  String get plannerTrailSubQuestions => 'Sub-questions';

  @override
  String get plannerTrailCounterArgs => 'Counter-arguments';

  @override
  String get plannerTrailEvidenceGaps => 'Evidence gaps';

  @override
  String get plannerTrailMaterialGapTrue => 'Material gap detected';

  @override
  String get plannerTrailRegeneratedBadge => 'Regenerated once';

  @override
  String get plannerTrailEmpty => 'no items';

  @override
  String get supportTitle => 'Help';

  @override
  String get supportSubtitle => 'We usually reply within 1-2 hours.';

  @override
  String get supportSearchPlaceholder => 'Search help…';

  @override
  String get supportStatusAllOk => 'All systems normal';

  @override
  String get supportFaqWhatIs => 'What is Advocat?';

  @override
  String get supportFaqHowSubscribe => 'How do I subscribe to Pro?';

  @override
  String get supportFaqExportData => 'Can I export my data?';

  @override
  String get supportFaqCancelAccount => 'Cancel or delete account';

  @override
  String get supportFaqTalkHuman => 'Talk to a human';

  @override
  String get supportContactEmail => 'Email';

  @override
  String get supportContactTelegram => 'Telegram';

  @override
  String get supportContactWhatsapp => 'WhatsApp';

  @override
  String get supportFooterSla => 'We respond within 24h';

  @override
  String get supportWhatsapp => 'WhatsApp';

  @override
  String get supportEmail => 'Email';

  @override
  String get supportInApp => 'Message us here';

  @override
  String get supportCategoryLabel => 'Category';

  @override
  String get supportCategoryBug => 'Bug';

  @override
  String get supportCategoryPayment => 'Payment issue';

  @override
  String get supportCategoryQuestion => 'Question';

  @override
  String get supportCategoryFeature => 'Feature request';

  @override
  String get supportCategoryOther => 'Other';

  @override
  String get supportMessagePlaceholder => 'Describe your problem...';

  @override
  String get supportEmailLabel => 'Email (optional)';

  @override
  String get supportSend => 'Send';

  @override
  String get supportSentSuccess => 'Message sent! We\'ll reply soon.';

  @override
  String get supportError => 'Something went wrong. Try again.';

  @override
  String get supportErrorTooShort => 'Please write at least 10 characters.';

  @override
  String get supportErrorTooLong => 'Maximum 2000 characters.';

  @override
  String get supportPrivacyNotice => 'Your message is stored securely.';

  @override
  String get reviewThisContract => 'Peržiūrėti sutartį';

  @override
  String get contractReviews => 'Sutarčių peržiūros';

  @override
  String get contractReviewsFreeFeature =>
      '1 sutarties peržiūra (visam laikui)';

  @override
  String get contractReviewsCounselFeature => '5 sutarčių peržiūros per mėnesį';

  @override
  String get contractReviewsProFeature => '20 sutarčių peržiūrų per mėnesį';

  @override
  String contractReviewsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Šį mėnesį liko $count sutarčių peržiūrų',
      many: 'Šį mėnesį liko $count sutarčių peržiūros',
      few: 'Šį mėnesį liko $count sutarčių peržiūros',
      one: 'Šį mėnesį liko $count sutarties peržiūra',
      zero: 'Šį mėnesį sutarčių peržiūrų nebeliko',
    );
    return '$_temp0';
  }

  @override
  String get contractReviewsExhausted => 'Šį mėnesį sutarčių peržiūrų neliko';

  @override
  String get contractReviewsFreeTrialLeft =>
      'Nemokamas bandymas: 1 sutarties peržiūra';

  @override
  String get contractReviewsFreeTrialUsed =>
      'Nemokamas bandymas išnaudotas — atnaujinkite';

  @override
  String get contractReviewsUpgradeTitle => 'Sutarčių peržiūros išnaudotos';

  @override
  String get contractReviewsUpgradeBodyFree =>
      'Išnaudojote nemokamą sutarties peržiūrą. Atnaujinkite, kad gautumėte mėnesines peržiūras.';

  @override
  String contractReviewsUpgradeBodyPaid(int used, int cap) {
    return 'Šį mėnesį panaudojote $used iš $cap peržiūrų. Atnaujinkite didesniam mėnesio limitui.';
  }

  @override
  String get contractReviewsUpgradeCounselCta =>
      'Atnaujinkite į Counsel (€19,99/mėn.) — 5 peržiūros';

  @override
  String get contractReviewsUpgradeProCta =>
      'Atnaujinkite į Pro (€29,99/mėn.) — 20 peržiūrų';

  @override
  String get contractReviewsUpgradeToProShort => 'Atnaujinkite į Pro — 20/mėn.';

  @override
  String get notNow => 'Ne dabar';

  @override
  String get referralTitle => 'Pakviesti draugų';

  @override
  String get referralSubtitle =>
      'Gauk nemokamą mėnesį. Padovanok nemokamą mėnesį.';

  @override
  String get referralYourLink => 'JŪSŲ NUORODA';

  @override
  String get referralCopyLink => 'Kopijuoti nuorodą';

  @override
  String get referralShare => 'Dalintis';

  @override
  String get referralLinkCopied => 'Nuoroda nukopijuota';

  @override
  String get referralStatsInvited => 'Pakviesta';

  @override
  String get referralStatsConverted => 'Prisijungė';

  @override
  String get referralStatsEarned => 'Nemokami mėnesiai';

  @override
  String get referralShareWhatsApp => 'Dalintis WhatsApp';

  @override
  String get referralShareTelegram => 'Dalintis Telegram';

  @override
  String get referralShareEmail => 'Dalintis el. paštu';

  @override
  String get referralEmailSubject =>
      'Išbandyk Advocat — savo DI teisės asistentą';

  @override
  String get referralLoadError =>
      'Nepavyko įkelti duomenų. Tempkite žemyn atnaujinti.';

  @override
  String get referralRetry => 'Bandyti dar kartą';

  @override
  String get referralSettingsTile => 'Pakviesti draugų';

  @override
  String get referralAfterReviewCta =>
      'Patiko? Pakviesk draugą — abu gausite nemokamą mėnesį.';

  @override
  String get referralAntiFraud => 'Maximum 12 successful referrals per year.';

  @override
  String get referralEmpty =>
      'No referrals yet. Send your link to start earning.';

  @override
  String get referralRecentActivity => 'Recent activity';

  @override
  String referralActivityInvited(String when) {
    return 'Invited $when';
  }

  @override
  String referralActivityActivated(String when) {
    return 'activated $when';
  }

  @override
  String get referralActivityPending => 'not activated yet';

  @override
  String referralStatsInvitedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count friends',
      one: '1 friend',
      zero: 'no friends yet',
    );
    return 'You\'ve invited $_temp0';
  }

  @override
  String referralStatsConvertedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count have activated',
      one: '1 has activated',
      zero: 'none activated yet',
    );
    return '$_temp0';
  }

  @override
  String referralStatsEarnedCount(int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months free months',
      one: '1 free month',
      zero: 'nothing yet',
    );
    return 'Your bonus: $_temp0';
  }

  @override
  String get referralNudgeMessage =>
      'Like Advocat? Invite a friend — both get a free month.';

  @override
  String get referralNudgeAction => 'Invite';

  @override
  String get referralLandingTitle => 'You\'ve been invited to Advocat';

  @override
  String referralLandingSubtitle(String inviterName) {
    return '$inviterName invited you — claim your free first month.';
  }

  @override
  String get referralLandingSubtitleGeneric =>
      'Claim your free first month of Advocat Pro.';

  @override
  String get referralLandingCta => 'Activate free month & sign up';

  @override
  String get referralLandingCtaSecondary => 'Or learn more about Advocat';

  @override
  String get referralLandingFallback =>
      'This link has expired — but you can still try Advocat free.';

  @override
  String get referralLandingBenefits =>
      '17 languages • Real Estonian, Finnish and EU law • 24/7 — no waiting';

  @override
  String get checkerProTagline => 'Profesionalūs tikrinimo įrankiai';

  @override
  String get checkerDataSource => 'Duomenys iš oficialių registrų';

  @override
  String get companyCheckerHint => 'Įmonės pavadinimas arba reg. numeris';

  @override
  String get companyCheckerPriceChip =>
      '€2.99 už patikrinimą  •  Įtraukta į Pro';

  @override
  String get companyCheckerEmptyState =>
      'Įveskite įmonės pavadinimą arba registracijos\nnumerį, kad gautumėte pilną ataskaitą';

  @override
  String get aiMemoryTitle => 'DI atmintis';

  @override
  String get aiMemorySubtitle =>
      'Peržiūrėkite ir ištrinkite, ką DI prisimena apie jus';

  @override
  String get bookLawyerCallTitle => 'Užsisakykite pokalbį su teisininku';

  @override
  String get bookLawyerCallComingSoonTitle =>
      'Pokalbiai su tikru teisininku — netrukus';

  @override
  String get bookLawyerCallComingSoonBody =>
      'Pro ir Premium paketai apima 15 minučių pokalbius su partneriniu teisininku (Pro – 1/ketv., Premium – 2/ketv.). Užbaigiame Estijos individualių praktikuotojų tinklą ir atsiųsime el. laišką, kai užsakymas atsivers.';

  @override
  String bookLawyerCallQuotaAvailable(int remaining, int total) {
    return 'Šį ketvirtį jums liko $remaining iš $total skambučių.';
  }

  @override
  String get bookLawyerCallQuotaExhausted => 'Ketvirčio kvota išnaudota.';

  @override
  String get bookLawyerCallQuotaBodyAvailable =>
      'Pro paketas apima 1 skambutį per ketvirtį, Premium – 2. Skambučiai trunka 15 minučių per Google Meet.';

  @override
  String get bookLawyerCallQuotaBodyExhausted =>
      'Jūsų kvota atsinaujins kito ketvirčio pirmąją dieną. Reikia kalbėtis greičiau? Pereikite į Premium ir gausite papildomą skambutį.';

  @override
  String get severityCritical => 'KRITIŠKA';

  @override
  String get severityHigh => 'AUKŠTA';

  @override
  String get severityMedium => 'VIDUTINIS';

  @override
  String get severityLow => 'ŽEMA';

  @override
  String get deadlineRequiredFields =>
      'Pavadinimas ir termino data yra privalomi';

  @override
  String get acceptTermsRequired => 'Sutikite su Paslaugos teikimo sąlygomis';

  @override
  String get chatLegalCouncilTooltip => 'Teisinė konsultacija (4 ekspertai)';

  @override
  String get attachFileTooltip => 'Pridėti failą';

  @override
  String get sendMessage => 'Siųsti pranešimą';

  @override
  String get stopGenerating => 'Sustabdyti generavimą';

  @override
  String get showPassword => 'Rodyti slaptažodį';

  @override
  String get hidePassword => 'Slėpti slaptažodį';

  @override
  String get decreaseDependents => 'Sumažinti';

  @override
  String get increaseDependents => 'Padidinti';

  @override
  String get sensitiveConsentTitle => 'Sensitive data consent';

  @override
  String get sensitiveConsentBody =>
      'Documents you\'re about to upload may contain special-category personal data under GDPR Art. 9 — such as health records, criminal records, biometric data, or information about your racial origin, religion, or sexual orientation.\n\nWe process this data only to provide you with AI legal assistance, store it encrypted in your private account, and never use it to train models. You can withdraw consent and delete the data at any time from Settings.\n\nBy accepting, you give explicit consent under Art. 9(2)(a) GDPR to process special-category data for this purpose.';

  @override
  String get sensitiveConsentExplicitCheckbox =>
      'I give explicit consent to process special-category data (Art. 9(2)(a) GDPR).';

  @override
  String get sensitiveConsentRightToShareCheckbox =>
      'I confirm I have the right to share this data (the data is mine, or I have informed/lawful basis to share third-party data).';

  @override
  String get sensitiveConsentViewCategories =>
      'View what counts as sensitive →';

  @override
  String get sensitiveConsentWithdrawAction =>
      'Withdraw sensitive data consent';

  @override
  String get privacyAndData => 'PRIVACY & DATA';

  @override
  String get exportMyDataSubtitle =>
      'Download a copy of all your personal data (GDPR Art. 15).';

  @override
  String get withdrawSensitiveConsent => 'Sensitive data consent';

  @override
  String get withdrawSensitiveConsentSubtitle =>
      'Manage or withdraw consent to process special-category data (GDPR Art. 9(2)(a)).';

  @override
  String get dataProcessingAgreement => 'Data Processing Agreement';

  @override
  String get exportingData => 'Exporting your data…';

  @override
  String get exportComplete => 'Data export ready — saved to your device.';

  @override
  String get exportFailed =>
      'Export failed. Please try again or contact support.';

  @override
  String get quotaExhaustedTitle => 'Free message limit reached';

  @override
  String quotaExhaustedBody(int count) {
    return 'You\'ve used all $count free messages. Upgrade to Advocat Counsel for €19.99/month and get unlimited AI legal consultations.';
  }

  @override
  String get quotaExhaustedLater => 'Later';

  @override
  String get quotaExhaustedUpgrade => 'Advocat Counsel — €19.99/mo';

  @override
  String quotaCtaMessage(int count) {
    return 'You\'ve used all $count free messages. Upgrade to Advocat Counsel for €19.99/month.';
  }

  @override
  String get quotaCtaButton => 'Get Advocat Counsel — €19.99/mo';

  @override
  String get aiErrorQuota =>
      'Free message limit reached. Subscribe to continue using AI.';

  @override
  String get aiErrorAuth =>
      'Sign-in required to use the AI. Please register or log in.';

  @override
  String get aiErrorGeneric =>
      'Temporary AI error. Please try again in a minute. If it persists, contact support.';

  @override
  String get tooltipShareCase => 'Share case summary';

  @override
  String get tooltipMuteVoice => 'Mute voice';

  @override
  String get tooltipUnmuteVoice => 'Unmute voice';

  @override
  String get tooltipAttachDoc => 'Attach document';

  @override
  String get aiTypingHint => 'AI…';

  @override
  String get error404Title => 'Page not found';

  @override
  String error404Body(String path) {
    return 'We couldn\'t find: $path';
  }

  @override
  String get goToHome => 'Go to home';

  @override
  String get emailAlreadyRegistered =>
      'This email is already registered. Want to sign in?';

  @override
  String get actionSignIn => 'Sign in';

  @override
  String get actionUndo => 'Undo';

  @override
  String get intakeUrgentOpened => 'Chat opened — your draft is saved.';

  @override
  String get panicCoachmark => 'Hold for emergency help.';

  @override
  String get panicTitle => 'What do you need right now?';

  @override
  String get panicCardReadAloud => 'Read aloud to the officer';

  @override
  String get panicCardRecord => 'Record this conversation';

  @override
  String get panicCardCall => 'Call a lawyer';

  @override
  String get panicCardAi => 'Talk to Advocat now';

  @override
  String get panicClose => 'Close';

  @override
  String get panicBadgeV2 => 'V2';

  @override
  String get panicRecordV1Title => 'Coming in V2';

  @override
  String get panicRecordV1Body =>
      'The recording feature is being legally validated for Estonia and will ship in V2. For now, use your phone\'s built-in voice recorder.';

  @override
  String get panicCallFallbackBody =>
      'Email kiire@advocat.ee with a short description and we will call you back.';

  @override
  String get consiliumHeader => 'Teisininkų konsiliumas';

  @override
  String consiliumProgress(int count, int total) {
    return '$count iš $total parengta';
  }

  @override
  String get consiliumStarting => 'Teisininkai analizuoja jūsų bylą…';

  @override
  String get consiliumDisagreement => 'Ekspertai nesutaria';

  @override
  String get consiliumSynthesizing => 'Rengiama rekomendacija…';

  @override
  String consiliumDone(int totalRoles) {
    return 'Konsiliumas baigtas · $totalRoles ekspertai';
  }

  @override
  String get consiliumPositionPush => 'Ginčyti';

  @override
  String get consiliumPositionSettle => 'Susitarti';

  @override
  String get consiliumPositionInvestigate => 'Tirti';

  @override
  String get consiliumPositionOutOfScope => 'Ne kompetencijoje';

  @override
  String get consiliumConfidence => 'Patikimumas';

  @override
  String get consiliumKeyCitation => 'Pagrindinė nuoroda';

  @override
  String get consiliumAdversarialRound => 'Prieštaringas turas';

  @override
  String get consiliumViewFullOpinion => 'Žiūrėti visą išvadą';

  @override
  String consiliumExpertsAgreed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ekspertų sutinka',
      many: '$count eksperto sutinka',
      few: '$count ekspertai sutinka',
      one: '$count ekspertas sutinka',
    );
    return '$_temp0';
  }

  @override
  String consiliumExpertsDisagree(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ekspertų nesutinka',
      many: '$count eksperto nesutinka',
      few: '$count ekspertai nesutinka',
      one: '$count ekspertas nesutinka',
    );
    return '$_temp0';
  }

  @override
  String get consiliumDisclaimer =>
      'DI agentai, ne žmonės teisininkai. Svarbius sprendimus patikrinkite su licencijuotu advokatu.';

  @override
  String get softCaseShellBanner =>
      'We created \"Untitled case\" to track this. Tap to rename.';

  @override
  String get softCaseShellBannerCta => 'Rename';

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
}
