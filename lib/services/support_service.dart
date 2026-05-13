// support_service.dart
// ---------------------------------------------------------------------------
// Thin client for the `support-ticket` Supabase edge function. Used by the
// in-app SupportSheet to deliver a single ticket from any visitor (anon or
// authenticated) to the founders' Telegram group via the backend.
//
// Two implementations live side-by-side here:
//
//   * `SupportService` — calls Supabase via `functions.invoke`. The HTTP
//     bits are owned by the Supabase SDK so we inherit JWT-when-available
//     plus the platform's CORS/auth setup. In demo mode (no Supabase
//     credentials) we short-circuit with a synthetic success so the UI can
//     be exercised in dev builds without burning a real ticket.
//
//   * `SupportServiceMeta` (pure, static) — builds the request payload so
//     the widget tests can lock in the metadata-injection contract
//     (page URL, language, app version, contact channel, honeypot field
//     `_hp`) without touching Supabase or `dart:html`.
//
// Anti-injection on the client is light: we trust the server to do final
// validation, but we DO enforce the same 10..2000 char window before we
// send so the user sees an immediate error instead of a round-trip.
// ---------------------------------------------------------------------------

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import 'supabase_service.dart';

/// Riverpod provider — read once and reuse. The underlying service holds no
/// state beyond a SupabaseService reference.
final supportServiceProvider = Provider<SupportService>((ref) {
  return SupportService(ref.read(supabaseServiceProvider));
});

/// Allowed category slugs. Must match the CHECK constraint on
/// public.support_tickets and the VALID_CATEGORIES set in the edge fn.
enum SupportCategory { bug, payment, question, feature, other }

extension SupportCategoryWire on SupportCategory {
  /// Wire-format slug accepted by the backend.
  String get wireValue => switch (this) {
        SupportCategory.bug => 'bug',
        SupportCategory.payment => 'payment',
        SupportCategory.question => 'question',
        SupportCategory.feature => 'feature',
        SupportCategory.other => 'other',
      };
}

/// Allowed contact channel slugs. The widget always submits `in_app` for
/// the in-app form path; the other two are reserved for future telemetry
/// when we want to attribute outbound clicks on the WhatsApp / Email
/// buttons.
enum SupportContactChannel { inApp, whatsapp, email }

extension SupportContactChannelWire on SupportContactChannel {
  String get wireValue => switch (this) {
        SupportContactChannel.inApp => 'in_app',
        SupportContactChannel.whatsapp => 'whatsapp',
        SupportContactChannel.email => 'email',
      };
}

/// Result of a submission. Either the server returned ok+ticket_id, or it
/// returned a structured error we can surface in the UI.
class SupportSubmitResult {
  const SupportSubmitResult.ok(this.ticketId)
      : success = true,
        errorReason = null,
        errorMessage = null;

  const SupportSubmitResult.error(this.errorReason, this.errorMessage)
      : success = false,
        ticketId = null;

  final bool success;
  final String? ticketId;
  final String? errorReason;
  final String? errorMessage;
}

/// Compile-time tuning knobs. Matches MESSAGE_MIN/MAX in the edge fn.
class SupportLimits {
  SupportLimits._();
  static const int messageMin = 10;
  static const int messageMax = 2000;
}

/// Pure, static helpers exposed for tests + the widget. No Supabase, no
/// `dart:html`, no `Platform.environment` — safe to import from any
/// pure-Dart test.
class SupportServiceMeta {
  SupportServiceMeta._();

  /// Builds the JSON payload sent to the edge function.
  ///
  /// [message] is trimmed; callers that need length validation should call
  /// [validateMessage] first so the user sees an immediate error instead
  /// of a round-trip.
  static Map<String, dynamic> buildPayload({
    required SupportCategory category,
    required String message,
    required SupportContactChannel contactChannel,
    String? email,
    String? pageUrl,
    String? language,
    String? appVersion,
    String honeypot = '',
  }) {
    final payload = <String, dynamic>{
      'category': category.wireValue,
      'message': message.trim(),
      'contact_channel': contactChannel.wireValue,
      // Always include the honeypot field — server treats an empty string
      // as legitimate human submission.
      '_hp': honeypot,
    };

    if (email != null && email.trim().isNotEmpty) {
      payload['email'] = email.trim();
    }
    if (pageUrl != null && pageUrl.isNotEmpty) {
      payload['page_url'] = pageUrl;
    }
    if (language != null && language.isNotEmpty) {
      payload['language'] = language;
    }
    if (appVersion != null && appVersion.isNotEmpty) {
      payload['app_version'] = appVersion;
    }
    return payload;
  }

  /// Validate the message length matches the edge fn contract. Returns
  /// null if valid, or a stable error code for the UI ('too_short' /
  /// 'too_long') the widget can translate.
  static String? validateMessage(String message) {
    final trimmed = message.trim();
    if (trimmed.length < SupportLimits.messageMin) return 'too_short';
    if (trimmed.length > SupportLimits.messageMax) return 'too_long';
    return null;
  }

  /// Best-effort detection of the current page URL on web; on native we
  /// return an empty string and the edge function records page_url='' .
  /// Exposed for tests so they can override.
  static String defaultPageUrl() {
    if (!kIsWeb) return '';
    try {
      return Uri.base.toString();
    } catch (_) {
      return '';
    }
  }
}

/// Live client. In demo mode (Supabase not initialised) the [submitTicket]
/// call short-circuits with a synthetic success so widget tests + local
/// dev builds can exercise the happy-path flow without a backend.
class SupportService {
  SupportService(this._supabase);

  final SupabaseService _supabase;

  static const String _functionName = 'support-ticket';

  /// Submit a ticket. Returns a typed [SupportSubmitResult] — never
  /// throws on validation or HTTP errors; only unrecoverable network
  /// failures (no connection at all) surface as `errorReason='network'`.
  Future<SupportSubmitResult> submitTicket({
    required SupportCategory category,
    required String message,
    SupportContactChannel contactChannel = SupportContactChannel.inApp,
    String? email,
    String? language,
    String? appVersion,
    String honeypot = '',
    @visibleForTesting String? pageUrlOverride,
  }) async {
    final validationError = SupportServiceMeta.validateMessage(message);
    if (validationError != null) {
      return SupportSubmitResult.error(validationError, null);
    }

    final payload = SupportServiceMeta.buildPayload(
      category: category,
      message: message,
      contactChannel: contactChannel,
      email: email,
      pageUrl: pageUrlOverride ?? SupportServiceMeta.defaultPageUrl(),
      language: language,
      appVersion: appVersion ?? AppConfig.appVersion,
      honeypot: honeypot,
    );

    if (_supabase.isDemo) {
      // Demo / offline build: pretend success with a synthetic ticket id so
      // the UI flow can be exercised end-to-end.
      return const SupportSubmitResult.ok('demo-00000000-0000-0000-0000-000000000000');
    }

    try {
      final res = await Supabase.instance.client.functions.invoke(
        _functionName,
        body: payload,
      );
      if (res.status >= 200 && res.status < 300) {
        final data = res.data;
        if (data is Map && data['ticket_id'] is String) {
          return SupportSubmitResult.ok(data['ticket_id'] as String);
        }
        // Server returned 2xx but no ticket id — treat as generic success
        // (the row was almost certainly saved, but we have nothing to
        // surface in the UI).
        return const SupportSubmitResult.ok('');
      }
      // Server returned a structured error. Pull `reason` / `error` if
      // present so the widget can localise the message.
      final data = res.data;
      String? reason;
      String? errorMessage;
      if (data is Map) {
        reason = (data['reason'] as String?) ?? (data['error'] as String?);
        errorMessage = data['error'] as String?;
      }
      return SupportSubmitResult.error(
        reason ?? 'server_${res.status}',
        errorMessage,
      );
    } on FunctionException catch (e) {
      // FunctionException carries the server's structured error body.
      final body = e.details;
      String? reason;
      String? errorMessage;
      if (body is Map) {
        reason = (body['reason'] as String?) ?? (body['error'] as String?);
        errorMessage = body['error'] as String?;
      }
      return SupportSubmitResult.error(
        reason ?? 'server_${e.status}',
        errorMessage,
      );
    } catch (e) {
      // Total network failure (offline, DNS, etc.). Keep the modal open
      // so the user can retry without retyping their message.
      return SupportSubmitResult.error('network', e.toString());
    }
  }
}
