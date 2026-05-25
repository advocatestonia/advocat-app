import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../shared/widgets/advocat_gradient_header.dart';
import '../../../shared/widgets/max_width_wrapper.dart';
import '../models/organization.dart';
import '../models/usage_stats.dart';
import '../providers/org_providers.dart';
import '../widgets/usage_chart.dart';
import '../widgets/working_context_banner.dart';

/// Usage stats: KPIs + daily activity chart + per-member breakdown + API
/// usage. Spec: see FLUTTER_UI_SPEC.md §6.
class OrgUsageStatsScreen extends ConsumerStatefulWidget {
  const OrgUsageStatsScreen({super.key, required this.slug});
  final String slug;

  @override
  ConsumerState<OrgUsageStatsScreen> createState() =>
      _OrgUsageStatsScreenState();
}

class _OrgUsageStatsScreenState extends ConsumerState<OrgUsageStatsScreen> {
  UsagePeriod _period = UsagePeriod.currentMonth;

  @override
  Widget build(BuildContext context) {
    final orgAsync = ref.watch(orgBySlugProvider(widget.slug));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AdvocatGradientHeader(title: 'Usage'),
      body: SafeArea(
        child: MaxWidthWrapper(
          child: orgAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text('$e',
                  style: const TextStyle(color: AppColors.error)),
            ),
            data: (org) {
              if (org == null) {
                return const Center(
                    child: Text('Organization not found.'));
              }
              return _UsageBody(
                org: org,
                period: _period,
                onPeriodChange: (p) => setState(() => _period = p),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _UsageBody extends ConsumerWidget {
  const _UsageBody({
    required this.org,
    required this.period,
    required this.onPeriodChange,
  });

  final Organization org;
  final UsagePeriod period;
  final ValueChanged<UsagePeriod> onPeriodChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(orgUsageStatsProvider(
      UsageStatsArgs(orgId: org.id, period: period),
    ));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(orgUsageStatsProvider(
            UsageStatsArgs(orgId: org.id, period: period)));
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          const WorkingContextBanner(),
          const SizedBox(height: 16),
          _PeriodTabs(current: period, onChanged: onPeriodChange),
          const SizedBox(height: 16),
          stats.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Text('$e',
                  style: const TextStyle(color: AppColors.error)),
            ),
            data: (s) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _KpiGrid(stats: s),
                const SizedBox(height: 16),
                _ChartCard(
                  title: 'Daily activity',
                  subtitle: 'Messages sent per day',
                  child: UsageLineChart(data: s.dailyActivity),
                ),
                const SizedBox(height: 16),
                _ChartCard(
                  title: 'Top members',
                  subtitle: 'By message volume in this period',
                  child: UsageBarChart(
                    bars: s.perMember
                        .take(10)
                        .map((m) => (
                              label: m.displayName,
                              value: m.messages.toDouble(),
                            ))
                        .toList(),
                  ),
                ),
                if (org.plan.hasApiAccess) ...[
                  const SizedBox(height: 16),
                  _ChartCard(
                    title: 'API usage',
                    subtitle: 'API calls per day',
                    child: UsageLineChart(
                      data: s.apiCallsByDay,
                      lineColor: AppColors.primary,
                      fillColor: AppColors.primary.withValues(alpha: 0.10),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodTabs extends StatelessWidget {
  const _PeriodTabs({required this.current, required this.onChanged});
  final UsagePeriod current;
  final ValueChanged<UsagePeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final p in UsagePeriod.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(p.label),
                selected: current == p,
                onSelected: (_) => onChanged(p),
                backgroundColor: AppColors.surface,
                selectedColor: AppColors.accent.withValues(alpha: 0.15),
                side: BorderSide(
                  color: current == p
                      ? AppColors.accent
                      : AppColors.border,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.stats});
  final UsageStats stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, c) {
        final cols = c.maxWidth > 700 ? 4 : 2;
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: cols == 4 ? 1.55 : 1.4,
          children: [
            _KpiCard(
              label: 'Messages sent',
              value: stats.messagesSent,
              delta: stats.messagesDelta,
              icon: Icons.chat_bubble_outline_rounded,
            ),
            _KpiCard(
              label: 'Documents uploaded',
              value: stats.documentsUploaded,
              delta: stats.documentsDelta,
              icon: Icons.upload_file_outlined,
            ),
            _KpiCard(
              label: 'Cases created',
              value: stats.casesCreated,
              delta: stats.casesDelta,
              icon: Icons.folder_outlined,
            ),
            _KpiCard(
              label: 'API calls',
              value: stats.apiCalls,
              delta: stats.apiDelta,
              icon: Icons.api_outlined,
            ),
          ],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.delta,
    required this.icon,
  });
  final String label;
  final int value;
  final double delta;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isPos = delta >= 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value.toString(),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          if (delta != 0)
            Row(
              children: [
                Icon(
                  isPos
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 12,
                  color: isPos ? AppColors.success : AppColors.error,
                ),
                const SizedBox(width: 2),
                Text(
                  '${(delta.abs() * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isPos ? AppColors.success : AppColors.error,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'vs prior',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
