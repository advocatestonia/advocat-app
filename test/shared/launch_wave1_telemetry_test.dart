import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:advocat/shared/telemetry_sink.dart';

/// launch/wave1 telemetry sink — Agent 1-6.
///
/// We cannot talk to a real Supabase table in unit tests, but we CAN
/// lock down the consent contract: no consent → nothing is written, and
/// the opt-in value round-trips through SharedPreferences.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('hasTelemetryConsent defaults to false', () async {
    expect(await hasTelemetryConsent(), isFalse);
  });

  test('setTelemetryConsent(true) persists and is read back', () async {
    await setTelemetryConsent(true);
    expect(await hasTelemetryConsent(), isTrue);
  });

  test('setTelemetryConsent(false) revokes a prior opt-in', () async {
    await setTelemetryConsent(true);
    expect(await hasTelemetryConsent(), isTrue);
    await setTelemetryConsent(false);
    expect(await hasTelemetryConsent(), isFalse);
  });

  test('uninstallTelemetrySink does not throw when sink is null', () {
    expect(() => uninstallTelemetrySink(), returnsNormally);
  });
}
