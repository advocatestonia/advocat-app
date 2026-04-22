// Refund consent modal — EU CRD Art. 16(m) digital-content waiver.
// -----------------------------------------------------------------------------
// Shown exactly once per paid subscription, before the user's first AI
// response. Collects an explicit checkbox-based waiver and posts it to the
// log-refund-consent Edge Function. The audit row is what lets us refuse a
// refund after the 7th response without violating the Consumer Rights
// Directive.
//
// Usage:
//
//   final accepted = await showRefundConsentModal(context);
//   if (accepted != true) {
//     // User dismissed — block the AI send.
//     return;
//   }
//
// The caller is responsible for calling the modal only once (tracked via
// refund_consents table server-side + a local SharedPreferences flag to
// avoid round-tripping every session).
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';

final _log = Logger(
  printer: PrettyPrinter(methodCount: 0),
  level: kDebugMode ? Level.debug : Level.off,
);

/// Shows the refund-consent modal. Returns `true` when the user ticks the
/// checkbox and presses "Begin"; `false` (or `null`) if they dismiss.
///
/// On acceptance, the modal POSTs to the `log-refund-consent` Edge Function
/// to create the audit row. A failed POST does NOT block the user — they
/// still proceed, and the event is logged client-side. The server can
/// reconcile later by looking at the first message timestamp.
Future<bool?> showRefundConsentModal(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const RefundConsentModal(),
  );
}

/// Visible widget — exposed so widget tests can pump it directly without
/// going through `showDialog`.
class RefundConsentModal extends StatefulWidget {
  const RefundConsentModal({super.key, this.onLogConsent});

  /// Optional override for the network call. Used by tests to avoid hitting
  /// a live Supabase Edge Function. Receives no arguments; should return
  /// `true` on success, `false` on failure.
  final Future<bool> Function()? onLogConsent;

  @override
  State<RefundConsentModal> createState() => _RefundConsentModalState();
}

class _RefundConsentModalState extends State<RefundConsentModal> {
  bool _accepted = false;
  bool _submitting = false;

  Future<bool> _defaultLogConsent() async {
    try {
      final res = await Supabase.instance.client.functions.invoke(
        'log-refund-consent',
        body: const {},
      );
      if (res.status >= 200 && res.status < 300) {
        return true;
      }
      _log.w('log-refund-consent responded with status ${res.status}');
      return false;
    } catch (e) {
      _log.w('log-refund-consent call failed: $e');
      return false;
    }
  }

  Future<void> _onBeginPressed() async {
    if (!_accepted || _submitting) return;
    setState(() => _submitting = true);

    final logger = widget.onLogConsent ?? _defaultLogConsent;
    final ok = await logger();
    if (!ok) {
      // We still let the user proceed — the waiver record is useful but
      // not a hard blocker (Supabase can reconcile from first_message_at).
      _log.i('Refund consent POST failed, proceeding anyway.');
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = l10n?.consentModalTitle ?? 'Before you begin';
    final body = l10n?.consentModalBody ??
        'You can request a refund within 14 days of subscribing, or up to '
            'your 7th AI response — whichever comes first. After the 7th '
            'answer, the 14-day right expires (EU CRD Art. 16m — digital '
            'content waiver).';
    final checkboxLabel = l10n?.consentModalCheckbox ??
        'I understand and agree to begin using the service';
    final buttonLabel = l10n?.consentModalButton ?? 'Begin';

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      title: Row(
        children: [
          const Icon(Icons.gavel_outlined, color: AppColors.accent),
          const SizedBox(width: 8),
          Flexible(child: Text(title)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              body,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _submitting
                  ? null
                  : () => setState(() => _accepted = !_accepted),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _accepted,
                    onChanged: _submitting
                        ? null
                        : (v) => setState(() => _accepted = v ?? false),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Text(
                        checkboxLabel,
                        style: const TextStyle(fontSize: 14, height: 1.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed:
              _accepted && !_submitting ? _onBeginPressed : null,
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(buttonLabel),
        ),
      ],
    );
  }
}
