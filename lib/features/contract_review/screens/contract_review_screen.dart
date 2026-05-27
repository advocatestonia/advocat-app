// =============================================================================
// contract_review_screen.dart — Standalone Contract Review entry point.
// =============================================================================
//
// Why this exists
// ---------------
// Contract Review is Advocat's highest-value paid feature (€0.13/contract,
// quality 8.5/10). Until now it was reachable only through chat: the user
// had to upload a PDF and hope the bot would detect it as a contract via
// the classify-contract edge function (see contract_detected_chip.dart).
// That gave it a 2/10 discoverability score.
//
// This screen surfaces the same backend pipeline as a first-class Home tile.
// Both paths share:
//   * the same edge function:    supabase/functions/contract-review/index.ts
//   * the same quota service:    features/chat/services/contract_review_quota_service.dart
//   * the same upgrade dialog:   features/chat/widgets/contract_review_upgrade_dialog.dart
//
// We deliberately DO NOT touch the chat detection path — both work side by
// side. A user can:
//   (a) upload a PDF in chat → see contract_detected_chip → analyze, OR
//   (b) tap the Home tile → land here → upload + analyze in isolation.
//
// Flow
// ----
//   1. Render quota pill + AI disclaimer banner above an Upload button.
//   2. User picks a PDF/DOCX/TXT via file_picker; we upload it through
//      SupabaseService.uploadDocument (same path the chat composer uses)
//      to obtain a `case_document_id`.
//   3. Show shimmer skeleton while contract-review edge fn runs.
//   4. On 200, render: summary + red flags + review points + negotiation tips.
//   5. On 402 (quota_exceeded), open the existing upgrade dialog.
//   6. CTAs:
//        - "Save to Vault"      → vault-upload of the rendered PDF (when
//                                  pdf_url is present in the response).
//        - "Continue in chat"   → /chat/general with a system seed so the
//                                  AI summarises the just-completed review.
// =============================================================================

import 'dart:async';
import 'dart:convert' show jsonEncode;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../config/router.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/supabase_service.dart';
import '../../../shared/widgets/ai_disclaimer_banner.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../chat/services/contract_review_quota_service.dart';
import '../../chat/widgets/contract_review_quota_pill.dart';
import '../../chat/widgets/contract_review_upgrade_dialog.dart';

// ─── Stable test keys ────────────────────────────────────────────────────────

/// Stable widget keys so the test harness never needs to lean on copy
/// strings (which shift between locales). Each key is namespaced under
/// `contract_review_` to make grep-debugging trivial.
abstract final class ContractReviewScreenKeys {
  static const Key root = Key('contract_review_screen_root');
  static const Key uploadCta = Key('contract_review_screen_upload_cta');
  static const Key loadingState = Key('contract_review_screen_loading');
  static const Key resultRoot = Key('contract_review_screen_result_root');
  static const Key redFlagsSection =
      Key('contract_review_screen_red_flags');
  static const Key reviewPointsSection =
      Key('contract_review_screen_review_points');
  static const Key negotiationTipsSection =
      Key('contract_review_screen_negotiation_tips');
  static const Key saveToVaultCta =
      Key('contract_review_screen_save_to_vault');
  static const Key continueInChatCta =
      Key('contract_review_screen_continue_in_chat');
  static const Key quotaExceededHint =
      Key('contract_review_screen_quota_exceeded_hint');
}

// ─── Screen state ────────────────────────────────────────────────────────────

enum _ScreenPhase { idle, uploading, analyzing, result, error }

/// In-memory result snapshot. Mirrors the JSON returned by
/// `supabase/functions/contract-review/handler.ts` (success body shape) so
/// the screen never has to peek at handler internals; only the keys it
/// renders are captured here.
class ContractReviewResultView {
  const ContractReviewResultView({
    required this.summary,
    required this.score,
    required this.criticalRiskCount,
    required this.emailMd,
    required this.pdfUrl,
    required this.reviewId,
    required this.redFlags,
    required this.reviewPoints,
    required this.negotiationTips,
  });

  final String summary;
  final num score;
  final int criticalRiskCount;
  final String emailMd;
  final String? pdfUrl;
  final String reviewId;
  final List<String> redFlags;
  final List<String> reviewPoints;
  final List<String> negotiationTips;
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class ContractReviewScreen extends ConsumerStatefulWidget {
  const ContractReviewScreen({super.key});

  @override
  ConsumerState<ContractReviewScreen> createState() =>
      _ContractReviewScreenState();
}

class _ContractReviewScreenState extends ConsumerState<ContractReviewScreen> {
  _ScreenPhase _phase = _ScreenPhase.idle;
  String? _errorMessage;
  String? _uploadedFilename;
  ContractReviewResultView? _result;
  bool _savingToVault = false;

  /// Picks a PDF/DOCX/TXT file, uploads it via SupabaseService, then calls
  /// the contract-review edge function. Server-side handles quota: a 402
  /// response opens the upgrade dialog instead of rendering a result.
  Future<void> _pickAndAnalyze() async {
    final l10n = AppLocalizations.of(context);

    // 0. Quota pre-check — server still authoritative, but a client-side
    //    short-circuit on the exhausted state avoids spending an upload
    //    round-trip the server will only reject. The user gets the same
    //    upgrade dialog either way.
    final quotaAsync = ref.read(contractReviewQuotaProvider);
    final quota = quotaAsync.valueOrNull;
    if (quota != null && quota.isExhausted) {
      unawaited(_openUpgradeDialog(quota));
      return;
    }

    // 1. File picker.
    FilePickerResult? picked;
    try {
      picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'doc', 'docx', 'txt'],
        withData: true,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[contract-review] file_picker error: $e');
      if (!mounted) return;
      setState(() {
        _phase = _ScreenPhase.error;
        _errorMessage =
            l10n?.genericError ?? 'Something went wrong. Please try again.';
      });
      return;
    }
    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.first;
    if (file.bytes == null || file.name.isEmpty) return;

    setState(() {
      _phase = _ScreenPhase.uploading;
      _errorMessage = null;
      _result = null;
      _uploadedFilename = file.name;
    });

    final supabase = ref.read(supabaseServiceProvider);

    // 2. Upload file → case_documents row.
    String docId;
    try {
      final caseId =
          'contract-review-${DateTime.now().millisecondsSinceEpoch}';
      docId = await supabase.uploadDocument(
        caseId: caseId,
        fileName: file.name,
        fileBytes: file.bytes!,
        mimeType: _mimeFromExt(file.name),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[contract-review] upload error: $e');
      if (!mounted) return;
      setState(() {
        _phase = _ScreenPhase.error;
        _errorMessage =
            l10n?.genericError ?? 'Something went wrong. Please try again.';
      });
      return;
    }

    if (!mounted) return;
    setState(() => _phase = _ScreenPhase.analyzing);

    // 3. Call edge function.
    final locale = Localizations.localeOf(context).languageCode;
    final body = <String, dynamic>{
      'case_document_ids': [docId],
      'output_language': locale,
    };
    final resp = await supabase.callEdgeFunction('contract-review', body: body);
    if (!mounted) return;

    // 4. Map response.
    final error = resp?['error'];
    if (error == 'quota_exceeded') {
      setState(() {
        _phase = _ScreenPhase.idle;
        _errorMessage = null;
      });
      // Refresh quota so the pill flips to exhausted, then surface dialog.
      ref.invalidate(contractReviewQuotaProvider);
      final q = ref.read(contractReviewQuotaProvider).valueOrNull;
      if (q != null) unawaited(_openUpgradeDialog(q));
      return;
    }
    if (resp == null || error != null) {
      setState(() {
        _phase = _ScreenPhase.error;
        _errorMessage =
            error is String && error.isNotEmpty
                ? error
                : (l10n?.genericError ??
                    'Something went wrong. Please try again.');
      });
      return;
    }

    setState(() {
      _phase = _ScreenPhase.result;
      _result = _parseResult(resp);
    });
    // Refresh quota — server just incremented on success.
    ref.invalidate(contractReviewQuotaProvider);
  }

  /// Convert the edge-function success body into the trimmed view model.
  ///
  /// The server returns the full ContractReviewOutput JSON under `raw_output`
  /// only when an internal verifier runs. The success-body shape exposed to
  /// the client carries: summary, score, critical_risk_count, email_md,
  /// pdf_url, contract_review_id. We additionally try to parse a structured
  /// "red flags / review points / negotiation tips" list from the email_md
  /// (when present) so the result UI is richer than a single paragraph.
  ContractReviewResultView _parseResult(Map<String, dynamic> resp) {
    final emailMd = (resp['email_md'] as String?) ?? '';
    final redFlags = _extractSection(emailMd, _redFlagPatterns);
    final reviewPoints = _extractSection(emailMd, _reviewPointPatterns);
    final negotiationTips = _extractSection(emailMd, _negotiationPatterns);
    return ContractReviewResultView(
      summary: (resp['summary'] as String?) ?? '',
      score: (resp['score'] as num?) ?? 0,
      criticalRiskCount: (resp['critical_risk_count'] as num?)?.toInt() ?? 0,
      emailMd: emailMd,
      pdfUrl: resp['pdf_url'] as String?,
      reviewId: (resp['contract_review_id'] as String?) ?? '',
      redFlags: redFlags,
      reviewPoints: reviewPoints,
      negotiationTips: negotiationTips,
    );
  }

  /// Extract bulleted lines that appear under any heading whose text matches
  /// one of [patterns] (case-insensitive, multilingual). Returns an empty
  /// list when the section is missing — the UI hides empty sections.
  ///
  /// We accept either Markdown headings (`## Red flags`) or simple labels
  /// followed by a colon (`Red flags:`) since the planner emits both forms
  /// depending on the output language.
  static List<String> _extractSection(String md, List<RegExp> patterns) {
    if (md.isEmpty) return const [];
    final lines = md.split('\n');
    final results = <String>[];
    var inSection = false;
    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) {
        if (inSection && results.isNotEmpty) {
          // Blank line ends the section.
          break;
        }
        continue;
      }
      final isHeading = line.startsWith('#') ||
          (line.endsWith(':') && line.length < 80);
      if (isHeading) {
        if (inSection) break;
        inSection = patterns.any((p) => p.hasMatch(line));
        continue;
      }
      if (!inSection) continue;
      // Bullet or numbered list entry.
      final stripped = line
          .replaceFirst(RegExp(r'^[-*•]\s+'), '')
          .replaceFirst(RegExp(r'^\d+[.)]\s+'), '')
          .trim();
      if (stripped.isNotEmpty) results.add(stripped);
    }
    return results;
  }

  // Heading-recognition patterns. The planner emits English-locale output
  // when the user's locale matches, so the headings shift; we keep the
  // most common variants per supported language to avoid an empty list.
  static final List<RegExp> _redFlagPatterns = [
    RegExp(r'red.?flag', caseSensitive: false),
    RegExp(r'риск', caseSensitive: false),
    RegExp(r'ohu', caseSensitive: false),
    RegExp(r'risk', caseSensitive: false),
  ];
  static final List<RegExp> _reviewPointPatterns = [
    RegExp(r'review.?point', caseSensitive: false),
    RegExp(r'пункт', caseSensitive: false),
    RegExp(r'\bkohti\b', caseSensitive: false),
    RegExp(r'punkti', caseSensitive: false),
    RegExp(r'key.?point', caseSensitive: false),
  ];
  static final List<RegExp> _negotiationPatterns = [
    RegExp(r'negotiat', caseSensitive: false),
    RegExp(r'перегов', caseSensitive: false),
    RegExp(r'läbiräägi', caseSensitive: false),
    RegExp(r'neuvotte', caseSensitive: false),
  ];

  Future<void> _openUpgradeDialog(ContractReviewQuota quota) async {
    final choice =
        await showContractReviewUpgradeDialog(context, quota: quota);
    if (choice == null || !mounted) return;
    unawaited(context.push(AppRoutes.subscription));
  }

  /// Hand off to the standard chat flow with a system seed so the assistant
  /// can pick up where the standalone review left off.
  Future<void> _continueInChat() async {
    final r = _result;
    if (r == null) return;
    // Persist a small handoff payload that ChatScreen can read on mount —
    // we deliberately avoid changing chat_screen.dart routing here. The
    // ChatScreen already supports a system seed via _sendMessage; using
    // SharedPreferences as a one-shot cache keeps this screen decoupled.
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'contract_review_handoff_v1',
        jsonEncode({
          'contract_review_id': r.reviewId,
          'summary': r.summary,
          'score': r.score,
          'critical_risk_count': r.criticalRiskCount,
          'filename': _uploadedFilename,
        }),
      );
    } catch (_) {
      // Non-fatal — chat will still load, just without the seed.
    }
    if (!mounted) return;
    unawaited(context.push('/chat/general'));
  }

  /// Save the rendered PDF to the Vault via the vault-upload edge function.
  /// Falls back to a no-op + SnackBar when the server didn't render a PDF.
  Future<void> _saveToVault() async {
    final l10n = AppLocalizations.of(context);
    final r = _result;
    if (r == null) return;
    if (r.pdfUrl == null || r.pdfUrl!.isEmpty) {
      // No PDF was rendered server-side (worker_not_configured or pending).
      // Tell the user the email body is still copy-able and skip the call.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.genericError ??
                'Contract review PDF is not ready yet. Try again shortly.',
          ),
        ),
      );
      return;
    }
    setState(() => _savingToVault = true);
    try {
      final supabase = ref.read(supabaseServiceProvider);
      // vault-upload expects a previously-stored object reference — we hand
      // it the contract_review_id so the server can resolve the canonical
      // storage path. The endpoint is permissive: any unrecognised key is
      // ignored and the source_url is the load-bearing input.
      await supabase.callEdgeFunction(
        'vault-upload',
        body: {
          'source': 'contract_review',
          'contract_review_id': r.reviewId,
          'source_url': r.pdfUrl,
          'filename': _uploadedFilename ?? 'contract-review.pdf',
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.contractReviewSaveToVault == null
                ? 'Saved to Vault'
                : '${l10n!.contractReviewSaveToVault} ✓',
          ),
        ),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[contract-review] save to vault error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.genericError ?? 'Something went wrong. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _savingToVault = false);
    }
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
    final quotaAsync = ref.watch(contractReviewQuotaProvider);

    return Scaffold(
      key: ContractReviewScreenKeys.root,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n?.contractReviewTitle ?? 'Contract Review',
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
            // EU AI Act Art. 50 transparency surface — non-dismissable inline
            // chip, identical to the one used in the chat composer.
            const AiDisclaimerBanner.compact(
              key: Key('contract_review_screen_ai_disclaimer'),
            ),
            const SizedBox(height: AppSpacing.md),

            // Quota pill — visual only. Server is authoritative.
            quotaAsync.when(
              data: (q) => Align(
                alignment: AlignmentDirectional.centerStart,
                child: ContractReviewQuotaPill(
                  quota: q,
                  onUpgrade: () => unawaited(_openUpgradeDialog(q)),
                ),
              ),
              loading: () => const SizedBox(height: 28),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSpacing.md),

            if (_phase == _ScreenPhase.idle ||
                _phase == _ScreenPhase.error)
              _IdleBlock(
                onUpload: _pickAndAnalyze,
                errorMessage: _errorMessage,
                quotaAsync: quotaAsync,
              ),

            if (_phase == _ScreenPhase.uploading ||
                _phase == _ScreenPhase.analyzing)
              const Padding(
                key: ContractReviewScreenKeys.loadingState,
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: GenericListSkeleton(itemCount: 6, itemHeight: 22),
              ),

            if (_phase == _ScreenPhase.result && _result != null)
              _ResultBlock(
                result: _result!,
                savingToVault: _savingToVault,
                onSaveToVault: _saveToVault,
                onContinueInChat: _continueInChat,
              ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

// ─── Idle block (upload CTA + optional error) ────────────────────────────────

class _IdleBlock extends StatelessWidget {
  const _IdleBlock({
    required this.onUpload,
    required this.errorMessage,
    required this.quotaAsync,
  });

  final VoidCallback onUpload;
  final String? errorMessage;
  final AsyncValue<ContractReviewQuota> quotaAsync;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final exhausted = quotaAsync.valueOrNull?.isExhausted ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.error, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    errorMessage!,
                    style:
                        const TextStyle(color: AppColors.error, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.description_outlined,
                size: 36,
                color: AppColors.accent,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n?.contractReviewTitle ?? 'Contract Review',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n?.contractReviewQuotaRemaining ??
                    'Upload a contract (PDF, DOC, DOCX, or TXT) for an AI '
                        'review with red flags and negotiation tips.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  key: ContractReviewScreenKeys.uploadCta,
                  onPressed: onUpload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  icon: const Icon(Icons.upload_file_outlined, size: 20),
                  label: Text(
                    l10n?.contractReviewUploadCta ?? 'Upload contract',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (exhausted) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n?.contractReviewQuotaRemaining ??
                      'You have used all available reviews this month. '
                          'Upgrade for more.',
                  key: ContractReviewScreenKeys.quotaExceededHint,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Result block ────────────────────────────────────────────────────────────

class _ResultBlock extends StatelessWidget {
  const _ResultBlock({
    required this.result,
    required this.savingToVault,
    required this.onSaveToVault,
    required this.onContinueInChat,
  });

  final ContractReviewResultView result;
  final bool savingToVault;
  final VoidCallback onSaveToVault;
  final VoidCallback onContinueInChat;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      key: ContractReviewScreenKeys.resultRoot,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary
          if (result.summary.isNotEmpty) ...[
            Text(
              result.summary,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          // Score + critical risk chips
          Row(
            children: [
              _ScoreChip(score: result.score),
              const SizedBox(width: AppSpacing.sm),
              if (result.criticalRiskCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    '${result.criticalRiskCount} critical',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                ),
            ],
          ),

          // Red flags
          if (result.redFlags.isNotEmpty)
            _Section(
              key: ContractReviewScreenKeys.redFlagsSection,
              title: l10n?.contractReviewRedFlags ?? 'Red flags',
              icon: Icons.warning_amber_rounded,
              color: AppColors.error,
              items: result.redFlags,
            ),

          // Review points
          if (result.reviewPoints.isNotEmpty)
            _Section(
              key: ContractReviewScreenKeys.reviewPointsSection,
              title: l10n?.contractReviewReviewPoints ?? 'Review points',
              icon: Icons.fact_check_outlined,
              color: AppColors.accent,
              items: result.reviewPoints,
            ),

          // Negotiation tips
          if (result.negotiationTips.isNotEmpty)
            _Section(
              key: ContractReviewScreenKeys.negotiationTipsSection,
              title: l10n?.contractReviewNegotiationTips ??
                  'Negotiation tips',
              icon: Icons.lightbulb_outline_rounded,
              color: AppColors.warning,
              items: result.negotiationTips,
            ),

          const SizedBox(height: AppSpacing.lg),

          // Save to Vault CTA
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              key: ContractReviewScreenKeys.saveToVaultCta,
              onPressed: savingToVault ? null : onSaveToVault,
              icon: savingToVault
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.lock_outline, size: 18),
              label: Text(
                l10n?.contractReviewSaveToVault ?? 'Save to Vault',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Continue in chat CTA
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              key: ContractReviewScreenKeys.continueInChatCta,
              onPressed: onContinueInChat,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
              label: Text(
                l10n?.contractReviewContinueChat ?? 'Continue in chat',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section list ────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...items.map(
            (it) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  ',
                      style: TextStyle(color: AppColors.textSecondary)),
                  Expanded(
                    child: Text(
                      it,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({required this.score});
  final num score;

  Color _bg() {
    if (score >= 75) return AppColors.success.withValues(alpha: 0.12);
    if (score >= 50) return AppColors.warning.withValues(alpha: 0.12);
    return AppColors.error.withValues(alpha: 0.12);
  }

  Color _fg() {
    if (score >= 75) return AppColors.success;
    if (score >= 50) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bg(),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        'Score ${score.toStringAsFixed(0)}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: _fg(),
        ),
      ),
    );
  }
}
