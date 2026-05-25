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
  static Map<String, Map<String, String>> get _table => {
        'en': {
          'title': "Looks like you're using Advocat professionally",
          'body':
              "We're building a separate version for law firms — multi-seat, "
                  "shared cases, audit log. Want 50% off a 3-month pilot?",
          'dismiss': 'Not now',
          'learn_more': 'Learn more',
        },
        'et': {
          'title': 'Tundub, et kasutate Advocati professionaalselt',
          'body':
              'Ehitame eraldi versiooni juriidilistele büroodele — mitu konto'
                  'kasutajat, jagatud juhtumid, auditi logi. Kas soovite '
                  '50% soodustust 3-kuulisele pilootkasutusele?',
          'dismiss': 'Mitte praegu',
          'learn_more': 'Lugege rohkem',
        },
        'ru': {
          'title': 'Похоже, вы используете Advocat профессионально',
          'body':
              'Мы строим отдельную версию для юр.фирм — multi-seat, общие '
                  'дела, журнал аудита. Хотите 50% off на 3-месячный пилот?',
          'dismiss': 'Не сейчас',
          'learn_more': 'Узнать больше',
        },
        'fi': {
          'title': 'Näyttää siltä, että käytät Advocatia ammatillisesti',
          'body':
              'Rakennamme erillistä versiota lakitoimistoille — useita '
                  'käyttäjiä, jaetut tapaukset, auditointiloki. Haluatko '
                  '50% alennuksen 3 kuukauden pilotista?',
          'dismiss': 'Ei nyt',
          'learn_more': 'Lue lisää',
        },
        'de': {
          'title': 'Sieht so aus, als nutzen Sie Advocat beruflich',
          'body':
              'Wir bauen eine separate Version für Kanzleien — Multi-Seat, '
                  'geteilte Fälle, Audit-Log. Möchten Sie 50% Rabatt auf '
                  'eine 3-monatige Pilotphase?',
          'dismiss': 'Nicht jetzt',
          'learn_more': 'Mehr erfahren',
        },
        // Carry-over locales (parity with welcome_modal). Not strictly
        // required by the brief but cheap to include — keeps the user out
        // of a hard EN fallback on a sensitive paid-touch surface.
        'fr': {
          'title':
              'On dirait que vous utilisez Advocat à titre professionnel',
          'body':
              "Nous construisons une version dédiée aux cabinets d'avocats "
                  "— multi-sièges, dossiers partagés, journal d'audit. "
                  "Profitez de 50 % de réduction sur un pilote de 3 mois ?",
          'dismiss': 'Pas maintenant',
          'learn_more': 'En savoir plus',
        },
        'es': {
          'title': 'Parece que usas Advocat profesionalmente',
          'body':
              'Estamos creando una versión específica para despachos — '
                  'multi-asiento, casos compartidos, registro de auditoría. '
                  '¿Quieres un 50 % de descuento en un piloto de 3 meses?',
          'dismiss': 'Ahora no',
          'learn_more': 'Saber más',
        },
        'it': {
          'title': 'Sembra che usi Advocat professionalmente',
          'body':
              'Stiamo creando una versione separata per studi legali — '
                  "multi-sede, casi condivisi, log d'audit. Vuoi il 50% di "
                  'sconto su un pilota di 3 mesi?',
          'dismiss': 'Non ora',
          'learn_more': 'Scopri di più',
        },
        'pl': {
          'title': 'Wygląda na to, że używasz Advocat zawodowo',
          'body':
              'Tworzymy osobną wersję dla kancelarii — multi-seat, wspólne '
                  'sprawy, dziennik audytu. Chcesz 50% zniżki na pilotaż '
                  '3-miesięczny?',
          'dismiss': 'Nie teraz',
          'learn_more': 'Dowiedz się więcej',
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
