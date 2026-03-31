import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';

class RightsGuideScreen extends StatelessWidget {
  const RightsGuideScreen({super.key});

  static const _scenarios = <_RightsScenario>[
    _RightsScenario(
      id: 'police-stop',
      title: 'Stopped by Police',
      subtitle: 'Your rights during a police encounter',
      icon: Icons.local_police_outlined,
      color: AppColors.info,
    ),
    _RightsScenario(
      id: 'deportation',
      title: 'Deportation Notice',
      subtitle: 'Steps to challenge a removal order',
      icon: Icons.flight_takeoff_outlined,
      color: AppColors.error,
    ),
    _RightsScenario(
      id: 'workplace',
      title: 'Workplace Rights',
      subtitle: 'Employment law protections in Finland',
      icon: Icons.work_outline,
      color: AppColors.accent,
    ),
    _RightsScenario(
      id: 'tenant',
      title: 'Tenant Rights',
      subtitle: 'Housing and rental protections',
      icon: Icons.home_outlined,
      color: AppColors.warning,
    ),
    _RightsScenario(
      id: 'detention',
      title: 'Immigration Detention',
      subtitle: 'Rights if detained by authorities',
      icon: Icons.lock_outline,
      color: AppColors.error,
    ),
    _RightsScenario(
      id: 'discrimination',
      title: 'Discrimination',
      subtitle: 'How to report and fight discrimination',
      icon: Icons.balance_outlined,
      color: AppColors.primary,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Know Your Rights')),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _scenarios.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final s = _scenarios[index];
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
