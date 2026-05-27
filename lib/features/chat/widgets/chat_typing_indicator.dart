import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../config/theme.dart';

/// Animated typing indicator shown when the AI is generating a response.
class ChatTypingIndicator extends StatelessWidget {
  const ChatTypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppRadius.lg),
              topRight: Radius.circular(AppRadius.lg),
              bottomLeft: Radius.circular(AppRadius.sm),
              bottomRight: Radius.circular(AppRadius.lg),
            ),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Dot(delay: 0.ms),
              const SizedBox(width: 4),
              _Dot(delay: 150.ms),
              const SizedBox(width: 4),
              _Dot(delay: 300.ms),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.delay});

  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(
          begin: 0.6,
          end: 1.0,
          delay: delay,
          duration: 400.ms,
          curve: Curves.easeInOut,
        )
        .then()
        .fadeIn(begin: 0.4);
  }
}
