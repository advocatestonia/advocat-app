import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../config/app_config.dart';

final emailServiceProvider = Provider<EmailService>((ref) {
  return EmailService();
});

/// Communicates with the backend email integration endpoint to fetch,
/// parse, and sync immigration-related emails into the case timeline.
class EmailService {
  EmailService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.emailApiBaseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 30),
            headers: {'Content-Type': 'application/json'},
          ),
        ),
        _log = Logger(printer: PrettyPrinter(methodCount: 0));

  final Dio _dio;
  final Logger _log;

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Start the OAuth flow to connect the user's email account.
  /// Returns the OAuth redirect URL that should be opened in a web view.
  Future<String> getOAuthUrl({required String provider}) async {
    try {
      final response = await _dio.post(
        '/email/oauth/start',
        data: {'provider': provider},
      );
      return response.data['url'] as String;
    } on DioException catch (e) {
      _log.e('Failed to get OAuth URL', error: e);
      throw EmailServiceException('Could not start email connection', e);
    }
  }

  /// Complete the OAuth flow with the authorization code.
  Future<void> completeOAuth({
    required String provider,
    required String code,
  }) async {
    try {
      await _dio.post(
        '/email/oauth/callback',
        data: {'provider': provider, 'code': code},
      );
    } on DioException catch (e) {
      _log.e('OAuth completion failed', error: e);
      throw EmailServiceException('Email connection failed', e);
    }
  }

  /// Trigger a manual sync of emails for the specified case.
  Future<EmailSyncResult> syncEmails({required String caseId}) async {
    try {
      final response = await _dio.post(
        '/email/sync',
        data: {'case_id': caseId},
      );
      return EmailSyncResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _log.e('Email sync failed', error: e);
      throw EmailServiceException('Failed to sync emails', e);
    }
  }

  /// Check whether the user has an active email integration.
  Future<bool> isConnected() async {
    try {
      final response = await _dio.get('/email/status');
      return response.data['connected'] as bool? ?? false;
    } on DioException {
      return false;
    }
  }

  /// Disconnect the user's email integration.
  Future<void> disconnect() async {
    try {
      await _dio.post('/email/disconnect');
    } on DioException catch (e) {
      _log.e('Email disconnect failed', error: e);
      throw EmailServiceException('Failed to disconnect email', e);
    }
  }
}

class EmailSyncResult {
  final int newEmails;
  final int updatedEmails;
  final int extractedDeadlines;
  final DateTime syncedAt;

  const EmailSyncResult({
    required this.newEmails,
    required this.updatedEmails,
    required this.extractedDeadlines,
    required this.syncedAt,
  });

  factory EmailSyncResult.fromJson(Map<String, dynamic> json) {
    return EmailSyncResult(
      newEmails: json['new_emails'] as int? ?? 0,
      updatedEmails: json['updated_emails'] as int? ?? 0,
      extractedDeadlines: json['extracted_deadlines'] as int? ?? 0,
      syncedAt: DateTime.parse(json['synced_at'] as String),
    );
  }
}

class EmailServiceException implements Exception {
  final String message;
  final DioException? cause;

  const EmailServiceException(this.message, [this.cause]);

  @override
  String toString() => 'EmailServiceException: $message';
}
