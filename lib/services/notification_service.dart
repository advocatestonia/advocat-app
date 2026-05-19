import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:logger/logger.dart';

/// Singleton service managing Firebase Cloud Messaging for push notifications.
///
/// Handles permission requests, token management, foreground/background
/// message handling, and topic subscriptions for deadline reminders.
class NotificationService {
  NotificationService._internal()
      : _messaging = FirebaseMessaging.instance,
        _log = Logger(
          printer: PrettyPrinter(methodCount: 0),
          level: kDebugMode ? Level.debug : Level.off,
        );

  static final NotificationService instance = NotificationService._internal();

  final FirebaseMessaging _messaging;
  final Logger _log;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Request notification permissions and retrieve the FCM token.
  Future<void> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    _log.i('Notification permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await _initToken();
      _listenForTokenRefresh();
      _setupForegroundHandler();
    }
  }

  Future<void> _initToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      _log.i('FCM token obtained (${_fcmToken?.length ?? 0} chars)');
    } catch (e) {
      _log.e('Failed to get FCM token', error: e);
    }
  }

  void _listenForTokenRefresh() {
    _messaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      _log.i('FCM token refreshed');
      // NOTE: refreshed token is held in memory only; backend persistence
      // is wired through the regular push registration flow on next session.
    });
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
