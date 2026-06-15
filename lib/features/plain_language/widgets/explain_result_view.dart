// =============================================================================
// explain_result_view.dart — renders an ExplainResult into readable sections.
// =============================================================================
//
// Layout (top → bottom):
//   1. TL;DR card  — the bottom line, 1–2 lines, high-emphasis.
//   2. Paragraphs  — section-by-section plain re-statement.
//   3. Glossary    — contentious terms; tappable when a corpus `ref` exists.
//   4. Next steps  — neutral, document-implied actions (checklist style).
//
// Glossary refs deep-link into the legal corpus via the doc-search route when
// present; the callback is injected so this widget stays route-agnostic.
// =============================================================================

import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../models/explain_result.dart';

class ExplainResultView extends StatelessWidget {
  const ExplainResultView({
    super.key,
    required this.body,
    this.onGlossaryRefTap,
  });

  final ExplainBody body;

  /// Called with a corpus slug when the user taps a glossary term that carries
  /// a `ref`. Null → terms render as plain text.
  final void Function(String ref)? onGlossaryRefTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final children = <Widget>[];

    if (body.tldr.isNotEmpty) {
      children.add(_TldrCard(lines: body.tldr, label: l10n.explainPlainTldr));
    }

    if (body.paragraphs.isNotEmpty) {
      children.add(_SectionHeader(l10n.explainPlainBreakdown));
      for (final p in body.paragraphs) {
        children.add(_ParagraphTile(paragraph: p));
      }
    }

    if (body.glossary.isNotEmpty) {
      children.add(_SectionHeader(l10n.explainPlainGlossary));
      for (final g in body.glossary) {
        children.add(
          _GlossaryTile(
            entry: g,
            onRefTap: onGlossaryRefTap,
            refHint: l10n.explainPlainOpenInCorpus,
          ),
        );
      }
    }

    if (body.nextSteps.isNotEmpty) {
      children.add(_SectionHeader(l10n.explainPlainNextSteps));
      for (final s in body.nextSteps) {
        children.add(_NextStepTile(text: s));
      }
    }

    if (children.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          l10n.explainPlainEmptyResult,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

class _TldrCard extends StatelessWidget {
  const _TldrCard({required this.lines, required this.label});

  final List<String> lines;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt, size: 18, color: AppColors.accentDark),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentDark,
                  fontSize: 13,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                line,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _ParagraphTile extends StatelessWidget {
  const _ParagraphTile({required this.paragraph});
  final ExplainParagraph paragraph;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (paragraph.heading.isNotEmpty) ...[
            Text(
              paragraph.heading,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            paragraph.plain,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlossaryTile extends StatelessWidget {
  const _GlossaryTile({
    required this.entry,
    required this.refHint,
    this.onRefTap,
  });

  final ExplainGlossaryEntry entry;
  final String refHint;
  final void Function(String ref)? onRefTap;

  @override
  Widget build(BuildContext context) {
    final hasRef = entry.ref != null && onRefTap != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.term,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            entry.plain,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: AppColors.textPrimary,
            ),
          ),
          if (hasRef) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () => onRefTap!(entry.ref!),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.menu_book_outlined,
                      size: 15, color: AppColors.accentDark),
                  const SizedBox(width: 4),
                  Text(
                    refHint,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.accentDark,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NextStepTile extends StatelessWidget {
  const _NextStepTile({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2, right: 8),
            child: Icon(Icons.arrow_forward, size: 16, color: AppColors.accent),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                height: 1.45,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
