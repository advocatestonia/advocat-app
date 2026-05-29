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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../l10n/app_localizations.dart';
// WAVE 2 FIX W2-03 (F3): privileged drafts in progress.
import '../../../shared/secure_screen.dart';
import '../models/draft_model.dart';
import '../services/draft_service.dart';
import '../widgets/ai_revision_dialog.dart';
import '../widgets/draft_toolbar.dart';
import 'draft_versions_screen.dart';

/// Loads + edits a single draft. The route can be opened either by id
/// (existing draft) or via a `prefill` payload (e.g. from Contract Review).
class DraftingStudioScreen extends ConsumerStatefulWidget {
  const DraftingStudioScreen({
    super.key,
    this.draftId,
    this.prefill,
    this.source,
  });

  /// Existing draft id. If null, [prefill] must be set so we can create
  /// a fresh row on first save.
  final String? draftId;

  /// Optional pre-fill payload (e.g. from "Draft a reply" in Contract Review).
  final DraftPrefill? prefill;

  /// Free-form provenance marker matching the `?source=` query param on the
  /// route. The known value `vault_note` switches the editor into Vault-Note
  /// mode (auto-saveToVault on first save, "Note: " title prefix, chip in
  /// the toolbar header).
  final String? source;

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

  // ─── Drafting × Vault state ────────────────────────────────────────────
  /// True when the editor was opened from the Vault "Create Note" CTA.
  /// Drives the toolbar chip + the auto-saveToVault on first save.
  bool _vaultNoteMode = false;

  /// True iff the very next first-save should auto-file into the Vault.
  /// Flipped off after the auto-save completes so subsequent saves are
  /// not duplicated unless the user clicks "Save to Vault" again.
  bool _pendingAutoSaveToVault = false;

  /// Live toolbar state. The button cycles idle → saving → saved → idle.
  bool _savingToVault = false;
  bool _savedToVaultFlash = false;

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
      // ── Drafting × Vault: detect vault-note mode early so we can amend
      //    the prefill (title prefix) and remember to auto-file on first
      //    save. We check both the explicit query string and the prefill
      //    source-type so either entry point works.
      final isVaultNote = widget.source == 'vault_note' ||
          widget.prefill?.sourceType == DraftSourceType.vaultNote;

      Draft? draft;
      if (widget.draftId != null) {
        draft = await svc.fetchById(widget.draftId!);
        // Existing draft was already created from a vault note? Reflect
        // that in the toolbar chip but don't re-trigger the auto-save.
        if (draft?.sourceType == DraftSourceType.vaultNote) {
          _vaultNoteMode = true;
        }
      }
      if (draft == null) {
        // Either no id, or fetch returned null (deleted / cross-user).
        final prefill = widget.prefill;
        if (prefill == null && !isVaultNote) {
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

        // Compose the prefill with vault-note overrides where needed.
        final effectivePrefill = prefill ??
            const DraftPrefill(
              title: '',
              contentMarkdown: '',
              sourceType: DraftSourceType.vaultNote,
            );
        // We've already checked `mounted` above (session non-null implies
        // the screen is mounted); read DraftingStrings before the next
        // async hop so the lints stay happy.
        if (!mounted) return;
        final notePrefix = AppLocalizations.of(context)!.vaultNoteTitlePrefix;
        final effectiveTitle = isVaultNote
            ? (effectivePrefill.title.startsWith(notePrefix)
                ? effectivePrefill.title
                : '$notePrefix${effectivePrefill.title}'.trim())
            : effectivePrefill.title;
        final effectiveSourceType =
            isVaultNote ? DraftSourceType.vaultNote : effectivePrefill.sourceType;

        draft = await svc.createDraft(
          userId: session,
          caseId: effectivePrefill.caseId,
          sourceType: effectiveSourceType,
          sourceId: effectivePrefill.sourceId,
          title: effectiveTitle.isEmpty ? null : effectiveTitle,
          contentMarkdown: effectivePrefill.contentMarkdown,
          language: effectivePrefill.language,
        );

        if (isVaultNote) {
          _vaultNoteMode = true;
          _pendingAutoSaveToVault = true;
        }
      }
      // Tear down any previous controller / listeners — `_loadOrCreate` can
      // be re-entered after a version restore.
      _autosave?.dispose();
      _bodyCtrl.removeListener(_onChanged);
      _titleCtrl.removeListener(_onChanged);
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
        _savedLabel = AppLocalizations.of(context)!.draftingSaved;
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
        _savedLabel = AppLocalizations.of(context)!.draftingSavedJustNow;
      });
      // Drafting × Vault — first save of a vault-note auto-files into the
      // Vault so the round-trip from the Vault "Create Note" CTA is
      // seamless. We flip the pending flag off so subsequent saves are
      // ordinary autosaves until the user clicks "Save to Vault" again.
      if (_pendingAutoSaveToVault) {
        _pendingAutoSaveToVault = false;
        // `silent: true` — no snackbar; the toolbar button's check tick
        // is enough cue at this stage.
        // Don't `await` — let the autosave UI settle before the spinner.
        // Errors fall back to the standard saveToVaultFailed snackbar
        // path inside _saveToVault.
        // ignore: unawaited_futures
        _saveToVault(silent: true);
      }
    } catch (e, st) {
      debugPrint('[drafting_studio] manualSave failed: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.draftingSaveFailed)),
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
    final l10n = AppLocalizations.of(context)!;
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
        SnackBar(content: Text('${l10n.draftingExportFailed}: $e')),
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
    // Track 1A — real server-side PDF via Typst worker (mirrors _exportDocx).
    // The DraftService surfaces a StateError when the Typst worker is not
    // configured in this environment (HTTP 503 worker_not_configured); we
    // catch that here and show a clear "unavailable" message instead of a
    // generic "export failed". The DOCX path remains the fallback.
    final l10n = AppLocalizations.of(context)!;
    final svc = ref.read(draftServiceProvider);
    try {
      final result = await svc.exportToPdf(
        contentMarkdown: _bodyCtrl.text,
        title: draft.title,
      );
      final bytes = base64Decode(result.base64);
      await Share.shareXFiles(
        <XFile>[
          XFile.fromData(bytes, name: result.filename, mimeType: result.mime),
        ],
        subject: draft.title ?? 'draft',
      );
    } on StateError catch (e) {
      if (!mounted) return;
      final unavailable = e.message.contains('worker_not_configured');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            unavailable ? l10n.pdfWorkerUnavailable : '${l10n.draftingExportFailed}: ${e.message}',
          ),
        ),
      );
    }
  }

  /// Drafting × Vault — file the current draft into the encrypted Vault.
  /// Flushes any pending autosave first so the Vault gets the latest body,
  /// then drives the toolbar through saving → saved → idle. On success we
  /// surface a snackbar with an "Open in Vault" action that deep-links to
  /// the vault screen for the newly-created document.
  Future<void> _saveToVault({bool silent = false}) async {
    final draft = _draft;
    if (draft == null) return;
    final l10n = AppLocalizations.of(context)!;
    final svc = ref.read(draftServiceProvider);
    setState(() => _savingToVault = true);
    try {
      await _autosave?.flush();
      final vaultDocId = await svc.saveToVault(draft.id);
      // Refresh local copy so the toolbar can tell "already filed".
      _draft = _draft?.copyWith(vaultCopyId: vaultDocId);
      if (!mounted) return;
      setState(() {
        _savingToVault = false;
        _savedToVaultFlash = true;
      });
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.savedToVault),
            action: SnackBarAction(
              label: l10n.openInVault,
              onPressed: () {
                // Navigate to the vault. Deep-linking to the specific doc
                // is up to the Vault agent's route; until that lands we
                // push the list which will surface the new "Draft"-tagged
                // row at the top (sorted by created_at desc).
                Navigator.of(context).pushNamed('/vault');
              },
            ),
          ),
        );
      }
      // One-shot reset of the success check after a short cue.
      Future<void>.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _savedToVaultFlash = false);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _savingToVault = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.saveToVaultFailed}: $e')),
      );
    }
  }

  /// Pushes the Version History screen. On restore (pop with `true`), we
  /// flush autosave and re-load the draft so the editor reflects the
  /// restored body.
  Future<void> _openVersionHistory() async {
    final draft = _draft;
    if (draft == null) return;
    // Flush any pending changes so the snapshot list reflects the truth.
    await _autosave?.flush();
    if (!mounted) return;
    final restored = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => DraftVersionsScreen(draftId: draft.id),
      ),
    );
    if (restored == true) {
      // Reload the editor body from server.
      await _loadOrCreate();
    }
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context)!;
    final draft = _draft;
    if (draft == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('drafting_delete_dialog'),
        title: Text(l10n.draftingConfirmDelete),
        content: Text(l10n.draftingConfirmDeleteMessage),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.draftingCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.draftingConfirm),
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
    final l10n = AppLocalizations.of(context)!;
    return SecureScreenScope(
      child: Scaffold(
      appBar: AppBar(
        title: Text(_draft?.displayTitle(untitledFallback: l10n.draftingTitle) ?? l10n.draftingTitle),
        actions: <Widget>[
          if (_draft != null)
            IconButton(
              key: const Key('drafting_history_btn'),
              tooltip: l10n.draftingVersionHistory,
              icon: const Icon(Icons.history),
              onPressed: _busy ? null : _openVersionHistory,
            ),
          if (_draft != null)
            IconButton(
              key: const Key('drafting_delete_btn'),
              tooltip: l10n.draftingDeleteDraft,
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
                      onSaveToVault:
                          _draft == null ? null : () => _saveToVault(),
                      savedLabel: _savedLabel,
                      busy: _busy,
                      savingToVault: _savingToVault,
                      savedToVault: _savedToVaultFlash,
                      vaultNoteMode: _vaultNoteMode,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: TextField(
                        key: const Key('drafting_title_field'),
                        controller: _titleCtrl,
                        decoration: InputDecoration(
                          hintText: l10n.draftingTitleHint,
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
                            hintText: l10n.draftingPlaceholder,
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}

/// Optional override hook so widget tests can supply a fake "current user
/// id" without booting Supabase. Production code leaves this null and we
/// fall through to the live Supabase session.
String? Function()? debugSupabaseUserIdAccessor;
