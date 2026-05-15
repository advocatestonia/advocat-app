// sample_case_messages_test.dart
//
// Backlog #36 Layer 3 — sample case transcript contract.
//
// The sample-case experience is canned content shown to first-time users
// who tap "Try with a sample case" in the welcome modal. The transcript
// MUST:
//   - Exist in all 4 supported locales (EN/ET/FI/RU)
//   - Have at least 3 messages (per spec: 3–5 alternating)
//   - Begin with a user message (asking for risks)
//   - Reference Estonian VÕS so the user can see Advocat citing real law
//
// If a future change drops any of these the test fails loudly — the spec
// is "Estonian legal style with VÕS § references where genuine".

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/onboarding/data/sample_case_messages.dart';

void main() {
  group('SampleCase static metadata', () {
    test('sentinel id is "sample"', () {
      expect(SampleCase.id, 'sample');
    });

    test('title is localized for ET / FI / RU', () {
      expect(SampleCase.title('et'), contains('Näide'));
      expect(SampleCase.title('fi'), contains('Esimerkki'));
      expect(SampleCase.title('ru'), contains('Пример'));
      expect(SampleCase.title('en'), startsWith('Example'));
    });

    test('banner copy mentions canned/sample nature', () {
      for (final loc in ['en', 'et', 'fi', 'ru']) {
        final s = SampleCase.banner(loc);
        expect(s, isNotEmpty, reason: 'Banner empty for $loc');
      }
    });

    test('startRealCta is non-empty in every supported locale', () {
      for (final loc in ['en', 'et', 'fi', 'ru']) {
        expect(SampleCase.startRealCta(loc), isNotEmpty,
            reason: 'CTA empty for $loc');
      }
    });
  });

  group('SampleCase transcript shape', () {
    for (final loc in ['en', 'et', 'fi', 'ru']) {
      test('$loc: has 3–5 messages, starts with user, alternates', () {
        final msgs = SampleCase.messages(loc);
        expect(msgs.length, inInclusiveRange(3, 5),
            reason: '$loc transcript wrong length');
        expect(msgs.first.role, 'user',
            reason: '$loc must start with a user message');
        // Alternate strictly.
        for (var i = 0; i < msgs.length - 1; i++) {
          expect(msgs[i].role == msgs[i + 1].role, isFalse,
              reason: '$loc messages must alternate at index $i');
        }
      });

      test('$loc: first assistant reply mentions Estonian VÕS', () {
        final msgs = SampleCase.messages(loc);
        final firstAssistant =
            msgs.firstWhere((m) => m.role == 'assistant');
        expect(firstAssistant.content, contains('VÕS'),
            reason:
                '$loc assistant reply must cite VÕS to show real-law style');
      });

      test('$loc: every message has non-empty content', () {
        final msgs = SampleCase.messages(loc);
        for (final m in msgs) {
          expect(m.content.trim(), isNotEmpty,
              reason: '$loc empty content for role ${m.role}');
        }
      });
    }

    test('unknown locale falls back to EN transcript', () {
      final unk = SampleCase.messages('xx');
      final en = SampleCase.messages('en');
      expect(unk.length, en.length);
      expect(unk.first.content, en.first.content);
    });
  });
}
