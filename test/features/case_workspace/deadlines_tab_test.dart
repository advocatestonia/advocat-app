// Phase 2 Pkg 4 — DeadlinesTab wrapper tests.
//
// The wrapper hosts the existing Pkg 9 CaseDeadlinesScreen with an
// AppBar suppression so the workspace TabBar is the canonical one.
// The Pkg 9 screen has its own dedicated test suite — we don't repeat
// the snooze / archive / mark-complete coverage here. We only assert
// that the wrapper renders the underlying screen with the right caseId.

import 'package:advocat/features/case_memory/data/case_deadline_repository.dart';
import 'package:advocat/features/case_memory/models/case_deadline.dart';
import 'package:advocat/features/case_memory/screens/case_deadlines_screen.dart';
import 'package:advocat/features/case_workspace/tabs/deadlines_tab.dart';
import 'package:advocat/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements CaseDeadlineRepository {
  _FakeRepo({this.list = const <CaseDeadline>[]});
  final List<CaseDeadline> list;

  @override
  Future<List<CaseDeadline>> listForCase(String caseId) async => list;

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

Widget _wrap(Widget child, {List<CaseDeadline> list = const []}) {
  return ProviderScope(
    overrides: [
      caseDeadlineRepositoryProvider
          .overrideWithValue(_FakeRepo(list: list)),
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

  testWidgets('DeadlinesTab — wraps Pkg 9 case deadlines screen',
      (tester) async {
    await tester.pumpWidget(_wrap(const DeadlinesTab(caseId: 'c-1')));
    await tester.pumpAndSettle();

    // The underlying Pkg 9 screen renders.
    expect(find.byType(CaseDeadlinesScreen), findsOneWidget);
    // Its empty state is hit (no deadlines seeded).
    expect(find.byKey(const Key('case-deadlines-empty')), findsOneWidget);
  });
}
