import 'package:supabase_flutter/supabase_flutter.dart';

class ClientKnowledgeService {
  final _client = Supabase.instance.client;
  String? _cachedContext;
  String? _cachedCaseId;
  String? _cachedUserId;
  int _messageCount = 0;

  /// Clear all cached state (call on logout or user change).
  void clear() {
    _cachedContext = null;
    _cachedCaseId = null;
    _cachedUserId = null;
    _messageCount = 0;
  }

  Future<String> buildClientContext({String? caseId}) async {
    final uid = _client.auth.currentUser?.id;
    // Invalidate cache when user changes (e.g. after logout/login)
    if (uid != _cachedUserId) {
      clear();
      _cachedUserId = uid;
    }
    if (_cachedContext != null && _cachedCaseId == caseId && _messageCount < 5) {
      return _cachedContext!;
    }
    if (uid == null) return '';
    final buf = StringBuffer();
    // Fetch profile and cases in parallel for faster loading
    Map<String, dynamic>? profile;
    List<dynamic> cases = [];
    try {
      final futures = await Future.wait([
        _client.from('profiles').select().eq('id', uid).maybeSingle(),
        _client.from('cases').select().eq('user_id', uid).order('created_at', ascending: false),
      ]);
      profile = futures[0] as Map<String, dynamic>?;
      cases = (futures[1] as List?) ?? [];
    } catch (_) {}

    // Client identity — prominent at the top
    final clientName = profile?['full_name'] ?? 'Unknown';
    final clientLang = profile?['preferred_language'] ?? 'et';
    buf.writeln('=== CLIENT: $clientName ===');
    buf.writeln('Preferred language: $clientLang');
    if (profile?['email'] != null) buf.writeln('Email: ${profile!['email']}');
    if (profile?['phone'] != null) buf.writeln('Phone: ${profile!['phone']}');
    buf.writeln('Total cases: ${cases.length}');
    buf.writeln();

    // All cases summary — so the AI knows the full picture
    if (cases.isNotEmpty) {
      buf.writeln('=== ALL CASES SUMMARY ===');
      for (var i = 0; i < cases.length; i++) {
        final c = cases[i];
        final marker = c['id'] == caseId ? ' [CURRENT]' : '';
        buf.writeln('${i + 1}. ${c['title']} — ${c['type']}, ${c['status']}$marker');
      }
      buf.writeln();

      // Current case details
      final currentCase = cases.where((c) => c['id'] == caseId).toList();
      if (currentCase.isNotEmpty) {
        final c = currentCase.first;
        buf.writeln('=== CURRENT CASE: ${c['title']} ===');
        buf.writeln('Type: ${c['type']}');
        buf.writeln('Status: ${c['status']}');
        if (c['description'] != null && (c['description'] as String).isNotEmpty) {
          buf.writeln('Description: ${c['description']}');
        }
        if (c['nationality'] != null) buf.writeln('Nationality: ${c['nationality']}');
        if (c['country'] != null) buf.writeln('Country: ${c['country']}');
        buf.writeln();
      }
    }
    if (caseId != null) {
      try {
        final docs = await _client.from('documents').select().eq('case_id', caseId).order('created_at', ascending: false);
        if ((docs as List).isNotEmpty) {
          buf.writeln('=== DOCUMENTS (${docs.length}) ===');
          for (final d in docs) {
            buf.write('- ${d['file_name']}');
            if (d['ai_summary'] != null) buf.write(' — ${d['ai_summary']}');
            buf.writeln();
          }
          buf.writeln();
        }
      } catch (_) {}
      try {
        final deadlines = await _client.from('deadlines').select().eq('user_id', uid).order('due_date', ascending: true);
        if ((deadlines as List).isNotEmpty) {
          buf.writeln('=== DEADLINES ===');
          for (final d in deadlines) { buf.writeln('- ${d['title']}: ${d['due_date']} (${d['status']})'); }
          buf.writeln();
        }
      } catch (_) {}
      try {
        final msgs = await _client.from('chat_messages').select().eq('case_id', caseId).order('created_at', ascending: true);
        final recent = (msgs as List).length > 15 ? msgs.sublist(msgs.length - 15) : msgs;
        if (recent.isNotEmpty) {
          buf.writeln('=== RECENT CONVERSATION ===');
          for (final m in recent) {
            final content = (m['content'] as String? ?? '');
            buf.writeln('[${m['role']}]: ${content.length > 150 ? '${content.substring(0, 150)}...' : content}');
          }
          buf.writeln();
        }
      } catch (_) {}
    }
    var result = buf.toString();
    if (result.length > 25000) result = '${result.substring(0, 25000)}\n[truncated]';
    _cachedContext = result;
    _cachedCaseId = caseId;
    _messageCount = 0;
    return result;
  }

  void notifyMessageSent() {
    _messageCount++;
    if (_messageCount >= 5) _cachedContext = null;
  }
}
