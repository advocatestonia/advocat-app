import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../models/organization.dart';

/// Pricing-tier card used in the onboarding wizard step 3 and on the
/// billing screen when changing plan.
class OrgPlanCard extends StatelessWidget {
  const OrgPlanCard({
    super.key,
    required this.plan,
    required this.isYearly,
    required this.isSelected,
    required this.onSelect,
    this.isRecommended = false,
  });

  final OrgPlan plan;
  final bool isYearly;
  final bool isSelected;
  final bool isRecommended;
  final VoidCallback onSelect;

  String get _title => switch (plan) {
        OrgPlan.starter => 'Starter',
        OrgPlan.firm => 'Firm',
        OrgPlan.enterprise => 'Enterprise',
      };

  String get _description => switch (plan) {
        OrgPlan.starter => 'Up to 5 seats · Core features',
        OrgPlan.firm => 'Up to 25 seats · Branding + API',
        OrgPlan.enterprise => 'Unlimited · White-label + SSO',
      };

  List<String> get _features => switch (plan) {
        OrgPlan.starter => const [
            'Shared cases & documents',
            'Per-seat chat history',
            'Role-based access (owner / admin / member)',
            'Email support',
          ],
        OrgPlan.firm => const [
            'Everything in Starter',
            'Custom logo & brand colors',
            'REST API + webhooks',
            'Priority email support',
            'Audit log export',
          ],
        OrgPlan.enterprise => const [
            'Everything in Firm',
            'Custom domain (firm.example.com)',
            'White-label client portal',
            'SSO (SAML / OIDC)',
            'Dedicated success manager',
            'Custom DPA + invoicing',
          ],
      };

  @override
  Widget build(BuildContext context) {
    final price = isYearly ? plan.pricePerSeatYearly : plan.pricePerSeatMonthly;
    final period = isYearly ? '/seat/year' : '/seat/month';

    final borderColor = isSelected
        ? AppColors.accent
        : (isRecommended ? AppColors.accent : AppColors.border);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: InkWell(
            onTap: onSelect,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: borderColor,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.18),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _description,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '€${price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        period,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  for (final f in _features)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(Icons.check_rounded,
                                size: 16, color: AppColors.accent),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              f,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                height: 1.35,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (isRecommended)
          Positioned(
            top: -10,
            left: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: const Text(
                'RECOMMENDED',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
