// gold_review_card.dart — one row in the queue master list.
// -----------------------------------------------------------------------------
// Compact card that shows the truncated question, language/category chips,
// age, and a status dot. Tapping the card selects it in the master list;
// the detail panel on the right then shows the full pair.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../../services/gold_review_service.dart';

class GoldReviewCard extends StatelessWidget {
  const GoldReviewCard({
    super.key,
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final GoldQueueItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final age = _formatAge(DateTime.now().difference(item.createdAt));

    return Material(
      color: selected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
          : theme.colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                width: 3,
                color: selected
                    ? theme.colorScheme.primary
                    : Colors.transparent,
              ),
              bottom: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.4),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (item.language != null)
                    _Chip(label: item.language!.toUpperCase()),
                  if (item.category != null) ...[
                    const SizedBox(width: 4),
                    _Chip(label: item.category!),
                  ],
                  const Spacer(),
                  Text(
                    age,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _truncate(item.userQuestion, 120),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _truncate(item.aiAnswer, 90),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _truncate(String s, int max) {
    if (s.length <= max) return s;
    return '${s.substring(0, max)}…';
  }

  static String _formatAge(Duration d) {
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    return '${d.inDays}d';
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: t.colorScheme.secondaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: t.textTheme.labelSmall?.copyWith(
          color: t.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
