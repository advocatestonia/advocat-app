import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../main.dart';
import '../../../shared/widgets/max_width_wrapper.dart';
import '../widgets/onboarding_page.dart';

/// Five-page onboarding: language selection first, then four feature pages.
///
/// Pages:
///   0. Language -- "Choose your language" (mandatory)
///   1. Shield   -- "Your AI Legal Defense"
///   2. Camera   -- "Scan Any Document"
///   3. Search   -- "AI Finds Errors"
///   4. Send     -- "Get Your Appeal Ready"
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pageController = PageController();
  int _currentPage = 0;

  // Total pages: 1 language + 4 feature
  static const _pageCount = 5;

  // Gradient colors for each page (shifts between pages)
  static const _gradientColors = <List<Color>>[
    [Color(0xFFF0EEEB), Color(0xFFE8E6E3)], // Language page
    [Color(0xFFF0EEEB), Color(0xFFE3EBF0)], // Shield - blueish
    [Color(0xFFF0EEEB), Color(0xFFE3F0ED)], // Camera - tealish
    [Color(0xFFF0EEEB), Color(0xFFF0ECE3)], // Search - warmish
    [Color(0xFFF0EEEB), Color(0xFFE3F0ED)], // Send - tealish
  ];

  late final AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  // -- Navigation helpers --------------------------------------------------

  void _goToNextPage() {
    if (_currentPage < _pageCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    context.go(AppRoutes.login);
  }

  void _selectLanguage(String code) {
    HapticFeedback.mediumImpact();
    ref.read(localeProvider.notifier).setLocale(Locale(code));
    _goToNextPage();
  }

  // -- Page data -----------------------------------------------------------

  static const _icons = <IconData>[
    Icons.shield_outlined,
    Icons.camera_alt_outlined,
    Icons.manage_search_rounded,
    Icons.send_rounded,
  ];

  static const _iconColors = <Color>[
    AppColors.primary,
    AppColors.accent,
    Color(0xFFD4870E), // warning amber
    AppColors.accent,
  ];

  List<String> _titles(AppLocalizations l) => [
        l.onboardingTitle1,
        l.onboardingTitle2,
        l.onboardingTitle3,
        l.onboardingTitle4,
      ];

  List<String> _subtitles(AppLocalizations l) => [
        l.onboardingDesc1,
        l.onboardingDesc2,
        l.onboardingDesc3,
        l.onboardingDesc4,
      ];

  // -- Build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final titles = _titles(l);
    final subtitles = _subtitles(l);
    final isLanguagePage = _currentPage == 0;
    final isLastPage = _currentPage == _pageCount - 1;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _gradientColors[_currentPage],
          ),
        ),
        // Use MaxWidthWrapper's responsive default — onboarding wizard
        // is page content (illustrations, language picker, hero copy),
        // not a form. On desktop it should breathe out to 1200px instead
        // of being squeezed into a 480px column with empty gradient.
        child: MaxWidthWrapper(
          child: Stack(
          children: [
            // Subtle particle/shimmer background
            _ParticleBackground(controller: _particleController),

            SafeArea(
              child: Column(
                // crossAxisAlignment: stretch so the inner PageView (which
                // sits in `Expanded`) gets a tight cross-axis constraint
                // equal to the wrapper's responsive max width (1200 on
                // desktop). With the default `center`, PageView collapses
                // to a 480px fallback and the wizard stays squeezed.
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // -- Skip button (top-right, hidden on language and last page) --
                  // P1-8: Use Visibility(maintainSize:false) so the widget is
                  // fully removed from the tree on lang/last pages — prevents
                  // an invisible-but-hit-testable TextButton from intercepting
                  // taps at the top-right corner.
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: AppSpacing.sm,
                        right: AppSpacing.md,
                      ),
                      child: Visibility(
                        visible: !(isLastPage || isLanguagePage),
                        maintainSize: false,
                        maintainAnimation: false,
                        maintainState: false,
                        child: TextButton(
                          onPressed: _navigateToLogin,
                          child: Text(
                            l.onboardingSkip,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // -- Page content --
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _pageCount,
                      // Prevent swiping away from language page without choosing
                      physics: isLanguagePage
                          ? const NeverScrollableScrollPhysics()
                          : const BouncingScrollPhysics(),
                      onPageChanged: (index) =>
                          setState(() => _currentPage = index),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _LanguageSelectionPage(
                            onLanguageSelected: _selectLanguage,
                          );
                        }
                        final featureIndex = index - 1;
                        return OnboardingPage(
                          icon: _icons[featureIndex],
                          title: titles[featureIndex],
                          subtitle: subtitles[featureIndex],
                          isActive: _currentPage == index,
                          iconColor: _iconColors[featureIndex],
                          iconBackgroundColor:
                              _iconColors[featureIndex].withValues(alpha: 0.08),
                        );
                      },
                    ),
                  ),

                  // -- Dots indicator (hidden on language page) --
                  if (!isLanguagePage)
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_pageCount, (index) {
                          final isActive = _currentPage == index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOutCubic,
                            margin:
                                const EdgeInsets.symmetric(horizontal: 5),
                            width: isActive ? 32 : 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.accent
                                  : AppColors.border,
                              borderRadius: BorderRadius.circular(5),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: AppColors.accent.withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                          );
                        }),
                      ),
                    ),

                  // -- Action buttons (hidden on language page) --
                  if (!isLanguagePage)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                      ),
                      child: Column(
                        children: [
                          // Premium glow button
                          _GlowButton(
                            onPressed: _goToNextPage,
                            label: isLastPage
                                ? l.getStarted
                                : l.onboardingNext,
                            isLastPage: isLastPage,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextButton(
                            onPressed: _navigateToLogin,
                            child: Text(
                              '${l.alreadyHaveAccount}${l.signInLink}',
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: isLanguagePage ? AppSpacing.md : AppSpacing.lg),
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

// ---------------------------------------------------------------------------
// Premium Glow Button
// ---------------------------------------------------------------------------

class _GlowButton extends StatefulWidget {
  const _GlowButton({
    required this.onPressed,
    required this.label,
    required this.isLastPage,
  });

  final VoidCallback onPressed;
  final String label;
  final bool isLastPage;

  @override
  State<_GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<_GlowButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (context, child) {
        final glowIntensity = 0.2 + _glowCtrl.value * 0.3;
        return Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: glowIntensity),
                blurRadius: 16 + _glowCtrl.value * 8,
                spreadRadius: _glowCtrl.value * 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        );
      },
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          widget.onPressed();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.label,
                key: ValueKey(widget.isLastPage),
              ),
              if (widget.isLastPage) ...[
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Particle Background — subtle floating particles
// ---------------------------------------------------------------------------

class _ParticleBackground extends StatelessWidget {
  const _ParticleBackground({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _ParticlePainter(progress: controller.value),
        );
      },
    );
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // 15 subtle floating particles
    final rng = math.Random(42); // fixed seed for consistency
    for (int i = 0; i < 15; i++) {
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final speed = 0.3 + rng.nextDouble() * 0.7;
      final radius = 1.5 + rng.nextDouble() * 2.5;

      final phase = (progress * speed + i * 0.07) % 1.0;
      final x = baseX + math.sin(phase * 2 * math.pi) * 20;
      final y = baseY - phase * 40 + 20;
      final opacity = (math.sin(phase * math.pi) * 0.12).clamp(0.0, 0.12);

      paint.color = AppColors.accent.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ---------------------------------------------------------------------------
// Language Selection Page (page 0)
// ---------------------------------------------------------------------------

class _LanguageSelectionPage extends StatelessWidget {
  const _LanguageSelectionPage({required this.onLanguageSelected});

  final ValueChanged<String> onLanguageSelected;

  // P1-1: Title shown in all 17 supported languages so every user — regardless
  // of device locale — can read at least one variant on the language picker.
  // Covers EN/RU/FI/ET/SV/DE/AR (originals) plus FR/ES/IT/PL/LV/LT/RO/TR/UK/FA
  // listed in the language grid (register_screen.dart:493-510).
  static const _multilingualTitles = [
    'Choose your language',
    '\u0412\u044B\u0431\u0435\u0440\u0438\u0442\u0435 \u044F\u0437\u044B\u043A', // Выберите язык (ru)
    'Valitse kieli', // fi
    'Valige keel', // et
    'V\u00E4lj spr\u00E5k', // sv
    'Sprache w\u00E4hlen', // de
    '\u0627\u062E\u062A\u0631 \u0644\u063A\u062A\u0643', // اختر لغتك (ar)
    'Choisissez votre langue', // fr
    'Elige tu idioma', // es
    'Scegli la tua lingua', // it
    'Wybierz swój język', // pl
    'Izvēlieties valodu', // lv
    'Pasirinkite kalbą', // lt
    'Alegeți limba', // ro
    'Dilinizi seçin', // tr
    '\u041E\u0431\u0435\u0440\u0456\u0442\u044C \u043C\u043E\u0432\u0443', // Оберіть мову (uk)
    '\u0632\u0628\u0627\u0646 \u062E\u0648\u062F \u0631\u0627 \u0627\u0646\u062A\u062E\u0627\u0628 \u06A9\u0646\u06CC\u062F', // زبان خود را انتخاب کنید (fa)
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.lg),

          // Globe icon with entrance animation
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.language_rounded,
              size: 40,
              color: AppColors.accent,
            ),
          )
              .animate()
              .scaleXY(
                begin: 0.5,
                end: 1.0,
                duration: 600.ms,
                curve: Curves.elasticOut,
              )
              .fadeIn(duration: 400.ms),

          const SizedBox(height: AppSpacing.md),

          // Multilingual titles with staggered fade-in
          ...List.generate(_multilingualTitles.length, (i) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Text(
                _multilingualTitles[i],
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            )
                .animate()
                .fadeIn(
                  delay: Duration(milliseconds: 300 + i * 80),
                  duration: 350.ms,
                )
                .slideY(
                  begin: 0.2,
                  end: 0,
                  delay: Duration(milliseconds: 300 + i * 80),
                  duration: 350.ms,
                  curve: Curves.easeOutCubic,
                );
          }),

          const SizedBox(height: AppSpacing.lg),

          // Language grid (2 columns) with staggered entrance
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.4,
              shrinkWrap: true,
              children: [
                for (int i = 0; i < supportedLanguages.length; i++)
                  _LanguageButton(
                    flag: supportedLanguages[i].flag,
                    label: supportedLanguages[i].name,
                    onTap: () => onLanguageSelected(supportedLanguages[i].code),
                    delay: Duration(milliseconds: 600 + i * 70),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageButton extends StatefulWidget {
  const _LanguageButton({
    required this.flag,
    required this.label,
    required this.onTap,
    required this.delay,
  });

  final String flag;
  final String label;
  final VoidCallback onTap;
  final Duration delay;

  @override
  State<_LanguageButton> createState() => _LanguageButtonState();
}

class _LanguageButtonState extends State<_LanguageButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: _pressed
                ? AppColors.accent.withValues(alpha: 0.06)
                : AppColors.surface,
            border: Border.all(
              color: _pressed ? AppColors.accent : AppColors.border,
              width: _pressed ? 1.5 : 1.0,
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: _pressed
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.flag, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: widget.delay, duration: 300.ms)
        .scaleXY(
          begin: 0.85,
          end: 1.0,
          delay: widget.delay,
          duration: 300.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
