import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../models/org_role.dart';

/// Compact pill displaying an [OrgRole] in a colour-coded badge.
///
/// Used by the members table, invitation rows, and the working-context
/// banner. Keep visual treatment in sync with `StatusChip` (same radius,
/// same font weight) so they don't clash when both appear on one screen.
class RoleBadge extends StatelessWidget {
  const RoleBadge({super.key, required this.role, this.size = RoleBadgeSize.medium});

  final OrgRole role;
  final RoleBadgeSize size;

  Color get _bgColor => switch (role) {
        OrgRole.owner => const Color(0xFFFEF3C7), // amber-100
        OrgRole.admin => const Color(0xFFDBEAFE), // blue-100
        OrgRole.billing => const Color(0xFFEDE9FE), // violet-100
        OrgRole.member => AppColors.surfaceVariant,
        OrgRole.viewer => const Color(0xFFF3F4F6), // gray-100
      };

  Color get _fgColor => switch (role) {
        OrgRole.owner => const Color(0xFF92400E),
        OrgRole.admin => const Color(0xFF1E3A8A),
        OrgRole.billing => const Color(0xFF5B21B6),
        OrgRole.member => AppColors.textSecondary,
        OrgRole.viewer => AppColors.textTertiary,
      };

  String _label() => switch (role) {
        OrgRole.owner => 'Owner',
        OrgRole.admin => 'Admin',
        OrgRole.billing => 'Billing',
        OrgRole.member => 'Member',
        OrgRole.viewer => 'Viewer',
      };

  @override
  Widget build(BuildContext context) {
    final isSmall = size == RoleBadgeSize.small;
    return Semantics(
      label: 'Role: ${_label()}',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 6 : 8,
          vertical: isSmall ? 2 : 3,
        ),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Text(
          _label(),
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: isSmall ? 10 : 11,
            fontWeight: FontWeight.w700,
            color: _fgColor,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

enum RoleBadgeSize { small, medium }
