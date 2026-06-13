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
  String get aiAnalyzing => 'AI analizuoja';

  @override
  String get speakIntoMicHint =>
      'Speak into the microphone. Make sure microphone access is enabled.';

  @override
  String get aiErrorRateLimit =>
      'Paslauga laikinai perkrauta. Bandykite dar kartą po 1–2 minučių.';

  @override
  String get aiErrorOverload =>
      'DI šiuo metu užimtas, bandykite dar kartą po minutės.';

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
  String get appleComingSoon => 'Netrukus';

  @override
  String get appleComingSoonMessage =>
      'Prisijungimas su Apple netrukus bus prieinamas. Tęskite naudodami Google arba el. paštą.';

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
  String get dpaTitle => 'Duomenų tvarkymo sutartis';

  @override
  String get dpaCheckoutGateTitle => 'Prieš atnaujinant planą';

  @override
  String get dpaCheckoutGateBody =>
      'ES teisė (BDAR 28 str.) reikalauja pasirašyti duomenų tvarkymo sutartį su kiekvienu mokančiu klientu. Peržiūrėkite ir sutikite.';

  @override
  String get dpaViewLink => 'Peržiūrėti duomenų tvarkymo sutartį';

  @override
  String get dpaCheckboxLabel =>
      'Perskaičiau ir sutinku su duomenų tvarkymo sutartimi (v1.0).';

  @override
  String get dpaCancel => 'Atšaukti';

  @override
  String get dpaAcceptAndContinue => 'Sutikti ir tęsti';

  @override
  String get dpaOpenHint =>
      'Atverkite DTS bent kartą, kad aktyvintumėte mygtuką „Sutikti“.';

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
  String get noEventsForFilter => 'Nė vienas įvykis neatitinka šio filtro';

  @override
  String get timelineFilterAll => 'Visi';

  @override
  String get timelineFilterEmails => 'El. laiškai';

  @override
  String get timelineFilterConsilium => 'DI sprendimai';

  @override
  String get timelineFilterDeadlines => 'Terminai';

  @override
  String get timelineFilterNotes => 'Pastabos';

  @override
  String get timelineEventEmailIn => 'Gautas el. laiškas';

  @override
  String get timelineEventEmailOut => 'Išsiųstas el. laiškas';

  @override
  String get timelineEventConsiliumDecision => 'DI sprendimas';

  @override
  String get timelineEventDeadlineSet => 'Terminas';

  @override
  String get timelineEventDocUploaded => 'Dokumentas';

  @override
  String get timelineEventPhaseChange => 'Etapo pakeitimas';

  @override
  String get timelineEventManualNote => 'Pastaba';

  @override
  String get timelineJustNow => 'Ką tik';

  @override
  String timelineMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'prieš $count minučių',
      many: 'prieš $count minutės',
      few: 'prieš $count minutes',
      one: 'prieš $count minutę',
    );
    return '$_temp0';
  }

  @override
  String timelineHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'prieš $count valandų',
      many: 'prieš $count valandos',
      few: 'prieš $count valandas',
      one: 'prieš $count valandą',
    );
    return '$_temp0';
  }

  @override
  String timelineDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'prieš $count dienų',
      many: 'prieš $count dienos',
      few: 'prieš $count dienas',
      one: 'prieš $count dieną',
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
      'Advocat v2.1 skaito jūsų pašto dėžutę, kad parengtų atsakymus; galite atšaukti bet kada. Iš naujo prijunkite Gmail, kad įjungtumėte aktyvų rūšiavimą.';

  @override
  String get gmailReauthBannerCta => 'Iš naujo autorizuoti';

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
      'Sveiki! Aš esu Advocat — jūsų AI teisinis padėjėjas. Teikiu teisinę informaciją, o ne teisines konsultacijas. Kokiu teisiniu klausimu galiu padėti?';

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
      'Advocat — tai AI teikiama teisinė informacija, o ne teisinė konsultacija. Prieš imdamiesi veiksmų pasitikrinkite pas licencijuotą teisininką.';

  @override
  String get aiDisclaimerFullTitle => 'Svarbu: kaip veikia Advocat';

  @override
  String get aiDisclaimerFullBody =>
      'Advocat — tai dirbtinio intelekto įrankis, teikiantis teisinę informaciją, o ne teisines konsultacijas. Pagal ES dirbtinio intelekto aktą (50 str.) privalome aiškiai pasakyti: bendraujate su AI, o ne su žmogumi teisininku.\n\nAdvocat nėra advokatų kontora. Mes nesame licencijuoti advokatai pagal Estijos Advokatuuriseadus ar Suomijos Asianajajalaki, o jūsų pokalbiams su šiuo įrankiu netaikoma advokato ir kliento bendravimo apsauga. Prieš remdamiesi bet kuriuo atsakymu — teikdami skundą, pasirašydami sutartį ar veikdami iki termino — pasitikrinkite pas licencijuotą teisininką savo jurisdikcijoje.';

  @override
  String get aiDisclaimerExpand => 'Sužinoti daugiau';

  @override
  String get aiDisclaimerDismiss => 'Gerai, supratau';

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
      'Išanalizuosiu situaciją, patikrinsiu dokumentus, rasiu klaidas ir pasiūlysiu, ką daryti.';

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
      'AI padėjėjas teikia teisinę informaciją, o ne teisines konsultacijas. Visada pasitarkite su kvalifikuotu teisininku.';

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
  String get upgradeBannerTitle =>
      'Atnaujinkite planą neribotoms konsultacijoms';

  @override
  String get upgradeBannerCta => 'Atnaujinti';

  @override
  String get paymentSuccessTitle => 'Mokėjimas sėkmingas';

  @override
  String get paymentSuccessBody => 'Jūsų prenumerata dabar aktyvi.';

  @override
  String get commonOk => 'Gerai';

  @override
  String get feedbackThumbsUpLabel => 'Naudinga';

  @override
  String get feedbackThumbsDownLabel => 'Nenaudinga';

  @override
  String get feedbackCommentPrompt => 'Kas buvo ne taip?';

  @override
  String get feedbackSend => 'Siųsti';

  @override
  String get feedbackCancel => 'Atšaukti';

  @override
  String get reasoningPillIdle => 'Mąstoma…';

  @override
  String get reasoningPillSearchingLaw => 'Ieškoma Estijos teisės aktų…';

  @override
  String get reasoningPillSearchingWeb => 'Ieškoma internete…';

  @override
  String get reasoningPillCheckingCompany => 'Tikrinamas įmonių registras…';

  @override
  String get reasoningPillCheckingVehicle =>
      'Tikrinamas transporto priemonių registras…';

  @override
  String get reasoningPillReadingDocument => 'Skaitomas jūsų dokumentas…';

  @override
  String get reasoningPillDrafting => 'Rengiamas dokumentas…';

  @override
  String get reasoningPillPreparingEmail => 'Ruošiamas el. laiškas…';

  @override
  String get reasoningPillFindingLawyer => 'Ieškoma advokatų…';

  @override
  String get reasoningPillThinking => 'Analizuojama jūsų byla…';

  @override
  String get reasoningPillFinalising => 'Rengiamas atsakymas…';

  @override
  String reasoningCollapsedFormat(int sec, int sources) {
    return 'Mąstyta $sec s · $sources šaltinių';
  }

  @override
  String get reasoningExpandHint => 'bakstelėkite, kad pamatytumėte žingsnius';

  @override
  String get caseFileTitle => 'Bylos byla';

  @override
  String get caseFileTimeline => 'Įvykių juosta';

  @override
  String get caseFileParties => 'Šalys';

  @override
  String get caseFileDeadlines => 'Terminai';

  @override
  String get caseFileExportPdf => 'Atsisiųsti bylą (PDF)';

  @override
  String get caseFileEmpty =>
      'Pasikalbėkite su DI apie savo bylą — įvykių juosta susikurs pati.';

  @override
  String get caseFileDisclaimer =>
      'Ši byla automatiškai sudaryta iš jūsų pokalbio. Tai nėra teisinė konsultacija.';

  @override
  String get caseFileTabLabel => 'Byla';

  @override
  String get refresh => 'Atnaujinti';

  @override
  String get demoLimitReached =>
      'Pasiektas demonstracinės versijos limitas. Užsiregistruokite nemokamai, kad tęstumėte.';

  @override
  String get demoLimitSignUpCta => 'Užsiregistruoti';

  @override
  String freeQuotaExhausted(int count) {
    return 'Šį mėnesį panaudojote visus $count nemokamų pranešimų.';
  }

  @override
  String get upgradeForUnlimited => 'Atnaujinkite į Pro neribotam naudojimui';

  @override
  String get upgradeCta => 'Atnaujinti';

  @override
  String get rateLimitTryAgain =>
      'Siunčiate per greitai. Bandykite dar kartą po kelių sekundžių.';

  @override
  String get quickProfilePrompt =>
      'Kad galėčiau padėti tiksliau, koks jūsų teisinis statusas: ar esate Estijos pilietis, ES pilietis iš kitos šalies, ar turite leidimą gyventi?';

  @override
  String get quickProfileChipEstonianCitizen => 'Estijos pilietis';

  @override
  String get quickProfileChipEuCitizen => 'ES pilietis (kita šalis)';

  @override
  String get quickProfileChipResidencePermit => 'Leidimas gyventi';

  @override
  String get quickProfileSkipBtn => 'Praleisti';

  @override
  String get quickProfileSavedAck => 'Supratau. Koks jūsų klausimas?';

  @override
  String get caseTitleLabel => 'Bylos pavadinimas';

  @override
  String get jurisdictionLabel => 'Jurisdikcija';

  @override
  String get caseTypeLabel => 'Bylos tipas';

  @override
  String get caseLanguageLabel => 'Kalba';

  @override
  String get caseNumbersSection => 'Bylos numeriai';

  @override
  String get partiesSection => 'Šalys';

  @override
  String get authoritiesSection => 'Institucijos';

  @override
  String get timelineSection => 'Įvykių juosta';

  @override
  String get openQuestionsSection => 'Atviri klausimai';

  @override
  String get nextActionsSection => 'Tolesni veiksmai';

  @override
  String get summarySection => 'Santrauka';

  @override
  String get addRow => 'Pridėti eilutę';

  @override
  String get removeRow => 'Pašalinti';

  @override
  String get archiveCase => 'Archyvuoti bylą';

  @override
  String get closeCase => 'Uždaryti bylą';

  @override
  String get continueChatAboutCase => 'Tęsti pokalbį apie šią bylą';

  @override
  String get linkChatToCase => 'Susieti su byla';

  @override
  String get clearActiveCase => 'Išvalyti aktyvią bylą';

  @override
  String get caseSavedAck => 'Byla išsaugota';

  @override
  String get caseArchivedAck => 'Byla archyvuota';

  @override
  String get intakeStep1Title => 'Kur yra byla?';

  @override
  String get intakeStep1Subtitle =>
      'Šalis ir institucija, su kuria turite reikalų.';

  @override
  String get intakeJurisdictionLabel => 'Šalis / jurisdikcija';

  @override
  String get intakeAuthorityLabel => 'Institucijos tipas';

  @override
  String get intakeAuthorityNameLabel => 'Institucijos pavadinimas (nebūtina)';

  @override
  String get intakeAuthorityPolice => 'Policija';

  @override
  String get intakeAuthorityCourt => 'Teismas';

  @override
  String get intakeAuthoritySocial => 'Socialinės tarnybos';

  @override
  String get intakeAuthorityEmployer => 'Darbdavys';

  @override
  String get intakeAuthorityLandlord => 'Nuomotojas';

  @override
  String get intakeAuthorityOpposingParty => 'Priešinga šalis';

  @override
  String get intakeAuthorityOther => 'Kita';

  @override
  String get intakeStep2Title => 'Kokio tipo byla?';

  @override
  String get intakeStep2Subtitle =>
      'Pasirinkite artimiausią tipą — vėliau galėsite patikslinti.';

  @override
  String get intakeCaseTypeCriminal => 'Baudžiamoji';

  @override
  String get intakeCaseTypeCivil => 'Civilinė';

  @override
  String get intakeCaseTypeFamily => 'Šeimos';

  @override
  String get intakeCaseTypeAdmin => 'Administracinė';

  @override
  String get intakeCaseTypeImmigration => 'Imigracijos';

  @override
  String get intakeCaseTypeLabor => 'Darbo';

  @override
  String get intakeCaseTypeConsumer => 'Vartotojų';

  @override
  String get intakeCaseTypeInheritance => 'Paveldėjimo';

  @override
  String get intakeCaseTypeOther => 'Kita';

  @override
  String get intakeStep3Title => 'Kas dalyvauja?';

  @override
  String get intakeStep3Subtitle => 'Jūsų vaidmuo ir kita šalis.';

  @override
  String get intakeRoleLabel => 'Jūsų vaidmuo';

  @override
  String get intakeRolePlaintiff => 'Ieškovas';

  @override
  String get intakeRoleDefendant => 'Atsakovas';

  @override
  String get intakeRoleVictim => 'Nukentėjusysis';

  @override
  String get intakeRoleAccused => 'Kaltinamasis';

  @override
  String get intakeRoleWitness => 'Liudytojas';

  @override
  String get intakeRoleFamily => 'Šeimos narys';

  @override
  String get intakeRoleOther => 'Kita';

  @override
  String get intakeOpposingSideLabel => 'Priešinga šalis (nebūtina)';

  @override
  String get intakeWitnessesLabel => 'Liudytojai (nebūtina)';

  @override
  String get intakeAddWitness => 'Pridėti liudytoją';

  @override
  String get intakeWitnessHint => 'Vardas arba kontaktas';

  @override
  String get intakeStep4Title => 'Numeriai ir datos';

  @override
  String get intakeStep4Subtitle =>
      'Įveskite tai, ką turite. Praleiskite, ko neturite.';

  @override
  String get intakeCaseNumberLabel => 'Bylos numeris (nebūtina)';

  @override
  String get intakeIncidentDateLabel => 'Įvykio data (nebūtina)';

  @override
  String get intakeIncidentDatePick => 'Pasirinkti datą';

  @override
  String get intakeDeadlinesLabel => 'Žinomi terminai';

  @override
  String get intakeAddDeadline => 'Pridėti terminą';

  @override
  String get intakeDeadlineWhatHint => 'Kas';

  @override
  String get intakeStep5Title => 'Dokumentai';

  @override
  String get intakeStep5Subtitle =>
      'Įkelkite viską, kas svarbu. Mes tai perskaitysime.';

  @override
  String get intakeUploadDocsLabel => 'Įkelti dokumentus';

  @override
  String get intakeSkipDocs => 'Praleisti — įkelsiu vėliau';

  @override
  String get intakeNextBtn => 'Toliau';

  @override
  String get intakeBackBtn => 'Atgal';

  @override
  String get intakeFinishBtn => 'Baigti ir atverti pokalbį';

  @override
  String get intakeUrgentBtn => 'Skubu — klausti dabar';

  @override
  String get intakeUrgentDialogTitle => 'Atverti pokalbį dabar?';

  @override
  String get intakeUrgentDialogBody =>
      'Tai, ką įvedėte, išsaugosime kaip bylos juodraštį. Vediklį galėsite baigti bylos puslapyje bet kada.';

  @override
  String get intakeUrgentConfirm => 'Atverti pokalbį';

  @override
  String get intakeUrgentCancel => 'Tęsti pildymą';

  @override
  String get intakePreparingCase => 'Ruošiama jūsų byla…';

  @override
  String get intakeFallbackGreeting =>
      'Matau jūsų bylą. Pasakykite, kas svarbiausia — kartu viską išspręsime.';

  @override
  String get intakeUrgentGreeting =>
      'Matau, kad tai skubu. Užduokite klausimą — likusią informaciją papildysiu eigoje.';

  @override
  String intakeStepIndicator(int current, int total) {
    return '$current žingsnis iš $total';
  }

  @override
  String get intakeFieldRequired => 'Privaloma';

  @override
  String intakeUploadProgress(int done, int total) {
    return 'Įkeliama $done / $total…';
  }

  @override
  String get uplDisclaimerFooter =>
      'Advocat nėra advokatų kontora. Tai informacija, o ne teisinė konsultacija.';

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
    return 'Konsiliumas rekomenduoja $count lygiagrečius veiksmus';
  }

  @override
  String get parallelActionsApproveAll => 'Patvirtinti visus ir siųsti';

  @override
  String parallelActionsApproveSelected(int count, int total) {
    return 'Patvirtinti $count iš $total';
  }

  @override
  String parallelActionsConfirmTitle(int count) {
    return 'Siųsti $count el. laiškus?';
  }

  @override
  String parallelActionsConfirmBody(int count) {
    return 'Advocat išsiųs $count parengtus atsakymus per jūsų prijungtą Gmail. Kiekvienas siunčiamas atskirai — jei vienas nepavyks, kiti vis tiek bus išsiųsti.';
  }

  @override
  String parallelActionsSentToast(int count) {
    return '$count išsiųsta.';
  }

  @override
  String parallelActionsPartialFailureToast(int sent, int failed) {
    return '$sent išsiųsta, $failed nepavyko.';
  }

  @override
  String get parallelActionsKindReply => 'atsakymas';

  @override
  String get parallelActionsKindNew => 'naujas';

  @override
  String get parallelActionsCheckboxSelected => 'Veiksmas pasirinktas';

  @override
  String get parallelActionsCheckboxUnselected => 'Veiksmas nepasirinktas';

  @override
  String parallelActionsCitationCount(int count) {
    return '$count cit.';
  }

  @override
  String parallelActionsRetryFailed(int count) {
    return 'Kartoti nepavykusius ($count)';
  }

  @override
  String get agentApprovalNeedsReviewTitle =>
      'Advocat reikia jūsų patvirtinimo';

  @override
  String get agentApprovalResolvedTitle => 'Veiksmas išspręstas';

  @override
  String get agentApprovalStepsLabel => 'žingsniai';

  @override
  String get agentApprovalApproveButton => 'Patvirtinti ir siųsti';

  @override
  String get agentApprovalDeclineButton => 'Atmesti';

  @override
  String get agentApprovalAttachmentsLabel => 'Priedai';

  @override
  String get agentApprovalSentSummary => 'Išsiųsta jūsų vardu.';

  @override
  String get agentApprovalDeclinedSummary => 'Atmesta — niekas neišsiųsta.';

  @override
  String get agentToolDraftEmailAtt => 'Siųsti el. laišką su priedais';

  @override
  String get agentToolSendEmail => 'Siųsti el. laišką';

  @override
  String get agentToolGeneratePdf => 'Generuoti PDF';

  @override
  String get agentToolApproveSend => 'Siųsti parengtą atsakymą';

  @override
  String get inboxErrorTitle => 'Nepavyko įkelti pašto dėžutės';

  @override
  String get inboxEditDiscardTitle => 'Atmesti neišsaugotus pakeitimus?';

  @override
  String get inboxEditDiscardBody =>
      'Turite neišsaugotų šio juodraščio pakeitimų. Grįžus atgal jie bus atmesti.';

  @override
  String get inboxEditKeepEditing => 'Tęsti redagavimą';

  @override
  String get inboxEditDiscard => 'Atmesti';

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
  String get plannerSettingsTitle => 'Trijų etapų teisinis samprotavimas';

  @override
  String get plannerSettingsSubtitle =>
      'Planas → atsakymas → kritika. Lėčiau, bet kruopščiau.';

  @override
  String get plannerSettingsProBadge => 'Pro';

  @override
  String get plannerSettingsProDescription => 'Prieinama su Pro planu';

  @override
  String get plannerTrailHeaderPlan => 'Planas';

  @override
  String get plannerTrailHeaderCritique => 'Kritika';

  @override
  String get plannerTrailSubQuestions => 'Papildomi klausimai';

  @override
  String get plannerTrailCounterArgs => 'Kontrargumentai';

  @override
  String get plannerTrailEvidenceGaps => 'Įrodymų spragos';

  @override
  String get plannerTrailMaterialGapTrue => 'Aptikta esminė spraga';

  @override
  String get plannerTrailRegeneratedBadge => 'Sugeneruota iš naujo kartą';

  @override
  String get plannerTrailEmpty => 'nėra elementų';

  @override
  String get supportTitle => 'Pagalba';

  @override
  String get supportSubtitle => 'Paprastai atsakome per 1–2 valandas.';

  @override
  String get supportSearchPlaceholder => 'Ieškoti pagalbos…';

  @override
  String get supportStatusAllOk => 'Visos sistemos veikia normaliai';

  @override
  String get supportFaqWhatIs => 'Kas yra Advocat?';

  @override
  String get supportFaqHowSubscribe => 'Kaip užsisakyti Pro?';

  @override
  String get supportFaqExportData => 'Ar galiu eksportuoti savo duomenis?';

  @override
  String get supportFaqCancelAccount => 'Atšaukti arba ištrinti paskyrą';

  @override
  String get supportFaqTalkHuman => 'Susisiekti su žmogumi';

  @override
  String get supportContactEmail => 'El. paštas';

  @override
  String get supportContactTelegram => 'Telegram';

  @override
  String get supportContactWhatsapp => 'WhatsApp';

  @override
  String get supportFooterSla => 'Atsakome per 24 val.';

  @override
  String get supportWhatsapp => 'WhatsApp';

  @override
  String get supportEmail => 'El. paštas';

  @override
  String get supportInApp => 'Parašykite mums čia';

  @override
  String get supportCategoryLabel => 'Kategorija';

  @override
  String get supportCategoryBug => 'Klaida';

  @override
  String get supportCategoryPayment => 'Mokėjimo problema';

  @override
  String get supportCategoryQuestion => 'Klausimas';

  @override
  String get supportCategoryFeature => 'Funkcijos pageidavimas';

  @override
  String get supportCategoryOther => 'Kita';

  @override
  String get supportMessagePlaceholder => 'Aprašykite savo problemą...';

  @override
  String get supportEmailLabel => 'El. paštas (nebūtina)';

  @override
  String get supportSend => 'Siųsti';

  @override
  String get supportSentSuccess => 'Pranešimas išsiųstas! Netrukus atsakysime.';

  @override
  String get supportError => 'Kažkas nepavyko. Bandykite dar kartą.';

  @override
  String get supportErrorTooShort => 'Parašykite bent 10 simbolių.';

  @override
  String get supportErrorTooLong => 'Daugiausia 2000 simbolių.';

  @override
  String get supportPrivacyNotice => 'Jūsų pranešimas saugomas saugiai.';

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
  String get referralAntiFraud =>
      'Daugiausia 12 sėkmingų rekomendacijų per metus.';

  @override
  String get referralEmpty =>
      'Rekomendacijų dar nėra. Išsiųskite savo nuorodą, kad pradėtumėte uždirbti.';

  @override
  String get referralRecentActivity => 'Naujausia veikla';

  @override
  String referralActivityInvited(String when) {
    return 'Pakviesta $when';
  }

  @override
  String referralActivityActivated(String when) {
    return 'aktyvuota $when';
  }

  @override
  String get referralActivityPending => 'dar neaktyvuota';

  @override
  String referralStatsInvitedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count draugų',
      many: '$count draugo',
      few: '$count draugus',
      one: '$count draugą',
      zero: 'dar nė vieno draugo',
    );
    return 'Pakvietėte $_temp0';
  }

  @override
  String referralStatsConvertedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aktyvavo',
      many: '$count aktyvavo',
      few: '$count aktyvavo',
      one: '$count aktyvavo',
      zero: 'dar nė vienas neaktyvavo',
    );
    return '$_temp0';
  }

  @override
  String referralStatsEarnedCount(int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months nemokamų mėnesių',
      many: '$months nemokamo mėnesio',
      few: '$months nemokami mėnesiai',
      one: '$months nemokamas mėnuo',
      zero: 'dar nieko',
    );
    return 'Jūsų premija: $_temp0';
  }

  @override
  String get referralNudgeMessage =>
      'Patinka Advocat? Pakvieskite draugą — abu gausite nemokamą mėnesį.';

  @override
  String get referralNudgeAction => 'Pakviesti';

  @override
  String get referralLandingTitle => 'Esate pakviestas į Advocat';

  @override
  String referralLandingSubtitle(String inviterName) {
    return '$inviterName jus pakvietė — atsiimkite nemokamą pirmąjį mėnesį.';
  }

  @override
  String get referralLandingSubtitleGeneric =>
      'Atsiimkite nemokamą pirmąjį Advocat Pro mėnesį.';

  @override
  String get referralLandingCta =>
      'Aktyvuoti nemokamą mėnesį ir užsiregistruoti';

  @override
  String get referralLandingCtaSecondary =>
      'Arba sužinokite daugiau apie Advocat';

  @override
  String get referralLandingFallback =>
      'Šios nuorodos galiojimas baigėsi — bet vis tiek galite išbandyti Advocat nemokamai.';

  @override
  String get referralLandingBenefits =>
      '17 kalbų • Tikra Estijos, Suomijos ir ES teisė • 24/7 — be laukimo';

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
  String get sensitiveConsentTitle => 'Sutikimas dėl jautrių duomenų';

  @override
  String get sensitiveConsentBody =>
      'Dokumentuose, kuriuos ketinate įkelti, gali būti specialių kategorijų asmens duomenų pagal BDAR 9 str. — pavyzdžiui, sveikatos įrašų, teistumo duomenų, biometrinių duomenų arba informacijos apie jūsų rasinę kilmę, religiją ar seksualinę orientaciją.\n\nŠiuos duomenis tvarkome tik tam, kad suteiktume jums DI teisinę pagalbą, saugome juos užšifruotus jūsų privačioje paskyroje ir niekada nenaudojame jų modeliams mokyti. Sutikimą galite atšaukti ir duomenis ištrinti bet kada Nustatymuose.\n\nSutikdami suteikiate aiškų sutikimą pagal BDAR 9 str. 2 d. a punktą tvarkyti specialių kategorijų duomenis šiuo tikslu.';

  @override
  String get sensitiveConsentExplicitCheckbox =>
      'Suteikiu aiškų sutikimą tvarkyti specialių kategorijų duomenis (BDAR 9 str. 2 d. a p.).';

  @override
  String get sensitiveConsentRightToShareCheckbox =>
      'Patvirtinu, kad turiu teisę dalytis šiais duomenimis (duomenys yra mano arba turiu informuotą / teisėtą pagrindą dalytis trečiųjų šalių duomenimis).';

  @override
  String get sensitiveConsentViewCategories =>
      'Peržiūrėti, kas laikoma jautriais duomenimis →';

  @override
  String get sensitiveConsentWithdrawAction =>
      'Atšaukti sutikimą dėl jautrių duomenų';

  @override
  String get privacyAndData => 'PRIVATUMAS IR DUOMENYS';

  @override
  String get exportMyDataSubtitle =>
      'Atsisiųskite visų savo asmens duomenų kopiją (BDAR 15 str.).';

  @override
  String get withdrawSensitiveConsent => 'Sutikimas dėl jautrių duomenų';

  @override
  String get withdrawSensitiveConsentSubtitle =>
      'Tvarkykite arba atšaukite sutikimą tvarkyti specialių kategorijų duomenis (BDAR 9 str. 2 d. a p.).';

  @override
  String get dataProcessingAgreement => 'Duomenų tvarkymo sutartis';

  @override
  String get exportingData => 'Eksportuojami jūsų duomenys…';

  @override
  String get exportComplete =>
      'Duomenų eksportas paruoštas — išsaugotas jūsų įrenginyje.';

  @override
  String get exportFailed =>
      'Eksportas nepavyko. Bandykite dar kartą arba susisiekite su pagalba.';

  @override
  String get quotaExhaustedTitle => 'Pasiektas nemokamų pranešimų limitas';

  @override
  String quotaExhaustedBody(int count) {
    return 'Panaudojote visus $count nemokamus pranešimus. Atnaujinkite į Advocat Counsel už 19,99 €/mėn. ir gaukite neribotas DI teisines konsultacijas.';
  }

  @override
  String get quotaExhaustedLater => 'Vėliau';

  @override
  String get quotaExhaustedUpgrade => 'Advocat Counsel — 19,99 €/mėn.';

  @override
  String quotaCtaMessage(int count) {
    return 'Panaudojote visus $count nemokamus pranešimus. Atnaujinkite į Advocat Counsel už 19,99 €/mėn.';
  }

  @override
  String get quotaCtaButton => 'Gauti Advocat Counsel — 19,99 €/mėn.';

  @override
  String get aiErrorQuota =>
      'Pasiektas nemokamų pranešimų limitas. Užsiprenumeruokite, kad tęstumėte DI naudojimą.';

  @override
  String get aiErrorAuth =>
      'Norint naudoti DI, reikia prisijungti. Užsiregistruokite arba prisijunkite.';

  @override
  String get aiErrorGeneric =>
      'Laikina DI klaida. Bandykite dar kartą po minutės. Jei kartojasi, susisiekite su pagalba.';

  @override
  String get tooltipShareCase => 'Bendrinti bylos santrauką';

  @override
  String get tooltipMuteVoice => 'Nutildyti balsą';

  @override
  String get tooltipUnmuteVoice => 'Įjungti balsą';

  @override
  String get tooltipAttachDoc => 'Pridėti dokumentą';

  @override
  String get aiTypingHint => 'DI…';

  @override
  String get error404Title => 'Puslapis nerastas';

  @override
  String error404Body(String path) {
    return 'Nepavyko rasti: $path';
  }

  @override
  String get goToHome => 'Eiti į pradžią';

  @override
  String get emailAlreadyRegistered =>
      'Šis el. paštas jau užregistruotas. Norite prisijungti?';

  @override
  String get actionSignIn => 'Prisijungti';

  @override
  String get actionUndo => 'Anuliuoti';

  @override
  String get intakeUrgentOpened =>
      'Pokalbis atvertas — jūsų juodraštis išsaugotas.';

  @override
  String get panicCoachmark => 'Laikykite pagalbai skubos atveju.';

  @override
  String get panicTitle => 'Ko jums reikia dabar?';

  @override
  String get panicCardReadAloud => 'Perskaityti pareigūnui balsu';

  @override
  String get panicCardRecord => 'Įrašyti šį pokalbį';

  @override
  String get panicCardCall => 'Skambinti advokatui';

  @override
  String get panicCardAi => 'Kalbėtis su Advocat dabar';

  @override
  String get panicClose => 'Uždaryti';

  @override
  String get panicBadgeV2 => 'V2';

  @override
  String get panicRecordV1Title => 'Bus V2 versijoje';

  @override
  String get panicRecordV1Body =>
      'Įrašymo funkcija teisiškai tikrinama Estijai ir bus įdiegta V2 versijoje. Kol kas naudokite telefono integruotą balso įrašymo įrenginį.';

  @override
  String get panicCallFallbackBody =>
      'Parašykite el. laišką kiire@advocat.ee su trumpu aprašymu ir mes jums perskambinsime.';

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
      'Sukūrėme „Bylą be pavadinimo“, kad galėtume tai sekti. Bakstelėkite, kad pervadintumėte.';

  @override
  String get softCaseShellBannerCta => 'Pervadinti';

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
  String get chatExamplePrompt1 => 'Padėk atsakyti į baudą';

  @override
  String get chatExamplePrompt2 => 'Peržiūrėk mano nuomos sutartį';

  @override
  String get chatExamplePrompt3 => 'Kokios mano teisės darbe?';

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
  String get contractReviewTitle => 'Sutarties peržiūra';

  @override
  String get contractReviewUploadCta => 'Įkelti sutartį';

  @override
  String get contractReviewQuotaRemaining =>
      'Įkelkite PDF, DOC, DOCX arba TXT formato sutartį ir gaukite AI peržiūrą su įspėjamaisiais ženklais bei derybų patarimais.';

  @override
  String get contractReviewRedFlags => 'Įspėjamieji ženklai';

  @override
  String get contractReviewReviewPoints => 'Peržiūros punktai';

  @override
  String get contractReviewNegotiationTips => 'Derybų patarimai';

  @override
  String get contractReviewSaveToVault => 'Išsaugoti saugykloje';

  @override
  String get contractReviewContinueChat => 'Tęsti pokalbyje';

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
  String get iapPayWithApple => 'Mokėti naudojant Apple';

  @override
  String get iapRestorePurchases => 'Atkurti pirkinius';

  @override
  String get iapPurchaseFailed =>
      'Pirkimas nepavyko. Bandykite dar kartą arba susisiekite su pagalba.';

  @override
  String get iapRestoreSuccess => 'Jūsų prenumerata atkurta.';

  @override
  String get iapRestoreNoActive => 'Atkurtinos aktyvios prenumeratos nerasta.';

  @override
  String get deadlineEuRadarTitle => 'EU deadline radar (preview)';

  @override
  String get deadlineEuRadarSubtitle =>
      'Hypothetical EU procedural deadlines — mock data';

  @override
  String get changePassword => 'Keisti slaptažodį';

  @override
  String get changePasswordSubtitle => 'Atnaujinkite savo paskyros slaptažodį';

  @override
  String get newPasswordTitle => 'Nustatykite naują slaptažodį';

  @override
  String get newPasswordHint =>
      'Įveskite ir patvirtinkite naują paskyros slaptažodį.';

  @override
  String get newPasswordSave => 'Išsaugoti naują slaptažodį';

  @override
  String get newPasswordSuccess =>
      'Slaptažodis atnaujintas. Dabar galite jį naudoti prisijungdami.';

  @override
  String get newPasswordError =>
      'Nepavyko atnaujinti slaptažodžio. Bandykite dar kartą.';

  @override
  String get accessLogTile => 'Access log';

  @override
  String get accessLogTileSubtitle => 'See who and what accessed your data';

  @override
  String get accessLogTitle => 'Access log for my data';

  @override
  String get accessLogIntro =>
      'A transparent, tamper-evident record of every time your data was accessed or processed — including by our AI. You can verify it has not been altered.';

  @override
  String get accessLogEmpty => 'No access events yet.';

  @override
  String get accessLogError =>
      'Could not load your access log. Pull down to retry.';

  @override
  String get accessLogIntegrityOk =>
      'Integrity verified — the log links form an unbroken chain.';

  @override
  String get accessLogIntegrityBroken =>
      'Warning: the log chain is broken. Some entries may have been removed or reordered. Please contact support.';

  @override
  String get accessActionLlmEgress =>
      'Sent to AI for processing (pseudonymized)';

  @override
  String get accessActionAiAnalysis => 'Analyzed by AI';

  @override
  String get accessActionDocumentParse => 'Document parsed';

  @override
  String get accessActionStaffRead => 'Reviewed by a staff member';

  @override
  String get accessActionExport => 'Data exported';

  @override
  String get accessActionEmailTriage => 'Email triaged';

  @override
  String get accessActionDeadlineScan => 'Deadlines scanned';
}
