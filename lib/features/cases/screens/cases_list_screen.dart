import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/case_model.dart';
import '../providers/cases_provider.dart';
import '../widgets/case_card.dart';

// ---------------------------------------------------------------------------
// Cases List Screen
// ---------------------------------------------------------------------------

/// Filter segment for the cases list.
enum _CaseSegment { all, active, closed }

/// Provider for the currently selected segment.
final _segmentProvider = StateProvider<_CaseSegment>((_) => _CaseSegment.all);

/// Provider for the search query.
final _searchQueryProvider = StateProvider<String>((_) => '');

class CasesListScreen extends ConsumerWidget {
  const CasesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final casesAsync = ref.watch(casesProvider);
    final segment = ref.watch(_segmentProvider);
    final searchQuery = ref.watch(_searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.myCases ?? 'My Cases'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_outlined),
            tooltip: 'Filter',
            onPressed: () => _showFilterSheet(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)?.searchCases ?? 'Search cases...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () =>
                            ref.read(_searchQueryProvider.notifier).state = '',
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 12,
                ),
              ),
              onChanged: (v) =>
                  ref.read(_searchQueryProvider.notifier).state = v,
            ),
          ),

          // ── Segmented control ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<_CaseSegment>(
                segments: [
                  ButtonSegment(
                    value: _CaseSegment.all,
                    label: Text(AppLocalizations.of(context)?.all ?? 'All'),
                  ),
                  ButtonSegment(
                    value: _CaseSegment.active,
                    label: Text(AppLocalizations.of(context)?.active ?? 'Active'),
                  ),
                  ButtonSegment(
                    value: _CaseSegment.closed,
                    label: Text(AppLocalizations.of(context)?.closed ?? 'Closed'),
                  ),
                ],
                selected: {segment},
                onSelectionChanged: (sel) =>
                    ref.read(_segmentProvider.notifier).state = sel.first,
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // ── Cases list ─────────────────────────────────────────────────
          Expanded(
            child: casesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorBody(
                onRetry: () => ref.invalidate(casesProvider),
              ),
              data: (cases) {
                final filtered = _filterCases(cases, segment, searchQuery);

                if (filtered.isEmpty) {
                  return _SegmentEmptyState(
                    segment: segment,
                    hasSearch: searchQuery.isNotEmpty,
                    onCreateCase: () => context.push(AppRoutes.caseCreate),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(casesProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      100, // FAB clearance
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final legalCase = filtered[index];
                      return CaseCard(
                        legalCase: legalCase,
                        onTap: () =>
                            context.push('/cases/${legalCase.id}'),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.caseCreate),
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context)?.newCase ?? 'New Case'),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
      ),
    );
  }

  List<LegalCase> _filterCases(
    List<LegalCase> cases,
    _CaseSegment segment,
    String query,
  ) {
    var result = cases;

    // Segment filter
    switch (segment) {
      case _CaseSegment.all:
        break;
      case _CaseSegment.active:
        result = result
            .where((c) =>
                c.status != CaseStatus.closed &&
                c.status != CaseStatus.resolved)
            .toList();
        break;
      case _CaseSegment.closed:
        result = result
            .where((c) =>
                c.status == CaseStatus.closed ||
                c.status == CaseStatus.resolved)
            .toList();
        break;
    }

    // Search filter
    if (query.isNotEmpty) {
      final lower = query.toLowerCase();
      result = result.where((c) {
        return c.title.toLowerCase().contains(lower) ||
            (c.description?.toLowerCase().contains(lower) ?? false) ||
            (c.migriReferenceNumber?.toLowerCase().contains(lower) ?? false);
      }).toList();
    }

    return result;
  }

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Filter by Type',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: CaseType.values.map((type) {
                    return FilterChip(
                      label: Text(_caseTypeLabel(type)),
                      selected: false,
                      onSelected: (_) {
                        // Filter by case type
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        );
      },
    );
  }
}

String _caseTypeLabel(CaseType type) {
  return switch (type) {
    CaseType.deportation => 'Deportation',
    CaseType.asylum => 'Asylum',
    CaseType.residencePermit => 'Residence Permit',
    CaseType.familyReunification => 'Family Reunification',
    CaseType.citizenship => 'Citizenship',
    CaseType.workPermit => 'Work Permit',
    CaseType.laborDispute => 'Labor Dispute',
    CaseType.tenantRights => 'Tenant Rights',
    CaseType.debtCollection => 'Debt Collection',
    CaseType.discrimination => 'Discrimination',
    CaseType.policeMisconduct => 'Police Misconduct',
    CaseType.socialBenefits => 'Social Benefits',
    CaseType.other => 'Other',
  };
}

// ---------------------------------------------------------------------------
// Segment Empty States
// ---------------------------------------------------------------------------

class _SegmentEmptyState extends StatelessWidget {
  const _SegmentEmptyState({
    required this.segment,
    required this.hasSearch,
    required this.onCreateCase,
  });

  final _CaseSegment segment;
  final bool hasSearch;
  final VoidCallback onCreateCase;

  @override
  Widget build(BuildContext context) {
    if (hasSearch) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off, size: 48, color: AppColors.textTertiary),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No cases match your search',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    final l = AppLocalizations.of(context);
    final (icon, title, subtitle) = switch (segment) {
      _CaseSegment.all => (
          Icons.folder_open_outlined,
          l?.noCasesYet ?? 'No cases yet',
          l?.startFirstCase ?? 'Create your first case',
        ),
      _CaseSegment.active => (
          Icons.check_circle_outline,
          l?.noCases ?? 'No active cases',
          '',
        ),
      _CaseSegment.closed => (
          Icons.archive_outlined,
          l?.closed ?? 'No closed cases',
          '',
        ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            if (segment == _CaseSegment.all) ...[
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton.icon(
                onPressed: onCreateCase,
                icon: const Icon(Icons.add),
                label: Text(AppLocalizations.of(context)?.createCase ?? 'Create Case'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error Body
// ---------------------------------------------------------------------------

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48, color: AppColors.error),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Failed to load cases',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(AppLocalizations.of(context)?.retry ?? 'Retry'),
          ),
        ],
      ),
    );
  }
}
