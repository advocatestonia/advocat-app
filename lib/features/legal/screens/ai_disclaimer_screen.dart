import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/advocat_gradient_header.dart';

/// Dedicated AI Disclaimer screen for the Advocat application.
///
/// Clearly explains what the AI can and cannot do, accuracy disclaimers,
/// when to consult a real lawyer, and how to report errors.
class AiDisclaimerScreen extends StatelessWidget {
  const AiDisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AdvocatGradientHeader(
        title: AppLocalizations.of(context)?.aiDisclaimer ?? 'AI Disclaimer',
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: Text(
                  'Advocat AI Disclaimer',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Effective Date: 1 March 2026',
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
      _criticalBox(
        'Important Notice',
        'Advocat provides AI-generated legal INFORMATION, not legal ADVICE. '
            'Advocat is not a law firm and does not provide legal representation. '
            'No attorney-client relationship is created by using this Service.\n\n'
            'Always consult a qualified lawyer before making legal decisions.',
      ),
      _canDoBox(
        '1. What Our AI Can Do',
        'The Advocat AI assistant is designed to help you with the following:\n\n'
            '1.1. Provide General Legal Information\n'
            '  - Explain legal concepts, terms, and procedures in plain language;\n'
            '  - Describe how laws and regulations generally apply;\n'
            '  - Outline typical legal processes (appeals, complaints, asylum procedures).\n\n'
            '1.2. Analyse and Explain Documents\n'
            '  - Summarise legal documents, court decisions, and official correspondence;\n'
            '  - Highlight key points, deadlines, and required actions;\n'
            '  - Translate legal jargon into understandable language.\n\n'
            '1.3. Draft Templates and Correspondence\n'
            '  - Generate draft letters, appeals, and complaints;\n'
            '  - Create template responses to official communications;\n'
            '  - Suggest structures for legal arguments.\n\n'
            '1.4. Identify Deadlines and Key Dates\n'
            '  - Detect deadlines mentioned in documents;\n'
            '  - Calculate appeal windows and statutory time limits;\n'
            '  - Provide reminders for important dates.\n\n'
            '1.5. Research and Reference\n'
            '  - Reference relevant laws, directives, and regulations;\n'
            '  - Identify applicable EU and national legal frameworks;\n'
            '  - Provide general guidance on where to find more information.',
      ),
      _cannotDoBox(
        '2. What Our AI CANNOT Do',
        'The Advocat AI assistant is NOT able to and does NOT:\n\n'
            '2.1. Provide Legal Advice\n'
            '  - The AI does not assess your specific legal situation to recommend a '
            'course of action;\n'
            '  - It cannot evaluate the merits of your particular case;\n'
            '  - It does not create an attorney-client relationship.\n\n'
            '2.2. Represent You in Legal Proceedings\n'
            '  - The AI cannot appear on your behalf in any court, tribunal, or '
            'administrative body;\n'
            '  - It cannot file documents with courts or government agencies;\n'
            '  - It cannot negotiate on your behalf.\n\n'
            '2.3. Guarantee Outcomes\n'
            '  - The AI cannot predict the outcome of any legal matter;\n'
            '  - Past results or general information do not guarantee future outcomes;\n'
            '  - Every legal situation is unique and depends on specific facts and '
            'circumstances.\n\n'
            '2.4. Replace a Lawyer\n'
            '  - The AI is a supplementary tool, not a substitute for professional '
            'legal counsel;\n'
            '  - Complex legal matters require human expertise, judgment, and '
            'professional accountability;\n'
            '  - Only a licensed lawyer can provide legal advice in your jurisdiction.',
      ),
      _section(
        '3. Accuracy Disclaimer',
        '3.1. The AI generates responses based on its training data and may not '
            'reflect the most current laws, regulations, or case law. Legal '
            'frameworks change frequently.\n\n'
            '3.2. AI-generated content may contain:\n'
            '  - Inaccuracies or errors in legal interpretation;\n'
            '  - Omissions of relevant legal provisions;\n'
            '  - Information that is not applicable to your specific jurisdiction;\n'
            '  - Outdated references to laws that have been amended or repealed.\n\n'
            '3.3. The AI may occasionally generate plausible-sounding but incorrect '
            'information (a known limitation of large language models).\n\n'
            '3.4. You should always verify AI-generated information against '
            'authoritative legal sources and, where appropriate, with a qualified '
            'legal professional.',
      ),
      _section(
        '4. How Our AI Works',
        '4.1. Technology\n'
            'Advocat uses Claude, an AI assistant developed by Anthropic. Claude is a '
            'large language model trained on a broad range of text data, including '
            'legal texts, to understand and generate human-like responses.\n\n'
            '4.2. Processing\n'
            'When you send a message or upload a document, the content is transmitted '
            'securely to Anthropic\'s servers for processing. The AI analyses your '
            'input and generates a response based on its training.\n\n'
            '4.3. Context\n'
            'The AI uses the context of your current conversation and case information '
            'to provide more relevant responses. It does not have access to external '
            'databases, live legal databases, or real-time information.\n\n'
            '4.4. Limitations\n'
            'The AI does not have access to:\n'
            '  - Real-time court records or case databases;\n'
            '  - Live government databases;\n'
            '  - Your specific court files or official records;\n'
            '  - Information beyond its training data cutoff date.',
      ),
      _highlightBox(
        '5. When to Consult a Real Lawyer',
        'You should ALWAYS consult a qualified legal professional when:\n\n'
            '  - You need to make a legal decision that could affect your rights;\n'
            '  - You are facing court proceedings, deportation, or criminal charges;\n'
            '  - You need to sign contracts or legal agreements;\n'
            '  - You are responding to official government decisions;\n'
            '  - You are filing appeals or complaints with courts or tribunals;\n'
            '  - You need legal representation before any authority;\n'
            '  - Your case involves significant financial consequences;\n'
            '  - You are unsure whether AI-generated information applies to your situation;\n'
            '  - The stakes are high or the matter is complex;\n'
            '  - You need advice specific to your jurisdiction and circumstances.\n\n'
            'Many jurisdictions offer free legal aid to individuals who cannot afford '
            'a lawyer. Use our Legal Aid Calculator to check if you may qualify.',
      ),
      _section(
        '6. Limitation of Liability for AI-Generated Content',
        '6.1. Advocat, its officers, directors, employees, and agents shall not be '
            'liable for any damages, losses, or adverse consequences arising from '
            'your reliance on AI-generated content.\n\n'
            '6.2. This includes, without limitation:\n'
            '  - Missed deadlines due to incorrect deadline calculation;\n'
            '  - Adverse legal outcomes due to reliance on AI information;\n'
            '  - Financial losses arising from AI-generated advice;\n'
            '  - Errors or omissions in document drafts generated by the AI;\n'
            '  - Incorrect interpretation of laws or regulations.\n\n'
            '6.3. You acknowledge that you use AI-generated content entirely at '
            'your own risk and that you are solely responsible for verifying the '
            'accuracy and applicability of any information before acting on it.',
      ),
      _section(
        '7. How to Report Errors',
        'If you discover inaccurate, misleading, or potentially harmful AI-generated '
            'content, please report it to us immediately:\n\n'
            'Email: info@advocat.ee\n'
            'Subject: AI Content Error Report\n\n'
            'Please include:\n'
            '  - A description of the error or inaccuracy;\n'
            '  - The approximate date and time of the conversation;\n'
            '  - The question you asked (if you remember);\n'
            '  - The response that was incorrect;\n'
            '  - Why you believe it is incorrect (if known).\n\n'
            'We take all reports seriously and use them to improve the Service. '
            'Your feedback helps us identify issues and enhance the accuracy of '
            'our AI system.',
      ),
      _section(
        '8. Continuous Improvement',
        'We are committed to improving the accuracy and reliability of our AI system. '
            'We regularly:\n\n'
            '  - Review and update AI instructions and safety guidelines;\n'
            '  - Incorporate user feedback to address known issues;\n'
            '  - Monitor for legal and regulatory changes;\n'
            '  - Test AI outputs against verified legal information;\n'
            '  - Implement safeguards against known AI limitations.\n\n'
            'Despite our best efforts, AI technology has inherent limitations. '
            'We encourage all users to exercise critical judgment when using '
            'AI-generated content.',
      ),
      _section(
        '9. Contact Us',
        'If you have any questions about this AI Disclaimer or how our AI works, '
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

  Widget _criticalBox(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.warning_rounded,
                  color: AppColors.error,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
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
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                height: 1.65,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _canDoBox(String title, String body) {
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
                  Icons.check_circle_outlined,
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

  Widget _cannotDoBox(String title, String body) {
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
                const Icon(
                  Icons.block_rounded,
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

  Widget _highlightBox(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.info.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.info.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.gavel_rounded,
                  color: AppColors.info,
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
