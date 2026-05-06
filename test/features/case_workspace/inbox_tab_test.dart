// Phase 2 Pkg 4 — InboxTab widget tests (case-scoped filter).

import 'package:advocat/features/case_workspace/tabs/inbox_tab.dart';
import 'package:advocat/features/inbox/models/inbox_severity.dart';
import 'package:advocat/features/inbox/models/inbox_thread.dart';
import 'package:advocat/features/inbox/providers/inbox_provider.dart';
import 'package:advocat/features/inbox/widgets/triage_card.dart';
import 'package:advocat/l10n/app_localizations.dart';
import 'package:advocat/services/assistant_tools.dart';
import 'package:advocat/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

InboxThread _t({
  required String id,
  required String? caseId,
  InboxSeverity severity = InboxSeverity.high,
}) {
  return InboxThread(
    threadId: id,
    triageId: 'triage-$id',
    subject: 'Subject $id',
    senderEmail: 'sender@example.com',
    severity: severity,
    userBrief: 'Brief',
    lastMessageAt: DateTime.now().toUtc(),
    hasDraft: true,
    sendRecommendation: 'hold_for_user_review',
    userAction: null,
    seenByUserAt: null,
    caseId: caseId,
  );
}

class _SeededInboxNotifier extends InboxNotifier {
  _SeededInboxNotifier(super.tools, List<InboxThread> seed) {
    state = InboxState(
      threads: seed,
      severityFilter: null,
      isLoading: false,
      errorMessage: null,
    );
  }
  @override
  Future<void> refresh() async {/* no-op */}
}

Widget _wrap(Widget child, {required List<InboxThread> seed}) {
  return ProviderScope(
    overrides: [
      inboxProvider.overrideWith(
        (ref) => _SeededInboxNotifier(
          ref.read(assistantToolsProvider),
          seed,
        ),
      ),
      assistantToolsProvider.overrideWithValue(
        AssistantTools(supabaseService: SupabaseService()),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('et'), Locale('ru')],
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('InboxTab — empty state when no threads match the case',
      (tester) async {
    await tester.pumpWidget(
      _wrap(const InboxTab(caseId: 'c-1'),
          seed: [_t(id: 'a', caseId: 'OTHER')]),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('workspace-inbox-empty')), findsOneWidget);
  });

  testWidgets('InboxTab — renders matching threads, hides others',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const InboxTab(caseId: 'c-1'),
        seed: [
          _t(id: 'a', caseId: 'c-1'),
          _t(id: 'b', caseId: 'c-1'),
          _t(id: 'c', caseId: 'OTHER'),
          _t(id: 'd', caseId: null),
        ],
      ),
    );
    // CRITICAL severity has a continuous pulse animation in the
    // triage card; pumpAndSettle would hang. Pump a few frames.
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    expect(find.byKey(const Key('workspace-inbox-tab')), findsOneWidget);
    expect(find.byType(TriageCard), findsNWidgets(2));
    expect(find.text('Subject a'), findsOneWidget);
    expect(find.text('Subject b'), findsOneWidget);
    expect(find.text('Subject c'), findsNothing);
    expect(find.text('Subject d'), findsNothing);
  });
}
