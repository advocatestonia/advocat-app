// Tier 1 user AI memory model — mirrors public.user_ai_memory rows.
// -----------------------------------------------------------------------------
// Ref: docs/learning/ADR-001-three-tier-learning.md
//      supabase/migrations/20260423010000_user_ai_memory.sql
//
// This is a dumb data class — no Supabase, no I/O. Shared between the
// service layer and the UI. Keep the key vocabulary in lock-step with
// supabase/functions/extract-memory/memory_schema.ts ALLOWED_KEYS and
// the SQL migration comment.
// -----------------------------------------------------------------------------

/// One fact Haiku has extracted about a user from a chat session.
class UserMemory {
  UserMemory({
    required this.id,
    required this.key,
    required this.text,
    required this.confidence,
    required this.createdAt,
    required this.lastReinforcedAt,
    this.sourceSessionId,
    this.expiresAt,
  });

  final String id;

  /// Bounded vocabulary — see [kAllowedMemoryKeys].
  final String key;

  /// The human-readable fact text (already capped to 500 chars server-side).
  final String text;

  /// 0.0..1.0. Rows below 0.5 never reach the client — the Edge Function
  /// drops them before insert.
  final double confidence;

  final DateTime createdAt;
  final DateTime lastReinforcedAt;
  final String? sourceSessionId;
  final DateTime? expiresAt;

  /// Parse a row returned by Supabase. The row shape is
  ///   { id, key, value jsonb, confidence real, created_at, ...}.
  /// where `value = {text, confidence, extracted_from}`.
  factory UserMemory.fromRow(Map<String, dynamic> row) {
    final value = row['value'];
    String text = '';
    if (value is Map) {
      final t = value['text'];
      if (t is String) text = t;
    } else if (value is String) {
      // Defensive — if Supabase returned it as a string for any reason.
      text = value;
    }
    double confidence = 0.5;
    final c = row['confidence'];
    if (c is num) confidence = c.toDouble();
    return UserMemory(
      id: row['id'] as String,
      key: row['key'] as String,
      text: text,
      confidence: confidence,
      createdAt: DateTime.parse(row['created_at'] as String),
      lastReinforcedAt: DateTime.parse(row['last_reinforced_at'] as String),
      sourceSessionId: row['source_session_id'] as String?,
      expiresAt: row['expires_at'] == null
          ? null
          : DateTime.parse(row['expires_at'] as String),
    );
  }

  /// True when the fact is time-bound and already passed.
  bool isExpired(DateTime now) =>
      expiresAt != null && expiresAt!.isBefore(now);
}

/// Client-side copy of the bounded vocabulary. Kept in sync manually
/// with the Edge Function + SQL migration. A mismatch here cannot
/// corrupt data (the server rejects unknown keys) but it can cause
/// the UI to show "Unknown" labels if a new key is added server-side.
///
/// 2026-05-05 expansion (Visioning Council #1 priority):
///   legal_status      — citizen | eu_citizen | 3rd_country | asylum_seeker
///                       | refugee | stateless | other
///   nationality       — ISO country code (RU, EE, FI, …)
///   residence_status  — permanent | temporary | humanitarian | undefined
/// These three gate which body of law applies and therefore appear in a
/// dedicated "YOUR LEGAL STATUS" section in [UserMemoryService.buildMemoryBlock].
const Set<String> kAllowedMemoryKeys = {
  'name',
  'tone',
  'emotional_state',
  'case_focus',
  'known_party',
  'deadline',
  'user_goal',
  'preference',
  'background',
  'discussed_topic',
  'legal_status',
  'nationality',
  'residence_status',
};

/// Subset of [kAllowedMemoryKeys] that determines which body of law applies
/// to the user. These are rendered in a separate, prominent section in the
/// system prompt so the model anchors on legal context before tone/style.
const Set<String> kLegalStatusMemoryKeys = {
  'legal_status',
  'nationality',
  'residence_status',
};

/// User-facing label for each memory key. Default shown when the enum
/// is out of date — `key` itself.
String memoryKeyLabel(String key) {
  switch (key) {
    case 'name':
      return 'Name';
    case 'tone':
      return 'Tone';
    case 'emotional_state':
      return 'Emotional state';
    case 'case_focus':
      return 'Case focus';
    case 'known_party':
      return 'People you mentioned';
    case 'deadline':
      return 'Deadlines';
    case 'user_goal':
      return 'Goals';
    case 'preference':
      return 'Preferences';
    case 'background':
      return 'Background';
    case 'discussed_topic':
      return 'Topics discussed';
    case 'legal_status':
      return 'Legal status';
    case 'nationality':
      return 'Nationality';
    case 'residence_status':
      return 'Residence status';
    default:
      return key;
  }
}
