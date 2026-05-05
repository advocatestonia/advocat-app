// case_file_screen_test.dart
// -----------------------------------------------------------------------------
// Widget tests for CaseFileScreen + the deadline countdown widget.
// We override the StateNotifier provider with a fake that exposes seeded
// data, so the screen renders deterministically without Supabase.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/case_file/case_file_providers.dart';
import 'package:advocat/features/case_file/screens/case_file_screen.dart';
import 'package:advocat/features/case_file/widgets/deadline_countdown_card.dart';
import 'package:advocat/l10n/app_localizations.dart';
import 'package:advocat/models/case_file.dart';
import 'package:advocat/services/case_file_service.dart';

class _FakeNotifier extends CaseFileNotifier {
  _FakeNotifier(super.service, CaseFileState initial) {
    state = initial;
  }
  @override
  Future<void> refresh() async {/* no-op for tests */}
  @override
  Future<void> bind({String? caseId}) async {/* no-op for tests */}
}

class _NoopService extends CaseFileService {
  _NoopService() : super();
  @override
  Future<List<CaseEvent>> listEvents({String? caseId, int limit = 200}) async => const [];
  @override
  Future<List<CaseParty>> listParties({String? caseId}) async => const [];
  @override
  Future<List<CaseDeadline>> listDeadlines({String? caseId}) async => const [];
}

Widget _wrap(Widget child, {required CaseFileState seed}) {
  return ProviderScope(
    overrides: [
      caseFileServiceProvider.overrideWithValue(_NoopService()),
      caseFileProvider.overrideWith(
        (ref) => _FakeNotifier(ref.read(caseFileServiceProvider), seed),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('et'), Locale('ru')],
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('formatDeadlineCountdown', () {
    final today = DateTime(2026, 5, 1);

    test('overdue: yields "Overdue by N days remaining"', () {
      final d = CaseDeadline(date: DateTime(2026, 4, 25), title: 'X');
      expect(
        formatDeadlineCountdown(
          today: today,
          deadline: d,
          oneDayLabel: '1 day remaining',
          daysLabel: 'days remaining',
          overdueLabel: 'Overdue by',
          dueTodayLabel: 'Due today',
        ),
        'Overdue by 6 days remaining',
      );
    });

    test('due today returns dueTodayLabel', () {
      final d = CaseDeadline(date: today, title: 'X');
      expect(
        formatDeadlineCountdown(
          today: today,
          deadline: d,
          oneDayLabel: '1 day remaining',
          daysLabel: 'days remaining',
          overdueLabel: 'Overdue by',
          dueTodayLabel: 'Due today',
        ),
        'Due today',
      );
    });

    test('1 day uses singular label', () {
      final d = CaseDeadline(date: DateTime(2026, 5, 2), title: 'X');
      expect(
        formatDeadlineCountdown(
          today: today,
          deadline: d,
          oneDayLabel: '1 day remaining',
          daysLabel: 'days remaining',
          overdueLabel: 'Overdue by',
          dueTodayLabel: 'Due today',
        ),
        '1 day remaining',
      );
    });

    test('many days uses plural label', () {
      final d = CaseDeadline(date: DateTime(2026, 5, 22), title: 'X');
      expect(
        formatDeadlineCountdown(
          today: today,
          deadline: d,
          oneDayLabel: '1 day remaining',
          daysLabel: 'days remaining',
          overdueLabel: 'Overdue by',
          dueTodayLabel: 'Due today',
        ),
        '21 days remaining',
      );
    });
  });

  group('CaseFileState', () {
    test('mostUrgentDeadline returns earliest non-completed in the future', () {
      final today = DateTime(2026, 5, 1);
      final state = CaseFileState(
        deadlines: [
          CaseDeadline(date: DateTime(2026, 4, 1), title: 'Past'),
          CaseDeadline(date: DateTime(2026, 5, 12), title: 'Soon'),
          CaseDeadline(date: DateTime(2026, 6, 1), title: 'Later'),
        ],
      );
      expect(state.mostUrgentDeadline(today)?.title, 'Soon');
    });

    test('mostUrgentDeadline ignores completed deadlines', () {
      final today = DateTime(2026, 5, 1);
      final state = CaseFileState(
        deadlines: [
          CaseDeadline(
              date: DateTime(2026, 5, 12), title: 'Soon', completed: true),
          CaseDeadline(date: DateTime(2026, 6, 1), title: 'Later'),
        ],
      );
      expect(state.mostUrgentDeadline(today)?.title, 'Later');
    });

    test('isEmpty true when no rows and not loading', () {
      const s = CaseFileState();
      expect(s.isEmpty, isTrue);
    });

    test('isEmpty false when events present', () {
      final s = CaseFileState(events: [CaseEvent(title: 'X')]);
      expect(s.isEmpty, isFalse);
    });
  });

  group('CaseFileScreen widget', () {
    testWidgets('renders empty state when no data', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const CaseFileScreen(),
          seed: const CaseFileState(),
        ),
      );
      // Pump once for the post-frame callbacks.
      await tester.pump();
      expect(find.text('Case File'), findsOneWidget);
      expect(
        find.textContaining('your timeline will build itself'),
        findsOneWidget,
      );
    });

    testWidgets('renders timeline rows when events present', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const CaseFileScreen(),
          seed: CaseFileState(
            events: [
              CaseEvent(
                date: DateTime(2026, 4, 12),
                title: 'PPA decision received',
                category: CaseEventCategory.decision,
              ),
              CaseEvent(
                date: DateTime(2026, 4, 25),
                title: 'Submitted appeal',
                category: CaseEventCategory.submission,
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      expect(find.text('PPA decision received'), findsOneWidget);
      expect(find.text('Submitted appeal'), findsOneWidget);
      // Timeline section header rendered
      expect(find.text('Timeline'), findsOneWidget);
    });

    testWidgets('renders countdown card for most-urgent deadline',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const CaseFileScreen(),
          seed: CaseFileState(
            deadlines: [
              CaseDeadline(
                date: DateTime.now().add(const Duration(days: 21)),
                title: 'Vaie esitamise tähtaeg',
                law: 'HMS § 75 lg 1',
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(DeadlineCountdownCard), findsOneWidget);
      expect(find.text('Vaie esitamise tähtaeg'), findsOneWidget);
      expect(find.text('HMS § 75 lg 1'), findsOneWidget);
    });

    testWidgets('renders party chips when parties present', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const CaseFileScreen(),
          seed: CaseFileState(
            parties: [
              CaseParty(
                  name: 'Politsei- ja Piirivalveamet',
                  type: PartyType.authority),
              CaseParty(name: 'Bolt OÜ', type: PartyType.company),
            ],
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Politsei- ja Piirivalveamet'), findsOneWidget);
      expect(find.text('Bolt OÜ'), findsOneWidget);
      expect(find.text('Parties'), findsOneWidget);
    });

    testWidgets('export PDF button is disabled when state is empty',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const CaseFileScreen(),
          seed: const CaseFileState(),
        ),
      );
      await tester.pump();
      // Empty state shows the "your timeline will build itself" message
      // and NOT the export button.
      expect(find.byKey(const Key('case_file_export_pdf')), findsNothing);
    });

    testWidgets('export PDF button is enabled when there is data',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const CaseFileScreen(),
          seed: CaseFileState(
            events: [CaseEvent(title: 'X', date: DateTime(2026, 4, 1))],
          ),
        ),
      );
      await tester.pump();
      // The key sits on the ElevatedButton itself (ElevatedButton.icon
      // returns an ElevatedButton via its _ElevatedButtonWithIcon wrapper).
      final btn = find.byKey(const Key('case_file_export_pdf'));
      expect(btn, findsOneWidget);
      final widget = tester.widget(btn) as ButtonStyleButton;
      expect(widget.onPressed, isNotNull);
    });
  });
}
