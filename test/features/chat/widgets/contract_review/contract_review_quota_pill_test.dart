@Tags(['fast'])
library;

// =============================================================================
// contract_review_quota_pill_test.dart — Pkg Contract Review pill widget.
// =============================================================================
//
// Pins the three visual states of the quota pill and the inline upgrade CTA:
//
//   1. Free + 0 used   → "Free trial: 1 contract review" (normal)
//   2. Free + 1 used   → "Free trial used — upgrade for more" (exhausted,
//                         red, with inline CTA)
//   3. Counsel (basic) + 5 left → "5 contract reviews left this month"
//                                  (normal)
//   4. Counsel + 1 left → near-limit (yellow)
//   5. Counsel + 0 left → exhausted (red + CTA)
//   6. Pro (premium) + 20 left → normal
//   7. Pro + 0 left → exhausted
//
// Plus: tapping the CTA fires the onUpgrade callback exactly once.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/chat/services/contract_review_quota_service.dart';
import 'package:advocat/features/chat/widgets/contract_review_quota_pill.dart';
import 'package:advocat/l10n/app_localizations.dart';
import 'package:advocat/models/user.dart';

ContractReviewQuota _quota(
  SubscriptionTier tier,
  int used, {
  DateTime? periodStart,
}) =>
    ContractReviewQuota(
      tier: tier,
      used: used,
      periodStart: periodStart ?? DateTime.now(),
    );

Widget _wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Padding(padding: const EdgeInsets.all(8), child: child),
    ),
  );
}

void main() {
  group('ContractReviewQuotaPill — visual state', () {
    testWidgets('free + 0 used → normal state with trial copy',
        (tester) async {
      await tester.pumpWidget(_wrap(
        ContractReviewQuotaPill(
          quota: _quota(SubscriptionTier.free, 0),
          onUpgrade: () {},
        ),
      ));
      await tester.pump();
      expect(
        find.byKey(const Key('contract_review_quota_pill_normal')),
        findsOneWidget,
      );
      expect(find.textContaining('Free trial'), findsOneWidget);
      // No inline CTA in normal state.
      expect(
        find.byKey(const Key('contract_review_quota_pill_upgrade_cta')),
        findsNothing,
      );
    });

    testWidgets('free + 1 used → exhausted state with upgrade CTA',
        (tester) async {
      var ctaTaps = 0;
      await tester.pumpWidget(_wrap(
        ContractReviewQuotaPill(
          quota: _quota(SubscriptionTier.free, 1),
          onUpgrade: () => ctaTaps++,
        ),
      ));
      await tester.pump();
      expect(
        find.byKey(const Key('contract_review_quota_pill_exhausted')),
        findsOneWidget,
      );
      expect(find.textContaining('Free trial used'), findsOneWidget);
      // Inline CTA present.
      final cta = find.byKey(
        const Key('contract_review_quota_pill_upgrade_cta'),
      );
      expect(cta, findsOneWidget);
      await tester.tap(cta);
      expect(ctaTaps, 1, reason: 'CTA tap must fire onUpgrade exactly once');
    });

    testWidgets('counsel + 5 left → normal state with monthly copy',
        (tester) async {
      await tester.pumpWidget(_wrap(
        ContractReviewQuotaPill(
          quota: _quota(SubscriptionTier.basic, 0),
          onUpgrade: () {},
        ),
      ));
      await tester.pump();
      expect(
        find.byKey(const Key('contract_review_quota_pill_normal')),
        findsOneWidget,
      );
      expect(find.textContaining('5 contract reviews left'), findsOneWidget);
    });

    testWidgets('counsel + 4 left (1 used) → normal (not yet near-limit)',
        (tester) async {
      await tester.pumpWidget(_wrap(
        ContractReviewQuotaPill(
          quota: _quota(SubscriptionTier.basic, 1),
          onUpgrade: () {},
        ),
      ));
      await tester.pump();
      expect(
        find.byKey(const Key('contract_review_quota_pill_normal')),
        findsOneWidget,
      );
    });

    testWidgets('counsel + 1 left → near-limit (yellow warning)',
        (tester) async {
      // Quota: basic limit=5, used=4 → remaining=1 → near-limit (yellow).
      await tester.pumpWidget(_wrap(
        ContractReviewQuotaPill(
          quota: _quota(SubscriptionTier.basic, 4),
          onUpgrade: () {},
        ),
      ));
      await tester.pump();
      expect(
        find.byKey(const Key('contract_review_quota_pill_nearLimit')),
        findsOneWidget,
      );
      // Still no inline CTA — only the exhausted state has it.
      expect(
        find.byKey(const Key('contract_review_quota_pill_upgrade_cta')),
        findsNothing,
      );
    });

    testWidgets('counsel + 0 left → exhausted (red + CTA)',
        (tester) async {
      await tester.pumpWidget(_wrap(
        ContractReviewQuotaPill(
          quota: _quota(SubscriptionTier.basic, 5),
          onUpgrade: () {},
        ),
      ));
      await tester.pump();
      expect(
        find.byKey(const Key('contract_review_quota_pill_exhausted')),
        findsOneWidget,
      );
      expect(find.textContaining('No contract reviews left'), findsOneWidget);
      expect(
        find.byKey(const Key('contract_review_quota_pill_upgrade_cta')),
        findsOneWidget,
      );
    });

    testWidgets('pro + 20 left → normal state shows 20', (tester) async {
      await tester.pumpWidget(_wrap(
        ContractReviewQuotaPill(
          quota: _quota(SubscriptionTier.premium, 0),
          onUpgrade: () {},
        ),
      ));
      await tester.pump();
      expect(find.textContaining('20 contract reviews left'), findsOneWidget);
    });

    testWidgets('pro + 0 left → exhausted', (tester) async {
      await tester.pumpWidget(_wrap(
        ContractReviewQuotaPill(
          quota: _quota(SubscriptionTier.premium, 20),
          onUpgrade: () {},
        ),
      ));
      await tester.pump();
      expect(
        find.byKey(const Key('contract_review_quota_pill_exhausted')),
        findsOneWidget,
      );
    });
  });

  group('ContractReviewQuotaPill — window roll behaviour', () {
    testWidgets('basic + 5 used but window expired → shows full quota again',
        (tester) async {
      // Window > 30 days old → remaining == limit (5) even though used=5.
      final old = DateTime.now().subtract(const Duration(days: 45));
      await tester.pumpWidget(_wrap(
        ContractReviewQuotaPill(
          quota: _quota(SubscriptionTier.basic, 5, periodStart: old),
          onUpgrade: () {},
        ),
      ));
      await tester.pump();
      expect(find.textContaining('5 contract reviews left'), findsOneWidget);
      expect(
        find.byKey(const Key('contract_review_quota_pill_normal')),
        findsOneWidget,
      );
    });

    testWidgets('free + 1 used after 60 days → STILL exhausted (lifetime)',
        (tester) async {
      // Free is a lifetime cap — window never rolls.
      final old = DateTime.now().subtract(const Duration(days: 60));
      await tester.pumpWidget(_wrap(
        ContractReviewQuotaPill(
          quota: _quota(SubscriptionTier.free, 1, periodStart: old),
          onUpgrade: () {},
        ),
      ));
      await tester.pump();
      expect(
        find.byKey(const Key('contract_review_quota_pill_exhausted')),
        findsOneWidget,
      );
    });
  });
}
