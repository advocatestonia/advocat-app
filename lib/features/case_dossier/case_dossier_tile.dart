// case_dossier_tile.dart
// ---------------------------------------------------------------------------
// Entry-point tile for the Case Dossier Export. Drop this into any case
// actions list (e.g. the case detail screen's action section) — it navigates
// to the `caseDossier` route without that host needing to know anything about
// the export flow.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/router.dart';
import '../../l10n/app_localizations.dart';

class CaseDossierTile extends StatelessWidget {
  const CaseDossierTile({
    super.key,
    required this.caseId,
    this.caseTitle,
  });

  final String caseId;
  final String? caseTitle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      leading: const Icon(Icons.picture_as_pdf_outlined),
      title: Text(l10n.caseDossierTileTitle),
      subtitle: Text(l10n.caseDossierTileSubtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push(
        AppRoutes.caseDossier.replaceFirst(':id', caseId),
        extra: caseTitle,
      ),
    );
  }
}
