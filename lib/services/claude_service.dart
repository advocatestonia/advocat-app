import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../config/app_config.dart';
import 'chat_stream_event.dart';
import 'jwt_refresh_policy.dart';
import 'law_search_client.dart';
import 'tool_definitions.dart';
import 'web_streaming_stub.dart' if (dart.library.js_interop) 'web_streaming_impl.dart';

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
  static const int _maxTokensHaiku = 800;

  /// Max output tokens for Sonnet (detailed answers).
  static const int _maxTokensSonnet = 2500;

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
    'palk', 'tööandja', 'leping', 'trahv', 'võlg', 'elatis',
    'hooldus', 'lahutus', 'pärand', 'pension', 'puue',
    'haigusleh', 'laen', 'pankrot', 'pettu', 'vargus', 'ähvard',
    // Russian civil/criminal terms
    'зарплат', 'увольн', 'договор', 'штраф', 'долг', 'алимент',
    'опека', 'развод', 'наследств', 'пенси', 'инвалид',
    'больнич', 'декрет', 'ипотек', 'кредит', 'банкрот',
    'мошенн', 'грабеж', 'кража', 'насили', 'побо', 'угроз',
    // ru: common verb/action stems users actually type (RU LLM quality fix
    // 2026-05-05). Matcher is substring-based, so 'уволи' covers
    // уволили/уволила/уволил/уволят.
    'уволи', 'обжалов', 'подал', 'выписк', 'нарушил', 'вынес',
    'депорт', 'компенсац', 'возмещ', 'жалоб',
    // English civil/criminal terms
    'salary', 'fired', 'contract', 'fine', 'debt', 'alimony',
    'custody', 'divorce', 'inheritance', 'pension', 'disability',
    'loan', 'bankruptcy', 'fraud', 'theft', 'threat',
    'child support', 'eviction', 'rent', 'landlord',
    // Finnish legal terms
    'palkka', 'irtisano', 'sopimus', 'sakko', 'velka', 'elatus',
    'huoltaj', 'avioero', 'perintö', 'eläke', 'vamma',
  ];

  /// Broader legal-domain stems used by [looksLegalish] (P0-3, 2026-05-05).
  /// Non-overlapping with [_complexKeywords] to avoid double counting in the
  /// match-count branches above. These cover RU/ET/EN/UK court/dispute/claim/
  /// contract vocabulary that users actually type when asking a legal
  /// question — the keyword-only `_complexKeywords` heuristic missed many
  /// short, plain-language legal turns ("can I appeal" / "kas ma saan
  /// vaidlustada" / "хочу подать иск") and routed them to Haiku.
  ///
  /// Substring matching, lower-cased input. Case folding on the input side
  /// keeps the list short.
  static const List<String> _legalishStems = [
    // RU broad (unique vs _complexKeywords).
    'иск', 'позов', 'подсуд', 'юридическ', 'правов', 'правонаруш',
    'трудово', 'арендодат', 'арендатор', 'выселени', 'возврат',
    // UK (Ukrainian) — not previously covered.
    'звільн', 'оскарж', 'скарг', 'позивач', 'відповідач',
    'трудов', 'спір', 'позовн', 'договір',
    // ET — Estonian legal-domain vocabulary missed by _complexKeywords.
    // Stems chosen to match common case-form variants while avoiding
    // collision with the bare adverb "vaid" (= only): we use the genitive
    // "vaide" and partitive "vaiet", plus the dispute family "vaidlus"
    // (covers vaidlustada / vaidlustamine). "hagi" matches hagi /
    // hagiavaldus. "kohtu" matches kohtu / kohtusse / kohtuasi /
    // kohtumäärus.
    'vaide', 'vaiet', 'vaidlus', 'hagi', 'töövaidlus', 'kohtu',
    'rikkumi', 'töölepingu', 'üürilepin', 'üüriand', 'üürnik',
    'koondami', 'tarbija', 'rahuldamata',
    // EN — broader civil/criminal terms not in _complexKeywords.
    'dispute', 'claim', 'plaintiff', 'defendant', 'tenant',
    'landlord', 'employer', 'employee', 'wrongful', 'breach',
    'sue ', 'suing', 'lawsuit', 'liable', 'compensation',
    'appeal ', 'appealing',
  ];

  /// Whether the message looks like a legal question.
  ///
  /// Keyword-based, no API call. Used by [chooseModel] to escalate to
  /// [modelSonnet] for legal turns even when the legacy keyword
  /// heuristic ([_complexKeywords] match-count) wouldn't have triggered.
  ///
  /// Coordinates with the RU-stem quick-win merged in 1c39ea8 — those stems
  /// stay in [_complexKeywords]; this list adds broader legal-domain
  /// vocabulary in RU/ET/EN/UK without duplicating them.
  static bool looksLegalish(String query) {
    final lower = query.toLowerCase();
    // First: any complex-keyword hit is a strong legal signal.
    if (_complexKeywords.any((kw) => lower.contains(kw))) return true;
    // Then: broader legal-domain stems (court/dispute/claim/contract).
    for (final stem in _legalishStems) {
      if (lower.contains(stem)) return true;
    }
    return false;
  }

  /// Determine the appropriate model for a query.
  ///
  /// Aggressively defaults to [modelHaiku] (3x faster) unless the query
  /// is clearly complex legal analysis requiring [modelSonnet].
  ///
  /// P0-3 (2026-05-05): when [userLanguage] is one of `ru/et/en/uk` and
  /// the query [looksLegalish], escalate to Sonnet even if the legacy
  /// keyword heuristic wouldn't have triggered. Legal questions deserve
  /// the Sonnet headroom regardless of message length / keyword count.
  /// Languages outside that set fall back to legacy behaviour exactly
  /// (no regression for FI/DE/SV/etc.).
  static String chooseModel(String query, {String? userLanguage}) {
    final lower = query.toLowerCase();

    // Short messages (< 150 chars) without complex keywords -> always Haiku
    // — UNLESS the message looks legal-ish for a covered language. Without
    // this gate the new legal-detection path would never fire on short
    // queries like "can I appeal this".
    if (query.length < 150) {
      final hasComplexKeyword =
          _complexKeywords.any((kw) => lower.contains(kw));
      if (!hasComplexKeyword) {
        if (_isLegalishLanguage(userLanguage) && looksLegalish(query)) {
          return modelSonnet;
        }
        return modelHaiku;
      }
    }

    // Only use Sonnet if MULTIPLE complex keywords found (truly complex query)
    final matchCount =
        _complexKeywords.where((kw) => lower.contains(kw)).length;
    if (matchCount >= 2) return modelSonnet;

    // Very long messages (> 300 chars) with at least one keyword -> Sonnet
    if (query.length > 300 && matchCount >= 1) return modelSonnet;

    // P0-3: legal-question escalation for ru/et/en/uk users.
    if (_isLegalishLanguage(userLanguage) && looksLegalish(query)) {
      return modelSonnet;
    }

    // Default: Haiku for speed
    return modelHaiku;
  }

  /// Whether [userLanguage] is in the set covered by the legal-question
  /// escalation rule. Null means "unknown" — keep legacy behaviour
  /// (no escalation) so existing call-sites that don't yet pass language
  /// remain byte-equal to pre-P0-3.
  static bool _isLegalishLanguage(String? userLanguage) {
    if (userLanguage == null) return false;
    return userLanguage == 'ru' ||
        userLanguage == 'et' ||
        userLanguage == 'en' ||
        userLanguage == 'uk';
  }

  /// Get the recommended max tokens for a given model.
  static int maxTokensForModel(String model) {
    return model == modelHaiku ? _maxTokensHaiku : _maxTokensSonnet;
  }

  /// Retrieve relevant law paragraphs for a user query (P0-3, 2026-05-05).
  ///
  /// Wraps [LawSearchClient.search] with the chat-turn budget (3 s) and
  /// soft-fail semantics: any error / timeout / empty result returns an
  /// empty list, and the caller skips RAG injection. Never let a search
  /// failure break a chat turn.
  ///
  /// Until P0-2 deploys the `law-search` Edge Function, this returns []
  /// after a single quick failure. That's the graceful fallback contract.
  static Future<List<LawChunk>> retrieveLawContext({
    required String query,
    required String lang,
    int matchCount = LawSearchClient.defaultMatchCount,
    double similarityThreshold = LawSearchClient.defaultSimilarityThreshold,
  }) async {
    return LawSearchClient.search(
      query: query,
      lang: lang,
      matchCount: matchCount,
      similarityThreshold: similarityThreshold,
    );
  }

  /// Choose a model for a tool-eligible turn (Anthropic engineer consilium,
  /// 2026-05-05). Tool turns benefit from Sonnet because the model has to
  /// (a) decide whether to call a tool, (b) interleave thinking between
  /// tool_use blocks (requires `interleaved-thinking-2025-05-14` beta —
  /// already attached in claude-proxy), and (c) stitch the tool result
  /// into a final answer. Haiku tends to short-circuit step (b).
  ///
  /// Routing matrix:
  ///
  ///   hasTools=true  + isAuthenticated=true  + !isSimpleQuery → Sonnet
  ///   hasTools=true  + isAuthenticated=false                  → Haiku
  ///       (anon callers cannot reach Sonnet — server clamps their
  ///       max_tokens to 500 and refuses thinking. Sonnet $ on them
  ///       would be pure burn. See claude-proxy/index.ts ANON_MAX_TOKENS.)
  ///   hasTools=true  + isAuthenticated=true  +  isSimpleQuery → Haiku
  ///       (greetings stay on Haiku — 12x cheaper, response is short.)
  ///   hasTools=false                                          → chooseModel
  ///       (legacy keyword heuristic — unchanged for non-tool turns.)
  ///
  /// Cost ceiling: Sonnet adds ~$0.05/turn vs Haiku for typical legal
  /// turns with thinking. Anon-path seal pinned by
  /// claude_service_routing_test.dart and the server-side
  /// classify_complexity_test.ts.
  static String chooseModelForTools(
    String query, {
    required bool hasTools,
    required bool isAuthenticated,
    String? userLanguage,
  }) {
    // Non-tool turns keep legacy behaviour exactly. Pin via direct delegation.
    if (!hasTools) {
      return chooseModel(query, userLanguage: userLanguage);
    }
    // Cost-control invariant: anon never reaches Sonnet.
    if (!isAuthenticated) {
      return modelHaiku;
    }
    // Simple greetings stay on Haiku — short reply, no need for Sonnet
    // headroom. Tools attached or not.
    if (isSimpleQuery(query)) {
      return modelHaiku;
    }
    // Authenticated, non-trivial, tool-eligible turn → Sonnet.
    return modelSonnet;
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
    if (query.length < 10) return true;
    return false;
  }

  /// Patterns that indicate the user wants a SHORT answer (yes/no, list, or
  /// direct command). Used by [isShortQuery] to trigger a tight max_tokens
  /// budget and an "adaptive response length" instruction in the system
  /// prompt — fixing the "AI always writes 5-paragraph essays" bug.
  //
  // NOTE on matching: Dart RegExp treats `\b` as ASCII word-boundary only,
  // so after a Cyrillic letter `\b` does not fire. Also `caseSensitive: false`
  // does not perform Unicode case-folding by default. We therefore lowercase
  // the input in [isShortQuery] before matching, use `(\s|$)` after non-ASCII
  // tokens, and enable the unicode flag on patterns that touch Cyrillic or
  // Estonian letters.
  static final List<RegExp> _shortQueryPatterns = [
    // "Yes or no:" / "Да или нет:" phrasings.
    RegExp(r'\byes\s+or\s+no\b'),
    RegExp(r'да\s+или\s+нет', unicode: true),
    // Pure yes/no questions by prefix.
    RegExp(r'^(can|is|are|do|does|will|should|may|am)\b'),
    RegExp(r'^(могу|можно|это|будет|надо)(\s|$)', unicode: true),
    RegExp(r'^kas\b'),
    RegExp(r'^(voi|voiko|voinko)\b'),
    // List / checklist requests.
    RegExp(r'\b(list|checklist)\b'),
    RegExp(r'^(составь|сделай|дай)\s+(список|чеклист|перечень)',
        unicode: true),
    RegExp(r'^(koosta|anna)\s+nimekiri\b'),
    RegExp(r'^give\s+me\s+(a\s+)?(list|checklist)\b'),
    // Direct commands.
    RegExp(r'^(extend|postpone|cancel|open|close)\b'),
    RegExp(r'^(продли|отмени|открой|закрой)(\s|$)', unicode: true),
    RegExp(r'^(pikenda|tühista|ava|sulge)(\s|$)', unicode: true),
  ];

  /// Whether the query deserves a short (<= ~200 tokens) answer.
  ///
  /// Complements [isSimpleQuery]: a query can be complex legally but still
  /// want a short answer (e.g. "Yes or no: can I appeal this decision?").
  /// Explicit verbosity markers ("in detail", "подробно", "üksikasjalikult")
  /// override the short classification.
  static bool isShortQuery(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return false;
    final lower = trimmed.toLowerCase();

    const verbosityMarkers = [
      'in detail', 'thoroughly', 'walk me through',
      'step by step', 'step-by-step',
      'подробно', 'в деталях',
      'üksikasjalikult', 'samm-sammult',
      'yksityiskohtaisesti',
    ];
    for (final m in verbosityMarkers) {
      if (lower.contains(m)) return false;
    }

    if (trimmed.length > 180) return false;

    for (final pattern in _shortQueryPatterns) {
      if (pattern.hasMatch(lower)) return true;
    }

    if (trimmed.length <= 40 && trimmed.endsWith('?')) {
      return true;
    }
    return false;
  }

  /// Tight token budget for short queries. Prevents Claude from padding a
  /// one-sentence answer into a five-paragraph essay.
  static int maxTokensForShortQuery() => 200;

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
    List<Map<String, dynamic>>? multimodalMessages,
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

    // multimodalMessages wins when provided — used by the vision path so the
    // last user turn can carry image blocks alongside text. When null we
    // forward the plain text-only list as before (backwards compatible).
    final List<dynamic> outgoingMessages =
        multimodalMessages ?? messages;

    final body = {
      'model': model ?? modelSonnet,
      'max_tokens': maxTokens,
      'temperature': temperature,
      'system': systemPrompt,
      'messages': outgoingMessages,
      // Includes both client-executed tools (check_company, etc.) and
      // Anthropic server tools (web_search). The proxy forwards them
      // as-is; Anthropic handles web_search server-side.
      if (includeTools) 'tools': ToolDefinitions.allTools,
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

        // Pre-launch fix (2026-04-29): when the proxy returns the
        // structured rate_limit (429) / overload (529) shape, propagate
        // the error code to callers immediately — no retry, no swallowed
        // message. Callers (AIService) refund the quota and the UI shows
        // a localized friendly message.
        if (statusCode == 429 || statusCode == 529) {
          throw ClaudeServiceException.fromProxyError(
            e.response?.data,
            statusCode: statusCode!,
            cause: e,
          );
        }

        // Don't retry on client errors (other than 429, already handled
        // above). Anthropic 5xx and network errors fall through to the
        // retry loop.
        if (statusCode != null &&
            statusCode >= 400 &&
            statusCode < 500) {
          final errorBody = e.response?.data;
          final errorMsg = errorBody is Map
              ? (errorBody['error']?['message'] as String? ??
                  'API request failed')
              : 'API request failed with status $statusCode';
          throw ClaudeServiceException(errorMsg, e);
        }

        // Retry on 5xx or network errors.
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
  ///
  /// When [multimodalMessages] is supplied, it overrides [messages] on the
  /// wire — used for the vision path where the last user turn carries an
  /// image content block. [messages] remains the authoritative typed
  /// argument for the text-only case and for callers that do not care
  /// about vision.
  Future<Map<String, dynamic>> sendMessageWithTools({
    required List<Map<String, String>> messages,
    required String systemPrompt,
    int maxTokens = 4096,
    String? model,
    List<Map<String, dynamic>>? multimodalMessages,
  }) async {
    _log.d('Sending message with tools to Claude '
        '(${(multimodalMessages ?? messages).length} messages, '
        'model: ${model ?? modelSonnet})');

    return _callApi(
      systemPrompt: systemPrompt,
      messages: messages,
      maxTokens: maxTokens,
      temperature: 0.3,
      includeTools: true,
      model: model,
      multimodalMessages: multimodalMessages,
    );
  }

  /// Analyze a document's text content.
  Future<ClaudeAnalysisResult> analyzeDocument({
    required String text,
    required String language,
    String? caseContext,
  }) async {
    _log.d('Analyzing document (${text.length} chars, lang: $language)');

    final systemPrompt = '''You are Advocat, a legal document analysis assistant with the voice of a skilled practising lawyer.
Analyze the following document and return a JSON object with these fields:
- "summary": a concise summary (2-3 sentences)
- "key_points": array of key points found in the document
- "legal_references": array of any laws, regulations, or legal provisions mentioned (use the jurisdiction's native citation form: "KarS § X", "HMS § X lg Y", "ст. X УК РФ", "Rikoslaki X luku § Y", "§ X BGB")
- "action_items": array of actions the person should take based on this document
- "detected_language": the language of the document (ISO 639-1 code)

LANGUAGE QUALITY: Write every string in native-level $language with correct grammar, legal register (not casual, not academic), and proper typography (« » / „" / " ", real ellipsis …, en-dash for ranges, non-breaking space before § and units). Use formal address ("Вы" / "teie" / "Sie" / "vous"). No slang, no emoji, no machine-translation artefacts.

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

  /// Legacy text-only streaming. Delegates to [sendMessageStreamingEvents]
  /// and filters down to text deltas via [ChatStreamEventTextExt.toTextStream].
  ///
  /// Kept for backward compatibility with call sites that pre-date the
  /// Reasoning Trail surface (2026-05-05). New code should consume the
  /// typed-event stream directly so it can show thinking + tool stages.
  Stream<String> sendMessageStreaming({
    required List<Map<String, String>> messages,
    required String systemPrompt,
    int maxTokens = 4096,
    String? model,
    List<Map<String, dynamic>>? tools,
    double temperature = 0.3,
    Map<String, dynamic>? thinking,
  }) {
    return sendMessageStreamingEvents(
      messages: messages,
      systemPrompt: systemPrompt,
      maxTokens: maxTokens,
      model: model,
      tools: tools,
      temperature: temperature,
      thinking: thinking,
    ).toTextStream();
  }

  /// Typed streaming surface (Reasoning Trail v1, 2026-05-05). Yields
  /// [ChatStreamEvent] subtypes — text deltas, thinking stages, tool_use
  /// blocks, tool results — one event per Anthropic SSE event we recognise.
  ///
  /// On **Flutter Web**, this uses the browser's native `fetch()` API via
  /// JS interop (see `web/streaming.js`). The current JS bridge surfaces
  /// only the assembled text, so on Web we wrap each chunk into a
  /// `TextDelta` event. Thinking/tool events are degraded to no-ops on
  /// Web until `web/streaming.js` is upgraded — non-blocking for v1
  /// because the Reasoning Trail falls back gracefully when no
  /// thinking/tool events arrive (the pill just rotates the idle caption).
  ///
  /// On **mobile/desktop**, this uses Dio with `ResponseType.stream` and
  /// the SSE parser dispatches every event type Anthropic emits.
  Stream<ChatStreamEvent> sendMessageStreamingEvents({
    required List<Map<String, String>> messages,
    required String systemPrompt,
    int maxTokens = 4096,
    String? model,
    List<Map<String, dynamic>>? tools,
    double temperature = 0.3,
    Map<String, dynamic>? thinking,
  }) async* {
    if (!isAvailable) {
      throw const ClaudeServiceException(
        'Claude API is not configured. Set SUPABASE_URL or CLAUDE_API_KEY.',
      );
    }

    // BUG#3 fix (2026-04-29): refresh the Supabase JWT BEFORE opening
    // the SSE pipe when we're about to authenticate via the proxy.
    // Sonnet streams can run 30-90s; if the access token expires
    // mid-stream the proxy returns 401 and the user sees a truncated
    // reply with no error surface. The policy is a no-op when the
    // token has plenty of life left, so the happy path is free.
    if (_useProxy) {
      try {
        await JwtRefreshPolicy.ensureFreshSession(
          auth: SupabaseAuthShim(),
        );
      } on JwtRefreshException catch (e) {
        // Genuine auth refresh failure — surface to login flow.
        throw ClaudeServiceException(
          'Session expired and refresh failed — please log in again',
          e,
        );
      } catch (e) {
        // Supabase not initialized / shim construction fail / unexpected —
        // skip JWT refresh; proxy handles auth via anon JWT.
        // Without this catch, any non-JwtRefreshException bubbles up to the
        // chat handler and shows "напишите в поддержку" fallback.
      }
    }

    // Rate limiting
    if (_lastRequestTime != null) {
      final elapsed =
          DateTime.now().difference(_lastRequestTime!).inMilliseconds;
      const throttleMs = 300;
      final remaining = throttleMs - elapsed;
      if (remaining > 0) {
        await Future<void>.delayed(Duration(milliseconds: remaining));
      }
    }
    _lastRequestTime = DateTime.now();

    final body = <String, dynamic>{
      'model': model ?? modelSonnet,
      'max_tokens': maxTokens,
      'temperature': temperature,
      'system': systemPrompt,
      'messages': messages,
      'stream': true,
    };
    if (tools != null && tools.isNotEmpty) body['tools'] = tools;
    // Reasoning Trail (2026-05-05): pass extended-thinking config through
    // to Anthropic. Server-side classifier in claude-proxy may also inject
    // its own based on message complexity — we forward the user's explicit
    // setting unchanged so callers retain control.
    if (thinking != null) body['thinking'] = thinking;

    // ── Web: use browser fetch() for real streaming ──────────────────────
    if (kIsWeb) {
      final path = _useProxy ? '/claude-proxy' : '/v1/messages';
      final baseUrl = _useProxy
          ? '${AppConfig.supabaseUrl}/functions/v1'
          : 'https://api.anthropic.com';
      final fullUrl = '$baseUrl$path';
      final bodyJson = jsonEncode(body);
      final authToken = _useProxy ? AppConfig.supabaseAnonKey : '';
      final apiKey = _useProxy ? '' : AppConfig.claudeApiKey;

      // Web bridge today returns assembled text only (see web_streaming_impl.dart).
      // Wrap each chunk into a TextDelta. Thinking + tool stages will surface
      // once web/streaming.js is upgraded to forward the raw SSE event names —
      // tracked as a follow-up. The Reasoning Trail UI degrades gracefully:
      // no thinking events → idle pill rotates, no tool events → no tool chips.
      await for (final chunk in webSendMessageStreaming(
        url: fullUrl,
        bodyJson: bodyJson,
        authToken: authToken,
        apiKey: apiKey,
      )) {
        if (chunk.isNotEmpty) yield TextDelta(chunk);
      }
      yield const MessageDone();
      return;
    }

    // ── Native (mobile/desktop): use Dio streaming ──────────────────────
    final path = _useProxy ? '/claude-proxy' : '/v1/messages';

    final response = await _dio.post<ResponseBody>(
      path,
      data: body,
      options: Options(
        responseType: ResponseType.stream,
        headers: _useProxy
            ? {
                'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
              }
            : {
                'x-api-key': AppConfig.claudeApiKey,
                'anthropic-version': '2023-06-01',
              },
      ),
    );

    final byteStream = response.data!.stream;
    String buffer = '';

    // Stateful UTF-8 decoder — handles multibyte chars (Russian, Estonian)
    // split across TCP chunks. Accumulate raw bytes, decode in larger batches.
    const utf8Decoder = Utf8Decoder(allowMalformed: false);
    final rawBytes = <int>[];
    // Per-stream parser state — tracks active block type, pending sig, etc.
    final sseState = SseStreamState();
    await for (final chunk in byteStream) {
      rawBytes.addAll(chunk);
      // Try to decode all accumulated bytes
      String textChunk;
      try {
        textChunk = utf8Decoder.convert(rawBytes);
        rawBytes.clear();
      } catch (_) {
        // Incomplete multibyte sequence — wait for more bytes
        continue;
      }
      buffer += textChunk;

      // Process complete SSE lines. Reasoning Trail v1: we delegate the
      // event-mapping logic to [parseSseEvent] so it is unit-testable in
      // isolation, and we update side-effecty token counters here when
      // the parser surfaces the `_TokenUsageHint` sentinel via [parsed].
      while (buffer.contains('\n')) {
        final lineEnd = buffer.indexOf('\n');
        final line = buffer.substring(0, lineEnd).trim();
        buffer = buffer.substring(lineEnd + 1);

        // Skip empty lines (SSE event boundaries) and event: lines
        if (line.isEmpty || line.startsWith('event:')) continue;
        if (!line.startsWith('data: ')) continue;
        final data = line.substring(6);

        Map<String, dynamic>? parsed;
        try {
          parsed = jsonDecode(data) as Map<String, dynamic>;
        } catch (_) {
          continue; // Skip unparseable lines
        }

        // Side-effect: update token counters before emitting events. This
        // matches legacy behaviour and keeps callers from having to wire it.
        _absorbUsage(parsed);

        final events = parseSseEvent(parsed, state: sseState);
        for (final ev in events) {
          yield ev;
          if (ev is MessageDone) return;
        }
      }
    }
  }

  /// Update internal token counters from a parsed SSE event. Pure side
  /// effect — no events emitted. Called once per SSE event.
  void _absorbUsage(Map<String, dynamic> parsed) {
    final type = parsed['type'] as String?;
    if (type == 'message_start') {
      final message = parsed['message'] as Map<String, dynamic>?;
      final usage = message?['usage'] as Map<String, dynamic>?;
      if (usage != null) {
        _sessionInputTokens += (usage['input_tokens'] as int? ?? 0);
      }
    } else if (type == 'message_delta') {
      // usage.output_tokens is CUMULATIVE — assign, not add
      final usage = parsed['usage'] as Map<String, dynamic>?;
      if (usage != null) {
        _sessionOutputTokens =
            usage['output_tokens'] as int? ?? _sessionOutputTokens;
      }
    }
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
// SSE → ChatStreamEvent mapping (Reasoning Trail v1, 2026-05-05)
// ---------------------------------------------------------------------------

/// Pure mapping from one Anthropic SSE JSON payload to zero-or-more
/// [ChatStreamEvent]s. Exposed at top level (not on the service class) so
/// tests can feed canned SSE strings without instantiating Dio/HTTP.
///
/// Anthropic event model (in stream order):
///   • message_start                        — sets up message metadata
///   • content_block_start (type=text|thinking|tool_use|server_tool_use)
///   • content_block_delta (type=text_delta|thinking_delta|input_json_delta|signature_delta)
///   • content_block_stop                   — closes the active block
///   • (loop content_block_* for each block)
///   • message_delta                        — final usage etc.
///   • message_stop                         — terminal sentinel
///
/// We track which block-kind opened most recently (text vs thinking vs
/// tool_use) to interpret each delta correctly. Callers must reuse the same
/// [SseStreamState] across calls within one stream — see
/// [sendMessageStreamingEvents] for the pattern.
List<ChatStreamEvent> parseSseEvent(
  Map<String, dynamic> parsed, {
  SseStreamState? state,
}) {
  final s = state ?? _ambient;
  final type = parsed['type'] as String?;
  final out = <ChatStreamEvent>[];

  switch (type) {
    case 'message_start':
      s.reset();
      break;

    case 'content_block_start':
      final block = parsed['content_block'] as Map<String, dynamic>?;
      final blockType = block?['type'] as String?;
      s.activeBlockType = blockType;
      if (blockType == 'thinking') {
        out.add(const ThinkingStart());
      } else if (blockType == 'tool_use') {
        s.toolCount += 1;
        final name = block?['name'] as String? ?? 'unknown_tool';
        final id = block?['id'] as String? ?? '';
        out.add(ToolUseStart(name, id));
      } else if (blockType == 'server_tool_use') {
        // Anthropic-executed tools (e.g. web_search). Same UI treatment.
        s.toolCount += 1;
        final name = block?['name'] as String? ?? 'web_search';
        final id = block?['id'] as String? ?? '';
        out.add(ToolUseStart(name, id));
      }
      // 'text' block_start has no UI signal — text_delta carries the payload.
      break;

    case 'content_block_delta':
      final delta = parsed['delta'] as Map<String, dynamic>?;
      final dType = delta?['type'] as String?;
      switch (dType) {
        case 'text_delta':
          final text = delta!['text'] as String? ?? '';
          if (text.isNotEmpty) out.add(TextDelta(text));
          break;
        case 'thinking_delta':
          final text = delta!['thinking'] as String? ?? delta['text'] as String? ?? '';
          if (text.isNotEmpty) out.add(ThinkingDelta(text));
          break;
        case 'input_json_delta':
          final partial = delta!['partial_json'] as String? ?? '';
          if (partial.isNotEmpty) out.add(ToolInputDelta(partial));
          break;
        case 'signature_delta':
          // We accumulate the signature so ThinkingStop carries it.
          final sig = delta!['signature'] as String? ?? '';
          s.pendingSignature = (s.pendingSignature ?? '') + sig;
          break;
        // Unknown delta type — drop. Forward-compat: future Anthropic
        // additions don't break the UI.
      }
      break;

    case 'content_block_stop':
      final blockType = s.activeBlockType;
      if (blockType == 'thinking') {
        out.add(ThinkingStop(signature: s.pendingSignature));
        s.pendingSignature = null;
      } else if (blockType == 'tool_use' || blockType == 'server_tool_use') {
        out.add(const ToolUseStop());
      }
      // 'text' block_stop has no UI signal.
      s.activeBlockType = null;
      break;

    case 'tool_result':
      // Anthropic does NOT emit `tool_result` SSE events natively; this is
      // a synthetic event the local tool dispatcher injects after running
      // a tool locally (chat layer). Still parsed here so all sources of
      // events flow through the same surface.
      final result = (parsed['result'] as Map<String, dynamic>?) ?? const {};
      out.add(ToolResultReceived(Map<String, dynamic>.from(result)));
      break;

    case 'message_delta':
      // Usage info is absorbed by _absorbUsage; nothing to surface as an event.
      break;

    case 'message_stop':
      out.add(MessageDone(
        thinkingMs: s.thinkingMs,
        sources: s.toolCount,
      ));
      break;
  }

  return out;
}

/// Mutable per-stream parser state. One instance per call to
/// [ClaudeService.sendMessageStreamingEvents]. Public for tests; production
/// code lets the caller manage one (or uses [_ambient] when null).
class SseStreamState {
  String? activeBlockType;
  String? pendingSignature;
  int toolCount = 0;
  int? thinkingMs; // best-effort wall clock; populated by parser future ext
  void reset() {
    activeBlockType = null;
    pendingSignature = null;
    toolCount = 0;
    thinkingMs = null;
  }
}

// Process-wide fallback for tests that do not pass explicit state. Real
// streams always create their own state; this is purely a convenience for
// stateless single-event mapping tests.
final SseStreamState _ambient = SseStreamState();

// ---------------------------------------------------------------------------
// Exception
// ---------------------------------------------------------------------------

class ClaudeServiceException implements Exception {
  final String message;
  final Exception? cause;

  /// Pre-launch fix (2026-04-29): structured error code forwarded by the
  /// `claude-proxy` Edge Function for retry-friendly Anthropic statuses.
  ///
  /// Possible values:
  ///   • `'rate_limit'` — Anthropic 429 (Tier 1 50 RPM cap hit)
  ///   • `'overload'`   — Anthropic 529 (transient capacity issue)
  ///   • `null`         — any other 4xx/5xx (legacy / generic)
  ///
  /// Callers MUST check this code before deciding whether to refund a
  /// quota slot or surface a localized friendly message.
  final String? errorCode;

  /// Localization key the UI should look up when [errorCode] is set.
  /// Mirrors the `user_message_key` field returned by the Edge Function.
  final String? userMessageKey;

  /// Optional hint from Anthropic's `Retry-After` header (seconds). Null
  /// when absent or non-numeric.
  final int? retryAfterSeconds;

  const ClaudeServiceException(
    this.message, [
    this.cause,
  ])  : errorCode = null,
        userMessageKey = null,
        retryAfterSeconds = null;

  /// Internal constructor used by [fromProxyError]. Public constructor
  /// stays positional so existing call-sites are unaffected.
  const ClaudeServiceException._coded({
    required this.message,
    required this.errorCode,
    required this.userMessageKey,
    required this.retryAfterSeconds,
    this.cause,
  });

  /// Build an exception from a `claude-proxy` error body. Recognises the
  /// new structured shape (`{error:'rate_limit'|'overload', ...}`) and
  /// falls back to the legacy `{error:<string>}` shape for everything
  /// else, so older proxy versions keep working.
  factory ClaudeServiceException.fromProxyError(
    Object? body, {
    required int statusCode,
    Exception? cause,
  }) {
    if (body is Map) {
      final raw = body['error'];
      if (raw is String &&
          (raw == 'rate_limit' || raw == 'overload')) {
        final retry = body['retry_after_seconds'];
        return ClaudeServiceException._coded(
          message: 'Anthropic returned $statusCode ($raw)',
          errorCode: raw,
          userMessageKey: body['user_message_key'] as String?,
          retryAfterSeconds: retry is int ? retry : null,
          cause: cause,
        );
      }
      if (raw is String) {
        return ClaudeServiceException(raw, cause);
      }
    }
    return ClaudeServiceException(
      'Anthropic returned $statusCode',
      cause,
    );
  }

  @override
  String toString() => 'ClaudeServiceException: $message';
}
