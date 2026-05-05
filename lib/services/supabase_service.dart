import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/case_model.dart';
import '../models/document.dart';
import '../models/correspondence.dart';
import '../models/deadline.dart';
import '../models/user.dart';
import 'demo_data.dart';
import 'errors/invalid_case_id_error.dart';

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

/// Thin wrapper around the Supabase client providing typed access to
/// database tables and storage buckets used by the application.
///
/// When Supabase is not initialised (no credentials at compile time)
/// all methods fall back to mock data from [DemoData].
class SupabaseService {
  SupabaseService();

  // ── Connection check ────────────────────────────────────────────────

  /// Whether the Supabase SDK has been initialised with real credentials.
  bool get _isInitialized {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// `true` when running without a backend (demo / offline mode).
  bool get isDemo => !_isInitialized;

  /// Convenience accessor; only call when [_isInitialized] is `true`.
  SupabaseClient get _client => Supabase.instance.client;

  /// Strict UUID regex (8-4-4-4-12 hex groups). Rejects synthetic ids like
  /// 'general', 'case-new-<ts>', empty string, etc.
  static final _uuidRegex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  /// Returns true only for real Supabase UUIDs matching the strict
  /// 8-4-4-4-12 hex format. Synthetic ids (e.g. 'general') return false so
  /// callers can short-circuit before hitting Postgres.
  bool _isRealUuid(String id) => _uuidRegex.hasMatch(id);

  /// Test-only exposure of [_isRealUuid]. Do not call from production code.
  @visibleForTesting
  bool isRealUuidForTest(String id) => _isRealUuid(id);

  /// Use when a UUID is REQUIRED (e.g. inserting a row with a FK).
  /// Throws [InvalidCaseIdError] for synthetic ids like 'general'.
  ///
  /// Most read paths (getChatMessages / getDocuments / etc.) deliberately
  /// short-circuit with empty results instead of throwing — only call this
  /// when a non-UUID truly cannot be handled.
  void requireUuid(String id, String context) {
    if (!_isRealUuid(id)) throw InvalidCaseIdError(id, context);
  }

  // ── Auth shortcuts ──────────────────────────────────────────────────

  String? get currentUserId {
    if (isDemo) return DemoData.user.id;
    return _client.auth.currentUser?.id;
  }

  Stream<AuthState> get authStateChanges {
    if (isDemo) return const Stream.empty();
    return _client.auth.onAuthStateChange;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    if (isDemo) throw Exception('Sign-in unavailable in demo mode');
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    if (isDemo) throw Exception('Sign-up unavailable in demo mode');
    return _client.auth.signUp(email: email, password: password, data: data);
  }

  Future<void> signOut() async {
    if (isDemo) return;
    await _client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    if (isDemo) return;
    await _client.auth.resetPasswordForEmail(email);
  }

  // ── User profile ──────────────────────────────────────────────────────

  Future<AppUser?> getUserProfile() async {
    if (isDemo) return DemoData.user;
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    final response =
        await _client.from('profiles').select().eq('id', uid).maybeSingle();
    if (response == null) return null;
    return AppUser.fromJson(response);
  }

  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    if (isDemo) return;
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    await _client.from('profiles').update(updates).eq('id', uid);
  }

  // ── Cases ─────────────────────────────────────────────────────────────

  Future<List<LegalCase>> getCases() async {
    if (isDemo) return DemoData.cases;
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    final response = await _client
        .from('cases')
        .select()
        .eq('user_id', uid)
        .order('updated_at', ascending: false);
    return (response as List).map((e) => LegalCase.fromJson(e)).toList();
  }

  // UUID v4-ish sanity check — anything else would make Postgres 400.
  static final _uuidLike = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  Future<LegalCase> getCaseById(String id) async {
    if (isDemo) {
      return DemoData.cases.firstWhere(
        (c) => c.id == id,
        orElse: () => DemoData.cases.isNotEmpty
            ? DemoData.cases.first
            : _placeholderCase(id),
      );
    }
    // Guard against non-UUID ids like "general" — Postgres rejects with 400.
    if (!_uuidLike.hasMatch(id)) {
      throw ArgumentError('getCaseById: "$id" is not a UUID');
    }
    final response =
        await _client.from('cases').select().eq('id', id).single();
    return LegalCase.fromJson(response);
  }

  LegalCase _placeholderCase(String id) => LegalCase(
        id: id,
        userId: DemoData.user.id,
        title: 'Demo case',
        type: CaseType.deportation,
        status: CaseStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  Future<LegalCase> createCase(Map<String, dynamic> caseData) async {
    if (isDemo) {
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
    final uid = _client.auth.currentUser?.id;
    caseData['user_id'] = uid;
    final response =
        await _client.from('cases').insert(caseData).select().single();
    return LegalCase.fromJson(response);
  }

  Future<void> updateCase(String id, Map<String, dynamic> updates) async {
    if (isDemo) return;
    updates['updated_at'] = DateTime.now().toIso8601String();
    await _client.from('cases').update(updates).eq('id', id);
  }

  // ── Documents ─────────────────────────────────────────────────────────

  Future<List<CaseDocument>> getDocuments(String caseId) async {
    if (isDemo) {
      return DemoData.documents.where((d) => d.caseId == caseId).toList();
    }
    // Synthetic 'general' chat (non-UUID) has no real case — return empty
    // instead of hitting Postgres with case_id='general' (400 error).
    if (!_isRealUuid(caseId)) return [];
    final response = await _client
        .from('documents')
        .select()
        .eq('case_id', caseId)
        .order('created_at', ascending: false);
    return (response as List).map((e) => CaseDocument.fromJson(e)).toList();
  }

  Future<String> uploadDocument({
    required String caseId,
    required String fileName,
    required Uint8List fileBytes,
    required String mimeType,
  }) async {
    if (isDemo) return 'demo-doc-${DateTime.now().millisecondsSinceEpoch}';

    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');

    final storagePath = '$uid/$caseId/$fileName';
    await _client.storage.from('case-documents').uploadBinary(
          storagePath,
          fileBytes,
          fileOptions: FileOptions(contentType: mimeType),
        );

    // Insert metadata row
    final response = await _client
        .from('documents')
        .insert({
          if (_isRealUuid(caseId)) 'case_id': caseId,
          'user_id': uid,
          'file_name': fileName,
          'storage_path': storagePath,
          'mime_type': mimeType,
          'file_size_bytes': fileBytes.length,
        })
        .select()
        .single();

    return response['id'] as String;
  }

  Future<String> getDocumentUrl(String storagePath) async {
    if (isDemo) return '';
    // Use signed URLs with 5-minute expiry so legal documents are never
    // publicly accessible via a static URL.
    final signedUrl = await _client.storage
        .from('case-documents')
        .createSignedUrl(storagePath, 300);
    return signedUrl;
  }

  /// Fetch all documents belonging to the current user (for the vault).
  Future<List<Map<String, dynamic>>> getVaultDocuments() async {
    if (isDemo) {
      return DemoData.documents.map((d) => d.toJson()).toList();
    }
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    final response = await _client
        .from('documents')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response as List);
  }

  // ── Correspondence ────────────────────────────────────────────────────

  Future<List<Correspondence>> getCorrespondence(String caseId) async {
    if (isDemo) {
      return DemoData.correspondence
          .where((c) => c.caseId == caseId)
          .toList();
    }
    // Synthetic 'general' chat — no case → empty list.
    if (!_isRealUuid(caseId)) return [];
    final response = await _client
        .from('correspondence')
        .select()
        .eq('case_id', caseId)
        .order('sent_at', ascending: false);
    return (response as List).map((e) => Correspondence.fromJson(e)).toList();
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
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    var query = _client.from('deadlines').select().eq('user_id', uid);
    if (caseId != null && _isRealUuid(caseId)) {
      query = query.eq('case_id', caseId);
    }
    final response = await query.order('due_date', ascending: true);
    return (response as List).map((e) => Deadline.fromJson(e)).toList();
  }

  Future<void> createDeadline(Map<String, dynamic> deadlineData) async {
    if (isDemo) return;
    final uid = _client.auth.currentUser?.id;
    deadlineData['user_id'] = uid;
    await _client.from('deadlines').insert(deadlineData);
  }

  Future<void> updateDeadline(
      String id, Map<String, dynamic> updates) async {
    if (isDemo) return;
    updates['updated_at'] = DateTime.now().toIso8601String();
    await _client.from('deadlines').update(updates).eq('id', id);
  }

  // ── Agent intentions (long-horizon follow-up promises) ──────────────────
  // Ref: supabase/migrations/20260505_agent_intentions.sql
  //      lib/services/assistant_tools.dart#_setFollowupIntention
  //
  // Demo-mode safe: returns null when Supabase isn't initialised so unit
  // tests can exercise the success card without a live DB.

  /// Insert a row into agent_intentions and return its id (or null in demo).
  Future<String?> createAgentIntention(Map<String, dynamic> data) async {
    if (isDemo) return null;
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('createAgentIntention: no signed-in user');
    }
    data['user_id'] = uid;
    final inserted = await _client
        .from('agent_intentions')
        .insert(data)
        .select('id')
        .single();
    return inserted['id'] as String?;
  }

  /// List uncompleted intentions for the signed-in user, optionally
  /// filtered by case_id. Used by the Case File "Pending follow-ups" UI.
  Future<List<Map<String, dynamic>>> listAgentIntentions({
    String? caseId,
  }) async {
    if (isDemo) return const [];
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return const [];
    var q = _client
        .from('agent_intentions')
        .select()
        .eq('user_id', uid)
        .eq('completed', false);
    if (caseId != null && caseId.isNotEmpty) {
      q = q.eq('case_id', caseId);
    }
    final rows = await q.order('next_check_at', ascending: true);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  /// Cancel an intention (sets completed=true) — used by the UI Cancel button.
  Future<void> cancelAgentIntention(String id) async {
    if (isDemo) return;
    await _client
        .from('agent_intentions')
        .update({'completed': true})
        .eq('id', id);
  }

  // ── Chat history ──────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getChatMessages(String caseId) async {
    if (isDemo) return DemoData.chatMessages;
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    var query = _client
        .from('chat_messages')
        .select()
        .eq('user_id', uid);
    if (_isRealUuid(caseId)) {
      query = query.eq('case_id', caseId);
    } else {
      query = query.isFilter('case_id', null);
    }
    final response = await query.order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<void> saveChatMessage({
    required String caseId,
    required String role,
    required String content,
  }) async {
    if (isDemo) return;
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    await _client.from('chat_messages').insert({
      if (_isRealUuid(caseId)) 'case_id': caseId,
      'user_id': uid,
      'role': role,
      'content': content,
    });
  }

  // ── Delete all user data ─────────────────────────────────────────────

  /// Deletes all user data from Supabase tables and storage, then signs out.
  /// Tables are deleted in foreign-key-safe order.
  /// Throws if not authenticated or if any step fails.
  Future<void> deleteAllUserData() async {
    if (isDemo) return; // Demo data is in-memory; nothing to delete.

    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');

    // Delete in FK-safe order: children first, then parents.
    // 1. chat_messages
    await _client.from('chat_messages').delete().eq('user_id', uid);
    // 2. documents (rows) + storage files
    final docRows = await _client
        .from('documents')
        .select('storage_path')
        .eq('user_id', uid);
    final storagePaths = (docRows as List)
        .map((r) => r['storage_path'] as String?)
        .where((p) => p != null && p.isNotEmpty)
        .cast<String>()
        .toList();
    if (storagePaths.isNotEmpty) {
      await _client.storage.from('case-documents').remove(storagePaths);
    }
    await _client.from('documents').delete().eq('user_id', uid);
    // 3. deadlines
    await _client.from('deadlines').delete().eq('user_id', uid);
    // 4. correspondence
    await _client.from('correspondence').delete().eq('user_id', uid);
    // 5. cases
    await _client.from('cases').delete().eq('user_id', uid);
    // 6. profile
    await _client.from('profiles').delete().eq('id', uid);

    // Sign out after data deletion
    await _client.auth.signOut();
  }

  // ── Edge Functions ──────────────────────────────────────────────────

  /// Call a Supabase Edge Function by [functionName] with an optional JSON
  /// [body].
  ///
  /// Returns the decoded JSON response on any response that contains a JSON
  /// body — INCLUDING non-200 responses. Callers should inspect the returned
  /// map for `ok`/`error` keys to decide success. This is deliberate: Edge
  /// Functions use standard HTTP semantics (400/401/429/503) and their JSON
  /// bodies carry actionable error details that must reach the user and the
  /// AI (so the AI can apologise and suggest a retry / provider switch).
  ///
  /// Only returns `null` in demo mode or when no JSON body could be decoded
  /// (network dead, malformed response). Never swallows errors silently.
  Future<Map<String, dynamic>?> callEdgeFunction(
    String functionName, {
    Map<String, dynamic>? body,
  }) async {
    if (isDemo) return null;
    try {
      final response = await _client.functions.invoke(
        functionName,
        body: body,
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      if (data is String && data.isNotEmpty) {
        try {
          final decoded = jsonDecode(data);
          if (decoded is Map<String, dynamic>) return decoded;
        } catch (_) {
          return {'error': 'Malformed response from $functionName: $data'};
        }
      }
      if (response.status >= 400) {
        return {
          'error': 'Edge function $functionName returned HTTP ${response.status}',
        };
      }
      return null;
    } on FunctionException catch (e) {
      // Supabase SDK throws FunctionException for non-2xx — surface the body.
      final details = e.details;
      if (details is Map<String, dynamic>) return details;
      if (details is String && details.isNotEmpty) {
        try {
          final decoded = jsonDecode(details);
          if (decoded is Map<String, dynamic>) return decoded;
        } catch (_) {/* fall through */}
        return {'error': details};
      }
      return {'error': 'Edge function $functionName failed: ${e.toString()}'};
    } catch (e) {
      return {'error': 'Edge function $functionName failed: $e'};
    }
  }

  // ── Export user data ─────────────────────────────────────────────────

  /// Fetches all user data and returns it as a formatted JSON string.
  /// Works in both demo and authenticated modes.
  Future<String> exportUserData() async {
    if (isDemo) {
      return _buildExportJson(
        profile: DemoData.user.toJson(),
        cases: DemoData.cases.map((c) => c.toJson()).toList(),
        documents: DemoData.documents.map((d) => d.toJson()).toList(),
        deadlines: DemoData.deadlines.map((d) => d.toJson()).toList(),
        correspondence:
            DemoData.correspondence.map((c) => c.toJson()).toList(),
        chatMessages: DemoData.chatMessages,
      );
    }

    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');

    // Fetch all data in parallel
    final results = await Future.wait<dynamic>([
      _client.from('profiles').select().eq('id', uid).maybeSingle(),
      _client.from('cases').select().eq('user_id', uid),
      _client.from('documents').select().eq('user_id', uid),
      _client.from('deadlines').select().eq('user_id', uid),
      _client.from('correspondence').select().eq('user_id', uid),
      _client.from('chat_messages').select().eq('user_id', uid),
    ]);

    return _buildExportJson(
      profile: results[0] as Map<String, dynamic>?,
      cases: List<Map<String, dynamic>>.from((results[1] as List?) ?? []),
      documents: List<Map<String, dynamic>>.from((results[2] as List?) ?? []),
      deadlines: List<Map<String, dynamic>>.from((results[3] as List?) ?? []),
      correspondence:
          List<Map<String, dynamic>>.from((results[4] as List?) ?? []),
      chatMessages:
          List<Map<String, dynamic>>.from((results[5] as List?) ?? []),
    );
  }

  String _buildExportJson({
    required Map<String, dynamic>? profile,
    required List<Map<String, dynamic>> cases,
    required List<Map<String, dynamic>> documents,
    required List<Map<String, dynamic>> deadlines,
    required List<Map<String, dynamic>> correspondence,
    required List<Map<String, dynamic>> chatMessages,
  }) {
    final exportData = {
      'exported_at': DateTime.now().toIso8601String(),
      'app': 'Advocat',
      'version': '1.0.0',
      'profile': profile,
      'cases': cases,
      'documents': documents,
      'deadlines': deadlines,
      'correspondence': correspondence,
      'chat_messages': chatMessages,
    };
    return const JsonEncoder.withIndent('  ').convert(exportData);
  }
}
