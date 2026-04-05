import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../config/app_config.dart';
import '../models/case_model.dart';
import 'claude_service.dart';
import 'system_prompts.dart';

final aiServiceProvider = Provider<AIService>((ref) {
  final claudeService = ref.watch(claudeServiceProvider);
  return AIService(claudeService: claudeService);
});

/// Service that communicates with the AI backend.
///
/// When [AppConfig.useRealAI] is true **and** a Claude API key is configured,
/// requests are sent directly to the Claude Messages API via [ClaudeService].
/// Otherwise, requests go through the backend proxy endpoint (original flow).
class AIService {
  AIService({ClaudeService? claudeService})
      : _claudeService = claudeService ?? ClaudeService(),
        _dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.aiApiBaseUrl,
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 120),
            headers: {
              'Content-Type': 'application/json',
            },
          ),
        ),
        _log = Logger(printer: PrettyPrinter(methodCount: 0));

  final ClaudeService _claudeService;
  final Dio _dio;
  final Logger _log;

  /// Whether this service instance is using the real Claude API.
  bool get isUsingRealAI => AppConfig.useRealAI && ClaudeService.isAvailable;

  /// Set the Supabase access token for authenticated proxy requests.
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // ── Input sanitization ──────────────────────────────────────────────────

  /// Patterns that indicate prompt injection attempts.
  static final List<RegExp> _injectionPatterns = [
    RegExp(r'ignore\s+(all\s+)?previous\s+instructions', caseSensitive: false),
    RegExp(r'ignore\s+(all\s+)?prior\s+instructions', caseSensitive: false),
    RegExp(r'disregard\s+(all\s+)?(previous|prior|above)\s+instructions', caseSensitive: false),
    RegExp(r'you\s+are\s+now\s+', caseSensitive: false),
    RegExp(r'new\s+system\s+prompt', caseSensitive: false),
    RegExp(r'override\s+system\s+prompt', caseSensitive: false),
    RegExp(r'act\s+as\s+(if\s+)?you\s+(are|were)\s+', caseSensitive: false),
    RegExp(r'pretend\s+(that\s+)?you\s+(are|were)\s+', caseSensitive: false),
    RegExp(r'forget\s+(all\s+)?(previous|prior|your)\s+(instructions|rules|constraints)', caseSensitive: false),
    RegExp(r'system:\s', caseSensitive: false),
    RegExp(r'<\s*system\s*>', caseSensitive: false),
    RegExp(r'\[SYSTEM\]', caseSensitive: false),
    RegExp(r'ENTER\s+(ADMIN|DEBUG|DEV)\s+MODE', caseSensitive: false),
  ];

  /// Sanitize user input by stripping prompt injection patterns.
  ///
  /// Returns the cleaned text. Matched fragments are replaced with
  /// `[removed]` so the user's intent is still partially preserved
  /// without the injection payload.
  static String _sanitizeInput(String text) {
    var sanitized = text;
    for (final pattern in _injectionPatterns) {
      sanitized = sanitized.replaceAll(pattern, '[removed]');
    }
    return sanitized;
  }

  // ── Conversation history for real AI mode ──────────────────────────────

  /// Per-case conversation history for Claude context.
  final Map<String, List<Map<String, String>>> _conversationHistory = {};

  /// Maximum messages to keep in conversation history per case.
  static const int _maxHistoryMessages = 40;

  void _addToHistory(String caseId, String role, String content) {
    _conversationHistory.putIfAbsent(caseId, () => []);
    _conversationHistory[caseId]!.add({'role': role, 'content': content});
    // Trim old messages, keeping system-level context fresh
    if (_conversationHistory[caseId]!.length > _maxHistoryMessages) {
      _conversationHistory[caseId] = _conversationHistory[caseId]!
          .sublist(_conversationHistory[caseId]!.length - _maxHistoryMessages);
    }
  }

  /// Clear conversation history for a case (e.g., on new session).
  void clearHistory(String caseId) {
    _conversationHistory.remove(caseId);
  }

  // ── Document analysis ──────────────────────────────────────────────────

  /// Analyze an uploaded document: extract text, summarize, find deadlines.
  Future<DocumentAnalysis> analyzeDocument({
    required String caseId,
    required String documentId,
    String? ocrText,
    CaseType? caseType,
    String? country,
  }) async {
    if (isUsingRealAI && ocrText != null && ocrText.isNotEmpty) {
      _log.i('Using Claude API for document analysis');
      try {
        final result = await _claudeService.analyzeDocument(
          text: ocrText,
          language: 'auto',
          caseContext: 'Case ID: $caseId, Document ID: $documentId',
        );
        return DocumentAnalysis(
          summary: result.summary,
          language: result.detectedLanguage,
          keyPoints: result.keyPoints,
          deadlines: result.actionItems
              .where((item) =>
                  item.toLowerCase().contains('deadline') ||
                  item.toLowerCase().contains('date') ||
                  item.toLowerCase().contains('days'))
              .map((item) => ExtractedDeadline(
                    title: item,
                    date: '', // Claude doesn't extract exact dates in this mode
                  ))
              .toList(),
          entities: {
            'legal_references': result.legalReferences,
            'action_items': result.actionItems,
          },
        );
      } on ClaudeServiceException catch (e) {
        _log.e('Claude document analysis failed, falling back to proxy', error: e);
        // Fall through to proxy
      }
    }

    // Proxy fallback
    try {
      final response = await _dio.post(
        '/ai/analyze-document',
        data: {
          'case_id': caseId,
          'document_id': documentId,
          if (ocrText != null) 'ocr_text': ocrText,
        },
      );
      return DocumentAnalysis.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _log.e('Document analysis failed', error: e);
      throw AIServiceException('Failed to analyze document', e);
    }
  }

  // ── Chat ───────────────────────────────────────────────────────────────

  /// Send a message in the AI legal assistant chat.
  ///
  /// When using real AI, [caseType], [country], [nationality], and
  /// [caseDescription] are used to build the system prompt with relevant
  /// legal knowledge.
  Future<ChatResponse> sendChatMessage({
    required String caseId,
    required String message,
    List<String>? attachmentIds,
    CaseType? caseType,
    String? country,
    String? nationality,
    String? caseDescription,
    String? userLanguage,
  }) async {
    // Sanitize user input before any AI processing
    final sanitizedMessage = _sanitizeInput(message);

    if (isUsingRealAI) {
      _log.i('Using Claude API for chat');
      try {
        // Add user message to history
        _addToHistory(caseId, 'user', sanitizedMessage);

        // Build system prompt with relevant knowledge from all 22 databases
        final systemPrompt = SystemPrompts.buildChatPrompt(
          caseType: caseType,
          country: country,
          nationality: nationality,
          caseContext: caseDescription,
          userLanguage: userLanguage,
          query: sanitizedMessage,
        );

        // Send to Claude with full conversation history
        final responseText = await _claudeService.sendMessage(
          messages: _conversationHistory[caseId] ?? [
            {'role': 'user', 'content': message},
          ],
          systemPrompt: systemPrompt,
        );

        // Add assistant response to history
        _addToHistory(caseId, 'assistant', responseText);

        return ChatResponse(
          message: responseText,
          disclaimer:
              'This is AI-generated legal information, not legal advice. '
              'Please consult a qualified attorney for advice specific to your situation.',
        );
      } on ClaudeServiceException catch (e) {
        _log.e('Claude chat failed, falling back to proxy', error: e);
        // Remove the message we added to history since it failed
        _conversationHistory[caseId]?.removeLast();
        // Fall through to proxy
      }
    }

    // Proxy fallback
    try {
      final response = await _dio.post(
        '/ai/chat',
        data: {
          'case_id': caseId,
          'message': sanitizedMessage,
          if (attachmentIds != null) 'attachment_ids': attachmentIds,
        },
      );
      return ChatResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _log.e('Chat message failed', error: e);
      throw AIServiceException('Failed to send message', e);
    }
  }

  // ── Draft generation ───────────────────────────────────────────────────

  /// Generate a draft appeal or response document based on the case context.
  Future<DraftResponse> generateDraft({
    required String caseId,
    required String draftType,
    Map<String, dynamic>? parameters,
    CaseType? caseType,
    String? country,
    String? nationality,
    String language = 'en',
  }) async {
    if (isUsingRealAI) {
      _log.i('Using Claude API for draft generation');
      try {
        final systemPrompt = SystemPrompts.buildDraftPrompt(
          documentType: draftType,
          language: language,
          caseType: caseType,
          country: country,
          nationality: nationality,
        );

        final caseData = {
          'case_id': caseId,
          'draft_type': draftType,
          if (parameters != null) ...parameters,
        };

        final content = await _claudeService.generateDraft(
          caseData: caseData,
          documentType: draftType,
          language: language,
          systemPrompt: systemPrompt,
        );

        return DraftResponse(
          title: '$draftType Draft',
          content: content,
          language: language,
          disclaimer:
              'This is an AI-generated draft. It must be reviewed and approved '
              'by a qualified attorney before submission to any court or authority.',
        );
      } on ClaudeServiceException catch (e) {
        _log.e('Claude draft generation failed, falling back to proxy', error: e);
        // Fall through to proxy
      }
    }

    // Proxy fallback
    try {
      final response = await _dio.post(
        '/ai/generate-draft',
        data: {
          'case_id': caseId,
          'draft_type': draftType,
          if (parameters != null) 'parameters': parameters,
        },
      );
      return DraftResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _log.e('Draft generation failed', error: e);
      throw AIServiceException('Failed to generate draft', e);
    }
  }

  // ── Deadline extraction ────────────────────────────────────────────────

  /// Extract deadlines and key dates from correspondence text.
  Future<List<ExtractedDeadline>> extractDeadlines({
    required String caseId,
    required String text,
  }) async {
    if (isUsingRealAI) {
      _log.i('Using Claude API for deadline extraction');
      try {
        final result = await _claudeService.analyzeDocument(
          text: text,
          language: 'auto',
          caseContext: 'Extract all deadlines, dates, and time-sensitive items.',
        );
        return result.actionItems
            .map((item) => ExtractedDeadline(
                  title: item,
                  date: '',
                  type: 'extracted',
                  description: item,
                ))
            .toList();
      } on ClaudeServiceException catch (e) {
        _log.e('Claude deadline extraction failed, falling back to proxy', error: e);
        // Fall through to proxy
      }
    }

    // Proxy fallback
    try {
      final response = await _dio.post(
        '/ai/extract-deadlines',
        data: {
          'case_id': caseId,
          'text': text,
        },
      );
      final items = response.data['deadlines'] as List<dynamic>;
      return items
          .map((e) => ExtractedDeadline.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _log.e('Deadline extraction failed', error: e);
      throw AIServiceException('Failed to extract deadlines', e);
    }
  }
}

// ── Response DTOs ─────────────────────────────────────────────────────────

class DocumentAnalysis {
  final String summary;
  final String? language;
  final List<String> keyPoints;
  final List<ExtractedDeadline> deadlines;
  final Map<String, dynamic> entities;

  const DocumentAnalysis({
    required this.summary,
    this.language,
    required this.keyPoints,
    required this.deadlines,
    required this.entities,
  });

  factory DocumentAnalysis.fromJson(Map<String, dynamic> json) {
    return DocumentAnalysis(
      summary: json['summary'] as String,
      language: json['language'] as String?,
      keyPoints: (json['key_points'] as List<dynamic>).cast<String>(),
      deadlines: (json['deadlines'] as List<dynamic>)
          .map((e) => ExtractedDeadline.fromJson(e as Map<String, dynamic>))
          .toList(),
      entities: json['entities'] as Map<String, dynamic>? ?? {},
    );
  }
}

class ChatResponse {
  final String message;
  final List<String>? suggestedActions;
  final String? disclaimer;

  const ChatResponse({
    required this.message,
    this.suggestedActions,
    this.disclaimer,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      message: json['message'] as String,
      suggestedActions: (json['suggested_actions'] as List<dynamic>?)?.cast<String>(),
      disclaimer: json['disclaimer'] as String?,
    );
  }
}

class DraftResponse {
  final String title;
  final String content;
  final String language;
  final String disclaimer;

  const DraftResponse({
    required this.title,
    required this.content,
    required this.language,
    required this.disclaimer,
  });

  factory DraftResponse.fromJson(Map<String, dynamic> json) {
    return DraftResponse(
      title: json['title'] as String,
      content: json['content'] as String,
      language: json['language'] as String? ?? 'en',
      disclaimer: json['disclaimer'] as String? ??
          'This is an AI-generated draft. Consult a licensed attorney before submitting.',
    );
  }
}

class ExtractedDeadline {
  final String title;
  final String date;
  final String? type;
  final String? description;

  const ExtractedDeadline({
    required this.title,
    required this.date,
    this.type,
    this.description,
  });

  factory ExtractedDeadline.fromJson(Map<String, dynamic> json) {
    return ExtractedDeadline(
      title: json['title'] as String,
      date: json['date'] as String,
      type: json['type'] as String?,
      description: json['description'] as String?,
    );
  }
}

// ── Exceptions ────────────────────────────────────────────────────────────

class AIServiceException implements Exception {
  final String message;
  final DioException? cause;

  const AIServiceException(this.message, [this.cause]);

  @override
  String toString() => 'AIServiceException: $message';
}
