import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/case_model.dart';
import '../models/document.dart';
import '../models/correspondence.dart';
import '../models/deadline.dart';
import '../models/user.dart';
import 'demo_data.dart';

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  final isDemo = ref.watch(isDemoModeProvider);
  return SupabaseService(isDemo: isDemo);
});

/// Thin wrapper around the Supabase client providing typed access to
/// database tables and storage buckets used by the application.
///
/// When [isDemo] is true, all methods return mock data from [DemoData]
/// without contacting any backend.
class SupabaseService {
  SupabaseService({this.isDemo = false});

  final bool isDemo;

  // ── Auth shortcuts (demo stubs) ──────────────────────────────────────

  String? get currentUserId => isDemo ? DemoData.user.id : null;

  Stream<dynamic> get authStateChanges =>
      isDemo ? const Stream.empty() : const Stream.empty();

  Future<void> signOut() async {}

  Future<void> resetPassword(String email) async {}

  // ── User profile ──────────────────────────────────────────────────────

  Future<AppUser?> getUserProfile() async {
    if (isDemo) return DemoData.user;
    return null;
  }

  Future<void> updateUserProfile(Map<String, dynamic> updates) async {}

  // ── Cases ─────────────────────────────────────────────────────────────

  Future<List<LegalCase>> getCases() async {
    if (isDemo) return DemoData.cases;
    return [];
  }

  Future<LegalCase> getCaseById(String id) async {
    if (isDemo) {
      return DemoData.cases.firstWhere(
        (c) => c.id == id,
        orElse: () => DemoData.cases.first,
      );
    }
    throw Exception('Not connected to backend');
  }

  Future<LegalCase> createCase(Map<String, dynamic> caseData) async {
    if (isDemo) {
      // Return a new case based on the provided data
      final now = DateTime.now();
      return LegalCase(
        id: 'case-new-${now.millisecondsSinceEpoch}',
        userId: DemoData.user.id,
        title: caseData['title'] as String? ?? 'New Case',
        description: caseData['description'] as String?,
        type: CaseType.deportation,
        status: CaseStatus.active,
        migriReferenceNumber: caseData['migri_reference_number'] as String?,
        createdAt: now,
      );
    }
    throw Exception('Not connected to backend');
  }

  Future<void> updateCase(String id, Map<String, dynamic> updates) async {}

  // ── Documents ─────────────────────────────────────────────────────────

  Future<List<CaseDocument>> getDocuments(String caseId) async {
    if (isDemo) {
      return DemoData.documents.where((d) => d.caseId == caseId).toList();
    }
    return [];
  }

  Future<String> uploadDocument({
    required String caseId,
    required String fileName,
    required Uint8List fileBytes,
    required String mimeType,
  }) async {
    if (isDemo) return 'demo-doc-${DateTime.now().millisecondsSinceEpoch}';
    throw Exception('Not connected to backend');
  }

  Future<String> getDocumentUrl(String storagePath) async {
    return '';
  }

  // ── Correspondence ────────────────────────────────────────────────────

  Future<List<Correspondence>> getCorrespondence(String caseId) async {
    if (isDemo) {
      return DemoData.correspondence
          .where((c) => c.caseId == caseId)
          .toList();
    }
    return [];
  }

  // ── Deadlines ─────────────────────────────────────────────────────────

  Future<List<Deadline>> getDeadlines({String? caseId}) async {
    if (isDemo) {
      var deadlines = DemoData.deadlines;
      if (caseId != null) {
        deadlines = deadlines.where((d) => d.caseId == caseId).toList();
      }
      return deadlines;
    }
    return [];
  }

  Future<void> createDeadline(Map<String, dynamic> deadlineData) async {}

  Future<void> updateDeadline(String id, Map<String, dynamic> updates) async {}

  // ── Chat history ──────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getChatMessages(String caseId) async {
    if (isDemo) return DemoData.chatMessages;
    return [];
  }

  Future<void> saveChatMessage({
    required String caseId,
    required String role,
    required String content,
  }) async {}
}
