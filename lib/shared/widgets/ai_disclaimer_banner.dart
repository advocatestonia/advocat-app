// AI legal-information disclaimer surface — addresses EU AI Act Art. 50(1)
// transparency obligation and member-state attorney-monopoly laws
// (EE Advokatuuriseadus §47, FI Asianajajalaki §5).
//
// Two variants:
//   * [AiDisclaimerBanner.compact] — inline 1-line chip that lives below
//     the primary surface (composer, result card, calculator outcome).
//     Tappable: opens a sheet with the full legal text. No dismiss control.
//   * [AiDisclaimerBanner.modal] — one-shot onboarding modal. Once dismissed,
//     persists under a separate key.
//
// Compact dismissal lives in `shared_preferences` under
// [_compactDismissedAtKey] as an ISO-8601 timestamp; the chip re-appears
// after 7 days so users see the reminder on a rolling cadence.
//
// Both keys carry a `_v1` suffix so future copy revisions can re-show by
// rotating the suffix.

import 'dart:async' show unawaited;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// SharedPreferences keys (versioned)
// ---------------------------------------------------------------------------

/// Timestamp (ISO-8601) of the last compact-banner dismissal.
/// When unset OR older than 7 days, the compact banner re-shows.
@visibleForTesting
const String kAiDisclaimerCompactDismissedAtKey =
    'ai_disclaimer_dismissed_v1';

/// Boolean: has the user seen the one-shot onboarding modal at least once.
@visibleForTesting
const String kAiDisclaimerModalSeenKey =
    'ai_disclaimer_modal_seen_v1';

/// Re-show window for the compact banner after dismissal.
@visibleForTesting
const Duration kAiDisclaimerCompactReshowAfter = Duration(days: 7);

// ---------------------------------------------------------------------------
// Public widget
// ---------------------------------------------------------------------------

/// Persistent "AI, not a lawyer" surface.
///
/// Use [AiDisclaimerBanner.compact] inline below high-risk surfaces (chat
/// composer, calculator verdict, contract findings list). Use
/// [AiDisclaimerBanner.modal] once during first-launch onboarding.
class AiDisclaimerBanner extends StatefulWidget {
  /// Compact, 1-line, sticky chip. No dismiss control — tap to expand.
  const AiDisclaimerBanner.compact({super.key})
      : _variant = _Variant.compact;

  /// Full-screen modal (used during onboarding). Shown once per device
  /// per `_v1` epoch.
  const AiDisclaimerBanner.modal({super.key}) : _variant = _Variant.modal;

  final _Variant _variant;

  // -------------------------------------------------------------------------
  // Static helpers for persistence
  // -------------------------------------------------------------------------

  /// Returns true if the compact banner should be displayed right now,
  /// i.e. it has never been dismissed OR the last dismissal is older than
  /// [kAiDisclaimerCompactReshowAfter].
  static Future<bool> shouldShowCompact() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(kAiDisclaimerCompactDismissedAtKey);
      if (raw == null || raw.isEmpty) return true;
      final dismissedAt = DateTime.tryParse(raw);
      if (dismissedAt == null) return true;
      return DateTime.now().difference(dismissedAt) >=
          kAiDisclaimerCompactReshowAfter;
    } catch (_) {
      // Fail-open: on storage error, show the disclaimer (safer for
      // compliance — never hide it because we couldn't read prefs).
      return true;
    }
  }

  /// Records a compact-banner dismissal at "now".
  static Future<void> markCompactDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      kAiDisclaimerCompactDismissedAtKey,
      DateTime.now().toIso8601String(),
    );
  }

  /// Returns true if the user has NOT yet seen the modal.
  static Future<bool> shouldShowModal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return !(prefs.getBool(kAiDisclaimerModalSeenKey) ?? false);
    } catch (_) {
      // Fail-open: show modal on read error.
      return true;
    }
  }

  /// Records the modal as seen.
  static Future<void> markModalSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kAiDisclaimerModalSeenKey, true);
  }

  @override
  State<AiDisclaimerBanner> createState() => _AiDisclaimerBannerState();
}

enum _Variant { compact, modal }

class _AiDisclaimerBannerState extends State<AiDisclaimerBanner> {
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    if (widget._variant == _Variant.compact) {
      _resolveVisibility();
    }
  }

  Future<void> _resolveVisibility() async {
    final show = await AiDisclaimerBanner.shouldShowCompact();
    if (!mounted) return;
    if (show != _visible) {
      setState(() => _visible = show);
    }
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (widget._variant == _Variant.modal) {
      return _buildModal(context);
    }
    if (!_visible) return const SizedBox.shrink();
    return _buildCompact(context);
  }

  // -------------------------------------------------------------------------
  // Compact chip
  // -------------------------------------------------------------------------

  Widget _buildCompact(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = l10n?.aiDisclaimerCompact ??
        'Advocat is AI legal information, not legal advice. '
            'Verify with a licensed lawyer before acting.';
    final learnMore = l10n?.aiDisclaimerExpand ?? 'Learn more';

    return Semantics(
      container: true,
      liveRegion: false,
      label: text,
      button: true,
      child: InkWell(
        key: const Key('ai_disclaimer_compact_root'),
        onTap: () => _openExpansionSheet(context),
        child: Container(
          constraints: const BoxConstraints(minHeight: 36, maxHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.warningBg,
            border: Border.all(
              color: AppColors.warning.withValues(alpha: 0.18),
            ),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.info_outline,
                size: 16,
                color: AppColors.warning,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.warning,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                learnMore,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Modal
  // -------------------------------------------------------------------------

  Widget _buildModal(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = l10n?.aiDisclaimerFullTitle ??
        'Important: how Advocat works';
    final body = l10n?.aiDisclaimerFullBody ?? _fallbackFullBody;
    final dismiss = l10n?.aiDisclaimerDismiss ?? 'OK, I understand';

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.info_outline,
              color: AppColors.warning,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          body,
          style: const TextStyle(
            fontSize: 13,
            height: 1.45,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );

    Future<void> onDismiss() async {
      await AiDisclaimerBanner.markModalSeen();
      if (!context.mounted) return;
      await Navigator.of(context).maybePop();
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return CupertinoAlertDialog(
        title: Text(title),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(body),
        ),
        actions: [
          CupertinoDialogAction(
            key: const Key('ai_disclaimer_modal_dismiss'),
            isDefaultAction: true,
            onPressed: onDismiss,
            child: Text(dismiss),
          ),
        ],
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            content,
            const SizedBox(height: AppSpacing.lg),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const Key('ai_disclaimer_modal_dismiss'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent,
                ),
                onPressed: onDismiss,
                child: Text(
                  dismiss,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Expansion sheet (compact -> full text)
  // -------------------------------------------------------------------------

  Future<void> _openExpansionSheet(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final title = l10n?.aiDisclaimerFullTitle ??
        'Important: how Advocat works';
    final body = l10n?.aiDisclaimerFullBody ?? _fallbackFullBody;
    final close = MaterialLocalizations.of(context).closeButtonLabel;

    final isIos = defaultTargetPlatform == TargetPlatform.iOS;

    if (isIos) {
      await showCupertinoModalPopup<void>(
        context: context,
        builder: (ctx) => CupertinoActionSheet(
          title: Text(title),
          message: Text(body, textAlign: TextAlign.start),
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(close),
          ),
        ),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.warning,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                body,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  key: const Key('ai_disclaimer_sheet_dismiss'),
                  onPressed: () async {
                    await AiDisclaimerBanner.markCompactDismissed();
                    if (!ctx.mounted) return;
                    Navigator.of(ctx).pop();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.accent,
                  ),
                  child: Text(
                    l10n?.aiDisclaimerDismiss ?? 'OK, I understand',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Refresh visibility after sheet closes (in case dismiss button was tapped).
    if (mounted) {
      // Intentional fire-and-forget — caller does not need to await; the
      // setState inside _resolveVisibility handles the UI update.
      unawaited(_resolveVisibility());
    }
  }
}

// ---------------------------------------------------------------------------
// English-only fallback for missing ARB entries (defensive, should never fire
// once gen-l10n runs and all 17 locales have at least the keys present).
// ---------------------------------------------------------------------------

const String _fallbackFullBody =
    'Advocat is an artificial-intelligence tool that provides legal '
    'information, not legal advice. Under the EU AI Act (Art. 50), we must '
    'tell you clearly: you are interacting with AI, not a human lawyer.\n\n'
    'Advocat is not a law firm. We are not licensed advocates under the '
    'Estonian Advokatuuriseadus or the Finnish Asianajajalaki, and '
    'attorney-client privilege does not attach to your conversations with '
    'this tool. Before relying on any output — to file an appeal, sign a '
    'contract, or act on a deadline — verify with a licensed lawyer in '
    'your jurisdiction.';
