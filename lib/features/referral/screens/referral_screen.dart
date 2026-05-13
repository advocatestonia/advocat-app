// lib/features/referral/screens/referral_screen.dart
// -----------------------------------------------------------------------------
// "Invite friends" screen — the user-facing surface of the referral program.
//
// Layout:
//   1. Hero card        — title + one-liner ("Get a free month. Give a free
//                         month.").
//   2. Share link tile  — advocat.ee/r/<code> + Copy + native Share.
//   3. Stats row        — invites_sent / conversions / free_months_earned.
//   4. Channel buttons  — WhatsApp / Telegram / Email.
//
// Reached from the Settings screen ("Invite friends" tile) and after-review
// CTA chips. The screen is auto-disposed when the user leaves so the
// FutureProviders refetch on next visit.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/advocat_gradient_header.dart';
import '../models/referral_stats.dart';
import '../state/referral_providers.dart';

class ReferralScreen extends ConsumerWidget {
  const ReferralScreen({super.key});

  static const String routePath = '/referral';
  static const String routeName = 'referral';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final statsAsync = ref.watch(referralStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AdvocatGradientHeader(title: l.referralTitle),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(referralStatsProvider);
          ref.invalidate(referralCodeProvider);
          await ref.read(referralStatsProvider.future);
        },
        child: statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorState(message: e.toString(), onRetry: () {
            ref.invalidate(referralStatsProvider);
          }),
          data: (stats) => _ReferralBody(stats: stats),
        ),
      ),
    );
  }
}

class _ReferralBody extends StatelessWidget {
  const _ReferralBody({required this.stats});
  final ReferralStats stats;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _HeroCard(subtitle: l.referralSubtitle),
        const SizedBox(height: AppSpacing.md),
        if (stats.hasCode) ...[
          _ShareLinkCard(stats: stats),
          const SizedBox(height: AppSpacing.md),
        ],
        _StatsRow(stats: stats),
        const SizedBox(height: AppSpacing.lg),
        if (stats.hasCode) _ChannelButtons(shareUrl: stats.shareUrl),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

// ─── Hero ──────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.subtitle});
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.card_giftcard, color: Colors.white, size: 28),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Share link ────────────────────────────────────────────────────────────

class _ShareLinkCard extends StatelessWidget {
  const _ShareLinkCard({required this.stats});
  final ReferralStats stats;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.referralYourLink,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          SelectableText(
            stats.shareUrl,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _copyToClipboard(context, stats.shareUrl),
                  icon: const Icon(Icons.copy, size: 18),
                  label: Text(l.referralCopyLink),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _nativeShare(stats.shareUrl, context),
                  icon: const Icon(Icons.ios_share, size: 18),
                  label: Text(l.referralShare),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Future<void> _copyToClipboard(BuildContext context, String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    final l = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.referralLinkCopied)),
    );
  }

  static Future<void> _nativeShare(String url, BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    await Share.share('${l.referralSubtitle} $url');
  }
}

// ─── Stats row ─────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});
  final ReferralStats stats;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: l.referralStatsInvited,
            value: stats.invitesSent,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatTile(
            label: l.referralStatsConverted,
            value: stats.conversions,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatTile(
            label: l.referralStatsEarned,
            value: stats.freeMonthsEarned,
            highlight: stats.freeMonthsEarned > 0,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    this.highlight = false,
  });
  final String label;
  final int value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.accent.withValues(alpha: 0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: highlight ? AppColors.accent : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: highlight ? AppColors.accent : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Channel buttons ───────────────────────────────────────────────────────

class _ChannelButtons extends StatelessWidget {
  const _ChannelButtons({required this.shareUrl});
  final String shareUrl;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final message = '${l.referralSubtitle} $shareUrl';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ChannelButton(
          icon: Icons.chat,
          label: l.referralShareWhatsApp,
          color: const Color(0xFF25D366),
          onTap: () => _openExternal(
            'https://wa.me/?text=${Uri.encodeComponent(message)}',
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _ChannelButton(
          icon: Icons.send,
          label: l.referralShareTelegram,
          color: const Color(0xFF229ED9),
          onTap: () => _openExternal(
            'https://t.me/share/url?url=${Uri.encodeComponent(shareUrl)}'
            '&text=${Uri.encodeComponent(l.referralSubtitle)}',
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _ChannelButton(
          icon: Icons.email_outlined,
          label: l.referralShareEmail,
          color: AppColors.primary,
          onTap: () => _openExternal(
            'mailto:?subject=${Uri.encodeComponent(l.referralEmailSubject)}'
            '&body=${Uri.encodeComponent(message)}',
          ),
        ),
      ],
    );
  }

  static Future<void> _openExternal(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _ChannelButton extends StatelessWidget {
  const _ChannelButton({
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
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

// ─── Error state ───────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const SizedBox(height: 80),
        const Icon(
          Icons.cloud_off,
          size: 48,
          color: AppColors.textSecondary,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l.referralLoadError,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: TextButton(
            onPressed: onRetry,
            child: Text(l.referralRetry),
          ),
        ),
      ],
    );
  }
}
