import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// AnimatedFadeIn — v24.1 WOW polish
// ---------------------------------------------------------------------------
//
// Wraps a child in a subtle 200-300ms fade + slide so that content never
// pops into existence — essential for making list items, chat bubbles,
// tool result cards feel "alive" rather than "tupnyak" (owner's words).
//
// Usage:
//   AnimatedFadeIn(child: MyCard())
//   AnimatedFadeIn(duration: Duration(milliseconds: 400),
//                  slideFrom: SlideDirection.bottom, child: ...)
//
// The widget only animates on mount.  If you rebuild its parent repeatedly
// (e.g. setState on a stream), wrap a stable key inside so it animates once.

enum SlideDirection { none, top, bottom, left, right }

class AnimatedFadeIn extends StatefulWidget {
  const AnimatedFadeIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 220),
    this.delay = Duration.zero,
    this.slideFrom = SlideDirection.bottom,
    this.slideDistance = 12.0,
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final Duration duration;
  final Duration delay;
  final SlideDirection slideFrom;
  final double slideDistance;
  final Curve curve;

  @override
  State<AnimatedFadeIn> createState() => _AnimatedFadeInState();
}

class _AnimatedFadeInState extends State<AnimatedFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _opacity = CurvedAnimation(parent: _controller, curve: widget.curve);
    _offset = Tween<Offset>(
      begin: _initialOffset(),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  Offset _initialOffset() {
    // Offset is in fractions of the child's own size — convert pixel
    // slideDistance to fraction by using a nominal 100px factor so the
    // animation is size-agnostic.  For practical use the distance is
    // small enough that fractional offset looks right.
    switch (widget.slideFrom) {
      case SlideDirection.none:
        return Offset.zero;
      case SlideDirection.top:
        return Offset(0, -widget.slideDistance / 100);
      case SlideDirection.bottom:
        return Offset(0, widget.slideDistance / 100);
      case SlideDirection.left:
        return Offset(-widget.slideDistance / 100, 0);
      case SlideDirection.right:
        return Offset(widget.slideDistance / 100, 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: widget.slideFrom == SlideDirection.none
          ? widget.child
          : SlideTransition(position: _offset, child: widget.child),
    );
  }
}

/// Staggered list animation — wrap each child in AnimatedFadeIn with a
/// small cumulative delay so the list cascades in.
class StaggeredFadeList extends StatelessWidget {
  const StaggeredFadeList({
    super.key,
    required this.children,
    this.stagger = const Duration(milliseconds: 40),
    this.duration = const Duration(milliseconds: 260),
  });

  final List<Widget> children;
  final Duration stagger;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(children.length, (i) {
        return AnimatedFadeIn(
          key: ValueKey('stagger_$i'),
          delay: stagger * i,
          duration: duration,
          child: children[i],
        );
      }),
    );
  }
}
