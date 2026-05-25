import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../providers/org_providers.dart';
import 'org_switcher_sheet.dart';

/// Persistent banner shown at the top of org-scoped screens reading
/// `Working as <Org name> · Switch`. Tapping "Switch" opens the
/// [OrgSwitcherSheet] bottom sheet.
///
/// Renders nothing when the user has no active org context (B2C mode) so
/// pure B2C users never see this surface.
class WorkingContextBanner extends ConsumerWidget {
  const WorkingContextBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final org = ref.watch(activeOrgProvider);
    if (org == null) return const SizedBox.shrink();

    return Material(
      color: AppColors.accent.withValues(alpha: 0.08),
      child: InkWell(
        onTap: () => OrgSwitcherSheet.show(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 8,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.business_outlined,
                size: 16,
                color: AppColors.accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Working as ${org.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentDark,
                  ),
                ),
              ),
              const Text(
                'Switch',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                  decoration: TextDecoration.underline,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.chevron_right_rounded,
                size: 14,
                color: AppColors.accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
