// feature_flags_ab_test.dart — unit tests for FeatureFlagsAb service.
// -----------------------------------------------------------------------------
// Coverage:
//   - assignment() stickiness (cached bucket reused)
//   - assignment() fresh pick on first call
//   - fromExternalAssignment() persistence + exposure
//   - trackEvent() no-op when no assignment
//   - trackEvent() records when assignment exists
//   - 50/50 weights produce balanced distribution at scale
//   - unknown experiments are rejected
//   - weighted picker honours bias
// -----------------------------------------------------------------------------

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/feature_flags_ab.dart';

void main() {
  group('FeatureFlagsAb.assignment()', () {
    test('returns cached variant on second call (sticky)', () {
      final storage = InMemoryAbStorage();
      final sink = InMemoryAbEventSink();
      // Force RNG to pick v1 every time.
      final svc = FeatureFlagsAb(
        storage: storage,
        sink: sink,
        rng: _FixedRandom(0.0),
      );

      final first = svc.assignment(AbExperiment.pricing);
      expect(first.variant, AbVariant.v1);
      expect(first.source, 'fresh');

      // Even with a different RNG result, sticky bucket wins.
      final svc2 = FeatureFlagsAb(
        storage: storage,
        sink: sink,
        rng: _FixedRandom(0.99),
      );
      final second = svc2.assignment(AbExperiment.pricing);
      expect(second.variant, AbVariant.v1);
      expect(second.source, 'cached');
    });

    test('records exposure once per call', () {
      final storage = InMemoryAbStorage();
      final sink = InMemoryAbEventSink();
      final svc = FeatureFlagsAb(
        storage: storage,
        sink: sink,
        rng: _FixedRandom(0.0),
      );

      svc.assignment(AbExperiment.pricing);
      svc.assignment(AbExperiment.pricing);

      expect(
        sink.events.where((e) => e['kind'] == 'exposure').length,
        2,
        reason: 'each call to assignment() should record exposure',
      );
    });

    test('recordExposure=false suppresses sink call', () {
      final storage = InMemoryAbStorage();
      final sink = InMemoryAbEventSink();
      final svc = FeatureFlagsAb(
        storage: storage,
        sink: sink,
        rng: _FixedRandom(0.0),
      );

      svc.assignment(AbExperiment.pricing, recordExposure: false);
      expect(sink.events, isEmpty);
    });

    test('throws on unknown experiment', () {
      final svc = FeatureFlagsAb(storage: InMemoryAbStorage());
      expect(
        () => svc.assignment('not_registered'),
        throwsArgumentError,
      );
    });

    test('50/50 weights yield ~balanced distribution over 10k trials', () {
      var v1Count = 0;
      var v2Count = 0;
      final rng = math.Random(42); // deterministic seed
      for (var i = 0; i < 10000; i++) {
        // Fresh storage each iteration so each user is "new".
        final svc = FeatureFlagsAb(
          storage: InMemoryAbStorage(),
          rng: rng,
        );
        final a = svc.assignment(AbExperiment.pricing);
        if (a.variant == AbVariant.v1) v1Count++;
        if (a.variant == AbVariant.v2) v2Count++;
      }
      // Allow ±3% drift — well within chi-square noise for n=10k.
      expect(v1Count, inInclusiveRange(4700, 5300));
      expect(v2Count, inInclusiveRange(4700, 5300));
      expect(v1Count + v2Count, 10000);
    });

    test('weighted picker honours bias', () {
      var v1 = 0;
      var v2 = 0;
      final rng = math.Random(7);
      for (var i = 0; i < 4000; i++) {
        final svc = FeatureFlagsAb(
          storage: InMemoryAbStorage(),
          rng: rng,
        );
        final a = svc.assignment(
          AbExperiment.pricing,
          weights: const {AbVariant.v1: 0.2, AbVariant.v2: 0.8},
        );
        if (a.variant == AbVariant.v1) v1++;
        if (a.variant == AbVariant.v2) v2++;
      }
      // ~20/80 split.
      expect(v1 / 4000, closeTo(0.20, 0.03));
      expect(v2 / 4000, closeTo(0.80, 0.03));
    });
  });

  group('FeatureFlagsAb.fromExternalAssignment()', () {
    test('persists variant and reports source="external"', () {
      final storage = InMemoryAbStorage();
      final sink = InMemoryAbEventSink();
      final svc = FeatureFlagsAb(storage: storage, sink: sink);

      final a = svc.fromExternalAssignment(AbExperiment.pricing, AbVariant.v2);
      expect(a.variant, AbVariant.v2);
      expect(a.source, 'external');
      expect(storage.snapshot()['advocat_ab_pricing'], AbVariant.v2);
      expect(sink.events, hasLength(1));
      expect(sink.events.first['kind'], 'exposure');
    });

    test('subsequent assignment() reads the external bucket as cached', () {
      final storage = InMemoryAbStorage();
      final sink = InMemoryAbEventSink();
      final svc = FeatureFlagsAb(storage: storage, sink: sink);

      svc.fromExternalAssignment(AbExperiment.pricing, AbVariant.v2);
      final a = svc.assignment(AbExperiment.pricing);
      expect(a.variant, AbVariant.v2);
      expect(a.source, 'cached');
    });

    test('rejects empty variant', () {
      final svc = FeatureFlagsAb(storage: InMemoryAbStorage());
      expect(
        () => svc.fromExternalAssignment(AbExperiment.pricing, ''),
        throwsArgumentError,
      );
    });
  });

  group('FeatureFlagsAb.trackEvent()', () {
    test('no-ops when no assignment exists', () {
      final sink = InMemoryAbEventSink();
      final svc = FeatureFlagsAb(
        storage: InMemoryAbStorage(),
        sink: sink,
      );
      svc.trackEvent(AbExperiment.pricing, 'cta_click');
      expect(sink.events, isEmpty);
    });

    test('records event with variant from cached assignment', () {
      final storage = InMemoryAbStorage();
      final sink = InMemoryAbEventSink();
      final svc = FeatureFlagsAb(
        storage: storage,
        sink: sink,
        rng: _FixedRandom(0.0),
      );

      svc.assignment(AbExperiment.pricing);
      sink.events.clear();

      svc.trackEvent(
        AbExperiment.pricing,
        'cta_click',
        metadata: const {'plan': 'pro'},
      );
      expect(sink.events, hasLength(1));
      expect(sink.events.first['kind'], 'event');
      expect(sink.events.first['event'], 'cta_click');
      expect(sink.events.first['variant'], AbVariant.v1);
      expect(sink.events.first['metadata'], const {'plan': 'pro'});
    });
  });

  group('AbExperiment.isKnown()', () {
    test('accepts registered keys', () {
      expect(AbExperiment.isKnown(AbExperiment.pricing), isTrue);
    });
    test('rejects typos', () {
      expect(AbExperiment.isKnown('priCing'), isFalse);
      expect(AbExperiment.isKnown(''), isFalse);
    });
  });
}

/// math.Random subclass that always returns the same double.
class _FixedRandom implements math.Random {
  _FixedRandom(this.value);

  final double value;

  @override
  bool nextBool() => value < 0.5;

  @override
  double nextDouble() => value;

  @override
  int nextInt(int max) {
    if (max <= 0) {
      throw RangeError.range(max, 1, null, 'max', 'must be > 0');
    }
    return (value * max).floor();
  }
}
