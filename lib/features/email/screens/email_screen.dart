import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.emailIntegrationTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: connection.isConnected
            ? _ConnectedView(key: const ValueKey('connected'), connection: connection)
            : const _DisconnectedView(key: ValueKey('disconnected')),
      ),
      floatingActionButton: connection.isConnected
          ? _ComposeButton()
              .animate()
              .scale(
                begin: const Offset(0, 0),
                end: const Offset(1, 1),
                duration: 400.ms,
                curve: Curves.elasticOut,
              )
          : null,
    );
  }
}

// ── Compose FAB with glow ────────────────────────────────────────────────

class _ComposeButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.4),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          // TODO: Navigate to compose screen
        },
        backgroundColor: AppColors.accent,
        elevation: 0,
        child: const Icon(Icons.edit_rounded, color: Colors.white),
      ),
    );
  }
}

// ── Disconnected View ────────────────────────────────────────────────────

class _DisconnectedView extends ConsumerWidget {
  const _DisconnectedView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),

            // Illustration with animated glow
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    blurRadius: 32,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Icon(
                AppIcons.emailOutlined,
                size: 56,
                color: AppColors.accent.withValues(alpha: 0.6),
              ),
            )
                .animate()
                .fadeIn(duration: 500.ms, curve: Curves.easeOut)
                .slideY(begin: -0.15, end: 0, duration: 500.ms, curve: Curves.easeOut),

            const SizedBox(height: AppSpacing.lg),

            Text(
              l10n.connectYourEmail,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
            )
                .animate()
                .fadeIn(delay: 100.ms, duration: 400.ms)
                .slideY(begin: 0.1, end: 0, delay: 100.ms, duration: 400.ms),

            const SizedBox(height: AppSpacing.sm),

            Text(
              l10n.connectYourEmailDesc,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
            )
                .animate()
                .fadeIn(delay: 200.ms, duration: 400.ms)
                .slideY(begin: 0.1, end: 0, delay: 200.ms, duration: 400.ms),

            const SizedBox(height: AppSpacing.xl),

            // Gmail button
            _OAuthButton(
              label: l10n.connectGmail,
              icon: Icons.g_mobiledata_rounded,
              iconColor: const Color(0xFFDB4437),
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textPrimary,
              borderColor: AppColors.border,
              onPressed: () => ref
                  .read(_emailConnectionProvider.notifier)
                  .connect(_EmailProvider.gmail),
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 400.ms)
                .slideX(begin: -0.08, end: 0, delay: 300.ms, duration: 400.ms),

            const SizedBox(height: AppSpacing.sm),

            // Outlook button
            _OAuthButton(
              label: l10n.connectOutlook,
              icon: Icons.mail_outline_rounded,
              iconColor: const Color(0xFF0078D4),
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textPrimary,
              borderColor: AppColors.border,
              onPressed: () => ref
                  .read(_emailConnectionProvider.notifier)
                  .connect(_EmailProvider.outlook),
            )
                .animate()
                .fadeIn(delay: 400.ms, duration: 400.ms)
                .slideX(begin: -0.08, end: 0, delay: 400.ms, duration: 400.ms),

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
                      l10n.emailPrivacyNote,
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
            )
                .animate()
                .fadeIn(delay: 500.ms, duration: 400.ms)
                .slideY(begin: 0.1, end: 0, delay: 500.ms, duration: 400.ms),

            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}

// ── Connected View ───────────────────────────────────────────────────────

class _ConnectedView extends ConsumerWidget {
  const _ConnectedView({super.key, required this.connection});

  final _EmailConnectionState connection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final linkedEmails =
        _mockEmails.where((e) => e.isLinked).toList();
    final unlinkedEmails =
        _mockEmails.where((e) => !e.isLinked).toList();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // ── Connection status with animated indicator ──────────────────
        _AnimatedConnectionCard(connection: connection, ref: ref)
            .animate()
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.08, end: 0, duration: 400.ms),

        const SizedBox(height: AppSpacing.lg),

        // ── Linked Legal Emails ───────────────────────────────────────
        _SectionLabel(
          title: l10n.legalEmails,
          count: linkedEmails.length,
        )
            .animate()
            .fadeIn(delay: 100.ms, duration: 300.ms),
        const SizedBox(height: AppSpacing.sm),

        if (linkedEmails.isEmpty)
          EmptyState(
            icon: AppIcons.emailOutlined,
            title: l10n.noLegalEmailsYet,
            description: l10n.legalEmailsWillAppear,
            compact: true,
          )
        else
          ...linkedEmails.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _EmailCard(email: entry.value)
                  .animate()
                  .fadeIn(
                    delay: Duration(milliseconds: 200 + entry.key * 80),
                    duration: 350.ms,
                  )
                  .slideX(
                    begin: 0.05,
                    end: 0,
                    delay: Duration(milliseconds: 200 + entry.key * 80),
                    duration: 350.ms,
                    curve: Curves.easeOutCubic,
                  ),
            ),
          ),

        const SizedBox(height: AppSpacing.lg),

        // ── Unlinked Emails ───────────────────────────────────────────
        if (unlinkedEmails.isNotEmpty) ...[
          _SectionLabel(
            title: l10n.unlinkedEmails,
            count: unlinkedEmails.length,
          )
              .animate()
              .fadeIn(delay: 300.ms, duration: 300.ms),
          const SizedBox(height: AppSpacing.sm),
          ...unlinkedEmails.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _EmailCard(email: entry.value, showAssignAction: true)
                  .animate()
                  .fadeIn(
                    delay: Duration(milliseconds: 400 + entry.key * 80),
                    duration: 350.ms,
                  )
                  .slideX(
                    begin: 0.05,
                    end: 0,
                    delay: Duration(milliseconds: 400 + entry.key * 80),
                    duration: 350.ms,
                    curve: Curves.easeOutCubic,
                  ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // ── Disconnect button ─────────────────────────────────────────
        Center(
          child: AppButton(
            label: l10n.disconnectEmail,
            variant: AppButtonVariant.danger,
            size: AppButtonSize.small,
            leadingIcon: Icons.link_off_rounded,
            onPressed: () => _showDisconnectDialog(context, ref),
          ),
        )
            .animate()
            .fadeIn(delay: 600.ms, duration: 300.ms),

        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  void _showDisconnectDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        title: Text(l10n.disconnectEmail),
        content: Text(l10n.disconnectEmailConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(_emailConnectionProvider.notifier).disconnect();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.emailDisconnected)),
              );
            },
            child: Text(
              l10n.disconnect,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated Connection Card ─────────────────────────────────────────────

class _AnimatedConnectionCard extends StatelessWidget {
  const _AnimatedConnectionCard({
    required this.connection,
    required this.ref,
  });

  final _EmailConnectionState connection;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          ...AppShadows.shadowSmall,
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Animated pulsing green dot
              _PulsingDot(),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.connectedTo(connection.email ?? ''),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
                AnimatedRotation(
                  turns: connection.isSyncing ? 1 : 0,
                  duration: const Duration(seconds: 1),
                  child: const Icon(
                    AppIcons.sync,
                    size: 14,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  l10n.lastSynced(_formatTimeAgo(connection.lastSyncAt!)),
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
                  label: l10n.syncNow,
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

// ── Pulsing green dot ────────────────────────────────────────────────────

class _PulsingDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      height: 14,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulse ring
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .scaleXY(begin: 0.8, end: 1.4, duration: 1500.ms, curve: Curves.easeOut)
              .fadeOut(begin: 0.6, duration: 1500.ms),
          // Inner solid dot
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────

class _OAuthButton extends StatefulWidget {
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
  State<_OAuthButton> createState() => _OAuthButtonState();
}

class _OAuthButtonState extends State<_OAuthButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: _isPressed
                ? widget.backgroundColor.withValues(alpha: 0.9)
                : widget.backgroundColor,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: widget.borderColor),
            boxShadow: _isPressed
                ? []
                : AppShadows.shadowSmall,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: widget.iconColor, size: 28),
              const SizedBox(width: AppSpacing.sm),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: widget.foregroundColor,
                ),
              ),
            ],
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
          title.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textTertiary,
            letterSpacing: 1.0,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _EmailCard extends StatefulWidget {
  const _EmailCard({required this.email, this.showAssignAction = false});
  final _LegalEmail email;
  final bool showAssignAction;

  @override
  State<_EmailCard> createState() => _EmailCardState();
}

class _EmailCardState extends State<_EmailCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AppCard(
          onTap: () {
            HapticFeedback.selectionClick();
            // TODO: Navigate to email detail or linked case
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Sender avatar circle
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        widget.email.sender.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      widget.email.sender,
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
                    _formatDate(widget.email.date),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: Text(
                  widget.email.subject,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: Row(
                  children: [
                    if (widget.email.isLinked) ...[
                      StatusChip(
                        label: widget.email.linkedCaseName!,
                        variant: StatusChipVariant.info,
                        showDot: false,
                        icon: AppIcons.link,
                      ),
                    ],
                    if (widget.showAssignAction)
                      InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(AppIcons.add, size: 14, color: AppColors.accent),
                              const SizedBox(width: 4),
                              Text(
                                l10n.assignToCase,
                                style: const TextStyle(
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
              ),
            ],
          ),
        ),
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
