import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../models/org_role.dart';
import '../providers/org_providers.dart';
import '../repositories/org_repository.dart';
import 'role_badge.dart';

class InviteMemberDialog extends ConsumerStatefulWidget {
  const InviteMemberDialog({super.key, required this.orgId});
  final String orgId;

  static Future<void> show(BuildContext context, String orgId) {
    return showDialog<void>(
      context: context,
      builder: (_) => InviteMemberDialog(orgId: orgId),
    );
  }

  @override
  ConsumerState<InviteMemberDialog> createState() =>
      _InviteMemberDialogState();
}

class _InviteMemberDialogState extends ConsumerState<InviteMemberDialog> {
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  OrgRole _role = OrgRole.member;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(orgRepositoryProvider).inviteMember(
            orgId: widget.orgId,
            email: _emailController.text.trim(),
            role: _role,
            welcomeMessage: _messageController.text.trim().isEmpty
                ? null
                : _messageController.text.trim(),
          );
      ref.invalidate(orgPendingInvitationsProvider(widget.orgId));
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Invite sent to ${_emailController.text.trim()}'),
          backgroundColor: AppColors.accent,
        ),
      );
    } on OrgRepositoryException catch (e) {
      if (mounted) {
        setState(() {
          _error = _mapError(e.code);
          _submitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Unexpected error: $e';
          _submitting = false;
        });
      }
    }
  }

  String _mapError(String code) => switch (code) {
        'seat_limit_reached' =>
          'Your plan is at its seat limit. Upgrade plan or remove a member first.',
        'already_member' => 'This person is already a member of the org.',
        'pending_invite' => 'An invitation is already pending for this email.',
        'invalid_email' => 'Invalid email address.',
        _ => 'Could not send invitation. Please try again.',
      };

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Invite member',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "We'll send them an email with a 7-day join link.",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'colleague@yourfirm.ee',
                  keyboardType: TextInputType.emailAddress,
                  autofocus: true,
                  validator: (v) {
                    final s = v?.trim() ?? '';
                    if (s.isEmpty) return 'Email is required';
                    if (!s.contains('@') || !s.contains('.')) {
                      return 'Invalid email format';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Role',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OrgRole.member,
                    OrgRole.admin,
                    OrgRole.viewer,
                    OrgRole.billing,
                  ]
                      .map((r) => ChoiceChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                RoleBadge(
                                    role: r, size: RoleBadgeSize.small),
                              ],
                            ),
                            selected: _role == r,
                            onSelected: (_) => setState(() => _role = r),
                            backgroundColor: AppColors.surfaceVariant,
                            selectedColor:
                                AppColors.accent.withValues(alpha: 0.15),
                            side: BorderSide(
                              color: _role == r
                                  ? AppColors.accent
                                  : AppColors.border,
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _messageController,
                  label: 'Welcome message (optional)',
                  hint:
                      'Hi! I want you to join us in Advocat — it makes our case work much smoother.',
                  isMultiline: true,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 300,
                  showCounter: true,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorBg,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Cancel',
                        variant: AppButtonVariant.ghost,
                        onPressed: _submitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        isFullWidth: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        label: 'Send invite',
                        onPressed: _submitting ? null : _submit,
                        isLoading: _submitting,
                        isFullWidth: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
