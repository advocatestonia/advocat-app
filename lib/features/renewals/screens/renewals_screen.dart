// renewals_screen.dart — Permit / Document Renewal Radar UI.
// -----------------------------------------------------------------------------
// Lists the user's tracked personal documents grouped by urgency, with a
// reminder-window timeline (90/30/7) per card, an add/edit bottom sheet, and a
// per-document reminders toggle. Self-contained: depends only on this feature's
// model/provider/repository, the shared theme, and l10n (renewal* prefix).
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../models/renewable_document.dart';
import '../providers/renewals_provider.dart';
import '../repositories/renewals_repository.dart';

class RenewalsScreen extends ConsumerWidget {
  const RenewalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(renewalsListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.renewalTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref, null),
        icon: const Icon(Icons.add),
        label: Text(l10n.renewalAdd),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(message: l10n.renewalLoadError),
        data: (docs) {
          if (docs.isEmpty) return _EmptyState(l10n: l10n);
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(renewalsListProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                Text(
                  l10n.renewalSubtitle,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                for (final d in docs)
                  _RenewalCard(
                    doc: d,
                    onTap: () => _openEditor(context, ref, d),
                    onToggle: (v) => _toggle(context, ref, d, v),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    RenewableDocument doc,
    bool enabled,
  ) async {
    try {
      await ref
          .read(renewalsRepositoryProvider)
          .setNotificationsEnabled(doc.id, enabled);
      ref.invalidate(renewalsListProvider);
    } on RenewalsRepositoryException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref,
    RenewableDocument? existing,
  ) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _RenewalEditor(existing: existing),
    );
    if (saved == true) ref.invalidate(renewalsListProvider);
  }
}

// ── Card ─────────────────────────────────────────────────────────────────────

class _RenewalCard extends StatelessWidget {
  const _RenewalCard({
    required this.doc,
    required this.onTap,
    required this.onToggle,
  });

  final RenewableDocument doc;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final days = doc.daysUntilExpiry();
    final urgency = doc.urgency();
    final color = _urgencyColor(urgency);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_typeIcon(doc.docType), size: 20, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      doc.label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                  Switch(
                    value: doc.notificationsEnabled,
                    onChanged: onToggle,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _expiryLabel(l10n, days, doc.expiresOn),
                style: TextStyle(color: color, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              _WindowTimeline(doc: doc),
              if (doc.docType.hasRenewalGuide) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.menu_book_outlined,
                        size: 16, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Text(
                      l10n.renewalGuideHint,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.accent),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _expiryLabel(AppLocalizations l10n, int days, DateTime on) {
    final dateStr = RenewableDocument.dateOnly(on);
    if (days < 0) return l10n.renewalExpiredOn(dateStr);
    if (days == 0) return l10n.renewalExpiresToday;
    return l10n.renewalExpiresInDays(days, dateStr);
  }
}

/// The 90/30/7 reminder windows as a dotted progress row. A dot is filled when
/// that window's reminder has already been sent (mirrors `reminders_sent`).
class _WindowTimeline extends StatelessWidget {
  const _WindowTimeline({required this.doc});
  final RenewableDocument doc;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sent = doc.remindersSent.toSet();
    Widget dot(String key, String label) {
      final done = sent.contains(key);
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            done ? Icons.check_circle : Icons.circle_outlined,
            size: 14,
            color: done ? AppColors.success : AppColors.textTertiary,
          ),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      );
    }

    return Wrap(
      spacing: 14,
      children: [
        dot('90', l10n.renewalWindow90),
        dot('30', l10n.renewalWindow30),
        dot('7', l10n.renewalWindow7),
      ],
    );
  }
}

// ── Editor bottom sheet ──────────────────────────────────────────────────────

class _RenewalEditor extends ConsumerStatefulWidget {
  const _RenewalEditor({this.existing});
  final RenewableDocument? existing;

  @override
  ConsumerState<_RenewalEditor> createState() => _RenewalEditorState();
}

class _RenewalEditorState extends ConsumerState<_RenewalEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _label;
  late final TextEditingController _number;
  late final TextEditingController _jurisdiction;
  late RenewableDocType _type;
  DateTime? _expiresOn;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _label = TextEditingController(text: e?.label ?? '');
    _number = TextEditingController(text: e?.docNumber ?? '');
    _jurisdiction = TextEditingController(text: e?.jurisdiction ?? '');
    _type = e?.docType ?? RenewableDocType.residencePermit;
    _expiresOn = e?.expiresOn;
  }

  @override
  void dispose() {
    _label.dispose();
    _number.dispose();
    _jurisdiction.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.existing == null
                    ? l10n.renewalAdd
                    : l10n.renewalEditTitle,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<RenewableDocType>(
                initialValue: _type,
                decoration: InputDecoration(labelText: l10n.renewalFieldType),
                items: [
                  for (final t in RenewableDocType.values)
                    DropdownMenuItem(
                        value: t, child: Text(_typeLabel(l10n, t))),
                ],
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _label,
                decoration: InputDecoration(labelText: l10n.renewalFieldLabel),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.renewalRequired : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _number,
                decoration:
                    InputDecoration(labelText: l10n.renewalFieldNumber),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _jurisdiction,
                maxLength: 2,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: l10n.renewalFieldJurisdiction,
                  hintText: 'FI, EE…',
                ),
              ),
              const SizedBox(height: 4),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.renewalFieldExpiry),
                subtitle: Text(
                  _expiresOn == null
                      ? l10n.renewalPickDate
                      : RenewableDocument.dateOnly(_expiresOn!),
                ),
                trailing: const Icon(Icons.calendar_today, size: 18),
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.renewalSave),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresOn ?? now.add(const Duration(days: 90)),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 20),
    );
    if (picked != null) setState(() => _expiresOn = picked);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_expiresOn == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.renewalPickDate)));
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(renewalsRepositoryProvider);
    final draft = RenewableDocument(
      id: widget.existing?.id ?? '',
      docType: _type,
      label: _label.text.trim(),
      docNumber: _number.text.trim(),
      jurisdiction: _jurisdiction.text.trim().toUpperCase(),
      expiresOn: _expiresOn!,
      notificationsEnabled: widget.existing?.notificationsEnabled ?? true,
    );
    try {
      if (widget.existing == null) {
        await repo.create(draft);
      } else {
        await repo.update(widget.existing!.id, draft);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on RenewalsRepositoryException catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

// ── Empty / error states ─────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_repeat,
                size: 56, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              l10n.renewalEmptyTitle,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.renewalEmptyBody,
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.error)),
      ),
    );
  }
}

// ── helpers ──────────────────────────────────────────────────────────────────

Color _urgencyColor(RenewalUrgency u) {
  switch (u) {
    case RenewalUrgency.expired:
    case RenewalUrgency.critical:
      return AppColors.error;
    case RenewalUrgency.soon:
      return AppColors.warning;
    case RenewalUrgency.upcoming:
      return AppColors.info;
    case RenewalUrgency.distant:
      return AppColors.textSecondary;
  }
}

IconData _typeIcon(RenewableDocType t) {
  switch (t) {
    case RenewableDocType.residencePermit:
    case RenewableDocType.workPermit:
      return Icons.badge_outlined;
    case RenewableDocType.passport:
      return Icons.book_outlined;
    case RenewableDocType.idCard:
      return Icons.credit_card;
    case RenewableDocType.visa:
      return Icons.flight_takeoff;
    case RenewableDocType.drivingLicence:
      return Icons.directions_car_outlined;
    case RenewableDocType.insurance:
      return Icons.health_and_safety_outlined;
    case RenewableDocType.other:
      return Icons.description_outlined;
  }
}

String _typeLabel(AppLocalizations l10n, RenewableDocType t) {
  switch (t) {
    case RenewableDocType.residencePermit:
      return l10n.renewalTypeResidencePermit;
    case RenewableDocType.passport:
      return l10n.renewalTypePassport;
    case RenewableDocType.idCard:
      return l10n.renewalTypeIdCard;
    case RenewableDocType.visa:
      return l10n.renewalTypeVisa;
    case RenewableDocType.drivingLicence:
      return l10n.renewalTypeDrivingLicence;
    case RenewableDocType.insurance:
      return l10n.renewalTypeInsurance;
    case RenewableDocType.workPermit:
      return l10n.renewalTypeWorkPermit;
    case RenewableDocType.other:
      return l10n.renewalTypeOther;
  }
}
