// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Romanian Moldavian Moldovan (`ro`).
class AppLocalizationsRo extends AppLocalizations {
  AppLocalizationsRo([String locale = 'ro']) : super(locale);

  @override
  String get appTitle => 'Advocat — Instrument de informații juridice';

  @override
  String get onboardingTitle1 => 'Informații juridice bazate pe IA';

  @override
  String get onboardingDesc1 =>
      'Advocat vă ajută să înțelegeți situația juridică. Instrumentele IA analizează documente, identifică posibile probleme și pregătesc proiecte de documente pentru revizuirea dvs. Nu este o firmă de avocatură — este un instrument tehnologic pentru a vă sprijini cazul.';

  @override
  String get onboardingTitle2 => 'Scanați și analizați documente';

  @override
  String get onboardingDesc2 =>
      'Fotografiați orice document juridic. IA îl citește în mai multe limbi, extrage datele cheie și verifică conformitatea cu directivele UE și legislația națională.';

  @override
  String get onboardingTitle3 => 'IA verifică posibilele probleme';

  @override
  String get onboardingDesc3 =>
      'Instrumentele noastre IA verifică peste 40 de tipuri de cerințe procedurale. Analiza IA poate identifica probleme care necesită atenție — cum ar fi limba de notificare, pașii procedurali și termenele legale. Verificați întotdeauna cu un avocat calificat.';

  @override
  String get onboardingTitle4 => 'Proiecte de documente pentru revizuirea dvs.';

  @override
  String get onboardingDesc4 =>
      'IA pregătește proiecte de apeluri, plangeri și scrisori cu referințe legale pentru revizuirea dvs. Dvs. decideți ce să depuneți. Fiecare document trebuie revizuit de un profesionist juridic calificat înainte de depunere.';

  @override
  String get onboardingNext => 'Următor';

  @override
  String get onboardingSkip => 'Săriți';

  @override
  String get getStarted => 'Începeți';

  @override
  String get welcomeBack => 'Bine ați revenit';

  @override
  String get signInSubtitle => 'Conectați-vă pentru a accesa cazurile dvs.';

  @override
  String get signIn => 'Conectare';

  @override
  String get logIn => 'Autentificare';

  @override
  String get signUp => 'Creați cont';

  @override
  String get createAccount => 'Creați cont';

  @override
  String get email => 'Email';

  @override
  String get password => 'Parolă';

  @override
  String get confirmPassword => 'Confirmați parola';

  @override
  String get fullName => 'Nume complet';

  @override
  String get forgotPassword => 'Ați uitat parola?';

  @override
  String get orDivider => 'sau';

  @override
  String get continueWithGoogle => 'Continuați cu Google';

  @override
  String get noAccount => 'Nu aveți cont? ';

  @override
  String get signUpLink => 'Înregistrați-vă';

  @override
  String get alreadyHaveAccount => 'Aveți deja cont? ';

  @override
  String get signInLink => 'Autentificare';

  @override
  String get emailRequired => 'Emailul este obligatoriu';

  @override
  String get emailInvalid => 'Introduceți o adresă de email validă';

  @override
  String get passwordRequired => 'Parola este obligatorie';

  @override
  String get passwordTooShort => 'Parola trebuie să aibă cel puțin 8 caractere';

  @override
  String get passwordsDoNotMatch => 'Parolele nu se potrivesc';

  @override
  String get nameRequired => 'Numele complet este obligatoriu';

  @override
  String get termsRequired => 'Trebuie să acceptați Termenii serviciului';

  @override
  String get agreeToTerms => 'Sunt de acord cu ';

  @override
  String get termsOfService => 'Termenii serviciului';

  @override
  String get andWord => ' și ';

  @override
  String get privacyPolicy => 'Politica de confidențialitate';

  @override
  String get preferredLanguage => 'Limba preferată';

  @override
  String get langEnglish => 'Engleză';

  @override
  String get langRussian => 'Rusă';

  @override
  String get langFinnish => 'Finlandeză';

  @override
  String get passwordStrengthWeak => 'Slabă';

  @override
  String get passwordStrengthMedium => 'Medie';

  @override
  String get passwordStrengthStrong => 'Puternică';

  @override
  String get loginFailed => 'Email sau parolă invalidă. Încercați din nou.';

  @override
  String get registerFailed => 'Înregistrarea a eșuat. Încercați din nou.';

  @override
  String get resetPasswordSent => 'Link de resetare trimis la emailul dvs.';

  @override
  String get resetPasswordFailed =>
      'Trimiterea linkului a eșuat. Încercați din nou.';

  @override
  String get myCases => 'Cazurile mele';

  @override
  String get newCase => 'Caz nou';

  @override
  String get noCases => 'Încă nu există cazuri';

  @override
  String get documents => 'Documente';

  @override
  String get timeline => 'Cronologie';

  @override
  String get aiAssistant => 'Asistent juridic IA';

  @override
  String get settings => 'Setări';

  @override
  String get language => 'Limbă';

  @override
  String get subscription => 'Abonament';

  @override
  String get signOut => 'Deconectare';

  @override
  String get disclaimer =>
      'Doar orientare IA — nu consultanță juridică. Consultați întotdeauna un avocat.';

  @override
  String get scanDocument => 'Scanați documentul';

  @override
  String get camera => 'Cameră';

  @override
  String get gallery => 'Galerie';

  @override
  String get saveAndAnalyze => 'Salvați și analizați';

  @override
  String get retry => 'Reîncercați';

  @override
  String get cancel => 'Anulați';

  @override
  String get confirm => 'Confirmați';

  @override
  String get error => 'Eroare';

  @override
  String get loading => 'Se încarcă...';

  @override
  String get home => 'Acasă';

  @override
  String get cases => 'Cazuri';

  @override
  String get deadlines => 'Termene';

  @override
  String get scan => 'Scanare';

  @override
  String goodMorning(String name) {
    return 'Bună dimineața, $name';
  }

  @override
  String goodAfternoon(String name) {
    return 'Bună ziua, $name';
  }

  @override
  String goodEvening(String name) {
    return 'Bună seara, $name';
  }

  @override
  String get caseOverview => 'Iată rezumatul cazurilor dvs.';

  @override
  String get activeCases => 'Cazuri active';

  @override
  String get recentActivity => 'Activitate recentă';

  @override
  String urgentDeadline(String title) {
    return 'Urgent: $title';
  }

  @override
  String daysRemaining(int count) {
    return '$count zile';
  }

  @override
  String get overdue => 'Depășit';

  @override
  String get upcoming => 'În curând';

  @override
  String get completed => 'Finalizat';

  @override
  String get markComplete => 'Marcați ca finalizat';

  @override
  String get deportation => 'Deportare';

  @override
  String get criminalCase => 'Caz penal';

  @override
  String get asylum => 'Azil';

  @override
  String get residencePermit => 'Permis de ședere';

  @override
  String get victimSupport => 'Sprijin pentru victime';

  @override
  String get familyReunification => 'Reîntregirea familiei';

  @override
  String get laborDispute => 'Conflict de muncă';

  @override
  String get tenantRights => 'Drepturile chiriașului';

  @override
  String get debtCollection => 'Recuperare creanțe';

  @override
  String get discrimination => 'Discriminare';

  @override
  String get policeMisconduct => 'Abuz polițienesc';

  @override
  String get socialBenefits => 'Prestații sociale';

  @override
  String get other => 'Altele';

  @override
  String get caseDetail => 'Detalii caz';

  @override
  String get aiAnalysis => 'Analiză IA';

  @override
  String get draftAppeal => 'Proiect de apel';

  @override
  String get aiChat => 'Chat IA';

  @override
  String get correspondence => 'Corespondență';

  @override
  String get analyzing => 'Se analizează...';

  @override
  String get readingDocument => 'Se citește documentul...';

  @override
  String get checkingErrors => 'Se verifică erorile...';

  @override
  String get researchingLaw => 'Se cercetează legislația aplicabilă...';

  @override
  String issuesFound(int count) {
    return '$count probleme găsite';
  }

  @override
  String get critical => 'Critic';

  @override
  String get important => 'Important';

  @override
  String get informational => 'Informativ';

  @override
  String get useInAppeal => 'Folosiți în apel';

  @override
  String get addedToAppeal => 'Adăugat la apel';

  @override
  String get generateAppeal => 'Generați apel';

  @override
  String get exportPdf => 'Exportați PDF';

  @override
  String get sendViaEmail => 'Trimiteți prin email';

  @override
  String get copyText => 'Copiați textul';

  @override
  String get editDraft => 'Editați';

  @override
  String get saveDraft => 'Salvați';

  @override
  String get reviewWarning =>
      'Revizuiți cu atenție înainte de trimitere. Sunteți responsabil pentru conținut.';

  @override
  String get disclaimerFull =>
      'Acesta este un asistent IA, nu un avocat. Analiza IA poate conține erori. Verificați întotdeauna cu un profesionist juridic calificat.';

  @override
  String get askAboutCase => 'Analizați cazul meu';

  @override
  String get whatAreMyOptions => 'Care sunt opțiunile mele?';

  @override
  String get checkDeadlines => 'Verificați termenele';

  @override
  String get typeMessage => 'Scrieți un mesaj...';

  @override
  String get connectEmail => 'Conectați emailul';

  @override
  String get connectGmail => 'Conectați Gmail';

  @override
  String get connectOutlook => 'Conectați Outlook';

  @override
  String get emailConnected => 'Email conectat';

  @override
  String get syncNow => 'Sincronizați acum';

  @override
  String get disconnect => 'Deconectați';

  @override
  String get emailPrivacyNote =>
      'Citim doar emailurile legate de chestiuni juridice. Emailurile personale rămân private.';

  @override
  String get pushNotifications => 'Notificări push';

  @override
  String get deadlineReminders => 'Memento-uri pentru termene';

  @override
  String get deadlineRemindersDesc => 'Primiți notificări înainte de termene';

  @override
  String get editProfile => 'Editați profilul';

  @override
  String get exportMyData => 'Exportați datele mele';

  @override
  String get exportDataDesc => 'Descărcați toate datele cazurilor dvs.';

  @override
  String get deleteAccount => 'Ștergeți contul';

  @override
  String get deleteAccountDesc => 'Eliminați permanent contul dvs.';

  @override
  String get deleteConfirm =>
      'Sunteți sigur? Toate datele dvs. vor fi șterse permanent.';

  @override
  String get about => 'Despre';

  @override
  String get version => 'Versiune';

  @override
  String get rateUs => 'Evaluați-ne';

  @override
  String get contactSupport => 'Contactați suportul';

  @override
  String get tryDemoMode => 'Încercați modul demo';

  @override
  String get demoModeDesc =>
      'Explorați aplicația cu date exemplu dintr-un caz real';

  @override
  String get free => 'Gratuit';

  @override
  String get basic => 'Bazic';

  @override
  String get pro => 'Pro';

  @override
  String get emergencyShield => 'Scut de urgență';

  @override
  String get legalFighter => 'Luptător juridic';

  @override
  String get fullDefense => 'Apărare completă';

  @override
  String get popular => 'POPULAR';

  @override
  String get currentPlan => 'Planul curent';

  @override
  String get choosePlan => 'Alegeți planul';

  @override
  String get saveWithAnnual => 'Economisiți 25% cu facturarea anuală';

  @override
  String get restorePurchases => 'Restaurați achizițiile';

  @override
  String get country => 'Țară';

  @override
  String get caseDescription => 'Descrieți situația dvs.';

  @override
  String get caseTitle => 'Titlul cazului';

  @override
  String get referenceNumber => 'Număr de referință';

  @override
  String get uploadDocument => 'Încărcați documentul';

  @override
  String get optional => '(opțional)';

  @override
  String step(int current, int total) {
    return 'Pasul $current din $total';
  }

  @override
  String get next => 'Următor';

  @override
  String get back => 'Înapoi';

  @override
  String get createCase => 'Creați caz';

  @override
  String get searchCases => 'Căutați cazuri...';

  @override
  String get all => 'Toate';

  @override
  String get active => 'Active';

  @override
  String get closed => 'Închise';

  @override
  String lastActivity(String time) {
    return 'Ultima activitate: $time';
  }

  @override
  String documentsCount(int count) {
    return '$count doc.';
  }

  @override
  String get noCasesYet => 'Încă nu există cazuri';

  @override
  String get startFirstCase => 'Începeți primul caz';

  @override
  String get noDeadlines => 'Fără termene — totul în ordine!';

  @override
  String get appealFiled => 'Apel depus';

  @override
  String get pendingDecision => 'Decizie în așteptare';

  @override
  String get inProgress => 'În desfășurare';

  @override
  String get won => 'Câștigat';

  @override
  String get lost => 'Pierdut';

  @override
  String get preferences => 'PREFERINȚE';

  @override
  String get notifications => 'NOTIFICĂRI';

  @override
  String get emailIntegration => 'INTEGRARE EMAIL';

  @override
  String get dataAndPrivacy => 'DATE ȘI CONFIDENȚIALITATE';

  @override
  String get legalSection => 'JURIDIC';

  @override
  String get aboutSection => 'DESPRE';

  @override
  String get appVersion => 'Versiunea aplicației';

  @override
  String get selectLanguage => 'Selectați limba';

  @override
  String get signOutConfirm => 'Sunteți sigur că doriți să vă deconectați?';

  @override
  String get emailDisconnected => 'Email deconectat';

  @override
  String get syncLegalCorrespondence => 'Sincronizați corespondența juridică';

  @override
  String get requestExport => 'Solicitați exportul';

  @override
  String get exportDataDialogContent =>
      'Vom pregăti o descărcare a tuturor datelor dvs., inclusiv cazuri, documente și corespondență. Veți primi un email când este gata.';

  @override
  String get deleteAccountDialogContent =>
      'Această acțiune este permanentă și irevocabilă. Toate datele, cazurile și documentele dvs. vor fi șterse permanent.';

  @override
  String get areYouAbsolutelySure => 'Sunteți absolut sigur?';

  @override
  String get typeDeleteToConfirm =>
      'Tastați DELETE pentru a confirma ștergerea permanentă a contului.';

  @override
  String get permanentlyDelete => 'Ștergeți permanent';

  @override
  String get dataExportRequested =>
      'Export de date solicitat. Verificați emailul.';

  @override
  String get connected => 'Conectat';

  @override
  String get caseUpdated => 'Caz actualizat';

  @override
  String get noRecentActivity => 'Fără activitate recentă';

  @override
  String get couldNotLoadCases => 'Nu s-au putut încărca cazurile dvs.';

  @override
  String get viewAll => 'Vedeți toate';

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
