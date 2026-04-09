import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../services/assistant_tools.dart';
import '../../../services/tool_executor.dart';

// ---------------------------------------------------------------------------
// Models for tool_use parsing
// ---------------------------------------------------------------------------

/// Represents a single tool_use block extracted from a Claude API response.
class ToolUseBlock {
  final String id;
  final String name;
  final Map<String, dynamic> input;

  const ToolUseBlock({
    required this.id,
    required this.name,
    required this.input,
  });

  factory ToolUseBlock.fromJson(Map<String, dynamic> json) {
    return ToolUseBlock(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      input: (json['input'] as Map<String, dynamic>?) ?? {},
    );
  }
}

/// A chat message that resulted from a tool execution, containing both
/// the text response and the structured card data.
class ToolResultMessage {
  /// The text displayed as the AI message in the chat.
  final String displayText;

  /// The structured tool result for rendering a rich card.
  final ToolResult? toolResult;

  /// Navigation that should be performed after showing the result.
  final ToolNavigation? navigation;

  /// Claude's text response that accompanied the tool call (if any).
  final String? claudeText;

  const ToolResultMessage({
    required this.displayText,
    this.toolResult,
    this.navigation,
    this.claudeText,
  });
}

// ---------------------------------------------------------------------------
// ChatToolBridge — connects Claude API tool_use responses to the executor
// ---------------------------------------------------------------------------

class ChatToolBridge {
  ChatToolBridge({
    required this.context,
    required this.ref,
  })  : _executor = ToolExecutor(context: context, ref: ref),
        _log = Logger(
          printer: PrettyPrinter(methodCount: 0),
          level: kDebugMode ? Level.debug : Level.off,
        );

  final BuildContext context;
  final WidgetRef ref;
  final ToolExecutor _executor;
  final Logger _log;

  // ── Public API ─────────────────────────────────────────────────────────

  /// Parse a Claude API response and check if it contains tool_use blocks.
  ///
  /// Returns `true` if the response has at least one tool_use content block.
  static bool hasToolUse(Map<String, dynamic> response) {
    final content = response['content'] as List<dynamic>?;
    if (content == null) return false;
    return content.any(
      (block) => (block as Map<String, dynamic>)['type'] == 'tool_use',
    );
  }

  /// Extract all tool_use blocks from a Claude API response.
  static List<ToolUseBlock> extractToolUseBlocks(Map<String, dynamic> response) {
    final content = response['content'] as List<dynamic>?;
    if (content == null) return [];

    return content
        .where((block) => (block as Map<String, dynamic>)['type'] == 'tool_use')
        .map((block) => ToolUseBlock.fromJson(block as Map<String, dynamic>))
        .toList();
  }

  /// Extract any text blocks from a Claude API response.
  static String extractText(Map<String, dynamic> response) {
    final content = response['content'] as List<dynamic>?;
    if (content == null) return '';

    return content
        .where((block) => (block as Map<String, dynamic>)['type'] == 'text')
        .map((block) => (block as Map<String, dynamic>)['text'] as String)
        .join('\n');
  }

  /// Execute all tool_use blocks from a Claude response and return
  /// the results as [ToolResultMessage] objects ready for the chat UI.
  ///
  /// The caller is responsible for:
  /// 1. Inserting the messages into the chat
  /// 2. Performing any navigation from [ToolResultMessage.navigation]
  /// 3. Optionally continuing the conversation with tool results
  Future<List<ToolResultMessage>> executeToolCalls(
    Map<String, dynamic> response,
  ) async {
    final toolBlocks = extractToolUseBlocks(response);
    final claudeText = extractText(response);
    final results = <ToolResultMessage>[];

    for (final block in toolBlocks) {
      _log.i('Executing tool: ${block.name} (id: ${block.id})');

      try {
        final executionResult = await _executor.execute(block.name, block.input);
        final toolResult = executionResult.toolResult;

        results.add(ToolResultMessage(
          displayText: toolResult.displayText,
          toolResult: toolResult,
          navigation: executionResult.navigation,
          claudeText: claudeText.isNotEmpty ? claudeText : null,
        ));
      } catch (e) {
        _log.e('Tool execution failed: ${block.name}', error: e);
        results.add(ToolResultMessage(
          displayText: 'Failed to execute ${block.name}: $e',
          claudeText: claudeText.isNotEmpty ? claudeText : null,
        ));
      }
    }

    return results;
  }

  /// Build the tool_result messages to send back to Claude for continuing
  /// the conversation after tool execution.
  ///
  /// Returns a list of content blocks in the format Claude expects:
  /// ```json
  /// [{"type": "tool_result", "tool_use_id": "...", "content": "..."}]
  /// ```
  static List<Map<String, dynamic>> buildToolResultsForClaude(
    Map<String, dynamic> originalResponse,
    List<ToolResultMessage> results,
  ) {
    final toolBlocks = extractToolUseBlocks(originalResponse);
    final toolResults = <Map<String, dynamic>>[];

    for (var i = 0; i < toolBlocks.length && i < results.length; i++) {
      final block = toolBlocks[i];
      final result = results[i];

      toolResults.add({
        'type': 'tool_result',
        'tool_use_id': block.id,
        'content': result.toolResult != null
            ? json.encode(result.toolResult!.toJson())
            : result.displayText,
      });
    }

    return toolResults;
  }

  /// Perform all pending navigations from tool results.
  ///
  /// Call this after all results have been inserted into the chat.
  /// Only the first navigation will be executed (multiple navigations
  /// at once would be confusing).
  Future<void> performNavigations(List<ToolResultMessage> results) async {
    for (final result in results) {
      if (result.navigation != null && result.toolResult?.requiresApproval != true) {
        await _executor.performNavigation(result.navigation!);
        break; // Only navigate once
      }
    }
  }
}
