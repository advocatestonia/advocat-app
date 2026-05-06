// =============================================================================
// citation_marker_span.dart — Phase 2 Pkg 2 inline marker renderer.
// -----------------------------------------------------------------------------
// Parses `[[ref:ACT:PARAGRAPH(:LANG)?]]` markers out of assistant message
// text and replaces each one with a styled, tappable span. Tap = open
// [CitationDetailSheet] for the matching [Citation] row.
//
// Marker regex source = `kCitationMarkerPattern` in lib/core/citations/marker.dart
// (single point of truth, mirrored verbatim by the Deno verifier).
//
// Visual treatment per design doc §6:
//   * verified  → primary-color underline (subtle, matches body text)
//   * historical → amber underline + small "★" badge "no longer in force"
//   * unverified → red underline + small "?" badge — NEVER hidden
//   * unknown   → neutral underline (forward-compat for new statuses)
//
// The chip is rendered as a `WidgetSpan` wrapping a small inline container
// so it lays out inline with surrounding text and respects line breaks.
// =============================================================================

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme.dart';
import '../../../../core/citations/marker.dart';
import '../../../../l10n/app_localizations.dart';
import '../../citations/citation_model.dart';
import 'citation_detail_sheet.dart';

/// Build a flat list of `InlineSpan`s for [text], replacing every citation
/// marker with a tappable chip.
///
/// [citations] is the per-message verifier output. The function tolerates
/// markers that have NO matching citation row (e.g. malformed marker the
/// verifier dropped) — those render as plain "TLS §88" text without any
/// tap handler.
///
/// [baseStyle] is applied to every plain-text run. The chip itself sets
/// its own font weight + color so it visually pops without being noisy.
List<InlineSpan> buildCitationSpans({
  required BuildContext context,
  required String text,
  required List<Citation> citations,
  required TextStyle baseStyle,
}) {
  if (text.isEmpty) return const [];

  // No markers AND no citations → fast-path: a single TextSpan, no scan.
  // The empty-citations branch is the common case for non-legal turns.
  if (!text.contains('[[ref:') && citations.isEmpty) {
    return [TextSpan(text: text, style: baseStyle)];
  }

  // Index citations by `lower(act):paragraph` so each marker hit is an
  // O(1) lookup. Same key shape as the server-side verifier.
  final byKey = <String, Citation>{
    for (final c in citations) c.key: c,
  };

  final regex = RegExp(kCitationMarkerPattern);
  final spans = <InlineSpan>[];
  int cursor = 0;

  for (final match in regex.allMatches(text)) {
    if (match.start > cursor) {
      spans.add(
        TextSpan(text: text.substring(cursor, match.start), style: baseStyle),
      );
    }
    final actSlug = (match.group(1) ?? '').toLowerCase();
    final paragraph = match.group(2) ?? '';
    final key = '$actSlug:$paragraph';
    final citation = byKey[key];

    spans.add(
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: _CitationChip(
          actSlug: actSlug,
          paragraph: paragraph,
          citation: citation,
          baseFontSize: baseStyle.fontSize ?? 14.0,
        ),
      ),
    );
    cursor = match.end;
  }

  if (cursor < text.length) {
    spans.add(TextSpan(text: text.substring(cursor), style: baseStyle));
  }

  return spans;
}

/// Inline chip rendered for one citation marker hit.
class _CitationChip extends StatelessWidget {
  const _CitationChip({
    required this.actSlug,
    required this.paragraph,
    required this.citation,
    required this.baseFontSize,
  });

  final String actSlug;
  final String paragraph;
  final Citation? citation;
  final double baseFontSize;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = citation?.status ?? CitationStatus.unverified;
    final colors = _colorsFor(status);
    final label = '${actSlug.toUpperCase()} §$paragraph';

    final tooltipMessage = _tooltipFor(status, l10n);

    final chip = Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: colors.border, width: 0.6),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            if (status == CitationStatus.unverified)
              TextSpan(
                text: '? ',
                style: TextStyle(
                  fontSize: baseFontSize - 2,
                  color: colors.foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            if (status == CitationStatus.historical)
              TextSpan(
                text: '\u2605 ',
                style: TextStyle(
                  fontSize: baseFontSize - 2,
                  color: colors.foreground,
                ),
              ),
            TextSpan(
              text: label,
              style: TextStyle(
                fontSize: baseFontSize - 1,
                color: colors.foreground,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );

    final wrapped = Tooltip(
      message: tooltipMessage,
      preferBelow: false,
      child: chip,
    );

    // Plain "TLS §88" without a tap handler when there's no matching
    // citation row — the bottom sheet wouldn't have anything useful to
    // show. We still render it (markdown-safe — never silently delete).
    final c = citation;
    if (c == null) return wrapped;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => CitationDetailSheet.show(context, c),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: wrapped,
      ),
    );
  }

  String _tooltipFor(CitationStatus status, AppLocalizations? l10n) {
    if (l10n == null) return ''; // Localizations not loaded — show empty.
    switch (status) {
      case CitationStatus.verified:
        return l10n.citationStatusVerifiedTooltip;
      case CitationStatus.historical:
        return l10n.citationStatusHistoricalTooltip;
      case CitationStatus.unverified:
        return l10n.citationStatusUnverifiedTooltip;
      case CitationStatus.unknown:
        return '';
    }
  }

  _CitationChipColors _colorsFor(CitationStatus status) {
    switch (status) {
      case CitationStatus.verified:
        return const _CitationChipColors(
          background: Color(0x1A0D9488), // primary teal @ 10%
          border: Color(0x4D0D9488),
          foreground: Color(0xFF0D9488),
        );
      case CitationStatus.historical:
        return _CitationChipColors(
          background: AppColors.warning.withValues(alpha: 0.10),
          border: AppColors.warning.withValues(alpha: 0.30),
          foreground: AppColors.warning,
        );
      case CitationStatus.unverified:
        return _CitationChipColors(
          background: AppColors.error.withValues(alpha: 0.10),
          border: AppColors.error.withValues(alpha: 0.30),
          foreground: AppColors.error,
        );
      case CitationStatus.unknown:
        return _CitationChipColors(
          background: AppColors.textTertiary.withValues(alpha: 0.10),
          border: AppColors.textTertiary.withValues(alpha: 0.30),
          foreground: AppColors.textTertiary,
        );
    }
  }
}

/// Small colour pack so [_CitationChip] doesn't grow N more parameters.
class _CitationChipColors {
  const _CitationChipColors({
    required this.background,
    required this.border,
    required this.foreground,
  });
  final Color background;
  final Color border;
  final Color foreground;
}

/// TextSpan-only convenience for callers that pass markers through a path
/// where `WidgetSpan` is unwanted (e.g. SelectableText copy plumbing). Used
/// by tests only — production renderer uses [buildCitationSpans] above.
TextSpan textOnlyMarkerSpan({
  required String text,
  required Citation? citation,
  required TextStyle baseStyle,
  required GestureRecognizer? recognizer,
}) {
  final actSlug = citation?.actSlug ?? '';
  final paragraph = citation?.paragraph ?? '';
  final label = '${actSlug.toUpperCase()} §$paragraph';
  return TextSpan(
    text: label,
    style: baseStyle.copyWith(
      decoration: TextDecoration.underline,
      decorationStyle: TextDecorationStyle.dotted,
    ),
    recognizer: recognizer,
  );
}
