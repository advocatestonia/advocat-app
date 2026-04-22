// ---------------------------------------------------------------------------
// launch/wave1 — Agent 1-6: Sentry-lite telemetry sink
// ---------------------------------------------------------------------------
//
// Forwards error-boundary reports to the public.app_errors table (see
// supabase/migrations/20260421_app_errors_telemetry.sql) so the owner can
// see production issues without paying for Sentry/Bugsnag.
//
// The sink is **opt-in** per installation. We store the choice in
// SharedPreferences under key `telemetry_consent_v1`; if the user has not
// explicitly accepted, nothing is ever sent.
//
// The sink is also **PII-scrubbed**: we truncate the stack trace, do not
// include the user id, and do not forward any Flutter widget inspector
// dumps that might contain message contents.

import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'error_boundary.dart';

const String _consentKey = 'telemetry_consent_v1';
const int _messageCap = 500;
const int _stackCap = 2048;

/// Returns true if the user has explicitly opted into error telemetry.
Future<bool> hasTelemetryConsent() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_consentKey) ?? false;
  } catch (_) {
    return false;
  }
}

/// Persists the user's opt-in / opt-out choice.
Future<void> setTelemetryConsent(bool accepted) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_consentKey, accepted);
  } catch (_) {
    // SharedPreferences failure (private browsing, sandbox) — the sink
    // will default to "no consent" on the next check, which is the safe
    // behaviour.
  }
}

/// Installs the Supabase-backed sink if the current user has consented.
/// Safe to call at any time; it's a no-op when consent is missing.
Future<void> installTelemetrySinkIfConsented({
  required SupabaseClient client,
  String? appVersion,
  String? locale,
}) async {
  if (kDebugMode) return; // never phone home in debug builds
  if (!await hasTelemetryConsent()) return;

  setErrorSink((Object error, StackTrace stack, {String? route, String? hint}) {
    // Fire-and-forget; we never await inside the boundary.
    unawaited(_publish(
      client: client,
      error: error,
      stack: stack,
      route: route,
      hint: hint,
      appVersion: appVersion,
      locale: locale,
    ));
  });
}

/// Removes the sink — used when the user revokes consent.
void uninstallTelemetrySink() {
  setErrorSink(null);
}

Future<void> _publish({
  required SupabaseClient client,
  required Object error,
  required StackTrace stack,
  String? route,
  String? hint,
  String? appVersion,
  String? locale,
}) async {
  try {
    final msg = error.toString();
    final trimmedMsg =
        msg.length > _messageCap ? msg.substring(0, _messageCap) : msg;
    final stackStr = stack.toString();
    final trimmedStack =
        stackStr.length > _stackCap ? stackStr.substring(0, _stackCap) : stackStr;

    await client.from('app_errors').insert({
      'route': route,
      'hint': hint,
      'error_type': error.runtimeType.toString(),
      'error_message': trimmedMsg,
      'stack_snippet': trimmedStack,
      'app_version': appVersion,
      'platform': kIsWeb ? 'web' : null,
      'locale': locale,
    });
  } catch (_) {
    // Telemetry must never cascade into a new error. Swallow.
  }
}
