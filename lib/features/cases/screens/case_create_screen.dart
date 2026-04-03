import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/case_model.dart';
import '../providers/cases_provider.dart';

// ---------------------------------------------------------------------------
// Case Create Screen — Step-by-step wizard
// ---------------------------------------------------------------------------

class CaseCreateScreen extends ConsumerStatefulWidget {
  const CaseCreateScreen({super.key});

  @override
  ConsumerState<CaseCreateScreen> createState() => _CaseCreateScreenState();
}

class _CaseCreateScreenState extends ConsumerState<CaseCreateScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  CaseType? _selectedType;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _referenceController = TextEditingController();
  String? _selectedCountry;
  bool _isLoading = false;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  static const _totalSteps = 3;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _fadeController.reset();
      setState(() => _currentStep++);
      _fadeController.forward();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _fadeController.reset();
      setState(() => _currentStep--);
      _fadeController.forward();
    }
  }

  bool get _canProceed {
    switch (_currentStep) {
      case 0:
        return _selectedType != null;
      case 1:
        return _titleController.text.trim().isNotEmpty;
      case 2:
        return true; // Document upload is optional
      default:
        return false;
    }
  }

  Future<void> _createCase() async {
    if (_selectedType == null || _titleController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final controller = ref.read(caseControllerProvider.notifier);
      final newCase = await controller.createCase(
        title: _titleController.text.trim(),
        type: _selectedType!,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        migriReferenceNumber: _referenceController.text.trim().isEmpty
            ? null
            : _referenceController.text.trim(),
      );
      if (mounted) context.go('/cases/${newCase.id}');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create case. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.newCase ?? 'New Case'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // ── Progress indicator ──────────────────────────────────────
          _StepProgressBar(
            currentStep: _currentStep,
            totalSteps: _totalSteps,
          ),

          // ── Step content ───────────────────────────────────────────
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildStepContent(),
              ),
            ),
          ),

          // ── Bottom navigation ──────────────────────────────────────
          _BottomNav(
            currentStep: _currentStep,
            totalSteps: _totalSteps,
            canProceed: _canProceed,
            isLoading: _isLoading,
            onBack: _previousStep,
            onNext: _currentStep == _totalSteps - 1 ? _createCase : _nextStep,
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _Step1CaseType(
          selectedType: _selectedType,
          onTypeSelected: (type) => setState(() => _selectedType = type),
        );
      case 1:
        return _Step2Details(
          titleController: _titleController,
          descriptionController: _descriptionController,
          referenceController: _referenceController,
          selectedCountry: _selectedCountry,
          onCountryChanged: (c) => setState(() => _selectedCountry = c),
          onChanged: () => setState(() {}),
        );
      case 2:
        return const _Step3Document();
      default:
        return const SizedBox.shrink();
    }
  }
}

// ---------------------------------------------------------------------------
// Step Progress Bar
// ---------------------------------------------------------------------------

class _StepProgressBar extends StatelessWidget {
  const _StepProgressBar({
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(totalSteps, (index) {
              final isCompleted = index < currentStep;
              final isCurrent = index == currentStep;

              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: index < totalSteps - 1 ? AppSpacing.xs : 0,
                  ),
                  height: 4,
                  decoration: BoxDecoration(
                    color: isCompleted || isCurrent
                        ? AppColors.accent
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(
                _stepLabel(currentStep),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                AppLocalizations.of(context)?.step(currentStep + 1, totalSteps) ?? 'Step ${currentStep + 1} of $totalSteps',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _stepLabel(int step) {
    return switch (step) {
      0 => 'Case Type',
      1 => 'Details',
      2 => 'Documents',
      _ => '',
    };
  }
}

// ---------------------------------------------------------------------------
// Step 1: Case Type Selector
// ---------------------------------------------------------------------------

class _Step1CaseType extends StatelessWidget {
  const _Step1CaseType({
    required this.selectedType,
    required this.onTypeSelected,
  });

  final CaseType? selectedType;
  final ValueChanged<CaseType> onTypeSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What type of case is this?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Select the category that best describes your situation.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: AppSpacing.xl),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.3,
            children: [
              _CaseTypeCard(
                type: CaseType.deportation,
                icon: Icons.flight_takeoff,
                label: AppLocalizations.of(context)?.deportation ?? 'Deportation',
                isSelected: selectedType == CaseType.deportation,
                color: AppColors.error,
                onTap: () => onTypeSelected(CaseType.deportation),
              ),
              _CaseTypeCard(
                type: CaseType.asylum,
                icon: Icons.home_outlined,
                label: AppLocalizations.of(context)?.asylum ?? 'Asylum',
                isSelected: selectedType == CaseType.asylum,
                color: AppColors.info,
                onTap: () => onTypeSelected(CaseType.asylum),
              ),
              _CaseTypeCard(
                type: CaseType.residencePermit,
                icon: Icons.credit_card_outlined,
                label: AppLocalizations.of(context)?.residencePermit ?? 'Residence Permit',
                isSelected: selectedType == CaseType.residencePermit,
                color: AppColors.accent,
                onTap: () => onTypeSelected(CaseType.residencePermit),
              ),
              _CaseTypeCard(
                type: CaseType.familyReunification,
                icon: Icons.people_outline,
                label: AppLocalizations.of(context)?.familyReunification ?? 'Family Reunion',
                isSelected: selectedType == CaseType.familyReunification,
                color: AppColors.warning,
                onTap: () => onTypeSelected(CaseType.familyReunification),
              ),
              _CaseTypeCard(
                type: CaseType.workPermit,
                icon: Icons.work_outline,
                label: 'Work Permit',
                isSelected: selectedType == CaseType.workPermit,
                color: AppColors.primaryLight,
                onTap: () => onTypeSelected(CaseType.workPermit),
              ),
              _CaseTypeCard(
                type: CaseType.laborDispute,
                icon: Icons.work_outline,
                label: AppLocalizations.of(context)?.laborDispute ?? 'Labor Dispute',
                isSelected: selectedType == CaseType.laborDispute,
                color: const Color(0xFF8B5CF6),
                onTap: () => onTypeSelected(CaseType.laborDispute),
              ),
              _CaseTypeCard(
                type: CaseType.tenantRights,
                icon: Icons.home_outlined,
                label: AppLocalizations.of(context)?.tenantRights ?? 'Tenant Rights',
                isSelected: selectedType == CaseType.tenantRights,
                color: const Color(0xFF10B981),
                onTap: () => onTypeSelected(CaseType.tenantRights),
              ),
              _CaseTypeCard(
                type: CaseType.debtCollection,
                icon: Icons.account_balance_wallet_outlined,
                label: AppLocalizations.of(context)?.debtCollection ?? 'Debt Collection',
                isSelected: selectedType == CaseType.debtCollection,
                color: const Color(0xFFF59E0B),
                onTap: () => onTypeSelected(CaseType.debtCollection),
              ),
              _CaseTypeCard(
                type: CaseType.discrimination,
                icon: Icons.balance_outlined,
                label: AppLocalizations.of(context)?.discrimination ?? 'Discrimination',
                isSelected: selectedType == CaseType.discrimination,
                color: const Color(0xFFEC4899),
                onTap: () => onTypeSelected(CaseType.discrimination),
              ),
              _CaseTypeCard(
                type: CaseType.policeMisconduct,
                icon: Icons.local_police_outlined,
                label: AppLocalizations.of(context)?.policeMisconduct ?? 'Police Misconduct',
                isSelected: selectedType == CaseType.policeMisconduct,
                color: const Color(0xFF6366F1),
                onTap: () => onTypeSelected(CaseType.policeMisconduct),
              ),
              _CaseTypeCard(
                type: CaseType.socialBenefits,
                icon: Icons.health_and_safety_outlined,
                label: AppLocalizations.of(context)?.socialBenefits ?? 'Social Benefits',
                isSelected: selectedType == CaseType.socialBenefits,
                color: const Color(0xFF14B8A6),
                onTap: () => onTypeSelected(CaseType.socialBenefits),
              ),
              _CaseTypeCard(
                type: CaseType.other,
                icon: Icons.more_horiz,
                label: AppLocalizations.of(context)?.other ?? 'Other',
                isSelected: selectedType == CaseType.other,
                color: AppColors.textSecondary,
                onTap: () => onTypeSelected(CaseType.other),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CaseTypeCard extends StatelessWidget {
  const _CaseTypeCard({
    required this.type,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final CaseType type;
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? color : AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? color : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 2: Details
// ---------------------------------------------------------------------------

class _Step2Details extends StatelessWidget {
  const _Step2Details({
    required this.titleController,
    required this.descriptionController,
    required this.referenceController,
    required this.selectedCountry,
    required this.onCountryChanged,
    required this.onChanged,
  });

  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController referenceController;
  final String? selectedCountry;
  final ValueChanged<String?> onCountryChanged;
  final VoidCallback onChanged;

  static const _countries = [
    'Finland',
    'Sweden',
    'Norway',
    'Denmark',
    'Germany',
    'France',
    'United Kingdom',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tell us about your case',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'This information helps our AI understand your situation better.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Case title
          TextFormField(
            controller: titleController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)?.caseTitle ?? 'Case Title',
              hintText: 'e.g., Residence Permit Appeal 2026',
            ),
            onChanged: (_) => onChanged(),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),

          // Country / jurisdiction
          DropdownButtonFormField<String>(
            initialValue: selectedCountry,
            decoration: const InputDecoration(
              labelText: 'Country / Jurisdiction',
              hintText: 'Select a country',
            ),
            items: _countries.map((c) {
              return DropdownMenuItem(value: c, child: Text(c));
            }).toList(),
            onChanged: onCountryChanged,
          ),
          const SizedBox(height: AppSpacing.md),

          // Migri reference
          TextFormField(
            controller: referenceController,
            decoration: InputDecoration(
              labelText: '${AppLocalizations.of(context)?.referenceNumber ?? "Reference Number"} ${AppLocalizations.of(context)?.optional ?? "(optional)"}',
              hintText: 'e.g., UMA/12345/2026',
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),

          // Description
          TextFormField(
            controller: descriptionController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              hintText:
                  'Describe your situation briefly. What happened? What decision was made?',
              alignLabelWithHint: true,
            ),
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 3: Document Upload (optional)
// ---------------------------------------------------------------------------

class _Step3Document extends StatelessWidget {
  const _Step3Document();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload your first document',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Upload the decision letter or any relevant document. You can skip this step and add documents later.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Upload area
          GestureDetector(
            onTap: () {
              // TODO: Open file picker
            },
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: AppColors.border,
                  style: BorderStyle.solid,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 48,
                    color: AppColors.textTertiary,
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    'Tap to upload a file',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    'PDF, JPG, PNG up to 25 MB',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Camera option
          OutlinedButton.icon(
            onPressed: () {
              // TODO: Open camera for document scan
            },
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Take a Photo Instead'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Skip hint
          const Center(
            child: Text(
              'You can always add documents later from the case detail screen.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textTertiary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom Navigation Bar
// ---------------------------------------------------------------------------

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.currentStep,
    required this.totalSteps,
    required this.canProceed,
    required this.isLoading,
    required this.onBack,
    required this.onNext,
  });

  final int currentStep;
  final int totalSteps;
  final bool canProceed;
  final bool isLoading;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isLastStep = currentStep == totalSteps - 1;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            if (currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: isLoading ? null : onBack,
                  child: Text(AppLocalizations.of(context)?.back ?? 'Back'),
                ),
              ),
            if (currentStep > 0) const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: currentStep > 0 ? 2 : 1,
              child: ElevatedButton(
                onPressed: canProceed && !isLoading ? onNext : null,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(isLastStep ? (AppLocalizations.of(context)?.createCase ?? 'Create Case') : (AppLocalizations.of(context)?.next ?? 'Next')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
