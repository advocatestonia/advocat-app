import 'package:flutter/material.dart';

import '../../../config/theme.dart';

/// Full GDPR-compliant Privacy Policy screen for the Advocat application.
///
/// Covers data controller information, data categories, legal bases,
/// third-party processors, user rights, and supervisory authority details.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
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
            'Advocat Privacy Policy',
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
        '1. Data Controller',
        'The data controller responsible for your personal data is:\n\n'
            'Advocat\n'
            'Registered in the Republic of Estonia\n'
            'Email: info@advocat.ee\n'
            'Website: https://advocat.ee\n\n'
            'For any questions regarding this Privacy Policy or our data processing '
            'practices, please contact us at info@advocat.ee.',
      ),
      _section(
        '2. What Data We Collect',
        'We collect and process the following categories of personal data:\n\n'
            '2.1. Account Data\n'
            'When you create an account, we collect:\n'
            '  - Email address;\n'
            '  - Full name;\n'
            '  - Language preference;\n'
            '  - Authentication credentials (securely hashed, never stored in plaintext).\n\n'
            '2.2. Case Data\n'
            'When you use our legal assistance features, we process:\n'
            '  - Case descriptions and details you provide;\n'
            '  - Documents you upload for analysis;\n'
            '  - Correspondence drafts and templates;\n'
            '  - Deadline and timeline information.\n\n'
            '2.3. Chat Data\n'
            'When you interact with our AI assistant, we process:\n'
            '  - Messages you send to the AI;\n'
            '  - AI-generated responses;\n'
            '  - Conversation history within your sessions.\n\n'
            '2.4. Usage Data\n'
            'We automatically collect:\n'
            '  - Device type and operating system;\n'
            '  - App version;\n'
            '  - Feature usage analytics (anonymised);\n'
            '  - Error and crash reports;\n'
            '  - Session duration and interaction patterns.\n\n'
            '2.5. Payment Data\n'
            'For paid subscriptions:\n'
            '  - Payments are processed by Stripe, our PCI DSS-compliant payment processor;\n'
            '  - We do NOT store credit card numbers, CVVs, or full card details;\n'
            '  - We receive and store only: payment confirmation, subscription status, '
            'billing period, and the last four digits of your card for reference.',
      ),
      _section(
        '3. Legal Basis for Processing (GDPR Article 6)',
        'We process your personal data on the following legal bases:\n\n'
            '3.1. Consent (Article 6(1)(a))\n'
            '  - Processing of your chat messages by AI systems;\n'
            '  - Sending you optional marketing communications;\n'
            '  - Use of non-essential analytics.\n'
            'You may withdraw your consent at any time by contacting info@advocat.ee. '
            'Withdrawal does not affect the lawfulness of processing before withdrawal.\n\n'
            '3.2. Performance of a Contract (Article 6(1)(b))\n'
            '  - Processing account data to provide and maintain the Service;\n'
            '  - Processing case data and documents to deliver the features you use;\n'
            '  - Processing payment data to manage your subscription.\n\n'
            '3.3. Legitimate Interest (Article 6(1)(f))\n'
            '  - Ensuring the security and integrity of the Service;\n'
            '  - Fraud prevention and detection;\n'
            '  - Improving the Service through anonymised analytics;\n'
            '  - Communicating important service updates.\n'
            'Our legitimate interests do not override your fundamental rights and freedoms.',
      ),
      _section(
        '4. Third-Party Data Processors',
        'We engage the following third-party processors to provide the Service:\n\n'
            '4.1. Anthropic (Claude AI)\n'
            '  - Purpose: AI-powered legal information generation;\n'
            '  - Data processed: Chat messages, case descriptions, document content;\n'
            '  - Location: United States;\n'
            '  - Safeguards: EU-US Data Privacy Framework; Standard Contractual Clauses;\n'
            '  - Privacy policy: https://www.anthropic.com/privacy\n\n'
            '4.2. Supabase\n'
            '  - Purpose: Database hosting, authentication, and file storage;\n'
            '  - Data processed: Account data, case data, documents;\n'
            '  - Location: European Union servers;\n'
            '  - Safeguards: GDPR-compliant data processing agreement;\n'
            '  - Privacy policy: https://supabase.com/privacy\n\n'
            '4.3. Stripe\n'
            '  - Purpose: Payment processing;\n'
            '  - Data processed: Payment and billing information;\n'
            '  - Safeguards: PCI DSS Level 1 certified; GDPR-compliant;\n'
            '  - Privacy policy: https://stripe.com/privacy\n\n'
            '4.4. Google (Firebase)\n'
            '  - Purpose: Analytics, crash reporting, and push notifications;\n'
            '  - Data processed: Anonymised usage data, device identifiers;\n'
            '  - Safeguards: EU-US Data Privacy Framework; Standard Contractual Clauses;\n'
            '  - Privacy policy: https://policies.google.com/privacy\n\n'
            'We ensure all processors provide adequate safeguards for personal data '
            'protection through data processing agreements in compliance with GDPR '
            'Article 28.',
      ),
      _section(
        '5. Data Retention',
        'We retain your personal data for the following periods:\n\n'
            '5.1. Account Data\n'
            '  - Retained for the duration of your active account;\n'
            '  - Deleted within 30 days of account deletion, except where retention '
            'is required by law.\n\n'
            '5.2. Case Data and Documents\n'
            '  - Retained for the duration of your active account;\n'
            '  - You may delete individual cases and documents at any time;\n'
            '  - All case data is deleted within 30 days of account deletion.\n\n'
            '5.3. Chat Data\n'
            '  - Active conversations: retained for the duration of the associated case;\n'
            '  - Deleted when the associated case is deleted or account is closed.\n\n'
            '5.4. Usage Data\n'
            '  - Anonymised analytics data: retained for up to 26 months;\n'
            '  - Crash reports: retained for 90 days;\n'
            '  - Raw usage logs: retained for 30 days, then anonymised or deleted.\n\n'
            '5.5. Payment Data\n'
            '  - Transaction records: retained for 7 years as required by Estonian '
            'and EU tax and accounting regulations;\n'
            '  - Active subscription details: retained for the duration of the subscription.\n\n'
            '5.6. Legal Obligations\n'
            '  - Where we are required by law to retain data beyond the above periods, '
            'we will do so in compliance with applicable legal requirements.',
      ),
      _highlightBox(
        '6. Your Rights Under GDPR',
        'Under the General Data Protection Regulation, you have the following rights:\n\n'
            '6.1. Right of Access (Article 15)\n'
            'You may request a copy of the personal data we hold about you.\n\n'
            '6.2. Right to Rectification (Article 16)\n'
            'You may request correction of inaccurate or incomplete personal data.\n\n'
            '6.3. Right to Erasure (Article 17)\n'
            'You may request deletion of your personal data ("right to be forgotten"), '
            'subject to applicable legal retention requirements.\n\n'
            '6.4. Right to Data Portability (Article 20)\n'
            'You may request your personal data in a structured, commonly used, '
            'and machine-readable format.\n\n'
            '6.5. Right to Object (Article 21)\n'
            'You may object to processing based on legitimate interests or for '
            'direct marketing purposes.\n\n'
            '6.6. Right to Restriction of Processing (Article 18)\n'
            'You may request that we restrict the processing of your personal data '
            'under certain circumstances.\n\n'
            '6.7. Right to Withdraw Consent\n'
            'Where processing is based on consent, you may withdraw consent at any time.\n\n'
            '6.8. Right to Lodge a Complaint\n'
            'You have the right to lodge a complaint with a supervisory authority '
            '(see Section 12).',
      ),
      _section(
        '7. How to Exercise Your Rights',
        'To exercise any of the above rights, please contact us at:\n\n'
            'Email: info@advocat.ee\n\n'
            'We will respond to your request within 30 days, as required by the GDPR. '
            'In complex cases, we may extend this period by an additional 60 days, '
            'provided we notify you of the extension.\n\n'
            'To verify your identity, we may ask you to provide additional information '
            'before processing your request.\n\n'
            'You may also exercise certain rights directly within the application:\n'
            '  - Export your data through Settings > Export My Data;\n'
            '  - Delete your account through Settings > Delete Account;\n'
            '  - Manage notification preferences through Settings.',
      ),
      _section(
        '8. Children\'s Privacy',
        '8.1. The Service is not intended for individuals under the age of 18.\n\n'
            '8.2. We do not knowingly collect personal data from anyone under 18 years '
            'of age.\n\n'
            '8.3. If we become aware that we have collected personal data from a '
            'person under 18 without appropriate parental consent, we will take '
            'steps to delete that data promptly.\n\n'
            '8.4. If you believe we may have collected data from a person under 18, '
            'please contact us immediately at info@advocat.ee.',
      ),
      _section(
        '9. International Data Transfers',
        '9.1. Your personal data is primarily stored on servers located within '
            'the European Union (via Supabase EU infrastructure).\n\n'
            '9.2. Certain data is transferred to the United States for processing by '
            'Anthropic (AI chat processing) and Google (analytics). These transfers '
            'are protected by:\n'
            '  - The EU-US Data Privacy Framework;\n'
            '  - Standard Contractual Clauses (SCCs) approved by the European Commission;\n'
            '  - Supplementary technical and organisational measures as needed.\n\n'
            '9.3. We ensure that any international transfer of personal data complies '
            'with GDPR Chapter V requirements and that appropriate safeguards are in place.',
      ),
      _section(
        '10. Cookies and Local Storage',
        '10.1. The Advocat mobile application uses minimal local storage for '
            'essential functionality only:\n'
            '  - Session management (authentication tokens);\n'
            '  - Language preference;\n'
            '  - GDPR consent flag;\n'
            '  - App settings and preferences.\n\n'
            '10.2. We do NOT use:\n'
            '  - Tracking cookies;\n'
            '  - Third-party advertising cookies;\n'
            '  - Cross-site tracking mechanisms.\n\n'
            '10.3. For our website (advocat.ee), we use only essential cookies '
            'required for the website to function. No analytics or marketing cookies '
            'are used without your explicit consent.\n\n'
            '10.4. For detailed information, please refer to our Cookie Policy, '
            'accessible within the application.',
      ),
      _section(
        '11. Data Security',
        '11.1. We implement appropriate technical and organisational measures to '
            'protect your personal data, including:\n'
            '  - Encryption in transit (TLS 1.3) and at rest (AES-256);\n'
            '  - Secure authentication with hashed credentials;\n'
            '  - Regular security audits and vulnerability assessments;\n'
            '  - Access controls and least-privilege principles;\n'
            '  - Secure development practices.\n\n'
            '11.2. While we take reasonable measures to protect your data, no method '
            'of electronic transmission or storage is 100% secure. We cannot guarantee '
            'absolute security.\n\n'
            '11.3. In the event of a personal data breach that poses a risk to your '
            'rights and freedoms, we will notify you and the relevant supervisory '
            'authority within 72 hours, as required by GDPR Article 33.',
      ),
      _section(
        '12. Supervisory Authority',
        'If you believe that our processing of your personal data violates the GDPR, '
            'you have the right to lodge a complaint with a supervisory authority.\n\n'
            'Our lead supervisory authority is:\n\n'
            'Andmekaitse Inspektsioon\n'
            '(Estonian Data Protection Inspectorate)\n'
            'Tatari 39, 10134 Tallinn, Estonia\n'
            'Phone: +372 627 4135\n'
            'Email: info@aki.ee\n'
            'Website: https://www.aki.ee\n\n'
            'You may also lodge a complaint with the supervisory authority in '
            'the EU Member State where you reside or work.',
      ),
      _section(
        '13. Changes to This Privacy Policy',
        '13.1. We may update this Privacy Policy from time to time. Material changes '
            'will be communicated through the application or via email at least 30 '
            'days before they take effect.\n\n'
            '13.2. The "Last Updated" date at the top of this policy indicates when '
            'it was last revised.\n\n'
            '13.3. Your continued use of the Service after any changes constitutes '
            'your acknowledgement of the updated policy.',
      ),
      _section(
        '14. Data Protection Officer',
        'For any data protection inquiries, you may contact our designated '
            'data protection contact:\n\n'
            'Advocat Data Protection Officer\n'
            'Email: info@advocat.ee\n\n'
            'We aim to respond to all data protection inquiries within 5 business days.',
      ),
      _section(
        '15. Contact Us',
        'If you have any questions, concerns, or requests regarding this Privacy Policy '
            'or our data practices, please contact us:\n\n'
            'Advocat\n'
            'Email: info@advocat.ee\n'
            'Website: https://advocat.ee\n'
            'Country of Registration: Republic of Estonia',
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
                Icon(
                  Icons.shield_outlined,
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
}
