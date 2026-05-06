// =====================================================================
// PhaseIndicator — Phase 2 Pkg 5
//
// A composite "row" widget that renders the case-phase badge plus the
// "entered N days ago" suffix and an optional manual-override dropdown.
//
// Reusable across:
//   * Case detail screen header (case_detail_screen.dart)
//   * Workspace Overview tab top row (Pkg 4 — consumed when ready)
//   * Cases list expanded row (future)
//
// This widget is dumb chrome — it does NOT call CasePhaseService
// itself. The parent owns the `onOverride` callback and decides
// whether to surface the dropdown (e.g. hide it on Cases list rows
// where there's no room).
//
// Localised entry-time copy lives inline (en/ru/et/fi); other locales
// fall back to English. The CasePhase enum is small and stable so
// inlining is cheap and avoids l10n regen across all 17 locales.
// =====================================================================

import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../models/case_phase.dart';
import 'phase_badge.dart';

class PhaseIndicator extends StatelessWidget {
  const PhaseIndicator({
    super.key,
    required this.phase,
    this.phaseEnteredAt,
    this.locale,
    this.onOverride,
    this.dense = false,
  });

  final CasePhase phase;
  final DateTime? phaseEnteredAt;
  final String? locale;

  /// When non-null, an overflow menu is rendered on the trailing edge
  /// that lets the user manually transition to any other phase. The
  /// callback is invoked with the chosen target phase. The menu is
  /// suppressed entirely when [onOverride] is null — the indicator
  /// becomes read-only chrome.
  final ValueChanged<CasePhase>? onOverride;

  /// Compact vertical density — used inside lists / table rows.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final entered = _enteredCopy();
    final showOverride = onOverride != null;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: dense ? 4 : AppSpacing.xs,
      ),
      child: Row(
        children: [
          PhaseBadge(phase: phase, locale: locale),
          if (entered != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                entered,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          if (showOverride) ...[
            const Spacer(),
            _OverrideMenu(
              currentPhase: phase,
              locale: locale,
              onSelected: onOverride!,
            ),
          ],
        ],
      ),
    );
  }

  /// Build the localised "entered N days/hours/minutes ago" string,
  /// or null if [phaseEnteredAt] is null. Past timestamps only — for
  /// future timestamps (clock skew) we suppress the suffix instead of
  /// printing a negative interval.
  String? _enteredCopy() {
    final ts = phaseEnteredAt;
    if (ts == null) return null;
    final diff = DateTime.now().difference(ts);
    if (diff.isNegative) return null;
    final lang = locale ?? 'en';
    final unit = _pickUnit(diff, lang);
    return unit;
  }

  String _pickUnit(Duration d, String lang) {
    final mins = d.inMinutes;
    final hrs = d.inHours;
    final days = d.inDays;
    if (days >= 1) return _enteredFormatters[lang]?.days(days) ?? _enteredFormatters['en']!.days(days);
    if (hrs >= 1) return _enteredFormatters[lang]?.hours(hrs) ?? _enteredFormatters['en']!.hours(hrs);
    if (mins >= 1) return _enteredFormatters[lang]?.minutes(mins) ?? _enteredFormatters['en']!.minutes(mins);
    return _enteredFormatters[lang]?.justNow() ?? _enteredFormatters['en']!.justNow();
  }

  static const Map<String, _EnteredFormatter> _enteredFormatters = {
    'en': _EnteredFormatter(
      _enteredEnDays,
      _enteredEnHours,
      _enteredEnMinutes,
      _enteredEnNow,
    ),
    'et': _EnteredFormatter(
      _enteredEtDays,
      _enteredEtHours,
      _enteredEtMinutes,
      _enteredEtNow,
    ),
    'ru': _EnteredFormatter(
      _enteredRuDays,
      _enteredRuHours,
      _enteredRuMinutes,
      _enteredRuNow,
    ),
    'fi': _EnteredFormatter(
      _enteredFiDays,
      _enteredFiHours,
      _enteredFiMinutes,
      _enteredFiNow,
    ),
  };
}

// ── Localised "entered X ago" formatters ────────────────────────────

typedef _PluralFn = String Function(int n);
typedef _NowFn = String Function();

class _EnteredFormatter {
  const _EnteredFormatter(this.days, this.hours, this.minutes, this.justNow);
  final _PluralFn days;
  final _PluralFn hours;
  final _PluralFn minutes;
  final _NowFn justNow;
}

String _enteredEnDays(int n) => 'entered $n day${n == 1 ? '' : 's'} ago';
String _enteredEnHours(int n) => 'entered $n hour${n == 1 ? '' : 's'} ago';
String _enteredEnMinutes(int n) => 'entered $n min${n == 1 ? '' : 's'} ago';
String _enteredEnNow() => 'entered just now';

String _enteredEtDays(int n) => 'sisestatud $n päeva tagasi';
String _enteredEtHours(int n) => 'sisestatud $n tunni tagasi';
String _enteredEtMinutes(int n) => 'sisestatud $n minuti tagasi';
String _enteredEtNow() => 'just sisestatud';

// Russian grammar-aware plurals for "день / часа / минут".
String _enteredRuDays(int n) {
  final form = _ruPlural(n, 'день', 'дня', 'дней');
  return 'на этой стадии $n $form';
}

String _enteredRuHours(int n) {
  final form = _ruPlural(n, 'час', 'часа', 'часов');
  return 'на этой стадии $n $form';
}

String _enteredRuMinutes(int n) {
  final form = _ruPlural(n, 'минуту', 'минуты', 'минут');
  return 'на этой стадии $n $form';
}

String _enteredRuNow() => 'только что перешли';

String _ruPlural(int n, String one, String few, String many) {
  final mod10 = n % 10;
  final mod100 = n % 100;
  if (mod10 == 1 && mod100 != 11) return one;
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return few;
  return many;
}

// Finnish — partitive case for time durations after a number.
String _enteredFiDays(int n) => 'siirretty $n päivää sitten';
String _enteredFiHours(int n) => 'siirretty $n tuntia sitten';
String _enteredFiMinutes(int n) => 'siirretty $n minuuttia sitten';
String _enteredFiNow() => 'juuri siirretty';

// ── Override menu — small popup picker ──────────────────────────────

class _OverrideMenu extends StatelessWidget {
  const _OverrideMenu({
    required this.currentPhase,
    required this.locale,
    required this.onSelected,
  });

  final CasePhase currentPhase;
  final String? locale;
  final ValueChanged<CasePhase> onSelected;

  static const List<CasePhase> _allPhases = [
    CasePhase.intake,
    CasePhase.strategy,
    CasePhase.draft,
    CasePhase.wait,
    CasePhase.closed,
  ];

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<CasePhase>(
      tooltip: _tooltipFor(locale),
      icon: const Icon(
        Icons.more_horiz,
        size: 18,
        color: AppColors.textSecondary,
      ),
      padding: EdgeInsets.zero,
      onSelected: onSelected,
      itemBuilder: (ctx) {
        return _allPhases.where((p) => p != currentPhase).map((p) {
          return PopupMenuItem<CasePhase>(
            value: p,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PhaseBadge(phase: p, locale: locale, compact: true),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    _overrideLabelFor(p, locale),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(growable: false);
      },
    );
  }

  static String _tooltipFor(String? lang) {
    switch (lang) {
      case 'et':
        return 'Muuda etappi';
      case 'ru':
        return 'Изменить этап';
      case 'fi':
        return 'Vaihda vaihetta';
      default:
        return 'Change phase';
    }
  }

  static String _overrideLabelFor(CasePhase p, String? lang) {
    final label = PhaseBadge.labelFor(p, locale: lang);
    switch (lang) {
      case 'et':
        return 'Märgi: $label';
      case 'ru':
        return 'Перевести: $label';
      case 'fi':
        return 'Siirrä: $label';
      default:
        return 'Mark as: $label';
    }
  }
}
