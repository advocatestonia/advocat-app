// case_file_extractor.dart — Case File auto-extraction.
// -----------------------------------------------------------------------------
// Ref: lib/models/case_file.dart
//      lib/services/case_file_service.dart
//      assets/prompts/case_file_extractor.txt
//      docs/visioning-council/case_file.md (Sprint 1, 2026-05-05)
//
// Extracts structured legal-case metadata (events, parties, deadlines,
// documents, key facts) from a single chat turn (user msg + AI reply) using
// Haiku-4.5. Cheap (~$0.0006/turn at our token budget) and fire-and-forget:
// the chat response NEVER waits for it.
//
// Pure function design:
//   * No Supabase IO here — the service layer persists the result.
//   * Returns [CaseFileExtraction.empty] on any error or short turn — the
//     caller treats null/empty identically.
//   * The extraction prompt lives in assets/prompts/case_file_extractor.txt
//     so we can iterate copy without redeploying app code.
// -----------------------------------------------------------------------------

import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/case_file.dart';
import 'claude_service.dart';

/// Riverpod DI — tests override the provider to inject a fake ClaudeService.
final caseFileExtractorProvider = Provider<CaseFileExtractor>((ref) {
  final claude = ref.watch(claudeServiceProvider);
  return CaseFileExtractor(claudeService: claude);
});

/// Min combined turn length (user + AI) before we bother running extraction.
/// Below this we'd just be burning Haiku calls on greetings.
const int _minTurnChars = 60;

/// Path to the extraction system prompt, relative to the Flutter asset
/// bundle. Public so tests can verify it's wired into pubspec.
const String kCaseFileExtractorPromptAsset =
    'assets/prompts/case_file_extractor.txt';

/// Max output tokens — keep tight, the JSON we ask for is small. Going too
/// high invites the model to hallucinate filler.
const int kCaseFileExtractorMaxTokens = 400;

class CaseFileExtractor {
  CaseFileExtractor({
    required ClaudeService claudeService,
    Future<String> Function(String key)? assetLoader,
  })  : _claude = claudeService,
        _loadAsset = assetLoader ?? rootBundle.loadString;

  final ClaudeService _claude;
  final Future<String> Function(String key) _loadAsset;

  String? _cachedPrompt;

  /// Lazily load the system prompt from assets. Cached for the lifetime
  /// of the service.
  Future<String> _systemPrompt() async {
    final cached = _cachedPrompt;
    if (cached != null) return cached;
    final p = await _loadAsset(kCaseFileExtractorPromptAsset);
    _cachedPrompt = p;
    return p;
  }

  /// Test seam — exposes the lazy-loaded prompt so tests can pin asset wiring.
  @visibleForTesting
  Future<String> systemPromptForTest() => _systemPrompt();

  /// Extract structured metadata from one chat turn.
  ///
  /// Returns [CaseFileExtraction.empty] when:
  ///   * the turn is too short to be worth a Haiku call,
  ///   * Claude is unavailable,
  ///   * the API call fails for any reason,
  ///   * the model emits malformed JSON.
  ///
  /// NEVER throws — callers use this fire-and-forget after the chat
  /// response has already been delivered to the user.
  Future<CaseFileExtraction> extractFromTurn({
    required String userMessage,
    required String aiResponse,
    String? caseId,
  }) async {
    final combined = userMessage.trim().length + aiResponse.trim().length;
    if (combined < _minTurnChars) return CaseFileExtraction.empty;
    if (!ClaudeService.isAvailable) return CaseFileExtraction.empty;

    try {
      final system = await _systemPrompt();
      final raw = await _claude.sendMessage(
        systemPrompt: system,
        messages: [
          {
            'role': 'user',
            'content':
                'USER: ${userMessage.trim()}\n\nAI: ${aiResponse.trim()}\n\nJSON:',
          },
        ],
        maxTokens: kCaseFileExtractorMaxTokens,
        model: ClaudeService.modelHaiku,
      );
      return CaseFileExtraction.fromRawJson(raw);
    } catch (_) {
      // Best-effort. If extraction fails the chat already succeeded — silently
      // drop and return empty. Logging is intentionally absent here so we
      // don't spam the console on every flaky network blip.
      return CaseFileExtraction.empty;
    }
  }
}
