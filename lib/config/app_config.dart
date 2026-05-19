/// Centralized application configuration.
///
/// All sensitive values are read from compile-time environment variables
/// using `--dart-define`. Never hard-code secrets here.
///
/// **NEVER log or print any of these values.** They must not appear in
/// console output, crash reports, or analytics payloads.
///
/// All Claude API traffic goes through the `claude-proxy` Supabase Edge
/// Function — the Anthropic key lives server-side only. There is no
/// direct-API client path; do not add one back.
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

  // ── Claude AI mode ───────────────────────────────────────────────────
  /// AI mode: 'real' to use Claude via the Supabase proxy, 'demo' for
  /// mock responses, 'auto' (default) to pick automatically based on
  /// proxy configuration.
  static const String _aiModeRaw = String.fromEnvironment(
    'AI_MODE',
    defaultValue: 'auto',
  );

  /// Resolved AI mode. In 'auto' mode, returns true iff the Supabase proxy
  /// is configured (URL + anon key). The proxy is the only Claude path —
  /// the legacy direct-Anthropic client path has been removed.
  static bool get useRealAI {
    if (_aiModeRaw == 'real') return true;
    if (_aiModeRaw == 'demo') return false;
    // 'auto': real AI only when the Supabase proxy is fully configured.
    return useSupabaseProxy;
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

/// Support widget configuration.
///
/// All values are read at compile time via `--dart-define`. Leave them
/// blank if a channel is not yet provisioned — the support sheet hides
/// any channel whose value is empty.
class SupportConfig {
  SupportConfig._();

  /// WhatsApp number in international format (digits only, no + or spaces).
  /// Example: `--dart-define=ADVOCAT_WHATSAPP_NUMBER=3725551234`. An empty
  /// value hides the WhatsApp button entirely.
  static const String whatsappNumber = String.fromEnvironment(
    'ADVOCAT_WHATSAPP_NUMBER',
    defaultValue: '',
  );

  /// Email used by the "Email us" button in the support sheet.
  static const String supportEmail = String.fromEnvironment(
    'ADVOCAT_SUPPORT_EMAIL',
    defaultValue: 'support@advocat.ee',
  );

  /// Whether the WhatsApp channel should be shown. Returns false when the
  /// number is unset so the button silently disappears.
  static bool get whatsappAvailable => whatsappNumber.isNotEmpty;
}
