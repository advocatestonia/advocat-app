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
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null && state.threads.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            state.errorMessage!,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppColors.error,
            ),
            textAlign: TextAlign.center,
          ),
        ),
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
        return KeyedSubtree(
          key: key,
          child: TriageCard(thread: thread),
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
            label: l?.inboxFilterAll ?? 'All',
            color: AppColors.textPrimary,
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
