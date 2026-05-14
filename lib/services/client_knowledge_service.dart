import 'package:supabase_flutter/supabase_flutter.dart';

class ClientKnowledgeService {
  final _client = Supabase.instance.client;
  String? _cachedContext;
  String? _cachedCaseId;
  String? _cachedUserId;
  int _messageCount = 0;

  /// Strict UUID regex (8-4-4-4-12 hex). Mirrors SupabaseService._uuidRegex.
  /// Synthetic ids like 'general' or 'case-new-<ts>' return false so we
  /// avoid hitting Postgres with `case_id=eq.general` (PostgREST 400).
  static final _uuidRegex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  static bool _isRealUuid(String? id) =>
      id != null && _uuidRegex.hasMatch(id);

  /// Get the cached context without waiting for refresh.
  /// Returns null if no cache exists (first message).
  String? getCachedContext() => _cachedContext;

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
    if (profile?['subscription_tier'] != null) {
      buf.writeln('Subscription: ${profile!['subscription_tier']}');
    }
    if (profile?['avatar_url'] != null) {
      buf.writeln('Has profile photo: yes');
    }
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
      // Synthetic caseIds (e.g. 'general' general chat) are not UUIDs —
      // PostgREST returns 400 for `case_id=eq.general`. Short-circuit
      // case-scoped queries to empty lists; user-scoped queries still run
      // so cross-case memory still works.
      final hasRealCase = _isRealUuid(caseId);
      // Run all 5 queries in parallel for faster loading
      final parallelResults = await Future.wait([
        hasRealCase
            ? _client.from('documents').select().eq('case_id', caseId).order('created_at', ascending: false).catchError((_) => <dynamic>[])
            : Future.value(<dynamic>[]),
        _client.from('deadlines').select().eq('user_id', uid).order('due_date', ascending: true).catchError((_) => <dynamic>[]),
        hasRealCase
            ? _client.from('chat_messages').select().eq('case_id', caseId).order('created_at', ascending: true).catchError((_) => <dynamic>[])
            : Future.value(<dynamic>[]),
        _client.from('conversation_summaries').select('summary, case_id, created_at').eq('user_id', uid).order('created_at', ascending: false).limit(10).catchError((_) => <dynamic>[]),
        _client.from('chat_messages').select('role, content, created_at').eq('user_id', uid).order('created_at', ascending: false).limit(20).catchError((_) => <dynamic>[]),
      ]);
      final docs = parallelResults[0];
      final deadlines = parallelResults[1];
      final msgs = parallelResults[2];
      final summaries = parallelResults[3];
      final allMsgs = parallelResults[4];

      if (docs.isNotEmpty) {
        buf.writeln('=== DOCUMENTS (${docs.length}) ===');
        for (final d in docs) {
          buf.write('- ${d['file_name']}');
          if (d['ai_summary'] != null) buf.write(' — ${d['ai_summary']}');
          buf.writeln();
        }
        buf.writeln();
      }

      if (deadlines.isNotEmpty) {
        buf.writeln('=== DEADLINES ===');
        for (final d in deadlines) { buf.writeln('- ${d['title']}: ${d['due_date']} (${d['status']})'); }
        buf.writeln();
      }

      final recent = msgs.length > 50 ? msgs.sublist(msgs.length - 50) : msgs;
      if (recent.isNotEmpty) {
        buf.writeln('=== RECENT CONVERSATION ===');
        for (final m in recent) {
          final content = (m['content'] as String? ?? '');
          buf.writeln('[${m['role']}]: ${content.length > 500 ? '${content.substring(0, 500)}...' : content}');
        }
        buf.writeln();
      }

      // Conversation summaries for long-term memory
      if (summaries.isNotEmpty) {
        buf.writeln('=== CONVERSATION MEMORY (past sessions) ===');
        for (final s in summaries) {
          buf.writeln('--- Session (${s['created_at']}) ---');
          buf.writeln(s['summary']);
        }
        buf.writeln();
      }

      // Recent messages from ALL cases for cross-session memory
      if (allMsgs.isNotEmpty) {
        buf.writeln('=== USER HISTORY (across all conversations) ===');
        for (final m in allMsgs.reversed) {
          final content = (m['content'] as String? ?? '');
          final preview = content.length > 200
              ? '${content.substring(0, 200)}...'
              : content;
          buf.writeln('[${m['role']}]: $preview');
        }
        buf.writeln();
      }
    }
    var result = buf.toString();
    if (result.length > 35000) result = '${result.substring(0, 35000)}\n[truncated]';
    _cachedContext = result;
    _cachedCaseId = caseId;
    _messageCount = 0;
    return result;
  }

  void notifyMessageSent() {
    _messageCount++;
    if (_messageCount >= 5) _cachedContext = null;
  }

  /// Generate and save a conversation summary for long-term memory.
  /// Call this when user leaves the chat screen.
  Future<void> saveConversationSummary({required String caseId}) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    // Synthetic caseIds (general chat) have no row in cases — nothing
    // to summarise against. Skip silently rather than hitting Postgres
    // with a non-UUID and getting a 400.
    if (!_isRealUuid(caseId)) return;

    try {
      // Get recent messages for this case
      final msgs = await _client
          .from('chat_messages')
          .select('role, content')
          .eq('case_id', caseId)
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(20);

      if ((msgs as List).length < 3) return; // Too few messages to summarize

      // Check if we already have a recent summary
      final existingSummaries = await _client
          .from('conversation_summaries')
          .select('created_at')
          .eq('user_id', uid)
          .eq('case_id', caseId)
          .order('created_at', ascending: false)
          .limit(1);

      if ((existingSummaries as List).isNotEmpty) {
        final lastSummary =
            DateTime.parse(existingSummaries[0]['created_at'] as String);
        if (DateTime.now().difference(lastSummary).inMinutes < 30) return;
      }

      // Build conversation text for summary
      final conversationText = msgs.reversed
          .map((m) =>
              '[${m['role']}]: ${(m['content'] as String).length > 500 ? (m['content'] as String).substring(0, 500) : m['content']}')
          .join('\n');

      // Generate summary using simple extraction (no extra API call)
      final summary = _extractSummary(conversationText);

      await _client.from('conversation_summaries').insert({
        'user_id': uid,
        'case_id': caseId,
        'summary': summary,
      });
    } catch (_) {}
  }

  String _extractSummary(String conversation) {
    final buf = StringBuffer();
    final lines = conversation.split('\n');
    final userLines = lines.where((l) => l.startsWith('[user]')).toList();
    final aiLines = lines.where((l) => l.startsWith('[assistant]')).toList();

    // Extract key facts from user messages
    buf.writeln('CLIENT DISCUSSED:');
    for (final line in userLines.take(8)) {
      final content = line.replaceFirst('[user]: ', '');
      buf.writeln(
          '- ${content.length > 200 ? content.substring(0, 200) : content}');
    }

    // Extract key advice from AI messages
    if (aiLines.isNotEmpty) {
      buf.writeln('AI ADVISED:');
      for (final line in aiLines.take(5)) {
        final content = line.replaceFirst('[assistant]: ', '');
        buf.writeln(
            '- ${content.length > 200 ? content.substring(0, 200) : content}');
      }
    }

    // Extract dates, numbers, names mentioned
    final allText = userLines.join(' ');
    final dates = RegExp(r'\d{1,2}[./]\d{1,2}[./]\d{2,4}')
        .allMatches(allText)
        .map((m) => m.group(0))
        .toSet();
    final amounts = RegExp(r'€?\d+[\s,.]?\d*\s*(?:€|EUR|eur|евро|eurot)')
        .allMatches(allText)
        .map((m) => m.group(0))
        .toSet();

    if (dates.isNotEmpty) buf.writeln('DATES MENTIONED: ${dates.join(", ")}');
    if (amounts.isNotEmpty) {
      buf.writeln('AMOUNTS MENTIONED: ${amounts.join(", ")}');
    }

    return buf.toString();
  }
}
