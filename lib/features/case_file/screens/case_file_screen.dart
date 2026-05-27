// case_file_screen.dart — the auto-built dossier UI.
// -----------------------------------------------------------------------------
// Renders a vertical timeline + parties list + key deadlines + an Export-PDF
// button.  Owner-spec: this is THE wow moment — paste a PPA letter + 2
// chat messages and 30s later see the timeline + countdown auto-built.
//
// Wired to:
//   * lib/features/case_file/case_file_providers.dart (state)
//   * lib/services/pdf_service.dart (PDF export)
//   * lib/services/case_file_service.dart (markdown rendering)
// -----------------------------------------------------------------------------

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui show FontFeature;

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/case_file.dart';
import '../../../services/case_file_service.dart';
import '../../../services/ics_export_service.dart';
import '../../../services/pdf_service.dart';
import '../case_file_providers.dart';
import '../widgets/deadline_countdown_card.dart';
import '../widgets/pending_intentions_section.dart';

/// Test-only seam — receives the rendered .ics body and is expected to
/// dispatch it to the platform's share/download surface. Production
/// callers leave this null and the screen uses [_defaultIcsHandler].
typedef IcsHandler = Future<void> Function(String icsBody);

class CaseFileScreen extends ConsumerStatefulWidget {
  const CaseFileScreen({
    super.key,
    this.caseId,
    this.pdfServiceOverride,
    this.icsHandlerOverride,
  });

  /// Optional case scoping. When null we show every Case-File row across
  /// all of the user's cases (cross-case dossier).
  final String? caseId;

  /// Test-only seam — production callers leave this null.
  final PdfService? pdfServiceOverride;

  /// Test-only seam — production callers leave this null and the screen
  /// uses the platform share-sheet to deliver the .ics file.
  final IcsHandler? icsHandlerOverride;

  @override
  ConsumerState<CaseFileScreen> createState() => _CaseFileScreenState();
}

class _CaseFileScreenState extends ConsumerState<CaseFileScreen> {
  PdfService get _pdfService => widget.pdfServiceOverride ?? PdfService();
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    if (widget.caseId != null) {
      // Bind to the specific case after the first build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(caseFileProvider.notifier).bind(caseId: widget.caseId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(caseFileProvider);
    final l = AppLocalizations.of(context);
    final today = DateTime.now();
    final urgent = state.mostUrgentDeadline(today);
    final activeDeadlines = state.activeDeadlines();

    final title = l?.caseFileTitle ?? 'Case File';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: state.loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: l?.refresh ?? 'Refresh',
            onPressed: state.loading
                ? null
                : () => ref.read(caseFileProvider.notifier).refresh(),
          ),
        ],
      ),
      body: state.isEmpty
          ? _EmptyState(message: l?.caseFileEmpty ??
              'Chat with the AI about your case — your timeline will build itself.')
          : RefreshIndicator(
              onRefresh: () => ref.read(caseFileProvider.notifier).refresh(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (urgent != null) ...[
                    _DeadlineRowWithCalendar(
                      deadline: urgent,
                      today: today,
                      iconKey: const Key(
                          'case_file_calendar_export_urgent'),
                      onAddToCalendar: () =>
                          _exportDeadlineToCalendar(urgent),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (activeDeadlines.length > 1)
                    _buildSection(
                      title: l?.caseFileDeadlines ?? 'Deadlines',
                      child: Column(
                        children: activeDeadlines
                            .skip(urgent != null ? 1 : 0)
                            .map((d) => Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 8),
                                  child: _DeadlineRowWithCalendar(
                                    deadline: d,
                                    today: today,
                                    iconKey: Key(
                                        'case_file_calendar_export_${d.dedupeKey}'),
                                    onAddToCalendar: () =>
                                        _exportDeadlineToCalendar(d),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  if (state.events.isNotEmpty)
                    _buildSection(
                      title: l?.caseFileTimeline ?? 'Timeline',
                      child: _Timeline(events: _sortedEvents(state.events)),
                    ),
                  if (state.parties.isNotEmpty)
                    _buildSection(
                      title: l?.caseFileParties ?? 'Parties',
                      child: _PartyChips(parties: state.parties),
                    ),
                  // v24.4 — Long-horizon agent intentions (cron-fired
                  // follow-up promises). Self-hides when nothing is pending.
                  const PendingIntentionsSection(),
                  const SizedBox(height: 24),
                  _ExportButton(
                    label: l?.caseFileExportPdf ?? 'Download dossier (PDF)',
                    busy: _exporting,
                    onPressed: state.isEmpty ? null : _exportPdf,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l?.caseFileDisclaimer ??
                        'This dossier is auto-extracted from your chat. It is not legal advice.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }

  List<CaseEvent> _sortedEvents(List<CaseEvent> events) {
    final out = [...events];
    out.sort((a, b) {
      final da = a.date;
      final db = b.date;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });
    return out;
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  /// Build an .ics body for [deadline] and hand it to the platform share
  /// sheet (mobile) / browser download (web). The handler can be
  /// overridden in tests via [CaseFileScreen.icsHandlerOverride].
  Future<void> _exportDeadlineToCalendar(CaseDeadline deadline) async {
    final law = (deadline.law ?? '').trim();
    final descriptionParts = <String>[
      if (law.isNotEmpty) '${deadline.title} — $law' else deadline.title,
      'Open in Advocat: https://advocat.ee/case-file',
    ];
    final ics = IcsExportService.renderEvent(
      title: deadline.title,
      startDate: deadline.date,
      allDay: true,
      description: descriptionParts.join('\n'),
    );

    final handler = widget.icsHandlerOverride ?? _defaultIcsHandler;
    try {
      await handler(ics);
    } catch (e) {
      debugPrint('calendar export failed: $e');
      if (!mounted) return;
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l?.genericError ?? 'Something went wrong. Please try again.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _defaultIcsHandler(String icsBody) async {
    final bytes = Uint8List.fromList(icsBody.codeUnits);
    final filename =
        'advocat_deadline_${DateTime.now().millisecondsSinceEpoch}.ics';
    final xfile = XFile.fromData(
      bytes,
      name: filename,
      mimeType: 'text/calendar',
    );
    if (kIsWeb) {
      // share_plus on web triggers a browser download via blob URL.
      await Share.shareXFiles([xfile], subject: 'Advocat — deadline');
    } else {
      // Mobile/desktop — system share sheet (Calendar.app, etc.).
      await Share.shareXFiles([xfile], subject: 'Advocat — deadline');
    }
  }

  Future<void> _exportPdf() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final state = ref.read(caseFileProvider);
      final lang = Localizations.localeOf(context).languageCode;
      final markdown = CaseFileService.buildDossierMarkdown(
        events: state.events,
        parties: state.parties,
        deadlines: state.deadlines,
        today: DateTime.now(),
        locale: lang,
      );
      final bytes = await _pdfService.renderLegalDocument(
        markdown: markdown,
        title: AppLocalizations.of(context)?.caseFileTitle ?? 'Case File',
        language: lang,
      );
      await Printing.sharePdf(bytes: bytes, filename: 'case_file_$lang.pdf');
    } catch (e) {
      debugPrint('case-file PDF export failed: $e');
      if (!mounted) return;
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l?.genericError ?? 'Something went wrong. Please try again.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }
}

// ── Deadline + add-to-calendar icon ──────────────────────────────────────────

/// Lays out a [DeadlineCountdownCard] with an "add to calendar" icon button
/// on the trailing edge. Tapping the icon hands the deadline to the
/// parent screen's .ics export pipeline.
class _DeadlineRowWithCalendar extends StatelessWidget {
  const _DeadlineRowWithCalendar({
    required this.deadline,
    required this.today,
    required this.onAddToCalendar,
    required this.iconKey,
  });

  final CaseDeadline deadline;
  final DateTime today;
  final VoidCallback onAddToCalendar;
  final Key iconKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: DeadlineCountdownCard(deadline: deadline, today: today),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 8),
          child: IconButton(
            key: iconKey,
            icon: const Icon(Icons.calendar_today),
            color: AppColors.accent,
            tooltip: 'Add to calendar',
            onPressed: onAddToCalendar,
          ),
        ),
      ],
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open_outlined,
                size: 72, color: AppColors.textTertiary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Timeline ─────────────────────────────────────────────────────────────────

class _Timeline extends StatelessWidget {
  const _Timeline({required this.events});
  final List<CaseEvent> events;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final e in events) _TimelineRow(event: e),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.event});
  final CaseEvent event;

  @override
  Widget build(BuildContext context) {
    final dateLabel = event.date != null
        ? '${event.date!.year.toString().padLeft(4, '0')}-'
            '${event.date!.month.toString().padLeft(2, '0')}-'
            '${event.date!.day.toString().padLeft(2, '0')}'
        : '—';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(
              dateLabel,
              style: const TextStyle(
                fontSize: 12,
                fontFeatures: [ui.FontFeature.tabularFigures()],
                color: AppColors.textTertiary,
              ),
            ),
          ),
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 4, right: 12),
            decoration: BoxDecoration(
              color: _categoryColor(event.category),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (event.description != null && event.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      event.description!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _categoryColor(CaseEventCategory c) {
    switch (c) {
      case CaseEventCategory.decision:
        return AppColors.error;
      case CaseEventCategory.deadline:
        return AppColors.error;
      case CaseEventCategory.hearing:
        return AppColors.accent;
      case CaseEventCategory.submission:
        return AppColors.accent;
      case CaseEventCategory.communication:
        return AppColors.textTertiary;
      case CaseEventCategory.other:
        return AppColors.textTertiary;
    }
  }
}

// ── Party chips ──────────────────────────────────────────────────────────────

class _PartyChips extends StatelessWidget {
  const _PartyChips({required this.parties});
  final List<CaseParty> parties;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: parties.map((p) => _PartyChip(party: p)).toList(),
    );
  }
}

class _PartyChip extends StatelessWidget {
  const _PartyChip({required this.party});
  final CaseParty party;

  @override
  Widget build(BuildContext context) {
    final accent = _typeColor(party.type);
    return Tooltip(
      message: party.context ?? party.type.toWire(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: accent.withValues(alpha: 0.30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_typeIcon(party.type), size: 14, color: accent),
            const SizedBox(width: 6),
            Text(
              party.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(PartyType t) {
    switch (t) {
      case PartyType.authority:
        return Icons.shield_outlined;
      case PartyType.lawyer:
        return Icons.gavel;
      case PartyType.company:
        return Icons.business;
      case PartyType.person:
        return Icons.person_outline;
      case PartyType.other:
        return Icons.label_outline;
    }
  }

  Color _typeColor(PartyType t) {
    switch (t) {
      case PartyType.authority:
        return AppColors.error;
      case PartyType.lawyer:
        return AppColors.accent;
      case PartyType.company:
        return AppColors.accentDark;
      case PartyType.person:
        return AppColors.textSecondary;
      case PartyType.other:
        return AppColors.textTertiary;
    }
  }
}

// ── Export button ────────────────────────────────────────────────────────────

class _ExportButton extends StatelessWidget {
  const _ExportButton({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        key: const Key('case_file_export_pdf'),
        onPressed: busy ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        icon: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.picture_as_pdf_outlined),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

