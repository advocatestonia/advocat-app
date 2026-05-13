@Tags(['fast'])
library;

// =============================================================================
// calendar_export_test.dart — verify the deadline → calendar wire-up.
// -----------------------------------------------------------------------------
// We cover the contract between CaseFileScreen and IcsExportService without
// invoking any platform share-sheet. The screen exposes a `IcsBuilder`
// callback seam for tests; the production callback uses the real share API.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/case_file/case_file_providers.dart';
import 'package:advocat/features/case_file/screens/case_file_screen.dart';
import 'package:advocat/l10n/app_localizations.dart';
import 'package:advocat/models/case_file.dart';
import 'package:advocat/services/case_file_service.dart';
import 'package:advocat/services/ics_export_service.dart';

class _FakeNotifier extends CaseFileNotifier {
  _FakeNotifier(super.service, CaseFileState initial) {
    state = initial;
  }
  @override
  Future<void> refresh() async {}
  @override
  Future<void> bind({String? caseId}) async {}
}

class _NoopService extends CaseFileService {
  _NoopService() : super();
  @override
  Future<List<CaseEvent>> listEvents({String? caseId, int limit = 200}) async =>
      const [];
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

  group('CaseFileScreen calendar export wire-up', () {
    testWidgets('renders an "add to calendar" icon next to the urgent deadline',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          CaseFileScreen(
            icsHandlerOverride: (_) async {/* swallow */},
          ),
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
      // The screen renders the urgent-deadline calendar add icon.
      expect(
        find.byKey(const Key('case_file_calendar_export_urgent')),
        findsOneWidget,
      );
    });

    testWidgets(
      'tapping the calendar icon hands a real .ics payload to the handler',
      (tester) async {
        String? captured;
        await tester.pumpWidget(
          _wrap(
            CaseFileScreen(
              icsHandlerOverride: (payload) async {
                captured = payload;
              },
            ),
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

        await tester.tap(
          find.byKey(const Key('case_file_calendar_export_urgent')),
        );
        await tester.pump();

        expect(captured, isNotNull);
        // Sanity: well-formed RFC 5545 envelope.
        expect(captured, contains('BEGIN:VCALENDAR'));
        expect(captured, contains('END:VCALENDAR'));
        expect(captured, contains('BEGIN:VEVENT'));
        expect(captured, contains('END:VEVENT'));
        // Carries the deadline title and law citation.
        expect(captured, contains('SUMMARY:Vaie esitamise tähtaeg'));
        expect(captured, contains('HMS § 75 lg 1'));
        // BEGIN/END pairs balance.
        expect('BEGIN:VEVENT'.allMatches(captured!).length, 1);
        expect('END:VEVENT'.allMatches(captured!).length, 1);
      },
    );

    testWidgets(
      'IcsExportService consumed by handler matches direct service output',
      (tester) async {
        // Drive through the screen, capture the handler payload, and
        // confirm it exactly matches what IcsExportService would build
        // for the same deadline. This locks in the contract.
        //
        // NOTE: `due` MUST be in the future relative to DateTime.now() because
        // CaseFileScreen only renders the "urgent" deadline row (and its
        // `case_file_calendar_export_urgent` key) when
        // `mostUrgentDeadline(today)` returns non-null — and that filter
        // drops any deadline strictly before today. Hard-coding a fixed
        // calendar date here causes this test to start failing the day
        // after that date passes. The sibling tests in this group use
        // `DateTime.now().add(...)` for exactly this reason.
        String? captured;
        final due = DateTime.now().add(const Duration(days: 21));

        await tester.pumpWidget(
          _wrap(
            CaseFileScreen(
              icsHandlerOverride: (payload) async {
                captured = payload;
              },
            ),
            seed: CaseFileState(
              deadlines: [
                CaseDeadline(
                  date: due,
                  title: 'Vaie esitamise tähtaeg',
                  law: 'HMS § 75 lg 1',
                ),
              ],
            ),
          ),
        );
        await tester.pump();
        await tester.tap(
          find.byKey(const Key('case_file_calendar_export_urgent')),
        );
        await tester.pump();

        expect(captured, isNotNull);
        // Whatever the screen produced must contain the same SUMMARY +
        // DTSTART that IcsExportService would emit for this deadline.
        final reference = IcsExportService.renderEvent(
          title: 'Vaie esitamise tähtaeg',
          startDate: due,
          allDay: true,
        );
        final summaryLine = reference
            .split('\r\n')
            .firstWhere((l) => l.startsWith('SUMMARY:'));
        final dtStartLine = reference
            .split('\r\n')
            .firstWhere((l) => l.startsWith('DTSTART;VALUE=DATE:'));
        expect(captured, contains(summaryLine));
        expect(captured, contains(dtStartLine));
      },
    );
  });
}
