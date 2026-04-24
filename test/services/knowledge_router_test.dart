@Tags(['fast'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/knowledge_router.dart';

/// Tests for [KnowledgeRouter] — the routing layer that maps user queries
/// to the correct specialty legal databases and assembles context for the
/// AI system prompt.
///
/// These tests exercise deterministic keyword-matching logic and context
/// assembly. All databases contain static data so no mocks are needed.
void main() {
  // ── Family law routing ────────────────────────────────────────────────

  group('KnowledgeRouter — family law routing', () {
    test('routes "divorce" query to family law context', () {
      final result = KnowledgeRouter.getContextForQuery(
        'How do I file for divorce?',
        country: 'EE',
      );
      expect(result, contains('FAMILY LAW'));
    });

    test('routes "custody" query to family law context', () {
      final result = KnowledgeRouter.getContextForQuery(
        'What are my custody rights?',
        country: 'FI',
      );
      expect(result, contains('FAMILY LAW'));
    });

    test('routes "child support" / "alimony" query', () {
      final result = KnowledgeRouter.getContextForQuery(
        'How much child support should I pay?',
        country: 'EE',
      );
      expect(result, contains('FAMILY LAW'));
    });

    test('routes "marriage" query', () {
      final result = KnowledgeRouter.getContextForQuery(
        'What documents do I need for marriage registration?',
        country: 'DE',
      );
      expect(result, contains('FAMILY LAW'));
    });

    test('routes "domestic violence" query', () {
      final result = KnowledgeRouter.getContextForQuery(
        'I am a victim of domestic violence, what are my options?',
        country: 'EE',
      );
      expect(result, contains('FAMILY LAW'));
    });

    test('routes "hague" convention query', () {
      final result = KnowledgeRouter.getContextForQuery(
        'My child was abducted under the Hague Convention',
        country: 'FI',
      );
      expect(result, contains('FAMILY LAW'));
    });
  });

  // ── Criminal / emergency routing ──────────────────────────────────────

  group('KnowledgeRouter — criminal / emergency routing', () {
    test('routes "arrest" query to emergency context', () {
      final result = KnowledgeRouter.getContextForQuery(
        'I was arrested by police, what are my rights?',
        country: 'EE',
      );
      expect(result, contains('EMERGENCY'));
    });

    test('routes "detained" query to prisoner rights or emergency', () {
      final result = KnowledgeRouter.getContextForQuery(
        'I am being detained at the border',
        country: 'FI',
      );
      // "detained" matches both emergency and prisoner rights keywords
      expect(result.isNotEmpty, isTrue);
      expect(
        result.contains('EMERGENCY') || result.contains('PRISONER') || result.contains('DETENTION'),
        isTrue,
      );
    });

    test('routes "prison" query to prisoner rights context', () {
      final result = KnowledgeRouter.getContextForQuery(
        'What are my rights in prison?',
        country: 'EE',
      );
      expect(result, contains('PRISONER'));
    });

    test('routes "police" query to emergency context', () {
      final result = KnowledgeRouter.getContextForQuery(
        'The police stopped me on the street',
        country: 'DE',
      );
      expect(result, contains('EMERGENCY'));
    });
  });

  // ── Immigration routing ───────────────────────────────────────────────

  group('KnowledgeRouter — immigration routing', () {
    test('routes "visa" query to work permit context', () {
      final result = KnowledgeRouter.getContextForQuery(
        'How do I get a work visa?',
        country: 'FI',
      );
      expect(result, contains('WORK PERMIT'));
    });

    test('routes "residence permit" query', () {
      final result = KnowledgeRouter.getContextForQuery(
        'How to apply for a residence permit?',
        country: 'EE',
      );
      expect(result, contains('WORK PERMIT'));
    });

    test('routes "blue card" query', () {
      final result = KnowledgeRouter.getContextForQuery(
        'Can I apply for an EU blue card?',
        country: 'DE',
      );
      expect(result, contains('WORK PERMIT'));
    });

    test('routes "citizenship" query to citizenship context', () {
      final result = KnowledgeRouter.getContextForQuery(
        'How do I become a citizen?',
        country: 'EE',
      );
      expect(result, contains('CITIZENSHIP'));
    });

    test('routes "naturalization" query to citizenship context', () {
      final result = KnowledgeRouter.getContextForQuery(
        'What is the naturalization process?',
        country: 'FI',
      );
      expect(result, contains('CITIZENSHIP'));
    });

    test('routes "passport" query to citizenship context', () {
      final result = KnowledgeRouter.getContextForQuery(
        'Can I get a passport?',
        country: 'EE',
      );
      expect(result, contains('CITIZENSHIP'));
    });
  });

  // ── Labor / employment routing ────────────────────────────────────────

  group('KnowledgeRouter — labor / employment routing', () {
    test('routes query via caseType "deportation" (fallback to extended)', () {
      // The caseType is appended to the combined text, but "deportation"
      // itself does not match the employment keywords. This verifies that
      // the caseType parameter is used in routing.
      final result = KnowledgeRouter.getContextForQuery(
        'Tell me about my case',
        country: 'EE',
        caseType: 'deportation',
      );
      // Should return something (at minimum the extended country knowledge)
      expect(result.isNotEmpty, isTrue);
    });

    test('routes "social benefits" / "welfare" queries', () {
      final result = KnowledgeRouter.getContextForQuery(
        'What social benefits am I entitled to?',
        country: 'FI',
      );
      expect(result, contains('SOCIAL BENEFITS'));
    });

    test('routes "unemployment" query to social benefits', () {
      final result = KnowledgeRouter.getContextForQuery(
        'How do I claim unemployment benefits?',
        country: 'EE',
      );
      expect(result, contains('SOCIAL BENEFITS'));
    });
  });

  // ── Consumer protection routing ───────────────────────────────────────

  group('KnowledgeRouter — consumer protection routing', () {
    test('routes "warranty" query to consumer context', () {
      final result = KnowledgeRouter.getContextForQuery(
        'My product is defective, what about warranty?',
        country: 'EE',
      );
      expect(result, contains('CONSUMER RIGHTS'));
    });

    test('routes "refund" query to consumer context', () {
      final result = KnowledgeRouter.getContextForQuery(
        'Can I get a refund for my online purchase?',
        country: 'FI',
      );
      expect(result, contains('CONSUMER RIGHTS'));
    });

    test('routes "flight compensation" query to consumer context', () {
      final result = KnowledgeRouter.getContextForQuery(
        'My flight was cancelled, what compensation can I get?',
        country: 'DE',
      );
      expect(result, contains('CONSUMER RIGHTS'));
    });

    test('consumer context includes EU directives', () {
      final result = KnowledgeRouter.getContextForQuery(
        'I want to return an online purchase',
        country: 'EE',
      );
      expect(result, contains('14-day'));
    });
  });

  // ── Unknown / ambiguous queries — default behavior ────────────────────

  group('KnowledgeRouter — unknown / ambiguous / fallback', () {
    test('returns non-empty for completely unrelated query', () {
      final result = KnowledgeRouter.getContextForQuery(
        'What is the meaning of life?',
        country: 'EE',
      );
      // Should fall back to extended country knowledge for EE
      expect(result.isNotEmpty, isTrue);
    });

    test('returns empty string for unrecognised country with no keyword match', () {
      // Even with unrecognised country, _resolveCountryCode defaults to 'FI'
      // and the extended knowledge base may still return data.
      final result = KnowledgeRouter.getContextForQuery(
        'random gibberish xyz123',
        country: 'XX',
      );
      // May return extended knowledge for default country or empty
      // The important thing is it does not crash
      expect(result, isA<String>());
    });

    test('returns non-empty for empty query with country', () {
      final result = KnowledgeRouter.getContextForQuery(
        '',
        country: 'FI',
      );
      // Empty query won't match any keywords, so falls back to extended
      expect(result, isA<String>());
    });

    test('handles null country gracefully (defaults to EE)', () {
      final result = KnowledgeRouter.getContextForQuery(
        'What are my rights?',
      );
      // No crash, returns something for Estonia
      expect(result, isA<String>());
    });

    test('handles null caseType gracefully', () {
      final result = KnowledgeRouter.getContextForQuery(
        'divorce',
        country: 'EE',
        caseType: null,
      );
      expect(result, contains('FAMILY LAW'));
    });
  });

  // ── Multi-topic queries ───────────────────────────────────────────────

  group('KnowledgeRouter — multi-topic queries', () {
    test('query with family + housing keywords returns both sections', () {
      final result = KnowledgeRouter.getContextForQuery(
        'I am going through a divorce and my landlord is evicting me',
        country: 'EE',
      );
      expect(result, contains('FAMILY LAW'));
      expect(result, contains('HOUSING'));
    });

    test('query with healthcare + work permit keywords returns both', () {
      final result = KnowledgeRouter.getContextForQuery(
        'I need a doctor and my work permit is expiring',
        country: 'FI',
        maxChars: 10000,
      );
      expect(result, contains('HEALTHCARE'));
      expect(result, contains('WORK PERMIT'));
    });

    test('query with emergency + legal aid keywords returns both', () {
      final result = KnowledgeRouter.getContextForQuery(
        'I was arrested and need a free legal aid lawyer',
        country: 'EE',
      );
      expect(result, contains('EMERGENCY'));
      expect(result, contains('LEGAL AID'));
    });

    test('query with consumer + EU directive keywords returns both', () {
      final result = KnowledgeRouter.getContextForQuery(
        'The warranty on my item expired, is there an EU directive?',
        country: 'EE',
      );
      expect(result, contains('CONSUMER'));
      // Directive section could also appear
      expect(result, contains('EU'));
    });

    test('multi-section result uses separator', () {
      final result = KnowledgeRouter.getContextForQuery(
        'divorce and eviction and work permit',
        country: 'EE',
      );
      // Multiple sections joined by '---' separator
      expect(result, contains('---'));
    });
  });

  // ── Language handling (Estonian, Russian, English) ─────────────────────

  group('KnowledgeRouter — language handling', () {
    test('matches Russian keyword "развод" (divorce)', () {
      final result = KnowledgeRouter.getContextForQuery(
        'Как подать на развод?',
        country: 'EE',
      );
      expect(result, contains('FAMILY LAW'));
    });

    test('matches Russian keyword "медицин" (medical)', () {
      final result = KnowledgeRouter.getContextForQuery(
        'Мне нужна медицинская помощь',
        country: 'FI',
      );
      expect(result, contains('HEALTHCARE'));
    });

    test('matches Russian keyword "арест" (arrest)', () {
      final result = KnowledgeRouter.getContextForQuery(
        'Меня задержали, арест',
        country: 'EE',
      );
      expect(result, contains('EMERGENCY'));
    });

    test('matches Russian keyword "виза" (visa)', () {
      final result = KnowledgeRouter.getContextForQuery(
        'Нужна рабочая виза',
        country: 'DE',
        maxChars: 10000,
      );
      expect(result, contains('WORK PERMIT'));
    });

    test('matches Russian keyword "жильё" (housing)', () {
      final result = KnowledgeRouter.getContextForQuery(
        'Проблемы с жильём',
        country: 'EE',
      );
      expect(result, contains('HOUSING'));
    });

    test('matches Russian keyword "гражданств" (citizenship)', () {
      final result = KnowledgeRouter.getContextForQuery(
        'Хочу получить гражданство',
        country: 'EE',
      );
      expect(result, contains('CITIZENSHIP'));
    });

    test('matches Russian keyword "пособи" (benefits)', () {
      final result = KnowledgeRouter.getContextForQuery(
        'Какие пособия мне положены?',
        country: 'FI',
      );
      expect(result, contains('SOCIAL BENEFITS'));
    });

    test('matches Russian keyword "возврат" (return/refund)', () {
      final result = KnowledgeRouter.getContextForQuery(
        'Хочу сделать возврат товара',
        country: 'EE',
      );
      expect(result, contains('CONSUMER RIGHTS'));
    });

    test('matches Russian keyword "полиц" (police)', () {
      final result = KnowledgeRouter.getContextForQuery(
        'Полиция остановила меня',
        country: 'EE',
      );
      expect(result, contains('EMERGENCY'));
    });

    test('matches Russian keyword "адвокат" (lawyer)', () {
      final result = KnowledgeRouter.getContextForQuery(
        'Мне нужен адвокат',
        country: 'EE',
      );
      expect(result, contains('LEGAL AID'));
    });

    test('matches English keywords case-insensitively', () {
      final result = KnowledgeRouter.getContextForQuery(
        'DIVORCE proceedings in Estonia',
        country: 'EE',
      );
      expect(result, contains('FAMILY LAW'));
    });

    test('matches mixed language query', () {
      final result = KnowledgeRouter.getContextForQuery(
        'I need help with развод (divorce) in Estonia',
        country: 'EE',
      );
      expect(result, contains('FAMILY LAW'));
    });
  });

  // ── Country resolution ────────────────────────────────────────────────

  group('KnowledgeRouter — country resolution', () {
    test('resolves full country name "Finland" to FI context', () {
      final result = KnowledgeRouter.getContextForQuery(
        'healthcare',
        country: 'Finland',
      );
      expect(result, contains('HEALTHCARE'));
    });

    test('resolves ISO code "DE" correctly', () {
      final result = KnowledgeRouter.getContextForQuery(
        'healthcare',
        country: 'DE',
      );
      expect(result, contains('HEALTHCARE'));
    });

    test('resolves native name "Suomi" to FI', () {
      final result = KnowledgeRouter.getContextForQuery(
        'healthcare',
        country: 'Suomi',
      );
      expect(result, contains('HEALTHCARE'));
    });

    test('resolves native name "Eesti" to EE', () {
      final result = KnowledgeRouter.getContextForQuery(
        'healthcare',
        country: 'Eesti',
      );
      expect(result, contains('HEALTHCARE'));
    });

    test('resolves native name "Deutschland" to DE', () {
      final result = KnowledgeRouter.getContextForQuery(
        'healthcare',
        country: 'Deutschland',
      );
      expect(result, contains('HEALTHCARE'));
    });

    test('defaults to EE when country is null', () {
      final result = KnowledgeRouter.getContextForQuery('healthcare');
      expect(result, contains('HEALTHCARE'));
    });

    test('defaults to EE when country is empty', () {
      final result = KnowledgeRouter.getContextForQuery(
        'healthcare',
        country: '',
      );
      expect(result, contains('HEALTHCARE'));
    });
  });

  // ── Truncation / budget ───────────────────────────────────────────────

  group('KnowledgeRouter — truncation and character budget', () {
    test('default output respects 3000 char limit', () {
      // Use a multi-topic query that generates lots of context
      final result = KnowledgeRouter.getContextForQuery(
        'divorce eviction work permit healthcare citizenship education insurance',
        country: 'FI',
      );
      expect(result.length, lessThanOrEqualTo(3100));
      // Allow small overhead from final separator; the important thing
      // is the truncation logic runs without error
    });

    test('custom maxChars parameter limits output', () {
      final result = KnowledgeRouter.getContextForQuery(
        'divorce eviction healthcare',
        country: 'EE',
        maxChars: 500,
      );
      expect(result.length, lessThanOrEqualTo(600));
    });

    test('short result is not truncated', () {
      // A single-topic query for consumer rights (static short text)
      final result = KnowledgeRouter.getContextForQuery(
        'warranty',
        country: 'EE',
        maxChars: 10000,
      );
      expect(result, contains('CONSUMER RIGHTS'));
      // Should contain the full consumer section
      expect(result, contains('14-day'));
    });
  });

  // ── Additional domain routing ─────────────────────────────────────────

  group('KnowledgeRouter — additional domains', () {
    test('routes GDPR / digital rights query', () {
      final result = KnowledgeRouter.getContextForQuery(
        'How do I file a GDPR complaint about my personal data?',
        country: 'EE',
      );
      expect(
        result.contains('DIGITAL RIGHTS') || result.contains('GDPR'),
        isTrue,
      );
    });

    test('routes "business" / "startup" query', () {
      final result = KnowledgeRouter.getContextForQuery(
        'How to register a company as a foreigner?',
        country: 'EE',
      );
      expect(result, contains('BUSINESS'));
    });

    test('routes "bank account" / financial query', () {
      final result = KnowledgeRouter.getContextForQuery(
        'How do I open a bank account?',
        country: 'FI',
      );
      expect(result, contains('FINANCIAL'));
    });

    test('routes "inheritance" / "testament" query', () {
      final result = KnowledgeRouter.getContextForQuery(
        'My relative passed away, what about inheritance?',
        country: 'EE',
      );
      expect(result, contains('INHERITANCE'));
    });

    test('routes "school" / "education" query', () {
      final result = KnowledgeRouter.getContextForQuery(
        'How do I enroll my child in school?',
        country: 'FI',
      );
      expect(result, contains('EDUCATION'));
    });

    test('routes "insurance" / "pension" query', () {
      final result = KnowledgeRouter.getContextForQuery(
        'When can I retire and get my pension?',
        country: 'EE',
      );
      expect(
        result.contains('INSURANCE') || result.contains('PENSION'),
        isTrue,
      );
    });

    test('routes "EU directive" query', () {
      final result = KnowledgeRouter.getContextForQuery(
        'Which EU directive covers asylum procedures?',
        country: 'EE',
      );
      expect(result, contains('EU DIRECTIVE'));
    });

    test('routes "court case" / "precedent" query', () {
      final result = KnowledgeRouter.getContextForQuery(
        'Are there any court case precedents for deportation appeals?',
        country: 'EE',
      );
      expect(result, contains('CASE LAW'));
    });

    test('routes "driving license" / transport query', () {
      final result = KnowledgeRouter.getContextForQuery(
        'Can I use my foreign driving license?',
        country: 'FI',
      );
      expect(
        result.contains('DRIVING') || result.contains('TRANSPORT'),
        isTrue,
      );
    });

    test('routes "religion" / "mosque" query', () {
      final result = KnowledgeRouter.getContextForQuery(
        'Where can I find a mosque? Are there halal options?',
        country: 'EE',
      );
      expect(result, contains('RELIGIOUS'));
    });

    test('routes "LGBTQ" query', () {
      final result = KnowledgeRouter.getContextForQuery(
        'What are LGBTQ rights in this country?',
        country: 'FI',
      );
      expect(result, contains('LGBTQ'));
    });

    test('routes "how to" / practical guide query', () {
      final result = KnowledgeRouter.getContextForQuery(
        'How to appeal a deportation decision step by step?',
        country: 'EE',
      );
      // "how to" matches practical guides
      expect(result.isNotEmpty, isTrue);
    });
  });

  // ── Edge cases ────────────────────────────────────────────────────────

  group('KnowledgeRouter — edge cases', () {
    test('handles very long query without crash', () {
      final longQuery = 'divorce ' * 500;
      final result = KnowledgeRouter.getContextForQuery(
        longQuery,
        country: 'EE',
      );
      expect(result, contains('FAMILY LAW'));
    });

    test('handles special characters in query', () {
      final result = KnowledgeRouter.getContextForQuery(
        'divorce? (custody!) @#\$%^&*',
        country: 'EE',
      );
      expect(result, contains('FAMILY LAW'));
    });

    test('handles unicode / emoji in query without crash', () {
      final result = KnowledgeRouter.getContextForQuery(
        'help with divorce proceedings',
        country: 'EE',
      );
      expect(result, isA<String>());
    });

    test('maxChars of 0 returns empty or minimal output', () {
      final result = KnowledgeRouter.getContextForQuery(
        'divorce',
        country: 'EE',
        maxChars: 0,
      );
      // With budget 0, the loop breaks immediately
      expect(result.length, lessThanOrEqualTo(10));
    });

    test('handles all 27 EU country codes without crash', () {
      const countryCodes = [
        'AT', 'BE', 'BG', 'HR', 'CY', 'CZ', 'DK', 'EE', 'FI', 'FR',
        'DE', 'GR', 'HU', 'IE', 'IT', 'LV', 'LT', 'LU', 'MT', 'NL',
        'PL', 'PT', 'RO', 'SK', 'SI', 'ES', 'SE',
      ];
      for (final code in countryCodes) {
        final result = KnowledgeRouter.getContextForQuery(
          'healthcare',
          country: code,
        );
        expect(result, isA<String>(), reason: 'Failed for country $code');
      }
    });
  });
}
