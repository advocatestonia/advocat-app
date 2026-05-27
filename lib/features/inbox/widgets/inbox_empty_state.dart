// inbox_empty_state.dart
// -----------------------------------------------------------------------------
// "Inbox is empty" placeholder. Shown when:
//   * the user has no triaged threads yet (e.g. Gmail just connected and
//     the email-inbox-sync edge fn has not run yet),
//   * a severity filter excludes all rows, or
//   * everything got snoozed/archived.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';

class InboxEmptyState extends StatelessWidget {
  const InboxEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return EmptyState(
      icon: Icons.inbox_outlined,
      illustration: 'assets/illustrations/empty_inbox.png',
      title: l?.inboxEmptyTitle ?? 'Nothing pending',
      description: l?.inboxEmptyBody ??
          'New email threads will appear here as they get triaged.',
    );
  }
}
