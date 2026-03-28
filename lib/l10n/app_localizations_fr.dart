// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Advocat — Outil d’information juridique';

  @override
  String get onboardingTitle1 => 'Information juridique par IA';

  @override
  String get onboardingDesc1 =>
      'Advocat vous aide à comprendre votre situation juridique. Les outils d’IA analysent les documents, identifient les problèmes potentiels et préparent des projets de documents pour votre examen. Ce n’est pas un cabinet d’avocats — c’est un outil technologique pour soutenir votre dossier.';

  @override
  String get onboardingTitle2 => 'Numérisez et analysez des documents';

  @override
  String get onboardingDesc2 =>
      'Photographiez n’importe quel document juridique. L’IA le lit en plusieurs langues, extrait les données clés et vérifie la conformité avec les directives de l’UE et les lois nationales.';

  @override
  String get onboardingTitle3 => 'L’IA vérifie les problèmes potentiels';

  @override
  String get onboardingDesc3 =>
      'Nos outils d’IA vérifient plus de 40 types d’exigences procédurales. L’analyse IA peut identifier des problèmes nécessitant une attention — comme la langue de signification, les étapes procédurales et les délais légaux. Vérifiez toujours auprès d’un avocat qualifié.';

  @override
  String get onboardingTitle4 => 'Projets de documents pour votre examen';

  @override
  String get onboardingDesc4 =>
      'L’IA prépare des projets d’appels, de plaintes et de lettres avec des références juridiques pour votre examen. C’est vous qui décidez quoi soumettre. Chaque document doit être revu par un professionnel du droit qualifié avant dépôt.';

  @override
  String get onboardingNext => 'Suivant';

  @override
  String get onboardingSkip => 'Passer';

  @override
  String get getStarted => 'Commencer';

  @override
  String get welcomeBack => 'Bon retour';

  @override
  String get signInSubtitle => 'Connectez-vous pour accéder à vos dossiers';

  @override
  String get signIn => 'Se connecter';

  @override
  String get logIn => 'Se connecter';

  @override
  String get signUp => 'Créer un compte';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get fullName => 'Nom complet';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get orDivider => 'ou';

  @override
  String get continueWithGoogle => 'Continuer avec Google';

  @override
  String get noAccount => 'Pas de compte ? ';

  @override
  String get signUpLink => 'S’inscrire';

  @override
  String get alreadyHaveAccount => 'Déjà un compte ? ';

  @override
  String get signInLink => 'Se connecter';

  @override
  String get emailRequired => 'L’e-mail est obligatoire';

  @override
  String get emailInvalid => 'Veuillez entrer une adresse e-mail valide';

  @override
  String get passwordRequired => 'Le mot de passe est obligatoire';

  @override
  String get passwordTooShort =>
      'Le mot de passe doit comporter au moins 8 caractères';

  @override
  String get passwordsDoNotMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get nameRequired => 'Le nom complet est obligatoire';

  @override
  String get termsRequired =>
      'Vous devez accepter les Conditions d’utilisation';

  @override
  String get agreeToTerms => 'J’accepte les ';

  @override
  String get termsOfService => 'Conditions d’utilisation';

  @override
  String get andWord => ' et ';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get preferredLanguage => 'Langue préférée';

  @override
  String get langEnglish => 'Anglais';

  @override
  String get langRussian => 'Russe';

  @override
  String get langFinnish => 'Finnois';

  @override
  String get passwordStrengthWeak => 'Faible';

  @override
  String get passwordStrengthMedium => 'Moyen';

  @override
  String get passwordStrengthStrong => 'Fort';

  @override
  String get loginFailed =>
      'E-mail ou mot de passe invalide. Veuillez réessayer.';

  @override
  String get registerFailed => 'Échec de l’inscription. Veuillez réessayer.';

  @override
  String get resetPasswordSent =>
      'Lien de réinitialisation envoyé à votre e-mail.';

  @override
  String get resetPasswordFailed =>
      'Échec de l’envoi du lien. Veuillez réessayer.';

  @override
  String get myCases => 'Mes dossiers';

  @override
  String get newCase => 'Nouveau dossier';

  @override
  String get noCases => 'Aucun dossier pour l’instant';

  @override
  String get documents => 'Documents';

  @override
  String get timeline => 'Chronologie';

  @override
  String get aiAssistant => 'Assistant juridique IA';

  @override
  String get settings => 'Paramètres';

  @override
  String get language => 'Langue';

  @override
  String get subscription => 'Abonnement';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get disclaimer =>
      'Orientation IA uniquement — pas un avis juridique. Consultez toujours un avocat.';

  @override
  String get scanDocument => 'Numériser un document';

  @override
  String get camera => 'Appareil photo';

  @override
  String get gallery => 'Galerie';

  @override
  String get saveAndAnalyze => 'Enregistrer et analyser';

  @override
  String get retry => 'Réessayer';

  @override
  String get cancel => 'Annuler';

  @override
  String get confirm => 'Confirmer';

  @override
  String get error => 'Erreur';

  @override
  String get loading => 'Chargement...';

  @override
  String get home => 'Accueil';

  @override
  String get cases => 'Dossiers';

  @override
  String get deadlines => 'Délais';

  @override
  String get scan => 'Numériser';

  @override
  String goodMorning(String name) {
    return 'Bonjour, $name';
  }

  @override
  String goodAfternoon(String name) {
    return 'Bon après-midi, $name';
  }

  @override
  String goodEvening(String name) {
    return 'Bonsoir, $name';
  }

  @override
  String get caseOverview => 'Voici l’aperçu de vos dossiers';

  @override
  String get activeCases => 'Dossiers actifs';

  @override
  String get recentActivity => 'Activité récente';

  @override
  String urgentDeadline(String title) {
    return 'Urgent : $title';
  }

  @override
  String daysRemaining(int count) {
    return '$count jours';
  }

  @override
  String get overdue => 'En retard';

  @override
  String get upcoming => 'À venir';

  @override
  String get completed => 'Terminé';

  @override
  String get markComplete => 'Marquer comme terminé';

  @override
  String get deportation => 'Déportation';

  @override
  String get criminalCase => 'Affaire pénale';

  @override
  String get asylum => 'Asile';

  @override
  String get residencePermit => 'Permis de séjour';

  @override
  String get victimSupport => 'Aide aux victimes';

  @override
  String get familyReunification => 'Regroupement familial';

  @override
  String get laborDispute => 'Conflit du travail';

  @override
  String get tenantRights => 'Droits du locataire';

  @override
  String get debtCollection => 'Recouvrement de créances';

  @override
  String get discrimination => 'Discrimination';

  @override
  String get policeMisconduct => 'Abus policier';

  @override
  String get socialBenefits => 'Prestations sociales';

  @override
  String get other => 'Autre';

  @override
  String get caseDetail => 'Détails du dossier';

  @override
  String get aiAnalysis => 'Analyse IA';

  @override
  String get draftAppeal => 'Projet d’appel';

  @override
  String get aiChat => 'Chat IA';

  @override
  String get correspondence => 'Correspondance';

  @override
  String get analyzing => 'Analyse en cours...';

  @override
  String get readingDocument => 'Lecture du document...';

  @override
  String get checkingErrors => 'Vérification des erreurs...';

  @override
  String get researchingLaw => 'Recherche du droit applicable...';

  @override
  String issuesFound(int count) {
    return '$count problèmes trouvés';
  }

  @override
  String get critical => 'Critique';

  @override
  String get important => 'Important';

  @override
  String get informational => 'Informatif';

  @override
  String get useInAppeal => 'Utiliser dans l’appel';

  @override
  String get addedToAppeal => 'Ajouté à l’appel';

  @override
  String get generateAppeal => 'Générer l’appel';

  @override
  String get exportPdf => 'Exporter en PDF';

  @override
  String get sendViaEmail => 'Envoyer par e-mail';

  @override
  String get copyText => 'Copier le texte';

  @override
  String get editDraft => 'Éditer';

  @override
  String get saveDraft => 'Enregistrer';

  @override
  String get reviewWarning =>
      'Vérifiez attentivement avant d’envoyer. Vous êtes responsable du contenu.';

  @override
  String get disclaimerFull =>
      'Ceci est un assistant IA, pas un avocat. L’analyse IA peut contenir des erreurs. Vérifiez toujours auprès d’un professionnel du droit qualifié.';

  @override
  String get askAboutCase => 'Analyser mon dossier';

  @override
  String get whatAreMyOptions => 'Quelles sont mes options ?';

  @override
  String get checkDeadlines => 'Vérifier les délais';

  @override
  String get typeMessage => 'Écrivez un message...';

  @override
  String get connectEmail => 'Connecter l’e-mail';

  @override
  String get connectGmail => 'Connecter Gmail';

  @override
  String get connectOutlook => 'Connecter Outlook';

  @override
  String get emailConnected => 'E-mail connecté';

  @override
  String get syncNow => 'Synchroniser maintenant';

  @override
  String get disconnect => 'Déconnecter';

  @override
  String get emailPrivacyNote =>
      'Nous ne lisons que les e-mails liés aux affaires juridiques. Vos e-mails personnels restent privés.';

  @override
  String get pushNotifications => 'Notifications push';

  @override
  String get deadlineReminders => 'Rappels de délais';

  @override
  String get deadlineRemindersDesc =>
      'Recevez des notifications avant les délais';

  @override
  String get editProfile => 'Modifier le profil';

  @override
  String get exportMyData => 'Exporter mes données';

  @override
  String get exportDataDesc => 'Télécharger toutes les données de vos dossiers';

  @override
  String get deleteAccount => 'Supprimer le compte';

  @override
  String get deleteAccountDesc => 'Supprimer définitivement votre compte';

  @override
  String get deleteConfirm =>
      'Êtes-vous sûr ? Cela supprimera définitivement toutes vos données.';

  @override
  String get about => 'À propos';

  @override
  String get version => 'Version';

  @override
  String get rateUs => 'Évaluez-nous';

  @override
  String get contactSupport => 'Contacter le support';

  @override
  String get tryDemoMode => 'Essayer le mode démo';

  @override
  String get demoModeDesc =>
      'Explorez l’application avec des données d’exemple d’un cas réel';

  @override
  String get free => 'Gratuit';

  @override
  String get basic => 'Basique';

  @override
  String get pro => 'Pro';

  @override
  String get emergencyShield => 'Bouclier d’urgence';

  @override
  String get legalFighter => 'Combattant juridique';

  @override
  String get fullDefense => 'Défense complète';

  @override
  String get popular => 'POPULAIRE';

  @override
  String get currentPlan => 'Plan actuel';

  @override
  String get choosePlan => 'Choisir un plan';

  @override
  String get saveWithAnnual => 'Économisez 25% avec la facturation annuelle';

  @override
  String get restorePurchases => 'Restaurer les achats';

  @override
  String get country => 'Pays';

  @override
  String get caseDescription => 'Décrivez votre situation';

  @override
  String get caseTitle => 'Titre du dossier';

  @override
  String get referenceNumber => 'Numéro de référence';

  @override
  String get uploadDocument => 'Télécharger un document';

  @override
  String get optional => '(facultatif)';

  @override
  String step(int current, int total) {
    return 'Étape $current sur $total';
  }

  @override
  String get next => 'Suivant';

  @override
  String get back => 'Retour';

  @override
  String get createCase => 'Créer un dossier';

  @override
  String get searchCases => 'Rechercher des dossiers...';

  @override
  String get all => 'Tous';

  @override
  String get active => 'Actifs';

  @override
  String get closed => 'Clos';

  @override
  String lastActivity(String time) {
    return 'Dernière activité : $time';
  }

  @override
  String documentsCount(int count) {
    return '$count docs';
  }

  @override
  String get noCasesYet => 'Aucun dossier pour l’instant';

  @override
  String get startFirstCase => 'Commencez votre premier dossier';

  @override
  String get noDeadlines => 'Aucun délai — tout est en ordre !';

  @override
  String get appealFiled => 'Appel déposé';

  @override
  String get pendingDecision => 'Décision en attente';

  @override
  String get inProgress => 'En cours';

  @override
  String get won => 'Gagné';

  @override
  String get lost => 'Perdu';

  @override
  String get preferences => 'PRÉFÉRENCES';

  @override
  String get notifications => 'NOTIFICATIONS';

  @override
  String get emailIntegration => 'INTÉGRATION E-MAIL';

  @override
  String get dataAndPrivacy => 'DONNÉES ET CONFIDENTIALITÉ';

  @override
  String get legalSection => 'JURIDIQUE';

  @override
  String get aboutSection => 'À PROPOS';

  @override
  String get appVersion => 'Version de l’application';

  @override
  String get selectLanguage => 'Sélectionner la langue';

  @override
  String get signOutConfirm => 'Êtes-vous sûr de vouloir vous déconnecter ?';

  @override
  String get emailDisconnected => 'E-mail déconnecté';

  @override
  String get syncLegalCorrespondence =>
      'Synchroniser la correspondance juridique';

  @override
  String get requestExport => 'Demander l’exportation';

  @override
  String get exportDataDialogContent =>
      'Nous préparerons un téléchargement de toutes vos données, y compris les dossiers, documents et correspondance. Vous recevrez un e-mail lorsque ce sera prêt.';

  @override
  String get deleteAccountDialogContent =>
      'Cette action est permanente et irréversible. Toutes vos données, dossiers et documents seront définitivement supprimés.';

  @override
  String get areYouAbsolutelySure => 'Êtes-vous absolument sûr ?';

  @override
  String get typeDeleteToConfirm =>
      'Tapez DELETE pour confirmer la suppression définitive du compte.';

  @override
  String get permanentlyDelete => 'Supprimer définitivement';

  @override
  String get dataExportRequested =>
      'Exportation des données demandée. Vérifiez votre e-mail.';

  @override
  String get connected => 'Connecté';

  @override
  String get caseUpdated => 'Dossier mis à jour';

  @override
  String get noRecentActivity => 'Aucune activité récente';

  @override
  String get couldNotLoadCases => 'Impossible de charger vos dossiers';

  @override
  String get viewAll => 'Voir tout';
}
