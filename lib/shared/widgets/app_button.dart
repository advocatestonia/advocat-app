import 'package:flutter/material.dart';

import '../../config/theme.dart';

/// The visual variant of an [AppButton].
enum AppButtonVariant { primary, secondary, danger, ghost }

/// The size of an [AppButton].
enum AppButtonSize { small, medium, large }

/// A reusable, brand-consistent button component.
///
/// Supports four visual variants, three sizes, loading/disabled states,
/// full-width mode, and optional leading or trailing icons.
///
/// ```dart
/// AppButton(
///   label: 'Save',
///   variant: AppButtonVariant.primary,
///   onPressed: () {},
/// )
/// ```
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.leadingIcon,
    this.trailingIcon,
  });

  /// The text label displayed on the button.
  final String label;

  /// Called when the button is tapped. A `null` value disables the button.
  final VoidCallback? onPressed;

  /// The visual style of the button.
  final AppButtonVariant variant;

  /// The size variant of the button.
  final AppButtonSize size;

  /// Whether to show a loading spinner and disable interaction.
  final bool isLoading;

  /// Whether the button stretches to fill the available width.
  final bool isFullWidth;

  /// An optional icon to display before the label.
  final IconData? leadingIcon;

  /// An optional icon to display after the label.
  final IconData? trailingIcon;

  bool get _isDisabled => onPressed == null || isLoading;

  // ── Sizing ───────────────────────────────────────────────────────────

  EdgeInsets get _padding => switch (size) {
        AppButtonSize.small =>
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        AppButtonSize.medium =>
          const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        AppButtonSize.large =>
          const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      };

  double get _fontSize => switch (size) {
        AppButtonSize.small => 13,
        AppButtonSize.medium => 15,
        AppButtonSize.large => 17,
      };

  double get _iconSize => switch (size) {
        AppButtonSize.small => 16,
        AppButtonSize.medium => 18,
        AppButtonSize.large => 20,
      };

  double get _spinnerSize => switch (size) {
        AppButtonSize.small => 14,
        AppButtonSize.medium => 18,
        AppButtonSize.large => 20,
      };

  double get _borderRadius => switch (size) {
        AppButtonSize.small => AppRadius.sm,
        AppButtonSize.medium => AppRadius.sm,
        AppButtonSize.large => AppRadius.md,
      };

  // ── Colors ───────────────────────────────────────────────────────────

  Color get _backgroundColor => switch (variant) {
        AppButtonVariant.primary => AppColors.accent,
        AppButtonVariant.secondary => Colors.transparent,
        AppButtonVariant.danger => Colors.transparent,
        AppButtonVariant.ghost => Colors.transparent,
      };

  Color get _foregroundColor => switch (variant) {
        AppButtonVariant.primary => Colors.white,
        AppButtonVariant.secondary => AppColors.primary,
        AppButtonVariant.danger => AppColors.error,
        AppButtonVariant.ghost => AppColors.textSecondary,
      };

  Color get _disabledBackgroundColor => switch (variant) {
        AppButtonVariant.primary => AppColors.accent.withValues(alpha: 0.4),
        _ => Colors.transparent,
      };

  Color get _disabledForegroundColor => switch (variant) {
        AppButtonVariant.primary => Colors.white.withValues(alpha: 0.7),
        _ => AppColors.textTertiary,
      };

  BorderSide? get _borderSide => switch (variant) {
        AppButtonVariant.secondary =>
          const BorderSide(color: AppColors.primary, width: 1.5),
        AppButtonVariant.danger =>
          const BorderSide(color: AppColors.error, width: 1.5),
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final buttonStyle = ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return _disabledBackgroundColor;
        }
        return _backgroundColor;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return _disabledForegroundColor;
        }
        return _foregroundColor;
      }),
      overlayColor: WidgetStateProperty.all(
        _foregroundColor.withValues(alpha: variant == AppButtonVariant.primary ? 0.1 : 0.06),
      ),
      padding: WidgetStateProperty.all(_padding),
      elevation: WidgetStateProperty.all(0),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          side: _isDisabled
              ? (_borderSide?.copyWith(
                      color: _borderSide!.color.withValues(alpha: 0.4)) ??
                  BorderSide.none)
              : (_borderSide ?? BorderSide.none),
        ),
      ),
      textStyle: WidgetStateProperty.all(
        TextStyle(
          fontFamily: 'Inter',
          fontSize: _fontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
      minimumSize: WidgetStateProperty.all(
        isFullWidth ? const Size(double.infinity, 0) : Size.zero,
      ),
    );

    final child = _buildChild();

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: variant == AppButtonVariant.ghost
          ? TextButton(
              onPressed: _isDisabled ? null : onPressed,
              style: buttonStyle,
              child: child,
            )
          : ElevatedButton(
              onPressed: _isDisabled ? null : onPressed,
              style: buttonStyle,
              child: child,
            ),
    );
  }

  Widget _buildChild() {
    if (isLoading) {
      return SizedBox(
        width: _spinnerSize,
        height: _spinnerSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(_foregroundColor),
        ),
      );
    }

    final textWidget = Text(label);

    if (leadingIcon == null && trailingIcon == null) {
      return textWidget;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leadingIcon != null) ...[
          Icon(leadingIcon, size: _iconSize),
          SizedBox(width: size == AppButtonSize.small ? 4 : 8),
        ],
        textWidget,
        if (trailingIcon != null) ...[
          SizedBox(width: size == AppButtonSize.small ? 4 : 8),
          Icon(trailingIcon, size: _iconSize),
        ],
      ],
    );
  }
}
