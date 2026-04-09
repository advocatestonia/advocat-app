import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../config/app_config.dart';
import 'tool_definitions.dart';

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
// Claude API Service — Supabase Edge Function proxy (secure, key on server)
// Falls back to direct Anthropic API if Supabase is not configured (local dev).
// ---------------------------------------------------------------------------

class ClaudeService {
  ClaudeService()
      : _useProxy = AppConfig.useSupabaseProxy,
        _dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.useSupabaseProxy
                ? '${AppConfig.supabaseUrl}/functions/v1'
                : 'https://api.anthropic.com',
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 30),
            headers: {
              'Content-Type': 'application/json',
              if (!AppConfig.useSupabaseProxy) 'anthropic-version': '2023-06-01',
            },
          ),
        ),
        _log = Logger(
          printer: PrettyPrinter(methodCount: 0),
          level: kDebugMode ? Level.debug : Level.off,
        );

  final Dio _dio;
  final Logger _log;
  final bool _useProxy;

  /// Running total of tokens used in this session.
  int _sessionInputTokens = 0;
  int _sessionOutputTokens = 0;

  int get sessionInputTokens => _sessionInputTokens;
  int get sessionOutputTokens => _sessionOutputTokens;
  int get sessionTotalTokens => _sessionInputTokens + _sessionOutputTokens;

  /// Timestamp of the last API request, used for throttling.
  DateTime? _lastRequestTime;

  /// Whether the service is available (Supabase proxy with anon key, or direct API key).
  static bool get isAvailable =>
      (AppConfig.supabaseUrl.isNotEmpty && AppConfig.supabaseAnonKey.isNotEmpty) ||
      AppConfig.claudeApiKey.isNotEmpty;

  /// Expensive model for complex legal analysis.
  static const String modelSonnet = 'claude-sonnet-4-20250514';

  /// Cheap model for simple questions (12x cheaper).
  static const String modelHaiku = 'claude-haiku-4-5-20251001';

  /// Max output tokens for Haiku (short answers — fewer tokens = faster).
  static const int _maxTokensHaiku = 400;

  /// Max output tokens for Sonnet (detailed answers).
  static const int _maxTokensSonnet = 1000;

  /// Keywords that indicate a complex legal query requiring Sonnet.
  static const List<String> _complexKeywords = [
    // English legal terms
    'appeal', 'deportation', 'asylum', 'court', 'judge', 'ruling',
    'deadline', 'hearing', 'petition', 'complaint', 'violation',
    'article', 'section', 'directive', 'regulation', 'statute',
    'lawyer', 'attorney', 'legal aid', 'ombudsman', 'prosecutor',
    'evidence', 'witness', 'testimony', 'precedent', 'case law',
    'residence permit', 'work permit', 'visa', 'citizenship',
    'discrimination', 'human rights', 'echr', 'eu charter',
    'non-refoulement', 'proportionality', 'procedural',
    'draft', 'document', 'analyze', 'review', 'strategy',
    'family reunification', 'entry ban', 'expulsion',
    // Russian legal terms
    'апелляция', 'депортация', 'суд', 'судья', 'решение',
    'срок', 'слушание', 'жалоба', 'нарушение', 'закон',
    'статья', 'директива', 'адвокат', 'юрист', 'прокурор',
    'доказательств', 'свидетел', 'прецедент', 'разрешение',
    'дискриминация', 'права человека', 'пропорциональность',
    'документ', 'анализ', 'стратегия', 'обжалован',
    // Finnish legal terms
    'valitus', 'hallinto-oikeus', 'karkotus', 'oleskelulupa',
    'tuomioistuin', 'päätös', 'määräaika', 'oikeusapu',
    // Estonian legal terms
    'kaebus', 'kohus', 'otsus', 'elamisluba',
  ];

  /// Determine the appropriate model for a query.
  ///
  /// Aggressively defaults to [modelHaiku] (3x faster) unless the query
  /// is clearly complex legal analysis requiring [modelSonnet].
  static String chooseModel(String query) {
    final lower = query.toLowerCase();

    // Short messages (< 150 chars) without complex keywords -> always Haiku
    if (query.length < 150) {
      final hasComplexKeyword =
          _complexKeywords.any((kw) => lower.contains(kw));
      if (!hasComplexKeyword) return modelHaiku;
    }

    // Only use Sonnet if MULTIPLE complex keywords found (truly complex query)
    final matchCount =
        _complexKeywords.where((kw) => lower.contains(kw)).length;
    if (matchCount >= 2) return modelSonnet;

    // Very long messages (> 300 chars) with at least one keyword -> Sonnet
    if (query.length > 300 && matchCount >= 1) return modelSonnet;

    // Default: Haiku for speed
    return modelHaiku;
  }

  /// Get the recommended max tokens for a given model.
  static int maxTokensForModel(String model) {
    return model == modelHaiku ? _maxTokensHaiku : _maxTokensSonnet;
  }

  /// Whether a query is "simple" — greetings, meta-questions, short queries
  /// without legal keywords. Simple queries skip the knowledge base entirely
  /// and use a minimal system prompt for maximum speed.
  static bool isSimpleQuery(String query) {
    if (query.length > 80) return false;
    final lower = query.toLowerCase().trim();
    // Check for any complex keyword — if found, not simple
    if (_complexKeywords.any((kw) => lower.contains(kw))) return false;
    // Greetings and meta-questions are always simple
    const simplePatterns = [
      'hi', 'hello', 'hey', 'привет', 'здравствуйте', 'tere', 'hei',
      'hola', 'bonjour', 'moi', 'terve', 'help', 'помощь', 'abi',
      'what can you do', 'что ты умеешь', 'mida sa oskad',
      'who are you', 'кто ты', 'kes sa oled',
      'thanks', 'thank you', 'спасибо', 'aitäh', 'kiitos',
      'ok', 'okay', 'good', 'хорошо', 'ладно', 'понял',
      'yes', 'no', 'да', 'нет', 'jah', 'ei',
    ];
    // Exact match or very short message
    if (simplePatterns.any((p) => lower == p || lower.startsWith('$p '))) {
      return true;
    }
    // Very short messages without legal content are simple
    if (query.length < 30) return true;
    return false;
  }

  /// Maximum retries on transient failures.
  static const int _maxRetries = 1;

  /// Delay between retries.
  static const Duration _retryDelay = Duration(seconds: 1);

  // ── Core API call with retries ──────────────────────────────────────────
  // When _useProxy is true, requests go to Supabase Edge Function which
  // holds the Claude API key server-side. The client authenticates with
  // the Supabase anon key (safe for client-side use).

  Future<Map<String, dynamic>> _callApi({
    required String systemPrompt,
    required List<Map<String, String>> messages,
    int maxTokens = 4096,
    double temperature = 0.3,
    bool includeTools = false,
    String? model,
  }) async {
    if (!isAvailable) {
      throw const ClaudeServiceException(
        'Claude API is not configured. Set SUPABASE_URL or CLAUDE_API_KEY.',
      );
    }

    // Enforce rate limiting: wait if the last request was too recent.
    // Use 300ms minimum gap (was 1000ms) — fast enough to prevent abuse,
    // short enough not to add perceived latency.
    if (_lastRequestTime != null) {
      final elapsed =
          DateTime.now().difference(_lastRequestTime!).inMilliseconds;
      const throttleMs = 300; // Reduced from AppConfig.aiRequestThrottleMs
      final remaining = throttleMs - elapsed;
      if (remaining > 0) {
        await Future<void>.delayed(Duration(milliseconds: remaining));
      }
    }
    _lastRequestTime = DateTime.now();

    final body = {
      'model': model ?? modelSonnet,
      'max_tokens': maxTokens,
      'temperature': temperature,
      'system': systemPrompt,
      'messages': messages,
      if (includeTools) 'tools': ToolDefinitions.toolDefinitions,
    };

    Exception? lastError;

    for (var attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        if (attempt > 0) {
          _log.w('Retrying Claude API call (attempt ${attempt + 1})');
          await Future.delayed(_retryDelay * attempt);
        }

        final response = await _dio.post(
          _useProxy ? '/claude-proxy' : '/v1/messages',
          data: body,
          options: Options(
            headers: _useProxy
                ? {
                    'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
                  }
                : {
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
  ///
  /// This is also exposed publicly as [extractText] for callers that
  /// work with raw API responses (e.g. tool_use flow).
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

  /// Check whether a Claude API response contains tool_use content blocks.
  bool hasToolUse(Map<String, dynamic> response) {
    final content = response['content'] as List<dynamic>?;
    if (content == null) return false;
    return content.any(
      (block) => (block as Map<String, dynamic>)['type'] == 'tool_use',
    );
  }

  /// Extract tool_use blocks from a Claude API response.
  ///
  /// Each returned map contains `id`, `name`, and `input` keys matching
  /// the Claude API tool_use content block format.
  List<Map<String, dynamic>> extractToolUseBlocks(
      Map<String, dynamic> response) {
    final content = response['content'] as List<dynamic>?;
    if (content == null) return [];
    return content
        .where((block) => (block as Map<String, dynamic>)['type'] == 'tool_use')
        .map((block) => block as Map<String, dynamic>)
        .toList();
  }

  /// Public accessor for extracting text from a raw API response.
  String extractText(Map<String, dynamic> response) => _extractText(response);

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
    String? model,
  }) async {
    _log.d('Sending message to Claude (${messages.length} messages, '
        'model: ${model ?? modelSonnet})');

    final response = await _callApi(
      systemPrompt: systemPrompt,
      messages: messages,
      maxTokens: maxTokens,
      temperature: 0.3,
      model: model,
    );

    return _extractText(response);
  }

  /// Send a chat message with tool definitions included.
  ///
  /// Returns the raw Claude API response so the caller can inspect
  /// `stop_reason` and handle both text-only and tool_use responses.
  Future<Map<String, dynamic>> sendMessageWithTools({
    required List<Map<String, String>> messages,
    required String systemPrompt,
    int maxTokens = 4096,
    String? model,
  }) async {
    _log.d('Sending message with tools to Claude (${messages.length} messages, '
        'model: ${model ?? modelSonnet})');

    return _callApi(
      systemPrompt: systemPrompt,
      messages: messages,
      maxTokens: maxTokens,
      temperature: 0.3,
      includeTools: true,
      model: model,
    );
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
    String? model,
  }) async* {
    // For MVP: get the full response and yield it
    // TODO: Implement true SSE streaming with stream: true parameter
    final response = await sendMessage(
      messages: messages,
      systemPrompt: systemPrompt,
      maxTokens: maxTokens,
      model: model,
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
