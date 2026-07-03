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
  String get appearance => 'Вигляд';

  @override
  String get appearanceSystem => 'Системний (авто)';

  @override
  String get appearanceLight => 'Світлий';

  @override
  String get appearanceDark => 'Темний';

  @override
  String get appearanceDescription => 'Оберіть, як виглядатиме Advocat';

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
  String get aiAnalyzing => 'ШІ аналізує';

  @override
  String get speakIntoMicHint =>
      'Говоріть у мікрофон. Переконайтеся, що доступ до мікрофона ввімкнено.';

  @override
  String get aiErrorRateLimit =>
      'Сервіс тимчасово перевантажений. Спробуйте через 1-2 хвилини.';

  @override
  String get aiErrorOverload => 'ШІ зараз зайнятий, спробуйте через хвилину.';

  @override
  String freeLimitReached(int count) {
    return 'Ви використали всі $count безкоштовних повідомлень ШІ. Перейдіть на Legal Counsel для необмеженої допомоги ШІ!';
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
  String get appleComingSoon => 'Незабаром';

  @override
  String get appleComingSoonMessage =>
      'Вхід через Apple стане доступним незабаром. Скористайтеся Google або електронною поштою, щоб продовжити.';

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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count днів',
      many: '$count днів',
      few: '$count дні',
      one: '$count день',
      zero: 'днів не залишилось',
    );
    return '$_temp0';
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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count документів',
      many: '$count документів',
      few: '$count документи',
      one: '$count документ',
      zero: 'немає документів',
    );
    return '$_temp0';
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
  String get inProgress => 'У процесі';

  @override
  String get informational => 'Інформаційне';

  @override
  String get inspection => 'Технічний огляд';

  @override
  String get insurance => 'Страхування';

  @override
  String issuesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Знайдено $count проблем',
      many: 'Знайдено $count проблем',
      few: 'Знайдено $count проблеми',
      one: 'Знайдено $count проблему',
      zero: 'проблем не знайдено',
    );
    return '$_temp0';
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
  String get dpaTitle => 'Угода про обробку даних';

  @override
  String get dpaCheckoutGateTitle => 'Перш ніж оновити план';

  @override
  String get dpaCheckoutGateBody =>
      'Законодавство ЄС (ст. 28 GDPR) вимагає від нас укласти Угоду про обробку даних з кожним платним клієнтом. Будь ласка, ознайомтеся та прийміть її.';

  @override
  String get dpaViewLink => 'Переглянути Угоду про обробку даних';

  @override
  String get dpaCheckboxLabel =>
      'Я прочитав(-ла) і приймаю Угоду про обробку даних (v1.0).';

  @override
  String get dpaCancel => 'Скасувати';

  @override
  String get dpaAcceptAndContinue => 'Прийняти та продовжити';

  @override
  String get dpaOpenHint =>
      'Відкрийте Угоду про обробку даних хоча б раз, щоб активувати кнопку «Прийняти».';

  @override
  String get pro => 'Професійний';

  @override
  String get pushNotifications => 'Push-сповіщення';

  @override
  String get rateUs => 'Оцінити нас';

  @override
  String get rateAppComingSoon => 'Незабаром у магазинах застосунків!';

  @override
  String get dataCopiedToClipboard => 'Дані скопійовано в буфер обміну';

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
  String get noEventsForFilter => 'Немає подій, що відповідають цьому фільтру';

  @override
  String get timelineFilterAll => 'Усі';

  @override
  String get timelineFilterEmails => 'Електронні листи';

  @override
  String get timelineFilterConsilium => 'Рішення ШІ';

  @override
  String get timelineFilterDeadlines => 'Строки';

  @override
  String get timelineFilterNotes => 'Нотатки';

  @override
  String get timelineEventEmailIn => 'Лист отримано';

  @override
  String get timelineEventEmailOut => 'Лист надіслано';

  @override
  String get timelineEventConsiliumDecision => 'Рішення ШІ';

  @override
  String get timelineEventDeadlineSet => 'Строк';

  @override
  String get timelineEventDocUploaded => 'Документ';

  @override
  String get timelineEventPhaseChange => 'Зміна етапу';

  @override
  String get timelineEventManualNote => 'Нотатка';

  @override
  String get timelineJustNow => 'Щойно';

  @override
  String timelineMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count хвилин тому',
      many: '$count хвилин тому',
      few: '$count хвилини тому',
      one: '$count хвилину тому',
    );
    return '$_temp0';
  }

  @override
  String timelineHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count годин тому',
      many: '$count годин тому',
      few: '$count години тому',
      one: '$count годину тому',
    );
    return '$_temp0';
  }

  @override
  String timelineDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count днів тому',
      many: '$count днів тому',
      few: '$count дні тому',
      one: '$count день тому',
    );
    return '$_temp0';
  }

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
  String get genericError => 'Щось пішло не так. Спробуйте ще раз.';

  @override
  String get retryAnalysis => 'Повторити аналіз';

  @override
  String issuesFoundInDocument(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'У документі знайдено $count проблем',
      many: 'У документі знайдено $count проблем',
      few: 'У документі знайдено $count проблеми',
      one: 'У документі знайдено $count проблему',
      zero: 'У документі проблем не знайдено',
    );
    return '$_temp0';
  }

  @override
  String get severityOverview => 'Огляд серйозності';

  @override
  String get issuesFoundHeader => 'Знайдені проблеми';

  @override
  String generateAppealWithIssues(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Створити оскарження ($count проблем)',
      many: 'Створити оскарження ($count проблем)',
      few: 'Створити оскарження ($count проблеми)',
      one: 'Створити оскарження ($count проблема)',
    );
    return '$_temp0';
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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count сторінок',
      many: '$count сторінок',
      few: '$count сторінки',
      one: '$count сторінка',
      zero: 'немає сторінок',
    );
    return '$_temp0';
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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count сторінок успішно завантажено',
      many: '$count сторінок успішно завантажено',
      few: '$count сторінки успішно завантажено',
      one: '$count сторінка успішно завантажена',
    );
    return '$_temp0';
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
      'Advocat v2.1 читає вашу поштову скриньку, щоб готувати відповіді; ви можете відкликати доступ будь-коли. Повторно підключіть Gmail, щоб увімкнути проактивне сортування.';

  @override
  String get gmailReauthBannerCta => 'Повторно авторизувати';

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
  String get fiveAiMessagesTotal => '5 повідомлень ШІ (на весь час)';

  @override
  String get hundredAiMessagesDay => '100 повідомлень ШІ/день';

  @override
  String get unlimitedAiMessages => 'Необмежені повідомлення ШІ';

  @override
  String get voiceInput => 'Голосове введення';

  @override
  String get strategyRecommendations => 'Стратегічні рекомендації';

  @override
  String get foundingMemberNote => 'Засновник: 9,99 €/міс перші 3 місяці';

  @override
  String get saveTwentyPercent => 'Заощаджуйте 20%';

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
      'Вітаю! Я Advocat — ваш ШІ-помічник з юридичних питань. Я надаю юридичну інформацію, а не юридичну консультацію. Чим можу допомогти?';

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
  String get aiDisclaimerCompact =>
      'Advocat надає юридичну інформацію на основі ШІ, а не юридичну консультацію. Перед дією перевірте інформацію з ліцензованим юристом.';

  @override
  String get aiDisclaimerFullTitle => 'Важливо: як працює Advocat';

  @override
  String get aiDisclaimerFullBody =>
      'Advocat — це інструмент на основі штучного інтелекту, який надає юридичну інформацію, а не юридичну консультацію. Відповідно до Закону ЄС про штучний інтелект (ст. 50) ми зобов\'язані чітко повідомити: ви спілкуєтеся зі ШІ, а не з юристом-людиною.\n\nAdvocat не є юридичною фірмою. Ми не є ліцензованими адвокатами відповідно до естонського Advokatuuriseadus чи фінського Asianajajalaki, і адвокатська таємниця не поширюється на ваше спілкування з цим інструментом. Перш ніж покладатися на будь-яку відповідь — щоб подати апеляцію, підписати договір чи діяти у зв\'язку з дедлайном — перевірте інформацію з ліцензованим юристом у вашій юрисдикції.';

  @override
  String get aiDisclaimerExpand => 'Дізнатися більше';

  @override
  String get aiDisclaimerDismiss => 'Зрозуміло';

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
      'Я погоджуюся на обробку моїх даних для правової допомоги ШІ (обов’язково)';

  @override
  String get gdprConsentAnalytics =>
      'Я погоджуюся на аналітику для покращення сервісу (необов’язково)';

  @override
  String get gdprArt9Intro =>
      'Цей застосунок обробляє особливі категорії персональних даних згідно зі статтею 9 GDPR, зокрема:';

  @override
  String get gdprSpecialLegalCases =>
      'Деталі вашої правової справи та судові документи';

  @override
  String get gdprSpecialNationality => 'Громадянство та імміграційний статус';

  @override
  String get gdprConsentLegalData =>
      'Я даю згоду на обробку даних моєї правової справи, громадянства та імміграційного статусу за допомогою ШІ (обов’язково)';

  @override
  String get gdprConsentVoice =>
      'Я даю згоду на обробку голосового запису (необов’язково)';

  @override
  String get gdprViewPrivacyPolicy => 'Переглянути Політику конфіденційності';

  @override
  String get legalInformation => 'Юридична інформація';

  @override
  String get legalEntityName => 'Vorantis OÜ';

  @override
  String get legalRegistryCode => 'Реєстраційний код: 17098992';

  @override
  String get legalAddress =>
      'Harju maakond, Tallinn, Kesklinna linnaosa, Tornimäe tn 5, 10145';

  @override
  String get legalEmail => 'Електронна пошта: support@advocat.ee';

  @override
  String get legalRegistry =>
      'Зареєстровано в Естонському комерційному реєстрі (Äriregister)';

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
      'Права потерпілих, екстрена допомога, заборонні приписи';

  @override
  String get rightCallEmergency =>
      'Ви маєте право зателефонувати 112 у будь-якій надзвичайній ситуації — поліція, швидка допомога, пожежна служба';

  @override
  String get rightVictimProtection =>
      'Як потерпілий(-а), ви маєте право на захист, підтримку та інформацію про вашу справу';

  @override
  String get rightRestrainingOrder =>
      'Ви можете подати заяву на заборонний припис (lähestymiskielto), щоб тримати кривдника на відстані';

  @override
  String get rightVictimInterpreter =>
      'Ви маєте право на перекладача під час усіх правових процедур';

  @override
  String get rightMedicalHelp =>
      'Ви маєте право на негайну медичну допомогу та документування травм';

  @override
  String get rightShelter =>
      'Ви маєте право на екстрене укриття — зверніться до притулку або соціальних служб';

  @override
  String get mustReportDanger =>
      'Якщо хтось перебуває в безпосередній небезпеці, негайно телефонуйте 112';

  @override
  String get mustDocumentInjuries =>
      'Задокументуйте всі травми — фотографії, медичні записи, письмові нотатки';

  @override
  String get domesticActionCallEmergency =>
      'Телефонуйте 112, якщо ви в безпосередній небезпеці';

  @override
  String get domesticActionGoToSafe =>
      'Перейдіть у безпечне місце — притулок, до друга, публічне місце';

  @override
  String get domesticActionDocumentEverything =>
      'Задокументуйте травми: зробіть фотографії, отримайте медичні записи';

  @override
  String get domesticActionFilePoliceReport =>
      'Подайте заяву до поліції — це можна зробити й пізніше';

  @override
  String get domesticActionContactShelter =>
      'Зверніться до притулку або кризової лінії допомоги';

  @override
  String get domesticActionApplyRestraining =>
      'Подайте заяву на заборонний припис через поліцію або суд';

  @override
  String get domesticFactRestrainingOrder =>
      'У Фінляндії заборонний припис (lähestymiskielto) може бути виданий навіть без кримінальної справи. Він забороняє особі контактувати з вами або наближатися до вас.';

  @override
  String get domesticFactVictimDirective =>
      'Згідно з Директивою ЄС про права потерпілих 2012/29/EU ви маєте право на повагу, на отримання інформації мовою, яку розумієте, та на доступ до служб підтримки потерпілих — незалежно від вашого статусу проживання.';

  @override
  String get domesticDeadlinePoliceReport =>
      'Подання заяви до поліції — суворого строку немає, але чим раніше, тим краще для доказів';

  @override
  String get domesticDeadlineRestraining =>
      'Заборонний припис — можна подати заяву будь-коли';

  @override
  String get contactEmergency => 'Екстрений номер';

  @override
  String get contactShelter => 'Лінія допомоги Turvakoti (Притулок)';

  @override
  String get contactCrisisHelpline => 'Кризова лінія допомоги (Kriisipuhelin)';

  @override
  String get contactNollaLinja =>
      'Nollalinja — Лінія допомоги щодо насильства над жінками';

  @override
  String get inheritance => 'Спадщина';

  @override
  String get inheritanceDesc =>
      'Заповіти, спадщина, права спадкоємців, обов\'язкова частка, спадкове провадження';

  @override
  String get rightInheritanceForced =>
      'Обов\'язкові спадкоємці (діти, подружжя) мають право на обов\'язкову частку незалежно від заповіту';

  @override
  String get rightInheritanceWill =>
      'Ви маєте право скласти заповіт щодо розпорядження вашим майном — нотаріально посвідчені заповіти мають найбільшу юридичну силу';

  @override
  String get rightInheritanceRenounce =>
      'Ви можете відмовитися від спадщини протягом 3 місяців з моменту, коли дізналися про неї';

  @override
  String get rightInheritanceInfo =>
      'Ви маєте право отримувати інформацію про спадкове майно від банків і реєстрів';

  @override
  String get rightInheritanceDispute =>
      'Ви можете оскаржити несправедливий заповіт у суді протягом встановленого строку позовної давності';

  @override
  String get mustFileInheritance =>
      'Подайте заяву про відкриття спадкового провадження нотаріусу протягом розумного строку';

  @override
  String get mustNotifyHeirs =>
      'Усі відомі спадкоємці мають бути повідомлені про спадкове провадження';

  @override
  String get inheritanceActionGatherDocs =>
      'Зберіть усі документи: свідоцтво про смерть, заповіт, документи на майно, банківські виписки';

  @override
  String get inheritanceActionContactNotary =>
      'Зверніться до нотаріуса для відкриття спадкового провадження';

  @override
  String get inheritanceActionCheckDebts =>
      'Перевірте, чи є у спадщини борги, перш ніж її приймати';

  @override
  String get inheritanceActionFileCourt =>
      'Якщо заповіт оскаржується, подайте позов до суду';

  @override
  String get inheritanceDeadlineRenounce =>
      '3 місяці на відмову від спадщини з моменту, коли про неї дізналися';

  @override
  String get inheritanceDeadlineDispute =>
      'Строк позовної давності для оскарження заповіту: залежить від підстав';

  @override
  String get inheritanceFactForced =>
      'В Естонії нащадки та подружжя мають право на обов\'язкову частку (1/2 законної частки), навіть якщо їх виключено із заповіту';

  @override
  String get inheritanceFactNotary =>
      'Усі спадкові провадження в Естонії мають проходити через нотаріуса — цей етап неможливо пропустити';

  @override
  String get consumerProtection => 'Захист споживачів';

  @override
  String get consumerProtectionDesc =>
      'Шахрайство, дефектні товари, повернення, недобросовісні продавці';

  @override
  String get rightReturnOnline =>
      'Ви маєте 14 днів, щоб скасувати онлайн-покупки без пояснення причин (право ЄС на відмову)';

  @override
  String get rightDefectiveProduct =>
      'Якщо товар дефектний, ви маєте право на ремонт, заміну або повернення коштів';

  @override
  String get rightClearPricing =>
      'Продавці повинні чітко вказувати ціни, включно з усіма зборами — приховані витрати незаконні';

  @override
  String get rightComplainBoard =>
      'Ви можете безкоштовно подати скаргу до Ради зі споживчих спорів';

  @override
  String get rightProtectionFraud =>
      'Ви захищені від недобросовісних комерційних практик і шахрайства';

  @override
  String get mustKeepReceipts =>
      'Зберігайте всі чеки, договори та листування з продавцями';

  @override
  String get mustActTimely =>
      'Повідомляйте продавця про дефекти протягом розумного строку після їх виявлення';

  @override
  String get consumerActionKeepEvidence =>
      'Зберігайте чеки, знімки екрана, листи та всі докази покупки';

  @override
  String get consumerActionContactSeller =>
      'Спершу зверніться до продавця — поясніть проблему письмово';

  @override
  String get consumerActionFileComplaint =>
      'Подайте скаргу до Ради зі споживчих спорів (kuluttajariitalautakunta)';

  @override
  String get consumerActionContactAuthority =>
      'Зверніться до Консультаційної служби для споживачів по безкоштовну допомогу';

  @override
  String get consumerActionReportFraud =>
      'Повідомте про шахрайство до поліції та Омбудсмена з прав споживачів';

  @override
  String get consumerFactWithdrawal =>
      'Згідно з Директивою ЄС про права споживачів 2011/83/EU ви маєте 14 днів, щоб відмовитися від будь-якої онлайн- чи дистанційної покупки — без пояснення причин. Продавець повинен повернути вам кошти протягом 14 днів.';

  @override
  String get consumerFactWarranty =>
      'У Фінляндії продавець відповідає за дефекти товару протягом розумного строку (часто 2+ роки). Це окремо від будь-якої гарантії виробника.';

  @override
  String get consumerDeadlineWithdrawal =>
      'Відмова від онлайн-покупки — 14 днів з моменту доставки';

  @override
  String get consumerDeadlineDefect =>
      'Повідомлення продавця про дефект — протягом 2 місяців з моменту виявлення (рекомендовано)';

  @override
  String get contactConsumerAdvisory => 'Консультаційна служба для споживачів';

  @override
  String get contactConsumerOmbudsman =>
      'Омбудсмен з прав споживачів (Kuluttaja-asiamies)';

  @override
  String get contactConsumerDisputesBoardDirect => 'Рада зі споживчих спорів';

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
      'Оберіть категорію, яка найкраще описує вашу ситуацію.';

  @override
  String get tellUsAboutCase => 'Розкажіть про вашу справу';

  @override
  String get aiHelpsUnderstand =>
      'Ця інформація допомагає нашому ШІ краще зрозуміти вашу ситуацію.';

  @override
  String get caseTitleHint =>
      'напр., Оскарження відмови у виді на проживання, 2026';

  @override
  String get countryJurisdiction => 'Країна / Юрисдикція';

  @override
  String get selectCountryHint => 'Оберіть країну';

  @override
  String get referenceNumberHint => 'напр., UMA/12345/2026';

  @override
  String get descriptionOptional => 'Опис (необов\'язково)';

  @override
  String get descriptionHint =>
      'Коротко опишіть вашу ситуацію. Що сталося? Яке рішення було прийнято?';

  @override
  String get uploadFirstDocument => 'Завантажте перший документ';

  @override
  String get uploadDocumentDescription =>
      'Завантажте лист-рішення або будь-який відповідний документ. Цей крок можна пропустити й додати документи пізніше.';

  @override
  String get tapToUploadFile => 'Натисніть щоб завантажити файл';

  @override
  String get fileSizeLimit => 'PDF, JPG, PNG до 25 МБ';

  @override
  String get addDocumentsLaterHint =>
      'Ви завжди можете додати документи пізніше з екрана деталей справи.';

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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count прав всередині',
      many: '$count прав всередині',
      few: '$count права всередині',
      one: '$count право всередині',
      zero: 'немає прав всередині',
    );
    return '$_temp0';
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
  String get chatDisclaimerSubtitle => 'ШІ-помічник · не юридична консультація';

  @override
  String get chatDisclaimerBannerFull =>
      'Advocat — це ШІ-помічник із правової інформації, а не юрист. Ця інформація не створює відносин адвокат–клієнт, не є юридичною консультацією та може містити помилки. Для отримання обов\'язкової юридичної поради зверніться до ліцензованого адвоката у вашій юрисдикції. Ми вас не представляємо.';

  @override
  String get chatDisclaimerFooter =>
      'Створено ШІ. Перевірте у ліцензованого адвоката.';

  @override
  String get chatDisclaimerGotIt => 'Зрозуміло';

  @override
  String get categoryChildren => 'Діти';

  @override
  String get categoryDigital => 'Цифрове';

  @override
  String get childrenRights => 'Права дітей та аліменти';

  @override
  String get childrenRightsDesc =>
      'Утримання дитини, аліменти, захист, державні гарантії';

  @override
  String get cyberbullying => 'Кібербулінг та онлайн-переслідування';

  @override
  String get cyberbullyingDesc =>
      'Погрози, порушення приватності, наклеп в інтернеті';

  @override
  String get rightChildSupport =>
      'Обидва батьки за законом зобов’язані фінансово утримувати свою дитину (Perekonnaseadus § 100–102)';

  @override
  String get rightMinimumAlimony =>
      'Мінімальне утримання дитини в Естонії: базова сума (295,86 €) + 3% від середньої валової зарплати за попередній рік (PKS § 101). Із 01.04.2026 — 318,62 €/місяць на дитину. Оновлюється щороку 1 квітня. Калькулятор: alimendid.ee';

  @override
  String get rightCourtAlimony =>
      'Ви можете подати заяву на аліменти через повітовий суд (maakohus) — адвокат не потрібен для вимог до 6 400 €';

  @override
  String get rightBailiffEnforcement =>
      'Якщо батько/мати відмовляється платити, судовий виконавець (kohtutäitur) може примусово виконати рішення суду, включно зі стягненням із зарплати';

  @override
  String get rightStateAlimonyGuarantee =>
      'Якщо батько/мати не платить, держава надає elatisabi (допомогу на утримання) через Sotsiaalkindlustusamet — до 100 €/місяць на дитину';

  @override
  String get rightChildEducation =>
      'Кожна дитина має право на освіту, охорону здоров’я та захист від жорстокого поводження (Lastekaitseseadus § 4–5)';

  @override
  String get rightChildContact =>
      'Дитина має право підтримувати контакт з обома батьками, якщо суд не вирішить інакше (PKS § 143)';

  @override
  String get mustFileCourtClaim =>
      'Щоб отримати аліменти, ви маєте подати позов до суду або домовитися про суму письмово';

  @override
  String get mustNotifyAddressChange =>
      'Повідомляйте Sotsiaalkindlustusamet про зміну адреси, якщо отримуєте elatisabi';

  @override
  String get childrenActionGatherDocs =>
      'Зберіть свідоцтво про народження дитини, ваше посвідчення особи та докази витрат';

  @override
  String get childrenActionFileCourtClaim =>
      'Подайте позов про аліменти до повітового суду (maakohus) — можна зробити онлайн через e-toimik';

  @override
  String get childrenActionApplyElatisabi =>
      'Подайте заяву на державну гарантію аліментів (elatisabi) до Sotsiaalkindlustusamet, якщо батько/мати не платить';

  @override
  String get childrenActionContactBailiff =>
      'Зверніться до судового виконавця (kohtutäitur) для примусового виконання рішення суду';

  @override
  String get childrenActionCallLasteabi =>
      'Телефонуйте на Lasteabi 116 111 — дитяча лінія допомоги, безкоштовна, цілодобово';

  @override
  String get childrenDeadlineElatisabi =>
      'Заява на elatisabi — після рішення суду, суворого строку немає, але процес потребує часу';

  @override
  String get childrenDeadlineCourt =>
      'Аліменти можна вимагати ретроактивно за період до 1 року до подання позову';

  @override
  String get childrenFactMinimum =>
      'Із 01.04.2026 мінімальне утримання дитини становить 318,62 €/місяць на дитину. Формула: базова сума (295,86 €) + 3% від середньої валової зарплати за попередній рік. Оновлюється щороку 1 квітня. Батько/мати не може домовитися платити менше. Калькулятор: alimendid.ee';

  @override
  String get childrenFactElatisabi =>
      'Державну гарантію аліментів Естонії (elatisabi) було запроваджено у 2017 році для захисту дітей, коли батько/мати відмовляється платити. Держава виплачує кошти, а потім стягує суму з батька-боржника.';

  @override
  String get rightReportCybercrime =>
      'Ви маєте право повідомляти про онлайн-погрози, переслідування та крадіжку особистих даних до поліції (Karistusseadustik § 120, § 157¹)';

  @override
  String get rightContentRemoval =>
      'Ви можете вимагати видалення наклепницького або приватного контенту з платформ і вимагати видалення згідно з GDPR';

  @override
  String get rightMoralDamageCompensation =>
      'Ви можете вимагати відшкодування моральної шкоди, заподіяної кібербулінгом (Võlaõigusseadus § 1043–1055)';

  @override
  String get rightPrivacyProtection =>
      'Ваше приватне життя захищене — несанкціоноване поширення ваших фотографій, повідомлень або персональних даних є незаконним (KarS § 157)';

  @override
  String get rightDataProtection =>
      'Повідомляйте про порушення захисту даних (несанкціоноване використання ваших даних) до Andmekaitse Inspektsioon';

  @override
  String get rightDefamationAction =>
      'Наклеп (laimamine) є цивільним правопорушенням — ви можете подати позов про відшкодування шкоди та вимагати публічного спростування (KarS § 247 (скасовано), VÕS § 1047)';

  @override
  String get mustCollectEvidence =>
      'Зберіть і збережіть усі докази — знімки екрана, посилання, дати та інформацію про свідків';

  @override
  String get mustNotRetaliate =>
      'Не мстіться і не вступайте у відповідне переслідування — це може послабити вашу справу';

  @override
  String get cyberActionScreenshots =>
      'Робіть знімки екрана всього переслідування — зберігайте URL, дати, імена користувачів і вміст';

  @override
  String get cyberActionReportPolice =>
      'Подайте заяву до поліції в найближчому відділку або онлайн на politsei.ee';

  @override
  String get cyberActionReportPlatform =>
      'Повідомте про контент платформі соціальних мереж для видалення';

  @override
  String get cyberActionContactDPA =>
      'Зверніться до Andmekaitse Inspektsioon, якщо ваші персональні дані було використано неправомірно';

  @override
  String get cyberActionConsultLawyer =>
      'Проконсультуйтеся з адвокатом щодо цивільного відшкодування — безкоштовна правова допомога доступна через Riigi Õigusabi';

  @override
  String get cyberDeadlineCriminal =>
      'Кримінальна скарга — суворого строку немає, але повідомляйте оперативно для найкращого результату';

  @override
  String get cyberDeadlineCivil =>
      'Цивільний позов про відшкодування шкоди — до 3 років з моменту, коли ви дізналися про порушення (TsÜS § 150)';

  @override
  String get cyberFactPrivacy =>
      'В Естонії несанкціоноване поширення інтимних зображень особи може призвести до позбавлення волі на строк до 3 років згідно з Karistusseadustik § 157¹ (порушення приватності).';

  @override
  String get cyberFactGDPR =>
      'Згідно з GDPR ви маєте «право бути забутим» — платформи зобов’язані видалити ваші персональні дані на вимогу, якщо немає правової підстави їх зберігати.';

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
  String get upgradeBannerTitle => 'Оновіть для необмежених консультацій';

  @override
  String get upgradeBannerCta => 'Оновити';

  @override
  String get paymentSuccessTitle => 'Оплата успішна';

  @override
  String get paymentSuccessBody => 'Вашу підписку активовано.';

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
  String get reasoningPillIdle => 'Думаю…';

  @override
  String get reasoningPillSearchingLaw => 'Шукаю в естонському законодавстві…';

  @override
  String get reasoningPillSearchingWeb => 'Шукаю в інтернеті…';

  @override
  String get reasoningPillCheckingCompany => 'Перевіряю реєстр компаній…';

  @override
  String get reasoningPillCheckingVehicle =>
      'Перевіряю реєстр транспортних засобів…';

  @override
  String get reasoningPillReadingDocument => 'Читаю ваш документ…';

  @override
  String get reasoningPillDrafting => 'Складаю документ…';

  @override
  String get reasoningPillPreparingEmail => 'Готую електронний лист…';

  @override
  String get reasoningPillFindingLawyer => 'Шукаю адвокатів…';

  @override
  String get reasoningPillThinking => 'Обмірковую вашу справу…';

  @override
  String get reasoningPillFinalising => 'Формую вашу відповідь…';

  @override
  String reasoningCollapsedFormat(int sec, int sources) {
    return 'Міркував $sec с · $sources джерел';
  }

  @override
  String get reasoningExpandHint => 'торкніться, щоб побачити кроки';

  @override
  String get caseFileTitle => 'Матеріали справи';

  @override
  String get caseFileTimeline => 'Хронологія';

  @override
  String get caseFileParties => 'Сторони';

  @override
  String get caseFileDeadlines => 'Строки';

  @override
  String get caseFileExportPdf => 'Завантажити досьє (PDF)';

  @override
  String get caseFileEmpty =>
      'Спілкуйтеся з ШІ про вашу справу — ваша хронологія сформується сама.';

  @override
  String get caseFileDisclaimer =>
      'Це досьє автоматично сформовано з вашого чату. Воно не є юридичною консультацією.';

  @override
  String get caseFileTabLabel => 'Справа';

  @override
  String get refresh => 'Оновити';

  @override
  String get demoLimitReached =>
      'Досягнуто демо-ліміту. Зареєструйтеся безкоштовно, щоб продовжити.';

  @override
  String get demoLimitSignUpCta => 'Зареєструватися';

  @override
  String freeQuotaExhausted(int count) {
    return 'Ви використали всі $count безкоштовних повідомлень цього місяця.';
  }

  @override
  String get upgradeForUnlimited => 'Перейдіть на Pro для необмеженого доступу';

  @override
  String get upgradeCta => 'Оновити';

  @override
  String get rateLimitTryAgain =>
      'Надсилаєте занадто швидко. Спробуйте знову за кілька секунд.';

  @override
  String get quickProfilePrompt =>
      'Щоб я міг допомогти точніше: який ваш правовий статус — ви громадянин(-ка) Естонії, громадянин(-ка) ЄС з іншої країни, чи маєте посвідку на проживання?';

  @override
  String get quickProfileChipEstonianCitizen => 'Громадянин(-ка) Естонії';

  @override
  String get quickProfileChipEuCitizen => 'Громадянин(-ка) ЄС (інша країна)';

  @override
  String get quickProfileChipResidencePermit => 'Посвідка на проживання';

  @override
  String get quickProfileSkipBtn => 'Пропустити';

  @override
  String get quickProfileSavedAck => 'Зрозуміло. Тепер, у чому ваше запитання?';

  @override
  String get caseTitleLabel => 'Назва справи';

  @override
  String get jurisdictionLabel => 'Юрисдикція';

  @override
  String get caseTypeLabel => 'Тип справи';

  @override
  String get caseLanguageLabel => 'Мова';

  @override
  String get caseNumbersSection => 'Номери справ';

  @override
  String get partiesSection => 'Сторони';

  @override
  String get authoritiesSection => 'Органи влади';

  @override
  String get timelineSection => 'Хронологія';

  @override
  String get openQuestionsSection => 'Відкриті питання';

  @override
  String get nextActionsSection => 'Наступні дії';

  @override
  String get summarySection => 'Підсумок';

  @override
  String get addRow => 'Додати рядок';

  @override
  String get removeRow => 'Видалити';

  @override
  String get archiveCase => 'Архівувати справу';

  @override
  String get closeCase => 'Закрити справу';

  @override
  String get continueChatAboutCase => 'Продовжити чат про цю справу';

  @override
  String get linkChatToCase => 'Прив’язати до справи';

  @override
  String get clearActiveCase => 'Очистити активну справу';

  @override
  String get caseSavedAck => 'Справу збережено';

  @override
  String get caseArchivedAck => 'Справу заархівовано';

  @override
  String get intakeStep1Title => 'Де розглядається справа?';

  @override
  String get intakeStep1Subtitle => 'Країна та орган, з яким ви маєте справу.';

  @override
  String get intakeJurisdictionLabel => 'Країна / юрисдикція';

  @override
  String get intakeAuthorityLabel => 'Тип органу';

  @override
  String get intakeAuthorityNameLabel => 'Назва органу (необов’язково)';

  @override
  String get intakeAuthorityPolice => 'Поліція';

  @override
  String get intakeAuthorityCourt => 'Суд';

  @override
  String get intakeAuthoritySocial => 'Соціальні служби';

  @override
  String get intakeAuthorityEmployer => 'Роботодавець';

  @override
  String get intakeAuthorityLandlord => 'Орендодавець';

  @override
  String get intakeAuthorityOpposingParty => 'Протилежна сторона';

  @override
  String get intakeAuthorityOther => 'Інше';

  @override
  String get intakeStep2Title => 'Який тип справи?';

  @override
  String get intakeStep2Subtitle =>
      'Оберіть найближчий тип — можна уточнити пізніше.';

  @override
  String get intakeCaseTypeCriminal => 'Кримінальна';

  @override
  String get intakeCaseTypeCivil => 'Цивільна';

  @override
  String get intakeCaseTypeFamily => 'Сімейна';

  @override
  String get intakeCaseTypeAdmin => 'Адміністративна';

  @override
  String get intakeCaseTypeImmigration => 'Імміграційна';

  @override
  String get intakeCaseTypeLabor => 'Трудова';

  @override
  String get intakeCaseTypeConsumer => 'Споживча';

  @override
  String get intakeCaseTypeInheritance => 'Спадкова';

  @override
  String get intakeCaseTypeOther => 'Інше';

  @override
  String get intakeStep3Title => 'Хто залучений?';

  @override
  String get intakeStep3Subtitle => 'Ваша роль і протилежна сторона.';

  @override
  String get intakeRoleLabel => 'Ваша роль';

  @override
  String get intakeRolePlaintiff => 'Позивач';

  @override
  String get intakeRoleDefendant => 'Відповідач';

  @override
  String get intakeRoleVictim => 'Потерпілий';

  @override
  String get intakeRoleAccused => 'Обвинувачений';

  @override
  String get intakeRoleWitness => 'Свідок';

  @override
  String get intakeRoleFamily => 'Член сім’ї';

  @override
  String get intakeRoleOther => 'Інше';

  @override
  String get intakeOpposingSideLabel => 'Протилежна сторона (необов’язково)';

  @override
  String get intakeWitnessesLabel => 'Свідки (необов’язково)';

  @override
  String get intakeAddWitness => 'Додати свідка';

  @override
  String get intakeWitnessHint => 'Ім’я або контакт';

  @override
  String get intakeStep4Title => 'Номери та дати';

  @override
  String get intakeStep4Subtitle =>
      'Усе, що вже маєте. Пропустіть те, чого немає.';

  @override
  String get intakeCaseNumberLabel => 'Номер справи (необов’язково)';

  @override
  String get intakeIncidentDateLabel => 'Дата інциденту (необов’язково)';

  @override
  String get intakeIncidentDatePick => 'Оберіть дату';

  @override
  String get intakeDeadlinesLabel => 'Відомі строки';

  @override
  String get intakeAddDeadline => 'Додати строк';

  @override
  String get intakeDeadlineWhatHint => 'Що';

  @override
  String get intakeStep5Title => 'Документи';

  @override
  String get intakeStep5Subtitle =>
      'Завантажте все релевантне. Ми це прочитаємо.';

  @override
  String get intakeUploadDocsLabel => 'Завантажити документи';

  @override
  String get intakeSkipDocs => 'Пропустити — завантажу пізніше';

  @override
  String get intakeNextBtn => 'Далі';

  @override
  String get intakeBackBtn => 'Назад';

  @override
  String get intakeFinishBtn => 'Завершити та відкрити чат';

  @override
  String get intakeUrgentBtn => 'Терміново — запитати зараз';

  @override
  String get intakeUrgentDialogTitle => 'Відкрити чат зараз?';

  @override
  String get intakeUrgentDialogBody =>
      'Ми збережемо введене вами як чернетку справи. Ви можете завершити майстер зі сторінки справи будь-коли.';

  @override
  String get intakeUrgentConfirm => 'Відкрити чат';

  @override
  String get intakeUrgentCancel => 'Продовжити заповнення';

  @override
  String get intakePreparingCase => 'Готуємо вашу справу…';

  @override
  String get intakeFallbackGreeting =>
      'Я бачу вашу справу. Розкажіть, що найбільш нагальне — я опрацюю це разом з вами.';

  @override
  String get intakeUrgentGreeting =>
      'Я бачу, що це терміново. Поставте своє запитання — решту я заповню в процесі.';

  @override
  String intakeStepIndicator(int current, int total) {
    return 'Крок $current з $total';
  }

  @override
  String get intakeFieldRequired => 'Обов’язково';

  @override
  String intakeUploadProgress(int done, int total) {
    return 'Завантаження $done / $total…';
  }

  @override
  String get uplDisclaimerFooter =>
      'Advocat не є юридичною фірмою. Це інформація, а не юридична консультація.';

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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count посилань',
      many: '$count посилань',
      few: '$count посилання',
      one: '$count посилання',
    );
    return '$_temp0';
  }

  @override
  String citationFooterSummaryVerified(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count перевірено',
      many: '$count перевірено',
      few: '$count перевірено',
      one: '$count перевірено',
    );
    return '$_temp0';
  }

  @override
  String citationFooterSummaryUnverified(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count не перевірено',
      many: '$count не перевірено',
      few: '$count не перевірено',
      one: '$count не перевірено',
    );
    return '$_temp0';
  }

  @override
  String citationFooterSummaryHistorical(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count історичних',
      many: '$count історичних',
      few: '$count історичні',
      one: '$count історичне',
    );
    return '$_temp0';
  }

  @override
  String get deadlineRadarTitle => 'Найближчі дедлайни';

  @override
  String get deadlineRadarEmpty => 'Немає найближчих дедлайнів';

  @override
  String get deadlineRadarViewAll => 'Переглянути всі';

  @override
  String deadlineCardDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'через $count днів',
      many: 'через $count днів',
      few: 'через $count дні',
      one: 'через $count день',
      zero: 'сьогодні',
    );
    return '$_temp0';
  }

  @override
  String get deadlineCardTomorrow => 'завтра';

  @override
  String get deadlineCardToday => 'сьогодні';

  @override
  String deadlineCardOverdue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'прострочено на $count днів',
      many: 'прострочено на $count днів',
      few: 'прострочено на $count дні',
      one: 'прострочено на $count день',
    );
    return '$_temp0';
  }

  @override
  String get deadlineCardMarkComplete => 'Позначити виконаним';

  @override
  String get deadlineCardSnooze => 'Відкласти';

  @override
  String get deadlineCardSnooze3d => 'Відкласти на 3 дні';

  @override
  String get deadlineCardSnooze7d => 'Відкласти на 7 днів';

  @override
  String get deadlineCardSnoozeCustom => 'Обрати дату';

  @override
  String get deadlineCardEdit => 'Редагувати';

  @override
  String get deadlineCardDelete => 'Архівувати';

  @override
  String get deadlineCardSourceLabelPdf => 'з PDF';

  @override
  String get deadlineCardSourceLabelIntake => 'з опитування';

  @override
  String get deadlineCardSourceLabelManual => 'додано вручну';

  @override
  String get deadlineCardSourceLabelEmail => 'з електронного листа';

  @override
  String get deadlineCardSourceLabelHaikuExtract => 'визначено ШІ';

  @override
  String get deadlineCardSourceLabelStatutoryTemplate => 'шаблон закону';

  @override
  String deadlineBannerCritical(String title, String when) {
    return 'Критичний дедлайн $title $when';
  }

  @override
  String get deadlineBannerDismiss => 'Приховати';

  @override
  String get deadlineBannerOpen => 'Відкрити дедлайн';

  @override
  String deadlineHolidayShifted(String original, String reason) {
    return 'Перенесено з $original через $reason';
  }

  @override
  String get deadlinePermissionAskTitle =>
      'Увімкнути нагадування про дедлайни?';

  @override
  String get deadlinePermissionAskBody =>
      'Ми нагадаємо вам за 7, 3 і 1 день до кожного встановленого законом дедлайну, а також уранці того дня. Ніколи не використовується для реклами.';

  @override
  String get deadlinePermissionAllow => 'Дозволити';

  @override
  String get deadlinePermissionLater => 'Пізніше';

  @override
  String get deadlineSettingsSection => 'Нагадування про дедлайни';

  @override
  String get deadlineSettingsPushChannel => 'Push-сповіщення';

  @override
  String get deadlineSettingsEmailChannel => 'Електронна пошта (лише критичні)';

  @override
  String get deadlineSettingsInAppChannel => 'Банери в застосунку';

  @override
  String get deadlineSettingsCriticalBypass =>
      'Критичні нагадування надходять навіть у тиху годину';

  @override
  String get deadlineSettingsQuietHours => 'Тихі години';

  @override
  String deadlineSettingsQuietHoursBadge(String start, String end) {
    return 'Тихо $start–$end';
  }

  @override
  String get deadlineCaseScreenTitle => 'Дедлайни справи';

  @override
  String get deadlineAddManualCta => 'Додати дедлайн';

  @override
  String get deadlineFormTitle => 'Назва';

  @override
  String get deadlineFormDescription => 'Опис (необов\'язково)';

  @override
  String get deadlineFormStatuteTemplate => 'Шаблон закону';

  @override
  String get deadlineFormStatuteTemplateNone => 'Немає (вручну)';

  @override
  String get deadlineFormDeadlineAt => 'Дата дедлайну';

  @override
  String get deadlineFormPriority => 'Пріоритет';

  @override
  String get deadlineFormSave => 'Зберегти';

  @override
  String get deadlineFormCancel => 'Скасувати';

  @override
  String get deadlineCompletedNotePrompt => 'Додати нотатку (необов\'язково)';

  @override
  String get deadlineCompletedNoteSave => 'Зберегти';

  @override
  String get inboxTitle => 'Вхідні';

  @override
  String get inboxEmptyTitle => 'Немає незавершених';

  @override
  String get inboxEmptyBody =>
      'Нові поштові гілки з\'являтимуться тут після сортування.';

  @override
  String get inboxApproveSend => 'Схвалити й надіслати';

  @override
  String get inboxEditDraft => 'Редагувати';

  @override
  String get inboxSnooze => 'Відкласти';

  @override
  String get inboxArchive => 'Архівувати';

  @override
  String get inboxFilterAll => 'Усі';

  @override
  String get inboxConfirmSendTitle => 'Надіслати підготовлену відповідь?';

  @override
  String get inboxConfirmSendBody =>
      'Advocat надішле підготовлену ШІ відповідь через ваш підключений Gmail. На наступному екрані ви ще зможете переглянути текст.';

  @override
  String get inboxSendButton => 'Надіслати';

  @override
  String get inboxSentToast => 'Надіслано.';

  @override
  String get inboxAlreadySentToast => 'Уже надіслано.';

  @override
  String get inboxSendErrorToast =>
      'Не вдалося надіслати відповідь. Натисніть, щоб повторити.';

  @override
  String get inboxSnoozedToast => 'Відкладено на 24 год.';

  @override
  String get inboxArchivedToast => 'Заархівовано.';

  @override
  String get inboxDraftLoadError => 'Не вдалося завантажити чернетку.';

  @override
  String get inboxDeadlineToday => 'сьогодні';

  @override
  String get inboxDeadlineTomorrow => 'завтра';

  @override
  String inboxDeadlineInDays(int days) {
    return 'за $days дн.';
  }

  @override
  String inboxDeadlineOverdue(int days) {
    return 'прострочено на $days дн.';
  }

  @override
  String parallelActionsHeadline(int count) {
    return 'Консиліум рекомендує $count паралельних дій';
  }

  @override
  String get parallelActionsApproveAll => 'Схвалити всі та надіслати';

  @override
  String parallelActionsApproveSelected(int count, int total) {
    return 'Схвалити $count з $total';
  }

  @override
  String parallelActionsConfirmTitle(int count) {
    return 'Надіслати $count листів?';
  }

  @override
  String parallelActionsConfirmBody(int count) {
    return 'Advocat надішле $count підготовлених відповідей через ваш підключений Gmail. Кожна надсилається незалежно — якщо одна не вдасться, інші все одно надійдуть.';
  }

  @override
  String parallelActionsSentToast(int count) {
    return '$count надіслано.';
  }

  @override
  String parallelActionsPartialFailureToast(int sent, int failed) {
    return '$sent надіслано, $failed не вдалося.';
  }

  @override
  String get parallelActionsKindReply => 'відповідь';

  @override
  String get parallelActionsKindNew => 'новий';

  @override
  String get parallelActionsCheckboxSelected => 'Дію обрано';

  @override
  String get parallelActionsCheckboxUnselected => 'Дію не обрано';

  @override
  String parallelActionsCitationCount(int count) {
    return '$count цит.';
  }

  @override
  String parallelActionsRetryFailed(int count) {
    return 'Повторити невдалі ($count)';
  }

  @override
  String get agentApprovalNeedsReviewTitle =>
      'Advocat потребує вашого схвалення';

  @override
  String get agentApprovalResolvedTitle => 'Дію вирішено';

  @override
  String get agentApprovalStepsLabel => 'кроків';

  @override
  String get agentApprovalApproveButton => 'Схвалити та надіслати';

  @override
  String get agentApprovalDeclineButton => 'Відхилити';

  @override
  String get agentApprovalAttachmentsLabel => 'Вкладення';

  @override
  String get agentApprovalSentSummary => 'Надіслано від вашого імені.';

  @override
  String get agentApprovalDeclinedSummary => 'Відхилено — нічого не надіслано.';

  @override
  String get agentToolDraftEmailAtt => 'Надіслати лист із вкладеннями';

  @override
  String get agentToolSendEmail => 'Надіслати лист';

  @override
  String get agentToolGeneratePdf => 'Згенерувати PDF';

  @override
  String get agentToolApproveSend => 'Надіслати підготовлену відповідь';

  @override
  String get inboxErrorTitle => 'Не вдалося завантажити поштову скриньку';

  @override
  String get inboxEditDiscardTitle => 'Відхилити незбережені зміни?';

  @override
  String get inboxEditDiscardBody =>
      'У вас є незбережені зміни в цій чернетці. Повернення назад відхилить їх.';

  @override
  String get inboxEditKeepEditing => 'Продовжити редагування';

  @override
  String get inboxEditDiscard => 'Відхилити';

  @override
  String get workspaceTabOverview => 'Огляд';

  @override
  String get workspaceTabChat => 'Чат';

  @override
  String get workspaceTabDrafts => 'Чернетки';

  @override
  String get workspaceOverviewEmpty =>
      'Додайте документи, щоб сформувати огляд.';

  @override
  String get workspaceTimelineEmpty => 'Подій ще немає.';

  @override
  String get workspaceDocumentsEmpty =>
      'Немає документів. Завантажте через сканування.';

  @override
  String get workspaceDraftsEmpty => 'Чернеток ще немає.';

  @override
  String get workspaceInboxEmpty => 'Немає пов\'язаних листів.';

  @override
  String get plannerSettingsTitle => 'Трипрохідне правове міркування';

  @override
  String get plannerSettingsSubtitle =>
      'План → відповідь → критика. Повільніше, але ретельніше.';

  @override
  String get plannerSettingsProBadge => 'Pro';

  @override
  String get plannerSettingsProDescription => 'Доступно в плані Pro';

  @override
  String get plannerTrailHeaderPlan => 'План';

  @override
  String get plannerTrailHeaderCritique => 'Критика';

  @override
  String get plannerTrailSubQuestions => 'Підпитання';

  @override
  String get plannerTrailCounterArgs => 'Контраргументи';

  @override
  String get plannerTrailEvidenceGaps => 'Прогалини в доказах';

  @override
  String get plannerTrailMaterialGapTrue => 'Виявлено суттєву прогалину';

  @override
  String get plannerTrailRegeneratedBadge => 'Згенеровано повторно один раз';

  @override
  String get plannerTrailEmpty => 'немає елементів';

  @override
  String get supportTitle => 'Допомога';

  @override
  String get supportSubtitle => 'Зазвичай ми відповідаємо протягом 1–2 годин.';

  @override
  String get supportSearchPlaceholder => 'Пошук у довідці…';

  @override
  String get supportStatusAllOk => 'Усі системи в нормі';

  @override
  String get supportFaqWhatIs => 'Що таке Advocat?';

  @override
  String get supportFaqHowSubscribe => 'Як оформити підписку на Pro?';

  @override
  String get supportFaqExportData => 'Чи можу я експортувати свої дані?';

  @override
  String get supportFaqCancelAccount =>
      'Скасувати або видалити обліковий запис';

  @override
  String get supportFaqTalkHuman => 'Поговорити з людиною';

  @override
  String get supportContactEmail => 'Електронна пошта';

  @override
  String get supportContactTelegram => 'Telegram';

  @override
  String get supportContactWhatsapp => 'WhatsApp';

  @override
  String get supportFooterSla => 'Ми відповідаємо протягом 24 год';

  @override
  String get supportWhatsapp => 'WhatsApp';

  @override
  String get supportEmail => 'Електронна пошта';

  @override
  String get supportInApp => 'Напишіть нам тут';

  @override
  String get supportCategoryLabel => 'Категорія';

  @override
  String get supportCategoryBug => 'Помилка';

  @override
  String get supportCategoryPayment => 'Проблема з оплатою';

  @override
  String get supportCategoryQuestion => 'Запитання';

  @override
  String get supportCategoryFeature => 'Запит функції';

  @override
  String get supportCategoryOther => 'Інше';

  @override
  String get supportMessagePlaceholder => 'Опишіть вашу проблему...';

  @override
  String get supportEmailLabel => 'Email (необов’язково)';

  @override
  String get supportSend => 'Надіслати';

  @override
  String get supportSentSuccess =>
      'Повідомлення надіслано! Ми скоро відповімо.';

  @override
  String get supportError => 'Щось пішло не так. Спробуйте ще раз.';

  @override
  String get supportErrorTooShort =>
      'Будь ласка, напишіть щонайменше 10 символів.';

  @override
  String get supportErrorTooLong => 'Максимум 2000 символів.';

  @override
  String get supportPrivacyNotice => 'Ваше повідомлення зберігається безпечно.';

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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Залишилось $count перевірок договорів цього місяця',
      many: 'Залишилось $count перевірок договорів цього місяця',
      few: 'Залишилось $count перевірки договорів цього місяця',
      one: 'Залишилась $count перевірка договорів цього місяця',
      zero: 'Цього місяця перевірок договорів не залишилось',
    );
    return '$_temp0';
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

  @override
  String get referralAntiFraud => 'Максимум 12 успішних запрошень на рік.';

  @override
  String get referralEmpty =>
      'Поки що немає запрошень. Надішліть своє посилання, щоб почати заробляти.';

  @override
  String get referralRecentActivity => 'Нещодавня активність';

  @override
  String referralActivityInvited(String when) {
    return 'Запрошено $when';
  }

  @override
  String referralActivityActivated(String when) {
    return 'активовано $when';
  }

  @override
  String get referralActivityPending => 'ще не активовано';

  @override
  String referralStatsInvitedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count друзів',
      many: '$count друзів',
      few: '$count друзів',
      one: '$count друга',
      zero: 'поки що жодного друга',
    );
    return 'Ви запросили $_temp0';
  }

  @override
  String referralStatsConvertedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count активували',
      many: '$count активували',
      few: '$count активували',
      one: '$count активував',
      zero: 'поки що жоден не активував',
    );
    return '$_temp0';
  }

  @override
  String referralStatsEarnedCount(int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months безкоштовного місяця',
      many: '$months безкоштовних місяців',
      few: '$months безкоштовні місяці',
      one: '$months безкоштовний місяць',
      zero: 'поки що нічого',
    );
    return 'Ваш бонус: $_temp0';
  }

  @override
  String get referralNudgeMessage =>
      'Подобається Advocat? Запросіть друга — обоє отримаєте безкоштовний місяць.';

  @override
  String get referralNudgeAction => 'Запросити';

  @override
  String get referralLandingTitle => 'Вас запрошено до Advocat';

  @override
  String referralLandingSubtitle(String inviterName) {
    return '$inviterName запросив(-ла) вас — отримайте безкоштовний перший місяць.';
  }

  @override
  String get referralLandingSubtitleGeneric =>
      'Отримайте безкоштовний перший місяць Advocat Pro.';

  @override
  String get referralLandingCta =>
      'Активувати безкоштовний місяць і зареєструватися';

  @override
  String get referralLandingCtaSecondary => 'Або дізнайтеся більше про Advocat';

  @override
  String get referralLandingFallback =>
      'Термін дії цього посилання минув — але ви все одно можете спробувати Advocat безкоштовно.';

  @override
  String get referralLandingBenefits =>
      '17 мов • Реальне естонське, фінське та право ЄС • Цілодобово — без очікування';

  @override
  String get checkerProTagline => 'Професійні інструменти перевірки';

  @override
  String get checkerDataSource => 'Дані з офіційних реєстрів';

  @override
  String get companyCheckerHint => 'Назва компанії або реєстр. номер';

  @override
  String get companyCheckerPriceChip => '€2.99 за перевірку  •  Входить у Pro';

  @override
  String get companyCheckerEmptyState =>
      'Введіть назву компанії або реєстраційний\nномер, щоб отримати повний звіт';

  @override
  String get aiMemoryTitle => 'Пам\'ять ШІ';

  @override
  String get aiMemorySubtitle =>
      'Перегляньте та видаліть те, що ШІ пам\'ятає про вас';

  @override
  String get bookLawyerCallTitle => 'Замовити дзвінок з юристом';

  @override
  String get bookLawyerCallComingSoonTitle => 'Дзвінки з живим юристом — скоро';

  @override
  String get bookLawyerCallComingSoonBody =>
      'Pro та Premium включають 15-хвилинні дзвінки з юристом-партнером (1/квартал у Pro, 2/квартал у Premium). Завершуємо формування мережі естонських приватнопрактикуючих юристів і надішлемо листа, щойно бронювання відкриється.';

  @override
  String bookLawyerCallQuotaAvailable(int remaining, int total) {
    return 'У вас залишилось $remaining з $total дзвінків цього кварталу.';
  }

  @override
  String get bookLawyerCallQuotaExhausted => 'Квартальну квоту вичерпано.';

  @override
  String get bookLawyerCallQuotaBodyAvailable =>
      'Тариф Pro включає 1 дзвінок на квартал, Premium — 2. Дзвінки тривають 15 хвилин у Google Meet.';

  @override
  String get bookLawyerCallQuotaBodyExhausted =>
      'Ваша квота оновиться в перший день наступного кварталу. Потрібно поговорити раніше? Перейдіть на Premium для додаткового дзвінка.';

  @override
  String get severityCritical => 'КРИТИЧНО';

  @override
  String get severityHigh => 'ВИСОКИЙ';

  @override
  String get severityMedium => 'СЕРЕДНІЙ';

  @override
  String get severityLow => 'НИЗЬКИЙ';

  @override
  String get deadlineRequiredFields =>
      'Заголовок і дата дедлайну є обов\'язковими';

  @override
  String get acceptTermsRequired => 'Будь ласка, прийміть Умови надання послуг';

  @override
  String get chatLegalCouncilTooltip => 'Юридичний консиліум (4 експерти)';

  @override
  String get attachFileTooltip => 'Прикріпити файл';

  @override
  String get sendMessage => 'Надіслати повідомлення';

  @override
  String get stopGenerating => 'Зупинити генерацію';

  @override
  String get showPassword => 'Показати пароль';

  @override
  String get hidePassword => 'Сховати пароль';

  @override
  String get decreaseDependents => 'Зменшити';

  @override
  String get increaseDependents => 'Збільшити';

  @override
  String get sensitiveConsentTitle => 'Згода на обробку чутливих даних';

  @override
  String get sensitiveConsentBody =>
      'Документи, які ви збираєтеся завантажити, можуть містити особливі категорії персональних даних згідно зі ст. 9 GDPR — як-от медичні записи, дані про судимість, біометричні дані або інформацію про ваше расове походження, релігію чи сексуальну орієнтацію.\n\nМи обробляємо ці дані лише для надання вам правової допомоги ШІ, зберігаємо їх у зашифрованому вигляді у вашому приватному обліковому записі та ніколи не використовуємо для навчання моделей. Ви можете відкликати згоду та видалити дані будь-коли в Налаштуваннях.\n\nПриймаючи, ви даєте явну згоду згідно зі ст. 9(2)(a) GDPR на обробку особливих категорій даних для цієї мети.';

  @override
  String get sensitiveConsentExplicitCheckbox =>
      'Я даю явну згоду на обробку особливих категорій даних (ст. 9(2)(a) GDPR).';

  @override
  String get sensitiveConsentRightToShareCheckbox =>
      'Я підтверджую, що маю право надати ці дані (дані є моїми, або я маю поінформовану/законну підставу надавати дані третіх осіб).';

  @override
  String get sensitiveConsentViewCategories =>
      'Переглянути, що вважається чутливим →';

  @override
  String get sensitiveConsentWithdrawAction =>
      'Відкликати згоду на обробку чутливих даних';

  @override
  String get privacyAndData => 'КОНФІДЕНЦІЙНІСТЬ І ДАНІ';

  @override
  String get exportMyDataSubtitle =>
      'Завантажте копію всіх ваших персональних даних (ст. 15 GDPR).';

  @override
  String get withdrawSensitiveConsent => 'Згода на обробку чутливих даних';

  @override
  String get withdrawSensitiveConsentSubtitle =>
      'Керуйте або відкликайте згоду на обробку особливих категорій даних (ст. 9(2)(a) GDPR).';

  @override
  String get dataProcessingAgreement => 'Угода про обробку даних';

  @override
  String get exportingData => 'Експортуємо ваші дані…';

  @override
  String get exportComplete =>
      'Експорт даних готовий — збережено на ваш пристрій.';

  @override
  String get exportFailed =>
      'Не вдалося експортувати. Будь ласка, спробуйте ще раз або зверніться до підтримки.';

  @override
  String get quotaExhaustedTitle => 'Ліміт безкоштовних повідомлень';

  @override
  String quotaExhaustedBody(int count) {
    return 'Ви використали всі $count безкоштовних повідомлень. Оформіть Advocat Pro за 19,99 €/міс для необмеженого доступу до AI-консультацій.';
  }

  @override
  String get quotaExhaustedLater => 'Пізніше';

  @override
  String get quotaExhaustedUpgrade => 'Advocat Pro — 19,99 €/міс';

  @override
  String quotaCtaMessage(int count) {
    return 'Ви використали всі $count безкоштовних повідомлень. Оформіть Advocat Pro за 19,99 €/міс.';
  }

  @override
  String get quotaCtaButton => 'Оформити Advocat Pro — 19,99 €/міс';

  @override
  String get aiErrorQuota =>
      'Досягнуто ліміт безкоштовних повідомлень. Оформіть підписку, щоб продовжити.';

  @override
  String get aiErrorAuth =>
      'Для використання AI потрібен вхід в акаунт. Зареєструйтеся або увійдіть.';

  @override
  String get aiErrorGeneric =>
      'Тимчасова помилка AI. Спробуйте ще раз за хвилину. Якщо не працює — напишіть у підтримку.';

  @override
  String get tooltipShareCase => 'Поділитися підсумком справи';

  @override
  String get tooltipMuteVoice => 'Вимкнути голос';

  @override
  String get tooltipUnmuteVoice => 'Увімкнути голос';

  @override
  String get tooltipAttachDoc => 'Прикріпити документ';

  @override
  String get aiTypingHint => 'ШІ…';

  @override
  String get error404Title => 'Сторінку не знайдено';

  @override
  String error404Body(String path) {
    return 'Не вдалося знайти: $path';
  }

  @override
  String get goToHome => 'На головну';

  @override
  String get emailAlreadyRegistered =>
      'Ця електронна пошта вже зареєстрована. Увійти?';

  @override
  String get actionSignIn => 'Увійти';

  @override
  String get actionUndo => 'Скасувати';

  @override
  String get intakeUrgentOpened => 'Чат відкрито — ваш чернетку збережено.';

  @override
  String get panicCoachmark => 'Утримуйте для екстреної допомоги.';

  @override
  String get panicTitle => 'Що вам потрібно прямо зараз?';

  @override
  String get panicCardReadAloud => 'Зачитати вголос офіцеру';

  @override
  String get panicCardRecord => 'Записати цю розмову';

  @override
  String get panicCardCall => 'Зателефонувати адвокату';

  @override
  String get panicCardAi => 'Поговорити з Advocat зараз';

  @override
  String get panicClose => 'Закрити';

  @override
  String get panicBadgeV2 => 'V2';

  @override
  String get panicRecordV1Title => 'Незабаром у V2';

  @override
  String get panicRecordV1Body =>
      'Функція запису проходить юридичну перевірку для Естонії та з’явиться у V2. Наразі скористайтеся вбудованим диктофоном вашого телефона.';

  @override
  String get panicCallFallbackBody =>
      'Напишіть на kiire@advocat.ee з коротким описом, і ми вам передзвонимо.';

  @override
  String get consiliumHeader => 'Консиліум юристів';

  @override
  String consiliumProgress(int count, int total) {
    return '$count з $total готові';
  }

  @override
  String get consiliumStarting => 'Юристи вивчають вашу справу…';

  @override
  String get consiliumDisagreement => 'Експерти не згодні';

  @override
  String get consiliumSynthesizing => 'Формується рекомендація…';

  @override
  String consiliumDone(int totalRoles) {
    return 'Консиліум завершено · $totalRoles експертів';
  }

  @override
  String get consiliumPositionPush => 'Оскаржити';

  @override
  String get consiliumPositionSettle => 'Домовитися';

  @override
  String get consiliumPositionInvestigate => 'Дослідити';

  @override
  String get consiliumPositionOutOfScope => 'Поза компетенцією';

  @override
  String get consiliumConfidence => 'Впевненість';

  @override
  String get consiliumKeyCitation => 'Ключове посилання';

  @override
  String get consiliumAdversarialRound => 'Змагальний раунд';

  @override
  String get consiliumViewFullOpinion => 'Повний висновок';

  @override
  String consiliumExpertsAgreed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count експертів згодні',
      many: '$count експертів згодні',
      few: '$count експерти згодні',
      one: '$count експерт згоден',
    );
    return '$_temp0';
  }

  @override
  String consiliumExpertsDisagree(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count експертів не згодні',
      many: '$count експертів не згодні',
      few: '$count експерти не згодні',
      one: '$count експерт не згоден',
    );
    return '$_temp0';
  }

  @override
  String get consiliumDisclaimer =>
      'ШІ-агенти, а не люди-юристи. Важливі рішення перевіряйте з ліцензованим адвокатом.';

  @override
  String get softCaseShellBanner =>
      'Ми створили «Справу без назви», щоб відстежувати це. Торкніться, щоб перейменувати.';

  @override
  String get softCaseShellBannerCta => 'Перейменувати';

  @override
  String get draftsTab => 'Чернетки';

  @override
  String get draftingTitle => 'Студія створення документів';

  @override
  String get draftingEmpty => 'Порожня чернетка';

  @override
  String get draftingPlaceholder => 'Почніть вводити текст чернетки…';

  @override
  String get draftingDraftsList => 'Мої чернетки';

  @override
  String get draftingSave => 'Зберегти';

  @override
  String get draftingSaved => 'Збережено';

  @override
  String get draftingSavedJustNow => 'Щойно збережено';

  @override
  String get draftingAiRevise => 'Виправити за допомогою ШІ';

  @override
  String get draftingExportPdf => 'Експортувати PDF';

  @override
  String get draftingExportDocx => 'Експортувати DOCX';

  @override
  String get draftingExportMd => 'Експортувати Markdown';

  @override
  String get draftingDeleteDraft => 'Видалити чернетку';

  @override
  String get draftingConfirmDelete => 'Видалити цю чернетку?';

  @override
  String get draftingConfirmDeleteMessage => 'Цю дію неможливо скасувати.';

  @override
  String get draftingConfirm => 'Видалити';

  @override
  String get draftingCancel => 'Скасувати';

  @override
  String draftingDraftReplyTo(String name) {
    return 'Відповідь до $name';
  }

  @override
  String get draftingUntitled => 'Без назви';

  @override
  String get draftingTitleHint => 'Назва (необов\'язково)';

  @override
  String get draftingAiReviseTitle => 'Виправити за допомогою ШІ';

  @override
  String get draftingAiReviseSelectionLabel => 'Обраний текст:';

  @override
  String get draftingAiReviseInstructionLabel => 'Інструкція (необов\'язково)';

  @override
  String get draftingAiReviseInstructionHint =>
      'напр., «зробити офіційнішим» або «скоротити»';

  @override
  String get draftingAiReviseRunButton => 'Створити виправлення';

  @override
  String get draftingAiReviseSuggestionLabel => 'Запропоноване виправлення:';

  @override
  String get draftingAiReviseChangesLabel => 'Зміни:';

  @override
  String get draftingAiReviseAccept => 'Прийняти';

  @override
  String get draftingAiReviseReject => 'Відхилити';

  @override
  String get draftingFormatBold => 'Жирний';

  @override
  String get draftingFormatItalic => 'Курсив';

  @override
  String get draftingFormatHeading => 'Заголовок';

  @override
  String get draftingFormatBullet => 'Маркований список';

  @override
  String get draftingFormatNumbered => 'Нумерований список';

  @override
  String get draftingEmptyListMessage => 'У вас ще немає чернеток.';

  @override
  String get draftingEmptyListAction => 'Нова чернетка';

  @override
  String get draftingExporting => 'Експортування…';

  @override
  String get draftingExportFailed => 'Не вдалося експортувати';

  @override
  String get draftingSaveFailed => 'Не вдалося зберегти';

  @override
  String get draftingNewDraft => 'Нова чернетка';

  @override
  String get vaultNoteChip => 'Нотатка у сховищі';

  @override
  String get saveToVault => 'Зберегти у сховище';

  @override
  String get savingToVault => 'Збереження у сховище…';

  @override
  String get savedToVault => 'Збережено у сховище';

  @override
  String get vaultNoteTitlePrefix => 'Нотатка: ';

  @override
  String get openInVault => 'Відкрити у сховищі';

  @override
  String get saveToVaultFailed => 'Не вдалося зберегти у сховище';

  @override
  String get pdfWorkerUnavailable =>
      'Експорт у PDF тимчасово недоступний. Спробуйте DOCX або Markdown.';

  @override
  String get draftingVersionHistory => 'Історія версій';

  @override
  String get emptyHomeTitle => 'Ласкаво просимо до Advocat';

  @override
  String get emptyHomeBody =>
      'Оберіть відправну точку — юридичну частину ми візьмемо на себе.';

  @override
  String get intentChip1 => 'Отримав штраф';

  @override
  String get intentChip2 => 'Відмовили в дозволі';

  @override
  String get intentChip3 => 'Проблема з договором';

  @override
  String get emptyCasesTitle => 'Справ ще немає';

  @override
  String get emptyCasesCta => 'Розпочати справу';

  @override
  String get emptyDraftsTitle => 'Чернеток ще немає';

  @override
  String get emptyDraftsCta => 'Створити чернетку';

  @override
  String get emptyChatTitle => 'Запитайте Advocat про будь-що';

  @override
  String get chatExamplePrompt1 => 'Допоможіть відповісти на штраф';

  @override
  String get chatExamplePrompt2 => 'Перевірте мій договір оренди';

  @override
  String get chatExamplePrompt3 => 'Які мої права на роботі?';

  @override
  String get dangerZone => 'Небезпечна зона';

  @override
  String get deleteAccountConfirmButton => 'Видалити назавжди';

  @override
  String deleteAccountConfirmHint(String email) {
    return 'Введіть $email для підтвердження';
  }

  @override
  String get deleteAccountSuccess =>
      'Обліковий запис видалено. Нам шкода, що ви йдете.';

  @override
  String get deleteAccountWarning =>
      'Це назавжди видалить ваш обліковий запис, усі справи, чернетки, документи у сховищі та історію чату. Цю дію не можна скасувати.';

  @override
  String get deletingAccount => 'Видалення облікового запису…';

  @override
  String get contractReviewTitle => 'Перевірка договору';

  @override
  String get contractReviewUploadCta => 'Завантажити договір';

  @override
  String get contractReviewQuotaRemaining =>
      'Завантажте договір у форматі PDF, DOC, DOCX або TXT для ШІ-перевірки з виявленням ризиків і порадами щодо переговорів.';

  @override
  String get contractReviewRedFlags => 'Тривожні сигнали';

  @override
  String get contractReviewReviewPoints => 'Пункти для перевірки';

  @override
  String get contractReviewNegotiationTips => 'Поради щодо переговорів';

  @override
  String get contractReviewSaveToVault => 'Зберегти у сховище';

  @override
  String get contractReviewContinueChat => 'Продовжити в чаті';

  @override
  String get referralInviteFriends => 'Запросити друзів';

  @override
  String get referralYourCode => 'Ваш код';

  @override
  String get referralCopiedToast => 'Код скопійовано в буфер обміну';

  @override
  String get referralReward =>
      'Отримуйте 1 місяць тарифу Counsel безкоштовно за кожного друга, який оформить підписку.';

  @override
  String get referralInvited => 'Запрошено друзів';

  @override
  String get referralRewardsEarned => 'Отримано безкоштовних місяців';

  @override
  String get deadlineUrgencyToday => 'Сьогодні та прострочені';

  @override
  String get deadlineUrgencyWeek => 'На цьому тижні';

  @override
  String get deadlineUrgencyMonth => 'Цього місяця';

  @override
  String get deadlineUrgencyLater => 'Пізніше';

  @override
  String get deadlineAddManual => 'Додати дедлайн';

  @override
  String get deadlineSnoozeBy => 'Відкласти';

  @override
  String get deadlineSnooze1d => 'Відкласти на 1 день';

  @override
  String get deadlineSnooze3d => 'Відкласти на 3 дні';

  @override
  String get deadlineSnooze7d => 'Відкласти на 7 днів';

  @override
  String get deadlineDismiss => 'Приховати';

  @override
  String get deadlineExportIcs => 'Додати до календаря';

  @override
  String get deadlineSource => 'Джерело';

  @override
  String get deadlineEmpty =>
      'Дедлайнів ще немає. Дедлайни створюються автоматично з ваших листів і документів — або додайте вручну кнопкою «+».';

  @override
  String get deadlineNewTitle => 'Новий дедлайн';

  @override
  String get deadlineFieldTitle => 'Назва';

  @override
  String get deadlineFieldDueDate => 'Дата виконання';

  @override
  String get deadlineFieldNotes => 'Нотатки (необов\'язково)';

  @override
  String get deadlineSaved => 'Дедлайн збережено';

  @override
  String get deadlineSaveFailed => 'Не вдалося зберегти дедлайн';

  @override
  String get deadlineUrgentBannerSingle => '1 дедлайн сьогодні або прострочено';

  @override
  String deadlineUrgentBannerMany(int count) {
    return '$count дедлайнів сьогодні або прострочено';
  }

  @override
  String deadlineDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'залишилося $count днів',
      many: 'залишилося $count днів',
      few: 'залишилося $count дні',
      one: 'залишився $count день',
      zero: 'сьогодні',
    );
    return '$_temp0';
  }

  @override
  String deadlineDaysOverdue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'прострочено на $count днів',
      many: 'прострочено на $count днів',
      few: 'прострочено на $count дні',
      one: 'прострочено на $count день',
    );
    return '$_temp0';
  }

  @override
  String get iapPayWithApple => 'Сплатити через Apple';

  @override
  String get iapRestorePurchases => 'Відновити покупки';

  @override
  String get iapPurchaseFailed =>
      'Не вдалося здійснити покупку. Спробуйте ще раз або зверніться до підтримки.';

  @override
  String get iapRestoreSuccess => 'Вашу підписку відновлено.';

  @override
  String get iapRestoreNoActive =>
      'Активну підписку для відновлення не знайдено.';

  @override
  String get deadlineEuRadarTitle => 'Радар дедлайнів ЄС (попередній перегляд)';

  @override
  String get deadlineEuRadarSubtitle =>
      'Гіпотетичні процедурні дедлайни ЄС — тестові дані';

  @override
  String get changePassword => 'Змінити пароль';

  @override
  String get changePasswordSubtitle =>
      'Оновіть пароль вашого облікового запису';

  @override
  String get newPasswordTitle => 'Встановіть новий пароль';

  @override
  String get newPasswordHint =>
      'Введіть і підтвердьте новий пароль для вашого облікового запису.';

  @override
  String get newPasswordSave => 'Зберегти новий пароль';

  @override
  String get newPasswordSuccess =>
      'Пароль оновлено. Тепер використовуйте його для входу.';

  @override
  String get newPasswordError => 'Не вдалося оновити пароль. Спробуйте ще раз.';

  @override
  String get accessLogTile => 'Журнал доступу';

  @override
  String get accessLogTileSubtitle =>
      'Дивіться, хто і що отримував доступ до ваших даних';

  @override
  String get accessLogTitle => 'Журнал доступу до моїх даних';

  @override
  String get accessLogIntro =>
      'Прозорий захищений від підробки запис кожного звернення до ваших даних чи їх обробки — зокрема нашим ШІ. Ви можете переконатися, що його не змінювали.';

  @override
  String get accessLogEmpty => 'Подій доступу ще немає.';

  @override
  String get accessLogError =>
      'Не вдалося завантажити журнал доступу. Потягніть донизу, щоб повторити.';

  @override
  String get accessLogIntegrityOk =>
      'Цілісність підтверджено — записи журналу утворюють безперервний ланцюжок.';

  @override
  String get accessLogIntegrityBroken =>
      'Увага: ланцюжок журналу порушено. Деякі записи могли бути видалені або переставлені. Будь ласка, зверніться до підтримки.';

  @override
  String get accessActionLlmEgress =>
      'Надіслано ШІ для обробки (псевдонімізовано)';

  @override
  String get accessActionAiAnalysis => 'Проаналізовано ШІ';

  @override
  String get accessActionDocumentParse => 'Документ розібрано';

  @override
  String get accessActionStaffRead => 'Переглянуто співробітником';

  @override
  String get accessActionExport => 'Дані експортовано';

  @override
  String get accessActionEmailTriage => 'Лист відсортовано';

  @override
  String get accessActionDeadlineScan => 'Строки перевірено';

  @override
  String get breachAlertTitle => 'Сповіщення безпеки щодо ваших даних';

  @override
  String get breachAlertBody =>
      'Наш автоматизований моніторинг виявив незвичайне звернення до ваших даних. Ми його перевіряємо й повідомимо вас про будь-який підтверджений інцидент, як вимагає закон (ст. 34 GDPR).';

  @override
  String get caseDossierTitle => 'Експорт досьє справи';

  @override
  String get caseDossierSubtitle =>
      'Один PDF з усім — факти, хронологія, строки та документи — щоб передати адвокату, суду чи органу розгляду скарг.';

  @override
  String get caseDossierTileTitle => 'Експорт досьє (PDF)';

  @override
  String get caseDossierTileSubtitle =>
      'Передайте всю справу адвокату чи суду одним файлом';

  @override
  String get caseDossierSectionsHeading => 'Включити до досьє';

  @override
  String get caseDossierSectionFacts => 'Факти справи';

  @override
  String get caseDossierSectionFactsHint => 'Завжди включено';

  @override
  String get caseDossierSectionTimeline => 'Хронологія';

  @override
  String get caseDossierSectionDeadlines => 'Строки';

  @override
  String get caseDossierSectionDocuments => 'Документи';

  @override
  String get caseDossierSectionAiSummary => 'Резюме ШІ';

  @override
  String get caseDossierExportButton => 'Експортувати PDF';

  @override
  String get caseDossierExporting => 'Формуємо ваше досьє…';

  @override
  String get caseDossierSuccess =>
      'Досьє готове. Відкрийте або поділіться файлом.';

  @override
  String get caseDossierOpen => 'Відкрити досьє';

  @override
  String get caseDossierError =>
      'Не вдалося сформувати досьє. Спробуйте ще раз.';

  @override
  String get caseDossierErrorNotOwned => 'Цю справу не знайдено.';

  @override
  String get caseDossierDisclaimer =>
      'Досьє відтворює дані вашої справи у записаному вигляді. Перевірте їх перед тим, як ділитися.';

  @override
  String get followupsTitle => 'Наступні кроки';

  @override
  String get followupsSubtitle =>
      'Практичні завдання, щоб справа рухалася далі';

  @override
  String get followupsEmpty => 'Подальших кроків ще немає.';

  @override
  String get followupsEmptyDesc =>
      'Додайте крок або дозвольте ШІ запропонувати, що робити далі.';

  @override
  String get followupsAdd => 'Додати крок';

  @override
  String get followupsSuggest => 'Запропонувати кроки';

  @override
  String get followupsSuggestNone =>
      'Зараз пропозицій немає. Спробуйте після обговорення справи в чаті.';

  @override
  String get followupsSuggestTitle => 'Запропоновані наступні кроки';

  @override
  String get followupsAddPrompt => 'Додайте кроки, які хочете зберегти:';

  @override
  String get followupsNewTitleHint => 'Що потрібно зробити?';

  @override
  String get followupsNewDetailHint =>
      'Необов\'язкова примітка (чому / що додати)';

  @override
  String get followupsDueOptional => 'Нагадати мені (необов\'язково)';

  @override
  String get followupsOverdue => 'Прострочено';

  @override
  String followupsDueOn(String date) {
    return 'Термін: $date';
  }

  @override
  String get followupsDone => 'Виконано';

  @override
  String get followupsSnooze => 'Відкласти';

  @override
  String get followupsSnooze1Week => 'Нагадати через тиждень';

  @override
  String get followupsDismiss => 'Відхилити';

  @override
  String get followupsLoadError => 'Не вдалося завантажити наступні кроки';

  @override
  String get followupsAiBadge => 'ШІ';

  @override
  String get contractCompareTitle => 'Порівняти версії';

  @override
  String get contractCompareIntro =>
      'Завантажте дві версії того самого договору. Ми виділимо, що змінилося і чи кожна зміна вам на користь чи на шкоду.';

  @override
  String get contractCompareOldVersion => 'Стара версія (v1)';

  @override
  String get contractCompareNewVersion => 'Нова версія (v2)';

  @override
  String get contractCompareCta => 'Порівняти версії';

  @override
  String get contractCompareAdverse => 'Несприятливо';

  @override
  String get contractCompareFavorable => 'Сприятливо';

  @override
  String get contractCompareNeutral => 'Нейтрально';

  @override
  String get contractCompareBefore => 'До';

  @override
  String get contractCompareAfter => 'Після';

  @override
  String get contractCompareTruncated =>
      'Довгий договір — порівняно лише першу частину кожної версії.';

  @override
  String get contractCompareNoChanges =>
      'Суттєвих змін між двома версіями не виявлено.';

  @override
  String get docSearchTitle => 'Пошук у моїх документах';

  @override
  String get docSearchHint => 'напр. де згадувалася застава';

  @override
  String get docSearchSubtitle =>
      'Семантичний пошук у вашому сховищі та файлах справ';

  @override
  String get docSearchIdle =>
      'Шукайте у змісті власних документів — а не лише за назвами.';

  @override
  String get docSearchNoResults => 'У ваших документах збігів не знайдено.';

  @override
  String get docSearchError => 'Пошук не вдався. Спробуйте ще раз.';

  @override
  String get docSearchUntitled => 'Документ без назви';

  @override
  String get docSearchKindCase => 'Документ справи';

  @override
  String get docSearchKindVault => 'Документ зі сховища';

  @override
  String get docSearchMenuTitle => 'Пошук у моїх документах';

  @override
  String get docSearchMenuSubtitle =>
      'Знаходьте будь-що у власних файлах за змістом';

  @override
  String get legalTemplatesTitle => 'Бібліотека шаблонів';

  @override
  String get legalTemplatesMenuLabel => 'Шаблони';

  @override
  String get legalTemplatesSubtitle =>
      'Оберіть готову форму, заповніть кілька полів — і ми створимо чернетку, яку можна редагувати та експортувати.';

  @override
  String get legalTemplatesDisclaimer =>
      'Це загальні зразки форм, а не індивідуальна юридична консультація. Перевірте й адаптуйте перед надсиланням.';

  @override
  String get legalTemplatesSampleBadge => 'Зразок';

  @override
  String get legalTemplatesEmpty => 'Шаблонів за цим фільтром поки немає.';

  @override
  String get legalTemplatesError =>
      'Не вдалося завантажити шаблони. Спробуйте ще раз.';

  @override
  String get legalTemplatesFilterAll => 'Усі';

  @override
  String get legalTemplatesJurisdictionFi => 'Фінляндія';

  @override
  String get legalTemplatesJurisdictionEe => 'Естонія';

  @override
  String get legalTemplatesCategoryComplaint => 'Скарги';

  @override
  String get legalTemplatesCategoryAppeal => 'Оскарження';

  @override
  String get legalTemplatesCategoryApplication => 'Заяви';

  @override
  String get legalTemplatesCategoryClaim => 'Позови';

  @override
  String get legalTemplatesCategoryRequest => 'Запити';

  @override
  String get legalTemplatesFillTitle => 'Заповніть деталі';

  @override
  String get legalTemplatesFillIntro =>
      'Ми автоматично підставимо ваше ім\'я та дані справи. Заповніть поля нижче.';

  @override
  String get legalTemplatesFieldRequired => 'Це поле обов\'язкове';

  @override
  String get legalTemplatesCreateDraft => 'Створити чернетку';

  @override
  String get legalTemplatesCreating => 'Створюємо чернетку…';

  @override
  String get legalTemplatesCreateFailed =>
      'Не вдалося створити чернетку. Спробуйте ще раз.';

  @override
  String get legalTemplatesUnresolvedWarning =>
      'Деякі поля досі порожні й позначені ____ у чернетці. Ви можете заповнити їх у редакторі.';

  @override
  String get legalTemplatesFieldRecipient => 'Одержувач (орган / орендодавець)';

  @override
  String get legalTemplatesFieldAddress => 'Ваша поштова адреса';

  @override
  String get legalTemplatesFieldSubject => 'Тема';

  @override
  String get legalTemplatesFieldDescription => 'Опис справи';

  @override
  String get legalTemplatesFieldDemand => 'Чого ви вимагаєте';

  @override
  String get checklistActionPlan => 'План дій';

  @override
  String get checklistActionPlanSubtitle => 'Кроки для цього типу справи';

  @override
  String checklistProgress(int completed, int total) {
    return 'Виконано $completed з $total кроків';
  }

  @override
  String get checklistAllDone => 'Усі кроки виконано';

  @override
  String get checklistEmpty => 'Плану дій для цього типу справи поки немає.';

  @override
  String checklistDeadlineDays(int days) {
    return '$days днів';
  }

  @override
  String get checklistDisclaimer =>
      'Це загальна інформація, а не юридична консультація. Строки наведені як стандартні законодавчі — підтвердьте точну дату для вашої справи.';

  @override
  String get checklistViewPlan => 'Переглянути план';

  @override
  String get explainPlainTitle => 'Пояснити простими словами';

  @override
  String get explainPlainIntro =>
      'Вставте офіційний лист, рішення чи договір — і ми простою мовою пояснимо, що це означає й чого від вас вимагає.';

  @override
  String get explainPlainLevelFriend => 'Як другові';

  @override
  String get explainPlainLevelTerms => 'Зберегти юридичні терміни';

  @override
  String get explainPlainInputHint => 'Вставте юридичний текст сюди…';

  @override
  String get explainPlainSubmit => 'Пояснити';

  @override
  String get explainPlainWorking => 'Пояснюємо…';

  @override
  String get explainPlainTldr => 'Головне';

  @override
  String get explainPlainBreakdown => 'Що тут написано, частина за частиною';

  @override
  String get explainPlainGlossary => 'Складні терміни з поясненням';

  @override
  String get explainPlainNextSteps => 'Що ви можете зробити далі';

  @override
  String get explainPlainOpenInCorpus => 'Знайти у бібліотеці законів';

  @override
  String get explainPlainEmptyResult =>
      'Для цього тексту не вдалося скласти пояснення. Спробуйте вставити довший або чіткіший уривок.';

  @override
  String get explainPlainQuotaTitle =>
      'Ви вичерпали безкоштовні пояснення цього місяця';

  @override
  String get explainPlainQuotaBody =>
      'Безкоштовні акаунти отримують 3 пояснення на місяць. Перейдіть на Pro для необмежених пояснень.';

  @override
  String get explainPlainUpgradeCta => 'Перейти на Pro';

  @override
  String get explainPlainError =>
      'Під час пояснення цього тексту сталася помилка. Спробуйте ще раз.';

  @override
  String get explainPlainRetry => 'Спробувати ще раз';

  @override
  String get demandLetterTitle => 'Претензійний лист';

  @override
  String get demandLetterSubtitle =>
      'Створіть офіційну досудову вимогу (maksuvaatimus / nõudekiri).';

  @override
  String get demandLetterStepType => 'Тип вимоги';

  @override
  String get demandLetterStepParties => 'Сторони';

  @override
  String get demandLetterStepClaim => 'Сума та підстава';

  @override
  String get demandLetterStepDeadline => 'Строк';

  @override
  String get demandLetterStepReview => 'Перевірка та створення';

  @override
  String get demandLetterClaimDepositReturn => 'Повернення орендної застави';

  @override
  String get demandLetterClaimUnpaidWage => 'Невиплачена заробітна плата';

  @override
  String get demandLetterClaimFineDispute => 'Оскарження штрафу / нарахування';

  @override
  String get demandLetterClaimGeneric => 'Інша грошова вимога';

  @override
  String get demandLetterJurisdiction => 'Юрисдикція';

  @override
  String get demandLetterLanguage => 'Мова листа';

  @override
  String get demandLetterRecipientName => 'Ім\'я одержувача';

  @override
  String get demandLetterRecipientAddress =>
      'Адреса одержувача (необов\'язково)';

  @override
  String get demandLetterSenderName => 'Ваше ім\'я';

  @override
  String get demandLetterSenderAddress =>
      'Ваша адреса / email (необов\'язково)';

  @override
  String get demandLetterAmount => 'Сума';

  @override
  String get demandLetterCurrency => 'Валюта';

  @override
  String get demandLetterBasis => 'Що сталося (підстава вимоги)';

  @override
  String get demandLetterBasisHint =>
      'Опишіть факти: дати, суми, про що домовлялися й що пішло не так.';

  @override
  String get demandLetterDeadline => 'Строк оплати';

  @override
  String get demandLetterDeadlineHint => 'напр. 14 днів від сьогодні';

  @override
  String get demandLetterReference => 'Посилання (необов\'язково)';

  @override
  String get demandLetterGenerate => 'Створити лист';

  @override
  String get demandLetterGenerating => 'Створюємо…';

  @override
  String get demandLetterGenerateFailed =>
      'Не вдалося створити лист. Спробуйте ще раз.';

  @override
  String get demandLetterFieldRequired => 'Це поле обов\'язкове';

  @override
  String get demandLetterNext => 'Далі';

  @override
  String get demandLetterBack => 'Назад';

  @override
  String get demandLetterPreviewTitle => 'Ваш лист';

  @override
  String get demandLetterCopy => 'Копіювати текст';

  @override
  String get demandLetterCopied => 'Лист скопійовано в буфер обміну';

  @override
  String get demandLetterExportPdf => 'Експортувати PDF';

  @override
  String get demandLetterExporting => 'Експортуємо…';

  @override
  String get demandLetterExportFailed =>
      'Не вдалося експортувати документ. Спробуйте ще раз.';

  @override
  String get demandLetterSendEmail => 'Надіслати електронною поштою';

  @override
  String get demandLetterNormsTitle => 'Правові посилання';

  @override
  String get demandLetterDisclaimer =>
      'Цей лист підготовлено від вашого імені як загальний шаблон. Це не юридична консультація й не дія ліцензованого адвоката. Перевірте його перед надсиланням — жоден лист не надсилається автоматично.';

  @override
  String get demandLetterMenuTile => 'Претензійний лист';

  @override
  String get calcHubTitle => 'Юридичні калькулятори';

  @override
  String get calcHubSubtitle => 'Швидкі оцінки перед наступним кроком';

  @override
  String get calcHubJurisdiction => 'Юрисдикція';

  @override
  String calcRatesAsOf(String date) {
    return 'Ставки станом на $date';
  }

  @override
  String get calcRatesOffline => 'Показано збережені ставки (офлайн)';

  @override
  String get calcIndicativeBanner =>
      'Лише орієнтовна оцінка — не офіційний розрахунок і не юридична консультація.';

  @override
  String get calcCalculate => 'Розрахувати';

  @override
  String get calcResult => 'Результат';

  @override
  String get calcFormula => 'Як це розраховано';

  @override
  String get calcSource => 'Джерело';

  @override
  String get calcSeveranceTitle => 'Вихідна допомога / попередження';

  @override
  String get calcSeveranceDesc =>
      'Оцініть вихідну допомогу та строк попередження при скороченні';

  @override
  String get calcSeveranceSalary => 'Місячна зарплата (брутто)';

  @override
  String get calcSeveranceTenure => 'Стаж роботи (років)';

  @override
  String get calcSeveranceTotal => 'Орієнтовна вихідна допомога';

  @override
  String get calcSeveranceNotice => 'Строк попередження';

  @override
  String get calcSeveranceGenerateDemand => 'Скласти претензійний лист';

  @override
  String get calcLimitationTitle => 'Строки давності та оскарження';

  @override
  String get calcLimitationDesc =>
      'Перевірте, чи минув строк для позову або оскарження';

  @override
  String get calcLimitationType => 'Тип строку';

  @override
  String get calcLimitationStart => 'Дата початку (подія / рішення)';

  @override
  String get calcLimitationPickDate => 'Обрати дату';

  @override
  String get calcLimitationDeadline => 'Строк';

  @override
  String get calcLimitationExpired => 'Строк минув';

  @override
  String calcLimitationDaysLeft(int days) {
    return 'Залишилося $days днів';
  }

  @override
  String get calcLimitationShifted =>
      'Перенесено на наступний робочий день (вихідні/свято).';

  @override
  String get calcLimitationAddDeadline => 'Додати до строків';

  @override
  String get calcStateFeeTitle => 'Судові / державні збори';

  @override
  String get calcStateFeeDesc =>
      'Довідкові збори за подання за судом і стадією';

  @override
  String get calcChildSupportTitle => 'Аліменти (орієнтовно)';

  @override
  String get calcChildSupportDesc =>
      'Приблизна орієнтовна сума — реальний розмір визначають у кожній справі окремо';

  @override
  String get calcChildSupportNet => 'Чистий місячний дохід платника';

  @override
  String get calcChildSupportChildren => 'Кількість дітей';

  @override
  String get calcChildSupportPerChild => 'На дитину';

  @override
  String get calcChildSupportTotal => 'Усього на місяць';

  @override
  String get calcChildSupportWarning =>
      'Дуже мінлива величина. Суди вирішують з огляду на потреби дитини та спроможність обох батьків платити. Використовуйте лише як відправну точку.';

  @override
  String get docCollectTitle => 'Документи для збору';

  @override
  String get docCollectSubtitle =>
      'Зберіть їх перед поданням заяви чи зверненням до суду';

  @override
  String get docCollectPickPrompt => 'Яка у вас ситуація?';

  @override
  String get docCollectProblemResidence => 'Посвідка на проживання';

  @override
  String get docCollectProblemTenant => 'Оренда / виселення';

  @override
  String get docCollectProblemDismissal => 'Звільнення з роботи';

  @override
  String get docCollectProblemInheritance => 'Спадщина';

  @override
  String get docCollectProblemDivorce => 'Розлучення';

  @override
  String docCollectProgress(int collected, int total) {
    return 'Зібрано $collected з $total';
  }

  @override
  String get docCollectAllDone => 'Усе зібрано';

  @override
  String get docCollectEmpty =>
      'Переліку документів для цієї ситуації поки немає.';

  @override
  String get docCollectOptional => 'Необов\'язково';

  @override
  String get docCollectWhereLabel => 'Де отримати';

  @override
  String get docCollectWhyLabel => 'Навіщо потрібно';

  @override
  String get docCollectAttach => 'Прикріпити файл';

  @override
  String get docCollectAttached => 'Файл прикріплено';

  @override
  String get docCollectChangeFile => 'Змінити файл';

  @override
  String get docCollectRemoveFile => 'Видалити файл';

  @override
  String get docCollectNoFiles => 'Ви ще не завантажили жодного документа.';

  @override
  String get docCollectPickFileTitle => 'Оберіть завантажений документ';

  @override
  String get docCollectExport => 'Експортувати перелік';

  @override
  String get docCollectExportSubject => 'Мій перелік документів';

  @override
  String get docCollectAiTitle => 'Потрібно щось конкретне?';

  @override
  String get docCollectAiHint =>
      'Опишіть свою ситуацію — і ми запропонуємо додаткові документи.';

  @override
  String get docCollectAiField => 'Опишіть свою ситуацію';

  @override
  String get docCollectAiButton => 'Запропонувати додаткові документи';

  @override
  String get docCollectAiLoading => 'Думаємо…';

  @override
  String get docCollectAiEmpty =>
      'Додаткових документів не запропоновано — базовий перелік виглядає повним для вашого опису.';

  @override
  String get docCollectAiSuggestionsTitle =>
      'Запропоновані додаткові документи';

  @override
  String get docCollectDisclaimer =>
      'Це базовий перелік документів, які зазвичай потрібні — вашій ситуації може бути потрібно більше або менше. Це загальна інформація, а не юридична консультація.';

  @override
  String get docCollectRetry => 'Спробувати ще раз';

  @override
  String get renewalTitle => 'Радар поновлень';

  @override
  String get renewalSubtitle =>
      'Відстежуйте, коли спливає строк дії ваших дозволів, паспорта, страховки та інших документів. Ми нагадаємо за 90, 30 і 7 днів до кожного поновлення.';

  @override
  String get renewalAdd => 'Додати документ';

  @override
  String get renewalEditTitle => 'Редагувати документ';

  @override
  String get renewalSave => 'Зберегти';

  @override
  String get renewalRequired => 'Обов\'язково';

  @override
  String get renewalPickDate => 'Обрати дату закінчення';

  @override
  String get renewalLoadError =>
      'Не вдалося завантажити ваші документи. Потягніть, щоб оновити.';

  @override
  String get renewalEmptyTitle => 'Документів ще не відстежується';

  @override
  String get renewalEmptyBody =>
      'Додайте посвідку на проживання, паспорт, страховку чи права — і ми стежитимемо за датами закінчення замість вас.';

  @override
  String get renewalGuideHint => 'Як поновити →';

  @override
  String get renewalFieldType => 'Тип документа';

  @override
  String get renewalFieldLabel => 'Назва';

  @override
  String get renewalFieldNumber => 'Номер документа (необов\'язково)';

  @override
  String get renewalFieldJurisdiction => 'Країна видачі';

  @override
  String get renewalFieldExpiry => 'Дата закінчення';

  @override
  String get renewalWindow90 => '90 днів';

  @override
  String get renewalWindow30 => '30 днів';

  @override
  String get renewalWindow7 => '7 днів';

  @override
  String get renewalExpiresToday => 'Спливає сьогодні';

  @override
  String renewalExpiresInDays(int days, String date) {
    return 'Спливає через $days днів · $date';
  }

  @override
  String renewalExpiredOn(String date) {
    return 'Сплив $date';
  }

  @override
  String get renewalTypeResidencePermit => 'Посвідка на проживання';

  @override
  String get renewalTypePassport => 'Паспорт';

  @override
  String get renewalTypeIdCard => 'ID-картка';

  @override
  String get renewalTypeVisa => 'Віза';

  @override
  String get renewalTypeDrivingLicence => 'Посвідчення водія';

  @override
  String get renewalTypeInsurance => 'Страховка';

  @override
  String get renewalTypeWorkPermit => 'Дозвіл на роботу';

  @override
  String get renewalTypeOther => 'Інше';

  @override
  String get costEstimateTitle => 'Оцінювач вартості та ризику';

  @override
  String get costEstimateSubtitle =>
      'Отримайте приблизне уявлення про те, скільки може коштувати справа, скільки вона триватиме та чи варто її вести.';

  @override
  String get costEstimateCaseTypeLabel => 'Тип справи';

  @override
  String get costEstimateCaseTypeHint =>
      'напр. несплачений рахунок, незаконне звільнення, спір щодо застави';

  @override
  String get costEstimateJurisdictionLabel => 'Юрисдикція';

  @override
  String get costEstimateAmountLabel => 'Спірна сума (необов\'язково)';

  @override
  String get costEstimateAmountHint => 'напр. 12500';

  @override
  String get costEstimateDescriptionLabel =>
      'Стисло опишіть ситуацію (необов\'язково)';

  @override
  String get costEstimateB2bToggle => 'Картка кваліфікації ліда (B2B)';

  @override
  String get costEstimateB2bSubtitle =>
      'Компактний результат для швидкого сортування вхідного клієнта.';

  @override
  String get costEstimateSubmit => 'Оцінити мою справу';

  @override
  String get costEstimateDisclaimer =>
      'Лише приблизна оцінка — не прогноз, не гарантія й не юридична консультація. Фактичні витрати та результати різняться від справи до справи.';

  @override
  String get costEstimateCostsHeading => 'Орієнтовні витрати';

  @override
  String get costEstimateCourtFee => 'Судовий / державний збір';

  @override
  String get costEstimateLawyerFee => 'Гонорар адвоката';

  @override
  String get costEstimateTotal => 'Усього (приблизно)';

  @override
  String get costEstimateDuration => 'Час до першого рішення';

  @override
  String get costEstimateMonthsSuffix => 'місяців';

  @override
  String get costEstimateFactorsFor => 'На вашу користь';

  @override
  String get costEstimateFactorsAgainst => 'Проти вас';

  @override
  String get costEstimateStrengthWorth => 'Ймовірно, варто вести';

  @override
  String get costEstimateStrengthContested =>
      'Спірно — може скластися по-різному';

  @override
  String get costEstimateStrengthWeak => 'Слабко — дійте обережно';

  @override
  String get deadlineIcsCopied => 'Файл ICS скопійовано до буфера обміну';

  @override
  String get deadlineExportFailed => 'Не вдалося експортувати подію календаря';

  @override
  String get orgSlugAvailable => 'Адреса доступна';

  @override
  String get orgSlugTaken => 'Адресу вже зайнято';

  @override
  String get commonCancel => 'Скасувати';

  @override
  String get commonRemove => 'Видалити';

  @override
  String get orgRemoveFromOrg => 'Видалити з організації';

  @override
  String get orgInvitationResent => 'Запрошення надіслано повторно';

  @override
  String get commonResend => 'Надіслати повторно';

  @override
  String get commonRevoke => 'Відкликати';

  @override
  String get vaultUploadSuccess => 'Документ успішно завантажено';

  @override
  String get vaultView => 'Переглянути';

  @override
  String get vaultPathNotFound => 'Шлях до документа не знайдено';

  @override
  String get vaultUrlFailed => 'Не вдалося створити URL-адресу документа';
}
