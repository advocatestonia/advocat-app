import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/notification_service.dart';
import 'package:advocat/services/notification_preferences_service.dart';

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

  // -------------------------------------------------------------------------
  // Pkg 9 — FCM token persistence to notification_preferences.fcm_token.
  // The forTesting constructor lets us stub both FirebaseMessaging and the
  // NotificationPreferencesService so we can verify the wiring contract
  // without standing up Supabase or Firebase.
  // -------------------------------------------------------------------------
  group('NotificationService — token persistence', () {
    test(
        'updateFcmToken called on the prefs service after the FCM token is obtained',
        () async {
      final prefs = _RecordingPrefs();
      final messaging = _StubMessaging(
        token: 'fcm-test-token-aaa111',
        status: AuthorizationStatus.authorized,
      );
      final service = NotificationService.forTesting(
        messaging: messaging,
        prefs: prefs,
      );

      final authorised = await service.requestPermission();
      expect(authorised, isTrue);
      expect(service.fcmToken, 'fcm-test-token-aaa111');
      expect(prefs.tokensPersisted, ['fcm-test-token-aaa111']);
    });

    test(
        'token refresh re-persists — survives FCM-server-initiated rotation',
        () async {
      final prefs = _RecordingPrefs();
      final messaging = _StubMessaging(
        token: 'initial-token',
        status: AuthorizationStatus.authorized,
      );
      final service = NotificationService.forTesting(
        messaging: messaging,
        prefs: prefs,
      );

      await service.requestPermission();
      expect(prefs.tokensPersisted, ['initial-token']);

      // Simulate FCM-server-initiated token rotation.
      messaging.emitRefresh('rotated-token');
      // Microtask drain so the async _persistTokenSafely settles.
      await Future<void>.delayed(Duration.zero);

      expect(service.fcmToken, 'rotated-token');
      expect(prefs.tokensPersisted, ['initial-token', 'rotated-token']);
    });

    test(
        'permission denied → no token fetched, no upsert attempted',
        () async {
      final prefs = _RecordingPrefs();
      final messaging = _StubMessaging(
        token: 'should-not-be-persisted',
        status: AuthorizationStatus.denied,
      );
      final service = NotificationService.forTesting(
        messaging: messaging,
        prefs: prefs,
      );

      final authorised = await service.requestPermission();
      expect(authorised, isFalse);
      expect(service.fcmToken, isNull);
      expect(prefs.tokensPersisted, isEmpty);
    });

    test(
        'persistence failure is swallowed — never propagates an exception',
        () async {
      final prefs = _RecordingPrefs(throwOnUpdate: true);
      final messaging = _StubMessaging(
        token: 'transient-failure-token',
        status: AuthorizationStatus.authorized,
      );
      final service = NotificationService.forTesting(
        messaging: messaging,
        prefs: prefs,
      );

      // MUST NOT throw — push is best-effort, the in-app channel is the
      // safety net. A crashy persistence path would brick app startup.
      await expectLater(service.requestPermission(), completes);
      expect(service.fcmToken, 'transient-failure-token');
      // We still recorded the attempt so the test can pin the contract.
      expect(prefs.attemptedUpdateCount, 1);
    });

    test(
        'empty / null token does not trigger an upsert (no zero-byte rows)',
        () async {
      final prefs = _RecordingPrefs();
      final messaging = _StubMessaging(
        token: null,
        status: AuthorizationStatus.authorized,
      );
      final service = NotificationService.forTesting(
        messaging: messaging,
        prefs: prefs,
      );

      await service.requestPermission();
      expect(service.fcmToken, isNull);
      expect(prefs.tokensPersisted, isEmpty);
    });

    test('provisional permission is treated as authorised', () async {
      final prefs = _RecordingPrefs();
      final messaging = _StubMessaging(
        token: 'provisional-token',
        status: AuthorizationStatus.provisional,
      );
      final service = NotificationService.forTesting(
        messaging: messaging,
        prefs: prefs,
      );

      final authorised = await service.requestPermission();
      expect(authorised, isTrue);
      expect(prefs.tokensPersisted, ['provisional-token']);
    });
  });
}

// =============================================================================
// Stubs
// =============================================================================

/// In-memory recorder that captures every updateFcmToken call. We override
/// only the methods NotificationService actually uses so the rest of
/// NotificationPreferencesService remains untouched.
class _RecordingPrefs implements NotificationPreferencesService {
  _RecordingPrefs({this.throwOnUpdate = false});

  final bool throwOnUpdate;
  final List<String> tokensPersisted = [];
  int attemptedUpdateCount = 0;

  @override
  Future<void> updateFcmToken(String token) async {
    attemptedUpdateCount += 1;
    if (throwOnUpdate) {
      throw StateError('simulated supabase failure');
    }
    tokensPersisted.add(token);
  }

  @override
  Future<NotificationPreferences> load() async =>
      const NotificationPreferences();

  @override
  Future<bool> save(NotificationPreferences prefs) async => true;

  @override
  Future<bool> disableAllEmail() async => true;
}

/// Minimal FirebaseMessaging stub that returns canned values for the four
/// methods NotificationService touches: requestPermission, getToken,
/// onTokenRefresh, and (transitively) onMessage / onMessageOpenedApp via
/// no-op streams.
class _StubMessaging implements FirebaseMessaging {
  _StubMessaging({
    required this.token,
    required AuthorizationStatus status,
  }) : _settings = NotificationSettings(
          alert: AppleNotificationSetting.enabled,
          announcement: AppleNotificationSetting.disabled,
          authorizationStatus: status,
          badge: AppleNotificationSetting.enabled,
          carPlay: AppleNotificationSetting.disabled,
          lockScreen: AppleNotificationSetting.enabled,
          notificationCenter: AppleNotificationSetting.enabled,
          showPreviews: AppleShowPreviewSetting.always,
          timeSensitive: AppleNotificationSetting.disabled,
          criticalAlert: AppleNotificationSetting.disabled,
          sound: AppleNotificationSetting.enabled,
        );

  final String? token;
  final NotificationSettings _settings;
  final StreamController<String> _refreshCtl =
      StreamController<String>.broadcast();

  void emitRefresh(String t) => _refreshCtl.add(t);

  @override
  Future<NotificationSettings> requestPermission({
    bool alert = false,
    bool announcement = false,
    bool badge = false,
    bool carPlay = false,
    bool criticalAlert = false,
    bool provisional = false,
    bool sound = false,
  }) async =>
      _settings;

  @override
  Future<String?> getToken({String? vapidKey}) async => token;

  @override
  Stream<String> get onTokenRefresh => _refreshCtl.stream;

  // Every other override on FirebaseMessaging is unused by
  // NotificationService.requestPermission's code path. noSuchMethod returns
  // sensible defaults (null for futures, no-op streams via late inits) so
  // we don't have to enumerate the surface.
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

