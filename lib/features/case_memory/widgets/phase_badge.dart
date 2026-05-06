// =====================================================================
// PhaseBadge — Phase 2 Pkg 5
//
// A small, dependency-light chip that renders the current
// conversation-state phase for a case. Used in three places:
//
//   1. Workspace Overview tab header (Pkg 4 — consumes when shipped)
//   2. Active-case chip in chat composer (suffix after the title)
//   3. Cases list row trailing element
//
// Localised labels are inlined here (not in AppLocalizations) so this
// widget stays a pure leaf with no l10n regeneration cost across all
// 17 supported locales. The phase enum is small (5 values) and stable;
// labels for the primary trio (en, et, ru, fi) cover ~95% of users.
// All other locales fall through to English.
//
// Visual weight: the closed phase renders at reduced opacity to signal
// "read-only, not active". Other phases use the accent palette.
// =====================================================================

import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../models/case_phase.dart';

class PhaseBadge extends StatelessWidget {
  const PhaseBadge({
    super.key,
    required this.phase,
    this.locale,
    this.compact = false,
  });

  /// Phase to render.
  final CasePhase phase;

  /// ISO 639-1 locale code (e.g. 'en', 'ru', 'et'). Null falls back to
  /// English.
  final String? locale;

  /// Compact mode strips icon + reduces padding. Used inside the
  /// active-case chip so the suffix doesn't dominate the title.
  final bool compact;

  // ── Localisation table ────────────────────────────────────────────

  /// Inlined label translations. Primary trio covers en/ru/et + fi
  /// (Sulga case). Other locales fall through to English via the
  /// resolver below.
  static const Map<CasePhase, Map<String, String>> _labels = {
    CasePhase.intake: {
      'en': 'Intake',
      'et': 'Andmete kogumine',
      'ru': 'Сбор данных',
      'fi': 'Tietojen kerääminen',
    },
    CasePhase.strategy: {
      'en': 'Strategy',
      'et': 'Strateegia',
      'ru': 'Стратегия',
      'fi': 'Strategia',
    },
    CasePhase.draft: {
      'en': 'Draft',
      'et': 'Mustand',
      'ru': 'Черновик',
      'fi': 'Luonnos',
    },
    CasePhase.wait: {
      'en': 'Waiting',
      'et': 'Ootel',
      'ru': 'Ожидание',
      'fi': 'Odotetaan',
    },
    CasePhase.closed: {
      'en': 'Closed',
      'et': 'Suletud',
      'ru': 'Закрыто',
      'fi': 'Suljettu',
    },
  };

  /// Resolve the localised label for [phase]. Falls back to English on
  /// unknown locales. Public so the active-case chip can render the
  /// suffix without instantiating a full PhaseBadge.
  static String labelFor(CasePhase phase, {String? locale}) {
    final table = _labels[phase] ?? const <String, String>{};
    if (locale != null && table.containsKey(locale)) return table[locale]!;
    return table['en'] ?? phase.name;
  }

  // ── Visual treatment ──────────────────────────────────────────────

  Color _bgColor() {
    switch (phase) {
      case CasePhase.intake:
        return AppColors.accent.withValues(alpha: 0.10);
      case CasePhase.strategy:
        return AppColors.accent.withValues(alpha: 0.18);
      case CasePhase.draft:
        return AppColors.warning.withValues(alpha: 0.18);
      case CasePhase.wait:
        return AppColors.surface;
      case CasePhase.closed:
        return AppColors.border.withValues(alpha: 0.40);
    }
  }

  Color _fgColor() {
    switch (phase) {
      case CasePhase.intake:
      case CasePhase.strategy:
        return AppColors.accentDark;
      case CasePhase.draft:
        return AppColors.warning;
      case CasePhase.wait:
        return AppColors.textSecondary;
      case CasePhase.closed:
        return AppColors.textSecondary;
    }
  }

  IconData _icon() {
    switch (phase) {
      case CasePhase.intake:
        return Icons.fact_check_outlined;
      case CasePhase.strategy:
        return Icons.lightbulb_outline;
      case CasePhase.draft:
        return Icons.edit_note;
      case CasePhase.wait:
        return Icons.hourglass_empty;
      case CasePhase.closed:
        return Icons.archive_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = labelFor(phase, locale: locale);
    final fg = _fgColor();
    final bg = _bgColor();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : AppSpacing.sm,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!compact) ...[
            Icon(_icon(), size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 10.5 : 11.5,
              fontWeight: FontWeight.w600,
              color: fg,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
