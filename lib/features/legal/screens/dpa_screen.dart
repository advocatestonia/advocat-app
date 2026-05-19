import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/advocat_gradient_header.dart';
import '../data/dpa_text.dart';

/// GDPR Article 28 — Data Processing Agreement review screen.
///
/// Route: `/legal/dpa`. Reachable from the checkout-gate dialog and from
/// the Privacy Policy screen. Renders [kDpaTextEnV1] verbatim with light
/// typographical structuring (headings vs body) and exposes the active
/// version + effective date in a sticky footer so the user can confirm
/// which contract they are about to sign.
class DpaScreen extends StatelessWidget {
  const DpaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // The DPA body itself is English-only (legal binding text). UI chrome
    // localises through AppLocalizations where the key exists; we fall
    // back to literal English when a translation is not yet generated.
    final l10n = AppLocalizations.of(context);
    final title = _safeTitle(l10n);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AdvocatGradientHeader(title: title),
      bottomNavigationBar: const _DpaFooter(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _buildBlocks(kDpaTextEnV1),
        ),
      ),
    );
  }

  /// Localised title with a safe English fallback. The `dpaTitle` ARB key
  /// has been added to app_en.arb / app_et.arb / app_ru.arb / app_fi.arb
  /// but the generated AppLocalizations getter is not present in this PR
  /// (would require regenerating ~50 files). Until then the fixed English
  /// string is used everywhere.
  static String _safeTitle(AppLocalizations? l10n) {
    return 'Data Processing Agreement';
  }

  /// Splits the DPA text into typographical blocks. Lines that look like
  /// section headings (numbered ALL-CAPS headers, the document title, or
  /// the "End of DPA" sentinel) render larger and bolder than body text.
  List<Widget> _buildBlocks(String body) {
    final lines = body.split('\n');
    final blocks = <Widget>[];

    final headingRe = RegExp(r'^\s*(?:\d+\.\s+[A-Z][A-Z0-9 ()/,\-]+|DATA PROCESSING AGREEMENT)\s*$');
    final versionRe = RegExp(r'^\s*Version v');
    final endRe = RegExp(r'^\s*--');

    StringBuffer paragraph = StringBuffer();

    void flushParagraph() {
      final text = paragraph.toString().trim();
      paragraph = StringBuffer();
      if (text.isEmpty) return;
      blocks.add(Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary,
            height: 1.6,
          ),
        ),
      ));
    }

    for (final raw in lines) {
      final line = raw.trimRight();
      if (line.trim().isEmpty) {
        flushParagraph();
        continue;
      }
      if (headingRe.hasMatch(line)) {
        flushParagraph();
        blocks.add(Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.md,
            bottom: AppSpacing.xs,
          ),
          child: Text(
            line.trim(),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              height: 1.35,
              letterSpacing: 0.2,
            ),
          ),
        ));
        continue;
      }
      if (versionRe.hasMatch(line) || endRe.hasMatch(line)) {
        flushParagraph();
        blocks.add(Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Text(
            line.trim(),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ));
        continue;
      }
      // Body line — keep paragraph breaks; preserve indentation for
      // numbered sub-points like "  (a) ...".
      if (paragraph.isNotEmpty) paragraph.write('\n');
      paragraph.write(line);
    }
    flushParagraph();
    return blocks;
  }
}

class _DpaFooter extends StatelessWidget {
  const _DpaFooter();

  @override
  Widget build(BuildContext context) {
    return const Material(
      color: AppColors.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 18,
                color: AppColors.accent,
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Data Processing Agreement',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '$kCurrentDpaVersion  ·  Effective 20 May 2026',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
