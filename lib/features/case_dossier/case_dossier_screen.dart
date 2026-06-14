// case_dossier_screen.dart
// ---------------------------------------------------------------------------
// Case Dossier Export — section-preview screen.
//
// Lets the user pick which sections (chronology / deadlines / documents / AI
// summary) to include, then taps "Export PDF". The backend
// (`case-dossier-export` edge function) aggregates the case, renders one
// dossier document, and returns a signed download URL which we open / share.
//
// This screen is reached via the `caseDossier` route (`/cases/:id/dossier`)
// so it can be added without editing case_detail_screen.dart — a single tile
// pushes here.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../shared/widgets/max_width_wrapper.dart';
import 'case_dossier_service.dart';

class CaseDossierScreen extends ConsumerStatefulWidget {
  const CaseDossierScreen({
    super.key,
    required this.caseId,
    this.caseTitle,
  });

  final String caseId;
  final String? caseTitle;

  @override
  ConsumerState<CaseDossierScreen> createState() => _CaseDossierScreenState();
}

class _CaseDossierScreenState extends ConsumerState<CaseDossierScreen> {
  DossierSectionToggles _sections = const DossierSectionToggles();
  bool _busy = false;
  DossierExportResult? _lastResult;

  Future<void> _export() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _busy = true;
      _lastResult = null;
    });

    final locale = Localizations.localeOf(context).languageCode;
    final result = await ref.read(caseDossierServiceProvider).export(
          caseId: widget.caseId,
          sections: _sections,
          locale: locale,
        );

    if (!mounted) return;
    setState(() {
      _busy = false;
      _lastResult = result;
    });

    final messenger = ScaffoldMessenger.of(context);
    if (result.ok) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.caseDossierSuccess)),
      );
    } else {
      final msg = result.errorCode != null &&
              result.errorCode!.contains('not found')
          ? l10n.caseDossierErrorNotOwned
          : l10n.caseDossierError;
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _open() async {
    final url = _lastResult?.downloadUrl;
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _share() async {
    final url = _lastResult?.downloadUrl;
    if (url == null) return;
    await Share.share(url);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.caseDossierTitle)),
      body: MaxWidthWrapper(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              widget.caseTitle ?? l10n.caseDossierTitle,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.caseDossierSubtitle,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.caseDossierSectionsHeading,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            // Facts — always included, shown disabled for transparency.
            SwitchListTile(
              value: true,
              onChanged: null,
              title: Text(l10n.caseDossierSectionFacts),
              subtitle: Text(l10n.caseDossierSectionFactsHint),
            ),
            SwitchListTile(
              value: _sections.timeline,
              onChanged: _busy
                  ? null
                  : (v) => setState(
                        () => _sections = _sections.copyWith(timeline: v),
                      ),
              title: Text(l10n.caseDossierSectionTimeline),
            ),
            SwitchListTile(
              value: _sections.deadlines,
              onChanged: _busy
                  ? null
                  : (v) => setState(
                        () => _sections = _sections.copyWith(deadlines: v),
                      ),
              title: Text(l10n.caseDossierSectionDeadlines),
            ),
            SwitchListTile(
              value: _sections.documents,
              onChanged: _busy
                  ? null
                  : (v) => setState(
                        () => _sections = _sections.copyWith(documents: v),
                      ),
              title: Text(l10n.caseDossierSectionDocuments),
            ),
            SwitchListTile(
              value: _sections.aiSummary,
              onChanged: _busy
                  ? null
                  : (v) => setState(
                        () => _sections = _sections.copyWith(aiSummary: v),
                      ),
              title: Text(l10n.caseDossierSectionAiSummary),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.caseDossierDisclaimer,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _busy ? null : _export,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined),
              label: Text(
                _busy ? l10n.caseDossierExporting : l10n.caseDossierExportButton,
              ),
            ),
            if (_lastResult?.ok == true) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _open,
                      icon: const Icon(Icons.open_in_new),
                      label: Text(l10n.caseDossierOpen),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.outlined(
                    onPressed: _share,
                    icon: const Icon(Icons.ios_share),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
