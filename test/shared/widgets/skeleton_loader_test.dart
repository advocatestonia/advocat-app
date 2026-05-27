@Tags(['fast'])
library;

// =============================================================================
// SkeletonLoader — widget tests for the cold-start shimmer primitives added
// 2026-05-27. Covers the 5 layouts wired to the 5 target screens:
//   * CaseCardSkeleton          → Home + Cases list
//   * CaseListSkeletonLoader    → Cases list
//   * ChatThreadSkeleton        → Chat thread
//   * DocumentTileSkeleton      → Vault + Drafts (shared)
//   * DocumentListSkeleton      → Vault + Drafts
//   * HomeHeaderSkeleton        → Home greeting + radar
//   * MessageBubbleSkeleton     → individual chat bubble
//   * GenericListSkeleton       → catch-all
//
// Also covers WCAG 2.3.3 / prefers-reduced-motion: when
// `MediaQuery.disableAnimations` is true the inner Shimmer is replaced with
// a static container, so we assert exactly one Shimmer in the default tree
// and zero Shimmers when reduce-motion is on.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shimmer/shimmer.dart';

import 'package:advocat/shared/widgets/skeleton_loader.dart';

Widget _wrap(Widget child, {bool reduceMotion = false}) {
  return MaterialApp(
    home: Scaffold(
      body: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: child,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CaseCardSkeleton', () {
    testWidgets('renders with a Shimmer wrapper by default', (tester) async {
      await tester.pumpWidget(_wrap(const CaseCardSkeleton()));
      await tester.pump(); // one frame; Shimmer needs no settle

      expect(find.byType(CaseCardSkeleton), findsOneWidget);
      expect(find.byType(Shimmer), findsOneWidget);
    });

    testWidgets(
        'reduce-motion: drops the Shimmer and keeps the static placeholder',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const CaseCardSkeleton(),
        reduceMotion: true,
      ));
      await tester.pump();

      expect(find.byType(CaseCardSkeleton), findsOneWidget);
      expect(find.byType(Shimmer), findsNothing,
          reason: 'WCAG 2.3.3: shimmer animation must be suppressed when '
              'MediaQuery.disableAnimations is true.');
    });
  });

  group('CaseListSkeletonLoader', () {
    testWidgets('default item count renders 4 CaseCardSkeletons',
        (tester) async {
      await tester.pumpWidget(_wrap(const SizedBox(
        height: 800,
        child: CaseListSkeletonLoader(),
      )));
      await tester.pump();

      expect(find.byType(CaseCardSkeleton), findsNWidgets(4));
    });

    testWidgets('custom itemCount honored', (tester) async {
      await tester.pumpWidget(_wrap(const SizedBox(
        height: 800,
        child: CaseListSkeletonLoader(itemCount: 2),
      )));
      await tester.pump();

      expect(find.byType(CaseCardSkeleton), findsNWidgets(2));
    });
  });

  group('ChatThreadSkeleton', () {
    testWidgets('default renders 3 alternating MessageBubbleSkeletons (brief)',
        (tester) async {
      await tester.pumpWidget(_wrap(const SizedBox(
        height: 800,
        child: ChatThreadSkeleton(),
      )));
      await tester.pump();

      expect(find.byType(MessageBubbleSkeleton), findsNWidgets(3));
    });

    testWidgets('reduce-motion: no Shimmer wrappers in the subtree',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const SizedBox(height: 800, child: ChatThreadSkeleton()),
        reduceMotion: true,
      ));
      await tester.pump();

      expect(find.byType(Shimmer), findsNothing);
      expect(find.byType(MessageBubbleSkeleton), findsNWidgets(3));
    });
  });

  group('DocumentTileSkeleton + DocumentListSkeleton', () {
    testWidgets('individual tile wraps in Shimmer', (tester) async {
      await tester.pumpWidget(_wrap(const DocumentTileSkeleton()));
      await tester.pump();

      expect(find.byType(DocumentTileSkeleton), findsOneWidget);
      expect(find.byType(Shimmer), findsOneWidget);
    });

    testWidgets('vault default count = 5', (tester) async {
      await tester.pumpWidget(_wrap(const SizedBox(
        height: 800,
        child: DocumentListSkeleton(),
      )));
      await tester.pump();

      expect(find.byType(DocumentTileSkeleton), findsNWidgets(5));
    });

    testWidgets('drafts variant: itemCount: 4 honoured', (tester) async {
      await tester.pumpWidget(_wrap(const SizedBox(
        height: 800,
        child: DocumentListSkeleton(itemCount: 4),
      )));
      await tester.pump();

      expect(find.byType(DocumentTileSkeleton), findsNWidgets(4));
    });
  });

  group('HomeHeaderSkeleton', () {
    testWidgets('renders with a single Shimmer wrapper by default',
        (tester) async {
      await tester.pumpWidget(_wrap(const HomeHeaderSkeleton()));
      await tester.pump();

      expect(find.byType(HomeHeaderSkeleton), findsOneWidget);
      expect(find.byType(Shimmer), findsOneWidget);
    });
  });

  group('GenericListSkeleton', () {
    testWidgets('renders the requested item count', (tester) async {
      await tester.pumpWidget(_wrap(const SizedBox(
        height: 600,
        child: GenericListSkeleton(itemCount: 6),
      )));
      await tester.pump();

      // Inside the shimmer, _SkeletonBox is private — assert via the
      // FractionallySizedBox count, which the implementation creates per
      // item.
      expect(find.byType(FractionallySizedBox), findsNWidgets(6));
    });

    testWidgets('reduce-motion: Shimmer is suppressed', (tester) async {
      await tester.pumpWidget(_wrap(
        const SizedBox(
          height: 600,
          child: GenericListSkeleton(itemCount: 3),
        ),
        reduceMotion: true,
      ));
      await tester.pump();

      expect(find.byType(Shimmer), findsNothing);
      expect(find.byType(FractionallySizedBox), findsNWidgets(3));
    });
  });

  // ── End-to-end-ish: 5 screen-shape contracts ──────────────────────────
  //
  // We pump the exact widget shapes each of the 5 wired screens uses on
  // cold-start, then resolve the data future and assert the skeleton is
  // replaced. Because the screens require Riverpod + GoRouter scaffolding
  // we can't pumpWidget them directly here without a much larger harness;
  // instead, this group verifies the building-block contract — the
  // skeleton is visible when isLoading is true and gone when false.
  group('Screen-shape contracts (5 screens × loading↔ready)', () {
    Widget loadingOrReady({required bool loading, required Widget skeleton}) {
      return loading ? skeleton : const Text('READY');
    }

    Future<void> runContract(
      WidgetTester tester, {
      required Widget skeleton,
      required Finder skeletonFinder,
    }) async {
      // Phase 1: loading — skeleton visible.
      await tester.pumpWidget(_wrap(SizedBox(
        height: 800,
        child: loadingOrReady(loading: true, skeleton: skeleton),
      )));
      await tester.pump();
      expect(skeletonFinder, findsWidgets,
          reason: 'Skeleton must be visible while data is loading.');
      expect(find.text('READY'), findsNothing);

      // Phase 2: data resolved — skeleton gone, real content visible.
      await tester.pumpWidget(_wrap(SizedBox(
        height: 800,
        child: loadingOrReady(loading: false, skeleton: skeleton),
      )));
      await tester.pump();
      expect(skeletonFinder, findsNothing);
      expect(find.text('READY'), findsOneWidget);
    }

    testWidgets('Home (CaseCardSkeleton)', (tester) async {
      await runContract(
        tester,
        skeleton: const CaseCardSkeleton(),
        skeletonFinder: find.byType(CaseCardSkeleton),
      );
    });

    testWidgets('Chat (ChatThreadSkeleton)', (tester) async {
      await runContract(
        tester,
        skeleton: const ChatThreadSkeleton(),
        skeletonFinder: find.byType(MessageBubbleSkeleton),
      );
    });

    testWidgets('Cases list (CaseListSkeletonLoader)', (tester) async {
      await runContract(
        tester,
        skeleton: const CaseListSkeletonLoader(),
        skeletonFinder: find.byType(CaseCardSkeleton),
      );
    });

    testWidgets('Vault (DocumentListSkeleton)', (tester) async {
      await runContract(
        tester,
        skeleton: const DocumentListSkeleton(itemCount: 5),
        skeletonFinder: find.byType(DocumentTileSkeleton),
      );
    });

    testWidgets('Drafts (DocumentListSkeleton itemCount=4)', (tester) async {
      await runContract(
        tester,
        skeleton: const DocumentListSkeleton(itemCount: 4),
        skeletonFinder: find.byType(DocumentTileSkeleton),
      );
    });
  });
}
