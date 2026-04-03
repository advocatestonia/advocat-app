import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';


/// Data model for a country's legal aid system.
class _CountryLegalAid {
  final String countryCode;
  final String flag;
  final String countryName;
  final String systemName;
  final String currency;
  final double freeThreshold;
  final double partialThreshold;
  final double assetThreshold;
  final String whereToApply;
  final String phone;
  final String website;
  final String notes;

  const _CountryLegalAid({
    required this.countryCode,
    required this.flag,
    required this.countryName,
    required this.systemName,
    required this.currency,
    required this.freeThreshold,
    required this.partialThreshold,
    required this.assetThreshold,
    required this.whereToApply,
    required this.phone,
    required this.website,
    this.notes = '',
  });
}

const List<_CountryLegalAid> _countries = [
  _CountryLegalAid(
    countryCode: 'FI',
    flag: '\u{1F1EB}\u{1F1EE}',
    countryName: 'Finland',
    systemName: 'Oikeusapu',
    currency: 'EUR',
    freeThreshold: 600,
    partialThreshold: 1400,
    assetThreshold: 10000,
    whereToApply: 'Oikeusaputoimisto (Legal Aid Office)',
    phone: '029 56 00100',
    website: 'https://oikeus.fi/oikeusapu',
    notes: 'Dependents reduce disposable income by ~300 EUR each.',
  ),
  _CountryLegalAid(
    countryCode: 'EE',
    flag: '\u{1F1EA}\u{1F1EA}',
    countryName: 'Estonia',
    systemName: 'Riigi \u00f5igusabi',
    currency: 'EUR',
    freeThreshold: 820,
    partialThreshold: 1200,
    assetThreshold: 8000,
    whereToApply: 'Riigi \u00d5igusabi (State Legal Aid)',
    phone: '+372 620 8183',
    website: 'https://www.riigiteataja.ee/en/eli/ee/Riigikogu/act/503012023005/consolide',
    notes: 'Free if income below minimum wage (~820 EUR). Court may grant partial aid.',
  ),
  _CountryLegalAid(
    countryCode: 'DE',
    flag: '\u{1F1E9}\u{1F1EA}',
    countryName: 'Germany',
    systemName: 'Beratungshilfe / Prozesskostenhilfe',
    currency: 'EUR',
    freeThreshold: 800,
    partialThreshold: 1500,
    assetThreshold: 15000,
    whereToApply: 'Amtsgericht (Local Court)',
    phone: 'Local Amtsgericht',
    website: 'https://www.bmj.de/DE/Themen/GessVerfR/Prozesskostenhilfe/Prozesskostenhilfe_node.html',
    notes:
        'Beratungshilfe for out-of-court advice. Prozesskostenhilfe for court proceedings.',
  ),
  _CountryLegalAid(
    countryCode: 'SE',
    flag: '\u{1F1F8}\u{1F1EA}',
    countryName: 'Sweden',
    systemName: 'R\u00e4ttshj\u00e4lp',
    currency: 'SEK',
    freeThreshold: 21700,
    partialThreshold: 21700,
    assetThreshold: 0,
    whereToApply: 'R\u00e4ttshj\u00e4lpsmyndigheten (Legal Aid Authority)',
    phone: '+46 60 13 46 00',
    website: 'https://www.rattshjalp.se',
    notes:
        'Available if annual income \u2264260,000 SEK (\u224821,700/month). Must first use legal insurance if available.',
  ),
  _CountryLegalAid(
    countryCode: 'FR',
    flag: '\u{1F1EB}\u{1F1F7}',
    countryName: 'France',
    systemName: 'Aide juridictionnelle',
    currency: 'EUR',
    freeThreshold: 1158,
    partialThreshold: 1737,
    assetThreshold: 12271,
    whereToApply: 'Bureau d\'aide juridictionnelle (BAJ)',
    phone: '3039',
    website: 'https://www.service-public.fr/particuliers/vosdroits/F18074',
    notes:
        'Full aid if income <1,158 EUR/month. Partial aid if income <1,737 EUR/month.',
  ),
  _CountryLegalAid(
    countryCode: 'ES',
    flag: '\u{1F1EA}\u{1F1F8}',
    countryName: 'Spain',
    systemName: 'Asistencia Jur\u00eddica Gratuita',
    currency: 'EUR',
    freeThreshold: 1200,
    partialThreshold: 1800,
    assetThreshold: 0,
    whereToApply: 'Comisi\u00f3n de Asistencia Jur\u00eddica Gratuita',
    phone: '900 101 025',
    website: 'https://www.mjusticia.gob.es/es/atencion-ciudadano/servicios/asistencia-juridica-gratuita',
    notes: 'Free if income below 2x IPREM (\u22481,200 EUR/month for individuals).',
  ),
  _CountryLegalAid(
    countryCode: 'IT',
    flag: '\u{1F1EE}\u{1F1F9}',
    countryName: 'Italy',
    systemName: 'Patrocinio a spese dello Stato',
    currency: 'EUR',
    freeThreshold: 1070,
    partialThreshold: 1070,
    assetThreshold: 0,
    whereToApply: 'Consiglio dell\'Ordine degli Avvocati',
    phone: 'Local Bar Association',
    website: 'https://www.giustizia.it/giustizia/it/mg_3_7.page',
    notes:
        'Free if taxable income <12,838 EUR/year (\u22481,070 EUR/month). Threshold increases with dependents.',
  ),
  _CountryLegalAid(
    countryCode: 'NL',
    flag: '\u{1F1F3}\u{1F1F1}',
    countryName: 'Netherlands',
    systemName: 'Gesubsidieerde rechtsbijstand',
    currency: 'EUR',
    freeThreshold: 1400,
    partialThreshold: 2100,
    assetThreshold: 31340,
    whereToApply: 'Raad voor Rechtsbijstand (Legal Aid Board)',
    phone: '0900 8020',
    website: 'https://www.rvr.org',
    notes: 'Based on income and assets. Checked via tax records. Small personal contribution required.',
  ),
  _CountryLegalAid(
    countryCode: 'PL',
    flag: '\u{1F1F5}\u{1F1F1}',
    countryName: 'Poland',
    systemName: 'Pomoc prawna z urz\u0119du',
    currency: 'PLN',
    freeThreshold: 3500,
    partialThreshold: 5000,
    assetThreshold: 0,
    whereToApply: 'S\u0105d (Court) or Free Legal Aid Points',
    phone: '+48 22 505 11 00',
    website: 'https://www.gov.pl/web/sprawiedliwosc/nieodplatna-pomoc-prawna',
    notes:
        'Court decides based on financial situation. Free legal aid points also available for all citizens.',
  ),
];

/// Calculator screen to determine eligibility for legal aid across EU countries.
class LegalAidCalculatorScreen extends StatefulWidget {
  const LegalAidCalculatorScreen({super.key});

  @override
  State<LegalAidCalculatorScreen> createState() =>
      _LegalAidCalculatorScreenState();
}

class _LegalAidCalculatorScreenState extends State<LegalAidCalculatorScreen> {
  int _selectedCountryIndex = 0;
  double _monthlyIncome = 0;
  double _assets = 0;
  int _dependents = 0;
  bool _calculated = false;
  _AidResult? _result;

  _CountryLegalAid get _selectedCountry => _countries[_selectedCountryIndex];

  void _onCountryChanged(int index) {
    setState(() {
      _selectedCountryIndex = index;
      _calculated = false;
      _result = null;
      _monthlyIncome = 0;
      _assets = 0;
      _dependents = 0;
    });
  }

  void _calculate() {
    final l10n = AppLocalizations.of(context)!;
    final country = _selectedCountry;
    final disposable = _monthlyIncome - (_dependents * 300);
    final bool eligible;
    final String description;
    final double coPayPercent;

    if (disposable <= country.freeThreshold &&
        (country.assetThreshold == 0 || _assets < country.assetThreshold)) {
      eligible = true;
      coPayPercent = 0;
      description = l10n.fullFreeLegalAid;
    } else if (disposable <= country.partialThreshold &&
        (country.assetThreshold == 0 ||
            _assets < country.assetThreshold * 3)) {
      eligible = true;
      final range = country.partialThreshold - country.freeThreshold;
      coPayPercent = range > 0
          ? ((disposable - country.freeThreshold) / range * 75).clamp(0, 75)
          : 0;
      description = l10n.legalAidWithCopay(coPayPercent.toStringAsFixed(0));
    } else {
      eligible = false;
      coPayPercent = 100;
      description = l10n.mayNotQualifyDesc;
    }

    setState(() {
      _calculated = true;
      _result = _AidResult(
        eligible: eligible,
        coPayPercent: coPayPercent,
        description: description,
      );
    });
  }

  double get _maxIncomeSlider {
    final country = _selectedCountry;
    // Set slider max to ~3x the partial threshold so user can go above
    final baseMax = country.partialThreshold * 3;
    if (country.currency == 'SEK') return 80000;
    if (country.currency == 'PLN') return 15000;
    return baseMax.clamp(3000, 10000);
  }

  double get _maxAssetsSlider {
    if (_selectedCountry.assetThreshold == 0) return 50000;
    return (_selectedCountry.assetThreshold * 5).clamp(10000, 200000);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final country = _selectedCountry;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.legalAidCalculator),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Country selector chips
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _countries.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final c = _countries[index];
                  final isSelected = index == _selectedCountryIndex;
                  return ChoiceChip(
                    label: Text(
                      '${c.flag} ${c.countryName}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? AppColors.textOnPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.accent,
                    backgroundColor: AppColors.surface,
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.accent
                          : AppColors.border,
                    ),
                    onSelected: (_) => _onCountryChanged(index),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Country legal aid info card
            _CountryInfoCard(country: country),
            const SizedBox(height: AppSpacing.lg),

            Text(
              l10n.checkEligibility,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.estimateDisclaimer,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _SliderField(
              label: '${l10n.monthlyIncome} (${country.currency})',
              value: _monthlyIncome.clamp(0, _maxIncomeSlider),
              min: 0,
              max: _maxIncomeSlider,
              divisions: 50,
              currency: country.currency,
              onChanged: (v) => setState(() {
                _monthlyIncome = v;
                _calculated = false;
              }),
            ),
            const SizedBox(height: AppSpacing.lg),
            _SliderField(
              label: '${l10n.totalAssets} (${country.currency})',
              value: _assets.clamp(0, _maxAssetsSlider),
              min: 0,
              max: _maxAssetsSlider,
              divisions: 100,
              currency: country.currency,
              onChanged: (v) => setState(() {
                _assets = v;
                _calculated = false;
              }),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Text(
                  l10n.numberOfDependents,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _dependents > 0
                      ? () => setState(() {
                            _dependents--;
                            _calculated = false;
                          })
                      : null,
                ),
                Text(
                  '$_dependents',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => setState(() {
                    _dependents++;
                    _calculated = false;
                  }),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _calculate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
                child: Text(l10n.calculateEligibility),
              ),
            ),
            if (_calculated && _result != null) ...[
              const SizedBox(height: AppSpacing.xl),
              _ResultCard(result: _result!),
            ],
          ],
        ),
      ),
    );
  }
}

/// Displays the selected country's legal aid system information.
class _CountryInfoCard extends StatelessWidget {
  const _CountryInfoCard({required this.country});

  final _CountryLegalAid country;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  country.flag,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        country.systemName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        country.countryName,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: AppSpacing.sm),
            _InfoRow(
              icon: Icons.money_off,
              label: 'Free aid threshold',
              value:
                  '\u2264${country.freeThreshold.toStringAsFixed(0)} ${country.currency}/month',
            ),
            if (country.partialThreshold != country.freeThreshold)
              _InfoRow(
                icon: Icons.money,
                label: 'Partial aid threshold',
                value:
                    '\u2264${country.partialThreshold.toStringAsFixed(0)} ${country.currency}/month',
              ),
            if (country.assetThreshold > 0)
              _InfoRow(
                icon: Icons.account_balance_wallet,
                label: 'Asset limit',
                value:
                    '<${country.assetThreshold.toStringAsFixed(0)} ${country.currency}',
              ),
            const SizedBox(height: AppSpacing.xs),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: AppSpacing.sm),
            _InfoRow(
              icon: Icons.business,
              label: 'Where to apply',
              value: country.whereToApply,
            ),
            _InfoRow(
              icon: Icons.phone,
              label: 'Phone',
              value: country.phone,
            ),
            _InfoRow(
              icon: Icons.language,
              label: 'Website',
              value: country.website,
            ),
            if (country.notes.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline,
                        size: 16,
                        color: AppColors.info),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        country.notes,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, height: 1.4),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliderField extends StatelessWidget {
  const _SliderField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    this.currency = 'EUR',
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const Spacer(),
            Text('${value.toStringAsFixed(0)} $currency',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: AppColors.accent,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _AidResult {
  final bool eligible;
  final double coPayPercent;
  final String description;

  const _AidResult({
    required this.eligible,
    required this.coPayPercent,
    required this.description,
  });
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final _AidResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = result.eligible ? AppColors.success : AppColors.warning;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  result.eligible
                      ? Icons.check_circle_outline
                      : Icons.info_outline,
                  color: color,
                ),
                const SizedBox(width: 8),
                Text(
                  result.eligible ? l10n.likelyEligible : l10n.mayNotQualify,
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700, color: color),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(result.description,
                style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5)),
          ],
        ),
      ),
    );
  }
}
