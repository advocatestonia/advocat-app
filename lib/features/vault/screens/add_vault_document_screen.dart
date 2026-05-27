import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/supabase_service.dart';
import '../../legal/utils/sensitive_consent_gate.dart';
import '../models/vault_document.dart';
import '../providers/vault_providers.dart';
import '../services/vault_service.dart';
import '../widgets/vault_strings.dart';
import 'document_vault_screen.dart';

/// Detect MIME type from file extension.
String _mimeFromExt(String fileName) {
  final ext = fileName.toLowerCase().split('.').last;
  switch (ext) {
    case 'pdf':
      return 'application/pdf';
    case 'doc':
      return 'application/msword';
    case 'docx':
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    case 'txt':
      return 'text/plain';
    case 'png':
      return 'image/png';
    case 'heic':
      return 'image/heic';
    case 'jpg':
    case 'jpeg':
    default:
      return 'image/jpeg';
  }
}

class AddVaultDocumentScreen extends ConsumerStatefulWidget {
  const AddVaultDocumentScreen({super.key});

  @override
  ConsumerState<AddVaultDocumentScreen> createState() =>
      _AddVaultDocumentScreenState();
}

class _AddVaultDocumentScreenState
    extends ConsumerState<AddVaultDocumentScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  bool _uploading = false;

  /// Selected tag slug for the next upload. Defaults to "other" per spec.
  String _selectedTagSlug = 'other';

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  /// Looks up the tag id for [_selectedTagSlug] inside the loaded tag
  /// list, falling back to the slug itself (which the backend treats as
  /// a stable default-tag id) when the AsyncValue hasn't resolved.
  String _selectedTagId(List<VaultTag> tags) {
    final hit = tags.where((t) => t.slug == _selectedTagSlug);
    if (hit.isNotEmpty) return hit.first.id;
    return _selectedTagSlug;
  }

  /// Pick any file (PDF, DOC, DOCX, TXT, images) using FilePicker.
  Future<void> _pickFileAndUpload() async {
    // GDPR Art. 9(2)(a) — explicit consent before opening the OS picker.
    final consented = await ensureSensitiveConsent(context, ref);
    if (!consented) return;
    if (!mounted) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf', 'doc', 'docx', 'txt',
        'jpg', 'jpeg', 'png', 'heic',
      ],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null || file.name.isEmpty) return;

    setState(() => _uploading = true);
    try {
      final mimeType = _mimeFromExt(file.name);
      final svc = ref.read(supabaseServiceProvider);
      final caseId = 'vault-${DateTime.now().millisecondsSinceEpoch}';
      final docId = await svc.uploadDocument(
        caseId: caseId,
        fileName: file.name,
        fileBytes: file.bytes!,
        mimeType: mimeType,
      );

      // Best-effort tag attach. Failure is non-fatal — the doc still lands
      // in the vault, just untagged. See VaultService.tagDocument for the
      // fallback logic while the backend tables are being built.
      await _tryTagDocument(docId);

      ref.invalidate(vaultDocumentsProvider);
      ref.invalidate(vaultDocumentsListProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document uploaded successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Upload error: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.genericError ??
                  'Something went wrong. Please try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  /// Take a photo with the camera and upload it.
  Future<void> _scanAndUpload() async {
    // GDPR Art. 9(2)(a) — explicit consent before the camera fires.
    final consented = await ensureSensitiveConsent(context, ref);
    if (!consented) return;
    if (!mounted) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _uploading = true);
    try {
      final bytes = await picked.readAsBytes();
      final fileName = picked.name;
      final mimeType = _mimeFromExt(fileName);
      final svc = ref.read(supabaseServiceProvider);
      final caseId = 'vault-${DateTime.now().millisecondsSinceEpoch}';
      final docId = await svc.uploadDocument(
        caseId: caseId,
        fileName: fileName,
        fileBytes: bytes,
        mimeType: mimeType,
      );

      await _tryTagDocument(docId);

      ref.invalidate(vaultDocumentsProvider);
      ref.invalidate(vaultDocumentsListProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document uploaded successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Upload error: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.genericError ??
                  'Something went wrong. Please try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  /// Best-effort tag attach. Reads the resolved tag list synchronously so
  /// we don't block the upload UI on the providers.
  Future<void> _tryTagDocument(String docId) async {
    if (_selectedTagSlug.isEmpty) return;
    final tagsAsync = ref.read(vaultTagsProvider);
    final tags = tagsAsync.maybeWhen(
      data: (t) => t,
      orElse: () => VaultTag.defaults,
    );
    final tagId = _selectedTagId(tags);
    try {
      await ref.read(vaultServiceProvider).tagDocument(docId, tagId);
    } catch (e) {
      if (kDebugMode) debugPrint('[vault] tag attach failed: $e');
    }
  }

  /// Spec #1 — route the "Create Note" tile to the Drafting Studio with a
  /// `source=vault_note` marker. The Drafting Studio agent will pick up
  /// that query param and stamp the resulting draft into the vault on save.
  void _openCreateNote() {
    context.push('/drafts/new?source=vault_note');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vs = VaultStrings.of(context);
    final tagsAsync = ref.watch(vaultTagsProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.addDocument,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: _uploading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Premium header with subtle shadow
                    Text(
                      l10n.chooseHowToAdd,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                        shadows: [
                          Shadow(
                            color:
                                AppColors.primary.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Tag picker — single-select horizontal chip row.
                    _TagPicker(
                      title: vs.tagPickerTitle,
                      tagsAsync: tagsAsync,
                      selectedSlug: _selectedTagSlug,
                      onTap: (slug) => setState(() {
                        _selectedTagSlug = slug;
                      }),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    _AnimatedOptionCard(
                      index: 0,
                      controller: _entranceController,
                      icon: Icons.camera_alt_outlined,
                      title: l10n.scanDocument,
                      subtitle: l10n.scanDocumentDesc,
                      color: AppColors.accent,
                      onTap: _scanAndUpload,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _AnimatedOptionCard(
                      index: 1,
                      controller: _entranceController,
                      icon: Icons.upload_file_outlined,
                      title: l10n.uploadFile,
                      subtitle: l10n.uploadFileDesc,
                      color: AppColors.info,
                      onTap: _pickFileAndUpload,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _AnimatedOptionCard(
                      index: 2,
                      controller: _entranceController,
                      icon: Icons.edit_document,
                      title: l10n.createNote,
                      subtitle: l10n.createNoteDesc,
                      color: AppColors.warning,
                      onTap: _openCreateNote,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Single-select horizontal chip row for tagging a fresh upload. Renders
/// the localized label from [VaultStrings.labelForSlug] regardless of what
/// the backend returned, so the picker reads cleanly in any locale.
class _TagPicker extends StatelessWidget {
  const _TagPicker({
    required this.title,
    required this.tagsAsync,
    required this.selectedSlug,
    required this.onTap,
  });

  final String title;
  final AsyncValue<List<VaultTag>> tagsAsync;
  final String selectedSlug;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final vs = VaultStrings.of(context);
    final tags = tagsAsync.maybeWhen(
      data: (t) => t,
      orElse: () => VaultTag.defaults,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tags.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final tag = tags[i];
              final active = tag.slug == selectedSlug;
              return _Chip(
                label: vs.labelForSlug(tag.slug, fallback: tag.label),
                active: active,
                onTap: () => onTap(tag.slug),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Pill-shaped chip used in both the upload tag picker and the vault list
/// filter row. Active state pulls from the accent palette to match the
/// "Add Document" CTA and the encryption badge.
class _Chip extends StatelessWidget {
  const _Chip({
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
          color: active
              ? AppColors.accent
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: active
                ? AppColors.accent
                : AppColors.border,
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
            color: active
                ? AppColors.textOnPrimary
                : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// An option card with staggered entrance animation and tap scale effect.
class _AnimatedOptionCard extends StatefulWidget {
  const _AnimatedOptionCard({
    required this.index,
    required this.controller,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final int index;
  final AnimationController controller;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_AnimatedOptionCard> createState() => _AnimatedOptionCardState();
}

class _AnimatedOptionCardState extends State<_AnimatedOptionCard> {
  bool _pressed = false;

  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    final begin = (widget.index * 0.15).clamp(0.0, 0.6);
    final end = (begin + 0.5).clamp(0.0, 1.0);

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: widget.controller,
        curve: Interval(begin, end, curve: Curves.easeOutCubic),
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: widget.controller,
        curve: Interval(begin, end, curve: Curves.easeOutCubic),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeInOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: _pressed
                      ? widget.color.withValues(alpha: 0.3)
                      : AppColors.border,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _pressed
                        ? widget.color.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.04),
                    blurRadius: _pressed ? 16 : 8,
                    offset: const Offset(0, 4),
                  ),
                  if (_pressed)
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.06),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            widget.color.withValues(alpha: 0.15),
                            widget.color.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(widget.icon, color: widget.color, size: 26),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: widget.color.withValues(alpha: 0.5),
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
