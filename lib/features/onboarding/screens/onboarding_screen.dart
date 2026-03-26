import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../main.dart';
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

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Total pages: 1 language + 4 feature
  static const _pageCount = 5;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // -- Navigation helpers --------------------------------------------------

  void _goToNextPage() {
    if (_currentPage < _pageCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // -- Skip button (top-right, hidden on language and last page) --
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.sm,
                  right: AppSpacing.md,
                ),
                child: AnimatedOpacity(
                  opacity: (isLastPage || isLanguagePage) ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: TextButton(
                    onPressed: (isLastPage || isLanguagePage)
                        ? null
                        : _navigateToLogin,
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
                    : const PageScrollPhysics(),
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
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      margin:
                          const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.accent
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(4),
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
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _goToNextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            isLastPage
                                ? l.getStarted
                                : l.onboardingNext,
                            key: ValueKey(isLastPage),
                          ),
                        ),
                      ),
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
    );
  }
}

// ---------------------------------------------------------------------------
// Language Selection Page (page 0)
// ---------------------------------------------------------------------------

class _LanguageSelectionPage extends StatelessWidget {
  const _LanguageSelectionPage({required this.onLanguageSelected});

  final ValueChanged<String> onLanguageSelected;

  // Title shown in all 7 languages so every user can read it
  static const _multilingualTitles = [
    'Choose your language',
    '\u0412\u044B\u0431\u0435\u0440\u0438\u0442\u0435 \u044F\u0437\u044B\u043A', // Выберите язык
    'Valitse kieli',
    'Valige keel',
    'V\u00E4lj spr\u00E5k',
    'Sprache w\u00E4hlen',
    '\u0627\u062E\u062A\u0631 \u0644\u063A\u062A\u0643', // اختر لغتك
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.lg),

          // Globe icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.language_rounded,
              size: 40,
              color: AppColors.accent,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Multilingual titles
          for (final title in _multilingualTitles)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          const SizedBox(height: AppSpacing.lg),

          // Language grid (2 columns)
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.4,
              shrinkWrap: true,
              children: [
                for (final lang in supportedLanguages)
                  _LanguageButton(
                    flag: lang.flag,
                    label: lang.name,
                    onTap: () => onLanguageSelected(lang.code),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageButton extends StatelessWidget {
  const _LanguageButton({
    required this.flag,
    required this.label,
    required this.onTap,
  });

  final String flag;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(flag, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  label,
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
    );
  }
}
