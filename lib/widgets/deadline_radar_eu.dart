// =====================================================================
// DeadlineRadarEU — UI-only mockup widget for the EU-wide deadline
// calculator (Landmark / EU Statutes phase 2 features).
//
// Status: MOCKUP. No backend wiring, no Riverpod providers, no Supabase
// calls. The user picks a jurisdiction + procedural category + start
// date and hits "Compute"; we return a hardcoded sample response.
// The real edge function (deadline-eu / fetch-eu-statute) will be
// wired in a follow-up; this file documents the contract the UI
// expects so the integration is mechanical.
//
// Contract the eventual backend MUST honour
// -------------------------------------------------------------------
//   Input:  { jurisdiction: ISO-2, category: enum, start: ISO-date }
//   Output: {
//     dueDate:        ISO-date,
//     warnings:       List<String>,   // e.g. interruption events,
//                                     //      holiday shifts, EU
//                                     //      Reg 1182/71 weekend rule
//     holidaySource:  String,         // human label, e.g.
//                                     //      "publicholidays.fi 2026"
//     statuteBasis:   String,         // statutory citation, e.g.
//                                     //      "OK 31:24 (FI)" or
//                                     //      "ZPO § 222 (DE)"
//   }
//
// Visual style: matches existing case_memory/deadline_card.dart —
// AppColors, AppSpacing, AppRadius tokens; Material 3 InkWell;
// light/dark surface variants from Theme.of(context).colorScheme.
// =====================================================================

import 'package:flutter/material.dart';

import '../config/theme.dart';

/// The 31 jurisdictions Advocat currently covers (EU-27 + EEA + UK +
/// Switzerland). Codes are ISO-3166-1 alpha-2; display labels live in
/// English so the mockup runs without the l10n delegate.
const List<JurisdictionEntry> kSupportedJurisdictions = [
  JurisdictionEntry('AT', 'Austria'),
  JurisdictionEntry('BE', 'Belgium'),
  JurisdictionEntry('BG', 'Bulgaria'),
  JurisdictionEntry('HR', 'Croatia'),
  JurisdictionEntry('CY', 'Cyprus'),
  JurisdictionEntry('CZ', 'Czech Republic'),
  JurisdictionEntry('DK', 'Denmark'),
  JurisdictionEntry('EE', 'Estonia'),
  JurisdictionEntry('FI', 'Finland'),
  JurisdictionEntry('FR', 'France'),
  JurisdictionEntry('DE', 'Germany'),
  JurisdictionEntry('GR', 'Greece'),
  JurisdictionEntry('HU', 'Hungary'),
  JurisdictionEntry('IS', 'Iceland'),
  JurisdictionEntry('IE', 'Ireland'),
  JurisdictionEntry('IT', 'Italy'),
  JurisdictionEntry('LV', 'Latvia'),
  JurisdictionEntry('LI', 'Liechtenstein'),
  JurisdictionEntry('LT', 'Lithuania'),
  JurisdictionEntry('LU', 'Luxembourg'),
  JurisdictionEntry('MT', 'Malta'),
  JurisdictionEntry('NL', 'Netherlands'),
  JurisdictionEntry('NO', 'Norway'),
  JurisdictionEntry('PL', 'Poland'),
  JurisdictionEntry('PT', 'Portugal'),
  JurisdictionEntry('RO', 'Romania'),
  JurisdictionEntry('SK', 'Slovakia'),
  JurisdictionEntry('SI', 'Slovenia'),
  JurisdictionEntry('ES', 'Spain'),
  JurisdictionEntry('SE', 'Sweden'),
  JurisdictionEntry('CH', 'Switzerland'),
];

/// Procedural categories supported by the EU deadline engine. These map
/// onto the `deadline_category` enum in the legal corpus.
const List<CategoryEntry> kDeadlineCategories = [
  CategoryEntry('appeal_civil', 'Civil appeal'),
  CategoryEntry('appeal_admin', 'Administrative appeal'),
  CategoryEntry('cassation', 'Cassation / Supreme'),
  CategoryEntry('echr_application', 'ECHR application'),
  CategoryEntry('cjeu_reference', 'CJEU preliminary reference'),
  CategoryEntry('contract_response', 'Contract response'),
  CategoryEntry('limitation_general', 'General limitation period'),
];

class JurisdictionEntry {
  const JurisdictionEntry(this.code, this.label);
  final String code;
  final String label;
}

class CategoryEntry {
  const CategoryEntry(this.code, this.label);
  final String code;
  final String label;
}

/// Mock response object — mirrors the eventual backend payload so the
/// UI doesn't change when we wire the real edge function.
class DeadlineEuResult {
  const DeadlineEuResult({
    required this.dueDate,
    required this.warnings,
    required this.holidaySource,
    required this.statuteBasis,
  });

  final DateTime dueDate;
  final List<String> warnings;
  final String holidaySource;
  final String statuteBasis;
}

/// Inline mock: deterministic so widget tests can assert exact strings.
/// Replace with a real call to the `compute-eu-deadline` edge function
/// once it lands.
DeadlineEuResult _mockCompute({
  required String jurisdictionCode,
  required String categoryCode,
  required DateTime start,
}) {
  // Toy rule: 30 days from start, shifted past weekend.
  var due = start.add(const Duration(days: 30));
  final warnings = <String>[];
  if (due.weekday == DateTime.saturday) {
    due = due.add(const Duration(days: 2));
    warnings.add('Shifted from Saturday per EU Reg 1182/71 art. 3(4).');
  } else if (due.weekday == DateTime.sunday) {
    due = due.add(const Duration(days: 1));
    warnings.add('Shifted from Sunday per EU Reg 1182/71 art. 3(4).');
  }
  if (categoryCode == 'appeal_civil' && jurisdictionCode == 'FI') {
    warnings.add(
      'Interruption event possible: see OK 31:24 — restoration via KHO.',
    );
  }
  if (categoryCode == 'echr_application') {
    warnings.add('ECHR rule changed 1.2.2022: 4-month window post-Protocol 15.');
  }

  return DeadlineEuResult(
    dueDate: due,
    warnings: warnings,
    holidaySource: 'publicholidays.eu — $jurisdictionCode 2026',
    statuteBasis: _basisFor(jurisdictionCode, categoryCode),
  );
}

String _basisFor(String j, String c) {
  // Trivial lookup — production wires this from corpus citations.
  if (j == 'FI' && c == 'appeal_civil') return 'OK 25:5 (Finland)';
  if (j == 'EE' && c == 'appeal_civil') return 'TsMS § 632 (Estonia)';
  if (j == 'DE' && c == 'appeal_civil') return 'ZPO § 517 (Germany)';
  if (c == 'echr_application') return 'ECHR art. 35 § 1';
  if (c == 'cjeu_reference') return 'TFEU art. 267';
  return 'Sample statute basis — backend will resolve this';
}

class DeadlineRadarEu extends StatefulWidget {
  const DeadlineRadarEu({super.key});

  @override
  State<DeadlineRadarEu> createState() => _DeadlineRadarEuState();
}

class _DeadlineRadarEuState extends State<DeadlineRadarEu> {
  String _jurisdiction = 'FI';
  String _category = 'appeal_civil';
  DateTime _start = DateTime(2026, 5, 19);
  DeadlineEuResult? _result;

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _start = picked);
    }
  }

  void _compute() {
    setState(() {
      _result = _mockCompute(
        jurisdictionCode: _jurisdiction,
        categoryCode: _category,
        start: _start,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.radar,
            label: 'EU deadline radar',
          ),
          const SizedBox(height: AppSpacing.md),
          // Jurisdiction
          DropdownButtonFormField<String>(
            key: const Key('deadline-eu-jurisdiction'),
            initialValue: _jurisdiction,
            decoration: const InputDecoration(
              labelText: 'Jurisdiction',
              prefixIcon: Icon(Icons.public, size: 18),
            ),
            items: kSupportedJurisdictions
                .map(
                  (j) => DropdownMenuItem(
                    value: j.code,
                    child: Text('${j.code} — ${j.label}'),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _jurisdiction = v);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          // Category
          DropdownButtonFormField<String>(
            key: const Key('deadline-eu-category'),
            initialValue: _category,
            decoration: const InputDecoration(
              labelText: 'Procedural category',
              prefixIcon: Icon(Icons.category_outlined, size: 18),
            ),
            items: kDeadlineCategories
                .map(
                  (c) => DropdownMenuItem(
                    value: c.code,
                    child: Text(c.label),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _category = v);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          // Start date
          InkWell(
            key: const Key('deadline-eu-start-date'),
            onTap: _pickStart,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Start date',
                prefixIcon: Icon(Icons.event, size: 18),
              ),
              child: Text(
                '${_start.year}-${_start.month.toString().padLeft(2, '0')}-'
                '${_start.day.toString().padLeft(2, '0')}',
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Compute button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const Key('deadline-eu-compute'),
              onPressed: _compute,
              icon: const Icon(Icons.calculate_outlined, size: 18),
              label: const Text('Compute deadline'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_result != null)
            _ResultCard(
              key: const Key('deadline-eu-result'),
              result: _result!,
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.accent),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({super.key, required this.result});
  final DeadlineEuResult result;

  @override
  Widget build(BuildContext context) {
    final due = result.dueDate;
    final formatted =
        '${due.year}-${due.month.toString().padLeft(2, '0')}-'
        '${due.day.toString().padLeft(2, '0')}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_available,
                  color: AppColors.success, size: 20),
              const SizedBox(width: AppSpacing.sm),
              const Text(
                'Due',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                formatted,
                key: const Key('deadline-eu-due-date'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (result.warnings.isNotEmpty) ...[
            const Divider(height: AppSpacing.md),
            const Text(
              'Warnings',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ...result.warnings.map(
              (w) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 14, color: AppColors.warning),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        w,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const Divider(height: AppSpacing.md),
          Row(
            children: [
              const Icon(Icons.menu_book_outlined,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  result.statuteBasis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.calendar_month_outlined,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  result.holidaySource,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
