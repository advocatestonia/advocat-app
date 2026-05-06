import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/router.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../constants/app_icons.dart';
import 'max_width_wrapper.dart';

/// Provider that exposes the count of urgent deadlines for the badge.
/// Replace with actual provider from deadlines feature when available.
final urgentDeadlineCountProvider = StateProvider<int>((ref) => 0);

/// Bottom navigation shell that wraps the main app screens.
///
/// Tabs: Home, Cases, Scan (centre, prominent), Deadlines, Settings.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  // Email Agent D6 — Inbox tab inserted between Cases and Scan. Six tabs
  // total now; the Scan centre button stays at index 3 (post-insert) so
  // the layout still puts it dead centre.
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
      route: AppRoutes.inbox,
      icon: Icons.inbox_outlined,
      activeIcon: Icons.inbox_rounded,
      label: 'Inbox',
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
    if (location.startsWith('/inbox')) return 2;
    if (location.startsWith('/scan')) return 3;
    if (location.startsWith('/deadlines')) return 4;
    if (location.startsWith('/settings')) return 5;
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

    // Localized labels for tabs (order must match _tabs).
    // Email Agent D6 inserts the Inbox tab between Cases and Scan, so
    // this list MUST track the same insertion to keep label/index alignment.
    final localizedLabels = [
      l?.home ?? 'Home',
      l?.cases ?? 'Cases',
      l?.inboxTitle ?? 'Inbox',
      l?.scan ?? 'Scan',
      l?.deadlines ?? 'Deadlines',
      l?.settings ?? 'Settings',
    ];

    return Scaffold(
      // Constrain mobile-first UI to phone width on desktop viewports.
      // Without this the home grid stretches to 1440px with huge dead
      // gutters between tiles — see QA report 2026-05-03 (P0 blocker).
      body: MaxWidthWrapper(child: child),
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.85),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, -4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 6,
                ),
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
      label:
          '$label tab${isActive ? ", selected" : ""}${badgeCount > 0 ? ", $badgeCount notifications" : ""}',
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
                // Icon with subtle glow when active
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.30),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ]
                        : [],
                  ),
                  child: Badge(
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
                    child: AnimatedScale(
                      scale: isActive ? 1.1 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      child: Icon(icon, size: 24, color: color),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: color,
                  ),
                  child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CenterScanButton extends StatefulWidget {
  const _CenterScanButton({
    required this.isActive,
    required this.label,
    required this.onTap,
  });

  final bool isActive;
  final String label;
  final VoidCallback onTap;

  @override
  State<_CenterScanButton> createState() => _CenterScanButtonState();
}

class _CenterScanButtonState extends State<_CenterScanButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${widget.label} tab${widget.isActive ? ", selected" : ""}',
      button: true,
      selected: widget.isActive,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                final pulseValue = _pulseAnimation.value;
                return Container(
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer pulse ring
                      Container(
                        width: 52 + (8 * pulseValue),
                        height: 52 + (8 * pulseValue),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.accent
                                .withValues(alpha: 0.25 * (1 - pulseValue)),
                            width: 2,
                          ),
                        ),
                      ),
                      // Main button
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
                              color: AppColors.accent
                                  .withValues(alpha: 0.35 + 0.15 * pulseValue),
                              blurRadius: 12 + 6 * pulseValue,
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
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 3),
            Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight:
                    widget.isActive ? FontWeight.w600 : FontWeight.w500,
                color:
                    widget.isActive ? AppColors.accent : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
