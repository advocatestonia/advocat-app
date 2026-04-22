// ---------------------------------------------------------------------------
// OMEGA-BULLETPROOF BP-3: structured telemetry events
// ---------------------------------------------------------------------------
//
// Thin wrapper on top of `telemetry_sink.dart` so callers can emit
// categorized events (ai_failure / stripe_failure / cron_failure /
// rls_violation / cap_hit / cost_alert) without re-implementing the
// consent gate, PII scrub, or fire-and-forget behaviour.
//
// Consumers should call `reportAiFailure(...)` / `reportStripeFailure(...)`
// etc. from catch-sites in the relevant service layers. The sink itself
// still no-ops when the user has not consented.
//
// The migration `20260421_app_errors_event_kind.sql` adds the `event_kind`
// column and the CHECK constraint — see that file for the canonical list.

import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'telemetry_sink.dart';

enum TelemetryEventKind {
  error,
  aiFailure,
  stripeFailure,
  cronFailure,
  rlsViolation,
  capHit,
  costAlert,
}

String _kindToColumn(TelemetryEventKind k) {
  switch (k) {
    case TelemetryEventKind.error:
      return 'error';
    case TelemetryEventKind.aiFailure:
      return 'ai_failure';
    case TelemetryEventKind.stripeFailure:
      return 'stripe_failure';
    case TelemetryEventKind.cronFailure:
      return 'cron_failure';
    case TelemetryEventKind.rlsViolation:
      return 'rls_violation';
    case TelemetryEventKind.capHit:
      return 'cap_hit';
    case TelemetryEventKind.costAlert:
      return 'cost_alert';
  }
}

const int _messageCap = 500;
const int _stackCap = 2048;

/// Low-level emitter. Prefer the named helpers below.
Future<void> reportEvent({
  required SupabaseClient client,
  required TelemetryEventKind kind,
  required String errorType,
  required String errorMessage,
  StackTrace? stack,
  String? route,
  String? hint,
  String? appVersion,
  String? locale,
}) async {
  if (kDebugMode) return;
  if (!await hasTelemetryConsent()) return;

  final trimmedMsg = errorMessage.length > _messageCap
      ? errorMessage.substring(0, _messageCap)
      : errorMessage;
  final stackStr = (stack ?? StackTrace.current).toString();
  final trimmedStack =
      stackStr.length > _stackCap ? stackStr.substring(0, _stackCap) : stackStr;

  try {
    await client.from('app_errors').insert({
      'event_kind': _kindToColumn(kind),
      'route': route,
      'hint': hint,
      'error_type': errorType,
      'error_message': trimmedMsg,
      'stack_snippet': trimmedStack,
      'app_version': appVersion,
      'platform': kIsWeb ? 'web' : null,
      'locale': locale,
    });
  } catch (_) {
    // Telemetry must never cascade.
  }
}

/// Shortcut: AI response error (timeout, empty, http!=200).
Future<void> reportAiFailure({
  required SupabaseClient client,
  required String message,
  String? route,
}) =>
    unawaited_(reportEvent(
      client: client,
      kind: TelemetryEventKind.aiFailure,
      errorType: 'AiFailure',
      errorMessage: message,
      route: route,
      hint: 'claude-proxy',
    ));

/// Shortcut: Stripe webhook / checkout transition anomaly.
Future<void> reportStripeFailure({
  required SupabaseClient client,
  required String message,
  String? route,
}) =>
    unawaited_(reportEvent(
      client: client,
      kind: TelemetryEventKind.stripeFailure,
      errorType: 'StripeFailure',
      errorMessage: message,
      route: route,
      hint: 'stripe-webhook',
    ));

/// Shortcut: deadline-reminder / scheduled task failure (rare client-side;
/// most cron lives server-side but we still want clients to report if a
/// reminder notification fails to dispatch).
Future<void> reportCronFailure({
  required SupabaseClient client,
  required String message,
  String? route,
}) =>
    unawaited_(reportEvent(
      client: client,
      kind: TelemetryEventKind.cronFailure,
      errorType: 'CronFailure',
      errorMessage: message,
      route: route,
      hint: 'deadline-reminder',
    ));

/// Shortcut: RLS policy violation (catch-site at write failure).
Future<void> reportRlsViolation({
  required SupabaseClient client,
  required String message,
  String? route,
}) =>
    unawaited_(reportEvent(
      client: client,
      kind: TelemetryEventKind.rlsViolation,
      errorType: 'RlsViolation',
      errorMessage: message,
      route: route,
      hint: 'rls',
    ));

/// Shortcut: founder cap reached (client sees the 403 from checkout).
Future<void> reportCapHit({
  required SupabaseClient client,
  required String message,
  String? route,
}) =>
    unawaited_(reportEvent(
      client: client,
      kind: TelemetryEventKind.capHit,
      errorType: 'CapHit',
      errorMessage: message,
      route: route,
      hint: 'founder-beta',
    ));

/// Shortcut: cost alert (triggered by server-side Claude cost aggregator,
/// but included here so a client-observed rate-limit can also emit).
Future<void> reportCostAlert({
  required SupabaseClient client,
  required String message,
}) =>
    unawaited_(reportEvent(
      client: client,
      kind: TelemetryEventKind.costAlert,
      errorType: 'CostAlert',
      errorMessage: message,
      hint: 'claude-cost',
    ));

/// Internal helper — wraps Future in a fire-and-forget so the caller can
/// `await` without blocking.
Future<void> unawaited_(Future<void> f) async {
  // ignore: discarded_futures
  unawaited(f);
}
