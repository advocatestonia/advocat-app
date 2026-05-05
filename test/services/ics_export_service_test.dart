@Tags(['fast'])
library;

// =============================================================================
// ics_export_service_test.dart — RFC 5545 calendar export contract tests.
// -----------------------------------------------------------------------------
// Pure unit tests. No IO. No Flutter widgets. The IcsExportService.renderEvent
// function must produce a valid VCALENDAR/VEVENT envelope that any major
// calendar app (Google, Outlook, Apple, Yandex) can import.
// =============================================================================

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/ics_export_service.dart';

void main() {
  group('IcsExportService.renderEvent — RFC 5545 envelope', () {
    test('renders required VCALENDAR/VEVENT skeleton', () {
      final ics = IcsExportService.renderEvent(
        title: 'Vaie esitamise tähtaeg',
        startDate: DateTime.utc(2026, 6, 15, 9, 0, 0),
      );

      expect(ics, contains('BEGIN:VCALENDAR'));
      expect(ics, contains('END:VCALENDAR'));
      expect(ics, contains('BEGIN:VEVENT'));
      expect(ics, contains('END:VEVENT'));
      expect(ics, contains('VERSION:2.0'));
      expect(ics, contains('PRODID:-//Advocat//advocat.ee//EN'));
      expect(ics, contains('DTSTART'));
      expect(ics, contains('DTEND'));
      expect(ics, contains('SUMMARY:'));
      expect(ics, contains('UID:'));
    });

    test('uses CRLF line endings (RFC 5545 §3.1)', () {
      final ics = IcsExportService.renderEvent(
        title: 'X',
        startDate: DateTime.utc(2026, 6, 15),
      );
      // Every newline in an RFC 5545 stream is CRLF, never bare LF.
      // Permit a final trailing CRLF but no bare LFs.
      final lfCount = '\n'.allMatches(ics).length;
      final crlfCount = '\r\n'.allMatches(ics).length;
      expect(lfCount, equals(crlfCount),
          reason: 'every \\n must be preceded by \\r');
    });

    test('BEGIN/END pairs balance', () {
      final ics = IcsExportService.renderEvent(
        title: 'Vaie',
        startDate: DateTime.utc(2026, 6, 15),
      );
      expect('BEGIN:VCALENDAR'.allMatches(ics).length, 1);
      expect('END:VCALENDAR'.allMatches(ics).length, 1);
      expect('BEGIN:VEVENT'.allMatches(ics).length, 1);
      expect('END:VEVENT'.allMatches(ics).length, 1);
    });
  });

  group('IcsExportService.renderEvent — date formats', () {
    test('all-day event emits DTSTART;VALUE=DATE: with YYYYMMDD', () {
      final ics = IcsExportService.renderEvent(
        title: 'Vaie esitamise tähtaeg',
        startDate: DateTime(2026, 6, 15),
        allDay: true,
      );
      expect(ics, contains('DTSTART;VALUE=DATE:20260615'));
      // All-day DTEND is exclusive — next day per RFC 5545.
      expect(ics, contains('DTEND;VALUE=DATE:20260616'));
      // No bare DTSTART:YYYYMMDDTHHMMSSZ for an all-day event.
      expect(ics, isNot(contains('DTSTART:20260615T')));
    });

    test('timed event emits DTSTART:YYYYMMDDTHHMMSSZ form', () {
      final ics = IcsExportService.renderEvent(
        title: 'Hearing',
        startDate: DateTime.utc(2026, 6, 15, 9, 30, 0),
        endDate: DateTime.utc(2026, 6, 15, 10, 30, 0),
      );
      expect(ics, contains('DTSTART:20260615T093000Z'));
      expect(ics, contains('DTEND:20260615T103000Z'));
    });

    test('timed event without endDate defaults to 1-hour duration', () {
      final ics = IcsExportService.renderEvent(
        title: 'Hearing',
        startDate: DateTime.utc(2026, 6, 15, 9, 0, 0),
      );
      expect(ics, contains('DTSTART:20260615T090000Z'));
      expect(ics, contains('DTEND:20260615T100000Z'));
    });
  });

  group('IcsExportService.renderEvent — UID stability', () {
    test('same title + start → same UID (idempotent across re-export)', () {
      final a = IcsExportService.renderEvent(
        title: 'Vaie',
        startDate: DateTime(2026, 6, 15),
        allDay: true,
      );
      final b = IcsExportService.renderEvent(
        title: 'Vaie',
        startDate: DateTime(2026, 6, 15),
        allDay: true,
      );
      final uidA = RegExp(r'UID:([^\r\n]+)').firstMatch(a)?.group(1);
      final uidB = RegExp(r'UID:([^\r\n]+)').firstMatch(b)?.group(1);
      expect(uidA, isNotNull);
      expect(uidA, equals(uidB));
    });

    test('different title → different UID', () {
      final a = IcsExportService.renderEvent(
        title: 'Vaie',
        startDate: DateTime(2026, 6, 15),
        allDay: true,
      );
      final b = IcsExportService.renderEvent(
        title: 'Hearing',
        startDate: DateTime(2026, 6, 15),
        allDay: true,
      );
      final uidA = RegExp(r'UID:([^\r\n]+)').firstMatch(a)?.group(1);
      final uidB = RegExp(r'UID:([^\r\n]+)').firstMatch(b)?.group(1);
      expect(uidA, isNot(equals(uidB)));
    });

    test('UID has @advocat.ee domain suffix', () {
      final ics = IcsExportService.renderEvent(
        title: 'X',
        startDate: DateTime.utc(2026, 6, 15),
      );
      final uid = RegExp(r'UID:([^\r\n]+)').firstMatch(ics)?.group(1);
      expect(uid, isNotNull);
      expect(uid, endsWith('@advocat.ee'));
    });
  });

  group('IcsExportService.renderEvent — text escaping (RFC 5545 §3.3.11)', () {
    test('commas in summary are escaped', () {
      final ics = IcsExportService.renderEvent(
        title: 'Hearing, Tallinn',
        startDate: DateTime.utc(2026, 6, 15),
      );
      expect(ics, contains(r'SUMMARY:Hearing\, Tallinn'));
    });

    test('semicolons in summary are escaped', () {
      final ics = IcsExportService.renderEvent(
        title: 'Vaie; HMS § 75',
        startDate: DateTime.utc(2026, 6, 15),
      );
      expect(ics, contains(r'SUMMARY:Vaie\; HMS § 75'));
    });

    test('newlines in description become literal \\n', () {
      final ics = IcsExportService.renderEvent(
        title: 'X',
        startDate: DateTime.utc(2026, 6, 15),
        description: 'Line 1\nLine 2',
      );
      expect(ics, contains(r'DESCRIPTION:Line 1\nLine 2'));
      // The literal raw \n character must NOT appear inside the
      // DESCRIPTION value (the \n must be escaped).
      // We extract the DESCRIPTION line and assert.
      final descLine = ics
          .split('\r\n')
          .firstWhere((l) => l.startsWith('DESCRIPTION:'),
              orElse: () => '');
      expect(descLine, isNot(contains('\n')));
    });

    test('backslash in description is escaped', () {
      final ics = IcsExportService.renderEvent(
        title: 'X',
        startDate: DateTime.utc(2026, 6, 15),
        description: r'path\to\file',
      );
      expect(ics, contains(r'DESCRIPTION:path\\to\\file'));
    });
  });

  group('IcsExportService.renderEvent — optional fields', () {
    test('omits DESCRIPTION when not provided', () {
      final ics = IcsExportService.renderEvent(
        title: 'X',
        startDate: DateTime.utc(2026, 6, 15),
      );
      expect(ics, isNot(contains('DESCRIPTION:')));
    });

    test('emits DESCRIPTION when provided with law citation', () {
      final ics = IcsExportService.renderEvent(
        title: 'Vaie esitamise tähtaeg',
        startDate: DateTime.utc(2026, 6, 15),
        description: 'HMS § 75 lg 1 — open in Advocat: '
            'https://advocat.ee/case-file',
      );
      expect(ics, contains('DESCRIPTION:HMS § 75 lg 1'));
      expect(ics, contains(r'https://advocat.ee/case-file'));
    });

    test('emits LOCATION when provided', () {
      final ics = IcsExportService.renderEvent(
        title: 'Hearing',
        startDate: DateTime.utc(2026, 6, 15, 10, 0, 0),
        location: 'Tartu Maakohus, Kalevi 1',
      );
      expect(ics, contains('LOCATION:Tartu Maakohus'));
    });

    test('omits LOCATION when not provided', () {
      final ics = IcsExportService.renderEvent(
        title: 'X',
        startDate: DateTime.utc(2026, 6, 15),
      );
      expect(ics, isNot(contains('LOCATION:')));
    });
  });

  group('IcsExportService.renderEvent — Sulga-style fixture', () {
    test('renders a real Estonian deadline correctly', () {
      // The case-file flow auto-extracts: PPA decision received 2026-04-12,
      // 30-day appeal window per HMS § 75 lg 1 → deadline 2026-05-12.
      final ics = IcsExportService.renderEvent(
        title: 'Vaie esitamise tähtaeg',
        startDate: DateTime(2026, 5, 12),
        allDay: true,
        description: 'Vaie esitamise tähtaeg — HMS § 75 lg 1\n'
            'Avaa Advocat: https://advocat.ee/case-file',
      );
      expect(ics, contains('SUMMARY:Vaie esitamise tähtaeg'));
      expect(ics, contains('DTSTART;VALUE=DATE:20260512'));
      expect(ics, contains('DTEND;VALUE=DATE:20260513'));
      expect(ics, contains(r'DESCRIPTION:Vaie esitamise tähtaeg — HMS § 75 lg 1\n'));
      expect(ics, contains('PRODID:-//Advocat//advocat.ee//EN'));
    });
  });
}
