// gold_review_screen.dart — Sofia's Goldkorpus review console.
// -----------------------------------------------------------------------------
// Phase A scope:
//   - Header with pending / approved-this-month counters
//   - Filter row: language / category / jurisdiction / date dropdown
//   - Master-detail layout (40% / 60%) on wide screens; stacked on narrow
//   - 4 actions: Approve / Edit / Reject / Skip
//   - Reject reason dropdown + reviewer notes field
//   - Keyboard shortcuts: a, e, r, s, j, k, Cmd+Enter
//   - Bottom progress bar against weekly target (default 100)
//
// Access control: AppRouter mounts this only when the current user's id is
// in the GOLD_REVIEWER_IDS allowlist (compiled via --dart-define). The edge
// function also enforces the allowlist server-side, so a hand-crafted route
// won't leak data.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/gold_review_service.dart';
import 'widgets/gold_review_card.dart';

const int kWeeklyTarget = 100;

const List<String> _kLanguageOptions = [
  '', 'et', 'ru', 'en', 'fi', 'lv', 'lt', 'sv', 'uk',
];
const List<String> _kCategoryOptions = [
  '', 'employment', 'housing', 'family', 'migration',
  'consumer', 'contract', 'criminal', 'admin', 'other',
];
const List<String> _kJurisdictionOptions = [
  '', 'estonia', 'finland', 'eu', 'other',
];

const Map<String, String> _kRejectionReasons = {
  'wrong_law': 'Wrong law',
  'hallucination': 'Hallucination',
  'wrong_tone': 'Wrong tone',
  'off_topic': 'Off topic',
  'outdated': 'Outdated',
  'other': 'Other',
};

// ─── Providers ──────────────────────────────────────────────────────────────

class _Filters {
  const _Filters({this.language, this.category, this.jurisdiction});
  final String? language;
  final String? category;
  final String? jurisdiction;
}

final _filtersProvider = StateProvider<_Filters>((_) => const _Filters());

final _queueProvider = FutureProvider.autoDispose
    .family<List<GoldQueueItem>, _Filters>((ref, filters) async {
  final svc = ref.watch(goldReviewServiceProvider);
  return svc.listQueue(
    limit: 20,
    language: filters.language,
    category: filters.category,
    jurisdiction: filters.jurisdiction,
  );
});

final _statsProvider = FutureProvider.autoDispose<GoldCorpusStats>((ref) async {
  final svc = ref.watch(goldReviewServiceProvider);
  return svc.fetchStats();
});

final _selectedIdProvider = StateProvider<String?>((_) => null);

// ─── Screen ─────────────────────────────────────────────────────────────────

class GoldReviewScreen extends ConsumerStatefulWidget {
  const GoldReviewScreen({super.key});

  @override
  ConsumerState<GoldReviewScreen> createState() => _GoldReviewScreenState();
}

class _GoldReviewScreenState extends ConsumerState<GoldReviewScreen> {
  final FocusNode _shortcutFocus = FocusNode();

  @override
  void dispose() {
    _shortcutFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(_filtersProvider);
    final queueAsync = ref.watch(_queueProvider(filters));
    final statsAsync = ref.watch(_statsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Goldkorpus Review${_headerSuffix(statsAsync)}'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(_queueProvider);
              ref.invalidate(_statsProvider);
            },
          ),
        ],
      ),
      body: Focus(
        focusNode: _shortcutFocus,
        autofocus: true,
        onKeyEvent: (node, event) => _onKey(event, queueAsync),
        child: LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth >= 800;
            return Column(
              children: [
                _FilterRow(),
                Expanded(
                  child: wide
                      ? Row(
                          children: [
                            SizedBox(
                              width: c.maxWidth * 0.4,
                              child: _MasterList(queueAsync: queueAsync),
                            ),
                            const VerticalDivider(width: 1),
                            Expanded(
                              child: _DetailPanel(
                                onDecided: _onDecided,
                              ),
                            ),
                          ],
                        )
                      : _MasterList(queueAsync: queueAsync),
                ),
                _ProgressBar(statsAsync: statsAsync),
              ],
            );
          },
        ),
      ),
    );
  }

  String _headerSuffix(AsyncValue<GoldCorpusStats> stats) {
    return stats.maybeWhen(
      data: (s) => '  ·  ${s.pendingReview} pending  ·  '
          '${s.reviewedThisMonth} approved this month',
      orElse: () => '',
    );
  }

  void _onDecided() {
    ref.invalidate(_queueProvider);
    ref.invalidate(_statsProvider);
    _advanceSelection();
  }

  void _advanceSelection() {
    final filters = ref.read(_filtersProvider);
    final queue = ref.read(_queueProvider(filters)).valueOrNull;
    if (queue == null || queue.isEmpty) {
      ref.read(_selectedIdProvider.notifier).state = null;
      return;
    }
    final current = ref.read(_selectedIdProvider);
    final idx = queue.indexWhere((it) => it.id == current);
    final next = (idx >= 0 && idx + 1 < queue.length)
        ? queue[idx + 1]
        : queue.first;
    ref.read(_selectedIdProvider.notifier).state = next.id;
  }

  KeyEventResult _onKey(
    KeyEvent event,
    AsyncValue<List<GoldQueueItem>> queueAsync,
  ) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final queue = queueAsync.valueOrNull;
    if (queue == null || queue.isEmpty) return KeyEventResult.ignored;

    // Ignore shortcuts while a text editor has focus — otherwise typing
    // "a" in the gold-answer textarea would fire Approve.
    final primary = FocusManager.instance.primaryFocus;
    final inTextField = primary?.context?.widget is EditableText ||
        (primary?.context?.findAncestorWidgetOfExactType<EditableText>() !=
            null);
    if (inTextField) return KeyEventResult.ignored;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.keyJ) {
      _moveSelection(queue, 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyK) {
      _moveSelection(queue, -1);
      return KeyEventResult.handled;
    }
    // a / e / r / s shortcuts are intercepted by the detail panel via the
    // sentinel keys (a/e/r/s shortcut bridge). We expose them by tapping
    // the buttons through their Keys.
    final tapKey = switch (key) {
      LogicalKeyboardKey.keyA => const Key('gold-action-approve'),
      LogicalKeyboardKey.keyE => const Key('gold-action-edit'),
      LogicalKeyboardKey.keyR => const Key('gold-action-reject'),
      LogicalKeyboardKey.keyS => const Key('gold-action-skip'),
      _ => null,
    };
    if (tapKey != null) {
      _fireButton(tapKey);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _fireButton(Key key) {
    // Walk the widget tree to find the button with [key] and tap it.
    void visit(Element el) {
      if (el.widget.key == key) {
        final w = el.widget;
        VoidCallback? cb;
        if (w is FilledButton) cb = w.onPressed;
        if (w is OutlinedButton) cb = w.onPressed;
        if (w is TextButton) cb = w.onPressed;
        // FilledButton.icon / .tonalIcon return generic ButtonStyleButton subtypes
        if (cb == null && w is ButtonStyleButton) cb = w.onPressed;
        cb?.call();
        return;
      }
      el.visitChildren(visit);
    }

    context.visitChildElements(visit);
  }

  void _moveSelection(List<GoldQueueItem> queue, int delta) {
    final current = ref.read(_selectedIdProvider);
    int idx = queue.indexWhere((it) => it.id == current);
    if (idx < 0) idx = 0;
    idx = (idx + delta).clamp(0, queue.length - 1);
    ref.read(_selectedIdProvider.notifier).state = queue[idx].id;
  }
}

// ─── Filter row ─────────────────────────────────────────────────────────────

class _FilterRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(_filtersProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          _filterDropdown(
            label: 'Language',
            value: filters.language ?? '',
            options: _kLanguageOptions,
            onChanged: (v) => ref.read(_filtersProvider.notifier).state =
                _Filters(
                  language: v.isEmpty ? null : v,
                  category: filters.category,
                  jurisdiction: filters.jurisdiction,
                ),
          ),
          const SizedBox(width: 12),
          _filterDropdown(
            label: 'Category',
            value: filters.category ?? '',
            options: _kCategoryOptions,
            onChanged: (v) => ref.read(_filtersProvider.notifier).state =
                _Filters(
                  language: filters.language,
                  category: v.isEmpty ? null : v,
                  jurisdiction: filters.jurisdiction,
                ),
          ),
          const SizedBox(width: 12),
          _filterDropdown(
            label: 'Jurisdiction',
            value: filters.jurisdiction ?? '',
            options: _kJurisdictionOptions,
            onChanged: (v) => ref.read(_filtersProvider.notifier).state =
                _Filters(
                  language: filters.language,
                  category: filters.category,
                  jurisdiction: v.isEmpty ? null : v,
                ),
          ),
        ],
      ),
    );
  }

  Widget _filterDropdown({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label:'),
        const SizedBox(width: 6),
        DropdownButton<String>(
          value: value,
          underline: const SizedBox.shrink(),
          items: options
              .map((o) => DropdownMenuItem(
                    value: o,
                    child: Text(o.isEmpty ? '(any)' : o),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }
}

// ─── Master list ────────────────────────────────────────────────────────────

class _MasterList extends ConsumerWidget {
  const _MasterList({required this.queueAsync});
  final AsyncValue<List<GoldQueueItem>> queueAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return queueAsync.when(
      data: (rows) {
        if (rows.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Inbox zero. Backlog cleared.'),
            ),
          );
        }
        final selected = ref.watch(_selectedIdProvider);
        // Auto-select first row when nothing is selected yet.
        if (selected == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (ref.read(_selectedIdProvider) == null && rows.isNotEmpty) {
              ref.read(_selectedIdProvider.notifier).state = rows.first.id;
            }
          });
        }
        return ListView.builder(
          itemCount: rows.length,
          itemBuilder: (ctx, i) {
            final row = rows[i];
            return GoldReviewCard(
              item: row,
              selected: row.id == selected,
              onTap: () => ref.read(_selectedIdProvider.notifier).state = row.id,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Failed to load queue: $e'),
        ),
      ),
    );
  }
}

// ─── Detail panel ───────────────────────────────────────────────────────────

class _DetailPanel extends ConsumerStatefulWidget {
  const _DetailPanel({required this.onDecided});
  final VoidCallback onDecided;

  @override
  ConsumerState<_DetailPanel> createState() => _DetailPanelState();
}

class _DetailPanelState extends ConsumerState<_DetailPanel> {
  final TextEditingController _goldCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  String? _rejectReason;
  bool _editMode = false;
  bool _rejectMode = false;
  bool _submitting = false;
  String? _hydratedItemId;

  @override
  void dispose() {
    _goldCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _hydrateFor(GoldQueueItem item) {
    if (_hydratedItemId == item.id) return;
    _hydratedItemId = item.id;
    _goldCtrl.text = item.aiAnswer;
    _notesCtrl.clear();
    _rejectReason = null;
    _editMode = false;
    _rejectMode = false;
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(_filtersProvider);
    final queueAsync = ref.watch(_queueProvider(filters));
    final selectedId = ref.watch(_selectedIdProvider);

    return queueAsync.when(
      data: (rows) {
        final item = selectedId == null
            ? null
            : rows.cast<GoldQueueItem?>().firstWhere(
                  (it) => it?.id == selectedId,
                  orElse: () => null,
                );
        if (item == null) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Select a row to begin review.'),
            ),
          );
        }
        _hydrateFor(item);
        return _buildDetail(item);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildDetail(GoldQueueItem item) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (item.language != null) _meta('lang', item.language!),
              if (item.category != null) _meta('cat', item.category!),
              if (item.jurisdiction != null) _meta('jur', item.jurisdiction!),
              if (item.aiModel != null) _meta('model', item.aiModel!),
            ],
          ),
          const SizedBox(height: 12),
          Text('Question', style: t.textTheme.titleSmall),
          const SizedBox(height: 4),
          _readonlyBox(item.userQuestion),
          const SizedBox(height: 12),
          Text('AI answer', style: t.textTheme.titleSmall),
          const SizedBox(height: 4),
          Expanded(child: _readonlyBox(item.aiAnswer, scrollable: true)),
          const SizedBox(height: 12),
          if (_editMode) ...[
            Text('Gold answer (edit)', style: t.textTheme.titleSmall),
            const SizedBox(height: 4),
            TextField(
              controller: _goldCtrl,
              maxLines: 6,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (_rejectMode) ...[
            Text('Rejection reason', style: t.textTheme.titleSmall),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              initialValue: _rejectReason,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: _kRejectionReasons.entries
                  .map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _rejectReason = v),
            ),
            const SizedBox(height: 8),
          ],
          Text('Reviewer notes', style: t.textTheme.titleSmall),
          const SizedBox(height: 4),
          TextField(
            controller: _notesCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Optional notes for next reviewer',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          _ActionBar(
            submitting: _submitting,
            onApprove: () => _submit(item, GoldDecisionStatus.approved),
            onEdit: _editMode
                ? () => _submit(item, GoldDecisionStatus.edited)
                : () => setState(() {
                      _editMode = true;
                      _rejectMode = false;
                    }),
            onReject: _rejectMode
                ? () => _submit(item, GoldDecisionStatus.rejected)
                : () => setState(() {
                      _rejectMode = true;
                      _editMode = false;
                    }),
            onSkip: () => _submit(item, GoldDecisionStatus.skipped),
            editPrimed: _editMode,
            rejectPrimed: _rejectMode,
          ),
        ],
      ),
    );
  }

  Widget _meta(String k, String v) {
    final t = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: t.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$k: $v',
        style: t.textTheme.labelSmall,
      ),
    );
  }

  Widget _readonlyBox(String text, {bool scrollable = false}) {
    final t = Theme.of(context);
    final inner = SelectableText(
      text,
      style: t.textTheme.bodyMedium,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: t.colorScheme.surface,
        border: Border.all(color: t.dividerColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: scrollable
          ? SingleChildScrollView(child: inner)
          : inner,
    );
  }

  Future<void> _submit(
    GoldQueueItem item,
    GoldDecisionStatus status,
  ) async {
    if (_submitting) return;
    if (status == GoldDecisionStatus.rejected && _rejectReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a rejection reason first.')),
      );
      return;
    }
    if (status == GoldDecisionStatus.edited && _goldCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gold answer cannot be empty.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final svc = ref.read(goldReviewServiceProvider);
      final result = await svc.decide(
        queueId: item.id,
        status: status,
        goldAnswer: status == GoldDecisionStatus.edited
            ? _goldCtrl.text.trim()
            : null,
        rejectionReason:
            status == GoldDecisionStatus.rejected ? _rejectReason : null,
        reviewerNotes: _notesCtrl.text.trim().isEmpty
            ? null
            : _notesCtrl.text.trim(),
      );
      if (!mounted) return;
      if (!result.ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${result.error ?? "unknown"}')),
        );
      } else {
        widget.onDecided();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

// ─── Action bar ─────────────────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.submitting,
    required this.onApprove,
    required this.onEdit,
    required this.onReject,
    required this.onSkip,
    required this.editPrimed,
    required this.rejectPrimed,
  });

  final bool submitting;
  final VoidCallback onApprove;
  final VoidCallback onEdit;
  final VoidCallback onReject;
  final VoidCallback onSkip;
  final bool editPrimed;
  final bool rejectPrimed;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    if (submitting) {
      return const SizedBox(
        height: 40,
        child: Center(child: LinearProgressIndicator()),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          key: const Key('gold-action-approve'),
          icon: const Icon(Icons.thumb_up),
          label: const Text('Approve  (a)'),
          onPressed: onApprove,
        ),
        FilledButton.tonalIcon(
          key: const Key('gold-action-edit'),
          icon: Icon(editPrimed ? Icons.check : Icons.edit),
          label: Text(editPrimed ? 'Submit edit  (⌘⏎)' : 'Edit  (e)'),
          onPressed: onEdit,
        ),
        OutlinedButton.icon(
          key: const Key('gold-action-reject'),
          icon: Icon(rejectPrimed ? Icons.check : Icons.block,
              color: Colors.red),
          label: Text(
            rejectPrimed ? 'Submit reject  (⌘⏎)' : 'Reject  (r)',
            style: TextStyle(color: t.colorScheme.error),
          ),
          onPressed: onReject,
        ),
        TextButton.icon(
          key: const Key('gold-action-skip'),
          icon: const Icon(Icons.skip_next),
          label: const Text('Skip  (s)'),
          onPressed: onSkip,
        ),
      ],
    );
  }
}

// ─── Progress bar ───────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.statsAsync});
  final AsyncValue<GoldCorpusStats> statsAsync;

  @override
  Widget build(BuildContext context) {
    return statsAsync.when(
      data: (s) {
        final week = s.reviewedThisWeek;
        final pct = (week / kWeeklyTarget).clamp(0.0, 1.0);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: Theme.of(context).colorScheme.surface,
          child: Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(value: pct, minHeight: 6),
              ),
              const SizedBox(width: 8),
              Text('$week / $kWeeklyTarget this week'),
              const SizedBox(width: 16),
              Text('today ${s.reviewedToday}'),
              const SizedBox(width: 12),
              Text('month ${s.reviewedThisMonth}'),
            ],
          ),
        );
      },
      loading: () => const SizedBox(
        height: 18,
        child: LinearProgressIndicator(minHeight: 2),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
