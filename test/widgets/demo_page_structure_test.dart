@Tags(['fast'])
library;

// Layer 1 of the "first 60 seconds wow" experience: the public live demo
// page at /demo.html. This test is the contract: the static page must
// expose the elements that drive the user's emotional response within
// 30-60 seconds of landing on advocat.ee.
//
// The demo runs ENTIRELY client-side -- no signup, no edge function call,
// no Anthropic charge. It plays an animation that mirrors the real
// "planner -> red-team -> subtraction" pipeline, then reveals a
// pre-cached PDF (web/og/sample-review.pdf) that was produced by the
// real pipeline.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const demoPath = 'web/demo.html';
  const samplePdfPath = 'web/og/sample-review.pdf';

  late String demoHtml;

  setUpAll(() {
    final demoFile = File(demoPath);
    expect(
      demoFile.existsSync(),
      isTrue,
      reason: 'Public demo page missing at $demoPath',
    );
    demoHtml = demoFile.readAsStringSync();
  });

  group('Layer 1 -- public demo page structure', () {
    test('pre-cached sample PDF is shipped with the build', () {
      final pdf = File(samplePdfPath);
      expect(
        pdf.existsSync(),
        isTrue,
        reason: 'Sample PDF must be checked in at $samplePdfPath',
      );
      expect(
        pdf.lengthSync(),
        greaterThan(50 * 1024),
        reason: 'Sample PDF looks truncated (${pdf.lengthSync()} bytes).',
      );
    });

    test('declares html5 + viewport', () {
      expect(demoHtml.toLowerCase(), contains('<!doctype html>'));
      expect(demoHtml, contains('name="viewport"'));
    });

    test('exposes the canonical demo stage container', () {
      expect(
        demoHtml,
        contains('id="demo-stage"'),
        reason: 'JS targets #demo-stage to drive the animation.',
      );
    });

    test('declares three pipeline stages (planner, red-team, subtraction)',
        () {
      expect(demoHtml, contains('data-demo-stage="planner"'));
      expect(demoHtml, contains('data-demo-stage="red-team"'));
      expect(demoHtml, contains('data-demo-stage="subtraction"'));
    });

    test('reveals the pre-cached PDF after the animation', () {
      expect(
        demoHtml,
        contains('/og/sample-review.pdf'),
        reason: 'Demo must link to the shipped sample PDF.',
      );
    });

    test('promises no signup is required', () {
      final lower = demoHtml.toLowerCase();
      expect(
        lower.contains('no signup') ||
            lower.contains('no sign-up') ||
            lower.contains('without signup') ||
            lower.contains('without sign-up'),
        isTrue,
        reason: 'Demo must clearly state no signup is required.',
      );
    });

    test('shows the post-demo CTA wall pointing at /app.html', () {
      expect(demoHtml, contains('id="demo-cta-wall"'));
      expect(demoHtml, contains('/app.html'));
    });

    test('carries a rate-limit / abuse notice', () {
      final lower = demoHtml.toLowerCase();
      expect(
        lower.contains('rate') || lower.contains('throttl'),
        isTrue,
        reason: 'Demo page must mention rate limiting / throttling.',
      );
    });

    test('analytics CustomEvents are wired for later instrumentation', () {
      expect(demoHtml, contains('advocat:demo-viewed'));
      expect(demoHtml, contains('advocat:demo-completed'));
      expect(demoHtml, contains('advocat:demo-signup-clicked'));
    });

    test('does not eagerly load third-party trackers', () {
      expect(
        demoHtml.contains('googletagmanager.com/gtag/js') ||
            demoHtml.contains('hotjar') ||
            demoHtml.contains('mixpanel'),
        isFalse,
        reason: 'Layer 1 must not eagerly load third-party trackers.',
      );
    });
  });
}
