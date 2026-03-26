import 'package:flutter/material.dart';

import '../../config/theme.dart';

/// Visual variants for [StatusChip].
enum StatusChipVariant { active, pending, error, info, neutral }

/// A small chip widget for displaying statuses.
///
/// Renders a coloured dot followed by a text label, wrapped in a rounded
/// container whose colour corresponds to the [variant].
///
/// ```dart
/// StatusChip(label: 'Active', variant: StatusChipVariant.active)
/// ```
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.variant = StatusChipVariant.neutral,
    this.icon,
    this.showDot = true,
  });

  /// The text label displayed on the chip.
  final String label;

  /// The visual variant that determines the chip colour.
  final StatusChipVariant variant;

  /// An optional icon displayed before the dot/label.
  final IconData? icon;

  /// Whether to show the small coloured dot before the label.
  final bool showDot;

  Color get _foreground => switch (variant) {
        StatusChipVariant.active => const Color(0xFF15803D),
        StatusChipVariant.pending => const Color(0xFF92400E),
        StatusChipVariant.error => const Color(0xFF991B1B),
        StatusChipVariant.info => const Color(0xFF1E40AF),
        StatusChipVariant.neutral => AppColors.textSecondary,
      };

  Color get _background => switch (variant) {
        StatusChipVariant.active => const Color(0xFFDCFCE7),
        StatusChipVariant.pending => const Color(0xFFFEF3C7),
        StatusChipVariant.error => const Color(0xFFFEE2E2),
        StatusChipVariant.info => const Color(0xFFDBEAFE),
        StatusChipVariant.neutral => AppColors.surfaceVariant,
      };

  Color get _dotColor => switch (variant) {
        StatusChipVariant.active => AppColors.success,
        StatusChipVariant.pending => AppColors.warning,
        StatusChipVariant.error => AppColors.error,
        StatusChipVariant.info => AppColors.info,
        StatusChipVariant.neutral => AppColors.textTertiary,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: _foreground),
            const SizedBox(width: 4),
          ],
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: _dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _foreground,
            ),
          ),
        ],
      ),
    );
  }
}
