@Tags(['fast'])
library;

// Widget tests for DraftsListScreen + empty-state CTA (Pkg 7 MVP).
// -----------------------------------------------------------------------------
// Uses a FakeDraftService so we don't need a Supabase instance.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/drafting/models/draft_model.dart';
import 'package:advocat/features/drafting/screens/drafts_list_screen.dart';
import 'package:advocat/features/drafting/services/draft_service.dart';
import 'package:advocat/l10n/app_localizations.dart';

class _FakeDraftService implements DraftService {
  _FakeDraftService(this._drafts);
  final List<Draft> _drafts;

  @override
  Future<List<Draft>> listMyDrafts({int limit = 50}) async {
    return List<Draft>.from(_drafts);
  }

  @override
  Future<Draft?> fetchById(String draftId) async =>
      _drafts.firstWhere((d) => d.id == draftId);

  @override
  Future<Draft> createDraft(
          {required String userId,
          String? caseId,
          DraftSourceType sourceType = DraftSourceType.blank,
          String? sourceId,
          String? title,
          String contentMarkdown = '',
          String? language,
          String? jurisdiction,
          Map<String, dynamic> metadata = const <String, dynamic>{}}) async =>
      throw UnimplementedError();

  @override
  Future<Draft> updateDraft(String draftId,
          {String? title,
          String? contentMarkdown,
          String? language,
          String? jurisdiction,
          DraftStatus? status,
          Map<String, dynamic>? metadata,
          String? vaultCopyId}) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteDraft(String draftId) async {}

  @override
  Future<void> snapshotVersion(String draftId,
      {required String contentMarkdown,
      bool aiRevision = false,
      Map<String, dynamic> metadata = const <String, dynamic>{}}) async {}

  @override
  Future<AiRevision> reviseWithAi(
          {required String draftId,
          required String selectedText,
          String? context,
          String? instruction,
          String? language}) async =>
      throw UnimplementedError();

  @override
  Future<DocxExport> exportToDocx(
          {required String contentMarkdown, String? title}) async =>
      throw UnimplementedError();
  @override
  Future<PdfExport> exportToPdf(
          {required String contentMarkdown, String? title}) async =>
      throw UnimplementedError();
  @override
  Future<String> saveToVault(String draftId) async => 'fake-vault-doc-id';
  @override
  Future<List<DraftVersion>> getVersions(String draftId) async =>
      <DraftVersion>[];
  @override
  Future<Draft> restoreVersion(String draftId, String versionId) async =>
      throw UnimplementedError();
}

Draft _draft({
  String id = 'a',
  String? title,
  String body = 'body text',
  DraftSourceType sourceType = DraftSourceType.blank,
}) {
  final now = DateTime.now().toUtc();
  return Draft(
    id: id,
    userId: 'u',
    title: title,
    contentMarkdown: body,
    contentPlaintext: body,
    sourceType: sourceType,
    createdAt: now,
    updatedAt: now,
  );
}

Widget _wrap(Widget child, {required List<Draft> drafts}) {
  return ProviderScope(
    overrides: <Override>[
      draftServiceProvider.overrideWithValue(_FakeDraftService(drafts)),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  group('DraftsListScreen', () {
    testWidgets('renders empty state CTA when no drafts', (tester) async {
      await tester.pumpWidget(_wrap(
        const DraftsListScreen(),
        drafts: <Draft>[],
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('drafts_list_empty_message')), findsOneWidget);
      expect(find.byKey(const Key('drafts_list_empty_cta')), findsOneWidget);
    });

    testWidgets('lists drafts when present', (tester) async {
      await tester.pumpWidget(_wrap(
        const DraftsListScreen(),
        drafts: <Draft>[
          _draft(id: 'a1', title: 'First', body: 'aaa'),
          _draft(id: 'a2', title: 'Second', body: 'bbb'),
        ],
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('drafts_list_item_a1')), findsOneWidget);
      expect(find.byKey(const Key('drafts_list_item_a2')), findsOneWidget);
      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
    });

    testWidgets('Untitled fallback rendered for blank-title drafts',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const DraftsListScreen(),
        drafts: <Draft>[_draft(id: 'a1', body: 'something')],
      ));
      await tester.pumpAndSettle();
      // English locale pumped via _wrap; matches draftingUntitled from app_en.arb.
      expect(find.text('Untitled'), findsOneWidget);
    });

    testWidgets('FAB to create new draft is present', (tester) async {
      await tester.pumpWidget(_wrap(
        const DraftsListScreen(),
        drafts: <Draft>[_draft(id: 'a1', title: 'x')],
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('drafts_list_new_fab')), findsOneWidget);
    });
  });
}
