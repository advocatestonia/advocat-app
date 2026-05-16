// =============================================================================
// contract_upsell_card.dart — mid-conversation contract review nudge.
// =============================================================================
//
// Bentley P8 (2026-05-16, conversion lever).
//
// Why this exists:
//   * Free tier was bumped 7 → 10 messages/month on the same day.
//   * Contract review is the single highest-converting flow we ship (1 free
//     review per lifetime; once a user has *seen* their first risk report
//     they convert ~4x more often than chat-only users).
//   * Most users never discover contract review because it lives behind the
//     "+" upload button. We have ~3 messages of headroom between the avg
//     "aha" moment (msg 7-8) and the paywall at msg 10 → drop a soft
//     reminder card in the chat stream right when they are most engaged.
//
// Trigger contract (consumed by [ChatScreen]):
//   * Free tier only (Pro users have unlimited messages and unlimited
//     interest in contract review — the card would be noise).
//   * Show ONCE per session, the first time `_freeMessagesUsed >= 7`.
//   * Single-use: tapping "Upload" or "Dismiss" hides it for the rest of
//     the session. Reload of the page can show it again (intentional —
//     low-frequency re-exposure).
//
// Visual:
//   * Soft accent banner-card, full-width inside the chat list. NOT a modal.
//   * Inline "Upload" CTA on the right, "X" dismiss on the top-right corner.
//   * Pill text on the bottom-left: "First one's free".
//
// Telemetry:
//   * Writes append-only rows into `public.ab_events`:
//       experiment = 'contract_upsell', variant = 'v1', event = one of
//       contract_upsell_shown | contract_upsell_click | contract_upsell_dismiss.
//   * Fire-and-forget — never throws into the chat stream.
//
// Localised copy:
//   Inlined per locale (EN/ET/FI/RU + EN fallback) so the widget does not
//   depend on regenerating AppLocalizations. Matches the welcome_modal
//   pattern.
// =============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/theme.dart';
import '../../../services/feature_flags_ab.dart';

/// Inline upsell card rendered into the chat stream at message 7 of the
/// 10-message free tier. Consumers MUST set both [onUpload] (CTA tap)
/// and [onDismiss] (X tap); the card does not own its own visibility
/// state — that belongs to the parent so it survives ListView rebuilds.
class ContractUpsellCard extends StatefulWidget {
  const ContractUpsellCard({
    super.key,
    required this.locale,
    required this.onUpload,
    required this.onDismiss,
  });

  final String locale;
  final VoidCallback onUpload;
  final VoidCallback onDismiss;

  @override
  State<ContractUpsellCard> createState() => _ContractUpsellCardState();
}

class _ContractUpsellCardState extends State<ContractUpsellCard> {
  bool _impressionLogged = false;

  @override
  void initState() {
    super.initState();
    // Defer the impression write to after the first frame so we never
    // block layout. The fire-and-forget call is idempotent at the use
    // site (parent only inserts us once per session).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _impressionLogged) return;
      _impressionLogged = true;
      _trackEvent('contract_upsell_shown');
    });
  }

  /// Localised string lookup. EN fallback is guaranteed for every key.
  String _t(String key) => _strings(widget.locale)[key] ?? _strings('en')[key]!;

  static Map<String, Map<String, String>> get _table => const {
        'en': {
          'title': 'Got a contract you\u2019d like reviewed?',
          'body':
              'Upload it now — Advocat will flag the risky clauses in plain '
                  'language. Your first review is free.',
          'cta': 'Upload contract',
          'free_pill': 'First one\u2019s free',
          'dismiss_a11y': 'Dismiss',
        },
        'et': {
          'title': 'Kas sul on leping, mida tahaksid üle vaadata?',
          'body':
              'Lae see kohe üles — Advocat märgib riskantsed klauslid '
                  'lihtsas keeles. Esimene ülevaatus on tasuta.',
          'cta': 'Lae leping üles',
          'free_pill': 'Esimene on tasuta',
          'dismiss_a11y': 'Sulge',
        },
        'fi': {
          'title': 'Onko sinulla sopimus, jonka haluaisit tarkistettavaksi?',
          'body':
              'Lataa se nyt — Advocat merkitsee riskialttiit lausekkeet '
                  'selkokielellä. Ensimmäinen tarkistus on ilmainen.',
          'cta': 'Lataa sopimus',
          'free_pill': 'Ensimmäinen on ilmainen',
          'dismiss_a11y': 'Sulje',
        },
        'ru': {
          'title': 'Хотите, чтобы мы проверили ваш договор?',
          'body':
              'Загрузите его сейчас — Advocat подсветит рискованные пункты '
                  'простым языком. Первая проверка — бесплатно.',
          'cta': 'Загрузить договор',
          'free_pill': 'Первый — бесплатно',
          'dismiss_a11y': 'Закрыть',
        },
      };

  static Map<String, String> _strings(String code) {
    return _table[code.toLowerCase()] ?? _table['en']!;
  }

  /// Best-effort insert into `public.ab_events`. Never throws.
  Future<void> _trackEvent(String event) async {
    try {
      // Sanity guard so we don't typo and silently produce useless rows.
      if (!AbExperiment.isKnown(AbExperiment.contractUpsell)) return;
      final client = Supabase.instance.client;
      final uid = client.auth.currentUser?.id;
      // Anonymous users: skip — `ab_events` is RLS-gated by auth.uid().
      if (uid == null) return;
      await client.from('ab_events').insert({
        'user_id': uid,
        'experiment': AbExperiment.contractUpsell,
        'variant': AbVariant.v1,
        'event': event,
        // Lightweight context: locale + which trigger message we fired on
        // (parent inserts us at msg 7, so we just stamp the locale).
        'metadata': {'locale': widget.locale},
      });
    } catch (_) {
      // fire-and-forget — never break the chat stream for telemetry.
    }
  }

  void _handleUpload() {
    HapticFeedback.selectionClick();
    unawaited(_trackEvent('contract_upsell_click'));
    widget.onUpload();
  }

  void _handleDismiss() {
    HapticFeedback.selectionClick();
    unawaited(_trackEvent('contract_upsell_dismiss'));
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const Key('contract_upsell_card'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withValues(alpha: 0.10),
              AppColors.accent.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.30),
            width: 1.0,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(14, 14, 10, 12),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(
                        Icons.description_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Leave room above for the X icon (24px reserved
                          // via Stack child below) so titles never collide.
                          Padding(
                            padding: const EdgeInsets.only(right: 24),
                            child: Text(
                              _t('title'),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                height: 1.3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _t('body'),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Free pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 13,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _t('free_pill'),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // CTA
                    TextButton.icon(
                      key: const Key('contract_upsell_cta'),
                      onPressed: _handleUpload,
                      icon: const Icon(
                        Icons.upload_file_rounded,
                        size: 16,
                      ),
                      label: Text(_t('cta')),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Dismiss "X" — top-right
            Positioned(
              top: -4,
              right: -4,
              child: IconButton(
                key: const Key('contract_upsell_dismiss'),
                tooltip: _t('dismiss_a11y'),
                icon: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.textTertiary.withValues(alpha: 0.8),
                ),
                visualDensity: VisualDensity.compact,
                splashRadius: 18,
                onPressed: _handleDismiss,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(
          begin: 0.2,
          end: 0,
          duration: 300.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

