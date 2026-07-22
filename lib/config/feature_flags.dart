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
/// Flip via `--dart-define=ADVOCAT_REFERRAL_ENABLED=false` at build time to
/// disable as a fast-rollback lever.
///
/// Re-enabled 2026-05-27 after security audit:
///   - Self-referral blocked (handler.ts inviterId === userId).
///   - Idempotency enforced by unique(referred_user_id) + race-loss handling.
///   - Rate-limited 30/min/user via requireUserWithRateLimit.
///   - Anon callers rejected (anonymousPerMinute=0 + anon: prefix check).
///   - Anti-abuse: rolling 12-credit/365-day cap (shouldBlockForAbuse).
///   - Credit path (creditInviterForReferred) callable only from stripe-webhook,
///     not from user JWT — a compromised user JWT cannot forge credit events.
///   - Code format restricted to ^[a-z0-9]{6,16}$.
///
/// Ref: consilium 2026-05-15 (soft-launch decision) + 2026-05-27 re-enable audit.
const bool kReferralEnabled = bool.fromEnvironment(
  'ADVOCAT_REFERRAL_ENABLED',
  defaultValue: true,
);

// -----------------------------------------------------------------------------
// Lawyer verification programme ("AI for verified attorneys — free forever").
// Ref: consilium adversary 2026-05-15, Bentley+ batch P12.
// -----------------------------------------------------------------------------

/// Master switch for the lawyer verification feature.
///
/// When `false`:
///   * The /lawyers landing copy still renders, but the verification form
///     entry button is hidden.
///   * The "Verify as attorney" tile on Settings is hidden.
///   * Direct deep-links to /lawyers/verify show a "temporarily paused"
///     placeholder card.
///   * The `verify-lawyer` Supabase edge function returns 503 with reason
///     `program_disabled` regardless of this flag (the function reads its
///     own LAWYER_PROGRAM_ENABLED env var).
///
/// Default `true` per the P12 brief — the programme ships enabled and is
/// disabled only as a fast-rollback lever if the bar registries become
/// unreachable or we hit an abuse vector.
///
/// Override via `--dart-define=ADVOCAT_LAWYER_PROGRAM_ENABLED=false`.
const bool kLawyerProgramEnabled = bool.fromEnvironment(
  'ADVOCAT_LAWYER_PROGRAM_ENABLED',
  defaultValue: true,
);

// -----------------------------------------------------------------------------
// Lawyer partnership programme — "1 human-lawyer call/quarter free" on Pro+.
// Ref: Day2-E brief (2026-05-16). Bets HUGO+ on value (their €9.90 hybrid).
// -----------------------------------------------------------------------------

/// Master switch for the "Book a lawyer call" perk shipped on Pro+ tiers.
///
/// When `false` (the **production default** until the owner has at least
/// three EE solo lawyers enrolled):
///   * The "Book a lawyer call" tile on the Pro/Premium home is hidden.
///   * The /book-lawyer route renders a "coming soon" placeholder card
///     instead of the booking form (so a leaked deep-link doesn't take a
///     fee for a service that has no providers yet).
///   * The /partner-lawyer route renders a "not enrolled" placeholder for
///     anyone hitting it (the dashboard is meaningless without the partner
///     programme running).
///   * The `lawyer-booking` Supabase edge function returns 503 with
///     `program_disabled` regardless of this flag (it reads its own
///     `LAWYER_PARTNERSHIP_ENABLED` env var; this flag is the client-side
///     mirror so the UI never offers an action the server will refuse).
///
/// Flip via `--dart-define=ADVOCAT_LAWYER_PARTNERSHIP_ENABLED=true` at
/// build time when the partner pool is ready. Both flags (client + server)
/// must be true for the feature to be live end-to-end.
///
/// ⚠️ DO NOT default this to `true` without coordinating with the partner
/// programme rollout — an empty "no slots available" state kills trust
/// faster than the feature builds it.
const bool kLawyerPartnershipEnabled = bool.fromEnvironment(
  'ADVOCAT_LAWYER_PARTNERSHIP_ENABLED',
  defaultValue: false,
);

// -----------------------------------------------------------------------------
// B2B org — pending (not-yet-deployed) edge-function endpoints.
// Ref: prod edge-function audit 2026-07-16 (plan 1.1). Owner decision
// 2026-07-16: no paying B2B orgs exist, so these stay OFF.
// -----------------------------------------------------------------------------

/// Gates every client call to a B2B org edge function that is NOT deployed
/// to prod as of 2026-07-16. The 9 phantom functions:
///
///   cancel-invitation, change-plan, change-seats, check-slug-availability,
///   org-billing-summary, org-invoices, preview-invitation,
///   resend-invitation, save-org-branding
///
/// When `false` (the **production default**):
///   * `OrgRepository` never invokes any of the functions above —
///     `isSlugAvailable` falls back to a direct table query, list-style
///     methods return empty, mutating methods throw
///     `OrgRepositoryException('feature_disabled')`.
///   * Members screen: "Resend" / "Cancel invitation" controls are hidden.
///   * Billing screen: seat +/- steppers and the Invoices section are
///     hidden (plan & payment method are still manageable via the Stripe
///     portal, whose `org-billing-portal` function IS deployed).
///   * Branding screen: the editor is replaced by a "coming soon" card
///     (autosave would silently fail without `save-org-branding`).
///
/// Flip via `--dart-define=ADVOCAT_ORG_PENDING_B2B_ENDPOINTS_ENABLED=true`
/// ONLY after the 9 functions above are deployed and smoke-tested — the
/// contract test `test/contract/org_edge_functions_contract_test.dart`
/// pins this list against `supabase/functions/`.
const bool kOrgPendingB2bEndpointsEnabled = bool.fromEnvironment(
  'ADVOCAT_ORG_PENDING_B2B_ENDPOINTS_ENABLED',
  defaultValue: false,
);
