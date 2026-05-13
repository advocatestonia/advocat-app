// gold_review_card_test.dart — Sofia Gold Corpus Phase A widget test.
// -----------------------------------------------------------------------------
// Coverage:
//   - Card renders the truncated question and answer preview.
//   - Card surfaces language + category chips when present.
//   - onTap callback fires when the card is tapped.
//   - Selected variant renders without throwing.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/admin/widgets/gold_review_card.dart';
import 'package:advocat/services/gold_review_service.dart';

GoldQueueItem _item({
  String id = '11111111-1111-1111-1111-111111111111',
  String? language = 'et',
  String? category = 'employment',
  String question =
      'Tööandja ütles, et koondamishüvitist ei maksa, kuna ma olin tähtajalise lepinguga.',
  String answer = 'Üldjuhul ei. TLS § 100 sätestab koondamishüvitise.',
}) {
  return GoldQueueItem(
    id: id,
    createdAt: DateTime.now().subtract(const Duration(minutes: 17)),
    userQuestion: question,
    aiAnswer: answer,
    language: language,
    category: category,
    jurisdiction: 'estonia',
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('GoldReviewCard renders question + answer preview',
      (tester) async {
    final item = _item();
    await tester.pumpWidget(
      _wrap(GoldReviewCard(
        item: item,
        selected: false,
        onTap: () {},
      )),
    );
    expect(find.textContaining('Tööandja ütles'), findsOneWidget);
    expect(find.textContaining('TLS § 100'), findsOneWidget);
  });

  testWidgets('GoldReviewCard shows language and category chips',
      (tester) async {
    final item = _item(language: 'et', category: 'employment');
    await tester.pumpWidget(
      _wrap(GoldReviewCard(
        item: item,
        selected: false,
        onTap: () {},
      )),
    );
    expect(find.text('ET'), findsOneWidget);
    expect(find.text('employment'), findsOneWidget);
  });

  testWidgets('GoldReviewCard fires onTap', (tester) async {
    var tapped = 0;
    final item = _item();
    await tester.pumpWidget(
      _wrap(GoldReviewCard(
        item: item,
        selected: false,
        onTap: () => tapped++,
      )),
    );
    await tester.tap(find.byType(InkWell));
    await tester.pump();
    expect(tapped, 1);
  });

  testWidgets('GoldReviewCard selected variant renders without error',
      (tester) async {
    final item = _item();
    await tester.pumpWidget(
      _wrap(GoldReviewCard(
        item: item,
        selected: true,
        onTap: () {},
      )),
    );
    expect(find.byType(GoldReviewCard), findsOneWidget);
  });

  testWidgets('GoldReviewCard chips hidden when classification missing',
      (tester) async {
    final item = _item(language: null, category: null);
    await tester.pumpWidget(
      _wrap(GoldReviewCard(
        item: item,
        selected: false,
        onTap: () {},
      )),
    );
    expect(find.text('ET'), findsNothing);
    expect(find.text('employment'), findsNothing);
  });
}
