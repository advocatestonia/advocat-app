import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.subscription),
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
                  Text(
                    AppLocalizations.of(context)!.monthly,
                    style: const TextStyle(
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
                  Text(
                    AppLocalizations.of(context)!.annual,
                    style: const TextStyle(
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
                    child: Text(
                      AppLocalizations.of(context)!.saveTwentyFivePercent,
                      style: const TextStyle(
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
              title: l10n.emergencyShield,
              tierLabel: 'FREE',
              monthlyPrice: 0,
              annualPrice: 0,
              isAnnual: isAnnual,
              isCurrent: currentTier == SubscriptionTier.free,
              isLoading: loadingPlan == 'free',
              features: [
                _Feature(l10n.oneCaseActive, true),
                _Feature(l10n.threeDocScans, true),
                _Feature(l10n.basicAiAnalysis, true),
                _Feature(l10n.emailIntegrationTitle, false),
                _Feature(l10n.fullAiAnalysis, false),
                _Feature(l10n.priorityProcessing, false),
              ],
              onSelect: currentTier == SubscriptionTier.free
                  ? null
                  : () => _handlePlanSelect(context, ref, 'free'),
            ),

            const SizedBox(height: AppSpacing.md),

            _PlanCard(
              planId: 'basic',
              title: l10n.legalFighter,
              tierLabel: 'BASIC',
              monthlyPrice: 9.99,
              annualPrice: 89.99,
              isAnnual: isAnnual,
              isCurrent: currentTier == SubscriptionTier.basic,
              isLoading: loadingPlan == 'basic',
              isPopular: true,
              features: [
                _Feature(l10n.threeCasesActive, true),
                _Feature(l10n.twentyDocScans, true),
                _Feature(l10n.fullAiAnalysis, true),
                _Feature(l10n.emailIntegrationTitle, true),
                _Feature(l10n.draftGeneration, true),
                _Feature(l10n.priorityProcessing, false),
              ],
              onSelect: currentTier == SubscriptionTier.basic
                  ? null
                  : () => _handlePlanSelect(context, ref, 'basic'),
            ),

            const SizedBox(height: AppSpacing.md),

            _PlanCard(
              planId: 'premium',
              title: l10n.fullDefense,
              tierLabel: 'PRO',
              monthlyPrice: 29.99,
              annualPrice: 269.99,
              isAnnual: isAnnual,
              isCurrent: currentTier == SubscriptionTier.premium,
              isLoading: loadingPlan == 'premium',
              accentColor: AppColors.primary,
              features: [
                _Feature(l10n.unlimitedCases, true),
                _Feature(l10n.unlimitedDocScans, true),
                _Feature(l10n.fullAiAnalysis, true),
                _Feature(l10n.emailIntegrationTitle, true),
                _Feature(l10n.draftGeneration, true),
                _Feature(l10n.priorityProcessing, true),
              ],
              onSelect: currentTier == SubscriptionTier.premium
                  ? null
                  : () => _handlePlanSelect(context, ref, 'premium'),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Restore Purchases ────────────────────────────────────────
            TextButton(
              onPressed: () => _handleRestore(context, ref),
              child: Text(
                l10n.restorePurchases,
                style: const TextStyle(
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
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.checkingPurchases)),
    );
    // TODO: Call Stripe or RevenueCat restore
    await Future<void>.delayed(const Duration(seconds: 1));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noPreviousPurchases)),
      );
    }
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────

class _CurrentPlanBanner extends StatelessWidget {
  const _CurrentPlanBanner({required this.tier});
  final SubscriptionTier tier;

  String _label(AppLocalizations l10n) => switch (tier) {
        SubscriptionTier.free => l10n.emergencyShield,
        SubscriptionTier.basic => l10n.legalFighter,
        SubscriptionTier.premium => l10n.fullDefense,
      };

  String get _tierText => tier.name.toUpperCase();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
          Text(
            l10n.currentPlan,
            style: const TextStyle(
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
            _label(l10n),
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

  String _priceText(AppLocalizations l10n) {
    if (monthlyPrice == 0) return l10n.free;
    final price = isAnnual ? annualPrice : monthlyPrice;
    return '\u20AC${price.toStringAsFixed(2)}';
  }

  String _periodText(AppLocalizations l10n) {
    if (monthlyPrice == 0) return l10n.forever;
    return isAnnual ? l10n.perYear : l10n.perMonth;
  }

  Color get _borderColor {
    if (isCurrent) return AppColors.accent;
    if (isPopular) return AppColors.accent;
    return AppColors.border;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                isCurrent ? l10n.currentPlan.toUpperCase() : l10n.mostPopular,
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
                      _priceText(l10n),
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
                        _periodText(l10n),
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
                  label: isCurrent ? l10n.currentPlan : l10n.choosePlan,
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
