import 'package:flutter/material.dart';

import '../../config/theme.dart';

/// The visual variant of an [AppButton].
///
/// CTA hierarchy rule: **ONE [primary] per screen.** Use [secondary] for
/// adjacent supporting actions, [tertiary] for low-emphasis text actions
/// (e.g. Cancel), and [destructive] only for irreversible operations.
///
/// Deprecated aliases [danger] (use [destructive]) and [ghost] (use
/// [tertiary]) are retained for backward compatibility during migration
/// and will be removed in a future major version.
enum AppButtonVariant {
  /// Navy filled — the single dominant CTA per screen.
  primary,

  /// Outlined navy — adjacent action of equal logical weight but lower
  /// visual weight than [primary].
  secondary,

  /// Text-only — low emphasis, used for Cancel / dismiss / nav.
  tertiary,

  /// Outlined red — irreversible destructive actions (delete, cancel
  /// subscription, etc.).
  destructive,

  /// @Deprecated Use [destructive] instead.
  @Deprecated('Use AppButtonVariant.destructive instead. Will be removed.')
  danger,

  /// @Deprecated Use [tertiary] instead.
  @Deprecated('Use AppButtonVariant.tertiary instead. Will be removed.')
  ghost,
}

/// The size of an [AppButton].
enum AppButtonSize {
  /// Small (sm) — compact rows, dense lists.
  sm,

  /// Medium (md) — default for most screens.
  md,

  /// Large (lg) — hero CTAs, onboarding, paywalls.
  lg,

  /// @Deprecated Use [sm] instead.
  @Deprecated('Use AppButtonSize.sm instead. Will be removed.')
  small,

  /// @Deprecated Use [md] instead.
  @Deprecated('Use AppButtonSize.md instead. Will be removed.')
  medium,

  /// @Deprecated Use [lg] instead.
  @Deprecated('Use AppButtonSize.lg instead. Will be removed.')
  large,
}

/// The single canonical button primitive for Advocat.
///
/// **CTA hierarchy rule:** ONE [AppButtonVariant.primary] per screen. Use
/// [AppButtonVariant.secondary] for adjacent actions of equal logical
/// weight, [AppButtonVariant.tertiary] for cancel/dismiss text actions,
/// and [AppButtonVariant.destructive] only for irreversible operations.
///
/// Replaces the legacy `GlowButton` primitive. Glow / pulse effects are
/// intentionally NOT supported — use elevation, color weight, and size
/// to express hierarchy instead.
///
/// ```dart
/// // Primary action
/// AppButton(label: 'Save', onPressed: _save)
///
/// // Adjacent secondary
/// AppButton(
///   label: 'Cancel',
///   variant: AppButtonVariant.tertiary,
///   onPressed: _cancel,
/// )
///
/// // Destructive
/// AppButton(
///   label: 'Delete account',
///   variant: AppButtonVariant.destructive,
///   onPressed: _delete,
/// )
/// ```
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
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

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  bool get _isDisabled => widget.onPressed == null || widget.isLoading;

  // ── Variant normalisation ────────────────────────────────────────────
  //
  // Map deprecated aliases (`danger`, `ghost`) to their canonical
  // replacements so the rest of the widget switches on a closed set of
  // four cases without `// ignore: deprecated_member_use`.

  AppButtonVariant get _variant {
    switch (widget.variant) {
      // ignore: deprecated_member_use_from_same_package
      case AppButtonVariant.danger:
        return AppButtonVariant.destructive;
      // ignore: deprecated_member_use_from_same_package
      case AppButtonVariant.ghost:
        return AppButtonVariant.tertiary;
      case AppButtonVariant.primary:
      case AppButtonVariant.secondary:
      case AppButtonVariant.tertiary:
      case AppButtonVariant.destructive:
        return widget.variant;
    }
  }

  AppButtonSize get _size {
    switch (widget.size) {
      // ignore: deprecated_member_use_from_same_package
      case AppButtonSize.small:
        return AppButtonSize.sm;
      // ignore: deprecated_member_use_from_same_package
      case AppButtonSize.medium:
        return AppButtonSize.md;
      // ignore: deprecated_member_use_from_same_package
      case AppButtonSize.large:
        return AppButtonSize.lg;
      case AppButtonSize.sm:
      case AppButtonSize.md:
      case AppButtonSize.lg:
        return widget.size;
    }
  }

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (!_isDisabled) _scaleController.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _scaleController.reverse();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  // ── Sizing ───────────────────────────────────────────────────────────

  EdgeInsets get _padding => switch (_size) {
        AppButtonSize.sm =>
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        AppButtonSize.md =>
          const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        AppButtonSize.lg =>
          const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        // Deprecated aliases unreachable after _size normalisation, but
        // exhaustiveness check requires them.
        // ignore: deprecated_member_use_from_same_package
        AppButtonSize.small ||
        // ignore: deprecated_member_use_from_same_package
        AppButtonSize.medium ||
        // ignore: deprecated_member_use_from_same_package
        AppButtonSize.large =>
          const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      };

  double get _fontSize => switch (_size) {
        AppButtonSize.sm => 13,
        AppButtonSize.md => 15,
        AppButtonSize.lg => 17,
        // ignore: deprecated_member_use_from_same_package
        AppButtonSize.small ||
        // ignore: deprecated_member_use_from_same_package
        AppButtonSize.medium ||
        // ignore: deprecated_member_use_from_same_package
        AppButtonSize.large =>
          15,
      };

  double get _iconSize => switch (_size) {
        AppButtonSize.sm => 16,
        AppButtonSize.md => 18,
        AppButtonSize.lg => 20,
        // ignore: deprecated_member_use_from_same_package
        AppButtonSize.small ||
        // ignore: deprecated_member_use_from_same_package
        AppButtonSize.medium ||
        // ignore: deprecated_member_use_from_same_package
        AppButtonSize.large =>
          18,
      };

  double get _spinnerSize => switch (_size) {
        AppButtonSize.sm => 14,
        AppButtonSize.md => 18,
        AppButtonSize.lg => 20,
        // ignore: deprecated_member_use_from_same_package
        AppButtonSize.small ||
        // ignore: deprecated_member_use_from_same_package
        AppButtonSize.medium ||
        // ignore: deprecated_member_use_from_same_package
        AppButtonSize.large =>
          18,
      };

  double get _borderRadius => switch (_size) {
        AppButtonSize.sm => AppRadius.sm,
        AppButtonSize.md => AppRadius.sm,
        AppButtonSize.lg => AppRadius.md,
        // ignore: deprecated_member_use_from_same_package
        AppButtonSize.small ||
        // ignore: deprecated_member_use_from_same_package
        AppButtonSize.medium ||
        // ignore: deprecated_member_use_from_same_package
        AppButtonSize.large =>
          AppRadius.sm,
      };

  // ── Colors ───────────────────────────────────────────────────────────
  //
  // Navy primary (#1A365D) per design system audit — replaces the
  // previous teal accent so the dominant CTA reads as the brand primary,
  // not the accent. Secondary/tertiary/destructive remain transparent
  // with their respective foreground colors.

  Color get _backgroundColor => switch (_variant) {
        AppButtonVariant.primary => AppColors.primary,
        AppButtonVariant.secondary => Colors.transparent,
        AppButtonVariant.tertiary => Colors.transparent,
        AppButtonVariant.destructive => Colors.transparent,
        // Unreachable after _variant normalisation.
        // ignore: deprecated_member_use_from_same_package
        AppButtonVariant.danger ||
        // ignore: deprecated_member_use_from_same_package
        AppButtonVariant.ghost =>
          Colors.transparent,
      };

  Color get _foregroundColor => switch (_variant) {
        AppButtonVariant.primary => Colors.white,
        AppButtonVariant.secondary => AppColors.primary,
        AppButtonVariant.tertiary => AppColors.textSecondary,
        AppButtonVariant.destructive => AppColors.error,
        // ignore: deprecated_member_use_from_same_package
        AppButtonVariant.danger => AppColors.error,
        // ignore: deprecated_member_use_from_same_package
        AppButtonVariant.ghost => AppColors.textSecondary,
      };

  Color get _disabledBackgroundColor => switch (_variant) {
        AppButtonVariant.primary => AppColors.primary.withValues(alpha: 0.4),
        _ => Colors.transparent,
      };

  Color get _disabledForegroundColor => switch (_variant) {
        AppButtonVariant.primary => Colors.white.withValues(alpha: 0.7),
        _ => AppColors.textTertiary,
      };

  BorderSide? get _borderSide => switch (_variant) {
        AppButtonVariant.secondary =>
          const BorderSide(color: AppColors.primary, width: 1.5),
        AppButtonVariant.destructive =>
          const BorderSide(color: AppColors.error, width: 1.5),
        // ignore: deprecated_member_use_from_same_package
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
        _foregroundColor.withValues(
            alpha: _variant == AppButtonVariant.primary ? 0.1 : 0.06),
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
        widget.isFullWidth ? const Size(double.infinity, 0) : Size.zero,
      ),
    );

    final child = _buildChild();

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: SizedBox(
          width: widget.isFullWidth ? double.infinity : null,
          // Glow effect intentionally removed — hierarchy is conveyed
          // through fill color, border weight, and label color only.
          child: _variant == AppButtonVariant.tertiary
              ? TextButton(
                  onPressed: _isDisabled ? null : widget.onPressed,
                  style: buttonStyle,
                  child: child,
                )
              : ElevatedButton(
                  onPressed: _isDisabled ? null : widget.onPressed,
                  style: buttonStyle,
                  child: child,
                ),
        ),
      ),
    );
  }

  Widget _buildChild() {
    if (widget.isLoading) {
      return SizedBox(
        width: _spinnerSize,
        height: _spinnerSize,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          strokeCap: StrokeCap.round,
          valueColor: AlwaysStoppedAnimation<Color>(_foregroundColor),
        ),
      );
    }

    final textWidget = Text(widget.label);

    if (widget.leadingIcon == null && widget.trailingIcon == null) {
      return textWidget;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.leadingIcon != null) ...[
          Icon(widget.leadingIcon, size: _iconSize),
          SizedBox(width: _size == AppButtonSize.sm ? 4 : 8),
        ],
        textWidget,
        if (widget.trailingIcon != null) ...[
          SizedBox(width: _size == AppButtonSize.sm ? 4 : 8),
          Icon(widget.trailingIcon, size: _iconSize),
        ],
      ],
    );
  }
}
