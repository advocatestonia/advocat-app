import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../models/organization.dart';
import '../providers/org_providers.dart';

/// Bottom sheet for switching between organizations + Personal context.
///
/// Shown by [WorkingContextBanner] and from the menu in Settings.
class OrgSwitcherSheet extends ConsumerWidget {
  const OrgSwitcherSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const OrgSwitcherSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeId = ref.watch(activeOrgIdProvider);
    final orgsAsync = ref.watch(myOrgsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              // Grabber
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text(
                  'Switch context',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              // Personal
              _ContextTile(
                title: 'Personal',
                subtitle: 'Your private B2C workspace',
                icon: Icons.person_outline_rounded,
                isActive: activeId == null,
                onTap: () async {
                  await ref
                      .read(activeOrgIdProvider.notifier)
                      .setActive(null);
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),

              orgsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Could not load organizations: $e',
                      style: const TextStyle(color: AppColors.error)),
                ),
                data: (orgs) {
                  if (orgs.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(20, 16, 20, 6),
                        child: Text(
                          'YOUR ORGANIZATIONS',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                      for (final org in orgs)
                        _ContextTile(
                          title: org.name,
                          subtitle: _planLabel(org),
                          icon: Icons.business_outlined,
                          isActive: org.id == activeId,
                          onTap: () async {
                            await ref
                                .read(activeOrgIdProvider.notifier)
                                .setActive(org.id);
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              context.go('/orgs/${org.slug}/dashboard');
                            }
                          },
                        ),
                    ],
                  );
                },
              ),
              const Divider(height: 32),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push('/orgs/new');
                  },
                  icon: const Icon(Icons.add_business_rounded, size: 18),
                  label: const Text('Create new organization'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _planLabel(Organization org) {
    final plan = org.plan.name[0].toUpperCase() + org.plan.name.substring(1);
    return '$plan plan · ${org.seatCount}/${org.seatLimit} seats';
  }
}

class _ContextTile extends StatelessWidget {
  const _ContextTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.accent.withValues(alpha: 0.15)
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  size: 18,
                  color:
                      isActive ? AppColors.accent : AppColors.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
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
            if (isActive)
              const Icon(Icons.check_circle_rounded,
                  size: 20, color: AppColors.accent),
          ],
        ),
      ),
    );
  }
}
