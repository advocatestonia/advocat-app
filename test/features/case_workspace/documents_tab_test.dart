// Phase 2 Pkg 4 — DocumentsTab widget tests.

import 'package:advocat/features/case_memory/data/case_repository.dart';
import 'package:advocat/features/case_memory/models/case_document.dart';
import 'package:advocat/features/case_workspace/tabs/documents_tab.dart';
import 'package:advocat/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../case_memory/data/case_repository_test.dart';

Widget _wrap(Widget child, {required CaseRepository repo}) {
  return ProviderScope(
    overrides: [
      caseRepositoryProvider.overrideWithValue(repo),
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

CaseDocument _doc({
  String id = 'd-1',
  String filename = 'epikriis.pdf',
  String? summary,
}) {
  return CaseDocument(
    id: id,
    caseId: 'c-1',
    userId: 'u-1',
    filename: filename,
    storagePath: 'u-1/c-1/$filename',
    parsedSummary: summary,
    uploadedAt: DateTime.utc(2026, 5, 6),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('DocumentsTab — empty state when no documents', (tester) async {
    final repo = FakeCaseRepository();
    await tester.pumpWidget(
      _wrap(const DocumentsTab(caseId: 'c-1'), repo: repo),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('workspace-documents-empty')), findsOneWidget);
  });

  testWidgets('DocumentsTab — renders one card per document', (tester) async {
    final repo = FakeCaseRepository(documents: [
      _doc(id: 'd-1', filename: 'epikriis.pdf', summary: 'F43.1 PTSD'),
      _doc(id: 'd-2', filename: 'kaebus.pdf'),
    ]);
    await tester.pumpWidget(
      _wrap(const DocumentsTab(caseId: 'c-1'), repo: repo),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('workspace-documents-tab')), findsOneWidget);
    expect(find.text('epikriis.pdf'), findsOneWidget);
    expect(find.text('kaebus.pdf'), findsOneWidget);
    expect(find.text('F43.1 PTSD'), findsOneWidget);
  });
}
