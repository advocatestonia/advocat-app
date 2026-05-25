// =============================================================================
// consilium_panel.dart — multi-role legal-consilium UI for the chat stream.
// =============================================================================
//
// Phase 1 Consilium (2026-05-25).
//
// Renders the live state of the role-orchestrator pipeline above the regular
// assistant text bubble:
//
//   ┌───────────────────────────────────────────────┐
//   │ Консилиум юристов            3 / 5 готово    │ ← header + progress
//   ├───────────────────────────────────────────────┤
//   │ ⚠ Эксперты расходятся                    [v] │ ← if disagreement
//   ├───────────────────────────────────────────────┤
//   │ [RoleOpinionCard × N]                         │
//   │ ▸ Адверсариальный раунд (collapsed)           │ ← if any attack frames
//   │ Синтезирую рекомендацию…                      │ ← when synthesis fires
//   ├───────────────────────────────────────────────┤
//   │ Консилиум 5 юристов · 2 раунда · готово       │ ← footer when done
//   └───────────────────────────────────────────────┘
//
// The synthesis text itself is NOT rendered here — that streams into the
// regular text bubble below. We avoid duplicating message_bubble logic.
//
// Event coupling:
//   The widget takes `List<ChatStreamEvent>`. To stay compatible with the
//   parallel SSE-parser agent that is wiring up the new typed events
//   (ConsiliumStart / RoleOpinion / AdversarialAttack / RoundDone /
//   ConsiliumSynthesisStart / ConsiliumDone), we read events via a runtime
//   type-name dispatch instead of compile-time class references. That keeps
//   this file building even before the parser agent's PR lands; once the
//   names match, all snapshots fill in automatically.
//
//   The snapshot also accepts pre-parsed events via the test-only
//   [ConsiliumSnapshot.fromMaps] constructor so widget tests don't depend
//   on the not-yet-merged classes.
// =============================================================================

import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../services/chat_stream_event.dart';
import 'disagreement_banner.dart';
import 'role_opinion_card.dart';

// ---------------------------------------------------------------------------
// Snapshot — derived view of the consilium state for a given event list.
// ---------------------------------------------------------------------------

/// One role's opinion as captured during streaming. Mutable inside the
/// snapshot builder; immutable to the renderer.
class ConsiliumRoleView {
  ConsiliumRoleView({required this.name});

  final String name;
  String? position;
  double? confidence;
  String? opinion;
  String? citation;
  bool get hasOpinion => position != null || opinion != null;
}

/// Read-only snapshot consumed by [ConsiliumPanel].
class ConsiliumSnapshot {
  ConsiliumSnapshot({
    required this.started,
    required this.totalRoles,
    required this.roles,
    required this.adversarialAttacks,
    required this.roundsCompleted,
    required this.synthesisStarted,
    required this.done,
  });

  final bool started;
  final int totalRoles;
  final List<ConsiliumRoleView> roles;
  final int adversarialAttacks;
  final int roundsCompleted;
  final bool synthesisStarted;
  final bool done;

  int get readyCount => roles.where((r) => r.hasOpinion).length;

  /// Build from raw [ChatStreamEvent] objects via runtime type-name dispatch.
  ///
  /// We support the event-class names the parser agent is adding:
  ///   * ConsiliumStart        — payload: roster (List<String> roleNames)
  ///   * RoleOpinion           — payload: role, position, confidence, opinion, citation
  ///   * AdversarialAttack     — payload: optional summary
  ///   * RoundDone             — payload: round_index
  ///   * ConsiliumSynthesisStart — no payload
  ///   * ConsiliumDone         — no payload
  ///
  /// Reading via `runtimeType.toString()` lets this file compile before
  /// the parser agent's PR merges. Once those classes exist, payload
  /// extraction goes through [_readField] which inspects public getters
  /// via dynamic invocation; missing fields fall back to null.
  factory ConsiliumSnapshot.fromEvents(List<ChatStreamEvent> events) {
    final maps = <Map<String, Object?>>[];
    for (final ev in events) {
      final typeName = ev.runtimeType.toString();
      switch (typeName) {
        case 'ConsiliumStart':
          maps.add({
            'kind': 'start',
            'roster': _readField<List<dynamic>>(ev, 'roster') ?? const [],
          });
        case 'RoleOpinion':
          maps.add({
            'kind': 'opinion',
            'role': _readField<String>(ev, 'role') ?? '',
            'position': _readField<String>(ev, 'position'),
            'confidence': _readNum(ev, 'confidence'),
            'opinion': _readField<String>(ev, 'opinion'),
            'citation': _readField<String>(ev, 'citation'),
          });
        case 'AdversarialAttack':
          maps.add({'kind': 'attack'});
        case 'RoundDone':
          maps.add({'kind': 'round_done'});
        case 'ConsiliumSynthesisStart':
          maps.add({'kind': 'synthesis_start'});
        case 'ConsiliumDone':
          maps.add({'kind': 'done'});
      }
    }
    return ConsiliumSnapshot.fromMaps(maps);
  }

  /// Test-only / forward-compatible constructor. Accepts an already-parsed
  /// list of maps each with a `kind` discriminator.
  factory ConsiliumSnapshot.fromMaps(List<Map<String, Object?>> entries) {
    var started = false;
    var totalRoles = 0;
    final roles = <String, ConsiliumRoleView>{};
    final rosterOrder = <String>[];
    var attacks = 0;
    var rounds = 0;
    var synth = false;
    var done = false;

    for (final m in entries) {
      switch (m['kind']) {
        case 'start':
          started = true;
          final roster = (m['roster'] as List?) ?? const [];
          for (final raw in roster) {
            final name = raw?.toString() ?? '';
            if (name.isEmpty) continue;
            if (!roles.containsKey(name)) {
              roles[name] = ConsiliumRoleView(name: name);
              rosterOrder.add(name);
            }
          }
          totalRoles = roles.length;
        case 'opinion':
          final name = (m['role'] as String?) ?? '';
          if (name.isEmpty) break;
          final view = roles.putIfAbsent(name, () {
            rosterOrder.add(name);
            return ConsiliumRoleView(name: name);
          });
          view.position = m['position'] as String?;
          final conf = m['confidence'];
          if (conf is num) view.confidence = conf.toDouble();
          view.opinion = m['opinion'] as String?;
          view.citation = m['citation'] as String?;
          if (totalRoles < roles.length) totalRoles = roles.length;
        case 'attack':
          attacks++;
        case 'round_done':
          rounds++;
        case 'synthesis_start':
          synth = true;
        case 'done':
          done = true;
      }
    }

    return ConsiliumSnapshot(
      started: started,
      totalRoles: totalRoles,
      roles: rosterOrder.map((n) => roles[n]!).toList(growable: false),
      adversarialAttacks: attacks,
      roundsCompleted: rounds,
      synthesisStarted: synth,
      done: done,
    );
  }
}

T? _readField<T>(Object obj, String name) {
  try {
    // ignore: avoid_dynamic_calls
    final dyn = (obj as dynamic);
    final value = switch (name) {
      'roster' => dyn.roster,
      'role' => dyn.role,
      'position' => dyn.position,
      'confidence' => dyn.confidence,
      'opinion' => dyn.opinion,
      'citation' => dyn.citation,
      _ => null,
    };
    return value is T ? value : null;
  } catch (_) {
    return null;
  }
}

num? _readNum(Object obj, String name) {
  final v = _readField<Object>(obj, name);
  if (v is num) return v;
  if (v is String) return num.tryParse(v);
  return null;
}

// ---------------------------------------------------------------------------
// Panel widget
// ---------------------------------------------------------------------------

class ConsiliumPanel extends StatelessWidget {
  const ConsiliumPanel({
    super.key,
    required this.events,
    this.headerLabel = 'Консилиум юристов',
    this.synthesisLabel = 'Синтезирую рекомендацию…',
    this.disagreementLabel = '⚠ Эксперты расходятся',
  }) : _testSnapshot = null;

  /// Test-only constructor: bypass event parsing by passing a pre-built
  /// [ConsiliumSnapshot]. Used by widget tests (since [ChatStreamEvent] is
  /// `sealed` and can't be mocked from outside its library).
  @visibleForTesting
  const ConsiliumPanel.fromSnapshot({
    super.key,
    required ConsiliumSnapshot snapshot,
    this.headerLabel = 'Консилиум юристов',
    this.synthesisLabel = 'Синтезирую рекомендацию…',
    this.disagreementLabel = '⚠ Эксперты расходятся',
  })  : events = const [],
        _testSnapshot = snapshot;

  /// All ChatStreamEvent objects collected for this assistant message.
  /// The widget filters down to consilium-related ones internally.
  final List<ChatStreamEvent> events;

  // l10n labels — passed by parent so the i18n agent can wire ARB lookups.
  final String headerLabel;
  final String synthesisLabel;
  final String disagreementLabel;

  final ConsiliumSnapshot? _testSnapshot;

  @override
  Widget build(BuildContext context) {
    final snap = _testSnapshot ?? ConsiliumSnapshot.fromEvents(events);
    if (!snap.started) {
      return const SizedBox.shrink(key: Key('consilium_panel_empty'));
    }

    // Disagreement detection — only meaningful once 2+ opinions are in.
    final readyOpinions = snap.roles
        .where((r) =>
            r.position != null &&
            r.confidence != null &&
            (r.position!.isNotEmpty))
        .map((r) => (
              role: r.name,
              position: r.position!,
              confidence: r.confidence!,
            ))
        .toList(growable: false);
    final disagreements = detectDisagreements(readyOpinions);

    return Container(
      key: const Key('consilium_panel'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: AppColors.infoBg.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.info.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.balance_rounded,
                  size: 16, color: AppColors.info),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  headerLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${snap.readyCount} / ${snap.totalRoles} готово',
                key: const Key('consilium_progress'),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Disagreement banner
          if (disagreements.isNotEmpty)
            DisagreementBanner(
              entries: disagreements,
              title: disagreementLabel,
            ),

          // Role cards (one per roster entry; loading skeleton until opinion lands)
          ...snap.roles.map(
            (r) => RoleOpinionCard(
              key: ValueKey('role_${r.name}'),
              roleName: r.name,
              position: parseRolePosition(r.position),
              confidence: r.confidence,
              opinion: r.opinion,
              citation: r.citation,
              isLoading: !r.hasOpinion,
            ),
          ),

          // Adversarial round
          if (snap.adversarialAttacks > 0)
            _AdversarialSection(
              attackCount: snap.adversarialAttacks,
              roundsCompleted: snap.roundsCompleted,
            ),

          // Synthesis indicator
          if (snap.synthesisStarted && !snap.done) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              key: const Key('consilium_synthesis'),
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.accent),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  synthesisLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],

          // Done footer
          if (snap.done) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Консилиум ${snap.totalRoles} юристов · '
              '${snap.roundsCompleted} ${snap.roundsCompleted == 1 ? "раунд" : "раунда"} · готово',
              key: const Key('consilium_done_footer'),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AdversarialSection extends StatefulWidget {
  const _AdversarialSection({
    required this.attackCount,
    required this.roundsCompleted,
  });

  final int attackCount;
  final int roundsCompleted;

  @override
  State<_AdversarialSection> createState() => _AdversarialSectionState();
}

class _AdversarialSectionState extends State<_AdversarialSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: 6),
            child: Row(
              key: const Key('consilium_adversarial_toggle'),
              children: [
                Icon(
                  _expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _expanded
                        ? 'Адверсариальный раунд · ${widget.attackCount} возражений'
                        : 'Адверсариальный раунд (${widget.attackCount})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
