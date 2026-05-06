// =============================================================================
// planner_trail.dart — Phase 2 Pkg 6 Reasoning Trail extension.
// =============================================================================
//
// Renders the planner sub-questions, counter-arguments and critique flag
// for a turn that ran the three-pass legal reasoning loop. Sibling of
// `reasoning_trail.dart` — that one shows live streaming progress; this
// one shows the post-loop trace once the answer has landed.
//
// Visual contract (per spec):
//   • Card under the assistant message, accent border, surface bg.
//   • Sections: "Plan" (sub-questions + counter-args), "Critique"
//     (material_gap + issues), "Regenerated once" badge when applicable.
//   • Tap to expand/collapse each section.
//   • Renders empty list as «no items» so the user sees the loop ran
//     even if a section was empty.
// =============================================================================

import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../services/legal_planner.dart';

/// Plan + critique payload as returned by the `planner_trace(uuid)` RPC,
/// shaped into a Dart object for the UI. Field set is a strict subset of
/// `chat_planner_traces` columns so the widget contract doesn't fan out
/// every time we add a column.
class PlannerTraceData {
  const PlannerTraceData({
    required this.subQuestions,
    required this.counterArgs,
    required this.evidenceGaps,
    required this.materialGap,
    required this.critiqueIssues,
    required this.regeneratedOnce,
    required this.summary,
  });

  factory PlannerTraceData.fromRpcRow(Map<String, dynamic> row) {
    final plan = (row['plan'] as Map<String, dynamic>?) ?? const {};
    final critique = (row['critique'] as Map<String, dynamic>?) ?? const {};
    return PlannerTraceData(
      subQuestions: (plan['sub_questions'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      counterArgs: (plan['counter_args'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      evidenceGaps: (plan['evidence_gaps'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      materialGap: critique['material_gap'] as bool? ?? false,
      critiqueIssues: (critique['issues'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      regeneratedOnce: row['regenerated_once'] as bool? ?? false,
      summary: PlannerSummary(
        regeneratedOnce: row['regenerated_once'] as bool? ?? false,
        latencyMs: row['latency_ms'] as int? ?? 0,
        costCents: row['cost_cents'] as int? ?? 0,
      ),
    );
  }

  final List<String> subQuestions;
  final List<String> counterArgs;
  final List<String> evidenceGaps;
  final bool materialGap;
  final List<String> critiqueIssues;
  final bool regeneratedOnce;
  final PlannerSummary summary;
}

/// Renders the planner trace under an assistant message.
///
/// Construction: pass a [PlannerTraceData] built from the augmented
/// `claude-proxy` JSON or from `planner_trace(uuid)` RPC. The widget is
/// stateless beyond the per-section expand toggle.
class PlannerTrail extends StatefulWidget {
  const PlannerTrail({
    super.key,
    required this.data,
  });

  final PlannerTraceData data;

  @override
  State<PlannerTrail> createState() => _PlannerTrailState();
}

class _PlannerTrailState extends State<PlannerTrail> {
  bool _planExpanded = true;
  bool _critiqueExpanded = true;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final secs = (d.summary.latencyMs / 1000).round();

    return Container(
      key: const ValueKey('planner_trail'),
      margin: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────
          Row(
            children: [
              const Icon(
                Icons.psychology_outlined,
                size: 14,
                color: AppColors.accent,
              ),
              const SizedBox(width: 6),
              Text(
                'Planner · 3 passes${d.regeneratedOnce ? ' + 1 regen' : ''} · ${secs}s',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Plan section ────────────────────────────────────────
          _Section(
            title: 'Plan',
            expanded: _planExpanded,
            onToggle: () =>
                setState(() => _planExpanded = !_planExpanded),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BulletList(
                  label: 'Sub-questions',
                  items: d.subQuestions,
                ),
                if (d.counterArgs.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _BulletList(
                    label: 'Counter-arguments',
                    items: d.counterArgs,
                  ),
                ],
                if (d.evidenceGaps.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _BulletList(
                    label: 'Evidence gaps',
                    items: d.evidenceGaps,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Critique section ────────────────────────────────────
          _Section(
            title: d.materialGap
                ? 'Critique · material gap'
                : 'Critique · clean',
            expanded: _critiqueExpanded,
            onToggle: () => setState(
              () => _critiqueExpanded = !_critiqueExpanded,
            ),
            child: d.critiqueIssues.isEmpty
                ? const Text(
                    'No issues flagged.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  )
                : _BulletList(
                    label: 'Issues',
                    items: d.critiqueIssues,
                  ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  final String title;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onToggle,
          child: Row(
            children: [
              Icon(
                expanded ? Icons.expand_less : Icons.expand_more,
                size: 14,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.only(left: 18, top: 4),
            child: child,
          ),
      ],
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({
    required this.label,
    required this.items,
  });

  final String label;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textTertiary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        if (items.isEmpty)
          const Text(
            '— no items —',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textTertiary,
              fontStyle: FontStyle.italic,
            ),
          )
        else
          ...items.map(
            (i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Text(
                '• $i',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
