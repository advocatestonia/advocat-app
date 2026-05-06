// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get about => 'О приложении';

  @override
  String get aboutSection => 'О ПРИЛОЖЕНИИ';

  @override
  String get accidents => 'ДТП';

  @override
  String get active => 'Активные';

  @override
  String get activeCases => 'Активные дела';

  @override
  String get addedToAppeal => 'Добавлено в жалобу';

  @override
  String get agreeToTerms => 'Я принимаю ';

  @override
  String get aiAnalysis => 'Автоматический анализ';

  @override
  String get aiAssistant => 'Юридический помощник';

  @override
  String get aiChat => 'Консультация';

  @override
  String get all => 'Все';

  @override
  String get alreadyHaveAccount => 'Уже есть аккаунт? ';

  @override
  String get analyzing => 'Анализ…';

  @override
  String get aiAnalyzing => 'ИИ анализирует';

  @override
  String get speakIntoMicHint =>
      'Говорите в микрофон. Убедитесь, что доступ к микрофону разрешён.';

  @override
  String get aiErrorRateLimit =>
      'Сервис временно перегружен. Попробуйте через 1-2 минуты.';

  @override
  String get aiErrorOverload => 'AI сейчас занят, попробуйте через минуту.';

  @override
  String freeLimitReached(int count) {
    return 'Вы использовали все $count бесплатных сообщений ИИ. Перейдите на тариф «Юридический советник» для безлимитной помощи ИИ.';
  }

  @override
  String get andWord => ' и ';

  @override
  String get appTitle => 'Advocat — Умный юридический помощник';

  @override
  String get appVersion => 'Версия приложения';

  @override
  String get appealFiled => 'Жалоба подана';

  @override
  String get areYouAbsolutelySure => 'Вы абсолютно уверены?';

  @override
  String get askAboutCase => 'Проанализировать моё дело';

  @override
  String get asylum => 'Убежище';

  @override
  String get back => 'Назад';

  @override
  String get basic => 'Базовый';

  @override
  String get beforeYouBuy => 'Прежде чем покупать';

  @override
  String get beforeYouWork => 'Прежде чем работать с ними';

  @override
  String get camera => 'Камера';

  @override
  String get cancel => 'Отмена';

  @override
  String get caseDescription => 'Опишите вашу ситуацию';

  @override
  String get caseDetail => 'Сведения о деле';

  @override
  String get caseOverview => 'Обзор вашего дела';

  @override
  String get caseTitle => 'Название дела';

  @override
  String get caseUpdated => 'Дело обновлено';

  @override
  String get cases => 'Дела';

  @override
  String get checkCompany => 'Проверить компанию';

  @override
  String get checkDeadlines => 'Проверить сроки';

  @override
  String get checkVehicle => 'Проверить автомобиль';

  @override
  String get checkerTitle => 'Проверка';

  @override
  String get checkingErrors => 'Проверка на ошибки…';

  @override
  String get choosePlan => 'Выбрать тариф';

  @override
  String get closed => 'Закрытые';

  @override
  String get companyName => 'Название или рег. номер';

  @override
  String get completed => 'Завершено';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get confirmPassword => 'Подтвердите пароль';

  @override
  String get connectEmail => 'Подключить почту';

  @override
  String get connectGmail => 'Подключить Gmail';

  @override
  String get connectOutlook => 'Подключить Outlook';

  @override
  String get connected => 'Подключено';

  @override
  String get contactSupport => 'Связаться с поддержкой';

  @override
  String get continueWithGoogle => 'Продолжить через Google';

  @override
  String get copyText => 'Скопировать текст';

  @override
  String get correspondence => 'Переписка';

  @override
  String get couldNotLoadCases => 'Не удалось загрузить ваши дела';

  @override
  String get country => 'Страна';

  @override
  String get createAccount => 'Создать аккаунт';

  @override
  String get createCase => 'Создать дело';

  @override
  String get criminalCase => 'Уголовное дело';

  @override
  String get critical => 'Критическое';

  @override
  String get currentPlan => 'Текущий тариф';

  @override
  String get dataAndPrivacy => 'ДАННЫЕ И КОНФИДЕНЦИАЛЬНОСТЬ';

  @override
  String get dataExportRequested =>
      'Запрос на экспорт данных отправлен. Проверьте почту.';

  @override
  String daysRemaining(int count) {
    return '$count дн.';
  }

  @override
  String get deadlineReminders => 'Напоминания о сроках';

  @override
  String get deadlineRemindersDesc =>
      'Получайте уведомления о приближающихся сроках';

  @override
  String get deadlines => 'Сроки';

  @override
  String get debtCollection => 'Долги и взыскание';

  @override
  String get deleteAccount => 'Удалить аккаунт';

  @override
  String get deleteAccountDesc => 'Безвозвратно удалить ваш аккаунт';

  @override
  String get deleteAccountDialogContent =>
      'Это действие необратимо. Все ваши данные, дела и документы будут удалены безвозвратно.';

  @override
  String get deleteConfirm =>
      'Вы уверены? Все ваши данные будут удалены безвозвратно.';

  @override
  String get demoHint => 'Демо: введите номер «908FBT»';

  @override
  String get demoModeDesc =>
      'Ознакомьтесь с приложением на примере реального дела';

  @override
  String get deportation => 'Депортация';

  @override
  String get disclaimer =>
      'Это справочная информация, а не юридическая консультация. Всегда обращайтесь к квалифицированному юристу.';

  @override
  String get disclaimerFull =>
      'Это цифровой помощник, а не юрист. Автоматический анализ может содержать неточности. Всегда проверяйте информацию у квалифицированного юриста.';

  @override
  String get disconnect => 'Отключить';

  @override
  String get discrimination => 'Дискриминация';

  @override
  String get doNotBuy => 'Не покупать';

  @override
  String get documents => 'Документы';

  @override
  String documentsCount(int count) {
    return '$count док.';
  }

  @override
  String get draftAppeal => 'Составить жалобу';

  @override
  String get editDraft => 'Редактировать';

  @override
  String get editProfile => 'Редактировать профиль';

  @override
  String get email => 'Электронная почта';

  @override
  String get emailConnected => 'Почта подключена';

  @override
  String get emailDisconnected => 'Почта отключена';

  @override
  String get emailIntegration => 'ИНТЕГРАЦИЯ С ПОЧТОЙ';

  @override
  String get emailInvalid => 'Введите корректный адрес электронной почты';

  @override
  String get emailPrivacyNote =>
      'Мы читаем только письма, связанные с вашим делом. Личная переписка остаётся конфиденциальной.';

  @override
  String get emailRequired => 'Укажите электронную почту';

  @override
  String get emergencyShield => 'Экстренная защита';

  @override
  String get error => 'Ошибка';

  @override
  String get exportDataDesc => 'Скачать все данные по вашим делам';

  @override
  String get exportDataDialogContent =>
      'Мы подготовим загрузку всех ваших данных, включая дела, документы и переписку. Вы получите уведомление на почту, когда файл будет готов.';

  @override
  String get exportMyData => 'Экспорт данных';

  @override
  String get exportPdf => 'Экспорт в PDF';

  @override
  String get familyReunification => 'Воссоединение семьи';

  @override
  String get forgotPassword => 'Забыли пароль?';

  @override
  String get free => 'Бесплатно';

  @override
  String get fullDefense => 'Advocat Pro';

  @override
  String get fullName => 'Полное имя';

  @override
  String get gallery => 'Галерея';

  @override
  String get generateAppeal => 'Сформировать жалобу';

  @override
  String get getStarted => 'Начать';

  @override
  String goodAfternoon(String name) {
    return 'Добрый день, $name';
  }

  @override
  String goodEvening(String name) {
    return 'Добрый вечер, $name';
  }

  @override
  String goodMorning(String name) {
    return 'Доброе утро, $name';
  }

  @override
  String goodNight(String name) {
    return 'Доброй ночи, $name';
  }

  @override
  String get home => 'Главная';

  @override
  String get important => 'Важное';

  @override
  String get inProgress => 'В работе';

  @override
  String get informational => 'Информационное';

  @override
  String get inspection => 'Техосмотр';

  @override
  String get insurance => 'Страховка';

  @override
  String issuesFound(int count) {
    return 'Найдено проблем: $count';
  }

  @override
  String get laborDispute => 'Трудовой спор';

  @override
  String get langEnglish => 'Английский';

  @override
  String get langFinnish => 'Финский';

  @override
  String get langRussian => 'Русский';

  @override
  String get language => 'Язык';

  @override
  String lastActivity(String time) {
    return 'Последнее действие: $time';
  }

  @override
  String get legalFighter => 'Юридический советник';

  @override
  String get legalSection => 'ПРАВОВАЯ ИНФОРМАЦИЯ';

  @override
  String get licensePlate => 'Номерной знак';

  @override
  String get loading => 'Загрузка…';

  @override
  String get logIn => 'Войти';

  @override
  String get loginFailed => 'Неверная почта или пароль. Попробуйте ещё раз.';

  @override
  String get lost => 'Проиграно';

  @override
  String get markComplete => 'Отметить как выполненное';

  @override
  String get mileage => 'Пробег';

  @override
  String get myCases => 'Мои дела';

  @override
  String get nameRequired => 'Укажите полное имя';

  @override
  String get newCase => 'Новое дело';

  @override
  String get next => 'Далее';

  @override
  String get noAccount => 'Нет аккаунта? ';

  @override
  String get noCases => 'Дел пока нет';

  @override
  String get noCasesYet => 'Дел пока нет';

  @override
  String get noDeadlines => 'Нет предстоящих сроков — всё в порядке!';

  @override
  String get noRecentActivity => 'Нет недавних действий';

  @override
  String get notifications => 'УВЕДОМЛЕНИЯ';

  @override
  String get onboardingDesc1 =>
      'Advocat помогает разобраться в вашей юридической ситуации. Система анализирует документы, выявляет возможные нарушения и подготавливает черновики документов для вашей проверки. Это не юридическая фирма — это цифровой инструмент для поддержки вашего дела.';

  @override
  String get onboardingDesc2 =>
      'Сфотографируйте любой юридический документ. Система прочитает его на нескольких языках, извлечёт ключевые детали и проверит на соответствие директивам ЕС и национальному законодательству.';

  @override
  String get onboardingDesc3 =>
      'Система проверяет более 40 видов процессуальных требований — язык вручения решения, соблюдение сроков, правильность оформления и многое другое. Результаты рекомендуется проверить у квалифицированного юриста.';

  @override
  String get onboardingDesc4 =>
      'Система подготавливает черновики жалоб, заявлений и писем со ссылками на законодательство. Вы решаете, что подавать. Каждый документ рекомендуется проверить у квалифицированного юриста перед подачей.';

  @override
  String get onboardingNext => 'Далее';

  @override
  String get onboardingSkip => 'Пропустить';

  @override
  String get onboardingTitle1 => 'Умный юридический помощник';

  @override
  String get onboardingTitle2 => 'Сканируйте и анализируйте документы';

  @override
  String get onboardingTitle3 => 'Автоматическая проверка нарушений';

  @override
  String get onboardingTitle4 => 'Черновики документов для вашей проверки';

  @override
  String get openACase => 'Открыть дело';

  @override
  String get optional => '(необязательно)';

  @override
  String get orDivider => 'или';

  @override
  String get other => 'Другое';

  @override
  String get overdue => 'Просрочено';

  @override
  String get owners => 'Предыдущие владельцы';

  @override
  String get password => 'Пароль';

  @override
  String get passwordRequired => 'Введите пароль';

  @override
  String get passwordStrengthMedium => 'Средний';

  @override
  String get passwordStrengthStrong => 'Надёжный';

  @override
  String get passwordStrengthWeak => 'Слабый';

  @override
  String get passwordTooShort => 'Пароль должен содержать не менее 8 символов';

  @override
  String get passwordsDoNotMatch => 'Пароли не совпадают';

  @override
  String get pendingDecision => 'Ожидание решения';

  @override
  String get perCheck => 'за проверку';

  @override
  String get permanentlyDelete => 'Удалить безвозвратно';

  @override
  String get policeMisconduct => 'Действия полиции';

  @override
  String get popular => 'ПОПУЛЯРНОЕ';

  @override
  String get preferences => 'НАСТРОЙКИ';

  @override
  String get preferredLanguage => 'Предпочитаемый язык';

  @override
  String get pricePerCheck => '4,99 € за проверку';

  @override
  String get privacyPolicy => 'Политику конфиденциальности';

  @override
  String get pro => 'Профессиональный';

  @override
  String get pushNotifications => 'Push-уведомления';

  @override
  String get rateUs => 'Оценить приложение';

  @override
  String get rateAppComingSoon => 'Скоро в магазинах приложений!';

  @override
  String get dataCopiedToClipboard => 'Данные скопированы в буфер обмена';

  @override
  String get readingDocument => 'Чтение документа…';

  @override
  String get recentActivity => 'Последние действия';

  @override
  String get referenceNumber => 'Номер дела';

  @override
  String get registerFailed =>
      'Не удалось зарегистрироваться. Попробуйте ещё раз.';

  @override
  String get reportFraud => 'Сообщить о мошенничестве';

  @override
  String get requestExport => 'Запросить экспорт';

  @override
  String get researchingLaw => 'Изучение применимого законодательства…';

  @override
  String get resetPasswordFailed =>
      'Не удалось отправить ссылку. Попробуйте ещё раз.';

  @override
  String get resetPasswordSent =>
      'Ссылка для сброса пароля отправлена на вашу почту.';

  @override
  String get residencePermit => 'Вид на жительство';

  @override
  String get manageSubscription => 'Управление подпиской';

  @override
  String get restorePurchases => 'Восстановить покупки';

  @override
  String get retry => 'Повторить';

  @override
  String get reviewWarning =>
      'Внимательно проверьте текст перед отправкой. Вы несёте ответственность за содержание.';

  @override
  String get riskHigh => 'Высокий риск — избегайте';

  @override
  String get riskLow => 'Безопасно для работы';

  @override
  String get riskMedium => 'Будьте осторожны';

  @override
  String get safeToBuy => 'Безопасно покупать';

  @override
  String get saveAndAnalyze => 'Сохранить и проанализировать';

  @override
  String get saveDraft => 'Сохранить';

  @override
  String get saveWithAnnual => 'Экономия 25% при оплате за год';

  @override
  String get scan => 'Скан';

  @override
  String get scanDocument => 'Сканировать документ';

  @override
  String get searchCases => 'Поиск дел…';

  @override
  String get selectCountry => 'Выберите страну';

  @override
  String get selectLanguage => 'Выберите язык';

  @override
  String get sendViaEmail => 'Отправить по почте';

  @override
  String get settings => 'Настройки';

  @override
  String get signIn => 'Войти';

  @override
  String get signInLink => 'Войти';

  @override
  String get signInSubtitle => 'Войдите, чтобы получить доступ к вашим делам';

  @override
  String get signOut => 'Выйти';

  @override
  String get signOutConfirm => 'Вы уверены, что хотите выйти?';

  @override
  String get signUp => 'Создать аккаунт';

  @override
  String get signUpLink => 'Зарегистрироваться';

  @override
  String get socialBenefits => 'Социальные пособия';

  @override
  String get someConcerns => 'Есть замечания';

  @override
  String get startFirstCase => 'Создайте ваше первое дело';

  @override
  String step(int current, int total) {
    return 'Шаг $current из $total';
  }

  @override
  String get stolen => 'Проверка на угон';

  @override
  String get subscription => 'Подписка';

  @override
  String get syncLegalCorrespondence => 'Синхронизация юридической переписки';

  @override
  String get syncNow => 'Синхронизировать';

  @override
  String get tenantRights => 'Права арендатора';

  @override
  String get termsOfService => 'Условия использования';

  @override
  String get termsRequired => 'Необходимо принять Условия использования';

  @override
  String get timeline => 'Хронология';

  @override
  String get tryDemoMode => 'Попробовать демо-режим';

  @override
  String get typeDeleteToConfirm =>
      'Введите DELETE для подтверждения удаления аккаунта.';

  @override
  String get typeMessage => 'Введите сообщение…';

  @override
  String get upcoming => 'Предстоящие';

  @override
  String get uploadDocument => 'Загрузить документ';

  @override
  String urgentDeadline(String title) {
    return 'Срочно: $title';
  }

  @override
  String get useInAppeal => 'Использовать в жалобе';

  @override
  String get vehicleChecker => 'Проверка авто';

  @override
  String get vehicleChecks => 'Проверки';

  @override
  String get vehicleColor => 'Цвет';

  @override
  String get vehicleMake => 'Марка';

  @override
  String get vehicleModel => 'Модель';

  @override
  String get vehicleYear => 'Год выпуска';

  @override
  String get version => 'Версия';

  @override
  String get victimSupport => 'Помощь пострадавшим';

  @override
  String get viewAll => 'Все';

  @override
  String get vinNumber => 'VIN номер';

  @override
  String get welcomeBack => 'С возвращением';

  @override
  String get whatAreMyOptions => 'Какие у меня варианты?';

  @override
  String get won => 'Выиграно';

  @override
  String get documentVault => 'Хранилище документов';

  @override
  String get secureDocumentStorage => 'Безопасное хранилище документов';

  @override
  String get secureDocumentStorageDesc =>
      'Храните важные юридические документы в одном месте для быстрого доступа.';

  @override
  String get addDocument => 'Добавить документ';

  @override
  String get chooseHowToAdd => 'Выберите способ добавления документа';

  @override
  String get uploadFile => 'Загрузить файл';

  @override
  String get uploadFileDesc => 'Выберите PDF или изображение с устройства';

  @override
  String get scanDocumentDesc => 'Сфотографировать документ';

  @override
  String get createNote => 'Создать заметку';

  @override
  String get createNoteDesc => 'Записать заметку или важные детали';

  @override
  String get knowYourRights => 'Знайте свои права';

  @override
  String get stoppedByPolice => 'Остановила полиция';

  @override
  String get stoppedByPoliceDesc => 'Ваши права при встрече с полицией';

  @override
  String get deportationNotice => 'Уведомление о депортации';

  @override
  String get deportationNoticeDesc => 'Как обжаловать решение о выдворении';

  @override
  String get workplaceRights => 'Трудовые права';

  @override
  String get workplaceRightsDesc => 'Защита трудовых прав в Эстонии';

  @override
  String get tenantRightsDesc => 'Жилищные права и защита арендаторов';

  @override
  String get immigrationDetention => 'Задержание мигрантов';

  @override
  String get immigrationDetentionDesc => 'Права при задержании властями';

  @override
  String get discriminationDesc =>
      'Как сообщить о дискриминации и бороться с ней';

  @override
  String get scenarioNotFound => 'Сценарий не найден';

  @override
  String get youHaveRightTo => 'Вы имеете право:';

  @override
  String get youMust => 'Вы обязаны:';

  @override
  String get immediateSteps => 'Немедленные действия:';

  @override
  String get yourRights => 'Ваши права:';

  @override
  String get basicRights => 'Основные права:';

  @override
  String get yourRightsAsTenant => 'Ваши права как арендатора:';

  @override
  String get yourRightsInDetention => 'Ваши права при задержании:';

  @override
  String get howToAct => 'Что делать:';

  @override
  String get rightKnowWhyStopped => 'Узнать причину остановки';

  @override
  String get rightRemainSilent => 'Хранить молчание (но назвать себя обязаны)';

  @override
  String get rightAskInterpreter => 'Попросить переводчика';

  @override
  String get rightContactLawyer => 'Связаться с адвокатом до допроса';

  @override
  String get rightRecordEncounter =>
      'Записывать встречу (в общественных местах)';

  @override
  String get mustProvideName => 'Назвать имя и дату рождения';

  @override
  String get mustShowId => 'Показать удостоверение личности, если есть';

  @override
  String get mustNotResist => 'Не оказывать физического сопротивления';

  @override
  String get doNotIgnoreNotice => 'НЕ игнорируйте уведомление — сроки строгие';

  @override
  String get noteAppealDeadline => 'Запишите срок обжалования (обычно 30 дней)';

  @override
  String get contactLawyerImmediately => 'Немедленно свяжитесь с адвокатом';

  @override
  String get applyLegalAid => 'Подайте заявление на юридическую помощь';

  @override
  String get rightAppealAdmin => 'Право обжаловать в Административном суде';

  @override
  String get rightLegalRep => 'Право на юридическое представительство';

  @override
  String get rightInterpreter => 'Право на переводчика';

  @override
  String get rightStayDuringAppeal =>
      'Право оставаться на время обжалования (в большинстве случаев)';

  @override
  String get minimumWage => 'Минимальная зарплата по коллективному договору';

  @override
  String get workingTimeLimits =>
      'Ограничения рабочего времени (не более 8 ч/день, 40 ч/неделя)';

  @override
  String get annualLeave =>
      'Ежегодный отпуск (минимум 2 дня за отработанный месяц)';

  @override
  String get sickLeave => 'Оплата больничного';

  @override
  String get safeWorkingConditions => 'Безопасные условия труда';

  @override
  String get writtenRentalAgreement => 'Требуется письменный договор аренды';

  @override
  String get securityDeposit => 'Залог — максимум 3 месяца аренды';

  @override
  String get landlordNotice => 'Арендодатель обязан уведомить за 3–6 месяцев';

  @override
  String get rightHabitableDwelling => 'Право на пригодное для жизни жильё';

  @override
  String get protectionUnjustEviction => 'Защита от незаконного выселения';

  @override
  String get rightKnowDetentionReason => 'Право знать причину задержания';

  @override
  String get rightContactLawyerDetention => 'Право связаться с адвокатом';

  @override
  String get rightContactEmbassy => 'Право связаться с посольством';

  @override
  String get rightChallengeDetention => 'Право обжаловать задержание в суде';

  @override
  String get rightHumaneTreatment =>
      'Право на гуманное обращение и медицинскую помощь';

  @override
  String get documentIncident =>
      'Задокументируйте инцидент (дата, время, свидетели)';

  @override
  String get fileComplaintOmbudsman =>
      'Подайте жалобу Уполномоченному по вопросам дискриминации';

  @override
  String get contactLegalAidOffice => 'Обратитесь в бюро юридической помощи';

  @override
  String get reportToPolice =>
      'Обратитесь в полицию при преступлении (угроза, нападение)';

  @override
  String get legalAidCalculator => 'Калькулятор юридической помощи';

  @override
  String checkEligibility(String country) {
    return 'Проверьте право на юридическую помощь: $country';
  }

  @override
  String get estimateDisclaimer =>
      'Это приблизительная оценка. Решение принимает Бюро юридической помощи.';

  @override
  String get monthlyIncome => 'Ежемесячный доход (EUR)';

  @override
  String get totalAssets => 'Общая сумма активов (EUR)';

  @override
  String get numberOfDependents => 'Количество иждивенцев';

  @override
  String get calculateEligibility => 'Рассчитать право на помощь';

  @override
  String get likelyEligible => 'Вероятно, имеете право';

  @override
  String get mayNotQualify => 'Возможно, не подходите';

  @override
  String get fullFreeLegalAid =>
      'Вы, вероятно, имеете право на полную бесплатную юридическую помощь (без доплаты).';

  @override
  String legalAidWithCopay(String percent) {
    return 'Вы можете получить юридическую помощь с доплатой $percent%.';
  }

  @override
  String get mayNotQualifyDesc =>
      'По предварительной оценке, вы можете не иметь права на государственную юридическую помощь. Рассмотрите обращение к частному адвокату или юридической клинике.';

  @override
  String get couldNotLoadDeadlines => 'Не удалось загрузить сроки';

  @override
  String get noUpcomingDeadlines => 'Нет предстоящих сроков';

  @override
  String get allClearDeadlines =>
      'Всё в порядке! Новые сроки появятся здесь, когда будут установлены.';

  @override
  String get nothingOverdue => 'Нет просроченных';

  @override
  String get greatJobDeadlines => 'Отлично! Вы не пропускаете сроки.';

  @override
  String get noCompletedDeadlines => 'Нет завершённых сроков';

  @override
  String get completedDeadlinesDesc =>
      'Завершённые сроки будут отображаться здесь.';

  @override
  String get daysLate => 'дн. просрочки';

  @override
  String get days => 'дн.';

  @override
  String get fromDocument => 'Из документа';

  @override
  String get couldNotLoadCase => 'Не удалось загрузить данные дела';

  @override
  String get typeLabel => 'Тип';

  @override
  String get nationality => 'Гражданство';

  @override
  String get migriReference => 'Номер Migri';

  @override
  String get courtCaseNo => 'Номер дела в суде';

  @override
  String get created => 'Создано';

  @override
  String get citizenship => 'Гражданство';

  @override
  String get workPermit => 'Разрешение на работу';

  @override
  String get noDocumentsYet => 'Документы ещё не загружены';

  @override
  String get noUpcomingDeadlinesShort => 'Нет предстоящих сроков';

  @override
  String get caseCreated => 'Дело создано';

  @override
  String get decisionReceived => 'Решение получено';

  @override
  String get appealDeadline => 'Срок обжалования';

  @override
  String get hearingScheduled => 'Назначено слушание';

  @override
  String get late => 'просрочено';

  @override
  String get pending => 'Ожидание';

  @override
  String get processing => 'Обработка';

  @override
  String get ready => 'Готово';

  @override
  String get failed => 'Ошибка';

  @override
  String get analyzed => 'Проанализировано';

  @override
  String get noDocumentsScanHint =>
      'Документов пока нет. Отсканируйте или загрузите.';

  @override
  String get inCourt => 'В суде';

  @override
  String get appeal => 'Жалоба';

  @override
  String get caseTimeline => 'Хронология дела';

  @override
  String get couldNotLoadTimeline => 'Не удалось загрузить хронологию';

  @override
  String get noEventsYet => 'Событий пока нет';

  @override
  String get activityWillAppear =>
      'Активность будет отображаться здесь по мере развития дела.';

  @override
  String caseCreatedDesc(String title) {
    return 'Дело «$title» создано.';
  }

  @override
  String get decisionReceivedDesc =>
      'Получено официальное решение по данному делу.';

  @override
  String get appealDeadlineSet => 'Установлен срок обжалования';

  @override
  String appealDeadlineDesc(String date) {
    return 'Жалоба должна быть подана до $date.';
  }

  @override
  String hearingScheduledDesc(String date) {
    return 'Слушание в суде назначено на $date.';
  }

  @override
  String get caseInfoUpdated => 'Информация по делу обновлена.';

  @override
  String get documentAnalysis => 'Анализ документа';

  @override
  String get exportAsPdf => 'Экспорт в PDF';

  @override
  String get pdfExportComingSoon => 'Экспорт в PDF скоро будет доступен';

  @override
  String get analysisFailedRetry => 'Анализ не удался. Попробуйте снова.';

  @override
  String get somethingWentWrong => 'Что-то пошло не так';

  @override
  String get retryAnalysis => 'Повторить анализ';

  @override
  String issuesFoundInDocument(int count) {
    return 'Найдено проблем в документе: $count';
  }

  @override
  String get severityOverview => 'Обзор критичности';

  @override
  String get issuesFoundHeader => 'Найденные проблемы';

  @override
  String generateAppealWithIssues(int count) {
    return 'Сформировать жалобу ($count проблем)';
  }

  @override
  String get analyzingContent => 'Анализ содержания…';

  @override
  String get documentProcessedOk => 'Документ обработан успешно';

  @override
  String get noSignificantIssues =>
      'В этом документе не обнаружено существенных проблем.';

  @override
  String get cameraPermissionRequired => 'Требуется разрешение камеры';

  @override
  String get cameraPermissionDesc =>
      'Предоставьте доступ к камере для сканирования документов или используйте галерею.';

  @override
  String get openSettings => 'Открыть настройки';

  @override
  String get alignDocument => 'Расположите документ в рамке';

  @override
  String pageCount(int count) {
    return '$count стр.';
  }

  @override
  String get preview => 'Предпросмотр';

  @override
  String pageNumber(int number) {
    return 'Страница $number';
  }

  @override
  String get done => 'Готово';

  @override
  String get retake => 'Переснять';

  @override
  String get useThisPhoto => 'Использовать фото';

  @override
  String get addPage => 'Добавить страницу';

  @override
  String uploadingPercent(int percent) {
    return 'Загрузка… $percent%';
  }

  @override
  String get preparingUpload => 'Подготовка загрузки…';

  @override
  String get documentUploadedSuccess => 'Документ успешно загружен';

  @override
  String pagesUploadedSuccess(int count) {
    return 'Загружено страниц: $count';
  }

  @override
  String get uploadFailed =>
      'Загрузка не удалась. Проверьте подключение и попробуйте снова.';

  @override
  String get capturePhotoFailed => 'Не удалось сделать фото. Попробуйте снова.';

  @override
  String get readingText => 'Распознавание текста…';

  @override
  String get draftDocument => 'Черновик документа';

  @override
  String get saveChanges => 'Сохранить изменения';

  @override
  String get editDocument => 'Редактировать документ';

  @override
  String get generatingDraft => 'Подготовка черновика…';

  @override
  String get generatingDraftDesc =>
      'Система готовит юридический документ на основе вашего дела и выбранных проблем.';

  @override
  String get failedToGenerateDraft =>
      'Не удалось сгенерировать черновик. Попробуйте снова.';

  @override
  String get changesSaved => 'Изменения сохранены';

  @override
  String get copiedToClipboard => 'Скопировано в буфер обмена';

  @override
  String get emailComingSoon => 'Отправка по почте скоро будет доступна';

  @override
  String get reviewBeforeSending =>
      'Внимательно проверьте перед отправкой. Вы несёте ответственность за содержание документа.';

  @override
  String get noContentAvailable => 'Содержание недоступно';

  @override
  String get save => 'Сохранить';

  @override
  String get edit => 'Редактировать';

  @override
  String get pdf => 'PDF';

  @override
  String get copy => 'Копировать';

  @override
  String get appealDraft => 'Черновик жалобы';

  @override
  String selected(int count) {
    return 'Выбрано: $count';
  }

  @override
  String get deleteSelected => 'Удалить выбранные';

  @override
  String deleteDocumentsConfirm(int count) {
    return 'Удалить документов: $count?';
  }

  @override
  String get delete => 'Удалить';

  @override
  String get analyzeSelected => 'Анализировать выбранные';

  @override
  String get batchAnalysisStarting => 'Запуск пакетного анализа…';

  @override
  String get switchToList => 'Переключить на список';

  @override
  String get switchToGrid => 'Переключить на сетку';

  @override
  String get scanNew => 'Сканировать';

  @override
  String get noDocumentsYetScan => 'Документов пока нет';

  @override
  String get scanFirstDocumentHint =>
      'Отсканируйте первый документ, чтобы система проанализировала его на ошибки и подготовила жалобу.';

  @override
  String get failedToLoadDocuments => 'Не удалось загрузить документы';

  @override
  String get emailIntegrationTitle => 'Интеграция с email';

  @override
  String get connectYourEmail => 'Подключите почту';

  @override
  String get connectYourEmailDesc =>
      'Подключите email для автоматического обнаружения и организации юридической переписки по вашим делам.';

  @override
  String get legalEmails => 'Юридические письма';

  @override
  String get unlinkedEmails => 'Непривязанные письма';

  @override
  String get noLegalEmailsYet => 'Юридических писем пока нет';

  @override
  String get legalEmailsWillAppear =>
      'Здесь появятся письма, классифицированные как юридические.';

  @override
  String get assignToCase => 'Привязать к делу';

  @override
  String get disconnectEmail => 'Отключить email';

  @override
  String get disconnectEmailConfirm =>
      'Автоматическая синхронизация email будет остановлена. Ранее синхронизированные письма останутся в делах.';

  @override
  String connectedTo(String email) {
    return 'Подключено к $email';
  }

  @override
  String lastSynced(String time) {
    return 'Синхронизировано: $time';
  }

  @override
  String get filterByType => 'Фильтр по типу';

  @override
  String get noCasesMatchSearch => 'Нет дел по вашему запросу';

  @override
  String get failedToLoadCases => 'Не удалось загрузить дела';

  @override
  String get monthly => 'Ежемесячный';

  @override
  String get annual => 'Годовой';

  @override
  String get saveTwentyFivePercent => 'Скидка 25%';

  @override
  String get mostPopular => 'ПОПУЛЯРНЫЙ';

  @override
  String get oneCaseActive => '1 активное дело';

  @override
  String get threeCasesActive => '3 активных дела';

  @override
  String get unlimitedCases => 'Безлимитные дела';

  @override
  String get threeDocScans => '3 скана документов';

  @override
  String get twentyDocScans => '20 сканов документов';

  @override
  String get unlimitedDocScans => 'Безлимитное сканирование';

  @override
  String get basicAiAnalysis => 'Базовый анализ ИИ';

  @override
  String get fullAiAnalysis => 'Полный анализ ИИ';

  @override
  String get draftGeneration => 'Генерация черновиков';

  @override
  String get priorityProcessing => 'Приоритетная обработка';

  @override
  String get fiveAiMessagesTotal => '5 сообщений ИИ (за всё время)';

  @override
  String get hundredAiMessagesDay => '100 сообщений ИИ/день';

  @override
  String get unlimitedAiMessages => 'Безлимитные сообщения ИИ';

  @override
  String get voiceInput => 'Голосовой ввод';

  @override
  String get strategyRecommendations => 'Рекомендации по стратегии';

  @override
  String get foundingMemberNote =>
      'Член-основатель: 9,99 €/мес первые 3 месяца';

  @override
  String get saveTwentyPercent => 'Экономия 20%';

  @override
  String get forever => 'навсегда';

  @override
  String get perMonth => '/мес';

  @override
  String get perYear => '/год';

  @override
  String get checkingPurchases => 'Проверка предыдущих покупок…';

  @override
  String get noPreviousPurchases => 'Предыдущие покупки не найдены.';

  @override
  String get chatWelcomeMessage =>
      'Привет! Я Advocat — твой AI-юридический ассистент. Я предоставляю правовую информацию, а не юридический совет. С чем я могу помочь?';

  @override
  String get copySummary => 'Скопировать сводку';

  @override
  String get caseSummaryCopied => 'Сводка дела скопирована';

  @override
  String get openCase => 'Открыть дело';

  @override
  String get viewFull => 'Полный вид';

  @override
  String get draftCopiedToClipboard => 'Черновик скопирован в буфер';

  @override
  String get reportMileageFraud => 'Сообщить о мошенничестве с пробегом';

  @override
  String get reportMileageFraudDesc =>
      'Будет создан отчёт о мошенничестве на основе данных проверки. Вы также можете открыть юридическое дело.';

  @override
  String get reportAndOpenCase => 'Сообщить и открыть дело';

  @override
  String get caseCreationComingSoon =>
      'Создание дела с предзаполнением — скоро';

  @override
  String get failedToCreateCaseRetry =>
      'Не удалось создать дело. Попробуйте ещё раз.';

  @override
  String get takePhotoInstead => 'Сделать фото';

  @override
  String get deleteCase => 'Удалить дело';

  @override
  String deleteCaseConfirm(String title) {
    return 'Вы уверены, что хотите удалить «$title»? Это действие нельзя отменить.';
  }

  @override
  String get haveQuestionsAi => 'Есть вопросы? Спросите ИИ';

  @override
  String get cookiePolicy => 'Политика cookie';

  @override
  String get aiDisclaimer => 'Оговорка об ответственности ИИ';

  @override
  String get dataPrivacyConsent => 'Согласие на обработку данных';

  @override
  String get gdprIntro =>
      'Для предоставления юридической помощи с ИИ мы обрабатываем ваши данные в соответствии с GDPR (EU 2016/679). Продолжая, вы соглашаетесь с:';

  @override
  String get gdprChat => 'Обработка сообщений чата с помощью ИИ';

  @override
  String get gdprDocs => 'Анализ загруженных документов';

  @override
  String get gdprStorage => 'Зашифрованное хранение данных дел';

  @override
  String get gdprDelete => 'Право удалить свои данные в любое время';

  @override
  String get gdprFooter =>
      'Ваши данные зашифрованы и никогда не передаются третьим лицам. Вы можете отозвать согласие и удалить все данные в Настройках.';

  @override
  String get gdprConsentAiProcessing =>
      'Я согласен на обработку моих данных для юридической помощи ИИ (обязательно)';

  @override
  String get gdprConsentAnalytics =>
      'Я согласен на аналитику для улучшения сервиса (необязательно)';

  @override
  String get gdprArt9Intro =>
      'Это приложение обрабатывает особые категории персональных данных в соответствии со статьёй 9 GDPR, включая:';

  @override
  String get gdprSpecialLegalCases =>
      'Данные вашего судебного дела и судебные документы';

  @override
  String get gdprSpecialNationality => 'Гражданство и иммиграционный статус';

  @override
  String get gdprConsentLegalData =>
      'Я даю согласие на обработку данных моего дела, гражданства и иммиграционного статуса с помощью ИИ (обязательно)';

  @override
  String get gdprConsentVoice =>
      'Я даю согласие на обработку голосовых записей (необязательно)';

  @override
  String get gdprViewPrivacyPolicy => 'Политика конфиденциальности';

  @override
  String get legalInformation => 'Юридическая информация';

  @override
  String get legalEntityName => 'Vorantis OÜ';

  @override
  String get legalRegistryCode => 'Регистрационный код: 17098992';

  @override
  String get legalAddress =>
      'Harju maakond, Tallinn, Kesklinna linnaosa, Tornimäe tn 5, 10145';

  @override
  String get legalEmail => 'E-mail: support@advocat.ee';

  @override
  String get legalRegistry =>
      'Зарегистрировано в Коммерческом регистре Эстонии (Äriregister)';

  @override
  String get aiGeneratedDisclaimer =>
      'Создано ИИ • Не является юридической консультацией';

  @override
  String get decline => 'Отклонить';

  @override
  String get iAgree => 'Согласен';

  @override
  String get iAgreeToThe => 'Я принимаю ';

  @override
  String get orWord => 'или';

  @override
  String get english => 'Английский';

  @override
  String get russian => 'Русский';

  @override
  String get finnish => 'Финский';

  @override
  String successSubscribed(String plan) {
    return 'Подписка на $plan оформлена!';
  }

  @override
  String paymentFailed(String error) {
    return 'Ошибка оплаты: $error';
  }

  @override
  String get whatToDo => 'Что делать';

  @override
  String get getHelp => 'Получить помощь';

  @override
  String get share => 'Поделиться';

  @override
  String get didYouKnow => 'Знаете ли вы?';

  @override
  String get mustKnow => 'Важно знать';

  @override
  String get goodToKnow => 'Полезно знать';

  @override
  String get sentFromAdvocat => 'Отправлено из приложения Advocat';

  @override
  String get policeActionStayCalm =>
      'Сохраняйте спокойствие и держите руки на виду';

  @override
  String get policeActionAskWhy =>
      'Спросите полицейского, почему вас остановили';

  @override
  String get policeActionProvideName => 'Назовите своё имя и дату рождения';

  @override
  String get policeActionWantLawyer =>
      'Чётко заявите: «Я хочу адвоката до начала любых допросов»';

  @override
  String get policeActionAskInterpreter =>
      'При необходимости попросите переводчика';

  @override
  String get policeActionNoteBadge =>
      'Запишите имя и номер жетона полицейского';

  @override
  String get policeFactMustTellReason =>
      'В Эстонии полиция обязана сообщить вам причину остановки. Если они этого не делают, вы можете спросить — они обязаны объяснить по закону.';

  @override
  String get policeFactCanRecord =>
      'В Эстонии вы можете записывать взаимодействие с полицией в общественных местах. Это защищено свободой слова.';

  @override
  String get contactFinnishLegalAid =>
      'Государственная правовая помощь Эстонии';

  @override
  String get contactNonDiscriminationOmbudsman =>
      'Омбудсмен по вопросам недискриминации';

  @override
  String get deportationDeadlineAppeal =>
      'Обжалование в Административный суд — обычно 30 дней с момента уведомления';

  @override
  String get deportationDeadlineLegalAid =>
      'Подайте заявку на юридическую помощь — сделайте это НЕМЕДЛЕННО';

  @override
  String get deportationFactStayDuringAppeal =>
      'В Эстонии вы обычно имеете право оставаться в стране, пока рассматривается ваша апелляция. Депортация не может произойти во время активной апелляции в большинстве случаев.';

  @override
  String get contactRefugeeAdviceCentre =>
      'Финский консультационный центр для беженцев';

  @override
  String get contactAdminCourtHelsinki => 'Административный суд Хельсинки';

  @override
  String get workplaceActionKeepContract => 'Храните копии трудового договора';

  @override
  String get workplaceActionTrackHours =>
      'Самостоятельно отслеживайте рабочее время';

  @override
  String get workplaceActionReportUnsafe =>
      'Сообщайте о небезопасных условиях в службу охраны труда';

  @override
  String get workplaceActionJoinUnion => 'Вступите в профсоюз для защиты';

  @override
  String get workplaceActionContactAuthority =>
      'При необходимости обратитесь в Управление охраны труда';

  @override
  String get workplaceFactCollectiveWage =>
      'В Эстонии правительство устанавливает государственную минимальную зарплату. Работодатель обязан платить не менее установленного минимума.';

  @override
  String get workplaceFactOralContract =>
      'Даже без письменного договора вы имеете полные трудовые права в Эстонии. Устное соглашение юридически равноценно.';

  @override
  String get contactOccupationalSafety => 'Управление охраны труда';

  @override
  String get contactTradeUnionSAK => 'Профсоюзная консультация (SAK)';

  @override
  String get tenantActionWrittenAgreement =>
      'Всегда заключайте письменный договор аренды';

  @override
  String get tenantActionDocumentCondition =>
      'Зафиксируйте состояние квартиры при заселении (фото)';

  @override
  String get tenantActionReportMaintenance =>
      'Сообщайте о проблемах с обслуживанием в письменной форме';

  @override
  String get tenantActionNoIllegalEviction =>
      'Никогда не соглашайтесь на незаконное выселение — решает суд';

  @override
  String get tenantActionContactAdvisory =>
      'Обратитесь в консультационную службу арендаторов при спорах';

  @override
  String get tenantFactNoEvictionWithoutCourt =>
      'Арендодатель в Эстонии не может выселить вас без решения суда, даже если срок аренды истёк. Замена замков или отключение коммунальных услуг незаконны.';

  @override
  String get contactTenantsAssociation => 'Союз квартирных товариществ Эстонии';

  @override
  String get contactConsumerDisputesBoard =>
      'Комиссия по потребительским спорам';

  @override
  String get detentionActionAskDecision =>
      'Немедленно потребуйте письменное решение о задержании';

  @override
  String get detentionActionRequestLawyer => 'Потребуйте связаться с адвокатом';

  @override
  String get detentionActionContactEmbassy =>
      'Свяжитесь с вашим посольством или консульством';

  @override
  String get detentionActionAskMedical =>
      'При необходимости попросите медицинскую помощь';

  @override
  String get detentionActionRequestInterpreter =>
      'Требуйте переводчика для всех процедур';

  @override
  String get detentionDeadlineCourtReview =>
      'Районный суд должен рассмотреть задержание в течение 4 дней';

  @override
  String get detentionDeadlineContinuation =>
      'Суд пересматривает продление каждые 2 недели';

  @override
  String get detentionFactCourtReview =>
      'Иммиграционное задержание в Эстонии должно быть рассмотрено районным судом в течение 4 дней. Если этого не произошло, задержание становится незаконным.';

  @override
  String get contactParliamentaryOmbudsman => 'Парламентский омбудсмен';

  @override
  String get discriminationActionWriteDown =>
      'Запишите точно, что произошло (дата, время, место)';

  @override
  String get discriminationActionSaveEvidence =>
      'Сохраните доказательства: сообщения, письма, свидетелей';

  @override
  String get discriminationActionFileComplaint =>
      'Подайте жалобу Омбудсмену по недискриминации';

  @override
  String get discriminationActionContactLegalAid =>
      'Обратитесь в бюро юридической помощи за бесплатной консультацией';

  @override
  String get discriminationActionReportPolice =>
      'Заявите в полицию, если были угрозы или насилие';

  @override
  String get discriminationFactNonDiscriminationAct =>
      'Закон Эстонии о недискриминации охватывает дискриминацию по возрасту, происхождению, национальности, языку, религии, здоровью, инвалидности, сексуальной ориентации и другим личным характеристикам.';

  @override
  String get contactVictimSupportRIKU => 'Служба помощи жертвам (116 006)';

  @override
  String get domesticViolence => 'Домашнее насилие';

  @override
  String get domesticViolenceDesc =>
      'Права жертв, экстренная помощь, запретительные предписания';

  @override
  String get rightCallEmergency =>
      'Вы имеете право позвонить по номеру 112 в любой экстренной ситуации — полиция, скорая, пожарная';

  @override
  String get rightVictimProtection =>
      'Как жертва, вы имеете право на защиту, поддержку и информацию о вашем деле';

  @override
  String get rightRestrainingOrder =>
      'Вы можете подать заявление на запретительное предписание (lähenemiskeeld), чтобы держать обидчика на расстоянии';

  @override
  String get rightVictimInterpreter =>
      'Вы имеете право на переводчика во всех судебных разбирательствах';

  @override
  String get rightMedicalHelp =>
      'Вы имеете право на немедленную медицинскую помощь и документирование травм';

  @override
  String get rightShelter =>
      'Вы имеете право на экстренное убежище — обратитесь в приют или социальные службы';

  @override
  String get mustReportDanger =>
      'Если кто-то в непосредственной опасности, немедленно звоните 112';

  @override
  String get mustDocumentInjuries =>
      'Документируйте все травмы — фото, медицинские записи, письменные заметки';

  @override
  String get domesticActionCallEmergency =>
      'Звоните 112, если вы в непосредственной опасности';

  @override
  String get domesticActionGoToSafe =>
      'Идите в безопасное место — приют, к друзьям, в общественное место';

  @override
  String get domesticActionDocumentEverything =>
      'Документируйте травмы: фотографируйте, получите медицинские записи';

  @override
  String get domesticActionFilePoliceReport =>
      'Подайте заявление в полицию — это можно сделать и позже';

  @override
  String get domesticActionContactShelter =>
      'Свяжитесь с приютом или кризисной горячей линией';

  @override
  String get domesticActionApplyRestraining =>
      'Подайте заявление на запретительное предписание через полицию или суд';

  @override
  String get domesticFactRestrainingOrder =>
      'В Эстонии запретительное предписание (lähenemiskeeld) может быть выдано даже без уголовного дела. Оно запрещает человеку связываться с вами или приближаться к вам.';

  @override
  String get domesticFactVictimDirective =>
      'Согласно Директиве ЕС о жертвах 2012/29/EU, вы имеете право на уважительное обращение, получение информации на понятном вам языке и доступ к службам помощи жертвам — независимо от вашего статуса проживания.';

  @override
  String get domesticDeadlinePoliceReport =>
      'Подайте заявление в полицию — строгого срока нет, но чем раньше, тем лучше для доказательств';

  @override
  String get domesticDeadlineRestraining =>
      'Запретительное предписание — можно подать в любое время';

  @override
  String get contactEmergency => 'Экстренный номер';

  @override
  String get contactShelter => 'Приют (Turvakoti) — телефон доверия';

  @override
  String get contactCrisisHelpline => 'Кризисная линия помощи (Kriisipuhelin)';

  @override
  String get contactNollaLinja =>
      'Nollalinja — линия помощи пострадавшим от насилия';

  @override
  String get inheritance => 'Наследство';

  @override
  String get inheritanceDesc =>
      'Завещания, наследственное имущество, права наследников, обязательная доля, наследственное производство';

  @override
  String get rightInheritanceForced =>
      'Обязательные наследники (дети, супруг) имеют право на обязательную долю независимо от завещания';

  @override
  String get rightInheritanceWill =>
      'Вы имеете право составить завещание — нотариальное завещание имеет наибольшую юридическую силу';

  @override
  String get rightInheritanceRenounce =>
      'От наследства можно отказаться в течение 3 месяцев после получения информации о нём';

  @override
  String get rightInheritanceInfo =>
      'Вы имеете право получить информацию о наследственном имуществе из банков и реестров';

  @override
  String get rightInheritanceDispute =>
      'Несправедливое завещание можно оспорить в суде в пределах срока исковой давности';

  @override
  String get mustFileInheritance =>
      'Начните наследственное производство у нотариуса в разумный срок';

  @override
  String get mustNotifyHeirs =>
      'Все известные наследники должны быть уведомлены о наследственном производстве';

  @override
  String get inheritanceActionGatherDocs =>
      'Соберите документы: свидетельство о смерти, завещание, документы на имущество, выписки из банка';

  @override
  String get inheritanceActionContactNotary =>
      'Обратитесь к нотариусу для начала наследственного производства';

  @override
  String get inheritanceActionCheckDebts =>
      'Проверьте, есть ли долги у наследственного имущества, прежде чем принять наследство';

  @override
  String get inheritanceActionFileCourt =>
      'Для оспаривания завещания подайте иск в суд';

  @override
  String get inheritanceDeadlineRenounce =>
      '3 месяца на отказ от наследства после получения информации';

  @override
  String get inheritanceDeadlineDispute =>
      'Срок исковой давности для оспаривания завещания: зависит от оснований';

  @override
  String get inheritanceFactForced =>
      'В Эстонии нисходящие родственники и супруг имеют право на обязательную долю (1/2 от законной доли) даже при исключении из завещания';

  @override
  String get inheritanceFactNotary =>
      'Все наследственные производства в Эстонии проходят через нотариуса — этот шаг нельзя пропустить';

  @override
  String get consumerProtection => 'Защита потребителей';

  @override
  String get consumerProtectionDesc =>
      'Мошенничество, бракованные товары, возвраты, недобросовестные продавцы';

  @override
  String get rightReturnOnline =>
      'У вас есть 14 дней для отмены онлайн-покупок без объяснения причин (право отказа ЕС)';

  @override
  String get rightDefectiveProduct =>
      'Если товар бракованный, вы имеете право на ремонт, замену или возврат денег';

  @override
  String get rightClearPricing =>
      'Продавцы обязаны указывать чёткие цены со всеми сборами — скрытые расходы незаконны';

  @override
  String get rightComplainBoard =>
      'Вы можете подать бесплатную жалобу в Комиссию по потребительским спорам';

  @override
  String get rightProtectionFraud =>
      'Вы защищены от недобросовестной коммерческой практики и мошенничества';

  @override
  String get mustKeepReceipts =>
      'Сохраняйте все чеки, договоры и переписку с продавцами';

  @override
  String get mustActTimely =>
      'Сообщайте продавцу о дефектах в разумные сроки после обнаружения';

  @override
  String get consumerActionKeepEvidence =>
      'Сохраняйте чеки, скриншоты, электронные письма и все доказательства покупки';

  @override
  String get consumerActionContactSeller =>
      'Сначала свяжитесь с продавцом — опишите проблему письменно';

  @override
  String get consumerActionFileComplaint =>
      'Подайте жалобу в Комиссию по потребительским спорам (kuluttajariitalautakunta)';

  @override
  String get consumerActionContactAuthority =>
      'Обратитесь в службу защиты прав потребителей за бесплатной помощью';

  @override
  String get consumerActionReportFraud =>
      'Сообщите о мошенничестве в полицию и омбудсмену по защите прав потребителей';

  @override
  String get consumerFactWithdrawal =>
      'Согласно Директиве ЕС о правах потребителей 2011/83/EU, у вас есть 14 дней для отказа от любой онлайн- или дистанционной покупки — без объяснения причин. Продавец обязан вернуть деньги в течение 14 дней.';

  @override
  String get consumerFactWarranty =>
      'В Финляндии продавец несёт ответственность за дефекты товара в течение разумного срока (часто 2+ года). Это не зависит от гарантии производителя.';

  @override
  String get consumerDeadlineWithdrawal =>
      'Отмена онлайн-покупки — 14 дней с момента доставки';

  @override
  String get consumerDeadlineDefect =>
      'Сообщите о дефекте продавцу — в течение 2 месяцев после обнаружения (рекомендуется)';

  @override
  String get contactConsumerAdvisory => 'Служба консультирования потребителей';

  @override
  String get contactConsumerOmbudsman =>
      'Омбудсмен по защите прав потребителей (Kuluttaja-asiamies)';

  @override
  String get contactConsumerDisputesBoardDirect =>
      'Комиссия по потребительским спорам';

  @override
  String get caseTypeStepLabel => 'Тип дела';

  @override
  String get detailsStepLabel => 'Детали';

  @override
  String get documentsStepLabel => 'Документы';

  @override
  String get whatTypeOfCase => 'Какой тип дела?';

  @override
  String get selectCategoryDescription =>
      'Выберите категорию, которая лучше всего описывает вашу ситуацию.';

  @override
  String get tellUsAboutCase => 'Расскажите о вашем деле';

  @override
  String get aiHelpsUnderstand =>
      'Эта информация поможет нашему ИИ лучше понять вашу ситуацию.';

  @override
  String get caseTitleHint => 'напр. Обжалование вида на жительство 2026';

  @override
  String get countryJurisdiction => 'Страна / Юрисдикция';

  @override
  String get selectCountryHint => 'Выберите страну';

  @override
  String get referenceNumberHint => 'напр. UMA/12345/2026';

  @override
  String get descriptionOptional => 'Описание (необязательно)';

  @override
  String get descriptionHint =>
      'Кратко опишите вашу ситуацию. Что произошло? Какое решение было принято?';

  @override
  String get uploadFirstDocument => 'Загрузите ваш первый документ';

  @override
  String get uploadDocumentDescription =>
      'Загрузите письмо с решением или любой соответствующий документ. Вы можете пропустить этот шаг и добавить документы позже.';

  @override
  String get tapToUploadFile => 'Нажмите для загрузки файла';

  @override
  String get fileSizeLimit => 'PDF, JPG, PNG до 25 МБ';

  @override
  String get addDocumentsLaterHint =>
      'Вы всегда можете добавить документы позже на странице дела.';

  @override
  String get callAI => 'Звонок ИИ';

  @override
  String get comingSoon => 'Скоро будет доступно';

  @override
  String get encrypted => 'Зашифровано';

  @override
  String get typing => 'Печатает…';

  @override
  String get online => 'Онлайн';

  @override
  String get chatWelcomeSubtitle =>
      'Я проанализирую ситуацию, проверю документы, найду ошибки и подскажу, что делать.';

  @override
  String get tapMicrophoneToSpeak => 'Нажмите на микрофон, чтобы говорить';

  @override
  String get categoryEssential => 'Основные';

  @override
  String get categoryPolice => 'Полиция';

  @override
  String get categoryWork => 'Работа';

  @override
  String get categoryHousing => 'Жильё';

  @override
  String get categoryConsumer => 'Потребитель';

  @override
  String rightsInsideCount(int count) {
    return '$count прав внутри';
  }

  @override
  String get freeAidThreshold => 'Порог бесплатной помощи';

  @override
  String get partialAidThreshold => 'Порог частичной помощи';

  @override
  String get assetLimit => 'Лимит активов';

  @override
  String get whereToApplyLabel => 'Куда обращаться';

  @override
  String get phoneLabel => 'Телефон';

  @override
  String get websiteLabel => 'Сайт';

  @override
  String get disclaimerCollapsed => 'Только справочная информация';

  @override
  String get disclaimerExpanded =>
      'ИИ-помощник — не юридическая консультация. Всегда проверяйте у квалифицированного юриста.';

  @override
  String get chatDisclaimerBanner =>
      'ИИ-помощник предоставляет правовую информацию, а не юридическую консультацию. Всегда консультируйтесь с квалифицированным юристом.';

  @override
  String get categoryChildren => 'Дети';

  @override
  String get categoryDigital => 'Онлайн';

  @override
  String get childrenRights => 'Права ребёнка и алименты';

  @override
  String get childrenRightsDesc =>
      'Алименты, защита детей, государственные гарантии';

  @override
  String get cyberbullying => 'Кибербуллинг и онлайн-преследование';

  @override
  String get cyberbullyingDesc =>
      'Угрозы, нарушение приватности, клевета в интернете';

  @override
  String get rightChildSupport =>
      'Оба родителя обязаны содержать ребёнка финансово (Perekonnaseadus § 100–102)';

  @override
  String get rightMinimumAlimony =>
      'Минимальные алименты в Эстонии: базовая сумма (295,86 €) + 3% от средней брутозарплаты за прошлый год (PKS § 101). С 01.04.2026 — 318,62 €/мес на ребёнка. Обновляется ежегодно 1 апреля. Калькулятор: alimendid.ee';

  @override
  String get rightCourtAlimony =>
      'Алименты можно взыскать через уездный суд (maakohus) — адвокат не нужен для исков до 6400 €';

  @override
  String get rightBailiffEnforcement =>
      'Если родитель отказывается платить, судебный исполнитель (kohtutäitur) принудит к исполнению, включая удержание из зарплаты';

  @override
  String get rightStateAlimonyGuarantee =>
      'Если родитель не платит, государство выплачивает elatisabi через Sotsiaalkindlustusamet — до 100 €/мес на ребёнка';

  @override
  String get rightChildEducation =>
      'Каждый ребёнок имеет право на образование, медицинскую помощь и защиту от насилия (Lastekaitseseadus § 4–5)';

  @override
  String get rightChildContact =>
      'Ребёнок имеет право общаться с обоими родителями, если суд не решил иначе (PKS § 143)';

  @override
  String get mustFileCourtClaim =>
      'Для получения алиментов необходимо подать иск в суд или договориться о сумме письменно';

  @override
  String get mustNotifyAddressChange =>
      'При получении elatisabi уведомите Sotsiaalkindlustusamet о смене адреса';

  @override
  String get childrenActionGatherDocs =>
      'Соберите свидетельство о рождении ребёнка, удостоверение личности и подтверждение расходов';

  @override
  String get childrenActionFileCourtClaim =>
      'Подайте иск об алиментах в уездный суд (maakohus) — можно онлайн через e-toimik';

  @override
  String get childrenActionApplyElatisabi =>
      'Подайте заявление на elatisabi в Sotsiaalkindlustusamet, если родитель не платит';

  @override
  String get childrenActionContactBailiff =>
      'Обратитесь к судебному исполнителю (kohtutäitur) для принудительного исполнения решения суда';

  @override
  String get childrenActionCallLasteabi =>
      'Позвоните на телефон помощи детям 116 111 — бесплатно, круглосуточно';

  @override
  String get childrenDeadlineElatisabi =>
      'Заявление на elatisabi — после решения суда, строгого срока нет, но процесс занимает время';

  @override
  String get childrenDeadlineCourt =>
      'Алименты можно взыскать за прошлый период — до 1 года до подачи иска';

  @override
  String get childrenFactMinimum =>
      'С 01.04.2026 минимальные алименты — 318,62 €/мес на ребёнка. Формула: базовая сумма (295,86 €) + 3% от средней брутозарплаты за прошлый год. Сумма обновляется ежегодно 1 апреля. Родитель не может договориться о меньшей сумме. Калькулятор: alimendid.ee';

  @override
  String get childrenFactElatisabi =>
      'Государственная гарантия алиментов (elatisabi) была введена в 2017 году для защиты детей, когда родитель отказывается платить. Государство платит и затем взыскивает сумму с должника.';

  @override
  String get rightReportCybercrime =>
      'Вы имеете право сообщить в полицию об угрозах, преследовании и краже личности в интернете (KarS § 120, § 157¹)';

  @override
  String get rightContentRemoval =>
      'Вы можете потребовать удаление клеветнического или личного контента с платформ по GDPR';

  @override
  String get rightMoralDamageCompensation =>
      'Вы можете требовать компенсацию морального вреда от кибербуллинга (VÕS § 1043–1055)';

  @override
  String get rightPrivacyProtection =>
      'Ваша частная жизнь защищена — несанкционированное распространение фото, сообщений или данных незаконно (KarS § 157)';

  @override
  String get rightDataProtection =>
      'Сообщайте о нарушениях защиты данных в Andmekaitse Inspektsioon';

  @override
  String get rightDefamationAction =>
      'Клевета — гражданское правонарушение: можно подать иск о возмещении ущерба и требовать опровержения (VÕS § 1047)';

  @override
  String get mustCollectEvidence =>
      'Соберите и сохраните все доказательства — скриншоты, ссылки, даты и данные свидетелей';

  @override
  String get mustNotRetaliate =>
      'Не отвечайте тем же и не преследуйте в ответ — это может ослабить вашу позицию';

  @override
  String get cyberActionScreenshots =>
      'Сделайте скриншоты всего преследования — сохраните URL, даты, имена пользователей и контент';

  @override
  String get cyberActionReportPolice =>
      'Подайте заявление в полицию в ближайшем отделении или онлайн на politsei.ee';

  @override
  String get cyberActionReportPlatform =>
      'Пожалуйтесь на контент в социальной сети для его удаления';

  @override
  String get cyberActionContactDPA =>
      'Обратитесь в Andmekaitse Inspektsioon, если ваши персональные данные были использованы незаконно';

  @override
  String get cyberActionConsultLawyer =>
      'Проконсультируйтесь с юристом о гражданском иске — бесплатная помощь доступна через Riigi Õigusabi';

  @override
  String get cyberDeadlineCriminal =>
      'Заявление о преступлении — строгого срока нет, но сообщите как можно скорее';

  @override
  String get cyberDeadlineCivil =>
      'Гражданский иск о возмещении ущерба — до 3 лет с момента, когда вы узнали о нарушении (TsÜS § 150)';

  @override
  String get cyberFactPrivacy =>
      'В Эстонии несанкционированное распространение интимных изображений может повлечь до 3 лет лишения свободы по KarS § 157¹.';

  @override
  String get cyberFactGDPR =>
      'Согласно GDPR у вас есть «право быть забытым» — платформы обязаны удалить ваши данные по запросу, если нет законного основания их хранить.';

  @override
  String get guestUser => 'Гость';

  @override
  String get howToUse => 'Как пользоваться?';

  @override
  String get tutorialStep1Title => 'ИИ-помощник по праву';

  @override
  String get tutorialStep1Desc =>
      'Задайте любой правовой вопрос и получите мгновенные ответы на основе законов Эстонии.';

  @override
  String get tutorialStep2Title => 'Знайте свои права';

  @override
  String get tutorialStep2Desc =>
      'Просматривайте правовую информацию по темам — работа, жильё, права потребителя и другое.';

  @override
  String get tutorialStep3Title => 'Сканирование документов';

  @override
  String get tutorialStep3Desc =>
      'Фотографируйте юридические документы для анализа ИИ и безопасного хранения.';

  @override
  String get tutorialStep4Title => 'Начнём!';

  @override
  String get tutorialStep4Desc =>
      'Исследуйте приложение и защищайте свои права. Все данные остаются на вашем устройстве.';

  @override
  String get advocatProTitle => 'Подписка Pro';

  @override
  String get advocatProSubtitle => 'Откройте все возможности';

  @override
  String get voiceDisclaimer =>
      'Голосовой помощник работает пока только на компьютере (браузер Chrome). Поддержка мобильных скоро.';

  @override
  String get recommended => 'Рекомендуем';

  @override
  String get pleaseLogIn => 'Пожалуйста, войдите в систему';

  @override
  String get subscriptionNotFound => 'Подписка не найдена';

  @override
  String errorWithMessage(String message) {
    return 'Ошибка: $message';
  }

  @override
  String get redirectingToPayment => 'Перенаправление на страницу оплаты…';

  @override
  String cheaperAnnually(String amount) {
    return '€$amount/мес. дешевле при годовой подписке';
  }

  @override
  String get navigatingTo => 'Открываю';

  @override
  String get stayInChat => 'Остаться в чате';

  @override
  String get backToChat => 'Назад в чат';

  @override
  String get upgradeBannerTitle => 'Откройте безлимитные консультации';

  @override
  String get upgradeBannerCta => 'Обновить';

  @override
  String get paymentSuccessTitle => 'Оплата прошла';

  @override
  String get paymentSuccessBody => 'Подписка активирована.';

  @override
  String get commonOk => 'ОК';

  @override
  String get feedbackThumbsUpLabel => 'Полезно';

  @override
  String get feedbackThumbsDownLabel => 'Не полезно';

  @override
  String get feedbackCommentPrompt => 'Что не так?';

  @override
  String get feedbackSend => 'Отправить';

  @override
  String get feedbackCancel => 'Отмена';

  @override
  String get reasoningPillIdle => 'Думаю…';

  @override
  String get reasoningPillSearchingLaw => 'Изучаю закон…';

  @override
  String get reasoningPillSearchingWeb => 'Ищу в интернете…';

  @override
  String get reasoningPillCheckingCompany => 'Проверяю реестр компаний…';

  @override
  String get reasoningPillCheckingVehicle => 'Проверяю реестр транспорта…';

  @override
  String get reasoningPillReadingDocument => 'Читаю Ваш документ…';

  @override
  String get reasoningPillDrafting => 'Готовлю документ…';

  @override
  String get reasoningPillPreparingEmail => 'Составляю письмо…';

  @override
  String get reasoningPillFindingLawyer => 'Подбираю адвокатов…';

  @override
  String get reasoningPillThinking => 'Анализирую Ваше дело…';

  @override
  String get reasoningPillFinalising => 'Формулирую ответ…';

  @override
  String reasoningCollapsedFormat(int sec, int sources) {
    return 'Размышлял $sec с · источников: $sources';
  }

  @override
  String get reasoningExpandHint => 'коснитесь, чтобы увидеть шаги';

  @override
  String get caseFileTitle => 'Досье';

  @override
  String get caseFileTimeline => 'Хронология';

  @override
  String get caseFileParties => 'Стороны';

  @override
  String get caseFileDeadlines => 'Сроки';

  @override
  String get caseFileExportPdf => 'Скачать досье (PDF)';

  @override
  String get caseFileEmpty =>
      'Поговорите с AI о вашем деле — хронология построится сама.';

  @override
  String get caseFileDisclaimer =>
      'Это досье автоматически извлечено из вашего чата. Это не юридическая консультация.';

  @override
  String get caseFileTabLabel => 'Дело';

  @override
  String get refresh => 'Обновить';

  @override
  String get demoLimitReached =>
      'Демо-лимит исчерпан. Зарегистрируйтесь бесплатно, чтобы продолжить.';

  @override
  String get demoLimitSignUpCta => 'Регистрация';

  @override
  String get freeQuotaExhausted =>
      'Вы использовали все 7 бесплатных сообщений в этом месяце.';

  @override
  String get upgradeForUnlimited => 'Оформите Pro для безлимитного доступа';

  @override
  String get upgradeCta => 'Оформить';

  @override
  String get rateLimitTryAgain =>
      'Слишком частые запросы. Попробуйте через пару секунд.';

  @override
  String get quickProfilePrompt =>
      'Чтобы я мог помочь точнее: вы гражданин Эстонии, гражданин ЕС из другой страны, или у вас вид на жительство (ВНЖ)?';

  @override
  String get quickProfileChipEstonianCitizen => 'Гражданин Эстонии';

  @override
  String get quickProfileChipEuCitizen => 'Гражданин ЕС (другая страна)';

  @override
  String get quickProfileChipResidencePermit => 'ВНЖ / временный';

  @override
  String get quickProfileSkipBtn => 'Пропустить';

  @override
  String get quickProfileSavedAck => 'Понял. Теперь — какой у вас вопрос?';

  @override
  String get caseTitleLabel => 'Название дела';

  @override
  String get jurisdictionLabel => 'Юрисдикция';

  @override
  String get caseTypeLabel => 'Тип дела';

  @override
  String get caseLanguageLabel => 'Язык';

  @override
  String get caseNumbersSection => 'Номера дел';

  @override
  String get partiesSection => 'Стороны';

  @override
  String get authoritiesSection => 'Органы';

  @override
  String get timelineSection => 'Хронология';

  @override
  String get openQuestionsSection => 'Открытые вопросы';

  @override
  String get nextActionsSection => 'Следующие шаги';

  @override
  String get summarySection => 'Краткое описание';

  @override
  String get addRow => 'Добавить';

  @override
  String get removeRow => 'Удалить';

  @override
  String get archiveCase => 'Архивировать';

  @override
  String get closeCase => 'Закрыть дело';

  @override
  String get continueChatAboutCase => 'Продолжить чат по этому делу';

  @override
  String get linkChatToCase => 'Связать с делом';

  @override
  String get clearActiveCase => 'Сбросить активное дело';

  @override
  String get caseSavedAck => 'Дело сохранено';

  @override
  String get caseArchivedAck => 'Дело архивировано';

  @override
  String get intakeStep1Title => 'Где дело?';

  @override
  String get intakeStep1Subtitle => 'Страна и орган, с которым вы имеете дело.';

  @override
  String get intakeJurisdictionLabel => 'Страна / юрисдикция';

  @override
  String get intakeAuthorityLabel => 'Тип органа';

  @override
  String get intakeAuthorityNameLabel => 'Название органа (необязательно)';

  @override
  String get intakeAuthorityPolice => 'Полиция';

  @override
  String get intakeAuthorityCourt => 'Суд';

  @override
  String get intakeAuthoritySocial => 'Социальная служба';

  @override
  String get intakeAuthorityEmployer => 'Работодатель';

  @override
  String get intakeAuthorityLandlord => 'Арендодатель';

  @override
  String get intakeAuthorityOpposingParty => 'Другая сторона';

  @override
  String get intakeAuthorityOther => 'Другое';

  @override
  String get intakeStep2Title => 'Какое это дело?';

  @override
  String get intakeStep2Subtitle => 'Выберите ближайший тип — уточним позже.';

  @override
  String get intakeCaseTypeCriminal => 'Уголовное';

  @override
  String get intakeCaseTypeCivil => 'Гражданское';

  @override
  String get intakeCaseTypeFamily => 'Семейное';

  @override
  String get intakeCaseTypeAdmin => 'Административное';

  @override
  String get intakeCaseTypeImmigration => 'Миграция';

  @override
  String get intakeCaseTypeLabor => 'Трудовое';

  @override
  String get intakeCaseTypeConsumer => 'Потребительское';

  @override
  String get intakeCaseTypeInheritance => 'Наследство';

  @override
  String get intakeCaseTypeOther => 'Другое';

  @override
  String get intakeStep3Title => 'Кто участвует?';

  @override
  String get intakeStep3Subtitle => 'Ваша роль и другая сторона.';

  @override
  String get intakeRoleLabel => 'Ваша роль';

  @override
  String get intakeRolePlaintiff => 'Истец';

  @override
  String get intakeRoleDefendant => 'Ответчик';

  @override
  String get intakeRoleVictim => 'Потерпевший';

  @override
  String get intakeRoleAccused => 'Обвиняемый';

  @override
  String get intakeRoleWitness => 'Свидетель';

  @override
  String get intakeRoleFamily => 'Член семьи';

  @override
  String get intakeRoleOther => 'Другое';

  @override
  String get intakeOpposingSideLabel => 'Другая сторона (необязательно)';

  @override
  String get intakeWitnessesLabel => 'Свидетели (необязательно)';

  @override
  String get intakeAddWitness => 'Добавить свидетеля';

  @override
  String get intakeWitnessHint => 'Имя или контакт';

  @override
  String get intakeStep4Title => 'Номера и даты';

  @override
  String get intakeStep4Subtitle =>
      'Что уже знаете. Что не знаете — пропустите.';

  @override
  String get intakeCaseNumberLabel => 'Номер дела (необязательно)';

  @override
  String get intakeIncidentDateLabel => 'Дата происшествия (необязательно)';

  @override
  String get intakeIncidentDatePick => 'Выбрать дату';

  @override
  String get intakeDeadlinesLabel => 'Известные сроки';

  @override
  String get intakeAddDeadline => 'Добавить срок';

  @override
  String get intakeDeadlineWhatHint => 'Что';

  @override
  String get intakeStep5Title => 'Документы';

  @override
  String get intakeStep5Subtitle => 'Загрузите всё, что есть. Мы прочитаем.';

  @override
  String get intakeUploadDocsLabel => 'Загрузить документы';

  @override
  String get intakeSkipDocs => 'Пропустить — загружу позже';

  @override
  String get intakeNextBtn => 'Далее';

  @override
  String get intakeBackBtn => 'Назад';

  @override
  String get intakeFinishBtn => 'Завершить и открыть чат';

  @override
  String get intakeUrgentBtn => 'Горит — спросить сразу';

  @override
  String get intakeUrgentDialogTitle => 'Открыть чат сейчас?';

  @override
  String get intakeUrgentDialogBody =>
      'Сохраним введённое как черновик дела. Можно дозаполнить из карточки дела в любой момент.';

  @override
  String get intakeUrgentConfirm => 'Открыть чат';

  @override
  String get intakeUrgentCancel => 'Продолжить заполнение';

  @override
  String get intakePreparingCase => 'Готовлю ваше дело…';

  @override
  String get intakeFallbackGreeting =>
      'Я вижу ваше дело. Скажите, что сейчас острее всего — разберёмся вместе.';

  @override
  String get intakeUrgentGreeting =>
      'Я вижу, что вам нужно срочно. Спросите вопрос — по ходу разговора заполню досье.';

  @override
  String intakeStepIndicator(int current, int total) {
    return 'Шаг $current из $total';
  }

  @override
  String get intakeFieldRequired => 'Обязательно';

  @override
  String intakeUploadProgress(int done, int total) {
    return 'Загружаю $done / $total…';
  }

  @override
  String get uplDisclaimerFooter =>
      'Advocat не является юридической фирмой. Это информация, а не юридическая консультация.';

  @override
  String get citationStatusVerifiedBadge => 'Проверено';

  @override
  String get citationStatusUnverifiedBadge => 'Не проверено';

  @override
  String get citationStatusHistoricalBadge => 'Старая редакция';

  @override
  String get citationStatusVerifiedTooltip =>
      'Цитата подтверждена найденным источником закона.';

  @override
  String get citationStatusUnverifiedTooltip =>
      'ИИ привёл ссылку без поиска — проверьте перед использованием.';

  @override
  String get citationStatusHistoricalTooltip =>
      'Указанная статья больше не действует.';

  @override
  String get citationOpenInRiigiTeataja => 'Открыть в Riigi Teataja';

  @override
  String get citationSnippetExpand => 'Показать полностью';

  @override
  String get citationSnippetCollapse => 'Свернуть';

  @override
  String get citationUnverifiedSheetNote =>
      'ИИ сослался на этот параграф, но он не был найден в корпусе закона на этом ходу. Проверьте ссылку перед использованием.';

  @override
  String get citationFooterNoneWarning => 'Нет подтверждённых ссылок';

  @override
  String citationFooterSummaryTotal(int count) {
    return '$count ссылок';
  }

  @override
  String citationFooterSummaryVerified(int count) {
    return '$count проверено';
  }

  @override
  String citationFooterSummaryUnverified(int count) {
    return '$count непроверенных';
  }

  @override
  String citationFooterSummaryHistorical(int count) {
    return '$count устаревших';
  }

  @override
  String get deadlineRadarTitle => 'Ближайшие сроки';

  @override
  String get deadlineRadarEmpty => 'Нет ближайших сроков';

  @override
  String get deadlineRadarViewAll => 'Все сроки';

  @override
  String deadlineCardDaysLeft(int count) {
    return 'через $count дн.';
  }

  @override
  String get deadlineCardTomorrow => 'завтра';

  @override
  String get deadlineCardToday => 'сегодня';

  @override
  String deadlineCardOverdue(int count) {
    return 'просрочено на $count дн.';
  }

  @override
  String get deadlineCardMarkComplete => 'Отметить выполненным';

  @override
  String get deadlineCardSnooze => 'Отложить';

  @override
  String get deadlineCardSnooze3d => 'Отложить на 3 дня';

  @override
  String get deadlineCardSnooze7d => 'Отложить на 7 дней';

  @override
  String get deadlineCardSnoozeCustom => 'Выбрать дату';

  @override
  String get deadlineCardEdit => 'Изменить';

  @override
  String get deadlineCardDelete => 'В архив';

  @override
  String get deadlineCardSourceLabelPdf => 'из PDF';

  @override
  String get deadlineCardSourceLabelIntake => 'из анкеты';

  @override
  String get deadlineCardSourceLabelManual => 'вручную';

  @override
  String get deadlineCardSourceLabelEmail => 'из e-mail';

  @override
  String get deadlineCardSourceLabelHaikuExtract => 'найдено AI';

  @override
  String get deadlineCardSourceLabelStatutoryTemplate => 'шаблон закона';

  @override
  String deadlineBannerCritical(String title, String when) {
    return 'Критический срок: $title $when';
  }

  @override
  String get deadlineBannerDismiss => 'Скрыть';

  @override
  String get deadlineBannerOpen => 'Открыть срок';

  @override
  String deadlineHolidayShifted(String original, String reason) {
    return 'Перенесено с $original ($reason)';
  }

  @override
  String get deadlinePermissionAskTitle => 'Включить напоминания о сроках?';

  @override
  String get deadlinePermissionAskBody =>
      'Напомним за 7, 3 и 1 день до каждого процессуального срока и утром в день срока. Никогда не используется для маркетинга.';

  @override
  String get deadlinePermissionAllow => 'Разрешить';

  @override
  String get deadlinePermissionLater => 'Позже';

  @override
  String get deadlineSettingsSection => 'Напоминания о сроках';

  @override
  String get deadlineSettingsPushChannel => 'Push-уведомления';

  @override
  String get deadlineSettingsEmailChannel => 'E-mail (только критические)';

  @override
  String get deadlineSettingsInAppChannel => 'Уведомления в приложении';

  @override
  String get deadlineSettingsCriticalBypass => 'Критические минуют тихие часы';

  @override
  String get deadlineSettingsQuietHours => 'Тихие часы';

  @override
  String deadlineSettingsQuietHoursBadge(String start, String end) {
    return 'Тихо $start–$end';
  }

  @override
  String get deadlineCaseScreenTitle => 'Сроки по делу';

  @override
  String get deadlineAddManualCta => 'Добавить срок';

  @override
  String get deadlineFormTitle => 'Название';

  @override
  String get deadlineFormDescription => 'Описание (необязательно)';

  @override
  String get deadlineFormStatuteTemplate => 'Шаблон статьи';

  @override
  String get deadlineFormStatuteTemplateNone => 'Нет (вручную)';

  @override
  String get deadlineFormDeadlineAt => 'Дата срока';

  @override
  String get deadlineFormPriority => 'Приоритет';

  @override
  String get deadlineFormSave => 'Сохранить';

  @override
  String get deadlineFormCancel => 'Отмена';

  @override
  String get deadlineCompletedNotePrompt => 'Заметка (необязательно)';

  @override
  String get deadlineCompletedNoteSave => 'Сохранить';

  @override
  String get inboxTitle => 'Входящие';

  @override
  String get inboxEmptyTitle => 'Ничего не ждёт';

  @override
  String get inboxEmptyBody => 'Новые письма появятся здесь после анализа.';

  @override
  String get inboxApproveSend => 'Подтвердить и отправить';

  @override
  String get inboxEditDraft => 'Изменить';

  @override
  String get inboxSnooze => 'Отложить';

  @override
  String get inboxArchive => 'В архив';

  @override
  String get inboxFilterAll => 'Все';

  @override
  String get inboxConfirmSendTitle => 'Отправить подготовленный ответ?';

  @override
  String get inboxConfirmSendBody =>
      'Advocat отправит подготовленный AI ответ через подключённый Gmail. Вы ещё сможете просмотреть текст на следующем экране.';

  @override
  String get inboxSendButton => 'Отправить';

  @override
  String get inboxSentToast => 'Отправлено.';

  @override
  String get inboxSnoozedToast => 'Отложено на 24 часа.';

  @override
  String get inboxArchivedToast => 'В архиве.';

  @override
  String get inboxDraftLoadError => 'Не удалось загрузить черновик.';

  @override
  String get inboxDeadlineToday => 'сегодня';

  @override
  String get inboxDeadlineTomorrow => 'завтра';

  @override
  String inboxDeadlineInDays(int days) {
    return 'через $days дн.';
  }

  @override
  String inboxDeadlineOverdue(int days) {
    return 'просрочено на $days дн.';
  }
}
