import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../config/theme.dart';

// ---------------------------------------------------------------------------
// First-time welcome modal (backlog #36; reordered Bentley P8, 2026-05-16)
// ---------------------------------------------------------------------------
//
// Shown once per device after the first authenticated arrival on Home.
// Three quick-action cards funnel the user into doing something valuable
// inside 60 s. The order is conversion-driven, not feature-symmetric:
//
//   1. Upload a contract  — FEATURED. Contract review is our highest-
//                            converting flow (financial analyst, 2026-05-16:
//                            free contract → paid review is the single
//                            biggest path-to-pay). Rendered larger with a
//                            visual lead so it's the first thing the eye
//                            lands on.
//   2. Ask a legal question — secondary; supports anyone who arrived with
//                              a Q in mind.
//   3. Try a sample case  — last; safety-net for users who want a guided
//                            demo before committing anything.
//
// All copy is inlined per-locale (EN/ET/FI/RU + EN fallback) so this widget
// does not depend on regenerating the auto-generated AppLocalizations.

enum WelcomeAction { sampleCase, uploadContract, askQuestion, skip }

/// Returns the action the user picked, or `WelcomeAction.skip` if they
/// dismissed without choosing. Never returns null — barrier dismiss is
/// disabled so the user must commit to one of the four exits.
Future<WelcomeAction> showWelcomeModal(
  BuildContext context, {
  required String locale,
}) async {
  final picked = await showDialog<WelcomeAction>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (ctx) => WelcomeModal(locale: locale),
  );
  return picked ?? WelcomeAction.skip;
}

class WelcomeModal extends StatelessWidget {
  const WelcomeModal({super.key, required this.locale});

  final String locale;

  String _t(String key) => _strings(locale)[key] ?? _strings('en')[key]!;

  static Map<String, Map<String, String>> get _table => {
        'en': {
          'headline': 'Welcome to Advocat',
          'subhead': 'Pick one to start. You can change your mind any time.',
          // Featured card (#1) — emphasised copy
          'upload_title': 'Try contract review — free',
          'upload_body':
              'Upload a PDF and get a plain-language risk report in 60 seconds. '
                  'Your first review is on us.',
          'upload_featured_badge': 'Most popular',
          'ask_title': 'Ask a legal question',
          'ask_body': 'Type any question. We answer in your language.',
          'sample_title': 'See a sample case',
          'sample_body':
              'Watch Advocat analyze a real service agreement in 15 seconds.',
          'skip': 'Skip — I know what I\u2019m doing',
        },
        'et': {
          'headline': 'Tere tulemast Advocati',
          'subhead': 'Vali üks, et alustada. Saad meelt muuta igal hetkel.',
          'upload_title': 'Proovi lepingu ülevaatust — tasuta',
          'upload_body':
              'Lae üles PDF ja saa lihtsas keeles riskiaruanne 60 sekundiga. '
                  'Esimene ülevaatus on meie kingitus.',
          'upload_featured_badge': 'Populaarseim',
          'ask_title': 'Esita juriidiline küsimus',
          'ask_body': 'Kirjuta küsimus. Vastame sinu keeles.',
          'sample_title': 'Vaata näidisjuhtumit',
          'sample_body':
              'Vaata, kuidas Advocat analüüsib teenuse lepingut 15 sekundiga.',
          'skip': 'Jäta vahele — tean, mida teen',
        },
        'fi': {
          'headline': 'Tervetuloa Advocatiin',
          'subhead':
              'Valitse yksi aloittaaksesi. Voit muuttaa mieltäsi milloin tahansa.',
          'upload_title': 'Kokeile sopimuksen tarkistusta — ilmaiseksi',
          'upload_body':
              'Lataa PDF ja saa selkokielinen riskiraportti 60 sekunnissa. '
                  'Ensimmäinen tarkistus on lahjamme.',
          'upload_featured_badge': 'Suosituin',
          'ask_title': 'Kysy oikeudellinen kysymys',
          'ask_body': 'Kirjoita kysymys. Vastaamme sinun kielelläsi.',
          'sample_title': 'Katso esimerkkitapaus',
          'sample_body':
              'Katso, miten Advocat analysoi palvelusopimuksen 15 sekunnissa.',
          'skip': 'Ohita — tiedän, mitä teen',
        },
        'ru': {
          'headline': 'Добро пожаловать в Advocat',
          'subhead':
              'Выберите одно, чтобы начать. Решение можно поменять в любой момент.',
          'upload_title': 'Проверить договор — бесплатно',
          'upload_body':
              'Загрузите PDF и получите отчёт о рисках простым языком за 60 секунд. '
                  'Первая проверка — за наш счёт.',
          'upload_featured_badge': 'Популярнее всего',
          'ask_title': 'Задать юридический вопрос',
          'ask_body': 'Напишите вопрос. Отвечаем на вашем языке.',
          'sample_title': 'Посмотреть пример дела',
          'sample_body':
              'Посмотрите, как Advocat разбирает договор оказания услуг за 15 секунд.',
          'skip': 'Пропустить — я знаю, что делаю',
        },
      };

  static Map<String, String> _strings(String code) {
    return _table[code.toLowerCase()] ?? _table['en']!;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Constrain so the modal looks like a card on desktop but goes nearly
    // full-bleed on phones.
    final maxWidth = media.size.width >= 720 ? 520.0 : double.infinity;

    return Dialog(
      key: const Key('welcome_modal_dialog'),
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: 640),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Headline
              Text(
                _t('headline'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: -0.1, end: 0, duration: 300.ms),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _t('subhead'),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ).animate(delay: 80.ms).fadeIn(duration: 300.ms),
              const SizedBox(height: AppSpacing.lg),

              // Card 1 (FEATURED, Bentley P8 2026-05-16): Upload contract.
              // Visually emphasised — larger padding, primary brand colour,
              // "Most popular" badge — because contract review is our
              // highest-converting flow.
              _WelcomeActionCard(
                key: const Key('welcome_modal_upload'),
                icon: Icons.upload_file_rounded,
                accentColor: AppColors.primary,
                title: _t('upload_title'),
                body: _t('upload_body'),
                badge: _t('upload_featured_badge'),
                featured: true,
                onTap: () =>
                    Navigator.of(context).pop(WelcomeAction.uploadContract),
                delay: 120.ms,
              ),
              const SizedBox(height: AppSpacing.sm),

              // Card 2: Ask a legal question
              _WelcomeActionCard(
                key: const Key('welcome_modal_ask'),
                icon: Icons.chat_bubble_outline_rounded,
                accentColor: AppColors.info,
                title: _t('ask_title'),
                body: _t('ask_body'),
                onTap: () =>
                    Navigator.of(context).pop(WelcomeAction.askQuestion),
                delay: 180.ms,
              ),
              const SizedBox(height: AppSpacing.sm),

              // Card 3: Sample case (fallback for browsers / unsure users)
              _WelcomeActionCard(
                key: const Key('welcome_modal_sample'),
                icon: Icons.auto_awesome_rounded,
                accentColor: AppColors.accent,
                title: _t('sample_title'),
                body: _t('sample_body'),
                onTap: () =>
                    Navigator.of(context).pop(WelcomeAction.sampleCase),
                delay: 240.ms,
              ),

              const SizedBox(height: AppSpacing.md),

              // Skip
              TextButton(
                key: const Key('welcome_modal_skip'),
                onPressed: () =>
                    Navigator.of(context).pop(WelcomeAction.skip),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textTertiary,
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                child: Text(_t('skip')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeActionCard extends StatefulWidget {
  const _WelcomeActionCard({
    super.key,
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.body,
    required this.onTap,
    required this.delay,
    this.featured = false,
    this.badge,
  });

  final IconData icon;
  final Color accentColor;
  final String title;
  final String body;
  final VoidCallback onTap;
  final Duration delay;

  /// When true the card renders bigger (taller padding, larger title,
  /// solid-tint icon tile, optional [badge]). Used to anchor the user's
  /// eye on the highest-converting choice. Defaults to false.
  final bool featured;

  /// Small pill rendered top-right when [featured] is true. Ignored on
  /// non-featured cards. Localised strings like "Most popular" /
  /// "Populaarseim".
  final String? badge;

  @override
  State<_WelcomeActionCard> createState() => _WelcomeActionCardState();
}

class _WelcomeActionCardState extends State<_WelcomeActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final featured = widget.featured;
    // Featured tuning (Bentley P8 2026-05-16): emphasised but not so tall
    // that the modal overflows the default 600px-height test viewport.
    final double verticalPadding = featured ? 16 : 14;
    final double iconSize = featured ? 48 : 44;
    final double iconGlyphSize = featured ? 26 : 22;
    final double titleSize = featured ? 16 : 15;
    final double bodySize = featured ? 13 : 13;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: verticalPadding,
          ),
          decoration: BoxDecoration(
            color: widget.accentColor
                .withValues(alpha: featured ? 0.10 : 0.06),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: widget.accentColor.withValues(
                alpha: _pressed ? 0.7 : (featured ? 0.45 : 0.25),
              ),
              width: featured ? 1.5 : (_pressed ? 1.5 : 1.0),
            ),
            boxShadow: featured
                ? [
                    BoxShadow(
                      color: widget.accentColor.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              Row(
                children: [
                  Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      color: widget.accentColor
                          .withValues(alpha: featured ? 0.18 : 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.accentColor,
                      size: iconGlyphSize,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Featured cards reserve a top slot for the badge,
                        // so push the title down a hair to balance.
                        if (featured && widget.badge != null)
                          const SizedBox(height: 18),
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: titleSize,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.body,
                          style: TextStyle(
                            fontSize: bodySize,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: widget.accentColor
                        .withValues(alpha: featured ? 0.9 : 0.7),
                    size: featured ? 26 : 22,
                  ),
                ],
              ),
              if (featured && widget.badge != null)
                Positioned(
                  top: 0,
                  right: 28,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: widget.accentColor,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      widget.badge!,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ).animate(delay: widget.delay).fadeIn(duration: 300.ms).slideY(
          begin: 0.15,
          end: 0,
          duration: 300.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
