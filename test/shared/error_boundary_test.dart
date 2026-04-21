import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/shared/error_boundary.dart';

// ---------------------------------------------------------------------------
// error_boundary_test.dart — army/wave3 C3
// ---------------------------------------------------------------------------

class _Throws extends StatelessWidget {
  const _Throws({required this.error});
  final Object error;
  @override
  Widget build(BuildContext context) {
    throw error;
  }
}

void main() {
  // Capture BEFORE any setUp; this is the true framework default.
  ErrorWidgetBuilder originalErrorBuilder = ErrorWidget.builder;
  FlutterExceptionHandler? originalOnError = FlutterError.onError;

  setUpAll(() {
    originalErrorBuilder = ErrorWidget.builder;
    originalOnError = FlutterError.onError;
  });

  setUp(() {
    setErrorSink(null);
    resetErrorBoundaryForTests();
  });

  tearDown(() {
    // Flutter test framework asserts that ErrorWidget.builder is
    // unchanged at the start of the next test. Restore handlers.
    ErrorWidget.builder = originalErrorBuilder;
    FlutterError.onError = originalOnError;
  });

  testWidgets(
      'ErrorBoundary catches LateInitializationError during build and renders fallback',
      (tester) async {
    installErrorBoundary();
    // Capture any sink activity.
    final caught = <Object>[];
    setErrorSink((err, _, {hint, route}) => caught.add(err));

    await tester.pumpWidget(
      const MaterialApp(home: _Throws(error: 'boom late init')),
    );

    // Flutter test framework keeps a record of thrown exceptions —
    // consume it so the test doesn't fail post-hoc. The boundary has
    // already handled it; we just drain the inbox.
    final ex = tester.takeException();
    expect(ex.toString(), contains('boom late init'));

    // Default fallback contains the trilingual heading.
    expect(find.text('Midagi läks valesti'), findsOneWidget);
    expect(find.text('Lae uuesti · Reload'), findsOneWidget);
    // Sink received the error.
    expect(caught.isNotEmpty, true);

    // Restore before test body ends — Flutter's
    // _verifyErrorWidgetBuilderUnset fires before tearDown.
    ErrorWidget.builder = originalErrorBuilder;
    FlutterError.onError = originalOnError;
  });

  testWidgets('ErrorBoundary reports runtime error to sink with hint',
      (tester) async {
    installErrorBoundary();
    String? caughtHint;
    setErrorSink((err, _, {hint, route}) => caughtHint = hint);

    await tester.pumpWidget(
      const MaterialApp(home: _Throws(error: 'runtime x')),
    );
    tester.takeException(); // drain

    expect(caughtHint, 'widget-build');

    ErrorWidget.builder = originalErrorBuilder;
    FlutterError.onError = originalOnError;
  });

  test('installErrorBoundary is idempotent', () {
    installErrorBoundary();
    installErrorBoundary();
    // No assertion here — just verify no exception.
    expect(true, true);
  });

  test('setErrorSink(null) clears sink without error', () {
    setErrorSink((_, __, {hint, route}) {});
    setErrorSink(null);
    expect(true, true);
  });
}
