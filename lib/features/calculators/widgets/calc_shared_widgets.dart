// calc_shared_widgets.dart — small presentational helpers shared by the four
// calculator screens (indicative banner, formula box, source link, result card).
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/theme.dart';

/// Amber "indicative only" banner shown above every calculator result.
class CalcIndicativeBanner extends StatelessWidget {
  const CalcIndicativeBanner({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.warning,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Boxed "how this is calculated" breakdown.
class CalcFormulaBox extends StatelessWidget {
  const CalcFormulaBox({
    super.key,
    required this.title,
    required this.lines,
  });

  final String title;
  final List<String> lines;

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
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...lines.map(
            (l) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  ',
                      style: TextStyle(color: AppColors.textSecondary)),
                  Expanded(
                    child: Text(
                      l,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tappable "Source: <norm>" row that opens the cited URL when provided.
class CalcSourceRow extends StatelessWidget {
  const CalcSourceRow({
    super.key,
    required this.label,
    required this.source,
    this.url,
  });

  final String label;
  final String source;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final child = RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 12, height: 1.4),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          TextSpan(
            text: source,
            style: TextStyle(
              color: url != null ? AppColors.accent : AppColors.textSecondary,
              decoration:
                  url != null ? TextDecoration.underline : TextDecoration.none,
            ),
          ),
        ],
      ),
    );
    if (url == null || url!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: child,
      );
    }
    return InkWell(
      onTap: () => launchUrl(Uri.parse(url!),
          mode: LaunchMode.externalApplication),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: child,
      ),
    );
  }
}

/// Compact labelled slider used across the calculator forms.
class CalcSliderRow extends StatelessWidget {
  const CalcSliderRow({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.display,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String display;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                display,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            activeColor: AppColors.accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Headline result card (big number + label).
class CalcResultCard extends StatelessWidget {
  const CalcResultCard({
    super.key,
    required this.label,
    required this.value,
    this.subLabel,
    this.subValue,
    this.color = AppColors.accent,
    this.icon = Icons.calculate_outlined,
  });

  final String label;
  final String value;
  final String? subLabel;
  final String? subValue;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          if (subLabel != null && subValue != null) ...[
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Text(
                  '$subLabel: ',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subValue!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
