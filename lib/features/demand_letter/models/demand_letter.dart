// demand_letter/models/demand_letter.dart — Feature #2.
// -----------------------------------------------------------------------------
// Plain data models for the Demand-Letter Generator. No Supabase dependency so
// they can be constructed in tests. Mirrors the `demand_letters` table from
// migration 20260617000000_demand_letters.sql and the `demand-letter` edge fn.
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart' show immutable;

/// The four supported claim presets. Kept as an enum so the wizard is
/// exhaustive and switch-checked.
enum DemandClaimType {
  depositReturn('deposit_return'),
  unpaidWage('unpaid_wage'),
  fineDispute('fine_dispute'),
  genericClaim('generic_claim');

  const DemandClaimType(this.wire);

  /// The string the edge function expects.
  final String wire;

  static DemandClaimType fromWire(String? v) {
    return DemandClaimType.values.firstWhere(
      (e) => e.wire == v,
      orElse: () => DemandClaimType.genericClaim,
    );
  }

  /// True when an amount is required for this claim type (everything except a
  /// fine dispute, where the user may be contesting rather than claiming).
  bool get requiresAmount => this != DemandClaimType.fineDispute;
}

/// A statutory reference embedded in the generated letter.
@immutable
class DemandNorm {
  const DemandNorm({
    required this.label,
    required this.slug,
    required this.article,
    required this.note,
  });

  final String label;
  final String slug;
  final String article;
  final String note;

  factory DemandNorm.fromJson(Map<String, dynamic> json) {
    return DemandNorm(
      label: (json['label'] as String?) ?? '',
      slug: (json['slug'] as String?) ?? '',
      article: (json['article'] as String?) ?? '',
      note: (json['note'] as String?) ?? '',
    );
  }
}

/// A party (sender / recipient) the wizard collects.
@immutable
class DemandParty {
  const DemandParty({required this.name, this.address});

  final String name;
  final String? address;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        if (address != null && address!.isNotEmpty) 'address': address,
      };
}

/// Result of a successful `demand-letter` edge-function call.
@immutable
class DemandLetterResult {
  const DemandLetterResult({
    required this.letterId,
    required this.markdown,
    required this.subject,
    this.norms = const <DemandNorm>[],
  });

  /// The id of the persisted row (for re-export / status updates).
  final String letterId;

  /// The composed letter body (markdown) — feeds the preview + pdf-generator.
  final String markdown;

  /// Subject line (also the saved-letter title).
  final String subject;

  /// The statutory references embedded in the body (rendered as chips).
  final List<DemandNorm> norms;

  factory DemandLetterResult.fromJson(Map<String, dynamic> json) {
    final rawNorms = json['norms'];
    final norms = rawNorms is List
        ? rawNorms
            .whereType<Map>()
            .map((m) => DemandNorm.fromJson(m.cast<String, dynamic>()))
            .toList(growable: false)
        : const <DemandNorm>[];
    return DemandLetterResult(
      letterId: (json['letter_id'] as String?) ?? '',
      markdown: (json['markdown'] as String?) ?? '',
      subject: (json['subject'] as String?) ?? '',
      norms: norms,
    );
  }
}

/// The full set of wizard inputs sent to the edge function.
@immutable
class DemandLetterRequest {
  const DemandLetterRequest({
    required this.claimType,
    required this.jurisdiction,
    required this.lang,
    required this.recipient,
    required this.basis,
    required this.deadline,
    this.sender,
    this.amount,
    this.currency = 'EUR',
    this.reference,
    this.caseId,
    this.letterId,
  });

  final DemandClaimType claimType;

  /// 'FI' or 'EE'.
  final String jurisdiction;

  /// 'fi' | 'et' | 'ru' | 'en'.
  final String lang;

  final DemandParty recipient;

  /// Optional — the server falls back to the user's profile when omitted.
  final DemandParty? sender;

  final String basis;
  final String deadline;
  final String? amount;
  final String currency;
  final String? reference;
  final String? caseId;

  /// When set, the server updates this existing draft instead of inserting.
  final String? letterId;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'claim_type': claimType.wire,
        'jurisdiction': jurisdiction,
        'lang': lang,
        'recipient': recipient.toJson(),
        if (sender != null) 'sender': sender!.toJson(),
        'basis': basis,
        'deadline': deadline,
        if (amount != null && amount!.isNotEmpty) 'amount': amount,
        'currency': currency,
        if (reference != null && reference!.isNotEmpty) 'reference': reference,
        if (caseId != null && caseId!.isNotEmpty) 'case_id': caseId,
        if (letterId != null && letterId!.isNotEmpty) 'letter_id': letterId,
      };
}
