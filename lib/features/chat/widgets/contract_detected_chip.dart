// contract_detected_chip.dart
// -----------------------------------------------------------------------------
// Auto-detect chip shown inline in the chat list after a PDF upload, when the
// classify-contract edge function tells us the document looks like a contract
// (confidence > 0.7).
//
// Tapping the chip triggers the parent's onTap callback, which is wired in
// chat_screen.dart to fire the analyze_contract tool with the user's locale
// as `output_language`. The chip itself is dumb: it doesn't talk to Supabase,
// doesn't know about quotas, and never tries to gate the tap. The contract-
// review edge function gates quota and returns 402 on its own; the screen
// handles that 402 with the existing upgrade dialog.
//
// The chip is intentionally narrow:
//   - one line of localized copy ("Review this contract"),
//   - a balance/scale icon to suggest legal review,
//   - a light-blue tinted background,
//   - a single tap target.
//
// Branding: never use the substring "B2B" in any code path or rendered text.
// The product copy is strictly "contract".
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';

/// Callback fired when the chip is tapped. The contract type hint (if any)
/// arrives via the constructor — parents that need to forward it to the
/// `analyze_contract` tool already know it; the chip is just a button.
typedef ContractChipTap = void Function([String? contractTypeHint]);

class ContractDetectedChip extends StatelessWidget {
  /// Default constructor — accepts an optional-positional callback so call
  /// sites can write either `onTap: () {}` (most common) or
  /// `onTap: ([hint]) {}` when they want the hint passed through.
  ///
  /// Internally we accept anything and adapt via [_adapt] so we can stay
  /// permissive about the signature at the call site (Dart does not
  /// auto-widen `void Function()` to `void Function([String?])`).
  ContractDetectedChip({
    super.key,
    required Function onTap,
    this.contractTypeHint,
  }) : _onTap = _adapt(onTap);

  final ContractChipTap _onTap;

  /// Optional industry hint surfaced from classify-contract. We don't
  /// render it — the chip stays one short line — but it is forwarded
  /// to the onTap callback so the analyze_contract call site can use it.
  final String? contractTypeHint;

  /// Adapt callbacks of either arity to the canonical `(String?)` signature.
  /// Throws a clear runtime error if a totally wrong signature is passed
  /// (rather than crashing the test with an obscure Dart error).
  static ContractChipTap _adapt(Function fn) {
    return ([String? hint]) {
      try {
        Function.apply(fn, hint == null ? const [] : [hint]);
      } on NoSuchMethodError {
        // Fall back: the callback didn't accept the positional argument —
        // call it without one. (Common case: `onTap: () {}`.)
        Function.apply(fn, const []);
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Falls back to the English wording when the locale delegate is missing
    // (e.g. a stripped-down test harness). The forbidden marker "B2B" is
    // never used.
    final label = l10n?.reviewThisContract ?? 'Review this contract';

    // Light-blue tint per spec. We use the existing accent tint to stay
    // visually consistent with the rest of chat (action chips, citations,
    // attachment indicators).
    final bg = AppColors.accent.withValues(alpha: 0.10);
    final border = AppColors.accent.withValues(alpha: 0.30);

    return Padding(
      padding: const EdgeInsets.only(
        top: 6,
        bottom: 2,
        left: 4,
        right: 4,
      ),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: const Key('contract_detected_chip_tap'),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: () => _onTap(contractTypeHint),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: border, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.balance,
                    size: 18,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
