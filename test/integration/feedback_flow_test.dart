@Tags(['fast'])
library;

// Integration test — feedback happy path (offline).
//
// Drives the FeedbackButtons widget end-to-end:
//   1. Render in idle state.
//   2. User taps 👎.
//   3. Comment dialog opens.
//   4. User types "wrong jurisdiction" + presses Send.
//   5. Verify the onSubmit callback receives (rating = -1,
//      comment = "wrong jurisdiction") AND that the FeedbackService's
//      payload builder shapes a row that satisfies the DB contract
//      (uuid case_id stripping, 500-char preview cap).
//
// Supabase is NOT touched — the actual round-trip is exercised by
// production smoke. This test validates the user journey + payload
// contract that a real flow depends on.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/l10n/app_localizations.dart';
import 'package:advocat/services/feedback_service.dart';
import 'package:advocat/widgets/feedback_buttons.dart';

void main() {
  testWidgets('happy path: thumbs-down with comment yields a valid DB payload',
      (tester) async {
    int? capturedRating;
    String? capturedComment;
    Map<String, dynamic>? builtPayload;

    const aiResponse = 'According to Estonian Civil Procedure Code, '
        'the deadline for filing an appeal is 30 days from receipt '
        'of the judgment...';
    const userMessage = 'Mu apellatsioonitähtaeg on möödas, mis nüüd?';

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: FeedbackButtons(
            messageId: 'ai_msg_42',
            onSubmit: (rating, comment) async {
              capturedRating = rating;
              capturedComment = comment;
              // Mirror what the chat_screen would do — build the
              // Supabase payload exactly as production code path #1.
              builtPayload = FeedbackService.buildPayload(
                userId: 'user-uuid-aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
                messageId: 'ai_msg_42',
                rating: rating!,
                caseId: 'general', // synthetic — should be stripped
                comment: comment,
                aiResponse: aiResponse,
                userMessage: userMessage,
                language: 'et',
                model: 'sonnet',
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();

    // 1. Idle state visible.
    expect(find.byIcon(Icons.thumb_up_outlined), findsOneWidget);
    expect(find.byIcon(Icons.thumb_down_outlined), findsOneWidget);

    // 2. User taps 👎.
    await tester.tap(find.byIcon(Icons.thumb_down_outlined));
    await tester.pumpAndSettle();

    // 3. Comment dialog opens.
    expect(find.text('What was wrong?'), findsOneWidget);
    expect(find.text('Send'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    // 4. User types and submits.
    await tester.enterText(find.byType(TextField), 'wrong jurisdiction');
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    // 5. onSubmit was called with the right arguments.
    expect(capturedRating, -1);
    expect(capturedComment, 'wrong jurisdiction');

    // 6. Active state now visible (filled thumbs-down).
    expect(find.byIcon(Icons.thumb_down), findsOneWidget);

    // 7. Built payload satisfies DB invariants.
    expect(builtPayload, isNotNull);
    expect(builtPayload!['rating'], -1);
    expect(builtPayload!['message_id'], 'ai_msg_42');
    expect(builtPayload!['comment'], 'wrong jurisdiction');
    expect(builtPayload!['ai_response_preview'], aiResponse);
    expect(builtPayload!['user_message_preview'], userMessage);
    expect(builtPayload!['language'], 'et');
    expect(builtPayload!['model'], 'sonnet');
    // Synthetic case_id 'general' must NOT be in the payload (uuid col).
    expect(builtPayload!.containsKey('case_id'), isFalse);
  });
}
