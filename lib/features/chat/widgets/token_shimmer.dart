import 'package:flutter/material.dart';

import '../../../config/theme.dart';

// ---------------------------------------------------------------------------
// TokenShimmer — subtle horizontal shimmer slide on newly-streamed tokens.
// ---------------------------------------------------------------------------
//
// When a new chunk of text arrives from the SSE stream the chat screen wraps
// it in [TokenShimmer]. The widget paints the child once, then drives a
// short (200ms) horizontal gradient sweep over it via [ShaderMask]. The
// gradient is transparent → tealLight @0.15 alpha → transparent so the
// effect is barely perceptible — a "watermark moving across the word",
// not a flash.
//
// The shimmer fires exactly once per mount. After the controller completes
// the child is rendered untouched (no ShaderMask overhead remains).
//
// Reduce-motion compliance:
//   If MediaQuery.disableAnimations is true the widget skips the shimmer
//   entirely and returns the child as-is on first paint.
//
// Why this widget is stateful (and not a simple flutter_animate wrapper):
//   - We must guarantee the shimmer runs at most once per stream chunk.
//   - We must release the AnimationController immediately after the run,
//     otherwise long messages would carry hundreds of idle controllers.
// ---------------------------------------------------------------------------

class TokenShimmer extends StatefulWidget {
  const TokenShimmer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 200),
    this.color,
    this.maxOpacity = 0.15,
  });

  /// The text/widget freshly streamed in from the SSE stream.
  final Widget child;

  /// Sweep duration. Spec default: 200ms.
  final Duration duration;

  /// Highlight colour. Defaults to [AppColors.accentTint] (a brighter teal
  /// suited for ephemeral highlights). Alpha is applied via [maxOpacity].
  final Color? color;

  /// Peak alpha for the middle of the gradient. Spec default: 0.15.
  final double maxOpacity;

  @override
  State<TokenShimmer> createState() => _TokenShimmerState();
}

class _TokenShimmerState extends State<TokenShimmer>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  late final Animation<double> _slide;
  bool _done = false;
  bool _initialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;

    // Honour reduce-motion: skip the controller entirely.
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    if (disableAnimations) {
      _done = true;
      return;
    }

    final c = AnimationController(vsync: this, duration: widget.duration);
    _controller = c;
    _slide = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: c, curve: Curves.easeOut),
    );
    c.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _done = true;
        });
        c.dispose();
        _controller = null;
      }
    });
    c.forward();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Once the shimmer has finished (or was skipped) return the child
    // without any ShaderMask wrapping — keeps long messages cheap.
    if (_done || _controller == null) return widget.child;

    final color = widget.color ?? AppColors.accentTint;

    return AnimatedBuilder(
      animation: _slide,
      child: widget.child,
      builder: (context, child) {
        final pos = _slide.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: const [0.0, 0.5, 1.0],
              colors: [
                Colors.transparent,
                color.withValues(alpha: widget.maxOpacity),
                Colors.transparent,
              ],
              transform: _GradientSlide(pos),
            ).createShader(rect);
          },
          child: child,
        );
      },
    );
  }
}

/// Slides a linear gradient horizontally by [fraction] of the rect width.
/// `fraction = 0` → gradient centred. `fraction = -1` → gradient shifted
/// fully off-screen to the left. `fraction = 2` → fully off-screen right.
class _GradientSlide extends GradientTransform {
  const _GradientSlide(this.fraction);

  final double fraction;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * fraction, 0, 0);
  }
}
