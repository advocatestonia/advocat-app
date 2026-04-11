import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';

import '../config/router.dart';
import 'assistant_tools.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// Provider for ToolExecutor. Requires a [BuildContext] for navigation,
/// so it is created per-screen rather than globally.
///
/// Usage from a ConsumerState:
/// ```dart
/// final executor = ToolExecutor(context: context, ref: ref);
/// final result = await executor.execute('check_company', {'company_name': 'Acme'});
/// ```

// ---------------------------------------------------------------------------
// Navigation action model
// ---------------------------------------------------------------------------

/// Describes a deferred navigation that should happen after displaying
/// the tool result in the chat.
class ToolNavigation {
  /// The GoRouter path to push.
  final String route;

  /// Optional delay before navigating (lets the user see the chat result).
  final Duration delay;

  /// Extra data to pass via GoRouter extra parameter.
  final Object? extra;

  const ToolNavigation({
    required this.route,
    this.delay = const Duration(milliseconds: 600),
    this.extra,
  });
}

// ---------------------------------------------------------------------------
// Extended result that includes navigation intent
// ---------------------------------------------------------------------------

class ToolExecutionResult {
  final ToolResult toolResult;
  final ToolNavigation? navigation;

  const ToolExecutionResult({
    required this.toolResult,
    this.navigation,
  });
}

// ---------------------------------------------------------------------------
// Tool executor — bridges AI tool calls to real app actions + navigation
// ---------------------------------------------------------------------------

class ToolExecutor {
  ToolExecutor({
    required this.context,
    required this.ref,
  })  : _tools = ref.read(assistantToolsProvider),
        _log = Logger(
          printer: PrettyPrinter(methodCount: 0),
          level: kDebugMode ? Level.debug : Level.off,
        );

  final BuildContext context;
  final WidgetRef ref;
  final AssistantTools _tools;
  final Logger _log;

  /// Execute a tool by name with given parameters.
  ///
  /// Returns a [ToolExecutionResult] containing the tool output and an
  /// optional [ToolNavigation] that the caller should perform after
  /// inserting the result into the chat.
  Future<ToolExecutionResult> execute(
    String toolName,
    Map<String, dynamic> params,
  ) async {
    _log.i('ToolExecutor: executing "$toolName"');

    // 1. Run the tool logic via AssistantTools
    final result = await _tools.execute(toolName, params);

    // 2. Determine if this tool should trigger navigation
    final navigation = _resolveNavigation(toolName, params, result);

    return ToolExecutionResult(
      toolResult: result,
      navigation: navigation,
    );
  }

  /// Perform the deferred navigation if present.
  ///
  /// Call this after the tool result has been inserted into the chat
  /// so the user can see the result before the screen changes.
  Future<void> performNavigation(ToolNavigation navigation) async {
    if (navigation.delay > Duration.zero) {
      await Future.delayed(navigation.delay);
    }

    if (!context.mounted) return;

    _log.i('ToolExecutor: navigating to ${navigation.route}');
    if (navigation.route == '__pop__') {
      GoRouter.of(context).pop();
    } else {
      GoRouter.of(context).push(navigation.route, extra: navigation.extra);
    }
  }

  // ── Navigation resolution ────────────────────────────────────────────

  ToolNavigation? _resolveNavigation(
    String toolName,
    Map<String, dynamic> params,
    ToolResult result,
  ) {
    if (!result.success) return null;

    switch (toolName) {
      case 'check_company':
        return ToolNavigation(
          route: AppRoutes.checkerCompany,
          extra: result.data,
        );

      case 'check_vehicle':
        return ToolNavigation(
          route: AppRoutes.checkerVehicle,
          extra: result.data,
        );

      case 'create_case':
        // Only navigate after user approves (requiresApproval = true)
        if (!result.requiresApproval) {
          final caseId = result.data?['case_id'] as String?;
          if (caseId != null) {
            return ToolNavigation(
              route: '/cases/$caseId',
              delay: const Duration(milliseconds: 800),
            );
          }
        }
        return null;

      case 'get_deadlines':
        return const ToolNavigation(route: AppRoutes.deadlines);

      case 'analyze_document':
        // Stay in chat -- analysis is displayed inline
        return null;

      case 'generate_draft':
        // Stay in chat -- draft preview shown inline
        return null;

      case 'find_lawyer':
        // Stay in chat -- contacts shown inline
        return null;

      case 'draft_email':
        // Email sending is handled via mailto: link in the approval flow,
        // not by navigating to the email settings screen.
        return null;

      case 'get_case_status':
        final caseId = params['case_id'] as String?;
        if (caseId != null) {
          return ToolNavigation(
            route: '/cases/$caseId',
            extra: result.data,
          );
        }
        return null;

      case 'open_camera':
        return const ToolNavigation(
          route: AppRoutes.scan,
          delay: Duration(milliseconds: 300),
        );

      case 'change_language':
        // Language change happens via state, no navigation needed
        return null;

      case 'translate_text':
        // Translation result shown inline
        return null;

      case 'search_knowledge':
        // Knowledge results shown inline
        return null;

      case 'navigate_to':
        final screen = params['screen'] as String? ?? 'home';

        // Handle "back" / "previous" / "chat" as a pop action
        if (screen == 'back' || screen == 'previous' || screen == 'chat') {
          return const ToolNavigation(
            route: '__pop__',
            delay: Duration(milliseconds: 300),
          );
        }

        const routeMap = <String, String>{
          'home': AppRoutes.home,
          'cases': AppRoutes.cases,
          'deadlines': AppRoutes.deadlines,
          'settings': AppRoutes.settings,
          'subscription': AppRoutes.subscription,
          'email': AppRoutes.email,
          'scan': AppRoutes.scan,
          'vault': AppRoutes.vault,
          'rights': AppRoutes.rights,
          'legal_aid': AppRoutes.legalAid,
          'checker': AppRoutes.checker,
          'new_case': AppRoutes.caseCreate,
          'profile': AppRoutes.settings,
        };
        final route = routeMap[screen] ?? AppRoutes.home;
        return ToolNavigation(
          route: route,
          delay: const Duration(milliseconds: 300),
        );

      default:
        return null;
    }
  }
}
