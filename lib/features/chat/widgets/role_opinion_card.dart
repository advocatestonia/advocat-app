// =============================================================================
// role_opinion_card.dart — single expert opinion card inside the consilium UI.
// =============================================================================
//
// Phase 1 Consilium (2026-05-25).
//
// One card per legal-role opinion that streams in from the consilium pipeline.
// Three visual states:
//   * Loading      — only the role roster is known (ConsiliumStart fired),
//                    the RoleOpinion for this role hasn't arrived yet.
//   * Ready        — RoleOpinion received with position + confidence + opinion
//                    + key citation.
//   * Stale        — same as Ready but rendered with reduced opacity once
//                    ConsiliumDone has fired (synthesis is the authoritative
//                    answer; per-role cards become reference material).
//
// Positions and their colors (matches backend role_orchestrator vocabulary):
//   * push           → red    (advocate for aggressive litigation)
//   * settle         → amber  (advise compromise / negotiation)
//   * investigate    → blue   (need more facts before recommending)
//   * out_of_scope   → grey   (italic — role isn't applicable here)
// =============================================================================

import 'package:flutter/material.dart';

import '../../../config/theme.dart';

/// Mutually-exclusive position the role has taken on the case.
///
/// The backend emits these as strings; [RoleOpinionCard.parsePosition] maps
/// unknown values to [unknown] which is rendered neutrally.
enum RolePosition { push, settle, investigate, outOfScope, unknown }

/// Parse a backend position string into the typed enum. Whitespace and case
/// are normalised; unknown strings fall through to [RolePosition.unknown].
RolePosition parseRolePosition(String? raw) {
  switch (raw?.trim().toLowerCase()) {
    case 'push':
      return RolePosition.push;
    case 'settle':
      return RolePosition.settle;
    case 'investigate':
      return RolePosition.investigate;
    case 'out_of_scope':
    case 'oos':
      return RolePosition.outOfScope;
    default:
      return RolePosition.unknown;
  }
}

/// A single role's opinion card. Stateless — all state is computed from the
/// constructor arguments so the parent panel can rebuild from the event list
/// on every SSE frame without losing animation continuity.
class RoleOpinionCard extends StatelessWidget {
  const RoleOpinionCard({
    super.key,
    required this.roleName,
    this.position,
    this.confidence,
    this.opinion,
    this.citation,
    this.isLoading = false,
  });

  /// Human-readable role title — e.g. "Иммиграционный юрист".
  /// The avatar circle uses the first 2 letters (capitalised).
  final String roleName;

  /// Null while loading; non-null once RoleOpinion arrives.
  final RolePosition? position;

  /// 0.0 – 1.0. Null while loading. Values are clamped before rendering.
  final double? confidence;

  /// The role's short reasoning (1-3 sentences). Trimmed with ellipsis.
  final String? opinion;

  /// Short citation string — e.g. "UL § 149" or "Code civil art. 1240".
  /// Rendered in monospace italic when it looks like a statute pin-cite.
  final String? citation;

  /// True before RoleOpinion has arrived for this role. Shows a skeleton.
  final bool isLoading;

  String get _initials {
    final parts = roleName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) {
      final p = parts.first;
      return p.substring(0, p.length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  /// Returns (background tint, foreground colour, label) for the chip.
  ({Color bg, Color fg, String label, bool italic}) _chipStyle() {
    switch (position) {
      case RolePosition.push:
        return (
          bg: AppColors.errorBg,
          fg: AppColors.error,
          label: 'push',
          italic: false,
        );
      case RolePosition.settle:
        return (
          bg: AppColors.warningBg,
          fg: AppColors.warning,
          label: 'settle',
          italic: false,
        );
      case RolePosition.investigate:
        return (
          bg: AppColors.infoBg,
          fg: AppColors.info,
          label: 'investigate',
          italic: false,
        );
      case RolePosition.outOfScope:
        return (
          bg: AppColors.surfaceVariant,
          fg: AppColors.textTertiary,
          label: 'out of scope',
          italic: true,
        );
      case RolePosition.unknown:
      case null:
        return (
          bg: AppColors.surfaceVariant,
          fg: AppColors.textTertiary,
          label: '—',
          italic: true,
        );
    }
  }

  bool get _citationLooksLikeStatute {
    if (citation == null) return false;
    return RegExp(r'(§|art\.|art\s|ch\.|ptk|§§)', caseSensitive: false)
        .hasMatch(citation!);
  }

  @override
  Widget build(BuildContext context) {
    final style = _chipStyle();
    final pct = ((confidence ?? 0).clamp(0.0, 1.0));

    return Container(
      key: ValueKey('role_card_${roleName}_${isLoading ? "loading" : "ready"}'),
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar circle with initials
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.accentTint.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _initials,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      roleName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (!isLoading) const SizedBox(height: 3),
                    if (!isLoading)
                      // Position chip + confidence bar in one row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: style.bg,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                            ),
                            child: Text(
                              style.label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: style.fg,
                                fontStyle: style.italic
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                              ),
                            ),
                          ),
                          if (confidence != null) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  minHeight: 4,
                                  backgroundColor: AppColors.surfaceVariant,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(style.fg),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${(pct * 100).round()}%',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (isLoading) ...[
            const SizedBox(height: AppSpacing.sm),
            const _SkeletonLine(width: double.infinity),
            const SizedBox(height: 4),
            const _SkeletonLine(width: 180),
          ] else ...[
            if (opinion != null && opinion!.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                opinion!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (citation != null && citation!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                citation!,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                  fontStyle: FontStyle.italic,
                  fontFamily: _citationLooksLikeStatute
                      ? 'monospace'
                      : null,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.width});
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 10,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
