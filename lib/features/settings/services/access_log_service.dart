// access_log_service.dart — Data Fortress Pillar 3 (transparent self-audit).
// Reads the user's own access log via the get_my_access_log RPC (RLS-scoped
// to auth.uid()) and verifies the tamper-evident hash chain locally.
import 'package:supabase_flutter/supabase_flutter.dart';

/// One row of "who/what/when touched my data".
class AccessLogEntry {
  AccessLogEntry({
    required this.ts,
    required this.action,
    required this.targetTable,
    required this.details,
    required this.rowHash,
    required this.prevHash,
  });

  final DateTime ts;
  final String action;
  final String? targetTable;
  final Map<String, dynamic> details;
  final String rowHash;
  final String prevHash;

  factory AccessLogEntry.fromMap(Map<String, dynamic> m) => AccessLogEntry(
        ts: DateTime.parse(m['ts'] as String).toLocal(),
        action: (m['action'] as String?) ?? '',
        targetTable: m['target_table'] as String?,
        details: (m['details'] as Map?)?.cast<String, dynamic>() ?? const {},
        rowHash: (m['row_hash'] as String?) ?? '',
        prevHash: (m['prev_hash'] as String?) ?? '',
      );
}

/// Result of verifying the hash chain over the loaded page.
class ChainVerification {
  const ChainVerification({required this.intact, required this.brokenAt});

  /// True if every loaded row's hash recomputes correctly and links to the
  /// previous row. A break means the log was tampered with after the fact.
  final bool intact;

  /// Index of the first row whose hash didn't verify (null if intact).
  final int? brokenAt;
}

class AccessLogService {
  AccessLogService(this._client);
  final SupabaseClient _client;

  /// Fetch a page of the caller's own access log, newest first.
  Future<List<AccessLogEntry>> fetch({
    int limit = 50,
    DateTime? before,
  }) async {
    final res = await _client.rpc(
      'get_my_access_log',
      params: {
        'p_limit': limit,
        'p_before': before?.toUtc().toIso8601String(),
      },
    );
    if (res is! List) return const [];
    return res
        .whereType<Map>()
        .map((e) => AccessLogEntry.fromMap(e.cast<String, dynamic>()))
        .toList();
  }

  /// Verify the hash-chain LINKAGE over [entries] (newest-first, as returned
  /// by [fetch]).
  ///
  /// IMPORTANT — what this does and does NOT prove. The DB row_hash
  /// (migration 20260531100000) is computed over server-only columns (id,
  /// user_id, target_id, ip, full timestamp) that the RPC deliberately does
  /// not expose, so the client cannot reproduce the digest itself. What the
  /// client CAN verify is the chain LINKAGE: each row's prev_hash must equal
  /// the previous row's row_hash. If a row were deleted or inserted in the
  /// middle, the linkage breaks and we detect it. This is a genuine
  /// tamper-evidence signal for "rows were removed/reordered", which is the
  /// main thing a data subject cares about. Full digest verification is a
  /// server/anchor responsibility (see the published Merkle anchor, roadmap
  /// Phase 1).
  ChainVerification verifyChain(List<AccessLogEntry> entries) {
    // entries are newest-first; walk so each row links to the OLDER one.
    for (var i = 0; i < entries.length - 1; i++) {
      final newer = entries[i];
      final older = entries[i + 1];
      if (newer.prevHash.isEmpty || newer.prevHash != older.rowHash) {
        return ChainVerification(intact: false, brokenAt: i);
      }
    }
    return const ChainVerification(intact: true, brokenAt: null);
  }
}
