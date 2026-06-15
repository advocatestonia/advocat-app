import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/ai_disclaimer_banner.dart';
import '../providers/cost_estimator_provider.dart';
import '../widgets/estimate_result_card.dart';

// ---------------------------------------------------------------------------
// Cost & Risk Estimator Screen (Feature #6)
//
// "How much will this cost and is it worth it?" — the user fills a short form
// (case type, jurisdiction, amount, optional description) and gets back a
// rough cost/duration band + a strength traffic-light. Designed to convert
// undecided B2C users ("ok, I'll go Pro") and to let B2B firms quickly
// qualify an inbound lead (compact card mode).
// ---------------------------------------------------------------------------

class CostEstimatorScreen extends ConsumerStatefulWidget {
  const CostEstimatorScreen({super.key});

  @override
  ConsumerState<CostEstimatorScreen> createState() =>
      _CostEstimatorScreenState();
}

class _CostEstimatorScreenState extends ConsumerState<CostEstimatorScreen> {
  final _caseTypeController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _caseTypeController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(costEstimatorProvider);
    final notifier = ref.read(costEstimatorProvider.notifier);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n?.costEstimateTitle ?? 'Cost & Risk Estimator',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => context.pop(),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // ── Intro / subtitle ─────────────────────────────────────────
            Text(
              l10n?.costEstimateSubtitle ??
                  'Get a rough idea of what a case might cost, how long it '
                      'could take, and whether it is worth pursuing.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Case type ────────────────────────────────────────────────
            TextField(
              controller: _caseTypeController,
              onChanged: notifier.setCaseType,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n?.costEstimateCaseTypeLabel ?? 'Type of case',
                hintText: l10n?.costEstimateCaseTypeHint ??
                    'e.g. unpaid invoice, wrongful dismissal, deposit dispute',
                prefixIcon: const Icon(Icons.gavel_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Jurisdiction ─────────────────────────────────────────────
            DropdownButtonFormField<String>(
              initialValue: state.jurisdiction,
              decoration: InputDecoration(
                labelText: l10n?.costEstimateJurisdictionLabel ?? 'Jurisdiction',
                prefixIcon: const Icon(Icons.public_outlined),
              ),
              items: kEstimatorJurisdictions.entries
                  .map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) notifier.setJurisdiction(v);
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Amount in dispute (optional) ─────────────────────────────
            TextField(
              controller: _amountController,
              onChanged: notifier.setDisputeAmount,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n?.costEstimateAmountLabel ??
                    'Amount in dispute (optional)',
                hintText: l10n?.costEstimateAmountHint ?? 'e.g. 12500',
                prefixIcon: const Icon(Icons.euro_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Description (optional) ───────────────────────────────────
            TextField(
              controller: _descriptionController,
              onChanged: notifier.setDescription,
              maxLines: 4,
              maxLength: 1000,
              decoration: InputDecoration(
                labelText: l10n?.costEstimateDescriptionLabel ??
                    'Briefly describe the situation (optional)',
                alignLabelWithHint: true,
              ),
            ),

            // ── B2B mode toggle ──────────────────────────────────────────
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: state.b2bMode,
              onChanged: notifier.setB2bMode,
              activeThumbColor: AppColors.accent,
              title: Text(
                l10n?.costEstimateB2bToggle ?? 'Lead-qualification card (B2B)',
                style: theme.textTheme.bodyMedium,
              ),
              subtitle: Text(
                l10n?.costEstimateB2bSubtitle ??
                    'Compact output for quickly triaging an inbound client.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textTertiary),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // ── Submit ───────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: state.canSubmit
                    ? () {
                        HapticFeedback.mediumImpact();
                        FocusScope.of(context).unfocus();
                        notifier.submit();
                      }
                    : null,
                icon: state.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.calculate_outlined),
                label: Text(
                  state.isLoading
                      ? (l10n?.loading ?? 'Estimating...')
                      : (l10n?.costEstimateSubmit ?? 'Estimate my case'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
            ),

            // ── Error ────────────────────────────────────────────────────
            if (state.errorMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border:
                      Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.error, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        state.errorMessage!,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Result ───────────────────────────────────────────────────
            if (state.estimate != null) ...[
              const SizedBox(height: AppSpacing.lg),
              const AiDisclaimerBanner.compact(
                key: Key('cost_estimator_ai_disclaimer_banner'),
              ),
              const SizedBox(height: AppSpacing.sm),
              EstimateResultCard(
                estimate: state.estimate!,
                b2bMode: state.b2bMode,
                onNextStep: () => context.go(AppRoutes.caseCreate),
              ),
            ],

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
