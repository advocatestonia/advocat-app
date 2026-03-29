import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../config/app_config.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final claudeServiceProvider = Provider<ClaudeService>((ref) {
  return ClaudeService();
});

// ---------------------------------------------------------------------------
// Usage tracking
// ---------------------------------------------------------------------------

class TokenUsage {
  final int inputTokens;
  final int outputTokens;
  final int totalTokens;

  const TokenUsage({
    required this.inputTokens,
    required this.outputTokens,
    required this.totalTokens,
  });

  factory TokenUsage.fromJson(Map<String, dynamic> json) {
    final input = json['input_tokens'] as int? ?? 0;
    final output = json['output_tokens'] as int? ?? 0;
    return TokenUsage(
      inputTokens: input,
      outputTokens: output,
      totalTokens: input + output,
    );
  }
}

// ---------------------------------------------------------------------------
// Document analysis result
// ---------------------------------------------------------------------------

class ClaudeAnalysisResult {
  final String summary;
  final List<String> keyPoints;
  final List<String> legalReferences;
  final List<String> actionItems;
  final String? detectedLanguage;
  final TokenUsage? usage;

  const ClaudeAnalysisResult({
    required this.summary,
    required this.keyPoints,
    required this.legalReferences,
    required this.actionItems,
    this.detectedLanguage,
    this.usage,
  });
}

// ---------------------------------------------------------------------------
// Claude API Service — direct API calls (MVP only, move to server-side later)
// ---------------------------------------------------------------------------

class ClaudeService {
  ClaudeService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: 'https://api.anthropic.com',
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 120),
            headers: {
              'Content-Type': 'application/json',
              'anthropic-version': '2023-06-01',
            },
          ),
        ),
        _log = Logger(printer: PrettyPrinter(methodCount: 0));

  final Dio _dio;
  final Logger _log;

  /// Running total of tokens used in this session.
  int _sessionInputTokens = 0;
  int _sessionOutputTokens = 0;

  int get sessionInputTokens => _sessionInputTokens;
  int get sessionOutputTokens => _sessionOutputTokens;
  int get sessionTotalTokens => _sessionInputTokens + _sessionOutputTokens;

  /// Whether a valid API key is configured.
  static bool get isAvailable => AppConfig.claudeApiKey.isNotEmpty;

  /// The model to use for requests.
  static const String _model = 'claude-sonnet-4-20250514';

  /// Maximum retries on transient failures.
  static const int _maxRetries = 2;

  /// Delay between retries.
  static const Duration _retryDelay = Duration(seconds: 2);

  // ── Core API call with retries ──────────────────────────────────────────

  Future<Map<String, dynamic>> _callApi({
    required String systemPrompt,
    required List<Map<String, String>> messages,
    int maxTokens = 4096,
    double temperature = 0.3,
  }) async {
    if (!isAvailable) {
      throw const ClaudeServiceException('Claude API key is not configured');
    }

    final body = {
      'model': _model,
      'max_tokens': maxTokens,
      'temperature': temperature,
      'system': systemPrompt,
      'messages': messages,
    };

    Exception? lastError;

    for (var attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        if (attempt > 0) {
          _log.w('Retrying Claude API call (attempt ${attempt + 1})');
          await Future.delayed(_retryDelay * attempt);
        }

        final response = await _dio.post(
          '/v1/messages',
          data: body,
          options: Options(
            headers: {
              'x-api-key': AppConfig.claudeApiKey,
            },
          ),
        );

        final data = response.data as Map<String, dynamic>;

        // Track token usage
        final usage = data['usage'] as Map<String, dynamic>?;
        if (usage != null) {
          _sessionInputTokens += (usage['input_tokens'] as int? ?? 0);
          _sessionOutputTokens += (usage['output_tokens'] as int? ?? 0);
        }

        return data;
      } on DioException catch (e) {
        lastError = e;
        final statusCode = e.response?.statusCode;

        // Don't retry on client errors (except 429 rate limit and 529 overload)
        if (statusCode != null &&
            statusCode >= 400 &&
            statusCode < 500 &&
            statusCode != 429) {
          final errorBody = e.response?.data;
          final errorMsg = errorBody is Map
              ? (errorBody['error']?['message'] as String? ??
                  'API request failed')
              : 'API request failed with status $statusCode';
          throw ClaudeServiceException(errorMsg, e);
        }

        // Retry on 429, 5xx, or network errors
        if (attempt == _maxRetries) {
          throw ClaudeServiceException(
            'Claude API call failed after ${_maxRetries + 1} attempts',
            e,
          );
        }
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        if (attempt == _maxRetries) {
          throw ClaudeServiceException(
            'Unexpected error calling Claude API',
            lastError,
          );
        }
      }
    }

    throw ClaudeServiceException(
      'Claude API call failed',
      lastError,
    );
  }

  /// Extract the text content from a Claude API response.
  String _extractText(Map<String, dynamic> response) {
    final content = response['content'] as List<dynamic>?;
    if (content == null || content.isEmpty) {
      return '';
    }
    final textBlocks = content
        .where((block) => (block as Map<String, dynamic>)['type'] == 'text')
        .map((block) => (block as Map<String, dynamic>)['text'] as String);
    return textBlocks.join('\n');
  }

  /// Extract token usage from a Claude API response.
  TokenUsage? _extractUsage(Map<String, dynamic> response) {
    final usage = response['usage'] as Map<String, dynamic>?;
    if (usage == null) return null;
    return TokenUsage.fromJson(usage);
  }

  // ── Public methods ──────────────────────────────────────────────────────

  /// Send a chat message and get a response.
  ///
  /// [messages] is the conversation history as a list of
  /// `{'role': 'user'|'assistant', 'content': '...'}` maps.
  /// [systemPrompt] is the system instruction for Claude.
  Future<String> sendMessage({
    required List<Map<String, String>> messages,
    required String systemPrompt,
    int maxTokens = 4096,
  }) async {
    _log.d('Sending message to Claude (${messages.length} messages)');

    final response = await _callApi(
      systemPrompt: systemPrompt,
      messages: messages,
      maxTokens: maxTokens,
      temperature: 0.3,
    );

    return _extractText(response);
  }

  /// Analyze a document's text content.
  Future<ClaudeAnalysisResult> analyzeDocument({
    required String text,
    required String language,
    String? caseContext,
  }) async {
    _log.d('Analyzing document (${text.length} chars, lang: $language)');

    final systemPrompt = '''You are Advocat, a legal document analysis assistant.
Analyze the following document and return a JSON object with these fields:
- "summary": a concise summary (2-3 sentences)
- "key_points": array of key points found in the document
- "legal_references": array of any laws, regulations, or legal provisions mentioned
- "action_items": array of actions the person should take based on this document
- "detected_language": the language of the document (ISO 639-1 code)

Respond ONLY with valid JSON, no markdown formatting.
${caseContext != null ? '\nCase context: $caseContext' : ''}''';

    final response = await _callApi(
      systemPrompt: systemPrompt,
      messages: [
        {'role': 'user', 'content': 'Analyze this document:\n\n$text'},
      ],
      maxTokens: 2048,
      temperature: 0.1,
    );

    final responseText = _extractText(response);
    final usage = _extractUsage(response);

    try {
      // Strip markdown code fences if present
      var jsonText = responseText.trim();
      if (jsonText.startsWith('```')) {
        jsonText = jsonText.replaceFirst(RegExp(r'^```\w*\n?'), '');
        jsonText = jsonText.replaceFirst(RegExp(r'\n?```$'), '');
      }

      final parsed = json.decode(jsonText) as Map<String, dynamic>;

      return ClaudeAnalysisResult(
        summary: parsed['summary'] as String? ?? responseText,
        keyPoints:
            (parsed['key_points'] as List<dynamic>?)?.cast<String>() ?? [],
        legalReferences:
            (parsed['legal_references'] as List<dynamic>?)?.cast<String>() ??
                [],
        actionItems:
            (parsed['action_items'] as List<dynamic>?)?.cast<String>() ?? [],
        detectedLanguage: parsed['detected_language'] as String?,
        usage: usage,
      );
    } catch (_) {
      // If JSON parsing fails, return the raw text as summary
      return ClaudeAnalysisResult(
        summary: responseText,
        keyPoints: [],
        legalReferences: [],
        actionItems: [],
        usage: usage,
      );
    }
  }

  /// Generate a legal document draft.
  Future<String> generateDraft({
    required Map<String, dynamic> caseData,
    required String documentType,
    required String language,
    required String systemPrompt,
  }) async {
    _log.d('Generating draft: $documentType in $language');

    final caseDescription = caseData.entries
        .map((e) => '${e.key}: ${e.value}')
        .join('\n');

    final response = await _callApi(
      systemPrompt: systemPrompt,
      messages: [
        {
          'role': 'user',
          'content':
              'Generate a $documentType document in $language based on this case:\n\n$caseDescription',
        },
      ],
      maxTokens: 8192,
      temperature: 0.2,
    );

    return _extractText(response);
  }

  /// Send a streaming chat message. Returns a stream of text chunks.
  ///
  /// Note: For MVP we use non-streaming API and simulate streaming by
  /// yielding the full response at once. True SSE streaming can be added
  /// later by switching to `responseType: ResponseType.stream`.
  Stream<String> sendMessageStreaming({
    required List<Map<String, String>> messages,
    required String systemPrompt,
    int maxTokens = 4096,
  }) async* {
    // For MVP: get the full response and yield it
    // TODO: Implement true SSE streaming with stream: true parameter
    final response = await sendMessage(
      messages: messages,
      systemPrompt: systemPrompt,
      maxTokens: maxTokens,
    );
    yield response;
  }

  /// Reset session token counters.
  void resetUsageTracking() {
    _sessionInputTokens = 0;
    _sessionOutputTokens = 0;
  }

  /// Estimate token count for a string (rough approximation: ~4 chars per token).
  static int estimateTokens(String text) {
    return (text.length / 4).ceil();
  }
}

// ---------------------------------------------------------------------------
// Exception
// ---------------------------------------------------------------------------

class ClaudeServiceException implements Exception {
  final String message;
  final Exception? cause;

  const ClaudeServiceException(this.message, [this.cause]);

  @override
  String toString() => 'ClaudeServiceException: $message';
}
