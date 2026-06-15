// demand_letter/screens/demand_letter_preview_screen.dart — Feature #2.
// -----------------------------------------------------------------------------
// Shows the composed demand letter: the markdown body, the cited legal-norm
// chips, and actions — copy to clipboard, export to a print-ready PDF (via the
// existing pdf-generator), and a "send via email" hand-off. Nothing is sent
// automatically; the user must explicitly trigger any dispatch.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../models/demand_letter.dart';
import '../services/demand_letter_service.dart';

class DemandLetterPreviewScreen extends ConsumerStatefulWidget {
  const DemandLetterPreviewScreen({
    super.key,
    required this.result,
    required this.locale,
    this.caseId,
  });

  final DemandLetterResult result;
  final String locale;
  final String? caseId;

  @override
  ConsumerState<DemandLetterPreviewScreen> createState() =>
      _DemandLetterPreviewScreenState();
}

class _DemandLetterPreviewScreenState
    extends ConsumerState<DemandLetterPreviewScreen> {
  bool _exporting = false;

  Future<void> _copy(AppLocalizations l10n) async {
    await Clipboard.setData(ClipboardData(text: widget.result.markdown));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.demandLetterCopied)),
    );
  }

  Future<void> _exportPdf(AppLocalizations l10n) async {
    setState(() => _exporting = true);
    try {
      final service = ref.read(demandLetterServiceProvider);
      final export = await service.exportPdf(
        title: widget.result.subject,
        markdown: widget.result.markdown,
        locale: widget.locale,
        caseId: widget.caseId,
      );
      final uri = Uri.tryParse(export.downloadUrl);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.demandLetterExportFailed)),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final r = widget.result;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.demandLetterPreviewTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(r.subject, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (r.norms.isNotEmpty) ...[
            Text(l10n.demandLetterNormsTitle,
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: r.norms
                  .map((n) => Chip(label: Text(n.label)))
                  .toList(growable: false),
            ),
            const SizedBox(height: 16),
          ],
          SelectableText(r.markdown),
          const SizedBox(height: 24),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => _copy(l10n),
                icon: const Icon(Icons.copy),
                label: Text(l10n.demandLetterCopy),
              ),
              FilledButton.icon(
                onPressed: _exporting ? null : () => _exportPdf(l10n),
                icon: const Icon(Icons.picture_as_pdf),
                label: Text(_exporting
                    ? l10n.demandLetterExporting
                    : l10n.demandLetterExportPdf),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
