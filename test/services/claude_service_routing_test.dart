@Tags(['fast'])
library;

// =============================================================================
// claude_service_routing_test.dart — model routing for tool turns.
// =============================================================================
//
// 2026-05-05 — Anthropic engineer (consilium) Gap: when the chat layer offers
// tools (assistant_tools, web_search, etc.) the model needs enough headroom
// to (a) pick a tool and (b) stitch the result into a final answer. Haiku is
// fine for greetings and short Q&A but degrades on multi-step tool turns.
//
// Contract pinned here:
//   - chooseModelForTools(query, hasTools=true,  isAuthenticated=true ) →
//        Sonnet UNLESS the query is a "simple" greeting (which gets Haiku).
//   - chooseModelForTools(query, hasTools=true,  isAuthenticated=false) →
//        Haiku regardless. Anon callers cannot trigger Sonnet — server
//        clamps their max_tokens to 500 and refuses thinking, so spending
//        Sonnet $ on them is wasted.
//   - chooseModelForTools(query, hasTools=false, isAuthenticated=true ) →
//        delegates to legacy chooseModel(query) — keyword heuristic stays
//        unchanged for non-tool turns.
//   - simple greetings always → Haiku, even with tools+auth.
//
// Cost ceiling:
//   Sonnet ≈ $3/MTok in, $15/MTok out vs Haiku $0.80/$4. With interleaved
//   thinking ON for tool turns the marginal cost per turn rises ~$0.05.
//   Anon path is the critical seal — see
//   supabase/functions/claude-proxy/__tests__/interleaved_thinking_test.ts.
// =============================================================================

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/claude_service.dart';

void main() {
  group('ClaudeService.chooseModelForTools — auth+tools matrix', () {
    test('authenticated + tools + non-trivial query → Sonnet', () {
      // The tool flow needs room to think between calls; Sonnet handles
      // multi-step reasoning where Haiku tends to short-circuit.
      const q = 'I just got a deportation notice from the Ministry — '
          'can you check the appeal deadline for me?';
      expect(
        ClaudeService.chooseModelForTools(
          q,
          hasTools: true,
          isAuthenticated: true,
        ),
        ClaudeService.modelSonnet,
      );
    });

    test('authenticated + tools + medium-length non-legal query → Sonnet', () {
      // Non-legal but non-greeting, tools attached. Sonnet still wins —
      // assistant_tools may need a multi-step reasoning pass.
      const q = 'Can you help me figure out what document I need to sign';
      expect(
        ClaudeService.chooseModelForTools(
          q,
          hasTools: true,
          isAuthenticated: true,
        ),
        ClaudeService.modelSonnet,
      );
    });

    test('anon caller + tools → Haiku regardless of query', () {
      const q = 'I just got a deportation notice from the Ministry — '
          'can you check the appeal deadline for me?';
      expect(
        ClaudeService.chooseModelForTools(
          q,
          hasTools: true,
          isAuthenticated: false,
        ),
        ClaudeService.modelHaiku,
        reason: 'Anon callers must NEVER reach Sonnet — server clamps '
            'their max_tokens to 500 and refuses thinking. Sonnet \$ on '
            'them would be pure burn.',
      );
    });

    test('authenticated + simple greeting + tools → Haiku', () {
      // "hi", "ok", "thanks" go to Haiku regardless of tools — short
      // replies don't need Sonnet headroom and Haiku is 12x cheaper.
      for (final greet in ['hi', 'ok', 'thanks', 'привет', 'tere']) {
        expect(
          ClaudeService.chooseModelForTools(
            greet,
            hasTools: true,
            isAuthenticated: true,
          ),
          ClaudeService.modelHaiku,
          reason: 'Greeting "$greet" must stay on Haiku.',
        );
      }
    });

    test('authenticated + no tools → falls back to legacy chooseModel', () {
      // No tools attached → behaviour should match the legacy keyword
      // heuristic exactly. We pin this by parity, not by re-implementing it.
      const queries = [
        'hello',
        'What is the weather today?',
        'I need help with my deportation appeal. The court hearing is next week.',
        'Quick yes or no question',
      ];
      for (final q in queries) {
        expect(
          ClaudeService.chooseModelForTools(
            q,
            hasTools: false,
            isAuthenticated: true,
          ),
          ClaudeService.chooseModel(q),
          reason: 'No-tools path must be byte-equal to legacy chooseModel '
              'for query "${q.length > 40 ? '${q.substring(0, 40)}…' : q}"',
        );
      }
    });

    test('authenticated + short question with tools → Sonnet (not Haiku)', () {
      // Short, non-greeting, tools attached. Anthropic engineer's Gap #1
      // case: the model needs thinking room between tool calls.
      const q = 'Can you draft a quick appeal letter';
      expect(
        ClaudeService.chooseModelForTools(
          q,
          hasTools: true,
          isAuthenticated: true,
        ),
        ClaudeService.modelSonnet,
      );
    });
  });

  group('ClaudeService.chooseModel — RU stem coverage (2026-05-05)', () {
    // RU LLM quality quick-win: users write 'уволили'/'обжаловать'/'подал'
    // — those didn't match the previous keyword set ('увольн'/'обжалован'
    // alone), so RU turns under-routed to Sonnet vs EN equivalents.
    // Each test below uses a real-world long-form (>300 chars) RU sentence
    // with a single new stem; chooseModel must return Sonnet via the
    // `len > 300 && match >= 1` branch.
    String pad(String core) {
      // Pads to >300 chars without sprinkling other legal keywords.
      const filler = ' это очень длинное сообщение от пользователя который '
          'хочет подробно описать свою ситуацию и попросить помощи.';
      var s = core;
      while (s.length < 320) {
        s = '$s$filler';
      }
      return s;
    }

    final ruStemCases = <String, String>{
      'уволи (уволили)': 'Меня уволили вчера без предупреждения и я не понимаю что делать дальше.',
      'обжалов (обжаловать)': 'Я хочу обжаловать это постановление и не знаю с чего начать.',
      'подал (подал заявление)': 'Я подал заявление в полицию на работодателя за невыплату.',
      'выписк (выписка)': 'Мне нужна выписка из реестра для подтверждения моего адреса.',
      'нарушил (нарушил права)': 'Работодатель нарушил мои права и я хочу восстановить справедливость.',
      'вынес (вынес постановление)': 'Орган вынес постановление и я не согласен с этим выводом.',
      'депорт (депортировать)': 'Меня хотят депортировать после отказа в продлении статуса.',
      'компенсац (компенсация)': 'Мне положена компенсация за моральный вред который мне причинили.',
      'возмещ (возмещение)': 'Я требую возмещение убытков от ответчика по этому делу.',
      'жалоб (жалобу)': 'Я хочу подготовить жалобу на действия должностного лица в орган.',
    };

    ruStemCases.forEach((label, core) {
      test('RU stem "$label" routes long query → Sonnet', () {
        final q = pad(core);
        expect(q.length, greaterThan(300));
        expect(
          ClaudeService.chooseModel(q),
          ClaudeService.modelSonnet,
          reason: 'Long RU query containing "$label" must route to Sonnet '
              '(len=${q.length}). Stem missing from _complexKeywords?',
        );
      });
    });

    test('benign RU greeting still picks Haiku (regression guard)', () {
      // Make sure the new stems didn't accidentally widen the net for
      // ordinary thank-you / hello messages.
      const benign = 'Здравствуйте, спасибо';
      expect(
        ClaudeService.chooseModel(benign),
        ClaudeService.modelHaiku,
        reason: 'Plain greeting must stay on Haiku — adding RU stems '
            'must not regress the short-message Haiku path.',
      );
    });
  });

  group('ClaudeService.chooseModelForTools — invariants', () {
    test('isAuthenticated=false NEVER returns Sonnet', () {
      // Cost-control invariant. Iterate a battery of queries that would
      // route to Sonnet for an authenticated caller and assert all of
      // them land on Haiku for anon.
      final sonnetishQueries = <String>[
        'I need help with my deportation appeal',
        'court hearing is next week, what should I do',
        'I want to file a complaint against my employer for wrongful dismissal',
        '${'a' * 300} court',
      ];
      for (final q in sonnetishQueries) {
        expect(
          ClaudeService.chooseModelForTools(
            q,
            hasTools: true,
            isAuthenticated: false,
          ),
          ClaudeService.modelHaiku,
          reason: 'Anon must stay on Haiku for query: "${q.substring(0, q.length.clamp(0, 50))}…"',
        );
      }
    });
  });
}
