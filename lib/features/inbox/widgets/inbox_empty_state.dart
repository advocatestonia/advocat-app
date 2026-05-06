// inbox_empty_state.dart
// -----------------------------------------------------------------------------
// "Inbox is empty" placeholder. Shown when:
//   * the user has no triaged threads yet (e.g. Gmail just connected and
//     the email-inbox-sync edge fn has not run yet),
//   * a severity filter excludes all rows, or
//   * everything got snoozed/archived.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';

class InboxEmptyState extends StatelessWidget {
  const InboxEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.inbox_outlined,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l?.inboxEmptyTitle ?? 'Nothing pending',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l?.inboxEmptyBody ??
                'New email threads will appear here as they get triaged.',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
