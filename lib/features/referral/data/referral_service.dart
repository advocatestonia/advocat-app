// lib/features/referral/data/referral_service.dart
// -----------------------------------------------------------------------------
// Thin wrapper around the `referral` Supabase edge function.
//
// Three calls:
//   * fetchCode()       → POST /referral/code        — get/create the user's code
//   * attribute(code)   → POST /referral/attribute   — claim a code at signup
//   * fetchStats()      → POST /referral/stats       — invites/conversions/months
//
// All three short-circuit in demo mode with deterministic stub data so the
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
    );
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}

class ReferralServiceException implements Exception {
  const ReferralServiceException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => 'ReferralServiceException: $message';
}
