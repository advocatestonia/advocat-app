// lib/features/lawyer_partnership/screens/book_lawyer_call_screen.dart
// -----------------------------------------------------------------------------
// "Book a 15-min call with a partner lawyer" screen (Day2-E user flow).
//
// Five panels stacked vertically:
//
//   1. Hero/quota banner       — "You have 1 call left this quarter."
//   2. Topic chips             — immigration / contract / family / ...
//   3. Slot picker             — simple discrete slot picker (we deliberately
//                                do not integrate Cal.com in v1 — see report).
//   4. Brief textarea          — "What do you want to cover?"
//   5. Partner pick (optional) — directory cards; "any available" default.
//
// The flow:
//   * If `kLawyerPartnershipEnabled == false`, the screen renders a single
//     "coming soon" card instead of the form (so a leaked deep-link from
//     a flag-on internal build never charges the user against a non-
//     existent provider pool).
//
//   * Quota check is server-authoritative; we display the cached value
//     for UX but submit anyway — server returns 429/quota_exhausted if
//     racey.
//
//   * Submission result swaps the form for a result card. On success we
//     show the AI brief preview + the next-steps timeline ("we'll email
//     a Google Meet link 24h before").
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/feature_flags.dart';
import '../../../config/theme.dart';
import '../models/lawyer_partnership_state.dart';
import '../state/lawyer_partnership_providers.dart';

class BookLawyerCallScreen extends ConsumerWidget {
  const BookLawyerCallScreen({super.key, this.caseId});

  static const String routePath = '/book-lawyer';
  static const String routeName = 'bookLawyerCall';

  /// Optional caseId — if the user opened the screen from a case workspace,
  /// the booking is pre-bound to that case (so the AI brief loads facts).
  final String? caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Book a lawyer call'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: kLawyerPartnershipEnabled
            ? _LiveFlow(caseId: caseId)
            : const _ComingSoonCard(),
      ),
    );
  }
}

// ─── Flag-off placeholder ───────────────────────────────────────────────────

class _ComingSoonCard extends StatelessWidget {
  const _ComingSoonCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.infoBg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.event_available_outlined,
                color: AppColors.info, size: 32),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Human lawyer calls — opening soon',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.info,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Pro and Premium include 15-minute calls with a partner '
              'lawyer (1/quarter on Pro, 2/quarter on Premium). We are '
              'finalising the EE solo-practitioner pool and will email '
              'you the moment booking opens.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Live flow ──────────────────────────────────────────────────────────────

class _LiveFlow extends ConsumerStatefulWidget {
  const _LiveFlow({this.caseId});
  final String? caseId;

  @override
  ConsumerState<_LiveFlow> createState() => _LiveFlowState();
}

class _LiveFlowState extends ConsumerState<_LiveFlow> {
  @override
  void initState() {
    super.initState();
    if (widget.caseId != null) {
      // Bind the caseId into the form on mount (after first frame so we
      // don't mutate the notifier during build).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(bookingFormProvider.notifier)
            .setCaseId(widget.caseId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final submitState = ref.watch(bookingSubmitProvider);
    if (submitState is BookingSubmitDone) {
      return _BookingResultCard(outcome: submitState.outcome);
    }
    final quotaAsync = ref.watch(bookingQuotaProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          quotaAsync.when(
            loading: () => const _QuotaSkeleton(),
            error: (_, __) => const SizedBox.shrink(),
            data: (quota) => _QuotaBanner(quota: quota),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _TopicChips(),
          const SizedBox(height: AppSpacing.lg),
          const _SlotPicker(),
          const SizedBox(height: AppSpacing.lg),
          const _UserBriefField(),
          const SizedBox(height: AppSpacing.lg),
          const _SubmitButton(),
        ],
      ),
    );
  }
}

// ─── Quota banner ───────────────────────────────────────────────────────────

class _QuotaSkeleton extends StatelessWidget {
  const _QuotaSkeleton();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _QuotaBanner extends StatelessWidget {
  const _QuotaBanner({required this.quota});
  final BookingQuota quota;

  @override
  Widget build(BuildContext context) {
    final canBook = quota.canBook;
    final bgColor = canBook ? AppColors.successBg : AppColors.warningBg;
    final fgColor = canBook ? AppColors.success : AppColors.warning;
    final icon = canBook ? Icons.event_available : Icons.event_busy;
    final title = canBook
        ? 'You have ${quota.remaining} of ${quota.quotaTotal} call(s) left this quarter.'
        : 'Quarterly quota used.';
    final body = canBook
        ? 'Pro tier includes 1 call/quarter, Premium 2. Calls last 15 minutes, by Google Meet.'
        : 'Your quota resets on the first day of next quarter. Need to talk sooner? Upgrade to Premium for an extra call.';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: fgColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: fgColor),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: fgColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Topic chips ────────────────────────────────────────────────────────────

class _TopicChips extends ConsumerWidget {
  const _TopicChips();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(bookingFormProvider);
    final ctl = ref.read(bookingFormProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'What is the call about?',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: BookingTopic.values.map((t) {
            final selected = form.topic == t;
            return ChoiceChip(
              label: Text(t.label),
              selected: selected,
              onSelected: (_) => ctl.setTopic(t),
            );
          }).toList(),
        ),
        if (form.topic == BookingTopic.other) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            initialValue: form.freeFormTopic,
            decoration: const InputDecoration(
              labelText: 'Briefly: what topic?',
              border: OutlineInputBorder(),
            ),
            maxLength: 100,
            onChanged: ctl.setFreeFormTopic,
          ),
        ],
      ],
    );
  }
}

// ─── Slot picker (deliberately simple — v1 uses time-preference text) ──────

class _SlotPicker extends ConsumerWidget {
  const _SlotPicker();

  /// Generate the next 7 days × 2 slots (10:00 + 14:00 EET) as a starting
  /// point. The owner can wire Cal.com later — for v1 the chip grid is
  /// good enough and avoids the OAuth + webhook plumbing cost.
  List<DateTime> _candidateSlots() {
    final out = <DateTime>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (var d = 1; d <= 7; d++) {
      final day = today.add(Duration(days: d));
      // Skip Sundays.
      if (day.weekday == DateTime.sunday) continue;
      out.add(DateTime(day.year, day.month, day.day, 10));
      out.add(DateTime(day.year, day.month, day.day, 14));
    }
    return out;
  }

  String _labelFor(DateTime ts) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hh = ts.hour.toString().padLeft(2, '0');
    final mm = ts.minute.toString().padLeft(2, '0');
    return '${ts.day} ${months[ts.month - 1]} · $hh:$mm';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(bookingFormProvider);
    final ctl = ref.read(bookingFormProvider.notifier);
    final slots = _candidateSlots();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Pick a slot',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const Text(
          '15-minute call. The lawyer confirms within 4h.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: slots.map((s) {
            final selected = form.scheduledAt == s;
            return ChoiceChip(
              label: Text(_labelFor(s)),
              selected: selected,
              onSelected: (_) => ctl.setScheduledAt(s),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          initialValue: form.timePreference,
          decoration: const InputDecoration(
            labelText:
                'Or describe your availability (e.g. "weekday mornings")',
            border: OutlineInputBorder(),
          ),
          maxLength: 200,
          onChanged: ctl.setTimePreference,
        ),
      ],
    );
  }
}

// ─── User brief textarea ────────────────────────────────────────────────────

class _UserBriefField extends ConsumerWidget {
  const _UserBriefField();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(bookingFormProvider);
    final ctl = ref.read(bookingFormProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'What do you want to cover?',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const Text(
          'We send this + an AI-generated brief to the lawyer 2h before '
          'the call. Specific facts > vague worries.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          initialValue: form.userBrief,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText:
                'e.g. "Landlord refuses to return the deposit (€700) "\n'
                '"after I moved out 4 weeks ago. I have email proof of move-out date."',
          ),
          maxLines: 6,
          maxLength: 4000,
          onChanged: ctl.setUserBrief,
        ),
      ],
    );
  }
}

// ─── Submit button ──────────────────────────────────────────────────────────

class _SubmitButton extends ConsumerWidget {
  const _SubmitButton();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(bookingFormProvider);
    final submitState = ref.watch(bookingSubmitProvider);
    final quotaAsync = ref.watch(bookingQuotaProvider);
    final submitting = submitState is BookingSubmitInFlight;
    final canBook = quotaAsync.maybeWhen(
      data: (q) => q.canBook,
      orElse: () => true,
    );
    final enabled = !submitting && form.isComplete && canBook;
    return ElevatedButton(
      onPressed: enabled
          ? () => ref.read(bookingSubmitProvider.notifier).submit()
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      child: submitting
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
          : const Text(
              'Request the call',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
    );
  }
}

// ─── Result card ────────────────────────────────────────────────────────────

class _BookingResultCard extends ConsumerWidget {
  const _BookingResultCard({required this.outcome});
  final BookingOutcome outcome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (outcome is BookingCreated) {
      final created = outcome as BookingCreated;
      return _SuccessCard(
        booking: created.booking,
        quotaRemaining: created.quotaRemaining,
        onReset: () {
          ref.read(bookingSubmitProvider.notifier).reset();
          ref.read(bookingFormProvider.notifier).reset();
        },
      );
    }
    final rejected = outcome as BookingRejected;
    return _RejectedCard(
      reasonCode: rejected.reasonCode,
      message: rejected.message,
      onRetry: () => ref.read(bookingSubmitProvider.notifier).reset(),
    );
  }
}

class _SuccessCard extends StatelessWidget {
  const _SuccessCard({
    required this.booking,
    required this.quotaRemaining,
    required this.onReset,
  });
  final LawyerBooking booking;
  final int quotaRemaining;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.successBg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(Icons.check_circle_outline,
                color: AppColors.success, size: 32),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Booking received',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Topic: ${booking.topic}\n'
              'Slot: ${booking.scheduledAt == null ? "to be confirmed" : booking.scheduledAt!.toLocal().toString().substring(0, 16)}\n'
              'Quota left this quarter: $quotaRemaining',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Next:\n'
              '  • A partner lawyer confirms within 4 hours.\n'
              '  • We email you a Google Meet link 24 hours before.\n'
              '  • An AI brief is sent to the lawyer 2 hours before.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: onReset,
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RejectedCard extends StatelessWidget {
  const _RejectedCard({
    required this.reasonCode,
    required this.onRetry,
    this.message,
  });
  final String reasonCode;
  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final friendly = _friendlyReason(reasonCode, message);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.errorBg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(Icons.error_outline, color: AppColors.error, size: 32),
            const SizedBox(height: AppSpacing.sm),
            Text(
              friendly,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  static String _friendlyReason(String code, String? message) {
    switch (code) {
      case 'upgrade_required':
        return 'Lawyer calls are included on Pro and Premium tiers. '
            'Upgrade in Settings to book one.';
      case 'quota_exhausted':
        return 'You have used all your lawyer calls for this quarter. '
            'They reset on the first day of next quarter.';
      case 'lawyer_unavailable':
        return 'The selected lawyer is not currently available. '
            'Try choosing another partner or leave the selection blank.';
      case 'lawyer_not_found':
        return 'The selected lawyer was not found in our partner directory.';
      case 'scheduled_in_past':
        return 'The slot you picked is in the past. Please pick a later slot.';
      case 'scheduled_too_far':
        return 'We only book up to 60 days ahead.';
      case 'program_disabled':
        return 'The lawyer-call program is currently paused. '
            'Please check back later.';
      case 'incomplete_form':
        return 'Please pick a topic and either a slot or a time preference, '
            'and (optionally) describe what you want to cover.';
      default:
        return message ??
            'Something went wrong. Please try again or write to '
                'support@advocat.ee.';
    }
  }
}
