import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/max_width_wrapper.dart';
import '../widgets/case_timeline_view.dart';

// ---------------------------------------------------------------------------
// Case Timeline Screen — wraps [CaseTimelineView] in a Scaffold + AppBar.
//
// The view itself is DB-backed (case_timeline_events table) and handles
// filter chips, pagination, pull-to-refresh, and per-tile expansion. This
// screen is intentionally thin so the view can also be embedded as a tab
// in `case_detail_screen.dart` without route navigation.
// ---------------------------------------------------------------------------

class CaseTimelineScreen extends ConsumerWidget {
  const CaseTimelineScreen({super.key, required this.caseId});

  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.caseTimeline)),
      // Use MaxWidthWrapper's responsive default — timeline is a list
      // page, not a form. On desktop it should breathe out instead of
      // being squeezed into the 480px column.
      body: MaxWidthWrapper(
        child: CaseTimelineView(caseId: caseId),
      ),
    );
  }
}
