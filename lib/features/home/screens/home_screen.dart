import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../config/feature_flags.dart';
import '../../../config/router.dart';
import '../../../config/theme.dart';
import '../../../core/icons/app_icons.dart';
import '../../../l10n/app_localizations.dart';
import '../../../main.dart';
import '../../../models/case_model.dart';
import '../../../models/deadline.dart';
import '../../../shared/utils/date_utils.dart';
import '../../../shared/widgets/ai_disclaimer_banner.dart';
import '../../../shared/widgets/gdpr_consent_dialog.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/pending_checkout.dart';
import '../../../services/demo_data.dart';
import '../../../services/stripe_checkout_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../cases/providers/cases_provider.dart';
import '../../cases/widgets/case_card.dart';
import '../../case_memory/widgets/deadline_radar_widget.dart';
import '../../deadlines/providers/deadlines_provider.dart';
import '../../onboarding/data/sample_case_messages.dart';
import '../../onboarding/widgets/welcome_modal.dart';
import '../../b2b/providers/b2b_detection_provider.dart';
import '../bootstrap/home_bootstrap.dart';
import '../../referral/referral_nudge.dart';

// ---------------------------------------------------------------------------
// Home Dashboard
// ---------------------------------------------------------------------------

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  /// Test hook: set to false to suppress the bootstrap modal queue when
  /// pumping HomeScreen in a widget test that only cares about layout.
  @visibleForTesting
  static bool runBootstrapInTests = true;

  @override
  void initState() {
    super.initState();

    // FIX 2026-05-27: cold-start used to fire six modal triggers
    // simultaneously, which stacked 3+ dialogs on the user within 2s.
    // We now route every modal through a serial priority queue (see
    // `bootstrap/home_bootstrap.dart` for the order + cool-downs).
    //
    // Payment-return polling is the one exception: it lives outside the
    // queue because it's a navigation effect, not a modal — it inspects
    // the URL fragment synchronously and only kicks the post-frame
    // callback when `payment-success` is present.
    _checkPaymentReturn();

    // The onboarding bootstrap (no UI) and the priority modal queue both
    // run on the next frame so providers + layout are settled. The queue
    // is awaited end-to-end so each modal blocks the next.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!runBootstrapInTests) return;
      unawaited(_runBootstrapQueue());
    });
  }

  /// Serial priority queue for cold-start modals. Each step awaits the
  /// previous modal's dismissal before checking the next, so the user
  /// never sees two surfaces racing on the same frame.
  ///
  /// Order (mirrors `kBootstrapPriorityOrder`):
  ///
  ///   1. GDPR consent     (legal — blocking)
  ///   2. Pending checkout (user just paid)
  ///   3. Welcome modal    (first-time onboarding)
  ///   4. B2B nudge        (opportunistic, cool-down gated)
  ///
  /// The referral snackbar is intentionally NOT here — it's surfaced from
  /// the chat screen after the user sends their first successful message
  /// (see `markFirstChatTimestamp` + the chat-screen integration point).
  /// On subsequent home visits we just no-op; the snackbar already fired
  /// in the natural success flow.
  Future<void> _runBootstrapQueue() async {
    // 1. GDPR — blocking. If declined the user is signed out by
    //    `_checkGdprConsent` itself and the rest of the queue becomes moot.
    await _checkGdprConsent();
    if (!mounted) return;

    // 2. Pending checkout — `?plan=...&billing=...` arrived via the
    //    landing CTA. Drive the Stripe redirect before any onboarding.
    await _checkPendingCheckout();
    if (!mounted) return;

    // 3. Welcome modal — first-time users only. Shared-prefs gated.
    await _checkFirstTimeOnboarding();
    if (!mounted) return;

    // 4. B2B silent-signal modal — opportunistic, 7-day cool-down.
    await _maybeShowB2BLeadModal();
  }

  /// B2B silent-signal detection. After login the backend may have flagged
  /// the user (heavy use, professional patterns) via
  /// `profiles.b2b_modal_pending = true`. Fire-and-forget; the controller
  /// silently no-ops on demo mode, network failure, or pending=false.
  ///
  /// Runs AFTER the welcome modal would have rendered so a brand-new user
  /// gets the standard onboarding first — the B2B signal is a second-
  /// session-or-later trigger by design.
  Future<void> _maybeShowB2BLeadModal() async {
    try {
      // Skip in demo mode — the demo user has no Supabase profile row to
      // read, and the modal would just immediately no-op.
      final isDemo = ref.read(isDemoModeProvider);
      if (isDemo) return;

      // Cool-down check: even if the backend re-flags pending=true, don't
      // re-show within 7 days of the last impression. Prevents bursty
      // re-triggering when an operator manually toggles
      // `profiles.b2b_modal_pending` or when our detector is over-eager.
      final cooldownPassed = await shouldShowB2bModal();
      if (!cooldownPassed) return;

      // The serial bootstrap queue (see `_runBootstrapQueue`) already
      // guarantees GDPR + checkout + welcome have rendered/dismissed
      // before we reach this step. No `Future.delayed` race-guard needed.
      if (!mounted) return;

      final locale = Localizations.localeOf(context).languageCode;
      final action = await ref
          .read(b2bDetectionControllerProvider.notifier)
          .maybeTrigger(context, locale: locale);

      // Only stamp the cool-down if the modal actually rendered (action
      // non-null means the controller didn't short-circuit on
      // `b2b_modal_pending=false`).
      if (action != null) {
        unawaited(markB2bModalShown());
      }
    } catch (_) {
      // Swallow — never block the home-screen render path on B2B detection.
    }
  }

  /// One-time growth nudge: after the user's first AI conversation and
  /// >24h of activity, surface a snackbar suggesting they invite a
  /// friend. Suppressed forever once the user has either tapped it or
  /// visited the /referral screen.
  ///
  /// Gating signals (all must be true):
  ///   * Authenticated (not demo) — no point asking demo users to share.
  ///   * `first_chat_at` is set (user has actually sent a message).
  ///   * `now - account.createdAt > 24h` — anti-cheap-share guard.
  ///   * `referral_seen` is false — they haven't opened the invite screen.
  ///   * `referral_nudge_shown` is false — the snackbar fired ≥ once
  ///     already in a prior session; don't pester.
  ///
  /// 2026-05-27: this method is intentionally NOT called from
  /// `initState` anymore — it stacked with GDPR + welcome + B2B and
  /// turned cold-start into a modal-pile. The snackbar now belongs in
  /// the chat-screen success path (after `markFirstChatTimestamp`).
  /// Kept here so a future test or feature flag can re-enable the
  /// post-cold-start variant without re-implementing the gates.
  // ignore: unused_element
  Future<void> _maybeShowReferralNudge() async {
    try {
      // Soft-launch gate (consilium 2026-05-15) — referral surfaces are
      // disabled by default; the rest of the gating logic is kept compiled
      // so the feature can be re-enabled via dart-define without churn.
      if (!kReferralEnabled) return;

      final isDemo = ref.read(isDemoModeProvider);
      if (isDemo) return;

      final prefs = await SharedPreferences.getInstance();
      // Hard kill-switches set elsewhere.
      if (prefs.getBool('referral_nudge_shown') ?? false) return;
      if (prefs.getBool(_referralSeenKey) ?? false) return;

      // Did the user send a chat message yet? We rely on the chat screen
      // to write `first_chat_at` on the first send — if the key is
      // missing, the user never typed a message; skip.
      final firstChatRaw = prefs.getString('first_chat_at');
      if (firstChatRaw == null || firstChatRaw.isEmpty) return;

      // Anti-cheap-share: require account age > 24h. Use createdAt from
      // the user profile when available, otherwise fall back to the
      // first-chat timestamp.
      final user = ref.read(currentUserProvider).valueOrNull;
      final reference = user?.createdAt ??
          DateTime.tryParse(firstChatRaw)?.toUtc();
      if (reference == null) return;
      if (DateTime.now().toUtc().difference(reference).inHours < 24) {
        return;
      }

      // Wait a bit so the home screen settles before the snackbar
      // appears — otherwise it competes with the GDPR / onboarding
      // sheets on a cold start.
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;

      final l = AppLocalizations.of(context);
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 8),
          content: Text(
            l?.referralNudgeMessage ??
                'Like Advocat? Invite a friend — both get a free month.',
            style: const TextStyle(color: Colors.white),
          ),
          action: SnackBarAction(
            label: l?.referralNudgeAction ?? 'Invite',
            textColor: const Color(0xFF14B8A6), // accentTint — high contrast
            onPressed: () {
              if (!mounted) return;
              context.push(AppRoutes.referral);
            },
          ),
        ),
      );
      // Fire-and-forget the persistence flip — don't block on the await
      // result since the snackbar is already on screen. Use the shared
      // helper so the 14-day cool-down timestamp stays in sync with the
      // legacy boolean.
      unawaited(markReferralNudgeShown());
    } catch (_) {
      // Any failure here is silent; the nudge is a nice-to-have.
    }
  }

  /// SharedPreferences key flipped by ReferralScreen on first open. Kept
  /// in-sync with [kReferralSeenPrefKey] in referral_screen.dart.
  static const String _referralSeenKey = 'referral_seen';

  /// If the landing redirected here with `?plan=...&billing=...`, kick off
  /// a Stripe Checkout once we are sure the user is signed in. We rely on
  /// the GoRouter redirect to bounce un-authed users to /login, so by the
  /// time HomeScreen renders the user is authenticated.
  ///
  /// Already-Pro users skip checkout (no double-billing). The pending
  /// checkout is consumed exactly once per session — page reload re-reads
  /// the URL, but a successful in-app navigation will not retrigger it.
  Future<void> _checkPendingCheckout() async {
    if (!kIsWeb) return;
    // Wait one frame so providers and the layout are settled.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;

    final pending = ref.read(pendingCheckoutProvider);
    if (pending == null) return;

    // If already Pro, drop the pending checkout silently — they don't need
    // to pay again. Show a small toast so the click isn't a no-op.
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user != null && user.isProActive) {
      ref.read(pendingCheckoutProvider.notifier).clear();
      if (mounted) {
        final l = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l?.currentPlan != null
                ? '${l!.currentPlan}: ${user.subscriptionTier.name}'
                : 'You already have an active subscription.'),
          ),
        );
      }
      return;
    }

    final consumed =
        ref.read(pendingCheckoutProvider.notifier).consume();
    if (consumed == null) return;

    try {
      final stripe = ref.read(stripeCheckoutServiceProvider);
      await stripe.startCheckoutWithBilling(
        stripePlanId: consumed.planId,
        billingPeriod: consumed.billingPeriod,
        customerEmail: user?.email,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Checkout failed: $e')),
        );
      }
    }
  }

  /// App major version used to key GDPR re-prompts. Bumped when ToS or
  /// Privacy Policy changes materially. Kept inline (not in pubspec at
  /// runtime) so a release can rev consent independently of the build
  /// version number.
  static const String _gdprMajorVersion = '1';

  Future<void> _checkGdprConsent() async {
    try {
      final isDemo = ref.read(isDemoModeProvider);
      if (isDemo) return; // Skip GDPR dialog in demo mode

      // Server-side authoritative check (Supabase `profiles.gdpr_consent_at`)
      // + local fallback. This already returns true if EITHER source has
      // a stored consent — see gdpr_consent_dialog.dart.
      final hasConsent = await hasGdprConsent();

      // Major-version gate: if the user accepted under an OLDER major
      // version, re-prompt even when `hasConsent` is true. This is how
      // we re-collect consent after a ToS rev without breaking the
      // existing "already accepted" Supabase row.
      final majorVersionNeedsPrompt =
          await shouldShowGdprConsentForMajorVersion(
              currentMajorVersion: _gdprMajorVersion);

      if ((!hasConsent || majorVersionNeedsPrompt) && mounted) {
        // The bootstrap queue already settled providers + layout; no
        // additional `Future.delayed` warm-up needed here.
        final accepted = await showGdprConsentDialog(context);
        if (accepted) {
          unawaited(markGdprAcceptedForMajorVersion(
              currentMajorVersion: _gdprMajorVersion));
        } else if (mounted) {
          // User declined — sign them out
          unawaited(ref.read(authControllerProvider.notifier).logout());
        }
      }
    } catch (_) {
      // Consent check failure — do not block the user
    }
  }

  void _checkPaymentReturn() {
    try {
      if (!kIsWeb) return;
      final fragment = Uri.base.fragment;
      if (fragment.contains('payment-success')) {
        // FIX-WAVE 8 (DEPT 4): the Stripe webhook can lag the customer
        // return by 1-3s (sometimes more under load). The old one-shot
        // ref.invalidate() ran exactly once, so users whose webhook hadn't
        // landed yet saw "Payment successful" but isProActive was still
        // false. We now poll until either Pro flips on or we time out.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            unawaited(_pollForProActivation());
          }
        });
      }
    } catch (_) {}
  }

  /// Polls currentUserProvider every 2s for up to 5 attempts (10s total),
  /// waiting for the Stripe webhook to flip is_pro=true. While polling we
  /// show a non-dismissible spinner dialog; on success we close it,
  /// navigate to the chat hub, and surface a "Welcome to Pro!" snackbar;
  /// on timeout we show a fallback dialog explaining the email-when-ready
  /// path so the user is never left staring at a spinner.
  Future<void> _pollForProActivation() async {
    final l = AppLocalizations.of(context);
    // Spinner dialog — barrierDismissible=false so the user can't dismiss
    // and start a parallel checkout. We close it ourselves below.
    if (!mounted) return;
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Text(
                  // No dedicated l10n key — fall back to a localised
                  // "activating" message built from the existing keys.
                  '${l?.paymentSuccessTitle ?? 'Payment successful'}\n'
                  '${l?.paymentSuccessBody ?? 'Activating your Pro plan...'}',
                ),
              ),
            ],
          ),
        ),
      ),
    );

    const maxAttempts = 5;
    const pollInterval = Duration(seconds: 2);
    var pro = false;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      if (!mounted) return;
      ref.invalidate(currentUserProvider);
      // Wait for the provider to re-emit before checking. ref.read on an
      // AsyncValue right after invalidate returns AsyncLoading; awaiting
      // the .future gives us the next concrete value.
      try {
        final user = await ref.read(currentUserProvider.future);
        if (user?.isProActive == true) {
          pro = true;
          break;
        }
      } catch (_) {
        // Transient network failure — keep polling.
      }
      if (attempt < maxAttempts - 1) {
        await Future<void>.delayed(pollInterval);
      }
    }

    if (!mounted) return;

    // Close the spinner dialog (always — both success and timeout).
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) navigator.pop();

    if (pro) {
      // Navigate to general chat ("Pro feature unlocked, start a
      // conversation") and surface the welcome snackbar.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            content: Text(
              '${l?.paymentSuccessTitle ?? 'Welcome to Pro!'} '
              '${l?.paymentSuccessBody ?? 'Your subscription is now active.'}',
              style: const TextStyle(color: Colors.white),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
        unawaited(context.push('/chat/general'));
      }
    } else {
      // Timed out — webhook may still be in flight. Tell the user we'll
      // email them once it lands, and offer a back-to-app button.
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l?.paymentSuccessTitle ?? 'Payment received'),
            content: const Text(
              // Composed from existing keys to avoid a new arb round-trip.
              "We're processing your payment. "
              "You'll get an email when it's ready.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l?.commonOk ?? 'Back to app'),
              ),
            ],
          ),
        );
      }
    }
  }

  /// SharedPreferences key for the v1 welcome modal seen flag (backlog #36).
  /// Independent from the legacy `onboarding_seen` key so QA can reset just
  /// the new modal without disturbing existing users.
  static const String _welcomeModalSeenKey = 'advocat_onboarding_v1_seen';

  Future<void> _checkFirstTimeOnboarding() async {
    try {
      // EU AI Act Art. 50(1) — register() routes straight to /home and the
      // router blocks authenticated users from /onboarding, so users who
      // sign up in-app would otherwise NEVER see the AI-not-a-lawyer modal
      // (it only fired from the onboarding screen). Mirror that trigger
      // here, gated by the same shared-prefs key
      // (`ai_disclaimer_modal_seen_v1`) so it shows at most once per
      // device regardless of which surface fired first. Runs BEFORE the
      // welcome-modal seen check so existing users who skipped onboarding
      // still get their one-time disclosure.
      final showDisclaimer = await AiDisclaimerBanner.shouldShowModal();
      if (showDisclaimer && mounted) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const AiDisclaimerBanner.modal(
            key: Key('home_ai_disclaimer_modal'),
          ),
        );
      }
      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool(_welcomeModalSeenKey) ?? false;
      if (seen) return;

      // Demo users are exploring — don't seed sample-case noise.
      final isDemo = ref.read(isDemoModeProvider);
      if (isDemo) {
        unawaited(prefs.setBool(_welcomeModalSeenKey, true));
        return;
      }

      // Settle a frame so the screen paints under the modal.
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;

      final locale = Localizations.localeOf(context).languageCode;
      final action = await showWelcomeModal(context, locale: locale);
      // Mark seen regardless of choice — the user has had their one shot.
      unawaited(prefs.setBool(_welcomeModalSeenKey, true));
      if (!mounted) return;

      switch (action) {
        case WelcomeAction.sampleCase:
          unawaited(context.push('/chat/${SampleCase.id}'));
          break;
        case WelcomeAction.uploadContract:
          unawaited(context.push(AppRoutes.scan));
          break;
        case WelcomeAction.askQuestion:
          unawaited(context.push('/chat/general'));
          break;
        case WelcomeAction.skip:
          break;
      }
    } catch (_) {
      // SharedPreferences failure — skip onboarding silently
    }
  }

  @override
  Widget build(BuildContext context) {
    final casesAsync = ref.watch(casesProvider);
    final deadlinesAsync = ref.watch(allDeadlinesProvider);
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(casesProvider);
          ref.invalidate(allDeadlinesProvider);
          ref.invalidate(currentUserProvider);
        },
        child: CustomScrollView(
          slivers: [
            // ── Greeting header ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Builder(
                builder: (context) {
                  final isDemo = ref.watch(isDemoModeProvider);
                  final displayName = isDemo
                      ? (AppLocalizations.of(context)?.guestUser ?? 'Guest')
                      : userAsync.valueOrNull?.fullName;
                  final avatarUrl = isDemo ? null : userAsync.valueOrNull?.avatarUrl;
                  return _GreetingHeader(userName: displayName, avatarUrl: avatarUrl);
                },
              ),
            ),

            // ── Pkg 9 Deadline Radar (case_deadlines table) ─────────────
            const SliverToBoxAdapter(child: DeadlineRadarWidget()),

            // ── Urgent deadline banner (legacy `deadlines` table) ────────
            SliverToBoxAdapter(
              child: deadlinesAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (deadlines) {
                  final urgent = deadlines.where((d) {
                    if (d.status == DeadlineStatus.completed ||
                        d.status == DeadlineStatus.cancelled) {
                      return false;
                    }
                    final days = AppDateUtils.daysUntil(d.dueDate);
                    return days <= 7;
                  }).toList();

                  if (urgent.isEmpty) return const SizedBox.shrink();

                  // Show the most urgent one
                  urgent.sort((a, b) => a.dueDate.compareTo(b.dueDate));
                  return _UrgentBanner(deadline: urgent.first);
                },
              ),
            ),

            // ── Quick actions ────────────────────────────────────────────
            const SliverToBoxAdapter(child: _QuickActions()),

            // ── How to use ─────────────────────────────────────────────
            const SliverToBoxAdapter(child: _HowToUseButton()),

            // ── Premium upgrade card ─────────────────────────────────────
            const SliverToBoxAdapter(child: _PremiumUpgradeCard()),

            // ── Cases or empty state ─────────────────────────────────────
            casesAsync.when(
              // Cold-start skeleton: 2 case-card placeholders. Greeting +
              // deadline radar render above this sliver from their own
              // providers (cases is typically the slowest). Honors WCAG
              // reduce-motion via _ReduceMotionShimmer.
              loading: () => SliverList(
                delegate: SliverChildListDelegate(const [
                  SizedBox(height: AppSpacing.md),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Column(
                      children: [
                        CaseCardSkeleton(),
                        SizedBox(height: AppSpacing.sm),
                        CaseCardSkeleton(),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.lg),
                ]),
              ),
              error: (error, _) => SliverFillRemaining(
                child: _ErrorState(
                  message: AppLocalizations.of(context)?.couldNotLoadCases ?? 'Could not load your cases',
                  onRetry: () => ref.invalidate(casesProvider),
                ),
              ),
              data: (cases) {
                if (cases.isEmpty) {
                  return const SliverToBoxAdapter(child: _EmptyState());
                }

                final activeCases = cases
                    .where((c) =>
                        c.status != CaseStatus.closed &&
                        c.status != CaseStatus.resolved)
                    .toList();

                return SliverList(
                  delegate: SliverChildListDelegate([
                    // Active cases header
                    if (activeCases.isNotEmpty) ...[
                      _SectionHeader(
                        title: AppLocalizations.of(context)?.activeCases ?? 'Active Cases',
                        trailing: cases.length > 3
                            ? TextButton(
                                onPressed: () => context.go(AppRoutes.cases),
                                child: Text(AppLocalizations.of(context)?.viewAll ?? 'View All'),
                              )
                            : null,
                      ),
                      ...activeCases.take(5).map(
                            (c) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.xs,
                              ),
                              child: CaseCard(
                                legalCase: c,
                                onTap: () => context.push('/cases/${c.id}'),
                              ),
                            ),
                          ),
                    ],

                    // Recent activity
                    const SizedBox(height: AppSpacing.md),
                    _SectionHeader(title: AppLocalizations.of(context)?.recentActivity ?? 'Recent Activity'),
                    _RecentActivity(cases: cases),
                    const SizedBox(height: AppSpacing.lg),
                  ]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Greeting Header
// ---------------------------------------------------------------------------

class _GreetingHeader extends ConsumerWidget {
  const _GreetingHeader({this.userName, this.avatarUrl});

  final String? userName;
  final String? avatarUrl;

  String _greeting(AppLocalizations l) {
    final hour = DateTime.now().hour;
    final name = _firstName;
    final n = name.isEmpty ? '' : name;
    String text;
    if (hour < 6) {
      text = l.goodNight(n);
    } else if (hour < 12) {
      text = l.goodMorning(n);
    } else if (hour < 17) {
      text = l.goodAfternoon(n);
    } else {
      text = l.goodEvening(n);
    }
    // Remove trailing comma+space when name is empty: "Добрый день, " → "Добрый день"
    return text.replaceAll(RegExp(r',\s*$'), '').trim();
  }

  IconData get _timeIcon {
    final hour = DateTime.now().hour;
    if (hour < 6) return Icons.dark_mode_outlined;
    if (hour < 12) return Icons.wb_sunny_outlined;
    if (hour < 17) return Icons.wb_cloudy_outlined;
    if (hour < 21) return Icons.wb_twilight_outlined;
    return Icons.dark_mode_outlined;
  }

  Color get _timeColor {
    final hour = DateTime.now().hour;
    if (hour < 6) return const Color(0xFF6366F1);
    if (hour < 12) return const Color(0xFFF59E0B);
    if (hour < 17) return AppColors.accent;
    if (hour < 21) return const Color(0xFFF97316);
    return const Color(0xFF6366F1);
  }

  String get _firstName {
    if (userName == null || userName!.isEmpty) return '';
    return userName!.split(' ').first;
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    final currentCode = ref.read(localeProvider).languageCode;

    showModalBottomSheet(
      context: context,
      // Dark-mode aware: in light theme this resolves to AppColors.surface,
      // in dark theme to AppColors.darkSurface (see config/theme.dart).
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.5,
        maxChildSize: 0.8,
        expand: false,
        builder: (ctx, scrollController) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                AppLocalizations.of(context)?.language ?? 'Language',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    for (final lang in supportedLanguages)
                      ListTile(
                        leading: Text(lang.flag, style: const TextStyle(fontSize: 28)),
                        title: Text(
                          lang.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 17,
                          ),
                        ),
                        trailing: currentCode == lang.code
                            ? const Icon(Icons.check_rounded, color: AppColors.accent, size: 28)
                            : null,
                        onTap: () {
                          ref.read(localeProvider.notifier).setLocale(Locale(lang.code));
                          Navigator.pop(ctx);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xs,
        ),
        child: Row(
          children: [
            // User avatar or time icon
            if (avatarUrl != null)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: NetworkImage(avatarUrl!),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              )
            else
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _firstName.isNotEmpty
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primary, AppColors.accent],
                        )
                      : null,
                  color: _firstName.isEmpty
                      ? AppColors.accent.withValues(alpha: 0.15)
                      : null,
                ),
                child: _firstName.isNotEmpty
                    ? Center(
                        child: Text(
                          _firstName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : Icon(_timeIcon, color: AppColors.accent, size: 22),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [AppColors.primary, _timeColor],
                ).createShader(bounds),
                child: Text(
                  _greeting(l),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                ),
              ),
            ),
            // Globe icon for quick language switching
            IconButton(
              onPressed: () => _showLanguagePicker(context, ref),
              icon: const Icon(Icons.language_rounded),
              color: AppColors.textSecondary,
              tooltip: l.language,
              iconSize: 24,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Urgent Deadline Banner
// ---------------------------------------------------------------------------

class _UrgentBanner extends StatelessWidget {
  const _UrgentBanner({required this.deadline});

  final Deadline deadline;

  @override
  Widget build(BuildContext context) {
    final days = AppDateUtils.daysUntil(deadline.dueDate);
    final isOverdue = days < 0;
    final bgColor = isOverdue
        ? AppColors.error.withValues(alpha: 0.08)
        : days <= 3
            ? AppColors.error.withValues(alpha: 0.08)
            : AppColors.warning.withValues(alpha: 0.08);
    final fgColor = isOverdue || days <= 3 ? AppColors.error : AppColors.warning;
    final icon = isOverdue ? Icons.error_outline : Icons.warning_amber_rounded;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: fgColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: fgColor, size: 24),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppDateUtils.urgencyLabel(deadline.dueDate),
                    style: TextStyle(
                      color: fgColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    deadline.title,
                    style: TextStyle(
                      color: fgColor.withValues(alpha: 0.85),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // chevron_right is auto-mirrored by Flutter in RTL.
            Icon(
              Icons.chevron_right,
              color: fgColor.withValues(alpha: 0.6),
              textDirection: Directionality.of(context),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick Actions Row
// ---------------------------------------------------------------------------

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _QuickActionButton(
                // Brand: AppIcons.scan (Phosphor) replaces Material
                // `document_scanner_outlined`. Maps to the same /scan route.
                icon: AppIcons.scan,
                label: l.scanDocument,
                color: AppColors.accent,
                onTap: () => context.push(AppRoutes.scan),
              ),
              _QuickActionButton(
                // Checker = "this contract is safe" — `ai` (brain) reads as
                // "AI-reviewed" better than `verified_user`.
                icon: AppIcons.ai,
                label: l.checkerTitle,
                color: AppColors.primary,
                onTap: () => context.push(AppRoutes.checker),
              ),
              _QuickActionButton(
                // Legal-rights section: kept thematically with `consilium`
                // (users / panel) instead of Material gavel — gavel reads as
                // "court", and this tile opens rights, not courts.
                icon: AppIcons.consilium,
                label: l.legalSection,
                color: AppColors.primary,
                onTap: () => context.push(AppRoutes.rights),
              ),
              _QuickActionButton(
                // Legal-aid calculator stays on Material `calculate_outlined`
                // until AppIcons gains a dedicated calculator/coins glyph —
                // brand consistency isn't worth a wrong-semantics swap here.
                icon: Icons.calculate_outlined,
                label: l.legalAidCalculator,
                color: AppColors.warning,
                onTap: () => context.push(AppRoutes.legalAid),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _QuickActionButton(
                // Vault entry — `AppIcons.vault` (Phosphor safe) reads as
                // "encrypted storage" much more clearly than a bare padlock.
                icon: AppIcons.vault,
                label: l.documents,
                color: AppColors.accent,
                onTap: () => context.push(AppRoutes.vault),
              ),
              _QuickActionButton(
                icon: AppIcons.inbox,
                label: l.email,
                color: AppColors.info,
                onTap: () => context.push(AppRoutes.email),
              ),
              _ShieldPulsingButton(
                label: l.aiAssistant,
                onTap: () => context.push('/chat/general'),
              ),
              // Pkg 7 Drafting Studio — replaces the previous "callAI / coming
              // soon" placeholder (2026-05-27). Drafts + Vault are now both
              // reachable in ≤2 taps from Home: Drafts via this tile and Vault
              // via the lock-icon tile two slots earlier in the same grid.
              _QuickActionButton(
                icon: AppIcons.draft,
                label: l.draftsTab,
                color: AppColors.success,
                onTap: () => context.push(AppRoutes.drafts),
              ),
              _QuickActionButton(
                // "New case" — folder (caseFolder) is the canonical case glyph
                // in AppIcons; Material `add_circle_outline` was generic.
                icon: AppIcons.caseFolder,
                label: l.newCase,
                color: AppColors.primary,
                onTap: () => context.push(AppRoutes.caseCreate),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Third Quick Actions row — Contract Review entry point. Until
          // 2026-05-27 Contract Review was reachable only through chat
          // (PDF upload + classify-contract auto-detect chip). That gave it
          // ~2/10 discoverability for the highest-value paid feature. This
          // tile surfaces the standalone screen at /contract-review; the
          // chat detection path is preserved alongside it.
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _QuickActionButton(
                // Contract Review uses `contract` (certificate glyph), the
                // brand-consistent signal for "executed legal document"
                // — distinct from `document` (generic file) and `draft`
                // (work-in-progress composition).
                icon: AppIcons.contract,
                label: l.contractReviewTitle,
                color: AppColors.accent,
                onTap: () => context.push(AppRoutes.contractReview),
              ),
              // Contract Version Compare — diff two versions of a contract.
              // Builds on the same upload + analysis pipeline; sits next to
              // Contract Review for discoverability.
              _QuickActionButton(
                icon: Icons.compare_arrows_rounded,
                label: l.contractCompareTitle,
                color: AppColors.accent,
                onTap: () => context.push(AppRoutes.contractCompare),
              ),
            ],
          ),

          // Wave-2 tools row — self-service helpers. Wrap so 6 tiles flow
          // onto multiple lines on narrow screens.
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _QuickActionButton(
                icon: Icons.lightbulb_outline,
                label: l.explainPlainTitle,
                color: AppColors.info,
                onTap: () => context.push(AppRoutes.explainPlain),
              ),
              _QuickActionButton(
                icon: Icons.calculate_outlined,
                label: l.calcHubTitle,
                color: AppColors.primary,
                onTap: () => context.push(AppRoutes.calculators),
              ),
              _QuickActionButton(
                icon: Icons.mail_outline,
                label: l.demandLetterTitle,
                color: AppColors.accentDark,
                onTap: () => context.push(AppRoutes.demandLetter),
              ),
              _QuickActionButton(
                icon: Icons.checklist_rtl_outlined,
                label: l.docCollectTitle,
                color: AppColors.primary,
                onTap: () => context.push(AppRoutes.docCollection),
              ),
              _QuickActionButton(
                icon: Icons.event_repeat_outlined,
                label: l.renewalTitle,
                color: AppColors.accent,
                onTap: () => context.push(AppRoutes.renewals),
              ),
              _QuickActionButton(
                icon: Icons.insights_outlined,
                label: l.costEstimateTitle,
                color: AppColors.info,
                onTap: () => context.push(AppRoutes.costEstimator),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// _ShieldPulsingButton — restored shield-icon pulsing tile (formerly the
// AdvocatPro quick-action design from commit 2e6b19a~1) with the same
// scale animation, soft shadow, accent ring, and shield_pro.svg artwork —
// but parameterized: caller controls label and onTap. Used on the home grid
// to make the AI Assistant tile visually pop with the brand shield while
// still routing to /chat/general.
class _ShieldPulsingButton extends StatefulWidget {
  const _ShieldPulsingButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  State<_ShieldPulsingButton> createState() => _ShieldPulsingButtonState();
}

class _ShieldPulsingButtonState extends State<_ShieldPulsingButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: Center(
                child: AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/images/shield_pro.svg',
                            width: 44,
                            height: 44,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// How To Use Button + Tutorial Bottom Sheet
// ---------------------------------------------------------------------------

class _HowToUseButton extends StatelessWidget {
  const _HowToUseButton();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: AppSpacing.md),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          onPressed: () => _showTutorial(context, l),
          icon: const Icon(Icons.help_outline_rounded, size: 16),
          label: Text(l.howToUse),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textTertiary,
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
    );
  }

  void _showTutorial(BuildContext context, AppLocalizations l) {
    showModalBottomSheet(
      context: context,
      // Dark-mode aware. See _showLanguagePicker above for the rationale.
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l.howToUse,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _TutorialStep(
                icon: Icons.support_agent_rounded,
                color: AppColors.accent,
                title: l.tutorialStep1Title,
                description: l.tutorialStep1Desc,
              ),
              const SizedBox(height: AppSpacing.md),
              _TutorialStep(
                icon: Icons.gavel_outlined,
                color: AppColors.primary,
                title: l.tutorialStep2Title,
                description: l.tutorialStep2Desc,
              ),
              const SizedBox(height: AppSpacing.md),
              _TutorialStep(
                icon: Icons.document_scanner_outlined,
                color: AppColors.info,
                title: l.tutorialStep3Title,
                description: l.tutorialStep3Desc,
              ),
              const SizedBox(height: AppSpacing.md),
              _TutorialStep(
                icon: Icons.rocket_launch_rounded,
                color: AppColors.success,
                title: l.tutorialStep4Title,
                description: l.tutorialStep4Desc,
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(l.tutorialStep4Title),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TutorialStep extends StatelessWidget {
  const _TutorialStep({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Premium Upgrade Card
// ---------------------------------------------------------------------------

class _PremiumUpgradeCard extends StatefulWidget {
  const _PremiumUpgradeCard();

  @override
  State<_PremiumUpgradeCard> createState() => _PremiumUpgradeCardState();
}

class _PremiumUpgradeCardState extends State<_PremiumUpgradeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: GestureDetector(
        onTap: () => context.push(AppRoutes.subscription),
        child: AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1A3C40),
                    Color(0xFF2D6A6A),
                    Color(0xFF1A3C40),
                  ],
                ),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.25),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4DA3A0).withValues(alpha: 0.20 + _glowAnimation.value * 0.25),
                    blurRadius: 12 + _glowAnimation.value * 10,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: const Color(0xFF4DA3A0).withValues(alpha: 0.10 + _glowAnimation.value * 0.15),
                    blurRadius: 20 + _glowAnimation.value * 8,
                    spreadRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Shield Pro icon
                  SvgPicture.asset(
                    'assets/images/shield_pro.svg',
                    width: 36,
                    height: 36,
                  ),
                  const SizedBox(width: 12),
                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)?.advocatProTitle ?? 'Advocat Pro',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                AppLocalizations.of(context)?.advocatProSubtitle ?? 'Unlock premium features',
                                style: const TextStyle(
                                  color: Color(0xFF8ECAC7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'from €19.99/mo',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Chevron — auto-mirrored by Flutter in RTL via Directionality.
                  Icon(
                    Icons.chevron_right_rounded,
                    color: const Color(0xFF8ECAC7),
                    size: 24,
                    textDirection: Directionality.of(context),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section Header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recent Activity (timeline-style)
// ---------------------------------------------------------------------------

class _RecentActivity extends StatelessWidget {
  const _RecentActivity({required this.cases});

  final List<LegalCase> cases;

  @override
  Widget build(BuildContext context) {
    // Generate recent activity items from case data
    final activities = <_ActivityItem>[];

    final l = AppLocalizations.of(context);
    for (final c in cases) {
      activities.add(_ActivityItem(
        title: l?.caseUpdated ?? 'Case updated',
        subtitle: c.title,
        time: c.updatedAt ?? c.createdAt,
        icon: Icons.update,
        color: AppColors.accent,
      ));
    }

    activities.sort((a, b) => b.time.compareTo(a.time));
    final recent = activities.take(5).toList();

    if (recent.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          l?.noRecentActivity ?? 'No recent activity',
          style: const TextStyle(color: AppColors.textTertiary),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              for (int i = 0; i < recent.length; i++) ...[
                _ActivityRow(
                  item: recent[i],
                  isLast: i == recent.length - 1,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityItem {
  const _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final DateTime time;
  final IconData icon;
  final Color color;
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item, this.isLast = false});

  final _ActivityItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot + line
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: item.color,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        timeago.format(item.time),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty State
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  /// CRO recommendation (2026-05-27): on a brand-new account, surface 3
  /// intent chips that pre-load the chat with a starter prompt. These map
  /// to the highest-converting intake categories.
  void _onIntentChip(BuildContext context, String prompt) {
    context.push('/chat/general?q=${Uri.encodeComponent(prompt)}');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final title = l.emptyHomeTitle;
    final body = l.emptyHomeBody;
    final chip1 = l.intentChip1;
    final chip2 = l.intentChip2;
    final chip3 = l.intentChip3;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Advocat shield logo — original PNG (whitespace-trimmed variant so
          // there is no padding to clip; restored 2026-07-03 after a prior
          // design pass had swapped the original for an SVG reconstruction).
          Image.asset(
            'assets/images/logo_shield_tight.png',
            width: 130,
            height: 130,
            fit: BoxFit.contain,
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Intent chips (CRO 2026-05-27) — wrap so they reflow on small
          // viewports. Each chip pushes /chat/general with `?q=` prefilled.
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _IntentChip(label: chip1, onTap: () => _onIntentChip(context, chip1)),
              _IntentChip(label: chip2, onTap: () => _onIntentChip(context, chip2)),
              _IntentChip(label: chip3, onTap: () => _onIntentChip(context, chip3)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Create case button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push(AppRoutes.caseCreate),
              icon: const Icon(Icons.add, size: 20),
              label: Text(l.createCase),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Or chat with AI
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/chat/general'),
              icon: const Icon(Icons.smart_toy_outlined, size: 20),
              label: Text(l.aiAssistant),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

// _TipItem removed — tips block removed from empty state

// ---------------------------------------------------------------------------
// Intent Chip — used in the brand-new-account empty state to deep-link
// into /chat/general with `?q=` so the AI can open the conversation with
// the user's intent pre-filled. Subtle: outlined pill, accent border on
// tap. Tapping pushes; no async work happens here.
// ---------------------------------------------------------------------------

class _IntentChip extends StatelessWidget {
  const _IntentChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error State
// ---------------------------------------------------------------------------

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context)?.retry ?? 'Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
