// =============================================================================
// logout_purge_test.dart — F1 regression test (WAVE 1, 2026-05-28)
// =============================================================================
//
// Why this exists
// ---------------
// F1 of the 2026-05-28 client security audit
// (`docs/security_audit_2026-05-28/findings/03_client_security.md`) flagged
// that `AuthController.logout()` previously called `_supabase.signOut()` and
// flipped the auth state to unauthenticated, but never touched
// SharedPreferences. The intake-wizard draft (case facts, party names),
// the contract-review handoff blob (summary + risk count + filename), and
// the active case UUID all survived logout — readable by the next user on
// a shared firm tablet, or by any XSS payload on web (where prefs map to
// localStorage). The fix added `purgeLegalPrefs()` to logout and exposed
// it as `@visibleForTesting static Future<void> AuthController.purgeLegalPrefs()`.
//
// This test pins down the contract so a future refactor that drops the
// purge call cannot silently regress the attorney-client confidentiality
// guarantee.
//
// Strategy
// --------
// We don't drive the full AuthController.logout() flow here (that needs
// the Riverpod container + a fake Supabase) — `auth_provider_test.dart`
// already covers the state-machine half. This file focuses on the
// SharedPreferences contract: seed every relevant key shape, call
// `purgeLegalPrefs()`, and assert the prefs are empty (modulo allowlist
// of non-legal keys we explicitly keep, like the app locale).

@Tags(['fast'])
library;

import 'package:advocat/features/auth/providers/auth_provider.dart';
import 'package:advocat/features/case_memory/state/active_case_provider.dart';
import 'package:advocat/features/case_memory/state/intake_wizard_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthController.purgeLegalPrefs — F1 (2026-05-28)', () {
    test('removes explicit legal-content keys', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'contract_review_handoff_v1': '{"summary":"NDA dispute","score":42}',
        kIntakeDraftPrefKey: '{"case_type":"deportation","facts":"..."}',
        kActiveCaseIdPrefKey: '11111111-2222-3333-4444-555555555555',
        'pending_checkout': '{"plan":"counsel","billing":"yearly"}',
      });

      await AuthController.purgeLegalPrefs();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('contract_review_handoff_v1'), isNull,
          reason: 'contract_review_handoff_v1 must be purged');
      expect(prefs.getString(kIntakeDraftPrefKey), isNull,
          reason: 'kIntakeDraftPrefKey must be purged');
      expect(prefs.getString(kActiveCaseIdPrefKey), isNull,
          reason: 'kActiveCaseIdPrefKey must be purged');
      expect(prefs.getString('pending_checkout'), isNull,
          reason: 'pending_checkout must be purged');
    });

    test('sweeps prefix-matched legal keys (case_, draft_, vault_, intake_, pending_checkout_)',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'case_workspace_tab_abc123': 'documents',
        'case_recent_uuid_xyz': '2026-05-28T10:00:00Z',
        'draft_letter_42': 'Dear court...',
        'draft_email_99': '{"to":"client@firm.ee"}',
        'vault_filter_state': '{"sort":"date"}',
        'vault_open_doc_777': 'doc-uuid',
        'intake_step': '3',
        'intake_partial_jurisdiction': 'FI',
        'pending_checkout_session_xyz': 'cs_test_abc',
      });

      await AuthController.purgeLegalPrefs();

      final prefs = await SharedPreferences.getInstance();
      final remainingKeys = prefs.getKeys();
      expect(remainingKeys, isEmpty,
          reason:
              'Every prefix-matched legal key should be wiped. Got: $remainingKeys');
    });

    test('preserves non-legal keys (e.g. app locale, theme)', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        // Non-legal — must survive logout.
        'app_locale': 'fi',
        'theme_mode': 'dark',
        'advocat_cookie_consent_v1': '{"choice":"accept"}',
        'telemetry_consent_v1': true,
        // Legal — must be wiped.
        kIntakeDraftPrefKey: '{"facts":"x"}',
        'case_recent_abc': 'x',
      });

      await AuthController.purgeLegalPrefs();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_locale'), 'fi',
          reason: 'app_locale must survive logout');
      expect(prefs.getString('theme_mode'), 'dark',
          reason: 'theme_mode must survive logout');
      expect(prefs.getString('advocat_cookie_consent_v1'),
          '{"choice":"accept"}',
          reason: 'cookie consent must survive logout');
      expect(prefs.getBool('telemetry_consent_v1'), isTrue,
          reason: 'telemetry consent must survive logout');
      expect(prefs.getString(kIntakeDraftPrefKey), isNull,
          reason: 'legal intake draft must be purged');
      expect(prefs.getString('case_recent_abc'), isNull,
          reason: 'case_-prefixed key must be purged');
    });

    test('is idempotent — calling twice on already-empty prefs is fine',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await AuthController.purgeLegalPrefs();
      await AuthController.purgeLegalPrefs(); // no throw
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), isEmpty);
    });

    test('handles a pref store that contains only non-legal keys', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'app_locale': 'et',
        'theme_mode': 'light',
      });
      await AuthController.purgeLegalPrefs();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_locale'), 'et');
      expect(prefs.getString('theme_mode'), 'light');
    });

    test('handles mixed real-world payload (privilege-confidentiality scenario)',
        () async {
      // Reproduces the F1 exploit scenario: lawyer-A finishes drafting,
      // taps Logout on a firm tablet. We seed every key the audit
      // identified as a leak vector. After purge, all of them must be
      // gone, but the device locale/theme survive so lawyer-B sees a
      // fresh login screen in the expected language.
      SharedPreferences.setMockInitialValues(<String, Object>{
        // F1 explicit leak keys
        'contract_review_handoff_v1':
            '{"contract_review_id":"r1","summary":"Privileged NDA review for Acme v. Foo"}',
        kIntakeDraftPrefKey:
            '{"jurisdiction":"FI","case_type":"deportation","facts":"Privileged client narrative"}',
        kActiveCaseIdPrefKey: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
        'pending_checkout': '{"plan":"representation"}',
        // F1 prefix-sweep examples
        'case_workspace_tab_aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee':
            'deadlines',
        'draft_letter_to_court_2026-05-28': 'Dear KHO...',
        'vault_last_opened_doc': 'doc-uuid',
        'intake_step_3_partial':
            '{"parties":"Sulga vs Finland","facts":"..."}',
        // Non-legal — must be preserved
        'app_locale': 'fi',
        'theme_mode': 'dark',
      });

      await AuthController.purgeLegalPrefs();

      final prefs = await SharedPreferences.getInstance();
      // Every legal key gone.
      expect(prefs.getString('contract_review_handoff_v1'), isNull);
      expect(prefs.getString(kIntakeDraftPrefKey), isNull);
      expect(prefs.getString(kActiveCaseIdPrefKey), isNull);
      expect(prefs.getString('pending_checkout'), isNull);
      expect(
          prefs.getString(
              'case_workspace_tab_aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'),
          isNull);
      expect(prefs.getString('draft_letter_to_court_2026-05-28'), isNull);
      expect(prefs.getString('vault_last_opened_doc'), isNull);
      expect(prefs.getString('intake_step_3_partial'), isNull);
      // Locale + theme preserved.
      expect(prefs.getString('app_locale'), 'fi');
      expect(prefs.getString('theme_mode'), 'dark');
    });
  });
}
