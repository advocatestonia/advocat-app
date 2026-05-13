@Tags(['fast'])
library;

// Widget tests for [ShareResultButton].
//
// We verify:
//   * The button renders the ios_share icon for a valid source UUID.
//   * The button is hidden when sourceId is empty.
//   * Tapping in demo mode (no Supabase init) yields the synthetic share
//     and the onShared callback fires with the right payload.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/chat/widgets/share_result_button.dart';
import 'package:advocat/services/share_result_service.dart';

Widget _wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

const _validUuid = '11111111-1111-1111-1111-111111111111';

void main() {
  group('ShareResultButton — rendering', () {
    testWidgets('shows the ios_share icon for a valid source UUID',
        (tester) async {
      await tester.pumpWidget(_wrap(const ShareResultButton(
        sourceType: ShareSourceType.legalAdvice,
        sourceId: _validUuid,
      )));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.ios_share_rounded), findsOneWidget);
    });

    testWidgets('renders SizedBox.shrink when sourceId is empty',
        (tester) async {
      await tester.pumpWidget(_wrap(const ShareResultButton(
        sourceType: ShareSourceType.legalAdvice,
        sourceId: '',
      )));
      await tester.pumpAndSettle();
      // No icon, no tooltip — only the shrink box.
      expect(find.byIcon(Icons.ios_share_rounded), findsNothing);
      expect(find.byType(Tooltip), findsNothing);
    });

    testWidgets('exposes the share-button ValueKey for automation',
        (tester) async {
      await tester.pumpWidget(_wrap(const ShareResultButton(
        sourceType: ShareSourceType.contractReview,
        sourceId: _validUuid,
      )));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('share_button_$_validUuid')),
        findsOneWidget,
      );
    });
  });

  group('ShareResultButton — interactions (demo mode)', () {
    testWidgets('tap fires onShared with synthetic demo share',
        (tester) async {
      ShareResult? captured;
      await tester.pumpWidget(_wrap(ShareResultButton(
        sourceType: ShareSourceType.legalAdvice,
        sourceId: _validUuid,
        onShared: (s) => captured = s,
      )));
      await tester.pumpAndSettle();

      // Tap. The share-sheet call (Share.share) is a no-op in test mode —
      // share_plus uses a MethodChannel that quietly succeeds.
      await tester.tap(find.byIcon(Icons.ios_share_rounded));
      await tester.pump(); // start
      await tester.pump(const Duration(milliseconds: 100));

      expect(captured, isNotNull,
          reason: 'onShared should fire on demo-mode tap');
      expect(captured!.slug.isNotEmpty, isTrue);
      expect(
        captured!.shareUrl.startsWith('https://advocat.ee/s/'),
        isTrue,
        reason: 'share URL should follow the /s/<slug> shape',
      );
    });
  });
}
