// lib/features/lawyer_verification/screens/lawyer_verification_screen.dart
// -----------------------------------------------------------------------------
// "AI for verified attorneys" verification form.
//
// Reached from /lawyers (web landing → app deep link) and from the
// Settings screen ("Verify as attorney" tile). The screen has three modes,
// gated on the status fetched on mount:
//
//   1. Verified-already → success card with revocation note.
//   2. Pending review   → "we'll get back within 24h" card.
//   3. Fresh form       → country selector + four text fields + submit.
//
// Submission lifecycle:
//   * LawyerSubmitIdle      → form is editable.
//   * LawyerSubmitInFlight  → button shows spinner, fields disabled.
//   * LawyerSubmitDone      → result card (Approved / Queued / Rejected),
//                             with "Try again" CTA on Rejected.
//
// Localisation strings live inline as untranslated English for the v1
// ship — the four-language marketing copy in Part 3 of the task is the
// authoritative source and will be migrated into ARBs when l10n updates
// land in the next batch.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../models/lawyer_verification_state.dart';
import '../state/lawyer_verification_providers.dart';

class LawyerVerificationScreen extends ConsumerWidget {
  const LawyerVerificationScreen({super.key});

  static const String routePath = '/lawyers/verify';
  static const String routeName = 'lawyer_verification';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(lawyerVerificationStatusProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Verify as attorney'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: statusAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _FormSection(),
          data: (status) {
            if (status.isVerified) {
              return _AlreadyVerifiedCard(status: status);
            }
            if (status.hasOpenApplication) {
              return const _PendingReviewCard();
            }
            return _FormSection();
          },
        ),
      ),
    );
  }
}

// ─── Form ────────────────────────────────────────────────────────────────

class _FormSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submitState = ref.watch(lawyerVerificationSubmitProvider);
    if (submitState is LawyerSubmitDone) {
      return _OutcomeCard(outcome: submitState.outcome);
    }
    return const SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _HeroBlock(),
          SizedBox(height: AppSpacing.lg),
          _LawyerForm(),
        ],
      ),
    );
  }
}

class _HeroBlock extends StatelessWidget {
  const _HeroBlock();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.verified_user_outlined, color: Colors.white, size: 32),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Premium for verified attorneys — free forever',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Estonian and Finnish bar members get unlimited Premium access. '
            'Validate the corpus, get a productivity edge, no obligation.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _LawyerForm extends ConsumerStatefulWidget {
  const _LawyerForm();
  @override
  ConsumerState<_LawyerForm> createState() => _LawyerFormState();
}

class _LawyerFormState extends ConsumerState<_LawyerForm> {
  final _barIdCtl = TextEditingController();
  final _nameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _urlCtl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _barIdCtl.dispose();
    _nameCtl.dispose();
    _emailCtl.dispose();
    _urlCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(lawyerVerificationFormProvider);
    final formCtl = ref.read(lawyerVerificationFormProvider.notifier);
    final submitState = ref.watch(lawyerVerificationSubmitProvider);
    final submitting = submitState is LawyerSubmitInFlight;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Country segmented control.
          _CountryToggle(
            value: form.country,
            onChanged: submitting ? null : formCtl.setCountry,
          ),
          const SizedBox(height: AppSpacing.md),

          // Bar ID.
          TextFormField(
            controller: _barIdCtl,
            enabled: !submitting,
            decoration: const InputDecoration(
              labelText: 'Bar association membership ID',
              helperText: 'Asianajajaliitto / Advokatuur member number',
              border: OutlineInputBorder(),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'\s')),
              // 64-char cap matches the DB CHECK.
              FilteringTextInputFormatter.singleLineFormatter,
            ],
            maxLength: 64,
            onChanged: formCtl.setBarId,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.sm),

          // Full name.
          TextFormField(
            controller: _nameCtl,
            enabled: !submitting,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Full name (as on the bar register)',
              border: OutlineInputBorder(),
            ),
            maxLength: 200,
            onChanged: formCtl.setFullName,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (v) {
              if (v == null || v.trim().length < 2) return 'Required';
              if (!v.contains(' ')) {
                return 'Please enter both first and last name';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.sm),

          // Email — must match the account email server-side.
          TextFormField(
            controller: _emailCtl,
            enabled: !submitting,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email (must match your account email)',
              border: OutlineInputBorder(),
            ),
            onChanged: formCtl.setEmail,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (v) {
              final t = (v ?? '').trim();
              if (!t.contains('@') || !t.contains('.')) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.sm),

          // Practice URL (optional but encouraged).
          TextFormField(
            controller: _urlCtl,
            enabled: !submitting,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Practice URL (LinkedIn or firm page) — optional',
              border: OutlineInputBorder(),
            ),
            maxLength: 500,
            onChanged: formCtl.setPracticeUrl,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (v) {
              final t = (v ?? '').trim();
              if (t.isEmpty) return null;
              if (!(t.startsWith('http://') || t.startsWith('https://'))) {
                return 'URL must start with http:// or https://';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Privacy note.
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.infoBg,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.lock_outline, size: 16, color: AppColors.info),
                SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Your bar ID is used only to verify membership against '
                    'the public registry. We never share it with third parties.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.info,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          ElevatedButton(
            onPressed: submitting || !form.isComplete
                ? null
                : () => ref
                    .read(lawyerVerificationSubmitProvider.notifier)
                    .submit(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            child: submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Text(
                    'Verify and activate Premium',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CountryToggle extends StatelessWidget {
  const _CountryToggle({required this.value, required this.onChanged});
  final LawyerBarCountry? value;
  final ValueChanged<LawyerBarCountry?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          _CountryChip(
            label: 'Estonia · Advokatuur',
            selected: value == LawyerBarCountry.ee,
            onTap: onChanged == null
                ? null
                : () => onChanged!(LawyerBarCountry.ee),
          ),
          const SizedBox(width: AppSpacing.xs),
          _CountryChip(
            label: 'Finland · Asianajajaliitto',
            selected: value == LawyerBarCountry.fi,
            onTap: onChanged == null
                ? null
                : () => onChanged!(LawyerBarCountry.fi),
          ),
        ],
      ),
    );
  }
}

class _CountryChip extends StatelessWidget {
  const _CountryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Result cards ────────────────────────────────────────────────────────

class _OutcomeCard extends ConsumerWidget {
  const _OutcomeCard({required this.outcome});
  final LawyerVerificationOutcome outcome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (outcome is LawyerVerificationApproved) {
      return _SuccessCard(
        verifiedAt: (outcome as LawyerVerificationApproved).verifiedAt,
      );
    }
    if (outcome is LawyerVerificationQueued) {
      return const _PendingReviewCard();
    }
    final rejected = outcome as LawyerVerificationRejected;
    return _RejectedCard(
      reasonCode: rejected.reasonCode,
      message: rejected.message,
      onRetry: () =>
          ref.read(lawyerVerificationSubmitProvider.notifier).reset(),
    );
  }
}

class _SuccessCard extends StatelessWidget {
  const _SuccessCard({required this.verifiedAt});
  final DateTime verifiedAt;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.successBg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.verified, color: AppColors.success, size: 32),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Welcome, counsel. Premium is active.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.success,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Your account is now Premium with unlimited messages, '
              'forever. A "Verified attorney" badge will appear on your '
              'profile in a few seconds.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingReviewCard extends StatelessWidget {
  const _PendingReviewCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.warningBg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.hourglass_bottom, color: AppColors.warning, size: 32),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Queued for review',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.warning,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              "We couldn't auto-match your details against the public "
              'registry — usually because of a recent change of practice or '
              'transliteration. The Advocat team reviews queued '
              'applications within 24 hours. You will get an email when '
              'Premium is activated.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RejectedCard extends StatelessWidget {
  const _RejectedCard({
    required this.reasonCode,
    required this.onRetry,
    this.message,
  });
  final String reasonCode;
  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final friendly = _friendlyReason(reasonCode, message);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.errorBg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(Icons.error_outline, color: AppColors.error, size: 32),
            const SizedBox(height: AppSpacing.sm),
            Text(
              friendly,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  /// Map server reason codes to user-friendly copy. Everything else falls
  /// back to a generic message that suggests contacting support.
  static String _friendlyReason(String code, String? message) {
    switch (code) {
      case 'email_mismatch':
        return 'The email you entered does not match the email on your '
            'Advocat account. Please use the same email — we cross-check '
            'before contacting the bar association.';
      case 'already_verified':
        return 'You are already verified as an attorney.';
      case 'pending_review':
        return 'Your previous application is already in the review queue.';
      case 'registry_miss':
        return 'We could not find a matching record on the bar association '
            'public registry. Double-check the spelling of your name and '
            'your membership ID. If your details are correct, contact '
            'support@advocat.ee — we will review manually.';
      case 'bad_country':
        return 'The bar program is currently open to Estonian (Advokatuur) '
            'and Finnish (Asianajajaliitto) members only.';
      case 'bad_bar_id':
        return 'Membership ID looks malformed.';
      case 'bad_name':
        return 'Please enter your full name (first and last).';
      case 'bad_email':
        return 'Email looks malformed.';
      case 'bad_url':
        return 'Practice URL must start with http:// or https://';
      case 'program_disabled':
        return 'The verified-attorney program is temporarily paused. '
            'Please check back later.';
      default:
        return message ??
            'Something went wrong. Please try again or contact '
                'support@advocat.ee.';
    }
  }
}

class _AlreadyVerifiedCard extends StatelessWidget {
  const _AlreadyVerifiedCard({required this.status});
  final LawyerVerificationStatus status;

  @override
  Widget build(BuildContext context) {
    final since = status.verifiedAt;
    final sinceText = since != null
        ? '${since.year}-${_pad(since.month)}-${_pad(since.day)}'
        : '—';
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.successBg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(Icons.verified, color: AppColors.success, size: 32),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'You are a verified attorney',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Premium is active since $sinceText. '
              'Your membership at the '
              '${status.barCountry == LawyerBarCountry.ee ? 'Advokatuur' : 'Asianajajaliitto'} '
              '(${status.barId ?? '—'}) is the source of truth — if it '
              'changes, write to support@advocat.ee.',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _pad(int v) => v.toString().padLeft(2, '0');
}
