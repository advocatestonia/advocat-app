// inbox_severity.dart
// -----------------------------------------------------------------------------
// Severity enum used by the Inbox UI. Maps 1:1 to the
// email_triage_results.severity check constraint values.
//
// `rank` is the load-bearing field for sorting: lower int = higher urgency,
// so a stable ascending sort puts CRITICAL first. The same ranks are used
// by lib/services/assistant_tools.dart::_listInbox (kept in lockstep).
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../../config/theme.dart';

enum InboxSeverity {
  critical(rank: 0, raw: 'CRITICAL'),
  high(rank: 1, raw: 'HIGH'),
  medium(rank: 2, raw: 'MEDIUM'),
  low(rank: 3, raw: 'LOW');

  const InboxSeverity({required this.rank, required this.raw});

  /// Sort key: 0 = highest urgency.
  final int rank;

  /// Canonical string as written to the DB / sent over the wire.
  final String raw;
}

extension InboxSeverityX on InboxSeverity {
  /// Render colour. Re-uses the existing semantic palette so the inbox
  /// stays visually consistent with deadlines / case-file accents.
  Color get badgeColor {
    switch (this) {
      case InboxSeverity.critical:
        return AppColors.error;
      case InboxSeverity.high:
        return AppColors.warning;
      case InboxSeverity.medium:
        return AppColors.info;
      case InboxSeverity.low:
        return AppColors.textTertiary;
    }
  }

  /// Light tint for the card background (subtle severity hint that does not
  /// hurt readability of the body text on top).
  Color get badgeBgColor {
    switch (this) {
      case InboxSeverity.critical:
        return AppColors.errorBg;
      case InboxSeverity.high:
        return AppColors.warningBg;
      case InboxSeverity.medium:
        return AppColors.infoBg;
      case InboxSeverity.low:
        return AppColors.surfaceVariant;
    }
  }

  /// CRITICAL gets the subtle pulse animation per spec §D6.
  bool get pulses => this == InboxSeverity.critical;

  /// Parse the raw enum string. Returns `null` if [raw] is null/empty/
  /// unknown — callers fall back to LOW.
  static InboxSeverity? parse(String? raw) {
    if (raw == null) return null;
    switch (raw) {
      case 'CRITICAL':
        return InboxSeverity.critical;
      case 'HIGH':
        return InboxSeverity.high;
      case 'MEDIUM':
        return InboxSeverity.medium;
      case 'LOW':
        return InboxSeverity.low;
      default:
        return null;
    }
  }
}
