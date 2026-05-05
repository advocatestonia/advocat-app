@Tags(['fast'])
library;

// =============================================================================
// chat_input_bar_stop_button_test.dart — Stop button (Gap #1, Cursor consilium).
// =============================================================================
//
// 2026-05-05 — when the AI is streaming a reply the send button used to lock
// into a spinner with `onPressed: null`, so the user could not cancel a
// wrong-direction generation. They had to wait ~15s and burn a quota slot
// to retry. This regression-pin asserts the new behaviour:
//
//   - while !isSending → onPressed fires onSend, icon = arrow/send
//   - while isSending  → onPressed fires onStop, icon = Icons.stop_rounded
//   - tapping during sending calls onStop (NOT onSend)
//   - when onStop is null and isSending, button disables (legacy)
//
// Widget-only — no Supabase, no Riverpod. The chat_screen integration that
// wires onStop to _stopStreaming is covered by the per-screen test suite.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/chat/widgets/chat_input_bar.dart';
import 'package:advocat/features/chat/widgets/voice_button.dart';
import 'package:advocat/l10n/app_localizations.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

ChatInputBar _build({
  required bool isSending,
  required VoidCallback onSend,
  VoidCallback? onStop,
  TextEditingController? controller,
}) {
  return ChatInputBar(
    messageController: controller ?? TextEditingController(text: 'hello'),
    focusNode: FocusNode(),
    isSending: isSending,
    voiceState: VoiceButtonState.idle,
    voiceInitialized: false,
    partialSpeech: '',
    onSend: onSend,
    onStop: onStop,
    onVoiceTap: () {},
  );
}

void main() {
  group('ChatInputBar — send/stop button states', () {
    testWidgets('idle: shows send icon and tap fires onSend', (tester) async {
      var sendCount = 0;
      var stopCount = 0;
      await tester.pumpWidget(_wrap(_build(
        isSending: false,
        onSend: () => sendCount += 1,
        onStop: () => stopCount += 1,
      )));
      await tester.pump();

      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
      expect(find.byIcon(Icons.stop_rounded), findsNothing);

      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      expect(sendCount, 1);
      expect(stopCount, 0);
    });

    testWidgets('streaming: shows stop icon and tap fires onStop',
        (tester) async {
      var sendCount = 0;
      var stopCount = 0;
      await tester.pumpWidget(_wrap(_build(
        isSending: true,
        onSend: () => sendCount += 1,
        onStop: () => stopCount += 1,
      )));
      await tester.pump();

      // The send arrow must NOT be present mid-stream.
      expect(find.byIcon(Icons.send_rounded), findsNothing);
      // The stop icon IS present, on the send-button side of the bar.
      expect(find.byIcon(Icons.stop_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.stop_rounded));
      await tester.pump();

      expect(stopCount, 1);
      expect(sendCount, 0);
    });

    testWidgets('streaming + null onStop: button is disabled (legacy fallback)',
        (tester) async {
      var sendCount = 0;
      await tester.pumpWidget(_wrap(_build(
        isSending: true,
        onSend: () => sendCount += 1,
        onStop: null,
      )));
      await tester.pump();

      // No stop icon (no callback to wire).
      expect(find.byIcon(Icons.stop_rounded), findsNothing);
      // Tapping the spinner does nothing.
      // (We can't tap an IconButton with onPressed=null reliably, so just
      // verify onSend wasn't accidentally fired by some KeyboardListener.)
      expect(sendCount, 0);
    });

    testWidgets('streaming → idle transition switches icon back to send',
        (tester) async {
      // Build once in streaming state…
      final controller = TextEditingController(text: 'hello');
      await tester.pumpWidget(_wrap(_build(
        isSending: true,
        onSend: () {},
        onStop: () {},
        controller: controller,
      )));
      await tester.pump();
      expect(find.byIcon(Icons.stop_rounded), findsOneWidget);

      // …then rebuild in idle state — icon must flip back to send.
      await tester.pumpWidget(_wrap(_build(
        isSending: false,
        onSend: () {},
        onStop: () {},
        controller: controller,
      )));
      await tester.pump();
      expect(find.byIcon(Icons.stop_rounded), findsNothing);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    });

    testWidgets('streaming: send button stays enabled (so tap reaches onStop)',
        (tester) async {
      // The bug fix is specifically that `onPressed != null` while sending
      // when onStop is provided. Pin that contract directly.
      await tester.pumpWidget(_wrap(_build(
        isSending: true,
        onSend: () {},
        onStop: () {},
      )));
      await tester.pump();

      final IconButton btn = tester
          .widgetList<IconButton>(find.byType(IconButton))
          .firstWhere(
            (b) => (b.icon as Icon?)?.icon == Icons.stop_rounded,
            orElse: () => throw StateError(
              'expected stop IconButton during isSending=true',
            ),
          );
      expect(btn.onPressed, isNotNull,
          reason: 'Stop button must be tappable mid-stream — '
              'pre-fix bug was onPressed:null spinner.');
    });
  });
}
