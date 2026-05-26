import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/deadline.dart';
import '../../../services/supabase_service.dart';
import '../../../shared/utils/date_utils.dart';
// EU corpus phase 2 — pan-EU deadline radar (self-contained mockup
// widget; no network, no providers, deterministic mock output). Mounted
// here as a collapsible section above the per-user deadlines list so
// users can dry-run a hypothetical EU deadline without leaving the
// screen.
import '../../../widgets/deadline_radar_eu.dart';
import '../providers/deadlines_provider.dart';

// ---------------------------------------------------------------------------
// Deadlines Screen
// ---------------------------------------------------------------------------

/// Segment filter for deadlines.
enum _DeadlineSegment { upcoming, overdue, completed }

final _deadlineSegmentProvider =
    StateProvider<_DeadlineSegment>((_) => _DeadlineSegment.upcoming);

class DeadlinesScreen extends ConsumerStatefulWidget {
  const DeadlinesScreen({super.key});

  @override
  ConsumerState<DeadlinesScreen> createState() => _DeadlinesScreenState();
}

class _DeadlinesScreenState extends ConsumerState<DeadlinesScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    ));
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final deadlinesAsync = ref.watch(allDeadlinesProvider);
    final segment = ref.watch(_deadlineSegmentProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_outlined, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(l10n.deadlines),
          ],
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              // -- EU deadline radar (collapsed by default) --
              // Self-contained mockup widget — degrades cleanly when not
              // touched (renders only the section header until expanded).
              const _EuRadarSection(),

              // -- Segmented control --
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<_DeadlineSegment>(
                    segments: [
                      ButtonSegment(
                        value: _DeadlineSegment.upcoming,
                        label: Text(l10n.upcoming),
                      ),
                      ButtonSegment(
                        value: _DeadlineSegment.overdue,
                        label: Text(l10n.overdue),
                      ),
                      ButtonSegment(
                        value: _DeadlineSegment.completed,
                        label: Text(l10n.completed),
                      ),
                    ],
                    selected: {segment},
                    onSelectionChanged: (sel) =>
                        ref.read(_deadlineSegmentProvider.notifier).state =
                            sel.first,
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ),

              // -- Deadlines list --
              Expanded(
                child: deadlinesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: AppColors.error),
                        const SizedBox(height: AppSpacing.md),
                        Text(l10n.couldNotLoadDeadlines,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: AppSpacing.sm),
                        TextButton(
                          onPressed: () =>
                              ref.invalidate(allDeadlinesProvider),
                          child: Text(l10n.retry),
                        ),
                      ],
                    ),
                  ),
                  data: (deadlines) {
                    final filtered = _filter(deadlines, segment);

                    if (filtered.isEmpty) {
                      return _EmptyDeadlines(segment: segment);
                    }

                    return RefreshIndicator(
                      onRefresh: () async =>
                          ref.invalidate(allDeadlinesProvider),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.sm,
                          AppSpacing.md,
                          AppSpacing.xxl,
                        ),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final isUrgent =
                              AppDateUtils.daysUntil(filtered[index].dueDate) <
                                      3 &&
                                  filtered[index].status !=
                                      DeadlineStatus.completed;
                          return _StaggeredDeadlineCard(
                            index: index,
                            isFirstUrgent: index == 0 && isUrgent,
                            child: _DeadlineCard(
                              deadline: filtered[index],
                              onMarkComplete: () async {
                                final supabase =
                                    ref.read(supabaseServiceProvider);
                                await supabase.updateDeadline(
                                  filtered[index].id,
                                  {'status': 'completed'},
                                );
                                ref.invalidate(allDeadlinesProvider);
                              },
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Deadline> _filter(List<Deadline> deadlines, _DeadlineSegment segment) {
    final now = DateTime.now();
    return switch (segment) {
      _DeadlineSegment.upcoming => deadlines
          .where((d) =>
              d.status == DeadlineStatus.upcoming &&
              d.dueDate.isAfter(now))
          .toList(),
      _DeadlineSegment.overdue => deadlines
          .where((d) =>
              d.status == DeadlineStatus.overdue ||
              (d.status == DeadlineStatus.upcoming &&
                  d.dueDate.isBefore(now)))
          .toList(),
      _DeadlineSegment.completed => deadlines
          .where((d) => d.status == DeadlineStatus.completed)
          .toList(),
    };
  }
}

// ---------------------------------------------------------------------------
// Staggered entrance animation wrapper
// ---------------------------------------------------------------------------

class _StaggeredDeadlineCard extends StatefulWidget {
  const _StaggeredDeadlineCard({
    required this.index,
    required this.child,
    this.isFirstUrgent = false,
  });

  final int index;
  final Widget child;
  final bool isFirstUrgent;

  @override
  State<_StaggeredDeadlineCard> createState() =>
      _StaggeredDeadlineCardState();
}

class _StaggeredDeadlineCardState extends State<_StaggeredDeadlineCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // Stagger delay per index (max 600ms total delay)
    final delay = Duration(milliseconds: (widget.index * 80).clamp(0, 600));
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );

    // Add breathing effect for the most urgent item
    if (widget.isFirstUrgent) {
      child = _BreathingWrapper(child: child);
    }

    return child;
  }
}

// ---------------------------------------------------------------------------
// Breathing effect for most urgent item
// ---------------------------------------------------------------------------

class _BreathingWrapper extends StatefulWidget {
  const _BreathingWrapper({required this.child});
  final Widget child;

  @override
  State<_BreathingWrapper> createState() => _BreathingWrapperState();
}

class _BreathingWrapperState extends State<_BreathingWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathController;
  late final Animation<double> _breathAnimation;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _breathAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _breathAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: [
              BoxShadow(
                color: AppColors.error
                    .withValues(alpha: 0.15 + 0.12 * _breathAnimation.value),
                blurRadius: 12 + 8 * _breathAnimation.value,
                spreadRadius: 1 * _breathAnimation.value,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ---------------------------------------------------------------------------
// Deadline Card
// ---------------------------------------------------------------------------

class _DeadlineCard extends StatefulWidget {
  const _DeadlineCard({
    required this.deadline,
    required this.onMarkComplete,
  });

  final Deadline deadline;
  final VoidCallback onMarkComplete;

  @override
  State<_DeadlineCard> createState() => _DeadlineCardState();
}

class _DeadlineCardState extends State<_DeadlineCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _pressAnimation;

  // Pulse controller for urgent countdown badge
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _pressAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );

    // Setup pulse for urgent deadlines
    final days = AppDateUtils.daysUntil(widget.deadline.dueDate);
    final isCompleted = widget.deadline.status == DeadlineStatus.completed;
    if (!isCompleted && days < 3) {
      _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
      )..repeat(reverse: true);
      _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
        CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
      );
    }
  }

  @override
  void dispose() {
    _pressController.dispose();
    _pulseController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final days = AppDateUtils.daysUntil(widget.deadline.dueDate);
    final isOverdue = days < 0;
    final isCompleted = widget.deadline.status == DeadlineStatus.completed;
    final isUrgent = !isCompleted && (isOverdue || days < 3);

    // Color coding: green >7d, amber 3-7d, red <3d
    final urgencyColor = isCompleted
        ? AppColors.textTertiary
        : isOverdue || days < 3
            ? AppColors.error
            : days <= 7
                ? AppColors.warning
                : AppColors.success;

    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) => _pressController.reverse(),
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: _pressAnimation,
        builder: (context, child) => Transform.scale(
          scale: _pressAnimation.value,
          child: child,
        ),
        child: Semantics(
          label:
              'Deadline: ${widget.deadline.title}, ${isCompleted ? "completed" : isOverdue ? "${-days} days overdue" : "$days days remaining"}',
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: isUrgent
                    ? AppColors.error.withValues(alpha: 0.3)
                    : AppColors.border,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
                if (isUrgent)
                  BoxShadow(
                    color: AppColors.error.withValues(alpha: 0.10),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  // -- Days remaining (big number) --
                  _buildCountdownBadge(
                      days, isOverdue, isCompleted, urgencyColor, l10n),
                  const SizedBox(width: AppSpacing.md),

                  // -- Deadline info --
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.deadline.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isCompleted
                                ? AppColors.textTertiary
                                : AppColors.textPrimary,
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppDateUtils.formatDate(widget.deadline.dueDate),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (widget.deadline.sourceDocumentId != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.link,
                                size: 12,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l10n.fromDocument,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // -- Mark complete --
                  if (!isCompleted)
                    Semantics(
                      label: 'Mark deadline complete',
                      button: true,
                      child: IconButton(
                        onPressed: widget.onMarkComplete,
                        tooltip: l10n.markComplete,
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        icon: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.success
                                    .withValues(alpha: 0.15),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check,
                            color: AppColors.success,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownBadge(int days, bool isOverdue, bool isCompleted,
      Color urgencyColor, AppLocalizations l10n) {
    Widget badge = Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: urgencyColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isCompleted)
            Icon(Icons.check, color: urgencyColor, size: 28)
          else ...[
            Text(
              isOverdue ? '${-days}' : '$days',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: urgencyColor,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isOverdue ? l10n.daysLate : l10n.days,
              style: TextStyle(
                fontSize: 11,
                color: urgencyColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );

    // Pulse animation for urgent countdown badges
    if (_pulseAnimation != null) {
      badge = AnimatedBuilder(
        animation: _pulseAnimation!,
        builder: (context, child) => Transform.scale(
          scale: _pulseAnimation!.value,
          child: child,
        ),
        child: badge,
      );
    }

    return badge;
  }
}

// ---------------------------------------------------------------------------
// Empty State
// ---------------------------------------------------------------------------

class _EmptyDeadlines extends StatefulWidget {
  const _EmptyDeadlines({required this.segment});

  final _DeadlineSegment segment;

  @override
  State<_EmptyDeadlines> createState() => _EmptyDeadlinesState();
}

class _EmptyDeadlinesState extends State<_EmptyDeadlines>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (icon, title, subtitle) = switch (widget.segment) {
      _DeadlineSegment.upcoming => (
          Icons.event_available_outlined,
          l10n.noUpcomingDeadlines,
          l10n.allClearDeadlines,
        ),
      _DeadlineSegment.overdue => (
          Icons.check_circle_outline,
          l10n.nothingOverdue,
          l10n.greatJobDeadlines,
        ),
      _DeadlineSegment.completed => (
          Icons.history_outlined,
          l10n.noCompletedDeadlines,
          l10n.completedDeadlinesDesc,
        ),
    };

    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 40, color: AppColors.success),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
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

// ---------------------------------------------------------------------------
// EU Deadline Radar section wrapper
// ---------------------------------------------------------------------------

/// Collapsible host for [DeadlineRadarEu]. The mockup widget is fully
/// self-contained (no network calls, deterministic mock output) so this
/// section degrades to a single ListTile-style header when collapsed and
/// renders the calculator inline when expanded. No risk of breaking the
/// existing per-user deadlines list below.
class _EuRadarSection extends StatelessWidget {
  const _EuRadarSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          // Remove the default ExpansionTile divider lines so it blends
          // with the surrounding deadlines screen chrome.
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: const ExpansionTile(
            key: Key('eu-deadline-radar-section'),
            leading: Icon(Icons.radar, color: AppColors.accent),
            title: Text(
              'EU deadline radar (preview)',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              'Hypothetical EU procedural deadlines — mock data',
              style: TextStyle(fontSize: 11),
            ),
            childrenPadding: EdgeInsets.zero,
            children: [DeadlineRadarEu()],
          ),
        ),
      ),
    );
  }
}
