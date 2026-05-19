// =====================================================================
// LandmarkExplorer — UI-only mockup for the Landmark Cases browser.
//
// Status: MOCKUP. 20 hardcoded landmark decisions (CJEU + ECHR + EFTA)
// rendered with a search bar, three filter chip groups (court / area /
// decade), and a tap-through detail panel.
//
// Contract the eventual backend MUST honour
// -------------------------------------------------------------------
//   GET /landmark-search?q=…&court=…&area=…&decade=…
//   → List<{
//       id, caseName, court, year, area, significance, summary,
//       citationUri (optional)
//     }>
//
// Once the `landmark-search` edge function exists this widget can be
// converted to a ConsumerStatefulWidget reading an async provider; the
// visible API (filter state, item shape) is designed to map 1:1.
// =====================================================================

import 'package:flutter/material.dart';

import '../config/theme.dart';

/// Mock data record. Inline so the mockup needs no model file.
class LandmarkCase {
  const LandmarkCase({
    required this.id,
    required this.caseName,
    required this.court,
    required this.year,
    required this.area,
    required this.significance,
    required this.summary,
  });

  final String id;
  final String caseName;
  final String court; // CJEU | ECHR | EFTA
  final int year;
  final String area; // GDPR | Free movement | Criminal | …
  final String significance; // 'foundational' | 'leading' | 'recent'
  final String summary;
}

/// 20 inline samples spanning the three courts and several decades.
const List<LandmarkCase> _kMockLandmarks = [
  LandmarkCase(
    id: 'cjeu-c-131-12',
    caseName: 'Google Spain v. AEPD (C-131/12)',
    court: 'CJEU',
    year: 2014,
    area: 'GDPR',
    significance: 'foundational',
    summary:
        'Established the "right to be forgotten" against search engines '
        'under the 1995 Data Protection Directive — later codified in '
        'GDPR art. 17.',
  ),
  LandmarkCase(
    id: 'cjeu-c-311-18',
    caseName: 'Schrems II (C-311/18)',
    court: 'CJEU',
    year: 2020,
    area: 'GDPR',
    significance: 'leading',
    summary:
        'Invalidated the EU–US Privacy Shield; SCCs survive only with '
        'a case-by-case adequacy assessment.',
  ),
  LandmarkCase(
    id: 'echr-12345-67',
    caseName: 'Sulga v. Finland (12345/67)',
    court: 'ECHR',
    year: 2024,
    area: 'Asylum & deportation',
    significance: 'recent',
    summary:
        'Pending — mock placeholder; real significance pending Chamber '
        'judgment.',
  ),
  LandmarkCase(
    id: 'cjeu-c-6-64',
    caseName: 'Costa v. ENEL (6/64)',
    court: 'CJEU',
    year: 1964,
    area: 'Constitutional',
    significance: 'foundational',
    summary:
        'Primacy of EU law over conflicting national law — bedrock '
        'principle of the EU legal order.',
  ),
  LandmarkCase(
    id: 'cjeu-26-62',
    caseName: 'Van Gend en Loos (26/62)',
    court: 'CJEU',
    year: 1963,
    area: 'Constitutional',
    significance: 'foundational',
    summary:
        'Direct effect of Treaty provisions — individuals can invoke '
        'EU law before national courts.',
  ),
  LandmarkCase(
    id: 'echr-25803-94',
    caseName: 'Selmouni v. France (25803/94)',
    court: 'ECHR',
    year: 1999,
    area: 'Article 3',
    significance: 'leading',
    summary:
        'Living-instrument doctrine: police violence reclassified from '
        'inhuman treatment to torture under ECHR art. 3.',
  ),
  LandmarkCase(
    id: 'echr-2346-02',
    caseName: 'Pretty v. United Kingdom (2346/02)',
    court: 'ECHR',
    year: 2002,
    area: 'Article 8',
    significance: 'leading',
    summary:
        'Right to private life encompasses personal autonomy; assisted '
        'suicide ban survives art. 8 challenge on margin of appreciation.',
    ),
  LandmarkCase(
    id: 'cjeu-c-186-87',
    caseName: 'Cowan v. Trésor Public (C-186/87)',
    court: 'CJEU',
    year: 1989,
    area: 'Free movement',
    significance: 'leading',
    summary:
        'Tourists as service recipients fall within the free movement '
        'of services — nationality discrimination prohibited.',
  ),
  LandmarkCase(
    id: 'efta-e-9-97',
    caseName: 'Sveinbjörnsdóttir (E-9/97)',
    court: 'EFTA',
    year: 1998,
    area: 'State liability',
    significance: 'foundational',
    summary:
        'EFTA Court extends Francovich-style state liability to EEA '
        'states for breaches of EEA law.',
  ),
  LandmarkCase(
    id: 'cjeu-c-617-10',
    caseName: 'Åkerberg Fransson (C-617/10)',
    court: 'CJEU',
    year: 2013,
    area: 'Charter',
    significance: 'leading',
    summary:
        'Charter applies whenever a Member State implements EU law — '
        'broad scope for fundamental rights review.',
  ),
  LandmarkCase(
    id: 'echr-30141-04',
    caseName: 'Schalk and Kopf v. Austria (30141/04)',
    court: 'ECHR',
    year: 2010,
    area: 'Article 12',
    significance: 'leading',
    summary:
        'Same-sex relationships enjoy "family life" protection under '
        'art. 8; no positive obligation to allow marriage under art. 12.',
  ),
  LandmarkCase(
    id: 'cjeu-c-362-14',
    caseName: 'Schrems I (C-362/14)',
    court: 'CJEU',
    year: 2015,
    area: 'GDPR',
    significance: 'foundational',
    summary:
        'Invalidated the Safe Harbor adequacy decision; opened the '
        'door to Schrems II.',
  ),
  LandmarkCase(
    id: 'echr-39954-08',
    caseName: 'Axel Springer v. Germany (39954/08)',
    court: 'ECHR',
    year: 2012,
    area: 'Article 10',
    significance: 'leading',
    summary:
        'Six-factor balancing test for press freedom vs. privacy of '
        'public figures.',
  ),
  LandmarkCase(
    id: 'cjeu-c-293-12',
    caseName: 'Digital Rights Ireland (C-293/12)',
    court: 'CJEU',
    year: 2014,
    area: 'GDPR',
    significance: 'leading',
    summary:
        'Data Retention Directive invalidated for disproportionate '
        'interference with Charter arts. 7 and 8.',
  ),
  LandmarkCase(
    id: 'echr-14038-88',
    caseName: 'Soering v. United Kingdom (14038/88)',
    court: 'ECHR',
    year: 1989,
    area: 'Article 3',
    significance: 'foundational',
    summary:
        'Non-refoulement to face death-row phenomenon engages art. 3 — '
        'cornerstone of extradition jurisprudence.',
  ),
  LandmarkCase(
    id: 'cjeu-c-415-93',
    caseName: 'Bosman (C-415/93)',
    court: 'CJEU',
    year: 1995,
    area: 'Free movement',
    significance: 'leading',
    summary:
        'Transfer fees for out-of-contract footballers violate free '
        'movement of workers (TFEU art. 45).',
  ),
  LandmarkCase(
    id: 'cjeu-c-555-07',
    caseName: 'Kücükdeveci (C-555/07)',
    court: 'CJEU',
    year: 2010,
    area: 'Employment',
    significance: 'leading',
    summary:
        'Age discrimination as a general principle of EU law — direct '
        'horizontal effect of the Charter principle.',
  ),
  LandmarkCase(
    id: 'efta-e-1-94',
    caseName: 'Restamark (E-1/94)',
    court: 'EFTA',
    year: 1994,
    area: 'Free movement',
    significance: 'leading',
    summary:
        'EEA agreement provisions enjoy direct effect within the EFTA '
        'pillar of the EEA.',
  ),
  LandmarkCase(
    id: 'echr-19010-07',
    caseName: 'X and Others v. Austria (19010/07)',
    court: 'ECHR',
    year: 2013,
    area: 'Article 14',
    significance: 'leading',
    summary:
        'Same-sex couples excluded from second-parent adoption — art. '
        '14 + art. 8 violation.',
  ),
  LandmarkCase(
    id: 'cjeu-c-673-16',
    caseName: 'Coman (C-673/16)',
    court: 'CJEU',
    year: 2018,
    area: 'Free movement',
    significance: 'recent',
    summary:
        '"Spouse" in the Citizens Rights Directive includes same-sex '
        'spouses — Member States must recognise residence rights.',
  ),
];

class LandmarkExplorer extends StatefulWidget {
  const LandmarkExplorer({super.key});

  @override
  State<LandmarkExplorer> createState() => _LandmarkExplorerState();
}

class _LandmarkExplorerState extends State<LandmarkExplorer> {
  String _query = '';
  final Set<String> _courtFilter = <String>{};
  final Set<String> _areaFilter = <String>{};
  final Set<int> _decadeFilter = <int>{};
  LandmarkCase? _selected;

  static const List<String> _kCourts = ['CJEU', 'ECHR', 'EFTA'];
  static const List<String> _kAreas = [
    'GDPR',
    'Free movement',
    'Constitutional',
    'Article 3',
    'Article 8',
    'Article 10',
    'Article 12',
    'Article 14',
    'Charter',
    'Employment',
    'State liability',
    'Asylum & deportation',
  ];
  static const List<int> _kDecades = [1960, 1980, 1990, 2000, 2010, 2020];

  List<LandmarkCase> get _filtered {
    final q = _query.trim().toLowerCase();
    return _kMockLandmarks.where((c) {
      if (_courtFilter.isNotEmpty && !_courtFilter.contains(c.court)) {
        return false;
      }
      if (_areaFilter.isNotEmpty && !_areaFilter.contains(c.area)) {
        return false;
      }
      if (_decadeFilter.isNotEmpty) {
        final decade = (c.year ~/ 10) * 10;
        if (!_decadeFilter.contains(decade)) return false;
      }
      if (q.isEmpty) return true;
      return c.caseName.toLowerCase().contains(q) ||
          c.summary.toLowerCase().contains(q) ||
          c.area.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.gavel, size: 18, color: AppColors.accent),
              SizedBox(width: AppSpacing.xs),
              Text(
                'Landmark explorer',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            key: const Key('landmark-search-bar'),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search, size: 18),
              hintText: 'Search by case name, summary, or area…',
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ChipGroup(
            label: 'Court',
            options: _kCourts,
            selected: _courtFilter,
            onToggle: (v) => setState(() {
              if (!_courtFilter.add(v)) _courtFilter.remove(v);
            }),
            keyPrefix: 'landmark-court',
          ),
          const SizedBox(height: AppSpacing.xs),
          _ChipGroup(
            label: 'Area',
            options: _kAreas,
            selected: _areaFilter,
            onToggle: (v) => setState(() {
              if (!_areaFilter.add(v)) _areaFilter.remove(v);
            }),
            keyPrefix: 'landmark-area',
          ),
          const SizedBox(height: AppSpacing.xs),
          _ChipGroup(
            label: 'Decade',
            options: _kDecades.map((d) => '${d}s').toList(),
            selected: _decadeFilter.map((d) => '${d}s').toSet(),
            onToggle: (v) {
              final decade = int.parse(v.substring(0, 4));
              setState(() {
                if (!_decadeFilter.add(decade)) {
                  _decadeFilter.remove(decade);
                }
              });
            },
            keyPrefix: 'landmark-decade',
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '${filtered.length} of ${_kMockLandmarks.length} cases',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          // Result list — capped at a sensible height so the explorer
          // can live inside a scroll view.
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: ListView.separated(
              key: const Key('landmark-result-list'),
              shrinkWrap: true,
              itemCount: filtered.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.xs),
              itemBuilder: (_, i) {
                final c = filtered[i];
                return _LandmarkRow(
                  data: c,
                  onTap: () => setState(() => _selected = c),
                );
              },
            ),
          ),
          if (_selected != null) ...[
            const SizedBox(height: AppSpacing.md),
            _DetailPanel(
              key: const Key('landmark-detail-panel'),
              data: _selected!,
              onClose: () => setState(() => _selected = null),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChipGroup extends StatelessWidget {
  const _ChipGroup({
    required this.label,
    required this.options,
    required this.selected,
    required this.onToggle,
    required this.keyPrefix,
  });

  final String label;
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: options.map((opt) {
            final isOn = selected.contains(opt);
            return FilterChip(
              key: Key('$keyPrefix-${opt.toLowerCase()}'),
              label: Text(opt),
              selected: isOn,
              onSelected: (_) => onToggle(opt),
              selectedColor: AppColors.accent.withValues(alpha: 0.18),
              checkmarkColor: AppColors.accent,
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _LandmarkRow extends StatelessWidget {
  const _LandmarkRow({required this.data, required this.onTap});
  final LandmarkCase data;
  final VoidCallback onTap;

  Color _courtColor() {
    switch (data.court) {
      case 'CJEU':
        return AppColors.primary;
      case 'ECHR':
        return AppColors.accent;
      case 'EFTA':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CourtBadge(label: data.court, color: _courtColor()),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.caseName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${data.area} · ${data.year} · ${data.significance}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 18, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourtBadge extends StatelessWidget {
  const _CourtBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({
    super.key,
    required this.data,
    required this.onClose,
  });
  final LandmarkCase data;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.infoBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  data.caseName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                key: const Key('landmark-detail-close'),
                onPressed: onClose,
                icon: const Icon(Icons.close, size: 18),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          Text(
            '${data.court} · ${data.year} · ${data.area} · '
            '${data.significance}',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            data.summary,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
