// lib/features/referral/referral_nudge.dart
// -----------------------------------------------------------------------------
// Cross-feature helper for the post-first-conversation referral nudge.
//
// Used by:
//   * The chat screen — calls [markFirstChatTimestamp] on the user's first
//     successful AI turn. Idempotent; only the very first call writes
//     anything.
//   * HomeScreen `_maybeShowReferralNudge` — reads the timestamp and
//     decides whether to show the snackbar.
//   * Tests — exercise the gating logic without spinning up a full app.
//
// Three keys live in SharedPreferences:
//   first_chat_at         ISO-8601 UTC timestamp of the first chat turn.
//                         Set ONCE; subsequent calls are no-ops.
//   referral_seen         true once the user has opened /referral.
//   referral_nudge_shown  true once the post-chat snackbar has fired.
//
// Keeping the keys in one module makes the lifecycle auditable without
// having to grep four screens.
// -----------------------------------------------------------------------------

import 'package:shared_preferences/shared_preferences.dart';

/// ISO-8601 timestamp of the first AI conversation. Written once, never
/// rewritten.
const String kFirstChatAtPrefKey = 'first_chat_at';

/// Flipped to `true` when the user opens the Referral screen for the
/// first time.
const String kReferralSeenPrefKey = 'referral_seen';

/// Flipped to `true` after the snackbar nudge fires. Prevents repeat
/// impressions on subsequent app launches.
const String kReferralNudgeShownPrefKey = 'referral_nudge_shown';

/// Records "now" as the user's first chat. Safe to call on every chat
/// send — only the first call has any effect.
Future<void> markFirstChatTimestamp({SharedPreferences? prefs}) async {
  try {
    final store = prefs ?? await SharedPreferences.getInstance();
    if (store.getString(kFirstChatAtPrefKey) != null) return;
    await store.setString(
      kFirstChatAtPrefKey,
      DateTime.now().toUtc().toIso8601String(),
    );
  } catch (_) {
    // Best-effort — failure here only loses the nudge, not any user data.
  }
}

/// Pure decision function. Given the timestamps that surround the nudge,
/// should we show it now? Exposed for unit tests so we don't have to
/// pump a full HomeScreen to exercise the gates.
///
/// All inputs are optional so the caller can express "I don't know this
/// signal yet" — anything unknown short-circuits to `false`.
bool shouldShowReferralNudge({
  required DateTime now,
  DateTime? accountCreatedAt,
  DateTime? firstChatAt,
  bool referralSeen = false,
  bool nudgeAlreadyShown = false,
}) {
  if (referralSeen) return false;
  if (nudgeAlreadyShown) return false;
  if (firstChatAt == null) return false;
  // Anti-cheap-share: account must be > 24h old. Fall back to the
  // first-chat timestamp when the account creation date is unknown
  // (e.g. demo profile).
  final reference = accountCreatedAt ?? firstChatAt;
  if (now.difference(reference).inHours < 24) return false;
  return true;
}
