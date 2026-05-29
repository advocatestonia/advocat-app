@Tags(['fast'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/shared/secure_screen.dart';

// ---------------------------------------------------------------------------
// secure_screen_test.dart — WAVE 2 FIX W2-03 (2026-05-28)
//
// Regression tests for the FLAG_SECURE platform channel and the
// SecureScreenScope ref-counting widget that gate it.
//
// What we assert
//   * SecureScreenScope.initState invokes `setSecure` on the platform
//     channel exactly once when the count goes 0 → 1.
//   * SecureScreenScope.dispose invokes `clearSecure` when the count
//     goes 1 → 0.
//   * Nested scopes do NOT cause `clearSecure` to fire when the inner
//     scope disposes while the outer is still mounted (ref-counting).
//   * SecureMode.enable / disable can be called imperatively without a
//     widget — same ref-counting semantics.
//   * SecureMode.disable() at refCount=0 is a no-op (fail-safe, does
//     not call the platform).
// ---------------------------------------------------------------------------

class _RecordingHandler {
  final List<String> calls = <String>[];

  Future<Object?> handle(MethodCall call) async {
    calls.add(call.method);
    return null;
  }
}

void main() {
  // The widget test binding installs a TestDefaultBinaryMessengerBinding
  // which exposes setMockMethodCallHandler. We pin it once and re-use
  // across tests by clearing the handler's recorded calls in setUp.
  TestWidgetsFlutterBinding.ensureInitialized();

  late _RecordingHandler handler;

  setUp(() async {
    handler = _RecordingHandler();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SecureMode.channel, handler.handle);
    await SecureMode.debugReset();
    handler.calls.clear();
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SecureMode.channel, null);
    await SecureMode.debugReset();
  });

  group('SecureMode imperative API', () {
    test('enable() at refCount=0 invokes setSecure once', () async {
      await SecureMode.enable();
      expect(handler.calls, equals(['setSecure']));
      expect(SecureMode.debugRefCount, equals(1));
      expect(SecureMode.isActive, isTrue);
    });

    test('two enables only call setSecure once (ref-count)', () async {
      await SecureMode.enable();
      await SecureMode.enable();
      expect(handler.calls, equals(['setSecure']));
      expect(SecureMode.debugRefCount, equals(2));
    });

    test('disable() at refCount=1 invokes clearSecure once', () async {
      await SecureMode.enable();
      handler.calls.clear();
      await SecureMode.disable();
      expect(handler.calls, equals(['clearSecure']));
      expect(SecureMode.debugRefCount, equals(0));
      expect(SecureMode.isActive, isFalse);
    });

    test('inner disable while outer still active does NOT clear', () async {
      await SecureMode.enable(); // outer
      await SecureMode.enable(); // inner
      handler.calls.clear();
      await SecureMode.disable(); // inner pops
      expect(handler.calls, isEmpty);
      expect(SecureMode.debugRefCount, equals(1));
      expect(SecureMode.isActive, isTrue);
      await SecureMode.disable(); // outer pops
      expect(handler.calls, equals(['clearSecure']));
      expect(SecureMode.debugRefCount, equals(0));
    });

    test('disable() at refCount=0 is a no-op (fail-safe)', () async {
      await SecureMode.disable();
      expect(handler.calls, isEmpty);
      expect(SecureMode.debugRefCount, equals(0));
    });
  });

  group('SecureScreenScope widget', () {
    testWidgets('initState calls setSecure', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SecureScreenScope(
            child: Scaffold(body: Text('secure body')),
          ),
        ),
      );
      // Allow any post-frame microtasks to run.
      await tester.pumpAndSettle();
      expect(handler.calls, contains('setSecure'));
      expect(SecureMode.debugRefCount, equals(1));
    });

    testWidgets('dispose calls clearSecure', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SecureScreenScope(
            child: Scaffold(body: Text('secure body')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      handler.calls.clear();

      // Replace the home with something non-secure → SecureScreenScope
      // is removed from the tree → dispose fires.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('public body')),
        ),
      );
      await tester.pumpAndSettle();

      expect(handler.calls, equals(['clearSecure']));
      expect(SecureMode.debugRefCount, equals(0));
    });

    testWidgets('two nested scopes — only one setSecure, one clearSecure',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SecureScreenScope(
            child: SecureScreenScope(
              child: Scaffold(body: Text('double-wrapped')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Both scopes mounted: refCount=2, but only one setSecure call.
      expect(
        handler.calls.where((c) => c == 'setSecure').length,
        equals(1),
        reason: 'ref-counted enable must hit the platform once',
      );
      expect(SecureMode.debugRefCount, equals(2));

      handler.calls.clear();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('public body')),
        ),
      );
      await tester.pumpAndSettle();

      // Both scopes disposed: refCount=0, exactly one clearSecure call.
      expect(
        handler.calls.where((c) => c == 'clearSecure').length,
        equals(1),
        reason: 'ref-counted disable must hit the platform once',
      );
      expect(SecureMode.debugRefCount, equals(0));
    });

    testWidgets(
        '2 nested scopes — inner unmounts first does NOT clear platform',
        (tester) async {
      // We control whether the inner scope is present via a stateful
      // builder so the outer remains mounted while the inner goes away.
      final innerKey = UniqueKey();
      bool showInner = true;
      late StateSetter setOuterState;

      await tester.pumpWidget(
        MaterialApp(
          home: SecureScreenScope(
            child: StatefulBuilder(
              builder: (context, setState) {
                setOuterState = setState;
                if (showInner) {
                  return SecureScreenScope(
                    key: innerKey,
                    child: const Scaffold(body: Text('double')),
                  );
                }
                return const Scaffold(body: Text('single (outer only)'));
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(SecureMode.debugRefCount, equals(2));

      handler.calls.clear();

      // Drop the inner scope. Outer is still mounted.
      setOuterState(() {
        showInner = false;
      });
      await tester.pumpAndSettle();

      expect(
        handler.calls,
        isEmpty,
        reason:
            'inner dispose while outer mounted must NOT call clearSecure',
      );
      expect(SecureMode.debugRefCount, equals(1));
      expect(SecureMode.isActive, isTrue);

      // Now tear down the entire tree — outer disposes too.
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('public'))),
      );
      await tester.pumpAndSettle();

      expect(handler.calls, equals(['clearSecure']));
      expect(SecureMode.debugRefCount, equals(0));
    });

    testWidgets('child widget is rendered (scope is transparent)',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SecureScreenScope(
            child: Scaffold(body: Text('I should be visible')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('I should be visible'), findsOneWidget);
    });
  });
}
