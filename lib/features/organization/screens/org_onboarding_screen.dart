import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../shared/widgets/advocat_gradient_header.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/max_width_wrapper.dart';
import '../models/organization.dart';
import '../providers/org_providers.dart';
import '../repositories/org_repository.dart';
import '../widgets/plan_card.dart';

/// 4-step wizard to create a new organization.
///
/// Spec: see FLUTTER_UI_SPEC.md §1.
class OrgOnboardingScreen extends ConsumerStatefulWidget {
  const OrgOnboardingScreen({super.key});

  @override
  ConsumerState<OrgOnboardingScreen> createState() =>
      _OrgOnboardingScreenState();
}

class _OrgOnboardingScreenState extends ConsumerState<OrgOnboardingScreen> {
  int _step = 0;

  // Step 1
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _legalNameController = TextEditingController();
  String _country = 'EE';
  bool? _slugAvailable;
  bool _slugChecking = false;
  bool _slugManuallyEdited = false;
  Timer? _slugDebounce;

  // Step 2
  final _billingEmailController = TextEditingController();
  final _vatController = TextEditingController();

  // Step 3
  OrgPlan _plan = OrgPlan.firm;
  bool _yearly = false;

  // Step 4
  bool _acceptedDpa = false;
  bool _submitting = false;
  String? _submitError;

  static const _countries = [
    ('EE', 'Estonia'),
    ('FI', 'Finland'),
    ('LV', 'Latvia'),
    ('LT', 'Lithuania'),
    ('DE', 'Germany'),
    ('SE', 'Sweden'),
    ('Other', 'Other'),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _legalNameController.dispose();
    _billingEmailController.dispose();
    _vatController.dispose();
    _slugDebounce?.cancel();
    super.dispose();
  }

  // ── Slug auto-derive + availability check ─────────────────────────────

  void _onNameChanged(String value) {
    if (!_slugManuallyEdited) {
      final slug = _slugify(value);
      _slugController.text = slug;
      _scheduleSlugCheck(slug);
    }
  }

  void _onSlugChanged(String value) {
    _slugManuallyEdited = true;
    _scheduleSlugCheck(value);
  }

  String _slugify(String input) {
    final lower = input.toLowerCase().trim();
    final replaced = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    return replaced.replaceAll(RegExp(r'^-+|-+$'), '');
  }

  void _scheduleSlugCheck(String slug) {
    _slugDebounce?.cancel();
    if (slug.length < 3) {
      setState(() {
        _slugAvailable = null;
        _slugChecking = false;
      });
      return;
    }
    setState(() => _slugChecking = true);
    _slugDebounce = Timer(const Duration(milliseconds: 450), () async {
      try {
        final available =
            await ref.read(orgRepositoryProvider).isSlugAvailable(slug);
        if (mounted) {
          setState(() {
            _slugAvailable = available;
            _slugChecking = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _slugChecking = false);
      }
    });
  }

  bool get _canContinueStep1 =>
      _nameController.text.trim().isNotEmpty &&
      _slugController.text.trim().length >= 3 &&
      _slugAvailable == true &&
      _legalNameController.text.trim().isNotEmpty;

  bool get _canContinueStep2 {
    final email = _billingEmailController.text.trim();
    return email.contains('@') && email.contains('.');
  }

  Future<void> _submit({required bool startTrial}) async {
    if (!_acceptedDpa) {
      setState(() => _submitError =
          'Please accept the Data Processing Agreement to continue.');
      return;
    }
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      final org = await ref.read(orgRepositoryProvider).createOrganization(
            name: _nameController.text.trim(),
            slug: _slugController.text.trim(),
            legalName: _legalNameController.text.trim(),
            country: _country,
            billingEmail: _billingEmailController.text.trim(),
            vatId: _vatController.text.trim().isEmpty
                ? null
                : _vatController.text.trim(),
            plan: _plan,
            yearly: _yearly,
          );
      ref.invalidate(myOrgsProvider);
      await ref.read(activeOrgIdProvider.notifier).setActive(org.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Welcome to ${org.name} — you have 14 days free."),
          backgroundColor: AppColors.accent,
        ),
      );
      context.go('/orgs/${org.slug}/dashboard');
    } on OrgRepositoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitError = e.code == 'slug_taken'
            ? 'That slug is taken — did a previous attempt succeed? Try logging in.'
            : 'Could not create organization (${e.code}). Please try again.';
        _submitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitError = 'Unexpected error: $e';
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AdvocatGradientHeader(title: 'Create organization'),
      body: SafeArea(
        child: MaxWidthWrapper(
          maxWidth: 720,
          child: Column(
            children: [
              _StepperBar(currentStep: _step, totalSteps: 4),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _buildStep(),
                ),
              ),
              _buildNavBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      case 3:
        return _buildStep4();
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Step 1: Organization details ──────────────────────────────────────

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tell us about your firm',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "We'll use this on invoices and your team's portal.",
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        AppTextField(
          controller: _nameController,
          label: 'Organization name',
          hint: 'Sirel & Partnerid',
          onChanged: _onNameChanged,
          autofocus: true,
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _slugController,
          label: 'URL slug',
          hint: 'sirel-partnerid',
          onChanged: _onSlugChanged,
        ),
        const SizedBox(height: 4),
        _SlugIndicator(
          slug: _slugController.text,
          available: _slugAvailable,
          checking: _slugChecking,
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _legalNameController,
          label: 'Legal name (for invoices)',
          hint: 'Sirel & Partnerid OÜ',
        ),
        const SizedBox(height: 16),
        const Text(
          'Country',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: _country,
          items: [
            for (final c in _countries)
              DropdownMenuItem(value: c.$1, child: Text(c.$2)),
          ],
          onChanged: (v) => setState(() => _country = v ?? 'EE'),
        ),
      ],
    );
  }

  // ── Step 2: Billing details ────────────────────────────────────────────

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Billing details',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 24),
        AppTextField(
          controller: _billingEmailController,
          label: 'Billing email',
          hint: 'billing@yourfirm.ee',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _vatController,
          label: 'VAT / KMKR ID (optional)',
          hint: 'EE123456789',
        ),
        const SizedBox(height: 8),
        const Text(
          'Required for a VAT invoice. Skip if you are not VAT-registered.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  // ── Step 3: Plan selection ────────────────────────────────────────────

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose a plan',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '14-day free trial on every plan. Change anytime.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        _BillingPeriodToggle(
          yearly: _yearly,
          onChanged: (v) => setState(() => _yearly = v),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (ctx, c) {
            final isWide = c.maxWidth > 700;
            if (isWide) {
              return Row(
                children: [
                  Expanded(child: _planCard(OrgPlan.starter)),
                  const SizedBox(width: 12),
                  Expanded(child: _planCard(OrgPlan.firm, recommended: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _planCard(OrgPlan.enterprise)),
                ],
              );
            }
            return Column(
              children: [
                _planCard(OrgPlan.starter),
                const SizedBox(height: 16),
                _planCard(OrgPlan.firm, recommended: true),
                const SizedBox(height: 16),
                _planCard(OrgPlan.enterprise),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _planCard(OrgPlan p, {bool recommended = false}) {
    return OrgPlanCard(
      plan: p,
      isYearly: _yearly,
      isSelected: _plan == p,
      isRecommended: recommended,
      onSelect: () => setState(() => _plan = p),
    );
  }

  // ── Step 4: Review & trial ────────────────────────────────────────────

  Widget _buildStep4() {
    final monthlyPrice =
        _yearly ? _plan.pricePerSeatYearly : _plan.pricePerSeatMonthly;
    final period = _yearly ? 'year' : 'month';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review & start',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _summaryRow('Name', _nameController.text),
              _summaryRow('URL', 'advocat.ee/orgs/${_slugController.text}'),
              _summaryRow('Legal name', _legalNameController.text),
              _summaryRow('Country', _country),
              _summaryRow('Billing email', _billingEmailController.text),
              if (_vatController.text.isNotEmpty)
                _summaryRow('VAT ID', _vatController.text),
              const Divider(height: 24),
              _summaryRow('Plan',
                  '${_plan.name[0].toUpperCase()}${_plan.name.substring(1)}'),
              _summaryRow('Billing',
                  '€${monthlyPrice.toStringAsFixed(0)} / seat / $period'),
              _summaryRow('Trial', '14 days free'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          value: _acceptedDpa,
          onChanged: (v) => setState(() => _acceptedDpa = v ?? false),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: AppColors.accent,
          title: const Text(
            'I accept the Data Processing Agreement (GDPR Art. 28)',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (_submitError != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.errorBg,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(_submitError!,
                style: const TextStyle(color: AppColors.error, fontSize: 12)),
          ),
        ],
      ],
    );
  }

  Widget _summaryRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 130,
              child: Text(label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  )),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  )),
            ),
          ],
        ),
      );

  // ── Bottom nav bar ────────────────────────────────────────────────────

  Widget _buildNavBar() {
    final isLast = _step == 3;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (_step > 0)
            AppButton(
              label: 'Back',
              variant: AppButtonVariant.ghost,
              onPressed: _submitting
                  ? null
                  : () => setState(() => _step--),
            ),
          const Spacer(),
          if (isLast)
            AppButton(
              label: 'Start 14-day trial',
              onPressed: _submitting
                  ? null
                  : () => _submit(startTrial: true),
              isLoading: _submitting,
              variant: AppButtonVariant.primary,
            )
          else
            AppButton(
              label: 'Continue',
              onPressed: _canContinueAt(_step)
                  ? () => setState(() => _step++)
                  : null,
            ),
        ],
      ),
    );
  }

  bool _canContinueAt(int step) {
    switch (step) {
      case 0:
        return _canContinueStep1;
      case 1:
        return _canContinueStep2;
      case 2:
        return true;
      default:
        return false;
    }
  }
}

// ─── Stepper bar ────────────────────────────────────────────────────────

class _StepperBar extends StatelessWidget {
  const _StepperBar({required this.currentStep, required this.totalSteps});
  final int currentStep;
  final int totalSteps;

  static const _labels = ['Details', 'Billing', 'Plan', 'Review'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: List.generate(totalSteps, (i) {
          final isActive = i <= currentStep;
          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.accent
                            : AppColors.surfaceVariant,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? Colors.white
                              : AppColors.textTertiary,
                        ),
                      ),
                    ),
                    if (i < totalSteps - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: i < currentStep
                              ? AppColors.accent
                              : AppColors.surfaceVariant,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _labels[i],
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ─── Slug availability indicator ────────────────────────────────────────

class _SlugIndicator extends StatelessWidget {
  const _SlugIndicator({
    required this.slug,
    required this.available,
    required this.checking,
  });
  final String slug;
  final bool? available;
  final bool checking;

  @override
  Widget build(BuildContext context) {
    if (slug.length < 3) {
      return const Text(
        'Slug must be at least 3 characters',
        style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
      );
    }
    if (checking) {
      return const Row(
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 1.5),
          ),
          SizedBox(width: 6),
          Text('Checking availability…',
              style:
                  TextStyle(fontSize: 11, color: AppColors.textTertiary)),
        ],
      );
    }
    if (available == true) {
      return const Row(
        children: [
          Icon(Icons.check_circle_outline_rounded,
              size: 14, color: AppColors.success),
          SizedBox(width: 6),
          Text('Slug is available',
              style: TextStyle(fontSize: 11, color: AppColors.success)),
        ],
      );
    }
    if (available == false) {
      return const Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 14, color: AppColors.error),
          SizedBox(width: 6),
          Text('Slug is taken',
              style: TextStyle(fontSize: 11, color: AppColors.error)),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}

// ─── Billing period toggle ──────────────────────────────────────────────

class _BillingPeriodToggle extends StatelessWidget {
  const _BillingPeriodToggle({required this.yearly, required this.onChanged});
  final bool yearly;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        children: [
          _toggleOption('Monthly', !yearly, () => onChanged(false)),
          _toggleOption('Yearly · save 17%', yearly, () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _toggleOption(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? AppColors.textPrimary
                  : AppColors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}
