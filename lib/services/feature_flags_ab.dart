// feature_flags_ab.dart — A/B-test assignment + event tracking service.
// -----------------------------------------------------------------------------
// Lightweight feature-flag layer for variant tests on Advocat. Two responsibilities:
//
//   1. assignment(): deterministic 50/50 (or arbitrary-weight) bucket pick for
//      a given experiment key. Cached locally so a user stays on the same
//      variant across reloads (sticky bucket).
//
//   2. trackEvent(): records experiment exposure / CTA click / conversion
//      events to Supabase `ab_events` (best-effort, no throw).
//
// Why not the existing config/feature_flags.dart?
//   That file holds compile-time constants (Gmail OAuth scopes). This one
//   holds runtime-resolved variants (currently 50/50 cookie/random) and is
//   safe to call from any screen.
//
// Coordination with the landing page (web/index.html):
//   The landing reads a cookie `advocat_ab_pricing` it sets on first visit.
//   When the user lands in the Flutter app via `/app.html?plan=…&billing=…`
//   the variant has already been chosen by JS; we mirror that here by
//   accepting an externally-supplied variant via fromExternalAssignment().
//
// Server-side persistence:
//   migration `20260514_ab_assignments.sql` introduces
//     ab_assignments(user_id, experiment, variant, created_at)
//     ab_events(user_id, experiment, variant, event, occurred_at, metadata)
//   Both RLS-restricted to own rows.
// -----------------------------------------------------------------------------

import 'dart:math' as math;

/// Known experiment keys. Centralised so we don't typo them across the
/// codebase.
class AbExperiment {
  static const String pricing = 'pricing';

  /// Bentley P8 (2026-05-16) — mid-conversation contract-review upsell
  /// shown at message 7 of the 10-message free tier. Tracks impression
  /// vs CTR vs subsequent upload so we can measure whether nudging the
  /// user mid-flow lifts contract review starts.
  ///
  /// Events used:
  ///   - contract_upsell_shown   : card rendered into the chat stream
  ///   - contract_upsell_click   : user tapped the upload CTA
  ///   - contract_upsell_dismiss : user tapped the dismiss "X"
  ///   - contract_upsell_upload  : a contract upload completed within the
  ///                                same session after a `shown` event
  ///
  /// Currently single-variant ("v1") so we get baseline CTR before we
  /// branch into copy / placement experiments.
  static const String contractUpsell = 'contract_upsell';

  /// All registered experiment keys — used by tests + admin tooling.
  static const Set<String> known = {pricing, contractUpsell};

  /// Returns true if [key] is a registered experiment. Unknown keys are
  /// rejected to prevent silent typos.
  static bool isKnown(String key) => known.contains(key);
}

/// Known variant labels. We keep variants as plain strings (not enums) so we
/// can add new variants without redeploying clients — the server is the
/// source of truth via `ab_assignments` table.
class AbVariant {
  static const String v1 = 'v1'; // control
  static const String v2 = 'v2'; // treatment
}

/// Result of an assignment lookup.
class AbAssignment {
  const AbAssignment({
    required this.experiment,
    required this.variant,
    required this.source,
  });

  final String experiment;
  final String variant;

  /// Where this assignment came from: 'cached' (local), 'external' (cookie /
  /// landing handoff), or 'fresh' (newly minted).
  final String source;

  @override
  String toString() =>
      'AbAssignment(experiment=$experiment, variant=$variant, source=$source)';
}

/// Minimal storage abstraction so tests can inject an in-memory map.
abstract class AbStorage {
  String? read(String key);
  void write(String key, String value);
}

/// In-memory implementation. The real app wires `SharedPreferences` over
/// this surface in a thin adapter; tests use it directly.
class InMemoryAbStorage implements AbStorage {
  final Map<String, String> _store = {};

  @override
  String? read(String key) => _store[key];

  @override
  void write(String key, String value) {
    _store[key] = value;
  }

  /// Test helper.
  Map<String, String> snapshot() => Map<String, String>.unmodifiable(_store);
}

/// Event sink — fire-and-forget. The real implementation pushes to Supabase
/// `ab_events` via the existing REST client; tests collect into a list.
abstract class AbEventSink {
  /// Called when a variant is first exposed to a user. MUST NOT throw.
  void recordExposure(AbAssignment a);

  /// Called for each CTA click or other interaction. [event] is a short
  /// snake_case label. [metadata] is small JSON-shaped data.
  void recordEvent(
    AbAssignment a,
    String event, {
    Map<String, Object?>? metadata,
  });
}

/// Test-friendly in-memory sink.
class InMemoryAbEventSink implements AbEventSink {
  final List<Map<String, Object?>> events = [];

  @override
  void recordExposure(AbAssignment a) {
    events.add({
      'kind': 'exposure',
      'experiment': a.experiment,
      'variant': a.variant,
      'source': a.source,
    });
  }

  @override
  void recordEvent(
    AbAssignment a,
    String event, {
    Map<String, Object?>? metadata,
  }) {
    events.add({
      'kind': 'event',
      'experiment': a.experiment,
      'variant': a.variant,
      'event': event,
      if (metadata != null) 'metadata': metadata,
    });
  }
}

/// Core A/B service.
///
/// Stateless apart from the [storage] handle. Safe to instantiate per-call.
class FeatureFlagsAb {
  FeatureFlagsAb({
    required AbStorage storage,
    AbEventSink? sink,
    math.Random? rng,
  })  : _storage = storage,
        _sink = sink,
        _rng = rng ?? math.Random();

  final AbStorage _storage;
  final AbEventSink? _sink;
  final math.Random _rng;

  static const String _storageKeyPrefix = 'advocat_ab_';

  /// Resolve the variant for [experiment]. Order of precedence:
  ///   1. cached assignment (sticky bucket)
  ///   2. fresh assignment from 50/50 (or supplied weights)
  ///
  /// Use [fromExternalAssignment] first if you have a value handed off from
  /// the landing cookie.
  AbAssignment assignment(
    String experiment, {
    Map<String, double>? weights,
    bool recordExposure = true,
  }) {
    _assertKnown(experiment);

    final cached = _storage.read('$_storageKeyPrefix$experiment');
    if (cached != null && cached.isNotEmpty) {
      final a = AbAssignment(
        experiment: experiment,
        variant: cached,
        source: 'cached',
      );
      if (recordExposure) _sink?.recordExposure(a);
      return a;
    }

    final variant = _pickVariant(weights ?? _defaultWeights());
    _storage.write('$_storageKeyPrefix$experiment', variant);

    final a = AbAssignment(
      experiment: experiment,
      variant: variant,
      source: 'fresh',
    );
    if (recordExposure) _sink?.recordExposure(a);
    return a;
  }

  /// Adopt an assignment computed elsewhere (e.g. read from cookie set by
  /// landing JS). Persists locally so a subsequent [assignment] call returns
  /// the same variant. Records exposure once.
  AbAssignment fromExternalAssignment(String experiment, String variant) {
    _assertKnown(experiment);
    if (variant.isEmpty) {
      throw ArgumentError.value(variant, 'variant', 'must not be empty');
    }
    _storage.write('$_storageKeyPrefix$experiment', variant);
    final a = AbAssignment(
      experiment: experiment,
      variant: variant,
      source: 'external',
    );
    _sink?.recordExposure(a);
    return a;
  }

  /// Record a downstream event for [experiment]'s current variant. Quietly
  /// no-ops if the user has not been assigned yet (we cannot attribute an
  /// event without a variant).
  void trackEvent(
    String experiment,
    String event, {
    Map<String, Object?>? metadata,
  }) {
    _assertKnown(experiment);
    final cached = _storage.read('$_storageKeyPrefix$experiment');
    if (cached == null || cached.isEmpty) return;
    _sink?.recordEvent(
      AbAssignment(
        experiment: experiment,
        variant: cached,
        source: 'cached',
      ),
      event,
      metadata: metadata,
    );
  }

  // ── Internals ───────────────────────────────────────────────────────────

  void _assertKnown(String experiment) {
    if (!AbExperiment.isKnown(experiment)) {
      throw ArgumentError.value(
        experiment,
        'experiment',
        'unknown experiment key — register it in AbExperiment.known',
      );
    }
  }

  /// 50/50 between v1 and v2.
  Map<String, double> _defaultWeights() => const {
        AbVariant.v1: 0.5,
        AbVariant.v2: 0.5,
      };

  /// Weighted random pick. Weights need not sum to 1 — we normalise.
  String _pickVariant(Map<String, double> weights) {
    if (weights.isEmpty) {
      throw ArgumentError('weights must not be empty');
    }
    var total = 0.0;
    for (final w in weights.values) {
      if (w < 0) {
        throw ArgumentError('weights must be non-negative');
      }
      total += w;
    }
    if (total <= 0) {
      throw ArgumentError('weights must sum to > 0');
    }
    final pick = _rng.nextDouble() * total;
    var running = 0.0;
    for (final entry in weights.entries) {
      running += entry.value;
      if (pick <= running) return entry.key;
    }
    // Floating-point safety: fall back to the last entry.
    return weights.keys.last;
  }
}
