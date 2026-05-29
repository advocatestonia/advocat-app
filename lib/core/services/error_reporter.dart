// ---------------------------------------------------------------------------
// ErrorReporter — Sentry wrapper with STRICT PII scrubbing.
// ---------------------------------------------------------------------------
//
// Advocat handles legal/PII-heavy content (chat messages, vault documents,
// email bodies, case numbers, identity data). Sending raw event payloads to
// Sentry would breach privilege & GDPR. Everything that leaves the app is
// passed through a beforeSend / beforeBreadcrumb scrubber that:
//
//   1. DROPS any event whose message looks like user content (emails,
//      case numbers, card numbers, free-text > 500 chars).
//   2. Strips the user object down to a hashed id — never email, name,
//      ip_address, geo, segment.
//   3. Removes query params from URLs (case_id, draft_id, doc_id can be
//      sensitive even in URL form).
//   4. Wipes request bodies and extras matching known-PII keys.
//
// CRITICAL: the rule is "drop > scrub". If we're unsure, the event is
// dropped (return null). Better to lose error visibility than to leak.
//
// Usage:
//
//   // From anywhere in the app:
//   try {
//     await riskyCall();
//   } catch (e, st) {
//     await ErrorReporter.capture(e, st, extras: {'route': '/drafts'});
//     rethrow; // or surface a friendly error
//   }
//
//   // For non-fatal info/warnings:
//   await ErrorReporter.message('legacy iap path hit', level: SentryLevel.warning);
//
//   // On login (only call with an opaque uid — never email):
//   ErrorReporter.setUser(uid: supabaseUser.id);
//
//   // On logout:
//   ErrorReporter.clearUser();
//
// Initialisation lives in main.dart via SentryFlutter.init. If no DSN is
// provided at build time (--dart-define=SENTRY_DSN=...), this module
// degrades to a no-op so local dev / CI work normally.

import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sentry_flutter/sentry_flutter.dart';

/// Compile-time DSN. Empty in local dev → Sentry is never initialised.
const String sentryDsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');

/// Environment tag (production / staging / dev).
const String sentryEnv = String.fromEnvironment(
  'SENTRY_ENV',
  defaultValue: 'production',
);

/// Release tag — typically the short commit hash + semver. Surfaces in
/// Sentry release health and lets us correlate crashes to canary deploys.
const String sentryRelease = String.fromEnvironment(
  'APP_VERSION',
  defaultValue: 'unknown',
);

/// True if Sentry should be initialised in this build.
bool get sentryEnabled => sentryDsn.isNotEmpty;

/// Keys that frequently contain PII inside extras / contexts. Anything
/// matching is REMOVED entirely before the event is sent.
const Set<String> _piiExtraKeys = <String>{
  'email',
  'user_email',
  'name',
  'full_name',
  'phone',
  'address',
  'content',
  'message',
  'message_text',
  'chat_message',
  'body',
  'email_body',
  'document',
  'document_text',
  'vault_content',
  'case_summary',
  'identity_code',
  'isikukood',
  'henkilotunnus',
  'passport',
  'iban',
  'card',
  'ssn',
  'token',
  'access_token',
  'refresh_token',
  'authorization',
  'cookie',
  'jwt',
};

/// Sentry wrapper. Static-only — there is no instance state.
class ErrorReporter {
  ErrorReporter._();

  // ── public API ──────────────────────────────────────────────────────

  /// Captures an exception with an optional stack trace and bag of extras.
  /// Extras pass through [_scrubExtras] before being attached. Safe to
  /// call when Sentry is disabled — it becomes a no-op.
  static Future<void> capture(
    Object error,
    StackTrace? stack, {
    Map<String, dynamic>? extras,
    SentryLevel level = SentryLevel.error,
  }) async {
    if (!sentryEnabled) return;
    final scrubbed = _scrubExtras(extras ?? const <String, dynamic>{});
    try {
      await Sentry.captureException(
        error,
        stackTrace: stack,
        withScope: (scope) {
          scope.level = level;
          if (scrubbed.isNotEmpty) {
            // Grouped under 'advocat' so it appears as a single Context
            // panel in the Sentry UI (preferred over deprecated extras).
            scope.setContexts('advocat', scrubbed);
          }
        },
      );
    } catch (_) {
      // Telemetry must never cascade into a new failure.
    }
  }

  /// Captures a free-text message. Strings that look like PII are dropped
  /// silently — use [capture] with structured extras when in doubt.
  static Future<void> message(
    String msg, {
    SentryLevel level = SentryLevel.info,
  }) async {
    if (!sentryEnabled) return;
    if (looksLikePii(msg)) return;
    try {
      await Sentry.captureMessage(msg, level: level);
    } catch (_) {/* swallow */}
  }

  /// Attaches a hashed user id to the current scope. NEVER pass email
  /// or display name — only the opaque Supabase uid. Pass null to clear.
  static void setUser({String? uid}) {
    if (!sentryEnabled) return;
    try {
      Sentry.configureScope((scope) {
        if (uid == null || uid.isEmpty) {
          scope.setUser(null);
        } else {
          scope.setUser(SentryUser(id: hashedUserId(uid)));
        }
      });
    } catch (_) {/* swallow */}
  }

  /// Removes the user from the current scope. Call on logout.
  static void clearUser() => setUser(uid: null);

  // ── scrubbing helpers (visible for testing) ─────────────────────────

  /// beforeSend hook installed on the Sentry options in main.dart.
  /// Returns null to drop the event entirely.
  static FutureOr<SentryEvent?> beforeSend(SentryEvent event, Hint hint) {
    // 1. Drop event whose top-level message looks like PII.
    final msg = event.message?.formatted ?? '';
    if (msg.isNotEmpty && looksLikePii(msg)) return null;

    // 2. Strip user → hashed id only.
    final user = event.user;
    if (user != null) {
      event = event.copyWith(
        user: SentryUser(id: hashedUserId(user.id)),
      );
    }

    // 3. Scrub request: drop body/cookies; strip query string from url.
    final req = event.request;
    if (req != null) {
      event = event.copyWith(
        request: SentryRequest(
          url: _stripQuery(req.url),
          method: req.method,
          // headers/cookies/data deliberately omitted.
        ),
      );
    }

    // 4. Scrub the legacy `extra` map if anything upstream still uses it.
    // We prefer Contexts going forward; this branch is defensive.
    // ignore: deprecated_member_use
    final extra = event.extra;
    if (extra != null && extra.isNotEmpty) {
      // ignore: deprecated_member_use
      event = event.copyWith(extra: _scrubExtras(extra));
    }

    return event;
  }

  /// beforeBreadcrumb hook — drop breadcrumbs whose message or url
  /// contains PII patterns. Returning null removes the breadcrumb.
  /// Signature must match Sentry's [BeforeBreadcrumbCallback] (non-null
  /// breadcrumb arg, nullable return).
  static Breadcrumb? beforeBreadcrumb(
    Breadcrumb? breadcrumb,
    Hint hint,
  ) {
    if (breadcrumb == null) return null;
    final msg = breadcrumb.message ?? '';
    if (msg.isNotEmpty && looksLikePii(msg)) return null;

    // navigation/http breadcrumbs: scrub the url data field if present.
    final data = breadcrumb.data;
    if (data != null && data.isNotEmpty) {
      final scrubbed = <String, dynamic>{};
      data.forEach((k, v) {
        if (_piiExtraKeys.contains(k.toLowerCase())) return;
        if (k == 'url' && v is String) {
          scrubbed[k] = _stripQuery(v);
        } else if (v is String && looksLikePii(v)) {
          // Skip — value smells like content.
        } else {
          scrubbed[k] = v;
        }
      });
      return breadcrumb.copyWith(data: scrubbed);
    }
    return breadcrumb;
  }

  /// Heuristic: does this string look like it contains PII?
  /// Conservative — false positives drop events; we'd rather lose noise
  /// than leak privileged content.
  static bool looksLikePii(String s) {
    if (s.isEmpty) return false;
    // Long free-text is suspicious (chat / vault excerpts).
    if (s.length > 500) return true;
    // Email-shape.
    if (RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+').hasMatch(s)) return true;
    // Finnish henkilötunnus (DDMMYY[+-A]NNNX).
    if (RegExp(r'\b\d{6}[+\-ABCDEFYXWVU]\d{3}[\dA-Z]\b').hasMatch(s)) {
      return true;
    }
    // Estonian isikukood (11 digits starting 3-6).
    if (RegExp(r'\b[3-6]\d{10}\b').hasMatch(s)) return true;
    // Generic case-number shape (e.g. R 25/1234, 5500/R/75170/25).
    if (RegExp(r'\b\d{3,5}/[A-Z]/\d{3,6}/\d{2}\b').hasMatch(s)) return true;
    // Card-like 13-19 digit run, allowing space/dash separators.
    if (RegExp(r'\b(?:\d[ -]?){13,19}\b').hasMatch(s)) return true;
    // Bearer / JWT token.
    if (RegExp(r'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}').hasMatch(s)) {
      return true;
    }
    return false;
  }

  /// Stable, non-reversible 8-hex-char digest of a user id. Returns
  /// 'anon' for null / empty input.
  static String hashedUserId(String? id) {
    if (id == null || id.isEmpty) return 'anon';
    final digest = sha256.convert(utf8.encode(id));
    return digest.toString().substring(0, 8);
  }

  /// Returns a copy of [extras] with PII-looking keys removed and
  /// PII-looking string values replaced by '[scrubbed]'.
  static Map<String, dynamic> _scrubExtras(Map<String, dynamic> extras) {
    final out = <String, dynamic>{};
    extras.forEach((k, v) {
      if (_piiExtraKeys.contains(k.toLowerCase())) return;
      if (v is String) {
        if (looksLikePii(v)) {
          out[k] = '[scrubbed]';
        } else {
          out[k] = v;
        }
      } else if (v is Map) {
        out[k] = _scrubExtras(Map<String, dynamic>.from(v));
      } else {
        out[k] = v;
      }
    });
    return out;
  }

  /// Removes query parameters from a URL string. Path + host kept.
  static String? _stripQuery(String? url) {
    if (url == null || url.isEmpty) return url;
    try {
      final u = Uri.parse(url);
      return u.replace(query: '', fragment: '').toString();
    } catch (_) {
      return url;
    }
  }

  /// Returns the runtime platform tag used as a Sentry `tag`.
  static String get platformTag {
    if (kIsWeb) return 'web';
    return 'native';
  }
}
