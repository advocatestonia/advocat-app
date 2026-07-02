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
  String get appearance => 'Izskats';

  @override
  String get appearanceSystem => 'Sistemas (automatiski)';

  @override
  String get appearanceLight => 'Gaiss';

  @override
  String get appearanceDark => 'Tumss';

  @override
  String get appearanceDescription => 'Izvelieties, ka izskatas Advocat';

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
      'Runajiet mikrofona. Parliecinieties, ka mikrofona pieklušana ir iespējota.';

  @override
  String get aiErrorRateLimit =>
      'Pakalpojums uz brīdi ir pārslogots. Lūdzu, mēģiniet vēlreiz pēc 1–2 minūtēm.';

  @override
  String get aiErrorOverload =>
      'MI šobrīd ir aizņemts, lūdzu, mēģiniet vēlreiz pēc minūtes.';

  @override
  String freeLimitReached(int count) {
    return 'Jūs esat izmantojis visus $count bezmaksas AI ziņojumus. Jauniniet uz Legal Counsel neierobežotai AI palīdzībai!';
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
  String get rateAppComingSoon => 'Drīzumā lietotņu veikalos!';

  @override
  String get dataCopiedToClipboard => 'Dati nokopēti starpliktuvē';

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
  String get fiveAiMessagesTotal => '5 AI ziņojumi (uz visiem laikiem)';

  @override
  String get hundredAiMessagesDay => '100 AI ziņojumi dienā';

  @override
  String get unlimitedAiMessages => 'Neierobežoti AI ziņojumi';

  @override
  String get voiceInput => 'Balss ievade';

  @override
  String get strategyRecommendations => 'Stratēģijas ieteikumi';

  @override
  String get foundingMemberNote =>
      'Dibinātājbiedrs: 9.99€/mēn. pirmos 3 mēnešus';

  @override
  String get saveTwentyPercent => 'Ietaupiet 20%';

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
      'Es piekrītu manu datu apstrādei AI juridiskās palīdzības nodrošināšanai (obligati)';

  @override
  String get gdprConsentAnalytics =>
      'Es piekrītu analītikas izmantošanai pakalpojuma uzlabošanai (neobligati)';

  @override
  String get gdprArt9Intro =>
      'Šī lietotne apstrādā īpašu kategoriju personas datus saskaņā ar VDAR 9. pantu, tostarp:';

  @override
  String get gdprSpecialLegalCases =>
      'Jūsu lietas informāciju un tiesas dokumentus';

  @override
  String get gdprSpecialNationality => 'Pilsonību un imigrācijas statusu';

  @override
  String get gdprConsentLegalData =>
      'Es piekrītu savu lietas datu, pilsonības un imigrācijas statusa apstrādei ar AI (obligati)';

  @override
  String get gdprConsentVoice =>
      'Es piekrītu balss ierakstu apstrādei (neobligati)';

  @override
  String get gdprViewPrivacyPolicy => 'Skatīt privātuma politiku';

  @override
  String get legalInformation => 'Juridiskā informācija';

  @override
  String get legalEntityName => 'Vorantis OÜ';

  @override
  String get legalRegistryCode => 'Reģistrācijas kods: 17098992';

  @override
  String get legalAddress =>
      'Harju maakond, Tallinn, Kesklinna linnaosa, Tornimäe tn 5, 10145';

  @override
  String get legalEmail => 'E-pasts: support@advocat.ee';

  @override
  String get legalRegistry =>
      'Reģistrēts Igaunijas Komercreģistrā (Äriregister)';

  @override
  String get aiGeneratedDisclaimer => 'Ģenerēts ar AI • Nav juridisks padoms';

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
      'Cietušo tiesības, ārkārtas palīdzība, ierobežojošie rīkojumi';

  @override
  String get rightCallEmergency =>
      'Jums ir tiesības jebkurā ārkārtas situācijā zvanīt 112 — policijai, ātrajai palīdzībai, ugunsdzēsējiem';

  @override
  String get rightVictimProtection =>
      'Kā cietušajam jums ir tiesības uz aizsardzību, atbalstu un informāciju par savu lietu';

  @override
  String get rightRestrainingOrder =>
      'Jūs varat pieteikties ierobežojošam rīkojumam (lähestymiskielto), lai turētu varmāku tālāk';

  @override
  String get rightVictimInterpreter =>
      'Jums ir tiesības uz tulku visā tiesvedības procesā';

  @override
  String get rightMedicalHelp =>
      'Jums ir tiesības uz tūlītu medicīnisko palīdzību un traumu dokumentēšanu';

  @override
  String get rightShelter =>
      'Jums ir tiesības uz ārkārtas patvērumu — sazinieties ar patvērumu vai sociālo dienestu';

  @override
  String get mustReportDanger =>
      'Ja kāds ir tiešās briesmās, nekavējoties zvaniet 112';

  @override
  String get mustDocumentInjuries =>
      'Dokumentējiet visas traumas — fotogrāfijas, medicīniskos ierakstus, rakstiskas piezīmes';

  @override
  String get domesticActionCallEmergency =>
      'Zvaniet 112, ja esat tiešās briesmās';

  @override
  String get domesticActionGoToSafe =>
      'Dodieties uz drošu vietu — patvērumu, pie drauga, sabiedriskā vietā';

  @override
  String get domesticActionDocumentEverything =>
      'Dokumentējiet traumas: uzņemiet fotogrāfijas, saņemiet medicīniskos ierakstus';

  @override
  String get domesticActionFilePoliceReport =>
      'Iesniedziet policijas ziņojumu — to var izdarīt arī vēlāk';

  @override
  String get domesticActionContactShelter =>
      'Sazinieties ar patvērumu vai krīzes tālruni';

  @override
  String get domesticActionApplyRestraining =>
      'Pieteikties ierobežojošam rīkojumam ar policijas vai tiesas starpniecību';

  @override
  String get domesticFactRestrainingOrder =>
      'Somijā ierobežojošu rīkojumu (lähestymiskielto) var izdot pat bez krimināllietas. Tas aizliedz šai personai ar jūms sazināties vai jums tuvoties.';

  @override
  String get domesticFactVictimDirective =>
      'Saskaņā ar ES Cietušo direktīvu 2012/29/ES jums ir tiesības tikt izturam ar cieņu, saņemt informāciju jums saprotamā valodā un pieklūt cietušo atbalsta pakalpojumiem — neatkarīgi no jūsu uzturēšanās statusa.';

  @override
  String get domesticDeadlinePoliceReport =>
      'Policijas ziņojuma iesniegšana — stingra termiņa nav, taču ātrāk ir labāk pierādījumiem';

  @override
  String get domesticDeadlineRestraining =>
      'Ierobežojošu rīkojumu var pieprastīt jebkurā laikā';

  @override
  String get contactEmergency => 'Ārkārtas numurs';

  @override
  String get contactShelter => 'Turvakoti (patvērums) uzticibas tālrunis';

  @override
  String get contactCrisisHelpline => 'Krīzes tālrunis (Kriisipuhelin)';

  @override
  String get contactNollaLinja =>
      'Nollalinja — vardarbības pret sievietēm uzticibas tālrunis';

  @override
  String get inheritance => 'Mantojums';

  @override
  String get inheritanceDesc =>
      'Testamenti, mantojums, mantinieku tiesības, obligatā mantojuma daļa, mantoanas process';

  @override
  String get rightInheritanceForced =>
      'Obligatie mantinieki (bērni, laulātais) ir tiesiģi saņemt obligato mantojuma daļu neatkarīgi no testamenta';

  @override
  String get rightInheritanceWill =>
      'Jums ir tiesības sastādīt testamentu par sava īpašuma sadali — notariāli apliecinātiem testamentiem ir vislielakais juridiskais spēks';

  @override
  String get rightInheritanceRenounce =>
      'Jūs varat atteikties no mantojuma 3 mēnešu laikā pēc uzzināšanas par to';

  @override
  String get rightInheritanceInfo =>
      'Jums ir tiesības saņemt informāciju par mantojuma masu no bankām un reģistriem';

  @override
  String get rightInheritanceDispute =>
      'Jūs varat apstrīdēt netaisnīgu testamentu tiesa likumā noteiktā noilguma termiņā';

  @override
  String get mustFileInheritance =>
      'Iesniedziet mantoanas lietu pie notāra saprātīgā termiņā';

  @override
  String get mustNotifyHeirs =>
      'Visi zināmie mantinieki jāinformē par mantoanas procesu';

  @override
  String get inheritanceActionGatherDocs =>
      'Savāciet visus dokumentus: miršanas apliecību, testamentu, īpašuma dokumentus, bankas izrakstus';

  @override
  String get inheritanceActionContactNotary =>
      'Sazinieties ar notāru, lai atvērtu mantoanas lietu';

  @override
  String get inheritanceActionCheckDebts =>
      'Pirms mantojuma pieņemšanas pārbaudiet, vai mantojuma masā nav parādu';

  @override
  String get inheritanceActionFileCourt =>
      'Ja testaments tiek apstrīdēts, iesniedziet prasību tiesā';

  @override
  String get inheritanceDeadlineRenounce =>
      '3 mēneši, lai atteiktos no mantojuma pēc uzzināšanas par to';

  @override
  String get inheritanceDeadlineDispute =>
      'Testamenta apstrīdēšanas noilgums: atkarīgs no pamatojuma';

  @override
  String get inheritanceFactForced =>
      'Igaunijā pēcnācējiem un laulātajam ir tiesības uz obligato mantojuma daļu (1/2 no likumīgās daļas) pat tad, ja viņi izslēgti no testamenta';

  @override
  String get inheritanceFactNotary =>
      'Visiem mantoanas procesiem Igaunijā jānotiek caur notāru — šo soli nevar izlaist';

  @override
  String get consumerProtection => 'Patērētāju aizsardzība';

  @override
  String get consumerProtectionDesc =>
      'Krāpšana, defektīvas preces, atgriešana, negodīgi pārdevēji';

  @override
  String get rightReturnOnline =>
      'Jums ir 14 dienas, lai atceltu tiešsaistes pirkumu bez iemesla norādīšanas (ES atteikuma tiesības)';

  @override
  String get rightDefectiveProduct =>
      'Ja prece ir defektīva, jums ir tiesības uz remontu, aizstāšanu vai naudas atmaksu';

  @override
  String get rightClearPricing =>
      'Pārdevējiem jāuzrāda skaidra cena, ieklaujot visas maksas — slēptas izmaksas ir nelikumīgas';

  @override
  String get rightComplainBoard =>
      'Jūs varat iesniegt bezmaksas sūdzību Patēretāju strīdu komitejai';

  @override
  String get rightProtectionFraud =>
      'Jūs esat aizsargāts pret negodīgu komercpraksi un krāpšanu';

  @override
  String get mustKeepReceipts =>
      'Saglabājiet visus čekus, līgumus un sarakstes ar pārdevējiem';

  @override
  String get mustActTimely =>
      'Ziņojiet pārdevējam par defektiem saprātīgā termiņā pēc to atklāšanas';

  @override
  String get consumerActionKeepEvidence =>
      'Saglabājiet čekus, ekrānuzņēmumus, e-pastus un visus pirkuma apliecinājumus';

  @override
  String get consumerActionContactSeller =>
      'Vispirms sazinieties ar pārdevēju — rakstiski izskaidrojiet problēmu';

  @override
  String get consumerActionFileComplaint =>
      'Iesniedziet sūdzību Patēretāju strīdu komitejai (kuluttajariitalautakunta)';

  @override
  String get consumerActionContactAuthority =>
      'Sazinieties ar Patēretāju konsultāciju dienestu bezmaksas palīdzībai';

  @override
  String get consumerActionReportFraud =>
      'Ziņojiet par krāpšanu policijai un Patēretāju tiesību aizsardzības ombudam';

  @override
  String get consumerFactWithdrawal =>
      'Saskaņā ar ES Patēretāju tiesību direktīvu 2011/83/ES jums ir 14 dienas, lai atteiktos no jebkura tiešsaistes vai distances pirkuma — bez jautājumiem. Pārdevējam nauda jāatmaksā 14 dienu laikā.';

  @override
  String get consumerFactWarranty =>
      'Somijā pārdevējs ir atbildīgs par preces defektiem saprātīgu laika periodā (bieži 2+ gadi). Tas ir atsevišķi no jebkuras ražotāja garantijas.';

  @override
  String get consumerDeadlineWithdrawal =>
      'Tiešsaistes pirkuma atteikums — 14 dienas no piegades';

  @override
  String get consumerDeadlineDefect =>
      'Ziņot pārdevējam par defektu — 2 mēnešu laikā pēc atklāšanas (ieteicams)';

  @override
  String get contactConsumerAdvisory => 'Patēretāju konsultāciju dienests';

  @override
  String get contactConsumerOmbudsman =>
      'Patēretāju tiesību aizsardzības ombuds (Kuluttaja-asiamies)';

  @override
  String get contactConsumerDisputesBoardDirect => 'Patēretāju strīdu komiteja';

  @override
  String get caseTypeStepLabel => 'Lietas veids';

  @override
  String get detailsStepLabel => 'Dati';

  @override
  String get documentsStepLabel => 'Dokumenti';

  @override
  String get whatTypeOfCase => 'Kāda veida lieta tā ir?';

  @override
  String get selectCategoryDescription =>
      'Izvēlieties kategoriju, kas vislābāk apraksta jūsu situāciju.';

  @override
  String get tellUsAboutCase => 'Pastāstiet mums par savu lietu';

  @override
  String get aiHelpsUnderstand =>
      'Šī informācija palīdz mūsu AI labāk izprast jūsu situāciju.';

  @override
  String get caseTitleHint => 'piem., Uzturēšanās atļaujas pārsūdzība 2026';

  @override
  String get countryJurisdiction => 'Valsts / jurisdikcija';

  @override
  String get selectCountryHint => 'Izvēlieties valsti';

  @override
  String get referenceNumberHint => 'piem., UMA/12345/2026';

  @override
  String get descriptionOptional => 'Apraksts (neobligats)';

  @override
  String get descriptionHint =>
      'Īsi aprakstiet savu situāciju. Kas notika? Kāds lēmums tika pieņemts?';

  @override
  String get uploadFirstDocument => 'Augupēieladējiet savu pirmo dokumentu';

  @override
  String get uploadDocumentDescription =>
      'Augupēieladējiet lēmuma vēstuli vai citu attiecīgu dokumentu. Šo soli var izlaist un dokumentus pievienot vēlāk.';

  @override
  String get tapToUploadFile => 'Pieskarieties, lai augupēieladētu failu';

  @override
  String get fileSizeLimit => 'PDF, JPG, PNG līdz 25 MB';

  @override
  String get addDocumentsLaterHint =>
      'Dokumentus vienmēr varat pievienot vēlāk lietas detāļu ekrānā.';

  @override
  String get callAI => 'Zvanīt AI';

  @override
  String get comingSoon => 'Drīzumā';

  @override
  String get encrypted => 'Šifrēts';

  @override
  String get typing => 'Raksta…';

  @override
  String get online => 'Tiešsaistē';

  @override
  String get chatWelcomeSubtitle =>
      'Es izanalizēšu situāciju, pārbaudīšu dokumentus, atradīšu kļūdas un ieteikšu, ko darīt.';

  @override
  String get tapMicrophoneToSpeak => 'Pieskarieties mikrofonam, lai runātu';

  @override
  String get categoryEssential => 'Būtiskākais';

  @override
  String get categoryPolice => 'Policija';

  @override
  String get categoryWork => 'Darbs';

  @override
  String get categoryHousing => 'Mājoklis';

  @override
  String get categoryConsumer => 'Patēretājs';

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
  String get freeAidThreshold => 'Bezmaksas palīdzības slieksnis';

  @override
  String get partialAidThreshold => 'Daļējas palīdzības slieksnis';

  @override
  String get assetLimit => 'Aktivu limits';

  @override
  String get whereToApplyLabel => 'Kur pieteikties';

  @override
  String get phoneLabel => 'Tālrunis';

  @override
  String get websiteLabel => 'Tīmekļa vietne';

  @override
  String get disclaimerCollapsed => 'Tikai AI norādes';

  @override
  String get disclaimerExpanded =>
      'AI asistents — nav juridisks padoms. Vienmēr pārbaudiet pie kvalificēta jurista.';

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
  String get categoryChildren => 'Bērni';

  @override
  String get categoryDigital => 'Digitāls';

  @override
  String get childrenRights => 'Bērnu tiesības un uzturlīdzekļi';

  @override
  String get childrenRightsDesc =>
      'Uzturlīdzekļi, alimenti, aizsardzība, valsts garantijas';

  @override
  String get cyberbullying => 'Kiberterorizeašana un tiešsaistes uzmākšanās';

  @override
  String get cyberbullyingDesc =>
      'Draudi, privātuma pārkāpumi, apmelošana tiešsaistē';

  @override
  String get rightChildSupport =>
      'Abiem vecākiem ir juridisks pienākums finansiāli uzturēt savu bērnu (Perekonnaseadus § 100–102)';

  @override
  String get rightMinimumAlimony =>
      'Minimālais uzturlīdzeklis Igaunijā: bāzes summa (295,86 €) + 3% no iepriešējā gada vidējās bruto algas (PKS § 101). No 01.04.2026 — 318,62 €/mēnesī par bērnu. Tiek atjaunināts katru gadu 1. aprīlī. Kalkulators: alimendid.ee';

  @override
  String get rightCourtAlimony =>
      'Uzturlīdzekļus var pieprastīt caur apriņķa tiesu (maakohus) — prasībām līdz 6400 € jurists nav nepieciešams';

  @override
  String get rightBailiffEnforcement =>
      'Ja vecāks atsakās maksāt, tiesu izpildītājs (kohtutäitur) var izpildīt tiesas lēmumu, tostarp veikt algas ieturejumu';

  @override
  String get rightStateAlimonyGuarantee =>
      'Ja vecāks nemaksā, valsts caur Sotsiaalkindlustusamet nodrošina elatisabi (uzturēšanas pabalstu) — līdz 100 €/mēnesī par bērnu';

  @override
  String get rightChildEducation =>
      'Katram bērnam ir tiesības uz izglītību, veselibas aprūpi un aizsardzību pret vardarbību (Lastekaitseseadus § 4–5)';

  @override
  String get rightChildContact =>
      'Bērnam ir tiesības uzturēt kontaktu ar abiem vecākiem, ja vien tiesa nelemj citādi (PKS § 143)';

  @override
  String get mustFileCourtClaim =>
      'Lai saņemtu uzturlīdzekļus, jāiesniedz prasība tiesā vai rakstiski jāvienojas par summu';

  @override
  String get mustNotifyAddressChange =>
      'Ja saņemat elatisabi, informējiet Sotsiaalkindlustusamet par adreses maiņu';

  @override
  String get childrenActionGatherDocs =>
      'Savāciet bērna dzimšanas apliecību, savu ID un izdevumu apliecinājumus';

  @override
  String get childrenActionFileCourtClaim =>
      'Iesniedziet uzturlīdzekļu prasību apriņķa tiesā (maakohus) — to var izdarīt tiešsaistē caur e-toimik';

  @override
  String get childrenActionApplyElatisabi =>
      'Ja vecāks nemaksā, pieteikties valsts uzturlīdzekļu garantijai (elatisabi) Sotsiaalkindlustusamet';

  @override
  String get childrenActionContactBailiff =>
      'Sazinieties ar tiesu izpildītāju (kohtutäitur), lai izpildītu tiesas lēmumu';

  @override
  String get childrenActionCallLasteabi =>
      'Zvaniet Lasteabi 116 111 — bērnu palīdzības tālrunis, bezmaksas, visu diennakti';

  @override
  String get childrenDeadlineElatisabi =>
      'Pieteikšanās elatisabi — pēc tiesas lēmuma, stingra termiņa nav, taču process aizņem laiku';

  @override
  String get childrenDeadlineCourt =>
      'Uzturlīdzekļus var pieprastīt retroaktivi līdz 1 gadam pirms prasības iesniegšanas tiesā';

  @override
  String get childrenFactMinimum =>
      'No 01.04.2026 minimālais uzturlīdzeklis ir 318,62 €/mēnesī par bērnu. Formula: bāzes summa (295,86 €) + 3% no iepriešējā gada vidējās bruto algas. Tiek atjaunināts katru gadu 1. aprīlī. Vecāks nedrīkst vienoties par mazaku summu. Kalkulators: alimendid.ee';

  @override
  String get childrenFactElatisabi =>
      'Igaunijas valsts uzturlīdzekļu garantija (elatisabi) tika ieviesta 2017. gadā, lai aizsargātu bērnus, kad vecāks atsakās maksāt. Valsts maksā un pēc tam piedzen summu no parādnieka vecāka.';

  @override
  String get rightReportCybercrime =>
      'Jums ir tiesības ziņot policijai par draudiem, uzmākšanos un identitātes zādzību tiešsaistē (Karistusseadustik § 120, § 157¹)';

  @override
  String get rightContentRemoval =>
      'Jūs varat pieprastīt apmelojoša vai privāta satura noņemšanu no platformām un pieprastīt izņemšanu saskaņā ar VDAR';

  @override
  String get rightMoralDamageCompensation =>
      'Jūs varat pieprastīt kompensāciju par morālo kaitējumu, ko izraisījusi kiberterorizeašana (Võlaõigusseadus § 1043–1055)';

  @override
  String get rightPrivacyProtection =>
      'Jūsu privātā dzīve ir aizsargāta — jūsu fotogrāfiju, ziņu vai personas datu neatļauta izplatīšana ir nelikumīga (KarS § 157)';

  @override
  String get rightDataProtection =>
      'Ziņojiet par datu aizsardzības pārkāpumiem (jūsu datu neatļauta izmantošana) Andmekaitse Inspektsioon';

  @override
  String get rightDefamationAction =>
      'Apmelošana (laimamine) ir civiltiesisks pārkāpums — jūs varat iesudzēt tiesā par zaudējumiem un pieprastīt publisku atsaukumu (KarS § 247 (atcelts), VÕS § 1047)';

  @override
  String get mustCollectEvidence =>
      'Savāciet un saglabājiet visus pierādījumus — ekrānuzņēmumus, saites, datumus un liecinieku informāciju';

  @override
  String get mustNotRetaliate =>
      'Neatriebieties un neiesaistieties pretuzbrukumos — tas var vājināt jūsu lietu';

  @override
  String get cyberActionScreenshots =>
      'Uzņemiet ekrānuzņēmumus no visas uzmākšanās — saglabājiet saites, datumus, lietotājvārdus un saturu';

  @override
  String get cyberActionReportPolice =>
      'Iesniedziet policijas ziņojumu tuvākajā iecirknī vai tiešsaistē politsei.ee';

  @override
  String get cyberActionReportPlatform =>
      'Ziņojiet par saturu sociālo mediju platformai tā noņemšanai';

  @override
  String get cyberActionContactDPA =>
      'Sazinieties ar Andmekaitse Inspektsioon, ja jūsu personas dati tika laūnprātīgi izmantoti';

  @override
  String get cyberActionConsultLawyer =>
      'Konsultējieties ar juristu par civiltiesiskiem zaudējumiem — bezmaksas juridiskā palīdzība pieejama caur Riigi Õigusabi';

  @override
  String get cyberDeadlineCriminal =>
      'Kriminālsūdzība — stingra termiņa nav, taču ziņojiet nekavējoties labākam rezultātam';

  @override
  String get cyberDeadlineCivil =>
      'Civilprasība par zaudējumiem — līdz 3 gadiem no pārkāpuma uzzināšanas brīdža (TsÜS § 150)';

  @override
  String get cyberFactPrivacy =>
      'Igaunijā par kāda intīmo attēlu neatļautu izplatīšanu var piespriest līdz 3 gadiem cietumā saskaņā ar Karistusseadustik § 157¹ (privātuma pārkāpums).';

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
  String get deadlineRadarTitle => 'Gaidāmie termiņi';

  @override
  String get deadlineRadarEmpty => 'Nav gaidāmu termiņu';

  @override
  String get deadlineRadarViewAll => 'Skatīt visus';

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
  String get deadlineCardTomorrow => 'rīt';

  @override
  String get deadlineCardToday => 'šodien';

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
  String get deadlineCardMarkComplete => 'Atzīmēt kā pabeigtu';

  @override
  String get deadlineCardSnooze => 'Atlikt';

  @override
  String get deadlineCardSnooze3d => 'Atlikt uz 3 dienām';

  @override
  String get deadlineCardSnooze7d => 'Atlikt uz 7 dienām';

  @override
  String get deadlineCardSnoozeCustom => 'Izvēlēties datumu';

  @override
  String get deadlineCardEdit => 'Rediģēt';

  @override
  String get deadlineCardDelete => 'Arhivēt';

  @override
  String get deadlineCardSourceLabelPdf => 'no PDF';

  @override
  String get deadlineCardSourceLabelIntake => 'no anketas';

  @override
  String get deadlineCardSourceLabelManual => 'pievienots manuāli';

  @override
  String get deadlineCardSourceLabelEmail => 'no e-pasta';

  @override
  String get deadlineCardSourceLabelHaikuExtract => 'AI izgūts';

  @override
  String get deadlineCardSourceLabelStatutoryTemplate => 'likuma veidne';

  @override
  String deadlineBannerCritical(String title, String when) {
    return 'Kritisks termiņš $title $when';
  }

  @override
  String get deadlineBannerDismiss => 'Aizvērt';

  @override
  String get deadlineBannerOpen => 'Atvērt termiņu';

  @override
  String deadlineHolidayShifted(String original, String reason) {
    return 'Pārcelts no $original sakarā ar $reason';
  }

  @override
  String get deadlinePermissionAskTitle => 'Iespējot termiņu atgādinājumus?';

  @override
  String get deadlinePermissionAskBody =>
      'Mēs jums atgādināsim 7, 3 un 1 dienu pirms katra likumā noteiktā termiņa, kā arī tajā rītā. Netiek izmantots mārketingam.';

  @override
  String get deadlinePermissionAllow => 'Atļaut';

  @override
  String get deadlinePermissionLater => 'Vēlāk';

  @override
  String get deadlineSettingsSection => 'Termiņu atgādinājumi';

  @override
  String get deadlineSettingsPushChannel => 'Push paziņojumi';

  @override
  String get deadlineSettingsEmailChannel => 'E-pasts (tikai kritiski)';

  @override
  String get deadlineSettingsInAppChannel => 'Paziņojumi lietotnē';

  @override
  String get deadlineSettingsCriticalBypass =>
      'Kritiskie atgādinājumi apiet klusuma stundas';

  @override
  String get deadlineSettingsQuietHours => 'Klusuma stundas';

  @override
  String deadlineSettingsQuietHoursBadge(String start, String end) {
    return 'Klusums $start–$end';
  }

  @override
  String get deadlineCaseScreenTitle => 'Lietas termiņi';

  @override
  String get deadlineAddManualCta => 'Pievienot termiņu';

  @override
  String get deadlineFormTitle => 'Nosaukums';

  @override
  String get deadlineFormDescription => 'Apraksts (neobligats)';

  @override
  String get deadlineFormStatuteTemplate => 'Likuma veidne';

  @override
  String get deadlineFormStatuteTemplateNone => 'Nav (manuāli)';

  @override
  String get deadlineFormDeadlineAt => 'Termiņa datums';

  @override
  String get deadlineFormPriority => 'Prioritāte';

  @override
  String get deadlineFormSave => 'Saglabāt';

  @override
  String get deadlineFormCancel => 'Atcelt';

  @override
  String get deadlineCompletedNotePrompt => 'Pievienot piezīmi (neobligati)';

  @override
  String get deadlineCompletedNoteSave => 'Saglabāt';

  @override
  String get inboxTitle => 'Iesutne';

  @override
  String get inboxEmptyTitle => 'Nekas nav gaidīšanā';

  @override
  String get inboxEmptyBody =>
      'Jaunas e-pasta sarakstes parādīsies šeit pēc to izskatīšanas.';

  @override
  String get inboxApproveSend => 'Apstiprināt un nosūtīt';

  @override
  String get inboxEditDraft => 'Rediģēt';

  @override
  String get inboxSnooze => 'Atlikt';

  @override
  String get inboxArchive => 'Arhivēt';

  @override
  String get inboxFilterAll => 'Visi';

  @override
  String get inboxConfirmSendTitle => 'Nosūtīt sagatavoto atbildi?';

  @override
  String get inboxConfirmSendBody =>
      'Advocat nosūtīs AI sagatavoto atbildi, izmantojot jūsu pievienoto Gmail. Nākamajā ekrānā vēl varēsiet pārskatīt tekstu.';

  @override
  String get inboxSendButton => 'Sūtīt';

  @override
  String get inboxSentToast => 'Nosūtīts.';

  @override
  String get inboxAlreadySentToast => 'Jau nosūtīts.';

  @override
  String get inboxSendErrorToast =>
      'Neizdevās nosūtīt atbildi. Pieskarieties, lai mēģinātu vēlreiz.';

  @override
  String get inboxSnoozedToast => 'Atlikts uz 24 h.';

  @override
  String get inboxArchivedToast => 'Arhivēts.';

  @override
  String get inboxDraftLoadError => 'Neizdevās ielādēt melnrakstu.';

  @override
  String get inboxDeadlineToday => 'šodien';

  @override
  String get inboxDeadlineTomorrow => 'rīt';

  @override
  String inboxDeadlineInDays(int days) {
    return 'pēc ${days}d';
  }

  @override
  String inboxDeadlineOverdue(int days) {
    return 'nokavēts ${days}d';
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
  String get workspaceTabOverview => 'Pārskats';

  @override
  String get workspaceTabChat => 'Tērzēšana';

  @override
  String get workspaceTabDrafts => 'Melnraksti';

  @override
  String get workspaceOverviewEmpty =>
      'Pievienojiet dokumentus, lai izveidotu kopsavilkumu.';

  @override
  String get workspaceTimelineEmpty => 'Vēl nav notikumu.';

  @override
  String get workspaceDocumentsEmpty =>
      'Nav dokumentu. Augupēieladējiet, izmantojot skenēšanu.';

  @override
  String get workspaceDraftsEmpty => 'Vēl nav melnrakstu.';

  @override
  String get workspaceInboxEmpty => 'Nav saistītu e-pastu.';

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
  String get draftsTab => 'Melnraksti';

  @override
  String get draftingTitle => 'Rakstīšanas studija';

  @override
  String get draftingEmpty => 'Tukšs melnraksts';

  @override
  String get draftingPlaceholder => 'Sāciet rakstīt savu melnrakstu…';

  @override
  String get draftingDraftsList => 'Mani melnraksti';

  @override
  String get draftingSave => 'Saglabāt';

  @override
  String get draftingSaved => 'Saglabāts';

  @override
  String get draftingSavedJustNow => 'Tikko saglabāts';

  @override
  String get draftingAiRevise => 'Rediģēt ar AI';

  @override
  String get draftingExportPdf => 'Eksportēt PDF';

  @override
  String get draftingExportDocx => 'Eksportēt DOCX';

  @override
  String get draftingExportMd => 'Eksportēt Markdown';

  @override
  String get draftingDeleteDraft => 'Dzēst melnrakstu';

  @override
  String get draftingConfirmDelete => 'Dzēst šo melnrakstu?';

  @override
  String get draftingConfirmDeleteMessage => 'Šo darbību nevar atsaukt.';

  @override
  String get draftingConfirm => 'Dzēst';

  @override
  String get draftingCancel => 'Atcelt';

  @override
  String draftingDraftReplyTo(String name) {
    return 'Atbildēt $name';
  }

  @override
  String get draftingUntitled => 'Bez nosaukuma';

  @override
  String get draftingTitleHint => 'Nosaukums (neobligats)';

  @override
  String get draftingAiReviseTitle => 'Rediģēt ar AI';

  @override
  String get draftingAiReviseSelectionLabel => 'Iezimētais teksts:';

  @override
  String get draftingAiReviseInstructionLabel => 'Instrukcija (neobligata)';

  @override
  String get draftingAiReviseInstructionHint =>
      'piem., \"padarīt formālāku\" vai \"saīsināt\"';

  @override
  String get draftingAiReviseRunButton => 'Ģenerēt labojumu';

  @override
  String get draftingAiReviseSuggestionLabel => 'Ieteiktais labojums:';

  @override
  String get draftingAiReviseChangesLabel => 'Izmaiņas:';

  @override
  String get draftingAiReviseAccept => 'Pieņemt';

  @override
  String get draftingAiReviseReject => 'Noraidīt';

  @override
  String get draftingFormatBold => 'Treknraksts';

  @override
  String get draftingFormatItalic => 'Slīpraksts';

  @override
  String get draftingFormatHeading => 'Virsraksts';

  @override
  String get draftingFormatBullet => 'Aizzimēju saraksts';

  @override
  String get draftingFormatNumbered => 'Numurēts saraksts';

  @override
  String get draftingEmptyListMessage => 'Jums vēl nav melnrakstu.';

  @override
  String get draftingEmptyListAction => 'Jauns melnraksts';

  @override
  String get draftingExporting => 'Eksportē…';

  @override
  String get draftingExportFailed => 'Eksportēšana neizdevās';

  @override
  String get draftingSaveFailed => 'Saglabāšana neizdevās';

  @override
  String get draftingNewDraft => 'Jauns melnraksts';

  @override
  String get vaultNoteChip => 'Glabātuves piezīme';

  @override
  String get saveToVault => 'Saglabāt Glabātuvē';

  @override
  String get savingToVault => 'Saglabā Glabātuvē…';

  @override
  String get savedToVault => 'Saglabāts Glabātuvē';

  @override
  String get vaultNoteTitlePrefix => 'Piezīme: ';

  @override
  String get openInVault => 'Atvērt Glabātuvē';

  @override
  String get saveToVaultFailed => 'Saglabāšana Glabātuvē neizdevās';

  @override
  String get pdfWorkerUnavailable =>
      'PDF eksports īslaicīgi nav pieejams. Lūdzu, izmēģiniet DOCX vai Markdown.';

  @override
  String get draftingVersionHistory => 'Versiju vēsture';

  @override
  String get emptyHomeTitle => 'Laipni lūdzam Advocat';

  @override
  String get emptyHomeBody =>
      'Izvēlieties sākumpunktu — mēs uzņemsimies juridisko darbu.';

  @override
  String get intentChip1 => 'Saņēmu sodu';

  @override
  String get intentChip2 => 'Atļauja atteikta';

  @override
  String get intentChip3 => 'Problēma ar līgumu';

  @override
  String get emptyCasesTitle => 'Vēl nav lietu';

  @override
  String get emptyCasesCta => 'Sākt lietu';

  @override
  String get emptyDraftsTitle => 'Vēl nav melnrakstu';

  @override
  String get emptyDraftsCta => 'Izveidot melnrakstu';

  @override
  String get emptyChatTitle => 'Vaicājiet Advocat jebko';

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
  String get referralInviteFriends => 'Uzaiciniet draugus';

  @override
  String get referralYourCode => 'Jūsu kods';

  @override
  String get referralCopiedToast => 'Kods nokopēts starpliktuvē';

  @override
  String get referralReward =>
      'Saņemiet 1 mēnesi Counsel bez maksas par katru draugu, kas nofromē abonementu.';

  @override
  String get referralInvited => 'Uzaicināti draugi';

  @override
  String get referralRewardsEarned => 'Nopelnītie bezmaksas mēneši';

  @override
  String get deadlineUrgencyToday => 'Šodien un nokavēts';

  @override
  String get deadlineUrgencyWeek => 'Šonedēļ';

  @override
  String get deadlineUrgencyMonth => 'Šomēnes';

  @override
  String get deadlineUrgencyLater => 'Vēlāk';

  @override
  String get deadlineAddManual => 'Pievienot termiņu';

  @override
  String get deadlineSnoozeBy => 'Atlikt';

  @override
  String get deadlineSnooze1d => 'Atlikt uz 1 dienu';

  @override
  String get deadlineSnooze3d => 'Atlikt uz 3 dienām';

  @override
  String get deadlineSnooze7d => 'Atlikt uz 7 dienām';

  @override
  String get deadlineDismiss => 'Aizvērt';

  @override
  String get deadlineExportIcs => 'Pievienot kalendāram';

  @override
  String get deadlineSource => 'Avots';

  @override
  String get deadlineEmpty =>
      'Vēl nav termiņu. Termiņi tiek veidoti automatiski no jūsu e-pastiem un dokumentiem — vai pievienojiet vienu manuāli ar + pogu.';

  @override
  String get deadlineNewTitle => 'Jauns termiņš';

  @override
  String get deadlineFieldTitle => 'Nosaukums';

  @override
  String get deadlineFieldDueDate => 'Izpildes datums';

  @override
  String get deadlineFieldNotes => 'Piezīmes (neobligatas)';

  @override
  String get deadlineSaved => 'Termiņš saglabāts';

  @override
  String get deadlineSaveFailed => 'Neizdevās saglabāt termiņu';

  @override
  String get deadlineUrgentBannerSingle => '1 termiņš šodien vai nokavēts';

  @override
  String deadlineUrgentBannerMany(int count) {
    return '$count termiņi šodien vai nokavēti';
  }

  @override
  String deadlineDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'atlikušas $count dienas',
      one: 'atlikusi 1 diena',
      zero: 'šodien',
    );
    return '$_temp0';
  }

  @override
  String deadlineDaysOverdue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'nokavētas $count dienas',
      one: 'nokavēta 1 diena',
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
  String get deadlineEuRadarTitle => 'ES termiņu radars (priekšskatījums)';

  @override
  String get deadlineEuRadarSubtitle =>
      'Hipotētiski ES procesuālie termiņi — testa dati';

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
