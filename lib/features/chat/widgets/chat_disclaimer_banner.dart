import 'package:flutter/material.dart';

import '../../../config/theme.dart';

/// Banner shown at the top of the chat to remind users that AI is not a lawyer.
class ChatDisclaimerBanner extends StatelessWidget {
  const ChatDisclaimerBanner({
    super.key,
    this.expanded = true,
    this.onDismiss,
  });

  final bool expanded;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    if (!expanded) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        border: Border(
          bottom: BorderSide(
            color: AppColors.warning.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: AppColors.warning.withValues(alpha: 0.8),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'AI assistant provides legal information, not legal advice. '
              'Always consult a qualified lawyer.',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.warning.withValues(alpha: 0.9),
                height: 1.3,
              ),
            ),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: Icon(
                Icons.close,
                size: 16,
                color: AppColors.warning.withValues(alpha: 0.6),
              ),
            ),
        ],
      ),
    );
  }
}
