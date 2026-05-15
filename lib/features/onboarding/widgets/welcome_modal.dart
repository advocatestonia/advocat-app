import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../config/theme.dart';

// ---------------------------------------------------------------------------
// First-time welcome modal (backlog #36)
// ---------------------------------------------------------------------------
//
// Shown once per device after the first authenticated arrival on Home.
// Three quick-action cards funnel the user into doing something valuable
// inside 60 s: try a sample case, upload a contract, or ask a legal
// question. No multi-step tour — the cards are the tour.
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
          'sample_title': 'Try with a sample case',
          'sample_body':
              'See Advocat analyze a real service agreement in 15 seconds.',
          'upload_title': 'Upload your contract',
          'upload_body':
              'Drop a PDF — get a plain-language risk report.',
          'ask_title': 'Ask a legal question',
          'ask_body': 'Type any question. We answer in your language.',
          'skip': 'Skip — I know what I\u2019m doing',
        },
        'et': {
          'headline': 'Tere tulemast Advocati',
          'subhead': 'Vali üks, et alustada. Saad meelt muuta igal hetkel.',
          'sample_title': 'Proovi näidisjuhtumiga',
          'sample_body':
              'Vaata, kuidas Advocat analüüsib teenuse lepingut 15 sekundiga.',
          'upload_title': 'Lae üles oma leping',
          'upload_body':
              'Lisa PDF — saad lihtsas keeles riskiaruande.',
          'ask_title': 'Esita juriidiline küsimus',
          'ask_body': 'Kirjuta küsimus. Vastame sinu keeles.',
          'skip': 'Jäta vahele — tean, mida teen',
        },
        'fi': {
          'headline': 'Tervetuloa Advocatiin',
          'subhead':
              'Valitse yksi aloittaaksesi. Voit muuttaa mieltäsi milloin tahansa.',
          'sample_title': 'Kokeile esimerkkitapauksella',
          'sample_body':
              'Katso, miten Advocat analysoi palvelusopimuksen 15 sekunnissa.',
          'upload_title': 'Lataa oma sopimus',
          'upload_body':
              'Pudota PDF — saat selkokielisen riskiraportin.',
          'ask_title': 'Kysy oikeudellinen kysymys',
          'ask_body': 'Kirjoita kysymys. Vastaamme sinun kielelläsi.',
          'skip': 'Ohita — tiedän, mitä teen',
        },
        'ru': {
          'headline': 'Добро пожаловать в Advocat',
          'subhead':
              'Выберите одно, чтобы начать. Решение можно поменять в любой момент.',
          'sample_title': 'Попробовать на примере дела',
          'sample_body':
              'Посмотрите, как Advocat разбирает договор оказания услуг за 15 секунд.',
          'upload_title': 'Загрузить свой договор',
          'upload_body':
              'Бросьте PDF — получите отчёт о рисках простым языком.',
          'ask_title': 'Задать юридический вопрос',
          'ask_body': 'Напишите вопрос. Отвечаем на вашем языке.',
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

              // Card 1: Sample case
              _WelcomeActionCard(
                key: const Key('welcome_modal_sample'),
                icon: Icons.auto_awesome_rounded,
                accentColor: AppColors.accent,
                title: _t('sample_title'),
                body: _t('sample_body'),
                onTap: () =>
                    Navigator.of(context).pop(WelcomeAction.sampleCase),
                delay: 120.ms,
              ),
              const SizedBox(height: AppSpacing.sm),

              // Card 2: Upload contract
              _WelcomeActionCard(
                key: const Key('welcome_modal_upload'),
                icon: Icons.upload_file_rounded,
                accentColor: AppColors.primary,
                title: _t('upload_title'),
                body: _t('upload_body'),
                onTap: () =>
                    Navigator.of(context).pop(WelcomeAction.uploadContract),
                delay: 180.ms,
              ),
              const SizedBox(height: AppSpacing.sm),

              // Card 3: Ask question
              _WelcomeActionCard(
                key: const Key('welcome_modal_ask'),
                icon: Icons.chat_bubble_outline_rounded,
                accentColor: AppColors.info,
                title: _t('ask_title'),
                body: _t('ask_body'),
                onTap: () =>
                    Navigator.of(context).pop(WelcomeAction.askQuestion),
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
  });

  final IconData icon;
  final Color accentColor;
  final String title;
  final String body;
  final VoidCallback onTap;
  final Duration delay;

  @override
  State<_WelcomeActionCard> createState() => _WelcomeActionCardState();
}

class _WelcomeActionCardState extends State<_WelcomeActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: widget.accentColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: widget.accentColor.withValues(
                alpha: _pressed ? 0.6 : 0.25,
              ),
              width: _pressed ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(widget.icon, color: widget.accentColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.body,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: widget.accentColor.withValues(alpha: 0.7),
                size: 22,
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
