// =============================================================================
// contract_compare_screen.dart — Contract Version Compare entry point.
// =============================================================================
//
// Why this exists
// ---------------
// A reviewer (especially a B2B lawyer) receives a NEW redline of a contract
// they already saw — a fresh lease / employment / services edition — and
// cannot tell WHAT changed or whether the delta is dangerous. contract-review
// analyses ONE contract; this screen diffs v1 vs v2 and highlights the risk
// delta clause-by-clause.
//
// It sits alongside (never replaces) ContractReviewScreen. Reached via a
// dedicated route /contract-compare and a Home / Contract Review tile.
//
// Flow
// ----
//   1. User uploads TWO versions (old + new) — PDF/DOC/DOCX/TXT each. We
//      upload both through SupabaseService.uploadDocument (the same path the
//      chat composer + contract-review screen use) to obtain two
//      `case_document_id`s.
//   2. Call the contract-compare edge function with both document ids.
//   3. Render a structured, colour-coded change list (favorable / adverse /
//      neutral) using ContractChangeCard, with a headline risk summary.
//
// We deliberately keep this screen self-contained (no chat / hot-path edits)
// and reuse the existing AI-disclaimer banner + skeleton loader.
// =============================================================================

import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/supabase_service.dart';
import '../../../shared/widgets/ai_disclaimer_banner.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../widgets/contract_change_card.dart';

// ─── Stable test keys ────────────────────────────────────────────────────────

abstract final class ContractCompareScreenKeys {
  static const Key root = Key('contract_compare_screen_root');
  static const Key pickOldCta = Key('contract_compare_pick_old');
  static const Key pickNewCta = Key('contract_compare_pick_new');
  static const Key compareCta = Key('contract_compare_run');
  static const Key loadingState = Key('contract_compare_loading');
  static const Key resultRoot = Key('contract_compare_result_root');
  static const Key summaryCard = Key('contract_compare_summary');
  static const Key changesList = Key('contract_compare_changes');
  static const Key emptyState = Key('contract_compare_empty');
}

// ─── Result view model ───────────────────────────────────────────────────────

/// Trimmed snapshot of the contract-compare edge-function success body.
class ContractCompareResultView {
  const ContractCompareResultView({
    required this.summary,
    required this.overallDirection,
    required this.adverseCount,
    required this.favorableCount,
    required this.truncated,
    required this.changes,
  });

  final String summary;
  final ContractChangeDirection overallDirection;
  final int adverseCount;
  final int favorableCount;
  final bool truncated;
  final List<ContractChangeView> changes;

  /// Parse the edge-function JSON body into the view model.
  factory ContractCompareResultView.fromJson(Map<String, dynamic> json) {
    final rawChanges = json['changes'];
    final changes = <ContractChangeView>[];
    if (rawChanges is List) {
      for (final c in rawChanges) {
        if (c is Map<String, dynamic>) {
          changes.add(ContractChangeView.fromJson(c));
        }
      }
    }
    return ContractCompareResultView(
      summary: (json['summary'] as String?)?.trim() ?? '',
      overallDirection: ContractChangeView.directionFromString(
        json['overall_direction'] as String?,
      ),
      adverseCount: (json['adverse_count'] as num?)?.toInt() ?? 0,
      favorableCount: (json['favorable_count'] as num?)?.toInt() ?? 0,
      truncated: json['truncated'] == true,
      changes: changes,
    );
  }
}

// ─── Screen ──────────────────────────────────────────────────────────────────

enum _Phase { idle, uploading, comparing, result, error }

class ContractCompareScreen extends ConsumerStatefulWidget {
  const ContractCompareScreen({super.key});

  @override
  ConsumerState<ContractCompareScreen> createState() =>
      _ContractCompareScreenState();
}

class _ContractCompareScreenState
    extends ConsumerState<ContractCompareScreen> {
  _Phase _phase = _Phase.idle;
  String? _errorMessage;

  PlatformFile? _oldFile;
  PlatformFile? _newFile;
  ContractCompareResultView? _result;

  Future<void> _pick({required bool isOld}) async {
    final l10n = AppLocalizations.of(context);
    FilePickerResult? picked;
    try {
      picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'doc', 'docx', 'txt'],
        withData: true,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[contract-compare] picker error: $e');
      if (!mounted) return;
      setState(() {
        _phase = _Phase.error;
        _errorMessage =
            l10n?.genericError ?? 'Something went wrong. Please try again.';
      });
      return;
    }
    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.first;
    if (file.bytes == null || file.name.isEmpty) return;
    setState(() {
      _errorMessage = null;
      _phase = _Phase.idle;
      if (isOld) {
        _oldFile = file;
      } else {
        _newFile = file;
      }
    });
  }

  Future<void> _compare() async {
    final l10n = AppLocalizations.of(context);
    final oldFile = _oldFile;
    final newFile = _newFile;
    if (oldFile == null || newFile == null) return;

    setState(() {
      _phase = _Phase.uploading;
      _errorMessage = null;
      _result = null;
    });

    final supabase = ref.read(supabaseServiceProvider);

    String oldDocId;
    String newDocId;
    try {
      final stamp = DateTime.now().millisecondsSinceEpoch;
      oldDocId = await supabase.uploadDocument(
        caseId: 'contract-compare-old-$stamp',
        fileName: oldFile.name,
        fileBytes: oldFile.bytes!,
        mimeType: _mimeFromExt(oldFile.name),
      );
      newDocId = await supabase.uploadDocument(
        caseId: 'contract-compare-new-$stamp',
        fileName: newFile.name,
        fileBytes: newFile.bytes!,
        mimeType: _mimeFromExt(newFile.name),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[contract-compare] upload error: $e');
      if (!mounted) return;
      setState(() {
        _phase = _Phase.error;
        _errorMessage =
            l10n?.genericError ?? 'Something went wrong. Please try again.';
      });
      return;
    }

    if (!mounted) return;
    setState(() => _phase = _Phase.comparing);

    final locale = Localizations.localeOf(context).languageCode;
    Map<String, dynamic>? resp;
    try {
      resp = await supabase.callEdgeFunction(
        'contract-compare',
        body: <String, dynamic>{
          'old_document_id': oldDocId,
          'new_document_id': newDocId,
          'output_language': locale,
        },
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[contract-compare] compare error: $e');
      if (!mounted) return;
      setState(() {
        _phase = _Phase.error;
        _errorMessage =
            l10n?.genericError ?? 'Something went wrong. Please try again.';
      });
      return;
    }
    if (!mounted) return;

    final error = resp?['error'];
    if (resp == null || error != null) {
      setState(() {
        _phase = _Phase.error;
        _errorMessage = error is String && error.isNotEmpty
            ? error
            : (l10n?.genericError ??
                'Something went wrong. Please try again.');
      });
      return;
    }

    setState(() {
      _phase = _Phase.result;
      _result = ContractCompareResultView.fromJson(resp!);
    });
  }

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
      default:
        return 'application/octet-stream';
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final busy = _phase == _Phase.uploading || _phase == _Phase.comparing;
    final canCompare = _oldFile != null && _newFile != null && !busy;

    return Scaffold(
      key: ContractCompareScreenKeys.root,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n?.contractCompareTitle ?? 'Compare versions',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const AiDisclaimerBanner.compact(
              key: Key('contract_compare_ai_disclaimer'),
            ),
            const SizedBox(height: AppSpacing.md),

            Text(
              l10n?.contractCompareIntro ??
                  'Upload two versions of the same contract. We highlight what '
                      'changed and whether each change helps or hurts you.',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            if (_errorMessage != null) ...[
              _ErrorBox(message: _errorMessage!),
              const SizedBox(height: AppSpacing.md),
            ],

            // Two upload slots.
            _UploadSlot(
              key: ContractCompareScreenKeys.pickOldCta,
              label: l10n?.contractCompareOldVersion ?? 'Old version (v1)',
              file: _oldFile,
              enabled: !busy,
              onTap: () => _pick(isOld: true),
            ),
            const SizedBox(height: AppSpacing.sm),
            _UploadSlot(
              key: ContractCompareScreenKeys.pickNewCta,
              label: l10n?.contractCompareNewVersion ?? 'New version (v2)',
              file: _newFile,
              enabled: !busy,
              onTap: () => _pick(isOld: false),
            ),
            const SizedBox(height: AppSpacing.md),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                key: ContractCompareScreenKeys.compareCta,
                onPressed: canCompare ? _compare : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                icon: const Icon(Icons.compare_arrows_rounded, size: 20),
                label: Text(
                  l10n?.contractCompareCta ?? 'Compare versions',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            if (busy)
              const Padding(
                key: ContractCompareScreenKeys.loadingState,
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: GenericListSkeleton(itemCount: 5, itemHeight: 26),
              ),

            if (_phase == _Phase.result && _result != null)
              _ResultBlock(result: _result!),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

// ─── Upload slot ─────────────────────────────────────────────────────────────

class _UploadSlot extends StatelessWidget {
  const _UploadSlot({
    super.key,
    required this.label,
    required this.file,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final PlatformFile? file;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final picked = file != null;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: picked ? AppColors.accent : AppColors.border,
            width: picked ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              picked
                  ? Icons.check_circle_rounded
                  : Icons.upload_file_outlined,
              size: 22,
              color: picked ? AppColors.accent : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (picked) ...[
                    const SizedBox(height: 2),
                    Text(
                      file!.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.error, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Result block ────────────────────────────────────────────────────────────

class _ResultBlock extends StatelessWidget {
  const _ResultBlock({required this.result});
  final ContractCompareResultView result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      key: ContractCompareScreenKeys.resultRoot,
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary card with delta counts.
          Container(
            key: ContractCompareScreenKeys.summaryCard,
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _CountChip(
                      count: result.adverseCount,
                      label: l10n?.contractCompareAdverse ?? 'Adverse',
                      color: AppColors.error,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _CountChip(
                      count: result.favorableCount,
                      label: l10n?.contractCompareFavorable ?? 'Favorable',
                      color: AppColors.success,
                    ),
                  ],
                ),
                if (result.summary.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    result.summary,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ],
                if (result.truncated) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n?.contractCompareTruncated ??
                        'Long contract — only the first part of each version '
                            'was compared.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          if (result.changes.isEmpty)
            Container(
              key: ContractCompareScreenKeys.emptyState,
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              alignment: Alignment.center,
              child: Text(
                l10n?.contractCompareNoChanges ??
                    'No material changes detected between the two versions.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            Column(
              key: ContractCompareScreenKeys.changesList,
              children: [
                for (final change in result.changes)
                  ContractChangeCard(
                    change: change,
                    favorableLabel:
                        l10n?.contractCompareFavorable ?? 'Favorable',
                    adverseLabel: l10n?.contractCompareAdverse ?? 'Adverse',
                    neutralLabel: l10n?.contractCompareNeutral ?? 'Neutral',
                    beforeLabel: l10n?.contractCompareBefore ?? 'Before',
                    afterLabel: l10n?.contractCompareAfter ?? 'After',
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.count,
    required this.label,
    required this.color,
  });

  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
