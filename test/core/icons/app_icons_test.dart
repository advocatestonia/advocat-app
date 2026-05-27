// Tests for the Advocat brand icon vocabulary.
//
// Goal: guard against silent regressions where a glyph is removed from
// AppIcons (which would silently break every screen that references it).
//
// These are intentionally cheap — they only verify the constants exist and
// expose valid IconData. Visual fidelity is owned by widget golden tests in
// individual screens.

import 'package:advocat/core/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

void main() {
  group('AppIcons', () {
    test('exposes the documented set (20 functional + 3 empty-state)', () {
      // If you add/remove an icon, update these counts and the matching docs.
      expect(AppIcons.all.length, 20);
      expect(AppIcons.emptyStates.length, 3);
    });

    test('all functional icons are non-null IconData', () {
      for (final icon in AppIcons.all) {
        expect(icon, isA<IconData>(), reason: 'icon should be IconData');
        expect(icon.codePoint, isNonZero, reason: 'icon must have codePoint');
      }
    });

    test('all empty-state icons are non-null IconData', () {
      for (final icon in AppIcons.emptyStates) {
        expect(icon, isA<IconData>());
        expect(icon.codePoint, isNonZero);
      }
    });

    test('functional icons come from Phosphor Regular variant', () {
      // Brand decision: 1.5px stroke (regular) matches Inter typography.
      for (final icon in AppIcons.all) {
        expect(icon, isA<PhosphorIconData>(),
            reason: 'AppIcons.all should only contain Phosphor glyphs');
        expect(icon.fontFamily, 'PhosphorRegular',
            reason: 'functional icons must use Phosphor Regular variant');
      }
    });

    test('empty-state icons come from Phosphor Thin variant', () {
      // Brand decision: thin variant for oversized illustrative glyphs.
      for (final icon in AppIcons.emptyStates) {
        expect(icon.fontFamily, 'PhosphorThin',
            reason: 'empty-state icons must use Phosphor Thin variant');
      }
    });

    test('no duplicate code points in the functional set', () {
      final seen = <int, IconData>{};
      for (final icon in AppIcons.all) {
        expect(seen.containsKey(icon.codePoint), isFalse,
            reason: 'duplicate codePoint 0x${icon.codePoint.toRadixString(16)} '
                '— two AppIcons constants map to the same glyph');
        seen[icon.codePoint] = icon;
      }
    });

    test('individual constants resolve (smoke)', () {
      // Spot-check the most-used glyphs. If a future Phosphor version renames
      // or removes one of these, the failure pinpoints which constant broke.
      expect(AppIcons.chat.codePoint, isNonZero);
      expect(AppIcons.document.codePoint, isNonZero);
      expect(AppIcons.send.codePoint, isNonZero);
      expect(AppIcons.home.codePoint, isNonZero);
      expect(AppIcons.inbox.codePoint, isNonZero);
      expect(AppIcons.settings.codePoint, isNonZero);
      expect(AppIcons.urgent.codePoint, isNonZero);
      expect(AppIcons.deadline.codePoint, isNonZero);
    });
  });

  group('AppIcons renders in an Icon widget', () {
    testWidgets('functional icon renders without throwing', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Icon(AppIcons.chat, size: 24),
        ),
      );
      expect(find.byIcon(AppIcons.chat), findsOneWidget);
    });

    testWidgets('empty-state icon renders without throwing', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Icon(AppIcons.emptyDocuments, size: 64),
        ),
      );
      expect(find.byIcon(AppIcons.emptyDocuments), findsOneWidget);
    });
  });
}
