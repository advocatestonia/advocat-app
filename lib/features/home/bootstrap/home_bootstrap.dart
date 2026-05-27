// lib/features/home/bootstrap/home_bootstrap.dart
// -----------------------------------------------------------------------------
// Home-screen modal priority queue + cool-down policy.
//
// Why this file exists
// --------------------
// Before 2026-05-27, HomeScreen.initState chained six fire-and-forget modal
// triggers (welcome, B2B, referral, GDPR, checkout, onboarding). Cold-start
// stacked 3+ surfaces on top of each other within ~2s — UX disaster.
//
// This module centralises:
//
//   1. The fixed priority order (compliance first, opportunistic last).
//   2. The cool-down constants (so one place audits "how often can we
//      pester the user?").
//   3. Pure decision predicates (`shouldShow*`) that read SharedPreferences
//      and return bool — testable without pumping the widget tree.
//
// HomeScreen itself owns the UI side: it awaits each predicate in order and
// shows ONE modal at a time. Subsequent items in the queue only run after
// the previous modal has been dismissed.
//
// Priority order (top = first):
//
//   1. GDPR consent          — BLOCKING. Legal requirement (Art 7 GDPR).
//                              Shown once per major app version.
//   2. Pending checkout      — User just paid. Activate Pro / poll webhook.
//   3. Welcome (first-time)  — Onboarding for brand-new users. Once per
//                              user lifetime.
//   4. B2B silent-signal     — Opportunistic upgrade nudge. Max 1× / 7 days,
//                              AND only if backend flag `b2b_modal_pending`
//                              is true.
//   5. Referral nudge        — NOT triggered from home initState anymore.
//                              Chat screen calls `markReferralEligible` after
//                              first successful AI turn; on subsequent home
//                              visits the snackbar fires (max 1× / 14 days).
//
// Onboarding bootstrap (no UI) is fire-and-forget by design — it does not
// participate in the queue.
// -----------------------------------------------------------------------------

import 'package:shared_preferences/shared_preferences.dart';

import '../../referral/referral_nudge.dart';

// ─── Cool-down storage keys ─────────────────────────────────────────────────
//
// Each timestamp is stored as ISO-8601 UTC. `null`/missing means "never
// shown". We keep keys plural-namespaced under `advocat_bootstrap_` so a
// `prefs.getKeys()` listing in DevTools makes the bootstrap surface
// auditable at a glance.

/// Major-app-version (e.g. "1") under which the user most recently accepted
/// GDPR consent. If the app's major version increments, consent is
/// re-prompted (terms may have changed).
const String kBootstrapGdprMajorVersionKey =
    'advocat_bootstrap_gdpr_major_version_v1';

/// ISO-8601 timestamp of the most recent B2B modal impression. Used to
/// enforce a 7-day cool-down even when the backend `b2b_modal_pending` flag
/// flaps back to true (rare but possible during a manual operator override).
const String kBootstrapB2bLastShownKey =
    'advocat_bootstrap_b2b_last_shown_v1';

/// ISO-8601 timestamp of the most recent referral snackbar nudge. Backstops
/// the existing `kReferralNudgeShownPrefKey` boolean — we keep both so a
/// future "show again after 14 days" can read this timestamp.
const String kBootstrapReferralLastShownKey =
    'advocat_bootstrap_referral_last_shown_v1';

// ─── Cool-down windows ──────────────────────────────────────────────────────

/// B2B modal: even if the backend re-flags pending=true, don't show again
/// for 7 days after the last impression. Prevents bursty re-triggering when
/// an operator manually toggles `profiles.b2b_modal_pending`.
const Duration kB2bCooldown = Duration(days: 7);

/// Referral snackbar: minimum gap between impressions. Combined with the
/// existing `referral_nudge_shown` boolean this is effectively "once",
/// but we keep the duration as a forward-compatible knob.
const Duration kReferralCooldown = Duration(days: 14);

// ─── Pure decision predicates ───────────────────────────────────────────────
//
// All predicates take an optional `now` so tests can pin time without
// reaching for fake clocks. Production callers pass `DateTime.now().toUtc()`.

/// True if the GDPR consent dialog needs to be shown for the running
/// app's major version.
///
/// Compliance NOTE: this predicate ONLY controls whether the LOCAL major-
/// version cool-down has expired. The caller MUST still check the
/// authoritative server-side consent timestamp (Supabase `profiles.
/// gdpr_consent_at`) via `hasGdprConsent()` before deciding to prompt.
/// In practice the home-screen flow does both: server check first, then
/// this version check.
Future<bool> shouldShowGdprConsentForMajorVersion({
  required String currentMajorVersion,
  SharedPreferences? prefs,
}) async {
  try {
    final store = prefs ?? await SharedPreferences.getInstance();
    final lastAccepted = store.getString(kBootstrapGdprMajorVersionKey);
    if (lastAccepted == null) return true;
    return lastAccepted != currentMajorVersion;
  } catch (_) {
    // On storage failure, err on the side of showing — GDPR is blocking
    // and the worst case is one extra prompt, never silent suppression.
    return true;
  }
}

/// Record that the user accepted GDPR for the given major version.
/// Called by the caller after `showGdprConsentDialog` returns true.
Future<void> markGdprAcceptedForMajorVersion({
  required String currentMajorVersion,
  SharedPreferences? prefs,
}) async {
  try {
    final store = prefs ?? await SharedPreferences.getInstance();
    await store.setString(kBootstrapGdprMajorVersionKey, currentMajorVersion);
  } catch (_) {
    // Best-effort; the server-side `profiles.gdpr_consent_at` is the
    // authoritative record.
  }
}

/// True if the B2B silent-signal modal is allowed to show right now, based
/// purely on the local cool-down. The caller is still responsible for
/// gating on `profiles.b2b_modal_pending` (the server-side signal) and on
/// non-demo mode.
Future<bool> shouldShowB2bModal({
  DateTime? now,
  SharedPreferences? prefs,
}) async {
  try {
    final store = prefs ?? await SharedPreferences.getInstance();
    final raw = store.getString(kBootstrapB2bLastShownKey);
    if (raw == null) return true;
    final last = DateTime.tryParse(raw);
    if (last == null) return true;
    final n = now ?? DateTime.now().toUtc();
    return n.difference(last) >= kB2bCooldown;
  } catch (_) {
    // Storage failure — fall through to "allow once"; the server-side flag
    // and the in-memory `triggeredThisSession` guard will still prevent
    // hammering.
    return true;
  }
}

/// Record a B2B modal impression. Called by the caller after the modal is
/// rendered (regardless of which action the user picked — we don't
/// re-pester).
Future<void> markB2bModalShown({
  DateTime? now,
  SharedPreferences? prefs,
}) async {
  try {
    final store = prefs ?? await SharedPreferences.getInstance();
    final n = now ?? DateTime.now().toUtc();
    await store.setString(kBootstrapB2bLastShownKey, n.toIso8601String());
  } catch (_) {
    // Best-effort.
  }
}

/// True if the referral snackbar nudge is allowed to fire, based on the
/// 14-day cool-down AND the existing one-shot boolean. The caller still has
/// to check that `first_chat_at` is set and the account is > 24h old (that
/// logic lives in `shouldShowReferralNudge` in referral_nudge.dart).
Future<bool> withinReferralCooldown({
  DateTime? now,
  SharedPreferences? prefs,
}) async {
  try {
    final store = prefs ?? await SharedPreferences.getInstance();
    // Hard kill-switches: the existing boolean keys.
    if (store.getBool(kReferralNudgeShownPrefKey) ?? false) {
      // Already nudged once — fall through to the 14-day check so we can
      // re-enable in the future without breaking the existing one-shot
      // behaviour.
      final raw = store.getString(kBootstrapReferralLastShownKey);
      if (raw == null) {
        // Boolean was flipped before this key existed — treat as "shown
        // forever ago" but still suppress until the boolean is cleared.
        return false;
      }
      final last = DateTime.tryParse(raw);
      if (last == null) return false;
      final n = now ?? DateTime.now().toUtc();
      return n.difference(last) >= kReferralCooldown;
    }
    if (store.getBool(kReferralSeenPrefKey) ?? false) return false;
    return true;
  } catch (_) {
    return false;
  }
}

/// Record a referral snackbar impression. Writes both the legacy boolean
/// (for back-compat with `_maybeShowReferralNudge` callers) and the new
/// timestamp.
Future<void> markReferralNudgeShown({
  DateTime? now,
  SharedPreferences? prefs,
}) async {
  try {
    final store = prefs ?? await SharedPreferences.getInstance();
    final n = now ?? DateTime.now().toUtc();
    await store.setBool(kReferralNudgeShownPrefKey, true);
    await store.setString(
      kBootstrapReferralLastShownKey,
      n.toIso8601String(),
    );
  } catch (_) {
    // Best-effort.
  }
}

// ─── Priority enumeration ───────────────────────────────────────────────────

/// Identifies a modal in the bootstrap queue. Exposed so tests can assert
/// "which modal was offered first" without having to inspect widget output.
enum BootstrapModal {
  /// Legal-blocking GDPR consent dialog.
  gdpr,

  /// Stripe checkout return / Pro activation spinner.
  pendingCheckout,

  /// First-time welcome / onboarding modal.
  welcome,

  /// Opportunistic B2B upgrade nudge.
  b2b,

  /// Post-first-chat referral snackbar.
  /// NOT shown from home initState — surfaced here only so test fixtures
  /// can reason about the full ordering.
  referral,
}

/// Canonical priority order. Index 0 = shown first.
const List<BootstrapModal> kBootstrapPriorityOrder = <BootstrapModal>[
  BootstrapModal.gdpr,
  BootstrapModal.pendingCheckout,
  BootstrapModal.welcome,
  BootstrapModal.b2b,
  BootstrapModal.referral,
];
