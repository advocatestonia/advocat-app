// =====================================================================
// CaseEditScreen — full UserCase editor.
//
// Each jsonb section is a tiny add/remove list of rows. We deliberately
// keep the UI simple: text fields per known field, "+ add" button,
// "x remove" per row. No drag-reorder, no schema editor — that's
// out of scope.
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../data/case_repository.dart';
import '../models/user_case.dart';
import '../state/cases_list_provider.dart';

class CaseEditScreen extends ConsumerStatefulWidget {
  const CaseEditScreen({super.key, required this.caseId});
  final String caseId;

  @override
  ConsumerState<CaseEditScreen> createState() => _CaseEditScreenState();
}

class _CaseEditScreenState extends ConsumerState<CaseEditScreen> {
  UserCase? _draft;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _summaryCtrl;
  late final TextEditingController _jurisdictionCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _summaryCtrl = TextEditingController();
    _jurisdictionCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _summaryCtrl.dispose();
    _jurisdictionCtrl.dispose();
    super.dispose();
  }

  void _seed(UserCase c) {
    _draft ??= c;
    if (_titleCtrl.text.isEmpty) _titleCtrl.text = c.title;
    if (_summaryCtrl.text.isEmpty) _summaryCtrl.text = c.summary ?? '';
    if (_jurisdictionCtrl.text.isEmpty) {
      _jurisdictionCtrl.text = c.jurisdiction;
    }
  }

  Future<void> _save() async {
    if (_draft == null) return;
    setState(() => _saving = true);
    try {
      final updated = _draft!.copyWith(
        title: _titleCtrl.text.trim(),
        summary: _summaryCtrl.text.trim().isEmpty
            ? null
            : _summaryCtrl.text.trim(),
        jurisdiction: _jurisdictionCtrl.text.trim().isEmpty
            ? _draft!.jurisdiction
            : _jurisdictionCtrl.text.trim(),
      );
      await ref.read(caseRepositoryProvider).updateCase(updated);
      ref.invalidate(caseByIdProvider(widget.caseId));
      ref.invalidate(casesListProvider);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n?.caseSavedAck ?? 'Case saved')),
      );
      context.pop();
    } catch (e) {
      debugPrint('case_edit save failed: $e');
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.genericError ?? 'Something went wrong. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final caseAsync = ref.watch(caseByIdProvider(widget.caseId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.edit ?? 'Edit'),
        actions: [
          IconButton(
            key: const Key('save-case-btn'),
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            tooltip: l10n?.save ?? 'Save',
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: caseAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) {
          debugPrint('case_edit load failed: $e');
          return Center(
            child: Text(
              l10n?.genericError ?? 'Something went wrong. Please try again.',
            ),
          );
        },
        data: (c) {
          if (c == null) {
            return Center(child: Text(l10n?.error ?? 'Case not found'));
          }
          _seed(c);
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              TextField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  labelText: l10n?.caseTitleLabel ?? 'Case title',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _jurisdictionCtrl,
                decoration: InputDecoration(
                  labelText: l10n?.jurisdictionLabel ?? 'Jurisdiction',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _summaryCtrl,
                decoration: InputDecoration(
                  labelText: l10n?.summarySection ?? 'Summary',
                ),
                maxLines: 4,
              ),
              const SizedBox(height: AppSpacing.lg),

              _CaseNumbersEditor(
                items: _draft!.caseNumbers,
                onChanged: (v) =>
                    setState(() => _draft = _draft!.copyWith(caseNumbers: v)),
              ),
              _PartiesEditor(
                items: _draft!.parties,
                onChanged: (v) =>
                    setState(() => _draft = _draft!.copyWith(parties: v)),
              ),
              _KeyDatesEditor(
                items: _draft!.keyDates,
                onChanged: (v) =>
                    setState(() => _draft = _draft!.copyWith(keyDates: v)),
              ),
              _AuthoritiesEditor(
                items: _draft!.authorities,
                onChanged: (v) =>
                    setState(() => _draft = _draft!.copyWith(authorities: v)),
              ),
              _TimelineEditor(
                items: _draft!.timeline,
                onChanged: (v) =>
                    setState(() => _draft = _draft!.copyWith(timeline: v)),
              ),
              _OpenQuestionsEditor(
                items: _draft!.openQuestions,
                onChanged: (v) => setState(
                  () => _draft = _draft!.copyWith(openQuestions: v),
                ),
              ),
              _NextActionsEditor(
                items: _draft!.nextActions,
                onChanged: (v) => setState(
                  () => _draft = _draft!.copyWith(nextActions: v),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          );
        },
      ),
    );
  }
}

// ── Reusable editor scaffold ─────────────────────────────────────────

class _SectionEditor extends StatelessWidget {
  const _SectionEditor({
    required this.title,
    required this.itemCount,
    required this.itemBuilder,
    required this.onAdd,
  });

  final String title;
  final int itemCount;
  final Widget Function(int) itemBuilder;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 16),
                label: Text(l10n?.addRow ?? 'Add'),
              ),
            ],
          ),
          for (var i = 0; i < itemCount; i++) itemBuilder(i),
        ],
      ),
    );
  }
}

Widget _removeButton(VoidCallback onTap, {String? label}) {
  return IconButton(
    icon: const Icon(Icons.close, size: 18),
    color: AppColors.error,
    tooltip: label,
    onPressed: onTap,
  );
}

// ── Concrete editors ─────────────────────────────────────────────────

class _CaseNumbersEditor extends StatelessWidget {
  const _CaseNumbersEditor({required this.items, required this.onChanged});
  final List<CaseNumber> items;
  final ValueChanged<List<CaseNumber>> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SectionEditor(
      title: l10n?.caseNumbersSection ?? 'Case numbers',
      itemCount: items.length,
      itemBuilder: (i) {
        final cn = items[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: cn.authority,
                  decoration: const InputDecoration(labelText: 'Authority'),
                  onChanged: (v) {
                    final next = [...items];
                    next[i] = CaseNumber(
                      authority: v,
                      number: cn.number,
                      role: cn.role,
                    );
                    onChanged(next);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: cn.number,
                  decoration: const InputDecoration(labelText: 'Number'),
                  onChanged: (v) {
                    final next = [...items];
                    next[i] = CaseNumber(
                      authority: cn.authority,
                      number: v,
                      role: cn.role,
                    );
                    onChanged(next);
                  },
                ),
              ),
              _removeButton(() {
                final next = [...items]..removeAt(i);
                onChanged(next);
              }),
            ],
          ),
        );
      },
      onAdd: () => onChanged([
        ...items,
        const CaseNumber(authority: '', number: '', role: null),
      ]),
    );
  }
}

class _PartiesEditor extends StatelessWidget {
  const _PartiesEditor({required this.items, required this.onChanged});
  final List<Party> items;
  final ValueChanged<List<Party>> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SectionEditor(
      title: l10n?.partiesSection ?? 'Parties',
      itemCount: items.length,
      itemBuilder: (i) {
        final p = items[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: p.role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  onChanged: (v) {
                    final next = [...items];
                    next[i] = Party(role: v, name: p.name, note: p.note);
                    onChanged(next);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: p.name,
                  decoration: const InputDecoration(labelText: 'Name'),
                  onChanged: (v) {
                    final next = [...items];
                    next[i] = Party(role: p.role, name: v, note: p.note);
                    onChanged(next);
                  },
                ),
              ),
              _removeButton(() {
                final next = [...items]..removeAt(i);
                onChanged(next);
              }),
            ],
          ),
        );
      },
      onAdd: () =>
          onChanged([...items, const Party(role: '', name: '', note: null)]),
    );
  }
}

class _KeyDatesEditor extends StatelessWidget {
  const _KeyDatesEditor({required this.items, required this.onChanged});
  final List<KeyDate> items;
  final ValueChanged<List<KeyDate>> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SectionEditor(
      title: 'Key dates',
      itemCount: items.length,
      itemBuilder: (i) {
        final d = items[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: d.label,
                  decoration: const InputDecoration(labelText: 'Label'),
                  onChanged: (v) {
                    final next = [...items];
                    next[i] = KeyDate(label: v, date: d.date, note: d.note);
                    onChanged(next);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: d.date,
                  decoration:
                      const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
                  onChanged: (v) {
                    final next = [...items];
                    next[i] = KeyDate(label: d.label, date: v, note: d.note);
                    onChanged(next);
                  },
                ),
              ),
              _removeButton(() {
                final next = [...items]..removeAt(i);
                onChanged(next);
              }),
            ],
          ),
        );
      },
      onAdd: () => onChanged(
        [...items, const KeyDate(label: '', date: '', note: null)],
      ),
    );
  }
}

class _AuthoritiesEditor extends StatelessWidget {
  const _AuthoritiesEditor({required this.items, required this.onChanged});
  final List<Authority> items;
  final ValueChanged<List<Authority>> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SectionEditor(
      title: l10n?.authoritiesSection ?? 'Authorities',
      itemCount: items.length,
      itemBuilder: (i) {
        final a = items[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: a.name,
                  decoration: const InputDecoration(labelText: 'Name'),
                  onChanged: (v) {
                    final next = [...items];
                    next[i] = Authority(name: v, contact: a.contact);
                    onChanged(next);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: a.contact ?? '',
                  decoration: const InputDecoration(labelText: 'Contact'),
                  onChanged: (v) {
                    final next = [...items];
                    next[i] = Authority(
                      name: a.name,
                      contact: v.isEmpty ? null : v,
                    );
                    onChanged(next);
                  },
                ),
              ),
              _removeButton(() {
                final next = [...items]..removeAt(i);
                onChanged(next);
              }),
            ],
          ),
        );
      },
      onAdd: () =>
          onChanged([...items, const Authority(name: '', contact: null)]),
    );
  }
}

class _TimelineEditor extends StatelessWidget {
  const _TimelineEditor({required this.items, required this.onChanged});
  final List<TimelineEntry> items;
  final ValueChanged<List<TimelineEntry>> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SectionEditor(
      title: l10n?.timelineSection ?? 'Timeline',
      itemCount: items.length,
      itemBuilder: (i) {
        final t = items[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: t.date,
                  decoration:
                      const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
                  onChanged: (v) {
                    final next = [...items];
                    next[i] = TimelineEntry(date: v, event: t.event);
                    onChanged(next);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: t.event,
                  decoration: const InputDecoration(labelText: 'Event'),
                  onChanged: (v) {
                    final next = [...items];
                    next[i] = TimelineEntry(date: t.date, event: v);
                    onChanged(next);
                  },
                ),
              ),
              _removeButton(() {
                final next = [...items]..removeAt(i);
                onChanged(next);
              }),
            ],
          ),
        );
      },
      onAdd: () =>
          onChanged([...items, const TimelineEntry(date: '', event: '')]),
    );
  }
}

class _OpenQuestionsEditor extends StatelessWidget {
  const _OpenQuestionsEditor({required this.items, required this.onChanged});
  final List<OpenQuestion> items;
  final ValueChanged<List<OpenQuestion>> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SectionEditor(
      title: l10n?.openQuestionsSection ?? 'Open questions',
      itemCount: items.length,
      itemBuilder: (i) {
        final q = items[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: q.question,
                  decoration: const InputDecoration(labelText: 'Question'),
                  onChanged: (v) {
                    final next = [...items];
                    next[i] = OpenQuestion(question: v, priority: q.priority);
                    onChanged(next);
                  },
                ),
              ),
              _removeButton(() {
                final next = [...items]..removeAt(i);
                onChanged(next);
              }),
            ],
          ),
        );
      },
      onAdd: () => onChanged(
        [...items, const OpenQuestion(question: '', priority: null)],
      ),
    );
  }
}

class _NextActionsEditor extends StatelessWidget {
  const _NextActionsEditor({required this.items, required this.onChanged});
  final List<NextAction> items;
  final ValueChanged<List<NextAction>> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SectionEditor(
      title: l10n?.nextActionsSection ?? 'Next actions',
      itemCount: items.length,
      itemBuilder: (i) {
        final a = items[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: a.action,
                  decoration: const InputDecoration(labelText: 'Action'),
                  onChanged: (v) {
                    final next = [...items];
                    next[i] = NextAction(action: v, due: a.due);
                    onChanged(next);
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 120,
                child: TextFormField(
                  initialValue: a.due ?? '',
                  decoration:
                      const InputDecoration(labelText: 'Due (YYYY-MM-DD)'),
                  onChanged: (v) {
                    final next = [...items];
                    next[i] = NextAction(
                      action: a.action,
                      due: v.isEmpty ? null : v,
                    );
                    onChanged(next);
                  },
                ),
              ),
              _removeButton(() {
                final next = [...items]..removeAt(i);
                onChanged(next);
              }),
            ],
          ),
        );
      },
      onAdd: () =>
          onChanged([...items, const NextAction(action: '', due: null)]),
    );
  }
}
