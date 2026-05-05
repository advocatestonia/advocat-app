// pending_intentions_section.dart — Case File "Pending follow-ups" widget.
// -----------------------------------------------------------------------------
// Ref: lib/features/case_file/agent_intentions_providers.dart
//      lib/services/assistant_tools.dart#_setFollowupIntention
//
// Shows the user every active agent_intentions row scoped to the current
// case (or all cases when no case is bound). Each row has a cancel button
// that flips completed=true. Surfacing the AI's promises makes them
// trustable across sessions.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../agent_intentions_providers.dart';

class PendingIntentionsSection extends ConsumerWidget {
  const PendingIntentionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(agentIntentionsProvider);

    // Empty state is hidden — no need to take vertical space when AI hasn't
    // promised anything. Loading also hidden (the screen-level spinner covers it).
    if (state.isEmpty || state.loading) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        key: const Key('pending_intentions_section'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Pending follow-ups',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          ...state.items.map(
            (e) => _IntentionRow(
              entry: e,
              key: Key('intention_row_${e.id}'),
              onCancel: () =>
                  ref.read(agentIntentionsProvider.notifier).cancel(e.id),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntentionRow extends StatelessWidget {
  const _IntentionRow({
    super.key,
    required this.entry,
    required this.onCancel,
  });

  final AgentIntentionEntry entry;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        entry.nextCheckAt.toIso8601String().substring(0, 10); // YYYY-MM-DD
    final typeLabel = _humanIntentLabel(entry.intentType);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    typeLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (entry.summary.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      entry.summary,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            TextButton(
              key: Key('intention_cancel_${entry.id}'),
              onPressed: onCancel,
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  static String _humanIntentLabel(String raw) {
    switch (raw) {
      case 'remind_deadline':
        return 'Deadline reminder';
      case 'check_court_status':
        return 'Court status check';
      case 'follow_up_question':
        return 'Follow-up';
      case 'check_company_status':
        return 'Company status check';
      default:
        return raw;
    }
  }
}
