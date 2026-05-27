import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../config/theme.dart';

// ---------------------------------------------------------------------------
// Reusable Shimmer Skeleton Widgets
//
// WCAG 2.3.3 / prefers-reduced-motion: when
// `MediaQuery.of(context).disableAnimations` is true the shimmer animation
// is replaced with a static neutral-grey block so motion-sensitive users
// (vestibular disorders, etc.) don't see the pulsing gradient. The
// placeholder rectangles still occupy the same layout space so cold-start
// reflow remains identical between the two paths.
// ---------------------------------------------------------------------------

/// Wraps [child] in a [Shimmer.fromColors] effect unless reduce-motion is
/// active, in which case it returns the child wrapped in a static grey
/// [DefaultTextStyle]-free container. Used by every skeleton primitive
/// below so reduce-motion behaviour is uniform.
class _ReduceMotionShimmer extends StatelessWidget {
  const _ReduceMotionShimmer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    if (disableAnimations) {
      // Static fallback — paints the same _SkeletonBox-coloured surface but
      // without the animated gradient sweep.
      return Container(color: Colors.transparent, child: child);
    }
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: child,
    );
  }
}

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
    return _ReduceMotionShimmer(
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
    return _ReduceMotionShimmer(
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

// ---------------------------------------------------------------------------
// HomeHeaderSkeleton — greeting row + deadline radar pill placeholder.
// Sits at the top of HomeScreen while currentUser / deadlines / cases
// providers are warming up.
// ---------------------------------------------------------------------------

class HomeHeaderSkeleton extends StatelessWidget {
  const HomeHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ReduceMotionShimmer(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting row: avatar circle + headline text
            Row(
              children: [
                _SkeletonBox(width: 40, height: 40, borderRadius: 999),
                SizedBox(width: 10),
                Expanded(
                  child: _SkeletonBox(width: double.infinity, height: 22),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.lg),
            // Deadline radar pill placeholder
            _SkeletonBox(
              width: double.infinity,
              height: 56,
              borderRadius: 12,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// MessageBubbleSkeleton — alternating left/right chat bubble placeholders.
// ---------------------------------------------------------------------------

class MessageBubbleSkeleton extends StatelessWidget {
  const MessageBubbleSkeleton({super.key, this.isUser = false});

  /// Right-aligned (true) or left-aligned (false) bubble.
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    return _ReduceMotionShimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Align(
          alignment: isUser
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: const [
                _SkeletonBox(width: 220, height: 14, borderRadius: 12),
                SizedBox(height: 6),
                _SkeletonBox(width: 180, height: 14, borderRadius: 12),
                SizedBox(height: 6),
                _SkeletonBox(width: 120, height: 14, borderRadius: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Renders N alternating [MessageBubbleSkeleton]s. Default count of 3
/// matches the brief.
class ChatThreadSkeleton extends StatelessWidget {
  const ChatThreadSkeleton({super.key, this.itemCount = 3});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (_, i) => MessageBubbleSkeleton(isUser: i.isOdd),
    );
  }
}

// ---------------------------------------------------------------------------
// DocumentTileSkeleton — vault / drafts list-tile placeholder. Mirrors the
// real tile's icon + 2-line text + chevron layout so the swap-in doesn't
// cause vertical jitter.
// ---------------------------------------------------------------------------

class DocumentTileSkeleton extends StatelessWidget {
  const DocumentTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _ReduceMotionShimmer(
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          children: [
            _SkeletonBox(width: 32, height: 32, borderRadius: 8),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonBox(width: double.infinity, height: 14),
                  SizedBox(height: 8),
                  _SkeletonBox(width: 120, height: 12),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            _SkeletonBox(width: 16, height: 16, borderRadius: 4),
          ],
        ),
      ),
    );
  }
}

/// Ready-made list of [DocumentTileSkeleton]s — vault + drafts share this.
class DocumentListSkeleton extends StatelessWidget {
  const DocumentListSkeleton({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        100,
      ),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (_, __) => const DocumentTileSkeleton(),
    );
  }
}
