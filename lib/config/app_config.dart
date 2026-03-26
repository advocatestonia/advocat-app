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
