import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';

class RightsGuideScreen extends StatelessWidget {
  const RightsGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final scenarios = <_RightsScenario>[
      _RightsScenario(
        id: 'police-stop',
        title: l10n.stoppedByPolice,
        subtitle: l10n.stoppedByPoliceDesc,
        icon: Icons.local_police_outlined,
        color: AppColors.info,
      ),
      _RightsScenario(
        id: 'deportation',
        title: l10n.deportationNotice,
        subtitle: l10n.deportationNoticeDesc,
        icon: Icons.flight_takeoff_outlined,
        color: AppColors.error,
      ),
      _RightsScenario(
        id: 'workplace',
        title: l10n.workplaceRights,
        subtitle: l10n.workplaceRightsDesc,
        icon: Icons.work_outline,
        color: AppColors.accent,
      ),
      _RightsScenario(
        id: 'tenant',
        title: l10n.tenantRights,
        subtitle: l10n.tenantRightsDesc,
        icon: Icons.home_outlined,
        color: AppColors.warning,
      ),
      _RightsScenario(
        id: 'detention',
        title: l10n.immigrationDetention,
        subtitle: l10n.immigrationDetentionDesc,
        icon: Icons.lock_outline,
        color: AppColors.error,
      ),
      _RightsScenario(
        id: 'discrimination',
        title: l10n.discrimination,
        subtitle: l10n.discriminationDesc,
        icon: Icons.balance_outlined,
        color: AppColors.primary,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.knowYourRights)),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: scenarios.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final s = scenarios[index];
          return Card(
            child: ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: s.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(s.icon, color: s.color, size: 24),
              ),
              title: Text(s.title,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(s.subtitle,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
              trailing: const Icon(Icons.chevron_right,
                  color: AppColors.textTertiary),
              onTap: () => context.push('/rights/${s.id}'),
            ),
          );
        },
      ),
    );
  }
}

class _RightsScenario {
  const _RightsScenario({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}
