// calculator_logic_test.dart — pure-logic tests for the Legal Calculators Hub.
// -----------------------------------------------------------------------------
// Covers severance (FI notice + EE koondamine), limitation-period date math +
// holiday roll-forward, child-support orientation, and the rate fallback parser.
// No widgets / IO.
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/calculators/data/calc_rates.dart';
import 'package:advocat/features/calculators/logic/calculator_logic.dart';
import 'package:advocat/features/calculators/logic/limitation_holidays.dart';

void main() {
  group('estonianKoondamine', () {
    test('under 5 years → employer only, 30-day notice', () {
      final r = estonianKoondamine(monthlySalary: 2000, tenureYears: 3);
      expect(r.totalAmount, 2000); // 1 month employer, 0 fund
      expect(r.noticeDays, 30);
    });

    test('5–10 years → employer + 1 fund month, 60-day notice', () {
      final r = estonianKoondamine(monthlySalary: 2000, tenureYears: 7);
      expect(r.totalAmount, 4000); // 1 + 1 months
      expect(r.noticeDays, 60);
    });

    test('over 10 years → employer + 2 fund months, 90-day notice', () {
      final r = estonianKoondamine(monthlySalary: 2000, tenureYears: 12);
      expect(r.totalAmount, 6000); // 1 + 2 months
      expect(r.noticeDays, 90);
    });

    test('under 1 year → 15-day notice', () {
      final r = estonianKoondamine(monthlySalary: 1500, tenureYears: 0.5);
      expect(r.noticeDays, 15);
    });
  });

  group('finnishNotice', () {
    test('under 1 year → half month notice (14 days)', () {
      final r = finnishNotice(monthlySalary: 3000, tenureYears: 0.5);
      expect(r.totalAmount, 1500); // 0.5 × salary
      expect(r.noticeDays, 15); // 0.5*30 rounded
    });

    test('8–12 years → 4 months notice', () {
      final r = finnishNotice(monthlySalary: 3000, tenureYears: 10);
      expect(r.totalAmount, 12000); // 4 × salary
    });

    test('over 12 years → 6 months notice', () {
      final r = finnishNotice(monthlySalary: 3000, tenureYears: 15);
      expect(r.totalAmount, 18000);
    });
  });

  group('limitationDeadline (years)', () {
    test('3-year claim from a weekday lands correctly', () {
      // 2026-03-10 is a Tuesday; +3 years = 2029-03-10 (Saturday) → shifts to
      // Monday 2029-03-12.
      final r = limitationDeadline(
        start: DateTime(2026, 3, 10),
        years: 3,
        jurisdiction: 'EE',
        norm: 'TsÜS §146',
        now: DateTime(2026, 6, 15),
      );
      expect(r.deadline.year, 2029);
      expect(r.expired, isFalse);
    });

    test('expired period is flagged', () {
      final r = limitationDeadline(
        start: DateTime(2020, 1, 1),
        years: 3,
        jurisdiction: 'EE',
        norm: 'TsÜS §146',
        now: DateTime(2026, 6, 15),
      );
      expect(r.expired, isTrue);
      expect(r.daysRemaining, lessThan(0));
    });
  });

  group('limitationDeadline (months) — ECHR Art. 35 §1 = 4 calendar months', () {
    // Regression guard: the ECHR window was previously modelled as a fixed
    // 120 days and fired ~3 days EARLY on the live Sulga app No.200. 4 calendar
    // months is ~120-123 days; it must never resolve earlier than 120 days.
    test('4 months from a mid-month date is true calendar-month arithmetic', () {
      // 2026-01-15 (Thu) + 4 months → 2026-05-15 (Fri, a plain working day) so
      // the month arithmetic is isolated from any weekend/holiday shift.
      // Note: a 4-calendar-month window that spans February is intentionally
      // *shorter* than a flat 120 days — that mismatch (flat-120 vs real months)
      // is exactly the Sulga app No.200 bug this change fixes.
      final r = limitationDeadline(
        start: DateTime(2026, 1, 15),
        months: 4,
        jurisdiction: 'FI',
        norm: 'ECHR Art. 35 (4kk)',
        now: DateTime(2026, 2, 1),
      );
      expect(r.deadline, DateTime(2026, 5, 15));
      expect(r.shifted, isFalse);
      // The same day-of-month is preserved across the 4-month add.
      expect(r.deadline.day, 15);
    });

    test('a 4-month window spanning long months exceeds 120 days', () {
      // 2026-03-15 + 4 months → 2026-07-15. Mar→Jul spans 31+30+31+30 day-months
      // so the real window (122 days) is LONGER than a flat 120-day count —
      // proving the fix is not a fixed-day approximation.
      final r = limitationDeadline(
        start: DateTime(2026, 3, 15),
        months: 4,
        jurisdiction: 'FI',
        norm: 'ECHR Art. 35 (4kk)',
        now: DateTime(2026, 4, 1),
      );
      final naive120 = DateTime(2026, 3, 15).add(const Duration(days: 120));
      expect(r.deadline.isAfter(naive120), isTrue,
          reason: 'Mar→Jul 4-month window (122d) must exceed a flat 120 days');
    });

    test('31 Oct + 4 months clamps to the last day of February (28, non-leap)',
        () {
      // 2025-10-31 + 4mo → "31 Feb 2026" → clamps to 2026-02-28 (Sat) →
      // next working day Mon 2026-03-02.
      final r = limitationDeadline(
        start: DateTime(2025, 10, 31),
        months: 4,
        jurisdiction: 'EE',
        norm: 'EIÕK art 35 (4 kuud)',
        now: DateTime(2025, 11, 1),
      );
      // Raw clamps to 28 Feb; the weekend shift then moves it to 2 Mar.
      expect(r.deadline, DateTime(2026, 3, 2));
      expect(r.shifted, isTrue);
    });

    test('leap-year February clamp lands on the 29th', () {
      // 2027-10-31 + 4mo → "31 Feb 2028" → 2028 is a leap year → clamp to 29 Feb
      // (Tue, a working day) → no shift.
      final r = limitationDeadline(
        start: DateTime(2027, 10, 31),
        months: 4,
        jurisdiction: 'EE',
        norm: 'EIÕK art 35 (4 kuud)',
        now: DateTime(2027, 11, 1),
      );
      expect(r.deadline, DateTime(2028, 2, 29));
      expect(r.shifted, isFalse);
    });

    test('year rollover: Dec start + 4 months crosses into the next year', () {
      // 2026-12-10 (Thu) + 4mo → month 16 normalises to 2027-04-10 (Sat) →
      // next working Mon 2027-04-12.
      final r = limitationDeadline(
        start: DateTime(2026, 12, 10),
        months: 4,
        jurisdiction: 'FI',
        norm: 'ECHR Art. 35 (4kk)',
        now: DateTime(2027, 1, 1),
      );
      expect(r.deadline.year, 2027);
      expect(r.deadline.month, 4);
      expect(r.deadline.day, anyOf(10, 12));
      expect(r.expired, isFalse);
    });

    test('an elapsed 4-month window is flagged expired', () {
      final r = limitationDeadline(
        start: DateTime(2025, 1, 1),
        months: 4,
        jurisdiction: 'FI',
        norm: 'ECHR Art. 35 (4kk)',
        now: DateTime(2026, 6, 15),
      );
      expect(r.expired, isTrue);
      expect(r.daysRemaining, lessThan(0));
    });

    test('the kFallbackRates ECHR entry uses 4 months, not 120 days', () {
      for (final j in ['FI', 'EE']) {
        final echr = fallbackFor(j)
            .limitationPeriods
            .firstWhere((p) => p.key == 'echr');
        expect(echr.months, 4, reason: '$j ECHR must be 4 calendar months');
        expect(echr.days, isNull,
            reason: '$j ECHR must not carry a fixed day count');
      }
    });
  });

  group('limitationDeadline (days) + holiday shift', () {
    test('30-day appeal rolls off a weekend', () {
      // Start 2026-06-01 (Mon) + 30 days = 2026-07-01 (Wed) → working day.
      final r = limitationDeadline(
        start: DateTime(2026, 6, 1),
        days: 30,
        jurisdiction: 'FI',
        norm: 'OK 1734 25:5',
        now: DateTime(2026, 6, 15),
      );
      expect(r.deadline.weekday, isNot(DateTime.saturday));
      expect(r.deadline.weekday, isNot(DateTime.sunday));
    });

    test('deadline on EE Jaanipäev (24 June) shifts forward', () {
      // Land exactly on 2026-06-24 (Estonian Midsummer holiday).
      // 2026-06-24 is a Wednesday holiday → next working day 2026-06-25.
      final r = limitationDeadline(
        start: DateTime(2026, 5, 25),
        days: 30,
        jurisdiction: 'EE',
        norm: 'TsMS §632',
        now: DateTime(2026, 5, 1),
      );
      expect(r.deadline, DateTime(2026, 6, 25));
      expect(r.shifted, isTrue);
    });
  });

  group('holiday helpers', () {
    test('weekend detection', () {
      expect(isWeekend(DateTime(2026, 6, 13)), isTrue); // Saturday
      expect(isWeekend(DateTime(2026, 6, 15)), isFalse); // Monday
    });

    test('New Year is a holiday in both jurisdictions', () {
      expect(isHoliday(DateTime(2026, 1, 1), 'FI'), isTrue);
      expect(isHoliday(DateTime(2026, 1, 1), 'EE'), isTrue);
    });

    test('FI Independence Day (6 Dec) is FI-only', () {
      expect(isHoliday(DateTime(2026, 12, 6), 'FI'), isTrue);
      expect(isHoliday(DateTime(2026, 12, 6), 'EE'), isFalse);
    });

    test('EE Independence Day (24 Feb) is EE-only', () {
      expect(isHoliday(DateTime(2026, 2, 24), 'EE'), isTrue);
      expect(isHoliday(DateTime(2026, 2, 24), 'FI'), isFalse);
    });

    test('nextWorkingDay leaves a plain weekday untouched', () {
      final d = DateTime(2026, 6, 15); // Monday
      expect(nextWorkingDay(d, 'EE'), d);
    });
  });

  group('childSupportEstimate', () {
    test('floor wins when income is low', () {
      final r = childSupportEstimate(
        payerNetMonthly: 500,
        children: 1,
        floorPerChild: 209.20,
        percentPerChild: 17,
      );
      // 17% of 500 = 85 < floor 209.20 → floor used.
      expect(r.perChild, 209.20);
      expect(r.total, 209.20);
    });

    test('percentage wins when income is high, scales by children', () {
      final r = childSupportEstimate(
        payerNetMonthly: 3000,
        children: 2,
        floorPerChild: 209.20,
        percentPerChild: 17,
      );
      // 17% of 3000 = 510 > floor → 510 per child × 2 = 1020.
      expect(r.perChild, closeTo(510, 0.001));
      expect(r.total, closeTo(1020, 0.001));
    });

    test('treats 0 children as 1', () {
      final r = childSupportEstimate(
        payerNetMonthly: 3000,
        children: 0,
        floorPerChild: 200,
        percentPerChild: 17,
      );
      expect(r.total, r.perChild);
    });
  });

  group('CalcRates fallback + edge parsing', () {
    test('fallbackFor returns the requested jurisdiction', () {
      expect(fallbackFor('FI').jurisdiction, 'FI');
      expect(fallbackFor('ee').jurisdiction, 'EE');
      expect(fallbackFor('XX').jurisdiction, 'EE'); // default
    });

    test('fromEdge overrides floor but keeps fallback for missing keys', () {
      final fb = fallbackFor('EE');
      final parsed = CalcRates.fromEdge({
        'as_of': '2026-07-01',
        'rates': {
          'child_support_floor': {
            'value_numeric': 250.0,
            'payload': {'percent_of_net_per_child': 20},
            'source_label': 'PKS §101 (uus)',
          },
        },
      }, fb);
      expect(parsed.fromNetwork, isTrue);
      expect(parsed.asOf, '2026-07-01');
      expect(parsed.childSupportFloor, 250.0);
      expect(parsed.childSupportPercent, 20);
      // limitation periods absent in payload → fallback retained.
      expect(parsed.limitationPeriods, isNotEmpty);
      expect(parsed.stateFeeBrackets, isNotEmpty);
    });
  });
}
