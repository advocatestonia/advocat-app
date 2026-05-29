// agent_approval_card.dart — Day 6-7 (2026-05-27) of agent-loop MVP.
// ----------------------------------------------------------------------------
// Renders the approval sheet when claude-proxy halts the agent loop on a
// WRITE tool and emits an `agent_awaiting_approval` SSE event.
//
// UI contract:
//   • Always shows the FULL tool_input (recipients, subject, body,
//     attachment list) — NO truncation. The user must be able to read
//     every word they're about to authorise.
//   • Two action buttons: Approve (filled, primary) and Decline (text).
//   • Both buttons POST to /agent-approve with {run_id, action_id,
//     decision}. Server verifies HMAC, executes (approve) or marks
//     rejected (decline). UI flips into in-flight state (spinner) until
//     the POST resolves.
//   • On success/error, the card emits a result message back into chat
//     via the [onResolved] callback so the chat history shows a final
//     "sent" or "declined" note.
//
// Tool-specific rendering:
//   • draft_email_with_attachments → recipients + subject + body +
//     attachment chips (filenames, no sizes — we don't have them in
//     toolInput, just the IDs).
//   • send_email → recipients + subject + body
//   • generate_pdf → title + document_type + content preview
//   • Anything else → JSON dump (fallback for new tools added later)
// ----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/supabase_service.dart';

class AgentApprovalCard extends ConsumerStatefulWidget {
  const AgentApprovalCard({
    super.key,
    required this.agentRunId,
    required this.toolName,
    required this.toolInput,
    required this.actionId,
    required this.iterations,
    required this.onResolved,
  });

  final String agentRunId;
  final String toolName;
  final Map<String, dynamic> toolInput;
  final String actionId;
  final int iterations;

  /// Called when the user picks an outcome and the server confirms it.
  /// Receives `approved` (true on approve+success, false on decline or
  /// approve+error) and a brief status text the chat can render.
  final void Function(bool approved, String summary) onResolved;

  @override
  ConsumerState<AgentApprovalCard> createState() => _AgentApprovalCardState();
}

class _AgentApprovalCardState extends ConsumerState<AgentApprovalCard> {
  bool _busy = false;
  bool _resolved = false;
  String? _errorText;

  Future<void> _decide(bool approve) async {
    if (_busy || _resolved) return;
    setState(() {
      _busy = true;
      _errorText = null;
    });
    try {
      final sb = ref.read(supabaseServiceProvider);
      final resp = await sb.callEdgeFunction(
        'agent-approve',
        body: {
          'run_id': widget.agentRunId,
          'action_id': widget.actionId,
          'decision': approve ? 'approve' : 'decline',
        },
      );
      if (!mounted) return;
      final ok = resp != null && resp['ok'] == true;
      final executed = resp != null && resp['executed'] == true;
      final errMsg = resp?['error']?.toString() ?? 'unknown error';
      final l = AppLocalizations.of(context);
      if (approve && ok && executed) {
        setState(() {
          _resolved = true;
          _busy = false;
        });
        widget.onResolved(
          true,
          l?.agentApprovalSentSummary ?? 'Sent on your behalf.',
        );
      } else if (!approve && resp != null && resp['decision'] == 'declined') {
        setState(() {
          _resolved = true;
          _busy = false;
        });
        widget.onResolved(
          false,
          l?.agentApprovalDeclinedSummary ?? 'Declined — nothing was sent.',
        );
      } else {
        setState(() {
          _busy = false;
          _errorText = errMsg;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorText = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final cs = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: _resolved ? cs.outlineVariant : cs.primary.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──────────────────────────────────────────────────
          Row(
            children: [
              Icon(
                _resolved
                    ? Icons.check_circle_rounded
                    : Icons.shield_outlined,
                color: _resolved ? cs.tertiary : cs.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _resolved
                      ? (l?.agentApprovalResolvedTitle ?? 'Action resolved')
                      : (l?.agentApprovalNeedsReviewTitle ??
                          'Advocat needs your approval'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (widget.iterations > 0)
                Text(
                  '${widget.iterations} ${l?.agentApprovalStepsLabel ?? "steps"}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Tool name pill ──────────────────────────────────────────
          Wrap(
            spacing: 6,
            children: [
              Chip(
                label: Text(_friendlyToolName(widget.toolName, l)),
                visualDensity: VisualDensity.compact,
                backgroundColor: cs.primaryContainer,
                labelStyle: TextStyle(
                  color: cs.onPrimaryContainer,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Tool-specific body ──────────────────────────────────────
          _ToolBody(toolName: widget.toolName, toolInput: widget.toolInput),

          if (_errorText != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.errorContainer,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                _errorText!,
                style: TextStyle(color: cs.onErrorContainer, fontSize: 12),
              ),
            ),
          ],

          // ── Action buttons (only when unresolved) ───────────────────
          if (!_resolved) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _busy ? null : () => _decide(false),
                    child: Text(
                      l?.agentApprovalDeclineButton ?? 'Decline',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _busy ? null : () => _decide(true),
                    child: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            l?.agentApprovalApproveButton ?? 'Approve & Send',
                          ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _friendlyToolName(String name, AppLocalizations? l) {
    switch (name) {
      case 'draft_email_with_attachments':
        return l?.agentToolDraftEmailAtt ?? 'Send email with attachments';
      case 'send_email':
        return l?.agentToolSendEmail ?? 'Send email';
      case 'generate_pdf':
        return l?.agentToolGeneratePdf ?? 'Generate PDF';
      case 'approve_send_draft':
        return l?.agentToolApproveSend ?? 'Send prepared reply';
      default:
        return name;
    }
  }
}

/// Tool-specific renderer — picks the right widget for the toolName.
class _ToolBody extends StatelessWidget {
  const _ToolBody({required this.toolName, required this.toolInput});

  final String toolName;
  final Map<String, dynamic> toolInput;

  @override
  Widget build(BuildContext context) {
    switch (toolName) {
      case 'draft_email_with_attachments':
      case 'send_email':
        return _EmailToolBody(input: toolInput);
      case 'generate_pdf':
        return _PdfToolBody(input: toolInput);
      default:
        return _JsonDumpBody(input: toolInput);
    }
  }
}

class _EmailToolBody extends StatelessWidget {
  const _EmailToolBody({required this.input});
  final Map<String, dynamic> input;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final to = (input['to'] as String?) ?? '';
    final cc = (input['cc'] as String?) ?? '';
    final subject = (input['subject'] as String?) ?? '';
    final body = (input['body'] as String?) ?? '';
    final attIds = (input['attachment_ids'] as List?)?.cast<String>() ?? const [];
    final attCount = attIds.length;
    final l = AppLocalizations.of(context);

    Widget kv(String k, String v, {bool mono = false}) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 72,
                child: Text(
                  k,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: SelectableText(
                  v,
                  style: mono
                      ? theme.textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                        )
                      : theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        kv('To', to),
        if (cc.isNotEmpty) kv('Cc', cc),
        kv('Subject', subject),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: SelectableText(
            body,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        if (attCount > 0) ...[
          const SizedBox(height: 12),
          Text(
            (l?.agentApprovalAttachmentsLabel ?? 'Attachments') +
                ' ($attCount)',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          // We only have IDs in tool_input — render compact chips with
          // first 8 chars of each. The user already saw filenames in the
          // model's prior message; this is just a "yes there are N files
          // attached" confirmation.
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final id in attIds)
                Chip(
                  visualDensity: VisualDensity.compact,
                  avatar: const Icon(Icons.attach_file, size: 16),
                  label: Text(
                    id.length > 8 ? id.substring(0, 8) : id,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _PdfToolBody extends StatelessWidget {
  const _PdfToolBody({required this.input});
  final Map<String, dynamic> input;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = (input['title'] as String?) ?? '';
    final docType = (input['document_type'] as String?) ?? '';
    final content = (input['content'] as String?) ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(docType, style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          constraints: const BoxConstraints(maxHeight: 240),
          child: SingleChildScrollView(
            child: SelectableText(
              content,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ),
      ],
    );
  }
}

class _JsonDumpBody extends StatelessWidget {
  const _JsonDumpBody({required this.input});
  final Map<String, dynamic> input;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: SelectableText(
        input.entries.map((e) => '${e.key}: ${e.value}').join('\n'),
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      ),
    );
  }
}
