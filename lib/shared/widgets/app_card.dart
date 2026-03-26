import 'package:flutter/material.dart';

import '../../config/theme.dart';

/// A reusable, brand-consistent card component.
///
/// Features an optional coloured left border (useful for case-type
/// indication), title/subtitle rows, a trailing widget, tap callback,
/// configurable elevation, and padding options.
///
/// ```dart
/// AppCard(
///   title: 'Employment Case',
///   subtitle: 'Updated 2 hours ago',
///   borderColor: AppColors.accent,
///   trailing: StatusChip(variant: StatusChipVariant.active, label: 'Open'),
///   onTap: () {},
/// )
/// ```
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    this.title,
    this.titleWidget,
    this.subtitle,
    this.subtitleWidget,
    this.trailing,
    this.leading,
    this.child,
    this.onTap,
    this.borderColor,
    this.borderWidth = 4,
    this.elevation = 0,
    this.padding,
    this.margin,
    this.backgroundColor,
  });

  /// Title text. Ignored when [titleWidget] is provided.
  final String? title;

  /// A custom widget to replace the default title text.
  final Widget? titleWidget;

  /// Subtitle text. Ignored when [subtitleWidget] is provided.
  final String? subtitle;

  /// A custom widget to replace the default subtitle text.
  final Widget? subtitleWidget;

  /// A widget displayed at the trailing end of the title row.
  final Widget? trailing;

  /// A widget displayed at the leading end of the title row.
  final Widget? leading;

  /// Optional arbitrary content rendered below the title/subtitle.
  final Widget? child;

  /// Callback invoked when the card is tapped.
  final VoidCallback? onTap;

  /// Colour of the left accent border. `null` means no accent border.
  final Color? borderColor;

  /// Width of the left accent border.
  final double borderWidth;

  /// Card elevation. Defaults to 0 (flat with border).
  final double elevation;

  /// Inner padding. Defaults to `AppSpacing.md` on all sides.
  final EdgeInsetsGeometry? padding;

  /// Outer margin around the card.
  final EdgeInsetsGeometry? margin;

  /// Background colour override.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasHeader = title != null ||
        titleWidget != null ||
        subtitle != null ||
        subtitleWidget != null;

    final cardContent = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasHeader)
            Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (titleWidget != null)
                        titleWidget!
                      else if (title != null)
                        Text(
                          title!,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      if (subtitleWidget != null) ...[
                        const SizedBox(height: 2),
                        subtitleWidget!,
                      ] else if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  trailing!,
                ],
              ],
            ),
          if (hasHeader && child != null) const SizedBox(height: AppSpacing.sm),
          if (child != null) child!,
        ],
      ),
    );

    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04 * elevation),
                  blurRadius: 4 * elevation,
                  offset: Offset(0, 2 * elevation),
                ),
              ]
            : null,
      ),
      child: borderColor != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: borderColor!, width: borderWidth),
                  ),
                ),
                child: cardContent,
              ),
            )
          : cardContent,
    );

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: card,
        ),
      );
    }

    return card;
  }
}
