import 'package:flutter/material.dart';

import '../../../config/theme.dart';

// ---------------------------------------------------------------------------
// ConsiliumIndicator — small navy dot signalling that a consilium reviewed
// the assistant message.
// ---------------------------------------------------------------------------
//
// Placed to the leading edge of an assistant message bubble whenever the
// message carries consilium events (multi-expert legal review fired during
// the turn). Replaces having to expand the consilium panel to know that
// "yes, this answer was vetted by N lawyers".
//
// Spec:
//   - dot:       4px navy (AppColors.primary, #1A365D)
//   - entrance:  fade-in 400ms (Curves.easeOutCubic)
//   - tooltip:   "Consilium reviewed" (localized by caller; widget accepts
//                a [tooltip] argument so the host screen passes the
//                AppLocalizations string).
//
// Reduce-motion compliance:
//   When MediaQuery.disableAnimations is true the dot appears instantly at
//   full opacity (no fade controller is created).
// ---------------------------------------------------------------------------

class ConsiliumIndicator extends StatefulWidget {
  const ConsiliumIndicator({
    super.key,
    required this.fired,
    this.tooltip = 'Consilium reviewed',
    this.size = 4.0,
    this.color,
    this.duration = const Duration(milliseconds: 400),
  });

  /// Whether a consilium fired for this message. When `false` the widget
  /// collapses to a zero-sized box (no layout reservation, matches the
  /// pre-consilium look of legacy messages).
  final bool fired;

  /// Tooltip string. Defaults to English; the chat screen passes the
  /// translated AppLocalizations.consiliumReviewed value.
  final String tooltip;

  /// Diameter of the navy dot in logical pixels. Default: 4px.
  final double size;

  /// Optional override for the dot colour. Defaults to [AppColors.primary]
  /// (#1A365D, the Advocat navy).
  final Color? color;

  /// Fade-in duration. Spec default: 400ms.
  final Duration duration;

  @override
  State<ConsiliumIndicator> createState() => _ConsiliumIndicatorState();
}

class _ConsiliumIndicatorState extends State<ConsiliumIndicator>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _opacity;
  bool _initialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised || !widget.fired) return;
    _initialised = true;

    final disableAnimations = MediaQuery.of(context).disableAnimations;
    if (disableAnimations) {
      // Skip controller — paint at full opacity straight away.
      return;
    }

    final c = AnimationController(vsync: this, duration: widget.duration);
    _controller = c;
    _opacity = CurvedAnimation(parent: c, curve: Curves.easeOutCubic);
    c.forward();
  }

  @override
  void didUpdateWidget(covariant ConsiliumIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If consilium fired later in the message lifecycle, run the fade now.
    if (widget.fired && !oldWidget.fired && _controller == null) {
      final disableAnimations = MediaQuery.of(context).disableAnimations;
      if (disableAnimations) return;
      final c = AnimationController(vsync: this, duration: widget.duration);
      _controller = c;
      _opacity = CurvedAnimation(parent: c, curve: Curves.easeOutCubic);
      c.forward();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.fired) return const SizedBox.shrink();

    final color = widget.color ?? AppColors.primary;

    final dot = Semantics(
      label: widget.tooltip,
      child: Tooltip(
        message: widget.tooltip,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );

    if (_opacity == null) return dot;

    return FadeTransition(opacity: _opacity!, child: dot);
  }
}
