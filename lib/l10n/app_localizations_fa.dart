// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get appTitle => 'Advocat — ابزار اطلاعات حقوقی';

  @override
  String get onboardingTitle1 => 'اطلاعات حقوقی مبتنی بر هوش مصنوعی';

  @override
  String get onboardingDesc1 =>
      'Advocat به شما کمک می‌کند وضعیت حقوقی خود را درک کنید. ابزارهای هوش مصنوعی اسناد را تحلیل می‌کنند، مشکلات احتمالی را شناسایی می‌کنند و پیش‌نویس اسناد را برای بررسی شما آماده می‌کنند. این یک دفتر وکالت نیست — یک ابزار فناوری برای پشتیبانی از پرونده شماست.';

  @override
  String get onboardingTitle2 => 'اسکن و تحلیل اسناد';

  @override
  String get onboardingDesc2 =>
      'از هر سند حقوقی عکس بگیرید. هوش مصنوعی آن را به چندین زبان می‌خواند، داده‌های کلیدی را استخراج می‌کند و انطباق با دستورالعمل‌های اتحادیه اروپا و قوانین ملی را بررسی می‌کند.';

  @override
  String get onboardingTitle3 => 'هوش مصنوعی مشکلات احتمالی را بررسی می‌کند';

  @override
  String get onboardingDesc3 =>
      'ابزارهای هوش مصنوعی ما بیش از ۴۰ نوع الزامات آیین دادرسی را بررسی می‌کنند. تحلیل هوش مصنوعی ممکن است مشکلاتی را شناسایی کند که نیاز به توجه دارند — مانند زبان ابلاغ، مراحل دادرسی و مهلت‌های قانونی. همیشه با یک وکیل واجد شرایط بررسی کنید.';

  @override
  String get onboardingTitle4 => 'پیش‌نویس اسناد برای بررسی شما';

  @override
  String get onboardingDesc4 =>
      'هوش مصنوعی پیش‌نویس تجدیدنظر، شکایات و نامه‌ها را با ارجاعات حقوقی برای بررسی شما آماده می‌کند. شما تصمیم می‌گیرید چه چیزی ارسال شود. هر سند باید توسط یک متخصص حقوقی واجد شرایط پیش از تقدیم بررسی شود.';

  @override
  String get onboardingNext => 'بعدی';

  @override
  String get onboardingSkip => 'رد شدن';

  @override
  String get getStarted => 'شروع';

  @override
  String get welcomeBack => 'خوش آمدید';

  @override
  String get signInSubtitle => 'برای دسترسی به پرونده‌های خود وارد شوید';

  @override
  String get signIn => 'ورود';

  @override
  String get logIn => 'ورود';

  @override
  String get signUp => 'ایجاد حساب';

  @override
  String get createAccount => 'ایجاد حساب';

  @override
  String get email => 'ایمیل';

  @override
  String get password => 'رمز عبور';

  @override
  String get confirmPassword => 'تأیید رمز عبور';

  @override
  String get fullName => 'نام کامل';

  @override
  String get forgotPassword => 'رمز عبور را فراموش کرده‌اید؟';

  @override
  String get orDivider => 'یا';

  @override
  String get continueWithGoogle => 'ادامه با Google';

  @override
  String get noAccount => 'حساب ندارید؟ ';

  @override
  String get signUpLink => 'ثبت‌نام';

  @override
  String get alreadyHaveAccount => 'قبلاً حساب دارید؟ ';

  @override
  String get signInLink => 'ورود';

  @override
  String get emailRequired => 'ایمیل الزامی است';

  @override
  String get emailInvalid => 'لطفاً یک آدرس ایمیل معتبر وارد کنید';

  @override
  String get passwordRequired => 'رمز عبور الزامی است';

  @override
  String get passwordTooShort => 'رمز عبور باید حداقل ۸ کاراکتر باشد';

  @override
  String get passwordsDoNotMatch => 'رمزهای عبور مطابقت ندارند';

  @override
  String get nameRequired => 'نام کامل الزامی است';

  @override
  String get termsRequired => 'باید شرایط خدمات را بپذیرید';

  @override
  String get agreeToTerms => 'موافقم با ';

  @override
  String get termsOfService => 'شرایط خدمات';

  @override
  String get andWord => ' و ';

  @override
  String get privacyPolicy => 'سیاست حفظ حریم خصوصی';

  @override
  String get preferredLanguage => 'زبان ترجیحی';

  @override
  String get langEnglish => 'انگلیسی';

  @override
  String get langRussian => 'روسی';

  @override
  String get langFinnish => 'فنلاندی';

  @override
  String get passwordStrengthWeak => 'ضعیف';

  @override
  String get passwordStrengthMedium => 'متوسط';

  @override
  String get passwordStrengthStrong => 'قوی';

  @override
  String get loginFailed =>
      'ایمیل یا رمز عبور نامعتبر است. لطفاً دوباره تلاش کنید.';

  @override
  String get registerFailed => 'ثبت‌نام ناموفق بود. لطفاً دوباره تلاش کنید.';

  @override
  String get resetPasswordSent =>
      'لینک بازنشانی رمز عبور به ایمیل شما ارسال شد.';

  @override
  String get resetPasswordFailed =>
      'ارسال لینک ناموفق بود. لطفاً دوباره تلاش کنید.';

  @override
  String get myCases => 'پرونده‌های من';

  @override
  String get newCase => 'پرونده جدید';

  @override
  String get noCases => 'هنوز پرونده‌ای نیست';

  @override
  String get documents => 'اسناد';

  @override
  String get timeline => 'جدول زمانی';

  @override
  String get aiAssistant => 'دستیار حقوقی هوش مصنوعی';

  @override
  String get settings => 'تنظیمات';

  @override
  String get language => 'زبان';

  @override
  String get subscription => 'اشتراک';

  @override
  String get signOut => 'خروج';

  @override
  String get disclaimer =>
      'فقط راهنمایی هوش مصنوعی — مشاوره حقوقی نیست. همیشه با وکیل مشورت کنید.';

  @override
  String get scanDocument => 'اسکن سند';

  @override
  String get camera => 'دوربین';

  @override
  String get gallery => 'گالری';

  @override
  String get saveAndAnalyze => 'ذخیره و تحلیل';

  @override
  String get retry => 'تلاش مجدد';

  @override
  String get cancel => 'لغو';

  @override
  String get confirm => 'تأیید';

  @override
  String get error => 'خطا';

  @override
  String get loading => 'در حال بارگذاری...';

  @override
  String get home => 'خانه';

  @override
  String get cases => 'پرونده‌ها';

  @override
  String get deadlines => 'مهلت‌ها';

  @override
  String get scan => 'اسکن';

  @override
  String goodMorning(String name) {
    return 'صبح بخیر، $name';
  }

  @override
  String goodAfternoon(String name) {
    return 'عصر بخیر، $name';
  }

  @override
  String goodEvening(String name) {
    return 'شب بخیر، $name';
  }

  @override
  String get caseOverview => 'خلاصه پرونده‌های شما';

  @override
  String get activeCases => 'پرونده‌های فعال';

  @override
  String get recentActivity => 'فعالیت اخیر';

  @override
  String urgentDeadline(String title) {
    return 'فوری: $title';
  }

  @override
  String daysRemaining(int count) {
    return '$count روز';
  }

  @override
  String get overdue => 'عقب افتاده';

  @override
  String get upcoming => 'آینده';

  @override
  String get completed => 'تکمیل شده';

  @override
  String get markComplete => 'علامت‌گذاری به عنوان تکمیل شده';

  @override
  String get deportation => 'اخراج';

  @override
  String get criminalCase => 'پرونده کیفری';

  @override
  String get asylum => 'پناهندگی';

  @override
  String get residencePermit => 'اجازه اقامت';

  @override
  String get victimSupport => 'حمایت از قربانیان';

  @override
  String get familyReunification => 'پیوستن خانواده';

  @override
  String get laborDispute => 'اختلاف کارگری';

  @override
  String get tenantRights => 'حقوق مستأجر';

  @override
  String get debtCollection => 'وصول مطالبات';

  @override
  String get discrimination => 'تبعیض';

  @override
  String get policeMisconduct => 'سوءرفتار پلیس';

  @override
  String get socialBenefits => 'مزایای اجتماعی';

  @override
  String get other => 'سایر';

  @override
  String get caseDetail => 'جزئیات پرونده';

  @override
  String get aiAnalysis => 'تحلیل هوش مصنوعی';

  @override
  String get draftAppeal => 'پیش‌نویس تجدیدنظر';

  @override
  String get aiChat => 'گفتگوی هوش مصنوعی';

  @override
  String get correspondence => 'مکاتبات';

  @override
  String get analyzing => 'در حال تحلیل...';

  @override
  String get readingDocument => 'در حال خواندن سند...';

  @override
  String get checkingErrors => 'بررسی خطاها...';

  @override
  String get researchingLaw => 'تحقیق قانون قابل اعمال...';

  @override
  String issuesFound(int count) {
    return '$count مشکل یافت شد';
  }

  @override
  String get critical => 'بحرانی';

  @override
  String get important => 'مهم';

  @override
  String get informational => 'اطلاع‌رسانی';

  @override
  String get useInAppeal => 'استفاده در تجدیدنظر';

  @override
  String get addedToAppeal => 'به تجدیدنظر اضافه شد';

  @override
  String get generateAppeal => 'تولید تجدیدنظر';

  @override
  String get exportPdf => 'خروجی PDF';

  @override
  String get sendViaEmail => 'ارسال از طریق ایمیل';

  @override
  String get copyText => 'کپی متن';

  @override
  String get editDraft => 'ویرایش';

  @override
  String get saveDraft => 'ذخیره';

  @override
  String get reviewWarning =>
      'قبل از ارسال با دقت بررسی کنید. شما مسئول محتوا هستید.';

  @override
  String get disclaimerFull =>
      'این یک دستیار هوش مصنوعی است، نه وکیل. تحلیل هوش مصنوعی ممکن است حاوی خطا باشد. همیشه با یک متخصص حقوقی واجد شرایط بررسی کنید.';

  @override
  String get askAboutCase => 'تحلیل پرونده من';

  @override
  String get whatAreMyOptions => 'گزینه‌های من چیست؟';

  @override
  String get checkDeadlines => 'بررسی مهلت‌ها';

  @override
  String get typeMessage => 'پیام بنویسید...';

  @override
  String get connectEmail => 'اتصال ایمیل';

  @override
  String get connectGmail => 'اتصال Gmail';

  @override
  String get connectOutlook => 'اتصال Outlook';

  @override
  String get emailConnected => 'ایمیل متصل شد';

  @override
  String get syncNow => 'همگام‌سازی اکنون';

  @override
  String get disconnect => 'قطع اتصال';

  @override
  String get emailPrivacyNote =>
      'ما فقط ایمیل‌های مربوط به مسائل حقوقی را می‌خوانیم. ایمیل‌های شخصی شما خصوصی می‌مانند.';

  @override
  String get pushNotifications => 'اعلان‌های فشاری';

  @override
  String get deadlineReminders => 'یادآوری مهلت‌ها';

  @override
  String get deadlineRemindersDesc => 'قبل از مهلت‌ها اعلان دریافت کنید';

  @override
  String get editProfile => 'ویرایش پروفایل';

  @override
  String get exportMyData => 'خروجی داده‌های من';

  @override
  String get exportDataDesc => 'دانلود تمام داده‌های پرونده';

  @override
  String get deleteAccount => 'حذف حساب';

  @override
  String get deleteAccountDesc => 'حذف دائمی حساب شما';

  @override
  String get deleteConfirm =>
      'آیا مطمئن هستید؟ تمام داده‌های شما برای همیشه حذف خواهد شد.';

  @override
  String get about => 'درباره';

  @override
  String get version => 'نسخه';

  @override
  String get rateUs => 'به ما امتیاز دهید';

  @override
  String get contactSupport => 'تماس با پشتیبانی';

  @override
  String get tryDemoMode => 'حالت آزمایشی را امتحان کنید';

  @override
  String get demoModeDesc =>
      'برنامه را با داده‌های نمونه از یک پرونده واقعی کاوش کنید';

  @override
  String get free => 'رایگان';

  @override
  String get basic => 'پایه';

  @override
  String get pro => 'حرفه‌ای';

  @override
  String get emergencyShield => 'سپر اضطراری';

  @override
  String get legalFighter => 'مبارز حقوقی';

  @override
  String get fullDefense => 'دفاع کامل';

  @override
  String get popular => 'محبوب';

  @override
  String get currentPlan => 'طرح فعلی';

  @override
  String get choosePlan => 'انتخاب طرح';

  @override
  String get saveWithAnnual => '۲۵٪ با پرداخت سالانه صرفه‌جویی کنید';

  @override
  String get restorePurchases => 'بازیابی خریدها';

  @override
  String get country => 'کشور';

  @override
  String get caseDescription => 'وضعیت خود را توضیح دهید';

  @override
  String get caseTitle => 'عنوان پرونده';

  @override
  String get referenceNumber => 'شماره مرجع';

  @override
  String get uploadDocument => 'بارگذاری سند';

  @override
  String get optional => '(اختیاری)';

  @override
  String step(int current, int total) {
    return 'مرحله $current از $total';
  }

  @override
  String get next => 'بعدی';

  @override
  String get back => 'قبلی';

  @override
  String get createCase => 'ایجاد پرونده';

  @override
  String get searchCases => 'جستجوی پرونده‌ها...';

  @override
  String get all => 'همه';

  @override
  String get active => 'فعال';

  @override
  String get closed => 'بسته شده';

  @override
  String lastActivity(String time) {
    return 'آخرین فعالیت: $time';
  }

  @override
  String documentsCount(int count) {
    return '$count سند';
  }

  @override
  String get noCasesYet => 'هنوز پرونده‌ای نیست';

  @override
  String get startFirstCase => 'اولین پرونده خود را شروع کنید';

  @override
  String get noDeadlines => 'مهلتی نیست — همه چیز مرتب است!';

  @override
  String get appealFiled => 'تجدیدنظر ثبت شد';

  @override
  String get pendingDecision => 'در انتظار تصمیم';

  @override
  String get inProgress => 'در حال انجام';

  @override
  String get won => 'برنده';

  @override
  String get lost => 'بازنده';

  @override
  String get preferences => 'ترجیحات';

  @override
  String get notifications => 'اعلان‌ها';

  @override
  String get emailIntegration => 'یکپارچه‌سازی ایمیل';

  @override
  String get dataAndPrivacy => 'داده‌ها و حریم خصوصی';

  @override
  String get legalSection => 'حقوقی';

  @override
  String get aboutSection => 'درباره';

  @override
  String get appVersion => 'نسخه برنامه';

  @override
  String get selectLanguage => 'انتخاب زبان';

  @override
  String get signOutConfirm => 'آیا مطمئن هستید که می‌خواهید خارج شوید؟';

  @override
  String get emailDisconnected => 'ایمیل قطع شد';

  @override
  String get syncLegalCorrespondence => 'همگام‌سازی مکاتبات حقوقی';

  @override
  String get requestExport => 'درخواست خروجی';

  @override
  String get exportDataDialogContent =>
      'ما یک فایل دانلود از تمام داده‌های شما شامل پرونده‌ها، اسناد و مکاتبات آماده می‌کنیم. وقتی آماده شد ایمیلی دریافت خواهید کرد.';

  @override
  String get deleteAccountDialogContent =>
      'این عمل دائمی و غیرقابل بازگشت است. تمام داده‌ها، پرونده‌ها و اسناد شما برای همیشه حذف خواهد شد.';

  @override
  String get areYouAbsolutelySure => 'آیا کاملاً مطمئن هستید؟';

  @override
  String get typeDeleteToConfirm =>
      'برای تأیید حذف دائمی حساب، DELETE را تایپ کنید.';

  @override
  String get permanentlyDelete => 'حذف دائمی';

  @override
  String get dataExportRequested =>
      'خروجی داده‌ها درخواست شد. ایمیل خود را بررسی کنید.';

  @override
  String get connected => 'متصل';

  @override
  String get caseUpdated => 'پرونده به‌روز شد';

  @override
  String get noRecentActivity => 'فعالیت اخیری نیست';

  @override
  String get couldNotLoadCases => 'بارگذاری پرونده‌ها ممکن نشد';

  @override
  String get viewAll => 'مشاهده همه';

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
