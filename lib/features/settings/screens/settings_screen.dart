import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/router.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../main.dart';
import '../../../shared/constants/app_icons.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../auth/providers/auth_provider.dart';
import 'edit_profile_screen.dart';

// ── Providers ────────────────────────────────────────────────────────────

final _pushNotificationsProvider = StateProvider<bool>((ref) => true);
final _deadlineRemindersProvider = StateProvider<bool>((ref) => true);
final _emailConnectedProvider = StateProvider<bool>((ref) => false);
final _connectedEmailProvider = StateProvider<String?>((ref) => null);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l.settings),
        backgroundColor: AppColors.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        children: [
          // ── Profile Section ────────────────────────────────────────────
          _buildProfileSection(context, ref),

          const SizedBox(height: AppSpacing.sm),

          // ── Language ───────────────────────────────────────────────────
          _SectionHeader(title: l.preferences),
          _SettingsTile(
            icon: AppIcons.language,
            title: l.language,
            subtitle: _languageLabelWithFlag(ref.watch(localeProvider).languageCode),
            trailing: const Icon(AppIcons.chevronRight, color: AppColors.textTertiary),
            onTap: () => _showLanguagePicker(context, ref),
          ),

          // ── Subscription ──────────────────────────────────────────────
          _buildSubscriptionTile(context, ref),

          const _SectionDivider(),

          // ── Notifications ─────────────────────────────────────────────
          _SectionHeader(title: l.notifications),
          _SettingsTile(
            icon: AppIcons.notificationsOutlined,
            title: l.pushNotifications,
            trailing: Switch.adaptive(
              value: ref.watch(_pushNotificationsProvider),
              onChanged: (v) =>
                  ref.read(_pushNotificationsProvider.notifier).state = v,
              activeThumbColor: Colors.white,
              activeTrackColor: AppColors.accent,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: AppColors.border,
            ),
          ),
          _SettingsTile(
            icon: AppIcons.timer,
            title: l.deadlineReminders,
            subtitle: l.deadlineRemindersDesc,
            trailing: Switch.adaptive(
              value: ref.watch(_deadlineRemindersProvider),
              onChanged: (v) =>
                  ref.read(_deadlineRemindersProvider.notifier).state = v,
              activeThumbColor: Colors.white,
              activeTrackColor: AppColors.accent,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: AppColors.border,
            ),
          ),

          const _SectionDivider(),

          // ── Email Integration ─────────────────────────────────────────
          _SectionHeader(title: l.emailIntegration),
          _buildEmailTile(context, ref),

          const _SectionDivider(),

          // ── Data & Privacy ────────────────────────────────────────────
          _SectionHeader(title: l.dataAndPrivacy),
          _SettingsTile(
            icon: AppIcons.dataExport,
            title: l.exportMyData,
            subtitle: l.exportDataDesc,
            onTap: () => _showExportDataDialog(context),
          ),
          _SettingsTile(
            icon: AppIcons.deleteAccount,
            iconColor: AppColors.error,
            title: l.deleteAccount,
            titleColor: AppColors.error,
            subtitle: l.deleteAccountDesc,
            onTap: () => _showDeleteAccountDialog(context, ref),
          ),

          const _SectionDivider(),

          // ── Legal ─────────────────────────────────────────────────────
          _SectionHeader(title: l.legalSection),
          _SettingsTile(
            icon: AppIcons.termsOutlined,
            title: l.termsOfService,
            trailing: const Icon(AppIcons.chevronRight, color: AppColors.textTertiary),
            onTap: () => _launchUrl('https://advocat.ee/terms'),
          ),
          _SettingsTile(
            icon: AppIcons.privacyOutlined,
            title: l.privacyPolicy,
            trailing: const Icon(AppIcons.chevronRight, color: AppColors.textTertiary),
            onTap: () => _launchUrl('https://advocat.ee/privacy'),
          ),
          _SettingsTile(
            icon: Icons.business_outlined,
            title: l.legalInformation,
            trailing: const Icon(AppIcons.chevronRight, color: AppColors.textTertiary),
            onTap: () => _showLegalInfoDialog(context),
          ),

          const _SectionDivider(),

          // ── About ─────────────────────────────────────────────────────
          _SectionHeader(title: l.aboutSection),
          _SettingsTile(
            icon: AppIcons.infoOutlined,
            title: l.appVersion,
            subtitle: '1.0.0 (Build 1)',
          ),
          _SettingsTile(
            icon: AppIcons.starOutlined,
            title: l.rateUs,
            trailing: const Icon(AppIcons.chevronRight, color: AppColors.textTertiary),
            onTap: () {
              // TODO: Open app store review page
            },
          ),
          _SettingsTile(
            icon: AppIcons.supportOutlined,
            title: l.contactSupport,
            trailing: const Icon(AppIcons.chevronRight, color: AppColors.textTertiary),
            onTap: () => _launchUrl('mailto:support@advocat.ee'),
          ),

          const _SectionDivider(),

          // ── Sign Out ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.lg,
            ),
            child: AppButton(
              label: l.signOut,
              variant: AppButtonVariant.danger,
              isFullWidth: true,
              leadingIcon: AppIcons.logout,
              onPressed: () => _showSignOutDialog(context, ref),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  // ── Profile ──────────────────────────────────────────────────────────

  Widget _buildProfileSection(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Accent gradient bar at the top of profile section
          Container(
            height: 3,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.accent, AppColors.accentLight, AppColors.accent],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: userAsync.when(
              loading: () => const SizedBox(
                height: 64,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (user) {
                if (user == null) return const SizedBox.shrink();
                final initials = user.fullName.isNotEmpty
                    ? user.fullName
                        .split(' ')
                        .take(2)
                        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
                        .join()
                    : '?';

                return Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.email,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => DraggableScrollableSheet(
                            initialChildSize: 0.92,
                            minChildSize: 0.5,
                            maxChildSize: 0.95,
                            expand: false,
                            builder: (ctx, _) => const ClipRRect(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(AppRadius.lg),
                              ),
                              child: EditProfileScreen(),
                            ),
                          ),
                        );
                      },
                      child: Text(
                        AppLocalizations.of(context)?.editProfile ?? 'Edit Profile',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Subscription tile ────────────────────────────────────────────────

  Widget _buildSubscriptionTile(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final tier = userAsync.whenOrNull(
            data: (u) => u?.subscriptionTier.name.toUpperCase()) ??
        'FREE';

    final l = AppLocalizations.of(context)!;
    return _SettingsTile(
      icon: AppIcons.subscriptionOutlined,
      title: l.subscription,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatusChip(
            label: tier,
            variant: tier == 'FREE'
                ? StatusChipVariant.neutral
                : StatusChipVariant.active,
            showDot: false,
          ),
          const SizedBox(width: 4),
          const Icon(AppIcons.chevronRight, color: AppColors.textTertiary),
        ],
      ),
      onTap: () => context.push(AppRoutes.subscription),
    );
  }

  // ── Email tile ───────────────────────────────────────────────────────

  Widget _buildEmailTile(BuildContext context, WidgetRef ref) {
    final connected = ref.watch(_emailConnectedProvider);
    final connectedEmail = ref.watch(_connectedEmailProvider);

    final l = AppLocalizations.of(context)!;
    return _SettingsTile(
      icon: AppIcons.emailOutlined,
      title: connected ? l.emailConnected : l.connectEmail,
      subtitle: connected
          ? connectedEmail ?? l.connected
          : l.syncLegalCorrespondence,
      trailing: connected
          ? TextButton(
              onPressed: () {
                ref.read(_emailConnectedProvider.notifier).state = false;
                ref.read(_connectedEmailProvider.notifier).state = null;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.emailDisconnected)),
                );
              },
              child: Text(
                l.disconnect,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
            )
          : TextButton(
              onPressed: () {
                // TODO: Start OAuth flow
                ref.read(_emailConnectedProvider.notifier).state = true;
                ref.read(_connectedEmailProvider.notifier).state =
                    'europeworktallinn@gmail.com';
              },
              child: Text(
                l.connectGmail,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ),
    );
  }

  // ── Language Picker ──────────────────────────────────────────────────

  String _languageLabelWithFlag(String code) {
    for (final lang in supportedLanguages) {
      if (lang.code == code) return '${lang.flag} ${lang.name}';
    }
    return code;
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    final currentCode = ref.read(localeProvider).languageCode;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(context),
        duration: const Duration(milliseconds: 400),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
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
                AppLocalizations.of(context)?.selectLanguage ?? 'Select Language',
                style: const TextStyle(
                  fontFamily: 'Inter',
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
                            fontFamily: 'Inter',
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

  // ── Dialogs ──────────────────────────────────────────────────────────

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        title: Text(l.signOut),
        content: Text(l.signOutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) context.go(AppRoutes.onboarding);
            },
            child: Text(
              l.signOut,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        title: Text(l.deleteAccount),
        content: Text(l.deleteAccountDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Show second confirmation
              _showFinalDeleteConfirmation(context, ref);
            },
            child: Text(
              l.deleteAccount,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showFinalDeleteConfirmation(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        title: Text(l.areYouAbsolutelySure),
        content: Text(l.typeDeleteToConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // TODO: Call delete account API
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) context.go(AppRoutes.onboarding);
            },
            child: Text(
              l.permanentlyDelete,
              style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _showExportDataDialog(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        title: Text(l.exportMyData),
        content: Text(l.exportDataDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l.dataExportRequested),
                ),
              );
            },
            child: Text(l.requestExport),
          ),
        ],
      ),
    );
  }

  void _showLegalInfoDialog(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
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
                l.legalInformation,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _LegalInfoRow(
                icon: Icons.business_outlined,
                text: l.legalEntityName,
              ),
              _LegalInfoRow(
                icon: Icons.tag_outlined,
                text: l.legalRegistryCode,
              ),
              _LegalInfoRow(
                icon: Icons.location_on_outlined,
                text: l.legalAddress,
              ),
              _LegalInfoRow(
                icon: Icons.email_outlined,
                text: l.legalEmail,
              ),
              _LegalInfoRow(
                icon: Icons.account_balance_outlined,
                text: l.legalRegistry,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ── Reusable settings list components ────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textTertiary,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Divider(height: 1, thickness: 1, color: AppColors.border),
    );
  }
}

class _SettingsTile extends StatefulWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? titleColor;

  @override
  State<_SettingsTile> createState() => _SettingsTileState();
}

class _SettingsTileState extends State<_SettingsTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    if (widget.onTap != null) _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.onTap != null) _scaleController.reverse();
  }

  void _handleTapCancel() {
    if (widget.onTap != null) _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${widget.title}${widget.subtitle != null ? ", ${widget.subtitle}" : ""}',
      button: widget.onTap != null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          child: Container(
            color: AppColors.surface,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                splashColor: AppColors.accent.withValues(alpha: 0.08),
                highlightColor: AppColors.accent.withValues(alpha: 0.04),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: (widget.iconColor ?? AppColors.textSecondary)
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Icon(
                          widget.icon,
                          size: 20,
                          color: widget.iconColor ?? AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: widget.titleColor ?? AppColors.textPrimary,
                              ),
                            ),
                            if (widget.subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                widget.subtitle!,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (widget.trailing != null) widget.trailing!,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LegalInfoRow extends StatelessWidget {
  const _LegalInfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                height: 1.4,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
