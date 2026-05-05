// =============================================================================
// ics_export_service.dart — RFC 5545 .ics calendar export.
// -----------------------------------------------------------------------------
// Pure-Dart, zero-dependency. Renders a single VEVENT inside a VCALENDAR
// envelope so the output can be imported by Google Calendar, Outlook,
// Apple Calendar, Yandex.Calendar, and any other RFC-5545-compliant client.
//
// Why hand-rolled (no `add_2_calendar` package):
//   * The package is mobile-only (Android intents / iOS EKEventStore) and
//     does not help on the web target — yet web is where most paying
//     Advocat users live.
//   * Generating an .ics blob is portable: same bytes work as a download
//     on web, an attachment on email, and a share-sheet payload on mobile.
//   * RFC 5545 §3.6.1 (VEVENT) is ~80 lines of string assembly.
//
// Caller wires the bytes into the platform's native share/download seam
// (see CaseFileScreen → calendar icon button).
// =============================================================================

import 'dart:convert';

class IcsExportService {
  IcsExportService._();

  /// PRODID — registered identifier for the producing application.
  /// RFC 5545 §3.7.3 — required, free-form, recommended to use a globally
  /// unique value derived from a domain we control.
  static const String _prodId = '-//Advocat//advocat.ee//EN';

  /// All multi-line .ics content uses CRLF per RFC 5545 §3.1.
  static const String _crlf = '\r\n';

  /// Renders a single calendar event as a complete .ics file body.
  ///
  /// [title]         — VEVENT SUMMARY (required).
  /// [startDate]     — VEVENT DTSTART. If [allDay] is true the local-date
  ///                   form is used; otherwise the UTC date-time form is
  ///                   emitted (so the receiver doesn't have to know our
  ///                   timezone).
  /// [endDate]       — Optional VEVENT DTEND. Defaults to start + 1h for
  ///                   timed events, or start + 1 day (exclusive) for
  ///                   all-day events.
  /// [description]   — Optional VEVENT DESCRIPTION. Newlines/specials are
  ///                   escaped per RFC 5545 §3.3.11.
  /// [location]      — Optional VEVENT LOCATION.
  /// [allDay]        — If true, use VALUE=DATE form (no time-of-day).
  ///
  /// Returns a CRLF-delimited string suitable for writing to a `.ics` file
  /// or for serving with `Content-Type: text/calendar`.
  static String renderEvent({
    required String title,
    required DateTime startDate,
    DateTime? endDate,
    String? description,
    String? location,
    bool allDay = false,
  }) {
    final dtStart = allDay
        ? _formatDate(startDate)
        : _formatDateTimeUtc(startDate);
    final dtEnd = allDay
        ? _formatDate(
            (endDate ?? startDate.add(const Duration(days: 1))),
          )
        : _formatDateTimeUtc(
            endDate ?? startDate.add(const Duration(hours: 1)),
          );

    final dtStartLine = allDay
        ? 'DTSTART;VALUE=DATE:$dtStart'
        : 'DTSTART:$dtStart';
    final dtEndLine = allDay
        ? 'DTEND;VALUE=DATE:$dtEnd'
        : 'DTEND:$dtEnd';

    // DTSTAMP is required (RFC 5545 §3.8.7.2). Use the same timestamp as
    // the event creation moment — for our deterministic-UID model the
    // exact value doesn't matter, but it must be present and well-formed.
    final dtStamp = _formatDateTimeUtc(DateTime.now().toUtc());

    final uid = _stableUid(title: title, startDate: startDate);

    final lines = <String>[
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:$_prodId',
      'CALSCALE:GREGORIAN',
      'METHOD:PUBLISH',
      'BEGIN:VEVENT',
      'UID:$uid',
      'DTSTAMP:$dtStamp',
      dtStartLine,
      dtEndLine,
      'SUMMARY:${_escapeText(title)}',
      if (description != null && description.isNotEmpty)
        'DESCRIPTION:${_escapeText(description)}',
      if (location != null && location.isNotEmpty)
        'LOCATION:${_escapeText(location)}',
      'END:VEVENT',
      'END:VCALENDAR',
    ];

    // Trailing CRLF so the file ends cleanly per RFC 5545 §3.1.
    return '${lines.join(_crlf)}$_crlf';
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// `YYYYMMDD` form, used with `VALUE=DATE` for all-day events.
  static String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y$m$day';
  }

  /// `YYYYMMDDTHHMMSSZ` form (UTC), used for timed events.
  static String _formatDateTimeUtc(DateTime dt) {
    final u = dt.toUtc();
    final y = u.year.toString().padLeft(4, '0');
    final m = u.month.toString().padLeft(2, '0');
    final d = u.day.toString().padLeft(2, '0');
    final hh = u.hour.toString().padLeft(2, '0');
    final mm = u.minute.toString().padLeft(2, '0');
    final ss = u.second.toString().padLeft(2, '0');
    return '$y$m${d}T$hh$mm${ss}Z';
  }

  /// RFC 5545 §3.3.11 TEXT escaping: backslash, semicolon, comma, newline.
  /// The order matters: escape backslashes FIRST so we don't double-escape
  /// the backslashes that we then introduce for the other characters.
  static String _escapeText(String input) {
    return input
        .replaceAll(r'\', r'\\')
        .replaceAll(';', r'\;')
        .replaceAll(',', r'\,')
        .replaceAll('\r\n', r'\n')
        .replaceAll('\n', r'\n')
        .replaceAll('\r', r'\n');
  }

  /// Stable UID — same `(title|startDate)` always yields the same UID, so
  /// re-importing the same .ics into a calendar updates the existing event
  /// instead of creating a duplicate. Domain suffix is required by RFC
  /// 5545 §3.8.4.7.
  static String _stableUid({
    required String title,
    required DateTime startDate,
  }) {
    final key =
        '${startDate.toIso8601String()}|${title.trim().toLowerCase()}';
    final digest = _fnv1a64Hex(key);
    return 'advocat-$digest@advocat.ee';
  }

  /// 64-bit FNV-1a hash → 16-char lowercase hex. We avoid pulling in
  /// `crypto` for SHA-1 because (a) the UID doesn't need cryptographic
  /// strength — just stable uniqueness — and (b) keeping this file
  /// dependency-free lets it be reused on any platform target.
  static String _fnv1a64Hex(String input) {
    // FNV-1a 64-bit constants.
    const int offsetHi = 0xCBF29CE4;
    const int offsetLo = 0x84222325;
    const int primeHi = 0x00000100;
    const int primeLo = 0x000001B3;

    int hi = offsetHi;
    int lo = offsetLo;

    final bytes = utf8.encode(input);
    for (final b in bytes) {
      // hash ^= byte
      lo ^= b;

      // hash *= FNV_prime  (64-bit multiply, split into two 32-bit halves)
      final newLo = (lo * primeLo) & 0xFFFFFFFF;
      final carry = (lo * primeLo) >> 32;
      final newHi = ((hi * primeLo) + (lo * primeHi) + carry) & 0xFFFFFFFF;

      hi = newHi;
      lo = newLo;
    }

    final hiHex = hi.toRadixString(16).padLeft(8, '0');
    final loHex = lo.toRadixString(16).padLeft(8, '0');
    return '$hiHex$loHex';
  }
}
