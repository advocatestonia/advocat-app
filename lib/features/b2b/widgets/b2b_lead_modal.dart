// =============================================================================
// b2b_lead_modal.dart
// =============================================================================
//
// Tasteful, one-time "Looks like you're using Advocat professionally?" modal.
// Shown to a user when backend's silent-signal detector sets
// `profiles.b2b_modal_pending = true`. The detector is owned by a parallel
// agent — this widget is purely client UI plus a result enum.
//
// Design constraints (from product brief 2026-05-25):
//   * Soft register, NOT aggressive. Two buttons only: "Not now" (ghost) and
//     "Learn more" (primary). No prices in the modal — those are talk-track,
//     not a paywall.
//   * Multi-locale (en/et/ru/fi/de + 4 extra carry-overs for parity with
//     welcome_modal). Unknown locales fall back to EN.
//   * Visual register mirrors welcome_modal.dart (same Dialog + corner radius
//     + spacing tokens) so the user reads it as "Advocat is talking to me",
//     not a paywall.
//   * One-shot: once the user picks any action, backend marks
//     `b2b_modal_shown_at = now()` and we never show it again for 90 days.
//
// API contract:
//   `showB2BLeadModal(BuildContext)` → returns the user's pick:
//     - [B2BAction.dismiss]   user tapped "Not now" or barrier-dismissed
//     - [B2BAction.learnMore] user tapped "Learn more"
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/theme.dart';

/// The result returned by [showB2BLeadModal]. `dismiss` is also the value
/// for a barrier-dismiss / Android back-button — callers should treat
/// "anything except [learnMore]" as a soft-skip and still mark the modal
/// as shown (per spec: don't pester again).
enum B2BAction { dismiss, learnMore }

/// Imperative entry point. Returns the user's choice. The modal is non-
/// dismissable by barrier-tap so users have to commit to one of the two
/// buttons; the only way to get [B2BAction.dismiss] is by pressing
/// "Not now" (or the system back gesture, which routes through the
/// fall-through `pop()` and lands on `dismiss`).
Future<B2BAction> showB2BLeadModal(
  BuildContext context, {
  required String locale,
}) async {
  final picked = await showDialog<B2BAction>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (ctx) => B2BLeadModal(locale: locale),
  );
  return picked ?? B2BAction.dismiss;
}

class B2BLeadModal extends StatelessWidget {
  const B2BLeadModal({super.key, required this.locale});

  final String locale;

  String _t(String key) => _strings(locale)[key] ?? _strings('en')[key]!;

  /// All copy is inlined per-locale so this widget doesn't depend on the
  /// auto-generated [AppLocalizations] (which lags real shipping pace).
  ///
  /// Mandatory locales per brief: en/et/ru/fi/de. The 4 carry-over slots
  /// (fr/es/it/pl) mirror welcome_modal coverage so DACH / LATAM / Adriatic
  /// users don't drop to EN on a paid-touch surface.
  ///
  /// v2 (2026-05-25) — copy refinement per analyst consilium.
  /// The v1 wording ("looks like you're using Advocat professionally") was
  /// flagged for two issues: (a) it sounds surveilling — "we noticed", and
  /// (b) it pre-supposes a value claim before showing what's on offer. The
  /// new framing positions Advocat-for-Firms as a closed-launch product
  /// the user is being invited to peek at: scarcity (limited to 15 firms),
  /// agency (you decide to look), and curiosity (we're BUILDING — not yet
  /// "buy this"). All locales mirror the FI/EE-specific register without
  /// literal-translating "büroo / toimisto" into languages that don't use
  /// those words for law firms.
  static Map<String, Map<String, String>> get _table => {
        'en': {
          'title': 'Building Advocat Firm — the law-firm edition',
          'body':
              "Closed launch, limited to 15 firms. Want to see what we're "
                  'building?',
          'dismiss': 'Not now',
          'learn_more': 'Tell me more',
        },
        'et': {
          'title': 'Ehitame Advocat Firm-i — versiooni büroodele',
          'body':
              'Suletud käivitamine, piiratud 15 bürooga. Soovite näha, mida '
                  'ehitame?',
          'dismiss': 'Mitte praegu',
          'learn_more': 'Räägi lähemalt',
        },
        'ru': {
          'title': 'Строим Advocat Firm — версию для бюро',
          'body':
              'Закрытый запуск, ограничено 15 фирмами. Посмотрите, что '
                  'готовим?',
          'dismiss': 'Не сейчас',
          'learn_more': 'Расскажите подробнее',
        },
        'fi': {
          'title':
              'Rakennamme Advocat Firm -versiota — lakitoimistoille',
          'body':
              'Suljettu lanseeraus, rajoitettu 15 toimistoon. Haluatko '
                  'nähdä, mitä rakennamme?',
          'dismiss': 'Ei nyt',
          'learn_more': 'Kerro lisää',
        },
        'de': {
          'title': 'Wir bauen Advocat Firm — die Edition für Kanzleien',
          'body':
              'Geschlossener Start, auf 15 Kanzleien begrenzt. Möchten Sie '
                  'sehen, was wir bauen?',
          'dismiss': 'Nicht jetzt',
          'learn_more': 'Mehr erzählen',
        },
        // Carry-over locales (parity with welcome_modal). Not strictly
        // required by the brief but cheap to include — keeps the user out
        // of a hard EN fallback on a sensitive paid-touch surface.
        'fr': {
          'title': "Nous construisons Advocat Firm — l'édition pour cabinets",
          'body':
              'Lancement fermé, limité à 15 cabinets. Vous voulez voir ce '
                  'que nous construisons ?',
          'dismiss': 'Pas maintenant',
          'learn_more': 'En dire plus',
        },
        'es': {
          'title': 'Estamos creando Advocat Firm — la edición para despachos',
          'body':
              'Lanzamiento cerrado, limitado a 15 despachos. ¿Quieres ver '
                  'qué estamos construyendo?',
          'dismiss': 'Ahora no',
          'learn_more': 'Cuéntame más',
        },
        'it': {
          'title': 'Stiamo costruendo Advocat Firm — la versione per studi',
          'body':
              'Lancio chiuso, limitato a 15 studi. Vuoi vedere cosa stiamo '
                  'costruendo?',
          'dismiss': 'Non ora',
          'learn_more': 'Raccontami di più',
        },
        'pl': {
          'title': 'Budujemy Advocat Firm — wersję dla kancelarii',
          'body':
              'Zamknięty start, ograniczony do 15 kancelarii. Chcesz '
                  'zobaczyć, co budujemy?',
          'dismiss': 'Nie teraz',
          'learn_more': 'Opowiedz mi więcej',
        },
      };

  static Map<String, String> _strings(String code) {
    return _table[code.toLowerCase()] ?? _table['en']!;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxWidth = media.size.width >= 720 ? 460.0 : double.infinity;

    return Dialog(
      key: const Key('b2b_lead_modal_dialog'),
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
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
              // Soft brand affordance — sets the "we noticed you" register
              // without screaming a paywall icon at the user.
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: const Icon(
                    Icons.business_center_rounded,
                    size: 28,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Headline — 18sp, semibold; smaller than welcome_modal's 24sp
              // because this surface is informational, not aspirational.
              Text(
                _t('title'),
                key: const Key('b2b_lead_modal_title'),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),

              // Body — set in textSecondary to keep the modal calm.
              Text(
                _t('body'),
                key: const Key('b2b_lead_modal_body'),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Primary CTA — "Learn more" routes the user to the contact
              // form. Same accent register as the contract-review upgrade
              // dialog to keep visual continuity.
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  key: const Key('b2b_lead_modal_learn_more'),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).pop(B2BAction.learnMore);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  // Locale-specific arrow direction — we use a single right
                  // arrow because every supported locale here is LTR.
                  child: Text('${_t('learn_more')} \u2192'),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              // Dismiss — ghost text button, same register as
              // contract_review_upgrade_dialog's "Not now".
              TextButton(
                key: const Key('b2b_lead_modal_dismiss'),
                onPressed: () =>
                    Navigator.of(context).pop(B2BAction.dismiss),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textTertiary,
                  textStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                child: Text(_t('dismiss')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
