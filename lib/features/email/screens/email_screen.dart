import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../shared/constants/app_icons.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/status_chip.dart';

// ── State ────────────────────────────────────────────────────────────────

enum _EmailProvider { gmail, outlook }

class _EmailConnectionState {
  const _EmailConnectionState({
    this.isConnected = false,
    this.email,
    this.provider,
    this.lastSyncAt,
    this.isSyncing = false,
  });

  final bool isConnected;
  final String? email;
  final _EmailProvider? provider;
  final DateTime? lastSyncAt;
  final bool isSyncing;

  _EmailConnectionState copyWith({
    bool? isConnected,
    String? email,
    _EmailProvider? provider,
    DateTime? lastSyncAt,
    bool? isSyncing,
  }) {
    return _EmailConnectionState(
      isConnected: isConnected ?? this.isConnected,
      email: email ?? this.email,
      provider: provider ?? this.provider,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }
}

class _EmailConnectionNotifier extends StateNotifier<_EmailConnectionState> {
  _EmailConnectionNotifier() : super(const _EmailConnectionState());

  Future<void> connect(_EmailProvider provider) async {
    // TODO: Replace with real OAuth flow via EmailService
    state = state.copyWith(isSyncing: true);
    await Future<void>.delayed(const Duration(seconds: 2));
    state = _EmailConnectionState(
      isConnected: true,
      email: provider == _EmailProvider.gmail
          ? 'europeworktallinn@gmail.com'
          : 'user@outlook.com',
      provider: provider,
      lastSyncAt: DateTime.now(),
      isSyncing: false,
    );
  }

  Future<void> syncNow() async {
    state = state.copyWith(isSyncing: true);
    await Future<void>.delayed(const Duration(seconds: 2));
    state = state.copyWith(
      lastSyncAt: DateTime.now(),
      isSyncing: false,
    );
  }

  Future<void> disconnect() async {
    state = const _EmailConnectionState();
  }
}

final _emailConnectionProvider =
    StateNotifierProvider<_EmailConnectionNotifier, _EmailConnectionState>(
  (ref) => _EmailConnectionNotifier(),
);

// ── Mock data ────────────────────────────────────────────────────────────

class _LegalEmail {
  const _LegalEmail({
    required this.id,
    required this.sender,
    required this.subject,
    required this.date,
    this.linkedCaseId,
    this.linkedCaseName,
  });

  final String id;
  final String sender;
  final String subject;
  final DateTime date;
  final String? linkedCaseId;
  final String? linkedCaseName;

  bool get isLinked => linkedCaseId != null;
}

final _mockEmails = [
  _LegalEmail(
    id: '1',
    sender: 'migri@migri.fi',
    subject: 'Re: Residence permit application - Decision pending',
    date: DateTime.now().subtract(const Duration(hours: 3)),
    linkedCaseId: 'case-1',
    linkedCaseName: 'Residence Permit Appeal',
  ),
  _LegalEmail(
    id: '2',
    sender: 'helsinki.ao@oikeus.fi',
    subject: 'Administrative Court - Hearing date confirmation',
    date: DateTime.now().subtract(const Duration(days: 1)),
    linkedCaseId: 'case-1',
    linkedCaseName: 'Residence Permit Appeal',
  ),
  _LegalEmail(
    id: '3',
    sender: 'legal-aid@oikeusapu.fi',
    subject: 'Legal aid decision - Application No. 2024-1234',
    date: DateTime.now().subtract(const Duration(days: 3)),
  ),
  _LegalEmail(
    id: '4',
    sender: 'te-palvelut@te-toimisto.fi',
    subject: 'Employment permit - Additional documents required',
    date: DateTime.now().subtract(const Duration(days: 5)),
  ),
];

// ── Screen ───────────────────────────────────────────────────────────────

class EmailScreen extends ConsumerWidget {
  const EmailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connection = ref.watch(_emailConnectionProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Email Integration'),
        backgroundColor: AppColors.surface,
      ),
      body: connection.isConnected
          ? _ConnectedView(connection: connection)
          : const _DisconnectedView(),
    );
  }
}

// ── Disconnected View ────────────────────────────────────────────────────

class _DisconnectedView extends ConsumerWidget {
  const _DisconnectedView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),

            // Illustration
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                AppIcons.emailOutlined,
                size: 56,
                color: AppColors.accent.withValues(alpha: 0.6),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            Text(
              'Connect Your Email',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),

            const SizedBox(height: AppSpacing.sm),

            Text(
              'Connect your email to automatically detect and organize legal correspondence related to your cases.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Gmail button
            _OAuthButton(
              label: 'Connect Gmail',
              icon: Icons.g_mobiledata_rounded,
              iconColor: const Color(0xFFDB4437),
              backgroundColor: Colors.white,
              foregroundColor: AppColors.textPrimary,
              borderColor: AppColors.border,
              onPressed: () => ref
                  .read(_emailConnectionProvider.notifier)
                  .connect(_EmailProvider.gmail),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Outlook button
            _OAuthButton(
              label: 'Connect Outlook',
              icon: Icons.mail_outline_rounded,
              iconColor: const Color(0xFF0078D4),
              backgroundColor: Colors.white,
              foregroundColor: AppColors.textPrimary,
              borderColor: AppColors.border,
              onPressed: () => ref
                  .read(_emailConnectionProvider.notifier)
                  .connect(_EmailProvider.outlook),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Security note
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.info.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  const Icon(
                    AppIcons.privacyOutlined,
                    size: 20,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'We only read legal-related emails. Your personal emails stay private.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.info.withValues(alpha: 0.9),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}

// ── Connected View ───────────────────────────────────────────────────────

class _ConnectedView extends ConsumerWidget {
  const _ConnectedView({required this.connection});

  final _EmailConnectionState connection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linkedEmails =
        _mockEmails.where((e) => e.isLinked).toList();
    final unlinkedEmails =
        _mockEmails.where((e) => !e.isLinked).toList();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // ── Connection status ─────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Connected to ${connection.email}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              if (connection.lastSyncAt != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(
                      AppIcons.sync,
                      size: 14,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Last synced ${_formatTimeAgo(connection.lastSyncAt!)}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Sync Now',
                      variant: AppButtonVariant.secondary,
                      size: AppButtonSize.small,
                      isLoading: connection.isSyncing,
                      leadingIcon: AppIcons.sync,
                      onPressed: () =>
                          ref.read(_emailConnectionProvider.notifier).syncNow(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // ── Linked Legal Emails ───────────────────────────────────────
        _SectionLabel(
          title: 'Legal Emails',
          count: linkedEmails.length,
        ),
        const SizedBox(height: AppSpacing.sm),

        if (linkedEmails.isEmpty)
          const EmptyState(
            icon: AppIcons.emailOutlined,
            title: 'No legal emails yet',
            description: 'Emails classified as legal-related will appear here.',
            compact: true,
          )
        else
          ...linkedEmails.map(
            (email) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _EmailCard(email: email),
            ),
          ),

        const SizedBox(height: AppSpacing.lg),

        // ── Unlinked Emails ───────────────────────────────────────────
        if (unlinkedEmails.isNotEmpty) ...[
          _SectionLabel(
            title: 'Unlinked Emails',
            count: unlinkedEmails.length,
          ),
          const SizedBox(height: AppSpacing.sm),
          ...unlinkedEmails.map(
            (email) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _EmailCard(email: email, showAssignAction: true),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // ── Disconnect button ─────────────────────────────────────────
        Center(
          child: AppButton(
            label: 'Disconnect Email',
            variant: AppButtonVariant.danger,
            size: AppButtonSize.small,
            leadingIcon: Icons.link_off_rounded,
            onPressed: () => _showDisconnectDialog(context, ref),
          ),
        ),

        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  void _showDisconnectDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        title: const Text('Disconnect Email'),
        content: const Text(
          'You will stop receiving automatic email syncing. '
          'Previously synced emails will remain in your cases.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(_emailConnectionProvider.notifier).disconnect();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Email disconnected')),
              );
            },
            child: const Text(
              'Disconnect',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────

class _OAuthButton extends StatelessWidget {
  const _OAuthButton({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: iconColor, size: 28),
        label: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: foregroundColor,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, this.count});
  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _EmailCard extends StatelessWidget {
  const _EmailCard({required this.email, this.showAssignAction = false});
  final _LegalEmail email;
  final bool showAssignAction;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () {
        // TODO: Navigate to email detail or linked case
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  email.sender,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                _formatDate(email.date),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            email.subject,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              if (email.isLinked) ...[
                StatusChip(
                  label: email.linkedCaseName!,
                  variant: StatusChipVariant.info,
                  showDot: false,
                  icon: AppIcons.link,
                ),
              ],
              if (showAssignAction)
                InkWell(
                  onTap: () {
                    // TODO: Show case picker bottom sheet
                  },
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.accent),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(AppIcons.add, size: 14, color: AppColors.accent),
                        SizedBox(width: 4),
                        Text(
                          'Assign to case',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inHours < 24) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
