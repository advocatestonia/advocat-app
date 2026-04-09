import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/ai_service.dart';
import '../../../services/assistant_tools.dart';
import '../../../services/demo_data.dart';
import '../../../services/supabase_service.dart';
import '../../../services/tool_executor.dart';
import '../../../services/voice_service.dart';
import '../widgets/tool_result_card.dart';
import '../widgets/voice_button.dart';

// ---------------------------------------------------------------------------
// Chat message model (local, UI-only)
// ---------------------------------------------------------------------------

enum MessageRole { user, assistant, system, toolResult }

enum MessageContentType { text, issueCard, draftCard, toolCard }

class ChatMessage {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final MessageContentType contentType;
  final Map<String, dynamic>? metadata;
  final bool hasAttachment;

  /// Structured tool result for rendering rich cards in the chat.
  final ToolResult? toolResult;

  /// Deferred navigation to perform after showing this message.
  final ToolNavigation? navigation;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.contentType = MessageContentType.text,
    this.metadata,
    this.hasAttachment = false,
    this.toolResult,
    this.navigation,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? DateTime.now().toIso8601String(),
      role: json['role'] == 'user' ? MessageRole.user : MessageRole.assistant,
      content: json['content'] as String? ?? '',
      timestamp: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      hasAttachment: json['has_attachment'] as bool? ?? false,
    );
  }
}

// ---------------------------------------------------------------------------
// Chat context phase — determines which quick action chips to show
// ---------------------------------------------------------------------------

enum _ChatPhase { newCase, afterScan, afterAnalysis }

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
  _ChatPhase _chatPhase = _ChatPhase.newCase;
  int _issuesFound = 0;

  // -- Voice state --
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

  // -- Voice initialization --

  Future<void> _initVoice() async {
    final voice = ref.read(voiceServiceProvider);
    final sttOk = await voice.initSpeech();
    await voice.initTTS();
    if (mounted) {
      setState(() => _voiceInitialized = sttOk);
    }
  }

  // -- Voice actions --

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
        break;
    }
  }

  void _startVoiceInput() {
    final voice = ref.read(voiceServiceProvider);
    if (!voice.isSttAvailable) return;

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

  Future<void> _speakResponse(String text) async {
    if (!_ttsEnabled) return;

    final voice = ref.read(voiceServiceProvider);
    final langCode = Localizations.localeOf(context).languageCode;

    setState(() => _voiceState = VoiceButtonState.speaking);
    await voice.speak(text, langCode: langCode);

    while (voice.isSpeaking) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
    }

    if (mounted) {
      setState(() => _voiceState = VoiceButtonState.idle);
    }
  }

  // -- Data loading --

  Future<void> _loadMessages() async {
    try {
      final supabase = ref.read(supabaseServiceProvider);
      final rawMessages = await supabase.getChatMessages(widget.caseId);

      if (mounted) {
        setState(() {
          _messages =
              rawMessages.map((m) => ChatMessage.fromJson(m)).toList();
          _isLoading = false;
        });

        // If no messages exist, this is a new case -- send welcome
        if (_messages.isEmpty) {
          _sendWelcomeMessage();
        } else {
          _updateChatPhase();
        }

        _scrollToBottom(animated: false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _messages = [];
        });
        _sendWelcomeMessage();
      }
    }
  }

  void _sendWelcomeMessage() {
    final l10n = AppLocalizations.of(context);
    final welcome = ChatMessage(
      id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
      role: MessageRole.assistant,
      content: l10n?.chatWelcomeMessage ??
          'Hello! I am your legal assistant. Tell me what happened — I will analyze the situation and suggest what to do.',
      timestamp: DateTime.now(),
    );
    setState(() {
      _messages.add(welcome);
      _chatPhase = _ChatPhase.newCase;
    });
    _scrollToBottom();
  }

  void _updateChatPhase() {
    final allText =
        _messages.map((m) => m.content.toLowerCase()).join(' ');

    if (allText.contains('ошибк') ||
        allText.contains('нарушен') ||
        allText.contains('error') ||
        allText.contains('issue') ||
        allText.contains('found')) {
      _chatPhase = _ChatPhase.afterAnalysis;
      // Count issues heuristic
      final issueMatches =
          RegExp(r'[🔴🟡🔵]|critical|важн|ошибк').allMatches(allText);
      _issuesFound = issueMatches.length.clamp(0, 10);
    } else if (allText.contains('документ') ||
        allText.contains('сканир') ||
        allText.contains('решение') ||
        allText.contains('document') ||
        allText.contains('scan')) {
      _chatPhase = _ChatPhase.afterScan;
    } else {
      _chatPhase = _ChatPhase.newCase;
    }
  }

  // -- Sending --

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

      // Check if the message maps to a tool call (intent detection)
      final toolCall = _detectToolIntent(text);

      if (toolCall != null) {
        // Execute tool directly and show rich result
        await _executeToolCall(toolCall.$1, toolCall.$2, supabase);
      } else {
        // Normal AI response flow
        String responseText;
        final ai = ref.read(aiServiceProvider);
        if (isDemo && !ai.isUsingRealAI) {
          await Future.delayed(const Duration(milliseconds: 800));
          responseText = _getDemoResponse(text);
        } else {
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
          _updateChatPhase();
          _scrollToBottom();

          if (_ttsEnabled) {
            _speakResponse(responseText);
          }
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

  // -- Tool intent detection --

  /// Detect if the user message maps to a known tool call.
  ///
  /// Returns a tuple of (toolName, params) or null if no tool matches.
  (String, Map<String, dynamic>)? _detectToolIntent(String message) {
    final lower = message.toLowerCase();

    // Check company: "check company X", "check firm X", "проверь фирму X"
    final companyMatch = RegExp(
      r'(?:check|проверь?|проверить|проверка|найти|узнай)\s+(?:company|firm|фирму?|компанию?|работодател[яь]?|employer)\s+(.+)',
      caseSensitive: false,
    ).firstMatch(lower);
    if (companyMatch != null) {
      return ('check_company', {'company_name': companyMatch.group(1)!.trim()});
    }

    // Check vehicle: "check plate ABC123", "проверь авто ABC123"
    final vehicleMatch = RegExp(
      r'(?:check|проверь?|проверить|проверка)\s+(?:vehicle|car|plate|авто|машину?|номер)\s+([A-Za-z0-9\- ]+)',
      caseSensitive: false,
    ).firstMatch(lower);
    if (vehicleMatch != null) {
      return ('check_vehicle', {'plate_number': vehicleMatch.group(1)!.trim().toUpperCase()});
    }

    // Create case: "create case", "создай дело", "new case"
    if (RegExp(r'(?:create|open|new|создай|открой|новое)\s+(?:case|дело|кейс)', caseSensitive: false).hasMatch(lower)) {
      final titleMatch = RegExp(r'(?:titled?|named?|с названием)\s+(.+)', caseSensitive: false).firstMatch(lower);
      return ('create_case', {
        'title': titleMatch?.group(1)?.trim() ?? 'New Case',
        'case_type': 'other',
      });
    }

    // Get deadlines: "show deadlines", "мои дедлайны", "сроки"
    if (RegExp(r'(?:show|get|check|list|мои|покажи|проверь)\s*(?:deadline|дедлайн|срок|дат)', caseSensitive: false).hasMatch(lower) ||
        lower == 'deadlines' || lower == 'дедлайны' || lower == 'сроки') {
      return ('get_deadlines', {'case_id': widget.caseId});
    }

    // Find lawyer: "find lawyer", "найти адвоката"
    if (RegExp(r'(?:find|search|найти|ищу|подскажи)\s*(?:lawyer|attorney|адвокат|юрист)', caseSensitive: false).hasMatch(lower)) {
      return ('find_lawyer', {'country': 'finland'});
    }

    // Change language: "switch to english", "переключи на финский"
    final langMatch = RegExp(
      r'(?:change|switch|set|переключи|смени|язык)\s+(?:to|на|language)?\s*(english|finnish|russian|german|estonian|suomi|русский|немецкий|эстонский)',
      caseSensitive: false,
    ).firstMatch(lower);
    if (langMatch != null) {
      final langMap = {
        'english': 'en', 'finnish': 'fi', 'suomi': 'fi',
        'russian': 'ru', 'русский': 'ru',
        'german': 'de', 'немецкий': 'de',
        'estonian': 'et', 'эстонский': 'et',
      };
      final lang = langMap[langMatch.group(1)!.toLowerCase()] ?? 'en';
      return ('change_language', {'language': lang});
    }

    // Case status: "case status", "статус дела"
    if (RegExp(r'(?:case|дело)\s*(?:status|статус)', caseSensitive: false).hasMatch(lower) ||
        RegExp(r'(?:status|статус)\s*(?:case|дело|кейс)', caseSensitive: false).hasMatch(lower)) {
      return ('get_case_status', {'case_id': widget.caseId});
    }

    // Translate: "translate ... to ..."
    final translateMatch = RegExp(
      r'(?:translate|переведи|перевод)\s+(.+?)\s+(?:to|на)\s+(english|finnish|russian|german|en|fi|ru|de)',
      caseSensitive: false,
    ).firstMatch(lower);
    if (translateMatch != null) {
      final langMap = {
        'english': 'en', 'finnish': 'fi', 'russian': 'ru', 'german': 'de',
        'en': 'en', 'fi': 'fi', 'ru': 'ru', 'de': 'de',
      };
      return ('translate_text', {
        'text': translateMatch.group(1)!.trim(),
        'target_language': langMap[translateMatch.group(2)!.toLowerCase()] ?? 'en',
      });
    }

    return null;
  }

  // -- Tool execution --

  Future<void> _executeToolCall(
    String toolName,
    Map<String, dynamic> params,
    dynamic supabase,
  ) async {
    // Create executor before any async gap
    final executor = ToolExecutor(context: context, ref: ref);

    try {
      final execResult = await executor.execute(toolName, params);
      final result = execResult.toolResult;

      // Persist the tool result as an assistant message
      await supabase.saveChatMessage(
        caseId: widget.caseId,
        role: 'assistant',
        content: result.displayText,
      );

      if (mounted) {
        final toolMessage = ChatMessage(
          id: 'tool_${DateTime.now().millisecondsSinceEpoch}',
          role: MessageRole.toolResult,
          content: result.displayText,
          timestamp: DateTime.now(),
          contentType: MessageContentType.toolCard,
          toolResult: result,
          navigation: execResult.navigation,
        );
        setState(() {
          _isTyping = false;
          _messages.add(toolMessage);
        });
        _updateChatPhase();
        _scrollToBottom();

        // Perform navigation if the tool result doesn't require approval
        if (execResult.navigation != null && !result.requiresApproval) {
          await executor.performNavigation(execResult.navigation!);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(
            id: 'error_${DateTime.now().millisecondsSinceEpoch}',
            role: MessageRole.system,
            content: 'Tool execution failed. Please try again.',
            timestamp: DateTime.now(),
          ));
        });
      }
    }
  }

  String _getDemoResponse(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('депортир') ||
        lower.contains('украл') ||
        lower.contains('полиц') ||
        lower.contains('магазин')) {
      return DemoData.chatResponses['situation']!;
    }
    if (lower.contains('вот решение') ||
        lower.contains('документ') ||
        lower.contains('фото')) {
      return DemoData.chatResponses['document_analysis']!;
    }
    if (lower.contains('analyze') || lower.contains('analysis')) {
      return DemoData.chatResponses['analyze']!;
    }
    if (lower.contains('option') || lower.contains('what can')) {
      return DemoData.chatResponses['options']!;
    }
    if (lower.contains('appeal') ||
        lower.contains('draft') ||
        lower.contains('жалоб')) {
      return DemoData.chatResponses['appeal']!;
    }
    if (lower.contains('deadline') ||
        lower.contains('date') ||
        lower.contains('срок')) {
      return DemoData.chatResponses['deadlines']!;
    }
    if (lower.contains('ошибк') || lower.contains('найти')) {
      return DemoData.chatResponses['analyze']!;
    }
    if (lower.contains('что у меня') ||
        lower.contains('ситуаци') ||
        lower.contains('что случ')) {
      return DemoData.chatResponses['situation']!;
    }
    if (lower.contains('прав') || lower.contains('right')) {
      return DemoData.chatResponses['options']!;
    }
    if (lower.contains('что делать') || lower.contains('первым')) {
      return DemoData.chatResponses['default']!;
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

  void _copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n?.copiedToClipboard ?? 'Copied to clipboard'),
        backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareCaseSummary() {
    final buffer = StringBuffer();
    buffer.writeln('=== CASE SUMMARY ===');
    buffer.writeln('Case: ${widget.caseName ?? widget.caseId}');
    buffer.writeln('Generated: ${DateTime.now().toLocal()}');
    buffer.writeln();

    for (final msg in _messages) {
      if (msg.role == MessageRole.system) continue;
      final prefix = msg.role == MessageRole.user ? 'USER' : 'AI';
      buffer.writeln('[$prefix ${_formatTime(msg.timestamp)}]');
      buffer.writeln(msg.content);
      buffer.writeln();
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    HapticFeedback.mediumImpact();
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n?.caseSummaryCopied ?? 'Case summary copied to clipboard'),
        backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // -- Build --

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Status bar
          _buildStatusBar(),

          // Disclaimer banner
          _buildDisclaimerBanner(),

          // Messages
          Expanded(child: _buildMessageList()),

          // Quick action chips
          if (!_isSending) _buildQuickActions(),

          // Input bar with voice button
          _buildInputBar(),
        ],
      ),
    );
  }

  // -- App bar --

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      titleSpacing: 0,
      title: Row(
        children: [
          // AI avatar — pulsing
          const _PulsingAvatar(),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.caseName ?? AppLocalizations.of(context)!.aiAssistant,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: _isTyping
                            ? AppColors.warning
                            : AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isTyping ? (AppLocalizations.of(context)?.typing ?? 'Typing...') : (AppLocalizations.of(context)?.online ?? 'Online'),
                      style: TextStyle(
                        fontSize: 12,
                        color: _isTyping
                            ? AppColors.warning
                            : AppColors.textTertiary,
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
        // Share case summary
        IconButton(
          icon: const Icon(Icons.summarize_outlined, size: 22),
          tooltip: 'Share case summary',
          onPressed: _shareCaseSummary,
        ),
        // TTS toggle
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

  // -- Status bar --

  Widget _buildStatusBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          // Case type icon
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.gavel_rounded,
              size: 16,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Case name
          Expanded(
            child: Text(
              widget.caseName ?? AppLocalizations.of(context)!.newCase,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Country flag
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🇫🇮', style: TextStyle(fontSize: 14)),
                SizedBox(width: 4),
                Text(
                  'FI',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Issues badge
          if (_issuesFound > 0) ...[
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 14, color: AppColors.error),
                  const SizedBox(width: 4),
                  Text(
                    '$_issuesFound',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Processing indicator
          if (_isTyping) ...[
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: AppColors.accent.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'AI...',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // -- Disclaimer banner --

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
                        ? (AppLocalizations.of(context)?.disclaimerExpanded ?? 'AI assistant — not legal advice. Always verify with a qualified lawyer.')
                        : (AppLocalizations.of(context)?.disclaimerCollapsed ?? 'AI guidance only'),
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

  // -- Message list --

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
                .scaleXY(
                    begin: 0.8,
                    end: 1,
                    duration: 500.ms,
                    curve: Curves.elasticOut),
            const SizedBox(height: AppSpacing.lg),
            Text(
              AppLocalizations.of(context)?.chatWelcomeMessage ??
                  'Tell me what happened',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            )
                .animate()
                .fadeIn(delay: 200.ms, duration: 400.ms),
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppLocalizations.of(context)?.chatWelcomeSubtitle ?? 'I will analyze the situation, check documents, find errors, and suggest what to do.',
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
                AppLocalizations.of(context)?.tapMicrophoneToSpeak ?? 'Tap the microphone to speak',
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

  // -- Message bubble --

  Widget _buildMessageBubble(ChatMessage message, int index) {
    final isUser = message.role == MessageRole.user;
    final isSystem = message.role == MessageRole.system;
    final isToolResult = message.role == MessageRole.toolResult;

    if (isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Center(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

    final screenWidth = MediaQuery.of(context).size.width;
    final bubbleMargin = screenWidth < 380 ? 32.0 : 48.0;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: AppSpacing.sm,
          left: isUser ? bubbleMargin : 0,
          right: isUser ? 0 : (isToolResult ? 16 : bubbleMargin),
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Message bubble — tool results get no wrapper, others get styled bubble
            if (isToolResult) ...[
              _buildMessageContent(message, false),
            ] else ...[
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
                  bottomLeft: isUser
                      ? const Radius.circular(AppRadius.lg)
                      : const Radius.circular(4),
                  bottomRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(AppRadius.lg),
                ),
                border: isUser
                    ? null
                    : Border.all(color: AppColors.border, width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: (isUser
                            ? AppColors.primary
                            : Colors.black)
                        .withValues(alpha: isUser ? 0.15 : 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMessageContent(message, isUser),
                  // Attachment indicator
                  if (message.hasAttachment) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: (isUser
                                ? Colors.white
                                : AppColors.accent)
                            .withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 16,
                            color: isUser
                                ? Colors.white70
                                : AppColors.accent,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Document attached',
                            style: TextStyle(
                              fontSize: 12,
                              color: isUser
                                  ? Colors.white70
                                  : AppColors.accent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ], // end of else (non-tool-result bubble)

            // Timestamp + action buttons row
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(message.timestamp),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  // Copy button for AI messages
                  if (!isUser) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _copyMessage(message.content),
                      child: const Icon(
                        Icons.copy_rounded,
                        size: 14,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideX(
          begin: isUser ? 0.15 : -0.15,
          end: 0,
          duration: 350.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildMessageContent(ChatMessage message, bool isUser) {
    final textColor = isUser ? Colors.white : AppColors.textPrimary;

    // Tool result messages get a rich card
    if (message.role == MessageRole.toolResult && message.toolResult != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ToolResultCard(
            result: message.toolResult!,
            onAction: (action) => _sendMessage(action),
            onApprove: () {
              // Handle approval -- navigate if there's a pending navigation
              if (message.navigation != null) {
                final executor = ToolExecutor(context: context, ref: ref);
                executor.performNavigation(message.navigation!);
              }
            },
            onReject: () {
              // Cancelled -- just acknowledge in chat
              _sendMessage('Cancel the action.');
            },
          ),
        ],
      );
    }

    if (!isUser) {
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

  Widget _buildRichAIContent(String content, Color textColor) {
    final lines = content.split('\n');
    final widgets = <Widget>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 6));
        continue;
      }

      // Clickable action buttons (lines starting with specific patterns)
      if (trimmed.startsWith('[ACTION:') && trimmed.endsWith(']')) {
        final actionText =
            trimmed.substring(8, trimmed.length - 1).trim();
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: _buildActionButton(actionText),
        ));
        continue;
      }

      // Severity indicators
      if (trimmed.startsWith('🔴') ||
          trimmed.startsWith('🟡') ||
          trimmed.startsWith('🔵')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: _buildSeverityLine(trimmed, textColor),
        ));
        continue;
      }

      // Bullet point lines
      if (trimmed.startsWith('- ') ||
          trimmed.startsWith('\u2022 ') ||
          trimmed.startsWith('* ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 4, left: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 7, right: 8),
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
                child: _buildStyledText(
                  trimmed.replaceFirst(RegExp(r'^[-\u2022\*]\s*'), ''),
                  textColor,
                ),
              ),
            ],
          ),
        ));
        continue;
      }

      // Numbered list
      if (RegExp(r'^\d+[\.\)]\s').hasMatch(trimmed)) {
        final match = RegExp(r'^(\d+[\.\)])\s(.*)').firstMatch(trimmed);
        if (match != null) {
          widgets.add(Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    match.group(1)!,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                    ),
                  ),
                ),
                Expanded(
                  child:
                      _buildStyledText(match.group(2)!, textColor),
                ),
              ],
            ),
          ));
          continue;
        }
      }

      // Checkbox lines
      if (trimmed.startsWith('[ ]') || trimmed.startsWith('[x]') ||
          trimmed.startsWith('[\u2713]')) {
        final checked =
            trimmed.startsWith('[x]') || trimmed.startsWith('[\u2713]');
        final checkText =
            trimmed.replaceFirst(RegExp(r'^\[.\]\s*'), '');
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 4, left: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 8),
                child: Icon(
                  checked
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  size: 18,
                  color: checked ? AppColors.success : AppColors.textTertiary,
                ),
              ),
              Expanded(
                child: _buildStyledText(checkText, textColor),
              ),
            ],
          ),
        ));
        continue;
      }

      // Status indicator lines (emoji prefix)
      if (trimmed.startsWith('\u2705') ||
          trimmed.startsWith('\u274C') ||
          trimmed.startsWith('\u26A0\uFE0F') ||
          trimmed.startsWith('\u26A0')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: _buildStyledText(trimmed, textColor),
        ));
        continue;
      }

      // Regular text line
      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: _buildStyledText(trimmed, textColor),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  /// Render text with inline **bold** support.
  Widget _buildStyledText(String text, Color baseColor) {
    final spans = <InlineSpan>[];
    final boldRegex = RegExp(r'\*\*(.+?)\*\*');
    int lastEnd = 0;

    for (final match in boldRegex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: TextStyle(color: baseColor, fontSize: 15, height: 1.45),
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: TextStyle(
          color: baseColor,
          fontSize: 15,
          height: 1.45,
          fontWeight: FontWeight.w700,
        ),
      ));
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: TextStyle(color: baseColor, fontSize: 15, height: 1.45),
      ));
    }

    if (spans.isEmpty) {
      return SelectableText(
        text,
        style: TextStyle(color: baseColor, fontSize: 15, height: 1.45),
      );
    }

    return SelectableText.rich(
      TextSpan(children: spans),
    );
  }

  Widget _buildSeverityLine(String text, Color textColor) {
    Color badgeColor;
    String label;

    if (text.startsWith('🔴')) {
      badgeColor = AppColors.error;
      label = 'Critical';
    } else if (text.startsWith('🟡')) {
      badgeColor = AppColors.warning;
      label = 'Important';
    } else {
      badgeColor = AppColors.info;
      label = 'Info';
    }

    final content = text.replaceFirst(RegExp(r'^[🔴🟡🔵]\s*'), '');

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border(
          left: BorderSide(color: badgeColor, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _buildStyledText(content, textColor),
        ],
      ),
    );
  }

  Widget _buildActionButton(String actionText) {
    IconData icon = Icons.arrow_forward_rounded;
    if (actionText.contains('Сканировать') ||
        actionText.contains('сканировать')) {
      icon = Icons.document_scanner_outlined;
    } else if (actionText.contains('жалобу') ||
        actionText.contains('Жалобу')) {
      icon = Icons.description_outlined;
    } else if (actionText.contains('дедлайн') ||
        actionText.contains('срок')) {
      icon = Icons.schedule_rounded;
    }

    return InkWell(
      onTap: () => _sendMessage(actionText),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.accent),
            const SizedBox(width: 8),
            Text(
              actionText,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 12, color: AppColors.accent),
          ],
        ),
      ),
    );
  }

  // -- Typing indicator --

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm, right: 80),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 6,
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'AI анализирует',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 10),
            ...List.generate(3, (i) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
              )
                  .animate(
                    onPlay: (c) => c.repeat(),
                  )
                  .moveY(
                    begin: 0,
                    end: -6,
                    delay: Duration(milliseconds: 180 * i),
                    duration: 350.ms,
                    curve: Curves.easeOutCubic,
                  )
                  .then()
                  .moveY(
                    begin: -6,
                    end: 0,
                    duration: 350.ms,
                    curve: Curves.bounceOut,
                  );
            }),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 250.ms)
        .slideX(begin: -0.1, end: 0, duration: 300.ms, curve: Curves.easeOutCubic);
  }

  // -- Quick action chips --

  Widget _buildQuickActions() {
    final List<(String, IconData)> actions;

    switch (_chatPhase) {
      case _ChatPhase.newCase:
        actions = [
          ('Что у меня за ситуация?', Icons.help_outline_rounded),
          ('Какие у меня права?', Icons.shield_outlined),
          ('Что делать первым?', Icons.flag_outlined),
          ('Сканировать документ', Icons.document_scanner_outlined),
        ];
        break;
      case _ChatPhase.afterScan:
        actions = [
          ('Найти ошибки', Icons.search_rounded),
          ('Составить жалобу', Icons.description_outlined),
          ('Проверить сроки', Icons.schedule_rounded),
          ('Объяснить простыми словами', Icons.translate_rounded),
        ];
        break;
      case _ChatPhase.afterAnalysis:
        actions = [
          ('Составить жалобу', Icons.description_outlined),
          ('Найти адвоката', Icons.person_search_outlined),
          ('Объяснить простыми словами', Icons.translate_rounded),
          ('Проверить дедлайны', Icons.schedule_rounded),
        ];
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          children: actions.map((action) {
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ActionChip(
                avatar:
                    Icon(action.$2, size: 16, color: AppColors.accent),
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
                  borderRadius:
                      BorderRadius.circular(AppRadius.full),
                ),
                onPressed: () => _sendMessage(action.$1),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // -- Input bar --

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.sm,
        right: AppSpacing.sm,
        top: AppSpacing.sm + 2,
        bottom:
            MediaQuery.of(context).padding.bottom + AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.border.withValues(alpha: 0.3),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Voice partial text + button
          if (_voiceState == VoiceButtonState.listening ||
              _voiceState == VoiceButtonState.speaking)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: VoiceButton(
                state: _voiceState,
                partialText:
                    _voiceState == VoiceButtonState.listening
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
                icon:
                    const Icon(Icons.add_circle_outline_rounded),
                color: AppColors.textTertiary,
                onPressed: () {
                  context
                      .push('/scan?caseId=${widget.caseId}');
                },
              ),

              // Text field with premium focus glow
              Expanded(
                child: _PremiumTextField(
                  controller: _messageController,
                  focusNode: _focusNode,
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

              // Send button with subtle glow
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed:
                      _isSending ? null : () => _sendMessage(),
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
                    disabledBackgroundColor:
                        AppColors.accent.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -- Date separator --

  Widget _buildDateSeparator(DateTime date) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          const Expanded(
              child: Divider(color: AppColors.border)),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm),
            child: Text(
              _formatDate(date),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Expanded(
              child: Divider(color: AppColors.border)),
        ],
      ),
    );
  }

  // -- Helpers --

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) return 'Сегодня';
    if (_isSameDay(
        date, now.subtract(const Duration(days: 1)))) {
      return 'Вчера';
    }
    const months = [
      '',
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];
    return '${date.day} ${months[date.month]}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _PulsingAvatar extends StatefulWidget {
  const _PulsingAvatar();

  @override
  State<_PulsingAvatar> createState() => _PulsingAvatarState();
}

class _PulsingAvatarState extends State<_PulsingAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 46,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer breathing glow ring
              Container(
                width: 36 + _pulse.value * 10,
                height: 36 + _pulse.value * 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.3 - _pulse.value * 0.25),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.12 + _pulse.value * 0.12),
                      blurRadius: 8 + _pulse.value * 8,
                      spreadRadius: _pulse.value * 3,
                    ),
                  ],
                ),
              ),
              // Second subtle ring
              Container(
                width: 36 + _pulse.value * 5,
                height: 36 + _pulse.value * 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accentLight.withValues(alpha: 0.15 - _pulse.value * 0.1),
                    width: 1.0,
                  ),
                ),
              ),
              // Core avatar
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.accent, AppColors.accentLight],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.3 + _pulse.value * 0.15),
                      blurRadius: 8 + _pulse.value * 4,
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
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Premium Text Field with focus glow
// ---------------------------------------------------------------------------

class _PremiumTextField extends StatefulWidget {
  const _PremiumTextField({
    required this.controller,
    required this.focusNode,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  State<_PremiumTextField> createState() => _PremiumTextFieldState();
}

class _PremiumTextFieldState extends State<_PremiumTextField> {
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) setState(() => _hasFocus = widget.focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      constraints: const BoxConstraints(maxHeight: 120),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: _hasFocus
            ? [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        maxLines: 5,
        minLines: 1,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.newline,
        decoration: InputDecoration(
          hintText: 'Опишите вашу ситуацию...',
          hintStyle: const TextStyle(color: AppColors.textTertiary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            borderSide: _hasFocus
                ? BorderSide(color: AppColors.accent.withValues(alpha: 0.4), width: 1.0)
                : BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            borderSide: BorderSide(color: AppColors.accent.withValues(alpha: 0.4), width: 1.0),
          ),
          filled: true,
          fillColor: _hasFocus
              ? AppColors.surface
              : AppColors.surfaceVariant,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
        ),
      ),
    );
  }
}
