import 'package:flutter/material.dart';

import '../../../config/theme.dart';

// ---------------------------------------------------------------------------
// StreamingCursor — Advocat signature streaming-answer cursor.
// ---------------------------------------------------------------------------
//
// A small pulsing teal dot that sits at the trailing edge of the assistant
// message while the SSE stream is still delivering tokens. Distinct from
// Claude.ai's hairline cursor and from ChatGPT's caret — this is a brand
// motion signature: warm teal, smooth easeInOut breathing rather than a
// hard blink.
//
// Spec:
//   - colour:    AppColors.accent (#0B7A70) by default
//   - size:      4px ↔ 8px (Tween)
//   - duration:  800ms per half-cycle, reverse-mirrored
//   - curve:     Curves.easeInOut
//   - when [active] is false, the controller is stopped and the dot is
//     hidden entirely (returns a zero-sized box). This avoids any visual
//     residue once streaming finishes.
//
// Reduce-motion compliance (WCAG 2.3.3 / prefers-reduced-motion):
//   When MediaQuery.disableAnimations is true the widget paints a static
//   solid teal dot at the larger size with no animation controller running.
//   This keeps the same layout slot so the bubble doesn't reflow.
//
// Performance:
//   - One AnimationController per cursor (the bubble owns a single one).
//   - AnimatedBuilder rebuild scope is the dot only — no parent setState.
//   - Static fallback short-circuits the controller entirely.
// ---------------------------------------------------------------------------

class StreamingCursor extends StatefulWidget {
  const StreamingCursor({
    super.key,
    required this.active,
    this.color,
    this.minSize = 4.0,
    this.maxSize = 8.0,
    this.duration = const Duration(milliseconds: 800),
  });

  /// Whether the cursor should animate. Pass `false` once streaming
  /// finishes; the widget collapses to a zero-sized box.
  final bool active;

  /// Optional override for the dot colour. Defaults to [AppColors.accent].
  final Color? color;

  /// Smaller end of the pulse range (in logical pixels).
  final double minSize;

  /// Larger end of the pulse range (in logical pixels).
  final double maxSize;

  /// Duration of one half-cycle (small → large). The reverse half uses
  /// the same duration, so the full breath is `2 * duration`.
  final Duration duration;

  @override
  State<StreamingCursor> createState() => _StreamingCursorState();
}

class _StreamingCursorState extends State<StreamingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _size;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _size = Tween<double>(begin: widget.minSize, end: widget.maxSize).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.active) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant StreamingCursor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active) {
      if (widget.active) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return const SizedBox.shrink();
    }

    final color = widget.color ?? AppColors.accent;
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    // Reduce-motion: paint a static dot at the larger size, no controller.
    if (disableAnimations) {
      // Make sure the controller isn't burning frames behind a static dot.
      if (_controller.isAnimating) {
        _controller.stop();
      }
      return _StaticDot(color: color, size: widget.maxSize);
    }

    // Keep the controller running (the active flag may flip back on a
    // subsequent build without going through didUpdateWidget — defensive).
    if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }

    return SizedBox(
      // Reserve the layout slot for the largest size so neighbouring
      // glyphs don't jitter as the dot breathes.
      width: widget.maxSize,
      height: widget.maxSize,
      child: Center(
        child: AnimatedBuilder(
          animation: _size,
          builder: (context, _) {
            return Container(
              width: _size.value,
              height: _size.value,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StaticDot extends StatelessWidget {
  const _StaticDot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
