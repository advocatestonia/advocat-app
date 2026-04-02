import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/ai_service.dart';
import '../../../services/assistant_tools.dart';
import '../../../services/demo_data.dart';
import '../../../services/supabase_service.dart';
import '../../../services/tool_executor.dart';

// ---------------------------------------------------------------------------
// Chat message model for provider state
// ---------------------------------------------------------------------------

enum ChatMessageRole { user, assistant, toolResult }

class ChatMessageData {
  final String id;
  final ChatMessageRole role;
  final String content;
  final DateTime timestamp;
  final bool isStreaming;

  /// Structured tool result data for rendering rich cards.
  final ToolResult? toolResult;

  /// Deferred navigation to perform after displaying the tool result.
  final ToolNavigation? navigation;

  const ChatMessageData({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isStreaming = false,
    this.toolResult,
    this.navigation,
  });

  ChatMessageData copyWith({String? content, bool? isStreaming}) {
    return ChatMessageData(
      id: id,
      role: role,
      content: content ?? this.content,
      timestamp: timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
      toolResult: toolResult,
      navigation: navigation,
    );
  }

  factory ChatMessageData.fromJson(Map<String, dynamic> json) {
    return ChatMessageData(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      role: json['role'] == 'user'
          ? ChatMessageRole.user
          : ChatMessageRole.assistant,
      content: json['content'] as String? ?? '',
      timestamp: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

// ---------------------------------------------------------------------------
// Chat state
// ---------------------------------------------------------------------------

class ChatState {
  final List<ChatMessageData> messages;
  final bool isLoading;
  final bool isSending;
  final bool isTyping;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isLoading = true,
    this.isSending = false,
    this.isTyping = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessageData>? messages,
    bool? isLoading,
    bool? isSending,
    bool? isTyping,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      isTyping: isTyping ?? this.isTyping,
      error: error,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier({
    required this.caseId,
    required this.supabaseService,
    required this.aiService,
    required this.isDemo,
  }) : super(const ChatState()) {
    _loadHistory();
  }

  final String caseId;
  final SupabaseService supabaseService;
  final AIService aiService;
  final bool isDemo;

  // ── Load chat history ─────────────────────────────────────────────────

  Future<void> _loadHistory() async {
    try {
      final rawMessages = await supabaseService.getChatMessages(caseId);
      final messages =
          rawMessages.map((m) => ChatMessageData.fromJson(m)).toList();

      state = state.copyWith(
        messages: messages,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load chat history',
      );
    }
  }

  /// Reload messages from the server.
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    await _loadHistory();
  }

  // ── Send a message ──────────────────────────────────────────────────

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isSending) return;

    // Optimistic UI: add user message immediately
    final userMessage = ChatMessageData(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      role: ChatMessageRole.user,
      content: trimmed,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isSending: true,
      isTyping: true,
      error: null,
    );

    try {
      // Persist user message
      await supabaseService.saveChatMessage(
        caseId: caseId,
        role: 'user',
        content: trimmed,
      );

      String responseText;
      if (isDemo && !aiService.isUsingRealAI) {
        // Pure demo mode — mock responses
        await Future.delayed(const Duration(milliseconds: 800));
        responseText = _getDemoResponse(trimmed);
      } else {
        // Real AI (direct Claude API) or backend proxy
        final response = await aiService.sendChatMessage(
          caseId: caseId,
          message: trimmed,
        );
        responseText = response.message;
      }

      // Persist AI response
      await supabaseService.saveChatMessage(
        caseId: caseId,
        role: 'assistant',
        content: responseText,
      );

      final aiMessage = ChatMessageData(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        role: ChatMessageRole.assistant,
        content: responseText,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isSending: false,
        isTyping: false,
      );
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        isTyping: false,
        error: 'Failed to send message. Please try again.',
      );
    }
  }

  /// Get a demo response based on the user's message.
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

  // ── Quick action handlers ─────────────────────────────────────────────

  Future<void> analyzeCase() => sendMessage('Please analyze my case and identify the key issues.');

  Future<void> checkOptions() => sendMessage('What are my legal options in this situation?');

  Future<void> draftAppeal() => sendMessage('Help me draft an appeal for my case.');

  Future<void> checkDeadlines() => sendMessage('What are the important deadlines for my case?');

  // ── Tool result insertion ─────────────────────────────────────────────

  /// Add a tool result message to the chat.
  ///
  /// Called by the chat screen after the [ChatToolBridge] executes a tool.
  void addToolResultMessage({
    required ToolResult toolResult,
    ToolNavigation? navigation,
  }) {
    final message = ChatMessageData(
      id: 'tool_${DateTime.now().millisecondsSinceEpoch}',
      role: ChatMessageRole.toolResult,
      content: toolResult.displayText,
      timestamp: DateTime.now(),
      toolResult: toolResult,
      navigation: navigation,
    );

    state = state.copyWith(
      messages: [...state.messages, message],
    );
  }

  /// Clear any transient error.
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Raw chat messages for a given case (simple FutureProvider for basic usage).
final chatMessagesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, caseId) async {
    return ref.watch(supabaseServiceProvider).getChatMessages(caseId);
  },
);

/// Full-featured chat state notifier, parameterized by case ID.
final chatNotifierProvider =
    StateNotifierProvider.family<ChatNotifier, ChatState, String>(
  (ref, caseId) {
    return ChatNotifier(
      caseId: caseId,
      supabaseService: ref.watch(supabaseServiceProvider),
      aiService: ref.watch(aiServiceProvider),
      isDemo: ref.watch(isDemoModeProvider),
    );
  },
);
