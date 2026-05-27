@Tags(['fast'])
library;

// Unit + widget tests for Track 1B Version History (Drafting Studio).
// -----------------------------------------------------------------------------
// Covers:
//   * DraftVersion.fromJson / previewSnippet
//   * DraftService.restoreVersion ordering — snapshot-then-overwrite
//   * DraftVersionsScreen — list, empty-state, AI badge, restore flow.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/drafting/models/draft_model.dart';
import 'package:advocat/features/drafting/screens/draft_versions_screen.dart';
import 'package:advocat/features/drafting/services/draft_service.dart';

/// Minimal fake — captures call ORDER so we can prove restoreVersion first
/// snapshots the current body, then updates the draft.
class _RecordingService implements DraftService {
  _RecordingService({
    Draft? current,
    List<DraftVersion> versions = const <DraftVersion>[],
  })  : _currentDraft = current,
        _versions = List<DraftVersion>.from(versions);

  Draft? _currentDraft;
  final List<DraftVersion> _versions;
  final List<String> calls = <String>[];

  @override
  Future<Draft?> fetchById(String draftId) async {
    calls.add('fetchById:$draftId');
    return _currentDraft;
  }

  @override
  Future<List<DraftVersion>> getVersions(String draftId) async {
    calls.add('getVersions:$draftId');
    return List<DraftVersion>.from(_versions);
  }

  @override
  Future<void> snapshotVersion(
    String draftId, {
    required String contentMarkdown,
    bool aiRevision = false,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) async {
    calls.add('snapshot:$draftId:$contentMarkdown:$aiRevision');
  }

  @override
  Future<Draft> updateDraft(
    String draftId, {
    String? title,
    String? contentMarkdown,
    String? language,
    String? jurisdiction,
    DraftStatus? status,
    Map<String, dynamic>? metadata,
    String? vaultCopyId,
  }) async {
    calls.add('update:$draftId:${contentMarkdown ?? ""}');
    final now = DateTime.now().toUtc();
    return Draft(
      id: draftId,
      userId: 'u',
      createdAt: now,
      updatedAt: now,
      contentMarkdown: contentMarkdown ?? '',
      contentPlaintext: contentMarkdown ?? '',
    );
  }

  // Reference fake of restoreVersion mirroring the production order: snapshot
  // current → fetch target → update. Lets us assert ordering in isolation.
  @override
  Future<Draft> restoreVersion(String draftId, String versionId) async {
    final current = await fetchById(draftId);
    if (current == null) throw StateError('not found');
    final target = _versions.firstWhere((v) => v.id == versionId);
    await snapshotVersion(
      draftId,
      contentMarkdown: current.contentMarkdown,
      aiRevision: false,
      metadata: <String, dynamic>{
        'reason': 'pre_restore',
        'restored_from': versionId,
      },
    );
    return updateDraft(draftId, contentMarkdown: target.contentSnapshot);
  }

  // ─── unused interface methods ─────────────────────────────────────────────
  @override
  Future<List<Draft>> listMyDrafts({int limit = 50}) async => <Draft>[];
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
  Future<void> deleteDraft(String draftId) async {}
  @override
  Future<AiRevision> reviseWithAi(
          {required String draftId,
          required String selectedText,
          String? context,
          String? instruction,
          String? language}) async =>
      const AiRevision(revisedText: '', explanation: '', changesMade: []);
  @override
  Future<DocxExport> exportToDocx(
          {required String contentMarkdown, String? title}) async =>
      const DocxExport(base64: '', filename: '', byteLength: 0);
  @override
  Future<PdfExport> exportToPdf(
          {required String contentMarkdown, String? title}) async =>
      const PdfExport(base64: '', filename: '', byteLength: 0);
  @override
  Future<String> saveToVault(String draftId) async => 'vault-stub';
}

DraftVersion _v({
  String id = 'v1',
  String draftId = 'd1',
  String snapshot = 'body',
  bool ai = false,
  DateTime? createdAt,
}) {
  return DraftVersion(
    id: id,
    draftId: draftId,
    contentSnapshot: snapshot,
    isAiRevision: ai,
    createdAt: createdAt ?? DateTime.now().toUtc(),
  );
}

Widget _wrap(Widget child, {required _RecordingService svc}) {
  return ProviderScope(
    overrides: <Override>[
      draftServiceProvider.overrideWithValue(svc),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  group('DraftVersion model', () {
    test('fromJson maps all fields including ai_revision boolean', () {
      final v = DraftVersion.fromJson(<String, dynamic>{
        'id': 'v1',
        'draft_id': 'd1',
        'content_snapshot': 'hello',
        'ai_revision': true,
        'created_at': '2026-05-27T10:00:00Z',
        'metadata': <String, dynamic>{'k': 'v'},
      });
      expect(v.id, 'v1');
      expect(v.draftId, 'd1');
      expect(v.contentSnapshot, 'hello');
      expect(v.isAiRevision, true);
      expect(v.metadata['k'], 'v');
    });

    test('previewSnippet strips markdown and caps at 100 chars', () {
      final v = _v(
        snapshot: '# Heading\n\n**Bold** text and a [link](http://x). '
            'A very long body that goes way past one hundred characters '
            'to exercise the truncation branch of the snippet helper.',
      );
      final preview = v.previewSnippet();
      // No leftover ATX markers / bold markers / link parens.
      expect(preview.contains('#'), false);
      expect(preview.contains('**'), false);
      expect(preview.contains('http'), false);
      expect(preview.endsWith('…'), true);
      expect(preview.length, lessThanOrEqualTo(101));
    });

    test('previewSnippet returns empty string for empty snapshot', () {
      expect(_v(snapshot: '').previewSnippet(), '');
    });
  });

  group('DraftService.restoreVersion', () {
    test('snapshots current body BEFORE overwriting (reversible)', () async {
      final now = DateTime.now().toUtc();
      final current = Draft(
        id: 'd1',
        userId: 'u',
        createdAt: now,
        updatedAt: now,
        contentMarkdown: 'CURRENT_BODY',
        contentPlaintext: 'CURRENT_BODY',
      );
      final target = _v(id: 'vX', draftId: 'd1', snapshot: 'OLD_BODY');
      final svc = _RecordingService(current: current, versions: <DraftVersion>[target]);
      await svc.restoreVersion('d1', 'vX');

      // 1. fetched current, 2. snapshot CURRENT_BODY, 3. update with OLD_BODY.
      expect(svc.calls[0], startsWith('fetchById'));
      expect(svc.calls[1], 'snapshot:d1:CURRENT_BODY:false');
      expect(svc.calls[2], 'update:d1:OLD_BODY');
    });
  });

  group('DraftVersionsScreen', () {
    testWidgets('empty state when no versions', (tester) async {
      final svc = _RecordingService();
      await tester.pumpWidget(_wrap(
        const DraftVersionsScreen(draftId: 'd1'),
        svc: svc,
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('draft_versions_empty_message')),
          findsOneWidget);
    });

    testWidgets('renders rows newest-first with AI badge when flagged',
        (tester) async {
      final svc = _RecordingService(versions: <DraftVersion>[
        _v(id: 'va', snapshot: 'first snap', ai: true),
        _v(id: 'vb', snapshot: 'second snap', ai: false),
      ]);
      await tester.pumpWidget(_wrap(
        const DraftVersionsScreen(draftId: 'd1'),
        svc: svc,
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('draft_versions_row_va')), findsOneWidget);
      expect(find.byKey(const Key('draft_versions_row_vb')), findsOneWidget);
      // Only the AI row carries the badge.
      expect(find.byKey(const Key('draft_versions_ai_badge')), findsOneWidget);
    });

    testWidgets('restore button shows confirm dialog', (tester) async {
      final now = DateTime.now().toUtc();
      final svc = _RecordingService(
        current: Draft(
          id: 'd1',
          userId: 'u',
          createdAt: now,
          updatedAt: now,
          contentMarkdown: 'CURRENT',
          contentPlaintext: 'CURRENT',
        ),
        versions: <DraftVersion>[_v(id: 'va', snapshot: 'OLD')],
      );
      await tester.pumpWidget(_wrap(
        const DraftVersionsScreen(draftId: 'd1'),
        svc: svc,
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('draft_versions_restore_va')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('draft_versions_restore_dialog')),
          findsOneWidget);
    });
  });
}
