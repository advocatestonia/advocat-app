import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Conditional import: real dart:html on web, no-op stub elsewhere.
// Lets non-web platforms compile without dart:html.
import 'shared/web_locale_stub.dart'
    if (dart.library.html) 'shared/web_locale_web.dart' as web_locale;

import 'config/app_config.dart';
import 'config/theme.dart';
import 'config/router.dart';
import 'core/services/error_reporter.dart';
import 'features/auth/providers/auth_provider.dart'
    show passwordRecoveryPendingProvider;
import 'l10n/app_localizations.dart';
import 'services/notification_service.dart';
import 'shared/error_boundary.dart';
import 'shared/providers/theme_mode_provider.dart';
import 'shared/telemetry_sink.dart';
import 'widgets/support/support_fab.dart';

/// Language data used across the app (onboarding, home, settings).
class LanguageOption {
  final String code;
  final String name;
  final String flag;

  const LanguageOption(this.code, this.name, this.flag);
}

const List<LanguageOption> supportedLanguages = [
  LanguageOption('et', 'Eesti', '\u{1F1EA}\u{1F1EA}'),
  LanguageOption('en', 'English', '\u{1F1EC}\u{1F1E7}'),
  LanguageOption('fi', 'Suomi', '\u{1F1EB}\u{1F1EE}'),
  LanguageOption('de', 'Deutsch', '\u{1F1E9}\u{1F1EA}'),
  LanguageOption('ru', '\u0420\u0443\u0441\u0441\u043A\u0438\u0439', '\u{1F1F7}\u{1F1FA}'),
  LanguageOption('sv', 'Svenska', '\u{1F1F8}\u{1F1EA}'),
  LanguageOption('uk', '\u0423\u043A\u0440\u0430\u0457\u043D\u0441\u044C\u043A\u0430', '\u{1F1FA}\u{1F1E6}'),
  LanguageOption('fr', 'Fran\u00e7ais', '\u{1F1EB}\u{1F1F7}'),
  LanguageOption('es', 'Espa\u00f1ol', '\u{1F1EA}\u{1F1F8}'),
  LanguageOption('it', 'Italiano', '\u{1F1EE}\u{1F1F9}'),
  LanguageOption('pl', 'Polski', '\u{1F1F5}\u{1F1F1}'),
  LanguageOption('lv', 'Latvie\u0161u', '\u{1F1F1}\u{1F1FB}'),
  LanguageOption('lt', 'Lietuvi\u0173', '\u{1F1F1}\u{1F1F9}'),
  LanguageOption('ro', 'Rom\u00e2n\u0103', '\u{1F1F7}\u{1F1F4}'),
  LanguageOption('tr', 'T\u00fcrk\u00e7e', '\u{1F1F9}\u{1F1F7}'),
  LanguageOption('ar', '\u0627\u0644\u0639\u0631\u0628\u064A\u0629', '\u{1F1F8}\u{1F1E6}'),
  LanguageOption('fa', '\u0641\u0627\u0631\u0633\u06cc', '\u{1F1EE}\u{1F1F7}'),
];

const String _localeKey = 'app_locale';

/// SharedPreferences instance, initialised before runApp.
late final SharedPreferences _prefs;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Install the global error boundary FIRST, before any other init. Any
  // LateInitializationError / async crash during startup lands in a
  // friendly reload card instead of a permanent grey screen.
  installErrorBoundary();

  // Sentry: only initialise when a DSN is provided via
  // --dart-define=SENTRY_DSN=... (production builds via canary-deploy.sh).
  // Local dev / CI without a DSN skips Sentry entirely and falls through
  // to the existing app runner — see lib/core/services/error_reporter.dart.
  if (sentryEnabled) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.environment = sentryEnv;
        options.release = sentryRelease;
        // 10% perf sample — bumpable later via dart-define if needed.
        options.tracesSampleRate = 0.1;
        // Profiling is off — third-party CPU cost not yet validated.
        options.profilesSampleRate = 0.0;
        // CRITICAL: never let the SDK auto-attach user PII (ip, headers).
        options.sendDefaultPii = false;
        options.attachThreads = false;
        options.maxBreadcrumbs = 50;
        // STRICT scrubbers — see ErrorReporter for the contract.
        options.beforeSend = ErrorReporter.beforeSend;
        options.beforeBreadcrumb = ErrorReporter.beforeBreadcrumb;
      },
      appRunner: _bootstrap,
    );
    return;
  }

  await _bootstrap();
}

/// The original app-runner body, extracted so SentryFlutter.init can wrap
/// it when a DSN is configured and bypass it cleanly when one isn't.
Future<void> _bootstrap() async {
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  _prefs = await SharedPreferences.getInstance();

  // Supabase: initialize only when credentials are provided via --dart-define.
  // Without credentials the app runs in demo mode.
  const supabaseUrl = AppConfig.supabaseUrl;
  const supabaseAnonKey = AppConfig.supabaseAnonKey;
  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    // Security: F7 (WAVE 1, 2026-05-28) — pin PKCE flow explicitly so a
    // future Supabase SDK default change cannot silently fall back to the
    // implicit grant (which is vulnerable to authorization-code replay).
    // PKCE has been the SDK default since 2.0, so this is belt-and-braces.
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );

    // P5 of Bentley batch (2026-05-15): wire the Sentry-lite telemetry sink
    // to the global error boundary. The sink is a no-op in debug builds
    // AND when the user has not opted into telemetry — see
    // lib/shared/telemetry_sink.dart for the consent gate. Without this
    // install call, the boundary catches errors but they never reach
    // public.app_errors, leaving the owner blind to production crashes.
    //
    // Fire-and-forget — the sink installer is async because it touches
    // SharedPreferences, but main() should not block on it.
    final localeCode = _prefs.getString(_localeKey);
    unawaited(installTelemetrySinkIfConsented(
      client: Supabase.instance.client,
      appVersion: AppConfig.appVersion,
      locale: localeCode,
    ));

    // Pkg 9 — Deadline Radar push channel.
    //
    // Request FCM permission + register the device token against
    // `notification_preferences.fcm_token` so the `push-send` edge fn can
    // route deadline reminders to this device. Fire-and-forget — the
    // service swallows all errors and never blocks startup.
    //
    // We do NOT call this on web (firebase_messaging Web requires a VAPID
    // key + a service-worker file; mobile MVP only). The kIsWeb branch on
    // line 196 means web users still get the in-app banner channel.
    //
    // We do NOT pre-request before the user signs in either — anonymous
    // sessions have no `auth.uid()` and the upsert would no-op. The auth
    // gate inside [NotificationPreferencesService.updateFcmToken] handles
    // that case, so calling here is safe even pre-auth; the token will
    // simply be persisted on the next refresh after sign-in.
    if (!kIsWeb) {
      unawaited(NotificationService.instance.requestPermission());
    }
  }

  // Firebase.initializeApp() requires firebase_options.dart — run flutterfire configure first
  // Stripe.publishableKey = AppConfig.stripePublishableKey;

  runWithErrorBoundary(() {
    runApp(
      ProviderScope(
        overrides: [
          // Surface the already-initialised SharedPreferences singleton so
          // the themeModeProvider (and any future pref-backed provider) can
          // resolve synchronously from inside Riverpod.
          sharedPreferencesProvider.overrideWithValue(_prefs),
        ],
        child: const AdvocatApp(),
      ),
    );
  });
}

/// Root [ScaffoldMessenger] key for cross-route SnackBars.
///
/// Per-Scaffold messengers die with their route, so any "show a SnackBar
/// on the *next* screen after navigation" flow (e.g. the intake wizard
/// urgent-shortcut Undo, FIX-WAVE 6 / 2026-05-20) needs a messenger that
/// outlives go_router transitions. Use sparingly — prefer per-screen
/// messengers when the toast belongs to the current screen.
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>(debugLabel: 'root');

class AdvocatApp extends ConsumerWidget {
  const AdvocatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);
    // Default = ThemeMode.system (OS preference wins until the user picks
    // Light/Dark in Settings → Appearance). See shared/providers/theme_mode_provider.dart.
    final themeMode = ref.watch(themeModeProvider);

    // Password-recovery deep link: when Supabase emits
    // AuthChangeEvent.passwordRecovery (user clicked the reset-email link),
    // the auth controller flips this flag — route to the set-new-password
    // screen so the reset flow isn't a dead end (beta audit 2026-06-11).
    // The flag also flips back to false after a successful update; the
    // `next` guard ignores that transition.
    ref.listen<bool>(passwordRecoveryPendingProvider, (previous, next) {
      if (next && previous != true) {
        router.go(AppRoutes.newPassword);
      }
    });

    return MaterialApp.router(
      title: 'Advocat \u2014 AI Legal Defense',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
      // The global support FAB lives in a Stack overlay above every route.
      // It is mounted via [MaterialApp.builder] so it survives navigation
      // (rather than being attached per-screen). The FAB itself is small,
      // dependency-light, and Material-localised — see widgets/support/.
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null)
              NotificationListener<UserScrollNotification>(
                onNotification: (n) {
                  kSupportFabBus.notifyScroll(n.direction);
                  return false;
                },
                child: child,
              ),
            const Positioned(
              right: 0,
              bottom: 0,
              child: SafeArea(child: SupportFab()),
            ),
          ],
        );
      },
    );
  }
}

/// Provider for the current locale, persisted via SharedPreferences.
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(_loadSavedLocale());

  /// Valid language codes the app supports.
  static final Set<String> _supportedCodes =
      supportedLanguages.map((l) => l.code).toSet();

  /// Priority on first boot:
  ///   1. URL ?lang= param (explicit user intent).
  ///   2. SharedPreferences (user previously set inside the app).
  ///   3. localStorage 'advocat-landing-lang' (bridge from web landing).
  ///   4. navigator.language (browser preference, first 2 chars).
  ///   5. Estonian (default).
  /// Once the user changes language via the in-app picker, [setLocale] writes
  /// SharedPreferences and step 2 wins forever after — so the manual choice is
  /// preserved across sessions even if the landing/browser disagrees.
  static Locale _loadSavedLocale() {
    // 1. Check URL query parameter (works on web; empty map on other platforms).
    if (kIsWeb) {
      final urlLang = Uri.base.queryParameters['lang'];
      if (urlLang != null && _supportedCodes.contains(urlLang)) {
        // Persist so subsequent visits (without ?lang) keep the choice.
        _prefs.setString(_localeKey, urlLang);
        return Locale(urlLang);
      }
    }

    // 2. SharedPreferences (covers returning users & in-app picker choice).
    final saved = _prefs.getString(_localeKey);
    if (saved != null && _supportedCodes.contains(saved)) {
      return Locale(saved);
    }

    // 3. Bridge from web landing: window.localStorage['advocat-landing-lang'].
    //    Non-web platforms return null from the stub — no-op.
    if (kIsWeb) {
      final landingLang = web_locale.readLandingLang();
      if (landingLang != null && _supportedCodes.contains(landingLang)) {
        _prefs.setString(_localeKey, landingLang);
        return Locale(landingLang);
      }

      // 4. Browser preference (navigator.language first 2 chars).
      final navLang = web_locale.readNavigatorLang();
      if (navLang != null && _supportedCodes.contains(navLang)) {
        _prefs.setString(_localeKey, navLang);
        return Locale(navLang);
      }
    }

    // 5. Default — Estonian.
    return const Locale('et');
  }

  void setLocale(Locale locale) {
    state = locale;
    _prefs.setString(_localeKey, locale.languageCode);
  }
}
