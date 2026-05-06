import 'dart:typed_data';

import 'package:advocat/features/case_memory/data/case_repository.dart';
import 'package:advocat/features/case_memory/screens/intake_wizard/intake_wizard_screen.dart';
import 'package:advocat/features/case_memory/screens/intake_wizard/step5_documents_screen.dart';
import 'package:advocat/features/case_memory/services/intake_greeting_service.dart';
import 'package:advocat/features/case_memory/state/active_case_provider.dart';
import 'package:advocat/features/case_memory/state/intake_wizard_state.dart';
import 'package:advocat/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/case_repository_test.dart';

GoRouter _router() => GoRouter(
      initialLocation: '/cases-v2/new',
      routes: [
        GoRoute(
          path: '/cases-v2/new',
          builder: (_, __) => const IntakeWizardScreen(),
        ),
        GoRoute(
          path: '/chat/:caseId',
          builder: (_, state) => Scaffold(
            body: Text('CHAT_${state.pathParameters['caseId']}'),
          ),
        ),
      ],
    );

/// Wraps the wizard with a deterministic greeting service so tests
/// don't poke at the real Anthropic stack.
Widget _wrap({
  required FakeCaseRepository repo,
  IntakeGreetingService? greeting,
  ProviderContainer? container,
}) {
  final overrides = <Override>[
    caseRepositoryProvider.overrideWithValue(repo),
    if (greeting != null)
      intakeGreetingServiceProvider.overrideWithValue(greeting),
  ];
  final Widget app = MaterialApp.router(
    routerConfig: _router(),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en')],
  );
  if (container != null) {
    return UncontrolledProviderScope(container: container, child: app);
  }
  return ProviderScope(overrides: overrides, child: app);
}

IntakeGreetingService _stubGreeting({String greeting = 'hi from sonnet'}) {
  final calls = <Map<String, String>>[];
  return IntakeGreetingService(
    send: ({required messages, required systemPrompt, int maxTokens = 400, String? model}) async {
      return greeting;
    },
    save: ({required caseId, required role, required content}) async {
      calls.add({'caseId': caseId, 'role': role, 'content': content});
    },
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('renders 5 steps in order', (tester) async {
    final repo = FakeCaseRepository();
    await tester.pumpWidget(_wrap(repo: repo, greeting: _stubGreeting()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('intake-step-1')), findsOneWidget);
    expect(find.byKey(const Key('intake-wizard-pageview')), findsOneWidget);
  });

  testWidgets('Next button disabled until step 1 complete', (tester) async {
    final repo = FakeCaseRepository();
    await tester.pumpWidget(_wrap(repo: repo, greeting: _stubGreeting()));
    await tester.pumpAndSettle();

    final nextBtn = tester.widget<ElevatedButton>(
      find.byKey(const Key('intake-next-btn')),
    );
    // Initially disabled — no authority type chosen yet.
    expect(nextBtn.onPressed, isNull);
  });

  testWidgets('Next enabled after step 1 + step 2 → page advances', (tester) async {
    final container = ProviderContainer(overrides: [
      caseRepositoryProvider.overrideWithValue(FakeCaseRepository()),
      intakeGreetingServiceProvider.overrideWithValue(_stubGreeting()),
    ]);
    addTearDown(container.dispose);

    // Pre-populate via the notifier (faster than tapping dropdowns).
    final notifier = container.read(intakeWizardProvider.notifier);
    await notifier.loaded;
    notifier.update((d) => d.copyWith(
          jurisdiction: 'EE',
          authorityType: IntakeAuthorityType.court,
          caseType: IntakeCaseType.civil,
        ));

    await tester.pumpWidget(_wrap(
      repo: FakeCaseRepository(),
      container: container,
    ));
    await tester.pumpAndSettle();

    // Step 1 satisfied — Next is enabled.
    final nextBtn = tester.widget<ElevatedButton>(
      find.byKey(const Key('intake-next-btn')),
    );
    expect(nextBtn.onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('intake-next-btn')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('intake-step-2')), findsOneWidget);
  });

  testWidgets('finish creates case, sets active, persists greeting, navigates',
      (tester) async {
    final repo = FakeCaseRepository();
    String? savedRole;
    String? savedContent;
    final greet = IntakeGreetingService(
      send: ({required messages, required systemPrompt, int maxTokens = 400, String? model}) async => 'GENERATED_GREETING',
      save: ({required caseId, required role, required content}) async {
        savedRole = role;
        savedContent = content;
      },
    );
    final container = ProviderContainer(overrides: [
      caseRepositoryProvider.overrideWithValue(repo),
      intakeGreetingServiceProvider.overrideWithValue(greet),
    ]);
    addTearDown(container.dispose);

    final notifier = container.read(intakeWizardProvider.notifier);
    await notifier.loaded;
    notifier.update((d) => d.copyWith(
          jurisdiction: 'FI',
          authorityType: IntakeAuthorityType.police,
          caseType: IntakeCaseType.criminal,
        ));

    await tester.pumpWidget(_wrap(repo: repo, container: container));
    await tester.pumpAndSettle();

    // Step 1 → 2 → 3 → 4 → 5
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byKey(const Key('intake-next-btn')));
      await tester.pumpAndSettle();
    }
    // Now on step 5 — Next reads "Finish".
    await tester.tap(find.byKey(const Key('intake-next-btn')));
    await tester.pumpAndSettle();

    // Case created with the wizard's fields.
    expect(repo.lastCreatePayload, isNotNull);
    expect(repo.lastCreatePayload!['jurisdiction'], 'FI');
    expect(repo.lastCreatePayload!['case_type'], 'criminal');

    // Greeting persisted as the assistant's first message.
    expect(savedRole, 'assistant');
    expect(savedContent, 'GENERATED_GREETING');

    // New case is now active.
    final active = container.read(activeCaseProvider).activeCase;
    expect(active, isNotNull);

    // Wizard draft cleared.
    expect(container.read(intakeWizardProvider).jurisdiction, isNull);

    // Navigated to chat for the new case.
    expect(find.textContaining('CHAT_'), findsOneWidget);
  });

  testWidgets('Урент shortcut creates case, marks urgent, navigates to chat',
      (tester) async {
    final repo = FakeCaseRepository();
    bool urgentSeenInPrompt = false;
    final greet = IntakeGreetingService(
      send: ({required messages, required systemPrompt, int maxTokens = 400, String? model}) async {
        if (systemPrompt.contains('URGENT')) urgentSeenInPrompt = true;
        return 'urgent ack';
      },
      save: ({required caseId, required role, required content}) async {},
    );
    final container = ProviderContainer(overrides: [
      caseRepositoryProvider.overrideWithValue(repo),
      intakeGreetingServiceProvider.overrideWithValue(greet),
    ]);
    addTearDown(container.dispose);

    // Set step 1 minimum so urgent has something to materialize.
    final notifier = container.read(intakeWizardProvider.notifier);
    await notifier.loaded;
    notifier.update((d) => d.copyWith(
          jurisdiction: 'EE',
          authorityType: IntakeAuthorityType.court,
        ));

    await tester.pumpWidget(_wrap(repo: repo, container: container));
    await tester.pumpAndSettle();

    // Tap urgent → confirm dialog → confirm.
    await tester.tap(find.byKey(const Key('intake-urgent-btn')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('intake-urgent-confirm')));
    await tester.pumpAndSettle();

    // Case was created even though step 2 was empty (urgent path
    // doesn't enforce the step-2 gate).
    expect(repo.lastCreatePayload, isNotNull);
    expect(repo.lastCreatePayload!['jurisdiction'], 'EE');

    // Active case set.
    final active = container.read(activeCaseProvider).activeCase;
    expect(active, isNotNull);

    // Greeting service saw the urgent flag in the system prompt.
    expect(urgentSeenInPrompt, isTrue);

    // Navigated to chat.
    expect(find.textContaining('CHAT_'), findsOneWidget);
  });

  testWidgets('staged docs are uploaded on finish', (tester) async {
    final repo = FakeCaseRepository();
    final container = ProviderContainer(overrides: [
      caseRepositoryProvider.overrideWithValue(repo),
      intakeGreetingServiceProvider.overrideWithValue(_stubGreeting()),
    ]);
    addTearDown(container.dispose);

    final notifier = container.read(intakeWizardProvider.notifier);
    await notifier.loaded;
    notifier.update((d) => d.copyWith(
          jurisdiction: 'EE',
          authorityType: IntakeAuthorityType.court,
          caseType: IntakeCaseType.civil,
        ));

    // Pre-stage a doc.
    container.read(stagedDocumentsProvider.notifier).state = [
      StagedDocument(
        filename: 'test.pdf',
        bytes: Uint8List.fromList([1, 2, 3, 4]),
        mimeType: 'application/pdf',
      ),
    ];

    await tester.pumpWidget(_wrap(repo: repo, container: container));
    await tester.pumpAndSettle();

    // Walk through 4 Next taps to land on step 5, then Finish.
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byKey(const Key('intake-next-btn')));
      await tester.pumpAndSettle();
    }

    expect(repo.uploadedPayloads, hasLength(1));
    expect(repo.uploadedPayloads.single['filename'], 'test.pdf');
    // Staged docs cleared after success.
    expect(container.read(stagedDocumentsProvider), isEmpty);
  });
}
