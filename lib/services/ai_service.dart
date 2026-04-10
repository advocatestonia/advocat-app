import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 30),
            headers: {
              'Content-Type': 'application/json',
            },
          ),
        ),
        _log = Logger(
          printer: PrettyPrinter(methodCount: 0),
          level: kDebugMode ? Level.debug : Level.off,
        );

  final ClaudeService _claudeService;
  final Dio _dio;
  final Logger _log;

  /// Whether this service instance is using the real Claude API.
  bool get isUsingRealAI => AppConfig.useRealAI && ClaudeService.isAvailable;

  // ── Response cache (avoids API calls for repeated common questions) ────

  /// In-memory cache: normalized query -> (response, timestamp).
  final Map<String, _CachedResponse> _responseCache = {};

  /// Cache TTL: 1 hour.
  static const Duration _cacheTtl = Duration(hours: 1);

  /// Max entries in cache to prevent unbounded memory growth.
  static const int _maxCacheEntries = 100;

  /// Normalize a query for cache lookup: lowercase, trimmed, first 100 chars.
  static String _normalizeCacheKey(String query) {
    final trimmed = query.trim().toLowerCase();
    return trimmed.length > 100 ? trimmed.substring(0, 100) : trimmed;
  }

  /// Look up a cached response. Returns null if not found or expired.
  String? _getCachedResponse(String query) {
    final key = _normalizeCacheKey(query);
    final cached = _responseCache[key];
    if (cached == null) return null;
    if (DateTime.now().difference(cached.timestamp) > _cacheTtl) {
      _responseCache.remove(key);
      return null;
    }
    return cached.response;
  }

  /// Store a response in cache.
  void _cacheResponse(String query, String response) {
    // Evict oldest entries if cache is full.
    if (_responseCache.length >= _maxCacheEntries) {
      final oldest = _responseCache.entries.reduce(
        (a, b) => a.value.timestamp.isBefore(b.value.timestamp) ? a : b,
      );
      _responseCache.remove(oldest.key);
    }
    final key = _normalizeCacheKey(query);
    _responseCache[key] = _CachedResponse(response, DateTime.now());
  }

  // ── Free-tier TOTAL limit (5 messages ever, not per day) ──────────────
  //
  // TODO(production): Enforce server-side in Supabase Edge Function.
  //

  /// Maximum free API calls TOTAL (lifetime, not per day).
  static const int _freeTotalLimit = 50;

  /// Key for storing total free message count.
  static const String _freeTotalKey = 'ai_total_free_count';

  /// Whether the current user is a Pro subscriber.
  bool isProUser = false;

  /// Check if free user has remaining API calls (lifetime limit).
  Future<bool> _checkAndIncrementDailyLimit() async {
    if (isProUser) return true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final count = prefs.getInt(_freeTotalKey) ?? 0;
      if (count >= _freeTotalLimit) return false;
      await prefs.setInt(_freeTotalKey, count + 1);
      return true;
    } catch (_) {
      return true;
    }
  }

  /// Get remaining free calls (lifetime).
  Future<int> getRemainingFreeCalls() async {
    if (isProUser) return -1; // unlimited
    try {
      final prefs = await SharedPreferences.getInstance();
      final count = prefs.getInt(_freeTotalKey) ?? 0;
      return (_freeTotalLimit - count).clamp(0, _freeTotalLimit);
    } catch (_) {
      return _freeTotalLimit;
    }
  }

  // ── Session usage tracking ────────────────────────────────────────────

  /// Total input tokens used in this session (across all API calls).
  int get sessionInputTokens => _claudeService.sessionInputTokens;

  /// Total output tokens used in this session (across all API calls).
  int get sessionOutputTokens => _claudeService.sessionOutputTokens;

  /// Total tokens used in this session.
  int get sessionTotalTokens => _claudeService.sessionTotalTokens;

  /// Estimated session cost in USD (rough, based on Sonnet pricing as upper bound).
  double get estimatedSessionCostUsd {
    // Sonnet: $3/1M input, $15/1M output
    // Haiku: $0.25/1M input, $1.25/1M output
    // Use Sonnet pricing as conservative upper bound.
    return (sessionInputTokens * 3.0 / 1000000) +
        (sessionOutputTokens * 15.0 / 1000000);
  }

  /// Set the Supabase access token for authenticated proxy requests.
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // ── Input sanitization ──────────────────────────────────────────────────

  /// Patterns that indicate prompt injection attempts.
  ///
  /// Covers English, Russian, Estonian, and Arabic injection vectors.
  static final List<RegExp> _injectionPatterns = [
    // ── English ──────────────────────────────────────────────────────────
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

    // ── Russian ──────────────────────────────────────────────────────────
    RegExp(r'игнорируй\s+(все\s+)?предыдущие\s+инструкции', caseSensitive: false),
    RegExp(r'забудь\s+(все\s+)?(предыдущие\s+)?инструкции', caseSensitive: false),
    RegExp(r'ты\s+теперь\s+', caseSensitive: false),
    RegExp(r'системная\s+команда', caseSensitive: false),
    RegExp(r'новая\s+системная\s+(роль|команда|инструкция)', caseSensitive: false),
    RegExp(r'притворись\s+(что\s+)?ты\s+', caseSensitive: false),
    RegExp(r'действуй\s+как\s+', caseSensitive: false),

    // ── Estonian ─────────────────────────────────────────────────────────
    RegExp(r'ignoreeri\s+(k[õo]iki\s+)?eelmisi\s+juhiseid', caseSensitive: false),
    RegExp(r'sa\s+oled\s+n[üu]{1,2}d\s+', caseSensitive: false),
    RegExp(r's[üu]steemi\s+k[äa]sk', caseSensitive: false),
    RegExp(r'unusta\s+(k[õo]ik\s+)?eelmised\s+juhised', caseSensitive: false),

    // ── Arabic ──────────────────────────────────────────────────────────
    RegExp(r'تجاهل\s+التعليمات\s+السابقة', caseSensitive: false),
    RegExp(r'أنت\s+الآن\s+', caseSensitive: false),
    RegExp(r'تجاهل\s+(كل\s+)?التعليمات', caseSensitive: false),
  ];

  /// Map of Cyrillic characters that visually resemble Latin ones.
  ///
  /// Attackers may substitute е→e, а→a, о→o, etc. to bypass regex
  /// filters. We normalise these before pattern matching.
  static const Map<String, String> _cyrillicHomoglyphs = {
    'А': 'A', 'а': 'a', // Cyrillic A
    'В': 'B',            // Cyrillic Ve
    'Е': 'E', 'е': 'e', // Cyrillic Ie
    'К': 'K', 'к': 'k', // Cyrillic Ka
    'М': 'M',            // Cyrillic Em
    'Н': 'H',            // Cyrillic En
    'О': 'O', 'о': 'o', // Cyrillic O
    'Р': 'P', 'р': 'p', // Cyrillic Er
    'С': 'C', 'с': 'c', // Cyrillic Es
    'Т': 'T',            // Cyrillic Te
    'У': 'Y',            // Cyrillic U
    'Х': 'X', 'х': 'x', // Cyrillic Kha
  };

  /// Normalise Cyrillic homoglyphs to their Latin equivalents so that
  /// mixed-script injection attempts are caught by the English patterns.
  static String _normalizeCyrillicHomoglyphs(String text) {
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_cyrillicHomoglyphs[char] ?? char);
    }
    return buffer.toString();
  }

  /// Sanitize user input by stripping prompt injection patterns.
  ///
  /// Returns the cleaned text. Matched fragments are replaced with
  /// `[removed]` so the user's intent is still partially preserved
  /// without the injection payload.
  ///
  /// The method first normalises Cyrillic homoglyphs to Latin so that
  /// mixed-script evasion attempts (e.g. using Cyrillic "а" instead of
  /// Latin "a") are caught by the English-language patterns.
  static String _sanitizeInput(String text) {
    // First pass: normalise homoglyphs and check against all patterns
    final normalised = _normalizeCyrillicHomoglyphs(text);
    var sanitized = text;
    for (final pattern in _injectionPatterns) {
      // Check against the normalised text to find match positions,
      // then remove from the original text at the same offsets.
      if (pattern.hasMatch(normalised)) {
        sanitized = sanitized.replaceAll(pattern, '[removed]');
        // Also replace in the homoglyph-normalised form applied to sanitized
        final sanitizedNorm = _normalizeCyrillicHomoglyphs(sanitized);
        if (pattern.hasMatch(sanitizedNorm)) {
          // Rebuild sanitized by replacing matches found in normalised form
          final normMatches = pattern.allMatches(sanitizedNorm);
          // Replace from end to preserve offsets
          final matchList = normMatches.toList().reversed;
          final chars = sanitized.split('');
          for (final m in matchList) {
            chars.replaceRange(m.start, m.end, '[removed]'.split(''));
          }
          sanitized = chars.join();
        }
      } else {
        sanitized = sanitized.replaceAll(pattern, '[removed]');
      }
    }
    return sanitized;
  }

  // ── Conversation history for real AI mode ──────────────────────────────

  /// Per-case conversation history for Claude context.
  final Map<String, List<Map<String, String>>> _conversationHistory = {};

  /// Maximum messages to keep in conversation history per case.
  static const int _maxHistoryMessages = 20;

  /// Number of recent messages to keep as full content.
  /// Older messages are summarized to a single line each.
  static const int _fullContentMessages = 10;

  void _addToHistory(String caseId, String role, String content) {
    // Purge stale histories before adding new messages.
    purgeStaleHistory();

    _conversationHistory.putIfAbsent(caseId, () => []);
    _conversationHistory[caseId]!.add({'role': role, 'content': content});
    _caseLastActivity[caseId] = DateTime.now();
    // Trim old messages
    if (_conversationHistory[caseId]!.length > _maxHistoryMessages) {
      _conversationHistory[caseId] = _conversationHistory[caseId]!
          .sublist(_conversationHistory[caseId]!.length - _maxHistoryMessages);
    }
  }

  /// Build the messages list for the API call, summarizing older messages.
  ///
  /// Returns the last [_fullContentMessages] as full content.
  /// Older messages are condensed to a single-line summary each to save tokens.
  List<Map<String, String>> _buildMessagesForApi(String caseId) {
    final history = _conversationHistory[caseId];
    if (history == null || history.isEmpty) return [];

    if (history.length <= _fullContentMessages) {
      return List<Map<String, String>>.from(history);
    }

    final result = <Map<String, String>>[];

    // Summarize older messages (before the last _fullContentMessages)
    final olderCount = history.length - _fullContentMessages;
    for (var i = 0; i < olderCount; i++) {
      final msg = history[i];
      final role = msg['role'] ?? 'user';
      final content = msg['content'] ?? '';
      // Condense to first 80 chars + ellipsis
      final summary = content.length > 80
          ? '${content.substring(0, 80)}...'
          : content;
      result.add({'role': role, 'content': summary});
    }

    // Keep recent messages as full content
    for (var i = olderCount; i < history.length; i++) {
      result.add(Map<String, String>.from(history[i]));
    }

    return result;
  }

  /// Clear conversation history for a case (e.g., on new session).
  void clearHistory(String caseId) {
    _conversationHistory.remove(caseId);
  }

  /// Clear all conversation history across all cases.
  ///
  /// Call this when the app goes to background (or when the browser tab
  /// becomes hidden on web) to prevent sensitive chat data from lingering
  /// in memory.
  void clearAllHistory() {
    _conversationHistory.clear();
    _responseCache.clear();
  }

  /// Remove messages older than [maxAge] from all conversation histories.
  ///
  /// This is a best-effort cleanup: messages do not carry individual
  /// timestamps, so we track the *last activity time* per case and
  /// purge entire case histories that have been idle longer than [maxAge].
  static const Duration _maxMessageAge = Duration(hours: 24);

  /// Per-case last-activity timestamp, updated whenever a message is added.
  final Map<String, DateTime> _caseLastActivity = {};

  /// Purge conversation histories that have not been touched for 24 hours.
  void purgeStaleHistory() {
    final now = DateTime.now();
    final staleCases = <String>[];
    for (final entry in _caseLastActivity.entries) {
      if (now.difference(entry.value) > _maxMessageAge) {
        staleCases.add(entry.key);
      }
    }
    for (final caseId in staleCases) {
      _conversationHistory.remove(caseId);
      _caseLastActivity.remove(caseId);
    }
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
  /// Seed the conversation history for a case from previously saved messages.
  ///
  /// Call this after loading messages from Supabase so the AI has context
  /// from prior conversations.
  void seedHistory(String caseId, List<Map<String, String>> messages) {
    if (messages.isEmpty) return;
    _conversationHistory.putIfAbsent(caseId, () => []);
    final existing = _conversationHistory[caseId]!;
    // Only seed if history is empty (avoid duplicates on reload)
    if (existing.isNotEmpty) return;
    for (final msg in messages) {
      existing.add(msg);
    }
    // Trim to max
    if (existing.length > _maxHistoryMessages) {
      _conversationHistory[caseId] =
          existing.sublist(existing.length - _maxHistoryMessages);
    }
    _caseLastActivity[caseId] = DateTime.now();
  }

  Future<ChatResponse> sendChatMessage({
    required String caseId,
    required String message,
    List<String>? attachmentIds,
    CaseType? caseType,
    String? country,
    String? nationality,
    String? caseDescription,
    String? userLanguage,
    String? userName,
  }) async {
    // Sanitize user input before any AI processing
    final sanitizedMessage = _sanitizeInput(message);

    if (isUsingRealAI) {
      // ── Free-tier daily limit check ──
      final allowed = await _checkAndIncrementDailyLimit();
      if (!allowed) {
        return const ChatResponse(
          message: 'You have used all $_freeTotalLimit free AI messages. '
              'Upgrade to Legal Counsel for unlimited AI assistance!',
          disclaimer: null,
        );
      }

      // ── Response cache check (skip map lookup if cache is empty) ──
      if (_responseCache.isNotEmpty) {
        final cached = _getCachedResponse(sanitizedMessage);
        if (cached != null) {
          _log.i('Cache hit for query');
          _addToHistory(caseId, 'user', sanitizedMessage);
          _addToHistory(caseId, 'assistant', cached);
          return ChatResponse(
            message: cached,
            disclaimer:
                'This is AI-generated legal information, not legal advice. '
                'Please consult a qualified attorney for advice specific to your situation.',
          );
        }
      }

      _log.i('Using Claude API for chat');
      try {
        // Determine if this is a simple query (greetings, meta-questions)
        final isSimple = ClaudeService.isSimpleQuery(sanitizedMessage);

        // Choose model based on query complexity
        final model = isSimple
            ? ClaudeService.modelHaiku
            : ClaudeService.chooseModel(sanitizedMessage);
        final maxTokens = isSimple ? 200 : ClaudeService.maxTokensForModel(model);
        _log.i('Model routing: $model (simple: $isSimple, maxTokens: $maxTokens)');

        // Add user message to history
        _addToHistory(caseId, 'user', sanitizedMessage);

        // Build system prompt: light prompt for simple queries, full for complex
        String systemPrompt;
        if (isSimple) {
          systemPrompt = SystemPrompts.buildLightPrompt(
            userLanguage: userLanguage,
          );
        } else {
          systemPrompt = SystemPrompts.buildChatPrompt(
            caseType: caseType,
            country: country,
            nationality: nationality,
            caseContext: caseDescription,
            userLanguage: userLanguage,
            query: sanitizedMessage,
            useReducedContext: model == ClaudeService.modelHaiku,
          );
        }

        // Personalize: tell the AI the user's name so it can greet them
        if (userName != null && userName.isNotEmpty) {
          systemPrompt += '\n\nThe user\'s name is $userName. '
              'Address them by name when appropriate (e.g. greetings).';
        }

        // Build messages with summarized older history.
        // For simple queries, skip history to reduce input tokens.
        final List<Map<String, String>> messages;
        if (isSimple) {
          messages = [{'role': 'user', 'content': sanitizedMessage}];
        } else {
          messages = _buildMessagesForApi(caseId);
          if (messages.isEmpty) {
            messages.add({'role': 'user', 'content': sanitizedMessage});
          }
        }

        // For simple queries: skip tools (saves ~500 input tokens and tool parsing overhead).
        // For complex queries: include tools for full functionality.
        final Map<String, dynamic> rawResponse;
        if (isSimple) {
          final textOnly = await _claudeService.sendMessage(
            messages: messages,
            systemPrompt: systemPrompt,
            maxTokens: maxTokens,
            model: model,
          );
          // Add to history and return immediately — no tool processing needed.
          _addToHistory(caseId, 'assistant', textOnly);
          _cacheResponse(sanitizedMessage, textOnly);
          return ChatResponse(
            message: textOnly,
            disclaimer:
                'This is AI-generated legal information, not legal advice. '
                'Please consult a qualified attorney for advice specific to your situation.',
          );
        }

        rawResponse = await _claudeService.sendMessageWithTools(
          messages: messages,
          systemPrompt: systemPrompt,
          maxTokens: maxTokens,
          model: model,
        );

        // Log token usage
        final usage = rawResponse['usage'] as Map<String, dynamic>?;
        if (usage != null) {
          _log.i('Tokens — input: ${usage['input_tokens']}, '
              'output: ${usage['output_tokens']}, '
              'model: $model');
        }

        // Check if Claude wants to use a tool
        if (_claudeService.hasToolUse(rawResponse)) {
          // Extract any accompanying text from the response
          final textContent = _claudeService.extractText(rawResponse);
          // Add text to history if present so context is preserved
          if (textContent.isNotEmpty) {
            _addToHistory(caseId, 'assistant', textContent);
          }

          return ChatResponse(
            message: textContent.isNotEmpty
                ? textContent
                : '', // text may be empty when only tool_use is returned
            disclaimer:
                'This is AI-generated legal information, not legal advice. '
                'Please consult a qualified attorney for advice specific to your situation.',
            toolUseResponse: rawResponse,
          );
        }

        // Normal text-only response
        final responseText = _claudeService.extractText(rawResponse);

        // Add assistant response to history
        _addToHistory(caseId, 'assistant', responseText);

        // Cache the response for future identical queries
        _cacheResponse(sanitizedMessage, responseText);

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

    // Proxy fallback — only attempt if a proxy base URL is configured.
    if (AppConfig.aiApiBaseUrl.isNotEmpty) {
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
        _log.e('Chat proxy fallback also failed', error: e);
        // Fall through to demo fallback below
      }
    }

    // Final fallback: return a helpful message instead of crashing.
    _log.w('All AI backends unavailable, returning fallback message');
    return const ChatResponse(
      message: 'AI assistant is temporarily unavailable. '
          'Please check your internet connection and try again. '
          'If the problem persists, restart the app.',
      disclaimer: null,
    );
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

  /// When the Claude response contains tool_use blocks, this holds the raw
  /// API response so that the caller (e.g. ChatToolBridge) can extract and
  /// execute tool calls.  `null` for plain text responses.
  final Map<String, dynamic>? toolUseResponse;

  const ChatResponse({
    required this.message,
    this.suggestedActions,
    this.disclaimer,
    this.toolUseResponse,
  });

  /// Whether this response contains tool calls that need to be executed.
  bool get hasToolUse => toolUseResponse != null;

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

// ── Internal helper ─────────────────────────────────────────────────────

/// A cached AI response with a creation timestamp.
class _CachedResponse {
  final String response;
  final DateTime timestamp;

  const _CachedResponse(this.response, this.timestamp);
}
