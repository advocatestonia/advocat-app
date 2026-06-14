// =============================================================================
// doc_search_result_tile.dart — one semantic-search hit, with highlight.
// =============================================================================

import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../services/doc_search_service.dart';

/// Renders a single [DocSearchHit]: document title + matched snippet with the
/// best-matching phrase highlighted, plus a similarity badge. Tapping invokes
/// [onTap] (the screen wires this to a deep-link into the source document).
class DocSearchResultTile extends StatelessWidget {
  const DocSearchResultTile({
    super.key,
    required this.hit,
    this.onTap,
  });

  final DocSearchHit hit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = (hit.docTitle != null && hit.docTitle!.trim().isNotEmpty)
        ? hit.docTitle!
        : l10n.docSearchUntitled;

    final isCase = hit.sourceKind == 'case_document';
    final kindLabel = isCase ? l10n.docSearchKindCase : l10n.docSearchKindVault;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isCase ? Icons.folder_outlined : Icons.lock_outline,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _SimilarityBadge(similarity: hit.similarity),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                kindLabel,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 8),
              _HighlightedSnippet(hit: hit),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders [DocSearchHit.snippet] with the [highlightStart..highlightEnd]
/// span emphasised. Falls back to plain text when there is no valid highlight.
class _HighlightedSnippet extends StatelessWidget {
  const _HighlightedSnippet({required this.hit});

  final DocSearchHit hit;

  @override
  Widget build(BuildContext context) {
    const baseStyle = TextStyle(
      fontSize: 13,
      height: 1.4,
      color: AppColors.textSecondary,
    );

    if (!hit.hasHighlight) {
      return Text(hit.snippet, style: baseStyle);
    }

    final start = hit.highlightStart!;
    final end = hit.highlightEnd!;
    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: hit.snippet.substring(0, start)),
          TextSpan(
            text: hit.snippet.substring(start, end),
            style: const TextStyle(
              backgroundColor: Color(0x33F59E0B),
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          TextSpan(text: hit.snippet.substring(end)),
        ],
      ),
    );
  }
}

class _SimilarityBadge extends StatelessWidget {
  const _SimilarityBadge({required this.similarity});

  final double similarity;

  @override
  Widget build(BuildContext context) {
    final pct = (similarity * 100).clamp(0, 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$pct%',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.accentDark,
        ),
      ),
    );
  }
}
