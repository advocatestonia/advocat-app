// feedback_service.dart
//
// Pre-launch feature: thumbs-up / thumbs-down feedback under every AI message.
//
// Goal: with the very first paying user we want a real signal of which
// answers worked and which didn't. In two weeks we'll skim the 👎 rows and
// nudge system prompts. Marketing can honestly say "learns from your
// feedback". Later this becomes training data for fine-tuning.
//
// Design:
//   * One row per (user_id, message_id) — toggling is an upsert.
//   * Captures a 500-char preview of both sides plus a sha256 hash of the
//     system prompt (first 1000 chars) so we can bucket feedback by prompt
//     revision.
//   * In demo mode (no Supabase) all writes silently no-op so the UI does
//     not crash on local builds.
//   * Synthetic case_ids like 'general' are stripped — the DB column is
//     uuid and would otherwise reject the insert (chat_infra pitfall #2).

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

final feedbackServiceProvider = Provider<FeedbackService>((ref) {
  final supabase = ref.read(supabaseServiceProvider);
  return FeedbackService(supabase);
});

class FeedbackService {
  FeedbackService(this._supabase);

  final SupabaseService _supabase;

  static const _table = 'message_feedback';
  static const _previewMax = 500;
  static const _promptHashMax = 1000;

  /// Strict UUID regex for case_id sanitization. Mirrors the one in
  /// SupabaseService — keeps this module independent for unit testing.
  static final _uuidRegex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  // ── Pure helpers (unit-testable, no Supabase) ────────────────────────

  /// Build the row payload that will be sent to Supabase. Pure — no IO.
  ///
  /// Throws [ArgumentError] for invalid rating or empty message_id.
  /// Optional fields are omitted from the returned map (rather than set
  /// to null) so the DB defaults / column nullability take effect.
  static Map<String, dynamic> buildPayload({
    required String userId,
    required String messageId,
    required int rating,
    String? caseId,
    String? comment,
    String? aiResponse,
    String? userMessage,
    String? systemPromptHash,
    String? language,
    String? model,
  }) {
    if (rating != 1 && rating != -1) {
      throw ArgumentError('rating must be -1 or 1, got $rating');
    }
    if (messageId.isEmpty) {
      throw ArgumentError('messageId must not be empty');
    }

    final payload = <String, dynamic>{
      'user_id': userId,
      'message_id': messageId,
      'rating': rating,
    };

    // Only attach case_id if it is a real UUID. Synthetic ids like 'general'
    // would violate the uuid column type.
    if (caseId != null && _uuidRegex.hasMatch(caseId)) {
      payload['case_id'] = caseId;
    }

    if (comment != null && comment.isNotEmpty) {
      payload['comment'] = _truncate(comment, _previewMax);
    }
    if (aiResponse != null && aiResponse.isNotEmpty) {
      payload['ai_response_preview'] = _truncate(aiResponse, _previewMax);
    }
    if (userMessage != null && userMessage.isNotEmpty) {
      payload['user_message_preview'] = _truncate(userMessage, _previewMax);
    }
    if (systemPromptHash != null && systemPromptHash.isNotEmpty) {
      payload['system_prompt_hash'] = systemPromptHash;
    }
    if (language != null && language.isNotEmpty) {
      payload['language'] = language;
    }
    if (model != null && model.isNotEmpty) {
      payload['model'] = model;
    }

    return payload;
  }

  /// SHA-256 of the first 1000 chars of [prompt]. Returns null for null /
  /// empty inputs. We don't store the prompt itself — only the hash — to
  /// keep the table small and free of accidentally-leaked secrets.
  static String? hashSystemPrompt(String? prompt) {
    if (prompt == null || prompt.isEmpty) return null;
    final head = prompt.length > _promptHashMax
        ? prompt.substring(0, _promptHashMax)
        : prompt;
    return sha256.convert(utf8.encode(head)).toString();
  }

  /// Returns the new rating after a click on [clicked] given the [current]
  /// state. Clicking the same icon twice deselects it (returns null).
  static int? toggleRating({required int? current, required int clicked}) {
    if (current == clicked) return null;
    return clicked;
  }

  static String _truncate(String s, int n) =>
      s.length <= n ? s : s.substring(0, n);

  // ── Supabase round-trips ─────────────────────────────────────────────

  /// Submit (upsert) a rating. In demo mode this silently no-ops.
  ///
  /// Pass [rating] = null to remove an existing rating (toggle off).
  Future<void> submitFeedback({
    required String messageId,
    required int? rating,
    String? caseId,
    String? comment,
    String? aiResponse,
    String? userMessage,
    String? systemPromptHash,
    String? language,
    String? model,
  }) async {
    if (_supabase.isDemo) return; // No-op in offline demo builds.

    final userId = _supabase.currentUserId;
    if (userId == null) {
      throw StateError('Cannot submit feedback: user is not authenticated');
    }

    final client = Supabase.instance.client;
    if (rating == null) {
      // Toggle off — delete the row if it exists.
      await client
          .from(_table)
          .delete()
          .eq('user_id', userId)
          .eq('message_id', messageId);
      return;
    }

    final payload = buildPayload(
      userId: userId,
      messageId: messageId,
      rating: rating,
      caseId: caseId,
      comment: comment,
      aiResponse: aiResponse,
      userMessage: userMessage,
      systemPromptHash: systemPromptHash,
      language: language,
      model: model,
    );

    await client
        .from(_table)
        .upsert(payload, onConflict: 'user_id,message_id');
  }

  /// Fetch the existing feedback row for [messageId] so the UI can restore
  /// the active state when a user revisits a conversation. Returns null if
  /// nothing was rated (or in demo mode / when unauthenticated).
  Future<FeedbackRecord?> getFeedback(String messageId) async {
    if (_supabase.isDemo) return null;
    final userId = _supabase.currentUserId;
    if (userId == null) return null;

    final row = await Supabase.instance.client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .eq('message_id', messageId)
        .maybeSingle();

    if (row == null) return null;
    return FeedbackRecord.fromMap(row);
  }

  /// Aggregate counts for the current user. Reserved for future analytics
  /// surfaces — not used by the chat UI yet.
  Future<({int up, int down})> getMyFeedbackStats() async {
    if (_supabase.isDemo) return (up: 0, down: 0);
    final userId = _supabase.currentUserId;
    if (userId == null) return (up: 0, down: 0);

    final rows = await Supabase.instance.client
        .from(_table)
        .select('rating')
        .eq('user_id', userId);

    int up = 0, down = 0;
    for (final r in rows as List) {
      final v = (r as Map)['rating'] as int?;
      if (v == 1) up++;
      if (v == -1) down++;
    }
    return (up: up, down: down);
  }
}

/// Snapshot of a stored feedback row, used by the UI to render the active
/// state of the thumbs buttons after navigating back to a conversation.
class FeedbackRecord {
  const FeedbackRecord({
    required this.messageId,
    required this.rating,
    this.comment,
  });

  final String messageId;
  final int rating;
  final String? comment;

  factory FeedbackRecord.fromMap(Map<String, dynamic> map) {
    return FeedbackRecord(
      messageId: map['message_id'] as String,
      rating: (map['rating'] as num).toInt(),
      comment: map['comment'] as String?,
    );
  }
}
