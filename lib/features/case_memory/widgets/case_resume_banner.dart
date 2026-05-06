// =====================================================================
// CaseResumeBanner — Phase 2 Pkg 5 (§7.2)
//
// When the user opens a case chat after a gap >24h AND the case is in
// a non-trivial phase (strategy / draft / wait), show a top banner
// with phase-specific resume copy:
//
//   STRATEGY: "Last time we were planning. Continue with the strategy?"
//   DRAFT:    "Last time we were drafting <last action>. Pick up where
//              we left off?"
//   WAIT:     "You were waiting for <last action>. Any news?"
//
// Hidden for intake (no anchor yet) and closed (read-only).
//
// Stateless: parent passes phase + timestamps + locale + dismiss
// callback. SharedPreferences-based dismissal lives in the parent
// screen — this widget just renders the chrome.
// =====================================================================

import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../models/case_phase.dart';

class CaseResumeBanner extends StatelessWidget {
  const CaseResumeBanner({
    super.key,
    required this.phase,
    required this.phaseEnteredAt,
    required this.lastSessionEndedAt,
    required this.onDismiss,
    this.lastActionSummary,
    this.locale,
  });

  final CasePhase phase;
  final DateTime? phaseEnteredAt;
  final DateTime? lastSessionEndedAt;
  final String? lastActionSummary;
  final String? locale;
  final VoidCallback onDismiss;

  /// Threshold below which we suppress the banner — same-day return
  /// doesn't need a resume cue. Mirrors the design doc §7.2.
  static const Duration _gapThreshold = Duration(hours: 24);

  bool get _shouldShow {
    // Phase gates — only the three "active work" phases get a banner.
    if (phase != CasePhase.strategy &&
        phase != CasePhase.draft &&
        phase != CasePhase.wait) {
      return false;
    }
    // Gap gate — first session, or recent session, no banner.
    final last = lastSessionEndedAt;
    if (last == null) return false;
    final gap = DateTime.now().difference(last);
    return gap >= _gapThreshold;
  }

  IconData _icon() {
    switch (phase) {
      case CasePhase.strategy:
        return Icons.lightbulb_outline;
      case CasePhase.draft:
        return Icons.edit_note;
      case CasePhase.wait:
        return Icons.hourglass_empty;
      case CasePhase.intake:
      case CasePhase.closed:
        return Icons.info_outline;
    }
  }

  /// Per-phase resume prompt, localised for en/ru/et/fi (primary trio
  /// + Sulga-Finland). Other locales fall back to English.
  String _copy() {
    final lang = locale ?? 'en';
    final base =
        _resumeCopy[phase]?[lang] ?? _resumeCopy[phase]?['en'] ?? '';
    final last = lastActionSummary;
    final tail = (last != null && last.isNotEmpty) ? ' — $last' : '';
    return '$base$tail';
  }

  static const Map<CasePhase, Map<String, String>> _resumeCopy = {
    CasePhase.strategy: {
      'en': "Last time we were planning the strategy. Pick up where we left off?",
      'et': 'Eelmisel korral arutasime strateegiat. Jätkame samast kohast?',
      'ru': 'В прошлый раз мы обсуждали стратегию. Продолжим?',
      'fi': 'Viimeksi suunnittelimme strategiaa. Jatketaanko siitä mihin jäimme?',
    },
    CasePhase.draft: {
      'en': "We were drafting a document last time. Continue?",
      'et': 'Eelmisel korral koostasime dokumenti. Jätkame?',
      'ru': 'В прошлый раз мы готовили документ. Продолжим?',
      'fi': 'Viimeksi laadimme asiakirjaa. Jatketaanko?',
    },
    CasePhase.wait: {
      'en': "You were waiting for a response. Any news?",
      'et': 'Te ootasite vastust. Kas on uudiseid?',
      'ru': 'Вы ожидали ответа. Есть новости?',
      'fi': 'Odotitte vastausta. Onko uutisia?',
    },
  };

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow) return const SizedBox.shrink();

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon(), size: 16, color: AppColors.accentDark),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _copy(),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.accentDark,
                height: 1.4,
              ),
            ),
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
