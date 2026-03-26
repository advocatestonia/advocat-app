import 'package:flutter/material.dart';

import '../../config/theme.dart';

/// A full-screen loading overlay with a semi-transparent background,
/// a circular progress indicator, and an optional message.
///
/// Designed to be used as a [Stack] overlay on top of a screen while
/// an asynchronous operation is in progress.
///
/// ```dart
/// Stack(
///   children: [
///     _buildContent(),
///     if (isLoading) const LoadingOverlay(message: 'Saving...'),
///   ],
/// )
/// ```
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    this.message,
    this.backgroundColor,
    this.indicatorColor,
  });

  /// Optional message text displayed below the spinner.
  final String? message;

  /// Background colour of the overlay. Defaults to semi-transparent black.
  final Color? backgroundColor;

  /// Colour of the progress indicator. Defaults to the accent colour.
  final Color? indicatorColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        color: backgroundColor ?? Colors.black.withValues(alpha: 0.35),
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    indicatorColor ?? AppColors.accent,
                  ),
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Convenience method to show the overlay as a full-screen dialog barrier.
  static void show(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (_) => LoadingOverlay(message: message),
    );
  }

  /// Convenience method to dismiss a previously shown overlay dialog.
  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}
