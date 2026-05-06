// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Estonian (`et`).
class AppLocalizationsEt extends AppLocalizations {
  AppLocalizationsEt([String locale = 'et']) : super(locale);

  @override
  String get about => 'Rakenduse teave';

  @override
  String get aboutSection => 'TEAVE';

  @override
  String get accidents => 'Õnnetused';

  @override
  String get active => 'Aktiivsed';

  @override
  String get activeCases => 'Aktiivsed juhtumid';

  @override
  String get addedToAppeal => 'Kaebusele lisatud';

  @override
  String get agreeToTerms => 'Nõustun ';

  @override
  String get aiAnalysis => 'AI analüüs';

  @override
  String get aiAssistant => 'AI õigusabi';

  @override
  String get aiChat => 'AI vestlus';

  @override
  String get all => 'Kõik';

  @override
  String get alreadyHaveAccount => 'Kas teil on juba konto? ';

  @override
  String get analyzing => 'Analüüsimine…';

  @override
  String get aiAnalyzing => 'AI analüüsib…';

  @override
  String get speakIntoMicHint =>
      'Rääkige mikrofoni. Veenduge, et mikrofon on sisse lülitatud.';

  @override
  String get aiErrorRateLimit =>
      'Teenus on hetkel ülekoormatud. Proovige 1–2 minuti pärast uuesti.';

  @override
  String get aiErrorOverload =>
      'AI on praegu hõivatud — proovige minuti pärast uuesti.';

  @override
  String freeLimitReached(int count) {
    return 'Teie $count tasuta AI-sõnumit on otsas. Uuendage Õigusnõustaja paketile, et saada piiramatu juurdepääs.';
  }

  @override
  String get andWord => ' ja ';

  @override
  String get appTitle => 'Advocat — AI õigusabi';

  @override
  String get appVersion => 'Rakenduse versioon';

  @override
  String get appealFiled => 'Kaebus esitatud';

  @override
  String get areYouAbsolutelySure => 'Kas olete täiesti kindel?';

  @override
  String get askAboutCase => 'Küsige oma juhtumi kohta';

  @override
  String get asylum => 'Varjupaik';

  @override
  String get back => 'Tagasi';

  @override
  String get basic => 'Põhi';

  @override
  String get beforeYouBuy => 'Enne ostmist';

  @override
  String get beforeYouWork => 'Enne nendega koostööd';

  @override
  String get camera => 'Kaamera';

  @override
  String get cancel => 'Tühista';

  @override
  String get caseDescription => 'Juhtumi kirjeldus';

  @override
  String get caseDetail => 'Juhtumi üksikasjad';

  @override
  String get caseOverview => 'Juhtumite ülevaade';

  @override
  String get caseTitle => 'Juhtumi pealkiri';

  @override
  String get caseUpdated => 'Juhtum uuendatud';

  @override
  String get cases => 'Juhtumid';

  @override
  String get checkCompany => 'Kontrolli ettevõtet';

  @override
  String get checkDeadlines => 'Kontrolli tähtaegu';

  @override
  String get checkVehicle => 'Kontrolli sõidukit';

  @override
  String get checkerTitle => 'Kontrollija';

  @override
  String get checkingErrors => 'Vigade kontrollimine…';

  @override
  String get choosePlan => 'Vali pakett';

  @override
  String get closed => 'Suletud';

  @override
  String get companyName => 'Ettevõtte nimi või reg. nr.';

  @override
  String get completed => 'Lõpetatud';

  @override
  String get confirm => 'Kinnita';

  @override
  String get confirmPassword => 'Kinnitage parool';

  @override
  String get connectEmail => 'Ühenda e-post';

  @override
  String get connectGmail => 'Ühenda Gmail';

  @override
  String get connectOutlook => 'Ühenda Outlook';

  @override
  String get connected => 'Ühendatud';

  @override
  String get contactSupport => 'Võtke ühendust kasutajatoega';

  @override
  String get continueWithGoogle => 'Jätka Google\'iga';

  @override
  String get copyText => 'Kopeeri tekst';

  @override
  String get correspondence => 'Kirjavahetus';

  @override
  String get couldNotLoadCases => 'Juhtumite laadimine ebaõnnestus';

  @override
  String get country => 'Riik';

  @override
  String get createAccount => 'Loo konto';

  @override
  String get createCase => 'Loo juhtum';

  @override
  String get criminalCase => 'Kriminaalasi';

  @override
  String get critical => 'Kriitiline';

  @override
  String get currentPlan => 'Praegune pakett';

  @override
  String get dataAndPrivacy => 'ANDMED JA PRIVAATSUS';

  @override
  String get dataExportRequested =>
      'Andmete eksport taotletud. Kontrollige oma e-posti.';

  @override
  String daysRemaining(int count) {
    return '$count päeva';
  }

  @override
  String get deadlineReminders => 'Tähtaja meeldetuletused';

  @override
  String get deadlineRemindersDesc => 'Saate teavituse enne tähtaja möödumist';

  @override
  String get deadlines => 'Tähtajad';

  @override
  String get debtCollection => 'Võlgade sissenõudmine';

  @override
  String get deleteAccount => 'Kustuta konto';

  @override
  String get deleteAccountDesc => 'Kustutage konto ja kõik andmed jäädavalt';

  @override
  String get deleteAccountDialogContent =>
      'See toiming on pöördumatu. Kõik teie andmed, juhtumid ja dokumendid kustutatakse jäädavalt.';

  @override
  String get deleteConfirm =>
      'Kas olete kindel, et soovite konto kustutada? Seda toimingut ei saa tagasi võtta.';

  @override
  String get demoHint => 'Demo: proovige numbrimärki „908FBT“';

  @override
  String get demoModeDesc => 'Tutvuge rakendusega ilma kontot loomata';

  @override
  String get deportation => 'Väljasaatmine';

  @override
  String get disclaimer =>
      'AI suunised — mitte õigusnõuanne. Pidage olulistel teemadel nõu juristiga.';

  @override
  String get disclaimerFull =>
      'See dokument on koostatud AI abil ja on mõeldud üksnes mustandiks. See ei ole õigusnõuanne. Enne kaebuse esitamist soovitame pidada nõu kvalifitseeritud juristiga.';

  @override
  String get disconnect => 'Katkesta ühendus';

  @override
  String get discrimination => 'Diskrimineerimine';

  @override
  String get doNotBuy => 'Ära osta';

  @override
  String get documents => 'Dokumendid';

  @override
  String documentsCount(int count) {
    return '$count dokumenti';
  }

  @override
  String get draftAppeal => 'Koosta kaebus';

  @override
  String get editDraft => 'Muuda mustandit';

  @override
  String get editProfile => 'Muuda profiili';

  @override
  String get email => 'E-post';

  @override
  String get emailConnected => 'E-post ühendatud';

  @override
  String get emailDisconnected => 'E-post lahti ühendatud';

  @override
  String get emailIntegration => 'E-POSTI INTEGRATSIOON';

  @override
  String get emailInvalid => 'Sisestage kehtiv e-posti aadress';

  @override
  String get emailPrivacyNote =>
      'Loeme ainult juhtumitega seotud kirju. Teie privaatsus on kaitstud.';

  @override
  String get emailRequired => 'E-posti aadress on kohustuslik';

  @override
  String get emergencyShield => 'Põhikaitse';

  @override
  String get error => 'Viga';

  @override
  String get exportDataDesc => 'Laadige kõik oma andmed alla JSON-vormingus';

  @override
  String get exportDataDialogContent =>
      'Valmistame ette kõigi teie andmete allalaadimise — juhtumid, dokumendid ja kirjavahetus. Saadame teile e-kirja, kui kõik on valmis.';

  @override
  String get exportMyData => 'Ekspordi minu andmed';

  @override
  String get exportPdf => 'Ekspordi PDF-ina';

  @override
  String get familyReunification => 'Perekonna taasühendamine';

  @override
  String get forgotPassword => 'Unustasid parooli?';

  @override
  String get free => 'Tasuta';

  @override
  String get fullDefense => 'Advocat Pro';

  @override
  String get fullName => 'Täisnimi';

  @override
  String get gallery => 'Galerii';

  @override
  String get generateAppeal => 'Genereeri kaebus';

  @override
  String get getStarted => 'Alusta';

  @override
  String goodAfternoon(String name) {
    return 'Tere päevast, $name';
  }

  @override
  String goodEvening(String name) {
    return 'Tere õhtust, $name';
  }

  @override
  String goodMorning(String name) {
    return 'Tere hommikust, $name';
  }

  @override
  String goodNight(String name) {
    return 'Head ööd, $name';
  }

  @override
  String get home => 'Avaleht';

  @override
  String get important => 'Oluline';

  @override
  String get inProgress => 'Menetluses';

  @override
  String get informational => 'Informatiivne';

  @override
  String get inspection => 'Tehniline ülevaatus';

  @override
  String get insurance => 'Kindlustus';

  @override
  String issuesFound(int count) {
    return '$count probleemi leitud';
  }

  @override
  String get laborDispute => 'Töövaidlus';

  @override
  String get langEnglish => 'Inglise keel';

  @override
  String get langFinnish => 'Soome keel';

  @override
  String get langRussian => 'Vene keel';

  @override
  String get language => 'Keel';

  @override
  String lastActivity(String time) {
    return 'Viimane tegevus: $time';
  }

  @override
  String get legalFighter => 'Õigusnõustaja';

  @override
  String get legalSection => 'ÕIGUSLIK';

  @override
  String get licensePlate => 'Numbrimärk';

  @override
  String get loading => 'Laadimine…';

  @override
  String get logIn => 'Logi sisse';

  @override
  String get loginFailed => 'Vale e-posti aadress või parool. Proovige uuesti.';

  @override
  String get lost => 'Kaotatud';

  @override
  String get markComplete => 'Märgi lõpetatuks';

  @override
  String get mileage => 'Läbisõit';

  @override
  String get myCases => 'Minu juhtumid';

  @override
  String get nameRequired => 'Täisnimi on kohustuslik';

  @override
  String get newCase => 'Uus juhtum';

  @override
  String get next => 'Järgmine';

  @override
  String get noAccount => 'Kas teil pole kontot? ';

  @override
  String get noCases => 'Juhtumeid pole veel';

  @override
  String get noCasesYet => 'Juhtumeid pole veel';

  @override
  String get noDeadlines => 'Tähtaegu pole';

  @override
  String get noRecentActivity => 'Viimast tegevust pole';

  @override
  String get notifications => 'TEAVITUSED';

  @override
  String get onboardingDesc1 =>
      'Advocat aitab teil oma õiguslikku olukorda paremini mõista. AI analüüsib dokumente, juhib tähelepanu võimalikele probleemidele ja koostab dokumendimustandeid teie ülevaatamiseks. Tegemist ei ole advokaadibürooga — see on tehnoloogiline tööriist, mis aitab teie juhtumi ette valmistada.';

  @override
  String get onboardingDesc2 =>
      'Pildistage iga õigusdokument. AI loeb seda mitmes keeles, võtab välja olulised andmed ning kontrollib EL-i direktiivide ja Eesti seaduste põhjal võimalikke vigu.';

  @override
  String get onboardingDesc3 =>
      'Meie AI vaatab läbi üle 40 menetlusnõude. Analüüs võib esile tuua tähelepanu vajavaid kohti — näiteks menetluse keel, menetlusetapid ja seadusjärgsed tähtajad. Olulistel juhtudel pidage alati nõu kvalifitseeritud juristiga.';

  @override
  String get onboardingDesc4 =>
      'AI koostab kaebuste, avalduste ja kirjade mustandid koos seaduseviidetega — teie ülevaatamiseks. Lõpliku otsuse esitamise üle teete teie. Iga dokument tasub enne esitamist lasta üle vaadata kvalifitseeritud juristil.';

  @override
  String get onboardingNext => 'Järgmine';

  @override
  String get onboardingSkip => 'Jäta vahele';

  @override
  String get onboardingTitle1 => 'AI-põhine õigusteave';

  @override
  String get onboardingTitle2 => 'Skaneerige ja analüüsige dokumente';

  @override
  String get onboardingTitle3 => 'AI tuvastab võimalikud vead';

  @override
  String get onboardingTitle4 => 'Dokumendimustandid teie ülevaatamiseks';

  @override
  String get openACase => 'Ava juhtum';

  @override
  String get optional => 'Valikuline';

  @override
  String get orDivider => 'või';

  @override
  String get other => 'Muu';

  @override
  String get overdue => 'Tähtaeg möödas';

  @override
  String get owners => 'Varasemad omanikud';

  @override
  String get password => 'Parool';

  @override
  String get passwordRequired => 'Parool on kohustuslik';

  @override
  String get passwordStrengthMedium => 'Keskmine';

  @override
  String get passwordStrengthStrong => 'Tugev';

  @override
  String get passwordStrengthWeak => 'Nõrk';

  @override
  String get passwordTooShort => 'Parool peab olema vähemalt 8 tähemärki';

  @override
  String get passwordsDoNotMatch => 'Paroolid ei kattu';

  @override
  String get pendingDecision => 'Otsust oodatakse';

  @override
  String get perCheck => 'kontrolli kohta';

  @override
  String get permanentlyDelete => 'Kustuta jäädavalt';

  @override
  String get policeMisconduct => 'Politsei tegevus';

  @override
  String get popular => 'Populaarne';

  @override
  String get preferences => 'EELISTUSED';

  @override
  String get preferredLanguage => 'Keel';

  @override
  String get pricePerCheck => '4,99 € kontrolli kohta';

  @override
  String get privacyPolicy => 'Privaatsuspoliitika';

  @override
  String get pro => 'Pro';

  @override
  String get pushNotifications => 'Tõuketeavitused';

  @override
  String get rateUs => 'Hinda rakendust';

  @override
  String get rateAppComingSoon => 'Tuleb peagi rakenduste poodidesse!';

  @override
  String get dataCopiedToClipboard => 'Andmed kopeeritud lõikelauale';

  @override
  String get readingDocument => 'Dokumendi lugemine…';

  @override
  String get recentActivity => 'Viimane tegevus';

  @override
  String get referenceNumber => 'Viitenumber';

  @override
  String get registerFailed => 'Registreerimine ebaõnnestus. Proovige uuesti.';

  @override
  String get reportFraud => 'Teata pettusest';

  @override
  String get requestExport => 'Taotle eksporti';

  @override
  String get researchingLaw => 'Kohaldatava õiguse uurimine…';

  @override
  String get resetPasswordFailed =>
      'Lingi saatmine ebaõnnestus. Proovige uuesti.';

  @override
  String get resetPasswordSent =>
      'Parooli lähtestamise link saadetud teie e-postile.';

  @override
  String get residencePermit => 'Elamisluba';

  @override
  String get manageSubscription => 'Halda tellimust';

  @override
  String get restorePurchases => 'Taasta ostud';

  @override
  String get retry => 'Proovi uuesti';

  @override
  String get reviewWarning => 'Vaadake enne saatmist üle';

  @override
  String get riskHigh => 'Kõrge risk — väldi';

  @override
  String get riskLow => 'Turvaline koostööks';

  @override
  String get riskMedium => 'Jätka ettevaatlikult';

  @override
  String get safeToBuy => 'Turvaline osta';

  @override
  String get saveAndAnalyze => 'Salvesta ja analüüsi';

  @override
  String get saveDraft => 'Salvesta mustand';

  @override
  String get saveWithAnnual => 'Säästa aastatellimusega';

  @override
  String get scan => 'Skaneeri';

  @override
  String get scanDocument => 'Skaneeri dokument';

  @override
  String get searchCases => 'Otsi juhtumeid';

  @override
  String get selectCountry => 'Vali riik';

  @override
  String get selectLanguage => 'Valige keel';

  @override
  String get sendViaEmail => 'Saada e-postiga';

  @override
  String get settings => 'Seaded';

  @override
  String get signIn => 'Logi sisse';

  @override
  String get signInLink => 'Logige sisse';

  @override
  String get signInSubtitle => 'Logige sisse, et pääseda oma juhtumite juurde';

  @override
  String get signOut => 'Logi välja';

  @override
  String get signOutConfirm => 'Kas olete kindel, et soovite välja logida?';

  @override
  String get signUp => 'Loo konto';

  @override
  String get signUpLink => 'Registreeruge';

  @override
  String get socialBenefits => 'Sotsiaaltoetused';

  @override
  String get someConcerns => 'Mõned mured';

  @override
  String get startFirstCase => 'Looge oma esimene juhtum';

  @override
  String step(int current, int total) {
    return 'Samm $current/$total';
  }

  @override
  String get stolen => 'Varguse kontroll';

  @override
  String get subscription => 'Tellimus';

  @override
  String get syncLegalCorrespondence => 'Sünkrooni juriidiline kirjavahetus';

  @override
  String get syncNow => 'Sünkrooni kohe';

  @override
  String get tenantRights => 'Üürniku õigused';

  @override
  String get termsOfService => 'Kasutustingimused';

  @override
  String get termsRequired => 'Te peate nõustuma kasutustingimustega';

  @override
  String get timeline => 'Ajajoon';

  @override
  String get tryDemoMode => 'Proovi demorežiimi';

  @override
  String get typeDeleteToConfirm =>
      'Sisestage DELETE konto püsiva kustutamise kinnitamiseks.';

  @override
  String get typeMessage => 'Sisestage sõnum…';

  @override
  String get upcoming => 'Tulemas';

  @override
  String get uploadDocument => 'Laadi dokument üles';

  @override
  String urgentDeadline(String title) {
    return 'Kiireloomuline: $title';
  }

  @override
  String get useInAppeal => 'Kasuta kaebuses';

  @override
  String get vehicleChecker => 'Sõiduki kontrollija';

  @override
  String get vehicleChecks => 'Seisundi kontrollid';

  @override
  String get vehicleColor => 'Värv';

  @override
  String get vehicleMake => 'Mark';

  @override
  String get vehicleModel => 'Mudel';

  @override
  String get vehicleYear => 'Aasta';

  @override
  String get version => 'Versioon';

  @override
  String get victimSupport => 'Ohvriabi';

  @override
  String get viewAll => 'Vaata kõiki';

  @override
  String get vinNumber => 'VIN-kood';

  @override
  String get welcomeBack => 'Tere tulemast tagasi';

  @override
  String get whatAreMyOptions => 'Millised on minu valikud?';

  @override
  String get won => 'Võidetud';

  @override
  String get documentVault => 'Dokumendihoidla';

  @override
  String get secureDocumentStorage => 'Turvaline dokumendihoidla';

  @override
  String get secureDocumentStorageDesc =>
      'Hoidke oma olulised õigusdokumendid ühes kohas lihtsaks juurdepääsuks.';

  @override
  String get addDocument => 'Lisa dokument';

  @override
  String get chooseHowToAdd => 'Valige, kuidas dokumenti lisada';

  @override
  String get uploadFile => 'Laadi fail üles';

  @override
  String get uploadFileDesc => 'Valige oma seadmest PDF või pilt';

  @override
  String get scanDocumentDesc => 'Tehke oma dokumendist foto';

  @override
  String get createNote => 'Loo märkus';

  @override
  String get createNoteDesc =>
      'Kirjutage märkus või salvestage olulised üksikasjad';

  @override
  String get knowYourRights => 'Tunne oma õigusi';

  @override
  String get stoppedByPolice => 'Politsei poolt peatatud';

  @override
  String get stoppedByPoliceDesc => 'Teie õigused politseikokkupuutel';

  @override
  String get deportationNotice => 'Väljasaatmisteade';

  @override
  String get deportationNoticeDesc =>
      'Sammud väljasaatmiskorralduse vaidlustamiseks';

  @override
  String get workplaceRights => 'Töökoha õigused';

  @override
  String get workplaceRightsDesc => 'Tööõiguskaitse Eestis';

  @override
  String get tenantRightsDesc => 'Eluaseme- ja üürikaitse';

  @override
  String get immigrationDetention => 'Immigratsioonikinnipidamine';

  @override
  String get immigrationDetentionDesc =>
      'Õigused, kui olete ametiasutuste poolt kinni peetud';

  @override
  String get discriminationDesc =>
      'Kuidas teatada diskrimineerimisest ja selle vastu võidelda';

  @override
  String get scenarioNotFound => 'Stsenaariumit ei leitud';

  @override
  String get youHaveRightTo => 'Teil on õigus:';

  @override
  String get youMust => 'Peate:';

  @override
  String get immediateSteps => 'Viivitamatud sammud:';

  @override
  String get yourRights => 'Teie õigused:';

  @override
  String get basicRights => 'Põhiõigused:';

  @override
  String get yourRightsAsTenant => 'Teie õigused üürnikuna:';

  @override
  String get yourRightsInDetention => 'Teie õigused kinnipidamisel:';

  @override
  String get howToAct => 'Kuidas käituda:';

  @override
  String get rightKnowWhyStopped => 'Teadke, miks teid peatati';

  @override
  String get rightRemainSilent => 'Vaikige (peate end identifitseerima)';

  @override
  String get rightAskInterpreter => 'Paluge endale tõlki';

  @override
  String get rightContactLawyer =>
      'Võtke enne ülekuulamist advokaadiga ühendust';

  @override
  String get rightRecordEncounter => 'Salvestage suhtlust (avalikes kohtades)';

  @override
  String get mustProvideName => 'Öelge oma nimi ja sünniaeg';

  @override
  String get mustShowId => 'Näidake isikut tõendavat dokumenti, kui teil on';

  @override
  String get mustNotResist => 'Mitte füüsiliselt vastu hakata';

  @override
  String get doNotIgnoreNotice =>
      'ÄRGE ignoreerige teadet — tähtajad on ranged';

  @override
  String get noteAppealDeadline =>
      'Märkige kaebuse tähtaeg (tavaliselt 30 päeva)';

  @override
  String get contactLawyerImmediately => 'Võtke kohe advokaadiga ühendust';

  @override
  String get applyLegalAid => 'Taotlege vajadusel õigusabi';

  @override
  String get rightAppealAdmin => 'Õigus esitada kaebus halduskohtusse';

  @override
  String get rightLegalRep => 'Õigus õigusabi esindajale';

  @override
  String get rightInterpreter => 'Õigus tõlgile';

  @override
  String get rightStayDuringAppeal =>
      'Õigus jääda riiki kaebuse menetluse ajaks (enamikul juhtudel)';

  @override
  String get minimumWage => 'Miinimumpalk vastavalt kollektiivlepingule';

  @override
  String get workingTimeLimits =>
      'Tööaja piirangud (kuni 8 t/päev, 40 t/nädal)';

  @override
  String get annualLeave => 'Põhipuhkus (vähemalt 2 päeva töötatud kuu kohta)';

  @override
  String get sickLeave => 'Haigushüvitis';

  @override
  String get safeWorkingConditions => 'Ohutud töötingimused';

  @override
  String get writtenRentalAgreement => 'Kirjalik üürileping nõutav';

  @override
  String get securityDeposit => 'Tagatisraha max 3 kuu üür';

  @override
  String get landlordNotice => 'Üürileandja peab andma teate (3–6 kuud)';

  @override
  String get rightHabitableDwelling => 'Õigus elamiskõlblikule eluasemele';

  @override
  String get protectionUnjustEviction => 'Kaitse ebaõiglase väljatõstmise eest';

  @override
  String get rightKnowDetentionReason => 'Õigus teada kinnipidamise põhjust';

  @override
  String get rightContactLawyerDetention => 'Õigus võtta ühendust advokaadiga';

  @override
  String get rightContactEmbassy => 'Õigus võtta ühendust oma saatkonnaga';

  @override
  String get rightChallengeDetention =>
      'Õigus vaidlustada kinnipidamine kohtus';

  @override
  String get rightHumaneTreatment =>
      'Õigus inimlikule kohtlemisele ja arstiabile';

  @override
  String get documentIncident =>
      'Dokumenteerige juhtum (kuupäev, kellaaeg, tunnistajad)';

  @override
  String get fileComplaintOmbudsman => 'Esitage kaebus võrdõigusvolinikule';

  @override
  String get contactLegalAidOffice => 'Võtke ühendust õigusabibürooga';

  @override
  String get reportToPolice =>
      'Esitage politseile avaldus, kui tegu on kuriteoga (ähvardus, kallaletung)';

  @override
  String get legalAidCalculator => 'Õigusabi kalkulaator';

  @override
  String checkEligibility(String country) {
    return 'Kontrollige oma sobivust õigusabile: $country';
  }

  @override
  String get estimateDisclaimer =>
      'See on ainult hinnang. Tegeliku sobivuse määrab õigusabibüroo.';

  @override
  String get monthlyIncome => 'Kuusissetulek (EUR)';

  @override
  String get totalAssets => 'Vara kokku (EUR)';

  @override
  String get numberOfDependents => 'Ülalpeetavate arv';

  @override
  String get calculateEligibility => 'Arvuta sobivus';

  @override
  String get likelyEligible => 'Tõenäoliselt sobiv';

  @override
  String get mayNotQualify => 'Ei pruugi kvalifitseeruda';

  @override
  String get fullFreeLegalAid =>
      'Tõenäoliselt kvalifitseerute tasuta õigusabile (ilma omaosaluseta).';

  @override
  String legalAidWithCopay(String percent) {
    return 'Võite kvalifitseeruda õigusabile omaosalusega $percent%.';
  }

  @override
  String get mayNotQualifyDesc =>
      'Selle hinnangu põhjal ei pruugi te kvalifitseeruda riiklikule õigusabile. Kaaluge eraadvokaati või õiguskliinikut.';

  @override
  String get couldNotLoadDeadlines => 'Tähtaegu ei saanud laadida';

  @override
  String get noUpcomingDeadlines => 'Eelseisvaid tähtaegu pole';

  @override
  String get allClearDeadlines =>
      'Kõik korras! Uued tähtajad ilmuvad siia, kui need määratakse.';

  @override
  String get nothingOverdue => 'Midagi pole tähtaja ületanud';

  @override
  String get greatJobDeadlines =>
      'Hästi tehtud, hoiate oma tähtajad kontrolli all.';

  @override
  String get noCompletedDeadlines => 'Täidetud tähtaegu pole';

  @override
  String get completedDeadlinesDesc => 'Täidetud tähtajad kuvatakse siin.';

  @override
  String get daysLate => 'päeva hilinenud';

  @override
  String get days => 'päeva';

  @override
  String get fromDocument => 'Dokumendist';

  @override
  String get couldNotLoadCase => 'Juhtumi üksikasju ei saanud laadida';

  @override
  String get typeLabel => 'Tüüp';

  @override
  String get nationality => 'Rahvus';

  @override
  String get migriReference => 'Migri viide';

  @override
  String get courtCaseNo => 'Kohtuasja nr';

  @override
  String get created => 'Loodud';

  @override
  String get citizenship => 'Kodakondsus';

  @override
  String get workPermit => 'Tööluba';

  @override
  String get noDocumentsYet => 'Dokumente pole veel üles laetud';

  @override
  String get noUpcomingDeadlinesShort => 'Eelseisvaid tähtaegu pole';

  @override
  String get caseCreated => 'Juhtum loodud';

  @override
  String get decisionReceived => 'Otsus saadud';

  @override
  String get appealDeadline => 'Kaebuse tähtaeg';

  @override
  String get hearingScheduled => 'Istung kavandatud';

  @override
  String get late => 'hilinenud';

  @override
  String get pending => 'Ootel';

  @override
  String get processing => 'Töötlemine';

  @override
  String get ready => 'Valmis';

  @override
  String get failed => 'Ebaõnnestunud';

  @override
  String get analyzed => 'Analüüsitud';

  @override
  String get noDocumentsScanHint =>
      'Dokumente pole veel. Skaneerige või laadige üles.';

  @override
  String get inCourt => 'Kohtus';

  @override
  String get appeal => 'Kaebus';

  @override
  String get caseTimeline => 'Juhtumi ajajoon';

  @override
  String get couldNotLoadTimeline => 'Ajajoont ei saanud laadida';

  @override
  String get noEventsYet => 'Sündmusi pole veel';

  @override
  String get activityWillAppear =>
      'Tegevused ilmuvad siia, kui teie juhtum edeneb.';

  @override
  String caseCreatedDesc(String title) {
    return 'Juhtum „$title“ on loodud.';
  }

  @override
  String get decisionReceivedDesc => 'Selle juhtumi kohta saadi ametlik otsus.';

  @override
  String get appealDeadlineSet => 'Kaebuse tähtaeg määratud';

  @override
  String appealDeadlineDesc(String date) {
    return 'Kaebus tuleb esitada hiljemalt $date.';
  }

  @override
  String hearingScheduledDesc(String date) {
    return 'Kohtuistung kavandatud kuupäevale $date.';
  }

  @override
  String get caseInfoUpdated => 'Juhtumi teave viimati uuendatud.';

  @override
  String get documentAnalysis => 'Dokumendianalüüs';

  @override
  String get exportAsPdf => 'Ekspordi PDF-ina';

  @override
  String get pdfExportComingSoon => 'PDF eksport peagi';

  @override
  String get analysisFailedRetry =>
      'Analüüs ebaõnnestus. Palun proovige uuesti.';

  @override
  String get somethingWentWrong => 'Midagi läks valesti';

  @override
  String get retryAnalysis => 'Proovi analüüsi uuesti';

  @override
  String issuesFoundInDocument(int count) {
    return 'Leiti $count probleem(i) teie dokumendist';
  }

  @override
  String get severityOverview => 'Tõsiduse ülevaade';

  @override
  String get issuesFoundHeader => 'Leitud probleemid';

  @override
  String generateAppealWithIssues(int count) {
    return 'Loo kaebus ($count probleemi)';
  }

  @override
  String get analyzingContent => 'Sisu analüüsimine…';

  @override
  String get documentProcessedOk => 'Dokument edukalt töödeldud';

  @override
  String get noSignificantIssues =>
      'Selles dokumendis ei tuvastatud olulisi probleeme.';

  @override
  String get cameraPermissionRequired => 'Kaamera luba on vajalik';

  @override
  String get cameraPermissionDesc =>
      'Andke kaamerale juurdepääs dokumentide skannimiseks või kasutage galeriid.';

  @override
  String get openSettings => 'Ava seaded';

  @override
  String get alignDocument => 'Joondage dokument raami sees';

  @override
  String pageCount(int count) {
    return '$count lehekülg(e)';
  }

  @override
  String get preview => 'Eelvaade';

  @override
  String pageNumber(int number) {
    return 'Lehekülg $number';
  }

  @override
  String get done => 'Valmis';

  @override
  String get retake => 'Tee uuesti';

  @override
  String get useThisPhoto => 'Kasuta seda fotot';

  @override
  String get addPage => 'Lisa lehekülg';

  @override
  String uploadingPercent(int percent) {
    return 'Üleslaadimine… $percent%';
  }

  @override
  String get preparingUpload => 'Üleslaadimise ettevalmistamine…';

  @override
  String get documentUploadedSuccess => 'Dokument edukalt üles laetud';

  @override
  String pagesUploadedSuccess(int count) {
    return '$count lehekülge edukalt üles laetud';
  }

  @override
  String get uploadFailed =>
      'Üleslaadimine ebaõnnestus. Kontrollige ühendust ja proovige uuesti.';

  @override
  String get capturePhotoFailed =>
      'Foto tegemine ebaõnnestus. Palun proovige uuesti.';

  @override
  String get readingText => 'Teksti lugemine…';

  @override
  String get draftDocument => 'Dokumendi mustand';

  @override
  String get saveChanges => 'Salvesta muudatused';

  @override
  String get editDocument => 'Muuda dokumenti';

  @override
  String get generatingDraft => 'Teie mustandi loomine…';

  @override
  String get generatingDraftDesc =>
      'AI valmistab ette õigusdokumendi teie juhtumi üksikasjade ja valitud probleemide põhjal.';

  @override
  String get failedToGenerateDraft =>
      'Mustandi loomine ebaõnnestus. Palun proovige uuesti.';

  @override
  String get changesSaved => 'Muudatused salvestatud';

  @override
  String get copiedToClipboard => 'Kopeeritud lõikelauale';

  @override
  String get emailComingSoon => 'E-kirjade saatmine peagi';

  @override
  String get reviewBeforeSending =>
      'Vaadake enne saatmist hoolikalt üle. Vastutate dokumendi sisu eest teie ise.';

  @override
  String get noContentAvailable => 'Sisu pole saadaval';

  @override
  String get save => 'Salvesta';

  @override
  String get edit => 'Muuda';

  @override
  String get pdf => 'PDF';

  @override
  String get copy => 'Kopeeri';

  @override
  String get appealDraft => 'Kaebuse mustand';

  @override
  String selected(int count) {
    return '$count valitud';
  }

  @override
  String get deleteSelected => 'Kustuta valitud';

  @override
  String deleteDocumentsConfirm(int count) {
    return 'Kustutada $count dokumenti?';
  }

  @override
  String get delete => 'Kustuta';

  @override
  String get analyzeSelected => 'Analüüsi valitud';

  @override
  String get batchAnalysisStarting => 'Pakettanalüüs algab…';

  @override
  String get switchToList => 'Lülitu loendivaatele';

  @override
  String get switchToGrid => 'Lülitu ruudustikuvaatele';

  @override
  String get scanNew => 'Uus skannimine';

  @override
  String get noDocumentsYetScan => 'Dokumente pole veel';

  @override
  String get scanFirstDocumentHint =>
      'Skaneerige oma esimene dokument, et AI saaks selle vigade suhtes üle vaadata ja kaebuse mustandi koostada.';

  @override
  String get failedToLoadDocuments => 'Dokumentide laadimine ebaõnnestus';

  @override
  String get emailIntegrationTitle => 'E-posti integratsioon';

  @override
  String get connectYourEmail => 'Ühendage oma e-post';

  @override
  String get connectYourEmailDesc =>
      'Ühendage oma e-post, et tuvastada ja korraldada juhtumitega seotud juriidiline kirjavahetus automaatselt.';

  @override
  String get legalEmails => 'Juriidilised e-kirjad';

  @override
  String get unlinkedEmails => 'Seostamata e-kirjad';

  @override
  String get noLegalEmailsYet => 'Juriidilisi e-kirju pole veel';

  @override
  String get legalEmailsWillAppear =>
      'Juriidiliseks liigitatud e-kirjad kuvatakse siin.';

  @override
  String get assignToCase => 'Määra juhtumile';

  @override
  String get disconnectEmail => 'Katkesta e-posti ühendus';

  @override
  String get disconnectEmailConfirm =>
      'Automaatne e-posti sünkroonimine lõpetatakse. Varem sünkroonitud e-kirjad jäävad teie juhtumitesse.';

  @override
  String connectedTo(String email) {
    return 'Ühendatud: $email';
  }

  @override
  String lastSynced(String time) {
    return 'Viimati sünkroonitud: $time';
  }

  @override
  String get filterByType => 'Filtreeri tüübi järgi';

  @override
  String get noCasesMatchSearch => 'Ükski juhtum ei vasta otsingule';

  @override
  String get failedToLoadCases => 'Juhtumite laadimine ebaõnnestus';

  @override
  String get monthly => 'Kuine';

  @override
  String get annual => 'Aastane';

  @override
  String get saveTwentyFivePercent => 'Säästa 25%';

  @override
  String get mostPopular => 'POPULAARSEIM';

  @override
  String get oneCaseActive => '1 juhtum';

  @override
  String get threeCasesActive => '3 juhtumit';

  @override
  String get unlimitedCases => 'Piiramatult juhtumeid';

  @override
  String get threeDocScans => '3 dokumendi skannimist (kokku)';

  @override
  String get twentyDocScans => '20 dokumendiskannimist kuus';

  @override
  String get unlimitedDocScans => 'Piiramatu dokumendiskannimine';

  @override
  String get basicAiAnalysis => 'AI põhianalüüs';

  @override
  String get fullAiAnalysis => 'Täielik AI analüüs';

  @override
  String get draftGeneration => 'Mustandite loomine';

  @override
  String get priorityProcessing => 'Prioriteetne töötlemine';

  @override
  String get fiveAiMessagesTotal =>
      '5 AI sõnumit (kokku, kogu kasutusaja jooksul)';

  @override
  String get hundredAiMessagesDay => '100 AI sõnumit päevas';

  @override
  String get unlimitedAiMessages => 'Piiramatu AI sõnumid';

  @override
  String get voiceInput => 'Häälsisend';

  @override
  String get strategyRecommendations => 'Strateegilised soovitused';

  @override
  String get foundingMemberNote => 'Asutajaliige: 9,99 € kuus esimesed 3 kuud';

  @override
  String get saveTwentyPercent => 'Säästa 20%';

  @override
  String get forever => 'igavesti';

  @override
  String get perMonth => '/kuus';

  @override
  String get perYear => '/aastas';

  @override
  String get checkingPurchases => 'Varasemate ostude kontrollimine…';

  @override
  String get noPreviousPurchases => 'Varasemaid oste ei leitud.';

  @override
  String get chatWelcomeMessage =>
      'Tere! Ma olen Advocat — sinu AI-õigusassistent. Annan õigusinformatsiooni, mitte õigusabi. Mille üle sind õiguslikult vaevab?';

  @override
  String get copySummary => 'Kopeeri kokkuvõte';

  @override
  String get caseSummaryCopied => 'Juhtumi kokkuvõte kopeeritud';

  @override
  String get openCase => 'Ava juhtum';

  @override
  String get viewFull => 'Vaata tervikuna';

  @override
  String get draftCopiedToClipboard => 'Mustand kopeeritud lõikelauale';

  @override
  String get reportMileageFraud => 'Teata läbisõidu pettusest';

  @override
  String get reportMileageFraudDesc =>
      'Koostame pettuseraporti sõiduki kontrolli andmete põhjal. Soovi korral saate avada ka juhtumi.';

  @override
  String get reportAndOpenCase => 'Teata ja ava juhtum';

  @override
  String get caseCreationComingSoon =>
      'Eeltäidetud andmetega juhtumi loomine peagi';

  @override
  String get failedToCreateCaseRetry =>
      'Juhtumi loomine ebaõnnestus. Palun proovige uuesti.';

  @override
  String get takePhotoInstead => 'Tehke foto';

  @override
  String get deleteCase => 'Kustuta juhtum';

  @override
  String deleteCaseConfirm(String title) {
    return 'Kas olete kindel, et soovite kustutada „$title“? Seda toimingut ei saa tagasi võtta.';
  }

  @override
  String get haveQuestionsAi => 'Küsimusi? Küsige AI-lt';

  @override
  String get cookiePolicy => 'Küpsiste poliitika';

  @override
  String get aiDisclaimer => 'AI vastutuse välistamine';

  @override
  String get dataPrivacyConsent => 'Andmekaitsenõusolek';

  @override
  String get gdprIntro =>
      'AI õigusabi pakkumiseks töötleme teie andmeid vastavalt GDPR-ile (EL 2016/679). Jätkates nõustute:';

  @override
  String get gdprChat => 'Teie vestlussõnumite töötlemine AI poolt';

  @override
  String get gdprDocs => 'Üleslaaditud dokumentide analüüs';

  @override
  String get gdprStorage => 'Juhtumite andmete krüpteeritud salvestamine';

  @override
  String get gdprDelete => 'Õigus kustutada oma andmed igal ajal';

  @override
  String get gdprFooter =>
      'Teie andmed on krüpteeritud ega jagata kunagi kolmandatele osapooltele. Saate nõusoleku tagasi võtta ja kõik andmed kustutada Seadetest.';

  @override
  String get gdprConsentAiProcessing =>
      'Nõustun oma andmete töötlemisega AI õigusabi jaoks (kohustuslik)';

  @override
  String get gdprConsentAnalytics =>
      'Nõustun analüütikaga teenuse parandamiseks (valikuline)';

  @override
  String get gdprArt9Intro =>
      'See rakendus töötleb GDPR artikli 9 alusel erilist liiki isikuandmeid, sealhulgas:';

  @override
  String get gdprSpecialLegalCases =>
      'Teie kohtuasja üksikasjad ja kohtudokumendid';

  @override
  String get gdprSpecialNationality => 'Kodakondsus ja immigratsiooniseisund';

  @override
  String get gdprConsentLegalData =>
      'Nõustun oma kohtuasja andmete, kodakondsuse ja immigratsiooniseisundi töötlemisega AI poolt (kohustuslik)';

  @override
  String get gdprConsentVoice =>
      'Nõustun häälsalvestuse töötlemisega (valikuline)';

  @override
  String get gdprViewPrivacyPolicy => 'Vaata privaatsuspoliitikat';

  @override
  String get legalInformation => 'Õiguslik teave';

  @override
  String get legalEntityName => 'Vorantis OÜ';

  @override
  String get legalRegistryCode => 'Registrikood: 17098992';

  @override
  String get legalAddress =>
      'Harju maakond, Tallinn, Kesklinna linnaosa, Tornimäe tn 5, 10145';

  @override
  String get legalEmail => 'E-post: support@advocat.ee';

  @override
  String get legalRegistry => 'Registreeritud Eesti äriregistris';

  @override
  String get aiGeneratedDisclaimer => 'AI loodud • Mitte õigusnõuanne';

  @override
  String get decline => 'Keeldu';

  @override
  String get iAgree => 'Nõustun';

  @override
  String get iAgreeToThe => 'Nõustun ';

  @override
  String get orWord => 'või';

  @override
  String get english => 'Inglise keel';

  @override
  String get russian => 'Vene keel';

  @override
  String get finnish => 'Soome keel';

  @override
  String successSubscribed(String plan) {
    return 'Tellimus $plan edukalt aktiveeritud!';
  }

  @override
  String paymentFailed(String error) {
    return 'Makse ebaõnnestus: $error';
  }

  @override
  String get whatToDo => 'Mida teha';

  @override
  String get getHelp => 'Abi saamine';

  @override
  String get share => 'Jaga';

  @override
  String get didYouKnow => 'Kas teadsite?';

  @override
  String get mustKnow => 'Peate teadma';

  @override
  String get goodToKnow => 'Kasulik teada';

  @override
  String get sentFromAdvocat => 'Saadetud Advocat rakendusest';

  @override
  String get policeActionStayCalm => 'Jääge rahulikuks ja hoidke käed nähtaval';

  @override
  String get policeActionAskWhy => 'Küsige ametnikult, miks teid peatati';

  @override
  String get policeActionProvideName => 'Öelge oma nimi ja sünniaeg';

  @override
  String get policeActionWantLawyer =>
      'Öelge selgelt: „Ma soovin advokaati enne küsimustele vastamist.“';

  @override
  String get policeActionAskInterpreter => 'Vajadusel paluge tõlki';

  @override
  String get policeActionNoteBadge =>
      'Märkige üles ametniku nimi ja teenistusnumber';

  @override
  String get policeFactMustTellReason =>
      'Eestis peab politsei ütlema teile peatamise põhjuse. Kui nad seda ei tee, võite küsida — ja nad on seaduslikult kohustatud selgitama.';

  @override
  String get policeFactCanRecord =>
      'Eestis võite avalikes kohtades politseikokkupuuteid salvestada. Seda kaitseb sõnavabadus.';

  @override
  String get contactFinnishLegalAid => 'Riigi õigusabi';

  @override
  String get contactNonDiscriminationOmbudsman => 'Võrdõigusvolinik';

  @override
  String get deportationDeadlineAppeal =>
      'Kaebus halduskohtule — tavaliselt 30 päeva alates otsuse kättesaamisest';

  @override
  String get deportationDeadlineLegalAid =>
      'Taotlege riigi õigusabi — tehke seda KOHE';

  @override
  String get deportationFactStayDuringAppeal =>
      'Eestis on teil enamasti õigus jääda riiki, kuni kaebus on menetluses. Aktiivse kaebuse ajal väljasaatmist üldjuhul ei viida läbi.';

  @override
  String get contactRefugeeAdviceCentre => 'Eesti Pagulasabi';

  @override
  String get contactAdminCourtHelsinki => 'Tallinna Halduskohus';

  @override
  String get workplaceActionKeepContract => 'Hoidke alles töölepingu koopiad';

  @override
  String get workplaceActionTrackHours =>
      'Pidage ise oma tööaja kohta arvestust';

  @override
  String get workplaceActionReportUnsafe =>
      'Teatage ohtlikest töötingimustest Tööinspektsioonile';

  @override
  String get workplaceActionJoinUnion => 'Liituge enda kaitseks ametiühinguga';

  @override
  String get workplaceActionContactAuthority =>
      'Vajadusel võtke ühendust Tööinspektsiooniga';

  @override
  String get workplaceFactCollectiveWage =>
      'Eestis kehtestab riikliku miinimumpalga Vabariigi Valitsus. Tööandja peab maksma vähemalt seaduses kehtestatud miinimumpalka.';

  @override
  String get workplaceFactOralContract =>
      'Eestis kehtivad töötaja õigused täies ulatuses ka ilma kirjaliku lepinguta. Suuline kokkulepe on seaduse järgi sama siduv.';

  @override
  String get contactOccupationalSafety => 'Tööinspektsioon';

  @override
  String get contactTradeUnionSAK => 'Eesti Ametiühingute Keskliit (EAKL)';

  @override
  String get tenantActionWrittenAgreement =>
      'Sõlmige alati kirjalik üürileping';

  @override
  String get tenantActionDocumentCondition =>
      'Dokumenteerige korteri seisund sissekolimisel (tehke fotod)';

  @override
  String get tenantActionReportMaintenance =>
      'Teavitage hooldusprobleemidest kirjalikult';

  @override
  String get tenantActionNoIllegalEviction =>
      'Ärge kunagi nõustuge seadusvastase väljatõstmisega — otsuse teeb kohus';

  @override
  String get tenantActionContactAdvisory =>
      'Vaidluste korral pöörduge üürnike nõustamisteenuse poole';

  @override
  String get tenantFactNoEvictionWithoutCourt =>
      'Eestis ei tohi üürileandja üürnikku välja tõsta ilma kohtumääruseta, isegi kui üürileping on lõppenud. Lukkude vahetamine või kommunaalteenuste katkestamine on seadusvastane.';

  @override
  String get contactTenantsAssociation => 'Eesti Üürnike Liit';

  @override
  String get contactConsumerDisputesBoard => 'Tarbijavaidluste komisjon';

  @override
  String get detentionActionAskDecision =>
      'Nõudke kohe kirjalikku kinnipidamisotsust';

  @override
  String get detentionActionRequestLawyer =>
      'Taotlege advokaadiga ühenduse võtmist';

  @override
  String get detentionActionContactEmbassy =>
      'Võtke ühendust oma saatkonna või konsulaadiga';

  @override
  String get detentionActionAskMedical => 'Vajadusel taotlege arstiabi';

  @override
  String get detentionActionRequestInterpreter =>
      'Nõudke tõlki kõigis menetlustes';

  @override
  String get detentionDeadlineCourtReview =>
      'Maakohus peab kinnipidamise läbi vaatama 4 päeva jooksul';

  @override
  String get detentionDeadlineContinuation =>
      'Kohus vaatab jätkamise läbi iga 2 nädala järel';

  @override
  String get detentionFactCourtReview =>
      'Sisserände kinnipidamine Eestis peab olema maakohtu poolt läbi vaadatud 4 päeva jooksul. Kui seda ei tehta, muutub kinnipidamine ebaseaduslikuks.';

  @override
  String get contactParliamentaryOmbudsman => 'Õiguskantsler';

  @override
  String get discriminationActionWriteDown =>
      'Kirjutage täpselt üles, mis juhtus (kuupäev, kellaaeg, koht)';

  @override
  String get discriminationActionSaveEvidence =>
      'Säilitage tõendid: sõnumid, e-kirjad, tunnistajad';

  @override
  String get discriminationActionFileComplaint =>
      'Esitage kaebus võrdõigusvolinikule';

  @override
  String get discriminationActionContactLegalAid =>
      'Võtke ühendust õigusabibürooga tasuta nõustamiseks';

  @override
  String get discriminationActionReportPolice =>
      'Teatage politseile, kui tegemist oli ähvarduse või rünnakuga';

  @override
  String get discriminationFactNonDiscriminationAct =>
      'Eesti võrdse kohtlemise seadus hõlmab diskrimineerimist vanuse, päritolu, kodakondsuse, keele, usu, tervise, puude, seksuaalse sättumuse ja muude isikuomaduste alusel.';

  @override
  String get contactVictimSupportRIKU => 'Ohvriabi (116 006)';

  @override
  String get domesticViolence => 'Koduvägivald';

  @override
  String get domesticViolenceDesc => 'Ohvri õigused, hädaabi, lähenemiskeeld';

  @override
  String get rightCallEmergency =>
      'Teil on õigus helistada 112 igal hädajuhul — politsei, kiirabi, tuletõrje';

  @override
  String get rightVictimProtection =>
      'Ohvrina on teil õigus kaitsele, toele ja teabele oma asja kohta';

  @override
  String get rightRestrainingOrder =>
      'Saate taotleda lähenemiskeeldu, et hoida vägivallatseja eemal';

  @override
  String get rightVictimInterpreter =>
      'Teil on õigus tõlgile kõigi õigusmenetluste ajal';

  @override
  String get rightMedicalHelp =>
      'Teil on õigus viivitamatule arstiabile ja vigastuste dokumenteerimisele';

  @override
  String get rightShelter =>
      'Teil on õigus varjupaigale — võtke ühendust varjupaiga või sotsiaalteenustega';

  @override
  String get mustReportDanger =>
      'Kui keegi on otseses ohus, helistage kohe 112';

  @override
  String get mustDocumentInjuries =>
      'Dokumenteerige kõik vigastused — fotod, arstitõendid, kirjalikud märkmed';

  @override
  String get domesticActionCallEmergency =>
      'Helistage 112, kui olete otseses ohus';

  @override
  String get domesticActionGoToSafe =>
      'Minge turvalisse kohta — naiste tugikeskus, sõbra juurde või rahvarohkesse kohta';

  @override
  String get domesticActionDocumentEverything =>
      'Dokumenteerige vigastused: tehke fotod, hankige arstitõendid';

  @override
  String get domesticActionFilePoliceReport =>
      'Esitage politseile avaldus — saate seda teha ka hiljem';

  @override
  String get domesticActionContactShelter =>
      'Võtke ühendust varjupaiga või kriisitelefoniga';

  @override
  String get domesticActionApplyRestraining =>
      'Taotlege lähenemiskeeldu politsei või kohtu kaudu';

  @override
  String get domesticFactRestrainingOrder =>
      'Eestis saab lähenemiskeeldu taotleda ka ilma kriminaalasjata. See keelab isikul teiega ühendust võtta või teile läheneda.';

  @override
  String get domesticFactVictimDirective =>
      'EL-i ohvrite direktiivi 2012/29/EL kohaselt on teil õigus lugupidavale kohtlemisele, teabe saamisele arusaadavas keeles ja ohvriabiteenustele — olenemata teie elamisloast.';

  @override
  String get domesticDeadlinePoliceReport =>
      'Politseile avalduse esitamine — kindlat tähtaega pole, kuid mida varem, seda parem tõendite jaoks';

  @override
  String get domesticDeadlineRestraining =>
      'Lähenemiskeeld — saab taotleda igal ajal';

  @override
  String get contactEmergency => 'Hädaabinumber';

  @override
  String get contactShelter => 'Naiste tugikeskus';

  @override
  String get contactCrisisHelpline => 'Ohvriabi telefon';

  @override
  String get contactNollaLinja => 'Ohvriabi kriisitelefon';

  @override
  String get inheritance => 'Pärimine';

  @override
  String get inheritanceDesc =>
      'Testamendid, pärandvara, pärijate õigused, sundosa, pärimismenetlus';

  @override
  String get rightInheritanceForced =>
      'Sundpärijatel (lapsed, abikaasa) on õigus sundosale olenemata testamendist';

  @override
  String get rightInheritanceWill =>
      'Teil on õigus teha testament oma vara kohta — notariaalne testament on kõige tugevam';

  @override
  String get rightInheritanceRenounce =>
      'Pärandist saab loobuda 3 kuu jooksul pärast sellest teadasaamist';

  @override
  String get rightInheritanceInfo =>
      'Teil on õigus saada teavet pärandvara kohta pankadest ja registritest';

  @override
  String get rightInheritanceDispute =>
      'Ebaõiglast testamenti saab kohtus vaidlustada aegumistähtaja jooksul';

  @override
  String get mustFileInheritance =>
      'Algatage pärimismenetlus notari juures mõistliku aja jooksul';

  @override
  String get mustNotifyHeirs =>
      'Kõiki teadaolevaid pärijaid tuleb pärimismenetlusest teavitada';

  @override
  String get inheritanceActionGatherDocs =>
      'Koguge dokumendid: surmatunnistus, testament, kinnisvaraandmed, pangaväljavõtted';

  @override
  String get inheritanceActionContactNotary =>
      'Võtke ühendust notariga pärimismenetluse alustamiseks';

  @override
  String get inheritanceActionCheckDebts =>
      'Kontrollige, kas pärandvaral on võlgu, enne pärandi vastuvõtmist';

  @override
  String get inheritanceActionFileCourt =>
      'Testamendi vaidlustamiseks esitage kohtule hagi';

  @override
  String get inheritanceDeadlineRenounce =>
      '3 kuud pärandist loobumiseks pärast sellest teadasaamist';

  @override
  String get inheritanceDeadlineDispute =>
      'Testamendi vaidlustamise aegumistähtaeg: sõltub alustest';

  @override
  String get inheritanceFactForced =>
      'Eestis on alanejatel sugulastel ja abikaasal õigus sundosale (1/2 seaduslikust osast) isegi testamendist väljajätmisel';

  @override
  String get inheritanceFactNotary =>
      'Kõik pärimismenetlused Eestis peavad käima läbi notari — seda sammu ei saa vahele jätta';

  @override
  String get consumerProtection => 'Tarbijakaitse';

  @override
  String get consumerProtectionDesc =>
      'Pettus, defektsed tooted, tagastused, petlikud müüjad';

  @override
  String get rightReturnOnline =>
      'Teil on 14 päeva veebiostu tühistamiseks ilma põhjuseta (EL-i taganemisõigus)';

  @override
  String get rightDefectiveProduct =>
      'Kui toode on defektne, on teil õigus parandusele, asendusele või tagasimaksele';

  @override
  String get rightClearPricing =>
      'Müüjad peavad kuvama selged hinnad koos kõigi tasudega — varjatud kulud on ebaseaduslikud';

  @override
  String get rightComplainBoard =>
      'Saate esitada tasuta kaebuse tarbijavaidluste komisjonile';

  @override
  String get rightProtectionFraud =>
      'Teid kaitseb seadus ebaausate kaubandustavade ja pettuse eest';

  @override
  String get mustKeepReceipts =>
      'Hoidke alles kõik kviitungid, lepingud ja suhtlus müüjatega';

  @override
  String get mustActTimely =>
      'Teatage defektidest müüjale mõistliku aja jooksul pärast avastamist';

  @override
  String get consumerActionKeepEvidence =>
      'Hoidke alles kviitungid, ekraanipildid, e-kirjad ja kõik ostutõendid';

  @override
  String get consumerActionContactSeller =>
      'Võtke esmalt ühendust müüjaga — selgitage probleemi kirjalikult';

  @override
  String get consumerActionFileComplaint =>
      'Esitage kaebus tarbijavaidluste komisjonile';

  @override
  String get consumerActionContactAuthority =>
      'Tasuta abi saamiseks pöörduge Tarbijakaitse ja Tehnilise Järelevalve Ameti poole';

  @override
  String get consumerActionReportFraud =>
      'Teatage pettusest politseile ja tarbijakaitseametile';

  @override
  String get consumerFactWithdrawal =>
      'EL-i tarbijaõiguste direktiivi 2011/83/EL kohaselt on teil õigus 14 päeva jooksul igast veebi- või kaugostust põhjust nimetamata taganeda. Müüja peab raha tagastama samuti 14 päeva jooksul.';

  @override
  String get consumerFactWarranty =>
      'Eestis vastutab müüja toote defektide eest mõistliku aja jooksul (sageli 2+ aastat). See on eraldiseisev mis tahes tootja garantiist.';

  @override
  String get consumerDeadlineWithdrawal =>
      'Veebiostu taganemistähtaeg — 14 päeva alates kättesaamisest';

  @override
  String get consumerDeadlineDefect =>
      'Defektist müüjale teatamine — 2 kuu jooksul pärast avastamist (soovitatav)';

  @override
  String get contactConsumerAdvisory =>
      'Tarbijakaitse ja Tehnilise Järelevalve Amet';

  @override
  String get contactConsumerOmbudsman => 'Tarbijaombudsman';

  @override
  String get contactConsumerDisputesBoardDirect => 'Tarbijavaidluste komisjon';

  @override
  String get caseTypeStepLabel => 'Juhtumi tüüp';

  @override
  String get detailsStepLabel => 'Üksikasjad';

  @override
  String get documentsStepLabel => 'Dokumendid';

  @override
  String get whatTypeOfCase => 'Mis tüüpi juhtumiga on tegu?';

  @override
  String get selectCategoryDescription =>
      'Valige kategooria, mis kirjeldab teie olukorda kõige paremini.';

  @override
  String get tellUsAboutCase => 'Rääkige meile oma juhtumist';

  @override
  String get aiHelpsUnderstand =>
      'See teave aitab meie AI-l teie olukorda paremini mõista.';

  @override
  String get caseTitleHint => 'nt Elamisloa kaebuse 2026';

  @override
  String get countryJurisdiction => 'Riik / Jurisdiktsioon';

  @override
  String get selectCountryHint => 'Valige riik';

  @override
  String get referenceNumberHint => 'nt UMA/12345/2026';

  @override
  String get descriptionOptional => 'Kirjeldus (valikuline)';

  @override
  String get descriptionHint =>
      'Kirjeldage oma olukorda lühidalt. Mis juhtus? Milline otsus tehti?';

  @override
  String get uploadFirstDocument => 'Laadige üles oma esimene dokument';

  @override
  String get uploadDocumentDescription =>
      'Laadige üles otsuse kiri või mõni asjakohane dokument. Võite selle sammu vahele jätta ja dokumendid hiljem lisada.';

  @override
  String get tapToUploadFile => 'Puudutage faili üleslaadimiseks';

  @override
  String get fileSizeLimit => 'PDF, JPG, PNG kuni 25 MB';

  @override
  String get addDocumentsLaterHint =>
      'Saate dokumente alati hiljem lisada juhtumi üksikasjade ekraanilt.';

  @override
  String get callAI => 'Helista AI-le';

  @override
  String get comingSoon => 'Tuleb peagi';

  @override
  String get encrypted => 'Krüpteeritud';

  @override
  String get typing => 'Kirjutab…';

  @override
  String get online => 'Võrgus';

  @override
  String get chatWelcomeSubtitle =>
      'Analüüsin olukorda, kontrollin dokumente, otsin vigu ja soovitan, mida teha.';

  @override
  String get tapMicrophoneToSpeak => 'Puudutage mikrofoni rääkimiseks';

  @override
  String get categoryEssential => 'Olulised';

  @override
  String get categoryPolice => 'Politsei';

  @override
  String get categoryWork => 'Töö';

  @override
  String get categoryHousing => 'Eluase';

  @override
  String get categoryConsumer => 'Tarbija';

  @override
  String rightsInsideCount(int count) {
    return '$count õigust sees';
  }

  @override
  String get freeAidThreshold => 'Tasuta abi piirmäär';

  @override
  String get partialAidThreshold => 'Osalise abi piirmäär';

  @override
  String get assetLimit => 'Varade piirmäär';

  @override
  String get whereToApplyLabel => 'Kuhu pöörduda';

  @override
  String get phoneLabel => 'Telefon';

  @override
  String get websiteLabel => 'Veebileht';

  @override
  String get disclaimerCollapsed => 'Üksnes teadmiseks';

  @override
  String get disclaimerExpanded =>
      'AI-assistent — mitte õigusnõuanne. Olulistel teemadel pidage nõu kvalifitseeritud juristiga.';

  @override
  String get chatDisclaimerBanner =>
      'AI-assistent pakub õigusteavet, mitte õigusnõuannet. Olulistel teemadel pidage nõu kvalifitseeritud juristiga.';

  @override
  String get categoryChildren => 'Lapsed';

  @override
  String get categoryDigital => 'Digitaalne';

  @override
  String get childrenRights => 'Lapse õigused ja elatis';

  @override
  String get childrenRightsDesc =>
      'Elatis, lastekaitse, riigi garantii, kohtusse pöördumine';

  @override
  String get cyberbullying => 'Küberkiusamine';

  @override
  String get cyberbullyingDesc =>
      'Ähvardamine, privaatsuse rikkumine, laimamine internetis';

  @override
  String get rightChildSupport =>
      'Mõlemal vanemal on seaduslik kohustus last rahaliselt ülal pidada (Perekonnaseadus § 100–102)';

  @override
  String get rightMinimumAlimony =>
      'Minimaalne elatis Eestis arvutatakse valemiga: baassumma (295,86 €) + 3% eelmise aasta keskmisest brutopalgast (PKS § 101). Alates 01.04.2026 — 318,62 €/kuus lapse kohta. Kohus võib seda suurendada vanema sissetuleku alusel. Kalkulaator: alimendid.ee';

  @override
  String get rightCourtAlimony =>
      'Elatist saab nõuda maakohtu kaudu — advokaati ei ole vaja nõuete puhul kuni 6400 €';

  @override
  String get rightBailiffEnforcement =>
      'Kui vanem keeldub maksmast, saab kohtutäitur kohtuotsuse täitmisele pöörata, sh palgast kinni pidada';

  @override
  String get rightStateAlimonyGuarantee =>
      'Kui vanem ei maksa, maksab riik elatisabi Sotsiaalkindlustusameti kaudu — kuni 100 €/kuus lapse kohta';

  @override
  String get rightChildEducation =>
      'Igal lapsel on õigus haridusele, tervishoiule ja kaitsele väärkohtlemise eest (Lastekaitseseadus § 4–5)';

  @override
  String get rightChildContact =>
      'Lapsel on õigus suhelda mõlema vanemaga, kui kohus ei ole teisiti otsustanud (PKS § 143)';

  @override
  String get mustFileCourtClaim =>
      'Elatise saamiseks tuleb esitada kohtule hagi või leppida summas kirjalikult kokku';

  @override
  String get mustNotifyAddressChange =>
      'Elatisabi saamisel teavitage Sotsiaalkindlustusametit aadressi muutumisest';

  @override
  String get childrenActionGatherDocs =>
      'Koguge kokku lapse sünnitunnistus, isikut tõendav dokument ja kulude tõendid';

  @override
  String get childrenActionFileCourtClaim =>
      'Esitage elatise hagi maakohtusse — saab teha internetis e-toimiku kaudu';

  @override
  String get childrenActionApplyElatisabi =>
      'Taotlege riigi elatisabi Sotsiaalkindlustusametist, kui vanem ei maksa';

  @override
  String get childrenActionContactBailiff =>
      'Pöörduge kohtutäituri poole kohtuotsuse täitmisele pööramiseks';

  @override
  String get childrenActionCallLasteabi =>
      'Helistage Lasteabi telefonile 116 111 — tasuta, ööpäevaringselt';

  @override
  String get childrenDeadlineElatisabi =>
      'Elatisabi taotlemine — pärast kohtuotsust, kindlat tähtaega ei ole, kuid protsess võtab aega';

  @override
  String get childrenDeadlineCourt =>
      'Elatist saab nõuda tagasiulatuvalt kuni 1 aasta enne kohtusse pöördumist';

  @override
  String get childrenFactMinimum =>
      'Alates 01.04.2026 on minimaalne elatis 318,62 €/kuus lapse kohta. Valem: baassumma (295,86 €) + 3% eelmise aasta keskmisest brutopalgast. Summa muutub igal aastal 1. aprillil. Vanem ei saa kokku leppida väiksemat summat. Kalkulaator: alimendid.ee';

  @override
  String get childrenFactElatisabi =>
      'Eesti riiklik elatisabi kehtestati 2017. aastal, et kaitsta lapsi, kui vanem keeldub elatist maksmast. Riik maksab ja nõuab summa hiljem võlgnikult sisse.';

  @override
  String get rightReportCybercrime =>
      'Teil on õigus teatada politseile internetiähvardustest, kiusamisest ja identiteedivargusest (KarS § 120, § 157¹)';

  @override
  String get rightContentRemoval =>
      'Saate nõuda laimava või eraelulise sisu eemaldamist platvormidelt ja nõuda kustutamist GDPR alusel';

  @override
  String get rightMoralDamageCompensation =>
      'Küberkiusamise tekitatud moraalse kahju eest saab nõuda hüvitist (VÕS § 1043–1055)';

  @override
  String get rightPrivacyProtection =>
      'Teie eraelu on kaitstud — fotode, sõnumite või isikuandmete loata jagamine on ebaseaduslik (KarS § 157)';

  @override
  String get rightDataProtection =>
      'Teatage andmekaitse rikkumistest (isikuandmete loata kasutamine) Andmekaitse Inspektsioonile';

  @override
  String get rightDefamationAction =>
      'Laimamine on tsiviilõiguslik rikkumine — saate nõuda kahju hüvitamist ja avalikku ümberlükkamist (VÕS § 1047)';

  @override
  String get mustCollectEvidence =>
      'Koguge ja säilitage kõik tõendid — ekraanipildid, lingid, kuupäevad ja tunnistajate andmed';

  @override
  String get mustNotRetaliate =>
      'Ärge vastake samaga ega kiusake vastu — see võib teie positsiooni nõrgendada';

  @override
  String get cyberActionScreenshots =>
      'Tehke ekraanipildid kogu kiusamisest — salvestage URL-id, kuupäevad, kasutajanimed ja sisu';

  @override
  String get cyberActionReportPolice =>
      'Esitage politseile avaldus lähimas kontoris või veebis politsei.ee kaudu';

  @override
  String get cyberActionReportPlatform =>
      'Teavitage sisu kohta sotsiaalmeedia platvormi eemaldamiseks';

  @override
  String get cyberActionContactDPA =>
      'Pöörduge Andmekaitse Inspektsiooni poole, kui teie isikuandmeid kuritarvitati';

  @override
  String get cyberActionConsultLawyer =>
      'Konsulteerige advokaadiga tsiviilkahju osas — tasuta õigusabi on saadaval Riigi Õigusabi kaudu';

  @override
  String get cyberDeadlineCriminal =>
      'Kriminaalteade — kindlat tähtaega ei ole, kuid teatage viivitamatult parima tulemuse saavutamiseks';

  @override
  String get cyberDeadlineCivil =>
      'Tsiviilhagi kahju hüvitamiseks — kuni 3 aastat rikkumisest teadasaamisest (TsÜS § 150)';

  @override
  String get cyberFactPrivacy =>
      'Eestis võib intiimpiltide loata jagamine kaasa tuua kuni 3 aasta pikkuse vangistuse Karistusseadustiku § 157¹ alusel.';

  @override
  String get cyberFactGDPR =>
      'GDPR-i kohaselt on teil „õigus olla unustatud“ — platvormid peavad teie isikuandmed kustutama, kui puudub seaduslik alus nende säilitamiseks.';

  @override
  String get guestUser => 'Külaline';

  @override
  String get howToUse => 'Kuidas kasutada?';

  @override
  String get tutorialStep1Title => 'AI õigusabi';

  @override
  String get tutorialStep1Desc =>
      'Küsige mis tahes õigusküsimus ja saage kohe vastus Eesti seaduste põhjal.';

  @override
  String get tutorialStep2Title => 'Tunne oma õigusi';

  @override
  String get tutorialStep2Desc =>
      'Sirvige õigusteavet teemade kaupa — töö, eluase, tarbijakaitse ja palju muud.';

  @override
  String get tutorialStep3Title => 'Skaneeri dokumente';

  @override
  String get tutorialStep3Desc =>
      'Pildistage õigusdokumente AI analüüsiks ja hoidke neid turvaliselt ühes kohas.';

  @override
  String get tutorialStep4Title => 'Alustame!';

  @override
  String get tutorialStep4Desc =>
      'Avastage rakendust ja kaitske oma õigusi. Andmed jäävad privaatseks teie seadmes.';

  @override
  String get advocatProTitle => 'Advocat Pro';

  @override
  String get advocatProSubtitle => 'Avage täiustatud funktsioonid';

  @override
  String get voiceDisclaimer =>
      'Häälassistent töötab praegu ainult lauaarvutis (Chrome\'i brauseris). Mobiilirakenduses tuleb tugi peagi.';

  @override
  String get recommended => 'Soovitatud';

  @override
  String get pleaseLogIn => 'Palun logige sisse';

  @override
  String get subscriptionNotFound => 'Tellimust ei leitud';

  @override
  String errorWithMessage(String message) {
    return 'Viga: $message';
  }

  @override
  String get redirectingToPayment => 'Suuname makselehele…';

  @override
  String cheaperAnnually(String amount) {
    return '€$amount kuus soodsam aastamaksuga';
  }

  @override
  String get navigatingTo => 'Avan';

  @override
  String get stayInChat => 'Jää vestlusesse';

  @override
  String get backToChat => 'Tagasi vestlusesse';

  @override
  String get upgradeBannerTitle => 'Vali Pro piiramatuteks konsultatsioonideks';

  @override
  String get upgradeBannerCta => 'Uuenda Pro-le';

  @override
  String get paymentSuccessTitle => 'Makse õnnestus';

  @override
  String get paymentSuccessBody => 'Teie tellimus on nüüd aktiivne.';

  @override
  String get commonOk => 'OK';

  @override
  String get feedbackThumbsUpLabel => 'Kasulik';

  @override
  String get feedbackThumbsDownLabel => 'Ei aidanud';

  @override
  String get feedbackCommentPrompt => 'Mis läks valesti?';

  @override
  String get feedbackSend => 'Saada';

  @override
  String get feedbackCancel => 'Tühista';

  @override
  String get reasoningPillIdle => 'Mõtlen…';

  @override
  String get reasoningPillSearchingLaw => 'Loen seadust…';

  @override
  String get reasoningPillSearchingWeb => 'Otsin veebist…';

  @override
  String get reasoningPillCheckingCompany => 'Kontrollin äriregistrit…';

  @override
  String get reasoningPillCheckingVehicle => 'Kontrollin sõidukiregistrit…';

  @override
  String get reasoningPillReadingDocument => 'Loen Teie dokumenti…';

  @override
  String get reasoningPillDrafting => 'Koostan dokumenti…';

  @override
  String get reasoningPillPreparingEmail => 'Valmistan e-kirja ette…';

  @override
  String get reasoningPillFindingLawyer => 'Otsin advokaate…';

  @override
  String get reasoningPillThinking => 'Analüüsin Teie juhtumit…';

  @override
  String get reasoningPillFinalising => 'Vormistan vastust…';

  @override
  String reasoningCollapsedFormat(int sec, int sources) {
    return 'Mõtlesin $sec s · $sources allikat';
  }

  @override
  String get reasoningExpandHint => 'vajuta sammude nägemiseks';

  @override
  String get caseFileTitle => 'Toimik';

  @override
  String get caseFileTimeline => 'Ajatelg';

  @override
  String get caseFileParties => 'Osalised';

  @override
  String get caseFileDeadlines => 'Tähtajad';

  @override
  String get caseFileExportPdf => 'Lae alla toimik (PDF)';

  @override
  String get caseFileEmpty =>
      'Vestle AI-ga oma juhtumist — ajatelg ehitub ise.';

  @override
  String get caseFileDisclaimer =>
      'See toimik on automaatselt vestlusest koostatud. See ei ole õigusnõuanne.';

  @override
  String get caseFileTabLabel => 'Toimik';

  @override
  String get refresh => 'Värskenda';

  @override
  String get demoLimitReached =>
      'Demoversiooni limiit on täis. Registreeru tasuta, et jätkata.';

  @override
  String get demoLimitSignUpCta => 'Registreeru';

  @override
  String get freeQuotaExhausted =>
      'Olete kasutanud kõik 7 tasuta sõnumit selles kuus.';

  @override
  String get upgradeForUnlimited => 'Uuenda Pro-le piiramatuks kasutamiseks';

  @override
  String get upgradeCta => 'Uuenda';

  @override
  String get rateLimitTryAgain =>
      'Saadate liiga kiiresti. Proovige paari sekundi pärast uuesti.';

  @override
  String get quickProfilePrompt =>
      'Et saaksin täpsemalt aidata: kas oled Eesti kodanik, mõne teise EL riigi kodanik, või on sul elamisluba?';

  @override
  String get quickProfileChipEstonianCitizen => 'Eesti kodanik';

  @override
  String get quickProfileChipEuCitizen => 'EL kodanik (muu)';

  @override
  String get quickProfileChipResidencePermit => 'Elamisluba';

  @override
  String get quickProfileSkipBtn => 'Jäta vahele';

  @override
  String get quickProfileSavedAck => 'Selge. Mis on su küsimus?';

  @override
  String get caseTitleLabel => 'Juhtumi pealkiri';

  @override
  String get jurisdictionLabel => 'Jurisdiktsioon';

  @override
  String get caseTypeLabel => 'Juhtumi tüüp';

  @override
  String get caseLanguageLabel => 'Keel';

  @override
  String get caseNumbersSection => 'Juhtumi numbrid';

  @override
  String get partiesSection => 'Osapooled';

  @override
  String get authoritiesSection => 'Asutused';

  @override
  String get timelineSection => 'Ajajoon';

  @override
  String get openQuestionsSection => 'Lahtised küsimused';

  @override
  String get nextActionsSection => 'Järgmised sammud';

  @override
  String get summarySection => 'Kokkuvõte';

  @override
  String get addRow => 'Lisa';

  @override
  String get removeRow => 'Eemalda';

  @override
  String get archiveCase => 'Arhiveeri';

  @override
  String get closeCase => 'Sulge juhtum';

  @override
  String get continueChatAboutCase => 'Jätka selle juhtumi vestlust';

  @override
  String get linkChatToCase => 'Seo juhtumiga';

  @override
  String get clearActiveCase => 'Tühjenda aktiivne juhtum';

  @override
  String get caseSavedAck => 'Juhtum salvestatud';

  @override
  String get caseArchivedAck => 'Juhtum arhiveeritud';

  @override
  String get intakeStep1Title => 'Kus on juhtum?';

  @override
  String get intakeStep1Subtitle => 'Riik ja asutus, kellega tegeled.';

  @override
  String get intakeJurisdictionLabel => 'Riik / jurisdiktsioon';

  @override
  String get intakeAuthorityLabel => 'Asutuse tüüp';

  @override
  String get intakeAuthorityNameLabel => 'Asutuse nimi (valikuline)';

  @override
  String get intakeAuthorityPolice => 'Politsei';

  @override
  String get intakeAuthorityCourt => 'Kohus';

  @override
  String get intakeAuthoritySocial => 'Sotsiaalamet';

  @override
  String get intakeAuthorityEmployer => 'Tööandja';

  @override
  String get intakeAuthorityLandlord => 'Üürileandja';

  @override
  String get intakeAuthorityOpposingParty => 'Vastaspool';

  @override
  String get intakeAuthorityOther => 'Muu';

  @override
  String get intakeStep2Title => 'Millise juhtumiga on tegu?';

  @override
  String get intakeStep2Subtitle => 'Vali lähim tüüp — saad hiljem täpsustada.';

  @override
  String get intakeCaseTypeCriminal => 'Kriminaal';

  @override
  String get intakeCaseTypeCivil => 'Tsiviil';

  @override
  String get intakeCaseTypeFamily => 'Perekond';

  @override
  String get intakeCaseTypeAdmin => 'Haldus';

  @override
  String get intakeCaseTypeImmigration => 'Migratsioon';

  @override
  String get intakeCaseTypeLabor => 'Töö';

  @override
  String get intakeCaseTypeConsumer => 'Tarbija';

  @override
  String get intakeCaseTypeInheritance => 'Pärimine';

  @override
  String get intakeCaseTypeOther => 'Muu';

  @override
  String get intakeStep3Title => 'Kes on osapooled?';

  @override
  String get intakeStep3Subtitle => 'Sinu roll ja vastaspool.';

  @override
  String get intakeRoleLabel => 'Sinu roll';

  @override
  String get intakeRolePlaintiff => 'Hageja';

  @override
  String get intakeRoleDefendant => 'Kostja';

  @override
  String get intakeRoleVictim => 'Kannatanu';

  @override
  String get intakeRoleAccused => 'Süüdistatav';

  @override
  String get intakeRoleWitness => 'Tunnistaja';

  @override
  String get intakeRoleFamily => 'Pereliige';

  @override
  String get intakeRoleOther => 'Muu';

  @override
  String get intakeOpposingSideLabel => 'Vastaspool (valikuline)';

  @override
  String get intakeWitnessesLabel => 'Tunnistajad (valikuline)';

  @override
  String get intakeAddWitness => 'Lisa tunnistaja';

  @override
  String get intakeWitnessHint => 'Nimi või kontakt';

  @override
  String get intakeStep4Title => 'Numbrid ja kuupäevad';

  @override
  String get intakeStep4Subtitle =>
      'Mida juba tead. Mida ei tea — jäta vahele.';

  @override
  String get intakeCaseNumberLabel => 'Juhtumi number (valikuline)';

  @override
  String get intakeIncidentDateLabel => 'Sündmuse kuupäev (valikuline)';

  @override
  String get intakeIncidentDatePick => 'Vali kuupäev';

  @override
  String get intakeDeadlinesLabel => 'Teadaolevad tähtajad';

  @override
  String get intakeAddDeadline => 'Lisa tähtaeg';

  @override
  String get intakeDeadlineWhatHint => 'Mis';

  @override
  String get intakeStep5Title => 'Dokumendid';

  @override
  String get intakeStep5Subtitle => 'Lae üles kõik asjakohane. Loeme need.';

  @override
  String get intakeUploadDocsLabel => 'Lae dokumendid';

  @override
  String get intakeSkipDocs => 'Jäta vahele — laen hiljem';

  @override
  String get intakeNextBtn => 'Edasi';

  @override
  String get intakeBackBtn => 'Tagasi';

  @override
  String get intakeFinishBtn => 'Lõpeta ja ava vestlus';

  @override
  String get intakeUrgentBtn => 'Kiireloomuline — küsi kohe';

  @override
  String get intakeUrgentDialogTitle => 'Kas avada vestlus kohe?';

  @override
  String get intakeUrgentDialogBody =>
      'Salvestame sisestatu mustandina. Saad ankeedi lõpetada juhtumi lehelt igal ajal.';

  @override
  String get intakeUrgentConfirm => 'Ava vestlus';

  @override
  String get intakeUrgentCancel => 'Jätka täitmist';

  @override
  String get intakePreparingCase => 'Valmistan juhtumit ette…';

  @override
  String get intakeFallbackGreeting =>
      'Ma näen sinu juhtumit. Ütle, mis on praegu kõige kiirem — vaatame koos läbi.';

  @override
  String get intakeUrgentGreeting =>
      'Ma näen, et see on kiireloomuline. Esita oma küsimus — täidan toimiku jutu käigus.';

  @override
  String intakeStepIndicator(int current, int total) {
    return 'Samm $current / $total';
  }

  @override
  String get intakeFieldRequired => 'Kohustuslik';

  @override
  String intakeUploadProgress(int done, int total) {
    return 'Laadin üles $done / $total…';
  }

  @override
  String get uplDisclaimerFooter =>
      'Advocat ei ole advokaadibüroo. See on informatsioon, mitte õigusnõu.';

  @override
  String get citationStatusVerifiedBadge => 'Kontrollitud';

  @override
  String get citationStatusUnverifiedBadge => 'Kontrollimata';

  @override
  String get citationStatusHistoricalBadge => 'Vana redaktsioon';

  @override
  String get citationStatusVerifiedTooltip =>
      'Tsiteeritud allikast, mis on otsitud praegusest seaduskorpusest.';

  @override
  String get citationStatusUnverifiedTooltip =>
      'AI tsiteeris seda ilma otsinguta — kontrolli enne tuginemist.';

  @override
  String get citationStatusHistoricalTooltip =>
      'Tsiteeritud säte ei kehti enam.';

  @override
  String get citationOpenInRiigiTeataja => 'Ava Riigi Teatajas';

  @override
  String get citationSnippetExpand => 'Näita täisteksti';

  @override
  String get citationSnippetCollapse => 'Peida';

  @override
  String get citationUnverifiedSheetNote =>
      'AI tsiteeris seda paragrahvi, kuid seda ei leitud praegusest seaduskorpusest. Kontrolli viidet enne tuginemist.';

  @override
  String get citationFooterNoneWarning => 'Allikaviiteid pole';

  @override
  String citationFooterSummaryTotal(int count) {
    return '$count viidet';
  }

  @override
  String citationFooterSummaryVerified(int count) {
    return '$count kontrollitud';
  }

  @override
  String citationFooterSummaryUnverified(int count) {
    return '$count kontrollimata';
  }

  @override
  String citationFooterSummaryHistorical(int count) {
    return '$count vana';
  }

  @override
  String get deadlineRadarTitle => 'Eesseisvad tähtajad';

  @override
  String get deadlineRadarEmpty => 'Eesseisvaid tähtaegasid pole';

  @override
  String get deadlineRadarViewAll => 'Vaata kõiki';

  @override
  String deadlineCardDaysLeft(int count) {
    return '$count päeva pärast';
  }

  @override
  String get deadlineCardTomorrow => 'homme';

  @override
  String get deadlineCardToday => 'täna';

  @override
  String deadlineCardOverdue(int count) {
    return '$count päeva üle tähtaja';
  }

  @override
  String get deadlineCardMarkComplete => 'Märgi tehtuks';

  @override
  String get deadlineCardSnooze => 'Lükka edasi';

  @override
  String get deadlineCardSnooze3d => 'Edasi 3 päeva';

  @override
  String get deadlineCardSnooze7d => 'Edasi 7 päeva';

  @override
  String get deadlineCardSnoozeCustom => 'Vali kuupäev';

  @override
  String get deadlineCardEdit => 'Muuda';

  @override
  String get deadlineCardDelete => 'Arhiveeri';

  @override
  String get deadlineCardSourceLabelPdf => 'PDF-ist';

  @override
  String get deadlineCardSourceLabelIntake => 'ankeedist';

  @override
  String get deadlineCardSourceLabelManual => 'käsitsi lisatud';

  @override
  String get deadlineCardSourceLabelEmail => 'e-kirjast';

  @override
  String get deadlineCardSourceLabelHaikuExtract => 'AI tuvastatud';

  @override
  String get deadlineCardSourceLabelStatutoryTemplate => 'seaduse mall';

  @override
  String deadlineBannerCritical(String title, String when) {
    return 'Kriitiline tähtaeg: $title $when';
  }

  @override
  String get deadlineBannerDismiss => 'Sulge';

  @override
  String get deadlineBannerOpen => 'Ava tähtaeg';

  @override
  String deadlineHolidayShifted(String original, String reason) {
    return 'Nihutatud kuupäevalt $original ($reason)';
  }

  @override
  String get deadlinePermissionAskTitle => 'Luba tähtaegade meeldetuletused?';

  @override
  String get deadlinePermissionAskBody =>
      'Saadame meeldetuletuse 7, 3 ja 1 päeva enne iga seadusjärgset tähtaega ning tähtaja päeva hommikul. Ei kasutata kunagi turunduseks.';

  @override
  String get deadlinePermissionAllow => 'Luba';

  @override
  String get deadlinePermissionLater => 'Hiljem';

  @override
  String get deadlineSettingsSection => 'Tähtaegade meeldetuletused';

  @override
  String get deadlineSettingsPushChannel => 'Tõuketeavitused';

  @override
  String get deadlineSettingsEmailChannel => 'E-post (ainult kriitilised)';

  @override
  String get deadlineSettingsInAppChannel => 'Sisesed teavitused';

  @override
  String get deadlineSettingsCriticalBypass =>
      'Kriitilised teavitused läbivad vaikust';

  @override
  String get deadlineSettingsQuietHours => 'Vaikne aeg';

  @override
  String deadlineSettingsQuietHoursBadge(String start, String end) {
    return 'Vaikne $start–$end';
  }

  @override
  String get deadlineCaseScreenTitle => 'Asja tähtajad';

  @override
  String get deadlineAddManualCta => 'Lisa tähtaeg';

  @override
  String get deadlineFormTitle => 'Pealkiri';

  @override
  String get deadlineFormDescription => 'Kirjeldus (valikuline)';

  @override
  String get deadlineFormStatuteTemplate => 'Seaduse mall';

  @override
  String get deadlineFormStatuteTemplateNone => 'Puudub (käsitsi)';

  @override
  String get deadlineFormDeadlineAt => 'Tähtaja kuupäev';

  @override
  String get deadlineFormPriority => 'Prioriteet';

  @override
  String get deadlineFormSave => 'Salvesta';

  @override
  String get deadlineFormCancel => 'Tühista';

  @override
  String get deadlineCompletedNotePrompt => 'Lisa märkus (valikuline)';

  @override
  String get deadlineCompletedNoteSave => 'Salvesta';

  @override
  String get inboxTitle => 'Postkast';

  @override
  String get inboxEmptyTitle => 'Pole midagi ootel';

  @override
  String get inboxEmptyBody =>
      'Uued e-kirjad ilmuvad siia, kui need on triaažitud.';

  @override
  String get inboxApproveSend => 'Kinnita ja saada';

  @override
  String get inboxEditDraft => 'Muuda';

  @override
  String get inboxSnooze => 'Edasi lükata';

  @override
  String get inboxArchive => 'Arhiveeri';

  @override
  String get inboxFilterAll => 'Kõik';

  @override
  String get inboxConfirmSendTitle => 'Kas saata ettevalmistatud vastus?';

  @override
  String get inboxConfirmSendBody =>
      'Advocat saadab AI ettevalmistatud vastuse sinu ühendatud Gmaili kaudu. Saad sisu vaadata järgmisel ekraanil.';

  @override
  String get inboxSendButton => 'Saada';

  @override
  String get inboxSentToast => 'Saadetud.';

  @override
  String get inboxSnoozedToast => 'Edasi lükatud 24 tunniks.';

  @override
  String get inboxArchivedToast => 'Arhiveeritud.';

  @override
  String get inboxDraftLoadError => 'Mustandit ei õnnestunud laadida.';
}
