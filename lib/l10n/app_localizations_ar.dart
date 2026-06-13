// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get about => 'حول التطبيق';

  @override
  String get aboutSection => 'حول';

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
  String get accidents => 'حوادث';

  @override
  String get active => 'نشطة';

  @override
  String get activeCases => 'القضايا النشطة';

  @override
  String get addedToAppeal => 'تمت الإضافة إلى الاستئناف';

  @override
  String get agreeToTerms => 'أوافق على ';

  @override
  String get aiAnalysis => 'تحليل الذكاء الاصطناعي';

  @override
  String get aiAssistant => 'المساعد القانوني الذكي';

  @override
  String get aiChat => 'محادثة مع الذكاء الاصطناعي';

  @override
  String get all => 'الكل';

  @override
  String get alreadyHaveAccount => 'لديك حساب بالفعل؟ ';

  @override
  String get analyzing => 'جارٍ التحليل…';

  @override
  String get aiAnalyzing => 'يقوم الذكاء الاصطناعي بالتحليل';

  @override
  String get speakIntoMicHint =>
      'تحدّث في الميكروفون. تأكد من تفعيل الوصول إلى الميكروفون.';

  @override
  String get aiErrorRateLimit =>
      'الخدمة مثقلة مؤقتًا. يرجى المحاولة مرة أخرى خلال دقيقة إلى دقيقتين.';

  @override
  String get aiErrorOverload =>
      'الذكاء الاصطناعي مشغول الآن، يرجى المحاولة مرة أخرى بعد دقيقة.';

  @override
  String freeLimitReached(int count) {
    return 'لقد استخدمت جميع رسائل الذكاء الاصطناعي المجانية الـ$count. قم بالترقية إلى المستشار القانوني للحصول على مساعدة غير محدودة بالذكاء الاصطناعي!';
  }

  @override
  String get andWord => ' و';

  @override
  String get appTitle => 'Advocat — أداة معلومات قانونية';

  @override
  String get appVersion => 'إصدار التطبيق';

  @override
  String get appealFiled => 'تم تقديم الاستئناف';

  @override
  String get areYouAbsolutelySure => 'هل أنت متأكد تماماً؟';

  @override
  String get askAboutCase => 'اسأل عن قضيتك';

  @override
  String get asylum => 'لجوء';

  @override
  String get back => 'رجوع';

  @override
  String get basic => 'أساسي';

  @override
  String get beforeYouBuy => 'قبل الشراء';

  @override
  String get beforeYouWork => 'قبل التعامل معهم';

  @override
  String get camera => 'الكاميرا';

  @override
  String get cancel => 'إلغاء';

  @override
  String get caseDescription => 'وصف القضية';

  @override
  String get caseDetail => 'تفاصيل القضية';

  @override
  String get caseOverview => 'نظرة عامة على القضايا';

  @override
  String get caseTitle => 'عنوان القضية';

  @override
  String get caseUpdated => 'تم تحديث القضية';

  @override
  String get cases => 'القضايا';

  @override
  String get checkCompany => 'تحقق من الشركة';

  @override
  String get checkDeadlines => 'تحقق من المواعيد النهائية';

  @override
  String get checkVehicle => 'تحقق من المركبة';

  @override
  String get checkerTitle => 'المدقق';

  @override
  String get checkingErrors => 'جارٍ التحقق من الأخطاء…';

  @override
  String get choosePlan => 'اختر خطتك';

  @override
  String get closed => 'مغلقة';

  @override
  String get companyName => 'اسم الشركة أو رقم التسجيل';

  @override
  String get completed => 'مكتمل';

  @override
  String get confirm => 'تأكيد';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get connectEmail => 'ربط البريد الإلكتروني';

  @override
  String get connectGmail => 'ربط Gmail';

  @override
  String get connectOutlook => 'ربط Outlook';

  @override
  String get connected => 'متصل';

  @override
  String get contactSupport => 'تواصل مع الدعم';

  @override
  String get continueWithGoogle => 'المتابعة باستخدام جوجل';

  @override
  String get appleComingSoon => 'قريبًا';

  @override
  String get appleComingSoonMessage =>
      'سيتوفر تسجيل الدخول عبر Apple قريبًا. استخدم Google أو البريد الإلكتروني للمتابعة.';

  @override
  String get copyText => 'نسخ النص';

  @override
  String get correspondence => 'المراسلات';

  @override
  String get couldNotLoadCases => 'تعذر تحميل قضاياك';

  @override
  String get country => 'البلد';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get createCase => 'إنشاء قضية';

  @override
  String get criminalCase => 'قضية جنائية';

  @override
  String get critical => 'حرج';

  @override
  String get currentPlan => 'خطتك الحالية';

  @override
  String get dataAndPrivacy => 'البيانات والخصوصية';

  @override
  String get dataExportRequested =>
      'تم طلب تصدير البيانات. تحقق من بريدك الإلكتروني.';

  @override
  String daysRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أيام',
      one: 'يوم واحد',
      zero: 'لا توجد أيام متبقية',
    );
    return '$_temp0';
  }

  @override
  String get deadlineReminders => 'تذكيرات المواعيد النهائية';

  @override
  String get deadlineRemindersDesc =>
      'تلقي إشعارات قبل المواعيد النهائية المهمة';

  @override
  String get deadlines => 'المواعيد النهائية';

  @override
  String get debtCollection => 'تحصيل الديون';

  @override
  String get deleteAccount => 'حذف الحساب';

  @override
  String get deleteAccountDesc => 'حذف حسابك وجميع بياناتك نهائياً';

  @override
  String get deleteAccountDialogContent =>
      'هذا الإجراء دائم ولا يمكن التراجع عنه. سيتم حذف جميع بياناتك وقضاياك ومستنداتك نهائياً.';

  @override
  String get deleteConfirm =>
      'هل أنت متأكد؟ لا يمكن التراجع عن هذا الإجراء. سيتم حذف جميع قضاياك ومستنداتك بشكل دائم.';

  @override
  String get demoHint => 'تجريبي: جرب اللوحة «908FBT»';

  @override
  String get demoModeDesc => 'استكشف التطبيق بقضية تجريبية دون إنشاء حساب';

  @override
  String get deportation => 'ترحيل';

  @override
  String get disclaimer =>
      'إرشادات ذكاء اصطناعي فقط — وليست استشارة قانونية. استشر محامياً دائماً.';

  @override
  String get disclaimerFull =>
      'هذا المستند أُنشئ بمساعدة الذكاء الاصطناعي للإرشاد فقط، ولا يُعدّ استشارة قانونية. يرجى مراجعة محامٍ مختص قبل تقديم أي طعن أو استئناف.';

  @override
  String get disconnect => 'إلغاء الربط';

  @override
  String get discrimination => 'تمييز';

  @override
  String get doNotBuy => 'لا تشتري';

  @override
  String get documents => 'المستندات';

  @override
  String documentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مستندات',
      one: 'مستند واحد',
      zero: 'لا توجد مستندات',
    );
    return '$_temp0';
  }

  @override
  String get draftAppeal => 'مسودة الاستئناف';

  @override
  String get editDraft => 'تعديل المسودة';

  @override
  String get editProfile => 'تعديل الملف الشخصي';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get emailConnected => 'البريد الإلكتروني مرتبط';

  @override
  String get emailDisconnected => 'تم إلغاء ربط البريد الإلكتروني';

  @override
  String get emailIntegration => 'تكامل البريد الإلكتروني';

  @override
  String get emailInvalid => 'يرجى إدخال بريد إلكتروني صالح';

  @override
  String get emailPrivacyNote =>
      'نقرأ فقط الرسائل المتعلقة بقضيتك القانونية. بياناتك محمية ومشفرة.';

  @override
  String get emailRequired => 'البريد الإلكتروني مطلوب';

  @override
  String get emergencyShield => 'درع الطوارئ';

  @override
  String get error => 'خطأ';

  @override
  String get exportDataDesc => 'تحميل جميع بياناتك ومستنداتك';

  @override
  String get exportDataDialogContent =>
      'سنقوم بإعداد تنزيل لجميع بياناتك بما في ذلك القضايا والمستندات والمراسلات. ستتلقى بريداً إلكترونياً عندما يكون جاهزاً.';

  @override
  String get exportMyData => 'تصدير بياناتي';

  @override
  String get exportPdf => 'تصدير PDF';

  @override
  String get familyReunification => 'لمّ شمل الأسرة';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get free => 'مجاني';

  @override
  String get fullDefense => 'Advocat Pro';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get gallery => 'المعرض';

  @override
  String get generateAppeal => 'إنشاء الاستئناف';

  @override
  String get getStarted => 'ابدأ الآن';

  @override
  String goodAfternoon(String name) {
    return 'مساء الخير، $name';
  }

  @override
  String goodEvening(String name) {
    return 'مساء الخير، $name';
  }

  @override
  String goodMorning(String name) {
    return 'صباح الخير، $name';
  }

  @override
  String goodNight(String name) {
    return 'تصبح على خير، $name';
  }

  @override
  String get home => 'الرئيسية';

  @override
  String get important => 'مهم';

  @override
  String get inProgress => 'قيد المعالجة';

  @override
  String get informational => 'معلوماتي';

  @override
  String get inspection => 'الفحص الفني';

  @override
  String get insurance => 'التأمين';

  @override
  String issuesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم العثور على $count مشاكل',
      one: 'تم العثور على مشكلة واحدة',
      zero: 'لم يتم العثور على مشاكل',
    );
    return '$_temp0';
  }

  @override
  String get laborDispute => 'نزاع عمالي';

  @override
  String get langEnglish => 'الإنجليزية';

  @override
  String get langFinnish => 'الفنلندية';

  @override
  String get langRussian => 'الروسية';

  @override
  String get language => 'اللغة';

  @override
  String lastActivity(String time) {
    return 'آخر نشاط: $time';
  }

  @override
  String get legalFighter => 'المدافع القانوني';

  @override
  String get legalSection => 'القانوني';

  @override
  String get licensePlate => 'لوحة الترخيص';

  @override
  String get loading => 'جارٍ التحميل…';

  @override
  String get logIn => 'الدخول';

  @override
  String get loginFailed =>
      'البريد الإلكتروني أو كلمة المرور غير صحيحة. يرجى المحاولة مرة أخرى.';

  @override
  String get lost => 'خسارة';

  @override
  String get markComplete => 'وضع علامة مكتمل';

  @override
  String get mileage => 'المسافة المقطوعة';

  @override
  String get myCases => 'قضاياي';

  @override
  String get nameRequired => 'الاسم الكامل مطلوب';

  @override
  String get newCase => 'قضية جديدة';

  @override
  String get next => 'التالي';

  @override
  String get noAccount => 'ليس لديك حساب؟ ';

  @override
  String get noCases => 'لا توجد قضايا بعد';

  @override
  String get noCasesYet => 'لا توجد قضايا بعد';

  @override
  String get noDeadlines => 'لا توجد مواعيد نهائية';

  @override
  String get noRecentActivity => 'لا يوجد نشاط حديث';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get onboardingDesc1 =>
      'يساعدك Advocat على فهم وضعك القانوني. أدوات الذكاء الاصطناعي تحلل المستندات، وتحدد المشكلات المحتملة، وتُعدّ مسودات مستندات لمراجعتك. ليس مكتب محاماة — بل أداة تقنية لدعم قضيتك.';

  @override
  String get onboardingDesc2 =>
      'صوّر أي مستند قانوني. يقرأه الذكاء الاصطناعي بعدة لغات، ويستخرج التفاصيل الرئيسية، ويتحقق من التوجيهات الأوروبية والقوانين الوطنية بحثاً عن مشكلات محتملة.';

  @override
  String get onboardingDesc3 =>
      'تتحقق أدوات الذكاء الاصطناعي لدينا من أكثر من 40 نوعاً من المتطلبات الإجرائية. قد يحدد تحليل الذكاء الاصطناعي مسائل تتطلب الانتباه — مثل لغة التبليغ، والخطوات الإجرائية، والمواعيد القانونية. تحقق دائماً مع محامٍ مؤهل.';

  @override
  String get onboardingDesc4 =>
      'يُعدّ الذكاء الاصطناعي مسودات طعون وشكاوى ورسائل مع مراجع قانونية لمراجعتك. أنت تقرر ما يتم تقديمه. يجب مراجعة كل مستند من قبل متخصص قانوني مؤهل قبل التقديم.';

  @override
  String get onboardingNext => 'التالي';

  @override
  String get onboardingSkip => 'تخطي';

  @override
  String get onboardingTitle1 => 'معلومات قانونية مدعومة بالذكاء الاصطناعي';

  @override
  String get onboardingTitle2 => 'امسح المستندات وحلّلها';

  @override
  String get onboardingTitle3 => 'الذكاء الاصطناعي يتحقق من المشكلات المحتملة';

  @override
  String get onboardingTitle4 => 'مسودات مستندات لمراجعتك';

  @override
  String get openACase => 'افتح قضية';

  @override
  String get optional => 'اختياري';

  @override
  String get orDivider => 'أو';

  @override
  String get other => 'أخرى';

  @override
  String get overdue => 'متأخر';

  @override
  String get owners => 'المالكون السابقون';

  @override
  String get password => 'كلمة المرور';

  @override
  String get passwordRequired => 'كلمة المرور مطلوبة';

  @override
  String get passwordStrengthMedium => 'متوسطة';

  @override
  String get passwordStrengthStrong => 'قوية';

  @override
  String get passwordStrengthWeak => 'ضعيفة';

  @override
  String get passwordTooShort => 'يجب أن تكون كلمة المرور ٨ أحرف على الأقل';

  @override
  String get passwordsDoNotMatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get pendingDecision => 'بانتظار القرار';

  @override
  String get perCheck => 'لكل فحص';

  @override
  String get permanentlyDelete => 'حذف نهائي';

  @override
  String get policeMisconduct => 'سوء سلوك الشرطة';

  @override
  String get popular => 'الأكثر طلباً';

  @override
  String get preferences => 'التفضيلات';

  @override
  String get preferredLanguage => 'اللغة المفضلة';

  @override
  String get pricePerCheck => '٤٫٩٩€ لكل فحص';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get dpaTitle => 'اتفاقية معالجة البيانات';

  @override
  String get dpaCheckoutGateTitle => 'قبل الترقية';

  @override
  String get dpaCheckoutGateBody =>
      'يُلزمنا قانون الاتحاد الأوروبي (المادة 28 من GDPR) بتوقيع اتفاقية معالجة بيانات مع كل عميل يدفع. يرجى المراجعة والقبول.';

  @override
  String get dpaViewLink => 'عرض اتفاقية معالجة البيانات';

  @override
  String get dpaCheckboxLabel =>
      'لقد قرأت اتفاقية معالجة البيانات (الإصدار 1.0) وأوافق عليها.';

  @override
  String get dpaCancel => 'إلغاء';

  @override
  String get dpaAcceptAndContinue => 'قبول ومتابعة';

  @override
  String get dpaOpenHint =>
      'افتح اتفاقية معالجة البيانات مرة واحدة على الأقل لتفعيل زر القبول.';

  @override
  String get pro => 'احترافي';

  @override
  String get pushNotifications => 'الإشعارات الفورية';

  @override
  String get rateUs => 'قيّمنا';

  @override
  String get rateAppComingSoon => 'قريبًا في متاجر التطبيقات!';

  @override
  String get dataCopiedToClipboard => 'تم نسخ البيانات إلى الحافظة';

  @override
  String get readingDocument => 'جارٍ قراءة المستند…';

  @override
  String get recentActivity => 'النشاط الأخير';

  @override
  String get referenceNumber => 'الرقم المرجعي';

  @override
  String get registerFailed => 'فشل إنشاء الحساب. يرجى المحاولة مرة أخرى.';

  @override
  String get reportFraud => 'الإبلاغ عن احتيال';

  @override
  String get requestExport => 'طلب التصدير';

  @override
  String get researchingLaw => 'جارٍ البحث في القانون…';

  @override
  String get resetPasswordFailed =>
      'فشل إرسال رابط إعادة التعيين. يرجى المحاولة مرة أخرى.';

  @override
  String get resetPasswordSent =>
      'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني.';

  @override
  String get residencePermit => 'تصريح إقامة';

  @override
  String get manageSubscription => 'إدارة الاشتراك';

  @override
  String get restorePurchases => 'استعادة المشتريات';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get reviewWarning => 'تحذير: راجع المسودة بعناية قبل التقديم';

  @override
  String get riskHigh => 'خطر عالي — تجنب';

  @override
  String get riskLow => 'آمن للتعامل';

  @override
  String get riskMedium => 'تابع بحذر';

  @override
  String get safeToBuy => 'آمن للشراء';

  @override
  String get saveAndAnalyze => 'حفظ وتحليل';

  @override
  String get saveDraft => 'حفظ المسودة';

  @override
  String get saveWithAnnual => 'وفّر مع الاشتراك السنوي';

  @override
  String get scan => 'مسح ضوئي';

  @override
  String get scanDocument => 'مسح مستند ضوئياً';

  @override
  String get searchCases => 'البحث في القضايا';

  @override
  String get selectCountry => 'اختر الدولة';

  @override
  String get selectLanguage => 'اختر اللغة';

  @override
  String get sendViaEmail => 'إرسال عبر البريد الإلكتروني';

  @override
  String get settings => 'الإعدادات';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signInLink => 'تسجيل الدخول';

  @override
  String get signInSubtitle => 'سجّل الدخول للوصول إلى قضاياك';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get signOutConfirm => 'هل أنت متأكد أنك تريد تسجيل الخروج؟';

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String get signUpLink => 'إنشاء حساب';

  @override
  String get socialBenefits => 'المزايا الاجتماعية';

  @override
  String get someConcerns => 'بعض المخاوف';

  @override
  String get startFirstCase => 'ابدأ بإنشاء قضيتك الأولى';

  @override
  String step(int current, int total) {
    return 'الخطوة $current من $total';
  }

  @override
  String get stolen => 'فحص السرقة';

  @override
  String get subscription => 'الاشتراك';

  @override
  String get syncLegalCorrespondence => 'مزامنة المراسلات القانونية';

  @override
  String get syncNow => 'مزامنة الآن';

  @override
  String get tenantRights => 'حقوق المستأجر';

  @override
  String get termsOfService => 'شروط الخدمة';

  @override
  String get termsRequired => 'يجب الموافقة على شروط الخدمة';

  @override
  String get timeline => 'الجدول الزمني';

  @override
  String get tryDemoMode => 'تجربة الوضع التجريبي';

  @override
  String get typeDeleteToConfirm => 'اكتب DELETE لتأكيد حذف الحساب نهائياً.';

  @override
  String get typeMessage => 'اكتب رسالتك…';

  @override
  String get upcoming => 'قادم';

  @override
  String get uploadDocument => 'رفع مستند';

  @override
  String urgentDeadline(String title) {
    return 'عاجل: $title';
  }

  @override
  String get useInAppeal => 'استخدام في الاستئناف';

  @override
  String get vehicleChecker => 'فاحص المركبات';

  @override
  String get vehicleChecks => 'فحوصات الحالة';

  @override
  String get vehicleColor => 'اللون';

  @override
  String get vehicleMake => 'الشركة المصنعة';

  @override
  String get vehicleModel => 'الطراز';

  @override
  String get vehicleYear => 'السنة';

  @override
  String get version => 'الإصدار';

  @override
  String get victimSupport => 'دعم الضحايا';

  @override
  String get viewAll => 'عرض الكل';

  @override
  String get vinNumber => 'رقم الهيكل';

  @override
  String get welcomeBack => 'مرحباً بعودتك';

  @override
  String get whatAreMyOptions => 'ما هي خياراتي؟';

  @override
  String get won => 'ربح';

  @override
  String get documentVault => 'خزنة المستندات';

  @override
  String get secureDocumentStorage => 'تخزين آمن للمستندات';

  @override
  String get secureDocumentStorageDesc =>
      'قم بتخزين مستنداتك القانونية المهمة بأمان. جميع الملفات مشفرة من طرف إلى طرف.';

  @override
  String get addDocument => 'إضافة مستند';

  @override
  String get chooseHowToAdd => 'اختر طريقة إضافة مستندك';

  @override
  String get uploadFile => 'رفع ملف';

  @override
  String get uploadFileDesc => 'اختر ملف PDF أو صورة من جهازك';

  @override
  String get scanDocumentDesc => 'التقط صورة لمستندك';

  @override
  String get createNote => 'إنشاء ملاحظة';

  @override
  String get createNoteDesc => 'اكتب ملاحظة أو سجّل تفاصيل مهمة';

  @override
  String get knowYourRights => 'اعرف حقوقك';

  @override
  String get stoppedByPolice => 'أوقفتك الشرطة';

  @override
  String get stoppedByPoliceDesc => 'حقوقك أثناء مواجهة مع الشرطة';

  @override
  String get deportationNotice => 'إشعار ترحيل';

  @override
  String get deportationNoticeDesc => 'خطوات الطعن في قرار الإبعاد';

  @override
  String get workplaceRights => 'حقوق العمل';

  @override
  String get workplaceRightsDesc => 'حماية قانون العمل في فنلندا';

  @override
  String get tenantRightsDesc => 'حماية حقوق السكن والإيجار';

  @override
  String get immigrationDetention => 'الاحتجاز المتعلق بالهجرة';

  @override
  String get immigrationDetentionDesc => 'حقوقك في حال احتجازك من قبل السلطات';

  @override
  String get discriminationDesc => 'كيفية الإبلاغ عن التمييز ومكافحته';

  @override
  String get scenarioNotFound => 'السيناريو غير موجود';

  @override
  String get youHaveRightTo => 'لديك الحق في:';

  @override
  String get youMust => 'يجب عليك:';

  @override
  String get immediateSteps => 'الخطوات الفورية:';

  @override
  String get yourRights => 'حقوقك:';

  @override
  String get basicRights => 'الحقوق الأساسية:';

  @override
  String get yourRightsAsTenant => 'حقوقك كمستأجر:';

  @override
  String get yourRightsInDetention => 'حقوقك أثناء الاحتجاز:';

  @override
  String get howToAct => 'كيف تتصرف:';

  @override
  String get rightKnowWhyStopped => 'معرفة سبب إيقافك';

  @override
  String get rightRemainSilent => 'التزام الصمت (يجب عليك تعريف هويتك)';

  @override
  String get rightAskInterpreter => 'طلب مترجم فوري';

  @override
  String get rightContactLawyer => 'الاتصال بمحامٍ قبل الاستجواب';

  @override
  String get rightRecordEncounter => 'تسجيل المواجهة (في الأماكن العامة)';

  @override
  String get mustProvideName => 'تقديم اسمك وتاريخ ميلادك';

  @override
  String get mustShowId => 'إبراز هويتك إن كانت لديك';

  @override
  String get mustNotResist => 'عدم المقاومة الجسدية';

  @override
  String get doNotIgnoreNotice => 'لا تتجاهل الإشعار - المواعيد النهائية صارمة';

  @override
  String get noteAppealDeadline => 'لاحظ موعد الاستئناف (عادة ٣٠ يوماً)';

  @override
  String get contactLawyerImmediately => 'اتصل بمحامٍ فوراً';

  @override
  String get applyLegalAid => 'قدّم طلب مساعدة قانونية إذا لزم الأمر';

  @override
  String get rightAppealAdmin => 'الحق في الاستئناف أمام المحكمة الإدارية';

  @override
  String get rightLegalRep => 'الحق في التمثيل القانوني';

  @override
  String get rightInterpreter => 'الحق في مترجم فوري';

  @override
  String get rightStayDuringAppeal =>
      'الحق في البقاء أثناء الاستئناف (في معظم الحالات)';

  @override
  String get minimumWage => 'الحد الأدنى للأجور وفقاً للاتفاقية الجماعية';

  @override
  String get workingTimeLimits =>
      'حدود ساعات العمل (بحد أقصى ٨ ساعات/يوم، ٤٠ ساعة/أسبوع)';

  @override
  String get annualLeave => 'إجازة سنوية (بحد أدنى يومان عن كل شهر عمل)';

  @override
  String get sickLeave => 'تعويض الإجازة المرضية';

  @override
  String get safeWorkingConditions => 'ظروف عمل آمنة';

  @override
  String get writtenRentalAgreement => 'يجب أن يكون عقد الإيجار مكتوباً';

  @override
  String get securityDeposit => 'مبلغ التأمين بحد أقصى ٣ أشهر إيجار';

  @override
  String get landlordNotice => 'يجب على المالك إعطاء إشعار (٣-٦ أشهر)';

  @override
  String get rightHabitableDwelling => 'الحق في مسكن صالح للسكن';

  @override
  String get protectionUnjustEviction => 'الحماية من الإخلاء غير العادل';

  @override
  String get rightKnowDetentionReason => 'الحق في معرفة سبب الاحتجاز';

  @override
  String get rightContactLawyerDetention => 'الحق في الاتصال بمحامٍ';

  @override
  String get rightContactEmbassy => 'الحق في الاتصال بسفارتك';

  @override
  String get rightChallengeDetention =>
      'الحق في الطعن في الاحتجاز أمام المحكمة';

  @override
  String get rightHumaneTreatment => 'الحق في معاملة إنسانية ورعاية طبية';

  @override
  String get documentIncident => 'وثّق الحادثة (التاريخ، الوقت، الشهود)';

  @override
  String get fileComplaintOmbudsman =>
      'قدّم شكوى لدى أمين المظالم لعدم التمييز';

  @override
  String get contactLegalAidOffice => 'اتصل بمكتب المساعدة القانونية';

  @override
  String get reportToPolice =>
      'أبلغ الشرطة إذا كان الأمر جنائياً (تهديد، اعتداء)';

  @override
  String get legalAidCalculator => 'حاسبة المساعدة القانونية';

  @override
  String checkEligibility(String country) {
    return 'تحقق من أهليتك للمساعدة القانونية: $country';
  }

  @override
  String get estimateDisclaimer =>
      'هذا تقدير فقط. يتم تحديد الأهلية الفعلية من قبل مكتب المساعدة القانونية.';

  @override
  String get monthlyIncome => 'الدخل الشهري (يورو)';

  @override
  String get totalAssets => 'إجمالي الأصول (يورو)';

  @override
  String get numberOfDependents => 'عدد المعالين';

  @override
  String get calculateEligibility => 'حساب الأهلية';

  @override
  String get likelyEligible => 'مؤهل على الأرجح';

  @override
  String get mayNotQualify => 'قد لا تكون مؤهلاً';

  @override
  String get fullFreeLegalAid =>
      'من المرجح أنك مؤهل للمساعدة القانونية المجانية الكاملة (بدون مساهمة مالية).';

  @override
  String legalAidWithCopay(String percent) {
    return 'قد تكون مؤهلاً للمساعدة القانونية مع مساهمة مالية بنسبة $percent%.';
  }

  @override
  String get mayNotQualifyDesc =>
      'بناءً على هذا التقدير، قد لا تكون مؤهلاً للمساعدة القانونية الحكومية. فكّر في استشارة محامٍ خاص أو عيادة قانونية.';

  @override
  String get couldNotLoadDeadlines => 'تعذر تحميل المواعيد النهائية';

  @override
  String get noUpcomingDeadlines => 'لا توجد مواعيد نهائية قادمة';

  @override
  String get allClearDeadlines =>
      'كل شيء على ما يرام! ستظهر المواعيد النهائية الجديدة هنا عند تحديدها.';

  @override
  String get nothingOverdue => 'لا يوجد شيء متأخر';

  @override
  String get greatJobDeadlines => 'عمل رائع في متابعة مواعيدك النهائية.';

  @override
  String get noCompletedDeadlines => 'لا توجد مواعيد نهائية مكتملة';

  @override
  String get completedDeadlinesDesc => 'ستظهر المواعيد النهائية المكتملة هنا.';

  @override
  String get daysLate => 'أيام تأخير';

  @override
  String get days => 'أيام';

  @override
  String get fromDocument => 'من المستند';

  @override
  String get couldNotLoadCase => 'تعذر تحميل تفاصيل القضية';

  @override
  String get typeLabel => 'النوع';

  @override
  String get nationality => 'الجنسية';

  @override
  String get migriReference => 'مرجع Migri';

  @override
  String get courtCaseNo => 'رقم القضية في المحكمة';

  @override
  String get created => 'تاريخ الإنشاء';

  @override
  String get citizenship => 'المواطنة';

  @override
  String get workPermit => 'تصريح العمل';

  @override
  String get noDocumentsYet => 'لم يتم رفع أي مستندات بعد';

  @override
  String get noUpcomingDeadlinesShort => 'لا توجد مواعيد نهائية قادمة';

  @override
  String get caseCreated => 'تم إنشاء القضية';

  @override
  String get decisionReceived => 'تم استلام القرار';

  @override
  String get appealDeadline => 'موعد الاستئناف النهائي';

  @override
  String get hearingScheduled => 'تم تحديد موعد الجلسة';

  @override
  String get late => 'متأخر';

  @override
  String get pending => 'قيد الانتظار';

  @override
  String get processing => 'قيد المعالجة';

  @override
  String get ready => 'جاهز';

  @override
  String get failed => 'فشل';

  @override
  String get analyzed => 'تم التحليل';

  @override
  String get noDocumentsScanHint =>
      'لا توجد مستندات بعد. امسح ضوئياً أو ارفع مستنداً.';

  @override
  String get inCourt => 'في المحكمة';

  @override
  String get appeal => 'استئناف';

  @override
  String get caseTimeline => 'الجدول الزمني للقضية';

  @override
  String get couldNotLoadTimeline => 'تعذر تحميل الجدول الزمني';

  @override
  String get noEventsYet => 'لا توجد أحداث بعد';

  @override
  String get activityWillAppear => 'سيظهر النشاط هنا مع تقدم قضيتك.';

  @override
  String caseCreatedDesc(String title) {
    return 'تم إنشاء القضية «$title».';
  }

  @override
  String get decisionReceivedDesc => 'تم استلام قرار رسمي لهذه القضية.';

  @override
  String get appealDeadlineSet => 'تم تحديد موعد الاستئناف النهائي';

  @override
  String appealDeadlineDesc(String date) {
    return 'يجب تقديم الاستئناف بحلول $date.';
  }

  @override
  String hearingScheduledDesc(String date) {
    return 'تم تحديد جلسة المحكمة في $date.';
  }

  @override
  String get caseInfoUpdated => 'تم تحديث معلومات القضية آخر مرة.';

  @override
  String get noEventsForFilter => 'لا توجد أحداث تطابق هذا الفلتر';

  @override
  String get timelineFilterAll => 'الكل';

  @override
  String get timelineFilterEmails => 'رسائل البريد الإلكتروني';

  @override
  String get timelineFilterConsilium => 'قرارات الذكاء الاصطناعي';

  @override
  String get timelineFilterDeadlines => 'المواعيد النهائية';

  @override
  String get timelineFilterNotes => 'الملاحظات';

  @override
  String get timelineEventEmailIn => 'تم استلام بريد إلكتروني';

  @override
  String get timelineEventEmailOut => 'تم إرسال بريد إلكتروني';

  @override
  String get timelineEventConsiliumDecision => 'قرار الذكاء الاصطناعي';

  @override
  String get timelineEventDeadlineSet => 'موعد نهائي';

  @override
  String get timelineEventDocUploaded => 'مستند';

  @override
  String get timelineEventPhaseChange => 'تغيير المرحلة';

  @override
  String get timelineEventManualNote => 'ملاحظة';

  @override
  String get timelineJustNow => 'الآن';

  @override
  String timelineMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'قبل $count دقيقة',
      one: 'قبل دقيقة واحدة',
    );
    return '$_temp0';
  }

  @override
  String timelineHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'قبل $count ساعة',
      one: 'قبل ساعة واحدة',
    );
    return '$_temp0';
  }

  @override
  String timelineDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'قبل $count يوم',
      one: 'قبل يوم واحد',
    );
    return '$_temp0';
  }

  @override
  String get documentAnalysis => 'تحليل المستند';

  @override
  String get exportAsPdf => 'تصدير كـ PDF';

  @override
  String get pdfExportComingSoon => 'تصدير PDF قريباً';

  @override
  String get analysisFailedRetry => 'فشل التحليل. يرجى المحاولة مرة أخرى.';

  @override
  String get somethingWentWrong => 'حدث خطأ ما';

  @override
  String get genericError => 'حدث خطأ ما. يرجى المحاولة مرة أخرى.';

  @override
  String get retryAnalysis => 'إعادة التحليل';

  @override
  String issuesFoundInDocument(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم العثور على $count مشاكل في المستند',
      one: 'تم العثور على مشكلة واحدة في المستند',
      zero: 'لم يتم العثور على مشاكل في المستند',
    );
    return '$_temp0';
  }

  @override
  String get severityOverview => 'نظرة عامة على الخطورة';

  @override
  String get issuesFoundHeader => 'المشكلات المكتشفة';

  @override
  String generateAppealWithIssues(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'إنشاء طعن ($count مشاكل)',
      one: 'إنشاء طعن (مشكلة واحدة)',
    );
    return '$_temp0';
  }

  @override
  String get analyzingContent => 'جارٍ تحليل المحتوى…';

  @override
  String get documentProcessedOk => 'تمت معالجة المستند بنجاح';

  @override
  String get noSignificantIssues =>
      'لم يتم اكتشاف مشكلات جوهرية في هذا المستند.';

  @override
  String get cameraPermissionRequired => 'مطلوب إذن الكاميرا';

  @override
  String get cameraPermissionDesc =>
      'امنح إذن الوصول إلى الكاميرا لمسح المستندات ضوئياً، أو استخدم المعرض.';

  @override
  String get openSettings => 'فتح الإعدادات';

  @override
  String get alignDocument => 'قم بمحاذاة المستند داخل الإطار';

  @override
  String pageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count صفحات',
      one: 'صفحة واحدة',
      zero: 'لا توجد صفحات',
    );
    return '$_temp0';
  }

  @override
  String get preview => 'معاينة';

  @override
  String pageNumber(int number) {
    return 'صفحة $number';
  }

  @override
  String get done => 'تم';

  @override
  String get retake => 'إعادة الالتقاط';

  @override
  String get useThisPhoto => 'استخدم هذه الصورة';

  @override
  String get addPage => 'إضافة صفحة';

  @override
  String uploadingPercent(int percent) {
    return 'جارٍ الرفع… $percent%';
  }

  @override
  String get preparingUpload => 'جارٍ تحضير الرفع…';

  @override
  String get documentUploadedSuccess => 'تم رفع المستند بنجاح';

  @override
  String pagesUploadedSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم تحميل $count صفحات بنجاح',
      one: 'تم تحميل صفحة واحدة بنجاح',
    );
    return '$_temp0';
  }

  @override
  String get uploadFailed =>
      'فشل الرفع. يرجى التحقق من اتصالك والمحاولة مرة أخرى.';

  @override
  String get capturePhotoFailed => 'فشل التقاط الصورة. يرجى المحاولة مرة أخرى.';

  @override
  String get readingText => 'جارٍ قراءة النص…';

  @override
  String get draftDocument => 'مسودة المستند';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get editDocument => 'تعديل المستند';

  @override
  String get generatingDraft => 'جارٍ إنشاء مسودتك…';

  @override
  String get generatingDraftDesc =>
      'يقوم الذكاء الاصطناعي بإعداد مستند قانوني بناءً على تفاصيل قضيتك والمشكلات المحددة.';

  @override
  String get failedToGenerateDraft =>
      'فشل إنشاء المسودة. يرجى المحاولة مرة أخرى.';

  @override
  String get changesSaved => 'تم حفظ التغييرات';

  @override
  String get copiedToClipboard => 'تم النسخ إلى الحافظة';

  @override
  String get emailComingSoon => 'إرسال البريد الإلكتروني قريباً';

  @override
  String get reviewBeforeSending =>
      'راجع بعناية قبل الإرسال. أنت مسؤول عن محتوى هذا المستند.';

  @override
  String get noContentAvailable => 'لا يوجد محتوى متاح';

  @override
  String get save => 'حفظ';

  @override
  String get edit => 'تعديل';

  @override
  String get pdf => 'PDF';

  @override
  String get copy => 'نسخ';

  @override
  String get appealDraft => 'مسودة الاستئناف';

  @override
  String selected(int count) {
    return '$count محدد';
  }

  @override
  String get deleteSelected => 'حذف المحدد';

  @override
  String deleteDocumentsConfirm(int count) {
    return 'حذف $count مستند؟';
  }

  @override
  String get delete => 'حذف';

  @override
  String get analyzeSelected => 'تحليل المحدد';

  @override
  String get batchAnalysisStarting => 'بدء التحليل الدُفعي…';

  @override
  String get switchToList => 'التبديل إلى القائمة';

  @override
  String get switchToGrid => 'التبديل إلى الشبكة';

  @override
  String get scanNew => 'مسح جديد';

  @override
  String get noDocumentsYetScan => 'لا توجد مستندات بعد';

  @override
  String get scanFirstDocumentHint =>
      'امسح أول مستند ضوئياً ليقوم الذكاء الاصطناعي بتحليله بحثاً عن أخطاء وإنشاء استئنافات.';

  @override
  String get failedToLoadDocuments => 'فشل تحميل المستندات';

  @override
  String get emailIntegrationTitle => 'تكامل البريد الإلكتروني';

  @override
  String get connectYourEmail => 'اربط بريدك الإلكتروني';

  @override
  String get connectYourEmailDesc =>
      'اربط بريدك الإلكتروني لاكتشاف وتنظيم المراسلات القانونية المتعلقة بقضاياك تلقائياً.';

  @override
  String get legalEmails => 'الرسائل القانونية';

  @override
  String get unlinkedEmails => 'رسائل غير مرتبطة';

  @override
  String get noLegalEmailsYet => 'لا توجد رسائل قانونية بعد';

  @override
  String get legalEmailsWillAppear => 'ستظهر هنا الرسائل المصنفة كقانونية.';

  @override
  String get assignToCase => 'تعيين للقضية';

  @override
  String get disconnectEmail => 'قطع البريد الإلكتروني';

  @override
  String get disconnectEmailConfirm =>
      'ستتوقف المزامنة التلقائية للبريد. ستبقى الرسائل المزامنة سابقاً في قضاياك.';

  @override
  String get gmailReauthBannerBody =>
      'يقرأ Advocat الإصدار 2.1 صندوق الوارد الخاص بك لصياغة الردود؛ يمكنك إلغاء الإذن في أي وقت. أعد الاتصال بـ Gmail لتفعيل الفرز الاستباقي.';

  @override
  String get gmailReauthBannerCta => 'إعادة التفويض';

  @override
  String connectedTo(String email) {
    return 'متصل بـ $email';
  }

  @override
  String lastSynced(String time) {
    return 'آخر مزامنة: $time';
  }

  @override
  String get filterByType => 'تصفية حسب النوع';

  @override
  String get noCasesMatchSearch => 'لا توجد قضايا مطابقة';

  @override
  String get failedToLoadCases => 'فشل تحميل القضايا';

  @override
  String get monthly => 'شهري';

  @override
  String get annual => 'سنوي';

  @override
  String get saveTwentyFivePercent => 'وفر 25%';

  @override
  String get mostPopular => 'الأكثر شعبية';

  @override
  String get oneCaseActive => 'قضية واحدة نشطة';

  @override
  String get threeCasesActive => '3 قضايا نشطة';

  @override
  String get unlimitedCases => 'قضايا غير محدودة';

  @override
  String get threeDocScans => '3 عمليات مسح';

  @override
  String get twentyDocScans => '20 عملية مسح';

  @override
  String get unlimitedDocScans => 'مسح غير محدود للمستندات';

  @override
  String get basicAiAnalysis => 'تحليل أساسي بالذكاء الاصطناعي';

  @override
  String get fullAiAnalysis => 'تحليل كامل بالذكاء الاصطناعي';

  @override
  String get draftGeneration => 'إنشاء المسودات';

  @override
  String get priorityProcessing => 'معالجة ذات أولوية';

  @override
  String get fiveAiMessagesTotal => '5 رسائل ذكاء اصطناعي (مدى الحياة)';

  @override
  String get hundredAiMessagesDay => '100 رسالة ذكاء اصطناعي/اليوم';

  @override
  String get unlimitedAiMessages => 'رسائل ذكاء اصطناعي غير محدودة';

  @override
  String get voiceInput => 'الإدخال الصوتي';

  @override
  String get strategyRecommendations => 'توصيات الاستراتيجية';

  @override
  String get foundingMemberNote => 'عضو مؤسس: 9.99€/شهريًا لأول 3 أشهر';

  @override
  String get saveTwentyPercent => 'وفّر 20%';

  @override
  String get forever => 'للأبد';

  @override
  String get perMonth => '/شهر';

  @override
  String get perYear => '/سنة';

  @override
  String get checkingPurchases => 'جارٍ التحقق من المشتريات السابقة…';

  @override
  String get noPreviousPurchases => 'لم يتم العثور على مشتريات سابقة.';

  @override
  String get chatWelcomeMessage =>
      'Hi! I\'m Advocat — your AI legal assistant. I provide legal information, not legal advice. What legal question can I help with?';

  @override
  String get copySummary => 'نسخ الملخص';

  @override
  String get caseSummaryCopied => 'تم نسخ ملخص القضية';

  @override
  String get openCase => 'فتح القضية';

  @override
  String get viewFull => 'عرض كامل';

  @override
  String get draftCopiedToClipboard => 'تم نسخ المسودة';

  @override
  String get reportMileageFraud => 'الإبلاغ عن تزوير العداد';

  @override
  String get reportMileageFraudDesc =>
      'سيتم إنشاء تقرير احتيال بناءً على بيانات فحص المركبة. يمكنك أيضاً فتح قضية قانونية.';

  @override
  String get reportAndOpenCase => 'إبلاغ وفتح قضية';

  @override
  String get caseCreationComingSoon =>
      'إنشاء القضية بالبيانات المعبأة مسبقاً قريباً';

  @override
  String get failedToCreateCaseRetry => 'فشل إنشاء القضية. حاول مرة أخرى.';

  @override
  String get takePhotoInstead => 'التقط صورة بدلاً من ذلك';

  @override
  String get deleteCase => 'حذف القضية';

  @override
  String deleteCaseConfirm(String title) {
    return 'هل أنت متأكد من حذف «$title»؟ لا يمكن التراجع عن هذا.';
  }

  @override
  String get haveQuestionsAi => 'لديك أسئلة؟ اسأل الذكاء الاصطناعي';

  @override
  String get cookiePolicy => 'سياسة ملفات تعريف الارتباط';

  @override
  String get aiDisclaimer => 'إخلاء مسؤولية الذكاء الاصطناعي';

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
  String get dataPrivacyConsent => 'موافقة خصوصية البيانات';

  @override
  String get gdprIntro =>
      'لتقديم المساعدة القانونية بالذكاء الاصطناعي، نعالج بياناتك وفقاً لـ GDPR (EU 2016/679). بالمتابعة توافق على:';

  @override
  String get gdprChat => 'معالجة رسائل المحادثة بالذكاء الاصطناعي';

  @override
  String get gdprDocs => 'تحليل المستندات المرفوعة';

  @override
  String get gdprStorage => 'تخزين مشفر لبيانات القضايا';

  @override
  String get gdprDelete => 'الحق في حذف بياناتك في أي وقت';

  @override
  String get gdprFooter =>
      'بياناتك مشفرة ولا تُشارك مع أطراف ثالثة. يمكنك سحب الموافقة وحذف جميع البيانات من الإعدادات.';

  @override
  String get gdprConsentAiProcessing =>
      'أوافق على معالجة بياناتي للحصول على مساعدة قانونية بالذكاء الاصطناعي (مطلوب)';

  @override
  String get gdprConsentAnalytics =>
      'أوافق على التحليلات لتحسين الخدمة (اختياري)';

  @override
  String get gdprArt9Intro =>
      'يعالج هذا التطبيق بيانات شخصية من فئة خاصة بموجب المادة 9 من GDPR، بما في ذلك:';

  @override
  String get gdprSpecialLegalCases => 'تفاصيل قضيتك القانونية ووثائق المحكمة';

  @override
  String get gdprSpecialNationality => 'الجنسية ووضع الهجرة';

  @override
  String get gdprConsentLegalData =>
      'أوافق على معالجة بيانات قضيتي القانونية وجنسيتي ووضع الهجرة الخاص بي بواسطة الذكاء الاصطناعي (مطلوب)';

  @override
  String get gdprConsentVoice => 'أوافق على معالجة التسجيل الصوتي (اختياري)';

  @override
  String get gdprViewPrivacyPolicy => 'عرض سياسة الخصوصية';

  @override
  String get legalInformation => 'المعلومات القانونية';

  @override
  String get legalEntityName => 'Vorantis OÜ';

  @override
  String get legalRegistryCode => 'رمز السجل: 17098992';

  @override
  String get legalAddress =>
      'Harju maakond, Tallinn, Kesklinna linnaosa, Tornimäe tn 5, 10145';

  @override
  String get legalEmail => 'البريد الإلكتروني: support@advocat.ee';

  @override
  String get legalRegistry => 'مسجّلة في السجل التجاري الإستوني (Äriregister)';

  @override
  String get aiGeneratedDisclaimer => 'AI-generated • Not legal advice';

  @override
  String get decline => 'رفض';

  @override
  String get iAgree => 'أوافق';

  @override
  String get iAgreeToThe => 'أوافق على ';

  @override
  String get orWord => 'أو';

  @override
  String get english => 'الإنجليزية';

  @override
  String get russian => 'الروسية';

  @override
  String get finnish => 'الفنلندية';

  @override
  String successSubscribed(String plan) {
    return 'تم الاشتراك في $plan بنجاح!';
  }

  @override
  String paymentFailed(String error) {
    return 'فشل الدفع: $error';
  }

  @override
  String get whatToDo => 'ماذا تفعل';

  @override
  String get getHelp => 'احصل على المساعدة';

  @override
  String get share => 'مشاركة';

  @override
  String get didYouKnow => 'هل تعلم؟';

  @override
  String get mustKnow => 'يجب أن تعرف';

  @override
  String get goodToKnow => 'من الجيد أن تعرف';

  @override
  String get sentFromAdvocat => 'أُرسل من تطبيق Advocat';

  @override
  String get policeActionStayCalm => 'ابقَ هادئاً واجعل يديك مرئيتين';

  @override
  String get policeActionAskWhy => 'اسأل الضابط عن سبب إيقافك';

  @override
  String get policeActionProvideName => 'قدّم اسمك وتاريخ ميلادك';

  @override
  String get policeActionWantLawyer =>
      'صرّح بوضوح: «أريد محامياً قبل أي أسئلة»';

  @override
  String get policeActionAskInterpreter => 'اطلب مترجماً عند الحاجة';

  @override
  String get policeActionNoteBadge => 'سجّل اسم الضابط ورقم شارته';

  @override
  String get policeFactMustTellReason =>
      'في فنلندا، يجب على الشرطة إخبارك بسبب إيقافك. إذا لم يفعلوا، يمكنك السؤال — وهم ملزمون قانونياً بالشرح.';

  @override
  String get policeFactCanRecord =>
      'يمكنك تسجيل التفاعلات مع الشرطة في الأماكن العامة في فنلندا. هذا محمي بحرية التعبير.';

  @override
  String get contactFinnishLegalAid => 'المساعدة القانونية الفنلندية';

  @override
  String get contactNonDiscriminationOmbudsman =>
      'أمين المظالم لمكافحة التمييز';

  @override
  String get deportationDeadlineAppeal =>
      'الطعن أمام المحكمة الإدارية — عادةً 30 يوماً من الإخطار';

  @override
  String get deportationDeadlineLegalAid =>
      'تقدّم بطلب المساعدة القانونية — افعل ذلك فوراً';

  @override
  String get deportationFactStayDuringAppeal =>
      'في فنلندا، لديك عادةً الحق في البقاء في البلاد أثناء معالجة طعنك. لا يمكن تنفيذ الترحيل أثناء طعن نشط في معظم الحالات.';

  @override
  String get contactRefugeeAdviceCentre => 'مركز المشورة الفنلندي للاجئين';

  @override
  String get contactAdminCourtHelsinki => 'المحكمة الإدارية في هلسنكي';

  @override
  String get workplaceActionKeepContract => 'احتفظ بنسخ من عقد العمل';

  @override
  String get workplaceActionTrackHours => 'تتبّع ساعات عملك بشكل مستقل';

  @override
  String get workplaceActionReportUnsafe =>
      'أبلغ عن الظروف غير الآمنة لهيئة السلامة المهنية';

  @override
  String get workplaceActionJoinUnion => 'انضم إلى نقابة عمالية للحماية';

  @override
  String get workplaceActionContactAuthority =>
      'تواصل مع هيئة السلامة المهنية عند الحاجة';

  @override
  String get workplaceFactCollectiveWage =>
      'في فنلندا، تحدد الاتفاقيات الجماعية الحد الأدنى للأجور حسب القطاع — لا يوجد حد أدنى وطني واحد للأجور. يجب على صاحب العمل الالتزام بالاتفاقية الجماعية لمجالك.';

  @override
  String get workplaceFactOralContract =>
      'حتى بدون عقد مكتوب، لديك حقوق كاملة كموظف في فنلندا. الاتفاق الشفهي ملزم قانونياً بنفس القدر.';

  @override
  String get contactOccupationalSafety => 'هيئة السلامة المهنية';

  @override
  String get contactTradeUnionSAK => 'استشارات النقابات العمالية (SAK)';

  @override
  String get tenantActionWrittenAgreement =>
      'احرص دائماً على وجود عقد إيجار مكتوب';

  @override
  String get tenantActionDocumentCondition =>
      'وثّق حالة الشقة عند الانتقال (صور)';

  @override
  String get tenantActionReportMaintenance => 'أبلغ عن مشاكل الصيانة كتابياً';

  @override
  String get tenantActionNoIllegalEviction =>
      'لا توافق أبداً على إخلاء غير قانوني — المحاكم هي من تقرر';

  @override
  String get tenantActionContactAdvisory =>
      'تواصل مع خدمات استشارات المستأجرين في حالة النزاعات';

  @override
  String get tenantFactNoEvictionWithoutCourt =>
      'لا يمكن للمؤجر في فنلندا إخلائك بدون أمر محكمة، حتى لو انتهى عقد الإيجار. تغيير الأقفال أو قطع المرافق غير قانوني.';

  @override
  String get contactTenantsAssociation => 'جمعية المستأجرين الفنلندية';

  @override
  String get contactConsumerDisputesBoard => 'مجلس نزاعات المستهلكين';

  @override
  String get detentionActionAskDecision => 'اطلب فوراً قرار الاحتجاز المكتوب';

  @override
  String get detentionActionRequestLawyer => 'اطلب التواصل مع محامٍ';

  @override
  String get detentionActionContactEmbassy => 'تواصل مع سفارتك أو قنصليتك';

  @override
  String get detentionActionAskMedical => 'اطلب الرعاية الطبية عند الحاجة';

  @override
  String get detentionActionRequestInterpreter =>
      'اطلب مترجماً لجميع الإجراءات';

  @override
  String get detentionDeadlineCourtReview =>
      'يجب على المحكمة الجزئية مراجعة الاحتجاز خلال 4 أيام';

  @override
  String get detentionDeadlineContinuation =>
      'تراجع المحكمة التمديد كل أسبوعين';

  @override
  String get detentionFactCourtReview =>
      'يجب مراجعة احتجاز المهاجرين في فنلندا من قبل محكمة جزئية خلال 4 أيام. إذا لم يتم ذلك، يصبح الاحتجاز غير قانوني.';

  @override
  String get contactParliamentaryOmbudsman => 'أمين المظالم البرلماني';

  @override
  String get discriminationActionWriteDown =>
      'دوّن بالضبط ما حدث (التاريخ، الوقت، المكان)';

  @override
  String get discriminationActionSaveEvidence =>
      'احفظ الأدلة: الرسائل، البريد الإلكتروني، الشهود';

  @override
  String get discriminationActionFileComplaint =>
      'قدّم شكوى لأمين المظالم لمكافحة التمييز';

  @override
  String get discriminationActionContactLegalAid =>
      'تواصل مع مكتب المساعدة القانونية للحصول على استشارة مجانية';

  @override
  String get discriminationActionReportPolice =>
      'أبلغ الشرطة إذا كانت هناك تهديدات أو اعتداء';

  @override
  String get discriminationFactNonDiscriminationAct =>
      'يغطي قانون مكافحة التمييز الفنلندي التمييز على أساس العمر والأصل والجنسية واللغة والدين والصحة والإعاقة والتوجه الجنسي وغيرها من الخصائص الشخصية.';

  @override
  String get contactVictimSupportRIKU => 'دعم الضحايا فنلندا (RIKU)';

  @override
  String get domesticViolence => 'العنف المنزلي';

  @override
  String get domesticViolenceDesc =>
      'حقوق الضحية، المساعدة الطارئة، أوامر التقييد';

  @override
  String get rightCallEmergency =>
      'لديك الحق في الاتصال بالرقم 112 في أي حالة طارئة — الشرطة، الإسعاف، الإطفاء';

  @override
  String get rightVictimProtection =>
      'بصفتك ضحية، لديك الحق في الحماية والدعم والمعلومات حول قضيتك';

  @override
  String get rightRestrainingOrder =>
      'يمكنك التقدم بطلب للحصول على أمر تقييد (lähestymiskielto) لإبعاد المعتدي عنك';

  @override
  String get rightVictimInterpreter =>
      'لديك الحق في الاستعانة بمترجم فوري خلال جميع الإجراءات القانونية';

  @override
  String get rightMedicalHelp =>
      'لديك الحق في تلقي العلاج الطبي الفوري وتوثيق الإصابات';

  @override
  String get rightShelter =>
      'لديك الحق في مأوى طارئ — تواصل مع مأوى أو الخدمات الاجتماعية';

  @override
  String get mustReportDanger =>
      'إذا كان شخص ما في خطر مباشر، فاتصل بالرقم 112 فورًا';

  @override
  String get mustDocumentInjuries =>
      'وثّق جميع الإصابات — الصور والسجلات الطبية والملاحظات المكتوبة';

  @override
  String get domesticActionCallEmergency =>
      'اتصل بالرقم 112 إذا كنت في خطر مباشر';

  @override
  String get domesticActionGoToSafe =>
      'اذهب إلى مكان آمن — مأوى، صديق، مكان عام';

  @override
  String get domesticActionDocumentEverything =>
      'وثّق الإصابات: التقط صورًا، واحصل على سجلات طبية';

  @override
  String get domesticActionFilePoliceReport =>
      'قدّم بلاغًا للشرطة — يمكنك فعل ذلك لاحقًا أيضًا';

  @override
  String get domesticActionContactShelter =>
      'تواصل مع مأوى أو خط مساعدة للأزمات';

  @override
  String get domesticActionApplyRestraining =>
      'تقدّم بطلب أمر تقييد عبر الشرطة أو المحكمة';

  @override
  String get domesticFactRestrainingOrder =>
      'في فنلندا، يمكن إصدار أمر تقييد (lähestymiskielto) حتى دون وجود قضية جنائية. وهو يمنع الشخص من الاتصال بك أو الاقتراب منك.';

  @override
  String get domesticFactVictimDirective =>
      'بموجب توجيه الاتحاد الأوروبي لحقوق الضحايا 2012/29/EU، لديك الحق في أن تُعامَل باحترام، وأن تتلقى المعلومات بلغة تفهمها، وأن تصل إلى خدمات دعم الضحايا — بغض النظر عن وضع إقامتك.';

  @override
  String get domesticDeadlinePoliceReport =>
      'تقديم بلاغ للشرطة — لا يوجد موعد نهائي صارم، لكن الأسرع أفضل للأدلة';

  @override
  String get domesticDeadlineRestraining =>
      'أمر التقييد — يمكن التقدم بطلبه في أي وقت';

  @override
  String get contactEmergency => 'رقم الطوارئ';

  @override
  String get contactShelter => 'خط مساعدة المأوى (Turvakoti)';

  @override
  String get contactCrisisHelpline => 'خط مساعدة الأزمات (Kriisipuhelin)';

  @override
  String get contactNollaLinja => 'Nollalinja — خط مساعدة العنف ضد المرأة';

  @override
  String get inheritance => 'الميراث';

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
  String get consumerProtection => 'حماية المستهلك';

  @override
  String get consumerProtectionDesc =>
      'الاحتيال، المنتجات المعيبة، الإرجاع، البائعون المخادعون';

  @override
  String get rightReturnOnline =>
      'لديك 14 يومًا لإلغاء المشتريات عبر الإنترنت دون إبداء سبب (حق الانسحاب في الاتحاد الأوروبي)';

  @override
  String get rightDefectiveProduct =>
      'إذا كان المنتج معيبًا، فلديك الحق في الإصلاح أو الاستبدال أو استرداد الأموال';

  @override
  String get rightClearPricing =>
      'يجب على البائعين عرض أسعار واضحة تشمل جميع الرسوم — التكاليف الخفية غير قانونية';

  @override
  String get rightComplainBoard =>
      'يمكنك تقديم شكوى مجانية إلى مجلس نزاعات المستهلكين';

  @override
  String get rightProtectionFraud =>
      'أنت محمي ضد الممارسات التجارية غير العادلة والاحتيال';

  @override
  String get mustKeepReceipts =>
      'احتفظ بجميع الإيصالات والعقود والمراسلات مع البائعين';

  @override
  String get mustActTimely =>
      'أبلغ البائع عن العيوب خلال وقت معقول بعد اكتشافها';

  @override
  String get consumerActionKeepEvidence =>
      'احتفظ بالإيصالات ولقطات الشاشة ورسائل البريد الإلكتروني وجميع إثباتات الشراء';

  @override
  String get consumerActionContactSeller =>
      'تواصل مع البائع أولًا — اشرح المشكلة كتابيًا';

  @override
  String get consumerActionFileComplaint =>
      'قدّم شكوى إلى مجلس نزاعات المستهلكين (kuluttajariitalautakunta)';

  @override
  String get consumerActionContactAuthority =>
      'تواصل مع خدمات استشارات المستهلك للحصول على مساعدة مجانية';

  @override
  String get consumerActionReportFraud =>
      'أبلغ عن الاحتيال إلى الشرطة وأمين مظالم المستهلك';

  @override
  String get consumerFactWithdrawal =>
      'بموجب توجيه حقوق المستهلك في الاتحاد الأوروبي 2011/83/EU، لديك 14 يومًا للانسحاب من أي عملية شراء عبر الإنترنت أو عن بُعد — دون إبداء أسباب. يجب على البائع رد أموالك خلال 14 يومًا.';

  @override
  String get consumerFactWarranty =>
      'في فنلندا، يكون البائع مسؤولًا عن عيوب المنتج لفترة معقولة (غالبًا أكثر من سنتين). وهذا منفصل عن أي ضمان من الشركة المصنّعة.';

  @override
  String get consumerDeadlineWithdrawal =>
      'الانسحاب من الشراء عبر الإنترنت — 14 يومًا من التسليم';

  @override
  String get consumerDeadlineDefect =>
      'الإبلاغ عن العيب للبائع — خلال شهرين من اكتشافه (موصى به)';

  @override
  String get contactConsumerAdvisory => 'خدمات استشارات المستهلك';

  @override
  String get contactConsumerOmbudsman =>
      'أمين مظالم المستهلك (Kuluttaja-asiamies)';

  @override
  String get contactConsumerDisputesBoardDirect => 'مجلس نزاعات المستهلكين';

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
  String get comingSoon => 'قريبًا';

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
      other: '$count حقوق بالداخل',
      one: 'حق واحد بالداخل',
      zero: 'لا توجد حقوق',
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
  String get categoryChildren => 'الأطفال';

  @override
  String get categoryDigital => 'الرقمي';

  @override
  String get childrenRights => 'حقوق الأطفال والنفقة';

  @override
  String get childrenRightsDesc =>
      'نفقة الطفل، الإعالة، الحماية، ضمانات الدولة';

  @override
  String get cyberbullying => 'التنمر الإلكتروني والمضايقات عبر الإنترنت';

  @override
  String get cyberbullyingDesc =>
      'التهديدات، انتهاكات الخصوصية، التشهير عبر الإنترنت';

  @override
  String get rightChildSupport =>
      'كلا الوالدين ملزمان قانونًا بإعالة طفلهما ماليًا (Perekonnaseadus § 100–102)';

  @override
  String get rightMinimumAlimony =>
      'الحد الأدنى لنفقة الطفل في إستونيا: المبلغ الأساسي (295.86€) + 3% من متوسط الراتب الإجمالي للعام السابق (PKS § 101). اعتبارًا من 01.04.2026 — 318.62€/شهريًا لكل طفل. يُحدَّث سنويًا في 1 أبريل. الآلة الحاسبة: alimendid.ee';

  @override
  String get rightCourtAlimony =>
      'يمكنك التقدم بطلب النفقة عبر محكمة المقاطعة (maakohus) — لا حاجة لمحامٍ للمطالبات حتى 6,400€';

  @override
  String get rightBailiffEnforcement =>
      'إذا رفض الوالد الدفع، يمكن لمأمور تنفيذ (kohtutäitur) إنفاذ أمر المحكمة، بما في ذلك الحجز على الأجور';

  @override
  String get rightStateAlimonyGuarantee =>
      'إذا لم يدفع الوالد، توفر الدولة elatisabi (بدل الإعالة) عبر Sotsiaalkindlustusamet — حتى 100€/شهريًا لكل طفل';

  @override
  String get rightChildEducation =>
      'لكل طفل الحق في التعليم والرعاية الصحية والحماية من الإساءة (Lastekaitseseadus § 4–5)';

  @override
  String get rightChildContact =>
      'للطفل الحق في الحفاظ على التواصل مع كلا الوالدين ما لم تقرر المحكمة خلاف ذلك (PKS § 143)';

  @override
  String get mustFileCourtClaim =>
      'لتلقي النفقة، يجب عليك تقديم مطالبة في المحكمة أو الاتفاق على المبلغ كتابيًا';

  @override
  String get mustNotifyAddressChange =>
      'أبلغ Sotsiaalkindlustusamet بتغييرات العنوان إذا كنت تتلقى elatisabi';

  @override
  String get childrenActionGatherDocs =>
      'اجمع شهادة ميلاد الطفل وهويتك وإثبات النفقات';

  @override
  String get childrenActionFileCourtClaim =>
      'قدّم مطالبة نفقة في محكمة المقاطعة (maakohus) — يمكن القيام بذلك عبر الإنترنت من خلال e-toimik';

  @override
  String get childrenActionApplyElatisabi =>
      'تقدّم بطلب ضمان النفقة الحكومي (elatisabi) لدى Sotsiaalkindlustusamet إذا رفض الوالد الدفع';

  @override
  String get childrenActionContactBailiff =>
      'تواصل مع مأمور تنفيذ (kohtutäitur) لإنفاذ أمر المحكمة';

  @override
  String get childrenActionCallLasteabi =>
      'اتصل بخط مساعدة الأطفال Lasteabi 116 111 — مجاني، على مدار الساعة';

  @override
  String get childrenDeadlineElatisabi =>
      'التقدم بطلب elatisabi — بعد أمر المحكمة، لا يوجد موعد نهائي صارم لكن العملية تستغرق وقتًا';

  @override
  String get childrenDeadlineCourt =>
      'يمكن المطالبة بالنفقة بأثر رجعي حتى سنة واحدة قبل تقديم الدعوى للمحكمة';

  @override
  String get childrenFactMinimum =>
      'اعتبارًا من 01.04.2026 يبلغ الحد الأدنى لنفقة الطفل 318.62€/شهريًا لكل طفل. المعادلة: المبلغ الأساسي (295.86€) + 3% من متوسط الراتب الإجمالي للعام السابق. يُحدَّث سنويًا في 1 أبريل. لا يمكن لأي والد الاتفاق على دفع أقل. الآلة الحاسبة: alimendid.ee';

  @override
  String get childrenFactElatisabi =>
      'تم استحداث ضمان النفقة الحكومي في إستونيا (elatisabi) عام 2017 لحماية الأطفال عندما يرفض أحد الوالدين الدفع. تدفع الدولة المبلغ ثم تستردّه من الوالد المدين.';

  @override
  String get rightReportCybercrime =>
      'لديك الحق في الإبلاغ عن التهديدات والمضايقات وسرقة الهوية عبر الإنترنت إلى الشرطة (Karistusseadustik § 120, § 157¹)';

  @override
  String get rightContentRemoval =>
      'يمكنك طلب إزالة المحتوى التشهيري أو الخاص من المنصات والمطالبة بحذفه بموجب GDPR';

  @override
  String get rightMoralDamageCompensation =>
      'يجوز لك المطالبة بتعويض عن الضرر المعنوي الناجم عن التنمر الإلكتروني (Võlaõigusseadus § 1043–1055)';

  @override
  String get rightPrivacyProtection =>
      'حياتك الخاصة محمية — المشاركة غير المصرّح بها لصورك أو رسائلك أو بياناتك الشخصية غير قانونية (KarS § 157)';

  @override
  String get rightDataProtection =>
      'أبلغ عن انتهاكات حماية البيانات (الاستخدام غير المصرّح به لبياناتك) إلى Andmekaitse Inspektsioon';

  @override
  String get rightDefamationAction =>
      'التشهير (laimamine) جريمة مدنية — يمكنك المقاضاة للحصول على تعويضات والمطالبة بتراجع علني (KarS § 247 (ملغى)، VÕS § 1047)';

  @override
  String get mustCollectEvidence =>
      'اجمع جميع الأدلة واحتفظ بها — لقطات الشاشة والروابط والتواريخ ومعلومات الشهود';

  @override
  String get mustNotRetaliate =>
      'لا تنتقم أو تنخرط في مضايقات مضادة — فقد يُضعف ذلك قضيتك';

  @override
  String get cyberActionScreenshots =>
      'التقط لقطات شاشة لجميع المضايقات — احفظ عناوين URL والتواريخ وأسماء المستخدمين والمحتوى';

  @override
  String get cyberActionReportPolice =>
      'قدّم بلاغًا للشرطة في أقرب مركز أو عبر الإنترنت على politsei.ee';

  @override
  String get cyberActionReportPlatform =>
      'أبلغ عن المحتوى إلى منصة التواصل الاجتماعي لإزالته';

  @override
  String get cyberActionContactDPA =>
      'تواصل مع Andmekaitse Inspektsioon إذا أُسيء استخدام بياناتك الشخصية';

  @override
  String get cyberActionConsultLawyer =>
      'استشر محاميًا بشأن التعويضات المدنية — تتوفر مساعدة قانونية مجانية عبر Riigi Õigusabi';

  @override
  String get cyberDeadlineCriminal =>
      'الشكوى الجنائية — لا يوجد موعد نهائي صارم، لكن أبلغ فورًا للحصول على أفضل النتائج';

  @override
  String get cyberDeadlineCivil =>
      'المطالبة المدنية بالتعويضات — حتى 3 سنوات من تاريخ علمك بالانتهاك (TsÜS § 150)';

  @override
  String get cyberFactPrivacy =>
      'في إستونيا، يمكن أن تؤدي المشاركة غير المصرّح بها لصور حميمة لشخص ما إلى السجن حتى 3 سنوات بموجب Karistusseadustik § 157¹ (انتهاك الخصوصية).';

  @override
  String get cyberFactGDPR =>
      'بموجب GDPR، لديك “الحق في النسيان” — يجب على المنصات حذف بياناتك الشخصية عند الطلب إذا لم يكن هناك أساس قانوني للاحتفاظ بها.';

  @override
  String get guestUser => 'ضيف';

  @override
  String get howToUse => 'كيفية الاستخدام؟';

  @override
  String get tutorialStep1Title => 'مساعد قانوني بالذكاء الاصطناعي';

  @override
  String get tutorialStep1Desc =>
      'اطرح أي سؤال قانوني واحصل على إجابات فورية بناءً على القانون الإستوني.';

  @override
  String get tutorialStep2Title => 'اعرف حقوقك';

  @override
  String get tutorialStep2Desc =>
      'تصفح المعلومات القانونية حسب الموضوع — العمل، السكن، حقوق المستهلك والمزيد.';

  @override
  String get tutorialStep3Title => 'مسح المستندات';

  @override
  String get tutorialStep3Desc =>
      'التقط صور المستندات القانونية لتحليل الذكاء الاصطناعي والتخزين الآمن.';

  @override
  String get tutorialStep4Title => 'لنبدأ!';

  @override
  String get tutorialStep4Desc =>
      'استكشف التطبيق واحمِ حقوقك. جميع البيانات تبقى خاصة على جهازك.';

  @override
  String get advocatProTitle => 'Advocat Pro';

  @override
  String get advocatProSubtitle => 'افتح الميزات المتقدمة';

  @override
  String get voiceDisclaimer =>
      'المساعد الصوتي يعمل حاليًا فقط على الكمبيوتر (متصفح Chrome). دعم الهاتف قريبًا.';

  @override
  String get recommended => 'موصى به';

  @override
  String get pleaseLogIn => 'يرجى تسجيل الدخول';

  @override
  String get subscriptionNotFound => 'لم يتم العثور على الاشتراك';

  @override
  String errorWithMessage(String message) {
    return 'خطأ: $message';
  }

  @override
  String get redirectingToPayment => 'جارٍ التوجيه إلى صفحة الدفع…';

  @override
  String cheaperAnnually(String amount) {
    return '€$amount/شهر أرخص بالاشتراك السنوي';
  }

  @override
  String get navigatingTo => 'جارٍ فتح';

  @override
  String get stayInChat => 'البقاء في المحادثة';

  @override
  String get backToChat => 'العودة إلى المحادثة';

  @override
  String get upgradeBannerTitle => 'قم بالترقية للحصول على استشارات غير محدودة';

  @override
  String get upgradeBannerCta => 'ترقية';

  @override
  String get paymentSuccessTitle => 'تم الدفع بنجاح';

  @override
  String get paymentSuccessBody => 'اشتراكك نشط الآن.';

  @override
  String get commonOk => 'موافق';

  @override
  String get feedbackThumbsUpLabel => 'مفيد';

  @override
  String get feedbackThumbsDownLabel => 'غير مفيد';

  @override
  String get feedbackCommentPrompt => 'ما الخطأ الذي حدث؟';

  @override
  String get feedbackSend => 'إرسال';

  @override
  String get feedbackCancel => 'إلغاء';

  @override
  String get reasoningPillIdle => 'يفكّر…';

  @override
  String get reasoningPillSearchingLaw => 'يبحث في القانون الإستوني…';

  @override
  String get reasoningPillSearchingWeb => 'يبحث على الويب…';

  @override
  String get reasoningPillCheckingCompany => 'يتحقق من سجل الشركات…';

  @override
  String get reasoningPillCheckingVehicle => 'يتحقق من سجل المركبات…';

  @override
  String get reasoningPillReadingDocument => 'يقرأ مستندك…';

  @override
  String get reasoningPillDrafting => 'يصوغ المستند…';

  @override
  String get reasoningPillPreparingEmail => 'يُعدّ البريد الإلكتروني…';

  @override
  String get reasoningPillFindingLawyer => 'يبحث عن محامين…';

  @override
  String get reasoningPillThinking => 'يفكّر في قضيتك…';

  @override
  String get reasoningPillFinalising => 'يصوغ إجابتك…';

  @override
  String reasoningCollapsedFormat(int sec, int sources) {
    return 'فكّر لمدة $sec ثانية · $sources مصدر';
  }

  @override
  String get reasoningExpandHint => 'اضغط لرؤية الخطوات';

  @override
  String get caseFileTitle => 'ملف القضية';

  @override
  String get caseFileTimeline => 'الجدول الزمني';

  @override
  String get caseFileParties => 'الأطراف';

  @override
  String get caseFileDeadlines => 'المواعيد النهائية';

  @override
  String get caseFileExportPdf => 'تنزيل الملف (PDF)';

  @override
  String get caseFileEmpty =>
      'تحدّث مع الذكاء الاصطناعي حول قضيتك — سيُبنى جدولك الزمني تلقائيًا.';

  @override
  String get caseFileDisclaimer =>
      'تم استخراج هذا الملف تلقائيًا من محادثتك. وهو ليس استشارة قانونية.';

  @override
  String get caseFileTabLabel => 'القضية';

  @override
  String get refresh => 'تحديث';

  @override
  String get demoLimitReached =>
      'تم بلوغ حد النسخة التجريبية. سجّل مجانًا للمتابعة.';

  @override
  String get demoLimitSignUpCta => 'إنشاء حساب';

  @override
  String freeQuotaExhausted(int count) {
    return 'لقد استخدمت جميع الرسائل المجانية الـ$count هذا الشهر.';
  }

  @override
  String get upgradeForUnlimited => 'قم بالترقية إلى Pro للاستخدام غير المحدود';

  @override
  String get upgradeCta => 'ترقية';

  @override
  String get rateLimitTryAgain =>
      'الإرسال سريع جدًا. حاول مرة أخرى خلال بضع ثوانٍ.';

  @override
  String get quickProfilePrompt =>
      'كي أتمكن من مساعدتك بدقة أكبر، ما هو وضعك القانوني: هل أنت مواطن إستوني، أو مواطن من دولة أخرى في الاتحاد الأوروبي، أم لديك تصريح إقامة؟';

  @override
  String get quickProfileChipEstonianCitizen => 'مواطن إستوني';

  @override
  String get quickProfileChipEuCitizen => 'مواطن أوروبي (آخر)';

  @override
  String get quickProfileChipResidencePermit => 'تصريح إقامة';

  @override
  String get quickProfileSkipBtn => 'تخطّي';

  @override
  String get quickProfileSavedAck => 'فهمت. والآن، ما هو سؤالك؟';

  @override
  String get caseTitleLabel => 'عنوان القضية';

  @override
  String get jurisdictionLabel => 'الاختصاص القضائي';

  @override
  String get caseTypeLabel => 'نوع القضية';

  @override
  String get caseLanguageLabel => 'اللغة';

  @override
  String get caseNumbersSection => 'أرقام القضية';

  @override
  String get partiesSection => 'الأطراف';

  @override
  String get authoritiesSection => 'السلطات';

  @override
  String get timelineSection => 'الجدول الزمني';

  @override
  String get openQuestionsSection => 'الأسئلة المفتوحة';

  @override
  String get nextActionsSection => 'الإجراءات التالية';

  @override
  String get summarySection => 'الملخّص';

  @override
  String get addRow => 'إضافة صف';

  @override
  String get removeRow => 'إزالة';

  @override
  String get archiveCase => 'أرشفة القضية';

  @override
  String get closeCase => 'إغلاق القضية';

  @override
  String get continueChatAboutCase => 'متابعة المحادثة حول هذه القضية';

  @override
  String get linkChatToCase => 'ربط بالقضية';

  @override
  String get clearActiveCase => 'مسح القضية النشطة';

  @override
  String get caseSavedAck => 'تم حفظ القضية';

  @override
  String get caseArchivedAck => 'تمت أرشفة القضية';

  @override
  String get intakeStep1Title => 'أين توجد القضية؟';

  @override
  String get intakeStep1Subtitle => 'الدولة والسلطة التي تتعامل معها.';

  @override
  String get intakeJurisdictionLabel => 'الدولة / الاختصاص القضائي';

  @override
  String get intakeAuthorityLabel => 'نوع السلطة';

  @override
  String get intakeAuthorityNameLabel => 'اسم السلطة (اختياري)';

  @override
  String get intakeAuthorityPolice => 'الشرطة';

  @override
  String get intakeAuthorityCourt => 'المحكمة';

  @override
  String get intakeAuthoritySocial => 'الخدمات الاجتماعية';

  @override
  String get intakeAuthorityEmployer => 'صاحب العمل';

  @override
  String get intakeAuthorityLandlord => 'المالك';

  @override
  String get intakeAuthorityOpposingParty => 'الطرف الخصم';

  @override
  String get intakeAuthorityOther => 'أخرى';

  @override
  String get intakeStep2Title => 'ما نوع القضية؟';

  @override
  String get intakeStep2Subtitle => 'اختر النوع الأقرب — يمكنك تحسينه لاحقًا.';

  @override
  String get intakeCaseTypeCriminal => 'جنائية';

  @override
  String get intakeCaseTypeCivil => 'مدنية';

  @override
  String get intakeCaseTypeFamily => 'أسرية';

  @override
  String get intakeCaseTypeAdmin => 'إدارية';

  @override
  String get intakeCaseTypeImmigration => 'هجرة';

  @override
  String get intakeCaseTypeLabor => 'عمالية';

  @override
  String get intakeCaseTypeConsumer => 'استهلاكية';

  @override
  String get intakeCaseTypeInheritance => 'ميراث';

  @override
  String get intakeCaseTypeOther => 'أخرى';

  @override
  String get intakeStep3Title => 'من المعنيّون؟';

  @override
  String get intakeStep3Subtitle => 'دورك والطرف الآخر.';

  @override
  String get intakeRoleLabel => 'دورك';

  @override
  String get intakeRolePlaintiff => 'المدّعي';

  @override
  String get intakeRoleDefendant => 'المدّعى عليه';

  @override
  String get intakeRoleVictim => 'الضحية';

  @override
  String get intakeRoleAccused => 'المتهم';

  @override
  String get intakeRoleWitness => 'الشاهد';

  @override
  String get intakeRoleFamily => 'أحد أفراد الأسرة';

  @override
  String get intakeRoleOther => 'أخرى';

  @override
  String get intakeOpposingSideLabel => 'الطرف الخصم (اختياري)';

  @override
  String get intakeWitnessesLabel => 'الشهود (اختياري)';

  @override
  String get intakeAddWitness => 'إضافة شاهد';

  @override
  String get intakeWitnessHint => 'الاسم أو جهة الاتصال';

  @override
  String get intakeStep4Title => 'الأرقام والتواريخ';

  @override
  String get intakeStep4Subtitle => 'ما لديك بالفعل. تخطَّ ما لا تملكه.';

  @override
  String get intakeCaseNumberLabel => 'رقم القضية (اختياري)';

  @override
  String get intakeIncidentDateLabel => 'تاريخ الحادثة (اختياري)';

  @override
  String get intakeIncidentDatePick => 'اختر التاريخ';

  @override
  String get intakeDeadlinesLabel => 'المواعيد النهائية المعروفة';

  @override
  String get intakeAddDeadline => 'إضافة موعد نهائي';

  @override
  String get intakeDeadlineWhatHint => 'ماذا';

  @override
  String get intakeStep5Title => 'المستندات';

  @override
  String get intakeStep5Subtitle => 'ارفع أي شيء ذي صلة. سنقرأه.';

  @override
  String get intakeUploadDocsLabel => 'رفع المستندات';

  @override
  String get intakeSkipDocs => 'تخطّي — سأرفعها لاحقًا';

  @override
  String get intakeNextBtn => 'التالي';

  @override
  String get intakeBackBtn => 'رجوع';

  @override
  String get intakeFinishBtn => 'إنهاء وفتح المحادثة';

  @override
  String get intakeUrgentBtn => 'عاجل — اسأل الآن';

  @override
  String get intakeUrgentDialogTitle => 'فتح المحادثة الآن؟';

  @override
  String get intakeUrgentDialogBody =>
      'سنحفظ ما أدخلته كقضية مسودّة. يمكنك إكمال المعالج من صفحة القضية في أي وقت.';

  @override
  String get intakeUrgentConfirm => 'فتح المحادثة';

  @override
  String get intakeUrgentCancel => 'متابعة التعبئة';

  @override
  String get intakePreparingCase => 'يتم تجهيز قضيتك…';

  @override
  String get intakeFallbackGreeting =>
      'أرى قضيتك. أخبرني بما هو الأكثر إلحاحًا — سأعمل عليه معك.';

  @override
  String get intakeUrgentGreeting =>
      'أرى أن هذا أمر عاجل. اطرح سؤالك — سأكمل الباقي أثناء تقدّمنا.';

  @override
  String intakeStepIndicator(int current, int total) {
    return 'الخطوة $current من $total';
  }

  @override
  String get intakeFieldRequired => 'مطلوب';

  @override
  String intakeUploadProgress(int done, int total) {
    return 'جارٍ الرفع $done / $total…';
  }

  @override
  String get uplDisclaimerFooter =>
      'Advocat ليست مكتب محاماة. هذه معلومات، وليست استشارة قانونية.';

  @override
  String get citationStatusVerifiedBadge => 'موثَّق';

  @override
  String get citationStatusUnverifiedBadge => 'غير موثَّق';

  @override
  String get citationStatusHistoricalBadge => 'نسخة سابقة';

  @override
  String get citationStatusVerifiedTooltip =>
      'مُقتبَس من مصدر قانوني تم استرجاعه.';

  @override
  String get citationStatusUnverifiedTooltip =>
      'اقتبس الذكاء الاصطناعي هذا دون استرجاع المصدر — تحقَّق قبل الاعتماد عليه.';

  @override
  String get citationStatusHistoricalTooltip =>
      'الحكم المُقتبَس لم يعد ساري المفعول.';

  @override
  String get citationOpenInRiigiTeataja => 'فتح في Riigi Teataja';

  @override
  String get citationSnippetExpand => 'عرض النص الكامل';

  @override
  String get citationSnippetCollapse => 'عرض أقل';

  @override
  String get citationUnverifiedSheetNote =>
      'اقتبس الذكاء الاصطناعي هذه الفقرة، غير أنه لم يتم استرجاعها من المتن القانوني في هذه الجلسة. تحقَّق من المرجع قبل الاعتماد عليه.';

  @override
  String get citationFooterNoneWarning => 'لا توجد اقتباسات موثَّقة';

  @override
  String citationFooterSummaryTotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count اقتباسات',
      one: 'اقتباس واحد',
    );
    return '$_temp0';
  }

  @override
  String citationFooterSummaryVerified(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم التحقق من $count',
      one: 'تم التحقق من واحد',
    );
    return '$_temp0';
  }

  @override
  String citationFooterSummaryUnverified(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count غير مُتحقق منها',
      one: 'غير مُتحقق منه واحد',
    );
    return '$_temp0';
  }

  @override
  String citationFooterSummaryHistorical(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تاريخية',
      one: 'تاريخي واحد',
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
      other: 'خلال $count أيام',
      one: 'خلال يوم واحد',
      zero: 'اليوم',
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
      other: 'متأخر $count أيام',
      one: 'متأخر يوم واحد',
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
    return 'يوصي المجلس بـ$count إجراءات متوازية';
  }

  @override
  String get parallelActionsApproveAll => 'الموافقة على الكل وإرسال';

  @override
  String parallelActionsApproveSelected(int count, int total) {
    return 'الموافقة على $count من $total';
  }

  @override
  String parallelActionsConfirmTitle(int count) {
    return 'إرسال $count رسالة بريد إلكتروني؟';
  }

  @override
  String parallelActionsConfirmBody(int count) {
    return 'سيرسل Advocat $count ردًا مُعدًّا عبر Gmail المتصل بك. كل رد يُرسَل بشكل مستقل — إذا فشل أحدها، تُرسَل البقية مع ذلك.';
  }

  @override
  String parallelActionsSentToast(int count) {
    return 'تم إرسال $count.';
  }

  @override
  String parallelActionsPartialFailureToast(int sent, int failed) {
    return 'تم إرسال $sent، وفشل $failed.';
  }

  @override
  String get parallelActionsKindReply => 'رد';

  @override
  String get parallelActionsKindNew => 'جديد';

  @override
  String get parallelActionsCheckboxSelected => 'تم تحديد الإجراء';

  @override
  String get parallelActionsCheckboxUnselected => 'لم يتم تحديد الإجراء';

  @override
  String parallelActionsCitationCount(int count) {
    return '$count اقتباس';
  }

  @override
  String parallelActionsRetryFailed(int count) {
    return 'إعادة محاولة الفاشلة ($count)';
  }

  @override
  String get agentApprovalNeedsReviewTitle => 'يحتاج Advocat إلى موافقتك';

  @override
  String get agentApprovalResolvedTitle => 'تم حلّ الإجراء';

  @override
  String get agentApprovalStepsLabel => 'خطوات';

  @override
  String get agentApprovalApproveButton => 'الموافقة والإرسال';

  @override
  String get agentApprovalDeclineButton => 'رفض';

  @override
  String get agentApprovalAttachmentsLabel => 'المرفقات';

  @override
  String get agentApprovalSentSummary => 'تم الإرسال نيابةً عنك.';

  @override
  String get agentApprovalDeclinedSummary => 'تم الرفض — لم يُرسَل أي شيء.';

  @override
  String get agentToolDraftEmailAtt => 'إرسال بريد إلكتروني مع مرفقات';

  @override
  String get agentToolSendEmail => 'إرسال بريد إلكتروني';

  @override
  String get agentToolGeneratePdf => 'إنشاء PDF';

  @override
  String get agentToolApproveSend => 'إرسال الرد المُعدّ';

  @override
  String get inboxErrorTitle => 'تعذّر تحميل صندوق الوارد';

  @override
  String get inboxEditDiscardTitle => 'تجاهل التعديلات غير المحفوظة؟';

  @override
  String get inboxEditDiscardBody =>
      'لديك تغييرات غير محفوظة على هذه المسودة. الرجوع سيؤدي إلى تجاهلها.';

  @override
  String get inboxEditKeepEditing => 'متابعة التعديل';

  @override
  String get inboxEditDiscard => 'تجاهل';

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
  String get plannerSettingsTitle => 'التفكير القانوني بثلاث مراحل';

  @override
  String get plannerSettingsSubtitle =>
      'تخطيط ← إجابة ← نقد. أبطأ لكنه أكثر شمولًا.';

  @override
  String get plannerSettingsProBadge => 'Pro';

  @override
  String get plannerSettingsProDescription => 'متاح في خطة Pro';

  @override
  String get plannerTrailHeaderPlan => 'الخطة';

  @override
  String get plannerTrailHeaderCritique => 'النقد';

  @override
  String get plannerTrailSubQuestions => 'الأسئلة الفرعية';

  @override
  String get plannerTrailCounterArgs => 'الحجج المضادة';

  @override
  String get plannerTrailEvidenceGaps => 'ثغرات الأدلة';

  @override
  String get plannerTrailMaterialGapTrue => 'تم اكتشاف ثغرة جوهرية';

  @override
  String get plannerTrailRegeneratedBadge => 'أُعيد التوليد مرة واحدة';

  @override
  String get plannerTrailEmpty => 'لا عناصر';

  @override
  String get supportTitle => 'المساعدة';

  @override
  String get supportSubtitle => 'نرد عادةً خلال ساعة إلى ساعتين.';

  @override
  String get supportSearchPlaceholder => 'البحث في المساعدة…';

  @override
  String get supportStatusAllOk => 'جميع الأنظمة طبيعية';

  @override
  String get supportFaqWhatIs => 'ما هو Advocat؟';

  @override
  String get supportFaqHowSubscribe => 'كيف أشترك في Pro؟';

  @override
  String get supportFaqExportData => 'هل يمكنني تصدير بياناتي؟';

  @override
  String get supportFaqCancelAccount => 'إلغاء أو حذف الحساب';

  @override
  String get supportFaqTalkHuman => 'التحدث إلى شخص';

  @override
  String get supportContactEmail => 'البريد الإلكتروني';

  @override
  String get supportContactTelegram => 'Telegram';

  @override
  String get supportContactWhatsapp => 'WhatsApp';

  @override
  String get supportFooterSla => 'نرد خلال 24 ساعة';

  @override
  String get supportWhatsapp => 'WhatsApp';

  @override
  String get supportEmail => 'البريد الإلكتروني';

  @override
  String get supportInApp => 'راسلنا هنا';

  @override
  String get supportCategoryLabel => 'الفئة';

  @override
  String get supportCategoryBug => 'خلل';

  @override
  String get supportCategoryPayment => 'مشكلة في الدفع';

  @override
  String get supportCategoryQuestion => 'سؤال';

  @override
  String get supportCategoryFeature => 'طلب ميزة';

  @override
  String get supportCategoryOther => 'أخرى';

  @override
  String get supportMessagePlaceholder => 'صِف مشكلتك...';

  @override
  String get supportEmailLabel => 'البريد الإلكتروني (اختياري)';

  @override
  String get supportSend => 'إرسال';

  @override
  String get supportSentSuccess => 'تم إرسال الرسالة! سنرد قريبًا.';

  @override
  String get supportError => 'حدث خطأ ما. حاول مرة أخرى.';

  @override
  String get supportErrorTooShort => 'يرجى كتابة 10 أحرف على الأقل.';

  @override
  String get supportErrorTooLong => 'بحد أقصى 2000 حرف.';

  @override
  String get supportPrivacyNotice => 'تُخزَّن رسالتك بشكل آمن.';

  @override
  String get reviewThisContract => 'راجع هذا العقد';

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
      other: 'تبقت $count مراجعات عقود هذا الشهر',
      one: 'تبقت مراجعة عقد واحدة هذا الشهر',
      zero: 'لا توجد مراجعات عقود متبقية هذا الشهر',
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
  String get referralTitle => 'ادعُ الأصدقاء';

  @override
  String get referralSubtitle => 'احصل على شهر مجاني. اهدِ شهرًا مجانيًا.';

  @override
  String get referralYourLink => 'رابطك';

  @override
  String get referralCopyLink => 'نسخ الرابط';

  @override
  String get referralShare => 'مشاركة';

  @override
  String get referralLinkCopied => 'تم نسخ الرابط';

  @override
  String get referralStatsInvited => 'المدعوون';

  @override
  String get referralStatsConverted => 'المشتركون';

  @override
  String get referralStatsEarned => 'أشهر مجانية';

  @override
  String get referralShareWhatsApp => 'مشاركة عبر واتساب';

  @override
  String get referralShareTelegram => 'مشاركة عبر تيليجرام';

  @override
  String get referralShareEmail => 'مشاركة عبر البريد';

  @override
  String get referralEmailSubject =>
      'جرّب Advocat — مساعدك القانوني بالذكاء الاصطناعي';

  @override
  String get referralLoadError => 'تعذّر تحميل البيانات. اسحب للتحديث.';

  @override
  String get referralRetry => 'أعد المحاولة';

  @override
  String get referralSettingsTile => 'ادعُ الأصدقاء';

  @override
  String get referralAfterReviewCta =>
      'أعجبك؟ ادعُ صديقًا — كلاكما يحصل على شهر مجاني.';

  @override
  String get referralAntiFraud => 'بحد أقصى 12 إحالة ناجحة سنويًا.';

  @override
  String get referralEmpty => 'لا توجد إحالات بعد. أرسل رابطك لتبدأ في الكسب.';

  @override
  String get referralRecentActivity => 'النشاط الأخير';

  @override
  String referralActivityInvited(String when) {
    return 'تمت الدعوة $when';
  }

  @override
  String referralActivityActivated(String when) {
    return 'تم التفعيل $when';
  }

  @override
  String get referralActivityPending => 'لم يتم التفعيل بعد';

  @override
  String referralStatsInvitedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أصدقاء',
      one: 'صديقًا واحدًا',
      zero: 'لا أصدقاء بعد',
    );
    return 'لقد دعوت $_temp0';
  }

  @override
  String referralStatsConvertedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'فعّل $count',
      one: 'فعّل واحد',
      zero: 'لم يُفعّل أحد بعد',
    );
    return '$_temp0';
  }

  @override
  String referralStatsEarnedCount(int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months أشهر مجانية',
      one: 'شهر مجاني واحد',
      zero: 'لا شيء بعد',
    );
    return 'مكافأتك: $_temp0';
  }

  @override
  String get referralNudgeMessage =>
      'هل أعجبك Advocat؟ ادعُ صديقًا — يحصل كلاكما على شهر مجاني.';

  @override
  String get referralNudgeAction => 'دعوة';

  @override
  String get referralLandingTitle => 'لقد تمت دعوتك إلى Advocat';

  @override
  String referralLandingSubtitle(String inviterName) {
    return 'دعاك $inviterName — احصل على شهرك الأول مجانًا.';
  }

  @override
  String get referralLandingSubtitleGeneric =>
      'احصل على شهرك الأول مجانًا من Advocat Pro.';

  @override
  String get referralLandingCta => 'تفعيل الشهر المجاني والتسجيل';

  @override
  String get referralLandingCtaSecondary => 'أو تعرّف على المزيد حول Advocat';

  @override
  String get referralLandingFallback =>
      'انتهت صلاحية هذا الرابط — لكن لا يزال بإمكانك تجربة Advocat مجانًا.';

  @override
  String get referralLandingBenefits =>
      '17 لغة • قانون إستوني وفنلندي وأوروبي حقيقي • على مدار الساعة — دون انتظار';

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
  String get sensitiveConsentTitle => 'موافقة على البيانات الحساسة';

  @override
  String get sensitiveConsentBody =>
      'قد تحتوي المستندات التي توشك على رفعها على بيانات شخصية من فئة خاصة بموجب المادة 9 من GDPR — مثل السجلات الصحية والسجلات الجنائية والبيانات البيومترية أو معلومات حول أصلك العرقي أو دينك أو ميولك الجنسية.\n\nنحن نعالج هذه البيانات فقط لتزويدك بمساعدة قانونية بالذكاء الاصطناعي، ونخزّنها مشفّرة في حسابك الخاص، ولا نستخدمها أبدًا لتدريب النماذج. يمكنك سحب الموافقة وحذف البيانات في أي وقت من الإعدادات.\n\nبقبولك، فإنك تمنح موافقة صريحة بموجب المادة 9(2)(أ) من GDPR لمعالجة بيانات الفئة الخاصة لهذا الغرض.';

  @override
  String get sensitiveConsentExplicitCheckbox =>
      'أمنح موافقة صريحة على معالجة بيانات الفئة الخاصة (المادة 9(2)(أ) من GDPR).';

  @override
  String get sensitiveConsentRightToShareCheckbox =>
      'أؤكّد أن لديّ الحق في مشاركة هذه البيانات (البيانات تخصّني، أو لديّ أساس قانوني/إعلامي لمشاركة بيانات طرف ثالث).';

  @override
  String get sensitiveConsentViewCategories => 'اعرض ما يُعدّ حساسًا ←';

  @override
  String get sensitiveConsentWithdrawAction =>
      'سحب الموافقة على البيانات الحساسة';

  @override
  String get privacyAndData => 'الخصوصية والبيانات';

  @override
  String get exportMyDataSubtitle =>
      'نزّل نسخة من جميع بياناتك الشخصية (المادة 15 من GDPR).';

  @override
  String get withdrawSensitiveConsent => 'موافقة على البيانات الحساسة';

  @override
  String get withdrawSensitiveConsentSubtitle =>
      'إدارة أو سحب الموافقة على معالجة بيانات الفئة الخاصة (المادة 9(2)(أ) من GDPR).';

  @override
  String get dataProcessingAgreement => 'اتفاقية معالجة البيانات';

  @override
  String get exportingData => 'يتم تصدير بياناتك…';

  @override
  String get exportComplete => 'تصدير البيانات جاهز — تم الحفظ على جهازك.';

  @override
  String get exportFailed =>
      'فشل التصدير. يرجى المحاولة مرة أخرى أو التواصل مع الدعم.';

  @override
  String get quotaExhaustedTitle => 'تم بلوغ حد الرسائل المجانية';

  @override
  String quotaExhaustedBody(int count) {
    return 'لقد استخدمت جميع الرسائل المجانية الـ$count. قم بالترقية إلى Advocat Counsel مقابل 19.99€/شهريًا واحصل على استشارات قانونية غير محدودة بالذكاء الاصطناعي.';
  }

  @override
  String get quotaExhaustedLater => 'لاحقًا';

  @override
  String get quotaExhaustedUpgrade => 'Advocat Counsel — 19.99€/شهريًا';

  @override
  String quotaCtaMessage(int count) {
    return 'لقد استخدمت جميع الرسائل المجانية الـ$count. قم بالترقية إلى Advocat Counsel مقابل 19.99€/شهريًا.';
  }

  @override
  String get quotaCtaButton => 'احصل على Advocat Counsel — 19.99€/شهريًا';

  @override
  String get aiErrorQuota =>
      'تم بلوغ حد الرسائل المجانية. اشترك لمتابعة استخدام الذكاء الاصطناعي.';

  @override
  String get aiErrorAuth =>
      'تسجيل الدخول مطلوب لاستخدام الذكاء الاصطناعي. يرجى التسجيل أو تسجيل الدخول.';

  @override
  String get aiErrorGeneric =>
      'خطأ مؤقت في الذكاء الاصطناعي. يرجى المحاولة مرة أخرى بعد دقيقة. إذا استمرت المشكلة، تواصل مع الدعم.';

  @override
  String get tooltipShareCase => 'مشاركة ملخّص القضية';

  @override
  String get tooltipMuteVoice => 'كتم الصوت';

  @override
  String get tooltipUnmuteVoice => 'إلغاء كتم الصوت';

  @override
  String get tooltipAttachDoc => 'إرفاق مستند';

  @override
  String get aiTypingHint => 'الذكاء الاصطناعي…';

  @override
  String get error404Title => 'الصفحة غير موجودة';

  @override
  String error404Body(String path) {
    return 'تعذّر علينا العثور على: $path';
  }

  @override
  String get goToHome => 'الذهاب إلى الصفحة الرئيسية';

  @override
  String get emailAlreadyRegistered =>
      'هذا البريد الإلكتروني مسجّل بالفعل. هل تريد تسجيل الدخول؟';

  @override
  String get actionSignIn => 'تسجيل الدخول';

  @override
  String get actionUndo => 'تراجع';

  @override
  String get intakeUrgentOpened => 'تم فتح المحادثة — تم حفظ مسودتك.';

  @override
  String get panicCoachmark => 'اضغط مطوّلًا للحصول على مساعدة طارئة.';

  @override
  String get panicTitle => 'ماذا تحتاج الآن؟';

  @override
  String get panicCardReadAloud => 'اقرأ بصوت عالٍ للضابط';

  @override
  String get panicCardRecord => 'سجّل هذه المحادثة';

  @override
  String get panicCardCall => 'اتصل بمحامٍ';

  @override
  String get panicCardAi => 'تحدّث مع Advocat الآن';

  @override
  String get panicClose => 'إغلاق';

  @override
  String get panicBadgeV2 => 'V2';

  @override
  String get panicRecordV1Title => 'قريبًا في V2';

  @override
  String get panicRecordV1Body =>
      'تخضع ميزة التسجيل للتحقق القانوني في إستونيا وستُطرح في V2. في الوقت الحالي، استخدم مسجّل الصوت المدمج في هاتفك.';

  @override
  String get panicCallFallbackBody =>
      'أرسل بريدًا إلكترونيًا إلى kiire@advocat.ee مع وصف موجز وسنعاود الاتصال بك.';

  @override
  String get consiliumHeader => 'مجلس المحامين';

  @override
  String consiliumProgress(int count, int total) {
    return '$count من $total جاهز';
  }

  @override
  String get consiliumStarting => 'يقوم المحامون بمراجعة قضيتك…';

  @override
  String get consiliumDisagreement => 'الخبراء غير متفقين';

  @override
  String get consiliumSynthesizing => 'جارٍ صياغة التوصية…';

  @override
  String consiliumDone(int totalRoles) {
    return 'اكتمل المجلس · $totalRoles خبراء';
  }

  @override
  String get consiliumPositionPush => 'اعترض';

  @override
  String get consiliumPositionSettle => 'تسوية';

  @override
  String get consiliumPositionInvestigate => 'تحقق';

  @override
  String get consiliumPositionOutOfScope => 'خارج نطاق الاختصاص';

  @override
  String get consiliumConfidence => 'الثقة';

  @override
  String get consiliumKeyCitation => 'المرجع الأساسي';

  @override
  String get consiliumAdversarialRound => 'جولة جدلية';

  @override
  String get consiliumViewFullOpinion => 'عرض الرأي كاملاً';

  @override
  String consiliumExpertsAgreed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count خبراء موافقون',
      one: 'خبير واحد موافق',
    );
    return '$_temp0';
  }

  @override
  String consiliumExpertsDisagree(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count خبراء غير موافقين',
      one: 'خبير واحد غير موافق',
    );
    return '$_temp0';
  }

  @override
  String get consiliumDisclaimer =>
      'وكلاء ذكاء اصطناعي، وليسوا محامين بشريين. تحقق من القرارات الجوهرية مع محامٍ مرخَّص.';

  @override
  String get softCaseShellBanner =>
      'أنشأنا “قضية بلا عنوان” لتتبّع هذا. اضغط لإعادة التسمية.';

  @override
  String get softCaseShellBannerCta => 'إعادة التسمية';

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
  String get iapPayWithApple => 'ادفع باستخدام Apple';

  @override
  String get iapRestorePurchases => 'استعادة المشتريات';

  @override
  String get iapPurchaseFailed =>
      'فشلت عملية الشراء. يرجى المحاولة مرة أخرى أو التواصل مع الدعم.';

  @override
  String get iapRestoreSuccess => 'تمت استعادة اشتراكك.';

  @override
  String get iapRestoreNoActive => 'لم يتم العثور على اشتراك نشط للاستعادة.';

  @override
  String get deadlineEuRadarTitle => 'EU deadline radar (preview)';

  @override
  String get deadlineEuRadarSubtitle =>
      'Hypothetical EU procedural deadlines — mock data';

  @override
  String get changePassword => 'تغيير كلمة المرور';

  @override
  String get changePasswordSubtitle => 'حدّث كلمة مرور حسابك';

  @override
  String get newPasswordTitle => 'تعيين كلمة مرور جديدة';

  @override
  String get newPasswordHint => 'أدخل كلمة مرور جديدة لحسابك وأكّدها.';

  @override
  String get newPasswordSave => 'حفظ كلمة المرور الجديدة';

  @override
  String get newPasswordSuccess =>
      'تم تحديث كلمة المرور. يمكنك الآن استخدامها لتسجيل الدخول.';

  @override
  String get newPasswordError =>
      'فشل تحديث كلمة المرور. يرجى المحاولة مرة أخرى.';

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
}
