import 'package:flutter/material.dart';

import '../../config/theme.dart';

/// Reusable gradient-shield header matching the home screen greeting style.
///
/// Drop-in replacement for `AppBar(title: Text(...))` on secondary screens to
/// keep visual consistency with the polished home header (40×40 gradient shield
/// + `ShaderMask` gradient title). Use as `appBar:` on a `Scaffold`.
///
/// Behaviour:
///   * If [onBack] is provided, a back arrow is rendered before the shield and
///     calls [onBack] when tapped.
///   * If [onBack] is `null` but `Navigator.canPop(context)` is `true`, a back
///     arrow is still rendered and calls `Navigator.pop(context)`.
///   * Otherwise no back button is shown.
///
/// Optional [actions] are rendered on the trailing side (e.g. language picker).
class AdvocatGradientHeader extends StatelessWidget
    implements PreferredSizeWidget {
  const AdvocatGradientHeader({
    super.key,
    required this.title,
    this.actions,
    this.onBack,
  });

  final String title;
  final List<Widget>? actions;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final showBack = onBack != null || canPop;
    final effectiveOnBack = onBack ?? (canPop ? () => Navigator.of(context).pop() : null);

    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: showBack ? 0 : AppSpacing.md,
      title: Row(
        children: [
          if (showBack)
            IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
              onPressed: effectiveOnBack,
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            ),
          // Shield brand icon — matches home greeting header
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.accent.withValues(alpha: 0.15),
                  AppColors.primary.withValues(alpha: 0.10),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: AppColors.accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
              ).createShader(bounds),
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
      actions: actions,
    );
  }
}
