@Tags(['fast'])
library;

import 'package:advocat/models/case_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

void main() {
  group('LegalCase', () {
    // ── fromJson ──────────────────────────────────────────────────────────

    group('fromJson', () {
      test('parses a complete JSON map', () {
        final json = makeCaseJson(
          id: 'c-1',
          userId: 'u-1',
          title: 'Deportation Appeal',
          description: 'Appealing deportation order',
          type: 'asylum',
          status: 'in_court',
          migriReferenceNumber: 'MR-12345',
          courtCaseNumber: 'CC-67890',
          nationality: 'Estonian',
          decisionDate: fixtureNow.toIso8601String(),
          appealDeadline: fixtureFuture.toIso8601String(),
          hearingDate: fixtureFuture.toIso8601String(),
          createdAt: fixtureNow.toIso8601String(),
          updatedAt: fixtureNow.toIso8601String(),
          documentCount: 5,
          unreadMessages: 3,
        );

        final legalCase = LegalCase.fromJson(json);

        expect(legalCase.id, 'c-1');
        expect(legalCase.userId, 'u-1');
        expect(legalCase.title, 'Deportation Appeal');
        expect(legalCase.description, 'Appealing deportation order');
        expect(legalCase.type, CaseType.asylum);
        expect(legalCase.status, CaseStatus.inCourt);
        expect(legalCase.migriReferenceNumber, 'MR-12345');
        expect(legalCase.courtCaseNumber, 'CC-67890');
        expect(legalCase.nationality, 'Estonian');
        expect(legalCase.decisionDate, fixtureNow);
        expect(legalCase.appealDeadline, fixtureFuture);
        expect(legalCase.hearingDate, fixtureFuture);
        expect(legalCase.documentCount, 5);
        expect(legalCase.unreadMessages, 3);
      });

      test('applies defaults for missing optional fields', () {
        final json = {
          'id': 'c-2',
          'user_id': 'u-2',
          'title': 'Minimal Case',
          'created_at': fixtureNow.toIso8601String(),
        };

        final legalCase = LegalCase.fromJson(json);

        expect(legalCase.description, isNull);
        expect(legalCase.type, CaseType.deportation);
        expect(legalCase.status, CaseStatus.active);
        expect(legalCase.migriReferenceNumber, isNull);
        expect(legalCase.courtCaseNumber, isNull);
        expect(legalCase.nationality, isNull);
        expect(legalCase.decisionDate, isNull);
        expect(legalCase.appealDeadline, isNull);
        expect(legalCase.hearingDate, isNull);
        expect(legalCase.updatedAt, isNull);
        expect(legalCase.documentCount, 0);
        expect(legalCase.unreadMessages, 0);
      });

      test('maps unknown type to deportation', () {
        final json = makeCaseJson(type: 'unknown_type');
        expect(LegalCase.fromJson(json).type, CaseType.deportation);
      });

      test('maps null type to deportation', () {
        final json = makeCaseJson();
        json['type'] = null;
        expect(LegalCase.fromJson(json).type, CaseType.deportation);
      });

      test('maps unknown status to active', () {
        final json = makeCaseJson(status: 'unknown_status');
        expect(LegalCase.fromJson(json).status, CaseStatus.active);
      });
    });

    // ── toJson ────────────────────────────────────────────────────────────

    group('toJson', () {
      test('serialises all fields', () {
        final c = makeCase(
          id: 'c-1',
          userId: 'u-1',
          title: 'Test',
          description: 'Desc',
          type: CaseType.asylum,
          status: CaseStatus.inCourt,
          migriReferenceNumber: 'MR-1',
          courtCaseNumber: 'CC-1',
          nationality: 'FI',
          decisionDate: fixtureNow,
          appealDeadline: fixtureFuture,
          hearingDate: fixtureFuture,
          createdAt: fixtureNow,
          updatedAt: fixtureNow,
          documentCount: 2,
          unreadMessages: 1,
        );

        final json = c.toJson();

        expect(json['id'], 'c-1');
        expect(json['user_id'], 'u-1');
        expect(json['title'], 'Test');
        expect(json['description'], 'Desc');
        expect(json['type'], 'asylum');
        expect(json['status'], 'in_court');
        expect(json['migri_reference_number'], 'MR-1');
        expect(json['court_case_number'], 'CC-1');
        expect(json['nationality'], 'FI');
        expect(json['document_count'], 2);
        expect(json['unread_messages'], 1);
      });
    });

    // ── Round-trip ────────────────────────────────────────────────────────

    test('round-trip: fromJson(toJson(case)) preserves data', () {
      final original = makeCase(
        id: 'rt-1',
        type: CaseType.familyReunification,
        status: CaseStatus.appealFiled,
        documentCount: 10,
      );

      final restored = LegalCase.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.type, original.type);
      expect(restored.status, original.status);
      expect(restored.documentCount, original.documentCount);
    });

    // ── copyWith ──────────────────────────────────────────────────────────

    group('copyWith', () {
      test('changes specified fields', () {
        final c = makeCase(title: 'Old Title', status: CaseStatus.active);
        final copy = c.copyWith(
          title: 'New Title',
          status: CaseStatus.resolved,
        );

        expect(copy.title, 'New Title');
        expect(copy.status, CaseStatus.resolved);
        expect(copy.id, c.id);
        expect(copy.type, c.type);
      });

      test('copies with no changes', () {
        final c = makeCase();
        final copy = c.copyWith();
        expect(copy.id, c.id);
        expect(copy.title, c.title);
      });
    });

    // ── CaseType enum ────────────────────────────────────────────────────

    group('CaseType enum', () {
      test('has 16 values', () {
        expect(CaseType.values.length, 16);
      });

      test('all values survive JSON round-trip', () {
        for (final caseType in CaseType.values) {
          final c = makeCase(type: caseType);
          final json = c.toJson();
          final restored = LegalCase.fromJson(json);
          expect(restored.type, caseType,
              reason: '${caseType.name} should round-trip');
        }
      });

      test('JSON string values are snake_case', () {
        final expectedMappings = {
          CaseType.deportation: 'deportation',
          CaseType.asylum: 'asylum',
          CaseType.residencePermit: 'residence_permit',
          CaseType.familyReunification: 'family_reunification',
          CaseType.citizenship: 'citizenship',
          CaseType.workPermit: 'work_permit',
          CaseType.laborDispute: 'labor_dispute',
          CaseType.tenantRights: 'tenant_rights',
          CaseType.debtCollection: 'debt_collection',
          CaseType.discrimination: 'discrimination',
          CaseType.policeMisconduct: 'police_misconduct',
          CaseType.socialBenefits: 'social_benefits',
          CaseType.domesticViolence: 'domestic_violence',
          CaseType.consumerProtection: 'consumer_protection',
          CaseType.inheritance: 'inheritance',
          CaseType.other: 'other',
        };

        for (final entry in expectedMappings.entries) {
          final c = makeCase(type: entry.key);
          expect(c.toJson()['type'], entry.value);
        }
      });
    });

    // ── CaseStatus enum ──────────────────────────────────────────────────

    group('CaseStatus enum', () {
      test('has 6 values', () {
        expect(CaseStatus.values.length, 6);
      });

      test('all values survive JSON round-trip', () {
        for (final status in CaseStatus.values) {
          final c = makeCase(status: status);
          final json = c.toJson();
          final restored = LegalCase.fromJson(json);
          expect(restored.status, status,
              reason: '${status.name} should round-trip');
        }
      });

      test('JSON string values are snake_case', () {
        final expectedMappings = {
          CaseStatus.active: 'active',
          CaseStatus.pendingDecision: 'pending_decision',
          CaseStatus.appealFiled: 'appeal_filed',
          CaseStatus.inCourt: 'in_court',
          CaseStatus.resolved: 'resolved',
          CaseStatus.closed: 'closed',
        };

        for (final entry in expectedMappings.entries) {
          final c = makeCase(status: entry.key);
          expect(c.toJson()['status'], entry.value);
        }
      });
    });
  });
}
