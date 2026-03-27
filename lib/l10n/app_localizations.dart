import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_et.dart';
import 'app_localizations_fi.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_sv.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('et'),
    Locale('fi'),
    Locale('ru'),
    Locale('sv')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Advocat — Legal Information Tool'**
  String get appTitle;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'AI-Powered Legal Information'**
  String get onboardingTitle1;

  /// No description provided for @onboardingDesc1.
  ///
  /// In en, this message translates to:
  /// **'Advocat helps you understand your legal situation. AI tools analyze documents, identify potential issues, and prepare draft documents for your review. Not a law firm — a technology tool to support your case.'**
  String get onboardingDesc1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Scan and Analyze Documents'**
  String get onboardingTitle2;

  /// No description provided for @onboardingDesc2.
  ///
  /// In en, this message translates to:
  /// **'Photograph any legal document. AI reads it in multiple languages, extracts key details, and checks against EU directives and national laws for potential issues.'**
  String get onboardingDesc2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'AI Checks for Potential Issues'**
  String get onboardingTitle3;

  /// No description provided for @onboardingDesc3.
  ///
  /// In en, this message translates to:
  /// **'Our AI tools check 40+ types of procedural requirements. AI analysis may identify issues that require attention — such as language of service, procedural steps, and legal deadlines. Always verify with a qualified lawyer.'**
  String get onboardingDesc3;

  /// No description provided for @onboardingTitle4.
  ///
  /// In en, this message translates to:
  /// **'Draft Documents for Your Review'**
  String get onboardingTitle4;

  /// No description provided for @onboardingDesc4.
  ///
  /// In en, this message translates to:
  /// **'AI prepares draft appeals, complaints, and letters with legal references for your review. You decide what to submit. Every document should be reviewed by a qualified legal professional before filing.'**
  String get onboardingDesc4;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to access your cases'**
  String get signInSubtitle;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get logIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get signUp;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orDivider;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get noAccount;

  /// No description provided for @signUpLink.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUpLink;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// No description provided for @signInLink.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get signInLink;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get emailInvalid;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordTooShort;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get nameRequired;

  /// No description provided for @termsRequired.
  ///
  /// In en, this message translates to:
  /// **'You must agree to the Terms of Service'**
  String get termsRequired;

  /// No description provided for @agreeToTerms.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get agreeToTerms;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @andWord.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get andWord;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @preferredLanguage.
  ///
  /// In en, this message translates to:
  /// **'Preferred Language'**
  String get preferredLanguage;

  /// No description provided for @langEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @langRussian.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get langRussian;

  /// No description provided for @langFinnish.
  ///
  /// In en, this message translates to:
  /// **'Finnish'**
  String get langFinnish;

  /// No description provided for @passwordStrengthWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get passwordStrengthWeak;

  /// No description provided for @passwordStrengthMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get passwordStrengthMedium;

  /// No description provided for @passwordStrengthStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get passwordStrengthStrong;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password. Please try again.'**
  String get loginFailed;

  /// No description provided for @registerFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed. Please try again.'**
  String get registerFailed;

  /// No description provided for @resetPasswordSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset link sent to your email.'**
  String get resetPasswordSent;

  /// No description provided for @resetPasswordFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send reset link. Please try again.'**
  String get resetPasswordFailed;

  /// No description provided for @myCases.
  ///
  /// In en, this message translates to:
  /// **'My Cases'**
  String get myCases;

  /// No description provided for @newCase.
  ///
  /// In en, this message translates to:
  /// **'New Case'**
  String get newCase;

  /// No description provided for @noCases.
  ///
  /// In en, this message translates to:
  /// **'No cases yet'**
  String get noCases;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @timeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timeline;

  /// No description provided for @aiAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Legal Assistant'**
  String get aiAssistant;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @disclaimer.
  ///
  /// In en, this message translates to:
  /// **'AI guidance only — not legal advice. Always consult a lawyer.'**
  String get disclaimer;

  /// No description provided for @scanDocument.
  ///
  /// In en, this message translates to:
  /// **'Scan Document'**
  String get scanDocument;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @saveAndAnalyze.
  ///
  /// In en, this message translates to:
  /// **'Save & Analyze'**
  String get saveAndAnalyze;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @cases.
  ///
  /// In en, this message translates to:
  /// **'Cases'**
  String get cases;

  /// No description provided for @deadlines.
  ///
  /// In en, this message translates to:
  /// **'Deadlines'**
  String get deadlines;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning, {name}'**
  String goodMorning(String name);

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon, {name}'**
  String goodAfternoon(String name);

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening, {name}'**
  String goodEvening(String name);

  /// No description provided for @caseOverview.
  ///
  /// In en, this message translates to:
  /// **'Here is your case overview'**
  String get caseOverview;

  /// No description provided for @activeCases.
  ///
  /// In en, this message translates to:
  /// **'Active Cases'**
  String get activeCases;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @urgentDeadline.
  ///
  /// In en, this message translates to:
  /// **'Urgent: {title}'**
  String urgentDeadline(String title);

  /// No description provided for @daysRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String daysRemaining(int count);

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @markComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark complete'**
  String get markComplete;

  /// No description provided for @deportation.
  ///
  /// In en, this message translates to:
  /// **'Deportation'**
  String get deportation;

  /// No description provided for @criminalCase.
  ///
  /// In en, this message translates to:
  /// **'Criminal Case'**
  String get criminalCase;

  /// No description provided for @asylum.
  ///
  /// In en, this message translates to:
  /// **'Asylum'**
  String get asylum;

  /// No description provided for @residencePermit.
  ///
  /// In en, this message translates to:
  /// **'Residence Permit'**
  String get residencePermit;

  /// No description provided for @victimSupport.
  ///
  /// In en, this message translates to:
  /// **'Victim Support'**
  String get victimSupport;

  /// No description provided for @familyReunification.
  ///
  /// In en, this message translates to:
  /// **'Family Reunification'**
  String get familyReunification;

  /// No description provided for @laborDispute.
  ///
  /// In en, this message translates to:
  /// **'Labor Dispute'**
  String get laborDispute;

  /// No description provided for @tenantRights.
  ///
  /// In en, this message translates to:
  /// **'Tenant Rights'**
  String get tenantRights;

  /// No description provided for @debtCollection.
  ///
  /// In en, this message translates to:
  /// **'Debt Collection'**
  String get debtCollection;

  /// No description provided for @discrimination.
  ///
  /// In en, this message translates to:
  /// **'Discrimination'**
  String get discrimination;

  /// No description provided for @policeMisconduct.
  ///
  /// In en, this message translates to:
  /// **'Police Misconduct'**
  String get policeMisconduct;

  /// No description provided for @socialBenefits.
  ///
  /// In en, this message translates to:
  /// **'Social Benefits'**
  String get socialBenefits;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @caseDetail.
  ///
  /// In en, this message translates to:
  /// **'Case Details'**
  String get caseDetail;

  /// No description provided for @aiAnalysis.
  ///
  /// In en, this message translates to:
  /// **'AI Analysis'**
  String get aiAnalysis;

  /// No description provided for @draftAppeal.
  ///
  /// In en, this message translates to:
  /// **'Draft Appeal'**
  String get draftAppeal;

  /// No description provided for @aiChat.
  ///
  /// In en, this message translates to:
  /// **'AI Chat'**
  String get aiChat;

  /// No description provided for @correspondence.
  ///
  /// In en, this message translates to:
  /// **'Correspondence'**
  String get correspondence;

  /// No description provided for @analyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing...'**
  String get analyzing;

  /// No description provided for @readingDocument.
  ///
  /// In en, this message translates to:
  /// **'Reading document...'**
  String get readingDocument;

  /// No description provided for @checkingErrors.
  ///
  /// In en, this message translates to:
  /// **'Checking for errors...'**
  String get checkingErrors;

  /// No description provided for @researchingLaw.
  ///
  /// In en, this message translates to:
  /// **'Researching applicable law...'**
  String get researchingLaw;

  /// No description provided for @issuesFound.
  ///
  /// In en, this message translates to:
  /// **'{count} issues found'**
  String issuesFound(int count);

  /// No description provided for @critical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get critical;

  /// No description provided for @important.
  ///
  /// In en, this message translates to:
  /// **'Important'**
  String get important;

  /// No description provided for @informational.
  ///
  /// In en, this message translates to:
  /// **'Informational'**
  String get informational;

  /// No description provided for @useInAppeal.
  ///
  /// In en, this message translates to:
  /// **'Use in Appeal'**
  String get useInAppeal;

  /// No description provided for @addedToAppeal.
  ///
  /// In en, this message translates to:
  /// **'Added to Appeal'**
  String get addedToAppeal;

  /// No description provided for @generateAppeal.
  ///
  /// In en, this message translates to:
  /// **'Generate Appeal'**
  String get generateAppeal;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// No description provided for @sendViaEmail.
  ///
  /// In en, this message translates to:
  /// **'Send via Email'**
  String get sendViaEmail;

  /// No description provided for @copyText.
  ///
  /// In en, this message translates to:
  /// **'Copy Text'**
  String get copyText;

  /// No description provided for @editDraft.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editDraft;

  /// No description provided for @saveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveDraft;

  /// No description provided for @reviewWarning.
  ///
  /// In en, this message translates to:
  /// **'Review carefully before sending. You are responsible for the content.'**
  String get reviewWarning;

  /// No description provided for @disclaimerFull.
  ///
  /// In en, this message translates to:
  /// **'This is an AI assistant, not a lawyer. AI analysis may contain errors. Always verify with a qualified legal professional.'**
  String get disclaimerFull;

  /// No description provided for @askAboutCase.
  ///
  /// In en, this message translates to:
  /// **'Analyze my case'**
  String get askAboutCase;

  /// No description provided for @whatAreMyOptions.
  ///
  /// In en, this message translates to:
  /// **'What are my options?'**
  String get whatAreMyOptions;

  /// No description provided for @checkDeadlines.
  ///
  /// In en, this message translates to:
  /// **'Check deadlines'**
  String get checkDeadlines;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessage;

  /// No description provided for @connectEmail.
  ///
  /// In en, this message translates to:
  /// **'Connect Email'**
  String get connectEmail;

  /// No description provided for @connectGmail.
  ///
  /// In en, this message translates to:
  /// **'Connect Gmail'**
  String get connectGmail;

  /// No description provided for @connectOutlook.
  ///
  /// In en, this message translates to:
  /// **'Connect Outlook'**
  String get connectOutlook;

  /// No description provided for @emailConnected.
  ///
  /// In en, this message translates to:
  /// **'Email connected'**
  String get emailConnected;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNow;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @emailPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'We only read legal-related emails. Your personal emails stay private.'**
  String get emailPrivacyNote;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @deadlineReminders.
  ///
  /// In en, this message translates to:
  /// **'Deadline Reminders'**
  String get deadlineReminders;

  /// No description provided for @deadlineRemindersDesc.
  ///
  /// In en, this message translates to:
  /// **'Get notified before deadlines'**
  String get deadlineRemindersDesc;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @exportMyData.
  ///
  /// In en, this message translates to:
  /// **'Export My Data'**
  String get exportMyData;

  /// No description provided for @exportDataDesc.
  ///
  /// In en, this message translates to:
  /// **'Download all your case data'**
  String get exportDataDesc;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountDesc.
  ///
  /// In en, this message translates to:
  /// **'Permanently remove your account'**
  String get deleteAccountDesc;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure? This will permanently delete all your data.'**
  String get deleteConfirm;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @rateUs.
  ///
  /// In en, this message translates to:
  /// **'Rate Us'**
  String get rateUs;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @tryDemoMode.
  ///
  /// In en, this message translates to:
  /// **'Try Demo Mode'**
  String get tryDemoMode;

  /// No description provided for @demoModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Explore the app with sample data from a real case'**
  String get demoModeDesc;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @basic.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get basic;

  /// No description provided for @pro.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get pro;

  /// No description provided for @emergencyShield.
  ///
  /// In en, this message translates to:
  /// **'Emergency Shield'**
  String get emergencyShield;

  /// No description provided for @legalFighter.
  ///
  /// In en, this message translates to:
  /// **'Legal Fighter'**
  String get legalFighter;

  /// No description provided for @fullDefense.
  ///
  /// In en, this message translates to:
  /// **'Full Defense'**
  String get fullDefense;

  /// No description provided for @popular.
  ///
  /// In en, this message translates to:
  /// **'POPULAR'**
  String get popular;

  /// No description provided for @currentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current Plan'**
  String get currentPlan;

  /// No description provided for @choosePlan.
  ///
  /// In en, this message translates to:
  /// **'Choose Plan'**
  String get choosePlan;

  /// No description provided for @saveWithAnnual.
  ///
  /// In en, this message translates to:
  /// **'Save 25% with annual billing'**
  String get saveWithAnnual;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
  String get restorePurchases;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @caseDescription.
  ///
  /// In en, this message translates to:
  /// **'Describe your situation'**
  String get caseDescription;

  /// No description provided for @caseTitle.
  ///
  /// In en, this message translates to:
  /// **'Case Title'**
  String get caseTitle;

  /// No description provided for @referenceNumber.
  ///
  /// In en, this message translates to:
  /// **'Reference Number'**
  String get referenceNumber;

  /// No description provided for @uploadDocument.
  ///
  /// In en, this message translates to:
  /// **'Upload Document'**
  String get uploadDocument;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'(optional)'**
  String get optional;

  /// No description provided for @step.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String step(int current, int total);

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @createCase.
  ///
  /// In en, this message translates to:
  /// **'Create Case'**
  String get createCase;

  /// No description provided for @searchCases.
  ///
  /// In en, this message translates to:
  /// **'Search cases...'**
  String get searchCases;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @lastActivity.
  ///
  /// In en, this message translates to:
  /// **'Last activity: {time}'**
  String lastActivity(String time);

  /// No description provided for @documentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} docs'**
  String documentsCount(int count);

  /// No description provided for @noCasesYet.
  ///
  /// In en, this message translates to:
  /// **'No cases yet'**
  String get noCasesYet;

  /// No description provided for @startFirstCase.
  ///
  /// In en, this message translates to:
  /// **'Start your first case'**
  String get startFirstCase;

  /// No description provided for @noDeadlines.
  ///
  /// In en, this message translates to:
  /// **'No deadlines — you\'re all clear!'**
  String get noDeadlines;

  /// No description provided for @appealFiled.
  ///
  /// In en, this message translates to:
  /// **'Appeal Filed'**
  String get appealFiled;

  /// No description provided for @pendingDecision.
  ///
  /// In en, this message translates to:
  /// **'Pending Decision'**
  String get pendingDecision;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @won.
  ///
  /// In en, this message translates to:
  /// **'Won'**
  String get won;

  /// No description provided for @lost.
  ///
  /// In en, this message translates to:
  /// **'Lost'**
  String get lost;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'PREFERENCES'**
  String get preferences;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATIONS'**
  String get notifications;

  /// No description provided for @emailIntegration.
  ///
  /// In en, this message translates to:
  /// **'EMAIL INTEGRATION'**
  String get emailIntegration;

  /// No description provided for @dataAndPrivacy.
  ///
  /// In en, this message translates to:
  /// **'DATA & PRIVACY'**
  String get dataAndPrivacy;

  /// No description provided for @legalSection.
  ///
  /// In en, this message translates to:
  /// **'LEGAL'**
  String get legalSection;

  /// No description provided for @aboutSection.
  ///
  /// In en, this message translates to:
  /// **'ABOUT'**
  String get aboutSection;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @signOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signOutConfirm;

  /// No description provided for @emailDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Email disconnected'**
  String get emailDisconnected;

  /// No description provided for @syncLegalCorrespondence.
  ///
  /// In en, this message translates to:
  /// **'Sync legal correspondence'**
  String get syncLegalCorrespondence;

  /// No description provided for @requestExport.
  ///
  /// In en, this message translates to:
  /// **'Request Export'**
  String get requestExport;

  /// No description provided for @exportDataDialogContent.
  ///
  /// In en, this message translates to:
  /// **'We will prepare a download of all your data including cases, documents, and correspondence. You will receive an email when it is ready.'**
  String get exportDataDialogContent;

  /// No description provided for @deleteAccountDialogContent.
  ///
  /// In en, this message translates to:
  /// **'This action is permanent and cannot be undone. All your data, cases, and documents will be permanently deleted.'**
  String get deleteAccountDialogContent;

  /// No description provided for @areYouAbsolutelySure.
  ///
  /// In en, this message translates to:
  /// **'Are you absolutely sure?'**
  String get areYouAbsolutelySure;

  /// No description provided for @typeDeleteToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE to confirm permanent account removal.'**
  String get typeDeleteToConfirm;

  /// No description provided for @permanentlyDelete.
  ///
  /// In en, this message translates to:
  /// **'Permanently Delete'**
  String get permanentlyDelete;

  /// No description provided for @dataExportRequested.
  ///
  /// In en, this message translates to:
  /// **'Data export requested. Check your email.'**
  String get dataExportRequested;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @caseUpdated.
  ///
  /// In en, this message translates to:
  /// **'Case updated'**
  String get caseUpdated;

  /// No description provided for @noRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'No recent activity'**
  String get noRecentActivity;

  /// No description provided for @couldNotLoadCases.
  ///
  /// In en, this message translates to:
  /// **'Could not load your cases'**
  String get couldNotLoadCases;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'ar',
        'de',
        'en',
        'et',
        'fi',
        'ru',
        'sv'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'et':
      return AppLocalizationsEt();
    case 'fi':
      return AppLocalizationsFi();
    case 'ru':
      return AppLocalizationsRu();
    case 'sv':
      return AppLocalizationsSv();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
