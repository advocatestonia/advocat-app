// share_result_button.dart
// ---------------------------------------------------------------------------
// Tiny "Share this analysis" icon button. Lives in the action row of
// completed AI replies / Contract Review results.
//
// Behaviour:
//   1. Tap → loading spinner replaces the icon.
//   2. Call ShareResultService.createShare(sourceType, sourceId).
//   3. On success → open the native share sheet via share_plus with the
//      generated /s/<slug> URL.
//   4. On failure → SnackBar with a localised-enough error message.
//
// The button is intentionally low-key (small icon, no label) so the action
// row stays tidy. We rely on the system share sheet to do the heavy lifting
// for copy / WhatsApp / iMessage / Twitter etc.
// ---------------------------------------------------------------------------

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// share_plus exports its own `ShareResult` — hide it so our (richer) class
// name remains canonical inside this widget. We only call Share.share() so
// the platform-side return type is not needed here.
import 'package:share_plus/share_plus.dart' hide ShareResult;

import '../../../config/theme.dart';
import '../../../services/share_result_service.dart';

/// Action button rendered next to "copy" and "download PDF" in the AI
/// message action row. Hidden when [sourceId] is empty (e.g. mid-stream).
class ShareResultButton extends ConsumerStatefulWidget {
  const ShareResultButton({
    super.key,
    required this.sourceType,
    required this.sourceId,
    this.size = 14,
    this.color,
    this.onShared,
  });

  /// Which kind of source this button shares.
  final ShareSourceType sourceType;

  /// UUID of the row in the source table (contract_reviews,
  /// case_messages, or case_deadlines). Empty disables the button.
  final String sourceId;

  /// Icon size — defaults to 14 to match the existing copy/PDF icons.
  final double size;

  /// Optional color override. Defaults to AppColors.textTertiary so the
  /// button visually matches its siblings.
  final Color? color;

  /// Optional callback invoked AFTER the share-result API call succeeds
  /// but BEFORE the native share sheet opens. Tests use this to assert
  /// the call happened without having to mock share_plus.
  final ValueChanged<ShareResult>? onShared;

  @override
  ConsumerState<ShareResultButton> createState() => _ShareResultButtonState();
}

class _ShareResultButtonState extends ConsumerState<ShareResultButton> {
  bool _busy = false;

  Future<void> _onTap() async {
    if (_busy) return;
    if (widget.sourceId.isEmpty) return;
    unawaited(HapticFeedback.selectionClick());

    setState(() => _busy = true);
    try {
      final svc = ref.read(shareResultServiceProvider);
      final res = await svc.createShare(
        sourceType: widget.sourceType,
        sourceId: widget.sourceId,
      );
      if (!mounted) return;
      if (res.success && res.share != null) {
        widget.onShared?.call(res.share!);
        await _openShareSheet(res.share!);
      } else {
        _showError(res.errorReason);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openShareSheet(ShareResult share) async {
    // Compose a friendly message — the URL is the payload, the copy is
    // the social hook. `share_plus` lets the user pick the channel.
    final text = [
      if (share.insightSummary.isNotEmpty) share.insightSummary,
      share.shareUrl,
    ].join('\n\n');

    await Share.share(
      text,
      subject: share.title.isEmpty ? 'Advocat — AI legal analysis' : share.title,
    );
  }

  void _showError(String? reason) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final msg = _localiseError(reason);
    messenger.showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _localiseError(String? reason) {
    switch (reason) {
      case 'not_owner':
        return "Can't share — this analysis belongs to another account.";
      case 'no_source':
        return "Can't share — the original analysis is no longer available.";
      case 'empty_source':
        return "Nothing to share yet.";
      case 'invalid_source_id':
        return "Can't share this message.";
      case 'network':
        return "Network error — try again in a moment.";
      default:
        return "Couldn't create share link. Try again later.";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sourceId.isEmpty) return const SizedBox.shrink();
    final color = widget.color ?? AppColors.textTertiary;
    return Tooltip(
      message: 'Share this analysis',
      child: GestureDetector(
        key: ValueKey('share_button_${widget.sourceId}'),
        onTap: _busy ? null : _onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: widget.size + 8,
          height: widget.size + 8,
          child: Center(
            child: _busy
                ? SizedBox(
                    width: widget.size,
                    height: widget.size,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  )
                : Icon(
                    Icons.ios_share_rounded,
                    size: widget.size,
                    color: color,
                    semanticLabel: 'Share this analysis',
                  ),
          ),
        ),
      ),
    );
  }
}
