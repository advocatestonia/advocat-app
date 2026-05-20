import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/app_config.dart';
import '../../../config/feature_flags.dart';
import '../../../config/router.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../main.dart';
import '../../../services/demo_data.dart';
import '../../../services/supabase_service.dart';
import '../../../shared/constants/app_icons.dart';
import '../../../shared/widgets/advocat_gradient_header.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../../services/legal_planner.dart';
import '../../auth/providers/auth_provider.dart';
import 'edit_profile_screen.dart';

// ── Providers ────────────────────────────────────────────────────────────

final _pushNotificationsProvider = StateProvider<bool>((ref) => true);
final _deadlineRemindersProvider = StateProvider<bool>((ref) => true);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AdvocatGradientHeader(
        title: l.settings,
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

          // Pkg 6 — three-pass planner toggle (Pro only). Default OFF;
          // adds ~3-6s to legal turns when on. Copy is localized via
          // plannerSettings* ARB keys (see _PlannerToggleTile below).
          _PlannerToggleTile(),

          const _SectionDivider(),

          // ── Email Integration ─────────────────────────────────────────
          _SectionHeader(title: l.emailIntegration),
          _buildEmailTile(context, ref),

          const _SectionDivider(),

          // ── Invite friends ────────────────────────────────────────────
          // Growth loop: tap → /referral screen with copyable link + share.
          // Soft-launched (consilium 2026-05-15): the tile is hidden behind
          // `kReferralEnabled`; route + service stay compiled so flipping
          // the flag re-exposes the surface with zero further work.
          if (kReferralEnabled)
            _SettingsTile(
              icon: Icons.card_giftcard_outlined,
              title: l.referralSettingsTile,
              subtitle: l.referralSubtitle,
              trailing: const Icon(
                AppIcons.chevronRight,
                color: AppColors.textTertiary,
              ),
              onTap: () => context.push(AppRoutes.referral),
            ),

          if (kReferralEnabled) const _SectionDivider(),

          // ── Privacy & Data (GDPR Arts. 15 / 17 / 21 / 9(2)(a)) ────────
          // Single self-service hub for all data-subject rights.
          // Section header migrated 2026-05-19 from "DATA & PRIVACY" →
          // "PRIVACY & DATA" to align with GDPR phrasing and to mark the
          // DSAR flow rollout (export-my-data wired to dsar-export edge fn).
          _SectionHeader(title: l.privacyAndData),
          // ADR-001 Tier 1 — let users review & wipe what the AI has
          // learned about them (GDPR Art. 17). Localized via aiMemory* keys.
          _SettingsTile(
            icon: Icons.psychology_outlined,
            title: l.aiMemoryTitle,
            subtitle: l.aiMemorySubtitle,
            trailing: const Icon(
              AppIcons.chevronRight,
              color: AppColors.textTertiary,
            ),
            onTap: () => context.push(AppRoutes.aiMemory),
          ),
          // GDPR Art. 15 — self-service data access. Calls dsar-export edge
          // fn, which assembles a JSON of every personal-data row and writes
          // a row to dsar_requests (Art. 12(3) audit trail).
          _SettingsTile(
            icon: AppIcons.dataExport,
            title: l.exportMyData,
            subtitle: l.exportMyDataSubtitle,
            onTap: () => _showExportDataDialog(context, ref),
          ),
          // GDPR Art. 9(2)(a) / Art. 7(3) — manage / withdraw special-category
          // consent. Routes to the dedicated consent screen.
          _SettingsTile(
            icon: Icons.health_and_safety_outlined,
            title: l.withdrawSensitiveConsent,
            subtitle: l.withdrawSensitiveConsentSubtitle,
            trailing: const Icon(
              AppIcons.chevronRight,
              color: AppColors.textTertiary,
            ),
            onTap: () => context.push(AppRoutes.sensitiveConsent),
          ),
          _SettingsTile(
            icon: AppIcons.privacyOutlined,
            title: l.privacyPolicy,
            trailing: const Icon(
              AppIcons.chevronRight,
              color: AppColors.textTertiary,
            ),
            onTap: () => _launchUrl('https://advocat.ee/privacy.html'),
          ),
          _SettingsTile(
            icon: AppIcons.termsOutlined,
            title: l.dataProcessingAgreement,
            trailing: const Icon(
              AppIcons.chevronRight,
              color: AppColors.textTertiary,
            ),
            onTap: () => _launchUrl('https://advocat.ee/dpa.html'),
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
          // Privacy Policy + DPA moved to Privacy & Data section above
          // (DSAR rollout, 2026-05-19). Terms of Service + company
          // information remain here.
          _SectionHeader(title: l.legalSection),
          _SettingsTile(
            icon: AppIcons.termsOutlined,
            title: l.termsOfService,
            trailing: const Icon(AppIcons.chevronRight, color: AppColors.textTertiary),
            onTap: () => _launchUrl('https://advocat.ee/terms.html'),
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
            subtitle: AppConfig.appVersion,
          ),
          _SettingsTile(
            icon: AppIcons.starOutlined,
            title: l.rateUs,
            trailing: const Icon(AppIcons.chevronRight, color: AppColors.textTertiary),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    l.rateAppComingSoon,
                  ),
                  backgroundColor: AppColors.info,
                ),
              );
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
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: user.avatarUrl == null
                            ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [AppColors.primary, AppColors.accent],
                              )
                            : null,
                        image: user.avatarUrl != null
                            ? DecorationImage(
                                image: NetworkImage(user.avatarUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: user.avatarUrl == null
                          ? Center(
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            )
                          : null,
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
    final l = AppLocalizations.of(context)!;
    return _SettingsTile(
      icon: AppIcons.emailOutlined,
      title: l.emailIntegration,
      subtitle: l.syncLegalCorrespondence,
      trailing: const Icon(AppIcons.chevronRight, color: AppColors.textTertiary),
      onTap: () => context.push(AppRoutes.email),
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
              await _performAccountDeletion(context, ref);
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

  Future<void> _performAccountDeletion(
      BuildContext context, WidgetRef ref) async {
    final isDemo = ref.read(isDemoModeProvider);
    final supabase = ref.read(supabaseServiceProvider);

    // Show a loading indicator
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('Deleting account data...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );
    }

    try {
      if (!isDemo) {
        // Real Supabase account: delete all data then sign out
        await supabase.deleteAllUserData();
      }

      // Log out (clears demo mode flag + auth state)
      await ref.read(authControllerProvider.notifier).logout();

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully.'),
            backgroundColor: Colors.green,
          ),
        );
        context.go(AppRoutes.onboarding);
      }
    } catch (e) {
      debugPrint('delete account failed: $e');
      if (context.mounted) {
        final l = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l?.genericError ?? 'Something went wrong. Please try again.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showExportDataDialog(BuildContext context, WidgetRef ref) {
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
              _performDataExport(context, ref);
            },
            child: Text(l.requestExport),
          ),
        ],
      ),
    );
  }

  Future<void> _performDataExport(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context)!;
    final supabase = ref.read(supabaseServiceProvider);
    final isDemo = ref.read(isDemoModeProvider);

    // Show loading indicator (localized).
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text(l.exportingData),
            ],
          ),
          duration: const Duration(seconds: 60),
        ),
      );
    }

    try {
      // Demo mode: fall back to client-side stub (no real account).
      // Real mode: call the dsar-export edge function which assembles the
      // full GDPR Art. 15 payload server-side under service-role.
      String jsonString;
      bool queued = false;
      if (isDemo) {
        jsonString = await supabase.exportUserData();
      } else {
        final result = await supabase.callEdgeFunction('dsar-export');
        if (result == null) {
          throw Exception('dsar-export returned no body');
        }
        if (result['error'] != null) {
          throw Exception(result['error'].toString());
        }
        if (result['queued'] == true) {
          queued = true;
          jsonString = '';
        } else {
          // Edge fn returns the JSON body inline; SDK has already decoded
          // it into a Map. Re-encode for download.
          jsonString = const JsonEncoder.withIndent('  ').convert(result);
        }
      }

      if (queued) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l.dataExportRequested),
              backgroundColor: AppColors.success,
            ),
          );
        }
        return;
      }

      if (kIsWeb) {
        // On web, use clipboard as fallback (dart:io not available).
        await Clipboard.setData(ClipboardData(text: jsonString));
        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l.dataCopiedToClipboard),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        // Write to a temporary file and share via system share sheet.
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
        final file =
            File('${tempDir.path}/advocat-data-export-$timestamp.json');
        await file.writeAsString(jsonString);

        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l.exportComplete),
              backgroundColor: AppColors.success,
            ),
          );
        }

        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'application/json')],
          subject: 'Advocat Data Export',
        );
      }
    } catch (e) {
      debugPrint('data export failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.exportFailed),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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

// ── Pkg 6 planner toggle ─────────────────────────────────────────────────
// Pro-only opt-in to the three-pass legal reasoning loop.
//
// Planner UX gap-fix (2026-05-06, audit d54268c): the previous build let
// free-tier users flip the switch (cosmetic-only deception — only the
// server gate enforced). Now the switch is TRULY disabled for non-Pro
// users via `onChanged: null`, with a Pro badge + locked-state hint so
// the upgrade path is honest. Localized via plannerSettings* l10n keys.
class _PlannerToggleTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final asyncEnabled = ref.watch(plannerEnabledProvider);
    final userAsync = ref.watch(currentUserProvider);
    final isPro =
        userAsync.whenOrNull(data: (u) => u?.isProActive) ?? false;
    final value = asyncEnabled.valueOrNull ?? false;
    final effectiveValue = isPro ? value : false;
    return _SettingsTile(
      icon: Icons.psychology_outlined,
      title: l.plannerSettingsTitle,
      subtitle: isPro
          ? l.plannerSettingsSubtitle
          : '${l.plannerSettingsSubtitle}  •  ${l.plannerSettingsProDescription}',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isPro) ...[
            StatusChip(
              label: l.plannerSettingsProBadge,
              variant: StatusChipVariant.neutral,
              showDot: false,
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Switch.adaptive(
            value: effectiveValue,
            // Free-tier: onChanged=null disables the switch entirely
            // (Material/Cupertino render greyed-out + non-interactive).
            onChanged: isPro
                ? (v) =>
                    ref.read(plannerEnabledProvider.notifier).setEnabled(v)
                : null,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.accent,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: AppColors.border,
          ),
        ],
      ),
    );
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
