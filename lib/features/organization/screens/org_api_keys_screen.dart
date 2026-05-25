import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../config/theme.dart';
import '../../../shared/widgets/advocat_gradient_header.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/max_width_wrapper.dart';
import '../models/api_key.dart';
import '../models/organization.dart';
import '../providers/org_providers.dart';
import '../repositories/org_repository.dart';
import '../widgets/create_api_key_dialog.dart';
import '../widgets/working_context_banner.dart';

/// API keys CRUD.
/// Spec: see FLUTTER_UI_SPEC.md §5.
class OrgApiKeysScreen extends ConsumerWidget {
  const OrgApiKeysScreen({super.key, required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgAsync = ref.watch(orgBySlugProvider(slug));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AdvocatGradientHeader(title: 'API keys'),
      body: SafeArea(
        child: MaxWidthWrapper(
          child: orgAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text('$e',
                  style: const TextStyle(color: AppColors.error)),
            ),
            data: (org) {
              if (org == null) {
                return const Center(
                    child: Text('Organization not found.'));
              }
              if (!(org.myRole?.canManageApiKeys ?? false)) {
                return const EmptyState(
                  icon: Icons.lock_outline_rounded,
                  title: 'Restricted',
                  description:
                      'Only the owner and admins can manage API keys.',
                );
              }
              if (!org.plan.hasApiAccess) {
                return const EmptyState(
                  icon: Icons.upgrade_outlined,
                  title: 'API access requires Firm plan',
                  description:
                      'Upgrade to the Firm or Enterprise plan to integrate Advocat with your systems via REST API.',
                );
              }
              return _ApiKeysBody(org: org);
            },
          ),
        ),
      ),
    );
  }
}

class _ApiKeysBody extends ConsumerWidget {
  const _ApiKeysBody({required this.org});
  final Organization org;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keysAsync = ref.watch(orgApiKeysProvider(org.id));
    return Column(
      children: [
        const WorkingContextBanner(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'API keys',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Use API keys to integrate Advocat with your CMS or other tools.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              AppButton(
                label: 'Create key',
                leadingIcon: Icons.add_rounded,
                onPressed: () => CreateApiKeyDialog.show(context, org.id),
              ),
            ],
          ),
        ),
        Expanded(
          child: keysAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text('$e',
                  style: const TextStyle(color: AppColors.error)),
            ),
            data: (keys) {
              final active = keys.where((k) => k.isActive).toList();
              if (active.isEmpty) {
                return EmptyState(
                  icon: Icons.key_outlined,
                  title: 'No API keys yet',
                  description:
                      'Create a key to integrate Advocat with your CMS, '
                      'document workflow, or custom dashboards.',
                  actionLabel: 'Create your first key',
                  onAction: () =>
                      CreateApiKeyDialog.show(context, org.id),
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(orgApiKeysProvider(org.id));
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    for (final k in keys)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ApiKeyCard(
                          apiKey: k,
                          onRevoke: () => _confirmRevoke(context, ref, k),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _confirmRevoke(
      BuildContext context, WidgetRef ref, ApiKey k) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Revoke "${k.name}"?'),
        content: const Text(
          'Any integration using this key will fail immediately. This action is irreversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(orgRepositoryProvider).revokeApiKey(k.id);
      ref.invalidate(orgApiKeysProvider(org.id));
    } on OrgRepositoryException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not revoke: ${e.code}')),
        );
      }
    }
  }
}

class _ApiKeyCard extends StatelessWidget {
  const _ApiKeyCard({required this.apiKey, required this.onRevoke});
  final ApiKey apiKey;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  apiKey.name,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onRevoke,
                icon: const Icon(Icons.block_outlined, size: 14),
                label: const Text('Revoke'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SelectableText(
            apiKey.displayKey,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final s in apiKey.scopes)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    s,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.schedule_outlined,
                  size: 12, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(
                'Created ${timeago.format(apiKey.createdAt)}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.bolt_outlined,
                  size: 12, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(
                apiKey.lastUsedAt == null
                    ? 'Never used'
                    : 'Used ${timeago.format(apiKey.lastUsedAt!)}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
              if (apiKey.expiresAt != null) ...[
                const SizedBox(width: 16),
                const Icon(Icons.event_outlined,
                    size: 12, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  'Expires ${timeago.format(apiKey.expiresAt!, allowFromNow: true)}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
