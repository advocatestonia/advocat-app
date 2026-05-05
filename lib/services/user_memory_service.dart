// UserMemoryService — ADR-001 Tier 1 client layer.
// -----------------------------------------------------------------------------
// Ref: docs/learning/ADR-001-three-tier-learning.md
//      supabase/functions/extract-memory/index.ts
//      lib/models/user_memory.dart
//
// Responsibilities:
//   * Fetch the current user's top-N memories from public.user_ai_memory.
//   * Format them into a system-prompt block ("=== WHAT WE KNOW ABOUT YOU ===").
//   * Delete a single memory (GDPR Art. 17).
//   * Delete every memory (full erase).
//   * Trigger the extract-memory Edge Function after a chat session ends.
//
// Integration into the chat pipeline (system_prompts.dart +
// ai_service.dart) is deliberately NOT wired yet — that patch ships
// after the UX-FIX branch merges. See docs/memory-tier1/integration_patch.md.
// -----------------------------------------------------------------------------

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_memory.dart';

/// Riverpod DI — tests can override this to inject a fake client.
final userMemoryServiceProvider = Provider<UserMemoryService>((ref) {
  return UserMemoryService();
});

class UserMemoryService {
  UserMemoryService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get _currentUserId => _client.auth.currentUser?.id;

  // ---------------------------------------------------------------------------
  // Fetch
  // ---------------------------------------------------------------------------

  /// Top-N memories for the current user, ordered by confidence desc.
  /// Filters out expired rows. Returns `[]` when not signed in or on error.
  Future<List<UserMemory>> getMemories({int limit = 20}) async {
    final uid = _currentUserId;
    if (uid == null) return const [];
    try {
      final rows = await _client
          .from('user_ai_memory')
          .select()
          .eq('user_id', uid)
          .order('confidence', ascending: false)
          .order('last_reinforced_at', ascending: false)
          .limit(limit);
      final now = DateTime.now();
      return (rows as List)
          .map((r) => UserMemory.fromRow(r as Map<String, dynamic>))
          .where((m) => !m.isExpired(now))
          .toList(growable: false);
    } catch (_) {
      // The RLS policy + network errors both fall through silently — the
      // AI falls back to its per-case context. Never throw to the caller.
      return const [];
    }
  }

  // ---------------------------------------------------------------------------
  // System-prompt formatting
  // ---------------------------------------------------------------------------

  /// Render a compact memory block for injection into the chat system
  /// prompt. Returns an empty string when there is nothing to say — the
  /// caller should guard on that to avoid printing a header with no body.
  ///
  /// Static so it can be called from the system-prompt builder without
  /// spinning up a Supabase client. The caller is responsible for
  /// fetching + sorting the memories (via [getMemories]).
  ///
  /// Output:
  ///
  ///   === YOUR LEGAL STATUS ===
  ///   (This determines which body of law applies. Apply Estonian Aliens
  ///   Act, EU directives, or Estonian civil/criminal law accordingly.)
  ///   - [Legal status] 3rd country national with humanitarian residence permit.
  ///   - [Nationality] RU
  ///   - [Residence status] temporary
  ///
  ///   === WHAT WE KNOW ABOUT YOU ===
  ///   (Use these to personalise tone and anticipate needs. Never quote
  ///   them verbatim unless the user asks what you remember.)
  ///   - [Tone] You prefer short replies.
  ///   - [People you mentioned] Your wife is Sofia.
  ///   ...
  ///
  /// Legal-status keys ([kLegalStatusMemoryKeys]) ALWAYS render first so
  /// the model anchors on jurisdiction before style/tone. They are not
  /// duplicated into the generic facts list below.
  static String buildMemoryBlock(List<UserMemory> memories) {
    if (memories.isEmpty) return '';

    final legal = memories
        .where((m) => kLegalStatusMemoryKeys.contains(m.key))
        .toList(growable: false);
    final generic = memories
        .where((m) => !kLegalStatusMemoryKeys.contains(m.key))
        .toList(growable: false);

    final buf = StringBuffer();

    if (legal.isNotEmpty) {
      buf
        ..writeln('=== YOUR LEGAL STATUS ===')
        ..writeln(
          '(This determines which body of law applies. Apply Estonian '
          'Aliens Act, EU directives, or Estonian civil/criminal law '
          'accordingly. Never assume citizenship — use only what is '
          'recorded here.)',
        );
      for (final m in legal) {
        buf.writeln('- [${memoryKeyLabel(m.key)}] ${m.text}');
      }
    }

    if (generic.isNotEmpty) {
      if (legal.isNotEmpty) buf.writeln();
      buf
        ..writeln('=== WHAT WE KNOW ABOUT YOU ===')
        ..writeln(
          '(Use these to personalise tone and anticipate needs. Never quote '
          'them verbatim unless the user asks what you remember.)',
        );
      for (final m in generic) {
        buf.writeln('- [${memoryKeyLabel(m.key)}] ${m.text}');
      }
    }

    return buf.toString();
  }

  // ---------------------------------------------------------------------------
  // GDPR — delete
  // ---------------------------------------------------------------------------

  /// Delete a single memory. Safe no-op when not signed in. Relies on the
  /// `user_ai_memory_delete_own` RLS policy to scope to the current user
  /// server-side.
  Future<void> forget(String memoryId) async {
    final uid = _currentUserId;
    if (uid == null) return;
    try {
      await _client
          .from('user_ai_memory')
          .delete()
          .eq('id', memoryId)
          .eq('user_id', uid);
    } catch (_) {
      // Network or RLS denial — don't crash the UI; the settings screen
      // will refresh and show the row is still there.
    }
  }

  /// Full erase — "Forget everything". Called from the settings screen
  /// behind a confirmation dialog.
  Future<void> forgetAll() async {
    final uid = _currentUserId;
    if (uid == null) return;
    try {
      await _client
          .from('user_ai_memory')
          .delete()
          .eq('user_id', uid);
    } catch (_) {
      // swallow — caller refreshes the list
    }
  }

  // ---------------------------------------------------------------------------
  // Trigger extraction
  // ---------------------------------------------------------------------------

  /// Ask the `extract-memory` Edge Function to run against a chat
  /// session and upsert any new facts. Called *after* the assistant
  /// finishes streaming so the user never waits on us.
  ///
  /// [messages] is a chronological list (oldest first). [sessionId] is
  /// optional — it ends up in `user_ai_memory.source_session_id` so
  /// users can trace a memory back to the conversation that produced it.
  ///
  /// Returns counts `{extracted, stored, duplicates}` for optional UI
  /// feedback. Returns `null` on any error so callers can treat it as
  /// best-effort.
  Future<Map<String, int>?> extractFromSession({
    required List<({String role, String content})> messages,
    String? sessionId,
  }) async {
    final uid = _currentUserId;
    if (uid == null) return null;
    if (messages.isEmpty) return null;
    try {
      final response = await _client.functions.invoke(
        'extract-memory',
        body: {
          if (sessionId != null) 'session_id': sessionId,
          'messages': messages
              .map((m) => {'role': m.role, 'content': m.content})
              .toList(),
        },
      );
      final data = response.data;
      if (data is Map) {
        return {
          'extracted': (data['extracted'] as num?)?.toInt() ?? 0,
          'stored': (data['stored'] as num?)?.toInt() ?? 0,
          'duplicates': (data['duplicates'] as num?)?.toInt() ?? 0,
        };
      }
      return null;
    } catch (_) {
      // Extraction is best-effort. Chat still works without it.
      return null;
    }
  }
}
