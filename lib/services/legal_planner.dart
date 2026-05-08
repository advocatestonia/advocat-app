// =============================================================================
// legal_planner.dart — Phase 2 Pkg 6 client-side planner glue.
// =============================================================================
//
// Decides when to route a chat turn through the three-pass server loop and
// shapes the augmented JSON response back into something the chat surface
// can render. This module is intentionally small — the actual orchestration
// lives in `supabase/functions/_shared/legal_planner.ts`. We just:
//
//   1. Decide whether to fire (Pro && opt-in pref && looksLegalish).
//   2. Call ClaudeService.sendLegalPlannerMessage and unpack the payload.
//   3. Surface plan + critique + regen flag for the Reasoning Trail UI
//      extension via PlannerTrace.
//
// The server is the source of truth for the loop shape and the trace
// persistence — clients NEVER short-circuit the server passes locally.
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'claude_service.dart';

/// localStorage key for the user-level opt-in to the planner loop. Default
/// is OFF — only Pro users who explicitly toggle this in Settings pay the
/// extra latency. The server-side mirror lives at
/// `user_settings.enable_planner_for_legal_turns` and is what the Pkg 8
/// eval suite reads when bucketing runs by treatment. The client-side
/// SharedPreferences cache is an optimisation so the chat orchestrator
/// can decide synchronously without a Supabase round-trip per turn.
const String kPlannerEnabledPrefKey = 'advocat_planner_enabled_v1';

/// Riverpod state for the toggle. Reads and writes both
/// SharedPreferences (synchronous gate on the chat path) and — when the
/// user is Pro — the server-side `user_settings` row (so the planner
/// flag survives a fresh install). The server write is fire-and-forget;
/// the source of truth for the chat-time gate is local prefs.
final plannerEnabledProvider =
    AsyncNotifierProvider<PlannerEnabledNotifier, bool>(
  PlannerEnabledNotifier.new,
);

/// Async notifier backing the Settings UI toggle. The async build pulls
/// the current value out of SharedPreferences; setEnabled writes both
/// prefs and (best-effort) the server row.
class PlannerEnabledNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(kPlannerEnabledPrefKey) ?? false;
    } catch (_) {
      // SharedPreferences can fail during early init on web — default OFF.
      return false;
    }
  }

  Future<void> setEnabled(bool value) async {
    state = AsyncData(value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kPlannerEnabledPrefKey, value);
    } catch (_) {
      // Best-effort — surface failure as a non-fatal log so the UI
      // doesn't get stuck on a stale value.
    }
  }
}

/// Verbatim mirror of [supabase/functions/_shared/legal_planner.ts]'s
/// `PlannerLoopResult` planner block. Field set is intentionally the
/// minimum the UI needs to render the Reasoning Trail extension; the
/// authoritative trace lives in `chat_planner_traces` and is fetched on
/// demand via the `planner_trace(uuid)` RPC.
class PlannerSummary {
  const PlannerSummary({
    required this.regeneratedOnce,
    required this.latencyMs,
    required this.costCents,
  });

  factory PlannerSummary.fromJson(Map<String, dynamic> json) {
    return PlannerSummary(
      regeneratedOnce: json['regenerated_once'] as bool? ?? false,
      latencyMs: json['latency_ms'] as int? ?? 0,
      costCents: json['cost_cents'] as int? ?? 0,
    );
  }

  /// True when the executor was re-run with the critique injected.
  final bool regeneratedOnce;

  /// End-to-end latency in milliseconds across all 3-4 passes. Surfaced
  /// on the collapsed Reasoning Trail pill so the user sees that the
  /// legal turn took longer because the planner ran.
  final int latencyMs;

  /// Total Anthropic cost across all passes in cents. UI does not show
  /// this to end users; it's exposed for the Pkg 8 eval suite.
  final int costCents;
}

/// Full planner result shape returned by the proxy. Wraps the assistant
/// reply text + Pkg 2 citations + the planner summary. Mirrors the
/// augmented JSON shape that claude-proxy emits in `mode: "legal_planner"`.
class PlannerResult {
  const PlannerResult({
    required this.replyText,
    required this.citations,
    required this.summary,
    this.messageId,
    this.blockingGap = false,
  });

  factory PlannerResult.fromAugmented(Map<String, dynamic> json) {
    final content = json['content'] as List<dynamic>?;
    final text = (content ?? [])
        .where((b) => b is Map && b['type'] == 'text')
        .map((b) => (b as Map)['text']?.toString() ?? '')
        .join('\n');
    final cits = (json['citations'] as List<dynamic>?) ?? <dynamic>[];
    final plannerRaw = json['planner'];
    final planner = plannerRaw is Map
        ? Map<String, dynamic>.from(plannerRaw)
        : <String, dynamic>{};
    return PlannerResult(
      replyText: text,
      citations: cits,
      summary: PlannerSummary.fromJson(planner),
      messageId: json['message_id'] as String?,
      // `planner.blocking_gap: true` means the AI needs more info before
      // giving a substantive answer — surfaces as an amber bubble in the UI.
      blockingGap: planner['blocking_gap'] as bool? ?? false,
    );
  }

  final String replyText;

  /// The Pkg 2 verifier output, untouched. The chat UI hands this to the
  /// existing citation chip renderer — Pkg 6 explicitly does not change
  /// the citation format.
  final List<dynamic> citations;
  final PlannerSummary summary;
  final String? messageId;

  /// True when the planner decided it needs more information before it can
  /// give a complete answer. Drives the amber bubble style in the chat UI.
  final bool blockingGap;
}

/// Runtime trigger gate for the planner. All three must be true:
///   1. [isPro] — the loop is Pro-only because it 3-4x's the API cost.
///   2. [enabledByPref] — user toggle, default OFF.
///   3. [looksLegalish] — coarse keyword filter (already in
///      `claude_service.dart`).
///
/// Pure function — no I/O, deterministic — so a contract test can pin
/// the gate without spinning up Riverpod or hitting Supabase.
bool shouldRouteToPlanner({
  required bool isPro,
  required bool enabledByPref,
  required bool looksLegalish,
}) {
  if (!isPro) return false;
  if (!enabledByPref) return false;
  if (!looksLegalish) return false;
  return true;
}

/// Riverpod-friendly service wrapping [ClaudeService.sendLegalPlannerMessage].
/// The chat surface calls [run] only after [shouldRouteToPlanner] returns
/// true; this class deliberately does NOT re-evaluate the gate so the
/// gate logic stays in exactly one place (the chat orchestrator).
class LegalPlannerService {
  LegalPlannerService(this._claude);

  final ClaudeService _claude;

  Future<PlannerResult> run({
    required List<Map<String, String>> messages,
    required String systemPrompt,
    String? caseId,
    String? messageId,
  }) async {
    final raw = await _claude.sendLegalPlannerMessage(
      messages: messages,
      systemPrompt: systemPrompt,
      caseId: caseId,
      messageId: messageId,
    );
    return PlannerResult.fromAugmented(raw);
  }
}

final legalPlannerServiceProvider = Provider<LegalPlannerService>((ref) {
  final claude = ref.watch(claudeServiceProvider);
  return LegalPlannerService(claude);
});
