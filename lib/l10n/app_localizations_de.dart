// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get about => 'Über';

  @override
  String get aboutSection => 'ÜBER';

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
  String get accidents => 'Unfälle';

  @override
  String get active => 'Aktiv';

  @override
  String get activeCases => 'Aktive Verfahren';

  @override
  String get addedToAppeal => 'Zum Widerspruch hinzugefügt';

  @override
  String get agreeToTerms => 'Ich stimme den ';

  @override
  String get aiAnalysis => 'KI-Analyse';

  @override
  String get aiAssistant => 'KI Rechtsassistent';

  @override
  String get aiChat => 'KI-Chat';

  @override
  String get all => 'Alle';

  @override
  String get alreadyHaveAccount => 'Bereits ein Konto? ';

  @override
  String get analyzing => 'Wird analysiert';

  @override
  String get aiAnalyzing => 'KI analysiert';

  @override
  String get speakIntoMicHint =>
      'Speak into the microphone. Make sure microphone access is enabled.';

  @override
  String get aiErrorRateLimit =>
      'Der Dienst ist vorübergehend überlastet. Bitte versuchen Sie es in 1-2 Minuten erneut.';

  @override
  String get aiErrorOverload =>
      'Die KI ist gerade ausgelastet, bitte versuchen Sie es in einer Minute erneut.';

  @override
  String freeLimitReached(int count) {
    return 'You have used all $count free AI messages. Upgrade to Legal Counsel for unlimited AI assistance!';
  }

  @override
  String get andWord => ' und ';

  @override
  String get appTitle => 'Advocat — Rechtsinformationswerkzeug';

  @override
  String get appVersion => 'App-Version';

  @override
  String get appealFiled => 'Widerspruch eingereicht';

  @override
  String get areYouAbsolutelySure => 'Sind Sie sich absolut sicher?';

  @override
  String get askAboutCase => 'Zum Verfahren fragen';

  @override
  String get asylum => 'Asyl';

  @override
  String get back => 'Zurück';

  @override
  String get basic => 'Basis';

  @override
  String get beforeYouBuy => 'Vor dem Kauf';

  @override
  String get beforeYouWork => 'Bevor Sie mit ihnen arbeiten';

  @override
  String get camera => 'Kamera';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get caseDescription => 'Verfahrensbeschreibung';

  @override
  String get caseDetail => 'Verfahrensdetails';

  @override
  String get caseOverview => 'Verfahrensübersicht';

  @override
  String get caseTitle => 'Verfahrenstitel';

  @override
  String get caseUpdated => 'Verfahren aktualisiert';

  @override
  String get cases => 'Verfahren';

  @override
  String get checkCompany => 'Firma prüfen';

  @override
  String get checkDeadlines => 'Fristen prüfen';

  @override
  String get checkVehicle => 'Fahrzeug prüfen';

  @override
  String get checkerTitle => 'Prüfer';

  @override
  String get checkingErrors => 'Fehlerprüfung';

  @override
  String get choosePlan => 'Tarif wählen';

  @override
  String get closed => 'Abgeschlossen';

  @override
  String get companyName => 'Firmenname oder Reg.-Nr.';

  @override
  String get completed => 'Abgeschlossen';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get confirmPassword => 'Passwort bestätigen';

  @override
  String get connectEmail => 'E-Mail verbinden';

  @override
  String get connectGmail => 'Gmail verbinden';

  @override
  String get connectOutlook => 'Outlook verbinden';

  @override
  String get connected => 'Verbunden';

  @override
  String get contactSupport => 'Support kontaktieren';

  @override
  String get continueWithGoogle => 'Weiter mit Google';

  @override
  String get appleComingSoon => 'Demnächst verfügbar';

  @override
  String get appleComingSoonMessage =>
      'Apple-Anmeldung wird bald verfügbar. Nutzen Sie Google oder E-Mail, um fortzufahren.';

  @override
  String get copyText => 'Text kopieren';

  @override
  String get correspondence => 'Korrespondenz';

  @override
  String get couldNotLoadCases => 'Ihre Verfahren konnten nicht geladen werden';

  @override
  String get country => 'Land';

  @override
  String get createAccount => 'Konto erstellen';

  @override
  String get createCase => 'Verfahren anlegen';

  @override
  String get criminalCase => 'Strafsache';

  @override
  String get critical => 'Kritisch';

  @override
  String get currentPlan => 'Aktueller Tarif';

  @override
  String get dataAndPrivacy => 'DATEN & DATENSCHUTZ';

  @override
  String get dataExportRequested =>
      'Datenexport angefordert. Überprüfen Sie Ihre E-Mail.';

  @override
  String daysRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '1 Tag',
      zero: 'keine Tage übrig',
    );
    return '$_temp0';
  }

  @override
  String get deadlineReminders => 'Fristenerinnerungen';

  @override
  String get deadlineRemindersDesc =>
      'Erhalten Sie Erinnerungen, bevor wichtige Fristen ablaufen';

  @override
  String get deadlines => 'Fristen';

  @override
  String get debtCollection => 'Inkasso';

  @override
  String get deleteAccount => 'Konto löschen';

  @override
  String get deleteAccountDesc =>
      'Löschen Sie Ihr Konto und alle Daten dauerhaft';

  @override
  String get deleteAccountDialogContent =>
      'Diese Aktion ist dauerhaft und kann nicht rückgängig gemacht werden. Alle Ihre Daten, Verfahren und Dokumente werden dauerhaft gelöscht.';

  @override
  String get deleteConfirm =>
      'Sind Sie sicher, dass Sie Ihr Konto löschen möchten? Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get demoHint => 'Demo: Kennzeichen „908FBT“ ausprobieren';

  @override
  String get demoModeDesc =>
      'Erkunden Sie die App mit Beispieldaten, ohne ein Konto zu erstellen';

  @override
  String get deportation => 'Abschiebung';

  @override
  String get disclaimer =>
      'Nur KI-gestützte Orientierung – keine Rechtsberatung. Konsultieren Sie stets einen Anwalt.';

  @override
  String get disclaimerFull =>
      'Dies ist eine KI-gestützte Orientierungshilfe und stellt keine Rechtsberatung dar. Sämtliche Inhalte sollten vor der Verwendung in rechtlichen Angelegenheiten von einem zugelassenen Anwalt geprüft werden.';

  @override
  String get disconnect => 'Trennen';

  @override
  String get discrimination => 'Diskriminierung';

  @override
  String get doNotBuy => 'Nicht kaufen';

  @override
  String get documents => 'Dokumente';

  @override
  String documentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Dokumente',
      one: '1 Dokument',
      zero: 'keine Dokumente',
    );
    return '$_temp0';
  }

  @override
  String get draftAppeal => 'Widerspruchsentwurf';

  @override
  String get editDraft => 'Entwurf bearbeiten';

  @override
  String get editProfile => 'Profil bearbeiten';

  @override
  String get email => 'E-Mail';

  @override
  String get emailConnected => 'E-Mail verbunden';

  @override
  String get emailDisconnected => 'E-Mail getrennt';

  @override
  String get emailIntegration => 'E-MAIL-INTEGRATION';

  @override
  String get emailInvalid => 'Bitte geben Sie eine gültige E-Mail-Adresse ein';

  @override
  String get emailPrivacyNote =>
      'Ihre E-Mail wird ausschließlich für verfahrensbezogene Korrespondenz verwendet und sicher gespeichert.';

  @override
  String get emailRequired => 'E-Mail-Adresse ist erforderlich';

  @override
  String get emergencyShield => 'Notfallschutz';

  @override
  String get error => 'Fehler';

  @override
  String get exportDataDesc =>
      'Laden Sie alle Ihre Verfahrensdaten und Dokumente herunter';

  @override
  String get exportDataDialogContent =>
      'Wir bereiten einen Download aller Ihrer Daten vor, einschließlich Verfahren, Dokumente und Korrespondenz. Sie erhalten eine E-Mail, wenn es fertig ist.';

  @override
  String get exportMyData => 'Meine Daten exportieren';

  @override
  String get exportPdf => 'PDF exportieren';

  @override
  String get familyReunification => 'Familienzusammenführung';

  @override
  String get forgotPassword => 'Passwort vergessen?';

  @override
  String get free => 'Kostenlos';

  @override
  String get fullDefense => 'Advocat Pro';

  @override
  String get fullName => 'Vollständiger Name';

  @override
  String get gallery => 'Galerie';

  @override
  String get generateAppeal => 'Widerspruch erstellen';

  @override
  String get getStarted => 'Jetzt starten';

  @override
  String goodAfternoon(String name) {
    return 'Guten Tag, $name';
  }

  @override
  String goodEvening(String name) {
    return 'Guten Abend, $name';
  }

  @override
  String goodMorning(String name) {
    return 'Guten Morgen, $name';
  }

  @override
  String goodNight(String name) {
    return 'Gute Nacht, $name';
  }

  @override
  String get home => 'Startseite';

  @override
  String get important => 'Wichtig';

  @override
  String get inProgress => 'In Bearbeitung';

  @override
  String get informational => 'Informativ';

  @override
  String get inspection => 'Technische Inspektion';

  @override
  String get insurance => 'Versicherung';

  @override
  String issuesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Probleme gefunden',
      one: '1 Problem gefunden',
      zero: 'keine Probleme gefunden',
    );
    return '$_temp0';
  }

  @override
  String get laborDispute => 'Arbeitsstreitigkeiten';

  @override
  String get langEnglish => 'Englisch';

  @override
  String get langFinnish => 'Finnisch';

  @override
  String get langRussian => 'Russisch';

  @override
  String get language => 'Sprache';

  @override
  String lastActivity(String time) {
    return 'Letzte Aktivität: $time';
  }

  @override
  String get legalFighter => 'Rechtskämpfer';

  @override
  String get legalSection => 'RECHTLICHES';

  @override
  String get licensePlate => 'Kennzeichen';

  @override
  String get loading => 'Wird geladen…';

  @override
  String get logIn => 'Anmelden';

  @override
  String get loginFailed =>
      'Ungültige E-Mail-Adresse oder ungültiges Passwort. Bitte versuchen Sie es erneut.';

  @override
  String get lost => 'Verloren';

  @override
  String get markComplete => 'Als abgeschlossen markieren';

  @override
  String get mileage => 'Kilometerstand';

  @override
  String get myCases => 'Meine Verfahren';

  @override
  String get nameRequired => 'Vollständiger Name ist erforderlich';

  @override
  String get newCase => 'Neues Verfahren';

  @override
  String get next => 'Weiter';

  @override
  String get noAccount => 'Noch kein Konto? ';

  @override
  String get noCases => 'Noch keine Verfahren';

  @override
  String get noCasesYet => 'Noch keine Verfahren';

  @override
  String get noDeadlines => 'Keine Fristen';

  @override
  String get noRecentActivity => 'Keine kürzliche Aktivität';

  @override
  String get notifications => 'BENACHRICHTIGUNGEN';

  @override
  String get onboardingDesc1 =>
      'Advocat hilft Ihnen, Ihre rechtliche Situation zu verstehen. KI-Werkzeuge analysieren Dokumente, identifizieren mögliche Probleme und erstellen Dokumententwürfe zu Ihrer Überprüfung. Keine Anwaltskanzlei — ein Technologiewerkzeug zur Unterstützung Ihres Falls.';

  @override
  String get onboardingDesc2 =>
      'Fotografieren Sie jedes Rechtsdokument. Die KI liest es in mehreren Sprachen, extrahiert wichtige Details und prüft anhand von EU-Richtlinien und nationalen Gesetzen auf mögliche Probleme.';

  @override
  String get onboardingDesc3 =>
      'Unsere KI-Werkzeuge prüfen über 40 Arten von Verfahrensanforderungen. Die KI-Analyse kann Punkte identifizieren, die Aufmerksamkeit erfordern — wie Zustellungssprache, Verfahrensschritte und rechtliche Fristen. Überprüfen Sie immer mit einem qualifizierten Anwalt.';

  @override
  String get onboardingDesc4 =>
      'Die KI erstellt Entwürfe für Widersprüche, Beschwerden und Schreiben mit Rechtsverweisen zu Ihrer Überprüfung. Sie entscheiden, was eingereicht wird. Jedes Dokument sollte vor der Einreichung von einem qualifizierten Rechtsexperten geprüft werden.';

  @override
  String get onboardingNext => 'Weiter';

  @override
  String get onboardingSkip => 'Überspringen';

  @override
  String get onboardingTitle1 => 'KI-gestützte Rechtsinformation';

  @override
  String get onboardingTitle2 => 'Dokumente scannen und analysieren';

  @override
  String get onboardingTitle3 => 'KI prüft auf mögliche Probleme';

  @override
  String get onboardingTitle4 => 'Dokumententwürfe zu Ihrer Überprüfung';

  @override
  String get openACase => 'Fall eröffnen';

  @override
  String get optional => 'Optional';

  @override
  String get orDivider => 'oder';

  @override
  String get other => 'Sonstiges';

  @override
  String get overdue => 'Überfällig';

  @override
  String get owners => 'Vorbesitzer';

  @override
  String get password => 'Passwort';

  @override
  String get passwordRequired => 'Passwort ist erforderlich';

  @override
  String get passwordStrengthMedium => 'Mittel';

  @override
  String get passwordStrengthStrong => 'Stark';

  @override
  String get passwordStrengthWeak => 'Schwach';

  @override
  String get passwordTooShort =>
      'Das Passwort muss mindestens 8 Zeichen lang sein';

  @override
  String get passwordsDoNotMatch => 'Die Passwörter stimmen nicht überein';

  @override
  String get pendingDecision => 'Bescheid ausstehend';

  @override
  String get perCheck => 'pro Prüfung';

  @override
  String get permanentlyDelete => 'Dauerhaft löschen';

  @override
  String get policeMisconduct => 'Polizeiverhalten';

  @override
  String get popular => 'Beliebt';

  @override
  String get preferences => 'EINSTELLUNGEN';

  @override
  String get preferredLanguage => 'Bevorzugte Sprache';

  @override
  String get pricePerCheck => '4,99 € pro Prüfung';

  @override
  String get privacyPolicy => 'Datenschutzrichtlinie';

  @override
  String get dpaTitle => 'Auftragsverarbeitungsvertrag';

  @override
  String get dpaCheckoutGateTitle => 'Vor dem Upgrade';

  @override
  String get dpaCheckoutGateBody =>
      'Das EU-Recht (Art. 28 DSGVO) verpflichtet uns, mit jedem zahlenden Kunden einen Auftragsverarbeitungsvertrag zu schließen. Bitte prüfen und akzeptieren Sie diesen.';

  @override
  String get dpaViewLink => 'Auftragsverarbeitungsvertrag ansehen';

  @override
  String get dpaCheckboxLabel =>
      'Ich habe den Auftragsverarbeitungsvertrag (v1.0) gelesen und akzeptiere ihn.';

  @override
  String get dpaCancel => 'Abbrechen';

  @override
  String get dpaAcceptAndContinue => 'Akzeptieren und fortfahren';

  @override
  String get dpaOpenHint =>
      'Öffnen Sie den AVV mindestens einmal, um die Schaltfläche „Akzeptieren“ freizuschalten.';

  @override
  String get pro => 'Pro';

  @override
  String get pushNotifications => 'Push-Benachrichtigungen';

  @override
  String get rateUs => 'Bewerten Sie uns';

  @override
  String get rateAppComingSoon => 'Coming to app stores soon!';

  @override
  String get dataCopiedToClipboard => 'Data copied to clipboard';

  @override
  String get readingDocument => 'Dokument wird gelesen';

  @override
  String get recentActivity => 'Letzte Aktivität';

  @override
  String get referenceNumber => 'Aktenzeichen';

  @override
  String get registerFailed =>
      'Registrierung fehlgeschlagen. Bitte versuchen Sie es erneut.';

  @override
  String get reportFraud => 'Betrug melden';

  @override
  String get requestExport => 'Export anfordern';

  @override
  String get researchingLaw => 'Rechtliche Recherche';

  @override
  String get resetPasswordFailed =>
      'Der Zurücksetzungslink konnte nicht gesendet werden. Bitte versuchen Sie es erneut.';

  @override
  String get resetPasswordSent =>
      'Ein Link zum Zurücksetzen des Passworts wurde an Ihre E-Mail-Adresse gesendet.';

  @override
  String get residencePermit => 'Aufenthaltstitel';

  @override
  String get manageSubscription => 'Abonnement verwalten';

  @override
  String get restorePurchases => 'Käufe wiederherstellen';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get reviewWarning => 'Überprüfungshinweis';

  @override
  String get riskHigh => 'Hohes Risiko — vermeiden';

  @override
  String get riskLow => 'Sicher zur Zusammenarbeit';

  @override
  String get riskMedium => 'Mit Vorsicht vorgehen';

  @override
  String get safeToBuy => 'Sicher zu kaufen';

  @override
  String get saveAndAnalyze => 'Speichern und analysieren';

  @override
  String get saveDraft => 'Entwurf speichern';

  @override
  String get saveWithAnnual => 'Mit Jahresabo sparen';

  @override
  String get scan => 'Scannen';

  @override
  String get scanDocument => 'Dokument scannen';

  @override
  String get searchCases => 'Verfahren suchen';

  @override
  String get selectCountry => 'Land auswählen';

  @override
  String get selectLanguage => 'Sprache wählen';

  @override
  String get sendViaEmail => 'Per E-Mail senden';

  @override
  String get settings => 'Einstellungen';

  @override
  String get signIn => 'Anmelden';

  @override
  String get signInLink => 'Anmelden';

  @override
  String get signInSubtitle =>
      'Melden Sie sich an, um auf Ihre Verfahren zuzugreifen';

  @override
  String get signOut => 'Abmelden';

  @override
  String get signOutConfirm =>
      'Sind Sie sicher, dass Sie sich abmelden möchten?';

  @override
  String get signUp => 'Konto erstellen';

  @override
  String get signUpLink => 'Registrieren';

  @override
  String get socialBenefits => 'Sozialleistungen';

  @override
  String get someConcerns => 'Einige Bedenken';

  @override
  String get startFirstCase => 'Erstellen Sie Ihr erstes Verfahren';

  @override
  String step(int current, int total) {
    return 'Schritt $current von $total';
  }

  @override
  String get stolen => 'Diebstahlprüfung';

  @override
  String get subscription => 'Abonnement';

  @override
  String get syncLegalCorrespondence =>
      'Rechtliche Korrespondenz synchronisieren';

  @override
  String get syncNow => 'Jetzt synchronisieren';

  @override
  String get tenantRights => 'Mieterrechte';

  @override
  String get termsOfService => 'Nutzungsbedingungen';

  @override
  String get termsRequired => 'Sie müssen den Nutzungsbedingungen zustimmen';

  @override
  String get timeline => 'Zeitverlauf';

  @override
  String get tryDemoMode => 'Demomodus testen';

  @override
  String get typeDeleteToConfirm =>
      'Geben Sie DELETE ein, um die permanente Kontolöschung zu bestätigen.';

  @override
  String get typeMessage => 'Nachricht eingeben';

  @override
  String get upcoming => 'Anstehend';

  @override
  String get uploadDocument => 'Dokument hochladen';

  @override
  String urgentDeadline(String title) {
    return 'Dringend: $title';
  }

  @override
  String get useInAppeal => 'Im Widerspruch verwenden';

  @override
  String get vehicleChecker => 'Fahrzeugprüfer';

  @override
  String get vehicleChecks => 'Statusprüfungen';

  @override
  String get vehicleColor => 'Farbe';

  @override
  String get vehicleMake => 'Marke';

  @override
  String get vehicleModel => 'Modell';

  @override
  String get vehicleYear => 'Baujahr';

  @override
  String get version => 'Version';

  @override
  String get victimSupport => 'Opferhilfe';

  @override
  String get viewAll => 'Alle anzeigen';

  @override
  String get vinNumber => 'Fahrgestellnummer';

  @override
  String get welcomeBack => 'Willkommen zurück';

  @override
  String get whatAreMyOptions => 'Welche Möglichkeiten habe ich?';

  @override
  String get won => 'Gewonnen';

  @override
  String get documentVault => 'Dokumententresor';

  @override
  String get secureDocumentStorage => 'Sichere Dokumentenablage';

  @override
  String get secureDocumentStorageDesc =>
      'Bewahren Sie Ihre wichtigen Rechtsdokumente an einem Ort für einfachen Zugriff auf.';

  @override
  String get addDocument => 'Dokument hinzufügen';

  @override
  String get chooseHowToAdd =>
      'Wählen Sie, wie Sie Ihr Dokument hinzufügen möchten';

  @override
  String get uploadFile => 'Datei hochladen';

  @override
  String get uploadFileDesc =>
      'Wählen Sie eine PDF- oder Bilddatei von Ihrem Gerät';

  @override
  String get scanDocumentDesc => 'Fotografieren Sie Ihr Dokument';

  @override
  String get createNote => 'Notiz erstellen';

  @override
  String get createNoteDesc =>
      'Eine Notiz schreiben oder wichtige Details festhalten';

  @override
  String get knowYourRights => 'Kennen Sie Ihre Rechte';

  @override
  String get stoppedByPolice => 'Von der Polizei angehalten';

  @override
  String get stoppedByPoliceDesc => 'Ihre Rechte bei einer Polizeikontrolle';

  @override
  String get deportationNotice => 'Abschiebungsbescheid';

  @override
  String get deportationNoticeDesc =>
      'Schritte zur Anfechtung einer Abschiebungsanordnung';

  @override
  String get workplaceRights => 'Arbeitsplatzrechte';

  @override
  String get workplaceRightsDesc => 'Arbeitsrechtlicher Schutz in Finnland';

  @override
  String get tenantRightsDesc => 'Wohn- und Mieterschutz';

  @override
  String get immigrationDetention => 'Einwanderungshaft';

  @override
  String get immigrationDetentionDesc =>
      'Rechte bei Inhaftierung durch Behörden';

  @override
  String get discriminationDesc =>
      'Wie man Diskriminierung meldet und bekämpft';

  @override
  String get scenarioNotFound => 'Szenario nicht gefunden';

  @override
  String get youHaveRightTo => 'Sie haben das Recht auf:';

  @override
  String get youMust => 'Sie müssen:';

  @override
  String get immediateSteps => 'Sofortmaßnahmen:';

  @override
  String get yourRights => 'Ihre Rechte:';

  @override
  String get basicRights => 'Grundrechte:';

  @override
  String get yourRightsAsTenant => 'Ihre Rechte als Mieter:';

  @override
  String get yourRightsInDetention => 'Ihre Rechte in Haft:';

  @override
  String get howToAct => 'Wie Sie handeln sollten:';

  @override
  String get rightKnowWhyStopped => 'Wissen, warum Sie angehalten werden';

  @override
  String get rightRemainSilent => 'Schweigen (Sie müssen sich ausweisen)';

  @override
  String get rightAskInterpreter => 'Einen Dolmetscher verlangen';

  @override
  String get rightContactLawyer =>
      'Vor der Vernehmung einen Anwalt kontaktieren';

  @override
  String get rightRecordEncounter =>
      'Die Begegnung aufzeichnen (an öffentlichen Orten)';

  @override
  String get mustProvideName => 'Namen und Geburtsdatum angeben';

  @override
  String get mustShowId => 'Ausweis zeigen, falls vorhanden';

  @override
  String get mustNotResist => 'Keinen physischen Widerstand leisten';

  @override
  String get doNotIgnoreNotice =>
      'Den Bescheid NICHT ignorieren – Fristen sind streng';

  @override
  String get noteAppealDeadline =>
      'Einspruchsfrist beachten (normalerweise 30 Tage)';

  @override
  String get contactLawyerImmediately => 'Sofort einen Anwalt kontaktieren';

  @override
  String get applyLegalAid => 'Bei Bedarf Prozesskostenhilfe beantragen';

  @override
  String get rightAppealAdmin => 'Recht auf Einspruch beim Verwaltungsgericht';

  @override
  String get rightLegalRep => 'Recht auf rechtliche Vertretung';

  @override
  String get rightInterpreter => 'Recht auf einen Dolmetscher';

  @override
  String get rightStayDuringAppeal =>
      'Recht, während des Einspruchs zu bleiben (in den meisten Fällen)';

  @override
  String get minimumWage => 'Mindestlohn gemäß Tarifvertrag';

  @override
  String get workingTimeLimits =>
      'Arbeitszeitgrenzen (max. 8 Std./Tag, 40 Std./Woche)';

  @override
  String get annualLeave =>
      'Jahresurlaub (mindestens 2 Tage pro gearbeitetem Monat)';

  @override
  String get sickLeave => 'Lohnfortzahlung im Krankheitsfall';

  @override
  String get safeWorkingConditions => 'Sichere Arbeitsbedingungen';

  @override
  String get writtenRentalAgreement => 'Schriftlicher Mietvertrag erforderlich';

  @override
  String get securityDeposit => 'Kaution max. 3 Monatsmieten';

  @override
  String get landlordNotice => 'Vermieter muss kündigen (3–6 Monate)';

  @override
  String get rightHabitableDwelling => 'Recht auf eine bewohnbare Wohnung';

  @override
  String get protectionUnjustEviction =>
      'Schutz vor ungerechtfertigter Räumung';

  @override
  String get rightKnowDetentionReason =>
      'Recht, den Grund der Inhaftierung zu erfahren';

  @override
  String get rightContactLawyerDetention =>
      'Recht, einen Anwalt zu kontaktieren';

  @override
  String get rightContactEmbassy => 'Recht, Ihre Botschaft zu kontaktieren';

  @override
  String get rightChallengeDetention =>
      'Recht, die Haft gerichtlich anzufechten';

  @override
  String get rightHumaneTreatment =>
      'Recht auf menschenwürdige Behandlung und medizinische Versorgung';

  @override
  String get documentIncident =>
      'Vorfall dokumentieren (Datum, Uhrzeit, Zeugen)';

  @override
  String get fileComplaintOmbudsman =>
      'Beschwerde beim Antidiskriminierungsbeauftragten einreichen';

  @override
  String get contactLegalAidOffice => 'Rechtsberatungsstelle kontaktieren';

  @override
  String get reportToPolice =>
      'Bei Straftaten Polizei einschalten (Bedrohung, Körperverletzung)';

  @override
  String get legalAidCalculator => 'Prozesskostenhilfe-Rechner';

  @override
  String checkEligibility(String country) {
    return 'Prüfen Sie Ihren Anspruch auf Prozesskostenhilfe: $country';
  }

  @override
  String get estimateDisclaimer =>
      'Dies ist nur eine Schätzung. Die tatsächliche Berechtigung wird vom Rechtsberatungsbüro festgestellt.';

  @override
  String get monthlyIncome => 'Monatliches Einkommen (EUR)';

  @override
  String get totalAssets => 'Gesamtvermögen (EUR)';

  @override
  String get numberOfDependents => 'Anzahl der Unterhaltsberechtigten';

  @override
  String get calculateEligibility => 'Anspruch berechnen';

  @override
  String get likelyEligible => 'Wahrscheinlich berechtigt';

  @override
  String get mayNotQualify => 'Möglicherweise nicht berechtigt';

  @override
  String get fullFreeLegalAid =>
      'Sie qualifizieren sich wahrscheinlich für kostenlose Prozesskostenhilfe (ohne Zuzahlung).';

  @override
  String legalAidWithCopay(String percent) {
    return 'Sie qualifizieren sich möglicherweise für Prozesskostenhilfe mit einer Zuzahlung von $percent%.';
  }

  @override
  String get mayNotQualifyDesc =>
      'Basierend auf dieser Schätzung qualifizieren Sie sich möglicherweise nicht für staatliche Prozesskostenhilfe. Erwägen Sie einen Privatanwalt oder eine Rechtsberatungsstelle.';

  @override
  String get couldNotLoadDeadlines => 'Fristen konnten nicht geladen werden';

  @override
  String get noUpcomingDeadlines => 'Keine anstehenden Fristen';

  @override
  String get allClearDeadlines =>
      'Alles erledigt! Neue Fristen erscheinen hier, wenn sie gesetzt werden.';

  @override
  String get nothingOverdue => 'Nichts überfällig';

  @override
  String get greatJobDeadlines =>
      'Gut gemacht, Sie behalten Ihre Fristen im Blick.';

  @override
  String get noCompletedDeadlines => 'Keine erledigten Fristen';

  @override
  String get completedDeadlinesDesc =>
      'Erledigte Fristen werden hier angezeigt.';

  @override
  String get daysLate => 'Tage überfällig';

  @override
  String get days => 'Tage';

  @override
  String get fromDocument => 'Aus Dokument';

  @override
  String get couldNotLoadCase => 'Falldetails konnten nicht geladen werden';

  @override
  String get typeLabel => 'Typ';

  @override
  String get nationality => 'Staatsangehörigkeit';

  @override
  String get migriReference => 'Migri-Referenz';

  @override
  String get courtCaseNo => 'Gerichtsaktenzeichen';

  @override
  String get created => 'Erstellt';

  @override
  String get citizenship => 'Staatsangehörigkeit';

  @override
  String get workPermit => 'Arbeitserlaubnis';

  @override
  String get noDocumentsYet => 'Noch keine Dokumente hochgeladen';

  @override
  String get noUpcomingDeadlinesShort => 'Keine anstehenden Fristen';

  @override
  String get caseCreated => 'Fall erstellt';

  @override
  String get decisionReceived => 'Entscheidung erhalten';

  @override
  String get appealDeadline => 'Einspruchsfrist';

  @override
  String get hearingScheduled => 'Anhörung geplant';

  @override
  String get late => 'überfällig';

  @override
  String get pending => 'Ausstehend';

  @override
  String get processing => 'Verarbeitung';

  @override
  String get ready => 'Bereit';

  @override
  String get failed => 'Fehlgeschlagen';

  @override
  String get analyzed => 'Analysiert';

  @override
  String get noDocumentsScanHint =>
      'Noch keine Dokumente. Scannen oder hochladen.';

  @override
  String get inCourt => 'Vor Gericht';

  @override
  String get appeal => 'Einspruch';

  @override
  String get caseTimeline => 'Fallzeitleiste';

  @override
  String get couldNotLoadTimeline => 'Zeitleiste konnte nicht geladen werden';

  @override
  String get noEventsYet => 'Noch keine Ereignisse';

  @override
  String get activityWillAppear =>
      'Aktivitäten werden hier angezeigt, wenn Ihr Fall voranschreitet.';

  @override
  String caseCreatedDesc(String title) {
    return 'Fall „$title“ wurde erstellt.';
  }

  @override
  String get decisionReceivedDesc =>
      'Eine offizielle Entscheidung wurde für diesen Fall erhalten.';

  @override
  String get appealDeadlineSet => 'Einspruchsfrist gesetzt';

  @override
  String appealDeadlineDesc(String date) {
    return 'Einspruch muss bis $date eingereicht werden.';
  }

  @override
  String hearingScheduledDesc(String date) {
    return 'Gerichtsverhandlung geplant für $date.';
  }

  @override
  String get caseInfoUpdated =>
      'Fallinformationen wurden zuletzt aktualisiert.';

  @override
  String get noEventsForFilter => 'Keine Ereignisse entsprechen diesem Filter';

  @override
  String get timelineFilterAll => 'Alle';

  @override
  String get timelineFilterEmails => 'E-Mails';

  @override
  String get timelineFilterConsilium => 'KI-Entscheidungen';

  @override
  String get timelineFilterDeadlines => 'Fristen';

  @override
  String get timelineFilterNotes => 'Notizen';

  @override
  String get timelineEventEmailIn => 'E-Mail empfangen';

  @override
  String get timelineEventEmailOut => 'E-Mail gesendet';

  @override
  String get timelineEventConsiliumDecision => 'KI-Entscheidung';

  @override
  String get timelineEventDeadlineSet => 'Frist';

  @override
  String get timelineEventDocUploaded => 'Dokument';

  @override
  String get timelineEventPhaseChange => 'Phasenwechsel';

  @override
  String get timelineEventManualNote => 'Notiz';

  @override
  String get timelineJustNow => 'Gerade eben';

  @override
  String timelineMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Minuten',
      one: 'vor 1 Minute',
    );
    return '$_temp0';
  }

  @override
  String timelineHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Stunden',
      one: 'vor 1 Stunde',
    );
    return '$_temp0';
  }

  @override
  String timelineDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Tagen',
      one: 'vor 1 Tag',
    );
    return '$_temp0';
  }

  @override
  String get documentAnalysis => 'Dokumentenanalyse';

  @override
  String get exportAsPdf => 'Als PDF exportieren';

  @override
  String get pdfExportComingSoon => 'PDF-Export kommt bald';

  @override
  String get analysisFailedRetry =>
      'Analyse fehlgeschlagen. Bitte erneut versuchen.';

  @override
  String get somethingWentWrong => 'Etwas ist schiefgelaufen';

  @override
  String get genericError =>
      'Etwas ist schiefgelaufen. Bitte versuchen Sie es erneut.';

  @override
  String get retryAnalysis => 'Analyse wiederholen';

  @override
  String issuesFoundInDocument(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Probleme im Dokument gefunden',
      one: '1 Problem im Dokument gefunden',
      zero: 'Keine Probleme im Dokument gefunden',
    );
    return '$_temp0';
  }

  @override
  String get severityOverview => 'Schweregrad-Übersicht';

  @override
  String get issuesFoundHeader => 'Gefundene Probleme';

  @override
  String generateAppealWithIssues(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Beschwerde erstellen ($count Probleme)',
      one: 'Beschwerde erstellen (1 Problem)',
    );
    return '$_temp0';
  }

  @override
  String get analyzingContent => 'Inhalt wird analysiert…';

  @override
  String get documentProcessedOk => 'Dokument erfolgreich verarbeitet';

  @override
  String get noSignificantIssues =>
      'Keine wesentlichen Probleme in diesem Dokument erkannt.';

  @override
  String get cameraPermissionRequired => 'Kameraberechtigung erforderlich';

  @override
  String get cameraPermissionDesc =>
      'Kamerazugriff zum Scannen von Dokumenten gewähren oder die Galerie verwenden.';

  @override
  String get openSettings => 'Einstellungen öffnen';

  @override
  String get alignDocument => 'Dokument im Rahmen ausrichten';

  @override
  String pageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Seiten',
      one: '1 Seite',
      zero: 'keine Seiten',
    );
    return '$_temp0';
  }

  @override
  String get preview => 'Vorschau';

  @override
  String pageNumber(int number) {
    return 'Seite $number';
  }

  @override
  String get done => 'Fertig';

  @override
  String get retake => 'Neu aufnehmen';

  @override
  String get useThisPhoto => 'Dieses Foto verwenden';

  @override
  String get addPage => 'Seite hinzufügen';

  @override
  String uploadingPercent(int percent) {
    return 'Hochladen… $percent%';
  }

  @override
  String get preparingUpload => 'Upload wird vorbereitet…';

  @override
  String get documentUploadedSuccess => 'Dokument erfolgreich hochgeladen';

  @override
  String pagesUploadedSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Seiten erfolgreich hochgeladen',
      one: '1 Seite erfolgreich hochgeladen',
    );
    return '$_temp0';
  }

  @override
  String get uploadFailed =>
      'Upload fehlgeschlagen. Bitte überprüfen Sie Ihre Verbindung und versuchen Sie es erneut.';

  @override
  String get capturePhotoFailed =>
      'Foto konnte nicht aufgenommen werden. Bitte erneut versuchen.';

  @override
  String get readingText => 'Text wird gelesen…';

  @override
  String get draftDocument => 'Dokument entwerfen';

  @override
  String get saveChanges => 'Änderungen speichern';

  @override
  String get editDocument => 'Dokument bearbeiten';

  @override
  String get generatingDraft => 'Ihr Entwurf wird erstellt…';

  @override
  String get generatingDraftDesc =>
      'KI bereitet ein Rechtsdokument basierend auf Ihren Falldetails und ausgewählten Problemen vor.';

  @override
  String get failedToGenerateDraft =>
      'Entwurf konnte nicht erstellt werden. Bitte erneut versuchen.';

  @override
  String get changesSaved => 'Änderungen gespeichert';

  @override
  String get copiedToClipboard => 'In die Zwischenablage kopiert';

  @override
  String get emailComingSoon => 'E-Mail-Versand kommt bald';

  @override
  String get reviewBeforeSending =>
      'Vor dem Senden sorgfältig prüfen. Sie sind für den Inhalt dieses Dokuments verantwortlich.';

  @override
  String get noContentAvailable => 'Kein Inhalt verfügbar';

  @override
  String get save => 'Speichern';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get pdf => 'PDF';

  @override
  String get copy => 'Kopieren';

  @override
  String get appealDraft => 'Einspruchsentwurf';

  @override
  String selected(int count) {
    return '$count ausgewählt';
  }

  @override
  String get deleteSelected => 'Ausgewählte löschen';

  @override
  String deleteDocumentsConfirm(int count) {
    return '$count Dokumente löschen?';
  }

  @override
  String get delete => 'Löschen';

  @override
  String get analyzeSelected => 'Ausgewählte analysieren';

  @override
  String get batchAnalysisStarting => 'Stapelanalyse wird gestartet…';

  @override
  String get switchToList => 'Zur Listenansicht wechseln';

  @override
  String get switchToGrid => 'Zur Rasteransicht wechseln';

  @override
  String get scanNew => 'Neu scannen';

  @override
  String get noDocumentsYetScan => 'Noch keine Dokumente';

  @override
  String get scanFirstDocumentHint =>
      'Scannen Sie Ihr erstes Dokument, damit die KI es auf Fehler analysieren und Einsprüche erstellen kann.';

  @override
  String get failedToLoadDocuments => 'Dokumente konnten nicht geladen werden';

  @override
  String get emailIntegrationTitle => 'E-Mail-Integration';

  @override
  String get connectYourEmail => 'E-Mail verbinden';

  @override
  String get connectYourEmailDesc =>
      'Verbinden Sie Ihre E-Mail, um rechtliche Korrespondenz zu Ihren Fällen automatisch zu erkennen.';

  @override
  String get legalEmails => 'Rechtliche E-Mails';

  @override
  String get unlinkedEmails => 'Nicht verknüpfte E-Mails';

  @override
  String get noLegalEmailsYet => 'Noch keine rechtlichen E-Mails';

  @override
  String get legalEmailsWillAppear =>
      'Als rechtlich eingestufte E-Mails erscheinen hier.';

  @override
  String get assignToCase => 'Dem Fall zuordnen';

  @override
  String get disconnectEmail => 'E-Mail trennen';

  @override
  String get disconnectEmailConfirm =>
      'Die automatische E-Mail-Synchronisierung wird gestoppt. Zuvor synchronisierte E-Mails bleiben in Ihren Fällen.';

  @override
  String get gmailReauthBannerBody =>
      'Advocat v2.1 liest Ihren Posteingang, um Antworten zu entwerfen; Sie können dies jederzeit widerrufen. Verbinden Sie Gmail erneut, um die proaktive Triage zu aktivieren.';

  @override
  String get gmailReauthBannerCta => 'Erneut autorisieren';

  @override
  String connectedTo(String email) {
    return 'Verbunden mit $email';
  }

  @override
  String lastSynced(String time) {
    return 'Zuletzt synchronisiert: $time';
  }

  @override
  String get filterByType => 'Nach Typ filtern';

  @override
  String get noCasesMatchSearch => 'Keine Fälle entsprechen Ihrer Suche';

  @override
  String get failedToLoadCases => 'Fälle konnten nicht geladen werden';

  @override
  String get monthly => 'Monatlich';

  @override
  String get annual => 'Jährlich';

  @override
  String get saveTwentyFivePercent => '25% sparen';

  @override
  String get mostPopular => 'BELIEBTESTE';

  @override
  String get oneCaseActive => '1 aktiver Fall';

  @override
  String get threeCasesActive => '3 aktive Fälle';

  @override
  String get unlimitedCases => 'Unbegrenzte Fälle';

  @override
  String get threeDocScans => '3 Dokumentenscans';

  @override
  String get twentyDocScans => '20 Dokumentenscans';

  @override
  String get unlimitedDocScans => 'Unbegrenztes Dokumentenscannen';

  @override
  String get basicAiAnalysis => 'Basis-KI-Analyse';

  @override
  String get fullAiAnalysis => 'Volle KI-Analyse';

  @override
  String get draftGeneration => 'Entwurfserstellung';

  @override
  String get priorityProcessing => 'Prioritätsbearbeitung';

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
  String get forever => 'unbegrenzt';

  @override
  String get perMonth => '/Monat';

  @override
  String get perYear => '/Jahr';

  @override
  String get checkingPurchases => 'Frühere Käufe werden geprüft…';

  @override
  String get noPreviousPurchases => 'Keine früheren Käufe gefunden.';

  @override
  String get chatWelcomeMessage =>
      'Hallo! Ich bin Advocat — Ihr KI-Rechtsassistent. Ich liefere Rechtsinformationen, keine Rechtsberatung. Bei welcher Rechtsfrage kann ich helfen?';

  @override
  String get copySummary => 'Zusammenfassung kopieren';

  @override
  String get caseSummaryCopied => 'Fallzusammenfassung kopiert';

  @override
  String get openCase => 'Fall öffnen';

  @override
  String get viewFull => 'Vollständig anzeigen';

  @override
  String get draftCopiedToClipboard => 'Entwurf in die Zwischenablage kopiert';

  @override
  String get reportMileageFraud => 'Kilometerbetrug melden';

  @override
  String get reportMileageFraudDesc =>
      'Es wird ein Betrugsbericht basierend auf den Fahrzeugprüfdaten erstellt. Sie können auch einen Rechtsfall eröffnen.';

  @override
  String get reportAndOpenCase => 'Melden und Fall eröffnen';

  @override
  String get caseCreationComingSoon =>
      'Fallerstellung mit vorausgefüllten Daten kommt bald';

  @override
  String get failedToCreateCaseRetry =>
      'Fall konnte nicht erstellt werden. Bitte erneut versuchen.';

  @override
  String get takePhotoInstead => 'Stattdessen Foto aufnehmen';

  @override
  String get deleteCase => 'Fall löschen';

  @override
  String deleteCaseConfirm(String title) {
    return 'Möchten Sie „$title“ wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.';
  }

  @override
  String get haveQuestionsAi => 'Fragen? Fragen Sie die KI';

  @override
  String get cookiePolicy => 'Cookie-Richtlinie';

  @override
  String get aiDisclaimer => 'KI-Haftungsausschluss';

  @override
  String get aiDisclaimerCompact =>
      'Advocat liefert KI-gestützte Rechtsinformationen, keine Rechtsberatung. Lassen Sie alles vor dem Handeln von einem zugelassenen Anwalt prüfen.';

  @override
  String get aiDisclaimerFullTitle => 'Wichtig: So funktioniert Advocat';

  @override
  String get aiDisclaimerFullBody =>
      'Advocat ist ein Werkzeug auf Basis künstlicher Intelligenz, das Rechtsinformationen liefert, keine Rechtsberatung. Nach der EU-KI-Verordnung (Art. 50) müssen wir Sie klar darauf hinweisen: Sie interagieren mit einer KI, nicht mit einem menschlichen Anwalt.\n\nAdvocat ist keine Anwaltskanzlei. Wir sind keine zugelassenen Anwälte nach dem estnischen Advokatuuriseadus oder dem finnischen Asianajajalaki, und Ihre Gespräche mit diesem Werkzeug unterliegen nicht dem Anwaltsgeheimnis. Bevor Sie sich auf eine Antwort verlassen — um Rechtsmittel einzulegen, einen Vertrag zu unterschreiben oder eine Frist zu wahren — lassen Sie sie von einem zugelassenen Anwalt in Ihrer Jurisdiktion prüfen.';

  @override
  String get aiDisclaimerExpand => 'Mehr erfahren';

  @override
  String get aiDisclaimerDismiss => 'OK, verstanden';

  @override
  String get dataPrivacyConsent => 'Datenschutzeinwilligung';

  @override
  String get gdprIntro =>
      'Um KI-gestützte Rechtsinformationen bereitzustellen, verarbeiten wir Ihre Daten gemäß DSGVO (EU 2016/679). Durch Fortfahren stimmen Sie zu:';

  @override
  String get gdprChat => 'Verarbeitung Ihrer Chat-Nachrichten durch KI';

  @override
  String get gdprDocs => 'Analyse hochgeladener Dokumente';

  @override
  String get gdprStorage => 'Verschlüsselte Speicherung von Falldaten';

  @override
  String get gdprDelete => 'Recht, Ihre Daten jederzeit zu löschen';

  @override
  String get gdprFooter =>
      'Ihre Daten sind verschlüsselt und werden nie an Dritte weitergegeben. Sie können die Einwilligung widerrufen und alle Daten in den Einstellungen löschen.';

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
  String get aiGeneratedDisclaimer => 'KI-generiert • Keine Rechtsberatung';

  @override
  String get decline => 'Ablehnen';

  @override
  String get iAgree => 'Ich stimme zu';

  @override
  String get iAgreeToThe => 'Ich stimme den ';

  @override
  String get orWord => 'oder';

  @override
  String get english => 'Englisch';

  @override
  String get russian => 'Russisch';

  @override
  String get finnish => 'Finnisch';

  @override
  String successSubscribed(String plan) {
    return 'Erfolgreich für $plan abonniert!';
  }

  @override
  String paymentFailed(String error) {
    return 'Zahlung fehlgeschlagen: $error';
  }

  @override
  String get whatToDo => 'Was tun';

  @override
  String get getHelp => 'Hilfe bekommen';

  @override
  String get share => 'Teilen';

  @override
  String get didYouKnow => 'Wussten Sie?';

  @override
  String get mustKnow => 'Wichtig zu wissen';

  @override
  String get goodToKnow => 'Gut zu wissen';

  @override
  String get sentFromAdvocat => 'Gesendet von der Advocat-App';

  @override
  String get policeActionStayCalm =>
      'Bleiben Sie ruhig und halten Sie die Hände sichtbar';

  @override
  String get policeActionAskWhy =>
      'Fragen Sie den Beamten, warum Sie angehalten werden';

  @override
  String get policeActionProvideName =>
      'Nennen Sie Ihren Namen und Ihr Geburtsdatum';

  @override
  String get policeActionWantLawyer =>
      'Sagen Sie deutlich: „Ich möchte einen Anwalt, bevor ich Fragen beantworte.“';

  @override
  String get policeActionAskInterpreter =>
      'Bitten Sie bei Bedarf um einen Dolmetscher';

  @override
  String get policeActionNoteBadge =>
      'Notieren Sie den Namen und die Dienstnummer des Beamten';

  @override
  String get policeFactMustTellReason =>
      'In Finnland muss die Polizei Ihnen den Grund für das Anhalten nennen. Wenn sie es nicht tun, können Sie fragen — und sie sind gesetzlich verpflichtet, es zu erklären.';

  @override
  String get policeFactCanRecord =>
      'Sie können Polizeikontakte an öffentlichen Orten in Finnland aufnehmen. Dies wird durch die Meinungsfreiheit geschützt.';

  @override
  String get contactFinnishLegalAid => 'Finnische Rechtshilfe';

  @override
  String get contactNonDiscriminationOmbudsman =>
      'Gleichbehandlungsbeauftragter';

  @override
  String get deportationDeadlineAppeal =>
      'Berufung beim Verwaltungsgericht — in der Regel 30 Tage nach Zustellung';

  @override
  String get deportationDeadlineLegalAid =>
      'Beantragen Sie Rechtshilfe — tun Sie dies SOFORT';

  @override
  String get deportationFactStayDuringAppeal =>
      'In Finnland haben Sie in der Regel das Recht, im Land zu bleiben, während Ihre Berufung bearbeitet wird. Die Abschiebung kann in den meisten Fällen während einer laufenden Berufung nicht vollzogen werden.';

  @override
  String get contactRefugeeAdviceCentre =>
      'Finnisches Flüchtlingsberatungszentrum';

  @override
  String get contactAdminCourtHelsinki => 'Verwaltungsgericht Helsinki';

  @override
  String get workplaceActionKeepContract =>
      'Bewahren Sie Kopien Ihres Arbeitsvertrags auf';

  @override
  String get workplaceActionTrackHours =>
      'Erfassen Sie Ihre Arbeitszeiten eigenständig';

  @override
  String get workplaceActionReportUnsafe =>
      'Melden Sie unsichere Bedingungen der Arbeitsschutzbehörde';

  @override
  String get workplaceActionJoinUnion => 'Treten Sie einer Gewerkschaft bei';

  @override
  String get workplaceActionContactAuthority =>
      'Wenden Sie sich bei Bedarf an die Arbeitsschutzbehörde';

  @override
  String get workplaceFactCollectiveWage =>
      'In Finnland legen Tarifverträge die Mindestlöhne je Branche fest — es gibt keinen einheitlichen nationalen Mindestlohn. Ihr Arbeitgeber muss den Tarifvertrag Ihrer Branche einhalten.';

  @override
  String get workplaceFactOralContract =>
      'Auch ohne schriftlichen Vertrag haben Sie in Finnland volle Arbeitnehmerrechte. Eine mündliche Vereinbarung ist gesetzlich ebenso bindend.';

  @override
  String get contactOccupationalSafety => 'Arbeitsschutzbehörde';

  @override
  String get contactTradeUnionSAK => 'Gewerkschaftsberatung (SAK)';

  @override
  String get tenantActionWrittenAgreement =>
      'Schließen Sie immer einen schriftlichen Mietvertrag ab';

  @override
  String get tenantActionDocumentCondition =>
      'Dokumentieren Sie den Zustand der Wohnung beim Einzug (Fotos)';

  @override
  String get tenantActionReportMaintenance =>
      'Melden Sie Instandhaltungsprobleme schriftlich';

  @override
  String get tenantActionNoIllegalEviction =>
      'Stimmen Sie niemals einer rechtswidrigen Räumung zu — Gerichte müssen entscheiden';

  @override
  String get tenantActionContactAdvisory =>
      'Wenden Sie sich bei Streitigkeiten an eine Mieterberatung';

  @override
  String get tenantFactNoEvictionWithoutCourt =>
      'Ein Vermieter in Finnland kann Sie nicht ohne Gerichtsbeschluss räumen, auch wenn Ihr Mietvertrag abgelaufen ist. Schlösser austauschen oder Versorgungsleistungen kappen ist illegal.';

  @override
  String get contactTenantsAssociation => 'Finnischer Mieterverband';

  @override
  String get contactConsumerDisputesBoard => 'Verbraucherschlichtungsstelle';

  @override
  String get detentionActionAskDecision =>
      'Fordern Sie sofort den schriftlichen Haftbeschluss an';

  @override
  String get detentionActionRequestLawyer =>
      'Verlangen Sie, einen Anwalt zu kontaktieren';

  @override
  String get detentionActionContactEmbassy =>
      'Kontaktieren Sie Ihre Botschaft oder Ihr Konsulat';

  @override
  String get detentionActionAskMedical =>
      'Bitten Sie bei Bedarf um medizinische Versorgung';

  @override
  String get detentionActionRequestInterpreter =>
      'Verlangen Sie einen Dolmetscher für alle Verfahren';

  @override
  String get detentionDeadlineCourtReview =>
      'Das Amtsgericht muss die Haft innerhalb von 4 Tagen überprüfen';

  @override
  String get detentionDeadlineContinuation =>
      'Das Gericht überprüft die Verlängerung alle 2 Wochen';

  @override
  String get detentionFactCourtReview =>
      'Einwanderungshaft in Finnland muss innerhalb von 4 Tagen von einem Amtsgericht überprüft werden. Geschieht dies nicht, wird die Haft rechtswidrig.';

  @override
  String get contactParliamentaryOmbudsman => 'Parlamentarischer Ombudsmann';

  @override
  String get discriminationActionWriteDown =>
      'Schreiben Sie genau auf, was passiert ist (Datum, Uhrzeit, Ort)';

  @override
  String get discriminationActionSaveEvidence =>
      'Sichern Sie Beweise: Nachrichten, E-Mails, Zeugen';

  @override
  String get discriminationActionFileComplaint =>
      'Reichen Sie eine Beschwerde beim Gleichbehandlungsbeauftragten ein';

  @override
  String get discriminationActionContactLegalAid =>
      'Wenden Sie sich an ein Rechtshilfebüro für kostenlose Beratung';

  @override
  String get discriminationActionReportPolice =>
      'Erstatten Sie Anzeige bei der Polizei bei Drohung oder Körperverletzung';

  @override
  String get discriminationFactNonDiscriminationAct =>
      'Das finnische Gleichbehandlungsgesetz umfasst Diskriminierung aufgrund von Alter, Herkunft, Staatsangehörigkeit, Sprache, Religion, Gesundheit, Behinderung, sexueller Orientierung und anderen persönlichen Merkmalen.';

  @override
  String get contactVictimSupportRIKU => 'Opferhilfe Finnland (RIKU)';

  @override
  String get domesticViolence => 'Häusliche Gewalt';

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
  String get inheritance => 'Erbschaft';

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
  String get consumerProtection => 'Verbraucherschutz';

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
  String get callAI => 'KI anrufen';

  @override
  String get comingSoon => 'Kommt bald';

  @override
  String get encrypted => 'Verschlüsselt';

  @override
  String get typing => 'Tippt…';

  @override
  String get online => 'Online';

  @override
  String get chatWelcomeSubtitle =>
      'Ich analysiere die Situation, prüfe Dokumente, finde Fehler und schlage vor, was zu tun ist.';

  @override
  String get tapMicrophoneToSpeak => 'Tippen Sie auf das Mikrofon zum Sprechen';

  @override
  String get categoryEssential => 'Wesentlich';

  @override
  String get categoryPolice => 'Polizei';

  @override
  String get categoryWork => 'Arbeit';

  @override
  String get categoryHousing => 'Wohnen';

  @override
  String get categoryConsumer => 'Verbraucher';

  @override
  String rightsInsideCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Rechte enthalten',
      one: '1 Recht enthalten',
      zero: 'keine Rechte',
    );
    return '$_temp0';
  }

  @override
  String get freeAidThreshold => 'Schwelle für kostenlose Hilfe';

  @override
  String get partialAidThreshold => 'Schwelle für Teilhilfe';

  @override
  String get assetLimit => 'Vermögensgrenze';

  @override
  String get whereToApplyLabel => 'Wo beantragen';

  @override
  String get phoneLabel => 'Telefon';

  @override
  String get websiteLabel => 'Webseite';

  @override
  String get disclaimerCollapsed => 'Nur zur Information';

  @override
  String get disclaimerExpanded =>
      'KI-Assistent — keine Rechtsberatung. Überprüfen Sie immer mit einem qualifizierten Anwalt.';

  @override
  String get chatDisclaimerBanner =>
      'Der KI-Assistent bietet rechtliche Informationen, keine Rechtsberatung. Konsultieren Sie immer einen qualifizierten Anwalt.';

  @override
  String get chatDisclaimerSubtitle => 'KI-Assistent · keine Rechtsberatung';

  @override
  String get chatDisclaimerBannerFull =>
      'Advocat ist ein KI-Assistent für Rechtsinformationen, kein Anwalt. Die Angaben hier begründen kein Mandatsverhältnis, sind keine Rechtsberatung und können fehlerhaft sein. Für verbindliche Rechtsberatung wenden Sie sich an einen in Ihrer Rechtsordnung zugelassenen Anwalt. Wir vertreten Sie nicht.';

  @override
  String get chatDisclaimerFooter =>
      'KI-generiert. Bei einem zugelassenen Anwalt prüfen lassen.';

  @override
  String get chatDisclaimerGotIt => 'Verstanden';

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
  String get guestUser => 'Gast';

  @override
  String get howToUse => 'Wie benutzen?';

  @override
  String get tutorialStep1Title => 'KI-Rechtsassistent';

  @override
  String get tutorialStep1Desc =>
      'Stellen Sie eine beliebige Rechtsfrage und erhalten Sie sofortige Antworten basierend auf estnischem Recht.';

  @override
  String get tutorialStep2Title => 'Kennen Sie Ihre Rechte';

  @override
  String get tutorialStep2Desc =>
      'Durchsuchen Sie Rechtsinformationen nach Themen — Arbeit, Wohnen, Verbraucherrechte und mehr.';

  @override
  String get tutorialStep3Title => 'Dokumente scannen';

  @override
  String get tutorialStep3Desc =>
      'Fotografieren Sie Rechtsdokumente zur KI-Analyse und sicheren Aufbewahrung.';

  @override
  String get tutorialStep4Title => 'Los geht\'s!';

  @override
  String get tutorialStep4Desc =>
      'Entdecken Sie die App und schützen Sie Ihre Rechte. Alle Daten bleiben privat auf Ihrem Gerät.';

  @override
  String get advocatProTitle => 'Advocat Pro';

  @override
  String get advocatProSubtitle => 'Premium-Funktionen freischalten';

  @override
  String get voiceDisclaimer =>
      'Der Sprachassistent funktioniert derzeit nur auf dem Desktop (Chrome-Browser). Mobile Unterstützung kommt bald.';

  @override
  String get recommended => 'Empfohlen';

  @override
  String get pleaseLogIn => 'Bitte melden Sie sich an';

  @override
  String get subscriptionNotFound => 'Abonnement nicht gefunden';

  @override
  String errorWithMessage(String message) {
    return 'Fehler: $message';
  }

  @override
  String get redirectingToPayment => 'Weiterleitung zur Zahlungsseite…';

  @override
  String cheaperAnnually(String amount) {
    return '€$amount/Monat günstiger im Jahresabo';
  }

  @override
  String get navigatingTo => 'Öffne';

  @override
  String get stayInChat => 'Im Chat bleiben';

  @override
  String get backToChat => 'Zurück zum Chat';

  @override
  String get upgradeBannerTitle => 'Upgrade für unbegrenzte Beratungen';

  @override
  String get upgradeBannerCta => 'Upgrade';

  @override
  String get paymentSuccessTitle => 'Zahlung erfolgreich';

  @override
  String get paymentSuccessBody => 'Ihr Abonnement ist jetzt aktiv.';

  @override
  String get commonOk => 'OK';

  @override
  String get feedbackThumbsUpLabel => 'Hilfreich';

  @override
  String get feedbackThumbsDownLabel => 'Nicht hilfreich';

  @override
  String get feedbackCommentPrompt => 'Was war falsch?';

  @override
  String get feedbackSend => 'Senden';

  @override
  String get feedbackCancel => 'Abbrechen';

  @override
  String get reasoningPillIdle => 'Denkt nach…';

  @override
  String get reasoningPillSearchingLaw => 'Estnisches Recht wird durchsucht…';

  @override
  String get reasoningPillSearchingWeb => 'Das Web wird durchsucht…';

  @override
  String get reasoningPillCheckingCompany => 'Handelsregister wird geprüft…';

  @override
  String get reasoningPillCheckingVehicle => 'Fahrzeugregister wird geprüft…';

  @override
  String get reasoningPillReadingDocument => 'Ihr Dokument wird gelesen…';

  @override
  String get reasoningPillDrafting => 'Das Dokument wird entworfen…';

  @override
  String get reasoningPillPreparingEmail => 'E-Mail wird vorbereitet…';

  @override
  String get reasoningPillFindingLawyer => 'Anwälte werden gesucht…';

  @override
  String get reasoningPillThinking => 'Ihr Fall wird durchdacht…';

  @override
  String get reasoningPillFinalising => 'Ihre Antwort wird verfasst…';

  @override
  String reasoningCollapsedFormat(int sec, int sources) {
    return '$sec Sek. überlegt · $sources Quellen';
  }

  @override
  String get reasoningExpandHint => 'tippen, um Schritte zu sehen';

  @override
  String get caseFileTitle => 'Fallakte';

  @override
  String get caseFileTimeline => 'Zeitleiste';

  @override
  String get caseFileParties => 'Beteiligte';

  @override
  String get caseFileDeadlines => 'Fristen';

  @override
  String get caseFileExportPdf => 'Dossier herunterladen (PDF)';

  @override
  String get caseFileEmpty =>
      'Sprechen Sie mit der KI über Ihren Fall — Ihre Zeitleiste baut sich von selbst auf.';

  @override
  String get caseFileDisclaimer =>
      'Dieses Dossier wird automatisch aus Ihrem Chat erstellt. Es stellt keine Rechtsberatung dar.';

  @override
  String get caseFileTabLabel => 'Fall';

  @override
  String get refresh => 'Aktualisieren';

  @override
  String get demoLimitReached =>
      'Demo-Limit erreicht. Registrieren Sie sich kostenlos, um fortzufahren.';

  @override
  String get demoLimitSignUpCta => 'Registrieren';

  @override
  String freeQuotaExhausted(int count) {
    return 'Sie haben alle $count kostenlosen Nachrichten diesen Monat aufgebraucht.';
  }

  @override
  String get upgradeForUnlimited => 'Auf Pro upgraden für unbegrenzte Nutzung';

  @override
  String get upgradeCta => 'Upgrade';

  @override
  String get rateLimitTryAgain =>
      'Zu schnell gesendet. Versuchen Sie es in ein paar Sekunden erneut.';

  @override
  String get quickProfilePrompt =>
      'Damit ich genauer helfen kann: Bist du estnischer Staatsbürger, EU-Bürger aus einem anderen Land, oder hast du einen Aufenthaltstitel?';

  @override
  String get quickProfileChipEstonianCitizen => 'Estnischer Staatsbürger';

  @override
  String get quickProfileChipEuCitizen => 'EU-Bürger (anderes Land)';

  @override
  String get quickProfileChipResidencePermit => 'Aufenthaltstitel';

  @override
  String get quickProfileSkipBtn => 'Überspringen';

  @override
  String get quickProfileSavedAck => 'Verstanden. Wie kann ich helfen?';

  @override
  String get caseTitleLabel => 'Falltitel';

  @override
  String get jurisdictionLabel => 'Zuständigkeit';

  @override
  String get caseTypeLabel => 'Fallart';

  @override
  String get caseLanguageLabel => 'Sprache';

  @override
  String get caseNumbersSection => 'Aktenzeichen';

  @override
  String get partiesSection => 'Beteiligte';

  @override
  String get authoritiesSection => 'Behörden';

  @override
  String get timelineSection => 'Zeitleiste';

  @override
  String get openQuestionsSection => 'Offene Fragen';

  @override
  String get nextActionsSection => 'Nächste Schritte';

  @override
  String get summarySection => 'Zusammenfassung';

  @override
  String get addRow => 'Zeile hinzufügen';

  @override
  String get removeRow => 'Entfernen';

  @override
  String get archiveCase => 'Fall archivieren';

  @override
  String get closeCase => 'Fall schließen';

  @override
  String get continueChatAboutCase => 'Chat zu diesem Fall fortsetzen';

  @override
  String get linkChatToCase => 'Mit Fall verknüpfen';

  @override
  String get clearActiveCase => 'Aktiven Fall zurücksetzen';

  @override
  String get caseSavedAck => 'Fall gespeichert';

  @override
  String get caseArchivedAck => 'Fall archiviert';

  @override
  String get intakeStep1Title => 'Wo befindet sich der Fall?';

  @override
  String get intakeStep1Subtitle =>
      'Land und Behörde, mit der Sie es zu tun haben.';

  @override
  String get intakeJurisdictionLabel => 'Land / Zuständigkeit';

  @override
  String get intakeAuthorityLabel => 'Behördentyp';

  @override
  String get intakeAuthorityNameLabel => 'Behördenname (optional)';

  @override
  String get intakeAuthorityPolice => 'Polizei';

  @override
  String get intakeAuthorityCourt => 'Gericht';

  @override
  String get intakeAuthoritySocial => 'Sozialdienste';

  @override
  String get intakeAuthorityEmployer => 'Arbeitgeber';

  @override
  String get intakeAuthorityLandlord => 'Vermieter';

  @override
  String get intakeAuthorityOpposingParty => 'Gegenpartei';

  @override
  String get intakeAuthorityOther => 'Sonstige';

  @override
  String get intakeStep2Title => 'Um welche Art von Fall handelt es sich?';

  @override
  String get intakeStep2Subtitle =>
      'Wählen Sie die passendste Art — Sie können sie später verfeinern.';

  @override
  String get intakeCaseTypeCriminal => 'Strafrecht';

  @override
  String get intakeCaseTypeCivil => 'Zivilrecht';

  @override
  String get intakeCaseTypeFamily => 'Familienrecht';

  @override
  String get intakeCaseTypeAdmin => 'Verwaltungsrecht';

  @override
  String get intakeCaseTypeImmigration => 'Einwanderung';

  @override
  String get intakeCaseTypeLabor => 'Arbeitsrecht';

  @override
  String get intakeCaseTypeConsumer => 'Verbraucherrecht';

  @override
  String get intakeCaseTypeInheritance => 'Erbrecht';

  @override
  String get intakeCaseTypeOther => 'Sonstige';

  @override
  String get intakeStep3Title => 'Wer ist beteiligt?';

  @override
  String get intakeStep3Subtitle => 'Ihre Rolle und die Gegenseite.';

  @override
  String get intakeRoleLabel => 'Ihre Rolle';

  @override
  String get intakeRolePlaintiff => 'Kläger';

  @override
  String get intakeRoleDefendant => 'Beklagter';

  @override
  String get intakeRoleVictim => 'Geschädigter';

  @override
  String get intakeRoleAccused => 'Angeklagter';

  @override
  String get intakeRoleWitness => 'Zeuge';

  @override
  String get intakeRoleFamily => 'Familienangehöriger';

  @override
  String get intakeRoleOther => 'Sonstige';

  @override
  String get intakeOpposingSideLabel => 'Gegenseite (optional)';

  @override
  String get intakeWitnessesLabel => 'Zeugen (optional)';

  @override
  String get intakeAddWitness => 'Zeugen hinzufügen';

  @override
  String get intakeWitnessHint => 'Name oder Kontakt';

  @override
  String get intakeStep4Title => 'Nummern & Daten';

  @override
  String get intakeStep4Subtitle =>
      'Alles, was Sie bereits haben. Überspringen Sie, was Sie nicht haben.';

  @override
  String get intakeCaseNumberLabel => 'Aktenzeichen (optional)';

  @override
  String get intakeIncidentDateLabel => 'Datum des Vorfalls (optional)';

  @override
  String get intakeIncidentDatePick => 'Datum wählen';

  @override
  String get intakeDeadlinesLabel => 'Bekannte Fristen';

  @override
  String get intakeAddDeadline => 'Frist hinzufügen';

  @override
  String get intakeDeadlineWhatHint => 'Was';

  @override
  String get intakeStep5Title => 'Dokumente';

  @override
  String get intakeStep5Subtitle =>
      'Laden Sie alles Relevante hoch. Wir lesen es.';

  @override
  String get intakeUploadDocsLabel => 'Dokumente hochladen';

  @override
  String get intakeSkipDocs => 'Überspringen — ich lade später hoch';

  @override
  String get intakeNextBtn => 'Weiter';

  @override
  String get intakeBackBtn => 'Zurück';

  @override
  String get intakeFinishBtn => 'Fertig & Chat öffnen';

  @override
  String get intakeUrgentBtn => 'Dringend — jetzt fragen';

  @override
  String get intakeUrgentDialogTitle => 'Chat jetzt öffnen?';

  @override
  String get intakeUrgentDialogBody =>
      'Wir speichern Ihre Eingaben als Fallentwurf. Sie können den Assistenten jederzeit auf der Fallseite abschließen.';

  @override
  String get intakeUrgentConfirm => 'Chat öffnen';

  @override
  String get intakeUrgentCancel => 'Weiter ausfüllen';

  @override
  String get intakePreparingCase => 'Ihr Fall wird vorbereitet…';

  @override
  String get intakeFallbackGreeting =>
      'Ich sehe Ihren Fall. Sagen Sie mir, was am dringendsten ist — ich arbeite es mit Ihnen durch.';

  @override
  String get intakeUrgentGreeting =>
      'Ich sehe, dass es dringend ist. Stellen Sie Ihre Frage — den Rest ergänze ich, während wir vorankommen.';

  @override
  String intakeStepIndicator(int current, int total) {
    return 'Schritt $current von $total';
  }

  @override
  String get intakeFieldRequired => 'Erforderlich';

  @override
  String intakeUploadProgress(int done, int total) {
    return '$done / $total werden hochgeladen…';
  }

  @override
  String get uplDisclaimerFooter =>
      'Advocat ist keine Anwaltskanzlei. Dies ist eine Information, keine Rechtsberatung.';

  @override
  String get citationStatusVerifiedBadge => 'Verifiziert';

  @override
  String get citationStatusUnverifiedBadge => 'Nicht verifiziert';

  @override
  String get citationStatusHistoricalBadge => 'Historische Fassung';

  @override
  String get citationStatusVerifiedTooltip =>
      'Aus einer abgerufenen Rechtsquelle zitiert.';

  @override
  String get citationStatusUnverifiedTooltip =>
      'Die KI hat diese Stelle ohne Quellenabruf zitiert — vor der Verwendung prüfen.';

  @override
  String get citationStatusHistoricalTooltip =>
      'Die zitierte Vorschrift ist nicht mehr in Kraft.';

  @override
  String get citationOpenInRiigiTeataja => 'Im Riigi Teataja öffnen';

  @override
  String get citationSnippetExpand => 'Volltext anzeigen';

  @override
  String get citationSnippetCollapse => 'Weniger anzeigen';

  @override
  String get citationUnverifiedSheetNote =>
      'Die KI hat diesen Paragraphen zitiert, doch er wurde in dieser Sitzung nicht aus dem Rechtskorpus abgerufen. Prüfen Sie den Verweis vor jeder Verwendung.';

  @override
  String get citationFooterNoneWarning => 'Keine belegten Quellenangaben';

  @override
  String citationFooterSummaryTotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Zitate',
      one: '1 Zitat',
    );
    return '$_temp0';
  }

  @override
  String citationFooterSummaryVerified(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count verifiziert',
      one: '1 verifiziert',
    );
    return '$_temp0';
  }

  @override
  String citationFooterSummaryUnverified(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unverifiziert',
      one: '1 unverifiziert',
    );
    return '$_temp0';
  }

  @override
  String citationFooterSummaryHistorical(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count historisch',
      one: '1 historisch',
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
      other: 'in $count Tagen',
      one: 'in 1 Tag',
      zero: 'heute',
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
      other: '$count Tage überfällig',
      one: '1 Tag überfällig',
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
  String get inboxSentToast => 'Gesendet.';

  @override
  String get inboxAlreadySentToast => 'Bereits gesendet.';

  @override
  String get inboxSendErrorToast =>
      'Antwort konnte nicht gesendet werden. Erneut versuchen.';

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
    return 'Das Consilium empfiehlt $count parallele Aktionen';
  }

  @override
  String get parallelActionsApproveAll => 'Alle freigeben & senden';

  @override
  String parallelActionsApproveSelected(int count, int total) {
    return '$count von $total freigeben';
  }

  @override
  String parallelActionsConfirmTitle(int count) {
    return '$count E-Mails senden?';
  }

  @override
  String parallelActionsConfirmBody(int count) {
    return 'Advocat versendet $count vorbereitete Antworten über Ihr verbundenes Gmail. Jede wird unabhängig gesendet — schlägt eine fehl, gehen die anderen trotzdem raus.';
  }

  @override
  String parallelActionsSentToast(int count) {
    return '$count gesendet.';
  }

  @override
  String parallelActionsPartialFailureToast(int sent, int failed) {
    return '$sent gesendet, $failed fehlgeschlagen.';
  }

  @override
  String get parallelActionsKindReply => 'Antwort';

  @override
  String get parallelActionsKindNew => 'neu';

  @override
  String get parallelActionsCheckboxSelected => 'Aktion ausgewählt';

  @override
  String get parallelActionsCheckboxUnselected => 'Aktion nicht ausgewählt';

  @override
  String parallelActionsCitationCount(int count) {
    return '$count Zit.';
  }

  @override
  String parallelActionsRetryFailed(int count) {
    return 'Fehlgeschlagene erneut versuchen ($count)';
  }

  @override
  String get agentApprovalNeedsReviewTitle => 'Advocat benötigt Ihre Freigabe';

  @override
  String get agentApprovalResolvedTitle => 'Aktion erledigt';

  @override
  String get agentApprovalStepsLabel => 'Schritte';

  @override
  String get agentApprovalApproveButton => 'Freigeben & senden';

  @override
  String get agentApprovalDeclineButton => 'Ablehnen';

  @override
  String get agentApprovalAttachmentsLabel => 'Anhänge';

  @override
  String get agentApprovalSentSummary => 'In Ihrem Namen gesendet.';

  @override
  String get agentApprovalDeclinedSummary =>
      'Abgelehnt — es wurde nichts gesendet.';

  @override
  String get agentToolDraftEmailAtt => 'E-Mail mit Anhängen senden';

  @override
  String get agentToolSendEmail => 'E-Mail senden';

  @override
  String get agentToolGeneratePdf => 'PDF erstellen';

  @override
  String get agentToolApproveSend => 'Vorbereitete Antwort senden';

  @override
  String get inboxErrorTitle => 'Posteingang konnte nicht geladen werden';

  @override
  String get inboxEditDiscardTitle =>
      'Nicht gespeicherte Änderungen verwerfen?';

  @override
  String get inboxEditDiscardBody =>
      'Sie haben nicht gespeicherte Änderungen an diesem Entwurf. Beim Zurückgehen werden sie verworfen.';

  @override
  String get inboxEditKeepEditing => 'Weiter bearbeiten';

  @override
  String get inboxEditDiscard => 'Verwerfen';

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
  String get plannerSettingsTitle => 'Dreistufige juristische Argumentation';

  @override
  String get plannerSettingsSubtitle =>
      'Planen → antworten → kritisieren. Langsamer, aber gründlicher.';

  @override
  String get plannerSettingsProBadge => 'Pro';

  @override
  String get plannerSettingsProDescription => 'Im Pro-Tarif verfügbar';

  @override
  String get plannerTrailHeaderPlan => 'Plan';

  @override
  String get plannerTrailHeaderCritique => 'Kritik';

  @override
  String get plannerTrailSubQuestions => 'Teilfragen';

  @override
  String get plannerTrailCounterArgs => 'Gegenargumente';

  @override
  String get plannerTrailEvidenceGaps => 'Beweislücken';

  @override
  String get plannerTrailMaterialGapTrue => 'Wesentliche Lücke erkannt';

  @override
  String get plannerTrailRegeneratedBadge => 'Einmal neu generiert';

  @override
  String get plannerTrailEmpty => 'keine Einträge';

  @override
  String get supportTitle => 'Hilfe';

  @override
  String get supportSubtitle =>
      'Wir antworten in der Regel innerhalb von 1-2 Stunden.';

  @override
  String get supportSearchPlaceholder => 'Hilfe durchsuchen…';

  @override
  String get supportStatusAllOk => 'Alle Systeme normal';

  @override
  String get supportFaqWhatIs => 'Was ist Advocat?';

  @override
  String get supportFaqHowSubscribe => 'Wie abonniere ich Pro?';

  @override
  String get supportFaqExportData => 'Kann ich meine Daten exportieren?';

  @override
  String get supportFaqCancelAccount => 'Konto kündigen oder löschen';

  @override
  String get supportFaqTalkHuman => 'Mit einem Menschen sprechen';

  @override
  String get supportContactEmail => 'E-Mail';

  @override
  String get supportContactTelegram => 'Telegram';

  @override
  String get supportContactWhatsapp => 'WhatsApp';

  @override
  String get supportFooterSla => 'Wir antworten innerhalb von 24 Stunden';

  @override
  String get supportWhatsapp => 'WhatsApp';

  @override
  String get supportEmail => 'E-Mail';

  @override
  String get supportInApp => 'Schreiben Sie uns hier';

  @override
  String get supportCategoryLabel => 'Kategorie';

  @override
  String get supportCategoryBug => 'Fehler';

  @override
  String get supportCategoryPayment => 'Zahlungsproblem';

  @override
  String get supportCategoryQuestion => 'Frage';

  @override
  String get supportCategoryFeature => 'Funktionswunsch';

  @override
  String get supportCategoryOther => 'Sonstiges';

  @override
  String get supportMessagePlaceholder => 'Beschreiben Sie Ihr Problem...';

  @override
  String get supportEmailLabel => 'E-Mail (optional)';

  @override
  String get supportSend => 'Senden';

  @override
  String get supportSentSuccess => 'Nachricht gesendet! Wir antworten bald.';

  @override
  String get supportError =>
      'Etwas ist schiefgelaufen. Versuchen Sie es erneut.';

  @override
  String get supportErrorTooShort =>
      'Bitte schreiben Sie mindestens 10 Zeichen.';

  @override
  String get supportErrorTooLong => 'Maximal 2000 Zeichen.';

  @override
  String get supportPrivacyNotice => 'Ihre Nachricht wird sicher gespeichert.';

  @override
  String get reviewThisContract => 'Vertrag prüfen';

  @override
  String get contractReviews => 'Vertragsprüfungen';

  @override
  String get contractReviewsFreeFeature =>
      '1 Vertragsprüfung (lebenslange Testversion)';

  @override
  String get contractReviewsCounselFeature => '5 Vertragsprüfungen pro Monat';

  @override
  String get contractReviewsProFeature => '20 Vertragsprüfungen pro Monat';

  @override
  String contractReviewsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Vertragsprüfungen diesen Monat übrig',
      one: '1 Vertragsprüfung diesen Monat übrig',
      zero: 'Diesen Monat keine Vertragsprüfungen übrig',
    );
    return '$_temp0';
  }

  @override
  String get contractReviewsExhausted =>
      'Keine Vertragsprüfungen mehr in diesem Monat';

  @override
  String get contractReviewsFreeTrialLeft =>
      'Kostenlose Testversion: 1 Vertragsprüfung';

  @override
  String get contractReviewsFreeTrialUsed =>
      'Testversion verbraucht — upgraden';

  @override
  String get contractReviewsUpgradeTitle => 'Vertragsprüfungen verbraucht';

  @override
  String get contractReviewsUpgradeBodyFree =>
      'Sie haben Ihre kostenlose Vertragsprüfung verbraucht. Upgraden Sie für monatliche Prüfungen.';

  @override
  String contractReviewsUpgradeBodyPaid(int used, int cap) {
    return 'Sie haben $used von $cap Prüfungen diesen Monat verbraucht. Upgraden Sie für ein höheres Limit.';
  }

  @override
  String get contractReviewsUpgradeCounselCta =>
      'Upgrade auf Counsel (€19,99/Mon.) — 5 Prüfungen';

  @override
  String get contractReviewsUpgradeProCta =>
      'Upgrade auf Pro (€29,99/Mon.) — 20 Prüfungen';

  @override
  String get contractReviewsUpgradeToProShort => 'Upgrade auf Pro — 20/Mon.';

  @override
  String get notNow => 'Nicht jetzt';

  @override
  String get referralTitle => 'Freunde einladen';

  @override
  String get referralSubtitle =>
      'Erhalte einen Gratismonat. Schenke einen Gratismonat.';

  @override
  String get referralYourLink => 'DEIN LINK';

  @override
  String get referralCopyLink => 'Link kopieren';

  @override
  String get referralShare => 'Teilen';

  @override
  String get referralLinkCopied => 'Link kopiert';

  @override
  String get referralStatsInvited => 'Eingeladen';

  @override
  String get referralStatsConverted => 'Konvertiert';

  @override
  String get referralStatsEarned => 'Gratismonate';

  @override
  String get referralShareWhatsApp => 'Auf WhatsApp teilen';

  @override
  String get referralShareTelegram => 'Auf Telegram teilen';

  @override
  String get referralShareEmail => 'Per E-Mail teilen';

  @override
  String get referralEmailSubject =>
      'Probiere Advocat — deinen KI-Rechtsassistenten';

  @override
  String get referralLoadError =>
      'Daten konnten nicht geladen werden. Zum Aktualisieren ziehen.';

  @override
  String get referralRetry => 'Erneut versuchen';

  @override
  String get referralSettingsTile => 'Freunde einladen';

  @override
  String get referralAfterReviewCta =>
      'Gefallen? Lade einen Freund ein — beide bekommen einen Gratismonat.';

  @override
  String get referralAntiFraud =>
      'Maximal 12 erfolgreiche Empfehlungen pro Jahr.';

  @override
  String get referralEmpty =>
      'Noch keine Empfehlungen. Senden Sie Ihren Link, um zu verdienen.';

  @override
  String get referralRecentActivity => 'Letzte Aktivität';

  @override
  String referralActivityInvited(String when) {
    return 'Eingeladen $when';
  }

  @override
  String referralActivityActivated(String when) {
    return 'aktiviert $when';
  }

  @override
  String get referralActivityPending => 'noch nicht aktiviert';

  @override
  String referralStatsInvitedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Freunde',
      one: '1 Freund',
      zero: 'noch keine Freunde',
    );
    return 'Sie haben $_temp0 eingeladen';
  }

  @override
  String referralStatsConvertedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count haben aktiviert',
      one: '1 hat aktiviert',
      zero: 'noch keine aktiviert',
    );
    return '$_temp0';
  }

  @override
  String referralStatsEarnedCount(int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months kostenlose Monate',
      one: '1 kostenloser Monat',
      zero: 'noch nichts',
    );
    return 'Ihr Bonus: $_temp0';
  }

  @override
  String get referralNudgeMessage =>
      'Gefällt Ihnen Advocat? Laden Sie einen Freund ein — beide erhalten einen kostenlosen Monat.';

  @override
  String get referralNudgeAction => 'Einladen';

  @override
  String get referralLandingTitle => 'Sie wurden zu Advocat eingeladen';

  @override
  String referralLandingSubtitle(String inviterName) {
    return '$inviterName hat Sie eingeladen — sichern Sie sich Ihren kostenlosen ersten Monat.';
  }

  @override
  String get referralLandingSubtitleGeneric =>
      'Sichern Sie sich Ihren kostenlosen ersten Monat Advocat Pro.';

  @override
  String get referralLandingCta =>
      'Kostenlosen Monat aktivieren & registrieren';

  @override
  String get referralLandingCtaSecondary => 'Oder mehr über Advocat erfahren';

  @override
  String get referralLandingFallback =>
      'Dieser Link ist abgelaufen — Sie können Advocat aber trotzdem kostenlos testen.';

  @override
  String get referralLandingBenefits =>
      '17 Sprachen • Echtes estnisches, finnisches und EU-Recht • 24/7 — ohne Wartezeit';

  @override
  String get checkerProTagline => 'Professionelle Prüfwerkzeuge';

  @override
  String get checkerDataSource => 'Daten aus offiziellen Registern';

  @override
  String get companyCheckerHint => 'Firmenname oder Reg.-Nr.';

  @override
  String get companyCheckerPriceChip =>
      '€2.99 pro Prüfung  •  In Pro enthalten';

  @override
  String get companyCheckerEmptyState =>
      'Geben Sie einen Firmennamen oder eine Reg.-Nr.\nein, um einen vollständigen Bericht zu erhalten';

  @override
  String get aiMemoryTitle => 'KI-Gedächtnis';

  @override
  String get aiMemorySubtitle =>
      'Überprüfen und löschen, was die KI über Sie gespeichert hat';

  @override
  String get bookLawyerCallTitle => 'Anwaltsgespräch buchen';

  @override
  String get bookLawyerCallComingSoonTitle =>
      'Anrufe mit echten Anwälten — bald verfügbar';

  @override
  String get bookLawyerCallComingSoonBody =>
      'Pro und Premium beinhalten 15-minütige Gespräche mit einem Partneranwalt (Pro – 1/Quartal, Premium – 2/Quartal). Wir stellen den estnischen Einzelanwalts-Pool fertig und benachrichtigen Sie per E-Mail, sobald die Buchung verfügbar ist.';

  @override
  String bookLawyerCallQuotaAvailable(int remaining, int total) {
    return 'Sie haben dieses Quartal noch $remaining von $total Anruf(en) übrig.';
  }

  @override
  String get bookLawyerCallQuotaExhausted => 'Quartalskontingent aufgebraucht.';

  @override
  String get bookLawyerCallQuotaBodyAvailable =>
      'Pro umfasst 1 Anruf/Quartal, Premium 2. Anrufe dauern 15 Minuten und werden über Google Meet geführt.';

  @override
  String get bookLawyerCallQuotaBodyExhausted =>
      'Ihr Kontingent setzt sich am ersten Tag des nächsten Quartals zurück. Brauchen Sie früher ein Gespräch? Aktualisieren Sie auf Premium für einen zusätzlichen Anruf.';

  @override
  String get severityCritical => 'KRITISCH';

  @override
  String get severityHigh => 'HOCH';

  @override
  String get severityMedium => 'MITTEL';

  @override
  String get severityLow => 'NIEDRIG';

  @override
  String get deadlineRequiredFields => 'Titel und Stichtag sind erforderlich';

  @override
  String get acceptTermsRequired =>
      'Bitte stimmen Sie den Nutzungsbedingungen zu';

  @override
  String get chatLegalCouncilTooltip => 'Rechtsrat (4 Experten)';

  @override
  String get attachFileTooltip => 'Datei anhängen';

  @override
  String get sendMessage => 'Nachricht senden';

  @override
  String get stopGenerating => 'Generierung stoppen';

  @override
  String get showPassword => 'Passwort anzeigen';

  @override
  String get hidePassword => 'Passwort ausblenden';

  @override
  String get decreaseDependents => 'Verringern';

  @override
  String get increaseDependents => 'Erhöhen';

  @override
  String get sensitiveConsentTitle => 'Einwilligung zu sensiblen Daten';

  @override
  String get sensitiveConsentBody =>
      'Dokumente, die Sie hochladen möchten, können besondere Kategorien personenbezogener Daten nach Art. 9 DSGVO enthalten — etwa Gesundheitsdaten, Strafregisterdaten, biometrische Daten oder Informationen über Ihre ethnische Herkunft, Religion oder sexuelle Orientierung.\n\nWir verarbeiten diese Daten ausschließlich, um Ihnen KI-gestützte Rechtshilfe zu bieten, speichern sie verschlüsselt in Ihrem privaten Konto und verwenden sie niemals zum Training von Modellen. Sie können Ihre Einwilligung jederzeit widerrufen und die Daten in den Einstellungen löschen.\n\nMit Ihrer Zustimmung erteilen Sie Ihre ausdrückliche Einwilligung nach Art. 9 Abs. 2 lit. a DSGVO zur Verarbeitung besonderer Datenkategorien zu diesem Zweck.';

  @override
  String get sensitiveConsentExplicitCheckbox =>
      'Ich erteile meine ausdrückliche Einwilligung zur Verarbeitung besonderer Datenkategorien (Art. 9 Abs. 2 lit. a DSGVO).';

  @override
  String get sensitiveConsentRightToShareCheckbox =>
      'Ich bestätige, dass ich berechtigt bin, diese Daten zu teilen (die Daten gehören mir, oder ich habe eine informierte/rechtmäßige Grundlage, Daten Dritter zu teilen).';

  @override
  String get sensitiveConsentViewCategories =>
      'Ansehen, was als sensibel gilt →';

  @override
  String get sensitiveConsentWithdrawAction =>
      'Einwilligung zu sensiblen Daten widerrufen';

  @override
  String get privacyAndData => 'DATENSCHUTZ & DATEN';

  @override
  String get exportMyDataSubtitle =>
      'Laden Sie eine Kopie all Ihrer personenbezogenen Daten herunter (Art. 15 DSGVO).';

  @override
  String get withdrawSensitiveConsent => 'Einwilligung zu sensiblen Daten';

  @override
  String get withdrawSensitiveConsentSubtitle =>
      'Einwilligung zur Verarbeitung besonderer Datenkategorien verwalten oder widerrufen (Art. 9 Abs. 2 lit. a DSGVO).';

  @override
  String get dataProcessingAgreement => 'Auftragsverarbeitungsvertrag';

  @override
  String get exportingData => 'Ihre Daten werden exportiert…';

  @override
  String get exportComplete =>
      'Datenexport bereit — auf Ihrem Gerät gespeichert.';

  @override
  String get exportFailed =>
      'Export fehlgeschlagen. Bitte versuchen Sie es erneut oder kontaktieren Sie den Support.';

  @override
  String get quotaExhaustedTitle =>
      'Limit der kostenlosen Nachrichten erreicht';

  @override
  String quotaExhaustedBody(int count) {
    return 'Sie haben alle $count kostenlosen Nachrichten verbraucht. Buchen Sie Advocat Pro für 19,99 €/Monat und erhalten Sie unbegrenzten Zugang zum KI-gestützten Rechtsinformations-Assistenten.';
  }

  @override
  String get quotaExhaustedLater => 'Später';

  @override
  String get quotaExhaustedUpgrade => 'Advocat Pro — 19,99 €/Monat';

  @override
  String quotaCtaMessage(int count) {
    return 'Sie haben alle $count kostenlosen Nachrichten verbraucht. Buchen Sie Advocat Pro für 19,99 €/Monat.';
  }

  @override
  String get quotaCtaButton => 'Advocat Pro buchen — 19,99 €/Monat';

  @override
  String get aiErrorQuota =>
      'Limit der kostenlosen Nachrichten erreicht. Abonnieren Sie, um die KI weiter zu nutzen.';

  @override
  String get aiErrorAuth =>
      'Für die KI-Nutzung ist eine Anmeldung erforderlich. Bitte registrieren oder anmelden.';

  @override
  String get aiErrorGeneric =>
      'Vorübergehender KI-Fehler. Bitte in einer Minute erneut versuchen. Falls es weiterhin nicht funktioniert — wenden Sie sich an den Support.';

  @override
  String get tooltipShareCase => 'Fallzusammenfassung teilen';

  @override
  String get tooltipMuteVoice => 'Stimme stummschalten';

  @override
  String get tooltipUnmuteVoice => 'Stimme einschalten';

  @override
  String get tooltipAttachDoc => 'Dokument anhängen';

  @override
  String get aiTypingHint => 'KI…';

  @override
  String get error404Title => 'Seite nicht gefunden';

  @override
  String error404Body(String path) {
    return 'Nicht gefunden: $path';
  }

  @override
  String get goToHome => 'Zur Startseite';

  @override
  String get emailAlreadyRegistered =>
      'Diese E-Mail ist bereits registriert. Anmelden?';

  @override
  String get actionSignIn => 'Anmelden';

  @override
  String get actionUndo => 'Rückgängig';

  @override
  String get intakeUrgentOpened =>
      'Chat geöffnet — dein Entwurf ist gespeichert.';

  @override
  String get panicCoachmark => 'Für Soforthilfe gedrückt halten.';

  @override
  String get panicTitle => 'Was brauchen Sie gerade jetzt?';

  @override
  String get panicCardReadAloud => 'Dem Beamten vorlesen';

  @override
  String get panicCardRecord => 'Dieses Gespräch aufzeichnen';

  @override
  String get panicCardCall => 'Einen Anwalt anrufen';

  @override
  String get panicCardAi => 'Jetzt mit Advocat sprechen';

  @override
  String get panicClose => 'Schließen';

  @override
  String get panicBadgeV2 => 'V2';

  @override
  String get panicRecordV1Title => 'Kommt in V2';

  @override
  String get panicRecordV1Body =>
      'Die Aufzeichnungsfunktion wird derzeit für Estland rechtlich geprüft und kommt in V2. Nutzen Sie vorerst das integrierte Sprachaufnahmegerät Ihres Telefons.';

  @override
  String get panicCallFallbackBody =>
      'Schreiben Sie an kiire@advocat.ee mit einer kurzen Beschreibung, und wir rufen Sie zurück.';

  @override
  String get consiliumHeader => 'Anwaltskonsilium';

  @override
  String consiliumProgress(int count, int total) {
    return '$count von $total bereit';
  }

  @override
  String get consiliumStarting => 'Anwälte prüfen Ihren Fall…';

  @override
  String get consiliumDisagreement => 'Experten sind uneinig';

  @override
  String get consiliumSynthesizing => 'Empfehlung wird zusammengestellt…';

  @override
  String consiliumDone(int totalRoles) {
    return 'Konsilium abgeschlossen · $totalRoles Experten';
  }

  @override
  String get consiliumPositionPush => 'Anfechten';

  @override
  String get consiliumPositionSettle => 'Einigen';

  @override
  String get consiliumPositionInvestigate => 'Weiter prüfen';

  @override
  String get consiliumPositionOutOfScope =>
      'Außerhalb des Zuständigkeitsbereichs';

  @override
  String get consiliumConfidence => 'Sicherheit';

  @override
  String get consiliumKeyCitation => 'Zentrale Quelle';

  @override
  String get consiliumAdversarialRound => 'Streitrunde';

  @override
  String get consiliumViewFullOpinion => 'Vollständiges Gutachten ansehen';

  @override
  String consiliumExpertsAgreed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Experten stimmen zu',
      one: '1 Experte stimmt zu',
    );
    return '$_temp0';
  }

  @override
  String consiliumExpertsDisagree(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Experten stimmen nicht zu',
      one: '1 Experte stimmt nicht zu',
    );
    return '$_temp0';
  }

  @override
  String get consiliumDisclaimer =>
      'KI-Agenten, keine menschlichen Anwälte. Wesentliche Entscheidungen sind durch einen zugelassenen Rechtsanwalt zu überprüfen.';

  @override
  String get softCaseShellBanner =>
      'Wir haben „Unbenannter Fall“ erstellt, um dies zu verfolgen. Tippen, um umzubenennen.';

  @override
  String get softCaseShellBannerCta => 'Umbenennen';

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
  String get chatExamplePrompt1 =>
      'Hilf mir, auf einen Bußgeldbescheid zu antworten';

  @override
  String get chatExamplePrompt2 => 'Prüfe meinen Mietvertrag';

  @override
  String get chatExamplePrompt3 => 'Welche Rechte habe ich am Arbeitsplatz?';

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
  String get contractReviewTitle => 'Vertragsprüfung';

  @override
  String get contractReviewUploadCta => 'Vertrag hochladen';

  @override
  String get contractReviewQuotaRemaining =>
      'Laden Sie einen Vertrag als PDF, DOC, DOCX oder TXT hoch und erhalten Sie eine KI-Prüfung mit Warnsignalen und Verhandlungstipps.';

  @override
  String get contractReviewRedFlags => 'Warnsignale';

  @override
  String get contractReviewReviewPoints => 'Prüfpunkte';

  @override
  String get contractReviewNegotiationTips => 'Verhandlungstipps';

  @override
  String get contractReviewSaveToVault => 'Im Tresor speichern';

  @override
  String get contractReviewContinueChat => 'Im Chat fortfahren';

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
  String get iapPayWithApple => 'Mit Apple bezahlen';

  @override
  String get iapRestorePurchases => 'Käufe wiederherstellen';

  @override
  String get iapPurchaseFailed =>
      'Kauf fehlgeschlagen. Bitte erneut versuchen oder Support kontaktieren.';

  @override
  String get iapRestoreSuccess => 'Dein Abonnement wurde wiederhergestellt.';

  @override
  String get iapRestoreNoActive =>
      'Kein aktives Abonnement zum Wiederherstellen gefunden.';

  @override
  String get deadlineEuRadarTitle => 'EU deadline radar (preview)';

  @override
  String get deadlineEuRadarSubtitle =>
      'Hypothetical EU procedural deadlines — mock data';

  @override
  String get changePassword => 'Passwort ändern';

  @override
  String get changePasswordSubtitle => 'Aktualisieren Sie Ihr Kontopasswort';

  @override
  String get newPasswordTitle => 'Neues Passwort festlegen';

  @override
  String get newPasswordHint =>
      'Geben Sie ein neues Passwort für Ihr Konto ein und bestätigen Sie es.';

  @override
  String get newPasswordSave => 'Neues Passwort speichern';

  @override
  String get newPasswordSuccess =>
      'Passwort aktualisiert. Sie können sich jetzt damit anmelden.';

  @override
  String get newPasswordError =>
      'Passwort konnte nicht aktualisiert werden. Bitte versuchen Sie es erneut.';

  @override
  String get accessLogTile => 'Zugriffsprotokoll';

  @override
  String get accessLogTileSubtitle =>
      'Sehen Sie, wer und was auf Ihre Daten zugegriffen hat';

  @override
  String get accessLogTitle => 'Zugriffsprotokoll für meine Daten';

  @override
  String get accessLogIntro =>
      'Eine transparente, manipulationssichere Aufzeichnung jedes Zugriffs auf oder jeder Verarbeitung Ihrer Daten – auch durch unsere KI. Sie können überprüfen, dass nichts verändert wurde.';

  @override
  String get accessLogEmpty => 'Noch keine Zugriffsereignisse.';

  @override
  String get accessLogError =>
      'Ihr Zugriffsprotokoll konnte nicht geladen werden. Zum Wiederholen nach unten ziehen.';

  @override
  String get accessLogIntegrityOk =>
      'Integrität bestätigt – die Protokolleinträge bilden eine ununterbrochene Kette.';

  @override
  String get accessLogIntegrityBroken =>
      'Warnung: Die Protokollkette ist unterbrochen. Möglicherweise wurden Einträge entfernt oder umgestellt. Bitte wenden Sie sich an den Support.';

  @override
  String get accessActionLlmEgress =>
      'Zur Verarbeitung an die KI gesendet (pseudonymisiert)';

  @override
  String get accessActionAiAnalysis => 'Von der KI analysiert';

  @override
  String get accessActionDocumentParse => 'Dokument ausgewertet';

  @override
  String get accessActionStaffRead => 'Von einem Teammitglied geprüft';

  @override
  String get accessActionExport => 'Daten exportiert';

  @override
  String get accessActionEmailTriage => 'E-Mail vorsortiert';

  @override
  String get accessActionDeadlineScan => 'Fristen geprüft';

  @override
  String get breachAlertTitle => 'Sicherheitswarnung zu Ihren Daten';

  @override
  String get breachAlertBody =>
      'Unsere automatische Überwachung hat einen ungewöhnlichen Zugriff auf Ihre Daten festgestellt. Wir prüfen den Vorfall und benachrichtigen Sie über jeden bestätigten Vorfall, soweit gesetzlich vorgeschrieben (Art. 34 DSGVO).';

  @override
  String get caseDossierTitle => 'Falldossier exportieren';

  @override
  String get caseDossierSubtitle =>
      'Ein PDF mit allem – Sachverhalt, Chronologie, Fristen und Dokumenten – zur Übergabe an einen Rechtsbeistand, ein Gericht oder eine Beschwerdestelle.';

  @override
  String get caseDossierTileTitle => 'Dossier exportieren (PDF)';

  @override
  String get caseDossierTileSubtitle =>
      'Den gesamten Fall in einer Datei an einen Rechtsbeistand oder ein Gericht übergeben';

  @override
  String get caseDossierSectionsHeading => 'In das Dossier aufnehmen';

  @override
  String get caseDossierSectionFacts => 'Sachverhalt';

  @override
  String get caseDossierSectionFactsHint => 'Immer enthalten';

  @override
  String get caseDossierSectionTimeline => 'Chronologie';

  @override
  String get caseDossierSectionDeadlines => 'Fristen';

  @override
  String get caseDossierSectionDocuments => 'Dokumente';

  @override
  String get caseDossierSectionAiSummary => 'KI-Zusammenfassung';

  @override
  String get caseDossierExportButton => 'PDF exportieren';

  @override
  String get caseDossierExporting => 'Ihr Dossier wird erstellt…';

  @override
  String get caseDossierSuccess => 'Dossier fertig. Datei öffnen oder teilen.';

  @override
  String get caseDossierOpen => 'Dossier öffnen';

  @override
  String get caseDossierError =>
      'Das Dossier konnte nicht erstellt werden. Bitte erneut versuchen.';

  @override
  String get caseDossierErrorNotOwned =>
      'Dieser Fall konnte nicht gefunden werden.';

  @override
  String get caseDossierDisclaimer =>
      'Das Dossier gibt Ihre Falldaten wie erfasst wieder. Bitte vor dem Teilen prüfen.';

  @override
  String get followupsTitle => 'Nächste Schritte';

  @override
  String get followupsSubtitle =>
      'Konkrete Aufgaben, um Ihren Fall voranzubringen';

  @override
  String get followupsEmpty => 'Noch keine Folgeschritte.';

  @override
  String get followupsEmptyDesc =>
      'Fügen Sie einen Schritt hinzu oder lassen Sie sich von der KI Vorschläge machen.';

  @override
  String get followupsAdd => 'Schritt hinzufügen';

  @override
  String get followupsSuggest => 'Schritte vorschlagen';

  @override
  String get followupsSuggestNone =>
      'Derzeit keine Vorschläge. Versuchen Sie es nach einem Gespräch über den Fall erneut.';

  @override
  String get followupsSuggestTitle => 'Vorgeschlagene nächste Schritte';

  @override
  String get followupsAddPrompt =>
      'Fügen Sie die Schritte hinzu, die Sie behalten möchten:';

  @override
  String get followupsNewTitleHint => 'Was muss getan werden?';

  @override
  String get followupsNewDetailHint =>
      'Optionale Notiz (warum / was beizufügen ist)';

  @override
  String get followupsDueOptional => 'Erinnern am (optional)';

  @override
  String get followupsOverdue => 'Überfällig';

  @override
  String followupsDueOn(String date) {
    return 'Fällig am $date';
  }

  @override
  String get followupsDone => 'Erledigt';

  @override
  String get followupsSnooze => 'Später erinnern';

  @override
  String get followupsSnooze1Week => 'In einer Woche erinnern';

  @override
  String get followupsDismiss => 'Verwerfen';

  @override
  String get followupsLoadError =>
      'Nächste Schritte konnten nicht geladen werden';

  @override
  String get followupsAiBadge => 'KI';

  @override
  String get contractCompareTitle => 'Versionen vergleichen';

  @override
  String get contractCompareIntro =>
      'Laden Sie zwei Versionen desselben Vertrags hoch. Wir markieren, was sich geändert hat und ob jede Änderung für Sie vorteilhaft oder nachteilig ist.';

  @override
  String get contractCompareOldVersion => 'Alte Version (v1)';

  @override
  String get contractCompareNewVersion => 'Neue Version (v2)';

  @override
  String get contractCompareCta => 'Versionen vergleichen';

  @override
  String get contractCompareAdverse => 'Nachteilig';

  @override
  String get contractCompareFavorable => 'Vorteilhaft';

  @override
  String get contractCompareNeutral => 'Neutral';

  @override
  String get contractCompareBefore => 'Vorher';

  @override
  String get contractCompareAfter => 'Nachher';

  @override
  String get contractCompareTruncated =>
      'Langer Vertrag – nur der erste Teil jeder Version wurde verglichen.';

  @override
  String get contractCompareNoChanges =>
      'Keine wesentlichen Änderungen zwischen den beiden Versionen festgestellt.';

  @override
  String get docSearchTitle => 'Meine Dokumente durchsuchen';

  @override
  String get docSearchHint => 'z. B. wo wurde die Kaution erwähnt';

  @override
  String get docSearchSubtitle =>
      'Semantische Suche in Ihrem Tresor und Ihren Fallunterlagen';

  @override
  String get docSearchIdle =>
      'Durchsuchen Sie den Inhalt Ihrer eigenen Dokumente – nicht nur die Titel.';

  @override
  String get docSearchNoResults =>
      'Keine Treffer in Ihren Dokumenten gefunden.';

  @override
  String get docSearchError => 'Suche fehlgeschlagen. Bitte erneut versuchen.';

  @override
  String get docSearchUntitled => 'Dokument ohne Titel';

  @override
  String get docSearchKindCase => 'Falldokument';

  @override
  String get docSearchKindVault => 'Tresordokument';

  @override
  String get docSearchMenuTitle => 'Meine Dokumente durchsuchen';

  @override
  String get docSearchMenuSubtitle =>
      'Finden Sie alles in Ihren eigenen Dateien nach Bedeutung';

  @override
  String get legalTemplatesTitle => 'Vorlagenbibliothek';

  @override
  String get legalTemplatesMenuLabel => 'Vorlagen';

  @override
  String get legalTemplatesSubtitle =>
      'Wählen Sie ein fertiges Formular, ergänzen Sie einige Angaben, und wir erstellen einen Entwurf, den Sie bearbeiten und exportieren können.';

  @override
  String get legalTemplatesDisclaimer =>
      'Dies sind allgemeine Musterformulare, keine individuelle Rechtsberatung. Bitte vor dem Versand prüfen und anpassen.';

  @override
  String get legalTemplatesSampleBadge => 'Muster';

  @override
  String get legalTemplatesEmpty => 'Noch keine Vorlagen für diesen Filter.';

  @override
  String get legalTemplatesError =>
      'Vorlagen konnten nicht geladen werden. Bitte erneut versuchen.';

  @override
  String get legalTemplatesFilterAll => 'Alle';

  @override
  String get legalTemplatesJurisdictionFi => 'Finnland';

  @override
  String get legalTemplatesJurisdictionEe => 'Estland';

  @override
  String get legalTemplatesCategoryComplaint => 'Beschwerden';

  @override
  String get legalTemplatesCategoryAppeal => 'Rechtsmittel';

  @override
  String get legalTemplatesCategoryApplication => 'Anträge';

  @override
  String get legalTemplatesCategoryClaim => 'Forderungen';

  @override
  String get legalTemplatesCategoryRequest => 'Ersuchen';

  @override
  String get legalTemplatesFillTitle => 'Angaben ausfüllen';

  @override
  String get legalTemplatesFillIntro =>
      'Wir füllen Ihren Namen und Ihre Falldetails automatisch aus. Bitte ergänzen Sie die Felder unten.';

  @override
  String get legalTemplatesFieldRequired => 'Dieses Feld ist erforderlich';

  @override
  String get legalTemplatesCreateDraft => 'Entwurf erstellen';

  @override
  String get legalTemplatesCreating => 'Entwurf wird erstellt…';

  @override
  String get legalTemplatesCreateFailed =>
      'Der Entwurf konnte nicht erstellt werden. Bitte erneut versuchen.';

  @override
  String get legalTemplatesUnresolvedWarning =>
      'Einige Felder sind noch leer und im Entwurf mit ____ markiert. Sie können sie im Editor ergänzen.';

  @override
  String get legalTemplatesFieldRecipient => 'Empfänger (Behörde / Vermieter)';

  @override
  String get legalTemplatesFieldAddress => 'Ihre Postanschrift';

  @override
  String get legalTemplatesFieldSubject => 'Betreff';

  @override
  String get legalTemplatesFieldDescription => 'Beschreibung des Anliegens';

  @override
  String get legalTemplatesFieldDemand => 'Worum Sie ersuchen';

  @override
  String get checklistActionPlan => 'Aktionsplan';

  @override
  String get checklistActionPlanSubtitle => 'Schritte für diese Art von Fall';

  @override
  String checklistProgress(int completed, int total) {
    return '$completed von $total Schritten erledigt';
  }

  @override
  String get checklistAllDone => 'Alle Schritte abgeschlossen';

  @override
  String get checklistEmpty =>
      'Für diese Fallart ist noch kein Aktionsplan verfügbar.';

  @override
  String checklistDeadlineDays(int days) {
    return '$days Tage';
  }

  @override
  String get checklistDisclaimer =>
      'Dies sind allgemeine Informationen, keine Rechtsberatung. Fristen sind gesetzliche Standardwerte – bestätigen Sie das genaue Datum für Ihren Fall.';

  @override
  String get checklistViewPlan => 'Plan ansehen';

  @override
  String get explainPlainTitle => 'In einfachen Worten erklären';

  @override
  String get explainPlainIntro =>
      'Fügen Sie ein behördliches Schreiben, einen Bescheid oder einen Vertrag ein, und wir erklären in einfacher Sprache, was er bedeutet und was er von Ihnen verlangt.';

  @override
  String get explainPlainLevelFriend => 'Wie einem Freund';

  @override
  String get explainPlainLevelTerms => 'Fachbegriffe beibehalten';

  @override
  String get explainPlainInputHint =>
      'Fügen Sie den juristischen Text hier ein…';

  @override
  String get explainPlainSubmit => 'Erklären';

  @override
  String get explainPlainWorking => 'Wird erklärt…';

  @override
  String get explainPlainTldr => 'Kurz gesagt';

  @override
  String get explainPlainBreakdown =>
      'Was darin steht, Abschnitt für Abschnitt';

  @override
  String get explainPlainGlossary => 'Schwierige Begriffe erklärt';

  @override
  String get explainPlainNextSteps => 'Was Sie als Nächstes tun können';

  @override
  String get explainPlainOpenInCorpus =>
      'In der Gesetzesbibliothek nachschlagen';

  @override
  String get explainPlainEmptyResult =>
      'Für diesen Text konnte keine Erklärung erstellt werden. Versuchen Sie es mit einem längeren oder klareren Auszug.';

  @override
  String get explainPlainQuotaTitle =>
      'Sie haben Ihre kostenlosen Erklärungen für diesen Monat aufgebraucht';

  @override
  String get explainPlainQuotaBody =>
      'Kostenlose Konten erhalten 3 Erklärungen pro Monat. Upgraden Sie auf Pro für unbegrenzte Erklärungen.';

  @override
  String get explainPlainUpgradeCta => 'Auf Pro upgraden';

  @override
  String get explainPlainError =>
      'Beim Erklären dieses Textes ist etwas schiefgelaufen. Bitte erneut versuchen.';

  @override
  String get explainPlainRetry => 'Erneut versuchen';

  @override
  String get demandLetterTitle => 'Mahnschreiben';

  @override
  String get demandLetterSubtitle =>
      'Erstellen Sie eine förmliche vorgerichtliche Aufforderung (maksuvaatimus / nõudekiri).';

  @override
  String get demandLetterStepType => 'Art der Forderung';

  @override
  String get demandLetterStepParties => 'Parteien';

  @override
  String get demandLetterStepClaim => 'Betrag & Grundlage';

  @override
  String get demandLetterStepDeadline => 'Frist';

  @override
  String get demandLetterStepReview => 'Prüfen & erstellen';

  @override
  String get demandLetterClaimDepositReturn => 'Rückzahlung der Mietkaution';

  @override
  String get demandLetterClaimUnpaidWage => 'Ausstehender Lohn';

  @override
  String get demandLetterClaimFineDispute =>
      'Anfechtung eines Bußgelds / einer Gebühr';

  @override
  String get demandLetterClaimGeneric => 'Sonstige Geldforderung';

  @override
  String get demandLetterJurisdiction => 'Rechtsraum';

  @override
  String get demandLetterLanguage => 'Sprache des Schreibens';

  @override
  String get demandLetterRecipientName => 'Name des Empfängers';

  @override
  String get demandLetterRecipientAddress =>
      'Anschrift des Empfängers (optional)';

  @override
  String get demandLetterSenderName => 'Ihr Name';

  @override
  String get demandLetterSenderAddress => 'Ihre Anschrift / E-Mail (optional)';

  @override
  String get demandLetterAmount => 'Betrag';

  @override
  String get demandLetterCurrency => 'Währung';

  @override
  String get demandLetterBasis => 'Was geschehen ist (Grundlage der Forderung)';

  @override
  String get demandLetterBasisHint =>
      'Beschreiben Sie den Sachverhalt: Daten, Beträge, was vereinbart wurde und was schiefging.';

  @override
  String get demandLetterDeadline => 'Zahlungsfrist';

  @override
  String get demandLetterDeadlineHint => 'z. B. 14 Tage ab heute';

  @override
  String get demandLetterReference => 'Aktenzeichen (optional)';

  @override
  String get demandLetterGenerate => 'Schreiben erstellen';

  @override
  String get demandLetterGenerating => 'Wird erstellt…';

  @override
  String get demandLetterGenerateFailed =>
      'Das Schreiben konnte nicht erstellt werden. Bitte erneut versuchen.';

  @override
  String get demandLetterFieldRequired => 'Dieses Feld ist erforderlich';

  @override
  String get demandLetterNext => 'Weiter';

  @override
  String get demandLetterBack => 'Zurück';

  @override
  String get demandLetterPreviewTitle => 'Ihr Schreiben';

  @override
  String get demandLetterCopy => 'Text kopieren';

  @override
  String get demandLetterCopied => 'Schreiben in die Zwischenablage kopiert';

  @override
  String get demandLetterExportPdf => 'PDF exportieren';

  @override
  String get demandLetterExporting => 'Wird exportiert…';

  @override
  String get demandLetterExportFailed =>
      'Das Dokument konnte nicht exportiert werden. Bitte erneut versuchen.';

  @override
  String get demandLetterSendEmail => 'Per E-Mail senden';

  @override
  String get demandLetterNormsTitle => 'Rechtsgrundlagen';

  @override
  String get demandLetterDisclaimer =>
      'Dieses Schreiben wird in Ihrem Namen als allgemeine Vorlage erstellt. Es ist keine Rechtsberatung und keine Handlung eines zugelassenen Rechtsbeistands. Bitte vor dem Versand prüfen – es wird kein Schreiben automatisch versendet.';

  @override
  String get demandLetterMenuTile => 'Mahnschreiben';

  @override
  String get calcHubTitle => 'Juristische Rechner';

  @override
  String get calcHubSubtitle =>
      'Schnelle Schätzungen vor Ihrem nächsten Schritt';

  @override
  String get calcHubJurisdiction => 'Rechtsraum';

  @override
  String calcRatesAsOf(String date) {
    return 'Sätze mit Stand $date';
  }

  @override
  String get calcRatesOffline =>
      'Zwischengespeicherte Sätze werden angezeigt (offline)';

  @override
  String get calcIndicativeBanner =>
      'Nur eine Richtschätzung – keine offizielle Berechnung und keine Rechtsberatung.';

  @override
  String get calcCalculate => 'Berechnen';

  @override
  String get calcResult => 'Ergebnis';

  @override
  String get calcFormula => 'So wird dies berechnet';

  @override
  String get calcSource => 'Quelle';

  @override
  String get calcSeveranceTitle => 'Abfindung / Kündigungsfrist';

  @override
  String get calcSeveranceDesc =>
      'Abfindung und Kündigungsfrist bei betriebsbedingter Kündigung schätzen';

  @override
  String get calcSeveranceSalary => 'Monatliches Bruttogehalt';

  @override
  String get calcSeveranceTenure => 'Dienstjahre';

  @override
  String get calcSeveranceTotal => 'Geschätzte Abfindung';

  @override
  String get calcSeveranceNotice => 'Kündigungsfrist';

  @override
  String get calcSeveranceGenerateDemand => 'Mahnschreiben entwerfen';

  @override
  String get calcLimitationTitle => 'Verjährungs- und Rechtsmittelfristen';

  @override
  String get calcLimitationDesc =>
      'Prüfen, ob eine Forderungs- oder Rechtsmittelfrist abgelaufen ist';

  @override
  String get calcLimitationType => 'Art der Frist';

  @override
  String get calcLimitationStart => 'Beginndatum (Ereignis / Bescheid)';

  @override
  String get calcLimitationPickDate => 'Datum wählen';

  @override
  String get calcLimitationDeadline => 'Frist';

  @override
  String get calcLimitationExpired => 'Frist ist abgelaufen';

  @override
  String calcLimitationDaysLeft(int days) {
    return '$days Tage verbleibend';
  }

  @override
  String get calcLimitationShifted =>
      'Auf den nächsten Werktag verschoben (Wochenende/Feiertag).';

  @override
  String get calcLimitationAddDeadline => 'Zu Fristen hinzufügen';

  @override
  String get calcStateFeeTitle => 'Gerichts- / Verwaltungsgebühren';

  @override
  String get calcStateFeeDesc =>
      'Übersicht der Verfahrensgebühren nach Gericht und Verfahrensstufe';

  @override
  String get calcChildSupportTitle => 'Kindesunterhalt (Orientierung)';

  @override
  String get calcChildSupportDesc =>
      'Grober Orientierungswert – der tatsächliche Betrag wird im Einzelfall festgelegt';

  @override
  String get calcChildSupportNet =>
      'Monatliches Nettoeinkommen des Zahlungspflichtigen';

  @override
  String get calcChildSupportChildren => 'Anzahl der Kinder';

  @override
  String get calcChildSupportPerChild => 'Pro Kind';

  @override
  String get calcChildSupportTotal => 'Monatlich gesamt';

  @override
  String get calcChildSupportWarning =>
      'Stark variabel. Gerichte entscheiden anhand des Bedarfs des Kindes und der Leistungsfähigkeit beider Elternteile. Nur als Ausgangspunkt verwenden.';

  @override
  String get docCollectTitle => 'Zu sammelnde Dokumente';

  @override
  String get docCollectSubtitle =>
      'Sammeln Sie diese, bevor Sie einen Antrag stellen oder vor Gericht gehen';

  @override
  String get docCollectPickPrompt => 'Wie ist Ihre Situation?';

  @override
  String get docCollectProblemResidence => 'Aufenthaltstitel';

  @override
  String get docCollectProblemTenant => 'Miete / Räumung';

  @override
  String get docCollectProblemDismissal => 'Kündigung im Arbeitsverhältnis';

  @override
  String get docCollectProblemInheritance => 'Erbschaft';

  @override
  String get docCollectProblemDivorce => 'Scheidung';

  @override
  String docCollectProgress(int collected, int total) {
    return '$collected von $total gesammelt';
  }

  @override
  String get docCollectAllDone => 'Alles gesammelt';

  @override
  String get docCollectEmpty =>
      'Für diese Situation ist noch keine Dokumentenliste verfügbar.';

  @override
  String get docCollectOptional => 'Optional';

  @override
  String get docCollectWhereLabel => 'Wo erhältlich';

  @override
  String get docCollectWhyLabel => 'Warum erforderlich';

  @override
  String get docCollectAttach => 'Datei anhängen';

  @override
  String get docCollectAttached => 'Datei angehängt';

  @override
  String get docCollectChangeFile => 'Datei ändern';

  @override
  String get docCollectRemoveFile => 'Datei entfernen';

  @override
  String get docCollectNoFiles => 'Sie haben noch keine Dokumente hochgeladen.';

  @override
  String get docCollectPickFileTitle => 'Hochgeladenes Dokument auswählen';

  @override
  String get docCollectExport => 'Liste exportieren';

  @override
  String get docCollectExportSubject => 'Meine Dokumenten-Checkliste';

  @override
  String get docCollectAiTitle => 'Brauchen Sie etwas Bestimmtes?';

  @override
  String get docCollectAiHint =>
      'Beschreiben Sie Ihre Situation, und wir schlagen zusätzliche Dokumente vor.';

  @override
  String get docCollectAiField => 'Beschreiben Sie Ihre Situation';

  @override
  String get docCollectAiButton => 'Zusätzliche Dokumente vorschlagen';

  @override
  String get docCollectAiLoading => 'Wird überlegt…';

  @override
  String get docCollectAiEmpty =>
      'Keine zusätzlichen Dokumente vorgeschlagen – die Grundliste scheint für Ihre Beschreibung vollständig zu sein.';

  @override
  String get docCollectAiSuggestionsTitle =>
      'Vorgeschlagene zusätzliche Dokumente';

  @override
  String get docCollectDisclaimer =>
      'Dies ist eine Grundliste der üblicherweise erforderlichen Dokumente – Ihre Situation kann mehr oder weniger erfordern. Es handelt sich um allgemeine Informationen, keine Rechtsberatung.';

  @override
  String get docCollectRetry => 'Erneut versuchen';

  @override
  String get renewalTitle => 'Verlängerungs-Radar';

  @override
  String get renewalSubtitle =>
      'Behalten Sie im Blick, wann Ihre Genehmigungen, Ihr Reisepass, Ihre Versicherung und andere Dokumente ablaufen. Wir erinnern Sie 90, 30 und 7 Tage vor jeder Verlängerung.';

  @override
  String get renewalAdd => 'Dokument hinzufügen';

  @override
  String get renewalEditTitle => 'Dokument bearbeiten';

  @override
  String get renewalSave => 'Speichern';

  @override
  String get renewalRequired => 'Erforderlich';

  @override
  String get renewalPickDate => 'Ablaufdatum wählen';

  @override
  String get renewalLoadError =>
      'Ihre Dokumente konnten nicht geladen werden. Zum Aktualisieren ziehen.';

  @override
  String get renewalEmptyTitle => 'Noch keine Dokumente erfasst';

  @override
  String get renewalEmptyBody =>
      'Fügen Sie Ihren Aufenthaltstitel, Reisepass, Ihre Versicherung oder Lizenz hinzu, und wir behalten die Ablaufdaten für Sie im Blick.';

  @override
  String get renewalGuideHint => 'So verlängern Sie →';

  @override
  String get renewalFieldType => 'Dokumententyp';

  @override
  String get renewalFieldLabel => 'Bezeichnung';

  @override
  String get renewalFieldNumber => 'Dokumentennummer (optional)';

  @override
  String get renewalFieldJurisdiction => 'Ausstellungsland';

  @override
  String get renewalFieldExpiry => 'Ablaufdatum';

  @override
  String get renewalWindow90 => '90 Tage';

  @override
  String get renewalWindow30 => '30 Tage';

  @override
  String get renewalWindow7 => '7 Tage';

  @override
  String get renewalExpiresToday => 'Läuft heute ab';

  @override
  String renewalExpiresInDays(int days, String date) {
    return 'Läuft in $days Tagen ab · $date';
  }

  @override
  String renewalExpiredOn(String date) {
    return 'Abgelaufen am $date';
  }

  @override
  String get renewalTypeResidencePermit => 'Aufenthaltstitel';

  @override
  String get renewalTypePassport => 'Reisepass';

  @override
  String get renewalTypeIdCard => 'Personalausweis';

  @override
  String get renewalTypeVisa => 'Visum';

  @override
  String get renewalTypeDrivingLicence => 'Führerschein';

  @override
  String get renewalTypeInsurance => 'Versicherung';

  @override
  String get renewalTypeWorkPermit => 'Arbeitserlaubnis';

  @override
  String get renewalTypeOther => 'Sonstiges';

  @override
  String get costEstimateTitle => 'Kosten- & Risikorechner';

  @override
  String get costEstimateSubtitle =>
      'Verschaffen Sie sich einen groben Überblick darüber, was ein Fall kosten könnte, wie lange er dauern könnte und ob er sich lohnt.';

  @override
  String get costEstimateCaseTypeLabel => 'Art des Falls';

  @override
  String get costEstimateCaseTypeHint =>
      'z. B. unbezahlte Rechnung, ungerechtfertigte Kündigung, Kautionsstreit';

  @override
  String get costEstimateJurisdictionLabel => 'Rechtsraum';

  @override
  String get costEstimateAmountLabel => 'Streitwert (optional)';

  @override
  String get costEstimateAmountHint => 'z. B. 12500';

  @override
  String get costEstimateDescriptionLabel =>
      'Beschreiben Sie die Situation kurz (optional)';

  @override
  String get costEstimateB2bToggle => 'Lead-Qualifizierungskarte (B2B)';

  @override
  String get costEstimateB2bSubtitle =>
      'Kompakte Ausgabe zur schnellen Einordnung eines eingehenden Mandanten.';

  @override
  String get costEstimateSubmit => 'Meinen Fall einschätzen';

  @override
  String get costEstimateDisclaimer =>
      'Nur eine grobe Schätzung – keine Prognose, keine Garantie und keine Rechtsberatung. Tatsächliche Kosten und Ergebnisse variieren von Fall zu Fall.';

  @override
  String get costEstimateCostsHeading => 'Geschätzte Kosten';

  @override
  String get costEstimateCourtFee => 'Gerichts- / Verwaltungsgebühr';

  @override
  String get costEstimateLawyerFee => 'Honorar für Rechtsbeistand';

  @override
  String get costEstimateTotal => 'Gesamt (ca.)';

  @override
  String get costEstimateDuration => 'Zeit bis zur ersten Klärung';

  @override
  String get costEstimateMonthsSuffix => 'Monate';

  @override
  String get costEstimateFactorsFor => 'Zu Ihren Gunsten';

  @override
  String get costEstimateFactorsAgainst => 'Gegen Sie sprechend';

  @override
  String get costEstimateStrengthWorth => 'Wahrscheinlich lohnenswert';

  @override
  String get costEstimateStrengthContested => 'Umstritten – Ausgang offen';

  @override
  String get costEstimateStrengthWeak => 'Schwach – mit Vorsicht vorgehen';
}
