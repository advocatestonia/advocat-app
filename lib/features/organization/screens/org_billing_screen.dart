import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/feature_flags.dart';
import '../../../config/theme.dart';
import '../../../shared/widgets/advocat_gradient_header.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/max_width_wrapper.dart';
import '../models/organization.dart';
import '../providers/org_providers.dart';
import '../repositories/org_repository.dart';
import '../widgets/working_context_banner.dart';

/// Subscription, seats, invoices, payment method.
/// Spec: see FLUTTER_UI_SPEC.md §3.
class OrgBillingScreen extends ConsumerWidget {
  const OrgBillingScreen({super.key, required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgAsync = ref.watch(orgBySlugProvider(slug));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AdvocatGradientHeader(title: 'Billing'),
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
              if (!(org.myRole?.canManageBilling ?? false)) {
                return const EmptyState(
                  icon: Icons.lock_outline_rounded,
                  title: 'Billing is restricted',
                  description:
                      'Only the owner, admins, and the billing role can see this screen. '
                      'Ask your admin if you need access.',
                );
              }
              return _BillingBody(org: org);
            },
          ),
        ),
      ),
    );
  }
}

class _BillingBody extends ConsumerWidget {
  const _BillingBody({required this.org});
  final Organization org;

  Future<void> _openPortal(BuildContext context, WidgetRef ref) async {
    try {
      final url = await ref
          .read(orgRepositoryProvider)
          .startBillingPortal(org.id);
      await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication);
    } on OrgRepositoryException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open portal: ${e.code}')),
        );
      }
    }
  }

  Future<void> _changeSeats(
      BuildContext context, WidgetRef ref, int delta) async {
    final newCount = (org.seatCount + delta)
        .clamp(1, org.plan.seatLimit)
        .toInt();
    if (newCount == org.seatCount) return;
    try {
      await ref.read(orgRepositoryProvider).changeSeats(org.id, newCount);
      ref.invalidate(myOrgsProvider);
      ref.invalidate(orgBillingSummaryProvider(org.id));
    } on OrgRepositoryException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not change seats: ${e.code}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        const WorkingContextBanner(),
        const SizedBox(height: 16),
        if (org.isOnTrial) _TrialBanner(org: org),
        _PlanCard(org: org, onManage: () => _openPortal(context, ref)),
        const SizedBox(height: 16),
        // change-seats is not deployed yet — render the seats card
        // read-only (no +/- steppers) until the endpoint exists.
        _SeatsCard(
          org: org,
          onIncrement: kOrgPendingB2bEndpointsEnabled
              ? () => _changeSeats(context, ref, 1)
              : null,
          onDecrement: kOrgPendingB2bEndpointsEnabled
              ? () => _changeSeats(context, ref, -1)
              : null,
        ),
        const SizedBox(height: 16),
        _PaymentMethodCard(onManage: () => _openPortal(context, ref)),
        // org-invoices is not deployed yet — hide the whole section;
        // invoices remain available inside the Stripe portal.
        if (kOrgPendingB2bEndpointsEnabled) ...[
          const SizedBox(height: 16),
          const _SectionHeader(title: 'Invoices'),
          ref.watch(orgInvoicesProvider(org.id)).when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Could not load invoices: $e',
                  style: const TextStyle(color: AppColors.error)),
            ),
            data: (invoices) {
              if (invoices.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text(
                    'No invoices yet. The first will appear after your trial ends.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.textTertiary,
                    ),
                  ),
                );
              }
              return _InvoicesTable(invoices: invoices);
            },
          ),
        ],
      ],
    );
  }
}

class _TrialBanner extends StatelessWidget {
  const _TrialBanner({required this.org});
  final Organization org;

  @override
  Widget build(BuildContext context) {
    final days = org.trialDaysRemaining ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.accent, AppColors.accentDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          const Icon(Icons.celebration_outlined, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  days <= 0
                      ? 'Your trial has ended'
                      : 'Trial ends in $days day${days == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Add a payment method to keep your team going.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Colors.white70,
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

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.org, required this.onManage});
  final Organization org;
  final VoidCallback onManage;

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
          const Text(
            'Current plan',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '${org.plan.name[0].toUpperCase()}${org.plan.name.substring(1)} plan',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: org.status == OrgStatus.active
                      ? AppColors.successBg
                      : AppColors.warningBg,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  org.status.name.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: org.status == OrgStatus.active
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Change plan',
            variant: AppButtonVariant.secondary,
            onPressed: onManage,
            leadingIcon: Icons.swap_horiz_rounded,
          ),
        ],
      ),
    );
  }
}

class _SeatsCard extends StatelessWidget {
  const _SeatsCard({
    required this.org,
    required this.onIncrement,
    required this.onDecrement,
  });
  final Organization org;

  /// Null callbacks render the card read-only (steppers hidden) — used
  /// while the `change-seats` edge function is not deployed.
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  bool get _selfServe => onIncrement != null && onDecrement != null;

  @override
  Widget build(BuildContext context) {
    final canDecrement = org.seatCount > 1;
    final canIncrement = org.seatCount < org.plan.seatLimit;
    final total = org.plan.pricePerSeatMonthly * org.seatCount;
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
          const Text(
            'Seats',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (_selfServe) ...[
                IconButton.filled(
                  onPressed: canDecrement ? onDecrement : null,
                  icon: const Icon(Icons.remove_rounded),
                  style: IconButton.styleFrom(
                      backgroundColor: AppColors.surfaceVariant,
                      foregroundColor: AppColors.textPrimary),
                ),
                const SizedBox(width: 16),
              ],
              Text(
                '${org.seatCount}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              if (_selfServe) ...[
                const SizedBox(width: 16),
                IconButton.filled(
                  onPressed: canIncrement ? onIncrement : null,
                  icon: const Icon(Icons.add_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
              const Spacer(),
              Text(
                '€${total.toStringAsFixed(0)}/mo',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _selfServe
                ? '€${org.plan.pricePerSeatMonthly.toStringAsFixed(0)} per seat / month. Changes are prorated on your next invoice.'
                : '€${org.plan.pricePerSeatMonthly.toStringAsFixed(0)} per seat / month. To change seats, use "Manage in Stripe" below or contact support.',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({required this.onManage});
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.credit_card_outlined,
              color: AppColors.textSecondary),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Payment method',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          AppButton(
            label: 'Manage in Stripe',
            variant: AppButtonVariant.ghost,
            size: AppButtonSize.small,
            onPressed: onManage,
            trailingIcon: Icons.open_in_new_rounded,
          ),
        ],
      ),
    );
  }
}

class _InvoicesTable extends StatelessWidget {
  const _InvoicesTable({required this.invoices});
  final List<Map<String, dynamic>> invoices;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < invoices.length; i++) ...[
            ListTile(
              dense: true,
              leading: const Icon(Icons.receipt_long_outlined,
                  color: AppColors.textSecondary),
              title: Text(
                invoices[i]['number']?.toString() ?? 'Invoice',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                invoices[i]['created_at']?.toString() ?? '',
                style: const TextStyle(fontSize: 11),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '€${invoices[i]['amount'] ?? '0'}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.download_rounded, size: 18),
                    onPressed: () {
                      final url = invoices[i]['hosted_invoice_url'] as String?;
                      if (url != null) {
                        launchUrl(Uri.parse(url),
                            mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                ],
              ),
            ),
            if (i < invoices.length - 1)
              const Divider(height: 1, color: AppColors.border),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.7,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}
