// AI memory settings screen — ADR-001 Tier 1.
// -----------------------------------------------------------------------------
// Ref: docs/learning/ADR-001-three-tier-learning.md
//      lib/services/user_memory_service.dart
//
// Shows the user what the AI has extracted about them and lets them
// delete individual facts or wipe the whole lot (GDPR Art. 17).
//
// Copy strings are inline-English on purpose — the ARB files will be
// extended in a follow-up commit once the UX-FIX branch merges, to
// avoid a merge conflict in lib/l10n/*.arb. This screen is reachable
// only from the settings menu, so the temporary English-only UI is
// acceptable for the internal review cycle.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../models/user_memory.dart';
import '../../../services/user_memory_service.dart';
import '../../../shared/widgets/advocat_gradient_header.dart';

/// Riverpod-managed list of memories — refetched on demand.
final aiMemoriesProvider = FutureProvider.autoDispose<List<UserMemory>>((ref) {
  return ref.read(userMemoryServiceProvider).getMemories(limit: 100);
});

class AiMemoryScreen extends ConsumerWidget {
  const AiMemoryScreen({super.key});

  static const String routePath = '/profile/ai-memory';
  static const String routeName = 'aiMemory';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memoriesAsync = ref.watch(aiMemoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AdvocatGradientHeader(
        title: 'What we remember',
      ),
      body: memoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const _EmptyState(
          message:
              "We couldn't load your AI memory. Check your connection and "
              'pull to refresh.',
        ),
        data: (memories) {
          if (memories.isEmpty) {
            return const _EmptyState(
              message:
                  "The AI hasn't learned anything specific about you yet. "
                  'After a few chats, personal preferences and the people '
                  'you mention will appear here.',
            );
          }
          final grouped = _groupByKey(memories);
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(aiMemoriesProvider),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                const _HeaderCard(),
                const SizedBox(height: AppSpacing.md),
                for (final entry in grouped.entries) ...[
                  _GroupHeader(label: memoryKeyLabel(entry.key)),
                  for (final mem in entry.value)
                    _MemoryTile(
                      memory: mem,
                      onForget: () => _confirmForget(context, ref, mem),
                    ),
                  const SizedBox(height: AppSpacing.md),
                ],
                const SizedBox(height: AppSpacing.lg),
                _ForgetAllButton(
                  onPressed: () => _confirmForgetAll(context, ref),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------

  /// Keys keep the ADR-001 canonical order so the page layout stays stable.
  Map<String, List<UserMemory>> _groupByKey(List<UserMemory> memories) {
    const orderedKeys = [
      'name',
      'user_goal',
      'tone',
      'preference',
      'emotional_state',
      'case_focus',
      'deadline',
      'known_party',
      'background',
      'discussed_topic',
    ];
    final byKey = <String, List<UserMemory>>{};
    for (final m in memories) {
      byKey.putIfAbsent(m.key, () => []).add(m);
    }
    final ordered = <String, List<UserMemory>>{};
    for (final k in orderedKeys) {
      if (byKey.containsKey(k)) ordered[k] = byKey[k]!;
    }
    // Any out-of-vocab keys (future-compatible) appended at the end.
    for (final k in byKey.keys) {
      if (!ordered.containsKey(k)) ordered[k] = byKey[k]!;
    }
    return ordered;
  }

  Future<void> _confirmForget(
    BuildContext context,
    WidgetRef ref,
    UserMemory mem,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Forget this?'),
        content: Text(
          'The assistant will stop using this fact:\n\n"${mem.text}"',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Forget'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(userMemoryServiceProvider).forget(mem.id);
    ref.invalidate(aiMemoriesProvider);
  }

  Future<void> _confirmForgetAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Forget everything?'),
        content: const Text(
          'The assistant will lose every personal fact it has learned about '
          'you. Case and document data stays. You can rebuild the memory by '
          'chatting again — this cannot be undone for past extractions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Forget everything'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(userMemoryServiceProvider).forgetAll();
    ref.invalidate(aiMemoriesProvider);
  }
}

// ---------------------------------------------------------------------------
// Internal widgets
// ---------------------------------------------------------------------------

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: const Text(
        'These are facts the AI has picked up from your conversations. '
        'Delete anything you want it to forget. You can also wipe '
        'everything at the bottom of the page.',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _MemoryTile extends StatelessWidget {
  const _MemoryTile({required this.memory, required this.onForget});
  final UserMemory memory;
  final VoidCallback onForget;

  @override
  Widget build(BuildContext context) {
    final reinforced = _formatRelative(memory.lastReinforcedAt);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memory.text,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Confidence ${(memory.confidence * 100).round()}% · $reinforced',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Forget',
            onPressed: onForget,
            icon: const Icon(
              Icons.delete_outline,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatRelative(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inDays < 1) return '${diff.inHours} h ago';
    if (diff.inDays < 30) return '${diff.inDays} d ago';
    return '${(diff.inDays / 30).floor()} mo ago';
  }
}

class _ForgetAllButton extends StatelessWidget {
  const _ForgetAllButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.delete_forever, color: AppColors.error),
        label: const Text(
          'Forget everything',
          style: TextStyle(color: AppColors.error),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          side: const BorderSide(color: AppColors.error),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
    );
  }
}
