// renewals_provider.dart — Riverpod wiring for the Renewal Radar.
// -----------------------------------------------------------------------------

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/renewable_document.dart';
import '../repositories/renewals_repository.dart';

final renewalsRepositoryProvider = Provider<RenewalsRepository>((ref) {
  return RenewalsRepository();
});

/// The caller's tracked documents, soonest-expiring first. Invalidate after a
/// create/update/delete to refresh the list.
final renewalsListProvider =
    FutureProvider<List<RenewableDocument>>((ref) async {
  return ref.watch(renewalsRepositoryProvider).list();
});
