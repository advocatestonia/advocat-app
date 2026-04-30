// feedback_buttons.dart
//
// Two small thumb icons rendered under every AI message bubble. Idle state
// is grey, hover/active turns green (👍) or red (👎). Clicking 👎 opens a
// minimal comment dialog. Clicking the same icon while it is active
// clears the rating (toggle off).
//
// The widget is deliberately decoupled from Supabase / Riverpod — the
// caller passes an [onSubmit] callback. This keeps unit tests fast (no
// network, no DI graph) and lets the parent decide where state lives.
//
// State semantics (rating value):
//    null  → no opinion
//     1    → thumbs up
//    -1    → thumbs down
//
// onSubmit is invoked with (newRating, comment). newRating may be null
// when the user is clearing an existing rating.

import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../l10n/app_localizations.dart';

/// Signature: (newRating, optional comment) -> Future<void>.
typedef FeedbackSubmit = Future<void> Function(int? rating, String? comment);

class FeedbackButtons extends StatefulWidget {
  const FeedbackButtons({
    super.key,
    required this.messageId,
    required this.onSubmit,
    this.initialRating,
  });

  final String messageId;
  final int? initialRating;
  final FeedbackSubmit onSubmit;

  @override
  State<FeedbackButtons> createState() => _FeedbackButtonsState();
}

class _FeedbackButtonsState extends State<FeedbackButtons> {
  int? _rating;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  @override
  void didUpdateWidget(covariant FeedbackButtons oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the parent re-fetched a stored rating, sync it into local state.
    if (oldWidget.initialRating != widget.initialRating &&
        widget.initialRating != _rating) {
      _rating = widget.initialRating;
    }
  }

  Future<void> _onTapUp() async {
    if (_busy) return;
    final newRating = _rating == 1 ? null : 1;
    setState(() {
      _rating = newRating;
      _busy = true;
    });
    try {
      await widget.onSubmit(newRating, null);
    } catch (_) {
      // On failure, revert local state so the icon doesn't lie.
      if (mounted) setState(() => _rating = widget.initialRating);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onTapDown() async {
    if (_busy) return;
    if (_rating == -1) {
      // Already down — toggle off without prompting.
      setState(() {
        _rating = null;
        _busy = true;
      });
      try {
        await widget.onSubmit(null, null);
      } catch (_) {
        if (mounted) setState(() => _rating = widget.initialRating);
      } finally {
        if (mounted) setState(() => _busy = false);
      }
      return;
    }

    final comment = await _showCommentDialog();
    if (comment == null) return; // user cancelled
    setState(() {
      _rating = -1;
      _busy = true;
    });
    try {
      // Treat empty input as "no comment" — no point storing a blank
      // string on a 👎 with no explanation.
      final trimmed = comment.trim();
      await widget.onSubmit(-1, trimmed.isEmpty ? null : trimmed);
    } catch (_) {
      if (mounted) setState(() => _rating = widget.initialRating);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Returns the entered comment, or null if cancelled.
  Future<String?> _showCommentDialog() async {
    final l = AppLocalizations.of(context);
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(
              labelText: l?.feedbackCommentPrompt ?? 'What was wrong?',
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l?.feedbackCancel ?? 'Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text),
              child: Text(l?.feedbackSend ?? 'Send'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final upActive = _rating == 1;
    final downActive = _rating == -1;

    final upColor = upActive ? AppColors.success : AppColors.textTertiary;
    final downColor = downActive ? AppColors.error : AppColors.textTertiary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: l?.feedbackThumbsUpLabel ?? 'Helpful',
          child: InkWell(
            onTap: _onTapUp,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                upActive ? Icons.thumb_up : Icons.thumb_up_outlined,
                size: 14,
                color: upColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Tooltip(
          message: l?.feedbackThumbsDownLabel ?? 'Not helpful',
          child: InkWell(
            onTap: _onTapDown,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                downActive ? Icons.thumb_down : Icons.thumb_down_outlined,
                size: 14,
                color: downColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
