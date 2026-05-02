import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../config/router.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';

/// Landing screen for the Checker feature with two main options.
class CheckerHomeScreen extends StatelessWidget {
  const CheckerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.checkerTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Premium header with shield icon
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(
                      Icons.verified_user_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.checkerTitle,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Professional verification tools',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textTertiary,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: -0.1, end: 0, duration: 400.ms, curve: Curves.easeOutCubic),

              const SizedBox(height: AppSpacing.xl),

              // Check a Company card — cinematic video background
              _CheckerCard(
                icon: Icons.business_center_rounded,
                title: l10n.checkCompany,
                subtitle: l10n.beforeYouWork,
                videoAsset: 'assets/videos/checker_company.mp4',
                fallbackGradient: const [AppColors.accent, AppColors.accentDark],
                onTap: () => context.push(AppRoutes.checkerCompany),
              )
                  .animate()
                  .fadeIn(delay: 150.ms, duration: 400.ms)
                  .slideY(begin: 0.12, end: 0, delay: 150.ms, duration: 400.ms, curve: Curves.easeOutCubic),

              const SizedBox(height: AppSpacing.md),

              // Check a Vehicle card — cinematic video background
              _CheckerCard(
                icon: Icons.directions_car_rounded,
                title: l10n.checkVehicle,
                subtitle: l10n.beforeYouBuy,
                videoAsset: 'assets/videos/checker_vehicle.mp4',
                fallbackGradient: const [AppColors.info, AppColors.infoDark],
                onTap: () => context.push(AppRoutes.checkerVehicle),
              )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 400.ms)
                  .slideY(begin: 0.12, end: 0, delay: 300.ms, duration: 400.ms, curve: Curves.easeOutCubic),

              const Spacer(),

              // Bottom trust badge
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_outlined, size: 16, color: AppColors.textTertiary),
                      SizedBox(width: 6),
                      Text(
                        'Data from official registries',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 500.ms, duration: 400.ms),

              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Checker Card with cinematic video background + premium press animation
// ---------------------------------------------------------------------------

class _CheckerCard extends StatefulWidget {
  const _CheckerCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.videoAsset,
    required this.fallbackGradient,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String videoAsset;
  final List<Color> fallbackGradient;
  final VoidCallback onTap;

  @override
  State<_CheckerCard> createState() => _CheckerCardState();
}

class _CheckerCardState extends State<_CheckerCard> {
  bool _isPressed = false;
  VideoPlayerController? _controller;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final c = VideoPlayerController.asset(widget.videoAsset);
      await c.initialize();
      await c.setLooping(true);
      await c.setVolume(0);
      await c.play();
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() {
        _controller = c;
        _videoReady = true;
      });
    } catch (_) {
      // Asset missing or codec unsupported — gracefully fall back to gradient.
      if (mounted) setState(() => _videoReady = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shadowColor = widget.fallbackGradient.first;
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          width: double.infinity,
          height: 112,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: [
              BoxShadow(
                color: shadowColor.withValues(alpha: _isPressed ? 0.15 : 0.35),
                blurRadius: _isPressed ? 8 : 20,
                offset: Offset(0, _isPressed ? 3 : 8),
                spreadRadius: _isPressed ? -2 : 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Layer 1: gradient (always visible — fallback + safety net while video loads)
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: widget.fallbackGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),

                // Layer 2: cinematic video (covers the card when ready)
                if (_videoReady && _controller != null)
                  FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller!.value.size.width,
                      height: _controller!.value.size.height,
                      child: VideoPlayer(_controller!),
                    ),
                  ),

                // Layer 3: brand-tinted scrim — preserves card identity + AA contrast on white text
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.fallbackGradient.first.withValues(alpha: 0.55),
                        widget.fallbackGradient.last.withValues(alpha: 0.75),
                      ],
                    ),
                  ),
                ),

                // Layer 4: original content (icon, title, subtitle, arrow)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Icon(widget.icon, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.subtitle,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white.withValues(alpha: 0.9),
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
