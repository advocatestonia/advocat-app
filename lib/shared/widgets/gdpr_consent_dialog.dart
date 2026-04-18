import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';

final _log = Logger(
  printer: PrettyPrinter(methodCount: 0),
  level: kDebugMode ? Level.debug : Level.off,
);

const _gdprStorageKey = 'gdpr_consent_accepted';
const _analyticsConsentKey = 'analytics_consent_accepted';
const _voiceConsentKey = 'voice_consent_accepted';

/// Returns `true` if the user has previously given GDPR consent.
Future<bool> hasGdprConsent() async {
  // First check Supabase profile (authoritative source)
  try {
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    if (uid != null) {
      final row = await client
          .from('profiles')
          .select('gdpr_consent_at')
          .eq('id', uid)
          .maybeSingle();
      if (row != null && row['gdpr_consent_at'] != null) {
        return true;
      }
    }
  } catch (e) {
    _log.d('Could not check Supabase gdpr_consent_at: $e');
  }

  // Fallback to local storage
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

/// Returns `true` if the user has opted in to voice recording processing.
Future<bool> hasVoiceConsent() async {
  const storage = FlutterSecureStorage();
  final value = await storage.read(key: _voiceConsentKey);
  return value == 'true';
}

/// Persists the GDPR consent flag locally and to Supabase.
Future<void> _saveGdprConsent({
  required bool analytics,
  required bool voice,
}) async {
  // Save to local storage
  try {
    const storage = FlutterSecureStorage();
    await storage.write(key: _gdprStorageKey, value: 'true');
    await storage.write(
      key: _analyticsConsentKey,
      value: analytics ? 'true' : 'false',
    );
    await storage.write(
      key: _voiceConsentKey,
      value: voice ? 'true' : 'false',
    );
  } catch (e) {
    if (kIsWeb) {
      _log.w('FlutterSecureStorage unavailable on web — GDPR consent '
          'accepted for this session only. Error: $e');
    }
  }

  // Save to Supabase profiles table
  try {
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    if (uid != null) {
      await client.from('profiles').update({
        'gdpr_consent_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', uid);
      _log.d('GDPR consent timestamp saved to Supabase profiles');
    }
  } catch (e) {
    _log.w('Failed to save gdpr_consent_at to Supabase: $e');
  }
}

/// Shows a GDPR explicit consent dialog (Art. 6 + Art. 9) and returns
/// `true` if the user accepted the required consent.
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
  bool _voiceConsent = false;
  bool _analyticsConsent = false;
  bool _saving = false;

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
            // ── Art. 9 special category data notice ─────────────────
            Text(
              l10n?.gdprArt9Intro ??
                  'This app processes special category personal data under '
                      'GDPR Article 9, including:',
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 12),
            _ConsentItem(
              icon: Icons.gavel_outlined,
              text: l10n?.gdprSpecialLegalCases ??
                  'Your legal case details and court documents',
            ),
            _ConsentItem(
              icon: Icons.public_outlined,
              text: l10n?.gdprSpecialNationality ??
                  'Nationality and immigration status',
            ),
            _ConsentItem(
              icon: Icons.chat_outlined,
              text: l10n?.gdprChat ??
                  'Messages you send to the AI assistant',
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
              label: l10n?.gdprConsentLegalData ??
                  'I consent to the processing of my legal case data, '
                      'nationality, and immigration status by AI (required)',
              isRequired: true,
            ),
            const SizedBox(height: 8),
            _ConsentCheckbox(
              value: _voiceConsent,
              onChanged: (v) =>
                  setState(() => _voiceConsent = v ?? false),
              label: l10n?.gdprConsentVoice ??
                  'I consent to voice recording processing (optional)',
              isRequired: false,
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
                  'Your data is encrypted and processed securely. We use '
                      'trusted service providers (AI processing, cloud '
                      'database) to deliver the service. See our Privacy '
                      'Policy for details. You can withdraw consent and '
                      'delete all data from Settings.',
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
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: Text(l10n?.decline ?? 'Decline'),
        ),
        FilledButton(
          onPressed: _aiProcessingConsent && !_saving
              ? () async {
                  setState(() => _saving = true);
                  await _saveGdprConsent(
                    analytics: _analyticsConsent,
                    voice: _voiceConsent,
                  );
                  if (context.mounted) Navigator.pop(context, true);
                }
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.3),
          ),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(l10n?.iAgree ?? 'I Agree'),
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
