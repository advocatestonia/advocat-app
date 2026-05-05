// =============================================================================
// reasoning_trail.dart — visible-thinking pill above the streaming answer.
// =============================================================================
//
// Reasoning Trail v1 (2026-05-05). Replaces the legacy "AI is analyzing…" dot
// indicator. Surfaces what the model is actually doing — searching law,
// reading documents, reasoning — so the user isn't staring at static dots
// while a 6-second extended-thinking turn runs.
//
// Visual contract (per owner spec):
//   • 32px pill, accent border, surface bg.
//   • 12px pulsing accent dot + rotating one-line caption.
//   • Caption changes on ThinkingDelta / ToolUseStart / ToolResult; throttled
//     to once per 2.5s so a single block running long doesn't strobe.
//   • On first TextDelta: 400ms delay → AnimatedSize collapse to one-line
//     summary "Reasoned for 7s · 2 sources · tap to expand".
//   • Tap collapsed → expand to a vertical step list with checkmarks.
//   • Persists user's expand preference across sessions in SharedPreferences:
//     if user expanded twice in last 10 turns, defaults to expanded.
//
// Lifecycle: stateful widget consumes a Stream<ChatStreamEvent>. The chat
// screen creates one ReasoningTrail per turn and disposes it when the message
// arrives. No global state beyond the SharedPreferences pref.
// =============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/chat_stream_event.dart';
import 'reasoning_caption_mapper.dart';

/// Min interval between caption rotations. A long-running tool call
/// (e.g. an 8s law search) shouldn't strobe the pill.
const Duration _kCaptionThrottle = Duration(milliseconds: 2500);

/// Time after first TextDelta before the pill collapses to "Reasoned for…".
/// Owner spec: 400ms — long enough that the user sees the final stage flash,
/// short enough that the answer doesn't feel delayed.
const Duration _kCollapseDelay = Duration(milliseconds: 400);

/// localStorage key tracking how many times the user expanded the trail in
/// the last [_kExpandWindow] turns. If >= [_kAutoExpandThreshold], the next
/// trail starts pre-expanded.
const String _kExpandPrefKey = 'advocat_reasoning_expanded';
const int _kAutoExpandThreshold = 2;

/// One step rendered in the expanded list. Captures the caption text +
/// elapsed time + tool/thinking type for the checkmark icon choice.
class _Step {
  _Step({
    required this.caption,
    required this.kind,
    required this.startedAt,
  });

  final String caption;
  final _StepKind kind;
  final DateTime startedAt;
  bool completed = false;
}

enum _StepKind { thinking, tool, finalising }

/// Visible-reasoning pill above the streaming assistant message.
///
/// Construction: pass the [events] stream that this turn's
/// `sendChatMessageStreamingEvents` returns. The widget subscribes,
/// updates its caption, and collapses 400ms after the first text arrives.
class ReasoningTrail extends StatefulWidget {
  const ReasoningTrail({
    super.key,
    required this.events,
    this.onClose,
  });

  /// Stream of events for the current turn. The widget subscribes once and
  /// rebuilds itself; do not pass a broadcast stream that's already been
  /// listened to.
  final Stream<ChatStreamEvent> events;

  /// Optional callback fired when MessageDone arrives. The chat screen can
  /// use this to remove the trail widget entirely once the answer is fully
  /// rendered.
  final VoidCallback? onClose;

  @override
  State<ReasoningTrail> createState() => _ReasoningTrailState();
}

class _ReasoningTrailState extends State<ReasoningTrail>
    with SingleTickerProviderStateMixin {
  StreamSubscription<ChatStreamEvent>? _sub;
  String? _caption;
  bool _throttleArmed = true; // false while inside the 2.5s lock-out
  Timer? _throttleTimer;
  DateTime? _startedAt;
  Timer? _collapseTimer;
  late final AnimationController _pulse;

  // Past stages for the expanded view.
  final List<_Step> _steps = [];
  _Step? _activeStep;

  // Aggregate stats for the collapsed summary.
  int _toolCount = 0;
  int? _thinkingMs;

  // Animation states.
  bool _collapsed = false;
  bool _expanded = false; // user-driven expand on collapsed pill

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _restoreExpandPreference();
    _sub = widget.events.listen(_onEvent, onError: (_) {
      // Errors handled upstream (chat_screen) — pill just closes silently.
      widget.onClose?.call();
    });
  }

  Future<void> _restoreExpandPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expandedCount = prefs.getInt(_kExpandPrefKey) ?? 0;
      if (expandedCount >= _kAutoExpandThreshold && mounted) {
        setState(() => _expanded = true);
      }
    } catch (_) {
      // Best-effort. SharedPreferences can fail on web during early init —
      // default to collapsed.
    }
  }

  Future<void> _bumpExpandPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cur = prefs.getInt(_kExpandPrefKey) ?? 0;
      // Cap at threshold + small headroom so the counter doesn't grow forever.
      await prefs.setInt(_kExpandPrefKey, (cur + 1).clamp(0, _kAutoExpandThreshold + 5));
    } catch (_) {
      // Ignore — preference is non-critical.
    }
  }

  void _onEvent(ChatStreamEvent event) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    // Track tool count for the collapsed summary.
    if (event is ToolUseStart) {
      _toolCount += 1;
    }

    // First TextDelta → schedule collapse 400ms later.
    if (event is TextDelta && _collapseTimer == null && !_collapsed) {
      _collapseTimer = Timer(_kCollapseDelay, () {
        if (!mounted) return;
        setState(() {
          _activeStep?.completed = true;
          _collapsed = true;
          _thinkingMs = DateTime.now().difference(_startedAt!).inMilliseconds;
        });
      });
    }

    // Terminal event → close (or chat_screen may already have us removed).
    if (event is MessageDone) {
      _collapseTimer?.cancel();
      if (!_collapsed) {
        setState(() {
          _activeStep?.completed = true;
          _collapsed = true;
          _thinkingMs = DateTime.now().difference(_startedAt!).inMilliseconds;
        });
      }
      widget.onClose?.call();
      return;
    }

    // Caption update — throttle to ≥ _kCaptionThrottle apart.
    // Throttle is implemented via a Timer (fake-clock friendly) rather than
    // wall-clock DateTime diffs so widget tests can drive `tester.pump(2600ms)`
    // to verify behaviour without sleeping.
    final candidate = captionForEvent(
      event,
      l10n,
      toolName: event is ToolUseStart ? event.name : null,
    );
    if (candidate == null) return;
    if (!_throttleArmed) return;

    setState(() {
      // Mark previous step done before pushing new one.
      _activeStep?.completed = true;
      _activeStep = _Step(
        caption: candidate,
        kind: switch (event) {
          ToolUseStart() => _StepKind.tool,
          ToolResultReceived() => _StepKind.finalising,
          MessageDone() => _StepKind.finalising,
          _ => _StepKind.thinking,
        },
        startedAt: DateTime.now(),
      );
      _steps.add(_activeStep!);
      _caption = candidate;
    });

    _throttleArmed = false;
    _throttleTimer?.cancel();
    _throttleTimer = Timer(_kCaptionThrottle, () {
      if (!mounted) return;
      _throttleArmed = true;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _collapseTimer?.cancel();
    _throttleTimer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final caption = _caption ?? (l10n?.reasoningPillIdle ?? 'Thinking…');

    // Note: we deliberately avoid wrapping in `.animate().fadeIn()` here
    // because flutter_animate's controller leaves a pending timer at widget
    // disposal which fails widget-test invariants. AnimatedSize handles
    // the height transition; the entry fade is left to the parent ListView
    // (which does its own AnimatedSwitcher in chat_screen).
    return AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topLeft,
      child: _collapsed ? _buildCollapsed(l10n, caption) : _buildExpanded(caption),
    );
  }

  Widget _buildExpanded(String caption) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm, right: 80),
        constraints: const BoxConstraints(minHeight: 32),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.4), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 12px pulsing accent dot — controller-driven so widget tests
            // can dispose it cleanly (flutter_animate's .repeat() leaves a
            // pending timer that breaks the FakeAsync test guard).
            FadeTransition(
              opacity: Tween<double>(begin: 0.45, end: 1.0).animate(
                CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
              ),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.85, end: 1.0).animate(
                  CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
                ),
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: Text(
                  caption,
                  key: ValueKey(caption),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsed(AppLocalizations? l10n, String _) {
    final secs = ((_thinkingMs ?? 0) / 1000).round();
    final summary = l10n?.reasoningCollapsedFormat(secs, _toolCount) ??
        'Reasoned for ${secs}s · $_toolCount sources';
    final hint = l10n?.reasoningExpandHint ?? 'tap to see steps';

    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() => _expanded = !_expanded);
          if (_expanded) {
            _bumpExpandPreference();
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm, right: 80),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 14,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '$summary · $hint',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 14,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 8),
                ..._steps.map(_buildStepRow),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepRow(_Step step) {
    final icon = step.completed
        ? Icons.check_circle
        : (step.kind == _StepKind.tool
            ? Icons.search_rounded
            : Icons.psychology_outlined);
    final color = step.completed ? AppColors.success : AppColors.accent;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              step.caption,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
