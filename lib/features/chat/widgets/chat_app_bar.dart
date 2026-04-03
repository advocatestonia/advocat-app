import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';

/// Custom app bar for the chat screen.
class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ChatAppBar({
    super.key,
    this.caseName,
    this.isTyping = false,
    this.ttsEnabled = true,
    this.onShareSummary,
    this.onToggleTts,
    this.onAttach,
  });

  final String? caseName;
  final bool isTyping;
  final bool ttsEnabled;
  final VoidCallback? onShareSummary;
  final VoidCallback? onToggleTts;
  final VoidCallback? onAttach;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            caseName ?? 'AI Legal Assistant',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (isTyping)
            const Text(
              'typing...',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.accent,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
      actions: [
        if (onToggleTts != null)
          IconButton(
            icon: Icon(
              ttsEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              size: 22,
            ),
            tooltip: ttsEnabled ? 'Mute voice' : 'Enable voice',
            onPressed: onToggleTts,
          ),
        if (onAttach != null)
          IconButton(
            icon: const Icon(Icons.attach_file_rounded, size: 22),
            tooltip: 'Attach document',
            onPressed: onAttach,
          ),
        if (onShareSummary != null)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, size: 22),
            onSelected: (value) {
              if (value == 'share') onShareSummary?.call();
            },
            itemBuilder: (context) {
              final l10n = AppLocalizations.of(context);
              return [
                PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      const Icon(Icons.copy_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(l10n?.copySummary ?? 'Copy summary'),
                    ],
                  ),
                ),
              ];
            },
          ),
      ],
    );
  }
}
