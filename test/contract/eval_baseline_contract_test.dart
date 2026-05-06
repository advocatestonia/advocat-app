// Contract test: workspace-level eval baseline.json must remain parsable.
//
// This test does NOT run the eval suite (that's a Deno script in
// /Users/ai.place/Advocat/scripts/eval/run-eval.ts). It just checks that
// the JSON contract between the eval harness and any consumer (CI, future
// dashboards) hasn't drifted.
//
// Tagged 'fast' so it runs in the contract test gate per Rule 10
// (anti-regression rules — every regression starts with a RED test).

@Tags(['fast'])
library;

import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('eval baseline.json shape', () {
    // Workspace layout: app/advocat_project/test/contract/this.dart
    // baseline lives at: <workspace_root>/data/eval/baseline.json
    // From cwd (app/advocat_project) → ../../data/eval/baseline.json
    final f = File('../../data/eval/baseline.json');
    if (!f.existsSync()) {
      markTestSkipped(
        'baseline not yet established (data/eval/baseline.json missing) — '
        'run `deno run -A scripts/eval/run-eval.ts --full` and promote',
      );
      return;
    }

    final json = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;

    // Required keys — adding/removing requires a migration plus a new commit
    expect(json['judge_version'], isNotNull, reason: 'judge_version pins prompt revision');
    expect(json['judge_version'], isA<String>());
    expect(json['n_cases'], isA<int>());
    expect(json['score_total'], isA<num>());
    expect(json['score_max'], isA<num>());
    expect(json['score_pct'], isA<num>());
    expect(json['per_case'], isA<Map>());

    // promoted_* may be null on first scaffold but keys must exist
    expect(json.containsKey('promoted_at'), isTrue);
    expect(json.containsKey('promoted_by'), isTrue);
    expect(json.containsKey('git_sha'), isTrue);

    // Sanity: if promoted, score_pct must be consistent with totals
    final promoted = json['promoted_at'] != null;
    if (promoted) {
      final total = (json['score_total'] as num).toDouble();
      final max = (json['score_max'] as num).toDouble();
      if (max > 0) {
        final expectedPct = total / max;
        final actualPct = (json['score_pct'] as num).toDouble();
        expect(
          (actualPct - expectedPct).abs(),
          lessThan(0.001),
          reason: 'score_pct must match score_total/score_max',
        );
      }
    }
  });
}
