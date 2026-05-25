// =====================================================================
// SoftCaseBanner — one-line rename prompt for auto-created shell cases.
//
// Shown after a first-touch document upload triggered
// PdfParserService to materialise a soft-case shell (see migration
// 20260525220000 and pdf_parser_service.dart). Without renaming, the
// case stays as "Untitled case YYYY-MM-DD" — functional but noisy in
// the case list.
//
// Stateless: parent screen owns the dismiss + navigation. We localise
// for the minimum-four locales (en/et/ru/fi) and fall back to English
// for everything else. App-level l10n keys exist (softCaseShellBanner +
// softCaseShellBannerCta) so callers that already have a BuildContext
// can use them; this widget exposes raw strings so it can be wired up
// from any surface — chat success card, file detail screen, etc.
//
// Tapping the body OR the CTA opens the case-rename screen
// (`/cases-v2/<id>/edit`). The widget itself only emits the intent via
// [onRenamePressed] — keeps the router dependency out of the widget.
// =====================================================================

import 'package:flutter/material.dart';

import '../../../config/theme.dart';

class SoftCaseBanner extends StatelessWidget {
  const SoftCaseBanner({
    super.key,
    required this.softCaseId,
    required this.onRenamePressed,
    required this.onDismiss,
    this.locale,
  });

  /// The id of the freshly-created shell case. Forwarded to
  /// [onRenamePressed] so the parent screen can navigate to the
  /// rename surface for THAT case (not the user's most recent one).
  final String softCaseId;

  /// User tapped the body OR the CTA. Parent navigates to
  /// `/cases-v2/<softCaseId>/edit` (see config/router.dart).
  final ValueChanged<String> onRenamePressed;

  /// User dismissed the banner. The shell still exists in the DB; it
  /// just won't be advertised again on this surface.
  final VoidCallback onDismiss;

  /// IETF language tag — falls back to English for unknown locales.
  final String? locale;

  static const Map<String, _Copy> _copy = {
    'en': _Copy(
      body: 'We created "Untitled case" to track this. Tap to rename.',
      cta: 'Rename',
    ),
    'et': _Copy(
      body: 'Lõime „Nimetu toimik" selle jälgimiseks. Vajuta ümbernimetamiseks.',
      cta: 'Nimeta ümber',
    ),
    'ru': _Copy(
      body: 'Мы создали «Без названия», чтобы отслеживать это дело. '
          'Нажмите, чтобы переименовать.',
      cta: 'Переименовать',
    ),
    'fi': _Copy(
      body: 'Loimme "Nimetön asia" -kohteen tämän seuraamiseksi. '
          'Napauta nimetäksesi uudelleen.',
      cta: 'Nimeä uudelleen',
    ),
  };

  _Copy get _strings {
    final lang = (locale ?? 'en').toLowerCase().split(RegExp(r'[-_]')).first;
    return _copy[lang] ?? _copy['en']!;
  }

  @override
  Widget build(BuildContext context) {
    final s = _strings;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        border: Border(
          bottom: BorderSide(
            color: AppColors.accent.withValues(alpha: 0.20),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.edit_note,
            size: 18,
            color: AppColors.accentDark,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: InkWell(
              onTap: () => onRenamePressed(softCaseId),
              child: Text(
                s.body,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.accentDark,
                  height: 1.35,
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: () => onRenamePressed(softCaseId),
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              foregroundColor: AppColors.accentDark,
            ),
            child: Text(s.cta),
          ),
          InkWell(
            onTap: onDismiss,
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.close,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Copy {
  const _Copy({required this.body, required this.cta});
  final String body;
  final String cta;
}
