import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/vehicle_checker_provider.dart';
import '../widgets/vehicle_report_card.dart';

// ---------------------------------------------------------------------------
// Vehicle Checker Screen — check any vehicle before buying
// ---------------------------------------------------------------------------

class VehicleCheckerScreen extends ConsumerStatefulWidget {
  const VehicleCheckerScreen({super.key});

  @override
  ConsumerState<VehicleCheckerScreen> createState() =>
      _VehicleCheckerScreenState();
}

class _VehicleCheckerScreenState extends ConsumerState<VehicleCheckerScreen> {
  final _controller = TextEditingController();
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
    _controller.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vehicleCheckerProvider);
    final notifier = ref.read(vehicleCheckerProvider.notifier);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n?.vehicleChecker ?? 'Vehicle Checker',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
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
            // ── Price badge ──────────────────────────────────────────────
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  l10n?.pricePerCheck ?? '\u20ac4.99 per check',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 300.ms)
                .slideY(begin: -0.1, end: 0, duration: 300.ms),

            const SizedBox(height: AppSpacing.lg),

            // ── Input Mode Toggle ────────────────────────────────────────
            _InputModeToggle(
              mode: state.inputMode,
              onChanged: (mode) {
                notifier.setInputMode(mode);
                _controller.clear();
              },
              l10n: l10n,
            )
                .animate()
                .fadeIn(delay: 100.ms, duration: 300.ms)
                .slideY(begin: 0.08, end: 0, delay: 100.ms, duration: 300.ms),

            const SizedBox(height: AppSpacing.md),

            // ── Country Selector (only for license plate mode) ───────────
            if (state.inputMode == VehicleInputMode.licensePlate) ...[
              _CountrySelector(
                selectedCode: state.countryCode,
                onChanged: notifier.setCountryCode,
              )
                  .animate()
                  .fadeIn(duration: 250.ms)
                  .slideY(begin: 0.05, end: 0, duration: 250.ms),
              const SizedBox(height: AppSpacing.md),
            ],

            // ── Input Field with glow on focus ───────────────────────────
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
                controller: _controller,
                focusNode: _searchFocusNode,
                onChanged: notifier.setQuery,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: state.inputMode == VehicleInputMode.licensePlate
                      ? (l10n?.licensePlate ?? 'License plate')
                      : (l10n?.vinNumber ?? 'VIN number'),
                  prefixIcon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      state.inputMode == VehicleInputMode.licensePlate
                          ? Icons.pin_outlined
                          : Icons.qr_code_outlined,
                      key: ValueKey('${state.inputMode}_$_isSearchFocused'),
                      color: _isSearchFocused ? AppColors.accent : null,
                    ),
                  ),
                  suffixIcon: state.query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _controller.clear();
                            notifier.clearResults();
                          },
                        )
                      : null,
                ),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
            )
                .animate()
                .fadeIn(delay: 200.ms, duration: 300.ms)
                .slideY(begin: 0.08, end: 0, delay: 200.ms, duration: 300.ms),

            const SizedBox(height: AppSpacing.md),

            // ── Check Button with glow ─────────────────────────────────
            _GlowVehicleCheckButton(
              isLoading: state.isLoading,
              label: state.isLoading
                  ? (l10n?.loading ?? 'Loading...')
                  : (l10n?.checkVehicle ?? 'Check Vehicle'),
              onPressed: () {
                HapticFeedback.mediumImpact();
                notifier.checkVehicle();
              },
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 300.ms)
                .slideY(begin: 0.08, end: 0, delay: 300.ms, duration: 300.ms),

            // ── Demo Hint ────────────────────────────────────────────────
            if (state.report == null && !state.isLoading) ...[
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Text(
                  l10n?.demoHint ?? 'Demo: try plate "908FBT"',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 300.ms),
            ],

            // ── Error Message ────────────────────────────────────────────
            if (state.errorMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
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
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .shakeX(hz: 3, amount: 4, duration: 400.ms),
            ],

            // ── Report Results with stagger animation ─────────────────
            if (state.report != null) ...[
              const SizedBox(height: AppSpacing.lg),
              VehicleReportCard(
                report: state.report!,
                onReportFraud: state.report!.mileageFraudSuspected
                    ? () => _showFraudDialog(context)
                    : null,
                onOpenCase: () => context.go(AppRoutes.caseCreate),
              )
                  .animate()
                  .fadeIn(duration: 500.ms, curve: Curves.easeOut)
                  .slideY(begin: 0.1, end: 0, duration: 500.ms, curve: Curves.easeOutCubic),
            ],

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  void _showFraudDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        title: Text(AppLocalizations.of(context)?.reportMileageFraud ?? 'Report Mileage Fraud'),
        content: Text(
          AppLocalizations.of(context)?.reportMileageFraudDesc ?? 'This will create a fraud report based on the vehicle check data. You can also open a legal case for further action.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go(AppRoutes.caseCreate);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            child: Text(AppLocalizations.of(context)?.reportAndOpenCase ?? 'Report & Open Case'),
          ),
        ],
      ),
    );
  }
}

// ── Glow Vehicle Check Button ────────────────────────────────────────────

class _GlowVehicleCheckButton extends StatefulWidget {
  const _GlowVehicleCheckButton({
    required this.isLoading,
    required this.label,
    required this.onPressed,
  });

  final bool isLoading;
  final String label;
  final VoidCallback onPressed;

  @override
  State<_GlowVehicleCheckButton> createState() => _GlowVehicleCheckButtonState();
}

class _GlowVehicleCheckButtonState extends State<_GlowVehicleCheckButton> {
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
          height: 52,
          decoration: BoxDecoration(
            color: widget.isLoading
                ? AppColors.accent.withValues(alpha: 0.7)
                : AppColors.accent,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: _isPressed ? 0.15 : 0.35),
                blurRadius: _isPressed ? 6 : 16,
                offset: Offset(0, _isPressed ? 2 : 6),
                spreadRadius: _isPressed ? -2 : 0,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                const Icon(Icons.search, color: Colors.white),
              const SizedBox(width: AppSpacing.sm),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Input Mode Toggle ──────────────────────────────────────────────────────

class _InputModeToggle extends StatelessWidget {
  const _InputModeToggle({
    required this.mode,
    required this.onChanged,
    this.l10n,
  });

  final VehicleInputMode mode;
  final ValueChanged<VehicleInputMode> onChanged;
  final AppLocalizations? l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        boxShadow: AppShadows.shadowSmall,
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _ToggleOption(
            label: l10n?.licensePlate ?? 'License plate',
            icon: Icons.pin_outlined,
            isSelected: mode == VehicleInputMode.licensePlate,
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(VehicleInputMode.licensePlate);
            },
          ),
          _ToggleOption(
            label: l10n?.vinNumber ?? 'VIN number',
            icon: Icons.qr_code_outlined,
            isSelected: mode == VehicleInputMode.vin,
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(VehicleInputMode.vin);
            },
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  const _ToggleOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm - 2),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : AppColors.textTertiary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isSelected ? Colors.white : AppColors.textTertiary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Country Selector ───────────────────────────────────────────────────────

class _CountrySelector extends StatelessWidget {
  const _CountrySelector({
    required this.selectedCode,
    required this.onChanged,
  });

  final String selectedCode;
  final ValueChanged<String> onChanged;

  static const _flags = <String, String>{
    'EE': '\u{1F1EA}\u{1F1EA}',
    'FI': '\u{1F1EB}\u{1F1EE}',
    'LV': '\u{1F1F1}\u{1F1FB}',
    'LT': '\u{1F1F1}\u{1F1F9}',
    'SE': '\u{1F1F8}\u{1F1EA}',
    'DE': '\u{1F1E9}\u{1F1EA}',
    'PL': '\u{1F1F5}\u{1F1F1}',
    'FR': '\u{1F1EB}\u{1F1F7}',
    'IT': '\u{1F1EE}\u{1F1F9}',
    'ES': '\u{1F1EA}\u{1F1F8}',
  };

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: selectedCode,
      decoration: const InputDecoration(
        labelText: 'Country',
        prefixIcon: Icon(Icons.public_outlined),
      ),
      items: kSupportedCountries.entries.map((entry) {
        return DropdownMenuItem(
          value: entry.key,
          child: Text('${_flags[entry.key] ?? ''} ${entry.value}'),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}
