// =====================================================================
// ActiveCaseChip — small badge above the chat composer that tells the
// user which case the current conversation is folded into.
//
// Two visual states:
//   1. activeCase != null → "📁 Дело: <title>" with an "x" to clear.
//   2. activeCase == null → "Связать с делом ▾" chip that opens a
//      bottom-sheet picker. The chip suppresses itself when the user
//      has zero cases (i.e. nothing to link to).
//
// The widget is plain ConsumerWidget — no controller plumbing into the
// chat screen, so the only chat-screen edit is one line:
//     const ActiveCaseChip(),
// rendered above _buildInputBar().
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../data/case_repository.dart';
import '../models/user_case.dart';
import '../state/active_case_provider.dart';
import '../state/cases_list_provider.dart';

class ActiveCaseChip extends ConsumerWidget {
  const ActiveCaseChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final active = ref.watch(activeCaseProvider).activeCase;

    if (active != null) {
      return _ActiveBadge(
        userCase: active,
        onClear: () =>
            ref.read(activeCaseProvider.notifier).clearActiveCase(),
        clearLabel: l10n?.clearActiveCase ?? 'Clear',
      );
    }

    // No active case — only show "link to case" chip if the user has
    // any cases at all. Suppress otherwise.
    final casesAsync = ref.watch(casesListProvider(CaseListFilter.active));
    return casesAsync.maybeWhen(
      data: (cases) {
        if (cases.isEmpty) return const SizedBox.shrink();
        return _LinkChip(
          label: l10n?.linkChatToCase ?? 'Link to case',
          onTap: () => _openPicker(context, ref, cases),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Future<void> _openPicker(
    BuildContext context,
    WidgetRef ref,
    List<UserCase> cases,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ...cases.map(
                (c) => ListTile(
                  leading: const Icon(
                    Icons.folder_outlined,
                    color: AppColors.accent,
                  ),
                  title: Text(c.title),
                  subtitle: Text(
                    [c.jurisdiction.toUpperCase(), c.caseType ?? '']
                        .where((s) => s.isNotEmpty)
                        .join(' · '),
                  ),
                  onTap: () {
                    ref
                        .read(activeCaseProvider.notifier)
                        .setActiveCase(c);
                    Navigator.of(sheetCtx).pop();
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge({
    required this.userCase,
    required this.onClear,
    required this.clearLabel,
  });

  final UserCase userCase;
  final VoidCallback onClear;
  final String clearLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      color: AppColors.accent.withValues(alpha: 0.06),
      child: Row(
        children: [
          const Text('📁', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              userCase.title,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.accentDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          InkWell(
            onTap: onClear,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Tooltip(
                message: clearLabel,
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkChip extends StatelessWidget {
  const _LinkChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        4,
        AppSpacing.md,
        4,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ActionChip(
          avatar: const Icon(
            Icons.folder_outlined,
            size: 16,
            color: AppColors.accent,
          ),
          label: Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
          onPressed: onTap,
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
            side: BorderSide(
              color: AppColors.border.withValues(alpha: 0.6),
            ),
          ),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}
