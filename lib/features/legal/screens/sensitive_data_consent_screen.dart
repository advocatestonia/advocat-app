// =====================================================================
// GDPR Art. 9(2)(a) — explicit consent dialog for special-category data.
//
// Shown the FIRST time a user triggers an upload (document scan, vault
// add, intake wizard step 5). Two mandatory checkboxes:
//   1. Explicit consent to process special-category data.
//   2. Right-to-share confirmation (data is mine OR I have lawful basis
//      to share third-party data).
// Both must be ticked before "Accept and continue" enables.
//
// A "View what counts as sensitive →" inline link opens a secondary
// modal listing the eight Art. 9 categories with concrete examples
// drawn from real Advocat use-cases (court rulings, medical certs,
// criminal records, police reports).
//
// The dialog itself is purely UI — persistence + fast-path is owned by
// `sensitive_consent_gate.dart`. The dialog returns `true` on accept,
// `false` on cancel / barrier dismiss.
// =====================================================================

import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';

/// The clickwrap consent dialog. Returns `true` when both checkboxes are
/// ticked and the user presses "Accept and continue".
class SensitiveDataConsentDialog extends StatefulWidget {
  const SensitiveDataConsentDialog({super.key});

  @override
  State<SensitiveDataConsentDialog> createState() =>
      _SensitiveDataConsentDialogState();
}

class _SensitiveDataConsentDialogState
    extends State<SensitiveDataConsentDialog> {
  bool _explicitConsent = false;
  bool _rightToShare = false;

  bool get _canAccept => _explicitConsent && _rightToShare;

  Future<void> _showCategoriesInfo() async {
    final l = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          title: Text(
            l.sensitiveConsentViewCategories,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CategoryRow(
                    title: 'Health data',
                    examples:
                        'Medical certificates, psychiatric epicrises, hospital records, F43 diagnoses.',
                  ),
                  _CategoryRow(
                    title: 'Criminal-conviction data',
                    examples:
                        'Court rulings, police reports, criminal-register extracts, deportation decisions.',
                  ),
                  _CategoryRow(
                    title: 'Biometric data',
                    examples:
                        'Fingerprint records, facial-recognition templates, passport-photo extracts.',
                  ),
                  _CategoryRow(
                    title: 'Racial or ethnic origin',
                    examples:
                        'Documents stating nationality, ethnic background or citizenship history.',
                  ),
                  _CategoryRow(
                    title: 'Religious or philosophical beliefs',
                    examples:
                        'Asylum statements citing religious persecution, faith-based exemption letters.',
                  ),
                  _CategoryRow(
                    title: 'Political opinions',
                    examples:
                        'Documents about party membership, political-asylum claims, dissident letters.',
                  ),
                  _CategoryRow(
                    title: 'Trade-union membership',
                    examples:
                        'Union cards, collective-bargaining grievances, labour-dispute filings.',
                  ),
                  _CategoryRow(
                    title: 'Sex life or sexual orientation',
                    examples:
                        'LGBTQ+ asylum claims, family-law filings touching on orientation.',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                MaterialLocalizations.of(ctx).closeButtonLabel,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      title: Text(
        l.sensitiveConsentTitle,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.sensitiveConsentBody,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // "View what counts as sensitive →" affordance.
              InkWell(
                onTap: _showCategoriesInfo,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l.sensitiveConsentViewCategories,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward,
                        size: 14,
                        color: AppColors.accent,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Checkbox 1 — explicit consent.
              _ConsentCheckbox(
                value: _explicitConsent,
                onChanged: (v) => setState(() => _explicitConsent = v ?? false),
                label: l.sensitiveConsentExplicitCheckbox,
                semanticKey: 'sensitive-consent-explicit-checkbox',
              ),

              // Checkbox 2 — right to share.
              _ConsentCheckbox(
                value: _rightToShare,
                onChanged: (v) => setState(() => _rightToShare = v ?? false),
                label: l.sensitiveConsentRightToShareCheckbox,
                semanticKey: 'sensitive-consent-right-to-share-checkbox',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('sensitive-consent-cancel-btn'),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            MaterialLocalizations.of(context).cancelButtonLabel,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          key: const Key('sensitive-consent-accept-btn'),
          onPressed: _canAccept
              ? () => Navigator.of(context).pop(true)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.3),
            disabledForegroundColor: Colors.white70,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
          child: const Text(
            'Accept and continue',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ConsentCheckbox extends StatelessWidget {
  const _ConsentCheckbox({
    required this.value,
    required this.onChanged,
    required this.label,
    required this.semanticKey,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;
  final String label;
  final String semanticKey;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: Key(semanticKey),
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.accent,
              visualDensity: VisualDensity.compact,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12, left: 4),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.title, required this.examples});

  final String title;
  final String examples;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            examples,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
