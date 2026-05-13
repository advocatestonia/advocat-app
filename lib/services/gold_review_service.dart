// gold_review_service.dart — Flutter client for the Sofia Gold Corpus
// review edge function.
// -----------------------------------------------------------------------------
// Talks to /functions/v1/gold-review. The current user's JWT is passed via
// Supabase.instance.client.functions.invoke; the edge function verifies the
// user_id is in GOLD_REVIEWER_IDS before allowing reads/writes.
// -----------------------------------------------------------------------------

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final goldReviewServiceProvider = Provider<GoldReviewService>((ref) {
  return GoldReviewService();
});

/// One pending queue row, as returned by `GET /gold-review/queue`.
class GoldQueueItem {
  GoldQueueItem({
    required this.id,
    required this.createdAt,
    required this.userQuestion,
    required this.aiAnswer,
    this.aiModel,
    this.aiCitations,
    this.language,
    this.category,
    this.jurisdiction,
  });

  final String id;
  final DateTime createdAt;
  final String userQuestion;
  final String aiAnswer;
  final String? aiModel;
  final List<String>? aiCitations;
  final String? language;
  final String? category;
  final String? jurisdiction;

  factory GoldQueueItem.fromJson(Map<String, dynamic> json) {
    DateTime parsed;
    try {
      parsed = DateTime.parse(json['created_at'] as String);
    } catch (_) {
      parsed = DateTime.now();
    }
    final cits = (json['ai_citations'] as List?)
        ?.map((e) => e.toString())
        .toList();
    return GoldQueueItem(
      id: json['id'] as String,
      createdAt: parsed,
      userQuestion: (json['user_question'] as String?) ?? '',
      aiAnswer: (json['ai_answer'] as String?) ?? '',
      aiModel: json['ai_model'] as String?,
      aiCitations: cits,
      language: json['language'] as String?,
      category: json['category'] as String?,
      jurisdiction: json['jurisdiction'] as String?,
    );
  }
}

/// Aggregated stats from the `gold_corpus_stats` view.
class GoldCorpusStats {
  GoldCorpusStats({
    required this.totalApproved,
    required this.totalEdited,
    required this.totalRejected,
    required this.totalSkipped,
    required this.reviewedToday,
    required this.reviewedThisWeek,
    required this.reviewedThisMonth,
    required this.pendingReview,
    required this.pendingScrub,
    this.avgEditSimilarity,
  });

  final int totalApproved;
  final int totalEdited;
  final int totalRejected;
  final int totalSkipped;
  final int reviewedToday;
  final int reviewedThisWeek;
  final int reviewedThisMonth;
  final int pendingReview;
  final int pendingScrub;
  final double? avgEditSimilarity;

  factory GoldCorpusStats.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    double? asDouble(dynamic v) {
      if (v == null) return null;
      if (v is double) return v;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    return GoldCorpusStats(
      totalApproved: asInt(json['total_approved']),
      totalEdited: asInt(json['total_edited']),
      totalRejected: asInt(json['total_rejected']),
      totalSkipped: asInt(json['total_skipped']),
      reviewedToday: asInt(json['reviewed_today']),
      reviewedThisWeek: asInt(json['reviewed_this_week']),
      reviewedThisMonth: asInt(json['reviewed_this_month']),
      pendingReview: asInt(json['pending_review']),
      pendingScrub: asInt(json['pending_scrub']),
      avgEditSimilarity: asDouble(json['avg_edit_similarity']),
    );
  }

  static GoldCorpusStats empty() => GoldCorpusStats(
        totalApproved: 0,
        totalEdited: 0,
        totalRejected: 0,
        totalSkipped: 0,
        reviewedToday: 0,
        reviewedThisWeek: 0,
        reviewedThisMonth: 0,
        pendingReview: 0,
        pendingScrub: 0,
      );
}

/// Result of a decide call. `pairId` is null on skip.
class GoldDecideResult {
  GoldDecideResult({
    required this.ok,
    required this.status,
    this.pairId,
    this.editSimilarity,
    this.error,
  });

  final bool ok;
  final String status;
  final String? pairId;
  final double? editSimilarity;
  final String? error;
}

enum GoldDecisionStatus { approved, edited, rejected, skipped }

extension GoldDecisionStatusX on GoldDecisionStatus {
  String get wire {
    switch (this) {
      case GoldDecisionStatus.approved:
        return 'approved';
      case GoldDecisionStatus.edited:
        return 'edited';
      case GoldDecisionStatus.rejected:
        return 'rejected';
      case GoldDecisionStatus.skipped:
        return 'skipped';
    }
  }
}

class GoldReviewService {
  GoldReviewService({SupabaseClient? client}) : _override = client;

  final SupabaseClient? _override;

  SupabaseClient get _client => _override ?? Supabase.instance.client;

  Future<List<GoldQueueItem>> listQueue({
    int limit = 20,
    int offset = 0,
    String? language,
    String? category,
    String? jurisdiction,
  }) async {
    final query = <String, String>{
      'limit': '$limit',
      'offset': '$offset',
    };
    if (language != null && language.isNotEmpty) query['language'] = language;
    if (category != null && category.isNotEmpty) query['category'] = category;
    if (jurisdiction != null && jurisdiction.isNotEmpty) {
      query['jurisdiction'] = jurisdiction;
    }
    final res = await _client.functions.invoke(
      'gold-review/queue',
      method: HttpMethod.get,
      queryParameters: query,
    );
    if (res.status < 200 || res.status >= 300) {
      throw GoldReviewException(
        'queue HTTP ${res.status}',
        _extractError(res.data),
      );
    }
    final data = res.data;
    if (data is! Map || data['rows'] is! List) {
      throw GoldReviewException('queue malformed response', null);
    }
    return (data['rows'] as List)
        .whereType<Map>()
        .map((m) => GoldQueueItem.fromJson(Map<String, dynamic>.from(m)))
        .toList(growable: false);
  }

  Future<GoldCorpusStats> fetchStats() async {
    final res = await _client.functions.invoke(
      'gold-review/stats',
      method: HttpMethod.get,
    );
    if (res.status < 200 || res.status >= 300) {
      throw GoldReviewException(
        'stats HTTP ${res.status}',
        _extractError(res.data),
      );
    }
    final data = res.data;
    if (data is! Map || data['stats'] is! Map) {
      return GoldCorpusStats.empty();
    }
    return GoldCorpusStats.fromJson(
      Map<String, dynamic>.from(data['stats'] as Map),
    );
  }

  Future<GoldDecideResult> decide({
    required String queueId,
    required GoldDecisionStatus status,
    String? goldAnswer,
    String? rejectionReason,
    String? reviewerNotes,
  }) async {
    final payload = <String, dynamic>{
      'queue_id': queueId,
      'status': status.wire,
    };
    if (goldAnswer != null) payload['gold_answer'] = goldAnswer;
    if (rejectionReason != null) payload['rejection_reason'] = rejectionReason;
    if (reviewerNotes != null) payload['reviewer_notes'] = reviewerNotes;

    final res = await _client.functions.invoke(
      'gold-review/decide',
      body: payload,
    );
    if (res.status < 200 || res.status >= 300) {
      return GoldDecideResult(
        ok: false,
        status: status.wire,
        error: _extractError(res.data) ?? 'HTTP ${res.status}',
      );
    }
    final data = res.data;
    if (data is! Map) {
      return GoldDecideResult(
        ok: false,
        status: status.wire,
        error: 'malformed response',
      );
    }
    final pairId = data['pair_id'];
    final sim = data['edit_similarity'];
    return GoldDecideResult(
      ok: data['ok'] == true,
      status: (data['status'] as String?) ?? status.wire,
      pairId: pairId is String ? pairId : null,
      editSimilarity: sim is num ? sim.toDouble() : null,
    );
  }

  String? _extractError(dynamic data) {
    if (data is Map) {
      final e = data['error'];
      if (e is String) return e;
    }
    return null;
  }
}

class GoldReviewException implements Exception {
  GoldReviewException(this.message, this.details);
  final String message;
  final String? details;

  @override
  String toString() =>
      details == null ? 'GoldReviewException: $message'
                       : 'GoldReviewException: $message — $details';
}
