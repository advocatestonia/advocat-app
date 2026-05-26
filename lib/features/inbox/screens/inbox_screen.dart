// inbox_screen.dart
// -----------------------------------------------------------------------------
// Inbox screen — D6.
//
// Shows triaged email threads sorted by severity (CRITICAL → LOW) with a
// per-severity filter row at the top. Each row is a TriageCard that owns
// its own actions (approve / edit / snooze / archive).
//
// Routing:
//   * /inbox                → top of the inbox (severity-sorted)
//   * /inbox/thread/:id     → opens the inbox + scrolls / focuses on the
//                             matching thread (deep-link target for the
//                             D7 push notification).
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../models/inbox_severity.dart';
import '../providers/inbox_provider.dart';
import '../widgets/inbox_empty_state.dart';
import '../widgets/parallel_actions_card.dart';
import '../widgets/triage_card.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key, this.focusThreadId});

  /// Optional thread UUID to focus when arriving via deep link
  /// `advocat://inbox/thread/<id>` (D7 push notification target).
  final String? focusThreadId;

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  final _scrollController = ScrollController();
  final _itemKeys = <String, GlobalKey>{};
  bool _didFocus = false;

  @override
  void initState() {
    super.initState();
    // Scroll to focusThreadId once the first build flushes.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeFocusThread());
  }

  @override
  void didUpdateWidget(covariant InboxScreen old) {
    super.didUpdateWidget(old);
    if (old.focusThreadId != widget.focusThreadId) _didFocus = false;
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeFocusThread());
  }

  void _maybeFocusThread() {
    if (_didFocus) return;
    final id = widget.focusThreadId;
    if (id == null || id.isEmpty) return;
    final key = _itemKeys[id];
    final ctx = key?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      alignment: 0.1,
    );
    _didFocus = true;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(inboxProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l?.inboxTitle ?? 'Inbox'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l?.refresh ?? 'Refresh',
            onPressed: () => ref.read(inboxProvider.notifier).refresh(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(inboxProvider.notifier).refresh(),
        child: Column(
          children: [
            _SeverityFilterRow(active: state.severityFilter),
            Expanded(child: _body(context, l)),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, AppLocalizations? l) {
    final state = ref.watch(inboxProvider);

    if (state.isLoading && state.threads.isEmpty) {
      // P1-7 (2026-05-27): skeleton list instead of a centred spinner.
      // The TriageCard structure is predictable (badge + subject + brief
      // + sender + chip + action row) so 3 grey shimmer-style cards
      // give the user a sense of "list is loading" rather than a
      // blank "is the app frozen?" moment.
      return const _InboxLoadingSkeleton();
    }
    if (state.errorMessage != null && state.threads.isEmpty) {
      // P1-6 (2026-05-27): error state now uses the same EmptyState
      // pattern as InboxEmptyState — icon + title + body + a single
      // clearly-affordant Retry button. A flat red sentence with no
      // call-to-action is a UX dead-end (the only escape was
      // pull-to-refresh, which a user staring at error text won't try).
      return _InboxErrorState(
        message: state.errorMessage!,
        onRetry: () => ref.read(inboxProvider.notifier).refresh(),
      );
    }
    if (state.threads.isEmpty) {
      return ListView(
        controller: _scrollController,
        children: const [
          SizedBox(height: 64),
          InboxEmptyState(),
        ],
      );
    }

    // Reset and rebuild the per-row keys map on every list change so
    // ensureVisible can find the focused row.
    _itemKeys.clear();
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: state.threads.length,
      itemBuilder: (ctx, i) {
        final thread = state.threads[i];
        final key = _itemKeys.putIfAbsent(
          thread.threadId,
          () => GlobalKey(debugLabel: 'inbox-${thread.threadId}'),
        );
        // Parallel Actions Panel (2026-05-25) — when the consilium proposed
        // 2+ related actions for this thread, render the grouped card with
        // batch-approve. Single-action and no-action rows keep using the
        // legacy TriageCard so the existing UX stays unchanged.
        final card = thread.hasParallelActions
            ? ParallelActionsCard(thread: thread)
            : TriageCard(thread: thread);
        return KeyedSubtree(
          key: key,
          child: card,
        );
      },
    );
  }
}

/// Severity filter row: All | CRITICAL | HIGH | MEDIUM | LOW.
class _SeverityFilterRow extends ConsumerWidget {
  const _SeverityFilterRow({required this.active});

  final InboxSeverity? active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        children: [
          _FilterChip(
            // P1-1 (2026-05-27): use brand teal accent (Material 3
            // secondaryContainer equivalent) so the "All" chip reads as
            // part of the same palette family as the severity pastels,
            // not a near-black outlier against the cream surface.
            label: l?.inboxFilterAll ?? 'All',
            color: AppColors.accent,
            selected: active == null,
            onTap: () => ref.read(inboxProvider.notifier).setSeverityFilter(null),
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterChip(
            label: l?.severityCritical ?? 'CRITICAL',
            color: AppColors.error,
            selected: active == InboxSeverity.critical,
            onTap: () => ref
                .read(inboxProvider.notifier)
                .setSeverityFilter(InboxSeverity.critical),
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterChip(
            label: l?.severityHigh ?? 'HIGH',
            color: AppColors.warning,
            selected: active == InboxSeverity.high,
            onTap: () => ref
                .read(inboxProvider.notifier)
                .setSeverityFilter(InboxSeverity.high),
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterChip(
            label: l?.severityMedium ?? 'MEDIUM',
            color: AppColors.info,
            selected: active == InboxSeverity.medium,
            onTap: () => ref
                .read(inboxProvider.notifier)
                .setSeverityFilter(InboxSeverity.medium),
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterChip(
            label: l?.severityLow ?? 'LOW',
            color: AppColors.textSecondary,
            selected: active == InboxSeverity.low,
            onTap: () => ref
                .read(inboxProvider.notifier)
                .setSeverityFilter(InboxSeverity.low),
          ),
        ],
      ),
    );
  }
}

/// P1-7 (2026-05-27): skeleton placeholder shown while the inbox is loading.
///
/// Three card-shaped rows roughly the same height as a TriageCard, with a
/// soft opacity-pulse so the screen feels alive without a centred spinner.
/// Honours `MediaQuery.disableAnimations` (prefers-reduced-motion / WCAG
/// 2.3.3) — when set the cards render at full opacity with no animation.
class _InboxLoadingSkeleton extends StatefulWidget {
  const _InboxLoadingSkeleton();

  @override
  State<_InboxLoadingSkeleton> createState() => _InboxLoadingSkeletonState();
}

class _InboxLoadingSkeletonState extends State<_InboxLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _opacity;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disabled = MediaQuery.of(context).disableAnimations;
    if (_controller == null && !disabled) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1100),
      )..repeat(reverse: true);
      _opacity = Tween<double>(begin: 0.45, end: 0.85).animate(
        CurvedAnimation(parent: _controller!, curve: Curves.easeInOut),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final anim = _opacity;
    const tile = _SkeletonCard();
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      children: [
        for (var i = 0; i < 3; i++)
          anim == null
              ? tile
              : AnimatedBuilder(
                  animation: anim,
                  builder: (_, child) =>
                      Opacity(opacity: anim.value, child: child),
                  child: tile,
                ),
      ],
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  static const _bone = Color(0xFFE5E7EB); // slate-200, neutral grey

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Severity badge + subject row.
          Row(
            children: [
              _Bone(width: 56, height: 16, color: _bone),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: _Bone(height: 16, color: _bone)),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          // Brief — two lines.
          _Bone(height: 12, color: _bone),
          SizedBox(height: 6),
          _Bone(width: 220, height: 12, color: _bone),
          SizedBox(height: AppSpacing.sm),
          // Sender row.
          _Bone(width: 180, height: 12, color: _bone),
          SizedBox(height: AppSpacing.md),
          // Action button row.
          Row(
            children: [
              _Bone(width: 110, height: 28, color: _bone),
              SizedBox(width: AppSpacing.sm),
              _Bone(width: 64, height: 28, color: _bone),
              SizedBox(width: AppSpacing.sm),
              _Bone(width: 80, height: 28, color: _bone),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bone extends StatelessWidget {
  const _Bone({this.width, required this.height, required this.color});

  final double? width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
    );
  }
}

/// P1-6 (2026-05-27): inbox error state with retry button.
///
/// Mirrors InboxEmptyState's visual structure (icon + title + body) so the
/// two states read as siblings. Uses error-tinted icon + a tonal FilledButton
/// for the retry CTA — strong enough to draw attention without competing
/// with the AppBar refresh icon.
class _InboxErrorState extends StatelessWidget {
  const _InboxErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListView(
      // Wrap in ListView so RefreshIndicator pull-to-refresh still fires
      // from the error screen (centred Padding alone is non-scrollable).
      children: [
        const SizedBox(height: 80),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l?.inboxErrorTitle ?? 'Could not load inbox',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(l?.retry ?? 'Retry'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0.4,
            color: selected ? color : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
