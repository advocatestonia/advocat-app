// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Latvian (`lv`).
class AppLocalizationsLv extends AppLocalizations {
  AppLocalizationsLv([String locale = 'lv']) : super(locale);

  @override
  String get about => 'Par';

  @override
  String get aboutSection => 'PAR';

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
  String get accidents => 'Negadījumi';

  @override
  String get active => 'Aktīvas';

  @override
  String get activeCases => 'Aktīvās lietas';

  @override
  String get addedToAppeal => 'Pievienots apelācijai';

  @override
  String get agreeToTerms => 'Es piekrītu ';

  @override
  String get aiAnalysis => 'AI analīze';

  @override
  String get aiAssistant => 'AI juridiskais palīgs';

  @override
  String get aiChat => 'AI tērzēšana';

  @override
  String get all => 'Visas';

  @override
  String get alreadyHaveAccount => 'Jau ir konts? ';

  @override
  String get analyzing => 'Analizē…';

  @override
  String get aiAnalyzing => 'AI analizē';

  @override
  String get speakIntoMicHint =>
      'Speak into the microphone. Make sure microphone access is enabled.';

  @override
  String get aiErrorRateLimit =>
      'Pakalpojums uz brīdi ir pārslogots. Lūdzu, mēģiniet vēlreiz pēc 1–2 minūtēm.';

  @override
  String get aiErrorOverload =>
      'MI šobrīd ir aizņemts, lūdzu, mēģiniet vēlreiz pēc minūtes.';

  @override
  String freeLimitReached(int count) {
    return 'You have used all $count free AI messages. Upgrade to Legal Counsel for unlimited AI assistance!';
  }

  @override
  String get andWord => ' un ';

  @override
  String get appTitle => 'Advocat — Juridiskās informācijas rīks';

  @override
  String get appVersion => 'Lietotnes versija';

  @override
  String get appealFiled => 'Apelācija iesniegta';

  @override
  String get areYouAbsolutelySure => 'Vai esat pilnībā pārliecināts?';

  @override
  String get askAboutCase => 'Analizēt manu lietu';

  @override
  String get asylum => 'Patvērums';

  @override
  String get back => 'Atpakaļ';

  @override
  String get basic => 'Pamata';

  @override
  String get beforeYouBuy => 'Pirms pērkat';

  @override
  String get beforeYouWork => 'Pirms strādājat ar viņiem';

  @override
  String get camera => 'Kamera';

  @override
  String get cancel => 'Atcelt';

  @override
  String get caseDescription => 'Aprakstiet savu situāciju';

  @override
  String get caseDetail => 'Lietas detaļas';

  @override
  String get caseOverview => 'Šeit ir jūsu lietu pārskats';

  @override
  String get caseTitle => 'Lietas nosaukums';

  @override
  String get caseUpdated => 'Lieta atjaunināta';

  @override
  String get cases => 'Lietas';

  @override
  String get checkCompany => 'Pārbaudīt uzņēmumu';

  @override
  String get checkDeadlines => 'Pārbaudīt termiņus';

  @override
  String get checkVehicle => 'Pārbaudīt transportlīdzekli';

  @override
  String get checkerTitle => 'Pārbaudītājs';

  @override
  String get checkingErrors => 'Pārbauda kļūdas…';

  @override
  String get choosePlan => 'Izvēlēties plānu';

  @override
  String get closed => 'Slēgtas';

  @override
  String get companyName => 'Uzņēmuma nosaukums vai reģ. numurs';

  @override
  String get completed => 'Pabeigts';

  @override
  String get confirm => 'Apstiprināt';

  @override
  String get confirmPassword => 'Apstiprināt paroli';

  @override
  String get connectEmail => 'Savienot e-pastu';

  @override
  String get connectGmail => 'Savienot Gmail';

  @override
  String get connectOutlook => 'Savienot Outlook';

  @override
  String get connected => 'Savienots';

  @override
  String get contactSupport => 'Sazināties ar atbalstu';

  @override
  String get continueWithGoogle => 'Turpināt ar Google';

  @override
  String get appleComingSoon => 'Drīzumā';

  @override
  String get appleComingSoonMessage =>
      'Apple pieteikšanās būs pieejama drīzumā. Turpiniet ar Google vai e-pastu.';

  @override
  String get copyText => 'Kopēt tekstu';

  @override
  String get correspondence => 'Sarakste';

  @override
  String get couldNotLoadCases => 'Nevarēja ielādēt jūsu lietas';

  @override
  String get country => 'Valsts';

  @override
  String get createAccount => 'Izveidot kontu';

  @override
  String get createCase => 'Izveidot lietu';

  @override
  String get criminalCase => 'Krimināllieta';

  @override
  String get critical => 'Kritisks';

  @override
  String get currentPlan => 'Pašreizējais plāns';

  @override
  String get dataAndPrivacy => 'DATI UN PRIVĀTUMS';

  @override
  String get dataExportRequested =>
      'Datu eksports pieprasīts. Pārbaudiet savu e-pastu.';

  @override
  String daysRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dienas',
      one: '$count diena',
      zero: '$count dienu',
    );
    return '$_temp0';
  }

  @override
  String get deadlineReminders => 'Termiņu atgādinājumi';

  @override
  String get deadlineRemindersDesc => 'Saņemiet paziņojumus pirms termiņiem';

  @override
  String get deadlines => 'Termiņi';

  @override
  String get debtCollection => 'Parādu piedziņa';

  @override
  String get deleteAccount => 'Dzēst kontu';

  @override
  String get deleteAccountDesc => 'Neatsaucami noņemt jūsu kontu';

  @override
  String get deleteAccountDialogContent =>
      'Šī darbība ir neatgriezeniska un to nevar atsaukt. Visi jūsu dati, lietas un dokumenti tiks neatgriezeniski dzēsti.';

  @override
  String get deleteConfirm =>
      'Vai esat pārliecināts? Tas neatsaucami izdzēsīs visus jūsu datus.';

  @override
  String get demoHint => 'Demo: izmēģiniet numuru „908FBT“';

  @override
  String get demoModeDesc =>
      'Izpētiet lietotni ar paraugu datiem no reālas lietas';

  @override
  String get deportation => 'Deportācija';

  @override
  String get disclaimer =>
      'Tikai AI norādījumi — nav juridisks padoms. Vienmēr konsultējieties ar advokātu.';

  @override
  String get disclaimerFull =>
      'Šis ir AI palīgs, nevis advokāts. AI analīze var saturēt kļūdas. Vienmēr pārbaudiet ar kvalificētu juridisko speciālistu.';

  @override
  String get disconnect => 'Atvienot';

  @override
  String get discrimination => 'Diskriminācija';

  @override
  String get doNotBuy => 'Nepērciet';

  @override
  String get documents => 'Dokumenti';

  @override
  String documentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dokumenti',
      one: '$count dokuments',
      zero: '$count dokumentu',
    );
    return '$_temp0';
  }

  @override
  String get draftAppeal => 'Apelācijas projekts';

  @override
  String get editDraft => 'Rediģēt';

  @override
  String get editProfile => 'Rediģēt profilu';

  @override
  String get email => 'E-pasts';

  @override
  String get emailConnected => 'E-pasts savienots';

  @override
  String get emailDisconnected => 'E-pasts atvienots';

  @override
  String get emailIntegration => 'E-PASTA INTEGRĀCIJA';

  @override
  String get emailInvalid => 'Lūdzu, ievadiet derīgu e-pasta adresi';

  @override
  String get emailPrivacyNote =>
      'Mēs lasām tikai ar juridiskiem jautājumiem saistītus e-pastus. Jūsu personīgie e-pasti paliek privāti.';

  @override
  String get emailRequired => 'E-pasts ir nepieciešams';

  @override
  String get emergencyShield => 'Ārkārtas aizsardzība';

  @override
  String get error => 'Kļūda';

  @override
  String get exportDataDesc => 'Lejupielādēt visus lietu datus';

  @override
  String get exportDataDialogContent =>
      'Mēs sagatavosim visu jūsu datu lejupielādi, ieskaitot lietas, dokumentus un saraksti. Jūs saņemsiet e-pastu, kad tas būs gatavs.';

  @override
  String get exportMyData => 'Eksportēt manus datus';

  @override
  String get exportPdf => 'Eksportēt PDF';

  @override
  String get familyReunification => 'Gimeņu atkalapvienošanās';

  @override
  String get forgotPassword => 'Aizmirsāt paroli?';

  @override
  String get free => 'Bezmaksas';

  @override
  String get fullDefense => 'Advocat Pro';

  @override
  String get fullName => 'Pilns vārds';

  @override
  String get gallery => 'Galerija';

  @override
  String get generateAppeal => 'Ģenerēt apelāciju';

  @override
  String get getStarted => 'Sākt';

  @override
  String goodAfternoon(String name) {
    return 'Labdien, $name';
  }

  @override
  String goodEvening(String name) {
    return 'Labvakar, $name';
  }

  @override
  String goodMorning(String name) {
    return 'Labrīt, $name';
  }

  @override
  String goodNight(String name) {
    return 'Ar labu nakti, $name';
  }

  @override
  String get home => 'Sākums';

  @override
  String get important => 'Svarīgs';

  @override
  String get inProgress => 'Processā';

  @override
  String get informational => 'Informatīvs';

  @override
  String get inspection => 'Tehniskā apskate';

  @override
  String get insurance => 'Apdrošināšana';

  @override
  String issuesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Atrastas $count problēmas',
      one: 'Atrasta $count problēma',
      zero: 'Atrastas $count problēmas',
    );
    return '$_temp0';
  }

  @override
  String get laborDispute => 'Darba strīds';

  @override
  String get langEnglish => 'Angļu';

  @override
  String get langFinnish => 'Somu';

  @override
  String get langRussian => 'Krievu';

  @override
  String get language => 'Valoda';

  @override
  String lastActivity(String time) {
    return 'Pēdējā darbība: $time';
  }

  @override
  String get legalFighter => 'Juridiskais cīņītājs';

  @override
  String get legalSection => 'JURIDISKAIS';

  @override
  String get licensePlate => 'Numura zīme';

  @override
  String get loading => 'Ielādē…';

  @override
  String get logIn => 'Ienākt';

  @override
  String get loginFailed =>
      'Nederīgs e-pasts vai parole. Lūdzu, mēģiniet vēlreiz.';

  @override
  String get lost => 'Zaudēts';

  @override
  String get markComplete => 'Atzīmēt kā pabeigtu';

  @override
  String get mileage => 'Nobraukums';

  @override
  String get myCases => 'Manas lietas';

  @override
  String get nameRequired => 'Pilns vārds ir nepieciešams';

  @override
  String get newCase => 'Jauna lieta';

  @override
  String get next => 'Tālāk';

  @override
  String get noAccount => 'Nav konta? ';

  @override
  String get noCases => 'Vēl nav lietu';

  @override
  String get noCasesYet => 'Vēl nav lietu';

  @override
  String get noDeadlines => 'Nav termiņu — viss kārtībā!';

  @override
  String get noRecentActivity => 'Nav nesenas darbības';

  @override
  String get notifications => 'PAZIŅOJUMI';

  @override
  String get onboardingDesc1 =>
      'Advocat palīdz jums izprast savu juridisko situāciju. AI rīki analizē dokumentus, identificē iespējamās problēmas un sagatavo dokumentu projektus jūsu pārskatīšanai. Tā nav advokātu biroja — tas ir tehnoloģiju rīks jūsu lietas atbalstam.';

  @override
  String get onboardingDesc2 =>
      'Nofotografējiet jebkuru juridisku dokumentu. AI to nolasa vairākās valodās, izvelk galvenos datus un pārbauda atbilstību ES direktīvām un nacionālajiem likumiem.';

  @override
  String get onboardingDesc3 =>
      'Mūsu AI rīki pārbauda vairāk nekā 40 procesuālo prasību veidus. AI analīze var atklat problēmas, kurām nepieciešama uzmanība — piemēram, apkalpošanas valoda, procesuālie soļi un juridiskie termiņi. Vienmēr pārbaudiet ar kvalificētu advokātu.';

  @override
  String get onboardingDesc4 =>
      'AI sagatavo apelāciju, sūdzību un vēstuļu projektus ar juridiskām atsaucēm jūsu pārskatīšanai. Jūs izlemjat, ko iesniegt. Katrs dokuments jāpārskata kvalificētam juridiskajam speciālistam pirms iesniegšanas.';

  @override
  String get onboardingNext => 'Tālāk';

  @override
  String get onboardingSkip => 'Izlaist';

  @override
  String get onboardingTitle1 => 'AI balstīta juridiskā informācija';

  @override
  String get onboardingTitle2 => 'Skenējiet un analizējiet dokumentus';

  @override
  String get onboardingTitle3 => 'AI pārbauda iespējamās problēmas';

  @override
  String get onboardingTitle4 => 'Dokumentu projekti jūsu pārskatīšanai';

  @override
  String get openACase => 'Atvērt lietu';

  @override
  String get optional => '(neobligāti)';

  @override
  String get orDivider => 'vai';

  @override
  String get other => 'Cits';

  @override
  String get overdue => 'Kavēts';

  @override
  String get owners => 'Iepriekšējie īpašnieki';

  @override
  String get password => 'Parole';

  @override
  String get passwordRequired => 'Parole ir nepieciešama';

  @override
  String get passwordStrengthMedium => 'Vidēja';

  @override
  String get passwordStrengthStrong => 'Stipra';

  @override
  String get passwordStrengthWeak => 'Vāja';

  @override
  String get passwordTooShort => 'Parolei jābūt vismaz 8 rakstzīmju garai';

  @override
  String get passwordsDoNotMatch => 'Paroles nesakrīt';

  @override
  String get pendingDecision => 'Gaida lēmumu';

  @override
  String get perCheck => 'par pārbaudi';

  @override
  String get permanentlyDelete => 'Neatgriezeniski dzēst';

  @override
  String get policeMisconduct => 'Policijas pārkāpumi';

  @override
  String get popular => 'POPULĀRS';

  @override
  String get preferences => 'IESTATĪJUMI';

  @override
  String get preferredLanguage => 'Vēlamā valoda';

  @override
  String get pricePerCheck => '€4,99 par pārbaudi';

  @override
  String get privacyPolicy => 'Privātuma politikai';

  @override
  String get dpaTitle => 'Datu apstrādes līgums';

  @override
  String get dpaCheckoutGateTitle => 'Pirms jaunināšanas';

  @override
  String get dpaCheckoutGateBody =>
      'ES tiesību akti (VDAR 28. pants) nosaka, ka mums ir jāparaksta datu apstrādes līgums ar katru maksājošo klientu. Lūdzu, iepazīstieties ar to un piekrītiet.';

  @override
  String get dpaViewLink => 'Skatīt datu apstrādes līgumu';

  @override
  String get dpaCheckboxLabel =>
      'Esmu izlasījis un piekrītu datu apstrādes līgumam (v1.0).';

  @override
  String get dpaCancel => 'Atcelt';

  @override
  String get dpaAcceptAndContinue => 'Piekrist un turpināt';

  @override
  String get dpaOpenHint =>
      'Atveriet DAL vismaz vienu reizi, lai aktivizētu pogu “Piekrist”.';

  @override
  String get pro => 'Pro';

  @override
  String get pushNotifications => 'Push paziņojumi';

  @override
  String get rateUs => 'Novērtējiet mūs';

  @override
  String get rateAppComingSoon => 'Coming to app stores soon!';

  @override
  String get dataCopiedToClipboard => 'Data copied to clipboard';

  @override
  String get readingDocument => 'Lasa dokumentu…';

  @override
  String get recentActivity => 'Nesenā darbība';

  @override
  String get referenceNumber => 'Atsauces numurs';

  @override
  String get registerFailed =>
      'Reģistrācija neizdevās. Lūdzu, mēģiniet vēlreiz.';

  @override
  String get reportFraud => 'Ziņot par krāpšanu';

  @override
  String get requestExport => 'Pieprasīt eksportu';

  @override
  String get researchingLaw => 'Pēta piemērojamos likumus…';

  @override
  String get resetPasswordFailed =>
      'Neizdevās nosūtīt atiestatīšanas saiti. Lūdzu, mēģiniet vēlreiz.';

  @override
  String get resetPasswordSent =>
      'Paroles atiestatīšanas saite nosūtīta uz jūsu e-pastu.';

  @override
  String get residencePermit => 'Uzturēšanās atļauja';

  @override
  String get manageSubscription => 'Pārvaldīt abonementu';

  @override
  String get restorePurchases => 'Atjaunot pirkumus';

  @override
  String get retry => 'Mēģināt vēlreiz';

  @override
  String get reviewWarning =>
      'Rūpīgi pārskatiet pirms nosūtīšanas. Jūs esat atbildīgs par saturu.';

  @override
  String get riskHigh => 'Augsts risks — izvairieties';

  @override
  String get riskLow => 'Droši sadarboties';

  @override
  String get riskMedium => 'Rīkojieties piesardzīgi';

  @override
  String get safeToBuy => 'Droši pirkt';

  @override
  String get saveAndAnalyze => 'Saglabāt un analizēt';

  @override
  String get saveDraft => 'Saglabāt';

  @override
  String get saveWithAnnual => 'Ietaupiet 25% ar gada maksājumu';

  @override
  String get scan => 'Skenēt';

  @override
  String get scanDocument => 'Skenēt dokumentu';

  @override
  String get searchCases => 'Meklēt lietas…';

  @override
  String get selectCountry => 'Izvēlēties valsti';

  @override
  String get selectLanguage => 'Izvēlēties valodu';

  @override
  String get sendViaEmail => 'Sūtīt pa e-pastu';

  @override
  String get settings => 'Iestatījumi';

  @override
  String get signIn => 'Pierakstīties';

  @override
  String get signInLink => 'Ienākt';

  @override
  String get signInSubtitle => 'Pierakstieties, lai piekļūtu savām lietām';

  @override
  String get signOut => 'Izrakstīties';

  @override
  String get signOutConfirm => 'Vai tiešām vēlaties izrakstīties?';

  @override
  String get signUp => 'Izveidot kontu';

  @override
  String get signUpLink => 'Reģistrēties';

  @override
  String get socialBenefits => 'Sociālie pabalsti';

  @override
  String get someConcerns => 'Dažas bažas';

  @override
  String get startFirstCase => 'Sāciet savu pirmo lietu';

  @override
  String step(int current, int total) {
    return '$current. solis no $total';
  }

  @override
  String get stolen => 'Zādzības pārbaude';

  @override
  String get subscription => 'Abonements';

  @override
  String get syncLegalCorrespondence => 'Sinhronizēt juridisko sarakstes';

  @override
  String get syncNow => 'Sinhronizēt tagad';

  @override
  String get tenantRights => 'Īrnieku tiesības';

  @override
  String get termsOfService => 'Pakalpojumu noteikumiem';

  @override
  String get termsRequired => 'Jums jāpiekrīt Pakalpojumu noteikumiem';

  @override
  String get timeline => 'Laika līnija';

  @override
  String get tryDemoMode => 'Izmēģināt demo režīmu';

  @override
  String get typeDeleteToConfirm =>
      'Ievadiet DELETE, lai apstiprinātu pastāvīgu konta dzēšanu.';

  @override
  String get typeMessage => 'Ierakstiet ziņojumu…';

  @override
  String get upcoming => 'Gaidāms';

  @override
  String get uploadDocument => 'Augšupielādēt dokumentu';

  @override
  String urgentDeadline(String title) {
    return 'Steidzami: $title';
  }

  @override
  String get useInAppeal => 'Izmantot apelācijā';

  @override
  String get vehicleChecker => 'Transportlīdzekļa pārbaude';

  @override
  String get vehicleChecks => 'Stāvokļa pārbaudes';

  @override
  String get vehicleColor => 'Krāsa';

  @override
  String get vehicleMake => 'Marka';

  @override
  String get vehicleModel => 'Modelis';

  @override
  String get vehicleYear => 'Gads';

  @override
  String get version => 'Versija';

  @override
  String get victimSupport => 'Upuru atbalsts';

  @override
  String get viewAll => 'Skatīt visas';

  @override
  String get vinNumber => 'VIN numurs';

  @override
  String get welcomeBack => 'Laipni lūdzam atpakaļ';

  @override
  String get whatAreMyOptions => 'Kādas ir manas iespējas?';

  @override
  String get won => 'Uzvarēts';

  @override
  String get documentVault => 'Dokumentu glabātuve';

  @override
  String get secureDocumentStorage => 'Droša dokumentu glabāšana';

  @override
  String get secureDocumentStorageDesc =>
      'Droši glabājiet savus svarīgos juridiskos dokumentus. Visi faili ir pilnībā šifrēti.';

  @override
  String get addDocument => 'Pievienot dokumentu';

  @override
  String get chooseHowToAdd => 'Izvēlieties, kā pievienot dokumentu';

  @override
  String get uploadFile => 'Augšupielādēt failu';

  @override
  String get uploadFileDesc => 'Izvēlieties PDF vai attēlu no savas ierīces';

  @override
  String get scanDocumentDesc => 'Nofotografējiet savu dokumentu';

  @override
  String get createNote => 'Izveidot piezīmi';

  @override
  String get createNoteDesc =>
      'Uzrakstiet piezīmi vai pierakstiet svarīgas detaļas';

  @override
  String get knowYourRights => 'Zini savas tiesības';

  @override
  String get stoppedByPolice => 'Apturēts policija';

  @override
  String get stoppedByPoliceDesc => 'Jūsu tiesības policijas kontroles laikā';

  @override
  String get deportationNotice => 'Deportācijas paziņojums';

  @override
  String get deportationNoticeDesc =>
      'Soļi, lai apstrīdētu izraidīšanas rīkojumu';

  @override
  String get workplaceRights => 'Darba tiesības';

  @override
  String get workplaceRightsDesc => 'Darba tiesību aizsardzība Somijā';

  @override
  String get tenantRightsDesc => 'Mājokļa un īres aizsardzība';

  @override
  String get immigrationDetention => 'Imigrācijas aizturēšana';

  @override
  String get immigrationDetentionDesc => 'Jūsu tiesības, ja esat aizturēts';

  @override
  String get discriminationDesc =>
      'Kā ziņot par diskrimināciju un cīnīties pret to';

  @override
  String get scenarioNotFound => 'Scenārijs nav atrasts';

  @override
  String get youHaveRightTo => 'Jums ir tiesības:';

  @override
  String get youMust => 'Jums jā:';

  @override
  String get immediateSteps => 'Tūlītēji soļi:';

  @override
  String get yourRights => 'Jūsu tiesības:';

  @override
  String get basicRights => 'Pamattiesības:';

  @override
  String get yourRightsAsTenant => 'Jūsu tiesības kā īrniekam:';

  @override
  String get yourRightsInDetention => 'Jūsu tiesības aizturēšanas laikā:';

  @override
  String get howToAct => 'Kā rīkoties:';

  @override
  String get rightKnowWhyStopped => 'Zināt, kāpēc esat apturēts';

  @override
  String get rightRemainSilent => 'Klusēt (jums jāidentificē sevi)';

  @override
  String get rightAskInterpreter => 'Lūgt tulku';

  @override
  String get rightContactLawyer =>
      'Sazināties ar advokātu pirms nopratināšanas';

  @override
  String get rightRecordEncounter => 'Ierakstīt notikumu (publiskās vietās)';

  @override
  String get mustProvideName => 'Norādīt savu vārdu un dzimšanas datumu';

  @override
  String get mustShowId => 'Uzrādīt personas apliecību, ja tāda ir';

  @override
  String get mustNotResist => 'Fiziski nepretoties';

  @override
  String get doNotIgnoreNotice =>
      'NEIGNORĒJIET paziņojumu — termiņi ir strikti';

  @override
  String get noteAppealDeadline =>
      'Atzīmējiet apelācijas termiņu (parasti 30 dienas)';

  @override
  String get contactLawyerImmediately => 'Nekavējoties sazinieties ar advokātu';

  @override
  String get applyLegalAid =>
      'Pieteikties juridiskajai palīdzībai, ja nepieciešams';

  @override
  String get rightAppealAdmin => 'Tiesības pārsūdzēt Administratīvajā tiesā';

  @override
  String get rightLegalRep => 'Tiesības uz juridisko pārstāvību';

  @override
  String get rightInterpreter => 'Tiesības uz tulku';

  @override
  String get rightStayDuringAppeal =>
      'Tiesības palikt apelācijas laikā (vairumā gadījumu)';

  @override
  String get minimumWage => 'Minimālā alga saskaņā ar koplīgumu';

  @override
  String get workingTimeLimits =>
      'Darba laika ierobežojumi (maks. 8 st./dienā, 40 st./nedēļā)';

  @override
  String get annualLeave =>
      'Ikgadējais atvaļinājums (vismaz 2 dienas par katru nostrādāto mēnesi)';

  @override
  String get sickLeave => 'Slimības pabalsts';

  @override
  String get safeWorkingConditions => 'Droši darba apstākļi';

  @override
  String get writtenRentalAgreement => 'Nepieciešams rakstisks īres līgums';

  @override
  String get securityDeposit => 'Drošības nauda — maks. 3 mēnešu īre';

  @override
  String get landlordNotice => 'Izīrētājam jābrīdina (3–6 mēneši)';

  @override
  String get rightHabitableDwelling => 'Tiesības uz apdzīvojamu mājokli';

  @override
  String get protectionUnjustEviction =>
      'Aizsardzība pret nepamatotu izlikšanu';

  @override
  String get rightKnowDetentionReason => 'Tiesības zināt aizturēšanas iemeslu';

  @override
  String get rightContactLawyerDetention => 'Tiesības sazināties ar advokātu';

  @override
  String get rightContactEmbassy => 'Tiesības sazināties ar savu vēstniecību';

  @override
  String get rightChallengeDetention => 'Tiesības apstrīdēt aizturēšanu tiesā';

  @override
  String get rightHumaneTreatment =>
      'Tiesības uz humānu izturēšanos un medicīnisko aprūpi';

  @override
  String get documentIncident =>
      'Dokumentējiet incidentu (datums, laiks, liecinieki)';

  @override
  String get fileComplaintOmbudsman =>
      'Iesniedziet sūdzību Nediskriminācijas ombudam';

  @override
  String get contactLegalAidOffice =>
      'Sazinieties ar juridiskās palīdzības biroju';

  @override
  String get reportToPolice =>
      'Ziņojiet policijai, ja tas ir krimināli (draudi, uzbrukums)';

  @override
  String get legalAidCalculator => 'Juridiskās palīdzības kalkulators';

  @override
  String checkEligibility(String country) {
    return 'Pārbaudiet savu tiesību uz juridisko palīdzību: $country';
  }

  @override
  String get estimateDisclaimer =>
      'Šis ir tikai novērtējums. Faktisko tiesību nosaka Juridiskās palīdzības birojs.';

  @override
  String get monthlyIncome => 'Ikmēneša ienākumi (EUR)';

  @override
  String get totalAssets => 'Kopējie aktīvi (EUR)';

  @override
  String get numberOfDependents => 'Apgādājamo skaits';

  @override
  String get calculateEligibility => 'Aprēķināt tiesības';

  @override
  String get likelyEligible => 'Visticamāk atbilstošs';

  @override
  String get mayNotQualify => 'Iespējams, neatbilst';

  @override
  String get fullFreeLegalAid =>
      'Jūs, visticamāk, atbilstat pilnīgi bezmaksas juridiskajai palīdzībai (bez līdzmaksājuma).';

  @override
  String legalAidWithCopay(String percent) {
    return 'Jūs, iespējams, atbilstat juridiskajai palīdzībai ar līdzmaksājumu $percent%.';
  }

  @override
  String get mayNotQualifyDesc =>
      'Saskaņā ar šo novērtējumu jūs, iespējams, neatbilstat valsts juridiskajai palīdzībai. Apsveriet konsultāciju ar privātu advokātu vai juridisko klīniku.';

  @override
  String get couldNotLoadDeadlines => 'Nevarēja ielādēt termiņus';

  @override
  String get noUpcomingDeadlines => 'Nav gaidāmu termiņu';

  @override
  String get allClearDeadlines =>
      'Viss kārtībā! Jauni termiņi parādīsies šeit, kad tie tiks noteikti.';

  @override
  String get nothingOverdue => 'Nekas nav kavēts';

  @override
  String get greatJobDeadlines => 'Lielisks darbs, sekojot saviem termiņiem.';

  @override
  String get noCompletedDeadlines => 'Nav pabeigtu termiņu';

  @override
  String get completedDeadlinesDesc => 'Pabeigti termiņi tiks parādīti šeit.';

  @override
  String get daysLate => 'dienas kavēts';

  @override
  String get days => 'dienas';

  @override
  String get fromDocument => 'No dokumenta';

  @override
  String get couldNotLoadCase => 'Nevarēja ielādēt lietas detaļas';

  @override
  String get typeLabel => 'Veids';

  @override
  String get nationality => 'Tautība';

  @override
  String get migriReference => 'Migri atsauce';

  @override
  String get courtCaseNo => 'Tiesas lietas Nr.';

  @override
  String get created => 'Izveidots';

  @override
  String get citizenship => 'Pilsonība';

  @override
  String get workPermit => 'Darba atļauja';

  @override
  String get noDocumentsYet => 'Vēl nav augšupielādētu dokumentu';

  @override
  String get noUpcomingDeadlinesShort => 'Nav gaidāmu termiņu';

  @override
  String get caseCreated => 'Lieta izveidota';

  @override
  String get decisionReceived => 'Lēmums saņemts';

  @override
  String get appealDeadline => 'Apelācijas termiņš';

  @override
  String get hearingScheduled => 'Tiesas sēde ieplānota';

  @override
  String get late => 'kavēts';

  @override
  String get pending => 'Gaida';

  @override
  String get processing => 'Apstrādā';

  @override
  String get ready => 'Gatavs';

  @override
  String get failed => 'Neizdevās';

  @override
  String get analyzed => 'Analizēts';

  @override
  String get noDocumentsScanHint =>
      'Vēl nav dokumentu. Skenējiet vai augšupielādējiet.';

  @override
  String get inCourt => 'Tiesā';

  @override
  String get appeal => 'Apelācija';

  @override
  String get caseTimeline => 'Lietas laika līnija';

  @override
  String get couldNotLoadTimeline => 'Nevarēja ielādēt laika līniju';

  @override
  String get noEventsYet => 'Vēl nav notikumu';

  @override
  String get activityWillAppear =>
      'Darbība parādīsies šeit, lietai progresējot.';

  @override
  String caseCreatedDesc(String title) {
    return 'Lieta „$title“ tika izveidota.';
  }

  @override
  String get decisionReceivedDesc => 'Šai lietai saņemts oficiāls lēmums.';

  @override
  String get appealDeadlineSet => 'Apelācijas termiņš noteikts';

  @override
  String appealDeadlineDesc(String date) {
    return 'Apelācija jāiesniedz līdz $date.';
  }

  @override
  String hearingScheduledDesc(String date) {
    return 'Tiesas sēde ieplānota $date.';
  }

  @override
  String get caseInfoUpdated => 'Lietas informācija pēdējo reizi atjaunināta.';

  @override
  String get noEventsForFilter => 'Šim filtram neatbilst neviens notikums';

  @override
  String get timelineFilterAll => 'Visi';

  @override
  String get timelineFilterEmails => 'E-pasti';

  @override
  String get timelineFilterConsilium => 'MI lēmumi';

  @override
  String get timelineFilterDeadlines => 'Termiņi';

  @override
  String get timelineFilterNotes => 'Piezīmes';

  @override
  String get timelineEventEmailIn => 'Saņemts e-pasts';

  @override
  String get timelineEventEmailOut => 'Nosūtīts e-pasts';

  @override
  String get timelineEventConsiliumDecision => 'MI lēmums';

  @override
  String get timelineEventDeadlineSet => 'Termiņš';

  @override
  String get timelineEventDocUploaded => 'Dokuments';

  @override
  String get timelineEventPhaseChange => 'Posma maiņa';

  @override
  String get timelineEventManualNote => 'Piezīme';

  @override
  String get timelineJustNow => 'Tikko';

  @override
  String timelineMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pirms $count minūtēm',
      one: 'pirms 1 minūtes',
    );
    return '$_temp0';
  }

  @override
  String timelineHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pirms $count stundām',
      one: 'pirms 1 stundas',
    );
    return '$_temp0';
  }

  @override
  String timelineDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pirms $count dienām',
      one: 'pirms 1 dienas',
    );
    return '$_temp0';
  }

  @override
  String get documentAnalysis => 'Dokumenta analīze';

  @override
  String get exportAsPdf => 'Eksportēt kā PDF';

  @override
  String get pdfExportComingSoon => 'PDF eksports drīzumā';

  @override
  String get analysisFailedRetry =>
      'Analīze neizdevās. Lūdzu, mēģiniet vēlreiz.';

  @override
  String get somethingWentWrong => 'Kaut kas nogāja greizi';

  @override
  String get genericError => 'Kaut kas nogāja greizi. Mēģiniet vēlreiz.';

  @override
  String get retryAnalysis => 'Atkārtot analīzi';

  @override
  String issuesFoundInDocument(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dokumentā atrastas $count problēmas',
      one: 'Dokumentā atrasta $count problēma',
      zero: 'Dokumentā atrastas $count problēmas',
    );
    return '$_temp0';
  }

  @override
  String get severityOverview => 'Nopietnības pārskats';

  @override
  String get issuesFoundHeader => 'Atrastās problēmas';

  @override
  String generateAppealWithIssues(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ģenerēt apelāciju ($count problēmas)',
      one: 'Ģenerēt apelāciju ($count problēma)',
      zero: 'Ģenerēt apelāciju ($count problēmas)',
    );
    return '$_temp0';
  }

  @override
  String get analyzingContent => 'Analizē saturu…';

  @override
  String get documentProcessedOk => 'Dokuments veiksmīgi apstrādāts';

  @override
  String get noSignificantIssues =>
      'Šajā dokumentā netika konstatētas būtiskas problēmas.';

  @override
  String get cameraPermissionRequired => 'Nepieciešama kameras atļauja';

  @override
  String get cameraPermissionDesc =>
      'Piešķiriet kameras piekļuvi, lai skenētu dokumentus, vai izmantojiet galeriju.';

  @override
  String get openSettings => 'Atvērt iestatījumus';

  @override
  String get alignDocument => 'Novietojiet dokumentu rāmī';

  @override
  String pageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lapas',
      one: '$count lapa',
      zero: '$count lapu',
    );
    return '$_temp0';
  }

  @override
  String get preview => 'Priekšskatījums';

  @override
  String pageNumber(int number) {
    return '$number. lapa';
  }

  @override
  String get done => 'Gatavs';

  @override
  String get retake => 'Uzņemt vēlreiz';

  @override
  String get useThisPhoto => 'Izmantot šo fotoattēlu';

  @override
  String get addPage => 'Pievienot lapu';

  @override
  String uploadingPercent(int percent) {
    return 'Augšupielādē… $percent%';
  }

  @override
  String get preparingUpload => 'Gatavo augšupielādi…';

  @override
  String get documentUploadedSuccess => 'Dokuments veiksmīgi augšupielādēts';

  @override
  String pagesUploadedSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lapas veiksmīgi augšupielādētas',
      one: '$count lapa veiksmīgi augšupielādēta',
      zero: '$count lapas veiksmīgi augšupielādētas',
    );
    return '$_temp0';
  }

  @override
  String get uploadFailed =>
      'Augšupielāde neizdevās. Lūdzu, pārbaudiet savienojumu un mēģiniet vēlreiz.';

  @override
  String get capturePhotoFailed =>
      'Neizdevās uzņemt fotoattēlu. Lūdzu, mēģiniet vēlreiz.';

  @override
  String get readingText => 'Lasa tekstu…';

  @override
  String get draftDocument => 'Dokumenta projekts';

  @override
  String get saveChanges => 'Saglabāt izmaiņas';

  @override
  String get editDocument => 'Rediģēt dokumentu';

  @override
  String get generatingDraft => 'Ģenerē jūsu projektu…';

  @override
  String get generatingDraftDesc =>
      'AI gatavo juridisku dokumentu, pamatojoties uz jūsu lietas datiem un atlasītajām problēmām.';

  @override
  String get failedToGenerateDraft =>
      'Neizdevās ģenerēt projektu. Lūdzu, mēģiniet vēlreiz.';

  @override
  String get changesSaved => 'Izmaiņas saglabātas';

  @override
  String get copiedToClipboard => 'Nokopēts starpliktuvē';

  @override
  String get emailComingSoon => 'E-pasta sūtīšana drīzumā';

  @override
  String get reviewBeforeSending =>
      'Rūpīgi pārskatiet pirms nosūtīšanas. Jūs esat atbildīgs par šī dokumenta saturu.';

  @override
  String get noContentAvailable => 'Saturs nav pieejams';

  @override
  String get save => 'Saglabāt';

  @override
  String get edit => 'Rediģēt';

  @override
  String get pdf => 'PDF';

  @override
  String get copy => 'Kopēt';

  @override
  String get appealDraft => 'Apelācijas projekts';

  @override
  String selected(int count) {
    return '$count atlasīts';
  }

  @override
  String get deleteSelected => 'Dzēst atlasītos';

  @override
  String deleteDocumentsConfirm(int count) {
    return 'Dzēst $count dokumentu(s)?';
  }

  @override
  String get delete => 'Dzēst';

  @override
  String get analyzeSelected => 'Analizēt atlasītos';

  @override
  String get batchAnalysisStarting => 'Sākas pakešu analīze…';

  @override
  String get switchToList => 'Pārslēgt uz sarakstu';

  @override
  String get switchToGrid => 'Pārslēgt uz režģi';

  @override
  String get scanNew => 'Skenēt jaunu';

  @override
  String get noDocumentsYetScan => 'Vēl nav dokumentu';

  @override
  String get scanFirstDocumentHint =>
      'Noskenējiet savu pirmo dokumentu, lai AI to analizētu kļūdu meklēšanai un apelāciju ģenerēšanai.';

  @override
  String get failedToLoadDocuments => 'Neizdevās ielādēt dokumentus';

  @override
  String get emailIntegrationTitle => 'E-pasta integrācija';

  @override
  String get connectYourEmail => 'Pievienojiet e-pastu';

  @override
  String get connectYourEmailDesc =>
      'Pievienojiet e-pastu, lai automātiski noteiktu un sakārtotu ar jūsu lietām saistīto juridisko saraksti.';

  @override
  String get legalEmails => 'Juridiskie e-pasti';

  @override
  String get unlinkedEmails => 'Nesaistīti e-pasti';

  @override
  String get noLegalEmailsYet => 'Juridisku e-pastu vēl nav';

  @override
  String get legalEmailsWillAppear =>
      'Šeit parādīsies kā juridiski klasificētie e-pasti.';

  @override
  String get assignToCase => 'Piesaistīt lietai';

  @override
  String get disconnectEmail => 'Atvienot e-pastu';

  @override
  String get disconnectEmailConfirm =>
      'Automātiskā e-pasta sinhronizācija tiks apturēta. Iepriekš sinhronizētie e-pasti paliks jūsu lietās.';

  @override
  String get gmailReauthBannerBody =>
      'Advocat v2.1 lasa jūsu iesūtni, lai sagatavotu atbildes; piekļuvi varat atsaukt jebkurā laikā. Atkārtoti savienojiet Gmail, lai iespējotu proaktīvu šķirošanu.';

  @override
  String get gmailReauthBannerCta => 'Atkārtoti autorizēt';

  @override
  String connectedTo(String email) {
    return 'Savienots ar $email';
  }

  @override
  String lastSynced(String time) {
    return 'Sinhronizēts: $time';
  }

  @override
  String get filterByType => 'Filtrēt pēc veida';

  @override
  String get noCasesMatchSearch => 'Nav atrastu lietu';

  @override
  String get failedToLoadCases => 'Neizdevās ielādēt lietas';

  @override
  String get monthly => 'Mēneša';

  @override
  String get annual => 'Gada';

  @override
  String get saveTwentyFivePercent => 'Ietaupiet 25%';

  @override
  String get mostPopular => 'POPULĀRĀKAIS';

  @override
  String get oneCaseActive => '1 aktīva lieta';

  @override
  String get threeCasesActive => '3 aktīvas lietas';

  @override
  String get unlimitedCases => 'Neierobežotas lietas';

  @override
  String get threeDocScans => '3 dokumentu skenēšanas';

  @override
  String get twentyDocScans => '20 dokumentu skenēšanas';

  @override
  String get unlimitedDocScans => 'Neierobežota dokumentu skenēšana';

  @override
  String get basicAiAnalysis => 'Pamata MI analīze';

  @override
  String get fullAiAnalysis => 'Pilna MI analīze';

  @override
  String get draftGeneration => 'Melnrakstu ģenerēšana';

  @override
  String get priorityProcessing => 'Prioritāra apstrāde';

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
  String get forever => 'mūžīgi';

  @override
  String get perMonth => '/mēn.';

  @override
  String get perYear => '/gadā';

  @override
  String get checkingPurchases => 'Pārbauda iepriekšējos pirkumus…';

  @override
  String get noPreviousPurchases => 'Iepriekšēji pirkumi nav atrasti.';

  @override
  String get chatWelcomeMessage =>
      'Sveiki! Es esmu Advocat — jūsu AI juridiskais palīgs. Es sniedzu juridisku informāciju, nevis juridiskas konsultācijas. Kādā juridiskā jautājumā varu palīdzēt?';

  @override
  String get copySummary => 'Kopēt kopsavilkumu';

  @override
  String get caseSummaryCopied => 'Lietas kopsavilkums nokopēts';

  @override
  String get openCase => 'Atvērt lietu';

  @override
  String get viewFull => 'Skatīt pilnībā';

  @override
  String get draftCopiedToClipboard => 'Melnraksts nokopēts';

  @override
  String get reportMileageFraud => 'Ziņot par nobraukuma viltošanu';

  @override
  String get reportMileageFraudDesc =>
      'Tiks izveidots krāpšanas ziņojums, pamatojoties uz transportlīdzekļa pārbaudes datiem. Varat arī atvērt juridisku lietu.';

  @override
  String get reportAndOpenCase => 'Ziņot un atvērt lietu';

  @override
  String get caseCreationComingSoon =>
      'Lietas izveide ar aizpildītiem datiem drīzumā';

  @override
  String get failedToCreateCaseRetry =>
      'Neizdevās izveidot lietu. Mēģiniet vēlreiz.';

  @override
  String get takePhotoInstead => 'Nofotografēt';

  @override
  String get deleteCase => 'Dzēst lietu';

  @override
  String deleteCaseConfirm(String title) {
    return 'Vai tiešām vēlaties dzēst „$title“? Šo darbību nevar atcelt.';
  }

  @override
  String get haveQuestionsAi => 'Ir jautājumi? Jautājiet MI';

  @override
  String get cookiePolicy => 'Sīkdatņu politika';

  @override
  String get aiDisclaimer => 'MI atruna';

  @override
  String get aiDisclaimerCompact =>
      'Advocat ir AI sniegta juridiska informācija, nevis juridiska konsultācija. Pirms rīkojaties, pārbaudiet to pie licencēta jurista.';

  @override
  String get aiDisclaimerFullTitle => 'Svarīgi: kā darbojas Advocat';

  @override
  String get aiDisclaimerFullBody =>
      'Advocat ir mākslīgā intelekta rīks, kas sniedz juridisku informāciju, nevis juridiskas konsultācijas. Saskaņā ar ES Mākslīgā intelekta aktu (50. pants) mums skaidri jāpasaka: jūs sazināties ar AI, nevis ar cilvēku — juristu.\n\nAdvocat nav advokātu birojs. Mēs neesam licencēti advokāti saskaņā ar Igaunijas Advokatuuriseadus vai Somijas Asianajajalaki, un uz jūsu sarunām ar šo rīku neattiecas advokāta un klienta saziņas konfidencialitāte. Pirms paļaujaties uz jebkuru atbildi — lai iesniegtu apelāciju, parakstītu līgumu vai rīkotos termiņā — pārbaudiet to pie licencēta jurista savā jurisdikcijā.';

  @override
  String get aiDisclaimerExpand => 'Uzzināt vairāk';

  @override
  String get aiDisclaimerDismiss => 'Labi, sapratu';

  @override
  String get dataPrivacyConsent => 'Datu konfidencialitātes piekrišana';

  @override
  String get gdprIntro =>
      'Lai sniegtu MI juridisko palīdzību, mēs apstrādājam jūsu datus saskaņā ar GDPR (ES 2016/679). Turpinot jūs piekrītat:';

  @override
  String get gdprChat => 'Tērzēšanas ziņojumu apstrāde ar MI';

  @override
  String get gdprDocs => 'Augšupielādēto dokumentu analīze';

  @override
  String get gdprStorage => 'Šifrēta lietu datu glabāšana';

  @override
  String get gdprDelete => 'Tiesības jebkurā laikā dzēst savus datus';

  @override
  String get gdprFooter =>
      'Jūsu dati ir šifrēti un nekad netiek kopīgoti ar trešajām pusēm. Varat atsaukt piekrišanu un dzēst visus datus Iestatījumos.';

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
  String get decline => 'Noraidīt';

  @override
  String get iAgree => 'Piekrītu';

  @override
  String get iAgreeToThe => 'Es piekrītu ';

  @override
  String get orWord => 'vai';

  @override
  String get english => 'Angļu';

  @override
  String get russian => 'Krievu';

  @override
  String get finnish => 'Somu';

  @override
  String successSubscribed(String plan) {
    return 'Abonements $plan veiksmīgi aktivizēts!';
  }

  @override
  String paymentFailed(String error) {
    return 'Maksājums neizdevās: $error';
  }

  @override
  String get whatToDo => 'Ko darīt';

  @override
  String get getHelp => 'Saņemt palīdzību';

  @override
  String get share => 'Kopīgot';

  @override
  String get didYouKnow => 'Vai zinājāt?';

  @override
  String get mustKnow => 'Jāzina obligāti';

  @override
  String get goodToKnow => 'Noderīgi zināt';

  @override
  String get sentFromAdvocat => 'Nosūtīts no Advocat lietotnes';

  @override
  String get policeActionStayCalm =>
      'Esiet mierīgs un turiet rokas redzamā vietā';

  @override
  String get policeActionAskWhy => 'Jautājiet ierēdnim, kāpēc jūs apturēja';

  @override
  String get policeActionProvideName =>
      'Norādiet savu vārdu un dzimšanas datumu';

  @override
  String get policeActionWantLawyer =>
      'Skaidri paziņojiet: „Es vēlos advokātu pirms jebkādiem jautājumiem“';

  @override
  String get policeActionAskInterpreter => 'Ja nepieciešams, lūdziet tulku';

  @override
  String get policeActionNoteBadge =>
      'Pierakstiet ierēdņa vārdu un dienesta numuru';

  @override
  String get policeFactMustTellReason =>
      'Somijā policijai ir jāpasaka iemesls, kāpēc jūs apturēja. Ja viņi to nedara, jūs varat jautāt — un viņiem ir juridisks pienākums paskaidrot.';

  @override
  String get policeFactCanRecord =>
      'Jūs varat ierakstīt mijiedarbību ar policiju publiskās vietās Somijā. To aizsargā vārda brīvība.';

  @override
  String get contactFinnishLegalAid => 'Somijas juridiskā palīdzība';

  @override
  String get contactNonDiscriminationOmbudsman => 'Nediskriminācijas ombuds';

  @override
  String get deportationDeadlineAppeal =>
      'Apelācija Administratīvajā tiesā — parasti 30 dienas pēc paziņošanas';

  @override
  String get deportationDeadlineLegalAid =>
      'Piesakieties juridiskajai palīdzībai — dariet to NEKAVĒJOTIES';

  @override
  String get deportationFactStayDuringAppeal =>
      'Somijā jums parasti ir tiesības palikt valstī, kamēr jūsu apelācija tiek izskatīta. Deportāciju nevar veikt aktīvas apelācijas laikā vairumā gadījumu.';

  @override
  String get contactRefugeeAdviceCentre => 'Somijas Bēgļu konsultāciju centrs';

  @override
  String get contactAdminCourtHelsinki => 'Helsinku Administratīvā tiesa';

  @override
  String get workplaceActionKeepContract => 'Saglabājiet darba līguma kopijas';

  @override
  String get workplaceActionTrackHours => 'Patstāvīgi fiksējiet darba stundas';

  @override
  String get workplaceActionReportUnsafe =>
      'Ziņojiet par nedrošiem apstākļiem darba aizsardzības iestādei';

  @override
  String get workplaceActionJoinUnion =>
      'Iestājieties arodbiedrībā aizsardzībai';

  @override
  String get workplaceActionContactAuthority =>
      'Ja nepieciešams, sazinieties ar Darba aizsardzības iestādi';

  @override
  String get workplaceFactCollectiveWage =>
      'Somijā koplīgumi nosaka minimālās algas pa nozarēm — nav vienas valsts minimālās algas. Jūsu darba devējam jāievēro jūsu nozares koplīgums.';

  @override
  String get workplaceFactOralContract =>
      'Pat bez rakstiska līguma jums Somijā ir pilnas darbinieka tiesības. Mutiska vienošanās ir tikpat juridiski saistoša.';

  @override
  String get contactOccupationalSafety => 'Darba aizsardzības iestāde';

  @override
  String get contactTradeUnionSAK => 'Arodbiedrību konsultācijas (SAK)';

  @override
  String get tenantActionWrittenAgreement =>
      'Vienmēr noslēdziet rakstisku īres līgumu';

  @override
  String get tenantActionDocumentCondition =>
      'Dokumentējiet dzīvokļa stāvokli iebraukšanas brīdī (fotogrāfijas)';

  @override
  String get tenantActionReportMaintenance =>
      'Ziņojiet par uzturēšanas problēmām rakstiski';

  @override
  String get tenantActionNoIllegalEviction =>
      'Nekad nepiekrītiet nelikumīgai izlikšanai — tiesai jālemj';

  @override
  String get tenantActionContactAdvisory =>
      'Strīdu gadījumā sazinieties ar īrnieku konsultāciju dienestu';

  @override
  String get tenantFactNoEvictionWithoutCourt =>
      'Izīrētājs Somijā nevar jūs izlikt bez tiesas lēmuma, pat ja īres līgums ir beidzies. Slēdzeņu maiņa vai komunālo pakalpojumu atslēgšana ir nelikumīga.';

  @override
  String get contactTenantsAssociation => 'Somijas Īrnieku apvienība';

  @override
  String get contactConsumerDisputesBoard => 'Patērētāju strīdu komisija';

  @override
  String get detentionActionAskDecision =>
      'Nekavējoties pieprasiet rakstisku aizturēšanas lēmumu';

  @override
  String get detentionActionRequestLawyer =>
      'Pieprasiet sazināties ar advokātu';

  @override
  String get detentionActionContactEmbassy =>
      'Sazinieties ar savu vēstniecību vai konsulātu';

  @override
  String get detentionActionAskMedical =>
      'Ja nepieciešams, pieprasiet medicīnisko palīdzību';

  @override
  String get detentionActionRequestInterpreter =>
      'Pieprasiet tulku visās tiesas sēdēs';

  @override
  String get detentionDeadlineCourtReview =>
      'Rajona tiesai jāpārskata aizturēšana 4 dienu laikā';

  @override
  String get detentionDeadlineContinuation =>
      'Tiesa pārskata pagarināšanu ik pēc 2 nedēļām';

  @override
  String get detentionFactCourtReview =>
      'Imigrācijas aizturēšana Somijā jāpārskata rajona tiesai 4 dienu laikā. Ja tas netiek darīts, aizturēšana kļūst nelikumīga.';

  @override
  String get contactParliamentaryOmbudsman => 'Parlamentārais ombuds';

  @override
  String get discriminationActionWriteDown =>
      'Pierakstiet precīzi, kas notika (datums, laiks, vieta)';

  @override
  String get discriminationActionSaveEvidence =>
      'Saglabājiet pierādījumus: ziņojumus, e-pastus, lieciniekus';

  @override
  String get discriminationActionFileComplaint =>
      'Iesniedziet sūdzību Nediskriminācijas ombudam';

  @override
  String get discriminationActionContactLegalAid =>
      'Sazinieties ar juridiskās palīdzības biroju bezmaksas konsultācijai';

  @override
  String get discriminationActionReportPolice =>
      'Ziņojiet policijai, ja bija iesaistīti draudi vai uzbrukums';

  @override
  String get discriminationFactNonDiscriminationAct =>
      'Somijas Nediskriminācijas likums aptver diskrimināciju pēc vecuma, izcelsmes, pilsonības, valodas, reliģijas, veselības, invaliditātes, seksuālās orientācijas un citām personiskām īpašībām.';

  @override
  String get contactVictimSupportRIKU => 'Cietušo atbalsts Somija (RIKU)';

  @override
  String get domesticViolence => 'Vardarbība ģimenē';

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
  String get inheritance => 'Mantojums';

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
  String get consumerProtection => 'Patērētāju aizsardzība';

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
  String get comingSoon => 'Drīzumā';

  @override
  String get encrypted => 'Encrypted';

  @override
  String get typing => 'Typing…';

  @override
  String get online => 'Online';

  @override
  String get chatWelcomeSubtitle =>
      'Es izanalizēšu situāciju, pārbaudīšu dokumentus, atradīšu kļūdas un ieteikšu, ko darīt.';

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
      other: '$count tiesības iekšā',
      one: '$count tiesība iekšā',
      zero: '$count tiesību iekšā',
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
      'AI palīgs sniedz juridisku informāciju, nevis juridiskas konsultācijas. Vienmēr konsultējieties ar kvalificētu juristu.';

  @override
  String get chatDisclaimerSubtitle =>
      'MI asistents · nav juridiskā konsultācija';

  @override
  String get chatDisclaimerBannerFull =>
      'Advocat ir MI juridiskās informācijas asistents, nevis advokāts. Šī informācija nerada advokāta–klienta attiecības, nav juridiskā konsultācija un var saturēt kļūdas. Saistošai juridiskai konsultācijai sazinieties ar licencētu advokātu savā jurisdikcijā. Mēs jūs nepārstāvam.';

  @override
  String get chatDisclaimerFooter =>
      'Radīts ar MI. Pārbaudiet pie licencēta advokāta.';

  @override
  String get chatDisclaimerGotIt => 'Saprotu';

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
  String get guestUser => 'Viesis';

  @override
  String get howToUse => 'Ka lietot?';

  @override
  String get tutorialStep1Title => 'MI juridiskais paligs';

  @override
  String get tutorialStep1Desc =>
      'Uzdodiet jebkuru juridisku jautajumu un sanemiet tulejas atbildes, pamatojoties uz Igaunijas likumiem.';

  @override
  String get tutorialStep2Title => 'Ziniet savas tiesibas';

  @override
  String get tutorialStep2Desc =>
      'Parlukojiet juridisko informaciju pa temam — darbs, majoklis, pateretaju tiesibas un citas.';

  @override
  String get tutorialStep3Title => 'Skenet dokumentus';

  @override
  String get tutorialStep3Desc =>
      'Fotografejiet juridiskos dokumentus MI analizei un drosai glabasanai.';

  @override
  String get tutorialStep4Title => 'Sakas!';

  @override
  String get tutorialStep4Desc =>
      'Izpetiet lietotni un aizsargajiet savas tiesibas. Visi dati paliek privati jusu ierice.';

  @override
  String get advocatProTitle => 'Advocat Pro';

  @override
  String get advocatProSubtitle => 'Atbloķējiet premium funkcijas';

  @override
  String get voiceDisclaimer =>
      'Balss asistents pašlaik darbojas tikai datorā (Chrome pārlūkprogramma). Mobilais atbalsts drīzumā.';

  @override
  String get recommended => 'Ieteicams';

  @override
  String get pleaseLogIn => 'Lūdzu, piesakieties';

  @override
  String get subscriptionNotFound => 'Abonements nav atrasts';

  @override
  String errorWithMessage(String message) {
    return 'Kļūda: $message';
  }

  @override
  String get redirectingToPayment => 'Pārvirzīšana uz maksājumu lapu…';

  @override
  String cheaperAnnually(String amount) {
    return '€$amount/mēn. lētāk ar gada abonementu';
  }

  @override
  String get navigatingTo => 'Atveru';

  @override
  String get stayInChat => 'Palikt čatā';

  @override
  String get backToChat => 'Atpakaļ uz čatu';

  @override
  String get upgradeBannerTitle =>
      'Jauniniet, lai saņemtu neierobežotas konsultācijas';

  @override
  String get upgradeBannerCta => 'Jaunināt';

  @override
  String get paymentSuccessTitle => 'Maksājums veiksmīgs';

  @override
  String get paymentSuccessBody => 'Jūsu abonements tagad ir aktīvs.';

  @override
  String get commonOk => 'Labi';

  @override
  String get feedbackThumbsUpLabel => 'Noderīgi';

  @override
  String get feedbackThumbsDownLabel => 'Nav noderīgi';

  @override
  String get feedbackCommentPrompt => 'Kas bija nepareizi?';

  @override
  String get feedbackSend => 'Sūtīt';

  @override
  String get feedbackCancel => 'Atcelt';

  @override
  String get reasoningPillIdle => 'Domāju…';

  @override
  String get reasoningPillSearchingLaw => 'Meklēju Igaunijas tiesību aktos…';

  @override
  String get reasoningPillSearchingWeb => 'Meklēju tīmeklī…';

  @override
  String get reasoningPillCheckingCompany => 'Pārbaudu uzņēmumu reģistrā…';

  @override
  String get reasoningPillCheckingVehicle =>
      'Pārbaudu transportlīdzekļu reģistrā…';

  @override
  String get reasoningPillReadingDocument => 'Lasu jūsu dokumentu…';

  @override
  String get reasoningPillDrafting => 'Sagatavoju dokumentu…';

  @override
  String get reasoningPillPreparingEmail => 'Gatavoju e-pastu…';

  @override
  String get reasoningPillFindingLawyer => 'Meklēju juristus…';

  @override
  String get reasoningPillThinking => 'Analizēju jūsu lietu…';

  @override
  String get reasoningPillFinalising => 'Sastādu jūsu atbildi…';

  @override
  String reasoningCollapsedFormat(int sec, int sources) {
    return 'Analizēts $sec s · $sources avoti';
  }

  @override
  String get reasoningExpandHint => 'pieskarieties, lai redzētu soļus';

  @override
  String get caseFileTitle => 'Lietas materiāli';

  @override
  String get caseFileTimeline => 'Laika līnija';

  @override
  String get caseFileParties => 'Puses';

  @override
  String get caseFileDeadlines => 'Termiņi';

  @override
  String get caseFileExportPdf => 'Lejupielādēt lietas materiālus (PDF)';

  @override
  String get caseFileEmpty =>
      'Tērzējiet ar MI par savu lietu — jūsu laika līnija izveidosies pati.';

  @override
  String get caseFileDisclaimer =>
      'Šie lietas materiāli ir automātiski iegūti no jūsu sarakstes. Tā nav juridiska konsultācija.';

  @override
  String get caseFileTabLabel => 'Lieta';

  @override
  String get refresh => 'Atsvaidzināt';

  @override
  String get demoLimitReached =>
      'Sasniegts demonstrācijas ierobežojums. Reģistrējieties bez maksas, lai turpinātu.';

  @override
  String get demoLimitSignUpCta => 'Reģistrēties';

  @override
  String freeQuotaExhausted(int count) {
    return 'Šomēnes esat izmantojis visus $count bezmaksas ziņojumus.';
  }

  @override
  String get upgradeForUnlimited =>
      'Jauniniet uz Pro, lai saņemtu neierobežoti';

  @override
  String get upgradeCta => 'Jaunināt';

  @override
  String get rateLimitTryAgain =>
      'Sūtāt pārāk ātri. Mēģiniet vēlreiz pēc dažām sekundēm.';

  @override
  String get quickProfilePrompt =>
      'Lai es varētu palīdzēt precīzāk, kāds ir jūsu juridiskais statuss: vai esat Igaunijas pilsonis, ES pilsonis no citas valsts, vai jums ir uzturēšanās atļauja?';

  @override
  String get quickProfileChipEstonianCitizen => 'Igaunijas pilsonis';

  @override
  String get quickProfileChipEuCitizen => 'ES pilsonis (cits)';

  @override
  String get quickProfileChipResidencePermit => 'Uzturēšanās atļauja';

  @override
  String get quickProfileSkipBtn => 'Izlaist';

  @override
  String get quickProfileSavedAck => 'Sapratu. Kāds ir jūsu jautājums?';

  @override
  String get caseTitleLabel => 'Lietas nosaukums';

  @override
  String get jurisdictionLabel => 'Jurisdikcija';

  @override
  String get caseTypeLabel => 'Lietas veids';

  @override
  String get caseLanguageLabel => 'Valoda';

  @override
  String get caseNumbersSection => 'Lietas numuri';

  @override
  String get partiesSection => 'Puses';

  @override
  String get authoritiesSection => 'Iestādes';

  @override
  String get timelineSection => 'Laika līnija';

  @override
  String get openQuestionsSection => 'Atklātie jautājumi';

  @override
  String get nextActionsSection => 'Nākamās darbības';

  @override
  String get summarySection => 'Kopsavilkums';

  @override
  String get addRow => 'Pievienot rindu';

  @override
  String get removeRow => 'Noņemt';

  @override
  String get archiveCase => 'Arhivēt lietu';

  @override
  String get closeCase => 'Slēgt lietu';

  @override
  String get continueChatAboutCase => 'Turpināt sarunu par šo lietu';

  @override
  String get linkChatToCase => 'Saistīt ar lietu';

  @override
  String get clearActiveCase => 'Notīrīt aktīvo lietu';

  @override
  String get caseSavedAck => 'Lieta saglabāta';

  @override
  String get caseArchivedAck => 'Lieta arhivēta';

  @override
  String get intakeStep1Title => 'Kur ir lieta?';

  @override
  String get intakeStep1Subtitle =>
      'Valsts un iestāde, ar kuru jums ir darīšana.';

  @override
  String get intakeJurisdictionLabel => 'Valsts / jurisdikcija';

  @override
  String get intakeAuthorityLabel => 'Iestādes veids';

  @override
  String get intakeAuthorityNameLabel => 'Iestādes nosaukums (neobligāti)';

  @override
  String get intakeAuthorityPolice => 'Policija';

  @override
  String get intakeAuthorityCourt => 'Tiesa';

  @override
  String get intakeAuthoritySocial => 'Sociālie dienesti';

  @override
  String get intakeAuthorityEmployer => 'Darba devējs';

  @override
  String get intakeAuthorityLandlord => 'Izīrētājs';

  @override
  String get intakeAuthorityOpposingParty => 'Pretējā puse';

  @override
  String get intakeAuthorityOther => 'Cits';

  @override
  String get intakeStep2Title => 'Kāda veida lieta?';

  @override
  String get intakeStep2Subtitle =>
      'Izvēlieties tuvāko veidu — vēlāk varēsiet precizēt.';

  @override
  String get intakeCaseTypeCriminal => 'Krimināllieta';

  @override
  String get intakeCaseTypeCivil => 'Civillieta';

  @override
  String get intakeCaseTypeFamily => 'Ģimenes lieta';

  @override
  String get intakeCaseTypeAdmin => 'Administratīvā lieta';

  @override
  String get intakeCaseTypeImmigration => 'Imigrācija';

  @override
  String get intakeCaseTypeLabor => 'Darba tiesības';

  @override
  String get intakeCaseTypeConsumer => 'Patērētāju tiesības';

  @override
  String get intakeCaseTypeInheritance => 'Mantojums';

  @override
  String get intakeCaseTypeOther => 'Cits';

  @override
  String get intakeStep3Title => 'Kas ir iesaistīts?';

  @override
  String get intakeStep3Subtitle => 'Jūsu loma un otra puse.';

  @override
  String get intakeRoleLabel => 'Jūsu loma';

  @override
  String get intakeRolePlaintiff => 'Prasītājs';

  @override
  String get intakeRoleDefendant => 'Atbildētājs';

  @override
  String get intakeRoleVictim => 'Cietušais';

  @override
  String get intakeRoleAccused => 'Apsūdzētais';

  @override
  String get intakeRoleWitness => 'Liecinieks';

  @override
  String get intakeRoleFamily => 'Ģimenes loceklis';

  @override
  String get intakeRoleOther => 'Cits';

  @override
  String get intakeOpposingSideLabel => 'Pretējā puse (neobligāti)';

  @override
  String get intakeWitnessesLabel => 'Liecinieki (neobligāti)';

  @override
  String get intakeAddWitness => 'Pievienot liecinieku';

  @override
  String get intakeWitnessHint => 'Vārds vai kontaktinformācija';

  @override
  String get intakeStep4Title => 'Numuri un datumi';

  @override
  String get intakeStep4Subtitle =>
      'Viss, kas jums jau ir. Izlaidiet to, kā jums nav.';

  @override
  String get intakeCaseNumberLabel => 'Lietas numurs (neobligāti)';

  @override
  String get intakeIncidentDateLabel => 'Notikuma datums (neobligāti)';

  @override
  String get intakeIncidentDatePick => 'Izvēlēties datumu';

  @override
  String get intakeDeadlinesLabel => 'Zināmie termiņi';

  @override
  String get intakeAddDeadline => 'Pievienot termiņu';

  @override
  String get intakeDeadlineWhatHint => 'Kas';

  @override
  String get intakeStep5Title => 'Dokumenti';

  @override
  String get intakeStep5Subtitle =>
      'Augšupielādējiet visu būtisko. Mēs to izlasīsim.';

  @override
  String get intakeUploadDocsLabel => 'Augšupielādēt dokumentus';

  @override
  String get intakeSkipDocs => 'Izlaist — augšupielādēšu vēlāk';

  @override
  String get intakeNextBtn => 'Tālāk';

  @override
  String get intakeBackBtn => 'Atpakaļ';

  @override
  String get intakeFinishBtn => 'Pabeigt un atvērt sarunu';

  @override
  String get intakeUrgentBtn => 'Steidzami — jautāt tagad';

  @override
  String get intakeUrgentDialogTitle => 'Atvērt sarunu tagad?';

  @override
  String get intakeUrgentDialogBody =>
      'Mēs saglabāsim ievadīto kā lietas melnrakstu. Vedni varat pabeigt no lietas lapas jebkurā laikā.';

  @override
  String get intakeUrgentConfirm => 'Atvērt sarunu';

  @override
  String get intakeUrgentCancel => 'Turpināt aizpildīšanu';

  @override
  String get intakePreparingCase => 'Gatavoju jūsu lietu…';

  @override
  String get intakeFallbackGreeting =>
      'Es redzu jūsu lietu. Pastāstiet, kas ir vissteidzamākais — kopā to atrisināsim.';

  @override
  String get intakeUrgentGreeting =>
      'Es redzu, ka tas ir steidzami. Uzdodiet savu jautājumu — pārējo aizpildīsim ceļā.';

  @override
  String intakeStepIndicator(int current, int total) {
    return '$current. solis no $total';
  }

  @override
  String get intakeFieldRequired => 'Obligāts';

  @override
  String intakeUploadProgress(int done, int total) {
    return 'Augšupielādē $done / $total…';
  }

  @override
  String get uplDisclaimerFooter =>
      'Advocat nav advokātu birojs. Šī ir informācija, nevis juridiska konsultācija.';

  @override
  String get citationStatusVerifiedBadge => 'Pārbaudīts';

  @override
  String get citationStatusUnverifiedBadge => 'Nepārbaudīts';

  @override
  String get citationStatusHistoricalBadge => 'Vēsturiskā redakcija';

  @override
  String get citationStatusVerifiedTooltip => 'Citēts no iegūta tiesību avota.';

  @override
  String get citationStatusUnverifiedTooltip =>
      'MI citēja šo fragmentu bez avota iegūšanas — pirms paļaušanās pārbaudiet.';

  @override
  String get citationStatusHistoricalTooltip => 'Citētā norma vairs nav spēkā.';

  @override
  String get citationOpenInRiigiTeataja => 'Atvērt Riigi Teataja';

  @override
  String get citationSnippetExpand => 'Rādīt pilnu tekstu';

  @override
  String get citationSnippetCollapse => 'Rādīt mazāk';

  @override
  String get citationUnverifiedSheetNote =>
      'MI citēja šo paragrāfu, taču šajā sarunā tas netika iegūts no tiesību aktu korpusa. Pārbaudiet atsauci, pirms uz tās paļaujaties.';

  @override
  String get citationFooterNoneWarning => 'Nav pamatotu atsauču';

  @override
  String citationFooterSummaryTotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count citāti',
      one: '$count citāts',
      zero: '$count citātu',
    );
    return '$_temp0';
  }

  @override
  String citationFooterSummaryVerified(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pārbaudīti',
      one: '$count pārbaudīts',
      zero: '$count pārbaudītu',
    );
    return '$_temp0';
  }

  @override
  String citationFooterSummaryUnverified(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nepārbaudīti',
      one: '$count nepārbaudīts',
      zero: '$count nepārbaudītu',
    );
    return '$_temp0';
  }

  @override
  String citationFooterSummaryHistorical(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vēsturiski',
      one: '$count vēsturisks',
      zero: '$count vēsturisku',
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
      other: 'pēc $count dienām',
      one: 'pēc $count dienas',
      zero: 'pēc $count dienām',
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
      other: 'kavējas $count dienas',
      one: 'kavējas $count dienu',
      zero: 'kavējas $count dienas',
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
    return 'Konsilijs iesaka $count paralēlas darbības';
  }

  @override
  String get parallelActionsApproveAll => 'Apstiprināt visas un sūtīt';

  @override
  String parallelActionsApproveSelected(int count, int total) {
    return 'Apstiprināt $count no $total';
  }

  @override
  String parallelActionsConfirmTitle(int count) {
    return 'Sūtīt $count e-pastus?';
  }

  @override
  String parallelActionsConfirmBody(int count) {
    return 'Advocat nosūtīs $count sagatavotās atbildes, izmantojot jūsu savienoto Gmail. Katra tiek nosūtīta atsevišķi — ja kāda neizdodas, pārējās tomēr tiek nosūtītas.';
  }

  @override
  String parallelActionsSentToast(int count) {
    return 'Nosūtīts: $count.';
  }

  @override
  String parallelActionsPartialFailureToast(int sent, int failed) {
    return '$sent nosūtīts, $failed neizdevās.';
  }

  @override
  String get parallelActionsKindReply => 'atbilde';

  @override
  String get parallelActionsKindNew => 'jauns';

  @override
  String get parallelActionsCheckboxSelected => 'Darbība atlasīta';

  @override
  String get parallelActionsCheckboxUnselected => 'Darbība nav atlasīta';

  @override
  String parallelActionsCitationCount(int count) {
    return '$count cit.';
  }

  @override
  String parallelActionsRetryFailed(int count) {
    return 'Atkārtot neizdevušās ($count)';
  }

  @override
  String get agentApprovalNeedsReviewTitle =>
      'Advocat nepieciešams jūsu apstiprinājums';

  @override
  String get agentApprovalResolvedTitle => 'Darbība atrisināta';

  @override
  String get agentApprovalStepsLabel => 'soļi';

  @override
  String get agentApprovalApproveButton => 'Apstiprināt un sūtīt';

  @override
  String get agentApprovalDeclineButton => 'Noraidīt';

  @override
  String get agentApprovalAttachmentsLabel => 'Pielikumi';

  @override
  String get agentApprovalSentSummary => 'Nosūtīts jūsu vārdā.';

  @override
  String get agentApprovalDeclinedSummary =>
      'Noraidīts — nekas netika nosūtīts.';

  @override
  String get agentToolDraftEmailAtt => 'Sūtīt e-pastu ar pielikumiem';

  @override
  String get agentToolSendEmail => 'Sūtīt e-pastu';

  @override
  String get agentToolGeneratePdf => 'Ģenerēt PDF';

  @override
  String get agentToolApproveSend => 'Sūtīt sagatavoto atbildi';

  @override
  String get inboxErrorTitle => 'Neizdevās ielādēt iesūtni';

  @override
  String get inboxEditDiscardTitle => 'Atmest nesaglabātās izmaiņas?';

  @override
  String get inboxEditDiscardBody =>
      'Šajā melnrakstā ir nesaglabātas izmaiņas. Dodoties atpakaļ, tās tiks atmestas.';

  @override
  String get inboxEditKeepEditing => 'Turpināt rediģēšanu';

  @override
  String get inboxEditDiscard => 'Atmest';

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
  String get plannerSettingsTitle => 'Trīspakāpju juridiskā argumentācija';

  @override
  String get plannerSettingsSubtitle =>
      'Plāns → atbilde → kritika. Lēnāk, bet rūpīgāk.';

  @override
  String get plannerSettingsProBadge => 'Pro';

  @override
  String get plannerSettingsProDescription => 'Pieejams Pro plānā';

  @override
  String get plannerTrailHeaderPlan => 'Plāns';

  @override
  String get plannerTrailHeaderCritique => 'Kritika';

  @override
  String get plannerTrailSubQuestions => 'Apakšjautājumi';

  @override
  String get plannerTrailCounterArgs => 'Pretargumenti';

  @override
  String get plannerTrailEvidenceGaps => 'Pierādījumu trūkumi';

  @override
  String get plannerTrailMaterialGapTrue => 'Konstatēts būtisks trūkums';

  @override
  String get plannerTrailRegeneratedBadge => 'Vienreiz pārģenerēts';

  @override
  String get plannerTrailEmpty => 'nav vienumu';

  @override
  String get supportTitle => 'Palīdzība';

  @override
  String get supportSubtitle => 'Parasti atbildam 1–2 stundu laikā.';

  @override
  String get supportSearchPlaceholder => 'Meklēt palīdzību…';

  @override
  String get supportStatusAllOk => 'Visas sistēmas darbojas normāli';

  @override
  String get supportFaqWhatIs => 'Kas ir Advocat?';

  @override
  String get supportFaqHowSubscribe => 'Kā abonēt Pro?';

  @override
  String get supportFaqExportData => 'Vai varu eksportēt savus datus?';

  @override
  String get supportFaqCancelAccount => 'Atcelt vai dzēst kontu';

  @override
  String get supportFaqTalkHuman => 'Runāt ar cilvēku';

  @override
  String get supportContactEmail => 'E-pasts';

  @override
  String get supportContactTelegram => 'Telegram';

  @override
  String get supportContactWhatsapp => 'WhatsApp';

  @override
  String get supportFooterSla => 'Atbildam 24 stundu laikā';

  @override
  String get supportWhatsapp => 'WhatsApp';

  @override
  String get supportEmail => 'E-pasts';

  @override
  String get supportInApp => 'Rakstiet mums šeit';

  @override
  String get supportCategoryLabel => 'Kategorija';

  @override
  String get supportCategoryBug => 'Kļūda';

  @override
  String get supportCategoryPayment => 'Maksājuma problēma';

  @override
  String get supportCategoryQuestion => 'Jautājums';

  @override
  String get supportCategoryFeature => 'Funkcijas pieprasījums';

  @override
  String get supportCategoryOther => 'Cits';

  @override
  String get supportMessagePlaceholder => 'Aprakstiet savu problēmu...';

  @override
  String get supportEmailLabel => 'E-pasts (neobligāti)';

  @override
  String get supportSend => 'Sūtīt';

  @override
  String get supportSentSuccess => 'Ziņojums nosūtīts! Drīz atbildēsim.';

  @override
  String get supportError => 'Kaut kas nogāja greizi. Mēģiniet vēlreiz.';

  @override
  String get supportErrorTooShort => 'Lūdzu, ierakstiet vismaz 10 rakstzīmes.';

  @override
  String get supportErrorTooLong => 'Maksimums 2000 rakstzīmes.';

  @override
  String get supportPrivacyNotice => 'Jūsu ziņojums tiek glabāts droši.';

  @override
  String get reviewThisContract => 'Pārskatīt līgumu';

  @override
  String get contractReviews => 'Līgumu pārbaudes';

  @override
  String get contractReviewsFreeFeature =>
      '1 līguma pārbaude (mūža izmēģinājums)';

  @override
  String get contractReviewsCounselFeature => '5 līgumu pārbaudes mēnesī';

  @override
  String get contractReviewsProFeature => '20 līgumu pārbaudes mēnesī';

  @override
  String contractReviewsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Šomēnes palikušas $count līgumu pārbaudes',
      one: 'Šomēnes palikusi $count līgumu pārbaude',
      zero: 'Šomēnes palikušas $count līgumu pārbaudes',
    );
    return '$_temp0';
  }

  @override
  String get contractReviewsExhausted => 'Šomēnes vairs nav līgumu pārbaužu';

  @override
  String get contractReviewsFreeTrialLeft =>
      'Bezmaksas izmēģinājums: 1 līguma pārbaude';

  @override
  String get contractReviewsFreeTrialUsed =>
      'Bezmaksas izmēģinājums izmantots — jaunini';

  @override
  String get contractReviewsUpgradeTitle => 'Līgumu pārbaudes izmantotas';

  @override
  String get contractReviewsUpgradeBodyFree =>
      'Tu izmantoji savu bezmaksas līguma pārbaudi. Jaunini, lai saņemtu ikmēneša pārbaudes.';

  @override
  String contractReviewsUpgradeBodyPaid(int used, int cap) {
    return 'Tu izmantoji $used no $cap pārbaudēm šomēnes. Jaunini augstākam mēneša limitam.';
  }

  @override
  String get contractReviewsUpgradeCounselCta =>
      'Jaunini uz Counsel (€19,99/mēn.) — 5 pārbaudes';

  @override
  String get contractReviewsUpgradeProCta =>
      'Jaunini uz Pro (€29,99/mēn.) — 20 pārbaudes';

  @override
  String get contractReviewsUpgradeToProShort => 'Jaunini uz Pro — 20/mēn.';

  @override
  String get notNow => 'Ne tagad';

  @override
  String get referralTitle => 'Uzaicināt draugus';

  @override
  String get referralSubtitle =>
      'Iegūsti bezmaksas mēnesi. Uzdāvini bezmaksas mēnesi.';

  @override
  String get referralYourLink => 'TAVA SAITE';

  @override
  String get referralCopyLink => 'Kopēt saiti';

  @override
  String get referralShare => 'Kopīgot';

  @override
  String get referralLinkCopied => 'Saite nokopēta';

  @override
  String get referralStatsInvited => 'Uzaicināti';

  @override
  String get referralStatsConverted => 'Pievienojušies';

  @override
  String get referralStatsEarned => 'Bezmaksas mēneši';

  @override
  String get referralShareWhatsApp => 'Kopīgot WhatsApp';

  @override
  String get referralShareTelegram => 'Kopīgot Telegram';

  @override
  String get referralShareEmail => 'Kopīgot e-pastā';

  @override
  String get referralEmailSubject => 'Pamēģini Advocat — tavu MI juristu';

  @override
  String get referralLoadError =>
      'Nevarēja ielādēt datus. Velc uz leju, lai atjauninātu.';

  @override
  String get referralRetry => 'Mēģināt vēlreiz';

  @override
  String get referralSettingsTile => 'Uzaicināt draugus';

  @override
  String get referralAfterReviewCta =>
      'Patika? Uzaicini draugu — abi saņemsiet bezmaksas mēnesi.';

  @override
  String get referralAntiFraud => 'Maksimums 12 veiksmīgi ieteikumi gadā.';

  @override
  String get referralEmpty =>
      'Vēl nav ieteikumu. Nosūtiet savu saiti, lai sāktu pelnīt.';

  @override
  String get referralRecentActivity => 'Nesenā aktivitāte';

  @override
  String referralActivityInvited(String when) {
    return 'Uzaicināts $when';
  }

  @override
  String referralActivityActivated(String when) {
    return 'aktivizēts $when';
  }

  @override
  String get referralActivityPending => 'vēl nav aktivizēts';

  @override
  String referralStatsInvitedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count draugus',
      one: '1 draugu',
      zero: 'vēl nevienu draugu',
    );
    return 'Jūs esat uzaicinājis $_temp0';
  }

  @override
  String referralStatsConvertedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ir aktivizējuši',
      one: '1 ir aktivizējis',
      zero: 'vēl neviens nav aktivizējis',
    );
    return '$_temp0';
  }

  @override
  String referralStatsEarnedCount(int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months bezmaksas mēneši',
      one: '1 bezmaksas mēnesis',
      zero: 'vēl nekas',
    );
    return 'Jūsu bonuss: $_temp0';
  }

  @override
  String get referralNudgeMessage =>
      'Patīk Advocat? Uzaiciniet draugu — abi saņemsiet bezmaksas mēnesi.';

  @override
  String get referralNudgeAction => 'Uzaicināt';

  @override
  String get referralLandingTitle => 'Jūs esat uzaicināts uz Advocat';

  @override
  String referralLandingSubtitle(String inviterName) {
    return '$inviterName jūs uzaicināja — saņemiet savu bezmaksas pirmo mēnesi.';
  }

  @override
  String get referralLandingSubtitleGeneric =>
      'Saņemiet savu bezmaksas pirmo Advocat Pro mēnesi.';

  @override
  String get referralLandingCta => 'Aktivizēt bezmaksas mēnesi un reģistrēties';

  @override
  String get referralLandingCtaSecondary => 'Vai uzziniet vairāk par Advocat';

  @override
  String get referralLandingFallback =>
      'Šīs saites derīguma termiņš ir beidzies — bet jūs joprojām varat izmēģināt Advocat bez maksas.';

  @override
  String get referralLandingBenefits =>
      '17 valodas • Reāli Igaunijas, Somijas un ES tiesību akti • 24/7 — bez gaidīšanas';

  @override
  String get checkerProTagline => 'Profesionāli pārbaudes rīki';

  @override
  String get checkerDataSource => 'Dati no oficiālajiem reģistriem';

  @override
  String get companyCheckerHint => 'Uzņēmuma nosaukums vai reģ. numurs';

  @override
  String get companyCheckerPriceChip => '€2.99 par pārbaudi  •  Iekļauts Pro';

  @override
  String get companyCheckerEmptyState =>
      'Ievadiet uzņēmuma nosaukumu vai reģistrācijas\nnumuru, lai saņemtu pilnu pārskatu';

  @override
  String get aiMemoryTitle => 'MI atmiņa';

  @override
  String get aiMemorySubtitle =>
      'Pārskatiet un dzēsiet to, ko MI atceras par jums';

  @override
  String get bookLawyerCallTitle => 'Rezervējiet sarunu ar juristu';

  @override
  String get bookLawyerCallComingSoonTitle =>
      'Sarunas ar īstu juristu — drīzumā';

  @override
  String get bookLawyerCallComingSoonBody =>
      'Pro un Premium ietver 15 minūšu sarunas ar partnera juristu (Pro – 1/ceturksnī, Premium – 2/ceturksnī). Pabeidzam Igaunijas individuālo juristu tīkla veidošanu un nosūtīsim e-pastu, tiklīdz rezervēšana būs atvērta.';

  @override
  String bookLawyerCallQuotaAvailable(int remaining, int total) {
    return 'Šajā ceturksnī jums atlikuši $remaining no $total zvaniem.';
  }

  @override
  String get bookLawyerCallQuotaExhausted => 'Ceturkšņa kvota izlietota.';

  @override
  String get bookLawyerCallQuotaBodyAvailable =>
      'Pro pakete ietver 1 zvanu ceturksnī, Premium – 2. Zvani ilgst 15 minūtes Google Meet vidē.';

  @override
  String get bookLawyerCallQuotaBodyExhausted =>
      'Jūsu kvota tiks atjaunota nākamā ceturkšņa pirmajā dienā. Vajag sarunu ātrāk? Atjauniniet uz Premium, lai saņemtu papildu zvanu.';

  @override
  String get severityCritical => 'KRITISKS';

  @override
  String get severityHigh => 'AUGSTS';

  @override
  String get severityMedium => 'VIDĒJS';

  @override
  String get severityLow => 'ZEMS';

  @override
  String get deadlineRequiredFields =>
      'Nosaukums un termiņa datums ir obligāti';

  @override
  String get acceptTermsRequired => 'Lūdzu, piekrītiet Pakalpojuma noteikumiem';

  @override
  String get chatLegalCouncilTooltip => 'Juridiskā konsultācija (4 eksperti)';

  @override
  String get attachFileTooltip => 'Pievienot failu';

  @override
  String get sendMessage => 'Sūtīt ziņojumu';

  @override
  String get stopGenerating => 'Apturēt ģenerēšanu';

  @override
  String get showPassword => 'Rādīt paroli';

  @override
  String get hidePassword => 'Slēpt paroli';

  @override
  String get decreaseDependents => 'Samazināt';

  @override
  String get increaseDependents => 'Palielināt';

  @override
  String get sensitiveConsentTitle => 'Piekrišana sensitīvu datu apstrādei';

  @override
  String get sensitiveConsentBody =>
      'Dokumenti, kurus gatavojaties augšupielādēt, var saturēt īpašu kategoriju personas datus saskaņā ar VDAR 9. pantu — piemēram, veselības ierakstus, sodāmības reģistra datus, biometriskos datus vai informāciju par jūsu rases izcelsmi, reliģiju vai seksuālo orientāciju.\n\nMēs apstrādājam šos datus tikai, lai sniegtu jums MI juridisko palīdzību, glabājam tos šifrētus jūsu privātajā kontā un nekad neizmantojam tos modeļu apmācībai. Piekrišanu varat atsaukt un datus dzēst jebkurā laikā sadaļā “Iestatījumi”.\n\nPiekrītot, jūs sniedzat skaidri paustu piekrišanu saskaņā ar VDAR 9. panta 2. punkta a) apakšpunktu apstrādāt īpašu kategoriju datus šim mērķim.';

  @override
  String get sensitiveConsentExplicitCheckbox =>
      'Es sniedzu skaidri paustu piekrišanu apstrādāt īpašu kategoriju datus (VDAR 9. panta 2. punkta a) apakšpunkts).';

  @override
  String get sensitiveConsentRightToShareCheckbox =>
      'Apliecinu, ka man ir tiesības koplietot šos datus (dati ir mani vai man ir informēts/likumīgs pamats koplietot trešo personu datus).';

  @override
  String get sensitiveConsentViewCategories =>
      'Skatīt, kas tiek uzskatīts par sensitīvu →';

  @override
  String get sensitiveConsentWithdrawAction =>
      'Atsaukt piekrišanu sensitīvu datu apstrādei';

  @override
  String get privacyAndData => 'KONFIDENCIALITĀTE UN DATI';

  @override
  String get exportMyDataSubtitle =>
      'Lejupielādējiet visu savu personas datu kopiju (VDAR 15. pants).';

  @override
  String get withdrawSensitiveConsent => 'Piekrišana sensitīvu datu apstrādei';

  @override
  String get withdrawSensitiveConsentSubtitle =>
      'Pārvaldiet vai atsauciet piekrišanu īpašu kategoriju datu apstrādei (VDAR 9. panta 2. punkta a) apakšpunkts).';

  @override
  String get dataProcessingAgreement => 'Datu apstrādes līgums';

  @override
  String get exportingData => 'Eksportē jūsu datus…';

  @override
  String get exportComplete =>
      'Datu eksports ir gatavs — saglabāts jūsu ierīcē.';

  @override
  String get exportFailed =>
      'Eksports neizdevās. Lūdzu, mēģiniet vēlreiz vai sazinieties ar atbalsta dienestu.';

  @override
  String get quotaExhaustedTitle => 'Sasniegts bezmaksas ziņojumu ierobežojums';

  @override
  String quotaExhaustedBody(int count) {
    return 'Esat izmantojis visus $count bezmaksas ziņojumus. Jauniniet uz Advocat Counsel par €19.99 mēnesī un saņemiet neierobežotas MI juridiskās konsultācijas.';
  }

  @override
  String get quotaExhaustedLater => 'Vēlāk';

  @override
  String get quotaExhaustedUpgrade => 'Advocat Counsel — €19.99/mēn.';

  @override
  String quotaCtaMessage(int count) {
    return 'Esat izmantojis visus $count bezmaksas ziņojumus. Jauniniet uz Advocat Counsel par €19.99 mēnesī.';
  }

  @override
  String get quotaCtaButton => 'Iegūt Advocat Counsel — €19.99/mēn.';

  @override
  String get aiErrorQuota =>
      'Sasniegts bezmaksas ziņojumu ierobežojums. Abonējiet, lai turpinātu lietot MI.';

  @override
  String get aiErrorAuth =>
      'Lai lietotu MI, nepieciešama pieteikšanās. Lūdzu, reģistrējieties vai pierakstieties.';

  @override
  String get aiErrorGeneric =>
      'Īslaicīga MI kļūda. Lūdzu, mēģiniet vēlreiz pēc minūtes. Ja tā saglabājas, sazinieties ar atbalsta dienestu.';

  @override
  String get tooltipShareCase => 'Kopīgot lietas kopsavilkumu';

  @override
  String get tooltipMuteVoice => 'Izslēgt balsi';

  @override
  String get tooltipUnmuteVoice => 'Ieslēgt balsi';

  @override
  String get tooltipAttachDoc => 'Pievienot dokumentu';

  @override
  String get aiTypingHint => 'MI…';

  @override
  String get error404Title => 'Lapa nav atrasta';

  @override
  String error404Body(String path) {
    return 'Mēs nevarējām atrast: $path';
  }

  @override
  String get goToHome => 'Doties uz sākumu';

  @override
  String get emailAlreadyRegistered =>
      'Šis e-pasts jau ir reģistrēts. Vai vēlaties pierakstīties?';

  @override
  String get actionSignIn => 'Pierakstīties';

  @override
  String get actionUndo => 'Atsaukt';

  @override
  String get intakeUrgentOpened =>
      'Saruna atvērta — jūsu melnraksts ir saglabāts.';

  @override
  String get panicCoachmark =>
      'Turiet nospiestu, lai saņemtu ārkārtas palīdzību.';

  @override
  String get panicTitle => 'Kas jums ir nepieciešams tieši tagad?';

  @override
  String get panicCardReadAloud => 'Nolasīt skaļi ierēdnim';

  @override
  String get panicCardRecord => 'Ierakstīt šo sarunu';

  @override
  String get panicCardCall => 'Zvanīt juristam';

  @override
  String get panicCardAi => 'Runāt ar Advocat tagad';

  @override
  String get panicClose => 'Aizvērt';

  @override
  String get panicBadgeV2 => 'V2';

  @override
  String get panicRecordV1Title => 'Drīzumā V2 versijā';

  @override
  String get panicRecordV1Body =>
      'Ierakstīšanas funkcija tiek juridiski validēta Igaunijai un būs pieejama V2 versijā. Pagaidām izmantojiet tālruņa iebūvēto balss ierakstītāju.';

  @override
  String get panicCallFallbackBody =>
      'Rakstiet uz kiire@advocat.ee ar īsu aprakstu, un mēs jums atzvanīsim.';

  @override
  String get consiliumHeader => 'Juristu konsīlijs';

  @override
  String consiliumProgress(int count, int total) {
    return '$count no $total gatavi';
  }

  @override
  String get consiliumStarting => 'Juristi izvērtē jūsu lietu…';

  @override
  String get consiliumDisagreement => 'Eksperti nav vienisprātis';

  @override
  String get consiliumSynthesizing => 'Veido ieteikumu…';

  @override
  String consiliumDone(int totalRoles) {
    return 'Konsīlijs pabeigts · $totalRoles eksperti';
  }

  @override
  String get consiliumPositionPush => 'Apstrīdēt';

  @override
  String get consiliumPositionSettle => 'Vienoties';

  @override
  String get consiliumPositionInvestigate => 'Izmeklēt';

  @override
  String get consiliumPositionOutOfScope => 'Ārpus kompetences';

  @override
  String get consiliumConfidence => 'Pārliecība';

  @override
  String get consiliumKeyCitation => 'Galvenā atsauce';

  @override
  String get consiliumAdversarialRound => 'Sacīkstes kārta';

  @override
  String get consiliumViewFullOpinion => 'Skatīt pilnu atzinumu';

  @override
  String consiliumExpertsAgreed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count eksperti piekrīt',
      one: '$count eksperts piekrīt',
      zero: '$count eksperti piekrīt',
    );
    return '$_temp0';
  }

  @override
  String consiliumExpertsDisagree(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count eksperti nepiekrīt',
      one: '$count eksperts nepiekrīt',
      zero: '$count eksperti nepiekrīt',
    );
    return '$_temp0';
  }

  @override
  String get consiliumDisclaimer =>
      'MI aģenti, nevis cilvēki juristi. Būtiskus lēmumus pārbaudiet pie licencēta zvērināta advokāta.';

  @override
  String get softCaseShellBanner =>
      'Mēs izveidojām “Lietu bez nosaukuma”, lai to izsekotu. Pieskarieties, lai pārdēvētu.';

  @override
  String get softCaseShellBannerCta => 'Pārdēvēt';

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
  String get chatExamplePrompt1 => 'Palīdzi atbildēt uz sodu';

  @override
  String get chatExamplePrompt2 => 'Pārbaudi manu īres līgumu';

  @override
  String get chatExamplePrompt3 => 'Kādas ir manas tiesības darbā?';

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
  String get contractReviewTitle => 'Līguma pārbaude';

  @override
  String get contractReviewUploadCta => 'Augšupielādēt līgumu';

  @override
  String get contractReviewQuotaRemaining =>
      'Augšupielādējiet PDF, DOC, DOCX vai TXT līgumu, lai saņemtu AI pārbaudi ar brīdinājuma signāliem un sarunu ieteikumiem.';

  @override
  String get contractReviewRedFlags => 'Brīdinājuma signāli';

  @override
  String get contractReviewReviewPoints => 'Pārbaudes punkti';

  @override
  String get contractReviewNegotiationTips => 'Sarunu ieteikumi';

  @override
  String get contractReviewSaveToVault => 'Saglabāt glabātuvē';

  @override
  String get contractReviewContinueChat => 'Turpināt tērzēšanā';

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
  String get iapPayWithApple => 'Maksāt ar Apple';

  @override
  String get iapRestorePurchases => 'Atjaunot pirkumus';

  @override
  String get iapPurchaseFailed =>
      'Pirkums neizdevās. Lūdzu, mēģiniet vēlreiz vai sazinieties ar atbalstu.';

  @override
  String get iapRestoreSuccess => 'Jūsu abonements ir atjaunots.';

  @override
  String get iapRestoreNoActive =>
      'Nav atrasts aktīvs abonements atjaunošanai.';

  @override
  String get deadlineEuRadarTitle => 'EU deadline radar (preview)';

  @override
  String get deadlineEuRadarSubtitle =>
      'Hypothetical EU procedural deadlines — mock data';

  @override
  String get changePassword => 'Mainīt paroli';

  @override
  String get changePasswordSubtitle => 'Atjauniniet sava konta paroli';

  @override
  String get newPasswordTitle => 'Iestatiet jaunu paroli';

  @override
  String get newPasswordHint =>
      'Ievadiet un apstipriniet sava konta jauno paroli.';

  @override
  String get newPasswordSave => 'Saglabāt jauno paroli';

  @override
  String get newPasswordSuccess =>
      'Parole ir atjaunināta. Tagad varat to izmantot, lai pieteiktos.';

  @override
  String get newPasswordError =>
      'Neizdevās atjaunināt paroli. Lūdzu, mēģiniet vēlreiz.';

  @override
  String get accessLogTile => 'Piekļuves žurnāls';

  @override
  String get accessLogTileSubtitle => 'Skatiet, kas un kā piekļuva jūsu datiem';

  @override
  String get accessLogTitle => 'Manu datu piekļuves žurnāls';

  @override
  String get accessLogIntro =>
      'Caurspīdīgs, pret viltojumiem aizsargāts ieraksts par katru reizi, kad jūsu datiem piekļuva vai tie tika apstrādāti — tostarp ar mūsu MI. Jūs varat pārbaudīt, ka tas nav mainīts.';

  @override
  String get accessLogEmpty => 'Vēl nav piekļuves notikumu.';

  @override
  String get accessLogError =>
      'Neizdevās ielādēt piekļuves žurnālu. Pavelciet uz leju, lai mēģinātu vēlreiz.';

  @override
  String get accessLogIntegrityOk =>
      'Integritāte pārbaudīta — žurnāla saites veido nepārtrauktu ķēdi.';

  @override
  String get accessLogIntegrityBroken =>
      'Brīdinājums: žurnāla ķēde ir pārtraukta. Daži ieraksti, iespējams, ir noņemti vai pārkārtoti. Lūdzu, sazinieties ar atbalsta dienestu.';

  @override
  String get accessActionLlmEgress => 'Nosūtīts MI apstrādei (pseidonimizēts)';

  @override
  String get accessActionAiAnalysis => 'Analizējis MI';

  @override
  String get accessActionDocumentParse => 'Dokuments apstrādāts';

  @override
  String get accessActionStaffRead => 'Pārskatījis darbinieks';

  @override
  String get accessActionExport => 'Dati eksportēti';

  @override
  String get accessActionEmailTriage => 'E-pasts šķirots';

  @override
  String get accessActionDeadlineScan => 'Termiņi noskenēti';

  @override
  String get breachAlertTitle => 'Drošības brīdinājums par jūsu datiem';

  @override
  String get breachAlertBody =>
      'Mūsu automatizētā uzraudzība konstatēja neparastu piekļuvi jūsu datiem. Mēs to izvērtējam un paziņosim jums par jebkuru apstiprinātu incidentu, kā to nosaka likums (VDAR 34. pants).';

  @override
  String get caseDossierTitle => 'Eksportēt lietas dokumentāciju';

  @override
  String get caseDossierSubtitle =>
      'Viens PDF ar visu — faktiem, hronoloģiju, termiņiem un dokumentiem — ko nodot advokātam, tiesai vai sūdzību iestādei.';

  @override
  String get caseDossierTileTitle => 'Eksportēt dokumentāciju (PDF)';

  @override
  String get caseDossierTileSubtitle =>
      'Nodod visu lietu advokātam vai tiesai vienā failā';

  @override
  String get caseDossierSectionsHeading => 'Iekļaut dokumentācijā';

  @override
  String get caseDossierSectionFacts => 'Lietas fakti';

  @override
  String get caseDossierSectionFactsHint => 'Vienmēr iekļauts';

  @override
  String get caseDossierSectionTimeline => 'Hronoloģija';

  @override
  String get caseDossierSectionDeadlines => 'Termiņi';

  @override
  String get caseDossierSectionDocuments => 'Dokumenti';

  @override
  String get caseDossierSectionAiSummary => 'MI kopsavilkums';

  @override
  String get caseDossierExportButton => 'Eksportēt PDF';

  @override
  String get caseDossierExporting => 'Veido jūsu dokumentāciju…';

  @override
  String get caseDossierSuccess =>
      'Dokumentācija gatava. Atveriet vai kopīgojiet failu.';

  @override
  String get caseDossierOpen => 'Atvērt dokumentāciju';

  @override
  String get caseDossierError =>
      'Neizdevās izveidot dokumentāciju. Lūdzu, mēģiniet vēlreiz.';

  @override
  String get caseDossierErrorNotOwned => 'Šo lietu neizdevās atrast.';

  @override
  String get caseDossierDisclaimer =>
      'Dokumentācija atveido jūsu lietas datus tādus, kā tie reģistrēti. Pārskatiet to pirms kopīgošanas.';

  @override
  String get followupsTitle => 'Nākamie soļi';

  @override
  String get followupsSubtitle =>
      'Praktiski uzdevumi, lai virzītu jūsu lietu uz priekšu';

  @override
  String get followupsEmpty => 'Vēl nav turpmāko soļu.';

  @override
  String get followupsEmptyDesc =>
      'Pievienojiet soli vai ļaujiet MI ieteikt, ko darīt tālāk.';

  @override
  String get followupsAdd => 'Pievienot soli';

  @override
  String get followupsSuggest => 'Ieteikt soļus';

  @override
  String get followupsSuggestNone =>
      'Pašlaik ieteikumu nav. Mēģiniet pēc sarunas par lietu.';

  @override
  String get followupsSuggestTitle => 'Ieteiktie nākamie soļi';

  @override
  String get followupsAddPrompt =>
      'Pievienojiet soļus, kurus vēlaties saglabāt:';

  @override
  String get followupsNewTitleHint => 'Kas ir jāizdara?';

  @override
  String get followupsNewDetailHint =>
      'Neobligāta piezīme (kāpēc / ko pievienot)';

  @override
  String get followupsDueOptional => 'Atgādināt (neobligāti)';

  @override
  String get followupsOverdue => 'Nokavēts';

  @override
  String followupsDueOn(String date) {
    return 'Termiņš $date';
  }

  @override
  String get followupsDone => 'Pabeigts';

  @override
  String get followupsSnooze => 'Atlikt';

  @override
  String get followupsSnooze1Week => 'Atgādināt pēc nedēļas';

  @override
  String get followupsDismiss => 'Noraidīt';

  @override
  String get followupsLoadError => 'Neizdevās ielādēt nākamos soļus';

  @override
  String get followupsAiBadge => 'MI';

  @override
  String get contractCompareTitle => 'Salīdzināt versijas';

  @override
  String get contractCompareIntro =>
      'Augšupielādējiet divas viena un tā paša līguma versijas. Mēs izceļam, kas ir mainījies un vai katra izmaiņa jums palīdz vai kaitē.';

  @override
  String get contractCompareOldVersion => 'Vecā versija (v1)';

  @override
  String get contractCompareNewVersion => 'Jaunā versija (v2)';

  @override
  String get contractCompareCta => 'Salīdzināt versijas';

  @override
  String get contractCompareAdverse => 'Nelabvēlīgs';

  @override
  String get contractCompareFavorable => 'Labvēlīgs';

  @override
  String get contractCompareNeutral => 'Neitrāls';

  @override
  String get contractCompareBefore => 'Pirms';

  @override
  String get contractCompareAfter => 'Pēc';

  @override
  String get contractCompareTruncated =>
      'Garš līgums — salīdzināta tika tikai katras versijas pirmā daļa.';

  @override
  String get contractCompareNoChanges =>
      'Starp abām versijām būtiskas izmaiņas nav konstatētas.';

  @override
  String get docSearchTitle => 'Meklēt manos dokumentos';

  @override
  String get docSearchHint => 'piem., kur tika minēts depozīts';

  @override
  String get docSearchSubtitle =>
      'Semantiskā meklēšana jūsu glabātavā un lietas failos';

  @override
  String get docSearchIdle =>
      'Meklējiet savu dokumentu saturā — ne tikai virsrakstos.';

  @override
  String get docSearchNoResults =>
      'Jūsu dokumentos atbilstības netika atrastas.';

  @override
  String get docSearchError => 'Meklēšana neizdevās. Lūdzu, mēģiniet vēlreiz.';

  @override
  String get docSearchUntitled => 'Dokuments bez nosaukuma';

  @override
  String get docSearchKindCase => 'Lietas dokuments';

  @override
  String get docSearchKindVault => 'Glabātavas dokuments';

  @override
  String get docSearchMenuTitle => 'Meklēt manos dokumentos';

  @override
  String get docSearchMenuSubtitle => 'Atrodiet jebko savos failos pēc nozīmes';

  @override
  String get legalTemplatesTitle => 'Veidņu bibliotēka';

  @override
  String get legalTemplatesMenuLabel => 'Veidnes';

  @override
  String get legalTemplatesSubtitle =>
      'Izvēlieties gatavu veidlapu, aizpildiet dažas detaļas, un mēs izveidosim melnrakstu, ko varat rediģēt un eksportēt.';

  @override
  String get legalTemplatesDisclaimer =>
      'Šīs ir vispārīgas paraugveidlapas, nevis individuāla juridiska konsultācija. Pārskatiet un pielāgojiet pirms nosūtīšanas.';

  @override
  String get legalTemplatesSampleBadge => 'Paraugs';

  @override
  String get legalTemplatesEmpty => 'Šim filtram vēl nav veidņu.';

  @override
  String get legalTemplatesError =>
      'Neizdevās ielādēt veidnes. Lūdzu, mēģiniet vēlreiz.';

  @override
  String get legalTemplatesFilterAll => 'Visas';

  @override
  String get legalTemplatesJurisdictionFi => 'Somija';

  @override
  String get legalTemplatesJurisdictionEe => 'Igaunija';

  @override
  String get legalTemplatesCategoryComplaint => 'Sūdzības';

  @override
  String get legalTemplatesCategoryAppeal => 'Apelācijas';

  @override
  String get legalTemplatesCategoryApplication => 'Pieteikumi';

  @override
  String get legalTemplatesCategoryClaim => 'Prasības';

  @override
  String get legalTemplatesCategoryRequest => 'Pieprasījumi';

  @override
  String get legalTemplatesFillTitle => 'Aizpildiet detaļas';

  @override
  String get legalTemplatesFillIntro =>
      'Mēs automātiski aizpildīsim jūsu vārdu un lietas datus. Aizpildiet zemāk esošos laukus.';

  @override
  String get legalTemplatesFieldRequired => 'Šis lauks ir obligāts';

  @override
  String get legalTemplatesCreateDraft => 'Izveidot melnrakstu';

  @override
  String get legalTemplatesCreating => 'Veido melnrakstu…';

  @override
  String get legalTemplatesCreateFailed =>
      'Neizdevās izveidot melnrakstu. Lūdzu, mēģiniet vēlreiz.';

  @override
  String get legalTemplatesUnresolvedWarning =>
      'Daži lauki joprojām ir tukši un melnrakstā ir atzīmēti ar ____. Jūs varat tos aizpildīt redaktorā.';

  @override
  String get legalTemplatesFieldRecipient => 'Saņēmējs (iestāde / izīrētājs)';

  @override
  String get legalTemplatesFieldAddress => 'Jūsu pasta adrese';

  @override
  String get legalTemplatesFieldSubject => 'Temats';

  @override
  String get legalTemplatesFieldDescription => 'Lietas apraksts';

  @override
  String get legalTemplatesFieldDemand => 'Ko jūs pieprasāt';

  @override
  String get checklistActionPlan => 'Rīcības plāns';

  @override
  String get checklistActionPlanSubtitle => 'Soļi šāda veida lietai';

  @override
  String checklistProgress(int completed, int total) {
    return 'Pabeigti $completed no $total soļiem';
  }

  @override
  String get checklistAllDone => 'Visi soļi pabeigti';

  @override
  String get checklistEmpty =>
      'Šim lietas veidam vēl nav pieejams rīcības plāns.';

  @override
  String checklistDeadlineDays(int days) {
    return '$days dienas';
  }

  @override
  String get checklistDisclaimer =>
      'Šī ir vispārīga informācija, nevis juridiska konsultācija. Termiņi ir likumā noteiktās noklusētās vērtības — apstipriniet precīzu datumu savai lietai.';

  @override
  String get checklistViewPlan => 'Skatīt plānu';

  @override
  String get explainPlainTitle => 'Paskaidrot vienkāršos vārdos';

  @override
  String get explainPlainIntro =>
      'Ielīmējiet oficiālu vēstuli, lēmumu vai līgumu, un mēs paskaidrosim, ko tas nozīmē un ko tas no jums prasa — vienkāršā valodā.';

  @override
  String get explainPlainLevelFriend => 'Kā draugam';

  @override
  String get explainPlainLevelTerms => 'Saglabāt juridiskos terminus';

  @override
  String get explainPlainInputHint => 'Ielīmējiet juridisko tekstu šeit…';

  @override
  String get explainPlainSubmit => 'Paskaidrot';

  @override
  String get explainPlainWorking => 'Skaidro…';

  @override
  String get explainPlainTldr => 'Galvenais';

  @override
  String get explainPlainBreakdown => 'Ko tas saka, pa daļām';

  @override
  String get explainPlainGlossary => 'Sarežģītie termini paskaidroti';

  @override
  String get explainPlainNextSteps => 'Ko jūs varat darīt tālāk';

  @override
  String get explainPlainOpenInCorpus => 'Meklēt likumu bibliotēkā';

  @override
  String get explainPlainEmptyResult =>
      'Šim tekstam neizdevās sniegt paskaidrojumu. Mēģiniet ielīmēt garāku vai skaidrāku fragmentu.';

  @override
  String get explainPlainQuotaTitle =>
      'Šomēnes esat izmantojis savus bezmaksas paskaidrojumus';

  @override
  String get explainPlainQuotaBody =>
      'Bezmaksas konti saņem 3 paskaidrojumus mēnesī. Jauniniet uz Pro, lai saņemtu neierobežotus paskaidrojumus.';

  @override
  String get explainPlainUpgradeCta => 'Jaunināt uz Pro';

  @override
  String get explainPlainError =>
      'Skaidrojot šo tekstu, radās kļūda. Lūdzu, mēģiniet vēlreiz.';

  @override
  String get explainPlainRetry => 'Mēģināt vēlreiz';

  @override
  String get demandLetterTitle => 'Pretenzijas vēstule';

  @override
  String get demandLetterSubtitle =>
      'Izveidojiet oficiālu pirmstiesas pretenziju (maksuvaatimus / nõudekiri).';

  @override
  String get demandLetterStepType => 'Prasības veids';

  @override
  String get demandLetterStepParties => 'Puses';

  @override
  String get demandLetterStepClaim => 'Summa un pamatojums';

  @override
  String get demandLetterStepDeadline => 'Termiņš';

  @override
  String get demandLetterStepReview => 'Pārskatīt un ģenerēt';

  @override
  String get demandLetterClaimDepositReturn => 'Īres depozīta atmaksa';

  @override
  String get demandLetterClaimUnpaidWage => 'Neizmaksāta alga';

  @override
  String get demandLetterClaimFineDispute => 'Apstrīdēt sodu / maksājumu';

  @override
  String get demandLetterClaimGeneric => 'Cita naudas prasība';

  @override
  String get demandLetterJurisdiction => 'Jurisdikcija';

  @override
  String get demandLetterLanguage => 'Vēstules valoda';

  @override
  String get demandLetterRecipientName => 'Saņēmēja vārds';

  @override
  String get demandLetterRecipientAddress => 'Saņēmēja adrese (neobligāti)';

  @override
  String get demandLetterSenderName => 'Jūsu vārds';

  @override
  String get demandLetterSenderAddress => 'Jūsu adrese / e-pasts (neobligāti)';

  @override
  String get demandLetterAmount => 'Summa';

  @override
  String get demandLetterCurrency => 'Valūta';

  @override
  String get demandLetterBasis => 'Kas notika (prasības pamatojums)';

  @override
  String get demandLetterBasisHint =>
      'Aprakstiet faktus: datumus, summas, kas tika norunāts un kas nogāja greizi.';

  @override
  String get demandLetterDeadline => 'Maksājuma termiņš';

  @override
  String get demandLetterDeadlineHint => 'piem., 14 dienas no šodienas';

  @override
  String get demandLetterReference => 'Atsauce (neobligāti)';

  @override
  String get demandLetterGenerate => 'Ģenerēt vēstuli';

  @override
  String get demandLetterGenerating => 'Ģenerē…';

  @override
  String get demandLetterGenerateFailed =>
      'Neizdevās ģenerēt vēstuli. Lūdzu, mēģiniet vēlreiz.';

  @override
  String get demandLetterFieldRequired => 'Šis lauks ir obligāts';

  @override
  String get demandLetterNext => 'Tālāk';

  @override
  String get demandLetterBack => 'Atpakaļ';

  @override
  String get demandLetterPreviewTitle => 'Jūsu vēstule';

  @override
  String get demandLetterCopy => 'Kopēt tekstu';

  @override
  String get demandLetterCopied => 'Vēstule nokopēta starpliktuvē';

  @override
  String get demandLetterExportPdf => 'Eksportēt PDF';

  @override
  String get demandLetterExporting => 'Eksportē…';

  @override
  String get demandLetterExportFailed =>
      'Neizdevās eksportēt dokumentu. Lūdzu, mēģiniet vēlreiz.';

  @override
  String get demandLetterSendEmail => 'Nosūtīt pa e-pastu';

  @override
  String get demandLetterNormsTitle => 'Juridiskās atsauces';

  @override
  String get demandLetterDisclaimer =>
      'Šī vēstule ir sagatavota jūsu vārdā kā vispārīga veidne. Tā nav juridiska konsultācija vai licencēta advokāta darbība. Pārskatiet to pirms nosūtīšanas — neviena vēstule netiek nosūtīta automātiski.';

  @override
  String get demandLetterMenuTile => 'Pretenzijas vēstule';

  @override
  String get calcHubTitle => 'Juridiskie kalkulatori';

  @override
  String get calcHubSubtitle => 'Ātri aprēķini pirms nākamā soļa';

  @override
  String get calcHubJurisdiction => 'Jurisdikcija';

  @override
  String calcRatesAsOf(String date) {
    return 'Likmes uz $date';
  }

  @override
  String get calcRatesOffline => 'Rāda kešotās likmes (bezsaistē)';

  @override
  String get calcIndicativeBanner =>
      'Tikai indikatīvs aprēķins — nav oficiāls aprēķins vai juridiska konsultācija.';

  @override
  String get calcCalculate => 'Aprēķināt';

  @override
  String get calcResult => 'Rezultāts';

  @override
  String get calcFormula => 'Kā tas tiek aprēķināts';

  @override
  String get calcSource => 'Avots';

  @override
  String get calcSeveranceTitle => 'Atlaišanas pabalsts / uzteikums';

  @override
  String get calcSeveranceDesc =>
      'Aprēķiniet atlaišanas pabalstu un uzteikuma termiņu darbinieku skaita samazināšanas gadījumā';

  @override
  String get calcSeveranceSalary => 'Bruto mēneša alga';

  @override
  String get calcSeveranceTenure => 'Darba stāža gadi';

  @override
  String get calcSeveranceTotal => 'Aprēķinātais atlaišanas pabalsts';

  @override
  String get calcSeveranceNotice => 'Uzteikuma termiņš';

  @override
  String get calcSeveranceGenerateDemand => 'Sagatavot pretenzijas vēstuli';

  @override
  String get calcLimitationTitle => 'Noilguma un apelācijas termiņi';

  @override
  String get calcLimitationDesc =>
      'Pārbaudiet, vai prasības vai apelācijas termiņš ir beidzies';

  @override
  String get calcLimitationType => 'Termiņa veids';

  @override
  String get calcLimitationStart => 'Sākuma datums (notikums / lēmums)';

  @override
  String get calcLimitationPickDate => 'Izvēlēties datumu';

  @override
  String get calcLimitationDeadline => 'Termiņš';

  @override
  String get calcLimitationExpired => 'Termiņš ir beidzies';

  @override
  String calcLimitationDaysLeft(int days) {
    return 'Atlikušas $days dienas';
  }

  @override
  String get calcLimitationShifted =>
      'Pārcelts uz nākamo darba dienu (nedēļas nogale/svētki).';

  @override
  String get calcLimitationAddDeadline => 'Pievienot termiņiem';

  @override
  String get calcStateFeeTitle => 'Tiesas / valsts nodevas';

  @override
  String get calcStateFeeDesc =>
      'Atsauces uz pieteikuma nodevām pēc tiesas un stadijas';

  @override
  String get calcChildSupportTitle => 'Uzturlīdzekļi (orientējoši)';

  @override
  String get calcChildSupportDesc =>
      'Aptuvens orientējošs skaitlis — reālo summu nosaka katrā lietā atsevišķi';

  @override
  String get calcChildSupportNet => 'Maksātāja neto mēneša ienākumi';

  @override
  String get calcChildSupportChildren => 'Bērnu skaits';

  @override
  String get calcChildSupportPerChild => 'Uz vienu bērnu';

  @override
  String get calcChildSupportTotal => 'Kopā mēnesī';

  @override
  String get calcChildSupportWarning =>
      'Ļoti mainīgs. Tiesas lemj pēc bērna vajadzībām un abu vecāku maksātspējas. Izmantojiet tikai kā sākumpunktu.';

  @override
  String get docCollectTitle => 'Savācamie dokumenti';

  @override
  String get docCollectSubtitle =>
      'Savāciet tos pirms pieteikuma iesniegšanas vai vēršanās tiesā';

  @override
  String get docCollectPickPrompt => 'Kāda ir jūsu situācija?';

  @override
  String get docCollectProblemResidence => 'Uzturēšanās atļauja';

  @override
  String get docCollectProblemTenant => 'Īre / izlikšana';

  @override
  String get docCollectProblemDismissal => 'Atlaišana no darba';

  @override
  String get docCollectProblemInheritance => 'Mantošana';

  @override
  String get docCollectProblemDivorce => 'Laulības šķiršana';

  @override
  String docCollectProgress(int collected, int total) {
    return 'Savākti $collected no $total';
  }

  @override
  String get docCollectAllDone => 'Viss savākts';

  @override
  String get docCollectEmpty =>
      'Šai situācijai vēl nav pieejams dokumentu saraksts.';

  @override
  String get docCollectOptional => 'Neobligāts';

  @override
  String get docCollectWhereLabel => 'Kur to iegūt';

  @override
  String get docCollectWhyLabel => 'Kāpēc tas ir vajadzīgs';

  @override
  String get docCollectAttach => 'Pievienot failu';

  @override
  String get docCollectAttached => 'Fails pievienots';

  @override
  String get docCollectChangeFile => 'Mainīt failu';

  @override
  String get docCollectRemoveFile => 'Noņemt failu';

  @override
  String get docCollectNoFiles =>
      'Jūs vēl neesat augšupielādējis nevienu dokumentu.';

  @override
  String get docCollectPickFileTitle => 'Izvēlieties augšupielādētu dokumentu';

  @override
  String get docCollectExport => 'Eksportēt sarakstu';

  @override
  String get docCollectExportSubject => 'Mans dokumentu kontrolsaraksts';

  @override
  String get docCollectAiTitle => 'Vajag kaut ko konkrētu?';

  @override
  String get docCollectAiHint =>
      'Aprakstiet savu situāciju, un mēs ieteiksim papildu dokumentus.';

  @override
  String get docCollectAiField => 'Aprakstiet savu situāciju';

  @override
  String get docCollectAiButton => 'Ieteikt papildu dokumentus';

  @override
  String get docCollectAiLoading => 'Domā…';

  @override
  String get docCollectAiEmpty =>
      'Papildu dokumenti netika ieteikti — pamatsaraksts jūsu aprakstam šķiet pilnīgs.';

  @override
  String get docCollectAiSuggestionsTitle => 'Ieteiktie papildu dokumenti';

  @override
  String get docCollectDisclaimer =>
      'Šis ir pamatsaraksts ar parasti nepieciešamajiem dokumentiem — jūsu situācijai var būt vajadzīgs vairāk vai mazāk. Tā ir vispārīga informācija, nevis juridiska konsultācija.';

  @override
  String get docCollectRetry => 'Mēģināt vēlreiz';

  @override
  String get renewalTitle => 'Atjaunošanas radars';

  @override
  String get renewalSubtitle =>
      'Sekojiet līdzi, kad beidzas jūsu atļaujas, pase, apdrošināšana un citi dokumenti. Mēs atgādināsim 90, 30 un 7 dienas pirms katras atjaunošanas.';

  @override
  String get renewalAdd => 'Pievienot dokumentu';

  @override
  String get renewalEditTitle => 'Rediģēt dokumentu';

  @override
  String get renewalSave => 'Saglabāt';

  @override
  String get renewalRequired => 'Obligāts';

  @override
  String get renewalPickDate => 'Izvēlieties derīguma termiņa datumu';

  @override
  String get renewalLoadError =>
      'Neizdevās ielādēt jūsu dokumentus. Pavelciet, lai atsvaidzinātu.';

  @override
  String get renewalEmptyTitle => 'Vēl netiek uzraudzīts neviens dokuments';

  @override
  String get renewalEmptyBody =>
      'Pievienojiet savu uzturēšanās atļauju, pasi, apdrošināšanu vai licenci, un mēs sekosim līdzi derīguma termiņiem.';

  @override
  String get renewalGuideHint => 'Kā atjaunot →';

  @override
  String get renewalFieldType => 'Dokumenta veids';

  @override
  String get renewalFieldLabel => 'Apzīmējums';

  @override
  String get renewalFieldNumber => 'Dokumenta numurs (neobligāti)';

  @override
  String get renewalFieldJurisdiction => 'Izdevējvalsts';

  @override
  String get renewalFieldExpiry => 'Derīguma termiņa datums';

  @override
  String get renewalWindow90 => '90 dienas';

  @override
  String get renewalWindow30 => '30 dienas';

  @override
  String get renewalWindow7 => '7 dienas';

  @override
  String get renewalExpiresToday => 'Beidzas šodien';

  @override
  String renewalExpiresInDays(int days, String date) {
    return 'Beidzas pēc $days dienām · $date';
  }

  @override
  String renewalExpiredOn(String date) {
    return 'Beidzās $date';
  }

  @override
  String get renewalTypeResidencePermit => 'Uzturēšanās atļauja';

  @override
  String get renewalTypePassport => 'Pase';

  @override
  String get renewalTypeIdCard => 'Personas apliecība';

  @override
  String get renewalTypeVisa => 'Vīza';

  @override
  String get renewalTypeDrivingLicence => 'Vadītāja apliecība';

  @override
  String get renewalTypeInsurance => 'Apdrošināšana';

  @override
  String get renewalTypeWorkPermit => 'Darba atļauja';

  @override
  String get renewalTypeOther => 'Cits';

  @override
  String get costEstimateTitle => 'Izmaksu un risku novērtētājs';

  @override
  String get costEstimateSubtitle =>
      'Gūstiet aptuvenu priekšstatu par to, cik lietai varētu izmaksāt, cik ilgi tā varētu ilgt un vai ir vērts to virzīt.';

  @override
  String get costEstimateCaseTypeLabel => 'Lietas veids';

  @override
  String get costEstimateCaseTypeHint =>
      'piem., neapmaksāts rēķins, nelikumīga atlaišana, depozīta strīds';

  @override
  String get costEstimateJurisdictionLabel => 'Jurisdikcija';

  @override
  String get costEstimateAmountLabel => 'Strīda summa (neobligāti)';

  @override
  String get costEstimateAmountHint => 'piem., 12500';

  @override
  String get costEstimateDescriptionLabel =>
      'Īsi aprakstiet situāciju (neobligāti)';

  @override
  String get costEstimateB2bToggle => 'Klienta kvalifikācijas karte (B2B)';

  @override
  String get costEstimateB2bSubtitle =>
      'Kompakts pārskats ienākoša klienta ātrai izvērtēšanai.';

  @override
  String get costEstimateSubmit => 'Novērtēt manu lietu';

  @override
  String get costEstimateDisclaimer =>
      'Tikai aptuvens novērtējums — nav prognoze, garantija vai juridiska konsultācija. Faktiskās izmaksas un iznākumi katrā lietā atšķiras.';

  @override
  String get costEstimateCostsHeading => 'Aprēķinātās izmaksas';

  @override
  String get costEstimateCourtFee => 'Tiesas / valsts nodeva';

  @override
  String get costEstimateLawyerFee => 'Advokāta honorārs';

  @override
  String get costEstimateTotal => 'Kopā (aptuveni)';

  @override
  String get costEstimateDuration => 'Laiks līdz pirmajam risinājumam';

  @override
  String get costEstimateMonthsSuffix => 'mēneši';

  @override
  String get costEstimateFactorsFor => 'Jums par labu';

  @override
  String get costEstimateFactorsAgainst => 'Pret jums';

  @override
  String get costEstimateStrengthWorth => 'Visticamāk, ir vērts virzīt';

  @override
  String get costEstimateStrengthContested => 'Apstrīdams — var noiet abējādi';

  @override
  String get costEstimateStrengthWeak => 'Vājš — rīkojieties piesardzīgi';
}
