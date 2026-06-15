// =============================================================================
// plain_language_screen.dart — "Объясни простыми словами" entry screen.
// =============================================================================
//
// The discoverable home for the plain-language explainer. Until now "explain
// it simply" existed only as a one-off prompt inside chat. This screen makes it
// a first-class flow:
//
//   1. Paste (or pre-fill via the `initialText` query param when launched from
//      a document) the legal text.
//   2. Pick a level: "как другу" (friend) / "с юр-терминами" (with terms).
//   3. Tap Explain → single-shot call to the explain-plain edge function.
//   4. Render TL;DR + paragraph breakdown + glossary + next steps.
//
// Language is auto-detected server-side from the pasted text (17 locales), so
// the screen sends no explicit `language` unless a caller passes one.
//
// UPL mitigation: the standard AiDisclaimerBanner.compact sits above the input,
// and the edge function appends the halt-rail advisory for serious-case text.
//
// Free users get 3 explanations/month; over the cap the screen shows an
// upgrade prompt linking to /subscription.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/ai_disclaimer_banner.dart';
import '../models/explain_result.dart';
import '../providers/explain_provider.dart';
import '../widgets/explain_result_view.dart';

/// Stable widget keys for tests.
const Key kExplainInputField = Key('explainPlain.input');
const Key kExplainSubmitButton = Key('explainPlain.submit');

class PlainLanguageScreen extends ConsumerStatefulWidget {
  const PlainLanguageScreen({super.key, this.initialText, this.caseId});

  /// Optional pre-filled text (e.g. launched from a document with a selection).
  final String? initialText;

  /// Optional case link, persisted with the explanation for history grouping.
  final String? caseId;

  @override
  ConsumerState<PlainLanguageScreen> createState() =>
      _PlainLanguageScreenState();
}

class _PlainLanguageScreenState extends ConsumerState<PlainLanguageScreen> {
  late final TextEditingController _controller;

  static const int _minChars = 20;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.length < _minChars) return;
    FocusScope.of(context).unfocus();
    ref.read(explainProvider.notifier).explain(
          sourceText: text,
          caseId: widget.caseId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(explainProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.explainPlainTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.explainPlainIntro,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              const AiDisclaimerBanner.compact(),
              const SizedBox(height: 12),
              _LevelPicker(
                level: state.level,
                onChanged: state.isLoading
                    ? null
                    : (lvl) => ref.read(explainProvider.notifier).setLevel(lvl),
                friendLabel: l10n.explainPlainLevelFriend,
                termsLabel: l10n.explainPlainLevelTerms,
              ),
              const SizedBox(height: 12),
              TextField(
                key: kExplainInputField,
                controller: _controller,
                enabled: !state.isLoading,
                minLines: 6,
                maxLines: 16,
                maxLength: 200000,
                decoration: InputDecoration(
                  hintText: l10n.explainPlainInputHint,
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 50,
                child: FilledButton.icon(
                  key: kExplainSubmitButton,
                  onPressed: state.isLoading ? null : _submit,
                  icon: state.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(
                    state.isLoading
                        ? l10n.explainPlainWorking
                        : l10n.explainPlainSubmit,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _ResultArea(
                state: state,
                onUpgrade: () => context.push(AppRoutes.subscription),
                onRetry: _submit,
                onGlossaryRefTap: (ref) => context.push(AppRoutes.docSearch),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelPicker extends StatelessWidget {
  const _LevelPicker({
    required this.level,
    required this.onChanged,
    required this.friendLabel,
    required this.termsLabel,
  });

  final ExplainLevel level;
  final ValueChanged<ExplainLevel>? onChanged;
  final String friendLabel;
  final String termsLabel;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ExplainLevel>(
      segments: [
        ButtonSegment(
          value: ExplainLevel.friend,
          label: Text(friendLabel),
          icon: const Icon(Icons.emoji_people, size: 18),
        ),
        ButtonSegment(
          value: ExplainLevel.withTerms,
          label: Text(termsLabel),
          icon: const Icon(Icons.gavel, size: 18),
        ),
      ],
      selected: {level},
      onSelectionChanged: onChanged == null
          ? null
          : (s) => onChanged!(s.first),
    );
  }
}

class _ResultArea extends StatelessWidget {
  const _ResultArea({
    required this.state,
    required this.onUpgrade,
    required this.onRetry,
    required this.onGlossaryRefTap,
  });

  final ExplainState state;
  final VoidCallback onUpgrade;
  final VoidCallback onRetry;
  final void Function(String ref) onGlossaryRefTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (state.phase) {
      case ExplainPhase.idle:
      case ExplainPhase.loading:
        return const SizedBox.shrink();
      case ExplainPhase.success:
        final result = state.result;
        if (result == null) return const SizedBox.shrink();
        return ExplainResultView(
          body: result.body,
          onGlossaryRefTap: onGlossaryRefTap,
        );
      case ExplainPhase.quotaExceeded:
        return _QuotaCard(
          title: l10n.explainPlainQuotaTitle,
          message: l10n.explainPlainQuotaBody,
          cta: l10n.explainPlainUpgradeCta,
          onUpgrade: onUpgrade,
        );
      case ExplainPhase.error:
        return _ErrorCard(
          message: l10n.explainPlainError,
          retry: l10n.explainPlainRetry,
          onRetry: onRetry,
        );
    }
  }
}

class _QuotaCard extends StatelessWidget {
  const _QuotaCard({
    required this.title,
    required this.message,
    required this.cta,
    required this.onUpgrade,
  });

  final String title;
  final String message;
  final String cta;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onUpgrade, child: Text(cta)),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.retry,
    required this.onRetry,
  });

  final String message;
  final String retry;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(retry),
          ),
        ],
      ),
    );
  }
}
