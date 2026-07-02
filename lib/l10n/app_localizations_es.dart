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
  String get appearance => 'Apariencia';

  @override
  String get appearanceSystem => 'Sistema (automático)';

  @override
  String get appearanceLight => 'Claro';

  @override
  String get appearanceDark => 'Oscuro';

  @override
  String get appearanceDescription => 'Elige cómo se ve Advocat';

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
  String get aiAnalyzing => 'La IA está analizando';

  @override
  String get speakIntoMicHint =>
      'Hable por el micrófono. Asegúrese de que el acceso al micrófono esté habilitado.';

  @override
  String get aiErrorRateLimit =>
      'El servicio está temporalmente saturado. Vuelva a intentarlo en 1-2 minutos.';

  @override
  String get aiErrorOverload =>
      'La IA está ocupada en este momento, vuelva a intentarlo en un minuto.';

  @override
  String freeLimitReached(int count) {
    return 'Ha utilizado los $count mensajes de IA gratuitos. ¡Cambie a Asesoría Jurídica para obtener asistencia de IA ilimitada!';
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
  String get appleComingSoon => 'Próximamente';

  @override
  String get appleComingSoonMessage =>
      'El inicio de sesión con Apple estará disponible pronto. Use Google o el correo electrónico para continuar.';

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
  String get dpaTitle => 'Acuerdo de tratamiento de datos';

  @override
  String get dpaCheckoutGateTitle => 'Antes de mejorar su plan';

  @override
  String get dpaCheckoutGateBody =>
      'La legislación de la UE (art. 28 del RGPD) nos obliga a firmar un acuerdo de tratamiento de datos con cada cliente de pago. Léalo y acéptelo.';

  @override
  String get dpaViewLink => 'Ver el acuerdo de tratamiento de datos';

  @override
  String get dpaCheckboxLabel =>
      'He leído y acepto el acuerdo de tratamiento de datos (v1.0).';

  @override
  String get dpaCancel => 'Cancelar';

  @override
  String get dpaAcceptAndContinue => 'Aceptar y continuar';

  @override
  String get dpaOpenHint =>
      'Abra el acuerdo de tratamiento de datos al menos una vez para habilitar el botón Aceptar.';

  @override
  String get pro => 'Pro';

  @override
  String get pushNotifications => 'Notificaciones push';

  @override
  String get rateUs => 'Valórenos';

  @override
  String get rateAppComingSoon =>
      '¡Próximamente en las tiendas de aplicaciones!';

  @override
  String get dataCopiedToClipboard => 'Datos copiados al portapapeles';

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
  String get noEventsForFilter => 'Ningún evento coincide con este filtro';

  @override
  String get timelineFilterAll => 'Todos';

  @override
  String get timelineFilterEmails => 'Correos electrónicos';

  @override
  String get timelineFilterConsilium => 'Decisiones de IA';

  @override
  String get timelineFilterDeadlines => 'Plazos';

  @override
  String get timelineFilterNotes => 'Notas';

  @override
  String get timelineEventEmailIn => 'Correo recibido';

  @override
  String get timelineEventEmailOut => 'Correo enviado';

  @override
  String get timelineEventConsiliumDecision => 'Decisión de IA';

  @override
  String get timelineEventDeadlineSet => 'Plazo';

  @override
  String get timelineEventDocUploaded => 'Documento';

  @override
  String get timelineEventPhaseChange => 'Cambio de fase';

  @override
  String get timelineEventManualNote => 'Nota';

  @override
  String get timelineJustNow => 'Ahora mismo';

  @override
  String timelineMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count minutos',
      one: 'hace 1 minuto',
    );
    return '$_temp0';
  }

  @override
  String timelineHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count horas',
      one: 'hace 1 hora',
    );
    return '$_temp0';
  }

  @override
  String timelineDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count días',
      one: 'hace 1 día',
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
      'Advocat v2.1 lee su bandeja de entrada para redactar respuestas; puede revocar el acceso en cualquier momento. Vuelva a conectar Gmail para habilitar el triaje proactivo.';

  @override
  String get gmailReauthBannerCta => 'Volver a autorizar';

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
  String get fiveAiMessagesTotal => '5 mensajes de IA (de por vida)';

  @override
  String get hundredAiMessagesDay => '100 mensajes de IA/día';

  @override
  String get unlimitedAiMessages => 'Mensajes de IA ilimitados';

  @override
  String get voiceInput => 'Entrada de voz';

  @override
  String get strategyRecommendations => 'Recomendaciones de estrategia';

  @override
  String get foundingMemberNote =>
      'Miembro fundador: 9,99 €/mes durante los primeros 3 meses';

  @override
  String get saveTwentyPercent => 'Ahorre un 20 %';

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
      '¡Hola! Soy Advocat, su asistente legal de IA. Proporciono información jurídica, no asesoramiento legal. ¿En qué cuestión legal puedo ayudarle?';

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
      'Advocat es información jurídica generada por IA, no asesoramiento legal. Verifíquelo con un abogado colegiado antes de actuar.';

  @override
  String get aiDisclaimerFullTitle => 'Importante: cómo funciona Advocat';

  @override
  String get aiDisclaimerFullBody =>
      'Advocat es una herramienta de inteligencia artificial que proporciona información jurídica, no asesoramiento legal. En virtud del Reglamento de IA de la UE (art. 50), debemos informarle claramente: está interactuando con una IA, no con un abogado humano.\n\nAdvocat no es un bufete de abogados. No somos abogados colegiados conforme a la Advokatuuriseadus estonia ni a la Asianajajalaki finlandesa, y el secreto profesional abogado-cliente no se aplica a sus conversaciones con esta herramienta. Antes de actuar sobre la base de cualquier respuesta —para presentar un recurso, firmar un contrato o cumplir un plazo—, verifíquela con un abogado colegiado en su jurisdicción.';

  @override
  String get aiDisclaimerExpand => 'Más información';

  @override
  String get aiDisclaimerDismiss => 'Entendido';

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
      'Acepto el tratamiento de mis datos para la asistencia jurídica con IA (obligatorio)';

  @override
  String get gdprConsentAnalytics =>
      'Acepto el análisis de datos para mejorar el servicio (opcional)';

  @override
  String get gdprArt9Intro =>
      'Esta aplicación trata datos personales de categorías especiales conforme al artículo 9 del RGPD, incluidos:';

  @override
  String get gdprSpecialLegalCases =>
      'Los detalles de su caso jurídico y los documentos judiciales';

  @override
  String get gdprSpecialNationality => 'Nacionalidad y situación migratoria';

  @override
  String get gdprConsentLegalData =>
      'Consiento el tratamiento por IA de los datos de mi caso jurídico, mi nacionalidad y mi situación migratoria (obligatorio)';

  @override
  String get gdprConsentVoice =>
      'Consiento el tratamiento de grabaciones de voz (opcional)';

  @override
  String get gdprViewPrivacyPolicy => 'Ver la política de privacidad';

  @override
  String get legalInformation => 'Información legal';

  @override
  String get legalEntityName => 'Vorantis OÜ';

  @override
  String get legalRegistryCode => 'Código de registro: 17098992';

  @override
  String get legalAddress =>
      'Harju maakond, Tallinn, Kesklinna linnaosa, Tornimäe tn 5, 10145';

  @override
  String get legalEmail => 'Correo electrónico: support@advocat.ee';

  @override
  String get legalRegistry =>
      'Inscrita en el Registro Mercantil de Estonia (Äriregister)';

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
      'Derechos de la víctima, ayuda de emergencia, órdenes de alejamiento';

  @override
  String get rightCallEmergency =>
      'Tiene derecho a llamar al 112 en cualquier emergencia: policía, ambulancia, bomberos';

  @override
  String get rightVictimProtection =>
      'Como víctima, tiene derecho a protección, apoyo e información sobre su caso';

  @override
  String get rightRestrainingOrder =>
      'Puede solicitar una orden de alejamiento (lähestymiskielto) para mantener alejado al agresor';

  @override
  String get rightVictimInterpreter =>
      'Tiene derecho a un intérprete durante todas las actuaciones judiciales';

  @override
  String get rightMedicalHelp =>
      'Tiene derecho a recibir tratamiento médico inmediato y a la documentación de las lesiones';

  @override
  String get rightShelter =>
      'Tiene derecho a un refugio de emergencia: póngase en contacto con un refugio o con los servicios sociales';

  @override
  String get mustReportDanger =>
      'Si alguien está en peligro inminente, llame al 112 de inmediato';

  @override
  String get mustDocumentInjuries =>
      'Documente todas las lesiones: fotos, informes médicos, notas escritas';

  @override
  String get domesticActionCallEmergency =>
      'Llame al 112 si está en peligro inminente';

  @override
  String get domesticActionGoToSafe =>
      'Vaya a un lugar seguro: refugio, casa de un amigo, lugar público';

  @override
  String get domesticActionDocumentEverything =>
      'Documente las lesiones: tome fotos, obtenga informes médicos';

  @override
  String get domesticActionFilePoliceReport =>
      'Presente una denuncia policial: también puede hacerlo más adelante';

  @override
  String get domesticActionContactShelter =>
      'Póngase en contacto con un refugio o una línea de ayuda en crisis';

  @override
  String get domesticActionApplyRestraining =>
      'Solicite una orden de alejamiento a través de la policía o el tribunal';

  @override
  String get domesticFactRestrainingOrder =>
      'En Finlandia, una orden de alejamiento (lähestymiskielto) puede dictarse incluso sin causa penal. Prohíbe a la persona contactarle o acercarse a usted.';

  @override
  String get domesticFactVictimDirective =>
      'Conforme a la Directiva de la UE sobre las víctimas 2012/29/UE, tiene derecho a ser tratada con respeto, a recibir información en un idioma que entienda y a acceder a los servicios de apoyo a las víctimas, con independencia de su situación de residencia.';

  @override
  String get domesticDeadlinePoliceReport =>
      'Presentar denuncia policial: sin plazo estricto, pero cuanto antes mejor para las pruebas';

  @override
  String get domesticDeadlineRestraining =>
      'Orden de alejamiento: puede solicitarse en cualquier momento';

  @override
  String get contactEmergency => 'Número de emergencias';

  @override
  String get contactShelter => 'Línea de ayuda Turvakoti (refugio)';

  @override
  String get contactCrisisHelpline =>
      'Línea de ayuda en crisis (Kriisipuhelin)';

  @override
  String get contactNollaLinja =>
      'Nollalinja: línea de ayuda contra la violencia hacia las mujeres';

  @override
  String get inheritance => 'Herencia';

  @override
  String get inheritanceDesc =>
      'Testamentos, herencia, derechos de los herederos, legítima, sucesión';

  @override
  String get rightInheritanceForced =>
      'Los herederos forzosos (hijos, cónyuge) tienen derecho a una legítima con independencia del testamento';

  @override
  String get rightInheritanceWill =>
      'Tiene derecho a otorgar testamento disponiendo de sus bienes; los testamentos notariales tienen la mayor fuerza legal';

  @override
  String get rightInheritanceRenounce =>
      'Puedes renunciar a una herencia dentro de los 3 meses siguientes a conocerla';

  @override
  String get rightInheritanceInfo =>
      'Tienes derecho a obtener información sobre el caudal hereditario de bancos y registros';

  @override
  String get rightInheritanceDispute =>
      'Puedes impugnar un testamento injusto ante los tribunales dentro del plazo de prescripción legal';

  @override
  String get mustFileInheritance =>
      'Debes iniciar el procedimiento sucesorio ante notario en un plazo razonable';

  @override
  String get mustNotifyHeirs =>
      'Todos los herederos conocidos deben ser notificados del procedimiento sucesorio';

  @override
  String get inheritanceActionGatherDocs =>
      'Reúne todos los documentos: certificado de defunción, testamento, registros de propiedad, extractos bancarios';

  @override
  String get inheritanceActionContactNotary =>
      'Contacta con un notario para abrir el procedimiento sucesorio';

  @override
  String get inheritanceActionCheckDebts =>
      'Comprueba si el caudal hereditario tiene deudas antes de aceptar la herencia';

  @override
  String get inheritanceActionFileCourt =>
      'Si se impugna el testamento, presenta una demanda ante los tribunales';

  @override
  String get inheritanceDeadlineRenounce =>
      '3 meses para renunciar a la herencia tras conocerla';

  @override
  String get inheritanceDeadlineDispute =>
      'Plazo de prescripción para impugnar un testamento: varía según la causa';

  @override
  String get inheritanceFactForced =>
      'En Estonia, los descendientes y el cónyuge tienen derecho a una legítima (1/2 de la parte legal) aunque estén excluidos del testamento';

  @override
  String get inheritanceFactNotary =>
      'Todo procedimiento sucesorio en Estonia debe tramitarse ante notario; este paso no puede omitirse';

  @override
  String get consumerProtection => 'Protección al consumidor';

  @override
  String get consumerProtectionDesc =>
      'Fraude, productos defectuosos, devoluciones, vendedores engañosos';

  @override
  String get rightReturnOnline =>
      'Tiene 14 días para cancelar compras en línea sin motivo (derecho de desistimiento de la UE)';

  @override
  String get rightDefectiveProduct =>
      'Si un producto es defectuoso, tiene derecho a la reparación, sustitución o reembolso';

  @override
  String get rightClearPricing =>
      'Los vendedores deben mostrar precios claros que incluyan todas las tarifas: los costes ocultos son ilegales';

  @override
  String get rightComplainBoard =>
      'Puede presentar una reclamación gratuita ante la Junta de Disputas de Consumo';

  @override
  String get rightProtectionFraud =>
      'Está protegido frente a prácticas comerciales desleales y al fraude';

  @override
  String get mustKeepReceipts =>
      'Conserve todos los recibos, contratos y comunicaciones con los vendedores';

  @override
  String get mustActTimely =>
      'Comunique los defectos al vendedor en un plazo razonable tras descubrirlos';

  @override
  String get consumerActionKeepEvidence =>
      'Conserve recibos, capturas de pantalla, correos y todo comprobante de compra';

  @override
  String get consumerActionContactSeller =>
      'Póngase en contacto primero con el vendedor: explique el problema por escrito';

  @override
  String get consumerActionFileComplaint =>
      'Presente una reclamación ante la Junta de Disputas de Consumo (kuluttajariitalautakunta)';

  @override
  String get consumerActionContactAuthority =>
      'Póngase en contacto con los Servicios de Asesoramiento al Consumidor para obtener ayuda gratuita';

  @override
  String get consumerActionReportFraud =>
      'Denuncie el fraude a la policía y al Defensor del Consumidor';

  @override
  String get consumerFactWithdrawal =>
      'Conforme a la Directiva de la UE sobre los derechos de los consumidores 2011/83/UE, tiene 14 días para desistir de cualquier compra en línea o a distancia, sin necesidad de justificación. El vendedor debe reembolsarle en un plazo de 14 días.';

  @override
  String get consumerFactWarranty =>
      'En Finlandia, el vendedor es responsable de los defectos del producto durante un tiempo razonable (a menudo 2 años o más). Esto es independiente de cualquier garantía del fabricante.';

  @override
  String get consumerDeadlineWithdrawal =>
      'Desistimiento de compra en línea: 14 días desde la entrega';

  @override
  String get consumerDeadlineDefect =>
      'Comunicar el defecto al vendedor: en un plazo de 2 meses desde su descubrimiento (recomendado)';

  @override
  String get contactConsumerAdvisory =>
      'Servicios de Asesoramiento al Consumidor';

  @override
  String get contactConsumerOmbudsman =>
      'Defensor del Consumidor (Kuluttaja-asiamies)';

  @override
  String get contactConsumerDisputesBoardDirect =>
      'Junta de Disputas de Consumo';

  @override
  String get caseTypeStepLabel => 'Tipo de caso';

  @override
  String get detailsStepLabel => 'Detalles';

  @override
  String get documentsStepLabel => 'Documentos';

  @override
  String get whatTypeOfCase => '¿Qué tipo de caso es este?';

  @override
  String get selectCategoryDescription =>
      'Seleccione la categoría que mejor describa su situación.';

  @override
  String get tellUsAboutCase => 'Cuéntenos sobre su caso';

  @override
  String get aiHelpsUnderstand =>
      'Esta información ayuda a nuestra IA a comprender mejor su situación.';

  @override
  String get caseTitleHint => 'p. ej., Recurso de permiso de residencia 2026';

  @override
  String get countryJurisdiction => 'País / Jurisdicción';

  @override
  String get selectCountryHint => 'Selecciona un país';

  @override
  String get referenceNumberHint => 'p. ej., UMA/12345/2026';

  @override
  String get descriptionOptional => 'Descripción (opcional)';

  @override
  String get descriptionHint =>
      'Describa brevemente su situación. ¿Qué ocurrió? ¿Qué decisión se tomó?';

  @override
  String get uploadFirstDocument => 'Suba su primer documento';

  @override
  String get uploadDocumentDescription =>
      'Sube la carta de decisión o cualquier documento relevante. Puedes omitir este paso y añadir documentos más tarde.';

  @override
  String get tapToUploadFile => 'Toca para subir un archivo';

  @override
  String get fileSizeLimit => 'PDF, JPG, PNG hasta 25 MB';

  @override
  String get addDocumentsLaterHint =>
      'Siempre puedes añadir documentos más tarde desde la pantalla de detalle del caso.';

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
  String get categoryChildren => 'Menores';

  @override
  String get categoryDigital => 'Digital';

  @override
  String get childrenRights => 'Derechos de los menores y pensión alimenticia';

  @override
  String get childrenRightsDesc =>
      'Manutención de menores, pensión alimenticia, protección, garantías estatales';

  @override
  String get cyberbullying => 'Ciberacoso y acoso en línea';

  @override
  String get cyberbullyingDesc =>
      'Amenazas, violaciones de la privacidad, difamación en línea';

  @override
  String get rightChildSupport =>
      'Ambos progenitores están legalmente obligados a mantener económicamente a su hijo (Perekonnaseadus § 100-102)';

  @override
  String get rightMinimumAlimony =>
      'Pensión alimenticia mínima en Estonia: importe base (295,86 €) + 3 % del salario bruto medio del año anterior (PKS § 101). A partir del 01.04.2026: 318,62 €/mes por hijo. Se actualiza anualmente el 1 de abril. Calculadora: alimendid.ee';

  @override
  String get rightCourtAlimony =>
      'Puede solicitar la pensión alimenticia a través del tribunal de condado (maakohus); no se requiere abogado para reclamaciones de hasta 6400 €';

  @override
  String get rightBailiffEnforcement =>
      'Si el progenitor se niega a pagar, un agente judicial (kohtutäitur) puede ejecutar la resolución judicial, incluido el embargo del salario';

  @override
  String get rightStateAlimonyGuarantee =>
      'Si el progenitor no paga, el Estado proporciona elatisabi (prestación de manutención) a través de Sotsiaalkindlustusamet: hasta 100 €/mes por hijo';

  @override
  String get rightChildEducation =>
      'Todo menor tiene derecho a la educación, la atención sanitaria y la protección frente a los malos tratos (Lastekaitseseadus § 4-5)';

  @override
  String get rightChildContact =>
      'Un menor tiene derecho a mantener contacto con ambos progenitores, salvo que un tribunal decida lo contrario (PKS § 143)';

  @override
  String get mustFileCourtClaim =>
      'Para recibir la pensión alimenticia, debe presentar una demanda judicial o acordar el importe por escrito';

  @override
  String get mustNotifyAddressChange =>
      'Notifique a Sotsiaalkindlustusamet los cambios de domicilio si recibe elatisabi';

  @override
  String get childrenActionGatherDocs =>
      'Reúna el certificado de nacimiento del menor, su documento de identidad y los justificantes de gastos';

  @override
  String get childrenActionFileCourtClaim =>
      'Presente una demanda de pensión alimenticia ante el tribunal de condado (maakohus): puede hacerse en línea a través de e-toimik';

  @override
  String get childrenActionApplyElatisabi =>
      'Solicite la garantía estatal de pensión alimenticia (elatisabi) en Sotsiaalkindlustusamet si el progenitor no paga';

  @override
  String get childrenActionContactBailiff =>
      'Póngase en contacto con un agente judicial (kohtutäitur) para ejecutar la resolución judicial';

  @override
  String get childrenActionCallLasteabi =>
      'Llame a Lasteabi 116 111, la línea de ayuda para menores: gratuita, 24/7';

  @override
  String get childrenDeadlineElatisabi =>
      'Solicitar elatisabi: tras la resolución judicial, sin plazo estricto, pero el proceso lleva tiempo';

  @override
  String get childrenDeadlineCourt =>
      'La pensión alimenticia puede reclamarse con carácter retroactivo hasta 1 año antes de la presentación de la demanda';

  @override
  String get childrenFactMinimum =>
      'A partir del 01.04.2026, la pensión alimenticia mínima es de 318,62 €/mes por hijo. Fórmula: importe base (295,86 €) + 3 % del salario bruto medio del año anterior. Se actualiza anualmente el 1 de abril. Un progenitor no puede acordar pagar menos. Calculadora: alimendid.ee';

  @override
  String get childrenFactElatisabi =>
      'La garantía estatal de pensión alimenticia de Estonia (elatisabi) se introdujo en 2017 para proteger a los menores cuando un progenitor se niega a pagar. El Estado paga y luego recupera el importe del progenitor deudor.';

  @override
  String get rightReportCybercrime =>
      'Tiene derecho a denunciar a la policía las amenazas en línea, el acoso y la usurpación de identidad (Karistusseadustik § 120, § 157¹)';

  @override
  String get rightContentRemoval =>
      'Puede solicitar la retirada de contenido difamatorio o privado de las plataformas y exigir su eliminación conforme al RGPD';

  @override
  String get rightMoralDamageCompensation =>
      'Puede reclamar una indemnización por el daño moral causado por el ciberacoso (Võlaõigusseadus § 1043-1055)';

  @override
  String get rightPrivacyProtection =>
      'Su vida privada está protegida: compartir sin autorización sus fotos, mensajes o datos personales es ilegal (KarS § 157)';

  @override
  String get rightDataProtection =>
      'Denuncie las infracciones de protección de datos (uso no autorizado de sus datos) ante Andmekaitse Inspektsioon';

  @override
  String get rightDefamationAction =>
      'La difamación (laimamine) es un ilícito civil: puede demandar por daños y perjuicios y exigir una rectificación pública (KarS § 247 (derogado), VÕS § 1047)';

  @override
  String get mustCollectEvidence =>
      'Recopile y conserve todas las pruebas: capturas de pantalla, enlaces, fechas e información de los testigos';

  @override
  String get mustNotRetaliate =>
      'No tome represalias ni incurra en contraacoso: podría debilitar su caso';

  @override
  String get cyberActionScreenshots =>
      'Tome capturas de pantalla de todo el acoso: guarde URL, fechas, nombres de usuario y contenido';

  @override
  String get cyberActionReportPolice =>
      'Presente una denuncia policial en la comisaría más cercana o en línea en politsei.ee';

  @override
  String get cyberActionReportPlatform =>
      'Denuncie el contenido a la plataforma de redes sociales para su retirada';

  @override
  String get cyberActionContactDPA =>
      'Póngase en contacto con Andmekaitse Inspektsioon si se utilizaron indebidamente sus datos personales';

  @override
  String get cyberActionConsultLawyer =>
      'Consulte a un abogado sobre los daños civiles: hay asistencia jurídica gratuita disponible a través de Riigi Õigusabi';

  @override
  String get cyberDeadlineCriminal =>
      'Denuncia penal: sin plazo estricto, pero denuncie con prontitud para obtener mejores resultados';

  @override
  String get cyberDeadlineCivil =>
      'Reclamación civil por daños y perjuicios: hasta 3 años desde que tuvo conocimiento de la infracción (TsÜS § 150)';

  @override
  String get cyberFactPrivacy =>
      'En Estonia, compartir sin autorización imágenes íntimas de alguien puede acarrear hasta 3 años de prisión conforme al Karistusseadustik § 157¹ (violación de la privacidad).';

  @override
  String get cyberFactGDPR =>
      'Conforme al RGPD, tiene «derecho al olvido»: las plataformas deben eliminar sus datos personales a petición si no existe una base jurídica para conservarlos.';

  @override
  String get guestUser => 'Invitado';

  @override
  String get howToUse => '¿Cómo se usa?';

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
  String get tutorialStep4Title => '¡Empecemos!';

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
  String get upgradeBannerTitle =>
      'Mejore su plan para tener consultas ilimitadas';

  @override
  String get upgradeBannerCta => 'Mejorar plan';

  @override
  String get paymentSuccessTitle => 'Pago realizado correctamente';

  @override
  String get paymentSuccessBody => 'Su suscripción ya está activa.';

  @override
  String get commonOk => 'Aceptar';

  @override
  String get feedbackThumbsUpLabel => 'Útil';

  @override
  String get feedbackThumbsDownLabel => 'No útil';

  @override
  String get feedbackCommentPrompt => '¿Qué estuvo mal?';

  @override
  String get feedbackSend => 'Enviar';

  @override
  String get feedbackCancel => 'Cancelar';

  @override
  String get reasoningPillIdle => 'Pensando…';

  @override
  String get reasoningPillSearchingLaw => 'Buscando en la legislación estonia…';

  @override
  String get reasoningPillSearchingWeb => 'Buscando en la web…';

  @override
  String get reasoningPillCheckingCompany =>
      'Consultando el registro mercantil…';

  @override
  String get reasoningPillCheckingVehicle =>
      'Consultando el registro de vehículos…';

  @override
  String get reasoningPillReadingDocument => 'Leyendo su documento…';

  @override
  String get reasoningPillDrafting => 'Redactando el documento…';

  @override
  String get reasoningPillPreparingEmail => 'Preparando el correo electrónico…';

  @override
  String get reasoningPillFindingLawyer => 'Buscando abogados…';

  @override
  String get reasoningPillThinking => 'Analizando su caso…';

  @override
  String get reasoningPillFinalising => 'Componiendo su respuesta…';

  @override
  String reasoningCollapsedFormat(int sec, int sources) {
    return 'Razonado durante $sec s · $sources fuentes';
  }

  @override
  String get reasoningExpandHint => 'toque para ver los pasos';

  @override
  String get caseFileTitle => 'Expediente del caso';

  @override
  String get caseFileTimeline => 'Cronología';

  @override
  String get caseFileParties => 'Partes';

  @override
  String get caseFileDeadlines => 'Plazos';

  @override
  String get caseFileExportPdf => 'Descargar el expediente (PDF)';

  @override
  String get caseFileEmpty =>
      'Hable con la IA sobre su caso: su cronología se irá construyendo sola.';

  @override
  String get caseFileDisclaimer =>
      'Este expediente se extrae automáticamente de su conversación. No constituye asesoramiento jurídico.';

  @override
  String get caseFileTabLabel => 'Caso';

  @override
  String get refresh => 'Actualizar';

  @override
  String get demoLimitReached =>
      'Límite de demostración alcanzado. Regístrese gratis para continuar.';

  @override
  String get demoLimitSignUpCta => 'Registrarse';

  @override
  String freeQuotaExhausted(int count) {
    return 'Ha utilizado los $count mensajes gratuitos de este mes.';
  }

  @override
  String get upgradeForUnlimited =>
      'Cambie a Pro para tener mensajes ilimitados';

  @override
  String get upgradeCta => 'Mejorar plan';

  @override
  String get rateLimitTryAgain =>
      'Está enviando demasiado rápido. Vuelva a intentarlo en unos segundos.';

  @override
  String get quickProfilePrompt =>
      'Para poder ayudarle con más precisión, ¿cuál es su situación jurídica?: ¿es ciudadano estonio, ciudadano de la UE de otro país o tiene un permiso de residencia?';

  @override
  String get quickProfileChipEstonianCitizen => 'Ciudadano estonio';

  @override
  String get quickProfileChipEuCitizen => 'Ciudadano de la UE (otro)';

  @override
  String get quickProfileChipResidencePermit => 'Permiso de residencia';

  @override
  String get quickProfileSkipBtn => 'Omitir';

  @override
  String get quickProfileSavedAck =>
      'Entendido. Ahora bien, ¿cuál es su consulta?';

  @override
  String get caseTitleLabel => 'Título del caso';

  @override
  String get jurisdictionLabel => 'Jurisdicción';

  @override
  String get caseTypeLabel => 'Tipo de caso';

  @override
  String get caseLanguageLabel => 'Idioma';

  @override
  String get caseNumbersSection => 'Números de expediente';

  @override
  String get partiesSection => 'Partes';

  @override
  String get authoritiesSection => 'Autoridades';

  @override
  String get timelineSection => 'Cronología';

  @override
  String get openQuestionsSection => 'Cuestiones pendientes';

  @override
  String get nextActionsSection => 'Próximas acciones';

  @override
  String get summarySection => 'Resumen';

  @override
  String get addRow => 'Añadir fila';

  @override
  String get removeRow => 'Eliminar';

  @override
  String get archiveCase => 'Archivar caso';

  @override
  String get closeCase => 'Cerrar caso';

  @override
  String get continueChatAboutCase =>
      'Continuar la conversación sobre este caso';

  @override
  String get linkChatToCase => 'Vincular al caso';

  @override
  String get clearActiveCase => 'Quitar el caso activo';

  @override
  String get caseSavedAck => 'Caso guardado';

  @override
  String get caseArchivedAck => 'Caso archivado';

  @override
  String get intakeStep1Title => '¿Dónde está el caso?';

  @override
  String get intakeStep1Subtitle =>
      'País y autoridad con la que está tratando.';

  @override
  String get intakeJurisdictionLabel => 'País / jurisdicción';

  @override
  String get intakeAuthorityLabel => 'Tipo de autoridad';

  @override
  String get intakeAuthorityNameLabel => 'Nombre de la autoridad (opcional)';

  @override
  String get intakeAuthorityPolice => 'Policía';

  @override
  String get intakeAuthorityCourt => 'Tribunal';

  @override
  String get intakeAuthoritySocial => 'Servicios sociales';

  @override
  String get intakeAuthorityEmployer => 'Empleador';

  @override
  String get intakeAuthorityLandlord => 'Arrendador';

  @override
  String get intakeAuthorityOpposingParty => 'Parte contraria';

  @override
  String get intakeAuthorityOther => 'Otra';

  @override
  String get intakeStep2Title => '¿Qué tipo de caso?';

  @override
  String get intakeStep2Subtitle =>
      'Elija el tipo más cercano: puede precisarlo más adelante.';

  @override
  String get intakeCaseTypeCriminal => 'Penal';

  @override
  String get intakeCaseTypeCivil => 'Civil';

  @override
  String get intakeCaseTypeFamily => 'Familia';

  @override
  String get intakeCaseTypeAdmin => 'Administrativo';

  @override
  String get intakeCaseTypeImmigration => 'Inmigración';

  @override
  String get intakeCaseTypeLabor => 'Laboral';

  @override
  String get intakeCaseTypeConsumer => 'Consumo';

  @override
  String get intakeCaseTypeInheritance => 'Sucesiones';

  @override
  String get intakeCaseTypeOther => 'Otro';

  @override
  String get intakeStep3Title => '¿Quién está implicado?';

  @override
  String get intakeStep3Subtitle => 'Su papel y la otra parte.';

  @override
  String get intakeRoleLabel => 'Su papel';

  @override
  String get intakeRolePlaintiff => 'Demandante';

  @override
  String get intakeRoleDefendant => 'Demandado';

  @override
  String get intakeRoleVictim => 'Víctima';

  @override
  String get intakeRoleAccused => 'Acusado';

  @override
  String get intakeRoleWitness => 'Testigo';

  @override
  String get intakeRoleFamily => 'Familiar';

  @override
  String get intakeRoleOther => 'Otro';

  @override
  String get intakeOpposingSideLabel => 'Parte contraria (opcional)';

  @override
  String get intakeWitnessesLabel => 'Testigos (opcional)';

  @override
  String get intakeAddWitness => 'Añadir testigo';

  @override
  String get intakeWitnessHint => 'Nombre o contacto';

  @override
  String get intakeStep4Title => 'Números y fechas';

  @override
  String get intakeStep4Subtitle => 'Lo que ya tenga. Omita lo que no tenga.';

  @override
  String get intakeCaseNumberLabel => 'Número de expediente (opcional)';

  @override
  String get intakeIncidentDateLabel => 'Fecha del incidente (opcional)';

  @override
  String get intakeIncidentDatePick => 'Elegir fecha';

  @override
  String get intakeDeadlinesLabel => 'Plazos conocidos';

  @override
  String get intakeAddDeadline => 'Añadir plazo';

  @override
  String get intakeDeadlineWhatHint => 'Qué';

  @override
  String get intakeStep5Title => 'Documentos';

  @override
  String get intakeStep5Subtitle => 'Suba todo lo relevante. Lo leeremos.';

  @override
  String get intakeUploadDocsLabel => 'Subir documentos';

  @override
  String get intakeSkipDocs => 'Omitir: los subiré más tarde';

  @override
  String get intakeNextBtn => 'Siguiente';

  @override
  String get intakeBackBtn => 'Atrás';

  @override
  String get intakeFinishBtn => 'Finalizar y abrir el chat';

  @override
  String get intakeUrgentBtn => 'Urgente: preguntar ahora';

  @override
  String get intakeUrgentDialogTitle => '¿Abrir el chat ahora?';

  @override
  String get intakeUrgentDialogBody =>
      'Guardaremos lo que ha introducido como un caso en borrador. Puede completar el asistente desde la página del caso en cualquier momento.';

  @override
  String get intakeUrgentConfirm => 'Abrir el chat';

  @override
  String get intakeUrgentCancel => 'Seguir rellenando';

  @override
  String get intakePreparingCase => 'Preparando su caso…';

  @override
  String get intakeFallbackGreeting =>
      'Veo su caso. Dígame qué es lo más urgente: lo resolveremos juntos.';

  @override
  String get intakeUrgentGreeting =>
      'Veo que es urgente. Haga su consulta: completaré el resto sobre la marcha.';

  @override
  String intakeStepIndicator(int current, int total) {
    return 'Paso $current de $total';
  }

  @override
  String get intakeFieldRequired => 'Obligatorio';

  @override
  String intakeUploadProgress(int done, int total) {
    return 'Subiendo $done / $total…';
  }

  @override
  String get uplDisclaimerFooter =>
      'Advocat no es un bufete de abogados. Esto es información, no asesoramiento jurídico.';

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
  String get deadlineRadarTitle => 'Próximos plazos';

  @override
  String get deadlineRadarEmpty => 'No hay plazos próximos';

  @override
  String get deadlineRadarViewAll => 'Ver todos';

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
  String get deadlineCardTomorrow => 'mañana';

  @override
  String get deadlineCardToday => 'hoy';

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
  String get deadlineCardMarkComplete => 'Marcar como completado';

  @override
  String get deadlineCardSnooze => 'Posponer';

  @override
  String get deadlineCardSnooze3d => 'Posponer 3 días';

  @override
  String get deadlineCardSnooze7d => 'Posponer 7 días';

  @override
  String get deadlineCardSnoozeCustom => 'Elegir una fecha';

  @override
  String get deadlineCardEdit => 'Editar';

  @override
  String get deadlineCardDelete => 'Archivar';

  @override
  String get deadlineCardSourceLabelPdf => 'desde PDF';

  @override
  String get deadlineCardSourceLabelIntake => 'desde el formulario inicial';

  @override
  String get deadlineCardSourceLabelManual => 'añadido manualmente';

  @override
  String get deadlineCardSourceLabelEmail => 'desde correo electrónico';

  @override
  String get deadlineCardSourceLabelHaikuExtract => 'extraído por IA';

  @override
  String get deadlineCardSourceLabelStatutoryTemplate => 'plantilla legal';

  @override
  String deadlineBannerCritical(String title, String when) {
    return 'Plazo crítico $title $when';
  }

  @override
  String get deadlineBannerDismiss => 'Descartar';

  @override
  String get deadlineBannerOpen => 'Abrir plazo';

  @override
  String deadlineHolidayShifted(String original, String reason) {
    return 'Desplazado desde $original debido a $reason';
  }

  @override
  String get deadlinePermissionAskTitle => '¿Activar recordatorios de plazos?';

  @override
  String get deadlinePermissionAskBody =>
      'Te avisaremos 7, 3 y 1 día antes de cada plazo legal, además de la mañana del vencimiento. Nunca se usa con fines de marketing.';

  @override
  String get deadlinePermissionAllow => 'Permitir';

  @override
  String get deadlinePermissionLater => 'Más tarde';

  @override
  String get deadlineSettingsSection => 'Recordatorios de plazos';

  @override
  String get deadlineSettingsPushChannel => 'Notificaciones push';

  @override
  String get deadlineSettingsEmailChannel =>
      'Correo electrónico (solo críticos)';

  @override
  String get deadlineSettingsInAppChannel => 'Avisos dentro de la app';

  @override
  String get deadlineSettingsCriticalBypass =>
      'Los recordatorios críticos ignoran las horas de silencio';

  @override
  String get deadlineSettingsQuietHours => 'Horas de silencio';

  @override
  String deadlineSettingsQuietHoursBadge(String start, String end) {
    return 'Silencio $start–$end';
  }

  @override
  String get deadlineCaseScreenTitle => 'Plazos del caso';

  @override
  String get deadlineAddManualCta => 'Añadir plazo';

  @override
  String get deadlineFormTitle => 'Título';

  @override
  String get deadlineFormDescription => 'Descripción (opcional)';

  @override
  String get deadlineFormStatuteTemplate => 'Plantilla legal';

  @override
  String get deadlineFormStatuteTemplateNone => 'Ninguna (manual)';

  @override
  String get deadlineFormDeadlineAt => 'Fecha límite';

  @override
  String get deadlineFormPriority => 'Prioridad';

  @override
  String get deadlineFormSave => 'Guardar';

  @override
  String get deadlineFormCancel => 'Cancelar';

  @override
  String get deadlineCompletedNotePrompt => 'Añadir una nota (opcional)';

  @override
  String get deadlineCompletedNoteSave => 'Guardar';

  @override
  String get inboxTitle => 'Bandeja de entrada';

  @override
  String get inboxEmptyTitle => 'Nada pendiente';

  @override
  String get inboxEmptyBody =>
      'Los nuevos hilos de correo aparecerán aquí a medida que se clasifiquen.';

  @override
  String get inboxApproveSend => 'Aprobar y enviar';

  @override
  String get inboxEditDraft => 'Editar';

  @override
  String get inboxSnooze => 'Posponer';

  @override
  String get inboxArchive => 'Archivar';

  @override
  String get inboxFilterAll => 'Todos';

  @override
  String get inboxConfirmSendTitle => '¿Enviar la respuesta preparada?';

  @override
  String get inboxConfirmSendBody =>
      'Advocat enviará la respuesta preparada por la IA a través de su Gmail conectado. Aún puede revisar el contenido en la siguiente pantalla.';

  @override
  String get inboxSendButton => 'Enviar';

  @override
  String get inboxSentToast => 'Enviado.';

  @override
  String get inboxAlreadySentToast => 'Ya se ha enviado.';

  @override
  String get inboxSendErrorToast =>
      'No se pudo enviar la respuesta. Toca para reintentar.';

  @override
  String get inboxSnoozedToast => 'Pospuesto 24 h.';

  @override
  String get inboxArchivedToast => 'Archivado.';

  @override
  String get inboxDraftLoadError => 'No se pudo cargar el borrador.';

  @override
  String get inboxDeadlineToday => 'hoy';

  @override
  String get inboxDeadlineTomorrow => 'mañana';

  @override
  String inboxDeadlineInDays(int days) {
    return 'en $days d';
  }

  @override
  String inboxDeadlineOverdue(int days) {
    return 'vencido hace $days d';
  }

  @override
  String parallelActionsHeadline(int count) {
    return 'El consilium recomienda $count acciones paralelas';
  }

  @override
  String get parallelActionsApproveAll => 'Aprobar todo y enviar';

  @override
  String parallelActionsApproveSelected(int count, int total) {
    return 'Aprobar $count de $total';
  }

  @override
  String parallelActionsConfirmTitle(int count) {
    return '¿Enviar $count correos electrónicos?';
  }

  @override
  String parallelActionsConfirmBody(int count) {
    return 'Advocat enviará $count respuestas preparadas a través de su Gmail conectado. Cada una se envía de forma independiente: si una falla, las demás se envían igualmente.';
  }

  @override
  String parallelActionsSentToast(int count) {
    return '$count enviados.';
  }

  @override
  String parallelActionsPartialFailureToast(int sent, int failed) {
    return '$sent enviados, $failed fallidos.';
  }

  @override
  String get parallelActionsKindReply => 'respuesta';

  @override
  String get parallelActionsKindNew => 'nuevo';

  @override
  String get parallelActionsCheckboxSelected => 'Acción seleccionada';

  @override
  String get parallelActionsCheckboxUnselected => 'Acción no seleccionada';

  @override
  String parallelActionsCitationCount(int count) {
    return '$count cit.';
  }

  @override
  String parallelActionsRetryFailed(int count) {
    return 'Reintentar fallidos ($count)';
  }

  @override
  String get agentApprovalNeedsReviewTitle => 'Advocat necesita su aprobación';

  @override
  String get agentApprovalResolvedTitle => 'Acción resuelta';

  @override
  String get agentApprovalStepsLabel => 'pasos';

  @override
  String get agentApprovalApproveButton => 'Aprobar y enviar';

  @override
  String get agentApprovalDeclineButton => 'Rechazar';

  @override
  String get agentApprovalAttachmentsLabel => 'Archivos adjuntos';

  @override
  String get agentApprovalSentSummary => 'Enviado en su nombre.';

  @override
  String get agentApprovalDeclinedSummary => 'Rechazado: no se envió nada.';

  @override
  String get agentToolDraftEmailAtt => 'Enviar correo con archivos adjuntos';

  @override
  String get agentToolSendEmail => 'Enviar correo electrónico';

  @override
  String get agentToolGeneratePdf => 'Generar PDF';

  @override
  String get agentToolApproveSend => 'Enviar respuesta preparada';

  @override
  String get inboxErrorTitle => 'No se pudo cargar la bandeja de entrada';

  @override
  String get inboxEditDiscardTitle =>
      '¿Descartar las modificaciones sin guardar?';

  @override
  String get inboxEditDiscardBody =>
      'Tiene cambios sin guardar en este borrador. Si vuelve atrás, se descartarán.';

  @override
  String get inboxEditKeepEditing => 'Seguir editando';

  @override
  String get inboxEditDiscard => 'Descartar';

  @override
  String get workspaceTabOverview => 'Resumen';

  @override
  String get workspaceTabChat => 'Chat';

  @override
  String get workspaceTabDrafts => 'Borradores';

  @override
  String get workspaceOverviewEmpty =>
      'Añade documentos para generar un resumen.';

  @override
  String get workspaceTimelineEmpty => 'Aún no hay eventos.';

  @override
  String get workspaceDocumentsEmpty =>
      'No hay documentos. Sube uno desde Escanear.';

  @override
  String get workspaceDraftsEmpty => 'Aún no hay borradores.';

  @override
  String get workspaceInboxEmpty => 'No hay correos relacionados.';

  @override
  String get plannerSettingsTitle => 'Razonamiento jurídico en tres fases';

  @override
  String get plannerSettingsSubtitle =>
      'Planificar → responder → criticar. Más lento, pero más exhaustivo.';

  @override
  String get plannerSettingsProBadge => 'Pro';

  @override
  String get plannerSettingsProDescription => 'Disponible en el plan Pro';

  @override
  String get plannerTrailHeaderPlan => 'Plan';

  @override
  String get plannerTrailHeaderCritique => 'Crítica';

  @override
  String get plannerTrailSubQuestions => 'Subpreguntas';

  @override
  String get plannerTrailCounterArgs => 'Contraargumentos';

  @override
  String get plannerTrailEvidenceGaps => 'Lagunas probatorias';

  @override
  String get plannerTrailMaterialGapTrue => 'Laguna material detectada';

  @override
  String get plannerTrailRegeneratedBadge => 'Regenerado una vez';

  @override
  String get plannerTrailEmpty => 'ningún elemento';

  @override
  String get supportTitle => 'Ayuda';

  @override
  String get supportSubtitle => 'Normalmente respondemos en 1-2 horas.';

  @override
  String get supportSearchPlaceholder => 'Buscar en la ayuda…';

  @override
  String get supportStatusAllOk =>
      'Todos los sistemas funcionan con normalidad';

  @override
  String get supportFaqWhatIs => '¿Qué es Advocat?';

  @override
  String get supportFaqHowSubscribe => '¿Cómo me suscribo a Pro?';

  @override
  String get supportFaqExportData => '¿Puedo exportar mis datos?';

  @override
  String get supportFaqCancelAccount => 'Cancelar o eliminar la cuenta';

  @override
  String get supportFaqTalkHuman => 'Hablar con una persona';

  @override
  String get supportContactEmail => 'Correo electrónico';

  @override
  String get supportContactTelegram => 'Telegram';

  @override
  String get supportContactWhatsapp => 'WhatsApp';

  @override
  String get supportFooterSla => 'Respondemos en un plazo de 24 h';

  @override
  String get supportWhatsapp => 'WhatsApp';

  @override
  String get supportEmail => 'Correo electrónico';

  @override
  String get supportInApp => 'Escríbanos aquí';

  @override
  String get supportCategoryLabel => 'Categoría';

  @override
  String get supportCategoryBug => 'Error';

  @override
  String get supportCategoryPayment => 'Problema de pago';

  @override
  String get supportCategoryQuestion => 'Pregunta';

  @override
  String get supportCategoryFeature => 'Solicitud de función';

  @override
  String get supportCategoryOther => 'Otro';

  @override
  String get supportMessagePlaceholder => 'Describa su problema...';

  @override
  String get supportEmailLabel => 'Correo electrónico (opcional)';

  @override
  String get supportSend => 'Enviar';

  @override
  String get supportSentSuccess => '¡Mensaje enviado! Le responderemos pronto.';

  @override
  String get supportError => 'Algo salió mal. Vuelva a intentarlo.';

  @override
  String get supportErrorTooShort => 'Escriba al menos 10 caracteres.';

  @override
  String get supportErrorTooLong => 'Máximo 2000 caracteres.';

  @override
  String get supportPrivacyNotice => 'Su mensaje se almacena de forma segura.';

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
      'Ha usado su revisión de contrato gratuita. Actualice para revisiones mensuales.';

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
  String get referralYourLink => 'SU ENLACE';

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
      'Pruebe Advocat — su asistente legal con IA';

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
  String get referralAntiFraud => 'Máximo 12 recomendaciones con éxito al año.';

  @override
  String get referralEmpty =>
      'Aún no hay recomendaciones. Envíe su enlace para empezar a ganar.';

  @override
  String get referralRecentActivity => 'Actividad reciente';

  @override
  String referralActivityInvited(String when) {
    return 'Invitado $when';
  }

  @override
  String referralActivityActivated(String when) {
    return 'activado $when';
  }

  @override
  String get referralActivityPending => 'aún no activado';

  @override
  String referralStatsInvitedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count amigos',
      one: '1 amigo',
      zero: 'ningún amigo todavía',
    );
    return 'Ha invitado a $_temp0';
  }

  @override
  String referralStatsConvertedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count han activado',
      one: '1 ha activado',
      zero: 'ninguno activado todavía',
    );
    return '$_temp0';
  }

  @override
  String referralStatsEarnedCount(int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months meses gratis',
      one: '1 mes gratis',
      zero: 'nada todavía',
    );
    return 'Su bonificación: $_temp0';
  }

  @override
  String get referralNudgeMessage =>
      '¿Le gusta Advocat? Invite a un amigo: ambos obtienen un mes gratis.';

  @override
  String get referralNudgeAction => 'Invitar';

  @override
  String get referralLandingTitle => 'Le han invitado a Advocat';

  @override
  String referralLandingSubtitle(String inviterName) {
    return '$inviterName le ha invitado: reclame su primer mes gratis.';
  }

  @override
  String get referralLandingSubtitleGeneric =>
      'Reclame su primer mes gratis de Advocat Pro.';

  @override
  String get referralLandingCta => 'Activar el mes gratis y registrarse';

  @override
  String get referralLandingCtaSecondary => 'O conozca más sobre Advocat';

  @override
  String get referralLandingFallback =>
      'Este enlace ha caducado, pero aún puede probar Advocat gratis.';

  @override
  String get referralLandingBenefits =>
      '17 idiomas • Legislación real estonia, finlandesa y de la UE • 24/7, sin esperas';

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
  String get sensitiveConsentTitle => 'Consentimiento de datos sensibles';

  @override
  String get sensitiveConsentBody =>
      'Los documentos que está a punto de subir pueden contener datos personales de categorías especiales conforme al art. 9 del RGPD, como historiales médicos, antecedentes penales, datos biométricos o información sobre su origen racial, su religión o su orientación sexual.\n\nTratamos estos datos únicamente para proporcionarle asistencia jurídica con IA, los almacenamos cifrados en su cuenta privada y nunca los usamos para entrenar modelos. Puede retirar su consentimiento y eliminar los datos en cualquier momento desde Ajustes.\n\nAl aceptar, otorga su consentimiento explícito conforme al art. 9(2)(a) del RGPD para tratar datos de categorías especiales con este fin.';

  @override
  String get sensitiveConsentExplicitCheckbox =>
      'Otorgo mi consentimiento explícito para tratar datos de categorías especiales (art. 9(2)(a) del RGPD).';

  @override
  String get sensitiveConsentRightToShareCheckbox =>
      'Confirmo que tengo derecho a compartir estos datos (los datos son míos, o tengo una base informada/lícita para compartir datos de terceros).';

  @override
  String get sensitiveConsentViewCategories =>
      'Ver qué se considera sensible →';

  @override
  String get sensitiveConsentWithdrawAction =>
      'Retirar el consentimiento de datos sensibles';

  @override
  String get privacyAndData => 'PRIVACIDAD Y DATOS';

  @override
  String get exportMyDataSubtitle =>
      'Descargue una copia de todos sus datos personales (art. 15 del RGPD).';

  @override
  String get withdrawSensitiveConsent => 'Consentimiento de datos sensibles';

  @override
  String get withdrawSensitiveConsentSubtitle =>
      'Gestione o retire el consentimiento para tratar datos de categorías especiales (art. 9(2)(a) del RGPD).';

  @override
  String get dataProcessingAgreement => 'Acuerdo de tratamiento de datos';

  @override
  String get exportingData => 'Exportando sus datos…';

  @override
  String get exportComplete =>
      'Exportación de datos lista: guardada en su dispositivo.';

  @override
  String get exportFailed =>
      'La exportación falló. Vuelva a intentarlo o póngase en contacto con el soporte.';

  @override
  String get quotaExhaustedTitle => 'Límite de mensajes gratuitos alcanzado';

  @override
  String quotaExhaustedBody(int count) {
    return 'Ha utilizado los $count mensajes gratuitos. Cambie a Advocat Counsel por 19,99 €/mes y obtenga consultas jurídicas con IA ilimitadas.';
  }

  @override
  String get quotaExhaustedLater => 'Más tarde';

  @override
  String get quotaExhaustedUpgrade => 'Advocat Counsel: 19,99 €/mes';

  @override
  String quotaCtaMessage(int count) {
    return 'Ha utilizado los $count mensajes gratuitos. Cambie a Advocat Counsel por 19,99 €/mes.';
  }

  @override
  String get quotaCtaButton => 'Obtener Advocat Counsel: 19,99 €/mes';

  @override
  String get aiErrorQuota =>
      'Límite de mensajes gratuitos alcanzado. Suscríbase para seguir usando la IA.';

  @override
  String get aiErrorAuth =>
      'Es necesario iniciar sesión para usar la IA. Regístrese o inicie sesión.';

  @override
  String get aiErrorGeneric =>
      'Error temporal de la IA. Vuelva a intentarlo en un minuto. Si persiste, póngase en contacto con el soporte.';

  @override
  String get tooltipShareCase => 'Compartir el resumen del caso';

  @override
  String get tooltipMuteVoice => 'Silenciar la voz';

  @override
  String get tooltipUnmuteVoice => 'Activar la voz';

  @override
  String get tooltipAttachDoc => 'Adjuntar documento';

  @override
  String get aiTypingHint => 'IA…';

  @override
  String get error404Title => 'Página no encontrada';

  @override
  String error404Body(String path) {
    return 'No pudimos encontrar: $path';
  }

  @override
  String get goToHome => 'Ir al inicio';

  @override
  String get emailAlreadyRegistered =>
      'Este correo electrónico ya está registrado. ¿Desea iniciar sesión?';

  @override
  String get actionSignIn => 'Iniciar sesión';

  @override
  String get actionUndo => 'Deshacer';

  @override
  String get intakeUrgentOpened => 'Chat abierto: su borrador está guardado.';

  @override
  String get panicCoachmark =>
      'Mantenga pulsado para obtener ayuda de emergencia.';

  @override
  String get panicTitle => '¿Qué necesita ahora mismo?';

  @override
  String get panicCardReadAloud => 'Leer en voz alta al agente';

  @override
  String get panicCardRecord => 'Grabar esta conversación';

  @override
  String get panicCardCall => 'Llamar a un abogado';

  @override
  String get panicCardAi => 'Hablar con Advocat ahora';

  @override
  String get panicClose => 'Cerrar';

  @override
  String get panicBadgeV2 => 'V2';

  @override
  String get panicRecordV1Title => 'Disponible en la V2';

  @override
  String get panicRecordV1Body =>
      'La función de grabación está en proceso de validación jurídica para Estonia y estará disponible en la V2. Por ahora, use la grabadora de voz integrada de su teléfono.';

  @override
  String get panicCallFallbackBody =>
      'Escriba a kiire@advocat.ee con una breve descripción y le devolveremos la llamada.';

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
      'Creamos un «Caso sin título» para hacer seguimiento de esto. Toque para cambiar el nombre.';

  @override
  String get softCaseShellBannerCta => 'Cambiar nombre';

  @override
  String get draftsTab => 'Borradores';

  @override
  String get draftingTitle => 'Estudio de redacción';

  @override
  String get draftingEmpty => 'Borrador vacío';

  @override
  String get draftingPlaceholder => 'Empiece a escribir su borrador…';

  @override
  String get draftingDraftsList => 'Mis borradores';

  @override
  String get draftingSave => 'Guardar';

  @override
  String get draftingSaved => 'Guardado';

  @override
  String get draftingSavedJustNow => 'Guardado hace un momento';

  @override
  String get draftingAiRevise => 'Revisar con IA';

  @override
  String get draftingExportPdf => 'Exportar PDF';

  @override
  String get draftingExportDocx => 'Exportar DOCX';

  @override
  String get draftingExportMd => 'Exportar Markdown';

  @override
  String get draftingDeleteDraft => 'Eliminar borrador';

  @override
  String get draftingConfirmDelete => '¿Eliminar este borrador?';

  @override
  String get draftingConfirmDeleteMessage =>
      'Esta acción no se puede deshacer.';

  @override
  String get draftingConfirm => 'Eliminar';

  @override
  String get draftingCancel => 'Cancelar';

  @override
  String draftingDraftReplyTo(String name) {
    return 'Responder a $name';
  }

  @override
  String get draftingUntitled => 'Sin título';

  @override
  String get draftingTitleHint => 'Título (opcional)';

  @override
  String get draftingAiReviseTitle => 'Revisar con IA';

  @override
  String get draftingAiReviseSelectionLabel => 'Texto seleccionado:';

  @override
  String get draftingAiReviseInstructionLabel => 'Instrucción (opcional)';

  @override
  String get draftingAiReviseInstructionHint =>
      'p. ej. «hazlo más formal» o «acórtalo»';

  @override
  String get draftingAiReviseRunButton => 'Generar revisión';

  @override
  String get draftingAiReviseSuggestionLabel => 'Revisión sugerida:';

  @override
  String get draftingAiReviseChangesLabel => 'Cambios:';

  @override
  String get draftingAiReviseAccept => 'Aceptar';

  @override
  String get draftingAiReviseReject => 'Rechazar';

  @override
  String get draftingFormatBold => 'Negrita';

  @override
  String get draftingFormatItalic => 'Cursiva';

  @override
  String get draftingFormatHeading => 'Encabezado';

  @override
  String get draftingFormatBullet => 'Lista con viñetas';

  @override
  String get draftingFormatNumbered => 'Lista numerada';

  @override
  String get draftingEmptyListMessage => 'Aún no tienes borradores.';

  @override
  String get draftingEmptyListAction => 'Nuevo borrador';

  @override
  String get draftingExporting => 'Exportando…';

  @override
  String get draftingExportFailed => 'Error al exportar';

  @override
  String get draftingSaveFailed => 'Error al guardar';

  @override
  String get draftingNewDraft => 'Nuevo borrador';

  @override
  String get vaultNoteChip => 'Nota de la Bóveda';

  @override
  String get saveToVault => 'Guardar en la Bóveda';

  @override
  String get savingToVault => 'Guardando en la Bóveda…';

  @override
  String get savedToVault => 'Guardado en la Bóveda';

  @override
  String get vaultNoteTitlePrefix => 'Nota: ';

  @override
  String get openInVault => 'Abrir en la Bóveda';

  @override
  String get saveToVaultFailed => 'Error al guardar en la Bóveda';

  @override
  String get pdfWorkerUnavailable =>
      'La exportación a PDF no está disponible temporalmente. Prueba con DOCX o Markdown.';

  @override
  String get draftingVersionHistory => 'Historial de versiones';

  @override
  String get emptyHomeTitle => 'Bienvenido a Advocat';

  @override
  String get emptyHomeBody =>
      'Elige un punto de partida: nosotros nos encargamos del trabajo legal pesado.';

  @override
  String get intentChip1 => 'Recibí una multa';

  @override
  String get intentChip2 => 'Permiso denegado';

  @override
  String get intentChip3 => 'Problema con un contrato';

  @override
  String get emptyCasesTitle => 'Aún no hay casos';

  @override
  String get emptyCasesCta => 'Iniciar un caso';

  @override
  String get emptyDraftsTitle => 'Aún no hay borradores';

  @override
  String get emptyDraftsCta => 'Crear borrador';

  @override
  String get emptyChatTitle => 'Pregúntale lo que quieras a Advocat';

  @override
  String get chatExamplePrompt1 => 'Ayúdame a responder a una multa';

  @override
  String get chatExamplePrompt2 => 'Revisa mi contrato de alquiler';

  @override
  String get chatExamplePrompt3 => '¿Cuáles son mis derechos en el trabajo?';

  @override
  String get dangerZone => 'Zona de riesgo';

  @override
  String get deleteAccountConfirmButton => 'Eliminar definitivamente';

  @override
  String deleteAccountConfirmHint(String email) {
    return 'Escriba $email para confirmar';
  }

  @override
  String get deleteAccountSuccess =>
      'Cuenta eliminada. Lamentamos que se marche.';

  @override
  String get deleteAccountWarning =>
      'Esto elimina permanentemente su cuenta, todos los casos, borradores, documentos de la caja fuerte y el historial de chat. Esta acción no se puede deshacer.';

  @override
  String get deletingAccount => 'Eliminando cuenta…';

  @override
  String get contractReviewTitle => 'Revisión de contratos';

  @override
  String get contractReviewUploadCta => 'Subir contrato';

  @override
  String get contractReviewQuotaRemaining =>
      'Sube un contrato en PDF, DOC, DOCX o TXT para una revisión con IA con señales de alerta y consejos de negociación.';

  @override
  String get contractReviewRedFlags => 'Señales de alerta';

  @override
  String get contractReviewReviewPoints => 'Puntos a revisar';

  @override
  String get contractReviewNegotiationTips => 'Consejos de negociación';

  @override
  String get contractReviewSaveToVault => 'Guardar en la Bóveda';

  @override
  String get contractReviewContinueChat => 'Continuar en el chat';

  @override
  String get referralInviteFriends => 'Invitar amigos';

  @override
  String get referralYourCode => 'Su código';

  @override
  String get referralCopiedToast => 'Código copiado al portapapeles';

  @override
  String get referralReward =>
      'Obtén 1 mes gratis de Counsel por cada amigo que se suscriba.';

  @override
  String get referralInvited => 'Amigos invitados';

  @override
  String get referralRewardsEarned => 'Meses gratis obtenidos';

  @override
  String get deadlineUrgencyToday => 'Hoy y vencidos';

  @override
  String get deadlineUrgencyWeek => 'Esta semana';

  @override
  String get deadlineUrgencyMonth => 'Este mes';

  @override
  String get deadlineUrgencyLater => 'Más adelante';

  @override
  String get deadlineAddManual => 'Añadir plazo';

  @override
  String get deadlineSnoozeBy => 'Posponer';

  @override
  String get deadlineSnooze1d => 'Posponer 1 día';

  @override
  String get deadlineSnooze3d => 'Posponer 3 días';

  @override
  String get deadlineSnooze7d => 'Posponer 7 días';

  @override
  String get deadlineDismiss => 'Descartar';

  @override
  String get deadlineExportIcs => 'Añadir al calendario';

  @override
  String get deadlineSource => 'Fuente';

  @override
  String get deadlineEmpty =>
      'Aún no hay plazos. Los plazos se crean automáticamente a partir de sus correos y documentos, o añada uno manualmente con el botón +.';

  @override
  String get deadlineNewTitle => 'Nuevo plazo';

  @override
  String get deadlineFieldTitle => 'Título';

  @override
  String get deadlineFieldDueDate => 'Fecha límite';

  @override
  String get deadlineFieldNotes => 'Notas (opcional)';

  @override
  String get deadlineSaved => 'Plazo guardado';

  @override
  String get deadlineSaveFailed => 'No se pudo guardar el plazo';

  @override
  String get deadlineUrgentBannerSingle => '1 plazo hoy o vencido';

  @override
  String deadlineUrgentBannerMany(int count) {
    return '$count plazos hoy o vencidos';
  }

  @override
  String deadlineDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'quedan $count días',
      one: 'queda 1 día',
      zero: 'hoy',
    );
    return '$_temp0';
  }

  @override
  String deadlineDaysOverdue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vencido hace $count días',
      one: 'vencido hace 1 día',
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
  String get iapRestoreSuccess => 'Su suscripción ha sido restaurada.';

  @override
  String get iapRestoreNoActive =>
      'No se encontró ninguna suscripción activa para restaurar.';

  @override
  String get deadlineEuRadarTitle => 'Radar de plazos de la UE (vista previa)';

  @override
  String get deadlineEuRadarSubtitle =>
      'Plazos procesales hipotéticos de la UE — datos ficticios';

  @override
  String get changePassword => 'Cambiar contraseña';

  @override
  String get changePasswordSubtitle => 'Actualice la contraseña de su cuenta';

  @override
  String get newPasswordTitle => 'Establecer una nueva contraseña';

  @override
  String get newPasswordHint =>
      'Introduzca y confirme una nueva contraseña para su cuenta.';

  @override
  String get newPasswordSave => 'Guardar nueva contraseña';

  @override
  String get newPasswordSuccess =>
      'Contraseña actualizada. Ya puedes usarla para iniciar sesión.';

  @override
  String get newPasswordError =>
      'No se pudo actualizar la contraseña. Inténtalo de nuevo.';

  @override
  String get accessLogTile => 'Registro de accesos';

  @override
  String get accessLogTileSubtitle =>
      'Vea quién accedió a sus datos y para qué';

  @override
  String get accessLogTitle => 'Registro de accesos a mis datos';

  @override
  String get accessLogIntro =>
      'Un registro transparente e inalterable de cada vez que sus datos fueron consultados o procesados, incluso por nuestra IA. Puede verificar que no ha sido modificado.';

  @override
  String get accessLogEmpty => 'Aún no hay eventos de acceso.';

  @override
  String get accessLogError =>
      'No se pudo cargar su registro de accesos. Deslice hacia abajo para reintentar.';

  @override
  String get accessLogIntegrityOk =>
      'Integridad verificada: los enlaces del registro forman una cadena ininterrumpida.';

  @override
  String get accessLogIntegrityBroken =>
      'Advertencia: la cadena del registro está rota. Es posible que se hayan eliminado o reordenado algunas entradas. Póngase en contacto con soporte.';

  @override
  String get accessActionLlmEgress =>
      'Enviado a la IA para su procesamiento (seudonimizado)';

  @override
  String get accessActionAiAnalysis => 'Analizado por la IA';

  @override
  String get accessActionDocumentParse => 'Documento procesado';

  @override
  String get accessActionStaffRead => 'Revisado por un miembro del personal';

  @override
  String get accessActionExport => 'Datos exportados';

  @override
  String get accessActionEmailTriage => 'Correo electrónico clasificado';

  @override
  String get accessActionDeadlineScan => 'Plazos analizados';

  @override
  String get breachAlertTitle => 'Alerta de seguridad sobre sus datos';

  @override
  String get breachAlertBody =>
      'Nuestra supervisión automática detectó un acceso inusual relacionado con sus datos. Lo estamos revisando y le notificaremos cualquier incidente confirmado conforme exige la ley (art. 34 del RGPD).';

  @override
  String get caseDossierTitle => 'Exportar expediente del caso';

  @override
  String get caseDossierSubtitle =>
      'Un único PDF con todo —hechos, cronología, plazos y documentos— para entregar a un asesor jurídico, un tribunal o un órgano de reclamación.';

  @override
  String get caseDossierTileTitle => 'Exportar expediente (PDF)';

  @override
  String get caseDossierTileSubtitle =>
      'Entregue todo el caso a un asesor jurídico o tribunal en un solo archivo';

  @override
  String get caseDossierSectionsHeading => 'Incluir en el expediente';

  @override
  String get caseDossierSectionFacts => 'Hechos del caso';

  @override
  String get caseDossierSectionFactsHint => 'Siempre incluido';

  @override
  String get caseDossierSectionTimeline => 'Cronología';

  @override
  String get caseDossierSectionDeadlines => 'Plazos';

  @override
  String get caseDossierSectionDocuments => 'Documentos';

  @override
  String get caseDossierSectionAiSummary => 'Resumen de la IA';

  @override
  String get caseDossierExportButton => 'Exportar PDF';

  @override
  String get caseDossierExporting => 'Generando su expediente…';

  @override
  String get caseDossierSuccess =>
      'Expediente listo. Abra o comparta el archivo.';

  @override
  String get caseDossierOpen => 'Abrir expediente';

  @override
  String get caseDossierError =>
      'No se pudo generar el expediente. Inténtelo de nuevo.';

  @override
  String get caseDossierErrorNotOwned => 'No se ha encontrado este caso.';

  @override
  String get caseDossierDisclaimer =>
      'El expediente reproduce los datos de su caso tal como están registrados. Revíselo antes de compartirlo.';

  @override
  String get followupsTitle => 'Próximos pasos';

  @override
  String get followupsSubtitle => 'Tareas prácticas para hacer avanzar su caso';

  @override
  String get followupsEmpty => 'Aún no hay pasos de seguimiento.';

  @override
  String get followupsEmptyDesc =>
      'Añada un paso o deje que la IA sugiera qué hacer a continuación.';

  @override
  String get followupsAdd => 'Añadir paso';

  @override
  String get followupsSuggest => 'Sugerir pasos';

  @override
  String get followupsSuggestNone =>
      'No hay sugerencias por ahora. Inténtelo después de conversar sobre el caso.';

  @override
  String get followupsSuggestTitle => 'Próximos pasos sugeridos';

  @override
  String get followupsAddPrompt => 'Añada los pasos que desea conservar:';

  @override
  String get followupsNewTitleHint => '¿Qué hay que hacer?';

  @override
  String get followupsNewDetailHint => 'Nota opcional (por qué / qué adjuntar)';

  @override
  String get followupsDueOptional => 'Recordarme el (opcional)';

  @override
  String get followupsOverdue => 'Vencido';

  @override
  String followupsDueOn(String date) {
    return 'Vence el $date';
  }

  @override
  String get followupsDone => 'Hecho';

  @override
  String get followupsSnooze => 'Posponer';

  @override
  String get followupsSnooze1Week => 'Recordar en una semana';

  @override
  String get followupsDismiss => 'Descartar';

  @override
  String get followupsLoadError => 'No se pudieron cargar los próximos pasos';

  @override
  String get followupsAiBadge => 'IA';

  @override
  String get contractCompareTitle => 'Comparar versiones';

  @override
  String get contractCompareIntro =>
      'Suba dos versiones del mismo contrato. Resaltamos qué cambió y si cada cambio le beneficia o le perjudica.';

  @override
  String get contractCompareOldVersion => 'Versión anterior (v1)';

  @override
  String get contractCompareNewVersion => 'Versión nueva (v2)';

  @override
  String get contractCompareCta => 'Comparar versiones';

  @override
  String get contractCompareAdverse => 'Desfavorable';

  @override
  String get contractCompareFavorable => 'Favorable';

  @override
  String get contractCompareNeutral => 'Neutro';

  @override
  String get contractCompareBefore => 'Antes';

  @override
  String get contractCompareAfter => 'Después';

  @override
  String get contractCompareTruncated =>
      'Contrato extenso: solo se comparó la primera parte de cada versión.';

  @override
  String get contractCompareNoChanges =>
      'No se detectaron cambios sustanciales entre las dos versiones.';

  @override
  String get docSearchTitle => 'Buscar en mis documentos';

  @override
  String get docSearchHint => 'p. ej., dónde se mencionó la fianza';

  @override
  String get docSearchSubtitle =>
      'Búsqueda semántica en su caja fuerte y archivos del caso';

  @override
  String get docSearchIdle =>
      'Busque en el contenido de sus propios documentos, no solo en los títulos.';

  @override
  String get docSearchNoResults =>
      'No se encontraron coincidencias en sus documentos.';

  @override
  String get docSearchError => 'La búsqueda falló. Inténtelo de nuevo.';

  @override
  String get docSearchUntitled => 'Documento sin título';

  @override
  String get docSearchKindCase => 'Documento del caso';

  @override
  String get docSearchKindVault => 'Documento de la caja fuerte';

  @override
  String get docSearchMenuTitle => 'Buscar en mis documentos';

  @override
  String get docSearchMenuSubtitle =>
      'Encuentre cualquier cosa en sus propios archivos por su significado';

  @override
  String get legalTemplatesTitle => 'Biblioteca de plantillas';

  @override
  String get legalTemplatesMenuLabel => 'Plantillas';

  @override
  String get legalTemplatesSubtitle =>
      'Elija un formulario predefinido, complete unos pocos datos y crearemos un borrador que podrá editar y exportar.';

  @override
  String get legalTemplatesDisclaimer =>
      'Estos son formularios de muestra generales, no asesoramiento jurídico individual. Revíselos y adáptelos antes de enviarlos.';

  @override
  String get legalTemplatesSampleBadge => 'Muestra';

  @override
  String get legalTemplatesEmpty => 'Aún no hay plantillas para este filtro.';

  @override
  String get legalTemplatesError =>
      'No se pudieron cargar las plantillas. Inténtelo de nuevo.';

  @override
  String get legalTemplatesFilterAll => 'Todas';

  @override
  String get legalTemplatesJurisdictionFi => 'Finlandia';

  @override
  String get legalTemplatesJurisdictionEe => 'Estonia';

  @override
  String get legalTemplatesCategoryComplaint => 'Reclamaciones';

  @override
  String get legalTemplatesCategoryAppeal => 'Recursos';

  @override
  String get legalTemplatesCategoryApplication => 'Solicitudes';

  @override
  String get legalTemplatesCategoryClaim => 'Demandas';

  @override
  String get legalTemplatesCategoryRequest => 'Peticiones';

  @override
  String get legalTemplatesFillTitle => 'Complete los datos';

  @override
  String get legalTemplatesFillIntro =>
      'Rellenaremos automáticamente su nombre y los datos del caso. Complete los campos siguientes.';

  @override
  String get legalTemplatesFieldRequired => 'Este campo es obligatorio';

  @override
  String get legalTemplatesCreateDraft => 'Crear borrador';

  @override
  String get legalTemplatesCreating => 'Creando borrador…';

  @override
  String get legalTemplatesCreateFailed =>
      'No se pudo crear el borrador. Inténtelo de nuevo.';

  @override
  String get legalTemplatesUnresolvedWarning =>
      'Algunos campos siguen en blanco y están marcados con ____ en el borrador. Puede completarlos en el editor.';

  @override
  String get legalTemplatesFieldRecipient =>
      'Destinatario (autoridad / arrendador)';

  @override
  String get legalTemplatesFieldAddress => 'Su dirección postal';

  @override
  String get legalTemplatesFieldSubject => 'Asunto';

  @override
  String get legalTemplatesFieldDescription => 'Descripción del asunto';

  @override
  String get legalTemplatesFieldDemand => 'Qué solicita';

  @override
  String get checklistActionPlan => 'Plan de acción';

  @override
  String get checklistActionPlanSubtitle => 'Pasos para este tipo de caso';

  @override
  String checklistProgress(int completed, int total) {
    return '$completed de $total pasos completados';
  }

  @override
  String get checklistAllDone => 'Todos los pasos completados';

  @override
  String get checklistEmpty =>
      'Aún no hay un plan de acción disponible para este tipo de caso.';

  @override
  String checklistDeadlineDays(int days) {
    return '$days días';
  }

  @override
  String get checklistDisclaimer =>
      'Esta es información general, no asesoramiento jurídico. Los plazos son valores legales por defecto: confirme la fecha exacta de su caso.';

  @override
  String get checklistViewPlan => 'Ver plan';

  @override
  String get explainPlainTitle => 'Explicar en palabras sencillas';

  @override
  String get explainPlainIntro =>
      'Pegue una carta oficial, una resolución o un contrato y le explicaremos qué significa y qué le pide hacer, en lenguaje sencillo.';

  @override
  String get explainPlainLevelFriend => 'Como a un amigo';

  @override
  String get explainPlainLevelTerms => 'Mantener los términos jurídicos';

  @override
  String get explainPlainInputHint => 'Pegue aquí el texto jurídico…';

  @override
  String get explainPlainSubmit => 'Explicar';

  @override
  String get explainPlainWorking => 'Explicando…';

  @override
  String get explainPlainTldr => 'En resumen';

  @override
  String get explainPlainBreakdown => 'Qué dice, parte por parte';

  @override
  String get explainPlainGlossary => 'Términos difíciles explicados';

  @override
  String get explainPlainNextSteps => 'Qué puede hacer a continuación';

  @override
  String get explainPlainOpenInCorpus => 'Consultar en la biblioteca jurídica';

  @override
  String get explainPlainEmptyResult =>
      'No se pudo generar una explicación para este texto. Pruebe a pegar un fragmento más largo o más claro.';

  @override
  String get explainPlainQuotaTitle =>
      'Ha agotado sus explicaciones gratuitas de este mes';

  @override
  String get explainPlainQuotaBody =>
      'Las cuentas gratuitas tienen 3 explicaciones al mes. Pásese a Pro para disponer de explicaciones ilimitadas.';

  @override
  String get explainPlainUpgradeCta => 'Pasar a Pro';

  @override
  String get explainPlainError =>
      'Algo salió mal al explicar este texto. Inténtelo de nuevo.';

  @override
  String get explainPlainRetry => 'Reintentar';

  @override
  String get demandLetterTitle => 'Carta de requerimiento';

  @override
  String get demandLetterSubtitle =>
      'Cree un requerimiento de pago formal previo a la vía judicial (maksuvaatimus / nõudekiri).';

  @override
  String get demandLetterStepType => 'Tipo de reclamación';

  @override
  String get demandLetterStepParties => 'Partes';

  @override
  String get demandLetterStepClaim => 'Importe y fundamento';

  @override
  String get demandLetterStepDeadline => 'Plazo';

  @override
  String get demandLetterStepReview => 'Revisar y generar';

  @override
  String get demandLetterClaimDepositReturn =>
      'Devolución de la fianza de alquiler';

  @override
  String get demandLetterClaimUnpaidWage => 'Salarios impagados';

  @override
  String get demandLetterClaimFineDispute => 'Impugnar una multa / un cargo';

  @override
  String get demandLetterClaimGeneric => 'Otra reclamación dineraria';

  @override
  String get demandLetterJurisdiction => 'Jurisdicción';

  @override
  String get demandLetterLanguage => 'Idioma de la carta';

  @override
  String get demandLetterRecipientName => 'Nombre del destinatario';

  @override
  String get demandLetterRecipientAddress =>
      'Dirección del destinatario (opcional)';

  @override
  String get demandLetterSenderName => 'Su nombre';

  @override
  String get demandLetterSenderAddress =>
      'Su dirección / correo electrónico (opcional)';

  @override
  String get demandLetterAmount => 'Importe';

  @override
  String get demandLetterCurrency => 'Moneda';

  @override
  String get demandLetterBasis => 'Qué ocurrió (fundamento de la reclamación)';

  @override
  String get demandLetterBasisHint =>
      'Describa los hechos: fechas, importes, qué se acordó y qué salió mal.';

  @override
  String get demandLetterDeadline => 'Plazo de pago';

  @override
  String get demandLetterDeadlineHint => 'p. ej., 14 días a partir de hoy';

  @override
  String get demandLetterReference => 'Referencia (opcional)';

  @override
  String get demandLetterGenerate => 'Generar carta';

  @override
  String get demandLetterGenerating => 'Generando…';

  @override
  String get demandLetterGenerateFailed =>
      'No se pudo generar la carta. Inténtelo de nuevo.';

  @override
  String get demandLetterFieldRequired => 'Este campo es obligatorio';

  @override
  String get demandLetterNext => 'Siguiente';

  @override
  String get demandLetterBack => 'Atrás';

  @override
  String get demandLetterPreviewTitle => 'Su carta';

  @override
  String get demandLetterCopy => 'Copiar texto';

  @override
  String get demandLetterCopied => 'Carta copiada al portapapeles';

  @override
  String get demandLetterExportPdf => 'Exportar PDF';

  @override
  String get demandLetterExporting => 'Exportando…';

  @override
  String get demandLetterExportFailed =>
      'No se pudo exportar el documento. Inténtelo de nuevo.';

  @override
  String get demandLetterSendEmail => 'Enviar por correo electrónico';

  @override
  String get demandLetterNormsTitle => 'Referencias jurídicas';

  @override
  String get demandLetterDisclaimer =>
      'Esta carta se prepara en su nombre como plantilla general. No constituye asesoramiento jurídico ni un acto de un abogado colegiado. Revísela antes de enviarla: ninguna carta se envía automáticamente.';

  @override
  String get demandLetterMenuTile => 'Carta de requerimiento';

  @override
  String get calcHubTitle => 'Calculadoras jurídicas';

  @override
  String get calcHubSubtitle => 'Estimaciones rápidas antes de su próximo paso';

  @override
  String get calcHubJurisdiction => 'Jurisdicción';

  @override
  String calcRatesAsOf(String date) {
    return 'Tarifas a fecha de $date';
  }

  @override
  String get calcRatesOffline => 'Mostrando tarifas almacenadas (sin conexión)';

  @override
  String get calcIndicativeBanner =>
      'Solo estimación orientativa: no es un cálculo oficial ni asesoramiento jurídico.';

  @override
  String get calcCalculate => 'Calcular';

  @override
  String get calcResult => 'Resultado';

  @override
  String get calcFormula => 'Cómo se calcula';

  @override
  String get calcSource => 'Fuente';

  @override
  String get calcSeveranceTitle => 'Indemnización / preaviso';

  @override
  String get calcSeveranceDesc =>
      'Estime la indemnización por despido y el plazo de preaviso en caso de despido por causas objetivas';

  @override
  String get calcSeveranceSalary => 'Salario mensual bruto';

  @override
  String get calcSeveranceTenure => 'Años de antigüedad';

  @override
  String get calcSeveranceTotal => 'Indemnización estimada';

  @override
  String get calcSeveranceNotice => 'Plazo de preaviso';

  @override
  String get calcSeveranceGenerateDemand =>
      'Redactar una carta de requerimiento';

  @override
  String get calcLimitationTitle => 'Plazos de prescripción y de recurso';

  @override
  String get calcLimitationDesc =>
      'Compruebe si ha vencido un plazo de reclamación o de recurso';

  @override
  String get calcLimitationType => 'Tipo de plazo';

  @override
  String get calcLimitationStart => 'Fecha de inicio (hecho / resolución)';

  @override
  String get calcLimitationPickDate => 'Elegir fecha';

  @override
  String get calcLimitationDeadline => 'Plazo';

  @override
  String get calcLimitationExpired => 'El plazo ha vencido';

  @override
  String calcLimitationDaysLeft(int days) {
    return 'Quedan $days días';
  }

  @override
  String get calcLimitationShifted =>
      'Trasladado al siguiente día hábil (fin de semana/festivo).';

  @override
  String get calcLimitationAddDeadline => 'Añadir a los plazos';

  @override
  String get calcStateFeeTitle => 'Tasas judiciales / estatales';

  @override
  String get calcStateFeeDesc =>
      'Tasas de presentación de referencia por tribunal y fase';

  @override
  String get calcChildSupportTitle => 'Pensión de alimentos (orientación)';

  @override
  String get calcChildSupportDesc =>
      'Cifra orientativa aproximada: el importe real se fija caso por caso';

  @override
  String get calcChildSupportNet =>
      'Ingresos netos mensuales del obligado al pago';

  @override
  String get calcChildSupportChildren => 'Número de hijos';

  @override
  String get calcChildSupportPerChild => 'Por hijo';

  @override
  String get calcChildSupportTotal => 'Total mensual';

  @override
  String get calcChildSupportWarning =>
      'Muy variable. Los tribunales deciden según las necesidades del menor y la capacidad de pago de ambos progenitores. Úsela solo como punto de partida.';

  @override
  String get docCollectTitle => 'Documentos que reunir';

  @override
  String get docCollectSubtitle =>
      'Reúna estos documentos antes de presentar su solicitud o acudir al tribunal';

  @override
  String get docCollectPickPrompt => '¿Cuál es su situación?';

  @override
  String get docCollectProblemResidence => 'Permiso de residencia';

  @override
  String get docCollectProblemTenant => 'Alquiler / desahucio';

  @override
  String get docCollectProblemDismissal => 'Despido laboral';

  @override
  String get docCollectProblemInheritance => 'Herencia';

  @override
  String get docCollectProblemDivorce => 'Divorcio';

  @override
  String docCollectProgress(int collected, int total) {
    return '$collected de $total reunidos';
  }

  @override
  String get docCollectAllDone => 'Todo reunido';

  @override
  String get docCollectEmpty =>
      'Aún no hay una lista de documentos disponible para esta situación.';

  @override
  String get docCollectOptional => 'Opcional';

  @override
  String get docCollectWhereLabel => 'Dónde obtenerlo';

  @override
  String get docCollectWhyLabel => 'Por qué es necesario';

  @override
  String get docCollectAttach => 'Adjuntar un archivo';

  @override
  String get docCollectAttached => 'Archivo adjuntado';

  @override
  String get docCollectChangeFile => 'Cambiar archivo';

  @override
  String get docCollectRemoveFile => 'Eliminar archivo';

  @override
  String get docCollectNoFiles => 'Aún no ha subido ningún documento.';

  @override
  String get docCollectPickFileTitle => 'Elija un documento subido';

  @override
  String get docCollectExport => 'Exportar lista';

  @override
  String get docCollectExportSubject => 'Mi lista de documentos';

  @override
  String get docCollectAiTitle => '¿Necesita algo específico?';

  @override
  String get docCollectAiHint =>
      'Describa su situación y le sugeriremos documentos adicionales.';

  @override
  String get docCollectAiField => 'Describa su situación';

  @override
  String get docCollectAiButton => 'Sugerir documentos adicionales';

  @override
  String get docCollectAiLoading => 'Pensando…';

  @override
  String get docCollectAiEmpty =>
      'No se sugieren documentos adicionales: la lista básica parece completa para su descripción.';

  @override
  String get docCollectAiSuggestionsTitle => 'Documentos adicionales sugeridos';

  @override
  String get docCollectDisclaimer =>
      'Esta es una lista básica de los documentos que suelen exigirse; su situación puede requerir más o menos. Es información general, no asesoramiento jurídico.';

  @override
  String get docCollectRetry => 'Reintentar';

  @override
  String get renewalTitle => 'Radar de renovaciones';

  @override
  String get renewalSubtitle =>
      'Controle cuándo caducan sus permisos, pasaporte, seguros y otros documentos. Le recordaremos 90, 30 y 7 días antes de cada renovación.';

  @override
  String get renewalAdd => 'Añadir documento';

  @override
  String get renewalEditTitle => 'Editar documento';

  @override
  String get renewalSave => 'Guardar';

  @override
  String get renewalRequired => 'Obligatorio';

  @override
  String get renewalPickDate => 'Elegir fecha de caducidad';

  @override
  String get renewalLoadError =>
      'No se pudieron cargar sus documentos. Deslice para actualizar.';

  @override
  String get renewalEmptyTitle => 'Aún no hay documentos en seguimiento';

  @override
  String get renewalEmptyBody =>
      'Añada su permiso de residencia, pasaporte, seguro o licencia y vigilaremos por usted las fechas de caducidad.';

  @override
  String get renewalGuideHint => 'Cómo renovar →';

  @override
  String get renewalFieldType => 'Tipo de documento';

  @override
  String get renewalFieldLabel => 'Etiqueta';

  @override
  String get renewalFieldNumber => 'Número de documento (opcional)';

  @override
  String get renewalFieldJurisdiction => 'País emisor';

  @override
  String get renewalFieldExpiry => 'Fecha de caducidad';

  @override
  String get renewalWindow90 => '90 días';

  @override
  String get renewalWindow30 => '30 días';

  @override
  String get renewalWindow7 => '7 días';

  @override
  String get renewalExpiresToday => 'Caduca hoy';

  @override
  String renewalExpiresInDays(int days, String date) {
    return 'Caduca en $days días · $date';
  }

  @override
  String renewalExpiredOn(String date) {
    return 'Caducó el $date';
  }

  @override
  String get renewalTypeResidencePermit => 'Permiso de residencia';

  @override
  String get renewalTypePassport => 'Pasaporte';

  @override
  String get renewalTypeIdCard => 'Documento de identidad';

  @override
  String get renewalTypeVisa => 'Visado';

  @override
  String get renewalTypeDrivingLicence => 'Permiso de conducir';

  @override
  String get renewalTypeInsurance => 'Seguro';

  @override
  String get renewalTypeWorkPermit => 'Permiso de trabajo';

  @override
  String get renewalTypeOther => 'Otro';

  @override
  String get costEstimateTitle => 'Estimador de costes y riesgos';

  @override
  String get costEstimateSubtitle =>
      'Hágase una idea aproximada de lo que podría costar un caso, cuánto podría tardar y si merece la pena emprenderlo.';

  @override
  String get costEstimateCaseTypeLabel => 'Tipo de caso';

  @override
  String get costEstimateCaseTypeHint =>
      'p. ej., factura impagada, despido improcedente, disputa por la fianza';

  @override
  String get costEstimateJurisdictionLabel => 'Jurisdicción';

  @override
  String get costEstimateAmountLabel => 'Importe en disputa (opcional)';

  @override
  String get costEstimateAmountHint => 'p. ej., 12500';

  @override
  String get costEstimateDescriptionLabel =>
      'Describa brevemente la situación (opcional)';

  @override
  String get costEstimateB2bToggle => 'Ficha de cualificación de leads (B2B)';

  @override
  String get costEstimateB2bSubtitle =>
      'Resultado compacto para clasificar rápidamente a un cliente potencial.';

  @override
  String get costEstimateSubmit => 'Estimar mi caso';

  @override
  String get costEstimateDisclaimer =>
      'Solo estimación aproximada: no es una predicción, garantía ni asesoramiento jurídico. Los costes y resultados reales varían según el caso.';

  @override
  String get costEstimateCostsHeading => 'Costes estimados';

  @override
  String get costEstimateCourtFee => 'Tasa judicial / estatal';

  @override
  String get costEstimateLawyerFee => 'Honorarios del abogado';

  @override
  String get costEstimateTotal => 'Total (aprox.)';

  @override
  String get costEstimateDuration => 'Tiempo hasta la primera resolución';

  @override
  String get costEstimateMonthsSuffix => 'meses';

  @override
  String get costEstimateFactorsFor => 'A su favor';

  @override
  String get costEstimateFactorsAgainst => 'En su contra';

  @override
  String get costEstimateStrengthWorth =>
      'Probablemente merezca la pena emprenderlo';

  @override
  String get costEstimateStrengthContested =>
      'Disputado: podría ir en cualquier dirección';

  @override
  String get costEstimateStrengthWeak => 'Débil: proceda con cautela';
}
