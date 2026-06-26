// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get about => 'À propos';

  @override
  String get aboutSection => 'À PROPOS';

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
  String get active => 'Actifs';

  @override
  String get activeCases => 'Dossiers actifs';

  @override
  String get addedToAppeal => 'Ajouté à l’appel';

  @override
  String get agreeToTerms => 'J’accepte les ';

  @override
  String get aiAnalysis => 'Analyse IA';

  @override
  String get aiAssistant => 'Assistant juridique IA';

  @override
  String get aiChat => 'Chat IA';

  @override
  String get all => 'Tous';

  @override
  String get alreadyHaveAccount => 'Déjà un compte ? ';

  @override
  String get analyzing => 'Analyse en cours…';

  @override
  String get aiAnalyzing => 'L\'IA analyse';

  @override
  String get speakIntoMicHint =>
      'Parlez dans le microphone. Assurez-vous que l\'accès au microphone est activé.';

  @override
  String get aiErrorRateLimit =>
      'Le service est temporairement surchargé. Veuillez réessayer dans 1 à 2 minutes.';

  @override
  String get aiErrorOverload =>
      'L\'IA est occupée pour le moment, veuillez réessayer dans une minute.';

  @override
  String freeLimitReached(int count) {
    return 'Vous avez utilisé l\'ensemble de vos $count messages IA gratuits. Passez à Legal Counsel pour une assistance IA illimitée !';
  }

  @override
  String get andWord => ' et ';

  @override
  String get appTitle => 'Advocat — Outil d’information juridique';

  @override
  String get appVersion => 'Version de l’application';

  @override
  String get appealFiled => 'Appel déposé';

  @override
  String get areYouAbsolutelySure => 'Êtes-vous absolument sûr ?';

  @override
  String get askAboutCase => 'Analyser mon dossier';

  @override
  String get asylum => 'Asile';

  @override
  String get back => 'Retour';

  @override
  String get basic => 'Basique';

  @override
  String get beforeYouBuy => 'Avant d’acheter';

  @override
  String get beforeYouWork => 'Avant de travailler avec eux';

  @override
  String get camera => 'Appareil photo';

  @override
  String get cancel => 'Annuler';

  @override
  String get caseDescription => 'Décrivez votre situation';

  @override
  String get caseDetail => 'Détails du dossier';

  @override
  String get caseOverview => 'Voici l’aperçu de vos dossiers';

  @override
  String get caseTitle => 'Titre du dossier';

  @override
  String get caseUpdated => 'Dossier mis à jour';

  @override
  String get cases => 'Dossiers';

  @override
  String get checkCompany => 'Vérifier l’entreprise';

  @override
  String get checkDeadlines => 'Vérifier les délais';

  @override
  String get checkVehicle => 'Vérifier le véhicule';

  @override
  String get checkerTitle => 'Vérificateur';

  @override
  String get checkingErrors => 'Vérification des erreurs…';

  @override
  String get choosePlan => 'Choisir un plan';

  @override
  String get closed => 'Clos';

  @override
  String get companyName => 'Nom ou n° d’enregistrement';

  @override
  String get completed => 'Terminé';

  @override
  String get confirm => 'Confirmer';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get connectEmail => 'Connecter l’e-mail';

  @override
  String get connectGmail => 'Connecter Gmail';

  @override
  String get connectOutlook => 'Connecter Outlook';

  @override
  String get connected => 'Connecté';

  @override
  String get contactSupport => 'Contacter le support';

  @override
  String get continueWithGoogle => 'Continuer avec Google';

  @override
  String get appleComingSoon => 'Bientôt disponible';

  @override
  String get appleComingSoonMessage =>
      'La connexion avec Apple sera bientôt disponible. Utilisez Google ou votre adresse e-mail pour continuer.';

  @override
  String get copyText => 'Copier le texte';

  @override
  String get correspondence => 'Correspondance';

  @override
  String get couldNotLoadCases => 'Impossible de charger vos dossiers';

  @override
  String get country => 'Pays';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get createCase => 'Créer un dossier';

  @override
  String get criminalCase => 'Affaire pénale';

  @override
  String get critical => 'Critique';

  @override
  String get currentPlan => 'Plan actuel';

  @override
  String get dataAndPrivacy => 'DONNÉES ET CONFIDENTIALITÉ';

  @override
  String get dataExportRequested =>
      'Exportation des données demandée. Vérifiez votre e-mail.';

  @override
  String daysRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '1 jour',
      zero: 'aucun jour restant',
    );
    return '$_temp0';
  }

  @override
  String get deadlineReminders => 'Rappels de délais';

  @override
  String get deadlineRemindersDesc =>
      'Recevez des notifications avant les délais';

  @override
  String get deadlines => 'Délais';

  @override
  String get debtCollection => 'Recouvrement de créances';

  @override
  String get deleteAccount => 'Supprimer le compte';

  @override
  String get deleteAccountDesc => 'Supprimer définitivement votre compte';

  @override
  String get deleteAccountDialogContent =>
      'Cette action est permanente et irréversible. Toutes vos données, dossiers et documents seront définitivement supprimés.';

  @override
  String get deleteConfirm =>
      'Êtes-vous sûr ? Cela supprimera définitivement toutes vos données.';

  @override
  String get demoHint => 'Démo : essayez la plaque « 908FBT »';

  @override
  String get demoModeDesc =>
      'Explorez l’application avec des données d’exemple d’un cas réel';

  @override
  String get deportation => 'Déportation';

  @override
  String get disclaimer =>
      'Orientation IA uniquement — pas un avis juridique. Consultez toujours un avocat.';

  @override
  String get disclaimerFull =>
      'Ceci est un assistant IA, pas un avocat. L’analyse IA peut contenir des erreurs. Vérifiez toujours auprès d’un professionnel du droit qualifié.';

  @override
  String get disconnect => 'Déconnecter';

  @override
  String get discrimination => 'Discrimination';

  @override
  String get doNotBuy => 'Ne pas acheter';

  @override
  String get documents => 'Documents';

  @override
  String documentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documents',
      one: '1 document',
      zero: 'aucun document',
    );
    return '$_temp0';
  }

  @override
  String get draftAppeal => 'Projet d’appel';

  @override
  String get editDraft => 'Éditer';

  @override
  String get editProfile => 'Modifier le profil';

  @override
  String get email => 'E-mail';

  @override
  String get emailConnected => 'E-mail connecté';

  @override
  String get emailDisconnected => 'E-mail déconnecté';

  @override
  String get emailIntegration => 'INTÉGRATION E-MAIL';

  @override
  String get emailInvalid => 'Veuillez entrer une adresse e-mail valide';

  @override
  String get emailPrivacyNote =>
      'Nous ne lisons que les e-mails liés aux affaires juridiques. Vos e-mails personnels restent privés.';

  @override
  String get emailRequired => 'L’e-mail est obligatoire';

  @override
  String get emergencyShield => 'Bouclier d’urgence';

  @override
  String get error => 'Erreur';

  @override
  String get exportDataDesc => 'Télécharger toutes les données de vos dossiers';

  @override
  String get exportDataDialogContent =>
      'Nous préparerons un téléchargement de toutes vos données, y compris les dossiers, documents et correspondance. Vous recevrez un e-mail lorsque ce sera prêt.';

  @override
  String get exportMyData => 'Exporter mes données';

  @override
  String get exportPdf => 'Exporter en PDF';

  @override
  String get familyReunification => 'Regroupement familial';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get free => 'Gratuit';

  @override
  String get fullDefense => 'Advocat Pro';

  @override
  String get fullName => 'Nom complet';

  @override
  String get gallery => 'Galerie';

  @override
  String get generateAppeal => 'Générer l’appel';

  @override
  String get getStarted => 'Commencer';

  @override
  String goodAfternoon(String name) {
    return 'Bon après-midi, $name';
  }

  @override
  String goodEvening(String name) {
    return 'Bonsoir, $name';
  }

  @override
  String goodMorning(String name) {
    return 'Bonjour, $name';
  }

  @override
  String goodNight(String name) {
    return 'Bonne nuit, $name';
  }

  @override
  String get home => 'Accueil';

  @override
  String get important => 'Important';

  @override
  String get inProgress => 'En cours';

  @override
  String get informational => 'Informatif';

  @override
  String get inspection => 'Contrôle technique';

  @override
  String get insurance => 'Assurance';

  @override
  String issuesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count problèmes trouvés',
      one: '1 problème trouvé',
      zero: 'aucun problème trouvé',
    );
    return '$_temp0';
  }

  @override
  String get laborDispute => 'Conflit du travail';

  @override
  String get langEnglish => 'Anglais';

  @override
  String get langFinnish => 'Finnois';

  @override
  String get langRussian => 'Russe';

  @override
  String get language => 'Langue';

  @override
  String lastActivity(String time) {
    return 'Dernière activité : $time';
  }

  @override
  String get legalFighter => 'Conseil juridique';

  @override
  String get legalSection => 'JURIDIQUE';

  @override
  String get licensePlate => 'Plaque d’immatriculation';

  @override
  String get loading => 'Chargement…';

  @override
  String get logIn => 'Se connecter';

  @override
  String get loginFailed =>
      'E-mail ou mot de passe invalide. Veuillez réessayer.';

  @override
  String get lost => 'Perdu';

  @override
  String get markComplete => 'Marquer comme terminé';

  @override
  String get mileage => 'Kilométrage';

  @override
  String get myCases => 'Mes dossiers';

  @override
  String get nameRequired => 'Le nom complet est obligatoire';

  @override
  String get newCase => 'Nouveau dossier';

  @override
  String get next => 'Suivant';

  @override
  String get noAccount => 'Pas de compte ? ';

  @override
  String get noCases => 'Aucun dossier pour l’instant';

  @override
  String get noCasesYet => 'Aucun dossier pour l’instant';

  @override
  String get noDeadlines => 'Aucun délai — tout est en ordre !';

  @override
  String get noRecentActivity => 'Aucune activité récente';

  @override
  String get notifications => 'NOTIFICATIONS';

  @override
  String get onboardingDesc1 =>
      'Advocat vous aide à comprendre votre situation juridique. Les outils d’IA analysent les documents, identifient les problèmes potentiels et préparent des projets de documents pour votre examen. Ce n’est pas un cabinet d’avocats — c’est un outil technologique pour soutenir votre dossier.';

  @override
  String get onboardingDesc2 =>
      'Photographiez n’importe quel document juridique. L’IA le lit en plusieurs langues, extrait les données clés et vérifie la conformité avec les directives de l’UE et les lois nationales.';

  @override
  String get onboardingDesc3 =>
      'Nos outils d’IA vérifient plus de 40 types d’exigences procédurales. L’analyse IA peut identifier des problèmes nécessitant une attention — comme la langue de signification, les étapes procédurales et les délais légaux. Vérifiez toujours auprès d’un avocat qualifié.';

  @override
  String get onboardingDesc4 =>
      'L’IA prépare des projets d’appels, de plaintes et de lettres avec des références juridiques pour votre examen. C’est vous qui décidez quoi soumettre. Chaque document doit être revu par un professionnel du droit qualifié avant dépôt.';

  @override
  String get onboardingNext => 'Suivant';

  @override
  String get onboardingSkip => 'Passer';

  @override
  String get onboardingTitle1 => 'Information juridique par IA';

  @override
  String get onboardingTitle2 => 'Numérisez et analysez des documents';

  @override
  String get onboardingTitle3 => 'L’IA vérifie les problèmes potentiels';

  @override
  String get onboardingTitle4 => 'Projets de documents pour votre examen';

  @override
  String get openACase => 'Ouvrir un dossier';

  @override
  String get optional => '(facultatif)';

  @override
  String get orDivider => 'ou';

  @override
  String get other => 'Autre';

  @override
  String get overdue => 'En retard';

  @override
  String get owners => 'Propriétaires précédents';

  @override
  String get password => 'Mot de passe';

  @override
  String get passwordRequired => 'Le mot de passe est obligatoire';

  @override
  String get passwordStrengthMedium => 'Moyen';

  @override
  String get passwordStrengthStrong => 'Fort';

  @override
  String get passwordStrengthWeak => 'Faible';

  @override
  String get passwordTooShort =>
      'Le mot de passe doit comporter au moins 8 caractères';

  @override
  String get passwordsDoNotMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get pendingDecision => 'Décision en attente';

  @override
  String get perCheck => 'par vérification';

  @override
  String get permanentlyDelete => 'Supprimer définitivement';

  @override
  String get policeMisconduct => 'Abus policier';

  @override
  String get popular => 'POPULAIRE';

  @override
  String get preferences => 'PRÉFÉRENCES';

  @override
  String get preferredLanguage => 'Langue préférée';

  @override
  String get pricePerCheck => '4,99 € par vérification';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get dpaTitle => 'Accord de traitement des données';

  @override
  String get dpaCheckoutGateTitle => 'Avant de passer à l\'offre supérieure';

  @override
  String get dpaCheckoutGateBody =>
      'Le droit de l\'UE (article 28 du RGPD) nous impose de signer un accord de traitement des données avec chaque client payant. Veuillez le consulter et l\'accepter.';

  @override
  String get dpaViewLink => 'Consulter l\'accord de traitement des données';

  @override
  String get dpaCheckboxLabel =>
      'J\'ai lu et j\'accepte l\'accord de traitement des données (v1.0).';

  @override
  String get dpaCancel => 'Annuler';

  @override
  String get dpaAcceptAndContinue => 'Accepter et continuer';

  @override
  String get dpaOpenHint =>
      'Ouvrez l\'accord de traitement des données au moins une fois pour activer le bouton Accepter.';

  @override
  String get pro => 'Pro';

  @override
  String get pushNotifications => 'Notifications push';

  @override
  String get rateUs => 'Évaluez-nous';

  @override
  String get rateAppComingSoon =>
      'Bientôt disponible sur les boutiques d\'applications !';

  @override
  String get dataCopiedToClipboard => 'Données copiées dans le presse-papiers';

  @override
  String get readingDocument => 'Lecture du document…';

  @override
  String get recentActivity => 'Activité récente';

  @override
  String get referenceNumber => 'Numéro de référence';

  @override
  String get registerFailed => 'Échec de l’inscription. Veuillez réessayer.';

  @override
  String get reportFraud => 'Signaler une fraude';

  @override
  String get requestExport => 'Demander l’exportation';

  @override
  String get researchingLaw => 'Recherche du droit applicable…';

  @override
  String get resetPasswordFailed =>
      'Échec de l’envoi du lien. Veuillez réessayer.';

  @override
  String get resetPasswordSent =>
      'Lien de réinitialisation envoyé à votre e-mail.';

  @override
  String get residencePermit => 'Permis de séjour';

  @override
  String get manageSubscription => 'Gérer l\'abonnement';

  @override
  String get restorePurchases => 'Restaurer les achats';

  @override
  String get retry => 'Réessayer';

  @override
  String get reviewWarning =>
      'Vérifiez attentivement avant d’envoyer. Vous êtes responsable du contenu.';

  @override
  String get riskHigh => 'Risque élevé — éviter';

  @override
  String get riskLow => 'Sûr pour collaborer';

  @override
  String get riskMedium => 'Procéder avec prudence';

  @override
  String get safeToBuy => 'Sûr à acheter';

  @override
  String get saveAndAnalyze => 'Enregistrer et analyser';

  @override
  String get saveDraft => 'Enregistrer';

  @override
  String get saveWithAnnual => 'Économisez 25% avec la facturation annuelle';

  @override
  String get scan => 'Numériser';

  @override
  String get scanDocument => 'Numériser un document';

  @override
  String get searchCases => 'Rechercher des dossiers…';

  @override
  String get selectCountry => 'Sélectionner le pays';

  @override
  String get selectLanguage => 'Sélectionner la langue';

  @override
  String get sendViaEmail => 'Envoyer par e-mail';

  @override
  String get settings => 'Paramètres';

  @override
  String get signIn => 'Se connecter';

  @override
  String get signInLink => 'Se connecter';

  @override
  String get signInSubtitle => 'Connectez-vous pour accéder à vos dossiers';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get signOutConfirm => 'Êtes-vous sûr de vouloir vous déconnecter ?';

  @override
  String get signUp => 'Créer un compte';

  @override
  String get signUpLink => 'S’inscrire';

  @override
  String get socialBenefits => 'Prestations sociales';

  @override
  String get someConcerns => 'Quelques préoccupations';

  @override
  String get startFirstCase => 'Commencez votre premier dossier';

  @override
  String step(int current, int total) {
    return 'Étape $current sur $total';
  }

  @override
  String get stolen => 'Vérification de vol';

  @override
  String get subscription => 'Abonnement';

  @override
  String get syncLegalCorrespondence =>
      'Synchroniser la correspondance juridique';

  @override
  String get syncNow => 'Synchroniser maintenant';

  @override
  String get tenantRights => 'Droits du locataire';

  @override
  String get termsOfService => 'Conditions d’utilisation';

  @override
  String get termsRequired =>
      'Vous devez accepter les Conditions d’utilisation';

  @override
  String get timeline => 'Chronologie';

  @override
  String get tryDemoMode => 'Essayer le mode démo';

  @override
  String get typeDeleteToConfirm =>
      'Tapez DELETE pour confirmer la suppression définitive du compte.';

  @override
  String get typeMessage => 'Écrivez un message…';

  @override
  String get upcoming => 'À venir';

  @override
  String get uploadDocument => 'Télécharger un document';

  @override
  String urgentDeadline(String title) {
    return 'Urgent : $title';
  }

  @override
  String get useInAppeal => 'Utiliser dans l’appel';

  @override
  String get vehicleChecker => 'Vérificateur de véhicules';

  @override
  String get vehicleChecks => 'Vérifications d\'état';

  @override
  String get vehicleColor => 'Couleur';

  @override
  String get vehicleMake => 'Marque';

  @override
  String get vehicleModel => 'Modèle';

  @override
  String get vehicleYear => 'Année';

  @override
  String get version => 'Version';

  @override
  String get victimSupport => 'Aide aux victimes';

  @override
  String get viewAll => 'Voir tout';

  @override
  String get vinNumber => 'Numéro VIN';

  @override
  String get welcomeBack => 'Bon retour';

  @override
  String get whatAreMyOptions => 'Quelles sont mes options ?';

  @override
  String get won => 'Gagné';

  @override
  String get documentVault => 'Coffre-fort de documents';

  @override
  String get secureDocumentStorage => 'Stockage sécurisé de documents';

  @override
  String get secureDocumentStorageDesc =>
      'Conservez vos documents juridiques importants en un seul endroit pour un accès facile.';

  @override
  String get addDocument => 'Ajouter un document';

  @override
  String get chooseHowToAdd => 'Choisissez comment ajouter votre document';

  @override
  String get uploadFile => 'Télécharger un fichier';

  @override
  String get uploadFileDesc =>
      'Choisissez un PDF ou une image de votre appareil';

  @override
  String get scanDocumentDesc => 'Prenez une photo de votre document';

  @override
  String get createNote => 'Créer une note';

  @override
  String get createNoteDesc =>
      'Rédigez une note ou enregistrez des détails importants';

  @override
  String get knowYourRights => 'Connaissez vos droits';

  @override
  String get stoppedByPolice => 'Contrôle de police';

  @override
  String get stoppedByPoliceDesc => 'Vos droits lors d\'un contrôle de police';

  @override
  String get deportationNotice => 'Avis d\'expulsion';

  @override
  String get deportationNoticeDesc =>
      'Étapes pour contester un arrêté d\'expulsion';

  @override
  String get workplaceRights => 'Droits au travail';

  @override
  String get workplaceRightsDesc =>
      'Protections du droit du travail en Finlande';

  @override
  String get tenantRightsDesc =>
      'Protections en matière de logement et de location';

  @override
  String get immigrationDetention => 'Rétention administrative';

  @override
  String get immigrationDetentionDesc =>
      'Droits en cas de détention par les autorités';

  @override
  String get discriminationDesc =>
      'Comment signaler et combattre la discrimination';

  @override
  String get scenarioNotFound => 'Scénario non trouvé';

  @override
  String get youHaveRightTo => 'Vous avez le droit de :';

  @override
  String get youMust => 'Vous devez :';

  @override
  String get immediateSteps => 'Étapes immédiates :';

  @override
  String get yourRights => 'Vos droits :';

  @override
  String get basicRights => 'Droits fondamentaux :';

  @override
  String get yourRightsAsTenant => 'Vos droits en tant que locataire :';

  @override
  String get yourRightsInDetention => 'Vos droits en détention :';

  @override
  String get howToAct => 'Comment agir :';

  @override
  String get rightKnowWhyStopped => 'Savoir pourquoi vous êtes contrôlé';

  @override
  String get rightRemainSilent =>
      'Garder le silence (vous devez vous identifier)';

  @override
  String get rightAskInterpreter => 'Demander un interprète';

  @override
  String get rightContactLawyer =>
      'Contacter un avocat avant l\'interrogatoire';

  @override
  String get rightRecordEncounter =>
      'Enregistrer la rencontre (dans les lieux publics)';

  @override
  String get mustProvideName => 'Donnez votre nom et date de naissance';

  @override
  String get mustShowId =>
      'Montrez votre pièce d\'identité si vous en avez une';

  @override
  String get mustNotResist => 'Ne pas résister physiquement';

  @override
  String get doNotIgnoreNotice =>
      'N\'ignorez PAS l\'avis - les délais sont stricts';

  @override
  String get noteAppealDeadline =>
      'Notez le délai de recours (généralement 30 jours)';

  @override
  String get contactLawyerImmediately => 'Contactez immédiatement un avocat';

  @override
  String get applyLegalAid => 'Demandez l\'aide juridictionnelle si nécessaire';

  @override
  String get rightAppealAdmin =>
      'Droit de recours devant le tribunal administratif';

  @override
  String get rightLegalRep => 'Droit à une représentation juridique';

  @override
  String get rightInterpreter => 'Droit à un interprète';

  @override
  String get rightStayDuringAppeal =>
      'Droit de rester pendant le recours (dans la plupart des cas)';

  @override
  String get minimumWage => 'Salaire minimum selon la convention collective';

  @override
  String get workingTimeLimits =>
      'Limites du temps de travail (max. 8h/jour, 40h/semaine)';

  @override
  String get annualLeave =>
      'Congés annuels (minimum 2 jours par mois travaillé)';

  @override
  String get sickLeave => 'Indemnités maladie';

  @override
  String get safeWorkingConditions => 'Conditions de travail sûres';

  @override
  String get writtenRentalAgreement => 'Contrat de location écrit obligatoire';

  @override
  String get securityDeposit => 'Dépôt de garantie max. 3 mois de loyer';

  @override
  String get landlordNotice =>
      'Le propriétaire doit donner un préavis (3–6 mois)';

  @override
  String get rightHabitableDwelling => 'Droit à un logement habitable';

  @override
  String get protectionUnjustEviction =>
      'Protection contre l\'expulsion injuste';

  @override
  String get rightKnowDetentionReason =>
      'Droit de connaître la raison de la détention';

  @override
  String get rightContactLawyerDetention => 'Droit de contacter un avocat';

  @override
  String get rightContactEmbassy => 'Droit de contacter votre ambassade';

  @override
  String get rightChallengeDetention =>
      'Droit de contester la détention devant un tribunal';

  @override
  String get rightHumaneTreatment =>
      'Droit à un traitement humain et à des soins médicaux';

  @override
  String get documentIncident =>
      'Documentez l\'incident (date, heure, témoins)';

  @override
  String get fileComplaintOmbudsman =>
      'Déposez une plainte auprès du Médiateur contre la discrimination';

  @override
  String get contactLegalAidOffice =>
      'Contactez un bureau d\'aide juridictionnelle';

  @override
  String get reportToPolice =>
      'Signalez à la police si criminel (menace, agression)';

  @override
  String get legalAidCalculator => 'Calculateur d\'aide juridictionnelle';

  @override
  String checkEligibility(String country) {
    return 'Vérifiez votre éligibilité à l\'aide juridictionnelle: $country';
  }

  @override
  String get estimateDisclaimer =>
      'Ceci n\'est qu\'une estimation. L\'éligibilité réelle est déterminée par le Bureau d\'aide juridictionnelle.';

  @override
  String get monthlyIncome => 'Revenu mensuel (EUR)';

  @override
  String get totalAssets => 'Actifs totaux (EUR)';

  @override
  String get numberOfDependents => 'Nombre de personnes à charge';

  @override
  String get calculateEligibility => 'Calculer l\'éligibilité';

  @override
  String get likelyEligible => 'Probablement éligible';

  @override
  String get mayNotQualify => 'Peut ne pas être éligible';

  @override
  String get fullFreeLegalAid =>
      'Vous êtes probablement éligible à l\'aide juridictionnelle gratuite (sans participation).';

  @override
  String legalAidWithCopay(String percent) {
    return 'Vous pourriez être éligible à l\'aide juridictionnelle avec une participation de $percent%.';
  }

  @override
  String get mayNotQualifyDesc =>
      'Selon cette estimation, vous pourriez ne pas être éligible à l\'aide juridictionnelle. Envisagez de consulter un avocat privé ou une clinique juridique.';

  @override
  String get couldNotLoadDeadlines => 'Impossible de charger les délais';

  @override
  String get noUpcomingDeadlines => 'Aucun délai à venir';

  @override
  String get allClearDeadlines =>
      'Tout est en ordre ! Les nouveaux délais apparaîtront ici lorsqu\'ils seront définis.';

  @override
  String get nothingOverdue => 'Rien en retard';

  @override
  String get greatJobDeadlines => 'Bravo, vous respectez vos délais.';

  @override
  String get noCompletedDeadlines => 'Aucun délai complété';

  @override
  String get completedDeadlinesDesc =>
      'Les délais complétés seront affichés ici.';

  @override
  String get daysLate => 'jours de retard';

  @override
  String get days => 'jours';

  @override
  String get fromDocument => 'Du document';

  @override
  String get couldNotLoadCase => 'Impossible de charger les détails du dossier';

  @override
  String get typeLabel => 'Type';

  @override
  String get nationality => 'Nationalité';

  @override
  String get migriReference => 'Référence Migri';

  @override
  String get courtCaseNo => 'N° d\'affaire';

  @override
  String get created => 'Créé';

  @override
  String get citizenship => 'Citoyenneté';

  @override
  String get workPermit => 'Permis de travail';

  @override
  String get noDocumentsYet => 'Aucun document téléchargé';

  @override
  String get noUpcomingDeadlinesShort => 'Aucun délai à venir';

  @override
  String get caseCreated => 'Dossier créé';

  @override
  String get decisionReceived => 'Décision reçue';

  @override
  String get appealDeadline => 'Délai de recours';

  @override
  String get hearingScheduled => 'Audience programmée';

  @override
  String get late => 'en retard';

  @override
  String get pending => 'En attente';

  @override
  String get processing => 'Traitement en cours';

  @override
  String get ready => 'Prêt';

  @override
  String get failed => 'Échoué';

  @override
  String get analyzed => 'Analysé';

  @override
  String get noDocumentsScanHint =>
      'Pas encore de documents. Numérisez ou téléchargez-en un.';

  @override
  String get inCourt => 'Au tribunal';

  @override
  String get appeal => 'Recours';

  @override
  String get caseTimeline => 'Chronologie du dossier';

  @override
  String get couldNotLoadTimeline => 'Impossible de charger la chronologie';

  @override
  String get noEventsYet => 'Pas encore d\'événements';

  @override
  String get activityWillAppear =>
      'L\'activité apparaîtra ici au fur et à mesure de l\'avancement de votre dossier.';

  @override
  String caseCreatedDesc(String title) {
    return 'Le dossier \"$title\" a été créé.';
  }

  @override
  String get decisionReceivedDesc =>
      'Une décision officielle a été reçue pour ce dossier.';

  @override
  String get appealDeadlineSet => 'Délai de recours défini';

  @override
  String appealDeadlineDesc(String date) {
    return 'Le recours doit être déposé avant le $date.';
  }

  @override
  String hearingScheduledDesc(String date) {
    return 'Audience prévue le $date.';
  }

  @override
  String get caseInfoUpdated =>
      'Les informations du dossier ont été mises à jour.';

  @override
  String get noEventsForFilter => 'Aucun événement ne correspond à ce filtre';

  @override
  String get timelineFilterAll => 'Tout';

  @override
  String get timelineFilterEmails => 'E-mails';

  @override
  String get timelineFilterConsilium => 'Décisions de l\'IA';

  @override
  String get timelineFilterDeadlines => 'Délais';

  @override
  String get timelineFilterNotes => 'Notes';

  @override
  String get timelineEventEmailIn => 'E-mail reçu';

  @override
  String get timelineEventEmailOut => 'E-mail envoyé';

  @override
  String get timelineEventConsiliumDecision => 'Décision de l\'IA';

  @override
  String get timelineEventDeadlineSet => 'Délai';

  @override
  String get timelineEventDocUploaded => 'Document';

  @override
  String get timelineEventPhaseChange => 'Changement de phase';

  @override
  String get timelineEventManualNote => 'Note';

  @override
  String get timelineJustNow => 'À l\'instant';

  @override
  String timelineMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count minutes',
      one: 'il y a 1 minute',
    );
    return '$_temp0';
  }

  @override
  String timelineHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count heures',
      one: 'il y a 1 heure',
    );
    return '$_temp0';
  }

  @override
  String timelineDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count jours',
      one: 'il y a 1 jour',
    );
    return '$_temp0';
  }

  @override
  String get documentAnalysis => 'Analyse de document';

  @override
  String get exportAsPdf => 'Exporter en PDF';

  @override
  String get pdfExportComingSoon => 'Export PDF bientôt disponible';

  @override
  String get analysisFailedRetry => 'L\'analyse a échoué. Veuillez réessayer.';

  @override
  String get somethingWentWrong => 'Une erreur s\'est produite';

  @override
  String get genericError => 'Une erreur est survenue. Veuillez réessayer.';

  @override
  String get retryAnalysis => 'Réessayer l\'analyse';

  @override
  String issuesFoundInDocument(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count problèmes trouvés dans votre document',
      one: '1 problème trouvé dans votre document',
      zero: 'Aucun problème dans votre document',
    );
    return '$_temp0';
  }

  @override
  String get severityOverview => 'Aperçu de la gravité';

  @override
  String get issuesFoundHeader => 'Problèmes trouvés';

  @override
  String generateAppealWithIssues(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Générer un recours ($count problèmes)',
      one: 'Générer un recours (1 problème)',
    );
    return '$_temp0';
  }

  @override
  String get analyzingContent => 'Analyse du contenu…';

  @override
  String get documentProcessedOk => 'Document traité avec succès';

  @override
  String get noSignificantIssues =>
      'Aucun problème significatif détecté dans ce document.';

  @override
  String get cameraPermissionRequired => 'Autorisation caméra requise';

  @override
  String get cameraPermissionDesc =>
      'Accordez l\'accès à la caméra pour numériser des documents ou utilisez la galerie.';

  @override
  String get openSettings => 'Ouvrir les paramètres';

  @override
  String get alignDocument => 'Alignez le document dans le cadre';

  @override
  String pageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages',
      one: '1 page',
      zero: 'aucune page',
    );
    return '$_temp0';
  }

  @override
  String get preview => 'Aperçu';

  @override
  String pageNumber(int number) {
    return 'Page $number';
  }

  @override
  String get done => 'Terminé';

  @override
  String get retake => 'Reprendre';

  @override
  String get useThisPhoto => 'Utiliser cette photo';

  @override
  String get addPage => 'Ajouter une page';

  @override
  String uploadingPercent(int percent) {
    return 'Téléchargement… $percent%';
  }

  @override
  String get preparingUpload => 'Préparation du téléchargement…';

  @override
  String get documentUploadedSuccess => 'Document téléchargé avec succès';

  @override
  String pagesUploadedSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages téléchargées avec succès',
      one: '1 page téléchargée avec succès',
    );
    return '$_temp0';
  }

  @override
  String get uploadFailed =>
      'Échec du téléchargement. Vérifiez votre connexion et réessayez.';

  @override
  String get capturePhotoFailed =>
      'Échec de la capture photo. Veuillez réessayer.';

  @override
  String get readingText => 'Lecture du texte…';

  @override
  String get draftDocument => 'Brouillon de document';

  @override
  String get saveChanges => 'Enregistrer les modifications';

  @override
  String get editDocument => 'Modifier le document';

  @override
  String get generatingDraft => 'Génération de votre brouillon…';

  @override
  String get generatingDraftDesc =>
      'L\'IA prépare un document juridique basé sur les détails de votre dossier et les problèmes sélectionnés.';

  @override
  String get failedToGenerateDraft =>
      'Échec de la génération du brouillon. Veuillez réessayer.';

  @override
  String get changesSaved => 'Modifications enregistrées';

  @override
  String get copiedToClipboard => 'Copié dans le presse-papiers';

  @override
  String get emailComingSoon => 'Envoi d\'email bientôt disponible';

  @override
  String get reviewBeforeSending =>
      'Vérifiez attentivement avant d\'envoyer. Vous êtes responsable du contenu de ce document.';

  @override
  String get noContentAvailable => 'Aucun contenu disponible';

  @override
  String get save => 'Enregistrer';

  @override
  String get edit => 'Modifier';

  @override
  String get pdf => 'PDF';

  @override
  String get copy => 'Copier';

  @override
  String get appealDraft => 'Brouillon de recours';

  @override
  String selected(int count) {
    return '$count sélectionné(s)';
  }

  @override
  String get deleteSelected => 'Supprimer la sélection';

  @override
  String deleteDocumentsConfirm(int count) {
    return 'Supprimer $count documents ?';
  }

  @override
  String get delete => 'Supprimer';

  @override
  String get analyzeSelected => 'Analyser la sélection';

  @override
  String get batchAnalysisStarting => 'Démarrage de l\'analyse par lots…';

  @override
  String get switchToList => 'Affichage en liste';

  @override
  String get switchToGrid => 'Affichage en grille';

  @override
  String get scanNew => 'Nouvelle numérisation';

  @override
  String get noDocumentsYetScan => 'Pas encore de documents';

  @override
  String get scanFirstDocumentHint =>
      'Numérisez votre premier document pour que l\'IA l\'analyse et génère des recours.';

  @override
  String get failedToLoadDocuments => 'Échec du chargement des documents';

  @override
  String get emailIntegrationTitle => 'Intégration email';

  @override
  String get connectYourEmail => 'Connectez votre email';

  @override
  String get connectYourEmailDesc =>
      'Connectez votre email pour détecter et organiser automatiquement la correspondance juridique liée à vos dossiers.';

  @override
  String get legalEmails => 'Emails juridiques';

  @override
  String get unlinkedEmails => 'Emails non liés';

  @override
  String get noLegalEmailsYet => 'Pas encore d\'emails juridiques';

  @override
  String get legalEmailsWillAppear =>
      'Les emails classés comme juridiques apparaîtront ici.';

  @override
  String get assignToCase => 'Attribuer au dossier';

  @override
  String get disconnectEmail => 'Déconnecter l\'email';

  @override
  String get disconnectEmailConfirm =>
      'La synchronisation automatique des emails sera arrêtée. Les emails précédemment synchronisés resteront dans vos dossiers.';

  @override
  String get gmailReauthBannerBody =>
      'Advocat v2.1 lit votre boîte de réception pour rédiger des réponses ; vous pouvez révoquer cet accès à tout moment. Reconnectez Gmail pour activer le tri proactif.';

  @override
  String get gmailReauthBannerCta => 'Réautoriser';

  @override
  String connectedTo(String email) {
    return 'Connecté à $email';
  }

  @override
  String lastSynced(String time) {
    return 'Dernière synchronisation : $time';
  }

  @override
  String get filterByType => 'Filtrer par type';

  @override
  String get noCasesMatchSearch =>
      'Aucun dossier ne correspond à votre recherche';

  @override
  String get failedToLoadCases => 'Échec du chargement des dossiers';

  @override
  String get monthly => 'Mensuel';

  @override
  String get annual => 'Annuel';

  @override
  String get saveTwentyFivePercent => 'Économisez 25%';

  @override
  String get mostPopular => 'LE PLUS POPULAIRE';

  @override
  String get oneCaseActive => '1 dossier actif';

  @override
  String get threeCasesActive => '3 dossiers actifs';

  @override
  String get unlimitedCases => 'Dossiers illimités';

  @override
  String get threeDocScans => '3 numérisations de documents';

  @override
  String get twentyDocScans => '20 numérisations de documents';

  @override
  String get unlimitedDocScans => 'Numérisation illimitée de documents';

  @override
  String get basicAiAnalysis => 'Analyse IA de base';

  @override
  String get fullAiAnalysis => 'Analyse IA complète';

  @override
  String get draftGeneration => 'Génération de brouillons';

  @override
  String get priorityProcessing => 'Traitement prioritaire';

  @override
  String get fiveAiMessagesTotal => '5 messages IA (à vie)';

  @override
  String get hundredAiMessagesDay => '100 messages IA/jour';

  @override
  String get unlimitedAiMessages => 'Messages IA illimités';

  @override
  String get voiceInput => 'Saisie vocale';

  @override
  String get strategyRecommendations => 'Recommandations stratégiques';

  @override
  String get foundingMemberNote =>
      'Membre fondateur : 9,99 €/mois pour les 3 premiers mois';

  @override
  String get saveTwentyPercent => 'Économisez 20 %';

  @override
  String get forever => 'pour toujours';

  @override
  String get perMonth => '/mois';

  @override
  String get perYear => '/an';

  @override
  String get checkingPurchases => 'Vérification des achats précédents…';

  @override
  String get noPreviousPurchases => 'Aucun achat précédent trouvé.';

  @override
  String get chatWelcomeMessage =>
      'Hi! I\'m Advocat — your AI legal assistant. I provide legal information, not legal advice. What legal question can I help with?';

  @override
  String get copySummary => 'Copier le résumé';

  @override
  String get caseSummaryCopied => 'Résumé du dossier copié';

  @override
  String get openCase => 'Ouvrir le dossier';

  @override
  String get viewFull => 'Voir en entier';

  @override
  String get draftCopiedToClipboard => 'Brouillon copié dans le presse-papiers';

  @override
  String get reportMileageFraud => 'Signaler une fraude au kilométrage';

  @override
  String get reportMileageFraudDesc =>
      'Un rapport de fraude sera créé sur la base des données de contrôle du véhicule. Vous pouvez également ouvrir un dossier juridique.';

  @override
  String get reportAndOpenCase => 'Signaler et ouvrir un dossier';

  @override
  String get caseCreationComingSoon =>
      'Création de dossier avec données préremplies bientôt disponible';

  @override
  String get failedToCreateCaseRetry =>
      'Échec de la création du dossier. Veuillez réessayer.';

  @override
  String get takePhotoInstead => 'Prendre une photo';

  @override
  String get deleteCase => 'Supprimer le dossier';

  @override
  String deleteCaseConfirm(String title) {
    return 'Êtes-vous sûr de vouloir supprimer \"$title\" ? Cette action est irréversible.';
  }

  @override
  String get haveQuestionsAi => 'Des questions ? Demandez à l\'IA';

  @override
  String get cookiePolicy => 'Politique de cookies';

  @override
  String get aiDisclaimer => 'Avertissement IA';

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
  String get dataPrivacyConsent =>
      'Consentement à la confidentialité des données';

  @override
  String get gdprIntro =>
      'Pour fournir une assistance juridique par IA, nous traitons vos données conformément au RGPD (UE 2016/679). En continuant, vous acceptez :';

  @override
  String get gdprChat => 'Traitement de vos messages de chat par l\'IA';

  @override
  String get gdprDocs => 'Analyse des documents téléchargés';

  @override
  String get gdprStorage => 'Stockage chiffré des données de dossiers';

  @override
  String get gdprDelete => 'Droit de supprimer vos données à tout moment';

  @override
  String get gdprFooter =>
      'Vos données sont chiffrées et ne sont jamais partagées avec des tiers. Vous pouvez retirer votre consentement et supprimer toutes les données dans les Paramètres.';

  @override
  String get gdprConsentAiProcessing =>
      'J\'accepte le traitement de mes données pour l\'assistance juridique par IA (obligatoire)';

  @override
  String get gdprConsentAnalytics =>
      'J\'accepte l\'analyse des données pour améliorer le service (facultatif)';

  @override
  String get gdprArt9Intro =>
      'Cette application traite des catégories particulières de données à caractère personnel au titre de l\'article 9 du RGPD, notamment :';

  @override
  String get gdprSpecialLegalCases =>
      'Les détails de votre affaire juridique et vos documents judiciaires';

  @override
  String get gdprSpecialNationality => 'Nationalité et statut d\'immigration';

  @override
  String get gdprConsentLegalData =>
      'Je consens au traitement par IA des données de mon affaire juridique, de ma nationalité et de mon statut d\'immigration (obligatoire)';

  @override
  String get gdprConsentVoice =>
      'Je consens au traitement de l\'enregistrement vocal (facultatif)';

  @override
  String get gdprViewPrivacyPolicy =>
      'Consulter la politique de confidentialité';

  @override
  String get legalInformation => 'Informations légales';

  @override
  String get legalEntityName => 'Vorantis OÜ';

  @override
  String get legalRegistryCode => 'Code de registre : 17098992';

  @override
  String get legalAddress =>
      'Harju maakond, Tallinn, Kesklinna linnaosa, Tornimäe tn 5, 10145';

  @override
  String get legalEmail => 'E-mail : support@advocat.ee';

  @override
  String get legalRegistry =>
      'Immatriculée au registre du commerce estonien (Äriregister)';

  @override
  String get aiGeneratedDisclaimer => 'Généré par IA • Pas un avis juridique';

  @override
  String get decline => 'Refuser';

  @override
  String get iAgree => 'J\'accepte';

  @override
  String get iAgreeToThe => 'J\'accepte les ';

  @override
  String get orWord => 'ou';

  @override
  String get english => 'Anglais';

  @override
  String get russian => 'Russe';

  @override
  String get finnish => 'Finlandais';

  @override
  String successSubscribed(String plan) {
    return 'Abonnement à $plan réussi !';
  }

  @override
  String paymentFailed(String error) {
    return 'Paiement échoué : $error';
  }

  @override
  String get whatToDo => 'Que faire';

  @override
  String get getHelp => 'Obtenir de l\'aide';

  @override
  String get share => 'Partager';

  @override
  String get didYouKnow => 'Le saviez-vous ?';

  @override
  String get mustKnow => 'À savoir absolument';

  @override
  String get goodToKnow => 'Bon à savoir';

  @override
  String get sentFromAdvocat => 'Envoyé depuis l\'application Advocat';

  @override
  String get policeActionStayCalm =>
      'Restez calme et gardez les mains visibles';

  @override
  String get policeActionAskWhy =>
      'Demandez à l\'agent pourquoi vous êtes arrêté';

  @override
  String get policeActionProvideName => 'Donnez votre nom et date de naissance';

  @override
  String get policeActionWantLawyer =>
      'Déclarez clairement : \"Je souhaite un avocat avant toute question\"';

  @override
  String get policeActionAskInterpreter =>
      'Demandez un interprète si nécessaire';

  @override
  String get policeActionNoteBadge =>
      'Notez le nom et le numéro de badge de l\'agent';

  @override
  String get policeFactMustTellReason =>
      'En Finlande, la police doit vous donner la raison de l\'interpellation. Si elle ne le fait pas, vous pouvez demander — et elle est légalement tenue d\'expliquer.';

  @override
  String get policeFactCanRecord =>
      'Vous pouvez enregistrer les interactions avec la police dans les lieux publics en Finlande. C\'est protégé par la liberté d\'expression.';

  @override
  String get contactFinnishLegalAid => 'Aide juridictionnelle finlandaise';

  @override
  String get contactNonDiscriminationOmbudsman =>
      'Médiateur contre la discrimination';

  @override
  String get deportationDeadlineAppeal =>
      'Recours devant le tribunal administratif — généralement 30 jours après notification';

  @override
  String get deportationDeadlineLegalAid =>
      'Demandez l\'aide juridictionnelle — faites-le IMMÉDIATEMENT';

  @override
  String get deportationFactStayDuringAppeal =>
      'En Finlande, vous avez généralement le droit de rester dans le pays pendant le traitement de votre recours. L\'expulsion ne peut pas être exécutée pendant un recours actif dans la plupart des cas.';

  @override
  String get contactRefugeeAdviceCentre =>
      'Centre finlandais de conseil aux réfugiés';

  @override
  String get contactAdminCourtHelsinki => 'Tribunal administratif d\'Helsinki';

  @override
  String get workplaceActionKeepContract =>
      'Conservez des copies de votre contrat de travail';

  @override
  String get workplaceActionTrackHours =>
      'Enregistrez vos heures de travail de manière indépendante';

  @override
  String get workplaceActionReportUnsafe =>
      'Signalez les conditions dangereuses à l\'inspection du travail';

  @override
  String get workplaceActionJoinUnion =>
      'Adhérez à un syndicat pour vous protéger';

  @override
  String get workplaceActionContactAuthority =>
      'Contactez l\'Autorité de sécurité au travail si nécessaire';

  @override
  String get workplaceFactCollectiveWage =>
      'En Finlande, les conventions collectives fixent les salaires minimums par secteur — il n\'y a pas de salaire minimum national unique. Votre employeur doit respecter la convention collective de votre domaine.';

  @override
  String get workplaceFactOralContract =>
      'Même sans contrat écrit, vous avez tous les droits d\'un salarié en Finlande. Un accord oral est tout aussi contraignant en droit.';

  @override
  String get contactOccupationalSafety => 'Autorité de sécurité au travail';

  @override
  String get contactTradeUnionSAK => 'Conseil syndical (SAK)';

  @override
  String get tenantActionWrittenAgreement =>
      'Ayez toujours un contrat de location écrit';

  @override
  String get tenantActionDocumentCondition =>
      'Documentez l\'état de l\'appartement à l\'emménagement (photos)';

  @override
  String get tenantActionReportMaintenance =>
      'Signalez les problèmes d\'entretien par écrit';

  @override
  String get tenantActionNoIllegalEviction =>
      'N\'acceptez jamais une expulsion illégale — les tribunaux doivent statuer';

  @override
  String get tenantActionContactAdvisory =>
      'Contactez un service de conseil aux locataires en cas de litige';

  @override
  String get tenantFactNoEvictionWithoutCourt =>
      'Un propriétaire en Finlande ne peut pas vous expulser sans décision de justice, même si votre bail a expiré. Changer les serrures ou couper les services est illégal.';

  @override
  String get contactTenantsAssociation =>
      'Association finlandaise des locataires';

  @override
  String get contactConsumerDisputesBoard =>
      'Commission des litiges de consommation';

  @override
  String get detentionActionAskDecision =>
      'Demandez immédiatement la décision de rétention écrite';

  @override
  String get detentionActionRequestLawyer => 'Demandez à contacter un avocat';

  @override
  String get detentionActionContactEmbassy =>
      'Contactez votre ambassade ou consulat';

  @override
  String get detentionActionAskMedical =>
      'Demandez une assistance médicale si nécessaire';

  @override
  String get detentionActionRequestInterpreter =>
      'Demandez un interprète pour toutes les procédures';

  @override
  String get detentionDeadlineCourtReview =>
      'Le tribunal de district doit examiner la rétention dans les 4 jours';

  @override
  String get detentionDeadlineContinuation =>
      'Le tribunal réexamine la prolongation toutes les 2 semaines';

  @override
  String get detentionFactCourtReview =>
      'La rétention administrative en Finlande doit être examinée par un tribunal de district dans les 4 jours. Si ce n\'est pas fait, la rétention devient illégale.';

  @override
  String get contactParliamentaryOmbudsman => 'Médiateur parlementaire';

  @override
  String get discriminationActionWriteDown =>
      'Notez exactement ce qui s\'est passé (date, heure, lieu)';

  @override
  String get discriminationActionSaveEvidence =>
      'Conservez les preuves : messages, e-mails, témoins';

  @override
  String get discriminationActionFileComplaint =>
      'Déposez une plainte auprès du Médiateur contre la discrimination';

  @override
  String get discriminationActionContactLegalAid =>
      'Contactez un bureau d\'aide juridictionnelle pour des conseils gratuits';

  @override
  String get discriminationActionReportPolice =>
      'Signalez à la police en cas de menace ou d\'agression';

  @override
  String get discriminationFactNonDiscriminationAct =>
      'La loi finlandaise sur la non-discrimination couvre la discrimination fondée sur l\'âge, l\'origine, la nationalité, la langue, la religion, la santé, le handicap, l\'orientation sexuelle et d\'autres caractéristiques personnelles.';

  @override
  String get contactVictimSupportRIKU => 'Aide aux victimes Finlande (RIKU)';

  @override
  String get domesticViolence => 'Violence domestique';

  @override
  String get domesticViolenceDesc =>
      'Droits des victimes, aide d\'urgence, ordonnances de protection';

  @override
  String get rightCallEmergency =>
      'Vous avez le droit d\'appeler le 112 en cas d\'urgence : police, ambulance, pompiers';

  @override
  String get rightVictimProtection =>
      'En tant que victime, vous avez droit à la protection, au soutien et à l\'information sur votre affaire';

  @override
  String get rightRestrainingOrder =>
      'Vous pouvez demander une ordonnance de protection (lähestymiskielto) pour tenir l\'agresseur à distance';

  @override
  String get rightVictimInterpreter =>
      'Vous avez droit à un interprète durant toutes les procédures judiciaires';

  @override
  String get rightMedicalHelp =>
      'Vous avez droit à des soins médicaux immédiats et à la documentation de vos blessures';

  @override
  String get rightShelter =>
      'Vous avez droit à un hébergement d\'urgence : contactez un refuge ou les services sociaux';

  @override
  String get mustReportDanger =>
      'Si une personne est en danger immédiat, appelez le 112 sans délai';

  @override
  String get mustDocumentInjuries =>
      'Documentez toutes les blessures : photos, dossiers médicaux, notes écrites';

  @override
  String get domesticActionCallEmergency =>
      'Appelez le 112 si vous êtes en danger immédiat';

  @override
  String get domesticActionGoToSafe =>
      'Rendez-vous dans un lieu sûr : refuge, ami, lieu public';

  @override
  String get domesticActionDocumentEverything =>
      'Documentez les blessures : prenez des photos, obtenez des dossiers médicaux';

  @override
  String get domesticActionFilePoliceReport =>
      'Déposez une plainte auprès de la police : vous pouvez aussi le faire plus tard';

  @override
  String get domesticActionContactShelter =>
      'Contactez un refuge ou une ligne d\'assistance en cas de crise';

  @override
  String get domesticActionApplyRestraining =>
      'Demandez une ordonnance de protection auprès de la police ou du tribunal';

  @override
  String get domesticFactRestrainingOrder =>
      'En Finlande, une ordonnance de protection (lähestymiskielto) peut être délivrée même en l\'absence d\'affaire pénale. Elle interdit à la personne de vous contacter ou de vous approcher.';

  @override
  String get domesticFactVictimDirective =>
      'En vertu de la directive 2012/29/UE relative aux droits des victimes, vous avez le droit d\'être traité avec respect, de recevoir des informations dans une langue que vous comprenez et d\'accéder aux services d\'aide aux victimes, quel que soit votre statut de résidence.';

  @override
  String get domesticDeadlinePoliceReport =>
      'Dépôt de plainte : aucun délai strict, mais plus tôt est préférable pour les preuves';

  @override
  String get domesticDeadlineRestraining =>
      'Ordonnance de protection : peut être demandée à tout moment';

  @override
  String get contactEmergency => 'Numéro d\'urgence';

  @override
  String get contactShelter => 'Ligne d\'assistance Turvakoti (refuge)';

  @override
  String get contactCrisisHelpline =>
      'Ligne d\'assistance en cas de crise (Kriisipuhelin)';

  @override
  String get contactNollaLinja =>
      'Nollalinja — Ligne d\'assistance contre les violences faites aux femmes';

  @override
  String get inheritance => 'Succession';

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
  String get consumerProtection => 'Protection des consommateurs';

  @override
  String get consumerProtectionDesc =>
      'Fraude, produits défectueux, retours, vendeurs trompeurs';

  @override
  String get rightReturnOnline =>
      'Vous disposez de 14 jours pour annuler un achat en ligne sans motif (droit de rétractation de l\'UE)';

  @override
  String get rightDefectiveProduct =>
      'Si un produit est défectueux, vous avez droit à sa réparation, son remplacement ou son remboursement';

  @override
  String get rightClearPricing =>
      'Les vendeurs doivent afficher des prix clairs incluant tous les frais : les coûts cachés sont illégaux';

  @override
  String get rightComplainBoard =>
      'Vous pouvez déposer gratuitement une réclamation auprès de la Commission des litiges de consommation';

  @override
  String get rightProtectionFraud =>
      'Vous êtes protégé contre les pratiques commerciales déloyales et la fraude';

  @override
  String get mustKeepReceipts =>
      'Conservez tous les reçus, contrats et échanges avec les vendeurs';

  @override
  String get mustActTimely =>
      'Signalez les défauts au vendeur dans un délai raisonnable après leur découverte';

  @override
  String get consumerActionKeepEvidence =>
      'Conservez les reçus, captures d\'écran, e-mails et toute preuve d\'achat';

  @override
  String get consumerActionContactSeller =>
      'Contactez d\'abord le vendeur : exposez le problème par écrit';

  @override
  String get consumerActionFileComplaint =>
      'Déposez une réclamation auprès de la Commission des litiges de consommation (kuluttajariitalautakunta)';

  @override
  String get consumerActionContactAuthority =>
      'Contactez les services de conseil aux consommateurs pour une aide gratuite';

  @override
  String get consumerActionReportFraud =>
      'Signalez la fraude à la police et au médiateur de la consommation';

  @override
  String get consumerFactWithdrawal =>
      'En vertu de la directive 2011/83/UE relative aux droits des consommateurs, vous disposez de 14 jours pour vous rétracter de tout achat en ligne ou à distance, sans justification. Le vendeur doit vous rembourser dans un délai de 14 jours.';

  @override
  String get consumerFactWarranty =>
      'En Finlande, le vendeur est responsable des défauts du produit pendant une durée raisonnable (souvent 2 ans ou plus). Cela est distinct de toute garantie du fabricant.';

  @override
  String get consumerDeadlineWithdrawal =>
      'Rétractation d\'un achat en ligne : 14 jours à compter de la livraison';

  @override
  String get consumerDeadlineDefect =>
      'Signalement d\'un défaut au vendeur : dans les 2 mois suivant la découverte (recommandé)';

  @override
  String get contactConsumerAdvisory => 'Services de conseil aux consommateurs';

  @override
  String get contactConsumerOmbudsman =>
      'Médiateur de la consommation (Kuluttaja-asiamies)';

  @override
  String get contactConsumerDisputesBoardDirect =>
      'Commission des litiges de consommation';

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
  String get callAI => 'Appeler IA';

  @override
  String get comingSoon => 'Bientôt disponible';

  @override
  String get encrypted => 'Chiffré';

  @override
  String get typing => 'Écrit…';

  @override
  String get online => 'En ligne';

  @override
  String get chatWelcomeSubtitle =>
      'J\'analyserai la situation, vérifierai les documents, trouverai les erreurs et suggérerai quoi faire.';

  @override
  String get tapMicrophoneToSpeak => 'Appuyez sur le micro pour parler';

  @override
  String get categoryEssential => 'Essentiel';

  @override
  String get categoryPolice => 'Police';

  @override
  String get categoryWork => 'Travail';

  @override
  String get categoryHousing => 'Logement';

  @override
  String get categoryConsumer => 'Consommateur';

  @override
  String rightsInsideCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count droits à l\'intérieur',
      one: '1 droit à l\'intérieur',
      zero: 'aucun droit à l\'intérieur',
    );
    return '$_temp0';
  }

  @override
  String get freeAidThreshold => 'Seuil d\'aide gratuite';

  @override
  String get partialAidThreshold => 'Seuil d\'aide partielle';

  @override
  String get assetLimit => 'Limite de patrimoine';

  @override
  String get whereToApplyLabel => 'Où postuler';

  @override
  String get phoneLabel => 'Téléphone';

  @override
  String get websiteLabel => 'Site web';

  @override
  String get disclaimerCollapsed => 'À titre informatif uniquement';

  @override
  String get disclaimerExpanded =>
      'Assistant IA — pas un avis juridique. Vérifiez toujours avec un avocat qualifié.';

  @override
  String get chatDisclaimerBanner =>
      'L\'assistant IA fournit des informations juridiques, pas des conseils juridiques. Consultez toujours un avocat qualifié.';

  @override
  String get chatDisclaimerSubtitle => 'Assistant IA · pas un avis juridique';

  @override
  String get chatDisclaimerBannerFull =>
      'Advocat est un assistant d\'information juridique par IA, pas un avocat. Les informations ici ne créent pas de relation avocat-client, ne constituent pas un avis juridique et peuvent être erronées. Pour un avis juridique contraignant, consultez un avocat agréé dans votre juridiction. Nous ne vous représentons pas.';

  @override
  String get chatDisclaimerFooter =>
      'Généré par IA. Vérifiez auprès d\'un avocat agréé.';

  @override
  String get chatDisclaimerGotIt => 'Compris';

  @override
  String get categoryChildren => 'Enfants';

  @override
  String get categoryDigital => 'Numérique';

  @override
  String get childrenRights => 'Droits de l\'enfant et pension alimentaire';

  @override
  String get childrenRightsDesc =>
      'Pension alimentaire, protection, garanties de l\'État';

  @override
  String get cyberbullying => 'Cyberharcèlement et harcèlement en ligne';

  @override
  String get cyberbullyingDesc =>
      'Menaces, atteintes à la vie privée, diffamation en ligne';

  @override
  String get rightChildSupport =>
      'Les deux parents sont légalement tenus de subvenir financièrement aux besoins de leur enfant (Perekonnaseadus § 100–102)';

  @override
  String get rightMinimumAlimony =>
      'Pension alimentaire minimale en Estonie : montant de base (295,86 €) + 3 % du salaire brut moyen de l\'année précédente (PKS § 101). À partir du 01.04.2026 — 318,62 €/mois par enfant. Révisée chaque année au 1er avril. Calculateur : alimendid.ee';

  @override
  String get rightCourtAlimony =>
      'Vous pouvez demander une pension alimentaire auprès du tribunal de comté (maakohus) : aucun avocat requis pour les demandes jusqu\'à 6 400 €';

  @override
  String get rightBailiffEnforcement =>
      'Si le parent refuse de payer, un huissier (kohtutäitur) peut faire exécuter la décision de justice, y compris par saisie sur salaire';

  @override
  String get rightStateAlimonyGuarantee =>
      'Si le parent ne paie pas, l\'État verse l\'elatisabi (allocation d\'entretien) via le Sotsiaalkindlustusamet — jusqu\'à 100 €/mois par enfant';

  @override
  String get rightChildEducation =>
      'Tout enfant a droit à l\'éducation, aux soins de santé et à la protection contre les mauvais traitements (Lastekaitseseadus § 4–5)';

  @override
  String get rightChildContact =>
      'Un enfant a le droit de maintenir le contact avec ses deux parents, sauf décision contraire du tribunal (PKS § 143)';

  @override
  String get mustFileCourtClaim =>
      'Pour percevoir une pension alimentaire, vous devez déposer une demande au tribunal ou convenir du montant par écrit';

  @override
  String get mustNotifyAddressChange =>
      'Signalez tout changement d\'adresse au Sotsiaalkindlustusamet si vous percevez l\'elatisabi';

  @override
  String get childrenActionGatherDocs =>
      'Rassemblez l\'acte de naissance de l\'enfant, votre pièce d\'identité et les justificatifs de dépenses';

  @override
  String get childrenActionFileCourtClaim =>
      'Déposez une demande de pension alimentaire au tribunal de comté (maakohus) : possible en ligne via e-toimik';

  @override
  String get childrenActionApplyElatisabi =>
      'Demandez la garantie d\'État de pension alimentaire (elatisabi) au Sotsiaalkindlustusamet si le parent ne paie pas';

  @override
  String get childrenActionContactBailiff =>
      'Contactez un huissier (kohtutäitur) pour faire exécuter la décision de justice';

  @override
  String get childrenActionCallLasteabi =>
      'Appelez Lasteabi au 116 111, la ligne d\'assistance pour enfants : gratuite, 24h/24 et 7j/7';

  @override
  String get childrenDeadlineElatisabi =>
      'Demande d\'elatisabi : après la décision de justice, aucun délai strict mais la procédure prend du temps';

  @override
  String get childrenDeadlineCourt =>
      'La pension alimentaire peut être réclamée rétroactivement jusqu\'à 1 an avant le dépôt de la demande';

  @override
  String get childrenFactMinimum =>
      'À partir du 01.04.2026, la pension alimentaire minimale est de 318,62 €/mois par enfant. Formule : montant de base (295,86 €) + 3 % du salaire brut moyen de l\'année précédente. Révisée chaque année au 1er avril. Un parent ne peut pas convenir de payer moins. Calculateur : alimendid.ee';

  @override
  String get childrenFactElatisabi =>
      'La garantie d\'État de pension alimentaire estonienne (elatisabi) a été instaurée en 2017 pour protéger les enfants lorsqu\'un parent refuse de payer. L\'État verse le montant puis le recouvre auprès du parent débiteur.';

  @override
  String get rightReportCybercrime =>
      'Vous avez le droit de signaler à la police les menaces en ligne, le harcèlement et l\'usurpation d\'identité (Karistusseadustik § 120, § 157¹)';

  @override
  String get rightContentRemoval =>
      'Vous pouvez demander le retrait de contenus diffamatoires ou privés auprès des plateformes et exiger leur suppression au titre du RGPD';

  @override
  String get rightMoralDamageCompensation =>
      'Vous pouvez réclamer une indemnisation pour le préjudice moral causé par le cyberharcèlement (Võlaõigusseadus § 1043–1055)';

  @override
  String get rightPrivacyProtection =>
      'Votre vie privée est protégée : le partage non autorisé de vos photos, messages ou données personnelles est illégal (KarS § 157)';

  @override
  String get rightDataProtection =>
      'Signalez les violations de la protection des données (usage non autorisé de vos données) à l\'Andmekaitse Inspektsioon';

  @override
  String get rightDefamationAction =>
      'La diffamation (laimamine) est une infraction civile : vous pouvez réclamer des dommages-intérêts et exiger une rétractation publique (KarS § 247 (abrogé), VÕS § 1047)';

  @override
  String get mustCollectEvidence =>
      'Recueillez et conservez toutes les preuves : captures d\'écran, liens, dates et informations sur les témoins';

  @override
  String get mustNotRetaliate =>
      'Ne ripostez pas et n\'engagez pas de contre-harcèlement : cela pourrait affaiblir votre dossier';

  @override
  String get cyberActionScreenshots =>
      'Prenez des captures d\'écran de tout le harcèlement : enregistrez les URL, dates, noms d\'utilisateur et contenus';

  @override
  String get cyberActionReportPolice =>
      'Déposez une plainte au poste de police le plus proche ou en ligne sur politsei.ee';

  @override
  String get cyberActionReportPlatform =>
      'Signalez le contenu à la plateforme de réseaux sociaux pour qu\'il soit retiré';

  @override
  String get cyberActionContactDPA =>
      'Contactez l\'Andmekaitse Inspektsioon si vos données personnelles ont été utilisées à mauvais escient';

  @override
  String get cyberActionConsultLawyer =>
      'Consultez un avocat au sujet des dommages-intérêts civils : une aide juridictionnelle gratuite est disponible via le Riigi Õigusabi';

  @override
  String get cyberDeadlineCriminal =>
      'Plainte pénale : aucun délai strict, mais signalez rapidement pour de meilleurs résultats';

  @override
  String get cyberDeadlineCivil =>
      'Action civile en dommages-intérêts : jusqu\'à 3 ans à compter de la connaissance de la violation (TsÜS § 150)';

  @override
  String get cyberFactPrivacy =>
      'En Estonie, le partage non autorisé d\'images intimes d\'une personne peut être puni de jusqu\'à 3 ans d\'emprisonnement au titre du Karistusseadustik § 157¹ (atteinte à la vie privée).';

  @override
  String get cyberFactGDPR =>
      'En vertu du RGPD, vous disposez du « droit à l\'oubli » : les plateformes doivent supprimer vos données personnelles sur demande s\'il n\'existe aucune base légale pour les conserver.';

  @override
  String get guestUser => 'Invité';

  @override
  String get howToUse => 'Comment utiliser ?';

  @override
  String get tutorialStep1Title => 'Assistant juridique IA';

  @override
  String get tutorialStep1Desc =>
      'Posez n\'importe quelle question juridique et obtenez des réponses instantanées basées sur le droit estonien.';

  @override
  String get tutorialStep2Title => 'Connaissez vos droits';

  @override
  String get tutorialStep2Desc =>
      'Parcourez les informations juridiques par thème — travail, logement, droits des consommateurs et plus.';

  @override
  String get tutorialStep3Title => 'Scanner des documents';

  @override
  String get tutorialStep3Desc =>
      'Prenez des photos de documents juridiques pour l\'analyse IA et le stockage sécurisé.';

  @override
  String get tutorialStep4Title => 'C\'est parti !';

  @override
  String get tutorialStep4Desc =>
      'Explorez l\'application et protégez vos droits. Toutes les données restent privées sur votre appareil.';

  @override
  String get advocatProTitle => 'Advocat Pro';

  @override
  String get advocatProSubtitle => 'Débloquez les fonctions premium';

  @override
  String get voiceDisclaimer =>
      'L\'assistant vocal fonctionne actuellement uniquement sur ordinateur (navigateur Chrome). Support mobile bientôt.';

  @override
  String get recommended => 'Recommandé';

  @override
  String get pleaseLogIn => 'Veuillez vous connecter';

  @override
  String get subscriptionNotFound => 'Abonnement non trouvé';

  @override
  String errorWithMessage(String message) {
    return 'Erreur : $message';
  }

  @override
  String get redirectingToPayment => 'Redirection vers la page de paiement…';

  @override
  String cheaperAnnually(String amount) {
    return '€$amount/mois moins cher à l\'année';
  }

  @override
  String get navigatingTo => 'Ouverture de';

  @override
  String get stayInChat => 'Rester dans le chat';

  @override
  String get backToChat => 'Retour au chat';

  @override
  String get upgradeBannerTitle =>
      'Passez à l\'offre supérieure pour des consultations illimitées';

  @override
  String get upgradeBannerCta => 'Mettre à niveau';

  @override
  String get paymentSuccessTitle => 'Paiement réussi';

  @override
  String get paymentSuccessBody => 'Votre abonnement est désormais actif.';

  @override
  String get commonOk => 'OK';

  @override
  String get feedbackThumbsUpLabel => 'Utile';

  @override
  String get feedbackThumbsDownLabel => 'Pas utile';

  @override
  String get feedbackCommentPrompt => 'Qu\'est-ce qui n\'allait pas ?';

  @override
  String get feedbackSend => 'Envoyer';

  @override
  String get feedbackCancel => 'Annuler';

  @override
  String get reasoningPillIdle => 'Réflexion en cours…';

  @override
  String get reasoningPillSearchingLaw => 'Recherche dans le droit estonien…';

  @override
  String get reasoningPillSearchingWeb => 'Recherche sur le Web…';

  @override
  String get reasoningPillCheckingCompany =>
      'Vérification du registre des sociétés…';

  @override
  String get reasoningPillCheckingVehicle =>
      'Vérification du registre des véhicules…';

  @override
  String get reasoningPillReadingDocument => 'Lecture de votre document…';

  @override
  String get reasoningPillDrafting => 'Rédaction du document…';

  @override
  String get reasoningPillPreparingEmail => 'Préparation de l\'e-mail…';

  @override
  String get reasoningPillFindingLawyer => 'Recherche d\'avocats…';

  @override
  String get reasoningPillThinking => 'Analyse de votre affaire…';

  @override
  String get reasoningPillFinalising => 'Rédaction de votre réponse…';

  @override
  String reasoningCollapsedFormat(int sec, int sources) {
    return 'Réflexion de $sec s · $sources sources';
  }

  @override
  String get reasoningExpandHint => 'appuyez pour voir les étapes';

  @override
  String get caseFileTitle => 'Dossier de l\'affaire';

  @override
  String get caseFileTimeline => 'Chronologie';

  @override
  String get caseFileParties => 'Parties';

  @override
  String get caseFileDeadlines => 'Délais';

  @override
  String get caseFileExportPdf => 'Télécharger le dossier (PDF)';

  @override
  String get caseFileEmpty =>
      'Discutez de votre affaire avec l\'IA : votre chronologie se construira d\'elle-même.';

  @override
  String get caseFileDisclaimer =>
      'Ce dossier est extrait automatiquement de votre conversation. Il ne constitue pas un conseil juridique.';

  @override
  String get caseFileTabLabel => 'Affaire';

  @override
  String get refresh => 'Actualiser';

  @override
  String get demoLimitReached =>
      'Limite de la démo atteinte. Inscrivez-vous gratuitement pour continuer.';

  @override
  String get demoLimitSignUpCta => 'S\'inscrire';

  @override
  String freeQuotaExhausted(int count) {
    return 'Vous avez utilisé vos $count messages gratuits ce mois-ci.';
  }

  @override
  String get upgradeForUnlimited => 'Passez à Pro pour un usage illimité';

  @override
  String get upgradeCta => 'Mettre à niveau';

  @override
  String get rateLimitTryAgain =>
      'Envoi trop rapide. Réessayez dans quelques secondes.';

  @override
  String get quickProfilePrompt =>
      'Pour mieux vous aider, quel est votre statut juridique : êtes-vous citoyen estonien, citoyen de l\'UE d\'un autre pays, ou titulaire d\'un titre de séjour ?';

  @override
  String get quickProfileChipEstonianCitizen => 'Citoyen estonien';

  @override
  String get quickProfileChipEuCitizen => 'Citoyen de l\'UE (autre)';

  @override
  String get quickProfileChipResidencePermit => 'Titre de séjour';

  @override
  String get quickProfileSkipBtn => 'Ignorer';

  @override
  String get quickProfileSavedAck => 'C\'est noté. Quelle est votre question ?';

  @override
  String get caseTitleLabel => 'Intitulé de l\'affaire';

  @override
  String get jurisdictionLabel => 'Juridiction';

  @override
  String get caseTypeLabel => 'Type d\'affaire';

  @override
  String get caseLanguageLabel => 'Langue';

  @override
  String get caseNumbersSection => 'Numéros de l\'affaire';

  @override
  String get partiesSection => 'Parties';

  @override
  String get authoritiesSection => 'Autorités';

  @override
  String get timelineSection => 'Chronologie';

  @override
  String get openQuestionsSection => 'Questions en suspens';

  @override
  String get nextActionsSection => 'Prochaines actions';

  @override
  String get summarySection => 'Résumé';

  @override
  String get addRow => 'Ajouter une ligne';

  @override
  String get removeRow => 'Supprimer';

  @override
  String get archiveCase => 'Archiver l\'affaire';

  @override
  String get closeCase => 'Clore l\'affaire';

  @override
  String get continueChatAboutCase =>
      'Poursuivre la conversation sur cette affaire';

  @override
  String get linkChatToCase => 'Associer à l\'affaire';

  @override
  String get clearActiveCase => 'Réinitialiser l\'affaire active';

  @override
  String get caseSavedAck => 'Affaire enregistrée';

  @override
  String get caseArchivedAck => 'Affaire archivée';

  @override
  String get intakeStep1Title => 'Où se déroule l\'affaire ?';

  @override
  String get intakeStep1Subtitle =>
      'Le pays et l\'autorité auxquels vous avez affaire.';

  @override
  String get intakeJurisdictionLabel => 'Pays / juridiction';

  @override
  String get intakeAuthorityLabel => 'Type d\'autorité';

  @override
  String get intakeAuthorityNameLabel => 'Nom de l\'autorité (facultatif)';

  @override
  String get intakeAuthorityPolice => 'Police';

  @override
  String get intakeAuthorityCourt => 'Tribunal';

  @override
  String get intakeAuthoritySocial => 'Services sociaux';

  @override
  String get intakeAuthorityEmployer => 'Employeur';

  @override
  String get intakeAuthorityLandlord => 'Propriétaire';

  @override
  String get intakeAuthorityOpposingParty => 'Partie adverse';

  @override
  String get intakeAuthorityOther => 'Autre';

  @override
  String get intakeStep2Title => 'Quel type d\'affaire ?';

  @override
  String get intakeStep2Subtitle =>
      'Choisissez le type le plus proche : vous pourrez préciser plus tard.';

  @override
  String get intakeCaseTypeCriminal => 'Pénal';

  @override
  String get intakeCaseTypeCivil => 'Civil';

  @override
  String get intakeCaseTypeFamily => 'Familial';

  @override
  String get intakeCaseTypeAdmin => 'Administratif';

  @override
  String get intakeCaseTypeImmigration => 'Immigration';

  @override
  String get intakeCaseTypeLabor => 'Travail';

  @override
  String get intakeCaseTypeConsumer => 'Consommation';

  @override
  String get intakeCaseTypeInheritance => 'Succession';

  @override
  String get intakeCaseTypeOther => 'Autre';

  @override
  String get intakeStep3Title => 'Qui est concerné ?';

  @override
  String get intakeStep3Subtitle => 'Votre rôle et la partie adverse.';

  @override
  String get intakeRoleLabel => 'Votre rôle';

  @override
  String get intakeRolePlaintiff => 'Demandeur';

  @override
  String get intakeRoleDefendant => 'Défendeur';

  @override
  String get intakeRoleVictim => 'Victime';

  @override
  String get intakeRoleAccused => 'Accusé';

  @override
  String get intakeRoleWitness => 'Témoin';

  @override
  String get intakeRoleFamily => 'Membre de la famille';

  @override
  String get intakeRoleOther => 'Autre';

  @override
  String get intakeOpposingSideLabel => 'Partie adverse (facultatif)';

  @override
  String get intakeWitnessesLabel => 'Témoins (facultatif)';

  @override
  String get intakeAddWitness => 'Ajouter un témoin';

  @override
  String get intakeWitnessHint => 'Nom ou coordonnées';

  @override
  String get intakeStep4Title => 'Numéros et dates';

  @override
  String get intakeStep4Subtitle =>
      'Tout ce dont vous disposez déjà. Ignorez ce que vous n\'avez pas.';

  @override
  String get intakeCaseNumberLabel => 'Numéro de l\'affaire (facultatif)';

  @override
  String get intakeIncidentDateLabel => 'Date de l\'incident (facultatif)';

  @override
  String get intakeIncidentDatePick => 'Choisir une date';

  @override
  String get intakeDeadlinesLabel => 'Délais connus';

  @override
  String get intakeAddDeadline => 'Ajouter un délai';

  @override
  String get intakeDeadlineWhatHint => 'Objet';

  @override
  String get intakeStep5Title => 'Documents';

  @override
  String get intakeStep5Subtitle =>
      'Téléversez tout élément pertinent. Nous le lirons.';

  @override
  String get intakeUploadDocsLabel => 'Téléverser des documents';

  @override
  String get intakeSkipDocs => 'Ignorer — je téléverserai plus tard';

  @override
  String get intakeNextBtn => 'Suivant';

  @override
  String get intakeBackBtn => 'Retour';

  @override
  String get intakeFinishBtn => 'Terminer et ouvrir la conversation';

  @override
  String get intakeUrgentBtn => 'Urgent — poser ma question maintenant';

  @override
  String get intakeUrgentDialogTitle => 'Ouvrir la conversation maintenant ?';

  @override
  String get intakeUrgentDialogBody =>
      'Nous enregistrerons les informations saisies en tant qu\'affaire provisoire. Vous pourrez terminer l\'assistant depuis la page de l\'affaire à tout moment.';

  @override
  String get intakeUrgentConfirm => 'Ouvrir la conversation';

  @override
  String get intakeUrgentCancel => 'Continuer à remplir';

  @override
  String get intakePreparingCase => 'Préparation de votre affaire…';

  @override
  String get intakeFallbackGreeting =>
      'Je vois votre affaire. Dites-moi ce qui est le plus pressant — nous le traiterons ensemble.';

  @override
  String get intakeUrgentGreeting =>
      'Je vois que c\'est urgent. Posez votre question — je compléterai le reste au fur et à mesure.';

  @override
  String intakeStepIndicator(int current, int total) {
    return 'Étape $current sur $total';
  }

  @override
  String get intakeFieldRequired => 'Obligatoire';

  @override
  String intakeUploadProgress(int done, int total) {
    return 'Téléversement de $done / $total…';
  }

  @override
  String get uplDisclaimerFooter =>
      'Advocat n\'est pas un cabinet d\'avocats. Il s\'agit d\'informations et non d\'un conseil juridique.';

  @override
  String get citationStatusVerifiedBadge => 'Vérifiée';

  @override
  String get citationStatusUnverifiedBadge => 'Non vérifiée';

  @override
  String get citationStatusHistoricalBadge => 'Version historique';

  @override
  String get citationStatusVerifiedTooltip =>
      'Citée à partir d\'une source juridique extraite.';

  @override
  String get citationStatusUnverifiedTooltip =>
      'L\'IA a cité ce passage sans extraction de source — vérifiez avant de vous y fier.';

  @override
  String get citationStatusHistoricalTooltip =>
      'La disposition citée n\'est plus en vigueur.';

  @override
  String get citationOpenInRiigiTeataja => 'Ouvrir dans Riigi Teataja';

  @override
  String get citationSnippetExpand => 'Afficher le texte intégral';

  @override
  String get citationSnippetCollapse => 'Afficher moins';

  @override
  String get citationUnverifiedSheetNote =>
      'L\'IA a cité ce paragraphe, mais il n\'a pas été extrait du corpus juridique lors de cette requête. Vérifiez la référence avant de vous y appuyer.';

  @override
  String get citationFooterNoneWarning => 'Aucune citation fondée';

  @override
  String citationFooterSummaryTotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count références',
      one: '1 référence',
    );
    return '$_temp0';
  }

  @override
  String citationFooterSummaryVerified(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vérifiées',
      one: '1 vérifiée',
    );
    return '$_temp0';
  }

  @override
  String citationFooterSummaryUnverified(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count non vérifiées',
      one: '1 non vérifiée',
    );
    return '$_temp0';
  }

  @override
  String citationFooterSummaryHistorical(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count historiques',
      one: '1 historique',
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
      other: 'dans $count jours',
      one: 'dans 1 jour',
      zero: 'aujourd\'hui',
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
      other: '$count jours de retard',
      one: '1 jour de retard',
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
    return 'Le consilium recommande $count actions parallèles';
  }

  @override
  String get parallelActionsApproveAll => 'Tout approuver et envoyer';

  @override
  String parallelActionsApproveSelected(int count, int total) {
    return 'Approuver $count sur $total';
  }

  @override
  String parallelActionsConfirmTitle(int count) {
    return 'Envoyer $count e-mails ?';
  }

  @override
  String parallelActionsConfirmBody(int count) {
    return 'Advocat enverra $count réponses préparées via votre compte Gmail connecté. Chacune est envoyée indépendamment : si l\'une échoue, les autres partent quand même.';
  }

  @override
  String parallelActionsSentToast(int count) {
    return '$count envoyé(s).';
  }

  @override
  String parallelActionsPartialFailureToast(int sent, int failed) {
    return '$sent envoyé(s), $failed en échec.';
  }

  @override
  String get parallelActionsKindReply => 'réponse';

  @override
  String get parallelActionsKindNew => 'nouveau';

  @override
  String get parallelActionsCheckboxSelected => 'Action sélectionnée';

  @override
  String get parallelActionsCheckboxUnselected => 'Action non sélectionnée';

  @override
  String parallelActionsCitationCount(int count) {
    return '$count cit.';
  }

  @override
  String parallelActionsRetryFailed(int count) {
    return 'Réessayer les échecs ($count)';
  }

  @override
  String get agentApprovalNeedsReviewTitle =>
      'Advocat a besoin de votre approbation';

  @override
  String get agentApprovalResolvedTitle => 'Action traitée';

  @override
  String get agentApprovalStepsLabel => 'étapes';

  @override
  String get agentApprovalApproveButton => 'Approuver et envoyer';

  @override
  String get agentApprovalDeclineButton => 'Refuser';

  @override
  String get agentApprovalAttachmentsLabel => 'Pièces jointes';

  @override
  String get agentApprovalSentSummary => 'Envoyé en votre nom.';

  @override
  String get agentApprovalDeclinedSummary => 'Refusé — rien n\'a été envoyé.';

  @override
  String get agentToolDraftEmailAtt => 'Envoyer un e-mail avec pièces jointes';

  @override
  String get agentToolSendEmail => 'Envoyer un e-mail';

  @override
  String get agentToolGeneratePdf => 'Générer un PDF';

  @override
  String get agentToolApproveSend => 'Envoyer la réponse préparée';

  @override
  String get inboxErrorTitle => 'Impossible de charger la boîte de réception';

  @override
  String get inboxEditDiscardTitle =>
      'Abandonner les modifications non enregistrées ?';

  @override
  String get inboxEditDiscardBody =>
      'Ce brouillon comporte des modifications non enregistrées. Revenir en arrière les supprimera.';

  @override
  String get inboxEditKeepEditing => 'Continuer à modifier';

  @override
  String get inboxEditDiscard => 'Abandonner';

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
  String get plannerSettingsTitle => 'Raisonnement juridique en trois passes';

  @override
  String get plannerSettingsSubtitle =>
      'Planifier → répondre → critiquer. Plus lent mais plus approfondi.';

  @override
  String get plannerSettingsProBadge => 'Pro';

  @override
  String get plannerSettingsProDescription => 'Disponible avec l\'offre Pro';

  @override
  String get plannerTrailHeaderPlan => 'Plan';

  @override
  String get plannerTrailHeaderCritique => 'Critique';

  @override
  String get plannerTrailSubQuestions => 'Sous-questions';

  @override
  String get plannerTrailCounterArgs => 'Contre-arguments';

  @override
  String get plannerTrailEvidenceGaps => 'Lacunes dans les preuves';

  @override
  String get plannerTrailMaterialGapTrue => 'Lacune substantielle détectée';

  @override
  String get plannerTrailRegeneratedBadge => 'Régénéré une fois';

  @override
  String get plannerTrailEmpty => 'aucun élément';

  @override
  String get supportTitle => 'Aide';

  @override
  String get supportSubtitle =>
      'Nous répondons généralement sous 1 à 2 heures.';

  @override
  String get supportSearchPlaceholder => 'Rechercher dans l\'aide…';

  @override
  String get supportStatusAllOk => 'Tous les systèmes sont opérationnels';

  @override
  String get supportFaqWhatIs => 'Qu\'est-ce qu\'Advocat ?';

  @override
  String get supportFaqHowSubscribe => 'Comment souscrire à l\'offre Pro ?';

  @override
  String get supportFaqExportData => 'Puis-je exporter mes données ?';

  @override
  String get supportFaqCancelAccount => 'Annuler ou supprimer le compte';

  @override
  String get supportFaqTalkHuman => 'Parler à un humain';

  @override
  String get supportContactEmail => 'E-mail';

  @override
  String get supportContactTelegram => 'Telegram';

  @override
  String get supportContactWhatsapp => 'WhatsApp';

  @override
  String get supportFooterSla => 'Nous répondons sous 24 h';

  @override
  String get supportWhatsapp => 'WhatsApp';

  @override
  String get supportEmail => 'E-mail';

  @override
  String get supportInApp => 'Écrivez-nous ici';

  @override
  String get supportCategoryLabel => 'Catégorie';

  @override
  String get supportCategoryBug => 'Bug';

  @override
  String get supportCategoryPayment => 'Problème de paiement';

  @override
  String get supportCategoryQuestion => 'Question';

  @override
  String get supportCategoryFeature => 'Demande de fonctionnalité';

  @override
  String get supportCategoryOther => 'Autre';

  @override
  String get supportMessagePlaceholder => 'Décrivez votre problème...';

  @override
  String get supportEmailLabel => 'E-mail (facultatif)';

  @override
  String get supportSend => 'Envoyer';

  @override
  String get supportSentSuccess => 'Message envoyé ! Nous répondrons bientôt.';

  @override
  String get supportError => 'Une erreur s\'est produite. Réessayez.';

  @override
  String get supportErrorTooShort => 'Veuillez écrire au moins 10 caractères.';

  @override
  String get supportErrorTooLong => '2000 caractères maximum.';

  @override
  String get supportPrivacyNotice =>
      'Votre message est stocké en toute sécurité.';

  @override
  String get reviewThisContract => 'Vérifier ce contrat';

  @override
  String get contractReviews => 'Examens de contrats';

  @override
  String get contractReviewsFreeFeature => '1 examen de contrat (essai à vie)';

  @override
  String get contractReviewsCounselFeature => '5 examens de contrat par mois';

  @override
  String get contractReviewsProFeature => '20 examens de contrat par mois';

  @override
  String contractReviewsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count revues de contrat restantes ce mois-ci',
      one: '1 revue de contrat restante ce mois-ci',
      zero: 'Aucune revue de contrat restante ce mois-ci',
    );
    return '$_temp0';
  }

  @override
  String get contractReviewsExhausted =>
      'Aucun examen de contrat restant ce mois-ci';

  @override
  String get contractReviewsFreeTrialLeft =>
      'Essai gratuit : 1 examen de contrat';

  @override
  String get contractReviewsFreeTrialUsed =>
      'Essai gratuit utilisé — mettez à niveau';

  @override
  String get contractReviewsUpgradeTitle => 'Examens de contrat épuisés';

  @override
  String get contractReviewsUpgradeBodyFree =>
      'Vous avez utilisé votre examen de contrat gratuit. Mettez à niveau pour des examens mensuels.';

  @override
  String contractReviewsUpgradeBodyPaid(int used, int cap) {
    return 'Vous avez utilisé $used examens sur $cap ce mois-ci. Mettez à niveau pour un plafond plus élevé.';
  }

  @override
  String get contractReviewsUpgradeCounselCta =>
      'Passez à Counsel (€19,99/mois) — 5 examens';

  @override
  String get contractReviewsUpgradeProCta =>
      'Passez à Pro (€29,99/mois) — 20 examens';

  @override
  String get contractReviewsUpgradeToProShort => 'Passez à Pro — 20/mois';

  @override
  String get notNow => 'Pas maintenant';

  @override
  String get referralTitle => 'Inviter des amis';

  @override
  String get referralSubtitle =>
      'Recevez un mois gratuit. Offrez un mois gratuit.';

  @override
  String get referralYourLink => 'VOTRE LIEN';

  @override
  String get referralCopyLink => 'Copier le lien';

  @override
  String get referralShare => 'Partager';

  @override
  String get referralLinkCopied => 'Lien copié';

  @override
  String get referralStatsInvited => 'Invités';

  @override
  String get referralStatsConverted => 'Convertis';

  @override
  String get referralStatsEarned => 'Mois gagnés';

  @override
  String get referralShareWhatsApp => 'Partager sur WhatsApp';

  @override
  String get referralShareTelegram => 'Partager sur Telegram';

  @override
  String get referralShareEmail => 'Partager par e-mail';

  @override
  String get referralEmailSubject =>
      'Essaie Advocat — ton assistant juridique IA';

  @override
  String get referralLoadError =>
      'Impossible de charger les informations. Tirez pour actualiser.';

  @override
  String get referralRetry => 'Réessayer';

  @override
  String get referralSettingsTile => 'Inviter des amis';

  @override
  String get referralAfterReviewCta =>
      'Ça t\'a plu ? Invite un ami — vous recevez tous les deux un mois gratuit.';

  @override
  String get referralAntiFraud => '12 parrainages réussis maximum par an.';

  @override
  String get referralEmpty =>
      'Aucun parrainage pour le moment. Envoyez votre lien pour commencer à gagner des récompenses.';

  @override
  String get referralRecentActivity => 'Activité récente';

  @override
  String referralActivityInvited(String when) {
    return 'Invité $when';
  }

  @override
  String referralActivityActivated(String when) {
    return 'activé $when';
  }

  @override
  String get referralActivityPending => 'pas encore activé';

  @override
  String referralStatsInvitedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count amis',
      one: '1 ami',
      zero: 'aucun ami pour le moment',
    );
    return 'Vous avez invité $_temp0';
  }

  @override
  String referralStatsConvertedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ont activé',
      one: '1 a activé',
      zero: 'aucune activation pour le moment',
    );
    return '$_temp0';
  }

  @override
  String referralStatsEarnedCount(int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months mois gratuits',
      one: '1 mois gratuit',
      zero: 'rien pour le moment',
    );
    return 'Votre bonus : $_temp0';
  }

  @override
  String get referralNudgeMessage =>
      'Advocat vous plaît ? Invitez un ami — vous gagnez tous les deux un mois gratuit.';

  @override
  String get referralNudgeAction => 'Inviter';

  @override
  String get referralLandingTitle => 'Vous avez été invité sur Advocat';

  @override
  String referralLandingSubtitle(String inviterName) {
    return '$inviterName vous a invité — profitez de votre premier mois gratuit.';
  }

  @override
  String get referralLandingSubtitleGeneric =>
      'Profitez de votre premier mois gratuit d\'Advocat Pro.';

  @override
  String get referralLandingCta => 'Activer le mois gratuit et s\'inscrire';

  @override
  String get referralLandingCtaSecondary => 'Ou en savoir plus sur Advocat';

  @override
  String get referralLandingFallback =>
      'Ce lien a expiré — mais vous pouvez tout de même essayer Advocat gratuitement.';

  @override
  String get referralLandingBenefits =>
      '17 langues • Véritable droit estonien, finlandais et de l\'UE • 24h/24 et 7j/7 — sans attente';

  @override
  String get checkerProTagline => 'Outils de vérification professionnels';

  @override
  String get checkerDataSource => 'Données issues des registres officiels';

  @override
  String get companyCheckerHint => 'Nom de l\'entreprise ou n° de registre';

  @override
  String get companyCheckerPriceChip =>
      '€2.99 par vérification  •  Inclus dans Pro';

  @override
  String get companyCheckerEmptyState =>
      'Saisissez un nom d\'entreprise ou un numéro\nde registre pour obtenir un rapport complet';

  @override
  String get aiMemoryTitle => 'Mémoire de l\'IA';

  @override
  String get aiMemorySubtitle =>
      'Consultez et effacez ce que l\'IA mémorise sur vous';

  @override
  String get bookLawyerCallTitle => 'Réserver un appel avec un avocat';

  @override
  String get bookLawyerCallComingSoonTitle =>
      'Appels avec un avocat humain — bientôt disponibles';

  @override
  String get bookLawyerCallComingSoonBody =>
      'Pro et Premium incluent des appels de 15 minutes avec un avocat partenaire (1/trimestre pour Pro, 2/trimestre pour Premium). Nous finalisons le réseau d\'avocats indépendants estoniens et vous enverrons un e-mail dès l\'ouverture des réservations.';

  @override
  String bookLawyerCallQuotaAvailable(int remaining, int total) {
    return 'Il vous reste $remaining appel(s) sur $total ce trimestre.';
  }

  @override
  String get bookLawyerCallQuotaExhausted => 'Quota trimestriel épuisé.';

  @override
  String get bookLawyerCallQuotaBodyAvailable =>
      'Le niveau Pro inclut 1 appel par trimestre, Premium 2. Les appels durent 15 minutes via Google Meet.';

  @override
  String get bookLawyerCallQuotaBodyExhausted =>
      'Votre quota se réinitialise le premier jour du trimestre suivant. Besoin de parler plus tôt ? Passez à Premium pour un appel supplémentaire.';

  @override
  String get severityCritical => 'CRITIQUE';

  @override
  String get severityHigh => 'ÉLEVÉ';

  @override
  String get severityMedium => 'MOYEN';

  @override
  String get severityLow => 'FAIBLE';

  @override
  String get deadlineRequiredFields =>
      'Le titre et la date limite sont obligatoires';

  @override
  String get acceptTermsRequired =>
      'Veuillez accepter les Conditions d\'utilisation';

  @override
  String get chatLegalCouncilTooltip => 'Conseil juridique (4 experts)';

  @override
  String get attachFileTooltip => 'Joindre un fichier';

  @override
  String get sendMessage => 'Envoyer le message';

  @override
  String get stopGenerating => 'Arrêter la génération';

  @override
  String get showPassword => 'Afficher le mot de passe';

  @override
  String get hidePassword => 'Masquer le mot de passe';

  @override
  String get decreaseDependents => 'Diminuer';

  @override
  String get increaseDependents => 'Augmenter';

  @override
  String get sensitiveConsentTitle => 'Consentement aux données sensibles';

  @override
  String get sensitiveConsentBody =>
      'Les documents que vous vous apprêtez à téléverser peuvent contenir des catégories particulières de données à caractère personnel au titre de l\'article 9 du RGPD — telles que des dossiers médicaux, des antécédents judiciaires, des données biométriques ou des informations sur votre origine raciale, votre religion ou votre orientation sexuelle.  Nous ne traitons ces données que pour vous fournir une assistance juridique par IA, les stockons chiffrées dans votre compte privé et ne les utilisons jamais pour entraîner des modèles. Vous pouvez retirer votre consentement et supprimer les données à tout moment depuis les Paramètres.  En acceptant, vous donnez votre consentement explicite, au titre de l\'article 9(2)(a) du RGPD, au traitement de catégories particulières de données à cette fin.';

  @override
  String get sensitiveConsentExplicitCheckbox =>
      'Je donne mon consentement explicite au traitement de catégories particulières de données (art. 9(2)(a) du RGPD).';

  @override
  String get sensitiveConsentRightToShareCheckbox =>
      'Je confirme avoir le droit de partager ces données (les données m\'appartiennent, ou je dispose d\'une base légale ou d\'une information préalable pour partager des données de tiers).';

  @override
  String get sensitiveConsentViewCategories =>
      'Voir ce qui est considéré comme sensible →';

  @override
  String get sensitiveConsentWithdrawAction =>
      'Retirer le consentement aux données sensibles';

  @override
  String get privacyAndData => 'CONFIDENTIALITÉ ET DONNÉES';

  @override
  String get exportMyDataSubtitle =>
      'Téléchargez une copie de toutes vos données personnelles (art. 15 du RGPD).';

  @override
  String get withdrawSensitiveConsent => 'Consentement aux données sensibles';

  @override
  String get withdrawSensitiveConsentSubtitle =>
      'Gérer ou retirer le consentement au traitement de catégories particulières de données (art. 9(2)(a) du RGPD).';

  @override
  String get dataProcessingAgreement => 'Accord de traitement des données';

  @override
  String get exportingData => 'Exportation de vos données…';

  @override
  String get exportComplete =>
      'Export des données prêt — enregistré sur votre appareil.';

  @override
  String get exportFailed =>
      'Échec de l\'export. Veuillez réessayer ou contacter le support.';

  @override
  String get quotaExhaustedTitle => 'Limite de messages gratuits atteinte';

  @override
  String quotaExhaustedBody(int count) {
    return 'Vous avez utilisé l\'ensemble de vos $count messages gratuits. Passez à Advocat Counsel pour 19,99 €/mois et bénéficiez de consultations juridiques par IA illimitées.';
  }

  @override
  String get quotaExhaustedLater => 'Plus tard';

  @override
  String get quotaExhaustedUpgrade => 'Advocat Counsel — 19,99 €/mois';

  @override
  String quotaCtaMessage(int count) {
    return 'Vous avez utilisé l\'ensemble de vos $count messages gratuits. Passez à Advocat Counsel pour 19,99 €/mois.';
  }

  @override
  String get quotaCtaButton => 'Obtenir Advocat Counsel — 19,99 €/mois';

  @override
  String get aiErrorQuota =>
      'Limite de messages gratuits atteinte. Abonnez-vous pour continuer à utiliser l\'IA.';

  @override
  String get aiErrorAuth =>
      'Connexion requise pour utiliser l\'IA. Veuillez vous inscrire ou vous connecter.';

  @override
  String get aiErrorGeneric =>
      'Erreur temporaire de l\'IA. Veuillez réessayer dans une minute. Si le problème persiste, contactez le support.';

  @override
  String get tooltipShareCase => 'Partager le résumé de l\'affaire';

  @override
  String get tooltipMuteVoice => 'Couper la voix';

  @override
  String get tooltipUnmuteVoice => 'Réactiver la voix';

  @override
  String get tooltipAttachDoc => 'Joindre un document';

  @override
  String get aiTypingHint => 'IA…';

  @override
  String get error404Title => 'Page introuvable';

  @override
  String error404Body(String path) {
    return 'Nous n\'avons pas pu trouver : $path';
  }

  @override
  String get goToHome => 'Aller à l\'accueil';

  @override
  String get emailAlreadyRegistered =>
      'Cette adresse e-mail est déjà enregistrée. Voulez-vous vous connecter ?';

  @override
  String get actionSignIn => 'Se connecter';

  @override
  String get actionUndo => 'Annuler';

  @override
  String get intakeUrgentOpened =>
      'Conversation ouverte — votre brouillon est enregistré.';

  @override
  String get panicCoachmark => 'Maintenez appuyé pour une aide d\'urgence.';

  @override
  String get panicTitle => 'De quoi avez-vous besoin maintenant ?';

  @override
  String get panicCardReadAloud => 'Lire à voix haute à l\'agent';

  @override
  String get panicCardRecord => 'Enregistrer cette conversation';

  @override
  String get panicCardCall => 'Appeler un avocat';

  @override
  String get panicCardAi => 'Parler à Advocat maintenant';

  @override
  String get panicClose => 'Fermer';

  @override
  String get panicBadgeV2 => 'V2';

  @override
  String get panicRecordV1Title => 'Arrive en V2';

  @override
  String get panicRecordV1Body =>
      'La fonction d\'enregistrement est en cours de validation juridique pour l\'Estonie et sera disponible en V2. Pour l\'instant, utilisez l\'enregistreur vocal intégré de votre téléphone.';

  @override
  String get panicCallFallbackBody =>
      'Écrivez à kiire@advocat.ee avec une brève description et nous vous rappellerons.';

  @override
  String get consiliumHeader => 'Consilium d\'avocats';

  @override
  String consiliumProgress(int count, int total) {
    return '$count sur $total prêts';
  }

  @override
  String get consiliumStarting => 'Les avocats examinent votre dossier…';

  @override
  String get consiliumDisagreement => 'Les experts sont en désaccord';

  @override
  String get consiliumSynthesizing => 'Synthèse de la recommandation…';

  @override
  String consiliumDone(int totalRoles) {
    return 'Consilium terminé · $totalRoles experts';
  }

  @override
  String get consiliumPositionPush => 'Contester';

  @override
  String get consiliumPositionSettle => 'Transiger';

  @override
  String get consiliumPositionInvestigate => 'Approfondir';

  @override
  String get consiliumPositionOutOfScope => 'Hors compétence';

  @override
  String get consiliumConfidence => 'Confiance';

  @override
  String get consiliumKeyCitation => 'Référence clé';

  @override
  String get consiliumAdversarialRound => 'Tour contradictoire';

  @override
  String get consiliumViewFullOpinion => 'Voir l\'avis complet';

  @override
  String consiliumExpertsAgreed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count experts d\'accord',
      one: '1 expert d\'accord',
    );
    return '$_temp0';
  }

  @override
  String consiliumExpertsDisagree(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count experts en désaccord',
      one: '1 expert en désaccord',
    );
    return '$_temp0';
  }

  @override
  String get consiliumDisclaimer =>
      'Agents IA, pas des avocats humains. Vérifiez les décisions importantes auprès d\'un avocat habilité.';

  @override
  String get softCaseShellBanner =>
      'Nous avons créé « Affaire sans titre » pour en assurer le suivi. Appuyez pour la renommer.';

  @override
  String get softCaseShellBannerCta => 'Renommer';

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
  String get iapPayWithApple => 'Payer avec Apple';

  @override
  String get iapRestorePurchases => 'Restaurer les achats';

  @override
  String get iapPurchaseFailed =>
      'L’achat a échoué. Veuillez réessayer ou contacter le support.';

  @override
  String get iapRestoreSuccess => 'Votre abonnement a été restauré.';

  @override
  String get iapRestoreNoActive => 'Aucun abonnement actif à restaurer.';

  @override
  String get deadlineEuRadarTitle => 'EU deadline radar (preview)';

  @override
  String get deadlineEuRadarSubtitle =>
      'Hypothetical EU procedural deadlines — mock data';

  @override
  String get changePassword => 'Changer le mot de passe';

  @override
  String get changePasswordSubtitle =>
      'Mettez à jour le mot de passe de votre compte';

  @override
  String get newPasswordTitle => 'Définir un nouveau mot de passe';

  @override
  String get newPasswordHint =>
      'Saisissez et confirmez un nouveau mot de passe pour votre compte.';

  @override
  String get newPasswordSave => 'Enregistrer le nouveau mot de passe';

  @override
  String get newPasswordSuccess =>
      'Mot de passe mis à jour. Vous pouvez maintenant l\'utiliser pour vous connecter.';

  @override
  String get newPasswordError =>
      'Échec de la mise à jour du mot de passe. Veuillez réessayer.';

  @override
  String get accessLogTile => 'Journal d\'accès';

  @override
  String get accessLogTileSubtitle =>
      'Voyez qui a accédé à vos données et comment';

  @override
  String get accessLogTitle => 'Journal d\'accès à mes données';

  @override
  String get accessLogIntro =>
      'Un relevé transparent et infalsifiable de chaque accès ou traitement de vos données — y compris par notre IA. Vous pouvez vérifier qu\'il n\'a pas été altéré.';

  @override
  String get accessLogEmpty => 'Aucun événement d\'accès pour le moment.';

  @override
  String get accessLogError =>
      'Impossible de charger votre journal d\'accès. Tirez vers le bas pour réessayer.';

  @override
  String get accessLogIntegrityOk =>
      'Intégrité vérifiée — les liens du journal forment une chaîne ininterrompue.';

  @override
  String get accessLogIntegrityBroken =>
      'Avertissement : la chaîne du journal est rompue. Certaines entrées ont pu être supprimées ou réorganisées. Veuillez contacter l\'assistance.';

  @override
  String get accessActionLlmEgress =>
      'Transmis à l\'IA pour traitement (pseudonymisé)';

  @override
  String get accessActionAiAnalysis => 'Analysé par l\'IA';

  @override
  String get accessActionDocumentParse => 'Document analysé';

  @override
  String get accessActionStaffRead => 'Consulté par un membre de l\'équipe';

  @override
  String get accessActionExport => 'Données exportées';

  @override
  String get accessActionEmailTriage => 'E-mail trié';

  @override
  String get accessActionDeadlineScan => 'Délais analysés';

  @override
  String get breachAlertTitle => 'Alerte de sécurité concernant vos données';

  @override
  String get breachAlertBody =>
      'Notre surveillance automatisée a détecté un accès inhabituel impliquant vos données. Nous l\'examinons et vous informerons de tout incident confirmé, conformément à la loi (art. 34 du RGPD).';

  @override
  String get caseDossierTitle => 'Exporter le dossier de l\'affaire';

  @override
  String get caseDossierSubtitle =>
      'Un seul PDF rassemblant tout — faits, chronologie, délais et documents — à remettre à un conseil, un tribunal ou un organe de réclamation.';

  @override
  String get caseDossierTileTitle => 'Exporter le dossier (PDF)';

  @override
  String get caseDossierTileSubtitle =>
      'Transmettez toute l\'affaire à un conseil ou un tribunal en un seul fichier';

  @override
  String get caseDossierSectionsHeading => 'À inclure dans le dossier';

  @override
  String get caseDossierSectionFacts => 'Faits de l\'affaire';

  @override
  String get caseDossierSectionFactsHint => 'Toujours inclus';

  @override
  String get caseDossierSectionTimeline => 'Chronologie';

  @override
  String get caseDossierSectionDeadlines => 'Délais';

  @override
  String get caseDossierSectionDocuments => 'Documents';

  @override
  String get caseDossierSectionAiSummary => 'Synthèse IA';

  @override
  String get caseDossierExportButton => 'Exporter le PDF';

  @override
  String get caseDossierExporting => 'Création de votre dossier…';

  @override
  String get caseDossierSuccess =>
      'Dossier prêt. Ouvrez ou partagez le fichier.';

  @override
  String get caseDossierOpen => 'Ouvrir le dossier';

  @override
  String get caseDossierError =>
      'Impossible de créer le dossier. Veuillez réessayer.';

  @override
  String get caseDossierErrorNotOwned => 'Cette affaire est introuvable.';

  @override
  String get caseDossierDisclaimer =>
      'Le dossier reproduit les données de votre affaire telles qu\'enregistrées. Vérifiez-le avant de le partager.';

  @override
  String get followupsTitle => 'Prochaines étapes';

  @override
  String get followupsSubtitle =>
      'Tâches concrètes pour faire avancer votre affaire';

  @override
  String get followupsEmpty => 'Aucune étape de suivi pour le moment.';

  @override
  String get followupsEmptyDesc =>
      'Ajoutez une étape, ou laissez l\'IA suggérer la suite.';

  @override
  String get followupsAdd => 'Ajouter une étape';

  @override
  String get followupsSuggest => 'Suggérer des étapes';

  @override
  String get followupsSuggestNone =>
      'Aucune suggestion pour le moment. Réessayez après avoir échangé sur l\'affaire.';

  @override
  String get followupsSuggestTitle => 'Prochaines étapes suggérées';

  @override
  String get followupsAddPrompt =>
      'Ajoutez les étapes que vous souhaitez conserver :';

  @override
  String get followupsNewTitleHint => 'Que faut-il faire ?';

  @override
  String get followupsNewDetailHint =>
      'Note facultative (pourquoi / quoi joindre)';

  @override
  String get followupsDueOptional => 'Me rappeler le (facultatif)';

  @override
  String get followupsOverdue => 'En retard';

  @override
  String followupsDueOn(String date) {
    return 'Échéance le $date';
  }

  @override
  String get followupsDone => 'Terminé';

  @override
  String get followupsSnooze => 'Reporter';

  @override
  String get followupsSnooze1Week => 'Me rappeler dans une semaine';

  @override
  String get followupsDismiss => 'Ignorer';

  @override
  String get followupsLoadError =>
      'Impossible de charger les prochaines étapes';

  @override
  String get followupsAiBadge => 'IA';

  @override
  String get contractCompareTitle => 'Comparer les versions';

  @override
  String get contractCompareIntro =>
      'Importez deux versions du même contrat. Nous mettons en évidence ce qui a changé et si chaque modification vous est favorable ou défavorable.';

  @override
  String get contractCompareOldVersion => 'Ancienne version (v1)';

  @override
  String get contractCompareNewVersion => 'Nouvelle version (v2)';

  @override
  String get contractCompareCta => 'Comparer les versions';

  @override
  String get contractCompareAdverse => 'Défavorable';

  @override
  String get contractCompareFavorable => 'Favorable';

  @override
  String get contractCompareNeutral => 'Neutre';

  @override
  String get contractCompareBefore => 'Avant';

  @override
  String get contractCompareAfter => 'Après';

  @override
  String get contractCompareTruncated =>
      'Contrat long — seule la première partie de chaque version a été comparée.';

  @override
  String get contractCompareNoChanges =>
      'Aucune modification substantielle détectée entre les deux versions.';

  @override
  String get docSearchTitle => 'Rechercher dans mes documents';

  @override
  String get docSearchHint => 'ex. où le dépôt de garantie était-il mentionné';

  @override
  String get docSearchSubtitle =>
      'Recherche sémantique dans votre coffre-fort et vos pièces de dossier';

  @override
  String get docSearchIdle =>
      'Recherchez dans le contenu de vos propres documents — pas seulement dans les titres.';

  @override
  String get docSearchNoResults =>
      'Aucune correspondance trouvée dans vos documents.';

  @override
  String get docSearchError => 'Échec de la recherche. Veuillez réessayer.';

  @override
  String get docSearchUntitled => 'Document sans titre';

  @override
  String get docSearchKindCase => 'Pièce de dossier';

  @override
  String get docSearchKindVault => 'Document du coffre-fort';

  @override
  String get docSearchMenuTitle => 'Rechercher dans mes documents';

  @override
  String get docSearchMenuSubtitle =>
      'Trouvez tout dans vos propres fichiers par le sens';

  @override
  String get legalTemplatesTitle => 'Bibliothèque de modèles';

  @override
  String get legalTemplatesMenuLabel => 'Modèles';

  @override
  String get legalTemplatesSubtitle =>
      'Choisissez un formulaire prêt à l\'emploi, renseignez quelques informations et nous créerons un brouillon que vous pourrez modifier et exporter.';

  @override
  String get legalTemplatesDisclaimer =>
      'Ce sont des modèles de formulaires généraux, non un conseil juridique individuel. Relisez-les et adaptez-les avant l\'envoi.';

  @override
  String get legalTemplatesSampleBadge => 'Exemple';

  @override
  String get legalTemplatesEmpty =>
      'Aucun modèle pour ce filtre pour l\'instant.';

  @override
  String get legalTemplatesError =>
      'Impossible de charger les modèles. Veuillez réessayer.';

  @override
  String get legalTemplatesFilterAll => 'Tous';

  @override
  String get legalTemplatesJurisdictionFi => 'Finlande';

  @override
  String get legalTemplatesJurisdictionEe => 'Estonie';

  @override
  String get legalTemplatesCategoryComplaint => 'Réclamations';

  @override
  String get legalTemplatesCategoryAppeal => 'Recours';

  @override
  String get legalTemplatesCategoryApplication => 'Demandes';

  @override
  String get legalTemplatesCategoryClaim => 'Créances';

  @override
  String get legalTemplatesCategoryRequest => 'Requêtes';

  @override
  String get legalTemplatesFillTitle => 'Renseignez les informations';

  @override
  String get legalTemplatesFillIntro =>
      'Nous remplirons automatiquement votre nom et les détails de l\'affaire. Complétez les champs ci-dessous.';

  @override
  String get legalTemplatesFieldRequired => 'Ce champ est obligatoire';

  @override
  String get legalTemplatesCreateDraft => 'Créer le brouillon';

  @override
  String get legalTemplatesCreating => 'Création du brouillon…';

  @override
  String get legalTemplatesCreateFailed =>
      'Impossible de créer le brouillon. Veuillez réessayer.';

  @override
  String get legalTemplatesUnresolvedWarning =>
      'Certains champs sont encore vides et sont marqués par ____ dans le brouillon. Vous pouvez les compléter dans l\'éditeur.';

  @override
  String get legalTemplatesFieldRecipient =>
      'Destinataire (autorité / propriétaire)';

  @override
  String get legalTemplatesFieldAddress => 'Votre adresse postale';

  @override
  String get legalTemplatesFieldSubject => 'Objet';

  @override
  String get legalTemplatesFieldDescription => 'Description de l\'affaire';

  @override
  String get legalTemplatesFieldDemand => 'Ce que vous demandez';

  @override
  String get checklistActionPlan => 'Plan d\'action';

  @override
  String get checklistActionPlanSubtitle => 'Étapes pour ce type d\'affaire';

  @override
  String checklistProgress(int completed, int total) {
    return '$completed étapes sur $total effectuées';
  }

  @override
  String get checklistAllDone => 'Toutes les étapes sont terminées';

  @override
  String get checklistEmpty =>
      'Aucun plan d\'action n\'est encore disponible pour ce type d\'affaire.';

  @override
  String checklistDeadlineDays(int days) {
    return '$days jours';
  }

  @override
  String get checklistDisclaimer =>
      'Il s\'agit d\'informations générales, et non d\'un conseil juridique. Les délais sont les délais légaux par défaut — confirmez la date exacte pour votre affaire.';

  @override
  String get checklistViewPlan => 'Voir le plan';

  @override
  String get explainPlainTitle => 'Expliquer en langage clair';

  @override
  String get explainPlainIntro =>
      'Collez un courrier officiel, une décision ou un contrat, et nous vous expliquerons ce qu\'il signifie et ce qu\'il vous demande de faire — en langage clair.';

  @override
  String get explainPlainLevelFriend => 'Comme à un ami';

  @override
  String get explainPlainLevelTerms => 'Conserver les termes juridiques';

  @override
  String get explainPlainInputHint => 'Collez le texte juridique ici…';

  @override
  String get explainPlainSubmit => 'Expliquer';

  @override
  String get explainPlainWorking => 'Explication en cours…';

  @override
  String get explainPlainTldr => 'En résumé';

  @override
  String get explainPlainBreakdown => 'Ce qu\'il dit, point par point';

  @override
  String get explainPlainGlossary => 'Les termes délicats expliqués';

  @override
  String get explainPlainNextSteps => 'Ce que vous pouvez faire ensuite';

  @override
  String get explainPlainOpenInCorpus =>
      'Rechercher dans la bibliothèque juridique';

  @override
  String get explainPlainEmptyResult =>
      'Aucune explication n\'a pu être produite pour ce texte. Essayez de coller un extrait plus long ou plus clair.';

  @override
  String get explainPlainQuotaTitle =>
      'Vous avez utilisé vos explications gratuites ce mois-ci';

  @override
  String get explainPlainQuotaBody =>
      'Les comptes gratuits bénéficient de 3 explications par mois. Passez à Pro pour des explications illimitées.';

  @override
  String get explainPlainUpgradeCta => 'Passer à Pro';

  @override
  String get explainPlainError =>
      'Une erreur s\'est produite lors de l\'explication de ce texte. Veuillez réessayer.';

  @override
  String get explainPlainRetry => 'Réessayer';

  @override
  String get demandLetterTitle => 'Lettre de mise en demeure';

  @override
  String get demandLetterSubtitle =>
      'Créez une mise en demeure formelle préalable à toute action en justice (maksuvaatimus / nõudekiri).';

  @override
  String get demandLetterStepType => 'Type de créance';

  @override
  String get demandLetterStepParties => 'Parties';

  @override
  String get demandLetterStepClaim => 'Montant et fondement';

  @override
  String get demandLetterStepDeadline => 'Délai';

  @override
  String get demandLetterStepReview => 'Vérifier et générer';

  @override
  String get demandLetterClaimDepositReturn =>
      'Restitution du dépôt de garantie';

  @override
  String get demandLetterClaimUnpaidWage => 'Salaires impayés';

  @override
  String get demandLetterClaimFineDispute => 'Contester une amende / un frais';

  @override
  String get demandLetterClaimGeneric => 'Autre créance pécuniaire';

  @override
  String get demandLetterJurisdiction => 'Juridiction';

  @override
  String get demandLetterLanguage => 'Langue de la lettre';

  @override
  String get demandLetterRecipientName => 'Nom du destinataire';

  @override
  String get demandLetterRecipientAddress =>
      'Adresse du destinataire (facultatif)';

  @override
  String get demandLetterSenderName => 'Votre nom';

  @override
  String get demandLetterSenderAddress => 'Votre adresse / e-mail (facultatif)';

  @override
  String get demandLetterAmount => 'Montant';

  @override
  String get demandLetterCurrency => 'Devise';

  @override
  String get demandLetterBasis =>
      'Ce qui s\'est passé (fondement de la créance)';

  @override
  String get demandLetterBasisHint =>
      'Décrivez les faits : dates, montants, ce qui a été convenu et ce qui a mal tourné.';

  @override
  String get demandLetterDeadline => 'Délai de paiement';

  @override
  String get demandLetterDeadlineHint =>
      'ex. 14 jours à compter d\'aujourd\'hui';

  @override
  String get demandLetterReference => 'Référence (facultatif)';

  @override
  String get demandLetterGenerate => 'Générer la lettre';

  @override
  String get demandLetterGenerating => 'Génération en cours…';

  @override
  String get demandLetterGenerateFailed =>
      'Impossible de générer la lettre. Veuillez réessayer.';

  @override
  String get demandLetterFieldRequired => 'Ce champ est obligatoire';

  @override
  String get demandLetterNext => 'Suivant';

  @override
  String get demandLetterBack => 'Retour';

  @override
  String get demandLetterPreviewTitle => 'Votre lettre';

  @override
  String get demandLetterCopy => 'Copier le texte';

  @override
  String get demandLetterCopied => 'Lettre copiée dans le presse-papiers';

  @override
  String get demandLetterExportPdf => 'Exporter le PDF';

  @override
  String get demandLetterExporting => 'Exportation en cours…';

  @override
  String get demandLetterExportFailed =>
      'Impossible d\'exporter le document. Veuillez réessayer.';

  @override
  String get demandLetterSendEmail => 'Envoyer par e-mail';

  @override
  String get demandLetterNormsTitle => 'Références juridiques';

  @override
  String get demandLetterDisclaimer =>
      'Cette lettre est préparée en votre nom à partir d\'un modèle général. Elle ne constitue ni un conseil juridique ni un acte d\'un avocat agréé. Relisez-la avant l\'envoi — aucune lettre n\'est envoyée automatiquement.';

  @override
  String get demandLetterMenuTile => 'Lettre de mise en demeure';

  @override
  String get calcHubTitle => 'Calculateurs juridiques';

  @override
  String get calcHubSubtitle =>
      'Estimations rapides avant votre prochaine étape';

  @override
  String get calcHubJurisdiction => 'Juridiction';

  @override
  String calcRatesAsOf(String date) {
    return 'Taux au $date';
  }

  @override
  String get calcRatesOffline => 'Affichage des taux en cache (hors ligne)';

  @override
  String get calcIndicativeBanner =>
      'Estimation indicative uniquement — ce n\'est ni un calcul officiel ni un conseil juridique.';

  @override
  String get calcCalculate => 'Calculer';

  @override
  String get calcResult => 'Résultat';

  @override
  String get calcFormula => 'Méthode de calcul';

  @override
  String get calcSource => 'Source';

  @override
  String get calcSeveranceTitle => 'Indemnité / préavis';

  @override
  String get calcSeveranceDesc =>
      'Estimez l\'indemnité de licenciement et la durée du préavis en cas de suppression de poste';

  @override
  String get calcSeveranceSalary => 'Salaire mensuel brut';

  @override
  String get calcSeveranceTenure => 'Années d\'ancienneté';

  @override
  String get calcSeveranceTotal => 'Indemnité estimée';

  @override
  String get calcSeveranceNotice => 'Durée du préavis';

  @override
  String get calcSeveranceGenerateDemand =>
      'Rédiger une lettre de mise en demeure';

  @override
  String get calcLimitationTitle => 'Délais de prescription et de recours';

  @override
  String get calcLimitationDesc =>
      'Vérifiez si un délai de réclamation ou de recours a expiré';

  @override
  String get calcLimitationType => 'Type de délai';

  @override
  String get calcLimitationStart => 'Date de départ (événement / décision)';

  @override
  String get calcLimitationPickDate => 'Choisir une date';

  @override
  String get calcLimitationDeadline => 'Date limite';

  @override
  String get calcLimitationExpired => 'Le délai a expiré';

  @override
  String calcLimitationDaysLeft(int days) {
    return '$days jours restants';
  }

  @override
  String get calcLimitationShifted =>
      'Reporté au jour ouvrable suivant (week-end / jour férié).';

  @override
  String get calcLimitationAddDeadline => 'Ajouter aux délais';

  @override
  String get calcStateFeeTitle => 'Frais de justice / d\'État';

  @override
  String get calcStateFeeDesc =>
      'Frais de dépôt de référence par tribunal et par étape';

  @override
  String get calcChildSupportTitle => 'Pension alimentaire (orientation)';

  @override
  String get calcChildSupportDesc =>
      'Chiffre indicatif approximatif — le montant réel est fixé au cas par cas';

  @override
  String get calcChildSupportNet => 'Revenu mensuel net du débiteur';

  @override
  String get calcChildSupportChildren => 'Nombre d\'enfants';

  @override
  String get calcChildSupportPerChild => 'Par enfant';

  @override
  String get calcChildSupportTotal => 'Total mensuel';

  @override
  String get calcChildSupportWarning =>
      'Très variable. Les tribunaux statuent selon les besoins de l\'enfant et la capacité contributive des deux parents. À utiliser comme point de départ uniquement.';

  @override
  String get docCollectTitle => 'Documents à réunir';

  @override
  String get docCollectSubtitle =>
      'Rassemblez ces documents avant de déposer une demande ou de saisir un tribunal';

  @override
  String get docCollectPickPrompt => 'Quelle est votre situation ?';

  @override
  String get docCollectProblemResidence => 'Titre de séjour';

  @override
  String get docCollectProblemTenant => 'Location / expulsion';

  @override
  String get docCollectProblemDismissal => 'Licenciement';

  @override
  String get docCollectProblemInheritance => 'Succession';

  @override
  String get docCollectProblemDivorce => 'Divorce';

  @override
  String docCollectProgress(int collected, int total) {
    return '$collected sur $total réunis';
  }

  @override
  String get docCollectAllDone => 'Tout est réuni';

  @override
  String get docCollectEmpty =>
      'Aucune liste de documents n\'est encore disponible pour cette situation.';

  @override
  String get docCollectOptional => 'Facultatif';

  @override
  String get docCollectWhereLabel => 'Où l\'obtenir';

  @override
  String get docCollectWhyLabel => 'Pourquoi il est nécessaire';

  @override
  String get docCollectAttach => 'Joindre un fichier';

  @override
  String get docCollectAttached => 'Fichier joint';

  @override
  String get docCollectChangeFile => 'Changer de fichier';

  @override
  String get docCollectRemoveFile => 'Retirer le fichier';

  @override
  String get docCollectNoFiles => 'Vous n\'avez encore importé aucun document.';

  @override
  String get docCollectPickFileTitle => 'Choisir un document importé';

  @override
  String get docCollectExport => 'Exporter la liste';

  @override
  String get docCollectExportSubject => 'Ma liste de documents';

  @override
  String get docCollectAiTitle => 'Besoin de quelque chose de précis ?';

  @override
  String get docCollectAiHint =>
      'Décrivez votre situation et nous vous suggérerons les documents supplémentaires.';

  @override
  String get docCollectAiField => 'Décrivez votre situation';

  @override
  String get docCollectAiButton => 'Suggérer des documents supplémentaires';

  @override
  String get docCollectAiLoading => 'Réflexion en cours…';

  @override
  String get docCollectAiEmpty =>
      'Aucun document supplémentaire suggéré — la liste de base semble complète pour votre description.';

  @override
  String get docCollectAiSuggestionsTitle =>
      'Documents supplémentaires suggérés';

  @override
  String get docCollectDisclaimer =>
      'Il s\'agit d\'une liste de base des documents couramment exigés — votre situation peut en nécessiter davantage ou moins. Ce sont des informations générales, et non un conseil juridique.';

  @override
  String get docCollectRetry => 'Réessayer';

  @override
  String get renewalTitle => 'Radar de renouvellement';

  @override
  String get renewalSubtitle =>
      'Suivez les dates d\'expiration de vos titres, passeport, assurance et autres documents. Nous vous rappellerons chaque renouvellement 90, 30 et 7 jours à l\'avance.';

  @override
  String get renewalAdd => 'Ajouter un document';

  @override
  String get renewalEditTitle => 'Modifier le document';

  @override
  String get renewalSave => 'Enregistrer';

  @override
  String get renewalRequired => 'Obligatoire';

  @override
  String get renewalPickDate => 'Choisir la date d\'expiration';

  @override
  String get renewalLoadError =>
      'Impossible de charger vos documents. Tirez pour actualiser.';

  @override
  String get renewalEmptyTitle => 'Aucun document suivi pour le moment';

  @override
  String get renewalEmptyBody =>
      'Ajoutez votre titre de séjour, passeport, assurance ou permis, et nous surveillerons les dates d\'expiration pour vous.';

  @override
  String get renewalGuideHint => 'Comment renouveler →';

  @override
  String get renewalFieldType => 'Type de document';

  @override
  String get renewalFieldLabel => 'Libellé';

  @override
  String get renewalFieldNumber => 'Numéro du document (facultatif)';

  @override
  String get renewalFieldJurisdiction => 'Pays de délivrance';

  @override
  String get renewalFieldExpiry => 'Date d\'expiration';

  @override
  String get renewalWindow90 => '90 jours';

  @override
  String get renewalWindow30 => '30 jours';

  @override
  String get renewalWindow7 => '7 jours';

  @override
  String get renewalExpiresToday => 'Expire aujourd\'hui';

  @override
  String renewalExpiresInDays(int days, String date) {
    return 'Expire dans $days jours · $date';
  }

  @override
  String renewalExpiredOn(String date) {
    return 'A expiré le $date';
  }

  @override
  String get renewalTypeResidencePermit => 'Titre de séjour';

  @override
  String get renewalTypePassport => 'Passeport';

  @override
  String get renewalTypeIdCard => 'Carte d\'identité';

  @override
  String get renewalTypeVisa => 'Visa';

  @override
  String get renewalTypeDrivingLicence => 'Permis de conduire';

  @override
  String get renewalTypeInsurance => 'Assurance';

  @override
  String get renewalTypeWorkPermit => 'Permis de travail';

  @override
  String get renewalTypeOther => 'Autre';

  @override
  String get costEstimateTitle => 'Estimateur de coût et de risque';

  @override
  String get costEstimateSubtitle =>
      'Obtenez une idée approximative de ce qu\'une affaire pourrait coûter, du temps qu\'elle pourrait prendre et de l\'intérêt de la poursuivre.';

  @override
  String get costEstimateCaseTypeLabel => 'Type d\'affaire';

  @override
  String get costEstimateCaseTypeHint =>
      'ex. facture impayée, licenciement abusif, litige sur un dépôt de garantie';

  @override
  String get costEstimateJurisdictionLabel => 'Juridiction';

  @override
  String get costEstimateAmountLabel => 'Montant en litige (facultatif)';

  @override
  String get costEstimateAmountHint => 'ex. 12500';

  @override
  String get costEstimateDescriptionLabel =>
      'Décrivez brièvement la situation (facultatif)';

  @override
  String get costEstimateB2bToggle =>
      'Fiche de qualification de prospect (B2B)';

  @override
  String get costEstimateB2bSubtitle =>
      'Résultat compact pour trier rapidement un client entrant.';

  @override
  String get costEstimateSubmit => 'Estimer mon affaire';

  @override
  String get costEstimateDisclaimer =>
      'Estimation approximative uniquement — ce n\'est ni une prévision, ni une garantie, ni un conseil juridique. Les coûts et résultats réels varient au cas par cas.';

  @override
  String get costEstimateCostsHeading => 'Coûts estimés';

  @override
  String get costEstimateCourtFee => 'Frais de justice / d\'État';

  @override
  String get costEstimateLawyerFee => 'Honoraires d\'avocat';

  @override
  String get costEstimateTotal => 'Total (approx.)';

  @override
  String get costEstimateDuration => 'Délai jusqu\'au premier dénouement';

  @override
  String get costEstimateMonthsSuffix => 'mois';

  @override
  String get costEstimateFactorsFor => 'En votre faveur';

  @override
  String get costEstimateFactorsAgainst => 'À votre désavantage';

  @override
  String get costEstimateStrengthWorth =>
      'Vaut probablement la peine d\'être poursuivie';

  @override
  String get costEstimateStrengthContested =>
      'Incertaine — l\'issue pourrait basculer d\'un côté ou de l\'autre';

  @override
  String get costEstimateStrengthWeak => 'Faible — à poursuivre avec prudence';
}
