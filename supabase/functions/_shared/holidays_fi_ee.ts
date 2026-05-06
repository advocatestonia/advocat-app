// holidays_fi_ee.ts — Phase 2 Pkg 9 deadline radar.
// -----------------------------------------------------------------------------
// FI/EE public holidays for 2026 + 2027. Used by `holiday_shift.ts` to skip
// weekends + holidays under the `next_business_day` policy.
//
// Coverage rule (architect spec §3): the array must always cover the current
// year + the next year. A test (HS-T60 in `holiday_shift_test.ts`) asserts
// the 2027-01-01 FI and 2027-02-24 EE entries are present so a year rollover
// without an updated table fails the build.
//
// Formats: ISO yyyy-mm-dd. The wall-time semantics intentionally use UTC
// (we compare against the date portion of a Date in UTC), which is fine for
// holiday tagging — both jurisdictions use Helsinki / Tallinn local dates and
// the difference is < 3h, never enough to flip a date when we use noon-UTC
// timestamps in shift calls (see holiday_shift.ts).
// -----------------------------------------------------------------------------

/** FI public holidays (kansalliset juhlapäivät). 2026–2027.
 *
 * Sources:
 *   * Suomen virallinen kalenteri (kalenteri.fi).
 *   * Helsingin yliopiston almanakka.
 *
 * Movable feasts (Easter, Ascension, Pentecost, Midsummer, All Saints')
 * are pre-computed for 2026 and 2027 because the codebase has no Easter
 * library and we don't want to pull one in for two years' worth of dates.
 */
export const FI_HOLIDAYS_2026_2027: readonly string[] = [
  // ── 2026 ────────────────────────────────────────────────────────────
  "2026-01-01", // uudenvuodenpäivä
  "2026-01-06", // loppiainen
  "2026-04-03", // pitkäperjantai (Good Friday 2026)
  "2026-04-05", // pääsiäispäivä (Easter Sunday 2026)
  "2026-04-06", // 2. pääsiäispäivä (Easter Monday 2026)
  "2026-05-01", // vappu
  "2026-05-14", // helatorstai (Ascension 2026 = Easter + 39d)
  "2026-05-24", // helluntaipäivä (Pentecost 2026 = Easter + 49d)
  "2026-06-19", // juhannusaatto (Friday between 19-25 June)
  "2026-06-20", // juhannuspäivä (Saturday after juhannusaatto)
  "2026-10-31", // pyhäinpäivä (movable: Sat between 31 Oct - 6 Nov)
  "2026-12-06", // itsenäisyyspäivä (Sunday in 2026)
  "2026-12-24", // jouluaatto
  "2026-12-25", // joulupäivä
  "2026-12-26", // tapaninpäivä
  // ── 2027 ────────────────────────────────────────────────────────────
  "2027-01-01",
  "2027-01-06",
  "2027-03-26", // pitkäperjantai 2027
  "2027-03-28", // pääsiäispäivä 2027
  "2027-03-29", // 2. pääsiäispäivä 2027
  "2027-05-01",
  "2027-05-06", // helatorstai 2027
  "2027-05-16", // helluntai 2027
  "2027-06-25", // juhannusaatto 2027
  "2027-06-26", // juhannuspäivä 2027
  "2027-11-06", // pyhäinpäivä 2027 (Sat 31 Oct..6 Nov)
  "2027-12-06",
  "2027-12-24",
  "2027-12-25",
  "2027-12-26",
];

/** EE public holidays (riigipühad). 2026–2027.
 *
 * Sources:
 *   * Riigi Teataja Pühade ja tähtpäevade seadus.
 *   * eesti.ee — Tähtsamad päevad ja vabad päevad.
 */
export const EE_HOLIDAYS_2026_2027: readonly string[] = [
  // ── 2026 ────────────────────────────────────────────────────────────
  "2026-01-01", // uusaasta
  "2026-02-24", // iseseisvuspäev
  "2026-04-03", // suur reede (Good Friday)
  "2026-04-05", // ülestõusmispühade 1. püha (Easter Sunday)
  "2026-05-01", // kevadpüha (1.5)
  "2026-05-24", // nelipühade 1. püha (Pentecost 2026)
  "2026-06-23", // võidupüha
  "2026-06-24", // jaanipäev
  "2026-08-20", // taasiseseisvumispäev
  "2026-12-24", // jõululaupäev
  "2026-12-25", // esimene jõulupüha
  "2026-12-26", // teine jõulupüha
  // ── 2027 ────────────────────────────────────────────────────────────
  "2027-01-01",
  "2027-02-24",
  "2027-03-26", // suur reede 2027
  "2027-03-28", // ülestõusmispühad 2027
  "2027-05-01",
  "2027-05-16", // nelipühad 2027
  "2027-06-23",
  "2027-06-24",
  "2027-08-20",
  "2027-12-24",
  "2027-12-25",
  "2027-12-26",
];

/** Pre-built sets for O(1) lookup. */
export const FI_HOLIDAYS_SET = new Set(FI_HOLIDAYS_2026_2027);
export const EE_HOLIDAYS_SET = new Set(EE_HOLIDAYS_2026_2027);
