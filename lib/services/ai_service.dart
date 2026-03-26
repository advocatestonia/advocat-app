import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../config/app_config.dart';

final aiServiceProvider = Provider<AIService>((ref) {
  return AIService();
});

/// Service that communicates with the backend AI endpoint (which proxies
/// requests to Claude). The mobile app never holds raw AI API keys -- all
/// requests go through our authenticated Supabase Edge Function.
class AIService {
  AIService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.aiApiBaseUrl,
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 120),
            headers: {
              'Content-Type': 'application/json',
            },
          ),
        ),
        _log = Logger(printer: PrettyPrinter(methodCount: 0));

  final Dio _dio;
  final Logger _log;

  /// Set the Supabase access token for authenticated requests.
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Analyze an uploaded document: extract text, summarize, find deadlines.
  Future<DocumentAnalysis> analyzeDocument({
    required String caseId,
    required String documentId,
    String? ocrText,
  }) async {
    try {
      final response = await _dio.post(
        '/ai/analyze-document',
        data: {
          'case_id': caseId,
          'document_id': documentId,
          if (ocrText != null) 'ocr_text': ocrText,
        },
      );
      return DocumentAnalysis.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _log.e('Document analysis failed', error: e);
      throw AIServiceException('Failed to analyze document', e);
    }
  }

  /// Send a message in the AI legal assistant chat.
  Future<ChatResponse> sendChatMessage({
    required String caseId,
    required String message,
    List<String>? attachmentIds,
  }) async {
    try {
      final response = await _dio.post(
        '/ai/chat',
        data: {
          'case_id': caseId,
          'message': message,
          if (attachmentIds != null) 'attachment_ids': attachmentIds,
        },
      );
      return ChatResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _log.e('Chat message failed', error: e);
      throw AIServiceException('Failed to send message', e);
    }
  }

  /// Generate a draft appeal or response document based on the case context.
  Future<DraftResponse> generateDraft({
    required String caseId,
    required String draftType,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      final response = await _dio.post(
        '/ai/generate-draft',
        data: {
          'case_id': caseId,
          'draft_type': draftType,
          if (parameters != null) 'parameters': parameters,
        },
      );
      return DraftResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _log.e('Draft generation failed', error: e);
      throw AIServiceException('Failed to generate draft', e);
    }
  }

  /// Extract deadlines and key dates from correspondence text.
  Future<List<ExtractedDeadline>> extractDeadlines({
    required String caseId,
    required String text,
  }) async {
    try {
      final response = await _dio.post(
        '/ai/extract-deadlines',
        data: {
          'case_id': caseId,
          'text': text,
        },
      );
      final items = response.data['deadlines'] as List<dynamic>;
      return items
          .map((e) => ExtractedDeadline.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _log.e('Deadline extraction failed', error: e);
      throw AIServiceException('Failed to extract deadlines', e);
    }
  }
}

// ── Response DTOs ─────────────────────────────────────────────────────────

class DocumentAnalysis {
  final String summary;
  final String? language;
  final List<String> keyPoints;
  final List<ExtractedDeadline> deadlines;
  final Map<String, dynamic> entities;

  const DocumentAnalysis({
    required this.summary,
    this.language,
    required this.keyPoints,
    required this.deadlines,
    required this.entities,
  });

  factory DocumentAnalysis.fromJson(Map<String, dynamic> json) {
    return DocumentAnalysis(
      summary: json['summary'] as String,
      language: json['language'] as String?,
      keyPoints: (json['key_points'] as List<dynamic>).cast<String>(),
      deadlines: (json['deadlines'] as List<dynamic>)
          .map((e) => ExtractedDeadline.fromJson(e as Map<String, dynamic>))
          .toList(),
      entities: json['entities'] as Map<String, dynamic>? ?? {},
    );
  }
}

class ChatResponse {
  final String message;
  final List<String>? suggestedActions;
  final String? disclaimer;

  const ChatResponse({
    required this.message,
    this.suggestedActions,
    this.disclaimer,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      message: json['message'] as String,
      suggestedActions: (json['suggested_actions'] as List<dynamic>?)?.cast<String>(),
      disclaimer: json['disclaimer'] as String?,
    );
  }
}

class DraftResponse {
  final String title;
  final String content;
  final String language;
  final String disclaimer;

  const DraftResponse({
    required this.title,
    required this.content,
    required this.language,
    required this.disclaimer,
  });

  factory DraftResponse.fromJson(Map<String, dynamic> json) {
    return DraftResponse(
      title: json['title'] as String,
      content: json['content'] as String,
      language: json['language'] as String? ?? 'en',
      disclaimer: json['disclaimer'] as String? ??
          'This is an AI-generated draft. Consult a licensed attorney before submitting.',
    );
  }
}

class ExtractedDeadline {
  final String title;
  final String date;
  final String? type;
  final String? description;

  const ExtractedDeadline({
    required this.title,
    required this.date,
    this.type,
    this.description,
  });

  factory ExtractedDeadline.fromJson(Map<String, dynamic> json) {
    return ExtractedDeadline(
      title: json['title'] as String,
      date: json['date'] as String,
      type: json['type'] as String?,
      description: json['description'] as String?,
    );
  }
}

// ── Exceptions ────────────────────────────────────────────────────────────

class AIServiceException implements Exception {
  final String message;
  final DioException? cause;

  const AIServiceException(this.message, [this.cause]);

  @override
  String toString() => 'AIServiceException: $message';
}
