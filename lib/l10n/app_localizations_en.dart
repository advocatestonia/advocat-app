// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get about => 'About';

  @override
  String get aboutSection => 'ABOUT';

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
  String get accidents => 'Accidents';

  @override
  String get active => 'Active';

  @override
  String get activeCases => 'Active Cases';

  @override
  String get addedToAppeal => 'Added to Appeal';

  @override
  String get agreeToTerms => 'I agree to the ';

  @override
  String get aiAnalysis => 'AI Analysis';

  @override
  String get aiAssistant => 'AI Legal Assistant';

  @override
  String get aiChat => 'AI Chat';

  @override
  String get all => 'All';

  @override
  String get alreadyHaveAccount => 'Already have an account? ';

  @override
  String get analyzing => 'Analyzing…';

  @override
  String get aiAnalyzing => 'AI is analyzing';

  @override
  String get speakIntoMicHint =>
      'Speak into the microphone. Make sure microphone access is enabled.';

  @override
  String get aiErrorRateLimit =>
      'The service is temporarily overloaded. Please try again in 1-2 minutes.';

  @override
  String get aiErrorOverload =>
      'The AI is busy right now, please try again in a minute.';

  @override
  String freeLimitReached(int count) {
    return 'You have used all $count free AI messages. Upgrade to Legal Counsel for unlimited AI assistance!';
  }

  @override
  String get andWord => ' and ';

  @override
  String get appTitle => 'Advocat — Legal Information Tool';

  @override
  String get appVersion => 'App Version';

  @override
  String get appealFiled => 'Appeal Filed';

  @override
  String get areYouAbsolutelySure => 'Are you absolutely sure?';

  @override
  String get askAboutCase => 'Analyze my case';

  @override
  String get asylum => 'Asylum';

  @override
  String get back => 'Back';

  @override
  String get basic => 'Basic';

  @override
  String get beforeYouBuy => 'Before you buy';

  @override
  String get beforeYouWork => 'Before you work with them';

  @override
  String get camera => 'Camera';

  @override
  String get cancel => 'Cancel';

  @override
  String get caseDescription => 'Describe your situation';

  @override
  String get caseDetail => 'Case Details';

  @override
  String get caseOverview => 'Here is your case overview';

  @override
  String get caseTitle => 'Case Title';

  @override
  String get caseUpdated => 'Case updated';

  @override
  String get cases => 'Cases';

  @override
  String get checkCompany => 'Check Company';

  @override
  String get checkDeadlines => 'Check deadlines';

  @override
  String get checkVehicle => 'Check Vehicle';

  @override
  String get checkerTitle => 'Checker';

  @override
  String get checkingErrors => 'Checking for errors…';

  @override
  String get choosePlan => 'Choose Plan';

  @override
  String get closed => 'Closed';

  @override
  String get companyName => 'Company name or reg. number';

  @override
  String get completed => 'Completed';

  @override
  String get confirm => 'Confirm';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get connectEmail => 'Connect Email';

  @override
  String get connectGmail => 'Connect Gmail';

  @override
  String get connectOutlook => 'Connect Outlook';

  @override
  String get connected => 'Connected';

  @override
  String get contactSupport => 'Contact Support';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get appleComingSoon => 'Coming soon';

  @override
  String get appleComingSoonMessage =>
      'Apple Sign-In becomes available soon. Use Google or email to continue.';

  @override
  String get copyText => 'Copy Text';

  @override
  String get correspondence => 'Correspondence';

  @override
  String get couldNotLoadCases => 'Could not load your cases';

  @override
  String get country => 'Country';

  @override
  String get createAccount => 'Create Account';

  @override
  String get createCase => 'Create Case';

  @override
  String get criminalCase => 'Criminal Case';

  @override
  String get critical => 'Critical';

  @override
  String get currentPlan => 'Current Plan';

  @override
  String get dataAndPrivacy => 'DATA & PRIVACY';

  @override
  String get dataExportRequested => 'Data export requested. Check your email.';

  @override
  String daysRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
      zero: 'no days remaining',
    );
    return '$_temp0';
  }

  @override
  String get deadlineReminders => 'Deadline Reminders';

  @override
  String get deadlineRemindersDesc => 'Get notified before deadlines';

  @override
  String get deadlines => 'Deadlines';

  @override
  String get debtCollection => 'Debt Collection';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountDesc => 'Permanently remove your account';

  @override
  String get deleteAccountDialogContent =>
      'This action is permanent and cannot be undone. All your data, cases, and documents will be permanently deleted.';

  @override
  String get deleteConfirm =>
      'Are you sure? This will permanently delete all your data.';

  @override
  String get demoHint => 'Demo: try plate \"908FBT\"';

  @override
  String get demoModeDesc =>
      'Explore the app with sample data from a real case';

  @override
  String get deportation => 'Deportation';

  @override
  String get disclaimer =>
      'AI guidance only — not legal advice. Always consult a lawyer.';

  @override
  String get disclaimerFull =>
      'This is an AI assistant, not a lawyer. AI analysis may contain errors. Always verify with a qualified legal professional.';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get discrimination => 'Discrimination';

  @override
  String get doNotBuy => 'Do not buy';

  @override
  String get documents => 'Documents';

  @override
  String documentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documents',
      one: '1 document',
      zero: 'no documents',
    );
    return '$_temp0';
  }

  @override
  String get draftAppeal => 'Draft Appeal';

  @override
  String get editDraft => 'Edit';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get email => 'Email';

  @override
  String get emailConnected => 'Email connected';

  @override
  String get emailDisconnected => 'Email disconnected';

  @override
  String get emailIntegration => 'EMAIL INTEGRATION';

  @override
  String get emailInvalid => 'Please enter a valid email address';

  @override
  String get emailPrivacyNote =>
      'We only read legal-related emails. Your personal emails stay private.';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get emergencyShield => 'Basic Protection';

  @override
  String get error => 'Error';

  @override
  String get exportDataDesc => 'Download all your case data';

  @override
  String get exportDataDialogContent =>
      'We will prepare a download of all your data including cases, documents, and correspondence. You will receive an email when it is ready.';

  @override
  String get exportMyData => 'Export My Data';

  @override
  String get exportPdf => 'Export PDF';

  @override
  String get familyReunification => 'Family Reunification';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get free => 'Free';

  @override
  String get fullDefense => 'Advocat Pro';

  @override
  String get fullName => 'Full Name';

  @override
  String get gallery => 'Gallery';

  @override
  String get generateAppeal => 'Generate Appeal';

  @override
  String get getStarted => 'Get Started';

  @override
  String goodAfternoon(String name) {
    return 'Good afternoon, $name';
  }

  @override
  String goodEvening(String name) {
    return 'Good evening, $name';
  }

  @override
  String goodMorning(String name) {
    return 'Good morning, $name';
  }

  @override
  String goodNight(String name) {
    return 'Good night, $name';
  }

  @override
  String get home => 'Home';

  @override
  String get important => 'Important';

  @override
  String get inProgress => 'In Progress';

  @override
  String get informational => 'Informational';

  @override
  String get inspection => 'Technical inspection';

  @override
  String get insurance => 'Insurance';

  @override
  String issuesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count issues found',
      one: '1 issue found',
      zero: 'no issues found',
    );
    return '$_temp0';
  }

  @override
  String get laborDispute => 'Labor Dispute';

  @override
  String get langEnglish => 'English';

  @override
  String get langFinnish => 'Finnish';

  @override
  String get langRussian => 'Russian';

  @override
  String get language => 'Language';

  @override
  String lastActivity(String time) {
    return 'Last activity: $time';
  }

  @override
  String get legalFighter => 'Legal Counsel';

  @override
  String get legalSection => 'LEGAL';

  @override
  String get licensePlate => 'License plate';

  @override
  String get loading => 'Loading…';

  @override
  String get logIn => 'Log In';

  @override
  String get loginFailed => 'Invalid email or password. Please try again.';

  @override
  String get lost => 'Lost';

  @override
  String get markComplete => 'Mark complete';

  @override
  String get mileage => 'Mileage';

  @override
  String get myCases => 'My Cases';

  @override
  String get nameRequired => 'Full name is required';

  @override
  String get newCase => 'New Case';

  @override
  String get next => 'Next';

  @override
  String get noAccount => 'Don’t have an account? ';

  @override
  String get noCases => 'No cases yet';

  @override
  String get noCasesYet => 'No cases yet';

  @override
  String get noDeadlines => 'No deadlines — you’re all clear.';

  @override
  String get noRecentActivity => 'No recent activity';

  @override
  String get notifications => 'NOTIFICATIONS';

  @override
  String get onboardingDesc1 =>
      'Advocat helps you understand your legal situation. AI tools analyze documents, identify potential issues, and prepare draft documents for your review. Not a law firm — a technology tool to support your case.';

  @override
  String get onboardingDesc2 =>
      'Photograph any legal document. AI reads it in multiple languages, extracts key details, and checks against EU directives and national laws for potential issues.';

  @override
  String get onboardingDesc3 =>
      'Our AI tools check 40+ types of procedural requirements. AI analysis may identify issues that require attention — such as language of service, procedural steps, and legal deadlines. Always verify with a qualified lawyer.';

  @override
  String get onboardingDesc4 =>
      'AI prepares draft appeals, complaints, and letters with legal references for your review. You decide what to submit. Every document should be reviewed by a qualified legal professional before filing.';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingTitle1 => 'AI-Powered Legal Information';

  @override
  String get onboardingTitle2 => 'Scan and Analyze Documents';

  @override
  String get onboardingTitle3 => 'AI Checks for Potential Issues';

  @override
  String get onboardingTitle4 => 'Draft Documents for Your Review';

  @override
  String get openACase => 'Open a Case';

  @override
  String get optional => '(optional)';

  @override
  String get orDivider => 'or';

  @override
  String get other => 'Other';

  @override
  String get overdue => 'Overdue';

  @override
  String get owners => 'Previous owners';

  @override
  String get password => 'Password';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordStrengthMedium => 'Medium';

  @override
  String get passwordStrengthStrong => 'Strong';

  @override
  String get passwordStrengthWeak => 'Weak';

  @override
  String get passwordTooShort => 'Password must be at least 8 characters';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get pendingDecision => 'Pending Decision';

  @override
  String get perCheck => 'per check';

  @override
  String get permanentlyDelete => 'Permanently Delete';

  @override
  String get policeMisconduct => 'Police Misconduct';

  @override
  String get popular => 'POPULAR';

  @override
  String get preferences => 'PREFERENCES';

  @override
  String get preferredLanguage => 'Preferred Language';

  @override
  String get pricePerCheck => '€4.99 per check';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get dpaTitle => 'Data Processing Agreement';

  @override
  String get dpaCheckoutGateTitle => 'Before you upgrade';

  @override
  String get dpaCheckoutGateBody =>
      'EU law (GDPR Art. 28) requires us to sign a Data Processing Agreement with every paying customer. Please review and accept.';

  @override
  String get dpaViewLink => 'View Data Processing Agreement';

  @override
  String get dpaCheckboxLabel =>
      'I have read and accept the Data Processing Agreement (v1.0).';

  @override
  String get dpaCancel => 'Cancel';

  @override
  String get dpaAcceptAndContinue => 'Accept and continue';

  @override
  String get dpaOpenHint =>
      'Open the DPA at least once to enable the Accept button.';

  @override
  String get pro => 'Pro';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get rateUs => 'Rate Us';

  @override
  String get rateAppComingSoon => 'Coming to app stores soon!';

  @override
  String get dataCopiedToClipboard => 'Data copied to clipboard';

  @override
  String get readingDocument => 'Reading document…';

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String get referenceNumber => 'Reference Number';

  @override
  String get registerFailed => 'Registration failed. Please try again.';

  @override
  String get reportFraud => 'Report Fraud';

  @override
  String get requestExport => 'Request Export';

  @override
  String get researchingLaw => 'Researching applicable law…';

  @override
  String get resetPasswordFailed =>
      'Failed to send reset link. Please try again.';

  @override
  String get resetPasswordSent => 'Password reset link sent to your email.';

  @override
  String get residencePermit => 'Residence Permit';

  @override
  String get manageSubscription => 'Manage subscription';

  @override
  String get restorePurchases => 'Restore Purchases';

  @override
  String get retry => 'Retry';

  @override
  String get reviewWarning =>
      'Review carefully before sending. You are responsible for the content.';

  @override
  String get riskHigh => 'High risk — avoid';

  @override
  String get riskLow => 'Safe to work with';

  @override
  String get riskMedium => 'Proceed with caution';

  @override
  String get safeToBuy => 'Safe to buy';

  @override
  String get saveAndAnalyze => 'Save & Analyze';

  @override
  String get saveDraft => 'Save';

  @override
  String get saveWithAnnual => 'Save 25% with annual billing';

  @override
  String get scan => 'Scan';

  @override
  String get scanDocument => 'Scan Document';

  @override
  String get searchCases => 'Search cases…';

  @override
  String get selectCountry => 'Select country';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get sendViaEmail => 'Send via Email';

  @override
  String get settings => 'Settings';

  @override
  String get signIn => 'Sign In';

  @override
  String get signInLink => 'Log In';

  @override
  String get signInSubtitle => 'Sign in to access your cases';

  @override
  String get signOut => 'Sign Out';

  @override
  String get signOutConfirm => 'Are you sure you want to sign out?';

  @override
  String get signUp => 'Create Account';

  @override
  String get signUpLink => 'Sign Up';

  @override
  String get socialBenefits => 'Social Benefits';

  @override
  String get someConcerns => 'Some concerns';

  @override
  String get startFirstCase => 'Start your first case';

  @override
  String step(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get stolen => 'Stolen check';

  @override
  String get subscription => 'Subscription';

  @override
  String get syncLegalCorrespondence => 'Sync legal correspondence';

  @override
  String get syncNow => 'Sync Now';

  @override
  String get tenantRights => 'Tenant Rights';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get termsRequired => 'You must agree to the Terms of Service';

  @override
  String get timeline => 'Timeline';

  @override
  String get tryDemoMode => 'Try Demo Mode';

  @override
  String get typeDeleteToConfirm =>
      'Type DELETE to confirm permanent account removal.';

  @override
  String get typeMessage => 'Type a message…';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get uploadDocument => 'Upload Document';

  @override
  String urgentDeadline(String title) {
    return 'Urgent: $title';
  }

  @override
  String get useInAppeal => 'Use in Appeal';

  @override
  String get vehicleChecker => 'Vehicle Checker';

  @override
  String get vehicleChecks => 'Status Checks';

  @override
  String get vehicleColor => 'Color';

  @override
  String get vehicleMake => 'Make';

  @override
  String get vehicleModel => 'Model';

  @override
  String get vehicleYear => 'Year';

  @override
  String get version => 'Version';

  @override
  String get victimSupport => 'Victim Support';

  @override
  String get viewAll => 'View All';

  @override
  String get vinNumber => 'VIN number';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get whatAreMyOptions => 'What are my options?';

  @override
  String get won => 'Won';

  @override
  String get documentVault => 'Document Vault';

  @override
  String get secureDocumentStorage => 'Secure Document Storage';

  @override
  String get secureDocumentStorageDesc =>
      'Store your important legal documents in one place for easy access.';

  @override
  String get addDocument => 'Add Document';

  @override
  String get chooseHowToAdd => 'Choose how to add your document';

  @override
  String get uploadFile => 'Upload File';

  @override
  String get uploadFileDesc => 'Choose a PDF or image from your device';

  @override
  String get scanDocumentDesc => 'Take a photo of your document';

  @override
  String get createNote => 'Create Note';

  @override
  String get createNoteDesc => 'Write a note or record important details';

  @override
  String get knowYourRights => 'Know Your Rights';

  @override
  String get stoppedByPolice => 'Stopped by Police';

  @override
  String get stoppedByPoliceDesc => 'Your rights during a police encounter';

  @override
  String get deportationNotice => 'Deportation Notice';

  @override
  String get deportationNoticeDesc => 'Steps to challenge a removal order';

  @override
  String get workplaceRights => 'Workplace Rights';

  @override
  String get workplaceRightsDesc => 'Employment law protections in Finland';

  @override
  String get tenantRightsDesc => 'Housing and rental protections';

  @override
  String get immigrationDetention => 'Immigration Detention';

  @override
  String get immigrationDetentionDesc => 'Rights if detained by authorities';

  @override
  String get discriminationDesc => 'How to report and fight discrimination';

  @override
  String get scenarioNotFound => 'Scenario not found';

  @override
  String get youHaveRightTo => 'You have the right to:';

  @override
  String get youMust => 'You must:';

  @override
  String get immediateSteps => 'Immediate steps:';

  @override
  String get yourRights => 'Your rights:';

  @override
  String get basicRights => 'Basic rights:';

  @override
  String get yourRightsAsTenant => 'Your rights as a tenant:';

  @override
  String get yourRightsInDetention => 'Your rights in detention:';

  @override
  String get howToAct => 'How to act:';

  @override
  String get rightKnowWhyStopped => 'Know why you are being stopped';

  @override
  String get rightRemainSilent => 'Remain silent (you must identify yourself)';

  @override
  String get rightAskInterpreter => 'Ask for an interpreter';

  @override
  String get rightContactLawyer => 'Contact a lawyer before questioning';

  @override
  String get rightRecordEncounter => 'Record the encounter (in public places)';

  @override
  String get mustProvideName => 'Provide your name and date of birth';

  @override
  String get mustShowId => 'Show ID if you have one';

  @override
  String get mustNotResist => 'Not physically resist';

  @override
  String get doNotIgnoreNotice =>
      'Do NOT ignore the notice — deadlines are strict';

  @override
  String get noteAppealDeadline => 'Note the appeal deadline (usually 30 days)';

  @override
  String get contactLawyerImmediately => 'Contact a lawyer immediately';

  @override
  String get applyLegalAid => 'Apply for legal aid if needed';

  @override
  String get rightAppealAdmin => 'Right to appeal to the Administrative Court';

  @override
  String get rightLegalRep => 'Right to legal representation';

  @override
  String get rightInterpreter => 'Right to an interpreter';

  @override
  String get rightStayDuringAppeal =>
      'Right to stay during appeal (in most cases)';

  @override
  String get minimumWage => 'Minimum wage as per collective agreement';

  @override
  String get workingTimeLimits => 'Working time limits (max 8h/day, 40h/week)';

  @override
  String get annualLeave => 'Annual leave (minimum 2 days per month worked)';

  @override
  String get sickLeave => 'Sick leave compensation';

  @override
  String get safeWorkingConditions => 'Safe working conditions';

  @override
  String get writtenRentalAgreement => 'Written rental agreement required';

  @override
  String get securityDeposit => 'Security deposit max 3 months rent';

  @override
  String get landlordNotice => 'Landlord must give notice (3–6 months)';

  @override
  String get rightHabitableDwelling => 'Right to a habitable dwelling';

  @override
  String get protectionUnjustEviction => 'Protection from unjust eviction';

  @override
  String get rightKnowDetentionReason =>
      'Right to know the reason for detention';

  @override
  String get rightContactLawyerDetention => 'Right to contact a lawyer';

  @override
  String get rightContactEmbassy => 'Right to contact your embassy';

  @override
  String get rightChallengeDetention => 'Right to challenge detention in court';

  @override
  String get rightHumaneTreatment =>
      'Right to humane treatment and medical care';

  @override
  String get documentIncident =>
      'Document the incident (date, time, witnesses)';

  @override
  String get fileComplaintOmbudsman =>
      'File a complaint with the Non-Discrimination Ombudsman';

  @override
  String get contactLegalAidOffice => 'Contact a legal aid office';

  @override
  String get reportToPolice => 'Report to police if criminal (threat, assault)';

  @override
  String get legalAidCalculator => 'Legal Aid Calculator';

  @override
  String checkEligibility(String country) {
    return 'Check your eligibility for $country legal aid';
  }

  @override
  String get estimateDisclaimer =>
      'This is an estimate only. Actual eligibility is determined by the Legal Aid Office.';

  @override
  String get monthlyIncome => 'Monthly income (EUR)';

  @override
  String get totalAssets => 'Total assets (EUR)';

  @override
  String get numberOfDependents => 'Number of dependents';

  @override
  String get calculateEligibility => 'Calculate Eligibility';

  @override
  String get likelyEligible => 'Likely Eligible';

  @override
  String get mayNotQualify => 'May Not Qualify';

  @override
  String get fullFreeLegalAid =>
      'You likely qualify for full free legal aid (no co-payment).';

  @override
  String legalAidWithCopay(String percent) {
    return 'You may qualify for legal aid with a co-payment of $percent%.';
  }

  @override
  String get mayNotQualifyDesc =>
      'Based on this estimate, you may not qualify for state legal aid. Consider consulting a private lawyer or legal clinic.';

  @override
  String get couldNotLoadDeadlines => 'Could not load deadlines';

  @override
  String get noUpcomingDeadlines => 'No upcoming deadlines';

  @override
  String get allClearDeadlines =>
      'You are all caught up. New deadlines will appear here when they are set.';

  @override
  String get nothingOverdue => 'Nothing overdue';

  @override
  String get greatJobDeadlines => 'You are on top of your deadlines.';

  @override
  String get noCompletedDeadlines => 'No completed deadlines';

  @override
  String get completedDeadlinesDesc =>
      'Deadlines you complete will be shown here.';

  @override
  String get daysLate => 'days late';

  @override
  String get days => 'days';

  @override
  String get fromDocument => 'From document';

  @override
  String get couldNotLoadCase => 'Could not load case details';

  @override
  String get typeLabel => 'Type';

  @override
  String get nationality => 'Nationality';

  @override
  String get migriReference => 'Migri Reference';

  @override
  String get courtCaseNo => 'Court Case No.';

  @override
  String get created => 'Created';

  @override
  String get citizenship => 'Citizenship';

  @override
  String get workPermit => 'Work Permit';

  @override
  String get noDocumentsYet => 'No documents uploaded yet';

  @override
  String get noUpcomingDeadlinesShort => 'No upcoming deadlines';

  @override
  String get caseCreated => 'Case created';

  @override
  String get decisionReceived => 'Decision received';

  @override
  String get appealDeadline => 'Appeal deadline';

  @override
  String get hearingScheduled => 'Hearing scheduled';

  @override
  String get late => 'late';

  @override
  String get pending => 'Pending';

  @override
  String get processing => 'Processing';

  @override
  String get ready => 'Ready';

  @override
  String get failed => 'Failed';

  @override
  String get analyzed => 'Analyzed';

  @override
  String get noDocumentsScanHint => 'No documents yet. Scan or upload one.';

  @override
  String get inCourt => 'In Court';

  @override
  String get appeal => 'Appeal';

  @override
  String get caseTimeline => 'Case Timeline';

  @override
  String get couldNotLoadTimeline => 'Could not load timeline';

  @override
  String get noEventsYet => 'No events yet';

  @override
  String get activityWillAppear =>
      'Activity will appear here as your case progresses.';

  @override
  String caseCreatedDesc(String title) {
    return 'Case \"$title\" was created.';
  }

  @override
  String get decisionReceivedDesc =>
      'An official decision was received for this case.';

  @override
  String get appealDeadlineSet => 'Appeal deadline set';

  @override
  String appealDeadlineDesc(String date) {
    return 'Appeal must be filed by $date.';
  }

  @override
  String hearingScheduledDesc(String date) {
    return 'Court hearing scheduled for $date.';
  }

  @override
  String get caseInfoUpdated => 'Case information was last updated.';

  @override
  String get noEventsForFilter => 'No events match this filter';

  @override
  String get timelineFilterAll => 'All';

  @override
  String get timelineFilterEmails => 'Emails';

  @override
  String get timelineFilterConsilium => 'AI decisions';

  @override
  String get timelineFilterDeadlines => 'Deadlines';

  @override
  String get timelineFilterNotes => 'Notes';

  @override
  String get timelineEventEmailIn => 'Email received';

  @override
  String get timelineEventEmailOut => 'Email sent';

  @override
  String get timelineEventConsiliumDecision => 'AI decision';

  @override
  String get timelineEventDeadlineSet => 'Deadline';

  @override
  String get timelineEventDocUploaded => 'Document';

  @override
  String get timelineEventPhaseChange => 'Phase change';

  @override
  String get timelineEventManualNote => 'Note';

  @override
  String get timelineJustNow => 'Just now';

  @override
  String timelineMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String timelineHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String timelineDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get documentAnalysis => 'Document Analysis';

  @override
  String get exportAsPdf => 'Export as PDF';

  @override
  String get pdfExportComingSoon => 'Export as PDF';

  @override
  String get analysisFailedRetry => 'Analysis failed. Please try again.';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get genericError => 'Something went wrong. Please try again.';

  @override
  String get retryAnalysis => 'Retry Analysis';

  @override
  String issuesFoundInDocument(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Found $count issues in your document',
      one: 'Found 1 issue in your document',
      zero: 'No issues found in your document',
    );
    return '$_temp0';
  }

  @override
  String get severityOverview => 'Severity Overview';

  @override
  String get issuesFoundHeader => 'Issues Found';

  @override
  String generateAppealWithIssues(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Generate Appeal ($count issues)',
      one: 'Generate Appeal (1 issue)',
    );
    return '$_temp0';
  }

  @override
  String get analyzingContent => 'Analyzing content…';

  @override
  String get documentProcessedOk => 'Document processed successfully';

  @override
  String get noSignificantIssues =>
      'No significant issues were detected in this document.';

  @override
  String get cameraPermissionRequired => 'Camera permission required';

  @override
  String get cameraPermissionDesc =>
      'Grant camera access to scan documents, or use the gallery.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get alignDocument => 'Align document within the frame';

  @override
  String pageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages',
      one: '1 page',
      zero: 'no pages',
    );
    return '$_temp0';
  }

  @override
  String get preview => 'Preview';

  @override
  String pageNumber(int number) {
    return 'Page $number';
  }

  @override
  String get done => 'Done';

  @override
  String get retake => 'Retake';

  @override
  String get useThisPhoto => 'Use This Photo';

  @override
  String get addPage => 'Add Page';

  @override
  String uploadingPercent(int percent) {
    return 'Uploading… $percent%';
  }

  @override
  String get preparingUpload => 'Preparing upload…';

  @override
  String get documentUploadedSuccess => 'Document uploaded successfully';

  @override
  String pagesUploadedSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages uploaded successfully',
      one: '1 page uploaded successfully',
    );
    return '$_temp0';
  }

  @override
  String get uploadFailed =>
      'Upload failed. Please check your connection and try again.';

  @override
  String get capturePhotoFailed => 'Failed to capture photo. Please try again.';

  @override
  String get readingText => 'Reading text…';

  @override
  String get draftDocument => 'Draft Document';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get editDocument => 'Edit document';

  @override
  String get generatingDraft => 'Generating your draft…';

  @override
  String get generatingDraftDesc =>
      'AI is preparing a legal document based on your case details and selected issues.';

  @override
  String get failedToGenerateDraft =>
      'Failed to generate draft. Please try again.';

  @override
  String get changesSaved => 'Changes saved';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get emailComingSoon => 'Send email via your connected Gmail account';

  @override
  String get reviewBeforeSending =>
      'Review carefully before sending. You are responsible for the content of this document.';

  @override
  String get noContentAvailable => 'No content available';

  @override
  String get save => 'Save';

  @override
  String get edit => 'Edit';

  @override
  String get pdf => 'PDF';

  @override
  String get copy => 'Copy';

  @override
  String get appealDraft => 'Appeal Draft';

  @override
  String selected(int count) {
    return '$count selected';
  }

  @override
  String get deleteSelected => 'Delete selected';

  @override
  String deleteDocumentsConfirm(int count) {
    return 'Delete $count documents?';
  }

  @override
  String get delete => 'Delete';

  @override
  String get analyzeSelected => 'Analyze selected';

  @override
  String get batchAnalysisStarting => 'Batch analysis starting…';

  @override
  String get switchToList => 'Switch to list';

  @override
  String get switchToGrid => 'Switch to grid';

  @override
  String get scanNew => 'Scan New';

  @override
  String get noDocumentsYetScan => 'No documents yet';

  @override
  String get scanFirstDocumentHint =>
      'Scan your first document to let AI analyze it for errors and generate appeals.';

  @override
  String get failedToLoadDocuments => 'Failed to load documents';

  @override
  String get emailIntegrationTitle => 'Email Integration';

  @override
  String get connectYourEmail => 'Connect Your Email';

  @override
  String get connectYourEmailDesc =>
      'Connect your email to automatically detect and organize legal correspondence related to your cases.';

  @override
  String get legalEmails => 'Legal Emails';

  @override
  String get unlinkedEmails => 'Unlinked Emails';

  @override
  String get noLegalEmailsYet => 'No legal emails yet';

  @override
  String get legalEmailsWillAppear =>
      'Emails classified as legal-related will appear here.';

  @override
  String get assignToCase => 'Assign to case';

  @override
  String get disconnectEmail => 'Disconnect Email';

  @override
  String get disconnectEmailConfirm =>
      'You will stop receiving automatic email syncing. Previously synced emails will remain in your cases.';

  @override
  String get gmailReauthBannerBody =>
      'Advocat v2.1 reads your inbox to draft replies; you can revoke any time. Reconnect Gmail to enable proactive triage.';

  @override
  String get gmailReauthBannerCta => 'Reauthorize';

  @override
  String connectedTo(String email) {
    return 'Connected to $email';
  }

  @override
  String lastSynced(String time) {
    return 'Last synced $time';
  }

  @override
  String get filterByType => 'Filter by Type';

  @override
  String get noCasesMatchSearch => 'No cases match your search';

  @override
  String get failedToLoadCases => 'Failed to load cases';

  @override
  String get monthly => 'Monthly';

  @override
  String get annual => 'Annual';

  @override
  String get saveTwentyFivePercent => 'Save 25%';

  @override
  String get mostPopular => 'MOST POPULAR';

  @override
  String get oneCaseActive => '1 case';

  @override
  String get threeCasesActive => '3 cases';

  @override
  String get unlimitedCases => 'Unlimited cases';

  @override
  String get threeDocScans => '3 document scans (total)';

  @override
  String get twentyDocScans => '20 document scans/month';

  @override
  String get unlimitedDocScans => 'Unlimited document scans';

  @override
  String get basicAiAnalysis => 'Basic AI analysis';

  @override
  String get fullAiAnalysis => 'Full AI analysis';

  @override
  String get draftGeneration => 'Draft generation';

  @override
  String get priorityProcessing => 'Priority processing';

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
  String get forever => 'forever';

  @override
  String get perMonth => '/month';

  @override
  String get perYear => '/year';

  @override
  String get checkingPurchases => 'Checking for previous purchases…';

  @override
  String get noPreviousPurchases => 'No previous purchases found.';

  @override
  String get chatWelcomeMessage =>
      'Hi! I\'m Advocat — your AI legal assistant. I provide legal information, not legal advice. What legal question can I help with?';

  @override
  String get copySummary => 'Copy summary';

  @override
  String get caseSummaryCopied => 'Case summary copied to clipboard';

  @override
  String get openCase => 'Open Case';

  @override
  String get viewFull => 'View Full';

  @override
  String get draftCopiedToClipboard => 'Draft copied to clipboard';

  @override
  String get reportMileageFraud => 'Report Mileage Fraud';

  @override
  String get reportMileageFraudDesc =>
      'This will create a fraud report based on the vehicle check data. You can also open a legal case for further action.';

  @override
  String get reportAndOpenCase => 'Report & Open Case';

  @override
  String get caseCreationComingSoon =>
      'Case creation with pre-filled data coming soon';

  @override
  String get failedToCreateCaseRetry =>
      'Failed to create case. Please try again.';

  @override
  String get takePhotoInstead => 'Take a Photo Instead';

  @override
  String get deleteCase => 'Delete Case';

  @override
  String deleteCaseConfirm(String title) {
    return 'Are you sure you want to delete \"$title\"? This action cannot be undone.';
  }

  @override
  String get haveQuestionsAi => 'Have questions? Talk to AI';

  @override
  String get cookiePolicy => 'Cookie Policy';

  @override
  String get aiDisclaimer => 'AI Disclaimer';

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
  String get dataPrivacyConsent => 'Data Privacy Consent';

  @override
  String get gdprIntro =>
      'To provide AI legal assistance, we process your data in accordance with GDPR (EU 2016/679). By continuing you agree to:';

  @override
  String get gdprChat => 'Processing of your chat messages by AI';

  @override
  String get gdprDocs => 'Analysis of uploaded documents';

  @override
  String get gdprStorage => 'Encrypted storage of case data';

  @override
  String get gdprDelete => 'Right to delete your data at any time';

  @override
  String get gdprFooter =>
      'Your data is encrypted and processed securely. We use trusted service providers (AI processing, cloud database) to deliver the service. See our Privacy Policy for details. You can withdraw consent and delete all data from Settings.';

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
  String get aiGeneratedDisclaimer => 'AI-generated • Not legal advice';

  @override
  String get decline => 'Decline';

  @override
  String get iAgree => 'I Agree';

  @override
  String get iAgreeToThe => 'I agree to the ';

  @override
  String get orWord => 'or';

  @override
  String get english => 'English';

  @override
  String get russian => 'Russian';

  @override
  String get finnish => 'Finnish';

  @override
  String successSubscribed(String plan) {
    return 'Successfully subscribed to $plan!';
  }

  @override
  String paymentFailed(String error) {
    return 'Payment failed: $error';
  }

  @override
  String get whatToDo => 'What To Do';

  @override
  String get getHelp => 'Get Help';

  @override
  String get share => 'Share';

  @override
  String get didYouKnow => 'Did you know?';

  @override
  String get mustKnow => 'Must know';

  @override
  String get goodToKnow => 'Good to know';

  @override
  String get sentFromAdvocat => 'Sent from Advocat app';

  @override
  String get policeActionStayCalm => 'Stay calm and keep your hands visible';

  @override
  String get policeActionAskWhy => 'Ask the officer why you are being stopped';

  @override
  String get policeActionProvideName => 'Provide your name and date of birth';

  @override
  String get policeActionWantLawyer =>
      'State clearly: \"I want a lawyer before any questions\"';

  @override
  String get policeActionAskInterpreter => 'If needed, ask for an interpreter';

  @override
  String get policeActionNoteBadge =>
      'Note the officer\'s name and badge number';

  @override
  String get policeFactMustTellReason =>
      'In Finland, the police must tell you the reason for stopping you. If they do not, you may ask — they are legally required to explain.';

  @override
  String get policeFactCanRecord =>
      'You can record police interactions in public places in Finland. This is protected under freedom of expression.';

  @override
  String get contactFinnishLegalAid => 'Finnish Legal Aid';

  @override
  String get contactNonDiscriminationOmbudsman =>
      'Non-Discrimination Ombudsman';

  @override
  String get deportationDeadlineAppeal =>
      'Appeal to Administrative Court — usually 30 days from notification';

  @override
  String get deportationDeadlineLegalAid =>
      'Apply for legal aid — do this IMMEDIATELY';

  @override
  String get deportationFactStayDuringAppeal =>
      'In Finland, you usually have the right to stay in the country while your appeal is being processed. Deportation cannot happen during an active appeal in most cases.';

  @override
  String get contactRefugeeAdviceCentre => 'Finnish Refugee Advice Centre';

  @override
  String get contactAdminCourtHelsinki => 'Administrative Court Helsinki';

  @override
  String get workplaceActionKeepContract =>
      'Keep copies of your employment contract';

  @override
  String get workplaceActionTrackHours =>
      'Track your working hours independently';

  @override
  String get workplaceActionReportUnsafe =>
      'Report unsafe conditions to occupational safety';

  @override
  String get workplaceActionJoinUnion => 'Join a trade union for protection';

  @override
  String get workplaceActionContactAuthority =>
      'Contact the Occupational Safety Authority if needed';

  @override
  String get workplaceFactCollectiveWage =>
      'In Finland, collective agreements set minimum wages by industry — there is no single national minimum wage. Your employer must follow the collective agreement for your field.';

  @override
  String get workplaceFactOralContract =>
      'Even without a written contract, you have full employee rights in Finland. An oral agreement is equally binding by law.';

  @override
  String get contactOccupationalSafety => 'Occupational Safety Authority';

  @override
  String get contactTradeUnionSAK => 'Trade Union Advice (SAK)';

  @override
  String get tenantActionWrittenAgreement =>
      'Always have a written rental agreement';

  @override
  String get tenantActionDocumentCondition =>
      'Document the apartment condition at move-in (photos)';

  @override
  String get tenantActionReportMaintenance =>
      'Report maintenance issues in writing';

  @override
  String get tenantActionNoIllegalEviction =>
      'Never agree to illegal eviction — courts must decide';

  @override
  String get tenantActionContactAdvisory =>
      'Contact tenant advisory services if disputes arise';

  @override
  String get tenantFactNoEvictionWithoutCourt =>
      'A landlord in Finland cannot evict you without a court order, even if your lease has expired. Changing locks or cutting utilities is illegal.';

  @override
  String get contactTenantsAssociation => 'Finnish Tenants Association';

  @override
  String get contactConsumerDisputesBoard => 'Consumer Disputes Board';

  @override
  String get detentionActionAskDecision =>
      'Ask for the written detention decision immediately';

  @override
  String get detentionActionRequestLawyer => 'Request to contact a lawyer';

  @override
  String get detentionActionContactEmbassy =>
      'Contact your embassy or consulate';

  @override
  String get detentionActionAskMedical => 'Ask for medical attention if needed';

  @override
  String get detentionActionRequestInterpreter =>
      'Request an interpreter for all proceedings';

  @override
  String get detentionDeadlineCourtReview =>
      'District Court must review detention within 4 days';

  @override
  String get detentionDeadlineContinuation =>
      'Court reviews continuation every 2 weeks';

  @override
  String get detentionFactCourtReview =>
      'Immigration detention in Finland must be reviewed by a district court within 4 days. If it is not, the detention becomes unlawful.';

  @override
  String get contactParliamentaryOmbudsman => 'Parliamentary Ombudsman';

  @override
  String get discriminationActionWriteDown =>
      'Write down exactly what happened (date, time, place)';

  @override
  String get discriminationActionSaveEvidence =>
      'Save any evidence: messages, emails, witnesses';

  @override
  String get discriminationActionFileComplaint =>
      'File a complaint with the Non-Discrimination Ombudsman';

  @override
  String get discriminationActionContactLegalAid =>
      'Contact a legal aid office for free advice';

  @override
  String get discriminationActionReportPolice =>
      'Report to police if threats or assault were involved';

  @override
  String get discriminationFactNonDiscriminationAct =>
      'Finland\'s Non-Discrimination Act covers discrimination based on age, origin, nationality, language, religion, health, disability, sexual orientation, and other personal characteristics.';

  @override
  String get contactVictimSupportRIKU => 'Victim Support Finland (RIKU)';

  @override
  String get domesticViolence => 'Domestic Violence & Assault';

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
  String get inheritance => 'Inheritance';

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
  String get consumerProtection => 'Consumer Protection';

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
  String get comingSoon => 'Coming soon';

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
      other: '$count rights inside',
      one: '1 right inside',
      zero: 'no rights inside',
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
  String get guestUser => 'Guest';

  @override
  String get howToUse => 'How to use?';

  @override
  String get tutorialStep1Title => 'AI Legal Assistant';

  @override
  String get tutorialStep1Desc =>
      'Ask any legal question and get instant answers based on Estonian law.';

  @override
  String get tutorialStep2Title => 'Know Your Rights';

  @override
  String get tutorialStep2Desc =>
      'Browse legal information by topic — employment, housing, consumer rights and more.';

  @override
  String get tutorialStep3Title => 'Scan Documents';

  @override
  String get tutorialStep3Desc =>
      'Take photos of legal documents for AI analysis and safe storage.';

  @override
  String get tutorialStep4Title => 'Get Started!';

  @override
  String get tutorialStep4Desc =>
      'Explore the app and protect your rights. All data stays private on your device.';

  @override
  String get advocatProTitle => 'Advocat Pro';

  @override
  String get advocatProSubtitle => 'Unlock premium features';

  @override
  String get voiceDisclaimer =>
      'Voice assistant currently works only on desktop (Chrome browser). Mobile support coming soon.';

  @override
  String get recommended => 'Recommended';

  @override
  String get pleaseLogIn => 'Please log in';

  @override
  String get subscriptionNotFound => 'Subscription not found';

  @override
  String errorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String get redirectingToPayment => 'Redirecting to payment page…';

  @override
  String cheaperAnnually(String amount) {
    return '€$amount/mo cheaper annually';
  }

  @override
  String get navigatingTo => 'Opening';

  @override
  String get stayInChat => 'Stay in chat';

  @override
  String get backToChat => 'Back to chat';

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
  String get feedbackThumbsUpLabel => 'Helpful';

  @override
  String get feedbackThumbsDownLabel => 'Not helpful';

  @override
  String get feedbackCommentPrompt => 'What was wrong?';

  @override
  String get feedbackSend => 'Send';

  @override
  String get feedbackCancel => 'Cancel';

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
  String freeQuotaExhausted(int count) {
    return 'You\'ve used all $count free messages this month.';
  }

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
  String get citationStatusVerifiedBadge => 'Verified';

  @override
  String get citationStatusUnverifiedBadge => 'Unverified';

  @override
  String get citationStatusHistoricalBadge => 'Historical version';

  @override
  String get citationStatusVerifiedTooltip =>
      'Cited from a retrieved law source.';

  @override
  String get citationStatusUnverifiedTooltip =>
      'AI quoted this without retrieval — verify before relying.';

  @override
  String get citationStatusHistoricalTooltip =>
      'Cited section is no longer in force.';

  @override
  String get citationOpenInRiigiTeataja => 'Open in Riigi Teataja';

  @override
  String get citationSnippetExpand => 'Show full text';

  @override
  String get citationSnippetCollapse => 'Show less';

  @override
  String get citationUnverifiedSheetNote =>
      'AI cited this paragraph but it was not retrieved from the law corpus this turn. Verify the reference before relying on it.';

  @override
  String get citationFooterNoneWarning => 'No grounded citations';

  @override
  String citationFooterSummaryTotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count citations',
      one: '1 citation',
    );
    return '$_temp0';
  }

  @override
  String citationFooterSummaryVerified(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count verified',
      one: '1 verified',
    );
    return '$_temp0';
  }

  @override
  String citationFooterSummaryUnverified(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unverified',
      one: '1 unverified',
    );
    return '$_temp0';
  }

  @override
  String citationFooterSummaryHistorical(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count historical',
      one: '1 historical',
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
      other: 'in $count days',
      one: 'in 1 day',
      zero: 'today',
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
      other: '$count days overdue',
      one: '1 day overdue',
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
    return 'Consilium recommends $count parallel actions';
  }

  @override
  String get parallelActionsApproveAll => 'Approve All & Send';

  @override
  String parallelActionsApproveSelected(int count, int total) {
    return 'Approve $count of $total';
  }

  @override
  String parallelActionsConfirmTitle(int count) {
    return 'Send $count emails?';
  }

  @override
  String parallelActionsConfirmBody(int count) {
    return 'Advocat will dispatch $count prepared replies via your connected Gmail. Each one is sent independently — if any one fails, the others still go.';
  }

  @override
  String parallelActionsSentToast(int count) {
    return '$count sent.';
  }

  @override
  String parallelActionsPartialFailureToast(int sent, int failed) {
    return '$sent sent, $failed failed.';
  }

  @override
  String get parallelActionsKindReply => 'reply';

  @override
  String get parallelActionsKindNew => 'new';

  @override
  String get parallelActionsCheckboxSelected => 'Action selected';

  @override
  String get parallelActionsCheckboxUnselected => 'Action not selected';

  @override
  String parallelActionsCitationCount(int count) {
    return '$count cit';
  }

  @override
  String parallelActionsRetryFailed(int count) {
    return 'Retry failed ($count)';
  }

  @override
  String get agentApprovalNeedsReviewTitle => 'Advocat needs your approval';

  @override
  String get agentApprovalResolvedTitle => 'Action resolved';

  @override
  String get agentApprovalStepsLabel => 'steps';

  @override
  String get agentApprovalApproveButton => 'Approve & Send';

  @override
  String get agentApprovalDeclineButton => 'Decline';

  @override
  String get agentApprovalAttachmentsLabel => 'Attachments';

  @override
  String get agentApprovalSentSummary => 'Sent on your behalf.';

  @override
  String get agentApprovalDeclinedSummary => 'Declined — nothing was sent.';

  @override
  String get agentToolDraftEmailAtt => 'Send email with attachments';

  @override
  String get agentToolSendEmail => 'Send email';

  @override
  String get agentToolGeneratePdf => 'Generate PDF';

  @override
  String get agentToolApproveSend => 'Send prepared reply';

  @override
  String get inboxErrorTitle => 'Could not load inbox';

  @override
  String get inboxEditDiscardTitle => 'Discard unsaved edits?';

  @override
  String get inboxEditDiscardBody =>
      'You have unsaved changes to this draft. Going back will discard them.';

  @override
  String get inboxEditKeepEditing => 'Keep editing';

  @override
  String get inboxEditDiscard => 'Discard';

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
  String get supportTitle => 'Help';

  @override
  String get supportSubtitle => 'We usually reply within 1-2 hours.';

  @override
  String get supportSearchPlaceholder => 'Search help…';

  @override
  String get supportStatusAllOk => 'All systems normal';

  @override
  String get supportFaqWhatIs => 'What is Advocat?';

  @override
  String get supportFaqHowSubscribe => 'How do I subscribe to Pro?';

  @override
  String get supportFaqExportData => 'Can I export my data?';

  @override
  String get supportFaqCancelAccount => 'Cancel or delete account';

  @override
  String get supportFaqTalkHuman => 'Talk to a human';

  @override
  String get supportContactEmail => 'Email';

  @override
  String get supportContactTelegram => 'Telegram';

  @override
  String get supportContactWhatsapp => 'WhatsApp';

  @override
  String get supportFooterSla => 'We respond within 24h';

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
  String get reviewThisContract => 'Review this contract';

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
      other: '$count contract reviews left this month',
      one: '1 contract review left this month',
      zero: 'No contract reviews left this month',
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
  String get referralTitle => 'Invite friends';

  @override
  String get referralSubtitle => 'Get a free month. Give a free month.';

  @override
  String get referralYourLink => 'YOUR LINK';

  @override
  String get referralCopyLink => 'Copy link';

  @override
  String get referralShare => 'Share';

  @override
  String get referralLinkCopied => 'Link copied';

  @override
  String get referralStatsInvited => 'Invited';

  @override
  String get referralStatsConverted => 'Converted';

  @override
  String get referralStatsEarned => 'Months earned';

  @override
  String get referralShareWhatsApp => 'Share on WhatsApp';

  @override
  String get referralShareTelegram => 'Share on Telegram';

  @override
  String get referralShareEmail => 'Share by email';

  @override
  String get referralEmailSubject => 'Try Advocat — your AI legal assistant';

  @override
  String get referralLoadError =>
      'Could not load referral info. Pull to refresh.';

  @override
  String get referralRetry => 'Retry';

  @override
  String get referralSettingsTile => 'Invite friends';

  @override
  String get referralAfterReviewCta =>
      'Loved this? Invite a friend — both get a free month.';

  @override
  String get referralAntiFraud => 'Maximum 12 successful referrals per year.';

  @override
  String get referralEmpty =>
      'No referrals yet. Send your link to start earning.';

  @override
  String get referralRecentActivity => 'Recent activity';

  @override
  String referralActivityInvited(String when) {
    return 'Invited $when';
  }

  @override
  String referralActivityActivated(String when) {
    return 'activated $when';
  }

  @override
  String get referralActivityPending => 'not activated yet';

  @override
  String referralStatsInvitedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count friends',
      one: '1 friend',
      zero: 'no friends yet',
    );
    return 'You\'ve invited $_temp0';
  }

  @override
  String referralStatsConvertedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count have activated',
      one: '1 has activated',
      zero: 'none activated yet',
    );
    return '$_temp0';
  }

  @override
  String referralStatsEarnedCount(int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months free months',
      one: '1 free month',
      zero: 'nothing yet',
    );
    return 'Your bonus: $_temp0';
  }

  @override
  String get referralNudgeMessage =>
      'Like Advocat? Invite a friend — both get a free month.';

  @override
  String get referralNudgeAction => 'Invite';

  @override
  String get referralLandingTitle => 'You\'ve been invited to Advocat';

  @override
  String referralLandingSubtitle(String inviterName) {
    return '$inviterName invited you — claim your free first month.';
  }

  @override
  String get referralLandingSubtitleGeneric =>
      'Claim your free first month of Advocat Pro.';

  @override
  String get referralLandingCta => 'Activate free month & sign up';

  @override
  String get referralLandingCtaSecondary => 'Or learn more about Advocat';

  @override
  String get referralLandingFallback =>
      'This link has expired — but you can still try Advocat free.';

  @override
  String get referralLandingBenefits =>
      '17 languages • Real Estonian, Finnish and EU law • 24/7 — no waiting';

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
  String get sensitiveConsentTitle => 'Sensitive data consent';

  @override
  String get sensitiveConsentBody =>
      'Documents you\'re about to upload may contain special-category personal data under GDPR Art. 9 — such as health records, criminal records, biometric data, or information about your racial origin, religion, or sexual orientation.\n\nWe process this data only to provide you with AI legal assistance, store it encrypted in your private account, and never use it to train models. You can withdraw consent and delete the data at any time from Settings.\n\nBy accepting, you give explicit consent under Art. 9(2)(a) GDPR to process special-category data for this purpose.';

  @override
  String get sensitiveConsentExplicitCheckbox =>
      'I give explicit consent to process special-category data (Art. 9(2)(a) GDPR).';

  @override
  String get sensitiveConsentRightToShareCheckbox =>
      'I confirm I have the right to share this data (the data is mine, or I have informed/lawful basis to share third-party data).';

  @override
  String get sensitiveConsentViewCategories =>
      'View what counts as sensitive →';

  @override
  String get sensitiveConsentWithdrawAction =>
      'Withdraw sensitive data consent';

  @override
  String get privacyAndData => 'PRIVACY & DATA';

  @override
  String get exportMyDataSubtitle =>
      'Download a copy of all your personal data (GDPR Art. 15).';

  @override
  String get withdrawSensitiveConsent => 'Sensitive data consent';

  @override
  String get withdrawSensitiveConsentSubtitle =>
      'Manage or withdraw consent to process special-category data (GDPR Art. 9(2)(a)).';

  @override
  String get dataProcessingAgreement => 'Data Processing Agreement';

  @override
  String get exportingData => 'Exporting your data…';

  @override
  String get exportComplete => 'Data export ready — saved to your device.';

  @override
  String get exportFailed =>
      'Export failed. Please try again or contact support.';

  @override
  String get quotaExhaustedTitle => 'Free message limit reached';

  @override
  String quotaExhaustedBody(int count) {
    return 'You\'ve used all $count free messages. Upgrade to Advocat Counsel for €19.99/month and get unlimited AI legal consultations.';
  }

  @override
  String get quotaExhaustedLater => 'Later';

  @override
  String get quotaExhaustedUpgrade => 'Advocat Counsel — €19.99/mo';

  @override
  String quotaCtaMessage(int count) {
    return 'You\'ve used all $count free messages. Upgrade to Advocat Counsel for €19.99/month.';
  }

  @override
  String get quotaCtaButton => 'Get Advocat Counsel — €19.99/mo';

  @override
  String get aiErrorQuota =>
      'Free message limit reached. Subscribe to continue using AI.';

  @override
  String get aiErrorAuth =>
      'Sign-in required to use the AI. Please register or log in.';

  @override
  String get aiErrorGeneric =>
      'Temporary AI error. Please try again in a minute. If it persists, contact support.';

  @override
  String get tooltipShareCase => 'Share case summary';

  @override
  String get tooltipMuteVoice => 'Mute voice';

  @override
  String get tooltipUnmuteVoice => 'Unmute voice';

  @override
  String get tooltipAttachDoc => 'Attach document';

  @override
  String get aiTypingHint => 'AI…';

  @override
  String get error404Title => 'Page not found';

  @override
  String error404Body(String path) {
    return 'We couldn\'t find: $path';
  }

  @override
  String get goToHome => 'Go to home';

  @override
  String get emailAlreadyRegistered =>
      'This email is already registered. Want to sign in?';

  @override
  String get actionSignIn => 'Sign in';

  @override
  String get actionUndo => 'Undo';

  @override
  String get intakeUrgentOpened => 'Chat opened — your draft is saved.';

  @override
  String get panicCoachmark => 'Hold for emergency help.';

  @override
  String get panicTitle => 'What do you need right now?';

  @override
  String get panicCardReadAloud => 'Read aloud to the officer';

  @override
  String get panicCardRecord => 'Record this conversation';

  @override
  String get panicCardCall => 'Call a lawyer';

  @override
  String get panicCardAi => 'Talk to Advocat now';

  @override
  String get panicClose => 'Close';

  @override
  String get panicBadgeV2 => 'V2';

  @override
  String get panicRecordV1Title => 'Coming in V2';

  @override
  String get panicRecordV1Body =>
      'The recording feature is being legally validated for Estonia and will ship in V2. For now, use your phone\'s built-in voice recorder.';

  @override
  String get panicCallFallbackBody =>
      'Email kiire@advocat.ee with a short description and we will call you back.';

  @override
  String get consiliumHeader => 'Lawyer Consilium';

  @override
  String consiliumProgress(int count, int total) {
    return '$count of $total ready';
  }

  @override
  String get consiliumStarting => 'Lawyers reviewing your case…';

  @override
  String get consiliumDisagreement => 'Experts disagree';

  @override
  String get consiliumSynthesizing => 'Synthesizing recommendation…';

  @override
  String consiliumDone(int totalRoles) {
    return 'Consilium complete · $totalRoles experts';
  }

  @override
  String get consiliumPositionPush => 'Push';

  @override
  String get consiliumPositionSettle => 'Settle';

  @override
  String get consiliumPositionInvestigate => 'Investigate';

  @override
  String get consiliumPositionOutOfScope => 'Out of scope';

  @override
  String get consiliumConfidence => 'Confidence';

  @override
  String get consiliumKeyCitation => 'Key citation';

  @override
  String get consiliumAdversarialRound => 'Adversarial round';

  @override
  String get consiliumViewFullOpinion => 'View full opinion';

  @override
  String consiliumExpertsAgreed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count experts agreed',
      one: '1 expert agreed',
    );
    return '$_temp0';
  }

  @override
  String consiliumExpertsDisagree(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count experts disagree',
      one: '1 expert disagrees',
    );
    return '$_temp0';
  }

  @override
  String get consiliumDisclaimer =>
      'AI agents, not human lawyers. Verify material decisions with a licensed attorney.';

  @override
  String get softCaseShellBanner =>
      'We created \"Untitled case\" to track this. Tap to rename.';

  @override
  String get softCaseShellBannerCta => 'Rename';

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
  String get dangerZone => 'Danger zone';

  @override
  String get deleteAccountConfirmButton => 'Delete forever';

  @override
  String deleteAccountConfirmHint(String email) {
    return 'Type $email to confirm';
  }

  @override
  String get deleteAccountSuccess =>
      'Account deleted. We\'re sorry to see you go.';

  @override
  String get deleteAccountWarning =>
      'This permanently deletes your account, all cases, drafts, vault documents, and chat history. This cannot be undone.';

  @override
  String get deletingAccount => 'Deleting account…';

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
  String get iapPayWithApple => 'Pay with Apple';

  @override
  String get iapRestorePurchases => 'Restore Purchases';

  @override
  String get iapPurchaseFailed =>
      'Purchase failed. Please try again or contact support.';

  @override
  String get iapRestoreSuccess => 'Your subscription has been restored.';

  @override
  String get iapRestoreNoActive => 'No active subscription found to restore.';

  @override
  String get deadlineEuRadarTitle => 'EU deadline radar (preview)';

  @override
  String get deadlineEuRadarSubtitle =>
      'Hypothetical EU procedural deadlines — mock data';

  @override
  String get changePassword => 'Change password';

  @override
  String get changePasswordSubtitle => 'Update your account password';

  @override
  String get newPasswordTitle => 'Set a new password';

  @override
  String get newPasswordHint =>
      'Enter and confirm a new password for your account.';

  @override
  String get newPasswordSave => 'Save new password';

  @override
  String get newPasswordSuccess =>
      'Password updated. You can now use it to sign in.';

  @override
  String get newPasswordError => 'Failed to update password. Please try again.';

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
  String followupsDueOn(String date) {
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
  String checklistProgress(int completed, int total) {
    return '$completed of $total steps done';
  }

  @override
  String get checklistAllDone => 'All steps complete';

  @override
  String get checklistEmpty =>
      'No action plan is available for this case type yet.';

  @override
  String checklistDeadlineDays(int days) {
    return '$days days';
  }

  @override
  String get checklistDisclaimer =>
      'This is general information, not legal advice. Deadlines are statutory defaults — confirm the exact date for your case.';

  @override
  String get checklistViewPlan => 'View plan';

  @override
  String get explainPlainTitle => 'Explain in plain words';

  @override
  String get explainPlainIntro =>
      'Paste an official letter, decision, or contract and we\'ll explain what it means and what it asks you to do — in plain language.';

  @override
  String get explainPlainLevelFriend => 'Like to a friend';

  @override
  String get explainPlainLevelTerms => 'Keep legal terms';

  @override
  String get explainPlainInputHint => 'Paste the legal text here…';

  @override
  String get explainPlainSubmit => 'Explain';

  @override
  String get explainPlainWorking => 'Explaining…';

  @override
  String get explainPlainTldr => 'Bottom line';

  @override
  String get explainPlainBreakdown => 'What it says, part by part';

  @override
  String get explainPlainGlossary => 'Tricky terms explained';

  @override
  String get explainPlainNextSteps => 'What you can do next';

  @override
  String get explainPlainOpenInCorpus => 'Look up in the law library';

  @override
  String get explainPlainEmptyResult =>
      'No explanation could be produced for this text. Try pasting a longer or clearer excerpt.';

  @override
  String get explainPlainQuotaTitle =>
      'You\'ve used your free explanations this month';

  @override
  String get explainPlainQuotaBody =>
      'Free accounts get 3 explanations per month. Upgrade to Pro for unlimited explanations.';

  @override
  String get explainPlainUpgradeCta => 'Upgrade to Pro';

  @override
  String get explainPlainError =>
      'Something went wrong while explaining this text. Please try again.';

  @override
  String get explainPlainRetry => 'Try again';

  @override
  String get demandLetterTitle => 'Demand letter';

  @override
  String get demandLetterSubtitle =>
      'Create a formal pre-court demand (maksuvaatimus / nõudekiri).';

  @override
  String get demandLetterStepType => 'Type of claim';

  @override
  String get demandLetterStepParties => 'Parties';

  @override
  String get demandLetterStepClaim => 'Amount & basis';

  @override
  String get demandLetterStepDeadline => 'Deadline';

  @override
  String get demandLetterStepReview => 'Review & generate';

  @override
  String get demandLetterClaimDepositReturn => 'Return of rental deposit';

  @override
  String get demandLetterClaimUnpaidWage => 'Unpaid wages';

  @override
  String get demandLetterClaimFineDispute => 'Dispute a fine / charge';

  @override
  String get demandLetterClaimGeneric => 'Other monetary claim';

  @override
  String get demandLetterJurisdiction => 'Jurisdiction';

  @override
  String get demandLetterLanguage => 'Letter language';

  @override
  String get demandLetterRecipientName => 'Recipient name';

  @override
  String get demandLetterRecipientAddress => 'Recipient address (optional)';

  @override
  String get demandLetterSenderName => 'Your name';

  @override
  String get demandLetterSenderAddress => 'Your address / email (optional)';

  @override
  String get demandLetterAmount => 'Amount';

  @override
  String get demandLetterCurrency => 'Currency';

  @override
  String get demandLetterBasis => 'What happened (basis of the claim)';

  @override
  String get demandLetterBasisHint =>
      'Describe the facts: dates, amounts, what was agreed and what went wrong.';

  @override
  String get demandLetterDeadline => 'Payment deadline';

  @override
  String get demandLetterDeadlineHint => 'e.g. 14 days from today';

  @override
  String get demandLetterReference => 'Reference (optional)';

  @override
  String get demandLetterGenerate => 'Generate letter';

  @override
  String get demandLetterGenerating => 'Generating…';

  @override
  String get demandLetterGenerateFailed =>
      'Couldn\'t generate the letter. Please try again.';

  @override
  String get demandLetterFieldRequired => 'This field is required';

  @override
  String get demandLetterNext => 'Next';

  @override
  String get demandLetterBack => 'Back';

  @override
  String get demandLetterPreviewTitle => 'Your letter';

  @override
  String get demandLetterCopy => 'Copy text';

  @override
  String get demandLetterCopied => 'Letter copied to clipboard';

  @override
  String get demandLetterExportPdf => 'Export PDF';

  @override
  String get demandLetterExporting => 'Exporting…';

  @override
  String get demandLetterExportFailed =>
      'Couldn\'t export the document. Please try again.';

  @override
  String get demandLetterSendEmail => 'Send via email';

  @override
  String get demandLetterNormsTitle => 'Legal references';

  @override
  String get demandLetterDisclaimer =>
      'This letter is prepared on your behalf as a general template. It is not legal advice or an act of a licensed attorney. Review it before sending — no letter is sent automatically.';

  @override
  String get demandLetterMenuTile => 'Demand letter';

  @override
  String get calcHubTitle => 'Legal calculators';

  @override
  String get calcHubSubtitle => 'Quick estimates before your next step';

  @override
  String get calcHubJurisdiction => 'Jurisdiction';

  @override
  String calcRatesAsOf(String date) {
    return 'Rates as of $date';
  }

  @override
  String get calcRatesOffline => 'Showing cached rates (offline)';

  @override
  String get calcIndicativeBanner =>
      'Indicative estimate only — not an official calculation or legal advice.';

  @override
  String get calcCalculate => 'Calculate';

  @override
  String get calcResult => 'Result';

  @override
  String get calcFormula => 'How this is calculated';

  @override
  String get calcSource => 'Source';

  @override
  String get calcSeveranceTitle => 'Severance / notice';

  @override
  String get calcSeveranceDesc =>
      'Estimate severance pay and notice period on redundancy';

  @override
  String get calcSeveranceSalary => 'Gross monthly salary';

  @override
  String get calcSeveranceTenure => 'Years of service';

  @override
  String get calcSeveranceTotal => 'Estimated severance';

  @override
  String get calcSeveranceNotice => 'Notice period';

  @override
  String get calcSeveranceGenerateDemand => 'Draft a demand letter';

  @override
  String get calcLimitationTitle => 'Limitation & appeal deadlines';

  @override
  String get calcLimitationDesc =>
      'Check whether a claim or appeal period has expired';

  @override
  String get calcLimitationType => 'Type of period';

  @override
  String get calcLimitationStart => 'Start date (event / decision)';

  @override
  String get calcLimitationPickDate => 'Pick date';

  @override
  String get calcLimitationDeadline => 'Deadline';

  @override
  String get calcLimitationExpired => 'Period has expired';

  @override
  String calcLimitationDaysLeft(int days) {
    return '$days days remaining';
  }

  @override
  String get calcLimitationShifted =>
      'Shifted to the next working day (weekend/holiday).';

  @override
  String get calcLimitationAddDeadline => 'Add to deadlines';

  @override
  String get calcStateFeeTitle => 'Court / state fees';

  @override
  String get calcStateFeeDesc => 'Reference filing fees by court and stage';

  @override
  String get calcChildSupportTitle => 'Child support (orientation)';

  @override
  String get calcChildSupportDesc =>
      'Rough orientation figure — the real amount is set case by case';

  @override
  String get calcChildSupportNet => 'Payer\'s net monthly income';

  @override
  String get calcChildSupportChildren => 'Number of children';

  @override
  String get calcChildSupportPerChild => 'Per child';

  @override
  String get calcChildSupportTotal => 'Total monthly';

  @override
  String get calcChildSupportWarning =>
      'Highly variable. Courts decide on the child\'s needs and both parents\' ability to pay. Use as a starting point only.';

  @override
  String get docCollectTitle => 'Documents to collect';

  @override
  String get docCollectSubtitle =>
      'Gather these before you apply or go to court';

  @override
  String get docCollectPickPrompt => 'What is your situation?';

  @override
  String get docCollectProblemResidence => 'Residence permit';

  @override
  String get docCollectProblemTenant => 'Renting / eviction';

  @override
  String get docCollectProblemDismissal => 'Dismissal at work';

  @override
  String get docCollectProblemInheritance => 'Inheritance';

  @override
  String get docCollectProblemDivorce => 'Divorce';

  @override
  String docCollectProgress(int collected, int total) {
    return '$collected of $total collected';
  }

  @override
  String get docCollectAllDone => 'Everything collected';

  @override
  String get docCollectEmpty =>
      'No document list is available for this situation yet.';

  @override
  String get docCollectOptional => 'Optional';

  @override
  String get docCollectWhereLabel => 'Where to get it';

  @override
  String get docCollectWhyLabel => 'Why it\'s needed';

  @override
  String get docCollectAttach => 'Attach a file';

  @override
  String get docCollectAttached => 'File attached';

  @override
  String get docCollectChangeFile => 'Change file';

  @override
  String get docCollectRemoveFile => 'Remove file';

  @override
  String get docCollectNoFiles => 'You haven\'t uploaded any documents yet.';

  @override
  String get docCollectPickFileTitle => 'Choose an uploaded document';

  @override
  String get docCollectExport => 'Export list';

  @override
  String get docCollectExportSubject => 'My document checklist';

  @override
  String get docCollectAiTitle => 'Need something specific?';

  @override
  String get docCollectAiHint =>
      'Describe your situation and we\'ll suggest any extra documents.';

  @override
  String get docCollectAiField => 'Describe your situation';

  @override
  String get docCollectAiButton => 'Suggest extra documents';

  @override
  String get docCollectAiLoading => 'Thinking…';

  @override
  String get docCollectAiEmpty =>
      'No extra documents suggested — the basic list looks complete for your description.';

  @override
  String get docCollectAiSuggestionsTitle => 'Suggested extra documents';

  @override
  String get docCollectDisclaimer =>
      'This is a basic list of commonly required documents — your situation may need more or fewer. It is general information, not legal advice.';

  @override
  String get docCollectRetry => 'Try again';

  @override
  String get renewalTitle => 'Renewal Radar';

  @override
  String get renewalSubtitle =>
      'Track when your permits, passport, insurance and other documents expire. We\'ll remind you 90, 30 and 7 days before each renewal.';

  @override
  String get renewalAdd => 'Add document';

  @override
  String get renewalEditTitle => 'Edit document';

  @override
  String get renewalSave => 'Save';

  @override
  String get renewalRequired => 'Required';

  @override
  String get renewalPickDate => 'Pick expiry date';

  @override
  String get renewalLoadError =>
      'Could not load your documents. Pull to refresh.';

  @override
  String get renewalEmptyTitle => 'No documents tracked yet';

  @override
  String get renewalEmptyBody =>
      'Add your residence permit, passport, insurance or licence and we\'ll watch the expiry dates for you.';

  @override
  String get renewalGuideHint => 'How to renew →';

  @override
  String get renewalFieldType => 'Document type';

  @override
  String get renewalFieldLabel => 'Label';

  @override
  String get renewalFieldNumber => 'Document number (optional)';

  @override
  String get renewalFieldJurisdiction => 'Issuing country';

  @override
  String get renewalFieldExpiry => 'Expiry date';

  @override
  String get renewalWindow90 => '90 days';

  @override
  String get renewalWindow30 => '30 days';

  @override
  String get renewalWindow7 => '7 days';

  @override
  String get renewalExpiresToday => 'Expires today';

  @override
  String renewalExpiresInDays(int days, String date) {
    return 'Expires in $days days · $date';
  }

  @override
  String renewalExpiredOn(String date) {
    return 'Expired on $date';
  }

  @override
  String get renewalTypeResidencePermit => 'Residence permit';

  @override
  String get renewalTypePassport => 'Passport';

  @override
  String get renewalTypeIdCard => 'ID card';

  @override
  String get renewalTypeVisa => 'Visa';

  @override
  String get renewalTypeDrivingLicence => 'Driving licence';

  @override
  String get renewalTypeInsurance => 'Insurance';

  @override
  String get renewalTypeWorkPermit => 'Work permit';

  @override
  String get renewalTypeOther => 'Other';

  @override
  String get costEstimateTitle => 'Cost & Risk Estimator';

  @override
  String get costEstimateSubtitle =>
      'Get a rough idea of what a case might cost, how long it could take, and whether it is worth pursuing.';

  @override
  String get costEstimateCaseTypeLabel => 'Type of case';

  @override
  String get costEstimateCaseTypeHint =>
      'e.g. unpaid invoice, wrongful dismissal, deposit dispute';

  @override
  String get costEstimateJurisdictionLabel => 'Jurisdiction';

  @override
  String get costEstimateAmountLabel => 'Amount in dispute (optional)';

  @override
  String get costEstimateAmountHint => 'e.g. 12500';

  @override
  String get costEstimateDescriptionLabel =>
      'Briefly describe the situation (optional)';

  @override
  String get costEstimateB2bToggle => 'Lead-qualification card (B2B)';

  @override
  String get costEstimateB2bSubtitle =>
      'Compact output for quickly triaging an inbound client.';

  @override
  String get costEstimateSubmit => 'Estimate my case';

  @override
  String get costEstimateDisclaimer =>
      'Rough estimate only — not a prediction, guarantee, or legal advice. Actual costs and outcomes vary case by case.';

  @override
  String get costEstimateCostsHeading => 'Estimated costs';

  @override
  String get costEstimateCourtFee => 'Court / state fee';

  @override
  String get costEstimateLawyerFee => 'Lawyer fee';

  @override
  String get costEstimateTotal => 'Total (approx.)';

  @override
  String get costEstimateDuration => 'Time to first resolution';

  @override
  String get costEstimateMonthsSuffix => 'months';

  @override
  String get costEstimateFactorsFor => 'In your favour';

  @override
  String get costEstimateFactorsAgainst => 'Working against you';

  @override
  String get costEstimateStrengthWorth => 'Likely worth pursuing';

  @override
  String get costEstimateStrengthContested => 'Contested — could go either way';

  @override
  String get costEstimateStrengthWeak => 'Weak — proceed with caution';

  @override
  String get deadlineIcsCopied => 'ICS copied to clipboard';

  @override
  String get deadlineExportFailed => 'Could not export calendar event';

  @override
  String get orgSlugAvailable => 'Slug is available';

  @override
  String get orgSlugTaken => 'Slug is taken';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonRemove => 'Remove';

  @override
  String get orgRemoveFromOrg => 'Remove from org';

  @override
  String get orgInvitationResent => 'Invitation resent';

  @override
  String get commonResend => 'Resend';

  @override
  String get commonRevoke => 'Revoke';

  @override
  String get vaultUploadSuccess => 'Document uploaded successfully';

  @override
  String get vaultView => 'View';

  @override
  String get vaultPathNotFound => 'Document path not found';

  @override
  String get vaultUrlFailed => 'Could not generate document URL';
}
