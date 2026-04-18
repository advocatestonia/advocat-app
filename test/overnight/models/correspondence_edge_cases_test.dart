// Overnight isolated test suite — DOES NOT modify production code.
// Edge-case coverage for Correspondence model.
import 'package:flutter_test/flutter_test.dart';
import 'package:advocat/models/correspondence.dart';

void main() {
  group('Correspondence overnight edge cases', () {
    test('all CorrespondenceDirection values round-trip', () {
      for (final dir in CorrespondenceDirection.values) {
        final c = Correspondence(
          id: 'c1',
          caseId: 'case1',
          userId: 'u1',
          subject: 'S',
          body: 'B',
          sender: 'a@x.com',
          recipient: 'b@x.com',
          direction: dir,
          sentAt: DateTime.utc(2024, 5, 1),
          createdAt: DateTime.utc(2024, 1, 1),
        );
        final decoded = Correspondence.fromJson(c.toJson());
        expect(decoded.direction, dir);
      }
    });

    test('all CorrespondenceChannel values round-trip', () {
      for (final ch in CorrespondenceChannel.values) {
        final c = Correspondence(
          id: 'c1',
          caseId: 'case1',
          userId: 'u1',
          subject: 'S',
          body: 'B',
          sender: 'a@x.com',
          recipient: 'b@x.com',
          channel: ch,
          sentAt: DateTime.utc(2024, 5, 1),
          createdAt: DateTime.utc(2024, 1, 1),
        );
        final decoded = Correspondence.fromJson(c.toJson());
        expect(decoded.channel, ch);
      }
    });

    test('unknown direction in JSON treated as incoming', () {
      final c = Correspondence.fromJson({
        'id': 'c1',
        'case_id': 'case1',
        'user_id': 'u1',
        'subject': 'S',
        'body': 'B',
        'sender': 'a@x.com',
        'recipient': 'b@x.com',
        'direction': 'diagonal',
        'sent_at': '2024-05-01T00:00:00.000Z',
        'created_at': '2024-01-01T00:00:00.000Z',
      });
      expect(c.direction, CorrespondenceDirection.incoming);
    });

    test('unknown channel falls back to email', () {
      final c = Correspondence.fromJson({
        'id': 'c1',
        'case_id': 'case1',
        'user_id': 'u1',
        'subject': 'S',
        'body': 'B',
        'sender': 'a@x.com',
        'recipient': 'b@x.com',
        'channel': 'carrier_pigeon',
        'sent_at': '2024-05-01T00:00:00.000Z',
        'created_at': '2024-01-01T00:00:00.000Z',
      });
      expect(c.channel, CorrespondenceChannel.email);
    });

    test('lists default to empty when absent', () {
      final c = Correspondence.fromJson({
        'id': 'c1',
        'case_id': 'case1',
        'user_id': 'u1',
        'subject': 'S',
        'body': 'B',
        'sender': 'a@x.com',
        'recipient': 'b@x.com',
        'sent_at': '2024-05-01T00:00:00.000Z',
        'created_at': '2024-01-01T00:00:00.000Z',
      });
      expect(c.extractedActionItems, isEmpty);
      expect(c.attachmentIds, isEmpty);
      expect(c.isRead, isFalse);
    });

    test('extracted action items + attachment ids round-trip cleanly', () {
      final c = Correspondence(
        id: 'c1',
        caseId: 'case1',
        userId: 'u1',
        subject: 'S',
        body: 'B',
        sender: 'a@x.com',
        recipient: 'b@x.com',
        extractedActionItems: const ['reply_by_monday', 'upload_passport'],
        attachmentIds: const ['att1', 'att2', 'att3'],
        isRead: true,
        sentAt: DateTime.utc(2024, 5, 1),
        createdAt: DateTime.utc(2024, 1, 1),
      );
      final b = Correspondence.fromJson(c.toJson());
      expect(b.extractedActionItems, ['reply_by_monday', 'upload_passport']);
      expect(b.attachmentIds, ['att1', 'att2', 'att3']);
      expect(b.isRead, isTrue);
    });

    test('copyWith overrides single field, keeps rest', () {
      final a = Correspondence(
        id: 'c1',
        caseId: 'case1',
        userId: 'u1',
        subject: 'Subject',
        body: 'Body',
        sender: 'a@x.com',
        recipient: 'b@x.com',
        sentAt: DateTime.utc(2024, 5, 1),
        createdAt: DateTime.utc(2024, 1, 1),
      );
      final b = a.copyWith(isRead: true, subject: 'Re: Subject');
      expect(b.isRead, isTrue);
      expect(b.subject, 'Re: Subject');
      expect(b.body, 'Body');
      expect(b.sender, 'a@x.com');
    });
  });
}
