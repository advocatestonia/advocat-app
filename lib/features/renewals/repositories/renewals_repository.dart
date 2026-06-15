// renewals_repository.dart — data access for the Renewal Radar.
// -----------------------------------------------------------------------------
// Self-contained: talks to the renewable_documents table directly via the
// Supabase client (RLS owner-only, so no server round-trip needed for CRUD).
// Kept out of the shared SupabaseService to avoid touching a hot shared file.
// -----------------------------------------------------------------------------

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/renewable_document.dart';

class RenewalsRepositoryException implements Exception {
  const RenewalsRepositoryException(this.message);
  final String message;
  @override
  String toString() => 'RenewalsRepositoryException: $message';
}

class RenewalsRepository {
  RenewalsRepository();

  SupabaseClient get _client => Supabase.instance.client;
  String? get _userId => _client.auth.currentUser?.id;

  /// All of the caller's tracked documents, soonest-expiring first. Uses the
  /// security-invoker RPC so ordering/filtering is centralised in the DB.
  Future<List<RenewableDocument>> list() async {
    try {
      final rows = await _client.rpc('renewable_documents_list');
      if (rows is! List) return const [];
      return rows
          .map((e) =>
              RenewableDocument.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      throw RenewalsRepositoryException('Failed to load documents: $e');
    }
  }

  /// Insert a new tracked document. Returns the created row.
  Future<RenewableDocument> create(RenewableDocument doc) async {
    final uid = _userId;
    if (uid == null) {
      throw const RenewalsRepositoryException('Not signed in');
    }
    try {
      final payload = {...doc.toInsert(), 'user_id': uid};
      final inserted = await _client
          .from('renewable_documents')
          .insert(payload)
          .select()
          .single();
      return RenewableDocument.fromJson(Map<String, dynamic>.from(inserted));
    } catch (e) {
      throw RenewalsRepositoryException('Failed to add document: $e');
    }
  }

  /// Update mutable fields of an existing document.
  Future<void> update(String id, RenewableDocument doc) async {
    try {
      await _client
          .from('renewable_documents')
          .update(doc.toInsert())
          .eq('id', id);
    } catch (e) {
      throw RenewalsRepositoryException('Failed to update document: $e');
    }
  }

  /// Toggle per-document reminders on/off without deleting it.
  Future<void> setNotificationsEnabled(String id, bool enabled) async {
    try {
      await _client
          .from('renewable_documents')
          .update({'notifications_enabled': enabled}).eq('id', id);
    } catch (e) {
      throw RenewalsRepositoryException('Failed to update reminders: $e');
    }
  }

  /// Permanently delete a tracked document.
  Future<void> delete(String id) async {
    try {
      await _client.from('renewable_documents').delete().eq('id', id);
    } catch (e) {
      throw RenewalsRepositoryException('Failed to delete document: $e');
    }
  }
}
