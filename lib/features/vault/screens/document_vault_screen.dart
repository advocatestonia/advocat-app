import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/router.dart';
import '../../../config/theme.dart';
import '../../../core/icons/app_icons.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/supabase_service.dart';
import '../../drafting/models/draft_model.dart';
import '../../drafting/screens/drafting_studio_screen.dart';
import '../../drafting/widgets/drafting_strings.dart';
// WAVE 2 FIX W2-03 (F3): SecureScreenScope protects the Vault from
// screenshots / screen recorders / iOS App-Switcher snapshot leak.
import '../../../shared/secure_screen.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../models/vault_document.dart';
import '../providers/vault_providers.dart';
import '../services/vault_service.dart';
import '../widgets/vault_strings.dart';

// ---------------------------------------------------------------------------
// Legacy provider (kept for backwards-compat with callers that still pull
// the raw `Map<String, dynamic>` shape, e.g. case-workspace document picker).
// New vault UI consumes `vaultDocumentsListProvider` from providers/.
// ---------------------------------------------------------------------------

final vaultDocumentsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final svc = ref.watch(supabaseServiceProvider);
  return svc.getVaultDocuments();
});

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class DocumentVaultScreen extends ConsumerStatefulWidget {
  const DocumentVaultScreen({super.key});

  @override
  ConsumerState<DocumentVaultScreen> createState() =>
      _DocumentVaultScreenState();
}

class _DocumentVaultScreenState extends ConsumerState<DocumentVaultScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _lockGlowController;
  late final AnimationController _pulseController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;
  late final Animation<double> _lockGlow;
  late final Animation<double> _pulse;

  // Debounced search controller. The provider key is bumped on each
  // keystroke after a 300ms quiet period so we don't issue an RPC per
  // character.
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    ));

    _lockGlowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _lockGlow = Tween<double>(begin: 0.15, end: 0.4).animate(
      CurvedAnimation(parent: _lockGlowController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _lockGlowController.dispose();
    _pulseController.dispose();
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      ref.read(vaultSearchQueryProvider.notifier).state = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vs = VaultStrings.of(context);
    final docsAsync = ref.watch(vaultDocumentsListProvider);

    return SecureScreenScope(
      child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.documentVault,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar — Cupertino style so iOS gets the familiar UI; on
          // Android it falls back to the material-themed Cupertino widget.
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: CupertinoSearchTextField(
              key: const ValueKey('vault_search_field'),
              controller: _searchCtrl,
              placeholder: vs.searchHint,
              onChanged: _onSearchChanged,
              onSuffixTap: () {
                _searchCtrl.clear();
                _onSearchChanged('');
              },
            ),
          ),

          // Tag chip row — single-select with "All" prepended.
          const _TagFilterRow(),

          const SizedBox(height: AppSpacing.sm),

          Expanded(
            child: docsAsync.when(
              // Cold-start: 5 document-tile skeletons. Matches real
              // ListTile dimensions so swap-in is jitter-free. Honors
              // WCAG 2.3.3 reduce-motion via _ReduceMotionShimmer.
              loading: () => const DocumentListSkeleton(itemCount: 5),
              error: (e, st) {
                debugPrint(
                    '[document_vault] docs provider failed: $e\n$st');
                return Center(
                  child: Text(l10n.genericError),
                );
              },
              data: (docs) {
                if (docs.isNotEmpty) {
                  return _buildDocumentList(context, l10n, docs);
                }
                return _buildEmptyState(context, l10n, vs);
              },
            ),
          ),
        ],
      ),
      ),
    );
  }

  // -- Open document --------------------------------------------------------

  /// Drafting × Vault — true for vault docs we can round-trip back into the
  /// Drafting Studio editor (.md / .txt / text/* mimes). PDFs and binary
  /// formats stay external-view-only.
  bool _isEditableInStudio(VaultDocument doc) {
    final n = doc.fileName.toLowerCase();
    return doc.mimeType.startsWith('text/') ||
        n.endsWith('.md') ||
        n.endsWith('.txt') ||
        n.endsWith('.markdown');
  }

  /// Drafting × Vault — fetch the vault doc's decrypted body, create a new
  /// draft seeded with that content, and navigate to the editor.
  Future<void> _editInStudio(VaultDocument doc) async {
    final draftingL10n = DraftingStrings.of(context);
    try {
      final vault = ref.read(vaultServiceProvider);
      final content = await vault.fetchDecryptedContent(doc.id);
      if (content == null || !content.isEditableInStudio) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(draftingL10n.saveToVaultFailed)),
        );
        return;
      }
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DraftingStudioScreen(
            prefill: DraftPrefill(
              title: content.fileName,
              contentMarkdown: content.contentText,
              sourceType: DraftSourceType.vaultImport,
              sourceId: content.documentId,
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${draftingL10n.saveToVaultFailed}: $e')),
      );
    }
  }

  Future<void> _openVaultDocument(VaultDocument doc) async {
    // If the doc is editable in the Studio, offer a choice: external view
    // (signed URL) vs Edit in Studio. Non-editable types just open the
    // signed URL straight away.
    if (_isEditableInStudio(doc) && mounted) {
      final draftingL10n = DraftingStrings.of(context);
      final action = await showModalBottomSheet<String>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                key: const Key('vault_doc_action_view'),
                leading: const Icon(Icons.open_in_new),
                title: const Text('View'),
                onTap: () => Navigator.of(ctx).pop('view'),
              ),
              ListTile(
                key: const Key('vault_doc_action_edit_in_studio'),
                leading: const Icon(Icons.edit_note_outlined),
                title: Text(draftingL10n.editInStudio),
                onTap: () => Navigator.of(ctx).pop('edit'),
              ),
            ],
          ),
        ),
      );
      if (action == 'edit') {
        await _editInStudio(doc);
        return;
      }
      if (action != 'view') return; // user dismissed
    }

    final storagePath = doc.storagePath;
    if (storagePath.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document path not found'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    try {
      final supabase = ref.read(supabaseServiceProvider);
      // Generate a fresh signed URL (5 min expiry) each time.
      final url = await supabase.getDocumentUrl(storagePath);
      if (url.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not generate document URL'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      final uri = Uri.parse(url);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open document: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // -- Delete confirmation --------------------------------------------------

  /// Tap-and-hold or swipe-left handler. Spec #2.
  Future<void> _confirmAndDelete(VaultDocument doc) async {
    final vs = VaultStrings.of(context);
    final result = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(vs.deleteFromVaultTitle),
        message: Text(
          '${doc.fileName}\n\n${vs.deleteFromVaultMessage}',
        ),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(vs.delete),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(false),
          isDefaultAction: true,
          child: Text(vs.cancel),
        ),
      ),
    );

    if (result != true) return;
    await _performDelete(doc);
  }

  Future<void> _performDelete(VaultDocument doc) async {
    final vs = VaultStrings.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(vaultServiceProvider).deleteDocument(doc.id);
      ref.invalidate(vaultDocumentsProvider);
      ref.invalidate(vaultDocumentsListProvider);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(vs.documentDeleted)),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('${vs.deleteFailed}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // -- Document list --------------------------------------------------------

  Widget _buildDocumentList(
    BuildContext context,
    AppLocalizations l10n,
    List<VaultDocument> docs,
  ) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              return _VaultDocumentTile(
                doc: doc,
                onTap: () => _openVaultDocument(doc),
                onLongPress: () => _confirmAndDelete(doc),
                onSwipeDelete: () => _confirmAndDelete(doc),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: _GlowButton(
            onPressed: () async {
              await context.push(AppRoutes.vaultAdd);
              ref.invalidate(vaultDocumentsProvider);
              ref.invalidate(vaultDocumentsListProvider);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, size: 20),
                const SizedBox(width: 8),
                Text(l10n.addDocument),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // -- Empty state ----------------------------------------------------------

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations l10n,
    VaultStrings vs,
  ) {
    return Center(
      child: FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideUp,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.04),
                    blurRadius: 40,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: AppSpacing.md),

                  // Lock icon with glow
                  AnimatedBuilder(
                    animation: _lockGlow,
                    builder: (context, child) {
                      return Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.accent
                                .withValues(alpha: _lockGlow.value),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent
                                  .withValues(alpha: _lockGlow.value * 0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lock_outlined,
                          size: 38,
                          color: AppColors.accent,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Premium header with shadow
                  Text(
                    l10n.secureDocumentStorage,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                          shadows: [
                            Shadow(
                              color:
                                  AppColors.primary.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  Text(
                    l10n.secureDocumentStorageDesc,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // NEW (Spec #5) — encryption reassurance line. Backend now
                  // encrypts at rest with the user's per-account key; this
                  // line is shown only in the empty state to set expectations.
                  Text(
                    vs.encryptedWithYourKey,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary.withValues(alpha: 0.85),
                      height: 1.45,
                      fontStyle: FontStyle.italic,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Glow button with tap animation
                  _GlowButton(
                    onPressed: () async {
                      await context.push(AppRoutes.vaultAdd);
                      ref.invalidate(vaultDocumentsProvider);
                      ref.invalidate(vaultDocumentsListProvider);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add, size: 20),
                        const SizedBox(width: 8),
                        Text(l10n.addDocument),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Encrypted badge with subtle pulse
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulse.value,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.06),
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                            border: Border.all(
                              color:
                                  AppColors.accent.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_user_outlined,
                                size: 14,
                                color:
                                    AppColors.accent.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                l10n.secureDocumentStorageDesc,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textTertiary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Horizontal tag filter chip row. "All" is synthesized on the client.
// ---------------------------------------------------------------------------

class _TagFilterRow extends ConsumerWidget {
  const _TagFilterRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vs = VaultStrings.of(context);
    final tagsAsync = ref.watch(vaultTagsProvider);
    final selected = ref.watch(vaultTagFilterProvider);
    final tags = tagsAsync.maybeWhen(
      data: (t) => t,
      orElse: () => VaultTag.defaults,
    );

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: tags.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          if (i == 0) {
            return _FilterChip(
              key: const ValueKey('vault_chip_all'),
              label: vs.tagAll,
              active: selected == null,
              onTap: () =>
                  ref.read(vaultTagFilterProvider.notifier).state = null,
            );
          }
          final tag = tags[i - 1];
          return _FilterChip(
            key: ValueKey('vault_chip_${tag.slug}'),
            label: vs.labelForSlug(tag.slug, fallback: tag.label),
            active: selected == tag.slug,
            onTap: () =>
                ref.read(vaultTagFilterProvider.notifier).state = tag.slug,
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: active ? AppColors.accent : AppColors.border,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? AppColors.textOnPrimary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// One row of the vault list. Wraps the existing ListTile look in a Dismissible
// so the user can swipe left to delete (matches iOS Mail / Notes behaviour),
// and adds onLongPress for the same action via tap-and-hold.
// ---------------------------------------------------------------------------

class _VaultDocumentTile extends StatelessWidget {
  const _VaultDocumentTile({
    required this.doc,
    required this.onTap,
    required this.onLongPress,
    required this.onSwipeDelete,
  });

  final VaultDocument doc;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onSwipeDelete;

  IconData get _icon {
    // Brand: doc-type tags use AppIcons (Phosphor) — keeps vault tile glyphs
    // visually consistent with the rest of the case-document surface.
    final mime = doc.mimeType;
    if (mime.contains('pdf')) return AppIcons.documentPdf;
    if (mime.contains('image')) return AppIcons.documentImage;
    return AppIcons.document;
  }

  String get _dateStr {
    final d = doc.createdAt.toLocal();
    final iso = d.toIso8601String();
    if (iso.length >= 16) return iso.substring(0, 16);
    return iso;
  }

  @override
  Widget build(BuildContext context) {
    final vs = VaultStrings.of(context);
    return Dismissible(
      key: ValueKey('vault_doc_${doc.id}'),
      direction: DismissDirection.endToStart,
      // Don't auto-remove from the list — we surface a confirmation sheet
      // first. Returning false leaves the tile in place; the actual delete
      // happens via `onSwipeDelete` which invalidates the provider on
      // success.
      confirmDismiss: (_) async {
        onSwipeDelete();
        return false;
      },
      background: Container(
        // RTL-aware: swipe-to-delete background icon sits at the trailing edge
        // (end). In LTR this is right; in RTL it is left, matching the
        // mirrored swipe direction Dismissible adopts under RTL Directionality.
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.delete_outline,
                color: AppColors.textOnPrimary, size: 20),
            const SizedBox(width: 8),
            Text(
              vs.delete,
              style: const TextStyle(
                color: AppColors.textOnPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      child: Card(
        color: AppColors.surface,
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.border),
        ),
        child: ListTile(
          leading: Icon(_icon, color: AppColors.accent),
          title: Text(
            doc.fileName,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Row(
            children: [
              if (doc.tagSlug != null && doc.tagSlug != 'other') ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    vs.labelForSlug(doc.tagSlug!, fallback: doc.tagLabel),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  _dateStr,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          // chevron_right is auto-mirrored by Flutter in RTL when given the
          // ambient text direction; ListTile.trailing flips position too.
          trailing: Icon(
            Icons.chevron_right,
            color: AppColors.textTertiary,
            textDirection: Directionality.of(context),
          ),
          onTap: onTap,
          onLongPress: onLongPress,
        ),
      ),
    );
  }
}

/// Premium button with accent glow effect and press animation.
class _GlowButton extends StatefulWidget {
  const _GlowButton({
    required this.onPressed,
    required this.child,
  });

  final VoidCallback onPressed;
  final Widget child;

  @override
  State<_GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<_GlowButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnim.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: DefaultTextStyle(
                style: const TextStyle(
                  color: AppColors.textOnPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                child: IconTheme(
                  data: const IconThemeData(color: AppColors.textOnPrimary),
                  child: child!,
                ),
              ),
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}
