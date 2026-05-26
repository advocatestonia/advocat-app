// inbox_draft_edit_screen.dart
// -----------------------------------------------------------------------------
// Thin wrapper around the existing DraftViewerScreen that fetches the
// persisted draft (email_triage_results.draft_*) by triage_id and forwards
// it to the viewer for inline editing.
//
// We keep this inside lib/features/inbox/ so we do NOT touch the existing
// drafts feature — only the inbox owns the wiring from
// `email_triage_results` to the existing draft UX. Once the user saves
// edits the existing flow can dispatch through send-email exactly like
// before, plus a triage-row update on success.
//
// P1-3 (2026-05-27): inline editor with autosave + dirty-check.
//   * The textarea writes back to a local _DraftBuffer every 5s (or on
//     blur) so an OS back-gesture / app suspension does not lose typed
//     edits. The buffer also flows into approveAndSend(editedBody: ...)
//     when the user taps Send.
//   * Hard char cap at 10,000 with a live counter — anything longer is a
//     sign of misuse (legal replies above ~10k chars almost never make
//     sense over email).
//   * WillPopScope prompts "Discard unsaved edits?" when the buffer is
//     dirty relative to the loaded draft body.
//
// We deliberately render an in-feature editor here instead of routing
// through DraftViewerScreen so the autosave / dirty-check / counter
// concerns stay scoped to the inbox surface and don't leak into the
// general drafts flow used by Pkg 7.
// -----------------------------------------------------------------------------

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/assistant_tools.dart';
import '../providers/inbox_provider.dart';

/// Char cap shared with the counter + the autosave guard.
const int _kInboxEditMaxChars = 10000;

/// Autosave cadence — every 5s the buffer flushes to the in-memory map
/// keyed by triageId so re-entry after a back-nav or app suspension
/// recovers the latest typed text.
const Duration _kInboxEditAutosaveInterval = Duration(seconds: 5);

/// In-memory draft buffer, keyed by triage_id. Survives navigation
/// within the running process but NOT app restart (acceptable for the
/// "user back-gestures by mistake" case the audit flagged; full
/// persistence would need a Hive box or Supabase write and is out of
/// scope for this P1).
class _InboxEditBuffer {
  static final Map<String, String> _bodies = <String, String>{};

  static String? get(String triageId) => _bodies[triageId];
  static void set(String triageId, String body) {
    _bodies[triageId] = body;
  }

  static void clear(String triageId) {
    _bodies.remove(triageId);
  }
}

class InboxDraftEditScreen extends ConsumerStatefulWidget {
  const InboxDraftEditScreen({
    super.key,
    required this.triageId,
    this.threadId,
    this.caseId,
  });

  final String triageId;
  final String? threadId;
  final String? caseId;

  @override
  ConsumerState<InboxDraftEditScreen> createState() =>
      _InboxDraftEditScreenState();
}

class _InboxDraftEditScreenState extends ConsumerState<InboxDraftEditScreen> {
  Future<_DraftPayload?>? _future;

  /// Backing controller for the textarea. Initialised once the draft
  /// payload loads (so it carries the server text or the buffered text,
  /// whichever the user is more likely to want to keep editing).
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  /// Pristine body as loaded from the edge function — `_isDirty` compares
  /// the controller's text against this baseline.
  String _initialBody = '';

  /// Periodic autosave timer — flushes the controller text to the
  /// in-memory buffer every [_kInboxEditAutosaveInterval]. Cancelled on
  /// dispose so a back-navved screen does not keep running it.
  Timer? _autosaveTimer;

  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _future = _loadDraft();
    _focusNode.addListener(_onFocusChange);
  }

  Future<_DraftPayload?> _loadDraft() async {
    if (widget.threadId == null || widget.threadId!.isEmpty) {
      return null;
    }
    final tools = ref.read(assistantToolsProvider);
    final res = await tools.execute('get_thread_triage', {
      'thread_id': widget.threadId!,
    });
    if (!res.success) return null;
    final data = res.data ?? const <String, dynamic>{};
    // P0 (2026-05-27): the edit screen MUST display the outbound draft
    // body (the text that send-email will actually dispatch) — not the
    // user_brief 2-4-sentence summary. Fall back to user_brief only when
    // draft_body is absent (severity=LOW path or pre-2026-05-27 rows).
    final draftBody = data['draft_body'] as String?;
    final brief = data['user_brief'] as String?;
    final draftSubject = data['draft_subject'] as String?;
    final subject = data['subject'] as String?;
    final loadedBody =
        (draftBody?.isNotEmpty == true ? draftBody! : brief) ?? '';
    // If we have a buffered edit from a prior session (back-nav, app
    // suspension), prefer it — that's what the user was typing.
    final buffered = _InboxEditBuffer.get(widget.triageId);
    final body = buffered ?? loadedBody;
    _initialBody = loadedBody;
    _controller.text = body;
    _autosaveTimer ??= Timer.periodic(
      _kInboxEditAutosaveInterval,
      (_) => _flushToBuffer(),
    );
    return _DraftPayload(
      title:
          (draftSubject?.isNotEmpty == true ? draftSubject! : subject) ?? '',
      content: body,
    );
  }

  /// Snapshot the current textarea text into the in-memory buffer so a
  /// back-gesture / OS suspension does not lose typed edits.
  void _flushToBuffer() {
    if (!mounted) return;
    final text = _controller.text;
    if (text == _initialBody) {
      // No user edits relative to the server baseline — keep the buffer
      // empty so the next load uses the freshly-fetched draft body.
      _InboxEditBuffer.clear(widget.triageId);
    } else {
      _InboxEditBuffer.set(widget.triageId, text);
    }
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      // On blur — flush immediately so a user who taps elsewhere does
      // not have to wait for the 5s timer.
      _flushToBuffer();
    }
  }

  bool get _isDirty => _controller.text.trim() != _initialBody.trim();

  /// PopScope `canPop` predicate — when `false` the framework blocks the
  /// pop and routes the attempt through [_onPopInvoked] so we can show
  /// the discard-edits dialog.
  bool get _canPop => !_isDirty || _sending;

  /// PopScope handler — when the buffer is dirty, prompt the user. Uses
  /// the modern PopScope API (Flutter 3.16+) instead of the deprecated
  /// WillPopScope to keep Android's predictive back gesture working.
  Future<void> _onPopInvoked(bool didPop, Object? result) async {
    if (didPop) return; // Already popped (clean state).
    final l = AppLocalizations.of(context);
    final keep = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l?.inboxEditDiscardTitle ?? 'Discard unsaved edits?'),
        content: Text(
          l?.inboxEditDiscardBody ??
              'You have unsaved changes to this draft. Going back will '
                  'discard them.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l?.inboxEditKeepEditing ?? 'Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l?.inboxEditDiscard ?? 'Discard'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (keep == true) {
      // User chose to discard — drop the buffer so a re-entry shows the
      // pristine server draft instead of the discarded edits.
      _InboxEditBuffer.clear(widget.triageId);
      Navigator.of(context).pop();
    }
  }

  Future<void> _onSendNow(_DraftPayload payload) async {
    if (_sending) return;
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(inboxProvider.notifier);

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l?.inboxConfirmSendTitle ?? 'Send the prepared reply?'),
            content: Text(
              l?.inboxConfirmSendBody ??
                  'Advocat will dispatch the AI-prepared reply via your '
                      'connected Gmail.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l?.cancel ?? 'Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(l?.inboxSendButton ?? 'Send'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    setState(() => _sending = true);
    try {
      final editedBody = _isDirty ? _controller.text : null;
      final res = await notifier.approveAndSend(
        widget.triageId,
        editedBody: editedBody,
      );
      if (!mounted) return;
      if (res.success) {
        unawaited(HapticFeedback.lightImpact().catchError((_) {}));
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              res.idempotent
                  ? (l?.inboxAlreadySentToast ?? 'Already sent.')
                  : (l?.inboxSentToast ?? 'Sent.'),
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
        // Server has the dispatched text — drop the local buffer so a
        // re-entry doesn't keep showing the stale edits.
        _InboxEditBuffer.clear(widget.triageId);
        if (widget.threadId != null) {
          notifier.hideAfterAction(widget.threadId!);
        }
        if (mounted) Navigator.of(context).pop();
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              res.errorMessage ??
                  (l?.inboxSendErrorToast ?? 'Could not send the reply.'),
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    // Final flush before tear-down so the buffer carries the latest
    // typed text even when the user navigates away with the system
    // back gesture before the periodic timer fires.
    _flushToBuffer();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FutureBuilder<_DraftPayload?>(
      future: _future,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final payload = snap.data;
        if (payload == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(l?.inboxEditDraft ?? 'Edit draft'),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  l?.inboxDraftLoadError ?? 'Could not load draft.',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        return PopScope(
          canPop: _canPop,
          onPopInvokedWithResult: _onPopInvoked,
          child: _EditScaffold(
            payload: payload,
            controller: _controller,
            focusNode: _focusNode,
            isSending: _sending,
            onSend: () => _onSendNow(payload),
          ),
        );
      },
    );
  }
}

class _EditScaffold extends StatelessWidget {
  const _EditScaffold({
    required this.payload,
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.onSend,
  });

  final _DraftPayload payload;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l?.inboxEditDraft ?? 'Edit draft'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (payload.title.isNotEmpty) ...[
              Text(
                payload.title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  maxLength: _kInboxEditMaxChars,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    height: 1.5,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isCollapsed: true,
                    contentPadding: EdgeInsets.all(AppSpacing.sm),
                    counter: SizedBox.shrink(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _CharCounter(controller: controller),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isSending ? null : onSend,
                icon: isSending
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textOnPrimary,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 16),
                label: Text(l?.inboxSendButton ?? 'Send'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm + 2,
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

/// Live char counter — listens to the controller so the count updates
/// on every keystroke without forcing the whole scaffold to rebuild.
class _CharCounter extends StatefulWidget {
  const _CharCounter({required this.controller});

  final TextEditingController controller;

  @override
  State<_CharCounter> createState() => _CharCounterState();
}

class _CharCounterState extends State<_CharCounter> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final len = widget.controller.text.length;
    final overLimit = len > _kInboxEditMaxChars;
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        '$len / $_kInboxEditMaxChars',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: overLimit ? AppColors.error : AppColors.textTertiary,
        ),
      ),
    );
  }
}

class _DraftPayload {
  const _DraftPayload({required this.title, required this.content});
  final String title;
  final String content;
}
