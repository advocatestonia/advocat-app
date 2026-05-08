import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/router.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/case_model.dart';
import '../../../models/deadline.dart';
import '../../../services/ai_service.dart';
import '../../../services/assistant_tools.dart';
import '../../../services/chat_stream_event.dart';
import '../../../services/claude_service.dart'
    show ClaudeService, ClaudeServiceException;
import '../../../services/legal_planner.dart';
import '../widgets/planner_trail.dart';
import '../../../services/chat_attachment_service.dart';
import '../../../services/client_knowledge_service.dart';
import '../../../services/supabase_service.dart';
import '../../../services/tool_executor.dart';
import '../../../services/feedback_service.dart';
import '../../../services/language_detector.dart';
import '../../../services/pdf_service.dart';
import '../../../services/voice_service.dart';
import '../citations/citation_model.dart';
import '../../../widgets/feedback_buttons.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/chat_tool_bridge.dart';
import '../utils/message_speaker.dart';
import '../widgets/quota_error_snackbar.dart';
import '../widgets/reasoning_trail.dart';
import '../widgets/tool_result_card.dart';
import '../widgets/voice_button.dart';
import '../widgets/welcome_chips.dart';
import '../quick_profile/quick_profile_gate.dart';
import '../quick_profile/quick_profile_intake.dart';
import '../../../services/user_memory_service.dart';
import '../../case_memory/widgets/active_case_chip.dart';
import '../../case_memory/widgets/deadline_banner.dart';

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

  /// Phase 2 Pkg 2 — grounded citations attached to this assistant message.
  /// Empty for user / system / tool-result messages, and for legacy
  /// assistant messages (pre-Pkg 2) which had no marker syntax.
  final List<Citation> citations;

  /// Phase 2 Pkg 6 — planner trace data for the Reasoning Trail UI.
  /// Non-null only on assistant messages produced by the legal planner loop
  /// (Pro + opt-in + looksLegalish). Renders [PlannerTrail] below the bubble.
  final PlannerTraceData? plannerTraceData;

  /// True when the planner signals `blocking_gap: true` — i.e. the AI needs
  /// more information before it can give a substantive answer. The bubble is
  /// rendered with a distinct amber background so the user notices it is a
  /// clarifying question, not an answer.
  final bool isBlockingGap;

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
    this.citations = const [],
    this.plannerTraceData,
    this.isBlockingGap = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? DateTime.now().toIso8601String(),
      role: json['role'] == 'user' ? MessageRole.user : MessageRole.assistant,
      content: json['content'] as String? ?? '',
      timestamp: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      hasAttachment: json['has_attachment'] as bool? ?? false,
      citations: Citation.listFromJson(json['citations']),
      isBlockingGap: json['is_blocking_gap'] as bool? ?? false,
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

/// Thrown inside _sendMessage to short-circuit the streaming try-block and
/// fall through to the non-streaming path. Used for turns that carry an
/// inline image attachment — streaming does not yet support vision content
/// blocks, and we need the multimodal-capable non-streaming path instead.
class _SkipStreamingForVision implements Exception {
  const _SkipStreamingForVision();
  @override
  String toString() =>
      'skip streaming: image attachment requires non-streaming vision path';
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
  // Reasoning Trail v1 (2026-05-05) — per-turn event broadcaster. The
  // streaming consumer below (around line 746) feeds typed ChatStreamEvents
  // here so the [ReasoningTrail] widget can show what the model is doing.
  // Kept as a broadcast so the widget can re-listen on rebuild without
  // dropping events.
  StreamController<ChatStreamEvent>? _trailController;
  _ChatPhase _chatPhase = _ChatPhase.newCase;
  int _issuesFound = 0;
  final _knowledgeService = ClientKnowledgeService();
  bool _upgradeBannerDismissed = false;
  int _freeMessagesUsed = 0;
  // Mirrors AIService.freeTotalLimit (7, per Founder's Beta refund policy).
  // Updated at runtime from the server response so the UI never drifts from
  // the real quota.
  int _freeMessagesTotal = AIService.freeTotalLimit;
  int _freeMessagesRemaining = AIService.freeTotalLimit;
  LegalCase? _currentCase;

  // -- Voice state --
  VoiceButtonState _voiceState = VoiceButtonState.idle;
  bool _ttsEnabled = true;
  bool _voiceInitialized = false;
  StreamSubscription<String>? _speechSub;

  // -- Stop button (Cursor consilium Gap #1, 2026-05-05) --
  //
  // Holds the active Stream subscription from
  // ai.sendChatMessageStreamingEvents() so the user can cancel a
  // wrong-direction generation mid-flight via _stopStreaming(). When the
  // stream completes naturally we set this back to null in the listen()
  // onDone handler.
  StreamSubscription<ChatStreamEvent>? _aiSub;
  // True when the active generation was cancelled by the user. Drives
  // the "Stopped by user" placeholder and quota refund decision in
  // _stopStreaming().
  bool _stoppedByUser = false;
  // Live references to the in-flight stream's text buffer + bubble id so
  // _stopStreaming() (invoked from the input bar's onPressed) can decide
  // (a) whether to refund the quota slot (empty buffer = refund) and
  // (b) which assistant bubble to mark "Stopped by user".
  StringBuffer? _currentStreamFullText;
  String? _currentStreamMessageId;

  /// Single source of truth for speaking AI replies. Rebuilt per reply
  /// so that each AI message produces exactly ONE voiceService.speak()
  /// call — see docs/tts-audit/02-voice-switching-root-cause.md.
  MessageSpeaker? _messageSpeaker;

  // -- Post-launch BUG 3 fix (2026-04-22): first-conversation prompt --
  //
  // When the user opens a brand-new case chat for the first time, show
  // five category chips under the welcome message so they can pick what
  // kind of help they need.  Hidden after first tap or after the user
  // sends any message manually.
  bool _showWelcomeChips = false;

  // -- Quick Profile intake (2026-05-05) --
  //
  // First-chat one-shot intake that asks the user's legal status once
  // (citizen / EU citizen / 3rd-country with permit). Without this the
  // AI re-asks the same question every session, and the answer never
  // settles into long-term memory. Decision logic + persistence lives in
  // [QuickProfileGate]; render is in [QuickProfileIntake]. We gate on
  // BOTH user_ai_memory (any legal-status fact already there) AND a
  // SharedPreferences flag (advocat_quick_profile_completed_at) so a
  // user who tapped Skip is never re-asked.
  bool _showQuickProfile = false;

  // Guards the per-session intake trigger: once we have decided to show
  // the bottom sheet (or determined it should not show), flip this flag
  // so subsequent AI responses do not re-trigger it.
  bool _hasShownIntakeThisSession = false;

  // -- Image-vision staging (2026-04-23) --
  // Staged when the user picks an image; consumed (cleared) on next
  // _sendMessage so the image is forwarded to Claude as an inline vision
  // content block. Streaming does not yet support vision — turns with
  // _pendingImageAttachment set skip the streaming path.
  ChatAttachment? _pendingImageAttachment;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _initVoice();
    _loadFreeMessageCount();
    _loadCase();
    _knowledgeService.buildClientContext(caseId: widget.caseId);
  }

  Future<void> _loadFreeMessageCount() async {
    try {
      final ai = ref.read(aiServiceProvider);
      final remaining = await ai.getRemainingFreeCalls();
      if (!mounted) return;
      setState(() {
        _freeMessagesTotal = AIService.freeTotalLimit;
        _freeMessagesRemaining = remaining < 0 ? -1 : remaining;
        _freeMessagesUsed = remaining < 0
            ? 0
            : (_freeMessagesTotal - remaining).clamp(0, _freeMessagesTotal);
      });
    } catch (_) {
      // On error, assume quota is exhausted (fall-closed UI matches
      // fall-closed service behaviour).
      if (!mounted) return;
      setState(() {
        _freeMessagesTotal = AIService.freeTotalLimit;
        _freeMessagesRemaining = 0;
        _freeMessagesUsed = _freeMessagesTotal;
      });
    }
  }

  Future<void> _loadCase() async {
    try {
      final supabase = ref.read(supabaseServiceProvider);
      _currentCase = await supabase.getCaseById(widget.caseId);
    } catch (_) {}
  }

  /// The Completer associated with the active stream's "done" signal. Held
  /// here (in addition to the local var inside _sendMessage) so that
  /// _stopStreaming() can complete it when the user taps Stop. Without
  /// this, the .cancel() drops events but the awaited future would never
  /// fire and the finally block would not run.
  Completer<void>? _streamDoneCompleter;

  /// Cancel the in-flight AI stream (Cursor consilium Gap #1, 2026-05-05).
  ///
  /// Behaviour:
  ///   - Cancels [_aiSub] so the upstream HTTP/SSE connection drops on the
  ///     next chunk boundary.
  ///   - Marks [_stoppedByUser] so the streaming consumer in _sendMessage
  ///     swaps a "Stopped by user" placeholder for the partial bubble when
  ///     no text has streamed in yet.
  ///   - Refunds the local quota slot iff no tokens have been received —
  ///     a tap that beats the first byte must not bill the user; a tap
  ///     after content arrived DOES bill (Anthropic charged us for it).
  ///   - Completes the stream's Completer so the awaiting `_sendMessage`
  ///     future falls through to its finally block.
  ///
  /// Idempotent and safe to call multiple times. No-op when no stream is
  /// active.
  void _stopStreaming(StringBuffer fullText, String streamingMessageId) {
    if (_aiSub == null) return; // No active stream — nothing to stop.
    _stoppedByUser = true;
    final anyTokensReceived = fullText.isNotEmpty;
    unawaited(_aiSub?.cancel() ?? Future<void>.value());
    _aiSub = null;
    final completer = _streamDoneCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
    _streamDoneCompleter = null;

    // Refund the quota only if we beat the first byte.
    final ai = ref.read(aiServiceProvider);
    ai.refundLocalQuotaIfEmptyStop(anyTokensReceived: anyTokensReceived);

    // Swap the empty placeholder bubble for "Stopped by user" so the chat
    // doesn't end with a blank assistant message.
    if (mounted) {
      final stoppedLabel = _stoppedByUserLabelForLocale();
      setState(() {
        final idx = _messages.indexWhere((m) => m.id == streamingMessageId);
        if (idx >= 0) {
          // If text already arrived, keep it and append the marker. Else
          // replace the empty bubble with the marker alone.
          final existing = _messages[idx].content;
          final newContent = existing.isEmpty
              ? stoppedLabel
              : '$existing\n\n_${stoppedLabel}_';
          _messages[idx] = ChatMessage(
            id: streamingMessageId,
            role: MessageRole.assistant,
            content: newContent,
            timestamp: DateTime.now(),
          );
        }
        _isSending = false;
        _isTyping = false;
      });
    }
    // Refresh the displayed quota counter after refund.
    _loadFreeMessageCount();
  }

  /// Inline locale switch for the "Stopped by user" marker. Self-contained
  /// so this fix doesn't require regenerating app_localizations.dart.
  String _stoppedByUserLabelForLocale() {
    final code = Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
    switch (code) {
      case 'et':
        return 'Kasutaja peatas';
      case 'ru':
      case 'uk':
        return 'Остановлено пользователем';
      case 'fi':
        return 'Käyttäjä pysäytti';
      case 'de':
        return 'Vom Benutzer gestoppt';
      default:
        return 'Stopped by user';
    }
  }

  @override
  void dispose() {
    _knowledgeService.saveConversationSummary(caseId: widget.caseId);
    _voiceSilenceTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _speechSub?.cancel();
    // Stop button (2026-05-05): kill any active AI subscription so an
    // in-flight stream does not write to a disposed widget.
    unawaited(_aiSub?.cancel() ?? Future<void>.value());
    _aiSub = null;
    _trailController?.close();
    super.dispose();
  }

  // -- Voice initialization --

  Future<void> _initVoice() async {
    final voice = ref.read(voiceServiceProvider);
    final sttOk = await voice.initSpeech();
    await voice.initTTS();
    if (mounted) {
      // On web, show the mic button even if STT init failed at startup.
      // The VoiceService will retry lazily on first tap (user gesture).
      setState(() => _voiceInitialized = sttOk || kIsWeb);
    }
    // Pre-warm Google TTS Edge Function to avoid cold start on first message.
    if (_ttsEnabled) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) voice.warmUp();
      });
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
    });

    final stream = voice.startListening(langCode: langCode);

    // Timeout: if no speech detected in 5 seconds, show hint
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted &&
          _voiceState == VoiceButtonState.listening &&
          _messageController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context)?.speakIntoMicHint ?? 'Speak into the microphone. Make sure microphone access is enabled.'),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    _speechSub?.cancel();
    _speechSub = stream.listen(
      (partial) {
        if (mounted) {
          // Put partial speech directly into the text field
          _messageController.text = partial;
          _messageController.selection = TextSelection.fromPosition(
            TextPosition(offset: partial.length),
          );
          setState(() {});

          // Reset silence timer — auto-send after 4.5s of silence.
          _voiceSilenceTimer?.cancel();
          _voiceSilenceTimer = Timer(const Duration(milliseconds: 4500), () {
            if (_voiceState == VoiceButtonState.listening &&
                _messageController.text.trim().isNotEmpty) {
              _stopVoiceInput(autoSend: true);
            }
          });
        }
      },
      onError: (Object error) {
        // Handle STT unavailable (e.g. web permissions denied).
        if (mounted) {
          setState(() {
            _voiceState = VoiceButtonState.idle;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Speech recognition unavailable. Please check microphone permissions.',
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
      },
      onDone: () {
        // In continuous mode, the stream does not complete until the user
        // explicitly presses the stop button.  Do NOT auto-stop here.
      },
    );
  }

  /// Timer that fires after user stops speaking — auto-sends the message.
  Timer? _voiceSilenceTimer;

  Future<void> _stopVoiceInput({bool autoSend = false}) async {
    _voiceSilenceTimer?.cancel();
    unawaited(_speechSub?.cancel());
    final voice = ref.read(voiceServiceProvider);
    final finalText = await voice.stopListening();

    if (!mounted) return;

    setState(() {
      _voiceState = VoiceButtonState.idle;
    });

    // Use finalText from STT, or fall back to what's already in the text field
    final textToSend = finalText.trim().isNotEmpty
        ? finalText.trim()
        : _messageController.text.trim();

    if (textToSend.isNotEmpty) {
      if (autoSend) {
        _messageController.clear();
        unawaited(_sendMessage(textToSend));
      } else {
        _messageController.text = textToSend;
        _messageController.selection = TextSelection.fromPosition(
          TextPosition(offset: textToSend.length),
        );
        _focusNode.requestFocus();
      }
    }
  }

  /// Speak a full (non-streaming) AI reply. Used by the welcome message,
  /// tool-use follow-ups, and the non-streaming LLM fallback.
  ///
  /// Contract: exactly ONE voiceService.speak() per call. The routing
  /// (ElevenLabs vs Google) is decided once by langCode — no mid-reply
  /// engine switch. See docs/tts-audit/02-voice-switching-root-cause.md.
  Future<void> _speakResponse(String text) async {
    if (!_ttsEnabled) return;

    final voice = ref.read(voiceServiceProvider);
    final langCode = Localizations.localeOf(context).languageCode;

    // Stop STT before TTS to prevent echo (AI voice being recognized
    // as user input).
    if (_voiceState == VoiceButtonState.listening) {
      _voiceSilenceTimer?.cancel();
      unawaited(_speechSub?.cancel());
      await voice.stopListening();
    }

    // Clear any text that might have been echoed into the input field.
    _messageController.clear();

    setState(() => _voiceState = VoiceButtonState.speaking);

    final speaker = MessageSpeaker(
      speaker: VoiceServiceSpeaker(voice),
      langCode: langCode,
    );

    try {
      await speaker.speakFullResponse(text);
      // Wait for audio to actually finish playing (safety timeout 30s).
      var waited = 0;
      while (voice.isSpeaking && waited < 150) {
        await Future.delayed(const Duration(milliseconds: 200));
        waited++;
        if (!mounted) return;
      }
    } catch (e) {
      debugPrint('TTS: _speakResponse error: $e');
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

        // Seed AI conversation history from saved messages
        _seedAIHistory();

        // If no messages exist, this is a new case -- send welcome
        if (_messages.isEmpty) {
          _sendWelcomeMessage();
        } else {
          _updateChatPhase();
        }

        // Preload context so the first AI response doesn't block on Supabase queries
        unawaited(_knowledgeService.buildClientContext(caseId: widget.caseId));

        // Quick Profile intake is now triggered AFTER the first AI response
        // (see _maybeShowIntakeAfterFirstAIResponse). No longer shown on mount.

        // Check for urgent deadlines and notify the user
        unawaited(_checkUrgentDeadlines());

        _scrollToBottom(animated: false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _messages = [];
        });
        _sendWelcomeMessage();
        // Quick Profile intake is deferred to after the first AI response.
      }
    }
  }

  /// Seed the AI service's conversation history from previously loaded messages
  /// so the AI has context from prior conversations.
  void _seedAIHistory() {
    if (_messages.isEmpty) return;
    final ai = ref.read(aiServiceProvider);
    final historyMsgs = <Map<String, String>>[];
    for (final msg in _messages) {
      if (msg.role == MessageRole.user) {
        historyMsgs.add({'role': 'user', 'content': msg.content});
      } else if (msg.role == MessageRole.assistant) {
        historyMsgs.add({'role': 'assistant', 'content': msg.content});
      }
    }
    ai.seedHistory(widget.caseId, historyMsgs);
  }

  void _sendWelcomeMessage() {
    final l10n = AppLocalizations.of(context);
    final welcome = ChatMessage(
      id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
      role: MessageRole.assistant,
      content: l10n?.chatWelcomeMessage ??
          // AI Act Art. 50 transparency: fallback also explicit about AI + disclaimer.
          "Hi! I'm Advocat — your AI legal assistant. I provide legal information, not legal advice. What legal question can I help with?",
      timestamp: DateTime.now(),
    );
    setState(() {
      _messages.add(welcome);
      _chatPhase = _ChatPhase.newCase;
      // BUG 3 fix: show first-conversation category chips below the
      // welcome message so the user knows how to start.
      _showWelcomeChips = true;
    });
    _scrollToBottom();
  }

  /// Bug 3 handler: user tapped one of the five welcome category chips.
  /// Pre-fills the text field and, after a short delay so they can see
  /// the pre-filled text, sends it automatically.
  void _onWelcomeCategoryPicked(
    WelcomeCategory category,
    String prefill,
  ) {
    setState(() {
      _showWelcomeChips = false;
      _messageController.text = prefill;
      _messageController.selection = TextSelection.fromPosition(
        TextPosition(offset: prefill.length),
      );
    });
    // Give the user 350 ms to see the pre-filled text before we send it;
    // this makes the transition less jarring than sending instantly.
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final text = _messageController.text.trim();
      if (text.isEmpty) return;
      _messageController.clear();
      _sendMessage(text);
    });
  }

  /// Bug 3 handler: user tapped "skip" on the welcome chips — they just
  /// want to start typing themselves. Hide the chips.
  void _onWelcomeSkip() {
    setState(() {
      _showWelcomeChips = false;
    });
  }

  // -- Quick Profile intake handlers (2026-05-05, redesigned 2026-05-08) --

  /// Called once after the first AI response arrives. Checks whether the
  /// intake gate should show and, if so, presents it as a bottom sheet
  /// after a short delay so the UI settles before the sheet appears.
  ///
  /// Idempotent — guarded by [_hasShownIntakeThisSession] so multiple AI
  /// responses (e.g. streaming + follow-up) only trigger it once.
  void _maybeShowIntakeAfterFirstAIResponse() {
    if (_hasShownIntakeThisSession) return;
    _hasShownIntakeThisSession = true;

    Future.delayed(const Duration(milliseconds: 800), () async {
      if (!mounted) return;
      try {
        final memoryService = ref.read(userMemoryServiceProvider);
        final memories = await memoryService.getMemories(limit: 20);
        if (!mounted) return;
        final show = await QuickProfileGate.shouldShow(memories: memories);
        if (!mounted || !show) return;
        _showIntakeGate();
      } catch (_) {
        // Best-effort — never block chat on intake gating.
      }
    });
  }

  /// Present the QuickProfileIntake as a modal bottom sheet. This is less
  /// aggressive than a blocking full-screen overlay and lets the user
  /// dismiss it without feeling interrupted.
  void _showIntakeGate() {
    final locale = Localizations.localeOf(context).languageCode;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E), // matches app dark surface
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                QuickProfileIntake(
                  locale: locale,
                  onAnswer: (answer) {
                    Navigator.of(context).pop();
                    _onQuickProfileAnswer(answer);
                  },
                  onSkip: () {
                    Navigator.of(context).pop();
                    _onQuickProfileSkip();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// User tapped a status chip — persist the flag, echo the answer back
  /// as a "user" message, and ask extract-memory to upsert the structured
  /// facts via the focused intake prompt (`intake: 'quick_profile'`).
  /// Intake never blocks the user — they can keep typing immediately.
  Future<void> _onQuickProfileAnswer(QuickProfileAnswer answer) async {
    final locale = Localizations.localeOf(context).languageCode;
    final label = quickProfileAnswerLabel(answer, locale);

    // Echo the tap back as a user message so the chat reads naturally
    // ("you said X, here's the rest"). Stays in the local list only —
    // we deliberately do NOT save to Supabase chat_messages, the intake
    // is a side-channel.
    final echo = ChatMessage(
      id: 'quick_profile_${DateTime.now().millisecondsSinceEpoch}',
      role: MessageRole.user,
      content: label,
      timestamp: DateTime.now(),
    );

    setState(() {
      _showQuickProfile = false;
      _messages.add(echo);
    });
    _scrollToBottom();

    // Persist the flag immediately so navigating away mid-extract still
    // suppresses the intake on next mount.
    unawaited(QuickProfileGate.markCompleted());

    // Fire-and-forget extraction. The Edge Function will see
    // intake='quick_profile' and use the focused prompt that pulls only
    // legal_status / nationality / residence_status — no tone/preference
    // pollution from a one-line reply.
    final facts = answer.toFacts();
    if (facts.isEmpty) return;
    final memoryService = ref.read(userMemoryServiceProvider);
    final intakeMessage = facts
        .map((f) => '${f.key}: ${f.value}')
        .join('\n');
    unawaited(
      memoryService.extractFromSession(
        messages: [(role: 'user', content: intakeMessage)],
        sessionId: 'quick_profile_intake',
        intake: 'quick_profile',
      ),
    );
  }

  /// User tapped Skip — hide intake, persist the flag so we never ask
  /// again, and do NOT call extract-memory (no facts to upsert).
  void _onQuickProfileSkip() {
    setState(() => _showQuickProfile = false);
    unawaited(QuickProfileGate.markCompleted());
  }

  /// Check for deadlines within 3 days and show a system-level warning.
  Future<void> _checkUrgentDeadlines() async {
    try {
      final supabase = ref.read(supabaseServiceProvider);
      final deadlines = await supabase.getDeadlines(caseId: widget.caseId);
      if (deadlines.isEmpty || !mounted) return;

      final now = DateTime.now();
      final urgentDeadlines = deadlines.where((d) {
        final daysLeft = d.dueDate.difference(now).inDays;
        // Show warning for deadlines within 3 days that are not completed/cancelled
        return daysLeft >= 0 &&
            daysLeft <= 3 &&
            d.status != DeadlineStatus.completed &&
            d.status != DeadlineStatus.cancelled;
      }).toList();

      if (urgentDeadlines.isEmpty) return;

      for (final d in urgentDeadlines) {
        final daysLeft = d.dueDate.difference(now).inDays;
        final timeLabel = daysLeft == 0 ? 'TODAY' : 'in $daysLeft day${daysLeft == 1 ? '' : 's'}';
        // Avoid duplicate deadline warnings in the same session
        final warningId = 'deadline_warn_${d.id}';
        if (_messages.any((m) => m.id == warningId)) continue;

        final warning = ChatMessage(
          id: warningId,
          role: MessageRole.system,
          content: '\u26a0\ufe0f Deadline $timeLabel: ${d.title}. '
              'Want me to help prepare?',
          timestamp: DateTime.now(),
        );
        if (mounted) {
          setState(() => _messages.insert(0, warning));
        }
      }
      if (mounted) _scrollToBottom();

      // Check if case has been inactive (use already loaded messages)
      if (_currentCase != null && _messages.isNotEmpty) {
        final lastMessage = _messages.last;
        final daysSince = DateTime.now().difference(lastMessage.timestamp).inDays;
        if (daysSince >= 3 && _currentCase!.status != CaseStatus.closed) {
          final caseTitle = _currentCase?.title ?? 'your case';
          _messages.add(ChatMessage(
            id: 'proactive_${DateTime.now().millisecondsSinceEpoch}',
            role: MessageRole.system,
            content: '💡 It\'s been $daysSince days since our last conversation about "$caseTitle". Any updates? New documents to analyze? Deadlines approaching?',
            timestamp: DateTime.now(),
          ));
        }
      }

      // Check if case has no deadlines tracked (user might be missing something)
      if (_currentCase != null && _messages.length > 5) {
        if (deadlines.isEmpty && _currentCase!.status != CaseStatus.closed) {
          final hintId = 'hint_deadlines_${widget.caseId}';
          if (!_messages.any((m) => m.id == hintId) && mounted) {
            setState(() {
              _messages.add(ChatMessage(
                id: hintId,
                role: MessageRole.system,
                content:
                    '\u23f0 No deadlines tracked for this case. Want me to '
                    'check if there are any important deadlines you should '
                    'know about?',
                timestamp: DateTime.now(),
              ));
            });
          }
        }
      }
    } catch (_) {
      // Non-critical — silently ignore errors
    }
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

  // -- Consilium --

  /// Trigger a multi-expert consilium analysis of the current case.
  ///
  /// v1 implementation: reuses the full streaming infrastructure by sending
  /// a structured consilium prompt as a regular user message. The proxy will
  /// eventually consume `mode: "consilium"` natively; until then this
  /// synthetic message produces a substantively equivalent multi-perspective
  /// analysis from the AI.
  ///
  /// Gated on Pro status — the button is hidden for free users so no
  /// quota guard is needed here beyond the standard _sendMessage gate.
  Future<void> _triggerConsilium() async {
    if (_isSending) return;
    const consiliumPrompt =
        '[CONSILIUM] Проведи юридический совет по моему делу от имени четырёх '
        'независимых экспертов: (1) специалист по процессуальному праву, '
        '(2) специалист по материальному праву, '
        '(3) специалист по правам человека и ЕКПЧ, '
        '(4) стратег-адвокат. '
        'Каждый эксперт даёт свою оценку ситуации и рекомендации. '
        'В конце — краткий синтез: согласованная позиция и приоритетные шаги.';
    await _sendMessage(consiliumPrompt);
  }

  // -- Sending --

  Future<void> _sendMessage([String? overrideText]) async {
    final text = (overrideText ?? _messageController.text).trim();
    if (text.isEmpty || _isSending) return;

    // Revenue-critical gate (2026-04-23): if the server quota is known to
    // be exhausted for this free user, show the upgrade dialog instead of
    // hitting claude-proxy. The server also enforces this, but refusing
    // at the UI layer saves a round-trip and prevents the user from
    // seeing "you've used all messages" text bubbles.
    //
    // Bug 1 fix (2026-05-05): also surface a visible SnackBar so the user
    // never thinks the send button "silently no-op'd". The dialog is
    // intrusive but easy to dismiss; the snackbar is the visible error
    // the QA agent expected to see when a send was blocked.
    if (_isQuotaExhausted) {
      unawaited(HapticFeedback.mediumImpact());
      _showQuotaErrorSnackBar();
      _showUpgradeDialog();
      return;
    }

    _messageController.clear();
    unawaited(HapticFeedback.lightImpact());

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
      // BUG 3: the user has engaged — hide the welcome chips regardless
      // of whether they tapped one or typed their own starter.
      _showWelcomeChips = false;
    });
    _scrollToBottom(force: true);

    try {
      final supabase = ref.read(supabaseServiceProvider);

      // Save user message in background — don't block the AI call.
      // This shaves ~100-300ms off perceived latency.
      unawaited(supabase.saveChatMessage(
        caseId: widget.caseId,
        role: 'user',
        content: text,
      ));

      // Check if the message maps to a tool call (intent detection)
      final toolCall = _detectToolIntent(text);

      if (toolCall != null) {
        // Execute tool directly and show rich result
        await _executeToolCall(toolCall.$1, toolCall.$2, supabase);
      } else {
        // Normal AI response flow
        String responseText = '';
        // Phase 2 Pkg 2 — citations from the final ChatResponse for this turn.
        // Captured here so the assistant ChatMessage built below the
        // streaming/non-streaming branches can attach them.
        List<Citation> responseCitations = const [];
        bool usedStreaming = false;
        final ai = ref.read(aiServiceProvider);
        if (ai.isUsingRealAI) {
          // Get user name from auth state for personalization
          final authState = ref.read(authControllerProvider);
          final userName = authState.appUser?.fullName;

          // Real AI is available — use it regardless of demo mode.
          // Use cached context immediately to eliminate 1-2s dead silence.
          // On first message the cache may be empty (preloaded in _loadMessages),
          // so fall back to awaiting the full build only when necessary.
          final String ctx;
          if (_knowledgeService.getCachedContext() != null) {
            ctx = _knowledgeService.getCachedContext()!;
            // Refresh in background for the next message
            unawaited(_knowledgeService.buildClientContext(caseId: widget.caseId));
          } else {
            ctx = await _knowledgeService.buildClientContext(caseId: widget.caseId);
          }

          // ── Phase 2 Pkg 6: legal planner routing ─────────────────
          // Check the planner gate BEFORE streaming. Planner turns are
          // non-streaming (3-pass server loop) and replace the normal path.
          // Gate: Pro user + opt-in toggle + looksLegalish keyword filter.
          // The async plannerEnabledProvider read is synchronous after first
          // build — .valueOrNull gives false if still loading.
          final plannerEnabled =
              ref.read(plannerEnabledProvider).valueOrNull ?? false;
          final isProForPlanner =
              ref.read(aiServiceProvider).isProUser;
          if (shouldRouteToPlanner(
            isPro: isProForPlanner,
            enabledByPref: plannerEnabled,
            looksLegalish: ClaudeService.looksLegalish(text),
          )) {
            // Planner path: non-streaming 3-pass loop via claude-proxy.
            try {
              final plannerSvc = ref.read(legalPlannerServiceProvider);
              final history = _messages
                  .where((m) =>
                      m.role == MessageRole.user ||
                      m.role == MessageRole.assistant)
                  .map((m) => {
                        'role': m.role == MessageRole.user ? 'user' : 'assistant',
                        'content': m.content,
                      })
                  .toList();
              final plannerResult = await plannerSvc.run(
                messages: history,
                systemPrompt: ctx,
                caseId: widget.caseId,
              );
              responseText = plannerResult.replyText;
              responseCitations =
                  Citation.listFromJson(plannerResult.citations);
              usedStreaming = false;

              // Build the PlannerTraceData from the summary returned by
              // the proxy. Sub-questions / counter-args require a separate
              // planner_trace() RPC that is not yet wired here — we
              // pre-populate them as empty lists so the trail card still
              // renders the summary row (latency + regen badge).
              final traceData = PlannerTraceData(
                subQuestions: const [],
                counterArgs: const [],
                evidenceGaps: const [],
                materialGap: false,
                critiqueIssues: const [],
                regeneratedOnce: plannerResult.summary.regeneratedOnce,
                summary: plannerResult.summary,
              );

              await supabase.saveChatMessage(
                caseId: widget.caseId,
                role: 'assistant',
                content: responseText,
              );

              if (mounted) {
                setState(() {
                  _isTyping = false;
                  _messages.add(ChatMessage(
                    id: 'ai_planner_${DateTime.now().millisecondsSinceEpoch}',
                    role: MessageRole.assistant,
                    content: responseText,
                    timestamp: DateTime.now(),
                    citations: responseCitations,
                    plannerTraceData: traceData,
                    isBlockingGap: plannerResult.blockingGap,
                  ));
                });
                _updateChatPhase();
                _scrollToBottom();
                if (_ttsEnabled) unawaited(_speakResponse(responseText));
                _maybeShowIntakeAfterFirstAIResponse();
              }
              // Planner path is complete — skip streaming + non-streaming.
              return;
            } catch (plannerErr) {
              // Planner failure is non-fatal — fall through to normal path.
              debugPrint(
                  'LegalPlanner failed, falling back to normal AI: $plannerErr');
            }
          }

          // ── Try streaming first for word-by-word UI ──────────────
          // Throttle timer declared outside try so catch can clean it up.
          //
          // EXCEPTION: turns that carry an inline image attachment skip
          // streaming. The vision content block must be injected into the
          // last user message in the outgoing API payload, which the
          // current streaming path does not support. Falling through to
          // the non-streaming block below keeps vision correctness and
          // the user still sees "typing…" while Claude analyses the
          // picture.
          Timer? streamUITimer;
          bool streamUIDirty = false;
          final bool hasPendingImage =
              _pendingImageAttachment?.hasInlineImage == true;
          try {
            if (hasPendingImage) {
              // Force the non-streaming fallback below.
              throw const _SkipStreamingForVision();
            }
            final streamingMessageId = 'ai_stream_${DateTime.now().millisecondsSinceEpoch}';
            final streamingMessage = ChatMessage(
              id: streamingMessageId,
              role: MessageRole.assistant,
              content: '',
              timestamp: DateTime.now(),
            );

            // Reasoning Trail v1 (2026-05-05): open a fresh per-turn
            // event broadcaster BEFORE we start consuming the stream.
            // The ReasoningTrail widget renders just above this message
            // and listens to the controller for thinking + tool stages.
            // Closed once the stream finishes (or in catch / finally).
            unawaited(_trailController?.close());
            _trailController = StreamController<ChatStreamEvent>.broadcast();

            setState(() {
              _isTyping = false; // Hide legacy typing indicator — Trail takes over
              _messages.add(streamingMessage);
            });
            _scrollToBottom(force: true);

            // Fresh MessageSpeaker for this reply — guarantees exactly
            // one speak() call once streaming completes, regardless of
            // how many chunks arrive. See message_speaker.dart.
            final voice = ref.read(voiceServiceProvider);
            _messageSpeaker = MessageSpeaker(
              speaker: VoiceServiceSpeaker(voice),
              langCode: Localizations.localeOf(context).languageCode,
              enabled: _ttsEnabled,
            );

            final fullText = StringBuffer();

            // Stop button (Cursor consilium Gap #1, 2026-05-05): consume
            // the event stream via .listen() so _stopStreaming() can
            // .cancel() the subscription mid-flight. Behaviour-equivalent
            // to the prior `await for` — handlers below are the loop body.
            // Reset stop flag at start of each turn.
            _stoppedByUser = false;
            _currentStreamFullText = fullText;
            _currentStreamMessageId = streamingMessageId;
            final streamDone = Completer<void>();
            _streamDoneCompleter = streamDone;
            unawaited(_aiSub?.cancel() ?? Future<void>.value());
            _aiSub = ai
                .sendChatMessageStreamingEvents(
              caseId: widget.caseId,
              message: text,
              userLanguage: Localizations.localeOf(context).languageCode,
              userName: userName,
              clientContext: ctx,
              caseType: _currentCase?.type,
              country: 'estonia',
              nationality: _currentCase?.nationality,
              freeLimitMessage: AppLocalizations.of(context)?.freeLimitReached(AIService.freeTotalLimit),
            )
                .listen(
              (event) {
                // Forward EVERY event to the trail so it can light up the
                // pill on thinking / tool_use / tool_result / message_done.
                _trailController?.add(event);

                // TextDelta: still drives the existing buffer + TTS chunk
                // feed exactly as before. Non-text events do not touch the
                // text buffer or the speaker.
                if (event is TextDelta) {
                  final chunk = event.text;
                  fullText.write(chunk);
                  streamUIDirty = true;
                  streamUITimer ??= Timer.periodic(const Duration(milliseconds: 50), (_) {
                    if (streamUIDirty && mounted) {
                      streamUIDirty = false;
                      setState(() {
                        final idx = _messages.indexWhere((m) => m.id == streamingMessageId);
                        if (idx >= 0) {
                          _messages[idx] = ChatMessage(
                            id: streamingMessageId,
                            role: MessageRole.assistant,
                            content: fullText.toString(),
                            timestamp: DateTime.now(),
                          );
                        }
                      });
                      _scrollToBottom();
                    }
                  });

                  // Stream the chunk into the speaker's buffer. No audio is
                  // produced here — MessageSpeaker speaks the FULL accumulated
                  // reply once onStreamComplete() fires, so ElevenLabs /
                  // Chirp3 / Gemini receive one continuous text and return
                  // one continuous voice. Sentence-level streaming was
                  // rejected by owner 22.04.2026.
                  _messageSpeaker?.onChunk(chunk);
                }
              },
              onError: (Object e, StackTrace st) {
                if (!streamDone.isCompleted) streamDone.completeError(e, st);
              },
              onDone: () {
                if (!streamDone.isCompleted) streamDone.complete();
              },
              cancelOnError: true,
            );
            try {
              await streamDone.future;
            } finally {
              await _aiSub?.cancel();
              _aiSub = null;
              _streamDoneCompleter = null;
              _currentStreamFullText = null;
              _currentStreamMessageId = null;
            }

            // Speak the full accumulated reply exactly once now that
            // streaming is finished. Fire-and-forget — the audio will
            // play while the UI continues (history save, typing-off,
            // scroll). `await` here would block the UI behind TTS.
            //
            // Stop button (2026-05-05): skip TTS when the user cancelled
            // mid-stream — they don't want the partial reply read out.
            if (_ttsEnabled && !_stoppedByUser) {
              setState(() => _voiceState = VoiceButtonState.speaking);
              unawaited(_messageSpeaker!.onStreamComplete().then((_) {
                if (mounted) {
                  setState(() => _voiceState = VoiceButtonState.idle);
                }
              }));
            }

            // Clean up the throttle timer.
            streamUITimer?.cancel();
            streamUITimer = null;

            // Reasoning Trail: emit terminal MessageDone (in case the
            // upstream stream didn't already), close, and clear so the
            // pill collapses and disappears.
            _trailController?.add(const MessageDone());
            await _trailController?.close();
            if (mounted) {
              setState(() {
                _trailController = null;
              });
            } else {
              _trailController = null;
            }

            responseText = fullText.toString();
            _knowledgeService.notifyMessageSent();

            // Final setState to ensure the complete text is displayed.
            if (mounted) {
              setState(() {
                final idx = _messages.indexWhere((m) => m.id == streamingMessageId);
                if (idx >= 0) {
                  _messages[idx] = ChatMessage(
                    id: streamingMessageId,
                    role: MessageRole.assistant,
                    content: responseText,
                    timestamp: DateTime.now(),
                  );
                }
              });
            }

            usedStreaming = true;
          } catch (e) {
            // Cancel throttle timer on error.
            streamUITimer?.cancel();
            streamUITimer = null;
            // Close the trail on error — pill collapses, doesn't hang.
            await _trailController?.close();
            _trailController = null;
            debugPrint('Streaming failed, falling back to non-streaming: $e');
            // Remove any leftover streaming placeholder.
            if (mounted) {
              setState(() {
                _messages.removeWhere(
                    (m) => m.id.startsWith('ai_stream_'));
                _isTyping = true; // Re-show typing indicator for fallback
              });
            }
          }

          // ── Fallback: non-streaming path (also handles tool_use) ──
          if (!usedStreaming) {
            // Consume the staged image attachment exactly once per turn.
            final ChatAttachment? imageAttachment = _pendingImageAttachment;
            _pendingImageAttachment = null;

            final response = await ai.sendChatMessage(
              caseId: widget.caseId,
              message: text,
              userLanguage: Localizations.localeOf(context).languageCode,
              userName: userName,
              clientContext: ctx,
              caseType: _currentCase?.type,
              country: 'estonia',
              nationality: _currentCase?.nationality,
              freeLimitMessage: AppLocalizations.of(context)?.freeLimitReached(AIService.freeTotalLimit),
              imageAttachment: imageAttachment,
            );
            _knowledgeService.notifyMessageSent();

            // ── Handle Claude tool_use responses ──────────────────────
            if (response.hasToolUse && response.toolUseResponse != null && mounted) {
              final bridge = ChatToolBridge(context: context, ref: ref);
              final toolResults = await bridge.executeToolCalls(response.toolUseResponse!);

              for (final tr in toolResults) {
                // Show Claude's accompanying text if present (only once)
                if (tr.claudeText != null && tr.claudeText!.isNotEmpty) {
                  await supabase.saveChatMessage(
                    caseId: widget.caseId,
                    role: 'assistant',
                    content: tr.claudeText!,
                  );
                  if (mounted) {
                    setState(() {
                      _messages.add(ChatMessage(
                        id: 'ai_text_${DateTime.now().millisecondsSinceEpoch}',
                        role: MessageRole.assistant,
                        content: tr.claudeText!,
                        timestamp: DateTime.now(),
                      ));
                    });
                    _scrollToBottom();
                  }
                }

                // Show the tool result card
                await supabase.saveChatMessage(
                  caseId: widget.caseId,
                  role: 'assistant',
                  content: tr.displayText,
                );
                if (mounted) {
                  setState(() {
                    _messages.add(ChatMessage(
                      id: 'tool_${DateTime.now().millisecondsSinceEpoch}',
                      role: MessageRole.toolResult,
                      content: tr.displayText,
                      timestamp: DateTime.now(),
                      contentType: MessageContentType.toolCard,
                      toolResult: tr.toolResult,
                      navigation: tr.navigation,
                    ));
                  });
                  _scrollToBottom();
                }
              }

              // Perform navigation from the first tool result (if any)
              if (mounted) {
                await bridge.performNavigations(toolResults);
              }

              // After showing tool results, ask Claude for follow-up / generation
              if (toolResults.isNotEmpty && mounted) {
                try {
                  // Check if any tool result has claudeText (generation prompt)
                  final claudePrompt = toolResults
                      .where((tr) => tr.toolResult?.claudeText != null)
                      .map((tr) => tr.toolResult!.claudeText!)
                      .join('\n\n');

                  final String followUpMessage;
                  if (claudePrompt.isNotEmpty) {
                    // Tool wants Claude to generate content (draft, analysis, translation)
                    followUpMessage = claudePrompt;
                  } else {
                    // Standard follow-up: summarize tool results and suggest next steps
                    final toolSummary = ChatToolBridge.buildFollowUpSummary(toolResults);
                    followUpMessage = 'I just ran a tool on behalf of the client. Here is what happened:\n\n'
                        '$toolSummary\n\n'
                        'Based on the above result, tell the client what this means for '
                        'their case and suggest 1-2 concrete next steps they should take. '
                        'Be specific — reference actual data from the result. '
                        'Keep it concise (2-3 sentences).';
                  }

                  final followUp = await ai.sendChatMessage(
                    caseId: widget.caseId,
                    message: followUpMessage,
                    userLanguage: Localizations.localeOf(context).languageCode,
                    userName: authState.appUser?.fullName,
                    clientContext: ctx,
                    caseType: _currentCase?.type,
                    country: 'estonia',
                    nationality: _currentCase?.nationality,
                    freeLimitMessage: AppLocalizations.of(context)?.freeLimitReached(AIService.freeTotalLimit),
                  );

                  if (mounted && followUp.message.trim().isNotEmpty) {
                    await supabase.saveChatMessage(
                      caseId: widget.caseId,
                      role: 'assistant',
                      content: followUp.message,
                    );
                    setState(() {
                      _messages.add(ChatMessage(
                        id: 'followup_${DateTime.now().millisecondsSinceEpoch}',
                        role: MessageRole.assistant,
                        content: followUp.message,
                        timestamp: DateTime.now(),
                      ));
                    });
                    _scrollToBottom();

                    if (_ttsEnabled) unawaited(_speakResponse(followUp.message));
                  }
                } catch (e) {
                  debugPrint('Follow-up suggestion failed (non-fatal): $e');
                }
              }

              if (mounted) {
                setState(() => _isTyping = false);
                _updateChatPhase();
                _scrollToBottom();
              }
              return; // Tool results handled — skip normal text flow
            }

            responseText = response.message;
            // Phase 2 Pkg 2 — capture grounded citations for the bubble.
            responseCitations = response.citations;
          }

          // Guard against empty responses (e.g. tool_use only).
          if (responseText.trim().isEmpty) {
            responseText = 'Ошибка: AI вернул пустой ответ. Попробуйте ещё раз или перезагрузите страницу.';
          }
        } else {
          // No AI backend configured — this is a real configuration issue,
          // not a demo mode. Surface it so the owner can fix it.
          responseText = 'Ошибка: AI не настроен (SUPABASE_URL/ANON_KEY не baked в сборку). Свяжитесь с поддержкой support@advocat.ee';
        }

        await supabase.saveChatMessage(
          caseId: widget.caseId,
          role: 'assistant',
          content: responseText,
        );

        if (mounted) {
          if (!usedStreaming) {
            final aiMessage = ChatMessage(
              id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
              role: MessageRole.assistant,
              content: responseText,
              timestamp: DateTime.now(),
              citations: responseCitations,
            );
            setState(() {
              _isTyping = false;
              _messages.add(aiMessage);
            });
          } else {
            setState(() {
              _isTyping = false;
            });
          }
          _updateChatPhase();
          _scrollToBottom();

          // For non-streaming path, speak the full response at once.
          // Streaming path already speaks sentence-by-sentence above.
          if (_ttsEnabled && !usedStreaming) {
            unawaited(_speakResponse(responseText));
          }

          // Show intake gate after first AI response (post-launch UX 2026-05-08).
          _maybeShowIntakeAfterFirstAIResponse();
        }
      }
    } catch (e, stackTrace) {
      debugPrint('ChatScreen._sendMessage error: $e\n$stackTrace');
      if (mounted) {
        // Show real error instead of demo fallback — hiding errors caused
        // users to see "кража в магазине" when real AI was failing.
        final l10n = AppLocalizations.of(context);
        String userFacingMessage;

        // Pre-launch (2026-04-29): the proxy now forwards a structured
        // error code for Anthropic 429 / 529. Prefer the typed channel
        // over substring matching when available.
        if (e is ClaudeServiceException && e.errorCode == 'rate_limit') {
          userFacingMessage = l10n?.aiErrorRateLimit ??
              'The service is temporarily overloaded. Please try again in 1-2 minutes.';
          // Bug 1 fix (2026-05-05): also surface a visible SnackBar so
          // the user gets immediate feedback at the input bar, not just
          // an assistant chat bubble that scrolls away.
          _showQuotaErrorSnackBar(
              reasonOverride: QuotaDenialReason.rateLimit);
        } else if (e is ClaudeServiceException && e.errorCode == 'overload') {
          userFacingMessage = l10n?.aiErrorOverload ??
              'The AI is busy right now, please try again in a minute.';
        } else {
          // Legacy substring fallback for code paths that have not been
          // migrated to typed errors yet.
          final errorMsg = e.toString().toLowerCase();
          if (errorMsg.contains('rate limit') || errorMsg.contains('429')) {
            userFacingMessage = l10n?.aiErrorRateLimit ??
                'Слишком много запросов подряд. Подождите минуту и попробуйте снова.';
          } else if (errorMsg.contains('overload') ||
              errorMsg.contains('529')) {
            userFacingMessage = l10n?.aiErrorOverload ??
                'AI сейчас занят, попробуйте через минуту.';
          } else if (errorMsg.contains('unauthorized') || errorMsg.contains('401')) {
            userFacingMessage = 'Требуется вход в аккаунт для использования AI. Зарегистрируйтесь или войдите.';
          } else if (errorMsg.contains('quota') || errorMsg.contains('free limit')) {
            userFacingMessage = 'Достигнут лимит бесплатных сообщений. Оформите подписку для продолжения.';
          } else {
            userFacingMessage = 'Временная ошибка AI. Попробуйте ещё раз через минуту. Если не работает — напишите в поддержку.';
          }
        }
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(
            id: 'ai_error_${DateTime.now().millisecondsSinceEpoch}',
            role: MessageRole.assistant,
            content: userFacingMessage,
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        unawaited(_loadFreeMessageCount()); // refresh counter after each message
      }
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
      r'(?:check|проверь?|проверить|проверка|найти|узнай|kontrolli|otsi)\s+(?:company|firm|фирму?|компанию?|работодател[яь]?|employer|ettevõtet|firmat?)\s+(.+)',
      caseSensitive: false,
    ).firstMatch(lower);
    if (companyMatch != null) {
      return ('check_company', {'company_name': companyMatch.group(1)!.trim()});
    }

    // Check vehicle: "check plate ABC123", "проверь авто ABC123"
    final vehicleMatch = RegExp(
      r'(?:check|проверь?|проверить|проверка|kontrolli)\s+(?:vehicle|car|plate|авто|машину?|номер|sõidukit|autot?|numbrimärki)\s+([A-Za-z0-9\- ]+)',
      caseSensitive: false,
    ).firstMatch(lower);
    if (vehicleMatch != null) {
      return ('check_vehicle', {'plate_number': vehicleMatch.group(1)!.trim().toUpperCase()});
    }

    // Create case: "create case", "создай дело", "new case"
    if (RegExp(r'(?:create|open|new|создай|открой|новое|loo|alusta)\s+(?:case|дело|кейс|juhtumi?)', caseSensitive: false).hasMatch(lower)) {
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
    if (RegExp(r'(?:find|search|найти|ищу|подскажи|otsi|leia)\s*(?:lawyer|attorney|адвокат|юрист|advokaati?|juristi?)', caseSensitive: false).hasMatch(lower)) {
      return ('find_lawyer', {'country': 'estonia'});
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
      r'(?:translate|переведи|перевод|tõlgi)\s+(.+?)\s+(?:to|на|keelde)\s+(english|finnish|russian|german|estonian|eesti|en|fi|ru|de|et)',
      caseSensitive: false,
    ).firstMatch(lower);
    if (translateMatch != null) {
      final langMap = {
        'english': 'en', 'finnish': 'fi', 'russian': 'ru', 'german': 'de',
        'estonian': 'et', 'eesti': 'et',
        'en': 'en', 'fi': 'fi', 'ru': 'ru', 'de': 'de', 'et': 'et',
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
          final nav = execResult.navigation!;
          if (nav.route == '__pop__') {
            // Pop immediately for "back" actions
            await executor.performNavigation(nav);
          } else {
            // Show cancelable navigation preview toast
            final l10n = AppLocalizations.of(context);
            final screenName = nav.route.split('/').last;
            bool cancelled = false;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${l10n?.navigatingTo ?? "Opening"} $screenName...',
                      ),
                    ),
                  ],
                ),
                action: SnackBarAction(
                  label: l10n?.stayInChat ?? 'Stay in chat',
                  textColor: Colors.white,
                  onPressed: () {
                    cancelled = true;
                  },
                ),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppColors.primary,
              ),
            );

            await Future.delayed(const Duration(seconds: 2));

            if (!cancelled && mounted) {
              await executor.performNavigation(nav);
            }
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
            content: 'Tool execution failed. Please try again.',
            timestamp: DateTime.now(),
          ));
        });
      }
    }
  }


  void _scrollToBottom({bool animated = true, bool force = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final pos = _scrollController.position;
      // Only auto-scroll if user is already near the bottom (within 150px)
      // or if force is true (e.g. user just sent a message).
      if (!force && pos.maxScrollExtent - pos.pixels > 150) return;
      final target = pos.maxScrollExtent;
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

  // ── PDF export ────────────────────────────────────────────────────────────

  /// Pluggable PDF service hook so widget tests can inject a fake.
  /// Production callers leave this null and we lazy-instantiate.
  PdfService? _pdfServiceOverride;
  PdfService get _pdfService => _pdfServiceOverride ?? PdfService();

  /// Renders [message]'s markdown content into a PDF and triggers a browser
  /// download / share sheet. Best-effort: any failure surfaces as a snack
  /// rather than crashing the chat.
  Future<void> _downloadMessageAsPdf(ChatMessage message) async {
    unawaited(HapticFeedback.lightImpact());
    final lang = Localizations.localeOf(context).languageCode;
    final title = _draftTitleFromContent(message.content);
    final filename = _draftFilenameFor(title, lang);

    try {
      final bytes = await _pdfService.renderLegalDocument(
        markdown: message.content,
        title: title,
        language: lang,
      );
      // sharePdf works on iOS/Android natively and triggers a download on
      // Flutter Web (the printing package handles the platform split).
      await Printing.sharePdf(bytes: bytes, filename: filename);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export PDF: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// Pull a sensible PDF title out of the message — the first `# Heading` if
  /// present, otherwise a generic fallback.
  String _draftTitleFromContent(String content) {
    final m = RegExp(r'^#\s+(.+)$', multiLine: true).firstMatch(content);
    if (m != null) {
      return m.group(1)!.trim();
    }
    return 'Legal Document';
  }

  /// Build a download filename from [title] + language. Strips characters that
  /// are unsafe in filenames; truncates to a reasonable length.
  String _draftFilenameFor(String title, String lang) {
    final cleaned = title
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    final truncated =
        cleaned.length > 40 ? cleaned.substring(0, 40) : cleaned;
    final stem = truncated.isEmpty ? 'advocat_document' : truncated;
    return '${stem}_$lang.pdf';
  }

  // ── Feedback (👍 / 👎) ────────────────────────────────────────────────

  /// Cache of stored ratings so we don't re-fetch on every rebuild.
  /// Key = ChatMessage.id. -2 sentinel means "not loaded yet".
  final Map<String, int?> _feedbackCache = <String, int?>{};

  /// True if [message] looks like an AI message that is still streaming
  /// content in (id starts with `ai_stream_`). We hide the feedback
  /// buttons until the response is complete so users don't rate a
  /// half-typed answer.
  bool _isStreamingMessage(ChatMessage message) {
    return message.id.startsWith('ai_stream_');
  }

  /// Find the user message that immediately preceded [aiMessage] so we
  /// can store a 500-char preview of the actual question alongside the
  /// rating. Returns null if no user message was found before the AI msg.
  String? _previousUserMessage(ChatMessage aiMessage) {
    final idx = _messages.indexWhere((m) => m.id == aiMessage.id);
    if (idx <= 0) return null;
    for (int i = idx - 1; i >= 0; i--) {
      if (_messages[i].role == MessageRole.user) {
        return _messages[i].content;
      }
    }
    return null;
  }

  Widget _buildFeedbackButtons(ChatMessage aiMessage) {
    final messageId = aiMessage.id;
    final feedbackService = ref.read(feedbackServiceProvider);

    // Lazy first-load: kick off a fetch for the stored rating exactly
    // once per message id, then cache the result.
    if (!_feedbackCache.containsKey(messageId)) {
      _feedbackCache[messageId] = null; // optimistic placeholder
      // Fire-and-forget; result is folded into the cache and we rebuild.
      feedbackService.getFeedback(messageId).then((rec) {
        if (!mounted) return;
        if (rec != null && _feedbackCache[messageId] != rec.rating) {
          setState(() => _feedbackCache[messageId] = rec.rating);
        }
      }).catchError((_) {
        // Silent — feedback is non-critical.
      });
    }

    final initialRating = _feedbackCache[messageId];

    return FeedbackButtons(
      key: ValueKey('feedback_$messageId'),
      messageId: messageId,
      initialRating: initialRating,
      onSubmit: (rating, comment) async {
        // Locale -> 'et' / 'en' / 'ru' / 'uk' / etc.
        final locale = Localizations.localeOf(context).languageCode;
        // Cheap secondary detect on the AI text — useful when user
        // overrode their profile language for this turn.
        final detected = LanguageDetector.detect(aiMessage.content) ?? locale;

        await feedbackService.submitFeedback(
          messageId: messageId,
          rating: rating,
          caseId: widget.caseId,
          comment: comment,
          aiResponse: aiMessage.content,
          userMessage: _previousUserMessage(aiMessage),
          language: detected,
          // Model is not currently surfaced on the message; leaving null
          // so the column stores the DB default. Wire-through can be
          // added when ai_service exposes it on ChatMessage.metadata.
        );

        if (!mounted) return;
        setState(() => _feedbackCache[messageId] = rating);
      },
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
          // Status bar with free message counter
          _buildStatusBar(),

          // Upgrade banner (after 3+ user messages, dismissible)
          if (!_upgradeBannerDismissed &&
              _messages.where((m) => m.role == MessageRole.user).length >= 3 &&
              !ref.read(aiServiceProvider).isProUser)
            _buildUpgradeBanner(),

          // Disclaimer banner
          _buildDisclaimerBanner(),

          // Messages with subtle gradient background
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF5F3F0), // slightly lighter top
                    Color(0xFFECEAE6), // slightly darker bottom
                  ],
                ),
              ),
              child: _buildMessageList(),
            ),
          ),

          // Quick action chips
          if (!_isSending) _buildQuickActions(),

          // Pkg 9 — Critical-deadline banner for the active case.
          // Renders nothing when no active case OR no deadline ≤ 3d OR
          // the user already dismissed the current urgency band.
          const DeadlineBanner(),

          // Pkg 1.D — Case Memory composer chip. Shows the active case
          // badge (or a "Link to case" chip) above the input bar so the
          // user always knows whether the next message will be folded
          // into a case file by claude-proxy (Pkg 1.B).
          const ActiveCaseChip(),

          // Quota-exhausted inline banner — sits immediately above the
          // input bar when the free limit is hit. Complements the upgrade
          // CTA inside the input bar; visible even if the user has not
          // dismissed a prior snackbar.
          if (_isQuotaExhausted && !ref.read(aiServiceProvider).isProUser)
            _buildQuotaExhaustedBanner(),

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
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surface,
              AppColors.accent.withValues(alpha: 0.04),
            ],
          ),
        ),
      ),
      title: Row(
        children: [
          // AI avatar — pulsing with glow
          const _PulsingAvatar(),
          const SizedBox(width: AppSpacing.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.caseName ?? AppLocalizations.of(context)!.aiAssistant,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Row(
                  children: [
                    _OnlineDot(isTyping: _isTyping),
                    const SizedBox(width: 5),
                    Text(
                      _isTyping ? (AppLocalizations.of(context)?.typing ?? 'Typing...') : (AppLocalizations.of(context)?.online ?? 'Online'),
                      style: TextStyle(
                        fontSize: 12,
                        color: _isTyping
                            ? AppColors.warning
                            : AppColors.success,
                        fontWeight: FontWeight.w500,
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
        // Case File — opens the auto-built dossier scoped to this case.
        IconButton(
          key: const Key('chat_open_case_file'),
          icon: const Icon(Icons.folder_open_outlined, size: 22),
          tooltip: AppLocalizations.of(context)?.caseFileTitle ?? 'Case File',
          onPressed: () {
            final cid = widget.caseId;
            final qs = (cid.isNotEmpty && cid != 'general') ? '?caseId=$cid' : '';
            context.push('/case-file$qs');
          },
        ),
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
        // Voice gender toggle (male / female)
        IconButton(
          icon: Icon(
            ref.read(voiceServiceProvider).voiceGender == VoiceGender.male
                ? Icons.record_voice_over_rounded
                : Icons.record_voice_over_outlined,
            color: AppColors.textTertiary,
            size: 20,
          ),
          tooltip: ref.read(voiceServiceProvider).voiceGender == VoiceGender.male
              ? 'Switch to female voice'
              : 'Switch to male voice',
          onPressed: () {
            final voice = ref.read(voiceServiceProvider);
            final newGender = voice.voiceGender == VoiceGender.male
                ? VoiceGender.female
                : VoiceGender.male;
            voice.setVoiceGender(newGender);
            setState(() {});
            HapticFeedback.selectionClick();
          },
        ),
        IconButton(
          icon: const Icon(Icons.attach_file_rounded),
          tooltip: 'Attach document',
          onPressed: _showAttachOptions,
        ),
        // User profile avatar
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: GestureDetector(
            onTap: () => context.push('/settings'),
            child: _buildUserAvatar(),
          ),
        ),
      ],
    );
  }

  Widget _buildUserAvatar() {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final name = user?.fullName ?? '';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

    if (user?.avatarUrl != null) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: NetworkImage(user!.avatarUrl!),
      );
    }
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.accent],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
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
                Text('🇪🇪', style: TextStyle(fontSize: 14)),
                SizedBox(width: 4),
                Text(
                  'EE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Free message counter
          if (!ref.read(aiServiceProvider).isProUser &&
              _freeMessagesUsed > 0) ...[
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _freeMessagesUsed >= _freeMessagesTotal - 5
                    ? AppColors.warning.withValues(alpha: 0.12)
                    : AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 12,
                    color: _freeMessagesUsed >= _freeMessagesTotal - 5
                        ? AppColors.warning
                        : AppColors.accent,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '$_freeMessagesUsed/$_freeMessagesTotal',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _freeMessagesUsed >= _freeMessagesTotal - 5
                          ? AppColors.warning
                          : AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
          ],

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

  // -- Quota error snackbar (Bug 1 fix, 2026-05-05) --

  /// Surface a visible SnackBar when a send is denied. Differentiates
  /// between anon (demo limit), logged-in free (free quota exhausted),
  /// and rate-limit (transient). See `quota_error_snackbar.dart` for the
  /// pure helper this delegates to.
  ///
  /// QA agent observation today: "After Pro upgrade banner appeared
  /// mid-session, my next 2 send-button clicks silently no-op'd." Without
  /// this snackbar the user got no feedback at all — they assumed the
  /// app was broken.
  void _showQuotaErrorSnackBar({QuotaDenialReason? reasonOverride}) {
    if (!mounted) return;

    final QuotaDenialReason reason;
    if (reasonOverride != null) {
      reason = reasonOverride;
    } else {
      final authState = ref.read(authControllerProvider);
      final ai = ref.read(aiServiceProvider);
      final isAnon = authState.appUser == null;
      final inferred = QuotaDenialReason.fromQuota(
        isAnon: isAnon,
        remaining: _freeMessagesRemaining < 0 ? 1 : _freeMessagesRemaining,
        isPro: ai.isProUser,
      );
      // Defensive: if nothing was inferred (e.g. pro user somehow
      // arrived here), bail rather than show a misleading message.
      if (inferred == null) return;
      reason = inferred;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      buildQuotaErrorSnackBar(
        context: context,
        reason: reason,
        onSignUp: () => context.push(AppRoutes.register),
        onUpgrade: () => context.push(AppRoutes.subscription),
      ),
    );
  }

  // -- Upgrade dialog (quota exhausted) --

  /// Shown when a free user tries to send while
  /// `allowed == false` (i.e. the server quota is exhausted). Gives them
  /// a single primary action: go to the subscription page.
  void _showUpgradeDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('quota_exhausted_dialog'),
        title: const Text('Лимит бесплатных сообщений'),
        content: Text(
          'Вы использовали все ${AIService.freeTotalLimit} бесплатных '
          'сообщений. Оформите Advocat Pro за €19.99/мес для неограниченного '
          'доступа к AI-консультациям.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Позже'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.push(AppRoutes.subscription);
            },
            child: const Text('Advocat Pro — €19.99/мес'),
          ),
        ],
      ),
    );
  }

  // -- Upgrade banner --

  Widget _buildUpgradeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withValues(alpha: 0.08),
            AppColors.primary.withValues(alpha: 0.06),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppColors.accent.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.workspace_premium_rounded,
            size: 18,
            color: AppColors.accent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              // v24.2.3 UX-Tier-A: localised (was hardcoded EN)
              AppLocalizations.of(context)?.upgradeBannerTitle ??
                  'Upgrade for unlimited consultations',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
              ),
            ),
          ),
          SizedBox(
            height: 28,
            child: TextButton(
              onPressed: () => context.push(AppRoutes.subscription),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text(
                // v24.2.3 UX-Tier-A: localised
                AppLocalizations.of(context)?.upgradeBannerCta ?? 'Upgrade',
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => setState(() => _upgradeBannerDismissed = true),
            child: const Icon(
              Icons.close_rounded,
              size: 16,
              color: AppColors.textTertiary,
            ),
          ),
        ],
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

    // BUG 3: add one trailing slot for the welcome chips when active.
    final chipsSlot = _showWelcomeChips ? 1 : 0;
    // Quick Profile intake slot (2026-05-05): rendered just after the
    // welcome chips slot when both are simultaneously active. In
    // practice they don't usually co-render — the intake is a global
    // first-launch prompt while welcome chips are per-empty-case — but
    // the layout supports it cleanly.
    final intakeSlot = _showQuickProfile ? 1 : 0;
    final typingSlot = _isTyping ? 1 : 0;
    // Reasoning Trail v1 (2026-05-05): when a streaming turn is active
    // (controller is non-null), render the visible-thinking pill in its own
    // ListView slot just below the messages.
    final trailSlot = _trailController != null ? 1 : 0;
    // fix/copy-selection: wrap the message list in SelectionArea so users
    // can drag-select text across bubbles on Flutter Web without the
    // per-bubble GestureDetector swallowing pan events. This is the
    // Flutter-recommended pattern (docs: SelectionArea, Flutter 3.3+).
    return SelectionArea(
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        itemCount: _messages.length +
            chipsSlot +
            intakeSlot +
            typingSlot +
            trailSlot,
        itemBuilder: (context, index) {
          // Order: messages → welcome chips (if active) → quick-profile
          // intake (if active) → typing indicator → reasoning trail.
          if (_showWelcomeChips && index == _messages.length) {
            final locale = Localizations.localeOf(context).languageCode;
            return ChatWelcomeChips(
              locale: locale,
              onCategorySelected: _onWelcomeCategoryPicked,
              onSkip: _onWelcomeSkip,
            );
          }
          final messagesAndChips = _messages.length + chipsSlot;
          if (_showQuickProfile && index == messagesAndChips) {
            final locale = Localizations.localeOf(context).languageCode;
            return QuickProfileIntake(
              locale: locale,
              onAnswer: _onQuickProfileAnswer,
              onSkip: _onQuickProfileSkip,
            );
          }
          final messagesChipsIntake = messagesAndChips + intakeSlot;
          if (index == messagesChipsIntake && _isTyping) {
            return _buildTypingIndicator();
          }
          // ReasoningTrail slot: appended right after typing/messages so
          // it sits immediately below the streaming assistant bubble.
          if (_trailController != null &&
              index == messagesChipsIntake + typingSlot) {
            return ReasoningTrail(
              key: ValueKey(_trailController.hashCode),
              events: _trailController!.stream,
            );
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
      ),
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
    // Blocking-gap messages are clarifying questions from the AI — give them
    // a distinct amber tint so the user knows they need to respond with info.
    final isBlockingGap = !isUser && message.isBlockingGap;

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
                gradient: isUser
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.accent, AppColors.accentDark],
                      )
                    : null,
                color: isUser
                    ? null
                    : isBlockingGap
                        ? const Color(0xFFFFF8E1) // amber-50 tint
                        : AppColors.surface,
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
                    : Border.all(
                        color: isBlockingGap
                            ? const Color(0xFFFFB300) // amber accent border
                            : AppColors.border,
                        width: isBlockingGap ? 1.0 : 0.5,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: (isUser
                            ? AppColors.accent
                            : Colors.black)
                        .withValues(alpha: isUser ? 0.20 : 0.06),
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

            // Phase 2 Pkg 6 — Planner Reasoning Trail.
            // Renders below the assistant bubble when the message was
            // produced by the three-pass legal planner loop (Pro + opt-in).
            if (!isUser && message.plannerTraceData != null)
              PlannerTrail(
                key: ValueKey('planner_trail_${message.id}'),
                data: message.plannerTraceData!,
              ),

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
                    // PDF download — only for messages that look like a
                    // legal-draft output and only once streaming finishes
                    // (avoid mid-stream exports of half-typed documents).
                    if (!_isStreamingMessage(message) &&
                        PdfService.looksLikeDraft(message.content)) ...[
                      const SizedBox(width: 8),
                      Tooltip(
                        message: 'Download as PDF',
                        child: GestureDetector(
                          key: ValueKey('pdf_download_${message.id}'),
                          onTap: () => _downloadMessageAsPdf(message),
                          child: const Icon(
                            Icons.picture_as_pdf,
                            size: 14,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ],
                    // Feedback thumbs (👍/👎) for completed AI messages.
                    // Hidden while the message is still streaming in.
                    if (!_isStreamingMessage(message)) ...[
                      const SizedBox(width: 8),
                      _buildFeedbackButtons(message),
                    ],
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
            onApprove: () async {
              // Handle approval -- execute the real action
              if (message.toolResult?.cardType == 'email_draft') {
                final data = message.toolResult?.data ?? {};
                final sendVia = data['send_via'] as String?;

                // v24.1: if the tool emitted `send_via: 'send-email'` we
                // dispatch via the Edge Function (real server-side send).
                // Otherwise we fall back to the legacy mailto: flow used by
                // the old draft_email tool.
                if (sendVia == 'send-email') {
                  final supabase = ref.read(supabaseServiceProvider);
                  final resp = await supabase.callEdgeFunction(
                    'send-email',
                    body: {
                      'to': data['to'],
                      if (data['cc'] != null) 'cc': data['cc'],
                      'subject': data['subject'],
                      'body': data['body'],
                      if (data['case_id'] != null)
                        'case_id': data['case_id'],
                    },
                  );
                  if (!mounted) return;
                  if (resp != null && resp['ok'] == true) {
                    final provider = resp['provider'] ?? 'provider';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Email sent via $provider.'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    // Report success back so Claude can confirm in-chat
                    // and proceed with the next step.
                    unawaited(_sendMessage(
                        '[system] send_email succeeded via $provider '
                        'to ${data['to']}. Confirm to the user briefly '
                        'in their language and ask what is next.'));
                  } else {
                    final err = (resp?['error'] as String?) ??
                        'email dispatch failed (no response from server)';
                    final details = resp?['details'] as String?;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Email not sent: $err'),
                        backgroundColor: AppColors.error,
                        duration: const Duration(seconds: 6),
                      ),
                    );
                    // Feed the error back so Claude can explain to the user
                    // instead of silently failing.
                    unawaited(_sendMessage(
                        '[system] send_email FAILED: $err'
                        '${details != null ? ' — $details' : ''}. '
                        'Apologise to the user in their language, explain '
                        'the email was NOT sent, and offer to try again or '
                        'open the email client via draft_email (mailto:).'));
                  }
                } else {
                  // Legacy draft_email path: open mailto:
                  final to = data['to'] as String? ?? '';
                  final subject = data['subject'] as String? ?? '';
                  final body = data['body'] as String? ?? '';
                  final uri = Uri(
                    scheme: 'mailto',
                    path: to,
                    queryParameters: {
                      'subject': subject,
                      'body': body,
                    },
                  );
                  unawaited(launchUrl(uri));
                }
              } else if (message.navigation != null) {
                final executor = ToolExecutor(context: context, ref: ref);
                unawaited(executor.performNavigation(message.navigation!));
              }
            },
            // BUG#4 fix (2026-04-29): structured tool_result reply.
            // Cancel and timeout produce different `type` values so the
            // AI can branch on the outcome (apologise vs offer
            // alternative vs retry). The 5-min auto-timeout in the
            // approval bar prevents indefinite dangling tool_use turns.
            onRejectWithReason: (outcome) {
              _sendMessage(outcome.toSystemMessage());
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

      // Markdown headers: ## Следующие шаги (and any ##/# heading)
      if (trimmed.startsWith('## ') || trimmed.startsWith('# ')) {
        final headerText = trimmed.startsWith('## ')
            ? trimmed.substring(3).trim()
            : trimmed.substring(2).trim();
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: Text(
            headerText,
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
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
            Text(
              AppLocalizations.of(context)?.aiAnalyzing ?? 'AI is analyzing',
              style: const TextStyle(
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

    final lang = Localizations.localeOf(context).languageCode;

    // Localized quick-action labels
    String _l(String et, String en, String ru) {
      switch (lang) {
        case 'et': return et;
        case 'en': return en;
        case 'ru': return ru;
        default: return en;
      }
    }

    switch (_chatPhase) {
      case _ChatPhase.newCase:
        actions = [
          (_l('Mis on minu olukord?', 'What is my situation?', 'Что у меня за ситуация?'), Icons.help_outline_rounded),
          (_l('Millised on minu õigused?', 'What are my rights?', 'Какие у меня права?'), Icons.shield_outlined),
          (_l('Mida teha kõigepealt?', 'What should I do first?', 'Что делать первым?'), Icons.flag_outlined),
          (_l('Skaneeri dokument', 'Scan document', 'Сканировать документ'), Icons.document_scanner_outlined),
        ];
        break;
      case _ChatPhase.afterScan:
        actions = [
          (_l('Leia vead', 'Find errors', 'Найти ошибки'), Icons.search_rounded),
          (_l('Koosta kaebus', 'Draft a complaint', 'Составить жалобу'), Icons.description_outlined),
          (_l('Kontrolli tähtaegu', 'Check deadlines', 'Проверить сроки'), Icons.schedule_rounded),
          (_l('Selgita lihtsalt', 'Explain simply', 'Объяснить простыми словами'), Icons.translate_rounded),
        ];
        break;
      case _ChatPhase.afterAnalysis:
        actions = [
          (_l('Koosta kaebus', 'Draft a complaint', 'Составить жалобу'), Icons.description_outlined),
          (_l('Leia advokaat', 'Find a lawyer', 'Найти адвоката'), Icons.person_search_outlined),
          (_l('Selgita lihtsalt', 'Explain simply', 'Объяснить простыми словами'), Icons.translate_rounded),
          (_l('Kontrolli tähtaegu', 'Check deadlines', 'Проверить дедлайны'), Icons.schedule_rounded),
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

  // -- Attach options --

  void _showAttachOptions() {
    final lang = Localizations.localeOf(context).languageCode;
    String _l(String et, String en, String ru) {
      switch (lang) {
        case 'et': return et;
        case 'en': return en;
        case 'ru': return ru;
        default: return en;
      }
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.upload_file_rounded),
              title: Text(_l('Vali fail', 'Choose file', 'Выбрать файл')),
              subtitle: Text(_l(
                'PDF, foto, dokument',
                'PDF, photo, document',
                'PDF, фото, документ',
              )),
              onTap: () async {
                Navigator.pop(ctx);
                await _pickAndAttachFile();
              },
            ),
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.document_scanner_outlined),
                title: Text(_l('Skaneeri dokument', 'Scan document', 'Сканировать документ')),
                subtitle: Text(_l(
                  'Kasuta kaamerat',
                  'Use camera',
                  'Использовать камеру',
                )),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/scan?caseId=${widget.caseId}');
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndAttachFile() async {
    // Capture locale before async gap
    final lang = Localizations.localeOf(context).languageCode;
    try {
      // Always request bytes so we can actually read / upload the file,
      // not just see its name. Without withData: true the Claude pipeline
      // would only see "Document attached: foo.pdf" — the actual bug we
      // are fixing on fix/ai-quality.
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf', 'doc', 'docx', 'txt', 'md', 'csv',
          'png', 'jpg', 'jpeg', 'heic', 'webp',
        ],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final fileName = file.name;
      final bytes = file.bytes;

      if (bytes == null) {
        unawaited(_sendMessage(_attachFallbackLabel(lang, fileName)));
        return;
      }

      final classification = ChatAttachmentService.classify(
        fileName: fileName,
        mimeType: null,
      );
      if (!classification.isSupported) {
        unawaited(_sendMessage(_attachUnsupportedLabel(lang, fileName)));
        return;
      }

      // For binary attachments (PDF / images) we first upload to the vault so
      // the AI can call the existing read_document tool against the resulting
      // id. For plain-text attachments we inline the decoded body directly
      // into the chat message — Claude will see the content immediately.
      String? documentId;
      if (classification.kind == AttachmentKind.pdf ||
          classification.kind == AttachmentKind.image) {
        try {
          final supabase = ref.read(supabaseServiceProvider);
          documentId = await supabase.uploadDocument(
            caseId: widget.caseId,
            fileName: fileName,
            fileBytes: bytes,
            mimeType: classification.resolvedMimeType,
          );
        } catch (e) {
          debugPrint('Chat attachment upload failed: $e');
          // Continue with documentId == null — buildUserMessage will produce
          // a user-friendly "upload failed, use scan screen" hint.
        }
      }

      final ChatAttachment attachment;
      try {
        attachment = await ChatAttachmentService.build(
          fileName: fileName,
          mimeType: classification.resolvedMimeType,
          bytes: bytes,
          documentId: documentId,
        );
      } on ChatAttachmentException catch (e) {
        // Most commonly: image > 5 MB — Claude's inline cap. Show the
        // localized explanation as a user message so it surfaces in the
        // conversation, and do NOT call the AI (there is nothing useful
        // for it to analyse).
        unawaited(_sendMessage(e.localized(lang)));
        return;
      }

      // For images, stage the attachment so _sendMessage can forward it
      // to Claude as an inline vision content block. PDF / text paths stay
      // unchanged (read_document / inlined body).
      if (attachment.kind == AttachmentKind.image &&
          attachment.hasInlineImage) {
        _pendingImageAttachment = attachment;
      }

      final aiVisibleMessage = ChatAttachmentService.buildUserMessage(
        attachment: attachment,
        language: lang,
      );

      // Send through the normal chat pipeline — the AI now receives
      // - for .txt: the inlined body,
      // - for PDF: a "use read_document with id X" instruction,
      // - for image: the caption alongside an inline image content block.
      unawaited(_sendMessage(aiVisibleMessage));
    } catch (e) {
      // Silently fail — the user can try again
      debugPrint('File picker error: $e');
    }
  }

  String _attachFallbackLabel(String lang, String fileName) {
    switch (lang) {
      case 'et':
        return 'Dokument lisatud: $fileName (ei õnnestunud sisu lugeda, '
            'palun proovi uuesti).';
      case 'ru':
        return 'Документ прикреплён: $fileName (не удалось прочитать '
            'содержимое, попробуй ещё раз).';
      default:
        return 'Document attached: $fileName (content unavailable, please '
            'try again).';
    }
  }

  String _attachUnsupportedLabel(String lang, String fileName) {
    switch (lang) {
      case 'et':
        return 'Fail "$fileName" pole toetatud — palun lae üles PDF, pilt '
            'või tekstifail.';
      case 'ru':
        return 'Файл «$fileName» не поддерживается — загрузи PDF, '
            'изображение или текст.';
      default:
        return 'File "$fileName" is not supported — please upload a PDF, '
            'image, or text file.';
    }
  }

  // -- Input bar --

  /// Inline banner shown immediately above the input container when the
  /// free-tier quota is exhausted. Provides a persistent upgrade path that
  /// is always visible — distinct from the transient snackbar and the CTA
  /// inside the input bar itself.
  Widget _buildQuotaExhaustedBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF1A2540),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Monthly limit reached',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () => context.push(AppRoutes.subscription),
            child: const Text(
              'Upgrade \u2192',
              style: TextStyle(color: Color(0xFF00E5FF)),
            ),
          ),
        ],
      ),
    );
  }

  /// Whether the user's free-tier AI quota is exhausted. Pro users are
  /// reported with `_freeMessagesRemaining == -1` (unlimited) by
  /// [_loadFreeMessageCount].
  bool get _isQuotaExhausted {
    final ai = ref.read(aiServiceProvider);
    if (ai.isProUser) return false;
    return _freeMessagesRemaining == 0;
  }

  Widget _buildInputBar() {
    final isListening = _voiceState == VoiceButtonState.listening;
    final ai = ref.read(aiServiceProvider);
    final isFreeUser = !ai.isProUser;
    final quotaExhausted = _isQuotaExhausted;

    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom:
            MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7F5), // slightly lighter than message area
        border: Border(
          top: BorderSide(
            color: AppColors.border.withValues(alpha: 0.15),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Quota exhausted → replace the composer with an "Upgrade to Pro"
          // CTA so the free user cannot submit another message.
          if (quotaExhausted)
            _buildUpgradeToProCta()
          else
            _buildComposerRow(isListening),

          // Remaining-messages hint — shown for free users when 3 or fewer
          // messages remain. Hidden at 0 (the upgrade CTA replaces the
          // composer and conveys exhaustion more prominently).
          if (isFreeUser &&
              !quotaExhausted &&
              _freeMessagesRemaining >= 0 &&
              _freeMessagesRemaining <= 3) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '$_freeMessagesRemaining '
                'message${_freeMessagesRemaining == 1 ? "" : "s"} '
                'left this month',
                key: const Key('free_messages_remaining_text'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _freeMessagesRemaining == 0
                      ? Colors.red
                      : Colors.orange,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// CTA that replaces the chat composer when the free-tier quota is
  /// exhausted. Navigates to the subscription page on tap.
  Widget _buildUpgradeToProCta() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              'Вы использовали все ${AIService.freeTotalLimit} бесплатных '
              'сообщений. Оформите Advocat Pro за €19.99/мес.',
              key: const Key('quota_exhausted_message'),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              key: const Key('upgrade_to_pro_cta'),
              onPressed: () => context.push(AppRoutes.subscription),
              icon: const Icon(Icons.workspace_premium_rounded, size: 18),
              label: const Text(
                'Оформить Advocat Pro — €19.99/мес',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Normal composer row — attach button, text field, mic, send.
  Widget _buildComposerRow(bool isListening) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Attach button — file picker (web-compatible) with scan fallback
        SizedBox(
          width: 40,
          height: 44,
          child: IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, size: 22),
            color: AppColors.textTertiary,
            onPressed: () => _showAttachOptions(),
            padding: EdgeInsets.zero,
          ),
        ),

        const SizedBox(width: 4),

        // Text field with premium focus glow — takes most width
        Expanded(
          child: _PremiumTextField(
            controller: _messageController,
            focusNode: _focusNode,
            onSend: _isSending ? null : () => _sendMessage(),
          ),
        ),

        const SizedBox(width: 6),

        // Consilium + Mic + Send buttons — same size (44x44), aligned in a row
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Consilium button — Pro-only, 44x44, circular
            if (ref.read(aiServiceProvider).isProUser)
              Tooltip(
                message: 'Юридический совет (4 эксперта)',
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface,
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    key: const Key('consilium_button'),
                    onPressed: _isSending ? null : _triggerConsilium,
                    icon: _isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textTertiary,
                            ),
                          )
                        : const Icon(
                            Icons.balance_rounded,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),

            if (ref.read(aiServiceProvider).isProUser) const SizedBox(width: 4),

            // Mic button — 44x44, circular with shadow
            if (_voiceInitialized)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isListening
                      ? AppColors.error.withValues(alpha: 0.12)
                      : AppColors.surface,
                  border: Border.all(
                    color: isListening
                        ? AppColors.error.withValues(alpha: 0.3)
                        : AppColors.border.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isListening
                          ? AppColors.error.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.06),
                      blurRadius: isListening ? 12 : 6,
                      offset: const Offset(0, 2),
                    ),
                    if (!isListening)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                  ],
                ),
                child: IconButton(
                  onPressed: _isSending ? null : _onVoiceTap,
                  icon: Icon(
                    isListening ? Icons.stop_rounded : Icons.mic_rounded,
                    color: isListening ? AppColors.error : AppColors.textSecondary,
                    size: 22,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),

            if (_voiceInitialized) const SizedBox(width: 6),

            // Send button — 44x44, circular, accent with glow
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _isSending
                    ? null
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.accent, AppColors.accentLight],
                      ),
                color: _isSending
                    ? AppColors.accent.withValues(alpha: 0.5)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              // Stop button (Cursor consilium Gap #1, 2026-05-05): while
              // streaming, the send button morphs into a stop icon. Tap
              // cancels the in-flight stream via _stopStreaming() —
              // refunds the quota slot when no tokens have been received.
              child: IconButton(
                onPressed: _isSending
                    ? (_aiSub != null
                        ? () {
                            final buf = _currentStreamFullText;
                            final id = _currentStreamMessageId;
                            if (buf != null && id != null) {
                              _stopStreaming(buf, id);
                            }
                          }
                        : null)
                    : () => _sendMessage(),
                icon: _isSending
                    ? (_aiSub != null
                        ? const Icon(Icons.stop_rounded, size: 22)
                        : const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ))
                    : const Icon(Icons.arrow_upward_rounded, size: 22),
                color: Colors.white,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
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
      width: 50,
      height: 50,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer breathing glow ring
              Container(
                width: 40 + _pulse.value * 10,
                height: 40 + _pulse.value * 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.25 - _pulse.value * 0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.15 + _pulse.value * 0.15),
                      blurRadius: 12 + _pulse.value * 10,
                      spreadRadius: _pulse.value * 4,
                    ),
                  ],
                ),
              ),
              // Second subtle ring
              Container(
                width: 40 + _pulse.value * 5,
                height: 40 + _pulse.value * 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accentLight.withValues(alpha: 0.12 - _pulse.value * 0.08),
                    width: 1.0,
                  ),
                ),
              ),
              // Core avatar — larger, more prominent
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.accent, AppColors.accentLight],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.35 + _pulse.value * 0.15),
                      blurRadius: 10 + _pulse.value * 6,
                      offset: const Offset(0, 2),
                    ),
                    BoxShadow(
                      color: AppColors.accentLight.withValues(alpha: 0.1 + _pulse.value * 0.1),
                      blurRadius: 20,
                      spreadRadius: _pulse.value * 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.balance_rounded,
                  size: 22,
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
// Pulsing Online status dot
// ---------------------------------------------------------------------------

class _OnlineDot extends StatefulWidget {
  const _OnlineDot({required this.isTyping});

  final bool isTyping;

  @override
  State<_OnlineDot> createState() => _OnlineDotState();
}

class _OnlineDotState extends State<_OnlineDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
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
    final color = widget.isTyping ? AppColors.warning : AppColors.success;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4 + _pulse.value * 0.3),
                blurRadius: 3 + _pulse.value * 3,
                spreadRadius: _pulse.value * 1,
              ),
            ],
          ),
        );
      },
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
    this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback? onSend;

  @override
  State<_PremiumTextField> createState() => _PremiumTextFieldState();
}

class _PremiumTextFieldState extends State<_PremiumTextField> {
  bool _hasFocus = false;
  late final FocusNode _keyboardFocusNode;

  @override
  void initState() {
    super.initState();
    _keyboardFocusNode = FocusNode();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    _keyboardFocusNode.dispose();
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
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          if (_hasFocus)
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.15),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          // Subtle outer shadow for depth
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: KeyboardListener(
        focusNode: _keyboardFocusNode,
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.enter &&
              !HardwareKeyboard.instance.isShiftPressed &&
              widget.onSend != null) {
            widget.onSend!();
          }
        },
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          maxLength: 3000,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          maxLines: 5,
          minLines: 1,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.newline,
          style: const TextStyle(fontSize: 15, height: 1.4),
          decoration: InputDecoration(
            counterText: '',
            hintText: AppLocalizations.of(context)?.typeMessage ?? 'Type a message...',
            hintStyle: TextStyle(
              color: AppColors.textTertiary.withValues(alpha: 0.7),
              fontSize: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: _hasFocus
                  ? BorderSide(color: AppColors.accent.withValues(alpha: 0.35), width: 1.0)
                  : BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(
                color: AppColors.border.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: AppColors.accent.withValues(alpha: 0.35), width: 1.0),
            ),
            filled: true,
            fillColor: _hasFocus
                ? AppColors.surface
                : AppColors.surface.withValues(alpha: 0.9),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 12,
            ),
          ),
        ),
      ),
    );
  }
}
