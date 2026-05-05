// quick_profile_gate.dart — decision logic + persistence for the
// one-shot Quick Profile intake (2026-05-05).
// -----------------------------------------------------------------------------
// Why this exists:
//   Memory Tier 2 added legal_status / nationality / residence_status to
//   the bounded vocabulary, but the AI only learns them when the user
//   happens to volunteer them. Without an intake question, every chat
//   session re-asks "are you a citizen / EU / 3rd-country?" — wasteful,
//   and worse, the answer never settles into memory.
//
//   This gate decides whether to show the intake on a given chat mount.
//   It uses two signals:
//     1. UserMemory[] — if any legal-status key is already remembered,
//        skip the intake (the user already told us, possibly in a
//        previous session that did populate memory).
//     2. SharedPreferences flag `advocat_quick_profile_completed_at` —
//        a user who tapped Skip should not see the intake again either.
//
//   Both signals must be false to render the intake. Once the user
//   answers (chip or skip), [markCompleted] is called to set the flag.
// -----------------------------------------------------------------------------

import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/user_memory.dart';

/// Persistence key used for the local flag.  Mirrors the value the
/// product spec reserved on the web ("localStorage advocat_quick_profile_
/// completed_at"); SharedPreferences is the cross-platform equivalent
/// and uses the same namespace.
const String kQuickProfileCompletedKey = 'advocat_quick_profile_completed_at';

class QuickProfileGate {
  QuickProfileGate._();

  /// Decide whether to render the intake on this chat mount.
  ///
  /// Returns true ONLY when:
  ///   - [memories] contains no fact whose [UserMemory.key] is in
  ///     [kLegalStatusMemoryKeys] (legal_status, nationality, residence_status);
  ///   - SharedPreferences[[kQuickProfileCompletedKey]] is unset.
  static Future<bool> shouldShow({required List<UserMemory> memories}) async {
    final hasLegalStatus =
        memories.any((m) => kLegalStatusMemoryKeys.contains(m.key));
    if (hasLegalStatus) return false;

    final prefs = await SharedPreferences.getInstance();
    final stamped = prefs.getString(kQuickProfileCompletedKey);
    if (stamped != null && stamped.isNotEmpty) return false;
    return true;
  }

  /// Persist the "intake done" flag with the current UTC timestamp.
  /// Called both on chip-tap and skip-tap so the user is never
  /// re-prompted in this app installation.
  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      kQuickProfileCompletedKey,
      DateTime.now().toUtc().toIso8601String(),
    );
  }
}
