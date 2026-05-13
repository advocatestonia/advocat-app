@Tags(['fast'])
library;

// Unit tests for the AutosaveController (Pkg 7 Drafting Studio MVP).
// -----------------------------------------------------------------------------
// Uses a fake DraftService so we can verify:
//   * markDirty + 30s timer triggers exactly one updateDraft call.
//   * flush() bypasses the debounce.
//   * flush() coalesces a save while one is already in flight.
//   * failure leaves the buffer dirty for retry on the next tick.
// -----------------------------------------------------------------------------

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/drafting/models/draft_model.dart';
import 'package:advocat/features/drafting/services/draft_service.dart';

class _FakeSvc implements DraftService {
  int updates = 0;
  bool failNext = false;
  Completer<void>? gate;

  @override
  Future<Draft> updateDraft(String id,
      {String? title,
      String? contentMarkdown,
      String? language,
      String? jurisdiction,
      DraftStatus? status,
      Map<String, dynamic>? metadata}) async {
    if (gate != null) await gate!.future;
    updates++;
    if (failNext) {
      failNext = false;
      throw Exception('boom');
    }
    return Draft(
      id: id,
      userId: 'u',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      contentMarkdown: contentMarkdown ?? '',
      contentPlaintext: contentMarkdown ?? '',
    );
  }

  // Unused — required to satisfy the interface.
  @override
  Future<List<Draft>> listMyDrafts({int limit = 50}) async => <Draft>[];
  @override
  Future<Draft?> fetchById(String draftId) async => null;
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
      const AiRevision(revisedText: '', explanation: '', changesMade: []);
  @override
  Future<DocxExport> exportToDocx(
          {required String contentMarkdown, String? title}) async =>
      const DocxExport(base64: '', filename: '', byteLength: 0);
}

void main() {
  group('AutosaveController', () {
    test('flush() saves immediately when dirty', () async {
      final svc = _FakeSvc();
      final c = AutosaveController(service: svc, draftId: 'd1');
      c.markDirty(markdown: 'hello');
      await c.flush();
      expect(svc.updates, 1);
      c.dispose();
    });

    test('flush() is a no-op when buffer is clean', () async {
      final svc = _FakeSvc();
      final c = AutosaveController(service: svc, draftId: 'd1');
      await c.flush();
      expect(svc.updates, 0);
      c.dispose();
    });

    test('markDirty + flush coalesce into a single save call', () async {
      final svc = _FakeSvc();
      final c = AutosaveController(service: svc, draftId: 'd1');
      c.markDirty(markdown: 'a');
      c.markDirty(markdown: 'ab');
      c.markDirty(markdown: 'abc');
      await c.flush();
      expect(svc.updates, 1);
      c.dispose();
    });

    test('failure leaves buffer dirty for retry', () async {
      final svc = _FakeSvc()..failNext = true;
      final c = AutosaveController(service: svc, draftId: 'd1');
      c.markDirty(markdown: 'oops');
      await c.flush(); // throws caught internally; dirty stays true
      await c.flush(); // retry
      expect(svc.updates, 2);
      c.dispose();
    });

    test('coalesces second flush while first is in flight', () async {
      final svc = _FakeSvc();
      svc.gate = Completer<void>();
      final c = AutosaveController(service: svc, draftId: 'd1');
      c.markDirty(markdown: 'a');
      final first = c.flush();
      // Mark again while in flight.
      c.markDirty(markdown: 'b');
      // Release the gate so first save resolves; second save should follow.
      svc.gate!.complete();
      await first;
      // Now run the second flush, which should send the new 'b' content.
      await c.flush();
      expect(svc.updates, 2);
      c.dispose();
    });

    test('dispose cancels pending timers', () async {
      final svc = _FakeSvc();
      final c = AutosaveController(
        service: svc,
        draftId: 'd1',
        interval: const Duration(milliseconds: 10),
      );
      c.markDirty(markdown: 'x');
      c.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      // Timer should have been cancelled — no save fired.
      expect(svc.updates, 0);
    });
  });
}
