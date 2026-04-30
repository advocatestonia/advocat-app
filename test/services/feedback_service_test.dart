@Tags(['fast'])
library;

// Tests for [FeedbackService] — pure unit coverage for the input shaping
// (preview truncation, prompt hashing, payload composition) without hitting
// Supabase. The Supabase round-trip is exercised by integration tests.
//
// These tests run in fast mode (no network) so they fit inside the
// pre-commit budget.

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/feedback_service.dart';

void main() {
  group('FeedbackService — payload shaping', () {
    test('buildPayload truncates ai_response_preview to 500 chars', () {
      final long = 'x' * 1200;
      final payload = FeedbackService.buildPayload(
        userId: '00000000-0000-0000-0000-000000000000',
        messageId: 'msg-1',
        rating: 1,
        aiResponse: long,
      );
      expect(payload['ai_response_preview'], hasLength(500));
    });

    test('buildPayload truncates user_message_preview to 500 chars', () {
      final long = 'y' * 800;
      final payload = FeedbackService.buildPayload(
        userId: '00000000-0000-0000-0000-000000000000',
        messageId: 'msg-1',
        rating: -1,
        userMessage: long,
      );
      expect(payload['user_message_preview'], hasLength(500));
    });

    test('buildPayload accepts thumbs up (rating = 1)', () {
      final payload = FeedbackService.buildPayload(
        userId: '00000000-0000-0000-0000-000000000000',
        messageId: 'msg-up',
        rating: 1,
      );
      expect(payload['rating'], 1);
      expect(payload['message_id'], 'msg-up');
    });

    test('buildPayload accepts thumbs down with comment', () {
      final payload = FeedbackService.buildPayload(
        userId: '00000000-0000-0000-0000-000000000000',
        messageId: 'msg-down',
        rating: -1,
        comment: 'wrong jurisdiction',
      );
      expect(payload['rating'], -1);
      expect(payload['comment'], 'wrong jurisdiction');
    });

    test('buildPayload rejects invalid rating values', () {
      expect(
        () => FeedbackService.buildPayload(
          userId: '00000000-0000-0000-0000-000000000000',
          messageId: 'msg-x',
          rating: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => FeedbackService.buildPayload(
          userId: '00000000-0000-0000-0000-000000000000',
          messageId: 'msg-x',
          rating: 2,
        ),
        throwsArgumentError,
      );
    });

    test('buildPayload requires non-empty message_id', () {
      expect(
        () => FeedbackService.buildPayload(
          userId: '00000000-0000-0000-0000-000000000000',
          messageId: '',
          rating: 1,
        ),
        throwsArgumentError,
      );
    });

    test('buildPayload omits null optional fields rather than sending null',
        () {
      final payload = FeedbackService.buildPayload(
        userId: '00000000-0000-0000-0000-000000000000',
        messageId: 'msg-1',
        rating: 1,
      );
      // Optional fields should not be present at all, so the DB defaults /
      // explicit NULLs from Postgres apply.
      expect(payload.containsKey('comment'), isFalse);
      expect(payload.containsKey('ai_response_preview'), isFalse);
      expect(payload.containsKey('language'), isFalse);
    });

    test('buildPayload includes case_id when provided as UUID', () {
      final payload = FeedbackService.buildPayload(
        userId: '00000000-0000-0000-0000-000000000000',
        messageId: 'msg-1',
        rating: 1,
        caseId: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
      );
      expect(payload['case_id'], 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee');
    });

    test('buildPayload omits case_id for synthetic ids like "general"', () {
      // The chat_screen passes widget.caseId which can be 'general' — that
      // is NOT a UUID, so we must not send it (would violate the column
      // type uuid).
      final payload = FeedbackService.buildPayload(
        userId: '00000000-0000-0000-0000-000000000000',
        messageId: 'msg-1',
        rating: 1,
        caseId: 'general',
      );
      expect(payload.containsKey('case_id'), isFalse);
    });

    test('buildPayload preserves system_prompt_hash, language, model', () {
      final payload = FeedbackService.buildPayload(
        userId: '00000000-0000-0000-0000-000000000000',
        messageId: 'msg-1',
        rating: 1,
        systemPromptHash: 'abc123',
        language: 'et',
        model: 'sonnet',
      );
      expect(payload['system_prompt_hash'], 'abc123');
      expect(payload['language'], 'et');
      expect(payload['model'], 'sonnet');
    });
  });

  group('FeedbackService — hashSystemPrompt', () {
    test('returns sha256 prefix for a known input', () {
      final hash = FeedbackService.hashSystemPrompt('hello world');
      // sha256('hello world') = b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9
      expect(hash, startsWith('b94d27b9934d3e08'));
      expect(hash, hasLength(64));
    });

    test('truncates input to first 1000 chars before hashing', () {
      // Same first 1000 chars -> same hash even if tails differ.
      final base = 'a' * 1000;
      final h1 = FeedbackService.hashSystemPrompt(base);
      final h2 = FeedbackService.hashSystemPrompt('${base}tail-A');
      final h3 = FeedbackService.hashSystemPrompt('${base}tail-B');
      expect(h1, equals(h2));
      expect(h2, equals(h3));
    });

    test('returns null for null input', () {
      expect(FeedbackService.hashSystemPrompt(null), isNull);
    });

    test('returns null for empty string', () {
      expect(FeedbackService.hashSystemPrompt(''), isNull);
    });
  });

  group('FeedbackService — toggle helper', () {
    test('toggleRating returns null when same rating clicked again', () {
      // Click thumbs up while it is already up -> deselect.
      expect(FeedbackService.toggleRating(current: 1, clicked: 1), isNull);
      // Click thumbs down while it is already down -> deselect.
      expect(FeedbackService.toggleRating(current: -1, clicked: -1), isNull);
    });

    test('toggleRating switches when other rating clicked', () {
      expect(FeedbackService.toggleRating(current: 1, clicked: -1), -1);
      expect(FeedbackService.toggleRating(current: -1, clicked: 1), 1);
    });

    test('toggleRating sets new rating when nothing was selected', () {
      expect(FeedbackService.toggleRating(current: null, clicked: 1), 1);
      expect(FeedbackService.toggleRating(current: null, clicked: -1), -1);
    });
  });
}
