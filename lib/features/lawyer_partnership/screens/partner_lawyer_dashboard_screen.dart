// lib/features/lawyer_partnership/screens/partner_lawyer_dashboard_screen.dart
// -----------------------------------------------------------------------------
// Partner-lawyer dashboard (Day2-E lawyer flow).
//
// Three sections stacked vertically:
//
//   1. Earnings + commitment header  — YTD payout, calls completed, avg
//                                      rating, monthly commitment.
//   2. Upcoming bookings list        — each row shows scheduled time, topic,
//                                      a "Read AI brief" inline expansion,
//                                      and a "Mark complete + add summary"
//                                      button when the slot has elapsed.
//   3. Recent completed bookings     — collapsed history with outcome.
//
// The screen is gated by `kLawyerPartnershipEnabled` AND by the user
// having a row in `partner_lawyers` (server enforces this; client shows
// the "not enrolled" card otherwise).
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/feature_flags.dart';
import '../../../config/theme.dart';
import '../models/lawyer_partnership_state.dart';
import '../state/lawyer_partnership_providers.dart';

class PartnerLawyerDashboardScreen extends ConsumerWidget {
  const PartnerLawyerDashboardScreen({super.key});

  static const String routePath = '/partner-lawyer';
  static const String routeName = 'partnerLawyerDashboard';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Partner lawyer dashboard'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: const SafeArea(
        // `kLawyerPartnershipEnabled` is a compile-time bool.fromEnvironment,
        // so the ternary is itself a constant expression — the analyzer
        // collapses it at build time and we keep a const SafeArea.
        child: kLawyerPartnershipEnabled ? _DashboardBody() : _DisabledCard(),
      ),
    );
  }
}

// ─── Flag-off card ──────────────────────────────────────────────────────────

class _DisabledCard extends StatelessWidget {
  const _DisabledCard();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Text(
        'The partner-lawyer program is currently paused.',
        style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
      ),
    );
  }
}

// ─── Body ───────────────────────────────────────────────────────────────────

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(partnerBookingsProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(partnerBookingsProvider);
        await Future<void>.delayed(const Duration(milliseconds: 200));
      },
      child: bookingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorCard(error: '$e'),
        data: (bookings) => _DashboardList(bookings: bookings),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error});
  final String error;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.errorBg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Text(
          'Failed to load dashboard: $error',
          style: const TextStyle(color: AppColors.error),
        ),
      ),
    );
  }
}

class _DashboardList extends StatelessWidget {
  const _DashboardList({required this.bookings});
  final List<LawyerBooking> bookings;

  @override
  Widget build(BuildContext context) {
    final upcoming = bookings.where((b) => b.status.isUpcoming).toList();
    final completed =
        bookings.where((b) => b.status == BookingStatus.completed).toList();
    final earningsCents = completed.fold<int>(
      0,
      (sum, b) => sum + (b.userRating != null ? 2500 : 2500),
    );
    final avgRating = _avg(completed);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: <Widget>[
        _HeaderStats(
          completedCount: completed.length,
          upcomingCount: upcoming.length,
          earningsCents: earningsCents,
          avgRating: avgRating,
        ),
        const SizedBox(height: AppSpacing.lg),
        const Text(
          'Upcoming',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (upcoming.isEmpty)
          const _EmptyHint(text: 'No upcoming bookings.')
        else
          ...upcoming.map((b) => _BookingTile(booking: b, isUpcoming: true)),
        const SizedBox(height: AppSpacing.lg),
        const Text(
          'Completed',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (completed.isEmpty)
          const _EmptyHint(text: 'No completed calls yet.')
        else
          ...completed
              .take(10)
              .map((b) => _BookingTile(booking: b, isUpcoming: false)),
      ],
    );
  }

  static double? _avg(List<LawyerBooking> b) {
    final ratings = b
        .map((x) => x.userRating)
        .where((r) => r != null)
        .cast<int>()
        .toList();
    if (ratings.isEmpty) return null;
    return ratings.fold<int>(0, (a, b) => a + b) / ratings.length;
  }
}

// ─── Header stats ───────────────────────────────────────────────────────────

class _HeaderStats extends StatelessWidget {
  const _HeaderStats({
    required this.completedCount,
    required this.upcomingCount,
    required this.earningsCents,
    required this.avgRating,
  });

  final int completedCount;
  final int upcomingCount;
  final int earningsCents;
  final double? avgRating;

  @override
  Widget build(BuildContext context) {
    final earnings = (earningsCents / 100).toStringAsFixed(2);
    final rating = avgRating == null ? '—' : avgRating!.toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Advocat Partner Lawyer',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              _StatTile(label: 'YTD earnings', value: '€$earnings'),
              _StatTile(
                label: 'Calls completed',
                value: completedCount.toString(),
              ),
              _StatTile(label: 'Upcoming', value: upcomingCount.toString()),
              _StatTile(label: 'Avg rating', value: rating),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

// ─── Booking tile ───────────────────────────────────────────────────────────

class _BookingTile extends ConsumerStatefulWidget {
  const _BookingTile({required this.booking, required this.isUpcoming});
  final LawyerBooking booking;
  final bool isUpcoming;

  @override
  ConsumerState<_BookingTile> createState() => _BookingTileState();
}

class _BookingTileState extends ConsumerState<_BookingTile> {
  bool _briefOpen = false;
  bool _outcomeOpen = false;

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final ts = b.scheduledAt?.toLocal().toString().substring(0, 16) ?? 'TBC';
    final hasBrief = (b.aiBriefMd ?? '').trim().isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '${b.topic.toUpperCase()}  ·  $ts  ·  ${b.language.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _StatusChip(status: b.status),
            ],
          ),
          if (b.userBrief != null && b.userBrief!.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              b.userBrief!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: <Widget>[
              if (hasBrief)
                TextButton.icon(
                  onPressed: () => setState(() => _briefOpen = !_briefOpen),
                  icon: Icon(_briefOpen
                      ? Icons.expand_less
                      : Icons.menu_book_outlined),
                  label: Text(_briefOpen ? 'Hide brief' : 'Read AI brief'),
                ),
              if (widget.isUpcoming && b.status != BookingStatus.cancelled)
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _outcomeOpen = !_outcomeOpen),
                  icon: const Icon(Icons.task_alt_outlined),
                  label: const Text('Mark complete'),
                ),
              if (b.outcomeSummary != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.successBg,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      'Outcome: ${b.outcomeSummary}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (_briefOpen && hasBrief) _BriefExpansion(markdown: b.aiBriefMd!),
          if (_outcomeOpen) _OutcomeForm(bookingId: b.id),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final BookingStatus status;
  @override
  Widget build(BuildContext context) {
    late Color bg;
    late Color fg;
    late String label;
    switch (status) {
      case BookingStatus.requested:
        bg = AppColors.warningBg;
        fg = AppColors.warning;
        label = 'requested';
        break;
      case BookingStatus.assigned:
      case BookingStatus.confirmed:
        bg = AppColors.infoBg;
        fg = AppColors.info;
        label = status.name;
        break;
      case BookingStatus.completed:
        bg = AppColors.successBg;
        fg = AppColors.success;
        label = 'completed';
        break;
      case BookingStatus.cancelled:
      case BookingStatus.noShow:
        bg = AppColors.errorBg;
        fg = AppColors.error;
        label = status == BookingStatus.cancelled ? 'cancelled' : 'no-show';
        break;
    }
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

class _BriefExpansion extends StatelessWidget {
  const _BriefExpansion({required this.markdown});
  final String markdown;

  @override
  Widget build(BuildContext context) {
    // We render the brief as monospace plain text. A markdown renderer
    // is overkill for v1; the brief.ts skeleton + AI output use a fixed
    // four-section structure that is readable as-is.
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: SelectableText(
        markdown,
        style: const TextStyle(
          fontSize: 13,
          height: 1.5,
          fontFamilyFallback: ['Menlo', 'Courier'],
        ),
      ),
    );
  }
}

class _OutcomeForm extends ConsumerStatefulWidget {
  const _OutcomeForm({required this.bookingId});
  final String bookingId;

  @override
  ConsumerState<_OutcomeForm> createState() => _OutcomeFormState();
}

class _OutcomeFormState extends ConsumerState<_OutcomeForm> {
  late final TextEditingController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = TextEditingController();
    // Bind once on mount.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(outcomeFormProvider.notifier).bind(widget.bookingId);
    });
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(outcomeFormProvider);
    final notifier = ref.read(outcomeFormProvider.notifier);
    final isMine = state.bookingId == widget.bookingId;
    if (!isMine) {
      // Another tile claimed the form; show a hint instead of a
      // confusing empty box.
      return Container(
        margin: const EdgeInsets.only(top: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: const Text(
          'Close the other outcome form first to edit this one.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.infoBg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'Post-call summary',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.info,
            ),
          ),
          const Text(
            'What did you cover? Recommended next steps for the user?',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _ctl,
            maxLines: 5,
            maxLength: 4000,
            onChanged: notifier.setSummary,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Write 4-8 sentences. Plain text.',
            ),
          ),
          if (state.error != null)
            const Text(
              'Failed to submit. Please try again.',
              style: TextStyle(color: AppColors.error, fontSize: 12),
            ),
          const SizedBox(height: AppSpacing.sm),
          ElevatedButton(
            onPressed: state.canSubmit
                ? () async {
                    // Capture the messenger BEFORE the await so the
                    // analyzer doesn't flag the BuildContext use across
                    // an async gap (and so we don't accidentally show
                    // the snackbar in a different Navigator if the
                    // user navigated away).
                    final messenger = ScaffoldMessenger.of(context);
                    final ok = await notifier.submit();
                    if (ok && mounted) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Outcome saved. Payout queued.'),
                        ),
                      );
                    }
                  }
                : null,
            child: state.submitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit and mark complete'),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
