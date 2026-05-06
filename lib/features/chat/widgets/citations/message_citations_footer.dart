// =============================================================================
// message_citations_footer.dart — Phase 2 Pkg 2 per-message footer.
// -----------------------------------------------------------------------------
// Spec: docs/architecture/phase2-pkg2-citations.md §6 widget #3.
//
// Collapsible footer rendered below an assistant bubble. Default: collapsed,
// shows summary "3 citations · 2 verified · 1 unverified". Tap → expand
// list of all citations; tap on a row → open [CitationDetailSheet].
//
// Empty list + assistant message that LOOKS legal-ish (contains §) → small
// "no grounded citations" warning so the user has a transparency signal.
// =============================================================================

import 'package:flutter/material.dart';

import '../../../../config/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../citations/citation_model.dart';
import 'citation_detail_sheet.dart';

class MessageCitationsFooter extends StatefulWidget {
  const MessageCitationsFooter({
    super.key,
    required this.citations,
    this.legalContent = false,
  });

  /// All citations attached to one assistant message.
  final List<Citation> citations;

  /// Whether the surrounding message looked legal-ish (contained `§` or
  /// matched the legal-stem heuristic in [looksLegalish]). Drives the
  /// "no grounded citations" warning when [citations] is empty.
  final bool legalContent;

  @override
  State<MessageCitationsFooter> createState() => _MessageCitationsFooterState();
}

class _MessageCitationsFooterState extends State<MessageCitationsFooter> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (widget.citations.isEmpty) {
      if (!widget.legalContent) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 12,
              color: AppColors.warning,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                l10n.citationFooterNoneWarning,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.warning,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final total = widget.citations.length;
    final verified = widget.citations
        .where((c) => c.status == CitationStatus.verified)
        .length;
    final unverified = widget.citations
        .where((c) => c.status == CitationStatus.unverified)
        .length;
    final historical = widget.citations
        .where((c) => c.status == CitationStatus.historical)
        .length;
    final summaryParts = <String>[
      l10n.citationFooterSummaryTotal(total),
      if (verified > 0) l10n.citationFooterSummaryVerified(verified),
      if (unverified > 0) l10n.citationFooterSummaryUnverified(unverified),
      if (historical > 0) l10n.citationFooterSummaryHistorical(historical),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            key: const Key('citation_footer_toggle'),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.keyboard_arrow_right_rounded,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    summaryParts.join(' · '),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.citations
                    .map((c) => _CitationRow(citation: c))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _CitationRow extends StatelessWidget {
  const _CitationRow({required this.citation});

  final Citation citation;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(citation.status);
    final label = '${citation.actSlug.toUpperCase()} §${citation.paragraph}';
    final actName = citation.actName;

    return InkWell(
      onTap: () => CitationDetailSheet.show(context, citation),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (actName != null && actName.isNotEmpty)
                      TextSpan(
                        text: ' — $actName',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(CitationStatus status) {
    switch (status) {
      case CitationStatus.verified:
        return AppColors.success;
      case CitationStatus.historical:
        return AppColors.warning;
      case CitationStatus.unverified:
        return AppColors.error;
      case CitationStatus.unknown:
        return AppColors.textTertiary;
    }
  }
}

/// Cheap heuristic — does the assistant text look legal-ish enough that we
/// should warn about missing citations?
///
/// Currently: contains `§` OR contains a known legal stem from a small list.
/// Conservative on purpose — false positives flood the chat with warnings.
bool looksLegalish(String text) {
  if (text.isEmpty) return false;
  if (text.contains('§')) return true;
  // Single source of legal stems — any language. Keep narrow to avoid
  // flagging "статья журнала" or "article in the magazine" false-positives.
  for (final stem in _legalishStems) {
    if (text.contains(stem)) return true;
  }
  return false;
}

const _legalishStems = <String>[
  // Estonian / Finnish / Russian / English legal stems.
  // Each must be specific enough to NOT match casual prose.
  'KarS',
  'KrMS',
  'HMS',
  'TLS',
  'VÕS',
  'TsÜS',
  'Rikoslaki',
  'Hallintolaki',
  'УК РФ',
  'ГК РФ',
  ' §',
];
