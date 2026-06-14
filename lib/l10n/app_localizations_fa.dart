// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get about => 'درباره';

  @override
  String get aboutSection => 'درباره';

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
  String get accidents => 'تصادفات';

  @override
  String get active => 'فعال';

  @override
  String get activeCases => 'پرونده‌های فعال';

  @override
  String get addedToAppeal => 'به تجدیدنظر اضافه شد';

  @override
  String get agreeToTerms => 'موافقم با ';

  @override
  String get aiAnalysis => 'تحلیل هوش مصنوعی';

  @override
  String get aiAssistant => 'دستیار حقوقی هوش مصنوعی';

  @override
  String get aiChat => 'گفتگوی هوش مصنوعی';

  @override
  String get all => 'همه';

  @override
  String get alreadyHaveAccount => 'قبلاً حساب دارید؟ ';

  @override
  String get analyzing => 'در حال تحلیل…';

  @override
  String get aiAnalyzing => 'هوش مصنوعی در حال تحلیل است';

  @override
  String get speakIntoMicHint =>
      'در میکروفون صحبت کنید. مطمئن شوید دسترسی به میکروفون فعال است.';

  @override
  String get aiErrorRateLimit =>
      'سرویس موقتاً بیش از حد بارگذاری شده است. لطفاً ۱ تا ۲ دقیقه دیگر دوباره تلاش کنید.';

  @override
  String get aiErrorOverload =>
      'هوش مصنوعی هم‌اکنون مشغول است، لطفاً یک دقیقه دیگر دوباره تلاش کنید.';

  @override
  String freeLimitReached(int count) {
    return 'شما از تمام $count پیام رایگان هوش مصنوعی استفاده کرده‌اید. برای دستیار حقوقی نامحدود به Legal Counsel ارتقا دهید!';
  }

  @override
  String get andWord => ' و ';

  @override
  String get appTitle => 'Advocat — ابزار اطلاعات حقوقی';

  @override
  String get appVersion => 'نسخه برنامه';

  @override
  String get appealFiled => 'تجدیدنظر ثبت شد';

  @override
  String get areYouAbsolutelySure => 'آیا کاملاً مطمئن هستید؟';

  @override
  String get askAboutCase => 'تحلیل پرونده من';

  @override
  String get asylum => 'پناهندگی';

  @override
  String get back => 'قبلی';

  @override
  String get basic => 'پایه';

  @override
  String get beforeYouBuy => 'قبل از خرید';

  @override
  String get beforeYouWork => 'قبل از همکاری با آن‌ها';

  @override
  String get camera => 'دوربین';

  @override
  String get cancel => 'لغو';

  @override
  String get caseDescription => 'وضعیت خود را توضیح دهید';

  @override
  String get caseDetail => 'جزئیات پرونده';

  @override
  String get caseOverview => 'خلاصه پرونده‌های شما';

  @override
  String get caseTitle => 'عنوان پرونده';

  @override
  String get caseUpdated => 'پرونده به‌روز شد';

  @override
  String get cases => 'پرونده‌ها';

  @override
  String get checkCompany => 'بررسی شرکت';

  @override
  String get checkDeadlines => 'بررسی مهلت‌ها';

  @override
  String get checkVehicle => 'بررسی خودرو';

  @override
  String get checkerTitle => 'بررسی‌کننده';

  @override
  String get checkingErrors => 'بررسی خطاها…';

  @override
  String get choosePlan => 'انتخاب طرح';

  @override
  String get closed => 'بسته شده';

  @override
  String get companyName => 'نام شرکت یا شماره ثبت';

  @override
  String get completed => 'تکمیل شده';

  @override
  String get confirm => 'تأیید';

  @override
  String get confirmPassword => 'تأیید رمز عبور';

  @override
  String get connectEmail => 'اتصال ایمیل';

  @override
  String get connectGmail => 'اتصال Gmail';

  @override
  String get connectOutlook => 'اتصال Outlook';

  @override
  String get connected => 'متصل';

  @override
  String get contactSupport => 'تماس با پشتیبانی';

  @override
  String get continueWithGoogle => 'ادامه با Google';

  @override
  String get appleComingSoon => 'به‌زودی';

  @override
  String get appleComingSoonMessage =>
      'ورود با Apple به‌زودی در دسترس خواهد بود. برای ادامه از Google یا ایمیل استفاده کنید.';

  @override
  String get copyText => 'کپی متن';

  @override
  String get correspondence => 'مکاتبات';

  @override
  String get couldNotLoadCases => 'بارگذاری پرونده‌ها ممکن نشد';

  @override
  String get country => 'کشور';

  @override
  String get createAccount => 'ایجاد حساب';

  @override
  String get createCase => 'ایجاد پرونده';

  @override
  String get criminalCase => 'پرونده کیفری';

  @override
  String get critical => 'بحرانی';

  @override
  String get currentPlan => 'طرح فعلی';

  @override
  String get dataAndPrivacy => 'داده‌ها و حریم خصوصی';

  @override
  String get dataExportRequested =>
      'خروجی داده‌ها درخواست شد. ایمیل خود را بررسی کنید.';

  @override
  String daysRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count روز',
      one: '۱ روز',
      zero: 'روزی باقی نمانده',
    );
    return '$_temp0';
  }

  @override
  String get deadlineReminders => 'یادآوری مهلت‌ها';

  @override
  String get deadlineRemindersDesc => 'قبل از مهلت‌ها اعلان دریافت کنید';

  @override
  String get deadlines => 'مهلت‌ها';

  @override
  String get debtCollection => 'وصول مطالبات';

  @override
  String get deleteAccount => 'حذف حساب';

  @override
  String get deleteAccountDesc => 'حذف دائمی حساب شما';

  @override
  String get deleteAccountDialogContent =>
      'این عمل دائمی و غیرقابل بازگشت است. تمام داده‌ها، پرونده‌ها و اسناد شما برای همیشه حذف خواهد شد.';

  @override
  String get deleteConfirm =>
      'آیا مطمئن هستید؟ تمام داده‌های شما برای همیشه حذف خواهد شد.';

  @override
  String get demoHint => 'نسخه نمایشی: پلاک «908FBT» را امتحان کنید';

  @override
  String get demoModeDesc =>
      'برنامه را با داده‌های نمونه از یک پرونده واقعی کاوش کنید';

  @override
  String get deportation => 'اخراج';

  @override
  String get disclaimer =>
      'فقط راهنمایی هوش مصنوعی — مشاوره حقوقی نیست. همیشه با وکیل مشورت کنید.';

  @override
  String get disclaimerFull =>
      'این یک دستیار هوش مصنوعی است، نه وکیل. تحلیل هوش مصنوعی ممکن است حاوی خطا باشد. همیشه با یک متخصص حقوقی واجد شرایط بررسی کنید.';

  @override
  String get disconnect => 'قطع اتصال';

  @override
  String get discrimination => 'تبعیض';

  @override
  String get doNotBuy => 'نخرید';

  @override
  String get documents => 'اسناد';

  @override
  String documentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count سند',
      one: '۱ سند',
      zero: 'بدون سند',
    );
    return '$_temp0';
  }

  @override
  String get draftAppeal => 'پیش‌نویس تجدیدنظر';

  @override
  String get editDraft => 'ویرایش';

  @override
  String get editProfile => 'ویرایش پروفایل';

  @override
  String get email => 'ایمیل';

  @override
  String get emailConnected => 'ایمیل متصل شد';

  @override
  String get emailDisconnected => 'ایمیل قطع شد';

  @override
  String get emailIntegration => 'یکپارچه‌سازی ایمیل';

  @override
  String get emailInvalid => 'لطفاً یک آدرس ایمیل معتبر وارد کنید';

  @override
  String get emailPrivacyNote =>
      'ما فقط ایمیل‌های مربوط به مسائل حقوقی را می‌خوانیم. ایمیل‌های شخصی شما خصوصی می‌مانند.';

  @override
  String get emailRequired => 'ایمیل الزامی است';

  @override
  String get emergencyShield => 'سپر اضطراری';

  @override
  String get error => 'خطا';

  @override
  String get exportDataDesc => 'دانلود تمام داده‌های پرونده';

  @override
  String get exportDataDialogContent =>
      'ما یک فایل دانلود از تمام داده‌های شما شامل پرونده‌ها، اسناد و مکاتبات آماده می‌کنیم. وقتی آماده شد ایمیلی دریافت خواهید کرد.';

  @override
  String get exportMyData => 'خروجی داده‌های من';

  @override
  String get exportPdf => 'خروجی PDF';

  @override
  String get familyReunification => 'پیوستن خانواده';

  @override
  String get forgotPassword => 'رمز عبور را فراموش کرده‌اید؟';

  @override
  String get free => 'رایگان';

  @override
  String get fullDefense => 'Advocat Pro';

  @override
  String get fullName => 'نام کامل';

  @override
  String get gallery => 'گالری';

  @override
  String get generateAppeal => 'تولید تجدیدنظر';

  @override
  String get getStarted => 'شروع';

  @override
  String goodAfternoon(String name) {
    return 'عصر بخیر، $name';
  }

  @override
  String goodEvening(String name) {
    return 'شب بخیر، $name';
  }

  @override
  String goodMorning(String name) {
    return 'صبح بخیر، $name';
  }

  @override
  String goodNight(String name) {
    return 'شب بخیر، $name';
  }

  @override
  String get home => 'خانه';

  @override
  String get important => 'مهم';

  @override
  String get inProgress => 'در حال انجام';

  @override
  String get informational => 'اطلاع‌رسانی';

  @override
  String get inspection => 'بازرسی فنی';

  @override
  String get insurance => 'بیمه';

  @override
  String issuesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مشکل یافت شد',
      one: '۱ مشکل یافت شد',
      zero: 'مشکلی یافت نشد',
    );
    return '$_temp0';
  }

  @override
  String get laborDispute => 'اختلاف کارگری';

  @override
  String get langEnglish => 'انگلیسی';

  @override
  String get langFinnish => 'فنلاندی';

  @override
  String get langRussian => 'روسی';

  @override
  String get language => 'زبان';

  @override
  String lastActivity(String time) {
    return 'آخرین فعالیت: $time';
  }

  @override
  String get legalFighter => 'مبارز حقوقی';

  @override
  String get legalSection => 'حقوقی';

  @override
  String get licensePlate => 'پلاک';

  @override
  String get loading => 'در حال بارگذاری…';

  @override
  String get logIn => 'ورود';

  @override
  String get loginFailed =>
      'ایمیل یا رمز عبور نامعتبر است. لطفاً دوباره تلاش کنید.';

  @override
  String get lost => 'بازنده';

  @override
  String get markComplete => 'علامت‌گذاری به عنوان تکمیل شده';

  @override
  String get mileage => 'کیلومتر';

  @override
  String get myCases => 'پرونده‌های من';

  @override
  String get nameRequired => 'نام کامل الزامی است';

  @override
  String get newCase => 'پرونده جدید';

  @override
  String get next => 'بعدی';

  @override
  String get noAccount => 'حساب ندارید؟ ';

  @override
  String get noCases => 'هنوز پرونده‌ای نیست';

  @override
  String get noCasesYet => 'هنوز پرونده‌ای نیست';

  @override
  String get noDeadlines => 'مهلتی نیست — همه چیز مرتب است!';

  @override
  String get noRecentActivity => 'فعالیت اخیری نیست';

  @override
  String get notifications => 'اعلان‌ها';

  @override
  String get onboardingDesc1 =>
      'Advocat به شما کمک می‌کند وضعیت حقوقی خود را درک کنید. ابزارهای هوش مصنوعی اسناد را تحلیل می‌کنند، مشکلات احتمالی را شناسایی می‌کنند و پیش‌نویس اسناد را برای بررسی شما آماده می‌کنند. این یک دفتر وکالت نیست — یک ابزار فناوری برای پشتیبانی از پرونده شماست.';

  @override
  String get onboardingDesc2 =>
      'از هر سند حقوقی عکس بگیرید. هوش مصنوعی آن را به چندین زبان می‌خواند، داده‌های کلیدی را استخراج می‌کند و انطباق با دستورالعمل‌های اتحادیه اروپا و قوانین ملی را بررسی می‌کند.';

  @override
  String get onboardingDesc3 =>
      'ابزارهای هوش مصنوعی ما بیش از ۴۰ نوع الزامات آیین دادرسی را بررسی می‌کنند. تحلیل هوش مصنوعی ممکن است مشکلاتی را شناسایی کند که نیاز به توجه دارند — مانند زبان ابلاغ، مراحل دادرسی و مهلت‌های قانونی. همیشه با یک وکیل واجد شرایط بررسی کنید.';

  @override
  String get onboardingDesc4 =>
      'هوش مصنوعی پیش‌نویس تجدیدنظر، شکایات و نامه‌ها را با ارجاعات حقوقی برای بررسی شما آماده می‌کند. شما تصمیم می‌گیرید چه چیزی ارسال شود. هر سند باید توسط یک متخصص حقوقی واجد شرایط پیش از تقدیم بررسی شود.';

  @override
  String get onboardingNext => 'بعدی';

  @override
  String get onboardingSkip => 'رد شدن';

  @override
  String get onboardingTitle1 => 'اطلاعات حقوقی مبتنی بر هوش مصنوعی';

  @override
  String get onboardingTitle2 => 'اسکن و تحلیل اسناد';

  @override
  String get onboardingTitle3 => 'هوش مصنوعی مشکلات احتمالی را بررسی می‌کند';

  @override
  String get onboardingTitle4 => 'پیش‌نویس اسناد برای بررسی شما';

  @override
  String get openACase => 'باز کردن پرونده';

  @override
  String get optional => '(اختیاری)';

  @override
  String get orDivider => 'یا';

  @override
  String get other => 'سایر';

  @override
  String get overdue => 'عقب افتاده';

  @override
  String get owners => 'مالکان قبلی';

  @override
  String get password => 'رمز عبور';

  @override
  String get passwordRequired => 'رمز عبور الزامی است';

  @override
  String get passwordStrengthMedium => 'متوسط';

  @override
  String get passwordStrengthStrong => 'قوی';

  @override
  String get passwordStrengthWeak => 'ضعیف';

  @override
  String get passwordTooShort => 'رمز عبور باید حداقل ۸ کاراکتر باشد';

  @override
  String get passwordsDoNotMatch => 'رمزهای عبور مطابقت ندارند';

  @override
  String get pendingDecision => 'در انتظار تصمیم';

  @override
  String get perCheck => 'به ازای هر بررسی';

  @override
  String get permanentlyDelete => 'حذف دائمی';

  @override
  String get policeMisconduct => 'سوءرفتار پلیس';

  @override
  String get popular => 'محبوب';

  @override
  String get preferences => 'ترجیحات';

  @override
  String get preferredLanguage => 'زبان ترجیحی';

  @override
  String get pricePerCheck => '€۴٫۹۹ به ازای هر بررسی';

  @override
  String get privacyPolicy => 'سیاست حفظ حریم خصوصی';

  @override
  String get dpaTitle => 'قرارداد پردازش داده‌ها';

  @override
  String get dpaCheckoutGateTitle => 'پیش از ارتقا';

  @override
  String get dpaCheckoutGateBody =>
      'قانون اتحادیه اروپا (ماده ۲۸ GDPR) ما را ملزم می‌کند که با هر مشتری پرداخت‌کننده یک قرارداد پردازش داده‌ها امضا کنیم. لطفاً آن را بررسی و بپذیرید.';

  @override
  String get dpaViewLink => 'مشاهده قرارداد پردازش داده‌ها';

  @override
  String get dpaCheckboxLabel =>
      'قرارداد پردازش داده‌ها (نسخه ۱.۰) را خوانده‌ام و می‌پذیرم.';

  @override
  String get dpaCancel => 'لغو';

  @override
  String get dpaAcceptAndContinue => 'پذیرفتن و ادامه';

  @override
  String get dpaOpenHint =>
      'برای فعال شدن دکمه پذیرش، حداقل یک بار DPA را باز کنید.';

  @override
  String get pro => 'حرفه‌ای';

  @override
  String get pushNotifications => 'اعلان‌های فشاری';

  @override
  String get rateUs => 'به ما امتیاز دهید';

  @override
  String get rateAppComingSoon => 'به‌زودی در فروشگاه‌های برنامه!';

  @override
  String get dataCopiedToClipboard => 'داده‌ها در کلیپ‌بورد کپی شد';

  @override
  String get readingDocument => 'در حال خواندن سند…';

  @override
  String get recentActivity => 'فعالیت اخیر';

  @override
  String get referenceNumber => 'شماره مرجع';

  @override
  String get registerFailed => 'ثبت‌نام ناموفق بود. لطفاً دوباره تلاش کنید.';

  @override
  String get reportFraud => 'گزارش کلاهبرداری';

  @override
  String get requestExport => 'درخواست خروجی';

  @override
  String get researchingLaw => 'تحقیق قانون قابل اعمال…';

  @override
  String get resetPasswordFailed =>
      'ارسال لینک ناموفق بود. لطفاً دوباره تلاش کنید.';

  @override
  String get resetPasswordSent =>
      'لینک بازنشانی رمز عبور به ایمیل شما ارسال شد.';

  @override
  String get residencePermit => 'اجازه اقامت';

  @override
  String get manageSubscription => 'مدیریت اشتراک';

  @override
  String get restorePurchases => 'بازیابی خریدها';

  @override
  String get retry => 'تلاش مجدد';

  @override
  String get reviewWarning =>
      'قبل از ارسال با دقت بررسی کنید. شما مسئول محتوا هستید.';

  @override
  String get riskHigh => 'ریسک بالا — اجتناب کنید';

  @override
  String get riskLow => 'امن برای همکاری';

  @override
  String get riskMedium => 'با احتیاط پیش بروید';

  @override
  String get safeToBuy => 'امن برای خرید';

  @override
  String get saveAndAnalyze => 'ذخیره و تحلیل';

  @override
  String get saveDraft => 'ذخیره';

  @override
  String get saveWithAnnual => '۲۵٪ با پرداخت سالانه صرفه‌جویی کنید';

  @override
  String get scan => 'اسکن';

  @override
  String get scanDocument => 'اسکن سند';

  @override
  String get searchCases => 'جستجوی پرونده‌ها…';

  @override
  String get selectCountry => 'انتخاب کشور';

  @override
  String get selectLanguage => 'انتخاب زبان';

  @override
  String get sendViaEmail => 'ارسال از طریق ایمیل';

  @override
  String get settings => 'تنظیمات';

  @override
  String get signIn => 'ورود';

  @override
  String get signInLink => 'ورود';

  @override
  String get signInSubtitle => 'برای دسترسی به پرونده‌های خود وارد شوید';

  @override
  String get signOut => 'خروج';

  @override
  String get signOutConfirm => 'آیا مطمئن هستید که می‌خواهید خارج شوید؟';

  @override
  String get signUp => 'ایجاد حساب';

  @override
  String get signUpLink => 'ثبت‌نام';

  @override
  String get socialBenefits => 'مزایای اجتماعی';

  @override
  String get someConcerns => 'برخی نگرانی‌ها';

  @override
  String get startFirstCase => 'اولین پرونده خود را شروع کنید';

  @override
  String step(int current, int total) {
    return 'مرحله $current از $total';
  }

  @override
  String get stolen => 'بررسی سرقت';

  @override
  String get subscription => 'اشتراک';

  @override
  String get syncLegalCorrespondence => 'همگام‌سازی مکاتبات حقوقی';

  @override
  String get syncNow => 'همگام‌سازی اکنون';

  @override
  String get tenantRights => 'حقوق مستأجر';

  @override
  String get termsOfService => 'شرایط خدمات';

  @override
  String get termsRequired => 'باید شرایط خدمات را بپذیرید';

  @override
  String get timeline => 'جدول زمانی';

  @override
  String get tryDemoMode => 'حالت آزمایشی را امتحان کنید';

  @override
  String get typeDeleteToConfirm =>
      'برای تأیید حذف دائمی حساب، DELETE را تایپ کنید.';

  @override
  String get typeMessage => 'پیام بنویسید…';

  @override
  String get upcoming => 'آینده';

  @override
  String get uploadDocument => 'بارگذاری سند';

  @override
  String urgentDeadline(String title) {
    return 'فوری: $title';
  }

  @override
  String get useInAppeal => 'استفاده در تجدیدنظر';

  @override
  String get vehicleChecker => 'بررسی‌کننده خودرو';

  @override
  String get vehicleChecks => 'بررسی‌های وضعیت';

  @override
  String get vehicleColor => 'رنگ';

  @override
  String get vehicleMake => 'سازنده';

  @override
  String get vehicleModel => 'مدل';

  @override
  String get vehicleYear => 'سال';

  @override
  String get version => 'نسخه';

  @override
  String get victimSupport => 'حمایت از قربانیان';

  @override
  String get viewAll => 'مشاهده همه';

  @override
  String get vinNumber => 'شماره شناسایی خودرو (VIN)';

  @override
  String get welcomeBack => 'خوش آمدید';

  @override
  String get whatAreMyOptions => 'گزینه‌های من چیست؟';

  @override
  String get won => 'برنده';

  @override
  String get documentVault => 'صندوق اسناد';

  @override
  String get secureDocumentStorage => 'ذخیره‌سازی امن اسناد';

  @override
  String get secureDocumentStorageDesc =>
      'اسناد حقوقی مهم خود را به صورت امن ذخیره کنید. تمام فایل‌ها به صورت سرتاسری رمزنگاری شده‌اند.';

  @override
  String get addDocument => 'افزودن سند';

  @override
  String get chooseHowToAdd => 'نحوه افزودن سند خود را انتخاب کنید';

  @override
  String get uploadFile => 'بارگذاری فایل';

  @override
  String get uploadFileDesc => 'یک فایل PDF یا تصویر از دستگاه خود انتخاب کنید';

  @override
  String get scanDocumentDesc => 'از سند خود عکس بگیرید';

  @override
  String get createNote => 'ایجاد یادداشت';

  @override
  String get createNoteDesc => 'یادداشتی بنویسید یا جزئیات مهم را ثبت کنید';

  @override
  String get knowYourRights => 'حقوق خود را بشناسید';

  @override
  String get stoppedByPolice => 'توقف توسط پلیس';

  @override
  String get stoppedByPoliceDesc => 'حقوق شما در هنگام مواجهه با پلیس';

  @override
  String get deportationNotice => 'اخطار اخراج';

  @override
  String get deportationNoticeDesc => 'مراحل اعتراض به حکم اخراج';

  @override
  String get workplaceRights => 'حقوق محل کار';

  @override
  String get workplaceRightsDesc => 'حمایت‌های قانون کار در فنلاند';

  @override
  String get tenantRightsDesc => 'حمایت‌های مسکن و اجاره';

  @override
  String get immigrationDetention => 'بازداشت مهاجرتی';

  @override
  String get immigrationDetentionDesc => 'حقوق شما در صورت بازداشت توسط مقامات';

  @override
  String get discriminationDesc => 'نحوه گزارش و مبارزه با تبعیض';

  @override
  String get scenarioNotFound => 'سناریو یافت نشد';

  @override
  String get youHaveRightTo => 'شما حق دارید:';

  @override
  String get youMust => 'شما باید:';

  @override
  String get immediateSteps => 'اقدامات فوری:';

  @override
  String get yourRights => 'حقوق شما:';

  @override
  String get basicRights => 'حقوق اساسی:';

  @override
  String get yourRightsAsTenant => 'حقوق شما به عنوان مستأجر:';

  @override
  String get yourRightsInDetention => 'حقوق شما در بازداشت:';

  @override
  String get howToAct => 'نحوه عمل:';

  @override
  String get rightKnowWhyStopped => 'دانستن دلیل توقف';

  @override
  String get rightRemainSilent => 'سکوت کردن (باید هویت خود را اعلام کنید)';

  @override
  String get rightAskInterpreter => 'درخواست مترجم';

  @override
  String get rightContactLawyer => 'تماس با وکیل قبل از بازجویی';

  @override
  String get rightRecordEncounter => 'ضبط مواجهه (در اماکن عمومی)';

  @override
  String get mustProvideName => 'ارائه نام و تاریخ تولد';

  @override
  String get mustShowId => 'نشان دادن کارت شناسایی در صورت داشتن';

  @override
  String get mustNotResist => 'مقاومت فیزیکی نکردن';

  @override
  String get doNotIgnoreNotice =>
      'اخطار را نادیده نگیرید - مهلت‌ها سختگیرانه هستند';

  @override
  String get noteAppealDeadline =>
      'مهلت تجدیدنظر را یادداشت کنید (معمولاً ۳۰ روز)';

  @override
  String get contactLawyerImmediately => 'فوراً با وکیل تماس بگیرید';

  @override
  String get applyLegalAid => 'در صورت نیاز درخواست کمک حقوقی دهید';

  @override
  String get rightAppealAdmin => 'حق تجدیدنظر در دادگاه اداری';

  @override
  String get rightLegalRep => 'حق داشتن نماینده حقوقی';

  @override
  String get rightInterpreter => 'حق داشتن مترجم';

  @override
  String get rightStayDuringAppeal =>
      'حق ماندن در طول تجدیدنظر (در اکثر موارد)';

  @override
  String get minimumWage => 'حداقل دستمزد طبق قرارداد جمعی';

  @override
  String get workingTimeLimits =>
      'محدودیت ساعت کار (حداکثر ۸ ساعت/روز، ۴۰ ساعت/هفته)';

  @override
  String get annualLeave => 'مرخصی سالانه (حداقل ۲ روز به ازای هر ماه کار)';

  @override
  String get sickLeave => 'غرامت مرخصی استعلاجی';

  @override
  String get safeWorkingConditions => 'شرایط کاری ایمن';

  @override
  String get writtenRentalAgreement => 'قرارداد اجاره کتبی الزامی است';

  @override
  String get securityDeposit => 'ودیعه حداکثر ۳ ماه اجاره';

  @override
  String get landlordNotice => 'موجر باید اخطار دهد (۳ تا ۶ ماه)';

  @override
  String get rightHabitableDwelling => 'حق داشتن مسکن مناسب';

  @override
  String get protectionUnjustEviction => 'حمایت در برابر تخلیه ناعادلانه';

  @override
  String get rightKnowDetentionReason => 'حق دانستن دلیل بازداشت';

  @override
  String get rightContactLawyerDetention => 'حق تماس با وکیل';

  @override
  String get rightContactEmbassy => 'حق تماس با سفارت خود';

  @override
  String get rightChallengeDetention => 'حق اعتراض به بازداشت در دادگاه';

  @override
  String get rightHumaneTreatment => 'حق برخورد انسانی و مراقبت پزشکی';

  @override
  String get documentIncident => 'حادثه را مستند کنید (تاریخ، زمان، شاهدان)';

  @override
  String get fileComplaintOmbudsman =>
      'شکایت نزد آمبودزمان عدم تبعیض تسلیم کنید';

  @override
  String get contactLegalAidOffice => 'با دفتر کمک حقوقی تماس بگیرید';

  @override
  String get reportToPolice =>
      'در صورت جنایی بودن به پلیس گزارش دهید (تهدید، حمله)';

  @override
  String get legalAidCalculator => 'محاسبه‌گر کمک حقوقی';

  @override
  String checkEligibility(String country) {
    return 'واجد شرایط بودن خود برای کمک حقوقی $country را بررسی کنید';
  }

  @override
  String get estimateDisclaimer =>
      'این فقط یک تخمین است. واجد شرایط بودن واقعی توسط دفتر کمک حقوقی تعیین می‌شود.';

  @override
  String get monthlyIncome => 'درآمد ماهانه (یورو)';

  @override
  String get totalAssets => 'کل دارایی‌ها (یورو)';

  @override
  String get numberOfDependents => 'تعداد افراد تحت تکفل';

  @override
  String get calculateEligibility => 'محاسبه واجد شرایط بودن';

  @override
  String get likelyEligible => 'احتمالاً واجد شرایط';

  @override
  String get mayNotQualify => 'ممکن است واجد شرایط نباشید';

  @override
  String get fullFreeLegalAid =>
      'شما احتمالاً واجد شرایط کمک حقوقی رایگان کامل هستید (بدون پرداخت سهم).';

  @override
  String legalAidWithCopay(String percent) {
    return 'ممکن است واجد شرایط کمک حقوقی با پرداخت سهم $percent% باشید.';
  }

  @override
  String get mayNotQualifyDesc =>
      'بر اساس این تخمین، ممکن است واجد شرایط کمک حقوقی دولتی نباشید. با یک وکیل خصوصی یا کلینیک حقوقی مشورت کنید.';

  @override
  String get couldNotLoadDeadlines => 'بارگذاری مهلت‌ها ممکن نشد';

  @override
  String get noUpcomingDeadlines => 'مهلت آینده‌ای نیست';

  @override
  String get allClearDeadlines =>
      'همه چیز مرتب است! مهلت‌های جدید در اینجا نمایش داده می‌شوند.';

  @override
  String get nothingOverdue => 'چیزی عقب نیفتاده';

  @override
  String get greatJobDeadlines => 'کار عالی در پیگیری مهلت‌هایتان.';

  @override
  String get noCompletedDeadlines => 'مهلت تکمیل شده‌ای نیست';

  @override
  String get completedDeadlinesDesc =>
      'مهلت‌هایی که تکمیل می‌کنید در اینجا نمایش داده می‌شوند.';

  @override
  String get daysLate => 'روز تأخیر';

  @override
  String get days => 'روز';

  @override
  String get fromDocument => 'از سند';

  @override
  String get couldNotLoadCase => 'بارگذاری جزئیات پرونده ممکن نشد';

  @override
  String get typeLabel => 'نوع';

  @override
  String get nationality => 'ملیت';

  @override
  String get migriReference => 'شماره مرجع Migri';

  @override
  String get courtCaseNo => 'شماره پرونده دادگاه';

  @override
  String get created => 'ایجاد شده';

  @override
  String get citizenship => 'تابعیت';

  @override
  String get workPermit => 'مجوز کار';

  @override
  String get noDocumentsYet => 'هنوز سندی بارگذاری نشده';

  @override
  String get noUpcomingDeadlinesShort => 'مهلت آینده‌ای نیست';

  @override
  String get caseCreated => 'پرونده ایجاد شد';

  @override
  String get decisionReceived => 'تصمیم دریافت شد';

  @override
  String get appealDeadline => 'مهلت تجدیدنظر';

  @override
  String get hearingScheduled => 'جلسه دادرسی تعیین شد';

  @override
  String get late => 'دیرکرد';

  @override
  String get pending => 'در انتظار';

  @override
  String get processing => 'در حال پردازش';

  @override
  String get ready => 'آماده';

  @override
  String get failed => 'ناموفق';

  @override
  String get analyzed => 'تحلیل شده';

  @override
  String get noDocumentsScanHint =>
      'هنوز سندی نیست. اسکن کنید یا بارگذاری کنید.';

  @override
  String get inCourt => 'در دادگاه';

  @override
  String get appeal => 'تجدیدنظر';

  @override
  String get caseTimeline => 'جدول زمانی پرونده';

  @override
  String get couldNotLoadTimeline => 'بارگذاری جدول زمانی ممکن نشد';

  @override
  String get noEventsYet => 'هنوز رویدادی نیست';

  @override
  String get activityWillAppear =>
      'فعالیت‌ها با پیشرفت پرونده شما در اینجا نمایش داده می‌شوند.';

  @override
  String caseCreatedDesc(String title) {
    return 'پرونده «$title» ایجاد شد.';
  }

  @override
  String get decisionReceivedDesc => 'یک تصمیم رسمی برای این پرونده دریافت شد.';

  @override
  String get appealDeadlineSet => 'مهلت تجدیدنظر تعیین شد';

  @override
  String appealDeadlineDesc(String date) {
    return 'تجدیدنظر باید تا $date تسلیم شود.';
  }

  @override
  String hearingScheduledDesc(String date) {
    return 'جلسه دادگاه برای $date تعیین شده است.';
  }

  @override
  String get caseInfoUpdated => 'اطلاعات پرونده آخرین بار به‌روزرسانی شد.';

  @override
  String get noEventsForFilter => 'هیچ رویدادی با این فیلتر مطابقت ندارد';

  @override
  String get timelineFilterAll => 'همه';

  @override
  String get timelineFilterEmails => 'ایمیل‌ها';

  @override
  String get timelineFilterConsilium => 'تصمیمات هوش مصنوعی';

  @override
  String get timelineFilterDeadlines => 'مهلت‌ها';

  @override
  String get timelineFilterNotes => 'یادداشت‌ها';

  @override
  String get timelineEventEmailIn => 'ایمیل دریافت شد';

  @override
  String get timelineEventEmailOut => 'ایمیل ارسال شد';

  @override
  String get timelineEventConsiliumDecision => 'تصمیم هوش مصنوعی';

  @override
  String get timelineEventDeadlineSet => 'مهلت';

  @override
  String get timelineEventDocUploaded => 'سند';

  @override
  String get timelineEventPhaseChange => 'تغییر مرحله';

  @override
  String get timelineEventManualNote => 'یادداشت';

  @override
  String get timelineJustNow => 'همین حالا';

  @override
  String timelineMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count دقیقه پیش',
      one: '۱ دقیقه پیش',
    );
    return '$_temp0';
  }

  @override
  String timelineHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ساعت پیش',
      one: '۱ ساعت پیش',
    );
    return '$_temp0';
  }

  @override
  String timelineDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count روز پیش',
      one: '۱ روز پیش',
    );
    return '$_temp0';
  }

  @override
  String get documentAnalysis => 'تحلیل سند';

  @override
  String get exportAsPdf => 'خروجی به صورت PDF';

  @override
  String get pdfExportComingSoon => 'خروجی PDF به زودی';

  @override
  String get analysisFailedRetry => 'تحلیل ناموفق بود. لطفاً دوباره تلاش کنید.';

  @override
  String get somethingWentWrong => 'مشکلی پیش آمد';

  @override
  String get genericError => 'مشکلی پیش آمد. لطفاً دوباره تلاش کنید.';

  @override
  String get retryAnalysis => 'تلاش مجدد تحلیل';

  @override
  String issuesFoundInDocument(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مشکل در سند یافت شد',
      one: '۱ مشکل در سند یافت شد',
      zero: 'مشکلی در سند یافت نشد',
    );
    return '$_temp0';
  }

  @override
  String get severityOverview => 'نمای کلی شدت';

  @override
  String get issuesFoundHeader => 'مشکلات یافت شده';

  @override
  String generateAppealWithIssues(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ایجاد دادخواست ($count مشکل)',
      one: 'ایجاد دادخواست (۱ مشکل)',
    );
    return '$_temp0';
  }

  @override
  String get analyzingContent => 'در حال تحلیل محتوا…';

  @override
  String get documentProcessedOk => 'سند با موفقیت پردازش شد';

  @override
  String get noSignificantIssues => 'مشکل قابل توجهی در این سند شناسایی نشد.';

  @override
  String get cameraPermissionRequired => 'مجوز دوربین لازم است';

  @override
  String get cameraPermissionDesc =>
      'برای اسکن اسناد دسترسی دوربین را اعطا کنید، یا از گالری استفاده کنید.';

  @override
  String get openSettings => 'باز کردن تنظیمات';

  @override
  String get alignDocument => 'سند را در کادر تنظیم کنید';

  @override
  String pageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count صفحه',
      one: '۱ صفحه',
      zero: 'بدون صفحه',
    );
    return '$_temp0';
  }

  @override
  String get preview => 'پیش‌نمایش';

  @override
  String pageNumber(int number) {
    return 'صفحه $number';
  }

  @override
  String get done => 'انجام شد';

  @override
  String get retake => 'عکس مجدد';

  @override
  String get useThisPhoto => 'استفاده از این عکس';

  @override
  String get addPage => 'افزودن صفحه';

  @override
  String uploadingPercent(int percent) {
    return 'در حال بارگذاری… $percent%';
  }

  @override
  String get preparingUpload => 'آماده‌سازی بارگذاری…';

  @override
  String get documentUploadedSuccess => 'سند با موفقیت بارگذاری شد';

  @override
  String pagesUploadedSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count صفحه با موفقیت بارگذاری شد',
      one: '۱ صفحه با موفقیت بارگذاری شد',
    );
    return '$_temp0';
  }

  @override
  String get uploadFailed =>
      'بارگذاری ناموفق بود. لطفاً اتصال خود را بررسی کنید و دوباره تلاش کنید.';

  @override
  String get capturePhotoFailed =>
      'گرفتن عکس ناموفق بود. لطفاً دوباره تلاش کنید.';

  @override
  String get readingText => 'در حال خواندن متن…';

  @override
  String get draftDocument => 'پیش‌نویس سند';

  @override
  String get saveChanges => 'ذخیره تغییرات';

  @override
  String get editDocument => 'ویرایش سند';

  @override
  String get generatingDraft => 'در حال تولید پیش‌نویس شما…';

  @override
  String get generatingDraftDesc =>
      'هوش مصنوعی در حال تهیه یک سند حقوقی بر اساس جزئیات پرونده و مشکلات انتخاب شده شماست.';

  @override
  String get failedToGenerateDraft =>
      'تولید پیش‌نویس ناموفق بود. لطفاً دوباره تلاش کنید.';

  @override
  String get changesSaved => 'تغییرات ذخیره شد';

  @override
  String get copiedToClipboard => 'در کلیپ‌بورد کپی شد';

  @override
  String get emailComingSoon => 'ارسال ایمیل به زودی';

  @override
  String get reviewBeforeSending =>
      'قبل از ارسال با دقت بررسی کنید. شما مسئول محتوای این سند هستید.';

  @override
  String get noContentAvailable => 'محتوایی در دسترس نیست';

  @override
  String get save => 'ذخیره';

  @override
  String get edit => 'ویرایش';

  @override
  String get pdf => 'PDF';

  @override
  String get copy => 'کپی';

  @override
  String get appealDraft => 'پیش‌نویس تجدیدنظر';

  @override
  String selected(int count) {
    return '$count انتخاب شده';
  }

  @override
  String get deleteSelected => 'حذف انتخاب شده‌ها';

  @override
  String deleteDocumentsConfirm(int count) {
    return '$count سند حذف شود؟';
  }

  @override
  String get delete => 'حذف';

  @override
  String get analyzeSelected => 'تحلیل انتخاب شده‌ها';

  @override
  String get batchAnalysisStarting => 'شروع تحلیل دسته‌ای…';

  @override
  String get switchToList => 'تغییر به فهرست';

  @override
  String get switchToGrid => 'تغییر به شبکه';

  @override
  String get scanNew => 'اسکن جدید';

  @override
  String get noDocumentsYetScan => 'هنوز سندی نیست';

  @override
  String get scanFirstDocumentHint =>
      'اولین سند خود را اسکن کنید تا هوش مصنوعی آن را برای خطاها تحلیل کند و تجدیدنظر تولید کند.';

  @override
  String get failedToLoadDocuments => 'بارگذاری اسناد ناموفق بود';

  @override
  String get emailIntegrationTitle => 'یکپارچه‌سازی ایمیل';

  @override
  String get connectYourEmail => 'ایمیل خود را متصل کنید';

  @override
  String get connectYourEmailDesc =>
      'ایمیل خود را متصل کنید تا مکاتبات حقوقی مرتبط با پرونده‌هایتان به طور خودکار شناسایی شود.';

  @override
  String get legalEmails => 'ایمیل‌های حقوقی';

  @override
  String get unlinkedEmails => 'ایمیل‌های متصل نشده';

  @override
  String get noLegalEmailsYet => 'هنوز ایمیل حقوقی وجود ندارد';

  @override
  String get legalEmailsWillAppear =>
      'ایمیل‌های طبقه‌بندی شده به عنوان حقوقی اینجا نمایش داده می‌شوند.';

  @override
  String get assignToCase => 'اختصاص به پرونده';

  @override
  String get disconnectEmail => 'قطع ایمیل';

  @override
  String get disconnectEmailConfirm =>
      'همگام‌سازی خودکار ایمیل متوقف می‌شود. ایمیل‌های قبلاً همگام‌سازی شده باقی می‌مانند.';

  @override
  String get gmailReauthBannerBody =>
      'Advocat نسخه ۲.۱ صندوق ورودی شما را برای پیش‌نویس پاسخ‌ها می‌خواند؛ هر زمان می‌توانید دسترسی را لغو کنید. برای فعال‌سازی غربالگری فعال، Gmail را دوباره وصل کنید.';

  @override
  String get gmailReauthBannerCta => 'تأیید مجدد دسترسی';

  @override
  String connectedTo(String email) {
    return 'متصل به $email';
  }

  @override
  String lastSynced(String time) {
    return 'آخرین همگام‌سازی: $time';
  }

  @override
  String get filterByType => 'فیلتر بر اساس نوع';

  @override
  String get noCasesMatchSearch => 'پرونده‌ای مطابق جستجو یافت نشد';

  @override
  String get failedToLoadCases => 'بارگذاری پرونده‌ها ناموفق بود';

  @override
  String get monthly => 'ماهانه';

  @override
  String get annual => 'سالانه';

  @override
  String get saveTwentyFivePercent => '۲۵٪ تخفیف';

  @override
  String get mostPopular => 'محبوب‌ترین';

  @override
  String get oneCaseActive => '۱ پرونده فعال';

  @override
  String get threeCasesActive => '۳ پرونده فعال';

  @override
  String get unlimitedCases => 'پرونده‌های نامحدود';

  @override
  String get threeDocScans => '۳ اسکن سند';

  @override
  String get twentyDocScans => '۲۰ اسکن سند';

  @override
  String get unlimitedDocScans => 'اسکن نامحدود اسناد';

  @override
  String get basicAiAnalysis => 'تحلیل پایه هوش مصنوعی';

  @override
  String get fullAiAnalysis => 'تحلیل کامل هوش مصنوعی';

  @override
  String get draftGeneration => 'تولید پیش‌نویس';

  @override
  String get priorityProcessing => 'پردازش اولویت‌دار';

  @override
  String get fiveAiMessagesTotal => '۵ پیام هوش مصنوعی (مادام‌العمر)';

  @override
  String get hundredAiMessagesDay => '۱۰۰ پیام هوش مصنوعی در روز';

  @override
  String get unlimitedAiMessages => 'پیام‌های نامحدود هوش مصنوعی';

  @override
  String get voiceInput => 'ورودی صوتی';

  @override
  String get strategyRecommendations => 'توصیه‌های راهبردی';

  @override
  String get foundingMemberNote => 'عضو مؤسس: ۹.۹۹ یورو در ماه برای ۳ ماه نخست';

  @override
  String get saveTwentyPercent => '۲۰٪ صرفه‌جویی';

  @override
  String get forever => 'برای همیشه';

  @override
  String get perMonth => '/ماه';

  @override
  String get perYear => '/سال';

  @override
  String get checkingPurchases => 'بررسی خریدهای قبلی…';

  @override
  String get noPreviousPurchases => 'خرید قبلی یافت نشد.';

  @override
  String get chatWelcomeMessage =>
      'Hi! I\'m Advocat — your AI legal assistant. I provide legal information, not legal advice. What legal question can I help with?';

  @override
  String get copySummary => 'کپی خلاصه';

  @override
  String get caseSummaryCopied => 'خلاصه پرونده کپی شد';

  @override
  String get openCase => 'باز کردن پرونده';

  @override
  String get viewFull => 'نمایش کامل';

  @override
  String get draftCopiedToClipboard => 'پیش‌نویس کپی شد';

  @override
  String get reportMileageFraud => 'گزارش تقلب در کیلومتر';

  @override
  String get reportMileageFraudDesc =>
      'گزارش تقلب بر اساس داده‌های بررسی خودرو ایجاد می‌شود. همچنین می‌توانید پرونده حقوقی باز کنید.';

  @override
  String get reportAndOpenCase => 'گزارش و باز کردن پرونده';

  @override
  String get caseCreationComingSoon =>
      'ایجاد پرونده با داده‌های از پیش پر شده به زودی';

  @override
  String get failedToCreateCaseRetry =>
      'ایجاد پرونده ناموفق بود. دوباره تلاش کنید.';

  @override
  String get takePhotoInstead => 'عکس بگیرید';

  @override
  String get deleteCase => 'حذف پرونده';

  @override
  String deleteCaseConfirm(String title) {
    return 'آیا مطمئنید که می‌خواهید «$title» را حذف کنید؟ این عمل قابل بازگشت نیست.';
  }

  @override
  String get haveQuestionsAi => 'سؤالی دارید؟ از هوش مصنوعی بپرسید';

  @override
  String get cookiePolicy => 'سیاست کوکی';

  @override
  String get aiDisclaimer => 'سلب مسئولیت هوش مصنوعی';

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
  String get dataPrivacyConsent => 'رضایت حریم خصوصی';

  @override
  String get gdprIntro =>
      'برای ارائه کمک حقوقی مبتنی بر هوش مصنوعی، داده‌های شما مطابق GDPR (EU 2016/679) پردازش می‌شود. با ادامه موافقت می‌کنید با:';

  @override
  String get gdprChat => 'پردازش پیام‌های چت توسط هوش مصنوعی';

  @override
  String get gdprDocs => 'تحلیل اسناد بارگذاری شده';

  @override
  String get gdprStorage => 'ذخیره‌سازی رمزگذاری شده داده‌های پرونده';

  @override
  String get gdprDelete => 'حق حذف داده‌ها در هر زمان';

  @override
  String get gdprFooter =>
      'داده‌های شما رمزگذاری شده و هرگز با اشخاص ثالث به اشتراک گذاشته نمی‌شود. می‌توانید رضایت را لغو کرده و تمام داده‌ها را از تنظیمات حذف کنید.';

  @override
  String get gdprConsentAiProcessing =>
      'با پردازش داده‌هایم برای دستیار حقوقی هوش مصنوعی موافقم (الزامی)';

  @override
  String get gdprConsentAnalytics =>
      'با تحلیل داده‌ها برای بهبود سرویس موافقم (اختیاری)';

  @override
  String get gdprArt9Intro =>
      'این برنامه داده‌های شخصی دسته‌های ویژه را طبق ماده ۹ GDPR پردازش می‌کند، از جمله:';

  @override
  String get gdprSpecialLegalCases => 'جزئیات پرونده حقوقی و اسناد دادگاهی شما';

  @override
  String get gdprSpecialNationality => 'ملیت و وضعیت مهاجرتی';

  @override
  String get gdprConsentLegalData =>
      'با پردازش داده‌های پرونده حقوقی، ملیت و وضعیت مهاجرتی‌ام توسط هوش مصنوعی موافقم (الزامی)';

  @override
  String get gdprConsentVoice => 'با پردازش ضبط صدا موافقم (اختیاری)';

  @override
  String get gdprViewPrivacyPolicy => 'مشاهده سیاست حریم خصوصی';

  @override
  String get legalInformation => 'اطلاعات حقوقی';

  @override
  String get legalEntityName => 'Vorantis OÜ';

  @override
  String get legalRegistryCode => 'کد ثبت: 17098992';

  @override
  String get legalAddress =>
      'Harju maakond, Tallinn, Kesklinna linnaosa, Tornimäe tn 5, 10145';

  @override
  String get legalEmail => 'ایمیل: support@advocat.ee';

  @override
  String get legalRegistry => 'ثبت‌شده در دفتر ثبت تجاری استونی (Äriregister)';

  @override
  String get aiGeneratedDisclaimer => 'AI-generated • Not legal advice';

  @override
  String get decline => 'رد کردن';

  @override
  String get iAgree => 'موافقم';

  @override
  String get iAgreeToThe => 'موافقت می‌کنم با ';

  @override
  String get orWord => 'یا';

  @override
  String get english => 'انگلیسی';

  @override
  String get russian => 'روسی';

  @override
  String get finnish => 'فنلاندی';

  @override
  String successSubscribed(String plan) {
    return 'اشتراک $plan با موفقیت فعال شد!';
  }

  @override
  String paymentFailed(String error) {
    return 'پرداخت ناموفق: $error';
  }

  @override
  String get whatToDo => 'چه باید کرد';

  @override
  String get getHelp => 'دریافت کمک';

  @override
  String get share => 'اشتراک‌گذاری';

  @override
  String get didYouKnow => 'آیا می‌دانستید؟';

  @override
  String get mustKnow => 'باید بدانید';

  @override
  String get goodToKnow => 'خوب است بدانید';

  @override
  String get sentFromAdvocat => 'ارسال شده از اپلیکیشن Advocat';

  @override
  String get policeActionStayCalm =>
      'آرام بمانید و دست‌هایتان را قابل مشاهده نگه دارید';

  @override
  String get policeActionAskWhy => 'از مأمور بپرسید چرا متوقف شده‌اید';

  @override
  String get policeActionProvideName => 'نام و تاریخ تولد خود را ارائه دهید';

  @override
  String get policeActionWantLawyer =>
      'واضح بگویید: «من قبل از هر سؤالی وکیل می‌خواهم»';

  @override
  String get policeActionAskInterpreter => 'در صورت نیاز مترجم بخواهید';

  @override
  String get policeActionNoteBadge =>
      'نام و شماره شناسایی مأمور را یادداشت کنید';

  @override
  String get policeFactMustTellReason =>
      'در فنلاند، پلیس باید دلیل توقف شما را بگوید. اگر نگویند، می‌توانید بپرسید — و قانوناً موظف به توضیح هستند.';

  @override
  String get policeFactCanRecord =>
      'شما می‌توانید تعاملات پلیس را در مکان‌های عمومی در فنلاند ضبط کنید. این تحت آزادی بیان محافظت می‌شود.';

  @override
  String get contactFinnishLegalAid => 'کمک حقوقی فنلاند';

  @override
  String get contactNonDiscriminationOmbudsman => 'بازرس مبارزه با تبعیض';

  @override
  String get deportationDeadlineAppeal =>
      'اعتراض به دادگاه اداری — معمولاً ۳۰ روز پس از ابلاغ';

  @override
  String get deportationDeadlineLegalAid =>
      'درخواست کمک حقوقی بدهید — فوراً این کار را انجام دهید';

  @override
  String get deportationFactStayDuringAppeal =>
      'در فنلاند، شما معمولاً حق دارید در حالی که اعتراض شما در حال بررسی است در کشور بمانید. اخراج در اکثر موارد در طول اعتراض فعال امکان‌پذیر نیست.';

  @override
  String get contactRefugeeAdviceCentre => 'مرکز مشاوره پناهندگان فنلاند';

  @override
  String get contactAdminCourtHelsinki => 'دادگاه اداری هلسینکی';

  @override
  String get workplaceActionKeepContract =>
      'نسخه‌هایی از قرارداد کار خود را نگه دارید';

  @override
  String get workplaceActionTrackHours =>
      'ساعات کاری خود را به طور مستقل پیگیری کنید';

  @override
  String get workplaceActionReportUnsafe =>
      'شرایط ناامن را به مرجع ایمنی شغلی گزارش دهید';

  @override
  String get workplaceActionJoinUnion =>
      'برای حمایت به یک اتحادیه کارگری بپیوندید';

  @override
  String get workplaceActionContactAuthority =>
      'در صورت نیاز با مرجع ایمنی شغلی تماس بگیرید';

  @override
  String get workplaceFactCollectiveWage =>
      'در فنلاند، قراردادهای جمعی حداقل دستمزد را بر اساس صنعت تعیین می‌کنند — حداقل دستمزد ملی واحدی وجود ندارد. کارفرمای شما باید از قرارداد جمعی حوزه شما پیروی کند.';

  @override
  String get workplaceFactOralContract =>
      'حتی بدون قرارداد کتبی، در فنلاند حقوق کامل کارمندی دارید. توافق شفاهی به همان اندازه از نظر قانونی الزام‌آور است.';

  @override
  String get contactOccupationalSafety => 'مرجع ایمنی شغلی';

  @override
  String get contactTradeUnionSAK => 'مشاوره اتحادیه کارگری (SAK)';

  @override
  String get tenantActionWrittenAgreement =>
      'همیشه قرارداد اجاره کتبی داشته باشید';

  @override
  String get tenantActionDocumentCondition =>
      'وضعیت آپارتمان را هنگام نقل مکان مستند کنید (عکس)';

  @override
  String get tenantActionReportMaintenance =>
      'مشکلات تعمیر و نگهداری را کتباً گزارش دهید';

  @override
  String get tenantActionNoIllegalEviction =>
      'هرگز با تخلیه غیرقانونی موافقت نکنید — دادگاه‌ها باید تصمیم بگیرند';

  @override
  String get tenantActionContactAdvisory =>
      'در صورت اختلاف با خدمات مشاوره مستأجران تماس بگیرید';

  @override
  String get tenantFactNoEvictionWithoutCourt =>
      'موجر در فنلاند نمی‌تواند بدون حکم دادگاه شما را تخلیه کند، حتی اگر اجاره‌نامه منقضی شده باشد. تعویض قفل یا قطع خدمات غیرقانونی است.';

  @override
  String get contactTenantsAssociation => 'انجمن مستأجران فنلاند';

  @override
  String get contactConsumerDisputesBoard => 'هیئت حل اختلاف مصرف‌کننده';

  @override
  String get detentionActionAskDecision =>
      'فوراً تصمیم کتبی بازداشت را بخواهید';

  @override
  String get detentionActionRequestLawyer => 'درخواست تماس با وکیل کنید';

  @override
  String get detentionActionContactEmbassy =>
      'با سفارت یا کنسولگری خود تماس بگیرید';

  @override
  String get detentionActionAskMedical =>
      'در صورت نیاز درخواست مراقبت پزشکی کنید';

  @override
  String get detentionActionRequestInterpreter =>
      'برای تمام جلسات مترجم بخواهید';

  @override
  String get detentionDeadlineCourtReview =>
      'دادگاه بخش باید بازداشت را ظرف ۴ روز بررسی کند';

  @override
  String get detentionDeadlineContinuation =>
      'دادگاه تمدید را هر ۲ هفته بررسی می‌کند';

  @override
  String get detentionFactCourtReview =>
      'بازداشت مهاجرتی در فنلاند باید ظرف ۴ روز توسط دادگاه بخش بررسی شود. اگر انجام نشود، بازداشت غیرقانونی می‌شود.';

  @override
  String get contactParliamentaryOmbudsman => 'بازرس پارلمانی';

  @override
  String get discriminationActionWriteDown =>
      'دقیقاً بنویسید چه اتفاقی افتاد (تاریخ، زمان، مکان)';

  @override
  String get discriminationActionSaveEvidence =>
      'مدارک را نگه دارید: پیام‌ها، ایمیل‌ها، شاهدان';

  @override
  String get discriminationActionFileComplaint =>
      'شکایت به بازرس مبارزه با تبعیض ارائه دهید';

  @override
  String get discriminationActionContactLegalAid =>
      'برای مشاوره رایگان با دفتر کمک حقوقی تماس بگیرید';

  @override
  String get discriminationActionReportPolice =>
      'اگر تهدید یا حمله بود به پلیس گزارش دهید';

  @override
  String get discriminationFactNonDiscriminationAct =>
      'قانون عدم تبعیض فنلاند تبعیض بر اساس سن، خاستگاه، تابعیت، زبان، مذهب، سلامت، معلولیت، گرایش جنسی و سایر ویژگی‌های شخصی را پوشش می‌دهد.';

  @override
  String get contactVictimSupportRIKU => 'حمایت از قربانیان فنلاند (RIKU)';

  @override
  String get domesticViolence => 'خشونت خانگی';

  @override
  String get domesticViolenceDesc =>
      'حقوق قربانی، کمک اضطراری، احکام منع نزدیکی';

  @override
  String get rightCallEmergency =>
      'شما حق دارید در هر شرایط اضطراری با ۱۱۲ تماس بگیرید — پلیس، آمبولانس، آتش‌نشانی';

  @override
  String get rightVictimProtection =>
      'به‌عنوان قربانی، شما حق محافظت، حمایت و دریافت اطلاعات درباره پرونده خود را دارید';

  @override
  String get rightRestrainingOrder =>
      'می‌توانید برای دور نگه داشتن آزاردهنده درخواست حکم منع نزدیکی (lähestymiskielto) دهید';

  @override
  String get rightVictimInterpreter =>
      'شما در تمام مراحل قانونی حق داشتن مترجم را دارید';

  @override
  String get rightMedicalHelp =>
      'شما حق درمان فوری پزشکی و مستندسازی آسیب‌ها را دارید';

  @override
  String get rightShelter =>
      'شما حق سرپناه اضطراری را دارید — با یک پناهگاه یا خدمات اجتماعی تماس بگیرید';

  @override
  String get mustReportDanger =>
      'اگر کسی در خطر فوری است، بلافاصله با ۱۱۲ تماس بگیرید';

  @override
  String get mustDocumentInjuries =>
      'تمام آسیب‌ها را مستند کنید — عکس، سوابق پزشکی، یادداشت‌های کتبی';

  @override
  String get domesticActionCallEmergency =>
      'اگر در خطر فوری هستید با ۱۱۲ تماس بگیرید';

  @override
  String get domesticActionGoToSafe =>
      'به مکانی امن بروید — پناهگاه، دوست، مکان عمومی';

  @override
  String get domesticActionDocumentEverything =>
      'آسیب‌ها را مستند کنید: عکس بگیرید، سوابق پزشکی تهیه کنید';

  @override
  String get domesticActionFilePoliceReport =>
      'شکایت پلیسی ثبت کنید — می‌توانید این کار را بعداً هم انجام دهید';

  @override
  String get domesticActionContactShelter =>
      'با یک پناهگاه یا خط تلفن بحران تماس بگیرید';

  @override
  String get domesticActionApplyRestraining =>
      'از طریق پلیس یا دادگاه درخواست حکم منع نزدیکی دهید';

  @override
  String get domesticFactRestrainingOrder =>
      'در فنلاند، حکم منع نزدیکی (lähestymiskielto) می‌تواند حتی بدون پرونده کیفری صادر شود. این حکم فرد را از تماس یا نزدیک شدن به شما منع می‌کند.';

  @override
  String get domesticFactVictimDirective =>
      'طبق دستورالعمل قربانیان اتحادیه اروپا 2012/29/EU، شما حق دارید با احترام با شما رفتار شود، اطلاعات را به زبانی که می‌فهمید دریافت کنید و به خدمات حمایت از قربانیان دسترسی داشته باشید — صرف‌نظر از وضعیت اقامت شما.';

  @override
  String get domesticDeadlinePoliceReport =>
      'ثبت شکایت پلیسی — مهلت سختگیرانه‌ای ندارد، اما هرچه زودتر برای حفظ شواهد بهتر است';

  @override
  String get domesticDeadlineRestraining =>
      'حکم منع نزدیکی — در هر زمان قابل درخواست است';

  @override
  String get contactEmergency => 'شماره اضطراری';

  @override
  String get contactShelter => 'خط تلفن پناهگاه (Turvakoti)';

  @override
  String get contactCrisisHelpline => 'خط تلفن بحران (Kriisipuhelin)';

  @override
  String get contactNollaLinja => 'Nollalinja — خط تلفن خشونت علیه زنان';

  @override
  String get inheritance => 'ارث';

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
  String get consumerProtection => 'حمایت از مصرف‌کننده';

  @override
  String get consumerProtectionDesc =>
      'کلاهبرداری، محصولات معیوب، مرجوعی، فروشندگان فریبکار';

  @override
  String get rightReturnOnline =>
      'شما ۱۴ روز فرصت دارید خریدهای آنلاین را بدون دلیل لغو کنید (حق انصراف اتحادیه اروپا)';

  @override
  String get rightDefectiveProduct =>
      'اگر محصولی معیوب است، شما حق تعمیر، تعویض یا بازپرداخت را دارید';

  @override
  String get rightClearPricing =>
      'فروشندگان باید قیمت‌های شفاف شامل تمام هزینه‌ها را نمایش دهند — هزینه‌های پنهان غیرقانونی هستند';

  @override
  String get rightComplainBoard =>
      'می‌توانید به‌صورت رایگان شکایتی به هیئت اختلافات مصرف‌کننده ثبت کنید';

  @override
  String get rightProtectionFraud =>
      'شما در برابر شیوه‌های تجاری ناعادلانه و کلاهبرداری محافظت می‌شوید';

  @override
  String get mustKeepReceipts =>
      'تمام رسیدها، قراردادها و مکاتبات با فروشندگان را نگه دارید';

  @override
  String get mustActTimely =>
      'نقص‌ها را در زمان معقولی پس از کشف به فروشنده گزارش دهید';

  @override
  String get consumerActionKeepEvidence =>
      'رسیدها، تصاویر صفحه، ایمیل‌ها و تمام مدارک خرید را نگه دارید';

  @override
  String get consumerActionContactSeller =>
      'ابتدا با فروشنده تماس بگیرید — مشکل را به‌صورت کتبی توضیح دهید';

  @override
  String get consumerActionFileComplaint =>
      'شکایتی به هیئت اختلافات مصرف‌کننده (kuluttajariitalautakunta) ثبت کنید';

  @override
  String get consumerActionContactAuthority =>
      'برای کمک رایگان با خدمات مشاوره مصرف‌کننده تماس بگیرید';

  @override
  String get consumerActionReportFraud =>
      'کلاهبرداری را به پلیس و دادستان مصرف‌کننده گزارش دهید';

  @override
  String get consumerFactWithdrawal =>
      'طبق دستورالعمل حقوق مصرف‌کننده اتحادیه اروپا 2011/83/EU، شما ۱۴ روز فرصت دارید از هر خرید آنلاین یا از راه دور انصراف دهید — بدون هیچ پرسشی. فروشنده باید ظرف ۱۴ روز مبلغ را بازپرداخت کند.';

  @override
  String get consumerFactWarranty =>
      'در فنلاند، فروشنده برای مدت معقولی (اغلب ۲ سال یا بیشتر) مسئول نقص‌های محصول است. این مستقل از هرگونه گارانتی سازنده است.';

  @override
  String get consumerDeadlineWithdrawal =>
      'انصراف از خرید آنلاین — ۱۴ روز از زمان تحویل';

  @override
  String get consumerDeadlineDefect =>
      'گزارش نقص به فروشنده — ظرف ۲ ماه از کشف (توصیه‌شده)';

  @override
  String get contactConsumerAdvisory => 'خدمات مشاوره مصرف‌کننده';

  @override
  String get contactConsumerOmbudsman =>
      'دادستان مصرف‌کننده (Kuluttaja-asiamies)';

  @override
  String get contactConsumerDisputesBoardDirect => 'هیئت اختلافات مصرف‌کننده';

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
  String get comingSoon => 'به زودی';

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
      other: '$count حق در داخل',
      one: '۱ حق در داخل',
      zero: 'بدون حق',
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
  String get chatDisclaimerSubtitle => 'AI assistant · not legal advice';

  @override
  String get chatDisclaimerBannerFull =>
      'Advocat is an AI legal-information assistant, not a lawyer. Information here does not establish an attorney-client relationship, is not legal advice, and may be incorrect. For binding legal advice, consult a licensed attorney in your jurisdiction. We do not represent you.';

  @override
  String get chatDisclaimerFooter =>
      'AI-generated. Verify with a licensed lawyer.';

  @override
  String get chatDisclaimerGotIt => 'Got it';

  @override
  String get categoryChildren => 'کودکان';

  @override
  String get categoryDigital => 'دیجیتال';

  @override
  String get childrenRights => 'حقوق کودکان و نفقه';

  @override
  String get childrenRightsDesc => 'نفقه فرزند، نفقه، حمایت، تضمین‌های دولتی';

  @override
  String get cyberbullying => 'قلدری سایبری و آزار آنلاین';

  @override
  String get cyberbullyingDesc => 'تهدید، نقض حریم خصوصی، افترا در فضای آنلاین';

  @override
  String get rightChildSupport =>
      'هر دو والد از نظر قانونی موظف به حمایت مالی از فرزند خود هستند (Perekonnaseadus § 100–102)';

  @override
  String get rightMinimumAlimony =>
      'حداقل نفقه فرزند در استونی: مبلغ پایه (€295.86) + ۳٪ میانگین حقوق ناخالص سال گذشته (PKS § 101). از 01.04.2026 — €318.62 در ماه برای هر فرزند. هر سال در اول آوریل به‌روزرسانی می‌شود. ماشین‌حساب: alimendid.ee';

  @override
  String get rightCourtAlimony =>
      'می‌توانید از طریق دادگاه شهرستان (maakohus) درخواست نفقه دهید — برای ادعاهای تا €6,400 نیازی به وکیل نیست';

  @override
  String get rightBailiffEnforcement =>
      'اگر والد از پرداخت خودداری کند، یک مأمور اجرا (kohtutäitur) می‌تواند حکم دادگاه را اجرا کند، از جمله توقیف حقوق';

  @override
  String get rightStateAlimonyGuarantee =>
      'اگر والد پرداخت نکند، دولت از طریق Sotsiaalkindlustusamet کمک‌هزینه نفقه (elatisabi) ارائه می‌دهد — تا €100 در ماه برای هر فرزند';

  @override
  String get rightChildEducation =>
      'هر کودکی حق آموزش، مراقبت بهداشتی و محافظت در برابر سوءاستفاده را دارد (Lastekaitseseadus § 4–5)';

  @override
  String get rightChildContact =>
      'کودک حق دارد ارتباط خود را با هر دو والد حفظ کند مگر اینکه دادگاه طور دیگری تصمیم بگیرد (PKS § 143)';

  @override
  String get mustFileCourtClaim =>
      'برای دریافت نفقه، باید در دادگاه دعوا اقامه کنید یا مبلغ را به‌صورت کتبی توافق کنید';

  @override
  String get mustNotifyAddressChange =>
      'اگر elatisabi دریافت می‌کنید، تغییرات آدرس را به Sotsiaalkindlustusamet اطلاع دهید';

  @override
  String get childrenActionGatherDocs =>
      'گواهی تولد فرزند، کارت شناسایی خود و مدارک هزینه‌ها را جمع‌آوری کنید';

  @override
  String get childrenActionFileCourtClaim =>
      'دعوای نفقه را در دادگاه شهرستان (maakohus) اقامه کنید — می‌تواند آنلاین از طریق e-toimik انجام شود';

  @override
  String get childrenActionApplyElatisabi =>
      'اگر والد پرداخت نکند، در Sotsiaalkindlustusamet برای تضمین نفقه دولتی (elatisabi) درخواست دهید';

  @override
  String get childrenActionContactBailiff =>
      'برای اجرای حکم دادگاه با یک مأمور اجرا (kohtutäitur) تماس بگیرید';

  @override
  String get childrenActionCallLasteabi =>
      'با خط تلفن کودکان Lasteabi 116 111 تماس بگیرید — رایگان، ۲۴ ساعته';

  @override
  String get childrenDeadlineElatisabi =>
      'درخواست elatisabi — پس از حکم دادگاه، مهلت سختگیرانه‌ای ندارد اما فرایند زمان‌بر است';

  @override
  String get childrenDeadlineCourt =>
      'نفقه را می‌توان به‌صورت گذشته‌نگر تا ۱ سال پیش از ثبت در دادگاه مطالبه کرد';

  @override
  String get childrenFactMinimum =>
      'از 01.04.2026 حداقل نفقه فرزند €318.62 در ماه برای هر فرزند است. فرمول: مبلغ پایه (€295.86) + ۳٪ میانگین حقوق ناخالص سال گذشته. هر سال در اول آوریل به‌روزرسانی می‌شود. یک والد نمی‌تواند توافق کند کمتر بپردازد. ماشین‌حساب: alimendid.ee';

  @override
  String get childrenFactElatisabi =>
      'تضمین نفقه دولتی استونی (elatisabi) در سال ۲۰۱۷ برای محافظت از کودکان هنگامی که یک والد از پرداخت خودداری می‌کند، معرفی شد. دولت پرداخت می‌کند و سپس مبلغ را از والد بدهکار بازپس می‌گیرد.';

  @override
  String get rightReportCybercrime =>
      'شما حق دارید تهدیدهای آنلاین، آزار و سرقت هویت را به پلیس گزارش دهید (Karistusseadustik § 120, § 157¹)';

  @override
  String get rightContentRemoval =>
      'می‌توانید درخواست حذف محتوای افتراآمیز یا خصوصی از پلتفرم‌ها را داشته باشید و طبق GDPR خواستار حذف آن شوید';

  @override
  String get rightMoralDamageCompensation =>
      'می‌توانید برای خسارت معنوی ناشی از قلدری سایبری مطالبه غرامت کنید (Võlaõigusseadus § 1043–1055)';

  @override
  String get rightPrivacyProtection =>
      'حریم خصوصی شما محافظت می‌شود — اشتراک‌گذاری غیرمجاز عکس‌ها، پیام‌ها یا داده‌های شخصی شما غیرقانونی است (KarS § 157)';

  @override
  String get rightDataProtection =>
      'نقض حفاظت از داده‌ها (استفاده غیرمجاز از داده‌های شما) را به Andmekaitse Inspektsioon گزارش دهید';

  @override
  String get rightDefamationAction =>
      'افترا (laimamine) یک تخلف مدنی است — می‌توانید برای خسارت شکایت کنید و خواستار عذرخواهی عمومی شوید (KarS § 247 (لغوشده)، VÕS § 1047)';

  @override
  String get mustCollectEvidence =>
      'تمام شواهد را جمع‌آوری و حفظ کنید — تصاویر صفحه، لینک‌ها، تاریخ‌ها و اطلاعات شاهدان';

  @override
  String get mustNotRetaliate =>
      'تلافی نکنید یا در آزار متقابل شرکت نکنید — ممکن است پرونده شما را تضعیف کند';

  @override
  String get cyberActionScreenshots =>
      'از تمام موارد آزار تصویر صفحه بگیرید — نشانی‌های اینترنتی، تاریخ‌ها، نام‌های کاربری و محتوا را ذخیره کنید';

  @override
  String get cyberActionReportPolice =>
      'در نزدیک‌ترین کلانتری یا به‌صورت آنلاین در politsei.ee شکایت پلیسی ثبت کنید';

  @override
  String get cyberActionReportPlatform =>
      'محتوا را برای حذف به پلتفرم رسانه اجتماعی گزارش دهید';

  @override
  String get cyberActionContactDPA =>
      'اگر از داده‌های شخصی شما سوءاستفاده شده است، با Andmekaitse Inspektsioon تماس بگیرید';

  @override
  String get cyberActionConsultLawyer =>
      'درباره خسارات مدنی با یک وکیل مشورت کنید — کمک حقوقی رایگان از طریق Riigi Õigusabi در دسترس است';

  @override
  String get cyberDeadlineCriminal =>
      'شکایت کیفری — مهلت سختگیرانه‌ای ندارد، اما برای بهترین نتیجه سریع گزارش دهید';

  @override
  String get cyberDeadlineCivil =>
      'دعوای مدنی برای خسارت — تا ۳ سال از زمانی که از تخلف مطلع شدید (TsÜS § 150)';

  @override
  String get cyberFactPrivacy =>
      'در استونی، اشتراک‌گذاری غیرمجاز تصاویر خصوصی فرد می‌تواند طبق Karistusseadustik § 157¹ (نقض حریم خصوصی) تا ۳ سال زندان در پی داشته باشد.';

  @override
  String get cyberFactGDPR =>
      'طبق GDPR، شما «حق فراموش شدن» را دارید — پلتفرم‌ها باید در صورت درخواست، داده‌های شخصی شما را حذف کنند، مگر اینکه مبنای قانونی برای نگه‌داشتن آن وجود داشته باشد.';

  @override
  String get guestUser => 'مهمان';

  @override
  String get howToUse => 'چگونه استفاده کنیم؟';

  @override
  String get tutorialStep1Title => 'دستیار حقوقی هوش مصنوعی';

  @override
  String get tutorialStep1Desc =>
      'هر سوال حقوقی بپرسید و پاسخ‌های فوری بر اساس قوانین استونی دریافت کنید.';

  @override
  String get tutorialStep2Title => 'حقوق خود را بشناسید';

  @override
  String get tutorialStep2Desc =>
      'اطلاعات حقوقی را بر اساس موضوع مرور کنید — کار، مسکن، حقوق مصرف‌کننده و بیشتر.';

  @override
  String get tutorialStep3Title => 'اسکن اسناد';

  @override
  String get tutorialStep3Desc =>
      'از اسناد حقوقی عکس بگیرید برای تحلیل هوش مصنوعی و ذخیره‌سازی امن.';

  @override
  String get tutorialStep4Title => 'شروع کنیم!';

  @override
  String get tutorialStep4Desc =>
      'برنامه را کاوش کنید و از حقوق خود محافظت کنید. همه داده‌ها خصوصی در دستگاه شما باقی می‌مانند.';

  @override
  String get advocatProTitle => 'Advocat Pro';

  @override
  String get advocatProSubtitle => 'ویژگی‌های ویژه را باز کنید';

  @override
  String get voiceDisclaimer =>
      'دستیار صوتی فعلاً فقط روی دسکتاپ کار می‌کند (مرورگر Chrome). پشتیبانی موبایل به زودی.';

  @override
  String get recommended => 'پیشنهادی';

  @override
  String get pleaseLogIn => 'لطفاً وارد شوید';

  @override
  String get subscriptionNotFound => 'اشتراک یافت نشد';

  @override
  String errorWithMessage(String message) {
    return 'خطا: $message';
  }

  @override
  String get redirectingToPayment => 'در حال انتقال به صفحه پرداخت…';

  @override
  String cheaperAnnually(String amount) {
    return '€$amount/ماه ارزان‌تر با اشتراک سالانه';
  }

  @override
  String get navigatingTo => 'در حال باز کردن';

  @override
  String get stayInChat => 'ماندن در چت';

  @override
  String get backToChat => 'بازگشت به چت';

  @override
  String get upgradeBannerTitle => 'برای مشاوره‌های نامحدود ارتقا دهید';

  @override
  String get upgradeBannerCta => 'ارتقا';

  @override
  String get paymentSuccessTitle => 'پرداخت موفق';

  @override
  String get paymentSuccessBody => 'اشتراک شما اکنون فعال است.';

  @override
  String get commonOk => 'تأیید';

  @override
  String get feedbackThumbsUpLabel => 'مفید';

  @override
  String get feedbackThumbsDownLabel => 'غیرمفید';

  @override
  String get feedbackCommentPrompt => 'چه چیزی اشتباه بود؟';

  @override
  String get feedbackSend => 'ارسال';

  @override
  String get feedbackCancel => 'لغو';

  @override
  String get reasoningPillIdle => 'در حال فکر کردن…';

  @override
  String get reasoningPillSearchingLaw => 'در حال جستجوی قانون استونی…';

  @override
  String get reasoningPillSearchingWeb => 'در حال جستجوی وب…';

  @override
  String get reasoningPillCheckingCompany => 'در حال بررسی دفتر ثبت شرکت‌ها…';

  @override
  String get reasoningPillCheckingVehicle => 'در حال بررسی دفتر ثبت خودرو…';

  @override
  String get reasoningPillReadingDocument => 'در حال خواندن سند شما…';

  @override
  String get reasoningPillDrafting => 'در حال تنظیم پیش‌نویس سند…';

  @override
  String get reasoningPillPreparingEmail => 'در حال آماده‌سازی ایمیل…';

  @override
  String get reasoningPillFindingLawyer => 'در حال جستجوی وکلا…';

  @override
  String get reasoningPillThinking => 'در حال تحلیل پرونده شما…';

  @override
  String get reasoningPillFinalising => 'در حال نگارش پاسخ شما…';

  @override
  String reasoningCollapsedFormat(int sec, int sources) {
    return '$sec ثانیه استدلال · $sources منبع';
  }

  @override
  String get reasoningExpandHint => 'برای دیدن مراحل ضربه بزنید';

  @override
  String get caseFileTitle => 'پرونده';

  @override
  String get caseFileTimeline => 'خط زمانی';

  @override
  String get caseFileParties => 'طرف‌ها';

  @override
  String get caseFileDeadlines => 'مهلت‌ها';

  @override
  String get caseFileExportPdf => 'دانلود پرونده (PDF)';

  @override
  String get caseFileEmpty =>
      'درباره پرونده‌تان با هوش مصنوعی گفتگو کنید — خط زمانی شما خودبه‌خود ساخته می‌شود.';

  @override
  String get caseFileDisclaimer =>
      'این پرونده به‌صورت خودکار از گفتگوی شما استخراج شده است. این مشاوره حقوقی نیست.';

  @override
  String get caseFileTabLabel => 'پرونده';

  @override
  String get refresh => 'بازخوانی';

  @override
  String get demoLimitReached =>
      'محدودیت نسخه نمایشی به پایان رسید. برای ادامه به‌صورت رایگان ثبت‌نام کنید.';

  @override
  String get demoLimitSignUpCta => 'ثبت‌نام';

  @override
  String freeQuotaExhausted(int count) {
    return 'شما از تمام $count پیام رایگان این ماه استفاده کرده‌اید.';
  }

  @override
  String get upgradeForUnlimited => 'برای نامحدود به Pro ارتقا دهید';

  @override
  String get upgradeCta => 'ارتقا';

  @override
  String get rateLimitTryAgain =>
      'ارسال بیش از حد سریع است. چند ثانیه دیگر دوباره تلاش کنید.';

  @override
  String get quickProfilePrompt =>
      'تا بتوانم دقیق‌تر کمک کنم، وضعیت حقوقی شما چیست: شهروند استونی هستید، شهروند اتحادیه اروپا از کشوری دیگر، یا اجازه اقامت دارید؟';

  @override
  String get quickProfileChipEstonianCitizen => 'شهروند استونی';

  @override
  String get quickProfileChipEuCitizen => 'شهروند اتحادیه اروپا (دیگر)';

  @override
  String get quickProfileChipResidencePermit => 'اجازه اقامت';

  @override
  String get quickProfileSkipBtn => 'رد کردن';

  @override
  String get quickProfileSavedAck => 'متوجه شدم. حالا، سؤال شما چیست؟';

  @override
  String get caseTitleLabel => 'عنوان پرونده';

  @override
  String get jurisdictionLabel => 'حوزه قضایی';

  @override
  String get caseTypeLabel => 'نوع پرونده';

  @override
  String get caseLanguageLabel => 'زبان';

  @override
  String get caseNumbersSection => 'شماره‌های پرونده';

  @override
  String get partiesSection => 'طرف‌ها';

  @override
  String get authoritiesSection => 'مراجع';

  @override
  String get timelineSection => 'خط زمانی';

  @override
  String get openQuestionsSection => 'پرسش‌های باز';

  @override
  String get nextActionsSection => 'اقدامات بعدی';

  @override
  String get summarySection => 'خلاصه';

  @override
  String get addRow => 'افزودن ردیف';

  @override
  String get removeRow => 'حذف';

  @override
  String get archiveCase => 'بایگانی پرونده';

  @override
  String get closeCase => 'بستن پرونده';

  @override
  String get continueChatAboutCase => 'ادامه گفتگو درباره این پرونده';

  @override
  String get linkChatToCase => 'پیوند به پرونده';

  @override
  String get clearActiveCase => 'پاک کردن پرونده فعال';

  @override
  String get caseSavedAck => 'پرونده ذخیره شد';

  @override
  String get caseArchivedAck => 'پرونده بایگانی شد';

  @override
  String get intakeStep1Title => 'پرونده کجاست؟';

  @override
  String get intakeStep1Subtitle => 'کشور و مرجعی که با آن سروکار دارید.';

  @override
  String get intakeJurisdictionLabel => 'کشور / حوزه قضایی';

  @override
  String get intakeAuthorityLabel => 'نوع مرجع';

  @override
  String get intakeAuthorityNameLabel => 'نام مرجع (اختیاری)';

  @override
  String get intakeAuthorityPolice => 'پلیس';

  @override
  String get intakeAuthorityCourt => 'دادگاه';

  @override
  String get intakeAuthoritySocial => 'خدمات اجتماعی';

  @override
  String get intakeAuthorityEmployer => 'کارفرما';

  @override
  String get intakeAuthorityLandlord => 'صاحب‌خانه';

  @override
  String get intakeAuthorityOpposingParty => 'طرف مقابل';

  @override
  String get intakeAuthorityOther => 'سایر';

  @override
  String get intakeStep2Title => 'چه نوع پرونده‌ای؟';

  @override
  String get intakeStep2Subtitle =>
      'نزدیک‌ترین نوع را انتخاب کنید — بعداً می‌توانید آن را اصلاح کنید.';

  @override
  String get intakeCaseTypeCriminal => 'کیفری';

  @override
  String get intakeCaseTypeCivil => 'مدنی';

  @override
  String get intakeCaseTypeFamily => 'خانواده';

  @override
  String get intakeCaseTypeAdmin => 'اداری';

  @override
  String get intakeCaseTypeImmigration => 'مهاجرت';

  @override
  String get intakeCaseTypeLabor => 'کار';

  @override
  String get intakeCaseTypeConsumer => 'مصرف‌کننده';

  @override
  String get intakeCaseTypeInheritance => 'ارث';

  @override
  String get intakeCaseTypeOther => 'سایر';

  @override
  String get intakeStep3Title => 'چه کسانی درگیر هستند؟';

  @override
  String get intakeStep3Subtitle => 'نقش شما و طرف مقابل.';

  @override
  String get intakeRoleLabel => 'نقش شما';

  @override
  String get intakeRolePlaintiff => 'خواهان';

  @override
  String get intakeRoleDefendant => 'خوانده';

  @override
  String get intakeRoleVictim => 'قربانی';

  @override
  String get intakeRoleAccused => 'متهم';

  @override
  String get intakeRoleWitness => 'شاهد';

  @override
  String get intakeRoleFamily => 'عضو خانواده';

  @override
  String get intakeRoleOther => 'سایر';

  @override
  String get intakeOpposingSideLabel => 'طرف مقابل (اختیاری)';

  @override
  String get intakeWitnessesLabel => 'شاهدان (اختیاری)';

  @override
  String get intakeAddWitness => 'افزودن شاهد';

  @override
  String get intakeWitnessHint => 'نام یا اطلاعات تماس';

  @override
  String get intakeStep4Title => 'شماره‌ها و تاریخ‌ها';

  @override
  String get intakeStep4Subtitle => 'هرچه دارید. آنچه ندارید را رد کنید.';

  @override
  String get intakeCaseNumberLabel => 'شماره پرونده (اختیاری)';

  @override
  String get intakeIncidentDateLabel => 'تاریخ رخداد (اختیاری)';

  @override
  String get intakeIncidentDatePick => 'انتخاب تاریخ';

  @override
  String get intakeDeadlinesLabel => 'مهلت‌های شناخته‌شده';

  @override
  String get intakeAddDeadline => 'افزودن مهلت';

  @override
  String get intakeDeadlineWhatHint => 'چه چیزی';

  @override
  String get intakeStep5Title => 'اسناد';

  @override
  String get intakeStep5Subtitle =>
      'هر چیز مرتبطی را بارگذاری کنید. ما آن را خواهیم خواند.';

  @override
  String get intakeUploadDocsLabel => 'بارگذاری اسناد';

  @override
  String get intakeSkipDocs => 'رد کردن — بعداً بارگذاری می‌کنم';

  @override
  String get intakeNextBtn => 'بعدی';

  @override
  String get intakeBackBtn => 'بازگشت';

  @override
  String get intakeFinishBtn => 'پایان و باز کردن گفتگو';

  @override
  String get intakeUrgentBtn => 'فوری — همین حالا بپرسید';

  @override
  String get intakeUrgentDialogTitle => 'گفتگو را همین حالا باز کنم؟';

  @override
  String get intakeUrgentDialogBody =>
      'آنچه وارد کرده‌اید را به‌عنوان پرونده پیش‌نویس ذخیره می‌کنیم. می‌توانید هر زمان از صفحه پرونده، راهنمای گام‌به‌گام را تکمیل کنید.';

  @override
  String get intakeUrgentConfirm => 'باز کردن گفتگو';

  @override
  String get intakeUrgentCancel => 'ادامه پر کردن';

  @override
  String get intakePreparingCase => 'در حال آماده‌سازی پرونده شما…';

  @override
  String get intakeFallbackGreeting =>
      'پرونده شما را می‌بینم. مهم‌ترین موضوع را بگویید — همراه شما به آن رسیدگی می‌کنم.';

  @override
  String get intakeUrgentGreeting =>
      'می‌بینم که این موضوع فوری است. سؤال خود را بپرسید — بقیه را در ادامه تکمیل می‌کنم.';

  @override
  String intakeStepIndicator(int current, int total) {
    return 'گام $current از $total';
  }

  @override
  String get intakeFieldRequired => 'الزامی';

  @override
  String intakeUploadProgress(int done, int total) {
    return 'در حال بارگذاری $done / $total…';
  }

  @override
  String get uplDisclaimerFooter =>
      'Advocat یک مؤسسه حقوقی نیست. این اطلاعات است، نه مشاوره حقوقی.';

  @override
  String get citationStatusVerifiedBadge => 'تأییدشده';

  @override
  String get citationStatusUnverifiedBadge => 'تأییدنشده';

  @override
  String get citationStatusHistoricalBadge => 'نسخهٔ پیشین';

  @override
  String get citationStatusVerifiedTooltip =>
      'از یک منبع حقوقی بازیابی‌شده نقل شده است.';

  @override
  String get citationStatusUnverifiedTooltip =>
      'هوش مصنوعی این متن را بدون بازیابی منبع نقل کرده است — پیش از اتکا، بازبینی کنید.';

  @override
  String get citationStatusHistoricalTooltip =>
      'حکم نقل‌شده دیگر لازم‌الاجرا نیست.';

  @override
  String get citationOpenInRiigiTeataja => 'گشودن در Riigi Teataja';

  @override
  String get citationSnippetExpand => 'نمایش متن کامل';

  @override
  String get citationSnippetCollapse => 'نمایش کمتر';

  @override
  String get citationUnverifiedSheetNote =>
      'هوش مصنوعی این بند را نقل کرد، اما در این گفت‌وگو از پیکرهٔ حقوقی بازیابی نشده است. پیش از اتکا، ارجاع را راستی‌آزمایی کنید.';

  @override
  String get citationFooterNoneWarning => 'هیچ ارجاع مستندی موجود نیست';

  @override
  String citationFooterSummaryTotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count نقل قول',
      one: '۱ نقل قول',
    );
    return '$_temp0';
  }

  @override
  String citationFooterSummaryVerified(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تأیید شده',
      one: '۱ تأیید شده',
    );
    return '$_temp0';
  }

  @override
  String citationFooterSummaryUnverified(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تأیید نشده',
      one: '۱ تأیید نشده',
    );
    return '$_temp0';
  }

  @override
  String citationFooterSummaryHistorical(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تاریخی',
      one: '۱ تاریخی',
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
      other: '$count روز دیگر',
      one: '۱ روز دیگر',
      zero: 'امروز',
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
      other: '$count روز تأخیر',
      one: '۱ روز تأخیر',
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
    return 'Consilium $count اقدام موازی را توصیه می‌کند';
  }

  @override
  String get parallelActionsApproveAll => 'تأیید همه و ارسال';

  @override
  String parallelActionsApproveSelected(int count, int total) {
    return 'تأیید $count از $total';
  }

  @override
  String parallelActionsConfirmTitle(int count) {
    return '$count ایمیل ارسال شود؟';
  }

  @override
  String parallelActionsConfirmBody(int count) {
    return 'Advocat $count پاسخ آماده‌شده را از طریق Gmail متصل شما ارسال می‌کند. هر یک مستقل ارسال می‌شود — اگر هرکدام ناموفق باشد، بقیه همچنان ارسال می‌شوند.';
  }

  @override
  String parallelActionsSentToast(int count) {
    return '$count ارسال شد.';
  }

  @override
  String parallelActionsPartialFailureToast(int sent, int failed) {
    return '$sent ارسال شد، $failed ناموفق.';
  }

  @override
  String get parallelActionsKindReply => 'پاسخ';

  @override
  String get parallelActionsKindNew => 'جدید';

  @override
  String get parallelActionsCheckboxSelected => 'اقدام انتخاب شد';

  @override
  String get parallelActionsCheckboxUnselected => 'اقدام انتخاب نشد';

  @override
  String parallelActionsCitationCount(int count) {
    return '$count استناد';
  }

  @override
  String parallelActionsRetryFailed(int count) {
    return 'تلاش مجدد برای ناموفق‌ها ($count)';
  }

  @override
  String get agentApprovalNeedsReviewTitle => 'Advocat به تأیید شما نیاز دارد';

  @override
  String get agentApprovalResolvedTitle => 'اقدام تعیین‌تکلیف شد';

  @override
  String get agentApprovalStepsLabel => 'گام';

  @override
  String get agentApprovalApproveButton => 'تأیید و ارسال';

  @override
  String get agentApprovalDeclineButton => 'رد کردن';

  @override
  String get agentApprovalAttachmentsLabel => 'پیوست‌ها';

  @override
  String get agentApprovalSentSummary => 'از طرف شما ارسال شد.';

  @override
  String get agentApprovalDeclinedSummary => 'رد شد — چیزی ارسال نشد.';

  @override
  String get agentToolDraftEmailAtt => 'ارسال ایمیل با پیوست';

  @override
  String get agentToolSendEmail => 'ارسال ایمیل';

  @override
  String get agentToolGeneratePdf => 'تولید PDF';

  @override
  String get agentToolApproveSend => 'ارسال پاسخ آماده‌شده';

  @override
  String get inboxErrorTitle => 'بارگذاری صندوق ورودی ممکن نشد';

  @override
  String get inboxEditDiscardTitle => 'تغییرات ذخیره‌نشده را نادیده بگیرم؟';

  @override
  String get inboxEditDiscardBody =>
      'تغییرات ذخیره‌نشده‌ای در این پیش‌نویس دارید. بازگشت آن‌ها را نادیده می‌گیرد.';

  @override
  String get inboxEditKeepEditing => 'ادامه ویرایش';

  @override
  String get inboxEditDiscard => 'نادیده گرفتن';

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
  String get plannerSettingsTitle => 'استدلال حقوقی سه‌مرحله‌ای';

  @override
  String get plannerSettingsSubtitle =>
      'برنامه‌ریزی ← پاسخ ← نقد. کندتر اما دقیق‌تر.';

  @override
  String get plannerSettingsProBadge => 'Pro';

  @override
  String get plannerSettingsProDescription => 'در طرح Pro در دسترس است';

  @override
  String get plannerTrailHeaderPlan => 'برنامه';

  @override
  String get plannerTrailHeaderCritique => 'نقد';

  @override
  String get plannerTrailSubQuestions => 'پرسش‌های فرعی';

  @override
  String get plannerTrailCounterArgs => 'استدلال‌های متقابل';

  @override
  String get plannerTrailEvidenceGaps => 'خلأهای شواهد';

  @override
  String get plannerTrailMaterialGapTrue => 'خلأ اساسی شناسایی شد';

  @override
  String get plannerTrailRegeneratedBadge => 'یک‌بار بازتولید شد';

  @override
  String get plannerTrailEmpty => 'موردی نیست';

  @override
  String get supportTitle => 'راهنما';

  @override
  String get supportSubtitle => 'معمولاً ظرف ۱ تا ۲ ساعت پاسخ می‌دهیم.';

  @override
  String get supportSearchPlaceholder => 'جستجوی راهنما…';

  @override
  String get supportStatusAllOk => 'همه سیستم‌ها عادی';

  @override
  String get supportFaqWhatIs => 'Advocat چیست؟';

  @override
  String get supportFaqHowSubscribe => 'چگونه در Pro مشترک شوم؟';

  @override
  String get supportFaqExportData => 'آیا می‌توانم داده‌هایم را خروجی بگیرم؟';

  @override
  String get supportFaqCancelAccount => 'لغو یا حذف حساب';

  @override
  String get supportFaqTalkHuman => 'گفتگو با یک انسان';

  @override
  String get supportContactEmail => 'ایمیل';

  @override
  String get supportContactTelegram => 'Telegram';

  @override
  String get supportContactWhatsapp => 'WhatsApp';

  @override
  String get supportFooterSla => 'ظرف ۲۴ ساعت پاسخ می‌دهیم';

  @override
  String get supportWhatsapp => 'WhatsApp';

  @override
  String get supportEmail => 'ایمیل';

  @override
  String get supportInApp => 'اینجا برای ما پیام بگذارید';

  @override
  String get supportCategoryLabel => 'دسته';

  @override
  String get supportCategoryBug => 'اشکال';

  @override
  String get supportCategoryPayment => 'مشکل پرداخت';

  @override
  String get supportCategoryQuestion => 'پرسش';

  @override
  String get supportCategoryFeature => 'درخواست قابلیت';

  @override
  String get supportCategoryOther => 'سایر';

  @override
  String get supportMessagePlaceholder => 'مشکل خود را شرح دهید...';

  @override
  String get supportEmailLabel => 'ایمیل (اختیاری)';

  @override
  String get supportSend => 'ارسال';

  @override
  String get supportSentSuccess => 'پیام ارسال شد! به‌زودی پاسخ می‌دهیم.';

  @override
  String get supportError => 'مشکلی پیش آمد. دوباره تلاش کنید.';

  @override
  String get supportErrorTooShort => 'لطفاً حداقل ۱۰ نویسه بنویسید.';

  @override
  String get supportErrorTooLong => 'حداکثر ۲۰۰۰ نویسه.';

  @override
  String get supportPrivacyNotice => 'پیام شما به‌صورت امن ذخیره می‌شود.';

  @override
  String get reviewThisContract => 'بررسی این قرارداد';

  @override
  String get contractReviews => 'Contract Reviews';

  @override
  String get contractReviewsFreeFeature => '1 contract review (lifetime trial)';

  @override
  String get contractReviewsCounselFeature => '5 contract reviews per month';

  @override
  String get contractReviewsProFeature => '20 contract reviews per month';

  @override
  String contractReviewsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count بررسی قرارداد این ماه باقی مانده',
      one: '۱ بررسی قرارداد این ماه باقی مانده',
      zero: 'این ماه بررسی قراردادی باقی نمانده',
    );
    return '$_temp0';
  }

  @override
  String get contractReviewsExhausted => 'No contract reviews left this month';

  @override
  String get contractReviewsFreeTrialLeft => 'Free trial: 1 contract review';

  @override
  String get contractReviewsFreeTrialUsed =>
      'Free trial used — upgrade for more';

  @override
  String get contractReviewsUpgradeTitle => 'Contract reviews used up';

  @override
  String get contractReviewsUpgradeBodyFree =>
      'You used your free contract review. Upgrade for monthly contract reviews.';

  @override
  String contractReviewsUpgradeBodyPaid(int used, int cap) {
    return 'You used $used of $cap reviews this month. Upgrade for a higher monthly cap.';
  }

  @override
  String get contractReviewsUpgradeCounselCta =>
      'Upgrade to Counsel (€19.99/mo) — 5 reviews';

  @override
  String get contractReviewsUpgradeProCta =>
      'Upgrade to Pro (€29.99/mo) — 20 reviews';

  @override
  String get contractReviewsUpgradeToProShort => 'Upgrade to Pro — 20/mo';

  @override
  String get notNow => 'Not now';

  @override
  String get referralTitle => 'دعوت از دوستان';

  @override
  String get referralSubtitle => 'یک ماه رایگان بگیر. یک ماه رایگان هدیه بده.';

  @override
  String get referralYourLink => 'لینک شما';

  @override
  String get referralCopyLink => 'کپی لینک';

  @override
  String get referralShare => 'اشتراک‌گذاری';

  @override
  String get referralLinkCopied => 'لینک کپی شد';

  @override
  String get referralStatsInvited => 'دعوت‌شده';

  @override
  String get referralStatsConverted => 'عضو شده';

  @override
  String get referralStatsEarned => 'ماه‌های رایگان';

  @override
  String get referralShareWhatsApp => 'اشتراک در واتساپ';

  @override
  String get referralShareTelegram => 'اشتراک در تلگرام';

  @override
  String get referralShareEmail => 'اشتراک با ایمیل';

  @override
  String get referralEmailSubject =>
      'Advocat را امتحان کن — دستیار حقوقی هوش مصنوعی تو';

  @override
  String get referralLoadError =>
      'بارگذاری اطلاعات ممکن نشد. برای تازه‌سازی بکشید.';

  @override
  String get referralRetry => 'تلاش دوباره';

  @override
  String get referralSettingsTile => 'دعوت از دوستان';

  @override
  String get referralAfterReviewCta =>
      'خوشت آمد؟ یک دوست را دعوت کن — هر دو یک ماه رایگان می‌گیرید.';

  @override
  String get referralAntiFraud => 'حداکثر ۱۲ معرفی موفق در سال.';

  @override
  String get referralEmpty =>
      'هنوز معرفی‌ای نیست. لینک خود را ارسال کنید تا کسب درآمد را آغاز کنید.';

  @override
  String get referralRecentActivity => 'فعالیت اخیر';

  @override
  String referralActivityInvited(String when) {
    return 'دعوت‌شده $when';
  }

  @override
  String referralActivityActivated(String when) {
    return 'فعال شد $when';
  }

  @override
  String get referralActivityPending => 'هنوز فعال نشده';

  @override
  String referralStatsInvitedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count دوست',
      one: '۱ دوست',
      zero: 'هنوز هیچ دوستی',
    );
    return 'شما $_temp0 دعوت کرده‌اید';
  }

  @override
  String referralStatsConvertedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count نفر فعال شده‌اند',
      one: '۱ نفر فعال شده',
      zero: 'هنوز هیچ‌کدام فعال نشده',
    );
    return '$_temp0';
  }

  @override
  String referralStatsEarnedCount(int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months ماه رایگان',
      one: '۱ ماه رایگان',
      zero: 'هنوز هیچ',
    );
    return 'پاداش شما: $_temp0';
  }

  @override
  String get referralNudgeMessage =>
      'از Advocat خوشتان آمد؟ یک دوست را دعوت کنید — هر دو یک ماه رایگان دریافت می‌کنید.';

  @override
  String get referralNudgeAction => 'دعوت';

  @override
  String get referralLandingTitle => 'شما به Advocat دعوت شده‌اید';

  @override
  String referralLandingSubtitle(String inviterName) {
    return '$inviterName شما را دعوت کرد — ماه اول رایگان خود را دریافت کنید.';
  }

  @override
  String get referralLandingSubtitleGeneric =>
      'ماه اول رایگان Advocat Pro خود را دریافت کنید.';

  @override
  String get referralLandingCta => 'فعال‌سازی ماه رایگان و ثبت‌نام';

  @override
  String get referralLandingCtaSecondary => 'یا درباره Advocat بیشتر بدانید';

  @override
  String get referralLandingFallback =>
      'این لینک منقضی شده است — اما همچنان می‌توانید Advocat را رایگان امتحان کنید.';

  @override
  String get referralLandingBenefits =>
      '۱۷ زبان • قانون واقعی استونی، فنلاند و اتحادیه اروپا • ۲۴/۷ — بدون انتظار';

  @override
  String get checkerProTagline => 'Professional verification tools';

  @override
  String get checkerDataSource => 'Data from official registries';

  @override
  String get companyCheckerHint => 'Company name or reg. number';

  @override
  String get companyCheckerPriceChip => '€2.99 per check  •  Included in Pro';

  @override
  String get companyCheckerEmptyState =>
      'Enter a company name or registration\nnumber to get a full report';

  @override
  String get aiMemoryTitle => 'AI memory';

  @override
  String get aiMemorySubtitle =>
      'Review and forget what the AI remembers about you';

  @override
  String get bookLawyerCallTitle => 'Book a lawyer call';

  @override
  String get bookLawyerCallComingSoonTitle =>
      'Human lawyer calls — opening soon';

  @override
  String get bookLawyerCallComingSoonBody =>
      'Pro and Premium include 15-minute calls with a partner lawyer (1/quarter on Pro, 2/quarter on Premium). We are finalising the EE solo-practitioner pool and will email you the moment booking opens.';

  @override
  String bookLawyerCallQuotaAvailable(int remaining, int total) {
    return 'You have $remaining of $total call(s) left this quarter.';
  }

  @override
  String get bookLawyerCallQuotaExhausted => 'Quarterly quota used.';

  @override
  String get bookLawyerCallQuotaBodyAvailable =>
      'Pro tier includes 1 call/quarter, Premium 2. Calls last 15 minutes, by Google Meet.';

  @override
  String get bookLawyerCallQuotaBodyExhausted =>
      'Your quota resets on the first day of next quarter. Need to talk sooner? Upgrade to Premium for an extra call.';

  @override
  String get severityCritical => 'CRITICAL';

  @override
  String get severityHigh => 'HIGH';

  @override
  String get severityMedium => 'MEDIUM';

  @override
  String get severityLow => 'LOW';

  @override
  String get deadlineRequiredFields => 'Title and deadline date are required';

  @override
  String get acceptTermsRequired => 'Please agree to the Terms of Service';

  @override
  String get chatLegalCouncilTooltip => 'Legal council (4 experts)';

  @override
  String get attachFileTooltip => 'Attach file';

  @override
  String get sendMessage => 'Send message';

  @override
  String get stopGenerating => 'Stop generating';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get decreaseDependents => 'Decrease';

  @override
  String get increaseDependents => 'Increase';

  @override
  String get sensitiveConsentTitle => 'رضایت برای داده‌های حساس';

  @override
  String get sensitiveConsentBody =>
      'اسنادی که قرار است بارگذاری کنید ممکن است حاوی داده‌های شخصی دسته‌های ویژه طبق ماده ۹ GDPR باشند — مانند سوابق پزشکی، سوابق کیفری، داده‌های زیست‌سنجی، یا اطلاعات مربوط به منشأ نژادی، مذهب یا گرایش جنسی شما.\n\nما این داده‌ها را تنها برای ارائه دستیار حقوقی هوش مصنوعی به شما پردازش می‌کنیم، آن‌ها را رمزگذاری‌شده در حساب خصوصی شما ذخیره می‌کنیم و هرگز از آن‌ها برای آموزش مدل‌ها استفاده نمی‌کنیم. می‌توانید هر زمان رضایت را پس بگیرید و داده‌ها را از بخش تنظیمات حذف کنید.\n\nبا پذیرفتن، شما طبق ماده ۹(۲)(الف) GDPR رضایت صریح خود را برای پردازش داده‌های دسته ویژه برای این منظور اعلام می‌کنید.';

  @override
  String get sensitiveConsentExplicitCheckbox =>
      'من رضایت صریح خود را برای پردازش داده‌های دسته ویژه اعلام می‌کنم (ماده ۹(۲)(الف) GDPR).';

  @override
  String get sensitiveConsentRightToShareCheckbox =>
      'تأیید می‌کنم که حق اشتراک‌گذاری این داده‌ها را دارم (داده‌ها از آن من است، یا مبنای قانونی/اطلاع‌رسانی برای اشتراک‌گذاری داده‌های شخص ثالث دارم).';

  @override
  String get sensitiveConsentViewCategories =>
      'ببینید چه چیزی حساس محسوب می‌شود ←';

  @override
  String get sensitiveConsentWithdrawAction =>
      'پس گرفتن رضایت برای داده‌های حساس';

  @override
  String get privacyAndData => 'حریم خصوصی و داده‌ها';

  @override
  String get exportMyDataSubtitle =>
      'یک نسخه از تمام داده‌های شخصی خود را دانلود کنید (ماده ۱۵ GDPR).';

  @override
  String get withdrawSensitiveConsent => 'رضایت برای داده‌های حساس';

  @override
  String get withdrawSensitiveConsentSubtitle =>
      'رضایت برای پردازش داده‌های دسته ویژه را مدیریت یا پس بگیرید (ماده ۹(۲)(الف) GDPR).';

  @override
  String get dataProcessingAgreement => 'قرارداد پردازش داده‌ها';

  @override
  String get exportingData => 'در حال خروجی گرفتن از داده‌های شما…';

  @override
  String get exportComplete =>
      'خروجی داده‌ها آماده است — در دستگاه شما ذخیره شد.';

  @override
  String get exportFailed =>
      'خروجی گرفتن ناموفق بود. لطفاً دوباره تلاش کنید یا با پشتیبانی تماس بگیرید.';

  @override
  String get quotaExhaustedTitle => 'محدودیت پیام رایگان به پایان رسید';

  @override
  String quotaExhaustedBody(int count) {
    return 'شما از تمام $count پیام رایگان استفاده کرده‌اید. به Advocat Counsel با ۱۹.۹۹ یورو در ماه ارتقا دهید و مشاوره‌های حقوقی نامحدود هوش مصنوعی دریافت کنید.';
  }

  @override
  String get quotaExhaustedLater => 'بعداً';

  @override
  String get quotaExhaustedUpgrade => 'Advocat Counsel — ۱۹.۹۹ یورو در ماه';

  @override
  String quotaCtaMessage(int count) {
    return 'شما از تمام $count پیام رایگان استفاده کرده‌اید. به Advocat Counsel با ۱۹.۹۹ یورو در ماه ارتقا دهید.';
  }

  @override
  String get quotaCtaButton => 'دریافت Advocat Counsel — ۱۹.۹۹ یورو در ماه';

  @override
  String get aiErrorQuota =>
      'محدودیت پیام رایگان به پایان رسید. برای ادامه استفاده از هوش مصنوعی مشترک شوید.';

  @override
  String get aiErrorAuth =>
      'برای استفاده از هوش مصنوعی ورود لازم است. لطفاً ثبت‌نام یا وارد شوید.';

  @override
  String get aiErrorGeneric =>
      'خطای موقت هوش مصنوعی. لطفاً یک دقیقه دیگر دوباره تلاش کنید. اگر ادامه یافت، با پشتیبانی تماس بگیرید.';

  @override
  String get tooltipShareCase => 'اشتراک‌گذاری خلاصه پرونده';

  @override
  String get tooltipMuteVoice => 'بی‌صدا کردن صدا';

  @override
  String get tooltipUnmuteVoice => 'باصدا کردن صدا';

  @override
  String get tooltipAttachDoc => 'پیوست سند';

  @override
  String get aiTypingHint => 'هوش مصنوعی…';

  @override
  String get error404Title => 'صفحه یافت نشد';

  @override
  String error404Body(String path) {
    return 'نتوانستیم این را پیدا کنیم: $path';
  }

  @override
  String get goToHome => 'رفتن به خانه';

  @override
  String get emailAlreadyRegistered =>
      'این ایمیل قبلاً ثبت شده است. می‌خواهید وارد شوید؟';

  @override
  String get actionSignIn => 'ورود';

  @override
  String get actionUndo => 'واگرد';

  @override
  String get intakeUrgentOpened => 'گفتگو باز شد — پیش‌نویس شما ذخیره شد.';

  @override
  String get panicCoachmark => 'برای کمک اضطراری نگه دارید.';

  @override
  String get panicTitle => 'همین حالا به چه چیزی نیاز دارید؟';

  @override
  String get panicCardReadAloud => 'برای مأمور با صدای بلند بخوانید';

  @override
  String get panicCardRecord => 'این گفتگو را ضبط کنید';

  @override
  String get panicCardCall => 'با یک وکیل تماس بگیرید';

  @override
  String get panicCardAi => 'همین حالا با Advocat صحبت کنید';

  @override
  String get panicClose => 'بستن';

  @override
  String get panicBadgeV2 => 'V2';

  @override
  String get panicRecordV1Title => 'در V2 می‌آید';

  @override
  String get panicRecordV1Body =>
      'قابلیت ضبط در حال اعتبارسنجی حقوقی برای استونی است و در V2 عرضه می‌شود. فعلاً از ضبط‌کننده صدای داخلی تلفن خود استفاده کنید.';

  @override
  String get panicCallFallbackBody =>
      'به kiire@advocat.ee یک توضیح کوتاه ایمیل کنید و ما با شما تماس می‌گیریم.';

  @override
  String get consiliumHeader => 'کنسولیوم وکلا';

  @override
  String consiliumProgress(int count, int total) {
    return '$count از $total آماده';
  }

  @override
  String get consiliumStarting => 'وکلا در حال بررسی پرونده شما هستند…';

  @override
  String get consiliumDisagreement => 'کارشناسان اختلاف نظر دارند';

  @override
  String get consiliumSynthesizing => 'در حال تدوین توصیه…';

  @override
  String consiliumDone(int totalRoles) {
    return 'کنسولیوم پایان یافت · $totalRoles کارشناس';
  }

  @override
  String get consiliumPositionPush => 'اعتراض کن';

  @override
  String get consiliumPositionSettle => 'سازش کن';

  @override
  String get consiliumPositionInvestigate => 'بررسی کن';

  @override
  String get consiliumPositionOutOfScope => 'خارج از صلاحیت';

  @override
  String get consiliumConfidence => 'اطمینان';

  @override
  String get consiliumKeyCitation => 'ارجاع کلیدی';

  @override
  String get consiliumAdversarialRound => 'دور تقابلی';

  @override
  String get consiliumViewFullOpinion => 'مشاهده نظر کامل';

  @override
  String consiliumExpertsAgreed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count کارشناس موافق',
      one: '۱ کارشناس موافق',
    );
    return '$_temp0';
  }

  @override
  String consiliumExpertsDisagree(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count کارشناس مخالف',
      one: '۱ کارشناس مخالف',
    );
    return '$_temp0';
  }

  @override
  String get consiliumDisclaimer =>
      'عامل‌های هوش مصنوعی، نه وکلای انسانی. تصمیمات مهم را با وکیل دارای پروانه بررسی کنید.';

  @override
  String get softCaseShellBanner =>
      'برای پیگیری این مورد «پرونده بدون عنوان» ایجاد کردیم. برای تغییر نام ضربه بزنید.';

  @override
  String get softCaseShellBannerCta => 'تغییر نام';

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
  String get iapPayWithApple => 'پرداخت با Apple';

  @override
  String get iapRestorePurchases => 'بازیابی خریدها';

  @override
  String get iapPurchaseFailed =>
      'خرید ناموفق بود. لطفاً دوباره تلاش کنید یا با پشتیبانی تماس بگیرید.';

  @override
  String get iapRestoreSuccess => 'اشتراک شما بازیابی شد.';

  @override
  String get iapRestoreNoActive => 'هیچ اشتراک فعالی برای بازیابی یافت نشد.';

  @override
  String get deadlineEuRadarTitle => 'EU deadline radar (preview)';

  @override
  String get deadlineEuRadarSubtitle =>
      'Hypothetical EU procedural deadlines — mock data';

  @override
  String get changePassword => 'تغییر رمز عبور';

  @override
  String get changePasswordSubtitle => 'رمز عبور حساب خود را به‌روزرسانی کنید';

  @override
  String get newPasswordTitle => 'تعیین رمز عبور جدید';

  @override
  String get newPasswordHint =>
      'رمز عبور جدیدی برای حساب خود وارد و تأیید کنید.';

  @override
  String get newPasswordSave => 'ذخیره رمز عبور جدید';

  @override
  String get newPasswordSuccess =>
      'رمز عبور به‌روزرسانی شد. اکنون می‌توانید با آن وارد شوید.';

  @override
  String get newPasswordError =>
      'به‌روزرسانی رمز عبور ناموفق بود. لطفاً دوباره تلاش کنید.';

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
