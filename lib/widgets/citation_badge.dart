// =====================================================================
// CitationBadge — minimal inline UI for the multi-jurisdiction citation
// extractor.
//
// Status: MOCKUP. The badge is a stateless chip that you drop into a
// chat bubble's rich-text run. Tapping it opens a bottom-sheet drawer
// with the full statutory text snippet.
//
// The extractor itself lives backend-side: it parses assistant replies
// for citation tokens (e.g. "BGB § 433", "Verordnung (EU) 2016/679
// Art 17", "Application 12345/67"), normalises them, and pushes a
// CitationRef payload into the message. The chat bubble renders those
// refs as CitationBadge instances.
//
// Contract the eventual backend MUST honour
// -------------------------------------------------------------------
//   CitationRef = {
//     label:     String,            // human-readable, e.g. "BGB § 433"
//     kind:      CitationKind,      // statute | regulation | echr_app
//     verified:  bool,              // ✓ vs ✗ (corpus hit or not)
//     snippet:   String,            // 1–3 paragraphs of authoritative
//                                   //      text to show in the drawer
//     sourceUri: String?,           // canonical URL (eur-lex,
//                                   //      gesetze-im-internet.de, …)
//   }
// =====================================================================

import 'package:flutter/material.dart';

import '../config/theme.dart';

enum CitationKind {
  /// National statute, e.g. BGB § 433 or OK 25:5.
  statute,

  /// EU regulation or directive, e.g. Verordnung (EU) 2016/679 Art 17.
  euRegulation,

  /// ECtHR application, e.g. Application 12345/67.
  echrApplication,
}

class CitationRef {
  const CitationRef({
    required this.label,
    required this.kind,
    required this.verified,
    required this.snippet,
    this.sourceUri,
  });

  final String label;
  final CitationKind kind;
  final bool verified;
  final String snippet;
  final String? sourceUri;
}

/// Three deterministic mock refs covering each citation kind. Exposed so
/// widget tests and storybook-style demos can share them; the chat
/// screen would normally inject real refs parsed from a message.
const CitationRef mockBgbCitation = CitationRef(
  label: 'BGB § 433',
  kind: CitationKind.statute,
  verified: true,
  snippet:
      '(1) Durch den Kaufvertrag wird der Verkäufer einer Sache verpflichtet, '
      'dem Käufer die Sache zu übergeben und das Eigentum an der Sache zu '
      'verschaffen. (2) Der Käufer ist verpflichtet, dem Verkäufer den '
      'vereinbarten Kaufpreis zu zahlen und die gekaufte Sache abzunehmen.',
  sourceUri: 'https://www.gesetze-im-internet.de/bgb/__433.html',
);

const CitationRef mockGdprArt17Citation = CitationRef(
  label: 'Verordnung (EU) 2016/679 Art 17',
  kind: CitationKind.euRegulation,
  verified: true,
  snippet:
      'Die betroffene Person hat das Recht, von dem Verantwortlichen zu '
      'verlangen, dass sie betreffende personenbezogene Daten unverzüglich '
      'gelöscht werden, und der Verantwortliche ist verpflichtet, '
      'personenbezogene Daten unverzüglich zu löschen, sofern einer der '
      'in Absatz 1 genannten Gründe zutrifft.',
  sourceUri:
      'https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:32016R0679',
);

const CitationRef mockEchrApplicationCitation = CitationRef(
  label: 'Application 12345/67',
  kind: CitationKind.echrApplication,
  verified: true,
  snippet:
      'Mock ECtHR application — full case text would arrive from the HUDOC '
      'corpus and include the procedure, the law, and the operative part.',
  sourceUri: 'https://hudoc.echr.coe.int/?app=12345/67',
);

/// The chip itself. Drop into a chat bubble; tap → drawer.
class CitationBadge extends StatelessWidget {
  const CitationBadge({super.key, required this.ref});
  final CitationRef ref;

  Color _kindColor() {
    switch (ref.kind) {
      case CitationKind.statute:
        return AppColors.primary;
      case CitationKind.euRegulation:
        return AppColors.accent;
      case CitationKind.echrApplication:
        return AppColors.info;
    }
  }

  IconData _kindIcon() {
    switch (ref.kind) {
      case CitationKind.statute:
        return Icons.menu_book_outlined;
      case CitationKind.euRegulation:
        return Icons.flag_outlined;
      case CitationKind.echrApplication:
        return Icons.gavel_outlined;
    }
  }

  void _openDrawer(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => _CitationDrawer(ref: ref),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _kindColor();
    final bg = color.withValues(alpha: 0.10);
    final border = color.withValues(alpha: 0.30);

    return Padding(
      padding: const EdgeInsets.only(right: 6, bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('citation-badge-${ref.label}'),
          onTap: () => _openDrawer(context),
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(color: border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_kindIcon(), size: 12, color: color),
                const SizedBox(width: 4),
                Text(
                  ref.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  ref.verified ? Icons.check_circle : Icons.error_outline,
                  size: 12,
                  color: ref.verified ? AppColors.success : AppColors.warning,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CitationDrawer extends StatelessWidget {
  const _CitationDrawer({required this.ref});
  final CitationRef ref;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: mq.viewInsets.bottom + AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  ref.label,
                  key: const Key('citation-drawer-title'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (ref.verified)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle,
                          size: 12, color: AppColors.success),
                      SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            ref.snippet,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
          if (ref.sourceUri != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const Icon(Icons.link, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    ref.sourceUri!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
