// ---------------------------------------------------------------------------
// Document-Collection Checklist (Feature #4) — screen.
//
// Lets the user pick a problem type (residence permit / tenancy / dismissal
// / inheritance / divorce) and see the materialised list of documents to
// collect, with WHERE/WHY detail, a check-off, an "attach a file" action
// that links an already-uploaded document, a progress bar, an AI top-up for
// non-standard situations, an export action, and a prominent "basic list,
// not legal advice" disclaimer.
//
// Pure UI over the RLS+RPC backend + the doc-requirements edge fn.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../models/doc_requirement.dart';
import '../providers/doc_collection_provider.dart';
import '../services/doc_collection_service.dart';

class DocCollectionScreen extends ConsumerStatefulWidget {
  const DocCollectionScreen({super.key, this.initialProblemType});

  /// Optional deep-link: open straight to one problem type (`?type=`).
  final DocProblemType? initialProblemType;

  @override
  ConsumerState<DocCollectionScreen> createState() =>
      _DocCollectionScreenState();
}

class _DocCollectionScreenState extends ConsumerState<DocCollectionScreen> {
  DocProblemType? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialProblemType;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selected = _selected;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.docCollectTitle),
        actions: [
          if (selected != null)
            IconButton(
              tooltip: l10n.docCollectExport,
              icon: const Icon(Icons.ios_share),
              onPressed: () => _export(context, selected),
            ),
        ],
      ),
      body: Column(
        children: [
          _ProblemPicker(
            selected: selected,
            onSelect: (t) => setState(() => _selected = t),
          ),
          const Divider(height: 1),
          Expanded(
            child: selected == null
                ? _PickPrompt()
                : _RequirementList(problemType: selected),
          ),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context, DocProblemType type) async {
    final l10n = AppLocalizations.of(context)!;
    final set = ref.read(docRequirementsProvider(type)).valueOrNull;
    if (set == null || set.isEmpty) return;
    final text = set.toPlainText();
    if (text.isEmpty) return;
    await Share.share(text, subject: l10n.docCollectExportSubject);
  }
}

// ---------------------------------------------------------------------------
// Problem-type chips
// ---------------------------------------------------------------------------

class _ProblemPicker extends StatelessWidget {
  const _ProblemPicker({required this.selected, required this.onSelect});

  final DocProblemType? selected;
  final ValueChanged<DocProblemType> onSelect;

  String _label(AppLocalizations l10n, DocProblemType t) {
    switch (t) {
      case DocProblemType.residencePermit:
        return l10n.docCollectProblemResidence;
      case DocProblemType.tenantRights:
        return l10n.docCollectProblemTenant;
      case DocProblemType.dismissal:
        return l10n.docCollectProblemDismissal;
      case DocProblemType.inheritance:
        return l10n.docCollectProblemInheritance;
      case DocProblemType.divorce:
        return l10n.docCollectProblemDivorce;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          for (final t in DocProblemType.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ChoiceChip(
                label: Text(_label(l10n, t)),
                selected: selected == t,
                onSelected: (_) => onSelect(t),
              ),
            ),
        ],
      ),
    );
  }
}

class _PickPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.folder_open,
                size: 44, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.docCollectPickPrompt,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.docCollectSubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Requirement list for the selected problem type
// ---------------------------------------------------------------------------

class _RequirementList extends ConsumerWidget {
  const _RequirementList({required this.problemType});

  final DocProblemType problemType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(docRequirementsProvider(problemType));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 40, color: AppColors.error),
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.docCollectEmpty, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () =>
                    ref.invalidate(docRequirementsProvider(problemType)),
                child: Text(l10n.docCollectRetry),
              ),
            ],
          ),
        ),
      ),
      data: (set) {
        if (set.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.inventory_2_outlined,
                      size: 40, color: AppColors.textTertiary),
                  const SizedBox(height: AppSpacing.sm),
                  Text(l10n.docCollectEmpty, textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref
              .read(docRequirementsProvider(problemType).notifier)
              .refresh(),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _ProgressHeader(set: set),
              const SizedBox(height: AppSpacing.md),
              ...set.items.map(
                (item) => _RequirementTile(
                  problemType: problemType,
                  item: item,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _AiTopUp(problemType: problemType),
              const SizedBox(height: AppSpacing.md),
              const _Disclaimer(),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        );
      },
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.set});

  final DocRequirementSet set;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final allDone = set.allCollected;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: allDone ? AppColors.successBg : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                allDone ? Icons.task_alt : Icons.folder_copy,
                size: 20,
                color: allDone ? AppColors.success : AppColors.accent,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  allDone
                      ? l10n.docCollectAllDone
                      : l10n.docCollectProgress(set.collected, set.total),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: set.progress,
              minHeight: 8,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                allDone ? AppColors.success : AppColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequirementTile extends ConsumerWidget {
  const _RequirementTile({required this.problemType, required this.item});

  final DocProblemType problemType;
  final DocRequirement item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final notifier =
        ref.read(docRequirementsProvider(problemType).notifier);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () =>
                    notifier.toggle(item.requirementId, !item.collected),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Checkbox(checked: item.collected),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                    decoration: item.collected
                                        ? TextDecoration.lineThrough
                                        : null,
                                    decorationColor: AppColors.textTertiary,
                                  ),
                                ),
                              ),
                              if (item.optional) _OptionalChip(),
                            ],
                          ),
                          if (item.whereToGet != null &&
                              item.whereToGet!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            _DetailLine(
                              icon: Icons.place_outlined,
                              label: l10n.docCollectWhereLabel,
                              value: item.whereToGet!,
                            ),
                          ],
                          if (item.whyNeeded != null &&
                              item.whyNeeded!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            _DetailLine(
                              icon: Icons.help_outline,
                              label: l10n.docCollectWhyLabel,
                              value: item.whyNeeded!,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _AttachRow(problemType: problemType, item: item),
            ],
          ),
        ),
      ),
    );
  }
}

class _Checkbox extends StatelessWidget {
  const _Checkbox({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: checked ? AppColors.accent : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: checked ? AppColors.accent : AppColors.border,
          width: 2,
        ),
      ),
      child: checked
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : null,
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.textTertiary),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OptionalChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(left: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        l10n.docCollectOptional,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Attach-file row (links an already-uploaded document)
// ---------------------------------------------------------------------------

class _AttachRow extends ConsumerWidget {
  const _AttachRow({required this.problemType, required this.item});

  final DocProblemType problemType;
  final DocRequirement item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final notifier =
        ref.read(docRequirementsProvider(problemType).notifier);

    if (item.hasLinkedDocument) {
      return Row(
        children: [
          const Icon(Icons.attach_file, size: 16, color: AppColors.success),
          const SizedBox(width: 6),
          Text(
            l10n.docCollectAttached,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.success,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => _pickFile(context, ref),
            child: Text(l10n.docCollectChangeFile),
          ),
          IconButton(
            tooltip: l10n.docCollectRemoveFile,
            icon: const Icon(Icons.close, size: 18),
            onPressed: () =>
                notifier.linkDocument(item.requirementId, null),
          ),
        ],
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        icon: const Icon(Icons.attach_file, size: 16),
        label: Text(l10n.docCollectAttach),
        onPressed: () => _pickFile(context, ref),
      ),
    );
  }

  Future<void> _pickFile(BuildContext context, WidgetRef ref) async {
    final service = ref.read(docCollectionServiceProvider);
    final docs = await service.listDocuments();
    if (!context.mounted) return;
    final chosen = await showModalBottomSheet<LinkableDocument>(
      context: context,
      builder: (ctx) => _FilePickerSheet(docs: docs),
    );
    if (chosen == null) return;
    await ref
        .read(docRequirementsProvider(problemType).notifier)
        .linkDocument(item.requirementId, chosen.id);
  }
}

class _FilePickerSheet extends StatelessWidget {
  const _FilePickerSheet({required this.docs});

  final List<LinkableDocument> docs;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.docCollectPickFileTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (docs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Text(
                  l10n.docCollectNoFiles,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final d = docs[i];
                    return ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: Text(d.fileName,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () => Navigator.of(ctx).pop(d),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AI top-up — propose extra documents for a non-standard situation
// ---------------------------------------------------------------------------

class _AiTopUp extends ConsumerStatefulWidget {
  const _AiTopUp({required this.problemType});

  final DocProblemType problemType;

  @override
  ConsumerState<_AiTopUp> createState() => _AiTopUpState();
}

class _AiTopUpState extends ConsumerState<_AiTopUp> {
  final _controller = TextEditingController();
  bool _loading = false;
  List<DocSuggestion>? _suggestions;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;
    setState(() => _loading = true);
    final result = await ref.read(docCollectionServiceProvider).suggestExtra(
          problemType: widget.problemType,
          situation: text,
        );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _suggestions = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
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
              const Icon(Icons.auto_awesome,
                  size: 18, color: AppColors.accent),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.docCollectAiTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.docCollectAiHint,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _controller,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: l10n.docCollectAiField,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _loading ? null : _run,
              icon: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome, size: 16),
              label: Text(
                _loading ? l10n.docCollectAiLoading : l10n.docCollectAiButton,
              ),
            ),
          ),
          if (_suggestions != null) ...[
            const SizedBox(height: AppSpacing.sm),
            if (_suggestions!.isEmpty)
              Text(
                l10n.docCollectAiEmpty,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              )
            else ...[
              Text(
                l10n.docCollectAiSuggestionsTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              ..._suggestions!.map((s) => _SuggestionTile(suggestion: s)),
            ],
          ],
        ],
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({required this.suggestion});

  final DocSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.add_circle_outline,
              size: 16, color: AppColors.accent),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (suggestion.whereToGet != null &&
                    suggestion.whereToGet!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  _DetailLine(
                    icon: Icons.place_outlined,
                    label: l10n.docCollectWhereLabel,
                    value: suggestion.whereToGet!,
                  ),
                ],
                if (suggestion.whyNeeded != null &&
                    suggestion.whyNeeded!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  _DetailLine(
                    icon: Icons.help_outline,
                    label: l10n.docCollectWhyLabel,
                    value: suggestion.whyNeeded!,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.infoBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.info),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              l10n.docCollectDisclaimer,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.info,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
