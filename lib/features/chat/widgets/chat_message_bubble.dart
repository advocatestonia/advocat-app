import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../config/theme.dart';
import '../../../services/pdf_service.dart';
import '../screens/chat_screen.dart';
import 'citations/message_citations_footer.dart';
import 'rich_message.dart';

/// A single chat message bubble with copy and action support.
class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    this.onCopy,
    this.onAction,
    this.onDownloadPdf,
  });

  final ChatMessage message;
  final ValueChanged<String>? onCopy;
  final ValueChanged<String>? onAction;

  /// Invoked when the user taps the PDF-download icon. The icon only
  /// appears for AI messages whose content [PdfService.looksLikeDraft]
  /// classifies as a legal-draft output.
  final ValueChanged<ChatMessage>? onDownloadPdf;

  bool get _isUser => message.role == MessageRole.user;
  bool get _isSystem => message.role == MessageRole.system;

  /// Teal accent used for the AI avatar badge.
  static const _kAvatarTeal = Color(0xFF0D9488);

  @override
  Widget build(BuildContext context) {
    if (_isSystem) return _buildSystemMessage(context);

    final bubble = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: _isUser
            ? MediaQuery.of(context).size.width * 0.82
            : MediaQuery.of(context).size.width * 0.82 - 32,
      ),
      child: GestureDetector(
        // fix/copy-selection: translucent hit-test so drag-to-select pan
        // events propagate to SelectableText/SelectionArea underneath
        // (Flutter Web fix — long-press recognizer stays intact).
        behavior: HitTestBehavior.translucent,
        onLongPress: () {
          HapticFeedback.mediumImpact();
          onCopy?.call(message.content);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            color: _isUser ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(AppRadius.lg),
              topRight: const Radius.circular(AppRadius.lg),
              bottomLeft: Radius.circular(
                _isUser ? AppRadius.lg : AppRadius.sm,
              ),
              bottomRight: Radius.circular(
                _isUser ? AppRadius.sm : AppRadius.lg,
              ),
            ),
            border: _isUser ? null : Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isUser)
                SelectableText(
                  message.content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.4,
                  ),
                )
              else
                RichMessage(
                  text: message.content,
                  onActionTap: (label) => onAction?.call(label),
                  citations: message.citations,
                ),
              if (!_isUser &&
                  (message.citations.isNotEmpty ||
                      looksLegalish(message.content)))
                MessageCitationsFooter(
                  citations: message.citations,
                  legalContent: looksLegalish(message.content),
                ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: _isUser
                          ? Colors.white.withValues(alpha: 0.6)
                          : AppColors.textTertiary,
                    ),
                  ),
                  if (!_isUser) ...[
                    const SizedBox(width: 8),
                    const Text(
                      'AI-generated \u2022 Not legal advice',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textTertiary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const Spacer(),
                    // fix/ai-quality: copy icon writes raw content to clipboard
                    // and invokes onCopy callback. Inline with meta row to keep
                    // a minimum-size hit target next to the timestamp.
                    InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Clipboard.setData(
                          ClipboardData(text: message.content),
                        );
                        onCopy?.call(message.content);
                      },
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.copy_rounded,
                          size: 14,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                    // PDF export — appears only on AI messages that look like
                    // a generated legal draft. Tapped → onDownloadPdf callback
                    // (caller decides how to render the bytes — Web download,
                    // share sheet, Supabase upload, …).
                    if (PdfService.looksLikeDraft(message.content))
                      InkWell(
                        key: ValueKey('pdf_download_${message.id}'),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onDownloadPdf?.call(message);
                        },
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.picture_as_pdf,
                            size: 14,
                            color: AppColors.textTertiary,
                            semanticLabel: 'Download as PDF',
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Align(
        alignment: _isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: _isUser
            ? bubble
            : Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // AI avatar — teal shield icon
                  Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: _kAvatarTeal.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      size: 14,
                      color: _kAvatarTeal,
                    ),
                  ),
                  Flexible(child: bubble),
                ],
              ),
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(
          begin: 0.1,
          end: 0,
          duration: 250.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildSystemMessage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            message.content,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.error,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}
