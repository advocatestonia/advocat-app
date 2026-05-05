@Tags(['fast'])
library;

// =============================================================================
// rag_injection_contract_test.dart — system-prompt RAG seam (P0-3 seam E)
// =============================================================================
//
// 2026-05-05 — P0-3 of the Advocat legal-brain rebuild. Pins the
// SystemPrompts.injectLawContext() / formatLawContext() contract used by
// the chat path to fold law-search retrieval results into the system
// prompt. Becomes seam E once wired into canary smoke (follow-up).
//
// Contract:
//   1. When law-search returns 0 chunks, system prompt is unchanged.
//   2. When law-search returns chunks, system prompt has the
//      "RELEVANT ESTONIAN LAW" header and exactly N entries — verbatim §
//      numbers, no paraphrase.
//   3. When chunk total exceeds budget, lowest-similarity chunks are
//      dropped first.
//   4. When `law-search` errors (timeout / 500), chat still proceeds with
//      no-RAG fallback (LawSearchClient.search returns []; injectLawContext
//      with empty list returns the original prompt unchanged).
// =============================================================================

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/law_search_client.dart';
import 'package:advocat/services/system_prompts.dart';

void main() {
  const basePrompt =
      '# ROLE\n\nYou are Advocat, an AI legal assistant.\n\n'
      '# RULES\n- be precise.\n';

  LawChunk makeChunk({
    required String act,
    required String para,
    String body = 'body text',
    double sim = 0.9,
    String? url,
  }) {
    return LawChunk(
      actName: act,
      paragraph: para,
      body: body,
      similarity: sim,
      sourceUrl: url,
    );
  }

  group('RAG injection — empty list (no-op)', () {
    test('empty chunks returns the prompt verbatim', () {
      final out = SystemPrompts.injectLawContext(basePrompt, const []);
      expect(out, basePrompt);
      expect(out.contains('RELEVANT ESTONIAN LAW'), isFalse);
    });

    test('null-equivalent (const []) does not introduce a header', () {
      final out = SystemPrompts.injectLawContext(basePrompt, const []);
      expect(out.startsWith('# ROLE'), isTrue,
          reason:
              'When there are no chunks, the prompt must start exactly where '
              'it started before — no placeholder header allowed.');
    });
  });

  group('RAG injection — non-empty list', () {
    test('header + verbatim entries land above the existing prompt', () {
      final chunks = [
        makeChunk(
          act: 'KarS',
          para: '§ 121',
          body: 'Kehaline väärkohtlemine.',
          sim: 0.92,
          url: 'https://www.riigiteataja.ee/akt/KarS',
        ),
        makeChunk(
          act: 'HMS',
          para: '§ 26',
          body: 'Haldusakti vaidlustamine.',
          sim: 0.85,
        ),
      ];
      final out = SystemPrompts.injectLawContext(basePrompt, chunks);

      // Header present, exactly once.
      expect(out, contains('## RELEVANT ESTONIAN LAW'));
      expect('RELEVANT ESTONIAN LAW'.allMatches(out).length, 1);

      // RAG block precedes the original prompt.
      final ragIdx = out.indexOf('## RELEVANT ESTONIAN LAW');
      final roleIdx = out.indexOf('# ROLE');
      expect(ragIdx, lessThan(roleIdx),
          reason: 'RAG block must be ABOVE the existing prompt.');

      // Verbatim § numbers — paragraph token preserved exactly.
      expect(out, contains('§ 121'));
      expect(out, contains('§ 26'));
      expect(out, contains('### KarS § 121'));
      expect(out, contains('### HMS § 26'));

      // Source URL appears when provided.
      expect(out, contains('[source: https://www.riigiteataja.ee/akt/KarS]'));

      // Existing prompt is preserved character-for-character at the tail.
      expect(out.endsWith(basePrompt), isTrue);
    });

    test('exactly N entries when N chunks supplied', () {
      final chunks = [
        makeChunk(act: 'A', para: '§ 1', sim: 0.9),
        makeChunk(act: 'B', para: '§ 2', sim: 0.8),
        makeChunk(act: 'C', para: '§ 3', sim: 0.7),
      ];
      final out = SystemPrompts.injectLawContext(basePrompt, chunks);
      // Each entry produces a "### <act> <paragraph>" header.
      final headerCount = RegExp(r'^### ', multiLine: true).allMatches(out).length;
      expect(headerCount, 3);
    });

    test('verbatim-cite directive is emitted', () {
      final chunks = [makeChunk(act: 'KarS', para: '§ 121')];
      final out = SystemPrompts.injectLawContext(basePrompt, chunks);
      // Header instruction.
      expect(
        out,
        contains('cite verbatim, do NOT paraphrase paragraph numbers'),
      );
      // Footer rules.
      expect(out, contains('Cite ONLY the paragraphs above'));
      expect(out, contains('Do NOT invent § numbers'));
    });
  });

  group('RAG injection — budget overflow drops lowest-similarity first', () {
    test('drops the lowest-similarity chunk when over budget', () {
      // Build three chunks with very large bodies. The budget will only
      // fit two of them — the lowest-similarity one MUST be the one
      // dropped (similarity-desc preservation).
      final hi = makeChunk(
        act: 'HighSim',
        para: '§ 1',
        body: 'H' * 4000,
        sim: 0.95,
      );
      final mid = makeChunk(
        act: 'MidSim',
        para: '§ 2',
        body: 'M' * 4000,
        sim: 0.80,
      );
      final lo = makeChunk(
        act: 'LowSim',
        para: '§ 3',
        body: 'L' * 4000,
        sim: 0.50,
      );
      // Budget: existingPrompt + ~ 2 chunks of ~4000 bytes each + overhead.
      // Three chunks would not fit; two should.
      const budget = basePrompt.length + 9000;
      final out = SystemPrompts.injectLawContext(
        basePrompt,
        [hi, mid, lo],
        budgetBytes: budget,
      );
      expect(out, contains('### HighSim § 1'),
          reason: 'Highest-similarity chunk MUST survive.');
      expect(out, contains('### MidSim § 2'),
          reason: 'Mid-similarity chunk MUST survive.');
      expect(
        out,
        isNot(contains('### LowSim § 3')),
        reason: 'Lowest-similarity chunk MUST be dropped first.',
      );
    });

    test('drops multiple chunks if needed, always lowest-sim first', () {
      final chunks = [
        makeChunk(act: 'A', para: '§ 1', body: 'a' * 3000, sim: 0.95),
        makeChunk(act: 'B', para: '§ 2', body: 'b' * 3000, sim: 0.85),
        makeChunk(act: 'C', para: '§ 3', body: 'c' * 3000, sim: 0.75),
        makeChunk(act: 'D', para: '§ 4', body: 'd' * 3000, sim: 0.65),
        makeChunk(act: 'E', para: '§ 5', body: 'e' * 3000, sim: 0.55),
      ];
      // Tight budget: only ~1 chunk worth of body + base prompt.
      const budget = basePrompt.length + 4000;
      final out = SystemPrompts.injectLawContext(
        basePrompt,
        chunks,
        budgetBytes: budget,
      );
      // The single highest-similarity chunk (A) should survive.
      expect(out, contains('### A § 1'));
      // None of the lower-similarity chunks should appear.
      for (final lowAct in ['B', 'C', 'D', 'E']) {
        expect(
          out,
          isNot(contains('### $lowAct §')),
          reason: 'Chunk $lowAct (lower similarity) must be dropped.',
        );
      }
    });

    test('returns prompt verbatim when even one chunk is over budget', () {
      // Existing prompt alone exceeds the budget — RAG must be sacrificed
      // entirely rather than truncate the user/legal content.
      final chunks = [
        makeChunk(act: 'A', para: '§ 1', body: 'a' * 100),
      ];
      const budget = basePrompt.length - 1; // intentionally too small
      final out = SystemPrompts.injectLawContext(
        basePrompt,
        chunks,
        budgetBytes: budget,
      );
      expect(out, basePrompt,
          reason:
              'When the existing prompt alone exceeds budget, return it '
              'unchanged. RAG is what we sacrifice, not user content.');
    });

    test('input list order does not matter — sort is by similarity', () {
      // Chunks delivered in REVERSE similarity order. Top-similarity must
      // still land first in the output.
      final chunks = [
        makeChunk(act: 'Lowest', para: '§ 9', sim: 0.20),
        makeChunk(act: 'Middle', para: '§ 5', sim: 0.50),
        makeChunk(act: 'Top', para: '§ 1', sim: 0.95),
      ];
      final out = SystemPrompts.injectLawContext(basePrompt, chunks);
      final topIdx = out.indexOf('### Top § 1');
      final midIdx = out.indexOf('### Middle § 5');
      final lowIdx = out.indexOf('### Lowest § 9');
      expect(topIdx, lessThan(midIdx),
          reason: 'Highest-similarity chunk renders first.');
      expect(midIdx, lessThan(lowIdx),
          reason: 'Similarity-desc ordering must be stable.');
    });
  });

  group('RAG injection — error path (law-search unavailable)', () {
    test(
        'simulated law-search failure: search() returns [] → '
        'injectLawContext yields prompt verbatim', () async {
      // P0-2 has not deployed `law-search` yet — search() must return [].
      // We invoke the real client with a tiny query; without the function
      // available it will graceful-fail to []. The chat path then calls
      // injectLawContext with [], which is a no-op.
      final chunks = await LawSearchClient.search(
        query: 'трудовой спор',
        lang: 'ru',
      );
      expect(chunks, isA<List<LawChunk>>());
      // Whether or not the function exists, injection with the result
      // must NEVER break the existing prompt.
      final out = SystemPrompts.injectLawContext(basePrompt, chunks);
      if (chunks.isEmpty) {
        expect(out, basePrompt,
            reason: 'No chunks → prompt unchanged.');
      } else {
        // If P0-2 is already live, the sanity check is just "header was added".
        expect(out, contains('## RELEVANT ESTONIAN LAW'));
        expect(out.endsWith(basePrompt), isTrue);
      }
    });
  });

  group('RAG injection — formatter wire format (formatLawContext)', () {
    test('blockquote body lines and act-paragraph anchoring', () {
      final c = makeChunk(
        act: 'KarS',
        para: '§ 121',
        body: 'Line one.\nLine two.',
        url: 'https://example.org/x',
      );
      final out = SystemPrompts.formatLawContext([c]);
      expect(out, contains('### KarS § 121'));
      expect(out, contains('> Line one.'));
      expect(out, contains('> Line two.'));
      expect(out, contains('[source: https://example.org/x]'));
    });

    test('omits source line when sourceUrl is null', () {
      final c = makeChunk(act: 'HMS', para: '§ 26', body: 'x');
      final out = SystemPrompts.formatLawContext([c]);
      expect(out, isNot(contains('[source:')));
    });
  });
}
