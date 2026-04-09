/// Centralized application configuration.
///
/// All sensitive values are read from compile-time environment variables
/// using `--dart-define`. Never hard-code secrets here.
///
/// **SECURITY NOTE — MVP ONLY:**
/// API keys below are embedded as compile-time constants via `--dart-define`.
/// While not visible in source code, they ARE present in the compiled binary
/// and can be extracted via reverse-engineering. Before production launch,
/// ALL API calls must be routed through a server-side proxy so that keys
/// never leave the backend. See: https://docs.anthropic.com/en/docs/build-with-claude
///
/// **NEVER log or print any of these values.** They must not appear in
/// console output, crash reports, or analytics payloads.
class AppConfig {
  AppConfig._();

  // ── Supabase ──────────────────────────────────────────────────────────
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://okgnkucgwsytsondrjye.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  // ── Stripe ────────────────────────────────────────────────────────────
  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  static const String stripeMerchantId = String.fromEnvironment(
    'STRIPE_MERCHANT_ID',
    defaultValue: 'merchant.com.ailegaldefense',
  );

  // ── AI Service ────────────────────────────────────────────────────────
  static const String aiApiBaseUrl = String.fromEnvironment(
    'AI_API_BASE_URL',
    defaultValue: '',
  );

  static const String aiApiKey = String.fromEnvironment(
    'AI_API_KEY',
    defaultValue: '',
  );

  // ── Claude Direct API ────────────────────────────────────────────────
  // TODO(production): MOVE TO SERVER-SIDE PROXY before public launch.
  // Client-side API keys can be extracted from compiled binaries.
  // Use a Supabase Edge Function or similar backend proxy instead.
  static const String claudeApiKey = String.fromEnvironment(
    'CLAUDE_API_KEY',
    defaultValue: '',
  );

  /// AI mode: 'real' to use Claude API directly, 'demo' for mock responses.
  /// Auto-detected: if CLAUDE_API_KEY is set, defaults to 'real'.
  static const String _aiModeRaw = String.fromEnvironment(
    'AI_MODE',
    defaultValue: 'auto',
  );

  /// Resolved AI mode. When set to 'auto', uses real AI if a Supabase proxy
  /// (with anon key) or direct Claude API key is available, otherwise falls
  /// back to demo mode.
  static bool get useRealAI {
    if (_aiModeRaw == 'real') return true;
    if (_aiModeRaw == 'demo') return false;
    // 'auto': use real AI if Supabase proxy with anon key, or direct API key
    return useSupabaseProxy || claudeApiKey.isNotEmpty;
  }

  /// Whether the Supabase proxy is fully configured (URL + anon key).
  static bool get useSupabaseProxy =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  // ── Email Integration ─────────────────────────────────────────────────
  static const String emailApiBaseUrl = String.fromEnvironment(
    'EMAIL_API_BASE_URL',
    defaultValue: '',
  );

  // ── General ───────────────────────────────────────────────────────────
  static const String appName = 'AI Legal Defense';
  static const String appVersion = '1.0.0';

  static const bool isProduction = bool.fromEnvironment(
    'PRODUCTION',
    defaultValue: false,
  );

  /// Minimum interval between AI requests to avoid abuse (milliseconds).
  static const int aiRequestThrottleMs = 1000;

  /// Maximum document file size in bytes (20 MB).
  static const int maxDocumentSizeBytes = 20 * 1024 * 1024;

  /// Supported document MIME types for upload.
  static const List<String> supportedDocumentTypes = [
    'application/pdf',
    'image/jpeg',
    'image/png',
    'image/heic',
  ];
}
