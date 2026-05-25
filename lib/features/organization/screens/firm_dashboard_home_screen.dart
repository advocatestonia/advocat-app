import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../shared/widgets/advocat_gradient_header.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/max_width_wrapper.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/organization.dart';
import '../providers/org_providers.dart';
import '../widgets/org_activity_feed.dart';
import '../widgets/working_context_banner.dart';

/// Firm home — landing for org members.
/// Spec: see FLUTTER_UI_SPEC.md §7.
class FirmDashboardHomeScreen extends ConsumerWidget {
  const FirmDashboardHomeScreen({super.key, required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgAsync = ref.watch(orgBySlugProvider(slug));
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AdvocatGradientHeader(title: 'Firm dashboard'),
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
              // Ensure active org context follows the URL.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (ref.read(activeOrgIdProvider) != org.id) {
                  ref.read(activeOrgIdProvider.notifier).setActive(org.id);
                }
              });
              return _DashboardBody(
                  org: org, firstName: user?.fullName.split(' ').first);
            },
          ),
        ),
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.org, this.firstName});
  final Organization org;
  final String? firstName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(orgMembersProvider(org.id));
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(orgMembersProvider(org.id));
        ref.invalidate(orgRecentActivityProvider(org.id));
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          const WorkingContextBanner(),
          const SizedBox(height: 16),
          _Greeting(
              firstName: firstName,
              org: org,
              memberCount: membersAsync.maybeWhen(
                  data: (l) => l.length, orElse: () => 1)),
          const SizedBox(height: 20),
          _QuickActions(slug: org.slug),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (ctx, c) {
              final isWide = c.maxWidth > 700;
              final activity = _Section(
                title: 'Recent activity',
                child: OrgActivityFeed(orgId: org.id),
              );
              final deadlines = _Section(
                title: 'Upcoming deadlines',
                child: _DeadlinesPlaceholder(slug: org.slug),
              );
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: activity),
                    const SizedBox(width: 16),
                    Expanded(child: deadlines),
                  ],
                );
              }
              return Column(
                children: [
                  activity,
                  const SizedBox(height: 16),
                  deadlines,
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          _Section(
            title: 'Shared with the firm',
            child: _CasesPlaceholder(slug: org.slug),
          ),
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({
    required this.org,
    required this.memberCount,
    this.firstName,
  });
  final Organization org;
  final int memberCount;
  final String? firstName;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final salutation = hour < 12
        ? 'Good morning'
        : (hour < 18 ? 'Good afternoon' : 'Good evening');
    final greet = firstName == null || firstName!.isEmpty
        ? salutation
        : '$salutation, $firstName';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withValues(alpha: 0.12),
            AppColors.primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greet — ${org.name}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _StatChip(value: '$memberCount', label: 'members'),
              const SizedBox(width: 16),
              _StatChip(value: '${org.seatLimit}', label: 'seats'),
              const SizedBox(width: 16),
              if (org.isOnTrial)
                _StatChip(
                  value: '${org.trialDaysRemaining ?? 0}',
                  label: 'trial days left',
                  highlight: true,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.value,
    required this.label,
    this.highlight = false,
  });
  final String value;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: highlight ? AppColors.accent : AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        AppButton(
          label: 'New case',
          leadingIcon: Icons.add_rounded,
          onPressed: () => context.push('/cases-v2/new'),
        ),
        AppButton(
          label: 'Upload document',
          variant: AppButtonVariant.secondary,
          leadingIcon: Icons.upload_outlined,
          onPressed: () => context.push('/scan'),
        ),
        AppButton(
          label: 'Add deadline',
          variant: AppButtonVariant.secondary,
          leadingIcon: Icons.event_outlined,
          onPressed: () => context.push('/deadlines'),
        ),
        AppButton(
          label: 'Invite member',
          variant: AppButtonVariant.ghost,
          leadingIcon: Icons.person_add_alt_1_outlined,
          onPressed: () => context.push('/orgs/$slug/members'),
        ),
      ],
    );
  }
}

class _DeadlinesPlaceholder extends StatelessWidget {
  const _DeadlinesPlaceholder({required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Deadlines from your firm-shared cases will appear here.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textTertiary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push('/deadlines'),
            icon: const Icon(Icons.event_outlined, size: 16),
            label: const Text('Open deadlines'),
          ),
        ],
      ),
    );
  }
}

class _CasesPlaceholder extends StatelessWidget {
  const _CasesPlaceholder({required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Shared cases live in your existing Cases tab — they show up automatically while in this org context.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push('/cases-v2'),
            icon: const Icon(Icons.folder_open_outlined, size: 16),
            label: const Text('Open cases'),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
