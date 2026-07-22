@Tags(['fast'])
library;

// =============================================================================
// org_edge_functions_contract_test.dart — B2B org client ↔ edge-fn surface
// =============================================================================
//
// 2026-07-16 — plan 1.1 (phantom edge-function audit). The org repository
// invoked 18 edge functions while only 8 existed in prod; users hit raw
// 404s. This contract pins the seam so it can never silently regress:
//
//   1. Every function name passed to `_invoke(...)` in org_repository.dart
//      must exist as a directory under supabase/functions/ (i.e. it is at
//      least committed and deployable), OR be explicitly listed in
//      `kPendingFunctions` — the set gated behind
//      `kOrgPendingB2bEndpointsEnabled` (default OFF, owner decision
//      2026-07-16: no paying B2B orgs).
//
//   2. Each pending (gated) invocation site must actually be guarded:
//      the enclosing method body must reference the flag before invoking.
//
//   3. If a pending function gains a directory under supabase/functions/,
//      the test fails on purpose — remove it from the pending set (and,
//      once all are deployed, retire the flag) instead of leaving stale
//      gates around.
//
//   4. The flag itself defaults to false (no dart-define in CI).
// =============================================================================

import 'dart:io';

import 'package:advocat/config/feature_flags.dart';
import 'package:flutter_test/flutter_test.dart';

/// Edge functions the client references but that are NOT deployed/committed
/// yet. Must stay in sync with the doc comment on
/// [kOrgPendingB2bEndpointsEnabled] in lib/config/feature_flags.dart.
const Set<String> kPendingFunctions = {
  'cancel-invitation',
  'change-plan',
  'change-seats',
  'check-slug-availability',
  'org-billing-summary',
  'org-invoices',
  'preview-invitation',
  'resend-invitation',
  'save-org-branding',
};

const String kRepoPath =
    'lib/features/organization/repositories/org_repository.dart';
const String kFunctionsDir = 'supabase/functions';
const String kFlagName = 'kOrgPendingB2bEndpointsEnabled';

void main() {
  late final String repoSource;
  late final Set<String> deployedFunctions;
  late final List<RegExpMatch> invokeMatches;

  setUpAll(() {
    repoSource = File(kRepoPath).readAsStringSync();
    deployedFunctions = Directory(kFunctionsDir)
        .listSync()
        .whereType<Directory>()
        .map((d) => d.uri.pathSegments
            .lastWhere((s) => s.isNotEmpty)) // trailing '/' → last non-empty
        .toSet();
    invokeMatches = RegExp(r"_invoke\(\s*'([a-z0-9\-_]+)'")
        .allMatches(repoSource)
        .toList();
  });

  test('sanity: repository still invokes edge functions via _invoke', () {
    // If the invocation pattern is refactored, this test must be updated —
    // fail loudly instead of silently matching nothing.
    expect(invokeMatches, isNotEmpty,
        reason: '$kRepoPath no longer matches the _invoke(\'name\' pattern; '
            'update org_edge_functions_contract_test.dart to the new seam.');
    expect(deployedFunctions, isNotEmpty,
        reason: '$kFunctionsDir listing came back empty — wrong cwd?');
  });

  test(
      'every edge function invoked by OrgRepository exists in '
      'supabase/functions/ or is flag-gated as pending', () {
    final violations = <String>[];
    for (final m in invokeMatches) {
      final name = m.group(1)!;
      final exists = deployedFunctions.contains(name);
      final gated = kPendingFunctions.contains(name);
      if (!exists && !gated) {
        violations.add(name);
      }
    }
    expect(violations, isEmpty,
        reason: 'OrgRepository invokes edge functions that neither exist '
            'under $kFunctionsDir nor are gated behind $kFlagName: '
            '$violations. Either commit+deploy the function or add it to '
            'kPendingFunctions AND guard the call site with the flag.');
  });

  test('every pending invocation site is guarded by $kFlagName', () {
    // For each pending function actually invoked, walk back from the
    // invocation to the start of the enclosing method (nearest preceding
    // `@override` or method signature boundary) and require the flag to be
    // referenced in between.
    final unguarded = <String>[];
    for (final m in invokeMatches) {
      final name = m.group(1)!;
      if (!kPendingFunctions.contains(name)) continue;
      final methodStart =
          repoSource.lastIndexOf(RegExp(r'@override|Future<'), m.start);
      final body = repoSource.substring(
          methodStart < 0 ? 0 : methodStart, m.start);
      // Guard must appear after the method start (i.e. inside this method),
      // not just anywhere earlier in the file.
      if (!body.contains(kFlagName)) {
        unguarded.add(name);
      }
    }
    expect(unguarded, isEmpty,
        reason: 'These pending edge-fn invocations are not guarded by '
            '$kFlagName inside their method: $unguarded');
  });

  test('pending functions do not exist yet — un-gate when deployed', () {
    final nowExisting = kPendingFunctions.intersection(deployedFunctions);
    expect(nowExisting, isEmpty,
        reason: 'These functions now exist under $kFunctionsDir: '
            '$nowExisting. Deploy them to prod, then remove them from '
            'kPendingFunctions, un-gate the call sites, and update the '
            '$kFlagName doc comment.');
  });

  test('rename applied: change-member-role is gone, update-member-role used',
      () {
    expect(repoSource.contains("'change-member-role'"), isFalse,
        reason: 'change-member-role does not exist in prod; the client must '
            'call update-member-role.');
    expect(repoSource.contains("'update-member-role'"), isTrue);
    // update-member-role expects `member_user_id` (see its index.ts).
    expect(repoSource.contains("'member_user_id'"), isTrue,
        reason: 'update-member-role rejects bodies without member_user_id.');
    expect(deployedFunctions.contains('update-member-role'), isTrue);
  });

  test('$kFlagName defaults to OFF (owner decision 2026-07-16)', () {
    expect(kOrgPendingB2bEndpointsEnabled, isFalse,
        reason: 'No paying B2B orgs exist; the 9 pending endpoints must stay '
            'dark by default. Flip only via --dart-define after deploying.');
  });
}
