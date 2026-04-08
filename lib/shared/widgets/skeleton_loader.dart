import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../config/theme.dart';

// ---------------------------------------------------------------------------
// Reusable Shimmer Skeleton Widgets
// ---------------------------------------------------------------------------

/// A single rounded rectangle placeholder used inside shimmer effects.
class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    this.borderRadius = 6.0,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CaseCardSkeleton — matches the layout of a real CaseCard
// ---------------------------------------------------------------------------

class CaseCardSkeleton extends StatelessWidget {
  const CaseCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left color bar placeholder
              Container(
                width: 3,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              // Card content
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row: title bar + status badge placeholder
                      Row(
                        children: [
                          Expanded(
                            child: _SkeletonBox(width: double.infinity, height: 16),
                          ),
                          SizedBox(width: AppSpacing.sm),
                          _SkeletonBox(width: 80, height: 22, borderRadius: 999),
                        ],
                      ),
                      SizedBox(height: AppSpacing.sm),
                      // Chips row
                      Row(
                        children: [
                          _SkeletonBox(width: 90, height: 20, borderRadius: 999),
                          SizedBox(width: AppSpacing.sm),
                          _SkeletonBox(width: 70, height: 20, borderRadius: 999),
                        ],
                      ),
                      SizedBox(height: AppSpacing.sm),
                      // Bottom row: activity text placeholder
                      _SkeletonBox(width: 160, height: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// GenericListSkeleton — renders N skeleton items for any list loading state
// ---------------------------------------------------------------------------

class GenericListSkeleton extends StatelessWidget {
  const GenericListSkeleton({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 20.0,
    this.spacing = AppSpacing.md,
  });

  final int itemCount;
  final double itemHeight;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(itemCount, (index) {
            // Alternate widths for a natural look
            final widthFactor = index.isEven ? 1.0 : 0.75;
            return Padding(
              padding: EdgeInsets.only(bottom: spacing),
              child: FractionallySizedBox(
                widthFactor: widthFactor,
                alignment: Alignment.centerLeft,
                child: _SkeletonBox(
                  width: double.infinity,
                  height: itemHeight,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CaseListSkeletonLoader — a ready-made list of CaseCardSkeleton items
// ---------------------------------------------------------------------------

class CaseListSkeletonLoader extends StatelessWidget {
  const CaseListSkeletonLoader({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        100, // FAB clearance
      ),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, __) => const CaseCardSkeleton(),
    );
  }
}
