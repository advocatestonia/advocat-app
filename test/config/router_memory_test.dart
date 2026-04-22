// TDD test for the AI-memory route (ADR-001 Tier 1 integration).
// -----------------------------------------------------------------------------
// Ref: docs/memory-tier1/integration_patch.md §4
//      lib/config/router.dart
//      lib/features/profile/screens/ai_memory_screen.dart
//
// Locks down that a dedicated top-level route constant exists and that
// it points at the path exposed by AiMemoryScreen.routePath.
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/config/router.dart';
import 'package:advocat/features/profile/screens/ai_memory_screen.dart';

void main() {
  group('AppRoutes.aiMemory', () {
    test('exposes the /profile/ai-memory path', () {
      expect(AppRoutes.aiMemory, '/profile/ai-memory');
    });

    test('matches AiMemoryScreen.routePath (single source of truth)', () {
      expect(AppRoutes.aiMemory, AiMemoryScreen.routePath);
    });

    test('starts with / and is a profile-scoped path', () {
      expect(AppRoutes.aiMemory.startsWith('/'), isTrue);
      expect(AppRoutes.aiMemory, startsWith('/profile/'));
    });
  });
}
