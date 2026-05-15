// feature_flags.dart — centralised feature flags for the Advocat app.
// -----------------------------------------------------------------------------
// One file per flag dimension. Do not import other config (theme, router)
// from here — this module must be safe to evaluate before Supabase init,
// because email_screen.dart references it at top-level for the OAuth scope
// constant.
//
// Refs:
//   business/email_agent_handoff_2026-05-06/v2.1_consilium/CONSILIUM_DECISIONS.md §0
//   business/email_agent_handoff_2026-05-06/v2.1_consilium/track_C_owner_decisions.md O1
//   business/email_agent_handoff_2026-05-06/09_INTEGRATION_INTO_ADVOCAT.md §D1
// -----------------------------------------------------------------------------

/// V1 — original send-only Gmail OAuth scope set.
/// Users connected before D1 (2026-05-07) hold tokens minted with this set.
const String kGmailOAuthScopesV1 =
    'email '
    'https://www.googleapis.com/auth/gmail.send';

/// V2 — proactive-inbox scope set (D1, 2026-05-07).
/// Adds `gmail.readonly` (read inbox for triage) and `gmail.modify` (apply
/// labels e.g. `advocat-handled-auto`) on top of `gmail.send`.
///
/// Owner action required (per memory: feedback_anti_regression_rules.md):
///   - Before flipping `kGmailScopesActive` to V2 in production, add
///     `gmail.readonly` and `gmail.modify` to the Authorized Scopes list
///     in Google Cloud Console (OAuth consent screen). Without that,
///     Google returns `error=access_denied` even though the request looks
///     fine on our side.
const String kGmailOAuthScopesV2 =
    'email '
    'https://www.googleapis.com/auth/gmail.send '
    'https://www.googleapis.com/auth/gmail.readonly '
    'https://www.googleapis.com/auth/gmail.modify';

/// Active scope set. Defaults to V2 (D1 shipped 2026-05-07). To roll back,
/// flip to `kGmailOAuthScopesV1` and redeploy — the re-auth banner
/// automatically hides because `kGmailScopesIncludeProactive` returns false.
const String kGmailScopesActive = kGmailOAuthScopesV2;

/// True iff the active scope set includes the proactive scopes
/// (`gmail.readonly` + `gmail.modify`). Used by the re-auth banner widget
/// to gate visibility — when false, the banner is dead code regardless of
/// what scopes the user's stored token currently has.
bool get kGmailScopesIncludeProactive =>
    kGmailScopesActive.contains('gmail.readonly') &&
    kGmailScopesActive.contains('gmail.modify');

/// Returns true if the given scope string (typically read from
/// `user_oauth_tokens.scope`) already includes `gmail.readonly`. A token
/// whose stored scope contains the read scope does NOT need re-auth.
///
/// Defensive: a `null` scope is treated as "not including readonly", which
/// triggers the banner — preferring user friction over the silent
/// loss-of-functionality failure mode (the banner can be dismissed via
/// re-auth, the silent failure cannot).
bool gmailScopeIncludesReadonly(String? scope) {
  if (scope == null || scope.isEmpty) return false;
  return scope.contains('gmail.readonly');
}

// -----------------------------------------------------------------------------
// Referral programme — soft-launch gate (consilium 2026-05-15).
// -----------------------------------------------------------------------------

/// Master switch for the in-app referral programme ("Invite a friend").
///
/// When `false` (current production default):
///   * The settings-screen "Invite friends" tile is hidden.
///   * The post-first-conversation snackbar nudge is suppressed.
///   * The /referral and /r/:code routes remain registered so that inbound
///     shared links (web/r.html → /r/<code>) still resolve — that surface
///     is governed by the server-side referral attribution endpoint, not
///     by the UI.
///   * The referral_service / providers / models stay compiled and
///     reachable from code; only the UI entry points are dark.
///
/// Flip via `--dart-define=ADVOCAT_REFERRAL_ENABLED=true` at build time to
/// re-enable without touching source.
///
/// Ref: consilium 2026-05-15 (soft-launch decision).
const bool kReferralEnabled = bool.fromEnvironment(
  'ADVOCAT_REFERRAL_ENABLED',
  defaultValue: false,
);
