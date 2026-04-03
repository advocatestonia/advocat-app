import 'package:flutter/material.dart';
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vehicleCheckerProvider);
    final notifier = ref.read(vehicleCheckerProvider.notifier);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.vehicleChecker ?? 'Vehicle Checker'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
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
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Input Mode Toggle ────────────────────────────────────────
            _InputModeToggle(
              mode: state.inputMode,
              onChanged: (mode) {
                notifier.setInputMode(mode);
                _controller.clear();
              },
              l10n: l10n,
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Country Selector (only for license plate mode) ───────────
            if (state.inputMode == VehicleInputMode.licensePlate) ...[
              _CountrySelector(
                selectedCode: state.countryCode,
                onChanged: notifier.setCountryCode,
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // ── Input Field ──────────────────────────────────────────────
            TextField(
              controller: _controller,
              onChanged: notifier.setQuery,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: state.inputMode == VehicleInputMode.licensePlate
                    ? (l10n?.licensePlate ?? 'License plate')
                    : (l10n?.vinNumber ?? 'VIN number'),
                prefixIcon: Icon(
                  state.inputMode == VehicleInputMode.licensePlate
                      ? Icons.pin_outlined
                      : Icons.qr_code_outlined,
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
            const SizedBox(height: AppSpacing.md),

            // ── Check Button ─────────────────────────────────────────────
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: state.isLoading ? null : () => notifier.checkVehicle(),
                icon: state.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.search),
                label: Text(
                  state.isLoading
                      ? (l10n?.loading ?? 'Loading...')
                      : (l10n?.checkVehicle ?? 'Check Vehicle'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

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
              ),
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
              ),
            ],

            // ── Report Results ───────────────────────────────────────────
            if (state.report != null) ...[
              const SizedBox(height: AppSpacing.lg),
              VehicleReportCard(
                report: state.report!,
                onReportFraud: state.report!.mileageFraudSuspected
                    ? () => _showFraudDialog(context)
                    : null,
                onOpenCase: () => context.go(AppRoutes.caseCreate),
              ),
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
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _ToggleOption(
            label: l10n?.licensePlate ?? 'License plate',
            icon: Icons.pin_outlined,
            isSelected: mode == VehicleInputMode.licensePlate,
            onTap: () => onChanged(VehicleInputMode.licensePlate),
          ),
          _ToggleOption(
            label: l10n?.vinNumber ?? 'VIN number',
            icon: Icons.qr_code_outlined,
            isSelected: mode == VehicleInputMode.vin,
            onTap: () => onChanged(VehicleInputMode.vin),
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
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm - 2),
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
