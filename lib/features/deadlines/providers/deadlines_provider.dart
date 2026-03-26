import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/deadline.dart';
import '../../../services/supabase_service.dart';

/// All deadlines for the current user, sorted by due date.
final allDeadlinesProvider = FutureProvider<List<Deadline>>((ref) async {
  return ref.watch(supabaseServiceProvider).getDeadlines();
});

/// Deadlines for a specific case.
final caseDeadlinesProvider =
    FutureProvider.family<List<Deadline>, String>((ref, caseId) async {
  return ref.watch(supabaseServiceProvider).getDeadlines(caseId: caseId);
});
