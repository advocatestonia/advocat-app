import 'package:flutter/material.dart';

import '../../config/theme.dart';
import 'app_button.dart';

/// A reusable empty-state placeholder widget.
///
/// Displays a large icon, a title, a description, and an optional
/// action button, all centred within the available space.
///
/// ```dart
/// EmptyState(
///   icon: Icons.folder_off_outlined,
///   title: 'No cases yet',
///   description: 'Create your first case to get started.',
///   actionLabel: 'Create Case',
///   onAction: () {},
/// )
/// ```
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    this.iconSize = 64,
    this.compact = false,
  });

  /// The large icon displayed at the top.
  final IconData icon;

  /// The primary title text.
  final String title;

  /// An optional explanatory description.
  final String? description;

  /// Label for the optional action button.
  final String? actionLabel;

  /// Callback invoked when the action button is pressed.
  final VoidCallback? onAction;

  /// Icon colour override. Defaults to [AppColors.textTertiary].
  final Color? iconColor;

  /// Size of the icon.
  final double iconSize;

  /// Whether to use compact spacing (e.g. inside a list section).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: compact ? AppSpacing.lg : AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: iconColor ?? AppColors.textTertiary.withValues(alpha: 0.5),
            ),
            SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
            if (description != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                description!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                variant: AppButtonVariant.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
