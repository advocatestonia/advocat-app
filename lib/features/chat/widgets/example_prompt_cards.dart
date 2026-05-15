import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/theme.dart';

// ---------------------------------------------------------------------------
// Empty-state example prompt cards (backlog #36, Layer 4)
// ---------------------------------------------------------------------------
//
// Renders inside the chat screen when the conversation has no user messages
// yet. Complements [ChatWelcomeChips]: those are 5 broad legal *categories*,
// these are 3 *concrete prompt examples* showing what a good question to
// Advocat looks like. Tapping inserts the prompt verbatim into the chat
// input and focuses it — the user can edit before sending. The cards
// disappear as soon as the first user message lands.
//
// Localized inline (EN/ET/FI/RU + EN fallback) to keep this surgical and
// avoid touching the auto-generated AppLocalizations.

enum ExamplePrompt { translate, landlord, nda }

class ExamplePromptCards extends StatelessWidget {
  const ExamplePromptCards({
    super.key,
    required this.locale,
    required this.onPromptSelected,
  });

  final String locale;

  /// Fired with the full prompt text in [locale] when the user taps a card.
  /// Parent inserts it into the message controller and focuses the input —
  /// the user types or hits send.
  final void Function(String prompt) onPromptSelected;

  static String _header(String code) {
    switch (code.toLowerCase()) {
      case 'et':
        return 'Proovi näiteks';
      case 'fi':
        return 'Kokeile esimerkiksi';
      case 'ru':
        return 'Например, попробуйте';
      default:
        return 'Try one of these';
    }
  }

  static String _promptText(ExamplePrompt p, String code) {
    switch (p) {
      case ExamplePrompt.translate:
        switch (code.toLowerCase()) {
          case 'et':
            return 'Tõlgi see leping saksa keelest eesti keelde';
          case 'fi':
            return 'Käännä tämä sopimus saksasta suomeksi';
          case 'ru':
            return 'Переведи этот договор с немецкого на русский';
          default:
            return 'Translate this contract from German to Estonian';
        }
      case ExamplePrompt.landlord:
        switch (code.toLowerCase()) {
          case 'et':
            return 'Millised on minu õigused, kui üürileandja tõstab üüri?';
          case 'fi':
            return 'Mitkä ovat oikeuteni, jos vuokranantaja nostaa vuokraa?';
          case 'ru':
            return 'Какие у меня права, если арендодатель повышает арендную плату?';
          default:
            return 'What are my rights if my landlord raises rent?';
        }
      case ExamplePrompt.nda:
        switch (code.toLowerCase()) {
          case 'et':
            return 'Koosta vabakutselisele konfidentsiaalsusleping (NDA)';
          case 'fi':
            return 'Laadi salassapitosopimus (NDA) freelancerille';
          case 'ru':
            return 'Составь соглашение о неразглашении (NDA) для фрилансера';
          default:
            return 'Draft a non-disclosure agreement for a freelancer';
        }
    }
  }

  static IconData _icon(ExamplePrompt p) {
    switch (p) {
      case ExamplePrompt.translate:
        return Icons.translate_rounded;
      case ExamplePrompt.landlord:
        return Icons.home_outlined;
      case ExamplePrompt.nda:
        return Icons.description_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = locale.toLowerCase();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              _header(code),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiary,
                letterSpacing: 0.3,
              ),
            ),
          ),
          for (final p in ExamplePrompt.values) ...[
            _ExamplePromptCard(
              key: Key('example_prompt_${p.name}'),
              icon: _icon(p),
              text: _promptText(p, code),
              onTap: () => onPromptSelected(_promptText(p, code)),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _ExamplePromptCard extends StatelessWidget {
  const _ExamplePromptCard({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.7),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    height: 1.35,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_outward_rounded,
                size: 16,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
