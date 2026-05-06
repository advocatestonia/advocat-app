// =====================================================================
// Phase 2 Pkg 4 — Deadlines tab.
//
// Wraps the existing Pkg 9 CaseDeadlinesScreen. No duplication — the
// Pkg 9 screen already implements per-case filtering, snooze / archive
// / mark-complete actions. We host it as a Material body inside the
// workspace's tab area.
//
// The Pkg 9 screen builds a Scaffold; we render it directly. The inner
// AppBar is collapsed via the same Theme trick used by ChatTab so the
// workspace's TabBar AppBar remains the canonical one.
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../case_memory/screens/case_deadlines_screen.dart';

class DeadlinesTab extends ConsumerWidget {
  const DeadlinesTab({super.key, required this.caseId});

  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Theme(
      data: Theme.of(context).copyWith(
        appBarTheme: Theme.of(context).appBarTheme.copyWith(
              toolbarHeight: 0,
              elevation: 0,
              scrolledUnderElevation: 0,
            ),
      ),
      child: CaseDeadlinesScreen(
        key: Key('workspace-deadlines-$caseId'),
        caseId: caseId,
      ),
    );
  }
}
