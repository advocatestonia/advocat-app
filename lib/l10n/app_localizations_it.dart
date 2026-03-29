// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Advocat — Strumento di informazione legale';

  @override
  String get onboardingTitle1 => 'Informazioni legali basate sull’IA';

  @override
  String get onboardingDesc1 =>
      'Advocat ti aiuta a comprendere la tua situazione legale. Gli strumenti di IA analizzano documenti, identificano potenziali problemi e preparano bozze di documenti per la tua revisione. Non è uno studio legale — è uno strumento tecnologico a supporto del tuo caso.';

  @override
  String get onboardingTitle2 => 'Scansiona e analizza documenti';

  @override
  String get onboardingDesc2 =>
      'Fotografa qualsiasi documento legale. L’IA lo legge in più lingue, estrae i dati chiave e verifica la conformità alle direttive UE e alle leggi nazionali.';

  @override
  String get onboardingTitle3 => 'L’IA verifica potenziali problemi';

  @override
  String get onboardingDesc3 =>
      'I nostri strumenti di IA verificano oltre 40 tipi di requisiti procedurali. L’analisi dell’IA può identificare problemi che richiedono attenzione — come la lingua di notifica, i passaggi procedurali e le scadenze legali. Verifica sempre con un avvocato qualificato.';

  @override
  String get onboardingTitle4 => 'Bozze di documenti per la tua revisione';

  @override
  String get onboardingDesc4 =>
      'L’IA prepara bozze di appelli, reclami e lettere con riferimenti legali per la tua revisione. Decidi tu cosa presentare. Ogni documento deve essere rivisto da un professionista legale qualificato prima della presentazione.';

  @override
  String get onboardingNext => 'Avanti';

  @override
  String get onboardingSkip => 'Salta';

  @override
  String get getStarted => 'Inizia';

  @override
  String get welcomeBack => 'Bentornato';

  @override
  String get signInSubtitle => 'Accedi per consultare i tuoi casi';

  @override
  String get signIn => 'Accedi';

  @override
  String get logIn => 'Entra';

  @override
  String get signUp => 'Crea account';

  @override
  String get createAccount => 'Crea account';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Conferma password';

  @override
  String get fullName => 'Nome completo';

  @override
  String get forgotPassword => 'Password dimenticata?';

  @override
  String get orDivider => 'o';

  @override
  String get continueWithGoogle => 'Continua con Google';

  @override
  String get noAccount => 'Non hai un account? ';

  @override
  String get signUpLink => 'Registrati';

  @override
  String get alreadyHaveAccount => 'Hai già un account? ';

  @override
  String get signInLink => 'Entra';

  @override
  String get emailRequired => 'L’email è obbligatoria';

  @override
  String get emailInvalid => 'Inserisci un indirizzo email valido';

  @override
  String get passwordRequired => 'La password è obbligatoria';

  @override
  String get passwordTooShort => 'La password deve avere almeno 8 caratteri';

  @override
  String get passwordsDoNotMatch => 'Le password non corrispondono';

  @override
  String get nameRequired => 'Il nome completo è obbligatorio';

  @override
  String get termsRequired => 'Devi accettare i Termini di servizio';

  @override
  String get agreeToTerms => 'Accetto i ';

  @override
  String get termsOfService => 'Termini di servizio';

  @override
  String get andWord => ' e ';

  @override
  String get privacyPolicy => 'Informativa sulla privacy';

  @override
  String get preferredLanguage => 'Lingua preferita';

  @override
  String get langEnglish => 'Inglese';

  @override
  String get langRussian => 'Russo';

  @override
  String get langFinnish => 'Finlandese';

  @override
  String get passwordStrengthWeak => 'Debole';

  @override
  String get passwordStrengthMedium => 'Media';

  @override
  String get passwordStrengthStrong => 'Forte';

  @override
  String get loginFailed => 'Email o password non validi. Riprova.';

  @override
  String get registerFailed => 'Registrazione non riuscita. Riprova.';

  @override
  String get resetPasswordSent =>
      'Link di reimpostazione inviato alla tua email.';

  @override
  String get resetPasswordFailed => 'Invio del link non riuscito. Riprova.';

  @override
  String get myCases => 'I miei casi';

  @override
  String get newCase => 'Nuovo caso';

  @override
  String get noCases => 'Ancora nessun caso';

  @override
  String get documents => 'Documenti';

  @override
  String get timeline => 'Cronologia';

  @override
  String get aiAssistant => 'Assistente legale IA';

  @override
  String get settings => 'Impostazioni';

  @override
  String get language => 'Lingua';

  @override
  String get subscription => 'Abbonamento';

  @override
  String get signOut => 'Esci';

  @override
  String get disclaimer =>
      'Solo orientamento IA — non consulenza legale. Consulta sempre un avvocato.';

  @override
  String get scanDocument => 'Scansiona documento';

  @override
  String get camera => 'Fotocamera';

  @override
  String get gallery => 'Galleria';

  @override
  String get saveAndAnalyze => 'Salva e analizza';

  @override
  String get retry => 'Riprova';

  @override
  String get cancel => 'Annulla';

  @override
  String get confirm => 'Conferma';

  @override
  String get error => 'Errore';

  @override
  String get loading => 'Caricamento...';

  @override
  String get home => 'Home';

  @override
  String get cases => 'Casi';

  @override
  String get deadlines => 'Scadenze';

  @override
  String get scan => 'Scansiona';

  @override
  String goodMorning(String name) {
    return 'Buongiorno, $name';
  }

  @override
  String goodAfternoon(String name) {
    return 'Buon pomeriggio, $name';
  }

  @override
  String goodEvening(String name) {
    return 'Buonasera, $name';
  }

  @override
  String get caseOverview => 'Ecco la panoramica dei tuoi casi';

  @override
  String get activeCases => 'Casi attivi';

  @override
  String get recentActivity => 'Attività recente';

  @override
  String urgentDeadline(String title) {
    return 'Urgente: $title';
  }

  @override
  String daysRemaining(int count) {
    return '$count giorni';
  }

  @override
  String get overdue => 'Scaduto';

  @override
  String get upcoming => 'In arrivo';

  @override
  String get completed => 'Completato';

  @override
  String get markComplete => 'Segna come completato';

  @override
  String get deportation => 'Deportazione';

  @override
  String get criminalCase => 'Caso penale';

  @override
  String get asylum => 'Asilo';

  @override
  String get residencePermit => 'Permesso di soggiorno';

  @override
  String get victimSupport => 'Supporto alle vittime';

  @override
  String get familyReunification => 'Ricongiungimento familiare';

  @override
  String get laborDispute => 'Controversia di lavoro';

  @override
  String get tenantRights => 'Diritti dell’inquilino';

  @override
  String get debtCollection => 'Recupero crediti';

  @override
  String get discrimination => 'Discriminazione';

  @override
  String get policeMisconduct => 'Abuso di polizia';

  @override
  String get socialBenefits => 'Prestazioni sociali';

  @override
  String get other => 'Altro';

  @override
  String get caseDetail => 'Dettagli del caso';

  @override
  String get aiAnalysis => 'Analisi IA';

  @override
  String get draftAppeal => 'Bozza di appello';

  @override
  String get aiChat => 'Chat IA';

  @override
  String get correspondence => 'Corrispondenza';

  @override
  String get analyzing => 'Analisi in corso...';

  @override
  String get readingDocument => 'Lettura documento...';

  @override
  String get checkingErrors => 'Controllo errori...';

  @override
  String get researchingLaw => 'Ricerca della legge applicabile...';

  @override
  String issuesFound(int count) {
    return '$count problemi trovati';
  }

  @override
  String get critical => 'Critico';

  @override
  String get important => 'Importante';

  @override
  String get informational => 'Informativo';

  @override
  String get useInAppeal => 'Usa nell’appello';

  @override
  String get addedToAppeal => 'Aggiunto all’appello';

  @override
  String get generateAppeal => 'Genera appello';

  @override
  String get exportPdf => 'Esporta PDF';

  @override
  String get sendViaEmail => 'Invia via email';

  @override
  String get copyText => 'Copia testo';

  @override
  String get editDraft => 'Modifica';

  @override
  String get saveDraft => 'Salva';

  @override
  String get reviewWarning =>
      'Rivedi attentamente prima dell’invio. Sei responsabile del contenuto.';

  @override
  String get disclaimerFull =>
      'Questo è un assistente IA, non un avvocato. L’analisi IA può contenere errori. Verifica sempre con un professionista legale qualificato.';

  @override
  String get askAboutCase => 'Analizza il mio caso';

  @override
  String get whatAreMyOptions => 'Quali sono le mie opzioni?';

  @override
  String get checkDeadlines => 'Verifica scadenze';

  @override
  String get typeMessage => 'Scrivi un messaggio...';

  @override
  String get connectEmail => 'Collega email';

  @override
  String get connectGmail => 'Collega Gmail';

  @override
  String get connectOutlook => 'Collega Outlook';

  @override
  String get emailConnected => 'Email collegata';

  @override
  String get syncNow => 'Sincronizza ora';

  @override
  String get disconnect => 'Disconnetti';

  @override
  String get emailPrivacyNote =>
      'Leggiamo solo le email relative a questioni legali. Le tue email personali restano private.';

  @override
  String get pushNotifications => 'Notifiche push';

  @override
  String get deadlineReminders => 'Promemoria scadenze';

  @override
  String get deadlineRemindersDesc => 'Ricevi notifiche prima delle scadenze';

  @override
  String get editProfile => 'Modifica profilo';

  @override
  String get exportMyData => 'Esporta i miei dati';

  @override
  String get exportDataDesc => 'Scarica tutti i dati dei tuoi casi';

  @override
  String get deleteAccount => 'Elimina account';

  @override
  String get deleteAccountDesc => 'Rimuovi permanentemente il tuo account';

  @override
  String get deleteConfirm =>
      'Sei sicuro? Tutti i tuoi dati verranno eliminati permanentemente.';

  @override
  String get about => 'Informazioni';

  @override
  String get version => 'Versione';

  @override
  String get rateUs => 'Valutaci';

  @override
  String get contactSupport => 'Contatta il supporto';

  @override
  String get tryDemoMode => 'Prova la modalità demo';

  @override
  String get demoModeDesc =>
      'Esplora l’app con dati di esempio da un caso reale';

  @override
  String get free => 'Gratuito';

  @override
  String get basic => 'Base';

  @override
  String get pro => 'Pro';

  @override
  String get emergencyShield => 'Scudo d’emergenza';

  @override
  String get legalFighter => 'Combattente legale';

  @override
  String get fullDefense => 'Difesa completa';

  @override
  String get popular => 'POPOLARE';

  @override
  String get currentPlan => 'Piano attuale';

  @override
  String get choosePlan => 'Scegli piano';

  @override
  String get saveWithAnnual => 'Risparmia il 25% con la fatturazione annuale';

  @override
  String get restorePurchases => 'Ripristina acquisti';

  @override
  String get country => 'Paese';

  @override
  String get caseDescription => 'Descrivi la tua situazione';

  @override
  String get caseTitle => 'Titolo del caso';

  @override
  String get referenceNumber => 'Numero di riferimento';

  @override
  String get uploadDocument => 'Carica documento';

  @override
  String get optional => '(facoltativo)';

  @override
  String step(int current, int total) {
    return 'Passo $current di $total';
  }

  @override
  String get next => 'Avanti';

  @override
  String get back => 'Indietro';

  @override
  String get createCase => 'Crea caso';

  @override
  String get searchCases => 'Cerca casi...';

  @override
  String get all => 'Tutti';

  @override
  String get active => 'Attivi';

  @override
  String get closed => 'Chiusi';

  @override
  String lastActivity(String time) {
    return 'Ultima attività: $time';
  }

  @override
  String documentsCount(int count) {
    return '$count doc.';
  }

  @override
  String get noCasesYet => 'Ancora nessun caso';

  @override
  String get startFirstCase => 'Inizia il tuo primo caso';

  @override
  String get noDeadlines => 'Nessuna scadenza — tutto in ordine!';

  @override
  String get appealFiled => 'Appello presentato';

  @override
  String get pendingDecision => 'Decisione in attesa';

  @override
  String get inProgress => 'In corso';

  @override
  String get won => 'Vinto';

  @override
  String get lost => 'Perso';

  @override
  String get preferences => 'PREFERENZE';

  @override
  String get notifications => 'NOTIFICHE';

  @override
  String get emailIntegration => 'INTEGRAZIONE EMAIL';

  @override
  String get dataAndPrivacy => 'DATI E PRIVACY';

  @override
  String get legalSection => 'LEGALE';

  @override
  String get aboutSection => 'INFORMAZIONI';

  @override
  String get appVersion => 'Versione dell’app';

  @override
  String get selectLanguage => 'Seleziona lingua';

  @override
  String get signOutConfirm => 'Sei sicuro di voler uscire?';

  @override
  String get emailDisconnected => 'Email disconnessa';

  @override
  String get syncLegalCorrespondence => 'Sincronizza corrispondenza legale';

  @override
  String get requestExport => 'Richiedi esportazione';

  @override
  String get exportDataDialogContent =>
      'Prepareremo un download di tutti i tuoi dati, inclusi casi, documenti e corrispondenza. Riceverai un’email quando sarà pronto.';

  @override
  String get deleteAccountDialogContent =>
      'Questa azione è permanente e irreversibile. Tutti i tuoi dati, casi e documenti verranno eliminati permanentemente.';

  @override
  String get areYouAbsolutelySure => 'Sei assolutamente sicuro?';

  @override
  String get typeDeleteToConfirm =>
      'Digita DELETE per confermare la rimozione permanente dell’account.';

  @override
  String get permanentlyDelete => 'Elimina permanentemente';

  @override
  String get dataExportRequested =>
      'Esportazione dati richiesta. Controlla la tua email.';

  @override
  String get connected => 'Collegato';

  @override
  String get caseUpdated => 'Caso aggiornato';

  @override
  String get noRecentActivity => 'Nessuna attività recente';

  @override
  String get couldNotLoadCases => 'Impossibile caricare i tuoi casi';

  @override
  String get viewAll => 'Vedi tutti';

  @override
  String get checkCompany => 'Check Company';

  @override
  String get checkVehicle => 'Check Vehicle';

  @override
  String get companyName => 'Company name or reg. number';

  @override
  String get selectCountry => 'Select country';

  @override
  String get riskLow => 'Safe to work with';

  @override
  String get riskMedium => 'Proceed with caution';

  @override
  String get riskHigh => 'High risk — avoid';

  @override
  String get perCheck => 'per check';

  @override
  String get checkerTitle => 'Checker';

  @override
  String get beforeYouWork => 'Before you work with them';

  @override
  String get beforeYouBuy => 'Before you buy';

  @override
  String get vehicleChecker => 'Vehicle Checker';

  @override
  String get licensePlate => 'License plate';

  @override
  String get vinNumber => 'VIN number';

  @override
  String get vehicleMake => 'Make';

  @override
  String get vehicleModel => 'Model';

  @override
  String get vehicleYear => 'Year';

  @override
  String get vehicleColor => 'Color';

  @override
  String get vehicleChecks => 'Status Checks';

  @override
  String get mileage => 'Mileage';

  @override
  String get accidents => 'Accidents';

  @override
  String get owners => 'Previous owners';

  @override
  String get insurance => 'Insurance';

  @override
  String get inspection => 'Technical inspection';

  @override
  String get stolen => 'Stolen check';

  @override
  String get safeToBuy => 'Safe to buy';

  @override
  String get someConcerns => 'Some concerns';

  @override
  String get doNotBuy => 'Do not buy';

  @override
  String get pricePerCheck => '€4.99 per check';

  @override
  String get demoHint => 'Demo: try plate \"908FBT\"';

  @override
  String get reportFraud => 'Report Fraud';

  @override
  String get openACase => 'Open a Case';
}
