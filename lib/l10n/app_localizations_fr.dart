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
  String calcRatesAsOf(Object date) {
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
  String calcLimitationDaysLeft(Object days) {
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
  String docCollectProgress(Object collected, Object total) {
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
  String renewalExpiresInDays(Object date, Object days) {
    return 'Expires in $days days · $date';
  }

  @override
  String renewalExpiredOn(Object date) {
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
}
