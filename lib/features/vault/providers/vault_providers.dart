// features/vault/providers/vault_providers.dart — Vault screen state.
// -----------------------------------------------------------------------------
// Shared Riverpod providers used by `document_vault_screen.dart` and
// `add_vault_document_screen.dart`. Kept separate from the screen file so
// tests can override providers without importing the widget.
// -----------------------------------------------------------------------------

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/vault_document.dart';
import '../services/vault_service.dart';

/// Slug of the currently-selected tag chip, or `null` for "All".
final vaultTagFilterProvider = StateProvider<String?>((_) => null);

/// Free-text search query (debounced by the widget). Empty = no filter.
final vaultSearchQueryProvider = StateProvider<String>((_) => '');

/// Documents shown in the list, combining tag filter + search query.
/// Backend agents own the actual filtering once `vault.search_documents`
/// exists; until then the service performs client-side fallbacks.
final vaultDocumentsListProvider =
    FutureProvider.autoDispose<List<VaultDocument>>((ref) async {
  final svc = ref.watch(vaultServiceProvider);
  final query = ref.watch(vaultSearchQueryProvider).trim();
  final tag = ref.watch(vaultTagFilterProvider);
  if (query.isNotEmpty) {
    final hits = await svc.search(query);
    if (tag == null) return hits;
    return hits.where((d) {
      if (tag == 'other') return d.tagSlug == null || d.tagSlug == 'other';
      return d.tagSlug == tag;
    }).toList();
  }
  return svc.getDocuments(tagFilter: tag);
});

/// Tags available in the chip row + the upload tag picker.
final vaultTagsProvider =
    FutureProvider.autoDispose<List<VaultTag>>((ref) async {
  return ref.watch(vaultServiceProvider).getTags();
});
