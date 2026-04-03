import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';

/// Cookie and local storage policy screen for the Advocat application.
///
/// Describes the minimal use of cookies and local storage, limited to
/// essential functionality only, with no tracking or advertising cookies.
class CookiePolicyScreen extends StatelessWidget {
  const CookiePolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.cookiePolicy ?? 'Cookie Policy'),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: AppSpacing.lg),
            ..._buildSections(),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Advocat Cookie Policy',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            'Effective Date: 1 March 2026',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            'Last Updated: 1 March 2026',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSections() {
    return [
      _section(
        '1. Our Approach to Cookies',
        'Advocat is committed to protecting your privacy. We follow a privacy-first '
            'approach and use only minimal cookies and local storage that are strictly '
            'necessary for the application to function properly.\n\n'
            'We do not use cookies for advertising, profiling, or cross-site tracking.',
      ),
      _section(
        '2. What Are Cookies and Local Storage?',
        'Cookies are small text files placed on your device by a website or '
            'application. Local storage is a similar technology that allows '
            'applications to store small amounts of data on your device.\n\n'
            'Both are used to remember preferences and maintain session state '
            'so that the application works correctly.',
      ),
      _highlightBox(
        '3. What We Use',
        'The Advocat application uses the following essential storage only:\n\n'
            '3.1. Session Management\n'
            '  - Purpose: Keep you logged in and authenticate your requests;\n'
            '  - Type: Authentication token stored in secure local storage;\n'
            '  - Duration: Expires when you log out or after the session timeout;\n'
            '  - Essential: Yes — the app cannot function without this.\n\n'
            '3.2. Language Preference\n'
            '  - Purpose: Remember your selected language;\n'
            '  - Type: Language code stored in local storage;\n'
            '  - Duration: Persists until you change it or clear app data;\n'
            '  - Essential: Yes — ensures correct language display.\n\n'
            '3.3. GDPR Consent Flag\n'
            '  - Purpose: Remember that you have acknowledged our data processing;\n'
            '  - Type: Boolean flag stored in local storage;\n'
            '  - Duration: Persists until you clear app data;\n'
            '  - Essential: Yes — required for GDPR compliance.\n\n'
            '3.4. App Preferences\n'
            '  - Purpose: Store your notification and display settings;\n'
            '  - Type: Key-value pairs in local storage;\n'
            '  - Duration: Persists until you change them or clear app data;\n'
            '  - Essential: Yes — preserves your customised experience.',
      ),
      _successBox(
        '4. What We Do NOT Use',
        'Advocat does NOT use:\n\n'
            '  - Tracking cookies;\n'
            '  - Third-party advertising cookies;\n'
            '  - Marketing or retargeting pixels;\n'
            '  - Cross-site tracking mechanisms;\n'
            '  - Browser fingerprinting;\n'
            '  - Social media tracking widgets;\n'
            '  - Any non-essential cookies without your explicit consent.',
      ),
      _section(
        '5. Third-Party Services',
        '5.1. Our application uses Firebase for crash reporting and basic analytics. '
            'Firebase may use its own cookies or identifiers on the web version of '
            'the service. On mobile, it uses device identifiers that are covered '
            'under our Privacy Policy.\n\n'
            '5.2. Payment processing by Stripe may involve Stripe\'s own cookies '
            'on the payment page. These are governed by Stripe\'s Cookie Policy.\n\n'
            '5.3. We have no control over third-party cookies and recommend '
            'reviewing the respective privacy policies of these services.',
      ),
      _section(
        '6. Managing Cookies and Local Storage',
        '6.1. Since we only use essential cookies and local storage, there is no '
            'cookie consent banner required under the ePrivacy Directive — essential '
            'cookies are exempt from consent requirements.\n\n'
            '6.2. You can clear all locally stored data by:\n'
            '  - Logging out of the application;\n'
            '  - Clearing the app data through your device settings;\n'
            '  - Uninstalling the application.\n\n'
            '6.3. Please note that clearing essential storage data will log you '
            'out and reset your preferences.',
      ),
      _section(
        '7. Changes to This Policy',
        'We may update this Cookie Policy from time to time. If we introduce any '
            'non-essential cookies in the future, we will obtain your explicit consent '
            'before placing them on your device, as required by the ePrivacy Directive '
            'and GDPR.',
      ),
      _section(
        '8. Contact Us',
        'If you have any questions about our use of cookies and local storage, '
            'please contact us:\n\n'
            'Advocat\n'
            'Email: info@advocat.ee\n'
            'Website: https://advocat.ee',
      ),
    ];
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            body,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }

  Widget _highlightBox(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.cookie_outlined,
                  color: AppColors.accent,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              body,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
                height: 1.65,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _successBox(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.success.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.success,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              body,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
                height: 1.65,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
