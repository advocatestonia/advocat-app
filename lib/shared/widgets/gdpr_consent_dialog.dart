import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../config/theme.dart';

const _gdprStorageKey = 'gdpr_consent_accepted';

/// Returns `true` if the user has previously given GDPR consent.
Future<bool> hasGdprConsent() async {
  const storage = FlutterSecureStorage();
  final value = await storage.read(key: _gdprStorageKey);
  return value == 'true';
}

/// Persists the GDPR consent flag.
Future<void> _saveGdprConsent() async {
  const storage = FlutterSecureStorage();
  await storage.write(key: _gdprStorageKey, value: 'true');
}

/// Shows a GDPR consent dialog and returns `true` if accepted.
Future<bool> showGdprConsentDialog(BuildContext context) async {
  final accepted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      title: const Row(
        children: [
          Icon(Icons.shield_outlined, color: AppColors.accent),
          SizedBox(width: 8),
          Text('Data Privacy Consent'),
        ],
      ),
      content: const SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To provide AI legal assistance, we process your data in accordance '
              'with GDPR (EU 2016/679). By continuing you agree to:',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            SizedBox(height: 12),
            _ConsentItem(
              icon: Icons.chat_outlined,
              text: 'Processing of your chat messages by AI',
            ),
            _ConsentItem(
              icon: Icons.description_outlined,
              text: 'Analysis of uploaded documents',
            ),
            _ConsentItem(
              icon: Icons.storage_outlined,
              text: 'Encrypted storage of case data',
            ),
            _ConsentItem(
              icon: Icons.delete_outline,
              text: 'Right to delete your data at any time',
            ),
            SizedBox(height: 12),
            Text(
              'Your data is encrypted and never shared with third parties. '
              'You can withdraw consent and delete all data from Settings.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Decline'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
          ),
          child: const Text('I Agree'),
        ),
      ],
    ),
  );

  if (accepted == true) {
    await _saveGdprConsent();
    return true;
  }
  return false;
}

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
