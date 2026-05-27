import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/deadline.dart';
import '../../../services/supabase_service.dart';
import '../../../shared/utils/date_utils.dart';
// EU corpus phase 2 — pan-EU deadline radar (self-contained mockup
// widget; no network, no providers, deterministic mock output). Mounted
// here as a collapsible section above the per-user deadlines list so
// users can dry-run a hypothetical EU deadline without leaving the
// screen.
import '../../../widgets/deadline_radar_eu.dart';
import '../providers/deadlines_provider.dart';

// ---------------------------------------------------------------------------
// Deadlines Screen
// ---------------------------------------------------------------------------
//
// 2026-05-27 rebuild (Sulga-case learning):
//   * Group by urgency bands (Today/Overdue → This week → This month → Later).
//   * Inline countdown that refreshes via Riverpod invalidation (pull-to-refresh).
//   * Per-card menu: snooze 1d/3d/7d, dismiss, add to calendar (.ics export).
//   * FAB to add a manual deadline (title + date + notes).
//   * Empty state with explanation copy ("auto-created from emails/docs").
//   * Source attribution row when a deadline came from a doc/email.
// ---------------------------------------------------------------------------

/// Urgency bucket assignment for a given delta in days.
enum _UrgencyBucket { todayOverdue, thisWeek, thisMonth, later }

_UrgencyBucket _bucketForDays(int days) {
  if (days <= 0) return _UrgencyBucket.todayOverdue;
  if (days <= 7) return _UrgencyBucket.thisWeek;
  if (days <= 30) return _UrgencyBucket.thisMonth;
  return _UrgencyBucket.later;
}

class DeadlinesScreen extends ConsumerStatefulWidget {
  const DeadlinesScreen({super.key});

  @override
  ConsumerState<DeadlinesScreen> createState() => _DeadlinesScreenState();
}

class _DeadlinesScreenState extends ConsumerState<DeadlinesScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  // Re-render ticker so "3 days left" refreshes without a manual refresh.
  // Cheap — one rebuild per minute is acceptable for a screen with at most
  // a few dozen rows and only paints visible cards.
  Timer? _minuteTicker;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    ));
    _entranceController.forward();

    _minuteTicker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _minuteTicker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final deadlinesAsync = ref.watch(allDeadlinesProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_outlined, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(l10n.deadlines),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDeadlineSheet(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.deadlineAddManual),
        backgroundColor: AppColors.accent,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: deadlinesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.error),
                  const SizedBox(height: AppSpacing.md),
                  Text(l10n.couldNotLoadDeadlines,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: () => ref.invalidate(allDeadlinesProvider),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            ),
            data: (deadlines) {
              // Filter out completed/cancelled — those live in the historic
              // archive; this screen is for actionable items.
              final actionable = deadlines
                  .where((d) =>
                      d.status != DeadlineStatus.completed &&
                      d.status != DeadlineStatus.cancelled)
                  .toList()
                ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

              if (actionable.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(allDeadlinesProvider),
                  child: ListView(
                    children: const [
                      _EuRadarSection(),
                      _DeadlinesEmptyState(),
                    ],
                  ),
                );
              }

              // Group by urgency bucket.
              final buckets = <_UrgencyBucket, List<Deadline>>{};
              for (final d in actionable) {
                final b = _bucketForDays(AppDateUtils.daysUntil(d.dueDate));
                (buckets[b] ??= []).add(d);
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(allDeadlinesProvider);
                  await ref.read(allDeadlinesProvider.future);
                },
                child: CustomScrollView(
                  key: const Key('deadlines-grouped-list'),
                  slivers: [
                    const SliverToBoxAdapter(child: _EuRadarSection()),
                    for (final bucket in _UrgencyBucket.values)
                      if ((buckets[bucket] ?? const []).isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: _UrgencyHeader(bucket: bucket),
                        ),
                        SliverList.separated(
                          itemCount: buckets[bucket]!.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, i) {
                            final deadline = buckets[bucket]![i];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ),
                              child: _DeadlineCard(
                                key: ValueKey('deadline-${deadline.id}'),
                                deadline: deadline,
                                onMarkComplete: () =>
                                    _markComplete(deadline),
                                onSnooze: (days) =>
                                    _snooze(deadline, days),
                                onDismiss: () => _dismiss(deadline),
                                onExportIcs: () =>
                                    _exportIcs(context, deadline),
                              ),
                            );
                          },
                        ),
                      ],
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 96),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _markComplete(Deadline d) async {
    final supabase = ref.read(supabaseServiceProvider);
    await supabase.updateDeadline(d.id, {'status': 'completed'});
    ref.invalidate(allDeadlinesProvider);
  }

  Future<void> _snooze(Deadline d, int days) async {
    final supabase = ref.read(supabaseServiceProvider);
    final newDue = d.dueDate.add(Duration(days: days));
    await supabase.updateDeadline(d.id, {
      'due_date': newDue.toIso8601String(),
    });
    ref.invalidate(allDeadlinesProvider);
  }

  Future<void> _dismiss(Deadline d) async {
    final supabase = ref.read(supabaseServiceProvider);
    await supabase.updateDeadline(d.id, {'status': 'cancelled'});
    ref.invalidate(allDeadlinesProvider);
  }

  Future<void> _exportIcs(BuildContext context, Deadline d) async {
    try {
      final ics = _buildIcs(d);
      // Web / desktop without path_provider — fall back to clipboard.
      Directory? dir;
      try {
        dir = await getTemporaryDirectory();
      } catch (_) {
        // Probably web. Copy to clipboard so the user can paste anywhere.
        await Clipboard.setData(ClipboardData(text: ics));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ICS copied to clipboard')),
          );
        }
        return;
      }
      final safe = d.title.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final file = File('${dir.path}/advocat_$safe.ics');
      await file.writeAsString(ics);
      await Share.shareXFiles([XFile(file.path)],
          subject: 'Advocat deadline: ${d.title}');
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not export calendar event')),
        );
      }
    }
  }

  Future<void> _showAddDeadlineSheet(BuildContext context) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddDeadlineSheet(
        onSave: (title, dueDate, notes) async {
          final supabase = ref.read(supabaseServiceProvider);
          await supabase.createDeadline({
            'title': title,
            'description': notes,
            'due_date': dueDate.toIso8601String(),
            'status': 'upcoming',
            'priority': 'high',
            'type': 'other',
            'source': 'manual',
            // case_id is nullable in the DB; left out here lets the row
            // belong to no case (or the trigger fills a default).
          });
        },
      ),
    );
    if (created == true) {
      ref.invalidate(allDeadlinesProvider);
    }
  }
}

// ---------------------------------------------------------------------------
// ICS builder — RFC 5545 minimal subset.
// ---------------------------------------------------------------------------
String _buildIcs(Deadline d) {
  final dtStamp = _formatIcsUtc(DateTime.now().toUtc());
  final dtStart = _formatIcsDate(d.dueDate);
  final summary = _escapeIcs('Advocat: ${d.title}');
  final description = d.description != null && d.description!.isNotEmpty
      ? _escapeIcs(d.description!)
      : '';
  return 'BEGIN:VCALENDAR\r\n'
      'VERSION:2.0\r\n'
      'PRODID:-//Advocat//EN\r\n'
      'CALSCALE:GREGORIAN\r\n'
      'BEGIN:VEVENT\r\n'
      'UID:advocat-${d.id}@advocat.ee\r\n'
      'DTSTAMP:$dtStamp\r\n'
      'DTSTART;VALUE=DATE:$dtStart\r\n'
      'SUMMARY:$summary\r\n'
      'DESCRIPTION:$description\r\n'
      'STATUS:CONFIRMED\r\n'
      'BEGIN:VALARM\r\n'
      'TRIGGER:-P1D\r\n'
      'ACTION:DISPLAY\r\n'
      'DESCRIPTION:Reminder\r\n'
      'END:VALARM\r\n'
      'END:VEVENT\r\n'
      'END:VCALENDAR\r\n';
}

String _formatIcsUtc(DateTime dt) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${dt.year}${two(dt.month)}${two(dt.day)}T'
      '${two(dt.hour)}${two(dt.minute)}${two(dt.second)}Z';
}

String _formatIcsDate(DateTime dt) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${dt.year}${two(dt.month)}${two(dt.day)}';
}

String _escapeIcs(String s) =>
    s.replaceAll('\\', '\\\\').replaceAll(',', '\\,').replaceAll(';', '\\;');

// ---------------------------------------------------------------------------
// Urgency header
// ---------------------------------------------------------------------------

class _UrgencyHeader extends StatelessWidget {
  const _UrgencyHeader({required this.bucket});
  final _UrgencyBucket bucket;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final (label, color, dot) = switch (bucket) {
      _UrgencyBucket.todayOverdue => (
          l.deadlineUrgencyToday,
          AppColors.error,
          '🔴',
        ),
      _UrgencyBucket.thisWeek => (l.deadlineUrgencyWeek, AppColors.warning, '🟠'),
      _UrgencyBucket.thisMonth => (l.deadlineUrgencyMonth, AppColors.success, '🟡'),
      _UrgencyBucket.later => (
          l.deadlineUrgencyLater,
          AppColors.textTertiary,
          '⚪',
        ),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$dot  $label',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Deadline Card
// ---------------------------------------------------------------------------

class _DeadlineCard extends StatelessWidget {
  const _DeadlineCard({
    super.key,
    required this.deadline,
    required this.onMarkComplete,
    required this.onSnooze,
    required this.onDismiss,
    required this.onExportIcs,
  });

  final Deadline deadline;
  final VoidCallback onMarkComplete;
  final void Function(int days) onSnooze;
  final VoidCallback onDismiss;
  final VoidCallback onExportIcs;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final days = AppDateUtils.daysUntil(deadline.dueDate);
    final isOverdue = days < 0;
    final isUrgent = isOverdue || days < 3;

    final urgencyColor = isOverdue || days < 3
        ? AppColors.error
        : days <= 7
            ? AppColors.warning
            : days <= 30
                ? AppColors.success
                : AppColors.textTertiary;

    final countdownText = isOverdue
        ? l10n.deadlineDaysOverdue(-days)
        : l10n.deadlineDaysLeft(days);

    return Semantics(
      label: 'Deadline: ${deadline.title}, $countdownText',
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isUrgent
                ? AppColors.error.withValues(alpha: 0.3)
                : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
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
                  // -- Days remaining (big number) --
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: urgencyColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isOverdue ? '${-days}' : '$days',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: urgencyColor,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isOverdue ? l10n.daysLate : l10n.days,
                          style: TextStyle(
                            fontSize: 10,
                            color: urgencyColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),

                  // -- Title + date --
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deadline.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${AppDateUtils.formatDate(deadline.dueDate)} '
                          '· $countdownText',
                          style: TextStyle(
                            fontSize: 12,
                            color: urgencyColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // -- More menu (snooze / dismiss / export) --
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert,
                        color: AppColors.textSecondary),
                    onSelected: (v) {
                      switch (v) {
                        case 'snooze_1':
                          onSnooze(1);
                          break;
                        case 'snooze_3':
                          onSnooze(3);
                          break;
                        case 'snooze_7':
                          onSnooze(7);
                          break;
                        case 'dismiss':
                          onDismiss();
                          break;
                        case 'export':
                          onExportIcs();
                          break;
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'snooze_1',
                        child: Text(l10n.deadlineSnooze1d),
                      ),
                      PopupMenuItem(
                        value: 'snooze_3',
                        child: Text(l10n.deadlineSnooze3d),
                      ),
                      PopupMenuItem(
                        value: 'snooze_7',
                        child: Text(l10n.deadlineSnooze7d),
                      ),
                      PopupMenuItem(
                        value: 'export',
                        child: Row(
                          children: [
                            const Icon(Icons.event_available_outlined, size: 18),
                            const SizedBox(width: 8),
                            Text(l10n.deadlineExportIcs),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'dismiss',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline,
                                size: 18, color: AppColors.error),
                            const SizedBox(width: 8),
                            Text(l10n.deadlineDismiss,
                                style: const TextStyle(color: AppColors.error)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // -- Quick complete --
                  Semantics(
                    label: 'Mark deadline complete',
                    button: true,
                    child: IconButton(
                      key: const ValueKey('mark-complete'),
                      onPressed: onMarkComplete,
                      tooltip: l10n.markComplete,
                      icon: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: AppColors.success,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // -- Source attribution (which document/email generated this) --
              if (deadline.source != DeadlineSource.manual ||
                  deadline.sourceDocumentId != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.only(left: 72),
                  child: Row(
                    children: [
                      Icon(_sourceIcon(deadline.source),
                          size: 12, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Text(
                        '${l10n.deadlineSource}: ${_sourceLabel(deadline.source, l10n)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static IconData _sourceIcon(DeadlineSource s) {
    switch (s) {
      case DeadlineSource.aiExtracted:
        return Icons.auto_awesome_outlined;
      case DeadlineSource.emailExtracted:
        return Icons.mail_outline;
      case DeadlineSource.manual:
        return Icons.edit_outlined;
    }
  }

  static String _sourceLabel(DeadlineSource s, AppLocalizations l) {
    switch (s) {
      case DeadlineSource.aiExtracted:
        return l.deadlineCardSourceLabelHaikuExtract;
      case DeadlineSource.emailExtracted:
        return l.deadlineCardSourceLabelEmail;
      case DeadlineSource.manual:
        return l.deadlineCardSourceLabelManual;
    }
  }
}

// ---------------------------------------------------------------------------
// Empty state — explains how deadlines get created.
// ---------------------------------------------------------------------------

class _DeadlinesEmptyState extends StatelessWidget {
  const _DeadlinesEmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 60),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_available_outlined,
              size: 40,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.noUpcomingDeadlines,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.deadlineEmpty,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add-deadline modal sheet (manual entry)
// ---------------------------------------------------------------------------

class _AddDeadlineSheet extends StatefulWidget {
  const _AddDeadlineSheet({required this.onSave});
  final Future<void> Function(String title, DateTime dueDate, String? notes)
      onSave;

  @override
  State<_AddDeadlineSheet> createState() => _AddDeadlineSheetState();
}

class _AddDeadlineSheetState extends State<_AddDeadlineSheet> {
  final _titleCtl = TextEditingController();
  final _notesCtl = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _saving = false;

  @override
  void dispose() {
    _titleCtl.dispose();
    _notesCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.deadlineNewTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              key: const Key('deadline-title-field'),
              controller: _titleCtl,
              decoration: InputDecoration(
                labelText: l.deadlineFieldTitle,
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: AppSpacing.md),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dueDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                );
                if (picked != null) {
                  setState(() => _dueDate = picked);
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l.deadlineFieldDueDate,
                  border: const OutlineInputBorder(),
                ),
                child: Text(AppDateUtils.formatDate(_dueDate)),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('deadline-notes-field'),
              controller: _notesCtl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l.deadlineFieldNotes,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('deadline-save-button'),
                onPressed: _saving || _titleCtl.text.trim().isEmpty
                    ? null
                    : () async {
                        setState(() => _saving = true);
                        try {
                          await widget.onSave(
                            _titleCtl.text.trim(),
                            _dueDate,
                            _notesCtl.text.trim().isEmpty
                                ? null
                                : _notesCtl.text.trim(),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l.deadlineSaved)),
                            );
                            Navigator.of(context).pop(true);
                          }
                        } catch (_) {
                          setState(() => _saving = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l.deadlineSaveFailed)),
                            );
                          }
                        }
                      },
                child: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l.deadlineSaved),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// EU Deadline Radar section wrapper
// ---------------------------------------------------------------------------

class _EuRadarSection extends StatelessWidget {
  const _EuRadarSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: const ExpansionTile(
            key: Key('eu-deadline-radar-section'),
            leading: Icon(Icons.radar, color: AppColors.accent),
            title: Text(
              'EU deadline radar (preview)',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              'Hypothetical EU procedural deadlines — mock data',
              style: TextStyle(fontSize: 11),
            ),
            childrenPadding: EdgeInsets.zero,
            children: [DeadlineRadarEu()],
          ),
        ),
      ),
    );
  }
}
