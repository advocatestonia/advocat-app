import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../config/router.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/case_model.dart';
import '../../../models/deadline.dart';
import '../../../models/document.dart';
import '../../../shared/utils/date_utils.dart';
import '../../../shared/widgets/max_width_wrapper.dart';
import '../providers/cases_provider.dart';
import '../../deadlines/providers/deadlines_provider.dart';
import '../../documents/providers/documents_provider.dart';

// ---------------------------------------------------------------------------
// Case Detail Screen
// ---------------------------------------------------------------------------

class CaseDetailScreen extends ConsumerWidget {
  const CaseDetailScreen({super.key, required this.caseId});

  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caseAsync = ref.watch(caseByIdProvider(caseId));
    final docsAsync = ref.watch(documentsProvider(caseId));
    final deadlinesAsync = ref.watch(caseDeadlinesProvider(caseId));

    return caseAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text(AppLocalizations.of(context)?.couldNotLoadCase ?? 'Could not load case details',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => ref.invalidate(caseByIdProvider(caseId)),
                child: Text(AppLocalizations.of(context)?.retry ?? 'Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (legalCase) => Scaffold(
        // Use MaxWidthWrapper's responsive default — case detail is page
        // content (info cards, action tiles, documents/deadlines sections),
        // not a form. On desktop it should breathe out to 1200px instead
        // of being squeezed into a 480px column with empty gutters.
        body: MaxWidthWrapper(
          child: CustomScrollView(
          slivers: [
            // ── Sliver app bar with glow effect ──────────────────────
            SliverAppBar(
              expandedHeight: 120,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  legalCase.title,
                  style: const TextStyle(fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                background: _GlowingAppBarBackground(),
              ),
              actions: [
                _StatusChip(status: legalCase.status),
                const SizedBox(width: AppSpacing.sm),
              ],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Case info card (entrance animation) ───────────
                    _EntranceAnimation(
                      delay: 0,
                      child: _CaseInfoCard(legalCase: legalCase),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Action tiles (entrance animation) ─────────────
                    _EntranceAnimation(
                      delay: 1,
                      child: _ActionTilesRow(caseId: caseId),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Documents section ─────────────────────────────
                    _EntranceAnimation(
                      delay: 2,
                      child: docsAsync.when(
                        loading: () => const _SectionShimmer(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (docs) => _DocumentsSection(
                          documents: docs,
                          caseId: caseId,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ── Deadlines section ─────────────────────────────
                    _EntranceAnimation(
                      delay: 3,
                      child: deadlinesAsync.when(
                        loading: () => const _SectionShimmer(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (deadlines) => _DeadlinesSection(
                          deadlines: deadlines,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ── Timeline section ──────────────────────────────
                    _EntranceAnimation(
                      delay: 4,
                      child: _TimelineSection(
                        legalCase: legalCase,
                        caseId: caseId,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Entrance Animation wrapper (fade + slide up)
// ---------------------------------------------------------------------------

class _EntranceAnimation extends StatefulWidget {
  const _EntranceAnimation({
    required this.delay,
    required this.child,
  });

  /// Delay index (0, 1, 2...) — each adds 80ms delay.
  final int delay;
  final Widget child;

  @override
  State<_EntranceAnimation> createState() => _EntranceAnimationState();
}

class _EntranceAnimationState extends State<_EntranceAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    Future.delayed(Duration(milliseconds: widget.delay * 80), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: widget.child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Glowing App Bar Background
// ---------------------------------------------------------------------------

class _GlowingAppBarBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle radial glow in top-left
          Positioned(
            top: -20,
            left: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: 0.15),
                    AppColors.accent.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          // Subtle radial glow in bottom-right
          Positioned(
            bottom: -30,
            right: -10,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentLight.withValues(alpha: 0.1),
                    AppColors.accentLight.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status Chip
// ---------------------------------------------------------------------------

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final CaseStatus status;

  Color get _color => switch (status) {
        CaseStatus.active => AppColors.accent,
        CaseStatus.pendingDecision => AppColors.warning,
        CaseStatus.appealFiled => AppColors.info,
        CaseStatus.inCourt => AppColors.primary,
        CaseStatus.resolved => AppColors.success,
        CaseStatus.closed => AppColors.textTertiary,
      };

  String _label(AppLocalizations l10n) => switch (status) {
        CaseStatus.active => l10n.active,
        CaseStatus.pendingDecision => l10n.pendingDecision,
        CaseStatus.appealFiled => l10n.appeal,
        CaseStatus.inCourt => l10n.inCourt,
        CaseStatus.resolved => l10n.won,
        CaseStatus.closed => l10n.closed,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _label(AppLocalizations.of(context)!),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Case Info Card
// ---------------------------------------------------------------------------

class _CaseInfoCard extends StatelessWidget {
  const _CaseInfoCard({required this.legalCase});

  final LegalCase legalCase;

  String _typeLabel(CaseType type, AppLocalizations l10n) => switch (type) {
        CaseType.deportation => l10n.deportation,
        CaseType.asylum => l10n.asylum,
        CaseType.residencePermit => l10n.residencePermit,
        CaseType.familyReunification => l10n.familyReunification,
        CaseType.citizenship => l10n.citizenship,
        CaseType.workPermit => l10n.workPermit,
        CaseType.laborDispute => l10n.laborDispute,
        CaseType.tenantRights => l10n.tenantRights,
        CaseType.debtCollection => l10n.debtCollection,
        CaseType.discrimination => l10n.discrimination,
        CaseType.policeMisconduct => l10n.policeMisconduct,
        CaseType.socialBenefits => l10n.socialBenefits,
        CaseType.domesticViolence => l10n.domesticViolence,
        CaseType.consumerProtection => l10n.consumerProtection,
        CaseType.inheritance => l10n.inheritance,
        CaseType.other => l10n.other,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            _InfoRow(
              label: l10n.typeLabel,
              value: _typeLabel(legalCase.type, l10n),
              icon: Icons.category_outlined,
            ),
            const Divider(height: AppSpacing.lg),
            if (legalCase.nationality != null) ...[
              _InfoRow(
                label: l10n.nationality,
                value: legalCase.nationality!,
                icon: Icons.flag_outlined,
              ),
              const Divider(height: AppSpacing.lg),
            ],
            if (legalCase.migriReferenceNumber != null) ...[
              _InfoRow(
                label: l10n.migriReference,
                value: legalCase.migriReferenceNumber!,
                icon: Icons.tag,
              ),
              const Divider(height: AppSpacing.lg),
            ],
            if (legalCase.courtCaseNumber != null) ...[
              _InfoRow(
                label: l10n.courtCaseNo,
                value: legalCase.courtCaseNumber!,
                icon: Icons.gavel_outlined,
              ),
              const Divider(height: AppSpacing.lg),
            ],
            _InfoRow(
              label: l10n.created,
              value: AppDateUtils.formatDate(legalCase.createdAt),
              icon: Icons.calendar_today_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textTertiary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Action Tiles Row (with scale animation on tap)
// ---------------------------------------------------------------------------

class _ActionTilesRow extends StatelessWidget {
  const _ActionTilesRow({required this.caseId});

  final String caseId;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        children: [
          _AnimatedActionTile(
            icon: Icons.document_scanner_outlined,
            label: l.scanDocument,
            color: AppColors.accent,
            onTap: () => context.push(AppRoutes.scan),
          ),
          _AnimatedActionTile(
            icon: Icons.psychology_outlined,
            label: l.aiAnalysis,
            color: AppColors.info,
            onTap: () => context.push('/chat/$caseId'),
          ),
          _AnimatedActionTile(
            icon: Icons.description_outlined,
            label: l.draftAppeal,
            color: AppColors.primary,
            onTap: () => context.push('/chat/$caseId'),
          ),
          _AnimatedActionTile(
            icon: Icons.smart_toy_outlined,
            label: l.aiChat,
            color: AppColors.accentDark,
            onTap: () => context.push('/chat/$caseId'),
          ),
        ],
      ),
    );
  }
}

class _AnimatedActionTile extends StatefulWidget {
  const _AnimatedActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_AnimatedActionTile> createState() => _AnimatedActionTileState();
}

class _AnimatedActionTileState extends State<_AnimatedActionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap();
        },
        onTapCancel: () => _controller.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: 88,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: widget.color.withValues(alpha: 0.15)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, color: widget.color, size: 28),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: widget.color,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Documents Section
// ---------------------------------------------------------------------------

class _DocumentsSection extends StatelessWidget {
  const _DocumentsSection({required this.documents, required this.caseId});

  final List<CaseDocument> documents;
  final String caseId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _SectionCard(
      title: l10n.documents,
      trailing: documents.length > 3
          ? TextButton(
              onPressed: () => context.push('/cases/$caseId/documents'),
              child: Text(l10n.viewAll),
            )
          : null,
      isEmpty: documents.isEmpty,
      emptyMessage: l10n.noDocumentsYet,
      emptyIcon: Icons.description_outlined,
      child: Column(
        children: documents.take(3).map((doc) {
          return ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(
                Icons.insert_drive_file_outlined,
                color: AppColors.textTertiary,
                size: 20,
              ),
            ),
            title: Text(
              doc.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              timeago.format(doc.createdAt),
              style: const TextStyle(fontSize: 12),
            ),
            trailing: _ProcessingBadge(status: doc.processingStatus),
          );
        }).toList(),
      ),
    );
  }
}

class _ProcessingBadge extends StatelessWidget {
  const _ProcessingBadge({required this.status});

  final DocumentProcessingStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (label, color) = switch (status) {
      DocumentProcessingStatus.pending => (l10n.pending, AppColors.textTertiary),
      DocumentProcessingStatus.processing => (l10n.processing, AppColors.warning),
      DocumentProcessingStatus.completed => (l10n.ready, AppColors.success),
      DocumentProcessingStatus.failed => (l10n.failed, AppColors.error),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Deadlines Section (with glow for urgent items)
// ---------------------------------------------------------------------------

class _DeadlinesSection extends StatelessWidget {
  const _DeadlinesSection({required this.deadlines});

  final List<Deadline> deadlines;

  @override
  Widget build(BuildContext context) {
    final upcoming = deadlines
        .where((d) =>
            d.status == DeadlineStatus.upcoming ||
            d.status == DeadlineStatus.overdue)
        .toList();

    final l10n = AppLocalizations.of(context)!;
    return _SectionCard(
      title: l10n.deadlines,
      isEmpty: upcoming.isEmpty,
      emptyMessage: l10n.noUpcomingDeadlinesShort,
      emptyIcon: Icons.event_available_outlined,
      child: Column(
        children: upcoming.take(3).map((deadline) {
          final days = AppDateUtils.daysUntil(deadline.dueDate);
          final isUrgent = days <= 3;
          final isOverdue = days < 0;
          final urgencyColor = isOverdue
              ? AppColors.error
              : isUrgent
                  ? AppColors.warning
                  : AppColors.success;

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                // Days countdown with glow for urgent
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: urgencyColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    boxShadow: (isUrgent || isOverdue)
                        ? [
                            BoxShadow(
                              color: urgencyColor.withValues(alpha: 0.3),
                              blurRadius: 10,
                              spreadRadius: 0,
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isOverdue ? '${-days}' : '$days',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: urgencyColor,
                        ),
                      ),
                      Text(
                        isOverdue ? l10n.late : l10n.days,
                        style: TextStyle(
                          fontSize: 10,
                          color: urgencyColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deadline.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppDateUtils.formatDate(deadline.dueDate),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Timeline Section (summary, links to full timeline)
// ---------------------------------------------------------------------------

class _TimelineSection extends StatelessWidget {
  const _TimelineSection({required this.legalCase, required this.caseId});

  final LegalCase legalCase;
  final String caseId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _SectionCard(
      title: l10n.timeline,
      trailing: TextButton(
        onPressed: () => context.push('/cases/$caseId/timeline'),
        child: Text(l10n.viewAll),
      ),
      isEmpty: false,
      emptyMessage: '',
      emptyIcon: Icons.timeline,
      child: Column(
        children: [
          _TimelineEntry(
            title: l10n.caseCreated,
            date: legalCase.createdAt,
            icon: Icons.add_circle_outline,
            color: AppColors.accent,
          ),
          if (legalCase.decisionDate != null)
            _TimelineEntry(
              title: l10n.decisionReceived,
              date: legalCase.decisionDate!,
              icon: Icons.gavel_outlined,
              color: AppColors.warning,
            ),
          if (legalCase.appealDeadline != null)
            _TimelineEntry(
              title: l10n.appealDeadline,
              date: legalCase.appealDeadline!,
              icon: Icons.schedule,
              color: AppColors.error,
              isLast: legalCase.hearingDate == null,
            ),
          if (legalCase.hearingDate != null)
            _TimelineEntry(
              title: l10n.hearingScheduled,
              date: legalCase.hearingDate!,
              icon: Icons.event_outlined,
              color: AppColors.info,
              isLast: true,
            ),
        ],
      ),
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    required this.title,
    required this.date,
    required this.icon,
    required this.color,
    this.isLast = false,
  });

  final String title;
  final DateTime date;
  final IconData icon;
  final Color color;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                _PulsingTimelineDot(icon: icon, color: color),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    AppDateUtils.formatShort(date),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
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

// ---------------------------------------------------------------------------
// Pulsing Timeline Dot
// ---------------------------------------------------------------------------

class _PulsingTimelineDot extends StatefulWidget {
  const _PulsingTimelineDot({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  State<_PulsingTimelineDot> createState() => _PulsingTimelineDotState();
}

class _PulsingTimelineDotState extends State<_PulsingTimelineDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  final _pulseNotifier = ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.addListener(() {
      _pulseNotifier.value = _pulseAnimation.value;
    });
  }

  @override
  void dispose() {
    _pulseNotifier.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: _pulseNotifier,
      builder: (context, pulse, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.15 + pulse * 0.15),
                blurRadius: 4 + pulse * 4,
                spreadRadius: pulse * 1.5,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Icon(widget.icon, size: 18, color: widget.color),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable Section Card
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    this.trailing,
    required this.isEmpty,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.child,
  });

  final String title;
  final Widget? trailing;
  final bool isEmpty;
  final String emptyMessage;
  final IconData emptyIcon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
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
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(emptyIcon, size: 20, color: AppColors.textTertiary),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      emptyMessage,
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            else
              child,
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer placeholder for loading sections
// ---------------------------------------------------------------------------

class _SectionShimmer extends StatelessWidget {
  const _SectionShimmer();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 100,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 200,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
