// =====================================================================
// DeadlineBanner — slot-in widget for chat_screen / case_detail_screen.
//
// Shows a persistent red banner above the composer when the active
// case has any deadline ≤ 3 days. Dismiss state is per-deadline-id and
// persisted to SharedPreferences:
//
//   advocat.deadline_banner_dismissed.<deadline_id>=<urgency_band>
//
// Re-shows automatically when the urgency band escalates (e.g. user
// dismissed at "high" → next morning it becomes "critical" and the
// banner reappears).
//
// Design (architect §7+§9):
//   * dismissible per-deadline, NOT per-session
//   * tap opens the deadline detail bottom sheet (read-only — full edits
//     happen on CaseDeadlinesScreen)
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../models/case_deadline.dart';
import '../state/active_case_provider.dart';
import '../state/case_deadline_providers.dart';

/// SharedPrefs key prefix.
const _kDismissPrefix = 'advocat.deadline_banner_dismissed.';

/// Lookup the band the user dismissed at (if any) for a deadline.
Future<CaseDeadlineUrgency?> _readDismissedBand(String deadlineId) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('$_kDismissPrefix$deadlineId');
  if (raw == null) return null;
  return CaseDeadlineUrgency.values.firstWhere(
    (v) => v.name == raw,
    orElse: () => CaseDeadlineUrgency.info,
  );
}

Future<void> _writeDismissedBand(
    String deadlineId, CaseDeadlineUrgency band) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('$_kDismissPrefix$deadlineId', band.name);
}

/// Dismissal-band ordering — `critical` is the most urgent, `info` the
/// least. Used to decide whether the urgency has "escalated" since the
/// user dismissed.
int _bandOrdinal(CaseDeadlineUrgency b) {
  switch (b) {
    case CaseDeadlineUrgency.critical:
      return 3;
    case CaseDeadlineUrgency.high:
      return 2;
    case CaseDeadlineUrgency.medium:
      return 1;
    case CaseDeadlineUrgency.info:
      return 0;
  }
}

class DeadlineBanner extends ConsumerStatefulWidget {
  const DeadlineBanner({super.key, this.now});

  /// Test-only override.
  final DateTime? now;

  @override
  ConsumerState<DeadlineBanner> createState() => _DeadlineBannerState();
}

class _DeadlineBannerState extends ConsumerState<DeadlineBanner> {
  /// Cached dismiss-band per deadline, loaded from SharedPreferences.
  /// We refresh on rebuild via [_loadFor]. Keyed by deadline id.
  final Map<String, CaseDeadlineUrgency?> _dismissedCache = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final activeCaseId = ref.watch(activeCaseProvider).activeCaseId;
    if (activeCaseId == null) return const SizedBox.shrink();

    final asyncCritical =
        ref.watch(criticalActiveCaseDeadlineProvider);

    return asyncCritical.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (deadline) {
        if (deadline == null) return const SizedBox.shrink();
        final currentBand = deadline.urgency(now: widget.now);
        // Only show for high/critical urgency (≤3d).
        if (_bandOrdinal(currentBand) <
            _bandOrdinal(CaseDeadlineUrgency.high)) {
          return const SizedBox.shrink();
        }
        return FutureBuilder<CaseDeadlineUrgency?>(
          future: _loadFor(deadline.id),
          builder: (context, snapshot) {
            // While loading, render — better to flash the banner
            // briefly than miss a critical reminder.
            final dismissedAt = snapshot.data;
            if (dismissedAt != null &&
                _bandOrdinal(currentBand) <= _bandOrdinal(dismissedAt)) {
              // User already dismissed at this or a higher band — hide.
              return const SizedBox.shrink();
            }
            return _BannerBody(
              l10n: l10n,
              deadline: deadline,
              currentBand: currentBand,
              now: widget.now,
              onDismiss: () async {
                await _writeDismissedBand(deadline.id, currentBand);
                setState(() {
                  _dismissedCache[deadline.id] = currentBand;
                });
              },
              onOpen: () =>
                  context.push('/cases-v2/${deadline.caseId}/deadlines'),
            );
          },
        );
      },
    );
  }

  Future<CaseDeadlineUrgency?> _loadFor(String id) async {
    if (_dismissedCache.containsKey(id)) {
      return _dismissedCache[id];
    }
    final v = await _readDismissedBand(id);
    _dismissedCache[id] = v;
    return v;
  }
}

class _BannerBody extends StatelessWidget {
  const _BannerBody({
    required this.l10n,
    required this.deadline,
    required this.currentBand,
    required this.onDismiss,
    required this.onOpen,
    this.now,
  });

  final AppLocalizations? l10n;
  final CaseDeadline deadline;
  final CaseDeadlineUrgency currentBand;
  final VoidCallback onDismiss;
  final VoidCallback onOpen;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final days = deadline.daysUntil(now: now);
    final whenLabel = _whenLabel(l10n, days);
    final isMostUrgent = currentBand == CaseDeadlineUrgency.critical;

    return Container(
      key: const Key('deadline-banner'),
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isMostUrgent ? AppColors.error : AppColors.errorBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.error),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: isMostUrgent ? Colors.white : AppColors.error,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              l10n?.deadlineBannerCritical(deadline.title, whenLabel) ??
                  'Critical deadline ${deadline.title} $whenLabel',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isMostUrgent ? Colors.white : AppColors.error,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          TextButton(
            key: const Key('deadline-banner-open'),
            onPressed: onOpen,
            style: TextButton.styleFrom(
              foregroundColor: isMostUrgent ? Colors.white : AppColors.error,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
            ),
            child: Text(l10n?.deadlineBannerOpen ?? 'Open'),
          ),
          IconButton(
            key: const Key('deadline-banner-dismiss'),
            tooltip: l10n?.deadlineBannerDismiss ?? 'Dismiss',
            icon: Icon(
              Icons.close,
              color: isMostUrgent ? Colors.white : AppColors.error,
              size: 18,
            ),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }

  String _whenLabel(AppLocalizations? l10n, int days) {
    if (l10n == null) {
      if (days < 0) return '${-days} days overdue';
      if (days == 0) return 'today';
      if (days == 1) return 'tomorrow';
      return 'in $days days';
    }
    if (days < 0) return l10n.deadlineCardOverdue(-days);
    if (days == 0) return l10n.deadlineCardToday;
    if (days == 1) return l10n.deadlineCardTomorrow;
    return l10n.deadlineCardDaysLeft(days);
  }
}
