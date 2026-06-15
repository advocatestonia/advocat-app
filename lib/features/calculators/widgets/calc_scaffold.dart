// calc_scaffold.dart — common shell for the four calculator screens.
// -----------------------------------------------------------------------------
// Loads the jurisdiction's rate bundle (network → fallback), shows the
// "rates as of <date>" / offline header + the indicative banner, then hands the
// resolved CalcRates to the calculator-specific body builder.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/ai_disclaimer_banner.dart';
import '../data/calc_rates.dart';
import '../data/calc_rates_provider.dart';
import 'calc_shared_widgets.dart';

class CalcScaffold extends ConsumerWidget {
  const CalcScaffold({
    super.key,
    required this.title,
    required this.jurisdiction,
    required this.bodyBuilder,
  });

  final String title;
  final String jurisdiction;
  final Widget Function(BuildContext context, CalcRates rates) bodyBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final ratesAsync = ref.watch(calcRatesProvider(jurisdiction));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: ratesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        // Provider never throws (falls back internally), but guard anyway.
        error: (_, __) => _content(context, l10n, fallbackFor(jurisdiction)),
        data: (rates) => _content(context, l10n, rates),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    AppLocalizations l10n,
    CalcRates rates,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rates freshness line.
          Row(
            children: [
              Icon(
                rates.fromNetwork ? Icons.cloud_done_outlined : Icons.cloud_off,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                rates.fromNetwork
                    ? l10n.calcRatesAsOf(rates.asOf)
                    : '${l10n.calcRatesAsOf(rates.asOf)} · ${l10n.calcRatesOffline}',
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          CalcIndicativeBanner(text: l10n.calcIndicativeBanner),
          const SizedBox(height: AppSpacing.lg),
          bodyBuilder(context, rates),
          const SizedBox(height: AppSpacing.md),
          const AiDisclaimerBanner.compact(),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
