import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
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
  final _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      setState(() => _isSearchFocused = _searchFocusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(companyCheckerProvider);
    final notifier = ref.read(companyCheckerProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.checkCompany,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
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
            // Search field with glow on focus
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                boxShadow: _isSearchFocused
                    ? [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.2),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: notifier.setQuery,
                decoration: InputDecoration(
                  hintText: l10n.companyCheckerHint,
                  prefixIcon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.search_rounded,
                      key: ValueKey(_isSearchFocused),
                      color: _isSearchFocused ? AppColors.accent : AppColors.textTertiary,
                    ),
                  ),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => notifier.checkCompany(),
              ),
            )
                .animate()
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.08, end: 0, duration: 300.ms),

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
            )
                .animate()
                .fadeIn(delay: 100.ms, duration: 300.ms)
                .slideY(begin: 0.08, end: 0, delay: 100.ms, duration: 300.ms),

            const SizedBox(height: AppSpacing.lg),

            // Check button with glow
            _GlowCheckButton(
              isLoading: state.status == CheckerStatus.loading,
              label: l10n.checkCompany,
              onPressed: () {
                HapticFeedback.mediumImpact();
                notifier.checkCompany();
              },
            )
                .animate()
                .fadeIn(delay: 200.ms, duration: 300.ms)
                .slideY(begin: 0.08, end: 0, delay: 200.ms, duration: 300.ms),

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
                child: Text(
                  l10n.companyCheckerPriceChip,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 300.ms),

            const SizedBox(height: AppSpacing.xl),

            // Error state
            if (state.status == CheckerStatus.error && state.errorMessage != null)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.error.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
              )
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .shakeX(hz: 3, amount: 4, duration: 400.ms),

            // Results with slide-in animation
            if (state.status == CheckerStatus.results && state.report != null)
              CompanyReportCard(report: state.report!)
                  .animate()
                  .fadeIn(duration: 500.ms, curve: Curves.easeOut)
                  .slideY(begin: 0.1, end: 0, duration: 500.ms, curve: Curves.easeOutCubic),

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
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.06),
                            blurRadius: 24,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.business_center_outlined,
                        size: 36,
                        color: AppColors.accent.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.companyCheckerEmptyState,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 500.ms)
                  .slideY(begin: 0.08, end: 0, delay: 400.ms, duration: 500.ms),
            ],

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

// ── Glow Check Button ────────────────────────────────────────────────────

class _GlowCheckButton extends StatefulWidget {
  const _GlowCheckButton({
    required this.isLoading,
    required this.label,
    required this.onPressed,
  });

  final bool isLoading;
  final String label;
  final VoidCallback onPressed;

  @override
  State<_GlowCheckButton> createState() => _GlowCheckButtonState();
}

class _GlowCheckButtonState extends State<_GlowCheckButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isLoading ? null : (_) => setState(() => _isPressed = true),
      onTapUp: widget.isLoading
          ? null
          : (_) {
              setState(() => _isPressed = false);
              widget.onPressed();
            },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            color: widget.isLoading
                ? AppColors.accent.withValues(alpha: 0.7)
                : AppColors.accent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: _isPressed ? 0.15 : 0.35),
                blurRadius: _isPressed ? 6 : 16,
                offset: Offset(0, _isPressed ? 2 : 6),
                spreadRadius: _isPressed ? -2 : 0,
              ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
