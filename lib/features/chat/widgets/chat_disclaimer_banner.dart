import 'package:flutter/material.dart';

import '../../../config/theme.dart';

/// Teal accent used for the calming info banner.
const _kBannerTeal = Color(0xFF0D9488);

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
        color: _kBannerTeal.withValues(alpha: 0.06),
        border: Border(
          bottom: BorderSide(
            color: _kBannerTeal.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: _kBannerTeal.withValues(alpha: 0.8),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'AI assistant provides legal information, not legal advice. '
              'Always consult a qualified lawyer.',
              style: TextStyle(
                fontSize: 11,
                color: _kBannerTeal.withValues(alpha: 0.9),
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Encryption trust badge
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_rounded,
                size: 12,
                color: _kBannerTeal.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 3),
              Text(
                'Encrypted',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _kBannerTeal.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(
                Icons.close,
                size: 16,
                color: _kBannerTeal.withValues(alpha: 0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
