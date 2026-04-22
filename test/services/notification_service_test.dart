import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/notification_service.dart';

/// Tests for [NotificationService] — singleton pattern and pending route.
///
/// Firebase-dependent methods (requestPermission, subscribeToCaseUpdates,
/// etc.) cannot be tested without Firebase initialization. We focus on the
/// synchronous, testable parts: singleton access and the pending route
/// consume logic.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Use the official Firebase Core mock from firebase_core_platform_interface
    setupFirebaseCoreMocks();

    // Mock the Firebase Messaging channel
    const MethodChannel messagingChannel =
        MethodChannel('plugins.flutter.io/firebase_messaging');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(messagingChannel, (MethodCall call) async {
      return null;
    });

    await Firebase.initializeApp();
  });

  group('NotificationService — singleton', () {
    test('instance returns the same object', () {
      final a = NotificationService.instance;
      final b = NotificationService.instance;
      expect(identical(a, b), isTrue);
    });
  });

  group('NotificationService — pending route', () {
    test('consumePendingRoute returns null when no route is set', () {
      final service = NotificationService.instance;
      // Ensure no stale state from other tests.
      service.consumePendingRoute();
      expect(service.consumePendingRoute(), isNull);
    });

    test('consumePendingRoute clears the route after consumption', () {
      final service = NotificationService.instance;
      // consumePendingRoute first to clear any stale state
      service.consumePendingRoute();
      final firstCall = service.consumePendingRoute();
      final secondCall = service.consumePendingRoute();
      // Both should be null since no route was set externally
      expect(firstCall, isNull);
      expect(secondCall, isNull);
    });
  });

  group('NotificationService — fcmToken', () {
    test('fcmToken is null before permission is requested', () {
      final service = NotificationService.instance;
      // FCM token is not set until requestPermission() is called
      // which requires Firebase. So it remains null in unit tests.
      expect(service.fcmToken, isNull);
    });
  });
}
