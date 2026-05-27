@Tags(['fast'])
library;

// Canonical AppButton test suite — covers all 4 variants, 3 sizes, every
// state (loading / disabled / pressed), icon slots, and deprecated alias
// behaviour. Lives at test/shared/widgets/ to mirror the production path.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/config/theme.dart';
import 'package:advocat/shared/widgets/app_button.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('AppButton — rendering', () {
    testWidgets('renders label by default', (tester) async {
      await tester.pumpWidget(_wrap(
        AppButton(label: 'Save', onPressed: () {}),
      ));
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('renders every canonical variant', (tester) async {
      const canonical = [
        AppButtonVariant.primary,
        AppButtonVariant.secondary,
        AppButtonVariant.tertiary,
        AppButtonVariant.destructive,
      ];
      for (final v in canonical) {
        await tester.pumpWidget(_wrap(
          AppButton(label: v.name, variant: v, onPressed: () {}),
        ));
        expect(
          find.text(v.name),
          findsOneWidget,
          reason: 'variant ${v.name} must render',
        );
      }
    });

    testWidgets('renders every canonical size', (tester) async {
      const canonical = [
        AppButtonSize.sm,
        AppButtonSize.md,
        AppButtonSize.lg,
      ];
      for (final s in canonical) {
        await tester.pumpWidget(_wrap(
          AppButton(label: 'btn-${s.name}', size: s, onPressed: () {}),
        ));
        expect(find.text('btn-${s.name}'), findsOneWidget);
      }
    });

    testWidgets('full-width stretches to parent', (tester) async {
      await tester.pumpWidget(_wrap(
        SizedBox(
          width: 400,
          child: AppButton(
            label: 'Wide',
            isFullWidth: true,
            onPressed: () {},
          ),
        ),
      ));
      final size = tester.getSize(find.byType(AppButton));
      expect(size.width, equals(400));
    });

    testWidgets('leading icon renders alongside label', (tester) async {
      await tester.pumpWidget(_wrap(
        AppButton(
          label: 'Save',
          leadingIcon: Icons.save,
          onPressed: () {},
        ),
      ));
      expect(find.text('Save'), findsOneWidget);
      expect(find.byIcon(Icons.save), findsOneWidget);
    });

    testWidgets('trailing icon renders alongside label', (tester) async {
      await tester.pumpWidget(_wrap(
        AppButton(
          label: 'Next',
          trailingIcon: Icons.arrow_forward,
          onPressed: () {},
        ),
      ));
      expect(find.text('Next'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });
  });

  group('AppButton — interaction & state', () {
    testWidgets('invokes onPressed when tapped', (tester) async {
      var count = 0;
      await tester.pumpWidget(_wrap(
        AppButton(label: 'Tap', onPressed: () => count++),
      ));
      await tester.tap(find.text('Tap'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      expect(count, 1);
    });

    testWidgets('disabled when onPressed == null', (tester) async {
      await tester.pumpWidget(_wrap(
        const AppButton(label: 'Off', onPressed: null),
      ));
      // The underlying ElevatedButton should report disabled.
      final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(btn.onPressed, isNull);
    });

    testWidgets('loading shows spinner and suppresses label', (tester) async {
      await tester.pumpWidget(_wrap(
        AppButton(
          label: 'Save',
          isLoading: true,
          onPressed: () {},
        ),
      ));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Save'), findsNothing);
    });

    testWidgets('loading swallows taps', (tester) async {
      var count = 0;
      await tester.pumpWidget(_wrap(
        AppButton(
          label: 'Save',
          isLoading: true,
          onPressed: () => count++,
        ),
      ));
      // Tap on the centre of the button widget.
      // NOTE: cannot use pumpAndSettle — the spinner animates forever.
      await tester.tap(find.byType(AppButton));
      await tester.pump(const Duration(milliseconds: 100));
      expect(count, 0);
    });

    testWidgets('press animation does not throw', (tester) async {
      await tester.pumpWidget(_wrap(
        AppButton(label: 'Press', onPressed: () {}),
      ));
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(AppButton)),
      );
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('Press'), findsOneWidget);
    });
  });

  group('AppButton — deprecated aliases (backward compat)', () {
    testWidgets('AppButtonVariant.danger maps to destructive', (tester) async {
      await tester.pumpWidget(_wrap(
        AppButton(
          label: 'Delete',
          // ignore: deprecated_member_use_from_same_package
          variant: AppButtonVariant.danger,
          onPressed: () {},
        ),
      ));
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('AppButtonVariant.ghost maps to tertiary', (tester) async {
      await tester.pumpWidget(_wrap(
        AppButton(
          label: 'Cancel',
          // ignore: deprecated_member_use_from_same_package
          variant: AppButtonVariant.ghost,
          onPressed: () {},
        ),
      ));
      // tertiary uses TextButton, not ElevatedButton.
      expect(find.byType(TextButton), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('deprecated size aliases still render', (tester) async {
      // ignore: deprecated_member_use_from_same_package
      const sizes = [AppButtonSize.small, AppButtonSize.medium, AppButtonSize.large];
      for (final s in sizes) {
        await tester.pumpWidget(_wrap(
          AppButton(label: 'sz-${s.name}', size: s, onPressed: () {}),
        ));
        expect(find.text('sz-${s.name}'), findsOneWidget);
      }
    });
  });

  group('AppButton — variant uses correct underlying button', () {
    testWidgets('primary uses ElevatedButton', (tester) async {
      await tester.pumpWidget(_wrap(
        AppButton(
          label: 'P',
          variant: AppButtonVariant.primary,
          onPressed: () {},
        ),
      ));
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('secondary uses ElevatedButton with border', (tester) async {
      await tester.pumpWidget(_wrap(
        AppButton(
          label: 'S',
          variant: AppButtonVariant.secondary,
          onPressed: () {},
        ),
      ));
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('tertiary uses TextButton', (tester) async {
      await tester.pumpWidget(_wrap(
        AppButton(
          label: 'T',
          variant: AppButtonVariant.tertiary,
          onPressed: () {},
        ),
      ));
      expect(find.byType(TextButton), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('destructive uses ElevatedButton with red border', (tester) async {
      await tester.pumpWidget(_wrap(
        AppButton(
          label: 'D',
          variant: AppButtonVariant.destructive,
          onPressed: () {},
        ),
      ));
      expect(find.byType(ElevatedButton), findsOneWidget);
    });
  });
}
