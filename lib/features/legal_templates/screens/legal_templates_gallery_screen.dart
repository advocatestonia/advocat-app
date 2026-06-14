// legal_templates/screens/legal_templates_gallery_screen.dart — Feature #5.
// -----------------------------------------------------------------------------
// Gallery of curated fill-in legal forms, grouped/filterable by jurisdiction.
// Tapping a card opens the fill screen. This screen is read-only (no user data
// touched) so it works for anonymous traffic too; the fill step is gated by
// auth at the edge function.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/secure_screen.dart';
import '../models/legal_template.dart';
import '../services/legal_template_service.dart';
import 'legal_template_fill_screen.dart';

/// Filter state for the gallery (null = all jurisdictions).
final _jurisdictionFilterProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);

/// Loads templates for the active jurisdiction filter.
final legalTemplatesProvider =
    FutureProvider.autoDispose<List<LegalTemplate>>((ref) async {
  final juris = ref.watch(_jurisdictionFilterProvider);
  final svc = ref.watch(legalTemplateServiceProvider);
  return svc.listTemplates(jurisdiction: juris);
});

class LegalTemplatesGalleryScreen extends ConsumerWidget {
  const LegalTemplatesGalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final templatesAsync = ref.watch(legalTemplatesProvider);
    final activeJuris = ref.watch(_jurisdictionFilterProvider);

    return SecureScreenScope(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.legalTemplatesTitle)),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                l10n.legalTemplatesSubtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            _DisclaimerBanner(text: l10n.legalTemplatesDisclaimer),
            _JurisdictionFilter(
              active: activeJuris,
              allLabel: l10n.legalTemplatesFilterAll,
              fiLabel: l10n.legalTemplatesJurisdictionFi,
              eeLabel: l10n.legalTemplatesJurisdictionEe,
              onChanged: (v) =>
                  ref.read(_jurisdictionFilterProvider.notifier).state = v,
            ),
            Expanded(
              child: templatesAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, st) {
                  debugPrint('[legal_templates] list failed: $e\n$st');
                  return Center(child: Text(l10n.legalTemplatesError));
                },
                data: (templates) {
                  if (templates.isEmpty) {
                    return Center(child: Text(l10n.legalTemplatesEmpty));
                  }
                  return ListView.separated(
                    key: const Key('legal_templates_list'),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: templates.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) => _TemplateCard(
                      template: templates[i],
                      sampleLabel: l10n.legalTemplatesSampleBadge,
                      onTap: () => _openFill(ctx, templates[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFill(BuildContext context, LegalTemplate t) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LegalTemplateFillScreen(template: t),
      ),
    );
  }
}

class _DisclaimerBanner extends StatelessWidget {
  const _DisclaimerBanner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.info_outline, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              key: const Key('legal_templates_disclaimer'),
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _JurisdictionFilter extends StatelessWidget {
  const _JurisdictionFilter({
    required this.active,
    required this.allLabel,
    required this.fiLabel,
    required this.eeLabel,
    required this.onChanged,
  });

  final String? active;
  final String allLabel;
  final String fiLabel;
  final String eeLabel;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: <Widget>[
          _chip(allLabel, active == null, () => onChanged(null), 'all'),
          const SizedBox(width: 8),
          _chip(fiLabel, active == 'FI', () => onChanged('FI'), 'FI'),
          const SizedBox(width: 8),
          _chip(eeLabel, active == 'EE', () => onChanged('EE'), 'EE'),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap, String key) {
    return ChoiceChip(
      key: Key('legal_templates_filter_$key'),
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.sampleLabel,
    required this.onTap,
  });

  final LegalTemplate template;
  final String sampleLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: Key('legal_template_card_${template.slug}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                _iconForCategory(template.category),
                size: 28,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            template.title,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _JurisBadge(jurisdiction: template.jurisdiction),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      template.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (template.isSample) ...<Widget>[
                      const SizedBox(height: 8),
                      _SampleBadge(label: sampleLabel),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'complaint':
        return Icons.report_outlined;
      case 'appeal':
        return Icons.gavel;
      case 'application':
        return Icons.description_outlined;
      case 'claim':
        return Icons.request_quote_outlined;
      case 'request':
        return Icons.folder_open_outlined;
      default:
        return Icons.article_outlined;
    }
  }
}

class _JurisBadge extends StatelessWidget {
  const _JurisBadge({required this.jurisdiction});
  final String jurisdiction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        jurisdiction,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _SampleBadge extends StatelessWidget {
  const _SampleBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
