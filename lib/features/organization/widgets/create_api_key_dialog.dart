import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../models/api_key.dart';
import '../providers/org_providers.dart';
import '../repositories/org_repository.dart';

class CreateApiKeyDialog extends ConsumerStatefulWidget {
  const CreateApiKeyDialog({super.key, required this.orgId});
  final String orgId;

  static Future<void> show(BuildContext context, String orgId) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CreateApiKeyDialog(orgId: orgId),
    );
  }

  @override
  ConsumerState<CreateApiKeyDialog> createState() =>
      _CreateApiKeyDialogState();
}

class _CreateApiKeyDialogState extends ConsumerState<CreateApiKeyDialog> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final Set<String> _scopes = {'cases:read'};
  DateTime? _expiresAt;
  bool _submitting = false;
  String? _error;
  ApiKeyWithSecret? _created;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_scopes.isEmpty) {
      setState(() => _error = 'Select at least one scope.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await ref.read(orgRepositoryProvider).createApiKey(
            orgId: widget.orgId,
            name: _nameController.text.trim(),
            scopes: _scopes.toList(),
            expiresAt: _expiresAt,
          );
      ref.invalidate(orgApiKeysProvider(widget.orgId));
      if (mounted) {
        setState(() {
          _created = result;
          _submitting = false;
        });
      }
    } on OrgRepositoryException catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not create key: ${e.code}';
          _submitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Unexpected error: $e';
          _submitting = false;
        });
      }
    }
  }

  Future<void> _pickExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _expiresAt ?? DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _expiresAt = picked);
  }

  @override
  Widget build(BuildContext context) {
    final secret = _created;
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: secret != null ? _buildSecretView(secret) : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Create API key',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Use these credentials in your integrations. Treat the secret like a password.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            AppTextField(
              controller: _nameController,
              label: 'Name',
              hint: 'Production CMS sync',
              autofocus: true,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name required' : null,
            ),
            const SizedBox(height: 16),
            const Text(
              'Scopes',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            for (final entry in ApiKeyScope.groups.entries)
              _ScopeGroup(
                title: entry.key,
                scopes: entry.value,
                selected: _scopes,
                onToggle: (id, on) => setState(() {
                  if (on) {
                    _scopes.add(id);
                  } else {
                    _scopes.remove(id);
                  }
                }),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickExpiry,
                    icon: const Icon(Icons.event_outlined, size: 16),
                    label: Text(
                      _expiresAt == null
                          ? 'No expiry'
                          : 'Expires ${_expiresAt!.toIso8601String().substring(0, 10)}',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                if (_expiresAt != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () => setState(() => _expiresAt = null),
                    tooltip: 'Remove expiry',
                  ),
                ],
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 12,
                  )),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Cancel',
                    variant: AppButtonVariant.ghost,
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    isFullWidth: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: 'Create key',
                    onPressed: _submitting ? null : _submit,
                    isLoading: _submitting,
                    isFullWidth: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecretView(ApiKeyWithSecret result) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: AppColors.warning, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Copy this key now',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          "We won't show this secret again. Save it somewhere safe — e.g. your CI environment variables or a password manager.",
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: SelectableText(
                  result.secret,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18),
                tooltip: 'Copy',
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: result.secret));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Secret copied to clipboard')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: AppButton(
            label: "I've saved it",
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}

class _ScopeGroup extends StatelessWidget {
  const _ScopeGroup({
    required this.title,
    required this.scopes,
    required this.selected,
    required this.onToggle,
  });

  final String title;
  final List<ApiKeyScope> scopes;
  final Set<String> selected;
  final void Function(String id, bool on) onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textTertiary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in scopes)
                FilterChip(
                  label: Text(s.id,
                      style: const TextStyle(
                          fontFamily: 'monospace', fontSize: 11)),
                  selected: selected.contains(s.id),
                  onSelected: (v) => onToggle(s.id, v),
                  backgroundColor: AppColors.surfaceVariant,
                  selectedColor: AppColors.accent.withValues(alpha: 0.15),
                  checkmarkColor: AppColors.accent,
                  side: BorderSide(
                    color: selected.contains(s.id)
                        ? AppColors.accent
                        : AppColors.border,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
