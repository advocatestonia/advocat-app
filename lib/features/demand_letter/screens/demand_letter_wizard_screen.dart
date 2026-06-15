// demand_letter/screens/demand_letter_wizard_screen.dart — Feature #2.
// -----------------------------------------------------------------------------
// A guided 5-step wizard that produces a formal pre-court demand letter
// (FI maksuvaatimus / EE nõudekiri). On the final step it calls the
// `demand-letter` edge function (compose + persist) and pushes the preview
// screen with the result.
//
// Scope is deliberately narrow: four presets, structured fields, no free
// editor. The output always carries a non-removable disclaimer (UPL mitigation)
// and is never auto-sent.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../models/demand_letter.dart';
import '../services/demand_letter_service.dart';
import 'demand_letter_preview_screen.dart';

class DemandLetterWizardScreen extends ConsumerStatefulWidget {
  const DemandLetterWizardScreen({super.key, this.caseId});

  /// Optional case to link / auto-fill from.
  final String? caseId;

  @override
  ConsumerState<DemandLetterWizardScreen> createState() =>
      _DemandLetterWizardScreenState();
}

class _DemandLetterWizardScreenState
    extends ConsumerState<DemandLetterWizardScreen> {
  int _step = 0;
  bool _busy = false;

  DemandClaimType _claimType = DemandClaimType.depositReturn;
  String _jurisdiction = 'EE';
  String _lang = 'et';

  final _recipientName = TextEditingController();
  final _recipientAddress = TextEditingController();
  final _senderName = TextEditingController();
  final _senderAddress = TextEditingController();
  final _amount = TextEditingController();
  final _currency = TextEditingController(text: 'EUR');
  final _basis = TextEditingController();
  final _deadline = TextEditingController();
  final _reference = TextEditingController();

  @override
  void dispose() {
    for (final c in <TextEditingController>[
      _recipientName,
      _recipientAddress,
      _senderName,
      _senderAddress,
      _amount,
      _currency,
      _basis,
      _deadline,
      _reference,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String _claimLabel(DemandClaimType t, AppLocalizations l10n) {
    switch (t) {
      case DemandClaimType.depositReturn:
        return l10n.demandLetterClaimDepositReturn;
      case DemandClaimType.unpaidWage:
        return l10n.demandLetterClaimUnpaidWage;
      case DemandClaimType.fineDispute:
        return l10n.demandLetterClaimFineDispute;
      case DemandClaimType.genericClaim:
        return l10n.demandLetterClaimGeneric;
    }
  }

  /// Per-step validation. Returns null when the step is complete, else an error
  /// message to surface in a snackbar.
  String? _validateStep(int step, AppLocalizations l10n) {
    switch (step) {
      case 1:
        if (_recipientName.text.trim().isEmpty) {
          return l10n.demandLetterFieldRequired;
        }
        return null;
      case 2:
        if (_basis.text.trim().isEmpty) return l10n.demandLetterFieldRequired;
        if (_claimType.requiresAmount && _amount.text.trim().isEmpty) {
          return l10n.demandLetterFieldRequired;
        }
        return null;
      case 3:
        if (_deadline.text.trim().isEmpty) {
          return l10n.demandLetterFieldRequired;
        }
        return null;
      default:
        return null;
    }
  }

  Future<void> _generate(AppLocalizations l10n) async {
    setState(() => _busy = true);
    try {
      final service = ref.read(demandLetterServiceProvider);
      final senderName = _senderName.text.trim();
      final request = DemandLetterRequest(
        claimType: _claimType,
        jurisdiction: _jurisdiction,
        lang: _lang,
        recipient: DemandParty(
          name: _recipientName.text.trim(),
          address: _recipientAddress.text.trim().isEmpty
              ? null
              : _recipientAddress.text.trim(),
        ),
        sender: senderName.isEmpty
            ? null
            : DemandParty(
                name: senderName,
                address: _senderAddress.text.trim().isEmpty
                    ? null
                    : _senderAddress.text.trim(),
              ),
        basis: _basis.text.trim(),
        deadline: _deadline.text.trim(),
        amount: _amount.text.trim().isEmpty ? null : _amount.text.trim(),
        currency: _currency.text.trim().isEmpty ? 'EUR' : _currency.text.trim(),
        reference:
            _reference.text.trim().isEmpty ? null : _reference.text.trim(),
        caseId: widget.caseId,
      );
      final result = await service.generate(request);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DemandLetterPreviewScreen(
            result: result,
            locale: _lang,
            caseId: widget.caseId,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.demandLetterGenerateFailed)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onNext(AppLocalizations l10n) {
    final err = _validateStep(_step, l10n);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    if (_step >= 4) {
      _generate(l10n);
      return;
    }
    setState(() => _step += 1);
  }

  void _onBack() {
    if (_step > 0) setState(() => _step -= 1);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.demandLetterTitle)),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildStep(l10n),
            ),
          ),
          _buildDisclaimer(l10n),
          _buildNav(l10n),
        ],
      ),
    );
  }

  Widget _buildStep(AppLocalizations l10n) {
    switch (_step) {
      case 0:
        return _stepType(l10n);
      case 1:
        return _stepParties(l10n);
      case 2:
        return _stepClaim(l10n);
      case 3:
        return _stepDeadline(l10n);
      default:
        return _stepReview(l10n);
    }
  }

  Widget _stepType(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.demandLetterStepType,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(l10n.demandLetterSubtitle,
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),
        for (final t in DemandClaimType.values)
          ListTile(
            leading: Icon(
              _claimType == t
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: _claimType == t
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            title: Text(_claimLabel(t, l10n)),
            onTap: () => setState(() => _claimType = t),
          ),
        const SizedBox(height: 16),
        _dropdown<String>(
          label: l10n.demandLetterJurisdiction,
          value: _jurisdiction,
          items: const <String>['EE', 'FI'],
          onChanged: (v) => setState(() => _jurisdiction = v ?? _jurisdiction),
        ),
        const SizedBox(height: 12),
        _dropdown<String>(
          label: l10n.demandLetterLanguage,
          value: _lang,
          items: const <String>['et', 'fi', 'ru', 'en'],
          onChanged: (v) => setState(() => _lang = v ?? _lang),
        ),
      ],
    );
  }

  Widget _stepParties(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.demandLetterStepParties,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        _field(_recipientName, l10n.demandLetterRecipientName),
        _field(_recipientAddress, l10n.demandLetterRecipientAddress,
            maxLines: 2),
        const Divider(height: 32),
        _field(_senderName, l10n.demandLetterSenderName),
        _field(_senderAddress, l10n.demandLetterSenderAddress, maxLines: 2),
      ],
    );
  }

  Widget _stepClaim(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.demandLetterStepClaim,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        if (_claimType.requiresAmount)
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _field(_amount, l10n.demandLetterAmount,
                    keyboardType: TextInputType.number),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field(_currency, l10n.demandLetterCurrency),
              ),
            ],
          ),
        _field(_basis, l10n.demandLetterBasis,
            hint: l10n.demandLetterBasisHint, maxLines: 5),
        _field(_reference, l10n.demandLetterReference),
      ],
    );
  }

  Widget _stepDeadline(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.demandLetterStepDeadline,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        _field(_deadline, l10n.demandLetterDeadline,
            hint: l10n.demandLetterDeadlineHint),
      ],
    );
  }

  Widget _stepReview(AppLocalizations l10n) {
    final rows = <MapEntry<String, String>>[
      MapEntry(l10n.demandLetterStepType, _claimLabel(_claimType, l10n)),
      MapEntry(l10n.demandLetterJurisdiction, _jurisdiction),
      MapEntry(l10n.demandLetterLanguage, _lang),
      MapEntry(l10n.demandLetterRecipientName, _recipientName.text.trim()),
      if (_claimType.requiresAmount)
        MapEntry(l10n.demandLetterAmount,
            '${_amount.text.trim()} ${_currency.text.trim()}'),
      MapEntry(l10n.demandLetterDeadline, _deadline.text.trim()),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.demandLetterStepReview,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 140,
                  child: Text(r.key,
                      style: Theme.of(context).textTheme.labelMedium),
                ),
                Expanded(child: Text(r.value)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDisclaimer(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Text(
        l10n.demandLetterDisclaimer,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  Widget _buildNav(AppLocalizations l10n) {
    final isLast = _step >= 4;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (_step > 0)
              TextButton(
                onPressed: _busy ? null : _onBack,
                child: Text(l10n.demandLetterBack),
              ),
            const Spacer(),
            FilledButton(
              onPressed: _busy ? null : () => _onNext(l10n),
              child: Text(
                _busy
                    ? l10n.demandLetterGenerating
                    : (isLast
                        ? l10n.demandLetterGenerate
                        : l10n.demandLetterNext),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── small UI helpers ──────────────────────────────────────────────────────

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          items: items
              .map((e) => DropdownMenuItem<T>(
                    value: e,
                    child: Text('$e'),
                  ))
              .toList(growable: false),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
