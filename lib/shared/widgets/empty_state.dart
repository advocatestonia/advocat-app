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
    this.illustration,
    this.illustrationSize = 180,
  });

  /// The large icon displayed at the top.
  ///
  /// Used as a fallback when [illustration] is null, ensuring callers that
  /// pre-date the illustration system still render correctly.
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

  /// Optional path to a brand illustration asset (PNG) that takes precedence
  /// over [icon] when provided. Example:
  /// `'assets/illustrations/empty_inbox.png'`.
  ///
  /// When null, the widget falls back to rendering [icon] for backward
  /// compatibility with existing call sites.
  final String? illustration;

  /// Rendered size (width & height) of the [illustration] in logical pixels.
  final double illustrationSize;

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
            if (illustration != null)
              Image.asset(
                illustration!,
                width: illustrationSize,
                height: illustrationSize,
                fit: BoxFit.contain,
                semanticLabel: title,
                errorBuilder: (context, error, stackTrace) => Icon(
                  icon,
                  size: iconSize,
                  color: iconColor ??
                      AppColors.textTertiary.withValues(alpha: 0.5),
                ),
              )
            else
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
