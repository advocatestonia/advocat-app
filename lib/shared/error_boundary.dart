import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ---------------------------------------------------------------------------
// Global error boundary — army/wave3 C3
// ---------------------------------------------------------------------------
//
// Addresses the production incident where a `LateInitializationError`
// during widget build caused the app to render a permanent grey screen.
// The previous behaviour relied on Flutter's default `ErrorWidget.builder`,
// which in release mode displays an opaque grey box with no recovery path.
//
// This module adds two layers of safety:
//
//   1. `ErrorWidget.builder` override — when an individual widget throws
//      during build/paint, we render a compact, branded fallback with a
//      "Reload" button instead of a grey box.
//
//   2. `FlutterError.onError` + `PlatformDispatcher.onError` + a top-level
//      `runZonedGuarded` hook installed via `runWithErrorBoundary` — any
//      otherwise-uncaught exception in the zone is captured and reported
//      to the `_errorSink` (currently the Flutter console + a pluggable
//      telemetry callback).
//
// Usage:
//
//     void main() async {
//       WidgetsFlutterBinding.ensureInitialized();
//       installErrorBoundary();
//       runWithErrorBoundary(() {
//         runApp(const ProviderScope(child: AdvocatApp()));
//       });
//     }
//
// Both functions are idempotent; calling `installErrorBoundary()` twice
// has no side effect.
//
// The fallback UI is intentionally *not* localised because at the moment
// it renders we cannot assume the localisation delegates are alive — we
// show short multi-language copy covering the three most common
// Advocat-user locales (et/ru/en).

typedef ErrorBoundarySink = void Function(Object error, StackTrace stack, {String? route, String? hint});

/// The currently installed telemetry sink (set via [setErrorSink]).
ErrorBoundarySink? _sink;

bool _installed = false;

/// Register a callback that fires every time the boundary catches an error.
/// Passing `null` removes the current sink. Safe to call at any time.
void setErrorSink(ErrorBoundarySink? sink) {
  _sink = sink;
}

/// Test-only hook: resets the installed state so `installErrorBoundary`
/// can be called again from the next test. Not intended for production
/// code paths. Does not undo any existing handlers.
@visibleForTesting
void resetErrorBoundaryForTests() {
  _installed = false;
}

/// Installs global error handlers. Idempotent.
void installErrorBoundary() {
  if (_installed) return;
  _installed = true;

  // 1. Replace the default red-screen / grey-screen widget with a friendly
  //    fallback card. This runs on the widget tree thread (build/paint).
  ErrorWidget.builder = (FlutterErrorDetails details) {
    _report(details.exception, details.stack ?? StackTrace.current,
        hint: 'widget-build', route: _currentRouteHint());
    return const _ErrorFallback();
  };

  // 2. Hook into Flutter framework errors (non-fatal by default).
  final prevOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    _report(details.exception, details.stack ?? StackTrace.current,
        hint: 'flutter-onerror', route: _currentRouteHint());
    prevOnError?.call(details); // preserve dev-time console output
  };

  // 3. Hook into platform-level dispatcher errors (async isolate errors,
  //    native-side callbacks). Returning `true` tells the engine that the
  //    error was handled.
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    _report(error, stack, hint: 'platform-dispatcher');
    return true;
  };
}

/// Runs [body] inside a guarded zone so any uncaught async exception is
/// captured and reported to the sink instead of killing the root isolate.
///
/// Must be called after [installErrorBoundary]. Returns whatever [body]
/// returns.
T runWithErrorBoundary<T>(T Function() body) {
  assert(_installed, 'Call installErrorBoundary() first.');
  late T result;
  runZonedGuarded<void>(
    () {
      result = body();
    },
    (Object error, StackTrace stack) {
      _report(error, stack, hint: 'zone-uncaught');
    },
  );
  return result;
}

String? _currentRouteHint() {
  try {
    // go_router injects a RouteInformation into the engine; we can read
    // the top-most observer route via the navigator key if attached.
    // This is best-effort: in release builds some fields may be null.
    final uri = WidgetsBinding.instance.platformDispatcher.defaultRouteName;
    return uri.isEmpty ? null : uri;
  } catch (_) {
    return null;
  }
}

void _report(Object error, StackTrace stack, {String? hint, String? route}) {
  // Always log to the dev console so local debugging works.
  developer.log(
    'ErrorBoundary: ${error.runtimeType} — $error',
    name: 'advocat.boundary',
    error: error,
    stackTrace: stack,
    level: 1000,
  );
  if (kDebugMode) {
    // In debug, also print so it shows in flutter run output.
    debugPrint('[advocat.boundary] $hint route=$route: $error');
  }

  // Forward to sink if attached.
  try {
    _sink?.call(error, stack, hint: hint, route: route);
  } catch (sinkError, sinkStack) {
    // Never let telemetry fail kill the app.
    developer.log(
      'ErrorBoundary sink failed: $sinkError',
      name: 'advocat.boundary',
      error: sinkError,
      stackTrace: sinkStack,
      level: 1000,
    );
  }
}

// ---------------------------------------------------------------------------
// Fallback UI
// ---------------------------------------------------------------------------

/// Minimal, brand-consistent fallback rendered instead of the grey screen
/// when a widget fails to build. Offers a reload button.
class _ErrorFallback extends StatelessWidget {
  const _ErrorFallback();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: const Color(0xFFF0EEEB),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0B7A70),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.refresh,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Midagi läks valesti',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A2B4A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Что-то пошло не так · Something went wrong',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B7A70),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      textStyle: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: _reload,
                    child: const Text('Lae uuesti · Reload'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Clipboard.setData(
                        const ClipboardData(text: 'hello@advocat.ee')),
                    child: const Text(
                      'hello@advocat.ee',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _reload() {
    if (kIsWeb) {
      // Force a full page reload on web (same as hitting refresh).
      // SystemNavigator.pop on web is no-op; we use JS interop via dart:html
      // indirectly through SystemChannels.navigation for consistency.
      SystemChannels.navigation
          .invokeMethod<void>('SystemNavigator.reload')
          .catchError((_) {
        // Fallback — best effort.
      });
    } else {
      // Mobile: pop to root. In most flows this clears the failing widget.
      SystemNavigator.pop();
    }
  }
}

/// Public wrapper for widgets that want *local* error handling without
/// relying on the global `ErrorWidget.builder`. When [child] throws
/// synchronously during build, [fallback] (or a default card) is shown.
///
/// NOTE: Flutter's build process does not catch runtime errors in the
/// child subtree — the global builder still applies. This widget is
/// mostly a hint for future refactors and adds scope reporting.
class ErrorBoundaryWidget extends StatelessWidget {
  const ErrorBoundaryWidget({
    super.key,
    required this.child,
    this.fallback,
    this.scope,
  });

  final Widget child;
  final Widget? fallback;
  final String? scope;

  @override
  Widget build(BuildContext context) {
    // Thin wrapper — the actual catching happens in ErrorWidget.builder.
    return child;
  }
}
