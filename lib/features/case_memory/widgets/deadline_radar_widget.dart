// =====================================================================
// DeadlineRadarWidget — top-5 upcoming deadlines across all cases.
//
// Slot-in widget for home_screen / cases_list_screen (architect §7).
// Reads `globalDeadlinesProvider` (active_deadlines RPC, top-10 returned;
// we cap display at 5 with "View all" link).
//
// Behaviour:
//   * Empty state: localized "No upcoming deadlines" placeholder.
//   * Each row: case title (small) + deadline title + "in 3 days" chip.
//   * Tap → navigate to per-case deadline list (CaseDeadlinesScreen).
//   * If permission state is `notAsked`, shows the soft-ask banner above
//     the list (architect §9).
//
// We deliberately use the existing `DeadlineCard` in compact mode so the
// radar and the per-case list look visually consistent.
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/notification_service.dart';
import '../models/case_deadline.dart';
import '../state/case_deadline_providers.dart';
import 'deadline_card.dart';

/// How many deadlines to show on the radar at most.
const int kRadarDisplayLimit = 5;

class DeadlineRadarWidget extends ConsumerWidget {
  const DeadlineRadarWidget({
    super.key,
    this.notificationService,
  });

  /// Test seam — defaults to [NotificationService.instance].
  final NotificationService? notificationService;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final asyncDeadlines = ref.watch(globalDeadlinesProvider);

    return asyncDeadlines.when(
      loading: () => const _RadarLoading(),
      error: (_, __) => const SizedBox.shrink(),
      data: (deadlines) {
        // ── Permission soft-ask: only render when we actually have a
        // deadline to remind the user about. No deadlines → no ask.
        final hasDeadlines = deadlines.isNotEmpty;
        final permissionState = ref.watch(deadlinePermissionProvider);

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasDeadlines &&
                  permissionState == DeadlinePermissionState.notAsked)
                _PermissionSoftAsk(
                  l10n: l10n,
                  onAllow: () async {
                    await ref
                        .read(deadlinePermissionProvider.notifier)
                        .markAllowed();
                    final svc =
                        notificationService ?? NotificationService.instance;
                    // Best-effort — swallow errors so the UI doesn't
                    // crash if firebase isn't configured in the test
                    // env.
                    try {
                      await svc.requestPermission();
                    } catch (_) {}
                  },
                  onLater: () => ref
                      .read(deadlinePermissionProvider.notifier)
                      .markLater(),
                ),
              Row(
                children: [
                  const Icon(Icons.radar, size: 18, color: AppColors.accent),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    l10n?.deadlineRadarTitle ?? 'Upcoming deadlines',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (deadlines.length > kRadarDisplayLimit)
                    TextButton(
                      key: const Key('deadline-radar-view-all'),
                      onPressed: () => context.go('/deadlines'),
                      child: Text(
                        l10n?.deadlineRadarViewAll ?? 'View all',
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              if (!hasDeadlines)
                _RadarEmpty(l10n: l10n)
              else
                ...deadlines.take(kRadarDisplayLimit).map(
                      (d) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: DeadlineCard(
                          deadline: d,
                          mode: DeadlineCardMode.compact,
                          onTap: () => _onTapDeadline(context, d),
                        ),
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  void _onTapDeadline(BuildContext context, CaseDeadline d) {
    // Per architect §7: tap → navigate to per-case deadline list. We
    // route through GoRouter so the deep link is shareable from a push.
    context.push('/cases-v2/${d.caseId}/deadlines');
  }
}

class _RadarLoading extends StatelessWidget {
  const _RadarLoading();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
    );
  }
}

class _RadarEmpty extends StatelessWidget {
  const _RadarEmpty({required this.l10n});
  final AppLocalizations? l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('deadline-radar-empty'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_available_outlined,
              color: AppColors.textSecondary, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              l10n?.deadlineRadarEmpty ?? 'No upcoming deadlines',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionSoftAsk extends StatelessWidget {
  const _PermissionSoftAsk({
    required this.l10n,
    required this.onAllow,
    required this.onLater,
  });

  final AppLocalizations? l10n;
  final VoidCallback onAllow;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('deadline-permission-soft-ask'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.infoBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active_outlined,
                  color: AppColors.info, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n?.deadlinePermissionAskTitle ??
                      'Enable deadline reminders?',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.info,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n?.deadlinePermissionAskBody ??
                "We'll ping you 7, 3, and 1 day before each statutory "
                    "deadline, plus the morning of. Never used for marketing.",
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                key: const Key('deadline-permission-later'),
                onPressed: onLater,
                child: Text(l10n?.deadlinePermissionLater ?? 'Later'),
              ),
              const SizedBox(width: AppSpacing.xs),
              ElevatedButton(
                key: const Key('deadline-permission-allow'),
                onPressed: onAllow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.info,
                  foregroundColor: Colors.white,
                ),
                child: Text(l10n?.deadlinePermissionAllow ?? 'Allow'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
