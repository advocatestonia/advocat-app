@Tags(['fast'])
library;

// Widget-level tests for [FeedbackButtons].
//
// These tests do NOT touch Supabase. They verify:
//   * Idle render (two grey thumb icons, no active state)
//   * Tap thumbs-up triggers the up callback
//   * Tap thumbs-down opens the comment dialog
//   * Dismissing the dialog does not trigger the down callback
//   * Pre-existing rating renders the active state
//
// We pass mock callbacks (onSubmit) instead of injecting a fake service —
// that keeps the widget loosely coupled and the tests focused on UX.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/l10n/app_localizations.dart';
import 'package:advocat/widgets/feedback_buttons.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('FeedbackButtons — idle rendering', () {
    testWidgets('shows two thumb icons when no prior rating', (tester) async {
      await tester.pumpWidget(_wrap(
        FeedbackButtons(
          messageId: 'msg-1',
          onSubmit: (_, __) async {},
        ),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.thumb_up_outlined), findsOneWidget);
      expect(find.byIcon(Icons.thumb_down_outlined), findsOneWidget);
      // No filled icons in the idle state.
      expect(find.byIcon(Icons.thumb_up), findsNothing);
      expect(find.byIcon(Icons.thumb_down), findsNothing);
    });

    testWidgets('shows active up state when initialRating = 1', (tester) async {
      await tester.pumpWidget(_wrap(
        FeedbackButtons(
          messageId: 'msg-1',
          initialRating: 1,
          onSubmit: (_, __) async {},
        ),
      ));
      await tester.pump();

      // Filled thumbs-up icon should be present once rating is active.
      expect(find.byIcon(Icons.thumb_up), findsOneWidget);
      expect(find.byIcon(Icons.thumb_down_outlined), findsOneWidget);
    });

    testWidgets('shows active down state when initialRating = -1',
        (tester) async {
      await tester.pumpWidget(_wrap(
        FeedbackButtons(
          messageId: 'msg-1',
          initialRating: -1,
          onSubmit: (_, __) async {},
        ),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.thumb_down), findsOneWidget);
      expect(find.byIcon(Icons.thumb_up_outlined), findsOneWidget);
    });
  });

  group('FeedbackButtons — interactions', () {
    testWidgets('tapping thumbs-up calls onSubmit with rating = 1',
        (tester) async {
      int? capturedRating;
      String? capturedComment;

      await tester.pumpWidget(_wrap(
        FeedbackButtons(
          messageId: 'msg-1',
          onSubmit: (rating, comment) async {
            capturedRating = rating;
            capturedComment = comment;
          },
        ),
      ));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.thumb_up_outlined));
      await tester.pumpAndSettle();

      expect(capturedRating, 1);
      // Thumbs-up does NOT show a comment dialog.
      expect(capturedComment, isNull);
    });

    testWidgets('tapping thumbs-down opens comment dialog', (tester) async {
      await tester.pumpWidget(_wrap(
        FeedbackButtons(
          messageId: 'msg-1',
          onSubmit: (_, __) async {},
        ),
      ));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.thumb_down_outlined));
      await tester.pumpAndSettle();

      // Dialog opens and shows the comment textarea + Send/Cancel buttons.
      expect(find.text('What was wrong?'), findsOneWidget);
      expect(find.text('Send'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('cancelling the comment dialog does NOT call onSubmit',
        (tester) async {
      var submitCalls = 0;
      await tester.pumpWidget(_wrap(
        FeedbackButtons(
          messageId: 'msg-1',
          onSubmit: (_, __) async {
            submitCalls++;
          },
        ),
      ));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.thumb_down_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(submitCalls, 0);
      // No active state since user cancelled.
      expect(find.byIcon(Icons.thumb_down), findsNothing);
    });

    testWidgets('submitting the comment dialog calls onSubmit with -1',
        (tester) async {
      int? capturedRating;
      String? capturedComment;

      await tester.pumpWidget(_wrap(
        FeedbackButtons(
          messageId: 'msg-1',
          onSubmit: (rating, comment) async {
            capturedRating = rating;
            capturedComment = comment;
          },
        ),
      ));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.thumb_down_outlined));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'wrong jurisdiction');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(capturedRating, -1);
      expect(capturedComment, 'wrong jurisdiction');
    });

    testWidgets('submitting empty comment is allowed', (tester) async {
      int? capturedRating;
      String? capturedComment;

      await tester.pumpWidget(_wrap(
        FeedbackButtons(
          messageId: 'msg-1',
          onSubmit: (rating, comment) async {
            capturedRating = rating;
            capturedComment = comment;
          },
        ),
      ));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.thumb_down_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(capturedRating, -1);
      // Empty input is normalized to null (no spurious empty-string row).
      expect(capturedComment, isNull);
    });

    testWidgets('clicking already-active thumbs-up clears the rating',
        (tester) async {
      int? lastRating = -2; // sentinel
      await tester.pumpWidget(_wrap(
        FeedbackButtons(
          messageId: 'msg-1',
          initialRating: 1,
          onSubmit: (rating, _) async {
            lastRating = rating;
          },
        ),
      ));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.thumb_up));
      await tester.pumpAndSettle();

      // null rating => deselect.
      expect(lastRating, isNull);
    });
  });
}
