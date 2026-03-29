import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../providers/company_checker_provider.dart';
import '../widgets/company_report_card.dart';

/// Screen for checking a company's reliability before doing business with them.
class CompanyCheckerScreen extends ConsumerStatefulWidget {
  const CompanyCheckerScreen({super.key});

  @override
  ConsumerState<CompanyCheckerScreen> createState() =>
      _CompanyCheckerScreenState();
}

class _CompanyCheckerScreenState extends ConsumerState<CompanyCheckerScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(companyCheckerProvider);
    final notifier = ref.read(companyCheckerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Check Company'),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // Search field
            TextField(
              controller: _searchController,
              onChanged: notifier.setQuery,
              decoration: const InputDecoration(
                hintText: 'Company name or reg. number',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => notifier.checkCompany(),
            ),
            const SizedBox(height: AppSpacing.md),

            // Country selector
            DropdownButtonFormField<String>(
              initialValue: state.selectedCountry,
              onChanged: (value) {
                if (value != null) notifier.setCountry(value);
              },
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.public_rounded),
              ),
              items: checkerCountries
                  .map((c) => DropdownMenuItem(
                        value: c.code,
                        child: Text('${c.flag}  ${c.name}'),
                      ))
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Check button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed:
                    state.status == CheckerStatus.loading ? null : () => notifier.checkCompany(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: state.status == CheckerStatus.loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Check Company'),
              ),
            ),

            // Price badge
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: const Text(
                  '\u20AC2.99 per check  \u2022  Included in Pro',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Error state
            if (state.status == CheckerStatus.error && state.errorMessage != null)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(color: AppColors.error, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),

            // Results
            if (state.status == CheckerStatus.results && state.report != null)
              CompanyReportCard(report: state.report!),

            // Idle hint
            if (state.status == CheckerStatus.idle) ...[
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.business_center_outlined,
                        size: 36,
                        color: AppColors.accent.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'Enter a company name or registration\nnumber to get a full report',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
