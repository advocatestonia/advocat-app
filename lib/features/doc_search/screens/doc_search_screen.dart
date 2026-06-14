// =============================================================================
// doc_search_screen.dart — Feature #4: Semantic search over the user's OWN
// documents (Vault + case documents).
// =============================================================================
//
// Why this exists
// ---------------
// Users and B2B firms accumulate dozens-to-hundreds of documents. Today they
// can only search by FILENAME. This screen adds search by CONTENT — "where was
// the deposit mentioned", "the termination clause" — backed by per-chunk
// embeddings in a dedicated, RLS-isolated table (user_doc_chunks).
//
// Backend (both RLS-scoped to the caller):
//   * doc-semantic-search → embeds the query + vector match.
//   * doc-indexer         → indexes a document on demand.
//
// This screen is purely additive: a search box + a results list. It does not
// touch the vault or case screens; it links INTO them on tap.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/doc_search_provider.dart';
import '../widgets/doc_search_result_tile.dart';

/// Stable test keys.
const kDocSearchField = Key('doc_search_field');
const kDocSearchResults = Key('doc_search_results');
const kDocSearchEmpty = Key('doc_search_empty');
const kDocSearchError = Key('doc_search_error');

class DocSearchScreen extends ConsumerStatefulWidget {
  const DocSearchScreen({super.key});

  @override
  ConsumerState<DocSearchScreen> createState() => _DocSearchScreenState();
}

class _DocSearchScreenState extends ConsumerState<DocSearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _runSearch() {
    FocusScope.of(context).unfocus();
    ref.read(docSearchProvider.notifier).setQuery(_controller.text);
    ref.read(docSearchProvider.notifier).search();
  }

  void _onTapHit(String sourceKind) {
    // Deep-link into the right surface. We don't have the parent case id on a
    // chunk, so we land on the relevant list; the user picks the document.
    if (sourceKind == 'case_document') {
      context.push(AppRoutes.cases);
    } else {
      context.push(AppRoutes.vault);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(docSearchProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.docSearchTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              key: kDocSearchField,
              controller: _controller,
              textInputAction: TextInputAction.search,
              onChanged: (v) =>
                  ref.read(docSearchProvider.notifier).setQuery(v),
              onSubmitted: (_) => _runSearch(),
              decoration: InputDecoration(
                hintText: l10n.docSearchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: state.query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          ref.read(docSearchProvider.notifier).clear();
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.docSearchSubtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ),
          Expanded(child: _body(context, l10n, state)),
        ],
      ),
    );
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l10n,
    DocSearchState state,
  ) {
    switch (state.status) {
      case DocSearchStatus.idle:
        return _Hint(text: l10n.docSearchIdle, icon: Icons.manage_search);
      case DocSearchStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case DocSearchStatus.empty:
        return _Hint(
          key: kDocSearchEmpty,
          text: l10n.docSearchNoResults,
          icon: Icons.search_off,
        );
      case DocSearchStatus.error:
        return _Hint(
          key: kDocSearchError,
          text: state.errorMessage ?? l10n.docSearchError,
          icon: Icons.error_outline,
          color: AppColors.error,
        );
      case DocSearchStatus.results:
        return ListView.builder(
          key: kDocSearchResults,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: state.hits.length,
          itemBuilder: (context, i) {
            final hit = state.hits[i];
            return DocSearchResultTile(
              hit: hit,
              onTap: () => _onTapHit(hit.sourceKind),
            );
          },
        );
    }
  }
}

class _Hint extends StatelessWidget {
  const _Hint({
    super.key,
    required this.text,
    required this.icon,
    this.color,
  });

  final String text;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: color ?? AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: color ?? AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
