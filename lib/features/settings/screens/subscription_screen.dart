import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../models/user.dart';
import '../../../shared/constants/app_icons.dart';
import '../../../shared/widgets/app_button.dart';
import '../../auth/providers/auth_provider.dart';

// ── Providers ────────────────────────────────────────────────────────────

final _isAnnualProvider = StateProvider<bool>((ref) => false);
final _isLoadingPlanProvider = StateProvider<String?>((ref) => null);

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final currentTier =
        userAsync.whenOrNull(data: (u) => u?.subscriptionTier) ??
            SubscriptionTier.free;
    final isAnnual = ref.watch(_isAnnualProvider);
    final loadingPlan = ref.watch(_isLoadingPlanProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Subscription'),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            // ── Current Plan Indicator ────────────────────────────────────
            _CurrentPlanBanner(tier: currentTier),

            const SizedBox(height: AppSpacing.lg),

            // ── Annual Toggle ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Monthly',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Switch.adaptive(
                    value: isAnnual,
                    onChanged: (v) =>
                        ref.read(_isAnnualProvider.notifier).state = v,
                    activeTrackColor: AppColors.accent,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Text(
                    'Annual',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: const Text(
                      'Save 25%',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Plan Cards ───────────────────────────────────────────────
            _PlanCard(
              planId: 'free',
              title: 'Emergency Shield',
              tierLabel: 'FREE',
              monthlyPrice: 0,
              annualPrice: 0,
              isAnnual: isAnnual,
              isCurrent: currentTier == SubscriptionTier.free,
              isLoading: loadingPlan == 'free',
              features: const [
                _Feature('1 active case', true),
                _Feature('3 document scans', true),
                _Feature('Basic AI analysis', true),
                _Feature('Email integration', false),
                _Feature('Full analysis & drafts', false),
                _Feature('Priority processing', false),
              ],
              onSelect: currentTier == SubscriptionTier.free
                  ? null
                  : () => _handlePlanSelect(context, ref, 'free'),
            ),

            const SizedBox(height: AppSpacing.md),

            _PlanCard(
              planId: 'basic',
              title: 'Legal Fighter',
              tierLabel: 'BASIC',
              monthlyPrice: 9.99,
              annualPrice: 89.99,
              isAnnual: isAnnual,
              isCurrent: currentTier == SubscriptionTier.basic,
              isLoading: loadingPlan == 'basic',
              isPopular: true,
              features: const [
                _Feature('3 active cases', true),
                _Feature('20 document scans', true),
                _Feature('Full AI analysis', true),
                _Feature('Email integration', true),
                _Feature('Draft generation', true),
                _Feature('Priority processing', false),
              ],
              onSelect: currentTier == SubscriptionTier.basic
                  ? null
                  : () => _handlePlanSelect(context, ref, 'basic'),
            ),

            const SizedBox(height: AppSpacing.md),

            _PlanCard(
              planId: 'premium',
              title: 'Full Defense',
              tierLabel: 'PRO',
              monthlyPrice: 29.99,
              annualPrice: 269.99,
              isAnnual: isAnnual,
              isCurrent: currentTier == SubscriptionTier.premium,
              isLoading: loadingPlan == 'premium',
              accentColor: AppColors.primary,
              features: const [
                _Feature('Unlimited cases', true),
                _Feature('Unlimited document scans', true),
                _Feature('Full AI analysis', true),
                _Feature('Email integration', true),
                _Feature('Draft generation', true),
                _Feature('Priority processing', true),
              ],
              onSelect: currentTier == SubscriptionTier.premium
                  ? null
                  : () => _handlePlanSelect(context, ref, 'premium'),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Restore Purchases ────────────────────────────────────────
            TextButton(
              onPressed: () => _handleRestore(context, ref),
              child: const Text(
                'Restore Purchases',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  // ── Handlers ─────────────────────────────────────────────────────────

  Future<void> _handlePlanSelect(
    BuildContext context,
    WidgetRef ref,
    String planId,
  ) async {
    ref.read(_isLoadingPlanProvider.notifier).state = planId;

    try {
      // TODO: Open Stripe checkout session or in-app payment sheet.
      // For now simulate a short delay.
      await Future<void>.delayed(const Duration(seconds: 2));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully subscribed to ${planId.toUpperCase()}!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      ref.read(_isLoadingPlanProvider.notifier).state = null;
    }
  }

  Future<void> _handleRestore(BuildContext context, WidgetRef ref) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Checking for previous purchases...')),
    );
    // TODO: Call Stripe or RevenueCat restore
    await Future<void>.delayed(const Duration(seconds: 1));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No previous purchases found.')),
      );
    }
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────

class _CurrentPlanBanner extends StatelessWidget {
  const _CurrentPlanBanner({required this.tier});
  final SubscriptionTier tier;

  String get _label => switch (tier) {
        SubscriptionTier.free => 'Emergency Shield',
        SubscriptionTier.basic => 'Legal Fighter',
        SubscriptionTier.premium => 'Full Defense',
      };

  String get _tierText => tier.name.toUpperCase();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          const Text(
            'Current Plan',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _tierText,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }
}

class _Feature {
  const _Feature(this.text, this.included);
  final String text;
  final bool included;
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.planId,
    required this.title,
    required this.tierLabel,
    required this.monthlyPrice,
    required this.annualPrice,
    required this.isAnnual,
    required this.isCurrent,
    required this.isLoading,
    required this.features,
    required this.onSelect,
    this.isPopular = false,
    this.accentColor,
  });

  final String planId;
  final String title;
  final String tierLabel;
  final double monthlyPrice;
  final double annualPrice;
  final bool isAnnual;
  final bool isCurrent;
  final bool isLoading;
  final bool isPopular;
  final List<_Feature> features;
  final VoidCallback? onSelect;
  final Color? accentColor;

  String get _priceText {
    if (monthlyPrice == 0) return 'Free';
    final price = isAnnual ? annualPrice : monthlyPrice;
    return '\u20AC${price.toStringAsFixed(2)}';
  }

  String get _periodText {
    if (monthlyPrice == 0) return 'forever';
    return isAnnual ? '/year' : '/month';
  }

  Color get _borderColor {
    if (isCurrent) return AppColors.accent;
    if (isPopular) return AppColors.accent;
    return AppColors.border;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: _borderColor,
          width: (isCurrent || isPopular) ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Badge row ────────────────────────────────────────────────
          if (isPopular || isCurrent)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isCurrent
                    ? AppColors.accent
                    : AppColors.accent.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg - 1),
                ),
              ),
              child: Text(
                isCurrent ? 'CURRENT PLAN' : 'MOST POPULAR',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isCurrent ? Colors.white : AppColors.accent,
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Tier label + title ─────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (accentColor ?? AppColors.accent)
                            .withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        tierLabel,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: accentColor ?? AppColors.accent,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                // ── Price ──────────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _priceText,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        _periodText,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),
                const Divider(color: AppColors.border),
                const SizedBox(height: AppSpacing.md),

                // ── Features ───────────────────────────────────────────
                ...features.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          f.included
                              ? AppIcons.checkCircle
                              : Icons.cancel_rounded,
                          size: 18,
                          color: f.included
                              ? AppColors.accent
                              : AppColors.textTertiary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            f.text,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: f.included
                                  ? AppColors.textPrimary
                                  : AppColors.textTertiary,
                              decoration: f.included
                                  ? null
                                  : TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // ── Action button ──────────────────────────────────────
                AppButton(
                  label: isCurrent ? 'Current Plan' : 'Choose Plan',
                  variant: isCurrent
                      ? AppButtonVariant.secondary
                      : AppButtonVariant.primary,
                  isFullWidth: true,
                  isLoading: isLoading,
                  onPressed: isCurrent ? null : onSelect,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
