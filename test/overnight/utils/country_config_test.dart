// Overnight isolated test suite — DOES NOT modify production code.
// Tests for EUCountries / EUCountryConfig.
import 'package:flutter_test/flutter_test.dart';
import 'package:advocat/services/country_config.dart';

void main() {
  group('EUCountries', () {
    test('sorted list is non-empty', () {
      expect(EUCountries.sorted, isNotEmpty);
    });

    test('Estonia and Finland are present (primary markets)', () {
      final codes = EUCountries.sorted.map((c) => c.code).toSet();
      expect(codes.contains('EE'), isTrue);
      expect(codes.contains('FI'), isTrue);
    });

    test('all codes are 2 uppercase letters', () {
      for (final c in EUCountries.sorted) {
        expect(c.code.length, 2, reason: 'Bad code length: ${c.code}');
        expect(c.code, c.code.toUpperCase(),
            reason: 'Non-uppercase code: ${c.code}');
      }
    });

    test('all codes are unique', () {
      final codes = EUCountries.sorted.map((c) => c.code).toList();
      expect(codes.toSet().length, codes.length);
    });

    test('every config has non-empty names and flag', () {
      for (final c in EUCountries.sorted) {
        expect(c.nameEn, isNotEmpty);
        expect(c.nameNative, isNotEmpty);
        expect(c.flag, isNotEmpty);
      }
    });

    test('const constructor equality works for identical configs', () {
      const a = EUCountryConfig(
        code: 'EE',
        flag: '🇪🇪',
        nameEn: 'Estonia',
        nameNative: 'Eesti',
      );
      const b = EUCountryConfig(
        code: 'EE',
        flag: '🇪🇪',
        nameEn: 'Estonia',
        nameNative: 'Eesti',
      );
      // const identity
      expect(identical(a, b), isTrue);
    });
  });
}
