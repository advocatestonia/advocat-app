// =====================================================================
// safe_launch.dart — hardened wrapper around url_launcher's launchUrl().
//
// Security context — F5 / F8 (WAVE 1, 2026-05-28).
// =====================================================================
//
// Why this exists
// ---------------
// Several call sites in the chat / email / support flows hand a Uri to
// `launchUrl(uri)` whose host/scheme/body is produced by either:
//   * the LLM (chat tool calls — `draft_email`, `send_email` fallback),
//   * remote support config (Telegram handle, WhatsApp number),
//   * unsanitised user/markdown input rendered into a "tap to email" link.
//
// Because the LLM is steerable by prompt injection (a poisoned PDF can
// instruct it to draft a `mailto:victim,bcc:attacker@evil.com?...` link)
// and because remote config can change without a release, every
// `launchUrl` call must:
//   1. confirm the scheme is in a small allowlist (https / mailto / tel),
//   2. reject `mailto:` payloads with header-injection markers
//      (comma list, CR/LF, `bcc:` / `cc:` in the *to* field — RFC-5322
//      smuggling attacks),
//   3. confirm `canLaunchUrl()` — avoids the "Could not open link" snack
//      that leaks the raw URL into the UI.
//
// This file is the single dedupe point for those checks. Call sites should
// migrate from bare `launchUrl(uri)` to `safeLaunchUrl(uri, ...)`.

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:url_launcher/url_launcher.dart';

/// Allowed schemes for outgoing launches. Anything else is rejected.
///
/// Notably absent: `http` (we force https), `javascript:` (XSS), `file:`,
/// `intent:`, `whatsapp:`, `tg:` (we use https://t.me + https://wa.me
/// instead so the allowlist stays tiny).
const Set<String> _kAllowedSchemes = <String>{'https', 'mailto', 'tel'};

/// CRLF + header-injection markers in the `to` portion of a mailto: URI.
/// Any of these characters in the address means an attacker is trying to
/// smuggle Cc/Bcc/Subject headers via the address itself.
final RegExp _kMailtoToInvalidChars = RegExp(r'[,;\r\n]');

/// Substrings that are header-injection signals inside the *to* field.
/// We check case-insensitively because some mail clients normalise
/// header names before parsing.
const List<String> _kMailtoHeaderInjectionMarkers = <String>[
  'bcc:',
  'cc:',
  'to:',
];

/// Result of a [safeLaunchUrl] call. Mirrors `launchUrl`'s `Future<bool>`
/// return but also surfaces whether the rejection was due to the security
/// guard rather than a missing handler.
class SafeLaunchResult {
  const SafeLaunchResult({
    required this.launched,
    this.blockedReason,
  });

  /// True iff `launchUrl` returned true.
  final bool launched;

  /// Non-null when the launch was blocked by [safeLaunchUrl] before
  /// even calling `launchUrl`. Useful for tests and for surfacing a
  /// user-visible "this link looks unsafe" message instead of the
  /// platform "no app could open this link" sheet.
  final String? blockedReason;

  bool get wasBlocked => blockedReason != null;
}

/// Validate [uri] against the security allowlist and launch it via
/// `url_launcher` only if everything checks out.
///
/// Behaviour:
///   * Rejects any scheme not in [_kAllowedSchemes].
///   * For `mailto:`, rejects header-injection patterns in the `to`
///     portion (comma-list, CRLF, `bcc:` / `cc:` substrings — these
///     are the attack surface for LLM-driven prompt injection).
///   * Calls `canLaunchUrl(uri)` before `launchUrl(uri)` so a missing
///     handler doesn't bubble up a snack with the raw URL.
///   * On any caught exception, returns a non-launched [SafeLaunchResult]
///     — this helper NEVER throws to the caller.
///
/// [mode] is forwarded to `launchUrl`. Defaults to
/// `LaunchMode.platformDefault` (the same default `launchUrl` uses).
Future<SafeLaunchResult> safeLaunchUrl(
  Uri uri, {
  LaunchMode mode = LaunchMode.platformDefault,
}) async {
  // 1. Scheme allowlist.
  final scheme = uri.scheme.toLowerCase();
  if (!_kAllowedSchemes.contains(scheme)) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[safe_launch] blocked scheme="$scheme"');
    }
    return SafeLaunchResult(
      launched: false,
      blockedReason: 'disallowed_scheme:$scheme',
    );
  }

  // 2. mailto-specific header-injection guard.
  if (scheme == 'mailto') {
    final to = uri.path; // mailto:foo@bar — `to` is in path
    if (to.isNotEmpty) {
      if (_kMailtoToInvalidChars.hasMatch(to)) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('[safe_launch] blocked mailto: invalid char in to="$to"');
        }
        return const SafeLaunchResult(
          launched: false,
          blockedReason: 'mailto_invalid_to_char',
        );
      }
      final lowered = to.toLowerCase();
      for (final marker in _kMailtoHeaderInjectionMarkers) {
        if (lowered.contains(marker)) {
          if (kDebugMode) {
            // ignore: avoid_print
            print('[safe_launch] blocked mailto: header marker "$marker"');
          }
          return SafeLaunchResult(
            launched: false,
            blockedReason: 'mailto_header_injection:$marker',
          );
        }
      }
    }
  }

  // 3. canLaunchUrl guard.
  try {
    final canLaunch = await canLaunchUrl(uri);
    if (!canLaunch) {
      return const SafeLaunchResult(
        launched: false,
        blockedReason: 'no_handler',
      );
    }
  } catch (e) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[safe_launch] canLaunchUrl threw: $e');
    }
    return const SafeLaunchResult(
      launched: false,
      blockedReason: 'can_launch_threw',
    );
  }

  // 4. Actual launch.
  try {
    final ok = await launchUrl(uri, mode: mode);
    return SafeLaunchResult(launched: ok);
  } catch (e) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[safe_launch] launchUrl threw: $e');
    }
    return const SafeLaunchResult(
      launched: false,
      blockedReason: 'launch_threw',
    );
  }
}

/// Visible-for-testing helper. Returns true iff [uri] would pass the
/// security guard (scheme allowlist + mailto header-injection check).
/// Does NOT call `canLaunchUrl` — useful for unit tests that don't have
/// a url_launcher binding.
bool isUriSafeForLaunch(Uri uri) {
  final scheme = uri.scheme.toLowerCase();
  if (!_kAllowedSchemes.contains(scheme)) return false;
  if (scheme == 'mailto') {
    final to = uri.path;
    if (to.isEmpty) return true; // mailto:?subject=... is OK
    if (_kMailtoToInvalidChars.hasMatch(to)) return false;
    final lowered = to.toLowerCase();
    for (final marker in _kMailtoHeaderInjectionMarkers) {
      if (lowered.contains(marker)) return false;
    }
  }
  return true;
}
