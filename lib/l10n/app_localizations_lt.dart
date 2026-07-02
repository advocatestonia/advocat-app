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
  String get appearance => 'Išvaizda';

  @override
  String get appearanceSystem => 'Sistemos (auto)';

  @override
  String get appearanceLight => 'Šviesus';

  @override
  String get appearanceDark => 'Tamsus';

  @override
  String get appearanceDescription => 'Pasirinkite, kaip atrodo „Advocat“';

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
      'Kalbėkite į mikrofoną. Įsitikinkite, kad įjungta prieiga prie mikrofono.';

  @override
  String get aiErrorRateLimit =>
      'Paslauga laikinai perkrauta. Bandykite dar kartą po 1–2 minučių.';

  @override
  String get aiErrorOverload =>
      'DI šiuo metu užimtas, bandykite dar kartą po minutės.';

  @override
  String freeLimitReached(int count) {
    return 'Jūs išnaudojote visus $count nemokamus DI pranešimus. Atnaujinkite iki „Legal Counsel“ plano ir gaukite neribotą DI pagalbą!';
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
  String get rateAppComingSoon => 'Netrukus programų parduotuvėse!';

  @override
  String get dataCopiedToClipboard => 'Duomenys nukopijuoti į iškarpinę';

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
  String get fiveAiMessagesTotal => '5 DI pranešimai (visam laikui)';

  @override
  String get hundredAiMessagesDay => '100 DI pranešimų per dieną';

  @override
  String get unlimitedAiMessages => 'Neriboti DI pranešimai';

  @override
  String get voiceInput => 'Balso įvestis';

  @override
  String get strategyRecommendations => 'Strategijos rekomendacijos';

  @override
  String get foundingMemberNote =>
      'Steigėjo narystė: 9,99 €/mėn. pirmuosius 3 mėnesius';

  @override
  String get saveTwentyPercent => 'Sutaupykite 20 %';

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
      'Sutinku, kad mano duomenys būtų tvarkomi DI teisinei pagalbai teikti (privaloma)';

  @override
  String get gdprConsentAnalytics =>
      'Sutinku su analitika, siekiant tobulinti paslaugą (neprivaloma)';

  @override
  String get gdprArt9Intro =>
      'Ši programa tvarko specialių kategorijų asmens duomenis pagal BDAR 9 straipsnį, įskaitant:';

  @override
  String get gdprSpecialLegalCases =>
      'Jūsų teisinės bylos duomenis ir teismo dokumentus';

  @override
  String get gdprSpecialNationality => 'Pilietybę ir imigracijos statusą';

  @override
  String get gdprConsentLegalData =>
      'Sutinku, kad DI tvarkytų mano teisinės bylos duomenis, pilietybę ir imigracijos statusą (privaloma)';

  @override
  String get gdprConsentVoice =>
      'Sutinku, kad būtų tvarkomas balso įrašas (neprivaloma)';

  @override
  String get gdprViewPrivacyPolicy => 'Peržiūrėti privatumo politiką';

  @override
  String get legalInformation => 'Teisinė informacija';

  @override
  String get legalEntityName => 'Vorantis OÜ';

  @override
  String get legalRegistryCode => 'Registro kodas: 17098992';

  @override
  String get legalAddress =>
      'Harju maakond, Talinas, Kesklinna miesto dalis, Tornimäe tn 5, 10145';

  @override
  String get legalEmail => 'El. paštas: support@advocat.ee';

  @override
  String get legalRegistry =>
      'Registruota Estijos komercinio registro (Äriregister) sąraše';

  @override
  String get aiGeneratedDisclaimer => 'Sukurta DI • Ne teisinė konsultacija';

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
      'Aukos teisės, skubi pagalba, apsauginiai orderiai';

  @override
  String get rightCallEmergency =>
      'Bet kokiu skubiu atveju turite teisę skambinti 112 — policijai, greitajai pagalbai, gaisrinei';

  @override
  String get rightVictimProtection =>
      'Kaip auka, turite teisę į apsaugą, paramą ir informaciją apie savo bylą';

  @override
  String get rightRestrainingOrder =>
      'Galite kreiptis dėl apsauginio orderio (lähestymiskielto), kad skriaudėjas laikytųsi atokiau';

  @override
  String get rightVictimInterpreter =>
      'Turite teisę į vertėją visuose teisiniuose procesuose';

  @override
  String get rightMedicalHelp =>
      'Turite teisę į skubią medicininę pagalbą ir sužalojimų fiksavimą dokumentais';

  @override
  String get rightShelter =>
      'Turite teisę į skubią prieglaudą — kreipkitės į prieglaudą ar socialines tarnybas';

  @override
  String get mustReportDanger =>
      'Jei kas nors yra tiesioginiame pavojuje, nedelsdami skambinkite 112';

  @override
  String get mustDocumentInjuries =>
      'Fiksuokite visus sužalojimus — nuotraukos, medicininiai įrašai, rašytinės pastabos';

  @override
  String get domesticActionCallEmergency =>
      'Skambinkite 112, jei esate tiesioginiame pavojuje';

  @override
  String get domesticActionGoToSafe =>
      'Vykite į saugią vietą — prieglaudą, pas draugą, viešą vietą';

  @override
  String get domesticActionDocumentEverything =>
      'Fiksuokite sužalojimus: darykite nuotraukas, gaukite medicininius įrašus';

  @override
  String get domesticActionFilePoliceReport =>
      'Pateikite pranešimą policijai — tai galite padaryti ir vėliau';

  @override
  String get domesticActionContactShelter =>
      'Kreipkitės į prieglaudą ar krizių pagalbos liniją';

  @override
  String get domesticActionApplyRestraining =>
      'Kreipkitės dėl apsauginio orderio per policiją arba teismą';

  @override
  String get domesticFactRestrainingOrder =>
      'Suomijoje apsauginis orderis (lähestymiskielto) gali būti išduotas net ir be baudžiamosios bylos. Jis draudžia asmeniui su jumis susisiekti ar prie jūsų artintis.';

  @override
  String get domesticFactVictimDirective =>
      'Pagal ES Nukentėjusiųjų direktyvą 2012/29/ES turite teisę į pagarbų elgesį, informaciją jums suprantama kalba ir prieigą prie aukų paramos paslaugų — nepriklausomai nuo jūsų gyvenamosios padėties statuso.';

  @override
  String get domesticDeadlinePoliceReport =>
      'Pranešimo policijai pateikimas — griežto termino nėra, tačiau geriau anksčiau, kad išsaugotumėte įrodymus';

  @override
  String get domesticDeadlineRestraining =>
      'Apsauginio orderio prašymą galima pateikti bet kuriuo metu';

  @override
  String get contactEmergency => 'Skubios pagalbos numeris';

  @override
  String get contactShelter => 'Turvakoti (prieglaudos) pagalbos linija';

  @override
  String get contactCrisisHelpline => 'Krizių pagalbos linija (Kriisipuhelin)';

  @override
  String get contactNollaLinja =>
      'Nollalinja — pagalbos linija smurto prieš moteris aukoms';

  @override
  String get inheritance => 'Paveldėjimas';

  @override
  String get inheritanceDesc =>
      'Testamentai, palikimas, įpėdinių teisės, privalomoji dalis, palikimo priėmimas';

  @override
  String get rightInheritanceForced =>
      'Privalomieji įpėdiniai (vaikai, sutuoktinis) turi teisę į privalomąją dalį nepriklausomai nuo testamento';

  @override
  String get rightInheritanceWill =>
      'Jūs turite teisę sudaryti testamentą dėl savo turto — notaro patvirtinti testamentai turi didžiausią teisinę galią';

  @override
  String get rightInheritanceRenounce =>
      'Palikimo galite atsisakyti per 3 mėnesius nuo sužinojimo apie jį';

  @override
  String get rightInheritanceInfo =>
      'Turite teisę gauti informaciją apie palikimą iš bankų ir registrų';

  @override
  String get rightInheritanceDispute =>
      'Nesąžiningą testamentą galite ginčyti teisme per įstatyme nustatytą ieškinio senaties terminą';

  @override
  String get mustFileInheritance =>
      'Kreipkitės dėl palikimo priėmimo pas notarą per protingą terminą';

  @override
  String get mustNotifyHeirs =>
      'Visi žinomi įpėdiniai turi būti informuoti apie palikimo priėmimo procedūrą';

  @override
  String get inheritanceActionGatherDocs =>
      'Surinkite visus dokumentus: mirties liudijimą, testamentą, nuosavybės dokumentus, banko išrašus';

  @override
  String get inheritanceActionContactNotary =>
      'Kreipkitės į notarą dėl palikimo priėmimo bylos pradėjimo';

  @override
  String get inheritanceActionCheckDebts =>
      'Prieš priimdami palikimą patikrinkite, ar palikimo masėje nėra skolų';

  @override
  String get inheritanceActionFileCourt =>
      'Jei testamentas ginčijamas, pateikite ieškinį teismui';

  @override
  String get inheritanceDeadlineRenounce =>
      '3 mėnesiai palikimo atsisakymui nuo sužinojimo apie jį';

  @override
  String get inheritanceDeadlineDispute =>
      'Testamento ginčijimo senaties terminas: priklauso nuo pagrindo';

  @override
  String get inheritanceFactForced =>
      'Estijoje palikuonys ir sutuoktinis turi teisę į privalomąją dalį (1/2 įstatyminės dalies), net jei testamente jie neįtraukti';

  @override
  String get inheritanceFactNotary =>
      'Visos palikimo priėmimo procedūros Estijoje turi vykti per notarą — šio žingsnio praleisti negalima';

  @override
  String get consumerProtection => 'Vartotojų apsauga';

  @override
  String get consumerProtectionDesc =>
      'Sukčiavimas, netinkami gaminiai, grąžinimai, apgaulingi pardavėjai';

  @override
  String get rightReturnOnline =>
      'Turite 14 dienų atsisakyti internetu atlikto pirkinio be priežasties (ES atsisakymo teisė)';

  @override
  String get rightDefectiveProduct =>
      'Jei gaminys turi trūkumų, turite teisę į remontą, keitimą ar pinigų grąžinimą';

  @override
  String get rightClearPricing =>
      'Pardavėjai privalo nurodyti aiškias kainas su visais mokesčiais — paslėptos išlaidos yra neteisėtos';

  @override
  String get rightComplainBoard =>
      'Galite pateikti nemokamą skundą Vartojimo ginčų komisijai';

  @override
  String get rightProtectionFraud =>
      'Jūs esate apsaugoti nuo nesąžiningos komercinės veiklos ir sukčiavimo';

  @override
  String get mustKeepReceipts =>
      'Saugokite visus kvitus, sutartis ir susirašinėjimą su pardavėjais';

  @override
  String get mustActTimely =>
      'Apie trūkumus pardavėjui praneškite per protingą terminą nuo jų pastebėjimo';

  @override
  String get consumerActionKeepEvidence =>
      'Saugokite kvitus, ekrano nuotraukas, el. laiškus ir visus pirkimo įrodymus';

  @override
  String get consumerActionContactSeller =>
      'Pirmiausia kreipkitės į pardavėją — raštu paaiškinkite problemą';

  @override
  String get consumerActionFileComplaint =>
      'Pateikite skundą Vartojimo ginčų komisijai (kuluttajariitalautakunta)';

  @override
  String get consumerActionContactAuthority =>
      'Kreipkitės į Vartotojų konsultavimo tarnybą dėl nemokamos pagalbos';

  @override
  String get consumerActionReportFraud =>
      'Praneškite apie sukčiavimą policijai ir vartotojų teisių gynėjui';

  @override
  String get consumerFactWithdrawal =>
      'Pagal ES Vartotojų teisių direktyvą 2011/83/ES turite 14 dienų atsisakyti bet kurio internetu ar nuotoliniu būdu atlikto pirkimo — be jokių klausimų. Pardavėjas privalo grąžinti pinigus per 14 dienų.';

  @override
  String get consumerFactWarranty =>
      'Suomijoje pardavėjas atsako už gaminio trūkumus protingą laikotarpį (dažnai 2+ metus). Tai nepriklauso nuo gamintojo garantijos.';

  @override
  String get consumerDeadlineWithdrawal =>
      'Internetinio pirkimo atsisakymas — 14 dienų nuo pristatymo';

  @override
  String get consumerDeadlineDefect =>
      'Trūkumo pranešimas pardavėjui — per 2 mėnesius nuo pastebėjimo (rekomenduojama)';

  @override
  String get contactConsumerAdvisory => 'Vartotojų konsultavimo tarnyba';

  @override
  String get contactConsumerOmbudsman =>
      'Vartotojų teisių gynėjas (Kuluttaja-asiamies)';

  @override
  String get contactConsumerDisputesBoardDirect => 'Vartojimo ginčų komisija';

  @override
  String get caseTypeStepLabel => 'Bylos tipas';

  @override
  String get detailsStepLabel => 'Duomenys';

  @override
  String get documentsStepLabel => 'Dokumentai';

  @override
  String get whatTypeOfCase => 'Kokio tipo ši byla?';

  @override
  String get selectCategoryDescription =>
      'Pasirinkite kategoriją, kuri geriausiai atitinka jūsų situaciją.';

  @override
  String get tellUsAboutCase => 'Papasakokite apie savo bylą';

  @override
  String get aiHelpsUnderstand =>
      'Ši informacija padeda mūsų DI geriau suprasti jūsų situaciją.';

  @override
  String get caseTitleHint => 'pvz., leidimo gyventi apskundimas 2026';

  @override
  String get countryJurisdiction => 'Šalis / jurisdikcija';

  @override
  String get selectCountryHint => 'Pasirinkite šalį';

  @override
  String get referenceNumberHint => 'pvz., UMA/12345/2026';

  @override
  String get descriptionOptional => 'Aprašymas (neprivaloma)';

  @override
  String get descriptionHint =>
      'Trumpai apibūdinkite savo situaciją. Kas atsitiko? Koks sprendimas buvo priimtas?';

  @override
  String get uploadFirstDocument => 'Įkelkite pirmąjį dokumentą';

  @override
  String get uploadDocumentDescription =>
      'Įkelkite sprendimo raštą ar bet kurį susijusį dokumentą. Šį žingsnį galite praleisti ir pridėti dokumentus vėliau.';

  @override
  String get tapToUploadFile => 'Palieskite, kad įkeltumėte failą';

  @override
  String get fileSizeLimit => 'PDF, JPG, PNG iki 25 MB';

  @override
  String get addDocumentsLaterHint =>
      'Dokumentus visada galite pridėti vėliau bylos kortelės ekrane.';

  @override
  String get callAI => 'Skambinti DI';

  @override
  String get comingSoon => 'Netrukus';

  @override
  String get encrypted => 'Šifruota';

  @override
  String get typing => 'Rašo…';

  @override
  String get online => 'Prisijungęs';

  @override
  String get chatWelcomeSubtitle =>
      'Išanalizuosiu situaciją, patikrinsiu dokumentus, rasiu klaidas ir pasiūlysiu, ką daryti.';

  @override
  String get tapMicrophoneToSpeak => 'Palieskite mikrofoną, kad kalbėtumėte';

  @override
  String get categoryEssential => 'Svarbiausia';

  @override
  String get categoryPolice => 'Policija';

  @override
  String get categoryWork => 'Darbas';

  @override
  String get categoryHousing => 'Būstas';

  @override
  String get categoryConsumer => 'Vartotojas';

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
  String get freeAidThreshold => 'Nemokamos pagalbos riba';

  @override
  String get partialAidThreshold => 'Dalinės pagalbos riba';

  @override
  String get assetLimit => 'Turto riba';

  @override
  String get whereToApplyLabel => 'Kur kreiptis';

  @override
  String get phoneLabel => 'Telefonas';

  @override
  String get websiteLabel => 'Svetainė';

  @override
  String get disclaimerCollapsed => 'Tik DI rekomendacijos';

  @override
  String get disclaimerExpanded =>
      'DI asistentas — ne teisinė konsultacija. Visada pasitikrinkite pas kvalifikuotą teisininką.';

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
  String get categoryChildren => 'Vaikai';

  @override
  String get categoryDigital => 'Skaitmeninė';

  @override
  String get childrenRights => 'Vaikų teisės ir alimentai';

  @override
  String get childrenRightsDesc =>
      'Vaikų išlaikymas, alimentai, apsauga, valstybės garantijos';

  @override
  String get cyberbullying => 'Patyčios ir priekabiavimas internete';

  @override
  String get cyberbullyingDesc =>
      'Grasinimai, privatumo pažeidimai, šmeižtas internete';

  @override
  String get rightChildSupport =>
      'Abu tėvai teisiškai privalo finansiškai išlaikyti savo vaiką (Perekonnaseadus § 100–102)';

  @override
  String get rightMinimumAlimony =>
      'Minimalus vaiko išlaikymas Estijoje: bazinė suma (295,86 €) + 3 % praėjusių metų vidutinio bruto darbo užmokesčio (PKS § 101). Nuo 2026-04-01 — 318,62 €/mėn. vienam vaikui. Atnaujinama kasmet balandžio 1 d. Skaičiuoklė: alimendid.ee';

  @override
  String get rightCourtAlimony =>
      'Dėl alimentų galite kreiptis į apygardos teismą (maakohus) — reikalavimams iki 6400 € advokatas nebūtinas';

  @override
  String get rightBailiffEnforcement =>
      'Jei tėvas atsisako mokėti, antstolis (kohtutäitur) gali priverstinai vykdyti teismo sprendimą, įskaitant išskaitas iš darbo užmokesčio';

  @override
  String get rightStateAlimonyGuarantee =>
      'Jei tėvas nemoka, valstybė per Sotsiaalkindlustusamet skiria elatisabi (išlaikymo pašalpą) — iki 100 €/mėn. vienam vaikui';

  @override
  String get rightChildEducation =>
      'Kiekvienas vaikas turi teisę į švietimą, sveikatos priežiūrą ir apsaugą nuo smurto (Lastekaitseseadus § 4–5)';

  @override
  String get rightChildContact =>
      'Vaikas turi teisę palaikyti ryšį su abiem tėvais, nebent teismas nusprendžia kitaip (PKS § 143)';

  @override
  String get mustFileCourtClaim =>
      'Norėdami gauti alimentus, turite pateikti ieškinį teismui arba raštu susitarti dėl sumos';

  @override
  String get mustNotifyAddressChange =>
      'Praneškite Sotsiaalkindlustusamet apie adreso pasikeitimą, jei gaunate elatisabi';

  @override
  String get childrenActionGatherDocs =>
      'Surinkite vaiko gimimo liudijimą, savo asmens dokumentą ir išlaidų įrodymus';

  @override
  String get childrenActionFileCourtClaim =>
      'Pateikite ieškinį dėl alimentų apygardos teismui (maakohus) — tai galima padaryti internetu per e-toimik';

  @override
  String get childrenActionApplyElatisabi =>
      'Jei tėvas nemoka, kreipkitės dėl valstybės išlaikymo garantijos (elatisabi) į Sotsiaalkindlustusamet';

  @override
  String get childrenActionContactBailiff =>
      'Kreipkitės į antstolį (kohtutäitur), kad priverstinai įvykdytų teismo sprendimą';

  @override
  String get childrenActionCallLasteabi =>
      'Skambinkite Lasteabi 116 111 — vaikų pagalbos linija, nemokama, visą parą';

  @override
  String get childrenDeadlineElatisabi =>
      'Elatisabi prašymas — po teismo sprendimo, griežto termino nėra, bet procesas užtrunka';

  @override
  String get childrenDeadlineCourt =>
      'Alimentų galima reikalauti atgaline data iki 1 metų iki ieškinio pateikimo teismui';

  @override
  String get childrenFactMinimum =>
      'Nuo 2026-04-01 minimalus vaiko išlaikymas yra 318,62 €/mėn. vienam vaikui. Formulė: bazinė suma (295,86 €) + 3 % praėjusių metų vidutinio bruto darbo užmokesčio. Atnaujinama kasmet balandžio 1 d. Tėvas negali sutikti mokėti mažiau. Skaičiuoklė: alimendid.ee';

  @override
  String get childrenFactElatisabi =>
      'Estijos valstybės išlaikymo garantija (elatisabi) buvo įvesta 2017 m., siekiant apsaugoti vaikus, kai tėvas atsisako mokėti. Valstybė moka, o vėliau susigrąžina sumą iš skolininko.';

  @override
  String get rightReportCybercrime =>
      'Turite teisę pranešti policijai apie grasinimus internete, priekabiavimą ir tapatybės vagystę (Karistusseadustik § 120, § 157¹)';

  @override
  String get rightContentRemoval =>
      'Galite reikalauti pašalinti šmeižikišką ar privatų turinį iš platformų ir reikalauti pašalinimo pagal BDAR';

  @override
  String get rightMoralDamageCompensation =>
      'Galite reikalauti kompensacijos už neturtinę žalą, padarytą patyčiomis internete (Võlaõigusseadus § 1043–1055)';

  @override
  String get rightPrivacyProtection =>
      'Jūsų privatus gyvenimas yra saugomas — jūsų nuotraukų, pranešimų ar asmens duomenų neteisėtas platinimas yra draudžiamas (KarS § 157)';

  @override
  String get rightDataProtection =>
      'Praneškite apie duomenų apsaugos pažeidimus (neteisėtas jūsų duomenų naudojimą) Andmekaitse Inspektsioon';

  @override
  String get rightDefamationAction =>
      'Šmeižtas (laimamine) yra civilinis pažeidimas — galite pareikšti ieškinį dėl žalos atlyginimo ir reikalauti viešo atsiėmimo (KarS § 247 (panaikinta), VÕS § 1047)';

  @override
  String get mustCollectEvidence =>
      'Rinkite ir saugokite visus įrodymus — ekrano nuotraukas, nuorodas, datas ir liudytojų informaciją';

  @override
  String get mustNotRetaliate =>
      'Nesikeršykite ir nesileiskite į atsakomąjį priekabiavimą — tai gali susilpninti jūsų bylą';

  @override
  String get cyberActionScreenshots =>
      'Fiksuokite visas patyčias ekrano nuotraukomis — išsaugokite nuorodas, datas, vartotojų vardus ir turinį';

  @override
  String get cyberActionReportPolice =>
      'Pateikite pranešimą policijai artimiausiame skyriuje arba internetu politsei.ee';

  @override
  String get cyberActionReportPlatform =>
      'Praneškite apie turinį socialinio tinklo platformai dėl pašalinimo';

  @override
  String get cyberActionContactDPA =>
      'Jei jūsų asmens duomenys buvo netinkamai naudojami, kreipkitės į Andmekaitse Inspektsioon';

  @override
  String get cyberActionConsultLawyer =>
      'Pasitarkite su teisininku dėl civilinės žalos atlyginimo — nemokama teisinė pagalba prieinama per Riigi Õigusabi';

  @override
  String get cyberDeadlineCriminal =>
      'Baudžiamasis skundas — griežto termino nėra, tačiau geriausia pranešti nedelsiant';

  @override
  String get cyberDeadlineCivil =>
      'Civilinis ieškinys dėl žalos atlyginimo — iki 3 metų nuo pažeidimo sužinojimo (TsÜS § 150)';

  @override
  String get cyberFactPrivacy =>
      'Estijoje neteisėtas kieno nors intymių nuotraukų platinimas gali užtraukti iki 3 metų laisvės atėmimo bausmę pagal Karistusseadustik § 157¹ (privatumo pažeidimas).';

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
  String get deadlineRadarTitle => 'Artėjantys terminai';

  @override
  String get deadlineRadarEmpty => 'Artėjančių terminų nėra';

  @override
  String get deadlineRadarViewAll => 'Peržiūrėti visus';

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
  String get deadlineCardTomorrow => 'rytoj';

  @override
  String get deadlineCardToday => 'šiandien';

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
  String get deadlineCardMarkComplete => 'Pažymėti kaip atlikta';

  @override
  String get deadlineCardSnooze => 'Atidėti';

  @override
  String get deadlineCardSnooze3d => 'Atidėti 3 dienoms';

  @override
  String get deadlineCardSnooze7d => 'Atidėti 7 dienoms';

  @override
  String get deadlineCardSnoozeCustom => 'Pasirinkti datą';

  @override
  String get deadlineCardEdit => 'Redaguoti';

  @override
  String get deadlineCardDelete => 'Archyvuoti';

  @override
  String get deadlineCardSourceLabelPdf => 'iš PDF';

  @override
  String get deadlineCardSourceLabelIntake => 'iš anketos';

  @override
  String get deadlineCardSourceLabelManual => 'pridėta rankiniu būdu';

  @override
  String get deadlineCardSourceLabelEmail => 'iš el. laiško';

  @override
  String get deadlineCardSourceLabelHaikuExtract => 'gauta iš DI';

  @override
  String get deadlineCardSourceLabelStatutoryTemplate => 'įstatymo šablonas';

  @override
  String deadlineBannerCritical(String title, String when) {
    return 'Svarbus terminas $title $when';
  }

  @override
  String get deadlineBannerDismiss => 'Atmesti';

  @override
  String get deadlineBannerOpen => 'Atidaryti terminą';

  @override
  String deadlineHolidayShifted(String original, String reason) {
    return 'Perkelta nuo $original dėl $reason';
  }

  @override
  String get deadlinePermissionAskTitle => 'Įjungti priminimus apie terminus?';

  @override
  String get deadlinePermissionAskBody =>
      'Priminsime jums likus 7, 3 ir 1 dienai iki kiekvieno įstatyminio termino, taip pat jo dieną ryte. Niekada nenaudojama rinkodarai.';

  @override
  String get deadlinePermissionAllow => 'Leisti';

  @override
  String get deadlinePermissionLater => 'Vėliau';

  @override
  String get deadlineSettingsSection => 'Priminimai apie terminus';

  @override
  String get deadlineSettingsPushChannel => 'Push pranešimai';

  @override
  String get deadlineSettingsEmailChannel => 'El. paštas (tik svarbiausi)';

  @override
  String get deadlineSettingsInAppChannel =>
      'Programos viduje rodomi pranešimai';

  @override
  String get deadlineSettingsCriticalBypass =>
      'Svarbūs priminimai apeina tylos valandas';

  @override
  String get deadlineSettingsQuietHours => 'Tylos valandos';

  @override
  String deadlineSettingsQuietHoursBadge(String start, String end) {
    return 'Tyla $start–$end';
  }

  @override
  String get deadlineCaseScreenTitle => 'Bylos terminai';

  @override
  String get deadlineAddManualCta => 'Pridėti terminą';

  @override
  String get deadlineFormTitle => 'Pavadinimas';

  @override
  String get deadlineFormDescription => 'Aprašymas (neprivaloma)';

  @override
  String get deadlineFormStatuteTemplate => 'Įstatymo šablonas';

  @override
  String get deadlineFormStatuteTemplateNone => 'Nėra (rankiniu būdu)';

  @override
  String get deadlineFormDeadlineAt => 'Termino data';

  @override
  String get deadlineFormPriority => 'Prioritetas';

  @override
  String get deadlineFormSave => 'Išsaugoti';

  @override
  String get deadlineFormCancel => 'Atšaukti';

  @override
  String get deadlineCompletedNotePrompt => 'Pridėti pastabą (neprivaloma)';

  @override
  String get deadlineCompletedNoteSave => 'Išsaugoti';

  @override
  String get inboxTitle => 'Gautieji';

  @override
  String get inboxEmptyTitle => 'Nieko laukiančio';

  @override
  String get inboxEmptyBody =>
      'Nauji el. laiškų siūlai bus rodomi čia, kai tik bus suklasifikuoti.';

  @override
  String get inboxApproveSend => 'Patvirtinti ir siųsti';

  @override
  String get inboxEditDraft => 'Redaguoti';

  @override
  String get inboxSnooze => 'Atidėti';

  @override
  String get inboxArchive => 'Archyvuoti';

  @override
  String get inboxFilterAll => 'Visi';

  @override
  String get inboxConfirmSendTitle => 'Siųsti paruoštą atsakymą?';

  @override
  String get inboxConfirmSendBody =>
      '„Advocat“ išsiųs DI paruoštą atsakymą per jūsų prijungtą „Gmail“. Turinį vis tiek galėsite peržiūrėti kitame ekrane.';

  @override
  String get inboxSendButton => 'Siųsti';

  @override
  String get inboxSentToast => 'Išsiųsta.';

  @override
  String get inboxAlreadySentToast => 'Jau išsiųsta.';

  @override
  String get inboxSendErrorToast =>
      'Nepavyko išsiųsti atsakymo. Palieskite, kad bandytumėte dar kartą.';

  @override
  String get inboxSnoozedToast => 'Atidėta 24 val.';

  @override
  String get inboxArchivedToast => 'Archyvuota.';

  @override
  String get inboxDraftLoadError => 'Nepavyko įkelti juodraščio.';

  @override
  String get inboxDeadlineToday => 'šiandien';

  @override
  String get inboxDeadlineTomorrow => 'rytoj';

  @override
  String inboxDeadlineInDays(int days) {
    return 'po $days d.';
  }

  @override
  String inboxDeadlineOverdue(int days) {
    return 'vėluoja $days d.';
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
  String get workspaceTabOverview => 'Apžvalga';

  @override
  String get workspaceTabChat => 'Pokalbis';

  @override
  String get workspaceTabDrafts => 'Juodraščiai';

  @override
  String get workspaceOverviewEmpty =>
      'Pridėkite dokumentus, kad būtų sukurta santrauka.';

  @override
  String get workspaceTimelineEmpty => 'Įvykių dar nėra.';

  @override
  String get workspaceDocumentsEmpty =>
      'Dokumentų nėra. Įkelkite per „Skenuoti“.';

  @override
  String get workspaceDraftsEmpty => 'Juodraščių dar nėra.';

  @override
  String get workspaceInboxEmpty => 'Susijusių el. laiškų nėra.';

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
  String get draftsTab => 'Juodraščiai';

  @override
  String get draftingTitle => 'Juodraščių studija';

  @override
  String get draftingEmpty => 'Tuščias juodraštis';

  @override
  String get draftingPlaceholder => 'Pradėkite rašyti savo juodraštį…';

  @override
  String get draftingDraftsList => 'Mano juodraščiai';

  @override
  String get draftingSave => 'Išsaugoti';

  @override
  String get draftingSaved => 'Išsaugota';

  @override
  String get draftingSavedJustNow => 'Ką tik išsaugota';

  @override
  String get draftingAiRevise => 'Taisyti su DI';

  @override
  String get draftingExportPdf => 'Eksportuoti PDF';

  @override
  String get draftingExportDocx => 'Eksportuoti DOCX';

  @override
  String get draftingExportMd => 'Eksportuoti Markdown';

  @override
  String get draftingDeleteDraft => 'Ištrinti juodraštį';

  @override
  String get draftingConfirmDelete => 'Ištrinti šį juodraštį?';

  @override
  String get draftingConfirmDeleteMessage => 'Šio veiksmo anuliuoti negalima.';

  @override
  String get draftingConfirm => 'Ištrinti';

  @override
  String get draftingCancel => 'Atšaukti';

  @override
  String draftingDraftReplyTo(String name) {
    return 'Atsakyti $name';
  }

  @override
  String get draftingUntitled => 'Be pavadinimo';

  @override
  String get draftingTitleHint => 'Pavadinimas (neprivaloma)';

  @override
  String get draftingAiReviseTitle => 'Taisyti su DI';

  @override
  String get draftingAiReviseSelectionLabel => 'Pažymėtas tekstas:';

  @override
  String get draftingAiReviseInstructionLabel => 'Nurodymas (neprivaloma)';

  @override
  String get draftingAiReviseInstructionHint =>
      'pvz., „padaryti oficialiau“ arba „sutrumpinti“';

  @override
  String get draftingAiReviseRunButton => 'Generuoti pataisymą';

  @override
  String get draftingAiReviseSuggestionLabel => 'Siūlomas pataisymas:';

  @override
  String get draftingAiReviseChangesLabel => 'Pakeitimai:';

  @override
  String get draftingAiReviseAccept => 'Priimti';

  @override
  String get draftingAiReviseReject => 'Atmesti';

  @override
  String get draftingFormatBold => 'Paryškintas';

  @override
  String get draftingFormatItalic => 'Kursyvas';

  @override
  String get draftingFormatHeading => 'Antraštė';

  @override
  String get draftingFormatBullet => 'Sąrašas su ženkleliais';

  @override
  String get draftingFormatNumbered => 'Numeruotas sąrašas';

  @override
  String get draftingEmptyListMessage => 'Juodraščių dar neturite.';

  @override
  String get draftingEmptyListAction => 'Naujas juodraštis';

  @override
  String get draftingExporting => 'Eksportuojama…';

  @override
  String get draftingExportFailed => 'Eksportuoti nepavyko';

  @override
  String get draftingSaveFailed => 'Išsaugoti nepavyko';

  @override
  String get draftingNewDraft => 'Naujas juodraštis';

  @override
  String get vaultNoteChip => 'Saugyklos užrašas';

  @override
  String get saveToVault => 'Išsaugoti į saugyklą';

  @override
  String get savingToVault => 'Saugoma į saugyklą…';

  @override
  String get savedToVault => 'Išsaugota į saugyklą';

  @override
  String get vaultNoteTitlePrefix => 'Užrašas: ';

  @override
  String get openInVault => 'Atidaryti saugykloje';

  @override
  String get saveToVaultFailed => 'Nepavyko išsaugoti į saugyklą';

  @override
  String get pdfWorkerUnavailable =>
      'PDF eksportas laikinai nepasiekiamas. Bandykite DOCX arba Markdown.';

  @override
  String get draftingVersionHistory => 'Versijų istorija';

  @override
  String get emptyHomeTitle => 'Sveiki atvykę į „Advocat“';

  @override
  String get emptyHomeBody =>
      'Pasirinkite pradžios tašką — mes pasirūpinsime teisiniu darbu.';

  @override
  String get intentChip1 => 'Gavau baudą';

  @override
  String get intentChip2 => 'Leidimas atmestas';

  @override
  String get intentChip3 => 'Sutarties problema';

  @override
  String get emptyCasesTitle => 'Bylų dar nėra';

  @override
  String get emptyCasesCta => 'Pradėti bylą';

  @override
  String get emptyDraftsTitle => 'Juodraščių dar nėra';

  @override
  String get emptyDraftsCta => 'Sukurti juodraštį';

  @override
  String get emptyChatTitle => 'Klauskite „Advocat“ bet ko';

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
  String get referralInviteFriends => 'Pakviesti draugus';

  @override
  String get referralYourCode => 'Jūsų kodas';

  @override
  String get referralCopiedToast => 'Kodas nukopijuotas į iškarpinę';

  @override
  String get referralReward =>
      'Gaukite 1 mėnesį „Counsel“ plano nemokamai už kiekvieną draugą, kuris užsiprenumeruoja.';

  @override
  String get referralInvited => 'Pakviesti draugai';

  @override
  String get referralRewardsEarned => 'Uždirbti nemokami mėnesiai';

  @override
  String get deadlineUrgencyToday => 'Šiandien ir vėluojantys';

  @override
  String get deadlineUrgencyWeek => 'Šią savaitę';

  @override
  String get deadlineUrgencyMonth => 'Šį mėnesį';

  @override
  String get deadlineUrgencyLater => 'Vėliau';

  @override
  String get deadlineAddManual => 'Pridėti terminą';

  @override
  String get deadlineSnoozeBy => 'Atidėti';

  @override
  String get deadlineSnooze1d => 'Atidėti 1 dienai';

  @override
  String get deadlineSnooze3d => 'Atidėti 3 dienoms';

  @override
  String get deadlineSnooze7d => 'Atidėti 7 dienoms';

  @override
  String get deadlineDismiss => 'Atmesti';

  @override
  String get deadlineExportIcs => 'Pridėti į kalendorių';

  @override
  String get deadlineSource => 'Šaltinis';

  @override
  String get deadlineEmpty =>
      'Terminų dar nėra. Terminai automatiškai sukuriami iš jūsų el. laiškų ir dokumentų — arba pridėkite juos rankiniu būdu mygtuku „+“.';

  @override
  String get deadlineNewTitle => 'Naujas terminas';

  @override
  String get deadlineFieldTitle => 'Pavadinimas';

  @override
  String get deadlineFieldDueDate => 'Termino data';

  @override
  String get deadlineFieldNotes => 'Pastabos (neprivaloma)';

  @override
  String get deadlineSaved => 'Terminas išsaugotas';

  @override
  String get deadlineSaveFailed => 'Nepavyko išsaugoti termino';

  @override
  String get deadlineUrgentBannerSingle =>
      '1 terminas šiandien arba vėluojantis';

  @override
  String deadlineUrgentBannerMany(int count) {
    return '$count terminai(-ų) šiandien arba vėluojantys';
  }

  @override
  String deadlineDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'liko $count dienų',
      one: 'liko 1 diena',
      zero: 'šiandien',
    );
    return '$_temp0';
  }

  @override
  String deadlineDaysOverdue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vėluoja $count dienų',
      one: 'vėluoja 1 dieną',
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
  String get deadlineEuRadarTitle => 'ES terminų radaras (peržiūra)';

  @override
  String get deadlineEuRadarSubtitle =>
      'Hipotetiniai ES procedūriniai terminai — bandomieji duomenys';

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
  String get accessLogTile => 'Prieigos žurnalas';

  @override
  String get accessLogTileSubtitle =>
      'Matykite, kas ir kaip pasiekė jūsų duomenis';

  @override
  String get accessLogTitle => 'Mano duomenų prieigos žurnalas';

  @override
  String get accessLogIntro =>
      'Skaidrus, klastojimui atsparus įrašas apie kiekvieną kartą, kai jūsų duomenys buvo pasiekti ar tvarkomi – įskaitant mūsų DI. Galite patikrinti, kad jis nebuvo pakeistas.';

  @override
  String get accessLogEmpty => 'Prieigos įvykių dar nėra.';

  @override
  String get accessLogError =>
      'Nepavyko įkelti jūsų prieigos žurnalo. Patraukite žemyn, kad bandytumėte dar kartą.';

  @override
  String get accessLogIntegrityOk =>
      'Vientisumas patikrintas – žurnalo nuorodos sudaro nepertraukiamą grandinę.';

  @override
  String get accessLogIntegrityBroken =>
      'Įspėjimas: žurnalo grandinė pažeista. Kai kurie įrašai galėjo būti pašalinti arba pertvarkyti. Kreipkitės į palaikymą.';

  @override
  String get accessActionLlmEgress =>
      'Išsiųsta DI apdorojimui (pseudonimizuota)';

  @override
  String get accessActionAiAnalysis => 'Išanalizuota DI';

  @override
  String get accessActionDocumentParse => 'Dokumentas išnagrinėtas';

  @override
  String get accessActionStaffRead => 'Peržiūrėjo darbuotojas';

  @override
  String get accessActionExport => 'Duomenys eksportuoti';

  @override
  String get accessActionEmailTriage => 'El. laiškas surūšiuotas';

  @override
  String get accessActionDeadlineScan => 'Terminai nuskaityti';

  @override
  String get breachAlertTitle => 'Saugumo įspėjimas dėl jūsų duomenų';

  @override
  String get breachAlertBody =>
      'Mūsų automatinė stebėsena aptiko neįprastą prieigą prie jūsų duomenų. Šiuo metu tai nagrinėjame ir, kaip reikalauja įstatymai (BDAR 34 str.), pranešime apie bet kokį patvirtintą incidentą.';

  @override
  String get caseDossierTitle => 'Eksportuoti bylos rinkinį';

  @override
  String get caseDossierSubtitle =>
      'Vienas PDF su viskuo – faktais, chronologija, terminais ir dokumentais – kurį galima perduoti advokatui, teismui ar skundų institucijai.';

  @override
  String get caseDossierTileTitle => 'Eksportuoti rinkinį (PDF)';

  @override
  String get caseDossierTileSubtitle =>
      'Perduokite visą bylą advokatui ar teismui viename faile';

  @override
  String get caseDossierSectionsHeading => 'Įtraukti į rinkinį';

  @override
  String get caseDossierSectionFacts => 'Bylos faktai';

  @override
  String get caseDossierSectionFactsHint => 'Įtraukiama visada';

  @override
  String get caseDossierSectionTimeline => 'Chronologija';

  @override
  String get caseDossierSectionDeadlines => 'Terminai';

  @override
  String get caseDossierSectionDocuments => 'Dokumentai';

  @override
  String get caseDossierSectionAiSummary => 'DI santrauka';

  @override
  String get caseDossierExportButton => 'Eksportuoti PDF';

  @override
  String get caseDossierExporting => 'Rengiamas jūsų rinkinys…';

  @override
  String get caseDossierSuccess =>
      'Rinkinys paruoštas. Atidarykite arba bendrinkite failą.';

  @override
  String get caseDossierOpen => 'Atidaryti rinkinį';

  @override
  String get caseDossierError =>
      'Nepavyko parengti rinkinio. Bandykite dar kartą.';

  @override
  String get caseDossierErrorNotOwned => 'Šios bylos rasti nepavyko.';

  @override
  String get caseDossierDisclaimer =>
      'Rinkinyje atkartojami jūsų bylos duomenys tokie, kokie užfiksuoti. Peržiūrėkite jį prieš bendrindami.';

  @override
  String get followupsTitle => 'Kiti žingsniai';

  @override
  String get followupsSubtitle => 'Praktinės užduotys, kad byla judėtų pirmyn';

  @override
  String get followupsEmpty => 'Tolesnių žingsnių dar nėra.';

  @override
  String get followupsEmptyDesc =>
      'Pridėkite žingsnį arba leiskite DI pasiūlyti, ką daryti toliau.';

  @override
  String get followupsAdd => 'Pridėti žingsnį';

  @override
  String get followupsSuggest => 'Pasiūlyti žingsnius';

  @override
  String get followupsSuggestNone =>
      'Šiuo metu pasiūlymų nėra. Pabandykite pasikalbėję apie bylą.';

  @override
  String get followupsSuggestTitle => 'Siūlomi kiti žingsniai';

  @override
  String get followupsAddPrompt =>
      'Pridėkite žingsnius, kuriuos norite išsaugoti:';

  @override
  String get followupsNewTitleHint => 'Ką reikia padaryti?';

  @override
  String get followupsNewDetailHint =>
      'Neprivaloma pastaba (kodėl / ką pridėti)';

  @override
  String get followupsDueOptional => 'Priminti (neprivaloma)';

  @override
  String get followupsOverdue => 'Pradelsta';

  @override
  String followupsDueOn(String date) {
    return 'Iki $date';
  }

  @override
  String get followupsDone => 'Atlikta';

  @override
  String get followupsSnooze => 'Atidėti';

  @override
  String get followupsSnooze1Week => 'Priminti po savaitės';

  @override
  String get followupsDismiss => 'Atmesti';

  @override
  String get followupsLoadError => 'Nepavyko įkelti kitų žingsnių';

  @override
  String get followupsAiBadge => 'DI';

  @override
  String get contractCompareTitle => 'Palyginti versijas';

  @override
  String get contractCompareIntro =>
      'Įkelkite dvi to paties sutarties versijas. Paryškinsime, kas pasikeitė ir ar kiekvienas pakeitimas jums naudingas, ar kenkia.';

  @override
  String get contractCompareOldVersion => 'Senoji versija (v1)';

  @override
  String get contractCompareNewVersion => 'Naujoji versija (v2)';

  @override
  String get contractCompareCta => 'Palyginti versijas';

  @override
  String get contractCompareAdverse => 'Nepalankus';

  @override
  String get contractCompareFavorable => 'Palankus';

  @override
  String get contractCompareNeutral => 'Neutralus';

  @override
  String get contractCompareBefore => 'Prieš';

  @override
  String get contractCompareAfter => 'Po';

  @override
  String get contractCompareTruncated =>
      'Ilga sutartis – palyginta tik pirmoji kiekvienos versijos dalis.';

  @override
  String get contractCompareNoChanges =>
      'Tarp dviejų versijų esminių pakeitimų neaptikta.';

  @override
  String get docSearchTitle => 'Ieškoti mano dokumentuose';

  @override
  String get docSearchHint => 'pvz., kur buvo paminėtas užstatas';

  @override
  String get docSearchSubtitle =>
      'Semantinė paieška jūsų seife ir bylos failuose';

  @override
  String get docSearchIdle =>
      'Ieškokite savo dokumentų turinyje – ne tik pavadinimuose.';

  @override
  String get docSearchNoResults => 'Jūsų dokumentuose atitikmenų nerasta.';

  @override
  String get docSearchError => 'Paieška nepavyko. Bandykite dar kartą.';

  @override
  String get docSearchUntitled => 'Dokumentas be pavadinimo';

  @override
  String get docSearchKindCase => 'Bylos dokumentas';

  @override
  String get docSearchKindVault => 'Seifo dokumentas';

  @override
  String get docSearchMenuTitle => 'Ieškoti mano dokumentuose';

  @override
  String get docSearchMenuSubtitle =>
      'Raskite bet ką savo failuose pagal prasmę';

  @override
  String get legalTemplatesTitle => 'Šablonų biblioteka';

  @override
  String get legalTemplatesMenuLabel => 'Šablonai';

  @override
  String get legalTemplatesSubtitle =>
      'Pasirinkite paruoštą formą, užpildykite kelias detales, ir sukursime juodraštį, kurį galėsite redaguoti ir eksportuoti.';

  @override
  String get legalTemplatesDisclaimer =>
      'Tai bendro pobūdžio pavyzdinės formos, o ne individuali teisinė konsultacija. Peržiūrėkite ir pritaikykite prieš siųsdami.';

  @override
  String get legalTemplatesSampleBadge => 'Pavyzdys';

  @override
  String get legalTemplatesEmpty => 'Šiam filtrui šablonų dar nėra.';

  @override
  String get legalTemplatesError =>
      'Nepavyko įkelti šablonų. Bandykite dar kartą.';

  @override
  String get legalTemplatesFilterAll => 'Visi';

  @override
  String get legalTemplatesJurisdictionFi => 'Suomija';

  @override
  String get legalTemplatesJurisdictionEe => 'Estija';

  @override
  String get legalTemplatesCategoryComplaint => 'Skundai';

  @override
  String get legalTemplatesCategoryAppeal => 'Apeliacijos';

  @override
  String get legalTemplatesCategoryApplication => 'Prašymai';

  @override
  String get legalTemplatesCategoryClaim => 'Reikalavimai';

  @override
  String get legalTemplatesCategoryRequest => 'Užklausos';

  @override
  String get legalTemplatesFillTitle => 'Užpildykite detales';

  @override
  String get legalTemplatesFillIntro =>
      'Automatiškai užpildysime jūsų vardą ir bylos duomenis. Užpildykite žemiau esančius laukus.';

  @override
  String get legalTemplatesFieldRequired => 'Šis laukas privalomas';

  @override
  String get legalTemplatesCreateDraft => 'Sukurti juodraštį';

  @override
  String get legalTemplatesCreating => 'Kuriamas juodraštis…';

  @override
  String get legalTemplatesCreateFailed =>
      'Nepavyko sukurti juodraščio. Bandykite dar kartą.';

  @override
  String get legalTemplatesUnresolvedWarning =>
      'Kai kurie laukai vis dar tušti ir juodraštyje pažymėti ____. Galite juos užpildyti redaktoriuje.';

  @override
  String get legalTemplatesFieldRecipient =>
      'Gavėjas (institucija / nuomotojas)';

  @override
  String get legalTemplatesFieldAddress => 'Jūsų pašto adresas';

  @override
  String get legalTemplatesFieldSubject => 'Tema';

  @override
  String get legalTemplatesFieldDescription => 'Reikalo aprašymas';

  @override
  String get legalTemplatesFieldDemand => 'Ko prašote';

  @override
  String get checklistActionPlan => 'Veiksmų planas';

  @override
  String get checklistActionPlanSubtitle => 'Žingsniai šio tipo bylai';

  @override
  String checklistProgress(int completed, int total) {
    return 'Atlikta $completed iš $total žingsnių';
  }

  @override
  String get checklistAllDone => 'Visi žingsniai atlikti';

  @override
  String get checklistEmpty => 'Šio tipo bylai veiksmų plano dar nėra.';

  @override
  String checklistDeadlineDays(int days) {
    return '$days d.';
  }

  @override
  String get checklistDisclaimer =>
      'Tai bendro pobūdžio informacija, o ne teisinė konsultacija. Terminai yra įstatyminiai numatytieji – patvirtinkite tikslią datą savo byloje.';

  @override
  String get checklistViewPlan => 'Peržiūrėti planą';

  @override
  String get explainPlainTitle => 'Paaiškinti paprastai';

  @override
  String get explainPlainIntro =>
      'Įklijuokite oficialų laišką, sprendimą ar sutartį, ir paaiškinsime, ką tai reiškia ir ko iš jūsų prašoma – paprasta kalba.';

  @override
  String get explainPlainLevelFriend => 'Kaip draugui';

  @override
  String get explainPlainLevelTerms => 'Išlaikyti teisinius terminus';

  @override
  String get explainPlainInputHint => 'Įklijuokite teisinį tekstą čia…';

  @override
  String get explainPlainSubmit => 'Paaiškinti';

  @override
  String get explainPlainWorking => 'Aiškinama…';

  @override
  String get explainPlainTldr => 'Esmė';

  @override
  String get explainPlainBreakdown => 'Ką tai sako, dalimis';

  @override
  String get explainPlainGlossary => 'Sudėtingi terminai paaiškinti';

  @override
  String get explainPlainNextSteps => 'Ką galite daryti toliau';

  @override
  String get explainPlainOpenInCorpus => 'Ieškoti teisės bibliotekoje';

  @override
  String get explainPlainEmptyResult =>
      'Šiam tekstui paaiškinimo parengti nepavyko. Pabandykite įklijuoti ilgesnę arba aiškesnę ištrauką.';

  @override
  String get explainPlainQuotaTitle =>
      'Šį mėnesį išnaudojote savo nemokamus paaiškinimus';

  @override
  String get explainPlainQuotaBody =>
      'Nemokamos paskyros gauna 3 paaiškinimus per mėnesį. Pereikite prie „Pro“ neribotiems paaiškinimams.';

  @override
  String get explainPlainUpgradeCta => 'Pereiti prie „Pro“';

  @override
  String get explainPlainError =>
      'Aiškinant šį tekstą kažkas nepavyko. Bandykite dar kartą.';

  @override
  String get explainPlainRetry => 'Bandyti dar kartą';

  @override
  String get demandLetterTitle => 'Reikalavimo raštas';

  @override
  String get demandLetterSubtitle =>
      'Sukurkite oficialų ikiteisminį reikalavimą (maksuvaatimus / nõudekiri).';

  @override
  String get demandLetterStepType => 'Reikalavimo tipas';

  @override
  String get demandLetterStepParties => 'Šalys';

  @override
  String get demandLetterStepClaim => 'Suma ir pagrindas';

  @override
  String get demandLetterStepDeadline => 'Terminas';

  @override
  String get demandLetterStepReview => 'Peržiūra ir generavimas';

  @override
  String get demandLetterClaimDepositReturn => 'Nuomos užstato grąžinimas';

  @override
  String get demandLetterClaimUnpaidWage => 'Neišmokėtas darbo užmokestis';

  @override
  String get demandLetterClaimFineDispute => 'Baudos / mokesčio ginčijimas';

  @override
  String get demandLetterClaimGeneric => 'Kitas piniginis reikalavimas';

  @override
  String get demandLetterJurisdiction => 'Jurisdikcija';

  @override
  String get demandLetterLanguage => 'Rašto kalba';

  @override
  String get demandLetterRecipientName => 'Gavėjo vardas';

  @override
  String get demandLetterRecipientAddress => 'Gavėjo adresas (neprivaloma)';

  @override
  String get demandLetterSenderName => 'Jūsų vardas';

  @override
  String get demandLetterSenderAddress =>
      'Jūsų adresas / el. paštas (neprivaloma)';

  @override
  String get demandLetterAmount => 'Suma';

  @override
  String get demandLetterCurrency => 'Valiuta';

  @override
  String get demandLetterBasis => 'Kas įvyko (reikalavimo pagrindas)';

  @override
  String get demandLetterBasisHint =>
      'Aprašykite faktus: datas, sumas, dėl ko buvo susitarta ir kas nutiko negerai.';

  @override
  String get demandLetterDeadline => 'Apmokėjimo terminas';

  @override
  String get demandLetterDeadlineHint => 'pvz., 14 dienų nuo šiandien';

  @override
  String get demandLetterReference => 'Nuoroda (neprivaloma)';

  @override
  String get demandLetterGenerate => 'Generuoti raštą';

  @override
  String get demandLetterGenerating => 'Generuojama…';

  @override
  String get demandLetterGenerateFailed =>
      'Nepavyko sugeneruoti rašto. Bandykite dar kartą.';

  @override
  String get demandLetterFieldRequired => 'Šis laukas privalomas';

  @override
  String get demandLetterNext => 'Toliau';

  @override
  String get demandLetterBack => 'Atgal';

  @override
  String get demandLetterPreviewTitle => 'Jūsų raštas';

  @override
  String get demandLetterCopy => 'Kopijuoti tekstą';

  @override
  String get demandLetterCopied => 'Raštas nukopijuotas į iškarpinę';

  @override
  String get demandLetterExportPdf => 'Eksportuoti PDF';

  @override
  String get demandLetterExporting => 'Eksportuojama…';

  @override
  String get demandLetterExportFailed =>
      'Nepavyko eksportuoti dokumento. Bandykite dar kartą.';

  @override
  String get demandLetterSendEmail => 'Siųsti el. paštu';

  @override
  String get demandLetterNormsTitle => 'Teisinės nuorodos';

  @override
  String get demandLetterDisclaimer =>
      'Šis raštas parengtas jūsų vardu kaip bendro pobūdžio šablonas. Tai nėra teisinė konsultacija ar licencijuoto advokato veiksmas. Peržiūrėkite jį prieš siųsdami – joks raštas nesiunčiamas automatiškai.';

  @override
  String get demandLetterMenuTile => 'Reikalavimo raštas';

  @override
  String get calcHubTitle => 'Teisiniai skaičiuotuvai';

  @override
  String get calcHubSubtitle => 'Greiti įverčiai prieš kitą žingsnį';

  @override
  String get calcHubJurisdiction => 'Jurisdikcija';

  @override
  String calcRatesAsOf(String date) {
    return 'Tarifai $date dienai';
  }

  @override
  String get calcRatesOffline =>
      'Rodomi talpykloje saugomi tarifai (neprisijungus)';

  @override
  String get calcIndicativeBanner =>
      'Tik orientacinis įvertis – ne oficialus skaičiavimas ar teisinė konsultacija.';

  @override
  String get calcCalculate => 'Skaičiuoti';

  @override
  String get calcResult => 'Rezultatas';

  @override
  String get calcFormula => 'Kaip tai apskaičiuota';

  @override
  String get calcSource => 'Šaltinis';

  @override
  String get calcSeveranceTitle => 'Išeitinė / įspėjimas';

  @override
  String get calcSeveranceDesc =>
      'Įvertinkite išeitinę išmoką ir įspėjimo laikotarpį atleidžiant dėl etatų mažinimo';

  @override
  String get calcSeveranceSalary => 'Bruto mėnesinis atlyginimas';

  @override
  String get calcSeveranceTenure => 'Darbo stažas (metais)';

  @override
  String get calcSeveranceTotal => 'Numatoma išeitinė';

  @override
  String get calcSeveranceNotice => 'Įspėjimo laikotarpis';

  @override
  String get calcSeveranceGenerateDemand => 'Parengti reikalavimo raštą';

  @override
  String get calcLimitationTitle => 'Senaties ir apeliacijos terminai';

  @override
  String get calcLimitationDesc =>
      'Patikrinkite, ar reikalavimo arba apeliacijos terminas nepasibaigė';

  @override
  String get calcLimitationType => 'Laikotarpio tipas';

  @override
  String get calcLimitationStart => 'Pradžios data (įvykis / sprendimas)';

  @override
  String get calcLimitationPickDate => 'Pasirinkti datą';

  @override
  String get calcLimitationDeadline => 'Terminas';

  @override
  String get calcLimitationExpired => 'Laikotarpis pasibaigė';

  @override
  String calcLimitationDaysLeft(int days) {
    return 'Liko $days dienų';
  }

  @override
  String get calcLimitationShifted =>
      'Perkelta į kitą darbo dieną (savaitgalis / šventė).';

  @override
  String get calcLimitationAddDeadline => 'Pridėti prie terminų';

  @override
  String get calcStateFeeTitle => 'Teismo / valstybės mokesčiai';

  @override
  String get calcStateFeeDesc =>
      'Orientaciniai žyminiai mokesčiai pagal teismą ir stadiją';

  @override
  String get calcChildSupportTitle => 'Vaiko išlaikymas (orientacinis)';

  @override
  String get calcChildSupportDesc =>
      'Apytikris orientacinis dydis – tikroji suma nustatoma kiekvienu atveju atskirai';

  @override
  String get calcChildSupportNet => 'Mokėtojo neto mėnesinės pajamos';

  @override
  String get calcChildSupportChildren => 'Vaikų skaičius';

  @override
  String get calcChildSupportPerChild => 'Vienam vaikui';

  @override
  String get calcChildSupportTotal => 'Iš viso per mėnesį';

  @override
  String get calcChildSupportWarning =>
      'Labai kintamas dydis. Teismai sprendžia pagal vaiko poreikius ir abiejų tėvų galimybes mokėti. Naudokite tik kaip atspirties tašką.';

  @override
  String get docCollectTitle => 'Dokumentai, kuriuos reikia surinkti';

  @override
  String get docCollectSubtitle =>
      'Surinkite juos prieš teikdami prašymą ar kreipdamiesi į teismą';

  @override
  String get docCollectPickPrompt => 'Kokia jūsų situacija?';

  @override
  String get docCollectProblemResidence => 'Leidimas gyventi';

  @override
  String get docCollectProblemTenant => 'Nuoma / iškeldinimas';

  @override
  String get docCollectProblemDismissal => 'Atleidimas iš darbo';

  @override
  String get docCollectProblemInheritance => 'Paveldėjimas';

  @override
  String get docCollectProblemDivorce => 'Skyrybos';

  @override
  String docCollectProgress(int collected, int total) {
    return 'Surinkta $collected iš $total';
  }

  @override
  String get docCollectAllDone => 'Viskas surinkta';

  @override
  String get docCollectEmpty => 'Šiai situacijai dokumentų sąrašo dar nėra.';

  @override
  String get docCollectOptional => 'Neprivaloma';

  @override
  String get docCollectWhereLabel => 'Kur gauti';

  @override
  String get docCollectWhyLabel => 'Kodėl reikia';

  @override
  String get docCollectAttach => 'Pridėti failą';

  @override
  String get docCollectAttached => 'Failas pridėtas';

  @override
  String get docCollectChangeFile => 'Pakeisti failą';

  @override
  String get docCollectRemoveFile => 'Pašalinti failą';

  @override
  String get docCollectNoFiles => 'Dar neįkėlėte jokių dokumentų.';

  @override
  String get docCollectPickFileTitle => 'Pasirinkite įkeltą dokumentą';

  @override
  String get docCollectExport => 'Eksportuoti sąrašą';

  @override
  String get docCollectExportSubject => 'Mano dokumentų sąrašas';

  @override
  String get docCollectAiTitle => 'Reikia ko nors konkretaus?';

  @override
  String get docCollectAiHint =>
      'Aprašykite savo situaciją, ir pasiūlysime papildomų dokumentų.';

  @override
  String get docCollectAiField => 'Aprašykite savo situaciją';

  @override
  String get docCollectAiButton => 'Pasiūlyti papildomų dokumentų';

  @override
  String get docCollectAiLoading => 'Mąstoma…';

  @override
  String get docCollectAiEmpty =>
      'Papildomų dokumentų nepasiūlyta – pagrindinis sąrašas atrodo išsamus jūsų aprašymui.';

  @override
  String get docCollectAiSuggestionsTitle => 'Siūlomi papildomi dokumentai';

  @override
  String get docCollectDisclaimer =>
      'Tai pagrindinis dažniausiai reikalaujamų dokumentų sąrašas – jūsų situacijai gali reikėti daugiau ar mažiau. Tai bendro pobūdžio informacija, o ne teisinė konsultacija.';

  @override
  String get docCollectRetry => 'Bandyti dar kartą';

  @override
  String get renewalTitle => 'Atnaujinimų radaras';

  @override
  String get renewalSubtitle =>
      'Stebėkite, kada baigiasi jūsų leidimų, paso, draudimo ir kitų dokumentų galiojimas. Primmsime likus 90, 30 ir 7 dienoms iki kiekvieno atnaujinimo.';

  @override
  String get renewalAdd => 'Pridėti dokumentą';

  @override
  String get renewalEditTitle => 'Redaguoti dokumentą';

  @override
  String get renewalSave => 'Išsaugoti';

  @override
  String get renewalRequired => 'Privaloma';

  @override
  String get renewalPickDate => 'Pasirinkti galiojimo pabaigos datą';

  @override
  String get renewalLoadError =>
      'Nepavyko įkelti jūsų dokumentų. Patraukite atnaujinti.';

  @override
  String get renewalEmptyTitle => 'Stebimų dokumentų dar nėra';

  @override
  String get renewalEmptyBody =>
      'Pridėkite savo leidimą gyventi, pasą, draudimą ar licenciją, ir stebėsime galiojimo pabaigos datas už jus.';

  @override
  String get renewalGuideHint => 'Kaip atnaujinti →';

  @override
  String get renewalFieldType => 'Dokumento tipas';

  @override
  String get renewalFieldLabel => 'Pavadinimas';

  @override
  String get renewalFieldNumber => 'Dokumento numeris (neprivaloma)';

  @override
  String get renewalFieldJurisdiction => 'Išdavusi šalis';

  @override
  String get renewalFieldExpiry => 'Galiojimo pabaigos data';

  @override
  String get renewalWindow90 => '90 dienų';

  @override
  String get renewalWindow30 => '30 dienų';

  @override
  String get renewalWindow7 => '7 dienos';

  @override
  String get renewalExpiresToday => 'Galioja iki šiandien';

  @override
  String renewalExpiresInDays(int days, String date) {
    return 'Galioja dar $days d. · $date';
  }

  @override
  String renewalExpiredOn(String date) {
    return 'Galiojimas baigėsi $date';
  }

  @override
  String get renewalTypeResidencePermit => 'Leidimas gyventi';

  @override
  String get renewalTypePassport => 'Pasas';

  @override
  String get renewalTypeIdCard => 'Asmens tapatybės kortelė';

  @override
  String get renewalTypeVisa => 'Viza';

  @override
  String get renewalTypeDrivingLicence => 'Vairuotojo pažymėjimas';

  @override
  String get renewalTypeInsurance => 'Draudimas';

  @override
  String get renewalTypeWorkPermit => 'Leidimas dirbti';

  @override
  String get renewalTypeOther => 'Kita';

  @override
  String get costEstimateTitle => 'Kaštų ir rizikos vertintuvas';

  @override
  String get costEstimateSubtitle =>
      'Susidarykite apytikrį vaizdą, kiek byla gali kainuoti, kiek užtrukti ir ar verta jos imtis.';

  @override
  String get costEstimateCaseTypeLabel => 'Bylos tipas';

  @override
  String get costEstimateCaseTypeHint =>
      'pvz., neapmokėta sąskaita, neteisėtas atleidimas, užstato ginčas';

  @override
  String get costEstimateJurisdictionLabel => 'Jurisdikcija';

  @override
  String get costEstimateAmountLabel => 'Ginčo suma (neprivaloma)';

  @override
  String get costEstimateAmountHint => 'pvz., 12500';

  @override
  String get costEstimateDescriptionLabel =>
      'Trumpai aprašykite situaciją (neprivaloma)';

  @override
  String get costEstimateB2bToggle => 'Kliento kvalifikavimo kortelė (B2B)';

  @override
  String get costEstimateB2bSubtitle =>
      'Glausta išvestis greitam gaunamo kliento rūšiavimui.';

  @override
  String get costEstimateSubmit => 'Įvertinti mano bylą';

  @override
  String get costEstimateDisclaimer =>
      'Tik apytikris įvertis – ne prognozė, garantija ar teisinė konsultacija. Tikrieji kaštai ir rezultatai kiekvienoje byloje skiriasi.';

  @override
  String get costEstimateCostsHeading => 'Numatomi kaštai';

  @override
  String get costEstimateCourtFee => 'Teismo / valstybės mokestis';

  @override
  String get costEstimateLawyerFee => 'Advokato honoraras';

  @override
  String get costEstimateTotal => 'Iš viso (apytiksliai)';

  @override
  String get costEstimateDuration => 'Laikas iki pirmojo sprendimo';

  @override
  String get costEstimateMonthsSuffix => 'mėn.';

  @override
  String get costEstimateFactorsFor => 'Jūsų naudai';

  @override
  String get costEstimateFactorsAgainst => 'Prieš jus';

  @override
  String get costEstimateStrengthWorth => 'Tikriausiai verta imtis';

  @override
  String get costEstimateStrengthContested =>
      'Ginčytina – gali baigtis bet kaip';

  @override
  String get costEstimateStrengthWeak => 'Silpna – elkitės atsargiai';
}
