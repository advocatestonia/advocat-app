@Tags(['fast'])
library;

import 'package:advocat/models/correspondence.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

void main() {
  group('Correspondence', () {
    // ── fromJson ──────────────────────────────────────────────────────────

    group('fromJson', () {
      test('parses a complete JSON map', () {
        final json = makeCorrespondenceJson(
          id: 'c-1',
          caseId: 'case-42',
          userId: 'user-7',
          subject: 'Decision Notice',
          body: 'Your appeal has been accepted.',
          sender: 'migri@gov.ee',
          recipient: 'user@test.ee',
          direction: 'outgoing',
          channel: 'postal',
          aiSummary: 'Appeal accepted',
          extractedActionItems: ['Submit form A', 'Pay fee'],
          attachmentIds: ['att-1', 'att-2'],
          isRead: true,
          sentAt: fixtureNow.toIso8601String(),
          createdAt: fixturePast.toIso8601String(),
        );

        final corr = Correspondence.fromJson(json);

        expect(corr.id, 'c-1');
        expect(corr.caseId, 'case-42');
        expect(corr.userId, 'user-7');
        expect(corr.subject, 'Decision Notice');
        expect(corr.body, 'Your appeal has been accepted.');
        expect(corr.sender, 'migri@gov.ee');
        expect(corr.recipient, 'user@test.ee');
        expect(corr.direction, CorrespondenceDirection.outgoing);
        expect(corr.channel, CorrespondenceChannel.postal);
        expect(corr.aiSummary, 'Appeal accepted');
        expect(corr.extractedActionItems, ['Submit form A', 'Pay fee']);
        expect(corr.attachmentIds, ['att-1', 'att-2']);
        expect(corr.isRead, isTrue);
        expect(corr.sentAt, fixtureNow);
        expect(corr.createdAt, fixturePast);
      });

      test('applies defaults for missing optional fields', () {
        final json = makeCorrespondenceJson();

        final corr = Correspondence.fromJson(json);

        expect(corr.direction, CorrespondenceDirection.incoming);
        expect(corr.channel, CorrespondenceChannel.email);
        expect(corr.aiSummary, isNull);
        expect(corr.extractedActionItems, isEmpty);
        expect(corr.attachmentIds, isEmpty);
        expect(corr.isRead, isFalse);
      });

      test('maps direction "outgoing" correctly', () {
        final json = makeCorrespondenceJson(direction: 'outgoing');
        final corr = Correspondence.fromJson(json);
        expect(corr.direction, CorrespondenceDirection.outgoing);
      });

      test('maps direction "incoming" correctly', () {
        final json = makeCorrespondenceJson(direction: 'incoming');
        final corr = Correspondence.fromJson(json);
        expect(corr.direction, CorrespondenceDirection.incoming);
      });

      test('maps unknown direction to incoming', () {
        final json = makeCorrespondenceJson(direction: 'unknown');
        final corr = Correspondence.fromJson(json);
        expect(corr.direction, CorrespondenceDirection.incoming);
      });

      test('maps channel "email" correctly', () {
        final json = makeCorrespondenceJson(channel: 'email');
        final corr = Correspondence.fromJson(json);
        expect(corr.channel, CorrespondenceChannel.email);
      });

      test('maps channel "postal" correctly', () {
        final json = makeCorrespondenceJson(channel: 'postal');
        final corr = Correspondence.fromJson(json);
        expect(corr.channel, CorrespondenceChannel.postal);
      });

      test('maps channel "portal" correctly', () {
        final json = makeCorrespondenceJson(channel: 'portal');
        final corr = Correspondence.fromJson(json);
        expect(corr.channel, CorrespondenceChannel.portal);
      });

      test('maps null channel to email', () {
        final json = makeCorrespondenceJson(channel: null);
        final corr = Correspondence.fromJson(json);
        expect(corr.channel, CorrespondenceChannel.email);
      });

      test('maps unknown channel to email', () {
        final json = makeCorrespondenceJson();
        json['channel'] = 'fax';
        final corr = Correspondence.fromJson(json);
        expect(corr.channel, CorrespondenceChannel.email);
      });

      test('handles null extracted_action_items', () {
        final json = makeCorrespondenceJson();
        json['extracted_action_items'] = null;
        final corr = Correspondence.fromJson(json);
        expect(corr.extractedActionItems, isEmpty);
      });

      test('handles null attachment_ids', () {
        final json = makeCorrespondenceJson();
        json['attachment_ids'] = null;
        final corr = Correspondence.fromJson(json);
        expect(corr.attachmentIds, isEmpty);
      });

      test('handles null is_read as false', () {
        final json = makeCorrespondenceJson();
        json['is_read'] = null;
        final corr = Correspondence.fromJson(json);
        expect(corr.isRead, isFalse);
      });
    });

    // ── toJson ────────────────────────────────────────────────────────────

    group('toJson', () {
      test('serialises all fields', () {
        final corr = makeCorrespondence(
          id: 'c-1',
          caseId: 'case-42',
          userId: 'user-7',
          subject: 'Test',
          body: 'Body text',
          sender: 'a@b.com',
          recipient: 'c@d.com',
          direction: CorrespondenceDirection.outgoing,
          channel: CorrespondenceChannel.portal,
          aiSummary: 'Summary',
          extractedActionItems: ['item1'],
          attachmentIds: ['att-1'],
          isRead: true,
          sentAt: fixtureNow,
          createdAt: fixturePast,
        );

        final json = corr.toJson();

        expect(json['id'], 'c-1');
        expect(json['case_id'], 'case-42');
        expect(json['user_id'], 'user-7');
        expect(json['subject'], 'Test');
        expect(json['body'], 'Body text');
        expect(json['sender'], 'a@b.com');
        expect(json['recipient'], 'c@d.com');
        expect(json['direction'], 'outgoing');
        expect(json['channel'], 'portal');
        expect(json['ai_summary'], 'Summary');
        expect(json['extracted_action_items'], ['item1']);
        expect(json['attachment_ids'], ['att-1']);
        expect(json['is_read'], isTrue);
        expect(json['sent_at'], fixtureNow.toIso8601String());
        expect(json['created_at'], fixturePast.toIso8601String());
      });

      test('serialises incoming direction', () {
        final corr = makeCorrespondence(
          direction: CorrespondenceDirection.incoming,
        );
        expect(corr.toJson()['direction'], 'incoming');
      });

      test('serialises email channel', () {
        final corr = makeCorrespondence(
          channel: CorrespondenceChannel.email,
        );
        expect(corr.toJson()['channel'], 'email');
      });

      test('serialises postal channel', () {
        final corr = makeCorrespondence(
          channel: CorrespondenceChannel.postal,
        );
        expect(corr.toJson()['channel'], 'postal');
      });

      test('serialises null aiSummary', () {
        final corr = makeCorrespondence(aiSummary: null);
        expect(corr.toJson()['ai_summary'], isNull);
      });
    });

    // ── fromJson / toJson round-trip ──────────────────────────────────────

    test('round-trip: fromJson(toJson(corr)) preserves data', () {
      final original = makeCorrespondence(
        id: 'round-trip',
        caseId: 'case-rt',
        userId: 'user-rt',
        subject: 'Round Trip',
        body: 'Body',
        sender: 'a@b.ee',
        recipient: 'c@d.ee',
        direction: CorrespondenceDirection.outgoing,
        channel: CorrespondenceChannel.postal,
        aiSummary: 'AI summary',
        extractedActionItems: ['action1', 'action2'],
        attachmentIds: ['att-x'],
        isRead: true,
        sentAt: fixtureNow,
        createdAt: fixturePast,
      );

      final restored = Correspondence.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.caseId, original.caseId);
      expect(restored.userId, original.userId);
      expect(restored.subject, original.subject);
      expect(restored.body, original.body);
      expect(restored.sender, original.sender);
      expect(restored.recipient, original.recipient);
      expect(restored.direction, original.direction);
      expect(restored.channel, original.channel);
      expect(restored.aiSummary, original.aiSummary);
      expect(restored.extractedActionItems, original.extractedActionItems);
      expect(restored.attachmentIds, original.attachmentIds);
      expect(restored.isRead, original.isRead);
      expect(restored.sentAt, original.sentAt);
      expect(restored.createdAt, original.createdAt);
    });

    // ── copyWith ──────────────────────────────────────────────────────────

    group('copyWith', () {
      test('copies with changed fields', () {
        final corr = makeCorrespondence();
        final copy = corr.copyWith(
          subject: 'New Subject',
          isRead: true,
          direction: CorrespondenceDirection.outgoing,
        );

        expect(copy.subject, 'New Subject');
        expect(copy.isRead, isTrue);
        expect(copy.direction, CorrespondenceDirection.outgoing);
        // Unchanged fields
        expect(copy.id, corr.id);
        expect(copy.body, corr.body);
        expect(copy.sender, corr.sender);
      });

      test('copies with no changes returns equivalent object', () {
        final corr = makeCorrespondence();
        final copy = corr.copyWith();
        expect(copy.id, corr.id);
        expect(copy.subject, corr.subject);
        expect(copy.body, corr.body);
        expect(copy.direction, corr.direction);
        expect(copy.channel, corr.channel);
        expect(copy.isRead, corr.isRead);
      });

      test('copies with new extractedActionItems', () {
        final corr = makeCorrespondence(extractedActionItems: ['old']);
        final copy = corr.copyWith(extractedActionItems: ['new1', 'new2']);
        expect(copy.extractedActionItems, ['new1', 'new2']);
      });

      test('copies with new attachmentIds', () {
        final corr = makeCorrespondence(attachmentIds: ['old-att']);
        final copy = corr.copyWith(attachmentIds: ['new-att']);
        expect(copy.attachmentIds, ['new-att']);
      });
    });

    // ── Constructor defaults ──────────────────────────────────────────────

    group('constructor defaults', () {
      test('direction defaults to incoming', () {
        final corr = Correspondence(
          id: 'd',
          caseId: 'c',
          userId: 'u',
          subject: 's',
          body: 'b',
          sender: 'a@b.com',
          recipient: 'c@d.com',
          sentAt: fixtureNow,
          createdAt: fixtureNow,
        );
        expect(corr.direction, CorrespondenceDirection.incoming);
      });

      test('channel defaults to email', () {
        final corr = Correspondence(
          id: 'd',
          caseId: 'c',
          userId: 'u',
          subject: 's',
          body: 'b',
          sender: 'a@b.com',
          recipient: 'c@d.com',
          sentAt: fixtureNow,
          createdAt: fixtureNow,
        );
        expect(corr.channel, CorrespondenceChannel.email);
      });

      test('aiSummary defaults to null', () {
        final corr = makeCorrespondence();
        expect(corr.aiSummary, isNull);
      });

      test('extractedActionItems defaults to empty list', () {
        final corr = makeCorrespondence();
        expect(corr.extractedActionItems, isEmpty);
      });

      test('attachmentIds defaults to empty list', () {
        final corr = makeCorrespondence();
        expect(corr.attachmentIds, isEmpty);
      });

      test('isRead defaults to false', () {
        final corr = makeCorrespondence();
        expect(corr.isRead, isFalse);
      });
    });

    // ── Enum completeness ────────────────────────────────────────────────

    group('CorrespondenceDirection', () {
      test('has exactly 2 values', () {
        expect(CorrespondenceDirection.values.length, 2);
      });

      test('contains incoming and outgoing', () {
        expect(
          CorrespondenceDirection.values,
          containsAll([
            CorrespondenceDirection.incoming,
            CorrespondenceDirection.outgoing,
          ]),
        );
      });
    });

    group('CorrespondenceChannel', () {
      test('has exactly 3 values', () {
        expect(CorrespondenceChannel.values.length, 3);
      });

      test('contains email, postal, portal', () {
        expect(
          CorrespondenceChannel.values,
          containsAll([
            CorrespondenceChannel.email,
            CorrespondenceChannel.postal,
            CorrespondenceChannel.portal,
          ]),
        );
      });
    });
  });
}
