// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get about => 'Acerca de';

  @override
  String get aboutSection => 'ACERCA DE';

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
  String get accidents => 'Accidentes';

  @override
  String get active => 'Activos';

  @override
  String get activeCases => 'Casos activos';

  @override
  String get addedToAppeal => 'Añadido a la apelación';

  @override
  String get agreeToTerms => 'Acepto los ';

  @override
  String get aiAnalysis => 'Análisis de IA';

  @override
  String get aiAssistant => 'Asistente jurídico IA';

  @override
  String get aiChat => 'Chat IA';

  @override
  String get all => 'Todos';

  @override
  String get alreadyHaveAccount => '¿Ya tiene cuenta? ';

  @override
  String get analyzing => 'Analizando…';

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
  String get andWord => ' y ';

  @override
  String get appTitle => 'Advocat — Herramienta de información jurídica';

  @override
  String get appVersion => 'Versión de la app';

  @override
  String get appealFiled => 'Apelación presentada';

  @override
  String get areYouAbsolutelySure => '¿Está completamente seguro?';

  @override
  String get askAboutCase => 'Analizar mi caso';

  @override
  String get asylum => 'Asilo';

  @override
  String get back => 'Atrás';

  @override
  String get basic => 'Básico';

  @override
  String get beforeYouBuy => 'Antes de comprar';

  @override
  String get beforeYouWork => 'Antes de trabajar con ellos';

  @override
  String get camera => 'Cámara';

  @override
  String get cancel => 'Cancelar';

  @override
  String get caseDescription => 'Describa su situación';

  @override
  String get caseDetail => 'Detalles del caso';

  @override
  String get caseOverview => 'Aquí está el resumen de sus casos';

  @override
  String get caseTitle => 'Título del caso';

  @override
  String get caseUpdated => 'Caso actualizado';

  @override
  String get cases => 'Casos';

  @override
  String get checkCompany => 'Verificar empresa';

  @override
  String get checkDeadlines => 'Verificar plazos';

  @override
  String get checkVehicle => 'Verificar vehículo';

  @override
  String get checkerTitle => 'Verificador';

  @override
  String get checkingErrors => 'Comprobando errores…';

  @override
  String get choosePlan => 'Elegir plan';

  @override
  String get closed => 'Cerrados';

  @override
  String get companyName => 'Nombre o núm. de registro';

  @override
  String get completed => 'Completado';

  @override
  String get confirm => 'Confirmar';

  @override
  String get confirmPassword => 'Confirmar contraseña';

  @override
  String get connectEmail => 'Conectar correo';

  @override
  String get connectGmail => 'Conectar Gmail';

  @override
  String get connectOutlook => 'Conectar Outlook';

  @override
  String get connected => 'Conectado';

  @override
  String get contactSupport => 'Contactar soporte';

  @override
  String get continueWithGoogle => 'Continuar con Google';

  @override
  String get appleComingSoon => 'Coming soon';

  @override
  String get appleComingSoonMessage =>
      'Apple Sign-In becomes available soon. Use Google or email to continue.';

  @override
  String get copyText => 'Copiar texto';

  @override
  String get correspondence => 'Correspondencia';

  @override
  String get couldNotLoadCases => 'No se pudieron cargar sus casos';

  @override
  String get country => 'País';

  @override
  String get createAccount => 'Crear cuenta';

  @override
  String get createCase => 'Crear caso';

  @override
  String get criminalCase => 'Caso penal';

  @override
  String get critical => 'Crítico';

  @override
  String get currentPlan => 'Plan actual';

  @override
  String get dataAndPrivacy => 'DATOS Y PRIVACIDAD';

  @override
  String get dataExportRequested =>
      'Exportación de datos solicitada. Revise su correo.';

  @override
  String daysRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
      zero: 'ningún día restante',
    );
    return '$_temp0';
  }

  @override
  String get deadlineReminders => 'Recordatorios de plazos';

  @override
  String get deadlineRemindersDesc =>
      'Reciba notificaciones antes de los plazos';

  @override
  String get deadlines => 'Plazos';

  @override
  String get debtCollection => 'Cobro de deudas';

  @override
  String get deleteAccount => 'Eliminar cuenta';

  @override
  String get deleteAccountDesc => 'Eliminar permanentemente su cuenta';

  @override
  String get deleteAccountDialogContent =>
      'Esta acción es permanente e irreversible. Todos sus datos, casos y documentos serán eliminados permanentemente.';

  @override
  String get deleteConfirm =>
      '¿Está seguro? Esto eliminará permanentemente todos sus datos.';

  @override
  String get demoHint => 'Demo: prueba la matrícula «908FBT»';

  @override
  String get demoModeDesc =>
      'Explore la app con datos de ejemplo de un caso real';

  @override
  String get deportation => 'Deportación';

  @override
  String get disclaimer =>
      'Solo orientación de IA — no es asesoramiento legal. Consulte siempre a un abogado.';

  @override
  String get disclaimerFull =>
      'Este es un asistente de IA, no un abogado. El análisis de IA puede contener errores. Siempre verifique con un profesional jurídico cualificado.';

  @override
  String get disconnect => 'Desconectar';

  @override
  String get discrimination => 'Discriminación';

  @override
  String get doNotBuy => 'No comprar';

  @override
  String get documents => 'Documentos';

  @override
  String documentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documentos',
      one: '1 documento',
      zero: 'ningún documento',
    );
    return '$_temp0';
  }

  @override
  String get draftAppeal => 'Borrador de apelación';

  @override
  String get editDraft => 'Editar';

  @override
  String get editProfile => 'Editar perfil';

  @override
  String get email => 'Correo electrónico';

  @override
  String get emailConnected => 'Correo conectado';

  @override
  String get emailDisconnected => 'Correo desconectado';

  @override
  String get emailIntegration => 'INTEGRACIÓN DE CORREO';

  @override
  String get emailInvalid => 'Introduzca una dirección de correo válida';

  @override
  String get emailPrivacyNote =>
      'Solo leemos correos relacionados con asuntos legales. Sus correos personales permanecen privados.';

  @override
  String get emailRequired => 'El correo electrónico es obligatorio';

  @override
  String get emergencyShield => 'Escudo de emergencia';

  @override
  String get error => 'Error';

  @override
  String get exportDataDesc => 'Descargar todos los datos de sus casos';

  @override
  String get exportDataDialogContent =>
      'Prepararemos una descarga de todos sus datos, incluidos casos, documentos y correspondencia. Recibirá un correo cuando esté listo.';

  @override
  String get exportMyData => 'Exportar mis datos';

  @override
  String get exportPdf => 'Exportar PDF';

  @override
  String get familyReunification => 'Reunificación familiar';

  @override
  String get forgotPassword => '¿Olvidó la contraseña?';

  @override
  String get free => 'Gratis';

  @override
  String get fullDefense => 'Advocat Pro';

  @override
  String get fullName => 'Nombre completo';

  @override
  String get gallery => 'Galería';

  @override
  String get generateAppeal => 'Generar apelación';

  @override
  String get getStarted => 'Comenzar';

  @override
  String goodAfternoon(String name) {
    return 'Buenas tardes, $name';
  }

  @override
  String goodEvening(String name) {
    return 'Buenas noches, $name';
  }

  @override
  String goodMorning(String name) {
    return 'Buenos días, $name';
  }

  @override
  String goodNight(String name) {
    return 'Buenas noches, $name';
  }

  @override
  String get home => 'Inicio';

  @override
  String get important => 'Importante';

  @override
  String get inProgress => 'En curso';

  @override
  String get informational => 'Informativo';

  @override
  String get inspection => 'Inspección técnica';

  @override
  String get insurance => 'Seguro';

  @override
  String issuesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count problemas encontrados',
      one: '1 problema encontrado',
      zero: 'no se encontraron problemas',
    );
    return '$_temp0';
  }

  @override
  String get laborDispute => 'Conflicto laboral';

  @override
  String get langEnglish => 'Inglés';

  @override
  String get langFinnish => 'Finlandés';

  @override
  String get langRussian => 'Ruso';

  @override
  String get language => 'Idioma';

  @override
  String lastActivity(String time) {
    return 'Última actividad: $time';
  }

  @override
  String get legalFighter => 'Luchador legal';

  @override
  String get legalSection => 'LEGAL';

  @override
  String get licensePlate => 'Matrícula';

  @override
  String get loading => 'Cargando…';

  @override
  String get logIn => 'Entrar';

  @override
  String get loginFailed =>
      'Correo o contraseña no válidos. Inténtelo de nuevo.';

  @override
  String get lost => 'Perdido';

  @override
  String get markComplete => 'Marcar como completado';

  @override
  String get mileage => 'Kilometraje';

  @override
  String get myCases => 'Mis casos';

  @override
  String get nameRequired => 'El nombre completo es obligatorio';

  @override
  String get newCase => 'Nuevo caso';

  @override
  String get next => 'Siguiente';

  @override
  String get noAccount => '¿No tiene cuenta? ';

  @override
  String get noCases => 'Aún no hay casos';

  @override
  String get noCasesYet => 'Aún no hay casos';

  @override
  String get noDeadlines => 'Sin plazos pendientes — ¡todo en orden!';

  @override
  String get noRecentActivity => 'Sin actividad reciente';

  @override
  String get notifications => 'NOTIFICACIONES';

  @override
  String get onboardingDesc1 =>
      'Advocat le ayuda a comprender su situación legal. Las herramientas de IA analizan documentos, identifican posibles problemas y preparan borradores de documentos para su revisión. No es un bufete de abogados — es una herramienta tecnológica para apoyar su caso.';

  @override
  String get onboardingDesc2 =>
      'Fotografe cualquier documento legal. La IA lo lee en varios idiomas, extrae los datos clave y verifica el cumplimiento de las directivas de la UE y las leyes nacionales.';

  @override
  String get onboardingDesc3 =>
      'Nuestras herramientas de IA verifican más de 40 tipos de requisitos procesales. El análisis de IA puede identificar problemas que requieren atención — como el idioma de notificación, los pasos procesales y los plazos legales. Siempre verifique con un abogado cualificado.';

  @override
  String get onboardingDesc4 =>
      'La IA prepara borradores de apelaciones, quejas y cartas con referencias legales para su revisión. Usted decide qué presentar. Cada documento debe ser revisado por un profesional jurídico cualificado antes de presentarlo.';

  @override
  String get onboardingNext => 'Siguiente';

  @override
  String get onboardingSkip => 'Omitir';

  @override
  String get onboardingTitle1 => 'Información jurídica con IA';

  @override
  String get onboardingTitle2 => 'Escanee y analice documentos';

  @override
  String get onboardingTitle3 => 'La IA verifica posibles problemas';

  @override
  String get onboardingTitle4 => 'Borradores de documentos para su revisión';

  @override
  String get openACase => 'Abrir un caso';

  @override
  String get optional => '(opcional)';

  @override
  String get orDivider => 'o';

  @override
  String get other => 'Otro';

  @override
  String get overdue => 'Vencido';

  @override
  String get owners => 'Propietarios anteriores';

  @override
  String get password => 'Contraseña';

  @override
  String get passwordRequired => 'La contraseña es obligatoria';

  @override
  String get passwordStrengthMedium => 'Media';

  @override
  String get passwordStrengthStrong => 'Fuerte';

  @override
  String get passwordStrengthWeak => 'Débil';

  @override
  String get passwordTooShort =>
      'La contraseña debe tener al menos 8 caracteres';

  @override
  String get passwordsDoNotMatch => 'Las contraseñas no coinciden';

  @override
  String get pendingDecision => 'Decisión pendiente';

  @override
  String get perCheck => 'por verificación';

  @override
  String get permanentlyDelete => 'Eliminar permanentemente';

  @override
  String get policeMisconduct => 'Conducta policial indebida';

  @override
  String get popular => 'POPULAR';

  @override
  String get preferences => 'PREFERENCIAS';

  @override
  String get preferredLanguage => 'Idioma preferido';

  @override
  String get pricePerCheck => '4,99 € por verificación';

  @override
  String get privacyPolicy => 'Política de privacidad';

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
  String get pushNotifications => 'Notificaciones push';

  @override
  String get rateUs => 'Valórenos';

  @override
  String get rateAppComingSoon => 'Coming to app stores soon!';

  @override
  String get dataCopiedToClipboard => 'Data copied to clipboard';

  @override
  String get readingDocument => 'Leyendo documento…';

  @override
  String get recentActivity => 'Actividad reciente';

  @override
  String get referenceNumber => 'Número de referencia';

  @override
  String get registerFailed => 'Error en el registro. Inténtelo de nuevo.';

  @override
  String get reportFraud => 'Reportar fraude';

  @override
  String get requestExport => 'Solicitar exportación';

  @override
  String get researchingLaw => 'Investigando la ley aplicable…';

  @override
  String get resetPasswordFailed =>
      'No se pudo enviar el enlace. Inténtelo de nuevo.';

  @override
  String get resetPasswordSent =>
      'Enlace de restablecimiento enviado a su correo.';

  @override
  String get residencePermit => 'Permiso de residencia';

  @override
  String get manageSubscription => 'Gestionar suscripción';

  @override
  String get restorePurchases => 'Restaurar compras';

  @override
  String get retry => 'Reintentar';

  @override
  String get reviewWarning =>
      'Revise cuidadosamente antes de enviar. Usted es responsable del contenido.';

  @override
  String get riskHigh => 'Alto riesgo — evitar';

  @override
  String get riskLow => 'Seguro para trabajar';

  @override
  String get riskMedium => 'Proceder con cautela';

  @override
  String get safeToBuy => 'Seguro para comprar';

  @override
  String get saveAndAnalyze => 'Guardar y analizar';

  @override
  String get saveDraft => 'Guardar';

  @override
  String get saveWithAnnual => 'Ahorre 25% con facturación anual';

  @override
  String get scan => 'Escanear';

  @override
  String get scanDocument => 'Escanear documento';

  @override
  String get searchCases => 'Buscar casos…';

  @override
  String get selectCountry => 'Seleccionar país';

  @override
  String get selectLanguage => 'Seleccionar idioma';

  @override
  String get sendViaEmail => 'Enviar por correo';

  @override
  String get settings => 'Ajustes';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get signInLink => 'Entrar';

  @override
  String get signInSubtitle => 'Inicie sesión para acceder a sus casos';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get signOutConfirm => '¿Está seguro de que desea cerrar sesión?';

  @override
  String get signUp => 'Crear cuenta';

  @override
  String get signUpLink => 'Registrarse';

  @override
  String get socialBenefits => 'Prestaciones sociales';

  @override
  String get someConcerns => 'Algunas preocupaciones';

  @override
  String get startFirstCase => 'Comience su primer caso';

  @override
  String step(int current, int total) {
    return 'Paso $current de $total';
  }

  @override
  String get stolen => 'Verificación de robo';

  @override
  String get subscription => 'Suscripción';

  @override
  String get syncLegalCorrespondence => 'Sincronizar correspondencia legal';

  @override
  String get syncNow => 'Sincronizar ahora';

  @override
  String get tenantRights => 'Derechos del inquilino';

  @override
  String get termsOfService => 'Términos de servicio';

  @override
  String get termsRequired => 'Debe aceptar los Términos de servicio';

  @override
  String get timeline => 'Cronología';

  @override
  String get tryDemoMode => 'Probar modo demo';

  @override
  String get typeDeleteToConfirm =>
      'Escriba DELETE para confirmar la eliminación permanente de la cuenta.';

  @override
  String get typeMessage => 'Escriba un mensaje…';

  @override
  String get upcoming => 'Próximo';

  @override
  String get uploadDocument => 'Subir documento';

  @override
  String urgentDeadline(String title) {
    return 'Urgente: $title';
  }

  @override
  String get useInAppeal => 'Usar en apelación';

  @override
  String get vehicleChecker => 'Verificador de vehículos';

  @override
  String get vehicleChecks => 'Verificaciones de estado';

  @override
  String get vehicleColor => 'Color';

  @override
  String get vehicleMake => 'Marca';

  @override
  String get vehicleModel => 'Modelo';

  @override
  String get vehicleYear => 'Año';

  @override
  String get version => 'Versión';

  @override
  String get victimSupport => 'Apoyo a víctimas';

  @override
  String get viewAll => 'Ver todos';

  @override
  String get vinNumber => 'Número VIN';

  @override
  String get welcomeBack => 'Bienvenido de nuevo';

  @override
  String get whatAreMyOptions => '¿Cuáles son mis opciones?';

  @override
  String get won => 'Ganado';

  @override
  String get documentVault => 'Bóveda de documentos';

  @override
  String get secureDocumentStorage => 'Almacenamiento seguro de documentos';

  @override
  String get secureDocumentStorageDesc =>
      'Guarde sus documentos legales importantes en un solo lugar para acceso fácil.';

  @override
  String get addDocument => 'Añadir documento';

  @override
  String get chooseHowToAdd => 'Elija cómo añadir su documento';

  @override
  String get uploadFile => 'Subir archivo';

  @override
  String get uploadFileDesc => 'Elija un PDF o imagen de su dispositivo';

  @override
  String get scanDocumentDesc => 'Tome una foto de su documento';

  @override
  String get createNote => 'Crear nota';

  @override
  String get createNoteDesc =>
      'Escriba una nota o registre detalles importantes';

  @override
  String get knowYourRights => 'Conozca sus derechos';

  @override
  String get stoppedByPolice => 'Detenido por la policía';

  @override
  String get stoppedByPoliceDesc =>
      'Sus derechos durante un encuentro policial';

  @override
  String get deportationNotice => 'Notificación de deportación';

  @override
  String get deportationNoticeDesc =>
      'Pasos para impugnar una orden de expulsión';

  @override
  String get workplaceRights => 'Derechos laborales';

  @override
  String get workplaceRightsDesc => 'Protecciones laborales en Finlandia';

  @override
  String get tenantRightsDesc => 'Protecciones de vivienda y alquiler';

  @override
  String get immigrationDetention => 'Detención migratoria';

  @override
  String get immigrationDetentionDesc =>
      'Derechos si es detenido por las autoridades';

  @override
  String get discriminationDesc =>
      'Cómo denunciar y combatir la discriminación';

  @override
  String get scenarioNotFound => 'Escenario no encontrado';

  @override
  String get youHaveRightTo => 'Tiene derecho a:';

  @override
  String get youMust => 'Debe:';

  @override
  String get immediateSteps => 'Pasos inmediatos:';

  @override
  String get yourRights => 'Sus derechos:';

  @override
  String get basicRights => 'Derechos básicos:';

  @override
  String get yourRightsAsTenant => 'Sus derechos como inquilino:';

  @override
  String get yourRightsInDetention => 'Sus derechos en detención:';

  @override
  String get howToAct => 'Cómo actuar:';

  @override
  String get rightKnowWhyStopped => 'Saber por qué le han detenido';

  @override
  String get rightRemainSilent => 'Guardar silencio (debe identificarse)';

  @override
  String get rightAskInterpreter => 'Solicitar un intérprete';

  @override
  String get rightContactLawyer =>
      'Contactar un abogado antes del interrogatorio';

  @override
  String get rightRecordEncounter =>
      'Grabar el encuentro (en lugares públicos)';

  @override
  String get mustProvideName => 'Proporcione su nombre y fecha de nacimiento';

  @override
  String get mustShowId => 'Muestre su identificación si la tiene';

  @override
  String get mustNotResist => 'No resistir físicamente';

  @override
  String get doNotIgnoreNotice =>
      'NO ignore la notificación - los plazos son estrictos';

  @override
  String get noteAppealDeadline =>
      'Anote el plazo de apelación (normalmente 30 días)';

  @override
  String get contactLawyerImmediately => 'Contacte un abogado inmediatamente';

  @override
  String get applyLegalAid => 'Solicite asistencia jurídica si es necesario';

  @override
  String get rightAppealAdmin =>
      'Derecho a apelar ante el Tribunal Administrativo';

  @override
  String get rightLegalRep => 'Derecho a representación legal';

  @override
  String get rightInterpreter => 'Derecho a un intérprete';

  @override
  String get rightStayDuringAppeal =>
      'Derecho a permanecer durante la apelación (en la mayoría de los casos)';

  @override
  String get minimumWage => 'Salario mínimo según convenio colectivo';

  @override
  String get workingTimeLimits =>
      'Límites de jornada (máx. 8h/día, 40h/semana)';

  @override
  String get annualLeave =>
      'Vacaciones anuales (mínimo 2 días por mes trabajado)';

  @override
  String get sickLeave => 'Compensación por baja por enfermedad';

  @override
  String get safeWorkingConditions => 'Condiciones de trabajo seguras';

  @override
  String get writtenRentalAgreement => 'Contrato de alquiler escrito requerido';

  @override
  String get securityDeposit => 'Depósito de garantía máx. 3 meses de alquiler';

  @override
  String get landlordNotice => 'El arrendador debe dar aviso (3–6 meses)';

  @override
  String get rightHabitableDwelling => 'Derecho a una vivienda habitable';

  @override
  String get protectionUnjustEviction => 'Protección contra desalojo injusto';

  @override
  String get rightKnowDetentionReason =>
      'Derecho a conocer el motivo de la detención';

  @override
  String get rightContactLawyerDetention => 'Derecho a contactar un abogado';

  @override
  String get rightContactEmbassy => 'Derecho a contactar su embajada';

  @override
  String get rightChallengeDetention =>
      'Derecho a impugnar la detención ante un tribunal';

  @override
  String get rightHumaneTreatment =>
      'Derecho a un trato humano y atención médica';

  @override
  String get documentIncident =>
      'Documente el incidente (fecha, hora, testigos)';

  @override
  String get fileComplaintOmbudsman =>
      'Presentar queja ante el Defensor contra la Discriminación';

  @override
  String get contactLegalAidOffice =>
      'Contacte una oficina de asistencia jurídica';

  @override
  String get reportToPolice =>
      'Denunciar a la policía si es delito (amenaza, agresión)';

  @override
  String get legalAidCalculator => 'Calculadora de asistencia jurídica';

  @override
  String checkEligibility(String country) {
    return 'Verifique su elegibilidad para la asistencia jurídica: $country';
  }

  @override
  String get estimateDisclaimer =>
      'Esta es solo una estimación. La elegibilidad real la determina la Oficina de Asistencia Jurídica.';

  @override
  String get monthlyIncome => 'Ingreso mensual (EUR)';

  @override
  String get totalAssets => 'Activos totales (EUR)';

  @override
  String get numberOfDependents => 'Número de dependientes';

  @override
  String get calculateEligibility => 'Calcular elegibilidad';

  @override
  String get likelyEligible => 'Probablemente elegible';

  @override
  String get mayNotQualify => 'Puede no calificar';

  @override
  String get fullFreeLegalAid =>
      'Probablemente califica para asistencia jurídica gratuita completa (sin copago).';

  @override
  String legalAidWithCopay(String percent) {
    return 'Puede calificar para asistencia jurídica con un copago del $percent%.';
  }

  @override
  String get mayNotQualifyDesc =>
      'Según esta estimación, puede no calificar para asistencia jurídica estatal. Considere consultar a un abogado privado o clínica legal.';

  @override
  String get couldNotLoadDeadlines => 'No se pudieron cargar los plazos';

  @override
  String get noUpcomingDeadlines => 'Sin plazos próximos';

  @override
  String get allClearDeadlines =>
      '¡Todo en orden! Los nuevos plazos aparecerán aquí cuando se establezcan.';

  @override
  String get nothingOverdue => 'Nada vencido';

  @override
  String get greatJobDeadlines =>
      '¡Buen trabajo manteniendo sus plazos al día!';

  @override
  String get noCompletedDeadlines => 'Sin plazos completados';

  @override
  String get completedDeadlinesDesc =>
      'Los plazos completados se mostrarán aquí.';

  @override
  String get daysLate => 'días de retraso';

  @override
  String get days => 'días';

  @override
  String get fromDocument => 'Del documento';

  @override
  String get couldNotLoadCase => 'No se pudieron cargar los detalles del caso';

  @override
  String get typeLabel => 'Tipo';

  @override
  String get nationality => 'Nacionalidad';

  @override
  String get migriReference => 'Referencia Migri';

  @override
  String get courtCaseNo => 'Nº de caso judicial';

  @override
  String get created => 'Creado';

  @override
  String get citizenship => 'Ciudadanía';

  @override
  String get workPermit => 'Permiso de trabajo';

  @override
  String get noDocumentsYet => 'Aún no se han subido documentos';

  @override
  String get noUpcomingDeadlinesShort => 'Sin plazos próximos';

  @override
  String get caseCreated => 'Caso creado';

  @override
  String get decisionReceived => 'Decisión recibida';

  @override
  String get appealDeadline => 'Plazo de apelación';

  @override
  String get hearingScheduled => 'Audiencia programada';

  @override
  String get late => 'atrasado';

  @override
  String get pending => 'Pendiente';

  @override
  String get processing => 'Procesando';

  @override
  String get ready => 'Listo';

  @override
  String get failed => 'Fallido';

  @override
  String get analyzed => 'Analizado';

  @override
  String get noDocumentsScanHint =>
      'Aún no hay documentos. Escanee o suba uno.';

  @override
  String get inCourt => 'En el tribunal';

  @override
  String get appeal => 'Apelación';

  @override
  String get caseTimeline => 'Cronología del caso';

  @override
  String get couldNotLoadTimeline => 'No se pudo cargar la cronología';

  @override
  String get noEventsYet => 'Aún no hay eventos';

  @override
  String get activityWillAppear =>
      'La actividad aparecerá aquí a medida que avance su caso.';

  @override
  String caseCreatedDesc(String title) {
    return 'Se ha creado el caso «$title».';
  }

  @override
  String get decisionReceivedDesc =>
      'Se recibió una decisión oficial para este caso.';

  @override
  String get appealDeadlineSet => 'Plazo de apelación establecido';

  @override
  String appealDeadlineDesc(String date) {
    return 'La apelación debe presentarse antes del $date.';
  }

  @override
  String hearingScheduledDesc(String date) {
    return 'Audiencia judicial programada para $date.';
  }

  @override
  String get caseInfoUpdated =>
      'La información del caso se actualizó por última vez.';

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
  String get documentAnalysis => 'Análisis de documentos';

  @override
  String get exportAsPdf => 'Exportar como PDF';

  @override
  String get pdfExportComingSoon => 'Exportación PDF próximamente';

  @override
  String get analysisFailedRetry => 'Análisis fallido. Inténtelo de nuevo.';

  @override
  String get somethingWentWrong => 'Algo salió mal';

  @override
  String get genericError => 'Algo salió mal. Por favor, inténtelo de nuevo.';

  @override
  String get retryAnalysis => 'Reintentar análisis';

  @override
  String issuesFoundInDocument(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se encontraron $count problemas en su documento',
      one: 'Se encontró 1 problema en su documento',
      zero: 'No se encontraron problemas en su documento',
    );
    return '$_temp0';
  }

  @override
  String get severityOverview => 'Resumen de gravedad';

  @override
  String get issuesFoundHeader => 'Problemas encontrados';

  @override
  String generateAppealWithIssues(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Generar apelación ($count problemas)',
      one: 'Generar apelación (1 problema)',
    );
    return '$_temp0';
  }

  @override
  String get analyzingContent => 'Analizando contenido…';

  @override
  String get documentProcessedOk => 'Documento procesado correctamente';

  @override
  String get noSignificantIssues =>
      'No se detectaron problemas significativos en este documento.';

  @override
  String get cameraPermissionRequired => 'Se requiere permiso de cámara';

  @override
  String get cameraPermissionDesc =>
      'Conceda acceso a la cámara para escanear documentos o use la galería.';

  @override
  String get openSettings => 'Abrir configuración';

  @override
  String get alignDocument => 'Alinee el documento dentro del marco';

  @override
  String pageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count páginas',
      one: '1 página',
      zero: 'ninguna página',
    );
    return '$_temp0';
  }

  @override
  String get preview => 'Vista previa';

  @override
  String pageNumber(int number) {
    return 'Página $number';
  }

  @override
  String get done => 'Hecho';

  @override
  String get retake => 'Repetir';

  @override
  String get useThisPhoto => 'Usar esta foto';

  @override
  String get addPage => 'Añadir página';

  @override
  String uploadingPercent(int percent) {
    return 'Subiendo… $percent%';
  }

  @override
  String get preparingUpload => 'Preparando subida…';

  @override
  String get documentUploadedSuccess => 'Documento subido correctamente';

  @override
  String pagesUploadedSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count páginas subidas con éxito',
      one: '1 página subida con éxito',
    );
    return '$_temp0';
  }

  @override
  String get uploadFailed =>
      'Error en la subida. Verifique su conexión e inténtelo de nuevo.';

  @override
  String get capturePhotoFailed =>
      'Error al capturar la foto. Inténtelo de nuevo.';

  @override
  String get readingText => 'Leyendo texto…';

  @override
  String get draftDocument => 'Borrador de documento';

  @override
  String get saveChanges => 'Guardar cambios';

  @override
  String get editDocument => 'Editar documento';

  @override
  String get generatingDraft => 'Generando su borrador…';

  @override
  String get generatingDraftDesc =>
      'La IA está preparando un documento legal basado en los detalles de su caso y los problemas seleccionados.';

  @override
  String get failedToGenerateDraft =>
      'Error al generar el borrador. Inténtelo de nuevo.';

  @override
  String get changesSaved => 'Cambios guardados';

  @override
  String get copiedToClipboard => 'Copiado al portapapeles';

  @override
  String get emailComingSoon => 'Envío de email próximamente';

  @override
  String get reviewBeforeSending =>
      'Revise cuidadosamente antes de enviar. Usted es responsable del contenido de este documento.';

  @override
  String get noContentAvailable => 'Sin contenido disponible';

  @override
  String get save => 'Guardar';

  @override
  String get edit => 'Editar';

  @override
  String get pdf => 'PDF';

  @override
  String get copy => 'Copiar';

  @override
  String get appealDraft => 'Borrador de apelación';

  @override
  String selected(int count) {
    return '$count seleccionados';
  }

  @override
  String get deleteSelected => 'Eliminar seleccionados';

  @override
  String deleteDocumentsConfirm(int count) {
    return '¿Eliminar $count documentos?';
  }

  @override
  String get delete => 'Eliminar';

  @override
  String get analyzeSelected => 'Analizar seleccionados';

  @override
  String get batchAnalysisStarting => 'Iniciando análisis por lotes…';

  @override
  String get switchToList => 'Cambiar a lista';

  @override
  String get switchToGrid => 'Cambiar a cuadrícula';

  @override
  String get scanNew => 'Nuevo escaneo';

  @override
  String get noDocumentsYetScan => 'Aún no hay documentos';

  @override
  String get scanFirstDocumentHint =>
      'Escanee su primer documento para que la IA lo analice en busca de errores y genere apelaciones.';

  @override
  String get failedToLoadDocuments => 'Error al cargar los documentos';

  @override
  String get emailIntegrationTitle => 'Integración de email';

  @override
  String get connectYourEmail => 'Conecte su email';

  @override
  String get connectYourEmailDesc =>
      'Conecte su email para detectar y organizar automáticamente la correspondencia legal relacionada con sus casos.';

  @override
  String get legalEmails => 'Emails legales';

  @override
  String get unlinkedEmails => 'Emails no vinculados';

  @override
  String get noLegalEmailsYet => 'Aún no hay emails legales';

  @override
  String get legalEmailsWillAppear =>
      'Los emails clasificados como legales aparecerán aquí.';

  @override
  String get assignToCase => 'Asignar al caso';

  @override
  String get disconnectEmail => 'Desconectar email';

  @override
  String get disconnectEmailConfirm =>
      'Se detendrá la sincronización automática de email. Los emails sincronizados previamente permanecerán en sus casos.';

  @override
  String get gmailReauthBannerBody =>
      'Advocat v2.1 reads your inbox to draft replies; you can revoke any time. Reconnect Gmail to enable proactive triage.';

  @override
  String get gmailReauthBannerCta => 'Reauthorize';

  @override
  String connectedTo(String email) {
    return 'Conectado a $email';
  }

  @override
  String lastSynced(String time) {
    return 'Última sincronización: $time';
  }

  @override
  String get filterByType => 'Filtrar por tipo';

  @override
  String get noCasesMatchSearch => 'Ningún caso coincide con su búsqueda';

  @override
  String get failedToLoadCases => 'Error al cargar los casos';

  @override
  String get monthly => 'Mensual';

  @override
  String get annual => 'Anual';

  @override
  String get saveTwentyFivePercent => 'Ahorre 25%';

  @override
  String get mostPopular => 'MÁS POPULAR';

  @override
  String get oneCaseActive => '1 caso activo';

  @override
  String get threeCasesActive => '3 casos activos';

  @override
  String get unlimitedCases => 'Casos ilimitados';

  @override
  String get threeDocScans => '3 escaneos de documentos';

  @override
  String get twentyDocScans => '20 escaneos de documentos';

  @override
  String get unlimitedDocScans => 'Escaneo ilimitado de documentos';

  @override
  String get basicAiAnalysis => 'Análisis básico de IA';

  @override
  String get fullAiAnalysis => 'Análisis completo de IA';

  @override
  String get draftGeneration => 'Generación de borradores';

  @override
  String get priorityProcessing => 'Procesamiento prioritario';

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
  String get forever => 'para siempre';

  @override
  String get perMonth => '/mes';

  @override
  String get perYear => '/año';

  @override
  String get checkingPurchases => 'Verificando compras anteriores…';

  @override
  String get noPreviousPurchases => 'No se encontraron compras anteriores.';

  @override
  String get chatWelcomeMessage =>
      'Hi! I\'m Advocat — your AI legal assistant. I provide legal information, not legal advice. What legal question can I help with?';

  @override
  String get copySummary => 'Copiar resumen';

  @override
  String get caseSummaryCopied => 'Resumen del caso copiado';

  @override
  String get openCase => 'Abrir caso';

  @override
  String get viewFull => 'Ver completo';

  @override
  String get draftCopiedToClipboard => 'Borrador copiado al portapapeles';

  @override
  String get reportMileageFraud => 'Reportar fraude de kilometraje';

  @override
  String get reportMileageFraudDesc =>
      'Se creará un informe de fraude basado en los datos de verificación del vehículo. También puede abrir un caso legal.';

  @override
  String get reportAndOpenCase => 'Reportar y abrir caso';

  @override
  String get caseCreationComingSoon =>
      'Creación de caso con datos prellenados próximamente';

  @override
  String get failedToCreateCaseRetry =>
      'Error al crear el caso. Inténtelo de nuevo.';

  @override
  String get takePhotoInstead => 'Tomar foto en su lugar';

  @override
  String get deleteCase => 'Eliminar caso';

  @override
  String deleteCaseConfirm(String title) {
    return '¿Está seguro de eliminar «$title»? Esta acción no se puede deshacer.';
  }

  @override
  String get haveQuestionsAi => '¿Preguntas? Hable con la IA';

  @override
  String get cookiePolicy => 'Política de cookies';

  @override
  String get aiDisclaimer => 'Aviso sobre IA';

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
  String get dataPrivacyConsent => 'Consentimiento de privacidad de datos';

  @override
  String get gdprIntro =>
      'Para proporcionar asistencia legal con IA, procesamos sus datos de acuerdo con el RGPD (UE 2016/679). Al continuar, acepta:';

  @override
  String get gdprChat => 'Procesamiento de mensajes de chat por IA';

  @override
  String get gdprDocs => 'Análisis de documentos subidos';

  @override
  String get gdprStorage => 'Almacenamiento cifrado de datos de casos';

  @override
  String get gdprDelete => 'Derecho a eliminar sus datos en cualquier momento';

  @override
  String get gdprFooter =>
      'Sus datos están cifrados y nunca se comparten con terceros. Puede retirar el consentimiento y eliminar todos los datos desde Configuración.';

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
  String get aiGeneratedDisclaimer =>
      'Generado por IA • No es asesoramiento legal';

  @override
  String get decline => 'Rechazar';

  @override
  String get iAgree => 'Acepto';

  @override
  String get iAgreeToThe => 'Acepto los ';

  @override
  String get orWord => 'o';

  @override
  String get english => 'Inglés';

  @override
  String get russian => 'Ruso';

  @override
  String get finnish => 'Finlandés';

  @override
  String successSubscribed(String plan) {
    return '¡Suscripción a $plan exitosa!';
  }

  @override
  String paymentFailed(String error) {
    return 'Pago fallido: $error';
  }

  @override
  String get whatToDo => 'Qué hacer';

  @override
  String get getHelp => 'Obtener ayuda';

  @override
  String get share => 'Compartir';

  @override
  String get didYouKnow => '¿Sabía que?';

  @override
  String get mustKnow => 'Debe saber';

  @override
  String get goodToKnow => 'Bueno saber';

  @override
  String get sentFromAdvocat => 'Enviado desde la app Advocat';

  @override
  String get policeActionStayCalm => 'Mantenga la calma y las manos visibles';

  @override
  String get policeActionAskWhy => 'Pregunte al agente por qué le han detenido';

  @override
  String get policeActionProvideName =>
      'Proporcione su nombre y fecha de nacimiento';

  @override
  String get policeActionWantLawyer =>
      'Diga claramente: «Quiero un abogado antes de responder preguntas»';

  @override
  String get policeActionAskInterpreter =>
      'Solicite un intérprete si es necesario';

  @override
  String get policeActionNoteBadge =>
      'Anote el nombre y número de placa del agente';

  @override
  String get policeFactMustTellReason =>
      'En Finlandia, la policía debe decirle el motivo de la detención. Si no lo hacen, puede preguntar — y están legalmente obligados a explicar.';

  @override
  String get policeFactCanRecord =>
      'Puede grabar las interacciones policiales en lugares públicos en Finlandia. Esto está protegido por la libertad de expresión.';

  @override
  String get contactFinnishLegalAid => 'Asistencia jurídica finlandesa';

  @override
  String get contactNonDiscriminationOmbudsman =>
      'Defensor contra la Discriminación';

  @override
  String get deportationDeadlineAppeal =>
      'Apelación ante el Tribunal Administrativo — generalmente 30 días desde la notificación';

  @override
  String get deportationDeadlineLegalAid =>
      'Solicite asistencia jurídica — hágalo INMEDIATAMENTE';

  @override
  String get deportationFactStayDuringAppeal =>
      'En Finlandia, generalmente tiene derecho a permanecer en el país mientras se tramita su apelación. La deportación no puede ejecutarse durante una apelación activa en la mayoría de los casos.';

  @override
  String get contactRefugeeAdviceCentre =>
      'Centro Finlandés de Asesoría a Refugiados';

  @override
  String get contactAdminCourtHelsinki => 'Tribunal Administrativo de Helsinki';

  @override
  String get workplaceActionKeepContract =>
      'Guarde copias de su contrato de trabajo';

  @override
  String get workplaceActionTrackHours =>
      'Registre sus horas de trabajo de forma independiente';

  @override
  String get workplaceActionReportUnsafe =>
      'Denuncie las condiciones inseguras a la inspección de trabajo';

  @override
  String get workplaceActionJoinUnion =>
      'Afíliese a un sindicato para protegerse';

  @override
  String get workplaceActionContactAuthority =>
      'Contacte la Autoridad de Seguridad Laboral si es necesario';

  @override
  String get workplaceFactCollectiveWage =>
      'En Finlandia, los convenios colectivos fijan los salarios mínimos por sector — no hay un salario mínimo nacional único. Su empleador debe cumplir el convenio colectivo de su sector.';

  @override
  String get workplaceFactOralContract =>
      'Incluso sin contrato escrito, tiene plenos derechos laborales en Finlandia. Un acuerdo oral es igualmente vinculante por ley.';

  @override
  String get contactOccupationalSafety => 'Autoridad de Seguridad Laboral';

  @override
  String get contactTradeUnionSAK => 'Asesoría sindical (SAK)';

  @override
  String get tenantActionWrittenAgreement =>
      'Siempre tenga un contrato de alquiler por escrito';

  @override
  String get tenantActionDocumentCondition =>
      'Documente el estado del apartamento al mudarse (fotos)';

  @override
  String get tenantActionReportMaintenance =>
      'Informe los problemas de mantenimiento por escrito';

  @override
  String get tenantActionNoIllegalEviction =>
      'Nunca acepte un desalojo ilegal — los tribunales deben decidir';

  @override
  String get tenantActionContactAdvisory =>
      'Contacte servicios de asesoría al inquilino si hay disputas';

  @override
  String get tenantFactNoEvictionWithoutCourt =>
      'Un arrendador en Finlandia no puede desalojarle sin orden judicial, incluso si su contrato ha expirado. Cambiar cerraduras o cortar servicios es ilegal.';

  @override
  String get contactTenantsAssociation => 'Asociación Finlandesa de Inquilinos';

  @override
  String get contactConsumerDisputesBoard => 'Junta de Disputas del Consumidor';

  @override
  String get detentionActionAskDecision =>
      'Solicite inmediatamente la decisión de detención por escrito';

  @override
  String get detentionActionRequestLawyer => 'Solicite contactar un abogado';

  @override
  String get detentionActionContactEmbassy =>
      'Contacte su embajada o consulado';

  @override
  String get detentionActionAskMedical =>
      'Solicite atención médica si es necesario';

  @override
  String get detentionActionRequestInterpreter =>
      'Solicite un intérprete para todos los procedimientos';

  @override
  String get detentionDeadlineCourtReview =>
      'El tribunal de distrito debe revisar la detención en 4 días';

  @override
  String get detentionDeadlineContinuation =>
      'El tribunal revisa la continuación cada 2 semanas';

  @override
  String get detentionFactCourtReview =>
      'La detención migratoria en Finlandia debe ser revisada por un tribunal de distrito en 4 días. Si no se hace, la detención se vuelve ilegal.';

  @override
  String get contactParliamentaryOmbudsman =>
      'Defensor del Pueblo Parlamentario';

  @override
  String get discriminationActionWriteDown =>
      'Anote exactamente lo que sucedió (fecha, hora, lugar)';

  @override
  String get discriminationActionSaveEvidence =>
      'Guarde las pruebas: mensajes, correos, testigos';

  @override
  String get discriminationActionFileComplaint =>
      'Presente una queja ante el Defensor contra la Discriminación';

  @override
  String get discriminationActionContactLegalAid =>
      'Contacte una oficina de asistencia jurídica para asesoría gratuita';

  @override
  String get discriminationActionReportPolice =>
      'Denuncie a la policía si hubo amenazas o agresión';

  @override
  String get discriminationFactNonDiscriminationAct =>
      'La Ley de No Discriminación de Finlandia cubre la discriminación por edad, origen, nacionalidad, idioma, religión, salud, discapacidad, orientación sexual y otras características personales.';

  @override
  String get contactVictimSupportRIKU => 'Apoyo a Víctimas Finlandia (RIKU)';

  @override
  String get domesticViolence => 'Violencia doméstica';

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
  String get inheritance => 'Herencia';

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
  String get consumerProtection => 'Protección al consumidor';

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
  String get callAI => 'Llamar IA';

  @override
  String get comingSoon => 'Disponible pronto';

  @override
  String get encrypted => 'Cifrado';

  @override
  String get typing => 'Escribiendo…';

  @override
  String get online => 'En línea';

  @override
  String get chatWelcomeSubtitle =>
      'Analizaré la situación, revisaré documentos, buscaré errores y sugeriré qué hacer.';

  @override
  String get tapMicrophoneToSpeak => 'Toque el micrófono para hablar';

  @override
  String get categoryEssential => 'Esencial';

  @override
  String get categoryPolice => 'Policía';

  @override
  String get categoryWork => 'Trabajo';

  @override
  String get categoryHousing => 'Vivienda';

  @override
  String get categoryConsumer => 'Consumidor';

  @override
  String rightsInsideCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count derechos dentro',
      one: '1 derecho dentro',
      zero: 'ningún derecho dentro',
    );
    return '$_temp0';
  }

  @override
  String get freeAidThreshold => 'Umbral de ayuda gratuita';

  @override
  String get partialAidThreshold => 'Umbral de ayuda parcial';

  @override
  String get assetLimit => 'Límite de activos';

  @override
  String get whereToApplyLabel => 'Dónde solicitar';

  @override
  String get phoneLabel => 'Teléfono';

  @override
  String get websiteLabel => 'Sitio web';

  @override
  String get disclaimerCollapsed => 'Solo informativo';

  @override
  String get disclaimerExpanded =>
      'Asistente IA — no es asesoramiento legal. Siempre verifique con un abogado calificado.';

  @override
  String get chatDisclaimerBanner =>
      'El asistente IA proporciona información legal, no asesoramiento legal. Consulte siempre a un abogado calificado.';

  @override
  String get chatDisclaimerSubtitle =>
      'Asistente IA · no es asesoramiento legal';

  @override
  String get chatDisclaimerBannerFull =>
      'Advocat es un asistente de IA de información jurídica, no un abogado. La información aquí no crea una relación abogado-cliente, no constituye asesoramiento legal y puede contener errores. Para asesoramiento jurídico vinculante, consulte a un abogado colegiado en su jurisdicción. No le representamos.';

  @override
  String get chatDisclaimerFooter =>
      'Generado por IA. Verifique con un abogado colegiado.';

  @override
  String get chatDisclaimerGotIt => 'Entendido';

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
  String get guestUser => 'Invitado';

  @override
  String get howToUse => 'Como usar?';

  @override
  String get tutorialStep1Title => 'Asistente legal IA';

  @override
  String get tutorialStep1Desc =>
      'Haga cualquier pregunta legal y obtenga respuestas instantaneas basadas en la legislacion estonia.';

  @override
  String get tutorialStep2Title => 'Conozca sus derechos';

  @override
  String get tutorialStep2Desc =>
      'Explore informacion legal por temas — trabajo, vivienda, derechos del consumidor y mas.';

  @override
  String get tutorialStep3Title => 'Escanear documentos';

  @override
  String get tutorialStep3Desc =>
      'Tome fotos de documentos legales para analisis de IA y almacenamiento seguro.';

  @override
  String get tutorialStep4Title => 'Empecemos!';

  @override
  String get tutorialStep4Desc =>
      'Explore la aplicacion y proteja sus derechos. Todos los datos permanecen privados en su dispositivo.';

  @override
  String get advocatProTitle => 'Advocat Pro';

  @override
  String get advocatProSubtitle => 'Desbloquea funciones premium';

  @override
  String get voiceDisclaimer =>
      'El asistente de voz actualmente solo funciona en escritorio (navegador Chrome). Soporte móvil próximamente.';

  @override
  String get recommended => 'Recomendado';

  @override
  String get pleaseLogIn => 'Por favor, inicie sesión';

  @override
  String get subscriptionNotFound => 'Suscripción no encontrada';

  @override
  String errorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String get redirectingToPayment => 'Redirigiendo a la página de pago…';

  @override
  String cheaperAnnually(String amount) {
    return '€$amount/mes más barato anualmente';
  }

  @override
  String get navigatingTo => 'Abriendo';

  @override
  String get stayInChat => 'Quedarse en el chat';

  @override
  String get backToChat => 'Volver al chat';

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
  String get freeQuotaExhausted =>
      'You\'ve used all 10 free messages this month.';

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
  String get citationStatusVerifiedBadge => 'Verificada';

  @override
  String get citationStatusUnverifiedBadge => 'Sin verificar';

  @override
  String get citationStatusHistoricalBadge => 'Versión histórica';

  @override
  String get citationStatusVerifiedTooltip =>
      'Citada a partir de una fuente jurídica recuperada.';

  @override
  String get citationStatusUnverifiedTooltip =>
      'La IA citó este pasaje sin recuperar la fuente — verifíquelo antes de confiar en él.';

  @override
  String get citationStatusHistoricalTooltip =>
      'La disposición citada ya no se encuentra en vigor.';

  @override
  String get citationOpenInRiigiTeataja => 'Abrir en Riigi Teataja';

  @override
  String get citationSnippetExpand => 'Mostrar texto completo';

  @override
  String get citationSnippetCollapse => 'Mostrar menos';

  @override
  String get citationUnverifiedSheetNote =>
      'La IA citó este párrafo, pero no fue recuperado del corpus jurídico en esta consulta. Verifique la referencia antes de utilizarla.';

  @override
  String get citationFooterNoneWarning => 'Sin citas fundamentadas';

  @override
  String citationFooterSummaryTotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count citas',
      one: '1 cita',
    );
    return '$_temp0';
  }

  @override
  String citationFooterSummaryVerified(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count verificadas',
      one: '1 verificada',
    );
    return '$_temp0';
  }

  @override
  String citationFooterSummaryUnverified(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count no verificadas',
      one: '1 no verificada',
    );
    return '$_temp0';
  }

  @override
  String citationFooterSummaryHistorical(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count históricas',
      one: '1 histórica',
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
      other: 'en $count días',
      one: 'en 1 día',
      zero: 'hoy',
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
      other: '$count días de retraso',
      one: '1 día de retraso',
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
  String get reviewThisContract => 'Revisar este contrato';

  @override
  String get contractReviews => 'Revisiones de contrato';

  @override
  String get contractReviewsFreeFeature =>
      '1 revisión de contrato (prueba de por vida)';

  @override
  String get contractReviewsCounselFeature => '5 revisiones de contrato al mes';

  @override
  String get contractReviewsProFeature => '20 revisiones de contrato al mes';

  @override
  String contractReviewsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count revisiones de contratos restantes este mes',
      one: '1 revisión de contrato restante este mes',
      zero: 'No quedan revisiones de contratos este mes',
    );
    return '$_temp0';
  }

  @override
  String get contractReviewsExhausted =>
      'No quedan revisiones de contrato este mes';

  @override
  String get contractReviewsFreeTrialLeft =>
      'Prueba gratuita: 1 revisión de contrato';

  @override
  String get contractReviewsFreeTrialUsed =>
      'Prueba gratuita usada — actualiza';

  @override
  String get contractReviewsUpgradeTitle => 'Revisiones de contrato agotadas';

  @override
  String get contractReviewsUpgradeBodyFree =>
      'Has usado tu revisión de contrato gratuita. Actualiza para revisiones mensuales.';

  @override
  String contractReviewsUpgradeBodyPaid(int used, int cap) {
    return 'Has usado $used de $cap revisiones este mes. Actualiza para un límite mensual mayor.';
  }

  @override
  String get contractReviewsUpgradeCounselCta =>
      'Actualiza a Counsel (€19,99/mes) — 5 revisiones';

  @override
  String get contractReviewsUpgradeProCta =>
      'Actualiza a Pro (€29,99/mes) — 20 revisiones';

  @override
  String get contractReviewsUpgradeToProShort => 'Actualiza a Pro — 20/mes';

  @override
  String get notNow => 'Ahora no';

  @override
  String get referralTitle => 'Invitar amigos';

  @override
  String get referralSubtitle =>
      'Consigue un mes gratis. Regala un mes gratis.';

  @override
  String get referralYourLink => 'TU ENLACE';

  @override
  String get referralCopyLink => 'Copiar enlace';

  @override
  String get referralShare => 'Compartir';

  @override
  String get referralLinkCopied => 'Enlace copiado';

  @override
  String get referralStatsInvited => 'Invitados';

  @override
  String get referralStatsConverted => 'Convertidos';

  @override
  String get referralStatsEarned => 'Meses ganados';

  @override
  String get referralShareWhatsApp => 'Compartir en WhatsApp';

  @override
  String get referralShareTelegram => 'Compartir en Telegram';

  @override
  String get referralShareEmail => 'Compartir por correo';

  @override
  String get referralEmailSubject =>
      'Prueba Advocat — tu asistente legal con IA';

  @override
  String get referralLoadError =>
      'No se pudo cargar la información. Desliza para actualizar.';

  @override
  String get referralRetry => 'Reintentar';

  @override
  String get referralSettingsTile => 'Invitar amigos';

  @override
  String get referralAfterReviewCta =>
      '¿Te gustó? Invita a un amigo — ambos obtienen un mes gratis.';

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
  String get checkerProTagline => 'Herramientas profesionales de verificación';

  @override
  String get checkerDataSource => 'Datos de registros oficiales';

  @override
  String get companyCheckerHint => 'Nombre de la empresa o nº de registro';

  @override
  String get companyCheckerPriceChip =>
      '€2.99 por comprobación  •  Incluido en Pro';

  @override
  String get companyCheckerEmptyState =>
      'Introduzca el nombre de la empresa o el\nnúmero de registro para obtener un informe completo';

  @override
  String get aiMemoryTitle => 'Memoria de la IA';

  @override
  String get aiMemorySubtitle =>
      'Revise y elimine lo que la IA recuerda de usted';

  @override
  String get bookLawyerCallTitle => 'Reservar una llamada con un abogado';

  @override
  String get bookLawyerCallComingSoonTitle =>
      'Llamadas con abogados reales — próximamente';

  @override
  String get bookLawyerCallComingSoonBody =>
      'Pro y Premium incluyen llamadas de 15 minutos con un abogado asociado (1/trimestre en Pro, 2/trimestre en Premium). Estamos ultimando la red de abogados estonios independientes y le enviaremos un correo en cuanto se abran las reservas.';

  @override
  String bookLawyerCallQuotaAvailable(int remaining, int total) {
    return 'Le quedan $remaining de $total llamadas este trimestre.';
  }

  @override
  String get bookLawyerCallQuotaExhausted => 'Cuota trimestral agotada.';

  @override
  String get bookLawyerCallQuotaBodyAvailable =>
      'El nivel Pro incluye 1 llamada al trimestre, Premium 2. Las llamadas duran 15 minutos por Google Meet.';

  @override
  String get bookLawyerCallQuotaBodyExhausted =>
      'Su cuota se restablece el primer día del próximo trimestre. ¿Necesita hablar antes? Actualice a Premium para una llamada adicional.';

  @override
  String get severityCritical => 'CRÍTICO';

  @override
  String get severityHigh => 'ALTO';

  @override
  String get severityMedium => 'MEDIO';

  @override
  String get severityLow => 'BAJO';

  @override
  String get deadlineRequiredFields =>
      'El título y la fecha límite son obligatorios';

  @override
  String get acceptTermsRequired => 'Acepte los Términos del Servicio';

  @override
  String get chatLegalCouncilTooltip => 'Consejo jurídico (4 expertos)';

  @override
  String get attachFileTooltip => 'Adjuntar archivo';

  @override
  String get sendMessage => 'Enviar mensaje';

  @override
  String get stopGenerating => 'Detener generación';

  @override
  String get showPassword => 'Mostrar contraseña';

  @override
  String get hidePassword => 'Ocultar contraseña';

  @override
  String get decreaseDependents => 'Disminuir';

  @override
  String get increaseDependents => 'Aumentar';

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
  String get consiliumHeader => 'Consilio de abogados';

  @override
  String consiliumProgress(int count, int total) {
    return '$count de $total listos';
  }

  @override
  String get consiliumStarting => 'Los abogados están revisando su caso…';

  @override
  String get consiliumDisagreement => 'Los expertos no están de acuerdo';

  @override
  String get consiliumSynthesizing => 'Sintetizando recomendación…';

  @override
  String consiliumDone(int totalRoles) {
    return 'Consilio finalizado · $totalRoles expertos';
  }

  @override
  String get consiliumPositionPush => 'Impugnar';

  @override
  String get consiliumPositionSettle => 'Negociar';

  @override
  String get consiliumPositionInvestigate => 'Investigar';

  @override
  String get consiliumPositionOutOfScope => 'Fuera de competencia';

  @override
  String get consiliumConfidence => 'Confianza';

  @override
  String get consiliumKeyCitation => 'Referencia clave';

  @override
  String get consiliumAdversarialRound => 'Ronda contradictoria';

  @override
  String get consiliumViewFullOpinion => 'Ver dictamen completo';

  @override
  String consiliumExpertsAgreed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count expertos de acuerdo',
      one: '1 experto de acuerdo',
    );
    return '$_temp0';
  }

  @override
  String consiliumExpertsDisagree(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count expertos en desacuerdo',
      one: '1 experto en desacuerdo',
    );
    return '$_temp0';
  }

  @override
  String get consiliumDisclaimer =>
      'Agentes de IA, no abogados humanos. Verifique las decisiones importantes con un abogado colegiado.';

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
  String get iapPayWithApple => 'Pagar con Apple';

  @override
  String get iapRestorePurchases => 'Restaurar compras';

  @override
  String get iapPurchaseFailed =>
      'La compra falló. Inténtalo de nuevo o contacta con soporte.';

  @override
  String get iapRestoreSuccess => 'Tu suscripción ha sido restaurada.';

  @override
  String get iapRestoreNoActive =>
      'No se encontró ninguna suscripción activa para restaurar.';
}
