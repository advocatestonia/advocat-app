// calc_rates.dart — rate models + offline fallback defaults for calculators.
// -----------------------------------------------------------------------------
// Mirrors the `calc_rates` table / `calc-rates` edge function. The live function
// is a freshness layer; these baked-in defaults guarantee the calculators work
// fully offline and degrade gracefully when the network is unavailable.
//
// IMPORTANT: keep `kFallbackRates` in sync with the seed in
// supabase/migrations/20260618000000_calc_rates.sql. Both are "rates as of
// 2026-01-01" and labelled indicative.
// -----------------------------------------------------------------------------

/// One bracket row of a state-fee table.
class FeeBracket {
  final String label;
  final num fee;
  const FeeBracket(this.label, this.fee);
}

/// One limitation / appeal period.
class LimitationPeriod {
  final String key;
  final String label;
  final int? days;
  final int? years;
  // Calendar months (e.g. ECHR Art. 35 §1 = 4 months, NOT 120 days). Months
  // are added calendar-wise, not as a fixed day count — a strict
  // non-extendable window must never land early.
  final int? months;
  final String norm;
  const LimitationPeriod({
    required this.key,
    required this.label,
    required this.norm,
    this.days,
    this.years,
    this.months,
  });
}

/// The resolved rate bundle for one jurisdiction.
class CalcRates {
  final String jurisdiction;
  final String asOf; // 'YYYY-MM-DD'
  final bool fromNetwork;

  final List<FeeBracket> stateFeeBrackets;
  final String stateFeeSource;

  final List<LimitationPeriod> limitationPeriods;
  final String limitationSource;

  final double childSupportFloor;
  final double childSupportPercent;
  final String childSupportSource;

  const CalcRates({
    required this.jurisdiction,
    required this.asOf,
    required this.fromNetwork,
    required this.stateFeeBrackets,
    required this.stateFeeSource,
    required this.limitationPeriods,
    required this.limitationSource,
    required this.childSupportFloor,
    required this.childSupportPercent,
    required this.childSupportSource,
  });

  /// Parse the calc-rates edge response. Falls back to [fallback] for any
  /// missing key so a partial response never crashes a calculator.
  factory CalcRates.fromEdge(
    Map<String, dynamic> json,
    CalcRates fallback,
  ) {
    final rates = (json['rates'] as Map?)?.cast<String, dynamic>() ?? {};
    final asOf = json['as_of'] as String? ?? fallback.asOf;

    List<FeeBracket> fees = fallback.stateFeeBrackets;
    String feeSrc = fallback.stateFeeSource;
    final feeRow = rates['state_fee_brackets'] as Map?;
    if (feeRow != null) {
      final payload = (feeRow['payload'] as Map?)?.cast<String, dynamic>();
      final brackets = payload?['brackets'] as List?;
      if (brackets != null && brackets.isNotEmpty) {
        fees = brackets
            .map((b) => FeeBracket(
                  (b as Map)['label'] as String? ?? '',
                  (b)['fee'] as num? ?? 0,
                ))
            .toList();
        feeSrc = feeRow['source_label'] as String? ?? feeSrc;
      }
    }

    List<LimitationPeriod> periods = fallback.limitationPeriods;
    String limSrc = fallback.limitationSource;
    final limRow = rates['limitation_periods'] as Map?;
    if (limRow != null) {
      final payload = (limRow['payload'] as Map?)?.cast<String, dynamic>();
      final list = payload?['periods'] as List?;
      if (list != null && list.isNotEmpty) {
        periods = list.map((p) {
          final m = p as Map;
          return LimitationPeriod(
            key: m['key'] as String? ?? '',
            label: m['label'] as String? ?? '',
            norm: m['norm'] as String? ?? '',
            days: (m['days'] as num?)?.toInt(),
            years: (m['years'] as num?)?.toInt(),
            months: (m['months'] as num?)?.toInt(),
          );
        }).toList();
        limSrc = limRow['source_label'] as String? ?? limSrc;
      }
    }

    double csFloor = fallback.childSupportFloor;
    double csPercent = fallback.childSupportPercent;
    String csSrc = fallback.childSupportSource;
    final csRow = rates['child_support_floor'] as Map?;
    if (csRow != null) {
      csFloor = (csRow['value_numeric'] as num?)?.toDouble() ?? csFloor;
      final payload = (csRow['payload'] as Map?)?.cast<String, dynamic>();
      csPercent =
          (payload?['percent_of_net_per_child'] as num?)?.toDouble() ??
              csPercent;
      csSrc = csRow['source_label'] as String? ?? csSrc;
    }

    return CalcRates(
      jurisdiction: fallback.jurisdiction,
      asOf: asOf,
      fromNetwork: true,
      stateFeeBrackets: fees,
      stateFeeSource: feeSrc,
      limitationPeriods: periods,
      limitationSource: limSrc,
      childSupportFloor: csFloor,
      childSupportPercent: csPercent,
      childSupportSource: csSrc,
    );
  }
}

/// Baked-in defaults per jurisdiction (rates as of 2026-01-01).
/// Keep aligned with migration 20260618000000_calc_rates.sql.
const Map<String, CalcRates> kFallbackRates = {
  'FI': CalcRates(
    jurisdiction: 'FI',
    asOf: '2026-01-01',
    fromNetwork: false,
    stateFeeSource: 'Tuomioistuinmaksulaki 1455/2015',
    stateFeeBrackets: [
      FeeBracket('Käräjäoikeus (laaja riita-asia)', 530),
      FeeBracket('Käräjäoikeus (suppea/summaarinen)', 110),
      FeeBracket('Hovioikeus (valitus)', 540),
      FeeBracket('Korkein oikeus (valitus)', 560),
      FeeBracket('Hallinto-oikeus', 270),
      FeeBracket('Korkein hallinto-oikeus (KHO)', 540),
    ],
    limitationSource: 'Laki velan vanhentumisesta 728/2003; OK 1734',
    limitationPeriods: [
      LimitationPeriod(
          key: 'general_debt',
          label: 'Yleinen velan vanhentuminen',
          years: 3,
          norm: 'VanhL 728/2003 §4'),
      LimitationPeriod(
          key: 'damages',
          label: 'Vahingonkorvaus',
          years: 3,
          norm: 'VanhL 728/2003 §7'),
      LimitationPeriod(
          key: 'civil_appeal',
          label: 'Valitus käräjäoikeudesta hovioikeuteen',
          days: 30,
          norm: 'OK 1734 25:5'),
      LimitationPeriod(
          key: 'admin_appeal',
          label: 'Valitus hallintopäätöksestä',
          days: 30,
          norm: 'OikHL 808/2019 §13'),
      LimitationPeriod(
          key: 'echr',
          label: 'Valitus Euroopan ihmisoikeustuomioistuimeen',
          months: 4,
          norm: 'ECHR Art. 35 (4kk)'),
    ],
    childSupportFloor: 195.31,
    childSupportPercent: 17,
    childSupportSource: 'Laki lapsen elatuksesta 704/1975',
  ),
  'EE': CalcRates(
    jurisdiction: 'EE',
    asOf: '2026-01-01',
    fromNetwork: false,
    stateFeeSource: 'Riigilõivuseadus',
    stateFeeBrackets: [
      FeeBracket('Hagi kuni 350 €', 75),
      FeeBracket('Hagi 350–500 €', 100),
      FeeBracket('Hagi 500–1000 €', 125),
      FeeBracket('Hagi 1000–2000 €', 200),
      FeeBracket('Hagi 2000–5000 €', 300),
      FeeBracket('Apellatsioonkaebus', 300),
      FeeBracket('Kassatsioonkaebus (Riigikohus)', 350),
    ],
    limitationSource: 'TsÜS; TsMS; HKMS',
    limitationPeriods: [
      LimitationPeriod(
          key: 'general_claim',
          label: 'Tehingust tuleneva nõude aegumine',
          years: 3,
          norm: 'TsÜS §146 lg 1'),
      LimitationPeriod(
          key: 'property',
          label: 'Asjaõiguslik nõue',
          years: 10,
          norm: 'TsÜS §146 lg 4'),
      LimitationPeriod(
          key: 'damages',
          label: 'Kahju hüvitamise nõue',
          years: 3,
          norm: 'TsÜS §150'),
      LimitationPeriod(
          key: 'civil_appeal',
          label: 'Apellatsioonkaebus maakohtu otsusele',
          days: 30,
          norm: 'TsMS §632 lg 1'),
      LimitationPeriod(
          key: 'admin_appeal',
          label: 'Kaebus haldusakti peale',
          days: 30,
          norm: 'HKMS §46'),
      LimitationPeriod(
          key: 'echr',
          label: 'Kaebus Euroopa Inimõiguste Kohtusse',
          months: 4,
          norm: 'EIÕK art 35 (4 kuud)'),
    ],
    childSupportFloor: 209.20,
    childSupportPercent: 17,
    childSupportSource: 'Perekonnaseadus §101',
  ),
};

/// Fallback bundle for an unsupported / unknown jurisdiction (defaults to EE).
CalcRates fallbackFor(String jurisdiction) =>
    kFallbackRates[jurisdiction.toUpperCase()] ?? kFallbackRates['EE']!;
