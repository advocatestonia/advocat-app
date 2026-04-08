import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../config/router.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../main.dart';
import '../../../models/case_model.dart';
import '../../../models/deadline.dart';
import '../../../shared/utils/date_utils.dart';
import '../../../shared/utils/call_assistant_launcher.dart';
import '../../auth/providers/auth_provider.dart';
import '../../cases/providers/cases_provider.dart';
import '../../cases/widgets/case_card.dart';
import '../../deadlines/providers/deadlines_provider.dart';

// ---------------------------------------------------------------------------
// Home Dashboard
// ---------------------------------------------------------------------------

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final casesAsync = ref.watch(casesProvider);
    final deadlinesAsync = ref.watch(allDeadlinesProvider);
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(casesProvider);
          ref.invalidate(allDeadlinesProvider);
          ref.invalidate(currentUserProvider);
        },
        child: CustomScrollView(
          slivers: [
            // ── Greeting header ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: _GreetingHeader(
                userName: userAsync.valueOrNull?.fullName,
              ),
            ),

            // ── Urgent deadline banner ───────────────────────────────────
            SliverToBoxAdapter(
              child: deadlinesAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (deadlines) {
                  final urgent = deadlines.where((d) {
                    if (d.status == DeadlineStatus.completed ||
                        d.status == DeadlineStatus.cancelled) {
                      return false;
                    }
                    final days = AppDateUtils.daysUntil(d.dueDate);
                    return days <= 7;
                  }).toList();

                  if (urgent.isEmpty) return const SizedBox.shrink();

                  // Show the most urgent one
                  urgent.sort((a, b) => a.dueDate.compareTo(b.dueDate));
                  return _UrgentBanner(deadline: urgent.first);
                },
              ),
            ),

            // ── Quick actions ────────────────────────────────────────────
            const SliverToBoxAdapter(child: _QuickActions()),

            // ── Cases or empty state ─────────────────────────────────────
            casesAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => SliverFillRemaining(
                child: _ErrorState(
                  message: AppLocalizations.of(context)?.couldNotLoadCases ?? 'Could not load your cases',
                  onRetry: () => ref.invalidate(casesProvider),
                ),
              ),
              data: (cases) {
                if (cases.isEmpty) {
                  return const SliverToBoxAdapter(child: _EmptyState());
                }

                final activeCases = cases
                    .where((c) =>
                        c.status != CaseStatus.closed &&
                        c.status != CaseStatus.resolved)
                    .toList();

                return SliverList(
                  delegate: SliverChildListDelegate([
                    // Active cases header
                    if (activeCases.isNotEmpty) ...[
                      _SectionHeader(
                        title: AppLocalizations.of(context)?.activeCases ?? 'Active Cases',
                        trailing: cases.length > 3
                            ? TextButton(
                                onPressed: () => context.go(AppRoutes.cases),
                                child: Text(AppLocalizations.of(context)?.viewAll ?? 'View All'),
                              )
                            : null,
                      ),
                      ...activeCases.take(5).map(
                            (c) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.xs,
                              ),
                              child: CaseCard(
                                legalCase: c,
                                onTap: () => context.push('/cases/${c.id}'),
                              ),
                            ),
                          ),
                    ],

                    // Recent activity
                    const SizedBox(height: AppSpacing.md),
                    _SectionHeader(title: AppLocalizations.of(context)?.recentActivity ?? 'Recent Activity'),
                    _RecentActivity(cases: cases),
                    const SizedBox(height: AppSpacing.lg),
                  ]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Greeting Header
// ---------------------------------------------------------------------------

class _GreetingHeader extends ConsumerWidget {
  const _GreetingHeader({this.userName});

  final String? userName;

  String _greeting(AppLocalizations l) {
    final hour = DateTime.now().hour;
    final name = _firstName;
    String text;
    if (hour < 12) {
      text = l.goodMorning(name.isEmpty ? '' : name);
    } else if (hour < 17) {
      text = l.goodAfternoon(name.isEmpty ? '' : name);
    } else {
      text = l.goodEvening(name.isEmpty ? '' : name);
    }
    // Remove trailing comma+space when name is empty: "Добрый день, " → "Добрый день"
    return text.replaceAll(RegExp(r',\s*$'), '').trim();
  }

  IconData get _timeIcon {
    final hour = DateTime.now().hour;
    if (hour < 6) return Icons.dark_mode_outlined;
    if (hour < 12) return Icons.wb_sunny_outlined;
    if (hour < 17) return Icons.wb_cloudy_outlined;
    if (hour < 21) return Icons.wb_twilight_outlined;
    return Icons.dark_mode_outlined;
  }

  Color get _timeColor {
    final hour = DateTime.now().hour;
    if (hour < 6) return const Color(0xFF6366F1);
    if (hour < 12) return const Color(0xFFF59E0B);
    if (hour < 17) return AppColors.accent;
    if (hour < 21) return const Color(0xFFF97316);
    return const Color(0xFF6366F1);
  }

  String get _firstName {
    if (userName == null || userName!.isEmpty) return '';
    return userName!.split(' ').first;
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    final currentCode = ref.read(localeProvider).languageCode;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.5,
        maxChildSize: 0.8,
        expand: false,
        builder: (ctx, scrollController) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                AppLocalizations.of(context)?.language ?? 'Language',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    for (final lang in supportedLanguages)
                      ListTile(
                        leading: Text(lang.flag, style: const TextStyle(fontSize: 28)),
                        title: Text(
                          lang.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 17,
                          ),
                        ),
                        trailing: currentCode == lang.code
                            ? const Icon(Icons.check_rounded, color: AppColors.accent, size: 28)
                            : null,
                        onTap: () {
                          ref.read(localeProvider.notifier).setLocale(Locale(lang.code));
                          Navigator.pop(ctx);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Time-of-day icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _timeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_timeIcon, color: _timeColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [AppColors.primary, _timeColor],
                    ).createShader(bounds),
                    child: Text(
                      _greeting(l),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                    ),
                  ),
                ),
                // Globe icon for quick language switching
                IconButton(
                  onPressed: () => _showLanguagePicker(context, ref),
                  icon: const Icon(Icons.language_rounded),
                  color: AppColors.textSecondary,
                  tooltip: l.language,
                  iconSize: 26,
                ),
              ],
            ),
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Urgent Deadline Banner
// ---------------------------------------------------------------------------

class _UrgentBanner extends StatelessWidget {
  const _UrgentBanner({required this.deadline});

  final Deadline deadline;

  @override
  Widget build(BuildContext context) {
    final days = AppDateUtils.daysUntil(deadline.dueDate);
    final isOverdue = days < 0;
    final bgColor = isOverdue
        ? AppColors.error.withValues(alpha: 0.08)
        : days <= 3
            ? AppColors.error.withValues(alpha: 0.08)
            : AppColors.warning.withValues(alpha: 0.08);
    final fgColor = isOverdue || days <= 3 ? AppColors.error : AppColors.warning;
    final icon = isOverdue ? Icons.error_outline : Icons.warning_amber_rounded;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: fgColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: fgColor, size: 24),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppDateUtils.urgencyLabel(deadline.dueDate),
                    style: TextStyle(
                      color: fgColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    deadline.title,
                    style: TextStyle(
                      color: fgColor.withValues(alpha: 0.85),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: fgColor.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick Actions Row
// ---------------------------------------------------------------------------

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _QuickActionButton(
                icon: Icons.document_scanner_outlined,
                label: l.scanDocument,
                color: AppColors.accent,
                onTap: () => context.push(AppRoutes.scan),
              ),
              _PulsingQuickActionButton(
                icon: Icons.support_agent_rounded,
                label: l.aiAssistant,
                color: AppColors.accent,
                onTap: () => context.push('/chat/general'),
              ),
              _QuickActionButton(
                icon: Icons.gavel_outlined,
                label: l.legalSection,
                color: AppColors.primary,
                onTap: () => context.push(AppRoutes.rights),
              ),
              _QuickActionButton(
                icon: Icons.calculate_outlined,
                label: l.legalAidCalculator,
                color: AppColors.warning,
                onTap: () => context.push(AppRoutes.legalAid),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _QuickActionButton(
                icon: Icons.lock_outlined,
                label: l.documents,
                color: AppColors.accent,
                onTap: () => context.push(AppRoutes.vault),
              ),
              _QuickActionButton(
                icon: Icons.email_outlined,
                label: 'Email',
                color: AppColors.info,
                onTap: () => context.push(AppRoutes.email),
              ),
              _QuickActionButton(
                icon: Icons.phone_in_talk_outlined,
                label: 'Call AI',
                color: AppColors.success,
                onTap: () => launchCallAssistant(),
              ),
              _QuickActionButton(
                icon: Icons.add_circle_outline,
                label: l.newCase,
                color: AppColors.primary,
                onTap: () => context.push(AppRoutes.caseCreate),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PulsingQuickActionButton extends StatefulWidget {
  const _PulsingQuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_PulsingQuickActionButton> createState() => _PulsingQuickActionButtonState();
}

class _PulsingQuickActionButtonState extends State<_PulsingQuickActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 64,
              height: 64,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Пульсирующее кольцо снаружи
                    Container(
                      width: 56 + _pulseAnimation.value * 12,
                      height: 56 + _pulseAnimation.value * 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.4 - _pulseAnimation.value * 0.35),
                          width: 2,
                        ),
                      ),
                    ),
                    // Основная кнопка — чёткая, не размытая
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.accent, AppColors.accentLight],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.balance_rounded, color: Colors.white, size: 26),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: widget.color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section Header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recent Activity (timeline-style)
// ---------------------------------------------------------------------------

class _RecentActivity extends StatelessWidget {
  const _RecentActivity({required this.cases});

  final List<LegalCase> cases;

  @override
  Widget build(BuildContext context) {
    // Generate recent activity items from case data
    final activities = <_ActivityItem>[];

    final l = AppLocalizations.of(context);
    for (final c in cases) {
      activities.add(_ActivityItem(
        title: l?.caseUpdated ?? 'Case updated',
        subtitle: c.title,
        time: c.updatedAt ?? c.createdAt,
        icon: Icons.update,
        color: AppColors.accent,
      ));
    }

    activities.sort((a, b) => b.time.compareTo(a.time));
    final recent = activities.take(5).toList();

    if (recent.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          l?.noRecentActivity ?? 'No recent activity',
          style: const TextStyle(color: AppColors.textTertiary),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              for (int i = 0; i < recent.length; i++) ...[
                _ActivityRow(
                  item: recent[i],
                  isLast: i == recent.length - 1,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityItem {
  const _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final DateTime time;
  final IconData icon;
  final Color color;
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item, this.isLast = false});

  final _ActivityItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot + line
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: item.color,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        timeago.format(item.time),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty State
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Advocat shield logo — negative margin to cut white space in PNG
          ClipRect(
            child: Align(
              alignment: Alignment.center,
              heightFactor: 0.7,
              child: Image.asset(
                'assets/images/logo_shield.png',
                width: 240,
                height: 240,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
          Text(
            l.noCasesYet,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          Text(
            l.startFirstCase,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 6),
          // Create case button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push(AppRoutes.caseCreate),
              icon: const Icon(Icons.add, size: 20),
              label: Text(l.createCase),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Or chat with AI
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/chat/general'),
              icon: const Icon(Icons.smart_toy_outlined, size: 20),
              label: Text(l.aiAssistant),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

// _TipItem removed — tips block removed from empty state

// ---------------------------------------------------------------------------
// Error State
// ---------------------------------------------------------------------------

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context)?.retry ?? 'Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
