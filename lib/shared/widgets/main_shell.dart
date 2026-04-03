import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/router.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../constants/app_icons.dart';

/// Provider that exposes the count of urgent deadlines for the badge.
/// Replace with actual provider from deadlines feature when available.
final urgentDeadlineCountProvider = StateProvider<int>((ref) => 0);

/// Bottom navigation shell that wraps the main app screens.
///
/// Tabs: Home, Cases, Scan (centre, prominent), Deadlines, Settings.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  static const _tabs = [
    _TabDef(
      route: AppRoutes.home,
      icon: AppIcons.homeOutlined,
      activeIcon: AppIcons.home,
      label: 'Home',
    ),
    _TabDef(
      route: AppRoutes.cases,
      icon: AppIcons.casesOutlined,
      activeIcon: AppIcons.cases,
      label: 'Cases',
    ),
    _TabDef(
      route: AppRoutes.scan,
      icon: AppIcons.scanOutlined,
      activeIcon: AppIcons.scan,
      label: 'Scan',
      isCenter: true,
    ),
    _TabDef(
      route: '/deadlines',
      icon: AppIcons.deadlinesOutlined,
      activeIcon: AppIcons.deadlines,
      label: 'Deadlines',
      hasBadge: true,
    ),
    _TabDef(
      route: AppRoutes.settings,
      icon: AppIcons.settingsOutlined,
      activeIcon: AppIcons.settings,
      label: 'Settings',
    ),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/cases')) return 1;
    if (location.startsWith('/scan')) return 2;
    if (location.startsWith('/deadlines')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    final tab = _tabs[index];
    // For the scan tab, push instead of go so it overlays the shell.
    if (tab.isCenter) {
      context.push(tab.route);
    } else {
      context.go(tab.route);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIdx = _currentIndex(context);
    final urgentCount = ref.watch(urgentDeadlineCountProvider);
    final l = AppLocalizations.of(context);

    // Localized labels for tabs (order must match _tabs)
    final localizedLabels = [
      l?.home ?? 'Home',
      l?.cases ?? 'Cases',
      l?.scan ?? 'Scan',
      l?.deadlines ?? 'Deadlines',
      l?.settings ?? 'Settings',
    ];

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final tab = _tabs[i];
                final isActive = currentIdx == i;

                if (tab.isCenter) {
                  return Expanded(
                    child: _CenterScanButton(
                      isActive: isActive,
                      label: localizedLabels[i],
                      onTap: () => _onTap(context, i),
                    ),
                  );
                }

                return Expanded(
                  child: _NavBarItem(
                    icon: isActive ? tab.activeIcon : tab.icon,
                    label: localizedLabels[i],
                    isActive: isActive,
                    badgeCount: tab.hasBadge ? urgentCount : 0,
                    onTap: () => _onTap(context, i),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Private helpers ──────────────────────────────────────────────────────

class _TabDef {
  const _TabDef({
    required this.route,
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.isCenter = false,
    this.hasBadge = false,
  });

  final String route;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isCenter;
  final bool hasBadge;
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.accent : AppColors.textTertiary;

    return Semantics(
      label: '$label tab${isActive ? ", selected" : ""}${badgeCount > 0 ? ", $badgeCount notifications" : ""}',
      button: true,
      selected: isActive,
      child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Badge(
              isLabelVisible: badgeCount > 0,
              label: Text(
                badgeCount > 9 ? '9+' : '$badgeCount',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              backgroundColor: AppColors.error,
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
      ),
      ),
    );
  }
}

class _CenterScanButton extends StatelessWidget {
  const _CenterScanButton({
    required this.isActive,
    required this.label,
    required this.onTap,
  });

  final bool isActive;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label tab${isActive ? ", selected" : ""}',
      button: true,
      selected: isActive,
      child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accent, AppColors.accentDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              AppIcons.scan,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive ? AppColors.accent : AppColors.textTertiary,
            ),
          ),
        ],
      ),
      ),
    );
  }
}
