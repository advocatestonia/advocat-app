// lib/features/referral/data/referral_service.dart
// -----------------------------------------------------------------------------
// Thin wrapper around the `referral` Supabase edge function.
//
// Four calls:
//   * fetchCode()           → POST /referral/code        — get/create the
//                             user's code.
//   * attribute(code)       → POST /referral/attribute   — claim a code at
//                             signup.
//   * fetchStats()          → POST /referral/stats       — invites /
//                             conversions / months / recent activity.
//   * lookupCode(code)      → GET  /referral/lookup?code=…
//                             Anon-readable preview of who is inviting (so
//                             the /r/<code> landing can greet "Sind kutsus
//                             Anna"). Backend MAY return 404 if the link is
//                             dead — UI treats that as the fallback state.
//
// All four short-circuit in demo mode with deterministic stub data so the
// UI flow can be exercised offline.
// -----------------------------------------------------------------------------

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/referral_stats.dart';

/// Result of [ReferralService.attribute].
sealed class AttributeResult {
  const AttributeResult();
}

final class AttributeOk extends AttributeResult {
  const AttributeOk({
    required this.attributionId,
    required this.status,
    required this.alreadyAttributed,
  });
  final String attributionId;
  final String status;
  final bool alreadyAttributed;
}

final class AttributeFailure extends AttributeResult {
  const AttributeFailure({required this.error, this.statusCode});
  final String error;
  final int? statusCode;
}

/// Result of [ReferralService.lookupCode] — what the /r/<code> landing
/// shows before the visitor signs up. The inviter's first name is purely
/// social proof; the backend MUST NOT leak email/last name/uid.
sealed class CodeLookupResult {
  const CodeLookupResult();
}

final class CodeLookupOk extends CodeLookupResult {
  const CodeLookupOk({required this.inviterFirstName});

  /// May be null if the inviter hasn't set a name yet. UI falls back to
  /// generic copy ("You've been invited to Advocat") in that case.
  final String? inviterFirstName;
}

final class CodeLookupInvalid extends CodeLookupResult {
  const CodeLookupInvalid();
}

/// Riverpod handle.
final referralServiceProvider = Provider<ReferralService>((ref) {
  return ReferralService();
});

class ReferralService {
  ReferralService({SupabaseClient? client}) : _client = client;
  final SupabaseClient? _client;

  static const String _functionName = 'referral';

  SupabaseClient? get _safeClient {
    if (_client != null) return _client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  bool get _isDemo => _safeClient == null;

  String _demoCode() {
    final uid = _safeClient?.auth.currentUser?.id ?? 'demouser';
    // Stable 8-char code per user so the share screen looks real offline.
    // Pad short ids so substring(0,8) is always safe.
    final cleaned = uid.replaceAll('-', '').padRight(8, '0');
    return cleaned.substring(0, 8).toLowerCase();
  }

  /// Returns the user's code (creates it server-side on first call).
  Future<String> fetchCode() async {
    if (_isDemo) return _demoCode();
    final client = _safeClient!;
    final res = await client.functions.invoke(
      '$_functionName/code',
      body: <String, dynamic>{},
    );
    if (res.status < 200 || res.status >= 300) {
      throw ReferralServiceException(
        'fetchCode failed: ${res.status}',
        statusCode: res.status,
      );
    }
    final data = res.data;
    if (data is Map && data['code'] is String) {
      return data['code'] as String;
    }
    throw const ReferralServiceException('fetchCode: malformed response');
  }

  /// Claims [code] on behalf of the authenticated user. Called once per
  /// new account, after auth. Idempotent server-side.
  Future<AttributeResult> attribute(String code) async {
    final cleaned = code.trim().toLowerCase();
    if (cleaned.isEmpty) {
      return const AttributeFailure(error: 'missing_referral_code');
    }
    if (_isDemo) {
      return const AttributeOk(
        attributionId: 'demo-attrib',
        status: 'attributed',
        alreadyAttributed: false,
      );
    }
    final client = _safeClient!;
    final res = await client.functions.invoke(
      '$_functionName/attribute',
      body: <String, dynamic>{'referral_code': cleaned},
    );
    final data = res.data;
    if (res.status >= 200 && res.status < 300) {
      if (data is Map) {
        return AttributeOk(
          attributionId: (data['attribution_id'] ?? '').toString(),
          status: (data['status'] ?? 'attributed').toString(),
          alreadyAttributed: data['already_attributed'] == true,
        );
      }
      return const AttributeOk(
        attributionId: '',
        status: 'attributed',
        alreadyAttributed: false,
      );
    }
    final errKey = (data is Map ? data['error']?.toString() : null) ??
        'unknown_error';
    return AttributeFailure(error: errKey, statusCode: res.status);
  }

  /// Aggregate stats for the inviter screen.
  Future<ReferralStats> fetchStats() async {
    if (_isDemo) {
      return ReferralStats(
        code: _demoCode(),
        shareUrl: 'https://advocat.ee/r/${_demoCode()}',
        invitesSent: 0,
        conversions: 0,
        freeMonthsEarned: 0,
        recentActivity: const <ReferralActivity>[],
      );
    }
    final client = _safeClient!;
    final res = await client.functions.invoke(
      '$_functionName/stats',
      body: <String, dynamic>{},
    );
    if (res.status < 200 || res.status >= 300) {
      throw ReferralServiceException(
        'fetchStats failed: ${res.status}',
        statusCode: res.status,
      );
    }
    final data = res.data;
    if (data is! Map) {
      throw const ReferralServiceException('fetchStats: malformed response');
    }
    return ReferralStats(
      code: (data['code'] ?? '').toString(),
      shareUrl: (data['share_url'] ?? '').toString(),
      invitesSent: _toInt(data['invites_sent']),
      conversions: _toInt(data['conversions']),
      freeMonthsEarned: _toInt(data['free_months_earned']),
      recentActivity: _parseActivity(data['recent_activity']),
    );
  }

  /// Anon-readable preview of a referral code's inviter. Used by the
  /// `/r/<code>` landing to greet the visitor. Returns
  /// [CodeLookupInvalid] for unknown codes (404) — the UI shows the
  /// fallback "link expired" copy in that case.
  Future<CodeLookupResult> lookupCode(String code) async {
    final cleaned = code.trim().toLowerCase();
    if (cleaned.isEmpty) return const CodeLookupInvalid();
    if (_isDemo) {
      // Stable demo result keyed on the code so screenshots are
      // reproducible offline.
      return const CodeLookupOk(inviterFirstName: 'Anna');
    }
    final client = _safeClient!;
    try {
      final res = await client.functions.invoke(
        '$_functionName/lookup',
        body: <String, dynamic>{'code': cleaned},
      );
      if (res.status == 404) return const CodeLookupInvalid();
      if (res.status < 200 || res.status >= 300) {
        return const CodeLookupInvalid();
      }
      final data = res.data;
      if (data is Map) {
        final rawName = data['inviter_first_name'];
        final name = rawName is String && rawName.trim().isNotEmpty
            ? rawName.trim()
            : null;
        return CodeLookupOk(inviterFirstName: name);
      }
      return const CodeLookupOk(inviterFirstName: null);
    } catch (_) {
      // Network / edge fn 5xx → degrade gracefully to the generic copy.
      return const CodeLookupOk(inviterFirstName: null);
    }
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static List<ReferralActivity> _parseActivity(dynamic raw) {
    if (raw is! List) return const <ReferralActivity>[];
    final out = <ReferralActivity>[];
    for (final item in raw) {
      final row = ReferralActivity.fromJson(item);
      if (row != null) out.add(row);
    }
    return out;
  }
}

class ReferralServiceException implements Exception {
  const ReferralServiceException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => 'ReferralServiceException: $message';
}
