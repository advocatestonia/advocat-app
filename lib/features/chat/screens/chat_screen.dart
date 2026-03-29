import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../services/ai_service.dart';
import '../../../services/demo_data.dart';
import '../../../services/supabase_service.dart';
import '../../../services/voice_service.dart';
import '../widgets/voice_button.dart';

// ---------------------------------------------------------------------------
// Chat message model (local, UI-only)
// ---------------------------------------------------------------------------

enum MessageRole { user, assistant, system }

enum MessageContentType { text, issueCard, draftCard }

class ChatMessage {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final MessageContentType contentType;
  final Map<String, dynamic>? metadata;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.contentType = MessageContentType.text,
    this.metadata,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? DateTime.now().toIso8601String(),
      role: json['role'] == 'user' ? MessageRole.user : MessageRole.assistant,
      content: json['content'] as String? ?? '',
      timestamp: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.caseId, this.caseName});

  final String caseId;
  final String? caseName;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isTyping = false;
  bool _disclaimerExpanded = true;
  // ignore: unused_field
  String? _errorMessage;

  // ── Voice state ──────────────────────────────────────────────────────────
  VoiceButtonState _voiceState = VoiceButtonState.idle;
  String _partialSpeech = '';
  bool _ttsEnabled = true;
  bool _voiceInitialized = false;
  StreamSubscription<String>? _speechSub;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _initVoice();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _speechSub?.cancel();
    super.dispose();
  }

  // ── Voice initialization ─────────────────────────────────────────────────

  Future<void> _initVoice() async {
    final voice = ref.read(voiceServiceProvider);
    final sttOk = await voice.initSpeech();
    await voice.initTTS();
    if (mounted) {
      setState(() => _voiceInitialized = sttOk);
    }
  }

  // ── Voice actions ────────────────────────────────────────────────────────

  void _onVoiceTap() {
    final voice = ref.read(voiceServiceProvider);

    switch (_voiceState) {
      case VoiceButtonState.idle:
        _startVoiceInput();
        break;
      case VoiceButtonState.listening:
        _stopVoiceInput();
        break;
      case VoiceButtonState.speaking:
        voice.stopSpeaking();
        setState(() => _voiceState = VoiceButtonState.idle);
        break;
      case VoiceButtonState.processing:
        // Do nothing while processing
        break;
    }
  }

  void _startVoiceInput() {
    final voice = ref.read(voiceServiceProvider);
    if (!voice.isSttAvailable) return;

    // Determine language from current locale
    final langCode = Localizations.localeOf(context).languageCode;

    setState(() {
      _voiceState = VoiceButtonState.listening;
      _partialSpeech = '';
    });

    final stream = voice.startListening(langCode: langCode);
    _speechSub?.cancel();
    _speechSub = stream.listen(
      (partial) {
        if (mounted) {
          setState(() => _partialSpeech = partial);
        }
      },
      onDone: () {
        // Auto-stop after silence timeout
        if (mounted && _voiceState == VoiceButtonState.listening) {
          _stopVoiceInput();
        }
      },
    );
  }

  Future<void> _stopVoiceInput() async {
    _speechSub?.cancel();
    final voice = ref.read(voiceServiceProvider);
    final finalText = await voice.stopListening();

    if (!mounted) return;

    if (finalText.trim().isEmpty) {
      setState(() {
        _voiceState = VoiceButtonState.idle;
        _partialSpeech = '';
      });
      return;
    }

    setState(() {
      _voiceState = VoiceButtonState.processing;
      _partialSpeech = '';
    });

    await _sendMessage(finalText);

    if (mounted) {
      setState(() {
        _voiceState = VoiceButtonState.idle;
      });
    }
  }

  /// Speak AI response via TTS and show speaking animation.
  Future<void> _speakResponse(String text) async {
    if (!_ttsEnabled) return;

    final voice = ref.read(voiceServiceProvider);
    final langCode = Localizations.localeOf(context).languageCode;

    setState(() => _voiceState = VoiceButtonState.speaking);
    await voice.speak(text, langCode: langCode);

    // Wait for TTS to finish
    // Poll briefly since FlutterTts callbacks update the service internally
    while (voice.isSpeaking) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
    }

    if (mounted) {
      setState(() => _voiceState = VoiceButtonState.idle);
    }
  }

  // ── Data loading ────────────────────────────────────────────────────────

  Future<void> _loadMessages() async {
    try {
      final supabase = ref.read(supabaseServiceProvider);
      final rawMessages = await supabase.getChatMessages(widget.caseId);

      if (mounted) {
        setState(() {
          _messages = rawMessages.map((m) => ChatMessage.fromJson(m)).toList();
          _isLoading = false;
        });
        _scrollToBottom(animated: false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _messages = [];
          _errorMessage = null; // Graceful fallback
        });
      }
    }
  }

  // ── Sending ─────────────────────────────────────────────────────────────

  Future<void> _sendMessage([String? overrideText]) async {
    final text = (overrideText ?? _messageController.text).trim();
    if (text.isEmpty || _isSending) return;

    _messageController.clear();
    HapticFeedback.lightImpact();

    final userMessage = ChatMessage(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      role: MessageRole.user,
      content: text,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isSending = true;
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final isDemo = ref.read(isDemoModeProvider);
      final supabase = ref.read(supabaseServiceProvider);

      await supabase.saveChatMessage(
        caseId: widget.caseId,
        role: 'user',
        content: text,
      );

      String responseText;
      final ai = ref.read(aiServiceProvider);
      if (isDemo && !ai.isUsingRealAI) {
        // Pure demo mode — mock responses
        await Future.delayed(const Duration(milliseconds: 800));
        responseText = _getDemoResponse(text);
      } else {
        // Real AI (direct Claude API) or backend proxy
        final response = await ai.sendChatMessage(
          caseId: widget.caseId,
          message: text,
        );
        responseText = response.message;
      }

      await supabase.saveChatMessage(
        caseId: widget.caseId,
        role: 'assistant',
        content: responseText,
      );

      if (mounted) {
        final aiMessage = ChatMessage(
          id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
          role: MessageRole.assistant,
          content: responseText,
          timestamp: DateTime.now(),
        );
        setState(() {
          _isTyping = false;
          _messages.add(aiMessage);
        });
        _scrollToBottom();

        // Auto-read AI response if TTS is enabled
        if (_ttsEnabled) {
          _speakResponse(responseText);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(
            id: 'error_${DateTime.now().millisecondsSinceEpoch}',
            role: MessageRole.system,
            content: 'Failed to get response. Please try again.',
            timestamp: DateTime.now(),
          ));
        });
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _getDemoResponse(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('analyze') || lower.contains('analysis')) {
      return DemoData.chatResponses['analyze']!;
    }
    if (lower.contains('option') || lower.contains('what can')) {
      return DemoData.chatResponses['options']!;
    }
    if (lower.contains('appeal') || lower.contains('draft')) {
      return DemoData.chatResponses['appeal']!;
    }
    if (lower.contains('deadline') || lower.contains('date')) {
      return DemoData.chatResponses['deadlines']!;
    }
    return DemoData.chatResponses['default']!;
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Disclaimer banner
          _buildDisclaimerBanner(),

          // Messages
          Expanded(child: _buildMessageList()),

          // Quick action chips
          if (!_isSending && _messages.length < 3)
            _buildQuickActions(),

          // Input bar with voice button
          _buildInputBar(),
        ],
      ),
    );
  }

  // ── App bar ─────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      titleSpacing: 0,
      title: Row(
        children: [
          // AI avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accent, AppColors.accentLight],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.balance_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.caseName ?? 'AI Legal Assistant',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Online',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // TTS mute/unmute toggle
        IconButton(
          icon: Icon(
            _ttsEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            color: _ttsEnabled ? AppColors.accent : AppColors.textTertiary,
          ),
          tooltip: _ttsEnabled ? 'Mute voice' : 'Unmute voice',
          onPressed: () {
            setState(() => _ttsEnabled = !_ttsEnabled);
            if (!_ttsEnabled) {
              final voice = ref.read(voiceServiceProvider);
              voice.stopSpeaking();
              if (_voiceState == VoiceButtonState.speaking) {
                setState(() => _voiceState = VoiceButtonState.idle);
              }
            }
            HapticFeedback.selectionClick();
          },
        ),
        IconButton(
          icon: const Icon(Icons.attach_file_rounded),
          tooltip: 'Attach document',
          onPressed: () {
            context.push('/scan?caseId=${widget.caseId}');
          },
        ),
      ],
    );
  }

  // ── Disclaimer banner ───────────────────────────────────────────────────

  Widget _buildDisclaimerBanner() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      color: AppColors.warning.withValues(alpha: 0.08),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () =>
              setState(() => _disclaimerExpanded = !_disclaimerExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: AppColors.warning.withValues(alpha: 0.8),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _disclaimerExpanded
                        ? 'AI assistant -- not legal advice. Always verify with a qualified lawyer.'
                        : 'AI guidance only',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.warning.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  _disclaimerExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: AppColors.warning.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Message list ────────────────────────────────────────────────────────

  Widget _buildMessageList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_messages.isEmpty && !_isTyping) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        // Typing indicator as last item
        if (index == _messages.length && _isTyping) {
          return _buildTypingIndicator();
        }

        final message = _messages[index];
        final showDate = index == 0 ||
            !_isSameDay(
              _messages[index - 1].timestamp,
              message.timestamp,
            );

        return Column(
          children: [
            if (showDate) _buildDateSeparator(message.timestamp),
            _buildMessageBubble(message, index),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accent, AppColors.accentLight],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.balance_rounded,
                size: 36,
                color: Colors.white,
              ),
            )
                .animate()
                .scaleXY(begin: 0.8, end: 1, duration: 500.ms, curve: Curves.elasticOut),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'How can I help with your case?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            )
                .animate()
                .fadeIn(delay: 200.ms, duration: 400.ms),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'I can analyze documents, check deadlines, find legal errors, and help draft appeals.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(delay: 350.ms, duration: 400.ms),
            if (_voiceInitialized) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Tap the microphone to speak',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
              )
                  .animate()
                  .fadeIn(delay: 500.ms, duration: 400.ms),
            ],
          ],
        ),
      ),
    );
  }

  // ── Message bubble ──────────────────────────────────────────────────────

  Widget _buildMessageBubble(ChatMessage message, int index) {
    final isUser = message.role == MessageRole.user;
    final isSystem = message.role == MessageRole.system;

    if (isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message.content,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: AppSpacing.sm,
          left: isUser ? 48 : 0,
          right: isUser ? 0 : 48,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Message bubble
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 4,
              ),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppRadius.lg),
                  topRight: const Radius.circular(AppRadius.lg),
                  bottomLeft:
                      isUser ? const Radius.circular(AppRadius.lg) : const Radius.circular(4),
                  bottomRight:
                      isUser ? const Radius.circular(4) : const Radius.circular(AppRadius.lg),
                ),
                border: isUser
                    ? null
                    : Border.all(color: AppColors.border, width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildMessageContent(message, isUser),
            ),

            // Timestamp
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
              child: Text(
                _formatTime(message.timestamp),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 250.ms)
        .slideY(
          begin: 0.1,
          end: 0,
          duration: 250.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildMessageContent(ChatMessage message, bool isUser) {
    final textColor = isUser ? Colors.white : AppColors.textPrimary;

    // Check if AI message contains legal citations (pattern: section symbol or "laki")
    if (!isUser && _containsLegalCitation(message.content)) {
      return _buildRichAIContent(message.content, textColor);
    }

    return SelectableText(
      message.content,
      style: TextStyle(
        color: textColor,
        fontSize: 15,
        height: 1.45,
      ),
    );
  }

  bool _containsLegalCitation(String text) {
    return text.contains('\u00A7') ||
        text.contains('laki') ||
        text.contains('Act') ||
        text.contains('Section');
  }

  Widget _buildRichAIContent(String content, Color textColor) {
    // Simple parsing: split on newlines for bullet points
    final lines = content.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) return const SizedBox(height: 4);

        // Bullet point
        if (trimmed.startsWith('- ') || trimmed.startsWith('\u2022 ')) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: 8),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Expanded(
                  child: SelectableText(
                    trimmed.replaceFirst(RegExp(r'^[-\u2022]\s*'), ''),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: SelectableText(
            trimmed,
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              height: 1.45,
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Typing indicator ────────────────────────────────────────────────────

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm, right: 80),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 4,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppRadius.lg),
            topRight: Radius.circular(AppRadius.lg),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(AppRadius.lg),
          ),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.textTertiary,
                shape: BoxShape.circle,
              ),
            )
                .animate(
                  onPlay: (c) => c.repeat(),
                )
                .scaleXY(
                  begin: 0.6,
                  end: 1.0,
                  delay: Duration(milliseconds: 200 * i),
                  duration: 600.ms,
                  curve: Curves.easeInOut,
                )
                .then()
                .scaleXY(
                  begin: 1.0,
                  end: 0.6,
                  duration: 600.ms,
                  curve: Curves.easeInOut,
                );
          }),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  // ── Quick action chips ──────────────────────────────────────────────────

  Widget _buildQuickActions() {
    final actions = [
      ('Analyze my case', Icons.analytics_outlined),
      ('What are my options?', Icons.help_outline_rounded),
      ('Draft an appeal', Icons.description_outlined),
      ('Check deadlines', Icons.schedule_rounded),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          children: actions.map((action) {
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ActionChip(
                avatar: Icon(action.$2, size: 16, color: AppColors.accent),
                label: Text(
                  action.$1,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                backgroundColor: AppColors.surface,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                onPressed: () => _sendMessage(action.$1),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Input bar ───────────────────────────────────────────────────────────

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.sm,
        right: AppSpacing.sm,
        top: AppSpacing.sm,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Voice partial text + button (shown when listening)
          if (_voiceState == VoiceButtonState.listening ||
              _voiceState == VoiceButtonState.speaking)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: VoiceButton(
                state: _voiceState,
                partialText: _voiceState == VoiceButtonState.listening
                    ? _partialSpeech
                    : null,
                onTap: _onVoiceTap,
              ),
            ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Attach button
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded),
                color: AppColors.textTertiary,
                onPressed: () {
                  context.push('/scan?caseId=${widget.caseId}');
                },
              ),

              // Text field
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: TextField(
                    controller: _messageController,
                    focusNode: _focusNode,
                    maxLines: 5,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: 'Ask about your case...',
                      hintStyle: const TextStyle(color: AppColors.textTertiary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm + 2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // Voice button (compact, next to send)
              if (_voiceInitialized &&
                  _voiceState != VoiceButtonState.listening &&
                  _voiceState != VoiceButtonState.speaking)
                VoiceButton(
                  state: _voiceState,
                  size: 40,
                  onTap: _onVoiceTap,
                ),

              if (_voiceInitialized) const SizedBox(width: 4),

              // Send button
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: IconButton(
                  onPressed: _isSending ? null : () => _sendMessage(),
                  icon: _isSending
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accent,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Date separator ──────────────────────────────────────────────────────

  Widget _buildDateSeparator(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              _formatDate(date),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Expanded(child: Divider(color: AppColors.border)),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) return 'Today';
    if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    }
    return '${date.day}.${date.month}.${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
