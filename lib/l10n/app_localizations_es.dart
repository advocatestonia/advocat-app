// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Advocat — Herramienta de información jurídica';

  @override
  String get onboardingTitle1 => 'Información jurídica con IA';

  @override
  String get onboardingDesc1 =>
      'Advocat le ayuda a comprender su situación legal. Las herramientas de IA analizan documentos, identifican posibles problemas y preparan borradores de documentos para su revisión. No es un bufete de abogados — es una herramienta tecnológica para apoyar su caso.';

  @override
  String get onboardingTitle2 => 'Escanee y analice documentos';

  @override
  String get onboardingDesc2 =>
      'Fotografe cualquier documento legal. La IA lo lee en varios idiomas, extrae los datos clave y verifica el cumplimiento de las directivas de la UE y las leyes nacionales.';

  @override
  String get onboardingTitle3 => 'La IA verifica posibles problemas';

  @override
  String get onboardingDesc3 =>
      'Nuestras herramientas de IA verifican más de 40 tipos de requisitos procesales. El análisis de IA puede identificar problemas que requieren atención — como el idioma de notificación, los pasos procesales y los plazos legales. Siempre verifique con un abogado cualificado.';

  @override
  String get onboardingTitle4 => 'Borradores de documentos para su revisión';

  @override
  String get onboardingDesc4 =>
      'La IA prepara borradores de apelaciones, quejas y cartas con referencias legales para su revisión. Usted decide qué presentar. Cada documento debe ser revisado por un profesional jurídico cualificado antes de presentarlo.';

  @override
  String get onboardingNext => 'Siguiente';

  @override
  String get onboardingSkip => 'Omitir';

  @override
  String get getStarted => 'Comenzar';

  @override
  String get welcomeBack => 'Bienvenido de nuevo';

  @override
  String get signInSubtitle => 'Inicie sesión para acceder a sus casos';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get logIn => 'Entrar';

  @override
  String get signUp => 'Crear cuenta';

  @override
  String get createAccount => 'Crear cuenta';

  @override
  String get email => 'Correo electrónico';

  @override
  String get password => 'Contraseña';

  @override
  String get confirmPassword => 'Confirmar contraseña';

  @override
  String get fullName => 'Nombre completo';

  @override
  String get forgotPassword => '¿Olvidó la contraseña?';

  @override
  String get orDivider => 'o';

  @override
  String get continueWithGoogle => 'Continuar con Google';

  @override
  String get noAccount => '¿No tiene cuenta? ';

  @override
  String get signUpLink => 'Registrarse';

  @override
  String get alreadyHaveAccount => '¿Ya tiene cuenta? ';

  @override
  String get signInLink => 'Entrar';

  @override
  String get emailRequired => 'El correo electrónico es obligatorio';

  @override
  String get emailInvalid => 'Introduzca una dirección de correo válida';

  @override
  String get passwordRequired => 'La contraseña es obligatoria';

  @override
  String get passwordTooShort =>
      'La contraseña debe tener al menos 8 caracteres';

  @override
  String get passwordsDoNotMatch => 'Las contraseñas no coinciden';

  @override
  String get nameRequired => 'El nombre completo es obligatorio';

  @override
  String get termsRequired => 'Debe aceptar los Términos de servicio';

  @override
  String get agreeToTerms => 'Acepto los ';

  @override
  String get termsOfService => 'Términos de servicio';

  @override
  String get andWord => ' y ';

  @override
  String get privacyPolicy => 'Política de privacidad';

  @override
  String get preferredLanguage => 'Idioma preferido';

  @override
  String get langEnglish => 'Inglés';

  @override
  String get langRussian => 'Ruso';

  @override
  String get langFinnish => 'Finlandés';

  @override
  String get passwordStrengthWeak => 'Débil';

  @override
  String get passwordStrengthMedium => 'Media';

  @override
  String get passwordStrengthStrong => 'Fuerte';

  @override
  String get loginFailed =>
      'Correo o contraseña no válidos. Inténtelo de nuevo.';

  @override
  String get registerFailed => 'Error en el registro. Inténtelo de nuevo.';

  @override
  String get resetPasswordSent =>
      'Enlace de restablecimiento enviado a su correo.';

  @override
  String get resetPasswordFailed =>
      'No se pudo enviar el enlace. Inténtelo de nuevo.';

  @override
  String get myCases => 'Mis casos';

  @override
  String get newCase => 'Nuevo caso';

  @override
  String get noCases => 'Aún no hay casos';

  @override
  String get documents => 'Documentos';

  @override
  String get timeline => 'Cronología';

  @override
  String get aiAssistant => 'Asistente jurídico IA';

  @override
  String get settings => 'Ajustes';

  @override
  String get language => 'Idioma';

  @override
  String get subscription => 'Suscripción';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get disclaimer =>
      'Solo orientación de IA — no es asesoramiento legal. Consulte siempre a un abogado.';

  @override
  String get scanDocument => 'Escanear documento';

  @override
  String get camera => 'Cámara';

  @override
  String get gallery => 'Galería';

  @override
  String get saveAndAnalyze => 'Guardar y analizar';

  @override
  String get retry => 'Reintentar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get error => 'Error';

  @override
  String get loading => 'Cargando...';

  @override
  String get home => 'Inicio';

  @override
  String get cases => 'Casos';

  @override
  String get deadlines => 'Plazos';

  @override
  String get scan => 'Escanear';

  @override
  String goodMorning(String name) {
    return 'Buenos días, $name';
  }

  @override
  String goodAfternoon(String name) {
    return 'Buenas tardes, $name';
  }

  @override
  String goodEvening(String name) {
    return 'Buenas noches, $name';
  }

  @override
  String get caseOverview => 'Aquí está el resumen de sus casos';

  @override
  String get activeCases => 'Casos activos';

  @override
  String get recentActivity => 'Actividad reciente';

  @override
  String urgentDeadline(String title) {
    return 'Urgente: $title';
  }

  @override
  String daysRemaining(int count) {
    return '$count días';
  }

  @override
  String get overdue => 'Vencido';

  @override
  String get upcoming => 'Próximo';

  @override
  String get completed => 'Completado';

  @override
  String get markComplete => 'Marcar como completado';

  @override
  String get deportation => 'Deportación';

  @override
  String get criminalCase => 'Caso penal';

  @override
  String get asylum => 'Asilo';

  @override
  String get residencePermit => 'Permiso de residencia';

  @override
  String get victimSupport => 'Apoyo a víctimas';

  @override
  String get familyReunification => 'Reunificación familiar';

  @override
  String get laborDispute => 'Conflicto laboral';

  @override
  String get tenantRights => 'Derechos del inquilino';

  @override
  String get debtCollection => 'Cobro de deudas';

  @override
  String get discrimination => 'Discriminación';

  @override
  String get policeMisconduct => 'Conducta policial indebida';

  @override
  String get socialBenefits => 'Prestaciones sociales';

  @override
  String get other => 'Otro';

  @override
  String get caseDetail => 'Detalles del caso';

  @override
  String get aiAnalysis => 'Análisis de IA';

  @override
  String get draftAppeal => 'Borrador de apelación';

  @override
  String get aiChat => 'Chat IA';

  @override
  String get correspondence => 'Correspondencia';

  @override
  String get analyzing => 'Analizando...';

  @override
  String get readingDocument => 'Leyendo documento...';

  @override
  String get checkingErrors => 'Comprobando errores...';

  @override
  String get researchingLaw => 'Investigando la ley aplicable...';

  @override
  String issuesFound(int count) {
    return '$count problemas encontrados';
  }

  @override
  String get critical => 'Crítico';

  @override
  String get important => 'Importante';

  @override
  String get informational => 'Informativo';

  @override
  String get useInAppeal => 'Usar en apelación';

  @override
  String get addedToAppeal => 'Añadido a la apelación';

  @override
  String get generateAppeal => 'Generar apelación';

  @override
  String get exportPdf => 'Exportar PDF';

  @override
  String get sendViaEmail => 'Enviar por correo';

  @override
  String get copyText => 'Copiar texto';

  @override
  String get editDraft => 'Editar';

  @override
  String get saveDraft => 'Guardar';

  @override
  String get reviewWarning =>
      'Revise cuidadosamente antes de enviar. Usted es responsable del contenido.';

  @override
  String get disclaimerFull =>
      'Este es un asistente de IA, no un abogado. El análisis de IA puede contener errores. Siempre verifique con un profesional jurídico cualificado.';

  @override
  String get askAboutCase => 'Analizar mi caso';

  @override
  String get whatAreMyOptions => '¿Cuáles son mis opciones?';

  @override
  String get checkDeadlines => 'Verificar plazos';

  @override
  String get typeMessage => 'Escriba un mensaje...';

  @override
  String get connectEmail => 'Conectar correo';

  @override
  String get connectGmail => 'Conectar Gmail';

  @override
  String get connectOutlook => 'Conectar Outlook';

  @override
  String get emailConnected => 'Correo conectado';

  @override
  String get syncNow => 'Sincronizar ahora';

  @override
  String get disconnect => 'Desconectar';

  @override
  String get emailPrivacyNote =>
      'Solo leemos correos relacionados con asuntos legales. Sus correos personales permanecen privados.';

  @override
  String get pushNotifications => 'Notificaciones push';

  @override
  String get deadlineReminders => 'Recordatorios de plazos';

  @override
  String get deadlineRemindersDesc =>
      'Reciba notificaciones antes de los plazos';

  @override
  String get editProfile => 'Editar perfil';

  @override
  String get exportMyData => 'Exportar mis datos';

  @override
  String get exportDataDesc => 'Descargar todos los datos de sus casos';

  @override
  String get deleteAccount => 'Eliminar cuenta';

  @override
  String get deleteAccountDesc => 'Eliminar permanentemente su cuenta';

  @override
  String get deleteConfirm =>
      '¿Está seguro? Esto eliminará permanentemente todos sus datos.';

  @override
  String get about => 'Acerca de';

  @override
  String get version => 'Versión';

  @override
  String get rateUs => 'Valórenos';

  @override
  String get contactSupport => 'Contactar soporte';

  @override
  String get tryDemoMode => 'Probar modo demo';

  @override
  String get demoModeDesc =>
      'Explore la app con datos de ejemplo de un caso real';

  @override
  String get free => 'Gratis';

  @override
  String get basic => 'Básico';

  @override
  String get pro => 'Pro';

  @override
  String get emergencyShield => 'Escudo de emergencia';

  @override
  String get legalFighter => 'Luchador legal';

  @override
  String get fullDefense => 'Defensa completa';

  @override
  String get popular => 'POPULAR';

  @override
  String get currentPlan => 'Plan actual';

  @override
  String get choosePlan => 'Elegir plan';

  @override
  String get saveWithAnnual => 'Ahorre 25% con facturación anual';

  @override
  String get restorePurchases => 'Restaurar compras';

  @override
  String get country => 'País';

  @override
  String get caseDescription => 'Describa su situación';

  @override
  String get caseTitle => 'Título del caso';

  @override
  String get referenceNumber => 'Número de referencia';

  @override
  String get uploadDocument => 'Subir documento';

  @override
  String get optional => '(opcional)';

  @override
  String step(int current, int total) {
    return 'Paso $current de $total';
  }

  @override
  String get next => 'Siguiente';

  @override
  String get back => 'Atrás';

  @override
  String get createCase => 'Crear caso';

  @override
  String get searchCases => 'Buscar casos...';

  @override
  String get all => 'Todos';

  @override
  String get active => 'Activos';

  @override
  String get closed => 'Cerrados';

  @override
  String lastActivity(String time) {
    return 'Última actividad: $time';
  }

  @override
  String documentsCount(int count) {
    return '$count docs';
  }

  @override
  String get noCasesYet => 'Aún no hay casos';

  @override
  String get startFirstCase => 'Comience su primer caso';

  @override
  String get noDeadlines => 'Sin plazos pendientes — ¡todo en orden!';

  @override
  String get appealFiled => 'Apelación presentada';

  @override
  String get pendingDecision => 'Decisión pendiente';

  @override
  String get inProgress => 'En curso';

  @override
  String get won => 'Ganado';

  @override
  String get lost => 'Perdido';

  @override
  String get preferences => 'PREFERENCIAS';

  @override
  String get notifications => 'NOTIFICACIONES';

  @override
  String get emailIntegration => 'INTEGRACIÓN DE CORREO';

  @override
  String get dataAndPrivacy => 'DATOS Y PRIVACIDAD';

  @override
  String get legalSection => 'LEGAL';

  @override
  String get aboutSection => 'ACERCA DE';

  @override
  String get appVersion => 'Versión de la app';

  @override
  String get selectLanguage => 'Seleccionar idioma';

  @override
  String get signOutConfirm => '¿Está seguro de que desea cerrar sesión?';

  @override
  String get emailDisconnected => 'Correo desconectado';

  @override
  String get syncLegalCorrespondence => 'Sincronizar correspondencia legal';

  @override
  String get requestExport => 'Solicitar exportación';

  @override
  String get exportDataDialogContent =>
      'Prepararemos una descarga de todos sus datos, incluidos casos, documentos y correspondencia. Recibirá un correo cuando esté listo.';

  @override
  String get deleteAccountDialogContent =>
      'Esta acción es permanente e irreversible. Todos sus datos, casos y documentos serán eliminados permanentemente.';

  @override
  String get areYouAbsolutelySure => '¿Está completamente seguro?';

  @override
  String get typeDeleteToConfirm =>
      'Escriba DELETE para confirmar la eliminación permanente de la cuenta.';

  @override
  String get permanentlyDelete => 'Eliminar permanentemente';

  @override
  String get dataExportRequested =>
      'Exportación de datos solicitada. Revise su correo.';

  @override
  String get connected => 'Conectado';

  @override
  String get caseUpdated => 'Caso actualizado';

  @override
  String get noRecentActivity => 'Sin actividad reciente';

  @override
  String get couldNotLoadCases => 'No se pudieron cargar sus casos';

  @override
  String get viewAll => 'Ver todos';

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
