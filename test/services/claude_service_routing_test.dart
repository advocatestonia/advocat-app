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
