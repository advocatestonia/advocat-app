import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/cases/models/case_timeline_event.dart';
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

  /// Mint a UUIDv4 string for distributed tracing. Synthesised from 16
  /// crypto-secure random bytes per RFC 4122 §4.4. Used as the `x-trace-id`
  /// header so every downstream edge fn / DB audit row joins under one
  /// trace_id in `app.trace_timeline`.
  String _newTraceId() {
    final r = math.Random.secure();
    final bytes = List<int>.generate(16, (_) => r.nextInt(256));
    // Set version (4) and variant (10xx) bits per RFC 4122.
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20, 32)}';
  }

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

  /// Where the password-recovery email links back to. Must match the web
  /// deployment URL — the same target the OAuth flows use (see
  /// `loginWithGoogle` / `loginWithApple` in auth_provider.dart). Without
  /// an explicit redirectTo, Supabase falls back to the project's Site URL
  /// which may not be the app shell.
  static const String passwordResetRedirectUrl = 'https://advocat.ee/app.html';

  Future<void> resetPassword(String email) async {
    if (isDemo) return;
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: passwordResetRedirectUrl,
    );
  }

  /// Set a new password for the signed-in user. Used by the set-new-password
  /// screen (password-recovery deep link + Settings → "Change password").
  Future<void> updatePassword(String newPassword) async {
    if (isDemo) {
      throw Exception('Password update unavailable in demo mode');
    }
    await _client.auth.updateUser(UserAttributes(password: newPassword));
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

  // ── Case Timeline Events ──────────────────────────────────────────────
  //
  // Reads the `case_timeline_events` table populated by:
  //   - email-inbox-sync   → 'email_in'
  //   - send-email         → 'email_out'
  //   - email-triage       → 'consilium_decision'
  //   - deadline-extractor → 'deadline_set'
  //   - case-auto-patch    → 'phase_change'
  //   - this service       → 'manual_note' (user-authored)
  //
  // RLS owner-only; demo mode returns an empty list. Synthetic 'general'
  // case ids short-circuit.

  /// Fetch a single page of timeline events for the given case, newest
  /// first. [pageSize] defaults to 50; [beforeOccurredAt] (exclusive)
  /// drives cursor-based pagination.
  Future<List<CaseTimelineEvent>> getCaseTimelineEvents({
    required String caseId,
    int pageSize = 50,
    DateTime? beforeOccurredAt,
  }) async {
    if (isDemo) return const [];
    if (!_isRealUuid(caseId)) return const [];
    var query = _client
        .from('case_timeline_events')
        .select()
        .eq('case_id', caseId);
    if (beforeOccurredAt != null) {
      query = query.lt('occurred_at', beforeOccurredAt.toIso8601String());
    }
    final response = await query
        .order('occurred_at', ascending: false)
        .limit(pageSize);
    return (response as List)
        .map((e) =>
            CaseTimelineEvent.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Append a `manual_note` event to the timeline. Returns the new
  /// event_id, or null in demo mode. Other event_types are pipeline-only
  /// — the RLS policy blocks direct inserts of system events.
  Future<String?> appendManualNote({
    required String caseId,
    required String title,
    String? summary,
  }) async {
    if (isDemo) return null;
    requireUuid(caseId, 'appendManualNote');
    final response = await _client.rpc(
      'record_case_event',
      params: {
        'p_case_id': caseId,
        'p_event_type': 'manual_note',
        'p_title': title,
        'p_summary': summary,
        'p_payload': <String, dynamic>{},
      },
    );
    if (response is Map && response['ok'] == true) {
      return response['event_id'] as String?;
    }
    return null;
  }

  /// Delete a `manual_note` event the user owns. Pipeline-emitted events
  /// are immutable to the client (blocked by RLS).
  Future<void> deleteManualNote(String eventId) async {
    if (isDemo) return;
    await _client
        .from('case_timeline_events')
        .delete()
        .eq('id', eventId);
  }

  // ── Soft-case shell ───────────────────────────────────────────────────
  //
  // First-touch upload flow: an authenticated user may upload a document
  // before they have any case. We auto-materialise a "soft shell" case so
  // the document + deadline-extractor pipeline has a real case_id to
  // attach to. The shell is idempotent — repeated calls return the same
  // case_id for the same user (see migration 20260525220000).

  /// Returns the case_id of the user's existing soft shell, creating one
  /// if necessary. Idempotent — calling N times returns the same id.
  /// Returns null in demo mode or when no user is signed in.
  Future<String?> ensureSoftCaseForUser() async {
    if (isDemo) return null;
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    try {
      final response = await _client.rpc(
        'ensure_soft_case_for_user',
        params: {'p_user_id': uid},
      );
      if (response is String) return response;
      return null;
    } catch (_) {
      // RPC missing (pre-migration) / RLS denial / network — never
      // crash the upload flow; caller falls back to the anon path.
      return null;
    }
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
    // `deadline_date` is the NOT NULL date column the reminder cron reads;
    // `due_date` is a nullable convenience column and sorts nulls unpredictably.
    final response = await query.order('deadline_date', ascending: true);
    return (response as List).map((e) => Deadline.fromJson(e)).toList();
  }

  /// Reconcile a caller-supplied deadline map with the actual `deadlines`
  /// table schema. Historically callers (the Deadlines screen and the agent
  /// `create_deadline` tool) passed `due_date` + `reminder_days_before`, but
  /// the table's required column is `deadline_date` (NOT NULL) and the reminder
  /// column is `reminder_days`. Sending the old names made EVERY insert throw
  /// (NOT NULL violation on `deadline_date` / unknown column
  /// `reminder_days_before`), so user- and agent-created deadlines were never
  /// saved and no reminder ever fired. Normalise here so both paths work and
  /// land in the row the reminder cron actually watches.
  static const _deadlineColumns = <String>{
    'id', 'user_id', 'case_id', 'title', 'description', 'deadline_date',
    'due_date', 'reminder_days', 'is_completed', 'priority', 'metadata',
    'org_id', 'created_at', 'updated_at',
  };

  Map<String, dynamic> _normalizeDeadlineColumns(Map<String, dynamic> data) {
    final out = Map<String, dynamic>.from(data);
    if (out.containsKey('due_date') && out['deadline_date'] == null) {
      out['deadline_date'] = out['due_date'];
    }
    if (out.containsKey('reminder_days_before')) {
      out['reminder_days'] ??= out.remove('reminder_days_before');
    }
    // The table tracks completion as bool `is_completed`; the model/UI use a
    // richer `status` enum ('completed'/'cancelled'/'upcoming'). Map it so
    // mark-complete / cancel / reopen actually persist — the column `status`
    // does not exist on `deadlines`, so an un-mapped update was a silent no-op.
    if (out.containsKey('status')) {
      final s = out.remove('status');
      out['is_completed'] = (s == 'completed' || s == 'cancelled');
    }
    out.removeWhere((k, v) => !_deadlineColumns.contains(k));
    return out;
  }

  Future<void> createDeadline(Map<String, dynamic> deadlineData) async {
    if (isDemo) return;
    final uid = _client.auth.currentUser?.id;
    final row = _normalizeDeadlineColumns(deadlineData);
    row['user_id'] = uid;
    await _client.from('deadlines').insert(row);
  }

  Future<void> updateDeadline(
      String id, Map<String, dynamic> updates) async {
    if (isDemo) return;
    final row = _normalizeDeadlineColumns(updates);
    row['updated_at'] = DateTime.now().toIso8601String();
    await _client.from('deadlines').update(row).eq('id', id);
  }

  // ── Agent intentions (long-horizon follow-up promises) ──────────────────
  // Ref: supabase/migrations/20260505110000_agent_intentions.sql
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

  /// Hard-deletes the caller's account.
  ///
  /// Calls the `account-delete` edge function under service-role:
  ///   1. wipes every user-owned application row (RLS scope can't reach all
  ///      of them from the client)
  ///   2. removes every storage object under `<uid>/` in `case-documents`
  ///   3. deletes `auth.users` row via Supabase admin API (the client SDK
  ///      cannot do this — requires service-role)
  ///
  /// Required by App Store Guideline 5.1.1(v) (hard requirement since 2022)
  /// and GDPR Art. 17 ("right to erasure"). NO soft-delete: the auth row
  /// is gone, so the email becomes available for re-signup immediately.
  ///
  /// Caller must provide the user's own email (`confirmEmail`) — the edge
  /// fn re-checks it server-side as defence-in-depth against an accidental
  /// or programmatic firing of the destructive call.
  ///
  /// Signs the session out on success. Throws on any failure with a
  /// user-displayable message.
  Future<void> deleteAllUserData({required String confirmEmail}) async {
    if (isDemo) return; // Demo data is in-memory; nothing to delete.

    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');

    final result = await callEdgeFunction(
      'account-delete',
      body: {'confirm': confirmEmail},
    );
    if (result == null) {
      throw Exception('account-delete returned no body');
    }
    final err = result['error'];
    if (err != null) {
      throw Exception(err.toString());
    }
    final deleted = result['deleted'] == true;
    if (!deleted) {
      final msg = (result['message'] as String?) ??
          'Account deletion did not complete. Please retry.';
      throw Exception(msg);
    }

    // Auth row is gone server-side; sign out the local session.
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
  ///
  /// [traceId] is propagated as the `x-trace-id` header so every downstream
  /// audit row (agent_runs, agent_audit_log, email_triage_results, etc.)
  /// joins to one distributed trace. If null, a fresh UUIDv4 is minted per
  /// invocation. Pass an existing trace_id (e.g. the chat session's id) when
  /// you want multiple consecutive calls to be grouped under one trace.
  Future<Map<String, dynamic>?> callEdgeFunction(
    String functionName, {
    Map<String, dynamic>? body,
    String? traceId,
  }) async {
    if (isDemo) return null;
    try {
      final effectiveTraceId = traceId ?? _newTraceId();
      final response = await _client.functions.invoke(
        functionName,
        body: body,
        headers: {'x-trace-id': effectiveTraceId},
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

  // ── Case-type checklists ──────────────────────────────────────────────
  //
  // Static "what to do next" roadmap per case type. Backed by
  // `get_case_checklist` / `toggle_checklist_item` RPCs (migration
  // 20260601120000_case_checklists.sql). Pure RLS + RPC — no LLM, no cron.

  /// Returns the ordered checklist for a case as a raw jsonb list
  /// (each element: {item_id, step_order, title, description,
  /// deadline_days, done}). Empty list in demo mode or on any error so
  /// the caller can render an empty/hidden panel rather than crash.
  Future<List<dynamic>> getCaseChecklist(String caseId) async {
    if (isDemo) return const [];
    requireUuid(caseId, 'getCaseChecklist');
    final response = await _client.rpc(
      'get_case_checklist',
      params: {'p_case_id': caseId},
    );
    if (response is List) return response;
    return const [];
  }

  /// Toggles one checklist item's `done` flag for the given case.
  /// Returns true on success. No-op (false) in demo mode.
  Future<bool> toggleChecklistItem({
    required String caseId,
    required String itemId,
    required bool done,
  }) async {
    if (isDemo) return false;
    requireUuid(caseId, 'toggleChecklistItem');
    requireUuid(itemId, 'toggleChecklistItem');
    final response = await _client.rpc(
      'toggle_checklist_item',
      params: {
        'p_case_id': caseId,
        'p_item_id': itemId,
        'p_done': done,
      },
    );
    return response is Map && response['ok'] == true;
  }
}
