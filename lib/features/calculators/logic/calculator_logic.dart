// calculator_logic.dart — pure, side-effect-free legal calculation functions.
// -----------------------------------------------------------------------------
// These are deliberately UI- and IO-free so they can be unit-tested in
// isolation and reused by any screen. They consume already-resolved rate inputs
// (see CalcRates / rate models) and return structured results that carry both
// the number AND the formula breakdown + the cited norm, so the UI can show its
// working. NONE of these are "official calculations" — the screens wrap every
// result in an indicative-only disclaimer.
// -----------------------------------------------------------------------------

import 'limitation_holidays.dart';

/// Result of a severance / notice estimate.
class SeveranceResult {
  /// Estimated total payout in the jurisdiction currency.
  final double totalAmount;

  /// Notice period expressed in days (FI/EE notice clocks differ; we normalise
  /// to days for display, plus a human label).
  final int noticeDays;

  /// Human-readable label of the notice period (e.g. "2 kuukautta", "30 päeva").
  final String noticeLabel;

  /// Ordered breakdown lines explaining each component of [totalAmount].
  final List<String> breakdown;

  const SeveranceResult({
    required this.totalAmount,
    required this.noticeDays,
    required this.noticeLabel,
    required this.breakdown,
  });
}

/// Result of a limitation / appeal-period check.
class LimitationResult {
  /// The computed deadline date (already holiday/weekend shifted forward).
  final DateTime deadline;

  /// True when [deadline] is already in the past relative to the reference now.
  final bool expired;

  /// Whole days remaining (negative if expired).
  final int daysRemaining;

  /// True when the raw statutory date fell on a weekend/holiday and was shifted.
  final bool shifted;

  /// The cited norm (e.g. "TsÜS §146 lg 1").
  final String norm;

  const LimitationResult({
    required this.deadline,
    required this.expired,
    required this.daysRemaining,
    required this.shifted,
    required this.norm,
  });
}

/// Severance estimate — Estonian `koondamine` model.
///
/// TLS §100: employer pays 1 month's average salary; Töötukassa adds 1 month
/// (5–10 yrs tenure) or 2 months (>10 yrs). Notice period scales with tenure
/// (TLS §97). All purely from the supplied [monthlySalary] + [tenureYears].
SeveranceResult estonianKoondamine({
  required double monthlySalary,
  required double tenureYears,
}) {
  final breakdown = <String>[];
  // Employer share — always 1 month (TLS §100).
  final employer = monthlySalary;
  breakdown.add('Tööandja (TLS §100): 1 × ${_money(monthlySalary)}');

  // Töötukassa share by tenure.
  double fundMonths = 0;
  if (tenureYears >= 10) {
    fundMonths = 2;
  } else if (tenureYears >= 5) {
    fundMonths = 1;
  }
  final fund = monthlySalary * fundMonths;
  if (fundMonths > 0) {
    breakdown.add(
        'Töötukassa: ${fundMonths.toStringAsFixed(0)} × ${_money(monthlySalary)}');
  } else {
    breakdown.add('Töötukassa: 0 (alla 5 a tööstaaži)');
  }

  // Notice period (TLS §97).
  final int noticeDays;
  if (tenureYears < 1) {
    noticeDays = 15;
  } else if (tenureYears < 5) {
    noticeDays = 30;
  } else if (tenureYears < 10) {
    noticeDays = 60;
  } else {
    noticeDays = 90;
  }

  return SeveranceResult(
    totalAmount: employer + fund,
    noticeDays: noticeDays,
    noticeLabel: '$noticeDays päeva (TLS §97)',
    breakdown: breakdown,
  );
}

/// Severance/notice estimate — Finnish model.
///
/// Finland has no general statutory severance pay; the protected value is the
/// *notice period* salary (TSL 6:3). We estimate the salary owed across the
/// notice period that scales with tenure.
SeveranceResult finnishNotice({
  required double monthlySalary,
  required double tenureYears,
}) {
  final double noticeMonths;
  if (tenureYears < 1) {
    noticeMonths = 0.5; // 14 days
  } else if (tenureYears < 4) {
    noticeMonths = 1;
  } else if (tenureYears < 8) {
    noticeMonths = 2;
  } else if (tenureYears < 12) {
    noticeMonths = 4;
  } else {
    noticeMonths = 6;
  }
  final noticeDays = (noticeMonths * 30).round();
  final total = monthlySalary * noticeMonths;
  return SeveranceResult(
    totalAmount: total,
    noticeDays: noticeDays,
    noticeLabel:
        '${noticeMonths == 0.5 ? '0,5' : noticeMonths.toStringAsFixed(0)} kk (TSL 6:3)',
    breakdown: [
      'Irtisanomisaika: ${noticeMonths == 0.5 ? '0,5' : noticeMonths.toStringAsFixed(0)} kk',
      'Palkka irtisanomisajalta: ${noticeMonths == 0.5 ? '0,5' : noticeMonths.toStringAsFixed(0)} × ${_money(monthlySalary)}',
    ],
  );
}

/// Compute a limitation / appeal deadline from a [start] event date.
///
/// Exactly one of [days] / [years] must be provided. The raw statutory date is
/// then shifted forward off weekends and national holidays (the universal
/// procedural rule in FI/EE: a deadline that lands on a non-working day moves to
/// the next working day).
LimitationResult limitationDeadline({
  required DateTime start,
  int? days,
  int? years,
  required String jurisdiction,
  required String norm,
  DateTime? now,
}) {
  assert((days == null) != (years == null),
      'Provide exactly one of days / years');
  final ref = now ?? DateTime.now();
  // Normalise to date-only to avoid time-of-day off-by-one.
  final s = DateTime(start.year, start.month, start.day);

  DateTime raw;
  if (years != null) {
    raw = DateTime(s.year + years, s.month, s.day);
  } else {
    raw = s.add(Duration(days: days!));
  }

  final shifted = nextWorkingDay(raw, jurisdiction);
  final wasShifted = !_sameDate(shifted, raw);

  final today = DateTime(ref.year, ref.month, ref.day);
  final daysRemaining = shifted.difference(today).inDays;

  return LimitationResult(
    deadline: shifted,
    expired: daysRemaining < 0,
    daysRemaining: daysRemaining,
    shifted: wasShifted,
    norm: norm,
  );
}

/// Pick the applicable state-fee bracket for a claim [amount] against the
/// supplied bracket list. Returns the index of the matched bracket, or -1 when
/// the list is empty. The brackets here are flat labelled rows (not numeric
/// ranges), so when no monetary mapping exists we return the first row as a
/// sensible default and let the UI present the full table.
int defaultStateFeeBracketIndex(List<dynamic> brackets) {
  return brackets.isEmpty ? -1 : 0;
}

/// Orientation child-support estimate.
///
/// Both FI and EE compute the real figure case-by-case (need of the child vs
/// parents' ability to pay). We surface a transparent orientation: the greater
/// of (a) the statutory minimum floor per child, or (b) a flat percentage of
/// the payer's net income per child. STRICTLY indicative.
class ChildSupportResult {
  final double perChild;
  final double total;
  final List<String> breakdown;

  const ChildSupportResult({
    required this.perChild,
    required this.total,
    required this.breakdown,
  });
}

ChildSupportResult childSupportEstimate({
  required double payerNetMonthly,
  required int children,
  required double floorPerChild,
  required double percentPerChild,
}) {
  final n = children < 1 ? 1 : children;
  final byPercent = payerNetMonthly * (percentPerChild / 100);
  final perChild = byPercent > floorPerChild ? byPercent : floorPerChild;
  final breakdown = <String>[
    'Miinimum / floor: ${_money(floorPerChild)} per laps',
    '${percentPerChild.toStringAsFixed(0)}% netosissetulekust: ${_money(byPercent)}',
    'Suurem neist × $n last',
  ];
  return ChildSupportResult(
    perChild: perChild,
    total: perChild * n,
    breakdown: breakdown,
  );
}

bool _sameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _money(double v) => v.toStringAsFixed(2);
