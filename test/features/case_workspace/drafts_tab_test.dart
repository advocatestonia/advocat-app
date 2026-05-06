// Phase 2 Pkg 4 — DraftsTab widget tests.

import 'package:advocat/features/case_workspace/providers/case_workspace_provider.dart';
import 'package:advocat/features/case_workspace/tabs/drafts_tab.dart';
import 'package:advocat/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _SeededDraftsNotifier extends WorkspaceDraftsNotifier {
  _SeededDraftsNotifier(List<WorkspaceDraft> seed) {
    state = seed;
  }
}

Widget _wrap(Widget child, {List<WorkspaceDraft> seed = const []}) {
  return ProviderScope(
    overrides: [
      workspaceCaseDraftsProvider('c-1')
          .overrideWith((ref) => _SeededDraftsNotifier(seed)),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('et'), Locale('ru')],
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('DraftsTab — empty state when no drafts', (tester) async {
    await tester.pumpWidget(_wrap(const DraftsTab(caseId: 'c-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('workspace-drafts-empty')), findsOneWidget);
  });

  testWidgets('DraftsTab — renders one card per draft', (tester) async {
    final draft = WorkspaceDraft(
      id: 'dr-1',
      caseId: 'c-1',
      title: 'Appeal letter',
      body: 'Lugupeetud kohus...',
      createdAt: DateTime.utc(2026, 5, 6),
    );
    await tester.pumpWidget(
      _wrap(const DraftsTab(caseId: 'c-1'), seed: [draft]),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('workspace-drafts-tab')), findsOneWidget);
    expect(find.byKey(const Key('workspace-draft-dr-1')), findsOneWidget);
    expect(find.text('Appeal letter'), findsOneWidget);
  });
}
