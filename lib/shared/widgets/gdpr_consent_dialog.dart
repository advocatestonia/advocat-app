import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';

final _log = Logger(
  printer: PrettyPrinter(methodCount: 0),
  level: kDebugMode ? Level.debug : Level.off,
);

const _gdprStorageKey = 'gdpr_consent_accepted';
const _analyticsConsentKey = 'analytics_consent_accepted';

/// Returns `true` if the user has previously given GDPR consent.
Future<bool> hasGdprConsent() async {
  try {
    const storage = FlutterSecureStorage();
    final value = await storage.read(key: _gdprStorageKey);
    return value == 'true';
  } catch (_) {
    return false;
  }
}

/// Returns `true` if the user has opted in to analytics.
Future<bool> hasAnalyticsConsent() async {
  const storage = FlutterSecureStorage();
  final value = await storage.read(key: _analyticsConsentKey);
  return value == 'true';
}

/// Persists the GDPR consent flag.
Future<void> _saveGdprConsent({required bool analytics}) async {
  try {
    const storage = FlutterSecureStorage();
    await storage.write(key: _gdprStorageKey, value: 'true');
    await storage.write(
      key: _analyticsConsentKey,
      value: analytics ? 'true' : 'false',
    );
  } catch (e) {
    // On web, FlutterSecureStorage may fail (e.g. no Web Crypto API).
    // Consent is still accepted for this session but will not persist.
    if (kIsWeb) {
      _log.w('FlutterSecureStorage unavailable on web — GDPR consent '
          'accepted for this session only. Error: $e');
    }
  }
}

/// Shows a GDPR consent dialog and returns `true` if accepted.
Future<bool> showGdprConsentDialog(BuildContext context) async {
  final accepted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const _GdprConsentDialogContent(),
  );

  return accepted == true;
}

class _GdprConsentDialogContent extends StatefulWidget {
  const _GdprConsentDialogContent();

  @override
  State<_GdprConsentDialogContent> createState() =>
      _GdprConsentDialogContentState();
}

class _GdprConsentDialogContentState
    extends State<_GdprConsentDialogContent> {
  bool _aiProcessingConsent = false;
  bool _analyticsConsent = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      title: Row(
        children: [
          const Icon(Icons.shield_outlined, color: AppColors.accent),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              l10n?.dataPrivacyConsent ?? 'Data Privacy Consent',
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.gdprIntro ??
                  'To provide AI legal assistance, we process your data in accordance with GDPR (EU 2016/679). By continuing you agree to:',
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 12),
            _ConsentItem(
              icon: Icons.chat_outlined,
              text: l10n?.gdprChat ??
                  'Processing of your chat messages by AI',
            ),
            _ConsentItem(
              icon: Icons.description_outlined,
              text: l10n?.gdprDocs ??
                  'Analysis of uploaded documents',
            ),
            _ConsentItem(
              icon: Icons.storage_outlined,
              text: l10n?.gdprStorage ??
                  'Encrypted storage of case data',
            ),
            _ConsentItem(
              icon: Icons.delete_outline,
              text: l10n?.gdprDelete ??
                  'Right to delete your data at any time',
            ),
            const SizedBox(height: 16),

            // ── Granular consent checkboxes ──────────────────────────
            _ConsentCheckbox(
              value: _aiProcessingConsent,
              onChanged: (v) =>
                  setState(() => _aiProcessingConsent = v ?? false),
              label: l10n?.gdprConsentAiProcessing ??
                  'I agree to the processing of my data for AI legal assistance (required)',
              isRequired: true,
            ),
            const SizedBox(height: 8),
            _ConsentCheckbox(
              value: _analyticsConsent,
              onChanged: (v) =>
                  setState(() => _analyticsConsent = v ?? false),
              label: l10n?.gdprConsentAnalytics ??
                  'I agree to analytics to improve the service (optional)',
              isRequired: false,
            ),

            const SizedBox(height: 16),

            // ── Honest footer text ──────────────────────────────────
            Text(
              l10n?.gdprFooter ??
                  'Your data is encrypted and processed securely. We use trusted service providers (AI processing, cloud database) to deliver the service. See our Privacy Policy for details. You can withdraw consent and delete all data from Settings.',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),

            // ── Privacy Policy link ─────────────────────────────────
            GestureDetector(
              onTap: () async {
                final uri = Uri.parse('https://advocat.ee/privacy');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Text(
                l10n?.gdprViewPrivacyPolicy ?? 'View Privacy Policy',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.accent,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n?.decline ?? 'Decline'),
        ),
        FilledButton(
          onPressed: _aiProcessingConsent
              ? () async {
                  await _saveGdprConsent(analytics: _analyticsConsent);
                  if (context.mounted) Navigator.pop(context, true);
                }
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.3),
          ),
          child: Text(l10n?.iAgree ?? 'I Agree'),
        ),
      ],
    );
  }
}

/// A single informational consent item row.
class _ConsentItem extends StatelessWidget {
  const _ConsentItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// A checkbox row for granular consent.
class _ConsentCheckbox extends StatelessWidget {
  const _ConsentCheckbox({
    required this.value,
    required this.onChanged,
    required this.label,
    required this.isRequired,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;
  final String label;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.accent,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  fontWeight:
                      isRequired ? FontWeight.w500 : FontWeight.normal,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
