// lib/features/referral/screens/referral_landing_screen.dart
// -----------------------------------------------------------------------------
// Landing surface for `/r/<code>` links. Anonymous-readable — this is the
// first thing an invited friend sees when they tap the WhatsApp / Telegram /
// email share their inviter sent.
//
// Flow:
//   1. Parse the code from the URL path.
//   2. Call ReferralService.lookupCode(code) — anon-friendly endpoint that
//      returns the inviter's first name (or null) for the social-proof
//      headline. 404 → fallback "link expired" copy.
//   3. Stash the code in SharedPreferences (`pending_referral_code`) so the
//      RegisterScreen can pull it after the user signs up and call
//      ReferralService.attribute() against the authenticated session.
//   4. Render the hero + CTA.
//
// The screen never tries to attribute itself — attribution requires an
// authenticated JWT (see handler.ts comments). The Register / Login screens
// pick up the pending code on their first successful auth.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../config/router.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../data/referral_service.dart';

/// SharedPreferences key written by the landing, read by the register flow.
const String kPendingReferralCodePrefKey = 'pending_referral_code';

/// Provider: lookup the inviter's first name for the given code. Public —
/// runs on the anon SDK client. Returns [CodeLookupOk] (possibly with null
/// name) or [CodeLookupInvalid].
final referralLandingLookupProvider =
    FutureProvider.autoDispose.family<CodeLookupResult, String>((ref, code) {
  return ref.read(referralServiceProvider).lookupCode(code);
});

class ReferralLandingScreen extends ConsumerStatefulWidget {
  const ReferralLandingScreen({super.key, required this.code});

  static const String routePath = '/r/:code';
  static const String routeName = 'referralLanding';

  /// The 6–16-char alphanumeric code from the URL path.
  final String code;

  @override
  ConsumerState<ReferralLandingScreen> createState() =>
      _ReferralLandingScreenState();
}

class _ReferralLandingScreenState
    extends ConsumerState<ReferralLandingScreen> {
  @override
  void initState() {
    super.initState();
    _stashCode();
  }

  /// Stash the code in SharedPreferences so the register flow can claim
  /// it after auth. Best-effort — a failure here is harmless (worst case
  /// the user simply doesn't get attribution).
  Future<void> _stashCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        kPendingReferralCodePrefKey,
        widget.code.trim().toLowerCase(),
      );
    } catch (_) {
      // Swallow — analytics-only effect.
    }
  }

  @override
  Widget build(BuildContext context) {
    final lookupAsync = ref.watch(referralLandingLookupProvider(widget.code));
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: lookupAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          // Network error → still show the generic landing rather than a
          // dead-end. Better to over-deliver than fail closed.
          error: (_, __) => const _LandingBody(
            inviterFirstName: null,
            expired: false,
          ),
          data: (result) => switch (result) {
            CodeLookupOk(:final inviterFirstName) => _LandingBody(
                inviterFirstName: inviterFirstName,
                expired: false,
              ),
            CodeLookupInvalid() => const _LandingBody(
                inviterFirstName: null,
                expired: true,
              ),
          },
        ),
      ),
    );
  }
}

class _LandingBody extends StatelessWidget {
  const _LandingBody({
    required this.inviterFirstName,
    required this.expired,
  });
  final String? inviterFirstName;
  final bool expired;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const SizedBox(height: AppSpacing.lg),
        _HeroGradientCard(
          title: l.referralLandingTitle,
          subtitle: _subtitleFor(l),
          expired: expired,
        ),
        const SizedBox(height: AppSpacing.lg),
        _BenefitsBlock(text: l.referralLandingBenefits),
        const SizedBox(height: AppSpacing.xl),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          onPressed: () => context.go(AppRoutes.register),
          child: Text(l.referralLandingCta),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: () => context.go(AppRoutes.login),
          child: Text(l.referralLandingCtaSecondary),
        ),
      ],
    );
  }

  String _subtitleFor(AppLocalizations l) {
    if (expired) return l.referralLandingFallback;
    final name = inviterFirstName;
    if (name == null || name.isEmpty) {
      return l.referralLandingSubtitleGeneric;
    }
    return l.referralLandingSubtitle(name);
  }
}

class _HeroGradientCard extends StatelessWidget {
  const _HeroGradientCard({
    required this.title,
    required this.subtitle,
    required this.expired,
  });
  final String title;
  final String subtitle;
  final bool expired;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: expired
              ? const [AppColors.textTertiary, AppColors.textSecondary]
              : const [AppColors.primary, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            expired ? Icons.link_off : Icons.card_giftcard,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitsBlock extends StatelessWidget {
  const _BenefitsBlock({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified, color: AppColors.accent, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
