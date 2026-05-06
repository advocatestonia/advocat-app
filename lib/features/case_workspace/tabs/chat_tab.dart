// =====================================================================
// Phase 2 Pkg 4 — Chat tab.
//
// Thin wrapper around the existing ChatScreen, scoping the chat to the
// current case. The wrapper:
//   1. Forwards `caseId` so the existing /chat/:caseId behaviour applies.
//   2. Suppresses the inner chat AppBar — the workspace owns the
//      AppBar with TabBar.
//
// We deliberately do NOT fork ChatScreen — Pkg 6 (Planner) and the
// reasoning-trail work both touch chat_screen.dart. Pkg 4's
// responsibility ends at "render the existing chat inside a tab body".
//
// Active-case scoping is set by the workspace screen on mount via
// activeCaseProvider, so claude-proxy injection still works whether the
// user enters via /chat/:id or /cases-v2/:id?tab=chat.
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chat/screens/chat_screen.dart';

class ChatTab extends ConsumerWidget {
  const ChatTab({super.key, required this.caseId, this.caseName});

  final String caseId;
  final String? caseName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The existing ChatScreen is a Scaffold with its own AppBar — when
    // hosted as a tab we want only the message list + composer. We
    // remove the inner AppBar by hiding it through the Theme (the
    // workspace AppBar/TabBar is the canonical one).
    //
    // ChatScreen builds its own Scaffold; clipping to the tab bounds
    // hides the inner AppBar's status-bar overlay. Theme override
    // collapses the inner Scaffold's app bar via Theme.appBarTheme so
    // both the inner AppBar and the workspace AppBar remain
    // accessible — only the inner one renders zero height.
    return Theme(
      data: Theme.of(context).copyWith(
        appBarTheme: Theme.of(context).appBarTheme.copyWith(
              toolbarHeight: 0,
              elevation: 0,
              scrolledUnderElevation: 0,
            ),
      ),
      child: ChatScreen(
        key: Key('workspace-chat-$caseId'),
        caseId: caseId,
        caseName: caseName,
      ),
    );
  }
}
