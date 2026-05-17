// Pure unit tests for the lawyer-partnership model layer (Day2-E).
// -----------------------------------------------------------------------------
// Ref: lib/features/lawyer_partnership/models/lawyer_partnership_state.dart
//
// Three things under test:
//   * BookingRequest.isComplete — client-side form gate.
//   * BookingRequest.toJson      — request envelope shape (matches edge fn).
//   * LawyerBooking.fromJson     — server row → model parsing.
//   * BookingStatus.parse        — DB column → enum mapping.
//
// No widget tree, no Supabase mock — these stay fast (sub-100 ms total).
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';
import 'package:advocat/features/lawyer_partnership/models/lawyer_partnership_state.dart';

void main() {
  group('BookingRequest.isComplete', () {
    test('rejects empty request', () {
      expect(const BookingRequest().isComplete, isFalse);
    });

    test('rejects missing topic', () {
      final req = const BookingRequest()
          .copyWith(timePreference: 'weekday mornings');
      expect(req.isComplete, isFalse);
    });

    test('rejects topic=other without freeFormTopic', () {
      final req = const BookingRequest().copyWith(
        topic: BookingTopic.other,
        timePreference: 'weekday mornings',
      );
      expect(req.isComplete, isFalse);
    });

    test('accepts topic=other with freeFormTopic >= 3 chars', () {
      final req = const BookingRequest().copyWith(
        topic: BookingTopic.other,
        freeFormTopic: 'Crypto inheritance',
        timePreference: 'weekday mornings',
      );
      expect(req.isComplete, isTrue);
    });

    test('rejects neither slot nor time preference', () {
      final req = const BookingRequest().copyWith(topic: BookingTopic.family);
      expect(req.isComplete, isFalse);
    });

    test('accepts a complete minimal payload (slot)', () {
      final future = DateTime.now().add(const Duration(days: 3));
      final req = const BookingRequest().copyWith(
        topic: BookingTopic.family,
        scheduledAt: future,
      );
      expect(req.isComplete, isTrue);
    });

    test('accepts a complete minimal payload (time preference only)', () {
      final req = const BookingRequest().copyWith(
        topic: BookingTopic.tenancy,
        timePreference: 'weekday mornings',
      );
      expect(req.isComplete, isTrue);
    });

    test('rejects bad language length', () {
      final req = const BookingRequest().copyWith(
        topic: BookingTopic.family,
        timePreference: 'morn',
        language: 'eng',
      );
      expect(req.isComplete, isFalse);
    });

    test('rejects overlong user brief', () {
      final req = const BookingRequest().copyWith(
        topic: BookingTopic.family,
        timePreference: 'morn',
        userBrief: 'x' * 4001,
      );
      expect(req.isComplete, isFalse);
    });

    test('rejects overlong time preference', () {
      final req = const BookingRequest().copyWith(
        topic: BookingTopic.family,
        timePreference: 'x' * 201,
      );
      expect(req.isComplete, isFalse);
    });
  });

  group('BookingRequest.toJson', () {
    test('emits canonical topic token for bucketed topics', () {
      final req = const BookingRequest().copyWith(
        topic: BookingTopic.immigration,
        timePreference: 'mornings',
      );
      final j = req.toJson();
      expect(j['op'], 'create');
      expect(j['topic'], 'immigration');
      expect(j['language'], 'et');
      expect(j['time_preference'], 'mornings');
      expect(j.containsKey('lawyer_id'), isFalse);
      expect(j.containsKey('case_id'), isFalse);
      expect(j.containsKey('scheduled_at'), isFalse);
    });

    test('emits freeFormTopic when topic=other', () {
      final req = const BookingRequest().copyWith(
        topic: BookingTopic.other,
        freeFormTopic: 'Mortgage refinancing',
        timePreference: 'mornings',
      );
      expect(req.toJson()['topic'], 'Mortgage refinancing');
    });

    test('includes lawyer_id, case_id, scheduled_at when present', () {
      final future = DateTime.utc(2026, 6, 1, 10);
      final req = const BookingRequest().copyWith(
        topic: BookingTopic.family,
        lawyerId: '11111111-1111-4111-8111-111111111111',
        caseId: '22222222-2222-4222-8222-222222222222',
        scheduledAt: future,
        userBrief: 'Want to talk about divorce settlement.',
      );
      final j = req.toJson();
      expect(j['lawyer_id'], '11111111-1111-4111-8111-111111111111');
      expect(j['case_id'], '22222222-2222-4222-8222-222222222222');
      expect(j['scheduled_at'], '2026-06-01T10:00:00.000Z');
      expect(j['user_brief'], 'Want to talk about divorce settlement.');
    });

    test('trims user_brief whitespace', () {
      final req = const BookingRequest().copyWith(
        topic: BookingTopic.family,
        timePreference: 'morn',
        userBrief: '   spaces around   ',
      );
      expect(req.toJson()['user_brief'], 'spaces around');
    });
  });

  group('LawyerBooking.fromJson', () {
    test('parses a fully-populated row', () {
      final b = LawyerBooking.fromJson(<String, dynamic>{
        'id': 'b1',
        'user_id': 'u1',
        'lawyer_id': 'l1',
        'topic': 'family',
        'language': 'et',
        'duration_minutes': 15,
        'scheduled_at': '2026-06-01T10:00:00Z',
        'status': 'confirmed',
        'quota_quarter': '2026-Q2',
        'created_at': '2026-05-16T10:00:00Z',
        'ai_brief_md': '## Situation\n- topic: family',
      });
      expect(b.id, 'b1');
      expect(b.lawyerId, 'l1');
      expect(b.status, BookingStatus.confirmed);
      expect(b.scheduledAt!.year, 2026);
      expect(b.aiBriefMd, contains('## Situation'));
    });

    test('tolerates missing optional fields', () {
      final b = LawyerBooking.fromJson(<String, dynamic>{
        'id': 'b2',
        'user_id': 'u2',
        'status': 'requested',
      });
      expect(b.status, BookingStatus.requested);
      expect(b.topic, 'other');
      expect(b.language, 'et');
      expect(b.lawyerId, isNull);
      expect(b.scheduledAt, isNull);
      expect(b.durationMinutes, 15);
    });
  });

  group('BookingStatus.parse', () {
    test('maps all known DB values', () {
      expect(BookingStatus.parse('requested'), BookingStatus.requested);
      expect(BookingStatus.parse('assigned'), BookingStatus.assigned);
      expect(BookingStatus.parse('confirmed'), BookingStatus.confirmed);
      expect(BookingStatus.parse('completed'), BookingStatus.completed);
      expect(BookingStatus.parse('cancelled'), BookingStatus.cancelled);
      expect(BookingStatus.parse('no_show'), BookingStatus.noShow);
    });

    test('falls back to requested on unknown / null', () {
      expect(BookingStatus.parse(null), BookingStatus.requested);
      expect(BookingStatus.parse('foo'), BookingStatus.requested);
    });

    test('isUpcoming / isFinal predicates', () {
      expect(BookingStatus.requested.isUpcoming, isTrue);
      expect(BookingStatus.assigned.isUpcoming, isTrue);
      expect(BookingStatus.confirmed.isUpcoming, isTrue);
      expect(BookingStatus.completed.isUpcoming, isFalse);
      expect(BookingStatus.completed.isFinal, isTrue);
      expect(BookingStatus.cancelled.isFinal, isTrue);
      expect(BookingStatus.noShow.isFinal, isTrue);
    });
  });

  group('BookingQuota', () {
    test('remaining and canBook derive correctly', () {
      const q = BookingQuota(quotaTotal: 2, quotaUsed: 1, quarter: '2026-Q2');
      expect(q.remaining, 1);
      expect(q.canBook, isTrue);
    });

    test('canBook false when used == total', () {
      const q = BookingQuota(quotaTotal: 1, quotaUsed: 1, quarter: '2026-Q2');
      expect(q.canBook, isFalse);
      expect(q.remaining, 0);
    });

    test('clamps remaining to zero when used exceeds total (race)', () {
      const q = BookingQuota(quotaTotal: 1, quotaUsed: 5, quarter: '2026-Q2');
      expect(q.remaining, 0);
      expect(q.canBook, isFalse);
    });
  });

  group('BookingTopic.tryParse', () {
    test('round-trip on every value', () {
      for (final t in BookingTopic.values) {
        expect(BookingTopic.tryParse(t.token), t);
      }
    });

    test('case-insensitive', () {
      expect(BookingTopic.tryParse('IMMIGRATION'), BookingTopic.immigration);
    });

    test('null / unknown → null', () {
      expect(BookingTopic.tryParse(null), isNull);
      expect(BookingTopic.tryParse('not-a-topic'), isNull);
    });
  });
}
