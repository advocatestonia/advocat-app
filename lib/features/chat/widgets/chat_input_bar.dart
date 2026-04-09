import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
        left: AppSpacing.sm,
        right: AppSpacing.sm,
        top: AppSpacing.sm,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Attach button
          if (onAttach != null)
            SizedBox(
              width: 40,
              height: 44,
              child: IconButton(
                icon: const Icon(Icons.attach_file_rounded, size: 22),
                color: AppColors.textTertiary,
                onPressed: isSending ? null : onAttach,
                padding: EdgeInsets.zero,
              ),
            ),

          if (onAttach != null) const SizedBox(width: 4),

          // Text field — takes most width
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.5),
                ),
              ),
              child: KeyboardListener(
                focusNode: FocusNode(),
                onKeyEvent: (event) {
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.enter &&
                      !HardwareKeyboard.instance.isShiftPressed) {
                    onSend();
                  }
                },
                child: TextField(
                  controller: messageController,
                  focusNode: focusNode,
                  maxLines: 5,
                  minLines: 1,
                  enabled: !isSending,
                  textInputAction: TextInputAction.newline,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)?.typeMessage ??
                        'Type a message...',
                    hintStyle:
                        const TextStyle(color: AppColors.textTertiary),
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
          ),

          const SizedBox(width: 6),

          // Mic + Send buttons — same size, aligned in a row
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mic button — 44x44, circular
              if (voiceInitialized)
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isListening
                        ? AppColors.error.withValues(alpha: 0.12)
                        : AppColors.surfaceVariant,
                    boxShadow: [
                      BoxShadow(
                        color: isListening
                            ? AppColors.error.withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.06),
                        blurRadius: isListening ? 10 : 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: isSending ? null : onVoiceTap,
                    icon: Icon(
                      isListening ? Icons.stop_rounded : Icons.mic_rounded,
                      color: isListening
                          ? AppColors.error
                          : AppColors.textSecondary,
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),

              if (voiceInitialized) const SizedBox(width: 6),

              // Send button — 44x44, circular, accent color
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSending
                      ? AppColors.accent.withValues(alpha: 0.5)
                      : AppColors.accent,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: isSending ? null : onSend,
                  icon: isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 20),
                  color: Colors.white,
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
