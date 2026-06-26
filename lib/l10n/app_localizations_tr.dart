// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get about => 'Hakkında';

  @override
  String get aboutSection => 'HAKKINDA';

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
  String get accidents => 'Kazalar';

  @override
  String get active => 'Aktif';

  @override
  String get activeCases => 'Aktif Davalar';

  @override
  String get addedToAppeal => 'İtiraza eklendi';

  @override
  String get agreeToTerms => 'Kabul ediyorum: ';

  @override
  String get aiAnalysis => 'Yapay Zeka Analizi';

  @override
  String get aiAssistant => 'Yapay Zeka Hukuk Asistanı';

  @override
  String get aiChat => 'Yapay Zeka Sohbet';

  @override
  String get all => 'Tümü';

  @override
  String get alreadyHaveAccount => 'Zaten hesabınız var mı? ';

  @override
  String get analyzing => 'Analiz ediliyor…';

  @override
  String get aiAnalyzing => 'Yapay zeka analiz ediyor';

  @override
  String get speakIntoMicHint =>
      'Mikrofona konuşun. Mikrofon erişiminin etkin olduğundan emin olun.';

  @override
  String get aiErrorRateLimit =>
      'Hizmet geçici olarak aşırı yüklü. Lütfen 1-2 dakika içinde tekrar deneyin.';

  @override
  String get aiErrorOverload =>
      'Yapay zeka şu anda meşgul, lütfen bir dakika içinde tekrar deneyin.';

  @override
  String freeLimitReached(int count) {
    return '$count ücretsiz yapay zeka mesajının tamamını kullandınız. Sınırsız yapay zeka desteği için Legal Counsel paketine yükseltin!';
  }

  @override
  String get andWord => ' ve ';

  @override
  String get appTitle => 'Advocat — Hukuki Bilgi Aracı';

  @override
  String get appVersion => 'Uygulama Sürümü';

  @override
  String get appealFiled => 'İtiraz Sunuldu';

  @override
  String get areYouAbsolutelySure => 'Kesinlikle emin misiniz?';

  @override
  String get askAboutCase => 'Davamı analiz et';

  @override
  String get asylum => 'İltica';

  @override
  String get back => 'Geri';

  @override
  String get basic => 'Temel';

  @override
  String get beforeYouBuy => 'Satın almadan önce';

  @override
  String get beforeYouWork => 'Onlarla çalışmadan önce';

  @override
  String get camera => 'Kamera';

  @override
  String get cancel => 'İptal';

  @override
  String get caseDescription => 'Durumunuzu açıklayın';

  @override
  String get caseDetail => 'Dava Detayları';

  @override
  String get caseOverview => 'İşte dava özetiniz';

  @override
  String get caseTitle => 'Dava Başlığı';

  @override
  String get caseUpdated => 'Dava güncellendi';

  @override
  String get cases => 'Davalar';

  @override
  String get checkCompany => 'Şirketi Kontrol Et';

  @override
  String get checkDeadlines => 'Süreleri kontrol et';

  @override
  String get checkVehicle => 'Aracı Kontrol Et';

  @override
  String get checkerTitle => 'Denetleyici';

  @override
  String get checkingErrors => 'Hatalar kontrol ediliyor…';

  @override
  String get choosePlan => 'Plan Seç';

  @override
  String get closed => 'Kapalı';

  @override
  String get companyName => 'Şirket adı veya sicil numarası';

  @override
  String get completed => 'Tamamlanmış';

  @override
  String get confirm => 'Onayla';

  @override
  String get confirmPassword => 'Şifreyi Onayla';

  @override
  String get connectEmail => 'E-posta Bağla';

  @override
  String get connectGmail => 'Gmail Bağla';

  @override
  String get connectOutlook => 'Outlook Bağla';

  @override
  String get connected => 'Bağlı';

  @override
  String get contactSupport => 'Destek ile İletişime Geçin';

  @override
  String get continueWithGoogle => 'Google ile Devam Et';

  @override
  String get appleComingSoon => 'Yakında';

  @override
  String get appleComingSoonMessage =>
      'Apple ile Giriş yakında kullanıma sunulacak. Devam etmek için Google veya e-posta kullanın.';

  @override
  String get copyText => 'Metni kopyala';

  @override
  String get correspondence => 'Yazışma';

  @override
  String get couldNotLoadCases => 'Davalarınız yüklenemedi';

  @override
  String get country => 'Ülke';

  @override
  String get createAccount => 'Hesap Oluştur';

  @override
  String get createCase => 'Dava Oluştur';

  @override
  String get criminalCase => 'Ceza Davası';

  @override
  String get critical => 'Kritik';

  @override
  String get currentPlan => 'Mevcut Plan';

  @override
  String get dataAndPrivacy => 'VERİ VE GİZLİLİK';

  @override
  String get dataExportRequested =>
      'Veri dışa aktarması talep edildi. E-postanızı kontrol edin.';

  @override
  String daysRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gün',
      zero: 'kalan gün yok',
    );
    return '$_temp0';
  }

  @override
  String get deadlineReminders => 'Süre Hatırlatmaları';

  @override
  String get deadlineRemindersDesc => 'Süreler öncesinde bildirim alın';

  @override
  String get deadlines => 'Süreler';

  @override
  String get debtCollection => 'Alacak Tahsilatı';

  @override
  String get deleteAccount => 'Hesabı Sil';

  @override
  String get deleteAccountDesc => 'Hesabınızı kalıcı olarak kaldırın';

  @override
  String get deleteAccountDialogContent =>
      'Bu işlem kalıcıdır ve geri alınamaz. Tüm verileriniz, davalarınız ve belgeleriniz kalıcı olarak silinecektir.';

  @override
  String get deleteConfirm =>
      'Emin misiniz? Tüm verileriniz kalıcı olarak silinecektir.';

  @override
  String get demoHint => 'Demo: “908FBT” plakasını deneyin';

  @override
  String get demoModeDesc =>
      'Gerçek bir davadan örnek verilerle uygulamayı keşfedin';

  @override
  String get deportation => 'Sınır dışı etme';

  @override
  String get disclaimer =>
      'Yalnızca yapay zeka rehberliği — hukuki danışmanlık değildir. Her zaman bir avukata danışın.';

  @override
  String get disclaimerFull =>
      'Bu bir yapay zeka asistanıdır, avukat değildir. Yapay zeka analizi hata içerebilir. Her zaman yetkin bir hukukçu ile doğrulayın.';

  @override
  String get disconnect => 'Bağlantıyı Kes';

  @override
  String get discrimination => 'Ayrımcılık';

  @override
  String get doNotBuy => 'Satın almayın';

  @override
  String get documents => 'Belgeler';

  @override
  String documentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count belge',
      zero: 'belge yok',
    );
    return '$_temp0';
  }

  @override
  String get draftAppeal => 'İtiraz Taslağı';

  @override
  String get editDraft => 'Düzenle';

  @override
  String get editProfile => 'Profili Düzenle';

  @override
  String get email => 'E-posta';

  @override
  String get emailConnected => 'E-posta bağlandı';

  @override
  String get emailDisconnected => 'E-posta bağlantısı kesildi';

  @override
  String get emailIntegration => 'E-POSTA ENTEGRASYONU';

  @override
  String get emailInvalid => 'Geçerli bir e-posta adresi girin';

  @override
  String get emailPrivacyNote =>
      'Yalnızca hukuki konularla ilgili e-postaları okuyoruz. Kişisel e-postalarınız gizli kalır.';

  @override
  String get emailRequired => 'E-posta gereklidir';

  @override
  String get emergencyShield => 'Acil Durum Kalkanı';

  @override
  String get error => 'Hata';

  @override
  String get exportDataDesc => 'Tüm dava verilerinizi indirin';

  @override
  String get exportDataDialogContent =>
      'Davalar, belgeler ve yazışmalar dahil tüm verilerinizin bir indirmesini hazırlayacağız. Hazır olduğunda bir e-posta alacaksınız.';

  @override
  String get exportMyData => 'Verilerimi Dışa Aktar';

  @override
  String get exportPdf => 'PDF olarak dışa aktar';

  @override
  String get familyReunification => 'Aile Birleşimi';

  @override
  String get forgotPassword => 'Şifremi Unuttum?';

  @override
  String get free => 'Ücretsiz';

  @override
  String get fullDefense => 'Advocat Pro';

  @override
  String get fullName => 'Ad Soyad';

  @override
  String get gallery => 'Galeri';

  @override
  String get generateAppeal => 'İtiraz oluştur';

  @override
  String get getStarted => 'Başla';

  @override
  String goodAfternoon(String name) {
    return 'İyi günler, $name';
  }

  @override
  String goodEvening(String name) {
    return 'İyi akşamlar, $name';
  }

  @override
  String goodMorning(String name) {
    return 'Günaydın, $name';
  }

  @override
  String goodNight(String name) {
    return 'İyi geceler, $name';
  }

  @override
  String get home => 'Ana Sayfa';

  @override
  String get important => 'Önemli';

  @override
  String get inProgress => 'Devam Ediyor';

  @override
  String get informational => 'Bilgilendirici';

  @override
  String get inspection => 'Teknik muayene';

  @override
  String get insurance => 'Sigorta';

  @override
  String issuesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sorun bulundu',
      zero: 'sorun bulunamadı',
    );
    return '$_temp0';
  }

  @override
  String get laborDispute => 'İşçi Uyuşmazlığı';

  @override
  String get langEnglish => 'İngilizce';

  @override
  String get langFinnish => 'Fince';

  @override
  String get langRussian => 'Rusça';

  @override
  String get language => 'Dil';

  @override
  String lastActivity(String time) {
    return 'Son aktivite: $time';
  }

  @override
  String get legalFighter => 'Hukuk Savaşçısı';

  @override
  String get legalSection => 'HUKUKİ';

  @override
  String get licensePlate => 'Plaka';

  @override
  String get loading => 'Yükleniyor…';

  @override
  String get logIn => 'Giriş Yap';

  @override
  String get loginFailed =>
      'Geçersiz e-posta veya şifre. Lütfen tekrar deneyin.';

  @override
  String get lost => 'Kaybedildi';

  @override
  String get markComplete => 'Tamamlandı olarak işaretle';

  @override
  String get mileage => 'Kilometre';

  @override
  String get myCases => 'Davalarım';

  @override
  String get nameRequired => 'Ad soyad gereklidir';

  @override
  String get newCase => 'Yeni Dava';

  @override
  String get next => 'İleri';

  @override
  String get noAccount => 'Hesabınız yok mu? ';

  @override
  String get noCases => 'Henüz dava yok';

  @override
  String get noCasesYet => 'Henüz dava yok';

  @override
  String get noDeadlines => 'Süre yok — her şey yolunda!';

  @override
  String get noRecentActivity => 'Son aktivite yok';

  @override
  String get notifications => 'BİLDİRİMLER';

  @override
  String get onboardingDesc1 =>
      'Advocat hukuki durumunuzu anlamanıza yardımcı olur. Yapay zeka araçları belgeleri analiz eder, olası sorunları belirler ve incelemeniz için belge taslakları hazırlar. Bir hukuk bürosu değil — davanızı destekleyen bir teknoloji aracıdır.';

  @override
  String get onboardingDesc2 =>
      'Herhangi bir hukuki belgeyi fotoğraflayın. Yapay zeka onu birden fazla dilde okur, temel verileri çıkarır ve AB direktifleri ile ulusal yasalara uygunluğu kontrol eder.';

  @override
  String get onboardingDesc3 =>
      'Yapay zeka araçlarımız 40’dan fazla usul gereksinimi türünü kontrol eder. Yapay zeka analizi dikkat gerektiren sorunları tespit edebilir — tebligat dili, usul adımları ve yasal süreler gibi. Her zaman yetkin bir avukat ile doğrulayın.';

  @override
  String get onboardingDesc4 =>
      'Yapay zeka, incelemeniz için hukuki referanslarla itiraz, şikayet ve mektup taslakları hazırlar. Ne sunacağınıza siz karar verirsiniz. Her belge, sunulmadan önce yetkin bir hukukçu tarafından incelenmelidir.';

  @override
  String get onboardingNext => 'İleri';

  @override
  String get onboardingSkip => 'Atla';

  @override
  String get onboardingTitle1 => 'Yapay Zeka Destekli Hukuki Bilgi';

  @override
  String get onboardingTitle2 => 'Belgeleri Tarayın ve Analiz Edin';

  @override
  String get onboardingTitle3 => 'Yapay Zeka Olası Sorunları Kontrol Eder';

  @override
  String get onboardingTitle4 => 'İncelemeniz İçin Belge Taslakları';

  @override
  String get openACase => 'Dava Aç';

  @override
  String get optional => '(isteğe bağlı)';

  @override
  String get orDivider => 'veya';

  @override
  String get other => 'Diğer';

  @override
  String get overdue => 'Gecikmiş';

  @override
  String get owners => 'Önceki sahipler';

  @override
  String get password => 'Şifre';

  @override
  String get passwordRequired => 'Şifre gereklidir';

  @override
  String get passwordStrengthMedium => 'Orta';

  @override
  String get passwordStrengthStrong => 'Güçlü';

  @override
  String get passwordStrengthWeak => 'Zayıf';

  @override
  String get passwordTooShort => 'Şifre en az 8 karakter olmalıdır';

  @override
  String get passwordsDoNotMatch => 'Şifreler eşleşmiyor';

  @override
  String get pendingDecision => 'Karar Bekleniyor';

  @override
  String get perCheck => 'kontrol başına';

  @override
  String get permanentlyDelete => 'Kalıcı Olarak Sil';

  @override
  String get policeMisconduct => 'Polis Suçu';

  @override
  String get popular => 'POPÜLER';

  @override
  String get preferences => 'TERCİHLER';

  @override
  String get preferredLanguage => 'Tercih Edilen Dil';

  @override
  String get pricePerCheck => '€4,99 kontrol başına';

  @override
  String get privacyPolicy => 'Gizlilik Politikası';

  @override
  String get dpaTitle => 'Veri İşleme Sözleşmesi';

  @override
  String get dpaCheckoutGateTitle => 'Yükseltmeden önce';

  @override
  String get dpaCheckoutGateBody =>
      'AB hukuku (GDPR Madde 28) her ödeme yapan müşteriyle bir Veri İşleme Sözleşmesi imzalamamızı gerektirir. Lütfen inceleyip kabul edin.';

  @override
  String get dpaViewLink => 'Veri İşleme Sözleşmesini görüntüle';

  @override
  String get dpaCheckboxLabel =>
      'Veri İşleme Sözleşmesini (v1.0) okudum ve kabul ediyorum.';

  @override
  String get dpaCancel => 'İptal';

  @override
  String get dpaAcceptAndContinue => 'Kabul et ve devam et';

  @override
  String get dpaOpenHint =>
      'Kabul Et düğmesini etkinleştirmek için DPA\'yı en az bir kez açın.';

  @override
  String get pro => 'Pro';

  @override
  String get pushNotifications => 'Anlık Bildirimler';

  @override
  String get rateUs => 'Bizi Değerlendirin';

  @override
  String get rateAppComingSoon => 'Yakında uygulama mağazalarında!';

  @override
  String get dataCopiedToClipboard => 'Veriler panoya kopyalandı';

  @override
  String get readingDocument => 'Belge okunuyor…';

  @override
  String get recentActivity => 'Son Aktivite';

  @override
  String get referenceNumber => 'Referans Numarası';

  @override
  String get registerFailed => 'Kayıt başarısız oldu. Lütfen tekrar deneyin.';

  @override
  String get reportFraud => 'Dolandırıcılığı Bildirin';

  @override
  String get requestExport => 'Dışa Aktarma Talep Et';

  @override
  String get researchingLaw => 'Uygulanabilir yasa araştırılıyor…';

  @override
  String get resetPasswordFailed =>
      'Bağlantı gönderilemedi. Lütfen tekrar deneyin.';

  @override
  String get resetPasswordSent =>
      'Şifre sıfırlama bağlantısı e-postanıza gönderildi.';

  @override
  String get residencePermit => 'Oturma İzni';

  @override
  String get manageSubscription => 'Aboneliği yönet';

  @override
  String get restorePurchases => 'Satın Almaları Geri Yükle';

  @override
  String get retry => 'Tekrar Dene';

  @override
  String get reviewWarning =>
      'Göndermeden önce dikkatlice inceleyin. İçerikten siz sorumlusunuz.';

  @override
  String get riskHigh => 'Yüksek risk — kaçının';

  @override
  String get riskLow => 'Çalışmak için güvenli';

  @override
  String get riskMedium => 'Dikkatli olun';

  @override
  String get safeToBuy => 'Satın almak güvenli';

  @override
  String get saveAndAnalyze => 'Kaydet ve Analiz Et';

  @override
  String get saveDraft => 'Kaydet';

  @override
  String get saveWithAnnual => 'Yıllık faturalandırma ile %25 tasarruf edin';

  @override
  String get scan => 'Tara';

  @override
  String get scanDocument => 'Belge Tara';

  @override
  String get searchCases => 'Dava ara…';

  @override
  String get selectCountry => 'Ülke seçin';

  @override
  String get selectLanguage => 'Dil Seçin';

  @override
  String get sendViaEmail => 'E-posta ile gönder';

  @override
  String get settings => 'Ayarlar';

  @override
  String get signIn => 'Giriş Yap';

  @override
  String get signInLink => 'Giriş Yap';

  @override
  String get signInSubtitle => 'Davalarınıza erişmek için giriş yapın';

  @override
  String get signOut => 'Çıkış Yap';

  @override
  String get signOutConfirm => 'Çıkış yapmak istediğinizden emin misiniz?';

  @override
  String get signUp => 'Hesap Oluştur';

  @override
  String get signUpLink => 'Kayıt Ol';

  @override
  String get socialBenefits => 'Sosyal Yardımlar';

  @override
  String get someConcerns => 'Bazı endişeler';

  @override
  String get startFirstCase => 'İlk davanızı başlatın';

  @override
  String step(int current, int total) {
    return 'Adım $current / $total';
  }

  @override
  String get stolen => 'Çalıntı kontrolü';

  @override
  String get subscription => 'Abonelik';

  @override
  String get syncLegalCorrespondence => 'Hukuki yazışmayı senkronize et';

  @override
  String get syncNow => 'Şimdi Senkronize Et';

  @override
  String get tenantRights => 'Kiracı Hakları';

  @override
  String get termsOfService => 'Hizmet Koşulları';

  @override
  String get termsRequired => 'Hizmet Koşullarını kabul etmelisiniz';

  @override
  String get timeline => 'Zaman Çizelgesi';

  @override
  String get tryDemoMode => 'Demo Modunu Deneyin';

  @override
  String get typeDeleteToConfirm =>
      'Hesabın kalıcı olarak kaldırılmasını onaylamak için DELETE yazın.';

  @override
  String get typeMessage => 'Bir mesaj yazın…';

  @override
  String get upcoming => 'Yaklaşan';

  @override
  String get uploadDocument => 'Belge Yükle';

  @override
  String urgentDeadline(String title) {
    return 'Acil: $title';
  }

  @override
  String get useInAppeal => 'İtirazda kullan';

  @override
  String get vehicleChecker => 'Araç Denetleyici';

  @override
  String get vehicleChecks => 'Durum Kontrolleri';

  @override
  String get vehicleColor => 'Renk';

  @override
  String get vehicleMake => 'Marka';

  @override
  String get vehicleModel => 'Model';

  @override
  String get vehicleYear => 'Yıl';

  @override
  String get version => 'Sürüm';

  @override
  String get victimSupport => 'Mağdur Desteği';

  @override
  String get viewAll => 'Tümünü Gör';

  @override
  String get vinNumber => 'VIN numarası';

  @override
  String get welcomeBack => 'Tekrar Hoş Geldiniz';

  @override
  String get whatAreMyOptions => 'Seçeneklerim neler?';

  @override
  String get won => 'Kazanıldı';

  @override
  String get documentVault => 'Belge kasası';

  @override
  String get secureDocumentStorage => 'Güvenli belge deposu';

  @override
  String get secureDocumentStorageDesc =>
      'Önemli hukuki belgelerinizi tek bir yerde saklayın.';

  @override
  String get addDocument => 'Belge ekle';

  @override
  String get chooseHowToAdd => 'Belgenizi nasıl eklemek istediğinizi seçin';

  @override
  String get uploadFile => 'Dosya yükle';

  @override
  String get uploadFileDesc => 'Cihazınızdan bir PDF veya resim seçin';

  @override
  String get scanDocumentDesc => 'Belgenizin fotoğrafını çekin';

  @override
  String get createNote => 'Not oluştur';

  @override
  String get createNoteDesc => 'Not yazın veya önemli ayrıntıları kaydedin';

  @override
  String get knowYourRights => 'Haklarınızı bilin';

  @override
  String get stoppedByPolice => 'Polis tarafından durdurulma';

  @override
  String get stoppedByPoliceDesc => 'Polis kontrolünde haklarınız';

  @override
  String get deportationNotice => 'Sınır dışı bildirimi';

  @override
  String get deportationNoticeDesc => 'Sınır dışı kararına itiraz adımları';

  @override
  String get workplaceRights => 'İşyeri hakları';

  @override
  String get workplaceRightsDesc => 'Finlandiya\'da iş hukuku korumaları';

  @override
  String get tenantRightsDesc => 'Konut ve kiracı korumaları';

  @override
  String get immigrationDetention => 'Göçmen gözaltısı';

  @override
  String get immigrationDetentionDesc =>
      'Yetkililer tarafından gözaltına alındığınızda haklar';

  @override
  String get discriminationDesc =>
      'Ayrımcılığı nasıl bildirir ve mücadele edersiniz';

  @override
  String get scenarioNotFound => 'Senaryo bulunamadı';

  @override
  String get youHaveRightTo => 'Haklarınız:';

  @override
  String get youMust => 'Yapmanız gerekenler:';

  @override
  String get immediateSteps => 'Acil adımlar:';

  @override
  String get yourRights => 'Haklarınız:';

  @override
  String get basicRights => 'Temel haklar:';

  @override
  String get yourRightsAsTenant => 'Kiracı olarak haklarınız:';

  @override
  String get yourRightsInDetention => 'Gözaltında haklarınız:';

  @override
  String get howToAct => 'Nasıl hareket etmeli:';

  @override
  String get rightKnowWhyStopped => 'Neden durdurulduğunuzu bilmek';

  @override
  String get rightRemainSilent => 'Sessiz kalın (kimliğinizi belirtmelisiniz)';

  @override
  String get rightAskInterpreter => 'Tercüman isteyin';

  @override
  String get rightContactLawyer => 'Sorgulamadan önce avukatla iletişim';

  @override
  String get rightRecordEncounter =>
      'Karşılaşmayı kaydedin (kamusal alanlarda)';

  @override
  String get mustProvideName => 'Adınızı ve doğum tarihinizi belirtin';

  @override
  String get mustShowId => 'Varsa kimliğinizi gösterin';

  @override
  String get mustNotResist => 'Fiziksel direnç göstermemek';

  @override
  String get doNotIgnoreNotice =>
      'Bildirimi görmezden GELMEYİN - süreler kesindir';

  @override
  String get noteAppealDeadline =>
      'İtiraz süresini not edin (genellikle 30 gün)';

  @override
  String get contactLawyerImmediately => 'Hemen bir avukatla iletişime geçin';

  @override
  String get applyLegalAid => 'Gerekirse adli yardım başvurusu yapın';

  @override
  String get rightAppealAdmin => 'İdare Mahkemesine itiraz hakkı';

  @override
  String get rightLegalRep => 'Hukuki temsil hakkı';

  @override
  String get rightInterpreter => 'Tercüman hakkı';

  @override
  String get rightStayDuringAppeal =>
      'İtiraz sırasında kalma hakkı (çoğu durumda)';

  @override
  String get minimumWage => 'Toplu sözleşmeye göre asgari ücret';

  @override
  String get workingTimeLimits =>
      'Çalışma süresi sınırları (maks 8s/gün, 40s/hafta)';

  @override
  String get annualLeave => 'Yıllık izin (çalışılan her ay için en az 2 gün)';

  @override
  String get sickLeave => 'Hastalık izni tazminatı';

  @override
  String get safeWorkingConditions => 'Güvenli çalışma koşulları';

  @override
  String get writtenRentalAgreement => 'Yazılı kira sözleşmesi gerekli';

  @override
  String get securityDeposit => 'Depozito max 3 aylık kira';

  @override
  String get landlordNotice => 'Ev sahibi ihbar süresi vermeli (3–6 ay)';

  @override
  String get rightHabitableDwelling => 'Yaşanabilir bir konuta hak';

  @override
  String get protectionUnjustEviction => 'Haksız tahliyeye karşı koruma';

  @override
  String get rightKnowDetentionReason => 'Gözaltı nedenini bilme hakkı';

  @override
  String get rightContactLawyerDetention => 'Avukatla iletişim hakkı';

  @override
  String get rightContactEmbassy => 'Büyükelçiliğinizle iletişim hakkı';

  @override
  String get rightChallengeDetention => 'Gözaltına mahkemede itiraz hakkı';

  @override
  String get rightHumaneTreatment => 'İnsani muamele ve tıbbi bakım hakkı';

  @override
  String get documentIncident => 'Olayı belgeleyin (tarih, saat, tanıklar)';

  @override
  String get fileComplaintOmbudsman =>
      'Ayrımcılıkla Mücadele Ombudsmanına şikayette bulunun';

  @override
  String get contactLegalAidOffice => 'Adli yardım bürosuyla iletişime geçin';

  @override
  String get reportToPolice => 'Suçsa polise bildirin (tehdit, saldırı)';

  @override
  String get legalAidCalculator => 'Adli yardım hesaplayıcı';

  @override
  String checkEligibility(String country) {
    return '$country adli yardım uygunluğunuzu kontrol edin';
  }

  @override
  String get estimateDisclaimer =>
      'Bu sadece bir tahmindir. Gerçek uygunluk Adli Yardım Bürosu tarafından belirlenir.';

  @override
  String get monthlyIncome => 'Aylık gelir (EUR)';

  @override
  String get totalAssets => 'Toplam varlıklar (EUR)';

  @override
  String get numberOfDependents => 'Bakmakla yükümlü olunan kişi sayısı';

  @override
  String get calculateEligibility => 'Uygunluğu hesapla';

  @override
  String get likelyEligible => 'Muhtemelen uygun';

  @override
  String get mayNotQualify => 'Uygun olmayabilir';

  @override
  String get fullFreeLegalAid =>
      'Muhtemelen ücretsiz adli yardıma hak kazanıyorsunuz.';

  @override
  String legalAidWithCopay(String percent) {
    return '%$percent katkı payı ile adli yardıma hak kazanabilirsiniz.';
  }

  @override
  String get mayNotQualifyDesc =>
      'Bu tahmine göre devlet adli yardımına uygun olmayabilirsiniz.';

  @override
  String get couldNotLoadDeadlines => 'Süreler yüklenemedi';

  @override
  String get noUpcomingDeadlines => 'Yaklaşan süre yok';

  @override
  String get allClearDeadlines =>
      'Her şey yolunda! Yeni süreler belirlendiğinde burada görünecek.';

  @override
  String get nothingOverdue => 'Gecikmiş bir şey yok';

  @override
  String get greatJobDeadlines =>
      'Süreleri takip etmekte harika iş çıkarıyorsunuz.';

  @override
  String get noCompletedDeadlines => 'Tamamlanmış süre yok';

  @override
  String get completedDeadlinesDesc =>
      'Tamamlanan süreler burada gösterilecektir.';

  @override
  String get daysLate => 'gün gecikmiş';

  @override
  String get days => 'gün';

  @override
  String get fromDocument => 'Belgeden';

  @override
  String get couldNotLoadCase => 'Dava ayrıntıları yüklenemedi';

  @override
  String get typeLabel => 'Tür';

  @override
  String get nationality => 'Uyruk';

  @override
  String get migriReference => 'Migri referansı';

  @override
  String get courtCaseNo => 'Mahkeme dosya no';

  @override
  String get created => 'Oluşturuldu';

  @override
  String get citizenship => 'Vatandaşlık';

  @override
  String get workPermit => 'Çalışma izni';

  @override
  String get noDocumentsYet => 'Henüz belge yüklenmedi';

  @override
  String get noUpcomingDeadlinesShort => 'Yaklaşan süre yok';

  @override
  String get caseCreated => 'Dava oluşturuldu';

  @override
  String get decisionReceived => 'Karar alındı';

  @override
  String get appealDeadline => 'İtiraz süresi';

  @override
  String get hearingScheduled => 'Duruşma planlandı';

  @override
  String get late => 'gecikmiş';

  @override
  String get pending => 'Beklemede';

  @override
  String get processing => 'İşleniyor';

  @override
  String get ready => 'Hazır';

  @override
  String get failed => 'Başarısız';

  @override
  String get analyzed => 'Analiz edildi';

  @override
  String get noDocumentsScanHint => 'Henüz belge yok. Tarayın veya yükleyin.';

  @override
  String get inCourt => 'Mahkemede';

  @override
  String get appeal => 'İtiraz';

  @override
  String get caseTimeline => 'Dava zaman çizelgesi';

  @override
  String get couldNotLoadTimeline => 'Zaman çizelgesi yüklenemedi';

  @override
  String get noEventsYet => 'Henüz etkinlik yok';

  @override
  String get activityWillAppear =>
      'Davanız ilerledikçe etkinlikler burada görünecektir.';

  @override
  String caseCreatedDesc(String title) {
    return '“$title” davası oluşturuldu.';
  }

  @override
  String get decisionReceivedDesc => 'Bu dava için resmi bir karar alındı.';

  @override
  String get appealDeadlineSet => 'İtiraz süresi belirlendi';

  @override
  String appealDeadlineDesc(String date) {
    return 'İtiraz en geç $date tarihine kadar yapılmalıdır.';
  }

  @override
  String hearingScheduledDesc(String date) {
    return 'Mahkeme duruşması $date için planlandı.';
  }

  @override
  String get caseInfoUpdated => 'Dava bilgileri son güncelleme.';

  @override
  String get noEventsForFilter => 'Bu filtreye uyan olay yok';

  @override
  String get timelineFilterAll => 'Tümü';

  @override
  String get timelineFilterEmails => 'E-postalar';

  @override
  String get timelineFilterConsilium => 'Yapay zeka kararları';

  @override
  String get timelineFilterDeadlines => 'Son tarihler';

  @override
  String get timelineFilterNotes => 'Notlar';

  @override
  String get timelineEventEmailIn => 'E-posta alındı';

  @override
  String get timelineEventEmailOut => 'E-posta gönderildi';

  @override
  String get timelineEventConsiliumDecision => 'Yapay zeka kararı';

  @override
  String get timelineEventDeadlineSet => 'Son tarih';

  @override
  String get timelineEventDocUploaded => 'Belge';

  @override
  String get timelineEventPhaseChange => 'Aşama değişikliği';

  @override
  String get timelineEventManualNote => 'Not';

  @override
  String get timelineJustNow => 'Az önce';

  @override
  String timelineMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dakika önce',
      one: '1 dakika önce',
    );
    return '$_temp0';
  }

  @override
  String timelineHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saat önce',
      one: '1 saat önce',
    );
    return '$_temp0';
  }

  @override
  String timelineDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gün önce',
      one: '1 gün önce',
    );
    return '$_temp0';
  }

  @override
  String get documentAnalysis => 'Belge analizi';

  @override
  String get exportAsPdf => 'PDF olarak dışa aktar';

  @override
  String get pdfExportComingSoon => 'PDF dışa aktarma yakında';

  @override
  String get analysisFailedRetry => 'Analiz başarısız. Lütfen tekrar deneyin.';

  @override
  String get somethingWentWrong => 'Bir şeyler yanlış gitti';

  @override
  String get genericError => 'Bir şeyler ters gitti. Lütfen tekrar deneyin.';

  @override
  String get retryAnalysis => 'Analizi tekrarla';

  @override
  String issuesFoundInDocument(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Belgenizde $count sorun bulundu',
      zero: 'Belgenizde sorun bulunamadı',
    );
    return '$_temp0';
  }

  @override
  String get severityOverview => 'Ciddiyet genel bakışı';

  @override
  String get issuesFoundHeader => 'Bulunan sorunlar';

  @override
  String generateAppealWithIssues(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'İtiraz Oluştur ($count sorun)',
    );
    return '$_temp0';
  }

  @override
  String get analyzingContent => 'İçerik analiz ediliyor…';

  @override
  String get documentProcessedOk => 'Belge başarıyla işlendi';

  @override
  String get noSignificantIssues => 'Bu belgede önemli sorun tespit edilmedi.';

  @override
  String get cameraPermissionRequired => 'Kamera izni gerekli';

  @override
  String get cameraPermissionDesc =>
      'Belge taramak için kamera erişimi verin veya galeriyi kullanın.';

  @override
  String get openSettings => 'Ayarları aç';

  @override
  String get alignDocument => 'Belgeyi çerçeve içinde hizalayın';

  @override
  String pageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sayfa',
      zero: 'sayfa yok',
    );
    return '$_temp0';
  }

  @override
  String get preview => 'Önizleme';

  @override
  String pageNumber(int number) {
    return 'Sayfa $number';
  }

  @override
  String get done => 'Bitti';

  @override
  String get retake => 'Yeniden çek';

  @override
  String get useThisPhoto => 'Bu fotoğrafı kullan';

  @override
  String get addPage => 'Sayfa ekle';

  @override
  String uploadingPercent(int percent) {
    return 'Yükleniyor… %$percent';
  }

  @override
  String get preparingUpload => 'Yükleme hazırlanıyor…';

  @override
  String get documentUploadedSuccess => 'Belge başarıyla yüklendi';

  @override
  String pagesUploadedSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sayfa başarıyla yüklendi',
    );
    return '$_temp0';
  }

  @override
  String get uploadFailed => 'Yükleme başarısız. Bağlantınızı kontrol edin.';

  @override
  String get capturePhotoFailed =>
      'Fotoğraf çekilemedi. Lütfen tekrar deneyin.';

  @override
  String get readingText => 'Metin okunuyor…';

  @override
  String get draftDocument => 'Taslak belge';

  @override
  String get saveChanges => 'Değişiklikleri kaydet';

  @override
  String get editDocument => 'Belgeyi düzenle';

  @override
  String get generatingDraft => 'Taslağınız oluşturuluyor…';

  @override
  String get generatingDraftDesc =>
      'YZ, dava detaylarınıza dayalı hukuki belge hazırlıyor.';

  @override
  String get failedToGenerateDraft =>
      'Taslak oluşturulamadı. Lütfen tekrar deneyin.';

  @override
  String get changesSaved => 'Değişiklikler kaydedildi';

  @override
  String get copiedToClipboard => 'Panoya kopyalandı';

  @override
  String get emailComingSoon => 'E-posta gönderimi yakında';

  @override
  String get reviewBeforeSending =>
      'Göndermeden önce dikkatlice gözden geçirin. Bu belgenin içeriğinden siz sorumlusunuz.';

  @override
  String get noContentAvailable => 'İçerik mevcut değil';

  @override
  String get save => 'Kaydet';

  @override
  String get edit => 'Düzenle';

  @override
  String get pdf => 'PDF';

  @override
  String get copy => 'Kopyala';

  @override
  String get appealDraft => 'İtiraz taslağı';

  @override
  String selected(int count) {
    return '$count seçili';
  }

  @override
  String get deleteSelected => 'Seçilenleri sil';

  @override
  String deleteDocumentsConfirm(int count) {
    return '$count belge silinsin mi?';
  }

  @override
  String get delete => 'Sil';

  @override
  String get analyzeSelected => 'Seçilenleri analiz et';

  @override
  String get batchAnalysisStarting => 'Toplu analiz başlıyor…';

  @override
  String get switchToList => 'Liste görünümüne geç';

  @override
  String get switchToGrid => 'Izgara görünümüne geç';

  @override
  String get scanNew => 'Yeni tarama';

  @override
  String get noDocumentsYetScan => 'Henüz belge yok';

  @override
  String get scanFirstDocumentHint =>
      'İlk belgenizi tarayın, YZ hatalar için analiz etsin.';

  @override
  String get failedToLoadDocuments => 'Belgeler yüklenemedi';

  @override
  String get emailIntegrationTitle => 'E-posta entegrasyonu';

  @override
  String get connectYourEmail => 'E-postanızı bağlayın';

  @override
  String get connectYourEmailDesc =>
      'Davalarınızla ilgili hukuki yazışmaları otomatik olarak tespit etmek için e-postanızı bağlayın.';

  @override
  String get legalEmails => 'Hukuki e-postalar';

  @override
  String get unlinkedEmails => 'Bağlanmamış e-postalar';

  @override
  String get noLegalEmailsYet => 'Henüz hukuki e-posta yok';

  @override
  String get legalEmailsWillAppear =>
      'Hukuki olarak sınıflandırılan e-postalar burada görünecek.';

  @override
  String get assignToCase => 'Davaya ata';

  @override
  String get disconnectEmail => 'E-postayı ayır';

  @override
  String get disconnectEmailConfirm =>
      'Otomatik e-posta senkronizasyonu durdurulacak. Önceden senkronize edilen e-postalar kalacak.';

  @override
  String get gmailReauthBannerBody =>
      'Advocat v2.1, yanıt taslakları hazırlamak için gelen kutunuzu okur; istediğiniz zaman iptal edebilirsiniz. Proaktif önceliklendirmeyi etkinleştirmek için Gmail\'i yeniden bağlayın.';

  @override
  String get gmailReauthBannerCta => 'Yeniden yetkilendir';

  @override
  String connectedTo(String email) {
    return '$email bağlı';
  }

  @override
  String lastSynced(String time) {
    return 'Son senkronizasyon: $time';
  }

  @override
  String get filterByType => 'Türe göre filtrele';

  @override
  String get noCasesMatchSearch => 'Aramanızla eşleşen dava yok';

  @override
  String get failedToLoadCases => 'Davalar yüklenemedi';

  @override
  String get monthly => 'Aylık';

  @override
  String get annual => 'Yıllık';

  @override
  String get saveTwentyFivePercent => '%25 tasarruf edin';

  @override
  String get mostPopular => 'EN POPÜLER';

  @override
  String get oneCaseActive => '1 aktif dava';

  @override
  String get threeCasesActive => '3 aktif dava';

  @override
  String get unlimitedCases => 'Sınırsız dava';

  @override
  String get threeDocScans => '3 belge taraması';

  @override
  String get twentyDocScans => '20 belge taraması';

  @override
  String get unlimitedDocScans => 'Sınırsız belge taraması';

  @override
  String get basicAiAnalysis => 'Temel YZ analizi';

  @override
  String get fullAiAnalysis => 'Tam YZ analizi';

  @override
  String get draftGeneration => 'Taslak oluşturma';

  @override
  String get priorityProcessing => 'Öncelikli işleme';

  @override
  String get fiveAiMessagesTotal => '5 yapay zeka mesajı (ömür boyu)';

  @override
  String get hundredAiMessagesDay => 'Günde 100 yapay zeka mesajı';

  @override
  String get unlimitedAiMessages => 'Sınırsız yapay zeka mesajı';

  @override
  String get voiceInput => 'Sesli giriş';

  @override
  String get strategyRecommendations => 'Strateji önerileri';

  @override
  String get foundingMemberNote => 'Kurucu Üye: İlk 3 ay için aylık 9,99 €';

  @override
  String get saveTwentyPercent => '%20 tasarruf edin';

  @override
  String get forever => 'sonsuza kadar';

  @override
  String get perMonth => '/ay';

  @override
  String get perYear => '/yıl';

  @override
  String get checkingPurchases => 'Önceki satın almalar kontrol ediliyor…';

  @override
  String get noPreviousPurchases => 'Önceki satın alma bulunamadı.';

  @override
  String get chatWelcomeMessage =>
      'Hi! I\'m Advocat — your AI legal assistant. I provide legal information, not legal advice. What legal question can I help with?';

  @override
  String get copySummary => 'Özeti kopyala';

  @override
  String get caseSummaryCopied => 'Dava özeti kopyalandı';

  @override
  String get openCase => 'Davayı aç';

  @override
  String get viewFull => 'Tam görüntüle';

  @override
  String get draftCopiedToClipboard => 'Taslak panoya kopyalandı';

  @override
  String get reportMileageFraud => 'Kilometre sahtekarlığını bildir';

  @override
  String get reportMileageFraudDesc =>
      'Araç kontrol verilerine dayalı sahtekarlık raporu oluşturulacak.';

  @override
  String get reportAndOpenCase => 'Bildir ve dava aç';

  @override
  String get caseCreationComingSoon =>
      'Önceden doldurulmuş verilerle dava oluşturma yakında';

  @override
  String get failedToCreateCaseRetry =>
      'Dava oluşturulamadı. Lütfen tekrar deneyin.';

  @override
  String get takePhotoInstead => 'Fotoğraf çekin';

  @override
  String get deleteCase => 'Davayı sil';

  @override
  String deleteCaseConfirm(String title) {
    return '“$title” silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.';
  }

  @override
  String get haveQuestionsAi => 'Sorularınız mı var? YZ\'ye sorun';

  @override
  String get cookiePolicy => 'Çerez Politikası';

  @override
  String get aiDisclaimer => 'Yapay Zeka Sorumluluk Reddi';

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
  String get dataPrivacyConsent => 'Veri Gizliliği Onayı';

  @override
  String get gdprIntro =>
      'YZ hukuki yardım sağlamak için verilerinizi GDPR (AB 2016/679) uyarınca işliyoruz. Devam ederek kabul ediyorsunuz:';

  @override
  String get gdprChat => 'Sohbet mesajlarının YZ tarafından işlenmesi';

  @override
  String get gdprDocs => 'Yüklenen belgelerin analizi';

  @override
  String get gdprStorage => 'Dava verilerinin şifreli depolanması';

  @override
  String get gdprDelete => 'Verilerinizi istediğiniz zaman silme hakkı';

  @override
  String get gdprFooter =>
      'Verileriniz şifrelenir ve üçüncü taraflarla paylaşılmaz. Onayı geri çekebilir ve tüm verileri Ayarlardan silebilirsiniz.';

  @override
  String get gdprConsentAiProcessing =>
      'Verilerimin yapay zeka hukuki yardımı için işlenmesini kabul ediyorum (zorunlu)';

  @override
  String get gdprConsentAnalytics =>
      'Hizmeti iyileştirmek için analitiği kabul ediyorum (isteğe bağlı)';

  @override
  String get gdprArt9Intro =>
      'Bu uygulama, GDPR Madde 9 kapsamında özel kategori kişisel verileri işler, şunlar dahil:';

  @override
  String get gdprSpecialLegalCases =>
      'Hukuki dava ayrıntılarınız ve mahkeme belgeleriniz';

  @override
  String get gdprSpecialNationality => 'Uyruk ve göçmenlik durumu';

  @override
  String get gdprConsentLegalData =>
      'Hukuki dava verilerimin, uyruğumun ve göçmenlik durumumun yapay zeka tarafından işlenmesine onay veriyorum (zorunlu)';

  @override
  String get gdprConsentVoice =>
      'Ses kaydı işlenmesine onay veriyorum (isteğe bağlı)';

  @override
  String get gdprViewPrivacyPolicy => 'Gizlilik Politikasını görüntüle';

  @override
  String get legalInformation => 'Yasal Bilgiler';

  @override
  String get legalEntityName => 'Vorantis OÜ';

  @override
  String get legalRegistryCode => 'Sicil kodu: 17098992';

  @override
  String get legalAddress =>
      'Harju maakond, Tallinn, Kesklinna linnaosa, Tornimäe tn 5, 10145';

  @override
  String get legalEmail => 'E-posta: support@advocat.ee';

  @override
  String get legalRegistry =>
      'Estonya Ticaret Siciline (Äriregister) kayıtlıdır';

  @override
  String get aiGeneratedDisclaimer => 'AI-generated • Not legal advice';

  @override
  String get decline => 'Reddet';

  @override
  String get iAgree => 'Kabul ediyorum';

  @override
  String get iAgreeToThe => 'Kabul ediyorum ';

  @override
  String get orWord => 'veya';

  @override
  String get english => 'İngilizce';

  @override
  String get russian => 'Rusça';

  @override
  String get finnish => 'Fince';

  @override
  String successSubscribed(String plan) {
    return '$plan aboneliği başarılı!';
  }

  @override
  String paymentFailed(String error) {
    return 'Ödeme başarısız: $error';
  }

  @override
  String get whatToDo => 'Ne yapmalı';

  @override
  String get getHelp => 'Yardım al';

  @override
  String get share => 'Paylaş';

  @override
  String get didYouKnow => 'Biliyor muydunuz?';

  @override
  String get mustKnow => 'Bilmeniz gereken';

  @override
  String get goodToKnow => 'Bilmekte fayda var';

  @override
  String get sentFromAdvocat => 'Advocat uygulamasından gönderildi';

  @override
  String get policeActionStayCalm => 'Sakin olun ve ellerinizi görünür tutun';

  @override
  String get policeActionAskWhy => 'Memura neden durdurulduğunuzu sorun';

  @override
  String get policeActionProvideName => 'Adınızı ve doğum tarihinizi bildirin';

  @override
  String get policeActionWantLawyer =>
      'Açıkça belirtin: “Sorulardan önce bir avukat istiyorum”';

  @override
  String get policeActionAskInterpreter => 'Gerekirse tercüman isteyin';

  @override
  String get policeActionNoteBadge =>
      'Memurun adını ve sicil numarasını not edin';

  @override
  String get policeFactMustTellReason =>
      'Finlandiya\'da polis, sizi durdurma nedenini söylemek zorundadır. Söylemezlerse sorabilirsiniz — yasal olarak açıklamak zorundadırlar.';

  @override
  String get policeFactCanRecord =>
      'Finlandiya\'da kamuya açık yerlerde polis etkileşimlerini kaydedebilirsiniz. Bu, ifade özgürlüğü kapsamında korunmaktadır.';

  @override
  String get contactFinnishLegalAid => 'Finlandiya Adli Yardım';

  @override
  String get contactNonDiscriminationOmbudsman =>
      'Ayrımcılıkla Mücadele Ombudsmanı';

  @override
  String get deportationDeadlineAppeal =>
      'İdare Mahkemesine itiraz — genellikle tebliğden itibaren 30 gün';

  @override
  String get deportationDeadlineLegalAid =>
      'Adli yardım başvurusu yapın — bunu DERHAL yapın';

  @override
  String get deportationFactStayDuringAppeal =>
      'Finlandiya\'da itirazınız işlenirken genellikle ülkede kalma hakkınız vardır. Aktif bir itiraz süresince çoğu durumda sınır dışı etme gerçekleştirilemez.';

  @override
  String get contactRefugeeAdviceCentre => 'Finlandiya Mülteci Danışma Merkezi';

  @override
  String get contactAdminCourtHelsinki => 'Helsinki İdare Mahkemesi';

  @override
  String get workplaceActionKeepContract =>
      'İş sözleşmenizin kopyalarını saklayın';

  @override
  String get workplaceActionTrackHours =>
      'Çalışma saatlerinizi bağımsız olarak takip edin';

  @override
  String get workplaceActionReportUnsafe =>
      'Güvensiz koşulları iş güvenliği otoritesine bildirin';

  @override
  String get workplaceActionJoinUnion => 'Korunma için bir sendikaya katılın';

  @override
  String get workplaceActionContactAuthority =>
      'Gerekirse İş Güvenliği Otoritesine başvurun';

  @override
  String get workplaceFactCollectiveWage =>
      'Finlandiya\'da toplu iş sözleşmeleri sektöre göre asgari ücretleri belirler — tek bir ulusal asgari ücret yoktur. İşvereniniz alanınızın toplu iş sözleşmesine uymak zorundadır.';

  @override
  String get workplaceFactOralContract =>
      'Yazılı sözleşme olmasa bile Finlandiya\'da tam çalışan haklarına sahipsiniz. Sözlü anlaşma yasal olarak eşit derecede bağlayıcıdır.';

  @override
  String get contactOccupationalSafety => 'İş Güvenliği Otoritesi';

  @override
  String get contactTradeUnionSAK => 'Sendika Danışmanlığı (SAK)';

  @override
  String get tenantActionWrittenAgreement =>
      'Her zaman yazılı kira sözleşmesi yapın';

  @override
  String get tenantActionDocumentCondition =>
      'Taşınma sırasında dairenin durumunu belgeleyin (fotoğraflar)';

  @override
  String get tenantActionReportMaintenance =>
      'Bakım sorunlarını yazılı olarak bildirin';

  @override
  String get tenantActionNoIllegalEviction =>
      'Yasadışı tahliyeyi asla kabul etmeyin — mahkemeler karar vermelidir';

  @override
  String get tenantActionContactAdvisory =>
      'Anlaşmazlık durumunda kiracı danışma hizmetlerine başvurun';

  @override
  String get tenantFactNoEvictionWithoutCourt =>
      'Finlandiya\'da ev sahibi, kira sözleşmeniz sona ermiş olsa bile mahkeme kararı olmadan sizi tahliye edemez. Kilit değiştirmek veya hizmetleri kesmek yasadışıdır.';

  @override
  String get contactTenantsAssociation => 'Finlandiya Kiracılar Derneği';

  @override
  String get contactConsumerDisputesBoard => 'Tüketici Uyuşmazlıkları Kurulu';

  @override
  String get detentionActionAskDecision =>
      'Derhal yazılı gözaltı kararını isteyin';

  @override
  String get detentionActionRequestLawyer =>
      'Avukatla iletişim kurmayı talep edin';

  @override
  String get detentionActionContactEmbassy =>
      'Büyükelçiliğiniz veya konsolosluğunuzla iletişime geçin';

  @override
  String get detentionActionAskMedical => 'Gerekirse tıbbi yardım isteyin';

  @override
  String get detentionActionRequestInterpreter =>
      'Tüm duruşmalar için tercüman talep edin';

  @override
  String get detentionDeadlineCourtReview =>
      'Sulh mahkemesi gözaltını 4 gün içinde incelemelidir';

  @override
  String get detentionDeadlineContinuation =>
      'Mahkeme uzatmayı her 2 haftada bir inceler';

  @override
  String get detentionFactCourtReview =>
      'Finlandiya\'da göç gözaltısı 4 gün içinde bir sulh mahkemesi tarafından incelenmelidir. İncelenmezse gözaltı yasadışı hale gelir.';

  @override
  String get contactParliamentaryOmbudsman => 'Parlamento Ombudsmanı';

  @override
  String get discriminationActionWriteDown =>
      'Ne olduğunu tam olarak yazın (tarih, saat, yer)';

  @override
  String get discriminationActionSaveEvidence =>
      'Kanıtları saklayın: mesajlar, e-postalar, tanıklar';

  @override
  String get discriminationActionFileComplaint =>
      'Ayrımcılıkla Mücadele Ombudsmanına şikayette bulunun';

  @override
  String get discriminationActionContactLegalAid =>
      'Ücretsiz danışmanlık için adli yardım bürosuna başvurun';

  @override
  String get discriminationActionReportPolice =>
      'Tehdit veya saldırı varsa polise bildirin';

  @override
  String get discriminationFactNonDiscriminationAct =>
      'Finlandiya Ayrımcılık Yasağı Kanunu; yaş, köken, uyruk, dil, din, sağlık, engellilik, cinsel yönelim ve diğer kişisel özelliklere dayalı ayrımcılığı kapsar.';

  @override
  String get contactVictimSupportRIKU => 'Mağdur Desteği Finlandiya (RIKU)';

  @override
  String get domesticViolence => 'Aile içi şiddet';

  @override
  String get domesticViolenceDesc =>
      'Mağdur hakları, acil yardım, uzaklaştırma kararları';

  @override
  String get rightCallEmergency =>
      'Herhangi bir acil durumda 112\'yi arama hakkına sahipsiniz — polis, ambulans, itfaiye';

  @override
  String get rightVictimProtection =>
      'Mağdur olarak korunma, destek ve davanız hakkında bilgi alma hakkına sahipsiniz';

  @override
  String get rightRestrainingOrder =>
      'İstismarcıyı uzak tutmak için uzaklaştırma kararı (lähestymiskielto) talep edebilirsiniz';

  @override
  String get rightVictimInterpreter =>
      'Tüm yasal işlemler sırasında tercüman hakkına sahipsiniz';

  @override
  String get rightMedicalHelp =>
      'Acil tıbbi tedavi ve yaralanmaların belgelenmesi hakkına sahipsiniz';

  @override
  String get rightShelter =>
      'Acil barınma hakkına sahipsiniz — bir sığınma evi veya sosyal hizmetlerle iletişime geçin';

  @override
  String get mustReportDanger =>
      'Biri ani tehlike altındaysa hemen 112\'yi arayın';

  @override
  String get mustDocumentInjuries =>
      'Tüm yaralanmaları belgeleyin — fotoğraflar, tıbbi kayıtlar, yazılı notlar';

  @override
  String get domesticActionCallEmergency =>
      'Ani tehlike altındaysanız 112\'yi arayın';

  @override
  String get domesticActionGoToSafe =>
      'Güvenli bir yere gidin — sığınma evi, arkadaş, kamuya açık yer';

  @override
  String get domesticActionDocumentEverything =>
      'Yaralanmaları belgeleyin: fotoğraf çekin, tıbbi kayıt alın';

  @override
  String get domesticActionFilePoliceReport =>
      'Polise suç duyurusunda bulunun — bunu daha sonra da yapabilirsiniz';

  @override
  String get domesticActionContactShelter =>
      'Bir sığınma evi veya kriz yardım hattıyla iletişime geçin';

  @override
  String get domesticActionApplyRestraining =>
      'Polis veya mahkeme aracılığıyla uzaklaştırma kararı için başvurun';

  @override
  String get domesticFactRestrainingOrder =>
      'Finlandiya\'da, bir uzaklaştırma kararı (lähestymiskielto) ceza davası olmadan dahi verilebilir. Bu, kişinin sizinle iletişim kurmasını veya size yaklaşmasını yasaklar.';

  @override
  String get domesticFactVictimDirective =>
      'AB Mağdur Hakları Direktifi 2012/29/EU uyarınca, ikamet durumunuzdan bağımsız olarak saygıyla muamele görme, anladığınız bir dilde bilgi alma ve mağdur destek hizmetlerine erişme hakkına sahipsiniz.';

  @override
  String get domesticDeadlinePoliceReport =>
      'Polise suç duyurusu — kesin bir son tarih yok, ancak deliller için erken olması daha iyidir';

  @override
  String get domesticDeadlineRestraining =>
      'Uzaklaştırma kararı — her zaman başvurulabilir';

  @override
  String get contactEmergency => 'Acil Durum Numarası';

  @override
  String get contactShelter => 'Turvakoti (Sığınma Evi) Yardım Hattı';

  @override
  String get contactCrisisHelpline => 'Kriz Yardım Hattı (Kriisipuhelin)';

  @override
  String get contactNollaLinja =>
      'Nollalinja — Kadına Yönelik Şiddet Yardım Hattı';

  @override
  String get inheritance => 'Miras';

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
  String get consumerProtection => 'Tüketici koruması';

  @override
  String get consumerProtectionDesc =>
      'Dolandırıcılık, kusurlu ürünler, iadeler, aldatıcı satıcılar';

  @override
  String get rightReturnOnline =>
      'Çevrimiçi alışverişleri 14 gün içinde gerekçe göstermeden iptal etme hakkına sahipsiniz (AB cayma hakkı)';

  @override
  String get rightDefectiveProduct =>
      'Bir ürün kusurluysa, onarım, değişim veya iade hakkına sahipsiniz';

  @override
  String get rightClearPricing =>
      'Satıcılar tüm ücretler dahil net fiyatları göstermek zorundadır — gizli maliyetler yasa dışıdır';

  @override
  String get rightComplainBoard =>
      'Tüketici Uyuşmazlıkları Kuruluna ücretsiz şikayette bulunabilirsiniz';

  @override
  String get rightProtectionFraud =>
      'Haksız ticari uygulamalara ve dolandırıcılığa karşı korunursunuz';

  @override
  String get mustKeepReceipts =>
      'Tüm fişleri, sözleşmeleri ve satıcılarla yapılan yazışmaları saklayın';

  @override
  String get mustActTimely =>
      'Kusurları, keşfettikten sonra makul bir süre içinde satıcıya bildirin';

  @override
  String get consumerActionKeepEvidence =>
      'Fişleri, ekran görüntülerini, e-postaları ve tüm satın alma kanıtlarını saklayın';

  @override
  String get consumerActionContactSeller =>
      'Önce satıcıyla iletişime geçin — sorunu yazılı olarak açıklayın';

  @override
  String get consumerActionFileComplaint =>
      'Tüketici Uyuşmazlıkları Kuruluna (kuluttajariitalautakunta) şikayette bulunun';

  @override
  String get consumerActionContactAuthority =>
      'Ücretsiz yardım için Tüketici Danışma Hizmetleriyle iletişime geçin';

  @override
  String get consumerActionReportFraud =>
      'Dolandırıcılığı polise ve Tüketici Ombudsmanına bildirin';

  @override
  String get consumerFactWithdrawal =>
      'AB Tüketici Hakları Direktifi 2011/83/EU uyarınca, herhangi bir çevrimiçi veya mesafeli satın alımdan 14 gün içinde cayma hakkına sahipsiniz — hiçbir gerekçe gerekmez. Satıcı 14 gün içinde geri ödeme yapmalıdır.';

  @override
  String get consumerFactWarranty =>
      'Finlandiya\'da satıcı, ürün kusurlarından makul bir süre (genellikle 2 yıl veya daha fazla) boyunca sorumludur. Bu, üreticinin garantisinden ayrıdır.';

  @override
  String get consumerDeadlineWithdrawal =>
      'Çevrimiçi satın alımdan cayma — teslimattan itibaren 14 gün';

  @override
  String get consumerDeadlineDefect =>
      'Kusuru satıcıya bildirin — keşiften itibaren 2 ay içinde (önerilir)';

  @override
  String get contactConsumerAdvisory => 'Tüketici Danışma Hizmetleri';

  @override
  String get contactConsumerOmbudsman =>
      'Tüketici Ombudsmanı (Kuluttaja-asiamies)';

  @override
  String get contactConsumerDisputesBoardDirect =>
      'Tüketici Uyuşmazlıkları Kurulu';

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
  String get comingSoon => 'Yakında';

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
      other: 'İçinde $count hak var',
      zero: 'hak yok',
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
  String get chatDisclaimerSubtitle =>
      'Yapay zeka asistanı · hukuki tavsiye değil';

  @override
  String get chatDisclaimerBannerFull =>
      'Advocat, bir avukat değil, hukuki bilgi sağlayan bir yapay zeka asistanıdır. Buradaki bilgiler avukat–müvekkil ilişkisi kurmaz, hukuki tavsiye niteliği taşımaz ve hatalı olabilir. Bağlayıcı hukuki tavsiye için yargı yetkinizdeki lisanslı bir avukata danışın. Sizi temsil etmiyoruz.';

  @override
  String get chatDisclaimerFooter =>
      'Yapay zeka tarafından üretildi. Lisanslı bir avukata danışın.';

  @override
  String get chatDisclaimerGotIt => 'Anladım';

  @override
  String get categoryChildren => 'Çocuklar';

  @override
  String get categoryDigital => 'Dijital';

  @override
  String get childrenRights => 'Çocuk Hakları ve Nafaka';

  @override
  String get childrenRightsDesc =>
      'Çocuk desteği, nafaka, koruma, devlet güvenceleri';

  @override
  String get cyberbullying => 'Siber Zorbalık ve Çevrimiçi Taciz';

  @override
  String get cyberbullyingDesc =>
      'Tehditler, gizlilik ihlalleri, çevrimiçi karalama';

  @override
  String get rightChildSupport =>
      'Her iki ebeveyn de çocuklarını mali olarak desteklemekle yasal olarak yükümlüdür (Perekonnaseadus § 100–102)';

  @override
  String get rightMinimumAlimony =>
      'Estonya\'da asgari çocuk desteği: temel tutar (295,86 €) + önceki yılın ortalama brüt maaşının %3\'ü (PKS § 101). 01.04.2026\'dan itibaren — çocuk başına aylık 318,62 €. Her yıl 1 Nisan\'da güncellenir. Hesaplayıcı: alimendid.ee';

  @override
  String get rightCourtAlimony =>
      'Bölge mahkemesi (maakohus) aracılığıyla nafaka talep edebilirsiniz — 6.400 €\'ya kadar talepler için avukat gerekmez';

  @override
  String get rightBailiffEnforcement =>
      'Ebeveyn ödemeyi reddederse, bir icra memuru (kohtutäitur) mahkeme kararını icra edebilir, maaş haczi dahil';

  @override
  String get rightStateAlimonyGuarantee =>
      'Ebeveyn ödeme yapmazsa, devlet Sotsiaalkindlustusamet aracılığıyla elatisabi (nafaka yardımı) sağlar — çocuk başına aylık 100 €\'ya kadar';

  @override
  String get rightChildEducation =>
      'Her çocuk eğitim, sağlık hizmeti ve istismardan korunma hakkına sahiptir (Lastekaitseseadus § 4–5)';

  @override
  String get rightChildContact =>
      'Bir mahkeme aksini kararlaştırmadıkça, çocuk her iki ebeveynle de iletişimini sürdürme hakkına sahiptir (PKS § 143)';

  @override
  String get mustFileCourtClaim =>
      'Nafaka almak için mahkemeye dava açmalı veya tutar üzerinde yazılı olarak anlaşmalısınız';

  @override
  String get mustNotifyAddressChange =>
      'Elatisabi alıyorsanız adres değişikliklerini Sotsiaalkindlustusamet\'e bildirin';

  @override
  String get childrenActionGatherDocs =>
      'Çocuğun doğum belgesini, kimliğinizi ve gider kanıtlarını toplayın';

  @override
  String get childrenActionFileCourtClaim =>
      'Bölge mahkemesine (maakohus) nafaka davası açın — e-toimik üzerinden çevrimiçi yapılabilir';

  @override
  String get childrenActionApplyElatisabi =>
      'Ebeveyn ödemezse Sotsiaalkindlustusamet\'te devlet nafaka güvencesi (elatisabi) için başvurun';

  @override
  String get childrenActionContactBailiff =>
      'Mahkeme kararını icra etmek için bir icra memuruyla (kohtutäitur) iletişime geçin';

  @override
  String get childrenActionCallLasteabi =>
      'Çocuk yardım hattı için Lasteabi 116 111\'i arayın — ücretsiz, 7/24';

  @override
  String get childrenDeadlineElatisabi =>
      'Elatisabi için başvurun — mahkeme kararından sonra, kesin bir son tarih yok ancak süreç zaman alır';

  @override
  String get childrenDeadlineCourt =>
      'Nafaka, mahkemeye başvurudan önceki 1 yıla kadar geriye dönük olarak talep edilebilir';

  @override
  String get childrenFactMinimum =>
      '01.04.2026\'dan itibaren asgari çocuk desteği çocuk başına aylık 318,62 €\'dur. Formül: temel tutar (295,86 €) + önceki yılın ortalama brüt maaşının %3\'ü. Her yıl 1 Nisan\'da güncellenir. Bir ebeveyn daha az ödemeyi kabul edemez. Hesaplayıcı: alimendid.ee';

  @override
  String get childrenFactElatisabi =>
      'Estonya\'nın devlet nafaka güvencesi (elatisabi), bir ebeveynin ödeme yapmayı reddetmesi durumunda çocukları korumak için 2017\'de getirildi. Devlet öder ve ardından tutarı borçlu ebeveynden tahsil eder.';

  @override
  String get rightReportCybercrime =>
      'Çevrimiçi tehditleri, tacizi ve kimlik hırsızlığını polise bildirme hakkına sahipsiniz (Karistusseadustik § 120, § 157¹)';

  @override
  String get rightContentRemoval =>
      'Karalayıcı veya özel içeriğin platformlardan kaldırılmasını talep edebilir ve GDPR kapsamında kaldırılmasını isteyebilirsiniz';

  @override
  String get rightMoralDamageCompensation =>
      'Siber zorbalığın neden olduğu manevi zarar için tazminat talep edebilirsiniz (Võlaõigusseadus § 1043–1055)';

  @override
  String get rightPrivacyProtection =>
      'Özel hayatınız korunmaktadır — fotoğraflarınızın, mesajlarınızın veya kişisel verilerinizin izinsiz paylaşılması yasa dışıdır (KarS § 157)';

  @override
  String get rightDataProtection =>
      'Veri koruma ihlallerini (verilerinizin izinsiz kullanımı) Andmekaitse Inspektsioon\'a bildirin';

  @override
  String get rightDefamationAction =>
      'Karalama (laimamine) bir hukuki suçtur — tazminat davası açabilir ve kamuya açık bir düzeltme talep edebilirsiniz (KarS § 247 (yürürlükten kaldırıldı), VÕS § 1047)';

  @override
  String get mustCollectEvidence =>
      'Tüm delilleri toplayın ve saklayın — ekran görüntüleri, bağlantılar, tarihler ve tanık bilgileri';

  @override
  String get mustNotRetaliate =>
      'Misilleme yapmayın veya karşı tacize girişmeyin — bu davanızı zayıflatabilir';

  @override
  String get cyberActionScreenshots =>
      'Tüm tacizin ekran görüntülerini alın — URL\'leri, tarihleri, kullanıcı adlarını ve içeriği kaydedin';

  @override
  String get cyberActionReportPolice =>
      'En yakın karakolda veya politsei.ee adresinde çevrimiçi olarak polise suç duyurusunda bulunun';

  @override
  String get cyberActionReportPlatform =>
      'İçeriği kaldırılması için sosyal medya platformuna bildirin';

  @override
  String get cyberActionContactDPA =>
      'Kişisel verileriniz kötüye kullanıldıysa Andmekaitse Inspektsioon ile iletişime geçin';

  @override
  String get cyberActionConsultLawyer =>
      'Hukuki tazminat hakkında bir avukata danışın — Riigi Õigusabi aracılığıyla ücretsiz hukuki yardım mevcuttur';

  @override
  String get cyberDeadlineCriminal =>
      'Suç duyurusu — kesin bir son tarih yok, ancak en iyi sonuç için derhal bildirin';

  @override
  String get cyberDeadlineCivil =>
      'Tazminat için hukuk davası — ihlali öğrendiğiniz tarihten itibaren 3 yıla kadar (TsÜS § 150)';

  @override
  String get cyberFactPrivacy =>
      'Estonya\'da, birinin mahrem görüntülerinin izinsiz paylaşılması Karistusseadustik § 157¹ (gizlilik ihlali) uyarınca 3 yıla kadar hapis cezasıyla sonuçlanabilir.';

  @override
  String get cyberFactGDPR =>
      'GDPR kapsamında “unutulma hakkına” sahipsiniz — platformlar, saklamak için yasal bir dayanak yoksa talebiniz üzerine kişisel verilerinizi silmek zorundadır.';

  @override
  String get guestUser => 'Misafir';

  @override
  String get howToUse => 'Nasil kullanilir?';

  @override
  String get tutorialStep1Title => 'YZ Hukuk Asistani';

  @override
  String get tutorialStep1Desc =>
      'Herhangi bir hukuki soru sorun ve Estonya yasalarina dayali aninda yanitlar alin.';

  @override
  String get tutorialStep2Title => 'Haklarinizi Bilin';

  @override
  String get tutorialStep2Desc =>
      'Hukuki bilgileri konulara gore arayin — is, konut, tuketici haklari ve daha fazlasi.';

  @override
  String get tutorialStep3Title => 'Belgeleri Tarayin';

  @override
  String get tutorialStep3Desc =>
      'Hukuki belgelerin fotografini cekin, YZ analizi ve guvenli depolama icin.';

  @override
  String get tutorialStep4Title => 'Baslayalim!';

  @override
  String get tutorialStep4Desc =>
      'Uygulamayi kesfedin ve haklarinizi koruyun. Tum veriler cihazinizda ozel kalir.';

  @override
  String get advocatProTitle => 'Advocat Pro';

  @override
  String get advocatProSubtitle => 'Premium özellikleri açın';

  @override
  String get voiceDisclaimer =>
      'Sesli asistan şu anda yalnızca masaüstünde çalışmaktadır (Chrome tarayıcı). Mobil destek yakında.';

  @override
  String get recommended => 'Önerilen';

  @override
  String get pleaseLogIn => 'Lütfen giriş yapın';

  @override
  String get subscriptionNotFound => 'Abonelik bulunamadı';

  @override
  String errorWithMessage(String message) {
    return 'Hata: $message';
  }

  @override
  String get redirectingToPayment => 'Ödeme sayfasına yönlendiriliyor…';

  @override
  String cheaperAnnually(String amount) {
    return '€$amount/ay daha ucuz yıllık abonelikle';
  }

  @override
  String get navigatingTo => 'Açılıyor';

  @override
  String get stayInChat => 'Sohbette kal';

  @override
  String get backToChat => 'Sohbete dön';

  @override
  String get upgradeBannerTitle => 'Sınırsız danışmanlık için yükseltin';

  @override
  String get upgradeBannerCta => 'Yükselt';

  @override
  String get paymentSuccessTitle => 'Ödeme başarılı';

  @override
  String get paymentSuccessBody => 'Aboneliğiniz artık etkin.';

  @override
  String get commonOk => 'Tamam';

  @override
  String get feedbackThumbsUpLabel => 'Yararlı';

  @override
  String get feedbackThumbsDownLabel => 'Yararlı değil';

  @override
  String get feedbackCommentPrompt => 'Nesi yanlıştı?';

  @override
  String get feedbackSend => 'Gönder';

  @override
  String get feedbackCancel => 'İptal';

  @override
  String get reasoningPillIdle => 'Düşünüyor…';

  @override
  String get reasoningPillSearchingLaw => 'Estonya hukuku aranıyor…';

  @override
  String get reasoningPillSearchingWeb => 'Web\'de aranıyor…';

  @override
  String get reasoningPillCheckingCompany => 'Şirket sicili kontrol ediliyor…';

  @override
  String get reasoningPillCheckingVehicle => 'Araç sicili kontrol ediliyor…';

  @override
  String get reasoningPillReadingDocument => 'Belgeniz okunuyor…';

  @override
  String get reasoningPillDrafting => 'Belge taslağı hazırlanıyor…';

  @override
  String get reasoningPillPreparingEmail => 'E-posta hazırlanıyor…';

  @override
  String get reasoningPillFindingLawyer => 'Avukatlar aranıyor…';

  @override
  String get reasoningPillThinking => 'Davanız üzerinde düşünülüyor…';

  @override
  String get reasoningPillFinalising => 'Yanıtınız oluşturuluyor…';

  @override
  String reasoningCollapsedFormat(int sec, int sources) {
    return '$sec sn boyunca akıl yürütüldü · $sources kaynak';
  }

  @override
  String get reasoningExpandHint => 'adımları görmek için dokunun';

  @override
  String get caseFileTitle => 'Dava Dosyası';

  @override
  String get caseFileTimeline => 'Zaman Çizelgesi';

  @override
  String get caseFileParties => 'Taraflar';

  @override
  String get caseFileDeadlines => 'Son tarihler';

  @override
  String get caseFileExportPdf => 'Dosyayı indir (PDF)';

  @override
  String get caseFileEmpty =>
      'Davanız hakkında yapay zeka ile sohbet edin — zaman çizelgeniz kendiliğinden oluşacak.';

  @override
  String get caseFileDisclaimer =>
      'Bu dosya, sohbetinizden otomatik olarak çıkarılmıştır. Hukuki tavsiye değildir.';

  @override
  String get caseFileTabLabel => 'Dava';

  @override
  String get refresh => 'Yenile';

  @override
  String get demoLimitReached =>
      'Demo sınırına ulaşıldı. Devam etmek için ücretsiz kaydolun.';

  @override
  String get demoLimitSignUpCta => 'Kaydol';

  @override
  String freeQuotaExhausted(int count) {
    return 'Bu ay $count ücretsiz mesajın tamamını kullandınız.';
  }

  @override
  String get upgradeForUnlimited => 'Sınırsız için Pro\'ya yükseltin';

  @override
  String get upgradeCta => 'Yükselt';

  @override
  String get rateLimitTryAgain =>
      'Çok hızlı gönderiyorsunuz. Birkaç saniye içinde tekrar deneyin.';

  @override
  String get quickProfilePrompt =>
      'Size daha isabetli yardımcı olabilmem için, yasal durumunuz nedir: Estonya vatandaşı mısınız, başka bir ülkeden AB vatandaşı mısınız, yoksa ikamet izniniz mi var?';

  @override
  String get quickProfileChipEstonianCitizen => 'Estonya vatandaşı';

  @override
  String get quickProfileChipEuCitizen => 'AB vatandaşı (diğer)';

  @override
  String get quickProfileChipResidencePermit => 'İkamet izni';

  @override
  String get quickProfileSkipBtn => 'Atla';

  @override
  String get quickProfileSavedAck => 'Anladım. Şimdi, sorunuz nedir?';

  @override
  String get caseTitleLabel => 'Dava başlığı';

  @override
  String get jurisdictionLabel => 'Yargı yetkisi';

  @override
  String get caseTypeLabel => 'Dava türü';

  @override
  String get caseLanguageLabel => 'Dil';

  @override
  String get caseNumbersSection => 'Dava numaraları';

  @override
  String get partiesSection => 'Taraflar';

  @override
  String get authoritiesSection => 'Makamlar';

  @override
  String get timelineSection => 'Zaman Çizelgesi';

  @override
  String get openQuestionsSection => 'Açık sorular';

  @override
  String get nextActionsSection => 'Sonraki adımlar';

  @override
  String get summarySection => 'Özet';

  @override
  String get addRow => 'Satır ekle';

  @override
  String get removeRow => 'Kaldır';

  @override
  String get archiveCase => 'Davayı arşivle';

  @override
  String get closeCase => 'Davayı kapat';

  @override
  String get continueChatAboutCase => 'Bu dava hakkında sohbete devam et';

  @override
  String get linkChatToCase => 'Davaya bağla';

  @override
  String get clearActiveCase => 'Etkin davayı temizle';

  @override
  String get caseSavedAck => 'Dava kaydedildi';

  @override
  String get caseArchivedAck => 'Dava arşivlendi';

  @override
  String get intakeStep1Title => 'Dava nerede?';

  @override
  String get intakeStep1Subtitle => 'İşlem yaptığınız ülke ve makam.';

  @override
  String get intakeJurisdictionLabel => 'Ülke / yargı yetkisi';

  @override
  String get intakeAuthorityLabel => 'Makam türü';

  @override
  String get intakeAuthorityNameLabel => 'Makam adı (isteğe bağlı)';

  @override
  String get intakeAuthorityPolice => 'Polis';

  @override
  String get intakeAuthorityCourt => 'Mahkeme';

  @override
  String get intakeAuthoritySocial => 'Sosyal hizmetler';

  @override
  String get intakeAuthorityEmployer => 'İşveren';

  @override
  String get intakeAuthorityLandlord => 'Ev sahibi';

  @override
  String get intakeAuthorityOpposingParty => 'Karşı taraf';

  @override
  String get intakeAuthorityOther => 'Diğer';

  @override
  String get intakeStep2Title => 'Ne tür bir dava?';

  @override
  String get intakeStep2Subtitle =>
      'En yakın türü seçin — daha sonra ayrıntılandırabilirsiniz.';

  @override
  String get intakeCaseTypeCriminal => 'Ceza';

  @override
  String get intakeCaseTypeCivil => 'Hukuk';

  @override
  String get intakeCaseTypeFamily => 'Aile';

  @override
  String get intakeCaseTypeAdmin => 'İdari';

  @override
  String get intakeCaseTypeImmigration => 'Göçmenlik';

  @override
  String get intakeCaseTypeLabor => 'İş';

  @override
  String get intakeCaseTypeConsumer => 'Tüketici';

  @override
  String get intakeCaseTypeInheritance => 'Miras';

  @override
  String get intakeCaseTypeOther => 'Diğer';

  @override
  String get intakeStep3Title => 'Kimler dahil?';

  @override
  String get intakeStep3Subtitle => 'Sizin rolünüz ve karşı taraf.';

  @override
  String get intakeRoleLabel => 'Rolünüz';

  @override
  String get intakeRolePlaintiff => 'Davacı';

  @override
  String get intakeRoleDefendant => 'Davalı';

  @override
  String get intakeRoleVictim => 'Mağdur';

  @override
  String get intakeRoleAccused => 'Sanık';

  @override
  String get intakeRoleWitness => 'Tanık';

  @override
  String get intakeRoleFamily => 'Aile üyesi';

  @override
  String get intakeRoleOther => 'Diğer';

  @override
  String get intakeOpposingSideLabel => 'Karşı taraf (isteğe bağlı)';

  @override
  String get intakeWitnessesLabel => 'Tanıklar (isteğe bağlı)';

  @override
  String get intakeAddWitness => 'Tanık ekle';

  @override
  String get intakeWitnessHint => 'Ad veya iletişim';

  @override
  String get intakeStep4Title => 'Numaralar ve tarihler';

  @override
  String get intakeStep4Subtitle => 'Elinizde ne varsa. Olmayanları atlayın.';

  @override
  String get intakeCaseNumberLabel => 'Dava numarası (isteğe bağlı)';

  @override
  String get intakeIncidentDateLabel => 'Olay tarihi (isteğe bağlı)';

  @override
  String get intakeIncidentDatePick => 'Tarih seç';

  @override
  String get intakeDeadlinesLabel => 'Bilinen son tarihler';

  @override
  String get intakeAddDeadline => 'Son tarih ekle';

  @override
  String get intakeDeadlineWhatHint => 'Ne';

  @override
  String get intakeStep5Title => 'Belgeler';

  @override
  String get intakeStep5Subtitle => 'İlgili her şeyi yükleyin. Biz okuyacağız.';

  @override
  String get intakeUploadDocsLabel => 'Belge yükle';

  @override
  String get intakeSkipDocs => 'Atla — daha sonra yükleyeceğim';

  @override
  String get intakeNextBtn => 'İleri';

  @override
  String get intakeBackBtn => 'Geri';

  @override
  String get intakeFinishBtn => 'Bitir ve sohbeti aç';

  @override
  String get intakeUrgentBtn => 'Acil — şimdi sor';

  @override
  String get intakeUrgentDialogTitle => 'Sohbeti şimdi aç?';

  @override
  String get intakeUrgentDialogBody =>
      'Girdiklerinizi taslak dava olarak kaydedeceğiz. Sihirbazı dava sayfasından istediğiniz zaman tamamlayabilirsiniz.';

  @override
  String get intakeUrgentConfirm => 'Sohbeti aç';

  @override
  String get intakeUrgentCancel => 'Doldurmaya devam et';

  @override
  String get intakePreparingCase => 'Davanız hazırlanıyor…';

  @override
  String get intakeFallbackGreeting =>
      'Davanızı görüyorum. En acil olanı söyleyin — sizinle birlikte üzerinde çalışacağım.';

  @override
  String get intakeUrgentGreeting =>
      'Bunun acil olduğunu görüyorum. Sorunuzu sorun — ilerledikçe gerisini ben tamamlarım.';

  @override
  String intakeStepIndicator(int current, int total) {
    return 'Adım $current / $total';
  }

  @override
  String get intakeFieldRequired => 'Zorunlu';

  @override
  String intakeUploadProgress(int done, int total) {
    return 'Yükleniyor $done / $total…';
  }

  @override
  String get uplDisclaimerFooter =>
      'Advocat bir hukuk bürosu değildir. Bu, bilgilendirmedir, hukuki tavsiye değildir.';

  @override
  String get citationStatusVerifiedBadge => 'Doğrulandı';

  @override
  String get citationStatusUnverifiedBadge => 'Doğrulanmadı';

  @override
  String get citationStatusHistoricalBadge => 'Tarihsel sürüm';

  @override
  String get citationStatusVerifiedTooltip =>
      'Erişilen bir hukuki kaynaktan alıntılandı.';

  @override
  String get citationStatusUnverifiedTooltip =>
      'Yapay zekâ bu bölümü kaynak erişimi olmadan alıntıladı — güvenmeden önce doğrulayın.';

  @override
  String get citationStatusHistoricalTooltip =>
      'Alıntılanan hüküm artık yürürlükte değil.';

  @override
  String get citationOpenInRiigiTeataja => 'Riigi Teataja\'da aç';

  @override
  String get citationSnippetExpand => 'Tam metni göster';

  @override
  String get citationSnippetCollapse => 'Daha az göster';

  @override
  String get citationUnverifiedSheetNote =>
      'Yapay zekâ bu paragrafı alıntıladı, ancak bu görüşmede mevzuat külliyatından alınmamıştı. Güvenmeden önce atfı doğrulayın.';

  @override
  String get citationFooterNoneWarning => 'Belgelenmiş atıf yok';

  @override
  String citationFooterSummaryTotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count alıntı',
    );
    return '$_temp0';
  }

  @override
  String citationFooterSummaryVerified(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count doğrulanmış',
    );
    return '$_temp0';
  }

  @override
  String citationFooterSummaryUnverified(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count doğrulanmamış',
    );
    return '$_temp0';
  }

  @override
  String citationFooterSummaryHistorical(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tarihsel',
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
      other: '$count gün içinde',
      zero: 'bugün',
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
      other: '$count gün gecikme',
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
    return 'Consilium $count paralel eylem öneriyor';
  }

  @override
  String get parallelActionsApproveAll => 'Tümünü Onayla ve Gönder';

  @override
  String parallelActionsApproveSelected(int count, int total) {
    return '$total eylemden $count tanesini onayla';
  }

  @override
  String parallelActionsConfirmTitle(int count) {
    return '$count e-posta gönderilsin mi?';
  }

  @override
  String parallelActionsConfirmBody(int count) {
    return 'Advocat, hazırlanan $count yanıtı bağlı Gmail hesabınız aracılığıyla gönderecek. Her biri bağımsız olarak gönderilir — herhangi biri başarısız olursa diğerleri yine de gider.';
  }

  @override
  String parallelActionsSentToast(int count) {
    return '$count gönderildi.';
  }

  @override
  String parallelActionsPartialFailureToast(int sent, int failed) {
    return '$sent gönderildi, $failed başarısız oldu.';
  }

  @override
  String get parallelActionsKindReply => 'yanıt';

  @override
  String get parallelActionsKindNew => 'yeni';

  @override
  String get parallelActionsCheckboxSelected => 'Eylem seçildi';

  @override
  String get parallelActionsCheckboxUnselected => 'Eylem seçilmedi';

  @override
  String parallelActionsCitationCount(int count) {
    return '$count atıf';
  }

  @override
  String parallelActionsRetryFailed(int count) {
    return 'Başarısız olanları yeniden dene ($count)';
  }

  @override
  String get agentApprovalNeedsReviewTitle =>
      'Advocat onayınıza ihtiyaç duyuyor';

  @override
  String get agentApprovalResolvedTitle => 'Eylem çözümlendi';

  @override
  String get agentApprovalStepsLabel => 'adım';

  @override
  String get agentApprovalApproveButton => 'Onayla ve Gönder';

  @override
  String get agentApprovalDeclineButton => 'Reddet';

  @override
  String get agentApprovalAttachmentsLabel => 'Ekler';

  @override
  String get agentApprovalSentSummary => 'Sizin adınıza gönderildi.';

  @override
  String get agentApprovalDeclinedSummary =>
      'Reddedildi — hiçbir şey gönderilmedi.';

  @override
  String get agentToolDraftEmailAtt => 'Eklerle e-posta gönder';

  @override
  String get agentToolSendEmail => 'E-posta gönder';

  @override
  String get agentToolGeneratePdf => 'PDF oluştur';

  @override
  String get agentToolApproveSend => 'Hazırlanan yanıtı gönder';

  @override
  String get inboxErrorTitle => 'Gelen kutusu yüklenemedi';

  @override
  String get inboxEditDiscardTitle => 'Kaydedilmemiş düzenlemeler atılsın mı?';

  @override
  String get inboxEditDiscardBody =>
      'Bu taslakta kaydedilmemiş değişiklikleriniz var. Geri dönmek bunları atacaktır.';

  @override
  String get inboxEditKeepEditing => 'Düzenlemeye devam et';

  @override
  String get inboxEditDiscard => 'At';

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
  String get plannerSettingsTitle => 'Üç aşamalı hukuki akıl yürütme';

  @override
  String get plannerSettingsSubtitle =>
      'Planla → yanıtla → eleştir. Daha yavaş ama daha kapsamlı.';

  @override
  String get plannerSettingsProBadge => 'Pro';

  @override
  String get plannerSettingsProDescription => 'Pro planında kullanılabilir';

  @override
  String get plannerTrailHeaderPlan => 'Plan';

  @override
  String get plannerTrailHeaderCritique => 'Eleştiri';

  @override
  String get plannerTrailSubQuestions => 'Alt sorular';

  @override
  String get plannerTrailCounterArgs => 'Karşı argümanlar';

  @override
  String get plannerTrailEvidenceGaps => 'Delil boşlukları';

  @override
  String get plannerTrailMaterialGapTrue => 'Esaslı boşluk tespit edildi';

  @override
  String get plannerTrailRegeneratedBadge => 'Bir kez yeniden oluşturuldu';

  @override
  String get plannerTrailEmpty => 'öğe yok';

  @override
  String get supportTitle => 'Yardım';

  @override
  String get supportSubtitle => 'Genellikle 1-2 saat içinde yanıt veririz.';

  @override
  String get supportSearchPlaceholder => 'Yardımda ara…';

  @override
  String get supportStatusAllOk => 'Tüm sistemler normal';

  @override
  String get supportFaqWhatIs => 'Advocat nedir?';

  @override
  String get supportFaqHowSubscribe => 'Pro\'ya nasıl abone olurum?';

  @override
  String get supportFaqExportData => 'Verilerimi dışa aktarabilir miyim?';

  @override
  String get supportFaqCancelAccount => 'Hesabı iptal et veya sil';

  @override
  String get supportFaqTalkHuman => 'Bir kişiyle görüş';

  @override
  String get supportContactEmail => 'E-posta';

  @override
  String get supportContactTelegram => 'Telegram';

  @override
  String get supportContactWhatsapp => 'WhatsApp';

  @override
  String get supportFooterSla => '24 saat içinde yanıt veririz';

  @override
  String get supportWhatsapp => 'WhatsApp';

  @override
  String get supportEmail => 'E-posta';

  @override
  String get supportInApp => 'Bize buradan yazın';

  @override
  String get supportCategoryLabel => 'Kategori';

  @override
  String get supportCategoryBug => 'Hata';

  @override
  String get supportCategoryPayment => 'Ödeme sorunu';

  @override
  String get supportCategoryQuestion => 'Soru';

  @override
  String get supportCategoryFeature => 'Özellik talebi';

  @override
  String get supportCategoryOther => 'Diğer';

  @override
  String get supportMessagePlaceholder => 'Sorununuzu açıklayın...';

  @override
  String get supportEmailLabel => 'E-posta (isteğe bağlı)';

  @override
  String get supportSend => 'Gönder';

  @override
  String get supportSentSuccess => 'Mesaj gönderildi! Yakında yanıt vereceğiz.';

  @override
  String get supportError => 'Bir şeyler ters gitti. Tekrar deneyin.';

  @override
  String get supportErrorTooShort => 'Lütfen en az 10 karakter yazın.';

  @override
  String get supportErrorTooLong => 'En fazla 2000 karakter.';

  @override
  String get supportPrivacyNotice => 'Mesajınız güvenli bir şekilde saklanır.';

  @override
  String get reviewThisContract => 'Sözleşmeyi incele';

  @override
  String get contractReviews => 'Sözleşme incelemeleri';

  @override
  String get contractReviewsFreeFeature =>
      '1 sözleşme incelemesi (ömür boyu deneme)';

  @override
  String get contractReviewsCounselFeature => 'Ayda 5 sözleşme incelemesi';

  @override
  String get contractReviewsProFeature => 'Ayda 20 sözleşme incelemesi';

  @override
  String contractReviewsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bu ay $count sözleşme incelemesi kaldı',
      zero: 'Bu ay sözleşme incelemesi kalmadı',
    );
    return '$_temp0';
  }

  @override
  String get contractReviewsExhausted => 'Bu ay sözleşme incelemesi kalmadı';

  @override
  String get contractReviewsFreeTrialLeft =>
      'Ücretsiz deneme: 1 sözleşme incelemesi';

  @override
  String get contractReviewsFreeTrialUsed =>
      'Ücretsiz deneme kullanıldı — yükseltin';

  @override
  String get contractReviewsUpgradeTitle => 'Sözleşme incelemeleri tükendi';

  @override
  String get contractReviewsUpgradeBodyFree =>
      'Ücretsiz sözleşme incelemenizi kullandınız. Aylık incelemeler için yükseltin.';

  @override
  String contractReviewsUpgradeBodyPaid(int used, int cap) {
    return 'Bu ay $cap incelemenin $used tanesini kullandınız. Daha yüksek aylık limit için yükseltin.';
  }

  @override
  String get contractReviewsUpgradeCounselCta =>
      'Counsel\'a yükselt (€19,99/ay) — 5 inceleme';

  @override
  String get contractReviewsUpgradeProCta =>
      'Pro\'ya yükselt (€29,99/ay) — 20 inceleme';

  @override
  String get contractReviewsUpgradeToProShort => 'Pro\'ya yükselt — 20/ay';

  @override
  String get notNow => 'Şimdi değil';

  @override
  String get referralTitle => 'Arkadaşlarını davet et';

  @override
  String get referralSubtitle =>
      'Bir ay ücretsiz kazan. Bir ay ücretsiz hediye et.';

  @override
  String get referralYourLink => 'BAĞLANTIN';

  @override
  String get referralCopyLink => 'Bağlantıyı kopyala';

  @override
  String get referralShare => 'Paylaş';

  @override
  String get referralLinkCopied => 'Bağlantı kopyalandı';

  @override
  String get referralStatsInvited => 'Davet edilen';

  @override
  String get referralStatsConverted => 'Kayıt olan';

  @override
  String get referralStatsEarned => 'Kazanılan ay';

  @override
  String get referralShareWhatsApp => 'WhatsApp\'ta paylaş';

  @override
  String get referralShareTelegram => 'Telegram\'da paylaş';

  @override
  String get referralShareEmail => 'E-posta ile paylaş';

  @override
  String get referralEmailSubject =>
      'Advocat\'ı dene — yapay zekâ hukuk asistanın';

  @override
  String get referralLoadError =>
      'Veriler yüklenemedi. Yenilemek için aşağı çek.';

  @override
  String get referralRetry => 'Tekrar dene';

  @override
  String get referralSettingsTile => 'Arkadaşlarını davet et';

  @override
  String get referralAfterReviewCta =>
      'Beğendin mi? Bir arkadaşını davet et — ikiniz de bir ay ücretsiz kazanın.';

  @override
  String get referralAntiFraud => 'Yılda en fazla 12 başarılı yönlendirme.';

  @override
  String get referralEmpty =>
      'Henüz yönlendirme yok. Kazanmaya başlamak için bağlantınızı gönderin.';

  @override
  String get referralRecentActivity => 'Son etkinlik';

  @override
  String referralActivityInvited(String when) {
    return 'Davet edildi $when';
  }

  @override
  String referralActivityActivated(String when) {
    return 'etkinleştirildi $when';
  }

  @override
  String get referralActivityPending => 'henüz etkinleştirilmedi';

  @override
  String referralStatsInvitedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arkadaş',
      one: '1 arkadaş',
      zero: 'henüz arkadaş davet etmediniz',
    );
    return '$_temp0 davet ettiniz';
  }

  @override
  String referralStatsConvertedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tanesi etkinleştirildi',
      one: '1 tanesi etkinleştirildi',
      zero: 'henüz hiçbiri etkinleştirilmedi',
    );
    return '$_temp0';
  }

  @override
  String referralStatsEarnedCount(int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months ücretsiz ay',
      one: '1 ücretsiz ay',
      zero: 'henüz yok',
    );
    return 'Bonusunuz: $_temp0';
  }

  @override
  String get referralNudgeMessage =>
      'Advocat\'ı beğendiniz mi? Bir arkadaşınızı davet edin — ikiniz de bir ücretsiz ay kazanın.';

  @override
  String get referralNudgeAction => 'Davet et';

  @override
  String get referralLandingTitle => 'Advocat\'a davet edildiniz';

  @override
  String referralLandingSubtitle(String inviterName) {
    return '$inviterName sizi davet etti — ücretsiz ilk ayınızı talep edin.';
  }

  @override
  String get referralLandingSubtitleGeneric =>
      'Advocat Pro\'nun ücretsiz ilk ayını talep edin.';

  @override
  String get referralLandingCta => 'Ücretsiz ayı etkinleştir ve kaydol';

  @override
  String get referralLandingCtaSecondary =>
      'Veya Advocat hakkında daha fazla bilgi edinin';

  @override
  String get referralLandingFallback =>
      'Bu bağlantının süresi doldu — ancak yine de Advocat\'ı ücretsiz deneyebilirsiniz.';

  @override
  String get referralLandingBenefits =>
      '17 dil • Gerçek Estonya, Finlandiya ve AB hukuku • 7/24 — bekleme yok';

  @override
  String get checkerProTagline => 'Profesyonel doğrulama araçları';

  @override
  String get checkerDataSource => 'Resmî kayıtlardan alınan veriler';

  @override
  String get companyCheckerHint => 'Şirket adı veya sicil numarası';

  @override
  String get companyCheckerPriceChip =>
      'Kontrol başına €2.99  •  Pro\'ya dahildir';

  @override
  String get companyCheckerEmptyState =>
      'Tam rapor için şirket adını veya sicil\nnumarasını girin';

  @override
  String get aiMemoryTitle => 'Yapay zekâ hafızası';

  @override
  String get aiMemorySubtitle =>
      'Yapay zekânın sizinle ilgili hatırladıklarını gözden geçirin ve silin';

  @override
  String get bookLawyerCallTitle => 'Avukatla görüşme planlayın';

  @override
  String get bookLawyerCallComingSoonTitle =>
      'Gerçek avukatlarla görüşmeler — yakında';

  @override
  String get bookLawyerCallComingSoonBody =>
      'Pro ve Premium, ortak avukatla 15 dakikalık görüşmeleri kapsar (Pro: 1/çeyrek, Premium: 2/çeyrek). Estonyalı bağımsız avukat ağını tamamlıyoruz; rezervasyon açılır açılmaz size e-posta göndereceğiz.';

  @override
  String bookLawyerCallQuotaAvailable(int remaining, int total) {
    return 'Bu çeyrekte $total aramadan $remaining hakkınız kaldı.';
  }

  @override
  String get bookLawyerCallQuotaExhausted => 'Üç aylık kontenjan kullanıldı.';

  @override
  String get bookLawyerCallQuotaBodyAvailable =>
      'Pro paketi çeyrekte 1, Premium 2 aramayı kapsar. Aramalar 15 dakikadır ve Google Meet üzerinden yapılır.';

  @override
  String get bookLawyerCallQuotaBodyExhausted =>
      'Kontenjanınız bir sonraki çeyreğin ilk günü sıfırlanır. Daha erken konuşmanız mı gerekiyor? Ekstra arama için Premium\'a yükseltin.';

  @override
  String get severityCritical => 'KRİTİK';

  @override
  String get severityHigh => 'YÜKSEK';

  @override
  String get severityMedium => 'ORTA';

  @override
  String get severityLow => 'DÜŞÜK';

  @override
  String get deadlineRequiredFields => 'Başlık ve son tarih zorunludur';

  @override
  String get acceptTermsRequired => 'Lütfen Hizmet Şartlarını kabul edin';

  @override
  String get chatLegalCouncilTooltip => 'Hukuki konsey (4 uzman)';

  @override
  String get attachFileTooltip => 'Dosya ekle';

  @override
  String get sendMessage => 'Mesaj gönder';

  @override
  String get stopGenerating => 'Oluşturmayı durdur';

  @override
  String get showPassword => 'Şifreyi göster';

  @override
  String get hidePassword => 'Şifreyi gizle';

  @override
  String get decreaseDependents => 'Azalt';

  @override
  String get increaseDependents => 'Artır';

  @override
  String get sensitiveConsentTitle => 'Hassas veri onayı';

  @override
  String get sensitiveConsentBody =>
      'Yüklemek üzere olduğunuz belgeler, GDPR Madde 9 kapsamında özel kategori kişisel veriler içerebilir — sağlık kayıtları, sabıka kayıtları, biyometrik veriler veya ırksal kökeniniz, dininiz ya da cinsel yöneliminiz hakkında bilgiler gibi.\n\nBu verileri yalnızca size yapay zeka hukuki yardımı sağlamak için işler, özel hesabınızda şifreli olarak saklar ve modelleri eğitmek için asla kullanmayız. Onayınızı geri çekebilir ve verileri istediğiniz zaman Ayarlar\'dan silebilirsiniz.\n\nKabul ederek, özel kategori verilerin bu amaçla işlenmesi için GDPR Madde 9(2)(a) uyarınca açık onay vermiş olursunuz.';

  @override
  String get sensitiveConsentExplicitCheckbox =>
      'Özel kategori verilerin işlenmesine açık onay veriyorum (GDPR Madde 9(2)(a)).';

  @override
  String get sensitiveConsentRightToShareCheckbox =>
      'Bu verileri paylaşma hakkına sahip olduğumu teyit ediyorum (veriler bana ait ya da üçüncü taraf verilerini paylaşmak için bilgilendirilmiş/yasal dayanağım var).';

  @override
  String get sensitiveConsentViewCategories =>
      'Neyin hassas sayıldığını görüntüle →';

  @override
  String get sensitiveConsentWithdrawAction => 'Hassas veri onayını geri çek';

  @override
  String get privacyAndData => 'GİZLİLİK VE VERİLER';

  @override
  String get exportMyDataSubtitle =>
      'Tüm kişisel verilerinizin bir kopyasını indirin (GDPR Madde 15).';

  @override
  String get withdrawSensitiveConsent => 'Hassas veri onayı';

  @override
  String get withdrawSensitiveConsentSubtitle =>
      'Özel kategori verilerin işlenmesine ilişkin onayı yönetin veya geri çekin (GDPR Madde 9(2)(a)).';

  @override
  String get dataProcessingAgreement => 'Veri İşleme Sözleşmesi';

  @override
  String get exportingData => 'Verileriniz dışa aktarılıyor…';

  @override
  String get exportComplete =>
      'Veri dışa aktarımı hazır — cihazınıza kaydedildi.';

  @override
  String get exportFailed =>
      'Dışa aktarma başarısız oldu. Lütfen tekrar deneyin veya destekle iletişime geçin.';

  @override
  String get quotaExhaustedTitle => 'Ücretsiz mesaj sınırına ulaşıldı';

  @override
  String quotaExhaustedBody(int count) {
    return '$count ücretsiz mesajın tamamını kullandınız. Aylık 19,99 € karşılığında Advocat Counsel\'a yükseltin ve sınırsız yapay zeka hukuki danışmanlığı edinin.';
  }

  @override
  String get quotaExhaustedLater => 'Daha sonra';

  @override
  String get quotaExhaustedUpgrade => 'Advocat Counsel — aylık 19,99 €';

  @override
  String quotaCtaMessage(int count) {
    return '$count ücretsiz mesajın tamamını kullandınız. Aylık 19,99 € karşılığında Advocat Counsel\'a yükseltin.';
  }

  @override
  String get quotaCtaButton => 'Advocat Counsel edinin — aylık 19,99 €';

  @override
  String get aiErrorQuota =>
      'Ücretsiz mesaj sınırına ulaşıldı. Yapay zekayı kullanmaya devam etmek için abone olun.';

  @override
  String get aiErrorAuth =>
      'Yapay zekayı kullanmak için giriş yapmanız gerekir. Lütfen kaydolun veya oturum açın.';

  @override
  String get aiErrorGeneric =>
      'Geçici yapay zeka hatası. Lütfen bir dakika içinde tekrar deneyin. Sorun devam ederse destekle iletişime geçin.';

  @override
  String get tooltipShareCase => 'Dava özetini paylaş';

  @override
  String get tooltipMuteVoice => 'Sesi kapat';

  @override
  String get tooltipUnmuteVoice => 'Sesi aç';

  @override
  String get tooltipAttachDoc => 'Belge ekle';

  @override
  String get aiTypingHint => 'Yapay zeka…';

  @override
  String get error404Title => 'Sayfa bulunamadı';

  @override
  String error404Body(String path) {
    return 'Şunu bulamadık: $path';
  }

  @override
  String get goToHome => 'Ana sayfaya git';

  @override
  String get emailAlreadyRegistered =>
      'Bu e-posta zaten kayıtlı. Oturum açmak ister misiniz?';

  @override
  String get actionSignIn => 'Oturum aç';

  @override
  String get actionUndo => 'Geri al';

  @override
  String get intakeUrgentOpened => 'Sohbet açıldı — taslağınız kaydedildi.';

  @override
  String get panicCoachmark => 'Acil yardım için basılı tutun.';

  @override
  String get panicTitle => 'Şu anda neye ihtiyacınız var?';

  @override
  String get panicCardReadAloud => 'Görevliye yüksek sesle oku';

  @override
  String get panicCardRecord => 'Bu konuşmayı kaydet';

  @override
  String get panicCardCall => 'Bir avukat ara';

  @override
  String get panicCardAi => 'Şimdi Advocat ile konuş';

  @override
  String get panicClose => 'Kapat';

  @override
  String get panicBadgeV2 => 'V2';

  @override
  String get panicRecordV1Title => 'V2\'de geliyor';

  @override
  String get panicRecordV1Body =>
      'Kayıt özelliği Estonya için yasal olarak doğrulanıyor ve V2\'de kullanıma sunulacak. Şimdilik telefonunuzun yerleşik ses kaydedicisini kullanın.';

  @override
  String get panicCallFallbackBody =>
      'kiire@advocat.ee adresine kısa bir açıklamayla e-posta gönderin, sizi geri arayalım.';

  @override
  String get consiliumHeader => 'Avukat konsültasyonu';

  @override
  String consiliumProgress(int count, int total) {
    return '$count / $total hazır';
  }

  @override
  String get consiliumStarting => 'Avukatlar davanızı inceliyor…';

  @override
  String get consiliumDisagreement => 'Uzmanlar aynı fikirde değil';

  @override
  String get consiliumSynthesizing => 'Tavsiye derleniyor…';

  @override
  String consiliumDone(int totalRoles) {
    return 'Konsültasyon tamamlandı · $totalRoles uzman';
  }

  @override
  String get consiliumPositionPush => 'İtiraz et';

  @override
  String get consiliumPositionSettle => 'Uzlaş';

  @override
  String get consiliumPositionInvestigate => 'Araştır';

  @override
  String get consiliumPositionOutOfScope => 'Yetki dışı';

  @override
  String get consiliumConfidence => 'Güven';

  @override
  String get consiliumKeyCitation => 'Temel kaynak';

  @override
  String get consiliumAdversarialRound => 'Çekişmeli tur';

  @override
  String get consiliumViewFullOpinion => 'Tam görüşü gör';

  @override
  String consiliumExpertsAgreed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uzman katılıyor',
    );
    return '$_temp0';
  }

  @override
  String consiliumExpertsDisagree(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uzman katılmıyor',
    );
    return '$_temp0';
  }

  @override
  String get consiliumDisclaimer =>
      'YZ ajanları, insan avukatlar değil. Önemli kararları baroya kayıtlı bir avukatla doğrulayın.';

  @override
  String get softCaseShellBanner =>
      'Bunu takip etmek için \"Başlıksız dava\" oluşturduk. Yeniden adlandırmak için dokunun.';

  @override
  String get softCaseShellBannerCta => 'Yeniden adlandır';

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
  String get iapPayWithApple => 'Apple ile öde';

  @override
  String get iapRestorePurchases => 'Satın alımları geri yükle';

  @override
  String get iapPurchaseFailed =>
      'Satın alma başarısız. Lütfen tekrar deneyin veya destek ile iletişime geçin.';

  @override
  String get iapRestoreSuccess => 'Aboneliğiniz geri yüklendi.';

  @override
  String get iapRestoreNoActive => 'Geri yüklenecek aktif abonelik bulunamadı.';

  @override
  String get deadlineEuRadarTitle => 'EU deadline radar (preview)';

  @override
  String get deadlineEuRadarSubtitle =>
      'Hypothetical EU procedural deadlines — mock data';

  @override
  String get changePassword => 'Şifreyi değiştir';

  @override
  String get changePasswordSubtitle => 'Hesap şifrenizi güncelleyin';

  @override
  String get newPasswordTitle => 'Yeni şifre belirleyin';

  @override
  String get newPasswordHint =>
      'Hesabınız için yeni bir şifre girin ve onaylayın.';

  @override
  String get newPasswordSave => 'Yeni şifreyi kaydet';

  @override
  String get newPasswordSuccess =>
      'Şifre güncellendi. Artık girişte kullanabilirsiniz.';

  @override
  String get newPasswordError => 'Şifre güncellenemedi. Lütfen tekrar deneyin.';

  @override
  String get accessLogTile => 'Erişim kaydı';

  @override
  String get accessLogTileSubtitle =>
      'Verilerinize kimin ve neyin eriştiğini görün';

  @override
  String get accessLogTitle => 'Verilerime ilişkin erişim kaydı';

  @override
  String get accessLogIntro =>
      'Verilerinize her erişildiğinde veya verileriniz her işlendiğinde — yapay zekamız dahil — tutulan, şeffaf ve değiştirilemez bir kayıt. Kaydın değiştirilmediğini doğrulayabilirsiniz.';

  @override
  String get accessLogEmpty => 'Henüz erişim olayı yok.';

  @override
  String get accessLogError =>
      'Erişim kaydınız yüklenemedi. Yeniden denemek için aşağı çekin.';

  @override
  String get accessLogIntegrityOk =>
      'Bütünlük doğrulandı — kayıt bağlantıları kesintisiz bir zincir oluşturuyor.';

  @override
  String get accessLogIntegrityBroken =>
      'Uyarı: kayıt zinciri kırılmış. Bazı kayıtlar kaldırılmış veya yeniden sıralanmış olabilir. Lütfen destek ekibiyle iletişime geçin.';

  @override
  String get accessActionLlmEgress =>
      'İşlenmek üzere yapay zekaya gönderildi (takma adlandırılmış)';

  @override
  String get accessActionAiAnalysis => 'Yapay zeka tarafından analiz edildi';

  @override
  String get accessActionDocumentParse => 'Belge ayrıştırıldı';

  @override
  String get accessActionStaffRead => 'Bir personel tarafından incelendi';

  @override
  String get accessActionExport => 'Veriler dışa aktarıldı';

  @override
  String get accessActionEmailTriage => 'E-posta önceliklendirildi';

  @override
  String get accessActionDeadlineScan => 'Süreler tarandı';

  @override
  String get breachAlertTitle => 'Verilerinize ilişkin güvenlik uyarısı';

  @override
  String get breachAlertBody =>
      'Otomatik izleme sistemimiz, verilerinizle ilgili olağan dışı bir erişim tespit etti. Durumu inceliyoruz ve doğrulanan herhangi bir olayı yasaların gerektirdiği şekilde size bildireceğiz (GDPR Madde 34).';

  @override
  String get caseDossierTitle => 'Dava dosyasını dışa aktar';

  @override
  String get caseDossierSubtitle =>
      'Bir avukata, mahkemeye veya şikayet merciine sunmak için her şeyi içeren tek bir PDF — olgular, kronoloji, süreler ve belgeler.';

  @override
  String get caseDossierTileTitle => 'Dosyayı dışa aktar (PDF)';

  @override
  String get caseDossierTileSubtitle =>
      'Davanın tamamını tek bir dosyayla avukata veya mahkemeye sunun';

  @override
  String get caseDossierSectionsHeading => 'Dosyaya dahil edilecekler';

  @override
  String get caseDossierSectionFacts => 'Dava olguları';

  @override
  String get caseDossierSectionFactsHint => 'Her zaman dahildir';

  @override
  String get caseDossierSectionTimeline => 'Kronoloji';

  @override
  String get caseDossierSectionDeadlines => 'Süreler';

  @override
  String get caseDossierSectionDocuments => 'Belgeler';

  @override
  String get caseDossierSectionAiSummary => 'Yapay zeka özeti';

  @override
  String get caseDossierExportButton => 'PDF olarak dışa aktar';

  @override
  String get caseDossierExporting => 'Dosyanız oluşturuluyor…';

  @override
  String get caseDossierSuccess => 'Dosya hazır. Dosyayı açın veya paylaşın.';

  @override
  String get caseDossierOpen => 'Dosyayı aç';

  @override
  String get caseDossierError => 'Dosya oluşturulamadı. Lütfen tekrar deneyin.';

  @override
  String get caseDossierErrorNotOwned => 'Bu dava bulunamadı.';

  @override
  String get caseDossierDisclaimer =>
      'Dosya, dava verilerinizi kayıtlı olduğu şekilde yansıtır. Paylaşmadan önce inceleyin.';

  @override
  String get followupsTitle => 'Sonraki adımlar';

  @override
  String get followupsSubtitle => 'Davanızı ilerletmek için pratik görevler';

  @override
  String get followupsEmpty => 'Henüz takip adımı yok.';

  @override
  String get followupsEmptyDesc =>
      'Bir adım ekleyin veya yapay zekanın bir sonraki adımı önermesine izin verin.';

  @override
  String get followupsAdd => 'Adım ekle';

  @override
  String get followupsSuggest => 'Adım öner';

  @override
  String get followupsSuggestNone =>
      'Şu anda öneri yok. Dava hakkında sohbet ettikten sonra tekrar deneyin.';

  @override
  String get followupsSuggestTitle => 'Önerilen sonraki adımlar';

  @override
  String get followupsAddPrompt => 'Saklamak istediğiniz adımları ekleyin:';

  @override
  String get followupsNewTitleHint => 'Ne yapılması gerekiyor?';

  @override
  String get followupsNewDetailHint =>
      'İsteğe bağlı not (neden / neyin ekleneceği)';

  @override
  String get followupsDueOptional => 'Bana hatırlat (isteğe bağlı)';

  @override
  String get followupsOverdue => 'Süresi geçti';

  @override
  String followupsDueOn(String date) {
    return 'Son tarih: $date';
  }

  @override
  String get followupsDone => 'Tamamlandı';

  @override
  String get followupsSnooze => 'Ertele';

  @override
  String get followupsSnooze1Week => 'Bir hafta sonra hatırlat';

  @override
  String get followupsDismiss => 'Yoksay';

  @override
  String get followupsLoadError => 'Sonraki adımlar yüklenemedi';

  @override
  String get followupsAiBadge => 'Yapay zeka';

  @override
  String get contractCompareTitle => 'Sürümleri karşılaştır';

  @override
  String get contractCompareIntro =>
      'Aynı sözleşmenin iki sürümünü yükleyin. Neyin değiştiğini ve her değişikliğin lehinize mi yoksa aleyhinize mi olduğunu vurgularız.';

  @override
  String get contractCompareOldVersion => 'Eski sürüm (v1)';

  @override
  String get contractCompareNewVersion => 'Yeni sürüm (v2)';

  @override
  String get contractCompareCta => 'Sürümleri karşılaştır';

  @override
  String get contractCompareAdverse => 'Aleyhte';

  @override
  String get contractCompareFavorable => 'Lehte';

  @override
  String get contractCompareNeutral => 'Nötr';

  @override
  String get contractCompareBefore => 'Önce';

  @override
  String get contractCompareAfter => 'Sonra';

  @override
  String get contractCompareTruncated =>
      'Uzun sözleşme — her sürümün yalnızca ilk bölümü karşılaştırıldı.';

  @override
  String get contractCompareNoChanges =>
      'İki sürüm arasında esaslı bir değişiklik tespit edilmedi.';

  @override
  String get docSearchTitle => 'Belgelerimde ara';

  @override
  String get docSearchHint => 'örn. depozito nerede belirtildi';

  @override
  String get docSearchSubtitle =>
      'Kasanız ve dava dosyalarınız genelinde anlamsal arama';

  @override
  String get docSearchIdle =>
      'Yalnızca başlıklarda değil, kendi belgelerinizin içeriğinde arama yapın.';

  @override
  String get docSearchNoResults => 'Belgelerinizde eşleşme bulunamadı.';

  @override
  String get docSearchError => 'Arama başarısız oldu. Lütfen tekrar deneyin.';

  @override
  String get docSearchUntitled => 'Başlıksız belge';

  @override
  String get docSearchKindCase => 'Dava belgesi';

  @override
  String get docSearchKindVault => 'Kasa belgesi';

  @override
  String get docSearchMenuTitle => 'Belgelerimde ara';

  @override
  String get docSearchMenuSubtitle =>
      'Kendi dosyalarınızda her şeyi anlamına göre bulun';

  @override
  String get legalTemplatesTitle => 'Şablon kütüphanesi';

  @override
  String get legalTemplatesMenuLabel => 'Şablonlar';

  @override
  String get legalTemplatesSubtitle =>
      'Hazır bir form seçin, birkaç ayrıntıyı doldurun; düzenleyip dışa aktarabileceğiniz bir taslak oluşturalım.';

  @override
  String get legalTemplatesDisclaimer =>
      'Bunlar genel örnek formlardır, bireysel hukuki danışmanlık değildir. Göndermeden önce inceleyip uyarlayın.';

  @override
  String get legalTemplatesSampleBadge => 'Örnek';

  @override
  String get legalTemplatesEmpty => 'Bu filtre için henüz şablon yok.';

  @override
  String get legalTemplatesError =>
      'Şablonlar yüklenemedi. Lütfen tekrar deneyin.';

  @override
  String get legalTemplatesFilterAll => 'Tümü';

  @override
  String get legalTemplatesJurisdictionFi => 'Finlandiya';

  @override
  String get legalTemplatesJurisdictionEe => 'Estonya';

  @override
  String get legalTemplatesCategoryComplaint => 'Şikayetler';

  @override
  String get legalTemplatesCategoryAppeal => 'İtirazlar';

  @override
  String get legalTemplatesCategoryApplication => 'Başvurular';

  @override
  String get legalTemplatesCategoryClaim => 'Talepler';

  @override
  String get legalTemplatesCategoryRequest => 'İstekler';

  @override
  String get legalTemplatesFillTitle => 'Ayrıntıları doldurun';

  @override
  String get legalTemplatesFillIntro =>
      'Adınızı ve dava ayrıntılarınızı otomatik dolduracağız. Aşağıdaki alanları tamamlayın.';

  @override
  String get legalTemplatesFieldRequired => 'Bu alan zorunludur';

  @override
  String get legalTemplatesCreateDraft => 'Taslak oluştur';

  @override
  String get legalTemplatesCreating => 'Taslak oluşturuluyor…';

  @override
  String get legalTemplatesCreateFailed =>
      'Taslak oluşturulamadı. Lütfen tekrar deneyin.';

  @override
  String get legalTemplatesUnresolvedWarning =>
      'Bazı alanlar hâlâ boş ve taslakta ____ ile işaretlenmiştir. Bunları düzenleyicide tamamlayabilirsiniz.';

  @override
  String get legalTemplatesFieldRecipient => 'Alıcı (makam / ev sahibi)';

  @override
  String get legalTemplatesFieldAddress => 'Posta adresiniz';

  @override
  String get legalTemplatesFieldSubject => 'Konu';

  @override
  String get legalTemplatesFieldDescription => 'Konunun açıklaması';

  @override
  String get legalTemplatesFieldDemand => 'Talebiniz';

  @override
  String get checklistActionPlan => 'Eylem planı';

  @override
  String get checklistActionPlanSubtitle => 'Bu tür davalar için adımlar';

  @override
  String checklistProgress(int completed, int total) {
    return '$total adımdan $completed tanesi tamamlandı';
  }

  @override
  String get checklistAllDone => 'Tüm adımlar tamamlandı';

  @override
  String get checklistEmpty =>
      'Bu dava türü için henüz bir eylem planı mevcut değil.';

  @override
  String checklistDeadlineDays(int days) {
    return '$days gün';
  }

  @override
  String get checklistDisclaimer =>
      'Bu genel bilgidir, hukuki danışmanlık değildir. Süreler yasal varsayılan değerlerdir — davanız için kesin tarihi teyit edin.';

  @override
  String get checklistViewPlan => 'Planı görüntüle';

  @override
  String get explainPlainTitle => 'Sade bir dille açıkla';

  @override
  String get explainPlainIntro =>
      'Resmi bir mektubu, kararı veya sözleşmeyi yapıştırın; ne anlama geldiğini ve sizden ne yapmanızı istediğini sade bir dille açıklayalım.';

  @override
  String get explainPlainLevelFriend => 'Bir arkadaşa anlatır gibi';

  @override
  String get explainPlainLevelTerms => 'Hukuki terimleri koru';

  @override
  String get explainPlainInputHint => 'Hukuki metni buraya yapıştırın…';

  @override
  String get explainPlainSubmit => 'Açıkla';

  @override
  String get explainPlainWorking => 'Açıklanıyor…';

  @override
  String get explainPlainTldr => 'Özetle';

  @override
  String get explainPlainBreakdown => 'Bölüm bölüm ne söylüyor';

  @override
  String get explainPlainGlossary => 'Zor terimlerin açıklaması';

  @override
  String get explainPlainNextSteps => 'Bundan sonra ne yapabilirsiniz';

  @override
  String get explainPlainOpenInCorpus => 'Hukuk kütüphanesinde ara';

  @override
  String get explainPlainEmptyResult =>
      'Bu metin için bir açıklama üretilemedi. Daha uzun veya daha net bir bölüm yapıştırmayı deneyin.';

  @override
  String get explainPlainQuotaTitle =>
      'Bu ay için ücretsiz açıklamalarınızı kullandınız';

  @override
  String get explainPlainQuotaBody =>
      'Ücretsiz hesaplar ayda 3 açıklama alır. Sınırsız açıklama için Pro\'ya yükseltin.';

  @override
  String get explainPlainUpgradeCta => 'Pro\'ya yükselt';

  @override
  String get explainPlainError =>
      'Bu metni açıklarken bir sorun oluştu. Lütfen tekrar deneyin.';

  @override
  String get explainPlainRetry => 'Tekrar dene';

  @override
  String get demandLetterTitle => 'İhtarname';

  @override
  String get demandLetterSubtitle =>
      'Resmi bir mahkeme öncesi ihtarname oluşturun (maksuvaatimus / nõudekiri).';

  @override
  String get demandLetterStepType => 'Talep türü';

  @override
  String get demandLetterStepParties => 'Taraflar';

  @override
  String get demandLetterStepClaim => 'Tutar ve dayanak';

  @override
  String get demandLetterStepDeadline => 'Süre';

  @override
  String get demandLetterStepReview => 'İncele ve oluştur';

  @override
  String get demandLetterClaimDepositReturn => 'Kira depozitosunun iadesi';

  @override
  String get demandLetterClaimUnpaidWage => 'Ödenmemiş ücretler';

  @override
  String get demandLetterClaimFineDispute => 'Bir cezaya / ücrete itiraz';

  @override
  String get demandLetterClaimGeneric => 'Diğer parasal talep';

  @override
  String get demandLetterJurisdiction => 'Yargı yetkisi';

  @override
  String get demandLetterLanguage => 'Mektup dili';

  @override
  String get demandLetterRecipientName => 'Alıcı adı';

  @override
  String get demandLetterRecipientAddress => 'Alıcı adresi (isteğe bağlı)';

  @override
  String get demandLetterSenderName => 'Adınız';

  @override
  String get demandLetterSenderAddress =>
      'Adresiniz / e-postanız (isteğe bağlı)';

  @override
  String get demandLetterAmount => 'Tutar';

  @override
  String get demandLetterCurrency => 'Para birimi';

  @override
  String get demandLetterBasis => 'Ne oldu (talebin dayanağı)';

  @override
  String get demandLetterBasisHint =>
      'Olguları açıklayın: tarihler, tutarlar, neyin kararlaştırıldığı ve neyin ters gittiği.';

  @override
  String get demandLetterDeadline => 'Ödeme süresi';

  @override
  String get demandLetterDeadlineHint => 'örn. bugünden itibaren 14 gün';

  @override
  String get demandLetterReference => 'Referans (isteğe bağlı)';

  @override
  String get demandLetterGenerate => 'Mektubu oluştur';

  @override
  String get demandLetterGenerating => 'Oluşturuluyor…';

  @override
  String get demandLetterGenerateFailed =>
      'Mektup oluşturulamadı. Lütfen tekrar deneyin.';

  @override
  String get demandLetterFieldRequired => 'Bu alan zorunludur';

  @override
  String get demandLetterNext => 'İleri';

  @override
  String get demandLetterBack => 'Geri';

  @override
  String get demandLetterPreviewTitle => 'Mektubunuz';

  @override
  String get demandLetterCopy => 'Metni kopyala';

  @override
  String get demandLetterCopied => 'Mektup panoya kopyalandı';

  @override
  String get demandLetterExportPdf => 'PDF olarak dışa aktar';

  @override
  String get demandLetterExporting => 'Dışa aktarılıyor…';

  @override
  String get demandLetterExportFailed =>
      'Belge dışa aktarılamadı. Lütfen tekrar deneyin.';

  @override
  String get demandLetterSendEmail => 'E-posta ile gönder';

  @override
  String get demandLetterNormsTitle => 'Hukuki referanslar';

  @override
  String get demandLetterDisclaimer =>
      'Bu mektup, genel bir şablon olarak sizin adınıza hazırlanmıştır. Hukuki danışmanlık veya lisanslı bir avukatın işlemi değildir. Göndermeden önce inceleyin — hiçbir mektup otomatik olarak gönderilmez.';

  @override
  String get demandLetterMenuTile => 'İhtarname';

  @override
  String get calcHubTitle => 'Hukuki hesaplayıcılar';

  @override
  String get calcHubSubtitle => 'Bir sonraki adımınızdan önce hızlı tahminler';

  @override
  String get calcHubJurisdiction => 'Yargı yetkisi';

  @override
  String calcRatesAsOf(String date) {
    return '$date tarihli oranlar';
  }

  @override
  String get calcRatesOffline =>
      'Önbelleğe alınmış oranlar gösteriliyor (çevrimdışı)';

  @override
  String get calcIndicativeBanner =>
      'Yalnızca yaklaşık bir tahmin — resmi bir hesaplama veya hukuki danışmanlık değildir.';

  @override
  String get calcCalculate => 'Hesapla';

  @override
  String get calcResult => 'Sonuç';

  @override
  String get calcFormula => 'Bu nasıl hesaplanır';

  @override
  String get calcSource => 'Kaynak';

  @override
  String get calcSeveranceTitle => 'Kıdem / ihbar';

  @override
  String get calcSeveranceDesc =>
      'İşten çıkarmada kıdem tazminatını ve ihbar süresini tahmin edin';

  @override
  String get calcSeveranceSalary => 'Brüt aylık maaş';

  @override
  String get calcSeveranceTenure => 'Hizmet yılı';

  @override
  String get calcSeveranceTotal => 'Tahmini kıdem tazminatı';

  @override
  String get calcSeveranceNotice => 'İhbar süresi';

  @override
  String get calcSeveranceGenerateDemand => 'İhtarname taslağı oluştur';

  @override
  String get calcLimitationTitle => 'Zamanaşımı ve itiraz süreleri';

  @override
  String get calcLimitationDesc =>
      'Bir talep veya itiraz süresinin dolup dolmadığını kontrol edin';

  @override
  String get calcLimitationType => 'Süre türü';

  @override
  String get calcLimitationStart => 'Başlangıç tarihi (olay / karar)';

  @override
  String get calcLimitationPickDate => 'Tarih seç';

  @override
  String get calcLimitationDeadline => 'Son tarih';

  @override
  String get calcLimitationExpired => 'Süre dolmuştur';

  @override
  String calcLimitationDaysLeft(int days) {
    return '$days gün kaldı';
  }

  @override
  String get calcLimitationShifted =>
      'Bir sonraki iş gününe kaydırıldı (hafta sonu/tatil).';

  @override
  String get calcLimitationAddDeadline => 'Sürelere ekle';

  @override
  String get calcStateFeeTitle => 'Mahkeme / devlet harçları';

  @override
  String get calcStateFeeDesc =>
      'Mahkeme ve aşamaya göre başvuru harçları referansı';

  @override
  String get calcChildSupportTitle => 'Nafaka (yönlendirme amaçlı)';

  @override
  String get calcChildSupportDesc =>
      'Kabaca bir yönlendirme rakamı — gerçek tutar dava bazında belirlenir';

  @override
  String get calcChildSupportNet => 'Ödeyenin aylık net geliri';

  @override
  String get calcChildSupportChildren => 'Çocuk sayısı';

  @override
  String get calcChildSupportPerChild => 'Çocuk başına';

  @override
  String get calcChildSupportTotal => 'Aylık toplam';

  @override
  String get calcChildSupportWarning =>
      'Büyük ölçüde değişkendir. Mahkemeler çocuğun ihtiyaçlarına ve her iki ebeveynin ödeme gücüne göre karar verir. Yalnızca bir başlangıç noktası olarak kullanın.';

  @override
  String get docCollectTitle => 'Toplanacak belgeler';

  @override
  String get docCollectSubtitle =>
      'Başvuru yapmadan veya mahkemeye gitmeden önce bunları toplayın';

  @override
  String get docCollectPickPrompt => 'Durumunuz nedir?';

  @override
  String get docCollectProblemResidence => 'Oturma izni';

  @override
  String get docCollectProblemTenant => 'Kira / tahliye';

  @override
  String get docCollectProblemDismissal => 'İşten çıkarılma';

  @override
  String get docCollectProblemInheritance => 'Miras';

  @override
  String get docCollectProblemDivorce => 'Boşanma';

  @override
  String docCollectProgress(int collected, int total) {
    return '$total belgeden $collected tanesi toplandı';
  }

  @override
  String get docCollectAllDone => 'Her şey toplandı';

  @override
  String get docCollectEmpty =>
      'Bu durum için henüz bir belge listesi mevcut değil.';

  @override
  String get docCollectOptional => 'İsteğe bağlı';

  @override
  String get docCollectWhereLabel => 'Nereden alınır';

  @override
  String get docCollectWhyLabel => 'Neden gerekli';

  @override
  String get docCollectAttach => 'Dosya ekle';

  @override
  String get docCollectAttached => 'Dosya eklendi';

  @override
  String get docCollectChangeFile => 'Dosyayı değiştir';

  @override
  String get docCollectRemoveFile => 'Dosyayı kaldır';

  @override
  String get docCollectNoFiles => 'Henüz hiç belge yüklemediniz.';

  @override
  String get docCollectPickFileTitle => 'Yüklenmiş bir belge seçin';

  @override
  String get docCollectExport => 'Listeyi dışa aktar';

  @override
  String get docCollectExportSubject => 'Belge kontrol listem';

  @override
  String get docCollectAiTitle => 'Belirli bir şeye mi ihtiyacınız var?';

  @override
  String get docCollectAiHint => 'Durumunuzu açıklayın; ek belgeler önerelim.';

  @override
  String get docCollectAiField => 'Durumunuzu açıklayın';

  @override
  String get docCollectAiButton => 'Ek belge öner';

  @override
  String get docCollectAiLoading => 'Düşünülüyor…';

  @override
  String get docCollectAiEmpty =>
      'Ek belge önerilmedi — temel liste açıklamanız için yeterli görünüyor.';

  @override
  String get docCollectAiSuggestionsTitle => 'Önerilen ek belgeler';

  @override
  String get docCollectDisclaimer =>
      'Bu, yaygın olarak istenen belgelerin temel bir listesidir — durumunuz daha fazla veya daha az belge gerektirebilir. Bu genel bilgidir, hukuki danışmanlık değildir.';

  @override
  String get docCollectRetry => 'Tekrar dene';

  @override
  String get renewalTitle => 'Yenileme Radarı';

  @override
  String get renewalSubtitle =>
      'İzinlerinizin, pasaportunuzun, sigortanızın ve diğer belgelerinizin ne zaman sona ereceğini takip edin. Her yenilemeden 90, 30 ve 7 gün önce size hatırlatırız.';

  @override
  String get renewalAdd => 'Belge ekle';

  @override
  String get renewalEditTitle => 'Belgeyi düzenle';

  @override
  String get renewalSave => 'Kaydet';

  @override
  String get renewalRequired => 'Zorunlu';

  @override
  String get renewalPickDate => 'Son geçerlilik tarihi seç';

  @override
  String get renewalLoadError =>
      'Belgeleriniz yüklenemedi. Yenilemek için çekin.';

  @override
  String get renewalEmptyTitle => 'Henüz takip edilen belge yok';

  @override
  String get renewalEmptyBody =>
      'Oturma izninizi, pasaportunuzu, sigortanızı veya ruhsatınızı ekleyin; son geçerlilik tarihlerini sizin için izleyelim.';

  @override
  String get renewalGuideHint => 'Nasıl yenilenir →';

  @override
  String get renewalFieldType => 'Belge türü';

  @override
  String get renewalFieldLabel => 'Etiket';

  @override
  String get renewalFieldNumber => 'Belge numarası (isteğe bağlı)';

  @override
  String get renewalFieldJurisdiction => 'Düzenleyen ülke';

  @override
  String get renewalFieldExpiry => 'Son geçerlilik tarihi';

  @override
  String get renewalWindow90 => '90 gün';

  @override
  String get renewalWindow30 => '30 gün';

  @override
  String get renewalWindow7 => '7 gün';

  @override
  String get renewalExpiresToday => 'Bugün sona eriyor';

  @override
  String renewalExpiresInDays(int days, String date) {
    return '$days gün içinde sona eriyor · $date';
  }

  @override
  String renewalExpiredOn(String date) {
    return '$date tarihinde sona erdi';
  }

  @override
  String get renewalTypeResidencePermit => 'Oturma izni';

  @override
  String get renewalTypePassport => 'Pasaport';

  @override
  String get renewalTypeIdCard => 'Kimlik kartı';

  @override
  String get renewalTypeVisa => 'Vize';

  @override
  String get renewalTypeDrivingLicence => 'Sürücü belgesi';

  @override
  String get renewalTypeInsurance => 'Sigorta';

  @override
  String get renewalTypeWorkPermit => 'Çalışma izni';

  @override
  String get renewalTypeOther => 'Diğer';

  @override
  String get costEstimateTitle => 'Maliyet ve Risk Tahmincisi';

  @override
  String get costEstimateSubtitle =>
      'Bir davanın ne kadara mal olabileceği, ne kadar sürebileceği ve takip etmeye değip değmeyeceği hakkında kabaca bir fikir edinin.';

  @override
  String get costEstimateCaseTypeLabel => 'Dava türü';

  @override
  String get costEstimateCaseTypeHint =>
      'örn. ödenmemiş fatura, haksız işten çıkarma, depozito anlaşmazlığı';

  @override
  String get costEstimateJurisdictionLabel => 'Yargı yetkisi';

  @override
  String get costEstimateAmountLabel => 'Uyuşmazlık tutarı (isteğe bağlı)';

  @override
  String get costEstimateAmountHint => 'örn. 12500';

  @override
  String get costEstimateDescriptionLabel =>
      'Durumu kısaca açıklayın (isteğe bağlı)';

  @override
  String get costEstimateB2bToggle => 'Müşteri değerlendirme kartı (B2B)';

  @override
  String get costEstimateB2bSubtitle =>
      'Gelen bir müşteriyi hızlıca önceliklendirmek için kompakt çıktı.';

  @override
  String get costEstimateSubmit => 'Davamı tahmin et';

  @override
  String get costEstimateDisclaimer =>
      'Yalnızca kabaca bir tahmin — bir öngörü, garanti veya hukuki danışmanlık değildir. Gerçek maliyetler ve sonuçlar dava bazında değişir.';

  @override
  String get costEstimateCostsHeading => 'Tahmini maliyetler';

  @override
  String get costEstimateCourtFee => 'Mahkeme / devlet harcı';

  @override
  String get costEstimateLawyerFee => 'Avukatlık ücreti';

  @override
  String get costEstimateTotal => 'Toplam (yaklaşık)';

  @override
  String get costEstimateDuration => 'İlk sonuca kadar geçen süre';

  @override
  String get costEstimateMonthsSuffix => 'ay';

  @override
  String get costEstimateFactorsFor => 'Lehinize';

  @override
  String get costEstimateFactorsAgainst => 'Aleyhinize';

  @override
  String get costEstimateStrengthWorth => 'Takip etmeye değer olabilir';

  @override
  String get costEstimateStrengthContested =>
      'İhtilaflı — her iki yöne de gidebilir';

  @override
  String get costEstimateStrengthWeak => 'Zayıf — dikkatli ilerleyin';
}
