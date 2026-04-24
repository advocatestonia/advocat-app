@Tags(['fast'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/tool_definitions.dart';

/// Verifies the Anthropic `web_search` server tool is declared correctly
/// and is forwarded alongside the user-defined tools.
///
/// We can't make a live Anthropic call here (no API key in unit tests), so
/// we assert the declaration shape matches what the API expects and that
/// the `allTools` array includes it. The integration path is smoke-tested
/// in `tests_overnight/` via a real proxy request.
void main() {
  group('web_search server tool declaration', () {
    test('serverTools contains web_search_20250305 entry', () {
      final ws = ToolDefinitions.serverTools
          .firstWhere((t) => t['name'] == 'web_search', orElse: () => {});
      expect(ws, isNotEmpty, reason: 'web_search must be declared');
      expect(ws['type'], 'web_search_20250305');
      expect(ws['max_uses'], isA<int>());
      expect(ws['max_uses'], lessThanOrEqualTo(5),
          reason: 'cap max_uses to avoid surprise \$10/1K billing');
      expect(ws['max_uses'], greaterThan(0));
    });

    test('web_search tool has NO input_schema (server tool shape)', () {
      // Anthropic server tools use a simpler schema than user-defined tools:
      // they expose `type` + `name` only. Including `input_schema` causes a
      // 400 "invalid server tool" error from the API.
      final ws = ToolDefinitions.serverTools
          .firstWhere((t) => t['name'] == 'web_search');
      expect(ws.containsKey('input_schema'), isFalse);
      expect(ws.containsKey('description'), isFalse);
    });

    test('allTools includes both client tools and web_search', () {
      final all = ToolDefinitions.allTools;
      // A representative client tool
      expect(all.any((t) => t['name'] == 'search_estonian_law'), isTrue);
      // The server tool
      expect(
        all.any((t) => t['name'] == 'web_search' && t['type'] == 'web_search_20250305'),
        isTrue,
        reason: 'web_search must be in the combined tools array sent to Claude',
      );
    });

    test('web_search is NOT in the client-side handler registry', () {
      // The client must never try to execute web_search — Anthropic does.
      // Our tool_definitions.toolNames lists only client-executed tools.
      expect(ToolDefinitions.toolNames, isNot(contains('web_search')));
    });

    test('allTools array is valid JSON-serialisable shape', () {
      for (final t in ToolDefinitions.allTools) {
        expect(t, isA<Map<String, dynamic>>());
        // Either has `name` (user tool) or `type` + `name` (server tool).
        expect(t['name'], isA<String>());
      }
    });
  });
}
