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
    try {
      final profile = await _client.from('profiles').select().eq('id', uid).maybeSingle();
      if (profile != null) {
        buf.writeln('=== CLIENT PROFILE ===');
        buf.writeln('Name: ${profile['full_name'] ?? 'Unknown'}');
        buf.writeln('Email: ${profile['email'] ?? ''}');
        if (profile['phone'] != null) buf.writeln('Phone: ${profile['phone']}');
        buf.writeln('Language: ${profile['preferred_language'] ?? 'et'}');
        buf.writeln();
      }
    } catch (_) {}
    try {
      final cases = await _client.from('cases').select().eq('user_id', uid).order('created_at', ascending: false);
      if ((cases as List).isNotEmpty) {
        buf.writeln('=== CLIENT CASES (${cases.length}) ===');
        for (final c in cases) {
          buf.write(c['id'] == caseId ? '>>> CURRENT: ' : '- ');
          buf.writeln('${c['title']} (${c['type']}, ${c['status']})');
          if (c['description'] != null) buf.writeln('  ${c['description']}');
        }
        buf.writeln();
      }
    } catch (_) {}
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
        final recent = (msgs as List).length > 10 ? msgs.sublist(msgs.length - 10) : msgs;
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
    if (result.length > 15000) result = '${result.substring(0, 15000)}\n[truncated]';
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
