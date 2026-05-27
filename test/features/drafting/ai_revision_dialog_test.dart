@Tags(['fast'])
library;

// Widget tests for AiRevisionDialog (Pkg 7 Drafting Studio MVP).
// -----------------------------------------------------------------------------
// Verifies:
//   * Selection preview renders.
//   * Instruction field accepts text and is forwarded on Generate.
//   * Suggestion is shown when the future resolves.
//   * Accept / Reject buttons return the right AiRevisionDecision.
//   * Backend failure surfaces an error message.
// -----------------------------------------------------------------------------

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/drafting/models/draft_model.dart';
import 'package:advocat/features/drafting/widgets/ai_revision_dialog.dart';
import 'package:advocat/l10n/app_localizations.dart';

Widget _wrap(Widget child) {
  // AiRevisionDialog reads AppLocalizations.of(context)! — bootstrap the
  // delegate so the dialog renders without a null-check crash.
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Builder(builder: (ctx) => child)),
  );
}

void main() {
  group('AiRevisionDialog', () {
    testWidgets('renders selected text + instruction field', (tester) async {
      await tester.pumpWidget(_wrap(AiRevisionDialog(
        selectedText: 'hello',
        onRequestRevision: (_) async => const AiRevision(
          revisedText: 'Hello, world.',
          explanation: '',
          changesMade: [],
        ),
      )));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ai_revision_dialog')), findsOneWidget);
      expect(find.byKey(const Key('ai_revision_selection_box')), findsOneWidget);
      expect(find.text('hello'), findsOneWidget);
      expect(find.byKey(const Key('ai_revision_instruction_field')),
          findsOneWidget);
    });

    testWidgets('Generate button calls the future and shows suggestion',
        (tester) async {
      String? receivedInstruction;
      await tester.pumpWidget(_wrap(AiRevisionDialog(
        selectedText: 'hello',
        onRequestRevision: (instr) async {
          receivedInstruction = instr;
          return const AiRevision(
            revisedText: 'Hello, world!',
            explanation: 'Capitalised + exclamation.',
            changesMade: ['Capitalised', 'Added exclamation'],
          );
        },
      )));
      await tester.enterText(
          find.byKey(const Key('ai_revision_instruction_field')),
          'make it punchy');
      await tester.tap(find.byKey(const Key('ai_revision_run_btn')));
      await tester.pumpAndSettle();
      expect(receivedInstruction, 'make it punchy');
      expect(find.byKey(const Key('ai_revision_suggestion_box')), findsOneWidget);
      expect(find.text('Hello, world!'), findsOneWidget);
      expect(find.text('Capitalised + exclamation.'), findsOneWidget);
      expect(find.byKey(const Key('ai_revision_accept_btn')), findsOneWidget);
    });

    testWidgets('Accept returns AiRevisionDecision(accepted=true)', (tester) async {
      final result = ValueNotifier<AiRevisionDecision?>(null);
      late BuildContext capturedCtx;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: Builder(builder: (ctx) {
            capturedCtx = ctx;
            return const SizedBox.shrink();
          }),
        ),
      ));
      // Schedule the dialog after first frame.
      unawaited(showAiRevisionDialog(
        context: capturedCtx,
        selectedText: 'hi',
        onRequestRevision: (_) async => const AiRevision(
          revisedText: 'HI!',
          explanation: '',
          changesMade: [],
        ),
      ).then(result.set));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('ai_revision_run_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('ai_revision_accept_btn')));
      await tester.pumpAndSettle();
      expect(result.value, isNotNull);
      expect(result.value!.accepted, isTrue);
      expect(result.value!.revision?.revisedText, 'HI!');
    });

    testWidgets('Reject returns AiRevisionDecision(accepted=false)',
        (tester) async {
      final result = ValueNotifier<AiRevisionDecision?>(null);
      late BuildContext capturedCtx;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: Builder(builder: (ctx) {
            capturedCtx = ctx;
            return const SizedBox.shrink();
          }),
        ),
      ));
      unawaited(showAiRevisionDialog(
        context: capturedCtx,
        selectedText: 'hi',
        onRequestRevision: (_) async => const AiRevision(
          revisedText: 'HI!',
          explanation: '',
          changesMade: [],
        ),
      ).then(result.set));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('ai_revision_reject_btn')));
      await tester.pumpAndSettle();
      expect(result.value, isNotNull);
      expect(result.value!.accepted, isFalse);
    });

    testWidgets('shows error message when revision future throws',
        (tester) async {
      await tester.pumpWidget(_wrap(AiRevisionDialog(
        selectedText: 'oops',
        onRequestRevision: (_) async {
          throw Exception('backend exploded');
        },
      )));
      await tester.tap(find.byKey(const Key('ai_revision_run_btn')));
      await tester.pumpAndSettle();
      expect(find.textContaining('backend exploded'), findsOneWidget);
    });
  });
}

extension on ValueNotifier<AiRevisionDecision?> {
  void set(AiRevisionDecision? v) => value = v;
}
