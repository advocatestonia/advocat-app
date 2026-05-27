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
  String get accidents => 'Accidente';

  @override
  String get active => 'Active';

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
  String get appleComingSoon => 'Coming soon';

  @override
  String get appleComingSoonMessage =>
      'Apple Sign-In becomes available soon. Use Google or email to continue.';

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
  String get email => 'Email';

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
  String get pushNotifications => 'Notificări push';

  @override
  String get rateUs => 'Evaluați-ne';

  @override
  String get rateAppComingSoon => 'Coming to app stores soon!';

  @override
  String get dataCopiedToClipboard => 'Data copied to clipboard';

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
      'Advocat v2.1 reads your inbox to draft replies; you can revoke any time. Reconnect Gmail to enable proactive triage.';

  @override
  String get gmailReauthBannerCta => 'Reauthorize';

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
      'Hi! I\'m Advocat — your AI legal assistant. I provide legal information, not legal advice. What legal question can I help with?';

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
  String get inheritance => 'Moștenire';

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
  String get consumerProtection => 'Protecția consumatorilor';

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
  String get comingSoon => 'În curând';

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
      other: '$count drepturi înăuntru',
      one: '1 drept înăuntru',
      zero: 'niciun drept înăuntru',
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
      'Under GDPR, you have the “right to be forgotten” — platforms must delete your personal data upon request if there is no legal basis to keep it.';

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
      other: 'în $count zile',
      one: 'în 1 zi',
      zero: 'astăzi',
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
      other: '$count zile întârziere',
      one: '1 zi întârziere',
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
  String get deadlineEuRadarTitle => 'EU deadline radar (preview)';

  @override
  String get deadlineEuRadarSubtitle =>
      'Hypothetical EU procedural deadlines — mock data';
}
