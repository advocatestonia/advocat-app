import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/router.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/user.dart';
import '../../../services/stripe_checkout_service.dart';
import '../../../shared/constants/app_icons.dart';
import '../../../shared/widgets/advocat_gradient_header.dart';
import '../../../shared/widgets/max_width_wrapper.dart';
import '../../auth/providers/auth_provider.dart';
import '../../legal/widgets/dpa_checkout_gate.dart';
import '../services/iap_service.dart';

// ── Providers ────────────────────────────────────────────────────────────

final _isAnnualProvider = StateProvider<bool>((ref) => false);
final _isLoadingPlanProvider = StateProvider<String?>((ref) => null);

/// Singleton IapService — created lazily on iOS, no-op stub elsewhere.
/// Disposal hook closes the purchaseStream subscription cleanly when the
/// provider tree tears down (test harness, sign-out, etc).
final iapServiceProvider = Provider<IapService>((ref) {
  final svc = IapService();
  ref.onDispose(() {
    // Fire-and-forget — dispose is async but ref.onDispose is sync.
    unawaited(svc.dispose());
  });
  return svc;
});

/// True when the current device should show the Apple IAP path. Web and
/// Android (until Play Console config lands) fall back to Stripe.
bool _shouldShowAppleIap() {
  if (kIsWeb) return false;
  try {
    return Platform.isIOS;
  } catch (_) {
    return false;
  }
}

/// Map the UI plan id (free/basic/premium) + annual toggle to an Apple
/// product id. Returns null for `free` since there is no IAP for that.
IapPlanId? _planIdToIapPlan(String planId, bool isAnnual) {
  switch (planId) {
    case 'basic':
      return isAnnual ? IapPlanId.counselAnnual : IapPlanId.counselMonthly;
    case 'premium':
      return isAnnual ? IapPlanId.proAnnual : IapPlanId.proMonthly;
    default:
      return null;
  }
}

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
      appBar: AdvocatGradientHeader(
        title: l10n.subscription,
      ),
      // Use MaxWidthWrapper's responsive default — pricing/Subscription is
      // a page-content screen (cards, comparison), not a form. On desktop
      // it should breathe out to 1200px, not sit in a 480px column with
      // empty gutters. Form screens (login/register/edit_profile) keep an
      // explicit 480 cap; this one is page-content.
      //
      // Column.crossAxisAlignment must be `stretch` so the inner PageView
      // (which has `viewportFraction: 0.85`) actually receives the full
      // 1200px wrapper width as a tight cross-axis constraint. With the
      // default `center`, children get loose constraints and PageView
      // collapses to a 480px fallback — keeping the desktop layout
      // squeezed even after the wrapper was loosened.
      body: SafeArea(
        top: false,
        child: MaxWidthWrapper(
        child: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
            // Fixed height keeps the carousel from being squeezed on short
            // viewports (where Expanded would shrink the card past its CTA)
            // and lets the page scroll naturally.
            SizedBox(
              height: 540,
              child: PageView.builder(
                controller: _pageController,
                itemCount: plans.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  return _StaggeredPlanCard(
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 8,
                      ),
                      child: plans[index],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // ── Page Indicator ───────────────────────────────────────
            _PageIndicator(
              controller: _pageController,
              count: plans.length,
            ),

            const SizedBox(height: 16),

            // ── Voice disclaimer ────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 18, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.voiceDisclaimer,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Manage Subscription (Stripe Customer Portal) ────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                onPressed: () async {
                  try {
                    final session = Supabase.instance.client.auth.currentSession;
                    if (session == null) {
                      if (context.mounted) {
                        final l10n = AppLocalizations.of(context)!;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.pleaseLogIn)),
                        );
                      }
                      return;
                    }
                    final response =
                        await Supabase.instance.client.functions.invoke(
                      'customer-portal',
                      method: HttpMethod.post,
                    );
                    final responseData = response.data;
                    Map<String, dynamic>? data;
                    if (responseData is Map<String, dynamic>) {
                      data = responseData;
                    } else if (responseData is String) {
                      try {
                        data = Map<String, dynamic>.from(
                          (responseData).isNotEmpty
                            ? Map.from(Uri.splitQueryString(responseData))
                            : {},
                        );
                      } catch (_) {}
                    }
                    final url = data?['url'] as String?;
                    if (url != null && url.isNotEmpty) {
                      await launchUrl(Uri.parse(url),
                          mode: LaunchMode.platformDefault);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(data?['error']?.toString() ?? AppLocalizations.of(context)!.subscriptionNotFound),
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context)!.errorWithMessage(e.toString()))),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.settings_outlined, size: 18),
                label: Text(
                  l10n.manageSubscription,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 4),

            // ── Restore Purchases ────────────────────────────────────
            TextButton(
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

            // ── For Law Firms (B2B silent-signal entry) ─────────────
            // Single ghost-text link, intentionally low-contrast and at
            // the very bottom of the screen. NOT a pricing CTA — the
            // /for-firms page itself shows no prices. Per spec
            // (2026-05-25): one-line, bottom, ghost text style.
            TextButton(
              key: const Key('subscription_for_firms_link'),
              onPressed: () => context.push(AppRoutes.forFirms),
              child: Text(
                _forFirmsLinkLabel(
                  Localizations.localeOf(context).languageCode,
                ),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textTertiary,
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

  /// Localised label for the ghost-text /for-firms link. We inline this
  /// instead of routing through AppLocalizations so the link can ship
  /// without an arb regen — same approach welcome_modal uses.
  String _forFirmsLinkLabel(String code) {
    switch (code.toLowerCase()) {
      case 'et':
        return 'Advocat advokaadibüroodele \u2192';
      case 'ru':
        return 'Advocat для юр.фирм \u2192';
      case 'fi':
        return 'Advocat asianajotoimistoille \u2192';
      case 'de':
        return 'Advocat für Kanzleien \u2192';
      case 'fr':
        return "Advocat pour les cabinets d'avocats \u2192";
      case 'es':
        return 'Advocat para despachos \u2192';
      case 'it':
        return 'Advocat per studi legali \u2192';
      case 'pl':
        return 'Advocat dla kancelarii \u2192';
      default:
        return 'Advocat for law firms \u2192';
    }
  }

  List<Widget> _buildPlans(
    AppLocalizations l10n,
    SubscriptionTier currentTier,
    bool isAnnual,
    String? loadingPlan,
  ) {
    // When the device is iOS we route purchases through StoreKit instead of
    // Stripe Checkout. Apple's anti-steering rules also forbid offering a
    // parallel web payment for the same item once IAP is the chosen path,
    // so the CTA reads "Pay via Apple" and the Stripe redirect is replaced
    // by the StoreKit sheet in _handlePlanSelect.
    final bool appleIapPath = _shouldShowAppleIap();

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
          // Pkg Contract Review (2026-05-13): per-tier quota line.
          _Feature(l10n.contractReviewsFreeFeature, true),
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
        monthlyPrice: 19.99,
        annualPrice: 159.99,
        isAnnual: isAnnual,
        isCurrent: currentTier == SubscriptionTier.basic,
        isLoading: loadingPlan == 'basic',
        isRecommended: true,
        useAppleIapLabel: appleIapPath,
        cardStyle: _CardStyle.recommended,

        features: [
          _Feature(l10n.hundredAiMessagesDay, true),
          _Feature(l10n.threeCasesActive, true),
          _Feature(l10n.twentyDocScans, true),
          _Feature(l10n.fullAiAnalysis, true),
          // Pkg Contract Review (2026-05-13): per-tier quota line.
          _Feature(l10n.contractReviewsCounselFeature, true),
          _Feature(l10n.draftGeneration, true),
          _Feature(l10n.voiceInput, true),
        ],
        onSelect: currentTier == SubscriptionTier.basic
            ? null
            : () => _handlePlanSelect(context, ref, 'basic'),
      ),

      // Advocat Pro (premium)
      _PlanCard(
        planId: 'premium',
        title: l10n.fullDefense,
        tierLabel: 'PRO',
        monthlyPrice: 29.99,
        annualPrice: 249.99,
        isAnnual: isAnnual,
        isCurrent: currentTier == SubscriptionTier.premium,
        isLoading: loadingPlan == 'premium',
        useAppleIapLabel: appleIapPath,
        cardStyle: _CardStyle.premium,
        features: [
          _Feature(l10n.unlimitedAiMessages, true),
          _Feature(l10n.unlimitedCases, true),
          _Feature(l10n.unlimitedDocScans, true),
          _Feature(l10n.fullAiAnalysis, true),
          // Pkg Contract Review (2026-05-13): per-tier quota line.
          _Feature(l10n.contractReviewsProFeature, true),
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

    // Re-entrancy / double-tap guard. Set the loading flag SYNCHRONOUSLY
    // before the first await below. Without this, a fast double-tap fires
    // _handlePlanSelect twice; both pass the DPA gate (which resolves
    // instantly when already accepted) and both start a checkout → the user
    // can be charged twice. Bail if a checkout for ANY plan is already in
    // flight. The finally-style resets at lines below clear the flag.
    final notifier = ref.read(_isLoadingPlanProvider.notifier);
    if (notifier.state != null) return;
    notifier.state = planId;

    // GDPR Art. 28 — clickwrap DPA gate. Blocks paid checkout until the
    // user has accepted the current DPA version (cached row in
    // public.dpa_acceptances skips the dialog on re-upgrade).
    final dpaOk = await ensureDpaAccepted(context);
    if (!dpaOk) {
      notifier.state = null;
      return;
    }

    final isAnnual = ref.read(_isAnnualProvider);

    // iOS native path → Apple IAP (App Store Guideline 3.1.1 requires IAP
    // for digital subs purchased inside the iOS app; Stripe-only would be
    // a rejection risk). Everywhere else → Stripe Checkout (unchanged).
    if (_shouldShowAppleIap()) {
      if (!context.mounted) {
        notifier.state = null;
        return;
      }
      await _handleApplePurchase(context, ref, planId, isAnnual);
      return;
    }

    try {
      final stripeService = ref.read(stripeCheckoutServiceProvider);
      final userEmail = Supabase.instance.client.auth.currentUser?.email;
      await stripeService.startCheckout(
        uiPlanId: planId,
        isAnnual: isAnnual,
        customerEmail: userEmail,
      );

      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.redirectingToPayment),
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

  /// iOS Apple IAP path. Mirrors the Stripe handler — sets loading state,
  /// fires the buy, listens once on results stream, then surfaces a
  /// success / failure snackbar. The server-side activation (profiles +
  /// subscriptions write) is done by apple-iap-verify so we just need to
  /// invalidate currentUserProvider on success and the rest of the UI
  /// updates via Riverpod.
  Future<void> _handleApplePurchase(
    BuildContext context,
    WidgetRef ref,
    String planId,
    bool isAnnual,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final iapPlan = _planIdToIapPlan(planId, isAnnual);
    if (iapPlan == null) {
      ref.read(_isLoadingPlanProvider.notifier).state = null;
      return;
    }

    final iap = ref.read(iapServiceProvider);
    final initialized = await iap.initialize();
    if (!initialized) {
      // Fall back to Stripe so the user is never stranded on a device
      // where StoreKit isn't available (jailbroken, parental controls).
      if (context.mounted) {
        final stripeService = ref.read(stripeCheckoutServiceProvider);
        final userEmail = Supabase.instance.client.auth.currentUser?.email;
        await stripeService.startCheckout(
          uiPlanId: planId,
          isAnnual: isAnnual,
          customerEmail: userEmail,
        );
      }
      ref.read(_isLoadingPlanProvider.notifier).state = null;
      return;
    }

    // Single-shot subscription — first emitted result completes this future.
    final completer = Completer<IapResult>();
    late StreamSubscription<IapResult> sub;
    sub = iap.results.listen((res) {
      if (res.kind == IapResultKind.success ||
          res.kind == IapResultKind.cancelled ||
          res.kind == IapResultKind.error ||
          res.kind == IapResultKind.notSupported) {
        if (!completer.isCompleted) completer.complete(res);
      }
    });

    try {
      await iap.buy(iapPlan);
      final result = await completer.future.timeout(
        const Duration(minutes: 3),
        onTimeout: () => const IapResult.error('Purchase timed out'),
      );
      if (!context.mounted) return;
      switch (result.kind) {
        case IapResultKind.success:
          ref.invalidate(currentUserProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.redirectingToPayment),
              backgroundColor: AppColors.accent,
            ),
          );
          break;
        case IapResultKind.cancelled:
          // User dismissed the StoreKit sheet — silent, no snackbar.
          break;
        case IapResultKind.error:
        case IapResultKind.notSupported:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.iapPurchaseFailed),
              backgroundColor: AppColors.error,
            ),
          );
          break;
        case IapResultKind.noActive:
          break;
      }
    } finally {
      await sub.cancel();
      ref.read(_isLoadingPlanProvider.notifier).state = null;
    }
  }

  Future<void> _handleRestore(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.checkingPurchases)),
    );

    // On iOS, fire StoreKit restore FIRST — Apple replays past transactions
    // through purchaseStream, IapService POSTs each to apple-iap-verify,
    // which writes profiles + subscriptions. We then invalidate the user
    // provider so the UI picks up the restored tier. (App Store Guideline
    // 3.1.1 explicitly requires this button in every app with IAP.)
    if (_shouldShowAppleIap()) {
      try {
        final iap = ref.read(iapServiceProvider);
        if (await iap.initialize()) {
          await iap.restore();
          // restorePurchases is async — give Apple a couple of seconds to
          // replay the transactions through purchaseStream + our server
          // round-trip.
          await Future<void>.delayed(const Duration(seconds: 3));
        }
      } catch (e) {
        // Restore is best-effort — if Apple errors we still fall through
        // to the Supabase re-fetch (Stripe customers also use Restore).
        debugPrint('[subscription] Apple restore error: $e');
      }
    }

    // Re-fetch profile from Supabase to check current subscription. This
    // also catches Stripe-side activations that the user lost local state
    // for (browser cookie wipe, fresh device, etc).
    ref.invalidate(currentUserProvider);

    // Wait for the profile to reload
    await Future<void>.delayed(const Duration(seconds: 2));

    if (context.mounted) {
      final user = ref.read(currentUserProvider).valueOrNull;
      // Access decision: rely on isProActive (is_pro && not expired), not
      // on subscriptionTier alone. Tier is still used below for the label.
      if (user != null && user.isProActive) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.iapRestoreSuccess),
            backgroundColor: AppColors.accent,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.iapRestoreNoActive)),
        );
      }
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
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        children: [
          // Monthly
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
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
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  l10n.monthly,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
              behavior: HitTestBehavior.opaque,
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
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        l10n.annual,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        l10n.saveTwentyFivePercent,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.currentPlan,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$_tierText  ·  ${_label(l10n)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
    this.useAppleIapLabel = false,
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

  /// When true, the CTA reads "Pay via Apple" instead of the generic
  /// "Choose plan". Free tier (planId='free') ignores this flag — the CTA
  /// stays the standard sign-up label.
  final bool useAppleIapLabel;

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

  String? _annualSavingsText(AppLocalizations l10n) {
    if (widget.monthlyPrice == 0 || widget.isAnnual) return null;
    final annualMonthly = widget.annualPrice / 12;
    final saved = widget.monthlyPrice - annualMonthly;
    if (saved <= 0) return null;
    return l10n.cheaperAnnually(saved.toStringAsFixed(2));
  }

  /// VAT disclosure label (EU consumer-law compliance). Returns null for
  /// the Free tier so we don't render "incl. 22% VAT" under €0.
  /// Localized inline to avoid a churn of 17 l10n regenerations — kept in
  /// sync with web/index.html#pricing.vat_included.
  String? _vatText(BuildContext context) {
    if (widget.monthlyPrice == 0) return null;
    return _vatTextForLocale(
      Localizations.localeOf(context).languageCode,
    );
  }

  static const Map<String, String> _vatLabels = {
    'en': 'incl. 22% VAT',
    'et': 'Sis. käibemaks 22%',
    'ru': 'Включая НДС 22%',
    'uk': 'З ПДВ 22%',
    'fi': 'Sis. ALV 22%',
    'de': 'inkl. 22 % MwSt.',
    'fr': 'TVA 22 % incluse',
    'es': 'IVA 22 % incl.',
    'it': 'IVA 22 % inclusa',
    'pl': 'zawiera 22% VAT',
    'sv': 'inkl. 22 % moms',
    'lv': 'ar 22 % PVN',
    'lt': 'su 22 % PVM',
    'ro': 'TVA 22 % inclus',
    'tr': 'KDV %22 dahil',
    'ar': 'شامل ضريبة القيمة المضافة 22%',
    'fa': 'شامل ۲۲٪ مالیات بر ارزش افزوده',
  };

  static String _vatTextForLocale(String code) {
    return _vatLabels[code] ?? _vatLabels['en']!;
  }

  Color? get _backgroundColor {
    switch (widget.cardStyle) {
      case _CardStyle.free:
        return const Color(0xFFF5F5F5);
      case _CardStyle.recommended:
        return Colors.white;
      case _CardStyle.premium:
        return null; // uses gradient
    }
  }

  Gradient? get _backgroundGradient {
    if (widget.cardStyle == _CardStyle.premium) {
      return const LinearGradient(
        colors: [Color(0xFF1A365D), Color(0xFF0F2240)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return null;
  }

  Border? get _border {
    switch (widget.cardStyle) {
      case _CardStyle.free:
        return Border.all(color: AppColors.border, width: 1);
      case _CardStyle.recommended:
        return Border.all(color: AppColors.accent, width: 2);
      case _CardStyle.premium:
        return null;
    }
  }

  List<BoxShadow> get _shadow {
    switch (widget.cardStyle) {
      case _CardStyle.free:
        return AppShadows.shadowSmall;
      case _CardStyle.recommended:
        return [
          BoxShadow(
            color: AppColors.accent.withValues(
                alpha: 0.10 + 0.05 * (_glowAnimation?.value ?? 0)),
            blurRadius: 12 + 4 * (_glowAnimation?.value ?? 0),
            offset: const Offset(0, 4),
          ),
        ];
      case _CardStyle.premium:
        return [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ];
    }
  }

  bool get _isDark =>
      widget.cardStyle == _CardStyle.premium;

  Color get _textPrimary =>
      _isDark ? Colors.white : AppColors.textPrimary;

  Color get _textSecondary =>
      _isDark ? Colors.white60 : AppColors.textSecondary;

  Color get _checkColor =>
      _isDark ? AppColors.accentLight : AppColors.accent;

  Color get _uncheckColor =>
      _isDark ? Colors.white24 : AppColors.textTertiary.withValues(alpha: 0.4);

  // Whether this card shows a top badge
  bool get _hasBadge => widget.isRecommended || widget.isCurrent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    Widget cardContent = Container(
      decoration: BoxDecoration(
        color: _backgroundColor,
        gradient: _backgroundGradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: _border,
        boxShadow: _shadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Top badge (recommended or current plan) ──────────
          if (widget.isRecommended)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              color: AppColors.accent,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_rounded,
                      size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    l10n.recommended,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          else if (widget.isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              color: _isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : AppColors.accent,
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

          // ── Card body ───────────────────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  16, _hasBadge ? 8 : 14, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  // Tier label pill
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
                  const SizedBox(height: 6),

                  // Title
                  Text(
                    widget.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      color: _textPrimary,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // ── Price ──────────────────────────────────
                  FadeTransition(
                    opacity: _priceAnimation,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: Text(
                            _priceText(l10n),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: _textPrimary,
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _periodText(l10n),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: _textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // VAT disclosure (EU consumer law) — only for paid tiers.
                  if (_vatText(context) != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _vatText(context)!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _textSecondary.withValues(alpha: 0.7),
                        ),
                      ),
                    ),

                  // Annual savings hint (reserved slot, avoids jitter when
                  // toggling monthly/annual).
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: SizedBox(
                      height: 16,
                      child: _annualSavingsText(l10n) != null
                          ? Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _annualSavingsText(l10n)!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  color: _isDark
                                      ? AppColors.accentLight
                                      : AppColors.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Divider(
                    height: 1,
                    color: _isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : AppColors.border,
                  ),

                  const SizedBox(height: 12),

                  // ── Features list ──────────────────────────
                  // Cap bumped to 7 in 2026-05-13 to make room for the
                  // Contract Reviews line on every tier (Pkg Contract Review).
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(
                          math.min(widget.features.length, 7),
                          (i) {
                            final f = widget.features[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 1),
                                    child: Icon(
                                      f.included
                                          ? AppIcons.checkCircle
                                          : Icons.cancel_rounded,
                                      size: 15,
                                      color: f.included
                                          ? _checkColor
                                          : _uncheckColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      f.text,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: true,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12.5,
                                        height: 1.3,
                                        fontWeight: FontWeight.w400,
                                        color: f.included
                                            ? _textPrimary
                                            : _textSecondary,
                                        decoration: f.included
                                            ? null
                                            : TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── CTA Button ─────────────────────────────
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
    // On iOS we surface "Pay via Apple" so the user knows the next step
    // is the StoreKit sheet, not a browser bounce to Stripe. Free tier
    // and current-plan states keep the generic labels.
    final String purchaseLabel = (widget.useAppleIapLabel &&
            widget.planId != 'free')
        ? l10n.iapPayWithApple
        : l10n.choosePlan;
    final label = widget.isCurrent ? l10n.currentPlan : purchaseLabel;

    const Widget loader = SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    );

    switch (widget.cardStyle) {
      case _CardStyle.free:
        return SizedBox(
          width: double.infinity,
          height: 48,
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
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            child: widget.isLoading ? loader : Text(label),
          ),
        );

      case _CardStyle.recommended:
        return SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: widget.isCurrent ? null : widget.onSelect,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.3),
              disabledForegroundColor: Colors.white60,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              textStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            child: widget.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                  )
                : Text(label),
          ),
        );

      case _CardStyle.premium:
        return SizedBox(
          width: double.infinity,
          height: 48,
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
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            child: widget.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primary),
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
