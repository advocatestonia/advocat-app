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

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() =>
      _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen>
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
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                // ── Current Plan Indicator ──────────────────────────────
                _CurrentPlanBanner(tier: currentTier),

                const SizedBox(height: AppSpacing.lg),

                // ── Annual Toggle ──────────────────────────────────────
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
                          borderRadius:
                              BorderRadius.circular(AppRadius.full),
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

                // ── Plan Cards ─────────────────────────────────────────
                _StaggeredPlanCard(
                  index: 0,
                  child: _PlanCard(
                    planId: 'free',
                    title: l10n.emergencyShield,
                    tierLabel: 'FREE',
                    monthlyPrice: 0,
                    annualPrice: 0,
                    isAnnual: isAnnual,
                    isCurrent: currentTier == SubscriptionTier.free,
                    isLoading: loadingPlan == 'free',
                    features: [
                      _Feature(l10n.fiveAiMessagesTotal, true),
                      _Feature(l10n.oneCaseActive, true),
                      _Feature(l10n.threeDocScans, true),
                      _Feature(l10n.basicAiAnalysis, true),
                      _Feature(l10n.draftGeneration, false),
                      _Feature(l10n.voiceInput, false),
                    ],
                    onSelect: currentTier == SubscriptionTier.free
                        ? null
                        : () => _handlePlanSelect(context, ref, 'free'),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                _StaggeredPlanCard(
                  index: 1,
                  child: _PlanCard(
                    planId: 'basic',
                    title: l10n.legalFighter,
                    tierLabel: 'COUNSEL',
                    monthlyPrice: 14.99,
                    annualPrice: 119.99,
                    isAnnual: isAnnual,
                    isCurrent: currentTier == SubscriptionTier.basic,
                    isLoading: loadingPlan == 'basic',
                    isPopular: true,
                    foundingMemberNote: l10n.foundingMemberNote,
                    features: [
                      _Feature(l10n.hundredAiMessagesDay, true),
                      _Feature(l10n.threeCasesActive, true),
                      _Feature(l10n.twentyDocScans, true),
                      _Feature(l10n.fullAiAnalysis, true),
                      _Feature(l10n.draftGeneration, true),
                      _Feature(l10n.emailIntegrationTitle, true),
                      _Feature(l10n.voiceInput, true),
                      _Feature(l10n.priorityProcessing, false),
                    ],
                    onSelect: currentTier == SubscriptionTier.basic
                        ? null
                        : () => _handlePlanSelect(context, ref, 'basic'),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                _StaggeredPlanCard(
                  index: 2,
                  child: _PlanCard(
                    planId: 'premium',
                    title: l10n.fullDefense,
                    tierLabel: 'PRO',
                    monthlyPrice: 29.99,
                    annualPrice: 249.99,
                    isAnnual: isAnnual,
                    isCurrent: currentTier == SubscriptionTier.premium,
                    isLoading: loadingPlan == 'premium',
                    isPremium: true,
                    accentColor: AppColors.primary,
                    features: [
                      _Feature(l10n.unlimitedAiMessages, true),
                      _Feature(l10n.unlimitedCases, true),
                      _Feature(l10n.unlimitedDocScans, true),
                      _Feature(l10n.fullAiAnalysis, true),
                      _Feature(l10n.draftGeneration, true),
                      _Feature(l10n.emailIntegrationTitle, true),
                      _Feature(l10n.voiceInput, true),
                      _Feature(l10n.priorityProcessing, true),
                      _Feature(l10n.strategyRecommendations, true),
                    ],
                    onSelect: currentTier == SubscriptionTier.premium
                        ? null
                        : () => _handlePlanSelect(context, ref, 'premium'),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // ── Restore Purchases ──────────────────────────────────
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
      await Future<void>.delayed(const Duration(seconds: 2));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context)
                        ?.successSubscribed(planId.toUpperCase()) ??
                    'Successfully subscribed to ${planId.toUpperCase()}!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context)?.paymentFailed(e.toString()) ??
                    'Payment failed: $e'),
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

// ── Staggered plan card animation ───────────────────────────────────────

class _StaggeredPlanCard extends StatefulWidget {
  const _StaggeredPlanCard({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  State<_StaggeredPlanCard> createState() => _StaggeredPlanCardState();
}

class _StaggeredPlanCardState extends State<_StaggeredPlanCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    final delay = Duration(milliseconds: 200 + widget.index * 120);
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────

class _CurrentPlanBanner extends StatefulWidget {
  const _CurrentPlanBanner({required this.tier});
  final SubscriptionTier tier;

  @override
  State<_CurrentPlanBanner> createState() => _CurrentPlanBannerState();
}

class _CurrentPlanBannerState extends State<_CurrentPlanBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  String _label(AppLocalizations l10n) => switch (widget.tier) {
        SubscriptionTier.free => l10n.emergencyShield,
        SubscriptionTier.basic => l10n.legalFighter,
        SubscriptionTier.premium => l10n.fullDefense,
      };

  String get _tierText => widget.tier.name.toUpperCase();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
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
            boxShadow: [
              BoxShadow(
                color: AppColors.primary
                    .withValues(alpha: 0.25 + 0.10 * _glowAnimation.value),
                blurRadius: 16 + 8 * _glowAnimation.value,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        );
      },
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

class _PlanCard extends StatefulWidget {
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
    this.isPremium = false,
    this.accentColor,
    this.foundingMemberNote,
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
  final bool isPremium;
  final List<_Feature> features;
  final VoidCallback? onSelect;
  final Color? accentColor;
  final String? foundingMemberNote;

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard>
    with TickerProviderStateMixin {
  // Premium glow animation
  AnimationController? _glowController;
  Animation<double>? _glowAnimation;

  // Price counter animation
  late final AnimationController _priceController;
  late final Animation<double> _priceAnimation;

  @override
  void initState() {
    super.initState();

    _priceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _priceAnimation = CurvedAnimation(
      parent: _priceController,
      curve: Curves.easeOut,
    );
    _priceController.forward();

    if (widget.isPremium) {
      _glowController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2500),
      )..repeat(reverse: true);
      _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _glowController!, curve: Curves.easeInOut),
      );
    }
  }

  @override
  void didUpdateWidget(_PlanCard old) {
    super.didUpdateWidget(old);
    if (old.isAnnual != widget.isAnnual) {
      _priceController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _glowController?.dispose();
    _priceController.dispose();
    super.dispose();
  }

  String _priceText(AppLocalizations l10n) {
    if (widget.monthlyPrice == 0) return l10n.free;
    final price = widget.isAnnual ? widget.annualPrice : widget.monthlyPrice;
    return '\u20AC${price.toStringAsFixed(2)}';
  }

  String _periodText(AppLocalizations l10n) {
    if (widget.monthlyPrice == 0) return l10n.forever;
    return widget.isAnnual ? l10n.perYear : l10n.perMonth;
  }

  Color get _borderColor {
    if (widget.isCurrent) return AppColors.accent;
    if (widget.isPopular) return AppColors.accent;
    if (widget.isPremium) return AppColors.primary;
    return AppColors.border;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    Widget card = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: _borderColor,
          width: (widget.isCurrent || widget.isPopular || widget.isPremium)
              ? 2
              : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Badge row ──────────────────────────────────────────────
          if (widget.isPopular || widget.isCurrent)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: widget.isCurrent
                    ? AppColors.accent
                    : AppColors.accent.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg - 1),
                ),
              ),
              child: Text(
                widget.isCurrent
                    ? l10n.currentPlan.toUpperCase()
                    : l10n.mostPopular,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color:
                      widget.isCurrent ? Colors.white : AppColors.accent,
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
                        color: (widget.accentColor ?? AppColors.accent)
                            .withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        widget.tierLabel,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color:
                              widget.accentColor ?? AppColors.accent,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                // ── Price (animated) ─────────────────────────────────
                FadeTransition(
                  opacity: _priceAnimation,
                  child: Row(
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
                ),

                if (widget.foundingMemberNote != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3CD),
                      borderRadius:
                          BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                        color: const Color(0xFFD69E2E)
                            .withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Color(0xFFD69E2E),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.foundingMemberNote!,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF92620E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.md),
                const Divider(color: AppColors.border),
                const SizedBox(height: AppSpacing.md),

                // ── Features (staggered) ─────────────────────────────
                ...List.generate(widget.features.length, (i) {
                  final f = widget.features[i];
                  return _StaggeredFeatureRow(
                    index: i,
                    child: Padding(
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
                                : AppColors.textTertiary
                                    .withValues(alpha: 0.5),
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
                  );
                }),

                const SizedBox(height: AppSpacing.md),

                // ── Action button ────────────────────────────────────
                AppButton(
                  label: widget.isCurrent
                      ? l10n.currentPlan
                      : l10n.choosePlan,
                  variant: widget.isCurrent
                      ? AppButtonVariant.secondary
                      : AppButtonVariant.primary,
                  isFullWidth: true,
                  isLoading: widget.isLoading,
                  onPressed: widget.isCurrent ? null : widget.onSelect,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // Premium golden glow wrapper
    if (widget.isPremium && _glowAnimation != null) {
      card = AnimatedBuilder(
        animation: _glowAnimation!,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD69E2E)
                      .withValues(alpha: 0.12 + 0.10 * _glowAnimation!.value),
                  blurRadius: 16 + 8 * _glowAnimation!.value,
                  spreadRadius: 1 * _glowAnimation!.value,
                ),
              ],
            ),
            child: child,
          );
        },
        child: card,
      );
    }

    return card;
  }
}

// ── Staggered feature row animation ─────────────────────────────────────

class _StaggeredFeatureRow extends StatefulWidget {
  const _StaggeredFeatureRow({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  State<_StaggeredFeatureRow> createState() => _StaggeredFeatureRowState();
}

class _StaggeredFeatureRowState extends State<_StaggeredFeatureRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    final delay = Duration(milliseconds: 400 + widget.index * 60);
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
