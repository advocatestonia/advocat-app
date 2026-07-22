@Tags(['fast'])
library;

// =============================================================================
// drift_check_gate_test.dart — contract for the drift-detection gate.
// =============================================================================
//
// 2026-07-16 — pins the git ↔ prod ↔ client drift gate:
//
//   * scripts/drift-check.sh          — the four-list drift script
//   * .github/workflows/drift-check.yml — nightly cron + manual dispatch
//
// This is the control that would have caught the June-2026 outage (16 edge
// functions committed but 404 in prod), the zombie functions, and the
// phantom endpoints. The test verifies:
//
//   1. the script exists, is executable, and parses (`bash -n`);
//   2. offline mode (no network, no creds) self-calibrates: it discovers the
//      real function dirs and real client invocations — no hardcoded counts;
//   3. load-bearing behavior is pinned by string contract (project ref,
//      schema_migrations query, _-dir exclusion, drift exit code);
//   4. the CI workflow wires the script to secrets.SUPABASE_ACCESS_TOKEN on a
//      nightly cron with workflow_dispatch.
//
// No network calls are made: prod comparison paths are exercised only via
// the string contract, offline mode is exercised for real.
// =============================================================================

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _script = 'scripts/drift-check.sh';
const _workflow = '.github/workflows/drift-check.yml';

String _read(String path) {
  final f = File(path);
  if (!f.existsSync()) {
    throw StateError(
      '$path not found. flutter test must run from the package root.',
    );
  }
  return f.readAsStringSync();
}

void main() {
  group('drift-check.sh — file contract', () {
    late String sh;
    setUpAll(() => sh = _read(_script));

    test('script exists and is executable', () {
      final stat = File(_script).statSync();
      // Owner-execute bit (POSIX). On CI checkout the mode is preserved.
      expect(stat.mode & 0x40, isNot(0),
          reason: '$_script must be chmod +x so CI can run it directly');
    });

    test('script parses under bash -n', () async {
      final res = await Process.run('bash', ['-n', _script]);
      expect(res.exitCode, 0, reason: 'bash -n failed: ${res.stderr}');
    });

    test('pins prod project ref as overridable default', () {
      expect(sh, contains(r'PROJECT_REF="${PROJECT_REF:-okgnkucgwsytsondrjye}"'));
    });

    test('LIST A excludes _shared/_tests (all _* dirs)', () {
      expect(sh, contains("! -name '_*'"));
    });

    test('LIST B has Management API fallback (read-only endpoint)', () {
      expect(sh, contains('api.supabase.com/v1/projects/\$PROJECT_REF/functions'));
      expect(sh, contains('supabase functions list --project-ref'));
    });

    test('LIST C covers invoke wrappers and fetch-style URLs', () {
      expect(sh, contains('callEdgeFunction'));
      expect(sh, contains('functions/v1/'));
    });

    test('migration ghosts compare against schema_migrations', () {
      expect(
        sh,
        contains('select version from supabase_migrations.schema_migrations'),
      );
    });

    test('drift exits non-zero, clean exits zero', () {
      expect(sh, contains('RESULT: DRIFT DETECTED'));
      expect(sh, contains('exit 1'));
      expect(sh, contains('exit 0'));
    });

    test('script is read-only against prod (no mutating verbs in SQL)', () {
      final lower = sh.toLowerCase();
      for (final verb in ['insert into', 'update ', 'delete from', 'drop ']) {
        expect(lower.contains('"query":"$verb'), isFalse,
            reason: 'drift-check must never mutate prod ($verb found)');
      }
      expect(sh, isNot(contains('supabase functions deploy')));
      expect(sh, isNot(contains('db push')));
    });
  });

  group('drift-check.sh — offline self-calibration (real run, no network)', () {
    late ProcessResult res;
    setUpAll(() async {
      res = await Process.run('bash', [_script, '--offline']);
    });

    test('offline mode exits 0', () {
      expect(res.exitCode, 0,
          reason: 'stdout: ${res.stdout}\nstderr: ${res.stderr}');
    });

    test('discovers git function dirs (LIST A) without hardcoded counts', () {
      final out = res.stdout as String;
      expect(out, contains('LIST A'));
      // Two functions that have existed since the MVP — if these vanish from
      // the listing the discovery glob is broken, not the functions.
      expect(out, contains('claude-proxy'));
      expect(out, contains('stripe-webhook'));
    });

    test('discovers client invocations (LIST C) incl. wrapper + const forms',
        () {
      final out = res.stdout as String;
      // literal functions.invoke(...)
      expect(out, contains('create-checkout'));
      // callEdgeFunction(...) literal
      expect(out, contains('dsar-export'));
      // const-resolved identifier (_kAppleVerifyFn = 'apple-iap-verify')
      expect(out, contains('apple-iap-verify'));
      // fetch-style functions/v1/... URL
      expect(out, contains('whisper-stt'));
    });

    test('lists local migration versions', () {
      final out = res.stdout as String;
      expect(out, contains('Local migration versions'));
    });
  });

  group('drift-check.yml — CI workflow contract', () {
    late String yml;
    setUpAll(() => yml = _read(_workflow));

    test('nightly cron schedule', () {
      expect(yml, contains('schedule:'));
      expect(yml, matches(RegExp(r'cron:\s*"[^"]+"')));
    });

    test('manual dispatch enabled', () {
      expect(yml, contains('workflow_dispatch:'));
    });

    test('uses secrets.SUPABASE_ACCESS_TOKEN', () {
      expect(yml, contains(r'${{ secrets.SUPABASE_ACCESS_TOKEN }}'));
    });

    test('fails loudly when the secret is missing', () {
      expect(yml, contains('SUPABASE_ACCESS_TOKEN secret is not set'));
    });

    test('runs the drift script with read-only permissions', () {
      expect(yml, contains('bash scripts/drift-check.sh'));
      expect(yml, contains('contents: read'));
    });
  });
}
