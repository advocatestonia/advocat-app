// Tests for the Case Dossier Export client (payload + toggles + demo path).
// ---------------------------------------------------------------------------
// These are pure-logic tests: the payload builder and section-toggle model are
// independent of Supabase. The demo-mode short-circuit is exercised against a
// real (uninitialised) SupabaseService, which reports isDemo=true in the test
// runtime — so no backend call is made.
// ---------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/case_dossier/case_dossier_service.dart';
import 'package:advocat/services/supabase_service.dart';

void main() {
  group('DossierSectionToggles', () {
    test('defaults to everything on', () {
      const t = DossierSectionToggles();
      expect(t.timeline, isTrue);
      expect(t.deadlines, isTrue);
      expect(t.documents, isTrue);
      expect(t.aiSummary, isTrue);
    });

    test('copyWith updates only the named field', () {
      const t = DossierSectionToggles();
      final updated = t.copyWith(timeline: false, documents: false);
      expect(updated.timeline, isFalse);
      expect(updated.documents, isFalse);
      expect(updated.deadlines, isTrue);
      expect(updated.aiSummary, isTrue);
    });

    test('toJson emits all four flags', () {
      const t = DossierSectionToggles(deadlines: false);
      final json = t.toJson();
      expect(json, {
        'timeline': true,
        'deadlines': false,
        'documents': true,
        'aiSummary': true,
      });
    });
  });

  group('DossierExportPayload.build', () {
    test('includes case_id and sections', () {
      final p = DossierExportPayload.build(
        caseId: 'abc-123',
        sections: const DossierSectionToggles(timeline: false),
      );
      expect(p['case_id'], 'abc-123');
      expect((p['sections'] as Map)['timeline'], false);
      expect(p.containsKey('locale'), isFalse);
    });

    test('includes locale when provided and non-blank', () {
      final p = DossierExportPayload.build(
        caseId: 'abc-123',
        sections: const DossierSectionToggles(),
        locale: 'et',
      );
      expect(p['locale'], 'et');
    });

    test('omits blank locale', () {
      final p = DossierExportPayload.build(
        caseId: 'abc-123',
        sections: const DossierSectionToggles(),
        locale: '   ',
      );
      expect(p.containsKey('locale'), isFalse);
    });
  });

  group('CaseDossierService demo mode', () {
    test('returns a synthetic success without a backend', () async {
      final service = CaseDossierService.forTest(SupabaseService());
      final result = await service.export(
        caseId: 'abc-123',
        sections: const DossierSectionToggles(),
      );
      expect(result.ok, isTrue);
      expect(result.downloadUrl, isNotNull);
      expect(result.downloadUrl, contains('dossier'));
    });
  });

  group('DossierExportResult', () {
    test('success factory', () {
      final r = DossierExportResult.success('https://x/y.pdf', 'y.pdf');
      expect(r.ok, isTrue);
      expect(r.downloadUrl, 'https://x/y.pdf');
      expect(r.filename, 'y.pdf');
    });

    test('failure factory carries the error code', () {
      final r = DossierExportResult.failure('no_response');
      expect(r.ok, isFalse);
      expect(r.errorCode, 'no_response');
      expect(r.downloadUrl, isNull);
    });
  });
}
