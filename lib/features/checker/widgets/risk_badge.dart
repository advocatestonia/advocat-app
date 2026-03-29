import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../providers/company_checker_provider.dart';

/// Reusable animated badge showing risk level assessment.
class RiskBadge extends StatefulWidget {
  const RiskBadge({super.key, required this.riskLevel, this.compact = false});

  final RiskLevel riskLevel;
  final bool compact;

  @override
  State<RiskBadge> createState() => _RiskBadgeState();
}

class _RiskBadgeState extends State<RiskBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _backgroundColor {
    switch (widget.riskLevel) {
      case RiskLevel.low:
        return AppColors.success.withValues(alpha: 0.1);
      case RiskLevel.medium:
        return AppColors.warning.withValues(alpha: 0.1);
      case RiskLevel.high:
        return AppColors.error.withValues(alpha: 0.1);
    }
  }

  Color get _foregroundColor {
    switch (widget.riskLevel) {
      case RiskLevel.low:
        return AppColors.success;
      case RiskLevel.medium:
        return AppColors.warning;
      case RiskLevel.high:
        return AppColors.error;
    }
  }

  IconData get _icon {
    switch (widget.riskLevel) {
      case RiskLevel.low:
        return Icons.verified_user_rounded;
      case RiskLevel.medium:
        return Icons.warning_amber_rounded;
      case RiskLevel.high:
        return Icons.dangerous_rounded;
    }
  }

  String get _label {
    switch (widget.riskLevel) {
      case RiskLevel.low:
        return 'Safe to work with';
      case RiskLevel.medium:
        return 'Proceed with caution';
      case RiskLevel.high:
        return 'High risk — avoid';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? AppSpacing.sm : AppSpacing.md,
            vertical: widget.compact ? AppSpacing.xs : AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: _foregroundColor.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _icon,
                color: _foregroundColor,
                size: widget.compact ? 16 : 20,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                _label,
                style: TextStyle(
                  color: _foregroundColor,
                  fontWeight: FontWeight.w600,
                  fontSize: widget.compact ? 12 : 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
