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
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/assistant_tools.dart';
import '../../drafts/screens/draft_viewer_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _future = _loadDraft();
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
    return _DraftPayload(
      title: (draftSubject?.isNotEmpty == true ? draftSubject! : subject) ?? '',
      content: (draftBody?.isNotEmpty == true ? draftBody! : brief) ?? '',
    );
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
        return DraftViewerScreen(
          // Existing DraftViewerScreen accepts caseId; route the inbox
          // edit flow through a synthetic case id when none is attached
          // to the thread (rare but possible — triage can run before the
          // case heuristic resolves).
          caseId: widget.caseId ?? 'inbox',
          draftTitle: payload.title,
          draftContent: payload.content,
          draftType: 'email',
        );
      },
    );
  }
}

class _DraftPayload {
  const _DraftPayload({required this.title, required this.content});
  final String title;
  final String content;
}
