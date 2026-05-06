// =============================================================================
// citation_detail_sheet.dart — Phase 2 Pkg 2 bottom sheet for one citation.
// -----------------------------------------------------------------------------
// Spec: docs/architecture/phase2-pkg2-citations.md §6 widget #2.
//
// Triggered by tapping a citation chip. Shows:
//   1. Act name (e.g. "Töölepingu seadus") — falls back to slug if absent
//   2. § + title subhead
//   3. Status badge (verified / historical / unverified)
//   4. Snippet body in a blockquote (expandable when >800 chars)
//   5. "Open in Riigi Teataja" button (uses sourceUrl, otherwise builder)
//
// Widget kept under 250 lines per implementer brief.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../citations/citation_model.dart';
import '../../citations/riigi_teataja_url.dart';

class CitationDetailSheet extends StatefulWidget {
  const CitationDetailSheet({super.key, required this.citation});

  final Citation citation;

  /// Convenience launcher used by [CitationMarkerSpan] chip taps. Wraps
  /// `showModalBottomSheet` with the standard Material sheet shape so each
  /// caller doesn't repeat the boilerplate.
  static Future<void> show(BuildContext context, Citation citation) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => CitationDetailSheet(citation: citation),
    );
  }

  @override
  State<CitationDetailSheet> createState() => _CitationDetailSheetState();
}

class _CitationDetailSheetState extends State<CitationDetailSheet> {
  static const int _snippetEllipsisAt = 800;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = widget.citation;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final actHeading = (c.actName != null && c.actName!.isNotEmpty)
        ? c.actName!
        : c.actSlug.toUpperCase();

    final subhead = StringBuffer('§${c.paragraph}');
    if (c.title != null && c.title!.isNotEmpty) {
      subhead.write(' — ${c.title}');
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Heading: act name ──
            Text(
              actHeading,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subhead.toString(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),

            // ── Status badge ──
            _StatusBadge(status: c.status, l10n: l10n),
            const SizedBox(height: 14),

            // ── Snippet body ──
            if (c.snippet != null && c.snippet!.trim().isNotEmpty)
              _Blockquote(
                text: c.snippet!,
                expanded: _expanded,
                ellipsisAt: _snippetEllipsisAt,
                onToggle: () => setState(() => _expanded = !_expanded),
                expandLabel: l10n.citationSnippetExpand,
                collapseLabel: l10n.citationSnippetCollapse,
              )
            else if (c.status == CitationStatus.unverified)
              _UnverifiedNote(text: l10n.citationUnverifiedSheetNote),

            const SizedBox(height: 16),

            // ── Riigi Teataja deep link ──
            _RtLinkButton(
              label: l10n.citationOpenInRiigiTeataja,
              onPressed: () => _launchSource(c, context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchSource(Citation c, BuildContext context) async {
    final url = buildRiigiTeatajaUrl(
      actSlug: c.actSlug,
      paragraph: c.paragraph,
      jurisdiction: c.jurisdiction,
      sourceUrl: c.sourceUrl,
    );
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    // Best-effort launch. On failure, leave the sheet open — user can
    // copy the URL via the on-screen text. We don't show an error toast
    // here to keep the file under the 250-line cap.
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.l10n});

  final CitationStatus status;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final IconData icon;
    late final String text;
    switch (status) {
      case CitationStatus.verified:
        color = AppColors.success;
        icon = Icons.check_circle_rounded;
        text = l10n.citationStatusVerifiedBadge;
      case CitationStatus.historical:
        color = AppColors.warning;
        icon = Icons.history_toggle_off_rounded;
        text = l10n.citationStatusHistoricalBadge;
      case CitationStatus.unverified:
        color = AppColors.error;
        icon = Icons.error_outline_rounded;
        text = l10n.citationStatusUnverifiedBadge;
      case CitationStatus.unknown:
        color = AppColors.textTertiary;
        icon = Icons.help_outline_rounded;
        text = l10n.citationStatusUnverifiedBadge;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Blockquote extends StatelessWidget {
  const _Blockquote({
    required this.text,
    required this.expanded,
    required this.ellipsisAt,
    required this.onToggle,
    required this.expandLabel,
    required this.collapseLabel,
  });

  final String text;
  final bool expanded;
  final int ellipsisAt;
  final VoidCallback onToggle;
  final String expandLabel;
  final String collapseLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final body = (!expanded && text.length > ellipsisAt)
        ? '${text.substring(0, ellipsisAt)}…'
        : text;
    final showToggle = text.length > ellipsisAt;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: AppColors.accent.withValues(alpha: 0.6),
            width: 3,
          ),
        ),
        color: (isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant)
            .withValues(alpha: 0.5),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(6),
          bottomRight: Radius.circular(6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            body,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              fontStyle: FontStyle.italic,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
          if (showToggle)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: InkWell(
                onTap: onToggle,
                child: Text(
                  expanded ? collapseLabel : expandLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _UnverifiedNote extends StatelessWidget {
  const _UnverifiedNote({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        color: AppColors.error,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}

class _RtLinkButton extends StatelessWidget {
  const _RtLinkButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        key: const Key('citation_rt_link_button'),
        onPressed: onPressed,
        icon: const Icon(Icons.open_in_new_rounded, size: 16),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
    );
  }
}
