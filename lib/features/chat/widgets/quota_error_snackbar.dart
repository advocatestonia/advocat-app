// =============================================================================
// quota_error_snackbar.dart
// =============================================================================
//
// Bug 1 fix (2026-05-05): when a free or anonymous user hit the AI quota
// cap (or the IP rate-limit), the send button silently no-op'd. The user
// got no feedback and assumed the app was broken.
//
// QA agent observation: "After Pro upgrade banner appeared mid-session, my
// next 2 send-button clicks silently no-op'd. Could be the actual cause of
// the broken sends, not a Flutter bug."
//
// This module provides a tiny pure helper [buildQuotaErrorSnackBar] that
// the chat screen surfaces via `ScaffoldMessenger.of(ctx).showSnackBar(...)`
// whenever a send is denied. Three reasons are differentiated:
//
//   1. [QuotaDenialReason.anonDemo] — anon user hit the demo cap. Shows
//      the demo limit text + a "Sign up" CTA that navigates to /register.
//   2. [QuotaDenialReason.freeQuotaExhausted] — logged-in free user used
//      all 7 monthly messages. Shows the upgrade text + an "Upgrade" CTA
//      that navigates to /subscription.
//   3. [QuotaDenialReason.rateLimit] — IP rate-limit (3/min) hit. Shows a
//      transient "try again" message with NO CTA (the user just waits).
//
// The helper is a pure function so the unit test can assert text + CTA
// wiring without spinning up the full ChatScreen.
// =============================================================================

import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';

/// Why a chat send was denied. Use [fromQuota] to derive the reason from
/// the current [AiQuota]/auth state — pass the resulting (nullable) value
/// to [buildQuotaErrorSnackBar] when non-null.
enum QuotaDenialReason {
  /// Anonymous user hit the demo cap (3/min IP rate limit + demo cap).
  /// CTA: sign up.
  anonDemo,

  /// Logged-in free-tier user used all 7 monthly messages. CTA: upgrade.
  freeQuotaExhausted,

  /// IP rate-limit (3 messages per minute). Transient — no CTA.
  rateLimit;

  /// Pure inference: maps quota+auth state to the right denial reason.
  /// Returns null when the user is allowed to send (i.e. nothing to surface).
  ///
  /// - [isAnon] true when there is no Supabase session for the user.
  /// - [remaining] is the server-reported remaining free messages
  ///   (0 ⇒ exhausted). -1 means "unlimited" — pro users never hit this.
  /// - [isPro] short-circuits: pro users are never denied.
  static QuotaDenialReason? fromQuota({
    required bool isAnon,
    required int remaining,
    required bool isPro,
  }) {
    if (isPro) return null;
    if (isAnon) return QuotaDenialReason.anonDemo;
    if (remaining == 0) return QuotaDenialReason.freeQuotaExhausted;
    return null;
  }
}

/// Build a localized [SnackBar] for the given [reason]. Returns the
/// SnackBar instance — caller must invoke
/// `ScaffoldMessenger.of(context).showSnackBar(...)` on it.
///
/// CTAs:
///   - [onSignUp] — fired when the user taps the "Sign up" CTA on
///     [QuotaDenialReason.anonDemo]. Typical impl: `context.push('/register')`.
///   - [onUpgrade] — fired when the user taps "Upgrade" on
///     [QuotaDenialReason.freeQuotaExhausted]. Typical impl:
///     `context.push('/subscription')`.
///   - rate limit has no CTA (it's transient — the user just waits).
SnackBar buildQuotaErrorSnackBar({
  required BuildContext context,
  required QuotaDenialReason reason,
  VoidCallback? onSignUp,
  VoidCallback? onUpgrade,
}) {
  final l10n = AppLocalizations.of(context);

  final String message;
  final String? ctaLabel;
  final VoidCallback? ctaCallback;
  final Color background;

  switch (reason) {
    case QuotaDenialReason.anonDemo:
      message = l10n?.demoLimitReached ??
          'Demo limit reached. Sign up for free to continue.';
      ctaLabel = l10n?.demoLimitSignUpCta ?? 'Sign up';
      ctaCallback = onSignUp;
      background = AppColors.primary;
      break;
    case QuotaDenialReason.freeQuotaExhausted:
      // Combine the two l10n keys so the user sees both lines in one
      // snackbar — "you've used all 10 / upgrade to Pro for unlimited".
      // Free-tier limit bumped 7 → 10 in Bentley P8 (2026-05-16); the
      // localised string ships with {count} so this fallback is the only
      // place a literal needs updating.
      final exhausted = l10n?.freeQuotaExhausted ??
          "You've used all 10 free messages this month.";
      final upgrade = l10n?.upgradeForUnlimited ?? 'Upgrade to Pro for unlimited';
      message = '$exhausted $upgrade';
      ctaLabel = l10n?.upgradeCta ?? 'Upgrade';
      ctaCallback = onUpgrade;
      background = AppColors.accent;
      break;
    case QuotaDenialReason.rateLimit:
      message = l10n?.rateLimitTryAgain ??
          'Sending too fast. Try again in a few seconds.';
      ctaLabel = null;
      ctaCallback = null;
      background = AppColors.warning;
      break;
  }

  // Build the content row: message + optional CTA button. We render the
  // CTA inline (rather than via SnackBarAction) so we can attach a stable
  // Key for widget tests, which SnackBarAction's API does not expose.
  final children = <Widget>[
    Expanded(
      child: Text(
        message,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    ),
  ];
  if (ctaLabel != null) {
    children.add(const SizedBox(width: 12));
    children.add(
      TextButton(
        key: const Key('quota_snackbar_cta'),
        onPressed: () {
          if (ctaCallback != null) ctaCallback();
        },
        style: TextButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: background,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          minimumSize: const Size(0, 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        child: Text(ctaLabel),
      ),
    );
  }

  return SnackBar(
    key: const Key('quota_error_snackbar'),
    content: Row(children: children),
    backgroundColor: background,
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 6),
  );
}
