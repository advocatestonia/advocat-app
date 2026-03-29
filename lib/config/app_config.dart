/// Centralized application configuration.
///
/// All sensitive values are read from compile-time environment variables
/// using `--dart-define`. Never hard-code secrets here.
class AppConfig {
  AppConfig._();

  // ── Supabase ──────────────────────────────────────────────────────────
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
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

  // ── Claude Direct API (MVP — will move to server-side proxy) ────────
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

  /// Resolved AI mode. When set to 'auto', uses real AI if a Claude API key
  /// is available, otherwise falls back to demo mode.
  static bool get useRealAI {
    if (_aiModeRaw == 'real') return true;
    if (_aiModeRaw == 'demo') return false;
    // 'auto': use real AI if API key is configured
    return claudeApiKey.isNotEmpty;
  }

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
