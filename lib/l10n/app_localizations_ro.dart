// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Romanian Moldavian Moldovan (`ro`).
class AppLocalizationsRo extends AppLocalizations {
  AppLocalizationsRo([String locale = 'ro']) : super(locale);

  @override
  String get about => 'Despre';

  @override
  String get aboutSection => 'DESPRE';

  @override
  String get appearance => 'Aspect';

  @override
  String get appearanceSystem => 'Sistem (automat)';

  @override
  String get appearanceLight => 'Deschis';

  @override
  String get appearanceDark => 'Închis';

  @override
  String get appearanceDescription => 'Alegeți cum arată Advocat';

  @override
  String get accidents => 'Accidente';

  @override
  String get active => 'Activ';

  @override
  String get activeCases => 'Cazuri active';

  @override
  String get addedToAppeal => 'Adăugat la apel';

  @override
  String get agreeToTerms => 'Sunt de acord cu ';

  @override
  String get aiAnalysis => 'Analiză IA';

  @override
  String get aiAssistant => 'Asistent juridic IA';

  @override
  String get aiChat => 'Chat IA';

  @override
  String get all => 'Toate';

  @override
  String get alreadyHaveAccount => 'Aveți deja cont? ';

  @override
  String get analyzing => 'Se analizează…';

  @override
  String get aiAnalyzing => 'IA analizează';

  @override
  String get speakIntoMicHint =>
      'Vorbiți în microfon. Asigurați-vă că accesul la microfon este activat.';

  @override
  String get aiErrorRateLimit =>
      'Serviciul este temporar supraîncărcat. Vă rugăm să încercați din nou peste 1-2 minute.';

  @override
  String get aiErrorOverload =>
      'IA este ocupată în acest moment, vă rugăm să încercați din nou într-un minut.';

  @override
  String freeLimitReached(int count) {
    return 'Ați folosit toate cele $count mesaje IA gratuite. Treceți la Legal Counsel pentru asistență IA nelimitată!';
  }

  @override
  String get andWord => ' și ';

  @override
  String get appTitle => 'Advocat — Instrument de informații juridice';

  @override
  String get appVersion => 'Versiunea aplicației';

  @override
  String get appealFiled => 'Apel depus';

  @override
  String get areYouAbsolutelySure => 'Sunteți absolut sigur?';

  @override
  String get askAboutCase => 'Analizați cazul meu';

  @override
  String get asylum => 'Azil';

  @override
  String get back => 'Înapoi';

  @override
  String get basic => 'Bazic';

  @override
  String get beforeYouBuy => 'Înainte de a cumpăra';

  @override
  String get beforeYouWork => 'Înainte de a lucra cu ei';

  @override
  String get camera => 'Cameră';

  @override
  String get cancel => 'Anulați';

  @override
  String get caseDescription => 'Descrieți situația dvs.';

  @override
  String get caseDetail => 'Detalii caz';

  @override
  String get caseOverview => 'Iată rezumatul cazurilor dvs.';

  @override
  String get caseTitle => 'Titlul cazului';

  @override
  String get caseUpdated => 'Caz actualizat';

  @override
  String get cases => 'Cazuri';

  @override
  String get checkCompany => 'Verificați compania';

  @override
  String get checkDeadlines => 'Verificați termenele';

  @override
  String get checkVehicle => 'Verificați vehiculul';

  @override
  String get checkerTitle => 'Verificator';

  @override
  String get checkingErrors => 'Se verifică erorile…';

  @override
  String get choosePlan => 'Alegeți planul';

  @override
  String get closed => 'Închise';

  @override
  String get companyName => 'Numele companiei sau numărul de înregistrare';

  @override
  String get completed => 'Finalizat';

  @override
  String get confirm => 'Confirmați';

  @override
  String get confirmPassword => 'Confirmați parola';

  @override
  String get connectEmail => 'Conectați emailul';

  @override
  String get connectGmail => 'Conectați Gmail';

  @override
  String get connectOutlook => 'Conectați Outlook';

  @override
  String get connected => 'Conectat';

  @override
  String get contactSupport => 'Contactați suportul';

  @override
  String get continueWithGoogle => 'Continuați cu Google';

  @override
  String get appleComingSoon => 'În curând';

  @override
  String get appleComingSoonMessage =>
      'Autentificarea cu Apple va fi disponibilă în curând. Folosiți Google sau e-mailul pentru a continua.';

  @override
  String get copyText => 'Copiați textul';

  @override
  String get correspondence => 'Corespondență';

  @override
  String get couldNotLoadCases => 'Nu s-au putut încărca cazurile dvs.';

  @override
  String get country => 'Țară';

  @override
  String get createAccount => 'Creați cont';

  @override
  String get createCase => 'Creați caz';

  @override
  String get criminalCase => 'Caz penal';

  @override
  String get critical => 'Critic';

  @override
  String get currentPlan => 'Planul curent';

  @override
  String get dataAndPrivacy => 'DATE ȘI CONFIDENȚIALITATE';

  @override
  String get dataExportRequested =>
      'Export de date solicitat. Verificați emailul.';

  @override
  String daysRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zile',
      one: '1 zi',
      zero: 'nicio zi rămasă',
    );
    return '$_temp0';
  }

  @override
  String get deadlineReminders => 'Memento-uri pentru termene';

  @override
  String get deadlineRemindersDesc => 'Primiți notificări înainte de termene';

  @override
  String get deadlines => 'Termene';

  @override
  String get debtCollection => 'Recuperare creanțe';

  @override
  String get deleteAccount => 'Ștergeți contul';

  @override
  String get deleteAccountDesc => 'Eliminați permanent contul dvs.';

  @override
  String get deleteAccountDialogContent =>
      'Această acțiune este permanentă și irevocabilă. Toate datele, cazurile și documentele dvs. vor fi șterse permanent.';

  @override
  String get deleteConfirm =>
      'Sunteți sigur? Toate datele dvs. vor fi șterse permanent.';

  @override
  String get demoHint => 'Demo: încercați plăcuța „908FBT”';

  @override
  String get demoModeDesc =>
      'Explorați aplicația cu date exemplu dintr-un caz real';

  @override
  String get deportation => 'Deportare';

  @override
  String get disclaimer =>
      'Doar orientare IA — nu consultanță juridică. Consultați întotdeauna un avocat.';

  @override
  String get disclaimerFull =>
      'Acesta este un asistent IA, nu un avocat. Analiza IA poate conține erori. Verificați întotdeauna cu un profesionist juridic calificat.';

  @override
  String get disconnect => 'Deconectați';

  @override
  String get discrimination => 'Discriminare';

  @override
  String get doNotBuy => 'Nu cumpărați';

  @override
  String get documents => 'Documente';

  @override
  String documentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documente',
      one: '1 document',
      zero: 'niciun document',
    );
    return '$_temp0';
  }

  @override
  String get draftAppeal => 'Proiect de apel';

  @override
  String get editDraft => 'Editați';

  @override
  String get editProfile => 'Editați profilul';

  @override
  String get email => 'E-mail';

  @override
  String get emailConnected => 'Email conectat';

  @override
  String get emailDisconnected => 'Email deconectat';

  @override
  String get emailIntegration => 'INTEGRARE EMAIL';

  @override
  String get emailInvalid => 'Introduceți o adresă de email validă';

  @override
  String get emailPrivacyNote =>
      'Citim doar emailurile legate de chestiuni juridice. Emailurile personale rămân private.';

  @override
  String get emailRequired => 'Emailul este obligatoriu';

  @override
  String get emergencyShield => 'Scut de urgență';

  @override
  String get error => 'Eroare';

  @override
  String get exportDataDesc => 'Descărcați toate datele cazurilor dvs.';

  @override
  String get exportDataDialogContent =>
      'Vom pregăti o descărcare a tuturor datelor dvs., inclusiv cazuri, documente și corespondență. Veți primi un email când este gata.';

  @override
  String get exportMyData => 'Exportați datele mele';

  @override
  String get exportPdf => 'Exportați PDF';

  @override
  String get familyReunification => 'Reîntregirea familiei';

  @override
  String get forgotPassword => 'Ați uitat parola?';

  @override
  String get free => 'Gratuit';

  @override
  String get fullDefense => 'Advocat Pro';

  @override
  String get fullName => 'Nume complet';

  @override
  String get gallery => 'Galerie';

  @override
  String get generateAppeal => 'Generați apel';

  @override
  String get getStarted => 'Începeți';

  @override
  String goodAfternoon(String name) {
    return 'Bună ziua, $name';
  }

  @override
  String goodEvening(String name) {
    return 'Bună seara, $name';
  }

  @override
  String goodMorning(String name) {
    return 'Bună dimineața, $name';
  }

  @override
  String goodNight(String name) {
    return 'Noapte bună, $name';
  }

  @override
  String get home => 'Acasă';

  @override
  String get important => 'Important';

  @override
  String get inProgress => 'În desfășurare';

  @override
  String get informational => 'Informativ';

  @override
  String get inspection => 'Inspecție tehnică';

  @override
  String get insurance => 'Asigurare';

  @override
  String issuesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count probleme găsite',
      one: '1 problemă găsită',
      zero: 'nicio problemă găsită',
    );
    return '$_temp0';
  }

  @override
  String get laborDispute => 'Conflict de muncă';

  @override
  String get langEnglish => 'Engleză';

  @override
  String get langFinnish => 'Finlandeză';

  @override
  String get langRussian => 'Rusă';

  @override
  String get language => 'Limbă';

  @override
  String lastActivity(String time) {
    return 'Ultima activitate: $time';
  }

  @override
  String get legalFighter => 'Luptător juridic';

  @override
  String get legalSection => 'JURIDIC';

  @override
  String get licensePlate => 'Număr de înmatriculare';

  @override
  String get loading => 'Se încarcă…';

  @override
  String get logIn => 'Autentificare';

  @override
  String get loginFailed => 'Email sau parolă invalidă. Încercați din nou.';

  @override
  String get lost => 'Pierdut';

  @override
  String get markComplete => 'Marcați ca finalizat';

  @override
  String get mileage => 'Kilometraj';

  @override
  String get myCases => 'Cazurile mele';

  @override
  String get nameRequired => 'Numele complet este obligatoriu';

  @override
  String get newCase => 'Caz nou';

  @override
  String get next => 'Următor';

  @override
  String get noAccount => 'Nu aveți cont? ';

  @override
  String get noCases => 'Încă nu există cazuri';

  @override
  String get noCasesYet => 'Încă nu există cazuri';

  @override
  String get noDeadlines => 'Fără termene — totul în ordine!';

  @override
  String get noRecentActivity => 'Fără activitate recentă';

  @override
  String get notifications => 'NOTIFICĂRI';

  @override
  String get onboardingDesc1 =>
      'Advocat vă ajută să înțelegeți situația juridică. Instrumentele IA analizează documente, identifică posibile probleme și pregătesc proiecte de documente pentru revizuirea dvs. Nu este o firmă de avocatură — este un instrument tehnologic pentru a vă sprijini cazul.';

  @override
  String get onboardingDesc2 =>
      'Fotografiați orice document juridic. IA îl citește în mai multe limbi, extrage datele cheie și verifică conformitatea cu directivele UE și legislația națională.';

  @override
  String get onboardingDesc3 =>
      'Instrumentele noastre IA verifică peste 40 de tipuri de cerințe procedurale. Analiza IA poate identifica probleme care necesită atenție — cum ar fi limba de notificare, pașii procedurali și termenele legale. Verificați întotdeauna cu un avocat calificat.';

  @override
  String get onboardingDesc4 =>
      'IA pregătește proiecte de apeluri, plangeri și scrisori cu referințe legale pentru revizuirea dvs. Dvs. decideți ce să depuneți. Fiecare document trebuie revizuit de un profesionist juridic calificat înainte de depunere.';

  @override
  String get onboardingNext => 'Următor';

  @override
  String get onboardingSkip => 'Săriți';

  @override
  String get onboardingTitle1 => 'Informații juridice bazate pe IA';

  @override
  String get onboardingTitle2 => 'Scanați și analizați documente';

  @override
  String get onboardingTitle3 => 'IA verifică posibilele probleme';

  @override
  String get onboardingTitle4 => 'Proiecte de documente pentru revizuirea dvs.';

  @override
  String get openACase => 'Deschideți un caz';

  @override
  String get optional => '(opțional)';

  @override
  String get orDivider => 'sau';

  @override
  String get other => 'Altele';

  @override
  String get overdue => 'Depășit';

  @override
  String get owners => 'Proprietari anteriori';

  @override
  String get password => 'Parolă';

  @override
  String get passwordRequired => 'Parola este obligatorie';

  @override
  String get passwordStrengthMedium => 'Medie';

  @override
  String get passwordStrengthStrong => 'Puternică';

  @override
  String get passwordStrengthWeak => 'Slabă';

  @override
  String get passwordTooShort => 'Parola trebuie să aibă cel puțin 8 caractere';

  @override
  String get passwordsDoNotMatch => 'Parolele nu se potrivesc';

  @override
  String get pendingDecision => 'Decizie în așteptare';

  @override
  String get perCheck => 'per verificare';

  @override
  String get permanentlyDelete => 'Ștergeți permanent';

  @override
  String get policeMisconduct => 'Abuz polițienesc';

  @override
  String get popular => 'POPULAR';

  @override
  String get preferences => 'PREFERINȚE';

  @override
  String get preferredLanguage => 'Limba preferată';

  @override
  String get pricePerCheck => '€4,99 per verificare';

  @override
  String get privacyPolicy => 'Politica de confidențialitate';

  @override
  String get dpaTitle => 'Acord de prelucrare a datelor';

  @override
  String get dpaCheckoutGateTitle => 'Înainte de a face upgrade';

  @override
  String get dpaCheckoutGateBody =>
      'Legislația UE (GDPR Art. 28) ne obligă să semnăm un Acord de prelucrare a datelor cu fiecare client plătitor. Vă rugăm să îl analizați și să îl acceptați.';

  @override
  String get dpaViewLink => 'Vizualizați Acordul de prelucrare a datelor';

  @override
  String get dpaCheckboxLabel =>
      'Am citit și accept Acordul de prelucrare a datelor (v1.0).';

  @override
  String get dpaCancel => 'Anulează';

  @override
  String get dpaAcceptAndContinue => 'Acceptă și continuă';

  @override
  String get dpaOpenHint =>
      'Deschideți Acordul de prelucrare a datelor cel puțin o dată pentru a activa butonul Acceptă.';

  @override
  String get pro => 'Pro';

  @override
  String get pushNotifications => 'Notificări push';

  @override
  String get rateUs => 'Evaluați-ne';

  @override
  String get rateAppComingSoon => 'În curând în magazinele de aplicații!';

  @override
  String get dataCopiedToClipboard => 'Datele au fost copiate în clipboard';

  @override
  String get readingDocument => 'Se citește documentul…';

  @override
  String get recentActivity => 'Activitate recentă';

  @override
  String get referenceNumber => 'Număr de referință';

  @override
  String get registerFailed => 'Înregistrarea a eșuat. Încercați din nou.';

  @override
  String get reportFraud => 'Raportați frauda';

  @override
  String get requestExport => 'Solicitați exportul';

  @override
  String get researchingLaw => 'Se cercetează legislația aplicabilă…';

  @override
  String get resetPasswordFailed =>
      'Trimiterea linkului a eșuat. Încercați din nou.';

  @override
  String get resetPasswordSent => 'Link de resetare trimis la emailul dvs.';

  @override
  String get residencePermit => 'Permis de ședere';

  @override
  String get manageSubscription => 'Gestionați abonamentul';

  @override
  String get restorePurchases => 'Restaurați achizițiile';

  @override
  String get retry => 'Reîncercați';

  @override
  String get reviewWarning =>
      'Revizuiți cu atenție înainte de trimitere. Sunteți responsabil pentru conținut.';

  @override
  String get riskHigh => 'Risc ridicat — evitați';

  @override
  String get riskLow => 'Sigur de lucrat cu';

  @override
  String get riskMedium => 'Procedați cu prudență';

  @override
  String get safeToBuy => 'Sigur de cumpărat';

  @override
  String get saveAndAnalyze => 'Salvați și analizați';

  @override
  String get saveDraft => 'Salvați';

  @override
  String get saveWithAnnual => 'Economisiți 25% cu facturarea anuală';

  @override
  String get scan => 'Scanare';

  @override
  String get scanDocument => 'Scanați documentul';

  @override
  String get searchCases => 'Căutați cazuri…';

  @override
  String get selectCountry => 'Selectați țara';

  @override
  String get selectLanguage => 'Selectați limba';

  @override
  String get sendViaEmail => 'Trimiteți prin email';

  @override
  String get settings => 'Setări';

  @override
  String get signIn => 'Conectare';

  @override
  String get signInLink => 'Autentificare';

  @override
  String get signInSubtitle => 'Conectați-vă pentru a accesa cazurile dvs.';

  @override
  String get signOut => 'Deconectare';

  @override
  String get signOutConfirm => 'Sunteți sigur că doriți să vă deconectați?';

  @override
  String get signUp => 'Creați cont';

  @override
  String get signUpLink => 'Înregistrați-vă';

  @override
  String get socialBenefits => 'Prestații sociale';

  @override
  String get someConcerns => 'Unele îngrijorări';

  @override
  String get startFirstCase => 'Începeți primul caz';

  @override
  String step(int current, int total) {
    return 'Pasul $current din $total';
  }

  @override
  String get stolen => 'Verificare furt';

  @override
  String get subscription => 'Abonament';

  @override
  String get syncLegalCorrespondence => 'Sincronizați corespondența juridică';

  @override
  String get syncNow => 'Sincronizați acum';

  @override
  String get tenantRights => 'Drepturile chiriașului';

  @override
  String get termsOfService => 'Termenii serviciului';

  @override
  String get termsRequired => 'Trebuie să acceptați Termenii serviciului';

  @override
  String get timeline => 'Cronologie';

  @override
  String get tryDemoMode => 'Încercați modul demo';

  @override
  String get typeDeleteToConfirm =>
      'Tastați DELETE pentru a confirma ștergerea permanentă a contului.';

  @override
  String get typeMessage => 'Scrieți un mesaj…';

  @override
  String get upcoming => 'În curând';

  @override
  String get uploadDocument => 'Încărcați documentul';

  @override
  String urgentDeadline(String title) {
    return 'Urgent: $title';
  }

  @override
  String get useInAppeal => 'Folosiți în apel';

  @override
  String get vehicleChecker => 'Verificator vehicule';

  @override
  String get vehicleChecks => 'Verificări de stare';

  @override
  String get vehicleColor => 'Culoare';

  @override
  String get vehicleMake => 'Marcă';

  @override
  String get vehicleModel => 'Model';

  @override
  String get vehicleYear => 'An';

  @override
  String get version => 'Versiune';

  @override
  String get victimSupport => 'Sprijin pentru victime';

  @override
  String get viewAll => 'Vedeți toate';

  @override
  String get vinNumber => 'Număr VIN';

  @override
  String get welcomeBack => 'Bine ați revenit';

  @override
  String get whatAreMyOptions => 'Care sunt opțiunile mele?';

  @override
  String get won => 'Câștigat';

  @override
  String get documentVault => 'Seif documente';

  @override
  String get secureDocumentStorage => 'Stocare securizată documente';

  @override
  String get secureDocumentStorageDesc =>
      'Păstrați documentele juridice importante într-un singur loc.';

  @override
  String get addDocument => 'Adaugă document';

  @override
  String get chooseHowToAdd => 'Alegeți cum să adăugați documentul';

  @override
  String get uploadFile => 'Încarcă fișier';

  @override
  String get uploadFileDesc => 'Alegeți un PDF sau o imagine de pe dispozitiv';

  @override
  String get scanDocumentDesc => 'Faceți o fotografie documentului';

  @override
  String get createNote => 'Creează notă';

  @override
  String get createNoteDesc =>
      'Scrieți o notă sau înregistrați detalii importante';

  @override
  String get knowYourRights => 'Cunoaște-ți drepturile';

  @override
  String get stoppedByPolice => 'Oprit de poliție';

  @override
  String get stoppedByPoliceDesc =>
      'Drepturile dvs. în timpul unui control de poliție';

  @override
  String get deportationNotice => 'Notificare deportare';

  @override
  String get deportationNoticeDesc =>
      'Pași pentru contestarea unui ordin de expulzare';

  @override
  String get workplaceRights => 'Drepturi la locul de muncă';

  @override
  String get workplaceRightsDesc =>
      'Protecții ale dreptului muncii în Finlanda';

  @override
  String get tenantRightsDesc => 'Protecții locative și de închiriere';

  @override
  String get immigrationDetention => 'Detenție pentru imigrare';

  @override
  String get immigrationDetentionDesc =>
      'Drepturi dacă sunteți reținut de autorități';

  @override
  String get discriminationDesc =>
      'Cum să raportați și să combateți discriminarea';

  @override
  String get scenarioNotFound => 'Scenariu negăsit';

  @override
  String get youHaveRightTo => 'Aveți dreptul la:';

  @override
  String get youMust => 'Trebuie să:';

  @override
  String get immediateSteps => 'Pași imediați:';

  @override
  String get yourRights => 'Drepturile dvs.:';

  @override
  String get basicRights => 'Drepturi de bază:';

  @override
  String get yourRightsAsTenant => 'Drepturile dvs. ca chiriaș:';

  @override
  String get yourRightsInDetention => 'Drepturile dvs. în detenție:';

  @override
  String get howToAct => 'Cum să acționați:';

  @override
  String get rightKnowWhyStopped => 'Să știți de ce ați fost oprit';

  @override
  String get rightRemainSilent =>
      'Păstrați tăcerea (trebuie să vă identificați)';

  @override
  String get rightAskInterpreter => 'Cereți un interpret';

  @override
  String get rightContactLawyer => 'Contactați un avocat înainte de audiere';

  @override
  String get rightRecordEncounter =>
      'Înregistrați întâlnirea (în locuri publice)';

  @override
  String get mustProvideName => 'Furnizați numele și data nașterii';

  @override
  String get mustShowId => 'Arătați actul de identitate dacă aveți';

  @override
  String get mustNotResist => 'A nu opune rezistență fizică';

  @override
  String get doNotIgnoreNotice =>
      'NU ignorați notificarea - termenele sunt stricte';

  @override
  String get noteAppealDeadline =>
      'Notați termenul contestației (de obicei 30 zile)';

  @override
  String get contactLawyerImmediately => 'Contactați imediat un avocat';

  @override
  String get applyLegalAid => 'Solicitați asistență juridică dacă este necesar';

  @override
  String get rightAppealAdmin =>
      'Dreptul de a contesta la Tribunalul Administrativ';

  @override
  String get rightLegalRep => 'Dreptul la reprezentare juridică';

  @override
  String get rightInterpreter => 'Dreptul la un interpret';

  @override
  String get rightStayDuringAppeal =>
      'Dreptul de a rămâne în timpul contestației';

  @override
  String get minimumWage => 'Salariu minim conform contractului colectiv';

  @override
  String get workingTimeLimits =>
      'Limite timp de lucru (max 8h/zi, 40h/săptămână)';

  @override
  String get annualLeave => 'Concediu anual (minim 2 zile pe lună lucrată)';

  @override
  String get sickLeave => 'Compensație concediu medical';

  @override
  String get safeWorkingConditions => 'Condiții de muncă sigure';

  @override
  String get writtenRentalAgreement =>
      'Contract de închiriere scris obligatoriu';

  @override
  String get securityDeposit => 'Garanție max 3 luni chirie';

  @override
  String get landlordNotice => 'Proprietarul trebuie să dea preaviz (3–6 luni)';

  @override
  String get rightHabitableDwelling => 'Dreptul la o locuință locuibilă';

  @override
  String get protectionUnjustEviction =>
      'Protecție împotriva evacuării nejuste';

  @override
  String get rightKnowDetentionReason =>
      'Dreptul de a cunoaște motivul detenției';

  @override
  String get rightContactLawyerDetention => 'Dreptul de a contacta un avocat';

  @override
  String get rightContactEmbassy => 'Dreptul de a contacta ambasada';

  @override
  String get rightChallengeDetention =>
      'Dreptul de a contesta detenția în instanță';

  @override
  String get rightHumaneTreatment =>
      'Dreptul la tratament uman și îngrijire medicală';

  @override
  String get documentIncident => 'Documentați incidentul (data, ora, martori)';

  @override
  String get fileComplaintOmbudsman =>
      'Depuneți o plângere la Ombudsmanul pentru nediscriminare';

  @override
  String get contactLegalAidOffice =>
      'Contactați un birou de asistență juridică';

  @override
  String get reportToPolice => 'Raportați la poliție dacă e infracțiune';

  @override
  String get legalAidCalculator => 'Calculator asistență juridică';

  @override
  String checkEligibility(String country) {
    return 'Verificați eligibilitatea pentru asistența juridică: $country';
  }

  @override
  String get estimateDisclaimer =>
      'Aceasta este doar o estimare. Eligibilitatea reală este determinată de Biroul de Asistență Juridică.';

  @override
  String get monthlyIncome => 'Venit lunar (EUR)';

  @override
  String get totalAssets => 'Active totale (EUR)';

  @override
  String get numberOfDependents => 'Număr de persoane în întreținere';

  @override
  String get calculateEligibility => 'Calculează eligibilitatea';

  @override
  String get likelyEligible => 'Probabil eligibil';

  @override
  String get mayNotQualify => 'Este posibil să nu vă calificați';

  @override
  String get fullFreeLegalAid =>
      'Probabil vă calificați pentru asistență juridică gratuită.';

  @override
  String legalAidWithCopay(String percent) {
    return 'Puteți beneficia de asistență juridică cu o coplată de $percent%.';
  }

  @override
  String get mayNotQualifyDesc =>
      'Pe baza acestei estimări, este posibil să nu vă calificați pentru asistență juridică de stat.';

  @override
  String get couldNotLoadDeadlines => 'Nu s-au putut încărca termenele';

  @override
  String get noUpcomingDeadlines => 'Fără termene viitoare';

  @override
  String get allClearDeadlines =>
      'Totul e în ordine! Termenele noi vor apărea aici.';

  @override
  String get nothingOverdue => 'Nimic întârziat';

  @override
  String get greatJobDeadlines => 'Bravo că respectați termenele.';

  @override
  String get noCompletedDeadlines => 'Niciun termen finalizat';

  @override
  String get completedDeadlinesDesc =>
      'Termenele finalizate vor fi afișate aici.';

  @override
  String get daysLate => 'zile întârziere';

  @override
  String get days => 'zile';

  @override
  String get fromDocument => 'Din document';

  @override
  String get couldNotLoadCase => 'Nu s-au putut încărca detaliile cazului';

  @override
  String get typeLabel => 'Tip';

  @override
  String get nationality => 'Naționalitate';

  @override
  String get migriReference => 'Referință Migri';

  @override
  String get courtCaseNo => 'Nr. dosar instanță';

  @override
  String get created => 'Creat';

  @override
  String get citizenship => 'Cetățenie';

  @override
  String get workPermit => 'Permis de muncă';

  @override
  String get noDocumentsYet => 'Încă nu s-au încărcat documente';

  @override
  String get noUpcomingDeadlinesShort => 'Fără termene viitoare';

  @override
  String get caseCreated => 'Caz creat';

  @override
  String get decisionReceived => 'Decizie primită';

  @override
  String get appealDeadline => 'Termen contestație';

  @override
  String get hearingScheduled => 'Audiență programată';

  @override
  String get late => 'întârziat';

  @override
  String get pending => 'În așteptare';

  @override
  String get processing => 'Procesare';

  @override
  String get ready => 'Pregătit';

  @override
  String get failed => 'Eșuat';

  @override
  String get analyzed => 'Analizat';

  @override
  String get noDocumentsScanHint =>
      'Încă nu sunt documente. Scanați sau încărcați.';

  @override
  String get inCourt => 'În instanță';

  @override
  String get appeal => 'Contestație';

  @override
  String get caseTimeline => 'Cronologia cazului';

  @override
  String get couldNotLoadTimeline => 'Nu s-a putut încărca cronologia';

  @override
  String get noEventsYet => 'Încă nu sunt evenimente';

  @override
  String get activityWillAppear =>
      'Activitățile vor apărea aici pe măsură ce cazul progresează.';

  @override
  String caseCreatedDesc(String title) {
    return 'Cazul „$title” a fost creat.';
  }

  @override
  String get decisionReceivedDesc =>
      'O decizie oficială a fost primită pentru acest caz.';

  @override
  String get appealDeadlineSet => 'Termen contestație setat';

  @override
  String appealDeadlineDesc(String date) {
    return 'Contestația trebuie depusă până la $date.';
  }

  @override
  String hearingScheduledDesc(String date) {
    return 'Audiență în instanță programată pentru $date.';
  }

  @override
  String get caseInfoUpdated => 'Informațiile cazului au fost actualizate.';

  @override
  String get noEventsForFilter =>
      'Niciun eveniment nu corespunde acestui filtru';

  @override
  String get timelineFilterAll => 'Toate';

  @override
  String get timelineFilterEmails => 'E-mailuri';

  @override
  String get timelineFilterConsilium => 'Decizii IA';

  @override
  String get timelineFilterDeadlines => 'Termene';

  @override
  String get timelineFilterNotes => 'Note';

  @override
  String get timelineEventEmailIn => 'E-mail primit';

  @override
  String get timelineEventEmailOut => 'E-mail trimis';

  @override
  String get timelineEventConsiliumDecision => 'Decizie IA';

  @override
  String get timelineEventDeadlineSet => 'Termen';

  @override
  String get timelineEventDocUploaded => 'Document';

  @override
  String get timelineEventPhaseChange => 'Schimbare de fază';

  @override
  String get timelineEventManualNote => 'Notă';

  @override
  String get timelineJustNow => 'Chiar acum';

  @override
  String timelineMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'acum $count minute',
      one: 'acum 1 minut',
    );
    return '$_temp0';
  }

  @override
  String timelineHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'acum $count ore',
      one: 'acum 1 oră',
    );
    return '$_temp0';
  }

  @override
  String timelineDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'acum $count zile',
      one: 'acum 1 zi',
    );
    return '$_temp0';
  }

  @override
  String get documentAnalysis => 'Analiză document';

  @override
  String get exportAsPdf => 'Exportă ca PDF';

  @override
  String get pdfExportComingSoon => 'Export PDF în curând';

  @override
  String get analysisFailedRetry => 'Analiza a eșuat. Încercați din nou.';

  @override
  String get somethingWentWrong => 'Ceva a mers greșit';

  @override
  String get genericError =>
      'Ceva a mers prost. Vă rugăm să încercați din nou.';

  @override
  String get retryAnalysis => 'Reîncearcă analiza';

  @override
  String issuesFoundInDocument(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count probleme găsite în documentul dvs.',
      one: '1 problemă găsită în documentul dvs.',
      zero: 'Nicio problemă în documentul dvs.',
    );
    return '$_temp0';
  }

  @override
  String get severityOverview => 'Rezumat gravitate';

  @override
  String get issuesFoundHeader => 'Probleme găsite';

  @override
  String generateAppealWithIssues(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Generează apel ($count probleme)',
      one: 'Generează apel (1 problemă)',
    );
    return '$_temp0';
  }

  @override
  String get analyzingContent => 'Se analizează conținutul…';

  @override
  String get documentProcessedOk => 'Document procesat cu succes';

  @override
  String get noSignificantIssues =>
      'Nu s-au detectat probleme semnificative în acest document.';

  @override
  String get cameraPermissionRequired => 'Este necesară permisiunea camerei';

  @override
  String get cameraPermissionDesc =>
      'Acordați acces la cameră pentru scanarea documentelor sau utilizați galeria.';

  @override
  String get openSettings => 'Deschide setările';

  @override
  String get alignDocument => 'Aliniați documentul în cadru';

  @override
  String pageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pagini',
      one: '1 pagină',
      zero: 'nicio pagină',
    );
    return '$_temp0';
  }

  @override
  String get preview => 'Previzualizare';

  @override
  String pageNumber(int number) {
    return 'Pagina $number';
  }

  @override
  String get done => 'Gata';

  @override
  String get retake => 'Reface';

  @override
  String get useThisPhoto => 'Folosește această fotografie';

  @override
  String get addPage => 'Adaugă pagină';

  @override
  String uploadingPercent(int percent) {
    return 'Se încarcă… $percent%';
  }

  @override
  String get preparingUpload => 'Se pregătește încărcarea…';

  @override
  String get documentUploadedSuccess => 'Document încărcat cu succes';

  @override
  String pagesUploadedSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pagini încărcate cu succes',
      one: '1 pagină încărcată cu succes',
    );
    return '$_temp0';
  }

  @override
  String get uploadFailed => 'Încărcarea a eșuat. Verificați conexiunea.';

  @override
  String get capturePhotoFailed =>
      'Nu s-a putut face fotografia. Încercați din nou.';

  @override
  String get readingText => 'Se citește textul…';

  @override
  String get draftDocument => 'Ciornă document';

  @override
  String get saveChanges => 'Salvează modificările';

  @override
  String get editDocument => 'Editează documentul';

  @override
  String get generatingDraft => 'Se generează ciorna…';

  @override
  String get generatingDraftDesc =>
      'IA pregătește un document juridic bazat pe detaliile cazului dvs.';

  @override
  String get failedToGenerateDraft =>
      'Nu s-a putut genera ciorna. Încercați din nou.';

  @override
  String get changesSaved => 'Modificări salvate';

  @override
  String get copiedToClipboard => 'Copiat în clipboard';

  @override
  String get emailComingSoon => 'Trimiterea emailurilor în curând';

  @override
  String get reviewBeforeSending =>
      'Verificați cu atenție înainte de trimitere. Sunteți responsabil pentru conținut.';

  @override
  String get noContentAvailable => 'Conținut indisponibil';

  @override
  String get save => 'Salvează';

  @override
  String get edit => 'Editează';

  @override
  String get pdf => 'PDF';

  @override
  String get copy => 'Copiază';

  @override
  String get appealDraft => 'Ciornă contestație';

  @override
  String selected(int count) {
    return '$count selectate';
  }

  @override
  String get deleteSelected => 'Șterge selectate';

  @override
  String deleteDocumentsConfirm(int count) {
    return 'Ștergeți $count documente?';
  }

  @override
  String get delete => 'Șterge';

  @override
  String get analyzeSelected => 'Analizează selectate';

  @override
  String get batchAnalysisStarting => 'Se pornește analiza în serie…';

  @override
  String get switchToList => 'Comută la listă';

  @override
  String get switchToGrid => 'Comută la grilă';

  @override
  String get scanNew => 'Scanare nouă';

  @override
  String get noDocumentsYetScan => 'Încă nu sunt documente';

  @override
  String get scanFirstDocumentHint =>
      'Scanați primul document pentru ca IA să-l analizeze.';

  @override
  String get failedToLoadDocuments => 'Nu s-au putut încărca documentele';

  @override
  String get emailIntegrationTitle => 'Integrare email';

  @override
  String get connectYourEmail => 'Conectați-vă emailul';

  @override
  String get connectYourEmailDesc =>
      'Conectați emailul pentru a detecta automat corespondența juridică legată de cazurile dvs.';

  @override
  String get legalEmails => 'Emailuri juridice';

  @override
  String get unlinkedEmails => 'Emailuri neasociate';

  @override
  String get noLegalEmailsYet => 'Încă nu sunt emailuri juridice';

  @override
  String get legalEmailsWillAppear =>
      'Emailurile clasificate ca juridice vor apărea aici.';

  @override
  String get assignToCase => 'Atribuie cazului';

  @override
  String get disconnectEmail => 'Deconectează emailul';

  @override
  String get disconnectEmailConfirm =>
      'Sincronizarea automată va fi oprită. Emailurile sincronizate anterior vor rămâne.';

  @override
  String get gmailReauthBannerBody =>
      'Advocat v2.1 vă citește căsuța de e-mail pentru a redacta răspunsuri; puteți revoca oricând. Reconectați Gmail pentru a activa trierea proactivă.';

  @override
  String get gmailReauthBannerCta => 'Reautorizează';

  @override
  String connectedTo(String email) {
    return 'Conectat la $email';
  }

  @override
  String lastSynced(String time) {
    return 'Ultima sincronizare: $time';
  }

  @override
  String get filterByType => 'Filtrează după tip';

  @override
  String get noCasesMatchSearch => 'Niciun caz nu corespunde căutării';

  @override
  String get failedToLoadCases => 'Nu s-au putut încărca cazurile';

  @override
  String get monthly => 'Lunar';

  @override
  String get annual => 'Anual';

  @override
  String get saveTwentyFivePercent => 'Economisiți 25%';

  @override
  String get mostPopular => 'CEL MAI POPULAR';

  @override
  String get oneCaseActive => '1 caz activ';

  @override
  String get threeCasesActive => '3 cazuri active';

  @override
  String get unlimitedCases => 'Cazuri nelimitate';

  @override
  String get threeDocScans => '3 scanări documente';

  @override
  String get twentyDocScans => '20 scanări documente';

  @override
  String get unlimitedDocScans => 'Scanare nelimitată';

  @override
  String get basicAiAnalysis => 'Analiză IA de bază';

  @override
  String get fullAiAnalysis => 'Analiză IA completă';

  @override
  String get draftGeneration => 'Generare ciorne';

  @override
  String get priorityProcessing => 'Procesare prioritară';

  @override
  String get fiveAiMessagesTotal => '5 mesaje IA (pe viață)';

  @override
  String get hundredAiMessagesDay => '100 mesaje IA/zi';

  @override
  String get unlimitedAiMessages => 'Mesaje IA nelimitate';

  @override
  String get voiceInput => 'Introducere vocală';

  @override
  String get strategyRecommendations => 'Recomandări de strategie';

  @override
  String get foundingMemberNote =>
      'Membru fondator: 9,99 €/lună pentru primele 3 luni';

  @override
  String get saveTwentyPercent => 'Economisiți 20%';

  @override
  String get forever => 'pentru totdeauna';

  @override
  String get perMonth => '/lună';

  @override
  String get perYear => '/an';

  @override
  String get checkingPurchases => 'Se verifică achizițiile anterioare…';

  @override
  String get noPreviousPurchases => 'Nu s-au găsit achiziții anterioare.';

  @override
  String get chatWelcomeMessage =>
      'Bună! Sunt Advocat — asistentul dumneavoastră juridic bazat pe AI. Ofer informații juridice, nu consultanță juridică. Cu ce întrebare juridică vă pot ajuta?';

  @override
  String get copySummary => 'Copiază rezumatul';

  @override
  String get caseSummaryCopied => 'Rezumatul cazului copiat';

  @override
  String get openCase => 'Deschide cazul';

  @override
  String get viewFull => 'Vezi complet';

  @override
  String get draftCopiedToClipboard => 'Ciornă copiată în clipboard';

  @override
  String get reportMileageFraud => 'Raportează fraudă de kilometraj';

  @override
  String get reportMileageFraudDesc =>
      'Se va crea un raport de fraudă bazat pe datele verificării vehiculului.';

  @override
  String get reportAndOpenCase => 'Raportează și deschide caz';

  @override
  String get caseCreationComingSoon =>
      'Crearea cazului cu date precompletate în curând';

  @override
  String get failedToCreateCaseRetry =>
      'Nu s-a putut crea cazul. Încercați din nou.';

  @override
  String get takePhotoInstead => 'Faceți o fotografie';

  @override
  String get deleteCase => 'Șterge cazul';

  @override
  String deleteCaseConfirm(String title) {
    return 'Sigur doriți să ștergeți „$title”? Acțiunea nu poate fi anulată.';
  }

  @override
  String get haveQuestionsAi => 'Întrebări? Întrebați IA';

  @override
  String get cookiePolicy => 'Politica cookie-urilor';

  @override
  String get aiDisclaimer => 'Avertisment IA';

  @override
  String get aiDisclaimerCompact =>
      'Advocat oferă informații juridice generate de AI, nu consultanță juridică. Verificați cu un avocat licențiat înainte de a acționa.';

  @override
  String get aiDisclaimerFullTitle => 'Important: cum funcționează Advocat';

  @override
  String get aiDisclaimerFullBody =>
      'Advocat este un instrument bazat pe inteligență artificială care oferă informații juridice, nu consultanță juridică. Conform Regulamentului UE privind IA (art. 50), trebuie să vă informăm clar: interacționați cu o inteligență artificială, nu cu un avocat uman.\n\nAdvocat nu este o casă de avocatură. Nu suntem avocați licențiați conform Legii estoniene privind avocatura (Advokatuuriseadus) sau Legii finlandeze privind avocatura (Asianajajalaki), iar secretul profesional avocat-client nu se aplică conversațiilor dumneavoastră cu acest instrument. Înainte de a vă baza pe orice răspuns — pentru a depune o contestație, a semna un contract sau a acționa în privința unui termen — verificați cu un avocat licențiat din jurisdicția dumneavoastră.';

  @override
  String get aiDisclaimerExpand => 'Aflați mai multe';

  @override
  String get aiDisclaimerDismiss => 'Am înțeles';

  @override
  String get dataPrivacyConsent => 'Consimțământ confidențialitate date';

  @override
  String get gdprIntro =>
      'Pentru a oferi asistență juridică cu IA, procesăm datele dvs. conform GDPR (UE 2016/679). Continuând, acceptați:';

  @override
  String get gdprChat => 'Procesarea mesajelor chat de către IA';

  @override
  String get gdprDocs => 'Analiza documentelor încărcate';

  @override
  String get gdprStorage => 'Stocare criptată a datelor cazurilor';

  @override
  String get gdprDelete => 'Dreptul de a șterge datele în orice moment';

  @override
  String get gdprFooter =>
      'Datele dvs. sunt criptate și nu sunt partajate cu terți. Puteți retrage consimțământul din Setări.';

  @override
  String get gdprConsentAiProcessing =>
      'Sunt de acord cu prelucrarea datelor mele pentru asistență juridică IA (obligatoriu)';

  @override
  String get gdprConsentAnalytics =>
      'Sunt de acord cu analiza datelor pentru îmbunătățirea serviciului (opțional)';

  @override
  String get gdprArt9Intro =>
      'Această aplicație prelucrează date cu caracter personal din categorii speciale conform articolului 9 GDPR, inclusiv:';

  @override
  String get gdprSpecialLegalCases =>
      'Detaliile cazului dumneavoastră juridic și documentele de instanță';

  @override
  String get gdprSpecialNationality => 'Naționalitatea și statutul de imigrare';

  @override
  String get gdprConsentLegalData =>
      'Consimt la prelucrarea datelor cazului meu juridic, a naționalității și a statutului de imigrare de către IA (obligatoriu)';

  @override
  String get gdprConsentVoice =>
      'Consimt la prelucrarea înregistrărilor vocale (opțional)';

  @override
  String get gdprViewPrivacyPolicy =>
      'Vizualizați Politica de confidențialitate';

  @override
  String get legalInformation => 'Informații juridice';

  @override
  String get legalEntityName => 'Vorantis OÜ';

  @override
  String get legalRegistryCode => 'Cod de înregistrare: 17098992';

  @override
  String get legalAddress =>
      'Harju maakond, Tallinn, Kesklinna linnaosa, Tornimäe tn 5, 10145';

  @override
  String get legalEmail => 'E-mail: support@advocat.ee';

  @override
  String get legalRegistry =>
      'Înregistrată în Registrul Comercial Eston (Äriregister)';

  @override
  String get aiGeneratedDisclaimer =>
      'Generat de AI • Nu constituie consultanță juridică';

  @override
  String get decline => 'Refuză';

  @override
  String get iAgree => 'Sunt de acord';

  @override
  String get iAgreeToThe => 'Accept ';

  @override
  String get orWord => 'sau';

  @override
  String get english => 'Engleză';

  @override
  String get russian => 'Rusă';

  @override
  String get finnish => 'Finlandeză';

  @override
  String successSubscribed(String plan) {
    return 'Abonament $plan activat cu succes!';
  }

  @override
  String paymentFailed(String error) {
    return 'Plata a eșuat: $error';
  }

  @override
  String get whatToDo => 'Ce trebuie făcut';

  @override
  String get getHelp => 'Obțineți ajutor';

  @override
  String get share => 'Distribuie';

  @override
  String get didYouKnow => 'Știați că?';

  @override
  String get mustKnow => 'Trebuie să știți';

  @override
  String get goodToKnow => 'Bine de știut';

  @override
  String get sentFromAdvocat => 'Trimis din aplicația Advocat';

  @override
  String get policeActionStayCalm =>
      'Rămâneți calm și țineți mâinile la vedere';

  @override
  String get policeActionAskWhy => 'Întrebați agentul de ce ați fost oprit';

  @override
  String get policeActionProvideName => 'Furnizați numele și data nașterii';

  @override
  String get policeActionWantLawyer =>
      'Declarați clar: „Vreau un avocat înainte de orice întrebare”';

  @override
  String get policeActionAskInterpreter =>
      'Solicitați un interpret dacă este necesar';

  @override
  String get policeActionNoteBadge =>
      'Notați numele și numărul de insignă al agentului';

  @override
  String get policeFactMustTellReason =>
      'În Finlanda, poliția trebuie să vă spună motivul opririi. Dacă nu o fac, puteți întreba — și sunt obligați legal să explice.';

  @override
  String get policeFactCanRecord =>
      'Puteți înregistra interacțiunile cu poliția în locuri publice în Finlanda. Acest lucru este protejat de libertatea de exprimare.';

  @override
  String get contactFinnishLegalAid => 'Asistență juridică finlandeză';

  @override
  String get contactNonDiscriminationOmbudsman =>
      'Ombudsmanul pentru nediscriminare';

  @override
  String get deportationDeadlineAppeal =>
      'Contestație la Tribunalul Administrativ — de obicei 30 de zile de la notificare';

  @override
  String get deportationDeadlineLegalAid =>
      'Solicitați asistență juridică — faceți acest lucru IMEDIAT';

  @override
  String get deportationFactStayDuringAppeal =>
      'În Finlanda, aveți de obicei dreptul de a rămâne în țară în timp ce contestația dvs. este procesată. Deportarea nu poate fi executată în timpul unei contestații active în majoritatea cazurilor.';

  @override
  String get contactRefugeeAdviceCentre =>
      'Centrul finlandez de consiliere pentru refugiați';

  @override
  String get contactAdminCourtHelsinki => 'Tribunalul Administrativ Helsinki';

  @override
  String get workplaceActionKeepContract =>
      'Păstrați copii ale contractului de muncă';

  @override
  String get workplaceActionTrackHours => 'Urmăriți independent orele de lucru';

  @override
  String get workplaceActionReportUnsafe =>
      'Raportați condițiile nesigure autorității de protecție a muncii';

  @override
  String get workplaceActionJoinUnion =>
      'Alăturați-vă unui sindicat pentru protecție';

  @override
  String get workplaceActionContactAuthority =>
      'Contactați Autoritatea de Securitate Ocupațională dacă este necesar';

  @override
  String get workplaceFactCollectiveWage =>
      'În Finlanda, contractele colective stabilesc salariile minime pe industrie — nu există un salariu minim național unic. Angajatorul dvs. trebuie să respecte contractul colectiv al domeniului dvs.';

  @override
  String get workplaceFactOralContract =>
      'Chiar și fără un contract scris, aveți drepturi depline ca angajat în Finlanda. Un acord verbal este la fel de obligatoriu din punct de vedere legal.';

  @override
  String get contactOccupationalSafety =>
      'Autoritatea de Securitate Ocupațională';

  @override
  String get contactTradeUnionSAK => 'Consiliere sindicală (SAK)';

  @override
  String get tenantActionWrittenAgreement =>
      'Aveți întotdeauna un contract de închiriere scris';

  @override
  String get tenantActionDocumentCondition =>
      'Documentați starea apartamentului la mutare (fotografii)';

  @override
  String get tenantActionReportMaintenance =>
      'Raportați problemele de întreținere în scris';

  @override
  String get tenantActionNoIllegalEviction =>
      'Nu acceptați niciodată o evacuare ilegală — instanțele trebuie să decidă';

  @override
  String get tenantActionContactAdvisory =>
      'Contactați serviciile de consiliere pentru chiriași în caz de dispute';

  @override
  String get tenantFactNoEvictionWithoutCourt =>
      'Un proprietar în Finlanda nu vă poate evacua fără o hotărâre judecătorească, chiar dacă contractul a expirat. Schimbarea încuietorilor sau întreruperea utilităților este ilegală.';

  @override
  String get contactTenantsAssociation => 'Asociația finlandeză a chiriașilor';

  @override
  String get contactConsumerDisputesBoard => 'Comisia pentru litigii de consum';

  @override
  String get detentionActionAskDecision =>
      'Cereți imediat decizia scrisă de detenție';

  @override
  String get detentionActionRequestLawyer =>
      'Solicitați să contactați un avocat';

  @override
  String get detentionActionContactEmbassy =>
      'Contactați ambasada sau consulatul dvs.';

  @override
  String get detentionActionAskMedical =>
      'Solicitați asistență medicală dacă este necesar';

  @override
  String get detentionActionRequestInterpreter =>
      'Solicitați un interpret pentru toate procedurile';

  @override
  String get detentionDeadlineCourtReview =>
      'Judecătoria trebuie să revizuiască detenția în 4 zile';

  @override
  String get detentionDeadlineContinuation =>
      'Instanța revizuiește continuarea la fiecare 2 săptămâni';

  @override
  String get detentionFactCourtReview =>
      'Detenția pentru imigrare în Finlanda trebuie revizuită de o judecătorie în 4 zile. Dacă nu se face, detenția devine ilegală.';

  @override
  String get contactParliamentaryOmbudsman => 'Ombudsmanul Parlamentar';

  @override
  String get discriminationActionWriteDown =>
      'Scrieți exact ce s-a întâmplat (data, ora, locul)';

  @override
  String get discriminationActionSaveEvidence =>
      'Salvați dovezile: mesaje, emailuri, martori';

  @override
  String get discriminationActionFileComplaint =>
      'Depuneți o plângere la Ombudsmanul pentru nediscriminare';

  @override
  String get discriminationActionContactLegalAid =>
      'Contactați un birou de asistență juridică pentru consiliere gratuită';

  @override
  String get discriminationActionReportPolice =>
      'Raportați la poliție dacă au fost implicate amenințări sau agresiune';

  @override
  String get discriminationFactNonDiscriminationAct =>
      'Legea finlandeză privind nediscriminarea acoperă discriminarea bazată pe vârstă, origine, naționalitate, limbă, religie, sănătate, dizabilitate, orientare sexuală și alte caracteristici personale.';

  @override
  String get contactVictimSupportRIKU =>
      'Sprijin pentru victime Finlanda (RIKU)';

  @override
  String get domesticViolence => 'Violență domestică';

  @override
  String get domesticViolenceDesc =>
      'Drepturile victimei, ajutor de urgență, ordine de restricție';

  @override
  String get rightCallEmergency =>
      'Aveți dreptul să sunați la 112 în orice urgență — poliție, ambulanță, pompieri';

  @override
  String get rightVictimProtection =>
      'În calitate de victimă, aveți dreptul la protecție, sprijin și informații despre cazul dumneavoastră';

  @override
  String get rightRestrainingOrder =>
      'Puteți solicita un ordin de restricție (lähestymiskielto) pentru a ține agresorul la distanță';

  @override
  String get rightVictimInterpreter =>
      'Aveți dreptul la un interpret pe parcursul tuturor procedurilor judiciare';

  @override
  String get rightMedicalHelp =>
      'Aveți dreptul la tratament medical imediat și la documentarea leziunilor';

  @override
  String get rightShelter =>
      'Aveți dreptul la adăpost de urgență — contactați un adăpost sau serviciile sociale';

  @override
  String get mustReportDanger =>
      'Dacă cineva se află în pericol imediat, sunați imediat la 112';

  @override
  String get mustDocumentInjuries =>
      'Documentați toate leziunile — fotografii, dosare medicale, note scrise';

  @override
  String get domesticActionCallEmergency =>
      'Sunați la 112 dacă vă aflați în pericol imediat';

  @override
  String get domesticActionGoToSafe =>
      'Mergeți într-un loc sigur — adăpost, prieten, loc public';

  @override
  String get domesticActionDocumentEverything =>
      'Documentați leziunile: faceți fotografii, obțineți dosare medicale';

  @override
  String get domesticActionFilePoliceReport =>
      'Depuneți o plângere la poliție — puteți face acest lucru și mai târziu';

  @override
  String get domesticActionContactShelter =>
      'Contactați un adăpost sau o linie de criză';

  @override
  String get domesticActionApplyRestraining =>
      'Solicitați un ordin de restricție prin poliție sau instanță';

  @override
  String get domesticFactRestrainingOrder =>
      'În Finlanda, un ordin de restricție (lähestymiskielto) poate fi emis chiar și fără un dosar penal. Acesta interzice persoanei să vă contacteze sau să se apropie de dumneavoastră.';

  @override
  String get domesticFactVictimDirective =>
      'Conform Directivei UE privind victimele 2012/29/UE, aveți dreptul de a fi tratat cu respect, de a primi informații într-o limbă pe care o înțelegeți și de a accesa servicii de sprijin pentru victime — indiferent de statutul dumneavoastră de rezidență.';

  @override
  String get domesticDeadlinePoliceReport =>
      'Depunerea plângerii la poliție — fără termen strict, dar mai devreme este mai bine pentru probe';

  @override
  String get domesticDeadlineRestraining =>
      'Ordinul de restricție — poate fi solicitat în orice moment';

  @override
  String get contactEmergency => 'Număr de urgență';

  @override
  String get contactShelter => 'Linie de asistență Turvakoti (Adăpost)';

  @override
  String get contactCrisisHelpline => 'Linie de criză (Kriisipuhelin)';

  @override
  String get contactNollaLinja =>
      'Nollalinja — Linie de asistență pentru violența împotriva femeilor';

  @override
  String get inheritance => 'Moștenire';

  @override
  String get inheritanceDesc =>
      'Testamente, moștenire, drepturile moștenitorilor, rezerva succesorală, procedura succesorală';

  @override
  String get rightInheritanceForced =>
      'Moștenitorii rezervatari (copii, soț/soție) au dreptul la o cotă rezervată indiferent de conținutul testamentului';

  @override
  String get rightInheritanceWill =>
      'Aveți dreptul de a întocmi un testament pentru a dispune de bunurile dumneavoastră — testamentele autentificate notarial au cea mai mare forță juridică';

  @override
  String get rightInheritanceRenounce =>
      'Puteți renunța la moștenire în termen de 3 luni de la aflarea existenței acesteia';

  @override
  String get rightInheritanceInfo =>
      'Aveți dreptul de a obține informații despre patrimoniul succesoral de la bănci și registre';

  @override
  String get rightInheritanceDispute =>
      'Puteți contesta un testament nedrept în instanță, în termenul legal de prescripție';

  @override
  String get mustFileInheritance =>
      'Depuneți cererea pentru procedura succesorală la un notar într-un termen rezonabil';

  @override
  String get mustNotifyHeirs =>
      'Toți moștenitorii cunoscuți trebuie notificați cu privire la procedura succesorală';

  @override
  String get inheritanceActionGatherDocs =>
      'Adunați toate documentele: certificatul de deces, testamentul, actele de proprietate, extrasele bancare';

  @override
  String get inheritanceActionContactNotary =>
      'Contactați un notar pentru a deschide procedura succesorală';

  @override
  String get inheritanceActionCheckDebts =>
      'Verificați dacă succesiunea are datorii înainte de a accepta moștenirea';

  @override
  String get inheritanceActionFileCourt =>
      'Dacă testamentul este contestat, depuneți o acțiune în instanță';

  @override
  String get inheritanceDeadlineRenounce =>
      '3 luni pentru a renunța la moștenire de la data aflării existenței acesteia';

  @override
  String get inheritanceDeadlineDispute =>
      'Termenul de prescripție pentru contestarea unui testament: variază în funcție de temei';

  @override
  String get inheritanceFactForced =>
      'În Estonia, descendenții și soțul/soția au dreptul la o cotă rezervată (1/2 din cota legală), chiar dacă sunt excluși din testament';

  @override
  String get inheritanceFactNotary =>
      'Toate procedurile succesorale în Estonia trebuie să treacă printr-un notar — acest pas nu poate fi omis';

  @override
  String get consumerProtection => 'Protecția consumatorilor';

  @override
  String get consumerProtectionDesc =>
      'Fraudă, produse defecte, returnări, vânzători înșelători';

  @override
  String get rightReturnOnline =>
      'Aveți 14 zile pentru a anula achizițiile online fără motiv (dreptul de retragere al UE)';

  @override
  String get rightDefectiveProduct =>
      'Dacă un produs este defect, aveți dreptul la reparare, înlocuire sau rambursare';

  @override
  String get rightClearPricing =>
      'Vânzătorii trebuie să afișeze prețuri clare, inclusiv toate taxele — costurile ascunse sunt ilegale';

  @override
  String get rightComplainBoard =>
      'Puteți depune o plângere gratuită la Comisia pentru litigiile consumatorilor';

  @override
  String get rightProtectionFraud =>
      'Sunteți protejat împotriva practicilor comerciale neloiale și a fraudei';

  @override
  String get mustKeepReceipts =>
      'Păstrați toate chitanțele, contractele și comunicările cu vânzătorii';

  @override
  String get mustActTimely =>
      'Raportați defectele vânzătorului într-un timp rezonabil după descoperire';

  @override
  String get consumerActionKeepEvidence =>
      'Păstrați chitanțele, capturile de ecran, e-mailurile și toate dovezile de achiziție';

  @override
  String get consumerActionContactSeller =>
      'Contactați mai întâi vânzătorul — explicați problema în scris';

  @override
  String get consumerActionFileComplaint =>
      'Depuneți o plângere la Comisia pentru litigiile consumatorilor (kuluttajariitalautakunta)';

  @override
  String get consumerActionContactAuthority =>
      'Contactați Serviciile de consiliere a consumatorilor pentru ajutor gratuit';

  @override
  String get consumerActionReportFraud =>
      'Raportați frauda la poliție și la Ombudsmanul consumatorilor';

  @override
  String get consumerFactWithdrawal =>
      'Conform Directivei UE privind drepturile consumatorilor 2011/83/UE, aveți 14 zile pentru a vă retrage din orice achiziție online sau la distanță — fără a fi nevoie de justificare. Vânzătorul trebuie să vă ramburseze în termen de 14 zile.';

  @override
  String get consumerFactWarranty =>
      'În Finlanda, vânzătorul este responsabil pentru defectele produsului pentru o perioadă rezonabilă (adesea 2+ ani). Aceasta este separată de orice garanție a producătorului.';

  @override
  String get consumerDeadlineWithdrawal =>
      'Retragerea din achiziția online — 14 zile de la livrare';

  @override
  String get consumerDeadlineDefect =>
      'Raportarea defectului către vânzător — în termen de 2 luni de la descoperire (recomandat)';

  @override
  String get contactConsumerAdvisory =>
      'Servicii de consiliere a consumatorilor';

  @override
  String get contactConsumerOmbudsman =>
      'Ombudsmanul consumatorilor (Kuluttaja-asiamies)';

  @override
  String get contactConsumerDisputesBoardDirect =>
      'Comisia pentru litigiile consumatorilor';

  @override
  String get caseTypeStepLabel => 'Tipul cazului';

  @override
  String get detailsStepLabel => 'Detalii';

  @override
  String get documentsStepLabel => 'Documente';

  @override
  String get whatTypeOfCase => 'Ce tip de caz este acesta?';

  @override
  String get selectCategoryDescription =>
      'Selectați categoria care descrie cel mai bine situația dumneavoastră.';

  @override
  String get tellUsAboutCase => 'Spuneți-ne despre cazul dumneavoastră';

  @override
  String get aiHelpsUnderstand =>
      'Aceste informații ajută AI-ul nostru să înțeleagă mai bine situația dumneavoastră.';

  @override
  String get caseTitleHint => 'de ex., Contestație permis de ședere 2026';

  @override
  String get countryJurisdiction => 'Țară / Jurisdicție';

  @override
  String get selectCountryHint => 'Selectați o țară';

  @override
  String get referenceNumberHint => 'de ex., UMA/12345/2026';

  @override
  String get descriptionOptional => 'Descriere (opțional)';

  @override
  String get descriptionHint =>
      'Descrieți pe scurt situația dumneavoastră. Ce s-a întâmplat? Ce decizie a fost luată?';

  @override
  String get uploadFirstDocument => 'Încărcați primul document';

  @override
  String get uploadDocumentDescription =>
      'Încărcați scrisoarea de decizie sau orice document relevant. Puteți sări peste acest pas și adăuga documente mai târziu.';

  @override
  String get tapToUploadFile => 'Atingeți pentru a încărca un fișier';

  @override
  String get fileSizeLimit => 'PDF, JPG, PNG până la 25 MB';

  @override
  String get addDocumentsLaterHint =>
      'Puteți adăuga oricând documente mai târziu din ecranul de detalii al cazului.';

  @override
  String get callAI => 'Apelați AI';

  @override
  String get comingSoon => 'În curând';

  @override
  String get encrypted => 'Criptat';

  @override
  String get typing => 'Scrie…';

  @override
  String get online => 'Online';

  @override
  String get chatWelcomeSubtitle =>
      'Voi analiza situația, voi verifica documentele, voi identifica erorile și voi sugera ce trebuie făcut.';

  @override
  String get tapMicrophoneToSpeak => 'Atingeți microfonul pentru a vorbi';

  @override
  String get categoryEssential => 'Esențial';

  @override
  String get categoryPolice => 'Poliție';

  @override
  String get categoryWork => 'Muncă';

  @override
  String get categoryHousing => 'Locuință';

  @override
  String get categoryConsumer => 'Consumator';

  @override
  String rightsInsideCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count drepturi înăuntru',
      one: '1 drept înăuntru',
      zero: 'niciun drept înăuntru',
    );
    return '$_temp0';
  }

  @override
  String get freeAidThreshold => 'Prag pentru asistență gratuită';

  @override
  String get partialAidThreshold => 'Prag pentru asistență parțială';

  @override
  String get assetLimit => 'Limita de active';

  @override
  String get whereToApplyLabel => 'Unde se depune cererea';

  @override
  String get phoneLabel => 'Telefon';

  @override
  String get websiteLabel => 'Website';

  @override
  String get disclaimerCollapsed => 'Doar îndrumare AI';

  @override
  String get disclaimerExpanded =>
      'Asistent AI — nu constituie consultanță juridică. Verificați întotdeauna cu un avocat calificat.';

  @override
  String get chatDisclaimerBanner =>
      'Asistentul AI oferă informații juridice, nu consultanță juridică. Consultați întotdeauna un avocat calificat.';

  @override
  String get chatDisclaimerSubtitle =>
      'Asistent IA · nu este consultanță juridică';

  @override
  String get chatDisclaimerBannerFull =>
      'Advocat este un asistent IA de informare juridică, nu un avocat. Informațiile de aici nu creează o relație avocat-client, nu constituie consultanță juridică și pot conține erori. Pentru consultanță juridică obligatorie, consultați un avocat licențiat în jurisdicția dumneavoastră. Nu vă reprezentăm.';

  @override
  String get chatDisclaimerFooter =>
      'Generat de IA. Verificați cu un avocat licențiat.';

  @override
  String get chatDisclaimerGotIt => 'Am înțeles';

  @override
  String get categoryChildren => 'Copii';

  @override
  String get categoryDigital => 'Digital';

  @override
  String get childrenRights => 'Drepturile copilului și pensia alimentară';

  @override
  String get childrenRightsDesc =>
      'Pensie de întreținere, pensie alimentară, protecție, garanții de stat';

  @override
  String get cyberbullying => 'Hărțuire cibernetică și hărțuire online';

  @override
  String get cyberbullyingDesc =>
      'Amenințări, încălcări ale confidențialității, defăimare online';

  @override
  String get rightChildSupport =>
      'Ambii părinți sunt obligați prin lege să își susțină financiar copilul (Perekonnaseadus § 100–102)';

  @override
  String get rightMinimumAlimony =>
      'Pensia minimă de întreținere a copilului în Estonia: suma de bază (295,86 €) + 3% din salariul brut mediu al anului precedent (PKS § 101). De la 01.04.2026 — 318,62 €/lună per copil. Actualizată anual la 1 aprilie. Calculator: alimendid.ee';

  @override
  String get rightCourtAlimony =>
      'Puteți solicita pensie alimentară prin tribunalul județean (maakohus) — nu este necesar avocat pentru pretenții de până la 6.400 €';

  @override
  String get rightBailiffEnforcement =>
      'Dacă părintele refuză să plătească, un executor judecătoresc (kohtutäitur) poate pune în aplicare hotărârea instanței, inclusiv prin poprire pe salariu';

  @override
  String get rightStateAlimonyGuarantee =>
      'Dacă părintele nu plătește, statul oferă elatisabi (indemnizație de întreținere) prin Sotsiaalkindlustusamet — până la 100 €/lună per copil';

  @override
  String get rightChildEducation =>
      'Fiecare copil are dreptul la educație, asistență medicală și protecție împotriva abuzurilor (Lastekaitseseadus § 4–5)';

  @override
  String get rightChildContact =>
      'Un copil are dreptul de a menține contactul cu ambii părinți, cu excepția cazului în care instanța decide altfel (PKS § 143)';

  @override
  String get mustFileCourtClaim =>
      'Pentru a primi pensie alimentară, trebuie să depuneți o cerere la instanță sau să conveniți suma în scris';

  @override
  String get mustNotifyAddressChange =>
      'Notificați Sotsiaalkindlustusamet cu privire la schimbările de adresă dacă primiți elatisabi';

  @override
  String get childrenActionGatherDocs =>
      'Adunați certificatul de naștere al copilului, actul dumneavoastră de identitate și dovada cheltuielilor';

  @override
  String get childrenActionFileCourtClaim =>
      'Depuneți o cerere de pensie alimentară la tribunalul județean (maakohus) — se poate face online prin e-toimik';

  @override
  String get childrenActionApplyElatisabi =>
      'Solicitați garanția de stat pentru pensia alimentară (elatisabi) la Sotsiaalkindlustusamet dacă părintele nu plătește';

  @override
  String get childrenActionContactBailiff =>
      'Contactați un executor judecătoresc (kohtutäitur) pentru a pune în aplicare hotărârea instanței';

  @override
  String get childrenActionCallLasteabi =>
      'Sunați la Lasteabi 116 111 pentru linia de asistență pentru copii — gratuit, 24/7';

  @override
  String get childrenDeadlineElatisabi =>
      'Solicitarea elatisabi — după hotărârea instanței, fără termen strict, dar procesul durează';

  @override
  String get childrenDeadlineCourt =>
      'Pensia alimentară poate fi solicitată retroactiv pentru până la 1 an înainte de depunerea cererii la instanță';

  @override
  String get childrenFactMinimum =>
      'De la 01.04.2026, pensia minimă de întreținere a copilului este de 318,62 €/lună per copil. Formula: suma de bază (295,86 €) + 3% din salariul brut mediu al anului precedent. Actualizată anual la 1 aprilie. Un părinte nu poate conveni să plătească mai puțin. Calculator: alimendid.ee';

  @override
  String get childrenFactElatisabi =>
      'Garanția de stat pentru pensia alimentară din Estonia (elatisabi) a fost introdusă în 2017 pentru a proteja copiii atunci când un părinte refuză să plătească. Statul plătește și apoi recuperează suma de la părintele debitor.';

  @override
  String get rightReportCybercrime =>
      'Aveți dreptul să raportați amenințările online, hărțuirea și furtul de identitate la poliție (Karistusseadustik § 120, § 157¹)';

  @override
  String get rightContentRemoval =>
      'Puteți solicita eliminarea conținutului defăimător sau privat de pe platforme și puteți cere retragerea acestuia conform GDPR';

  @override
  String get rightMoralDamageCompensation =>
      'Puteți solicita despăgubiri pentru prejudiciul moral cauzat de hărțuirea cibernetică (Võlaõigusseadus § 1043–1055)';

  @override
  String get rightPrivacyProtection =>
      'Viața dumneavoastră privată este protejată — partajarea neautorizată a fotografiilor, mesajelor sau datelor dumneavoastră cu caracter personal este ilegală (KarS § 157)';

  @override
  String get rightDataProtection =>
      'Raportați încălcările protecției datelor (utilizarea neautorizată a datelor dumneavoastră) la Andmekaitse Inspektsioon';

  @override
  String get rightDefamationAction =>
      'Defăimarea (laimamine) este o faptă civilă — puteți da în judecată pentru daune și puteți cere o retractare publică (KarS § 247 (abrogat), VÕS § 1047)';

  @override
  String get mustCollectEvidence =>
      'Colectați și păstrați toate probele — capturi de ecran, linkuri, date și informații despre martori';

  @override
  String get mustNotRetaliate =>
      'Nu vă răzbunați și nu vă angajați în contra-hărțuire — acest lucru vă poate slăbi cazul';

  @override
  String get cyberActionScreenshots =>
      'Faceți capturi de ecran ale întregii hărțuiri — salvați URL-uri, date, nume de utilizator și conținut';

  @override
  String get cyberActionReportPolice =>
      'Depuneți o plângere la poliție la cea mai apropiată secție sau online la politsei.ee';

  @override
  String get cyberActionReportPlatform =>
      'Raportați conținutul către platforma de socializare pentru eliminare';

  @override
  String get cyberActionContactDPA =>
      'Contactați Andmekaitse Inspektsioon dacă datele dumneavoastră cu caracter personal au fost utilizate abuziv';

  @override
  String get cyberActionConsultLawyer =>
      'Consultați un avocat cu privire la daunele civile — asistența juridică gratuită este disponibilă prin Riigi Õigusabi';

  @override
  String get cyberDeadlineCriminal =>
      'Plângerea penală — fără termen strict, dar raportați prompt pentru cele mai bune rezultate';

  @override
  String get cyberDeadlineCivil =>
      'Acțiunea civilă pentru daune — până la 3 ani de la momentul în care ați aflat despre încălcare (TsÜS § 150)';

  @override
  String get cyberFactPrivacy =>
      'În Estonia, partajarea neautorizată a imaginilor intime ale unei persoane poate duce la până la 3 ani de închisoare conform Karistusseadustik § 157¹ (încălcarea confidențialității).';

  @override
  String get cyberFactGDPR =>
      'Conform GDPR, aveți „dreptul de a fi uitat” — platformele trebuie să vă șteargă datele cu caracter personal la cerere dacă nu există un temei juridic pentru a le păstra.';

  @override
  String get guestUser => 'Oaspete';

  @override
  String get howToUse => 'Cum se utilizeaza?';

  @override
  String get tutorialStep1Title => 'Asistent juridic IA';

  @override
  String get tutorialStep1Desc =>
      'Puneti orice intrebare juridica si primiti raspunsuri instantanee bazate pe legislatia estoniana.';

  @override
  String get tutorialStep2Title => 'Cunoaste-ti drepturile';

  @override
  String get tutorialStep2Desc =>
      'Navigati prin informatii juridice pe teme — munca, locuinta, drepturile consumatorului si altele.';

  @override
  String get tutorialStep3Title => 'Scaneaza documente';

  @override
  String get tutorialStep3Desc =>
      'Fotografiati documente juridice pentru analiza IA si stocare sigura.';

  @override
  String get tutorialStep4Title => 'Sa incepem!';

  @override
  String get tutorialStep4Desc =>
      'Explorati aplicatia si protejati-va drepturile. Toate datele raman private pe dispozitivul dvs.';

  @override
  String get advocatProTitle => 'Advocat Pro';

  @override
  String get advocatProSubtitle => 'Deblocați funcțiile premium';

  @override
  String get voiceDisclaimer =>
      'Asistentul vocal funcționează momentan doar pe desktop (browser Chrome). Suport mobil în curând.';

  @override
  String get recommended => 'Recomandat';

  @override
  String get pleaseLogIn => 'Vă rugăm să vă autentificați';

  @override
  String get subscriptionNotFound => 'Abonamentul nu a fost găsit';

  @override
  String errorWithMessage(String message) {
    return 'Eroare: $message';
  }

  @override
  String get redirectingToPayment => 'Redirecționare către pagina de plată…';

  @override
  String cheaperAnnually(String amount) {
    return '€$amount/lună mai ieftin cu abonamentul anual';
  }

  @override
  String get navigatingTo => 'Se deschide';

  @override
  String get stayInChat => 'Rămâi în chat';

  @override
  String get backToChat => 'Înapoi la chat';

  @override
  String get upgradeBannerTitle =>
      'Faceți upgrade pentru consultații nelimitate';

  @override
  String get upgradeBannerCta => 'Upgrade';

  @override
  String get paymentSuccessTitle => 'Plată reușită';

  @override
  String get paymentSuccessBody => 'Abonamentul dumneavoastră este acum activ.';

  @override
  String get commonOk => 'OK';

  @override
  String get feedbackThumbsUpLabel => 'Util';

  @override
  String get feedbackThumbsDownLabel => 'Inutil';

  @override
  String get feedbackCommentPrompt => 'Ce a fost greșit?';

  @override
  String get feedbackSend => 'Trimite';

  @override
  String get feedbackCancel => 'Anulează';

  @override
  String get reasoningPillIdle => 'Se gândește…';

  @override
  String get reasoningPillSearchingLaw => 'Se caută în legislația estonă…';

  @override
  String get reasoningPillSearchingWeb => 'Se caută pe web…';

  @override
  String get reasoningPillCheckingCompany =>
      'Se verifică registrul societăților…';

  @override
  String get reasoningPillCheckingVehicle =>
      'Se verifică registrul vehiculelor…';

  @override
  String get reasoningPillReadingDocument =>
      'Se citește documentul dumneavoastră…';

  @override
  String get reasoningPillDrafting => 'Se redactează documentul…';

  @override
  String get reasoningPillPreparingEmail => 'Se pregătește e-mailul…';

  @override
  String get reasoningPillFindingLawyer => 'Se caută avocați…';

  @override
  String get reasoningPillThinking => 'Se analizează cazul dumneavoastră…';

  @override
  String get reasoningPillFinalising => 'Se compune răspunsul dumneavoastră…';

  @override
  String reasoningCollapsedFormat(int sec, int sources) {
    return 'A raționat ${sec}s · $sources surse';
  }

  @override
  String get reasoningExpandHint => 'atingeți pentru a vedea pașii';

  @override
  String get caseFileTitle => 'Dosarul cazului';

  @override
  String get caseFileTimeline => 'Cronologie';

  @override
  String get caseFileParties => 'Părți';

  @override
  String get caseFileDeadlines => 'Termene';

  @override
  String get caseFileExportPdf => 'Descarcă dosarul (PDF)';

  @override
  String get caseFileEmpty =>
      'Discutați cu IA despre cazul dumneavoastră — cronologia se va construi singură.';

  @override
  String get caseFileDisclaimer =>
      'Acest dosar este extras automat din conversația dumneavoastră. Nu constituie consultanță juridică.';

  @override
  String get caseFileTabLabel => 'Caz';

  @override
  String get refresh => 'Reîmprospătează';

  @override
  String get demoLimitReached =>
      'Limita demo a fost atinsă. Înregistrați-vă gratuit pentru a continua.';

  @override
  String get demoLimitSignUpCta => 'Înregistrare';

  @override
  String freeQuotaExhausted(int count) {
    return 'Ați folosit toate cele $count mesaje gratuite din această lună.';
  }

  @override
  String get upgradeForUnlimited => 'Treceți la Pro pentru acces nelimitat';

  @override
  String get upgradeCta => 'Upgrade';

  @override
  String get rateLimitTryAgain =>
      'Trimiteți prea repede. Încercați din nou peste câteva secunde.';

  @override
  String get quickProfilePrompt =>
      'Pentru a vă putea ajuta mai precis, care este statutul dumneavoastră juridic: sunteți cetățean eston, cetățean UE dintr-o altă țară sau aveți un permis de ședere?';

  @override
  String get quickProfileChipEstonianCitizen => 'Cetățean eston';

  @override
  String get quickProfileChipEuCitizen => 'Cetățean UE (altă țară)';

  @override
  String get quickProfileChipResidencePermit => 'Permis de ședere';

  @override
  String get quickProfileSkipBtn => 'Omite';

  @override
  String get quickProfileSavedAck =>
      'Am înțeles. Acum, care este întrebarea dumneavoastră?';

  @override
  String get caseTitleLabel => 'Titlul cazului';

  @override
  String get jurisdictionLabel => 'Jurisdicție';

  @override
  String get caseTypeLabel => 'Tipul cazului';

  @override
  String get caseLanguageLabel => 'Limbă';

  @override
  String get caseNumbersSection => 'Numerele cazului';

  @override
  String get partiesSection => 'Părți';

  @override
  String get authoritiesSection => 'Autorități';

  @override
  String get timelineSection => 'Cronologie';

  @override
  String get openQuestionsSection => 'Întrebări deschise';

  @override
  String get nextActionsSection => 'Acțiuni următoare';

  @override
  String get summarySection => 'Rezumat';

  @override
  String get addRow => 'Adaugă rând';

  @override
  String get removeRow => 'Elimină';

  @override
  String get archiveCase => 'Arhivează cazul';

  @override
  String get closeCase => 'Închide cazul';

  @override
  String get continueChatAboutCase => 'Continuă conversația despre acest caz';

  @override
  String get linkChatToCase => 'Asociază cu cazul';

  @override
  String get clearActiveCase => 'Șterge cazul activ';

  @override
  String get caseSavedAck => 'Cazul a fost salvat';

  @override
  String get caseArchivedAck => 'Cazul a fost arhivat';

  @override
  String get intakeStep1Title => 'Unde este cazul?';

  @override
  String get intakeStep1Subtitle =>
      'Țara și autoritatea cu care aveți de-a face.';

  @override
  String get intakeJurisdictionLabel => 'Țară / jurisdicție';

  @override
  String get intakeAuthorityLabel => 'Tipul autorității';

  @override
  String get intakeAuthorityNameLabel => 'Numele autorității (opțional)';

  @override
  String get intakeAuthorityPolice => 'Poliție';

  @override
  String get intakeAuthorityCourt => 'Instanță';

  @override
  String get intakeAuthoritySocial => 'Servicii sociale';

  @override
  String get intakeAuthorityEmployer => 'Angajator';

  @override
  String get intakeAuthorityLandlord => 'Proprietar';

  @override
  String get intakeAuthorityOpposingParty => 'Parte adversă';

  @override
  String get intakeAuthorityOther => 'Altele';

  @override
  String get intakeStep2Title => 'Ce fel de caz?';

  @override
  String get intakeStep2Subtitle =>
      'Alegeți tipul cel mai apropiat — îl puteți rafina mai târziu.';

  @override
  String get intakeCaseTypeCriminal => 'Penal';

  @override
  String get intakeCaseTypeCivil => 'Civil';

  @override
  String get intakeCaseTypeFamily => 'Familie';

  @override
  String get intakeCaseTypeAdmin => 'Administrativ';

  @override
  String get intakeCaseTypeImmigration => 'Imigrare';

  @override
  String get intakeCaseTypeLabor => 'Muncă';

  @override
  String get intakeCaseTypeConsumer => 'Consumator';

  @override
  String get intakeCaseTypeInheritance => 'Moștenire';

  @override
  String get intakeCaseTypeOther => 'Altele';

  @override
  String get intakeStep3Title => 'Cine este implicat?';

  @override
  String get intakeStep3Subtitle => 'Rolul dumneavoastră și cealaltă parte.';

  @override
  String get intakeRoleLabel => 'Rolul dumneavoastră';

  @override
  String get intakeRolePlaintiff => 'Reclamant';

  @override
  String get intakeRoleDefendant => 'Pârât';

  @override
  String get intakeRoleVictim => 'Victimă';

  @override
  String get intakeRoleAccused => 'Acuzat';

  @override
  String get intakeRoleWitness => 'Martor';

  @override
  String get intakeRoleFamily => 'Membru al familiei';

  @override
  String get intakeRoleOther => 'Altele';

  @override
  String get intakeOpposingSideLabel => 'Partea adversă (opțional)';

  @override
  String get intakeWitnessesLabel => 'Martori (opțional)';

  @override
  String get intakeAddWitness => 'Adaugă martor';

  @override
  String get intakeWitnessHint => 'Nume sau contact';

  @override
  String get intakeStep4Title => 'Numere și date';

  @override
  String get intakeStep4Subtitle =>
      'Orice aveți deja. Săriți peste ce nu aveți.';

  @override
  String get intakeCaseNumberLabel => 'Numărul cazului (opțional)';

  @override
  String get intakeIncidentDateLabel => 'Data incidentului (opțional)';

  @override
  String get intakeIncidentDatePick => 'Alege data';

  @override
  String get intakeDeadlinesLabel => 'Termene cunoscute';

  @override
  String get intakeAddDeadline => 'Adaugă termen';

  @override
  String get intakeDeadlineWhatHint => 'Ce';

  @override
  String get intakeStep5Title => 'Documente';

  @override
  String get intakeStep5Subtitle =>
      'Încărcați orice este relevant. Le vom citi.';

  @override
  String get intakeUploadDocsLabel => 'Încarcă documente';

  @override
  String get intakeSkipDocs => 'Omite — voi încărca mai târziu';

  @override
  String get intakeNextBtn => 'Înainte';

  @override
  String get intakeBackBtn => 'Înapoi';

  @override
  String get intakeFinishBtn => 'Finalizează și deschide conversația';

  @override
  String get intakeUrgentBtn => 'Urgent — întreabă acum';

  @override
  String get intakeUrgentDialogTitle => 'Deschideți conversația acum?';

  @override
  String get intakeUrgentDialogBody =>
      'Vom salva ceea ce ați introdus ca un caz în ciornă. Puteți finaliza asistentul din pagina cazului oricând.';

  @override
  String get intakeUrgentConfirm => 'Deschide conversația';

  @override
  String get intakeUrgentCancel => 'Continuă completarea';

  @override
  String get intakePreparingCase => 'Se pregătește cazul dumneavoastră…';

  @override
  String get intakeFallbackGreeting =>
      'Văd cazul dumneavoastră. Spuneți-mi ce este cel mai presant — îl voi rezolva împreună cu dumneavoastră.';

  @override
  String get intakeUrgentGreeting =>
      'Văd că este urgent. Adresați-vă întrebarea — voi completa restul pe parcurs.';

  @override
  String intakeStepIndicator(int current, int total) {
    return 'Pasul $current din $total';
  }

  @override
  String get intakeFieldRequired => 'Obligatoriu';

  @override
  String intakeUploadProgress(int done, int total) {
    return 'Se încarcă $done / $total…';
  }

  @override
  String get uplDisclaimerFooter =>
      'Advocat nu este o firmă de avocatură. Acestea sunt informații, nu consultanță juridică.';

  @override
  String get citationStatusVerifiedBadge => 'Verificată';

  @override
  String get citationStatusUnverifiedBadge => 'Neverificată';

  @override
  String get citationStatusHistoricalBadge => 'Versiune istorică';

  @override
  String get citationStatusVerifiedTooltip =>
      'Citată dintr-o sursă juridică recuperată.';

  @override
  String get citationStatusUnverifiedTooltip =>
      'IA a citat acest pasaj fără recuperarea sursei — verificați înainte de a vă baza pe el.';

  @override
  String get citationStatusHistoricalTooltip =>
      'Dispoziția citată nu mai este în vigoare.';

  @override
  String get citationOpenInRiigiTeataja => 'Deschide în Riigi Teataja';

  @override
  String get citationSnippetExpand => 'Afișează textul integral';

  @override
  String get citationSnippetCollapse => 'Afișează mai puțin';

  @override
  String get citationUnverifiedSheetNote =>
      'IA a citat acest paragraf, însă acesta nu a fost recuperat din corpusul juridic în această sesiune. Verificați referința înainte de a vă baza pe ea.';

  @override
  String get citationFooterNoneWarning => 'Nicio citare documentată';

  @override
  String citationFooterSummaryTotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count citări',
      one: '1 citare',
    );
    return '$_temp0';
  }

  @override
  String citationFooterSummaryVerified(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count verificate',
      one: '1 verificată',
    );
    return '$_temp0';
  }

  @override
  String citationFooterSummaryUnverified(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count neverificate',
      one: '1 neverificată',
    );
    return '$_temp0';
  }

  @override
  String citationFooterSummaryHistorical(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count istorice',
      one: '1 istorică',
    );
    return '$_temp0';
  }

  @override
  String get deadlineRadarTitle => 'Termene viitoare';

  @override
  String get deadlineRadarEmpty => 'Niciun termen viitor';

  @override
  String get deadlineRadarViewAll => 'Vezi toate';

  @override
  String deadlineCardDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'în $count zile',
      one: 'în 1 zi',
      zero: 'astăzi',
    );
    return '$_temp0';
  }

  @override
  String get deadlineCardTomorrow => 'mâine';

  @override
  String get deadlineCardToday => 'astăzi';

  @override
  String deadlineCardOverdue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zile întârziere',
      one: '1 zi întârziere',
    );
    return '$_temp0';
  }

  @override
  String get deadlineCardMarkComplete => 'Marchează ca finalizat';

  @override
  String get deadlineCardSnooze => 'Amână';

  @override
  String get deadlineCardSnooze3d => 'Amână 3 zile';

  @override
  String get deadlineCardSnooze7d => 'Amână 7 zile';

  @override
  String get deadlineCardSnoozeCustom => 'Alege o dată';

  @override
  String get deadlineCardEdit => 'Editează';

  @override
  String get deadlineCardDelete => 'Arhivează';

  @override
  String get deadlineCardSourceLabelPdf => 'din PDF';

  @override
  String get deadlineCardSourceLabelIntake => 'din formularul de admitere';

  @override
  String get deadlineCardSourceLabelManual => 'adăugat manual';

  @override
  String get deadlineCardSourceLabelEmail => 'din e-mail';

  @override
  String get deadlineCardSourceLabelHaikuExtract => 'extras de AI';

  @override
  String get deadlineCardSourceLabelStatutoryTemplate => 'șablon legal';

  @override
  String deadlineBannerCritical(String title, String when) {
    return 'Termen critic $title $when';
  }

  @override
  String get deadlineBannerDismiss => 'Închide';

  @override
  String get deadlineBannerOpen => 'Deschide termenul';

  @override
  String deadlineHolidayShifted(String original, String reason) {
    return 'Amânat de la $original din cauza $reason';
  }

  @override
  String get deadlinePermissionAskTitle => 'Activați remindere pentru termene?';

  @override
  String get deadlinePermissionAskBody =>
      'Vă vom notifica cu 7, 3 și 1 zi înainte de fiecare termen legal, plus în dimineața respectivă. Nu este folosit niciodată pentru marketing.';

  @override
  String get deadlinePermissionAllow => 'Permite';

  @override
  String get deadlinePermissionLater => 'Mai târziu';

  @override
  String get deadlineSettingsSection => 'Remindere pentru termene';

  @override
  String get deadlineSettingsPushChannel => 'Notificări push';

  @override
  String get deadlineSettingsEmailChannel => 'E-mail (doar critic)';

  @override
  String get deadlineSettingsInAppChannel => 'Bannere în aplicație';

  @override
  String get deadlineSettingsCriticalBypass =>
      'Reminderele critice ignoră orele de liniște';

  @override
  String get deadlineSettingsQuietHours => 'Ore de liniște';

  @override
  String deadlineSettingsQuietHoursBadge(String start, String end) {
    return 'Liniște $start–$end';
  }

  @override
  String get deadlineCaseScreenTitle => 'Termene ale cazului';

  @override
  String get deadlineAddManualCta => 'Adaugă termen';

  @override
  String get deadlineFormTitle => 'Titlu';

  @override
  String get deadlineFormDescription => 'Descriere (opțional)';

  @override
  String get deadlineFormStatuteTemplate => 'Șablon legal';

  @override
  String get deadlineFormStatuteTemplateNone => 'Niciunul (manual)';

  @override
  String get deadlineFormDeadlineAt => 'Data termenului';

  @override
  String get deadlineFormPriority => 'Prioritate';

  @override
  String get deadlineFormSave => 'Salvează';

  @override
  String get deadlineFormCancel => 'Anulează';

  @override
  String get deadlineCompletedNotePrompt => 'Adăugați o notă (opțional)';

  @override
  String get deadlineCompletedNoteSave => 'Salvează';

  @override
  String get inboxTitle => 'Inbox';

  @override
  String get inboxEmptyTitle => 'Nimic în așteptare';

  @override
  String get inboxEmptyBody =>
      'Firele de e-mail noi vor apărea aici pe măsură ce sunt triate.';

  @override
  String get inboxApproveSend => 'Aprobă și trimite';

  @override
  String get inboxEditDraft => 'Editează';

  @override
  String get inboxSnooze => 'Amână';

  @override
  String get inboxArchive => 'Arhivează';

  @override
  String get inboxFilterAll => 'Toate';

  @override
  String get inboxConfirmSendTitle => 'Trimiteți răspunsul pregătit?';

  @override
  String get inboxConfirmSendBody =>
      'Advocat va trimite răspunsul pregătit de AI prin contul dumneavoastră Gmail conectat. Puteți revizui conținutul în ecranul următor.';

  @override
  String get inboxSendButton => 'Trimite';

  @override
  String get inboxSentToast => 'Trimis.';

  @override
  String get inboxAlreadySentToast => 'Deja trimis.';

  @override
  String get inboxSendErrorToast =>
      'Răspunsul nu a putut fi trimis. Atingeți pentru a reîncerca.';

  @override
  String get inboxSnoozedToast => 'Amânat cu 24h.';

  @override
  String get inboxArchivedToast => 'Arhivat.';

  @override
  String get inboxDraftLoadError => 'Ciorna nu a putut fi încărcată.';

  @override
  String get inboxDeadlineToday => 'astăzi';

  @override
  String get inboxDeadlineTomorrow => 'mâine';

  @override
  String inboxDeadlineInDays(int days) {
    return 'în ${days}z';
  }

  @override
  String inboxDeadlineOverdue(int days) {
    return 'întârziat ${days}z';
  }

  @override
  String parallelActionsHeadline(int count) {
    return 'Consilium recomandă $count acțiuni paralele';
  }

  @override
  String get parallelActionsApproveAll => 'Aprobă tot și trimite';

  @override
  String parallelActionsApproveSelected(int count, int total) {
    return 'Aprobă $count din $total';
  }

  @override
  String parallelActionsConfirmTitle(int count) {
    return 'Trimiteți $count e-mailuri?';
  }

  @override
  String parallelActionsConfirmBody(int count) {
    return 'Advocat va expedia $count răspunsuri pregătite prin Gmail-ul dumneavoastră conectat. Fiecare este trimis independent — dacă unul eșuează, celelalte sunt trimise în continuare.';
  }

  @override
  String parallelActionsSentToast(int count) {
    return '$count trimise.';
  }

  @override
  String parallelActionsPartialFailureToast(int sent, int failed) {
    return '$sent trimise, $failed eșuate.';
  }

  @override
  String get parallelActionsKindReply => 'răspuns';

  @override
  String get parallelActionsKindNew => 'nou';

  @override
  String get parallelActionsCheckboxSelected => 'Acțiune selectată';

  @override
  String get parallelActionsCheckboxUnselected => 'Acțiune neselectată';

  @override
  String parallelActionsCitationCount(int count) {
    return '$count citări';
  }

  @override
  String parallelActionsRetryFailed(int count) {
    return 'Reîncearcă eșuate ($count)';
  }

  @override
  String get agentApprovalNeedsReviewTitle =>
      'Advocat are nevoie de aprobarea dumneavoastră';

  @override
  String get agentApprovalResolvedTitle => 'Acțiune soluționată';

  @override
  String get agentApprovalStepsLabel => 'pași';

  @override
  String get agentApprovalApproveButton => 'Aprobă și trimite';

  @override
  String get agentApprovalDeclineButton => 'Refuză';

  @override
  String get agentApprovalAttachmentsLabel => 'Atașamente';

  @override
  String get agentApprovalSentSummary => 'Trimis în numele dumneavoastră.';

  @override
  String get agentApprovalDeclinedSummary => 'Refuzat — nu s-a trimis nimic.';

  @override
  String get agentToolDraftEmailAtt => 'Trimite e-mail cu atașamente';

  @override
  String get agentToolSendEmail => 'Trimite e-mail';

  @override
  String get agentToolGeneratePdf => 'Generează PDF';

  @override
  String get agentToolApproveSend => 'Trimite răspunsul pregătit';

  @override
  String get inboxErrorTitle => 'Nu s-a putut încărca căsuța de e-mail';

  @override
  String get inboxEditDiscardTitle => 'Renunțați la modificările nesalvate?';

  @override
  String get inboxEditDiscardBody =>
      'Aveți modificări nesalvate la această ciornă. Revenirea înapoi le va elimina.';

  @override
  String get inboxEditKeepEditing => 'Continuă editarea';

  @override
  String get inboxEditDiscard => 'Renunță';

  @override
  String get workspaceTabOverview => 'Prezentare generală';

  @override
  String get workspaceTabChat => 'Chat';

  @override
  String get workspaceTabDrafts => 'Ciorne';

  @override
  String get workspaceOverviewEmpty =>
      'Adăugați documente pentru a genera un rezumat.';

  @override
  String get workspaceTimelineEmpty => 'Niciun eveniment încă.';

  @override
  String get workspaceDocumentsEmpty =>
      'Niciun document. Încărcați din Scanare.';

  @override
  String get workspaceDraftsEmpty => 'Nicio ciornă încă.';

  @override
  String get workspaceInboxEmpty => 'Niciun e-mail asociat.';

  @override
  String get plannerSettingsTitle => 'Raționament juridic în trei etape';

  @override
  String get plannerSettingsSubtitle =>
      'Planificare → răspuns → critică. Mai lent, dar mai amănunțit.';

  @override
  String get plannerSettingsProBadge => 'Pro';

  @override
  String get plannerSettingsProDescription => 'Disponibil în planul Pro';

  @override
  String get plannerTrailHeaderPlan => 'Plan';

  @override
  String get plannerTrailHeaderCritique => 'Critică';

  @override
  String get plannerTrailSubQuestions => 'Sub-întrebări';

  @override
  String get plannerTrailCounterArgs => 'Contraargumente';

  @override
  String get plannerTrailEvidenceGaps => 'Lacune în probe';

  @override
  String get plannerTrailMaterialGapTrue => 'Lacună materială detectată';

  @override
  String get plannerTrailRegeneratedBadge => 'Regenerat o dată';

  @override
  String get plannerTrailEmpty => 'niciun element';

  @override
  String get supportTitle => 'Ajutor';

  @override
  String get supportSubtitle => 'De obicei răspundem în 1-2 ore.';

  @override
  String get supportSearchPlaceholder => 'Caută în ajutor…';

  @override
  String get supportStatusAllOk => 'Toate sistemele funcționează normal';

  @override
  String get supportFaqWhatIs => 'Ce este Advocat?';

  @override
  String get supportFaqHowSubscribe => 'Cum mă abonez la Pro?';

  @override
  String get supportFaqExportData => 'Îmi pot exporta datele?';

  @override
  String get supportFaqCancelAccount => 'Anulează sau șterge contul';

  @override
  String get supportFaqTalkHuman => 'Vorbește cu o persoană';

  @override
  String get supportContactEmail => 'E-mail';

  @override
  String get supportContactTelegram => 'Telegram';

  @override
  String get supportContactWhatsapp => 'WhatsApp';

  @override
  String get supportFooterSla => 'Răspundem în 24 de ore';

  @override
  String get supportWhatsapp => 'WhatsApp';

  @override
  String get supportEmail => 'E-mail';

  @override
  String get supportInApp => 'Scrieți-ne aici';

  @override
  String get supportCategoryLabel => 'Categorie';

  @override
  String get supportCategoryBug => 'Eroare';

  @override
  String get supportCategoryPayment => 'Problemă de plată';

  @override
  String get supportCategoryQuestion => 'Întrebare';

  @override
  String get supportCategoryFeature => 'Cerere de funcționalitate';

  @override
  String get supportCategoryOther => 'Altele';

  @override
  String get supportMessagePlaceholder => 'Descrieți problema dumneavoastră...';

  @override
  String get supportEmailLabel => 'E-mail (opțional)';

  @override
  String get supportSend => 'Trimite';

  @override
  String get supportSentSuccess => 'Mesaj trimis! Vom răspunde în curând.';

  @override
  String get supportError => 'Ceva nu a mers bine. Încercați din nou.';

  @override
  String get supportErrorTooShort =>
      'Vă rugăm să scrieți cel puțin 10 caractere.';

  @override
  String get supportErrorTooLong => 'Maximum 2000 de caractere.';

  @override
  String get supportPrivacyNotice =>
      'Mesajul dumneavoastră este stocat în siguranță.';

  @override
  String get reviewThisContract => 'Verifică contractul';

  @override
  String get contractReviews => 'Verificări contracte';

  @override
  String get contractReviewsFreeFeature =>
      '1 verificare contract (probă pe viață)';

  @override
  String get contractReviewsCounselFeature => '5 verificări contracte pe lună';

  @override
  String get contractReviewsProFeature => '20 verificări contracte pe lună';

  @override
  String contractReviewsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count revizuiri de contracte rămase luna aceasta',
      one: '1 revizuire de contract rămasă luna aceasta',
      zero: 'Nicio revizuire de contract rămasă luna aceasta',
    );
    return '$_temp0';
  }

  @override
  String get contractReviewsExhausted =>
      'Nu mai sunt verificări contracte luna aceasta';

  @override
  String get contractReviewsFreeTrialLeft =>
      'Probă gratuită: 1 verificare contract';

  @override
  String get contractReviewsFreeTrialUsed =>
      'Probă gratuită folosită — actualizați';

  @override
  String get contractReviewsUpgradeTitle => 'Verificări contracte epuizate';

  @override
  String get contractReviewsUpgradeBodyFree =>
      'Ați folosit verificarea gratuită de contract. Actualizați pentru verificări lunare.';

  @override
  String contractReviewsUpgradeBodyPaid(int used, int cap) {
    return 'Ați folosit $used din $cap verificări luna aceasta. Actualizați pentru o limită lunară mai mare.';
  }

  @override
  String get contractReviewsUpgradeCounselCta =>
      'Treceți la Counsel (€19,99/lună) — 5 verificări';

  @override
  String get contractReviewsUpgradeProCta =>
      'Treceți la Pro (€29,99/lună) — 20 verificări';

  @override
  String get contractReviewsUpgradeToProShort => 'Treceți la Pro — 20/lună';

  @override
  String get notNow => 'Nu acum';

  @override
  String get referralTitle => 'Invită prieteni';

  @override
  String get referralSubtitle => 'Primește o lună gratis. Oferă o lună gratis.';

  @override
  String get referralYourLink => 'LINKUL TĂU';

  @override
  String get referralCopyLink => 'Copiază linkul';

  @override
  String get referralShare => 'Distribuie';

  @override
  String get referralLinkCopied => 'Link copiat';

  @override
  String get referralStatsInvited => 'Invitați';

  @override
  String get referralStatsConverted => 'Convertiți';

  @override
  String get referralStatsEarned => 'Luni câștigate';

  @override
  String get referralShareWhatsApp => 'Distribuie pe WhatsApp';

  @override
  String get referralShareTelegram => 'Distribuie pe Telegram';

  @override
  String get referralShareEmail => 'Distribuie prin email';

  @override
  String get referralEmailSubject =>
      'Încearcă Advocat — asistentul tău juridic AI';

  @override
  String get referralLoadError =>
      'Nu s-au putut încărca datele. Trage în jos pentru reîmprospătare.';

  @override
  String get referralRetry => 'Încearcă din nou';

  @override
  String get referralSettingsTile => 'Invită prieteni';

  @override
  String get referralAfterReviewCta =>
      'Ți-a plăcut? Invită un prieten — amândoi primiți o lună gratis.';

  @override
  String get referralAntiFraud => 'Maximum 12 recomandări reușite pe an.';

  @override
  String get referralEmpty =>
      'Încă nicio recomandare. Trimiteți linkul dumneavoastră pentru a începe să câștigați.';

  @override
  String get referralRecentActivity => 'Activitate recentă';

  @override
  String referralActivityInvited(String when) {
    return 'Invitat $when';
  }

  @override
  String referralActivityActivated(String when) {
    return 'activat $when';
  }

  @override
  String get referralActivityPending => 'neactivat încă';

  @override
  String referralStatsInvitedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count prieteni',
      one: '1 prieten',
      zero: 'încă niciun prieten',
    );
    return 'Ați invitat $_temp0';
  }

  @override
  String referralStatsConvertedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count au activat',
      one: '1 a activat',
      zero: 'încă niciunul activat',
    );
    return '$_temp0';
  }

  @override
  String referralStatsEarnedCount(int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months luni gratuite',
      one: '1 lună gratuită',
      zero: 'încă nimic',
    );
    return 'Bonusul dumneavoastră: $_temp0';
  }

  @override
  String get referralNudgeMessage =>
      'Vă place Advocat? Invitați un prieten — amândoi primiți o lună gratuită.';

  @override
  String get referralNudgeAction => 'Invită';

  @override
  String get referralLandingTitle => 'Ați fost invitat la Advocat';

  @override
  String referralLandingSubtitle(String inviterName) {
    return '$inviterName v-a invitat — revendicați prima lună gratuită.';
  }

  @override
  String get referralLandingSubtitleGeneric =>
      'Revendicați prima lună gratuită de Advocat Pro.';

  @override
  String get referralLandingCta =>
      'Activează luna gratuită și înregistrează-te';

  @override
  String get referralLandingCtaSecondary =>
      'Sau aflați mai multe despre Advocat';

  @override
  String get referralLandingFallback =>
      'Acest link a expirat — dar puteți încerca în continuare Advocat gratuit.';

  @override
  String get referralLandingBenefits =>
      '17 limbi • Legislație reală estonă, finlandeză și UE • 24/7 — fără așteptare';

  @override
  String get checkerProTagline => 'Instrumente profesionale de verificare';

  @override
  String get checkerDataSource => 'Date din registre oficiale';

  @override
  String get companyCheckerHint => 'Numele companiei sau nr. de înregistrare';

  @override
  String get companyCheckerPriceChip => '€2.99 pe verificare  •  Inclus în Pro';

  @override
  String get companyCheckerEmptyState =>
      'Introduceți numele companiei sau numărul\nde înregistrare pentru a obține un raport complet';

  @override
  String get aiMemoryTitle => 'Memoria AI';

  @override
  String get aiMemorySubtitle =>
      'Verificați și ștergeți ceea ce AI își amintește despre dvs.';

  @override
  String get bookLawyerCallTitle => 'Rezervați un apel cu un avocat';

  @override
  String get bookLawyerCallComingSoonTitle =>
      'Apeluri cu avocați reali — în curând';

  @override
  String get bookLawyerCallComingSoonBody =>
      'Pro și Premium includ apeluri de 15 minute cu un avocat partener (1/trimestru pe Pro, 2/trimestru pe Premium). Finalizăm rețeaua estonă de practicieni individuali și vă vom trimite un e-mail imediat ce rezervările se vor deschide.';

  @override
  String bookLawyerCallQuotaAvailable(int remaining, int total) {
    return 'Vă mai rămân $remaining din $total apeluri în acest trimestru.';
  }

  @override
  String get bookLawyerCallQuotaExhausted => 'Cota trimestrială epuizată.';

  @override
  String get bookLawyerCallQuotaBodyAvailable =>
      'Pachetul Pro include 1 apel/trimestru, Premium 2. Apelurile durează 15 minute, prin Google Meet.';

  @override
  String get bookLawyerCallQuotaBodyExhausted =>
      'Cota dvs. se resetează în prima zi a trimestrului următor. Aveți nevoie să discutați mai devreme? Treceți la Premium pentru un apel suplimentar.';

  @override
  String get severityCritical => 'CRITIC';

  @override
  String get severityHigh => 'RIDICAT';

  @override
  String get severityMedium => 'MEDIU';

  @override
  String get severityLow => 'SCĂZUT';

  @override
  String get deadlineRequiredFields => 'Titlul și data limită sunt obligatorii';

  @override
  String get acceptTermsRequired =>
      'Vă rugăm să acceptați Termenii și condițiile';

  @override
  String get chatLegalCouncilTooltip => 'Consiliu juridic (4 experți)';

  @override
  String get attachFileTooltip => 'Atașează fișier';

  @override
  String get sendMessage => 'Trimite mesajul';

  @override
  String get stopGenerating => 'Oprește generarea';

  @override
  String get showPassword => 'Afișează parola';

  @override
  String get hidePassword => 'Ascunde parola';

  @override
  String get decreaseDependents => 'Micșorează';

  @override
  String get increaseDependents => 'Mărește';

  @override
  String get sensitiveConsentTitle => 'Consimțământ pentru date sensibile';

  @override
  String get sensitiveConsentBody =>
      'Documentele pe care urmează să le încărcați pot conține date cu caracter personal din categorii speciale conform articolului 9 GDPR — cum ar fi dosare medicale, cazier judiciar, date biometrice sau informații despre originea dumneavoastră rasială, religia sau orientarea sexuală.\n\nPrelucrăm aceste date numai pentru a vă oferi asistență juridică IA, le stocăm criptate în contul dumneavoastră privat și nu le folosim niciodată pentru antrenarea modelelor. Vă puteți retrage consimțământul și puteți șterge datele oricând din Setări.\n\nPrin acceptare, oferiți consimțământul explicit conform articolului 9(2)(a) GDPR pentru prelucrarea datelor din categorii speciale în acest scop.';

  @override
  String get sensitiveConsentExplicitCheckbox =>
      'Ofer consimțământul explicit pentru prelucrarea datelor din categorii speciale (Art. 9(2)(a) GDPR).';

  @override
  String get sensitiveConsentRightToShareCheckbox =>
      'Confirm că am dreptul de a partaja aceste date (datele îmi aparțin sau am un temei informat/legal pentru a partaja datele unor terți).';

  @override
  String get sensitiveConsentViewCategories =>
      'Vedeți ce este considerat sensibil →';

  @override
  String get sensitiveConsentWithdrawAction =>
      'Retrage consimțământul pentru date sensibile';

  @override
  String get privacyAndData => 'CONFIDENȚIALITATE ȘI DATE';

  @override
  String get exportMyDataSubtitle =>
      'Descărcați o copie a tuturor datelor dumneavoastră cu caracter personal (GDPR Art. 15).';

  @override
  String get withdrawSensitiveConsent => 'Consimțământ pentru date sensibile';

  @override
  String get withdrawSensitiveConsentSubtitle =>
      'Gestionați sau retrageți consimțământul pentru prelucrarea datelor din categorii speciale (GDPR Art. 9(2)(a)).';

  @override
  String get dataProcessingAgreement => 'Acord de prelucrare a datelor';

  @override
  String get exportingData => 'Se exportă datele dumneavoastră…';

  @override
  String get exportComplete =>
      'Exportul datelor este gata — salvat pe dispozitivul dumneavoastră.';

  @override
  String get exportFailed =>
      'Exportul a eșuat. Vă rugăm să încercați din nou sau să contactați asistența.';

  @override
  String get quotaExhaustedTitle => 'Limita de mesaje gratuite a fost atinsă';

  @override
  String quotaExhaustedBody(int count) {
    return 'Ați folosit toate cele $count mesaje gratuite. Treceți la Advocat Counsel pentru 19,99 €/lună și beneficiați de consultații juridice IA nelimitate.';
  }

  @override
  String get quotaExhaustedLater => 'Mai târziu';

  @override
  String get quotaExhaustedUpgrade => 'Advocat Counsel — 19,99 €/lună';

  @override
  String quotaCtaMessage(int count) {
    return 'Ați folosit toate cele $count mesaje gratuite. Treceți la Advocat Counsel pentru 19,99 €/lună.';
  }

  @override
  String get quotaCtaButton => 'Obține Advocat Counsel — 19,99 €/lună';

  @override
  String get aiErrorQuota =>
      'Limita de mesaje gratuite a fost atinsă. Abonați-vă pentru a continua să folosiți IA.';

  @override
  String get aiErrorAuth =>
      'Este necesară autentificarea pentru a folosi IA. Vă rugăm să vă înregistrați sau să vă conectați.';

  @override
  String get aiErrorGeneric =>
      'Eroare temporară a IA. Vă rugăm să încercați din nou într-un minut. Dacă persistă, contactați asistența.';

  @override
  String get tooltipShareCase => 'Partajează rezumatul cazului';

  @override
  String get tooltipMuteVoice => 'Dezactivează vocea';

  @override
  String get tooltipUnmuteVoice => 'Activează vocea';

  @override
  String get tooltipAttachDoc => 'Atașează document';

  @override
  String get aiTypingHint => 'IA…';

  @override
  String get error404Title => 'Pagină negăsită';

  @override
  String error404Body(String path) {
    return 'Nu am putut găsi: $path';
  }

  @override
  String get goToHome => 'Mergi la pagina principală';

  @override
  String get emailAlreadyRegistered =>
      'Acest e-mail este deja înregistrat. Doriți să vă conectați?';

  @override
  String get actionSignIn => 'Conectare';

  @override
  String get actionUndo => 'Anulează';

  @override
  String get intakeUrgentOpened =>
      'Conversația a fost deschisă — ciorna dumneavoastră este salvată.';

  @override
  String get panicCoachmark => 'Țineți apăsat pentru ajutor de urgență.';

  @override
  String get panicTitle => 'De ce aveți nevoie chiar acum?';

  @override
  String get panicCardReadAloud => 'Citește cu voce tare ofițerului';

  @override
  String get panicCardRecord => 'Înregistrează această conversație';

  @override
  String get panicCardCall => 'Sună un avocat';

  @override
  String get panicCardAi => 'Vorbește cu Advocat acum';

  @override
  String get panicClose => 'Închide';

  @override
  String get panicBadgeV2 => 'V2';

  @override
  String get panicRecordV1Title => 'În curând în V2';

  @override
  String get panicRecordV1Body =>
      'Funcția de înregistrare este în curs de validare juridică pentru Estonia și va fi lansată în V2. Deocamdată, folosiți reportofonul încorporat al telefonului dumneavoastră.';

  @override
  String get panicCallFallbackBody =>
      'Trimiteți un e-mail la kiire@advocat.ee cu o scurtă descriere și vă vom suna înapoi.';

  @override
  String get consiliumHeader => 'Consiliu de avocați';

  @override
  String consiliumProgress(int count, int total) {
    return '$count din $total gata';
  }

  @override
  String get consiliumStarting => 'Avocații examinează cazul dvs.…';

  @override
  String get consiliumDisagreement => 'Experții nu sunt de acord';

  @override
  String get consiliumSynthesizing => 'Se sintetizează recomandarea…';

  @override
  String consiliumDone(int totalRoles) {
    return 'Consiliu finalizat · $totalRoles experți';
  }

  @override
  String get consiliumPositionPush => 'Contestă';

  @override
  String get consiliumPositionSettle => 'Conciliază';

  @override
  String get consiliumPositionInvestigate => 'Investighează';

  @override
  String get consiliumPositionOutOfScope => 'În afara competenței';

  @override
  String get consiliumConfidence => 'Încredere';

  @override
  String get consiliumKeyCitation => 'Referință-cheie';

  @override
  String get consiliumAdversarialRound => 'Rundă contradictorie';

  @override
  String get consiliumViewFullOpinion => 'Vezi avizul complet';

  @override
  String consiliumExpertsAgreed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count experți de acord',
      one: '1 expert de acord',
    );
    return '$_temp0';
  }

  @override
  String consiliumExpertsDisagree(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count experți dezacord',
      one: '1 expert dezacord',
    );
    return '$_temp0';
  }

  @override
  String get consiliumDisclaimer =>
      'Agenți IA, nu avocați umani. Verificați deciziile importante cu un avocat înscris în barou.';

  @override
  String get softCaseShellBanner =>
      'Am creat „Caz fără titlu” pentru a-l urmări. Atingeți pentru a redenumi.';

  @override
  String get softCaseShellBannerCta => 'Redenumește';

  @override
  String get draftsTab => 'Ciorne';

  @override
  String get draftingTitle => 'Studio de redactare';

  @override
  String get draftingEmpty => 'Ciornă goală';

  @override
  String get draftingPlaceholder => 'Începeți să scrieți ciorna…';

  @override
  String get draftingDraftsList => 'Ciornele mele';

  @override
  String get draftingSave => 'Salvează';

  @override
  String get draftingSaved => 'Salvat';

  @override
  String get draftingSavedJustNow => 'Salvat acum câteva clipe';

  @override
  String get draftingAiRevise => 'Revizuiește cu AI';

  @override
  String get draftingExportPdf => 'Exportă PDF';

  @override
  String get draftingExportDocx => 'Exportă DOCX';

  @override
  String get draftingExportMd => 'Exportă Markdown';

  @override
  String get draftingDeleteDraft => 'Șterge ciorna';

  @override
  String get draftingConfirmDelete => 'Ștergeți această ciornă?';

  @override
  String get draftingConfirmDeleteMessage =>
      'Această acțiune nu poate fi anulată.';

  @override
  String get draftingConfirm => 'Șterge';

  @override
  String get draftingCancel => 'Anulează';

  @override
  String draftingDraftReplyTo(String name) {
    return 'Răspunde către $name';
  }

  @override
  String get draftingUntitled => 'Fără titlu';

  @override
  String get draftingTitleHint => 'Titlu (opțional)';

  @override
  String get draftingAiReviseTitle => 'Revizuiește cu AI';

  @override
  String get draftingAiReviseSelectionLabel => 'Text selectat:';

  @override
  String get draftingAiReviseInstructionLabel => 'Instrucțiune (opțional)';

  @override
  String get draftingAiReviseInstructionHint =>
      'de ex. „faceți-l mai formal” sau „scurtați”';

  @override
  String get draftingAiReviseRunButton => 'Generează revizuire';

  @override
  String get draftingAiReviseSuggestionLabel => 'Revizuire sugerată:';

  @override
  String get draftingAiReviseChangesLabel => 'Modificări:';

  @override
  String get draftingAiReviseAccept => 'Acceptă';

  @override
  String get draftingAiReviseReject => 'Respinge';

  @override
  String get draftingFormatBold => 'Aldin';

  @override
  String get draftingFormatItalic => 'Cursiv';

  @override
  String get draftingFormatHeading => 'Titlu de secțiune';

  @override
  String get draftingFormatBullet => 'Listă cu marcatori';

  @override
  String get draftingFormatNumbered => 'Listă numerotată';

  @override
  String get draftingEmptyListMessage => 'Nu aveți încă nicio ciornă.';

  @override
  String get draftingEmptyListAction => 'Ciornă nouă';

  @override
  String get draftingExporting => 'Se exportă…';

  @override
  String get draftingExportFailed => 'Exportul a eșuat';

  @override
  String get draftingSaveFailed => 'Salvarea a eșuat';

  @override
  String get draftingNewDraft => 'Ciornă nouă';

  @override
  String get vaultNoteChip => 'Notă în Vault';

  @override
  String get saveToVault => 'Salvează în Vault';

  @override
  String get savingToVault => 'Se salvează în Vault…';

  @override
  String get savedToVault => 'Salvat în Vault';

  @override
  String get vaultNoteTitlePrefix => 'Notă: ';

  @override
  String get openInVault => 'Deschide în Vault';

  @override
  String get saveToVaultFailed => 'Salvarea în Vault a eșuat';

  @override
  String get pdfWorkerUnavailable =>
      'Exportul PDF este temporar indisponibil. Încercați DOCX sau Markdown.';

  @override
  String get draftingVersionHistory => 'Istoric versiuni';

  @override
  String get emptyHomeTitle => 'Bun venit la Advocat';

  @override
  String get emptyHomeBody =>
      'Alegeți un punct de plecare — noi ne ocupăm de partea juridică complicată.';

  @override
  String get intentChip1 => 'Am primit o amendă';

  @override
  String get intentChip2 => 'Permis refuzat';

  @override
  String get intentChip3 => 'Problemă contractuală';

  @override
  String get emptyCasesTitle => 'Niciun caz încă';

  @override
  String get emptyCasesCta => 'Începeți un caz';

  @override
  String get emptyDraftsTitle => 'Nicio ciornă încă';

  @override
  String get emptyDraftsCta => 'Creează ciornă';

  @override
  String get emptyChatTitle => 'Întrebați orice pe Advocat';

  @override
  String get chatExamplePrompt1 => 'Ajutați-mă să răspund la o amendă';

  @override
  String get chatExamplePrompt2 => 'Revizuiți contractul meu de închiriere';

  @override
  String get chatExamplePrompt3 =>
      'Care sunt drepturile mele la locul de muncă?';

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
  String get contractReviewTitle => 'Revizuire contract';

  @override
  String get contractReviewUploadCta => 'Încărcați contractul';

  @override
  String get contractReviewQuotaRemaining =>
      'Încărcați un contract PDF, DOC, DOCX sau TXT pentru o revizuire AI cu semnale de alarmă și sfaturi de negociere.';

  @override
  String get contractReviewRedFlags => 'Semnale de alarmă';

  @override
  String get contractReviewReviewPoints => 'Puncte de revizuit';

  @override
  String get contractReviewNegotiationTips => 'Sfaturi de negociere';

  @override
  String get contractReviewSaveToVault => 'Salvează în Vault';

  @override
  String get contractReviewContinueChat => 'Continuă în chat';

  @override
  String get referralInviteFriends => 'Invitați prieteni';

  @override
  String get referralYourCode => 'Codul dumneavoastră';

  @override
  String get referralCopiedToast => 'Cod copiat în clipboard';

  @override
  String get referralReward =>
      'Primiți 1 lună de Counsel gratuit pentru fiecare prieten care se abonează.';

  @override
  String get referralInvited => 'Prieteni invitați';

  @override
  String get referralRewardsEarned => 'Luni gratuite câștigate';

  @override
  String get deadlineUrgencyToday => 'Astăzi și restante';

  @override
  String get deadlineUrgencyWeek => 'Săptămâna aceasta';

  @override
  String get deadlineUrgencyMonth => 'Luna aceasta';

  @override
  String get deadlineUrgencyLater => 'Mai târziu';

  @override
  String get deadlineAddManual => 'Adaugă termen';

  @override
  String get deadlineSnoozeBy => 'Amână';

  @override
  String get deadlineSnooze1d => 'Amână 1 zi';

  @override
  String get deadlineSnooze3d => 'Amână 3 zile';

  @override
  String get deadlineSnooze7d => 'Amână 7 zile';

  @override
  String get deadlineDismiss => 'Închide';

  @override
  String get deadlineExportIcs => 'Adaugă în calendar';

  @override
  String get deadlineSource => 'Sursă';

  @override
  String get deadlineEmpty =>
      'Niciun termen încă. Termenele sunt create automat din e-mailurile și documentele dumneavoastră — sau adăugați unul manual cu butonul +.';

  @override
  String get deadlineNewTitle => 'Termen nou';

  @override
  String get deadlineFieldTitle => 'Titlu';

  @override
  String get deadlineFieldDueDate => 'Data scadentă';

  @override
  String get deadlineFieldNotes => 'Note (opțional)';

  @override
  String get deadlineSaved => 'Termen salvat';

  @override
  String get deadlineSaveFailed => 'Termenul nu a putut fi salvat';

  @override
  String get deadlineUrgentBannerSingle => '1 termen astăzi sau restant';

  @override
  String deadlineUrgentBannerMany(int count) {
    return '$count termene astăzi sau restante';
  }

  @override
  String deadlineDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'mai rămân $count zile',
      one: 'mai rămâne 1 zi',
      zero: 'astăzi',
    );
    return '$_temp0';
  }

  @override
  String deadlineDaysOverdue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'restant de $count zile',
      one: 'restant de 1 zi',
    );
    return '$_temp0';
  }

  @override
  String get iapPayWithApple => 'Plătește cu Apple';

  @override
  String get iapRestorePurchases => 'Restaurează achizițiile';

  @override
  String get iapPurchaseFailed =>
      'Achiziția a eșuat. Încearcă din nou sau contactează asistența.';

  @override
  String get iapRestoreSuccess => 'Abonamentul tău a fost restaurat.';

  @override
  String get iapRestoreNoActive => 'Nu există abonament activ de restaurat.';

  @override
  String get deadlineEuRadarTitle => 'Radar termene UE (previzualizare)';

  @override
  String get deadlineEuRadarSubtitle =>
      'Termene procedurale UE ipotetice — date simulate';

  @override
  String get changePassword => 'Schimbă parola';

  @override
  String get changePasswordSubtitle => 'Actualizează parola contului tău';

  @override
  String get newPasswordTitle => 'Setează o parolă nouă';

  @override
  String get newPasswordHint =>
      'Introdu și confirmă o parolă nouă pentru contul tău.';

  @override
  String get newPasswordSave => 'Salvează parola nouă';

  @override
  String get newPasswordSuccess =>
      'Parola a fost actualizată. O poți folosi acum pentru autentificare.';

  @override
  String get newPasswordError =>
      'Actualizarea parolei a eșuat. Te rugăm să încerci din nou.';

  @override
  String get accessLogTile => 'Jurnal de acces';

  @override
  String get accessLogTileSubtitle =>
      'Vedeți cine și ce a accesat datele dumneavoastră';

  @override
  String get accessLogTitle => 'Jurnal de acces la datele mele';

  @override
  String get accessLogIntro =>
      'O evidență transparentă și inviolabilă a fiecărei accesări sau prelucrări a datelor dumneavoastră — inclusiv de către sistemul nostru de inteligență artificială. Puteți verifica faptul că nu a fost modificată.';

  @override
  String get accessLogEmpty => 'Încă nu există evenimente de acces.';

  @override
  String get accessLogError =>
      'Jurnalul de acces nu a putut fi încărcat. Trageți în jos pentru a reîncerca.';

  @override
  String get accessLogIntegrityOk =>
      'Integritate verificată — verigile jurnalului formează un lanț neîntrerupt.';

  @override
  String get accessLogIntegrityBroken =>
      'Avertisment: lanțul jurnalului este întrerupt. Este posibil ca unele înregistrări să fi fost eliminate sau reordonate. Vă rugăm să contactați asistența.';

  @override
  String get accessActionLlmEgress =>
      'Trimis către inteligența artificială pentru prelucrare (pseudonimizat)';

  @override
  String get accessActionAiAnalysis => 'Analizat de inteligența artificială';

  @override
  String get accessActionDocumentParse => 'Document procesat';

  @override
  String get accessActionStaffRead => 'Examinat de un membru al personalului';

  @override
  String get accessActionExport => 'Date exportate';

  @override
  String get accessActionEmailTriage => 'E-mail triat';

  @override
  String get accessActionDeadlineScan => 'Termene scanate';

  @override
  String get breachAlertTitle =>
      'Alertă de securitate privind datele dumneavoastră';

  @override
  String get breachAlertBody =>
      'Monitorizarea noastră automată a detectat un acces neobișnuit care implică datele dumneavoastră. Îl analizăm și vă vom notifica cu privire la orice incident confirmat, conform legii (art. 34 RGPD).';

  @override
  String get caseDossierTitle => 'Exportați dosarul cauzei';

  @override
  String get caseDossierSubtitle =>
      'Un singur PDF cu tot — fapte, cronologie, termene și documente — pentru a-l preda unui avocat, unei instanțe sau unui organism de soluționare a plângerilor.';

  @override
  String get caseDossierTileTitle => 'Exportați dosarul (PDF)';

  @override
  String get caseDossierTileSubtitle =>
      'Predați întreaga cauză unui avocat sau unei instanțe într-un singur fișier';

  @override
  String get caseDossierSectionsHeading => 'Includeți în dosar';

  @override
  String get caseDossierSectionFacts => 'Faptele cauzei';

  @override
  String get caseDossierSectionFactsHint => 'Întotdeauna inclus';

  @override
  String get caseDossierSectionTimeline => 'Cronologie';

  @override
  String get caseDossierSectionDeadlines => 'Termene';

  @override
  String get caseDossierSectionDocuments => 'Documente';

  @override
  String get caseDossierSectionAiSummary =>
      'Rezumat generat de inteligența artificială';

  @override
  String get caseDossierExportButton => 'Exportați PDF';

  @override
  String get caseDossierExporting => 'Se generează dosarul…';

  @override
  String get caseDossierSuccess =>
      'Dosarul este gata. Deschideți sau partajați fișierul.';

  @override
  String get caseDossierOpen => 'Deschideți dosarul';

  @override
  String get caseDossierError =>
      'Dosarul nu a putut fi generat. Vă rugăm să încercați din nou.';

  @override
  String get caseDossierErrorNotOwned => 'Această cauză nu a putut fi găsită.';

  @override
  String get caseDossierDisclaimer =>
      'Dosarul reproduce datele cauzei dumneavoastră așa cum au fost înregistrate. Verificați-l înainte de a-l partaja.';

  @override
  String get followupsTitle => 'Pașii următori';

  @override
  String get followupsSubtitle =>
      'Sarcini practice pentru a menține cauza în desfășurare';

  @override
  String get followupsEmpty => 'Încă nu există pași de urmărit.';

  @override
  String get followupsEmptyDesc =>
      'Adăugați un pas sau lăsați inteligența artificială să sugereze ce trebuie făcut în continuare.';

  @override
  String get followupsAdd => 'Adăugați un pas';

  @override
  String get followupsSuggest => 'Sugerați pași';

  @override
  String get followupsSuggestNone =>
      'Nicio sugestie momentan. Încercați după ce discutați despre cauză.';

  @override
  String get followupsSuggestTitle => 'Pași următori sugerați';

  @override
  String get followupsAddPrompt =>
      'Adăugați pașii pe care doriți să îi păstrați:';

  @override
  String get followupsNewTitleHint => 'Ce trebuie făcut?';

  @override
  String get followupsNewDetailHint => 'Notă opțională (de ce / ce să atașați)';

  @override
  String get followupsDueOptional => 'Amintește-mi la (opțional)';

  @override
  String get followupsOverdue => 'Întârziat';

  @override
  String followupsDueOn(String date) {
    return 'Termen $date';
  }

  @override
  String get followupsDone => 'Finalizat';

  @override
  String get followupsSnooze => 'Amână';

  @override
  String get followupsSnooze1Week => 'Amintește-mi peste o săptămână';

  @override
  String get followupsDismiss => 'Respinge';

  @override
  String get followupsLoadError => 'Pașii următori nu au putut fi încărcați';

  @override
  String get followupsAiBadge => 'IA';

  @override
  String get contractCompareTitle => 'Comparați versiunile';

  @override
  String get contractCompareIntro =>
      'Încărcați două versiuni ale aceluiași contract. Evidențiem ce s-a modificat și dacă fiecare modificare vă avantajează sau vă dezavantajează.';

  @override
  String get contractCompareOldVersion => 'Versiunea veche (v1)';

  @override
  String get contractCompareNewVersion => 'Versiunea nouă (v2)';

  @override
  String get contractCompareCta => 'Comparați versiunile';

  @override
  String get contractCompareAdverse => 'Nefavorabil';

  @override
  String get contractCompareFavorable => 'Favorabil';

  @override
  String get contractCompareNeutral => 'Neutru';

  @override
  String get contractCompareBefore => 'Înainte';

  @override
  String get contractCompareAfter => 'După';

  @override
  String get contractCompareTruncated =>
      'Contract lung — a fost comparată doar prima parte a fiecărei versiuni.';

  @override
  String get contractCompareNoChanges =>
      'Nu au fost detectate modificări semnificative între cele două versiuni.';

  @override
  String get docSearchTitle => 'Căutați în documentele mele';

  @override
  String get docSearchHint => 'de ex. unde a fost menționat avansul';

  @override
  String get docSearchSubtitle =>
      'Căutare semantică în seiful și dosarele dumneavoastră';

  @override
  String get docSearchIdle =>
      'Căutați în conținutul propriilor documente — nu doar în titluri.';

  @override
  String get docSearchNoResults =>
      'Nicio potrivire găsită în documentele dumneavoastră.';

  @override
  String get docSearchError =>
      'Căutarea a eșuat. Vă rugăm să încercați din nou.';

  @override
  String get docSearchUntitled => 'Document fără titlu';

  @override
  String get docSearchKindCase => 'Document al cauzei';

  @override
  String get docSearchKindVault => 'Document din seif';

  @override
  String get docSearchMenuTitle => 'Căutați în documentele mele';

  @override
  String get docSearchMenuSubtitle =>
      'Găsiți orice în propriile fișiere după sens';

  @override
  String get legalTemplatesTitle => 'Bibliotecă de modele';

  @override
  String get legalTemplatesMenuLabel => 'Modele';

  @override
  String get legalTemplatesSubtitle =>
      'Alegeți un formular gata făcut, completați câteva detalii, iar noi vom crea un proiect pe care îl puteți edita și exporta.';

  @override
  String get legalTemplatesDisclaimer =>
      'Acestea sunt formulare-model generale, nu consultanță juridică individuală. Verificați-le și adaptați-le înainte de a le trimite.';

  @override
  String get legalTemplatesSampleBadge => 'Model';

  @override
  String get legalTemplatesEmpty =>
      'Încă nu există modele pentru acest filtru.';

  @override
  String get legalTemplatesError =>
      'Modelele nu au putut fi încărcate. Vă rugăm să încercați din nou.';

  @override
  String get legalTemplatesFilterAll => 'Toate';

  @override
  String get legalTemplatesJurisdictionFi => 'Finlanda';

  @override
  String get legalTemplatesJurisdictionEe => 'Estonia';

  @override
  String get legalTemplatesCategoryComplaint => 'Plângeri';

  @override
  String get legalTemplatesCategoryAppeal => 'Recursuri';

  @override
  String get legalTemplatesCategoryApplication => 'Cereri';

  @override
  String get legalTemplatesCategoryClaim => 'Pretenții';

  @override
  String get legalTemplatesCategoryRequest => 'Solicitări';

  @override
  String get legalTemplatesFillTitle => 'Completați detaliile';

  @override
  String get legalTemplatesFillIntro =>
      'Vom completa automat numele dumneavoastră și detaliile cauzei. Completați câmpurile de mai jos.';

  @override
  String get legalTemplatesFieldRequired => 'Acest câmp este obligatoriu';

  @override
  String get legalTemplatesCreateDraft => 'Creați proiectul';

  @override
  String get legalTemplatesCreating => 'Se creează proiectul…';

  @override
  String get legalTemplatesCreateFailed =>
      'Proiectul nu a putut fi creat. Vă rugăm să încercați din nou.';

  @override
  String get legalTemplatesUnresolvedWarning =>
      'Unele câmpuri sunt încă necompletate și sunt marcate cu ____ în proiect. Le puteți completa în editor.';

  @override
  String get legalTemplatesFieldRecipient =>
      'Destinatar (autoritate / proprietar)';

  @override
  String get legalTemplatesFieldAddress => 'Adresa dumneavoastră poștală';

  @override
  String get legalTemplatesFieldSubject => 'Obiect';

  @override
  String get legalTemplatesFieldDescription => 'Descrierea cauzei';

  @override
  String get legalTemplatesFieldDemand => 'Ce solicitați';

  @override
  String get checklistActionPlan => 'Plan de acțiune';

  @override
  String get checklistActionPlanSubtitle => 'Pași pentru acest tip de cauză';

  @override
  String checklistProgress(int completed, int total) {
    return '$completed din $total pași finalizați';
  }

  @override
  String get checklistAllDone => 'Toți pașii sunt finalizați';

  @override
  String get checklistEmpty =>
      'Încă nu este disponibil un plan de acțiune pentru acest tip de cauză.';

  @override
  String checklistDeadlineDays(int days) {
    return '$days zile';
  }

  @override
  String get checklistDisclaimer =>
      'Aceasta este o informație generală, nu consultanță juridică. Termenele sunt valori legale implicite — confirmați data exactă pentru cauza dumneavoastră.';

  @override
  String get checklistViewPlan => 'Vizualizați planul';

  @override
  String get explainPlainTitle => 'Explicați pe înțelesul tuturor';

  @override
  String get explainPlainIntro =>
      'Lipiți o scrisoare oficială, o decizie sau un contract, iar noi vă vom explica ce înseamnă și ce vă solicită să faceți — într-un limbaj simplu.';

  @override
  String get explainPlainLevelFriend => 'Ca pentru un prieten';

  @override
  String get explainPlainLevelTerms => 'Păstrați termenii juridici';

  @override
  String get explainPlainInputHint => 'Lipiți textul juridic aici…';

  @override
  String get explainPlainSubmit => 'Explicați';

  @override
  String get explainPlainWorking => 'Se explică…';

  @override
  String get explainPlainTldr => 'Pe scurt';

  @override
  String get explainPlainBreakdown => 'Ce spune, parte cu parte';

  @override
  String get explainPlainGlossary => 'Termeni dificili explicați';

  @override
  String get explainPlainNextSteps => 'Ce puteți face în continuare';

  @override
  String get explainPlainOpenInCorpus => 'Căutați în biblioteca juridică';

  @override
  String get explainPlainEmptyResult =>
      'Nu s-a putut genera o explicație pentru acest text. Încercați să lipiți un fragment mai lung sau mai clar.';

  @override
  String get explainPlainQuotaTitle =>
      'Ați folosit explicațiile gratuite din această lună';

  @override
  String get explainPlainQuotaBody =>
      'Conturile gratuite primesc 3 explicații pe lună. Treceți la Pro pentru explicații nelimitate.';

  @override
  String get explainPlainUpgradeCta => 'Treceți la Pro';

  @override
  String get explainPlainError =>
      'A apărut o eroare la explicarea acestui text. Vă rugăm să încercați din nou.';

  @override
  String get explainPlainRetry => 'Încercați din nou';

  @override
  String get demandLetterTitle => 'Scrisoare de punere în întârziere';

  @override
  String get demandLetterSubtitle =>
      'Creați o somație formală prealabilă procesului (maksuvaatimus / nõudekiri).';

  @override
  String get demandLetterStepType => 'Tipul pretenției';

  @override
  String get demandLetterStepParties => 'Părți';

  @override
  String get demandLetterStepClaim => 'Sumă și temei';

  @override
  String get demandLetterStepDeadline => 'Termen';

  @override
  String get demandLetterStepReview => 'Verificare și generare';

  @override
  String get demandLetterClaimDepositReturn => 'Restituirea garanției locative';

  @override
  String get demandLetterClaimUnpaidWage => 'Salarii neplătite';

  @override
  String get demandLetterClaimFineDispute =>
      'Contestarea unei amenzi / unui debit';

  @override
  String get demandLetterClaimGeneric => 'Altă pretenție bănească';

  @override
  String get demandLetterJurisdiction => 'Jurisdicție';

  @override
  String get demandLetterLanguage => 'Limba scrisorii';

  @override
  String get demandLetterRecipientName => 'Numele destinatarului';

  @override
  String get demandLetterRecipientAddress => 'Adresa destinatarului (opțional)';

  @override
  String get demandLetterSenderName => 'Numele dumneavoastră';

  @override
  String get demandLetterSenderAddress =>
      'Adresa dumneavoastră / e-mailul (opțional)';

  @override
  String get demandLetterAmount => 'Sumă';

  @override
  String get demandLetterCurrency => 'Monedă';

  @override
  String get demandLetterBasis => 'Ce s-a întâmplat (temeiul pretenției)';

  @override
  String get demandLetterBasisHint =>
      'Descrieți faptele: date, sume, ce s-a convenit și ce a mers greșit.';

  @override
  String get demandLetterDeadline => 'Termen de plată';

  @override
  String get demandLetterDeadlineHint => 'de ex. 14 zile de astăzi';

  @override
  String get demandLetterReference => 'Referință (opțional)';

  @override
  String get demandLetterGenerate => 'Generați scrisoarea';

  @override
  String get demandLetterGenerating => 'Se generează…';

  @override
  String get demandLetterGenerateFailed =>
      'Scrisoarea nu a putut fi generată. Vă rugăm să încercați din nou.';

  @override
  String get demandLetterFieldRequired => 'Acest câmp este obligatoriu';

  @override
  String get demandLetterNext => 'Înainte';

  @override
  String get demandLetterBack => 'Înapoi';

  @override
  String get demandLetterPreviewTitle => 'Scrisoarea dumneavoastră';

  @override
  String get demandLetterCopy => 'Copiați textul';

  @override
  String get demandLetterCopied => 'Scrisoarea a fost copiată în clipboard';

  @override
  String get demandLetterExportPdf => 'Exportați PDF';

  @override
  String get demandLetterExporting => 'Se exportă…';

  @override
  String get demandLetterExportFailed =>
      'Documentul nu a putut fi exportat. Vă rugăm să încercați din nou.';

  @override
  String get demandLetterSendEmail => 'Trimiteți prin e-mail';

  @override
  String get demandLetterNormsTitle => 'Referințe juridice';

  @override
  String get demandLetterDisclaimer =>
      'Această scrisoare este întocmită în numele dumneavoastră ca model general. Nu reprezintă consultanță juridică sau un act al unui avocat autorizat. Verificați-o înainte de a o trimite — nicio scrisoare nu este trimisă automat.';

  @override
  String get demandLetterMenuTile => 'Scrisoare de punere în întârziere';

  @override
  String get calcHubTitle => 'Calculatoare juridice';

  @override
  String get calcHubSubtitle => 'Estimări rapide înaintea pasului următor';

  @override
  String get calcHubJurisdiction => 'Jurisdicție';

  @override
  String calcRatesAsOf(String date) {
    return 'Tarife valabile la data $date';
  }

  @override
  String get calcRatesOffline =>
      'Se afișează tarifele din memoria cache (offline)';

  @override
  String get calcIndicativeBanner =>
      'Doar estimare orientativă — nu este un calcul oficial sau consultanță juridică.';

  @override
  String get calcCalculate => 'Calculați';

  @override
  String get calcResult => 'Rezultat';

  @override
  String get calcFormula => 'Cum se calculează';

  @override
  String get calcSource => 'Sursă';

  @override
  String get calcSeveranceTitle => 'Indemnizație / preaviz';

  @override
  String get calcSeveranceDesc =>
      'Estimați indemnizația de concediere și perioada de preaviz în caz de disponibilizare';

  @override
  String get calcSeveranceSalary => 'Salariu lunar brut';

  @override
  String get calcSeveranceTenure => 'Ani de vechime';

  @override
  String get calcSeveranceTotal => 'Indemnizație estimată';

  @override
  String get calcSeveranceNotice => 'Perioadă de preaviz';

  @override
  String get calcSeveranceGenerateDemand =>
      'Întocmiți o scrisoare de punere în întârziere';

  @override
  String get calcLimitationTitle => 'Termene de prescripție și de recurs';

  @override
  String get calcLimitationDesc =>
      'Verificați dacă un termen de formulare a unei pretenții sau a unui recurs a expirat';

  @override
  String get calcLimitationType => 'Tipul termenului';

  @override
  String get calcLimitationStart => 'Data de început (eveniment / decizie)';

  @override
  String get calcLimitationPickDate => 'Alegeți data';

  @override
  String get calcLimitationDeadline => 'Termen';

  @override
  String get calcLimitationExpired => 'Termenul a expirat';

  @override
  String calcLimitationDaysLeft(int days) {
    return '$days zile rămase';
  }

  @override
  String get calcLimitationShifted =>
      'Mutat în următoarea zi lucrătoare (weekend/sărbătoare).';

  @override
  String get calcLimitationAddDeadline => 'Adăugați la termene';

  @override
  String get calcStateFeeTitle => 'Taxe judiciare / de stat';

  @override
  String get calcStateFeeDesc =>
      'Taxe de înregistrare orientative, după instanță și etapă';

  @override
  String get calcChildSupportTitle => 'Pensie de întreținere (orientativ)';

  @override
  String get calcChildSupportDesc =>
      'Cifră orientativă aproximativă — cuantumul real se stabilește de la caz la caz';

  @override
  String get calcChildSupportNet => 'Venitul lunar net al plătitorului';

  @override
  String get calcChildSupportChildren => 'Numărul de copii';

  @override
  String get calcChildSupportPerChild => 'Per copil';

  @override
  String get calcChildSupportTotal => 'Total lunar';

  @override
  String get calcChildSupportWarning =>
      'Foarte variabil. Instanțele decid în funcție de nevoile copilului și de capacitatea de plată a ambilor părinți. Utilizați doar ca punct de plecare.';

  @override
  String get docCollectTitle => 'Documente de strâns';

  @override
  String get docCollectSubtitle =>
      'Adunați-le înainte de a depune cererea sau de a merge în instanță';

  @override
  String get docCollectPickPrompt => 'Care este situația dumneavoastră?';

  @override
  String get docCollectProblemResidence => 'Permis de ședere';

  @override
  String get docCollectProblemTenant => 'Închiriere / evacuare';

  @override
  String get docCollectProblemDismissal => 'Concediere la locul de muncă';

  @override
  String get docCollectProblemInheritance => 'Moștenire';

  @override
  String get docCollectProblemDivorce => 'Divorț';

  @override
  String docCollectProgress(int collected, int total) {
    return '$collected din $total strânse';
  }

  @override
  String get docCollectAllDone => 'Totul a fost strâns';

  @override
  String get docCollectEmpty =>
      'Încă nu este disponibilă o listă de documente pentru această situație.';

  @override
  String get docCollectOptional => 'Opțional';

  @override
  String get docCollectWhereLabel => 'De unde îl obțineți';

  @override
  String get docCollectWhyLabel => 'De ce este necesar';

  @override
  String get docCollectAttach => 'Atașați un fișier';

  @override
  String get docCollectAttached => 'Fișier atașat';

  @override
  String get docCollectChangeFile => 'Schimbați fișierul';

  @override
  String get docCollectRemoveFile => 'Eliminați fișierul';

  @override
  String get docCollectNoFiles => 'Încă nu ați încărcat niciun document.';

  @override
  String get docCollectPickFileTitle => 'Alegeți un document încărcat';

  @override
  String get docCollectExport => 'Exportați lista';

  @override
  String get docCollectExportSubject =>
      'Lista mea de verificare a documentelor';

  @override
  String get docCollectAiTitle => 'Aveți nevoie de ceva anume?';

  @override
  String get docCollectAiHint =>
      'Descrieți situația dumneavoastră, iar noi vă vom sugera eventuale documente suplimentare.';

  @override
  String get docCollectAiField => 'Descrieți situația dumneavoastră';

  @override
  String get docCollectAiButton => 'Sugerați documente suplimentare';

  @override
  String get docCollectAiLoading => 'Se procesează…';

  @override
  String get docCollectAiEmpty =>
      'Nu au fost sugerate documente suplimentare — lista de bază pare completă pentru descrierea dumneavoastră.';

  @override
  String get docCollectAiSuggestionsTitle => 'Documente suplimentare sugerate';

  @override
  String get docCollectDisclaimer =>
      'Aceasta este o listă de bază a documentelor solicitate în mod obișnuit — situația dumneavoastră poate necesita mai multe sau mai puține. Este o informație generală, nu consultanță juridică.';

  @override
  String get docCollectRetry => 'Încercați din nou';

  @override
  String get renewalTitle => 'Radar de reînnoire';

  @override
  String get renewalSubtitle =>
      'Urmăriți când expiră permisele, pașaportul, asigurarea și alte documente. Vă vom reaminti cu 90, 30 și 7 zile înainte de fiecare reînnoire.';

  @override
  String get renewalAdd => 'Adăugați un document';

  @override
  String get renewalEditTitle => 'Editați documentul';

  @override
  String get renewalSave => 'Salvați';

  @override
  String get renewalRequired => 'Obligatoriu';

  @override
  String get renewalPickDate => 'Alegeți data de expirare';

  @override
  String get renewalLoadError =>
      'Documentele dumneavoastră nu au putut fi încărcate. Trageți pentru a reîmprospăta.';

  @override
  String get renewalEmptyTitle => 'Încă niciun document urmărit';

  @override
  String get renewalEmptyBody =>
      'Adăugați permisul de ședere, pașaportul, asigurarea sau permisul, iar noi vom urmări datele de expirare pentru dumneavoastră.';

  @override
  String get renewalGuideHint => 'Cum se reînnoiește →';

  @override
  String get renewalFieldType => 'Tipul documentului';

  @override
  String get renewalFieldLabel => 'Etichetă';

  @override
  String get renewalFieldNumber => 'Numărul documentului (opțional)';

  @override
  String get renewalFieldJurisdiction => 'Țara emitentă';

  @override
  String get renewalFieldExpiry => 'Data de expirare';

  @override
  String get renewalWindow90 => '90 de zile';

  @override
  String get renewalWindow30 => '30 de zile';

  @override
  String get renewalWindow7 => '7 zile';

  @override
  String get renewalExpiresToday => 'Expiră astăzi';

  @override
  String renewalExpiresInDays(int days, String date) {
    return 'Expiră peste $days zile · $date';
  }

  @override
  String renewalExpiredOn(String date) {
    return 'A expirat la $date';
  }

  @override
  String get renewalTypeResidencePermit => 'Permis de ședere';

  @override
  String get renewalTypePassport => 'Pașaport';

  @override
  String get renewalTypeIdCard => 'Carte de identitate';

  @override
  String get renewalTypeVisa => 'Viză';

  @override
  String get renewalTypeDrivingLicence => 'Permis de conducere';

  @override
  String get renewalTypeInsurance => 'Asigurare';

  @override
  String get renewalTypeWorkPermit => 'Permis de muncă';

  @override
  String get renewalTypeOther => 'Altul';

  @override
  String get costEstimateTitle => 'Estimator de costuri și riscuri';

  @override
  String get costEstimateSubtitle =>
      'Aflați aproximativ cât ar putea costa o cauză, cât ar putea dura și dacă merită urmărită.';

  @override
  String get costEstimateCaseTypeLabel => 'Tipul cauzei';

  @override
  String get costEstimateCaseTypeHint =>
      'de ex. factură neplătită, concediere abuzivă, litigiu privind garanția';

  @override
  String get costEstimateJurisdictionLabel => 'Jurisdicție';

  @override
  String get costEstimateAmountLabel => 'Suma în litigiu (opțional)';

  @override
  String get costEstimateAmountHint => 'de ex. 12500';

  @override
  String get costEstimateDescriptionLabel =>
      'Descrieți pe scurt situația (opțional)';

  @override
  String get costEstimateB2bToggle =>
      'Fișă de calificare a clienților potențiali (B2B)';

  @override
  String get costEstimateB2bSubtitle =>
      'Rezultat compact pentru trierea rapidă a unui client nou.';

  @override
  String get costEstimateSubmit => 'Estimați cauza mea';

  @override
  String get costEstimateDisclaimer =>
      'Doar o estimare aproximativă — nu o predicție, o garanție sau consultanță juridică. Costurile și rezultatele reale variază de la caz la caz.';

  @override
  String get costEstimateCostsHeading => 'Costuri estimate';

  @override
  String get costEstimateCourtFee => 'Taxă judiciară / de stat';

  @override
  String get costEstimateLawyerFee => 'Onorariu avocat';

  @override
  String get costEstimateTotal => 'Total (aprox.)';

  @override
  String get costEstimateDuration => 'Timp până la prima soluționare';

  @override
  String get costEstimateMonthsSuffix => 'luni';

  @override
  String get costEstimateFactorsFor => 'În favoarea dumneavoastră';

  @override
  String get costEstimateFactorsAgainst => 'În defavoarea dumneavoastră';

  @override
  String get costEstimateStrengthWorth => 'Probabil merită urmărită';

  @override
  String get costEstimateStrengthContested =>
      'Contestată — poate evolua în oricare direcție';

  @override
  String get costEstimateStrengthWeak => 'Slabă — procedați cu prudență';
}
