import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../config/feature_flags.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/advocat_gradient_header.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/max_width_wrapper.dart';
import '../models/org_invitation.dart';
import '../models/org_member.dart';
import '../models/org_role.dart';
import '../models/organization.dart';
import '../providers/org_providers.dart';
import '../repositories/org_repository.dart';
import '../widgets/invite_member_dialog.dart';
import '../widgets/member_avatar.dart';
import '../widgets/role_badge.dart';
import '../widgets/working_context_banner.dart';

/// List + manage organization members.
/// Spec: see FLUTTER_UI_SPEC.md §2.
class OrgMembersScreen extends ConsumerWidget {
  const OrgMembersScreen({super.key, required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgAsync = ref.watch(orgBySlugProvider(slug));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AdvocatGradientHeader(title: 'Members'),
      body: SafeArea(
        child: MaxWidthWrapper(
          child: orgAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text('Could not load organization: $e',
                  style: const TextStyle(color: AppColors.error)),
            ),
            data: (org) {
              if (org == null) {
                return const Center(
                  child: Text('Organization not found.'),
                );
              }
              return _MembersBody(org: org);
            },
          ),
        ),
      ),
    );
  }
}

class _MembersBody extends ConsumerWidget {
  const _MembersBody({required this.org});
  final Organization org;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(orgMembersProvider(org.id));
    final invitesAsync = ref.watch(orgPendingInvitationsProvider(org.id));
    final canManage = org.myRole?.canManageMembers ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const WorkingContextBanner(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Members',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${org.seatCount} / ${org.seatLimit} seats used',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (canManage)
                AppButton(
                  label: 'Invite member',
                  leadingIcon: Icons.person_add_alt_1_outlined,
                  onPressed: org.hasAvailableSeats
                      ? () => InviteMemberDialog.show(context, org.id)
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Seat limit reached. Upgrade plan or remove a member first.'),
                            ),
                          );
                        },
                ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(orgMembersProvider(org.id));
              ref.invalidate(orgPendingInvitationsProvider(org.id));
              await Future<void>.delayed(
                  const Duration(milliseconds: 400));
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                membersAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Could not load members: $e',
                        style: const TextStyle(color: AppColors.error)),
                  ),
                  data: (members) {
                    if (members.isEmpty) {
                      return EmptyState(
                        icon: Icons.group_outlined,
                        title: "You're flying solo",
                        description:
                            'Invite your first colleague to share cases, deadlines, and AI memory.',
                        actionLabel: canManage ? 'Invite member' : null,
                        onAction: canManage
                            ? () =>
                                InviteMemberDialog.show(context, org.id)
                            : null,
                      );
                    }
                    return _MembersList(
                      members: members,
                      org: org,
                      canManage: canManage,
                    );
                  },
                ),
                const SizedBox(height: 24),
                invitesAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (invites) => invites.isEmpty
                      ? const SizedBox.shrink()
                      : _InvitationsSection(
                          invitations: invites,
                          orgId: org.id,
                          canManage: canManage,
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MembersList extends ConsumerWidget {
  const _MembersList({
    required this.members,
    required this.org,
    required this.canManage,
  });
  final List<OrgMember> members;
  final Organization org;
  final bool canManage;

  Future<void> _changeRole(
    BuildContext context,
    WidgetRef ref,
    OrgMember member,
    OrgRole newRole,
  ) async {
    try {
      await ref.read(orgRepositoryProvider).changeMemberRole(
            orgId: org.id,
            userId: member.userId,
            role: newRole,
          );
      ref.invalidate(orgMembersProvider(org.id));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${member.displayName} → ${newRole.wire}')),
        );
      }
    } on OrgRepositoryException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not change role: ${e.code}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _removeMember(
      BuildContext context, WidgetRef ref, OrgMember member) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove member?'),
        content: Text(
          '${member.displayName} will lose access immediately. '
          'All cases and documents they created will be reassigned to you.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l.commonRemove),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(orgRepositoryProvider).removeMember(
            orgId: org.id,
            userId: member.userId,
          );
      ref.invalidate(orgMembersProvider(org.id));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Removed ${member.displayName}')),
        );
      }
    } on OrgRepositoryException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not remove: ${e.code}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < members.length; i++) ...[
            _MemberRow(
              member: members[i],
              canManage: canManage,
              onRoleChange: (r) =>
                  _changeRole(context, ref, members[i], r),
              onRemove: () => _removeMember(context, ref, members[i]),
            ),
            if (i < members.length - 1)
              const Divider(height: 1, color: AppColors.border),
          ],
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.canManage,
    required this.onRoleChange,
    required this.onRemove,
  });

  final OrgMember member;
  final bool canManage;
  final ValueChanged<OrgRole> onRoleChange;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isOwner = member.role == OrgRole.owner;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          MemberAvatar(
            initial: member.initial,
            imageUrl: member.avatarUrl,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  member.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (canManage && !isOwner)
            PopupMenuButton<OrgRole>(
              tooltip: 'Change role',
              initialValue: member.role,
              onSelected: onRoleChange,
              itemBuilder: (_) => [
                for (final r in [
                  OrgRole.admin,
                  OrgRole.member,
                  OrgRole.viewer,
                  OrgRole.billing,
                ])
                  PopupMenuItem(
                    value: r,
                    child: Row(
                      children: [
                        RoleBadge(role: r, size: RoleBadgeSize.small),
                        const SizedBox(width: 8),
                        if (r == member.role)
                          const Icon(Icons.check_rounded,
                              size: 14, color: AppColors.accent),
                      ],
                    ),
                  ),
              ],
              child: Row(
                children: [
                  RoleBadge(role: member.role),
                  const SizedBox(width: 4),
                  const Icon(Icons.expand_more_rounded,
                      size: 16, color: AppColors.textTertiary),
                ],
              ),
            )
          else
            RoleBadge(role: member.role),
          const SizedBox(width: 12),
          Text(
            timeago.format(member.joinedAt, locale: 'en_short'),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textTertiary,
            ),
          ),
          if (canManage && !isOwner)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, size: 18),
              tooltip: 'More',
              onSelected: (v) {
                if (v == 'remove') onRemove();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      const Icon(Icons.person_remove_outlined,
                          size: 16, color: AppColors.error),
                      const SizedBox(width: 8),
                      Text(l.orgRemoveFromOrg),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _InvitationsSection extends ConsumerWidget {
  const _InvitationsSection({
    required this.invitations,
    required this.orgId,
    required this.canManage,
  });

  final List<OrgInvitation> invitations;
  final String orgId;
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.mail_outline_rounded,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'Pending invitations (${invitations.length})',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          for (var i = 0; i < invitations.length; i++) ...[
            _InvitationRow(
              invitation: invitations[i],
              canManage: canManage,
              onResend: () async {
                try {
                  await ref
                      .read(orgRepositoryProvider)
                      .resendInvitation(invitations[i].id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l.orgInvitationResent)),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not resend: $e')),
                    );
                  }
                }
              },
              onCancel: () async {
                try {
                  await ref
                      .read(orgRepositoryProvider)
                      .cancelInvitation(invitations[i].id);
                  ref.invalidate(orgPendingInvitationsProvider(orgId));
                } catch (_) {}
              },
            ),
            if (i < invitations.length - 1)
              const Divider(height: 1, color: AppColors.border),
          ],
        ],
      ),
    );
  }
}

class _InvitationRow extends StatelessWidget {
  const _InvitationRow({
    required this.invitation,
    required this.canManage,
    required this.onResend,
    required this.onCancel,
  });

  final OrgInvitation invitation;
  final bool canManage;
  final VoidCallback onResend;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.email_outlined,
              color: AppColors.textTertiary, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invitation.email,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Invited ${timeago.format(invitation.createdAt)} · '
                  'expires ${timeago.format(invitation.expiresAt, allowFromNow: true)}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          RoleBadge(role: invitation.role, size: RoleBadgeSize.small),
          // resend-invitation / cancel-invitation edge functions are not
          // deployed yet — hide the controls entirely (no dead buttons).
          if (canManage && kOrgPendingB2bEndpointsEnabled) ...[
            TextButton(
              onPressed: onResend,
              child: Text(l.commonResend,
                  style: const TextStyle(fontSize: 12)),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: onCancel,
              tooltip: 'Cancel invitation',
            ),
          ],
        ],
      ),
    );
  }
}
