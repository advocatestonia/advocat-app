import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kDebugMode, visibleForTesting;
import 'package:logger/logger.dart';

import 'notification_preferences_service.dart';

/// Singleton service managing Firebase Cloud Messaging for push notifications.
///
/// Handles permission requests, token management, foreground/background
/// message handling, and topic subscriptions for deadline reminders.
///
/// Token persistence lifecycle:
///   1. `requestPermission()` → if granted, `_initToken()` fetches the FCM
///       registration token AND immediately POSTs it to
///       `notification_preferences.fcm_token` via [NotificationPreferencesService]
///       so the server-side `push-send` edge fn can route Pkg 9 deadline
///       pushes to this device.
///   2. `_listenForTokenRefresh()` re-persists on every rotation (install,
///       reinstall, FCM-server-initiated refresh).
///   3. Persistence is best-effort: when Supabase is offline or the user is
///       in demo mode, the upsert is a no-op and the token simply waits
///       until the next refresh / next session. We NEVER throw from the
///       token path — push is best-effort, the in-app banner channel is
///       always the safety net (see deadline-radar-tick channel='in_app').
class NotificationService {
  NotificationService._internal()
      : _messaging = FirebaseMessaging.instance,
        _log = Logger(
          printer: PrettyPrinter(methodCount: 0),
          level: kDebugMode ? Level.debug : Level.off,
        ),
        _prefs = NotificationPreferencesService();

  static final NotificationService instance = NotificationService._internal();

  /// Test-only seam — pass a stub [NotificationPreferencesService] so unit
  /// tests can assert the token is persisted without touching Supabase.
  @visibleForTesting
  NotificationService.forTesting({
    required FirebaseMessaging messaging,
    required NotificationPreferencesService prefs,
  })  : _messaging = messaging,
        _prefs = prefs,
        _log = Logger(
          printer: PrettyPrinter(methodCount: 0),
          level: Level.off,
        );

  final FirebaseMessaging _messaging;
  final Logger _log;
  final NotificationPreferencesService _prefs;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Request notification permissions and retrieve the FCM token.
  ///
  /// Safe to call multiple times — Firebase short-circuits redundant
  /// permission prompts. Returns true iff the user authorised push.
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    _log.i('Notification permission: ${settings.authorizationStatus}');

    final authorised =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;

    if (authorised) {
      await _initToken();
      _listenForTokenRefresh();
      _setupForegroundHandler();
    }
    return authorised;
  }

  Future<void> _initToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      _log.i('FCM token obtained (${_fcmToken?.length ?? 0} chars)');
      await _persistTokenSafely(_fcmToken);
    } catch (e) {
      _log.e('Failed to get FCM token', error: e);
    }
  }

  void _listenForTokenRefresh() {
    _messaging.onTokenRefresh.listen((token) async {
      _fcmToken = token;
      _log.i('FCM token refreshed');
      await _persistTokenSafely(token);
    });
  }

  /// Persist the token to `notification_preferences.fcm_token` for the
  /// signed-in user. Swallows all errors — this MUST never crash the app
  /// or leak a noisy log on the user's screen. The owner can grep
  /// `notification_preferences` for rows with fcm_token IS NULL to spot
  /// users where persistence has not yet succeeded.
  Future<void> _persistTokenSafely(String? token) async {
    if (token == null || token.isEmpty) return;
    try {
      await _prefs.updateFcmToken(token);
      _log.d('FCM token persisted to notification_preferences');
    } catch (e) {
      _log.w('FCM token persistence failed (will retry on refresh): $e');
    }
  }

  void _setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _log.i('Foreground message: ${message.notification?.title}');
      _handleMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _log.i('Message opened app: ${message.notification?.title}');
      _handleMessageTap(message);
    });
  }

  void _handleMessage(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] as String?;

    switch (type) {
      case 'deadline_reminder':
        _onDeadlineReminder(data);
        break;
      case 'document_processed':
        _onDocumentProcessed(data);
        break;
      case 'new_correspondence':
        _onNewCorrespondence(data);
        break;
      default:
        _log.w('Unknown notification type: $type');
    }
  }

  void _handleMessageTap(RemoteMessage message) {
    // Deep-link routing is handled by GoRouter; we just need to extract
    // the target path from the notification payload.
    final data = message.data;
    final route = data['route'] as String?;
    if (route != null) {
      _log.i('Should navigate to: $route');
      // Navigation will be handled by the router through a stream/callback
      _pendingRoute = route;
    }
  }

  String? _pendingRoute;

  /// Consume and clear any pending deep-link route from a notification tap.
  String? consumePendingRoute() {
    final route = _pendingRoute;
    _pendingRoute = null;
    return route;
  }

  // ── Topic subscriptions ─────────────────────────────────────────────

  /// Subscribe to deadline reminders for a specific case.
  Future<void> subscribeToCaseUpdates(String caseId) async {
    await _messaging.subscribeToTopic('case_$caseId');
    _log.i('Subscribed to case updates: $caseId');
  }

  /// Unsubscribe from a case's notifications.
  Future<void> unsubscribeFromCaseUpdates(String caseId) async {
    await _messaging.unsubscribeFromTopic('case_$caseId');
    _log.i('Unsubscribed from case updates: $caseId');
  }

  // ── Notification handlers ──────────────────────────────────────────

  void _onDeadlineReminder(Map<String, dynamic> data) {
    _log.d('Deadline reminder received');
  }

  void _onDocumentProcessed(Map<String, dynamic> data) {
    _log.d('Document processed notification received');
  }

  void _onNewCorrespondence(Map<String, dynamic> data) {
    _log.d('New correspondence notification received');
  }
}
