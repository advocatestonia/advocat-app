// =============================================================================
// disagreement_banner.dart — surfaces conflicts between role opinions.
// =============================================================================
//
// Phase 1 Consilium (2026-05-25).
//
// When 2+ role opinions disagree the user needs to know — both because that
// is genuinely useful information ("two senior lawyers see this differently")
// and because the eventual synthesis will look like a compromise without the
// banner explaining why.
//
// Disagreement is detected by the parent consilium panel (it has the full
// event list); this widget is a dumb renderer that takes the already-derived
// disagreement summary.
// =============================================================================

import 'package:flutter/material.dart';

import '../../../config/theme.dart';

/// One disagreement edge between two roles.
class DisagreementEntry {
  const DisagreementEntry({
    required this.roleA,
    required this.positionA,
    required this.confidenceA,
    required this.roleB,
    required this.positionB,
    required this.confidenceB,
  });

  final String roleA;
  final String positionA;
  final double confidenceA;
  final String roleB;
  final String positionB;
  final double confidenceB;

  /// Confidence delta (always positive).
  double get delta => (confidenceA - confidenceB).abs();
}

/// Amber expandable banner. Collapsed shows count of disagreements; expanded
/// lists each pair with their positions and confidences.
class DisagreementBanner extends StatefulWidget {
  const DisagreementBanner({
    super.key,
    required this.entries,
    this.title = '⚠ Эксперты расходятся',
  });

  final List<DisagreementEntry> entries;
  final String title;

  @override
  State<DisagreementBanner> createState() => _DisagreementBannerState();
}

class _DisagreementBannerState extends State<DisagreementBanner> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.entries.isEmpty) return const SizedBox.shrink();

    return Container(
      key: const Key('disagreement_banner'),
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm + 2, vertical: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                    Icon(
                      _expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 18,
                      color: AppColors.warning,
                    ),
                  ],
                ),
                if (_expanded) ...[
                  const SizedBox(height: 6),
                  ...widget.entries.map(_buildEntryRow),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEntryRow(DisagreementEntry e) {
    String fmtPct(double v) => '${(v.clamp(0.0, 1.0) * 100).round()}%';
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        '${e.roleA}: ${e.positionA} ${fmtPct(e.confidenceA)} · '
        '${e.roleB}: ${e.positionB} ${fmtPct(e.confidenceB)}',
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
          height: 1.4,
        ),
      ),
    );
  }
}

/// Detect disagreement edges from a snapshot of role opinions.
///
/// Rule (matches task brief):
///   * Two roles disagree if confidence delta > 0.2, OR
///   * One position is `push` while the other is `settle`.
///
/// Returns at most one edge per (roleA, roleB) pair (lexicographic order
/// so the same disagreement isn't surfaced twice across rebuilds).
List<DisagreementEntry> detectDisagreements(
  List<({String role, String position, double confidence})> opinions,
) {
  final out = <DisagreementEntry>[];
  for (var i = 0; i < opinions.length; i++) {
    for (var j = i + 1; j < opinions.length; j++) {
      final a = opinions[i];
      final b = opinions[j];
      final delta = (a.confidence - b.confidence).abs();
      final pushSettleClash =
          (a.position == 'push' && b.position == 'settle') ||
              (a.position == 'settle' && b.position == 'push');
      if (delta > 0.2 || pushSettleClash) {
        // Stable lexicographic ordering
        final (first, second) =
            a.role.compareTo(b.role) <= 0 ? (a, b) : (b, a);
        out.add(DisagreementEntry(
          roleA: first.role,
          positionA: first.position,
          confidenceA: first.confidence,
          roleB: second.role,
          positionB: second.position,
          confidenceB: second.confidence,
        ));
      }
    }
  }
  return out;
}
