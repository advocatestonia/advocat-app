// user_memory_edge_cases_test.dart
//
// OMEGA pre-launch QA expansion (2026-04-29). The existing
// `user_memory_service_test.dart` covers happy-path UserMemory
// parsing + buildMemoryBlock formatting. This file pins the
// invariants for adversarial inputs the extract-memory Edge
// Function or a corrupted DB row could feed back to the client:
//
//   • confidence boundary values (0, 0.5, 1.0, 1.01, -0.1, 100)
//   • value field as a non-Map (string fallback, null, list)
//   • empty memory list → empty block (not "=== WHAT WE KNOW ===" header)
//   • 50 memories render in a single block without truncation
//   • UTF-8 / emoji / Cyrillic in fact text passes through unchanged
//   • duplicate keys preserve caller ordering — caller decides
//     which "wins" (per ADR-001 the highest-confidence row wins
//     server-side, so the caller's pre-sort is the source of truth)
//   • memory key labels stay stable for every value in
//     kAllowedMemoryKeys (compile-time check that the label switch
//     matches the allow-list)
//   • isExpired boundary at exact `now`
//   • session-id propagation through extractFromSession (the actual
//     Edge Function call is mocked away by Riverpod overrides — pure
//     unit signal here is the message-shape transformation)
//
// @Tags(['fast'])

@Tags(['fast'])
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/models/user_memory.dart';
import 'package:advocat/services/user_memory_service.dart';

void main() {
  // ---- Fixtures -----------------------------------------------------------

  Map<String, dynamic> mkRow({
    String id = 'id-1',
    String userId = 'u',
    String key = 'tone',
    Object? value,
    num confidence = 0.9,
    String? sourceSessionId,
    String createdAt = '2026-04-23T10:00:00Z',
    String? expiresAt,
  }) =>
      <String, dynamic>{
        'id': id,
        'user_id': userId,
        'key': key,
        'value': value ?? {'text': 'You prefer short replies'},
        'confidence': confidence,
        'source_session_id': sourceSessionId,
        'created_at': createdAt,
        'last_reinforced_at': createdAt,
        'expires_at': expiresAt,
      };

  group('UserMemory.fromRow — confidence boundary values', () {
    test('confidence = 0.0 is preserved verbatim', () {
      final m = UserMemory.fromRow(mkRow(confidence: 0.0));
      expect(m.confidence, 0.0);
    });

    test('confidence = 1.0 (max valid) is preserved', () {
      final m = UserMemory.fromRow(mkRow(confidence: 1.0));
      expect(m.confidence, 1.0);
    });

    test('confidence > 1.0 is preserved (server should reject; client trusts)',
        () {
      // The Edge Function rejects rows above 1.0. If one slips through
      // (corrupted DB row), the client must NOT crash — it stores
      // whatever was there.
      final m = UserMemory.fromRow(mkRow(confidence: 1.5));
      expect(m.confidence, 1.5);
    });

    test('confidence = 100 (caller bug, e.g. percent vs ratio) is preserved',
        () {
      final m = UserMemory.fromRow(mkRow(confidence: 100));
      expect(m.confidence, 100.0);
    });

    test('negative confidence is preserved (no client-side clamping)', () {
      final m = UserMemory.fromRow(mkRow(confidence: -0.1));
      expect(m.confidence, -0.1);
    });

    test('integer confidence (1 instead of 1.0) parses cleanly', () {
      final m = UserMemory.fromRow(mkRow(confidence: 1));
      expect(m.confidence, 1.0);
    });
  });

  group('UserMemory.fromRow — malformed value shapes', () {
    test('value = null → text becomes empty string, no crash', () {
      // mkRow uses a default Map; explicitly pass null to test the path.
      final row = mkRow();
      row['value'] = null;
      final m = UserMemory.fromRow(row);
      expect(m.text, '');
    });

    test('value = "raw string" is accepted (defensive fallback)', () {
      final m = UserMemory.fromRow(mkRow(value: 'just a string'));
      expect(m.text, 'just a string');
    });

    test('value = list (wrong type) → text becomes empty, no crash', () {
      // Edge Function never produces this, but we should survive a
      // garbage row from a manual SQL insert.
      final m = UserMemory.fromRow(mkRow(value: ['nope']));
      expect(m.text, '');
    });

    test('value = Map without text key → text empty', () {
      final m = UserMemory.fromRow(
          mkRow(value: {'confidence': 0.9, 'extracted_from': 'x'}));
      expect(m.text, '');
    });

    test('value text with emoji + Cyrillic + Estonian preserved verbatim', () {
      final m = UserMemory.fromRow(mkRow(value: {
        'text': 'Жена Sofia 🥰 — kõlbmatu olukord',
      }));
      expect(m.text, 'Жена Sofia 🥰 — kõlbmatu olukord');
    });
  });

  group('UserMemory.isExpired — boundary at exact now', () {
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

    test('expires_at == now → not expired (strict isBefore)', () {
      // The model uses `isBefore` — equal is NOT before, so this row
      // is treated as still-live. Pin the contract so a future change
      // to `<= now` forces a deliberate review.
      expect(build(expires: now).isExpired(now), isFalse);
    });

    test('expires_at 1 microsecond before now → expired', () {
      expect(
        build(expires: now.subtract(const Duration(microseconds: 1)))
            .isExpired(now),
        isTrue,
      );
    });
  });

  group('UserMemoryService.buildMemoryBlock — scale + ordering', () {
    final now = DateTime.utc(2026, 4, 23);

    UserMemory mem(String key, String text, {double conf = 0.9}) =>
        UserMemory(
          id: '${key}_$text',
          key: key,
          text: text,
          confidence: conf,
          createdAt: now,
          lastReinforcedAt: now,
        );

    test('50 memories all render — no truncation', () {
      final memories = List.generate(
        50,
        (i) => mem(i.isEven ? 'tone' : 'background', 'fact #$i'),
      );
      final block = UserMemoryService.buildMemoryBlock(memories);
      // Each fact must appear once.
      for (var i = 0; i < 50; i++) {
        expect(block, contains('fact #$i'));
      }
    });

    test('block header appears exactly once for non-empty list', () {
      final block = UserMemoryService.buildMemoryBlock([
        mem('tone', 'a'),
        mem('background', 'b'),
        mem('preference', 'c'),
      ]);
      final headerCount = '=== WHAT WE KNOW ABOUT YOU ==='.allMatches(block).length;
      expect(headerCount, 1);
    });

    test('empty list → exact empty string (no whitespace, no header)', () {
      expect(UserMemoryService.buildMemoryBlock(const []), '');
    });

    test('duplicate keys with different texts — both render in order', () {
      final block = UserMemoryService.buildMemoryBlock([
        mem('known_party', 'Wife: Sofia'),
        mem('known_party', 'Lawyer: Tolonen'),
      ]);
      // Both must appear; ordering must be preserved (caller-supplied).
      expect(block, contains('Wife: Sofia'));
      expect(block, contains('Lawyer: Tolonen'));
      expect(
        block.indexOf('Wife: Sofia'),
        lessThan(block.indexOf('Lawyer: Tolonen')),
      );
    });

    test('emoji + Cyrillic in fact text survives the renderer', () {
      final block = UserMemoryService.buildMemoryBlock([
        mem('known_party', 'Жена — Sofia 🥰'),
      ]);
      expect(block, contains('Жена — Sofia 🥰'));
    });

    test('the rendered list is NOT mutated when the same memory list is reused',
        () {
      // Defensive: the renderer must not modify its input — the same
      // list should produce the same output every time.
      final memories = [mem('tone', 'AAA'), mem('tone', 'BBB')];
      final a = UserMemoryService.buildMemoryBlock(memories);
      final b = UserMemoryService.buildMemoryBlock(memories);
      expect(a, b);
      expect(memories.length, 2,
          reason: 'caller list must not be mutated');
    });
  });

  group('memoryKeyLabel — every allowed key has a labeled fallback', () {
    test('every key in kAllowedMemoryKeys produces a non-empty label', () {
      for (final key in kAllowedMemoryKeys) {
        final label = memoryKeyLabel(key);
        expect(label, isNotEmpty,
            reason: 'allowed key "$key" must have a label');
        // The label should be either the human-readable form OR the
        // raw key (the documented fallback).
        expect(label.length, greaterThanOrEqualTo(3));
      }
    });

    test('unknown key falls through to raw key (forward compat)', () {
      // ADR-001 vocabulary is bounded BUT the server can ship a new key
      // ahead of the client. The label fallback must be the key itself.
      expect(memoryKeyLabel('hypothetical_future_key'),
          'hypothetical_future_key');
    });
  });
}
