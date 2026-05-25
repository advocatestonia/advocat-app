import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../config/theme.dart';
import '../providers/org_providers.dart';

/// Live activity feed for the firm dashboard.
class OrgActivityFeed extends ConsumerWidget {
  const OrgActivityFeed({super.key, required this.orgId});
  final String orgId;

  IconData _iconFor(String action) => switch (action) {
        'case_create' => Icons.folder_outlined,
        'document_uploaded' => Icons.upload_file_outlined,
        'case_resolved' => Icons.check_circle_outline_rounded,
        'member_joined' => Icons.person_add_alt_1_outlined,
        'member_invited' => Icons.mail_outline_rounded,
        _ => Icons.bolt_outlined,
      };

  String _summary(Map<String, dynamic> row) {
    final action = row['action'] as String? ?? '';
    final profile = row['profiles'] as Map<String, dynamic>?;
    final actor = profile?['full_name'] as String? ??
        profile?['email'] as String? ??
        'Someone';
    final details = row['details'] as Map<String, dynamic>?;
    final target = details?['title'] as String? ?? details?['name'] as String?;

    return switch (action) {
      'case_create' => '$actor opened ${target ?? 'a new case'}',
      'document_uploaded' => '$actor uploaded ${target ?? 'a document'}',
      'case_resolved' => '$actor resolved ${target ?? 'a case'}',
      'member_joined' => '$actor joined the firm',
      'member_invited' => '$actor invited ${details?['email'] ?? 'a colleague'}',
      _ => '$actor: $action',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(orgRecentActivityProvider(orgId));
    return feed.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(24),
        child: Text('Activity feed unavailable: $e',
            style: const TextStyle(color: AppColors.error)),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No activity yet. Once members start working, their actions show up here.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textTertiary,
                height: 1.4,
              ),
            ),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: AppColors.border),
          itemBuilder: (_, i) {
            final row = items[i];
            final ts = DateTime.tryParse(row['created_at'] as String? ?? '');
            return ListTile(
              dense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              leading: CircleAvatar(
                radius: 16,
                backgroundColor:
                    AppColors.accent.withValues(alpha: 0.12),
                child: Icon(_iconFor(row['action'] as String? ?? ''),
                    size: 16, color: AppColors.accent),
              ),
              title: Text(
                _summary(row),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                ts == null ? '' : timeago.format(ts),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
