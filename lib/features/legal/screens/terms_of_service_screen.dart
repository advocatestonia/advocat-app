import 'package:flutter/material.dart';

import '../../../config/theme.dart';

/// Full Terms of Service screen for the Advocat application.
///
/// Covers service description, AI disclaimers, liability limitations,
/// subscription terms, and governing law (Estonian jurisdiction).
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Terms of Service'),
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
            'Advocat Terms of Service',
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
        '1. Introduction and Acceptance',
        'Welcome to Advocat ("Service", "Platform", "we", "us", or "our"), '
            'operated by Advocat, a company registered in the Republic of Estonia, '
            'accessible at advocat.ee.\n\n'
            'By accessing or using the Advocat application, website, or any related '
            'services, you ("User", "you", or "your") agree to be bound by these '
            'Terms of Service ("Terms"). If you do not agree to these Terms, you '
            'must not access or use the Service.\n\n'
            'These Terms constitute a legally binding agreement between you and Advocat. '
            'Please read them carefully before using the Service.',
      ),
      _section(
        '2. Service Description',
        '2.1. Advocat is an AI-powered legal information platform designed to help '
            'users understand legal concepts, analyse documents, identify deadlines, '
            'draft correspondence templates, and access general legal information '
            'relevant to European Union jurisdictions.\n\n'
            '2.2. The Service utilises artificial intelligence technology, including '
            'large language models provided by third-party processors, to generate '
            'responses to user queries and analyse uploaded documents.\n\n'
            '2.3. The Service may include, but is not limited to, the following features:\n'
            '  (a) AI-assisted legal information chat;\n'
            '  (b) Document analysis and summarisation;\n'
            '  (c) Deadline tracking and reminder tools;\n'
            '  (d) Draft document and correspondence generation;\n'
            '  (e) Company and vehicle background checks;\n'
            '  (f) Legal rights guides and calculators;\n'
            '  (g) Secure document storage.',
      ),
      _importantBox(
        '3. AI Disclaimer — CRITICAL NOTICE',
        '3.1. Advocat provides AI-generated legal INFORMATION, not legal ADVICE. '
            'Advocat is not a law firm, does not employ licensed attorneys for the '
            'purpose of providing legal advice through this Service, and does not '
            'provide legal representation.\n\n'
            '3.2. The information provided by Advocat is for general informational '
            'purposes only and should not be construed as legal advice on any '
            'specific matter.\n\n'
            '3.3. No attorney-client relationship is created between you and Advocat '
            'by your use of the Service.\n\n'
            '3.4. AI-generated content may contain inaccuracies, omissions, or '
            'outdated information. Laws and regulations change frequently, and '
            'the AI may not reflect the most current legal developments.\n\n'
            '3.5. ALWAYS CONSULT A QUALIFIED LAWYER before making legal decisions, '
            'signing legal documents, appearing before courts or tribunals, or '
            'taking any action that may have legal consequences.\n\n'
            '3.6. You acknowledge and agree that any reliance on information '
            'provided by the Service is at your own risk.',
      ),
      _section(
        '4. User Eligibility',
        '4.1. You must be at least 18 years of age to use the Service.\n\n'
            '4.2. The Service is primarily intended for individuals residing in '
            'or having legal matters connected to the European Union, European '
            'Economic Area, or the United Kingdom.\n\n'
            '4.3. By using the Service, you represent and warrant that:\n'
            '  (a) You are at least 18 years of age;\n'
            '  (b) You have the legal capacity to enter into a binding agreement;\n'
            '  (c) You are not barred from using the Service under applicable law;\n'
            '  (d) The information you provide is accurate and complete.',
      ),
      _section(
        '5. Account Terms',
        '5.1. To access certain features of the Service, you must create an account. '
            'You agree to provide accurate, current, and complete information during '
            'registration.\n\n'
            '5.2. You are responsible for maintaining the confidentiality of your '
            'account credentials and for all activities that occur under your account.\n\n'
            '5.3. You must notify us immediately at info@advocat.ee if you become aware '
            'of any unauthorised use of your account.\n\n'
            '5.4. We reserve the right to suspend or terminate your account if you '
            'provide inaccurate information or violate these Terms.\n\n'
            '5.5. One person or entity may maintain only one account. Duplicate '
            'accounts may be terminated without notice.',
      ),
      _section(
        '6. Acceptable Use Policy',
        '6.1. You agree to use the Service only for lawful purposes and in '
            'accordance with these Terms. You shall not:\n\n'
            '  (a) Use the Service to engage in or facilitate any illegal activity;\n'
            '  (b) Submit false, misleading, or fraudulent information;\n'
            '  (c) Attempt to gain unauthorised access to any part of the Service;\n'
            '  (d) Interfere with or disrupt the integrity or performance of the Service;\n'
            '  (e) Use automated systems (bots, scrapers, crawlers) to access the Service '
            'without our written permission;\n'
            '  (f) Reverse-engineer, decompile, or disassemble any part of the Service;\n'
            '  (g) Use the Service to generate content that is defamatory, obscene, '
            'or violates the rights of third parties;\n'
            '  (h) Resell, sublicense, or commercially exploit the Service without '
            'our written consent;\n'
            '  (i) Upload content that contains malware, viruses, or harmful code.\n\n'
            '6.2. We reserve the right to investigate and take appropriate action '
            'against anyone who violates this section, including removing content, '
            'suspending accounts, and reporting to law enforcement.',
      ),
      _section(
        '7. Subscription Terms and Payment',
        '7.1. The Service offers both free and paid subscription tiers. Feature '
            'availability varies by tier and may change from time to time.\n\n'
            '7.2. Paid subscriptions are billed on a recurring basis (monthly or '
            'annually, as selected by you) through our payment processor, Stripe.\n\n'
            '7.3. All prices are displayed inclusive of applicable value-added tax (VAT) '
            'unless otherwise stated.\n\n'
            '7.4. Subscription Cancellation:\n'
            '  (a) You may cancel your subscription at any time through the app settings;\n'
            '  (b) Cancellation takes effect at the end of the current billing period;\n'
            '  (c) You retain access to paid features until the end of the period '
            'you have already paid for;\n'
            '  (d) No partial refunds are provided for unused portions of a billing period.\n\n'
            '7.5. Refund Policy:\n'
            '  (a) Refund requests must be submitted within 14 days of the initial '
            'subscription purchase, in accordance with the EU Consumer Rights Directive;\n'
            '  (b) By using the Service during the cooling-off period, you acknowledge '
            'that you may lose the right to a full refund for the services already provided;\n'
            '  (c) Refund requests should be directed to info@advocat.ee.\n\n'
            '7.6. We reserve the right to change pricing with at least 30 days\' prior '
            'notice. Price changes do not affect active subscription periods.',
      ),
      _section(
        '8. Data Processing',
        '8.1. We collect and process personal data in accordance with our Privacy Policy, '
            'which forms an integral part of these Terms.\n\n'
            '8.2. By using the Service, you acknowledge that:\n'
            '  (a) Your case data, documents, and chat messages are processed by AI systems;\n'
            '  (b) Data may be transmitted to third-party processors as described in '
            'our Privacy Policy;\n'
            '  (c) You have read and understood our Privacy Policy;\n'
            '  (d) You consent to the processing of your data as described therein.\n\n'
            '8.3. For full details on data collection, processing, retention, and '
            'your rights under the General Data Protection Regulation (GDPR), please '
            'refer to our Privacy Policy, accessible within the application.',
      ),
      _section(
        '9. Intellectual Property',
        '9.1. The Service, including its design, features, content, software, '
            'and documentation, is the intellectual property of Advocat and is '
            'protected by applicable copyright, trademark, and other intellectual '
            'property laws.\n\n'
            '9.2. You retain ownership of the content you submit to the Service '
            '(documents, case descriptions, messages). By submitting content, you '
            'grant us a limited, non-exclusive licence to process and store such '
            'content solely for the purpose of providing the Service.\n\n'
            '9.3. AI-generated outputs are provided for your personal use. You may '
            'use AI-generated content (drafts, summaries, analyses) for your own '
            'legal matters, but you may not commercially redistribute such content.\n\n'
            '9.4. The Advocat name, logo, and branding are trademarks of Advocat. '
            'You may not use these without our prior written consent.',
      ),
      _section(
        '10. Limitation of Liability',
        '10.1. TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, ADVOCAT AND ITS '
            'OFFICERS, DIRECTORS, EMPLOYEES, AND AGENTS SHALL NOT BE LIABLE FOR:\n\n'
            '  (a) Any indirect, incidental, special, consequential, or punitive damages;\n'
            '  (b) Any loss of profits, data, business opportunity, or goodwill;\n'
            '  (c) Any damages arising from your reliance on AI-generated content;\n'
            '  (d) Any damages arising from unauthorised access to or alteration of '
            'your data;\n'
            '  (e) Any damages exceeding the amount you paid to Advocat in the twelve '
            '(12) months preceding the claim.\n\n'
            '10.2. The Service is provided "AS IS" and "AS AVAILABLE" without '
            'warranties of any kind, whether express or implied, including but not '
            'limited to implied warranties of merchantability, fitness for a particular '
            'purpose, and non-infringement.\n\n'
            '10.3. We do not warrant that:\n'
            '  (a) The Service will be uninterrupted, timely, secure, or error-free;\n'
            '  (b) The results obtained from the Service will be accurate or reliable;\n'
            '  (c) Any errors in the Service will be corrected.\n\n'
            '10.4. Nothing in these Terms excludes or limits liability that cannot be '
            'excluded or limited under applicable law, including liability for death '
            'or personal injury caused by negligence, fraud, or fraudulent '
            'misrepresentation.',
      ),
      _section(
        '11. Indemnification',
        '11.1. You agree to indemnify, defend, and hold harmless Advocat, its '
            'officers, directors, employees, and agents from and against any claims, '
            'liabilities, damages, losses, costs, or expenses (including reasonable '
            'legal fees) arising out of or relating to:\n\n'
            '  (a) Your use of the Service;\n'
            '  (b) Your violation of these Terms;\n'
            '  (c) Your violation of any rights of any third party;\n'
            '  (d) Any content you submit to the Service.',
      ),
      _section(
        '12. Governing Law and Jurisdiction',
        '12.1. These Terms shall be governed by and construed in accordance with '
            'the laws of the Republic of Estonia, without regard to its conflict '
            'of law provisions.\n\n'
            '12.2. Any disputes arising out of or in connection with these Terms '
            'shall be subject to the exclusive jurisdiction of the courts of '
            'Harju County, Tallinn, Estonia.\n\n'
            '12.3. Notwithstanding the foregoing, if you are a consumer residing '
            'in the European Union, you may also bring proceedings in the courts '
            'of the Member State in which you are domiciled, and nothing in these '
            'Terms shall deprive you of any mandatory consumer protection rights '
            'under applicable EU or national law.',
      ),
      _section(
        '13. Dispute Resolution',
        '13.1. In the event of any dispute, you agree to first attempt to resolve '
            'it informally by contacting us at info@advocat.ee. We will endeavour '
            'to resolve disputes within 30 days of receipt.\n\n'
            '13.2. If the dispute cannot be resolved informally, either party may '
            'submit the dispute to the Consumer Disputes Committee of the Estonian '
            'Consumer Protection and Technical Regulatory Authority '
            '(Tarbijakaitse ja Tehnilise Jarelevalve Amet).\n\n'
            '13.3. EU consumers may also use the European Commission\'s Online '
            'Dispute Resolution platform at https://ec.europa.eu/consumers/odr/.',
      ),
      _section(
        '14. Termination',
        '14.1. You may terminate your account at any time by contacting us at '
            'info@advocat.ee or through the account settings.\n\n'
            '14.2. We may terminate or suspend your access to the Service '
            'immediately, without prior notice or liability, for any reason, '
            'including but not limited to a breach of these Terms.\n\n'
            '14.3. Upon termination:\n'
            '  (a) Your right to use the Service ceases immediately;\n'
            '  (b) We may delete your account data after a reasonable period;\n'
            '  (c) Provisions that by their nature should survive termination '
            'shall survive, including intellectual property, limitation of '
            'liability, indemnification, and governing law.',
      ),
      _section(
        '15. Changes to These Terms',
        '15.1. We reserve the right to modify these Terms at any time. Material '
            'changes will be communicated through the application or via email '
            'at least 30 days before they take effect.\n\n'
            '15.2. Your continued use of the Service after the effective date of '
            'any changes constitutes your acceptance of the modified Terms.\n\n'
            '15.3. If you do not agree to the modified Terms, you must stop using '
            'the Service and terminate your account.',
      ),
      _section(
        '16. Severability',
        'If any provision of these Terms is held to be invalid or unenforceable, '
            'that provision shall be modified to the minimum extent necessary to make '
            'it valid and enforceable, and the remaining provisions shall continue '
            'in full force and effect.',
      ),
      _section(
        '17. Entire Agreement',
        'These Terms, together with the Privacy Policy and any other legal notices '
            'published on the Service, constitute the entire agreement between you and '
            'Advocat regarding your use of the Service and supersede all prior '
            'agreements, negotiations, and discussions.',
      ),
      _section(
        '18. Contact Information',
        'If you have any questions about these Terms, please contact us:\n\n'
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

  Widget _importantBox(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
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
