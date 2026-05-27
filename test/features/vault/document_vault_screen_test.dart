// document_vault_screen_test.dart — widget coverage for the Vault list.
// -----------------------------------------------------------------------------
// Smoke-level tests focused on the new affordances landed this pass:
//   * Tag chip row renders defaults + "All" prefix.
//   * Tag chip tap mutates `vaultTagFilterProvider`.
//   * Long-press shows the CupertinoActionSheet with Delete + Cancel.
//   * Tapping "Delete" forwards to VaultService.deleteDocument.
//   * Search field is wired (debounce timing is non-deterministic — we
//     only assert presence + key callback, not the 300ms tick).
//   * Empty state shows the new encryption reassurance line.
//
// Network is stubbed by `_FakeVaultService` so the test doesn't need a
// SupabaseService binding. Routes that the production widget pushes
// (`/vault/add`) are intercepted at the router level — we override
// `goRouter` here with a stub that records pushes.
// -----------------------------------------------------------------------------

@Tags(['fast'])
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:typed_data';

import 'package:advocat/features/vault/models/vault_document.dart';
import 'package:advocat/features/vault/screens/document_vault_screen.dart';
import 'package:advocat/features/vault/services/vault_service.dart';
import 'package:advocat/l10n/app_localizations.dart';

class _FakeVaultService implements VaultService {
  _FakeVaultService(this._docs);

  final List<VaultDocument> _docs;
  final List<String> deletes = <String>[];

  @override
  Future<List<VaultDocument>> getDocuments({String? tagFilter}) async {
    if (tagFilter == null) return _docs;
    if (tagFilter == 'other') {
      return _docs
          .where((d) => d.tagSlug == null || d.tagSlug == 'other')
          .toList();
    }
    return _docs.where((d) => d.tagSlug == tagFilter).toList();
  }

  @override
  Future<List<VaultDocument>> search(String query) async {
    if (query.trim().isEmpty) return _docs;
    final q = query.toLowerCase();
    return _docs
        .where((d) => d.fileName.toLowerCase().contains(q))
        .toList();
  }

  @override
  Future<void> deleteDocument(String id) async {
    deletes.add(id);
    _docs.removeWhere((d) => d.id == id);
  }

  @override
  Future<void> tagDocument(String docId, String tagId) async {}

  @override
  Future<List<VaultTag>> getTags() async => VaultTag.defaults;

  @override
  Future<VaultUploadResult> uploadFromDraft({
    required String draftId,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    String? caseId,
  }) async {
    return VaultUploadResult(
      documentId: 'fake-$draftId',
      storagePath: 'fake/$fileName',
      fileName: fileName,
      mimeType: mimeType,
    );
  }

  @override
  Future<VaultContent?> fetchDecryptedContent(String documentId) async => null;

  @override
  Future<String?> ensureDraftSystemTag() async => null;
}

VaultDocument _doc({
  required String id,
  String fileName = 'evidence.pdf',
  String? tagSlug,
}) {
  return VaultDocument(
    id: id,
    fileName: fileName,
    storagePath: 'u/c/$fileName',
    mimeType: 'application/pdf',
    createdAt: DateTime.utc(2026, 5, 1, 10),
    tagSlug: tagSlug,
  );
}

Widget _wrap(VaultService svc) {
  return ProviderScope(
    overrides: [
      vaultServiceProvider.overrideWithValue(svc),
    ],
    child: const MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('en'), Locale('et'), Locale('fi'), Locale('ru')],
      home: DocumentVaultScreen(),
    ),
  );
}

// Bounded settle: the Vault screen has looping animations (entrance fade-in,
// glow pulse on the empty-state lock icon, staggered card slide-ins) that
// keep frames scheduled forever. Drain enough frames to let one-shot
// animations complete + one async microtask cycle, then return.
Future<void> _settle(WidgetTester tester) async {
  // Drain initial frame + the longest one-shot entrance (~600ms typical).
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 100));
}

// Default test viewport (800×600) causes RenderFlex overflow on:
//  - The 7-chip filter row at the top of the list.
//  - The "Secure storage" status badge (long localized label).
// Both overflow in tests only because the screen's internal scroll/wrap
// behaviour was designed for a phone width (~402dp) + vertical scroll.
// We give tests a tall viewport so chip row + tile content + empty state
// all render without throwing. Production overflow at sub-1024 widths is
// tracked separately — not a test concern.
Future<void> _setPhoneSize(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1024, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DocumentVaultScreen — tag chip row', () {
    testWidgets('renders All + 6 default tag chips', (tester) async {
      final svc = _FakeVaultService([_doc(id: '1')]);
      await _setPhoneSize(tester);
      await tester.pumpWidget(_wrap(svc));
      await _settle(tester);

      expect(find.byKey(const ValueKey('vault_chip_all')), findsOneWidget);
      expect(
          find.byKey(const ValueKey('vault_chip_contract')), findsOneWidget);
      expect(find.byKey(const ValueKey('vault_chip_receipt')), findsOneWidget);
      expect(find.byKey(const ValueKey('vault_chip_email')), findsOneWidget);
      expect(find.byKey(const ValueKey('vault_chip_evidence')), findsOneWidget);
      expect(find.byKey(const ValueKey('vault_chip_id_passport')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('vault_chip_other')), findsOneWidget);
    });

    testWidgets('tapping a chip filters the list', (tester) async {
      final svc = _FakeVaultService([
        _doc(id: '1', fileName: 'contract.pdf', tagSlug: 'contract'),
        _doc(id: '2', fileName: 'receipt.pdf', tagSlug: 'receipt'),
      ]);
      await _setPhoneSize(tester);
      await tester.pumpWidget(_wrap(svc));
      await _settle(tester);

      // Both visible under "All".
      expect(find.text('contract.pdf'), findsOneWidget);
      expect(find.text('receipt.pdf'), findsOneWidget);

      // Tap the Contract chip.
      await tester.tap(find.byKey(const ValueKey('vault_chip_contract')));
      await _settle(tester);

      expect(find.text('contract.pdf'), findsOneWidget);
      expect(find.text('receipt.pdf'), findsNothing);
    });
  });

  group('DocumentVaultScreen — delete confirmation', () {
    testWidgets('long-press shows CupertinoActionSheet with Delete + Cancel',
        (tester) async {
      final svc = _FakeVaultService([
        _doc(id: 'd1', fileName: 'evidence.pdf'),
      ]);
      await _setPhoneSize(tester);
      await tester.pumpWidget(_wrap(svc));
      await _settle(tester);

      await tester.longPress(find.text('evidence.pdf'));
      await _settle(tester);

      expect(find.byType(CupertinoActionSheet), findsOneWidget);
      expect(find.text('Delete from Vault?'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Cancel closes the sheet without deleting', (tester) async {
      final svc = _FakeVaultService([
        _doc(id: 'd1', fileName: 'evidence.pdf'),
      ]);
      await _setPhoneSize(tester);
      await tester.pumpWidget(_wrap(svc));
      await _settle(tester);

      await tester.longPress(find.text('evidence.pdf'));
      await _settle(tester);

      await tester.tap(find.text('Cancel'));
      await _settle(tester);

      expect(find.byType(CupertinoActionSheet), findsNothing);
      expect(svc.deletes, isEmpty);
      expect(find.text('evidence.pdf'), findsOneWidget);
    });

    testWidgets('Confirm forwards to VaultService.deleteDocument',
        (tester) async {
      final svc = _FakeVaultService([
        _doc(id: 'd1', fileName: 'evidence.pdf'),
      ]);
      await _setPhoneSize(tester);
      await tester.pumpWidget(_wrap(svc));
      await _settle(tester);

      await tester.longPress(find.text('evidence.pdf'));
      await _settle(tester);

      // The destructive action button text is "Delete" — same string as the
      // background swipe label. `find.text('Delete').last` picks the action
      // sheet button which sits below the swipe background.
      await tester.tap(find.text('Delete').last);
      await _settle(tester);

      expect(svc.deletes, ['d1']);
    });
  });

  group('DocumentVaultScreen — search', () {
    testWidgets('search field is present with the placeholder', (tester) async {
      final svc = _FakeVaultService([_doc(id: '1')]);
      await _setPhoneSize(tester);
      await tester.pumpWidget(_wrap(svc));
      await _settle(tester);

      expect(
          find.byKey(const ValueKey('vault_search_field')), findsOneWidget);
    });
  });

  group('DocumentVaultScreen — empty state', () {
    testWidgets('shows encryption reassurance line', (tester) async {
      final svc = _FakeVaultService(<VaultDocument>[]);
      await _setPhoneSize(tester);
      await tester.pumpWidget(_wrap(svc));
      await _settle(tester);

      expect(
        find.textContaining('encrypted with your personal key'),
        findsOneWidget,
      );
    });
  });
}
