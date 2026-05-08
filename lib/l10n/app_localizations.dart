import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_et.dart';
import 'app_localizations_fa.dart';
import 'app_localizations_fi.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_lt.dart';
import 'app_localizations_lv.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_ro.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_sv.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_uk.dart';

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
    Locale('es'),
    Locale('et'),
    Locale('fa'),
    Locale('fi'),
    Locale('fr'),
    Locale('it'),
    Locale('lt'),
    Locale('lv'),
    Locale('pl'),
    Locale('ro'),
    Locale('ru'),
    Locale('sv'),
    Locale('tr'),
    Locale('uk')
  ];

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutSection.
  ///
  /// In en, this message translates to:
  /// **'ABOUT'**
  String get aboutSection;

  /// No description provided for @accidents.
  ///
  /// In en, this message translates to:
  /// **'Accidents'**
  String get accidents;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @activeCases.
  ///
  /// In en, this message translates to:
  /// **'Active Cases'**
  String get activeCases;

  /// No description provided for @addedToAppeal.
  ///
  /// In en, this message translates to:
  /// **'Added to Appeal'**
  String get addedToAppeal;

  /// No description provided for @agreeToTerms.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get agreeToTerms;

  /// No description provided for @aiAnalysis.
  ///
  /// In en, this message translates to:
  /// **'AI Analysis'**
  String get aiAnalysis;

  /// No description provided for @aiAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Legal Assistant'**
  String get aiAssistant;

  /// No description provided for @aiChat.
  ///
  /// In en, this message translates to:
  /// **'AI Chat'**
  String get aiChat;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// No description provided for @analyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing…'**
  String get analyzing;

  /// No description provided for @aiAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'AI is analyzing'**
  String get aiAnalyzing;

  /// No description provided for @speakIntoMicHint.
  ///
  /// In en, this message translates to:
  /// **'Speak into the microphone. Make sure microphone access is enabled.'**
  String get speakIntoMicHint;

  /// No description provided for @aiErrorRateLimit.
  ///
  /// In en, this message translates to:
  /// **'The service is temporarily overloaded. Please try again in 1-2 minutes.'**
  String get aiErrorRateLimit;

  /// No description provided for @aiErrorOverload.
  ///
  /// In en, this message translates to:
  /// **'The AI is busy right now, please try again in a minute.'**
  String get aiErrorOverload;

  /// No description provided for @freeLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You have used all {count} free AI messages. Upgrade to Legal Counsel for unlimited AI assistance!'**
  String freeLimitReached(int count);

  /// No description provided for @andWord.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get andWord;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Advocat — Legal Information Tool'**
  String get appTitle;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// No description provided for @appealFiled.
  ///
  /// In en, this message translates to:
  /// **'Appeal Filed'**
  String get appealFiled;

  /// No description provided for @areYouAbsolutelySure.
  ///
  /// In en, this message translates to:
  /// **'Are you absolutely sure?'**
  String get areYouAbsolutelySure;

  /// No description provided for @askAboutCase.
  ///
  /// In en, this message translates to:
  /// **'Analyze my case'**
  String get askAboutCase;

  /// No description provided for @asylum.
  ///
  /// In en, this message translates to:
  /// **'Asylum'**
  String get asylum;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @basic.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get basic;

  /// No description provided for @beforeYouBuy.
  ///
  /// In en, this message translates to:
  /// **'Before you buy'**
  String get beforeYouBuy;

  /// No description provided for @beforeYouWork.
  ///
  /// In en, this message translates to:
  /// **'Before you work with them'**
  String get beforeYouWork;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @caseDescription.
  ///
  /// In en, this message translates to:
  /// **'Describe your situation'**
  String get caseDescription;

  /// No description provided for @caseDetail.
  ///
  /// In en, this message translates to:
  /// **'Case Details'**
  String get caseDetail;

  /// No description provided for @caseOverview.
  ///
  /// In en, this message translates to:
  /// **'Here is your case overview'**
  String get caseOverview;

  /// No description provided for @caseTitle.
  ///
  /// In en, this message translates to:
  /// **'Case Title'**
  String get caseTitle;

  /// No description provided for @caseUpdated.
  ///
  /// In en, this message translates to:
  /// **'Case updated'**
  String get caseUpdated;

  /// No description provided for @cases.
  ///
  /// In en, this message translates to:
  /// **'Cases'**
  String get cases;

  /// No description provided for @checkCompany.
  ///
  /// In en, this message translates to:
  /// **'Check Company'**
  String get checkCompany;

  /// No description provided for @checkDeadlines.
  ///
  /// In en, this message translates to:
  /// **'Check deadlines'**
  String get checkDeadlines;

  /// No description provided for @checkVehicle.
  ///
  /// In en, this message translates to:
  /// **'Check Vehicle'**
  String get checkVehicle;

  /// No description provided for @checkerTitle.
  ///
  /// In en, this message translates to:
  /// **'Checker'**
  String get checkerTitle;

  /// No description provided for @checkingErrors.
  ///
  /// In en, this message translates to:
  /// **'Checking for errors…'**
  String get checkingErrors;

  /// No description provided for @choosePlan.
  ///
  /// In en, this message translates to:
  /// **'Choose Plan'**
  String get choosePlan;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @companyName.
  ///
  /// In en, this message translates to:
  /// **'Company name or reg. number'**
  String get companyName;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

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

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @copyText.
  ///
  /// In en, this message translates to:
  /// **'Copy Text'**
  String get copyText;

  /// No description provided for @correspondence.
  ///
  /// In en, this message translates to:
  /// **'Correspondence'**
  String get correspondence;

  /// No description provided for @couldNotLoadCases.
  ///
  /// In en, this message translates to:
  /// **'Could not load your cases'**
  String get couldNotLoadCases;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @createCase.
  ///
  /// In en, this message translates to:
  /// **'Create Case'**
  String get createCase;

  /// No description provided for @criminalCase.
  ///
  /// In en, this message translates to:
  /// **'Criminal Case'**
  String get criminalCase;

  /// No description provided for @critical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get critical;

  /// No description provided for @currentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current Plan'**
  String get currentPlan;

  /// No description provided for @dataAndPrivacy.
  ///
  /// In en, this message translates to:
  /// **'DATA & PRIVACY'**
  String get dataAndPrivacy;

  /// No description provided for @dataExportRequested.
  ///
  /// In en, this message translates to:
  /// **'Data export requested. Check your email.'**
  String get dataExportRequested;

  /// No description provided for @daysRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String daysRemaining(int count);

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

  /// No description provided for @deadlines.
  ///
  /// In en, this message translates to:
  /// **'Deadlines'**
  String get deadlines;

  /// No description provided for @debtCollection.
  ///
  /// In en, this message translates to:
  /// **'Debt Collection'**
  String get debtCollection;

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

  /// No description provided for @deleteAccountDialogContent.
  ///
  /// In en, this message translates to:
  /// **'This action is permanent and cannot be undone. All your data, cases, and documents will be permanently deleted.'**
  String get deleteAccountDialogContent;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure? This will permanently delete all your data.'**
  String get deleteConfirm;

  /// No description provided for @demoHint.
  ///
  /// In en, this message translates to:
  /// **'Demo: try plate \"908FBT\"'**
  String get demoHint;

  /// No description provided for @demoModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Explore the app with sample data from a real case'**
  String get demoModeDesc;

  /// No description provided for @deportation.
  ///
  /// In en, this message translates to:
  /// **'Deportation'**
  String get deportation;

  /// No description provided for @disclaimer.
  ///
  /// In en, this message translates to:
  /// **'AI guidance only — not legal advice. Always consult a lawyer.'**
  String get disclaimer;

  /// No description provided for @disclaimerFull.
  ///
  /// In en, this message translates to:
  /// **'This is an AI assistant, not a lawyer. AI analysis may contain errors. Always verify with a qualified legal professional.'**
  String get disclaimerFull;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @discrimination.
  ///
  /// In en, this message translates to:
  /// **'Discrimination'**
  String get discrimination;

  /// No description provided for @doNotBuy.
  ///
  /// In en, this message translates to:
  /// **'Do not buy'**
  String get doNotBuy;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @documentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} docs'**
  String documentsCount(int count);

  /// No description provided for @draftAppeal.
  ///
  /// In en, this message translates to:
  /// **'Draft Appeal'**
  String get draftAppeal;

  /// No description provided for @editDraft.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editDraft;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailConnected.
  ///
  /// In en, this message translates to:
  /// **'Email connected'**
  String get emailConnected;

  /// No description provided for @emailDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Email disconnected'**
  String get emailDisconnected;

  /// No description provided for @emailIntegration.
  ///
  /// In en, this message translates to:
  /// **'EMAIL INTEGRATION'**
  String get emailIntegration;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get emailInvalid;

  /// No description provided for @emailPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'We only read legal-related emails. Your personal emails stay private.'**
  String get emailPrivacyNote;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @emergencyShield.
  ///
  /// In en, this message translates to:
  /// **'Basic Protection'**
  String get emergencyShield;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @exportDataDesc.
  ///
  /// In en, this message translates to:
  /// **'Download all your case data'**
  String get exportDataDesc;

  /// No description provided for @exportDataDialogContent.
  ///
  /// In en, this message translates to:
  /// **'We will prepare a download of all your data including cases, documents, and correspondence. You will receive an email when it is ready.'**
  String get exportDataDialogContent;

  /// No description provided for @exportMyData.
  ///
  /// In en, this message translates to:
  /// **'Export My Data'**
  String get exportMyData;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// No description provided for @familyReunification.
  ///
  /// In en, this message translates to:
  /// **'Family Reunification'**
  String get familyReunification;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @fullDefense.
  ///
  /// In en, this message translates to:
  /// **'Advocat Pro'**
  String get fullDefense;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @generateAppeal.
  ///
  /// In en, this message translates to:
  /// **'Generate Appeal'**
  String get generateAppeal;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

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

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning, {name}'**
  String goodMorning(String name);

  /// No description provided for @goodNight.
  ///
  /// In en, this message translates to:
  /// **'Good night, {name}'**
  String goodNight(String name);

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @important.
  ///
  /// In en, this message translates to:
  /// **'Important'**
  String get important;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @informational.
  ///
  /// In en, this message translates to:
  /// **'Informational'**
  String get informational;

  /// No description provided for @inspection.
  ///
  /// In en, this message translates to:
  /// **'Technical inspection'**
  String get inspection;

  /// No description provided for @insurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get insurance;

  /// No description provided for @issuesFound.
  ///
  /// In en, this message translates to:
  /// **'{count} issues found'**
  String issuesFound(int count);

  /// No description provided for @laborDispute.
  ///
  /// In en, this message translates to:
  /// **'Labor Dispute'**
  String get laborDispute;

  /// No description provided for @langEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @langFinnish.
  ///
  /// In en, this message translates to:
  /// **'Finnish'**
  String get langFinnish;

  /// No description provided for @langRussian.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get langRussian;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @lastActivity.
  ///
  /// In en, this message translates to:
  /// **'Last activity: {time}'**
  String lastActivity(String time);

  /// No description provided for @legalFighter.
  ///
  /// In en, this message translates to:
  /// **'Legal Counsel'**
  String get legalFighter;

  /// No description provided for @legalSection.
  ///
  /// In en, this message translates to:
  /// **'LEGAL'**
  String get legalSection;

  /// No description provided for @licensePlate.
  ///
  /// In en, this message translates to:
  /// **'License plate'**
  String get licensePlate;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get logIn;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password. Please try again.'**
  String get loginFailed;

  /// No description provided for @lost.
  ///
  /// In en, this message translates to:
  /// **'Lost'**
  String get lost;

  /// No description provided for @markComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark complete'**
  String get markComplete;

  /// No description provided for @mileage.
  ///
  /// In en, this message translates to:
  /// **'Mileage'**
  String get mileage;

  /// No description provided for @myCases.
  ///
  /// In en, this message translates to:
  /// **'My Cases'**
  String get myCases;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get nameRequired;

  /// No description provided for @newCase.
  ///
  /// In en, this message translates to:
  /// **'New Case'**
  String get newCase;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don’t have an account? '**
  String get noAccount;

  /// No description provided for @noCases.
  ///
  /// In en, this message translates to:
  /// **'No cases yet'**
  String get noCases;

  /// No description provided for @noCasesYet.
  ///
  /// In en, this message translates to:
  /// **'No cases yet'**
  String get noCasesYet;

  /// No description provided for @noDeadlines.
  ///
  /// In en, this message translates to:
  /// **'No deadlines — you’re all clear.'**
  String get noDeadlines;

  /// No description provided for @noRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'No recent activity'**
  String get noRecentActivity;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATIONS'**
  String get notifications;

  /// No description provided for @onboardingDesc1.
  ///
  /// In en, this message translates to:
  /// **'Advocat helps you understand your legal situation. AI tools analyze documents, identify potential issues, and prepare draft documents for your review. Not a law firm — a technology tool to support your case.'**
  String get onboardingDesc1;

  /// No description provided for @onboardingDesc2.
  ///
  /// In en, this message translates to:
  /// **'Photograph any legal document. AI reads it in multiple languages, extracts key details, and checks against EU directives and national laws for potential issues.'**
  String get onboardingDesc2;

  /// No description provided for @onboardingDesc3.
  ///
  /// In en, this message translates to:
  /// **'Our AI tools check 40+ types of procedural requirements. AI analysis may identify issues that require attention — such as language of service, procedural steps, and legal deadlines. Always verify with a qualified lawyer.'**
  String get onboardingDesc3;

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

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'AI-Powered Legal Information'**
  String get onboardingTitle1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Scan and Analyze Documents'**
  String get onboardingTitle2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'AI Checks for Potential Issues'**
  String get onboardingTitle3;

  /// No description provided for @onboardingTitle4.
  ///
  /// In en, this message translates to:
  /// **'Draft Documents for Your Review'**
  String get onboardingTitle4;

  /// No description provided for @openACase.
  ///
  /// In en, this message translates to:
  /// **'Open a Case'**
  String get openACase;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'(optional)'**
  String get optional;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orDivider;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @owners.
  ///
  /// In en, this message translates to:
  /// **'Previous owners'**
  String get owners;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

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

  /// No description provided for @passwordStrengthWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get passwordStrengthWeak;

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

  /// No description provided for @pendingDecision.
  ///
  /// In en, this message translates to:
  /// **'Pending Decision'**
  String get pendingDecision;

  /// No description provided for @perCheck.
  ///
  /// In en, this message translates to:
  /// **'per check'**
  String get perCheck;

  /// No description provided for @permanentlyDelete.
  ///
  /// In en, this message translates to:
  /// **'Permanently Delete'**
  String get permanentlyDelete;

  /// No description provided for @policeMisconduct.
  ///
  /// In en, this message translates to:
  /// **'Police Misconduct'**
  String get policeMisconduct;

  /// No description provided for @popular.
  ///
  /// In en, this message translates to:
  /// **'POPULAR'**
  String get popular;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'PREFERENCES'**
  String get preferences;

  /// No description provided for @preferredLanguage.
  ///
  /// In en, this message translates to:
  /// **'Preferred Language'**
  String get preferredLanguage;

  /// No description provided for @pricePerCheck.
  ///
  /// In en, this message translates to:
  /// **'€4.99 per check'**
  String get pricePerCheck;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @pro.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get pro;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @rateUs.
  ///
  /// In en, this message translates to:
  /// **'Rate Us'**
  String get rateUs;

  /// No description provided for @rateAppComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming to app stores soon!'**
  String get rateAppComingSoon;

  /// No description provided for @dataCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Data copied to clipboard'**
  String get dataCopiedToClipboard;

  /// No description provided for @readingDocument.
  ///
  /// In en, this message translates to:
  /// **'Reading document…'**
  String get readingDocument;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @referenceNumber.
  ///
  /// In en, this message translates to:
  /// **'Reference Number'**
  String get referenceNumber;

  /// No description provided for @registerFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed. Please try again.'**
  String get registerFailed;

  /// No description provided for @reportFraud.
  ///
  /// In en, this message translates to:
  /// **'Report Fraud'**
  String get reportFraud;

  /// No description provided for @requestExport.
  ///
  /// In en, this message translates to:
  /// **'Request Export'**
  String get requestExport;

  /// No description provided for @researchingLaw.
  ///
  /// In en, this message translates to:
  /// **'Researching applicable law…'**
  String get researchingLaw;

  /// No description provided for @resetPasswordFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send reset link. Please try again.'**
  String get resetPasswordFailed;

  /// No description provided for @resetPasswordSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset link sent to your email.'**
  String get resetPasswordSent;

  /// No description provided for @residencePermit.
  ///
  /// In en, this message translates to:
  /// **'Residence Permit'**
  String get residencePermit;

  /// No description provided for @manageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage subscription'**
  String get manageSubscription;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
  String get restorePurchases;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @reviewWarning.
  ///
  /// In en, this message translates to:
  /// **'Review carefully before sending. You are responsible for the content.'**
  String get reviewWarning;

  /// No description provided for @riskHigh.
  ///
  /// In en, this message translates to:
  /// **'High risk — avoid'**
  String get riskHigh;

  /// No description provided for @riskLow.
  ///
  /// In en, this message translates to:
  /// **'Safe to work with'**
  String get riskLow;

  /// No description provided for @riskMedium.
  ///
  /// In en, this message translates to:
  /// **'Proceed with caution'**
  String get riskMedium;

  /// No description provided for @safeToBuy.
  ///
  /// In en, this message translates to:
  /// **'Safe to buy'**
  String get safeToBuy;

  /// No description provided for @saveAndAnalyze.
  ///
  /// In en, this message translates to:
  /// **'Save & Analyze'**
  String get saveAndAnalyze;

  /// No description provided for @saveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveDraft;

  /// No description provided for @saveWithAnnual.
  ///
  /// In en, this message translates to:
  /// **'Save 25% with annual billing'**
  String get saveWithAnnual;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// No description provided for @scanDocument.
  ///
  /// In en, this message translates to:
  /// **'Scan Document'**
  String get scanDocument;

  /// No description provided for @searchCases.
  ///
  /// In en, this message translates to:
  /// **'Search cases…'**
  String get searchCases;

  /// No description provided for @selectCountry.
  ///
  /// In en, this message translates to:
  /// **'Select country'**
  String get selectCountry;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @sendViaEmail.
  ///
  /// In en, this message translates to:
  /// **'Send via Email'**
  String get sendViaEmail;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signInLink.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get signInLink;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to access your cases'**
  String get signInSubtitle;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @signOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signOutConfirm;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get signUp;

  /// No description provided for @signUpLink.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUpLink;

  /// No description provided for @socialBenefits.
  ///
  /// In en, this message translates to:
  /// **'Social Benefits'**
  String get socialBenefits;

  /// No description provided for @someConcerns.
  ///
  /// In en, this message translates to:
  /// **'Some concerns'**
  String get someConcerns;

  /// No description provided for @startFirstCase.
  ///
  /// In en, this message translates to:
  /// **'Start your first case'**
  String get startFirstCase;

  /// No description provided for @step.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String step(int current, int total);

  /// No description provided for @stolen.
  ///
  /// In en, this message translates to:
  /// **'Stolen check'**
  String get stolen;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @syncLegalCorrespondence.
  ///
  /// In en, this message translates to:
  /// **'Sync legal correspondence'**
  String get syncLegalCorrespondence;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNow;

  /// No description provided for @tenantRights.
  ///
  /// In en, this message translates to:
  /// **'Tenant Rights'**
  String get tenantRights;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @termsRequired.
  ///
  /// In en, this message translates to:
  /// **'You must agree to the Terms of Service'**
  String get termsRequired;

  /// No description provided for @timeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timeline;

  /// No description provided for @tryDemoMode.
  ///
  /// In en, this message translates to:
  /// **'Try Demo Mode'**
  String get tryDemoMode;

  /// No description provided for @typeDeleteToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE to confirm permanent account removal.'**
  String get typeDeleteToConfirm;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message…'**
  String get typeMessage;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @uploadDocument.
  ///
  /// In en, this message translates to:
  /// **'Upload Document'**
  String get uploadDocument;

  /// No description provided for @urgentDeadline.
  ///
  /// In en, this message translates to:
  /// **'Urgent: {title}'**
  String urgentDeadline(String title);

  /// No description provided for @useInAppeal.
  ///
  /// In en, this message translates to:
  /// **'Use in Appeal'**
  String get useInAppeal;

  /// No description provided for @vehicleChecker.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Checker'**
  String get vehicleChecker;

  /// No description provided for @vehicleChecks.
  ///
  /// In en, this message translates to:
  /// **'Status Checks'**
  String get vehicleChecks;

  /// No description provided for @vehicleColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get vehicleColor;

  /// No description provided for @vehicleMake.
  ///
  /// In en, this message translates to:
  /// **'Make'**
  String get vehicleMake;

  /// No description provided for @vehicleModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get vehicleModel;

  /// No description provided for @vehicleYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get vehicleYear;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @victimSupport.
  ///
  /// In en, this message translates to:
  /// **'Victim Support'**
  String get victimSupport;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @vinNumber.
  ///
  /// In en, this message translates to:
  /// **'VIN number'**
  String get vinNumber;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @whatAreMyOptions.
  ///
  /// In en, this message translates to:
  /// **'What are my options?'**
  String get whatAreMyOptions;

  /// No description provided for @won.
  ///
  /// In en, this message translates to:
  /// **'Won'**
  String get won;

  /// No description provided for @documentVault.
  ///
  /// In en, this message translates to:
  /// **'Document Vault'**
  String get documentVault;

  /// No description provided for @secureDocumentStorage.
  ///
  /// In en, this message translates to:
  /// **'Secure Document Storage'**
  String get secureDocumentStorage;

  /// No description provided for @secureDocumentStorageDesc.
  ///
  /// In en, this message translates to:
  /// **'Store your important legal documents in one place for easy access.'**
  String get secureDocumentStorageDesc;

  /// No description provided for @addDocument.
  ///
  /// In en, this message translates to:
  /// **'Add Document'**
  String get addDocument;

  /// No description provided for @chooseHowToAdd.
  ///
  /// In en, this message translates to:
  /// **'Choose how to add your document'**
  String get chooseHowToAdd;

  /// No description provided for @uploadFile.
  ///
  /// In en, this message translates to:
  /// **'Upload File'**
  String get uploadFile;

  /// No description provided for @uploadFileDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose a PDF or image from your device'**
  String get uploadFileDesc;

  /// No description provided for @scanDocumentDesc.
  ///
  /// In en, this message translates to:
  /// **'Take a photo of your document'**
  String get scanDocumentDesc;

  /// No description provided for @createNote.
  ///
  /// In en, this message translates to:
  /// **'Create Note'**
  String get createNote;

  /// No description provided for @createNoteDesc.
  ///
  /// In en, this message translates to:
  /// **'Write a note or record important details'**
  String get createNoteDesc;

  /// No description provided for @knowYourRights.
  ///
  /// In en, this message translates to:
  /// **'Know Your Rights'**
  String get knowYourRights;

  /// No description provided for @stoppedByPolice.
  ///
  /// In en, this message translates to:
  /// **'Stopped by Police'**
  String get stoppedByPolice;

  /// No description provided for @stoppedByPoliceDesc.
  ///
  /// In en, this message translates to:
  /// **'Your rights during a police encounter'**
  String get stoppedByPoliceDesc;

  /// No description provided for @deportationNotice.
  ///
  /// In en, this message translates to:
  /// **'Deportation Notice'**
  String get deportationNotice;

  /// No description provided for @deportationNoticeDesc.
  ///
  /// In en, this message translates to:
  /// **'Steps to challenge a removal order'**
  String get deportationNoticeDesc;

  /// No description provided for @workplaceRights.
  ///
  /// In en, this message translates to:
  /// **'Workplace Rights'**
  String get workplaceRights;

  /// No description provided for @workplaceRightsDesc.
  ///
  /// In en, this message translates to:
  /// **'Employment law protections in Finland'**
  String get workplaceRightsDesc;

  /// No description provided for @tenantRightsDesc.
  ///
  /// In en, this message translates to:
  /// **'Housing and rental protections'**
  String get tenantRightsDesc;

  /// No description provided for @immigrationDetention.
  ///
  /// In en, this message translates to:
  /// **'Immigration Detention'**
  String get immigrationDetention;

  /// No description provided for @immigrationDetentionDesc.
  ///
  /// In en, this message translates to:
  /// **'Rights if detained by authorities'**
  String get immigrationDetentionDesc;

  /// No description provided for @discriminationDesc.
  ///
  /// In en, this message translates to:
  /// **'How to report and fight discrimination'**
  String get discriminationDesc;

  /// No description provided for @scenarioNotFound.
  ///
  /// In en, this message translates to:
  /// **'Scenario not found'**
  String get scenarioNotFound;

  /// No description provided for @youHaveRightTo.
  ///
  /// In en, this message translates to:
  /// **'You have the right to:'**
  String get youHaveRightTo;

  /// No description provided for @youMust.
  ///
  /// In en, this message translates to:
  /// **'You must:'**
  String get youMust;

  /// No description provided for @immediateSteps.
  ///
  /// In en, this message translates to:
  /// **'Immediate steps:'**
  String get immediateSteps;

  /// No description provided for @yourRights.
  ///
  /// In en, this message translates to:
  /// **'Your rights:'**
  String get yourRights;

  /// No description provided for @basicRights.
  ///
  /// In en, this message translates to:
  /// **'Basic rights:'**
  String get basicRights;

  /// No description provided for @yourRightsAsTenant.
  ///
  /// In en, this message translates to:
  /// **'Your rights as a tenant:'**
  String get yourRightsAsTenant;

  /// No description provided for @yourRightsInDetention.
  ///
  /// In en, this message translates to:
  /// **'Your rights in detention:'**
  String get yourRightsInDetention;

  /// No description provided for @howToAct.
  ///
  /// In en, this message translates to:
  /// **'How to act:'**
  String get howToAct;

  /// No description provided for @rightKnowWhyStopped.
  ///
  /// In en, this message translates to:
  /// **'Know why you are being stopped'**
  String get rightKnowWhyStopped;

  /// No description provided for @rightRemainSilent.
  ///
  /// In en, this message translates to:
  /// **'Remain silent (you must identify yourself)'**
  String get rightRemainSilent;

  /// No description provided for @rightAskInterpreter.
  ///
  /// In en, this message translates to:
  /// **'Ask for an interpreter'**
  String get rightAskInterpreter;

  /// No description provided for @rightContactLawyer.
  ///
  /// In en, this message translates to:
  /// **'Contact a lawyer before questioning'**
  String get rightContactLawyer;

  /// No description provided for @rightRecordEncounter.
  ///
  /// In en, this message translates to:
  /// **'Record the encounter (in public places)'**
  String get rightRecordEncounter;

  /// No description provided for @mustProvideName.
  ///
  /// In en, this message translates to:
  /// **'Provide your name and date of birth'**
  String get mustProvideName;

  /// No description provided for @mustShowId.
  ///
  /// In en, this message translates to:
  /// **'Show ID if you have one'**
  String get mustShowId;

  /// No description provided for @mustNotResist.
  ///
  /// In en, this message translates to:
  /// **'Not physically resist'**
  String get mustNotResist;

  /// No description provided for @doNotIgnoreNotice.
  ///
  /// In en, this message translates to:
  /// **'Do NOT ignore the notice — deadlines are strict'**
  String get doNotIgnoreNotice;

  /// No description provided for @noteAppealDeadline.
  ///
  /// In en, this message translates to:
  /// **'Note the appeal deadline (usually 30 days)'**
  String get noteAppealDeadline;

  /// No description provided for @contactLawyerImmediately.
  ///
  /// In en, this message translates to:
  /// **'Contact a lawyer immediately'**
  String get contactLawyerImmediately;

  /// No description provided for @applyLegalAid.
  ///
  /// In en, this message translates to:
  /// **'Apply for legal aid if needed'**
  String get applyLegalAid;

  /// No description provided for @rightAppealAdmin.
  ///
  /// In en, this message translates to:
  /// **'Right to appeal to the Administrative Court'**
  String get rightAppealAdmin;

  /// No description provided for @rightLegalRep.
  ///
  /// In en, this message translates to:
  /// **'Right to legal representation'**
  String get rightLegalRep;

  /// No description provided for @rightInterpreter.
  ///
  /// In en, this message translates to:
  /// **'Right to an interpreter'**
  String get rightInterpreter;

  /// No description provided for @rightStayDuringAppeal.
  ///
  /// In en, this message translates to:
  /// **'Right to stay during appeal (in most cases)'**
  String get rightStayDuringAppeal;

  /// No description provided for @minimumWage.
  ///
  /// In en, this message translates to:
  /// **'Minimum wage as per collective agreement'**
  String get minimumWage;

  /// No description provided for @workingTimeLimits.
  ///
  /// In en, this message translates to:
  /// **'Working time limits (max 8h/day, 40h/week)'**
  String get workingTimeLimits;

  /// No description provided for @annualLeave.
  ///
  /// In en, this message translates to:
  /// **'Annual leave (minimum 2 days per month worked)'**
  String get annualLeave;

  /// No description provided for @sickLeave.
  ///
  /// In en, this message translates to:
  /// **'Sick leave compensation'**
  String get sickLeave;

  /// No description provided for @safeWorkingConditions.
  ///
  /// In en, this message translates to:
  /// **'Safe working conditions'**
  String get safeWorkingConditions;

  /// No description provided for @writtenRentalAgreement.
  ///
  /// In en, this message translates to:
  /// **'Written rental agreement required'**
  String get writtenRentalAgreement;

  /// No description provided for @securityDeposit.
  ///
  /// In en, this message translates to:
  /// **'Security deposit max 3 months rent'**
  String get securityDeposit;

  /// No description provided for @landlordNotice.
  ///
  /// In en, this message translates to:
  /// **'Landlord must give notice (3–6 months)'**
  String get landlordNotice;

  /// No description provided for @rightHabitableDwelling.
  ///
  /// In en, this message translates to:
  /// **'Right to a habitable dwelling'**
  String get rightHabitableDwelling;

  /// No description provided for @protectionUnjustEviction.
  ///
  /// In en, this message translates to:
  /// **'Protection from unjust eviction'**
  String get protectionUnjustEviction;

  /// No description provided for @rightKnowDetentionReason.
  ///
  /// In en, this message translates to:
  /// **'Right to know the reason for detention'**
  String get rightKnowDetentionReason;

  /// No description provided for @rightContactLawyerDetention.
  ///
  /// In en, this message translates to:
  /// **'Right to contact a lawyer'**
  String get rightContactLawyerDetention;

  /// No description provided for @rightContactEmbassy.
  ///
  /// In en, this message translates to:
  /// **'Right to contact your embassy'**
  String get rightContactEmbassy;

  /// No description provided for @rightChallengeDetention.
  ///
  /// In en, this message translates to:
  /// **'Right to challenge detention in court'**
  String get rightChallengeDetention;

  /// No description provided for @rightHumaneTreatment.
  ///
  /// In en, this message translates to:
  /// **'Right to humane treatment and medical care'**
  String get rightHumaneTreatment;

  /// No description provided for @documentIncident.
  ///
  /// In en, this message translates to:
  /// **'Document the incident (date, time, witnesses)'**
  String get documentIncident;

  /// No description provided for @fileComplaintOmbudsman.
  ///
  /// In en, this message translates to:
  /// **'File a complaint with the Non-Discrimination Ombudsman'**
  String get fileComplaintOmbudsman;

  /// No description provided for @contactLegalAidOffice.
  ///
  /// In en, this message translates to:
  /// **'Contact a legal aid office'**
  String get contactLegalAidOffice;

  /// No description provided for @reportToPolice.
  ///
  /// In en, this message translates to:
  /// **'Report to police if criminal (threat, assault)'**
  String get reportToPolice;

  /// No description provided for @legalAidCalculator.
  ///
  /// In en, this message translates to:
  /// **'Legal Aid Calculator'**
  String get legalAidCalculator;

  /// No description provided for @checkEligibility.
  ///
  /// In en, this message translates to:
  /// **'Check your eligibility for {country} legal aid'**
  String checkEligibility(String country);

  /// No description provided for @estimateDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This is an estimate only. Actual eligibility is determined by the Legal Aid Office.'**
  String get estimateDisclaimer;

  /// No description provided for @monthlyIncome.
  ///
  /// In en, this message translates to:
  /// **'Monthly income (EUR)'**
  String get monthlyIncome;

  /// No description provided for @totalAssets.
  ///
  /// In en, this message translates to:
  /// **'Total assets (EUR)'**
  String get totalAssets;

  /// No description provided for @numberOfDependents.
  ///
  /// In en, this message translates to:
  /// **'Number of dependents'**
  String get numberOfDependents;

  /// No description provided for @calculateEligibility.
  ///
  /// In en, this message translates to:
  /// **'Calculate Eligibility'**
  String get calculateEligibility;

  /// No description provided for @likelyEligible.
  ///
  /// In en, this message translates to:
  /// **'Likely Eligible'**
  String get likelyEligible;

  /// No description provided for @mayNotQualify.
  ///
  /// In en, this message translates to:
  /// **'May Not Qualify'**
  String get mayNotQualify;

  /// No description provided for @fullFreeLegalAid.
  ///
  /// In en, this message translates to:
  /// **'You likely qualify for full free legal aid (no co-payment).'**
  String get fullFreeLegalAid;

  /// No description provided for @legalAidWithCopay.
  ///
  /// In en, this message translates to:
  /// **'You may qualify for legal aid with a co-payment of {percent}%.'**
  String legalAidWithCopay(String percent);

  /// No description provided for @mayNotQualifyDesc.
  ///
  /// In en, this message translates to:
  /// **'Based on this estimate, you may not qualify for state legal aid. Consider consulting a private lawyer or legal clinic.'**
  String get mayNotQualifyDesc;

  /// No description provided for @couldNotLoadDeadlines.
  ///
  /// In en, this message translates to:
  /// **'Could not load deadlines'**
  String get couldNotLoadDeadlines;

  /// No description provided for @noUpcomingDeadlines.
  ///
  /// In en, this message translates to:
  /// **'No upcoming deadlines'**
  String get noUpcomingDeadlines;

  /// No description provided for @allClearDeadlines.
  ///
  /// In en, this message translates to:
  /// **'You are all caught up. New deadlines will appear here when they are set.'**
  String get allClearDeadlines;

  /// No description provided for @nothingOverdue.
  ///
  /// In en, this message translates to:
  /// **'Nothing overdue'**
  String get nothingOverdue;

  /// No description provided for @greatJobDeadlines.
  ///
  /// In en, this message translates to:
  /// **'You are on top of your deadlines.'**
  String get greatJobDeadlines;

  /// No description provided for @noCompletedDeadlines.
  ///
  /// In en, this message translates to:
  /// **'No completed deadlines'**
  String get noCompletedDeadlines;

  /// No description provided for @completedDeadlinesDesc.
  ///
  /// In en, this message translates to:
  /// **'Deadlines you complete will be shown here.'**
  String get completedDeadlinesDesc;

  /// No description provided for @daysLate.
  ///
  /// In en, this message translates to:
  /// **'days late'**
  String get daysLate;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @fromDocument.
  ///
  /// In en, this message translates to:
  /// **'From document'**
  String get fromDocument;

  /// No description provided for @couldNotLoadCase.
  ///
  /// In en, this message translates to:
  /// **'Could not load case details'**
  String get couldNotLoadCase;

  /// No description provided for @typeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get typeLabel;

  /// No description provided for @nationality.
  ///
  /// In en, this message translates to:
  /// **'Nationality'**
  String get nationality;

  /// No description provided for @migriReference.
  ///
  /// In en, this message translates to:
  /// **'Migri Reference'**
  String get migriReference;

  /// No description provided for @courtCaseNo.
  ///
  /// In en, this message translates to:
  /// **'Court Case No.'**
  String get courtCaseNo;

  /// No description provided for @created.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get created;

  /// No description provided for @citizenship.
  ///
  /// In en, this message translates to:
  /// **'Citizenship'**
  String get citizenship;

  /// No description provided for @workPermit.
  ///
  /// In en, this message translates to:
  /// **'Work Permit'**
  String get workPermit;

  /// No description provided for @noDocumentsYet.
  ///
  /// In en, this message translates to:
  /// **'No documents uploaded yet'**
  String get noDocumentsYet;

  /// No description provided for @noUpcomingDeadlinesShort.
  ///
  /// In en, this message translates to:
  /// **'No upcoming deadlines'**
  String get noUpcomingDeadlinesShort;

  /// No description provided for @caseCreated.
  ///
  /// In en, this message translates to:
  /// **'Case created'**
  String get caseCreated;

  /// No description provided for @decisionReceived.
  ///
  /// In en, this message translates to:
  /// **'Decision received'**
  String get decisionReceived;

  /// No description provided for @appealDeadline.
  ///
  /// In en, this message translates to:
  /// **'Appeal deadline'**
  String get appealDeadline;

  /// No description provided for @hearingScheduled.
  ///
  /// In en, this message translates to:
  /// **'Hearing scheduled'**
  String get hearingScheduled;

  /// No description provided for @late.
  ///
  /// In en, this message translates to:
  /// **'late'**
  String get late;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get processing;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @analyzed.
  ///
  /// In en, this message translates to:
  /// **'Analyzed'**
  String get analyzed;

  /// No description provided for @noDocumentsScanHint.
  ///
  /// In en, this message translates to:
  /// **'No documents yet. Scan or upload one.'**
  String get noDocumentsScanHint;

  /// No description provided for @inCourt.
  ///
  /// In en, this message translates to:
  /// **'In Court'**
  String get inCourt;

  /// No description provided for @appeal.
  ///
  /// In en, this message translates to:
  /// **'Appeal'**
  String get appeal;

  /// No description provided for @caseTimeline.
  ///
  /// In en, this message translates to:
  /// **'Case Timeline'**
  String get caseTimeline;

  /// No description provided for @couldNotLoadTimeline.
  ///
  /// In en, this message translates to:
  /// **'Could not load timeline'**
  String get couldNotLoadTimeline;

  /// No description provided for @noEventsYet.
  ///
  /// In en, this message translates to:
  /// **'No events yet'**
  String get noEventsYet;

  /// No description provided for @activityWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Activity will appear here as your case progresses.'**
  String get activityWillAppear;

  /// No description provided for @caseCreatedDesc.
  ///
  /// In en, this message translates to:
  /// **'Case \"{title}\" was created.'**
  String caseCreatedDesc(String title);

  /// No description provided for @decisionReceivedDesc.
  ///
  /// In en, this message translates to:
  /// **'An official decision was received for this case.'**
  String get decisionReceivedDesc;

  /// No description provided for @appealDeadlineSet.
  ///
  /// In en, this message translates to:
  /// **'Appeal deadline set'**
  String get appealDeadlineSet;

  /// No description provided for @appealDeadlineDesc.
  ///
  /// In en, this message translates to:
  /// **'Appeal must be filed by {date}.'**
  String appealDeadlineDesc(String date);

  /// No description provided for @hearingScheduledDesc.
  ///
  /// In en, this message translates to:
  /// **'Court hearing scheduled for {date}.'**
  String hearingScheduledDesc(String date);

  /// No description provided for @caseInfoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Case information was last updated.'**
  String get caseInfoUpdated;

  /// No description provided for @documentAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Document Analysis'**
  String get documentAnalysis;

  /// No description provided for @exportAsPdf.
  ///
  /// In en, this message translates to:
  /// **'Export as PDF'**
  String get exportAsPdf;

  /// No description provided for @pdfExportComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Export as PDF'**
  String get pdfExportComingSoon;

  /// No description provided for @analysisFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Analysis failed. Please try again.'**
  String get analysisFailedRetry;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @retryAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Retry Analysis'**
  String get retryAnalysis;

  /// No description provided for @issuesFoundInDocument.
  ///
  /// In en, this message translates to:
  /// **'Found {count} issue(s) in your document'**
  String issuesFoundInDocument(int count);

  /// No description provided for @severityOverview.
  ///
  /// In en, this message translates to:
  /// **'Severity Overview'**
  String get severityOverview;

  /// No description provided for @issuesFoundHeader.
  ///
  /// In en, this message translates to:
  /// **'Issues Found'**
  String get issuesFoundHeader;

  /// No description provided for @generateAppealWithIssues.
  ///
  /// In en, this message translates to:
  /// **'Generate Appeal ({count} issues)'**
  String generateAppealWithIssues(int count);

  /// No description provided for @analyzingContent.
  ///
  /// In en, this message translates to:
  /// **'Analyzing content…'**
  String get analyzingContent;

  /// No description provided for @documentProcessedOk.
  ///
  /// In en, this message translates to:
  /// **'Document processed successfully'**
  String get documentProcessedOk;

  /// No description provided for @noSignificantIssues.
  ///
  /// In en, this message translates to:
  /// **'No significant issues were detected in this document.'**
  String get noSignificantIssues;

  /// No description provided for @cameraPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Camera permission required'**
  String get cameraPermissionRequired;

  /// No description provided for @cameraPermissionDesc.
  ///
  /// In en, this message translates to:
  /// **'Grant camera access to scan documents, or use the gallery.'**
  String get cameraPermissionDesc;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @alignDocument.
  ///
  /// In en, this message translates to:
  /// **'Align document within the frame'**
  String get alignDocument;

  /// No description provided for @pageCount.
  ///
  /// In en, this message translates to:
  /// **'{count} page(s)'**
  String pageCount(int count);

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @pageNumber.
  ///
  /// In en, this message translates to:
  /// **'Page {number}'**
  String pageNumber(int number);

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @retake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get retake;

  /// No description provided for @useThisPhoto.
  ///
  /// In en, this message translates to:
  /// **'Use This Photo'**
  String get useThisPhoto;

  /// No description provided for @addPage.
  ///
  /// In en, this message translates to:
  /// **'Add Page'**
  String get addPage;

  /// No description provided for @uploadingPercent.
  ///
  /// In en, this message translates to:
  /// **'Uploading… {percent}%'**
  String uploadingPercent(int percent);

  /// No description provided for @preparingUpload.
  ///
  /// In en, this message translates to:
  /// **'Preparing upload…'**
  String get preparingUpload;

  /// No description provided for @documentUploadedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Document uploaded successfully'**
  String get documentUploadedSuccess;

  /// No description provided for @pagesUploadedSuccess.
  ///
  /// In en, this message translates to:
  /// **'{count} pages uploaded successfully'**
  String pagesUploadedSuccess(int count);

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed. Please check your connection and try again.'**
  String get uploadFailed;

  /// No description provided for @capturePhotoFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to capture photo. Please try again.'**
  String get capturePhotoFailed;

  /// No description provided for @readingText.
  ///
  /// In en, this message translates to:
  /// **'Reading text…'**
  String get readingText;

  /// No description provided for @draftDocument.
  ///
  /// In en, this message translates to:
  /// **'Draft Document'**
  String get draftDocument;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @editDocument.
  ///
  /// In en, this message translates to:
  /// **'Edit document'**
  String get editDocument;

  /// No description provided for @generatingDraft.
  ///
  /// In en, this message translates to:
  /// **'Generating your draft…'**
  String get generatingDraft;

  /// No description provided for @generatingDraftDesc.
  ///
  /// In en, this message translates to:
  /// **'AI is preparing a legal document based on your case details and selected issues.'**
  String get generatingDraftDesc;

  /// No description provided for @failedToGenerateDraft.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate draft. Please try again.'**
  String get failedToGenerateDraft;

  /// No description provided for @changesSaved.
  ///
  /// In en, this message translates to:
  /// **'Changes saved'**
  String get changesSaved;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @emailComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Send email via your connected Gmail account'**
  String get emailComingSoon;

  /// No description provided for @reviewBeforeSending.
  ///
  /// In en, this message translates to:
  /// **'Review carefully before sending. You are responsible for the content of this document.'**
  String get reviewBeforeSending;

  /// No description provided for @noContentAvailable.
  ///
  /// In en, this message translates to:
  /// **'No content available'**
  String get noContentAvailable;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @pdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get pdf;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @appealDraft.
  ///
  /// In en, this message translates to:
  /// **'Appeal Draft'**
  String get appealDraft;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selected(int count);

  /// No description provided for @deleteSelected.
  ///
  /// In en, this message translates to:
  /// **'Delete selected'**
  String get deleteSelected;

  /// No description provided for @deleteDocumentsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} documents?'**
  String deleteDocumentsConfirm(int count);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @analyzeSelected.
  ///
  /// In en, this message translates to:
  /// **'Analyze selected'**
  String get analyzeSelected;

  /// No description provided for @batchAnalysisStarting.
  ///
  /// In en, this message translates to:
  /// **'Batch analysis starting…'**
  String get batchAnalysisStarting;

  /// No description provided for @switchToList.
  ///
  /// In en, this message translates to:
  /// **'Switch to list'**
  String get switchToList;

  /// No description provided for @switchToGrid.
  ///
  /// In en, this message translates to:
  /// **'Switch to grid'**
  String get switchToGrid;

  /// No description provided for @scanNew.
  ///
  /// In en, this message translates to:
  /// **'Scan New'**
  String get scanNew;

  /// No description provided for @noDocumentsYetScan.
  ///
  /// In en, this message translates to:
  /// **'No documents yet'**
  String get noDocumentsYetScan;

  /// No description provided for @scanFirstDocumentHint.
  ///
  /// In en, this message translates to:
  /// **'Scan your first document to let AI analyze it for errors and generate appeals.'**
  String get scanFirstDocumentHint;

  /// No description provided for @failedToLoadDocuments.
  ///
  /// In en, this message translates to:
  /// **'Failed to load documents'**
  String get failedToLoadDocuments;

  /// No description provided for @emailIntegrationTitle.
  ///
  /// In en, this message translates to:
  /// **'Email Integration'**
  String get emailIntegrationTitle;

  /// No description provided for @connectYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Connect Your Email'**
  String get connectYourEmail;

  /// No description provided for @connectYourEmailDesc.
  ///
  /// In en, this message translates to:
  /// **'Connect your email to automatically detect and organize legal correspondence related to your cases.'**
  String get connectYourEmailDesc;

  /// No description provided for @legalEmails.
  ///
  /// In en, this message translates to:
  /// **'Legal Emails'**
  String get legalEmails;

  /// No description provided for @unlinkedEmails.
  ///
  /// In en, this message translates to:
  /// **'Unlinked Emails'**
  String get unlinkedEmails;

  /// No description provided for @noLegalEmailsYet.
  ///
  /// In en, this message translates to:
  /// **'No legal emails yet'**
  String get noLegalEmailsYet;

  /// No description provided for @legalEmailsWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Emails classified as legal-related will appear here.'**
  String get legalEmailsWillAppear;

  /// No description provided for @assignToCase.
  ///
  /// In en, this message translates to:
  /// **'Assign to case'**
  String get assignToCase;

  /// No description provided for @disconnectEmail.
  ///
  /// In en, this message translates to:
  /// **'Disconnect Email'**
  String get disconnectEmail;

  /// No description provided for @disconnectEmailConfirm.
  ///
  /// In en, this message translates to:
  /// **'You will stop receiving automatic email syncing. Previously synced emails will remain in your cases.'**
  String get disconnectEmailConfirm;

  /// No description provided for @gmailReauthBannerBody.
  ///
  /// In en, this message translates to:
  /// **'Advocat v2.1 reads your inbox to draft replies; you can revoke any time. Reconnect Gmail to enable proactive triage.'**
  String get gmailReauthBannerBody;

  /// No description provided for @gmailReauthBannerCta.
  ///
  /// In en, this message translates to:
  /// **'Reauthorize'**
  String get gmailReauthBannerCta;

  /// No description provided for @connectedTo.
  ///
  /// In en, this message translates to:
  /// **'Connected to {email}'**
  String connectedTo(String email);

  /// No description provided for @lastSynced.
  ///
  /// In en, this message translates to:
  /// **'Last synced {time}'**
  String lastSynced(String time);

  /// No description provided for @filterByType.
  ///
  /// In en, this message translates to:
  /// **'Filter by Type'**
  String get filterByType;

  /// No description provided for @noCasesMatchSearch.
  ///
  /// In en, this message translates to:
  /// **'No cases match your search'**
  String get noCasesMatchSearch;

  /// No description provided for @failedToLoadCases.
  ///
  /// In en, this message translates to:
  /// **'Failed to load cases'**
  String get failedToLoadCases;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @annual.
  ///
  /// In en, this message translates to:
  /// **'Annual'**
  String get annual;

  /// No description provided for @saveTwentyFivePercent.
  ///
  /// In en, this message translates to:
  /// **'Save 25%'**
  String get saveTwentyFivePercent;

  /// No description provided for @mostPopular.
  ///
  /// In en, this message translates to:
  /// **'MOST POPULAR'**
  String get mostPopular;

  /// No description provided for @oneCaseActive.
  ///
  /// In en, this message translates to:
  /// **'1 case'**
  String get oneCaseActive;

  /// No description provided for @threeCasesActive.
  ///
  /// In en, this message translates to:
  /// **'3 cases'**
  String get threeCasesActive;

  /// No description provided for @unlimitedCases.
  ///
  /// In en, this message translates to:
  /// **'Unlimited cases'**
  String get unlimitedCases;

  /// No description provided for @threeDocScans.
  ///
  /// In en, this message translates to:
  /// **'3 document scans (total)'**
  String get threeDocScans;

  /// No description provided for @twentyDocScans.
  ///
  /// In en, this message translates to:
  /// **'20 document scans/month'**
  String get twentyDocScans;

  /// No description provided for @unlimitedDocScans.
  ///
  /// In en, this message translates to:
  /// **'Unlimited document scans'**
  String get unlimitedDocScans;

  /// No description provided for @basicAiAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Basic AI analysis'**
  String get basicAiAnalysis;

  /// No description provided for @fullAiAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Full AI analysis'**
  String get fullAiAnalysis;

  /// No description provided for @draftGeneration.
  ///
  /// In en, this message translates to:
  /// **'Draft generation'**
  String get draftGeneration;

  /// No description provided for @priorityProcessing.
  ///
  /// In en, this message translates to:
  /// **'Priority processing'**
  String get priorityProcessing;

  /// No description provided for @fiveAiMessagesTotal.
  ///
  /// In en, this message translates to:
  /// **'5 AI messages (lifetime)'**
  String get fiveAiMessagesTotal;

  /// No description provided for @hundredAiMessagesDay.
  ///
  /// In en, this message translates to:
  /// **'100 AI messages/day'**
  String get hundredAiMessagesDay;

  /// No description provided for @unlimitedAiMessages.
  ///
  /// In en, this message translates to:
  /// **'Unlimited AI messages'**
  String get unlimitedAiMessages;

  /// No description provided for @voiceInput.
  ///
  /// In en, this message translates to:
  /// **'Voice input'**
  String get voiceInput;

  /// No description provided for @strategyRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Strategy recommendations'**
  String get strategyRecommendations;

  /// No description provided for @foundingMemberNote.
  ///
  /// In en, this message translates to:
  /// **'Founding Member: 9.99€/mo for first 3 months'**
  String get foundingMemberNote;

  /// No description provided for @saveTwentyPercent.
  ///
  /// In en, this message translates to:
  /// **'Save 20%'**
  String get saveTwentyPercent;

  /// No description provided for @forever.
  ///
  /// In en, this message translates to:
  /// **'forever'**
  String get forever;

  /// No description provided for @perMonth.
  ///
  /// In en, this message translates to:
  /// **'/month'**
  String get perMonth;

  /// No description provided for @perYear.
  ///
  /// In en, this message translates to:
  /// **'/year'**
  String get perYear;

  /// No description provided for @checkingPurchases.
  ///
  /// In en, this message translates to:
  /// **'Checking for previous purchases…'**
  String get checkingPurchases;

  /// No description provided for @noPreviousPurchases.
  ///
  /// In en, this message translates to:
  /// **'No previous purchases found.'**
  String get noPreviousPurchases;

  /// No description provided for @chatWelcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Hi! I\'m Advocat — your AI legal assistant. I provide legal information, not legal advice. What legal question can I help with?'**
  String get chatWelcomeMessage;

  /// No description provided for @copySummary.
  ///
  /// In en, this message translates to:
  /// **'Copy summary'**
  String get copySummary;

  /// No description provided for @caseSummaryCopied.
  ///
  /// In en, this message translates to:
  /// **'Case summary copied to clipboard'**
  String get caseSummaryCopied;

  /// No description provided for @openCase.
  ///
  /// In en, this message translates to:
  /// **'Open Case'**
  String get openCase;

  /// No description provided for @viewFull.
  ///
  /// In en, this message translates to:
  /// **'View Full'**
  String get viewFull;

  /// No description provided for @draftCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Draft copied to clipboard'**
  String get draftCopiedToClipboard;

  /// No description provided for @reportMileageFraud.
  ///
  /// In en, this message translates to:
  /// **'Report Mileage Fraud'**
  String get reportMileageFraud;

  /// No description provided for @reportMileageFraudDesc.
  ///
  /// In en, this message translates to:
  /// **'This will create a fraud report based on the vehicle check data. You can also open a legal case for further action.'**
  String get reportMileageFraudDesc;

  /// No description provided for @reportAndOpenCase.
  ///
  /// In en, this message translates to:
  /// **'Report & Open Case'**
  String get reportAndOpenCase;

  /// No description provided for @caseCreationComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Case creation with pre-filled data coming soon'**
  String get caseCreationComingSoon;

  /// No description provided for @failedToCreateCaseRetry.
  ///
  /// In en, this message translates to:
  /// **'Failed to create case. Please try again.'**
  String get failedToCreateCaseRetry;

  /// No description provided for @takePhotoInstead.
  ///
  /// In en, this message translates to:
  /// **'Take a Photo Instead'**
  String get takePhotoInstead;

  /// No description provided for @deleteCase.
  ///
  /// In en, this message translates to:
  /// **'Delete Case'**
  String get deleteCase;

  /// No description provided for @deleteCaseConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"? This action cannot be undone.'**
  String deleteCaseConfirm(String title);

  /// No description provided for @haveQuestionsAi.
  ///
  /// In en, this message translates to:
  /// **'Have questions? Talk to AI'**
  String get haveQuestionsAi;

  /// No description provided for @cookiePolicy.
  ///
  /// In en, this message translates to:
  /// **'Cookie Policy'**
  String get cookiePolicy;

  /// No description provided for @aiDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'AI Disclaimer'**
  String get aiDisclaimer;

  /// No description provided for @dataPrivacyConsent.
  ///
  /// In en, this message translates to:
  /// **'Data Privacy Consent'**
  String get dataPrivacyConsent;

  /// No description provided for @gdprIntro.
  ///
  /// In en, this message translates to:
  /// **'To provide AI legal assistance, we process your data in accordance with GDPR (EU 2016/679). By continuing you agree to:'**
  String get gdprIntro;

  /// No description provided for @gdprChat.
  ///
  /// In en, this message translates to:
  /// **'Processing of your chat messages by AI'**
  String get gdprChat;

  /// No description provided for @gdprDocs.
  ///
  /// In en, this message translates to:
  /// **'Analysis of uploaded documents'**
  String get gdprDocs;

  /// No description provided for @gdprStorage.
  ///
  /// In en, this message translates to:
  /// **'Encrypted storage of case data'**
  String get gdprStorage;

  /// No description provided for @gdprDelete.
  ///
  /// In en, this message translates to:
  /// **'Right to delete your data at any time'**
  String get gdprDelete;

  /// No description provided for @gdprFooter.
  ///
  /// In en, this message translates to:
  /// **'Your data is encrypted and processed securely. We use trusted service providers (AI processing, cloud database) to deliver the service. See our Privacy Policy for details. You can withdraw consent and delete all data from Settings.'**
  String get gdprFooter;

  /// No description provided for @gdprConsentAiProcessing.
  ///
  /// In en, this message translates to:
  /// **'I agree to the processing of my data for AI legal assistance (required)'**
  String get gdprConsentAiProcessing;

  /// No description provided for @gdprConsentAnalytics.
  ///
  /// In en, this message translates to:
  /// **'I agree to analytics to improve the service (optional)'**
  String get gdprConsentAnalytics;

  /// No description provided for @gdprArt9Intro.
  ///
  /// In en, this message translates to:
  /// **'This app processes special category personal data under GDPR Article 9, including:'**
  String get gdprArt9Intro;

  /// No description provided for @gdprSpecialLegalCases.
  ///
  /// In en, this message translates to:
  /// **'Your legal case details and court documents'**
  String get gdprSpecialLegalCases;

  /// No description provided for @gdprSpecialNationality.
  ///
  /// In en, this message translates to:
  /// **'Nationality and immigration status'**
  String get gdprSpecialNationality;

  /// No description provided for @gdprConsentLegalData.
  ///
  /// In en, this message translates to:
  /// **'I consent to the processing of my legal case data, nationality, and immigration status by AI (required)'**
  String get gdprConsentLegalData;

  /// No description provided for @gdprConsentVoice.
  ///
  /// In en, this message translates to:
  /// **'I consent to voice recording processing (optional)'**
  String get gdprConsentVoice;

  /// No description provided for @gdprViewPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'View Privacy Policy'**
  String get gdprViewPrivacyPolicy;

  /// No description provided for @legalInformation.
  ///
  /// In en, this message translates to:
  /// **'Legal Information'**
  String get legalInformation;

  /// No description provided for @legalEntityName.
  ///
  /// In en, this message translates to:
  /// **'Vorantis OÜ'**
  String get legalEntityName;

  /// No description provided for @legalRegistryCode.
  ///
  /// In en, this message translates to:
  /// **'Registry code: 17098992'**
  String get legalRegistryCode;

  /// No description provided for @legalAddress.
  ///
  /// In en, this message translates to:
  /// **'Harju maakond, Tallinn, Kesklinna linnaosa, Tornimäe tn 5, 10145'**
  String get legalAddress;

  /// No description provided for @legalEmail.
  ///
  /// In en, this message translates to:
  /// **'Email: support@advocat.ee'**
  String get legalEmail;

  /// No description provided for @legalRegistry.
  ///
  /// In en, this message translates to:
  /// **'Registered in Estonian Commercial Register (Äriregister)'**
  String get legalRegistry;

  /// No description provided for @aiGeneratedDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'AI-generated • Not legal advice'**
  String get aiGeneratedDisclaimer;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @iAgree.
  ///
  /// In en, this message translates to:
  /// **'I Agree'**
  String get iAgree;

  /// No description provided for @iAgreeToThe.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get iAgreeToThe;

  /// No description provided for @orWord.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orWord;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @russian.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get russian;

  /// No description provided for @finnish.
  ///
  /// In en, this message translates to:
  /// **'Finnish'**
  String get finnish;

  /// No description provided for @successSubscribed.
  ///
  /// In en, this message translates to:
  /// **'Successfully subscribed to {plan}!'**
  String successSubscribed(String plan);

  /// No description provided for @paymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment failed: {error}'**
  String paymentFailed(String error);

  /// No description provided for @whatToDo.
  ///
  /// In en, this message translates to:
  /// **'What To Do'**
  String get whatToDo;

  /// No description provided for @getHelp.
  ///
  /// In en, this message translates to:
  /// **'Get Help'**
  String get getHelp;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @didYouKnow.
  ///
  /// In en, this message translates to:
  /// **'Did you know?'**
  String get didYouKnow;

  /// No description provided for @mustKnow.
  ///
  /// In en, this message translates to:
  /// **'Must know'**
  String get mustKnow;

  /// No description provided for @goodToKnow.
  ///
  /// In en, this message translates to:
  /// **'Good to know'**
  String get goodToKnow;

  /// No description provided for @sentFromAdvocat.
  ///
  /// In en, this message translates to:
  /// **'Sent from Advocat app'**
  String get sentFromAdvocat;

  /// No description provided for @policeActionStayCalm.
  ///
  /// In en, this message translates to:
  /// **'Stay calm and keep your hands visible'**
  String get policeActionStayCalm;

  /// No description provided for @policeActionAskWhy.
  ///
  /// In en, this message translates to:
  /// **'Ask the officer why you are being stopped'**
  String get policeActionAskWhy;

  /// No description provided for @policeActionProvideName.
  ///
  /// In en, this message translates to:
  /// **'Provide your name and date of birth'**
  String get policeActionProvideName;

  /// No description provided for @policeActionWantLawyer.
  ///
  /// In en, this message translates to:
  /// **'State clearly: \"I want a lawyer before any questions\"'**
  String get policeActionWantLawyer;

  /// No description provided for @policeActionAskInterpreter.
  ///
  /// In en, this message translates to:
  /// **'If needed, ask for an interpreter'**
  String get policeActionAskInterpreter;

  /// No description provided for @policeActionNoteBadge.
  ///
  /// In en, this message translates to:
  /// **'Note the officer\'s name and badge number'**
  String get policeActionNoteBadge;

  /// No description provided for @policeFactMustTellReason.
  ///
  /// In en, this message translates to:
  /// **'In Finland, the police must tell you the reason for stopping you. If they do not, you may ask — they are legally required to explain.'**
  String get policeFactMustTellReason;

  /// No description provided for @policeFactCanRecord.
  ///
  /// In en, this message translates to:
  /// **'You can record police interactions in public places in Finland. This is protected under freedom of expression.'**
  String get policeFactCanRecord;

  /// No description provided for @contactFinnishLegalAid.
  ///
  /// In en, this message translates to:
  /// **'Finnish Legal Aid'**
  String get contactFinnishLegalAid;

  /// No description provided for @contactNonDiscriminationOmbudsman.
  ///
  /// In en, this message translates to:
  /// **'Non-Discrimination Ombudsman'**
  String get contactNonDiscriminationOmbudsman;

  /// No description provided for @deportationDeadlineAppeal.
  ///
  /// In en, this message translates to:
  /// **'Appeal to Administrative Court — usually 30 days from notification'**
  String get deportationDeadlineAppeal;

  /// No description provided for @deportationDeadlineLegalAid.
  ///
  /// In en, this message translates to:
  /// **'Apply for legal aid — do this IMMEDIATELY'**
  String get deportationDeadlineLegalAid;

  /// No description provided for @deportationFactStayDuringAppeal.
  ///
  /// In en, this message translates to:
  /// **'In Finland, you usually have the right to stay in the country while your appeal is being processed. Deportation cannot happen during an active appeal in most cases.'**
  String get deportationFactStayDuringAppeal;

  /// No description provided for @contactRefugeeAdviceCentre.
  ///
  /// In en, this message translates to:
  /// **'Finnish Refugee Advice Centre'**
  String get contactRefugeeAdviceCentre;

  /// No description provided for @contactAdminCourtHelsinki.
  ///
  /// In en, this message translates to:
  /// **'Administrative Court Helsinki'**
  String get contactAdminCourtHelsinki;

  /// No description provided for @workplaceActionKeepContract.
  ///
  /// In en, this message translates to:
  /// **'Keep copies of your employment contract'**
  String get workplaceActionKeepContract;

  /// No description provided for @workplaceActionTrackHours.
  ///
  /// In en, this message translates to:
  /// **'Track your working hours independently'**
  String get workplaceActionTrackHours;

  /// No description provided for @workplaceActionReportUnsafe.
  ///
  /// In en, this message translates to:
  /// **'Report unsafe conditions to occupational safety'**
  String get workplaceActionReportUnsafe;

  /// No description provided for @workplaceActionJoinUnion.
  ///
  /// In en, this message translates to:
  /// **'Join a trade union for protection'**
  String get workplaceActionJoinUnion;

  /// No description provided for @workplaceActionContactAuthority.
  ///
  /// In en, this message translates to:
  /// **'Contact the Occupational Safety Authority if needed'**
  String get workplaceActionContactAuthority;

  /// No description provided for @workplaceFactCollectiveWage.
  ///
  /// In en, this message translates to:
  /// **'In Finland, collective agreements set minimum wages by industry — there is no single national minimum wage. Your employer must follow the collective agreement for your field.'**
  String get workplaceFactCollectiveWage;

  /// No description provided for @workplaceFactOralContract.
  ///
  /// In en, this message translates to:
  /// **'Even without a written contract, you have full employee rights in Finland. An oral agreement is equally binding by law.'**
  String get workplaceFactOralContract;

  /// No description provided for @contactOccupationalSafety.
  ///
  /// In en, this message translates to:
  /// **'Occupational Safety Authority'**
  String get contactOccupationalSafety;

  /// No description provided for @contactTradeUnionSAK.
  ///
  /// In en, this message translates to:
  /// **'Trade Union Advice (SAK)'**
  String get contactTradeUnionSAK;

  /// No description provided for @tenantActionWrittenAgreement.
  ///
  /// In en, this message translates to:
  /// **'Always have a written rental agreement'**
  String get tenantActionWrittenAgreement;

  /// No description provided for @tenantActionDocumentCondition.
  ///
  /// In en, this message translates to:
  /// **'Document the apartment condition at move-in (photos)'**
  String get tenantActionDocumentCondition;

  /// No description provided for @tenantActionReportMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Report maintenance issues in writing'**
  String get tenantActionReportMaintenance;

  /// No description provided for @tenantActionNoIllegalEviction.
  ///
  /// In en, this message translates to:
  /// **'Never agree to illegal eviction — courts must decide'**
  String get tenantActionNoIllegalEviction;

  /// No description provided for @tenantActionContactAdvisory.
  ///
  /// In en, this message translates to:
  /// **'Contact tenant advisory services if disputes arise'**
  String get tenantActionContactAdvisory;

  /// No description provided for @tenantFactNoEvictionWithoutCourt.
  ///
  /// In en, this message translates to:
  /// **'A landlord in Finland cannot evict you without a court order, even if your lease has expired. Changing locks or cutting utilities is illegal.'**
  String get tenantFactNoEvictionWithoutCourt;

  /// No description provided for @contactTenantsAssociation.
  ///
  /// In en, this message translates to:
  /// **'Finnish Tenants Association'**
  String get contactTenantsAssociation;

  /// No description provided for @contactConsumerDisputesBoard.
  ///
  /// In en, this message translates to:
  /// **'Consumer Disputes Board'**
  String get contactConsumerDisputesBoard;

  /// No description provided for @detentionActionAskDecision.
  ///
  /// In en, this message translates to:
  /// **'Ask for the written detention decision immediately'**
  String get detentionActionAskDecision;

  /// No description provided for @detentionActionRequestLawyer.
  ///
  /// In en, this message translates to:
  /// **'Request to contact a lawyer'**
  String get detentionActionRequestLawyer;

  /// No description provided for @detentionActionContactEmbassy.
  ///
  /// In en, this message translates to:
  /// **'Contact your embassy or consulate'**
  String get detentionActionContactEmbassy;

  /// No description provided for @detentionActionAskMedical.
  ///
  /// In en, this message translates to:
  /// **'Ask for medical attention if needed'**
  String get detentionActionAskMedical;

  /// No description provided for @detentionActionRequestInterpreter.
  ///
  /// In en, this message translates to:
  /// **'Request an interpreter for all proceedings'**
  String get detentionActionRequestInterpreter;

  /// No description provided for @detentionDeadlineCourtReview.
  ///
  /// In en, this message translates to:
  /// **'District Court must review detention within 4 days'**
  String get detentionDeadlineCourtReview;

  /// No description provided for @detentionDeadlineContinuation.
  ///
  /// In en, this message translates to:
  /// **'Court reviews continuation every 2 weeks'**
  String get detentionDeadlineContinuation;

  /// No description provided for @detentionFactCourtReview.
  ///
  /// In en, this message translates to:
  /// **'Immigration detention in Finland must be reviewed by a district court within 4 days. If it is not, the detention becomes unlawful.'**
  String get detentionFactCourtReview;

  /// No description provided for @contactParliamentaryOmbudsman.
  ///
  /// In en, this message translates to:
  /// **'Parliamentary Ombudsman'**
  String get contactParliamentaryOmbudsman;

  /// No description provided for @discriminationActionWriteDown.
  ///
  /// In en, this message translates to:
  /// **'Write down exactly what happened (date, time, place)'**
  String get discriminationActionWriteDown;

  /// No description provided for @discriminationActionSaveEvidence.
  ///
  /// In en, this message translates to:
  /// **'Save any evidence: messages, emails, witnesses'**
  String get discriminationActionSaveEvidence;

  /// No description provided for @discriminationActionFileComplaint.
  ///
  /// In en, this message translates to:
  /// **'File a complaint with the Non-Discrimination Ombudsman'**
  String get discriminationActionFileComplaint;

  /// No description provided for @discriminationActionContactLegalAid.
  ///
  /// In en, this message translates to:
  /// **'Contact a legal aid office for free advice'**
  String get discriminationActionContactLegalAid;

  /// No description provided for @discriminationActionReportPolice.
  ///
  /// In en, this message translates to:
  /// **'Report to police if threats or assault were involved'**
  String get discriminationActionReportPolice;

  /// No description provided for @discriminationFactNonDiscriminationAct.
  ///
  /// In en, this message translates to:
  /// **'Finland\'s Non-Discrimination Act covers discrimination based on age, origin, nationality, language, religion, health, disability, sexual orientation, and other personal characteristics.'**
  String get discriminationFactNonDiscriminationAct;

  /// No description provided for @contactVictimSupportRIKU.
  ///
  /// In en, this message translates to:
  /// **'Victim Support Finland (RIKU)'**
  String get contactVictimSupportRIKU;

  /// No description provided for @domesticViolence.
  ///
  /// In en, this message translates to:
  /// **'Domestic Violence & Assault'**
  String get domesticViolence;

  /// No description provided for @domesticViolenceDesc.
  ///
  /// In en, this message translates to:
  /// **'Victim rights, emergency help, restraining orders'**
  String get domesticViolenceDesc;

  /// No description provided for @rightCallEmergency.
  ///
  /// In en, this message translates to:
  /// **'You have the right to call 112 in any emergency — police, ambulance, fire'**
  String get rightCallEmergency;

  /// No description provided for @rightVictimProtection.
  ///
  /// In en, this message translates to:
  /// **'As a victim, you have the right to protection, support, and information about your case'**
  String get rightVictimProtection;

  /// No description provided for @rightRestrainingOrder.
  ///
  /// In en, this message translates to:
  /// **'You can apply for a restraining order (lähestymiskielto) to keep the abuser away'**
  String get rightRestrainingOrder;

  /// No description provided for @rightVictimInterpreter.
  ///
  /// In en, this message translates to:
  /// **'You have the right to an interpreter during all legal proceedings'**
  String get rightVictimInterpreter;

  /// No description provided for @rightMedicalHelp.
  ///
  /// In en, this message translates to:
  /// **'You have the right to immediate medical treatment and documentation of injuries'**
  String get rightMedicalHelp;

  /// No description provided for @rightShelter.
  ///
  /// In en, this message translates to:
  /// **'You have the right to emergency shelter — contact a shelter or social services'**
  String get rightShelter;

  /// No description provided for @mustReportDanger.
  ///
  /// In en, this message translates to:
  /// **'If someone is in immediate danger, call 112 immediately'**
  String get mustReportDanger;

  /// No description provided for @mustDocumentInjuries.
  ///
  /// In en, this message translates to:
  /// **'Document all injuries — photos, medical records, written notes'**
  String get mustDocumentInjuries;

  /// No description provided for @domesticActionCallEmergency.
  ///
  /// In en, this message translates to:
  /// **'Call 112 if you are in immediate danger'**
  String get domesticActionCallEmergency;

  /// No description provided for @domesticActionGoToSafe.
  ///
  /// In en, this message translates to:
  /// **'Go to a safe place — shelter, friend, public place'**
  String get domesticActionGoToSafe;

  /// No description provided for @domesticActionDocumentEverything.
  ///
  /// In en, this message translates to:
  /// **'Document injuries: take photos, get medical records'**
  String get domesticActionDocumentEverything;

  /// No description provided for @domesticActionFilePoliceReport.
  ///
  /// In en, this message translates to:
  /// **'File a police report — you can do this later too'**
  String get domesticActionFilePoliceReport;

  /// No description provided for @domesticActionContactShelter.
  ///
  /// In en, this message translates to:
  /// **'Contact a shelter or crisis helpline'**
  String get domesticActionContactShelter;

  /// No description provided for @domesticActionApplyRestraining.
  ///
  /// In en, this message translates to:
  /// **'Apply for a restraining order through police or court'**
  String get domesticActionApplyRestraining;

  /// No description provided for @domesticFactRestrainingOrder.
  ///
  /// In en, this message translates to:
  /// **'In Finland, a restraining order (lähestymiskielto) can be issued even without a criminal case. It prohibits the person from contacting or approaching you.'**
  String get domesticFactRestrainingOrder;

  /// No description provided for @domesticFactVictimDirective.
  ///
  /// In en, this message translates to:
  /// **'Under EU Victims\' Directive 2012/29/EU, you have the right to be treated with respect, to receive information in a language you understand, and to access victim support services — regardless of your residence status.'**
  String get domesticFactVictimDirective;

  /// No description provided for @domesticDeadlinePoliceReport.
  ///
  /// In en, this message translates to:
  /// **'File police report — no strict deadline, but sooner is better for evidence'**
  String get domesticDeadlinePoliceReport;

  /// No description provided for @domesticDeadlineRestraining.
  ///
  /// In en, this message translates to:
  /// **'Restraining order — can be applied for at any time'**
  String get domesticDeadlineRestraining;

  /// No description provided for @contactEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency Number'**
  String get contactEmergency;

  /// No description provided for @contactShelter.
  ///
  /// In en, this message translates to:
  /// **'Turvakoti (Shelter) Helpline'**
  String get contactShelter;

  /// No description provided for @contactCrisisHelpline.
  ///
  /// In en, this message translates to:
  /// **'Crisis Helpline (Kriisipuhelin)'**
  String get contactCrisisHelpline;

  /// No description provided for @contactNollaLinja.
  ///
  /// In en, this message translates to:
  /// **'Nollalinja — Violence Against Women Helpline'**
  String get contactNollaLinja;

  /// No description provided for @inheritance.
  ///
  /// In en, this message translates to:
  /// **'Inheritance'**
  String get inheritance;

  /// No description provided for @inheritanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Wills, estate, heirs\' rights, forced heirship, probate'**
  String get inheritanceDesc;

  /// No description provided for @rightInheritanceForced.
  ///
  /// In en, this message translates to:
  /// **'Forced heirs (children, spouse) are entitled to a compulsory share regardless of the will'**
  String get rightInheritanceForced;

  /// No description provided for @rightInheritanceWill.
  ///
  /// In en, this message translates to:
  /// **'You have the right to make a will disposing of your property — notarized wills have the strongest legal force'**
  String get rightInheritanceWill;

  /// No description provided for @rightInheritanceRenounce.
  ///
  /// In en, this message translates to:
  /// **'You can renounce an inheritance within 3 months of learning about it'**
  String get rightInheritanceRenounce;

  /// No description provided for @rightInheritanceInfo.
  ///
  /// In en, this message translates to:
  /// **'You have the right to obtain information about the estate from banks and registries'**
  String get rightInheritanceInfo;

  /// No description provided for @rightInheritanceDispute.
  ///
  /// In en, this message translates to:
  /// **'You can challenge an unfair will in court within the statutory limitation period'**
  String get rightInheritanceDispute;

  /// No description provided for @mustFileInheritance.
  ///
  /// In en, this message translates to:
  /// **'File for succession proceedings at a notary within a reasonable time'**
  String get mustFileInheritance;

  /// No description provided for @mustNotifyHeirs.
  ///
  /// In en, this message translates to:
  /// **'All known heirs must be notified of the succession proceedings'**
  String get mustNotifyHeirs;

  /// No description provided for @inheritanceActionGatherDocs.
  ///
  /// In en, this message translates to:
  /// **'Gather all documents: death certificate, will, property records, bank statements'**
  String get inheritanceActionGatherDocs;

  /// No description provided for @inheritanceActionContactNotary.
  ///
  /// In en, this message translates to:
  /// **'Contact a notary to open succession proceedings'**
  String get inheritanceActionContactNotary;

  /// No description provided for @inheritanceActionCheckDebts.
  ///
  /// In en, this message translates to:
  /// **'Check whether the estate has debts before accepting inheritance'**
  String get inheritanceActionCheckDebts;

  /// No description provided for @inheritanceActionFileCourt.
  ///
  /// In en, this message translates to:
  /// **'If the will is disputed, file a claim in court'**
  String get inheritanceActionFileCourt;

  /// No description provided for @inheritanceDeadlineRenounce.
  ///
  /// In en, this message translates to:
  /// **'3 months to renounce inheritance after learning of it'**
  String get inheritanceDeadlineRenounce;

  /// No description provided for @inheritanceDeadlineDispute.
  ///
  /// In en, this message translates to:
  /// **'Statute of limitations for challenging a will: varies by grounds'**
  String get inheritanceDeadlineDispute;

  /// No description provided for @inheritanceFactForced.
  ///
  /// In en, this message translates to:
  /// **'In Estonia, descendants and spouse have a right to a compulsory share (1/2 of legal share) even if excluded from the will'**
  String get inheritanceFactForced;

  /// No description provided for @inheritanceFactNotary.
  ///
  /// In en, this message translates to:
  /// **'All succession proceedings in Estonia must go through a notary — you cannot skip this step'**
  String get inheritanceFactNotary;

  /// No description provided for @consumerProtection.
  ///
  /// In en, this message translates to:
  /// **'Consumer Protection'**
  String get consumerProtection;

  /// No description provided for @consumerProtectionDesc.
  ///
  /// In en, this message translates to:
  /// **'Fraud, defective products, returns, deceptive sellers'**
  String get consumerProtectionDesc;

  /// No description provided for @rightReturnOnline.
  ///
  /// In en, this message translates to:
  /// **'You have 14 days to cancel online purchases without reason (EU right of withdrawal)'**
  String get rightReturnOnline;

  /// No description provided for @rightDefectiveProduct.
  ///
  /// In en, this message translates to:
  /// **'If a product is defective, you have the right to repair, replacement, or refund'**
  String get rightDefectiveProduct;

  /// No description provided for @rightClearPricing.
  ///
  /// In en, this message translates to:
  /// **'Sellers must display clear prices including all fees — hidden costs are illegal'**
  String get rightClearPricing;

  /// No description provided for @rightComplainBoard.
  ///
  /// In en, this message translates to:
  /// **'You can file a free complaint with the Consumer Disputes Board'**
  String get rightComplainBoard;

  /// No description provided for @rightProtectionFraud.
  ///
  /// In en, this message translates to:
  /// **'You are protected against unfair commercial practices and fraud'**
  String get rightProtectionFraud;

  /// No description provided for @mustKeepReceipts.
  ///
  /// In en, this message translates to:
  /// **'Keep all receipts, contracts, and communication with sellers'**
  String get mustKeepReceipts;

  /// No description provided for @mustActTimely.
  ///
  /// In en, this message translates to:
  /// **'Report defects to the seller within a reasonable time after discovery'**
  String get mustActTimely;

  /// No description provided for @consumerActionKeepEvidence.
  ///
  /// In en, this message translates to:
  /// **'Keep receipts, screenshots, emails, and all proof of purchase'**
  String get consumerActionKeepEvidence;

  /// No description provided for @consumerActionContactSeller.
  ///
  /// In en, this message translates to:
  /// **'Contact the seller first — explain the problem in writing'**
  String get consumerActionContactSeller;

  /// No description provided for @consumerActionFileComplaint.
  ///
  /// In en, this message translates to:
  /// **'File a complaint with the Consumer Disputes Board (kuluttajariitalautakunta)'**
  String get consumerActionFileComplaint;

  /// No description provided for @consumerActionContactAuthority.
  ///
  /// In en, this message translates to:
  /// **'Contact the Consumer Advisory Services for free help'**
  String get consumerActionContactAuthority;

  /// No description provided for @consumerActionReportFraud.
  ///
  /// In en, this message translates to:
  /// **'Report fraud to the police and Consumer Ombudsman'**
  String get consumerActionReportFraud;

  /// No description provided for @consumerFactWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'Under the EU Consumer Rights Directive 2011/83/EU, you have 14 days to withdraw from any online or distance purchase — no questions asked. The seller must refund you within 14 days.'**
  String get consumerFactWithdrawal;

  /// No description provided for @consumerFactWarranty.
  ///
  /// In en, this message translates to:
  /// **'In Finland, the seller is responsible for product defects for a reasonable time (often 2+ years). This is separate from any manufacturer warranty.'**
  String get consumerFactWarranty;

  /// No description provided for @consumerDeadlineWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'Online purchase withdrawal — 14 days from delivery'**
  String get consumerDeadlineWithdrawal;

  /// No description provided for @consumerDeadlineDefect.
  ///
  /// In en, this message translates to:
  /// **'Report defect to seller — within 2 months of discovery (recommended)'**
  String get consumerDeadlineDefect;

  /// No description provided for @contactConsumerAdvisory.
  ///
  /// In en, this message translates to:
  /// **'Consumer Advisory Services'**
  String get contactConsumerAdvisory;

  /// No description provided for @contactConsumerOmbudsman.
  ///
  /// In en, this message translates to:
  /// **'Consumer Ombudsman (Kuluttaja-asiamies)'**
  String get contactConsumerOmbudsman;

  /// No description provided for @contactConsumerDisputesBoardDirect.
  ///
  /// In en, this message translates to:
  /// **'Consumer Disputes Board'**
  String get contactConsumerDisputesBoardDirect;

  /// No description provided for @caseTypeStepLabel.
  ///
  /// In en, this message translates to:
  /// **'Case Type'**
  String get caseTypeStepLabel;

  /// No description provided for @detailsStepLabel.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailsStepLabel;

  /// No description provided for @documentsStepLabel.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documentsStepLabel;

  /// No description provided for @whatTypeOfCase.
  ///
  /// In en, this message translates to:
  /// **'What type of case is this?'**
  String get whatTypeOfCase;

  /// No description provided for @selectCategoryDescription.
  ///
  /// In en, this message translates to:
  /// **'Select the category that best describes your situation.'**
  String get selectCategoryDescription;

  /// No description provided for @tellUsAboutCase.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your case'**
  String get tellUsAboutCase;

  /// No description provided for @aiHelpsUnderstand.
  ///
  /// In en, this message translates to:
  /// **'This information helps our AI understand your situation better.'**
  String get aiHelpsUnderstand;

  /// No description provided for @caseTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Residence Permit Appeal 2026'**
  String get caseTitleHint;

  /// No description provided for @countryJurisdiction.
  ///
  /// In en, this message translates to:
  /// **'Country / Jurisdiction'**
  String get countryJurisdiction;

  /// No description provided for @selectCountryHint.
  ///
  /// In en, this message translates to:
  /// **'Select a country'**
  String get selectCountryHint;

  /// No description provided for @referenceNumberHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., UMA/12345/2026'**
  String get referenceNumberHint;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptional;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe your situation briefly. What happened? What decision was made?'**
  String get descriptionHint;

  /// No description provided for @uploadFirstDocument.
  ///
  /// In en, this message translates to:
  /// **'Upload your first document'**
  String get uploadFirstDocument;

  /// No description provided for @uploadDocumentDescription.
  ///
  /// In en, this message translates to:
  /// **'Upload the decision letter or any relevant document. You can skip this step and add documents later.'**
  String get uploadDocumentDescription;

  /// No description provided for @tapToUploadFile.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload a file'**
  String get tapToUploadFile;

  /// No description provided for @fileSizeLimit.
  ///
  /// In en, this message translates to:
  /// **'PDF, JPG, PNG up to 25 MB'**
  String get fileSizeLimit;

  /// No description provided for @addDocumentsLaterHint.
  ///
  /// In en, this message translates to:
  /// **'You can always add documents later from the case detail screen.'**
  String get addDocumentsLaterHint;

  /// No description provided for @callAI.
  ///
  /// In en, this message translates to:
  /// **'Call AI'**
  String get callAI;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @encrypted.
  ///
  /// In en, this message translates to:
  /// **'Encrypted'**
  String get encrypted;

  /// No description provided for @typing.
  ///
  /// In en, this message translates to:
  /// **'Typing…'**
  String get typing;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @chatWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'I will analyze the situation, check documents, find errors, and suggest what to do.'**
  String get chatWelcomeSubtitle;

  /// No description provided for @tapMicrophoneToSpeak.
  ///
  /// In en, this message translates to:
  /// **'Tap the microphone to speak'**
  String get tapMicrophoneToSpeak;

  /// No description provided for @categoryEssential.
  ///
  /// In en, this message translates to:
  /// **'Essential'**
  String get categoryEssential;

  /// No description provided for @categoryPolice.
  ///
  /// In en, this message translates to:
  /// **'Police'**
  String get categoryPolice;

  /// No description provided for @categoryWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get categoryWork;

  /// No description provided for @categoryHousing.
  ///
  /// In en, this message translates to:
  /// **'Housing'**
  String get categoryHousing;

  /// No description provided for @categoryConsumer.
  ///
  /// In en, this message translates to:
  /// **'Consumer'**
  String get categoryConsumer;

  /// No description provided for @rightsInsideCount.
  ///
  /// In en, this message translates to:
  /// **'{count} rights inside'**
  String rightsInsideCount(int count);

  /// No description provided for @freeAidThreshold.
  ///
  /// In en, this message translates to:
  /// **'Free aid threshold'**
  String get freeAidThreshold;

  /// No description provided for @partialAidThreshold.
  ///
  /// In en, this message translates to:
  /// **'Partial aid threshold'**
  String get partialAidThreshold;

  /// No description provided for @assetLimit.
  ///
  /// In en, this message translates to:
  /// **'Asset limit'**
  String get assetLimit;

  /// No description provided for @whereToApplyLabel.
  ///
  /// In en, this message translates to:
  /// **'Where to apply'**
  String get whereToApplyLabel;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// No description provided for @websiteLabel.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get websiteLabel;

  /// No description provided for @disclaimerCollapsed.
  ///
  /// In en, this message translates to:
  /// **'AI guidance only'**
  String get disclaimerCollapsed;

  /// No description provided for @disclaimerExpanded.
  ///
  /// In en, this message translates to:
  /// **'AI assistant — not legal advice. Always verify with a qualified lawyer.'**
  String get disclaimerExpanded;

  /// No description provided for @chatDisclaimerBanner.
  ///
  /// In en, this message translates to:
  /// **'AI assistant provides legal information, not legal advice. Always consult a qualified lawyer.'**
  String get chatDisclaimerBanner;

  /// No description provided for @categoryChildren.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get categoryChildren;

  /// No description provided for @categoryDigital.
  ///
  /// In en, this message translates to:
  /// **'Digital'**
  String get categoryDigital;

  /// No description provided for @childrenRights.
  ///
  /// In en, this message translates to:
  /// **'Children\'s Rights & Alimony'**
  String get childrenRights;

  /// No description provided for @childrenRightsDesc.
  ///
  /// In en, this message translates to:
  /// **'Child support, alimony, protection, state guarantees'**
  String get childrenRightsDesc;

  /// No description provided for @cyberbullying.
  ///
  /// In en, this message translates to:
  /// **'Cyberbullying & Online Harassment'**
  String get cyberbullying;

  /// No description provided for @cyberbullyingDesc.
  ///
  /// In en, this message translates to:
  /// **'Threats, privacy violations, defamation online'**
  String get cyberbullyingDesc;

  /// No description provided for @rightChildSupport.
  ///
  /// In en, this message translates to:
  /// **'Both parents are legally obligated to support their child financially (Perekonnaseadus § 100–102)'**
  String get rightChildSupport;

  /// No description provided for @rightMinimumAlimony.
  ///
  /// In en, this message translates to:
  /// **'Minimum child support in Estonia: base amount (€295.86) + 3% of previous year\'s average gross salary (PKS § 101). From 01.04.2026 — €318.62/month per child. Updated annually on April 1st. Calculator: alimendid.ee'**
  String get rightMinimumAlimony;

  /// No description provided for @rightCourtAlimony.
  ///
  /// In en, this message translates to:
  /// **'You can apply for alimony through county court (maakohus) — no lawyer required for claims up to €6,400'**
  String get rightCourtAlimony;

  /// No description provided for @rightBailiffEnforcement.
  ///
  /// In en, this message translates to:
  /// **'If the parent refuses to pay, a bailiff (kohtutäitur) can enforce the court order, including wage garnishment'**
  String get rightBailiffEnforcement;

  /// No description provided for @rightStateAlimonyGuarantee.
  ///
  /// In en, this message translates to:
  /// **'If the parent does not pay, the state provides elatisabi (maintenance allowance) through Sotsiaalkindlustusamet — up to €100/month per child'**
  String get rightStateAlimonyGuarantee;

  /// No description provided for @rightChildEducation.
  ///
  /// In en, this message translates to:
  /// **'Every child has the right to education, healthcare, and protection from abuse (Lastekaitseseadus § 4–5)'**
  String get rightChildEducation;

  /// No description provided for @rightChildContact.
  ///
  /// In en, this message translates to:
  /// **'A child has the right to maintain contact with both parents unless a court decides otherwise (PKS § 143)'**
  String get rightChildContact;

  /// No description provided for @mustFileCourtClaim.
  ///
  /// In en, this message translates to:
  /// **'To receive alimony, you must file a claim at court or agree on the amount in writing'**
  String get mustFileCourtClaim;

  /// No description provided for @mustNotifyAddressChange.
  ///
  /// In en, this message translates to:
  /// **'Notify Sotsiaalkindlustusamet of address changes if receiving elatisabi'**
  String get mustNotifyAddressChange;

  /// No description provided for @childrenActionGatherDocs.
  ///
  /// In en, this message translates to:
  /// **'Gather child\'s birth certificate, your ID, and proof of expenses'**
  String get childrenActionGatherDocs;

  /// No description provided for @childrenActionFileCourtClaim.
  ///
  /// In en, this message translates to:
  /// **'File an alimony claim at the county court (maakohus) — can be done online via e-toimik'**
  String get childrenActionFileCourtClaim;

  /// No description provided for @childrenActionApplyElatisabi.
  ///
  /// In en, this message translates to:
  /// **'Apply for state alimony guarantee (elatisabi) at Sotsiaalkindlustusamet if parent won\'t pay'**
  String get childrenActionApplyElatisabi;

  /// No description provided for @childrenActionContactBailiff.
  ///
  /// In en, this message translates to:
  /// **'Contact a bailiff (kohtutäitur) to enforce the court order'**
  String get childrenActionContactBailiff;

  /// No description provided for @childrenActionCallLasteabi.
  ///
  /// In en, this message translates to:
  /// **'Call Lasteabi 116 111 for children\'s helpline — free, 24/7'**
  String get childrenActionCallLasteabi;

  /// No description provided for @childrenDeadlineElatisabi.
  ///
  /// In en, this message translates to:
  /// **'Apply for elatisabi — after court order, no strict deadline but process takes time'**
  String get childrenDeadlineElatisabi;

  /// No description provided for @childrenDeadlineCourt.
  ///
  /// In en, this message translates to:
  /// **'Alimony can be claimed retroactively for up to 1 year before court filing'**
  String get childrenDeadlineCourt;

  /// No description provided for @childrenFactMinimum.
  ///
  /// In en, this message translates to:
  /// **'From 01.04.2026 minimum child support is €318.62/month per child. Formula: base amount (€295.86) + 3% of previous year\'s average gross salary. Updated annually on April 1st. A parent cannot agree to pay less. Calculator: alimendid.ee'**
  String get childrenFactMinimum;

  /// No description provided for @childrenFactElatisabi.
  ///
  /// In en, this message translates to:
  /// **'Estonia\'s state alimony guarantee (elatisabi) was introduced in 2017 to protect children when a parent refuses to pay. The state pays and then recovers the amount from the debtor parent.'**
  String get childrenFactElatisabi;

  /// No description provided for @rightReportCybercrime.
  ///
  /// In en, this message translates to:
  /// **'You have the right to report online threats, harassment, and identity theft to the police (Karistusseadustik § 120, § 157¹)'**
  String get rightReportCybercrime;

  /// No description provided for @rightContentRemoval.
  ///
  /// In en, this message translates to:
  /// **'You can request removal of defamatory or private content from platforms and demand takedown under GDPR'**
  String get rightContentRemoval;

  /// No description provided for @rightMoralDamageCompensation.
  ///
  /// In en, this message translates to:
  /// **'You may claim compensation for moral damage caused by cyberbullying (Võlaõigusseadus § 1043–1055)'**
  String get rightMoralDamageCompensation;

  /// No description provided for @rightPrivacyProtection.
  ///
  /// In en, this message translates to:
  /// **'Your private life is protected — unauthorized sharing of your photos, messages, or personal data is illegal (KarS § 157)'**
  String get rightPrivacyProtection;

  /// No description provided for @rightDataProtection.
  ///
  /// In en, this message translates to:
  /// **'Report data protection violations (unauthorized use of your data) to Andmekaitse Inspektsioon'**
  String get rightDataProtection;

  /// No description provided for @rightDefamationAction.
  ///
  /// In en, this message translates to:
  /// **'Defamation (laimamine) is a civil offense — you can sue for damages and demand a public retraction (KarS § 247 (repealed), VÕS § 1047)'**
  String get rightDefamationAction;

  /// No description provided for @mustCollectEvidence.
  ///
  /// In en, this message translates to:
  /// **'Collect and preserve all evidence — screenshots, links, dates, and witness information'**
  String get mustCollectEvidence;

  /// No description provided for @mustNotRetaliate.
  ///
  /// In en, this message translates to:
  /// **'Do not retaliate or engage in counter-harassment — it may weaken your case'**
  String get mustNotRetaliate;

  /// No description provided for @cyberActionScreenshots.
  ///
  /// In en, this message translates to:
  /// **'Take screenshots of all harassment — save URLs, dates, usernames, and content'**
  String get cyberActionScreenshots;

  /// No description provided for @cyberActionReportPolice.
  ///
  /// In en, this message translates to:
  /// **'File a police report at the nearest station or online at politsei.ee'**
  String get cyberActionReportPolice;

  /// No description provided for @cyberActionReportPlatform.
  ///
  /// In en, this message translates to:
  /// **'Report the content to the social media platform for removal'**
  String get cyberActionReportPlatform;

  /// No description provided for @cyberActionContactDPA.
  ///
  /// In en, this message translates to:
  /// **'Contact Andmekaitse Inspektsioon if your personal data was misused'**
  String get cyberActionContactDPA;

  /// No description provided for @cyberActionConsultLawyer.
  ///
  /// In en, this message translates to:
  /// **'Consult a lawyer about civil damages — free legal aid is available through Riigi Õigusabi'**
  String get cyberActionConsultLawyer;

  /// No description provided for @cyberDeadlineCriminal.
  ///
  /// In en, this message translates to:
  /// **'Criminal complaint — no strict deadline, but report promptly for best results'**
  String get cyberDeadlineCriminal;

  /// No description provided for @cyberDeadlineCivil.
  ///
  /// In en, this message translates to:
  /// **'Civil claim for damages — up to 3 years from when you learned of the violation (TsÜS § 150)'**
  String get cyberDeadlineCivil;

  /// No description provided for @cyberFactPrivacy.
  ///
  /// In en, this message translates to:
  /// **'In Estonia, unauthorized sharing of someone\'s intimate images can result in up to 3 years in prison under Karistusseadustik § 157¹ (violation of privacy).'**
  String get cyberFactPrivacy;

  /// No description provided for @cyberFactGDPR.
  ///
  /// In en, this message translates to:
  /// **'Under GDPR, you have the “right to be forgotten” — platforms must delete your personal data upon request if there is no legal basis to keep it.'**
  String get cyberFactGDPR;

  /// No description provided for @guestUser.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guestUser;

  /// No description provided for @howToUse.
  ///
  /// In en, this message translates to:
  /// **'How to use?'**
  String get howToUse;

  /// No description provided for @tutorialStep1Title.
  ///
  /// In en, this message translates to:
  /// **'AI Legal Assistant'**
  String get tutorialStep1Title;

  /// No description provided for @tutorialStep1Desc.
  ///
  /// In en, this message translates to:
  /// **'Ask any legal question and get instant answers based on Estonian law.'**
  String get tutorialStep1Desc;

  /// No description provided for @tutorialStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Know Your Rights'**
  String get tutorialStep2Title;

  /// No description provided for @tutorialStep2Desc.
  ///
  /// In en, this message translates to:
  /// **'Browse legal information by topic — employment, housing, consumer rights and more.'**
  String get tutorialStep2Desc;

  /// No description provided for @tutorialStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Scan Documents'**
  String get tutorialStep3Title;

  /// No description provided for @tutorialStep3Desc.
  ///
  /// In en, this message translates to:
  /// **'Take photos of legal documents for AI analysis and safe storage.'**
  String get tutorialStep3Desc;

  /// No description provided for @tutorialStep4Title.
  ///
  /// In en, this message translates to:
  /// **'Get Started!'**
  String get tutorialStep4Title;

  /// No description provided for @tutorialStep4Desc.
  ///
  /// In en, this message translates to:
  /// **'Explore the app and protect your rights. All data stays private on your device.'**
  String get tutorialStep4Desc;

  /// No description provided for @advocatProTitle.
  ///
  /// In en, this message translates to:
  /// **'Advocat Pro'**
  String get advocatProTitle;

  /// No description provided for @advocatProSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock premium features'**
  String get advocatProSubtitle;

  /// No description provided for @voiceDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Voice assistant currently works only on desktop (Chrome browser). Mobile support coming soon.'**
  String get voiceDisclaimer;

  /// No description provided for @recommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get recommended;

  /// No description provided for @pleaseLogIn.
  ///
  /// In en, this message translates to:
  /// **'Please log in'**
  String get pleaseLogIn;

  /// No description provided for @subscriptionNotFound.
  ///
  /// In en, this message translates to:
  /// **'Subscription not found'**
  String get subscriptionNotFound;

  /// No description provided for @errorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorWithMessage(String message);

  /// No description provided for @redirectingToPayment.
  ///
  /// In en, this message translates to:
  /// **'Redirecting to payment page…'**
  String get redirectingToPayment;

  /// No description provided for @cheaperAnnually.
  ///
  /// In en, this message translates to:
  /// **'€{amount}/mo cheaper annually'**
  String cheaperAnnually(String amount);

  /// No description provided for @navigatingTo.
  ///
  /// In en, this message translates to:
  /// **'Opening'**
  String get navigatingTo;

  /// No description provided for @stayInChat.
  ///
  /// In en, this message translates to:
  /// **'Stay in chat'**
  String get stayInChat;

  /// No description provided for @backToChat.
  ///
  /// In en, this message translates to:
  /// **'Back to chat'**
  String get backToChat;

  /// No description provided for @upgradeBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Upgrade for unlimited consultations'**
  String get upgradeBannerTitle;

  /// No description provided for @upgradeBannerCta.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgradeBannerCta;

  /// No description provided for @paymentSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment successful'**
  String get paymentSuccessTitle;

  /// No description provided for @paymentSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'Your subscription is now active.'**
  String get paymentSuccessBody;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @feedbackThumbsUpLabel.
  ///
  /// In en, this message translates to:
  /// **'Helpful'**
  String get feedbackThumbsUpLabel;

  /// No description provided for @feedbackThumbsDownLabel.
  ///
  /// In en, this message translates to:
  /// **'Not helpful'**
  String get feedbackThumbsDownLabel;

  /// No description provided for @feedbackCommentPrompt.
  ///
  /// In en, this message translates to:
  /// **'What was wrong?'**
  String get feedbackCommentPrompt;

  /// No description provided for @feedbackSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get feedbackSend;

  /// No description provided for @feedbackCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get feedbackCancel;

  /// No description provided for @reasoningPillIdle.
  ///
  /// In en, this message translates to:
  /// **'Thinking…'**
  String get reasoningPillIdle;

  /// No description provided for @reasoningPillSearchingLaw.
  ///
  /// In en, this message translates to:
  /// **'Searching Estonian law…'**
  String get reasoningPillSearchingLaw;

  /// No description provided for @reasoningPillSearchingWeb.
  ///
  /// In en, this message translates to:
  /// **'Searching the web…'**
  String get reasoningPillSearchingWeb;

  /// No description provided for @reasoningPillCheckingCompany.
  ///
  /// In en, this message translates to:
  /// **'Checking company registry…'**
  String get reasoningPillCheckingCompany;

  /// No description provided for @reasoningPillCheckingVehicle.
  ///
  /// In en, this message translates to:
  /// **'Checking vehicle registry…'**
  String get reasoningPillCheckingVehicle;

  /// No description provided for @reasoningPillReadingDocument.
  ///
  /// In en, this message translates to:
  /// **'Reading your document…'**
  String get reasoningPillReadingDocument;

  /// No description provided for @reasoningPillDrafting.
  ///
  /// In en, this message translates to:
  /// **'Drafting the document…'**
  String get reasoningPillDrafting;

  /// No description provided for @reasoningPillPreparingEmail.
  ///
  /// In en, this message translates to:
  /// **'Preparing email…'**
  String get reasoningPillPreparingEmail;

  /// No description provided for @reasoningPillFindingLawyer.
  ///
  /// In en, this message translates to:
  /// **'Looking up lawyers…'**
  String get reasoningPillFindingLawyer;

  /// No description provided for @reasoningPillThinking.
  ///
  /// In en, this message translates to:
  /// **'Reasoning through your case…'**
  String get reasoningPillThinking;

  /// No description provided for @reasoningPillFinalising.
  ///
  /// In en, this message translates to:
  /// **'Composing your answer…'**
  String get reasoningPillFinalising;

  /// No description provided for @reasoningCollapsedFormat.
  ///
  /// In en, this message translates to:
  /// **'Reasoned for {sec}s · {sources} sources'**
  String reasoningCollapsedFormat(int sec, int sources);

  /// No description provided for @reasoningExpandHint.
  ///
  /// In en, this message translates to:
  /// **'tap to see steps'**
  String get reasoningExpandHint;

  /// No description provided for @caseFileTitle.
  ///
  /// In en, this message translates to:
  /// **'Case File'**
  String get caseFileTitle;

  /// No description provided for @caseFileTimeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get caseFileTimeline;

  /// No description provided for @caseFileParties.
  ///
  /// In en, this message translates to:
  /// **'Parties'**
  String get caseFileParties;

  /// No description provided for @caseFileDeadlines.
  ///
  /// In en, this message translates to:
  /// **'Deadlines'**
  String get caseFileDeadlines;

  /// No description provided for @caseFileExportPdf.
  ///
  /// In en, this message translates to:
  /// **'Download dossier (PDF)'**
  String get caseFileExportPdf;

  /// No description provided for @caseFileEmpty.
  ///
  /// In en, this message translates to:
  /// **'Chat with the AI about your case — your timeline will build itself.'**
  String get caseFileEmpty;

  /// No description provided for @caseFileDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This dossier is auto-extracted from your chat. It is not legal advice.'**
  String get caseFileDisclaimer;

  /// No description provided for @caseFileTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Case'**
  String get caseFileTabLabel;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @demoLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Demo limit reached. Sign up for free to continue.'**
  String get demoLimitReached;

  /// No description provided for @demoLimitSignUpCta.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get demoLimitSignUpCta;

  /// No description provided for @freeQuotaExhausted.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used all 7 free messages this month.'**
  String get freeQuotaExhausted;

  /// No description provided for @upgradeForUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro for unlimited'**
  String get upgradeForUnlimited;

  /// No description provided for @upgradeCta.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgradeCta;

  /// No description provided for @rateLimitTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Sending too fast. Try again in a few seconds.'**
  String get rateLimitTryAgain;

  /// No description provided for @quickProfilePrompt.
  ///
  /// In en, this message translates to:
  /// **'So I can help more precisely, what is your legal status: are you an Estonian citizen, an EU citizen from another country, or do you have a residence permit?'**
  String get quickProfilePrompt;

  /// No description provided for @quickProfileChipEstonianCitizen.
  ///
  /// In en, this message translates to:
  /// **'Estonian citizen'**
  String get quickProfileChipEstonianCitizen;

  /// No description provided for @quickProfileChipEuCitizen.
  ///
  /// In en, this message translates to:
  /// **'EU citizen (other)'**
  String get quickProfileChipEuCitizen;

  /// No description provided for @quickProfileChipResidencePermit.
  ///
  /// In en, this message translates to:
  /// **'Residence permit'**
  String get quickProfileChipResidencePermit;

  /// No description provided for @quickProfileSkipBtn.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get quickProfileSkipBtn;

  /// No description provided for @quickProfileSavedAck.
  ///
  /// In en, this message translates to:
  /// **'Got it. Now, what\'s your question?'**
  String get quickProfileSavedAck;

  /// No description provided for @caseTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Case title'**
  String get caseTitleLabel;

  /// No description provided for @jurisdictionLabel.
  ///
  /// In en, this message translates to:
  /// **'Jurisdiction'**
  String get jurisdictionLabel;

  /// No description provided for @caseTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Case type'**
  String get caseTypeLabel;

  /// No description provided for @caseLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get caseLanguageLabel;

  /// No description provided for @caseNumbersSection.
  ///
  /// In en, this message translates to:
  /// **'Case numbers'**
  String get caseNumbersSection;

  /// No description provided for @partiesSection.
  ///
  /// In en, this message translates to:
  /// **'Parties'**
  String get partiesSection;

  /// No description provided for @authoritiesSection.
  ///
  /// In en, this message translates to:
  /// **'Authorities'**
  String get authoritiesSection;

  /// No description provided for @timelineSection.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timelineSection;

  /// No description provided for @openQuestionsSection.
  ///
  /// In en, this message translates to:
  /// **'Open questions'**
  String get openQuestionsSection;

  /// No description provided for @nextActionsSection.
  ///
  /// In en, this message translates to:
  /// **'Next actions'**
  String get nextActionsSection;

  /// No description provided for @summarySection.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summarySection;

  /// No description provided for @addRow.
  ///
  /// In en, this message translates to:
  /// **'Add row'**
  String get addRow;

  /// No description provided for @removeRow.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeRow;

  /// No description provided for @archiveCase.
  ///
  /// In en, this message translates to:
  /// **'Archive case'**
  String get archiveCase;

  /// No description provided for @closeCase.
  ///
  /// In en, this message translates to:
  /// **'Close case'**
  String get closeCase;

  /// No description provided for @continueChatAboutCase.
  ///
  /// In en, this message translates to:
  /// **'Continue chat about this case'**
  String get continueChatAboutCase;

  /// No description provided for @linkChatToCase.
  ///
  /// In en, this message translates to:
  /// **'Link to case'**
  String get linkChatToCase;

  /// No description provided for @clearActiveCase.
  ///
  /// In en, this message translates to:
  /// **'Clear active case'**
  String get clearActiveCase;

  /// No description provided for @caseSavedAck.
  ///
  /// In en, this message translates to:
  /// **'Case saved'**
  String get caseSavedAck;

  /// No description provided for @caseArchivedAck.
  ///
  /// In en, this message translates to:
  /// **'Case archived'**
  String get caseArchivedAck;

  /// No description provided for @intakeStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Where is the case?'**
  String get intakeStep1Title;

  /// No description provided for @intakeStep1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Country and authority you are dealing with.'**
  String get intakeStep1Subtitle;

  /// No description provided for @intakeJurisdictionLabel.
  ///
  /// In en, this message translates to:
  /// **'Country / jurisdiction'**
  String get intakeJurisdictionLabel;

  /// No description provided for @intakeAuthorityLabel.
  ///
  /// In en, this message translates to:
  /// **'Authority type'**
  String get intakeAuthorityLabel;

  /// No description provided for @intakeAuthorityNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Authority name (optional)'**
  String get intakeAuthorityNameLabel;

  /// No description provided for @intakeAuthorityPolice.
  ///
  /// In en, this message translates to:
  /// **'Police'**
  String get intakeAuthorityPolice;

  /// No description provided for @intakeAuthorityCourt.
  ///
  /// In en, this message translates to:
  /// **'Court'**
  String get intakeAuthorityCourt;

  /// No description provided for @intakeAuthoritySocial.
  ///
  /// In en, this message translates to:
  /// **'Social services'**
  String get intakeAuthoritySocial;

  /// No description provided for @intakeAuthorityEmployer.
  ///
  /// In en, this message translates to:
  /// **'Employer'**
  String get intakeAuthorityEmployer;

  /// No description provided for @intakeAuthorityLandlord.
  ///
  /// In en, this message translates to:
  /// **'Landlord'**
  String get intakeAuthorityLandlord;

  /// No description provided for @intakeAuthorityOpposingParty.
  ///
  /// In en, this message translates to:
  /// **'Opposing party'**
  String get intakeAuthorityOpposingParty;

  /// No description provided for @intakeAuthorityOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get intakeAuthorityOther;

  /// No description provided for @intakeStep2Title.
  ///
  /// In en, this message translates to:
  /// **'What kind of case?'**
  String get intakeStep2Title;

  /// No description provided for @intakeStep2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick the closest type — you can refine later.'**
  String get intakeStep2Subtitle;

  /// No description provided for @intakeCaseTypeCriminal.
  ///
  /// In en, this message translates to:
  /// **'Criminal'**
  String get intakeCaseTypeCriminal;

  /// No description provided for @intakeCaseTypeCivil.
  ///
  /// In en, this message translates to:
  /// **'Civil'**
  String get intakeCaseTypeCivil;

  /// No description provided for @intakeCaseTypeFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get intakeCaseTypeFamily;

  /// No description provided for @intakeCaseTypeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Administrative'**
  String get intakeCaseTypeAdmin;

  /// No description provided for @intakeCaseTypeImmigration.
  ///
  /// In en, this message translates to:
  /// **'Immigration'**
  String get intakeCaseTypeImmigration;

  /// No description provided for @intakeCaseTypeLabor.
  ///
  /// In en, this message translates to:
  /// **'Labor'**
  String get intakeCaseTypeLabor;

  /// No description provided for @intakeCaseTypeConsumer.
  ///
  /// In en, this message translates to:
  /// **'Consumer'**
  String get intakeCaseTypeConsumer;

  /// No description provided for @intakeCaseTypeInheritance.
  ///
  /// In en, this message translates to:
  /// **'Inheritance'**
  String get intakeCaseTypeInheritance;

  /// No description provided for @intakeCaseTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get intakeCaseTypeOther;

  /// No description provided for @intakeStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Who is involved?'**
  String get intakeStep3Title;

  /// No description provided for @intakeStep3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Your role and the other side.'**
  String get intakeStep3Subtitle;

  /// No description provided for @intakeRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Your role'**
  String get intakeRoleLabel;

  /// No description provided for @intakeRolePlaintiff.
  ///
  /// In en, this message translates to:
  /// **'Plaintiff'**
  String get intakeRolePlaintiff;

  /// No description provided for @intakeRoleDefendant.
  ///
  /// In en, this message translates to:
  /// **'Defendant'**
  String get intakeRoleDefendant;

  /// No description provided for @intakeRoleVictim.
  ///
  /// In en, this message translates to:
  /// **'Victim'**
  String get intakeRoleVictim;

  /// No description provided for @intakeRoleAccused.
  ///
  /// In en, this message translates to:
  /// **'Accused'**
  String get intakeRoleAccused;

  /// No description provided for @intakeRoleWitness.
  ///
  /// In en, this message translates to:
  /// **'Witness'**
  String get intakeRoleWitness;

  /// No description provided for @intakeRoleFamily.
  ///
  /// In en, this message translates to:
  /// **'Family member'**
  String get intakeRoleFamily;

  /// No description provided for @intakeRoleOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get intakeRoleOther;

  /// No description provided for @intakeOpposingSideLabel.
  ///
  /// In en, this message translates to:
  /// **'Opposing side (optional)'**
  String get intakeOpposingSideLabel;

  /// No description provided for @intakeWitnessesLabel.
  ///
  /// In en, this message translates to:
  /// **'Witnesses (optional)'**
  String get intakeWitnessesLabel;

  /// No description provided for @intakeAddWitness.
  ///
  /// In en, this message translates to:
  /// **'Add witness'**
  String get intakeAddWitness;

  /// No description provided for @intakeWitnessHint.
  ///
  /// In en, this message translates to:
  /// **'Name or contact'**
  String get intakeWitnessHint;

  /// No description provided for @intakeStep4Title.
  ///
  /// In en, this message translates to:
  /// **'Numbers & dates'**
  String get intakeStep4Title;

  /// No description provided for @intakeStep4Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Whatever you already have. Skip what you don\'t.'**
  String get intakeStep4Subtitle;

  /// No description provided for @intakeCaseNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Case number (optional)'**
  String get intakeCaseNumberLabel;

  /// No description provided for @intakeIncidentDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Incident date (optional)'**
  String get intakeIncidentDateLabel;

  /// No description provided for @intakeIncidentDatePick.
  ///
  /// In en, this message translates to:
  /// **'Pick date'**
  String get intakeIncidentDatePick;

  /// No description provided for @intakeDeadlinesLabel.
  ///
  /// In en, this message translates to:
  /// **'Known deadlines'**
  String get intakeDeadlinesLabel;

  /// No description provided for @intakeAddDeadline.
  ///
  /// In en, this message translates to:
  /// **'Add deadline'**
  String get intakeAddDeadline;

  /// No description provided for @intakeDeadlineWhatHint.
  ///
  /// In en, this message translates to:
  /// **'What'**
  String get intakeDeadlineWhatHint;

  /// No description provided for @intakeStep5Title.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get intakeStep5Title;

  /// No description provided for @intakeStep5Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload anything relevant. We will read it.'**
  String get intakeStep5Subtitle;

  /// No description provided for @intakeUploadDocsLabel.
  ///
  /// In en, this message translates to:
  /// **'Upload documents'**
  String get intakeUploadDocsLabel;

  /// No description provided for @intakeSkipDocs.
  ///
  /// In en, this message translates to:
  /// **'Skip — I\'ll upload later'**
  String get intakeSkipDocs;

  /// No description provided for @intakeNextBtn.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get intakeNextBtn;

  /// No description provided for @intakeBackBtn.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get intakeBackBtn;

  /// No description provided for @intakeFinishBtn.
  ///
  /// In en, this message translates to:
  /// **'Finish & open chat'**
  String get intakeFinishBtn;

  /// No description provided for @intakeUrgentBtn.
  ///
  /// In en, this message translates to:
  /// **'Urgent — ask now'**
  String get intakeUrgentBtn;

  /// No description provided for @intakeUrgentDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Open chat now?'**
  String get intakeUrgentDialogTitle;

  /// No description provided for @intakeUrgentDialogBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ll save what you\'ve entered as a draft case. You can finish the wizard from the case page anytime.'**
  String get intakeUrgentDialogBody;

  /// No description provided for @intakeUrgentConfirm.
  ///
  /// In en, this message translates to:
  /// **'Open chat'**
  String get intakeUrgentConfirm;

  /// No description provided for @intakeUrgentCancel.
  ///
  /// In en, this message translates to:
  /// **'Keep filling'**
  String get intakeUrgentCancel;

  /// No description provided for @intakePreparingCase.
  ///
  /// In en, this message translates to:
  /// **'Preparing your case…'**
  String get intakePreparingCase;

  /// No description provided for @intakeFallbackGreeting.
  ///
  /// In en, this message translates to:
  /// **'I see your case. Tell me what\'s most pressing — I\'ll work through it with you.'**
  String get intakeFallbackGreeting;

  /// No description provided for @intakeUrgentGreeting.
  ///
  /// In en, this message translates to:
  /// **'I see this is urgent. Ask your question — I\'ll fill in the rest as we go.'**
  String get intakeUrgentGreeting;

  /// No description provided for @intakeStepIndicator.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String intakeStepIndicator(int current, int total);

  /// No description provided for @intakeFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get intakeFieldRequired;

  /// No description provided for @intakeUploadProgress.
  ///
  /// In en, this message translates to:
  /// **'Uploading {done} / {total}…'**
  String intakeUploadProgress(int done, int total);

  /// No description provided for @uplDisclaimerFooter.
  ///
  /// In en, this message translates to:
  /// **'Advocat is not a law firm. This is information, not legal advice.'**
  String get uplDisclaimerFooter;

  /// No description provided for @citationStatusVerifiedBadge.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get citationStatusVerifiedBadge;

  /// No description provided for @citationStatusUnverifiedBadge.
  ///
  /// In en, this message translates to:
  /// **'Unverified'**
  String get citationStatusUnverifiedBadge;

  /// No description provided for @citationStatusHistoricalBadge.
  ///
  /// In en, this message translates to:
  /// **'Historical version'**
  String get citationStatusHistoricalBadge;

  /// No description provided for @citationStatusVerifiedTooltip.
  ///
  /// In en, this message translates to:
  /// **'Cited from a retrieved law source.'**
  String get citationStatusVerifiedTooltip;

  /// No description provided for @citationStatusUnverifiedTooltip.
  ///
  /// In en, this message translates to:
  /// **'AI quoted this without retrieval — verify before relying.'**
  String get citationStatusUnverifiedTooltip;

  /// No description provided for @citationStatusHistoricalTooltip.
  ///
  /// In en, this message translates to:
  /// **'Cited section is no longer in force.'**
  String get citationStatusHistoricalTooltip;

  /// No description provided for @citationOpenInRiigiTeataja.
  ///
  /// In en, this message translates to:
  /// **'Open in Riigi Teataja'**
  String get citationOpenInRiigiTeataja;

  /// No description provided for @citationSnippetExpand.
  ///
  /// In en, this message translates to:
  /// **'Show full text'**
  String get citationSnippetExpand;

  /// No description provided for @citationSnippetCollapse.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get citationSnippetCollapse;

  /// No description provided for @citationUnverifiedSheetNote.
  ///
  /// In en, this message translates to:
  /// **'AI cited this paragraph but it was not retrieved from the law corpus this turn. Verify the reference before relying on it.'**
  String get citationUnverifiedSheetNote;

  /// No description provided for @citationFooterNoneWarning.
  ///
  /// In en, this message translates to:
  /// **'No grounded citations'**
  String get citationFooterNoneWarning;

  /// No description provided for @citationFooterSummaryTotal.
  ///
  /// In en, this message translates to:
  /// **'{count} citations'**
  String citationFooterSummaryTotal(int count);

  /// No description provided for @citationFooterSummaryVerified.
  ///
  /// In en, this message translates to:
  /// **'{count} verified'**
  String citationFooterSummaryVerified(int count);

  /// No description provided for @citationFooterSummaryUnverified.
  ///
  /// In en, this message translates to:
  /// **'{count} unverified'**
  String citationFooterSummaryUnverified(int count);

  /// No description provided for @citationFooterSummaryHistorical.
  ///
  /// In en, this message translates to:
  /// **'{count} historical'**
  String citationFooterSummaryHistorical(int count);

  /// No description provided for @deadlineRadarTitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming deadlines'**
  String get deadlineRadarTitle;

  /// No description provided for @deadlineRadarEmpty.
  ///
  /// In en, this message translates to:
  /// **'No upcoming deadlines'**
  String get deadlineRadarEmpty;

  /// No description provided for @deadlineRadarViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get deadlineRadarViewAll;

  /// No description provided for @deadlineCardDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'in {count} days'**
  String deadlineCardDaysLeft(int count);

  /// No description provided for @deadlineCardTomorrow.
  ///
  /// In en, this message translates to:
  /// **'tomorrow'**
  String get deadlineCardTomorrow;

  /// No description provided for @deadlineCardToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get deadlineCardToday;

  /// No description provided for @deadlineCardOverdue.
  ///
  /// In en, this message translates to:
  /// **'{count} days overdue'**
  String deadlineCardOverdue(int count);

  /// No description provided for @deadlineCardMarkComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark complete'**
  String get deadlineCardMarkComplete;

  /// No description provided for @deadlineCardSnooze.
  ///
  /// In en, this message translates to:
  /// **'Snooze'**
  String get deadlineCardSnooze;

  /// No description provided for @deadlineCardSnooze3d.
  ///
  /// In en, this message translates to:
  /// **'Snooze 3 days'**
  String get deadlineCardSnooze3d;

  /// No description provided for @deadlineCardSnooze7d.
  ///
  /// In en, this message translates to:
  /// **'Snooze 7 days'**
  String get deadlineCardSnooze7d;

  /// No description provided for @deadlineCardSnoozeCustom.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get deadlineCardSnoozeCustom;

  /// No description provided for @deadlineCardEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get deadlineCardEdit;

  /// No description provided for @deadlineCardDelete.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get deadlineCardDelete;

  /// No description provided for @deadlineCardSourceLabelPdf.
  ///
  /// In en, this message translates to:
  /// **'from PDF'**
  String get deadlineCardSourceLabelPdf;

  /// No description provided for @deadlineCardSourceLabelIntake.
  ///
  /// In en, this message translates to:
  /// **'from intake'**
  String get deadlineCardSourceLabelIntake;

  /// No description provided for @deadlineCardSourceLabelManual.
  ///
  /// In en, this message translates to:
  /// **'added manually'**
  String get deadlineCardSourceLabelManual;

  /// No description provided for @deadlineCardSourceLabelEmail.
  ///
  /// In en, this message translates to:
  /// **'from email'**
  String get deadlineCardSourceLabelEmail;

  /// No description provided for @deadlineCardSourceLabelHaikuExtract.
  ///
  /// In en, this message translates to:
  /// **'AI-extracted'**
  String get deadlineCardSourceLabelHaikuExtract;

  /// No description provided for @deadlineCardSourceLabelStatutoryTemplate.
  ///
  /// In en, this message translates to:
  /// **'statute template'**
  String get deadlineCardSourceLabelStatutoryTemplate;

  /// No description provided for @deadlineBannerCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical deadline {title} {when}'**
  String deadlineBannerCritical(String title, String when);

  /// No description provided for @deadlineBannerDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get deadlineBannerDismiss;

  /// No description provided for @deadlineBannerOpen.
  ///
  /// In en, this message translates to:
  /// **'Open deadline'**
  String get deadlineBannerOpen;

  /// No description provided for @deadlineHolidayShifted.
  ///
  /// In en, this message translates to:
  /// **'Shifted from {original} due to {reason}'**
  String deadlineHolidayShifted(String original, String reason);

  /// No description provided for @deadlinePermissionAskTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable deadline reminders?'**
  String get deadlinePermissionAskTitle;

  /// No description provided for @deadlinePermissionAskBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ll ping you 7, 3, and 1 day before each statutory deadline, plus the morning of. Never used for marketing.'**
  String get deadlinePermissionAskBody;

  /// No description provided for @deadlinePermissionAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get deadlinePermissionAllow;

  /// No description provided for @deadlinePermissionLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get deadlinePermissionLater;

  /// No description provided for @deadlineSettingsSection.
  ///
  /// In en, this message translates to:
  /// **'Deadline reminders'**
  String get deadlineSettingsSection;

  /// No description provided for @deadlineSettingsPushChannel.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get deadlineSettingsPushChannel;

  /// No description provided for @deadlineSettingsEmailChannel.
  ///
  /// In en, this message translates to:
  /// **'Email (critical only)'**
  String get deadlineSettingsEmailChannel;

  /// No description provided for @deadlineSettingsInAppChannel.
  ///
  /// In en, this message translates to:
  /// **'In-app banners'**
  String get deadlineSettingsInAppChannel;

  /// No description provided for @deadlineSettingsCriticalBypass.
  ///
  /// In en, this message translates to:
  /// **'Critical reminders bypass quiet hours'**
  String get deadlineSettingsCriticalBypass;

  /// No description provided for @deadlineSettingsQuietHours.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours'**
  String get deadlineSettingsQuietHours;

  /// No description provided for @deadlineSettingsQuietHoursBadge.
  ///
  /// In en, this message translates to:
  /// **'Quiet {start}–{end}'**
  String deadlineSettingsQuietHoursBadge(String start, String end);

  /// No description provided for @deadlineCaseScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Case deadlines'**
  String get deadlineCaseScreenTitle;

  /// No description provided for @deadlineAddManualCta.
  ///
  /// In en, this message translates to:
  /// **'Add deadline'**
  String get deadlineAddManualCta;

  /// No description provided for @deadlineFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get deadlineFormTitle;

  /// No description provided for @deadlineFormDescription.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get deadlineFormDescription;

  /// No description provided for @deadlineFormStatuteTemplate.
  ///
  /// In en, this message translates to:
  /// **'Statute template'**
  String get deadlineFormStatuteTemplate;

  /// No description provided for @deadlineFormStatuteTemplateNone.
  ///
  /// In en, this message translates to:
  /// **'None (manual)'**
  String get deadlineFormStatuteTemplateNone;

  /// No description provided for @deadlineFormDeadlineAt.
  ///
  /// In en, this message translates to:
  /// **'Deadline date'**
  String get deadlineFormDeadlineAt;

  /// No description provided for @deadlineFormPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get deadlineFormPriority;

  /// No description provided for @deadlineFormSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get deadlineFormSave;

  /// No description provided for @deadlineFormCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get deadlineFormCancel;

  /// No description provided for @deadlineCompletedNotePrompt.
  ///
  /// In en, this message translates to:
  /// **'Add a note (optional)'**
  String get deadlineCompletedNotePrompt;

  /// No description provided for @deadlineCompletedNoteSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get deadlineCompletedNoteSave;

  /// No description provided for @inboxTitle.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get inboxTitle;

  /// No description provided for @inboxEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing pending'**
  String get inboxEmptyTitle;

  /// No description provided for @inboxEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'New email threads will appear here as they get triaged.'**
  String get inboxEmptyBody;

  /// No description provided for @inboxApproveSend.
  ///
  /// In en, this message translates to:
  /// **'Approve & send'**
  String get inboxApproveSend;

  /// No description provided for @inboxEditDraft.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get inboxEditDraft;

  /// No description provided for @inboxSnooze.
  ///
  /// In en, this message translates to:
  /// **'Snooze'**
  String get inboxSnooze;

  /// No description provided for @inboxArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get inboxArchive;

  /// No description provided for @inboxFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get inboxFilterAll;

  /// No description provided for @inboxConfirmSendTitle.
  ///
  /// In en, this message translates to:
  /// **'Send the prepared reply?'**
  String get inboxConfirmSendTitle;

  /// No description provided for @inboxConfirmSendBody.
  ///
  /// In en, this message translates to:
  /// **'Advocat will dispatch the AI-prepared reply via your connected Gmail. You can still review the body in the next screen.'**
  String get inboxConfirmSendBody;

  /// No description provided for @inboxSendButton.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get inboxSendButton;

  /// No description provided for @inboxSentToast.
  ///
  /// In en, this message translates to:
  /// **'Sent.'**
  String get inboxSentToast;

  /// No description provided for @inboxSnoozedToast.
  ///
  /// In en, this message translates to:
  /// **'Snoozed for 24h.'**
  String get inboxSnoozedToast;

  /// No description provided for @inboxArchivedToast.
  ///
  /// In en, this message translates to:
  /// **'Archived.'**
  String get inboxArchivedToast;

  /// No description provided for @inboxDraftLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load draft.'**
  String get inboxDraftLoadError;

  /// No description provided for @inboxDeadlineToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get inboxDeadlineToday;

  /// No description provided for @inboxDeadlineTomorrow.
  ///
  /// In en, this message translates to:
  /// **'tomorrow'**
  String get inboxDeadlineTomorrow;

  /// No description provided for @inboxDeadlineInDays.
  ///
  /// In en, this message translates to:
  /// **'in {days}d'**
  String inboxDeadlineInDays(int days);

  /// No description provided for @inboxDeadlineOverdue.
  ///
  /// In en, this message translates to:
  /// **'overdue {days}d'**
  String inboxDeadlineOverdue(int days);

  /// No description provided for @workspaceTabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get workspaceTabOverview;

  /// No description provided for @workspaceTabChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get workspaceTabChat;

  /// No description provided for @workspaceTabDrafts.
  ///
  /// In en, this message translates to:
  /// **'Drafts'**
  String get workspaceTabDrafts;

  /// No description provided for @workspaceOverviewEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add documents to build a summary.'**
  String get workspaceOverviewEmpty;

  /// No description provided for @workspaceTimelineEmpty.
  ///
  /// In en, this message translates to:
  /// **'No events yet.'**
  String get workspaceTimelineEmpty;

  /// No description provided for @workspaceDocumentsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No documents. Upload from Scan.'**
  String get workspaceDocumentsEmpty;

  /// No description provided for @workspaceDraftsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No drafts yet.'**
  String get workspaceDraftsEmpty;

  /// No description provided for @workspaceInboxEmpty.
  ///
  /// In en, this message translates to:
  /// **'No related email.'**
  String get workspaceInboxEmpty;

  /// Settings tile title for the planner toggle (Pkg 6).
  ///
  /// In en, this message translates to:
  /// **'Three-pass legal reasoning'**
  String get plannerSettingsTitle;

  /// Settings tile subtitle explaining the planner's three-pass loop.
  ///
  /// In en, this message translates to:
  /// **'Plan → answer → critique. Slower but more thorough.'**
  String get plannerSettingsSubtitle;

  /// Pro tier badge on the planner settings tile.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get plannerSettingsProBadge;

  /// Locked-tile hint shown to free-tier users on the planner toggle.
  ///
  /// In en, this message translates to:
  /// **'Available on Pro plan'**
  String get plannerSettingsProDescription;

  /// Reasoning Trail Plan section header.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get plannerTrailHeaderPlan;

  /// Reasoning Trail Critique section header.
  ///
  /// In en, this message translates to:
  /// **'Critique'**
  String get plannerTrailHeaderCritique;

  /// Reasoning Trail sub-questions list label.
  ///
  /// In en, this message translates to:
  /// **'Sub-questions'**
  String get plannerTrailSubQuestions;

  /// Reasoning Trail counter-arguments list label.
  ///
  /// In en, this message translates to:
  /// **'Counter-arguments'**
  String get plannerTrailCounterArgs;

  /// Reasoning Trail evidence-gaps list label.
  ///
  /// In en, this message translates to:
  /// **'Evidence gaps'**
  String get plannerTrailEvidenceGaps;

  /// Reasoning Trail critique status when the planner flagged a material gap.
  ///
  /// In en, this message translates to:
  /// **'Material gap detected'**
  String get plannerTrailMaterialGapTrue;

  /// Reasoning Trail header badge when the answer was regenerated once.
  ///
  /// In en, this message translates to:
  /// **'Regenerated once'**
  String get plannerTrailRegeneratedBadge;

  /// Reasoning Trail placeholder shown when a list section is empty.
  ///
  /// In en, this message translates to:
  /// **'no items'**
  String get plannerTrailEmpty;
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
        'es',
        'et',
        'fa',
        'fi',
        'fr',
        'it',
        'lt',
        'lv',
        'pl',
        'ro',
        'ru',
        'sv',
        'tr',
        'uk'
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
    case 'es':
      return AppLocalizationsEs();
    case 'et':
      return AppLocalizationsEt();
    case 'fa':
      return AppLocalizationsFa();
    case 'fi':
      return AppLocalizationsFi();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'lt':
      return AppLocalizationsLt();
    case 'lv':
      return AppLocalizationsLv();
    case 'pl':
      return AppLocalizationsPl();
    case 'ro':
      return AppLocalizationsRo();
    case 'ru':
      return AppLocalizationsRu();
    case 'sv':
      return AppLocalizationsSv();
    case 'tr':
      return AppLocalizationsTr();
    case 'uk':
      return AppLocalizationsUk();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
