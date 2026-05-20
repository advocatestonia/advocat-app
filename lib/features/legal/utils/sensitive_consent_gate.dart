// =====================================================================
// GDPR Art. 9(2)(a) — explicit-consent gate for special-category data.
//
// Used by every upload trigger (document scan, vault add, intake wizard
// step 5) to ensure the user has an ACTIVE row in
// `public.sensitive_consents` BEFORE any file leaves their device.
//
// Fast path (no UI): if a row with `withdrawn_at IS NULL` already exists
// for the current user, this returns `true` immediately.
// Slow path: shows `SensitiveDataConsentDialog`. On accept we insert a
// new row and return `true`. On cancel / barrier-dismiss we return
// `false` and the caller MUST abort the upload.
//
// Idempotency: even if two upload triggers fire concurrently and both
// open a dialog, the row insert is gated by the active-consent index
// — the second insert can simply succeed (acceptable: we want a fresh
// audit row per session if any) or be coalesced. We do NOT collapse on
// unique-violation here because (user_id) is not unique; this is by
// design — multiple consent rows across sessions form the audit trail.
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/theme.dart';
import '../screens/sensitive_data_consent_screen.dart';

/// Current consent text version. Bump when wording in the dialog changes
/// — a bump forces re-consent (the gate ignores rows with stale versions).
const String kCurrentSensitiveConsentVersion = 'v1.0-2026-05-20';

/// Returns `true` if the user has (or just granted) explicit consent to
/// process special-category personal data under GDPR Art. 9(2)(a).
/// Returns `false` if the user cancels the dialog, is not authenticated,
/// or the insert fails — callers MUST NOT proceed with the upload in
/// any of those cases.
///
/// The `ref` parameter is accepted for forward-compat with Riverpod-based
/// telemetry but is currently unused; kept in signature to match the
/// project's gate utility convention (e.g. `ensureDpaAccepted`).
Future<bool> ensureSensitiveConsent(
  BuildContext context,
  WidgetRef ref,
) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  if (user == null) {
    // No authed user — silently fail closed. Upstream auth guards
    // should prevent ever reaching an upload entry-point in this state.
    return false;
  }

  // 1. Fast path: active consent at current version already on record.
  try {
    final existing = await supabase
        .from('sensitive_consents')
        .select('id')
        .eq('user_id', user.id)
        .eq('consent_version', kCurrentSensitiveConsentVersion)
        .filter('withdrawn_at', 'is', null)
        .limit(1)
        .maybeSingle();
    if (existing != null) return true;
  } catch (_) {
    // RLS / transient error — fall through to dialog so the user has
    // another chance to grant consent rather than hard-failing.
  }

  if (!context.mounted) return false;

  // 2. Show the mandatory consent dialog.
  final accepted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const SensitiveDataConsentDialog(),
  );
  if (accepted != true) return false;

  // 3. Persist the consent row BEFORE returning. If the insert fails,
  //    treat the gate as not passed — we will not let an upload proceed
  //    without a recorded lawful basis.
  try {
    await supabase.from('sensitive_consents').insert({
      'user_id': user.id,
      'consent_version': kCurrentSensitiveConsentVersion,
      // ip_address + user_agent intentionally left to server-side fill
      // if/when we add an edge fn audit wrapper. RLS does not allow
      // either to be set from the client anyway (no policy elevation).
    });
    return true;
  } on PostgrestException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not record sensitive-data consent: ${e.message}',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
    return false;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not record sensitive-data consent: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
    return false;
  }
}

/// Withdraws the user's currently-active consent by stamping
/// `withdrawn_at = now()` on every active row. Returns the number of
/// rows updated (0 if there was no active consent).
///
/// Per owner default (2026-05-20), withdrawal does NOT cascade-delete
/// previously uploaded documents — it only blocks future uploads from
/// triggering Art. 9 processing. The owner explicitly confirms before
/// any destructive purge is wired up.
Future<int> withdrawSensitiveConsent() async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  if (user == null) return 0;

  final rows = await supabase
      .from('sensitive_consents')
      .update({'withdrawn_at': DateTime.now().toUtc().toIso8601String()})
      .eq('user_id', user.id)
      .filter('withdrawn_at', 'is', null)
      .select('id');
  return (rows as List).length;
}

/// Fetches the single active consent row (if any) for the current user.
/// Used by the Settings "manage / withdraw" screen.
Future<Map<String, dynamic>?> fetchActiveSensitiveConsent() async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  if (user == null) return null;

  return supabase
      .from('sensitive_consents')
      .select('id, consent_version, granted_at, categories, legal_basis')
      .eq('user_id', user.id)
      .filter('withdrawn_at', 'is', null)
      .order('granted_at', ascending: false)
      .limit(1)
      .maybeSingle();
}
