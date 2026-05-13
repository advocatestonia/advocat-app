import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_config.dart';
import 'config/theme.dart';
import 'config/router.dart';
import 'l10n/app_localizations.dart';
import 'shared/error_boundary.dart';
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
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  // Firebase.initializeApp() requires firebase_options.dart — run flutterfire configure first
  // Stripe.publishableKey = AppConfig.stripePublishableKey;

  runWithErrorBoundary(() {
    runApp(
      const ProviderScope(
        child: AdvocatApp(),
      ),
    );
  });
}

class AdvocatApp extends ConsumerWidget {
  const AdvocatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Advocat \u2014 AI Legal Defense',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
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
            if (child != null) child,
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

  /// Priority: URL ?lang= param > SharedPreferences > Estonian (default).
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

    // 2. Check SharedPreferences (covers returning users & localStorage bridge).
    final saved = _prefs.getString(_localeKey);
    if (saved != null && _supportedCodes.contains(saved)) {
      return Locale(saved);
    }

    // 3. Default — ALWAYS Estonian. No browser language auto-detect.
    return const Locale('et');
  }

  void setLocale(Locale locale) {
    state = locale;
    _prefs.setString(_localeKey, locale.languageCode);
  }
}
