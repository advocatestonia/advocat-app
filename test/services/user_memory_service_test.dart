// Tests for UserMemory model + the pure bits of UserMemoryService.
// -----------------------------------------------------------------------------
// Ref: lib/models/user_memory.dart
//      lib/services/user_memory_service.dart
//      docs/learning/ADR-001-three-tier-learning.md
//
// Network-backed methods (getMemories, forget, forgetAll, extractFromSession)
// require a live Supabase client with a logged-in session; those paths are
// exercised by the widget test for the AI memory screen which stubs
// Supabase via the UserMemoryService Riverpod provider.
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/models/user_memory.dart';
import 'package:advocat/services/user_memory_service.dart';

void main() {
  group('UserMemory.fromRow', () {
    test('parses a well-formed Supabase row', () {
      final row = <String, dynamic>{
        'id': '11111111-1111-1111-1111-111111111111',
        'user_id': 'user-1',
        'key': 'tone',
        'value': {
          'text': 'You prefer short replies',
          'confidence': 0.9,
          'extracted_from': 'sess-1',
        },
        'confidence': 0.9,
        'source_session_id': 'sess-1',
        'created_at': '2026-04-23T10:00:00Z',
        'last_reinforced_at': '2026-04-23T11:00:00Z',
        'expires_at': null,
      };
      final m = UserMemory.fromRow(row);
      expect(m.id, '11111111-1111-1111-1111-111111111111');
      expect(m.key, 'tone');
      expect(m.text, 'You prefer short replies');
      expect(m.confidence, 0.9);
      expect(m.sourceSessionId, 'sess-1');
      expect(m.expiresAt, isNull);
      expect(m.createdAt, DateTime.utc(2026, 4, 23, 10, 0, 0));
      expect(m.lastReinforcedAt, DateTime.utc(2026, 4, 23, 11, 0, 0));
    });

    test('tolerates value missing the text field', () {
      final row = <String, dynamic>{
        'id': 'id-2',
        'user_id': 'u',
        'key': 'background',
        'value': <String, dynamic>{},
        'confidence': 0.6,
        'source_session_id': null,
        'created_at': '2026-04-23T10:00:00Z',
        'last_reinforced_at': '2026-04-23T10:00:00Z',
        'expires_at': null,
      };
      final m = UserMemory.fromRow(row);
      expect(m.text, '');
    });

    test('parses expires_at when present', () {
      final row = <String, dynamic>{
        'id': 'id-3',
        'user_id': 'u',
        'key': 'deadline',
        'value': {'text': 'Hearing on 18.05.2026', 'confidence': 0.95},
        'confidence': 0.95,
        'source_session_id': null,
        'created_at': '2026-04-23T10:00:00Z',
        'last_reinforced_at': '2026-04-23T10:00:00Z',
        'expires_at': '2026-05-18T10:00:00Z',
      };
      final m = UserMemory.fromRow(row);
      expect(m.expiresAt, DateTime.utc(2026, 5, 18, 10, 0, 0));
    });
  });

  group('UserMemory.isExpired', () {
    final now = DateTime.utc(2026, 4, 23, 12, 0, 0);

    UserMemory build({DateTime? expires}) => UserMemory(
          id: 'x',
          key: 'deadline',
          text: 't',
          confidence: 0.9,
          createdAt: now,
          lastReinforcedAt: now,
          expiresAt: expires,
        );

    test('null expires_at → never expired', () {
      expect(build().isExpired(now), isFalse);
    });

    test('future expires_at → not expired', () {
      expect(
        build(expires: now.add(const Duration(days: 1))).isExpired(now),
        isFalse,
      );
    });

    test('past expires_at → expired', () {
      expect(
        build(expires: now.subtract(const Duration(minutes: 1))).isExpired(now),
        isTrue,
      );
    });
  });

  group('kAllowedMemoryKeys', () {
    test('matches ADR-001 vocabulary (12 keys after legal_status expansion)',
        () {
      // Explicit list keeps the client, Edge Function and SQL migration
      // in lock-step. Widening the vocabulary must go through an ADR.
      // 2026-05-05: added legal_status, nationality, residence_status —
      // these determine which body of law applies to the user, so they
      // are the highest-leverage facts to remember.
      expect(kAllowedMemoryKeys, {
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
      });
    });
  });

  group('memoryKeyLabel', () {
    test('renders a friendly label for each canonical key', () {
      expect(memoryKeyLabel('name'), 'Name');
      expect(memoryKeyLabel('tone'), 'Tone');
      expect(memoryKeyLabel('emotional_state'), 'Emotional state');
      expect(memoryKeyLabel('case_focus'), 'Case focus');
      expect(memoryKeyLabel('known_party'), 'People you mentioned');
      expect(memoryKeyLabel('deadline'), 'Deadlines');
      expect(memoryKeyLabel('user_goal'), 'Goals');
      expect(memoryKeyLabel('preference'), 'Preferences');
      expect(memoryKeyLabel('background'), 'Background');
      expect(memoryKeyLabel('discussed_topic'), 'Topics discussed');
    });

    test('renders friendly labels for legal-status keys', () {
      // 2026-05-05 expansion — these labels surface in the AI Memory
      // settings screen and in the system-prompt block rendering.
      expect(memoryKeyLabel('legal_status'), 'Legal status');
      expect(memoryKeyLabel('nationality'), 'Nationality');
      expect(memoryKeyLabel('residence_status'), 'Residence status');
    });

    test('unknown key falls through to the raw key', () {
      expect(memoryKeyLabel('future_key'), 'future_key');
    });
  });

  group('UserMemoryService.buildMemoryBlock — legal-status expansion', () {
    final now = DateTime.utc(2026, 5, 5);
    UserMemory mem(String key, String text, {double conf = 0.95}) =>
        UserMemory(
          id: '${key}_${text.hashCode}',
          key: key,
          text: text,
          confidence: conf,
          createdAt: now,
          lastReinforcedAt: now,
        );

    test('legal_status renders under an explanatory section header', () {
      // The brief mandates an explanatory header so the model knows WHY
      // this fact matters (it gates which body of law applies).
      final block = UserMemoryService.buildMemoryBlock([
        mem('legal_status',
            '3rd country national with humanitarian residence permit'),
      ]);
      expect(block, contains('YOUR LEGAL STATUS'));
      expect(block, contains('Aliens Act'));
      expect(
        block,
        contains('3rd country national with humanitarian residence permit'),
      );
    });

    test('legal-status section sits BEFORE the generic facts list', () {
      // Why: the model must know "who you are legally" before anything
      // else. If a tone preference renders before the legal status, the
      // model anchors on tone first and may misapply EU vs Estonian law.
      final block = UserMemoryService.buildMemoryBlock([
        mem('tone', 'You prefer short replies'),
        mem('legal_status', 'EU citizen'),
      ]);
      final legalIdx = block.indexOf('YOUR LEGAL STATUS');
      final factsIdx = block.indexOf('=== WHAT WE KNOW ABOUT YOU ===');
      expect(legalIdx, greaterThanOrEqualTo(0));
      expect(factsIdx, greaterThanOrEqualTo(0));
      expect(legalIdx, lessThan(factsIdx),
          reason: 'legal-status header must precede the generic facts header');
    });

    test('nationality + residence_status render in the legal section', () {
      final block = UserMemoryService.buildMemoryBlock([
        mem('nationality', 'RU'),
        mem('residence_status', 'temporary'),
      ]);
      expect(block, contains('YOUR LEGAL STATUS'));
      expect(block, contains('RU'));
      expect(block, contains('temporary'));
      // No generic facts header when ONLY legal-status keys are present.
      expect(block, isNot(contains('=== WHAT WE KNOW ABOUT YOU ===')));
    });

    test('legal-status keys are NOT duplicated in the generic facts list', () {
      final block = UserMemoryService.buildMemoryBlock([
        mem('legal_status', 'EU citizen'),
        mem('tone', 'short replies'),
      ]);
      // legal_status appears in legal section, not in generic list.
      // Count occurrences of the legal_status text — must be exactly 1.
      final occurrences = 'EU citizen'.allMatches(block).length;
      expect(occurrences, 1,
          reason: 'legal_status fact must not double-render');
    });

    test('empty list still returns empty string (no header bleed-through)',
        () {
      // Regression guard: don't accidentally print "YOUR LEGAL STATUS"
      // header when no legal-status facts exist.
      expect(UserMemoryService.buildMemoryBlock(const []), '');
    });

    test('only generic facts → no legal-status header rendered', () {
      final block = UserMemoryService.buildMemoryBlock([
        mem('tone', 'You prefer short replies'),
      ]);
      expect(block, isNot(contains('YOUR LEGAL STATUS')));
      expect(block, contains('=== WHAT WE KNOW ABOUT YOU ==='));
    });
  });

  group('UserMemoryService.buildMemoryBlock', () {
    final now = DateTime.utc(2026, 4, 23);

    UserMemory mem(String key, String text, {double conf = 0.9}) => UserMemory(
          id: '${key}_id',
          key: key,
          text: text,
          confidence: conf,
          createdAt: now,
          lastReinforcedAt: now,
        );

    test('empty list → empty string (no header printed)', () {
      expect(UserMemoryService.buildMemoryBlock(const []), '');
    });

    test('renders a labelled list with the standard header', () {
      final block = UserMemoryService.buildMemoryBlock([
        mem('tone', 'You prefer short replies'),
        mem('known_party', 'Your wife is Sofia'),
      ]);
      expect(block, contains('=== WHAT WE KNOW ABOUT YOU ==='));
      expect(block, contains('[Tone] You prefer short replies'));
      expect(block, contains('[People you mentioned] Your wife is Sofia'));
    });

    test('tells the model NOT to quote memories verbatim by default', () {
      // If the guidance is removed, models start to recite "I remember
      // that your wife is Sofia" which creeps users out. Pin it.
      final block = UserMemoryService.buildMemoryBlock([mem('tone', 'x')]);
      expect(block.toLowerCase(), contains('never quote them verbatim'));
    });

    test('preserves caller ordering (assumes caller sorted by confidence)', () {
      final block = UserMemoryService.buildMemoryBlock([
        mem('tone', 'AAA first'),
        mem('tone', 'BBB second'),
      ]);
      expect(
        block.indexOf('AAA first'),
        lessThan(block.indexOf('BBB second')),
      );
    });
  });
}
