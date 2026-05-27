@Tags(['fast'])
library;

// Widget tests for Track 1B Templates Picker (Drafting Studio).
// -----------------------------------------------------------------------------
// Covers:
//   * 5 cards render in spec order: blank / letter / appeal / memo / contract.
//   * Contract reply card is locked when the user has no contract reviews.
//   * Contract reply card unlocks when the probe returns true.
//   * Catalogue builder maps each option to the correct DraftSourceType.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/drafting/models/draft_model.dart';
import 'package:advocat/features/drafting/screens/draft_templates_screen.dart';
import 'package:advocat/features/drafting/widgets/drafting_strings.dart';

Widget _wrap(Widget child, {bool hasReviews = false}) {
  debugContractReviewProbe = () async => hasReviews;
  addTearDown(() {
    debugContractReviewProbe = null;
  });
  return ProviderScope(
    child: MaterialApp(home: child),
  );
}

void main() {
  group('buildTemplateCatalogue', () {
    test('returns 5 options in spec order', () {
      final cat = buildTemplateCatalogue(DraftingStrings.forCode('en'));
      expect(cat.length, 5);
      expect(cat[0].sourceType, DraftSourceType.blank);
      expect(cat[1].sourceType, DraftSourceType.letter);
      expect(cat[2].sourceType, DraftSourceType.appeal);
      expect(cat[3].sourceType, DraftSourceType.memo);
      expect(cat[4].sourceType, DraftSourceType.contractReviewReply);
    });

    test('only the contract reply card requires contract reviews', () {
      final cat = buildTemplateCatalogue(DraftingStrings.forCode('en'));
      expect(cat.where((t) => t.requiresContractReview).length, 1);
      expect(cat.last.requiresContractReview, true);
    });

    test('starter markdown is populated for non-blank templates', () {
      final cat = buildTemplateCatalogue(DraftingStrings.forCode('en'));
      expect(cat[0].starterMarkdown, ''); // blank
      expect(cat[1].starterMarkdown, isNotEmpty); // letter
      expect(cat[2].starterMarkdown, contains('# Appeal'));
      expect(cat[3].starterMarkdown, contains('# Legal memo'));
      expect(cat[4].starterMarkdown, contains('# Reply on contract review'));
    });

    test('Estonian locale produces translated titles', () {
      final cat = buildTemplateCatalogue(DraftingStrings.forCode('et'));
      expect(cat[2].title, 'Kaebus');
      expect(cat[3].title, 'Memo');
    });
  });

  group('DraftTemplatesScreen', () {
    testWidgets('renders all 5 cards', (tester) async {
      await tester.pumpWidget(_wrap(const DraftTemplatesScreen()));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('draft_template_card_blank')), findsOneWidget);
      expect(find.byKey(const Key('draft_template_card_letter')), findsOneWidget);
      expect(find.byKey(const Key('draft_template_card_appeal')), findsOneWidget);
      expect(find.byKey(const Key('draft_template_card_memo')), findsOneWidget);
      expect(
          find.byKey(const Key('draft_template_card_contract_review_reply')),
          findsOneWidget);
    });

    testWidgets('contract reply card shows locked label when no reviews',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const DraftTemplatesScreen(),
        hasReviews: false,
      ));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('draft_template_locked_contract_review_reply')),
        findsOneWidget,
      );
    });

    testWidgets('contract reply card unlocked when user has at least 1 review',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const DraftTemplatesScreen(),
        hasReviews: true,
      ));
      await tester.pumpAndSettle();
      // Locked label is hidden — the InkWell is tappable.
      expect(
        find.byKey(const Key('draft_template_locked_contract_review_reply')),
        findsNothing,
      );
    });
  });
}
