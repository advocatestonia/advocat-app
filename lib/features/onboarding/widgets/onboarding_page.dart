import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../config/theme.dart';

/// A single page within the onboarding flow.
///
/// Displays a large icon in a decorated container (top 40 % of the layout),
/// a title, and a subtitle. The content fades in when [isActive] is `true`,
/// creating a polished transition between pages.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isActive,
    this.iconColor,
    this.iconBackgroundColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isActive;
  final Color? iconColor;
  final Color? iconBackgroundColor;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    if (widget.isActive) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(OnboardingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = widget.iconColor ?? AppColors.accent;
    final effectiveBgColor =
        widget.iconBackgroundColor ?? AppColors.accent.withValues(alpha: 0.08);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            children: [
              // -- Icon / illustration area (top ~40 %) --
              Expanded(
                flex: 4,
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer decorative ring with shimmer
                      AnimatedBuilder(
                        animation: _shimmerController,
                        builder: (context, child) {
                          return Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                startAngle: _shimmerController.value * 2 * math.pi,
                                colors: [
                                  effectiveIconColor.withValues(alpha: 0.0),
                                  effectiveIconColor.withValues(alpha: 0.12),
                                  effectiveIconColor.withValues(alpha: 0.0),
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                            ),
                          );
                        },
                      ),
                      // Main icon circle with scale animation
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: effectiveBgColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: effectiveIconColor.withValues(alpha: 0.15),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            widget.icon,
                            size: 80,
                            color: effectiveIconColor,
                          ),
                        ),
                      )
                          .animate(
                            autoPlay: false,
                            target: widget.isActive ? 1.0 : 0.0,
                          )
                          .scaleXY(
                            begin: 0.6,
                            end: 1.0,
                            duration: 700.ms,
                            curve: Curves.elasticOut,
                          )
                          .fadeIn(
                            duration: 400.ms,
                            curve: Curves.easeOut,
                          ),
                    ],
                  ),
                ),
              ),

              // -- Text area (bottom ~60 %) --
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    Text(
                      widget.title,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                height: 1.3,
                              ),
                      textAlign: TextAlign.center,
                    )
                        .animate(
                          autoPlay: false,
                          target: widget.isActive ? 1.0 : 0.0,
                        )
                        .fadeIn(delay: 200.ms, duration: 400.ms)
                        .slideY(begin: 0.15, end: 0, duration: 400.ms, curve: Curves.easeOutCubic),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      widget.subtitle,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                      textAlign: TextAlign.center,
                    )
                        .animate(
                          autoPlay: false,
                          target: widget.isActive ? 1.0 : 0.0,
                        )
                        .fadeIn(delay: 350.ms, duration: 400.ms)
                        .slideY(begin: 0.15, end: 0, duration: 400.ms, curve: Curves.easeOutCubic),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
