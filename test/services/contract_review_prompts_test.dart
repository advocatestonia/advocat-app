@Tags(['fast'])
library;

// =============================================================================
// contract_review_prompts_test.dart — pins the composable Contract Review
// prompt modules.
// =============================================================================
//
// Each module is tested in isolation; the orchestrator is tested at the
// bottom. These tests are the contract between the prompt layer and the
// Typst rendering worker — break them and the PDF stops rendering, so
// changes here require a deliberate version bump in the prompt module.
// =============================================================================

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/contract_review_prompts.dart';

void main() {
  group('pickContractReviewVersion', () {
    test('defaults to v1.0 when env var unset', () {
      // envOverride: '' simulates an unset / empty env var. Platform.environment
      // is best-effort on web; we exercise the override path here.
      expect(pickContractReviewVersion(envOverride: ''),
          equals(kContractReviewPromptVersionDefault));
    });

    test('accepts a known version override', () {
      expect(pickContractReviewVersion(envOverride: 'v1.0'), equals('v1.0'));
    });

    test('falls back to default for unknown version', () {
      expect(pickContractReviewVersion(envOverride: 'v9.9-experimental'),
          equals(kContractReviewPromptVersionDefault));
    });
  });

  group('buildJurisdictionContext', () {
    test('returns non-empty fragment for known jurisdictions', () {
      final out = buildJurisdictionContext(['DE']);
      expect(out, isNotEmpty);
      expect(out.length, greaterThan(100));
    });

    test('includes BGB toolkit for German contracts', () {
      final out = buildJurisdictionContext(['DE']);
      expect(out, contains('BGB'));
      expect(out, contains('HGB'));
      expect(out, contains('AGB-Kontrolle'));
      expect(out, contains('§ 84'));
      expect(out, contains('§ 377'));
    });

    test('includes BGB toolkit for AT and CH too', () {
      expect(buildJurisdictionContext(['AT']), contains('BGB'));
      expect(buildJurisdictionContext(['CH']), contains('BGB'));
    });

    test('includes UCC toolkit for US contracts', () {
      final out = buildJurisdictionContext(['US']);
      expect(out, contains('UCC'));
      expect(out, contains('§ 2-207'));
      // "common-law" (hyphenated) is the canonical spelling we use.
      expect(out, contains('common-law'));
    });

    test('includes UK common-law toolkit', () {
      final out = buildJurisdictionContext(['UK']);
      expect(out, contains('Sale of Goods Act 1979'));
      expect(out, contains('Hadley v. Baxendale'));
    });

    test('includes GDPR + CISG when EU is declared', () {
      final out = buildJurisdictionContext(['EU']);
      expect(out, contains('GDPR'));
      expect(out, contains('Brussels I'));
      expect(out, contains('CISG'));
    });

    test('stacks multiple families when several jurisdictions supplied', () {
      final out = buildJurisdictionContext(['DE', 'EU']);
      expect(out, contains('BGB'));
      expect(out, contains('GDPR'));
    });

    test('falls back to generic when no jurisdictions supplied', () {
      final out = buildJurisdictionContext(<String>[]);
      expect(out, contains('Generic toolkit'));
    });

    test('falls back to generic on unknown tag', () {
      final out = buildJurisdictionContext(['ZZ']);
      expect(out, contains('Generic toolkit'));
    });

    test('is case-insensitive for jurisdiction tags', () {
      final lower = buildJurisdictionContext(['de']);
      final upper = buildJurisdictionContext(['DE']);
      expect(lower, equals(upper));
    });

    test('output is well below the 30 KB module budget', () {
      // Worst case: all families stacked.
      final out = buildJurisdictionContext(['DE', 'US', 'UK', 'EU']);
      expect(out.length, lessThan(30 * 1024));
    });
  });

  group('buildRiskTaxonomy', () {
    test('returns non-empty base taxonomy without industry', () {
      final out = buildRiskTaxonomy();
      expect(out, isNotEmpty);
      expect(out, contains('CRITICAL'));
      expect(out, contains('HIGH'));
      expect(out, contains('MEDIUM'));
      expect(out, contains('INFO'));
      expect(out, contains('GOOD'));
    });

    test('lists all five categories', () {
      final out = buildRiskTaxonomy();
      expect(out, contains('Commercial'));
      expect(out, contains('Legal'));
      expect(out, contains('Warranty'));
      expect(out, contains('IP & data'));
      expect(out, contains('Operational'));
    });

    test('adds dealer module when industry=dealer', () {
      final out = buildRiskTaxonomy(industry: 'dealer');
      expect(out, contains('dealer'));
      expect(out, contains('Ausgleichsanspruch'));
    });

    test('adds SaaS module when industry=saas', () {
      final out = buildRiskTaxonomy(industry: 'saas');
      expect(out, contains('SaaS'));
      expect(out, contains('SLA'));
      expect(out, contains('Sub-processors'));
    });

    test('adds NDA module when industry=nda', () {
      final out = buildRiskTaxonomy(industry: 'nda');
      expect(out, contains('NDA'));
      // Case-insensitive match: source is "Residual-knowledge".
      expect(out.toLowerCase(), contains('residual'));
    });

    test('adds employment module when industry=employment', () {
      final out = buildRiskTaxonomy(industry: 'employment');
      expect(out, contains('Probation'));
      expect(out, contains('Non-compete'));
    });

    test('adds M&A module when industry=m&a', () {
      final out = buildRiskTaxonomy(industry: 'm&a');
      expect(out, contains('Reps & warranties'));
      expect(out, contains('MAC'));
    });

    test('adds real-estate module when industry=real_estate', () {
      final out = buildRiskTaxonomy(industry: 'real_estate');
      expect(out, contains('Rent indexation'));
    });

    test('unknown industry tag is a no-op (does not throw)', () {
      expect(() => buildRiskTaxonomy(industry: 'space-mining'), returnsNormally);
      final out = buildRiskTaxonomy(industry: 'space-mining');
      // Still contains the base taxonomy.
      expect(out, contains('CRITICAL'));
    });

    test('output is under the 30 KB module budget', () {
      final out = buildRiskTaxonomy(industry: 'm&a');
      expect(out.length, lessThan(30 * 1024));
    });
  });

  group('buildContractAnalysisCore', () {
    test('returns non-empty fragment', () {
      final out = buildContractAnalysisCore('en');
      expect(out, isNotEmpty);
      expect(out.length, greaterThan(500));
    });

    test('forbids the verb "sign"', () {
      final out = buildContractAnalysisCore('en');
      // The prompt explicitly enumerates forbidden verbs.
      expect(out, contains('"sign"'));
      expect(out, contains('NEVER'));
    });

    test('lists allowed verbs', () {
      final out = buildContractAnalysisCore('en');
      expect(out, contains('flag'));
      expect(out, contains('suggest'));
      expect(out, contains('propose alternative wording'));
    });

    test('always mentions Advocat AI as the byline (never personal name)', () {
      final out = buildContractAnalysisCore('en');
      expect(out, contains('Advocat AI'));
      expect(out, contains('Asianajajaliitto'));
      expect(out, contains('Advokatuur'));
    });

    test('emits the strict JSON schema for the Typst worker', () {
      final out = buildContractAnalysisCore('en');
      expect(out, contains('"cover"'));
      expect(out, contains('"summary"'));
      expect(out, contains('"translation"'));
      expect(out, contains('"checklist"'));
      expect(out, contains('"email_to_counterparty"'));
      expect(out, contains('CRITICAL|HIGH|MEDIUM|INFO|GOOD'));
    });

    test('includes the localised disclaimer footer for the output language', () {
      final etOut = buildContractAnalysisCore('et');
      expect(etOut, contains('Informatiivne analüüs'));
      expect(etOut, contains('Advocat OÜ ei vastuta otsuste eest'));

      final ruOut = buildContractAnalysisCore('ru');
      expect(ruOut, contains('Информационный анализ'));

      final deOut = buildContractAnalysisCore('de');
      expect(deOut, contains('Informative Analyse'));
    });

    test('falls back to English disclaimer for unknown language', () {
      final out = buildContractAnalysisCore('xx');
      expect(out, contains('Informational analysis only'));
    });

    test('all 17 advertised languages resolve a disclaimer', () {
      const langs = <String>[
        'en', 'ru', 'et', 'fi', 'de', 'sv', 'fr', 'es', 'it', 'pl',
        'ar', 'tr', 'uk', 'lv', 'lt', 'ro', 'fa',
      ];
      for (final l in langs) {
        expect(kContractReviewDisclaimers.containsKey(l), isTrue,
            reason: 'missing disclaimer for $l');
        final out = buildContractAnalysisCore(l);
        expect(out, contains(kContractReviewDisclaimers[l]!),
            reason: '$l disclaimer not embedded');
      }
    });

    test('NEVER uses the string "B2B" in any output language', () {
      const langs = <String>['en', 'ru', 'et', 'fi', 'de'];
      for (final l in langs) {
        final out = buildContractAnalysisCore(l);
        expect(out.contains('B2B'), isFalse,
            reason: '"B2B" leaked into core prompt for $l');
      }
    });

    test('output is under the 30 KB module budget', () {
      final out = buildContractAnalysisCore('en');
      expect(out.length, lessThan(30 * 1024));
    });
  });

  group('buildEmailDraftAddendum', () {
    test('returns non-empty fragment', () {
      final out = buildEmailDraftAddendum('de');
      expect(out, isNotEmpty);
    });

    test('instructs to use original language not output language', () {
      final out = buildEmailDraftAddendum('de');
      expect(out, contains('ORIGINAL'));
      expect(out, contains('de'));
      // Anti-regression: the addendum must not bind to the user's reading
      // language. It is exclusively about the contract's own language.
      expect(out, contains('Do NOT translate'));
    });

    test('requires 3-5 clause-specific numbered questions', () {
      final out = buildEmailDraftAddendum('en');
      expect(out, contains('3 to 5'));
      expect(out, contains('numbered'));
      expect(out, contains('clause'));
    });

    test('forbids loaded language in the email', () {
      final out = buildEmailDraftAddendum('en');
      expect(out, contains('unfair'));
      expect(out, contains('never'));
    });

    test('leaves the signature line as a placeholder', () {
      final out = buildEmailDraftAddendum('en');
      expect(out, contains('[Name]'));
    });

    test('output is under the 30 KB module budget', () {
      final out = buildEmailDraftAddendum('de');
      expect(out.length, lessThan(30 * 1024));
    });
  });

  group('buildContractReviewPrompt orchestrator', () {
    test('assembles all modules into one prompt', () {
      final out = buildContractReviewPrompt(
        jurisdictions: ['DE', 'EU'],
        outputLanguage: 'ru',
        originalLanguage: 'de',
        industry: 'dealer',
      );
      // Header
      expect(out, contains('FEATURE: Contract Review'));
      expect(out,
          contains('CONTRACT_REVIEW_PROMPT_VERSION: $kContractReviewPromptVersionDefault'));
      // Jurisdictions
      expect(out, contains('BGB'));
      expect(out, contains('GDPR'));
      // Risk taxonomy
      expect(out, contains('CRITICAL'));
      expect(out, contains('Ausgleichsanspruch'));
      // Core
      expect(out, contains('Advocat AI'));
      // Email addendum
      expect(out, contains('ORIGINAL'));
    });

    test('embeds the user-language disclaimer in the assembled prompt', () {
      final ru = buildContractReviewPrompt(
        jurisdictions: ['DE'],
        outputLanguage: 'ru',
        originalLanguage: 'de',
      );
      expect(ru, contains('Информационный анализ'));
    });

    test('respects the version override', () {
      final out = buildContractReviewPrompt(
        jurisdictions: ['EU'],
        outputLanguage: 'en',
        originalLanguage: 'en',
        version: 'v1.0',
      );
      expect(out, contains('CONTRACT_REVIEW_PROMPT_VERSION: v1.0'));
    });

    test('never leaks the string "B2B" anywhere in the assembled output', () {
      final out = buildContractReviewPrompt(
        jurisdictions: ['DE', 'EU'],
        outputLanguage: 'ru',
        originalLanguage: 'de',
        industry: 'dealer',
      );
      expect(out.contains('B2B'), isFalse,
          reason: '"B2B" must be an internal-only term; never user-facing');
    });

    test('total assembled prompt stays under 120 KB shared budget', () {
      final out = buildContractReviewPrompt(
        jurisdictions: ['DE', 'US', 'UK', 'EU'],
        outputLanguage: 'ru',
        originalLanguage: 'de',
        industry: 'm&a',
      );
      expect(out.length, lessThan(120 * 1024),
          reason: 'Composite prompt must fit under combined 120 KB budget');
    });
  });
}
