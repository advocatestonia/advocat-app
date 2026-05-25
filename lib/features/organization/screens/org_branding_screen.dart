import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../shared/widgets/advocat_gradient_header.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/max_width_wrapper.dart';
import '../models/org_branding.dart';
import '../models/organization.dart';
import '../providers/org_providers.dart';
import '../repositories/org_repository.dart';
import '../widgets/working_context_banner.dart';

/// Customize logo, colors, support email, footer, custom domain.
/// Spec: see FLUTTER_UI_SPEC.md §4.
class OrgBrandingScreen extends ConsumerWidget {
  const OrgBrandingScreen({super.key, required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgAsync = ref.watch(orgBySlugProvider(slug));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AdvocatGradientHeader(title: 'Branding'),
      body: SafeArea(
        child: MaxWidthWrapper(
          child: orgAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text('$e',
                  style: const TextStyle(color: AppColors.error)),
            ),
            data: (org) {
              if (org == null) {
                return const Center(
                    child: Text('Organization not found.'));
              }
              if (!(org.myRole?.canManageBranding ?? false)) {
                return const EmptyState(
                  icon: Icons.lock_outline_rounded,
                  title: 'Branding is restricted',
                  description:
                      'Only the owner and admins can customize the firm brand.',
                );
              }
              if (!org.plan.hasBranding) {
                return const EmptyState(
                  icon: Icons.upgrade_outlined,
                  title: 'Available on Firm plan and up',
                  description:
                      'Upgrade to the Firm plan to upload your logo and pick brand colors.',
                );
              }
              return _BrandingBody(org: org);
            },
          ),
        ),
      ),
    );
  }
}

class _BrandingBody extends ConsumerStatefulWidget {
  const _BrandingBody({required this.org});
  final Organization org;

  @override
  ConsumerState<_BrandingBody> createState() => _BrandingBodyState();
}

class _BrandingBodyState extends ConsumerState<_BrandingBody> {
  Timer? _saveDebounce;
  bool _saving = false;
  String? _saveStatus;

  final _supportEmailController = TextEditingController();
  final _customDomainController = TextEditingController();
  final _footerHtmlController = TextEditingController();

  bool _initialized = false;

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _supportEmailController.dispose();
    _customDomainController.dispose();
    _footerHtmlController.dispose();
    super.dispose();
  }

  void _ensureInitialized(OrgBranding b) {
    if (_initialized) return;
    _supportEmailController.text = b.supportEmail ?? '';
    _customDomainController.text = b.customDomain ?? '';
    _footerHtmlController.text = b.footerHtml ?? '';
    _initialized = true;
  }

  void _scheduleSave() {
    _saveDebounce?.cancel();
    setState(() => _saveStatus = 'Saving…');
    _saveDebounce = Timer(const Duration(seconds: 1), _save);
  }

  Future<void> _save() async {
    final draft = ref.read(brandingDraftProvider(widget.org.id));
    if (draft == null || _saving) return;
    setState(() => _saving = true);
    try {
      final updated = await ref.read(orgRepositoryProvider).saveBranding(
            draft.copyWith(
              supportEmail: _supportEmailController.text.trim(),
              customDomain: _customDomainController.text.trim().isEmpty
                  ? null
                  : _customDomainController.text.trim(),
              footerHtml: _footerHtmlController.text.trim().isEmpty
                  ? null
                  : _footerHtmlController.text.trim(),
            ),
          );
      ref
          .read(brandingDraftProvider(widget.org.id).notifier)
          .update(updated);
      ref.invalidate(orgBrandingProvider(widget.org.id));
      if (mounted) {
        setState(() {
          _saveStatus = 'Saved';
          _saving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saveStatus = 'Could not save: $e';
          _saving = false;
        });
      }
    }
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp', 'svg'],
    );
    final file = result?.files.firstOrNull;
    if (file == null || file.bytes == null) return;
    setState(() => _saveStatus = 'Uploading logo…');
    try {
      final url = await ref.read(orgRepositoryProvider).uploadLogo(
            widget.org.id,
            file.bytes!,
            file.name,
          );
      final current = ref.read(brandingDraftProvider(widget.org.id));
      if (current != null) {
        ref
            .read(brandingDraftProvider(widget.org.id).notifier)
            .update(current.copyWith(logoUrl: url));
      }
      _scheduleSave();
    } catch (e) {
      if (mounted) {
        setState(() => _saveStatus = 'Logo upload failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final draftAsync = ref.watch(orgBrandingProvider(widget.org.id));
    final draft = ref.watch(brandingDraftProvider(widget.org.id));

    return draftAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('$e', style: const TextStyle(color: AppColors.error)),
      ),
      data: (b) {
        _ensureInitialized(b);
        final current = draft ?? b;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            const WorkingContextBanner(),
            const SizedBox(height: 16),
            _SaveStatus(status: _saveStatus, saving: _saving),
            _LogoSection(
              logoUrl: current.logoUrl,
              onPick: _pickLogo,
              onRemove: () {
                ref
                    .read(brandingDraftProvider(widget.org.id).notifier)
                    .update(current.copyWith(logoUrl: ''));
                _scheduleSave();
              },
            ),
            const SizedBox(height: 16),
            _ColorSection(
              primary: current.primaryColor ?? '#1A365D',
              accent: current.accentColor ?? '#0B7A70',
              onChange: (p, a) {
                ref
                    .read(brandingDraftProvider(widget.org.id).notifier)
                    .update(current.copyWith(
                      primaryColor: p,
                      accentColor: a,
                    ));
                _scheduleSave();
              },
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Support email',
              description:
                  'Appears on outgoing emails sent through Advocat for this org.',
              child: AppTextField(
                controller: _supportEmailController,
                hint: 'support@yourfirm.ee',
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => _scheduleSave(),
              ),
            ),
            if (widget.org.plan.hasWhiteLabel) ...[
              const SizedBox(height: 16),
              _Section(
                title: 'Footer HTML',
                description:
                    'Appears on outgoing emails and PDF documents. HTML is sanitized server-side.',
                child: AppTextField(
                  controller: _footerHtmlController,
                  isMultiline: true,
                  minLines: 3,
                  maxLines: 6,
                  hint: '<p>Sirel & Partnerid · Tartu mnt 84a, Tallinn</p>',
                  onChanged: (_) => _scheduleSave(),
                ),
              ),
            ],
            if (widget.org.plan.hasCustomDomain) ...[
              const SizedBox(height: 16),
              _Section(
                title: 'Custom domain',
                description:
                    'Point a CNAME record from your subdomain to '
                    '`cname.advocat.ee` and we will issue a TLS certificate.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(
                      controller: _customDomainController,
                      hint: 'app.yourfirm.ee',
                      onChanged: (_) => _scheduleSave(),
                    ),
                    if (current.customDomainStatus != null) ...[
                      const SizedBox(height: 8),
                      _DomainStatusBadge(
                          status: current.customDomainStatus!),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _SaveStatus extends StatelessWidget {
  const _SaveStatus({required this.status, required this.saving});
  final String? status;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    if (status == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (saving)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            )
          else
            Icon(
              status == 'Saved'
                  ? Icons.check_circle_rounded
                  : Icons.error_outline_rounded,
              size: 14,
              color: status == 'Saved'
                  ? AppColors.success
                  : AppColors.textTertiary,
            ),
          const SizedBox(width: 6),
          Text(
            status!,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoSection extends StatelessWidget {
  const _LogoSection({
    required this.logoUrl,
    required this.onPick,
    required this.onRemove,
  });
  final String? logoUrl;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Logo',
      description: 'PNG, JPEG, SVG, or WebP. Max 5 MB.',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
              image: logoUrl != null && logoUrl!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(logoUrl!),
                      fit: BoxFit.contain,
                    )
                  : null,
            ),
            alignment: Alignment.center,
            child: logoUrl == null || logoUrl!.isEmpty
                ? const Icon(Icons.image_outlined,
                    color: AppColors.textTertiary, size: 32)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FilledButton.icon(
                  onPressed: onPick,
                  icon: const Icon(Icons.upload_outlined, size: 16),
                  label: Text(
                      logoUrl == null || logoUrl!.isEmpty
                          ? 'Upload logo'
                          : 'Replace logo'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                  ),
                ),
                if (logoUrl != null && logoUrl!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    label: const Text('Remove'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.error),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorSection extends StatelessWidget {
  const _ColorSection({
    required this.primary,
    required this.accent,
    required this.onChange,
  });
  final String primary;
  final String accent;
  final void Function(String primary, String accent) onChange;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Brand colors',
      description:
          'Used in emails, the client portal, and exported PDFs.',
      child: Column(
        children: [
          _ColorRow(
            label: 'Primary',
            value: primary,
            onChanged: (v) => onChange(v, accent),
          ),
          const SizedBox(height: 12),
          _ColorRow(
            label: 'Accent',
            value: accent,
            onChanged: (v) => onChange(primary, v),
          ),
          const SizedBox(height: 16),
          _Preview(primary: primary, accent: accent),
        ],
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  Color get _color {
    var hex = value.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.tryParse(hex, radix: 16) ?? 0xFF000000);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _color,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.border),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: TextField(
            controller: TextEditingController(text: value)
              ..selection = TextSelection.fromPosition(
                  TextPosition(offset: value.length)),
            onSubmitted: (v) {
              if (RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(v.trim())) {
                onChanged(v.trim().toUpperCase());
              }
            },
            decoration: const InputDecoration(
              hintText: '#0B7A70',
              isDense: true,
            ),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.primary, required this.accent});
  final String primary;
  final String accent;

  Color _parse(String s) {
    var hex = s.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.tryParse(hex, radix: 16) ?? 0xFF000000);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _parse(primary),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preview',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white60,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'How your brand will appear',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _parse(accent),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Text(
              'Open client portal',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DomainStatusBadge extends StatelessWidget {
  const _DomainStatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'active' => AppColors.success,
      'failed' => AppColors.error,
      _ => AppColors.warning,
    };
    final label = switch (status) {
      'active' => 'Active',
      'failed' => 'TLS issuance failed',
      'pending_dns' => 'Awaiting DNS propagation',
      _ => status,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    this.description,
  });

  final String title;
  final String? description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (description != null) ...[
            const SizedBox(height: 4),
            Text(
              description!,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
