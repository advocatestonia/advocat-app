// limitation_holidays.dart — minimal FI/EE public-holiday + weekend roll-forward.
// -----------------------------------------------------------------------------
// The universal procedural rule in both Finland and Estonia: when a statutory
// deadline lands on a Saturday, Sunday, or a public holiday, it rolls forward to
// the next working day. This mirrors the edge-side `_shared/holiday_shift.ts`
// logic but is kept as a self-contained client copy so the limitation
// calculator works fully offline.
//
// Coverage: fixed-date national holidays for FI/EE plus the movable Easter
// cluster (Good Friday, Easter Monday, Ascension, Whit/Pentecost-adjacent days)
// computed from the Gauss/Meeus Easter algorithm. Midsummer (FI Juhannus) is the
// Friday/Saturday between 19–25 June. This is a procedural convenience, not a
// definitive holiday register — the calculator is explicitly indicative.
// -----------------------------------------------------------------------------

/// Returns true if [d] is a Saturday or Sunday.
bool isWeekend(DateTime d) =>
    d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;

/// Returns true if [d] is a recognised public holiday in [jurisdiction]
/// ('FI' or 'EE'). Unknown jurisdictions return false (weekend-only shift).
bool isHoliday(DateTime d, String jurisdiction) {
  final j = jurisdiction.toUpperCase();
  final md = (d.month, d.day);
  final easter = _easterSunday(d.year);

  // Shared fixed dates.
  const sharedFixed = <(int, int)>{
    (1, 1), // New Year
    (5, 1), // May Day / Labour
    (12, 24), // Christmas Eve
    (12, 25), // Christmas Day
    (12, 26), // Boxing / 2nd Christmas
  };
  if (sharedFixed.contains(md)) return true;

  // Easter cluster (both): Good Friday (-2), Easter Monday (+1),
  // Ascension (+39), Pentecost Sunday (+49).
  final goodFriday = easter.subtract(const Duration(days: 2));
  final easterMonday = easter.add(const Duration(days: 1));
  final ascension = easter.add(const Duration(days: 39));
  final pentecost = easter.add(const Duration(days: 49));
  for (final h in [goodFriday, easter, easterMonday, ascension, pentecost]) {
    if (_sameDate(d, h)) return true;
  }

  if (j == 'FI') {
    const fiFixed = <(int, int)>{
      (1, 6), // Epiphany
      (12, 6), // Independence Day
    };
    if (fiFixed.contains(md)) return true;
    // Midsummer Eve: Friday between 19–25 June.
    if (d.month == 6 && d.day >= 19 && d.day <= 25 &&
        d.weekday == DateTime.friday) {
      return true;
    }
    // All Saints' Day: Saturday between Oct 31 – Nov 6.
    if (((d.month == 10 && d.day == 31) || (d.month == 11 && d.day <= 6)) &&
        d.weekday == DateTime.saturday) {
      return true;
    }
    return false;
  }

  if (j == 'EE') {
    const eeFixed = <(int, int)>{
      (2, 24), // Independence Day
      (6, 23), // Victory Day
      (6, 24), // Midsummer (Jaanipäev)
      (8, 20), // Restoration of Independence
    };
    if (eeFixed.contains(md)) return true;
    return false;
  }

  return false;
}

/// Roll [d] forward to the next working day if it falls on a weekend/holiday.
/// If [d] is already a working day it is returned unchanged.
DateTime nextWorkingDay(DateTime d, String jurisdiction) {
  var cur = DateTime(d.year, d.month, d.day);
  // Bounded loop — at most a handful of consecutive non-working days exist.
  for (var i = 0; i < 14; i++) {
    if (!isWeekend(cur) && !isHoliday(cur, jurisdiction)) return cur;
    cur = cur.add(const Duration(days: 1));
  }
  return cur;
}

/// Gauss/Meeus Easter Sunday (Western/Gregorian) for [year].
DateTime _easterSunday(int year) {
  final a = year % 19;
  final b = year ~/ 100;
  final c = year % 100;
  final d = b ~/ 4;
  final e = b % 4;
  final f = (b + 8) ~/ 25;
  final g = (b - f + 1) ~/ 3;
  final h = (19 * a + b - d - g + 15) % 30;
  final i = c ~/ 4;
  final k = c % 4;
  final l = (32 + 2 * e + 2 * i - h - k) % 7;
  final m = (a + 11 * h + 22 * l) ~/ 451;
  final month = (h + l - 7 * m + 114) ~/ 31;
  final day = ((h + l - 7 * m + 114) % 31) + 1;
  return DateTime(year, month, day);
}

bool _sameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
