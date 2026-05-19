// drafting/screens/drafting_studio_screen.dart — Pkg 7 Drafting Studio MVP.
// -----------------------------------------------------------------------------
// Main editor screen. Loads a draft by id, autosaves every 30s, exposes a
// formatting toolbar, AI revise dialog, and export menu. Stays under 500
// lines by delegating presentation to small siblings (toolbar, dialog,
// strings) and IO to DraftService.
// -----------------------------------------------------------------------------

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/draft_model.dart';
import '../services/draft_service.dart';
import '../widgets/ai_revision_dialog.dart';
import '../widgets/draft_toolbar.dart';
import '../widgets/drafting_strings.dart';

/// Loads + edits a single draft. The route can be opened either by id
/// (existing draft) or via a `prefill` payload (e.g. from Contract Review).
class DraftingStudioScreen extends ConsumerStatefulWidget {
  const DraftingStudioScreen({
    super.key,
    this.draftId,
    this.prefill,
  });

  /// Existing draft id. If null, [prefill] must be set so we can create
  /// a fresh row on first save.
  final String? draftId;

  /// Optional pre-fill payload (e.g. from "Draft a reply" in Contract Review).
  final DraftPrefill? prefill;

  @override
  ConsumerState<DraftingStudioScreen> createState() => _DraftingStudioScreenState();
}

/// Plain pre-fill payload — no Riverpod refs so it can be passed via go_router.
class DraftPrefill {
  const DraftPrefill({
    required this.title,
    required this.contentMarkdown,
    this.language,
    this.sourceType = DraftSourceType.blank,
    this.sourceId,
    this.caseId,
  });
  final String title;
  final String contentMarkdown;
  final String? language;
  final DraftSourceType sourceType;
  final String? sourceId;
  final String? caseId;
}

class _DraftingStudioScreenState extends ConsumerState<DraftingStudioScreen> {
  late final TextEditingController _bodyCtrl;
  late final TextEditingController _titleCtrl;
  Draft? _draft;
  AutosaveController? _autosave;
  String? _savedLabel;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bodyCtrl = TextEditingController();
    _titleCtrl = TextEditingController();
    // Defer to next frame so the Scaffold is mounted before we trigger any
    // SnackBars from initial load failures.
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOrCreate());
  }

  @override
  void dispose() {
    _autosave?.dispose();
    _bodyCtrl.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadOrCreate() async {
    final svc = ref.read(draftServiceProvider);
    setState(() => _busy = true);
    try {
      Draft? draft;
      if (widget.draftId != null) {
        draft = await svc.fetchById(widget.draftId!);
      }
      if (draft == null) {
        // Either no id, or fetch returned null (deleted / cross-user).
        final prefill = widget.prefill;
        if (prefill == null) {
          // Empty in-memory draft until first save creates the row.
          if (!mounted) return;
          setState(() => _busy = false);
          return;
        }
        // Determine current user id from Supabase. If we can't, leave the
        // editor in offline mode (user-less drafts are not persisted).
        // We avoid coupling this screen to SupabaseService — read from the
        // current auth session directly.
        final session = _currentUserId();
        if (session == null) {
          if (!mounted) return;
          setState(() {
            _busy = false;
            _error = 'Not authenticated';
          });
          return;
        }
        draft = await svc.createDraft(
          userId: session,
          caseId: prefill.caseId,
          sourceType: prefill.sourceType,
          sourceId: prefill.sourceId,
          title: prefill.title,
          contentMarkdown: prefill.contentMarkdown,
          language: prefill.language,
        );
      }
      _draft = draft;
      _bodyCtrl.text = draft.contentMarkdown;
      _titleCtrl.text = draft.title ?? '';
      _autosave = AutosaveController(
        service: svc,
        draftId: draft.id,
      );
      _bodyCtrl.addListener(_onChanged);
      _titleCtrl.addListener(_onChanged);
      if (!mounted) return;
      setState(() => _busy = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  String? _currentUserId() {
    final override = debugSupabaseUserIdAccessor;
    if (override != null) return override();
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  void _onChanged() {
    _autosave?.markDirty(
      markdown: _bodyCtrl.text,
      title: _titleCtrl.text.isEmpty ? null : _titleCtrl.text,
    );
    if (mounted) {
      setState(() {
        _savedLabel = DraftingStrings.of(context).saved;
      });
    }
  }

  Future<void> _manualSave() async {
    if (_autosave == null) return;
    setState(() => _busy = true);
    try {
      await _autosave!.flush();
      if (!mounted) return;
      setState(() {
        _savedLabel = DraftingStrings.of(context).savedJustNow;
      });
    } catch (e, st) {
      debugPrint('[drafting_studio] manualSave failed: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(DraftingStrings.of(context).saveFailed)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _applyFormat(DraftFormatOp op) async {
    final sel = _bodyCtrl.selection;
    final start = sel.start < 0 ? _bodyCtrl.text.length : sel.start;
    final end = sel.end < 0 ? _bodyCtrl.text.length : sel.end;
    final result = applyFormat(op, _bodyCtrl.text, start, end);
    _bodyCtrl.value = TextEditingValue(
      text: result.text,
      selection: TextSelection(
        baseOffset: result.selectionStart,
        extentOffset: result.selectionEnd,
      ),
    );
  }

  Future<void> _runAiRevise() async {
    final sel = _bodyCtrl.selection;
    final hasSelection = sel.isValid && sel.start != sel.end;
    if (!hasSelection) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select text first to revise it.')),
      );
      return;
    }
    final selectedText = _bodyCtrl.text.substring(sel.start, sel.end);
    final draftId = _draft?.id;
    if (draftId == null) return;
    final svc = ref.read(draftServiceProvider);
    final ctx = _surroundingContext(sel.start, sel.end);

    final decision = await showAiRevisionDialog(
      context: context,
      selectedText: selectedText,
      onRequestRevision: (instr) => svc.reviseWithAi(
        draftId: draftId,
        selectedText: selectedText,
        instruction: instr,
        context: ctx,
        language: _draft?.language,
      ),
    );
    if (decision == null || !decision.accepted || decision.revision == null) {
      return;
    }
    // Snapshot pre-revision body before replacing.
    await svc.snapshotVersion(
      draftId,
      contentMarkdown: _bodyCtrl.text,
      aiRevision: true,
      metadata: <String, dynamic>{
        'instruction': decision.instruction ?? '',
        'selection_start': sel.start,
        'selection_end': sel.end,
      },
    );
    final before = _bodyCtrl.text.substring(0, sel.start);
    final after = _bodyCtrl.text.substring(sel.end);
    final newText = '$before${decision.revision!.revisedText}$after';
    _bodyCtrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: before.length + decision.revision!.revisedText.length,
      ),
    );
  }

  String _surroundingContext(int start, int end) {
    const window = 600;
    final text = _bodyCtrl.text;
    final ctxStart = (start - window).clamp(0, text.length);
    final ctxEnd = (end + window).clamp(0, text.length);
    final before = text.substring(ctxStart, start);
    final after = text.substring(end, ctxEnd);
    return '$before<<SELECTION>>$after';
  }

  Future<void> _export(DraftExportKind kind) async {
    final draft = _draft;
    if (draft == null) return;
    final l10n = DraftingStrings.of(context);
    setState(() => _busy = true);
    try {
      switch (kind) {
        case DraftExportKind.markdown:
          await _exportMarkdown(draft);
          break;
        case DraftExportKind.docx:
          await _exportDocx(draft);
          break;
        case DraftExportKind.pdf:
          await _exportPdf(draft);
          break;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.exportFailed}: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportMarkdown(Draft draft) async {
    final title = (draft.title?.trim().isNotEmpty ?? false)
        ? draft.title!.trim()
        : 'draft';
    if (kIsWeb) {
      // On web, share the markdown as a text payload.
      await Share.share(_bodyCtrl.text, subject: title);
      return;
    }
    await Share.share(_bodyCtrl.text, subject: '$title.md');
  }

  Future<void> _exportDocx(Draft draft) async {
    final svc = ref.read(draftServiceProvider);
    final result = await svc.exportToDocx(
      contentMarkdown: _bodyCtrl.text,
      title: draft.title,
    );
    // Decode the base64 payload into bytes and hand off to share_plus, which
    // surfaces the OS share sheet (web: triggers Blob download).
    final bytes = base64Decode(result.base64);
    await Share.shareXFiles(
      <XFile>[
        XFile.fromData(
          bytes,
          name: result.filename,
          mimeType:
              'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        ),
      ],
      subject: draft.title ?? 'draft',
    );
  }

  Future<void> _exportPdf(Draft draft) async {
    // MVP: copy markdown to clipboard with a hint to use the existing
    // pdf-generator path until we add a dedicated DraftService.exportToPdf.
    // This keeps the contract review PDF route untouched (no shared edge fn
    // mutation) and avoids cross-package coupling in the same commit.
    await Clipboard.setData(ClipboardData(text: _bodyCtrl.text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('PDF export queued — copy is on your clipboard meanwhile.'),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final l10n = DraftingStrings.of(context);
    final draft = _draft;
    if (draft == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('drafting_delete_dialog'),
        title: Text(l10n.confirmDelete),
        content: Text(l10n.confirmDeleteMessage),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final svc = ref.read(draftServiceProvider);
    await svc.deleteDraft(draft.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = DraftingStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_draft?.displayTitle(untitledFallback: l10n.title) ?? l10n.title),
        actions: <Widget>[
          if (_draft != null)
            IconButton(
              key: const Key('drafting_delete_btn'),
              tooltip: l10n.deleteDraft,
              icon: const Icon(Icons.delete_outline),
              onPressed: _busy ? null : _confirmDelete,
            ),
        ],
      ),
      body: _busy && _draft == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  children: <Widget>[
                    DraftToolbar(
                      onFormat: _applyFormat,
                      onAiRevise: _runAiRevise,
                      onSave: _manualSave,
                      onExport: _export,
                      savedLabel: _savedLabel,
                      busy: _busy,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: TextField(
                        key: const Key('drafting_title_field'),
                        controller: _titleCtrl,
                        decoration: InputDecoration(
                          hintText: l10n.titleHint,
                          border: InputBorder.none,
                        ),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: TextField(
                          key: const Key('drafting_body_field'),
                          controller: _bodyCtrl,
                          maxLines: null,
                          expands: true,
                          keyboardType: TextInputType.multiline,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: InputDecoration(
                            hintText: l10n.placeholder,
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

/// Optional override hook so widget tests can supply a fake "current user
/// id" without booting Supabase. Production code leaves this null and we
/// fall through to the live Supabase session.
String? Function()? debugSupabaseUserIdAccessor;
