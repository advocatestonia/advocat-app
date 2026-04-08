import 'package:flutter/material.dart';

import '../../config/theme.dart';

/// A button wrapper that adds a subtle animated glow and press-down effect.
///
/// The glow pulses gently (scale 1.0 -> 1.05 -> 1.0) and the button
/// scales down to 0.97 on press for tactile feedback.
class GlowButton extends StatefulWidget {
  const GlowButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.glowColor,
    this.glowRadius = 12.0,
  });

  /// The button content (typically a Text, Icon, or Row).
  final Widget child;

  /// Callback when the button is tapped.
  final VoidCallback? onPressed;

  /// The color of the glow effect. Defaults to [AppColors.accent] at 0.3 alpha.
  final Color? glowColor;

  /// Blur radius of the glow. Defaults to 12.
  final double glowRadius;

  @override
  State<GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<GlowButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  bool _isPressed = false;

  bool get _enabled => widget.onPressed != null;

  Color get _effectiveGlowColor =>
      widget.glowColor ?? AppColors.accent.withAlpha(77); // ~0.3 alpha

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.05)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.05, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_pulseController);

    if (_enabled) {
      _pulseController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant GlowButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_enabled && !_pulseController.isAnimating) {
      _pulseController.repeat();
    } else if (!_enabled && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    if (!_enabled) return;
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails _) {
    if (!_enabled) return;
    setState(() => _isPressed = false);
    widget.onPressed?.call();
  }

  void _handleTapCancel() {
    if (!_enabled) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          final double pressScale = _isPressed ? 0.97 : 1.0;
          final double glowScale = _enabled ? _pulseAnimation.value : 1.0;

          return Transform.scale(
            scale: pressScale,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                boxShadow: _enabled
                    ? [
                        BoxShadow(
                          color: _effectiveGlowColor,
                          blurRadius: widget.glowRadius * glowScale,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Convenience alias — [AnimatedBuilder] is the canonical name for the
/// widget formerly known as AnimatedWidget's builder variant.
/// Flutter 3.x uses AnimatedBuilder which extends AnimatedWidget.
/// This typedef avoids confusion.
