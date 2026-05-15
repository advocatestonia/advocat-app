import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../config/feature_flags.dart';
import '../../../config/router.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../main.dart';
import '../../../models/case_model.dart';
import '../../../models/deadline.dart';
import '../../../shared/utils/date_utils.dart';
import '../../../shared/widgets/gdpr_consent_dialog.dart';
import '../../../shared/pending_checkout.dart';
import '../../../services/demo_data.dart';
import '../../../services/stripe_checkout_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../cases/providers/cases_provider.dart';
import '../../cases/widgets/case_card.dart';
import '../../case_memory/widgets/deadline_radar_widget.dart';
import '../../deadlines/providers/deadlines_provider.dart';

// ---------------------------------------------------------------------------
// Home Dashboard
// ---------------------------------------------------------------------------

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _checkPaymentReturn();
    _checkFirstTimeOnboarding();
    _checkGdprConsent();
    _checkPendingCheckout();
    _maybeShowReferralNudge();
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
      // result since the snackbar is already on screen.
      unawaited(prefs.setBool('referral_nudge_shown', true));
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

  Future<void> _checkGdprConsent() async {
    try {
      final isDemo = ref.read(isDemoModeProvider);
      if (isDemo) return; // Skip GDPR dialog in demo mode

      final hasConsent = await hasGdprConsent();
      if (!hasConsent && mounted) {
        // Small delay so the screen renders first
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          final accepted = await showGdprConsentDialog(context);
          if (!accepted && mounted) {
            // User declined — sign them out
            unawaited(ref.read(authControllerProvider.notifier).logout());
          }
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
        // Refresh user profile to get updated subscription
        ref.invalidate(currentUserProvider);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // v24.2.3 UX-Tier-A: localise payment-success dialog (was EN).
            final l = AppLocalizations.of(context);
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(l?.paymentSuccessTitle ?? 'Payment successful'),
                content: Text(
                  l?.paymentSuccessBody ?? 'Your subscription is now active.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(l?.commonOk ?? 'OK'),
                  ),
                ],
              ),
            );
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _checkFirstTimeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool('onboarding_seen') ?? false;
      if (!seen && mounted) {
        // Small delay so the screen renders first
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          _showOnboardingSheet();
          await prefs.setBool('onboarding_seen', true);
        }
      }
    } catch (_) {
      // SharedPreferences failure — skip onboarding silently
    }
  }

  void _showOnboardingSheet() {
    final l = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'How it works',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _OnboardingStep(
                number: '1',
                icon: Icons.chat_bubble_outline_rounded,
                color: AppColors.accent,
                title: l.tutorialStep1Title,
                description: l.tutorialStep1Desc,
              ),
              const SizedBox(height: AppSpacing.md),
              _OnboardingStep(
                number: '2',
                icon: Icons.document_scanner_outlined,
                color: AppColors.info,
                title: l.tutorialStep3Title,
                description: l.tutorialStep3Desc,
              ),
              const SizedBox(height: AppSpacing.md),
              _OnboardingStep(
                number: '3',
                icon: Icons.check_circle_outline_rounded,
                color: AppColors.success,
                title: l.tutorialStep4Title,
                description: l.tutorialStep4Desc,
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
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
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
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
      backgroundColor: AppColors.surface,
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
            Icon(
              Icons.chevron_right,
              color: fgColor.withValues(alpha: 0.6),
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
                icon: Icons.document_scanner_outlined,
                label: l.scanDocument,
                color: AppColors.accent,
                onTap: () => context.push(AppRoutes.scan),
              ),
              _QuickActionButton(
                icon: Icons.verified_user_rounded,
                label: l.checkerTitle,
                color: AppColors.primary,
                onTap: () => context.push(AppRoutes.checker),
              ),
              _QuickActionButton(
                icon: Icons.gavel_outlined,
                label: l.legalSection,
                color: AppColors.primary,
                onTap: () => context.push(AppRoutes.rights),
              ),
              _QuickActionButton(
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
                icon: Icons.lock_outlined,
                label: l.documents,
                color: AppColors.accent,
                onTap: () => context.push(AppRoutes.vault),
              ),
              _QuickActionButton(
                icon: Icons.email_outlined,
                label: l.email,
                color: AppColors.info,
                onTap: () => context.push(AppRoutes.email),
              ),
              _ShieldPulsingButton(
                label: l.aiAssistant,
                onTap: () => context.push('/chat/general'),
              ),
              _QuickActionButton(
                icon: Icons.phone_in_talk_outlined,
                label: l.callAI,
                color: AppColors.success,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.comingSoon)),
                  );
                },
              ),
              _QuickActionButton(
                icon: Icons.add_circle_outline,
                label: l.newCase,
                color: AppColors.primary,
                onTap: () => context.push(AppRoutes.caseCreate),
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
// scale animation, soft shadow, accent ring, and shield_pro.png artwork —
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
                        child: Image.asset(
                          'assets/images/shield_pro.png',
                          width: 44,
                          height: 44,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                  );
                },
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
      padding: const EdgeInsets.only(left: AppSpacing.md),
      child: Align(
        alignment: Alignment.centerLeft,
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
      backgroundColor: AppColors.surface,
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
                  Image.asset(
                    'assets/images/shield_pro.png',
                    width: 36,
                    height: 36,
                    filterQuality: FilterQuality.high,
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
                  // Chevron
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF8ECAC7),
                    size: 24,
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
// Onboarding Step (for first-time bottom sheet)
// ---------------------------------------------------------------------------

class _OnboardingStep extends StatelessWidget {
  const _OnboardingStep({
    required this.number,
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  final String number;
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step number circle
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      number,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Advocat shield logo — negative margin to cut white space in PNG
          ClipRect(
            child: Align(
              alignment: Alignment.center,
              heightFactor: 0.65,
              child: Image.asset(
                'assets/images/logo_shield.png',
                width: 200,
                height: 200,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
          Text(
            l.noCasesYet,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          Text(
            l.startFirstCase,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 6),
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
