// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get about => 'O aplikacji';

  @override
  String get aboutSection => 'O APLIKACJI';

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
  String get accidents => 'Wypadki';

  @override
  String get active => 'Aktywne';

  @override
  String get activeCases => 'Aktywne sprawy';

  @override
  String get addedToAppeal => 'Dodano do odwołania';

  @override
  String get agreeToTerms => 'Akceptuję ';

  @override
  String get aiAnalysis => 'Analiza AI';

  @override
  String get aiAssistant => 'Asystent prawny AI';

  @override
  String get aiChat => 'Czat AI';

  @override
  String get all => 'Wszystkie';

  @override
  String get alreadyHaveAccount => 'Masz już konto? ';

  @override
  String get analyzing => 'Analizowanie…';

  @override
  String get aiAnalyzing => 'AI analizuje';

  @override
  String get speakIntoMicHint =>
      'Speak into the microphone. Make sure microphone access is enabled.';

  @override
  String get aiErrorRateLimit =>
      'Usługa jest tymczasowo przeciążona. Spróbuj ponownie za 1-2 minuty.';

  @override
  String get aiErrorOverload =>
      'AI jest teraz zajęte, spróbuj ponownie za chwilę.';

  @override
  String freeLimitReached(int count) {
    return 'You have used all $count free AI messages. Upgrade to Legal Counsel for unlimited AI assistance!';
  }

  @override
  String get andWord => ' i ';

  @override
  String get appTitle => 'Advocat — Narzędzie informacji prawnej';

  @override
  String get appVersion => 'Wersja aplikacji';

  @override
  String get appealFiled => 'Odwołanie złożone';

  @override
  String get areYouAbsolutelySure => 'Czy jesteś absolutnie pewien?';

  @override
  String get askAboutCase => 'Przeanalizuj moją sprawę';

  @override
  String get asylum => 'Azyl';

  @override
  String get back => 'Wstecz';

  @override
  String get basic => 'Podstawowy';

  @override
  String get beforeYouBuy => 'Zanim kupisz';

  @override
  String get beforeYouWork => 'Zanim zaczniesz z nimi pracować';

  @override
  String get camera => 'Aparat';

  @override
  String get cancel => 'Anuluj';

  @override
  String get caseDescription => 'Opisz swoją sytuację';

  @override
  String get caseDetail => 'Szczegóły sprawy';

  @override
  String get caseOverview => 'Oto przegląd Twoich spraw';

  @override
  String get caseTitle => 'Tytuł sprawy';

  @override
  String get caseUpdated => 'Sprawa zaktualizowana';

  @override
  String get cases => 'Sprawy';

  @override
  String get checkCompany => 'Sprawdź firmę';

  @override
  String get checkDeadlines => 'Sprawdź terminy';

  @override
  String get checkVehicle => 'Sprawdź pojazd';

  @override
  String get checkerTitle => 'Weryfikator';

  @override
  String get checkingErrors => 'Sprawdzanie błędów…';

  @override
  String get choosePlan => 'Wybierz plan';

  @override
  String get closed => 'Zamknięte';

  @override
  String get companyName => 'Nazwa firmy lub numer rejestracyjny';

  @override
  String get completed => 'Zakończone';

  @override
  String get confirm => 'Potwierdź';

  @override
  String get confirmPassword => 'Potwierdź hasło';

  @override
  String get connectEmail => 'Połącz e-mail';

  @override
  String get connectGmail => 'Połącz Gmail';

  @override
  String get connectOutlook => 'Połącz Outlook';

  @override
  String get connected => 'Połączony';

  @override
  String get contactSupport => 'Skontaktuj się z pomocą';

  @override
  String get continueWithGoogle => 'Kontynuuj z Google';

  @override
  String get appleComingSoon => 'Już wkrótce';

  @override
  String get appleComingSoonMessage =>
      'Logowanie przez Apple będzie wkrótce dostępne. Użyj Google lub e-maila, aby kontynuować.';

  @override
  String get copyText => 'Kopiuj tekst';

  @override
  String get correspondence => 'Korespondencja';

  @override
  String get couldNotLoadCases => 'Nie udało się załadować Twoich spraw';

  @override
  String get country => 'Kraj';

  @override
  String get createAccount => 'Utwórz konto';

  @override
  String get createCase => 'Utwórz sprawę';

  @override
  String get criminalCase => 'Sprawa karna';

  @override
  String get critical => 'Krytyczny';

  @override
  String get currentPlan => 'Obecny plan';

  @override
  String get dataAndPrivacy => 'DANE I PRYWATNOŚĆ';

  @override
  String get dataExportRequested =>
      'Eksport danych zamówiony. Sprawdź swój e-mail.';

  @override
  String daysRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dni',
      many: '$count dni',
      few: '$count dni',
      one: '1 dzień',
      zero: 'brak pozostałych dni',
    );
    return '$_temp0';
  }

  @override
  String get deadlineReminders => 'Przypomnienia o terminach';

  @override
  String get deadlineRemindersDesc => 'Otrzymuj powiadomienia przed terminami';

  @override
  String get deadlines => 'Terminy';

  @override
  String get debtCollection => 'Windykacja długów';

  @override
  String get deleteAccount => 'Usuń konto';

  @override
  String get deleteAccountDesc => 'Trwale usuń swoje konto';

  @override
  String get deleteAccountDialogContent =>
      'Ta czynność jest nieodwracalna. Wszystkie Twoje dane, sprawy i dokumenty zostaną trwale usunięte.';

  @override
  String get deleteConfirm =>
      'Czy jesteś pewien? To trwale usunie wszystkie Twoje dane.';

  @override
  String get demoHint => 'Demo: wypróbuj tablicę „908FBT”';

  @override
  String get demoModeDesc =>
      'Poznaj aplikację z przykładowymi danymi z prawdziwej sprawy';

  @override
  String get deportation => 'Deportacja';

  @override
  String get disclaimer =>
      'Tylko wskazówki AI — nie porada prawna. Zawsze skonsultuj się z adwokatem.';

  @override
  String get disclaimerFull =>
      'To asystent AI, nie adwokat. Analiza AI może zawierać błędy. Zawsze weryfikuj z wykwalifikowanym prawnikiem.';

  @override
  String get disconnect => 'Odłącz';

  @override
  String get discrimination => 'Dyskryminacja';

  @override
  String get doNotBuy => 'Nie kupuj';

  @override
  String get documents => 'Dokumenty';

  @override
  String documentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dokumentów',
      many: '$count dokumentów',
      few: '$count dokumenty',
      one: '1 dokument',
      zero: 'brak dokumentów',
    );
    return '$_temp0';
  }

  @override
  String get draftAppeal => 'Projekt odwołania';

  @override
  String get editDraft => 'Edytuj';

  @override
  String get editProfile => 'Edytuj profil';

  @override
  String get email => 'E-mail';

  @override
  String get emailConnected => 'E-mail połączony';

  @override
  String get emailDisconnected => 'E-mail odłączony';

  @override
  String get emailIntegration => 'INTEGRACJA E-MAIL';

  @override
  String get emailInvalid => 'Podaj prawidłowy adres e-mail';

  @override
  String get emailPrivacyNote =>
      'Czytamy tylko e-maile związane ze sprawami prawnymi. Twoje prywatne e-maile pozostają prywatne.';

  @override
  String get emailRequired => 'E-mail jest wymagany';

  @override
  String get emergencyShield => 'Tarcza awaryjna';

  @override
  String get error => 'Błąd';

  @override
  String get exportDataDesc => 'Pobierz wszystkie dane spraw';

  @override
  String get exportDataDialogContent =>
      'Przygotujemy plik do pobrania ze wszystkimi Twoimi danymi, w tym sprawami, dokumentami i korespondencją. Otrzymasz e-mail, gdy będzie gotowy.';

  @override
  String get exportMyData => 'Eksportuj moje dane';

  @override
  String get exportPdf => 'Eksportuj PDF';

  @override
  String get familyReunification => 'Łączenie rodzin';

  @override
  String get forgotPassword => 'Zapomniałeś hasła?';

  @override
  String get free => 'Bezpłatny';

  @override
  String get fullDefense => 'Advocat Pro';

  @override
  String get fullName => 'Imię i nazwisko';

  @override
  String get gallery => 'Galeria';

  @override
  String get generateAppeal => 'Generuj odwołanie';

  @override
  String get getStarted => 'Rozpocznij';

  @override
  String goodAfternoon(String name) {
    return 'Dzień dobry, $name';
  }

  @override
  String goodEvening(String name) {
    return 'Dobry wieczór, $name';
  }

  @override
  String goodMorning(String name) {
    return 'Dzień dobry, $name';
  }

  @override
  String goodNight(String name) {
    return 'Dobranoc, $name';
  }

  @override
  String get home => 'Główna';

  @override
  String get important => 'Ważny';

  @override
  String get inProgress => 'W toku';

  @override
  String get informational => 'Informacyjny';

  @override
  String get inspection => 'Przegląd techniczny';

  @override
  String get insurance => 'Ubezpieczenie';

  @override
  String issuesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Znaleziono $count problemów',
      many: 'Znaleziono $count problemów',
      few: 'Znaleziono $count problemy',
      one: 'Znaleziono 1 problem',
      zero: 'nie znaleziono problemów',
    );
    return '$_temp0';
  }

  @override
  String get laborDispute => 'Spór pracowniczy';

  @override
  String get langEnglish => 'Angielski';

  @override
  String get langFinnish => 'Fiński';

  @override
  String get langRussian => 'Rosyjski';

  @override
  String get language => 'Język';

  @override
  String lastActivity(String time) {
    return 'Ostatnia aktywność: $time';
  }

  @override
  String get legalFighter => 'Wojownik prawny';

  @override
  String get legalSection => 'PRAWNE';

  @override
  String get licensePlate => 'Numer rejestracyjny';

  @override
  String get loading => 'Ładowanie…';

  @override
  String get logIn => 'Zaloguj się';

  @override
  String get loginFailed => 'Nieprawidłowy e-mail lub hasło. Spróbuj ponownie.';

  @override
  String get lost => 'Przegrana';

  @override
  String get markComplete => 'Oznacz jako zakończone';

  @override
  String get mileage => 'Przebieg';

  @override
  String get myCases => 'Moje sprawy';

  @override
  String get nameRequired => 'Imię i nazwisko jest wymagane';

  @override
  String get newCase => 'Nowa sprawa';

  @override
  String get next => 'Dalej';

  @override
  String get noAccount => 'Nie masz konta? ';

  @override
  String get noCases => 'Brak spraw';

  @override
  String get noCasesYet => 'Brak spraw';

  @override
  String get noDeadlines => 'Brak terminów — wszystko w porządku!';

  @override
  String get noRecentActivity => 'Brak ostatniej aktywności';

  @override
  String get notifications => 'POWIADOMIENIA';

  @override
  String get onboardingDesc1 =>
      'Advocat pomaga zrozumieć Twoją sytuację prawną. Narzędzia AI analizują dokumenty, identyfikują potencjalne problemy i przygotowują projekty dokumentów do Twojej weryfikacji. To nie kancelaria prawna — to narzędzie technologiczne wspierające Twoją sprawę.';

  @override
  String get onboardingDesc2 =>
      'Sfotografuj dowolny dokument prawny. AI odczytuje go w wielu językach, wyodrębnia kluczowe dane i sprawdza zgodność z dyrektywami UE i przepisami krajowymi.';

  @override
  String get onboardingDesc3 =>
      'Nasze narzędzia AI sprawdzają ponad 40 typów wymogów proceduralnych. Analiza AI może wykryć problemy wymagające uwagi — takie jak język doręczenia, kroki proceduralne i terminy prawne. Zawsze weryfikuj z wykwalifikowanym adwokatem.';

  @override
  String get onboardingDesc4 =>
      'AI przygotowuje projekty odwołań, skarg i pism z odniesieniami prawnymi do Twojej weryfikacji. Ty decydujesz, co złożyć. Każdy dokument powinien być zweryfikowany przez wykwalifikowanego prawnika przed złożeniem.';

  @override
  String get onboardingNext => 'Dalej';

  @override
  String get onboardingSkip => 'Pomiń';

  @override
  String get onboardingTitle1 => 'Informacje prawne oparte na AI';

  @override
  String get onboardingTitle2 => 'Skanuj i analizuj dokumenty';

  @override
  String get onboardingTitle3 => 'AI sprawdza potencjalne problemy';

  @override
  String get onboardingTitle4 => 'Projekty dokumentów do Twojej weryfikacji';

  @override
  String get openACase => 'Otwórz sprawę';

  @override
  String get optional => '(opcjonalnie)';

  @override
  String get orDivider => 'lub';

  @override
  String get other => 'Inne';

  @override
  String get overdue => 'Zaległe';

  @override
  String get owners => 'Poprzedni właściciele';

  @override
  String get password => 'Hasło';

  @override
  String get passwordRequired => 'Hasło jest wymagane';

  @override
  String get passwordStrengthMedium => 'Średnie';

  @override
  String get passwordStrengthStrong => 'Silne';

  @override
  String get passwordStrengthWeak => 'Słabe';

  @override
  String get passwordTooShort => 'Hasło musi mieć co najmniej 8 znaków';

  @override
  String get passwordsDoNotMatch => 'Hasła nie są zgodne';

  @override
  String get pendingDecision => 'Oczekiwanie na decyzję';

  @override
  String get perCheck => 'za sprawdzenie';

  @override
  String get permanentlyDelete => 'Usuń trwale';

  @override
  String get policeMisconduct => 'Nadużycia policji';

  @override
  String get popular => 'POPULARNE';

  @override
  String get preferences => 'PREFERENCJE';

  @override
  String get preferredLanguage => 'Preferowany język';

  @override
  String get pricePerCheck => '€4,99 za sprawdzenie';

  @override
  String get privacyPolicy => 'Politykę prywatności';

  @override
  String get dpaTitle => 'Umowa powierzenia przetwarzania danych';

  @override
  String get dpaCheckoutGateTitle => 'Zanim przejdziesz na wyższy plan';

  @override
  String get dpaCheckoutGateBody =>
      'Prawo UE (art. 28 RODO) wymaga od nas zawarcia umowy powierzenia przetwarzania danych z każdym płacącym klientem. Zapoznaj się z nią i zaakceptuj.';

  @override
  String get dpaViewLink => 'Wyświetl umowę powierzenia przetwarzania danych';

  @override
  String get dpaCheckboxLabel =>
      'Przeczytałem(-am) i akceptuję umowę powierzenia przetwarzania danych (v1.0).';

  @override
  String get dpaCancel => 'Anuluj';

  @override
  String get dpaAcceptAndContinue => 'Zaakceptuj i kontynuuj';

  @override
  String get dpaOpenHint =>
      'Otwórz umowę powierzenia przynajmniej raz, aby aktywować przycisk Zaakceptuj.';

  @override
  String get pro => 'Pro';

  @override
  String get pushNotifications => 'Powiadomienia push';

  @override
  String get rateUs => 'Oceń nas';

  @override
  String get rateAppComingSoon => 'Coming to app stores soon!';

  @override
  String get dataCopiedToClipboard => 'Data copied to clipboard';

  @override
  String get readingDocument => 'Odczytywanie dokumentu…';

  @override
  String get recentActivity => 'Ostatnia aktywność';

  @override
  String get referenceNumber => 'Numer referencyjny';

  @override
  String get registerFailed =>
      'Rejestracja nie powiodła się. Spróbuj ponownie.';

  @override
  String get reportFraud => 'Zgłoś oszustwo';

  @override
  String get requestExport => 'Poprosi o eksport';

  @override
  String get researchingLaw => 'Badanie obowiązującego prawa…';

  @override
  String get resetPasswordFailed =>
      'Nie udało się wysłać linku. Spróbuj ponownie.';

  @override
  String get resetPasswordSent =>
      'Link do resetowania hasła wysłany na Twój e-mail.';

  @override
  String get residencePermit => 'Pozwolenie na pobyt';

  @override
  String get manageSubscription => 'Zarządzaj subskrypcją';

  @override
  String get restorePurchases => 'Przywróć zakupy';

  @override
  String get retry => 'Spróbuj ponownie';

  @override
  String get reviewWarning =>
      'Dokładnie przejrzyj przed wysłaniem. Jesteś odpowiedzialny za treść.';

  @override
  String get riskHigh => 'Wysokie ryzyko — unikaj';

  @override
  String get riskLow => 'Bezpiecznie współpracować';

  @override
  String get riskMedium => 'Zachowaj ostrożność';

  @override
  String get safeToBuy => 'Bezpiecznie do kupienia';

  @override
  String get saveAndAnalyze => 'Zapisz i analizuj';

  @override
  String get saveDraft => 'Zapisz';

  @override
  String get saveWithAnnual => 'Zaoszczędź 25% przy rozliczeniu rocznym';

  @override
  String get scan => 'Skanuj';

  @override
  String get scanDocument => 'Skanuj dokument';

  @override
  String get searchCases => 'Szukaj spraw…';

  @override
  String get selectCountry => 'Wybierz kraj';

  @override
  String get selectLanguage => 'Wybierz język';

  @override
  String get sendViaEmail => 'Wyślij e-mailem';

  @override
  String get settings => 'Ustawienia';

  @override
  String get signIn => 'Zaloguj się';

  @override
  String get signInLink => 'Zaloguj się';

  @override
  String get signInSubtitle =>
      'Zaloguj się, aby uzyskać dostęp do swoich spraw';

  @override
  String get signOut => 'Wyloguj się';

  @override
  String get signOutConfirm => 'Czy na pewno chcesz się wylogować?';

  @override
  String get signUp => 'Utwórz konto';

  @override
  String get signUpLink => 'Zarejestruj się';

  @override
  String get socialBenefits => 'Świadczenia socjalne';

  @override
  String get someConcerns => 'Pewne zastrzeżenia';

  @override
  String get startFirstCase => 'Rozpocznij swoją pierwszą sprawę';

  @override
  String step(int current, int total) {
    return 'Krok $current z $total';
  }

  @override
  String get stolen => 'Sprawdzenie kradzieży';

  @override
  String get subscription => 'Subskrypcja';

  @override
  String get syncLegalCorrespondence => 'Synchronizuj korespondencję prawną';

  @override
  String get syncNow => 'Synchronizuj teraz';

  @override
  String get tenantRights => 'Prawa najemcy';

  @override
  String get termsOfService => 'Regulamin';

  @override
  String get termsRequired => 'Musisz zaakceptować Regulamin';

  @override
  String get timeline => 'Oś czasu';

  @override
  String get tryDemoMode => 'Wypróbuj tryb demo';

  @override
  String get typeDeleteToConfirm =>
      'Wpisz DELETE, aby potwierdzić trwałe usunięcie konta.';

  @override
  String get typeMessage => 'Napisz wiadomość…';

  @override
  String get upcoming => 'Nadchodzące';

  @override
  String get uploadDocument => 'Prześlij dokument';

  @override
  String urgentDeadline(String title) {
    return 'Pilne: $title';
  }

  @override
  String get useInAppeal => 'Użyj w odwołaniu';

  @override
  String get vehicleChecker => 'Weryfikacja pojazdu';

  @override
  String get vehicleChecks => 'Kontrole stanu';

  @override
  String get vehicleColor => 'Kolor';

  @override
  String get vehicleMake => 'Marka';

  @override
  String get vehicleModel => 'Model';

  @override
  String get vehicleYear => 'Rok';

  @override
  String get version => 'Wersja';

  @override
  String get victimSupport => 'Wsparcie ofiar';

  @override
  String get viewAll => 'Pokaż wszystkie';

  @override
  String get vinNumber => 'Numer VIN';

  @override
  String get welcomeBack => 'Witaj ponownie';

  @override
  String get whatAreMyOptions => 'Jakie mam opcje?';

  @override
  String get won => 'Wygrana';

  @override
  String get documentVault => 'Sejf dokumentów';

  @override
  String get secureDocumentStorage => 'Bezpieczne przechowywanie dokumentów';

  @override
  String get secureDocumentStorageDesc =>
      'Przechowuj ważne dokumenty prawne w jednym miejscu.';

  @override
  String get addDocument => 'Dodaj dokument';

  @override
  String get chooseHowToAdd => 'Wybierz sposób dodania dokumentu';

  @override
  String get uploadFile => 'Prześlij plik';

  @override
  String get uploadFileDesc => 'Wybierz PDF lub obraz z urządzenia';

  @override
  String get scanDocumentDesc => 'Zrób zdjęcie dokumentu';

  @override
  String get createNote => 'Utwórz notatkę';

  @override
  String get createNoteDesc => 'Napisz notatkę lub zapisz ważne szczegóły';

  @override
  String get knowYourRights => 'Poznaj swoje prawa';

  @override
  String get stoppedByPolice => 'Zatrzymany przez policję';

  @override
  String get stoppedByPoliceDesc => 'Twoje prawa podczas kontroli policyjnej';

  @override
  String get deportationNotice => 'Zawiadomienie o deportacji';

  @override
  String get deportationNoticeDesc =>
      'Kroki do zakwestionowania nakazu wydalenia';

  @override
  String get workplaceRights => 'Prawa pracownicze';

  @override
  String get workplaceRightsDesc => 'Ochrona prawa pracy w Finlandii';

  @override
  String get tenantRightsDesc => 'Ochrona mieszkaniowa i najemcy';

  @override
  String get immigrationDetention => 'Zatrzymanie imigracyjne';

  @override
  String get immigrationDetentionDesc =>
      'Prawa w przypadku zatrzymania przez władze';

  @override
  String get discriminationDesc => 'Jak zgłaszać i zwalczać dyskryminację';

  @override
  String get scenarioNotFound => 'Scenariusz nie znaleziony';

  @override
  String get youHaveRightTo => 'Masz prawo do:';

  @override
  String get youMust => 'Musisz:';

  @override
  String get immediateSteps => 'Natychmiastowe kroki:';

  @override
  String get yourRights => 'Twoje prawa:';

  @override
  String get basicRights => 'Podstawowe prawa:';

  @override
  String get yourRightsAsTenant => 'Twoje prawa jako najemca:';

  @override
  String get yourRightsInDetention => 'Twoje prawa w zatrzymaniu:';

  @override
  String get howToAct => 'Jak postępować:';

  @override
  String get rightKnowWhyStopped => 'Wiedzieć dlaczego zostałeś zatrzymany';

  @override
  String get rightRemainSilent =>
      'Zachować milczenie (musisz się zidentyfikować)';

  @override
  String get rightAskInterpreter => 'Poproś o tłumacza';

  @override
  String get rightContactLawyer =>
      'Skontaktuj się z prawnikiem przed przesłuchaniem';

  @override
  String get rightRecordEncounter =>
      'Nagrywaj spotkanie (w miejscach publicznych)';

  @override
  String get mustProvideName => 'Podaj imię i datę urodzenia';

  @override
  String get mustShowId => 'Pokaż dowód osobisty, jeśli masz';

  @override
  String get mustNotResist => 'Nie stawiać oporu fizycznego';

  @override
  String get doNotIgnoreNotice =>
      'NIE ignoruj zawiadomienia - terminy są ścisłe';

  @override
  String get noteAppealDeadline => 'Zanotuj termin odwołania (zwykle 30 dni)';

  @override
  String get contactLawyerImmediately =>
      'Natychmiast skontaktuj się z prawnikiem';

  @override
  String get applyLegalAid => 'Złóż wniosek o pomoc prawną w razie potrzeby';

  @override
  String get rightAppealAdmin => 'Prawo do odwołania do sądu administracyjnego';

  @override
  String get rightLegalRep => 'Prawo do reprezentacji prawnej';

  @override
  String get rightInterpreter => 'Prawo do tłumacza';

  @override
  String get rightStayDuringAppeal =>
      'Prawo do pobytu podczas odwołania (w większości przypadków)';

  @override
  String get minimumWage => 'Płaca minimalna wg układu zbiorowego';

  @override
  String get workingTimeLimits =>
      'Limity czasu pracy (max 8h/dzień, 40h/tydzień)';

  @override
  String get annualLeave =>
      'Urlop roczny (min. 2 dni na przepracowany miesiąc)';

  @override
  String get sickLeave => 'Zasiłek chorobowy';

  @override
  String get safeWorkingConditions => 'Bezpieczne warunki pracy';

  @override
  String get writtenRentalAgreement => 'Wymagana pisemna umowa najmu';

  @override
  String get securityDeposit => 'Kaucja max 3 miesiące czynszu';

  @override
  String get landlordNotice =>
      'Wynajmujący musi dać wypowiedzenie (3–6 miesięcy)';

  @override
  String get rightHabitableDwelling =>
      'Prawo do mieszkania nadającego się do zamieszkania';

  @override
  String get protectionUnjustEviction =>
      'Ochrona przed nieuzasadnioną eksmisją';

  @override
  String get rightKnowDetentionReason => 'Prawo do poznania powodu zatrzymania';

  @override
  String get rightContactLawyerDetention => 'Prawo do kontaktu z prawnikiem';

  @override
  String get rightContactEmbassy => 'Prawo do kontaktu z ambasadą';

  @override
  String get rightChallengeDetention =>
      'Prawo do zaskarżenia zatrzymania w sądzie';

  @override
  String get rightHumaneTreatment =>
      'Prawo do humanitarnego traktowania i opieki medycznej';

  @override
  String get documentIncident =>
      'Udokumentuj zdarzenie (data, godzina, świadkowie)';

  @override
  String get fileComplaintOmbudsman => 'Złóż skargę do Rzecznika ds. Równości';

  @override
  String get contactLegalAidOffice => 'Skontaktuj się z biurem pomocy prawnej';

  @override
  String get reportToPolice =>
      'Zgłoś na policję jeśli przestępstwo (groźba, napaść)';

  @override
  String get legalAidCalculator => 'Kalkulator pomocy prawnej';

  @override
  String checkEligibility(String country) {
    return 'Sprawdź swoje uprawnienia do pomocy prawnej: $country';
  }

  @override
  String get estimateDisclaimer =>
      'To tylko szacunek. Faktyczne uprawnienia określa Biuro Pomocy Prawnej.';

  @override
  String get monthlyIncome => 'Dochód miesięczny (EUR)';

  @override
  String get totalAssets => 'Aktywa ogółem (EUR)';

  @override
  String get numberOfDependents => 'Liczba osób na utrzymaniu';

  @override
  String get calculateEligibility => 'Oblicz uprawnienia';

  @override
  String get likelyEligible => 'Prawdopodobnie uprawniony';

  @override
  String get mayNotQualify => 'Może nie kwalifikować się';

  @override
  String get fullFreeLegalAid =>
      'Prawdopodobnie kwalifikujesz się na bezpłatną pomoc prawną.';

  @override
  String legalAidWithCopay(String percent) {
    return 'Możesz kwalifikować się na pomoc prawną ze współpłatnością $percent%.';
  }

  @override
  String get mayNotQualifyDesc =>
      'Na podstawie tej oceny możesz nie kwalifikować się na państwową pomoc prawną.';

  @override
  String get couldNotLoadDeadlines => 'Nie udało się załadować terminów';

  @override
  String get noUpcomingDeadlines => 'Brak nadchodzących terminów';

  @override
  String get allClearDeadlines =>
      'Wszystko w porządku! Nowe terminy pojawią się tutaj.';

  @override
  String get nothingOverdue => 'Nic nie jest przeterminowane';

  @override
  String get greatJobDeadlines => 'Świetna robota z dotrzymywaniem terminów.';

  @override
  String get noCompletedDeadlines => 'Brak ukończonych terminów';

  @override
  String get completedDeadlinesDesc =>
      'Ukończone terminy będą wyświetlane tutaj.';

  @override
  String get daysLate => 'dni opóźnienia';

  @override
  String get days => 'dni';

  @override
  String get fromDocument => 'Z dokumentu';

  @override
  String get couldNotLoadCase => 'Nie udało się załadować szczegółów sprawy';

  @override
  String get typeLabel => 'Typ';

  @override
  String get nationality => 'Narodowość';

  @override
  String get migriReference => 'Numer Migri';

  @override
  String get courtCaseNo => 'Nr sprawy sądowej';

  @override
  String get created => 'Utworzono';

  @override
  String get citizenship => 'Obywatelstwo';

  @override
  String get workPermit => 'Pozwolenie na pracę';

  @override
  String get noDocumentsYet => 'Brak przesłanych dokumentów';

  @override
  String get noUpcomingDeadlinesShort => 'Brak nadchodzących terminów';

  @override
  String get caseCreated => 'Sprawa utworzona';

  @override
  String get decisionReceived => 'Decyzja otrzymana';

  @override
  String get appealDeadline => 'Termin odwołania';

  @override
  String get hearingScheduled => 'Rozprawa zaplanowana';

  @override
  String get late => 'opóźnione';

  @override
  String get pending => 'Oczekujące';

  @override
  String get processing => 'Przetwarzanie';

  @override
  String get ready => 'Gotowe';

  @override
  String get failed => 'Niepowodzenie';

  @override
  String get analyzed => 'Przeanalizowane';

  @override
  String get noDocumentsScanHint => 'Brak dokumentów. Zeskanuj lub prześlij.';

  @override
  String get inCourt => 'W sądzie';

  @override
  String get appeal => 'Odwołanie';

  @override
  String get caseTimeline => 'Oś czasu sprawy';

  @override
  String get couldNotLoadTimeline => 'Nie udało się załadować osi czasu';

  @override
  String get noEventsYet => 'Brak wydarzeń';

  @override
  String get activityWillAppear =>
      'Aktywność pojawi się tutaj w miarę postępu sprawy.';

  @override
  String caseCreatedDesc(String title) {
    return 'Sprawa „$title” została utworzona.';
  }

  @override
  String get decisionReceivedDesc =>
      'Otrzymano oficjalną decyzję w tej sprawie.';

  @override
  String get appealDeadlineSet => 'Termin odwołania ustawiony';

  @override
  String appealDeadlineDesc(String date) {
    return 'Odwołanie musi być złożone do $date.';
  }

  @override
  String hearingScheduledDesc(String date) {
    return 'Rozprawa sądowa zaplanowana na $date.';
  }

  @override
  String get caseInfoUpdated => 'Informacje o sprawie zostały zaktualizowane.';

  @override
  String get noEventsForFilter => 'Brak zdarzeń pasujących do tego filtra';

  @override
  String get timelineFilterAll => 'Wszystkie';

  @override
  String get timelineFilterEmails => 'E-maile';

  @override
  String get timelineFilterConsilium => 'Decyzje AI';

  @override
  String get timelineFilterDeadlines => 'Terminy';

  @override
  String get timelineFilterNotes => 'Notatki';

  @override
  String get timelineEventEmailIn => 'E-mail otrzymany';

  @override
  String get timelineEventEmailOut => 'E-mail wysłany';

  @override
  String get timelineEventConsiliumDecision => 'Decyzja AI';

  @override
  String get timelineEventDeadlineSet => 'Termin';

  @override
  String get timelineEventDocUploaded => 'Dokument';

  @override
  String get timelineEventPhaseChange => 'Zmiana fazy';

  @override
  String get timelineEventManualNote => 'Notatka';

  @override
  String get timelineJustNow => 'Przed chwilą';

  @override
  String timelineMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minuty temu',
      many: '$count minut temu',
      few: '$count minuty temu',
      one: '1 minutę temu',
    );
    return '$_temp0';
  }

  @override
  String timelineHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count godziny temu',
      many: '$count godzin temu',
      few: '$count godziny temu',
      one: '1 godzinę temu',
    );
    return '$_temp0';
  }

  @override
  String timelineDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dnia temu',
      many: '$count dni temu',
      few: '$count dni temu',
      one: '1 dzień temu',
    );
    return '$_temp0';
  }

  @override
  String get documentAnalysis => 'Analiza dokumentu';

  @override
  String get exportAsPdf => 'Eksportuj jako PDF';

  @override
  String get pdfExportComingSoon => 'Eksport PDF wkrótce';

  @override
  String get analysisFailedRetry =>
      'Analiza nie powiodła się. Spróbuj ponownie.';

  @override
  String get somethingWentWrong => 'Coś poszło nie tak';

  @override
  String get genericError => 'Coś poszło nie tak. Spróbuj ponownie.';

  @override
  String get retryAnalysis => 'Ponów analizę';

  @override
  String issuesFoundInDocument(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Znaleziono $count problemów w dokumencie',
      many: 'Znaleziono $count problemów w dokumencie',
      few: 'Znaleziono $count problemy w dokumencie',
      one: 'Znaleziono 1 problem w dokumencie',
      zero: 'Nie znaleziono problemów w dokumencie',
    );
    return '$_temp0';
  }

  @override
  String get severityOverview => 'Przegląd powagi';

  @override
  String get issuesFoundHeader => 'Znalezione problemy';

  @override
  String generateAppealWithIssues(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wygeneruj odwołanie ($count problemów)',
      many: 'Wygeneruj odwołanie ($count problemów)',
      few: 'Wygeneruj odwołanie ($count problemy)',
      one: 'Wygeneruj odwołanie (1 problem)',
    );
    return '$_temp0';
  }

  @override
  String get analyzingContent => 'Analizowanie treści…';

  @override
  String get documentProcessedOk => 'Dokument przetworzony pomyślnie';

  @override
  String get noSignificantIssues =>
      'Nie wykryto istotnych problemów w tym dokumencie.';

  @override
  String get cameraPermissionRequired => 'Wymagane pozwolenie na aparat';

  @override
  String get cameraPermissionDesc =>
      'Udziel dostępu do aparatu, aby skanować dokumenty, lub użyj galerii.';

  @override
  String get openSettings => 'Otwórz ustawienia';

  @override
  String get alignDocument => 'Wyrównaj dokument w ramce';

  @override
  String pageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stron',
      many: '$count stron',
      few: '$count strony',
      one: '1 strona',
      zero: 'brak stron',
    );
    return '$_temp0';
  }

  @override
  String get preview => 'Podgląd';

  @override
  String pageNumber(int number) {
    return 'Strona $number';
  }

  @override
  String get done => 'Gotowe';

  @override
  String get retake => 'Powtórz';

  @override
  String get useThisPhoto => 'Użyj tego zdjęcia';

  @override
  String get addPage => 'Dodaj stronę';

  @override
  String uploadingPercent(int percent) {
    return 'Przesyłanie… $percent%';
  }

  @override
  String get preparingUpload => 'Przygotowywanie przesyłania…';

  @override
  String get documentUploadedSuccess => 'Dokument przesłany pomyślnie';

  @override
  String pagesUploadedSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stron przesłanych pomyślnie',
      many: '$count stron przesłanych pomyślnie',
      few: '$count strony przesłane pomyślnie',
      one: '1 strona przesłana pomyślnie',
    );
    return '$_temp0';
  }

  @override
  String get uploadFailed =>
      'Przesyłanie nie powiodło się. Sprawdź połączenie i spróbuj ponownie.';

  @override
  String get capturePhotoFailed =>
      'Nie udało się zrobić zdjęcia. Spróbuj ponownie.';

  @override
  String get readingText => 'Czytanie tekstu…';

  @override
  String get draftDocument => 'Szkic dokumentu';

  @override
  String get saveChanges => 'Zapisz zmiany';

  @override
  String get editDocument => 'Edytuj dokument';

  @override
  String get generatingDraft => 'Generowanie szkicu…';

  @override
  String get generatingDraftDesc =>
      'AI przygotowuje dokument prawny na podstawie szczegółów sprawy.';

  @override
  String get failedToGenerateDraft =>
      'Nie udało się wygenerować szkicu. Spróbuj ponownie.';

  @override
  String get changesSaved => 'Zmiany zapisane';

  @override
  String get copiedToClipboard => 'Skopiowano do schowka';

  @override
  String get emailComingSoon => 'Wysyłanie emaili wkrótce';

  @override
  String get reviewBeforeSending =>
      'Sprawdź dokładnie przed wysłaniem. Ponosisz odpowiedzialność za treść dokumentu.';

  @override
  String get noContentAvailable => 'Brak dostępnej treści';

  @override
  String get save => 'Zapisz';

  @override
  String get edit => 'Edytuj';

  @override
  String get pdf => 'PDF';

  @override
  String get copy => 'Kopiuj';

  @override
  String get appealDraft => 'Szkic odwołania';

  @override
  String selected(int count) {
    return '$count wybranych';
  }

  @override
  String get deleteSelected => 'Usuń wybrane';

  @override
  String deleteDocumentsConfirm(int count) {
    return 'Usunąć $count dokumentów?';
  }

  @override
  String get delete => 'Usuń';

  @override
  String get analyzeSelected => 'Analizuj wybrane';

  @override
  String get batchAnalysisStarting => 'Rozpoczynanie analizy zbiorczej…';

  @override
  String get switchToList => 'Widok listy';

  @override
  String get switchToGrid => 'Widok siatki';

  @override
  String get scanNew => 'Nowy skan';

  @override
  String get noDocumentsYetScan => 'Brak dokumentów';

  @override
  String get scanFirstDocumentHint =>
      'Zeskanuj pierwszy dokument, aby AI przeanalizowało go pod kątem błędów.';

  @override
  String get failedToLoadDocuments => 'Nie udało się załadować dokumentów';

  @override
  String get emailIntegrationTitle => 'Integracja email';

  @override
  String get connectYourEmail => 'Połącz swój email';

  @override
  String get connectYourEmailDesc =>
      'Połącz email, aby automatycznie wykrywać i organizować korespondencję prawną.';

  @override
  String get legalEmails => 'Emaile prawne';

  @override
  String get unlinkedEmails => 'Niepowiązane emaile';

  @override
  String get noLegalEmailsYet => 'Brak emaili prawnych';

  @override
  String get legalEmailsWillAppear =>
      'Emaile sklasyfikowane jako prawne pojawią się tutaj.';

  @override
  String get assignToCase => 'Przypisz do sprawy';

  @override
  String get disconnectEmail => 'Odłącz email';

  @override
  String get disconnectEmailConfirm =>
      'Automatyczna synchronizacja email zostanie zatrzymana. Wcześniej zsynchronizowane emaile pozostaną.';

  @override
  String get gmailReauthBannerBody =>
      'Advocat v2.1 czyta Twoją skrzynkę, aby przygotowywać odpowiedzi; możesz cofnąć dostęp w dowolnym momencie. Połącz ponownie Gmail, aby włączyć proaktywne sortowanie.';

  @override
  String get gmailReauthBannerCta => 'Autoryzuj ponownie';

  @override
  String connectedTo(String email) {
    return 'Połączono z $email';
  }

  @override
  String lastSynced(String time) {
    return 'Ostatnia synchronizacja: $time';
  }

  @override
  String get filterByType => 'Filtruj według typu';

  @override
  String get noCasesMatchSearch => 'Brak spraw pasujących do wyszukiwania';

  @override
  String get failedToLoadCases => 'Nie udało się załadować spraw';

  @override
  String get monthly => 'Miesięczny';

  @override
  String get annual => 'Roczny';

  @override
  String get saveTwentyFivePercent => 'Oszczędź 25%';

  @override
  String get mostPopular => 'NAJPOPULARNIEJSZY';

  @override
  String get oneCaseActive => '1 aktywna sprawa';

  @override
  String get threeCasesActive => '3 aktywne sprawy';

  @override
  String get unlimitedCases => 'Nieograniczone sprawy';

  @override
  String get threeDocScans => '3 skany dokumentów';

  @override
  String get twentyDocScans => '20 skanów dokumentów';

  @override
  String get unlimitedDocScans => 'Nieograniczone skanowanie';

  @override
  String get basicAiAnalysis => 'Podstawowa analiza AI';

  @override
  String get fullAiAnalysis => 'Pełna analiza AI';

  @override
  String get draftGeneration => 'Generowanie szkiców';

  @override
  String get priorityProcessing => 'Przetwarzanie priorytetowe';

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
  String get forever => 'na zawsze';

  @override
  String get perMonth => '/mies.';

  @override
  String get perYear => '/rok';

  @override
  String get checkingPurchases => 'Sprawdzanie poprzednich zakupów…';

  @override
  String get noPreviousPurchases => 'Nie znaleziono poprzednich zakupów.';

  @override
  String get chatWelcomeMessage =>
      'Cześć! Jestem Advocat — Twój asystent prawny AI. Dostarczam informacje prawne, a nie porady prawne. W jakiej kwestii prawnej mogę pomóc?';

  @override
  String get copySummary => 'Kopiuj podsumowanie';

  @override
  String get caseSummaryCopied => 'Podsumowanie sprawy skopiowane';

  @override
  String get openCase => 'Otwórz sprawę';

  @override
  String get viewFull => 'Zobacz pełny';

  @override
  String get draftCopiedToClipboard => 'Szkic skopiowany do schowka';

  @override
  String get reportMileageFraud => 'Zgłoś oszustwo z przebiegiem';

  @override
  String get reportMileageFraudDesc =>
      'Zostanie utworzony raport o oszustwie na podstawie danych kontroli pojazdu.';

  @override
  String get reportAndOpenCase => 'Zgłoś i otwórz sprawę';

  @override
  String get caseCreationComingSoon =>
      'Tworzenie sprawy z wypełnionymi danymi wkrótce';

  @override
  String get failedToCreateCaseRetry =>
      'Nie udało się utworzyć sprawy. Spróbuj ponownie.';

  @override
  String get takePhotoInstead => 'Zrób zdjęcie';

  @override
  String get deleteCase => 'Usuń sprawę';

  @override
  String deleteCaseConfirm(String title) {
    return 'Czy na pewno chcesz usunąć „$title”? Tej czynności nie można cofnąć.';
  }

  @override
  String get haveQuestionsAi => 'Pytania? Zapytaj AI';

  @override
  String get cookiePolicy => 'Polityka plików cookie';

  @override
  String get aiDisclaimer => 'Zastrzeżenie dotyczące AI';

  @override
  String get aiDisclaimerCompact =>
      'Advocat to informacja prawna generowana przez AI, a nie porada prawna. Przed podjęciem działań skonsultuj się z licencjonowanym prawnikiem.';

  @override
  String get aiDisclaimerFullTitle => 'Ważne: jak działa Advocat';

  @override
  String get aiDisclaimerFullBody =>
      'Advocat to narzędzie sztucznej inteligencji, które dostarcza informacje prawne, a nie porady prawne. Zgodnie z unijnym aktem o sztucznej inteligencji (art. 50) musimy wyraźnie poinformować: rozmawiasz z AI, a nie z prawnikiem.\n\nAdvocat nie jest kancelarią prawną. Nie jesteśmy licencjonowanymi adwokatami w rozumieniu estońskiej ustawy Advokatuuriseadus ani fińskiej ustawy Asianajajalaki, a Twoje rozmowy z tym narzędziem nie są objęte tajemnicą adwokacką. Zanim oprzesz się na jakiejkolwiek odpowiedzi — aby złożyć odwołanie, podpisać umowę lub dotrzymać terminu — zweryfikuj ją u licencjonowanego prawnika w swojej jurysdykcji.';

  @override
  String get aiDisclaimerExpand => 'Dowiedz się więcej';

  @override
  String get aiDisclaimerDismiss => 'OK, rozumiem';

  @override
  String get dataPrivacyConsent => 'Zgoda na przetwarzanie danych';

  @override
  String get gdprIntro =>
      'Aby świadczyć pomoc prawną z AI, przetwarzamy Twoje dane zgodnie z RODO (UE 2016/679). Kontynuując zgadzasz się na:';

  @override
  String get gdprChat => 'Przetwarzanie wiadomości czatu przez AI';

  @override
  String get gdprDocs => 'Analiza przesłanych dokumentów';

  @override
  String get gdprStorage => 'Szyfrowane przechowywanie danych spraw';

  @override
  String get gdprDelete => 'Prawo do usunięcia danych w dowolnym momencie';

  @override
  String get gdprFooter =>
      'Twoje dane są szyfrowane i nigdy nie są udostępniane stronom trzecim. Możesz wycofać zgodę i usunąć dane w Ustawieniach.';

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
  String get decline => 'Odrzuć';

  @override
  String get iAgree => 'Zgadzam się';

  @override
  String get iAgreeToThe => 'Akceptuję ';

  @override
  String get orWord => 'lub';

  @override
  String get english => 'Angielski';

  @override
  String get russian => 'Rosyjski';

  @override
  String get finnish => 'Fiński';

  @override
  String successSubscribed(String plan) {
    return 'Subskrypcja $plan aktywowana!';
  }

  @override
  String paymentFailed(String error) {
    return 'Płatność nie powiodła się: $error';
  }

  @override
  String get whatToDo => 'Co robić';

  @override
  String get getHelp => 'Uzyskaj pomoc';

  @override
  String get share => 'Udostępnij';

  @override
  String get didYouKnow => 'Czy wiesz?';

  @override
  String get mustKnow => 'Musisz wiedzieć';

  @override
  String get goodToKnow => 'Warto wiedzieć';

  @override
  String get sentFromAdvocat => 'Wysłano z aplikacji Advocat';

  @override
  String get policeActionStayCalm => 'Zachowaj spokój i trzymaj ręce na widoku';

  @override
  String get policeActionAskWhy =>
      'Zapytaj funkcjonariusza, dlaczego zostałeś zatrzymany';

  @override
  String get policeActionProvideName => 'Podaj swoje imię i datę urodzenia';

  @override
  String get policeActionWantLawyer =>
      'Powiedz wyraźnie: „Chcę adwokata przed odpowiadaniem na pytania”';

  @override
  String get policeActionAskInterpreter => 'W razie potrzeby poproś o tłumacza';

  @override
  String get policeActionNoteBadge =>
      'Zanotuj imię i numer służbowy funkcjonariusza';

  @override
  String get policeFactMustTellReason =>
      'W Finlandii policja musi podać powód zatrzymania. Jeśli tego nie zrobi, możesz zapytać — i jest prawnie zobowiązana do wyjaśnienia.';

  @override
  String get policeFactCanRecord =>
      'W Finlandii możesz nagrywać interakcje z policją w miejscach publicznych. Jest to chronione przez wolność słowa.';

  @override
  String get contactFinnishLegalAid => 'Fińska pomoc prawna';

  @override
  String get contactNonDiscriminationOmbudsman => 'Rzecznik ds. Równości';

  @override
  String get deportationDeadlineAppeal =>
      'Odwołanie do sądu administracyjnego — zwykle 30 dni od doręczenia';

  @override
  String get deportationDeadlineLegalAid =>
      'Złóż wniosek o pomoc prawną — zrób to NATYCHMIAST';

  @override
  String get deportationFactStayDuringAppeal =>
      'W Finlandii zwykle masz prawo pozostać w kraju podczas rozpatrywania odwołania. Deportacja nie może być wykonana podczas aktywnego odwołania w większości przypadków.';

  @override
  String get contactRefugeeAdviceCentre =>
      'Fińskie Centrum Porad dla Uchodźców';

  @override
  String get contactAdminCourtHelsinki => 'Sąd Administracyjny w Helsinkach';

  @override
  String get workplaceActionKeepContract => 'Przechowuj kopie umowy o pracę';

  @override
  String get workplaceActionTrackHours =>
      'Samodzielnie rejestruj godziny pracy';

  @override
  String get workplaceActionReportUnsafe =>
      'Zgłaszaj niebezpieczne warunki do inspekcji pracy';

  @override
  String get workplaceActionJoinUnion =>
      'Wstąp do związku zawodowego dla ochrony';

  @override
  String get workplaceActionContactAuthority =>
      'W razie potrzeby skontaktuj się z Urzędem Bezpieczeństwa Pracy';

  @override
  String get workplaceFactCollectiveWage =>
      'W Finlandii układy zbiorowe ustalają płace minimalne w poszczególnych branżach — nie ma jednej krajowej płacy minimalnej. Twój pracodawca musi przestrzegać układu zbiorowego dla Twojej branży.';

  @override
  String get workplaceFactOralContract =>
      'Nawet bez pisemnej umowy masz pełne prawa pracownicze w Finlandii. Umowa ustna jest równie wiążąca prawnie.';

  @override
  String get contactOccupationalSafety => 'Urząd Bezpieczeństwa Pracy';

  @override
  String get contactTradeUnionSAK => 'Doradztwo związkowe (SAK)';

  @override
  String get tenantActionWrittenAgreement => 'Zawsze miej pisemną umowę najmu';

  @override
  String get tenantActionDocumentCondition =>
      'Udokumentuj stan mieszkania przy wprowadzeniu (zdjęcia)';

  @override
  String get tenantActionReportMaintenance =>
      'Zgłaszaj problemy z konserwacją na piśmie';

  @override
  String get tenantActionNoIllegalEviction =>
      'Nigdy nie zgadzaj się na nielegalne wyrzucenie — o eksmisji decyduje sąd';

  @override
  String get tenantActionContactAdvisory =>
      'W razie sporów skontaktuj się z poradnią dla najemców';

  @override
  String get tenantFactNoEvictionWithoutCourt =>
      'Wynajmujący w Finlandii nie może cię eksmitować bez nakazu sądowego, nawet jeśli umowa wygasła. Wymiana zamków lub odcięcie mediów jest nielegalne.';

  @override
  String get contactTenantsAssociation => 'Fiński Związek Najemców';

  @override
  String get contactConsumerDisputesBoard => 'Komisja ds. Sporów Konsumenckich';

  @override
  String get detentionActionAskDecision =>
      'Natychmiast zażądaj pisemnej decyzji o zatrzymaniu';

  @override
  String get detentionActionRequestLawyer => 'Zażądaj kontaktu z adwokatem';

  @override
  String get detentionActionContactEmbassy =>
      'Skontaktuj się z ambasadą lub konsulatem';

  @override
  String get detentionActionAskMedical =>
      'W razie potrzeby poproś o pomoc medyczną';

  @override
  String get detentionActionRequestInterpreter =>
      'Żądaj tłumacza na wszystkie rozprawy';

  @override
  String get detentionDeadlineCourtReview =>
      'Sąd rejonowy musi rozpatrzyć zatrzymanie w ciągu 4 dni';

  @override
  String get detentionDeadlineContinuation =>
      'Sąd sprawdza przedłużenie co 2 tygodnie';

  @override
  String get detentionFactCourtReview =>
      'Zatrzymanie imigracyjne w Finlandii musi być rozpatrzone przez sąd rejonowy w ciągu 4 dni. Jeśli tak się nie stanie, zatrzymanie staje się bezprawne.';

  @override
  String get contactParliamentaryOmbudsman => 'Rzecznik Praw Obywatelskich';

  @override
  String get discriminationActionWriteDown =>
      'Zapisz dokładnie, co się wydarzyło (data, godzina, miejsce)';

  @override
  String get discriminationActionSaveEvidence =>
      'Zachowaj dowody: wiadomości, e-maile, świadkowie';

  @override
  String get discriminationActionFileComplaint =>
      'Złóż skargę do Rzecznika ds. Równości';

  @override
  String get discriminationActionContactLegalAid =>
      'Skontaktuj się z biurem pomocy prawnej po bezpłatną poradę';

  @override
  String get discriminationActionReportPolice =>
      'Zgłoś na policję, jeśli doszło do gróźb lub napaści';

  @override
  String get discriminationFactNonDiscriminationAct =>
      'Fińska ustawa o zakazie dyskryminacji obejmuje dyskryminację ze względu na wiek, pochodzenie, obywatelstwo, język, religię, zdrowie, niepełnosprawność, orientację seksualną i inne cechy osobiste.';

  @override
  String get contactVictimSupportRIKU => 'Wsparcie Ofiar Finlandia (RIKU)';

  @override
  String get domesticViolence => 'Przemoc domowa';

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
  String get inheritance => 'Spadek';

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
  String get consumerProtection => 'Ochrona konsumentów';

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
  String get comingSoon => 'Wkrótce';

  @override
  String get encrypted => 'Encrypted';

  @override
  String get typing => 'Typing…';

  @override
  String get online => 'Online';

  @override
  String get chatWelcomeSubtitle =>
      'Przeanalizuję sytuację, sprawdzę dokumenty, znajdę błędy i podpowiem, co robić.';

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
      other: '$count praw w środku',
      many: '$count praw w środku',
      few: '$count prawa w środku',
      one: '1 prawo w środku',
      zero: 'brak praw w środku',
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
      'Asystent AI dostarcza informacje prawne, a nie porady prawne. Zawsze skonsultuj się z wykwalifikowanym prawnikiem.';

  @override
  String get chatDisclaimerSubtitle => 'Asystent AI · nie porada prawna';

  @override
  String get chatDisclaimerBannerFull =>
      'Advocat to asystent AI udzielający informacji prawnej, a nie prawnik. Treści tutaj nie tworzą stosunku adwokat–klient, nie są poradą prawną i mogą być błędne. W sprawie wiążącej porady prawnej skonsultuj się z licencjonowanym adwokatem w swojej jurysdykcji. Nie reprezentujemy Państwa.';

  @override
  String get chatDisclaimerFooter =>
      'Wygenerowane przez AI. Zweryfikuj u licencjonowanego adwokata.';

  @override
  String get chatDisclaimerGotIt => 'Rozumiem';

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
  String get guestUser => 'Gość';

  @override
  String get howToUse => 'Jak korzystac?';

  @override
  String get tutorialStep1Title => 'Asystent prawny AI';

  @override
  String get tutorialStep1Desc =>
      'Zadaj dowolne pytanie prawne i uzyskaj natychmiastowe odpowiedzi na podstawie prawa estonskiego.';

  @override
  String get tutorialStep2Title => 'Poznaj swoje prawa';

  @override
  String get tutorialStep2Desc =>
      'Przegladaj informacje prawne wedlug tematow — praca, mieszkanie, prawa konsumenta i wiecej.';

  @override
  String get tutorialStep3Title => 'Skanuj dokumenty';

  @override
  String get tutorialStep3Desc =>
      'Fotografuj dokumenty prawne do analizy AI i bezpiecznego przechowywania.';

  @override
  String get tutorialStep4Title => 'Zaczynamy!';

  @override
  String get tutorialStep4Desc =>
      'Odkryj aplikacje i chron swoje prawa. Wszystkie dane pozostaja prywatne na Twoim urzadzeniu.';

  @override
  String get advocatProTitle => 'Advocat Pro';

  @override
  String get advocatProSubtitle => 'Odblokuj funkcje premium';

  @override
  String get voiceDisclaimer =>
      'Asystent głosowy działa obecnie tylko na komputerze (przeglądarka Chrome). Wsparcie mobilne wkrótce.';

  @override
  String get recommended => 'Polecany';

  @override
  String get pleaseLogIn => 'Proszę się zalogować';

  @override
  String get subscriptionNotFound => 'Nie znaleziono subskrypcji';

  @override
  String errorWithMessage(String message) {
    return 'Błąd: $message';
  }

  @override
  String get redirectingToPayment => 'Przekierowanie na stronę płatności…';

  @override
  String cheaperAnnually(String amount) {
    return '€$amount/mies. taniej w subskrypcji rocznej';
  }

  @override
  String get navigatingTo => 'Otwieram';

  @override
  String get stayInChat => 'Zostań na czacie';

  @override
  String get backToChat => 'Wróć do czatu';

  @override
  String get upgradeBannerTitle =>
      'Przejdź na wyższy plan, aby uzyskać nieograniczone konsultacje';

  @override
  String get upgradeBannerCta => 'Ulepsz plan';

  @override
  String get paymentSuccessTitle => 'Płatność zakończona pomyślnie';

  @override
  String get paymentSuccessBody => 'Twoja subskrypcja jest teraz aktywna.';

  @override
  String get commonOk => 'OK';

  @override
  String get feedbackThumbsUpLabel => 'Pomocne';

  @override
  String get feedbackThumbsDownLabel => 'Niepomocne';

  @override
  String get feedbackCommentPrompt => 'Co było nie tak?';

  @override
  String get feedbackSend => 'Wyślij';

  @override
  String get feedbackCancel => 'Anuluj';

  @override
  String get reasoningPillIdle => 'Myślę…';

  @override
  String get reasoningPillSearchingLaw => 'Przeszukuję prawo estońskie…';

  @override
  String get reasoningPillSearchingWeb => 'Przeszukuję sieć…';

  @override
  String get reasoningPillCheckingCompany =>
      'Sprawdzam rejestr przedsiębiorstw…';

  @override
  String get reasoningPillCheckingVehicle => 'Sprawdzam rejestr pojazdów…';

  @override
  String get reasoningPillReadingDocument => 'Czytam Twój dokument…';

  @override
  String get reasoningPillDrafting => 'Przygotowuję dokument…';

  @override
  String get reasoningPillPreparingEmail => 'Przygotowuję e-mail…';

  @override
  String get reasoningPillFindingLawyer => 'Wyszukuję prawników…';

  @override
  String get reasoningPillThinking => 'Analizuję Twoją sprawę…';

  @override
  String get reasoningPillFinalising => 'Tworzę Twoją odpowiedź…';

  @override
  String reasoningCollapsedFormat(int sec, int sources) {
    return 'Analiza trwała $sec s · $sources źródeł';
  }

  @override
  String get reasoningExpandHint => 'dotknij, aby zobaczyć kroki';

  @override
  String get caseFileTitle => 'Akta sprawy';

  @override
  String get caseFileTimeline => 'Oś czasu';

  @override
  String get caseFileParties => 'Strony';

  @override
  String get caseFileDeadlines => 'Terminy';

  @override
  String get caseFileExportPdf => 'Pobierz akta (PDF)';

  @override
  String get caseFileEmpty =>
      'Porozmawiaj z AI o swojej sprawie — oś czasu zbuduje się sama.';

  @override
  String get caseFileDisclaimer =>
      'Te akta są automatycznie wyodrębniane z Twojej rozmowy. To nie jest porada prawna.';

  @override
  String get caseFileTabLabel => 'Sprawa';

  @override
  String get refresh => 'Odśwież';

  @override
  String get demoLimitReached =>
      'Osiągnięto limit wersji demo. Zarejestruj się bezpłatnie, aby kontynuować.';

  @override
  String get demoLimitSignUpCta => 'Zarejestruj się';

  @override
  String freeQuotaExhausted(int count) {
    return 'Wykorzystałeś(-aś) wszystkie $count bezpłatnych wiadomości w tym miesiącu.';
  }

  @override
  String get upgradeForUnlimited =>
      'Przejdź na Pro, aby uzyskać dostęp bez limitów';

  @override
  String get upgradeCta => 'Ulepsz plan';

  @override
  String get rateLimitTryAgain =>
      'Wysyłasz zbyt szybko. Spróbuj ponownie za kilka sekund.';

  @override
  String get quickProfilePrompt =>
      'Abym mógł pomóc Ci dokładniej, jaki jest Twój status prawny: jesteś obywatelem Estonii, obywatelem UE z innego kraju, czy posiadasz zezwolenie na pobyt?';

  @override
  String get quickProfileChipEstonianCitizen => 'Obywatel Estonii';

  @override
  String get quickProfileChipEuCitizen => 'Obywatel UE (inny)';

  @override
  String get quickProfileChipResidencePermit => 'Zezwolenie na pobyt';

  @override
  String get quickProfileSkipBtn => 'Pomiń';

  @override
  String get quickProfileSavedAck =>
      'Zrozumiałem. A teraz, jakie jest Twoje pytanie?';

  @override
  String get caseTitleLabel => 'Tytuł sprawy';

  @override
  String get jurisdictionLabel => 'Jurysdykcja';

  @override
  String get caseTypeLabel => 'Rodzaj sprawy';

  @override
  String get caseLanguageLabel => 'Język';

  @override
  String get caseNumbersSection => 'Numery spraw';

  @override
  String get partiesSection => 'Strony';

  @override
  String get authoritiesSection => 'Organy';

  @override
  String get timelineSection => 'Oś czasu';

  @override
  String get openQuestionsSection => 'Otwarte pytania';

  @override
  String get nextActionsSection => 'Następne działania';

  @override
  String get summarySection => 'Podsumowanie';

  @override
  String get addRow => 'Dodaj wiersz';

  @override
  String get removeRow => 'Usuń';

  @override
  String get archiveCase => 'Archiwizuj sprawę';

  @override
  String get closeCase => 'Zamknij sprawę';

  @override
  String get continueChatAboutCase => 'Kontynuuj czat o tej sprawie';

  @override
  String get linkChatToCase => 'Powiąż ze sprawą';

  @override
  String get clearActiveCase => 'Wyczyść aktywną sprawę';

  @override
  String get caseSavedAck => 'Sprawa zapisana';

  @override
  String get caseArchivedAck => 'Sprawa zarchiwizowana';

  @override
  String get intakeStep1Title => 'Gdzie toczy się sprawa?';

  @override
  String get intakeStep1Subtitle => 'Kraj i organ, z którym masz do czynienia.';

  @override
  String get intakeJurisdictionLabel => 'Kraj / jurysdykcja';

  @override
  String get intakeAuthorityLabel => 'Rodzaj organu';

  @override
  String get intakeAuthorityNameLabel => 'Nazwa organu (opcjonalnie)';

  @override
  String get intakeAuthorityPolice => 'Policja';

  @override
  String get intakeAuthorityCourt => 'Sąd';

  @override
  String get intakeAuthoritySocial => 'Pomoc społeczna';

  @override
  String get intakeAuthorityEmployer => 'Pracodawca';

  @override
  String get intakeAuthorityLandlord => 'Wynajmujący';

  @override
  String get intakeAuthorityOpposingParty => 'Strona przeciwna';

  @override
  String get intakeAuthorityOther => 'Inne';

  @override
  String get intakeStep2Title => 'Jakiego rodzaju to sprawa?';

  @override
  String get intakeStep2Subtitle =>
      'Wybierz najbliższy rodzaj — możesz go później doprecyzować.';

  @override
  String get intakeCaseTypeCriminal => 'Karna';

  @override
  String get intakeCaseTypeCivil => 'Cywilna';

  @override
  String get intakeCaseTypeFamily => 'Rodzinna';

  @override
  String get intakeCaseTypeAdmin => 'Administracyjna';

  @override
  String get intakeCaseTypeImmigration => 'Imigracyjna';

  @override
  String get intakeCaseTypeLabor => 'Pracownicza';

  @override
  String get intakeCaseTypeConsumer => 'Konsumencka';

  @override
  String get intakeCaseTypeInheritance => 'Spadkowa';

  @override
  String get intakeCaseTypeOther => 'Inna';

  @override
  String get intakeStep3Title => 'Kto jest zaangażowany?';

  @override
  String get intakeStep3Subtitle => 'Twoja rola i strona przeciwna.';

  @override
  String get intakeRoleLabel => 'Twoja rola';

  @override
  String get intakeRolePlaintiff => 'Powód';

  @override
  String get intakeRoleDefendant => 'Pozwany';

  @override
  String get intakeRoleVictim => 'Pokrzywdzony';

  @override
  String get intakeRoleAccused => 'Oskarżony';

  @override
  String get intakeRoleWitness => 'Świadek';

  @override
  String get intakeRoleFamily => 'Członek rodziny';

  @override
  String get intakeRoleOther => 'Inna';

  @override
  String get intakeOpposingSideLabel => 'Strona przeciwna (opcjonalnie)';

  @override
  String get intakeWitnessesLabel => 'Świadkowie (opcjonalnie)';

  @override
  String get intakeAddWitness => 'Dodaj świadka';

  @override
  String get intakeWitnessHint => 'Imię lub kontakt';

  @override
  String get intakeStep4Title => 'Numery i daty';

  @override
  String get intakeStep4Subtitle =>
      'Wszystko, co już masz. Pomiń to, czego nie masz.';

  @override
  String get intakeCaseNumberLabel => 'Numer sprawy (opcjonalnie)';

  @override
  String get intakeIncidentDateLabel => 'Data zdarzenia (opcjonalnie)';

  @override
  String get intakeIncidentDatePick => 'Wybierz datę';

  @override
  String get intakeDeadlinesLabel => 'Znane terminy';

  @override
  String get intakeAddDeadline => 'Dodaj termin';

  @override
  String get intakeDeadlineWhatHint => 'Co';

  @override
  String get intakeStep5Title => 'Dokumenty';

  @override
  String get intakeStep5Subtitle =>
      'Prześlij wszystko, co istotne. Przeczytamy to.';

  @override
  String get intakeUploadDocsLabel => 'Prześlij dokumenty';

  @override
  String get intakeSkipDocs => 'Pomiń — prześlę później';

  @override
  String get intakeNextBtn => 'Dalej';

  @override
  String get intakeBackBtn => 'Wstecz';

  @override
  String get intakeFinishBtn => 'Zakończ i otwórz czat';

  @override
  String get intakeUrgentBtn => 'Pilne — zapytaj teraz';

  @override
  String get intakeUrgentDialogTitle => 'Otworzyć czat teraz?';

  @override
  String get intakeUrgentDialogBody =>
      'Zapiszemy wprowadzone dane jako wersję roboczą sprawy. Kreator możesz dokończyć ze strony sprawy w dowolnym momencie.';

  @override
  String get intakeUrgentConfirm => 'Otwórz czat';

  @override
  String get intakeUrgentCancel => 'Wypełniaj dalej';

  @override
  String get intakePreparingCase => 'Przygotowuję Twoją sprawę…';

  @override
  String get intakeFallbackGreeting =>
      'Widzę Twoją sprawę. Powiedz mi, co jest najpilniejsze — przeanalizuję to razem z Tobą.';

  @override
  String get intakeUrgentGreeting =>
      'Widzę, że to pilne. Zadaj pytanie — resztę uzupełnię w trakcie.';

  @override
  String intakeStepIndicator(int current, int total) {
    return 'Krok $current z $total';
  }

  @override
  String get intakeFieldRequired => 'Wymagane';

  @override
  String intakeUploadProgress(int done, int total) {
    return 'Przesyłanie $done / $total…';
  }

  @override
  String get uplDisclaimerFooter =>
      'Advocat nie jest kancelarią prawną. To informacja, a nie porada prawna.';

  @override
  String get citationStatusVerifiedBadge => 'Zweryfikowano';

  @override
  String get citationStatusUnverifiedBadge => 'Niezweryfikowane';

  @override
  String get citationStatusHistoricalBadge => 'Wersja historyczna';

  @override
  String get citationStatusVerifiedTooltip =>
      'Zacytowano z odzyskanego źródła prawnego.';

  @override
  String get citationStatusUnverifiedTooltip =>
      'SI zacytowała ten fragment bez odzyskania źródła — należy zweryfikować przed wykorzystaniem.';

  @override
  String get citationStatusHistoricalTooltip =>
      'Zacytowany przepis nie obowiązuje już w obecnym brzmieniu.';

  @override
  String get citationOpenInRiigiTeataja => 'Otwórz w Riigi Teataja';

  @override
  String get citationSnippetExpand => 'Pokaż pełny tekst';

  @override
  String get citationSnippetCollapse => 'Pokaż mniej';

  @override
  String get citationUnverifiedSheetNote =>
      'SI zacytowała ten paragraf, lecz nie został on odzyskany z korpusu prawnego w tej rozmowie. Zweryfikuj odniesienie przed jego wykorzystaniem.';

  @override
  String get citationFooterNoneWarning => 'Brak udokumentowanych cytatów';

  @override
  String citationFooterSummaryTotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cytatów',
      many: '$count cytatów',
      few: '$count cytaty',
      one: '1 cytat',
    );
    return '$_temp0';
  }

  @override
  String citationFooterSummaryVerified(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zweryfikowanych',
      many: '$count zweryfikowanych',
      few: '$count zweryfikowane',
      one: '1 zweryfikowany',
    );
    return '$_temp0';
  }

  @override
  String citationFooterSummaryUnverified(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count niezweryfikowanych',
      many: '$count niezweryfikowanych',
      few: '$count niezweryfikowane',
      one: '1 niezweryfikowany',
    );
    return '$_temp0';
  }

  @override
  String citationFooterSummaryHistorical(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count historycznych',
      many: '$count historycznych',
      few: '$count historyczne',
      one: '1 historyczny',
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
      other: 'za $count dni',
      many: 'za $count dni',
      few: 'za $count dni',
      one: 'za 1 dzień',
      zero: 'dzisiaj',
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
      other: '$count dni po terminie',
      many: '$count dni po terminie',
      few: '$count dni po terminie',
      one: '1 dzień po terminie',
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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count działania równoległe',
      many: '$count działań równoległych',
      few: '$count działania równoległe',
      one: '1 działanie równoległe',
    );
    return 'Konsylium zaleca $_temp0';
  }

  @override
  String get parallelActionsApproveAll => 'Zatwierdź wszystkie i wyślij';

  @override
  String parallelActionsApproveSelected(int count, int total) {
    return 'Zatwierdź $count z $total';
  }

  @override
  String parallelActionsConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count e-maila',
      many: '$count e-maili',
      few: '$count e-maile',
      one: '1 e-mail',
    );
    return 'Wysłać $_temp0?';
  }

  @override
  String parallelActionsConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count przygotowane odpowiedzi',
      many: '$count przygotowanych odpowiedzi',
      few: '$count przygotowane odpowiedzi',
      one: '1 przygotowaną odpowiedź',
    );
    return 'Advocat wyśle $_temp0 przez połączony Gmail. Każda jest wysyłana niezależnie — jeśli jedna się nie powiedzie, pozostałe i tak zostaną wysłane.';
  }

  @override
  String parallelActionsSentToast(int count) {
    return 'Wysłano: $count.';
  }

  @override
  String parallelActionsPartialFailureToast(int sent, int failed) {
    return 'Wysłano: $sent, nieudane: $failed.';
  }

  @override
  String get parallelActionsKindReply => 'odpowiedź';

  @override
  String get parallelActionsKindNew => 'nowy';

  @override
  String get parallelActionsCheckboxSelected => 'Działanie wybrane';

  @override
  String get parallelActionsCheckboxUnselected => 'Działanie niewybrane';

  @override
  String parallelActionsCitationCount(int count) {
    return '$count cyt.';
  }

  @override
  String parallelActionsRetryFailed(int count) {
    return 'Ponów nieudane ($count)';
  }

  @override
  String get agentApprovalNeedsReviewTitle =>
      'Advocat potrzebuje Twojego zatwierdzenia';

  @override
  String get agentApprovalResolvedTitle => 'Działanie rozstrzygnięte';

  @override
  String get agentApprovalStepsLabel => 'kroki';

  @override
  String get agentApprovalApproveButton => 'Zatwierdź i wyślij';

  @override
  String get agentApprovalDeclineButton => 'Odrzuć';

  @override
  String get agentApprovalAttachmentsLabel => 'Załączniki';

  @override
  String get agentApprovalSentSummary => 'Wysłano w Twoim imieniu.';

  @override
  String get agentApprovalDeclinedSummary => 'Odrzucono — nic nie wysłano.';

  @override
  String get agentToolDraftEmailAtt => 'Wyślij e-mail z załącznikami';

  @override
  String get agentToolSendEmail => 'Wyślij e-mail';

  @override
  String get agentToolGeneratePdf => 'Wygeneruj PDF';

  @override
  String get agentToolApproveSend => 'Wyślij przygotowaną odpowiedź';

  @override
  String get inboxErrorTitle => 'Nie można załadować skrzynki odbiorczej';

  @override
  String get inboxEditDiscardTitle => 'Odrzucić niezapisane zmiany?';

  @override
  String get inboxEditDiscardBody =>
      'Masz niezapisane zmiany w tej wersji roboczej. Powrót spowoduje ich odrzucenie.';

  @override
  String get inboxEditKeepEditing => 'Kontynuuj edycję';

  @override
  String get inboxEditDiscard => 'Odrzuć';

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
  String get plannerSettingsTitle => 'Trzyetapowe rozumowanie prawne';

  @override
  String get plannerSettingsSubtitle =>
      'Plan → odpowiedź → krytyka. Wolniej, ale dokładniej.';

  @override
  String get plannerSettingsProBadge => 'Pro';

  @override
  String get plannerSettingsProDescription => 'Dostępne w planie Pro';

  @override
  String get plannerTrailHeaderPlan => 'Plan';

  @override
  String get plannerTrailHeaderCritique => 'Krytyka';

  @override
  String get plannerTrailSubQuestions => 'Podpytania';

  @override
  String get plannerTrailCounterArgs => 'Kontrargumenty';

  @override
  String get plannerTrailEvidenceGaps => 'Braki dowodowe';

  @override
  String get plannerTrailMaterialGapTrue => 'Wykryto istotny brak';

  @override
  String get plannerTrailRegeneratedBadge => 'Wygenerowano ponownie raz';

  @override
  String get plannerTrailEmpty => 'brak pozycji';

  @override
  String get supportTitle => 'Pomoc';

  @override
  String get supportSubtitle => 'Zwykle odpowiadamy w ciągu 1-2 godzin.';

  @override
  String get supportSearchPlaceholder => 'Szukaj w pomocy…';

  @override
  String get supportStatusAllOk => 'Wszystkie systemy działają prawidłowo';

  @override
  String get supportFaqWhatIs => 'Czym jest Advocat?';

  @override
  String get supportFaqHowSubscribe => 'Jak wykupić plan Pro?';

  @override
  String get supportFaqExportData => 'Czy mogę wyeksportować moje dane?';

  @override
  String get supportFaqCancelAccount => 'Anulowanie lub usunięcie konta';

  @override
  String get supportFaqTalkHuman => 'Porozmawiaj z człowiekiem';

  @override
  String get supportContactEmail => 'E-mail';

  @override
  String get supportContactTelegram => 'Telegram';

  @override
  String get supportContactWhatsapp => 'WhatsApp';

  @override
  String get supportFooterSla => 'Odpowiadamy w ciągu 24 godz.';

  @override
  String get supportWhatsapp => 'WhatsApp';

  @override
  String get supportEmail => 'E-mail';

  @override
  String get supportInApp => 'Napisz do nas tutaj';

  @override
  String get supportCategoryLabel => 'Kategoria';

  @override
  String get supportCategoryBug => 'Błąd';

  @override
  String get supportCategoryPayment => 'Problem z płatnością';

  @override
  String get supportCategoryQuestion => 'Pytanie';

  @override
  String get supportCategoryFeature => 'Propozycja funkcji';

  @override
  String get supportCategoryOther => 'Inne';

  @override
  String get supportMessagePlaceholder => 'Opisz swój problem...';

  @override
  String get supportEmailLabel => 'E-mail (opcjonalnie)';

  @override
  String get supportSend => 'Wyślij';

  @override
  String get supportSentSuccess => 'Wiadomość wysłana! Odpowiemy wkrótce.';

  @override
  String get supportError => 'Coś poszło nie tak. Spróbuj ponownie.';

  @override
  String get supportErrorTooShort => 'Wpisz co najmniej 10 znaków.';

  @override
  String get supportErrorTooLong => 'Maksymalnie 2000 znaków.';

  @override
  String get supportPrivacyNotice =>
      'Twoja wiadomość jest przechowywana bezpiecznie.';

  @override
  String get reviewThisContract => 'Przeanalizuj umowę';

  @override
  String get contractReviews => 'Przeglądy umów';

  @override
  String get contractReviewsFreeFeature =>
      '1 przegląd umowy (jednorazowo, bezpłatnie)';

  @override
  String get contractReviewsCounselFeature => '5 przeglądów umów miesięcznie';

  @override
  String get contractReviewsProFeature => '20 przeglądów umów miesięcznie';

  @override
  String contractReviewsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pozostało $count przeglądów umów w tym miesiącu',
      many: 'Pozostało $count przeglądów umów w tym miesiącu',
      few: 'Pozostały $count przeglądy umów w tym miesiącu',
      one: 'Pozostał 1 przegląd umów w tym miesiącu',
      zero: 'Brak przeglądów umów w tym miesiącu',
    );
    return '$_temp0';
  }

  @override
  String get contractReviewsExhausted =>
      'Brak pozostałych przeglądów umów w tym miesiącu';

  @override
  String get contractReviewsFreeTrialLeft =>
      'Bezpłatna wersja próbna: 1 przegląd umowy';

  @override
  String get contractReviewsFreeTrialUsed =>
      'Wersja próbna wykorzystana — ulepsz plan';

  @override
  String get contractReviewsUpgradeTitle => 'Przeglądy umów wyczerpane';

  @override
  String get contractReviewsUpgradeBodyFree =>
      'Wykorzystałeś(-aś) bezpłatny przegląd umowy. Ulepsz plan, aby otrzymywać miesięczne przeglądy.';

  @override
  String contractReviewsUpgradeBodyPaid(int used, int cap) {
    return 'Wykorzystałeś(-aś) $used z $cap przeglądów w tym miesiącu. Ulepsz plan, aby uzyskać wyższy miesięczny limit.';
  }

  @override
  String get contractReviewsUpgradeCounselCta =>
      'Przejdź na Counsel (€19,99/mies.) — 5 przeglądów';

  @override
  String get contractReviewsUpgradeProCta =>
      'Przejdź na Pro (€29,99/mies.) — 20 przeglądów';

  @override
  String get contractReviewsUpgradeToProShort => 'Przejdź na Pro — 20/mies.';

  @override
  String get notNow => 'Nie teraz';

  @override
  String get referralTitle => 'Zaproś znajomych';

  @override
  String get referralSubtitle =>
      'Otrzymaj darmowy miesiąc. Daj darmowy miesiąc.';

  @override
  String get referralYourLink => 'TWÓJ LINK';

  @override
  String get referralCopyLink => 'Kopiuj link';

  @override
  String get referralShare => 'Udostępnij';

  @override
  String get referralLinkCopied => 'Link skopiowany';

  @override
  String get referralStatsInvited => 'Zaproszeni';

  @override
  String get referralStatsConverted => 'Dołączyli';

  @override
  String get referralStatsEarned => 'Darmowe miesiące';

  @override
  String get referralShareWhatsApp => 'Udostępnij na WhatsApp';

  @override
  String get referralShareTelegram => 'Udostępnij na Telegram';

  @override
  String get referralShareEmail => 'Udostępnij e-mailem';

  @override
  String get referralEmailSubject =>
      'Wypróbuj Advocat — twój asystent prawny AI';

  @override
  String get referralLoadError =>
      'Nie udało się załadować danych. Pociągnij w dół, by odświeżyć.';

  @override
  String get referralRetry => 'Spróbuj ponownie';

  @override
  String get referralSettingsTile => 'Zaproś znajomych';

  @override
  String get referralAfterReviewCta =>
      'Spodobało się? Zaproś znajomego — obaj dostaniecie darmowy miesiąc.';

  @override
  String get referralAntiFraud => 'Maksymalnie 12 udanych poleceń rocznie.';

  @override
  String get referralEmpty =>
      'Brak poleceń. Wyślij swój link, aby zacząć zarabiać.';

  @override
  String get referralRecentActivity => 'Ostatnia aktywność';

  @override
  String referralActivityInvited(String when) {
    return 'Zaproszono $when';
  }

  @override
  String referralActivityActivated(String when) {
    return 'aktywowano $when';
  }

  @override
  String get referralActivityPending => 'jeszcze nieaktywowane';

  @override
  String referralStatsInvitedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count znajomych',
      many: '$count znajomych',
      few: '$count znajomych',
      one: '1 znajomy',
      zero: 'jeszcze nikogo',
    );
    return 'Zaproszono: $_temp0';
  }

  @override
  String referralStatsConvertedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aktywowało',
      many: '$count aktywowało',
      few: '$count aktywowało',
      one: '1 aktywował',
      zero: 'nikt jeszcze nie aktywował',
    );
    return '$_temp0';
  }

  @override
  String referralStatsEarnedCount(int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months darmowego miesiąca',
      many: '$months darmowych miesięcy',
      few: '$months darmowe miesiące',
      one: '1 darmowy miesiąc',
      zero: 'jeszcze nic',
    );
    return 'Twój bonus: $_temp0';
  }

  @override
  String get referralNudgeMessage =>
      'Podoba Ci się Advocat? Zaproś znajomego — oboje otrzymacie darmowy miesiąc.';

  @override
  String get referralNudgeAction => 'Zaproś';

  @override
  String get referralLandingTitle => 'Otrzymałeś(-aś) zaproszenie do Advocat';

  @override
  String referralLandingSubtitle(String inviterName) {
    return '$inviterName zaprosił(a) Cię — odbierz swój darmowy pierwszy miesiąc.';
  }

  @override
  String get referralLandingSubtitleGeneric =>
      'Odbierz swój darmowy pierwszy miesiąc Advocat Pro.';

  @override
  String get referralLandingCta => 'Aktywuj darmowy miesiąc i zarejestruj się';

  @override
  String get referralLandingCtaSecondary => 'Lub dowiedz się więcej o Advocat';

  @override
  String get referralLandingFallback =>
      'Ten link wygasł — ale nadal możesz wypróbować Advocat za darmo.';

  @override
  String get referralLandingBenefits =>
      '17 języków • Prawdziwe prawo estońskie, fińskie i UE • 24/7 — bez czekania';

  @override
  String get checkerProTagline => 'Profesjonalne narzędzia weryfikacji';

  @override
  String get checkerDataSource => 'Dane z oficjalnych rejestrów';

  @override
  String get companyCheckerHint => 'Nazwa firmy lub numer rejestru';

  @override
  String get companyCheckerPriceChip => '€2.99 za sprawdzenie  •  W planie Pro';

  @override
  String get companyCheckerEmptyState =>
      'Wprowadź nazwę firmy lub numer\nrejestru, aby uzyskać pełny raport';

  @override
  String get aiMemoryTitle => 'Pamięć AI';

  @override
  String get aiMemorySubtitle =>
      'Przejrzyj i usuń to, co AI zapamiętało o Tobie';

  @override
  String get bookLawyerCallTitle => 'Zarezerwuj rozmowę z prawnikiem';

  @override
  String get bookLawyerCallComingSoonTitle =>
      'Rozmowy z prawnikiem — wkrótce dostępne';

  @override
  String get bookLawyerCallComingSoonBody =>
      'Pro i Premium obejmują 15-minutowe rozmowy z prawnikiem partnerskim (1/kwartał w Pro, 2/kwartał w Premium). Finalizujemy sieć estońskich prawników indywidualnych i wyślemy e-mail, gdy rezerwacje będą dostępne.';

  @override
  String bookLawyerCallQuotaAvailable(int remaining, int total) {
    return 'Pozostało Ci $remaining z $total rozmów w tym kwartale.';
  }

  @override
  String get bookLawyerCallQuotaExhausted => 'Limit kwartalny wykorzystany.';

  @override
  String get bookLawyerCallQuotaBodyAvailable =>
      'Plan Pro obejmuje 1 rozmowę/kwartał, Premium 2. Rozmowy trwają 15 minut, przez Google Meet.';

  @override
  String get bookLawyerCallQuotaBodyExhausted =>
      'Twój limit zostanie zresetowany pierwszego dnia następnego kwartału. Potrzebujesz rozmowy wcześniej? Przejdź na Premium, aby uzyskać dodatkową rozmowę.';

  @override
  String get severityCritical => 'KRYTYCZNY';

  @override
  String get severityHigh => 'WYSOKI';

  @override
  String get severityMedium => 'ŚREDNI';

  @override
  String get severityLow => 'NISKI';

  @override
  String get deadlineRequiredFields => 'Tytuł i data terminu są wymagane';

  @override
  String get acceptTermsRequired => 'Zaakceptuj Warunki korzystania z usługi';

  @override
  String get chatLegalCouncilTooltip => 'Konsylium prawne (4 ekspertów)';

  @override
  String get attachFileTooltip => 'Załącz plik';

  @override
  String get sendMessage => 'Wyślij wiadomość';

  @override
  String get stopGenerating => 'Zatrzymaj generowanie';

  @override
  String get showPassword => 'Pokaż hasło';

  @override
  String get hidePassword => 'Ukryj hasło';

  @override
  String get decreaseDependents => 'Zmniejsz';

  @override
  String get increaseDependents => 'Zwiększ';

  @override
  String get sensitiveConsentTitle => 'Zgoda na dane wrażliwe';

  @override
  String get sensitiveConsentBody =>
      'Dokumenty, które zamierzasz przesłać, mogą zawierać dane osobowe szczególnej kategorii zgodnie z art. 9 RODO — takie jak dokumentacja medyczna, dane o karalności, dane biometryczne lub informacje o pochodzeniu rasowym, wyznaniu czy orientacji seksualnej.\n\nPrzetwarzamy te dane wyłącznie w celu świadczenia Ci pomocy prawnej z użyciem AI, przechowujemy je zaszyfrowane na Twoim prywatnym koncie i nigdy nie używamy ich do trenowania modeli. W każdej chwili możesz cofnąć zgodę i usunąć dane w Ustawieniach.\n\nAkceptując, wyrażasz wyraźną zgodę zgodnie z art. 9 ust. 2 lit. a) RODO na przetwarzanie danych szczególnej kategorii w tym celu.';

  @override
  String get sensitiveConsentExplicitCheckbox =>
      'Wyrażam wyraźną zgodę na przetwarzanie danych szczególnej kategorii (art. 9 ust. 2 lit. a) RODO).';

  @override
  String get sensitiveConsentRightToShareCheckbox =>
      'Potwierdzam, że mam prawo udostępnić te dane (dane są moje lub mam podstawę prawną do udostępnienia danych osób trzecich).';

  @override
  String get sensitiveConsentViewCategories =>
      'Zobacz, co uznaje się za wrażliwe →';

  @override
  String get sensitiveConsentWithdrawAction => 'Cofnij zgodę na dane wrażliwe';

  @override
  String get privacyAndData => 'PRYWATNOŚĆ I DANE';

  @override
  String get exportMyDataSubtitle =>
      'Pobierz kopię wszystkich swoich danych osobowych (art. 15 RODO).';

  @override
  String get withdrawSensitiveConsent => 'Zgoda na dane wrażliwe';

  @override
  String get withdrawSensitiveConsentSubtitle =>
      'Zarządzaj lub cofnij zgodę na przetwarzanie danych szczególnej kategorii (art. 9 ust. 2 lit. a) RODO).';

  @override
  String get dataProcessingAgreement =>
      'Umowa powierzenia przetwarzania danych';

  @override
  String get exportingData => 'Eksportowanie Twoich danych…';

  @override
  String get exportComplete =>
      'Eksport danych gotowy — zapisano na Twoim urządzeniu.';

  @override
  String get exportFailed =>
      'Eksport nie powiódł się. Spróbuj ponownie lub skontaktuj się z pomocą techniczną.';

  @override
  String get quotaExhaustedTitle => 'Osiągnięto limit bezpłatnych wiadomości';

  @override
  String quotaExhaustedBody(int count) {
    return 'Wykorzystałeś(-aś) wszystkie $count bezpłatnych wiadomości. Przejdź na Advocat Counsel za 19,99 €/miesiąc i uzyskaj nieograniczone konsultacje prawne z AI.';
  }

  @override
  String get quotaExhaustedLater => 'Później';

  @override
  String get quotaExhaustedUpgrade => 'Advocat Counsel — 19,99 €/mies.';

  @override
  String quotaCtaMessage(int count) {
    return 'Wykorzystałeś(-aś) wszystkie $count bezpłatnych wiadomości. Przejdź na Advocat Counsel za 19,99 €/miesiąc.';
  }

  @override
  String get quotaCtaButton => 'Wybierz Advocat Counsel — 19,99 €/mies.';

  @override
  String get aiErrorQuota =>
      'Osiągnięto limit bezpłatnych wiadomości. Subskrybuj, aby nadal korzystać z AI.';

  @override
  String get aiErrorAuth =>
      'Aby korzystać z AI, wymagane jest zalogowanie. Zarejestruj się lub zaloguj.';

  @override
  String get aiErrorGeneric =>
      'Tymczasowy błąd AI. Spróbuj ponownie za chwilę. Jeśli problem się utrzymuje, skontaktuj się z pomocą techniczną.';

  @override
  String get tooltipShareCase => 'Udostępnij podsumowanie sprawy';

  @override
  String get tooltipMuteVoice => 'Wycisz głos';

  @override
  String get tooltipUnmuteVoice => 'Włącz głos';

  @override
  String get tooltipAttachDoc => 'Dołącz dokument';

  @override
  String get aiTypingHint => 'AI…';

  @override
  String get error404Title => 'Nie znaleziono strony';

  @override
  String error404Body(String path) {
    return 'Nie mogliśmy znaleźć: $path';
  }

  @override
  String get goToHome => 'Przejdź do strony głównej';

  @override
  String get emailAlreadyRegistered =>
      'Ten e-mail jest już zarejestrowany. Chcesz się zalogować?';

  @override
  String get actionSignIn => 'Zaloguj się';

  @override
  String get actionUndo => 'Cofnij';

  @override
  String get intakeUrgentOpened =>
      'Czat otwarty — Twoja wersja robocza jest zapisana.';

  @override
  String get panicCoachmark =>
      'Przytrzymaj, aby uzyskać pomoc w nagłym wypadku.';

  @override
  String get panicTitle => 'Czego potrzebujesz w tej chwili?';

  @override
  String get panicCardReadAloud => 'Przeczytaj na głos funkcjonariuszowi';

  @override
  String get panicCardRecord => 'Nagraj tę rozmowę';

  @override
  String get panicCardCall => 'Zadzwoń do prawnika';

  @override
  String get panicCardAi => 'Porozmawiaj teraz z Advocat';

  @override
  String get panicClose => 'Zamknij';

  @override
  String get panicBadgeV2 => 'V2';

  @override
  String get panicRecordV1Title => 'Wkrótce w V2';

  @override
  String get panicRecordV1Body =>
      'Funkcja nagrywania jest obecnie walidowana prawnie dla Estonii i pojawi się w V2. Na razie użyj wbudowanego dyktafonu w telefonie.';

  @override
  String get panicCallFallbackBody =>
      'Napisz na kiire@advocat.ee z krótkim opisem, a oddzwonimy.';

  @override
  String get consiliumHeader => 'Konsylium prawników';

  @override
  String consiliumProgress(int count, int total) {
    return '$count z $total gotowych';
  }

  @override
  String get consiliumStarting => 'Prawnicy analizują Twoją sprawę…';

  @override
  String get consiliumDisagreement => 'Eksperci są podzieleni';

  @override
  String get consiliumSynthesizing => 'Tworzenie rekomendacji…';

  @override
  String consiliumDone(int totalRoles) {
    return 'Konsylium zakończone · $totalRoles ekspertów';
  }

  @override
  String get consiliumPositionPush => 'Zaskarż';

  @override
  String get consiliumPositionSettle => 'Ugodnij';

  @override
  String get consiliumPositionInvestigate => 'Zbadaj';

  @override
  String get consiliumPositionOutOfScope => 'Poza zakresem';

  @override
  String get consiliumConfidence => 'Pewność';

  @override
  String get consiliumKeyCitation => 'Kluczowe odniesienie';

  @override
  String get consiliumAdversarialRound => 'Runda kontradyktoryjna';

  @override
  String get consiliumViewFullOpinion => 'Zobacz pełną opinię';

  @override
  String consiliumExpertsAgreed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ekspertów zgadza się',
      many: '$count ekspertów zgadza się',
      few: '$count ekspertów zgadza się',
      one: '1 ekspert zgadza się',
    );
    return '$_temp0';
  }

  @override
  String consiliumExpertsDisagree(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ekspertów nie zgadza się',
      many: '$count ekspertów nie zgadza się',
      few: '$count ekspertów nie zgadza się',
      one: '1 ekspert nie zgadza się',
    );
    return '$_temp0';
  }

  @override
  String get consiliumDisclaimer =>
      'Agenci SI, nie ludzie-prawnicy. Istotne decyzje skonsultuj z wpisanym na listę adwokatem lub radcą prawnym.';

  @override
  String get softCaseShellBanner =>
      'Utworzyliśmy „Sprawę bez tytułu”, aby ją śledzić. Dotknij, aby zmienić nazwę.';

  @override
  String get softCaseShellBannerCta => 'Zmień nazwę';

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
  String get chatExamplePrompt1 => 'Pomóż mi odpowiedzieć na mandat';

  @override
  String get chatExamplePrompt2 => 'Sprawdź moją umowę najmu';

  @override
  String get chatExamplePrompt3 => 'Jakie mam prawa w pracy?';

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
  String get contractReviewTitle => 'Analiza umowy';

  @override
  String get contractReviewUploadCta => 'Prześlij umowę';

  @override
  String get contractReviewQuotaRemaining =>
      'Prześlij umowę w formacie PDF, DOC, DOCX lub TXT, aby otrzymać analizę AI z sygnałami ostrzegawczymi i wskazówkami negocjacyjnymi.';

  @override
  String get contractReviewRedFlags => 'Sygnały ostrzegawcze';

  @override
  String get contractReviewReviewPoints => 'Punkty do weryfikacji';

  @override
  String get contractReviewNegotiationTips => 'Wskazówki negocjacyjne';

  @override
  String get contractReviewSaveToVault => 'Zapisz w Sejfie';

  @override
  String get contractReviewContinueChat => 'Kontynuuj na czacie';

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
  String get iapPayWithApple => 'Zapłać przez Apple';

  @override
  String get iapRestorePurchases => 'Przywróć zakupy';

  @override
  String get iapPurchaseFailed =>
      'Zakup nie powiódł się. Spróbuj ponownie lub skontaktuj się z pomocą.';

  @override
  String get iapRestoreSuccess => 'Twoja subskrypcja została przywrócona.';

  @override
  String get iapRestoreNoActive =>
      'Nie znaleziono aktywnej subskrypcji do przywrócenia.';

  @override
  String get deadlineEuRadarTitle => 'EU deadline radar (preview)';

  @override
  String get deadlineEuRadarSubtitle =>
      'Hypothetical EU procedural deadlines — mock data';

  @override
  String get changePassword => 'Zmień hasło';

  @override
  String get changePasswordSubtitle => 'Zaktualizuj hasło swojego konta';

  @override
  String get newPasswordTitle => 'Ustaw nowe hasło';

  @override
  String get newPasswordHint =>
      'Wprowadź i potwierdź nowe hasło do swojego konta.';

  @override
  String get newPasswordSave => 'Zapisz nowe hasło';

  @override
  String get newPasswordSuccess =>
      'Hasło zostało zaktualizowane. Możesz teraz zalogować się nowym hasłem.';

  @override
  String get newPasswordError =>
      'Nie udało się zaktualizować hasła. Spróbuj ponownie.';

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
}
