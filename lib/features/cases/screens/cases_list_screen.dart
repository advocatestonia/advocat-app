import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/case_model.dart';
import '../providers/cases_provider.dart';
import '../../../shared/widgets/skeleton_loader.dart';
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
        // TODO: Re-enable filter when case type filtering is implemented
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.tune_outlined),
        //     tooltip: 'Filter',
        //     onPressed: () => _showFilterSheet(context, ref),
        //   ),
        // ],
      ),
      body: Column(
        children: [
          // ── Search bar with glow ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: _GlowingSearchField(
              searchQuery: searchQuery,
              onChanged: (v) =>
                  ref.read(_searchQueryProvider.notifier).state = v,
              onClear: () =>
                  ref.read(_searchQueryProvider.notifier).state = '',
            ),
          ),

          // ── Segmented control with animated selection ────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: SizedBox(
              width: double.infinity,
              child: AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
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
                    animationDuration: Duration(milliseconds: 300),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // ── Cases list with staggered animation ──────────────────────
          Expanded(
            child: casesAsync.when(
              loading: () => const CaseListSkeletonLoader(),
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
                  child: _StaggeredCaseList(
                    cases: filtered,
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
                  AppLocalizations.of(context)?.filterByType ?? 'Filter by Type',
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
                      label: Text(_caseTypeLabel(context, type)),
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

// ---------------------------------------------------------------------------
// Glowing Search Field
// ---------------------------------------------------------------------------

class _GlowingSearchField extends StatefulWidget {
  const _GlowingSearchField({
    required this.searchQuery,
    required this.onChanged,
    required this.onClear,
  });

  final String searchQuery;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  State<_GlowingSearchField> createState() => _GlowingSearchFieldState();
}

class _GlowingSearchFieldState extends State<_GlowingSearchField> {
  final _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.25),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: TextField(
        focusNode: _focusNode,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)?.searchCases ?? 'Search cases...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: widget.searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: widget.onClear,
                )
              : null,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 12,
          ),
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Staggered Case List with entrance animation
// ---------------------------------------------------------------------------

class _StaggeredCaseList extends StatefulWidget {
  const _StaggeredCaseList({required this.cases});

  final List<LegalCase> cases;

  @override
  State<_StaggeredCaseList> createState() => _StaggeredCaseListState();
}

class _StaggeredCaseListState extends State<_StaggeredCaseList>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300 + widget.cases.length * 80),
    )..forward();
  }

  @override
  void didUpdateWidget(_StaggeredCaseList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cases.length != widget.cases.length) {
      _controller.duration =
          Duration(milliseconds: 300 + widget.cases.length * 80);
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        100, // FAB clearance
      ),
      itemCount: widget.cases.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final legalCase = widget.cases[index];
        final start = (index * 0.08).clamp(0.0, 0.7);
        final end = (start + 0.3).clamp(0.0, 1.0);

        final slideAnimation = Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ));

        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(start, end, curve: Curves.easeOut),
          ),
        );

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: _PressableCaseCard(
              legalCase: legalCase,
              onTap: () => context.push('/cases/${legalCase.id}'),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Pressable Case Card — scale down on tap + subtle shadow
// ---------------------------------------------------------------------------

class _PressableCaseCard extends StatefulWidget {
  const _PressableCaseCard({
    required this.legalCase,
    required this.onTap,
  });

  final LegalCase legalCase;
  final VoidCallback onTap;

  @override
  State<_PressableCaseCard> createState() => _PressableCaseCardState();
}

class _PressableCaseCardState extends State<_PressableCaseCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _scaleController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: CaseCard(
            legalCase: widget.legalCase,
            onTap: () {}, // handled by GestureDetector above
          ),
        ),
      ),
    );
  }
}

String _caseTypeLabel(BuildContext context, CaseType type) {
  final l10n = AppLocalizations.of(context);
  return switch (type) {
    CaseType.deportation => l10n?.deportation ?? 'Deportation',
    CaseType.asylum => l10n?.asylum ?? 'Asylum',
    CaseType.residencePermit => l10n?.residencePermit ?? 'Residence Permit',
    CaseType.familyReunification => l10n?.familyReunification ?? 'Family Reunification',
    CaseType.citizenship => l10n?.citizenship ?? 'Citizenship',
    CaseType.workPermit => l10n?.workPermit ?? 'Work Permit',
    CaseType.laborDispute => l10n?.laborDispute ?? 'Labor Dispute',
    CaseType.tenantRights => l10n?.tenantRights ?? 'Tenant Rights',
    CaseType.debtCollection => l10n?.debtCollection ?? 'Debt Collection',
    CaseType.discrimination => l10n?.discrimination ?? 'Discrimination',
    CaseType.policeMisconduct => l10n?.policeMisconduct ?? 'Police Misconduct',
    CaseType.socialBenefits => l10n?.socialBenefits ?? 'Social Benefits',
    CaseType.domesticViolence => l10n?.domesticViolence ?? 'Domestic Violence',
    CaseType.consumerProtection => l10n?.consumerProtection ?? 'Consumer Protection',
    CaseType.other => l10n?.other ?? 'Other',
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
                AppLocalizations.of(context)?.noCasesMatchSearch ?? 'No cases match your search',
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
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.accent.withValues(alpha: 0.15),
                    AppColors.accent.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(icon, size: 40, color: AppColors.accent),
            ),
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
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: onCreateCase,
                  icon: const Icon(Icons.add),
                  label: Text(AppLocalizations.of(context)?.createCase ?? 'Create Case'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
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
            AppLocalizations.of(context)?.failedToLoadCases ?? 'Failed to load cases',
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
