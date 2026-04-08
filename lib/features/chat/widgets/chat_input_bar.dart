import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import 'voice_button.dart';

/// Bottom input bar for the chat screen with text field, send, voice and attach.
class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.messageController,
    required this.focusNode,
    required this.isSending,
    required this.voiceState,
    required this.voiceInitialized,
    required this.partialSpeech,
    required this.onSend,
    required this.onVoiceTap,
    this.onAttach,
  });

  final TextEditingController messageController;
  final FocusNode focusNode;
  final bool isSending;
  final VoiceButtonState voiceState;
  final bool voiceInitialized;
  final String partialSpeech;
  final VoidCallback onSend;
  final VoidCallback onVoiceTap;
  final VoidCallback? onAttach;

  @override
  Widget build(BuildContext context) {
    final isListening = voiceState == VoiceButtonState.listening;

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.sm,
        top: AppSpacing.sm,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Partial speech text
          if (isListening && partialSpeech.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                partialSpeech,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Attach button
              if (onAttach != null)
                IconButton(
                  icon: const Icon(Icons.attach_file_rounded, size: 22),
                  color: AppColors.textTertiary,
                  onPressed: isSending ? null : onAttach,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),

              // Text field
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: messageController,
                    focusNode: focusNode,
                    maxLines: 5,
                    minLines: 1,
                    enabled: !isSending,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)?.typeMessage ?? 'Type a message...',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ),

              const SizedBox(width: 4),

              // Voice button (compact)
              if (voiceInitialized)
                SizedBox(
                  width: 40,
                  height: 40,
                  child: IconButton(
                    icon: Icon(
                      isListening ? Icons.stop_rounded : Icons.mic_rounded,
                      color: isListening ? AppColors.error : AppColors.textTertiary,
                      size: 22,
                    ),
                    onPressed: isSending ? null : onVoiceTap,
                    padding: EdgeInsets.zero,
                  ),
                ),

              // Send button
              SizedBox(
                width: 40,
                height: 40,
                child: IconButton(
                  icon: isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: AppColors.accent,
                          size: 22,
                        ),
                  onPressed: isSending ? null : onSend,
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
