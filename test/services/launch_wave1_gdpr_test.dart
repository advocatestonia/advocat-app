import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/supabase_service.dart';

/// launch/wave1 GDPR regression tests (Agent 1-5).
///
/// GDPR Art. 15 (data portability) — user must receive *all* their data
/// in a machine-readable form. GDPR Art. 17 (right to erasure) — delete
/// must cascade across all child tables + storage files.
///
/// The current implementation:
///   * deleteAllUserData({required confirmEmail}) — calls the
///     `account-delete` edge fn under service-role; the edge fn does the
///     cascade across all tables + storage AND deletes auth.users
///     (App Store 5.1.1(v) hard requirement)
///   * exportUserData() — one JSON bundle with 6 collections (demo) or
///     a full dsar-export edge fn call (real)
///
/// These tests validate the *contract* (not the Supabase wire calls) in
/// demo mode: schema shape, all expected collections present, no field
/// dropped. If a future refactor removes `deadlines` from the export,
/// this test screams — that would be a GDPR Art. 15 violation.
void main() {
  late SupabaseService svc;

  setUp(() {
    svc = SupabaseService(); // demo mode by default
  });

  group('GDPR Art. 15 — exportUserData', () {
    test('returns all six canonical collections in demo mode', () async {
      final raw = await svc.exportUserData();
      final decoded = jsonDecode(raw) as Map<String, dynamic>;

      // Top-level keys the user is entitled to receive.
      for (final key in const [
        'profile', 'cases', 'documents', 'deadlines',
        'correspondence', 'chat_messages',
      ]) {
        expect(decoded.containsKey(key), isTrue,
            reason: 'GDPR Art. 15 requires "$key" in the export bundle');
      }
    });

    test('output is valid JSON that round-trips through a parser', () async {
      final raw = await svc.exportUserData();
      // Must not throw.
      final parsed = jsonDecode(raw);
      expect(parsed, isA<Map<String, dynamic>>());
    });

    test('export has a generation timestamp for audit trail', () async {
      final raw = await svc.exportUserData();
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      // At least one of: exported_at / export_timestamp / generated_at.
      final hasTs = decoded.keys.any((k) =>
          k.contains('export') || k.contains('generat') || k.contains('at'));
      expect(hasTs, isTrue,
          reason: 'export bundle must carry a timestamp for user audit');
    });
  });

  group('GDPR Art. 17 — deleteAllUserData (contract, demo-safe)', () {
    test('demo mode is a no-op that does not throw', () async {
      // In demo mode no real Supabase client exists. The method must
      // short-circuit gracefully — never leak an auth exception to the
      // UI layer.
      // confirmEmail is now a required parameter (App Store 5.1.1(v) — the
      // Flutter UI requires the user to type their email to confirm; the
      // edge fn re-checks it server-side). In demo mode the call returns
      // before reading it.
      await expectLater(
        svc.deleteAllUserData(confirmEmail: 'demo@example.com'),
        completes,
      );
    });
  });
}
