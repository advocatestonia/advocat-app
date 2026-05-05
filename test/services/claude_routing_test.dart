@Tags(['fast'])
library;

// =============================================================================
// claude_routing_test.dart — P0-3 legal-question detector + Sonnet escalation
// =============================================================================
//
// 2026-05-05 — P0-3 of the Advocat legal-brain rebuild. Adds a stricter
// "is this a legal question" detector and routes legal turns to Sonnet
// regardless of message length / keyword count.
//
// Contract pinned here:
//   - looksLegalish("can I appeal") == true
//   - looksLegalish("hello there")  == false
//   - chooseModel(legal-ish, userLanguage='ru') → Sonnet
//   - chooseModel(legal-ish, userLanguage='fi') → legacy behaviour (Haiku
//     for short non-keyword queries) — FI is not in the P0-3 set
//   - chooseModel(non-legal, userLanguage='ru') → Haiku (no false escalation)
//   - chooseModel(legal-ish, userLanguage=null) → legacy behaviour (no
//     escalation; back-compat for call-sites that don't yet pass language)
//
// The existing claude_service_routing_test.dart pins the chooseModelForTools
// matrix and the RU stem battery — this file pins the NEW knobs P0-3 adds.
// =============================================================================

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/claude_service.dart';

void main() {
  group('ClaudeService.looksLegalish — keyword detector', () {
    test('RU short legal phrasings → true', () {
      const cases = [
        'меня уволили',
        'хочу обжаловать решение',
        'подать иск в суд',
        'мне положена компенсация',
        'хочу подать жалобу',
        'я подал заявление',
      ];
      for (final q in cases) {
        expect(
          ClaudeService.looksLegalish(q),
          isTrue,
          reason: 'RU "$q" must register as legal-ish.',
        );
      }
    });

    test('ET broad-domain legal phrasings → true', () {
      const cases = [
        'kas ma saan esitada vaide',
        'hagi esitamine kohtusse',
        'mul on töövaidlus tööandjaga',
        'kohtuasi pere kohta',
        'ma tahan üürilepingut lõpetada',
        'tarbija õigus tagastusele',
      ];
      for (final q in cases) {
        expect(
          ClaudeService.looksLegalish(q),
          isTrue,
          reason: 'ET "$q" must register as legal-ish.',
        );
      }
    });

    test('EN broad-domain legal phrasings → true', () {
      const cases = [
        'I want to file a dispute',
        'how do I make a claim',
        'my landlord refuses to return the deposit',
        'wrongful dismissal lawsuit',
        'can I sue them',
        'is my employer liable',
      ];
      for (final q in cases) {
        expect(
          ClaudeService.looksLegalish(q),
          isTrue,
          reason: 'EN "$q" must register as legal-ish.',
        );
      }
    });

    test('UK legal phrasings → true', () {
      const cases = [
        'мене звільнили з роботи',
        'хочу оскаржити рішення',
        'подати скаргу до суду',
        'трудовий спір з роботодавцем',
      ];
      for (final q in cases) {
        expect(
          ClaudeService.looksLegalish(q),
          isTrue,
          reason: 'UK "$q" must register as legal-ish.',
        );
      }
    });

    test('benign small-talk → false', () {
      const cases = [
        'hi',
        'hello there',
        'привет как дела',
        'tere mis uudist',
        'thanks',
        'спасибо большое',
        'aitäh',
        'how is the weather today in Tallinn',
        // Conversational but not legal — even when long.
        'I just wanted to say hello and ask how you are doing today my friend',
      ];
      for (final q in cases) {
        expect(
          ClaudeService.looksLegalish(q),
          isFalse,
          reason: '"$q" must NOT register as legal-ish.',
        );
      }
    });
  });

  group('ClaudeService.chooseModel — P0-3 legal escalation', () {
    test('RU legal-ish short query → Sonnet (was Haiku in legacy)', () {
      // Short message, no double-keyword match, but legal-ish stems are
      // present. P0-3: escalate to Sonnet.
      const q = 'хочу обжаловать решение';
      expect(
        ClaudeService.chooseModel(q, userLanguage: 'ru'),
        ClaudeService.modelSonnet,
      );
    });

    test('ET legal-ish short query → Sonnet', () {
      const q = 'kas ma saan esitada vaide';
      expect(
        ClaudeService.chooseModel(q, userLanguage: 'et'),
        ClaudeService.modelSonnet,
      );
    });

    test('EN legal-ish short query → Sonnet', () {
      const q = 'can I file a dispute';
      expect(
        ClaudeService.chooseModel(q, userLanguage: 'en'),
        ClaudeService.modelSonnet,
      );
    });

    test('UK legal-ish short query → Sonnet', () {
      const q = 'хочу оскаржити рішення';
      expect(
        ClaudeService.chooseModel(q, userLanguage: 'uk'),
        ClaudeService.modelSonnet,
      );
    });

    test('FI legal-ish query stays on legacy path (FI not in P0-3 set)', () {
      // Finnish is not in the P0-3 escalation set — legacy heuristic owns it.
      // 'irtisano' is in _complexKeywords so a short FI query still routes
      // through the existing logic — we only assert that explicitly passing
      // userLanguage='fi' does not break legacy parity.
      const q = 'voinko tehdä valituksen';
      final actual = ClaudeService.chooseModel(q, userLanguage: 'fi');
      final legacy = ClaudeService.chooseModel(q);
      expect(
        actual,
        legacy,
        reason: 'FI must keep legacy chooseModel behaviour exactly.',
      );
    });

    test('non-legal short query in RU → Haiku (no false escalation)', () {
      const q = 'привет как дела';
      expect(
        ClaudeService.chooseModel(q, userLanguage: 'ru'),
        ClaudeService.modelHaiku,
      );
    });

    test('userLanguage=null preserves legacy behaviour exactly', () {
      // Back-compat: pre-P0-3 call-sites pass no userLanguage. Their
      // routing must be byte-equal to the legacy single-arg form.
      const queries = [
        'hi',
        'хочу обжаловать решение', // would be Sonnet with lang=ru
        'kas ma saan esitada vaide',
        'I want to file a dispute',
        'how is the weather today',
      ];
      for (final q in queries) {
        final withoutLang = ClaudeService.chooseModel(q);
        final withNullLang = ClaudeService.chooseModel(q, userLanguage: null);
        expect(
          withNullLang,
          withoutLang,
          reason: 'userLanguage=null must equal omitted-arg routing for "$q".',
        );
      }
    });

    test('legacy double-keyword match still routes to Sonnet', () {
      // Regression guard: existing matchCount >= 2 path must keep working
      // even after the new escalation gate is added.
      const q = 'I need help with my deportation appeal — court hearing soon';
      expect(
        ClaudeService.chooseModel(q),
        ClaudeService.modelSonnet,
        reason: 'Legacy match-count >= 2 path must remain.',
      );
    });

    test('benign greeting still picks Haiku regardless of language', () {
      for (final lang in ['ru', 'et', 'en', 'uk', null, 'fi']) {
        expect(
          ClaudeService.chooseModel('hi', userLanguage: lang),
          ClaudeService.modelHaiku,
          reason: 'Greeting "hi" with lang=$lang must stay on Haiku.',
        );
      }
    });
  });

  group('ClaudeService.chooseModelForTools — userLanguage forwarding', () {
    test('no-tools path forwards userLanguage to chooseModel', () {
      // Without tools, chooseModelForTools must delegate to chooseModel
      // INCLUDING the userLanguage hint. Otherwise the P0-3 escalation
      // wouldn't fire for the no-tools turn surface.
      const q = 'хочу обжаловать решение';
      expect(
        ClaudeService.chooseModelForTools(
          q,
          hasTools: false,
          isAuthenticated: true,
          userLanguage: 'ru',
        ),
        ClaudeService.modelSonnet,
      );
    });

    test('no-tools, no userLanguage → legacy chooseModel parity', () {
      const queries = [
        'hi',
        'I need help with my deportation appeal',
        'short question',
      ];
      for (final q in queries) {
        expect(
          ClaudeService.chooseModelForTools(
            q,
            hasTools: false,
            isAuthenticated: true,
          ),
          ClaudeService.chooseModel(q),
          reason: 'No-tools, no-lang path must equal legacy chooseModel.',
        );
      }
    });
  });
}
