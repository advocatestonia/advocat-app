import 'package:advocat/features/case_memory/models/user_case.dart';
import 'package:advocat/features/case_memory/services/intake_greeting_service.dart';
import 'package:advocat/features/case_memory/state/intake_wizard_state.dart';
import 'package:flutter_test/flutter_test.dart';

UserCase _mkCase({
  String id = 'c-1',
  String jurisdiction = 'FI',
  String? caseType = 'immigration',
  String language = 'ru',
}) {
  final now = DateTime.utc(2026, 5, 5);
  return UserCase(
    id: id,
    userId: 'user-1',
    title: 'Test case',
    jurisdiction: jurisdiction,
    caseType: caseType,
    language: language,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('buildPrompt', () {
    test('embeds case fields and draft details', () {
      final svc = IntakeGreetingService(
        send: ({required messages, required systemPrompt, int maxTokens = 400, String? model}) async => 'unused',
        save: ({required caseId, required role, required content}) async {},
      );
      final draft = IntakeDraft(
        jurisdiction: 'FI',
        authorityType: IntakeAuthorityType.police,
        authorityName: 'Itä-Uudenmaan poliisi',
        caseType: IntakeCaseType.criminal,
        userRole: IntakeUserRole.victim,
        opposingSide: 'unknown suspect',
        witnesses: const ['Anna'],
        caseNumber: 'R/123/45',
        incidentDate: DateTime.utc(2025, 8, 30),
        deadlines: [
          IntakeDeadline(what: 'Appeal', date: DateTime.utc(2026, 1, 4)),
        ],
      );
      final prompt = svc.buildPrompt(
        userCase: _mkCase(),
        draft: draft,
        uploadedFilenames: const ['epicrisis.pdf'],
        documentSummaries: const ['Esitutkintapöytäkirja, 35 pages'],
      );

      // System prompt encodes language + register expectations.
      expect(prompt.systemPrompt, contains('"ru"'));
      expect(prompt.systemPrompt, contains('2–3 sentences'));

      // User message carries the case + every captured draft field.
      expect(prompt.userMessage, contains('Jurisdiction: FI'));
      expect(prompt.userMessage, contains('Authority: police'));
      expect(prompt.userMessage, contains('Itä-Uudenmaan poliisi'));
      expect(prompt.userMessage, contains('User role: victim'));
      expect(prompt.userMessage, contains('Opposing side: unknown suspect'));
      expect(prompt.userMessage, contains('Witnesses: Anna'));
      expect(prompt.userMessage, contains('R/123/45'));
      expect(prompt.userMessage, contains('2025-08-30'));
      expect(prompt.userMessage, contains('Appeal'));
      expect(prompt.userMessage, contains('2026-01-04'));
      expect(prompt.userMessage, contains('epicrisis.pdf'));
      expect(prompt.userMessage, contains('Esitutkintapöytäkirja'));
    });

    test('urgent shortcut surfaces in system prompt and case summary', () {
      final svc = IntakeGreetingService(
        send: ({required messages, required systemPrompt, int maxTokens = 400, String? model}) async => 'unused',
        save: ({required caseId, required role, required content}) async {},
      );
      const draft = IntakeDraft(urgentShortcutTaken: true);
      final prompt = svc.buildPrompt(userCase: _mkCase(), draft: draft);
      expect(prompt.systemPrompt, contains('URGENT'));
      expect(prompt.userMessage, contains('URGENT shortcut'));
    });
  });

  group('generateAndPersist', () {
    test('persists Sonnet greeting on success', () async {
      String? savedRole;
      String? savedContent;
      String? savedCaseId;
      final svc = IntakeGreetingService(
        send: ({required messages, required systemPrompt, int maxTokens = 400, String? model}) async {
          // Sonnet would normally be invoked.
          return 'Я вижу ваше дело — депортация, 30 дней на апелляцию.';
        },
        save: ({required caseId, required role, required content}) async {
          savedCaseId = caseId;
          savedRole = role;
          savedContent = content;
        },
      );

      final res = await svc.generateAndPersist(
        userCase: _mkCase(),
        draft: const IntakeDraft(caseType: IntakeCaseType.immigration),
      );

      expect(res.usedFallback, isFalse);
      expect(res.greeting, contains('депортация'));
      expect(savedCaseId, 'c-1');
      expect(savedRole, 'assistant');
      expect(savedContent, contains('депортация'));
    });

    test('falls back when Sonnet throws', () async {
      String? savedContent;
      final svc = IntakeGreetingService(
        send: ({required messages, required systemPrompt, int maxTokens = 400, String? model}) =>
            Future.error(Exception('no API key')),
        save: ({required caseId, required role, required content}) async {
          savedContent = content;
        },
      );

      final res = await svc.generateAndPersist(
        userCase: _mkCase(language: 'ru', caseType: 'immigration'),
        draft: const IntakeDraft(caseType: IntakeCaseType.immigration),
      );

      expect(res.usedFallback, isTrue);
      expect(res.greeting, isNotEmpty);
      // RU template for immigration case.
      expect(res.greeting, contains('миграционное дело'));
      expect(savedContent, res.greeting);
    });

    test('falls back when Sonnet times out', () async {
      final svc = IntakeGreetingService(
        send: ({required messages, required systemPrompt, int maxTokens = 400, String? model}) =>
            Future<String>.delayed(const Duration(seconds: 2), () => 'too-late'),
        save: ({required caseId, required role, required content}) async {},
        timeout: const Duration(milliseconds: 50),
      );

      final res = await svc.generateAndPersist(
        userCase: _mkCase(language: 'en', caseType: 'civil'),
        draft: const IntakeDraft(caseType: IntakeCaseType.civil),
      );

      expect(res.usedFallback, isTrue);
      expect(res.greeting, isNotEmpty);
    });

    test('falls back when Sonnet returns empty string', () async {
      final svc = IntakeGreetingService(
        send: ({required messages, required systemPrompt, int maxTokens = 400, String? model}) async => '   ',
        save: ({required caseId, required role, required content}) async {},
      );
      final res = await svc.generateAndPersist(
        userCase: _mkCase(language: 'fi', caseType: 'admin'),
        draft: const IntakeDraft(caseType: IntakeCaseType.admin),
      );
      expect(res.usedFallback, isTrue);
      expect(res.greeting, contains('hallintoasiasi'));
    });

    test('save errors do not throw — greeting still returned', () async {
      final svc = IntakeGreetingService(
        send: ({required messages, required systemPrompt, int maxTokens = 400, String? model}) async => 'g',
        save: ({required caseId, required role, required content}) =>
            Future.error(Exception('insert failed')),
      );
      final res = await svc.generateAndPersist(
        userCase: _mkCase(),
        draft: const IntakeDraft(),
      );
      expect(res.greeting, 'g');
    });
  });

  group('fallbackGreeting templates', () {
    test('urgent ru template names urgency', () {
      final g = IntakeGreetingService.fallbackGreeting(
        caseType: 'criminal',
        language: 'ru',
        urgent: true,
      );
      expect(g, contains('срочно'));
    });

    test('et urgent template uses formal pronoun', () {
      final g = IntakeGreetingService.fallbackGreeting(
        caseType: 'admin',
        language: 'et',
        urgent: true,
      );
      expect(g, contains('kiireloomuline'));
    });

    test('unknown language falls back to English', () {
      final g = IntakeGreetingService.fallbackGreeting(
        caseType: 'civil',
        language: 'de',
        urgent: false,
      );
      expect(g, contains('I see'));
    });

    test('null caseType uses generic template', () {
      final g = IntakeGreetingService.fallbackGreeting(
        caseType: null,
        language: 'ru',
        urgent: false,
      );
      expect(g, contains('Я вижу ваше дело'));
    });
  });
}
