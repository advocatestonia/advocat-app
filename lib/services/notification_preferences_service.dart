// notification_preferences_service.dart
// -----------------------------------------------------------------------------
// Thin Supabase wrapper for the public.notification_preferences table.
//
// Backed by the 2026-05-14 retention infrastructure migration. Used by the
// Settings → Notifications screen to persist user opt-ins for:
//   * weekly digest
//   * winback emails
//   * deadline / insight / counterparty push
//   * an all-email kill switch (one-click unsubscribe target)
//
// Demo mode: when SupabaseService.isInitialized is false (no credentials),
// the service falls through to local in-memory defaults so the UI is
// usable from the demo home.
// -----------------------------------------------------------------------------

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final notificationPreferencesServiceProvider =
    Provider<NotificationPreferencesService>((ref) {
  return NotificationPreferencesService();
});

/// Returns the live SupabaseClient or null if the SDK was never initialised
/// (demo / offline). We probe lazily so the service can be constructed
/// without Supabase being up.
SupabaseClient? _safeClient() {
  try {
    return Supabase.instance.client;
  } catch (_) {
    return null;
  }
}

/// Persistent notification preferences for the signed-in user.
///
/// Defaults match the DB-side defaults in 20260514130000_retention_infra.sql:
/// everything opt-in for transactional, everything opt-in for push, marketing
/// (winback day-14 promo) ALSO opt-in at first — owner toggle to flip later.
class NotificationPreferences {
  const NotificationPreferences({
    this.emailDigestEnabled = true,
    this.emailWinbackEnabled = true,
    this.emailDeadlineEnabled = true,
    this.emailInsightsEnabled = true,
    this.pushEnabled = true,
    this.pushDeadlineEnabled = true,
    this.pushInsightsEnabled = true,
    this.pushCounterpartyEnabled = true,
    this.digestFrequency = 'weekly',
    this.digestDayOfWeek = 1,
    this.allEmailDisabled = false,
    this.fcmToken,
  });

  final bool emailDigestEnabled;
  final bool emailWinbackEnabled;
  final bool emailDeadlineEnabled;
  final bool emailInsightsEnabled;
  final bool pushEnabled;
  final bool pushDeadlineEnabled;
  final bool pushInsightsEnabled;
  final bool pushCounterpartyEnabled;
  final String digestFrequency; // 'weekly' | 'biweekly' | 'off'
  final int digestDayOfWeek; // 0=Sun .. 6=Sat
  final bool allEmailDisabled;
  final String? fcmToken;

  NotificationPreferences copyWith({
    bool? emailDigestEnabled,
    bool? emailWinbackEnabled,
    bool? emailDeadlineEnabled,
    bool? emailInsightsEnabled,
    bool? pushEnabled,
    bool? pushDeadlineEnabled,
    bool? pushInsightsEnabled,
    bool? pushCounterpartyEnabled,
    String? digestFrequency,
    int? digestDayOfWeek,
    bool? allEmailDisabled,
    String? fcmToken,
  }) {
    return NotificationPreferences(
      emailDigestEnabled: emailDigestEnabled ?? this.emailDigestEnabled,
      emailWinbackEnabled: emailWinbackEnabled ?? this.emailWinbackEnabled,
      emailDeadlineEnabled: emailDeadlineEnabled ?? this.emailDeadlineEnabled,
      emailInsightsEnabled: emailInsightsEnabled ?? this.emailInsightsEnabled,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      pushDeadlineEnabled: pushDeadlineEnabled ?? this.pushDeadlineEnabled,
      pushInsightsEnabled: pushInsightsEnabled ?? this.pushInsightsEnabled,
      pushCounterpartyEnabled:
          pushCounterpartyEnabled ?? this.pushCounterpartyEnabled,
      digestFrequency: digestFrequency ?? this.digestFrequency,
      digestDayOfWeek: digestDayOfWeek ?? this.digestDayOfWeek,
      allEmailDisabled: allEmailDisabled ?? this.allEmailDisabled,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  Map<String, dynamic> toJson() => {
        'email_digest_enabled': emailDigestEnabled,
        'email_winback_enabled': emailWinbackEnabled,
        'email_deadline_enabled': emailDeadlineEnabled,
        'email_insights_enabled': emailInsightsEnabled,
        'push_enabled': pushEnabled,
        'push_deadline_enabled': pushDeadlineEnabled,
        'push_insights_enabled': pushInsightsEnabled,
        'push_counterparty_enabled': pushCounterpartyEnabled,
        'digest_frequency': digestFrequency,
        'digest_day_of_week': digestDayOfWeek,
        'all_email_disabled': allEmailDisabled,
        if (fcmToken != null) 'fcm_token': fcmToken,
      };

  factory NotificationPreferences.fromJson(Map<String, dynamic> j) {
    return NotificationPreferences(
      emailDigestEnabled: j['email_digest_enabled'] as bool? ?? true,
      emailWinbackEnabled: j['email_winback_enabled'] as bool? ?? true,
      emailDeadlineEnabled: j['email_deadline_enabled'] as bool? ?? true,
      emailInsightsEnabled: j['email_insights_enabled'] as bool? ?? true,
      pushEnabled: j['push_enabled'] as bool? ?? true,
      pushDeadlineEnabled: j['push_deadline_enabled'] as bool? ?? true,
      pushInsightsEnabled: j['push_insights_enabled'] as bool? ?? true,
      pushCounterpartyEnabled:
          j['push_counterparty_enabled'] as bool? ?? true,
      digestFrequency: j['digest_frequency'] as String? ?? 'weekly',
      digestDayOfWeek: (j['digest_day_of_week'] as int?) ?? 1,
      allEmailDisabled: j['all_email_disabled'] as bool? ?? false,
      fcmToken: j['fcm_token'] as String?,
    );
  }
}

class NotificationPreferencesService {
  NotificationPreferencesService();

  SupabaseClient? get _client => _safeClient();

  /// Load preferences for the signed-in user. Creates a default row on
  /// first read so the DB always has a backing record (enables the
  /// unsubscribe-token link to be generated lazily).
  Future<NotificationPreferences> load() async {
    final client = _client;
    if (client == null) return const NotificationPreferences();
    final uid = client.auth.currentUser?.id;
    if (uid == null) return const NotificationPreferences();
    try {
      final row = await client
          .from('notification_preferences')
          .select()
          .eq('user_id', uid)
          .maybeSingle();
      if (row == null) {
        await client.from('notification_preferences').insert({'user_id': uid});
        return const NotificationPreferences();
      }
      return NotificationPreferences.fromJson(Map<String, dynamic>.from(row));
    } catch (_) {
      // Table may not exist yet in older deployments — return defaults.
      return const NotificationPreferences();
    }
  }

  /// Upsert the entire preferences row. Used when the user toggles a
  /// single switch — we send the full row so concurrent edits from a
  /// second device don't clobber each other.
  Future<bool> save(NotificationPreferences prefs) async {
    final client = _client;
    if (client == null) return true;
    final uid = client.auth.currentUser?.id;
    if (uid == null) return false;
    try {
      await client.from('notification_preferences').upsert({
        'user_id': uid,
        ...prefs.toJson(),
      });
      return true;
    } catch (e) {
      // Schema cache miss after migration: surface a non-throwing false
      // so the UI can revert the toggle.
      return false;
    }
  }

  /// Update the user's FCM token. Called from notification_service.dart
  /// when firebase_messaging produces a new token (lifecycle: install,
  /// re-install, token rotation).
  Future<void> updateFcmToken(String token) async {
    final client = _client;
    if (client == null) return;
    final uid = client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await client.from('notification_preferences').upsert({
        'user_id': uid,
        'fcm_token': token,
        'fcm_token_updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {
      // Best-effort; an offline write means the user will get push
      // on next sync.
    }
  }

  /// One-click unsubscribe stub (anchors a future deep-link target).
  /// The real unsubscribe is triggered by the emailed link calling the
  /// public.unsubscribe_by_token RPC; this helper is for in-app use.
  Future<bool> disableAllEmail() async {
    final current = await load();
    return save(current.copyWith(allEmailDisabled: true));
  }
}
