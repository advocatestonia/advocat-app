// Pure unit tests for the lawyer-verification model layer.
// -----------------------------------------------------------------------------
// Ref: lib/features/lawyer_verification/models/lawyer_verification_state.dart
//
// Three things under test:
//   * LawyerVerificationApplication.isComplete — client-side gate.
//   * LawyerVerificationApplication.toJson — request shape.
//   * LawyerVerificationLifecycle.parse — DB column → enum.
//
// No widget tree, no Supabase mock — these stay fast (sub-100 ms total).
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';
import 'package:advocat/features/lawyer_verification/models/lawyer_verification_state.dart';

void main() {
  group('LawyerVerificationApplication.isComplete', () {
    test('rejects empty application', () {
      expect(const LawyerVerificationApplication().isComplete, isFalse);
    });

    test('rejects missing country', () {
      final app = const LawyerVerificationApplication()
          .copyWith(
            barId: '5421',
            fullName: 'Dmitri Sulga',
            email: 'd@example.com',
          );
      expect(app.isComplete, isFalse);
    });

    test('rejects single-token name', () {
      final app = const LawyerVerificationApplication(
        country: LawyerBarCountry.ee,
        barId: '5421',
        fullName: 'Madonna',
        email: 'd@example.com',
      );
      expect(app.isComplete, isFalse);
    });

    test('rejects malformed email', () {
      final app = const LawyerVerificationApplication(
        country: LawyerBarCountry.ee,
        barId: '5421',
        fullName: 'Dmitri Sulga',
        email: 'no-at-sign',
      );
      expect(app.isComplete, isFalse);
    });

    test('accepts a complete minimal payload', () {
      final app = const LawyerVerificationApplication(
        country: LawyerBarCountry.fi,
        barId: '12345',
        fullName: 'Matti Virtanen',
        email: 'matti@firm.fi',
      );
      expect(app.isComplete, isTrue);
    });

    test('rejects practice_url without scheme', () {
      final app = const LawyerVerificationApplication(
        country: LawyerBarCountry.ee,
        barId: '5421',
        fullName: 'Dmitri Sulga',
        email: 'd@example.com',
        practiceUrl: 'advokaadid.ee/sulga',
      );
      expect(app.isComplete, isFalse);
    });

    test('accepts http and https practice_url', () {
      const baseApp = LawyerVerificationApplication(
        country: LawyerBarCountry.ee,
        barId: '5421',
        fullName: 'Dmitri Sulga',
        email: 'd@example.com',
      );
      expect(
        baseApp.copyWith(practiceUrl: 'http://firm.ee/sulga').isComplete,
        isTrue,
      );
      expect(
        baseApp.copyWith(practiceUrl: 'https://linkedin.com/in/sulga').isComplete,
        isTrue,
      );
    });
  });

  group('LawyerVerificationApplication.toJson', () {
    test('serialises the expected keys', () {
      final json = const LawyerVerificationApplication(
        country: LawyerBarCountry.ee,
        barId: '  5421 ',
        fullName: '  Dmitri Sulga  ',
        email: 'Dmitri@Example.COM',
        practiceUrl: 'https://firm.ee/sulga',
      ).toJson();

      expect(json['country'], 'EE');
      expect(json['bar_id'], '5421');
      expect(json['name'], 'Dmitri Sulga');
      expect(json['email'], 'dmitri@example.com');
      expect(json['practice_url'], 'https://firm.ee/sulga');
    });

    test('omits practice_url when blank', () {
      final json = const LawyerVerificationApplication(
        country: LawyerBarCountry.fi,
        barId: '12345',
        fullName: 'Matti Virtanen',
        email: 'matti@firm.fi',
        practiceUrl: '   ',
      ).toJson();
      expect(json.containsKey('practice_url'), isFalse);
    });
  });

  group('LawyerBarCountry.tryParse', () {
    test('handles canonical codes', () {
      expect(LawyerBarCountry.tryParse('FI'), LawyerBarCountry.fi);
      expect(LawyerBarCountry.tryParse('EE'), LawyerBarCountry.ee);
    });
    test('case-insensitive', () {
      expect(LawyerBarCountry.tryParse('fi'), LawyerBarCountry.fi);
    });
    test('returns null for unknown', () {
      expect(LawyerBarCountry.tryParse('DE'), isNull);
      expect(LawyerBarCountry.tryParse(null), isNull);
    });
  });

  group('LawyerVerificationLifecycle', () {
    test('parses DB strings', () {
      expect(
        LawyerVerificationLifecycle.parse('auto_approved'),
        LawyerVerificationLifecycle.autoApproved,
      );
      expect(
        LawyerVerificationLifecycle.parse('pending'),
        LawyerVerificationLifecycle.pending,
      );
      expect(
        LawyerVerificationLifecycle.parse('manually_approved'),
        LawyerVerificationLifecycle.manuallyApproved,
      );
      expect(
        LawyerVerificationLifecycle.parse('rejected'),
        LawyerVerificationLifecycle.rejected,
      );
      expect(
        LawyerVerificationLifecycle.parse('revoked'),
        LawyerVerificationLifecycle.revoked,
      );
    });

    test('falls back to none on unknown / null', () {
      expect(
        LawyerVerificationLifecycle.parse(null),
        LawyerVerificationLifecycle.none,
      );
      expect(
        LawyerVerificationLifecycle.parse('weird_value'),
        LawyerVerificationLifecycle.none,
      );
    });

    test('isCurrentlyVerified flag', () {
      expect(
        LawyerVerificationLifecycle.autoApproved.isCurrentlyVerified,
        isTrue,
      );
      expect(
        LawyerVerificationLifecycle.manuallyApproved.isCurrentlyVerified,
        isTrue,
      );
      expect(
        LawyerVerificationLifecycle.pending.isCurrentlyVerified,
        isFalse,
      );
      expect(
        LawyerVerificationLifecycle.rejected.isCurrentlyVerified,
        isFalse,
      );
      expect(
        LawyerVerificationLifecycle.revoked.isCurrentlyVerified,
        isFalse,
      );
    });
  });
}
