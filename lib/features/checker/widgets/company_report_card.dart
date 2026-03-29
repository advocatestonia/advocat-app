import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../config/theme.dart';
import '../providers/company_checker_provider.dart';
import 'risk_badge.dart';

/// A beautifully styled report card showing all company check results.
class CompanyReportCard extends StatelessWidget {
  const CompanyReportCard({super.key, required this.report});

  final CompanyReport report;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Risk badge header
        Center(child: RiskBadge(riskLevel: report.riskLevel)),
        const SizedBox(height: AppSpacing.lg),

        // Main info card
        _InfoCard(
          children: [
            _InfoRow(
              icon: Icons.business_rounded,
              label: 'Company',
              value: report.companyName,
              isBold: true,
            ),
            const _Divider(),
            _InfoRow(
              icon: Icons.tag_rounded,
              label: 'Reg. number',
              value: report.registrationNumber,
            ),
            const _Divider(),
            _InfoRow(
              icon: Icons.circle,
              label: 'Status',
              valueWidget: _StatusChip(status: report.status),
            ),
            const _Divider(),
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: 'Address',
              value: report.address,
            ),
            const _Divider(),
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Founded',
              value: DateFormat('dd MMM yyyy').format(report.foundingDate),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // Risk indicators card
        _InfoCard(
          children: [
            _IndicatorRow(
              icon: Icons.account_balance_outlined,
              label: 'Tax debt',
              level: _taxDebtColor(report.taxDebtLevel),
              description: _taxDebtDescription(report.taxDebtLevel),
            ),
            const _Divider(),
            _IndicatorRow(
              icon: Icons.gavel_outlined,
              label: 'Court cases',
              level: report.hasCourtCases ? AppColors.error : AppColors.success,
              description: report.hasCourtCases
                  ? '${report.courtCasesCount} case(s) found'
                  : 'None found',
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // AI Summary card
        _InfoCard(
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(
                    Icons.smart_toy_outlined,
                    color: AppColors.accent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Text(
                  'AI Assessment',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              report.aiSummary,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),

        // "Open a Case" button if issues found
        if (report.riskLevel != RiskLevel.low) ...[
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Navigate to case creation with pre-filled data
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Case creation with pre-filled data coming soon'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.folder_open_outlined),
              label: const Text('Open a Case'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Color _taxDebtColor(TaxDebtLevel level) {
    switch (level) {
      case TaxDebtLevel.none:
        return AppColors.success;
      case TaxDebtLevel.minor:
        return AppColors.warning;
      case TaxDebtLevel.significant:
        return AppColors.error;
    }
  }

  String _taxDebtDescription(TaxDebtLevel level) {
    switch (level) {
      case TaxDebtLevel.none:
        return 'No tax debt';
      case TaxDebtLevel.minor:
        return 'Minor delays';
      case TaxDebtLevel.significant:
        return 'Significant debt';
    }
  }
}

// ---------------------------------------------------------------------------
// Internal widgets
// ---------------------------------------------------------------------------

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    this.value,
    this.valueWidget,
    this.isBold = false,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Widget? valueWidget;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textTertiary),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textTertiary,
              ),
            ),
          ),
          Expanded(
            child: valueWidget ??
                Text(
                  value ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
                    color: AppColors.textPrimary,
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

class _IndicatorRow extends StatelessWidget {
  const _IndicatorRow({
    required this.icon,
    required this.label,
    required this.level,
    required this.description,
  });

  final IconData icon;
  final String label;
  final Color level;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textTertiary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: level,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: level,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final CompanyStatus status;

  Color get _color {
    switch (status) {
      case CompanyStatus.active:
        return AppColors.success;
      case CompanyStatus.liquidated:
        return AppColors.warning;
      case CompanyStatus.bankrupt:
        return AppColors.error;
      case CompanyStatus.unknown:
        return AppColors.textTertiary;
    }
  }

  String get _label {
    switch (status) {
      case CompanyStatus.active:
        return 'Active';
      case CompanyStatus.liquidated:
        return 'Liquidated';
      case CompanyStatus.bankrupt:
        return 'Bankrupt';
      case CompanyStatus.unknown:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: _color,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Divider(height: 1, color: AppColors.border),
    );
  }
}
