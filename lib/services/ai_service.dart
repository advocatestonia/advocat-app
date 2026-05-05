import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode, visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../config/app_config.dart';
import '../models/case_model.dart';
import 'agentic_loop.dart';
import 'assistant_tools.dart';
import 'chat_attachment_service.dart';
import 'chat_stream_event.dart';
import 'citation_verifier.dart';
import 'claude_service.dart';
import 'language_detector.dart';
import 'supabase_service.dart';
import 'system_prompts.dart';
import 'user_memory_service.dart';
import 'voice_service.dart';
import 'voice_tag_stream_scrubber.dart';

// ---------------------------------------------------------------------------
// Quota typed response (P0-3)
// ---------------------------------------------------------------------------

/// Result of a `check-ai-quota` Edge Function call. Used by both the
/// non-streaming and streaming chat paths before any message is sent to
/// Claude. The struct is intentionally small so it can be cached in memory
/// for 60 s without leaking.
class AiQuota {
  const AiQuota({
    required this.allowed,
    required this.remaining,
    required this.limit,
    required this.plan,
    this.used = 0,
    this.unlimited = false,
  });

  final bool allowed;

  /// `null` means unlimited (pro).
  final int? remaining;

  /// Monthly free-tier limit, or -1 for pro.
  final int limit;

  /// `'free'` or `'pro'`.
  final String plan;

  final int used;
  final bool unlimited;

  bool get isPro => plan == 'pro' || unlimited || limit < 0;

  factory AiQuota.fromApi(Map<String, dynamic> api) {
    final plan = (api['plan'] as String?) ?? 'free';
    final unlimited = (api['unlimited'] as bool?) ?? false;
    final remaining = api['remaining'];
    return AiQuota(
      allowed: (api['allowed'] as bool?) ?? false,
      remaining: remaining is int ? remaining : null,
      limit: (api['limit'] as int?) ?? 7,
      plan: plan,
      used: (api['used'] as int?) ?? 0,
      unlimited: unlimited,
    );
  }

  /// Fall-closed response used when the `check-ai-quota` Edge Function is
  /// unreachable. Revenue-critical rule (see task 2026-04-23): deny by
  /// default rather than letting a free user fall back to an unbounded
  /// local counter. Pro users skip this path entirely.
  factory AiQuota.denied({int limit = 7}) {
    return AiQuota(
      allowed: false,
      remaining: 0,
      limit: limit,
      plan: 'free',
      used: limit,
      unlimited: false,
    );
  }

  /// Conservative client-side fallback used when the Edge Function is
  /// unreachable. We rely on SharedPreferences as a last-resort guard so
  /// offline clients still see *some* rate-limit — the real enforcement
  /// happens server-side.
  factory AiQuota.fromLocal({
    required int used,
    required int limit,
    required bool isPro,
  }) {
    return AiQuota(
      allowed: isPro || used < limit,
      remaining: isPro ? null : (limit - used).clamp(0, limit),
      limit: isPro ? -1 : limit,
      plan: isPro ? 'pro' : 'free',
      used: used,
      unlimited: isPro,
    );
  }
}

// ---------------------------------------------------------------------------
// Quota client abstraction (for tests + fallback)
// ---------------------------------------------------------------------------

abstract class AiQuotaClient {
  Future<AiQuota?> check();
  Future<AiQuota?> consume();
}

/// Production client — talks to the `check-ai-quota` Edge Function via
/// [SupabaseService.callEdgeFunction]. Returns `null` on transport error so
/// callers can degrade gracefully.
class SupabaseAiQuotaClient implements AiQuotaClient {
  SupabaseAiQuotaClient(this._supabase);
  final SupabaseService _supabase;

  @override
  Future<AiQuota?> check() => _call('check');

  @override
  Future<AiQuota?> consume() => _call('consume');

  Future<AiQuota?> _call(String action) async {
    try {
      final resp = await _supabase.callEdgeFunction(
        'check-ai-quota',
        body: {'action': action},
      );
      if (resp == null) return null;
      if (resp['error'] != null) return null;
      return AiQuota.fromApi(resp);
    } catch (_) {
      return null;
    }
  }
}

final aiServiceProvider = Provider<AIService>((ref) {
  final claudeService = ref.watch(claudeServiceProvider);
  final supabase = ref.watch(supabaseServiceProvider);
  final memoryService = ref.watch(userMemoryServiceProvider);
  final assistantTools = ref.watch(assistantToolsProvider);
  return AIService(
    claudeService: claudeService,
    quotaClient: SupabaseAiQuotaClient(supabase),
    memoryService: memoryService,
    assistantTools: assistantTools,
  );
});

/// Service that communicates with the AI backend.
///
/// When [AppConfig.useRealAI] is true **and** a Claude API key is configured,
/// requests are sent directly to the Claude Messages API via [ClaudeService].
/// Otherwise, requests go through the backend proxy endpoint (original flow).
class AIService {
  AIService({
    ClaudeService? claudeService,
    AiQuotaClient? quotaClient,
    UserMemoryService? memoryService,
    AssistantTools? assistantTools,
  })  : _claudeService = claudeService ?? ClaudeService(),
        _quotaClient = quotaClient,
        _memoryService = memoryService,
        _assistantTools = assistantTools,
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
  final AiQuotaClient? _quotaClient;

  /// Optional [AssistantTools] for the agentic loop. When wired, tool_use
  /// responses from Claude are executed in-loop and the actual tool_result
  /// blocks are sent back — instead of the legacy single-shot return.
  /// When null, the legacy single-shot behaviour is preserved (backwards
  /// compat for callers/tests that don't supply tools).
  final AssistantTools? _assistantTools;

  /// Optional ADR-001 Tier 1 memory service. When wired, chat calls
  /// inject the user's memory block into the system prompt and trigger
  /// extraction after the assistant finishes streaming.
  ///
  /// Null-safe: every memory path degrades to a plain chat call when
  /// this is null, which keeps tests and the proxy fallback simple.
  final UserMemoryService? _memoryService;
  final Dio _dio;
  final Logger _log;

  // ── ADR-001 Tier 1 — user memory integration ──────────────────────────
  //
  // Minimum number of messages in the current session before we bother
  // calling the extract-memory Edge Function. Extracting from a one-turn
  // exchange is expensive for no signal.
  static const int _memoryExtractionMinMessages = 4;

  /// Fetches the current user's top memories and formats them into a
  /// system-prompt block. Returns an empty string when no memory service
  /// is wired, when the user is not signed in, or on any transport error.
  ///
  /// Called from the chat paths right before [SystemPrompts.buildChatPrompt]
  /// is invoked. The [UserMemoryService.getMemories] call itself already
  /// swallows errors, but we keep an extra guard here so future changes
  /// to that contract never crash the chat pipeline.
  Future<String> _fetchMemoryBlock() async {
    final mem = _memoryService;
    if (mem == null) return '';
    try {
      final memories = await mem.getMemories(limit: 20);
      return UserMemoryService.buildMemoryBlock(memories);
    } catch (e) {
      _log.w('User memory fetch failed — continuing without it: $e');
      return '';
    }
  }

  /// Kicks off the extract-memory Edge Function for a chat session.
  ///
  /// Fire-and-forget by convention: callers use `unawaited(...)`. We do
  /// not wait for the result because extraction is best-effort and the
  /// user should never block on it. Short sessions (<4 messages) are
  /// skipped to avoid burning Haiku calls on greetings.
  Future<void> _triggerMemoryExtraction({
    required String sessionId,
    required List<({String role, String content})> messages,
  }) async {
    final mem = _memoryService;
    if (mem == null) return;
    if (messages.length < _memoryExtractionMinMessages) return;
    try {
      await mem.extractFromSession(
        messages: messages,
        sessionId: sessionId,
      );
    } catch (e) {
      _log.w('User memory extraction failed: $e');
    }
  }

  /// Test seam for the memory-fetch path. Not for production use.
  @visibleForTesting
  Future<String> fetchMemoryBlockForTest() => _fetchMemoryBlock();

  /// Test seam for the memory-extraction path. Not for production use.
  @visibleForTesting
  Future<void> triggerMemoryExtractionForTest({
    required String sessionId,
    required List<({String role, String content})> messages,
  }) =>
      _triggerMemoryExtraction(sessionId: sessionId, messages: messages);

  /// Smart Agent v2 — Verified Citations post-processor.
  ///
  /// Runs once on the assembled answer text after the agentic loop has
  /// finished. Any § citation in the text that is NOT backed by a
  /// `search_estonian_law` / `search_finnish_law` / `search_knowledge`
  /// tool call this turn is replaced with a soft-correction placeholder
  /// (see [CitationVerifier.unverifiedPlaceholder]).
  ///
  /// Pure delegation to the verifier — exposed as an instance method so
  /// the agentic-loop call site reads cleanly.
  String _applyCitationVerification(
    String text,
    List<LoopToolCall> toolCalls,
  ) {
    if (text.isEmpty) return text;
    final hits = CitationVerifier.findCitations(text);
    if (hits.isEmpty) return text;
    final unverified = CitationVerifier.filterUnverified(
      hits,
      toolCalls.map((c) => c.toCitationToolCall()).toList(),
    );
    if (unverified.isEmpty) return text;
    _log.i('Citation verifier: stripping ${unverified.length} unverified '
        'citation(s) of ${hits.length} total in this turn');
    return CitationVerifier.stripUnverified(text, unverified);
  }

  /// Test-only seam for the citation verifier — see
  /// [test/services/ai_citation_verifier_wiring_test.dart].
  @visibleForTesting
  String applyCitationVerificationForTest(
    String text,
    List<LoopToolCall> toolCalls,
  ) =>
      _applyCitationVerification(text, toolCalls);

  // ── Quota cache (P0-3) ─────────────────────────────────────────────
  //
  // Server-side quota is the source of truth, but hitting the Edge
  // Function on every streamed token would thrash the DB. We cache the
  // last check-result for 60 s — a single user cannot burn through more
  // than one message per minute under normal UX flows.

  AiQuota? _cachedQuota;
  DateTime? _cachedQuotaAt;
  static const Duration _quotaCacheTtl = Duration(seconds: 60);

  /// Check the server-side AI quota for the current user.
  ///
  /// Returns the cached value if younger than 60 s. **Fall-closed**: when
  /// the Edge Function is unreachable we deny the request rather than
  /// trust an unauthenticated local counter — this is the only way to
  /// prevent a free user from sending unlimited messages by simulating a
  /// 500 (or running the app offline). See task "Free tier has NO message
  /// limit" (2026-04-23).
  Future<AiQuota> checkQuota({bool forceRefresh = false}) async {
    if (isProUser) {
      return AiQuota.fromLocal(used: 0, limit: -1, isPro: true);
    }

    // Cache hit within TTL.
    if (!forceRefresh && _cachedQuota != null && _cachedQuotaAt != null) {
      if (DateTime.now().difference(_cachedQuotaAt!) < _quotaCacheTtl) {
        return _cachedQuota!;
      }
    }

    final fresh = await _quotaClient?.check();
    if (fresh != null) {
      _cachedQuota = fresh;
      _cachedQuotaAt = DateTime.now();
      return fresh;
    }

    _log.w('check-ai-quota unavailable — denying request (fall-closed)');
    return AiQuota.denied(limit: _freeTotalLimit);
  }

  /// Pre-launch fix (2026-04-29): refund the local quota cache after a
  /// rate-limit (429) or overload (529) from Anthropic.
  ///
  /// We don't have a server refund endpoint — the `check-ai-quota` Edge
  /// Function only exposes `check` and `consume`. Mutating the cache is
  /// the next-best mitigation: the UI shows the correct count immediately,
  /// and the next server `check` (cache TTL = 60s) brings the two back in
  /// sync. Net effect for the user: one fewer free message lost when
  /// Anthropic was momentarily unavailable.
  ///
  /// No-op for pro users (no quota to refund) and bounded so refund
  /// cannot push remaining above the monthly limit or used below zero.
  void _refundLocalQuota() {
    if (isProUser) return;
    final cached = _cachedQuota;
    if (cached == null || cached.isPro) return;
    final newUsed = (cached.used - 1).clamp(0, cached.limit);
    final newRemaining =
        (cached.limit - newUsed).clamp(0, cached.limit);
    _cachedQuota = AiQuota(
      allowed: newUsed < cached.limit,
      remaining: newRemaining,
      limit: cached.limit,
      plan: cached.plan,
      used: newUsed,
      unlimited: cached.unlimited,
    );
    _cachedQuotaAt = DateTime.now();
    _log.i('Local quota refunded after rate-limit/overload: '
        'remaining=$newRemaining/$newUsed used');
  }

  /// Test-only seam mirroring [_refundLocalQuota]. Production callers
  /// trigger the refund through the catch handler in [sendChatMessage] /
  /// [sendChatMessageStreaming] — this is purely a contract pin for tests.
  @visibleForTesting
  void refundLocalQuotaForTest() => _refundLocalQuota();

  /// Atomically increment the server counter and return the new state.
  /// Called right before each message is dispatched to Claude.
  ///
  /// **Fall-closed**: on Edge Function failure we deny the request so a
  /// broken server does not effectively hand free users unlimited AI.
  /// The previous behaviour (local SharedPreferences increment) was the
  /// root cause of the "free tier has no message limit" bug.
  Future<AiQuota> consumeQuota() async {
    if (isProUser) {
      return AiQuota.fromLocal(used: 0, limit: -1, isPro: true);
    }

    final fresh = await _quotaClient?.consume();
    if (fresh != null) {
      _cachedQuota = fresh;
      _cachedQuotaAt = DateTime.now();
      return fresh;
    }

    _log.w('check-ai-quota consume unavailable — denying request (fall-closed)');
    return AiQuota.denied(limit: _freeTotalLimit);
  }

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

  // ── Free-tier TOTAL limit (7 AI responses, per Founder's Beta policy) ──
  //
  // Enforced server-side in the `check-ai-quota` Edge Function. This
  // constant is the fallback limit used when building fall-closed
  // denials and must match `FREE_LIMIT` in
  // supabase/functions/check-ai-quota/index.ts.
  //

  /// Maximum free AI responses per user (aligned with the Founder's Beta
  /// refund policy: 14 days OR 7 AI responses).
  static const int _freeTotalLimit = 7;

  /// Public accessor for [_freeTotalLimit] so UI layers can render the
  /// current limit without duplicating the constant. Matches the server
  /// `FREE_LIMIT` in `supabase/functions/check-ai-quota/index.ts`.
  static int get freeTotalLimit => _freeTotalLimit;

  /// Whether the current user is a Pro subscriber.
  bool isProUser = false;

  /// Check if the free user has remaining AI messages, then atomically
  /// increment the server-side counter.
  ///
  /// Returns `false` when the Edge Function is unreachable (fall-closed) so
  /// the caller **must not** proceed to call Claude. Callers should show the
  /// upgrade CTA instead.
  Future<bool> _checkAndIncrementDailyLimit() async {
    if (isProUser) return true;
    final q = await consumeQuota();
    return q.allowed;
  }

  /// Public test-only wrapper around [_checkAndIncrementDailyLimit] so the
  /// enforcement test can verify the gate without instantiating a real
  /// ClaudeService / network stack.
  @visibleForTesting
  Future<bool> checkAndIncrementDailyLimitForTest() =>
      _checkAndIncrementDailyLimit();

  /// Test-only seam mirroring the quota gate at the top of
  /// [sendChatMessage]. Lets the double-decrement regression test pin
  /// down the fix without requiring `AppConfig.useRealAI` to be true
  /// in unit tests (which would need Supabase env vars).
  ///
  /// Contract:
  ///   - quotaAlreadyConsumed=false → consume once, return allowed
  ///   - quotaAlreadyConsumed=true  → skip consume, return true
  ///   - isProUser=true            → skip consume, return true
  @visibleForTesting
  Future<bool> sendChatMessageQuotaGateForTest({
    required bool quotaAlreadyConsumed,
  }) async {
    if (quotaAlreadyConsumed) return true;
    return _checkAndIncrementDailyLimit();
  }

  /// Get remaining free AI responses. Server-side is the source of truth.
  ///
  /// Returns `-1` for unlimited (pro) users. Returns `0` on fall-closed so
  /// the UI shows the upgrade CTA rather than an optimistic count derived
  /// from an untrusted local counter.
  Future<int> getRemainingFreeCalls() async {
    if (isProUser) return -1; // unlimited
    try {
      final q = await checkQuota();
      if (q.isPro) return -1;
      return q.remaining ?? 0;
    } catch (_) {
      return 0;
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

  /// Unicode tag characters (U+E0000-U+E007F): invisible ASCII-mirror
  /// code-points abused by 2024+ jailbreaks to smuggle hidden instructions
  /// inside foreign-script text. Stripped before pattern-matching.
  static final RegExp _unicodeTagRange =
      RegExp(r'[\u{E0000}-\u{E007F}]', unicode: true);

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
  /// Two pre-passes happen before pattern matching:
  ///   1. Strip Unicode tag characters (U+E0000-U+E007F) that are used
  ///      to smuggle invisible ASCII instructions inside a foreign-
  ///      script message.
  ///   2. Normalise Cyrillic homoglyphs to Latin so mixed-script evasion
  ///      (e.g. Cyrillic "а" for Latin "a") hits the English patterns.
  static String _sanitizeInput(String text) {
    // Pass 0: strip invisible Unicode tag characters
    final stripped = text.replaceAll(_unicodeTagRange, '');
    // Pass 1: normalise homoglyphs and check against all patterns
    final normalised = _normalizeCyrillicHomoglyphs(stripped);
    var sanitized = stripped;
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

  /// Test-only exposure of [_sanitizeInput]. Do not call from production code.
  @visibleForTesting
  static String sanitizeForTest(String text) => _sanitizeInput(text);

  // ── Proxy fallback response parser ─────────────────────────────────────
  //
  // Production bug (2026-04-29): the `/ai/chat` proxy used to return a
  // legacy `{message, suggested_actions, disclaimer}` body, but is now
  // pass-through to the Anthropic Messages API which returns
  // `{content: [{type:"text", text:"..."}], stop_reason, usage, ...}`.
  //
  // The previous `ChatResponse.fromJson(response.data)` cast threw on
  // every fallback hit, the catch swallowed the exception, and users
  // received the hardcoded English "AI assistant is temporarily
  // unavailable…" string — even Russian-speaking ones — making the
  // chat appear broken. This parser handles BOTH shapes so we degrade
  // gracefully no matter which version of the proxy is deployed.
  //
  // Exposed via `@visibleForTesting` so we can unit-test the parser
  // without spinning up the full Dio + Claude pipeline.
  @visibleForTesting
  static ChatResponse parseProxyChatResponseForTest(
    Map<String, dynamic> data,
  ) {
    // New (raw Anthropic) shape: {content: [{type:"text", text:"..."}]}
    if (data.containsKey('content') && data['content'] is List) {
      final blocks = data['content'] as List<dynamic>;
      final text = blocks
          .whereType<Map<String, dynamic>>()
          .where((b) => b['type'] == 'text')
          .map((b) => (b['text'] as String?) ?? '')
          .where((s) => s.isNotEmpty)
          .join('\n');
      // Voice-tag scrub (2026-04-29): Claude is permitted to emit
      // `[warmth]`, `[thoughtful]`, etc. for the TTS pipeline, but those
      // tags MUST be stripped before the chat UI renders the bubble.
      // See test/services/ai_service_voice_tag_strip_test.dart.
      return ChatResponse(
        message: VoiceService.stripVoiceTags(text),
        disclaimer: data['disclaimer'] as String?,
      );
    }
    // Legacy shape: {message, suggested_actions, disclaimer}
    final legacy = ChatResponse.fromJson(data);
    return ChatResponse(
      message: VoiceService.stripVoiceTags(legacy.message),
      disclaimer: legacy.disclaimer,
      suggestedActions: legacy.suggestedActions,
      toolUseResponse: legacy.toolUseResponse,
    );
  }

  // ── Conversation history for real AI mode ──────────────────────────────

  /// Per-case conversation history for Claude context.
  final Map<String, List<Map<String, String>>> _conversationHistory = {};

  /// Maximum messages to keep in conversation history per case.
  /// Increased from 20 to 50 so the AI retains more context across sessions.
  static const int _maxHistoryMessages = 50;

  /// Number of recent messages to keep as full content.
  /// Older messages are summarized to a single line each.
  static const int _fullContentMessages = 16;

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

  /// When the current user turn carries an image attachment, build a
  /// multimodal messages list that swaps the last `role: user` entry for
  /// an Anthropic content-block array:
  ///
  ///   [
  ///     {type: "image", source: {type: "base64", media_type: ..., data: ...}},
  ///     {type: "text",  text: "<user prompt> …Проанализируй приложенное..."}
  ///   ]
  ///
  /// Returns `null` when there is nothing to do (no attachment, non-image,
  /// or missing bytes) so callers can keep the plain text-only path.
  ///
  /// Static-only — no instance state needed. Exposed as `_maybe…` to keep
  /// it private; see [buildMultimodalMessagesForTest] for tests.
  List<Map<String, dynamic>>? _maybeBuildMultimodalMessages({
    required List<Map<String, String>> messages,
    required String userMessage,
    required ChatAttachment? imageAttachment,
  }) {
    if (imageAttachment == null || !imageAttachment.hasInlineImage) {
      return null;
    }
    final imageBlock = ChatAttachmentService.buildImageBlock(imageAttachment);
    if (imageBlock == null) return null;

    // Build the nudge the text block will carry alongside the image. We
    // intentionally include BOTH the original user prompt AND an explicit
    // Russian instruction: the system prompt is multilingual, but the
    // imperative "analyse the attached image" reliably forces the model to
    // treat the visual block as the primary subject rather than drift to
    // generic legal text.
    final textPart = userMessage.trim().isEmpty
        ? 'Проанализируй приложенное изображение.'
        : '$userMessage\n\nПроанализируй приложенное изображение.';

    final multimodal = <Map<String, dynamic>>[];
    // Copy all but the last message as-is (text history stays compact).
    for (var i = 0; i < messages.length - 1; i++) {
      multimodal.add({
        'role': messages[i]['role'] ?? 'user',
        'content': messages[i]['content'] ?? '',
      });
    }

    // Replace the last message (expected to be the current user turn) with
    // the multimodal content list. Defensive fallback: if the history is
    // empty for some reason, inject a single user turn instead.
    multimodal.add({
      'role': 'user',
      'content': [
        imageBlock,
        {'type': 'text', 'text': textPart},
      ],
    });
    return multimodal;
  }

  /// Test seam for the multimodal-builder. Not for production use.
  @visibleForTesting
  List<Map<String, dynamic>>? buildMultimodalMessagesForTest({
    required List<Map<String, String>> messages,
    required String userMessage,
    required ChatAttachment? imageAttachment,
  }) =>
      _maybeBuildMultimodalMessages(
        messages: messages,
        userMessage: userMessage,
        imageAttachment: imageAttachment,
      );

  /// Snapshot the current in-memory history for a case as the tuple
  /// shape expected by [UserMemoryService.extractFromSession]. We copy
  /// the list so the fire-and-forget extraction call cannot observe
  /// later mutations (e.g. the next user turn).
  List<({String role, String content})> _snapshotHistoryForExtraction(
    String caseId,
  ) {
    final history = _conversationHistory[caseId];
    if (history == null || history.isEmpty) return const [];
    return history
        .map((m) => (
              role: m['role'] ?? 'user',
              content: m['content'] ?? '',
            ))
        .toList(growable: false);
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
      // Document analysis is a billable Claude call — gate it with the
      // same server-side quota as chat/draft. Fall-closed on 500.
      final allowed = await _checkAndIncrementDailyLimit();
      if (!allowed) {
        throw const AIServiceException(
          'Free-tier AI quota exhausted. Upgrade to Advocat Pro to continue '
          'analyzing documents.',
        );
      }
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

    // Always replace with the full Supabase history when it has more context
    // than what's currently in memory. This ensures the AI never loses
    // conversation context after app resume or screen re-entry.
    if (existing.isNotEmpty && existing.length >= messages.length) {
      // In-memory history already has equal or more messages — skip.
      return;
    }

    // Replace with the full history from Supabase.
    existing.clear();
    final start = messages.length > _maxHistoryMessages
        ? messages.length - _maxHistoryMessages
        : 0;
    for (var i = start; i < messages.length; i++) {
      existing.add(messages[i]);
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
    String? clientContext,
    String? freeLimitMessage,
    ChatAttachment? imageAttachment,
    // Pre-launch fix (2026-04-29): when the streaming path has already
    // consumed quota for this turn and falls back here on a transient
    // ClaudeServiceException, the caller passes `true` so we skip a
    // second consume. Otherwise a single network blip costs the user
    // two free-tier slots. Pro users are unaffected (consumeQuota is a
    // no-op for them).
    bool quotaAlreadyConsumed = false,
  }) async {
    // Sanitize user input before any AI processing
    final sanitizedMessage = _sanitizeInput(message);

    // Post-launch BUG 1 fix (2026-04-22): per-message language override.
    // If the current message is clearly in a different language than the
    // user's profile preference, respond in the language of the message.
    // See lib/services/language_detector.dart for the heuristic.
    final effectiveUserLanguage = LanguageDetector.resolveUserLanguage(
      profileLanguage: userLanguage,
      message: sanitizedMessage,
    );

    if (isUsingRealAI) {
      // ── Free-tier daily limit check ──
      // Skip when the streaming path has already paid for this turn
      // (see [sendChatMessageStreaming] catch handler).
      if (!quotaAlreadyConsumed) {
        final allowed = await _checkAndIncrementDailyLimit();
        if (!allowed) {
          return ChatResponse(
            message: freeLimitMessage ??
                'You have used all $_freeTotalLimit free AI messages. '
                    'Upgrade to Legal Counsel for unlimited AI assistance!',
            disclaimer: null,
          );
        }
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
        // Adaptive length (fix/ai-quality bug 2): short questions (yes/no,
        // list, command) get a tight token budget so Claude cannot pad a
        // one-line answer into a five-paragraph essay.
        final bool isShort =
            !isSimple && ClaudeService.isShortQuery(sanitizedMessage);
        final int maxTokens;
        if (isSimple) {
          maxTokens = 200;
        } else if (isShort) {
          maxTokens = ClaudeService.maxTokensForShortQuery();
        } else {
          maxTokens = ClaudeService.maxTokensForModel(model);
        }
        _log.i('Model routing: $model (simple: $isSimple, short: $isShort, maxTokens: $maxTokens)');

        // Add user message to history
        _addToHistory(caseId, 'user', sanitizedMessage);

        // Build system prompt: light prompt for simple queries, full for complex
        String systemPrompt;
        if (isSimple) {
          systemPrompt = SystemPrompts.buildLightPrompt(
            userLanguage: effectiveUserLanguage,
          );
        } else {
          // ADR-001 Tier 1 — inject the user's memory block ahead of
          // the legal knowledge base. Safe no-op when not signed in.
          final memoryBlock = await _fetchMemoryBlock();
          systemPrompt = SystemPrompts.buildChatPrompt(
            caseType: caseType,
            country: country,
            nationality: nationality,
            caseContext: caseDescription,
            userLanguage: effectiveUserLanguage,
            query: sanitizedMessage,
            useReducedContext: model == ClaudeService.modelHaiku,
            memoryBlock: memoryBlock,
          );
        }

        // Prepend client knowledge base if available
        if (clientContext != null && clientContext.isNotEmpty) {
          systemPrompt = '# CLIENT PERSONAL KNOWLEDGE BASE\n\n$clientContext\n\n$systemPrompt';
        }

        // Personalize: tell the AI the user's name so it can greet them
        if (userName != null && userName.isNotEmpty) {
          systemPrompt += '\n\nThe user\'s name is $userName. '
              'Use their name naturally in conversation — at least once every 3-4 messages. '
              'Do not overuse it, just weave it in like a friend would.';
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

        // Vision path: when the current user turn carries an image, swap the
        // last user message in the outgoing request for a multimodal content
        // block list so Claude actually SEES the picture. read_document only
        // returns text, so it cannot analyse images — the visual channel is
        // the authoritative input for photos/screenshots.
        final List<Map<String, dynamic>>? multimodal =
            _maybeBuildMultimodalMessages(
          messages: messages,
          userMessage: sanitizedMessage,
          imageAttachment: imageAttachment,
        );

        rawResponse = await _claudeService.sendMessageWithTools(
          messages: messages,
          systemPrompt: systemPrompt,
          maxTokens: maxTokens,
          model: model,
          multimodalMessages: multimodal,
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
          // Smart Agent v2 (2026-05-05): proper Anthropic agentic loop.
          //
          // When [_assistantTools] is wired, drive a multi-turn loop with
          // real tool_result blocks so Claude can chain tools, recover
          // from errors, and compose a final answer in ONE chat turn —
          // instead of the legacy fake-user-followup hack that ran a
          // second ChatResponse round.
          //
          // When tools aren't wired (legacy callers, simple tests), we
          // fall through to the original single-shot behaviour: return
          // the toolUseResponse so chat_screen.dart's handler can render
          // the cards via ChatToolBridge as before.
          final tools = _assistantTools;
          if (tools == null) {
            final textContent = _claudeService.extractText(rawResponse);
            if (textContent.isNotEmpty) {
              _addToHistory(caseId, 'assistant', textContent);
            }
            return ChatResponse(
              message: textContent.isNotEmpty ? textContent : '',
              disclaimer:
                  'This is AI-generated legal information, not legal advice. '
                  'Please consult a qualified attorney for advice specific to your situation.',
              toolUseResponse: rawResponse,
            );
          }

          // Build the seed message list for the loop. We hand Claude back
          // its own first response (so iteration 0 inside the loop short-
          // circuits to "tool_use processing") via the canned send below.
          final loopMessages = <Map<String, dynamic>>[
            for (final m in messages) Map<String, dynamic>.from(m),
          ];

          // First call already happened above — the loop's first iteration
          // is already paid for. We feed the canned [rawResponse] back on
          // the FIRST invocation of the send closure, then route real
          // subsequent calls through [ClaudeService.sendMessageWithTools]
          // using its multimodalMessages channel (which accepts arbitrary
          // List-of-blocks content — exactly what the agentic loop sends).
          int sendCount = 0;
          Future<Map<String, dynamic>> sendFn(
              List<Map<String, dynamic>> msgs) async {
            if (sendCount == 0) {
              sendCount++;
              return rawResponse;
            }
            sendCount++;
            // Build a canonical block list. Each turn's content is either
            // a String (plain user text) or a List of blocks
            // (assistant tool_use / user tool_result). The proxy/Anthropic
            // accepts both shapes inside a single messages array.
            final wireMessages = msgs
                .map((m) => <String, dynamic>{
                      'role': m['role'],
                      'content': m['content'],
                    })
                .toList();
            return _claudeService.sendMessageWithTools(
              // The typed `messages` param is unused when multimodalMessages
              // wins — pass the original simple history for safety only.
              messages: messages,
              systemPrompt: systemPrompt,
              maxTokens: maxTokens,
              model: model,
              multimodalMessages: wireMessages,
            );
          }

          final outcome = await runAgenticLoop(
            initialMessages: loopMessages,
            send: sendFn,
            executeTool: tools.execute,
          );

          // Approval pause — preserve the legacy UI flow EXACTLY.
          if (outcome.stopReason == LoopStopReason.requiresApproval) {
            final partialText = outcome.text;
            if (partialText.isNotEmpty) {
              _addToHistory(caseId, 'assistant', partialText);
            }
            return ChatResponse(
              message: partialText,
              disclaimer:
                  'This is AI-generated legal information, not legal advice. '
                  'Please consult a qualified attorney for advice specific to your situation.',
              toolUseResponse: outcome.pendingApprovalResponse,
            );
          }

          // Loop produced a composed answer — verify citations and persist.
          var finalText = outcome.text;
          finalText = _applyCitationVerification(finalText, outcome.toolCalls);

          if (finalText.isNotEmpty) {
            _addToHistory(caseId, 'assistant', finalText);
            _cacheResponse(sanitizedMessage, finalText);
          }

          unawaited(_triggerMemoryExtraction(
            sessionId: caseId,
            messages: _snapshotHistoryForExtraction(caseId),
          ));

          return ChatResponse(
            message: finalText,
            disclaimer:
                'This is AI-generated legal information, not legal advice. '
                'Please consult a qualified attorney for advice specific to your situation.',
          );
        }

        // Normal text-only response
        final responseText = _claudeService.extractText(rawResponse);

        // Add assistant response to history
        _addToHistory(caseId, 'assistant', responseText);

        // Cache the response for future identical queries
        _cacheResponse(sanitizedMessage, responseText);

        // ADR-001 Tier 1 — fire-and-forget memory extraction. Safe no-op
        // when no memory service is wired, short conversations, or errors.
        unawaited(_triggerMemoryExtraction(
          sessionId: caseId,
          messages: _snapshotHistoryForExtraction(caseId),
        ));

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
        // Pre-launch fix (2026-04-29): on rate-limit (429) / overload
        // (529) from Anthropic, refund the local quota and re-throw so
        // the UI can show a localized friendly message instead of the
        // generic «Временная ошибка AI». Other errors still fall
        // through to the proxy fallback as before.
        if (e.errorCode == 'rate_limit' || e.errorCode == 'overload') {
          _refundLocalQuota();
          rethrow;
        }
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
        return parseProxyChatResponseForTest(
          response.data as Map<String, dynamic>,
        );
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

  // ── Streaming chat ─────────────────────────────────────────────────────

  /// Streaming version of [sendChatMessage] — yields text chunks as they
  /// arrive from the Claude API.
  ///
  /// For simple queries (greetings, meta-questions) the method falls back to
  /// the non-streaming path because those replies are too short to benefit
  /// from incremental rendering.
  ///
  /// After the stream completes the full response is saved to conversation
  /// history exactly as the non-streaming path would.
  Stream<String> sendChatMessageStreaming({
    required String caseId,
    required String message,
    String? userLanguage,
    String? userName,
    String? clientContext,
    CaseType? caseType,
    String? country,
    String? nationality,
    String? caseDescription,
    String? freeLimitMessage,
  }) async* {
    // Sanitize user input before any AI processing.
    final sanitizedMessage = _sanitizeInput(message);

    // Post-launch BUG 1 fix (2026-04-22): per-message language override.
    // Same logic as sendChatMessage — honour the language of THIS message
    // rather than the profile preference when they disagree.
    final effectiveUserLanguage = LanguageDetector.resolveUserLanguage(
      profileLanguage: userLanguage,
      message: sanitizedMessage,
    );

    // If real AI is not available, fall back to the regular method.
    if (!isUsingRealAI) {
      final response = await sendChatMessage(
        caseId: caseId,
        message: message,
        caseType: caseType,
        country: country,
        nationality: nationality,
        caseDescription: caseDescription,
        userLanguage: userLanguage,
        userName: userName,
        clientContext: clientContext,
        freeLimitMessage: freeLimitMessage,
      );
      yield response.message;
      return;
    }

    // ── Free-tier lifetime limit check ──
    final allowed = await _checkAndIncrementDailyLimit();
    if (!allowed) {
      yield freeLimitMessage ??
          'You have used all $_freeTotalLimit free AI messages. '
              'Upgrade to Legal Counsel for unlimited AI assistance!';
      return;
    }

    // ── Response cache check ──
    if (_responseCache.isNotEmpty) {
      final cached = _getCachedResponse(sanitizedMessage);
      if (cached != null) {
        _log.i('Cache hit for query (streaming path)');
        _addToHistory(caseId, 'user', sanitizedMessage);
        _addToHistory(caseId, 'assistant', cached);
        yield cached;
        return;
      }
    }

    // ── Simple queries: use non-streaming (too fast to benefit) ──
    final isSimple = ClaudeService.isSimpleQuery(sanitizedMessage);
    if (isSimple) {
      final response = await sendChatMessage(
        caseId: caseId,
        message: message,
        caseType: caseType,
        country: country,
        nationality: nationality,
        caseDescription: caseDescription,
        userLanguage: userLanguage,
        userName: userName,
        clientContext: clientContext,
        freeLimitMessage: freeLimitMessage,
      );
      yield response.message;
      return;
    }

    // ── Complex query — use streaming ──
    _log.i('Using Claude API for streaming chat');
    try {
      final model = ClaudeService.chooseModel(sanitizedMessage);
      final bool isShort = ClaudeService.isShortQuery(sanitizedMessage);
      final int maxTokens = isShort
          ? ClaudeService.maxTokensForShortQuery()
          : ClaudeService.maxTokensForModel(model);
      _log.i('Streaming model routing: $model (short: $isShort, maxTokens: $maxTokens)');

      // ADR-001 Tier 1 — inject user memory block ahead of the KB.
      final memoryBlock = await _fetchMemoryBlock();

      // Build system prompt (same logic as sendChatMessage).
      String systemPrompt = SystemPrompts.buildChatPrompt(
        caseType: caseType,
        country: country,
        nationality: nationality,
        caseContext: caseDescription,
        userLanguage: effectiveUserLanguage,
        query: sanitizedMessage,
        useReducedContext: model == ClaudeService.modelHaiku,
        memoryBlock: memoryBlock,
      );

      // Prepend client knowledge base if available.
      if (clientContext != null && clientContext.isNotEmpty) {
        systemPrompt =
            '# CLIENT PERSONAL KNOWLEDGE BASE\n\n$clientContext\n\n$systemPrompt';
      }

      // Personalize with user name.
      if (userName != null && userName.isNotEmpty) {
        systemPrompt += '\n\nThe user\'s name is $userName. '
            'Use their name naturally in conversation — at least once every 3-4 messages. '
            'Do not overuse it, just weave it in like a friend would.';
      }

      // Add user message to history.
      _addToHistory(caseId, 'user', sanitizedMessage);

      // Build messages with summarized older history.
      final messages = _buildMessagesForApi(caseId);
      if (messages.isEmpty) {
        messages.add({'role': 'user', 'content': sanitizedMessage});
      }

      // Stream from Claude.
      final fullResponse = StringBuffer();
      // BUG#2 fix (2026-04-29): voice tags like `[warmth]` MUST NOT
      // reach the chat UI. Tags can span chunk boundaries
      // (e.g. "[war" then "mth] Привет"), and legal-citation brackets
      // like `[Article 26]` MUST be preserved verbatim. The legacy
      // condition-based logic broke on three real prod inputs (cross-
      // chunk, mid-tag-space, and unclosed-tag-at-EOF). Replaced with
      // an explicit two-state scrubber pinned by
      // test/services/voice_tag_state_machine_test.dart.
      final scrubber = VoiceTagStreamScrubber();

      await for (final chunk in _claudeService.sendMessageStreaming(
        model: model,
        messages: messages,
        systemPrompt: systemPrompt,
        maxTokens: maxTokens,
        temperature: 0.3,
      )) {
        fullResponse.write(chunk);
        final emit = scrubber.feed(chunk);
        if (emit.isNotEmpty) yield emit;
      }
      // Flush any unclosed `[` tail verbatim — better visible truncation
      // than a silent drop. Matches the legacy guarantee that no user
      // text is ever lost on stream end.
      final tail = scrubber.flush();
      if (tail.isNotEmpty) yield tail;

      // After stream completes — save to history and cache.
      // Also strip voice tags from the persisted text so subsequent
      // turns (which feed history back into the prompt) don't carry
      // `[warmth]` artefacts that could confuse the model.
      final responseText = VoiceService.stripVoiceTags(fullResponse.toString());
      if (responseText.isNotEmpty) {
        _addToHistory(caseId, 'assistant', responseText);
        _cacheResponse(sanitizedMessage, responseText);

        // ADR-001 Tier 1 — fire-and-forget memory extraction. Runs in
        // the background so we never block the user on the Edge call.
        unawaited(_triggerMemoryExtraction(
          sessionId: caseId,
          messages: _snapshotHistoryForExtraction(caseId),
        ));
      }
    } on ClaudeServiceException catch (e) {
      _log.e('Claude streaming chat failed, falling back to non-streaming',
          error: e);
      // Remove the user message we added to history since streaming failed.
      _conversationHistory[caseId]?.removeLast();

      // Pre-launch fix (2026-04-29): on rate-limit (429) / overload
      // (529), refund the local quota and rethrow so chat_screen can
      // show a localized friendly message — there is no point retrying
      // the same Anthropic call right now.
      if (e.errorCode == 'rate_limit' || e.errorCode == 'overload') {
        _refundLocalQuota();
        rethrow;
      }

      // Fall back to non-streaming. Pass quotaAlreadyConsumed=true so
      // the fallback does NOT charge the user a second quota slot for
      // this same turn — a transient ClaudeServiceException must cost
      // exactly one free-tier message, not two (pre-launch fix).
      final response = await sendChatMessage(
        caseId: caseId,
        message: message,
        caseType: caseType,
        country: country,
        nationality: nationality,
        caseDescription: caseDescription,
        userLanguage: userLanguage,
        userName: userName,
        clientContext: clientContext,
        freeLimitMessage: freeLimitMessage,
        quotaAlreadyConsumed: true,
      );
      yield response.message;
    }
  }

  /// Reasoning Trail v1 (2026-05-05) — typed-event streaming surface.
  ///
  /// Mirrors [sendChatMessageStreaming] semantically (same fallbacks, same
  /// history/cache writes, same quota & error handling) but yields
  /// [ChatStreamEvent] subtypes instead of raw text. Consumers can light up
  /// the Reasoning Trail pill (thinking + tool stages) without losing the
  /// `TextDelta` text chunks the legacy UI relied on.
  ///
  /// The call sites that pre-date this surface keep using
  /// [sendChatMessageStreaming]; the chat screen migrates incrementally.
  Stream<ChatStreamEvent> sendChatMessageStreamingEvents({
    required String caseId,
    required String message,
    String? userLanguage,
    String? userName,
    String? clientContext,
    CaseType? caseType,
    String? country,
    String? nationality,
    String? caseDescription,
    String? freeLimitMessage,
  }) async* {
    final sanitizedMessage = _sanitizeInput(message);

    final effectiveUserLanguage = LanguageDetector.resolveUserLanguage(
      profileLanguage: userLanguage,
      message: sanitizedMessage,
    );

    // Mock / no-real-AI path → emit one TextDelta + Done so the UI flow
    // is identical regardless of source.
    if (!isUsingRealAI) {
      final response = await sendChatMessage(
        caseId: caseId,
        message: message,
        caseType: caseType,
        country: country,
        nationality: nationality,
        caseDescription: caseDescription,
        userLanguage: userLanguage,
        userName: userName,
        clientContext: clientContext,
        freeLimitMessage: freeLimitMessage,
      );
      yield TextDelta(response.message);
      yield const MessageDone();
      return;
    }

    final allowed = await _checkAndIncrementDailyLimit();
    if (!allowed) {
      yield TextDelta(freeLimitMessage ??
          'You have used all $_freeTotalLimit free AI messages. '
              'Upgrade to Legal Counsel for unlimited AI assistance!');
      yield const MessageDone();
      return;
    }

    if (_responseCache.isNotEmpty) {
      final cached = _getCachedResponse(sanitizedMessage);
      if (cached != null) {
        _log.i('Cache hit for query (streaming events path)');
        _addToHistory(caseId, 'user', sanitizedMessage);
        _addToHistory(caseId, 'assistant', cached);
        yield TextDelta(cached);
        yield const MessageDone();
        return;
      }
    }

    final isSimple = ClaudeService.isSimpleQuery(sanitizedMessage);
    if (isSimple) {
      final response = await sendChatMessage(
        caseId: caseId,
        message: message,
        caseType: caseType,
        country: country,
        nationality: nationality,
        caseDescription: caseDescription,
        userLanguage: userLanguage,
        userName: userName,
        clientContext: clientContext,
        freeLimitMessage: freeLimitMessage,
      );
      yield TextDelta(response.message);
      yield const MessageDone();
      return;
    }

    _log.i('Using Claude API for streaming chat (events surface)');
    try {
      final model = ClaudeService.chooseModel(sanitizedMessage);
      final bool isShort = ClaudeService.isShortQuery(sanitizedMessage);
      final int maxTokens = isShort
          ? ClaudeService.maxTokensForShortQuery()
          : ClaudeService.maxTokensForModel(model);
      _log.i('Streaming events model routing: $model (short: $isShort, maxTokens: $maxTokens)');

      final memoryBlock = await _fetchMemoryBlock();

      String systemPrompt = SystemPrompts.buildChatPrompt(
        caseType: caseType,
        country: country,
        nationality: nationality,
        caseContext: caseDescription,
        userLanguage: effectiveUserLanguage,
        query: sanitizedMessage,
        useReducedContext: model == ClaudeService.modelHaiku,
        memoryBlock: memoryBlock,
      );

      if (clientContext != null && clientContext.isNotEmpty) {
        systemPrompt =
            '# CLIENT PERSONAL KNOWLEDGE BASE\n\n$clientContext\n\n$systemPrompt';
      }

      if (userName != null && userName.isNotEmpty) {
        systemPrompt += '\n\nThe user\'s name is $userName. '
            'Use their name naturally in conversation — at least once every 3-4 messages. '
            'Do not overuse it, just weave it in like a friend would.';
      }

      _addToHistory(caseId, 'user', sanitizedMessage);

      final messages = _buildMessagesForApi(caseId);
      if (messages.isEmpty) {
        messages.add({'role': 'user', 'content': sanitizedMessage});
      }

      final fullResponse = StringBuffer();
      // Voice-tag scrubber operates on TextDelta only — thinking/tool deltas
      // never carry voice tags. The output text is yielded as a NEW TextDelta
      // (so consumers see scrubbed text), while the rest of the events pass
      // through untouched.
      final scrubber = VoiceTagStreamScrubber();

      await for (final event in _claudeService.sendMessageStreamingEvents(
        model: model,
        messages: messages,
        systemPrompt: systemPrompt,
        maxTokens: maxTokens,
        temperature: 0.3,
      )) {
        if (event is TextDelta) {
          fullResponse.write(event.text);
          final scrubbed = scrubber.feed(event.text);
          if (scrubbed.isNotEmpty) yield TextDelta(scrubbed);
        } else {
          yield event;
        }
      }

      // Flush any buffered tail from the scrubber.
      final tail = scrubber.flush();
      if (tail.isNotEmpty) yield TextDelta(tail);

      final responseText = VoiceService.stripVoiceTags(fullResponse.toString());
      if (responseText.isNotEmpty) {
        _addToHistory(caseId, 'assistant', responseText);
        _cacheResponse(sanitizedMessage, responseText);

        unawaited(_triggerMemoryExtraction(
          sessionId: caseId,
          messages: _snapshotHistoryForExtraction(caseId),
        ));
      }
    } on ClaudeServiceException catch (e) {
      _log.e('Claude streaming chat (events) failed, falling back', error: e);
      _conversationHistory[caseId]?.removeLast();

      if (e.errorCode == 'rate_limit' || e.errorCode == 'overload') {
        _refundLocalQuota();
        rethrow;
      }

      final response = await sendChatMessage(
        caseId: caseId,
        message: message,
        caseType: caseType,
        country: country,
        nationality: nationality,
        caseDescription: caseDescription,
        userLanguage: userLanguage,
        userName: userName,
        clientContext: clientContext,
        freeLimitMessage: freeLimitMessage,
        quotaAlreadyConsumed: true,
      );
      yield TextDelta(response.message);
      yield const MessageDone();
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
      // Draft generation is a billable Claude call — gate it with the
      // same server-side quota as chat. Fall-closed on 500.
      final allowed = await _checkAndIncrementDailyLimit();
      if (!allowed) {
        throw const AIServiceException(
          'Free-tier AI quota exhausted. Upgrade to Advocat Pro to continue '
          'generating drafts.',
        );
      }
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
      // Deadline extraction is a billable Claude call — gate it with the
      // same server-side quota. Fall-closed on 500.
      final allowed = await _checkAndIncrementDailyLimit();
      if (!allowed) {
        throw const AIServiceException(
          'Free-tier AI quota exhausted. Upgrade to Advocat Pro to continue '
          'extracting deadlines.',
        );
      }
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
