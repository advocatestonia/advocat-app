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
  String get appearance => 'Wygląd';

  @override
  String get appearanceSystem => 'System (automatycznie)';

  @override
  String get appearanceLight => 'Jasny';

  @override
  String get appearanceDark => 'Ciemny';

  @override
  String get appearanceDescription => 'Wybierz wygląd aplikacji Advocat';

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
      'Mów do mikrofonu. Upewnij się, że dostęp do mikrofonu jest włączony.';

  @override
  String get aiErrorRateLimit =>
      'Usługa jest tymczasowo przeciążona. Spróbuj ponownie za 1-2 minuty.';

  @override
  String get aiErrorOverload =>
      'AI jest teraz zajęte, spróbuj ponownie za chwilę.';

  @override
  String freeLimitReached(int count) {
    return 'Wykorzystałeś wszystkie $count bezpłatnych wiadomości AI. Przejdź na plan Counsel, aby korzystać z nielimitowanej pomocy AI!';
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
  String get rateAppComingSoon => 'Wkrótce w sklepach z aplikacjami!';

  @override
  String get dataCopiedToClipboard => 'Dane skopiowane do schowka';

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
  String get fiveAiMessagesTotal => '5 wiadomości AI (łącznie)';

  @override
  String get hundredAiMessagesDay => '100 wiadomości AI/dzień';

  @override
  String get unlimitedAiMessages => 'Nielimitowane wiadomości AI';

  @override
  String get voiceInput => 'Wprowadzanie głosowe';

  @override
  String get strategyRecommendations => 'Rekomendacje strategiczne';

  @override
  String get foundingMemberNote =>
      'Członek założyciel: 9,99 €/mies. przez pierwsze 3 miesiące';

  @override
  String get saveTwentyPercent => 'Oszczędź 20%';

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
      'Wyrażam zgodę na przetwarzanie moich danych w celu świadczenia pomocy prawnej AI (wymagane)';

  @override
  String get gdprConsentAnalytics =>
      'Wyrażam zgodę na analitykę w celu ulepszenia usługi (opcjonalnie)';

  @override
  String get gdprArt9Intro =>
      'Ta aplikacja przetwarza szczególne kategorie danych osobowych na podstawie art. 9 RODO, w tym:';

  @override
  String get gdprSpecialLegalCases =>
      'Szczegóły Twojej sprawy prawnej i dokumenty sądowe';

  @override
  String get gdprSpecialNationality => 'Narodowość i status imigracyjny';

  @override
  String get gdprConsentLegalData =>
      'Wyrażam zgodę na przetwarzanie danych mojej sprawy prawnej, narodowości i statusu imigracyjnego przez AI (wymagane)';

  @override
  String get gdprConsentVoice =>
      'Wyrażam zgodę na przetwarzanie nagrań głosowych (opcjonalnie)';

  @override
  String get gdprViewPrivacyPolicy => 'Zobacz Politykę prywatności';

  @override
  String get legalInformation => 'Informacje prawne';

  @override
  String get legalEntityName => 'Vorantis OÜ';

  @override
  String get legalRegistryCode => 'Numer rejestrowy: 17098992';

  @override
  String get legalAddress =>
      'Harju maakond, Tallinn, Kesklinna linnaosa, Tornimäe tn 5, 10145';

  @override
  String get legalEmail => 'E-mail: support@advocat.ee';

  @override
  String get legalRegistry =>
      'Zarejestrowana w estońskim Rejestrze Handlowym (Äriregister)';

  @override
  String get aiGeneratedDisclaimer =>
      'Wygenerowane przez AI • To nie jest porada prawna';

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
      'Prawa ofiar, pomoc doraźna, zakazy zbliżania się';

  @override
  String get rightCallEmergency =>
      'Masz prawo zadzwonić pod numer 112 w każdej sytuacji zagrożenia — policja, pogotowie, straż pożarna';

  @override
  String get rightVictimProtection =>
      'Jako ofiara masz prawo do ochrony, wsparcia i informacji o swojej sprawie';

  @override
  String get rightRestrainingOrder =>
      'Możesz wystąpić o zakaz zbliżania się (lähestymiskielto), aby trzymać sprawcę z dala';

  @override
  String get rightVictimInterpreter =>
      'Masz prawo do tłumacza we wszystkich postępowaniach prawnych';

  @override
  String get rightMedicalHelp =>
      'Masz prawo do natychmiastowej pomocy medycznej i udokumentowania obrażeń';

  @override
  String get rightShelter =>
      'Masz prawo do schronienia awaryjnego — skontaktuj się ze schroniskiem lub pomocą społeczną';

  @override
  String get mustReportDanger =>
      'Jeśli ktoś jest w bezpośrednim niebezpieczeństwie, natychmiast zadzwoń pod numer 112';

  @override
  String get mustDocumentInjuries =>
      'Udokumentuj wszystkie obrażenia — zdjęcia, dokumentacja medyczna, pisemne notatki';

  @override
  String get domesticActionCallEmergency =>
      'Zadzwoń pod numer 112, jeśli jesteś w bezpośrednim niebezpieczeństwie';

  @override
  String get domesticActionGoToSafe =>
      'Udaj się w bezpieczne miejsce — schronisko, do znajomych, w miejsce publiczne';

  @override
  String get domesticActionDocumentEverything =>
      'Udokumentuj obrażenia: zrób zdjęcia, uzyskaj dokumentację medyczną';

  @override
  String get domesticActionFilePoliceReport =>
      'Złóż zawiadomienie na policji — możesz to zrobić też później';

  @override
  String get domesticActionContactShelter =>
      'Skontaktuj się ze schroniskiem lub telefonem zaufania';

  @override
  String get domesticActionApplyRestraining =>
      'Wystąp o zakaz zbliżania się przez policję lub sąd';

  @override
  String get domesticFactRestrainingOrder =>
      'W Finlandii zakaz zbliżania się (lähestymiskielto) może zostać wydany nawet bez sprawy karnej. Zakazuje on danej osobie kontaktowania się z Tobą lub zbliżania się do Ciebie.';

  @override
  String get domesticFactVictimDirective =>
      'Na mocy unijnej Dyrektywy o prawach ofiar 2012/29/UE masz prawo do traktowania z szacunkiem, otrzymywania informacji w zrozumiałym dla Ciebie języku oraz dostępu do usług wsparcia dla ofiar — niezależnie od Twojego statusu pobytowego.';

  @override
  String get domesticDeadlinePoliceReport =>
      'Zgłoszenie na policję — brak ścisłego terminu, ale im szybciej, tym lepiej dla dowodów';

  @override
  String get domesticDeadlineRestraining =>
      'Zakaz zbliżania się — można wystąpić w dowolnym momencie';

  @override
  String get contactEmergency => 'Numer alarmowy';

  @override
  String get contactShelter => 'Turvakoti (schronisko) — infolinia';

  @override
  String get contactCrisisHelpline => 'Telefon zaufania (Kriisipuhelin)';

  @override
  String get contactNollaLinja =>
      'Nollalinja — infolinia ds. przemocy wobec kobiet';

  @override
  String get inheritance => 'Spadek';

  @override
  String get inheritanceDesc =>
      'Testamenty, spadek, prawa spadkobierców, zachowek, postępowanie spadkowe';

  @override
  String get rightInheritanceForced =>
      'Spadkobiercy ustawowi (dzieci, małżonek) mają prawo do zachowku niezależnie od treści testamentu';

  @override
  String get rightInheritanceWill =>
      'Masz prawo sporządzić testament rozporządzający Twoim majątkiem — testamenty notarialne mają najsilniejszą moc prawną';

  @override
  String get rightInheritanceRenounce =>
      'Możesz odrzucić spadek w ciągu 3 miesięcy od dnia, w którym dowiedziałeś się o nim';

  @override
  String get rightInheritanceInfo =>
      'Masz prawo uzyskać informacje o masie spadkowej z banków i rejestrów';

  @override
  String get rightInheritanceDispute =>
      'Możesz zakwestionować niesprawiedliwy testament w sądzie w ustawowym terminie przedawnienia';

  @override
  String get mustFileInheritance =>
      'Złóż wniosek o postępowanie spadkowe u notariusza w rozsądnym terminie';

  @override
  String get mustNotifyHeirs =>
      'Wszyscy znani spadkobiercy muszą zostać powiadomieni o postępowaniu spadkowym';

  @override
  String get inheritanceActionGatherDocs =>
      'Zbierz wszystkie dokumenty: akt zgonu, testament, dokumenty własności, wyciągi bankowe';

  @override
  String get inheritanceActionContactNotary =>
      'Skontaktuj się z notariuszem, aby otworzyć postępowanie spadkowe';

  @override
  String get inheritanceActionCheckDebts =>
      'Przed przyjęciem spadku sprawdź, czy masa spadkowa ma długi';

  @override
  String get inheritanceActionFileCourt =>
      'Jeśli testament jest kwestionowany, złóż pozew do sądu';

  @override
  String get inheritanceDeadlineRenounce =>
      '3 miesiące na odrzucenie spadku od dowiedzenia się o nim';

  @override
  String get inheritanceDeadlineDispute =>
      'Termin przedawnienia zaskarżenia testamentu: zależy od podstawy prawnej';

  @override
  String get inheritanceFactForced =>
      'W Estonii zstępni i małżonek mają prawo do zachowku (1/2 udziału ustawowego), nawet jeśli zostali pominięci w testamencie';

  @override
  String get inheritanceFactNotary =>
      'Każde postępowanie spadkowe w Estonii musi przebiegać przez notariusza — tego kroku nie można pominąć';

  @override
  String get consumerProtection => 'Ochrona konsumentów';

  @override
  String get consumerProtectionDesc =>
      'Oszustwa, wadliwe produkty, zwroty, nieuczciwi sprzedawcy';

  @override
  String get rightReturnOnline =>
      'Masz 14 dni na odstąpienie od zakupów online bez podania przyczyny (unijne prawo odstąpienia)';

  @override
  String get rightDefectiveProduct =>
      'Jeśli produkt jest wadliwy, masz prawo do naprawy, wymiany lub zwrotu pieniędzy';

  @override
  String get rightClearPricing =>
      'Sprzedawcy muszą podawać jasne ceny wraz ze wszystkimi opłatami — ukryte koszty są nielegalne';

  @override
  String get rightComplainBoard =>
      'Możesz złożyć bezpłatną skargę do Komisji ds. Sporów Konsumenckich';

  @override
  String get rightProtectionFraud =>
      'Jesteś chroniony przed nieuczciwymi praktykami handlowymi i oszustwami';

  @override
  String get mustKeepReceipts =>
      'Zachowuj wszystkie paragony, umowy i korespondencję ze sprzedawcami';

  @override
  String get mustActTimely =>
      'Zgłoś wady sprzedawcy w rozsądnym terminie po ich wykryciu';

  @override
  String get consumerActionKeepEvidence =>
      'Zachowaj paragony, zrzuty ekranu, e-maile i wszystkie dowody zakupu';

  @override
  String get consumerActionContactSeller =>
      'Najpierw skontaktuj się ze sprzedawcą — opisz problem na piśmie';

  @override
  String get consumerActionFileComplaint =>
      'Złóż skargę do Komisji ds. Sporów Konsumenckich (kuluttajariitalautakunta)';

  @override
  String get consumerActionContactAuthority =>
      'Skontaktuj się z Doradztwem Konsumenckim po bezpłatną pomoc';

  @override
  String get consumerActionReportFraud =>
      'Zgłoś oszustwo na policję i do Rzecznika Konsumentów';

  @override
  String get consumerFactWithdrawal =>
      'Na mocy unijnej Dyrektywy o prawach konsumentów 2011/83/UE masz 14 dni na odstąpienie od każdego zakupu online lub na odległość — bez podania przyczyny. Sprzedawca musi zwrócić pieniądze w ciągu 14 dni.';

  @override
  String get consumerFactWarranty =>
      'W Finlandii sprzedawca odpowiada za wady produktu przez rozsądny okres (często 2 lata i dłużej). Jest to niezależne od gwarancji producenta.';

  @override
  String get consumerDeadlineWithdrawal =>
      'Odstąpienie od zakupu online — 14 dni od dostawy';

  @override
  String get consumerDeadlineDefect =>
      'Zgłoszenie wady sprzedawcy — w ciągu 2 miesięcy od wykrycia (zalecane)';

  @override
  String get contactConsumerAdvisory => 'Doradztwo Konsumenckie';

  @override
  String get contactConsumerOmbudsman =>
      'Rzecznik Konsumentów (Kuluttaja-asiamies)';

  @override
  String get contactConsumerDisputesBoardDirect =>
      'Komisja ds. Sporów Konsumenckich';

  @override
  String get caseTypeStepLabel => 'Rodzaj sprawy';

  @override
  String get detailsStepLabel => 'Szczegóły';

  @override
  String get documentsStepLabel => 'Dokumenty';

  @override
  String get whatTypeOfCase => 'Jakiego rodzaju jest ta sprawa?';

  @override
  String get selectCategoryDescription =>
      'Wybierz kategorię, która najlepiej opisuje Twoją sytuację.';

  @override
  String get tellUsAboutCase => 'Opowiedz nam o swojej sprawie';

  @override
  String get aiHelpsUnderstand =>
      'Ta informacja pomaga naszej AI lepiej zrozumieć Twoją sytuację.';

  @override
  String get caseTitleHint =>
      'np. Odwołanie od decyzji o zezwoleniu na pobyt 2026';

  @override
  String get countryJurisdiction => 'Kraj / jurysdykcja';

  @override
  String get selectCountryHint => 'Wybierz kraj';

  @override
  String get referenceNumberHint => 'np. UMA/12345/2026';

  @override
  String get descriptionOptional => 'Opis (opcjonalnie)';

  @override
  String get descriptionHint =>
      'Krótko opisz swoją sytuację. Co się wydarzyło? Jaka decyzja zapadła?';

  @override
  String get uploadFirstDocument => 'Prześlij swój pierwszy dokument';

  @override
  String get uploadDocumentDescription =>
      'Prześlij pismo z decyzją lub inny istotny dokument. Możesz pominąć ten krok i dodać dokumenty później.';

  @override
  String get tapToUploadFile => 'Dotknij, aby przesłać plik';

  @override
  String get fileSizeLimit => 'PDF, JPG, PNG do 25 MB';

  @override
  String get addDocumentsLaterHint =>
      'Dokumenty możesz zawsze dodać później z ekranu szczegółów sprawy.';

  @override
  String get callAI => 'Zadzwoń do AI';

  @override
  String get comingSoon => 'Wkrótce';

  @override
  String get encrypted => 'Zaszyfrowane';

  @override
  String get typing => 'Pisze…';

  @override
  String get online => 'Online';

  @override
  String get chatWelcomeSubtitle =>
      'Przeanalizuję sytuację, sprawdzę dokumenty, znajdę błędy i podpowiem, co robić.';

  @override
  String get tapMicrophoneToSpeak => 'Dotknij mikrofonu, aby mówić';

  @override
  String get categoryEssential => 'Najważniejsze';

  @override
  String get categoryPolice => 'Policja';

  @override
  String get categoryWork => 'Praca';

  @override
  String get categoryHousing => 'Mieszkanie';

  @override
  String get categoryConsumer => 'Konsument';

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
  String get freeAidThreshold => 'Próg bezpłatnej pomocy';

  @override
  String get partialAidThreshold => 'Próg częściowej pomocy';

  @override
  String get assetLimit => 'Limit majątku';

  @override
  String get whereToApplyLabel => 'Gdzie złożyć wniosek';

  @override
  String get phoneLabel => 'Telefon';

  @override
  String get websiteLabel => 'Strona internetowa';

  @override
  String get disclaimerCollapsed => 'Tylko wskazówki AI';

  @override
  String get disclaimerExpanded =>
      'Asystent AI — to nie jest porada prawna. Zawsze skonsultuj się z wykwalifikowanym prawnikiem.';

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
  String get categoryChildren => 'Dzieci';

  @override
  String get categoryDigital => 'Cyfrowe';

  @override
  String get childrenRights => 'Prawa dziecka i alimenty';

  @override
  String get childrenRightsDesc =>
      'Alimenty na dziecko, ochrona, gwarancje państwowe';

  @override
  String get cyberbullying => 'Cyberprzemoc i nękanie w internecie';

  @override
  String get cyberbullyingDesc =>
      'Groźby, naruszenia prywatności, zniesławienie online';

  @override
  String get rightChildSupport =>
      'Oboje rodzice są prawnie zobowiązani do finansowego utrzymania dziecka (Perekonnaseadus § 100–102)';

  @override
  String get rightMinimumAlimony =>
      'Minimalne alimenty w Estonii: kwota bazowa (295,86 €) + 3% średniego wynagrodzenia brutto z poprzedniego roku (PKS § 101). Od 01.04.2026 — 318,62 €/mies. na dziecko. Aktualizowane corocznie 1 kwietnia. Kalkulator: alimendid.ee';

  @override
  String get rightCourtAlimony =>
      'Możesz wystąpić o alimenty w sądzie okręgowym (maakohus) — bez wymogu adwokata przy roszczeniach do 6400 €';

  @override
  String get rightBailiffEnforcement =>
      'Jeśli rodzic odmawia płacenia, komornik (kohtutäitur) może wyegzekwować orzeczenie sądu, w tym zajęcie wynagrodzenia';

  @override
  String get rightStateAlimonyGuarantee =>
      'Jeśli rodzic nie płaci, państwo zapewnia elatisabi (zasiłek alimentacyjny) za pośrednictwem Sotsiaalkindlustusamet — do 100 €/mies. na dziecko';

  @override
  String get rightChildEducation =>
      'Każde dziecko ma prawo do edukacji, opieki zdrowotnej i ochrony przed przemocą (Lastekaitseseadus § 4–5)';

  @override
  String get rightChildContact =>
      'Dziecko ma prawo do utrzymywania kontaktu z oboma rodzicami, chyba że sąd zdecyduje inaczej (PKS § 143)';

  @override
  String get mustFileCourtClaim =>
      'Aby otrzymywać alimenty, musisz złożyć pozew w sądzie lub ustalić kwotę pisemnie';

  @override
  String get mustNotifyAddressChange =>
      'Powiadom Sotsiaalkindlustusamet o zmianie adresu, jeśli otrzymujesz elatisabi';

  @override
  String get childrenActionGatherDocs =>
      'Zbierz akt urodzenia dziecka, swój dowód tożsamości i dowody wydatków';

  @override
  String get childrenActionFileCourtClaim =>
      'Złóż pozew alimentacyjny w sądzie okręgowym (maakohus) — można to zrobić online przez e-toimik';

  @override
  String get childrenActionApplyElatisabi =>
      'Wystąp o państwową gwarancję alimentacyjną (elatisabi) w Sotsiaalkindlustusamet, jeśli rodzic nie płaci';

  @override
  String get childrenActionContactBailiff =>
      'Skontaktuj się z komornikiem (kohtutäitur), aby wyegzekwować orzeczenie sądu';

  @override
  String get childrenActionCallLasteabi =>
      'Zadzwoń pod Lasteabi 116 111 — bezpłatna infolinia dla dzieci, 24/7';

  @override
  String get childrenDeadlineElatisabi =>
      'Wniosek o elatisabi — po orzeczeniu sądu, brak ścisłego terminu, ale proces trwa';

  @override
  String get childrenDeadlineCourt =>
      'Alimenty można dochodzić wstecz do 1 roku przed złożeniem pozwu';

  @override
  String get childrenFactMinimum =>
      'Od 01.04.2026 minimalne alimenty na dziecko wynoszą 318,62 €/mies. Wzór: kwota bazowa (295,86 €) + 3% średniego wynagrodzenia brutto z poprzedniego roku. Aktualizowane corocznie 1 kwietnia. Rodzic nie może umówić się na niższą kwotę. Kalkulator: alimendid.ee';

  @override
  String get childrenFactElatisabi =>
      'Państwowa gwarancja alimentacyjna w Estonii (elatisabi) została wprowadzona w 2017 r., aby chronić dzieci, gdy rodzic odmawia płacenia. Państwo płaci, a następnie odzyskuje kwotę od rodzica-dłużnika.';

  @override
  String get rightReportCybercrime =>
      'Masz prawo zgłosić groźby online, nękanie i kradzież tożsamości na policję (Karistusseadustik § 120, § 157¹)';

  @override
  String get rightContentRemoval =>
      'Możesz zażądać usunięcia zniesławiających lub prywatnych treści z platform i domagać się ich usunięcia na podstawie RODO';

  @override
  String get rightMoralDamageCompensation =>
      'Możesz dochodzić odszkodowania za krzywdę moralną spowodowaną cyberprzemocą (Võlaõigusseadus § 1043–1055)';

  @override
  String get rightPrivacyProtection =>
      'Twoje życie prywatne jest chronione — nieuprawnione udostępnianie Twoich zdjęć, wiadomości lub danych osobowych jest nielegalne (KarS § 157)';

  @override
  String get rightDataProtection =>
      'Zgłoś naruszenia ochrony danych (nieuprawnione wykorzystanie Twoich danych) do Andmekaitse Inspektsioon';

  @override
  String get rightDefamationAction =>
      'Zniesławienie (laimamine) jest wykroczeniem cywilnym — możesz pozwać o odszkodowanie i zażądać publicznego sprostowania (KarS § 247 (uchylony), VÕS § 1047)';

  @override
  String get mustCollectEvidence =>
      'Zbieraj i zachowuj wszystkie dowody — zrzuty ekranu, linki, daty i dane świadków';

  @override
  String get mustNotRetaliate =>
      'Nie odwzajemniaj się i nie angażuj się w kontrnękanie — może to osłabić Twoją sprawę';

  @override
  String get cyberActionScreenshots =>
      'Rób zrzuty ekranu wszystkich przypadków nękania — zapisuj adresy URL, daty, nazwy użytkowników i treści';

  @override
  String get cyberActionReportPolice =>
      'Złóż zawiadomienie na najbliższym posterunku policji lub online na politsei.ee';

  @override
  String get cyberActionReportPlatform =>
      'Zgłoś treść platformie mediów społecznościowych w celu usunięcia';

  @override
  String get cyberActionContactDPA =>
      'Skontaktuj się z Andmekaitse Inspektsioon, jeśli Twoje dane osobowe zostały wykorzystane niezgodnie z prawem';

  @override
  String get cyberActionConsultLawyer =>
      'Skonsultuj się z prawnikiem w sprawie odszkodowania cywilnego — bezpłatna pomoc prawna jest dostępna przez Riigi Õigusabi';

  @override
  String get cyberDeadlineCriminal =>
      'Zawiadomienie karne — brak ścisłego terminu, ale zgłoś jak najszybciej dla najlepszych rezultatów';

  @override
  String get cyberDeadlineCivil =>
      'Roszczenie cywilne o odszkodowanie — do 3 lat od dnia, w którym dowiedziałeś się o naruszeniu (TsÜS § 150)';

  @override
  String get cyberFactPrivacy =>
      'W Estonii nieuprawnione udostępnianie czyichś intymnych zdjęć może skutkować karą do 3 lat więzienia na podstawie Karistusseadustik § 157¹ (naruszenie prywatności).';

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
  String get deadlineRadarTitle => 'Nadchodzące terminy';

  @override
  String get deadlineRadarEmpty => 'Brak nadchodzących terminów';

  @override
  String get deadlineRadarViewAll => 'Zobacz wszystkie';

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
  String get deadlineCardTomorrow => 'jutro';

  @override
  String get deadlineCardToday => 'dzisiaj';

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
  String get deadlineCardMarkComplete => 'Oznacz jako zakończone';

  @override
  String get deadlineCardSnooze => 'Odłóż';

  @override
  String get deadlineCardSnooze3d => 'Odłóż o 3 dni';

  @override
  String get deadlineCardSnooze7d => 'Odłóż o 7 dni';

  @override
  String get deadlineCardSnoozeCustom => 'Wybierz datę';

  @override
  String get deadlineCardEdit => 'Edytuj';

  @override
  String get deadlineCardDelete => 'Archiwizuj';

  @override
  String get deadlineCardSourceLabelPdf => 'z PDF';

  @override
  String get deadlineCardSourceLabelIntake => 'z formularza zgłoszeniowego';

  @override
  String get deadlineCardSourceLabelManual => 'dodane ręcznie';

  @override
  String get deadlineCardSourceLabelEmail => 'z e-maila';

  @override
  String get deadlineCardSourceLabelHaikuExtract => 'wyodrębnione przez AI';

  @override
  String get deadlineCardSourceLabelStatutoryTemplate => 'szablon ustawowy';

  @override
  String deadlineBannerCritical(String title, String when) {
    return 'Krytyczny termin $title $when';
  }

  @override
  String get deadlineBannerDismiss => 'Odrzuć';

  @override
  String get deadlineBannerOpen => 'Otwórz termin';

  @override
  String deadlineHolidayShifted(String original, String reason) {
    return 'Przesunięto z $original z powodu $reason';
  }

  @override
  String get deadlinePermissionAskTitle => 'Włączyć przypomnienia o terminach?';

  @override
  String get deadlinePermissionAskBody =>
      'Powiadomimy Cię 7, 3 i 1 dzień przed każdym ustawowym terminem, a także rano w dniu terminu. Nigdy nie wykorzystujemy tego do celów marketingowych.';

  @override
  String get deadlinePermissionAllow => 'Zezwól';

  @override
  String get deadlinePermissionLater => 'Później';

  @override
  String get deadlineSettingsSection => 'Przypomnienia o terminach';

  @override
  String get deadlineSettingsPushChannel => 'Powiadomienia push';

  @override
  String get deadlineSettingsEmailChannel => 'E-mail (tylko krytyczne)';

  @override
  String get deadlineSettingsInAppChannel => 'Banery w aplikacji';

  @override
  String get deadlineSettingsCriticalBypass =>
      'Krytyczne przypomnienia pomijają godziny ciszy';

  @override
  String get deadlineSettingsQuietHours => 'Godziny ciszy';

  @override
  String deadlineSettingsQuietHoursBadge(String start, String end) {
    return 'Cisza $start–$end';
  }

  @override
  String get deadlineCaseScreenTitle => 'Terminy sprawy';

  @override
  String get deadlineAddManualCta => 'Dodaj termin';

  @override
  String get deadlineFormTitle => 'Tytuł';

  @override
  String get deadlineFormDescription => 'Opis (opcjonalnie)';

  @override
  String get deadlineFormStatuteTemplate => 'Szablon ustawowy';

  @override
  String get deadlineFormStatuteTemplateNone => 'Brak (ręcznie)';

  @override
  String get deadlineFormDeadlineAt => 'Data terminu';

  @override
  String get deadlineFormPriority => 'Priorytet';

  @override
  String get deadlineFormSave => 'Zapisz';

  @override
  String get deadlineFormCancel => 'Anuluj';

  @override
  String get deadlineCompletedNotePrompt => 'Dodaj notatkę (opcjonalnie)';

  @override
  String get deadlineCompletedNoteSave => 'Zapisz';

  @override
  String get inboxTitle => 'Skrzynka odbiorcza';

  @override
  String get inboxEmptyTitle => 'Brak oczekujących';

  @override
  String get inboxEmptyBody =>
      'Nowe wątki e-mail pojawią się tutaj po ich posortowaniu.';

  @override
  String get inboxApproveSend => 'Zatwierdź i wyślij';

  @override
  String get inboxEditDraft => 'Edytuj';

  @override
  String get inboxSnooze => 'Odłóż';

  @override
  String get inboxArchive => 'Archiwizuj';

  @override
  String get inboxFilterAll => 'Wszystkie';

  @override
  String get inboxConfirmSendTitle => 'Wysłać przygotowaną odpowiedź?';

  @override
  String get inboxConfirmSendBody =>
      'Advocat wyśle odpowiedź przygotowaną przez AI za pośrednictwem połączonego konta Gmail. Możesz jeszcze przejrzeć treść na następnym ekranie.';

  @override
  String get inboxSendButton => 'Wyślij';

  @override
  String get inboxSentToast => 'Wysłano.';

  @override
  String get inboxAlreadySentToast => 'Już wysłano.';

  @override
  String get inboxSendErrorToast =>
      'Nie udało się wysłać odpowiedzi. Dotknij, aby spróbować ponownie.';

  @override
  String get inboxSnoozedToast => 'Odłożono na 24 godz.';

  @override
  String get inboxArchivedToast => 'Zarchiwizowano.';

  @override
  String get inboxDraftLoadError => 'Nie udało się wczytać wersji roboczej.';

  @override
  String get inboxDeadlineToday => 'dzisiaj';

  @override
  String get inboxDeadlineTomorrow => 'jutro';

  @override
  String inboxDeadlineInDays(int days) {
    return 'za ${days}d';
  }

  @override
  String inboxDeadlineOverdue(int days) {
    return 'opóźnienie ${days}d';
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
  String get workspaceTabOverview => 'Przegląd';

  @override
  String get workspaceTabChat => 'Czat';

  @override
  String get workspaceTabDrafts => 'Wersje robocze';

  @override
  String get workspaceOverviewEmpty =>
      'Dodaj dokumenty, aby utworzyć podsumowanie.';

  @override
  String get workspaceTimelineEmpty => 'Brak wydarzeń.';

  @override
  String get workspaceDocumentsEmpty => 'Brak dokumentów. Prześlij ze skanera.';

  @override
  String get workspaceDraftsEmpty => 'Brak wersji roboczych.';

  @override
  String get workspaceInboxEmpty => 'Brak powiązanych e-maili.';

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
  String get draftsTab => 'Wersje robocze';

  @override
  String get draftingTitle => 'Studio redagowania';

  @override
  String get draftingEmpty => 'Pusta wersja robocza';

  @override
  String get draftingPlaceholder => 'Zacznij pisać swoją wersję roboczą…';

  @override
  String get draftingDraftsList => 'Moje wersje robocze';

  @override
  String get draftingSave => 'Zapisz';

  @override
  String get draftingSaved => 'Zapisano';

  @override
  String get draftingSavedJustNow => 'Zapisano przed chwilą';

  @override
  String get draftingAiRevise => 'Popraw z pomocą AI';

  @override
  String get draftingExportPdf => 'Eksportuj PDF';

  @override
  String get draftingExportDocx => 'Eksportuj DOCX';

  @override
  String get draftingExportMd => 'Eksportuj Markdown';

  @override
  String get draftingDeleteDraft => 'Usuń wersję roboczą';

  @override
  String get draftingConfirmDelete => 'Usunąć tę wersję roboczą?';

  @override
  String get draftingConfirmDeleteMessage => 'Tej czynności nie można cofnąć.';

  @override
  String get draftingConfirm => 'Usuń';

  @override
  String get draftingCancel => 'Anuluj';

  @override
  String draftingDraftReplyTo(String name) {
    return 'Odpowiedź do $name';
  }

  @override
  String get draftingUntitled => 'Bez tytułu';

  @override
  String get draftingTitleHint => 'Tytuł (opcjonalnie)';

  @override
  String get draftingAiReviseTitle => 'Popraw z pomocą AI';

  @override
  String get draftingAiReviseSelectionLabel => 'Zaznaczony tekst:';

  @override
  String get draftingAiReviseInstructionLabel => 'Instrukcja (opcjonalnie)';

  @override
  String get draftingAiReviseInstructionHint =>
      'np. „uczyń bardziej formalnym” lub „skróć”';

  @override
  String get draftingAiReviseRunButton => 'Generuj poprawkę';

  @override
  String get draftingAiReviseSuggestionLabel => 'Sugerowana poprawka:';

  @override
  String get draftingAiReviseChangesLabel => 'Zmiany:';

  @override
  String get draftingAiReviseAccept => 'Zaakceptuj';

  @override
  String get draftingAiReviseReject => 'Odrzuć';

  @override
  String get draftingFormatBold => 'Pogrubienie';

  @override
  String get draftingFormatItalic => 'Kursywa';

  @override
  String get draftingFormatHeading => 'Nagłówek';

  @override
  String get draftingFormatBullet => 'Lista punktowana';

  @override
  String get draftingFormatNumbered => 'Lista numerowana';

  @override
  String get draftingEmptyListMessage =>
      'Nie masz jeszcze żadnych wersji roboczych.';

  @override
  String get draftingEmptyListAction => 'Nowa wersja robocza';

  @override
  String get draftingExporting => 'Eksportowanie…';

  @override
  String get draftingExportFailed => 'Eksport nie powiódł się';

  @override
  String get draftingSaveFailed => 'Zapis nie powiódł się';

  @override
  String get draftingNewDraft => 'Nowa wersja robocza';

  @override
  String get vaultNoteChip => 'Notatka w skarbcu';

  @override
  String get saveToVault => 'Zapisz w Skarbcu';

  @override
  String get savingToVault => 'Zapisywanie w Skarbcu…';

  @override
  String get savedToVault => 'Zapisano w Skarbcu';

  @override
  String get vaultNoteTitlePrefix => 'Notatka: ';

  @override
  String get openInVault => 'Otwórz w Skarbcu';

  @override
  String get saveToVaultFailed => 'Zapis w Skarbcu nie powiódł się';

  @override
  String get pdfWorkerUnavailable =>
      'Eksport do PDF jest tymczasowo niedostępny. Spróbuj DOCX lub Markdown.';

  @override
  String get draftingVersionHistory => 'Historia wersji';

  @override
  String get emptyHomeTitle => 'Witaj w Advocat';

  @override
  String get emptyHomeBody =>
      'Wybierz punkt wyjścia — my zajmiemy się prawnym ciężarem.';

  @override
  String get intentChip1 => 'Dostałem mandat';

  @override
  String get intentChip2 => 'Odmówiono zezwolenia';

  @override
  String get intentChip3 => 'Problem z umową';

  @override
  String get emptyCasesTitle => 'Brak spraw';

  @override
  String get emptyCasesCta => 'Rozpocznij sprawę';

  @override
  String get emptyDraftsTitle => 'Brak wersji roboczych';

  @override
  String get emptyDraftsCta => 'Utwórz wersję roboczą';

  @override
  String get emptyChatTitle => 'Zapytaj Advocat o cokolwiek';

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
  String get referralInviteFriends => 'Zaproś znajomych';

  @override
  String get referralYourCode => 'Twój kod';

  @override
  String get referralCopiedToast => 'Kod skopiowany do schowka';

  @override
  String get referralReward =>
      'Otrzymaj 1 miesiąc planu Counsel gratis za każdego znajomego, który się zasubskrybuje.';

  @override
  String get referralInvited => 'Zaproszeni znajomi';

  @override
  String get referralRewardsEarned => 'Zdobyte darmowe miesiące';

  @override
  String get deadlineUrgencyToday => 'Dziś i zaległe';

  @override
  String get deadlineUrgencyWeek => 'W tym tygodniu';

  @override
  String get deadlineUrgencyMonth => 'W tym miesiącu';

  @override
  String get deadlineUrgencyLater => 'Później';

  @override
  String get deadlineAddManual => 'Dodaj termin';

  @override
  String get deadlineSnoozeBy => 'Odłóż';

  @override
  String get deadlineSnooze1d => 'Odłóż o 1 dzień';

  @override
  String get deadlineSnooze3d => 'Odłóż o 3 dni';

  @override
  String get deadlineSnooze7d => 'Odłóż o 7 dni';

  @override
  String get deadlineDismiss => 'Odrzuć';

  @override
  String get deadlineExportIcs => 'Dodaj do kalendarza';

  @override
  String get deadlineSource => 'Źródło';

  @override
  String get deadlineEmpty =>
      'Brak terminów. Terminy są tworzone automatycznie z Twoich e-maili i dokumentów — lub dodaj je ręcznie przyciskiem +.';

  @override
  String get deadlineNewTitle => 'Nowy termin';

  @override
  String get deadlineFieldTitle => 'Tytuł';

  @override
  String get deadlineFieldDueDate => 'Termin realizacji';

  @override
  String get deadlineFieldNotes => 'Notatki (opcjonalnie)';

  @override
  String get deadlineSaved => 'Termin zapisany';

  @override
  String get deadlineSaveFailed => 'Nie udało się zapisać terminu';

  @override
  String get deadlineUrgentBannerSingle => '1 termin dzisiaj lub zaległy';

  @override
  String deadlineUrgentBannerMany(int count) {
    return '$count terminów dzisiaj lub zaległych';
  }

  @override
  String deadlineDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pozostało $count dni',
      few: 'pozostały $count dni',
      one: 'pozostał 1 dzień',
      zero: 'dzisiaj',
    );
    return '$_temp0';
  }

  @override
  String deadlineDaysOverdue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dni opóźnienia',
      few: '$count dni opóźnienia',
      one: '1 dzień opóźnienia',
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
  String get deadlineEuRadarTitle => 'Radar terminów UE (podgląd)';

  @override
  String get deadlineEuRadarSubtitle =>
      'Hipotetyczne unijne terminy proceduralne — dane przykładowe';

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
  String get accessLogTile => 'Rejestr dostępu';

  @override
  String get accessLogTileSubtitle =>
      'Zobacz, kto i co miało dostęp do Twoich danych';

  @override
  String get accessLogTitle => 'Rejestr dostępu do moich danych';

  @override
  String get accessLogIntro =>
      'Przejrzysty, odporny na manipulacje zapis każdego dostępu do Twoich danych lub ich przetwarzania — w tym przez naszą SI. Możesz zweryfikować, że nie został zmieniony.';

  @override
  String get accessLogEmpty => 'Brak zdarzeń dostępu.';

  @override
  String get accessLogError =>
      'Nie udało się załadować rejestru dostępu. Pociągnij w dół, aby spróbować ponownie.';

  @override
  String get accessLogIntegrityOk =>
      'Integralność potwierdzona — wpisy rejestru tworzą nieprzerwany łańcuch.';

  @override
  String get accessLogIntegrityBroken =>
      'Ostrzeżenie: łańcuch rejestru jest przerwany. Niektóre wpisy mogły zostać usunięte lub przestawione. Skontaktuj się z pomocą techniczną.';

  @override
  String get accessActionLlmEgress =>
      'Wysłano do SI w celu przetworzenia (pseudonimizowane)';

  @override
  String get accessActionAiAnalysis => 'Przeanalizowane przez SI';

  @override
  String get accessActionDocumentParse => 'Przetworzono dokument';

  @override
  String get accessActionStaffRead => 'Sprawdzone przez członka zespołu';

  @override
  String get accessActionExport => 'Wyeksportowano dane';

  @override
  String get accessActionEmailTriage => 'Posegregowano e-mail';

  @override
  String get accessActionDeadlineScan => 'Przeskanowano terminy';

  @override
  String get breachAlertTitle => 'Alert bezpieczeństwa dotyczący Twoich danych';

  @override
  String get breachAlertBody =>
      'Nasz automatyczny monitoring wykrył nietypowy dostęp do Twoich danych. Sprawdzamy to i powiadomimy Cię o każdym potwierdzonym incydencie zgodnie z wymogami prawa (art. 34 RODO).';

  @override
  String get caseDossierTitle => 'Eksportuj akta sprawy';

  @override
  String get caseDossierSubtitle =>
      'Jeden plik PDF zawierający wszystko — fakty, chronologię, terminy i dokumenty — do przekazania prawnikowi, sądowi lub organowi rozpatrującemu skargi.';

  @override
  String get caseDossierTileTitle => 'Eksportuj akta (PDF)';

  @override
  String get caseDossierTileSubtitle =>
      'Przekaż całą sprawę prawnikowi lub sądowi w jednym pliku';

  @override
  String get caseDossierSectionsHeading => 'Uwzględnij w aktach';

  @override
  String get caseDossierSectionFacts => 'Fakty sprawy';

  @override
  String get caseDossierSectionFactsHint => 'Zawsze uwzględniane';

  @override
  String get caseDossierSectionTimeline => 'Chronologia';

  @override
  String get caseDossierSectionDeadlines => 'Terminy';

  @override
  String get caseDossierSectionDocuments => 'Dokumenty';

  @override
  String get caseDossierSectionAiSummary => 'Podsumowanie SI';

  @override
  String get caseDossierExportButton => 'Eksportuj PDF';

  @override
  String get caseDossierExporting => 'Tworzenie akt…';

  @override
  String get caseDossierSuccess => 'Akta gotowe. Otwórz lub udostępnij plik.';

  @override
  String get caseDossierOpen => 'Otwórz akta';

  @override
  String get caseDossierError =>
      'Nie udało się utworzyć akt. Spróbuj ponownie.';

  @override
  String get caseDossierErrorNotOwned => 'Nie znaleziono tej sprawy.';

  @override
  String get caseDossierDisclaimer =>
      'Akta odtwarzają dane Twojej sprawy w zarejestrowanej postaci. Sprawdź je przed udostępnieniem.';

  @override
  String get followupsTitle => 'Następne kroki';

  @override
  String get followupsSubtitle =>
      'Praktyczne zadania utrzymujące postęp sprawy';

  @override
  String get followupsEmpty => 'Brak kolejnych kroków.';

  @override
  String get followupsEmptyDesc =>
      'Dodaj krok lub pozwól SI zaproponować, co zrobić dalej.';

  @override
  String get followupsAdd => 'Dodaj krok';

  @override
  String get followupsSuggest => 'Zaproponuj kroki';

  @override
  String get followupsSuggestNone =>
      'Brak propozycji w tej chwili. Spróbuj po rozmowie o sprawie.';

  @override
  String get followupsSuggestTitle => 'Proponowane następne kroki';

  @override
  String get followupsAddPrompt => 'Dodaj kroki, które chcesz zachować:';

  @override
  String get followupsNewTitleHint => 'Co należy zrobić?';

  @override
  String get followupsNewDetailHint =>
      'Opcjonalna notatka (dlaczego / co dołączyć)';

  @override
  String get followupsDueOptional => 'Przypomnij mi (opcjonalnie)';

  @override
  String get followupsOverdue => 'Po terminie';

  @override
  String followupsDueOn(String date) {
    return 'Termin: $date';
  }

  @override
  String get followupsDone => 'Gotowe';

  @override
  String get followupsSnooze => 'Odłóż';

  @override
  String get followupsSnooze1Week => 'Przypomnij za tydzień';

  @override
  String get followupsDismiss => 'Odrzuć';

  @override
  String get followupsLoadError => 'Nie udało się załadować następnych kroków';

  @override
  String get followupsAiBadge => 'SI';

  @override
  String get contractCompareTitle => 'Porównaj wersje';

  @override
  String get contractCompareIntro =>
      'Prześlij dwie wersje tej samej umowy. Wyróżnimy, co się zmieniło i czy każda zmiana jest dla Ciebie korzystna, czy niekorzystna.';

  @override
  String get contractCompareOldVersion => 'Stara wersja (v1)';

  @override
  String get contractCompareNewVersion => 'Nowa wersja (v2)';

  @override
  String get contractCompareCta => 'Porównaj wersje';

  @override
  String get contractCompareAdverse => 'Niekorzystna';

  @override
  String get contractCompareFavorable => 'Korzystna';

  @override
  String get contractCompareNeutral => 'Neutralna';

  @override
  String get contractCompareBefore => 'Przed';

  @override
  String get contractCompareAfter => 'Po';

  @override
  String get contractCompareTruncated =>
      'Długa umowa — porównano tylko pierwszą część każdej wersji.';

  @override
  String get contractCompareNoChanges =>
      'Nie wykryto istotnych zmian między dwiema wersjami.';

  @override
  String get docSearchTitle => 'Przeszukaj moje dokumenty';

  @override
  String get docSearchHint => 'np. gdzie wspomniano o kaucji';

  @override
  String get docSearchSubtitle =>
      'Wyszukiwanie semantyczne w sejfie i aktach spraw';

  @override
  String get docSearchIdle =>
      'Przeszukuj treść własnych dokumentów — nie tylko tytuły.';

  @override
  String get docSearchNoResults =>
      'Nie znaleziono dopasowań w Twoich dokumentach.';

  @override
  String get docSearchError =>
      'Wyszukiwanie nie powiodło się. Spróbuj ponownie.';

  @override
  String get docSearchUntitled => 'Dokument bez tytułu';

  @override
  String get docSearchKindCase => 'Dokument sprawy';

  @override
  String get docSearchKindVault => 'Dokument z sejfu';

  @override
  String get docSearchMenuTitle => 'Przeszukaj moje dokumenty';

  @override
  String get docSearchMenuSubtitle =>
      'Znajdź wszystko we własnych plikach według znaczenia';

  @override
  String get legalTemplatesTitle => 'Biblioteka wzorów';

  @override
  String get legalTemplatesMenuLabel => 'Wzory';

  @override
  String get legalTemplatesSubtitle =>
      'Wybierz gotowy formularz, uzupełnij kilka danych, a my utworzymy projekt, który możesz edytować i wyeksportować.';

  @override
  String get legalTemplatesDisclaimer =>
      'To ogólne przykładowe formularze, a nie indywidualna porada prawna. Sprawdź je i dostosuj przed wysłaniem.';

  @override
  String get legalTemplatesSampleBadge => 'Przykład';

  @override
  String get legalTemplatesEmpty => 'Brak wzorów dla tego filtra.';

  @override
  String get legalTemplatesError =>
      'Nie udało się załadować wzorów. Spróbuj ponownie.';

  @override
  String get legalTemplatesFilterAll => 'Wszystkie';

  @override
  String get legalTemplatesJurisdictionFi => 'Finlandia';

  @override
  String get legalTemplatesJurisdictionEe => 'Estonia';

  @override
  String get legalTemplatesCategoryComplaint => 'Skargi';

  @override
  String get legalTemplatesCategoryAppeal => 'Odwołania';

  @override
  String get legalTemplatesCategoryApplication => 'Wnioski';

  @override
  String get legalTemplatesCategoryClaim => 'Roszczenia';

  @override
  String get legalTemplatesCategoryRequest => 'Żądania';

  @override
  String get legalTemplatesFillTitle => 'Uzupełnij dane';

  @override
  String get legalTemplatesFillIntro =>
      'Automatycznie wypełnimy Twoje imię i dane sprawy. Uzupełnij poniższe pola.';

  @override
  String get legalTemplatesFieldRequired => 'To pole jest wymagane';

  @override
  String get legalTemplatesCreateDraft => 'Utwórz projekt';

  @override
  String get legalTemplatesCreating => 'Tworzenie projektu…';

  @override
  String get legalTemplatesCreateFailed =>
      'Nie udało się utworzyć projektu. Spróbuj ponownie.';

  @override
  String get legalTemplatesUnresolvedWarning =>
      'Niektóre pola są nadal puste i oznaczone jako ____ w projekcie. Możesz je uzupełnić w edytorze.';

  @override
  String get legalTemplatesFieldRecipient => 'Adresat (organ / wynajmujący)';

  @override
  String get legalTemplatesFieldAddress => 'Twój adres pocztowy';

  @override
  String get legalTemplatesFieldSubject => 'Temat';

  @override
  String get legalTemplatesFieldDescription => 'Opis sprawy';

  @override
  String get legalTemplatesFieldDemand => 'O co wnosisz';

  @override
  String get checklistActionPlan => 'Plan działania';

  @override
  String get checklistActionPlanSubtitle => 'Kroki dla tego typu sprawy';

  @override
  String checklistProgress(int completed, int total) {
    return 'Wykonano $completed z $total kroków';
  }

  @override
  String get checklistAllDone => 'Wszystkie kroki ukończone';

  @override
  String get checklistEmpty => 'Brak planu działania dla tego typu sprawy.';

  @override
  String checklistDeadlineDays(int days) {
    return '$days dni';
  }

  @override
  String get checklistDisclaimer =>
      'To ogólne informacje, a nie porada prawna. Terminy to ustawowe wartości domyślne — potwierdź dokładną datę dla swojej sprawy.';

  @override
  String get checklistViewPlan => 'Zobacz plan';

  @override
  String get explainPlainTitle => 'Wyjaśnij prostymi słowami';

  @override
  String get explainPlainIntro =>
      'Wklej urzędowe pismo, decyzję lub umowę, a wyjaśnimy, co to znaczy i czego od Ciebie wymaga — prostym językiem.';

  @override
  String get explainPlainLevelFriend => 'Jak do przyjaciela';

  @override
  String get explainPlainLevelTerms => 'Zachowaj terminy prawne';

  @override
  String get explainPlainInputHint => 'Wklej tutaj tekst prawny…';

  @override
  String get explainPlainSubmit => 'Wyjaśnij';

  @override
  String get explainPlainWorking => 'Wyjaśnianie…';

  @override
  String get explainPlainTldr => 'W skrócie';

  @override
  String get explainPlainBreakdown => 'Co mówi, część po części';

  @override
  String get explainPlainGlossary => 'Trudne terminy wyjaśnione';

  @override
  String get explainPlainNextSteps => 'Co możesz zrobić dalej';

  @override
  String get explainPlainOpenInCorpus => 'Sprawdź w bibliotece prawa';

  @override
  String get explainPlainEmptyResult =>
      'Nie udało się przygotować wyjaśnienia dla tego tekstu. Spróbuj wkleić dłuższy lub bardziej czytelny fragment.';

  @override
  String get explainPlainQuotaTitle =>
      'Wykorzystałeś bezpłatne wyjaśnienia w tym miesiącu';

  @override
  String get explainPlainQuotaBody =>
      'Konta bezpłatne otrzymują 3 wyjaśnienia miesięcznie. Przejdź na Pro, aby uzyskać nieograniczone wyjaśnienia.';

  @override
  String get explainPlainUpgradeCta => 'Przejdź na Pro';

  @override
  String get explainPlainError =>
      'Coś poszło nie tak podczas wyjaśniania tego tekstu. Spróbuj ponownie.';

  @override
  String get explainPlainRetry => 'Spróbuj ponownie';

  @override
  String get demandLetterTitle => 'Wezwanie';

  @override
  String get demandLetterSubtitle =>
      'Utwórz formalne przedsądowe wezwanie (maksuvaatimus / nõudekiri).';

  @override
  String get demandLetterStepType => 'Rodzaj roszczenia';

  @override
  String get demandLetterStepParties => 'Strony';

  @override
  String get demandLetterStepClaim => 'Kwota i podstawa';

  @override
  String get demandLetterStepDeadline => 'Termin';

  @override
  String get demandLetterStepReview => 'Przejrzyj i wygeneruj';

  @override
  String get demandLetterClaimDepositReturn => 'Zwrot kaucji najmu';

  @override
  String get demandLetterClaimUnpaidWage => 'Niewypłacone wynagrodzenie';

  @override
  String get demandLetterClaimFineDispute =>
      'Zakwestionowanie grzywny / opłaty';

  @override
  String get demandLetterClaimGeneric => 'Inne roszczenie pieniężne';

  @override
  String get demandLetterJurisdiction => 'Jurysdykcja';

  @override
  String get demandLetterLanguage => 'Język pisma';

  @override
  String get demandLetterRecipientName => 'Imię i nazwisko adresata';

  @override
  String get demandLetterRecipientAddress => 'Adres adresata (opcjonalnie)';

  @override
  String get demandLetterSenderName => 'Twoje imię i nazwisko';

  @override
  String get demandLetterSenderAddress => 'Twój adres / e-mail (opcjonalnie)';

  @override
  String get demandLetterAmount => 'Kwota';

  @override
  String get demandLetterCurrency => 'Waluta';

  @override
  String get demandLetterBasis => 'Co się stało (podstawa roszczenia)';

  @override
  String get demandLetterBasisHint =>
      'Opisz fakty: daty, kwoty, co uzgodniono i co poszło nie tak.';

  @override
  String get demandLetterDeadline => 'Termin płatności';

  @override
  String get demandLetterDeadlineHint => 'np. 14 dni od dziś';

  @override
  String get demandLetterReference => 'Sygnatura (opcjonalnie)';

  @override
  String get demandLetterGenerate => 'Wygeneruj pismo';

  @override
  String get demandLetterGenerating => 'Generowanie…';

  @override
  String get demandLetterGenerateFailed =>
      'Nie udało się wygenerować pisma. Spróbuj ponownie.';

  @override
  String get demandLetterFieldRequired => 'To pole jest wymagane';

  @override
  String get demandLetterNext => 'Dalej';

  @override
  String get demandLetterBack => 'Wstecz';

  @override
  String get demandLetterPreviewTitle => 'Twoje pismo';

  @override
  String get demandLetterCopy => 'Kopiuj tekst';

  @override
  String get demandLetterCopied => 'Pismo skopiowane do schowka';

  @override
  String get demandLetterExportPdf => 'Eksportuj PDF';

  @override
  String get demandLetterExporting => 'Eksportowanie…';

  @override
  String get demandLetterExportFailed =>
      'Nie udało się wyeksportować dokumentu. Spróbuj ponownie.';

  @override
  String get demandLetterSendEmail => 'Wyślij e-mailem';

  @override
  String get demandLetterNormsTitle => 'Odniesienia prawne';

  @override
  String get demandLetterDisclaimer =>
      'To pismo jest przygotowane w Twoim imieniu jako ogólny wzór. Nie stanowi porady prawnej ani czynności licencjonowanego adwokata. Sprawdź je przed wysłaniem — żadne pismo nie jest wysyłane automatycznie.';

  @override
  String get demandLetterMenuTile => 'Wezwanie';

  @override
  String get calcHubTitle => 'Kalkulatory prawne';

  @override
  String get calcHubSubtitle => 'Szybkie szacunki przed kolejnym krokiem';

  @override
  String get calcHubJurisdiction => 'Jurysdykcja';

  @override
  String calcRatesAsOf(String date) {
    return 'Stawki na dzień $date';
  }

  @override
  String get calcRatesOffline => 'Wyświetlanie zapisanych stawek (offline)';

  @override
  String get calcIndicativeBanner =>
      'Tylko szacunek orientacyjny — nie jest to oficjalne obliczenie ani porada prawna.';

  @override
  String get calcCalculate => 'Oblicz';

  @override
  String get calcResult => 'Wynik';

  @override
  String get calcFormula => 'Jak to obliczono';

  @override
  String get calcSource => 'Źródło';

  @override
  String get calcSeveranceTitle => 'Odprawa / wypowiedzenie';

  @override
  String get calcSeveranceDesc =>
      'Oszacuj odprawę i okres wypowiedzenia przy zwolnieniu z przyczyn ekonomicznych';

  @override
  String get calcSeveranceSalary => 'Miesięczne wynagrodzenie brutto';

  @override
  String get calcSeveranceTenure => 'Lata stażu pracy';

  @override
  String get calcSeveranceTotal => 'Szacowana odprawa';

  @override
  String get calcSeveranceNotice => 'Okres wypowiedzenia';

  @override
  String get calcSeveranceGenerateDemand => 'Sporządź wezwanie';

  @override
  String get calcLimitationTitle => 'Terminy przedawnienia i odwołań';

  @override
  String get calcLimitationDesc =>
      'Sprawdź, czy termin roszczenia lub odwołania upłynął';

  @override
  String get calcLimitationType => 'Rodzaj terminu';

  @override
  String get calcLimitationStart => 'Data początkowa (zdarzenie / decyzja)';

  @override
  String get calcLimitationPickDate => 'Wybierz datę';

  @override
  String get calcLimitationDeadline => 'Termin';

  @override
  String get calcLimitationExpired => 'Termin upłynął';

  @override
  String calcLimitationDaysLeft(int days) {
    return 'Pozostało $days dni';
  }

  @override
  String get calcLimitationShifted =>
      'Przesunięto na następny dzień roboczy (weekend/święto).';

  @override
  String get calcLimitationAddDeadline => 'Dodaj do terminów';

  @override
  String get calcStateFeeTitle => 'Opłaty sądowe / skarbowe';

  @override
  String get calcStateFeeDesc =>
      'Orientacyjne opłaty od pozwu według sądu i etapu';

  @override
  String get calcChildSupportTitle => 'Alimenty (orientacyjnie)';

  @override
  String get calcChildSupportDesc =>
      'Przybliżona wartość orientacyjna — rzeczywista kwota ustalana jest indywidualnie';

  @override
  String get calcChildSupportNet => 'Miesięczny dochód netto płatnika';

  @override
  String get calcChildSupportChildren => 'Liczba dzieci';

  @override
  String get calcChildSupportPerChild => 'Na dziecko';

  @override
  String get calcChildSupportTotal => 'Łącznie miesięcznie';

  @override
  String get calcChildSupportWarning =>
      'Bardzo zmienne. Sądy orzekają na podstawie potrzeb dziecka i możliwości płatniczych obojga rodziców. Traktuj jedynie jako punkt wyjścia.';

  @override
  String get docCollectTitle => 'Dokumenty do zebrania';

  @override
  String get docCollectSubtitle =>
      'Zbierz je, zanim złożysz wniosek lub pójdziesz do sądu';

  @override
  String get docCollectPickPrompt => 'Jaka jest Twoja sytuacja?';

  @override
  String get docCollectProblemResidence => 'Zezwolenie na pobyt';

  @override
  String get docCollectProblemTenant => 'Najem / eksmisja';

  @override
  String get docCollectProblemDismissal => 'Zwolnienie z pracy';

  @override
  String get docCollectProblemInheritance => 'Spadek';

  @override
  String get docCollectProblemDivorce => 'Rozwód';

  @override
  String docCollectProgress(int collected, int total) {
    return 'Zebrano $collected z $total';
  }

  @override
  String get docCollectAllDone => 'Wszystko zebrane';

  @override
  String get docCollectEmpty => 'Brak listy dokumentów dla tej sytuacji.';

  @override
  String get docCollectOptional => 'Opcjonalne';

  @override
  String get docCollectWhereLabel => 'Gdzie to uzyskać';

  @override
  String get docCollectWhyLabel => 'Dlaczego jest potrzebne';

  @override
  String get docCollectAttach => 'Dołącz plik';

  @override
  String get docCollectAttached => 'Plik dołączony';

  @override
  String get docCollectChangeFile => 'Zmień plik';

  @override
  String get docCollectRemoveFile => 'Usuń plik';

  @override
  String get docCollectNoFiles => 'Nie przesłałeś jeszcze żadnych dokumentów.';

  @override
  String get docCollectPickFileTitle => 'Wybierz przesłany dokument';

  @override
  String get docCollectExport => 'Eksportuj listę';

  @override
  String get docCollectExportSubject => 'Moja lista dokumentów';

  @override
  String get docCollectAiTitle => 'Potrzebujesz czegoś konkretnego?';

  @override
  String get docCollectAiHint =>
      'Opisz swoją sytuację, a zaproponujemy dodatkowe dokumenty.';

  @override
  String get docCollectAiField => 'Opisz swoją sytuację';

  @override
  String get docCollectAiButton => 'Zaproponuj dodatkowe dokumenty';

  @override
  String get docCollectAiLoading => 'Myślę…';

  @override
  String get docCollectAiEmpty =>
      'Nie zaproponowano dodatkowych dokumentów — podstawowa lista wygląda na kompletną dla Twojego opisu.';

  @override
  String get docCollectAiSuggestionsTitle => 'Proponowane dodatkowe dokumenty';

  @override
  String get docCollectDisclaimer =>
      'To podstawowa lista najczęściej wymaganych dokumentów — Twoja sytuacja może wymagać ich więcej lub mniej. To ogólne informacje, a nie porada prawna.';

  @override
  String get docCollectRetry => 'Spróbuj ponownie';

  @override
  String get renewalTitle => 'Radar Odnowień';

  @override
  String get renewalSubtitle =>
      'Śledź, kiedy wygasają Twoje zezwolenia, paszport, ubezpieczenie i inne dokumenty. Przypomnimy Ci 90, 30 i 7 dni przed każdym odnowieniem.';

  @override
  String get renewalAdd => 'Dodaj dokument';

  @override
  String get renewalEditTitle => 'Edytuj dokument';

  @override
  String get renewalSave => 'Zapisz';

  @override
  String get renewalRequired => 'Wymagane';

  @override
  String get renewalPickDate => 'Wybierz datę ważności';

  @override
  String get renewalLoadError =>
      'Nie udało się załadować dokumentów. Pociągnij, aby odświeżyć.';

  @override
  String get renewalEmptyTitle => 'Nie śledzisz jeszcze żadnych dokumentów';

  @override
  String get renewalEmptyBody =>
      'Dodaj zezwolenie na pobyt, paszport, ubezpieczenie lub prawo jazdy, a będziemy pilnować dat ważności za Ciebie.';

  @override
  String get renewalGuideHint => 'Jak odnowić →';

  @override
  String get renewalFieldType => 'Typ dokumentu';

  @override
  String get renewalFieldLabel => 'Etykieta';

  @override
  String get renewalFieldNumber => 'Numer dokumentu (opcjonalnie)';

  @override
  String get renewalFieldJurisdiction => 'Kraj wydania';

  @override
  String get renewalFieldExpiry => 'Data ważności';

  @override
  String get renewalWindow90 => '90 dni';

  @override
  String get renewalWindow30 => '30 dni';

  @override
  String get renewalWindow7 => '7 dni';

  @override
  String get renewalExpiresToday => 'Wygasa dzisiaj';

  @override
  String renewalExpiresInDays(int days, String date) {
    return 'Wygasa za $days dni · $date';
  }

  @override
  String renewalExpiredOn(String date) {
    return 'Wygasł $date';
  }

  @override
  String get renewalTypeResidencePermit => 'Zezwolenie na pobyt';

  @override
  String get renewalTypePassport => 'Paszport';

  @override
  String get renewalTypeIdCard => 'Dowód osobisty';

  @override
  String get renewalTypeVisa => 'Wiza';

  @override
  String get renewalTypeDrivingLicence => 'Prawo jazdy';

  @override
  String get renewalTypeInsurance => 'Ubezpieczenie';

  @override
  String get renewalTypeWorkPermit => 'Zezwolenie na pracę';

  @override
  String get renewalTypeOther => 'Inne';

  @override
  String get costEstimateTitle => 'Kalkulator kosztów i ryzyka';

  @override
  String get costEstimateSubtitle =>
      'Uzyskaj ogólne wyobrażenie, ile może kosztować sprawa, jak długo może potrwać i czy warto ją prowadzić.';

  @override
  String get costEstimateCaseTypeLabel => 'Rodzaj sprawy';

  @override
  String get costEstimateCaseTypeHint =>
      'np. niezapłacona faktura, bezprawne zwolnienie, spór o kaucję';

  @override
  String get costEstimateJurisdictionLabel => 'Jurysdykcja';

  @override
  String get costEstimateAmountLabel =>
      'Wartość przedmiotu sporu (opcjonalnie)';

  @override
  String get costEstimateAmountHint => 'np. 12500';

  @override
  String get costEstimateDescriptionLabel =>
      'Krótko opisz sytuację (opcjonalnie)';

  @override
  String get costEstimateB2bToggle => 'Karta kwalifikacji leada (B2B)';

  @override
  String get costEstimateB2bSubtitle =>
      'Zwięzły wynik do szybkiej segregacji napływającego klienta.';

  @override
  String get costEstimateSubmit => 'Oszacuj moją sprawę';

  @override
  String get costEstimateDisclaimer =>
      'Tylko orientacyjny szacunek — nie jest to prognoza, gwarancja ani porada prawna. Rzeczywiste koszty i wyniki różnią się w zależności od sprawy.';

  @override
  String get costEstimateCostsHeading => 'Szacowane koszty';

  @override
  String get costEstimateCourtFee => 'Opłata sądowa / skarbowa';

  @override
  String get costEstimateLawyerFee => 'Honorarium prawnika';

  @override
  String get costEstimateTotal => 'Łącznie (w przybliżeniu)';

  @override
  String get costEstimateDuration => 'Czas do pierwszego rozstrzygnięcia';

  @override
  String get costEstimateMonthsSuffix => 'mies.';

  @override
  String get costEstimateFactorsFor => 'Na Twoją korzyść';

  @override
  String get costEstimateFactorsAgainst => 'Przeciwko Tobie';

  @override
  String get costEstimateStrengthWorth => 'Prawdopodobnie warto prowadzić';

  @override
  String get costEstimateStrengthContested =>
      'Sporne — może pójść w obie strony';

  @override
  String get costEstimateStrengthWeak => 'Słabe — postępuj ostrożnie';
}
