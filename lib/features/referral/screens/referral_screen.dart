// lib/features/referral/screens/referral_screen.dart
// -----------------------------------------------------------------------------
// "Invite friends" screen — the user-facing surface of the referral program.
//
// Layout (top to bottom):
//   1. Hero card           — title + one-liner ("Get a free month. Give a
//                            free month.").
//   2. Share link tile     — advocat.ee/r/<code> + Copy + native Share.
//   3. Stats row           — invites_sent / conversions / free_months_earned.
//   4. Channel buttons     — WhatsApp / Telegram / Email.
//   5. Recent activity     — anonymised "invited 3d ago → activated 2d ago"
//                            rows. Empty state when no referrals yet.
//   6. Anti-fraud footnote — "Maximum 12 successful referrals per year."
//
// Reached from the Settings screen ("Invite friends" tile), after-review
// CTA chips, and the post-first-chat nudge (HomeScreen). When the user
// lands here, the SharedPreferences flag `referral_seen` is flipped so
// the nudge does not fire again.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/advocat_gradient_header.dart';
import '../models/referral_stats.dart';
import '../state/referral_providers.dart';

/// SharedPreferences key flipped to `true` when the user opens this screen.
/// Read by the HomeScreen onboarding nudge to suppress repeat impressions.
const String kReferralSeenPrefKey = 'referral_seen';

class ReferralScreen extends ConsumerStatefulWidget {
  const ReferralScreen({super.key});

  static const String routePath = '/referral';
  static const String routeName = 'referral';

  @override
  ConsumerState<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<ReferralScreen> {
  @override
  void initState() {
    super.initState();
    // Best-effort: mark the screen as seen so the home nudge stops firing.
    // A failure here is harmless — the nudge will simply show once more.
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setBool(kReferralSeenPrefKey, true))
        .ignore();
  }

  @override
  Widget build(BuildContext context) {
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
          error: (e, _) => _ErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(referralStatsProvider),
          ),
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
        const SizedBox(height: AppSpacing.sm),
        _StatsCopyBlock(stats: stats),
        const SizedBox(height: AppSpacing.lg),
        if (stats.hasCode) _ChannelButtons(shareUrl: stats.shareUrl),
        const SizedBox(height: AppSpacing.lg),
        _RecentActivitySection(stats: stats),
        const SizedBox(height: AppSpacing.lg),
        const _AntiFraudFootnote(),
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
    return Semantics(
      label: subtitle,
      header: true,
      child: Container(
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
    return Semantics(
      label: '$label: $value',
      child: Container(
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
      ),
    );
  }
}

// ─── Stats copy ────────────────────────────────────────────────────────────
//
// The three tiles above are compact "5/3/2"-style chips. Below them we
// surface the same numbers in plural-aware sentences so the screen reads
// like a personal report rather than a dashboard.

class _StatsCopyBlock extends StatelessWidget {
  const _StatsCopyBlock({required this.stats});
  final ReferralStats stats;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final lines = <String>[
      l.referralStatsInvitedCount(stats.invitesSent),
      l.referralStatsConvertedCount(stats.conversions),
      l.referralStatsEarnedCount(stats.freeMonthsEarned),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                line,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
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

// ─── Recent activity ───────────────────────────────────────────────────────

class _RecentActivitySection extends StatelessWidget {
  const _RecentActivitySection({required this.stats});
  final ReferralStats stats;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.referralRecentActivity,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (!stats.hasActivity)
          _EmptyActivityCard(message: l.referralEmpty)
        else
          ...stats.recentActivity.map((a) => _ActivityRow(activity: a)),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity});
  final ReferralActivity activity;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final invited = l.referralActivityInvited(
      _formatRelative(activity.invitedAt, now, l),
    );
    final activated = activity.hasConverted
        ? l.referralActivityActivated(
            _formatRelative(activity.convertedAt!, now, l),
          )
        : l.referralActivityPending;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: activity.hasConverted
                  ? AppColors.accent
                  : AppColors.textTertiary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '$invited  →  $activated',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Minimal "N days/hours/min ago" formatter — locale-neutral suffixes
  /// (we don't have a relative-time pluraliser in the ARB yet, and
  /// timeago is not currently a dependency). Falls back to ISO date for
  /// anything older than 30 days. Good enough for an anonymised activity
  /// log; if/when we add full timeago we'll swap this for `l.daysAgo(n)`.
  static String _formatRelative(
    DateTime when,
    DateTime now,
    AppLocalizations l,
  ) {
    final diff = now.difference(when);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    final y = when.year.toString().padLeft(4, '0');
    final m = when.month.toString().padLeft(2, '0');
    final d = when.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

class _EmptyActivityCard extends StatelessWidget {
  const _EmptyActivityCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border, style: BorderStyle.solid),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.people_outline,
            color: AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Anti-fraud footnote ───────────────────────────────────────────────────

class _AntiFraudFootnote extends StatelessWidget {
  const _AntiFraudFootnote();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Row(
      children: [
        const Icon(
          Icons.info_outline,
          color: AppColors.textTertiary,
          size: 14,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            l.referralAntiFraud,
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
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
