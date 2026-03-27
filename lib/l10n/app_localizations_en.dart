// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Advocat — Legal Information Tool';

  @override
  String get onboardingTitle1 => 'AI-Powered Legal Information';

  @override
  String get onboardingDesc1 =>
      'Advocat helps you understand your legal situation. AI tools analyze documents, identify potential issues, and prepare draft documents for your review. Not a law firm — a technology tool to support your case.';

  @override
  String get onboardingTitle2 => 'Scan and Analyze Documents';

  @override
  String get onboardingDesc2 =>
      'Photograph any legal document. AI reads it in multiple languages, extracts key details, and checks against EU directives and national laws for potential issues.';

  @override
  String get onboardingTitle3 => 'AI Checks for Potential Issues';

  @override
  String get onboardingDesc3 =>
      'Our AI tools check 40+ types of procedural requirements. AI analysis may identify issues that require attention — such as language of service, procedural steps, and legal deadlines. Always verify with a qualified lawyer.';

  @override
  String get onboardingTitle4 => 'Draft Documents for Your Review';

  @override
  String get onboardingDesc4 =>
      'AI prepares draft appeals, complaints, and letters with legal references for your review. You decide what to submit. Every document should be reviewed by a qualified legal professional before filing.';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get getStarted => 'Get Started';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get signInSubtitle => 'Sign in to access your cases';

  @override
  String get signIn => 'Sign In';

  @override
  String get logIn => 'Log In';

  @override
  String get signUp => 'Create Account';

  @override
  String get createAccount => 'Create Account';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get fullName => 'Full Name';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get orDivider => 'or';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get noAccount => 'Don\'t have an account? ';

  @override
  String get signUpLink => 'Sign Up';

  @override
  String get alreadyHaveAccount => 'Already have an account? ';

  @override
  String get signInLink => 'Log In';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get emailInvalid => 'Please enter a valid email address';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordTooShort => 'Password must be at least 8 characters';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get nameRequired => 'Full name is required';

  @override
  String get termsRequired => 'You must agree to the Terms of Service';

  @override
  String get agreeToTerms => 'I agree to the ';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get andWord => ' and ';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get preferredLanguage => 'Preferred Language';

  @override
  String get langEnglish => 'English';

  @override
  String get langRussian => 'Russian';

  @override
  String get langFinnish => 'Finnish';

  @override
  String get passwordStrengthWeak => 'Weak';

  @override
  String get passwordStrengthMedium => 'Medium';

  @override
  String get passwordStrengthStrong => 'Strong';

  @override
  String get loginFailed => 'Invalid email or password. Please try again.';

  @override
  String get registerFailed => 'Registration failed. Please try again.';

  @override
  String get resetPasswordSent => 'Password reset link sent to your email.';

  @override
  String get resetPasswordFailed =>
      'Failed to send reset link. Please try again.';

  @override
  String get myCases => 'My Cases';

  @override
  String get newCase => 'New Case';

  @override
  String get noCases => 'No cases yet';

  @override
  String get documents => 'Documents';

  @override
  String get timeline => 'Timeline';

  @override
  String get aiAssistant => 'AI Legal Assistant';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get subscription => 'Subscription';

  @override
  String get signOut => 'Sign Out';

  @override
  String get disclaimer =>
      'AI guidance only — not legal advice. Always consult a lawyer.';

  @override
  String get scanDocument => 'Scan Document';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get saveAndAnalyze => 'Save & Analyze';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get error => 'Error';

  @override
  String get loading => 'Loading...';

  @override
  String get home => 'Home';

  @override
  String get cases => 'Cases';

  @override
  String get deadlines => 'Deadlines';

  @override
  String get scan => 'Scan';

  @override
  String goodMorning(String name) {
    return 'Good morning, $name';
  }

  @override
  String goodAfternoon(String name) {
    return 'Good afternoon, $name';
  }

  @override
  String goodEvening(String name) {
    return 'Good evening, $name';
  }

  @override
  String get caseOverview => 'Here is your case overview';

  @override
  String get activeCases => 'Active Cases';

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String urgentDeadline(String title) {
    return 'Urgent: $title';
  }

  @override
  String daysRemaining(int count) {
    return '$count days';
  }

  @override
  String get overdue => 'Overdue';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get completed => 'Completed';

  @override
  String get markComplete => 'Mark complete';

  @override
  String get deportation => 'Deportation';

  @override
  String get criminalCase => 'Criminal Case';

  @override
  String get asylum => 'Asylum';

  @override
  String get residencePermit => 'Residence Permit';

  @override
  String get victimSupport => 'Victim Support';

  @override
  String get familyReunification => 'Family Reunification';

  @override
  String get laborDispute => 'Labor Dispute';

  @override
  String get tenantRights => 'Tenant Rights';

  @override
  String get debtCollection => 'Debt Collection';

  @override
  String get discrimination => 'Discrimination';

  @override
  String get policeMisconduct => 'Police Misconduct';

  @override
  String get socialBenefits => 'Social Benefits';

  @override
  String get other => 'Other';

  @override
  String get caseDetail => 'Case Details';

  @override
  String get aiAnalysis => 'AI Analysis';

  @override
  String get draftAppeal => 'Draft Appeal';

  @override
  String get aiChat => 'AI Chat';

  @override
  String get correspondence => 'Correspondence';

  @override
  String get analyzing => 'Analyzing...';

  @override
  String get readingDocument => 'Reading document...';

  @override
  String get checkingErrors => 'Checking for errors...';

  @override
  String get researchingLaw => 'Researching applicable law...';

  @override
  String issuesFound(int count) {
    return '$count issues found';
  }

  @override
  String get critical => 'Critical';

  @override
  String get important => 'Important';

  @override
  String get informational => 'Informational';

  @override
  String get useInAppeal => 'Use in Appeal';

  @override
  String get addedToAppeal => 'Added to Appeal';

  @override
  String get generateAppeal => 'Generate Appeal';

  @override
  String get exportPdf => 'Export PDF';

  @override
  String get sendViaEmail => 'Send via Email';

  @override
  String get copyText => 'Copy Text';

  @override
  String get editDraft => 'Edit';

  @override
  String get saveDraft => 'Save';

  @override
  String get reviewWarning =>
      'Review carefully before sending. You are responsible for the content.';

  @override
  String get disclaimerFull =>
      'This is an AI assistant, not a lawyer. AI analysis may contain errors. Always verify with a qualified legal professional.';

  @override
  String get askAboutCase => 'Analyze my case';

  @override
  String get whatAreMyOptions => 'What are my options?';

  @override
  String get checkDeadlines => 'Check deadlines';

  @override
  String get typeMessage => 'Type a message...';

  @override
  String get connectEmail => 'Connect Email';

  @override
  String get connectGmail => 'Connect Gmail';

  @override
  String get connectOutlook => 'Connect Outlook';

  @override
  String get emailConnected => 'Email connected';

  @override
  String get syncNow => 'Sync Now';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get emailPrivacyNote =>
      'We only read legal-related emails. Your personal emails stay private.';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get deadlineReminders => 'Deadline Reminders';

  @override
  String get deadlineRemindersDesc => 'Get notified before deadlines';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get exportMyData => 'Export My Data';

  @override
  String get exportDataDesc => 'Download all your case data';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountDesc => 'Permanently remove your account';

  @override
  String get deleteConfirm =>
      'Are you sure? This will permanently delete all your data.';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get rateUs => 'Rate Us';

  @override
  String get contactSupport => 'Contact Support';

  @override
  String get tryDemoMode => 'Try Demo Mode';

  @override
  String get demoModeDesc =>
      'Explore the app with sample data from a real case';

  @override
  String get free => 'Free';

  @override
  String get basic => 'Basic';

  @override
  String get pro => 'Pro';

  @override
  String get emergencyShield => 'Emergency Shield';

  @override
  String get legalFighter => 'Legal Fighter';

  @override
  String get fullDefense => 'Full Defense';

  @override
  String get popular => 'POPULAR';

  @override
  String get currentPlan => 'Current Plan';

  @override
  String get choosePlan => 'Choose Plan';

  @override
  String get saveWithAnnual => 'Save 25% with annual billing';

  @override
  String get restorePurchases => 'Restore Purchases';

  @override
  String get country => 'Country';

  @override
  String get caseDescription => 'Describe your situation';

  @override
  String get caseTitle => 'Case Title';

  @override
  String get referenceNumber => 'Reference Number';

  @override
  String get uploadDocument => 'Upload Document';

  @override
  String get optional => '(optional)';

  @override
  String step(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get createCase => 'Create Case';

  @override
  String get searchCases => 'Search cases...';

  @override
  String get all => 'All';

  @override
  String get active => 'Active';

  @override
  String get closed => 'Closed';

  @override
  String lastActivity(String time) {
    return 'Last activity: $time';
  }

  @override
  String documentsCount(int count) {
    return '$count docs';
  }

  @override
  String get noCasesYet => 'No cases yet';

  @override
  String get startFirstCase => 'Start your first case';

  @override
  String get noDeadlines => 'No deadlines — you\'re all clear!';

  @override
  String get appealFiled => 'Appeal Filed';

  @override
  String get pendingDecision => 'Pending Decision';

  @override
  String get inProgress => 'In Progress';

  @override
  String get won => 'Won';

  @override
  String get lost => 'Lost';

  @override
  String get preferences => 'PREFERENCES';

  @override
  String get notifications => 'NOTIFICATIONS';

  @override
  String get emailIntegration => 'EMAIL INTEGRATION';

  @override
  String get dataAndPrivacy => 'DATA & PRIVACY';

  @override
  String get legalSection => 'LEGAL';

  @override
  String get aboutSection => 'ABOUT';

  @override
  String get appVersion => 'App Version';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get signOutConfirm => 'Are you sure you want to sign out?';

  @override
  String get emailDisconnected => 'Email disconnected';

  @override
  String get syncLegalCorrespondence => 'Sync legal correspondence';

  @override
  String get requestExport => 'Request Export';

  @override
  String get exportDataDialogContent =>
      'We will prepare a download of all your data including cases, documents, and correspondence. You will receive an email when it is ready.';

  @override
  String get deleteAccountDialogContent =>
      'This action is permanent and cannot be undone. All your data, cases, and documents will be permanently deleted.';

  @override
  String get areYouAbsolutelySure => 'Are you absolutely sure?';

  @override
  String get typeDeleteToConfirm =>
      'Type DELETE to confirm permanent account removal.';

  @override
  String get permanentlyDelete => 'Permanently Delete';

  @override
  String get dataExportRequested => 'Data export requested. Check your email.';

  @override
  String get connected => 'Connected';

  @override
  String get caseUpdated => 'Case updated';

  @override
  String get noRecentActivity => 'No recent activity';

  @override
  String get couldNotLoadCases => 'Could not load your cases';

  @override
  String get viewAll => 'View All';
}
