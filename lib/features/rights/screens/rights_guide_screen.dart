import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';

class RightsGuideScreen extends StatefulWidget {
  const RightsGuideScreen({super.key});

  @override
  State<RightsGuideScreen> createState() => _RightsGuideScreenState();
}

class _RightsGuideScreenState extends State<RightsGuideScreen> {
  String? _selectedCategory;

  static const _categoryAll = 'All';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final scenarios = <_RightsScenario>[
      // 1. Домашнее насилие
      _RightsScenario(
        id: 'domestic-violence',
        title: l10n.domesticViolence,
        subtitle: l10n.domesticViolenceDesc,
        icon: Icons.health_and_safety_outlined,
        color: AppColors.error,
        category: 'Essential',
        rightsCount: 6,
        tag: 'Essential',
      ),
      // 2. Права детей и алименты
      _RightsScenario(
        id: 'children-rights',
        title: l10n.childrenRights,
        subtitle: l10n.childrenRightsDesc,
        icon: Icons.child_care,
        color: const Color(0xFFE91E63),
        category: 'Children',
        rightsCount: 7,
        tag: 'Children',
      ),
      // 3. Кибербуллинг
      _RightsScenario(
        id: 'cyberbullying',
        title: l10n.cyberbullying,
        subtitle: l10n.cyberbullyingDesc,
        icon: Icons.security,
        color: const Color(0xFF9C27B0),
        category: 'Digital',
        rightsCount: 6,
        tag: 'Digital',
      ),
      // 4. Полиция
      _RightsScenario(
        id: 'police-stop',
        title: l10n.stoppedByPolice,
        subtitle: l10n.stoppedByPoliceDesc,
        icon: Icons.local_police_outlined,
        color: AppColors.info,
        category: 'Police',
        rightsCount: 5,
        tag: 'Essential',
      ),
      // 5. Депортация
      _RightsScenario(
        id: 'deportation',
        title: l10n.deportationNotice,
        subtitle: l10n.deportationNoticeDesc,
        icon: Icons.flight_takeoff_outlined,
        color: AppColors.error,
        category: 'Essential',
        rightsCount: 4,
        tag: 'Essential',
      ),
      // 6. Трудовые права
      _RightsScenario(
        id: 'workplace',
        title: l10n.workplaceRights,
        subtitle: l10n.workplaceRightsDesc,
        icon: Icons.work_outline,
        color: AppColors.accent,
        category: 'Work',
        rightsCount: 5,
        tag: 'Work',
      ),
      // 7. Жильё
      _RightsScenario(
        id: 'tenant',
        title: l10n.tenantRights,
        subtitle: l10n.tenantRightsDesc,
        icon: Icons.home_outlined,
        color: AppColors.warning,
        category: 'Housing',
        rightsCount: 5,
        tag: 'Housing',
      ),
      // 8. Задержание
      _RightsScenario(
        id: 'detention',
        title: l10n.immigrationDetention,
        subtitle: l10n.immigrationDetentionDesc,
        icon: Icons.lock_outline,
        color: AppColors.error,
        category: 'Essential',
        rightsCount: 5,
        tag: 'Essential',
      ),
      // 9. Дискриминация
      _RightsScenario(
        id: 'discrimination',
        title: l10n.discrimination,
        subtitle: l10n.discriminationDesc,
        icon: Icons.balance_outlined,
        color: AppColors.primary,
        category: 'Essential',
        rightsCount: 4,
        tag: 'Essential',
      ),
      // 10. Защита потребителя
      _RightsScenario(
        id: 'consumer',
        title: l10n.consumerProtection,
        subtitle: l10n.consumerProtectionDesc,
        icon: Icons.shopping_bag_outlined,
        color: AppColors.accent,
        category: 'Consumer',
        rightsCount: 5,
        tag: 'Consumer',
      ),
      // 11. Наследство / Inheritance
      _RightsScenario(
        id: 'inheritance',
        title: l10n.inheritance,
        subtitle: l10n.inheritanceDesc,
        icon: Icons.account_balance_outlined,
        color: const Color(0xFF795548),
        category: 'Essential',
        rightsCount: 5,
        tag: 'Essential',
      ),
    ];

    final categoryLabels = <String, String>{
      _categoryAll: l10n.all,
      'Essential': l10n.categoryEssential,
      'Police': l10n.categoryPolice,
      'Work': l10n.categoryWork,
      'Housing': l10n.categoryHousing,
      'Consumer': l10n.categoryConsumer,
      'Children': l10n.categoryChildren,
      'Digital': l10n.categoryDigital,
    };

    final categories = [
      _categoryAll,
      'Essential',
      'Police',
      'Work',
      'Housing',
      'Consumer',
      'Children',
      'Digital',
    ];

    final filtered = _selectedCategory == null ||
            _selectedCategory == _categoryAll
        ? scenarios
        : scenarios.where((s) => s.category == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.knowYourRights,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          // Spacer
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),

          // Category filter chips
          SliverToBoxAdapter(
            child: SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                itemCount: categories.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.xs),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected =
                      (_selectedCategory ?? _categoryAll) == cat;
                  return FilterChip(
                    label: Text(categoryLabels[cat] ?? cat),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                    backgroundColor: AppColors.surface,
                    selectedColor: AppColors.accent.withValues(alpha: 0.12),
                    checkmarkColor: AppColors.accent,
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.accent
                          : AppColors.textSecondary,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.accent.withValues(alpha: 0.4)
                          : AppColors.border,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    elevation: isSelected ? 2 : 0,
                    pressElevation: 4,
                    shadowColor: AppColors.accent.withValues(alpha: 0.2),
                  );
                },
              ),
            ),
          ),

          // Scenario cards with staggered fade-in
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final s = filtered[index];
                  return _AnimatedScenarioCard(
                    scenario: s,
                    index: index,
                  );
                },
                childCount: filtered.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.xl),
          ),
        ],
      ),
    );
  }
}

/// Animates each card in with a staggered fade + slide on first build.
class _AnimatedScenarioCard extends StatefulWidget {
  const _AnimatedScenarioCard({
    required this.scenario,
    required this.index,
  });

  final _RightsScenario scenario;
  final int index;

  @override
  State<_AnimatedScenarioCard> createState() => _AnimatedScenarioCardState();
}

class _AnimatedScenarioCardState extends State<_AnimatedScenarioCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // Stagger: each card starts slightly later
    Future.delayed(Duration(milliseconds: widget.index * 80), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scenario;
    final l10n = AppLocalizations.of(context)!;
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) {
              setState(() => _pressed = false);
              context.push('/rights/${s.id}');
            },
            onTapCancel: () => setState(() => _pressed = false),
            child: AnimatedScale(
              scale: _pressed ? 0.97 : 1.0,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeInOut,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: _pressed
                        ? s.color.withValues(alpha: 0.3)
                        : AppColors.border,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: s.color.withValues(alpha: _pressed ? 0.12 : 0.06),
                      blurRadius: _pressed ? 20 : 12,
                      offset: const Offset(0, 4),
                    ),
                    if (_pressed)
                      BoxShadow(
                        color: s.color.withValues(alpha: 0.06),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: s.color,
                          width: 4,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          // Larger icon container with glow
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  s.color.withValues(alpha: 0.15),
                                  s.color.withValues(alpha: 0.05),
                                ],
                              ),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                              boxShadow: [
                                BoxShadow(
                                  color: s.color.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(s.icon, color: s.color, size: 28),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title row
                                Text(
                                  s.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  s.subtitle,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                // Bottom row: tag + rights count badge
                                Row(
                                  children: [
                                    _CategoryTag(
                                      label: s.tag,
                                      color: s.color,
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(
                                            AppRadius.full),
                                      ),
                                      child: Text(
                                        l10n.rightsInsideCount(s.rightsCount),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: s.color.withValues(alpha: 0.5),
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryTag extends StatelessWidget {
  const _CategoryTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _RightsScenario {
  const _RightsScenario({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.category,
    required this.rightsCount,
    required this.tag,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String category;
  final int rightsCount;
  final String tag;
}
