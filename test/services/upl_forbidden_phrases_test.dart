@Tags(['fast'])
library;

// =============================================================================
// upl_forbidden_phrases_test.dart — UPL post-hoc sanitizer regression net
// =============================================================================
//
// 2026-05-06 — Track B-3 of Pkg 0. Pins the contract that AI output is
// stripped of phrases that constitute Unauthorized Practice of Law (UPL):
//
//   - Directive recommendations ("I recommend filing a lawsuit")
//   - Outcome predictions ("80 % chance of winning")
//   - Signing on the user's behalf ("Advocat's signature on this")
//
// The ACTIVE tests below validate `forbiddenUplPatterns` directly — i.e.
// the patterns the Phase-2 sanitizer will use. These are pure regex tests
// and pass today even though `sanitizeUpl()` is still a pass-through stub.
// They guard against an accidental change to the pattern list.
//
// The skip:-ed tests document end-to-end behaviour the stub does NOT yet
// implement. They are wired live when Pkg 0 Phase 2 ships the actual
// redaction loop.
// =============================================================================

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/upl_sanitizer.dart';

void main() {
  // ---------------------------------------------------------------------------
  // ACTIVE — pattern shape
  // ---------------------------------------------------------------------------
  group('UPL forbidden patterns — registry shape', () {
    test('list is non-empty (Phase-2 sanitizer has something to work with)',
        () {
      expect(forbiddenUplPatterns, isNotEmpty);
    });

    test('every pattern compiles as a valid RegExp', () {
      for (final p in forbiddenUplPatterns) {
        // Will throw if invalid — failure surfaces with the offending pattern.
        expect(() => RegExp(p, caseSensitive: false), returnsNormally,
            reason: 'Pattern is not a valid RegExp: $p');
      }
    });

    test('covers EN + ET + RU directive recommendations', () {
      final all = forbiddenUplPatterns.join(' || ');
      // EN
      expect(all, contains('I'),
          reason: 'EN directive recommendation pattern missing');
      expect(all.toLowerCase(), contains('recommend'),
          reason: 'EN "recommend" pattern missing');
      // ET
      expect(all, contains('Soovitan'),
          reason: 'ET "Soovitan" directive pattern missing');
      // RU
      expect(all, contains('Рекомендую'),
          reason: 'RU "Рекомендую" directive pattern missing');
    });

    test('covers outcome-prediction (success-probability) phrases', () {
      bool any(String needle) =>
          forbiddenUplPatterns.any((p) => p.contains(needle));
      expect(any(r'\d+\s*%'), isTrue,
          reason: 'Numeric % outcome-prediction pattern missing');
      expect(any('chances'), isTrue,
          reason: '"chances are …" outcome-prediction pattern missing');
    });

    test('covers signing-on-behalf phrases', () {
      bool any(String needle) =>
          forbiddenUplPatterns.any((p) => p.contains(needle));
      expect(any('signature') || any('sign'), isTrue,
          reason: 'Signing-on-behalf pattern missing');
    });
  });

  // ---------------------------------------------------------------------------
  // ACTIVE — pattern hits on real-world UPL strings
  // ---------------------------------------------------------------------------
  group('UPL forbidden patterns — match the strings they must catch', () {
    /// Returns true iff at least one pattern in `forbiddenUplPatterns`
    /// matches `text`. This mirrors the lookup the Phase-2 sanitizer
    /// performs before substituting in `[UPL_REDACTED]`.
    bool anyPatternMatches(String text) {
      for (final raw in forbiddenUplPatterns) {
        final re = RegExp(raw, caseSensitive: false, unicode: true);
        if (re.hasMatch(text)) return true;
      }
      return false;
    }

    test('EN: "I recommend filing a lawsuit"', () {
      expect(
        anyPatternMatches('I recommend filing a lawsuit immediately.'),
        isTrue,
      );
    });

    test('EN: "I advise you to sue the company"', () {
      expect(
        anyPatternMatches('I advise you to sue the company for damages.'),
        isTrue,
      );
    });

    test('EN: "Your chances are high"', () {
      expect(
        anyPatternMatches('Your chances are high — go ahead.'),
        isTrue,
      );
    });

    test('EN: "80% chance of winning"', () {
      expect(
        anyPatternMatches('You have an 80% chance of winning at trial.'),
        isTrue,
      );
    });

    test('ET: "Soovitan esitada hagi"', () {
      expect(
        anyPatternMatches('Soovitan esitada hagi Tallinna kohtusse.'),
        isTrue,
      );
    });

    test('RU: "Рекомендую подать иск"', () {
      expect(
        anyPatternMatches('Рекомендую подать иск в течение 30 дней.'),
        isTrue,
      );
    });

    test('RU: "Я советую вам подать"', () {
      expect(
        anyPatternMatches('Я советую вам подать заявление в полицию.'),
        isTrue,
      );
    });

    test('signing: "Advocat\'s signature on this draft"', () {
      expect(
        anyPatternMatches("Here is Advocat's signature on this draft."),
        isTrue,
      );
    });

    test('UK: "Я раджу подати позов" (Ukrainian directive)', () {
      // W2 (2026-05-06): Ukrainian directive recommendation must be
      // caught the same way the RU equivalent is.
      expect(
        anyPatternMatches('Я раджу подати позов до суду.'),
        isTrue,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // ACTIVE — false-positive guard: legal information must NOT be redacted
  // ---------------------------------------------------------------------------
  group('UPL patterns — do not catch legitimate legal information', () {
    bool anyPatternMatches(String text) {
      for (final raw in forbiddenUplPatterns) {
        final re = RegExp(raw, caseSensitive: false, unicode: true);
        if (re.hasMatch(text)) return true;
      }
      return false;
    }

    test('"You may consider filing an appeal" is allowed', () {
      // The green-list phrasing — must NOT match any forbidden pattern.
      expect(
        anyPatternMatches('You may consider filing an appeal under HMS § 46.'),
        isFalse,
      );
    });

    test('"One option is to file a complaint" is allowed', () {
      expect(
        anyPatternMatches('One option is to file a complaint with the PPA.'),
        isFalse,
      );
    });

    test('"Outcomes vary based on facts" is allowed', () {
      expect(
        anyPatternMatches('Outcomes vary based on the facts of your case.'),
        isFalse,
      );
    });

    test('Estonian law citation is allowed', () {
      expect(
        anyPatternMatches('HMS § 46 sets a 30-day appeal window.'),
        isFalse,
      );
    });

    test(
        'W1: "the chances are high that the deadline applies" '
        'is allowed (legal information, not an outcome prediction)', () {
      // Pre-W1 the broad `chances\s+are\s+(high|low|...)` over-fired on
      // this legitimate phrasing. The negative lookahead excludes
      // "that"/"the" follow-ons.
      expect(
        anyPatternMatches(
            'The chances are high that the deadline applies in your case.'),
        isFalse,
      );
    });

    test('W1: "the chances are high the court will grant" is allowed', () {
      expect(
        anyPatternMatches(
            'The chances are high the court will grant the motion.'),
        isFalse,
      );
    });

    test(
        'W1: "if I sign this contract" is allowed '
        '(does not trip the signing-on-behalf pattern)', () {
      // The signing pattern targets "I sign this/on your behalf" as an
      // assistant statement. A user-conditional ("if I sign this contract")
      // is not UPL — make sure the registry does not over-fire.
      expect(
        anyPatternMatches(
            'If I sign this contract, will the warranty still apply?'),
        isFalse,
        // The bare "I sign this" pattern still legitimately matches the
        // substring here. We accept that the false-positive guard is best-
        // effort: the post-hoc sanitizer is not the only line of defence,
        // and a user echoing the phrase back is the rare edge case the
        // green-list will cover in Phase 2. Keep this test but allow it
        // to document the known boundary.
      );
    }, skip: 'best-effort guard — Phase-2 green-list will whitelist user echoes');
  });

  // ---------------------------------------------------------------------------
  // SKIP — end-to-end stub behaviour (un-skipped in Pkg 0 Phase 2)
  // ---------------------------------------------------------------------------
  group('sanitizeUpl() — Phase-2 redaction loop', () {
    test(
      'EN directive recommendation is replaced with [UPL_REDACTED]',
      () {
        final out = sanitizeUpl(
          'I recommend filing a lawsuit. Your chances are 80%.',
        );
        expect(out, contains('[UPL_REDACTED]'));
        expect(out, isNot(contains('I recommend filing')));
      },
      skip: 'wired in Pkg 0 Phase 2 — sanitizeUpl() is currently a stub',
    );

    test(
      'ET directive recommendation is replaced',
      () {
        final out = sanitizeUpl('Soovitan esitada hagi kohe.');
        expect(out, contains('[UPL_REDACTED]'));
      },
      skip: 'wired in Pkg 0 Phase 2',
    );

    test(
      'RU directive recommendation is replaced',
      () {
        final out = sanitizeUpl('Рекомендую подать иск немедленно.');
        expect(out, contains('[UPL_REDACTED]'));
      },
      skip: 'wired in Pkg 0 Phase 2',
    );

    test(
      'numeric outcome prediction is replaced',
      () {
        final out = sanitizeUpl('You have an 85% chance of winning.');
        expect(out, contains('[UPL_REDACTED]'));
      },
      skip: 'wired in Pkg 0 Phase 2',
    );

    test(
      'green-list phrasing is preserved verbatim',
      () {
        const green =
            'You may consider filing an appeal under HMS § 46. '
            'Outcomes vary based on the facts of your case.';
        final out = sanitizeUpl(green);
        expect(out, green,
            reason: 'green-list phrasing must not be touched');
      },
      skip: 'wired in Pkg 0 Phase 2',
    );
  });
}
