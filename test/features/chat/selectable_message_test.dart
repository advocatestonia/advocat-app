// Widget tests for selectable AI message content + copy button.
//
// Bug context (fix/ai-quality): users could not select/copy AI answers
// because ChatMessageBubble used plain Text() for user content (and some
// UI trimmings). This suite pins the contract:
//
//   1. AI message content MUST be selectable (SelectableText).
//   2. User message content MUST be selectable (SelectableText).
//   3. A copy-icon action MUST exist on every AI message and copy the
//      raw content to the system clipboard.
//   4. Tapping the copy icon MUST trigger the onCopy callback so that
//      hosting screens can show a snackbar.
//
// These tests intentionally render [ChatMessageBubble] in isolation —
// the production chat screen already uses SelectableText directly, but
// the reusable bubble widget should behave the same and is the common
// regression point.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/chat/screens/chat_screen.dart';
import 'package:advocat/features/chat/widgets/chat_message_bubble.dart';

ChatMessage _aiMessage(String content) => ChatMessage(
      id: 'ai-1',
      role: MessageRole.assistant,
      content: content,
      timestamp: DateTime(2026, 4, 21, 12, 30),
    );

ChatMessage _userMessage(String content) => ChatMessage(
      id: 'user-1',
      role: MessageRole.user,
      content: content,
      timestamp: DateTime(2026, 4, 21, 12, 29),
    );

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    ),
  );
  // Let flutter_animate entry animations settle.
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  group('ChatMessageBubble — selectable content', () {
    testWidgets('AI message renders via SelectableText (rich)',
        (tester) async {
      const content = 'This is the AI legal analysis with **bold** text.';
      await _pump(
        tester,
        ChatMessageBubble(message: _aiMessage(content)),
      );

      // There must be at least one SelectableText in the subtree rendering
      // the AI reply (RichMessage uses SelectableText.rich for plain spans).
      expect(
        find.byType(SelectableText),
        findsWidgets,
        reason: 'AI message must use SelectableText so users can copy text',
      );
    });

    testWidgets('User message content is wrapped in SelectableText',
        (tester) async {
      const content = 'User question — can I copy this?';
      await _pump(
        tester,
        ChatMessageBubble(message: _userMessage(content)),
      );

      // The user bubble body is the first SelectableText containing the
      // literal content (timestamps / disclaimers stay as plain Text).
      final bodyFinder = find.descendant(
        of: find.byType(ChatMessageBubble),
        matching: find.byWidgetPredicate(
          (w) => w is SelectableText && w.data == content,
        ),
      );
      expect(
        bodyFinder,
        findsOneWidget,
        reason: 'User messages should also be selectable for copy-paste',
      );
    });

    testWidgets('Copy icon is rendered for AI messages', (tester) async {
      await _pump(
        tester,
        ChatMessageBubble(message: _aiMessage('AI content for copy test')),
      );

      expect(
        find.byIcon(Icons.copy_rounded),
        findsOneWidget,
        reason: 'AI messages must expose a copy action in the bubble footer',
      );
    });

    testWidgets('Tapping copy icon invokes onCopy with raw content',
        (tester) async {
      const content = 'Copy me verbatim, please.';
      String? captured;

      await _pump(
        tester,
        ChatMessageBubble(
          message: _aiMessage(content),
          onCopy: (value) => captured = value,
        ),
      );

      await tester.tap(find.byIcon(Icons.copy_rounded));
      await tester.pump();

      expect(
        captured,
        content,
        reason: 'onCopy must receive the exact message.content string',
      );
    });

    testWidgets('Copy icon writes message content to the system clipboard',
        (tester) async {
      const content = 'Clipboard payload — legal advice body';
      // Intercept platform channel calls so we can assert on the payload
      // without a real Flutter engine.
      String? clipboardPayload;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall call) async {
          if (call.method == 'Clipboard.setData') {
            clipboardPayload =
                (call.arguments as Map?)?['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

      await _pump(
        tester,
        ChatMessageBubble(message: _aiMessage(content)),
      );

      await tester.tap(find.byIcon(Icons.copy_rounded));
      await tester.pump();

      expect(
        clipboardPayload,
        content,
        reason: 'Tapping copy must call Clipboard.setData with raw content',
      );
    });

    testWidgets('Long-press still fires onCopy (backwards compatibility)',
        (tester) async {
      const content = 'Long press should still work.';
      String? captured;
      await _pump(
        tester,
        ChatMessageBubble(
          message: _aiMessage(content),
          onCopy: (value) => captured = value,
        ),
      );

      await tester.longPress(find.byType(ChatMessageBubble));
      await tester.pump();

      expect(captured, content);
    });
  });
}
