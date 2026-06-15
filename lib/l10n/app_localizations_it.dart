// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get about => 'Informazioni';

  @override
  String get aboutSection => 'INFORMAZIONI';

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
  String get accidents => 'Incidenti';

  @override
  String get active => 'Attivi';

  @override
  String get activeCases => 'Casi attivi';

  @override
  String get addedToAppeal => 'Aggiunto all’appello';

  @override
  String get agreeToTerms => 'Accetto i ';

  @override
  String get aiAnalysis => 'Analisi IA';

  @override
  String get aiAssistant => 'Assistente legale IA';

  @override
  String get aiChat => 'Chat IA';

  @override
  String get all => 'Tutti';

  @override
  String get alreadyHaveAccount => 'Hai già un account? ';

  @override
  String get analyzing => 'Analisi in corso…';

  @override
  String get aiAnalyzing => 'L\'IA sta analizzando';

  @override
  String get speakIntoMicHint =>
      'Parli nel microfono. Si assicuri che l\'accesso al microfono sia abilitato.';

  @override
  String get aiErrorRateLimit =>
      'Il servizio è temporaneamente sovraccarico. Riprovi tra 1-2 minuti.';

  @override
  String get aiErrorOverload =>
      'L\'IA è occupata in questo momento, riprovi tra un minuto.';

  @override
  String freeLimitReached(int count) {
    return 'Ha utilizzato tutti i $count messaggi IA gratuiti. Passi a Legal Counsel per un\'assistenza IA illimitata!';
  }

  @override
  String get andWord => ' e ';

  @override
  String get appTitle => 'Advocat — Strumento di informazione legale';

  @override
  String get appVersion => 'Versione dell’app';

  @override
  String get appealFiled => 'Appello presentato';

  @override
  String get areYouAbsolutelySure => 'Sei assolutamente sicuro?';

  @override
  String get askAboutCase => 'Analizza il mio caso';

  @override
  String get asylum => 'Asilo';

  @override
  String get back => 'Indietro';

  @override
  String get basic => 'Base';

  @override
  String get beforeYouBuy => 'Prima di acquistare';

  @override
  String get beforeYouWork => 'Prima di lavorare con loro';

  @override
  String get camera => 'Fotocamera';

  @override
  String get cancel => 'Annulla';

  @override
  String get caseDescription => 'Descrivi la tua situazione';

  @override
  String get caseDetail => 'Dettagli del caso';

  @override
  String get caseOverview => 'Ecco la panoramica dei tuoi casi';

  @override
  String get caseTitle => 'Titolo del caso';

  @override
  String get caseUpdated => 'Caso aggiornato';

  @override
  String get cases => 'Casi';

  @override
  String get checkCompany => 'Verifica azienda';

  @override
  String get checkDeadlines => 'Verifica scadenze';

  @override
  String get checkVehicle => 'Verifica veicolo';

  @override
  String get checkerTitle => 'Verificatore';

  @override
  String get checkingErrors => 'Controllo errori…';

  @override
  String get choosePlan => 'Scegli piano';

  @override
  String get closed => 'Chiusi';

  @override
  String get companyName => 'Nome azienda o n. registrazione';

  @override
  String get completed => 'Completato';

  @override
  String get confirm => 'Conferma';

  @override
  String get confirmPassword => 'Conferma password';

  @override
  String get connectEmail => 'Collega email';

  @override
  String get connectGmail => 'Collega Gmail';

  @override
  String get connectOutlook => 'Collega Outlook';

  @override
  String get connected => 'Collegato';

  @override
  String get contactSupport => 'Contatta il supporto';

  @override
  String get continueWithGoogle => 'Continua con Google';

  @override
  String get appleComingSoon => 'Disponibile a breve';

  @override
  String get appleComingSoonMessage =>
      'L\'accesso con Apple sarà disponibile a breve. Usi Google o l\'email per continuare.';

  @override
  String get copyText => 'Copia testo';

  @override
  String get correspondence => 'Corrispondenza';

  @override
  String get couldNotLoadCases => 'Impossibile caricare i tuoi casi';

  @override
  String get country => 'Paese';

  @override
  String get createAccount => 'Crea account';

  @override
  String get createCase => 'Crea caso';

  @override
  String get criminalCase => 'Caso penale';

  @override
  String get critical => 'Critico';

  @override
  String get currentPlan => 'Piano attuale';

  @override
  String get dataAndPrivacy => 'DATI E PRIVACY';

  @override
  String get dataExportRequested =>
      'Esportazione dati richiesta. Controlla la tua email.';

  @override
  String daysRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giorni',
      one: '1 giorno',
      zero: 'nessun giorno rimanente',
    );
    return '$_temp0';
  }

  @override
  String get deadlineReminders => 'Promemoria scadenze';

  @override
  String get deadlineRemindersDesc => 'Ricevi notifiche prima delle scadenze';

  @override
  String get deadlines => 'Scadenze';

  @override
  String get debtCollection => 'Recupero crediti';

  @override
  String get deleteAccount => 'Elimina account';

  @override
  String get deleteAccountDesc => 'Rimuovi permanentemente il tuo account';

  @override
  String get deleteAccountDialogContent =>
      'Questa azione è permanente e irreversibile. Tutti i tuoi dati, casi e documenti verranno eliminati permanentemente.';

  @override
  String get deleteConfirm =>
      'Sei sicuro? Tutti i tuoi dati verranno eliminati permanentemente.';

  @override
  String get demoHint => 'Demo: prova la targa «908FBT»';

  @override
  String get demoModeDesc =>
      'Esplora l’app con dati di esempio da un caso reale';

  @override
  String get deportation => 'Deportazione';

  @override
  String get disclaimer =>
      'Solo orientamento IA — non consulenza legale. Consulta sempre un avvocato.';

  @override
  String get disclaimerFull =>
      'Questo è un assistente IA, non un avvocato. L’analisi IA può contenere errori. Verifica sempre con un professionista legale qualificato.';

  @override
  String get disconnect => 'Disconnetti';

  @override
  String get discrimination => 'Discriminazione';

  @override
  String get doNotBuy => 'Non acquistare';

  @override
  String get documents => 'Documenti';

  @override
  String documentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documenti',
      one: '1 documento',
      zero: 'nessun documento',
    );
    return '$_temp0';
  }

  @override
  String get draftAppeal => 'Bozza di appello';

  @override
  String get editDraft => 'Modifica';

  @override
  String get editProfile => 'Modifica profilo';

  @override
  String get email => 'Email';

  @override
  String get emailConnected => 'Email collegata';

  @override
  String get emailDisconnected => 'Email disconnessa';

  @override
  String get emailIntegration => 'INTEGRAZIONE EMAIL';

  @override
  String get emailInvalid => 'Inserisci un indirizzo email valido';

  @override
  String get emailPrivacyNote =>
      'Leggiamo solo le email relative a questioni legali. Le tue email personali restano private.';

  @override
  String get emailRequired => 'L’email è obbligatoria';

  @override
  String get emergencyShield => 'Scudo d’emergenza';

  @override
  String get error => 'Errore';

  @override
  String get exportDataDesc => 'Scarica tutti i dati dei tuoi casi';

  @override
  String get exportDataDialogContent =>
      'Prepareremo un download di tutti i tuoi dati, inclusi casi, documenti e corrispondenza. Riceverai un’email quando sarà pronto.';

  @override
  String get exportMyData => 'Esporta i miei dati';

  @override
  String get exportPdf => 'Esporta PDF';

  @override
  String get familyReunification => 'Ricongiungimento familiare';

  @override
  String get forgotPassword => 'Password dimenticata?';

  @override
  String get free => 'Gratuito';

  @override
  String get fullDefense => 'Advocat Pro';

  @override
  String get fullName => 'Nome completo';

  @override
  String get gallery => 'Galleria';

  @override
  String get generateAppeal => 'Genera appello';

  @override
  String get getStarted => 'Inizia';

  @override
  String goodAfternoon(String name) {
    return 'Buon pomeriggio, $name';
  }

  @override
  String goodEvening(String name) {
    return 'Buonasera, $name';
  }

  @override
  String goodMorning(String name) {
    return 'Buongiorno, $name';
  }

  @override
  String goodNight(String name) {
    return 'Buonanotte, $name';
  }

  @override
  String get home => 'Home';

  @override
  String get important => 'Importante';

  @override
  String get inProgress => 'In corso';

  @override
  String get informational => 'Informativo';

  @override
  String get inspection => 'Revisione tecnica';

  @override
  String get insurance => 'Assicurazione';

  @override
  String issuesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count problemi trovati',
      one: '1 problema trovato',
      zero: 'nessun problema trovato',
    );
    return '$_temp0';
  }

  @override
  String get laborDispute => 'Controversia di lavoro';

  @override
  String get langEnglish => 'Inglese';

  @override
  String get langFinnish => 'Finlandese';

  @override
  String get langRussian => 'Russo';

  @override
  String get language => 'Lingua';

  @override
  String lastActivity(String time) {
    return 'Ultima attività: $time';
  }

  @override
  String get legalFighter => 'Combattente legale';

  @override
  String get legalSection => 'LEGALE';

  @override
  String get licensePlate => 'Targa';

  @override
  String get loading => 'Caricamento…';

  @override
  String get logIn => 'Entra';

  @override
  String get loginFailed => 'Email o password non validi. Riprova.';

  @override
  String get lost => 'Perso';

  @override
  String get markComplete => 'Segna come completato';

  @override
  String get mileage => 'Chilometraggio';

  @override
  String get myCases => 'I miei casi';

  @override
  String get nameRequired => 'Il nome completo è obbligatorio';

  @override
  String get newCase => 'Nuovo caso';

  @override
  String get next => 'Avanti';

  @override
  String get noAccount => 'Non hai un account? ';

  @override
  String get noCases => 'Ancora nessun caso';

  @override
  String get noCasesYet => 'Ancora nessun caso';

  @override
  String get noDeadlines => 'Nessuna scadenza — tutto in ordine!';

  @override
  String get noRecentActivity => 'Nessuna attività recente';

  @override
  String get notifications => 'NOTIFICHE';

  @override
  String get onboardingDesc1 =>
      'Advocat ti aiuta a comprendere la tua situazione legale. Gli strumenti di IA analizzano documenti, identificano potenziali problemi e preparano bozze di documenti per la tua revisione. Non è uno studio legale — è uno strumento tecnologico a supporto del tuo caso.';

  @override
  String get onboardingDesc2 =>
      'Fotografa qualsiasi documento legale. L’IA lo legge in più lingue, estrae i dati chiave e verifica la conformità alle direttive UE e alle leggi nazionali.';

  @override
  String get onboardingDesc3 =>
      'I nostri strumenti di IA verificano oltre 40 tipi di requisiti procedurali. L’analisi dell’IA può identificare problemi che richiedono attenzione — come la lingua di notifica, i passaggi procedurali e le scadenze legali. Verifica sempre con un avvocato qualificato.';

  @override
  String get onboardingDesc4 =>
      'L’IA prepara bozze di appelli, reclami e lettere con riferimenti legali per la tua revisione. Decidi tu cosa presentare. Ogni documento deve essere rivisto da un professionista legale qualificato prima della presentazione.';

  @override
  String get onboardingNext => 'Avanti';

  @override
  String get onboardingSkip => 'Salta';

  @override
  String get onboardingTitle1 => 'Informazioni legali basate sull’IA';

  @override
  String get onboardingTitle2 => 'Scansiona e analizza documenti';

  @override
  String get onboardingTitle3 => 'L’IA verifica potenziali problemi';

  @override
  String get onboardingTitle4 => 'Bozze di documenti per la tua revisione';

  @override
  String get openACase => 'Apri un caso';

  @override
  String get optional => '(facoltativo)';

  @override
  String get orDivider => 'o';

  @override
  String get other => 'Altro';

  @override
  String get overdue => 'Scaduto';

  @override
  String get owners => 'Proprietari precedenti';

  @override
  String get password => 'Password';

  @override
  String get passwordRequired => 'La password è obbligatoria';

  @override
  String get passwordStrengthMedium => 'Media';

  @override
  String get passwordStrengthStrong => 'Forte';

  @override
  String get passwordStrengthWeak => 'Debole';

  @override
  String get passwordTooShort => 'La password deve avere almeno 8 caratteri';

  @override
  String get passwordsDoNotMatch => 'Le password non corrispondono';

  @override
  String get pendingDecision => 'Decisione in attesa';

  @override
  String get perCheck => 'per verifica';

  @override
  String get permanentlyDelete => 'Elimina permanentemente';

  @override
  String get policeMisconduct => 'Abuso di polizia';

  @override
  String get popular => 'POPOLARE';

  @override
  String get preferences => 'PREFERENZE';

  @override
  String get preferredLanguage => 'Lingua preferita';

  @override
  String get pricePerCheck => '4,99 € per verifica';

  @override
  String get privacyPolicy => 'Informativa sulla privacy';

  @override
  String get dpaTitle => 'Accordo sul trattamento dei dati';

  @override
  String get dpaCheckoutGateTitle => 'Prima di effettuare l\'upgrade';

  @override
  String get dpaCheckoutGateBody =>
      'La normativa UE (art. 28 GDPR) ci impone di firmare un accordo sul trattamento dei dati con ogni cliente pagante. La preghiamo di leggerlo e accettarlo.';

  @override
  String get dpaViewLink => 'Visualizza l\'accordo sul trattamento dei dati';

  @override
  String get dpaCheckboxLabel =>
      'Ho letto e accetto l\'accordo sul trattamento dei dati (v1.0).';

  @override
  String get dpaCancel => 'Annulla';

  @override
  String get dpaAcceptAndContinue => 'Accetta e continua';

  @override
  String get dpaOpenHint =>
      'Apra l\'accordo (DPA) almeno una volta per abilitare il pulsante Accetta.';

  @override
  String get pro => 'Pro';

  @override
  String get pushNotifications => 'Notifiche push';

  @override
  String get rateUs => 'Valutaci';

  @override
  String get rateAppComingSoon => 'Disponibile a breve negli app store!';

  @override
  String get dataCopiedToClipboard => 'Dati copiati negli appunti';

  @override
  String get readingDocument => 'Lettura documento…';

  @override
  String get recentActivity => 'Attività recente';

  @override
  String get referenceNumber => 'Numero di riferimento';

  @override
  String get registerFailed => 'Registrazione non riuscita. Riprova.';

  @override
  String get reportFraud => 'Segnala frode';

  @override
  String get requestExport => 'Richiedi esportazione';

  @override
  String get researchingLaw => 'Ricerca della legge applicabile…';

  @override
  String get resetPasswordFailed => 'Invio del link non riuscito. Riprova.';

  @override
  String get resetPasswordSent =>
      'Link di reimpostazione inviato alla tua email.';

  @override
  String get residencePermit => 'Permesso di soggiorno';

  @override
  String get manageSubscription => 'Gestisci abbonamento';

  @override
  String get restorePurchases => 'Ripristina acquisti';

  @override
  String get retry => 'Riprova';

  @override
  String get reviewWarning =>
      'Rivedi attentamente prima dell’invio. Sei responsabile del contenuto.';

  @override
  String get riskHigh => 'Rischio alto — evitare';

  @override
  String get riskLow => 'Sicuro per collaborare';

  @override
  String get riskMedium => 'Procedere con cautela';

  @override
  String get safeToBuy => 'Sicuro da acquistare';

  @override
  String get saveAndAnalyze => 'Salva e analizza';

  @override
  String get saveDraft => 'Salva';

  @override
  String get saveWithAnnual => 'Risparmia il 25% con la fatturazione annuale';

  @override
  String get scan => 'Scansiona';

  @override
  String get scanDocument => 'Scansiona documento';

  @override
  String get searchCases => 'Cerca casi…';

  @override
  String get selectCountry => 'Seleziona paese';

  @override
  String get selectLanguage => 'Seleziona lingua';

  @override
  String get sendViaEmail => 'Invia via email';

  @override
  String get settings => 'Impostazioni';

  @override
  String get signIn => 'Accedi';

  @override
  String get signInLink => 'Entra';

  @override
  String get signInSubtitle => 'Accedi per consultare i tuoi casi';

  @override
  String get signOut => 'Esci';

  @override
  String get signOutConfirm => 'Sei sicuro di voler uscire?';

  @override
  String get signUp => 'Crea account';

  @override
  String get signUpLink => 'Registrati';

  @override
  String get socialBenefits => 'Prestazioni sociali';

  @override
  String get someConcerns => 'Alcune preoccupazioni';

  @override
  String get startFirstCase => 'Inizia il tuo primo caso';

  @override
  String step(int current, int total) {
    return 'Passo $current di $total';
  }

  @override
  String get stolen => 'Verifica furto';

  @override
  String get subscription => 'Abbonamento';

  @override
  String get syncLegalCorrespondence => 'Sincronizza corrispondenza legale';

  @override
  String get syncNow => 'Sincronizza ora';

  @override
  String get tenantRights => 'Diritti dell’inquilino';

  @override
  String get termsOfService => 'Termini di servizio';

  @override
  String get termsRequired => 'Devi accettare i Termini di servizio';

  @override
  String get timeline => 'Cronologia';

  @override
  String get tryDemoMode => 'Prova la modalità demo';

  @override
  String get typeDeleteToConfirm =>
      'Digita DELETE per confermare la rimozione permanente dell’account.';

  @override
  String get typeMessage => 'Scrivi un messaggio…';

  @override
  String get upcoming => 'In arrivo';

  @override
  String get uploadDocument => 'Carica documento';

  @override
  String urgentDeadline(String title) {
    return 'Urgente: $title';
  }

  @override
  String get useInAppeal => 'Usa nell’appello';

  @override
  String get vehicleChecker => 'Verificatore veicoli';

  @override
  String get vehicleChecks => 'Verifiche di stato';

  @override
  String get vehicleColor => 'Colore';

  @override
  String get vehicleMake => 'Marca';

  @override
  String get vehicleModel => 'Modello';

  @override
  String get vehicleYear => 'Anno';

  @override
  String get version => 'Versione';

  @override
  String get victimSupport => 'Supporto alle vittime';

  @override
  String get viewAll => 'Vedi tutti';

  @override
  String get vinNumber => 'Numero VIN';

  @override
  String get welcomeBack => 'Bentornato';

  @override
  String get whatAreMyOptions => 'Quali sono le mie opzioni?';

  @override
  String get won => 'Vinto';

  @override
  String get documentVault => 'Cassaforte documenti';

  @override
  String get secureDocumentStorage => 'Archivio documenti sicuro';

  @override
  String get secureDocumentStorageDesc =>
      'Conserva i tuoi documenti legali importanti in un unico posto per un accesso facile.';

  @override
  String get addDocument => 'Aggiungi documento';

  @override
  String get chooseHowToAdd => 'Scegli come aggiungere il tuo documento';

  @override
  String get uploadFile => 'Carica file';

  @override
  String get uploadFileDesc =>
      'Scegli un PDF o un\'immagine dal tuo dispositivo';

  @override
  String get scanDocumentDesc => 'Scatta una foto del tuo documento';

  @override
  String get createNote => 'Crea nota';

  @override
  String get createNoteDesc => 'Scrivi una nota o registra dettagli importanti';

  @override
  String get knowYourRights => 'Conosci i tuoi diritti';

  @override
  String get stoppedByPolice => 'Fermato dalla polizia';

  @override
  String get stoppedByPoliceDesc =>
      'I tuoi diritti durante un controllo di polizia';

  @override
  String get deportationNotice => 'Avviso di espulsione';

  @override
  String get deportationNoticeDesc =>
      'Passi per contestare un ordine di allontanamento';

  @override
  String get workplaceRights => 'Diritti sul lavoro';

  @override
  String get workplaceRightsDesc =>
      'Tutele del diritto del lavoro in Finlandia';

  @override
  String get tenantRightsDesc => 'Protezioni abitative e locative';

  @override
  String get immigrationDetention => 'Trattenimento per immigrazione';

  @override
  String get immigrationDetentionDesc => 'Diritti se trattenuto dalle autorità';

  @override
  String get discriminationDesc =>
      'Come segnalare e combattere la discriminazione';

  @override
  String get scenarioNotFound => 'Scenario non trovato';

  @override
  String get youHaveRightTo => 'Hai il diritto di:';

  @override
  String get youMust => 'Devi:';

  @override
  String get immediateSteps => 'Passi immediati:';

  @override
  String get yourRights => 'I tuoi diritti:';

  @override
  String get basicRights => 'Diritti fondamentali:';

  @override
  String get yourRightsAsTenant => 'I tuoi diritti come inquilino:';

  @override
  String get yourRightsInDetention => 'I tuoi diritti in detenzione:';

  @override
  String get howToAct => 'Come agire:';

  @override
  String get rightKnowWhyStopped => 'Sapere perché sei stato fermato';

  @override
  String get rightRemainSilent => 'Rimanere in silenzio (devi identificarti)';

  @override
  String get rightAskInterpreter => 'Chiedere un interprete';

  @override
  String get rightContactLawyer =>
      'Contattare un avvocato prima dell\'interrogatorio';

  @override
  String get rightRecordEncounter =>
      'Registrare l\'incontro (in luoghi pubblici)';

  @override
  String get mustProvideName => 'Fornisci il tuo nome e data di nascita';

  @override
  String get mustShowId => 'Mostra il documento se ne hai uno';

  @override
  String get mustNotResist => 'Non opporre resistenza fisica';

  @override
  String get doNotIgnoreNotice =>
      'NON ignorare l\'avviso - le scadenze sono rigorose';

  @override
  String get noteAppealDeadline =>
      'Annota la scadenza del ricorso (di solito 30 giorni)';

  @override
  String get contactLawyerImmediately => 'Contatta immediatamente un avvocato';

  @override
  String get applyLegalAid =>
      'Richiedi il patrocinio a spese dello Stato se necessario';

  @override
  String get rightAppealAdmin =>
      'Diritto di ricorso al Tribunale Amministrativo';

  @override
  String get rightLegalRep => 'Diritto alla rappresentanza legale';

  @override
  String get rightInterpreter => 'Diritto a un interprete';

  @override
  String get rightStayDuringAppeal =>
      'Diritto di restare durante il ricorso (nella maggior parte dei casi)';

  @override
  String get minimumWage => 'Salario minimo secondo il contratto collettivo';

  @override
  String get workingTimeLimits =>
      'Limiti orario di lavoro (max 8h/giorno, 40h/settimana)';

  @override
  String get annualLeave => 'Ferie annuali (minimo 2 giorni per mese lavorato)';

  @override
  String get sickLeave => 'Indennità di malattia';

  @override
  String get safeWorkingConditions => 'Condizioni di lavoro sicure';

  @override
  String get writtenRentalAgreement =>
      'Contratto di locazione scritto obbligatorio';

  @override
  String get securityDeposit => 'Deposito cauzionale max 3 mesi di affitto';

  @override
  String get landlordNotice => 'Il proprietario deve dare preavviso (3–6 mesi)';

  @override
  String get rightHabitableDwelling => 'Diritto a un\'abitazione abitabile';

  @override
  String get protectionUnjustEviction => 'Protezione da sfratto ingiusto';

  @override
  String get rightKnowDetentionReason =>
      'Diritto di conoscere il motivo della detenzione';

  @override
  String get rightContactLawyerDetention => 'Diritto di contattare un avvocato';

  @override
  String get rightContactEmbassy =>
      'Diritto di contattare la propria ambasciata';

  @override
  String get rightChallengeDetention =>
      'Diritto di contestare la detenzione in tribunale';

  @override
  String get rightHumaneTreatment =>
      'Diritto a un trattamento umano e cure mediche';

  @override
  String get documentIncident =>
      'Documenta l\'incidente (data, ora, testimoni)';

  @override
  String get fileComplaintOmbudsman =>
      'Presenta un reclamo al Garante contro la discriminazione';

  @override
  String get contactLegalAidOffice =>
      'Contatta un ufficio di assistenza legale';

  @override
  String get reportToPolice =>
      'Denuncia alla polizia se reato (minaccia, aggressione)';

  @override
  String get legalAidCalculator => 'Calcolatore assistenza legale';

  @override
  String checkEligibility(String country) {
    return 'Verifica la tua idoneità al patrocinio a spese dello Stato: $country';
  }

  @override
  String get estimateDisclaimer =>
      'Questa è solo una stima. L\'idoneità effettiva è determinata dall\'Ufficio di assistenza legale.';

  @override
  String get monthlyIncome => 'Reddito mensile (EUR)';

  @override
  String get totalAssets => 'Patrimonio totale (EUR)';

  @override
  String get numberOfDependents => 'Numero di persone a carico';

  @override
  String get calculateEligibility => 'Calcola idoneità';

  @override
  String get likelyEligible => 'Probabilmente idoneo';

  @override
  String get mayNotQualify => 'Potrebbe non essere idoneo';

  @override
  String get fullFreeLegalAid =>
      'Probabilmente hai diritto al patrocinio gratuito (senza compartecipazione).';

  @override
  String legalAidWithCopay(String percent) {
    return 'Potresti avere diritto all\'assistenza legale con una compartecipazione del $percent%.';
  }

  @override
  String get mayNotQualifyDesc =>
      'In base a questa stima, potresti non avere diritto al patrocinio statale. Considera un avvocato privato o un centro di consulenza legale.';

  @override
  String get couldNotLoadDeadlines => 'Impossibile caricare le scadenze';

  @override
  String get noUpcomingDeadlines => 'Nessuna scadenza imminente';

  @override
  String get allClearDeadlines =>
      'Tutto in ordine! Le nuove scadenze appariranno qui quando saranno impostate.';

  @override
  String get nothingOverdue => 'Nulla in ritardo';

  @override
  String get greatJobDeadlines => 'Ottimo lavoro nel rispettare le scadenze.';

  @override
  String get noCompletedDeadlines => 'Nessuna scadenza completata';

  @override
  String get completedDeadlinesDesc =>
      'Le scadenze completate verranno mostrate qui.';

  @override
  String get daysLate => 'giorni di ritardo';

  @override
  String get days => 'giorni';

  @override
  String get fromDocument => 'Dal documento';

  @override
  String get couldNotLoadCase => 'Impossibile caricare i dettagli del caso';

  @override
  String get typeLabel => 'Tipo';

  @override
  String get nationality => 'Nazionalità';

  @override
  String get migriReference => 'Riferimento Migri';

  @override
  String get courtCaseNo => 'N. fascicolo';

  @override
  String get created => 'Creato';

  @override
  String get citizenship => 'Cittadinanza';

  @override
  String get workPermit => 'Permesso di lavoro';

  @override
  String get noDocumentsYet => 'Nessun documento caricato';

  @override
  String get noUpcomingDeadlinesShort => 'Nessuna scadenza imminente';

  @override
  String get caseCreated => 'Caso creato';

  @override
  String get decisionReceived => 'Decisione ricevuta';

  @override
  String get appealDeadline => 'Scadenza ricorso';

  @override
  String get hearingScheduled => 'Udienza programmata';

  @override
  String get late => 'in ritardo';

  @override
  String get pending => 'In attesa';

  @override
  String get processing => 'Elaborazione';

  @override
  String get ready => 'Pronto';

  @override
  String get failed => 'Fallito';

  @override
  String get analyzed => 'Analizzato';

  @override
  String get noDocumentsScanHint =>
      'Nessun documento ancora. Scansiona o carica.';

  @override
  String get inCourt => 'In tribunale';

  @override
  String get appeal => 'Ricorso';

  @override
  String get caseTimeline => 'Cronologia del caso';

  @override
  String get couldNotLoadTimeline => 'Impossibile caricare la cronologia';

  @override
  String get noEventsYet => 'Nessun evento ancora';

  @override
  String get activityWillAppear =>
      'Le attività appariranno qui man mano che il caso procede.';

  @override
  String caseCreatedDesc(String title) {
    return 'Il caso «$title» è stato creato.';
  }

  @override
  String get decisionReceivedDesc =>
      'È stata ricevuta una decisione ufficiale per questo caso.';

  @override
  String get appealDeadlineSet => 'Scadenza ricorso impostata';

  @override
  String appealDeadlineDesc(String date) {
    return 'Il ricorso deve essere presentato entro il $date.';
  }

  @override
  String hearingScheduledDesc(String date) {
    return 'Udienza in tribunale programmata per $date.';
  }

  @override
  String get caseInfoUpdated =>
      'Le informazioni del caso sono state aggiornate.';

  @override
  String get noEventsForFilter => 'Nessun evento corrisponde a questo filtro';

  @override
  String get timelineFilterAll => 'Tutti';

  @override
  String get timelineFilterEmails => 'Email';

  @override
  String get timelineFilterConsilium => 'Decisioni IA';

  @override
  String get timelineFilterDeadlines => 'Scadenze';

  @override
  String get timelineFilterNotes => 'Note';

  @override
  String get timelineEventEmailIn => 'Email ricevuta';

  @override
  String get timelineEventEmailOut => 'Email inviata';

  @override
  String get timelineEventConsiliumDecision => 'Decisione IA';

  @override
  String get timelineEventDeadlineSet => 'Scadenza';

  @override
  String get timelineEventDocUploaded => 'Documento';

  @override
  String get timelineEventPhaseChange => 'Cambio di fase';

  @override
  String get timelineEventManualNote => 'Nota';

  @override
  String get timelineJustNow => 'Proprio ora';

  @override
  String timelineMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minuti fa',
      one: '1 minuto fa',
    );
    return '$_temp0';
  }

  @override
  String timelineHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ore fa',
      one: '1 ora fa',
    );
    return '$_temp0';
  }

  @override
  String timelineDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giorni fa',
      one: '1 giorno fa',
    );
    return '$_temp0';
  }

  @override
  String get documentAnalysis => 'Analisi del documento';

  @override
  String get exportAsPdf => 'Esporta come PDF';

  @override
  String get pdfExportComingSoon => 'Esportazione PDF in arrivo';

  @override
  String get analysisFailedRetry => 'Analisi fallita. Riprova.';

  @override
  String get somethingWentWrong => 'Qualcosa è andato storto';

  @override
  String get genericError => 'Qualcosa è andato storto. Riprova.';

  @override
  String get retryAnalysis => 'Riprova analisi';

  @override
  String issuesFoundInDocument(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Trovati $count problemi nel documento',
      one: 'Trovato 1 problema nel documento',
      zero: 'Nessun problema nel documento',
    );
    return '$_temp0';
  }

  @override
  String get severityOverview => 'Panoramica della gravità';

  @override
  String get issuesFoundHeader => 'Problemi trovati';

  @override
  String generateAppealWithIssues(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Genera ricorso ($count problemi)',
      one: 'Genera ricorso (1 problema)',
    );
    return '$_temp0';
  }

  @override
  String get analyzingContent => 'Analisi del contenuto…';

  @override
  String get documentProcessedOk => 'Documento elaborato con successo';

  @override
  String get noSignificantIssues =>
      'Nessun problema significativo rilevato in questo documento.';

  @override
  String get cameraPermissionRequired => 'Permesso fotocamera richiesto';

  @override
  String get cameraPermissionDesc =>
      'Consenti l\'accesso alla fotocamera per scansionare documenti o usa la galleria.';

  @override
  String get openSettings => 'Apri impostazioni';

  @override
  String get alignDocument => 'Allinea il documento nella cornice';

  @override
  String pageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pagine',
      one: '1 pagina',
      zero: 'nessuna pagina',
    );
    return '$_temp0';
  }

  @override
  String get preview => 'Anteprima';

  @override
  String pageNumber(int number) {
    return 'Pagina $number';
  }

  @override
  String get done => 'Fatto';

  @override
  String get retake => 'Rifai';

  @override
  String get useThisPhoto => 'Usa questa foto';

  @override
  String get addPage => 'Aggiungi pagina';

  @override
  String uploadingPercent(int percent) {
    return 'Caricamento… $percent%';
  }

  @override
  String get preparingUpload => 'Preparazione caricamento…';

  @override
  String get documentUploadedSuccess => 'Documento caricato con successo';

  @override
  String pagesUploadedSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pagine caricate con successo',
      one: '1 pagina caricata con successo',
    );
    return '$_temp0';
  }

  @override
  String get uploadFailed =>
      'Caricamento fallito. Controlla la connessione e riprova.';

  @override
  String get capturePhotoFailed => 'Impossibile scattare la foto. Riprova.';

  @override
  String get readingText => 'Lettura del testo…';

  @override
  String get draftDocument => 'Bozza documento';

  @override
  String get saveChanges => 'Salva modifiche';

  @override
  String get editDocument => 'Modifica documento';

  @override
  String get generatingDraft => 'Generazione della bozza…';

  @override
  String get generatingDraftDesc =>
      'L\'IA sta preparando un documento legale basato sui dettagli del tuo caso e sui problemi selezionati.';

  @override
  String get failedToGenerateDraft => 'Impossibile generare la bozza. Riprova.';

  @override
  String get changesSaved => 'Modifiche salvate';

  @override
  String get copiedToClipboard => 'Copiato negli appunti';

  @override
  String get emailComingSoon => 'Invio email in arrivo';

  @override
  String get reviewBeforeSending =>
      'Rivedi attentamente prima di inviare. Sei responsabile del contenuto di questo documento.';

  @override
  String get noContentAvailable => 'Nessun contenuto disponibile';

  @override
  String get save => 'Salva';

  @override
  String get edit => 'Modifica';

  @override
  String get pdf => 'PDF';

  @override
  String get copy => 'Copia';

  @override
  String get appealDraft => 'Bozza di ricorso';

  @override
  String selected(int count) {
    return '$count selezionati';
  }

  @override
  String get deleteSelected => 'Elimina selezionati';

  @override
  String deleteDocumentsConfirm(int count) {
    return 'Eliminare $count documenti?';
  }

  @override
  String get delete => 'Elimina';

  @override
  String get analyzeSelected => 'Analizza selezionati';

  @override
  String get batchAnalysisStarting => 'Avvio analisi in batch…';

  @override
  String get switchToList => 'Passa alla lista';

  @override
  String get switchToGrid => 'Passa alla griglia';

  @override
  String get scanNew => 'Nuova scansione';

  @override
  String get noDocumentsYetScan => 'Nessun documento ancora';

  @override
  String get scanFirstDocumentHint =>
      'Scansiona il tuo primo documento per far analizzare all\'IA gli errori e generare ricorsi.';

  @override
  String get failedToLoadDocuments => 'Impossibile caricare i documenti';

  @override
  String get emailIntegrationTitle => 'Integrazione email';

  @override
  String get connectYourEmail => 'Collega la tua email';

  @override
  String get connectYourEmailDesc =>
      'Collega la tua email per rilevare e organizzare automaticamente la corrispondenza legale relativa ai tuoi casi.';

  @override
  String get legalEmails => 'Email legali';

  @override
  String get unlinkedEmails => 'Email non collegate';

  @override
  String get noLegalEmailsYet => 'Nessuna email legale ancora';

  @override
  String get legalEmailsWillAppear =>
      'Le email classificate come legali appariranno qui.';

  @override
  String get assignToCase => 'Assegna al caso';

  @override
  String get disconnectEmail => 'Disconnetti email';

  @override
  String get disconnectEmailConfirm =>
      'La sincronizzazione automatica dell\'email verrà interrotta. Le email sincronizzate in precedenza rimarranno nei tuoi casi.';

  @override
  String get gmailReauthBannerBody =>
      'Advocat v2.1 legge la sua casella di posta per redigere le risposte; può revocare l\'accesso in qualsiasi momento. Riconnetta Gmail per abilitare la classificazione proattiva.';

  @override
  String get gmailReauthBannerCta => 'Riautorizza';

  @override
  String connectedTo(String email) {
    return 'Connesso a $email';
  }

  @override
  String lastSynced(String time) {
    return 'Ultima sincronizzazione: $time';
  }

  @override
  String get filterByType => 'Filtra per tipo';

  @override
  String get noCasesMatchSearch => 'Nessun caso corrisponde alla ricerca';

  @override
  String get failedToLoadCases => 'Impossibile caricare i casi';

  @override
  String get monthly => 'Mensile';

  @override
  String get annual => 'Annuale';

  @override
  String get saveTwentyFivePercent => 'Risparmia 25%';

  @override
  String get mostPopular => 'PIÙ POPOLARE';

  @override
  String get oneCaseActive => '1 caso attivo';

  @override
  String get threeCasesActive => '3 casi attivi';

  @override
  String get unlimitedCases => 'Casi illimitati';

  @override
  String get threeDocScans => '3 scansioni documenti';

  @override
  String get twentyDocScans => '20 scansioni documenti';

  @override
  String get unlimitedDocScans => 'Scansione documenti illimitata';

  @override
  String get basicAiAnalysis => 'Analisi IA di base';

  @override
  String get fullAiAnalysis => 'Analisi IA completa';

  @override
  String get draftGeneration => 'Generazione bozze';

  @override
  String get priorityProcessing => 'Elaborazione prioritaria';

  @override
  String get fiveAiMessagesTotal => '5 messaggi IA (a vita)';

  @override
  String get hundredAiMessagesDay => '100 messaggi IA/giorno';

  @override
  String get unlimitedAiMessages => 'Messaggi IA illimitati';

  @override
  String get voiceInput => 'Input vocale';

  @override
  String get strategyRecommendations => 'Raccomandazioni strategiche';

  @override
  String get foundingMemberNote =>
      'Membro fondatore: 9,99 €/mese per i primi 3 mesi';

  @override
  String get saveTwentyPercent => 'Risparmia il 20%';

  @override
  String get forever => 'per sempre';

  @override
  String get perMonth => '/mese';

  @override
  String get perYear => '/anno';

  @override
  String get checkingPurchases => 'Verifica acquisti precedenti…';

  @override
  String get noPreviousPurchases => 'Nessun acquisto precedente trovato.';

  @override
  String get chatWelcomeMessage =>
      'Hi! I\'m Advocat — your AI legal assistant. I provide legal information, not legal advice. What legal question can I help with?';

  @override
  String get copySummary => 'Copia riepilogo';

  @override
  String get caseSummaryCopied => 'Riepilogo del caso copiato';

  @override
  String get openCase => 'Apri caso';

  @override
  String get viewFull => 'Visualizza intero';

  @override
  String get draftCopiedToClipboard => 'Bozza copiata negli appunti';

  @override
  String get reportMileageFraud => 'Segnala frode chilometrica';

  @override
  String get reportMileageFraudDesc =>
      'Verrà creato un rapporto di frode basato sui dati di verifica del veicolo. Puoi anche aprire un caso legale.';

  @override
  String get reportAndOpenCase => 'Segnala e apri caso';

  @override
  String get caseCreationComingSoon =>
      'Creazione caso con dati precompilati in arrivo';

  @override
  String get failedToCreateCaseRetry => 'Impossibile creare il caso. Riprova.';

  @override
  String get takePhotoInstead => 'Scatta una foto';

  @override
  String get deleteCase => 'Elimina caso';

  @override
  String deleteCaseConfirm(String title) {
    return 'Sei sicuro di voler eliminare «$title»? Questa azione non può essere annullata.';
  }

  @override
  String get haveQuestionsAi => 'Domande? Chiedi all\'IA';

  @override
  String get cookiePolicy => 'Politica sui cookie';

  @override
  String get aiDisclaimer => 'Avviso sull\'IA';

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
  String get dataPrivacyConsent => 'Consenso alla privacy dei dati';

  @override
  String get gdprIntro =>
      'Per fornire assistenza legale tramite IA, elaboriamo i tuoi dati in conformità al GDPR (UE 2016/679). Continuando accetti:';

  @override
  String get gdprChat => 'Elaborazione dei messaggi chat dall\'IA';

  @override
  String get gdprDocs => 'Analisi dei documenti caricati';

  @override
  String get gdprStorage => 'Archiviazione crittografata dei dati dei casi';

  @override
  String get gdprDelete =>
      'Diritto di cancellare i tuoi dati in qualsiasi momento';

  @override
  String get gdprFooter =>
      'I tuoi dati sono crittografati e non vengono mai condivisi con terzi. Puoi revocare il consenso e cancellare tutti i dati dalle Impostazioni.';

  @override
  String get gdprConsentAiProcessing =>
      'Acconsento al trattamento dei miei dati per l\'assistenza legale IA (obbligatorio)';

  @override
  String get gdprConsentAnalytics =>
      'Acconsento all\'analisi dei dati per migliorare il servizio (facoltativo)';

  @override
  String get gdprArt9Intro =>
      'Questa app tratta categorie particolari di dati personali ai sensi dell\'articolo 9 del GDPR, tra cui:';

  @override
  String get gdprSpecialLegalCases =>
      'I dettagli del suo caso legale e i documenti giudiziari';

  @override
  String get gdprSpecialNationality => 'Nazionalità e status di immigrazione';

  @override
  String get gdprConsentLegalData =>
      'Acconsento al trattamento da parte dell\'IA dei dati del mio caso legale, della nazionalità e dello status di immigrazione (obbligatorio)';

  @override
  String get gdprConsentVoice =>
      'Acconsento al trattamento delle registrazioni vocali (facoltativo)';

  @override
  String get gdprViewPrivacyPolicy => 'Visualizza l\'informativa sulla privacy';

  @override
  String get legalInformation => 'Informazioni legali';

  @override
  String get legalEntityName => 'Vorantis OÜ';

  @override
  String get legalRegistryCode => 'Codice di registro: 17098992';

  @override
  String get legalAddress =>
      'Harju maakond, Tallinn, Kesklinna linnaosa, Tornimäe tn 5, 10145';

  @override
  String get legalEmail => 'Email: support@advocat.ee';

  @override
  String get legalRegistry =>
      'Iscritta al Registro delle imprese estone (Äriregister)';

  @override
  String get aiGeneratedDisclaimer => 'AI-generated • Not legal advice';

  @override
  String get decline => 'Rifiuta';

  @override
  String get iAgree => 'Accetto';

  @override
  String get iAgreeToThe => 'Accetto i ';

  @override
  String get orWord => 'o';

  @override
  String get english => 'Inglese';

  @override
  String get russian => 'Russo';

  @override
  String get finnish => 'Finlandese';

  @override
  String successSubscribed(String plan) {
    return 'Abbonamento a $plan riuscito!';
  }

  @override
  String paymentFailed(String error) {
    return 'Pagamento fallito: $error';
  }

  @override
  String get whatToDo => 'Cosa fare';

  @override
  String get getHelp => 'Ottenere aiuto';

  @override
  String get share => 'Condividi';

  @override
  String get didYouKnow => 'Lo sapevi?';

  @override
  String get mustKnow => 'Da sapere';

  @override
  String get goodToKnow => 'Utile sapere';

  @override
  String get sentFromAdvocat => 'Inviato dall\'app Advocat';

  @override
  String get policeActionStayCalm =>
      'Mantieni la calma e tieni le mani visibili';

  @override
  String get policeActionAskWhy =>
      'Chiedi all\'agente perché sei stato fermato';

  @override
  String get policeActionProvideName =>
      'Fornisci il tuo nome e data di nascita';

  @override
  String get policeActionWantLawyer =>
      'Dichiara chiaramente: «Voglio un avvocato prima di qualsiasi domanda»';

  @override
  String get policeActionAskInterpreter =>
      'Se necessario, chiedi un interprete';

  @override
  String get policeActionNoteBadge =>
      'Annota il nome e il numero di matricola dell\'agente';

  @override
  String get policeFactMustTellReason =>
      'In Finlandia, la polizia deve comunicarti il motivo del fermo. Se non lo fanno, puoi chiedere — e sono legalmente obbligati a spiegare.';

  @override
  String get policeFactCanRecord =>
      'Puoi registrare le interazioni con la polizia nei luoghi pubblici in Finlandia. Questo è protetto dalla libertà di espressione.';

  @override
  String get contactFinnishLegalAid => 'Assistenza legale finlandese';

  @override
  String get contactNonDiscriminationOmbudsman =>
      'Garante contro la discriminazione';

  @override
  String get deportationDeadlineAppeal =>
      'Ricorso al Tribunale Amministrativo — di solito 30 giorni dalla notifica';

  @override
  String get deportationDeadlineLegalAid =>
      'Richiedi il patrocinio a spese dello Stato — fallo IMMEDIATAMENTE';

  @override
  String get deportationFactStayDuringAppeal =>
      'In Finlandia, hai generalmente il diritto di restare nel paese durante la trattazione del ricorso. L\'espulsione non può essere eseguita durante un ricorso attivo nella maggior parte dei casi.';

  @override
  String get contactRefugeeAdviceCentre =>
      'Centro finlandese di consulenza per rifugiati';

  @override
  String get contactAdminCourtHelsinki =>
      'Tribunale Amministrativo di Helsinki';

  @override
  String get workplaceActionKeepContract =>
      'Conserva copie del tuo contratto di lavoro';

  @override
  String get workplaceActionTrackHours =>
      'Registra le tue ore lavorative in modo indipendente';

  @override
  String get workplaceActionReportUnsafe =>
      'Segnala le condizioni non sicure all\'ispettorato del lavoro';

  @override
  String get workplaceActionJoinUnion =>
      'Iscriviti a un sindacato per protezione';

  @override
  String get workplaceActionContactAuthority =>
      'Contatta l\'Autorità per la sicurezza sul lavoro se necessario';

  @override
  String get workplaceFactCollectiveWage =>
      'In Finlandia, i contratti collettivi stabiliscono i salari minimi per settore — non esiste un salario minimo nazionale unico. Il tuo datore di lavoro deve rispettare il contratto collettivo del tuo settore.';

  @override
  String get workplaceFactOralContract =>
      'Anche senza contratto scritto, hai pieni diritti da lavoratore in Finlandia. Un accordo orale è ugualmente vincolante per legge.';

  @override
  String get contactOccupationalSafety =>
      'Autorità per la sicurezza sul lavoro';

  @override
  String get contactTradeUnionSAK => 'Consulenza sindacale (SAK)';

  @override
  String get tenantActionWrittenAgreement =>
      'Avere sempre un contratto di locazione scritto';

  @override
  String get tenantActionDocumentCondition =>
      'Documentare le condizioni dell\'appartamento al momento del trasloco (foto)';

  @override
  String get tenantActionReportMaintenance =>
      'Segnalare i problemi di manutenzione per iscritto';

  @override
  String get tenantActionNoIllegalEviction =>
      'Non accettare mai uno sfratto illegale — i tribunali devono decidere';

  @override
  String get tenantActionContactAdvisory =>
      'Contattare un servizio di consulenza per inquilini in caso di controversie';

  @override
  String get tenantFactNoEvictionWithoutCourt =>
      'Un proprietario in Finlandia non può sfrattarti senza un\'ordinanza del tribunale, anche se il contratto è scaduto. Cambiare le serrature o tagliare le utenze è illegale.';

  @override
  String get contactTenantsAssociation =>
      'Associazione finlandese degli inquilini';

  @override
  String get contactConsumerDisputesBoard =>
      'Commissione per le controversie dei consumatori';

  @override
  String get detentionActionAskDecision =>
      'Chiedi immediatamente la decisione scritta di trattenimento';

  @override
  String get detentionActionRequestLawyer =>
      'Richiedi di contattare un avvocato';

  @override
  String get detentionActionContactEmbassy =>
      'Contatta la tua ambasciata o consolato';

  @override
  String get detentionActionAskMedical =>
      'Chiedi assistenza medica se necessario';

  @override
  String get detentionActionRequestInterpreter =>
      'Richiedi un interprete per tutti i procedimenti';

  @override
  String get detentionDeadlineCourtReview =>
      'Il tribunale distrettuale deve esaminare il trattenimento entro 4 giorni';

  @override
  String get detentionDeadlineContinuation =>
      'Il tribunale esamina il rinnovo ogni 2 settimane';

  @override
  String get detentionFactCourtReview =>
      'Il trattenimento per immigrazione in Finlandia deve essere esaminato da un tribunale distrettuale entro 4 giorni. Se ciò non avviene, il trattenimento diventa illegale.';

  @override
  String get contactParliamentaryOmbudsman => 'Difensore civico parlamentare';

  @override
  String get discriminationActionWriteDown =>
      'Scrivi esattamente cosa è successo (data, ora, luogo)';

  @override
  String get discriminationActionSaveEvidence =>
      'Conserva le prove: messaggi, email, testimoni';

  @override
  String get discriminationActionFileComplaint =>
      'Presenta un reclamo al Garante contro la discriminazione';

  @override
  String get discriminationActionContactLegalAid =>
      'Contatta un ufficio di assistenza legale per consulenza gratuita';

  @override
  String get discriminationActionReportPolice =>
      'Denuncia alla polizia in caso di minacce o aggressione';

  @override
  String get discriminationFactNonDiscriminationAct =>
      'La legge finlandese sulla non discriminazione copre la discriminazione basata su età, origine, nazionalità, lingua, religione, salute, disabilità, orientamento sessuale e altre caratteristiche personali.';

  @override
  String get contactVictimSupportRIKU => 'Supporto vittime Finlandia (RIKU)';

  @override
  String get domesticViolence => 'Violenza domestica';

  @override
  String get domesticViolenceDesc =>
      'Diritti delle vittime, aiuto d\'emergenza, ordini restrittivi';

  @override
  String get rightCallEmergency =>
      'Ha il diritto di chiamare il 112 in qualsiasi emergenza — polizia, ambulanza, vigili del fuoco';

  @override
  String get rightVictimProtection =>
      'In quanto vittima, ha diritto a protezione, sostegno e informazioni sul suo caso';

  @override
  String get rightRestrainingOrder =>
      'Può richiedere un ordine restrittivo (lähestymiskielto) per tenere lontano l\'aggressore';

  @override
  String get rightVictimInterpreter =>
      'Ha diritto a un interprete durante tutti i procedimenti legali';

  @override
  String get rightMedicalHelp =>
      'Ha diritto a cure mediche immediate e alla documentazione delle lesioni';

  @override
  String get rightShelter =>
      'Ha diritto a un rifugio d\'emergenza — contatti una casa rifugio o i servizi sociali';

  @override
  String get mustReportDanger =>
      'Se qualcuno è in pericolo immediato, chiami subito il 112';

  @override
  String get mustDocumentInjuries =>
      'Documenti tutte le lesioni — foto, referti medici, annotazioni scritte';

  @override
  String get domesticActionCallEmergency =>
      'Chiami il 112 se è in pericolo immediato';

  @override
  String get domesticActionGoToSafe =>
      'Si rechi in un luogo sicuro — rifugio, amico, luogo pubblico';

  @override
  String get domesticActionDocumentEverything =>
      'Documenti le lesioni: scatti foto, ottenga referti medici';

  @override
  String get domesticActionFilePoliceReport =>
      'Presenti una denuncia alla polizia — può farlo anche in seguito';

  @override
  String get domesticActionContactShelter =>
      'Contatti una casa rifugio o una linea di assistenza per le crisi';

  @override
  String get domesticActionApplyRestraining =>
      'Richieda un ordine restrittivo tramite la polizia o il tribunale';

  @override
  String get domesticFactRestrainingOrder =>
      'In Finlandia, un ordine restrittivo (lähestymiskielto) può essere emesso anche senza un procedimento penale. Vieta alla persona di contattarla o di avvicinarsi a lei.';

  @override
  String get domesticFactVictimDirective =>
      'Ai sensi della direttiva UE sulle vittime 2012/29/UE, ha il diritto di essere trattata con rispetto, di ricevere informazioni in una lingua che comprende e di accedere ai servizi di assistenza alle vittime — indipendentemente dal suo status di residenza.';

  @override
  String get domesticDeadlinePoliceReport =>
      'Presentazione della denuncia alla polizia — nessun termine perentorio, ma prima è meglio per le prove';

  @override
  String get domesticDeadlineRestraining =>
      'Ordine restrittivo — può essere richiesto in qualsiasi momento';

  @override
  String get contactEmergency => 'Numero d\'emergenza';

  @override
  String get contactShelter => 'Linea di assistenza Turvakoti (casa rifugio)';

  @override
  String get contactCrisisHelpline =>
      'Linea di assistenza per le crisi (Kriisipuhelin)';

  @override
  String get contactNollaLinja =>
      'Nollalinja — Linea di assistenza per la violenza contro le donne';

  @override
  String get inheritance => 'Eredità';

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
  String get consumerProtection => 'Tutela dei consumatori';

  @override
  String get consumerProtectionDesc =>
      'Frodi, prodotti difettosi, resi, venditori ingannevoli';

  @override
  String get rightReturnOnline =>
      'Ha 14 giorni per annullare gli acquisti online senza motivazione (diritto di recesso UE)';

  @override
  String get rightDefectiveProduct =>
      'Se un prodotto è difettoso, ha diritto alla riparazione, alla sostituzione o al rimborso';

  @override
  String get rightClearPricing =>
      'I venditori devono indicare prezzi chiari comprensivi di tutti i costi — i costi nascosti sono illegali';

  @override
  String get rightComplainBoard =>
      'Può presentare un reclamo gratuito alla Commissione per le controversie dei consumatori';

  @override
  String get rightProtectionFraud =>
      'È tutelato contro le pratiche commerciali scorrette e le frodi';

  @override
  String get mustKeepReceipts =>
      'Conservi tutte le ricevute, i contratti e le comunicazioni con i venditori';

  @override
  String get mustActTimely =>
      'Segnali i difetti al venditore entro un tempo ragionevole dalla scoperta';

  @override
  String get consumerActionKeepEvidence =>
      'Conservi ricevute, screenshot, email e ogni prova d\'acquisto';

  @override
  String get consumerActionContactSeller =>
      'Contatti prima il venditore — spieghi il problema per iscritto';

  @override
  String get consumerActionFileComplaint =>
      'Presenti un reclamo alla Commissione per le controversie dei consumatori (kuluttajariitalautakunta)';

  @override
  String get consumerActionContactAuthority =>
      'Contatti i Servizi di consulenza ai consumatori per assistenza gratuita';

  @override
  String get consumerActionReportFraud =>
      'Segnali la frode alla polizia e al Difensore civico dei consumatori';

  @override
  String get consumerFactWithdrawal =>
      'Ai sensi della direttiva UE sui diritti dei consumatori 2011/83/UE, ha 14 giorni per recedere da qualsiasi acquisto online o a distanza — senza dover fornire spiegazioni. Il venditore deve rimborsarla entro 14 giorni.';

  @override
  String get consumerFactWarranty =>
      'In Finlandia, il venditore è responsabile dei difetti del prodotto per un periodo ragionevole (spesso 2 anni o più). Ciò è distinto da qualsiasi garanzia del produttore.';

  @override
  String get consumerDeadlineWithdrawal =>
      'Recesso dall\'acquisto online — 14 giorni dalla consegna';

  @override
  String get consumerDeadlineDefect =>
      'Segnalazione del difetto al venditore — entro 2 mesi dalla scoperta (consigliato)';

  @override
  String get contactConsumerAdvisory => 'Servizi di consulenza ai consumatori';

  @override
  String get contactConsumerOmbudsman =>
      'Difensore civico dei consumatori (Kuluttaja-asiamies)';

  @override
  String get contactConsumerDisputesBoardDirect =>
      'Commissione per le controversie dei consumatori';

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
  String get comingSoon => 'In arrivo';

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
      other: '$count diritti inclusi',
      one: '1 diritto incluso',
      zero: 'nessun diritto incluso',
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
      'Assistente IA · non è consulenza legale';

  @override
  String get chatDisclaimerBannerFull =>
      'Advocat è un assistente IA di informazione giuridica, non un avvocato. Le informazioni qui non creano un rapporto avvocato-cliente, non costituiscono consulenza legale e possono essere errate. Per consulenza legale vincolante, rivolgersi a un avvocato abilitato nella propria giurisdizione. Non vi rappresentiamo.';

  @override
  String get chatDisclaimerFooter =>
      'Generato dall\'IA. Verificare con un avvocato abilitato.';

  @override
  String get chatDisclaimerGotIt => 'Capito';

  @override
  String get categoryChildren => 'Minori';

  @override
  String get categoryDigital => 'Digitale';

  @override
  String get childrenRights => 'Diritti dei minori e mantenimento';

  @override
  String get childrenRightsDesc =>
      'Mantenimento dei figli, alimenti, protezione, garanzie statali';

  @override
  String get cyberbullying => 'Cyberbullismo e molestie online';

  @override
  String get cyberbullyingDesc =>
      'Minacce, violazioni della privacy, diffamazione online';

  @override
  String get rightChildSupport =>
      'Entrambi i genitori sono giuridicamente obbligati a mantenere economicamente il figlio (Perekonnaseadus § 100–102)';

  @override
  String get rightMinimumAlimony =>
      'Mantenimento minimo dei figli in Estonia: importo base (295,86 €) + 3% dello stipendio lordo medio dell\'anno precedente (PKS § 101). Dal 01.04.2026 — 318,62 €/mese per figlio. Aggiornato annualmente il 1° aprile. Calcolatore: alimendid.ee';

  @override
  String get rightCourtAlimony =>
      'Può richiedere gli alimenti presso il tribunale di contea (maakohus) — non è richiesto un avvocato per le domande fino a 6.400 €';

  @override
  String get rightBailiffEnforcement =>
      'Se il genitore si rifiuta di pagare, un ufficiale giudiziario (kohtutäitur) può eseguire l\'ordine del tribunale, incluso il pignoramento dello stipendio';

  @override
  String get rightStateAlimonyGuarantee =>
      'Se il genitore non paga, lo Stato fornisce l\'elatisabi (assegno di mantenimento) tramite il Sotsiaalkindlustusamet — fino a 100 €/mese per figlio';

  @override
  String get rightChildEducation =>
      'Ogni minore ha diritto all\'istruzione, all\'assistenza sanitaria e alla protezione dagli abusi (Lastekaitseseadus § 4–5)';

  @override
  String get rightChildContact =>
      'Un minore ha diritto a mantenere i contatti con entrambi i genitori, salvo diversa decisione del tribunale (PKS § 143)';

  @override
  String get mustFileCourtClaim =>
      'Per ricevere gli alimenti, deve presentare una domanda al tribunale o concordare l\'importo per iscritto';

  @override
  String get mustNotifyAddressChange =>
      'Comunichi al Sotsiaalkindlustusamet i cambi di indirizzo se riceve l\'elatisabi';

  @override
  String get childrenActionGatherDocs =>
      'Raccolga il certificato di nascita del minore, il suo documento d\'identità e le prove delle spese';

  @override
  String get childrenActionFileCourtClaim =>
      'Presenti una domanda di alimenti al tribunale di contea (maakohus) — è possibile farlo online tramite e-toimik';

  @override
  String get childrenActionApplyElatisabi =>
      'Richieda la garanzia statale per gli alimenti (elatisabi) al Sotsiaalkindlustusamet se il genitore non paga';

  @override
  String get childrenActionContactBailiff =>
      'Contatti un ufficiale giudiziario (kohtutäitur) per eseguire l\'ordine del tribunale';

  @override
  String get childrenActionCallLasteabi =>
      'Chiami Lasteabi 116 111 per la linea di assistenza ai minori — gratuita, 24 ore su 24, 7 giorni su 7';

  @override
  String get childrenDeadlineElatisabi =>
      'Richiesta di elatisabi — dopo l\'ordine del tribunale, nessun termine perentorio ma la procedura richiede tempo';

  @override
  String get childrenDeadlineCourt =>
      'Gli alimenti possono essere richiesti retroattivamente fino a 1 anno prima del deposito della domanda in tribunale';

  @override
  String get childrenFactMinimum =>
      'Dal 01.04.2026 il mantenimento minimo dei figli è di 318,62 €/mese per figlio. Formula: importo base (295,86 €) + 3% dello stipendio lordo medio dell\'anno precedente. Aggiornato annualmente il 1° aprile. Un genitore non può accordarsi per pagare meno. Calcolatore: alimendid.ee';

  @override
  String get childrenFactElatisabi =>
      'La garanzia statale estone per gli alimenti (elatisabi) è stata introdotta nel 2017 per tutelare i minori quando un genitore si rifiuta di pagare. Lo Stato paga e poi recupera l\'importo dal genitore debitore.';

  @override
  String get rightReportCybercrime =>
      'Ha il diritto di denunciare alla polizia minacce online, molestie e furti d\'identità (Karistusseadustik § 120, § 157¹)';

  @override
  String get rightContentRemoval =>
      'Può richiedere la rimozione di contenuti diffamatori o privati dalle piattaforme ed esigerne la cancellazione ai sensi del GDPR';

  @override
  String get rightMoralDamageCompensation =>
      'Può richiedere il risarcimento del danno morale causato dal cyberbullismo (Võlaõigusseadus § 1043–1055)';

  @override
  String get rightPrivacyProtection =>
      'La sua vita privata è tutelata — la condivisione non autorizzata delle sue foto, dei suoi messaggi o dei suoi dati personali è illegale (KarS § 157)';

  @override
  String get rightDataProtection =>
      'Segnali le violazioni della protezione dei dati (uso non autorizzato dei suoi dati) all\'Andmekaitse Inspektsioon';

  @override
  String get rightDefamationAction =>
      'La diffamazione (laimamine) è un illecito civile — può citare in giudizio per i danni ed esigere una ritrattazione pubblica (KarS § 247 (abrogato), VÕS § 1047)';

  @override
  String get mustCollectEvidence =>
      'Raccolga e conservi tutte le prove — screenshot, link, date e informazioni sui testimoni';

  @override
  String get mustNotRetaliate =>
      'Non reagisca né si dedichi a contro-molestie — ciò potrebbe indebolire il suo caso';

  @override
  String get cyberActionScreenshots =>
      'Faccia screenshot di tutte le molestie — salvi URL, date, nomi utente e contenuti';

  @override
  String get cyberActionReportPolice =>
      'Presenti una denuncia alla polizia presso la stazione più vicina o online su politsei.ee';

  @override
  String get cyberActionReportPlatform =>
      'Segnali il contenuto alla piattaforma di social media per la rimozione';

  @override
  String get cyberActionContactDPA =>
      'Contatti l\'Andmekaitse Inspektsioon se i suoi dati personali sono stati utilizzati impropriamente';

  @override
  String get cyberActionConsultLawyer =>
      'Si rivolga a un avvocato per i danni civili — l\'assistenza legale gratuita è disponibile tramite Riigi Õigusabi';

  @override
  String get cyberDeadlineCriminal =>
      'Denuncia penale — nessun termine perentorio, ma denunci tempestivamente per ottenere i migliori risultati';

  @override
  String get cyberDeadlineCivil =>
      'Domanda civile di risarcimento — fino a 3 anni da quando è venuto a conoscenza della violazione (TsÜS § 150)';

  @override
  String get cyberFactPrivacy =>
      'In Estonia, la condivisione non autorizzata di immagini intime di una persona può comportare fino a 3 anni di reclusione ai sensi del Karistusseadustik § 157¹ (violazione della privacy).';

  @override
  String get cyberFactGDPR =>
      'Ai sensi del GDPR, ha il “diritto all\'oblio” — le piattaforme devono cancellare i suoi dati personali su richiesta se non vi è alcuna base giuridica per conservarli.';

  @override
  String get guestUser => 'Ospite';

  @override
  String get howToUse => 'Come usare?';

  @override
  String get tutorialStep1Title => 'Assistente legale IA';

  @override
  String get tutorialStep1Desc =>
      'Fai qualsiasi domanda legale e ottieni risposte immediate basate sul diritto estone.';

  @override
  String get tutorialStep2Title => 'Conosci i tuoi diritti';

  @override
  String get tutorialStep2Desc =>
      'Sfoglia le informazioni legali per argomento — lavoro, alloggio, diritti dei consumatori e altro.';

  @override
  String get tutorialStep3Title => 'Scansiona documenti';

  @override
  String get tutorialStep3Desc =>
      'Scatta foto di documenti legali per l\'analisi IA e l\'archiviazione sicura.';

  @override
  String get tutorialStep4Title => 'Iniziamo!';

  @override
  String get tutorialStep4Desc =>
      'Esplora l\'app e proteggi i tuoi diritti. Tutti i dati rimangono privati sul tuo dispositivo.';

  @override
  String get advocatProTitle => 'Advocat Pro';

  @override
  String get advocatProSubtitle => 'Sblocca le funzionalità premium';

  @override
  String get voiceDisclaimer =>
      'L\'assistente vocale funziona attualmente solo su desktop (browser Chrome). Supporto mobile in arrivo.';

  @override
  String get recommended => 'Consigliato';

  @override
  String get pleaseLogIn => 'Effettua l\'accesso';

  @override
  String get subscriptionNotFound => 'Abbonamento non trovato';

  @override
  String errorWithMessage(String message) {
    return 'Errore: $message';
  }

  @override
  String get redirectingToPayment =>
      'Reindirizzamento alla pagina di pagamento…';

  @override
  String cheaperAnnually(String amount) {
    return '€$amount/mese in meno con l\'abbonamento annuale';
  }

  @override
  String get navigatingTo => 'Apertura di';

  @override
  String get stayInChat => 'Resta nella chat';

  @override
  String get backToChat => 'Torna alla chat';

  @override
  String get upgradeBannerTitle =>
      'Effettui l\'upgrade per consulenze illimitate';

  @override
  String get upgradeBannerCta => 'Effettua l\'upgrade';

  @override
  String get paymentSuccessTitle => 'Pagamento riuscito';

  @override
  String get paymentSuccessBody => 'Il suo abbonamento è ora attivo.';

  @override
  String get commonOk => 'OK';

  @override
  String get feedbackThumbsUpLabel => 'Utile';

  @override
  String get feedbackThumbsDownLabel => 'Non utile';

  @override
  String get feedbackCommentPrompt => 'Cosa non andava?';

  @override
  String get feedbackSend => 'Invia';

  @override
  String get feedbackCancel => 'Annulla';

  @override
  String get reasoningPillIdle => 'Sto pensando…';

  @override
  String get reasoningPillSearchingLaw => 'Ricerca nella legge estone…';

  @override
  String get reasoningPillSearchingWeb => 'Ricerca sul web…';

  @override
  String get reasoningPillCheckingCompany =>
      'Verifica nel registro delle imprese…';

  @override
  String get reasoningPillCheckingVehicle =>
      'Verifica nel registro dei veicoli…';

  @override
  String get reasoningPillReadingDocument => 'Lettura del suo documento…';

  @override
  String get reasoningPillDrafting => 'Redazione del documento…';

  @override
  String get reasoningPillPreparingEmail => 'Preparazione dell\'email…';

  @override
  String get reasoningPillFindingLawyer => 'Ricerca di avvocati…';

  @override
  String get reasoningPillThinking => 'Analisi del suo caso…';

  @override
  String get reasoningPillFinalising => 'Composizione della sua risposta…';

  @override
  String reasoningCollapsedFormat(int sec, int sources) {
    return 'Ragionamento per ${sec}s · $sources fonti';
  }

  @override
  String get reasoningExpandHint => 'tocca per vedere i passaggi';

  @override
  String get caseFileTitle => 'Fascicolo del caso';

  @override
  String get caseFileTimeline => 'Cronologia';

  @override
  String get caseFileParties => 'Parti';

  @override
  String get caseFileDeadlines => 'Scadenze';

  @override
  String get caseFileExportPdf => 'Scarica il fascicolo (PDF)';

  @override
  String get caseFileEmpty =>
      'Parli con l\'IA del suo caso — la sua cronologia si costruirà da sola.';

  @override
  String get caseFileDisclaimer =>
      'Questo fascicolo è estratto automaticamente dalla sua chat. Non costituisce consulenza legale.';

  @override
  String get caseFileTabLabel => 'Caso';

  @override
  String get refresh => 'Aggiorna';

  @override
  String get demoLimitReached =>
      'Limite della demo raggiunto. Si registri gratuitamente per continuare.';

  @override
  String get demoLimitSignUpCta => 'Registrati';

  @override
  String freeQuotaExhausted(int count) {
    return 'Ha utilizzato tutti i $count messaggi gratuiti di questo mese.';
  }

  @override
  String get upgradeForUnlimited => 'Passi a Pro per messaggi illimitati';

  @override
  String get upgradeCta => 'Effettua l\'upgrade';

  @override
  String get rateLimitTryAgain =>
      'Invio troppo rapido. Riprovi tra qualche secondo.';

  @override
  String get quickProfilePrompt =>
      'Per poterla aiutare in modo più preciso, qual è il suo status giuridico: è un cittadino estone, un cittadino UE di un altro Paese o è titolare di un permesso di soggiorno?';

  @override
  String get quickProfileChipEstonianCitizen => 'Cittadino estone';

  @override
  String get quickProfileChipEuCitizen => 'Cittadino UE (altro)';

  @override
  String get quickProfileChipResidencePermit => 'Permesso di soggiorno';

  @override
  String get quickProfileSkipBtn => 'Salta';

  @override
  String get quickProfileSavedAck => 'Ricevuto. Ora, qual è la sua domanda?';

  @override
  String get caseTitleLabel => 'Titolo del caso';

  @override
  String get jurisdictionLabel => 'Giurisdizione';

  @override
  String get caseTypeLabel => 'Tipo di caso';

  @override
  String get caseLanguageLabel => 'Lingua';

  @override
  String get caseNumbersSection => 'Numeri di causa';

  @override
  String get partiesSection => 'Parti';

  @override
  String get authoritiesSection => 'Autorità';

  @override
  String get timelineSection => 'Cronologia';

  @override
  String get openQuestionsSection => 'Questioni aperte';

  @override
  String get nextActionsSection => 'Azioni successive';

  @override
  String get summarySection => 'Riepilogo';

  @override
  String get addRow => 'Aggiungi riga';

  @override
  String get removeRow => 'Rimuovi';

  @override
  String get archiveCase => 'Archivia caso';

  @override
  String get closeCase => 'Chiudi caso';

  @override
  String get continueChatAboutCase => 'Continua la chat su questo caso';

  @override
  String get linkChatToCase => 'Collega al caso';

  @override
  String get clearActiveCase => 'Cancella caso attivo';

  @override
  String get caseSavedAck => 'Caso salvato';

  @override
  String get caseArchivedAck => 'Caso archiviato';

  @override
  String get intakeStep1Title => 'Dove si trova il caso?';

  @override
  String get intakeStep1Subtitle => 'Paese e autorità con cui ha a che fare.';

  @override
  String get intakeJurisdictionLabel => 'Paese / giurisdizione';

  @override
  String get intakeAuthorityLabel => 'Tipo di autorità';

  @override
  String get intakeAuthorityNameLabel => 'Nome dell\'autorità (facoltativo)';

  @override
  String get intakeAuthorityPolice => 'Polizia';

  @override
  String get intakeAuthorityCourt => 'Tribunale';

  @override
  String get intakeAuthoritySocial => 'Servizi sociali';

  @override
  String get intakeAuthorityEmployer => 'Datore di lavoro';

  @override
  String get intakeAuthorityLandlord => 'Locatore';

  @override
  String get intakeAuthorityOpposingParty => 'Controparte';

  @override
  String get intakeAuthorityOther => 'Altro';

  @override
  String get intakeStep2Title => 'Che tipo di caso?';

  @override
  String get intakeStep2Subtitle =>
      'Scelga il tipo più simile — potrà precisarlo in seguito.';

  @override
  String get intakeCaseTypeCriminal => 'Penale';

  @override
  String get intakeCaseTypeCivil => 'Civile';

  @override
  String get intakeCaseTypeFamily => 'Famiglia';

  @override
  String get intakeCaseTypeAdmin => 'Amministrativo';

  @override
  String get intakeCaseTypeImmigration => 'Immigrazione';

  @override
  String get intakeCaseTypeLabor => 'Lavoro';

  @override
  String get intakeCaseTypeConsumer => 'Consumatori';

  @override
  String get intakeCaseTypeInheritance => 'Successioni';

  @override
  String get intakeCaseTypeOther => 'Altro';

  @override
  String get intakeStep3Title => 'Chi è coinvolto?';

  @override
  String get intakeStep3Subtitle => 'Il suo ruolo e la controparte.';

  @override
  String get intakeRoleLabel => 'Il suo ruolo';

  @override
  String get intakeRolePlaintiff => 'Attore';

  @override
  String get intakeRoleDefendant => 'Convenuto';

  @override
  String get intakeRoleVictim => 'Vittima';

  @override
  String get intakeRoleAccused => 'Imputato';

  @override
  String get intakeRoleWitness => 'Testimone';

  @override
  String get intakeRoleFamily => 'Familiare';

  @override
  String get intakeRoleOther => 'Altro';

  @override
  String get intakeOpposingSideLabel => 'Controparte (facoltativo)';

  @override
  String get intakeWitnessesLabel => 'Testimoni (facoltativo)';

  @override
  String get intakeAddWitness => 'Aggiungi testimone';

  @override
  String get intakeWitnessHint => 'Nome o contatto';

  @override
  String get intakeStep4Title => 'Numeri e date';

  @override
  String get intakeStep4Subtitle =>
      'Tutto ciò che ha già a disposizione. Salti ciò che non ha.';

  @override
  String get intakeCaseNumberLabel => 'Numero di causa (facoltativo)';

  @override
  String get intakeIncidentDateLabel => 'Data dell\'incidente (facoltativo)';

  @override
  String get intakeIncidentDatePick => 'Scegli data';

  @override
  String get intakeDeadlinesLabel => 'Scadenze note';

  @override
  String get intakeAddDeadline => 'Aggiungi scadenza';

  @override
  String get intakeDeadlineWhatHint => 'Cosa';

  @override
  String get intakeStep5Title => 'Documenti';

  @override
  String get intakeStep5Subtitle =>
      'Carichi tutto ciò che è rilevante. Lo leggeremo.';

  @override
  String get intakeUploadDocsLabel => 'Carica documenti';

  @override
  String get intakeSkipDocs => 'Salta — caricherò in seguito';

  @override
  String get intakeNextBtn => 'Avanti';

  @override
  String get intakeBackBtn => 'Indietro';

  @override
  String get intakeFinishBtn => 'Termina e apri la chat';

  @override
  String get intakeUrgentBtn => 'Urgente — chiedi ora';

  @override
  String get intakeUrgentDialogTitle => 'Aprire la chat ora?';

  @override
  String get intakeUrgentDialogBody =>
      'Salveremo quanto ha inserito come caso in bozza. Potrà completare la procedura guidata dalla pagina del caso in qualsiasi momento.';

  @override
  String get intakeUrgentConfirm => 'Apri la chat';

  @override
  String get intakeUrgentCancel => 'Continua a compilare';

  @override
  String get intakePreparingCase => 'Preparazione del suo caso…';

  @override
  String get intakeFallbackGreeting =>
      'Vedo il suo caso. Mi dica qual è la questione più urgente — la affronteremo insieme.';

  @override
  String get intakeUrgentGreeting =>
      'Vedo che è urgente. Faccia la sua domanda — compilerò il resto man mano.';

  @override
  String intakeStepIndicator(int current, int total) {
    return 'Passaggio $current di $total';
  }

  @override
  String get intakeFieldRequired => 'Obbligatorio';

  @override
  String intakeUploadProgress(int done, int total) {
    return 'Caricamento $done / $total…';
  }

  @override
  String get uplDisclaimerFooter =>
      'Advocat non è uno studio legale. Queste sono informazioni, non consulenza legale.';

  @override
  String get citationStatusVerifiedBadge => 'Verificata';

  @override
  String get citationStatusUnverifiedBadge => 'Non verificata';

  @override
  String get citationStatusHistoricalBadge => 'Versione storica';

  @override
  String get citationStatusVerifiedTooltip =>
      'Citata da una fonte normativa recuperata.';

  @override
  String get citationStatusUnverifiedTooltip =>
      'L\'IA ha citato questo passaggio senza recuperare la fonte — verificare prima di farvi affidamento.';

  @override
  String get citationStatusHistoricalTooltip =>
      'La disposizione citata non è più in vigore.';

  @override
  String get citationOpenInRiigiTeataja => 'Apri in Riigi Teataja';

  @override
  String get citationSnippetExpand => 'Mostra testo completo';

  @override
  String get citationSnippetCollapse => 'Mostra meno';

  @override
  String get citationUnverifiedSheetNote =>
      'L\'IA ha citato questo paragrafo, ma non è stato recuperato dal corpus normativo in questa interazione. Verificare il riferimento prima di farvi affidamento.';

  @override
  String get citationFooterNoneWarning => 'Nessuna citazione documentata';

  @override
  String citationFooterSummaryTotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count citazioni',
      one: '1 citazione',
    );
    return '$_temp0';
  }

  @override
  String citationFooterSummaryVerified(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count verificate',
      one: '1 verificata',
    );
    return '$_temp0';
  }

  @override
  String citationFooterSummaryUnverified(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count non verificate',
      one: '1 non verificata',
    );
    return '$_temp0';
  }

  @override
  String citationFooterSummaryHistorical(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count storiche',
      one: '1 storica',
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
      other: 'tra $count giorni',
      one: 'tra 1 giorno',
      zero: 'oggi',
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
      other: '$count giorni di ritardo',
      one: '1 giorno di ritardo',
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
    return 'Il consilium raccomanda $count azioni parallele';
  }

  @override
  String get parallelActionsApproveAll => 'Approva tutte e invia';

  @override
  String parallelActionsApproveSelected(int count, int total) {
    return 'Approva $count di $total';
  }

  @override
  String parallelActionsConfirmTitle(int count) {
    return 'Inviare $count email?';
  }

  @override
  String parallelActionsConfirmBody(int count) {
    return 'Advocat invierà $count risposte preparate tramite il suo Gmail collegato. Ciascuna viene inviata in modo indipendente — se una non va a buon fine, le altre vengono comunque inviate.';
  }

  @override
  String parallelActionsSentToast(int count) {
    return '$count inviate.';
  }

  @override
  String parallelActionsPartialFailureToast(int sent, int failed) {
    return '$sent inviate, $failed non riuscite.';
  }

  @override
  String get parallelActionsKindReply => 'risposta';

  @override
  String get parallelActionsKindNew => 'nuova';

  @override
  String get parallelActionsCheckboxSelected => 'Azione selezionata';

  @override
  String get parallelActionsCheckboxUnselected => 'Azione non selezionata';

  @override
  String parallelActionsCitationCount(int count) {
    return '$count cit.';
  }

  @override
  String parallelActionsRetryFailed(int count) {
    return 'Riprova le non riuscite ($count)';
  }

  @override
  String get agentApprovalNeedsReviewTitle =>
      'Advocat necessita della sua approvazione';

  @override
  String get agentApprovalResolvedTitle => 'Azione risolta';

  @override
  String get agentApprovalStepsLabel => 'passaggi';

  @override
  String get agentApprovalApproveButton => 'Approva e invia';

  @override
  String get agentApprovalDeclineButton => 'Rifiuta';

  @override
  String get agentApprovalAttachmentsLabel => 'Allegati';

  @override
  String get agentApprovalSentSummary => 'Inviato per suo conto.';

  @override
  String get agentApprovalDeclinedSummary =>
      'Rifiutato — non è stato inviato nulla.';

  @override
  String get agentToolDraftEmailAtt => 'Invia email con allegati';

  @override
  String get agentToolSendEmail => 'Invia email';

  @override
  String get agentToolGeneratePdf => 'Genera PDF';

  @override
  String get agentToolApproveSend => 'Invia la risposta preparata';

  @override
  String get inboxErrorTitle => 'Impossibile caricare la casella di posta';

  @override
  String get inboxEditDiscardTitle => 'Eliminare le modifiche non salvate?';

  @override
  String get inboxEditDiscardBody =>
      'Ha modifiche non salvate a questa bozza. Tornando indietro andranno perse.';

  @override
  String get inboxEditKeepEditing => 'Continua a modificare';

  @override
  String get inboxEditDiscard => 'Elimina';

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
  String get plannerSettingsTitle => 'Ragionamento legale in tre passaggi';

  @override
  String get plannerSettingsSubtitle =>
      'Pianifica → rispondi → critica. Più lento ma più approfondito.';

  @override
  String get plannerSettingsProBadge => 'Pro';

  @override
  String get plannerSettingsProDescription => 'Disponibile con il piano Pro';

  @override
  String get plannerTrailHeaderPlan => 'Piano';

  @override
  String get plannerTrailHeaderCritique => 'Critica';

  @override
  String get plannerTrailSubQuestions => 'Sotto-domande';

  @override
  String get plannerTrailCounterArgs => 'Controargomentazioni';

  @override
  String get plannerTrailEvidenceGaps => 'Lacune probatorie';

  @override
  String get plannerTrailMaterialGapTrue => 'Rilevata lacuna sostanziale';

  @override
  String get plannerTrailRegeneratedBadge => 'Rigenerato una volta';

  @override
  String get plannerTrailEmpty => 'nessun elemento';

  @override
  String get supportTitle => 'Aiuto';

  @override
  String get supportSubtitle => 'Di solito rispondiamo entro 1-2 ore.';

  @override
  String get supportSearchPlaceholder => 'Cerca aiuto…';

  @override
  String get supportStatusAllOk => 'Tutti i sistemi funzionano normalmente';

  @override
  String get supportFaqWhatIs => 'Cos\'è Advocat?';

  @override
  String get supportFaqHowSubscribe => 'Come mi abbono a Pro?';

  @override
  String get supportFaqExportData => 'Posso esportare i miei dati?';

  @override
  String get supportFaqCancelAccount => 'Annulla o elimina account';

  @override
  String get supportFaqTalkHuman => 'Parla con un operatore';

  @override
  String get supportContactEmail => 'Email';

  @override
  String get supportContactTelegram => 'Telegram';

  @override
  String get supportContactWhatsapp => 'WhatsApp';

  @override
  String get supportFooterSla => 'Rispondiamo entro 24 ore';

  @override
  String get supportWhatsapp => 'WhatsApp';

  @override
  String get supportEmail => 'Email';

  @override
  String get supportInApp => 'Scrivici qui';

  @override
  String get supportCategoryLabel => 'Categoria';

  @override
  String get supportCategoryBug => 'Bug';

  @override
  String get supportCategoryPayment => 'Problema di pagamento';

  @override
  String get supportCategoryQuestion => 'Domanda';

  @override
  String get supportCategoryFeature => 'Richiesta di funzionalità';

  @override
  String get supportCategoryOther => 'Altro';

  @override
  String get supportMessagePlaceholder => 'Descriva il suo problema...';

  @override
  String get supportEmailLabel => 'Email (facoltativa)';

  @override
  String get supportSend => 'Invia';

  @override
  String get supportSentSuccess => 'Messaggio inviato! Risponderemo a breve.';

  @override
  String get supportError => 'Qualcosa è andato storto. Riprovi.';

  @override
  String get supportErrorTooShort => 'Scriva almeno 10 caratteri.';

  @override
  String get supportErrorTooLong => 'Massimo 2000 caratteri.';

  @override
  String get supportPrivacyNotice =>
      'Il suo messaggio è archiviato in modo sicuro.';

  @override
  String get reviewThisContract => 'Esamina questo contratto';

  @override
  String get contractReviews => 'Revisioni contrattuali';

  @override
  String get contractReviewsFreeFeature =>
      '1 revisione contrattuale (prova a vita)';

  @override
  String get contractReviewsCounselFeature =>
      '5 revisioni contrattuali al mese';

  @override
  String get contractReviewsProFeature => '20 revisioni contrattuali al mese';

  @override
  String contractReviewsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count revisioni contratti rimaste questo mese',
      one: '1 revisione contratto rimasta questo mese',
      zero: 'Nessuna revisione di contratto rimasta questo mese',
    );
    return '$_temp0';
  }

  @override
  String get contractReviewsExhausted =>
      'Nessuna revisione contrattuale rimasta questo mese';

  @override
  String get contractReviewsFreeTrialLeft =>
      'Prova gratuita: 1 revisione contrattuale';

  @override
  String get contractReviewsFreeTrialUsed => 'Prova gratuita usata — aggiorna';

  @override
  String get contractReviewsUpgradeTitle => 'Revisioni contrattuali esaurite';

  @override
  String get contractReviewsUpgradeBodyFree =>
      'Hai usato la tua revisione contrattuale gratuita. Aggiorna per revisioni mensili.';

  @override
  String contractReviewsUpgradeBodyPaid(int used, int cap) {
    return 'Hai usato $used di $cap revisioni questo mese. Aggiorna per un limite mensile più alto.';
  }

  @override
  String get contractReviewsUpgradeCounselCta =>
      'Passa a Counsel (€19,99/mese) — 5 revisioni';

  @override
  String get contractReviewsUpgradeProCta =>
      'Passa a Pro (€29,99/mese) — 20 revisioni';

  @override
  String get contractReviewsUpgradeToProShort => 'Passa a Pro — 20/mese';

  @override
  String get notNow => 'Non ora';

  @override
  String get referralTitle => 'Invita amici';

  @override
  String get referralSubtitle =>
      'Ottieni un mese gratis. Regala un mese gratis.';

  @override
  String get referralYourLink => 'IL TUO LINK';

  @override
  String get referralCopyLink => 'Copia link';

  @override
  String get referralShare => 'Condividi';

  @override
  String get referralLinkCopied => 'Link copiato';

  @override
  String get referralStatsInvited => 'Invitati';

  @override
  String get referralStatsConverted => 'Convertiti';

  @override
  String get referralStatsEarned => 'Mesi guadagnati';

  @override
  String get referralShareWhatsApp => 'Condividi su WhatsApp';

  @override
  String get referralShareTelegram => 'Condividi su Telegram';

  @override
  String get referralShareEmail => 'Condividi via email';

  @override
  String get referralEmailSubject =>
      'Prova Advocat — il tuo assistente legale IA';

  @override
  String get referralLoadError =>
      'Impossibile caricare i dati. Tira per aggiornare.';

  @override
  String get referralRetry => 'Riprova';

  @override
  String get referralSettingsTile => 'Invita amici';

  @override
  String get referralAfterReviewCta =>
      'Ti è piaciuto? Invita un amico — entrambi ricevete un mese gratis.';

  @override
  String get referralAntiFraud =>
      'Massimo 12 inviti andati a buon fine all\'anno.';

  @override
  String get referralEmpty =>
      'Ancora nessun invito. Invii il suo link per iniziare a guadagnare.';

  @override
  String get referralRecentActivity => 'Attività recente';

  @override
  String referralActivityInvited(String when) {
    return 'Invitato $when';
  }

  @override
  String referralActivityActivated(String when) {
    return 'attivato $when';
  }

  @override
  String get referralActivityPending => 'non ancora attivato';

  @override
  String referralStatsInvitedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count amici',
      one: '1 amico',
      zero: 'ancora nessun amico',
    );
    return 'Ha invitato $_temp0';
  }

  @override
  String referralStatsConvertedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hanno attivato',
      one: '1 ha attivato',
      zero: 'ancora nessuno attivato',
    );
    return '$_temp0';
  }

  @override
  String referralStatsEarnedCount(int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months mesi gratuiti',
      one: '1 mese gratuito',
      zero: 'ancora niente',
    );
    return 'Il suo bonus: $_temp0';
  }

  @override
  String get referralNudgeMessage =>
      'Le piace Advocat? Inviti un amico — entrambi ricevete un mese gratuito.';

  @override
  String get referralNudgeAction => 'Invita';

  @override
  String get referralLandingTitle => 'È stato invitato su Advocat';

  @override
  String referralLandingSubtitle(String inviterName) {
    return '$inviterName l\'ha invitato — riscatti il suo primo mese gratuito.';
  }

  @override
  String get referralLandingSubtitleGeneric =>
      'Riscatti il suo primo mese gratuito di Advocat Pro.';

  @override
  String get referralLandingCta => 'Attiva il mese gratuito e registrati';

  @override
  String get referralLandingCtaSecondary => 'Oppure scopri di più su Advocat';

  @override
  String get referralLandingFallback =>
      'Questo link è scaduto — ma può comunque provare Advocat gratuitamente.';

  @override
  String get referralLandingBenefits =>
      '17 lingue • Diritto estone, finlandese e UE reale • 24 ore su 24, 7 giorni su 7 — senza attese';

  @override
  String get checkerProTagline => 'Strumenti professionali di verifica';

  @override
  String get checkerDataSource => 'Dati dai registri ufficiali';

  @override
  String get companyCheckerHint => 'Nome dell\'azienda o n. di registro';

  @override
  String get companyCheckerPriceChip => '€2.99 per verifica  •  Incluso in Pro';

  @override
  String get companyCheckerEmptyState =>
      'Inserisci il nome dell\'azienda o il numero\ndi registro per ottenere un rapporto completo';

  @override
  String get aiMemoryTitle => 'Memoria dell\'IA';

  @override
  String get aiMemorySubtitle =>
      'Rivedi ed elimina ciò che l\'IA ricorda di te';

  @override
  String get bookLawyerCallTitle => 'Prenota una chiamata con un avvocato';

  @override
  String get bookLawyerCallComingSoonTitle =>
      'Chiamate con avvocati reali — disponibili a breve';

  @override
  String get bookLawyerCallComingSoonBody =>
      'Pro e Premium includono chiamate di 15 minuti con un avvocato partner (1/trimestre per Pro, 2/trimestre per Premium). Stiamo finalizzando la rete di avvocati individuali estoni e ti invieremo un\'e-mail non appena le prenotazioni saranno aperte.';

  @override
  String bookLawyerCallQuotaAvailable(int remaining, int total) {
    return 'Ti rimangono $remaining chiamate su $total in questo trimestre.';
  }

  @override
  String get bookLawyerCallQuotaExhausted => 'Quota trimestrale esaurita.';

  @override
  String get bookLawyerCallQuotaBodyAvailable =>
      'Il piano Pro include 1 chiamata/trimestre, Premium 2. Le chiamate durano 15 minuti via Google Meet.';

  @override
  String get bookLawyerCallQuotaBodyExhausted =>
      'La tua quota si ripristina il primo giorno del prossimo trimestre. Hai bisogno di parlare prima? Passa a Premium per una chiamata extra.';

  @override
  String get severityCritical => 'CRITICO';

  @override
  String get severityHigh => 'ALTO';

  @override
  String get severityMedium => 'MEDIO';

  @override
  String get severityLow => 'BASSO';

  @override
  String get deadlineRequiredFields =>
      'Titolo e data di scadenza sono obbligatori';

  @override
  String get acceptTermsRequired => 'Accetta i Termini di servizio';

  @override
  String get chatLegalCouncilTooltip => 'Consiglio legale (4 esperti)';

  @override
  String get attachFileTooltip => 'Allega file';

  @override
  String get sendMessage => 'Invia messaggio';

  @override
  String get stopGenerating => 'Interrompi generazione';

  @override
  String get showPassword => 'Mostra password';

  @override
  String get hidePassword => 'Nascondi password';

  @override
  String get decreaseDependents => 'Diminuisci';

  @override
  String get increaseDependents => 'Aumenta';

  @override
  String get sensitiveConsentTitle => 'Consenso ai dati sensibili';

  @override
  String get sensitiveConsentBody =>
      'I documenti che sta per caricare possono contenere categorie particolari di dati personali ai sensi dell\'art. 9 del GDPR — come dati sanitari, dati giudiziari, dati biometrici o informazioni sulla sua origine razziale, religione o orientamento sessuale.\n\nTrattiamo questi dati esclusivamente per fornirle assistenza legale IA, li conserviamo cifrati nel suo account privato e non li usiamo mai per addestrare i modelli. Può revocare il consenso ed eliminare i dati in qualsiasi momento dalle Impostazioni.\n\nAccettando, fornisce il consenso esplicito ai sensi dell\'art. 9(2)(a) del GDPR al trattamento di categorie particolari di dati per questa finalità.';

  @override
  String get sensitiveConsentExplicitCheckbox =>
      'Fornisco il consenso esplicito al trattamento di categorie particolari di dati (art. 9(2)(a) GDPR).';

  @override
  String get sensitiveConsentRightToShareCheckbox =>
      'Confermo di avere il diritto di condividere questi dati (i dati sono miei, oppure dispongo di una base informata/lecita per condividere dati di terzi).';

  @override
  String get sensitiveConsentViewCategories =>
      'Visualizza cosa è considerato sensibile →';

  @override
  String get sensitiveConsentWithdrawAction =>
      'Revoca il consenso ai dati sensibili';

  @override
  String get privacyAndData => 'PRIVACY E DATI';

  @override
  String get exportMyDataSubtitle =>
      'Scarichi una copia di tutti i suoi dati personali (art. 15 GDPR).';

  @override
  String get withdrawSensitiveConsent => 'Consenso ai dati sensibili';

  @override
  String get withdrawSensitiveConsentSubtitle =>
      'Gestisci o revoca il consenso al trattamento di categorie particolari di dati (art. 9(2)(a) GDPR).';

  @override
  String get dataProcessingAgreement => 'Accordo sul trattamento dei dati';

  @override
  String get exportingData => 'Esportazione dei suoi dati…';

  @override
  String get exportComplete =>
      'Esportazione dei dati pronta — salvata sul suo dispositivo.';

  @override
  String get exportFailed =>
      'Esportazione non riuscita. Riprovi o contatti l\'assistenza.';

  @override
  String get quotaExhaustedTitle => 'Limite di messaggi gratuiti raggiunto';

  @override
  String quotaExhaustedBody(int count) {
    return 'Ha utilizzato tutti i $count messaggi gratuiti. Passi ad Advocat Counsel per 19,99 €/mese e ottenga consulenze legali IA illimitate.';
  }

  @override
  String get quotaExhaustedLater => 'Più tardi';

  @override
  String get quotaExhaustedUpgrade => 'Advocat Counsel — 19,99 €/mese';

  @override
  String quotaCtaMessage(int count) {
    return 'Ha utilizzato tutti i $count messaggi gratuiti. Passi ad Advocat Counsel per 19,99 €/mese.';
  }

  @override
  String get quotaCtaButton => 'Ottieni Advocat Counsel — 19,99 €/mese';

  @override
  String get aiErrorQuota =>
      'Limite di messaggi gratuiti raggiunto. Si abboni per continuare a usare l\'IA.';

  @override
  String get aiErrorAuth =>
      'È necessario l\'accesso per usare l\'IA. La preghiamo di registrarsi o accedere.';

  @override
  String get aiErrorGeneric =>
      'Errore temporaneo dell\'IA. Riprovi tra un minuto. Se persiste, contatti l\'assistenza.';

  @override
  String get tooltipShareCase => 'Condividi il riepilogo del caso';

  @override
  String get tooltipMuteVoice => 'Disattiva la voce';

  @override
  String get tooltipUnmuteVoice => 'Attiva la voce';

  @override
  String get tooltipAttachDoc => 'Allega documento';

  @override
  String get aiTypingHint => 'IA…';

  @override
  String get error404Title => 'Pagina non trovata';

  @override
  String error404Body(String path) {
    return 'Non siamo riusciti a trovare: $path';
  }

  @override
  String get goToHome => 'Vai alla home';

  @override
  String get emailAlreadyRegistered =>
      'Questa email è già registrata. Desidera accedere?';

  @override
  String get actionSignIn => 'Accedi';

  @override
  String get actionUndo => 'Annulla';

  @override
  String get intakeUrgentOpened => 'Chat aperta — la sua bozza è salvata.';

  @override
  String get panicCoachmark => 'Tieni premuto per l\'aiuto d\'emergenza.';

  @override
  String get panicTitle => 'Di cosa ha bisogno in questo momento?';

  @override
  String get panicCardReadAloud => 'Leggi ad alta voce all\'agente';

  @override
  String get panicCardRecord => 'Registra questa conversazione';

  @override
  String get panicCardCall => 'Chiama un avvocato';

  @override
  String get panicCardAi => 'Parla con Advocat ora';

  @override
  String get panicClose => 'Chiudi';

  @override
  String get panicBadgeV2 => 'V2';

  @override
  String get panicRecordV1Title => 'In arrivo nella V2';

  @override
  String get panicRecordV1Body =>
      'La funzione di registrazione è in fase di validazione legale per l\'Estonia e sarà disponibile nella V2. Per ora, usi il registratore vocale integrato del suo telefono.';

  @override
  String get panicCallFallbackBody =>
      'Scriva a kiire@advocat.ee con una breve descrizione e la richiameremo.';

  @override
  String get consiliumHeader => 'Consilio di avvocati';

  @override
  String consiliumProgress(int count, int total) {
    return '$count su $total pronti';
  }

  @override
  String get consiliumStarting => 'Gli avvocati stanno esaminando il tuo caso…';

  @override
  String get consiliumDisagreement => 'Gli esperti sono in disaccordo';

  @override
  String get consiliumSynthesizing => 'Sintesi della raccomandazione…';

  @override
  String consiliumDone(int totalRoles) {
    return 'Consilio concluso · $totalRoles esperti';
  }

  @override
  String get consiliumPositionPush => 'Impugna';

  @override
  String get consiliumPositionSettle => 'Concilia';

  @override
  String get consiliumPositionInvestigate => 'Indaga';

  @override
  String get consiliumPositionOutOfScope => 'Fuori competenza';

  @override
  String get consiliumConfidence => 'Affidabilità';

  @override
  String get consiliumKeyCitation => 'Riferimento chiave';

  @override
  String get consiliumAdversarialRound => 'Turno contraddittorio';

  @override
  String get consiliumViewFullOpinion => 'Visualizza parere completo';

  @override
  String consiliumExpertsAgreed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count esperti d\'accordo',
      one: '1 esperto d\'accordo',
    );
    return '$_temp0';
  }

  @override
  String consiliumExpertsDisagree(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count esperti in disaccordo',
      one: '1 esperto in disaccordo',
    );
    return '$_temp0';
  }

  @override
  String get consiliumDisclaimer =>
      'Agenti IA, non avvocati umani. Verifica le decisioni rilevanti con un avvocato iscritto all\'albo.';

  @override
  String get softCaseShellBanner =>
      'Abbiamo creato \"Caso senza titolo\" per tenerne traccia. Tocchi per rinominarlo.';

  @override
  String get softCaseShellBannerCta => 'Rinomina';

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
  String get iapPayWithApple => 'Paga con Apple';

  @override
  String get iapRestorePurchases => 'Ripristina acquisti';

  @override
  String get iapPurchaseFailed =>
      'Acquisto non riuscito. Riprova o contatta l’assistenza.';

  @override
  String get iapRestoreSuccess => 'Il tuo abbonamento è stato ripristinato.';

  @override
  String get iapRestoreNoActive => 'Nessun abbonamento attivo da ripristinare.';

  @override
  String get deadlineEuRadarTitle => 'EU deadline radar (preview)';

  @override
  String get deadlineEuRadarSubtitle =>
      'Hypothetical EU procedural deadlines — mock data';

  @override
  String get changePassword => 'Cambia password';

  @override
  String get changePasswordSubtitle => 'Aggiorna la password del tuo account';

  @override
  String get newPasswordTitle => 'Imposta una nuova password';

  @override
  String get newPasswordHint =>
      'Inserisci e conferma una nuova password per il tuo account.';

  @override
  String get newPasswordSave => 'Salva nuova password';

  @override
  String get newPasswordSuccess =>
      'Password aggiornata. Ora puoi usarla per accedere.';

  @override
  String get newPasswordError => 'Impossibile aggiornare la password. Riprova.';

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

  @override
  String get breachAlertTitle => 'Security alert on your data';

  @override
  String get breachAlertBody =>
      'Our automated monitoring detected unusual access involving your data. We are reviewing it and will notify you of any confirmed incident as required by law (GDPR Art. 34).';

  @override
  String get caseDossierTitle => 'Export case dossier';

  @override
  String get caseDossierSubtitle =>
      'One PDF with everything — facts, chronology, deadlines and documents — to hand to a lawyer, a court, or a complaint body.';

  @override
  String get caseDossierTileTitle => 'Export dossier (PDF)';

  @override
  String get caseDossierTileSubtitle =>
      'Hand the whole case to a lawyer or court in one file';

  @override
  String get caseDossierSectionsHeading => 'Include in the dossier';

  @override
  String get caseDossierSectionFacts => 'Case facts';

  @override
  String get caseDossierSectionFactsHint => 'Always included';

  @override
  String get caseDossierSectionTimeline => 'Chronology';

  @override
  String get caseDossierSectionDeadlines => 'Deadlines';

  @override
  String get caseDossierSectionDocuments => 'Documents';

  @override
  String get caseDossierSectionAiSummary => 'AI summary';

  @override
  String get caseDossierExportButton => 'Export PDF';

  @override
  String get caseDossierExporting => 'Building your dossier…';

  @override
  String get caseDossierSuccess => 'Dossier ready. Open or share the file.';

  @override
  String get caseDossierOpen => 'Open dossier';

  @override
  String get caseDossierError =>
      'Could not build the dossier. Please try again.';

  @override
  String get caseDossierErrorNotOwned => 'This case could not be found.';

  @override
  String get caseDossierDisclaimer =>
      'The dossier reproduces your case data as recorded. Review it before sharing.';

  @override
  String get followupsTitle => 'Next steps';

  @override
  String get followupsSubtitle => 'Practical tasks to keep your case moving';

  @override
  String get followupsEmpty => 'No follow-up steps yet.';

  @override
  String get followupsEmptyDesc =>
      'Add a step, or let the AI suggest what to do next.';

  @override
  String get followupsAdd => 'Add step';

  @override
  String get followupsSuggest => 'Suggest steps';

  @override
  String get followupsSuggestNone =>
      'No suggestions right now. Try after chatting about the case.';

  @override
  String get followupsSuggestTitle => 'Suggested next steps';

  @override
  String get followupsAddPrompt => 'Add the steps you want to keep:';

  @override
  String get followupsNewTitleHint => 'What needs to be done?';

  @override
  String get followupsNewDetailHint => 'Optional note (why / what to attach)';

  @override
  String get followupsDueOptional => 'Remind me on (optional)';

  @override
  String get followupsOverdue => 'Overdue';

  @override
  String followupsDueOn(Object date) {
    return 'Due $date';
  }

  @override
  String get followupsDone => 'Done';

  @override
  String get followupsSnooze => 'Snooze';

  @override
  String get followupsSnooze1Week => 'Remind in a week';

  @override
  String get followupsDismiss => 'Dismiss';

  @override
  String get followupsLoadError => 'Could not load next steps';

  @override
  String get followupsAiBadge => 'AI';

  @override
  String get contractCompareTitle => 'Compare versions';

  @override
  String get contractCompareIntro =>
      'Upload two versions of the same contract. We highlight what changed and whether each change helps or hurts you.';

  @override
  String get contractCompareOldVersion => 'Old version (v1)';

  @override
  String get contractCompareNewVersion => 'New version (v2)';

  @override
  String get contractCompareCta => 'Compare versions';

  @override
  String get contractCompareAdverse => 'Adverse';

  @override
  String get contractCompareFavorable => 'Favorable';

  @override
  String get contractCompareNeutral => 'Neutral';

  @override
  String get contractCompareBefore => 'Before';

  @override
  String get contractCompareAfter => 'After';

  @override
  String get contractCompareTruncated =>
      'Long contract — only the first part of each version was compared.';

  @override
  String get contractCompareNoChanges =>
      'No material changes detected between the two versions.';

  @override
  String get docSearchTitle => 'Search my documents';

  @override
  String get docSearchHint => 'e.g. where was the deposit mentioned';

  @override
  String get docSearchSubtitle =>
      'Semantic search across your vault and case files';

  @override
  String get docSearchIdle =>
      'Search the contents of your own documents — not just titles.';

  @override
  String get docSearchNoResults => 'No matches found in your documents.';

  @override
  String get docSearchError => 'Search failed. Please try again.';

  @override
  String get docSearchUntitled => 'Untitled document';

  @override
  String get docSearchKindCase => 'Case document';

  @override
  String get docSearchKindVault => 'Vault document';

  @override
  String get docSearchMenuTitle => 'Search my documents';

  @override
  String get docSearchMenuSubtitle =>
      'Find anything in your own files by meaning';

  @override
  String get legalTemplatesTitle => 'Template library';

  @override
  String get legalTemplatesMenuLabel => 'Templates';

  @override
  String get legalTemplatesSubtitle =>
      'Pick a ready-made form, fill in a few details, and we\'ll create a draft you can edit and export.';

  @override
  String get legalTemplatesDisclaimer =>
      'These are general sample forms, not individual legal advice. Review and adapt before sending.';

  @override
  String get legalTemplatesSampleBadge => 'Sample';

  @override
  String get legalTemplatesEmpty => 'No templates for this filter yet.';

  @override
  String get legalTemplatesError =>
      'Couldn\'t load templates. Please try again.';

  @override
  String get legalTemplatesFilterAll => 'All';

  @override
  String get legalTemplatesJurisdictionFi => 'Finland';

  @override
  String get legalTemplatesJurisdictionEe => 'Estonia';

  @override
  String get legalTemplatesCategoryComplaint => 'Complaints';

  @override
  String get legalTemplatesCategoryAppeal => 'Appeals';

  @override
  String get legalTemplatesCategoryApplication => 'Applications';

  @override
  String get legalTemplatesCategoryClaim => 'Claims';

  @override
  String get legalTemplatesCategoryRequest => 'Requests';

  @override
  String get legalTemplatesFillTitle => 'Fill in the details';

  @override
  String get legalTemplatesFillIntro =>
      'We\'ll auto-fill your name and case details. Complete the fields below.';

  @override
  String get legalTemplatesFieldRequired => 'This field is required';

  @override
  String get legalTemplatesCreateDraft => 'Create draft';

  @override
  String get legalTemplatesCreating => 'Creating draft…';

  @override
  String get legalTemplatesCreateFailed =>
      'Couldn\'t create the draft. Please try again.';

  @override
  String get legalTemplatesUnresolvedWarning =>
      'Some fields are still blank and are marked with ____ in the draft. You can complete them in the editor.';

  @override
  String get legalTemplatesFieldRecipient => 'Recipient (authority / landlord)';

  @override
  String get legalTemplatesFieldAddress => 'Your postal address';

  @override
  String get legalTemplatesFieldSubject => 'Subject';

  @override
  String get legalTemplatesFieldDescription => 'Description of the matter';

  @override
  String get legalTemplatesFieldDemand => 'What you are asking for';

  @override
  String get checklistActionPlan => 'Action plan';

  @override
  String get checklistActionPlanSubtitle => 'Steps for this type of case';

  @override
  String checklistProgress(Object completed, Object total) {
    return '$completed of $total steps done';
  }

  @override
  String get checklistAllDone => 'All steps complete';

  @override
  String get checklistEmpty =>
      'No action plan is available for this case type yet.';

  @override
  String checklistDeadlineDays(Object days) {
    return '$days days';
  }

  @override
  String get checklistDisclaimer =>
      'This is general information, not legal advice. Deadlines are statutory defaults — confirm the exact date for your case.';

  @override
  String get checklistViewPlan => 'View plan';

  @override
  String get explainPlainTitle => 'Explain in plain words';

  @override
  String get explainPlainIntro =>
      'Paste an official letter, decision, or contract and we\'ll explain what it means and what it asks you to do — in plain language.';

  @override
  String get explainPlainLevelFriend => 'Like to a friend';

  @override
  String get explainPlainLevelTerms => 'Keep legal terms';

  @override
  String get explainPlainInputHint => 'Paste the legal text here…';

  @override
  String get explainPlainSubmit => 'Explain';

  @override
  String get explainPlainWorking => 'Explaining…';

  @override
  String get explainPlainTldr => 'Bottom line';

  @override
  String get explainPlainBreakdown => 'What it says, part by part';

  @override
  String get explainPlainGlossary => 'Tricky terms explained';

  @override
  String get explainPlainNextSteps => 'What you can do next';

  @override
  String get explainPlainOpenInCorpus => 'Look up in the law library';

  @override
  String get explainPlainEmptyResult =>
      'No explanation could be produced for this text. Try pasting a longer or clearer excerpt.';

  @override
  String get explainPlainQuotaTitle =>
      'You\'ve used your free explanations this month';

  @override
  String get explainPlainQuotaBody =>
      'Free accounts get 3 explanations per month. Upgrade to Pro for unlimited explanations.';

  @override
  String get explainPlainUpgradeCta => 'Upgrade to Pro';

  @override
  String get explainPlainError =>
      'Something went wrong while explaining this text. Please try again.';

  @override
  String get explainPlainRetry => 'Try again';

  @override
  String get demandLetterTitle => 'Demand letter';

  @override
  String get demandLetterSubtitle =>
      'Create a formal pre-court demand (maksuvaatimus / nõudekiri).';

  @override
  String get demandLetterStepType => 'Type of claim';

  @override
  String get demandLetterStepParties => 'Parties';

  @override
  String get demandLetterStepClaim => 'Amount & basis';

  @override
  String get demandLetterStepDeadline => 'Deadline';

  @override
  String get demandLetterStepReview => 'Review & generate';

  @override
  String get demandLetterClaimDepositReturn => 'Return of rental deposit';

  @override
  String get demandLetterClaimUnpaidWage => 'Unpaid wages';

  @override
  String get demandLetterClaimFineDispute => 'Dispute a fine / charge';

  @override
  String get demandLetterClaimGeneric => 'Other monetary claim';

  @override
  String get demandLetterJurisdiction => 'Jurisdiction';

  @override
  String get demandLetterLanguage => 'Letter language';

  @override
  String get demandLetterRecipientName => 'Recipient name';

  @override
  String get demandLetterRecipientAddress => 'Recipient address (optional)';

  @override
  String get demandLetterSenderName => 'Your name';

  @override
  String get demandLetterSenderAddress => 'Your address / email (optional)';

  @override
  String get demandLetterAmount => 'Amount';

  @override
  String get demandLetterCurrency => 'Currency';

  @override
  String get demandLetterBasis => 'What happened (basis of the claim)';

  @override
  String get demandLetterBasisHint =>
      'Describe the facts: dates, amounts, what was agreed and what went wrong.';

  @override
  String get demandLetterDeadline => 'Payment deadline';

  @override
  String get demandLetterDeadlineHint => 'e.g. 14 days from today';

  @override
  String get demandLetterReference => 'Reference (optional)';

  @override
  String get demandLetterGenerate => 'Generate letter';

  @override
  String get demandLetterGenerating => 'Generating…';

  @override
  String get demandLetterGenerateFailed =>
      'Couldn\'t generate the letter. Please try again.';

  @override
  String get demandLetterFieldRequired => 'This field is required';

  @override
  String get demandLetterNext => 'Next';

  @override
  String get demandLetterBack => 'Back';

  @override
  String get demandLetterPreviewTitle => 'Your letter';

  @override
  String get demandLetterCopy => 'Copy text';

  @override
  String get demandLetterCopied => 'Letter copied to clipboard';

  @override
  String get demandLetterExportPdf => 'Export PDF';

  @override
  String get demandLetterExporting => 'Exporting…';

  @override
  String get demandLetterExportFailed =>
      'Couldn\'t export the document. Please try again.';

  @override
  String get demandLetterSendEmail => 'Send via email';

  @override
  String get demandLetterNormsTitle => 'Legal references';

  @override
  String get demandLetterDisclaimer =>
      'This letter is prepared on your behalf as a general template. It is not legal advice or an act of a licensed attorney. Review it before sending — no letter is sent automatically.';

  @override
  String get demandLetterMenuTile => 'Demand letter';

  @override
  String get calcHubTitle => 'Legal calculators';

  @override
  String get calcHubSubtitle => 'Quick estimates before your next step';

  @override
  String get calcHubJurisdiction => 'Jurisdiction';

  @override
  String calcRatesAsOf(Object date) {
    return 'Rates as of $date';
  }

  @override
  String get calcRatesOffline => 'Showing cached rates (offline)';

  @override
  String get calcIndicativeBanner =>
      'Indicative estimate only — not an official calculation or legal advice.';

  @override
  String get calcCalculate => 'Calculate';

  @override
  String get calcResult => 'Result';

  @override
  String get calcFormula => 'How this is calculated';

  @override
  String get calcSource => 'Source';

  @override
  String get calcSeveranceTitle => 'Severance / notice';

  @override
  String get calcSeveranceDesc =>
      'Estimate severance pay and notice period on redundancy';

  @override
  String get calcSeveranceSalary => 'Gross monthly salary';

  @override
  String get calcSeveranceTenure => 'Years of service';

  @override
  String get calcSeveranceTotal => 'Estimated severance';

  @override
  String get calcSeveranceNotice => 'Notice period';

  @override
  String get calcSeveranceGenerateDemand => 'Draft a demand letter';

  @override
  String get calcLimitationTitle => 'Limitation & appeal deadlines';

  @override
  String get calcLimitationDesc =>
      'Check whether a claim or appeal period has expired';

  @override
  String get calcLimitationType => 'Type of period';

  @override
  String get calcLimitationStart => 'Start date (event / decision)';

  @override
  String get calcLimitationPickDate => 'Pick date';

  @override
  String get calcLimitationDeadline => 'Deadline';

  @override
  String get calcLimitationExpired => 'Period has expired';

  @override
  String calcLimitationDaysLeft(Object days) {
    return '$days days remaining';
  }

  @override
  String get calcLimitationShifted =>
      'Shifted to the next working day (weekend/holiday).';

  @override
  String get calcLimitationAddDeadline => 'Add to deadlines';

  @override
  String get calcStateFeeTitle => 'Court / state fees';

  @override
  String get calcStateFeeDesc => 'Reference filing fees by court and stage';

  @override
  String get calcChildSupportTitle => 'Child support (orientation)';

  @override
  String get calcChildSupportDesc =>
      'Rough orientation figure — the real amount is set case by case';

  @override
  String get calcChildSupportNet => 'Payer\'s net monthly income';

  @override
  String get calcChildSupportChildren => 'Number of children';

  @override
  String get calcChildSupportPerChild => 'Per child';

  @override
  String get calcChildSupportTotal => 'Total monthly';

  @override
  String get calcChildSupportWarning =>
      'Highly variable. Courts decide on the child\'s needs and both parents\' ability to pay. Use as a starting point only.';

  @override
  String get docCollectTitle => 'Documents to collect';

  @override
  String get docCollectSubtitle =>
      'Gather these before you apply or go to court';

  @override
  String get docCollectPickPrompt => 'What is your situation?';

  @override
  String get docCollectProblemResidence => 'Residence permit';

  @override
  String get docCollectProblemTenant => 'Renting / eviction';

  @override
  String get docCollectProblemDismissal => 'Dismissal at work';

  @override
  String get docCollectProblemInheritance => 'Inheritance';

  @override
  String get docCollectProblemDivorce => 'Divorce';

  @override
  String docCollectProgress(Object collected, Object total) {
    return '$collected of $total collected';
  }

  @override
  String get docCollectAllDone => 'Everything collected';

  @override
  String get docCollectEmpty =>
      'No document list is available for this situation yet.';

  @override
  String get docCollectOptional => 'Optional';

  @override
  String get docCollectWhereLabel => 'Where to get it';

  @override
  String get docCollectWhyLabel => 'Why it\'s needed';

  @override
  String get docCollectAttach => 'Attach a file';

  @override
  String get docCollectAttached => 'File attached';

  @override
  String get docCollectChangeFile => 'Change file';

  @override
  String get docCollectRemoveFile => 'Remove file';

  @override
  String get docCollectNoFiles => 'You haven\'t uploaded any documents yet.';

  @override
  String get docCollectPickFileTitle => 'Choose an uploaded document';

  @override
  String get docCollectExport => 'Export list';

  @override
  String get docCollectExportSubject => 'My document checklist';

  @override
  String get docCollectAiTitle => 'Need something specific?';

  @override
  String get docCollectAiHint =>
      'Describe your situation and we\'ll suggest any extra documents.';

  @override
  String get docCollectAiField => 'Describe your situation';

  @override
  String get docCollectAiButton => 'Suggest extra documents';

  @override
  String get docCollectAiLoading => 'Thinking…';

  @override
  String get docCollectAiEmpty =>
      'No extra documents suggested — the basic list looks complete for your description.';

  @override
  String get docCollectAiSuggestionsTitle => 'Suggested extra documents';

  @override
  String get docCollectDisclaimer =>
      'This is a basic list of commonly required documents — your situation may need more or fewer. It is general information, not legal advice.';

  @override
  String get docCollectRetry => 'Try again';

  @override
  String get renewalTitle => 'Renewal Radar';

  @override
  String get renewalSubtitle =>
      'Track when your permits, passport, insurance and other documents expire. We\'ll remind you 90, 30 and 7 days before each renewal.';

  @override
  String get renewalAdd => 'Add document';

  @override
  String get renewalEditTitle => 'Edit document';

  @override
  String get renewalSave => 'Save';

  @override
  String get renewalRequired => 'Required';

  @override
  String get renewalPickDate => 'Pick expiry date';

  @override
  String get renewalLoadError =>
      'Could not load your documents. Pull to refresh.';

  @override
  String get renewalEmptyTitle => 'No documents tracked yet';

  @override
  String get renewalEmptyBody =>
      'Add your residence permit, passport, insurance or licence and we\'ll watch the expiry dates for you.';

  @override
  String get renewalGuideHint => 'How to renew →';

  @override
  String get renewalFieldType => 'Document type';

  @override
  String get renewalFieldLabel => 'Label';

  @override
  String get renewalFieldNumber => 'Document number (optional)';

  @override
  String get renewalFieldJurisdiction => 'Issuing country';

  @override
  String get renewalFieldExpiry => 'Expiry date';

  @override
  String get renewalWindow90 => '90 days';

  @override
  String get renewalWindow30 => '30 days';

  @override
  String get renewalWindow7 => '7 days';

  @override
  String get renewalExpiresToday => 'Expires today';

  @override
  String renewalExpiresInDays(Object date, Object days) {
    return 'Expires in $days days · $date';
  }

  @override
  String renewalExpiredOn(Object date) {
    return 'Expired on $date';
  }

  @override
  String get renewalTypeResidencePermit => 'Residence permit';

  @override
  String get renewalTypePassport => 'Passport';

  @override
  String get renewalTypeIdCard => 'ID card';

  @override
  String get renewalTypeVisa => 'Visa';

  @override
  String get renewalTypeDrivingLicence => 'Driving licence';

  @override
  String get renewalTypeInsurance => 'Insurance';

  @override
  String get renewalTypeWorkPermit => 'Work permit';

  @override
  String get renewalTypeOther => 'Other';

  @override
  String get costEstimateTitle => 'Cost & Risk Estimator';

  @override
  String get costEstimateSubtitle =>
      'Get a rough idea of what a case might cost, how long it could take, and whether it is worth pursuing.';

  @override
  String get costEstimateCaseTypeLabel => 'Type of case';

  @override
  String get costEstimateCaseTypeHint =>
      'e.g. unpaid invoice, wrongful dismissal, deposit dispute';

  @override
  String get costEstimateJurisdictionLabel => 'Jurisdiction';

  @override
  String get costEstimateAmountLabel => 'Amount in dispute (optional)';

  @override
  String get costEstimateAmountHint => 'e.g. 12500';

  @override
  String get costEstimateDescriptionLabel =>
      'Briefly describe the situation (optional)';

  @override
  String get costEstimateB2bToggle => 'Lead-qualification card (B2B)';

  @override
  String get costEstimateB2bSubtitle =>
      'Compact output for quickly triaging an inbound client.';

  @override
  String get costEstimateSubmit => 'Estimate my case';

  @override
  String get costEstimateDisclaimer =>
      'Rough estimate only — not a prediction, guarantee, or legal advice. Actual costs and outcomes vary case by case.';

  @override
  String get costEstimateCostsHeading => 'Estimated costs';

  @override
  String get costEstimateCourtFee => 'Court / state fee';

  @override
  String get costEstimateLawyerFee => 'Lawyer fee';

  @override
  String get costEstimateTotal => 'Total (approx.)';

  @override
  String get costEstimateDuration => 'Time to first resolution';

  @override
  String get costEstimateMonthsSuffix => 'months';

  @override
  String get costEstimateFactorsFor => 'In your favour';

  @override
  String get costEstimateFactorsAgainst => 'Working against you';

  @override
  String get costEstimateStrengthWorth => 'Likely worth pursuing';

  @override
  String get costEstimateStrengthContested => 'Contested — could go either way';

  @override
  String get costEstimateStrengthWeak => 'Weak — proceed with caution';
}
