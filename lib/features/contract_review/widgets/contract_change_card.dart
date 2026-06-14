// =============================================================================
// contract_change_card.dart — one clause-level delta in a contract redline.
// =============================================================================
//
// Renders a single change returned by the contract-compare edge function:
//   - a coloured left rail + chip encoding the DIRECTION (favorable / adverse
//     / neutral) so a reviewer can scan the redline risk at a glance,
//   - the clause heading + plain-language explanation,
//   - optional before/after verbatim quotes in an inline diff style (old =
//     struck-through red tint, new = green tint).
//
// Pure presentational widget — it takes a ContractChangeView value object and
// has no Riverpod / network dependencies, so it unit-tests in isolation.
// =============================================================================

import 'package:flutter/material.dart';

import '../../../config/theme.dart';

/// Direction of a change from the reader's perspective. Mirrors the edge
/// function's `ChangeDirection`.
enum ContractChangeDirection { favorable, adverse, neutral }

/// Structural edit kind. Mirrors the edge function's `ChangeKind`.
enum ContractChangeKind { added, removed, modified }

/// Immutable view model for one clause-level change. Built from the
/// edge-function JSON in contract_compare_screen.dart.
class ContractChangeView {
  const ContractChangeView({
    required this.clause,
    required this.kind,
    required this.direction,
    required this.severity,
    required this.explanation,
    this.beforeQuote,
    this.afterQuote,
  });

  final String clause;
  final ContractChangeKind kind;
  final ContractChangeDirection direction;

  /// One of: critical, high, medium, low, info, good (free-form from server;
  /// shown verbatim as a small badge, lower-cased).
  final String severity;
  final String explanation;
  final String? beforeQuote;
  final String? afterQuote;

  static ContractChangeDirection directionFromString(String? s) {
    switch (s) {
      case 'favorable':
        return ContractChangeDirection.favorable;
      case 'adverse':
        return ContractChangeDirection.adverse;
      default:
        return ContractChangeDirection.neutral;
    }
  }

  static ContractChangeKind kindFromString(String? s) {
    switch (s) {
      case 'added':
        return ContractChangeKind.added;
      case 'removed':
        return ContractChangeKind.removed;
      default:
        return ContractChangeKind.modified;
    }
  }

  /// Build from a single `changes[]` entry of the edge-function body.
  factory ContractChangeView.fromJson(Map<String, dynamic> json) {
    return ContractChangeView(
      clause: (json['clause'] as String?)?.trim() ?? '',
      kind: kindFromString(json['kind'] as String?),
      direction: directionFromString(json['direction'] as String?),
      severity: (json['severity'] as String?)?.trim().toLowerCase() ?? 'info',
      explanation: (json['explanation'] as String?)?.trim() ?? '',
      beforeQuote: _nonEmpty(json['before_quote'] as String?),
      afterQuote: _nonEmpty(json['after_quote'] as String?),
    );
  }

  static String? _nonEmpty(String? s) {
    if (s == null) return null;
    final t = s.trim();
    return t.isEmpty ? null : t;
  }
}

/// Resolve the accent colour for a direction.
Color contractChangeDirectionColor(ContractChangeDirection d) {
  switch (d) {
    case ContractChangeDirection.favorable:
      return AppColors.success;
    case ContractChangeDirection.adverse:
      return AppColors.error;
    case ContractChangeDirection.neutral:
      return AppColors.textSecondary;
  }
}

class ContractChangeCard extends StatelessWidget {
  const ContractChangeCard({
    super.key,
    required this.change,
    this.favorableLabel = 'Favorable',
    this.adverseLabel = 'Adverse',
    this.neutralLabel = 'Neutral',
    this.beforeLabel = 'Before',
    this.afterLabel = 'After',
  });

  final ContractChangeView change;
  final String favorableLabel;
  final String adverseLabel;
  final String neutralLabel;
  final String beforeLabel;
  final String afterLabel;

  String _directionLabel() {
    switch (change.direction) {
      case ContractChangeDirection.favorable:
        return favorableLabel;
      case ContractChangeDirection.adverse:
        return adverseLabel;
      case ContractChangeDirection.neutral:
        return neutralLabel;
    }
  }

  IconData _directionIcon() {
    switch (change.direction) {
      case ContractChangeDirection.favorable:
        return Icons.trending_up_rounded;
      case ContractChangeDirection.adverse:
        return Icons.trending_down_rounded;
      case ContractChangeDirection.neutral:
        return Icons.trending_flat_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = contractChangeDirectionColor(change.direction);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Coloured direction rail.
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.md),
                  bottomLeft: Radius.circular(AppRadius.md),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row: direction chip + severity badge.
                    Row(
                      children: [
                        _Chip(
                          icon: _directionIcon(),
                          label: _directionLabel(),
                          color: color,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _SeverityBadge(severity: change.severity),
                        const Spacer(),
                        _KindBadge(kind: change.kind),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Clause heading.
                    if (change.clause.isNotEmpty)
                      Text(
                        change.clause,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    if (change.explanation.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        change.explanation,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          height: 1.45,
                        ),
                      ),
                    ],
                    // Inline before/after diff.
                    if (change.beforeQuote != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _QuoteLine(
                        label: beforeLabel,
                        text: change.beforeQuote!,
                        color: AppColors.error,
                        strikethrough: true,
                      ),
                    ],
                    if (change.afterQuote != null) ...[
                      const SizedBox(height: 4),
                      _QuoteLine(
                        label: afterLabel,
                        text: change.afterQuote!,
                        color: AppColors.success,
                        strikethrough: false,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  const _SeverityBadge({required this.severity});
  final String severity;

  @override
  Widget build(BuildContext context) {
    if (severity.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        severity,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _KindBadge extends StatelessWidget {
  const _KindBadge({required this.kind});
  final ContractChangeKind kind;

  String get _glyph {
    switch (kind) {
      case ContractChangeKind.added:
        return '+';
      case ContractChangeKind.removed:
        return '−';
      case ContractChangeKind.modified:
        return '~';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _glyph,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _QuoteLine extends StatelessWidget {
  const _QuoteLine({
    required this.label,
    required this.text,
    required this.color,
    required this.strikethrough,
  });

  final String label;
  final String text;
  final Color color;
  final bool strikethrough;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.textPrimary,
              decoration:
                  strikethrough ? TextDecoration.lineThrough : TextDecoration.none,
              decorationColor: color,
            ),
          ),
        ],
      ),
    );
  }
}
