// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get about => 'Про додаток';

  @override
  String get aboutSection => 'ПРО ДОДАТОК';

  @override
  String get accidents => 'Аварії';

  @override
  String get active => 'Активні';

  @override
  String get activeCases => 'Активні справи';

  @override
  String get addedToAppeal => 'Додано до апеляції';

  @override
  String get agreeToTerms => 'Я погоджуюся з ';

  @override
  String get aiAnalysis => 'Аналіз ШІ';

  @override
  String get aiAssistant => 'ШІ юридичний помічник';

  @override
  String get aiChat => 'Чат з ШІ';

  @override
  String get all => 'Усі';

  @override
  String get alreadyHaveAccount => 'Вже є обліковий запис? ';

  @override
  String get analyzing => 'Аналізується…';

  @override
  String get aiAnalyzing => 'AI is analyzing';

  @override
  String get speakIntoMicHint =>
      'Speak into the microphone. Make sure microphone access is enabled.';

  @override
  String get aiErrorRateLimit =>
      'Сервіс тимчасово перевантажений. Спробуйте через 1-2 хвилини.';

  @override
  String get aiErrorOverload => 'ШІ зараз зайнятий, спробуйте через хвилину.';

  @override
  String freeLimitReached(int count) {
    return 'You have used all $count free AI messages. Upgrade to Legal Counsel for unlimited AI assistance!';
  }

  @override
  String get andWord => ' та ';

  @override
  String get appTitle => 'Advocat — Інструмент юридичної інформації';

  @override
  String get appVersion => 'Версія додатку';

  @override
  String get appealFiled => 'Апеляцію подано';

  @override
  String get areYouAbsolutelySure => 'Ви абсолютно впевнені?';

  @override
  String get askAboutCase => 'Проаналізувати мою справу';

  @override
  String get asylum => 'Притулок';

  @override
  String get back => 'Назад';

  @override
  String get basic => 'Базовий';

  @override
  String get beforeYouBuy => 'Перед покупкою';

  @override
  String get beforeYouWork => 'Перед співпрацею з ними';

  @override
  String get camera => 'Камера';

  @override
  String get cancel => 'Скасувати';

  @override
  String get caseDescription => 'Опишіть вашу ситуацію';

  @override
  String get caseDetail => 'Деталі справи';

  @override
  String get caseOverview => 'Огляд справ';

  @override
  String get caseTitle => 'Назва справи';

  @override
  String get caseUpdated => 'Справу оновлено';

  @override
  String get cases => 'Справи';

  @override
  String get checkCompany => 'Перевірити компанію';

  @override
  String get checkDeadlines => 'Перевірити строки';

  @override
  String get checkVehicle => 'Перевірити транспорт';

  @override
  String get checkerTitle => 'Перевірка';

  @override
  String get checkingErrors => 'Перевірка помилок…';

  @override
  String get choosePlan => 'Обрати план';

  @override
  String get closed => 'Закриті';

  @override
  String get companyName => 'Назва компанії або реєстр. номер';

  @override
  String get completed => 'Завершено';

  @override
  String get confirm => 'Підтвердити';

  @override
  String get confirmPassword => 'Підтвердити пароль';

  @override
  String get connectEmail => 'Підключити пошту';

  @override
  String get connectGmail => 'Підключити Gmail';

  @override
  String get connectOutlook => 'Підключити Outlook';

  @override
  String get connected => 'Підключено';

  @override
  String get contactSupport => 'Зв\'язатися з підтримкою';

  @override
  String get continueWithGoogle => 'Продовжити з Google';

  @override
  String get copyText => 'Копіювати текст';

  @override
  String get correspondence => 'Кореспонденція';

  @override
  String get couldNotLoadCases => 'Не вдалося завантажити ваші справи';

  @override
  String get country => 'Країна';

  @override
  String get createAccount => 'Створити обліковий запис';

  @override
  String get createCase => 'Створити справу';

  @override
  String get criminalCase => 'Кримінальна справа';

  @override
  String get critical => 'Критичне';

  @override
  String get currentPlan => 'Поточний план';

  @override
  String get dataAndPrivacy => 'ДАНІ ТА КОНФІДЕНЦІЙНІСТЬ';

  @override
  String get dataExportRequested =>
      'Запит на експорт даних надіслано. Перевірте пошту.';

  @override
  String daysRemaining(int count) {
    return '$count днів';
  }

  @override
  String get deadlineReminders => 'Нагадування про строки';

  @override
  String get deadlineRemindersDesc =>
      'Отримуйте сповіщення перед закінченням строків';

  @override
  String get deadlines => 'Строки';

  @override
  String get debtCollection => 'Стягнення боргу';

  @override
  String get deleteAccount => 'Видалити обліковий запис';

  @override
  String get deleteAccountDesc => 'Назавжди видалити ваш обліковий запис';

  @override
  String get deleteAccountDialogContent =>
      'Ця дія є остаточною і не може бути скасована. Усі ваші дані, справи та документи будуть назавжди видалені.';

  @override
  String get deleteConfirm =>
      'Ви впевнені? Це назавжди видалить усі ваші дані.';

  @override
  String get demoHint => 'Демо: спробуйте номер «908FBT»';

  @override
  String get demoModeDesc =>
      'Ознайомтеся з додатком на прикладі реальної справи';

  @override
  String get deportation => 'Депортація';

  @override
  String get disclaimer =>
      'Лише інформація від ШІ — не юридична консультація. Завжди консультуйтеся з юристом.';

  @override
  String get disclaimerFull =>
      'Це ШІ-помічник, а не юрист. Аналіз ШІ може містити помилки. Завжди перевіряйте з кваліфікованим юристом.';

  @override
  String get disconnect => 'Відключити';

  @override
  String get discrimination => 'Дискримінація';

  @override
  String get doNotBuy => 'Не купуйте';

  @override
  String get documents => 'Документи';

  @override
  String documentsCount(int count) {
    return '$count документів';
  }

  @override
  String get draftAppeal => 'Проект апеляції';

  @override
  String get editDraft => 'Редагувати';

  @override
  String get editProfile => 'Редагувати профіль';

  @override
  String get email => 'Електронна пошта';

  @override
  String get emailConnected => 'Пошту підключено';

  @override
  String get emailDisconnected => 'Пошту відключено';

  @override
  String get emailIntegration => 'ІНТЕГРАЦІЯ ПОШТИ';

  @override
  String get emailInvalid => 'Введіть дійсну адресу електронної пошти';

  @override
  String get emailPrivacyNote =>
      'Ми читаємо лише юридичні листи. Ваша особиста пошта залишається приватною.';

  @override
  String get emailRequired => 'Електронна пошта обов\'язкова';

  @override
  String get emergencyShield => 'Екстрений захист';

  @override
  String get error => 'Помилка';

  @override
  String get exportDataDesc => 'Завантажити всі ваші дані про справи';

  @override
  String get exportDataDialogContent =>
      'Ми підготуємо завантаження всіх ваших даних, включаючи справи, документи та кореспонденцію. Ви отримаєте електронний лист, коли все буде готово.';

  @override
  String get exportMyData => 'Експортувати мої дані';

  @override
  String get exportPdf => 'Експорт PDF';

  @override
  String get familyReunification => 'Возз\'єднання сім\'ї';

  @override
  String get forgotPassword => 'Забули пароль?';

  @override
  String get free => 'Безкоштовно';

  @override
  String get fullDefense => 'Advocat Pro';

  @override
  String get fullName => 'Повне ім\'я';

  @override
  String get gallery => 'Галерея';

  @override
  String get generateAppeal => 'Створити апеляцію';

  @override
  String get getStarted => 'Розпочати';

  @override
  String goodAfternoon(String name) {
    return 'Добрий день, $name';
  }

  @override
  String goodEvening(String name) {
    return 'Добрий вечір, $name';
  }

  @override
  String goodMorning(String name) {
    return 'Доброго ранку, $name';
  }

  @override
  String goodNight(String name) {
    return 'Доброї ночі, $name';
  }

  @override
  String get home => 'Головна';

  @override
  String get important => 'Важливе';

  @override
  String get inProgress => 'В процесі';

  @override
  String get informational => 'Інформаційне';

  @override
  String get inspection => 'Технічний огляд';

  @override
  String get insurance => 'Страхування';

  @override
  String issuesFound(int count) {
    return '$count проблем знайдено';
  }

  @override
  String get laborDispute => 'Трудовий спір';

  @override
  String get langEnglish => 'Англійська';

  @override
  String get langFinnish => 'Фінська';

  @override
  String get langRussian => 'Російська';

  @override
  String get language => 'Мова';

  @override
  String lastActivity(String time) {
    return 'Остання активність: $time';
  }

  @override
  String get legalFighter => 'Юридичний радник';

  @override
  String get legalSection => 'ЮРИДИЧНЕ';

  @override
  String get licensePlate => 'Номерний знак';

  @override
  String get loading => 'Завантаження…';

  @override
  String get logIn => 'Увійти';

  @override
  String get loginFailed =>
      'Невірна електронна пошта або пароль. Спробуйте ще раз.';

  @override
  String get lost => 'Програно';

  @override
  String get markComplete => 'Позначити як завершене';

  @override
  String get mileage => 'Пробіг';

  @override
  String get myCases => 'Мої справи';

  @override
  String get nameRequired => 'Повне ім\'я обов\'язкове';

  @override
  String get newCase => 'Нова справа';

  @override
  String get next => 'Далі';

  @override
  String get noAccount => 'Немає облікового запису? ';

  @override
  String get noCases => 'Справ ще немає';

  @override
  String get noCasesYet => 'Справ ще немає';

  @override
  String get noDeadlines => 'Строків немає — усе в порядку.';

  @override
  String get noRecentActivity => 'Немає останньої активності';

  @override
  String get notifications => 'СПОВІЩЕННЯ';

  @override
  String get onboardingDesc1 =>
      'Advocat допомагає вам зрозуміти вашу правову ситуацію. Інструменти ШІ аналізують документи, визначають потенційні проблеми та готують проекти документів для вашого перегляду. Не юридична фірма — технологічний інструмент для підтримки вашої справи.';

  @override
  String get onboardingDesc2 =>
      'Сфотографуйте будь-який юридичний документ. ШІ прочитає його кількома мовами, витягне ключові деталі та перевірить на відповідність директивам ЄС та національному законодавству.';

  @override
  String get onboardingDesc3 =>
      'Наші інструменти ШІ перевіряють понад 40 типів процесуальних вимог. Аналіз ШІ може виявити питання, що потребують уваги — такі як мова повідомлення, процесуальні кроки та правові строки. Завжди перевіряйте з кваліфікованим юристом.';

  @override
  String get onboardingDesc4 =>
      'ШІ готує проекти апеляцій, скарг та листів із правовими посиланнями для вашого перегляду. Ви вирішуєте, що подавати. Кожен документ має бути перевірений кваліфікованим юристом перед поданням.';

  @override
  String get onboardingNext => 'Далі';

  @override
  String get onboardingSkip => 'Пропустити';

  @override
  String get onboardingTitle1 => 'Юридична інформація на базі ШІ';

  @override
  String get onboardingTitle2 => 'Скануйте та аналізуйте документи';

  @override
  String get onboardingTitle3 => 'ШІ перевіряє потенційні проблеми';

  @override
  String get onboardingTitle4 => 'Проекти документів для вашого перегляду';

  @override
  String get openACase => 'Відкрити справу';

  @override
  String get optional => '(необов\'язково)';

  @override
  String get orDivider => 'або';

  @override
  String get other => 'Інше';

  @override
  String get overdue => 'Прострочено';

  @override
  String get owners => 'Попередні власники';

  @override
  String get password => 'Пароль';

  @override
  String get passwordRequired => 'Пароль обов\'язковий';

  @override
  String get passwordStrengthMedium => 'Середній';

  @override
  String get passwordStrengthStrong => 'Сильний';

  @override
  String get passwordStrengthWeak => 'Слабкий';

  @override
  String get passwordTooShort => 'Пароль повинен містити щонайменше 8 символів';

  @override
  String get passwordsDoNotMatch => 'Паролі не збігаються';

  @override
  String get pendingDecision => 'Очікування рішення';

  @override
  String get perCheck => 'за перевірку';

  @override
  String get permanentlyDelete => 'Видалити назавжди';

  @override
  String get policeMisconduct => 'Неправомірні дії поліції';

  @override
  String get popular => 'ПОПУЛЯРНИЙ';

  @override
  String get preferences => 'НАЛАШТУВАННЯ';

  @override
  String get preferredLanguage => 'Бажана мова';

  @override
  String get pricePerCheck => '4,99 € за перевірку';

  @override
  String get privacyPolicy => 'Політикою конфіденційності';

  @override
  String get pro => 'Професійний';

  @override
  String get pushNotifications => 'Push-сповіщення';

  @override
  String get rateUs => 'Оцінити нас';

  @override
  String get rateAppComingSoon => 'Coming to app stores soon!';

  @override
  String get dataCopiedToClipboard => 'Data copied to clipboard';

  @override
  String get readingDocument => 'Читання документа…';

  @override
  String get recentActivity => 'Остання активність';

  @override
  String get referenceNumber => 'Номер довідки';

  @override
  String get registerFailed => 'Реєстрація не вдалася. Спробуйте ще раз.';

  @override
  String get reportFraud => 'Повідомити про шахрайство';

  @override
  String get requestExport => 'Запит на експорт';

  @override
  String get researchingLaw => 'Дослідження законодавства…';

  @override
  String get resetPasswordFailed =>
      'Не вдалося надіслати посилання для скидання. Спробуйте ще раз.';

  @override
  String get resetPasswordSent =>
      'Посилання для скидання пароля надіслано на вашу пошту.';

  @override
  String get residencePermit => 'Дозвіл на проживання';

  @override
  String get manageSubscription => 'Керування підпискою';

  @override
  String get restorePurchases => 'Відновити покупки';

  @override
  String get retry => 'Повторити';

  @override
  String get reviewWarning =>
      'Уважно перегляньте перед відправкою. Ви відповідаєте за зміст.';

  @override
  String get riskHigh => 'Високий ризик — уникайте';

  @override
  String get riskLow => 'Безпечна співпраця';

  @override
  String get riskMedium => 'Діяти обережно';

  @override
  String get safeToBuy => 'Безпечно купувати';

  @override
  String get saveAndAnalyze => 'Зберегти та аналізувати';

  @override
  String get saveDraft => 'Зберегти';

  @override
  String get saveWithAnnual => 'Заощаджуйте 25% з річною підпискою';

  @override
  String get scan => 'Сканувати';

  @override
  String get scanDocument => 'Сканувати документ';

  @override
  String get searchCases => 'Пошук справ…';

  @override
  String get selectCountry => 'Оберіть країну';

  @override
  String get selectLanguage => 'Оберіть мову';

  @override
  String get sendViaEmail => 'Надіслати електронною поштою';

  @override
  String get settings => 'Налаштування';

  @override
  String get signIn => 'Увійти';

  @override
  String get signInLink => 'Увійти';

  @override
  String get signInSubtitle => 'Увійдіть, щоб отримати доступ до ваших справ';

  @override
  String get signOut => 'Вийти';

  @override
  String get signOutConfirm => 'Ви впевнені, що хочете вийти?';

  @override
  String get signUp => 'Створити обліковий запис';

  @override
  String get signUpLink => 'Зареєструватися';

  @override
  String get socialBenefits => 'Соціальні виплати';

  @override
  String get someConcerns => 'Деякі занепокоєння';

  @override
  String get startFirstCase => 'Розпочніть вашу першу справу';

  @override
  String step(int current, int total) {
    return 'Крок $current з $total';
  }

  @override
  String get stolen => 'Перевірка на викрадення';

  @override
  String get subscription => 'Підписка';

  @override
  String get syncLegalCorrespondence =>
      'Синхронізувати юридичну кореспонденцію';

  @override
  String get syncNow => 'Синхронізувати зараз';

  @override
  String get tenantRights => 'Права орендаря';

  @override
  String get termsOfService => 'Умовами використання';

  @override
  String get termsRequired => 'Ви повинні погодитися з Умовами використання';

  @override
  String get timeline => 'Хронологія';

  @override
  String get tryDemoMode => 'Спробувати демо-режим';

  @override
  String get typeDeleteToConfirm =>
      'Введіть DELETE для підтвердження видалення облікового запису.';

  @override
  String get typeMessage => 'Введіть повідомлення…';

  @override
  String get upcoming => 'Найближчі';

  @override
  String get uploadDocument => 'Завантажити документ';

  @override
  String urgentDeadline(String title) {
    return 'Терміново: $title';
  }

  @override
  String get useInAppeal => 'Використати в апеляції';

  @override
  String get vehicleChecker => 'Перевірка транспорту';

  @override
  String get vehicleChecks => 'Перевірки стану';

  @override
  String get vehicleColor => 'Колір';

  @override
  String get vehicleMake => 'Марка';

  @override
  String get vehicleModel => 'Модель';

  @override
  String get vehicleYear => 'Рік';

  @override
  String get version => 'Версія';

  @override
  String get victimSupport => 'Підтримка постраждалих';

  @override
  String get viewAll => 'Переглянути все';

  @override
  String get vinNumber => 'VIN-код';

  @override
  String get welcomeBack => 'З поверненням';

  @override
  String get whatAreMyOptions => 'Які мої варіанти?';

  @override
  String get won => 'Виграно';

  @override
  String get documentVault => 'Сховище документів';

  @override
  String get secureDocumentStorage => 'Безпечне сховище документів';

  @override
  String get secureDocumentStorageDesc =>
      'Зберігайте важливі юридичні документи в одному місці.';

  @override
  String get addDocument => 'Додати документ';

  @override
  String get chooseHowToAdd => 'Оберіть спосіб додавання документа';

  @override
  String get uploadFile => 'Завантажити файл';

  @override
  String get uploadFileDesc => 'Виберіть PDF або зображення з пристрою';

  @override
  String get scanDocumentDesc => 'Сфотографуйте документ';

  @override
  String get createNote => 'Створити нотатку';

  @override
  String get createNoteDesc => 'Напишіть нотатку або зафіксуйте важливі деталі';

  @override
  String get knowYourRights => 'Знай свої права';

  @override
  String get stoppedByPolice => 'Зупинений поліцією';

  @override
  String get stoppedByPoliceDesc => 'Ваші права під час поліцейського контролю';

  @override
  String get deportationNotice => 'Повідомлення про депортацію';

  @override
  String get deportationNoticeDesc =>
      'Кроки для оскарження наказу про видалення';

  @override
  String get workplaceRights => 'Права на робочому місці';

  @override
  String get workplaceRightsDesc => 'Захист трудового права в Естонії';

  @override
  String get tenantRightsDesc => 'Захист житла та орендарів';

  @override
  String get immigrationDetention => 'Імміграційне затримання';

  @override
  String get immigrationDetentionDesc => 'Права при затриманні владою';

  @override
  String get discriminationDesc =>
      'Як повідомити про дискримінацію та боротися з нею';

  @override
  String get scenarioNotFound => 'Сценарій не знайдено';

  @override
  String get youHaveRightTo => 'Ви маєте право на:';

  @override
  String get youMust => 'Ви повинні:';

  @override
  String get immediateSteps => 'Негайні кроки:';

  @override
  String get yourRights => 'Ваші права:';

  @override
  String get basicRights => 'Основні права:';

  @override
  String get yourRightsAsTenant => 'Ваші права як орендаря:';

  @override
  String get yourRightsInDetention => 'Ваші права при затриманні:';

  @override
  String get howToAct => 'Як діяти:';

  @override
  String get rightKnowWhyStopped => 'Знати, чому вас зупинили';

  @override
  String get rightRemainSilent => 'Мовчати (необхідно назвати себе)';

  @override
  String get rightAskInterpreter => 'Попросіть перекладача';

  @override
  String get rightContactLawyer => 'Зв\'яжіться з адвокатом до допиту';

  @override
  String get rightRecordEncounter => 'Записати зустріч (у публічних місцях)';

  @override
  String get mustProvideName => 'Назвіть ім\'я та дату народження';

  @override
  String get mustShowId => 'Покажіть документ, якщо є';

  @override
  String get mustNotResist => 'Не чинити фізичний опір';

  @override
  String get doNotIgnoreNotice => 'НЕ ігноруйте повідомлення - терміни суворі';

  @override
  String get noteAppealDeadline =>
      'Зверніть увагу на термін оскарження (зазвичай 30 днів)';

  @override
  String get contactLawyerImmediately => 'Негайно зверніться до адвоката';

  @override
  String get applyLegalAid => 'Подайте заяву на правову допомогу за потреби';

  @override
  String get rightAppealAdmin => 'Право оскарження в Адміністративному суді';

  @override
  String get rightLegalRep => 'Право на юридичне представництво';

  @override
  String get rightInterpreter => 'Право на перекладача';

  @override
  String get rightStayDuringAppeal =>
      'Право залишитися під час оскарження (у більшості випадків)';

  @override
  String get minimumWage => 'Мінімальна зарплата за колективним договором';

  @override
  String get workingTimeLimits =>
      'Обмеження робочого часу (макс 8г/день, 40г/тиждень)';

  @override
  String get annualLeave =>
      'Щорічна відпустка (мінімум 2 дні за відпрацьований місяць)';

  @override
  String get sickLeave => 'Компенсація лікарняного';

  @override
  String get safeWorkingConditions => 'Безпечні умови праці';

  @override
  String get writtenRentalAgreement => 'Потрібен письмовий договір оренди';

  @override
  String get securityDeposit => 'Застава макс. 3 місяці оренди';

  @override
  String get landlordNotice => 'Орендодавець має попередити (3–6 місяців)';

  @override
  String get rightHabitableDwelling => 'Право на придатне для проживання житло';

  @override
  String get protectionUnjustEviction => 'Захист від несправедливого виселення';

  @override
  String get rightKnowDetentionReason => 'Право знати причину затримання';

  @override
  String get rightContactLawyerDetention => 'Право зв\'язатися з адвокатом';

  @override
  String get rightContactEmbassy => 'Право зв\'язатися з посольством';

  @override
  String get rightChallengeDetention => 'Право оскаржити затримання в суді';

  @override
  String get rightHumaneTreatment =>
      'Право на гуманне поводження та медичну допомогу';

  @override
  String get documentIncident => 'Задокументуйте інцидент (дата, час, свідки)';

  @override
  String get fileComplaintOmbudsman =>
      'Подайте скаргу омбудсмену з питань недискримінації';

  @override
  String get contactLegalAidOffice => 'Зверніться до бюро правової допомоги';

  @override
  String get reportToPolice =>
      'Повідомте поліцію, якщо злочин (погроза, напад)';

  @override
  String get legalAidCalculator => 'Калькулятор правової допомоги';

  @override
  String checkEligibility(String country) {
    return 'Перевірте право на правову допомогу: $country';
  }

  @override
  String get estimateDisclaimer =>
      'Це лише оцінка. Фактичне право визначає Бюро правової допомоги.';

  @override
  String get monthlyIncome => 'Місячний дохід (EUR)';

  @override
  String get totalAssets => 'Загальні активи (EUR)';

  @override
  String get numberOfDependents => 'Кількість утриманців';

  @override
  String get calculateEligibility => 'Розрахувати право';

  @override
  String get likelyEligible => 'Ймовірно має право';

  @override
  String get mayNotQualify => 'Може не мати права';

  @override
  String get fullFreeLegalAid =>
      'Ви, ймовірно, маєте право на безкоштовну правову допомогу.';

  @override
  String legalAidWithCopay(String percent) {
    return 'Ви можете мати право на правову допомогу зі співоплатою $percent%.';
  }

  @override
  String get mayNotQualifyDesc =>
      'За цією оцінкою ви можете не мати права на державну правову допомогу.';

  @override
  String get couldNotLoadDeadlines => 'Не вдалося завантажити терміни';

  @override
  String get noUpcomingDeadlines => 'Найближчих термінів немає';

  @override
  String get allClearDeadlines => 'Все гаразд! Нові терміни з\'являться тут.';

  @override
  String get nothingOverdue => 'Нічого не прострочено';

  @override
  String get greatJobDeadlines => 'Чудова робота з дотриманням термінів.';

  @override
  String get noCompletedDeadlines => 'Виконаних термінів немає';

  @override
  String get completedDeadlinesDesc =>
      'Виконані терміни відображатимуться тут.';

  @override
  String get daysLate => 'днів затримки';

  @override
  String get days => 'днів';

  @override
  String get fromDocument => 'З документа';

  @override
  String get couldNotLoadCase => 'Не вдалося завантажити деталі справи';

  @override
  String get typeLabel => 'Тип';

  @override
  String get nationality => 'Національність';

  @override
  String get migriReference => 'Посилання Migri';

  @override
  String get courtCaseNo => 'Номер судової справи';

  @override
  String get created => 'Створено';

  @override
  String get citizenship => 'Громадянство';

  @override
  String get workPermit => 'Дозвіл на роботу';

  @override
  String get noDocumentsYet => 'Документів ще не завантажено';

  @override
  String get noUpcomingDeadlinesShort => 'Найближчих термінів немає';

  @override
  String get caseCreated => 'Справу створено';

  @override
  String get decisionReceived => 'Рішення отримано';

  @override
  String get appealDeadline => 'Термін оскарження';

  @override
  String get hearingScheduled => 'Слухання заплановано';

  @override
  String get late => 'прострочено';

  @override
  String get pending => 'Очікує';

  @override
  String get processing => 'Обробка';

  @override
  String get ready => 'Готово';

  @override
  String get failed => 'Не вдалося';

  @override
  String get analyzed => 'Проаналізовано';

  @override
  String get noDocumentsScanHint =>
      'Документів ще немає. Скануйте або завантажте.';

  @override
  String get inCourt => 'У суді';

  @override
  String get appeal => 'Оскарження';

  @override
  String get caseTimeline => 'Хронологія справи';

  @override
  String get couldNotLoadTimeline => 'Не вдалося завантажити хронологію';

  @override
  String get noEventsYet => 'Подій ще немає';

  @override
  String get activityWillAppear =>
      'Активність з\'явиться тут у міру просування справи.';

  @override
  String caseCreatedDesc(String title) {
    return 'Справу «$title» створено.';
  }

  @override
  String get decisionReceivedDesc => 'Отримано офіційне рішення у цій справі.';

  @override
  String get appealDeadlineSet => 'Термін оскарження встановлено';

  @override
  String appealDeadlineDesc(String date) {
    return 'Оскарження має бути подано до $date.';
  }

  @override
  String hearingScheduledDesc(String date) {
    return 'Судове слухання заплановано на $date.';
  }

  @override
  String get caseInfoUpdated => 'Інформація справи оновлена.';

  @override
  String get documentAnalysis => 'Аналіз документа';

  @override
  String get exportAsPdf => 'Експортувати як PDF';

  @override
  String get pdfExportComingSoon => 'Експорт PDF незабаром';

  @override
  String get analysisFailedRetry => 'Аналіз не вдався. Спробуйте знову.';

  @override
  String get somethingWentWrong => 'Щось пішло не так';

  @override
  String get retryAnalysis => 'Повторити аналіз';

  @override
  String issuesFoundInDocument(int count) {
    return 'Знайдено $count проблем(и) у документі';
  }

  @override
  String get severityOverview => 'Огляд серйозності';

  @override
  String get issuesFoundHeader => 'Знайдені проблеми';

  @override
  String generateAppealWithIssues(int count) {
    return 'Створити оскарження ($count проблем)';
  }

  @override
  String get analyzingContent => 'Аналіз вмісту…';

  @override
  String get documentProcessedOk => 'Документ успішно оброблено';

  @override
  String get noSignificantIssues => 'Суттєвих проблем у документі не виявлено.';

  @override
  String get cameraPermissionRequired => 'Потрібен дозвіл камери';

  @override
  String get cameraPermissionDesc =>
      'Надайте доступ до камери для сканування документів або скористайтеся галереєю.';

  @override
  String get openSettings => 'Відкрити налаштування';

  @override
  String get alignDocument => 'Вирівняйте документ у рамці';

  @override
  String pageCount(int count) {
    return '$count сторінок';
  }

  @override
  String get preview => 'Попередній перегляд';

  @override
  String pageNumber(int number) {
    return 'Сторінка $number';
  }

  @override
  String get done => 'Готово';

  @override
  String get retake => 'Зробити знову';

  @override
  String get useThisPhoto => 'Використати це фото';

  @override
  String get addPage => 'Додати сторінку';

  @override
  String uploadingPercent(int percent) {
    return 'Завантаження… $percent%';
  }

  @override
  String get preparingUpload => 'Підготовка завантаження…';

  @override
  String get documentUploadedSuccess => 'Документ успішно завантажено';

  @override
  String pagesUploadedSuccess(int count) {
    return '$count сторінок успішно завантажено';
  }

  @override
  String get uploadFailed => 'Завантаження не вдалося. Перевірте з\'єднання.';

  @override
  String get capturePhotoFailed => 'Не вдалося зробити фото. Спробуйте знову.';

  @override
  String get readingText => 'Читання тексту…';

  @override
  String get draftDocument => 'Чернетка документа';

  @override
  String get saveChanges => 'Зберегти зміни';

  @override
  String get editDocument => 'Редагувати документ';

  @override
  String get generatingDraft => 'Створення чернетки…';

  @override
  String get generatingDraftDesc =>
      'ШІ готує юридичний документ на основі деталей справи.';

  @override
  String get failedToGenerateDraft =>
      'Не вдалося створити чернетку. Спробуйте знову.';

  @override
  String get changesSaved => 'Зміни збережено';

  @override
  String get copiedToClipboard => 'Скопійовано до буфера';

  @override
  String get emailComingSoon => 'Надсилання email незабаром';

  @override
  String get reviewBeforeSending =>
      'Уважно перегляньте перед надсиланням. Ви відповідаєте за зміст документа.';

  @override
  String get noContentAvailable => 'Вміст недоступний';

  @override
  String get save => 'Зберегти';

  @override
  String get edit => 'Редагувати';

  @override
  String get pdf => 'PDF';

  @override
  String get copy => 'Копіювати';

  @override
  String get appealDraft => 'Чернетка оскарження';

  @override
  String selected(int count) {
    return '$count вибрано';
  }

  @override
  String get deleteSelected => 'Видалити вибрані';

  @override
  String deleteDocumentsConfirm(int count) {
    return 'Видалити $count документів?';
  }

  @override
  String get delete => 'Видалити';

  @override
  String get analyzeSelected => 'Аналізувати вибрані';

  @override
  String get batchAnalysisStarting => 'Пакетний аналіз починається…';

  @override
  String get switchToList => 'Перемкнути на список';

  @override
  String get switchToGrid => 'Перемкнути на сітку';

  @override
  String get scanNew => 'Нове сканування';

  @override
  String get noDocumentsYetScan => 'Документів ще немає';

  @override
  String get scanFirstDocumentHint =>
      'Скануйте перший документ, щоб ШІ проаналізував його.';

  @override
  String get failedToLoadDocuments => 'Не вдалося завантажити документи';

  @override
  String get emailIntegrationTitle => 'Інтеграція email';

  @override
  String get connectYourEmail => 'Підключіть вашу пошту';

  @override
  String get connectYourEmailDesc =>
      'Підключіть email для автоматичного виявлення юридичного листування.';

  @override
  String get legalEmails => 'Юридичні листи';

  @override
  String get unlinkedEmails => 'Непов\'язані листи';

  @override
  String get noLegalEmailsYet => 'Юридичних листів ще немає';

  @override
  String get legalEmailsWillAppear =>
      'Листи, класифіковані як юридичні, з\'являться тут.';

  @override
  String get assignToCase => 'Призначити до справи';

  @override
  String get disconnectEmail => 'Від\'єднати email';

  @override
  String get disconnectEmailConfirm =>
      'Автоматична синхронізація email буде припинена. Раніше синхронізовані листи залишаться.';

  @override
  String get gmailReauthBannerBody =>
      'Advocat v2.1 reads your inbox to draft replies; you can revoke any time. Reconnect Gmail to enable proactive triage.';

  @override
  String get gmailReauthBannerCta => 'Reauthorize';

  @override
  String connectedTo(String email) {
    return 'Підключено до $email';
  }

  @override
  String lastSynced(String time) {
    return 'Остання синхронізація: $time';
  }

  @override
  String get filterByType => 'Фільтрувати за типом';

  @override
  String get noCasesMatchSearch => 'Жодна справа не відповідає пошуку';

  @override
  String get failedToLoadCases => 'Не вдалося завантажити справи';

  @override
  String get monthly => 'Щомісячний';

  @override
  String get annual => 'Річний';

  @override
  String get saveTwentyFivePercent => 'Заощадьте 25%';

  @override
  String get mostPopular => 'НАЙПОПУЛЯРНІШИЙ';

  @override
  String get oneCaseActive => '1 активна справа';

  @override
  String get threeCasesActive => '3 активні справи';

  @override
  String get unlimitedCases => 'Необмежені справи';

  @override
  String get threeDocScans => '3 сканування документів';

  @override
  String get twentyDocScans => '20 сканувань документів';

  @override
  String get unlimitedDocScans => 'Необмежене сканування';

  @override
  String get basicAiAnalysis => 'Базовий аналіз ШІ';

  @override
  String get fullAiAnalysis => 'Повний аналіз ШІ';

  @override
  String get draftGeneration => 'Створення чернеток';

  @override
  String get priorityProcessing => 'Пріоритетна обробка';

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
  String get forever => 'назавжди';

  @override
  String get perMonth => '/міс';

  @override
  String get perYear => '/рік';

  @override
  String get checkingPurchases => 'Перевірка попередніх покупок…';

  @override
  String get noPreviousPurchases => 'Попередні покупки не знайдено.';

  @override
  String get chatWelcomeMessage =>
      'Hi! I\'m Advocat — your AI legal assistant. I provide legal information, not legal advice. What legal question can I help with?';

  @override
  String get copySummary => 'Копіювати зведення';

  @override
  String get caseSummaryCopied => 'Зведення справи скопійовано';

  @override
  String get openCase => 'Відкрити справу';

  @override
  String get viewFull => 'Переглянути повністю';

  @override
  String get draftCopiedToClipboard => 'Чернетку скопійовано до буфера';

  @override
  String get reportMileageFraud => 'Повідомити про шахрайство з пробігом';

  @override
  String get reportMileageFraudDesc =>
      'Буде створено звіт про шахрайство на основі даних перевірки.';

  @override
  String get reportAndOpenCase => 'Повідомити та відкрити справу';

  @override
  String get caseCreationComingSoon =>
      'Створення справи з попередньо заповненими даними незабаром';

  @override
  String get failedToCreateCaseRetry =>
      'Не вдалося створити справу. Спробуйте знову.';

  @override
  String get takePhotoInstead => 'Зробити фото';

  @override
  String get deleteCase => 'Видалити справу';

  @override
  String deleteCaseConfirm(String title) {
    return 'Ви впевнені, що хочете видалити \"$title\"? Цю дію не можна скасувати.';
  }

  @override
  String get haveQuestionsAi => 'Є питання? Запитайте ШІ';

  @override
  String get cookiePolicy => 'Політика файлів cookie';

  @override
  String get aiDisclaimer => 'Застереження щодо ШІ';

  @override
  String get dataPrivacyConsent => 'Згода на обробку даних';

  @override
  String get gdprIntro =>
      'Для надання правової допомоги з ШІ ми обробляємо ваші дані відповідно до GDPR (ЄС 2016/679). Продовжуючи, ви погоджуєтесь з:';

  @override
  String get gdprChat => 'Обробка повідомлень чату ШІ';

  @override
  String get gdprDocs => 'Аналіз завантажених документів';

  @override
  String get gdprStorage => 'Зашифроване зберігання даних справ';

  @override
  String get gdprDelete => 'Право видалити свої дані в будь-який час';

  @override
  String get gdprFooter =>
      'Ваші дані зашифровані і ніколи не передаються третім особам. Ви можете відкликати згоду та видалити всі дані в Налаштуваннях.';

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
  String get aiGeneratedDisclaimer =>
      'Згенеровано ШІ • Не є юридичною консультацією';

  @override
  String get decline => 'Відхилити';

  @override
  String get iAgree => 'Погоджуюсь';

  @override
  String get iAgreeToThe => 'Я приймаю ';

  @override
  String get orWord => 'або';

  @override
  String get english => 'Англійська';

  @override
  String get russian => 'Російська';

  @override
  String get finnish => 'Фінська';

  @override
  String successSubscribed(String plan) {
    return 'Підписка на $plan успішна!';
  }

  @override
  String paymentFailed(String error) {
    return 'Помилка оплати: $error';
  }

  @override
  String get whatToDo => 'Що робити';

  @override
  String get getHelp => 'Отримати допомогу';

  @override
  String get share => 'Поділитися';

  @override
  String get didYouKnow => 'Чи знали ви?';

  @override
  String get mustKnow => 'Обов\'язково знати';

  @override
  String get goodToKnow => 'Корисно знати';

  @override
  String get sentFromAdvocat => 'Надіслано з додатку Advocat';

  @override
  String get policeActionStayCalm =>
      'Зберігайте спокій і тримайте руки на виду';

  @override
  String get policeActionAskWhy => 'Запитайте поліцейського, чому вас зупинили';

  @override
  String get policeActionProvideName => 'Назвіть своє ім\'я та дату народження';

  @override
  String get policeActionWantLawyer =>
      'Чітко заявіть: \"Я хочу адвоката перед будь-якими питаннями\"';

  @override
  String get policeActionAskInterpreter => 'За потреби попросіть перекладача';

  @override
  String get policeActionNoteBadge =>
      'Запишіть ім\'я та номер жетона поліцейського';

  @override
  String get policeFactMustTellReason =>
      'В Естонії поліція зобов\'язана повідомити причину зупинки. Якщо вони цього не роблять, ви можете запитати — і вони зобов\'язані за законом пояснити.';

  @override
  String get policeFactCanRecord =>
      'В Естонії ви можете записувати взаємодію з поліцією в громадських місцях. Це захищено свободою слова.';

  @override
  String get contactFinnishLegalAid => 'Державна правова допомога Естонії';

  @override
  String get contactNonDiscriminationOmbudsman =>
      'Уповноважений з питань недискримінації';

  @override
  String get deportationDeadlineAppeal =>
      'Оскарження до Адміністративного суду — зазвичай 30 днів з моменту повідомлення';

  @override
  String get deportationDeadlineLegalAid =>
      'Подайте заявку на правову допомогу — зробіть це НЕГАЙНО';

  @override
  String get deportationFactStayDuringAppeal =>
      'В Естонії ви зазвичай маєте право залишатися в країні під час розгляду вашого оскарження. Депортація не може бути здійснена під час активного оскарження у більшості випадків.';

  @override
  String get contactRefugeeAdviceCentre =>
      'Фінський центр консультування біженців';

  @override
  String get contactAdminCourtHelsinki => 'Адміністративний суд Гельсінкі';

  @override
  String get workplaceActionKeepContract =>
      'Зберігайте копії трудового договору';

  @override
  String get workplaceActionTrackHours => 'Самостійно відстежуйте робочий час';

  @override
  String get workplaceActionReportUnsafe =>
      'Повідомляйте про небезпечні умови до інспекції праці';

  @override
  String get workplaceActionJoinUnion => 'Вступіть до профспілки для захисту';

  @override
  String get workplaceActionContactAuthority =>
      'За потреби зверніться до Управління з охорони праці';

  @override
  String get workplaceFactCollectiveWage =>
      'В Естонії уряд встановлює державну мінімальну заробітну плату. Роботодавець зобов\'язаний платити не менше встановленого мінімуму.';

  @override
  String get workplaceFactOralContract =>
      'Навіть без письмового договору ви маєте повні трудові права в Естонії. Усна угода є однаково обов\'язковою за законом.';

  @override
  String get contactOccupationalSafety => 'Управління з охорони праці';

  @override
  String get contactTradeUnionSAK => 'Профспілкова консультація (SAK)';

  @override
  String get tenantActionWrittenAgreement =>
      'Завжди укладайте письмовий договір оренди';

  @override
  String get tenantActionDocumentCondition =>
      'Задокументуйте стан квартири при заселенні (фото)';

  @override
  String get tenantActionReportMaintenance =>
      'Повідомляйте про проблеми з обслуговуванням письмово';

  @override
  String get tenantActionNoIllegalEviction =>
      'Ніколи не погоджуйтесь на незаконне виселення — рішення приймає суд';

  @override
  String get tenantActionContactAdvisory =>
      'У разі спорів зверніться до консультаційної служби для орендарів';

  @override
  String get tenantFactNoEvictionWithoutCourt =>
      'Орендодавець в Естонії не може виселити вас без рішення суду, навіть якщо термін оренди закінчився. Заміна замків або відключення комунальних послуг є незаконним.';

  @override
  String get contactTenantsAssociation => 'Фінська асоціація орендарів';

  @override
  String get contactConsumerDisputesBoard => 'Комісія зі споживчих спорів';

  @override
  String get detentionActionAskDecision =>
      'Негайно вимагайте письмове рішення про затримання';

  @override
  String get detentionActionRequestLawyer => 'Вимагайте зв\'язку з адвокатом';

  @override
  String get detentionActionContactEmbassy =>
      'Зв\'яжіться зі своїм посольством або консульством';

  @override
  String get detentionActionAskMedical =>
      'За потреби вимагайте медичну допомогу';

  @override
  String get detentionActionRequestInterpreter =>
      'Вимагайте перекладача на всі засідання';

  @override
  String get detentionDeadlineCourtReview =>
      'Районний суд повинен переглянути затримання протягом 4 днів';

  @override
  String get detentionDeadlineContinuation =>
      'Суд переглядає продовження кожні 2 тижні';

  @override
  String get detentionFactCourtReview =>
      'Імміграційне затримання в Естонії повинно бути переглянуте районним судом протягом 4 днів. Якщо цього не відбувається, затримання стає незаконним.';

  @override
  String get contactParliamentaryOmbudsman => 'Парламентський омбудсмен';

  @override
  String get discriminationActionWriteDown =>
      'Запишіть точно, що сталося (дата, час, місце)';

  @override
  String get discriminationActionSaveEvidence =>
      'Збережіть докази: повідомлення, електронні листи, свідків';

  @override
  String get discriminationActionFileComplaint =>
      'Подайте скаргу Уповноваженому з питань недискримінації';

  @override
  String get discriminationActionContactLegalAid =>
      'Зверніться до бюро правової допомоги за безкоштовною консультацією';

  @override
  String get discriminationActionReportPolice =>
      'Зверніться до поліції, якщо мали місце погрози або напад';

  @override
  String get discriminationFactNonDiscriminationAct =>
      'Фінський Закон про недискримінацію охоплює дискримінацію за віком, походженням, громадянством, мовою, релігією, станом здоров\'я, інвалідністю, сексуальною орієнтацією та іншими особистими характеристиками.';

  @override
  String get contactVictimSupportRIKU => 'Служба допомоги жертвам (116 006)';

  @override
  String get domesticViolence => 'Домашнє насильство';

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
  String get inheritance => 'Спадщина';

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
  String get consumerProtection => 'Захист споживачів';

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
  String get caseTypeStepLabel => 'Тип справи';

  @override
  String get detailsStepLabel => 'Деталі';

  @override
  String get documentsStepLabel => 'Документи';

  @override
  String get whatTypeOfCase => 'Який тип справи?';

  @override
  String get selectCategoryDescription =>
      'Select the category that best describes your situation.';

  @override
  String get tellUsAboutCase => 'Розкажіть про вашу справу';

  @override
  String get aiHelpsUnderstand =>
      'This information helps our AI understand your situation better.';

  @override
  String get caseTitleHint => 'e.g., Residence Permit Appeal 2026';

  @override
  String get countryJurisdiction => 'Країна / Юрисдикція';

  @override
  String get selectCountryHint => 'Оберіть країну';

  @override
  String get referenceNumberHint => 'e.g., UMA/12345/2026';

  @override
  String get descriptionOptional => 'Description (optional)';

  @override
  String get descriptionHint =>
      'Describe your situation briefly. What happened? What decision was made?';

  @override
  String get uploadFirstDocument => 'Завантажте перший документ';

  @override
  String get uploadDocumentDescription =>
      'Upload the decision letter or any relevant document. You can skip this step and add documents later.';

  @override
  String get tapToUploadFile => 'Натисніть щоб завантажити файл';

  @override
  String get fileSizeLimit => 'PDF, JPG, PNG up to 25 MB';

  @override
  String get addDocumentsLaterHint =>
      'You can always add documents later from the case detail screen.';

  @override
  String get callAI => 'Зателефонувати ШІ';

  @override
  String get comingSoon => 'Незабаром';

  @override
  String get encrypted => 'Зашифровано';

  @override
  String get typing => 'Друкує…';

  @override
  String get online => 'Онлайн';

  @override
  String get chatWelcomeSubtitle =>
      'Я проаналізую вашу ситуацію та допоможу зрозуміти ваші права';

  @override
  String get tapMicrophoneToSpeak => 'Натисніть мікрофон щоб говорити';

  @override
  String get categoryEssential => 'Основне';

  @override
  String get categoryPolice => 'Поліція';

  @override
  String get categoryWork => 'Робота';

  @override
  String get categoryHousing => 'Житло';

  @override
  String get categoryConsumer => 'Споживач';

  @override
  String rightsInsideCount(int count) {
    return '$count прав всередині';
  }

  @override
  String get freeAidThreshold => 'Поріг безкоштовної допомоги';

  @override
  String get partialAidThreshold => 'Поріг часткової допомоги';

  @override
  String get assetLimit => 'Ліміт активів';

  @override
  String get whereToApplyLabel => 'Куди звертатися';

  @override
  String get phoneLabel => 'Телефон';

  @override
  String get websiteLabel => 'Вебсайт';

  @override
  String get disclaimerCollapsed => 'ШІ-помічник — не юридична консультація';

  @override
  String get disclaimerExpanded =>
      'ШІ-помічник надає правову інформацію, а не юридичну консультацію. Завжди перевіряйте у кваліфікованого юриста.';

  @override
  String get chatDisclaimerBanner =>
      'ШІ-помічник надає загальну правову інформацію. Це не замінює кваліфіковану юридичну консультацію.';

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
  String get guestUser => 'Гість';

  @override
  String get howToUse => 'Як користуватися?';

  @override
  String get tutorialStep1Title => 'ШІ-помічник із права';

  @override
  String get tutorialStep1Desc =>
      'Задайте будь-яке правове питання та отримайте миттєві відповіді на основі законів Естонії.';

  @override
  String get tutorialStep2Title => 'Знайте свої права';

  @override
  String get tutorialStep2Desc =>
      'Переглядайте правову інформацію за темами — робота, житло, права споживача та інше.';

  @override
  String get tutorialStep3Title => 'Сканування документів';

  @override
  String get tutorialStep3Desc =>
      'Фотографуйте юридичні документи для аналізу ШІ та безпечного зберігання.';

  @override
  String get tutorialStep4Title => 'Почнімо!';

  @override
  String get tutorialStep4Desc =>
      'Досліджуйте додаток та захищайте свої права. Усі дані залишаються на вашому пристрої.';

  @override
  String get advocatProTitle => 'Підписка Pro';

  @override
  String get advocatProSubtitle => 'Відкрийте всі можливості';

  @override
  String get voiceDisclaimer =>
      'Голосовий помічник наразі працює лише на комп\'ютері (браузер Chrome). Мобільна підтримка незабаром.';

  @override
  String get recommended => 'Рекомендовано';

  @override
  String get pleaseLogIn => 'Будь ласка, увійдіть';

  @override
  String get subscriptionNotFound => 'Підписку не знайдено';

  @override
  String errorWithMessage(String message) {
    return 'Помилка: $message';
  }

  @override
  String get redirectingToPayment => 'Перенаправлення на сторінку оплати…';

  @override
  String cheaperAnnually(String amount) {
    return '€$amount/міс. дешевше з річною підпискою';
  }

  @override
  String get navigatingTo => 'Відкриваю';

  @override
  String get stayInChat => 'Залишитися в чаті';

  @override
  String get backToChat => 'Назад до чату';

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
  String get feedbackThumbsUpLabel => 'Корисно';

  @override
  String get feedbackThumbsDownLabel => 'Не корисно';

  @override
  String get feedbackCommentPrompt => 'Що не так?';

  @override
  String get feedbackSend => 'Надіслати';

  @override
  String get feedbackCancel => 'Скасувати';

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
      'You\'ve used all 7 free messages this month.';

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
  String get citationStatusVerifiedBadge => 'Перевірено';

  @override
  String get citationStatusUnverifiedBadge => 'Не перевірено';

  @override
  String get citationStatusHistoricalBadge => 'Історична редакція';

  @override
  String get citationStatusVerifiedTooltip =>
      'Цитата з відновленого правового джерела.';

  @override
  String get citationStatusUnverifiedTooltip =>
      'ШІ навів цей фрагмент без відновлення джерела — перевірте перед використанням.';

  @override
  String get citationStatusHistoricalTooltip =>
      'Цитоване положення вже не чинне.';

  @override
  String get citationOpenInRiigiTeataja => 'Відкрити в Riigi Teataja';

  @override
  String get citationSnippetExpand => 'Показати повний текст';

  @override
  String get citationSnippetCollapse => 'Згорнути';

  @override
  String get citationUnverifiedSheetNote =>
      'ШІ навів цей пункт, проте у цій сесії його не було відновлено з правового корпусу. Перевірте посилання, перш ніж на нього спиратися.';

  @override
  String get citationFooterNoneWarning => 'Немає підтверджених посилань';

  @override
  String citationFooterSummaryTotal(int count) {
    return '$count посилань';
  }

  @override
  String citationFooterSummaryVerified(int count) {
    return '$count перевірено';
  }

  @override
  String citationFooterSummaryUnverified(int count) {
    return '$count не перевірено';
  }

  @override
  String citationFooterSummaryHistorical(int count) {
    return '$count історичних';
  }

  @override
  String get deadlineRadarTitle => 'Upcoming deadlines';

  @override
  String get deadlineRadarEmpty => 'No upcoming deadlines';

  @override
  String get deadlineRadarViewAll => 'View all';

  @override
  String deadlineCardDaysLeft(int count) {
    return 'in $count days';
  }

  @override
  String get deadlineCardTomorrow => 'tomorrow';

  @override
  String get deadlineCardToday => 'today';

  @override
  String deadlineCardOverdue(int count) {
    return '$count days overdue';
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
  String get supportTitle => 'Need help?';

  @override
  String get supportSubtitle => 'We usually reply within 1-2 hours.';

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
  String get reviewThisContract => 'Розібрати договір';

  @override
  String get contractReviews => 'Перевірки договорів';

  @override
  String get contractReviewsFreeFeature =>
      '1 перевірка договору (пробна назавжди)';

  @override
  String get contractReviewsCounselFeature => '5 перевірок договорів на місяць';

  @override
  String get contractReviewsProFeature => '20 перевірок договорів на місяць';

  @override
  String contractReviewsLeft(int count) {
    return 'Залишилось $count перевірок договорів цього місяця';
  }

  @override
  String get contractReviewsExhausted =>
      'Цього місяця перевірок договорів не залишилось';

  @override
  String get contractReviewsFreeTrialLeft =>
      'Пробна версія: 1 перевірка договору';

  @override
  String get contractReviewsFreeTrialUsed =>
      'Пробну версію використано — оновіть план';

  @override
  String get contractReviewsUpgradeTitle => 'Перевірки договорів вичерпано';

  @override
  String get contractReviewsUpgradeBodyFree =>
      'Ви використали безкоштовну перевірку договору. Оновіть план для щомісячних перевірок.';

  @override
  String contractReviewsUpgradeBodyPaid(int used, int cap) {
    return 'Ви використали $used з $cap перевірок цього місяця. Оновіть план для більшого ліміту.';
  }

  @override
  String get contractReviewsUpgradeCounselCta =>
      'Перейти на Counsel (€19,99/міс) — 5 перевірок';

  @override
  String get contractReviewsUpgradeProCta =>
      'Перейти на Pro (€29,99/міс) — 20 перевірок';

  @override
  String get contractReviewsUpgradeToProShort => 'Перейти на Pro — 20/міс';

  @override
  String get notNow => 'Не зараз';

  @override
  String get referralTitle => 'Запросити друзів';

  @override
  String get referralSubtitle =>
      'Отримай безплатний місяць. Подаруй безплатний місяць.';

  @override
  String get referralYourLink => 'ВАШЕ ПОСИЛАННЯ';

  @override
  String get referralCopyLink => 'Копіювати посилання';

  @override
  String get referralShare => 'Поділитися';

  @override
  String get referralLinkCopied => 'Посилання скопійоване';

  @override
  String get referralStatsInvited => 'Запрошено';

  @override
  String get referralStatsConverted => 'Приєдналося';

  @override
  String get referralStatsEarned => 'Безплатних місяців';

  @override
  String get referralShareWhatsApp => 'Поділитися у WhatsApp';

  @override
  String get referralShareTelegram => 'Поділитися в Telegram';

  @override
  String get referralShareEmail => 'Надіслати email';

  @override
  String get referralEmailSubject => 'Спробуй Advocat — твій ШІ-юрист';

  @override
  String get referralLoadError =>
      'Не вдалося завантажити дані. Потягніть униз.';

  @override
  String get referralRetry => 'Повторити';

  @override
  String get referralSettingsTile => 'Запросити друзів';

  @override
  String get referralAfterReviewCta =>
      'Сподобалось? Запроси друга — обидва отримаєте безплатний місяць.';
}
