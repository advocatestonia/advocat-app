import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/user.dart';
import '../../../services/stripe_checkout_service.dart';
import '../../../shared/constants/app_icons.dart';
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

  late final PageController _pageController;

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
    _entranceController.forward();

    // Start on the middle (recommended) card
    _pageController = PageController(
      viewportFraction: 0.85,
      initialPage: 1,
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pageController.dispose();
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

    final plans = _buildPlans(l10n, currentTier, isAnnual, loadingPlan);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.subscription),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            const SizedBox(height: 16),

            // ── Current Plan Compact ─────────────────────────────────
            _CompactCurrentPlan(tier: currentTier),

            const SizedBox(height: 16),

            // ── Annual / Monthly Toggle ──────────────────────────────
            _BillingToggle(
              isAnnual: isAnnual,
              onChanged: (v) =>
                  ref.read(_isAnnualProvider.notifier).state = v,
            ),

            const SizedBox(height: 16),

            // ── Horizontal Plan Cards (PageView) ─────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: plans.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  return _StaggeredPlanCard(
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      child: plans[index],
                    ),
                  );
                },
              ),
            ),

            // ── Page Indicator ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _PageIndicator(
                controller: _pageController,
                count: plans.length,
              ),
            ),

            // ── Restore Purchases ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextButton(
                onPressed: () => _handleRestore(context, ref),
                child: Text(
                  l10n.restorePurchases,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPlans(
    AppLocalizations l10n,
    SubscriptionTier currentTier,
    bool isAnnual,
    String? loadingPlan,
  ) {
    return [
      // Free tier
      _PlanCard(
        planId: 'free',
        title: l10n.emergencyShield,
        tierLabel: 'FREE',
        monthlyPrice: 0,
        annualPrice: 0,
        isAnnual: isAnnual,
        isCurrent: currentTier == SubscriptionTier.free,
        isLoading: loadingPlan == 'free',
        cardStyle: _CardStyle.free,
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

      // Legal Counsel (recommended)
      _PlanCard(
        planId: 'basic',
        title: l10n.legalFighter,
        tierLabel: 'COUNSEL',
        monthlyPrice: 14.99,
        annualPrice: 119.99,
        isAnnual: isAnnual,
        isCurrent: currentTier == SubscriptionTier.basic,
        isLoading: loadingPlan == 'basic',
        isRecommended: true,
        cardStyle: _CardStyle.recommended,
        foundingMemberNote: l10n.foundingMemberNote,
        features: [
          _Feature(l10n.hundredAiMessagesDay, true),
          _Feature(l10n.threeCasesActive, true),
          _Feature(l10n.twentyDocScans, true),
          _Feature(l10n.fullAiAnalysis, true),
          _Feature(l10n.draftGeneration, true),
          _Feature(l10n.voiceInput, true),
        ],
        onSelect: currentTier == SubscriptionTier.basic
            ? null
            : () => _handlePlanSelect(context, ref, 'basic'),
      ),

      // Full Representation (premium)
      _PlanCard(
        planId: 'premium',
        title: l10n.fullDefense,
        tierLabel: 'PRO',
        monthlyPrice: 29.99,
        annualPrice: 249.99,
        isAnnual: isAnnual,
        isCurrent: currentTier == SubscriptionTier.premium,
        isLoading: loadingPlan == 'premium',
        cardStyle: _CardStyle.premium,
        features: [
          _Feature(l10n.unlimitedAiMessages, true),
          _Feature(l10n.unlimitedCases, true),
          _Feature(l10n.unlimitedDocScans, true),
          _Feature(l10n.fullAiAnalysis, true),
          _Feature(l10n.draftGeneration, true),
          _Feature(l10n.priorityProcessing, true),
        ],
        onSelect: currentTier == SubscriptionTier.premium
            ? null
            : () => _handlePlanSelect(context, ref, 'premium'),
      ),
    ];
  }

  // ── Handlers ─────────────────────────────────────────────────────────

  Future<void> _handlePlanSelect(
    BuildContext context,
    WidgetRef ref,
    String planId,
  ) async {
    if (planId == 'free') return;

    ref.read(_isLoadingPlanProvider.notifier).state = planId;
    final isAnnual = ref.read(_isAnnualProvider);

    try {
      final stripeService = ref.read(stripeCheckoutServiceProvider);
      await stripeService.startCheckout(
        uiPlanId: planId,
        isAnnual: isAnnual,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Redirecting to payment page...'),
            backgroundColor: AppColors.accent,
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
    await Future<void>.delayed(const Duration(seconds: 1));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noPreviousPurchases)),
      );
    }
  }
}

// ── Billing Toggle (Segmented Control) ───────────────────────────────────

class _BillingToggle extends StatelessWidget {
  const _BillingToggle({
    required this.isAnnual,
    required this.onChanged,
  });

  final bool isAnnual;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        children: [
          // Monthly
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: !isAnnual ? AppColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  boxShadow: !isAnnual
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  l10n.monthly,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: !isAnnual ? FontWeight.w600 : FontWeight.w500,
                    color: !isAnnual
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                  ),
                ),
              ),
            ),
          ),

          // Annual + badge
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: isAnnual ? AppColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  boxShadow: isAnnual
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.annual,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight:
                            isAnnual ? FontWeight.w600 : FontWeight.w500,
                        color: isAnnual
                            ? AppColors.textPrimary
                            : AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        l10n.saveTwentyFivePercent,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Compact Current Plan ─────────────────────────────────────────────────

class _CompactCurrentPlan extends StatelessWidget {
  const _CompactCurrentPlan({required this.tier});
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
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF2A4A7F)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.shield_rounded,
            color: Colors.white70,
            size: 20,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.currentPlan,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white60,
                ),
              ),
              Text(
                '$_tierText  ·  ${_label(l10n)}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Card Style Enum ──────────────────────────────────────────────────────

enum _CardStyle { free, recommended, premium }

// ── Feature Model ────────────────────────────────────────────────────────

class _Feature {
  const _Feature(this.text, this.included);
  final String text;
  final bool included;
}

// ── Plan Card ────────────────────────────────────────────────────────────

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
    required this.cardStyle,
    this.isRecommended = false,
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
  final bool isRecommended;
  final _CardStyle cardStyle;
  final List<_Feature> features;
  final VoidCallback? onSelect;
  final String? foundingMemberNote;

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard>
    with TickerProviderStateMixin {
  late final AnimationController _priceController;
  late final Animation<double> _priceAnimation;

  // Glow for recommended card
  AnimationController? _glowController;
  Animation<double>? _glowAnimation;

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

    if (widget.isRecommended) {
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
    _priceController.dispose();
    _glowController?.dispose();
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

  String? _annualSavingsText() {
    if (widget.monthlyPrice == 0 || widget.isAnnual) return null;
    final annualMonthly = widget.annualPrice / 12;
    final saved = widget.monthlyPrice - annualMonthly;
    if (saved <= 0) return null;
    return '\u20AC${saved.toStringAsFixed(2)}/mo cheaper annually';
  }

  // Background per card style
  BoxDecoration get _cardDecoration {
    switch (widget.cardStyle) {
      case _CardStyle.free:
        return BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: AppShadows.shadowSmall,
        );
      case _CardStyle.recommended:
        return BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.accent, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(
                  alpha: 0.15 + 0.12 * (_glowAnimation?.value ?? 0)),
              blurRadius: 20 + 12 * (_glowAnimation?.value ?? 0),
              spreadRadius: 1 + 2 * (_glowAnimation?.value ?? 0),
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: AppColors.accent.withValues(
                  alpha: 0.06 + 0.04 * (_glowAnimation?.value ?? 0)),
              blurRadius: 40,
              spreadRadius: 0,
            ),
          ],
        );
      case _CardStyle.premium:
        return BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A365D), Color(0xFF0F2240)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        );
    }
  }

  bool get _isDark => widget.cardStyle == _CardStyle.premium;

  Color get _textPrimary =>
      _isDark ? Colors.white : AppColors.textPrimary;

  Color get _textSecondary =>
      _isDark ? Colors.white60 : AppColors.textSecondary;

  Color get _checkColor =>
      _isDark ? AppColors.accentLight : AppColors.accent;

  Color get _uncheckColor =>
      _isDark ? Colors.white24 : AppColors.textTertiary.withValues(alpha: 0.4);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    Widget cardContent = Container(
      decoration: _cardDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Recommended badge ────────────────────────────────────
          if (widget.isRecommended)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.accent, AppColors.accentLight],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg - 1),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_rounded, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Soovitatav / Recommended',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

          // ── Current plan badge ───────────────────────────────────
          if (widget.isCurrent && !widget.isRecommended)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color: _isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : AppColors.accent,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg - 1),
                ),
              ),
              child: Text(
                l10n.currentPlan.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: Colors.white,
                ),
              ),
            ),

          // ── Card body ────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tier label pill
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : (widget.isRecommended
                                  ? AppColors.accent
                                      .withValues(alpha: 0.1)
                                  : AppColors.textTertiary
                                      .withValues(alpha: 0.1)),
                          borderRadius:
                              BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          widget.tierLabel,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _isDark
                                ? Colors.white70
                                : (widget.isRecommended
                                    ? AppColors.accent
                                    : AppColors.textTertiary),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Title
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ── Price ────────────────────────────────────────
                  FadeTransition(
                    opacity: _priceAnimation,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          _priceText(l10n),
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: _textPrimary,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _periodText(l10n),
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Annual savings hint
                  if (_annualSavingsText() != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _annualSavingsText()!,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: _isDark
                            ? AppColors.accentLight
                            : AppColors.accent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],

                  // Founding member note
                  if (widget.foundingMemberNote != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 13,
                          color: Color(0xFFD69E2E),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.foundingMemberNote!,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFD69E2E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 10),

                  Divider(
                    height: 1,
                    color: _isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : AppColors.border,
                  ),

                  const SizedBox(height: 10),

                  // ── Features list ────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(
                        math.min(widget.features.length, 6),
                        (i) {
                          final f = widget.features[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Row(
                              children: [
                                Icon(
                                  f.included
                                      ? AppIcons.checkCircle
                                      : Icons.cancel_rounded,
                                  size: 15,
                                  color: f.included
                                      ? _checkColor
                                      : _uncheckColor,
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    f.text,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: f.included
                                          ? _textPrimary
                                          : _textSecondary,
                                      decoration: f.included
                                          ? null
                                          : TextDecoration.lineThrough,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // ── CTA Button ──────────────────────────────────
                  _buildCta(l10n),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    // Wrap recommended card with glow animation
    if (widget.isRecommended && _glowAnimation != null) {
      cardContent = AnimatedBuilder(
        animation: _glowAnimation!,
        builder: (context, child) => child!,
        child: cardContent,
      );
    }

    return cardContent;
  }

  Widget _buildCta(AppLocalizations l10n) {
    final label = widget.isCurrent ? l10n.currentPlan : l10n.choosePlan;

    switch (widget.cardStyle) {
      case _CardStyle.free:
        // Outlined, subtle
        return SizedBox(
          width: double.infinity,
          height: 40,
          child: OutlinedButton(
            onPressed: widget.isCurrent ? null : widget.onSelect,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: BorderSide(
                color: widget.isCurrent
                    ? AppColors.border
                    : AppColors.textTertiary,
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              textStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: widget.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(label),
          ),
        );

      case _CardStyle.recommended:
        // Filled accent with glow
        return Container(
          width: double.infinity,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            boxShadow: widget.isCurrent
                ? null
                : [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.35),
                      blurRadius: 14,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: ElevatedButton(
            onPressed: widget.isCurrent ? null : widget.onSelect,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  AppColors.accent.withValues(alpha: 0.4),
              disabledForegroundColor: Colors.white70,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              textStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: widget.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(label),
          ),
        );

      case _CardStyle.premium:
        // Filled navy/white
        return SizedBox(
          width: double.infinity,
          height: 42,
          child: ElevatedButton(
            onPressed: widget.isCurrent ? null : widget.onSelect,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              disabledBackgroundColor: Colors.white.withValues(alpha: 0.3),
              disabledForegroundColor: Colors.white60,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              textStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: widget.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : Text(label),
          ),
        );
    }
  }
}

// ── Staggered Plan Card Animation ────────────────────────────────────────

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
      begin: const Offset(0.08, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    final delay = Duration(milliseconds: 150 + widget.index * 100);
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

// ── Page Indicator ───────────────────────────────────────────────────────

class _PageIndicator extends StatefulWidget {
  const _PageIndicator({
    required this.controller,
    required this.count,
  });

  final PageController controller;
  final int count;

  @override
  State<_PageIndicator> createState() => _PageIndicatorState();
}

class _PageIndicatorState extends State<_PageIndicator> {
  double _page = 1;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (widget.controller.hasClients) {
      setState(() {
        _page = widget.controller.page ?? 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.count, (i) {
        final distance = (i - _page).abs().clamp(0.0, 1.0);
        final size = 8.0 - distance * 3.0;
        final opacity = 1.0 - distance * 0.6;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: i == _page.round() ? 20 : size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        );
      }),
    );
  }
}
