import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/vehicle_checker_provider.dart';

// ---------------------------------------------------------------------------
// Vehicle Report Card — displays the full vehicle check results
// ---------------------------------------------------------------------------

class VehicleReportCard extends StatelessWidget {
  const VehicleReportCard({
    super.key,
    required this.report,
    this.onReportFraud,
    this.onOpenCase,
  });

  final VehicleReport report;
  final VoidCallback? onReportFraud;
  final VoidCallback? onOpenCase;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── AI Assessment Banner ──────────────────────────────────────────
        _AssessmentBanner(assessment: report.assessment, l10n: l10n),
        const SizedBox(height: AppSpacing.md),

        // ── AI Summary ───────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.smart_toy_outlined, color: AppColors.accent, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  report.aiSummary,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── Vehicle Identity ─────────────────────────────────────────────
        _SectionTitle(title: l10n?.vehicleMake ?? 'Vehicle'),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.directions_car_outlined,
                  label: l10n?.vehicleMake ?? 'Make',
                  value: report.make,
                ),
                const Divider(height: AppSpacing.lg),
                _InfoRow(
                  icon: Icons.category_outlined,
                  label: l10n?.vehicleModel ?? 'Model',
                  value: report.model,
                ),
                const Divider(height: AppSpacing.lg),
                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: l10n?.vehicleYear ?? 'Year',
                  value: '${report.year}',
                ),
                const Divider(height: AppSpacing.lg),
                _InfoRow(
                  icon: Icons.palette_outlined,
                  label: l10n?.vehicleColor ?? 'Color',
                  value: report.color,
                ),
                const Divider(height: AppSpacing.lg),
                _InfoRow(
                  icon: Icons.confirmation_number_outlined,
                  label: 'VIN',
                  value: report.vin,
                  valueStyle: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── Mileage Section ──────────────────────────────────────────────
        _SectionTitle(title: l10n?.mileage ?? 'Mileage'),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.speed_outlined,
                      color: report.mileageFraudSuspected
                          ? AppColors.error
                          : AppColors.accent,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${_formatNumber(report.mileageKm)} km',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    if (report.mileageFraudSuspected)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: AppColors.error, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Fraud suspected',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_outline,
                                color: AppColors.success, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Consistent',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (report.mileageHistory.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  _MileageChart(history: report.mileageHistory),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── Status Checks ────────────────────────────────────────────────
        _SectionTitle(title: l10n?.vehicleChecks ?? 'Status Checks'),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                _StatusRow(
                  icon: Icons.minor_crash_outlined,
                  label: l10n?.accidents ?? 'Accidents',
                  value: report.accidentCount == 0
                      ? 'None'
                      : '${report.accidentCount} reported',
                  isGood: report.accidentCount == 0,
                ),
                const Divider(height: AppSpacing.lg),
                _StatusRow(
                  icon: Icons.shield_outlined,
                  label: l10n?.insurance ?? 'Insurance',
                  value: report.insuranceActive
                      ? 'Active${report.insuranceExpiry != null ? ' (until ${_formatDate(report.insuranceExpiry!)})' : ''}'
                      : 'Expired',
                  isGood: report.insuranceActive,
                ),
                const Divider(height: AppSpacing.lg),
                _StatusRow(
                  icon: Icons.build_outlined,
                  label: l10n?.inspection ?? 'Technical inspection',
                  value: report.inspectionValid
                      ? 'Valid${report.inspectionExpiry != null ? ' (until ${_formatDate(report.inspectionExpiry!)})' : ''}'
                      : 'Expired',
                  isGood: report.inspectionValid,
                ),
                const Divider(height: AppSpacing.lg),
                _StatusRow(
                  icon: Icons.people_outline,
                  label: l10n?.owners ?? 'Previous owners',
                  value: '${report.ownerCount}',
                  isGood: report.ownerCount <= 3,
                ),
                const Divider(height: AppSpacing.lg),
                _StatusRow(
                  icon: Icons.gpp_maybe_outlined,
                  label: l10n?.stolen ?? 'Stolen check',
                  value: report.isStolen ? 'STOLEN' : 'Clear',
                  isGood: !report.isStolen,
                  isCritical: report.isStolen,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── Action Buttons ───────────────────────────────────────────────
        if (report.mileageFraudSuspected && onReportFraud != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: OutlinedButton.icon(
              onPressed: onReportFraud,
              icon: const Icon(Icons.flag_outlined, color: AppColors.error),
              label: Text(
                l10n?.reportFraud ?? 'Report Fraud',
                style: const TextStyle(color: AppColors.error),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        if (onOpenCase != null)
          OutlinedButton.icon(
            onPressed: onOpenCase,
            icon: const Icon(Icons.gavel_outlined),
            label: Text(l10n?.openACase ?? 'Open a Case'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
      ],
    );
  }

  static String _formatNumber(int n) {
    final s = n.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }

  static String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}';
  }
}

// ── Assessment Banner ──────────────────────────────────────────────────────

class _AssessmentBanner extends StatelessWidget {
  const _AssessmentBanner({required this.assessment, this.l10n});

  final VehicleAssessment assessment;
  final AppLocalizations? l10n;

  @override
  Widget build(BuildContext context) {
    final (color, bgColor, icon, text) = switch (assessment) {
      VehicleAssessment.safeToBuy => (
          AppColors.success,
          AppColors.success.withValues(alpha: 0.1),
          Icons.check_circle_rounded,
          l10n?.safeToBuy ?? 'Safe to buy',
        ),
      VehicleAssessment.someConcerns => (
          AppColors.warning,
          AppColors.warning.withValues(alpha: 0.1),
          Icons.warning_rounded,
          l10n?.someConcerns ?? 'Some concerns',
        ),
      VehicleAssessment.doNotBuy => (
          AppColors.error,
          AppColors.error.withValues(alpha: 0.1),
          Icons.dangerous_rounded,
          l10n?.doNotBuy ?? 'Do not buy',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Title ──────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
    );
  }
}

// ── Info Row ───────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueStyle,
  });

  final IconData icon;
  final String label;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textTertiary),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: valueStyle ??
              theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

// ── Status Row ─────────────────────────────────────────────────────────────

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isGood,
    this.isCritical = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isGood;
  final bool isCritical;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor =
        isCritical ? AppColors.error : (isGood ? AppColors.success : AppColors.warning);

    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textTertiary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Mileage Chart (simple bar chart) ───────────────────────────────────────

class _MileageChart extends StatelessWidget {
  const _MileageChart({required this.history});
  final List<MileageRecord> history;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox.shrink();

    final maxKm = history.map((r) => r.mileageKm).reduce((a, b) => a > b ? a : b);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mileage History',
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...history.map((record) {
          final fraction = maxKm > 0 ? record.mileageKm / maxKm : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 58,
                  child: Text(
                    '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textTertiary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 14,
                      backgroundColor: isDark
                          ? AppColors.darkSurfaceVariant
                          : AppColors.surfaceVariant,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(AppColors.accent),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 60,
                  child: Text(
                    '${(record.mileageKm / 1000).toStringAsFixed(0)}k',
                    textAlign: TextAlign.end,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
