import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/theme.dart';

/// A tappable action chip with teal outline styling.
///
/// Used for quick-action buttons and inline clickable actions inside
/// rich AI messages.
class ChatActionChip extends StatelessWidget {
  const ChatActionChip({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.compact = false,
  });

  /// Display text.
  final String label;

  /// Called when the chip is tapped.
  final VoidCallback onTap;

  /// Optional leading icon.
  final IconData? icon;

  /// When `true` uses a smaller padding/font for inline usage.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final verticalPad = compact ? 4.0 : 6.0;
    final horizontalPad = compact ? 10.0 : 14.0;
    final fontSize = compact ? 12.0 : 13.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPad,
            vertical: verticalPad,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.5),
            ),
            color: AppColors.accent.withValues(alpha: 0.06),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: compact ? 14 : 16,
                  color: AppColors.accent,
                ),
                SizedBox(width: compact ? 4 : 6),
              ],
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                    height: 1.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
