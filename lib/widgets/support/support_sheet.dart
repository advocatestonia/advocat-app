// widgets/support/support_sheet.dart
//
// Modal sheet opened by [SupportFab]. Offers three contact channels:
//
//   1. WhatsApp — opens https://wa.me/<number>. Hidden when
//      `SupportConfig.whatsappNumber` is empty so we can launch ads without
//      the WhatsApp channel and add it later.
//
//   2. Email — opens `mailto:` with a pre-filled subject and body.
//
//   3. In-app — expands to an inline form that POSTs to the support-ticket
//      edge function via [SupportService].
//
// All three rows are styled as 56-dp tall, rounded buttons so the sheet
// feels consistent with the rest of the app. The success state is a
// transient checkmark + dismissed-modal pattern (auto-close after 2 s).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_config.dart';
import '../../l10n/app_localizations.dart';
import '../../services/support_service.dart';
import 'support_fab.dart' show kSupportTeal, kSupportTealDark;

class SupportSheet extends ConsumerStatefulWidget {
  const SupportSheet({super.key});

  @override
  ConsumerState<SupportSheet> createState() => _SupportSheetState();
}

class _SupportSheetState extends ConsumerState<SupportSheet> {
  final _messageController = TextEditingController();
  final _emailController = TextEditingController();
  // Honeypot — a hidden input. Real users never see or touch it; bots that
  // fill every named input lose the request.
  final _honeypotController = TextEditingController();

  SupportCategory _category = SupportCategory.bug;

  /// When true the in-app form is expanded below the three channel rows.
  bool _formOpen = false;

  /// Submission in flight — disables the submit button + keeps the user
  /// from double-tapping during the round trip.
  bool _submitting = false;

  /// Set after a successful submit. Triggers the inline success view +
  /// auto-close after 2 s.
  bool _success = false;

  /// Last error code from the server, if any (e.g. 'too_short' / 'network').
  String? _errorReason;

  @override
  void initState() {
    super.initState();
    _prefillEmail();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _emailController.dispose();
    _honeypotController.dispose();
    super.dispose();
  }

  void _prefillEmail() {
    // Best-effort: read the currently-signed-in Supabase user's email if
    // available. In demo mode / pre-auth the field is left blank.
    try {
      final email = Supabase.instance.client.auth.currentUser?.email;
      if (email != null && email.isNotEmpty) {
        _emailController.text = email;
      }
    } catch (_) {
      // Supabase not initialised in demo mode — leave blank.
    }
  }

  Future<void> _openWhatsApp() async {
    const number = SupportConfig.whatsappNumber;
    if (number.isEmpty) return;
    final uri = Uri.parse('https://wa.me/$number');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openEmail() async {
    const email = SupportConfig.supportEmail;
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Support&body=Hi%2C%20',
    );
    await launchUrl(uri);
  }

  Future<void> _submitInApp() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _errorReason = null;
    });

    final service = ref.read(supportServiceProvider);
    final locale = Localizations.localeOf(context).languageCode;
    final result = await service.submitTicket(
      category: _category,
      message: _messageController.text,
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      language: locale,
      honeypot: _honeypotController.text,
    );

    if (!mounted) return;

    if (result.success) {
      setState(() {
        _submitting = false;
        _success = true;
      });
      // Auto-close after 2 s so the user gets a clear confirmation but
      // isn't trapped on the success view.
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.of(context).maybePop();
      });
    } else {
      setState(() {
        _submitting = false;
        _errorReason = result.errorReason;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: _success
              ? _buildSuccess(loc)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(context, loc),
                    const SizedBox(height: 8),
                    Text(
                      loc?.supportSubtitle ??
                          'We usually reply within 1-2 hours.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.black54,
                          ),
                    ),
                    const SizedBox(height: 16),
                    if (SupportConfig.whatsappAvailable) ...[
                      _buildChannelButton(
                        key: const ValueKey('support-whatsapp'),
                        label: loc?.supportWhatsapp ?? 'WhatsApp',
                        icon: Icons.chat_bubble_outline,
                        color: const Color(0xFF25D366),
                        onTap: _openWhatsApp,
                      ),
                      const SizedBox(height: 10),
                    ],
                    _buildChannelButton(
                      key: const ValueKey('support-email'),
                      label: loc?.supportEmail ?? 'Email',
                      icon: Icons.mail_outline,
                      color: const Color(0xFF2563EB),
                      onTap: _openEmail,
                    ),
                    const SizedBox(height: 10),
                    _buildChannelButton(
                      key: const ValueKey('support-inapp'),
                      label: loc?.supportInApp ?? 'Message us here',
                      icon: Icons.support_agent,
                      color: kSupportTeal,
                      onTap: () => setState(() => _formOpen = !_formOpen),
                      selected: _formOpen,
                    ),
                    if (_formOpen) ...[
                      const SizedBox(height: 16),
                      _buildInAppForm(context, loc),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      loc?.supportPrivacyNotice ??
                          'Your message is stored securely.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.black45,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations? loc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            loc?.supportTitle ?? 'Need help?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        IconButton(
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }

  Widget _buildChannelButton({
    required Key key,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    return Material(
      key: key,
      color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? color : color.withValues(alpha: 0.45),
          width: selected ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: selected ? color : Colors.black87,
                  ),
                ),
              ),
              Icon(
                selected ? Icons.expand_less : Icons.chevron_right,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInAppForm(BuildContext context, AppLocalizations? loc) {
    final remaining = SupportLimits.messageMax - _messageController.text.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<SupportCategory>(
          key: const ValueKey('support-category'),
          initialValue: _category,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            isDense: true,
            labelText: loc?.supportCategoryLabel ?? 'Category',
          ),
          items: SupportCategory.values
              .map((c) => DropdownMenuItem<SupportCategory>(
                    value: c,
                    child: Text(_categoryLabel(loc, c)),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _category = v ?? _category),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('support-message'),
          controller: _messageController,
          maxLines: 4,
          maxLength: SupportLimits.messageMax,
          inputFormatters: [
            LengthLimitingTextInputFormatter(SupportLimits.messageMax),
          ],
          onChanged: (_) => setState(() {}), // refresh counter
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText:
                loc?.supportMessagePlaceholder ?? 'Describe your problem...',
            counterText: '${_messageController.text.length} / '
                '${SupportLimits.messageMax}',
            errorText: _errorReason == 'too_short'
                ? (loc?.supportErrorTooShort ??
                    'Please write at least 10 characters.')
                : _errorReason == 'too_long'
                    ? (loc?.supportErrorTooLong ?? 'Message too long.')
                    : null,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          // Live remaining-chars hint, separate from the counterText for a
          // friendlier tone on screens that crop the counter.
          remaining < 100 ? '$remaining left' : '',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        TextField(
          key: const ValueKey('support-email-input'),
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            isDense: true,
            labelText: loc?.supportEmailLabel ?? 'Email (optional)',
            hintText: 'you@example.com',
          ),
        ),
        // Honeypot — VISUALLY hidden but in the tree so test harness +
        // form-fillers can be detected. Real users never see or focus this.
        _Honeypot(controller: _honeypotController),
        const SizedBox(height: 12),
        if (_errorReason != null &&
            _errorReason != 'too_short' &&
            _errorReason != 'too_long')
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              loc?.supportError ?? 'Something went wrong. Try again.',
              style: const TextStyle(color: Color(0xFFB91C1C)),
            ),
          ),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            key: const ValueKey('support-submit'),
            onPressed: _submitting ? null : _submitInApp,
            style: ElevatedButton.styleFrom(
              backgroundColor: kSupportTeal,
              foregroundColor: Colors.white,
              disabledBackgroundColor: kSupportTealDark.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(loc?.supportSend ?? 'Send'),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess(AppLocalizations? loc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: kSupportTeal, size: 64),
          const SizedBox(height: 16),
          Text(
            loc?.supportSentSuccess ?? 'Message sent! We will reply soon.',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _categoryLabel(AppLocalizations? loc, SupportCategory c) {
    return switch (c) {
      SupportCategory.bug => loc?.supportCategoryBug ?? 'Bug',
      SupportCategory.payment =>
        loc?.supportCategoryPayment ?? 'Payment issue',
      SupportCategory.question => loc?.supportCategoryQuestion ?? 'Question',
      SupportCategory.feature =>
        loc?.supportCategoryFeature ?? 'Feature request',
      SupportCategory.other => loc?.supportCategoryOther ?? 'Other',
    };
  }
}

/// Visually-hidden honeypot text field. We keep it INSIDE the form tree
/// (rather than off-screen with `Offstage`) so any naive form-filling bot
/// that walks the widget tree fills it in. We give it size 0 so a real
/// user can never reach it.
class _Honeypot extends StatelessWidget {
  const _Honeypot({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 0,
      width: 0,
      child: ExcludeFocus(
        child: ExcludeSemantics(
          child: TextField(
            key: const ValueKey('support-honeypot'),
            controller: controller,
            autofocus: false,
            enabled: true,
            decoration: const InputDecoration(
              labelText: 'website', // misleading-but-innocuous label
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
      ),
    );
  }
}
