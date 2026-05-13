@Tags(['fast'])
library;

// =============================================================================
// contract_review_upgrade_dialog_test.dart — Pkg Contract Review upgrade modal.
// =============================================================================
//
// Pins:
//   1. Free user sees BOTH CTAs (Counsel + Pro). Tapping each pops with the
//      matching [ContractReviewUpgradeChoice].
//   2. Counsel (basic) user sees ONLY the Pro CTA (Counsel = current plan).
//   3. Dismiss button pops with null.
//   4. Pricing copy is exactly €19.99 / €29.99 (NOT €14.99 — see
//      reference_current_pricing.md).
//   5. Free body copy mentions the lifetime trial; paid body copy shows
//      used/cap counts.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/chat/services/contract_review_quota_service.dart';
import 'package:advocat/features/chat/widgets/contract_review_upgrade_dialog.dart';
import 'package:advocat/l10n/app_localizations.dart';
import 'package:advocat/models/user.dart';

ContractReviewQuota _quota(SubscriptionTier tier, int used) =>
    ContractReviewQuota(
      tier: tier,
      used: used,
      periodStart: DateTime.now(),
    );

Widget _wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('ContractReviewUpgradeDialog — free user', () {
    testWidgets('renders both Counsel and Pro CTAs', (tester) async {
      await tester.pumpWidget(_wrap(
        ContractReviewUpgradeDialog(quota: _quota(SubscriptionTier.free, 1)),
      ));
      await tester.pump();
      expect(find.byKey(ContractReviewUpgradeDialogKeys.root), findsOneWidget);
      expect(
        find.byKey(ContractReviewUpgradeDialogKeys.counselCta),
        findsOneWidget,
      );
      expect(
        find.byKey(ContractReviewUpgradeDialogKeys.proCta),
        findsOneWidget,
      );
      expect(
        find.byKey(ContractReviewUpgradeDialogKeys.dismiss),
        findsOneWidget,
      );
    });

    testWidgets('shows free-trial body copy', (tester) async {
      await tester.pumpWidget(_wrap(
        ContractReviewUpgradeDialog(quota: _quota(SubscriptionTier.free, 1)),
      ));
      await tester.pump();
      expect(find.textContaining('free contract review'), findsOneWidget);
    });

    testWidgets('CTA labels carry €19.99 / €29.99 pricing exactly',
        (tester) async {
      await tester.pumpWidget(_wrap(
        ContractReviewUpgradeDialog(quota: _quota(SubscriptionTier.free, 1)),
      ));
      await tester.pump();
      // Counsel CTA — must say €19.99/mo, NEVER €14.99.
      expect(find.textContaining('€19.99'), findsOneWidget);
      expect(find.textContaining('€14.99'), findsNothing);
      // Pro CTA — €29.99/mo.
      expect(find.textContaining('€29.99'), findsOneWidget);
      // Cap counts present.
      expect(find.textContaining('5 reviews'), findsOneWidget);
      expect(find.textContaining('20 reviews'), findsOneWidget);
    });

    testWidgets('Counsel CTA pops with counsel choice', (tester) async {
      ContractReviewUpgradeChoice? choice;
      // Use a Navigator + showDialog so we can capture the pop result.
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (ctx) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    choice = await showContractReviewUpgradeDialog(
                      ctx,
                      quota: _quota(SubscriptionTier.free, 1),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ContractReviewUpgradeDialogKeys.counselCta));
      await tester.pumpAndSettle();
      expect(choice, ContractReviewUpgradeChoice.counsel);
    });

    testWidgets('Pro CTA pops with pro choice', (tester) async {
      ContractReviewUpgradeChoice? choice;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (ctx) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    choice = await showContractReviewUpgradeDialog(
                      ctx,
                      quota: _quota(SubscriptionTier.free, 1),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ContractReviewUpgradeDialogKeys.proCta));
      await tester.pumpAndSettle();
      expect(choice, ContractReviewUpgradeChoice.pro);
    });

    testWidgets('dismiss pops with null', (tester) async {
      ContractReviewUpgradeChoice? choice =
          ContractReviewUpgradeChoice.counsel; // sentinel non-null
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (ctx) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    choice = await showContractReviewUpgradeDialog(
                      ctx,
                      quota: _quota(SubscriptionTier.free, 1),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ContractReviewUpgradeDialogKeys.dismiss));
      await tester.pumpAndSettle();
      expect(choice, null);
    });
  });

  group('ContractReviewUpgradeDialog — counsel user', () {
    testWidgets('renders ONLY the Pro CTA (Counsel = current plan)',
        (tester) async {
      await tester.pumpWidget(_wrap(
        ContractReviewUpgradeDialog(
          quota: _quota(SubscriptionTier.basic, 5),
        ),
      ));
      await tester.pump();
      expect(
        find.byKey(ContractReviewUpgradeDialogKeys.counselCta),
        findsNothing,
      );
      expect(
        find.byKey(ContractReviewUpgradeDialogKeys.proCta),
        findsOneWidget,
      );
    });

    testWidgets('body copy shows 5 of 5 used', (tester) async {
      await tester.pumpWidget(_wrap(
        ContractReviewUpgradeDialog(
          quota: _quota(SubscriptionTier.basic, 5),
        ),
      ));
      await tester.pump();
      // l10n template: "You used {used} of {cap} reviews this month."
      expect(find.textContaining('5 of 5'), findsOneWidget);
    });
  });

  group('Pricing string invariant', () {
    testWidgets('no €14.99 anywhere in dialog (Counsel must be €19.99)',
        (tester) async {
      // Belt-and-braces: search the entire widget tree for "14.99".
      await tester.pumpWidget(_wrap(
        ContractReviewUpgradeDialog(quota: _quota(SubscriptionTier.free, 1)),
      ));
      await tester.pump();
      final allText = find.byType(Text).evaluate().map((el) {
        final w = el.widget as Text;
        return w.data ?? '';
      }).join(' ');
      expect(
        allText.contains('14.99'),
        false,
        reason:
            'Counsel pricing changed to €19.99 in May 2026 — never €14.99',
      );
    });
  });
}
