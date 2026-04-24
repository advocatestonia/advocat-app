// Widget test for the ChatMessageBubble copy button.
//
// fix/copy-selection: pins that tapping the copy icon on an AI bubble
// writes the raw message content to the system clipboard via
// Clipboard.setData. Complements `selectable_message_test.dart` by
// isolating the clipboard payload assertion for the "test content"
// fixture named in the bug report.

@Tags(['fast'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/chat/screens/chat_screen.dart';
import 'package:advocat/features/chat/widgets/chat_message_bubble.dart';

ChatMessage _aiMessage(String content) => ChatMessage(
      id: 'ai-copy-1',
      role: MessageRole.assistant,
      content: content,
      timestamp: DateTime(2026, 4, 23, 10, 0),
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
  group('ChatMessageBubble — copy button clipboard', () {
    testWidgets(
      'tapping the copy icon writes raw content to system clipboard',
      (tester) async {
        const content = 'test content';
        String? clipboardPayload;

        // Mock the platform clipboard channel so the clipboard write is
        // observable without a real engine.
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

        await _pump(tester, ChatMessageBubble(message: _aiMessage(content)));

        // Copy icon is Icons.copy_rounded and must exist on AI bubbles.
        final copyFinder = find.byIcon(Icons.copy_rounded);
        expect(copyFinder, findsOneWidget);

        await tester.tap(copyFinder);
        await tester.pump();

        expect(
          clipboardPayload,
          content,
          reason: 'Copy icon must push exact message.content to clipboard',
        );
      },
    );
  });
}
